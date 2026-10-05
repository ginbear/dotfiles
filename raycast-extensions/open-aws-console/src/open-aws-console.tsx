import { Action, ActionPanel, Icon, List, Toast, getPreferenceValues, showToast } from "@raycast/api";
import { useCachedPromise, useFrecencySorting } from "@raycast/utils";
import { execFile } from "node:child_process";
import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";

const run = promisify(execFile);
const AWS = "/opt/homebrew/bin/aws";

type Role = {
  accountId: string;
  accountName: string;
  roleName: string;
  portalUrl: string;
};

type Destination = { title: string; path: string; icon: Icon };

const OTHER_DESTINATIONS: Destination[] = [
  { title: "EKS", path: "/eks/home", icon: Icon.Box },
  { title: "EC2", path: "/ec2/home", icon: Icon.ComputerChip },
  { title: "RDS", path: "/rds/home", icon: Icon.HardDrive },
  { title: "S3", path: "/s3/home", icon: Icon.Tray },
  { title: "CloudWatch", path: "/cloudwatch/home", icon: Icon.LineChart },
  { title: "IAM", path: "/iam/home", icon: Icon.Key },
  { title: "Billing", path: "/billing/home", icon: Icon.Coins },
];

class LoginRequiredError extends Error {}

// The aws CLI names the token cache after the SHA-1 of the sso-session name.
async function readToken(ssoSession: string) {
  const file = join(homedir(), ".aws", "sso", "cache", createHash("sha1").update(ssoSession).digest("hex") + ".json");
  const cache = await readFile(file, "utf8").then(JSON.parse, () => undefined);
  if (!cache?.accessToken || new Date(cache.expiresAt) <= new Date()) {
    throw new LoginRequiredError(`SSO session "${ssoSession}" is not logged in`);
  }
  return cache as { accessToken: string; region: string; startUrl: string };
}

async function sso<T>(region: string, token: string, args: string[]): Promise<T> {
  try {
    const { stdout } = await run(AWS, ["sso", ...args, "--access-token", token, "--region", region, "--output", "json"]);
    return JSON.parse(stdout) as T;
  } catch (e) {
    if (String((e as { stderr?: string }).stderr).includes("UnauthorizedException")) {
      throw new LoginRequiredError("SSO token was rejected");
    }
    throw e;
  }
}

async function listRoles(ssoSession: string): Promise<Role[]> {
  const { accessToken, region, startUrl } = await readToken(ssoSession);
  const portalUrl = startUrl.replace(/\/?#?$/, "");
  const { accountList } = await sso<{ accountList: { accountId: string; accountName: string }[] }>(
    region,
    accessToken,
    ["list-accounts"],
  );
  const perAccount = await Promise.all(
    accountList.map(async (a) => {
      const { roleList } = await sso<{ roleList: { roleName: string }[] }>(region, accessToken, [
        "list-account-roles",
        "--account-id",
        a.accountId,
      ]);
      return roleList.map((r) => ({ ...a, roleName: r.roleName, portalUrl }));
    }),
  );
  return perAccount.flat().sort((a, b) => a.accountName.localeCompare(b.accountName));
}

function consoleUrl(role: Role, path?: string) {
  const params = new URLSearchParams({ account_id: role.accountId, role_name: role.roleName });
  if (path) params.set("destination", "https://console.aws.amazon.com" + path);
  return `${role.portalUrl}/#/console?${params}`;
}

async function login(ssoSession: string, revalidate: () => void) {
  const toast = await showToast({ style: Toast.Style.Animated, title: "Waiting for aws sso login in browser..." });
  try {
    await run(AWS, ["sso", "login", "--sso-session", ssoSession], { timeout: 5 * 60 * 1000 });
    toast.style = Toast.Style.Success;
    toast.title = "Logged in";
    revalidate();
  } catch (e) {
    toast.style = Toast.Style.Failure;
    toast.title = "aws sso login failed";
    toast.message = String((e as { stderr?: string }).stderr ?? e);
  }
}

function DestinationList(props: { role: Role; onVisit: () => void }) {
  const { role, onVisit } = props;
  const destinations = [{ title: "Console Home", path: "", icon: Icon.House }, ...OTHER_DESTINATIONS];
  return (
    <List navigationTitle={`${role.accountName} / ${role.roleName}`} searchBarPlaceholder="Open console at...">
      {destinations.map((d) => (
        <List.Item
          key={d.title}
          title={d.title}
          icon={d.icon}
          actions={
            <ActionPanel>
              <Action.OpenInBrowser title={`Open ${d.title}`} url={consoleUrl(role, d.path)} onOpen={onVisit} />
              <Action.CopyToClipboard title="Copy URL" content={consoleUrl(role, d.path)} shortcut={{ modifiers: ["cmd"], key: "c" }} />
            </ActionPanel>
          }
        />
      ))}
    </List>
  );
}

export default function Command() {
  const { ssoSession } = getPreferenceValues<{ ssoSession: string }>();
  const { data, isLoading, error, revalidate } = useCachedPromise(listRoles, [ssoSession], {
    // Cached roles stay usable: opening the console relies on the browser's portal session, not the CLI token.
    onError: (e) => {
      showToast({
        style: Toast.Style.Failure,
        title: e instanceof LoginRequiredError ? "aws sso login required" : "Failed to list accounts",
        message: e.message,
        primaryAction: { title: "Log In", onAction: () => login(ssoSession, revalidate) },
      });
    },
  });
  const { data: sorted, visitItem } = useFrecencySorting(data, { key: (r) => `${r.accountId}/${r.roleName}` });
  const loginAction = (
    <Action title="Log in with aws sso login" icon={Icon.Key} onAction={() => login(ssoSession, revalidate)} />
  );

  return (
    <List isLoading={isLoading} searchBarPlaceholder="Search accounts and roles">
      {error && !data?.length ? (
        <List.EmptyView
          icon={Icon.Lock}
          title={error instanceof LoginRequiredError ? "aws sso login required" : "Failed to list accounts"}
          description={error.message}
          actions={<ActionPanel>{loginAction}</ActionPanel>}
        />
      ) : null}
      {sorted.map((role) => {
        const onVisit = () => visitItem(role);
        return (
          <List.Item
            key={`${role.accountId}/${role.roleName}`}
            title={role.accountName}
            subtitle={role.roleName}
            keywords={[role.roleName, role.accountId]}
            icon={Icon.Cloud}
            accessories={[{ text: role.accountId }]}
            actions={
              <ActionPanel>
                <Action.OpenInBrowser title="Open Console" url={consoleUrl(role)} onOpen={onVisit} />
                <Action.Push
                  title="Choose Destination"
                  icon={Icon.ArrowRight}
                  shortcut={{ modifiers: ["shift"], key: "return" }}
                  target={<DestinationList role={role} onVisit={onVisit} />}
                />
                <ActionPanel.Section title="Open in Browser">
                  {OTHER_DESTINATIONS.map((d) => (
                    <Action.OpenInBrowser key={d.title} title={d.title} icon={d.icon} url={consoleUrl(role, d.path)} onOpen={onVisit} />
                  ))}
                </ActionPanel.Section>
                <Action.CopyToClipboard title="Copy URL" content={consoleUrl(role)} shortcut={{ modifiers: ["cmd"], key: "c" }} />
                <Action.CopyToClipboard title="Copy Account ID" content={role.accountId} shortcut={{ modifiers: ["cmd", "shift"], key: "c" }} />
                {loginAction}
              </ActionPanel>
            }
          />
        );
      })}
    </List>
  );
}
