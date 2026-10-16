import { expect, test } from 'claude-code/testing'

import { extractLinks, label, mergeSeen, replaceBranch } from './links'

test('extracts and dedupes PR and issue URLs', () => {
  const text = 'see https://github.com/o/r/pull/12/files and https://github.com/o/r/issues/3, again https://github.com/o/r/pull/12'
  const found = extractLinks(text, 'seen')
  expect(found.map(l => l.key)).toEqual(['o/r#12', 'o/r#3'])
  expect(found[0]!.url).toBe('https://github.com/o/r/pull/12')
})

test('a link seen again moves to the front and keeps its title', () => {
  const [a, b] = extractLinks('https://github.com/o/r/pull/1 https://github.com/o/r/pull/2', 'seen')
  const list = mergeSeen([], [a!, b!]).map(l => (l.key === 'o/r#2' ? { ...l, title: 'two' } : l))
  const next = mergeSeen(list, [b!])
  expect(next.map(l => l.key)).toEqual(['o/r#2', 'o/r#1'])
  expect(next[0]!.title).toBe('two')
})

test('branch links stay on top and replace the previous branch', () => {
  const seen = mergeSeen([], extractLinks('https://github.com/o/r/issues/9', 'seen'))
  const withBranch = replaceBranch(seen, extractLinks('https://github.com/o/r/pull/5', 'branch'))
  expect(withBranch.map(l => `${l.source}:${l.key}`)).toEqual(['branch:o/r#5', 'seen:o/r#9'])
  expect(mergeSeen(withBranch, extractLinks('https://github.com/o/r/pull/7', 'seen'))[0]!.key).toBe('o/r#5')
  expect(replaceBranch(withBranch, []).map(l => l.key)).toEqual(['o/r#9'])
})

test('labels are cut to the width', () => {
  const [l] = extractLinks('https://github.com/o/r/pull/1', 'seen')
  expect(label({ ...l!, title: 'a long title', state: 'open' }, 12)).toBe('o/r#1 [open…')
})
