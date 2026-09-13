// Offline mock contract: single base URL bridged to the emulator via adb reverse.
export const API = "http://localhost:8787";

export type CardT = { kind: string; url?: string; title?: string };
export type Msg = { id: string; role: string; text: string; ts: string; cards?: CardT[]; reply_to?: string };
export type Thread = { id: string; title: string; unread?: number | boolean };
export type FeedUnit = { id: string; title: string; subtitle: string; kind: string };
export type Connector = { id: string; name: string };

export async function api(path: string, init?: RequestInit) {
  const r = await fetch(`${API}${path}`, {
    headers: { "content-type": "application/json" },
    ...init,
  });
  if (!r.ok) throw new Error(`${r.status} ${path}`);
  return r.json();
}

export const post = (path: string, body: unknown) =>
  api(path, { method: "POST", body: JSON.stringify(body) });
