// Read-only research-library projections for the browser.
//
// These are rebuilt from the lab files on every request. They are deliberately
// a view, not a second ledger or database: the Markdown, YAML, JSONL and run
// artifacts remain authoritative.

import * as fs from 'node:fs'
import * as crypto from 'node:crypto'
import * as path from 'node:path'
import { indexRunDirectory, listRuns, resolveRun, type Kind } from './index.mts'
import { loadProvenance, parseFlatToml, type Provenance } from './provenance.mts'
import { parseSx, summarize } from './sx.mts'

const MAX_JSONL_BYTES = 12 * 1024 * 1024
const MAX_CASE_RECORDS = 320
const CASE_FILES = [
    'prompts.jsonl',
    'prompts/prompts.jsonl',
    'responses.jsonl',
    'model-errors.jsonl',
    'attempts.jsonl',
    'gate-results.jsonl',
    'accepted-proposals.jsonl',
    'rows.jsonl',
    'trajectory.jsonl',
]

function readText(file: string, limit = 4 * 1024 * 1024): string {
    try {
        const data = fs.readFileSync(file)
        return data.subarray(0, limit).toString('utf8')
    } catch {
        return ''
    }
}

function readJson(file: string): Record<string, unknown> | null {
    try {
        const value = JSON.parse(fs.readFileSync(file, 'utf8'))
        return value && typeof value === 'object' ? value as Record<string, unknown> : null
    } catch {
        return null
    }
}

function readJsonl(file: string): Record<string, unknown>[] {
    try {
        if (fs.statSync(file).size > MAX_JSONL_BYTES) return []
    } catch {
        return []
    }
    return readText(file, MAX_JSONL_BYTES)
        .split('\n')
        .filter((line) => line.trim() !== '')
        .flatMap((line) => {
            try {
                const value = JSON.parse(line)
                return value && typeof value === 'object' ? [value as Record<string, unknown>] : []
            } catch {
                return []
            }
        })
}

function scalar(text: string, key: string): string {
    const match = text.match(new RegExp(`^${key}:\\s*["']?([^"'\\n#]+)`,'m'))
    return match?.[1]?.trim() ?? ''
}

function experimentManifests(repoRoot: string): Record<string, unknown>[] {
    const dir = path.join(repoRoot, 'research', 'experiments')
    let names: fs.Dirent[]
    try { names = fs.readdirSync(dir, { withFileTypes: true }) } catch { return [] }
    return names
        .filter((entry) => entry.isDirectory() && /^E\d{4}-/.test(entry.name))
        .sort((a, b) => a.name.localeCompare(b.name))
        .map((entry) => {
            const manifestPath = path.join(dir, entry.name, 'manifest.yaml')
            const text = readText(manifestPath)
            return {
                id: scalar(text, 'id') || entry.name.split('-')[0],
                title: scalar(text, 'title') || entry.name,
                question: scalar(text, 'question'),
                status: scalar(text, 'status') || 'unknown',
                active_cell: scalar(text, 'active_cell'),
                reported_run: scalar(text, 'reported_run'),
                path: path.relative(repoRoot, manifestPath),
            }
        })
}

function decisions(repoRoot: string): Record<string, unknown>[] {
    const dir = path.join(repoRoot, 'research', 'decisions')
    let names: string[]
    try { names = fs.readdirSync(dir).filter((name) => name.endsWith('.md')) } catch { return [] }
    return names.sort().reverse().map((name) => {
        const relativePath = path.join('research', 'decisions', name)
        const text = readText(path.join(repoRoot, relativePath), 64 * 1024)
        const heading = text.match(/^# (D\d+)\.\s*(.+)$/m)
        return {
            id: heading?.[1] ?? name.slice(0, 5),
            title: heading?.[2] ?? name,
            date: scalar(text, 'Date'),
            status: scalar(text, 'Status'),
            path: relativePath,
        }
    })
}

function runDocuments(root: string): Record<string, unknown>[] {
    const documents: Record<string, unknown>[] = []
    for (const ref of listRuns(root)) {
        const run = resolveRun(root, ref)
        if (!run.ok) continue
        for (const entry of indexRunDirectory(run.abs, ref).entries) {
            if (!['pdf', 'sx', 'ebnf', 'antlr', 'bison', 'treesitter', 'fortran', 'tsv', 'jsonl'].includes(entry.kind)) continue
            documents.push({ ref, path: entry.rel, kind: entry.kind, bytes: entry.bytes })
            if (documents.length >= 1200) return documents
        }
    }
    return documents
}

type ProgressLane = {
    id: string
    title: string
    completed: number
    total: number
    basis: string
    evidence: string[]
}

function progressLanes(repoRoot: string): ProgressLane[] {
    const file = path.join(repoRoot, 'research', 'progress.toml')
    let text = readText(file, 64 * 1024)
    if (text === '') return []
    const fields = parseFlatToml(text)
    const ids = [...new Set(Object.keys(fields)
        .map((key) => key.match(/^lanes\.([^\.]+)\./)?.[1])
        .filter((id): id is string => Boolean(id)))]
    return ids.map((id) => {
        const get = (key: string) => fields[`lanes.${id}.${key}`] ?? ''
        return {
            id,
            title: get('title') || id,
            completed: Number(get('completed')) || 0,
            total: Number(get('total')) || 0,
            basis: get('basis'),
            evidence: get('evidence').split('|').map((item) => item.trim()).filter(Boolean),
        }
    })
}

function scalarToml(text: string, key: string): string {
    return parseFlatToml(text)[key] ?? ''
}

function artifactSources(repoRoot: string): Record<string, unknown>[] {
    const dir = path.join(repoRoot, 'artifacts', 'isa')
    let names: string[]
    try { names = fs.readdirSync(dir).filter((name) => name.endsWith('.toml')).sort() } catch { return [] }
    return names.map((name) => {
        const manifestPath = path.join(dir, name)
        const fields = parseFlatToml(readText(manifestPath, 64 * 1024))
        const artifactName = fields.name || name.slice(0, -5)
        const urlPath = (fields.url || '').split('?')[0]
        const urlExt = urlPath.endsWith('.tar.gz') ? 'gz' : (urlPath.split('.').pop() || 'bin')
        const cachePath = path.join(repoRoot, '.cache', `${artifactName}.${['pdf', 'zip', 'gz', 'xz', 'zst', 'tar', 'json', 'xml', 'txt'].includes(urlExt) ? urlExt : 'bin'}`)
        let cached = false
        let verified: boolean | null = null
        let bytes = 0
        try {
            const stat = fs.statSync(cachePath)
            cached = stat.isFile()
            bytes = stat.size
            if (cached && fields.sha256) {
                const hash = requireHash(cachePath)
                verified = hash === fields.sha256
            }
        } catch { /* absent external artifacts are normal */ }
        return {
            name: artifactName,
            title: fields.title || artifactName,
            purpose: fields.purpose || '',
            licence: fields.licence || '',
            url: fields.url || '',
            manifest: path.relative(repoRoot, manifestPath),
            cache: path.relative(repoRoot, cachePath),
            cached,
            verified,
            bytes,
            source_class: fields.purpose?.match(/machine-readable|formal|normative|vendor|comparison/i)?.[0] || 'source',
        }
    })
}

function requireHash(file: string): string {
    return crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex')
}

function productionRepos(repoRoot: string): Record<string, unknown>[] {
    const fields = parseFlatToml(readText(path.join(repoRoot, 'repos.toml'), 64 * 1024))
    const entries = ['standard', 'frontend', 'compiler', 'backend']
    return entries.map((id) => {
        const name = fields[`repos.${id}.path`] || id
        const abs = path.resolve(repoRoot, '..', name)
        const files: { path: string; bytes: number }[] = []
        const allowed = new Set(['src', 'app', 'test', 'tests', 'include', 'specs'])
        const visit = (dir: string, rel: string, depth: number) => {
            if (files.length >= 3000 || depth > 5) return
            let entries: fs.Dirent[]
            try { entries = fs.readdirSync(dir, { withFileTypes: true }) } catch { return }
            for (const entry of entries.sort((a, b) => a.name.localeCompare(b.name))) {
                const nextRel = rel ? `${rel}/${entry.name}` : entry.name
                const next = path.join(dir, entry.name)
                if (entry.isDirectory()) {
                    if (rel === '' && !allowed.has(entry.name)) continue
                    visit(next, nextRel, depth + 1)
                } else if (entry.isFile() && (rel === '' || allowed.has(rel.split('/')[0]))) {
                    if (/\.(f90|f95|f03|f08|f18|c|h|cc|cpp|fpp|sxs|sx|md|toml|yaml|yml|json|py|sh|mjs|mts|ts)$/.test(entry.name) || ['README.md', 'AGENTS.md', 'CLAUDE.md', 'fpm.toml'].includes(entry.name)) {
                        try { files.push({ path: nextRel, bytes: fs.statSync(next).size }) } catch { /* race */ }
                    }
                }
            }
        }
        try { if (fs.statSync(abs).isDirectory()) visit(abs, '', 0) } catch { /* not checked out */ }
        return {
            id,
            name,
            role: fields[`repos.${id}.role`] || '',
            path: path.relative(repoRoot, abs),
            present: files.length > 0,
            files,
        }
    })
}

const FLOWS: Record<string, Record<string, unknown>> = {
    production: {
        id: 'production', title: 'Specification → compiler pipeline',
        description: 'The language and target specifications meet only at the future MIR contract.',
        edges: [['pdf', 'standardir'], ['isa', 'targetir'], ['standardir', 'frontend'], ['frontend', 'mir'], ['mir', 'targetir'], ['targetir', 'object']],
        nodes: [
            { id: 'pdf', label: 'Normative PDF', kind: 'source', detail: 'Pinned source document and extracted text rectangles.', path: 'artifacts/standards/j3-24-007.toml' },
            { id: 'standardir', label: 'StandardIR', kind: 'artifact', detail: 'Source-backed syntax, definitions, constraints and semantic relations.', path: 'DESIGN.md', experiments: ['E0013', 'E0141'] },
            { id: 'frontend', label: 'Generated frontend', kind: 'mechanical', detail: 'Lexer/parser/AST and semantic engine generated from StandardIR.', repo: 'standard' },
            { id: 'mir', label: 'Small typed MIR', kind: 'gate', detail: 'Target-independent program representation. Contract first; no backend-specific encoding here.', repo: 'compiler', experiments: ['E0128', 'E0132', 'E0140'] },
            { id: 'isa', label: 'ISA / ABI / μarch sources', kind: 'source', detail: 'Machine-readable instructions, formal models, ABI documents and cost profiles.', path: 'artifacts/isa' },
            { id: 'targetir', label: 'TargetIR', kind: 'artifact', detail: 'Normalized target facts, encodings, registers, effects and relocations.', repo: 'backend', experiments: ['E0127', 'E0131', 'E0139', 'E0146'] },
            { id: 'object', label: 'Generated object code', kind: 'artifact', detail: 'Deterministic encoders, object writer and validated machine code.', repo: 'backend' },
        ],
    },
    syntax: {
        id: 'syntax', title: 'Normative syntax generation',
        description: 'One source-backed syntax record produces several comparison formats.',
        edges: [['pdf', 'extract'], ['extract', 'standardir'], ['standardir', 'exports'], ['exports', 'oracles']],
        nodes: [
            { id: 'pdf', label: 'PDF + text rectangles', kind: 'source', detail: 'Page, rule number and source span remain attached.' },
            { id: 'extract', label: 'Deterministic extraction', kind: 'mechanical', detail: 'Numbered productions are recovered without copying comparison grammars.', experiments: ['E0013', 'E0016'] },
            { id: 'standardir', label: 'Canonical StandardIR SX', kind: 'artifact', detail: 'The maintained syntax source for all projections.' },
            { id: 'exports', label: 'EBNF · ANTLR · Bison · tree-sitter', kind: 'mechanical', detail: 'Generated compatibility exports with rule provenance.', experiments: ['E0016', 'E0017', 'E0018', 'E0019', 'E0129', 'E0134'] },
            { id: 'oracles', label: 'Differential corpus checks', kind: 'gate', detail: 'Compare acceptance, inventories and parse structures without promoting comparison grammars.', experiments: ['E0020', 'E0021'] },
        ],
    },
    semantic: {
        id: 'semantic', title: 'Bounded semantic resolution',
        description: 'Mechanics supplies context and gates; the model fills only a typed local residue.',
        edges: [['source', 'mechanical'], ['mechanical', 'llm'], ['llm', 'gate'], ['gate', 'accepted'], ['gate', 'residue']],
        nodes: [
            { id: 'source', label: 'Rule + cited context', kind: 'source', detail: 'Numbered constraint, definitions, cross-references, page and hash.', experiments: ['E0115'] },
            { id: 'mechanical', label: 'Mechanical candidate', kind: 'mechanical', detail: 'Pattern extraction, source segmentation, known vocabulary and deterministic pre/post-processing.', experiments: ['E0115', 'E0123'] },
            { id: 'llm', label: 'Local Qwen proposal', kind: 'llm', detail: 'Small schema-valid ImplIR fragment; no wiring, promotion or architecture.', experiments: ['E0112', 'E0116', 'E0142'] },
            { id: 'gate', label: 'Source / replay / witness gate', kind: 'gate', detail: 'Independent validation decides accepted, disputed, unresolved or hard failure.', experiments: ['E0116', 'E0117', 'E0123'] },
            { id: 'accepted', label: 'Accepted StandardIR fact', kind: 'artifact', detail: 'Only witnessed, source-backed facts enter the ledger.' },
            { id: 'residue', label: 'Retained residue', kind: 'gate', detail: 'Failures and disagreements remain visible for the next protocol.' },
        ],
    },
    backend: {
        id: 'backend', title: 'Target specification → backend',
        description: 'Architectural truth, ABI facts and microarchitecture costs stay separate.',
        edges: [['sources', 'targetir'], ['targetir', 'tables'], ['tables', 'selection'], ['selection', 'object']],
        nodes: [
            { id: 'sources', label: 'ISA · formal · ABI · μarch', kind: 'source', detail: 'Browse pinned manifests and verified local caches in the source library.', path: 'artifacts/isa' },
            { id: 'targetir', label: 'TargetIR schema', kind: 'artifact', detail: 'Normalized instruction, register, effect, feature, ABI and relocation records.', repo: 'backend', experiments: ['E0127', 'E0131', 'E0139', 'E0146'] },
            { id: 'tables', label: 'Generated tables/codecs', kind: 'mechanical', detail: 'Encoders, decoders, register/feature tables and source-origin queries.' },
            { id: 'selection', label: 'MIR legalization / selection', kind: 'gate', detail: 'Starts only after the MIR boundary is stable; semantic equivalence precedes cost.', experiments: ['E0128', 'E0135'] },
            { id: 'object', label: 'Object / machine code', kind: 'artifact', detail: 'Final generated backend output and independent binary validation.' },
        ],
    },
}

export function flows(): Record<string, unknown>[] {
    return Object.values(FLOWS)
}

export function flow(id: string): Record<string, unknown> | null {
    return FLOWS[id] ?? null
}

export function library(repoRoot: string, root: string, provenance = loadProvenance(repoRoot)): Record<string, unknown> {
    const ledger = provenance.ledger.slice().reverse()
    const experiments = experimentManifests(repoRoot)
    const runsByExperiment = new Map<string, number>()
    for (const run of provenance.ledger) runsByExperiment.set(run.experiment, (runsByExperiment.get(run.experiment) ?? 0) + 1)
    for (const experiment of experiments) experiment.runs = runsByExperiment.get(String(experiment.id)) ?? 0
    const declared = experiments
        .map((item) => String(item.active_cell ?? '').match(/(E\d+\/R\d+(?:\/[^/]+)?)/)?.[1] ?? '')
        .filter(Boolean)
    const activeRefs = [...new Set([...declared, ...listRuns(root).slice(-12)])]
    const active_progress = activeRefs.map((ref) => ({ ref, progress: progress(root, ref) }))
    return {
        generated_at: new Date().toISOString(),
        progress: progressLanes(repoRoot),
        flows: flows(),
        experiments,
        decisions: decisions(repoRoot),
        isa_sources: artifactSources(repoRoot),
        production_repos: productionRepos(repoRoot),
        active_progress,
        recent_runs: ledger.slice(0, 100).map((run) => ({
            run: run.run, experiment: run.experiment, status: run.status, origin: run.origin,
            method: run.method, representation: run.representation, artifact: run.artifact,
            source: run.source,
        })),
        documents: runDocuments(root),
        roadmap: readText(path.join(repoRoot, 'ROADMAP.md'), 32 * 1024),
    }
}

export function ruleRegister(root: string): Record<string, unknown>[] {
    const rules: Record<string, unknown>[] = []
    for (const ref of listRuns(root)) {
        const run = resolveRun(root, ref)
        if (!run.ok) continue
        for (const entry of indexRunDirectory(run.abs, ref).entries.filter((item) => item.kind === 'sx')) {
            if (rules.length >= 12000) return rules
            const file = path.join(run.abs, entry.rel)
            const text = readText(file, 12 * 1024 * 1024)
            const doc = parseSx(text)
            for (const record of summarize(doc, text)) {
                rules.push({
                    id: record.id, label: record.label, head: record.head, source: record.source,
                    domain: entry.rel.includes('target') || entry.rel.includes('mir') ? 'target/mir' : 'standardir',
                    ref, path: entry.rel, index: record.index, line: record.line,
                })
                if (rules.length >= 12000) return rules
            }
        }
    }
    // Semantic rows are not SX rules, but they are still named rule-like
    // objects in the experiment corpus. Keeping them in the same register
    // makes the level explicit instead of forcing the reader to know which
    // JSONL file happened to hold a constraint.
    for (const ref of listRuns(root)) {
        const run = resolveRun(root, ref)
        if (!run.ok) continue
        for (const file of ['rows.jsonl', 'prompts.jsonl', 'responses.jsonl', 'gate-results.jsonl']) {
            for (const row of readJsonl(path.join(run.abs, file))) {
                if (rules.length >= 20000) return rules
                const id = caseKey(row)
                if (!id) continue
                rules.push({
                    id,
                    label: typeof row.label === 'string' ? row.label : (typeof row.name === 'string' ? row.name : id),
                    head: typeof row.status === 'string' ? row.status : file,
                    source: typeof row.source === 'string' ? row.source : (typeof row.citation === 'string' ? row.citation : ''),
                    domain: 'semantic', ref, path: file, index: null, line: null,
                })
            }
        }
    }
    return rules
}

export function sourceFile(repoRoot: string, repo: string, relative: string): { abs: string; path: string } | { error: string } {
    const fields = parseFlatToml(readText(path.join(repoRoot, 'repos.toml'), 64 * 1024))
    const ids = ['standard', 'frontend', 'compiler', 'backend']
    if (!ids.includes(repo)) return { error: 'unknown production repository' }
    if (relative.startsWith('/') || relative.includes('..') || relative.includes('\\') || relative.includes('\0')) return { error: 'unsafe source path' }
    const base = path.resolve(repoRoot, '..', fields[`repos.${repo}.path`] || repo)
    const abs = path.resolve(base, relative)
    const realBase = (() => { try { return fs.realpathSync(base) } catch { return base } })()
    let real: string
    try { real = fs.realpathSync(abs) } catch { return { error: 'source file not found' } }
    if (real !== realBase && !real.startsWith(`${realBase}${path.sep}`)) return { error: 'source path escapes repository' }
    if (!fs.statSync(real).isFile()) return { error: 'not a file' }
    const top = relative.split('/')[0]
    if (top && !['src', 'app', 'test', 'tests', 'include', 'specs'].includes(top) && !['README.md', 'AGENTS.md', 'CLAUDE.md', 'fpm.toml'].includes(relative)) return { error: 'source path is not allowlisted' }
    return { abs: real, path: relative }
}

export function isaFile(repoRoot: string, name: string): { abs: string; manifest: string; fields: Record<string, string> } | { error: string } {
    if (!/^[A-Za-z0-9._-]+$/.test(name)) return { error: 'unsafe artifact name' }
    const manifest = path.join(repoRoot, 'artifacts', 'isa', `${name}.toml`)
    if (!fs.existsSync(manifest)) return { error: 'unknown ISA artifact' }
    const fields = parseFlatToml(readText(manifest, 64 * 1024))
    const urlPath = (fields.url || '').split('?')[0]
    const ext = urlPath.endsWith('.tar.gz') ? 'gz' : (urlPath.split('.').pop() || 'bin')
    const suffix = ['pdf', 'zip', 'gz', 'xz', 'zst', 'tar', 'json', 'xml', 'txt'].includes(ext) ? ext : 'bin'
    const abs = path.join(repoRoot, '.cache', `${fields.name || name}.${suffix}`)
    if (!fs.existsSync(abs)) return { error: 'artifact is not cached; run scripts/fetch.sh --verify ' + (fields.name || name) }
    if (fields.sha256 && requireHash(abs) !== fields.sha256) return { error: 'cached artifact fails its manifest hash' }
    return { abs, manifest: path.relative(repoRoot, manifest), fields }
}

function caseKey(row: Record<string, unknown>): string | null {
    for (const key of ['name', 'row_key', 'constraint_id', 'id']) {
        if (typeof row[key] === 'string' && row[key] !== '') return row[key] as string
    }
    return null
}

function caseRecords(run: { abs: string }): Map<string, { file: string; row: Record<string, unknown> }[]> {
    const out = new Map<string, { file: string; row: Record<string, unknown> }[]>()
    const bases = [run.abs]
    if (!/^R\d+$/.test(path.basename(run.abs))) bases.push(path.dirname(run.abs))
    for (const base of [...new Set(bases)]) {
        for (const file of CASE_FILES) {
            for (const row of readJsonl(path.join(base, file))) {
                const key = caseKey(row)
                if (!key) continue
                const records = out.get(key) ?? []
                if (records.length < MAX_CASE_RECORDS) records.push({ file, row })
                out.set(key, records)
            }
        }
    }
    return out
}

export function cases(root: string, ref: string): Record<string, unknown>[] {
    const run = resolveRun(root, ref)
    if (!run.ok) return []
    const records = caseRecords(run)
    const base = CASE_FILES.flatMap((file) => readJsonl(path.join(run.abs, file)))
        .map((row) => caseKey(row)).filter((key): key is string => key !== '')
    return [...new Set(base)].map((key, index) => {
        const rows = records.get(key) ?? []
        const terminal = rows.find((item) => ['accepted', 'abstain', 'hard_failure', 'unresolved', 'reference-only'].includes(String(item.row.status)))
        return { index, key, status: terminal?.row.status ?? 'pending', records: rows.length }
    })
}

export function caseDetail(root: string, ref: string, index: number): Record<string, unknown> | { error: string } {
    const run = resolveRun(root, ref)
    if (!run.ok) return { error: run.reason }
    const available = cases(root, ref)
    const selected = available[index]
    if (!selected) return { error: 'no such case' }
    const records = caseRecords(run).get(String(selected.key)) ?? []
    const prompt = records.find((item) => item.file === 'prompts.jsonl')?.row ?? null
    const response = records.find((item) => item.file === 'responses.jsonl')?.row ?? null
    return { ...selected, prompt, response, records }
}

export function progress(root: string, ref: string): Record<string, unknown> {
    const run = resolveRun(root, ref)
    if (!run.ok) return { status: 'missing' }
    const progressFile = readJson(path.join(run.abs, 'progress.json'))
    if (progressFile) return progressFile
    const responseCount = readJsonl(path.join(run.abs, 'responses.jsonl')).length
    const promptCount = readJsonl(path.join(run.abs, 'prompts.jsonl')).length
    return {
        status: 'no-heartbeat', total: promptCount || null, completed: responseCount,
        remaining: promptCount ? Math.max(0, promptCount - responseCount) : null,
        eta_s: null, note: 'This run predates progress heartbeats or has not started its runner.',
    }
}
