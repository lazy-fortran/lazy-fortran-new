// SX reader.
//
// D0006 fixes the format: `form := atom | integer | string | "(" form* ")"`,
// nothing else. The lexical details here mirror the canonical Fortran reader,
// standard-new `src/fortsx.f90`: whitespace is space and tab (newlines separate
// the line-per-form documents this repository writes), a bare atom ends at
// whitespace or `)`, a quoted atom accepts `\"` and `\\` and no other escape,
// and there is no comment syntax. Reading SX any other way here would make the
// viewer disagree with the writer that produced the file.

export type SxAtom = { k: 'atom'; v: string; quoted: boolean }
export type SxList = { k: 'list'; c: SxNode[] }
export type SxNode = SxAtom | SxList

export type SxForm = {
    index: number
    line: number // 1-based line of the form's first character
    start: number // byte-equivalent character offset into the document
    end: number
    node: SxNode
}

export type SxError = { line: number; offset: number; message: string }

export type SxDocument = {
    forms: SxForm[]
    errors: SxError[]
}

function isSpace(ch: string): boolean {
    return ch === ' ' || ch === '\t' || ch === '\n' || ch === '\r'
}

class Reader {
    text: string
    pos: number
    constructor(text: string) {
        this.text = text
        this.pos = 0
    }
    skipSpace(): void {
        while (this.pos < this.text.length && isSpace(this.text[this.pos])) this.pos++
    }
    // Throws on malformed input; the caller turns that into a recorded error.
    readForm(depth: number): SxNode {
        if (depth > 200) throw new Error('SX nesting too deep')
        this.skipSpace()
        if (this.pos >= this.text.length) throw new Error('unexpected end of SX form')
        const ch = this.text[this.pos]
        if (ch === '(') return this.readList(depth)
        if (ch === '"') return this.readQuoted()
        if (ch === ')') throw new Error('unexpected closing parenthesis')
        const start = this.pos
        while (this.pos < this.text.length) {
            const c = this.text[this.pos]
            if (isSpace(c) || c === ')') break
            this.pos++
        }
        if (this.pos === start) throw new Error('empty SX atom')
        return { k: 'atom', v: this.text.slice(start, this.pos), quoted: false }
    }
    readQuoted(): SxAtom {
        this.pos++ // the opening quote
        let value = ''
        while (this.pos < this.text.length) {
            const ch = this.text[this.pos]
            if (ch === '"') {
                this.pos++
                return { k: 'atom', v: value, quoted: true }
            }
            if (ch === '\\') {
                this.pos++
                if (this.pos >= this.text.length) throw new Error('unterminated SX escape')
                const esc = this.text[this.pos]
                if (esc !== '"' && esc !== '\\') throw new Error(`unsupported SX escape \\${esc}`)
                value += esc
                this.pos++
                continue
            }
            value += ch
            this.pos++
        }
        throw new Error('unclosed SX quoted atom')
    }
    readList(depth: number): SxList {
        this.pos++ // the opening parenthesis
        const items: SxNode[] = []
        for (;;) {
            this.skipSpace()
            if (this.pos >= this.text.length) throw new Error('unclosed SX list')
            if (this.text[this.pos] === ')') {
                this.pos++
                return { k: 'list', c: items }
            }
            items.push(this.readForm(depth + 1))
        }
    }
}

function lineOf(lineStarts: number[], offset: number): number {
    let lo = 0
    let hi = lineStarts.length - 1
    while (lo < hi) {
        const mid = (lo + hi + 1) >> 1
        if (lineStarts[mid] <= offset) lo = mid
        else hi = mid - 1
    }
    return lo + 1
}

export function parseSx(text: string): SxDocument {
    const lineStarts = [0]
    for (let i = 0; i < text.length; i++) if (text[i] === '\n') lineStarts.push(i + 1)

    const reader = new Reader(text)
    const forms: SxForm[] = []
    const errors: SxError[] = []
    for (;;) {
        reader.skipSpace()
        if (reader.pos >= text.length) break
        const start = reader.pos
        try {
            const node = reader.readForm(0)
            forms.push({ index: forms.length, line: lineOf(lineStarts, start), start, end: reader.pos, node })
        } catch (err) {
            errors.push({
                line: lineOf(lineStarts, start),
                offset: start,
                message: err instanceof Error ? err.message : String(err),
            })
            // Resynchronize on the next line: this repository writes one form
            // per line, so a bad form costs one record and not the document.
            const nextLine = text.indexOf('\n', start)
            if (nextLine < 0) break
            reader.pos = nextLine + 1
        }
    }
    return { forms, errors }
}

export function head(node: SxNode): string {
    if (node.k === 'atom') return node.v
    const first = node.c[0]
    return first && first.k === 'atom' ? first.v : ''
}

// The `(key value ...)` child of a list, if there is one.
export function child(node: SxNode, key: string): SxList | null {
    if (node.k !== 'list') return null
    for (const item of node.c) {
        if (item.k === 'list' && head(item) === key) return item
    }
    return null
}

function atomsOf(list: SxList | null): string[] {
    if (!list) return []
    return list.c.slice(1).flatMap((n) => (n.k === 'atom' ? [n.v] : []))
}

export type SxRecord = {
    index: number
    line: number
    bytes: number
    head: string // `syntax`, `standardir`, ...
    id: string // `R401` when the second element is an atom
    label: string // `(lhs ...)` when present, else the id
    source: Record<string, string> // flattened `(source ...)` fields
    text: string // the raw form, for the raw view and for search
}

// Flatten `(source (document J3-24-007) (clause 5-15) ...)` to key/value pairs.
function flatFields(list: SxList | null): Record<string, string> {
    const out: Record<string, string> = {}
    if (!list) return out
    for (const item of list.c.slice(1)) {
        if (item.k !== 'list') continue
        const key = head(item)
        if (key === '') continue
        out[key] = atomsOf(item).join(' ')
    }
    return out
}

export function summarize(doc: SxDocument, text: string): SxRecord[] {
    return doc.forms.map((form) => {
        const node = form.node
        const id = node.k === 'list' && node.c[1] && node.c[1].k === 'atom' ? node.c[1].v : ''
        const lhs = atomsOf(child(node, 'lhs')).join(' ')
        return {
            index: form.index,
            line: form.line,
            bytes: form.end - form.start,
            head: head(node),
            id,
            label: lhs !== '' ? lhs : id,
            source: flatFields(child(node, 'source')),
            text: text.slice(form.start, form.end),
        }
    })
}
