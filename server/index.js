import { createServer } from "node:http";
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const dir = join(dirname(fileURLToPath(import.meta.url)), "data");
const load = (f) => JSON.parse(readFileSync(join(dir, f), "utf8"));
const threads = load("threads.json");
const messages = load("messages.json");
const units = load("feed.json");
const connectors = load("connectors.json");
const profile = load("profile.json");
// ponytail: serve the existing orig binary; no new assets to manage.
const demoImage = readFileSync(join(dir, "..", "orig", "demo.jpg"));

const PORT = process.env.PORT || 8787;
let n = 0;
const uid = (p) => `${p}${++n}_${Date.now().toString(36)}`;
const vm = (id = "vm1") => ({ vm_id: id, ws_url: `ws://localhost:${PORT}/vm/${id}`, status: "active" });
const now = () => new Date().toISOString();

const send = (res, code, obj) => {
  res.writeHead(code, { "content-type": "application/json" });
  res.end(JSON.stringify(obj));
};
const sendImage = (res) => {
  res.writeHead(200, { "content-type": "image/jpeg", "content-length": demoImage.length });
  res.end(demoImage);
};
const server = createServer((req, res) => {
  for (const [k, v] of [["Access-Control-Allow-Origin", "*"], ["Access-Control-Allow-Methods", "*"], ["Access-Control-Allow-Headers", "*"]]) res.setHeader(k, v);
  if (req.method === "OPTIONS") return res.writeHead(204).end();
  const u = new URL(req.url, "http://x");
  let body = "";
  req.on("data", (c) => (body += c));
  req.on("end", () => {
    let b = {};
    try { if (body) b = JSON.parse(body); } catch { return send(res, 400, { error: "invalid json" }); }
    console.log(`${req.method} ${u.pathname}`, JSON.stringify(b).slice(0, 120));
    const r = (o, code = 200) => send(res, code, o);
    const k = `${req.method} ${u.pathname}`;
    if (k === "POST /hatch/login") return r({ access_token: "tok_" + uid(""), user_id: "u1" });
    if (k === "POST /hatch/auth/start") return r({ challenge_id: uid("ch_") });
    if (k === "POST /hatch/auth/send_otp") return r({ ok: true });
    if (k === "POST /hatch/auth/confirm_otp")
      return b.code === "123456" ? r({ access_token: "tok_" + uid(""), user_id: "u1" }) : r({ error: "invalid code" }, 401);
    if (k === "POST /hatch/auth/select_account") return r({ access_token: "tok_" + uid(""), user_id: b.account_id || "u1" });
    if (k === "GET /hatch/fetch_vms") return r({ vms: [vm()] });
    if (k === "POST /hatch/lease_vm") return r(vm(uid("vm_")));
    if (k === "POST /hatch/vm/wake") return r({ vm_id: b.vm_id || "vm1", status: "active" });
    if (k === "POST /graphql") {
      const prompt = b?.variables?.prompt ?? "";
      if (typeof prompt === "string" && prompt.includes("feed")) return r({ data: { feed: { units } } });
      return r({ data: { reply: { text: String(prompt || "Hello from Muse!"), cards: [] } } });
    }
    if (k === "GET /api/session/list") return r({ threads });
    if (k === "POST /api/session/rename" || k === "POST /api/session/delete" || k === "POST /api/session/archive") return r({ ok: true });
    if (k === "GET /api/chat/history") return r({ messages: messages[u.searchParams.get("thread_id")] || [] });
    if (k === "POST /api/chat/send") {
      const text = String(b.text ?? "");
      const cards = /picture|image|photo/i.test(text)
        ? [{ kind: "image", url: `http://localhost:${PORT}/api/demo-image`, title: "demo.jpg" }]
        : [];
      return r({ message: { id: uid("m_"), role: "agent", text, ts: now(), cards } });
    }
    if (k === "GET /api/feed") return r({ units });
    if (k === "GET /api/connectors") return r({ connectors });
    if (k === "GET /hatch/subscription") return r({ plan: "free", credits: 100 });
    if (k === "GET /hatch/viewer/profile") return r(profile);
    if (k === "GET /api/demo-image") return sendImage(res);
    if (k === "POST /hatch/accept_tos") return r({ ok: true });
    return r({ error: "not found" }, 404);
  });
});

server.listen(PORT, () => console.log(`mock on ${PORT}`));
