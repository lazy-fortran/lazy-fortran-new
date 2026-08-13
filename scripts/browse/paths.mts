// Path allowlist for the run browser.
//
// One rule: a request may only name a file that lies inside the allowlisted
// root, both lexically and after symlinks are resolved. Both checks are kept
// because they fail differently. The lexical one rejects `..` and absolute
// paths before touching the filesystem; the realpath one rejects a symlink
// inside the root that points out of it, which no amount of string inspection
// can see. `selftest.mts` exercises each rejection reason.

import * as fs from 'node:fs'
import * as path from 'node:path'

export type Resolved =
    | { ok: true; abs: string; rel: string }
    | { ok: false; reason: string }

// The root, with symlinks resolved. Every comparison is against this form.
export function realRoot(dir: string): string {
    return fs.realpathSync(path.resolve(dir))
}

export function isInside(root: string, candidate: string): boolean {
    return candidate === root || candidate.startsWith(root + path.sep)
}

// Normalize a client-supplied relative path to root-relative POSIX form, or
// explain why it is not acceptable. Nothing here reads the filesystem.
export function checkRelative(rel: string): { ok: true; rel: string } | { ok: false; reason: string } {
    if (rel.includes('\0')) return { ok: false, reason: 'nul byte in path' }
    if (rel.startsWith('/') || /^[a-zA-Z]:/.test(rel)) {
        return { ok: false, reason: 'absolute path' }
    }
    if (rel.includes('\\')) return { ok: false, reason: 'backslash in path' }
    const parts = rel.split('/').filter((p) => p !== '' && p !== '.')
    if (parts.some((p) => p === '..')) return { ok: false, reason: 'parent traversal' }
    return { ok: true, rel: parts.join('/') }
}

// Resolve a root-relative path to an absolute one that is provably inside the
// root. `mustExist` is on for content requests and off only where a caller
// wants to report a missing file itself.
export function resolveInRoot(root: string, rel: string): Resolved {
    const checked = checkRelative(rel)
    if (!checked.ok) return checked
    const joined = path.resolve(root, checked.rel)
    if (!isInside(root, joined)) return { ok: false, reason: 'outside root' }
    let real: string
    try {
        real = fs.realpathSync(joined)
    } catch (err) {
        const code = (err as NodeJS.ErrnoException).code
        return { ok: false, reason: code === 'ENOENT' ? 'not found' : `unreadable: ${code}` }
    }
    if (!isInside(root, real)) return { ok: false, reason: 'symlink escapes root' }
    return { ok: true, abs: real, rel: checked.rel }
}
