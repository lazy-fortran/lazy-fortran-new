// Deterministic index of one run directory.
//
// The index is built in memory on every request and never written anywhere, so
// there is no staleness question and nothing to invalidate. Ordering is by
// section, then by byte-wise path comparison, so two runs of the indexer over
// the same directory produce the same list in the same order.

import * as fs from 'node:fs'
import * as path from 'node:path'
import { isInside, resolveInRoot } from './paths.mts'

export type Kind =
    | 'sx'
    | 'ebnf'
    | 'antlr'
    | 'bison'
    | 'treesitter'
    | 'fortran'
    | 'tsv'
    | 'jsonl'
    | 'json'
    | 'toml'
    | 'log'
    | 'java'
    | 'text'
    | 'binary'

export type Section = 'standardir' | 'grammar' | 'fortran' | 'metrics' | 'logs' | 'other'

export type IndexEntry = {
    rel: string // relative to the run directory
    name: string
    kind: Kind
    section: Section
    bytes: number
}

export type RunIndex = {
    ref: string // run directory relative to the served root, e.g. E0074/R000001
    entries: IndexEntry[]
    truncated: boolean
}

const SECTION_ORDER: Section[] = ['standardir', 'grammar', 'fortran', 'metrics', 'logs', 'other']

// Files past this count are not listed. A run directory holding more than this
// is not the bounded thing this tool was written for.
const MAX_ENTRIES = 4000
const MAX_DEPTH = 6

export function classify(rel: string): { kind: Kind; section: Section } {
    const name = path.posix.basename(rel).toLowerCase()
    const ext = name.includes('.') ? name.slice(name.lastIndexOf('.')) : ''
    if (ext === '.sx') return { kind: 'sx', section: 'standardir' }
    if (ext === '.ebnf') return { kind: 'ebnf', section: 'grammar' }
    if (ext === '.g4') return { kind: 'antlr', section: 'grammar' }
    if (ext === '.y') return { kind: 'bison', section: 'grammar' }
    if (ext === '.js') return { kind: 'treesitter', section: 'grammar' }
    if (ext === '.f90' || ext === '.f' || ext === '.f95' || ext === '.f03') {
        return { kind: 'fortran', section: 'fortran' }
    }
    if (ext === '.tsv' || ext === '.csv') return { kind: 'tsv', section: 'metrics' }
    if (ext === '.jsonl') return { kind: 'jsonl', section: 'metrics' }
    if (ext === '.json') return { kind: 'json', section: 'metrics' }
    if (ext === '.toml') return { kind: 'toml', section: 'metrics' }
    if (ext === '.log') return { kind: 'log', section: 'logs' }
    if (ext === '.java') return { kind: 'java', section: 'other' }
    if (ext === '.tokens' || ext === '.interp' || ext === '.txt' || ext === '.md') {
        return { kind: 'text', section: 'other' }
    }
    if (ext === '.o' || ext === '.a' || ext === '.mod' || ext === '.smod' || ext === '.so') {
        return { kind: 'binary', section: 'other' }
    }
    if (ext === '') return { kind: 'text', section: 'other' }
    return { kind: 'text', section: 'other' }
}

function compareEntries(a: IndexEntry, b: IndexEntry): number {
    const sa = SECTION_ORDER.indexOf(a.section)
    const sb = SECTION_ORDER.indexOf(b.section)
    if (sa !== sb) return sa - sb
    return a.rel < b.rel ? -1 : a.rel > b.rel ? 1 : 0
}

function walk(dir: string, base: string, depth: number, out: IndexEntry[]): boolean {
    if (depth > MAX_DEPTH) return false
    let names: fs.Dirent[]
    try {
        names = fs.readdirSync(dir, { withFileTypes: true })
    } catch {
        return false
    }
    let truncated = false
    for (const entry of names.sort((a, b) => (a.name < b.name ? -1 : a.name > b.name ? 1 : 0))) {
        const abs = path.join(dir, entry.name)
        const rel = base === '' ? entry.name : `${base}/${entry.name}`
        if (entry.isDirectory()) {
            truncated = walk(abs, rel, depth + 1, out) || truncated
            continue
        }
        // Symlinks are listed only when they stay inside the run directory.
        if (entry.isSymbolicLink()) {
            try {
                if (!isInside(fs.realpathSync(dir), fs.realpathSync(abs))) continue
            } catch {
                continue
            }
        } else if (!entry.isFile()) {
            continue
        }
        if (out.length >= MAX_ENTRIES) {
            truncated = true
            break
        }
        let bytes = 0
        try {
            bytes = fs.statSync(abs).size
        } catch {
            continue
        }
        const { kind, section } = classify(rel)
        out.push({ rel, name: entry.name, kind, section, bytes })
    }
    return truncated
}

export function indexRunDirectory(absDir: string, ref: string): RunIndex {
    const entries: IndexEntry[] = []
    const truncated = walk(absDir, '', 0, entries)
    entries.sort(compareEntries)
    return { ref, entries, truncated }
}

// Every run directory below the served root, as `E<NNNN>/R<NNNNNN>` refs when
// the root is the run cache, and as a single `.` when the root is one run.
export function listRuns(root: string): string[] {
    const refs: string[] = []
    const push = (rel: string) => {
        if (!refs.includes(rel)) refs.push(rel)
    }
    const top = safeReadDir(root)
    let anyExperiment = false
    for (const exp of top) {
        if (!exp.isDirectory()) continue
        const runs = safeReadDir(path.join(root, exp.name))
        for (const run of runs) {
            if (!run.isDirectory()) continue
            if (!/^R\d+$/.test(run.name)) continue
            anyExperiment = true
            push(`${exp.name}/${run.name}`)
        }
    }
    if (!anyExperiment) push('.')
    refs.sort((a, b) => (a < b ? -1 : a > b ? 1 : 0))
    return refs
}

function safeReadDir(dir: string): fs.Dirent[] {
    try {
        return fs.readdirSync(dir, { withFileTypes: true })
    } catch {
        return []
    }
}

// Resolve a run reference against the root; `.` means the root itself.
export function resolveRun(root: string, ref: string): { ok: true; abs: string; ref: string } | { ok: false; reason: string } {
    if (ref === '.' || ref === '') return { ok: true, abs: root, ref: '.' }
    const resolved = resolveInRoot(root, ref)
    if (!resolved.ok) return resolved
    if (!fs.statSync(resolved.abs).isDirectory()) return { ok: false, reason: 'not a directory' }
    return { ok: true, abs: resolved.abs, ref: resolved.rel }
}
