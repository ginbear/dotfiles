import type { GitHubLink } from '../types'

const URL_RE = /https:\/\/github\.com\/([\w.-]+)\/([\w.-]+)\/(pull|issues)\/(\d+)/g

export const MAX_SEEN = 50

export function extractLinks(text: string, source: GitHubLink['source']): GitHubLink[] {
  const found = new Map<string, GitHubLink>()
  for (const [, owner, repo, kind, num] of text.matchAll(URL_RE)) {
    const key = `${owner}/${repo}#${num}`
    found.set(key, {
      key,
      url: `https://github.com/${owner}/${repo}/${kind}/${num}`,
      kind: kind as GitHubLink['kind'],
      source,
    })
  }
  return [...found.values()]
}

// Seen links move to the front when they come up again; titles fetched earlier are kept.
export function mergeSeen(list: readonly GitHubLink[], found: readonly GitHubLink[]): GitHubLink[] {
  const byKey = new Map(list.map(l => [l.key, l]))
  const fresh = found.map(f => ({ ...f, ...pickMeta(byKey.get(f.key)), source: byKey.get(f.key)?.source ?? f.source }))
  const freshKeys = new Set(fresh.map(f => f.key))
  const rest = list.filter(l => !freshKeys.has(l.key))
  const branch = [...fresh, ...rest].filter(l => l.source === 'branch')
  const seen = [...fresh, ...rest].filter(l => l.source === 'seen').slice(0, MAX_SEEN)
  return [...branch, ...seen]
}

export function replaceBranch(list: readonly GitHubLink[], branch: readonly GitHubLink[]): GitHubLink[] {
  const keys = new Set(branch.map(b => b.key))
  const byKey = new Map(list.map(l => [l.key, l]))
  return [
    ...branch.map(b => ({ ...pickMeta(byKey.get(b.key)), ...b })),
    ...list.filter(l => l.source === 'seen' && !keys.has(l.key)),
  ]
}

function pickMeta(l: GitHubLink | undefined): Partial<GitHubLink> {
  return l === undefined ? {} : { title: l.title, state: l.state }
}

export function label(l: GitHubLink, width: number): string {
  const head = `${l.key}${l.state ? ` [${l.state}]` : ''}`
  const text = l.title ? `${head} ${l.title}` : head
  return text.length > width ? `${text.slice(0, Math.max(0, width - 1))}…` : text
}
