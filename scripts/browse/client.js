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
    wrap: false,
    view: 'library',
    library: null,
    flow: null,
    rules: null,
    cases: null,
    caseIndex: 0,
    liveTimer: null,
}

const el = (id) => document.getElementById(id)

// The file list is a sidebar on a wide screen and a drawer over the content on
// a phone. Which one it is, is the stylesheet's decision; this only carries the
// open/closed bit, which is inert at widths where the sidebar is always shown.
function setNav(open) {
    document.body.classList.toggle('nav-open', open)
    el('nav-toggle').setAttribute('aria-expanded', String(open))
    el('nav-scrim').hidden = !open
}

function stopLiveRefresh() {
    if (state.liveTimer !== null) {
        clearInterval(state.liveTimer)
        state.liveTimer = null
    }
}

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
    const parts = [`view=${encodeURIComponent(state.view || 'library')}`]
    if (state.ref) parts.push(`ref=${encodeURIComponent(state.ref)}`)
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
    if (hash.view && hash.view !== 'run') {
        await showView(hash.view)
    } else if (hash.path || hash.ref) {
        await loadRun(hash.ref || root.focus, hash.path, hash.mode)
    } else {
        await showLibrary()
    }
}

async function loadRun(ref, wantPath, wantMode) {
    const run = await api('/api/run', { ref })
    state.ref = run.ref
    state.view = 'run'
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
        link.append(text('span', 'name', entry.rel), text('span', 'size', bytes(entry.bytes)))
        link.onclick = (event) => {
            event.preventDefault()
            setNav(false)
            openFile(entry.rel)
        }
        nav.append(link)
    }
    const provLink = document.createElement('a')
    provLink.href = '#'
    provLink.dataset.path = ''
    provLink.append(text('span', 'name', 'run provenance'))
    provLink.onclick = (event) => {
        event.preventDefault()
        setNav(false)
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
        button.dataset.mode = mode
        button.onclick = () => showMode(mode)
        tabs.append(button)
    }
    if (!file.binary && file.kind !== 'tsv') tabs.append(text('span', 'spacer'), wrapButton())
    await showMode(chosen)
}

// Soft wrap is a view setting, not a file setting: it survives moving between
// files, and it lives in memory only.
function wrapButton() {
    const button = text('button', state.wrap ? 'on' : null, 'wrap')
    button.id = 'wrap-toggle'
    button.title = 'soft-wrap long lines; line numbers are hidden while wrapped'
    button.onclick = () => {
        state.wrap = !state.wrap
        document.body.classList.toggle('wrap', state.wrap)
        button.classList.toggle('on', state.wrap)
    }
    return button
}

async function showMode(mode) {
    state.mode = mode
    for (const button of el('tabs').querySelectorAll('button[data-mode]')) {
        button.classList.toggle('on', button.dataset.mode === mode)
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
    // Capped only to bound the node, not to fit a width: the stylesheet elides
    // the preview against the actual pane.
    summary.append(head, text('span', 'dim', brief.slice(0, 300)))
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

function viewHeader(title, detail = '') {
    state.file = null
    el('file-head').replaceChildren(text('span', 'path', title), text('span', 'dim', detail))
    el('tabs').replaceChildren()
    el('files').replaceChildren()
    markActive(null)
}

function navButton(label, view, detail = '') {
    const link = document.createElement('a')
    link.href = '#'
    link.append(text('span', 'name', label), text('span', 'size', detail))
    link.onclick = (event) => {
        event.preventDefault()
        setNav(false)
        showView(view)
    }
    return link
}

function libraryNav() {
    const nav = el('files')
    nav.replaceChildren()
    nav.append(text('h2', null, 'start here'))
    nav.append(navButton('overview', 'library'))
    nav.append(navButton('documents', 'documents'))
    nav.append(navButton('live run', 'live'))
    nav.append(text('h2', null, 'explore'))
    nav.append(navButton('rule dictionary', 'rules'))
    nav.append(navButton('architecture', 'flows'))
    nav.append(navButton('source code', 'sources'))
    nav.append(text('h2', null, 'artifacts'))
    if (state.ref) nav.append(navButton('current run files', 'run'))
    nav.append(text('p', 'note', 'Choose a document first. Details open only when requested.'))
}

function progressCard(lane) {
    const total = Number(lane.total) || 0
    const completed = Number(lane.completed) || 0
    const percent = total ? Math.round(100 * completed / total) : 0
    const card = text('article', 'progress-card')
    const top = text('div', 'progress-top')
    top.append(text('strong', null, lane.title), text('span', 'progress-percent', `${percent}%  (${completed}/${total})`))
    const bar = text('div', 'progress-bar')
    const fill = text('div', 'progress-fill')
    fill.style.width = `${Math.max(0, Math.min(100, percent))}%`
    bar.append(fill)
    card.append(top, bar, text('p', 'dim', lane.basis))
    const evidence = document.createElement('details')
    evidence.append(text('summary', null, 'evidence'))
    evidence.append(text('p', 'dim', (lane.evidence || []).join(' · ')))
    card.append(evidence)
    return card
}

function linkButton(label, fn, className = '') {
    const button = text('button', className, label)
    button.onclick = fn
    return button
}

function section(title, body) {
    const details = document.createElement('details')
    details.open = true
    details.append(text('summary', null, title), body)
    return details
}

async function showLibrary() {
    stopLiveRefresh()
    state.view = 'library'
    libraryNav()
    viewHeader('research library', 'start with a document or follow the active run')
    const content = el('content')
    content.replaceChildren(text('p', 'note', 'loading library…'))
    const data = await api('/api/library')
    state.library = data
    const lanes = data.progress || []
    const total = lanes.reduce((sum, lane) => sum + (Number(lane.total) || 0), 0)
    const done = lanes.reduce((sum, lane) => sum + (Number(lane.completed) || 0), 0)
    const overall = total ? Math.round(100 * done / total) : 0
    const intro = text('div', 'library-intro')
    intro.append(text('h1', null, 'Specification-generated compiler laboratory'))
    intro.append(text('p', 'dim', 'Read the maintained evidence from the source document outward. The numbers below are named evidence gates, not code coverage.'))
    intro.append(text('p', 'progress-summary', `${overall}% of tracked gates (${done}/${total})`))
    intro.append(linkButton('refresh', () => showLibrary()))
    content.replaceChildren(intro)

    const cards = text('div', 'entry-grid')
    const entries = [
        ['standard', 'Standard document', 'PDF, extracted text and page index', 'standard'],
        ['standardir', 'StandardIR', 'Canonical SX, contracts and source facts', 'standardir'],
        ['grammar', 'Grammar exports', 'EBNF, ANTLR4, Bison and tree-sitter', 'grammar'],
        ['semantic', 'Semantic rules', 'Facts, residue, prompts and validation', 'semantic'],
        ['mir', 'MIR', 'Target-independent IR and handoff artifacts', 'mir'],
        ['backend', 'Backend and ISA', 'TargetIR, ABI, instruction and μarch sources', 'backend'],
    ]
    for (const [id, title, detail, level] of entries) {
        const card = text('button', 'entry-card')
        card.append(text('strong', null, title), text('span', 'dim', detail))
        card.onclick = () => showDocuments(level)
        cards.append(card)
    }
    content.append(text('h2', 'section-title', 'Start here'), cards)

    const active = (data.active_progress || []).find((item) => item.progress?.status === 'running') || (data.active_progress || []).find((item) => String(item.ref).includes('E0112'))
    const live = text('article', 'current-run-card')
    if (active) {
        const p = active.progress || {}
        live.append(text('strong', null, 'Active experiment'), text('p', 'dim', active.ref))
        live.append(text('p', null, `${p.completed || 0}/${p.total || '?'} cases · ${p.status || 'unknown'} · ${p.eta_s == null ? 'ETA appears in live view' : `ETA ${Math.ceil(p.eta_s)}s`}`))
        live.append(linkButton('follow live', () => showLive(active.ref)))
    } else {
        live.append(text('strong', null, 'No active run reported'), text('p', 'dim', 'Open run files from the run menu when a cell is available.'))
    }
    content.append(live)

    const progress = document.createElement('details')
    progress.className = 'home-section'
    progress.append(text('summary', null, `Progress by layer · ${overall}%`))
    const progressGrid = text('div', 'progress-grid')
    for (const lane of lanes) progressGrid.append(progressCard(lane))
    progress.append(progressGrid)
    content.append(progress)

    const more = document.createElement('details')
    more.className = 'home-section'
    more.append(text('summary', null, 'More ways to explore'))
    const buttons = text('div', 'button-row')
    buttons.append(linkButton('rule dictionary', () => showRules()), linkButton('architecture flows', () => showFlow()), linkButton('source code', () => showSources()), linkButton('all documents', () => showDocuments('all')))
    more.append(buttons)
    content.append(more)
    writeHash()
}

function rowOf(values, header = false) {
    const row = document.createElement('tr')
    for (const value of values) {
        const cell = document.createElement(header ? 'th' : 'td')
        cell.textContent = value == null ? '' : String(value)
        row.append(cell)
    }
    return row
}

async function showDocuments(level = 'all') {
    stopLiveRefresh()
    state.view = 'documents'
    libraryNav()
    viewHeader('documents', level === 'all' ? 'standard → IR → semantics → MIR → backend' : level)
    const content = el('content')
    content.replaceChildren(text('p', 'note', 'loading documents…'))
    const data = state.library || await api('/api/library')
    state.library = data
    const title = text('div', 'document-intro')
    title.append(text('h1', null, level === 'all' ? 'Evidence library' : `${level} documents`))
    title.append(text('p', 'dim', 'Each item has one authoritative location. Open it to see the actual PDF, extracted text, SX, grammar, prompt evidence or IR artifact.'))
    const choices = text('div', 'button-row')
    for (const item of [['all', 'all'], ['standard', 'standard'], ['standardir', 'StandardIR'], ['grammar', 'grammars'], ['semantic', 'semantics'], ['mir', 'MIR'], ['backend', 'backend']] ) {
        choices.append(linkButton(item[1], () => showDocuments(item[0]), item[0] === level ? 'on' : ''))
    }
    const filter = document.createElement('input')
    filter.className = 'wide-filter'
    filter.placeholder = 'filter documents, rules, formats, paths…'
    const list = text('div', 'document-list')
    content.replaceChildren(title, choices, filter, list)
    const render = () => {
        const needle = filter.value.trim().toLowerCase()
        list.replaceChildren()
        let shown = 0
        for (const doc of data.documents || []) {
            if (level !== 'all' && doc.level !== level) continue
            if (needle && !`${doc.title} ${doc.level} ${doc.kind} ${doc.description} ${doc.ref || ''} ${doc.path || ''}`.toLowerCase().includes(needle)) continue
            if (shown++ >= 240) break
            const row = text('article', 'document-row')
            const head = text('div', 'document-head')
            head.append(text('strong', null, doc.title), text('span', 'document-kind', `${doc.level} · ${doc.kind}`))
            row.append(head, text('p', 'dim', doc.description))
            row.append(text('p', 'document-location', doc.ref ? `${doc.ref}/${doc.path}` : (doc.research_path || doc.manifest || '')))
            if (doc.available) row.append(linkButton(doc.kind === 'pdf' ? 'open PDF' : 'open document', () => showLibraryDocument(doc)))
            else row.append(text('span', 'dim', 'not available in cache'))
            list.append(row)
        }
        if (!shown) list.append(text('p', 'empty', 'No matching documents in this level.'))
    }
    filter.oninput = render
    render()
    writeHash()
}

async function showLibraryDocument(doc) {
    stopLiveRefresh()
    state.view = 'document'
    libraryNav()
    viewHeader(doc.title, `${doc.level} · ${doc.ref ? `${doc.ref}/${doc.path}` : doc.research_path || doc.manifest || ''}`)
    const content = el('content')
    content.replaceChildren(text('p', 'note', 'loading document…'))
    const data = await api('/api/library-file', { id: doc.id })
    const intro = text('div', 'document-intro')
    intro.append(text('h1', null, doc.title), text('p', 'dim', doc.description))
    if (data.manifest) intro.append(text('p', 'document-location', `manifest: ${data.manifest}`))
    const raw = text('a', 'button-link', doc.kind === 'pdf' ? 'open PDF in new tab' : 'open raw bytes')
    raw.href = `/library-raw?id=${encodeURIComponent(doc.id)}`
    raw.target = '_blank'
    intro.append(raw)
    content.replaceChildren(intro)
    if (data.binary && data.kind === 'pdf') {
        const frame = document.createElement('iframe')
        frame.className = 'pdf-viewer'
        frame.src = `/library-raw?id=${encodeURIComponent(doc.id)}`
        frame.title = doc.title
        content.append(frame)
    } else if (data.binary) {
        content.append(text('p', 'note', `Binary artifact: ${bytes(data.bytes)}. SHA-256 ${data.sha256}`))
    } else {
        const code = text('div', 'code document-code')
        code.append(text('pre', 'gutter', data.gutter))
        const source = document.createElement('pre')
        source.innerHTML = data.html
        code.append(source)
        content.append(code)
    }
    writeHash()
}

async function refreshLive(ref, target) {
    try {
        const [progressData, caseData] = await Promise.all([
            api('/api/progress', { ref }),
            api('/api/cases', { ref }),
        ])
        const snapshot = progressData.progress || {}
        const items = caseData.cases || []
        target.replaceChildren()
        const top = text('div', 'live-summary')
        const completed = Number(snapshot.completed || 0)
        const total = Number(snapshot.total || items.length || 0)
        const percent = total ? Math.round(100 * completed / total) : 0
        top.append(text('h1', null, 'Live run'), text('p', 'dim', ref), text('p', null, `${completed}/${total || '?'} · ${snapshot.status || 'unknown'} · ${snapshot.eta_s == null ? 'ETA unavailable' : `ETA ${Math.ceil(snapshot.eta_s)}s`}`))
        const bar = text('div', 'progress-bar')
        const fill = text('div', 'progress-fill')
        fill.style.width = `${percent}%`
        bar.append(fill)
        top.append(bar)
        target.append(top)
        const columns = text('div', 'live-columns')
        const list = text('div', 'live-case-list')
        list.append(text('h2', null, 'inputs and outputs'))
        for (const item of items) {
            const button = text('button', item.index === state.caseIndex ? 'on' : '', `${item.index + 1}. ${item.key} · ${item.status}`)
            button.onclick = async () => {
                state.caseIndex = item.index
                await refreshLive(ref, target)
            }
            list.append(button)
        }
        if (!items.length) list.append(text('p', 'empty', 'The runner has not published a keyed input yet.'))
        const output = text('div', 'live-case-output')
        output.append(text('h2', null, 'selected case'))
        columns.append(list, output)
        target.append(columns)
        if (items.length) {
            const detail = await api('/api/case', { ref, i: state.caseIndex })
            output.append(text('h3', null, `${detail.key} · ${detail.status}`))
            output.append(text('p', 'dim', `${detail.records} related records; the panes below update as JSONL is appended.`))
            if (detail.prompt) output.append(section('input prompt', preJson(detail.prompt)))
            if (detail.response) output.append(section('model output', preJson(detail.response)))
            output.append(section('gate / trajectory records', preJson(detail.records)))
        }
        if (snapshot.status && snapshot.status !== 'running') stopLiveRefresh()
    } catch (error) {
        target.replaceChildren(text('p', 'status-bad', `live view unavailable: ${error.message || error}`))
    }
}

async function showLive(ref = state.ref) {
    stopLiveRefresh()
    state.view = 'live'
    if (ref) state.ref = ref
    libraryNav()
    viewHeader('live run', state.ref || 'no active run')
    const content = el('content')
    if (!state.ref) { content.replaceChildren(text('p', 'empty', 'No run selected.')); return }
    const controls = text('div', 'live-controls')
    const select = document.createElement('select')
    for (const item of state.library?.active_progress || []) {
        const option = document.createElement('option')
        option.value = item.ref
        option.textContent = item.ref
        select.append(option)
    }
    select.value = state.ref
    select.onchange = () => showLive(select.value)
    controls.append(text('span', 'dim', 'follow'), select, linkButton('stop live refresh', stopLiveRefresh))
    const target = text('div', 'live-target')
    content.replaceChildren(controls, target)
    await refreshLive(state.ref, target)
    if (!state.liveTimer) state.liveTimer = setInterval(() => refreshLive(state.ref, target), 2000)
    writeHash()
}

async function showFlow(id = 'production') {
    state.view = 'flows'
    libraryNav()
    viewHeader('pipeline flow', id)
    const content = el('content')
    content.replaceChildren(text('p', 'note', 'loading flow…'))
    const data = await api('/api/flow', { id })
    state.flow = data
    const chooser = text('div', 'button-row')
    for (const item of (state.library?.flows || [])) chooser.append(linkButton(item.title, () => showFlow(item.id), item.id === id ? 'on' : ''))
    content.replaceChildren(chooser, text('h1', null, data.title), text('p', 'dim', data.description))
    const nodes = new Map((data.nodes || []).map((node) => [node.id, node]))
    const chart = text('div', 'flow-chart')
    for (let i = 0; i < (data.nodes || []).length; i++) {
        const node = data.nodes[i]
        const box = text('article', `flow-node ${node.kind || ''}`)
        box.append(text('strong', null, node.label), text('p', 'dim', node.detail))
        if (node.experiments) box.append(text('p', 'dim', `evidence: ${node.experiments.join(' · ')}`))
        const action = node.repo ? linkButton(`open ${node.repo} source`, () => showSources(node.repo)) : node.path === 'artifacts/isa' ? linkButton('open backend documents', () => showDocuments('backend')) : node.path ? linkButton('open related record', () => showResearchFile(node.path)) : null
        if (action) box.append(action)
        chart.append(box)
        if (i + 1 < data.nodes.length) chart.append(text('div', 'flow-arrow', '↓'))
    }
    content.append(chart)
    const edges = text('p', 'dim', `Declared relations: ${(data.edges || []).map((edge) => `${edge[0]} → ${edge[1]}`).join('  ·  ')}`)
    content.append(edges)
    writeHash()
}

function jsonHtml(value) {
    const escaped = String(value).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    return escaped
        .replace(/(&quot;[^&]*?&quot;)(\s*:)/g, '<span class="t-field">$1</span>$2')
        .replace(/(&quot;.*?&quot;)/g, '<span class="t-str">$1</span>')
        .replace(/\b(true|false|null)\b/g, '<span class="t-kw">$1</span>')
        .replace(/\b-?\d+(?:\.\d+)?\b/g, '<span class="t-num">$1</span>')
}

function preJson(value) {
    const pre = document.createElement('pre')
    pre.className = 'case-json'
    pre.innerHTML = jsonHtml(JSON.stringify(value, null, 2))
    return pre
}

async function showRules() {
    state.view = 'rules'
    libraryNav()
    viewHeader('rule register', 'StandardIR · semantic · MIR · TargetIR levels')
    const content = el('content')
    content.replaceChildren(text('p', 'note', 'loading rule register…'))
    const data = await api('/api/rules')
    state.rules = data.rules || []
    content.replaceChildren(text('p', 'dim', `${state.rules.length} indexed entries; SX records remain linked to their run and source.`))
    const filter = document.createElement('input')
    filter.className = 'wide-filter'
    filter.placeholder = 'search id, label, source, level, run…'
    const list = text('div', 'rule-list')
    content.append(filter, list)
    const render = () => {
        const needle = filter.value.trim().toLowerCase()
        list.replaceChildren()
        let shown = 0
        for (const rule of state.rules) {
            if (needle && !`${rule.id} ${rule.label} ${rule.head} ${rule.source} ${rule.domain} ${rule.ref}`.toLowerCase().includes(needle)) continue
            if (shown++ >= 1000) break
            const row = text('div', 'rule-row')
            row.append(text('strong', null, rule.id || rule.head), text('span', 'rule-domain', rule.domain || 'unknown'), text('span', null, rule.label || rule.head))
            row.append(text('p', 'dim', `${rule.ref} · ${rule.path} · ${rule.source || 'no source field'}`))
            if (rule.index !== null && rule.path.endsWith('.sx')) row.append(linkButton('open SX record', () => loadRun(rule.ref, rule.path, 'tree')))
            else if (rule.domain === 'semantic') row.append(linkButton('open case set', () => showCases(rule.ref)))
            list.append(row)
        }
        if (shown === 0) list.append(text('p', 'empty', 'no matching rules'))
    }
    filter.oninput = render
    render()
    writeHash()
}

async function showCases(ref = state.ref) {
    state.view = 'cases'
    if (ref) state.ref = ref
    libraryNav()
    viewHeader('case browser', state.ref || 'no run selected')
    const content = el('content')
    content.replaceChildren(text('p', 'note', 'loading cases…'))
    if (!state.ref) { content.replaceChildren(text('p', 'empty', 'Select a run with case records first.')); return }
    const data = await api('/api/cases', { ref: state.ref })
    state.cases = data.cases || []
    state.caseIndex = Math.min(state.caseIndex, Math.max(0, state.cases.length - 1))
    const controls = text('div', 'case-controls')
    const select = document.createElement('select')
    for (const item of state.cases) {
        const option = document.createElement('option')
        option.value = item.index
        option.textContent = `${item.index + 1}. ${item.key} · ${item.status}`
        select.append(option)
    }
    select.value = String(state.caseIndex)
    const detail = text('div', 'case-detail')
    const render = async () => {
        state.caseIndex = Number(select.value)
        detail.replaceChildren(text('p', 'note', 'loading case…'))
        if (!state.cases.length) { detail.replaceChildren(text('p', 'empty', 'No keyed case records in this run.')); return }
        const item = await api('/api/case', { ref: state.ref, i: state.caseIndex })
        detail.replaceChildren(text('h2', null, `${item.key} · ${item.status}`), text('p', 'dim', `${item.records} related records`))
        if (item.prompt) detail.append(section('prompt', preJson(item.prompt)))
        if (item.response) detail.append(section('response', preJson(item.response)))
        detail.append(section('gate and trajectory records', preJson(item.records)))
    }
    select.onchange = render
    controls.append(select)
    controls.append(linkButton('previous', () => { if (state.caseIndex > 0) { select.value = String(--state.caseIndex); render() } }))
    controls.append(linkButton('next', () => { if (state.caseIndex + 1 < state.cases.length) { select.value = String(++state.caseIndex); render() } }))
    content.replaceChildren(controls, detail)
    await render()
    writeHash()
}

async function showSources(repoId = '') {
    state.view = 'sources'
    libraryNav()
    viewHeader('source library', 'production repositories and pinned ISA/ABI/μarch material')
    const content = el('content')
    const data = state.library || await api('/api/library')
    state.library = data
    const selector = document.createElement('select')
    for (const repo of data.production_repos || []) {
        const option = document.createElement('option')
        option.value = repo.id
        option.textContent = repo.name
        selector.append(option)
    }
    const fileList = text('div', 'source-list')
    const sourceView = text('div', 'source-view')
    const renderRepo = () => {
        const repo = (data.production_repos || []).find((item) => item.id === selector.value)
        fileList.replaceChildren()
        if (!repo || !repo.present) { fileList.append(text('p', 'empty', 'repository is not checked out')); return }
        const filter = document.createElement('input')
        filter.placeholder = 'filter source files'
        fileList.append(filter)
        const items = text('div', null)
        fileList.append(items)
        const render = () => {
            items.replaceChildren()
            const needle = filter.value.toLowerCase()
            for (const file of repo.files) {
                if (needle && !file.path.toLowerCase().includes(needle)) continue
                const link = text('a', null, `${file.path}  ${bytes(file.bytes)}`)
                link.href = '#'
                link.onclick = (event) => { event.preventDefault(); openSource(repo.id, file.path, sourceView) }
                items.append(link)
            }
        }
        filter.oninput = render
        render()
    }
    selector.value = repoId || data.production_repos?.[0]?.id || ''
    selector.onchange = renderRepo
    const top = text('div', 'source-toolbar')
    top.append(text('span', 'dim', 'production source'), selector)
    content.replaceChildren(top, text('div', 'source-browser'))
    const browser = content.querySelector('.source-browser')
    browser.append(fileList, sourceView)
    renderRepo()
    const isa = text('div', 'library-list')
    for (const item of data.isa_sources || []) {
        const row = text('div', 'library-row')
        row.append(text('strong', null, item.name), text('span', 'dim', item.cached ? (item.verified ? 'verified cache' : 'unverified cache') : 'manifest only'))
        row.append(text('p', 'dim', item.title + ' — ' + item.purpose))
        if (item.cached && item.verified) row.append(linkButton('open artifact', () => showIsa(item.name)))
        isa.append(row)
    }
    content.append(section('pinned ISA / ABI / microarchitecture material', isa))
    writeHash()
}

async function openSource(repo, file, target) {
    target.replaceChildren(text('p', 'note', 'loading source…'))
    const data = await api('/api/source-file', { repo, path: file })
    target.replaceChildren(text('h2', 'note', `${repo}/${file}`))
    const code = text('div', 'code')
    const gutter = text('pre', 'gutter', data.gutter)
    const source = document.createElement('pre')
    source.innerHTML = data.html
    code.append(gutter, source)
    target.append(code)
}

async function showIsa(name) {
    state.view = 'sources'
    libraryNav()
    viewHeader('cached external source', name)
    const content = el('content')
    const data = await api('/api/isa-file', { name })
    content.replaceChildren(text('h2', 'note', data.path), definitionList(Object.entries(data.fields || {})))
    if (data.binary) content.append(text('p', 'note', `binary artifact; raw bytes are available only when the format is safe to render (${bytes(data.bytes)}). sha256 ${data.sha256}`))
    else {
        const code = text('div', 'code')
        code.append(text('pre', 'gutter', data.gutter))
        const source = document.createElement('pre')
        source.innerHTML = data.html
        code.append(source)
        content.append(code)
    }
    writeHash()
}

async function showResearchFile(file) {
    viewHeader('research record', file)
    const content = el('content')
    const data = await api('/api/research-file', { path: file })
    content.replaceChildren(text('h2', 'note', data.path))
    const pre = document.createElement('pre')
    pre.textContent = data.text
    content.append(pre)
    writeHash()
}

async function showView(view) {
    if (view === 'run') return loadRun(state.ref || state.root?.focus)
    if (view === 'documents') return showDocuments()
    if (view === 'live') return showLive()
    if (view === 'rules') return showRules()
    if (view === 'flows') return showFlow()
    if (view === 'sources') return showSources()
    if (view === 'cases') return showCases()
    return showLibrary()
}

el('nav-toggle').onclick = () => setNav(!document.body.classList.contains('nav-open'))
el('nav-scrim').onclick = () => setNav(false)
el('home-button').onclick = () => { setNav(false); showLibrary() }
document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') setNav(false)
})

el('jump-form').onsubmit = async (event) => {
    event.preventDefault()
    const query = el('jump').value.trim()
    if (!query) return
    setNav(false)
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
