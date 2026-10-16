export type GitHubLink = {
  /** `owner/repo#123` */
  key: string
  url: string
  kind: 'pull' | 'issues'
  /** `branch` is the current branch's PR (and the issues it closes); `seen` came up in the conversation. */
  source: 'branch' | 'seen'
  title?: string
  state?: string
}

declare module 'claude-code' {
  interface PluginState {
    'session-links': { links: GitHubLink[] }
  }
}
