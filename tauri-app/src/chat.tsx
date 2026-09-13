import { VStack } from "@astryxdesign/core/Layout";
import { Text } from "@astryxdesign/core/Text";
import { Avatar } from "@astryxdesign/core/Avatar";
import { Thumbnail } from "@astryxdesign/core/Thumbnail";
import { Timestamp } from "@astryxdesign/core/Timestamp";
import {
  ChatComposer,
  ChatComposerDrawer,
  ChatLayout,
  ChatMessage,
  ChatMessageBubble,
  ChatMessageList,
  ChatMessageMetadata,
  ChatSystemMessage,
} from "@astryxdesign/core/Chat";
import { Token } from "@astryxdesign/core/Token";
import { IconButton } from "@astryxdesign/core/IconButton";
import { Icon } from "@astryxdesign/core/Icon";
import { MicIcon, PlusCircleIcon } from "./icons";
import { EmptyState } from "@astryxdesign/core/EmptyState";
import { API, type Msg } from "./api";

type Props = {
  title: string;
  msgs: Msg[];
  attachments: string[];
  onSend: (v: string) => void;
  onAttach: () => void;
  onRemoveAttachment: (a: string) => void;
  onDictate: () => void;
};

// Mobile chat transcript: black user bubbles right, grey assistant left,
// reply row + quote card + image card per measured original.
export default function ChatScreen(p: Props) {
  return (
    <ChatLayout
      composer={
        <ChatComposer placeholder={p.title ? `Message in ${p.title}` : "Message"}
          onSubmit={(v) => p.onSend(v)}
          drawer={p.attachments.length ? (
            <ChatComposerDrawer count={p.attachments.length} label="Attachments">
              {p.attachments.map((a) => <Token key={a} label={a} onRemove={() => p.onRemoveAttachment(a)} />)}
            </ChatComposerDrawer>
          ) : undefined}
          headerActions={<IconButton label="Attach" tooltip="Attach" icon={<Icon icon={PlusCircleIcon} size="md" color="inherit" />} variant="ghost" size="md" onClick={p.onAttach} />}
          sendActions={<IconButton label="Dictate" tooltip="Dictate" icon={<Icon icon={MicIcon} size="md" color="inherit" />} variant="ghost" size="md" onClick={p.onDictate} />} />
      }
      emptyState={<EmptyState title="Start a conversation with Muse" description="Send a message below." icon={<Icon icon="search" size="lg" />} />}>
      {p.msgs.length ? (
        <ChatMessageList density="compact">
          <ChatSystemMessage variant="divider">{new Date(p.msgs[0].ts).toLocaleDateString(undefined, { month: "short", day: "numeric" })}</ChatSystemMessage>
          {p.msgs.map((m) => (
            <ChatMessage key={m.id} sender={m.role === "user" ? "user" : "assistant"}
              avatar={m.role === "user" ? undefined : <Avatar name="Muse" size="sm" />}>
              {m.role !== "user" ? (
                <VStack gap={1} style={{ marginBottom: 4 }}>
                  <Text style={{ fontSize: 13, color: "#6F7278" }}>Muse replied to you</Text>
                  <ChatMessageBubble variant="filled" width="auto">
                    <Text style={{ fontSize: 15, color: "#1A1A1A" }}>{m.reply_to ?? ""}</Text>
                  </ChatMessageBubble>
                </VStack>
              ) : null}
              <ChatMessageBubble name={m.role === "user" ? undefined : "Muse"} variant="filled"
                metadata={<ChatMessageMetadata timestamp={<Timestamp value={m.ts} format="time" />} />}>
                {m.text}
              </ChatMessageBubble>
              {(m.cards ?? []).map((c, i) => c.kind === "image" && c.url ? (
                <ChatMessageBubble key={`${m.id}-card-${i}`} variant="ghost" width="100%"
                  metadata={<ChatMessageMetadata timestamp={<Timestamp value={m.ts} format="time" />} />}>
                  <VStack gap={2}>
                    <Text weight="semibold">{c.title ?? "Image"}</Text>
                    <Thumbnail src={c.url.startsWith("/") ? `${API}${c.url}` : c.url} alt={c.title ?? "Demo picture"} label={c.title ?? "Demo picture"} />
                  </VStack>
                </ChatMessageBubble>
              ) : null)}
            </ChatMessage>
          ))}
        </ChatMessageList>
      ) : null}
    </ChatLayout>
  );
}
