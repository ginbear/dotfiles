import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { GitHubLink } from '../types'
import { extractLinks, label, mergeSeen, replaceBranch } from './links'

const PANE = 'session-links'
const links = atom({ plugin: 'session-links', key: 'links' } as const, [] as GitHubLink[])

async function refreshBranch($: EngineInterface): Promise<void> {
  const cwd = await $.session.cwd()
  const ran = await $.process.run(
    ['gh', 'pr', 'view', '--json', 'url,title,state,closingIssuesReferences'],
    { cwd, timeoutMs: 15_000 },
  )
  const branch = ran.exitCode === 0 ? extractLinks(ran.stdout, 'branch') : []
  if (ran.exitCode === 0) {
    const pr = JSON.parse(ran.stdout) as { url: string; title: string; state: string }
    const own = branch.find(b => b.url === pr.url)
    if (own) Object.assign(own, { title: pr.title, state: pr.state.toLowerCase() })
  }
  await update($, links, list => replaceBranch(list, branch))
}

async function fillTitles($: EngineInterface): Promise<void> {
  const missing = (await read($, links)).filter(l => l.title === undefined).slice(0, 20)
  const fetched = await Promise.all(
    missing.map(async l => {
      const [repo, num] = l.key.split('#')
      const ran = await $.process.run(
        ['gh', 'api', `repos/${repo}/issues/${num}`, '--jq',
          '[.title, (if .pull_request.merged_at then "merged" else .state end)] | @tsv'],
        { timeoutMs: 15_000 },
      )
      if (ran.exitCode !== 0) return undefined
      const [title, state] = ran.stdout.trim().split('\t')
      return { key: l.key, title, state }
    }),
  )
  const byKey = new Map(fetched.filter(f => f !== undefined).map(f => [f.key, f]))
  await update($, links, list => list.map(l => ({ ...l, ...byKey.get(l.key) })))
}

async function openUrl($: EngineInterface, url: string): Promise<void> {
  await $.process.run(['open', url])
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'links',
      description: 'このブランチの PR と、この session に出てきた issue/PR を一覧して開く',
      argumentHint: '[番号で直接開く]',
    })
    return next(e)
  })

  // Every row the conversation keeps (prompts, replies, tool results) passes here once.
  on('session.append', async ($, e, next) => {
    const stored = await next(e)
    const found = extractLinks(JSON.stringify(e.message.content), 'seen')
    if (found.length > 0) await update($, links, list => mergeSeen(list, found))
    return stored
  }).catch(($, e, next) => next(e))

  on('command.run', { command: 'links' }, async ($, e) => {
    const n = Number.parseInt(e.args.trim(), 10)
    if (Number.isInteger(n)) {
      const target = (await read($, links))[n - 1]
      if (target === undefined) return { text: `${n} 番のリンクはありません。` }
      await openUrl($, target.url)
      return { text: `${target.key} を開きました。` }
    }
    // focus: without it the digit hotkeys go to the prompt instead of the pane.
    await $.ui.open({ id: PANE, title: 'Session links', focus: true, closeOnEscape: true })
    await refreshBranch($)
    void fillTitles($)
    return { text: 'リンク一覧を開きました。' }
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Text, Button } = $.ui.resolve(e)
    const list = await read($, links)
    const width = Math.max(20, (e.props.bodyColumns ?? 80) - 4)
    const row = (l: GitHubLink, i: number) => (
      <Button
        key={l.key}
        plain
        hotkey={i < 9 ? String(i + 1) : undefined}
        onPress={() => void openUrl($, l.url)}
      >
        {label(l, width)}
      </Button>
    )
    const branch = list.filter(l => l.source === 'branch')
    const seen = list.filter(l => l.source === 'seen')

    return (
      <Box flexDirection="column">
        <Text dimColor>このブランチ</Text>
        {branch.length === 0 && <Text dimColor>  PR なし</Text>}
        {branch.map((l, i) => row(l, i))}
        <Text dimColor>この session</Text>
        {seen.length === 0 && <Text dimColor>  まだありません</Text>}
        {seen.map((l, i) => row(l, branch.length + i))}
      </Box>
    )
  })
}
