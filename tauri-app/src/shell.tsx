import { HStack, Layout, LayoutContent, LayoutFooter, LayoutHeader, StackItem, VStack } from "@astryxdesign/core/Layout";
import { Heading, Text } from "@astryxdesign/core/Text";
import { Icon } from "@astryxdesign/core/Icon";
import { IconButton } from "@astryxdesign/core/IconButton";
import { TextInput } from "@astryxdesign/core/TextInput";
import { List, ListItem } from "@astryxdesign/core/List";
import { Card } from "@astryxdesign/core/Card";
import { EmptyState } from "@astryxdesign/core/EmptyState";
import { Dialog } from "@astryxdesign/core/Dialog";
import { AlertDialog } from "@astryxdesign/core/AlertDialog";
import { Button } from "@astryxdesign/core/Button";
import { ChatTabIconFilled, ChatTabIconOutline, GoalsTabIconFilled, GoalsTabIconOutline, IdeasTabIconFilled, IdeasTabIconOutline, LibraryTabIconFilled, LibraryTabIconOutline } from "./icons";
import ChatScreen from "./chat";
import type { FeedUnit, Msg, Thread } from "./api";

export type Tab = "CHAT" | "IDEAS" | "GOALS" | "LIBRARY" | "SETTINGS";

type Props = {
  tab: Tab;
  title: string;
  plan: string;
  status: string;
  threads: Thread[];
  threadId: string;
  query: string;
  msgs: Msg[];
  feed: FeedUnit[];
  profile: string;
  attachments: string[];
  threadsOpen: boolean;
  renameOpen: boolean;
  rename: string;
  logoutOpen: boolean;
  legalOpen: boolean;
  feedOpen: string | null;
  busy: boolean;
  onTab: (t: Tab) => void;
  onQuery: (v: string) => void;
  onThread: (id: string) => void;
  onThreadsOpen: (v: boolean) => void;
  onSend: (v: string) => void;
  onAttach: () => void;
  onRemoveAttachment: (a: string) => void;
  onDictate: () => void;
  onRename: (v: string) => void;
  onRenameOpen: (v: boolean) => void;
  onSaveRename: () => void;
  onLegalOpen: (v: boolean) => void;
  onFeedOpen: (v: string | null) => void;
  onLogoutOpen: (v: boolean) => void;
  onLogout: () => void;
  onHelp: () => void;
};

// Mobile-only shell: chat header, content, bottom 4-tab icon bar.
export default function MobileShell(p: Props) {
  return (
    <Layout height="fill"
      header={p.tab === "CHAT" ? (
        <LayoutHeader hasDivider>
          <HStack gap={2} vAlign="center" style={{ paddingTop: 48, paddingBottom: 8, paddingLeft: 8, paddingRight: 8 }}>
            <IconButton label="Threads" tooltip="Threads" icon={<Icon icon="menu" size="md" color="inherit" />} variant="ghost" size="md" onClick={() => p.onThreadsOpen(true)} />
            <StackItem size="fill"><Heading level={4}>{p.title || "New chat"}</Heading></StackItem>
            <Text color="secondary">{p.plan}</Text>
          </HStack>
        </LayoutHeader>
      ) : undefined}
      content={
        <LayoutContent padding={p.tab === "CHAT" ? 0 : 4}>
          {p.status ? <Text color="secondary">{p.status}</Text> : null}
          {p.tab === "CHAT" ? (
            <ChatScreen title={p.title} msgs={p.msgs} attachments={p.attachments}
              onSend={p.onSend} onAttach={p.onAttach} onRemoveAttachment={p.onRemoveAttachment} onDictate={p.onDictate} />
          ) : null}
          {p.tab === "IDEAS" ? (
            <List density="balanced" header={<Heading level={2}>Ideas</Heading>} hasDividers>
              {p.feed.map((u) => (
                <ListItem key={u.id} label={u.title} description={u.subtitle} onClick={() => p.onFeedOpen(u.id)} />
              ))}
            </List>
          ) : null}
          {p.tab === "GOALS" ? <EmptyState title="No goals yet" description="Goals appear here." icon={<Icon icon="check" size="lg" />} /> : null}
          {p.tab === "LIBRARY" ? <EmptyState title="No library items yet" description="Saved items appear here." icon={<Icon icon="search" size="lg" />} /> : null}
          {p.tab === "SETTINGS" ? (
            <VStack gap={4} style={{ maxWidth: 720 }}>
              <Heading level={2}>Settings</Heading>
              <Card padding={4}>
                <VStack gap={1}>
                  <Text weight="semibold">{p.profile}</Text>
                  <Text color="secondary">Plan: {p.plan} · VM: active</Text>
                </VStack>
              </Card>
              <List density="balanced" hasDividers>
                <ListItem label="Help & support" onClick={p.onHelp} />
                <ListItem label="Legal info" onClick={() => p.onLegalOpen(true)} />
                <ListItem label="Rename thread" description={p.title || "No thread"} onClick={() => p.onRenameOpen(true)} />
                <ListItem label="Log out" onClick={() => p.onLogoutOpen(true)} />
              </List>
            </VStack>
          ) : null}
        </LayoutContent>
      }
      footer={
        <LayoutFooter hasDivider height={64}>
          <HStack gap={0} vAlign="center" style={{ width: "100%", justifyContent: "space-around", paddingTop: 8, paddingBottom: 8 }}>
            {(["CHAT", "IDEAS", "GOALS", "LIBRARY"] as const).map((t) => (
              <IconButton key={t} label={t} tooltip={t}
                icon={<Icon icon={t === "CHAT" ? (p.tab === t ? ChatTabIconFilled : ChatTabIconOutline) : t === "IDEAS" ? (p.tab === t ? IdeasTabIconFilled : IdeasTabIconOutline) : t === "GOALS" ? (p.tab === t ? GoalsTabIconFilled : GoalsTabIconOutline) : (p.tab === t ? LibraryTabIconFilled : LibraryTabIconOutline)} size="lg" color="inherit" />}
                variant="ghost" size="lg" onClick={() => p.onTab(t)} />
            ))}
          </HStack>
        </LayoutFooter>
      } />
  );
}

export function MobileDialogs(p: Props) {
  return (
    <>
      <Dialog isOpen={p.threadsOpen} onOpenChange={p.onThreadsOpen} width={360} padding={4}>
        <VStack gap={3}>
          <TextInput label="Search threads" isLabelHidden placeholder="Search threads" startIcon="search" hasClear value={p.query} onChange={p.onQuery} />
          <List density="balanced" header={<Text type="label" color="secondary">Threads</Text>}>
            {p.threads.filter((t) => t.title.toLowerCase().includes(p.query.toLowerCase())).map((t) => (
              <ListItem key={t.id} label={t.title} isSelected={t.id === p.threadId} onClick={() => p.onThread(t.id)} />
            ))}
          </List>
        </VStack>
      </Dialog>
      <Dialog isOpen={p.renameOpen} onOpenChange={p.onRenameOpen} width={400} padding={4}>
        <VStack gap={3}>
          <Heading level={3}>Rename thread</Heading>
          <TextInput label="Title" value={p.rename} onChange={p.onRename} />
          <HStack gap={2}>
            <Button label="Cancel" variant="ghost" onClick={() => p.onRenameOpen(false)} />
            <Button label="Save" variant="primary" isLoading={p.busy} onClick={p.onSaveRename} />
          </HStack>
        </VStack>
      </Dialog>
      <Dialog isOpen={p.legalOpen} onOpenChange={p.onLegalOpen} width={480} padding={4}>
        <VStack gap={2}>
          <Heading level={3}>Legal info</Heading>
          <Text color="secondary">Local offline demo. No data leaves this machine.</Text>
          <Button label="Close" variant="primary" onClick={() => p.onLegalOpen(false)} />
        </VStack>
      </Dialog>
      <Dialog isOpen={p.feedOpen !== null} onOpenChange={(o) => { if (!o) p.onFeedOpen(null); }} width={440} padding={4}>
        <VStack gap={2}>
          <Heading level={3}>{p.feed.find((u) => u.id === p.feedOpen)?.title ?? "Idea"}</Heading>
          <Text color="secondary">{p.feed.find((u) => u.id === p.feedOpen)?.subtitle ?? ""}</Text>
          <Button label="Close" variant="primary" onClick={() => p.onFeedOpen(null)} />
        </VStack>
      </Dialog>
      <AlertDialog isOpen={p.logoutOpen} onOpenChange={p.onLogoutOpen} title="Log out?" description="Return to the offline login screen." actionLabel="Log out" onAction={p.onLogout} />
    </>
  );
}
