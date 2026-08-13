// Command line for the run browser. `scripts/browse.sh` is the entry point.

import * as fs from 'node:fs'
import * as path from 'node:path'
import { fileURLToPath } from 'node:url'
import { indexRunDirectory, listRuns, resolveRun } from './index.mts'
import { loadProvenance, resolveReference } from './provenance.mts'
import { realRoot } from './paths.mts'
import { provRefOf, startServer, type ServerOptions } from './server.mts'

const REPO_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..')
const DEFAULT_ROOT = path.join(REPO_ROOT, '.cache', 'runs')
const DEFAULT_PORT = 7373

const USAGE = `usage: scripts/browse.sh <serve|index> [options]

  serve                  read-only viewer on 127.0.0.1
  index                  print the deterministic file index and stop

  --root DIR             allowlisted root, default .cache/runs
  --run REF              run to open: E0074/R000001, R000083, or E0074
  --run-dir DIR          serve one run directory as the whole root
  --port N               default ${DEFAULT_PORT}
  --json                 index as JSON rather than a table
`

type Options = {
    command: string
    root: string
    run: string | null
    runDir: string | null
    port: number
    json: boolean
}

function parseArgs(argv: string[]): Options {
    const opts: Options = { command: '', root: DEFAULT_ROOT, run: null, runDir: null, port: DEFAULT_PORT, json: false }
    const rest = [...argv]
    while (rest.length > 0) {
        const arg = rest.shift()!
        const value = () => {
            const next = rest.shift()
            if (next === undefined) die(`${arg} needs a value`)
            return next!
        }
        switch (arg) {
            case '--root':
                opts.root = value()
                break
            case '--run':
                opts.run = value()
                break
            case '--run-dir':
                opts.runDir = value()
                break
            case '--port':
                opts.port = Number(value())
                break
            case '--json':
                opts.json = true
                break
            case '-h':
            case '--help':
                process.stdout.write(USAGE)
                process.exit(0)
                break
            default:
                if (arg.startsWith('-')) die(`unknown option: ${arg}`)
                else if (opts.command === '') opts.command = arg
                else die(`unexpected argument: ${arg}`)
        }
    }
    return opts
}

function die(message: string): never {
    process.stderr.write(`error: ${message}\n`)
    process.exit(2)
}

// Turn the options into a root, its canonical run reference, and the run the
// client should open on. `--run-dir` narrows the allowlist to one run.
function resolveTargets(opts: Options): ServerOptions {
    let rootPath = opts.root
    let rootRef = ''
    if (opts.runDir) {
        rootPath = opts.runDir
    }
    if (!fs.existsSync(rootPath)) die(`root does not exist: ${rootPath}`)
    const root = realRoot(rootPath)
    const cacheRuns = fs.existsSync(DEFAULT_ROOT) ? realRoot(DEFAULT_ROOT) : DEFAULT_ROOT
    if (root !== cacheRuns) {
        const relative = path.relative(cacheRuns, root)
        if (/^E\d+\/R\d+$/.test(relative)) rootRef = relative
    }

    const prov = loadProvenance(REPO_ROOT)
    const refs = listRuns(root)
    if (refs.length === 0) die(`no run directories under ${root}`)
    let focus = refs[0]
    if (opts.run) {
        const canonical = refs.map((ref) => (rootRef === '' ? ref : ref === '.' ? rootRef : `${rootRef}/${ref}`))
        const found = resolveReference(prov, opts.run, canonical)
        if (!found) die(`no run under ${root} matches ${opts.run}`)
        focus = refs[canonical.indexOf(found)]
    }
    return { root, repoRoot: REPO_ROOT, rootRef, focus, port: opts.port, host: '127.0.0.1' }
}

function printIndex(server: ServerOptions, asJson: boolean): void {
    const run = resolveRun(server.root, server.focus)
    if (!run.ok) die(`run: ${run.reason}`)
    const index = indexRunDirectory(run.abs, run.ref)
    const prov = loadProvenance(server.repoRoot)
    const canonical = provRefOf(server, run.ref)
    const entry = prov.runsByRef.get(canonical)
    if (asJson) {
        process.stdout.write(
            `${JSON.stringify({
                root: server.root,
                run: canonical,
                entries: index.entries,
                truncated: index.truncated,
                manifests: (entry?.manifests ?? []).map((m) => ({ manifestPath: m.manifestPath, fileRel: m.fileRel })),
                ledger: (entry?.ledger ?? []).map((l) => ({ run: l.run, status: l.status, artifact: l.artifact })),
            })}\n`,
        )
        return
    }
    process.stdout.write(`run       ${canonical}\n`)
    process.stdout.write(`directory ${run.abs}\n`)
    const ledger = (entry?.ledger ?? []).map((l) => `${l.run} (${l.status})`).join(', ')
    process.stdout.write(`ledger    ${ledger === '' ? 'no ledger run cites this directory' : ledger}\n`)
    process.stdout.write(`files     ${index.entries.length}${index.truncated ? ' (truncated)' : ''}\n\n`)
    const manifestFor = new Map((entry?.manifests ?? []).map((m) => [m.fileRel ?? '', m.manifestPath]))
    for (const file of index.entries) {
        process.stdout.write(
            `${file.section.padEnd(10)} ${file.kind.padEnd(11)} ${String(file.bytes).padStart(9)}  ${file.rel}` +
                `${manifestFor.has(file.rel) ? `  <- ${manifestFor.get(file.rel)}` : ''}\n`,
        )
    }
}

function main(): void {
    const opts = parseArgs(process.argv.slice(2))
    if (opts.command === '') {
        process.stdout.write(USAGE)
        process.exit(2)
    }
    const server = resolveTargets(opts)
    if (opts.command === 'index') {
        printIndex(server, opts.json)
        return
    }
    if (opts.command !== 'serve') die(`unknown command: ${opts.command}`)

    const handle = startServer(server)
    handle.on('listening', () => {
        process.stdout.write(`root  ${server.root}\n`)
        process.stdout.write(`run   ${provRefOf(server, server.focus)}\n`)
        process.stdout.write(`open  http://127.0.0.1:${server.port}/\n`)
        process.stdout.write('stop  Ctrl-C\n')
    })
    handle.on('error', (err) => die(String(err)))
    for (const signal of ['SIGINT', 'SIGTERM'] as const) {
        process.on(signal, () => {
            handle.close()
            process.exit(0)
        })
    }
}

main()
