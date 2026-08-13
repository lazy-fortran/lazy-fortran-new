// Plain DOM client. No framework, no build step, no dependencies.
//
// The server sends already-highlighted HTML for file content and JSON for
// everything structural. This file decides what to ask for and where to put it.

const state = {
    root: null,
    ref: null,
    index: null,
    provenance: null,
    file: null,
    mode: 'raw',
    records: null,
    record: null,
}

const el = (id) => document.getElementById(id)

async function api(path, params) {
    const url = new URL(path, location.origin)
    for (const [k, v] of Object.entries(params || {})) url.searchParams.set(k, v)
    const response = await fetch(url, { cache: 'no-store' })
    const body = await response.json()
    if (!response.ok) throw new Error(body.error || `${response.status}`)
    return body
}

function text(tag, className, content) {
    const node = document.createElement(tag)
    if (className) node.className = className
    if (content !== undefined) node.textContent = content
    return node
}

function bytes(n) {
    if (n < 1024) return `${n} B`
    if (n < 1024 * 1024) return `${(n / 1024).toFixed(1)} kB`
    return `${(n / (1024 * 1024)).toFixed(1)} MB`
}

const SECTION_TITLES = {
    standardir: 'StandardIR SX',
    grammar: 'grammar projections',
    fortran: 'generated Fortran',
    metrics: 'metrics and records',
    logs: 'logs',
    other: 'other',
}

function writeHash() {
    const parts = [`ref=${encodeURIComponent(state.ref || '')}`]
    if (state.file) parts.push(`path=${encodeURIComponent(state.file.path)}`)
    if (state.mode !== 'raw') parts.push(`mode=${state.mode}`)
    history.replaceState(null, '', `#${parts.join('&')}`)
}

function readHash() {
    const out = {}
    for (const part of location.hash.replace(/^#/, '').split('&')) {
        const eq = part.indexOf('=')
        if (eq > 0) out[part.slice(0, eq)] = decodeURIComponent(part.slice(eq + 1))
    }
    return out
}

async function loadRoot() {
    const root = await api('/api/root')
    state.root = root
    el('root-path').textContent = root.root
    const select = el('run-select')
    select.replaceChildren()
    for (const run of root.runs) {
        const option = document.createElement('option')
        option.value = run.ref
        option.textContent = run.ledger.length ? `${run.canonical}  (${run.ledger.join(', ')})` : run.canonical
        select.append(option)
    }
    select.onchange = () => loadRun(select.value)
    const hash = readHash()
    await loadRun(hash.ref || root.focus, hash.path, hash.mode)
}

async function loadRun(ref, wantPath, wantMode) {
    const run = await api('/api/run', { ref })
    state.ref = run.ref
    state.index = run
    state.provenance = run.provenance
    el('run-select').value = run.ref

    const ledger = run.provenance.ledger
    const meta = el('run-meta')
    meta.replaceChildren()
    if (ledger.length === 0) {
        meta.append(text('span', 'dim', 'no ledger run cites this directory'))
    } else {
        for (const entry of ledger) {
            const tag = text('span', entry.status === 'accepted' ? 'status-good' : 'status-bad')
            tag.textContent = `${entry.run} ${entry.status} ${entry.origin}`
            tag.title = `${entry.representation}\n${entry.source}`
            meta.append(tag)
        }
    }

    const nav = el('files')
    nav.replaceChildren()
    let section = null
    for (const entry of run.entries) {
        if (entry.section !== section) {
            section = entry.section
            nav.append(text('h2', null, SECTION_TITLES[section] || section))
        }
        const link = document.createElement('a')
        link.href = '#'
        link.dataset.path = entry.rel
        link.append(text('span', 'size', bytes(entry.bytes)), document.createTextNode(entry.rel))
        link.onclick = (event) => {
            event.preventDefault()
            openFile(entry.rel)
        }
        nav.append(link)
    }
    const provLink = document.createElement('a')
    provLink.href = '#'
    provLink.dataset.path = ''
    provLink.textContent = 'run provenance'
    provLink.onclick = (event) => {
        event.preventDefault()
        showRunProvenance()
    }
    nav.prepend(provLink)

    const first = wantPath || pickDefault(run.entries)
    if (first) await openFile(first, wantMode)
    else showRunProvenance()
}

function pickDefault(entries) {
    const sx = entries.find((e) => e.kind === 'sx')
    if (sx) return sx.rel
    return entries.length ? entries[0].rel : null
}

function markActive(path) {
    for (const link of el('files').querySelectorAll('a')) {
        link.classList.toggle('active', link.dataset.path === path)
    }
}

async function openFile(path, wantMode) {
    const file = await api('/api/file', { ref: state.ref, path })
    state.file = file
    state.records = null
    state.record = null
    markActive(path)

    const head = el('file-head')
    head.replaceChildren()
    head.append(text('span', 'path', file.path), text('span', 'dim', `${file.kind}  ${bytes(file.bytes)}`))
    if (!file.binary) head.append(text('span', 'dim', `${file.lines} lines`))
    const hash = text('span', 'dim', `sha256 ${file.sha256.slice(0, 12)}…`)
    hash.title = file.sha256
    head.append(hash)
    if (file.hashMatch === true) head.append(text('span', 'status-good', 'matches manifest'))
    if (file.hashMatch === false) head.append(text('span', 'status-bad', 'differs from manifest'))
    const raw = document.createElement('a')
    raw.href = `/raw?ref=${encodeURIComponent(state.ref)}&path=${encodeURIComponent(file.path)}`
    raw.textContent = 'bytes'
    raw.target = '_blank'
    head.append(raw)
    if (file.truncated) head.append(text('span', 'status-bad', 'view truncated'))

    const modes = ['raw']
    if (file.kind === 'sx') modes.push('tree')
    modes.push('provenance')
    const chosen = modes.includes(wantMode) ? wantMode : 'raw'
    const tabs = el('tabs')
    tabs.replaceChildren()
    for (const mode of modes) {
        const button = text('button', mode === chosen ? 'on' : null, mode)
        button.onclick = () => showMode(mode)
        tabs.append(button)
    }
    await showMode(chosen)
}

async function showMode(mode) {
    state.mode = mode
    for (const button of el('tabs').querySelectorAll('button')) {
        button.classList.toggle('on', button.textContent === mode)
    }
    if (mode === 'raw') showRaw()
    else if (mode === 'tree') await showTree()
    else showFileProvenance()
    writeHash()
}

function showRaw() {
    const content = el('content')
    content.replaceChildren()
    const file = state.file
    if (file.binary) {
        content.append(text('p', 'note', `binary file, ${bytes(file.bytes)}, not rendered. sha256 ${file.sha256}`))
        return
    }
    if (file.kind === 'tsv') {
        const wrap = document.createElement('div')
        wrap.innerHTML = file.html
        content.append(wrap)
        return
    }
    const wrap = text('div', 'code')
    const gutter = text('pre', 'gutter', file.gutter)
    const code = document.createElement('pre')
    code.innerHTML = file.html
    wrap.append(gutter, code)
    content.append(wrap)
}

async function showTree() {
    const content = el('content')
    content.replaceChildren(text('p', 'note', 'reading SX…'))
    const data = await api('/api/sx', { ref: state.ref, path: state.file.path })
    state.records = data.records
    const wrap = text('div', 'sx')
    const list = text('div', 'sx-list')
    const filter = document.createElement('input')
    filter.placeholder = `filter ${data.records.length} records`
    list.append(filter)
    const items = document.createElement('div')
    list.append(items)
    const tree = text('div', 'sx-tree')
    wrap.append(list, tree)
    content.replaceChildren()
    if (data.errors.length) {
        content.append(text('p', 'status-bad', `${data.errors.length} unreadable form(s): ${data.errors[0].message} at line ${data.errors[0].line}`))
    }
    content.append(wrap)

    const render = () => {
        const needle = filter.value.trim().toLowerCase()
        items.replaceChildren()
        let shown = 0
        for (const record of data.records) {
            const haystack = `${record.id} ${record.label} ${record.head}`.toLowerCase()
            if (needle && !haystack.includes(needle)) continue
            if (shown++ > 800) break
            const link = document.createElement('a')
            link.href = '#'
            link.dataset.index = String(record.index)
            link.append(text('span', 'id', record.id || record.head), document.createTextNode(record.label))
            link.onclick = (event) => {
                event.preventDefault()
                openRecord(record.index, items, tree)
            }
            items.append(link)
        }
    }
    filter.oninput = render
    render()
    if (data.records.length) openRecord(state.record ?? data.records[0].index, items, tree)
}

async function openRecord(index, items, tree) {
    state.record = index
    for (const link of items.querySelectorAll('a')) {
        link.classList.toggle('active', link.dataset.index === String(index))
    }
    const record = await api('/api/sx/record', { ref: state.ref, path: state.file.path, i: index })
    tree.replaceChildren()
    tree.append(text('div', 'dim', `form ${index}, line ${record.line}`))
    tree.append(renderNode(record.tree, 0))
    const raw = document.createElement('pre')
    raw.innerHTML = record.html
    const details = document.createElement('details')
    details.append(text('summary', null, 'raw form'), raw)
    tree.append(details)
}

const atomText = (node) => (node.q ? JSON.stringify(node.a) : node.a)

// A list renders as a <details>; native disclosure needs no script to toggle.
// A list whose operands are all atoms has nothing to expand, so it renders as
// one line instead.
function renderNode(node, depth) {
    if (node.a !== undefined) {
        const leaf = text('div', 'leaf')
        leaf.append(text('span', node.q ? 't-str' : 't-atom', atomText(node)))
        return leaf
    }
    const headAtom = node.l.length && node.l[0].a !== undefined ? node.l[0].a : ''
    const operands = node.l.slice(headAtom ? 1 : 0)
    const head = text('span', 't-kw', headAtom || '()')
    if (operands.every((child) => child.a !== undefined)) {
        const leaf = text('div', 'leaf')
        leaf.append(head, document.createTextNode(` ${operands.map(atomText).join(' ')}`))
        return leaf
    }
    const details = document.createElement('details')
    if (depth < 2) details.open = true
    const brief = operands
        .map((child) => (child.a !== undefined ? atomText(child) : `(${child.l.length && child.l[0].a !== undefined ? child.l[0].a : '…'} …)`))
        .join(' ')
    const summary = document.createElement('summary')
    summary.append(head, document.createTextNode(' '), text('span', 'dim', brief.slice(0, 110)))
    details.append(summary)
    for (const child of operands) details.append(renderNode(child, depth + 1))
    return details
}

function definitionList(pairs) {
    const dl = text('dl', 'kv')
    for (const [key, value] of pairs) {
        dl.append(text('dt', null, key), text('dd', null, value))
    }
    return dl
}

function showFileProvenance() {
    const content = el('content')
    content.replaceChildren()
    const file = state.file
    if (!file.manifest) {
        content.append(text('p', 'note', 'no artifact manifest names this file'))
        showRunProvenanceInto(content)
        return
    }
    content.append(text('h2', 'note', file.manifest.manifestPath))
    content.append(definitionList(Object.entries(file.manifest.fields)))
    showRunProvenanceInto(content)
}

function showRunProvenance() {
    state.file = null
    markActive(null)
    el('file-head').replaceChildren(text('span', 'path', state.ref))
    el('tabs').replaceChildren()
    const content = el('content')
    content.replaceChildren()
    showRunProvenanceInto(content)
    writeHash()
}

function showRunProvenanceInto(content) {
    const prov = state.provenance
    content.append(text('h2', 'note', 'ledger runs citing this directory'))
    if (prov.ledger.length === 0) content.append(text('p', 'note', 'none'))
    for (const entry of prov.ledger) {
        content.append(
            definitionList([
                ['run', entry.run],
                ['experiment', entry.experiment],
                ['status', entry.status],
                ['origin', entry.origin],
                ['method', entry.method],
                ['representation', entry.representation],
                ['artifact', entry.artifact || ''],
                ['record', entry.source],
                ['verification', JSON.stringify(entry.record.verification || {})],
            ]),
        )
    }
    content.append(text('h2', 'note', 'artifact manifests'))
    if (prov.manifests.length === 0) content.append(text('p', 'note', 'none'))
    for (const manifest of prov.manifests) {
        const link = text('div', 'dim', `${manifest.manifestPath}  ->  ${manifest.fileRel || '(no cache path)'}`)
        content.append(link)
    }
}

el('jump-form').onsubmit = async (event) => {
    event.preventDefault()
    const query = el('jump').value.trim()
    if (!query) return
    try {
        const found = await api('/api/resolve', { q: query })
        await loadRun(found.ref)
    } catch (err) {
        el('run-meta').replaceChildren(text('span', 'status-bad', String(err.message || err)))
    }
}

loadRoot().catch((err) => {
    document.body.append(text('p', 'status-bad', String(err.message || err)))
})
