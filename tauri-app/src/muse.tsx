import { useEffect, useState } from "react";
import { Theme } from "@astryxdesign/core/theme";
import AuthScreen from "./auth";
import MobileShell, { MobileDialogs, type Tab } from "./shell";
import { api, post, type Connector, type FeedUnit, type Msg, type Thread } from "./api";

// ponytail: thin mobile state owner; screens own layout, api.ts owns data.
export default function MuseApp({ theme }: { theme: Parameters<typeof Theme>[0]["theme"] }) {
  const [authed, setAuthed] = useState(false);
  const [step, setStep] = useState(0);
  const [busy, setBusy] = useState(false);
  const [status, setStatus] = useState("");
  const [phone, setPhone] = useState("");
  const [code, setCode] = useState("");
  const [name, setName] = useState("Noel");
  const [pin, setPin] = useState("");
  const [tab, setTab] = useState<Tab>("CHAT");
  const [threads, setThreads] = useState<Thread[]>([]);
  const [threadId, setThreadId] = useState("t1");
  const [messages, setMessages] = useState<Record<string, Msg[]>>({});
  const [feed, setFeed] = useState<FeedUnit[]>([]);
  const [connectors, setConnectors] = useState<Connector[]>([]);
  const [linked, setLinked] = useState<string[]>([]);
  const [profile, setProfile] = useState("Muse User");
  const [plan, setPlan] = useState("free");
  const [query, setQuery] = useState("");
  const [threadsOpen, setThreadsOpen] = useState(false);
  const [renameOpen, setRenameOpen] = useState(false);
  const [rename, setRename] = useState("");
  const [logoutOpen, setLogoutOpen] = useState(false);
  const [legalOpen, setLegalOpen] = useState(false);
  const [feedOpen, setFeedOpen] = useState<string | null>(null);
  const [attachments, setAttachments] = useState<string[]>([]);

  const run = async (fn: () => Promise<void>) => {
    setBusy(true);
    setStatus("");
    try {
      await fn();
    } catch (e) {
      setStatus(e instanceof Error ? e.message : "Request failed");
    } finally {
      setBusy(false);
    }
  };

  const bootstrap = async () => {
    const [t, f, p, s, c] = await Promise.all([
      api("/api/session/list"),
      api("/api/feed"),
      api("/hatch/viewer/profile"),
      api("/hatch/subscription"),
      api("/api/connectors"),
    ]);
    setThreads(t.threads ?? []);
    setFeed(f.units ?? []);
    setProfile(p?.user?.name ?? p?.name ?? "Muse User");
    setPlan(s.plan ?? "free");
    setConnectors(c.connectors ?? []);
    const first = (t.threads ?? [])[0]?.id ?? "t1";
    setThreadId(first);
    const h = await api(`/api/chat/history?thread_id=${first}`);
    setMessages({ [first]: h.messages ?? [] });
  };

  const loadThread = async (id: string) => {
    setThreadId(id);
    setThreadsOpen(false);
    const h = await api(`/api/chat/history?thread_id=${id}`);
    setMessages((m) => ({ ...m, [id]: h.messages ?? [] }));
  };

  const send = async (value: string) => {
    const text = attachments.length ? `[${attachments.join(", ")}] ${value}` : value;
    const user: Msg = { id: `u${Date.now()}`, role: "user", text, ts: new Date().toISOString() };
    setMessages((m) => ({ ...m, [threadId]: [...(m[threadId] ?? []), user] }));
    setAttachments([]);
    try {
      const r = await post("/api/chat/send", { thread_id: threadId, text });
      setMessages((m) => ({ ...m, [threadId]: [...(m[threadId] ?? []), r.message] }));
    } catch {
      setMessages((m) => ({ ...m, [threadId]: [...(m[threadId] ?? []),
        { id: `a${Date.now()}`, role: "agent", text, ts: new Date().toISOString() }] }));
    }
  };

  useEffect(() => {
    if (authed) void run(bootstrap);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [authed]);

  if (!authed) {
    return (
      <Theme theme={theme} mode="light">
        <AuthScreen step={step} busy={busy} status={status} phone={phone} code={code} name={name} pin={pin}
          connectors={connectors} linked={linked}
          onPhone={setPhone} onCode={setCode} onName={setName} onPin={setPin}
          onToggleLink={(id) => setLinked((l) => l.includes(id) ? l.filter((x) => x !== id) : [...l, id])}
          onContinuePhone={() => void run(async () => {
            await post("/hatch/auth/start", { phone: phone.trim() });
            await post("/hatch/auth/send_otp", { challenge_id: "stub" });
            setStep(1);
          })}
          onConfirmCode={() => void run(async () => {
            await post("/hatch/auth/confirm_otp", { challenge_id: "stub", code: code.trim() });
            setStep(2);
          })}
          onBackToPhone={() => setStep(0)}
          onContinueAccount={() => void run(async () => {
            await post("/hatch/auth/select_account", { account_id: "u1" });
            const c = await api("/api/connectors");
            setConnectors(c.connectors ?? []);
            setStep(3);
          })}
          onContinueConnectors={() => setStep(4)}
          onActivate={() => void run(async () => {
            const v = await api("/hatch/fetch_vms");
            const id = v.vms?.[0]?.vm_id ?? (await post("/hatch/lease_vm", {})).vm_id;
            await post("/hatch/vm/wake", { vm_id: id });
            setStep(5);
          })}
          onAcceptTos={() => void run(async () => {
            await post("/hatch/accept_tos", {});
            setAuthed(true);
          })}
          onOpenLegal={() => setLegalOpen(true)} />
      </Theme>
    );
  }

  const current = threads.find((t) => t.id === threadId);
  const shell = {
    tab, title: current?.title ?? "New chat", plan, status,
    threads, threadId, query, msgs: messages[threadId] ?? [], feed, profile,
    attachments, threadsOpen, renameOpen, rename, logoutOpen, legalOpen, feedOpen, busy,
    onTab: setTab, onQuery: setQuery, onThread: (id: string) => void run(() => loadThread(id)),
    onThreadsOpen: setThreadsOpen, onSend: (v: string) => void send(v),
    onAttach: () => setAttachments((l) => [...l, `file${l.length + 1}`]),
    onRemoveAttachment: (a: string) => setAttachments((l) => l.filter((x) => x !== a)),
    onDictate: () => setStatus("Mic is a visual stub"),
    onRename: setRename, onRenameOpen: setRenameOpen,
    onSaveRename: () => void run(async () => {
      await post("/api/session/rename", { id: threadId, title: rename });
      setThreads((ts) => ts.map((t) => (t.id === threadId ? { ...t, title: rename } : t)));
      setRenameOpen(false);
    }),
    onLegalOpen: setLegalOpen, onFeedOpen: setFeedOpen, onLogoutOpen: setLogoutOpen,
    onLogout: () => { setLogoutOpen(false); setAuthed(false); setStep(0); setMessages({}); },
    onHelp: () => setStatus("Help is a stub"),
  };
  return (
    <Theme theme={theme} mode="light">
      <MobileShell {...shell} />
      <MobileDialogs {...shell} />
    </Theme>
  );
}
