// Read-only syntax highlighting, written here rather than depended on.
//
// D0039 rejects a general highlighter as a dependency. What is needed instead
// is one small tokenizer per format this repository actually generates. Each is
// an ordered alternation scanned left to right: the first rule that matches at
// a position wins, and text no rule matches is escaped and emitted plain. A
// tokenizer that is wrong shows the wrong colour; it never changes the bytes,
// which are always available through the raw endpoint.

import type { Kind } from './index.mts'

type Rule = { cls: string; re: string }

export function escapeHtml(text: string): string {
    return text
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
}

// Number of capture groups a pattern contributes, so rules may contain their
// own groups without breaking the mapping from match index back to rule.
function groupCount(source: string): number {
    return new RegExp(`${source}|`).exec('')!.length - 1
}

function scan(text: string, rules: Rule[], flags: string): string {
    if (rules.length === 0) return escapeHtml(text)
    const combined = new RegExp(rules.map((r) => `(${r.re})`).join('|'), `g${flags}`)
    const owner: number[] = []
    let group = 1
    rules.forEach((rule, index) => {
        owner[group] = index
        group += 1 + groupCount(rule.re)
    })
    let out = ''
    let last = 0
    for (const match of text.matchAll(combined)) {
        const start = match.index
        if (start > last) out += escapeHtml(text.slice(last, start))
        let ruleIndex = -1
        for (const key of Object.keys(owner)) {
            const g = Number(key)
            if (match[g] !== undefined) {
                ruleIndex = owner[g]
                break
            }
        }
        const cls = ruleIndex >= 0 ? rules[ruleIndex].cls : 'plain'
        out += `<span class="t-${cls}">${escapeHtml(match[0])}</span>`
        last = start + match[0].length
        if (match[0].length === 0) last = start + 1 // never loop on an empty match
    }
    if (last < text.length) out += escapeHtml(text.slice(last))
    return out
}

const STRING_DQ = '"(?:\\\\.|[^"\\\\])*"'
const STRING_SQ = "'(?:\\\\.|[^'\\\\])*'"

const RULES: Record<string, { rules: Rule[]; flags: string }> = {
    // SX: the head atom of a list is the operator, so it is highlighted apart
    // from the operands. That is the only structural claim made here.
    sx: {
        rules: [
            { cls: 'str', re: STRING_DQ },
            { cls: 'kw', re: '(?<=\\()[^\\s()"]+' },
            { cls: 'punct', re: '[()]' },
            { cls: 'num', re: '(?<![\\w-])-?\\d+(?![\\w-])' },
            { cls: 'atom', re: '[^\\s()"]+' },
        ],
        flags: '',
    },
    ebnf: {
        rules: [
            { cls: 'comment', re: '\\(\\*[\\s\\S]*?\\*\\)' },
            { cls: 'str', re: STRING_DQ },
            { cls: 'op', re: '::=' },
            { cls: 'punct', re: '[{}\\[\\]|;]' },
            { cls: 'ident', re: '[A-Za-z_][A-Za-z0-9_-]*' },
        ],
        flags: '',
    },
    antlr: {
        rules: [
            { cls: 'comment', re: '//[^\\n]*|/\\*[\\s\\S]*?\\*/' },
            { cls: 'str', re: STRING_SQ },
            { cls: 'kw', re: '\\b(?:grammar|fragment|lexer|parser|options|tokens|channels|import|returns|locals|mode|skip|channel)\\b' },
            { cls: 'def', re: '^[A-Za-z_][A-Za-z0-9_]*' },
            { cls: 'punct', re: '[:;|()*+?~]' },
            { cls: 'ident', re: '[A-Za-z_][A-Za-z0-9_]*' },
        ],
        flags: 'm',
    },
    bison: {
        rules: [
            { cls: 'comment', re: '//[^\\n]*|/\\*[\\s\\S]*?\\*/' },
            { cls: 'kw', re: '%%|%[a-z]+' },
            { cls: 'str', re: `${STRING_DQ}|${STRING_SQ}` },
            { cls: 'def', re: '^[A-Za-z_][A-Za-z0-9_.]*(?=\\s*:)' },
            { cls: 'punct', re: '[:;|]' },
            { cls: 'ident', re: '[A-Za-z_][A-Za-z0-9_.]*' },
        ],
        flags: 'm',
    },
    treesitter: {
        rules: [
            { cls: 'comment', re: '//[^\\n]*|/\\*[\\s\\S]*?\\*/' },
            { cls: 'str', re: `${STRING_DQ}|${STRING_SQ}|\`(?:\\\\.|[^\`\\\\])*\`` },
            { cls: 'field', re: '\\$\\.[A-Za-z0-9_]+' },
            { cls: 'kw', re: '\\b(?:module|exports|require|const|let|var|function|return|grammar|name|rules)\\b' },
            { cls: 'builtin', re: '\\b(?:seq|choice|repeat1|repeat|optional|prec|token|field|alias)\\b' },
            { cls: 'num', re: '\\b\\d+\\b' },
            { cls: 'punct', re: '[{}()\\[\\],:;=>]' },
        ],
        flags: '',
    },
    fortran: {
        rules: [
            { cls: 'comment', re: '![^\\n]*' },
            { cls: 'str', re: "'(?:[^'\\n]|'')*'|\"(?:[^\"\\n]|\"\")*\"" },
            {
                cls: 'kw',
                re:
                    '\\b(?:module|submodule|endmodule|program|subroutine|function|end|contains|use|only|implicit|none|' +
                    'intent|in|out|inout|type|class|integer|real|logical|character|complex|allocatable|pointer|' +
                    'target|parameter|private|public|protected|save|call|return|select|case|default|if|then|else|' +
                    'elseif|endif|do|while|exit|cycle|associate|where|forall|block|interface|procedure|result|' +
                    'pure|elemental|recursive|optional|len|kind|dimension|allocate|deallocate|nullify|stop|' +
                    'error|print|write|read|open|close|format|generic|abstract|extends|deferred|import)\\b',
            },
            { cls: 'num', re: '\\b\\d+(?:\\.\\d*)?(?:[eEdD][-+]?\\d+)?(?:_\\w+)?\\b' },
            { cls: 'op', re: '::|=>|==|/=|<=|>=|\\.(?:and|or|not|eqv|neqv|true|false)\\.' },
        ],
        flags: 'i',
    },
    json: {
        rules: [
            { cls: 'str', re: `${STRING_DQ}(?=\\s*:)` },
            { cls: 'field', re: STRING_DQ },
            { cls: 'num', re: '-?\\b\\d+(?:\\.\\d+)?(?:[eE][-+]?\\d+)?\\b' },
            { cls: 'kw', re: '\\b(?:true|false|null)\\b' },
            { cls: 'punct', re: '[{}\\[\\],:]' },
        ],
        flags: '',
    },
    toml: {
        rules: [
            { cls: 'comment', re: '#[^\\n]*' },
            { cls: 'str', re: STRING_DQ },
            { cls: 'def', re: '^\\[[^\\]\\n]*\\]' },
            { cls: 'field', re: '^[A-Za-z_][A-Za-z0-9_.-]*(?=\\s*=)' },
            { cls: 'num', re: '\\b\\d+\\b' },
        ],
        flags: 'm',
    },
    log: {
        rules: [
            { cls: 'bad', re: '^.*\\b(?:error|Error|ERROR|fatal|FAIL)\\b.*$' },
            { cls: 'warn', re: '^.*\\b(?:warning|Warning|WARNING)\\b.*$' },
        ],
        flags: 'm',
    },
}

RULES.jsonl = RULES.json
RULES.java = RULES.treesitter

export function highlight(kind: Kind, text: string): string {
    const spec = RULES[kind]
    if (!spec) return escapeHtml(text)
    return scan(text, spec.rules, spec.flags)
}

// Tab-separated metric files are read as tables, not as text: `summary.tsv` is
// the run's headline numbers and reading it in a monospace column is the point.
export function tsvTable(text: string): string {
    const rows = text.split('\n').filter((line) => line !== '')
    if (rows.length === 0) return '<p class="empty">empty</p>'
    const cells = rows.map((row) => row.split('\t'))
    const width = Math.max(...cells.map((c) => c.length))
    const body = cells
        .map((row, i) => {
            const tag = i === 0 ? 'th' : 'td'
            const filled = [...row, ...Array(Math.max(0, width - row.length)).fill('')]
            return `<tr>${filled.map((c) => `<${tag}>${escapeHtml(c)}</${tag}>`).join('')}</tr>`
        })
        .join('\n')
    return `<table class="tsv">${body}</table>`
}

export function gutter(lines: number): string {
    let out = ''
    for (let i = 1; i <= lines; i++) out += `${i}\n`
    return out
}
