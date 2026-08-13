// The three-hop join this tool exists to make cheap.
//
//   .cache/runs/E0074/R000001/summary.tsv      the artifact a run produced
//   artifacts/runs/E0074/R000001-summary.toml  its manifest, with hash and origin
//   research/runs/2026-08.jsonl  "run":"R000083"  the ledger entry citing it
//
// The manifest names the cache path, and the ledger entry names the manifest,
// so the map is derived from the data in both directions. Nothing is inferred
// from filenames when a field is available; the filename is only a fallback.

import * as fs from 'node:fs'
import * as path from 'node:path'

export type Manifest = {
    manifestPath: string // repository-relative
    fields: Record<string, string>
    runRef: string | null // E0074/R000001
    fileRel: string | null // path inside the run directory
}

export type LedgerRun = {
    run: string
    experiment: string
    status: string
    origin: string
    method: string
    representation: string
    artifact: string | null
    record: Record<string, unknown>
    source: string // the jsonl file it came from, repository-relative
}

export type Provenance = {
    manifests: Manifest[]
    ledger: LedgerRun[]
    runsByRef: Map<string, { manifests: Manifest[]; ledger: LedgerRun[] }>
    refByLedgerRun: Map<string, string>
}

// Flat TOML: `key = value` lines, `[section]` headers, `#` comments. lib.sh
// documents that the repository writes nothing else, and a real parser would
// be a dependency this tool has decided not to have.
export function parseFlatToml(text: string): Record<string, string> {
    const out: Record<string, string> = {}
    let section = ''
    for (const raw of text.split('\n')) {
        const line = raw.trim()
        if (line === '' || line.startsWith('#')) continue
        if (line.startsWith('[')) {
            const end = line.indexOf(']')
            if (end > 0) section = line.slice(1, end).trim()
            continue
        }
        const eq = line.indexOf('=')
        if (eq < 0) continue
        const key = line.slice(0, eq).trim()
        if (key === '') continue
        let value = line.slice(eq + 1).trim()
        if (value.startsWith('"')) {
            let literal = ''
            let i = 1
            for (; i < value.length; i++) {
                const ch = value[i]
                if (ch === '\\' && i + 1 < value.length) {
                    literal += value[i + 1]
                    i++
                    continue
                }
                if (ch === '"') break
                literal += ch
            }
            value = literal
        } else {
            const hash = value.indexOf('#')
            if (hash >= 0) value = value.slice(0, hash).trim()
        }
        out[section === '' ? key : `${section}.${key}`] = value
    }
    return out
}

function runRefOf(manifestPath: string, fields: Record<string, string>): { runRef: string | null; fileRel: string | null } {
    const cachePath = fields.path ?? ''
    const fromField = /^\.cache\/runs\/(E\d+)\/(R\d+)\/(.+)$/.exec(cachePath)
    if (fromField) return { runRef: `${fromField[1]}/${fromField[2]}`, fileRel: fromField[3] }
    const fromName = /(?:^|\/)(E\d+)\/(R\d+)-[^/]*\.toml$/.exec(manifestPath)
    if (fromName) return { runRef: `${fromName[1]}/${fromName[2]}`, fileRel: null }
    return { runRef: null, fileRel: null }
}

function collectToml(dir: string, repoRoot: string, out: string[]): void {
    let entries: fs.Dirent[]
    try {
        entries = fs.readdirSync(dir, { withFileTypes: true })
    } catch {
        return
    }
    for (const entry of entries.sort((a, b) => (a.name < b.name ? -1 : 1))) {
        const abs = path.join(dir, entry.name)
        if (entry.isDirectory()) collectToml(abs, repoRoot, out)
        else if (entry.isFile() && entry.name.endsWith('.toml')) out.push(path.relative(repoRoot, abs))
    }
}

export function loadProvenance(repoRoot: string): Provenance {
    const manifests: Manifest[] = []
    const manifestPaths: string[] = []
    collectToml(path.join(repoRoot, 'artifacts'), repoRoot, manifestPaths)
    for (const rel of manifestPaths.sort()) {
        let text: string
        try {
            text = fs.readFileSync(path.join(repoRoot, rel), 'utf8')
        } catch {
            continue
        }
        const fields = parseFlatToml(text)
        const { runRef, fileRel } = runRefOf(rel, fields)
        manifests.push({ manifestPath: rel, fields, runRef, fileRel })
    }

    const ledger: LedgerRun[] = []
    const runsDir = path.join(repoRoot, 'research', 'runs')
    let runFiles: string[] = []
    try {
        runFiles = fs
            .readdirSync(runsDir)
            .filter((n) => n.endsWith('.jsonl'))
            .sort()
    } catch {
        runFiles = []
    }
    for (const name of runFiles) {
        const text = fs.readFileSync(path.join(runsDir, name), 'utf8')
        for (const line of text.split('\n')) {
            if (line.trim() === '') continue
            let record: Record<string, unknown>
            try {
                record = JSON.parse(line) as Record<string, unknown>
            } catch {
                continue // a malformed line is the ledger's problem, not the viewer's
            }
            ledger.push({
                run: String(record.run ?? ''),
                experiment: String(record.experiment ?? ''),
                status: String(record.status ?? ''),
                origin: String(record.origin ?? ''),
                method: String(record.method ?? ''),
                representation: String(record.representation ?? ''),
                artifact: typeof record.artifact === 'string' ? record.artifact : null,
                record,
                source: `research/runs/${name}`,
            })
        }
    }

    const runsByRef = new Map<string, { manifests: Manifest[]; ledger: LedgerRun[] }>()
    const bucket = (ref: string) => {
        let entry = runsByRef.get(ref)
        if (!entry) {
            entry = { manifests: [], ledger: [] }
            runsByRef.set(ref, entry)
        }
        return entry
    }
    const manifestByPath = new Map(manifests.map((m) => [m.manifestPath, m]))
    for (const manifest of manifests) {
        if (manifest.runRef) bucket(manifest.runRef).manifests.push(manifest)
    }
    const refByLedgerRun = new Map<string, string>()
    for (const run of ledger) {
        if (!run.artifact) continue
        const manifest = manifestByPath.get(run.artifact)
        const ref = manifest?.runRef ?? null
        if (!ref) continue
        bucket(ref).ledger.push(run)
        refByLedgerRun.set(run.run, ref)
    }
    return { manifests, ledger, runsByRef, refByLedgerRun }
}

export function manifestForFile(prov: Provenance, runRef: string, fileRel: string): Manifest | null {
    const entry = prov.runsByRef.get(runRef)
    if (!entry) return null
    return entry.manifests.find((m) => m.fileRel === fileRel) ?? null
}

// Accepts `E0074/R000001`, `R000083`, `E0074` or a cache path, and answers with
// a run reference. This is the cross-navigation the ledger's R-numbers need.
export function resolveReference(prov: Provenance, query: string, knownRefs: string[]): string | null {
    const text = query.trim().replace(/^\.?\/*/, '').replace(/\/+$/, '')
    if (text === '') return null
    const cache = /^\.?cache\/runs\/(E\d+\/R\d+)/.exec(text) ?? /^(E\d+\/R\d+)/.exec(text)
    if (cache && knownRefs.includes(cache[1])) return cache[1]
    if (/^R\d+$/.test(text)) {
        const ref = prov.refByLedgerRun.get(text)
        if (ref && knownRefs.includes(ref)) return ref
        // Cache directories number runs per experiment, so a bare R-number may
        // also be a directory name. Only answer when it is unambiguous.
        const matches = knownRefs.filter((r) => r.endsWith(`/${text}`))
        if (matches.length === 1) return matches[0]
        return null
    }
    if (/^E\d+$/.test(text)) {
        const matches = knownRefs.filter((r) => r.startsWith(`${text}/`))
        return matches.length > 0 ? matches[0] : null
    }
    return null
}
