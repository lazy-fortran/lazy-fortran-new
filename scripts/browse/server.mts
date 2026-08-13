// The viewer's HTTP surface: loopback only, GET and HEAD only, read only.
//
// Every response that carries file content passes through `resolveInRoot`, so
// there is exactly one place where a path becomes a file. Static assets are a
// fixed map rather than a path join, because a viewer's own directory is not a
// document root.

import * as crypto from 'node:crypto'
import * as fs from 'node:fs'
import * as http from 'node:http'
import * as path from 'node:path'
import { fileURLToPath } from 'node:url'
import { indexRunDirectory, listRuns, resolveRun, type Kind } from './index.mts'
import { gutter, highlight, tsvTable } from './highlight.mts'
import { loadProvenance, manifestForFile, resolveReference, type Provenance } from './provenance.mts'
import { parseSx, summarize, type SxDocument, type SxNode } from './sx.mts'
import { resolveInRoot } from './paths.mts'

const HERE = path.dirname(fileURLToPath(import.meta.url))

const MAX_CONTENT = 4 * 1024 * 1024 // bytes read for any single view
const MAX_HIGHLIGHT = 2 * 1024 * 1024 // above this the text is served unhighlighted

export type ServerOptions = {
    root: string // already realpath'd and allowlisted
    repoRoot: string
    // Canonical `E<NNNN>/R<NNNNNN>` prefix of the root, empty when the root is
    // the run cache itself. Serving a single run directly still has to look its
    // provenance up under the reference the manifests and ledger use.
    rootRef: string
    focus: string // run reference the client opens on
    port: number
    host: string
}

type FileView = {
    ref: string
    path: string
    kind: Kind
    bytes: number
    sha256: string
    truncated: boolean
    binary: boolean
    lines: number
    html: string
    gutter: string
    manifest: { manifestPath: string; fields: Record<string, string> } | null
    hashMatch: boolean | null
}

function json(res: http.ServerResponse, status: number, body: unknown): void {
    const text = JSON.stringify(body)
    res.writeHead(status, {
        'content-type': 'application/json; charset=utf-8',
        'cache-control': 'no-store',
        'x-content-type-options': 'nosniff',
    })
    res.end(text)
}

function send(res: http.ServerResponse, status: number, type: string, body: string | Buffer): void {
    res.writeHead(status, {
        'content-type': type,
        'cache-control': 'no-store',
        'x-content-type-options': 'nosniff',
    })
    res.end(body)
}

function readBounded(abs: string): { text: string; truncated: boolean; sha256: string } {
    const buffer = fs.readFileSync(abs)
    const sha256 = crypto.createHash('sha256').update(buffer).digest('hex')
    const truncated = buffer.length > MAX_CONTENT
    const slice = truncated ? buffer.subarray(0, MAX_CONTENT) : buffer
    return { text: slice.toString('utf8'), truncated, sha256 }
}

function looksBinary(kind: Kind, text: string): boolean {
    if (kind === 'binary') return true
    return text.slice(0, 8000).includes('\0')
}

// One parsed SX document is kept, keyed by identity and mtime. This is a memo
// for the open file, not a cache with a lifetime: it holds at most one entry.
let sxMemo: { key: string; doc: SxDocument; text: string } | null = null

function sxDocument(abs: string): { doc: SxDocument; text: string } {
    const stat = fs.statSync(abs)
    const key = `${abs}:${stat.mtimeMs}:${stat.size}`
    if (sxMemo && sxMemo.key === key) return { doc: sxMemo.doc, text: sxMemo.text }
    const text = fs.readFileSync(abs, 'utf8')
    const doc = parseSx(text)
    sxMemo = { key, doc, text }
    return { doc, text }
}

// A run reference as the manifests and the ledger spell it.
export function provRefOf(opts: ServerOptions, ref: string): string {
    if (opts.rootRef === '') return ref
    return ref === '.' ? opts.rootRef : `${opts.rootRef}/${ref}`
}

function nodeToJson(node: SxNode): unknown {
    if (node.k === 'atom') return { a: node.v, q: node.quoted }
    return { l: node.c.map(nodeToJson) }
}

function buildFileView(opts: ServerOptions, prov: Provenance, ref: string, rel: string): FileView | { error: string } {
    const run = resolveRun(opts.root, ref)
    if (!run.ok) return { error: `run: ${run.reason}` }
    const joined = run.ref === '.' ? rel : `${run.ref}/${rel}`
    const resolved = resolveInRoot(opts.root, joined)
    if (!resolved.ok) return { error: resolved.reason }
    const stat = fs.statSync(resolved.abs)
    if (!stat.isFile()) return { error: 'not a file' }
    const entry = indexRunDirectory(run.abs, run.ref).entries.find((e) => e.rel === rel)
    const kind: Kind = entry?.kind ?? 'text'
    const { text, truncated, sha256 } = readBounded(resolved.abs)
    const binary = looksBinary(kind, text)

    const manifest = manifestForFile(prov, provRefOf(opts, run.ref), rel)
    const declared = manifest?.fields.sha256 ?? null
    const hashMatch = declared ? declared === sha256 : null

    let html = ''
    if (binary) {
        html = ''
    } else if (kind === 'tsv') {
        html = tsvTable(text)
    } else if (text.length > MAX_HIGHLIGHT) {
        html = highlight('text', text)
    } else {
        html = highlight(kind, text)
    }
    const lines = binary ? 0 : text.split('\n').length
    return {
        ref: run.ref,
        path: rel,
        kind,
        bytes: stat.size,
        sha256,
        truncated,
        binary,
        lines,
        html,
        gutter: binary || kind === 'tsv' ? '' : gutter(lines),
        manifest: manifest ? { manifestPath: manifest.manifestPath, fields: manifest.fields } : null,
        hashMatch,
    }
}

export function startServer(opts: ServerOptions): http.Server {
    const prov = loadProvenance(opts.repoRoot)
    const refs = listRuns(opts.root)

    const staticFiles: Record<string, { file: string; type: string }> = {
        '/': { file: 'shell.html', type: 'text/html; charset=utf-8' },
        '/static/client.js': { file: 'client.js', type: 'text/javascript; charset=utf-8' },
        '/static/style.css': { file: 'style.css', type: 'text/css; charset=utf-8' },
    }

    const server = http.createServer((req, res) => {
        if (req.method !== 'GET' && req.method !== 'HEAD') {
            send(res, 405, 'text/plain; charset=utf-8', 'GET and HEAD only\n')
            return
        }
        // A loopback-only viewer should still refuse a request that reached it
        // under some other name, which is the cheap half of rebinding defence.
        const host = (req.headers.host ?? '').split(':')[0]
        if (host !== '127.0.0.1' && host !== 'localhost' && host !== '[::1]' && host !== '::1') {
            send(res, 403, 'text/plain; charset=utf-8', 'unexpected Host header\n')
            return
        }
        const url = new URL(req.url ?? '/', 'http://127.0.0.1')
        const query = url.searchParams

        try {
            const asset = staticFiles[url.pathname]
            if (asset) {
                send(res, 200, asset.type, fs.readFileSync(path.join(HERE, asset.file)))
                return
            }

            if (url.pathname === '/api/root') {
                json(res, 200, {
                    root: opts.root,
                    repoRoot: opts.repoRoot,
                    focus: opts.focus,
                    runs: refs.map((ref) => ({
                        ref,
                        canonical: provRefOf(opts, ref),
                        ledger: (prov.runsByRef.get(provRefOf(opts, ref))?.ledger ?? []).map((l) => l.run),
                        experiment: provRefOf(opts, ref).split('/')[0],
                    })),
                })
                return
            }

            if (url.pathname === '/api/resolve') {
                const canonical = refs.map((ref) => provRefOf(opts, ref))
                const found = resolveReference(prov, query.get('q') ?? '', canonical)
                const ref = found === null ? null : refs[canonical.indexOf(found)]
                json(res, ref ? 200 : 404, ref ? { ref, canonical: found } : { error: 'no run matches' })
                return
            }

            if (url.pathname === '/api/run') {
                const run = resolveRun(opts.root, query.get('ref') ?? opts.focus)
                if (!run.ok) {
                    json(res, 400, { error: run.reason })
                    return
                }
                const index = indexRunDirectory(run.abs, run.ref)
                const entry = prov.runsByRef.get(provRefOf(opts, run.ref))
                json(res, 200, {
                    ...index,
                    canonical: provRefOf(opts, run.ref),
                    provenance: {
                        manifests: (entry?.manifests ?? []).map((m) => ({
                            manifestPath: m.manifestPath,
                            fileRel: m.fileRel,
                            fields: m.fields,
                        })),
                        ledger: (entry?.ledger ?? []).map((l) => ({
                            run: l.run,
                            experiment: l.experiment,
                            status: l.status,
                            origin: l.origin,
                            method: l.method,
                            representation: l.representation,
                            artifact: l.artifact,
                            source: l.source,
                            record: l.record,
                        })),
                    },
                })
                return
            }

            if (url.pathname === '/api/file') {
                const view = buildFileView(opts, prov, query.get('ref') ?? opts.focus, query.get('path') ?? '')
                if ('error' in view) {
                    json(res, 400, view)
                    return
                }
                json(res, 200, view)
                return
            }

            if (url.pathname === '/raw') {
                const run = resolveRun(opts.root, query.get('ref') ?? opts.focus)
                if (!run.ok) {
                    send(res, 400, 'text/plain; charset=utf-8', `${run.reason}\n`)
                    return
                }
                const rel = query.get('path') ?? ''
                const joined = run.ref === '.' ? rel : `${run.ref}/${rel}`
                const resolved = resolveInRoot(opts.root, joined)
                if (!resolved.ok) {
                    send(res, 400, 'text/plain; charset=utf-8', `${resolved.reason}\n`)
                    return
                }
                const buffer = fs.readFileSync(resolved.abs)
                send(res, 200, 'text/plain; charset=utf-8', buffer.subarray(0, MAX_CONTENT))
                return
            }

            if (url.pathname === '/api/sx' || url.pathname === '/api/sx/record') {
                const run = resolveRun(opts.root, query.get('ref') ?? opts.focus)
                if (!run.ok) {
                    json(res, 400, { error: run.reason })
                    return
                }
                const rel = query.get('path') ?? ''
                const joined = run.ref === '.' ? rel : `${run.ref}/${rel}`
                const resolved = resolveInRoot(opts.root, joined)
                if (!resolved.ok) {
                    json(res, 400, { error: resolved.reason })
                    return
                }
                const { doc, text } = sxDocument(resolved.abs)
                if (url.pathname === '/api/sx') {
                    const records = summarize(doc, text).map((r) => ({
                        index: r.index,
                        line: r.line,
                        bytes: r.bytes,
                        head: r.head,
                        id: r.id,
                        label: r.label,
                        source: r.source,
                    }))
                    json(res, 200, { records, errors: doc.errors, forms: doc.forms.length })
                    return
                }
                const i = Number(query.get('i') ?? '-1')
                const form = doc.forms[i]
                if (!form) {
                    json(res, 404, { error: 'no such record' })
                    return
                }
                json(res, 200, {
                    index: i,
                    line: form.line,
                    tree: nodeToJson(form.node),
                    text: text.slice(form.start, form.end),
                    html: highlight('sx', text.slice(form.start, form.end)),
                })
                return
            }

            send(res, 404, 'text/plain; charset=utf-8', 'not found\n')
        } catch (err) {
            const message = err instanceof Error ? err.message : String(err)
            send(res, 500, 'text/plain; charset=utf-8', `${message}\n`)
        }
    })

    server.listen(opts.port, opts.host)
    return server
}
