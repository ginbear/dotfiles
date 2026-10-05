import { Action, ActionPanel, Icon, List, getPreferenceValues } from "@raycast/api";
import { useCachedPromise, useFrecencySorting } from "@raycast/utils";
import { execFile } from "node:child_process";
import { promisify } from "node:util";

const run = promisify(execFile);

type Repo = {
  name: string;
  description: string | null;
  url: string;
  pushedAt: string;
  isPrivate: boolean;
};

type Destination = { title: string; path: string; icon: Icon };

const CODE: Destination = { title: "Code", path: "", icon: Icon.Code };
const PULLS: Destination = { title: "Pull Requests", path: "/pulls", icon: Icon.ArrowUpCircle };

const OTHER_DESTINATIONS: Destination[] = [
  { title: "My Open Pull Requests", path: "/pulls?q=is:pr+is:open+author:@me", icon: Icon.Person },
  { title: "Review Requested", path: "/pulls?q=is:pr+is:open+review-requested:@me", icon: Icon.Eye },
  { title: "Issues", path: "/issues", icon: Icon.Bug },
  { title: "Actions", path: "/actions", icon: Icon.Play },
  { title: "Releases", path: "/releases", icon: Icon.Tag },
  { title: "Settings", path: "/settings", icon: Icon.Gear },
];

const DESTINATIONS = [CODE, PULLS, ...OTHER_DESTINATIONS];

async function listRepos(org: string): Promise<Repo[]> {
  const { stdout } = await run(
    "/opt/homebrew/bin/gh",
    ["repo", "list", org, "--limit", "1000", "--no-archived", "--json", "name,description,url,pushedAt,isPrivate"],
    { maxBuffer: 32 * 1024 * 1024 },
  );
  return JSON.parse(stdout) as Repo[];
}

function DestinationList(props: { repo: Repo; onVisit: () => void }) {
  const { repo, onVisit } = props;
  return (
    <List navigationTitle={repo.name} searchBarPlaceholder={`Open ${repo.name} at...`}>
      {DESTINATIONS.map((d) => (
        <List.Item
          key={d.title}
          title={d.title}
          icon={d.icon}
          actions={
            <ActionPanel>
              <Action.OpenInBrowser title={`Open ${d.title}`} url={repo.url + d.path} onOpen={onVisit} />
              <Action.CopyToClipboard title="Copy URL" content={repo.url + d.path} shortcut={{ modifiers: ["cmd"], key: "c" }} />
            </ActionPanel>
          }
        />
      ))}
    </List>
  );
}

export default function Command() {
  const { org } = getPreferenceValues<{ org: string }>();
  const { data, isLoading } = useCachedPromise(listRepos, [org]);
  const { data: sorted, visitItem } = useFrecencySorting(data, { key: (repo) => repo.url });

  return (
    <List isLoading={isLoading} searchBarPlaceholder="Search repositories">
      {sorted.map((repo) => {
        const onVisit = () => visitItem(repo);
        return (
          <List.Item
            key={repo.url}
            title={repo.name}
            subtitle={repo.description ?? undefined}
            keywords={repo.description ? [repo.description] : []}
            icon={repo.isPrivate ? Icon.Lock : Icon.Book}
            accessories={[{ date: new Date(repo.pushedAt) }]}
            actions={
              <ActionPanel>
                <Action.OpenInBrowser title="Open Repository" url={repo.url} onOpen={onVisit} />
                <Action.OpenInBrowser title="Open Pull Requests" url={repo.url + PULLS.path} onOpen={onVisit} />
                <Action.Push
                  title="Choose Destination"
                  icon={Icon.ArrowRight}
                  shortcut={{ modifiers: ["shift"], key: "return" }}
                  target={<DestinationList repo={repo} onVisit={onVisit} />}
                />
                <ActionPanel.Section title="Open in Browser">
                  {OTHER_DESTINATIONS.map((d) => (
                    <Action.OpenInBrowser key={d.title} title={d.title} icon={d.icon} url={repo.url + d.path} onOpen={onVisit} />
                  ))}
                </ActionPanel.Section>
                <Action.CopyToClipboard title="Copy URL" content={repo.url} shortcut={{ modifiers: ["cmd"], key: "c" }} />
              </ActionPanel>
            }
          />
        );
      })}
    </List>
  );
}
