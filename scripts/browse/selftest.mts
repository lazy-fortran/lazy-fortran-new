// Checks for the three parts of this tool that can be wrong silently: the path
// allowlist, the run-to-manifest-to-ledger join, and file discovery. Each test
// builds its own fixture in a temporary directory and states the expected
// answer independently, so a test passes because the behaviour is right and not
// because it agrees with whatever the code currently does.
//
// The allowlist tests carry a negative control in the same style as
// scripts/selftest.sh gate 4: the escaping path is shown to reach outside the
// root under a naive resolver, so a test that passes is evidence the check did
// something.

import * as assert from 'node:assert/strict'
import * as fs from 'node:fs'
import * as os from 'node:os'
import * as path from 'node:path'
import { checkRelative, isInside, realRoot, resolveInRoot } from './paths.mts'
import { classify, indexRunDirectory, listRuns, resolveRun } from './index.mts'
import { loadProvenance, manifestForFile, parseFlatToml, resolveReference } from './provenance.mts'
import { parseSx, summarize } from './sx.mts'
import { highlight, tsvTable } from './highlight.mts'

let failures = 0
let checks = 0

function check(name: string, body: () => void): void {
    checks++
    process.stdout.write(`${name.padEnd(70)}`)
    try {
        body()
        process.stdout.write('ok\n')
    } catch (err) {
        failures++
        process.stdout.write('FAIL\n')
        const message = err instanceof Error ? (err.stack ?? err.message) : String(err)
        process.stdout.write(`${message.split('\n').slice(0, 6).join('\n')}\n`)
    }
}

function tempDir(): string {
    return fs.mkdtempSync(path.join(os.tmpdir(), 'lf-browse-test-'))
}

// ------------------------------------------------------------------ allowlist

check('allowlist accepts a file inside the root', () => {
    const dir = tempDir()
    fs.mkdirSync(path.join(dir, 'root', 'E0900', 'R000007'), { recursive: true })
    fs.writeFileSync(path.join(dir, 'root', 'E0900', 'R000007', 'a.sx'), '(x)\n')
    const root = realRoot(path.join(dir, 'root'))
    const result = resolveInRoot(root, 'E0900/R000007/a.sx')
    assert.equal(result.ok, true)
    if (result.ok) {
        assert.equal(fs.readFileSync(result.abs, 'utf8'), '(x)\n')
        assert.equal(result.rel, 'E0900/R000007/a.sx')
    }
})

check('allowlist rejects parent traversal, and the target really is outside', () => {
    const dir = tempDir()
    fs.mkdirSync(path.join(dir, 'root'), { recursive: true })
    fs.writeFileSync(path.join(dir, 'secret.txt'), 'not for the browser\n')
    const root = realRoot(path.join(dir, 'root'))
    const escape = '../secret.txt'

    // Negative control: a resolver without the check reads the file, so the
    // rejection below is not vacuous.
    const naive = path.resolve(root, escape)
    assert.equal(fs.readFileSync(naive, 'utf8'), 'not for the browser\n')
    assert.equal(isInside(root, naive), false)

    const result = resolveInRoot(root, escape)
    assert.equal(result.ok, false)
    if (!result.ok) assert.equal(result.reason, 'parent traversal')
})

check('allowlist rejects absolute paths, backslashes and NUL', () => {
    const dir = tempDir()
    fs.mkdirSync(path.join(dir, 'root'), { recursive: true })
    const root = realRoot(path.join(dir, 'root'))
    for (const [input, reason] of [
        ['/etc/passwd', 'absolute path'],
        ['C:/windows', 'absolute path'],
        ['a\\..\\b', 'backslash in path'],
        ['a\0b', 'nul byte in path'],
    ] as const) {
        const result = resolveInRoot(root, input)
        assert.equal(result.ok, false, `expected ${input} to be rejected`)
        if (!result.ok) assert.equal(result.reason, reason, `for ${input}`)
    }
})

check('allowlist rejects a symlink that leaves the root', () => {
    const dir = tempDir()
    fs.mkdirSync(path.join(dir, 'root'), { recursive: true })
    fs.writeFileSync(path.join(dir, 'outside.txt'), 'outside\n')
    fs.symlinkSync(path.join(dir, 'outside.txt'), path.join(dir, 'root', 'link.txt'))
    const root = realRoot(path.join(dir, 'root'))

    // Negative control: the symlink is lexically clean and does resolve out.
    assert.equal(checkRelative('link.txt').ok, true)
    assert.equal(fs.readFileSync(path.join(root, 'link.txt'), 'utf8'), 'outside\n')

    const result = resolveInRoot(root, 'link.txt')
    assert.equal(result.ok, false)
    if (!result.ok) assert.equal(result.reason, 'symlink escapes root')
})

check('allowlist keeps a symlink that stays inside the root', () => {
    const dir = tempDir()
    fs.mkdirSync(path.join(dir, 'root', 'sub'), { recursive: true })
    fs.writeFileSync(path.join(dir, 'root', 'sub', 'real.sx'), '(y)\n')
    fs.symlinkSync(path.join(dir, 'root', 'sub', 'real.sx'), path.join(dir, 'root', 'alias.sx'))
    const root = realRoot(path.join(dir, 'root'))
    const result = resolveInRoot(root, 'alias.sx')
    assert.equal(result.ok, true)
})

check('allowlist reports a missing file rather than guessing', () => {
    const dir = tempDir()
    fs.mkdirSync(path.join(dir, 'root'), { recursive: true })
    const root = realRoot(path.join(dir, 'root'))
    const result = resolveInRoot(root, 'nope.sx')
    assert.equal(result.ok, false)
    if (!result.ok) assert.equal(result.reason, 'not found')
})

// ----------------------------------------------------------------- provenance

check('flat TOML parsing handles quotes, comments and sections', () => {
    const fields = parseFlatToml(
        [
            '# leading comment',
            'name        = "E0900-R000007-summary"',
            'bytes       = 1111',
            'purpose     = "counts # not a comment"',
            'origin      = MECHANICAL   # trailing comment',
            '',
            '[extra]',
            'key = "value"',
        ].join('\n'),
    )
    assert.equal(fields.name, 'E0900-R000007-summary')
    assert.equal(fields.bytes, '1111')
    assert.equal(fields.purpose, 'counts # not a comment')
    assert.equal(fields.origin, 'MECHANICAL')
    assert.equal(fields['extra.key'], 'value')
    assert.equal(Object.hasOwn(fields, 'name'), true)
})

function provenanceFixture(): string {
    const dir = tempDir()
    fs.mkdirSync(path.join(dir, 'artifacts', 'runs', 'E0900'), { recursive: true })
    fs.mkdirSync(path.join(dir, 'research', 'runs'), { recursive: true })
    fs.writeFileSync(
        path.join(dir, 'artifacts', 'runs', 'E0900', 'R000007-summary.toml'),
        [
            'name        = "E0900-R000007-summary"',
            'sha256      = "1111111111111111111111111111111111111111111111111111111111111111"',
            'bytes       = 42',
            'origin      = "MECHANICAL"',
            'path        = ".cache/runs/E0900/R000007/summary.tsv"',
            '',
        ].join('\n'),
    )
    fs.writeFileSync(
        path.join(dir, 'artifacts', 'runs', 'E0900', 'R000007-standardir.toml'),
        [
            'name        = "E0900-R000007-standardir"',
            'sha256      = "2222222222222222222222222222222222222222222222222222222222222222"',
            'path        = ".cache/runs/E0900/R000007/core.standardir.sx"',
            '',
        ].join('\n'),
    )
    fs.writeFileSync(
        path.join(dir, 'research', 'runs', '2099-01.jsonl'),
        [
            JSON.stringify({
                run: 'R000900',
                experiment: 'E0900',
                status: 'accepted',
                origin: 'MECHANICAL',
                artifact: 'artifacts/runs/E0900/R000007-summary.toml',
            }),
            JSON.stringify({
                run: 'R000901',
                experiment: 'E0900',
                status: 'verification_failure',
                origin: 'MECHANICAL',
                artifact: 'artifacts/runs/E0900/R000007-standardir.toml',
            }),
            'this line is not JSON and must not stop the loader',
            '',
        ].join('\n'),
    )
    return dir
}

check('provenance joins cache directory, manifest and ledger run', () => {
    const repo = provenanceFixture()
    const prov = loadProvenance(repo)
    const entry = prov.runsByRef.get('E0900/R000007')
    assert.ok(entry, 'expected a bucket for E0900/R000007')
    assert.deepEqual(
        entry.manifests.map((m) => m.fileRel).sort(),
        ['core.standardir.sx', 'summary.tsv'],
    )
    assert.deepEqual(entry.ledger.map((l) => l.run).sort(), ['R000900', 'R000901'])
    assert.equal(prov.refByLedgerRun.get('R000900'), 'E0900/R000007')
    assert.equal(prov.refByLedgerRun.get('R000901'), 'E0900/R000007')
    assert.equal(prov.refByLedgerRun.get('R000999'), undefined)
})

check('provenance maps a file to the manifest that names it', () => {
    const prov = loadProvenance(provenanceFixture())
    const manifest = manifestForFile(prov, 'E0900/R000007', 'summary.tsv')
    assert.ok(manifest)
    assert.equal(manifest.manifestPath, 'artifacts/runs/E0900/R000007-summary.toml')
    assert.equal(manifest.fields.sha256, '1111111111111111111111111111111111111111111111111111111111111111')
    assert.equal(manifestForFile(prov, 'E0900/R000007', 'not-in-any-manifest.log'), null)
})

check('a ledger R-number and a cache reference resolve to the same run', () => {
    const prov = loadProvenance(provenanceFixture())
    const refs = ['E0900/R000007', 'E0901/R000001']
    assert.equal(resolveReference(prov, 'R000900', refs), 'E0900/R000007')
    assert.equal(resolveReference(prov, 'E0900/R000007', refs), 'E0900/R000007')
    assert.equal(resolveReference(prov, '.cache/runs/E0900/R000007/summary.tsv', refs), 'E0900/R000007')
    assert.equal(resolveReference(prov, 'E0901', refs), 'E0901/R000001')
    assert.equal(resolveReference(prov, 'R000007', refs), 'E0900/R000007') // unique directory name
    assert.equal(resolveReference(prov, 'R000042', refs), null)
    assert.equal(resolveReference(prov, '', refs), null)
})

// ------------------------------------------------------------------ discovery

function runFixture(): string {
    const dir = tempDir()
    const run = path.join(dir, 'E0900', 'R000007')
    fs.mkdirSync(path.join(run, 'treesitter'), { recursive: true })
    fs.mkdirSync(path.join(run, 'antlr'), { recursive: true })
    const files: [string, string][] = [
        ['core.standardir.sx', '(standardir (format 1))\n'],
        ['integrated.ebnf', 'x ::= y ;\n'],
        ['integrated.g4', 'grammar G;\nr_x : r_y ;\n'],
        ['integrated.y', '%%\nr_x:\n  r_y\n  ;\n'],
        ['treesitter/grammar.js', "module.exports = grammar({ name: 'g', rules: {} })\n"],
        ['generated-dispatch.f90', 'module m\nend module m\n'],
        ['summary.tsv', 'metric\tvalue\nrows\t3\n'],
        ['antlr/Lexer.java', 'class Lexer {}\n'],
        ['bison-validate.log', 'warning: 1 shift/reduce\n'],
        ['notes.txt', 'plain\n'],
    ]
    for (const [rel, body] of files) fs.writeFileSync(path.join(run, rel), body)
    fs.writeFileSync(path.join(run, 'generated-dispatch.o'), Buffer.from([0x7f, 0x45, 0x4c, 0x46, 0x00]))
    return dir
}

check('discovery classifies every generated format', () => {
    const expected: [string, string, string][] = [
        ['core.standardir.sx', 'sx', 'standardir'],
        ['integrated.ebnf', 'ebnf', 'grammar'],
        ['integrated.g4', 'antlr', 'grammar'],
        ['integrated.y', 'bison', 'grammar'],
        ['treesitter/grammar.js', 'treesitter', 'grammar'],
        ['generated-dispatch.f90', 'fortran', 'fortran'],
        ['summary.tsv', 'tsv', 'metrics'],
        ['bison-validate.log', 'log', 'logs'],
        ['antlr/Lexer.java', 'java', 'other'],
        ['generated-dispatch.o', 'binary', 'other'],
        ['notes.txt', 'text', 'other'],
    ]
    for (const [rel, kind, section] of expected) {
        const actual = classify(rel)
        assert.equal(actual.kind, kind, `kind of ${rel}`)
        assert.equal(actual.section, section, `section of ${rel}`)
    }
})

check('the run index lists every file once, grouped and deterministic', () => {
    const root = realRoot(runFixture())
    const run = resolveRun(root, 'E0900/R000007')
    assert.equal(run.ok, true)
    if (!run.ok) return
    const first = indexRunDirectory(run.abs, run.ref)
    const second = indexRunDirectory(run.abs, run.ref)
    assert.deepEqual(
        first.entries.map((e) => e.rel),
        second.entries.map((e) => e.rel),
    )
    assert.deepEqual(
        first.entries.map((e) => e.rel),
        [
            'core.standardir.sx',
            'integrated.ebnf',
            'integrated.g4',
            'integrated.y',
            'treesitter/grammar.js',
            'generated-dispatch.f90',
            'summary.tsv',
            'bison-validate.log',
            'antlr/Lexer.java',
            'generated-dispatch.o',
            'notes.txt',
        ],
    )
    assert.equal(first.truncated, false)
    const sizes = new Map(first.entries.map((e) => [e.rel, e.bytes]))
    assert.equal(sizes.get('summary.tsv'), fs.statSync(path.join(run.abs, 'summary.tsv')).size)
})

check('run listing finds E/R directories and rejects a non-directory ref', () => {
    const root = realRoot(runFixture())
    assert.deepEqual(listRuns(root), ['E0900/R000007'])
    const file = resolveRun(root, 'E0900/R000007/summary.tsv')
    assert.equal(file.ok, false)
    if (!file.ok) assert.equal(file.reason, 'not a directory')
    const outside = resolveRun(root, '../..')
    assert.equal(outside.ok, false)
})

// ------------------------------------------------------------------ SX reader

check('SX reader follows the canonical reader on atoms, quotes and escapes', () => {
    const text = [
        '(standardir (format 1) (origin MECHANICAL))',
        '(syntax R401 (lhs xyz-list) (rhs (seq (ref xyz) (token ","))) (source (document J3-24-007) (rule R401) (page 45)))',
        '(syntax R402 (lhs q) (rhs (token "a\\"b")) (source (document J3-24-007) (rule R402)))',
        '',
    ].join('\n')
    const doc = parseSx(text)
    assert.equal(doc.errors.length, 0)
    assert.equal(doc.forms.length, 3)
    const records = summarize(doc, text)
    assert.equal(records[1].head, 'syntax')
    assert.equal(records[1].id, 'R401')
    assert.equal(records[1].label, 'xyz-list')
    assert.equal(records[1].line, 2)
    assert.deepEqual(records[1].source, { document: 'J3-24-007', rule: 'R401', page: '45' })
    // `\"` is the only escape besides `\\`, and the value keeps the quote.
    const third = doc.forms[2].node
    assert.equal(third.k, 'list')
    if (third.k === 'list') {
        const rhs = third.c.find((n) => n.k === 'list' && n.c[0].k === 'atom' && n.c[0].v === 'rhs')
        assert.ok(rhs && rhs.k === 'list')
        const token = rhs.c[1]
        assert.ok(token.k === 'list')
        assert.deepEqual(token.c[1], { k: 'atom', v: 'a"b', quoted: true })
    }
})

check('SX reader reports a bad form and keeps the rest of the document', () => {
    const text = ['(good one)', '(bad "unterminated', '(good two)', ''].join('\n')
    const doc = parseSx(text)
    assert.equal(doc.errors.length, 1)
    assert.equal(doc.errors[0].line, 2)
    assert.equal(doc.forms.length, 2)
    assert.deepEqual(summarize(doc, text).map((r) => r.id), ['one', 'two'])

    const unsupported = parseSx('(x "a\\nb")\n')
    assert.equal(unsupported.errors.length, 1)
    assert.match(unsupported.errors[0].message, /unsupported SX escape/)
})

// ---------------------------------------------------------------- highlighting

// Removing the tokenizer's own spans and undoing the escaping must give the
// input back: that is the property that makes highlighting safe to inject and
// faithful to the bytes.
function unrender(html: string): string {
    return html
        .replace(/<span class="t-[a-z]+">/g, '')
        .replace(/<\/span>/g, '')
        .replace(/&lt;/g, '<')
        .replace(/&gt;/g, '>')
        .replace(/&quot;/g, '"')
        .replace(/&amp;/g, '&')
}

check('highlighting escapes markup in every format it renders', () => {
    const hostile = '<script>alert("x")</script> & <img onerror=1>'
    for (const kind of ['sx', 'ebnf', 'antlr', 'bison', 'treesitter', 'fortran', 'log', 'text'] as const) {
        const html = highlight(kind, hostile)
        assert.equal(html.includes('<script'), false, `${kind} leaked a tag`)
        assert.equal(html.includes('<img'), false, `${kind} leaked a tag`)
        assert.equal(unrender(html), hostile, `${kind} changed the text`)
    }
    const table = tsvTable('a\t<b>\nc\td\n')
    assert.equal(table.includes('<b>'), false)
    assert.equal(table.includes('&lt;b&gt;'), true)
})

check('highlighting preserves the text it was given', () => {
    const sample = '(syntax R401 (lhs xyz-list) (rhs (token ",")))'
    assert.equal(unrender(highlight('sx', sample)), sample)
    const fortran = "    if (n > 0) call parse_x2D_y(context, ok)  ! trailing 'comment'\n"
    assert.equal(unrender(highlight('fortran', fortran)), fortran)
})

process.stdout.write(`\n${checks - failures}/${checks} checks passed\n`)
process.exit(failures === 0 ? 0 : 1)
