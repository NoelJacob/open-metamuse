use std::io::{self, Write};

use anyhow::Result;
use iroh::{endpoint::presets::N0, Endpoint};
use iroh_tickets::endpoint::EndpointTicket;
use tokio::io::{AsyncReadExt, AsyncWriteExt};

const ALPN: &[u8] = b"metamuse-stream/0";
// ponytail: 64KiB chunks — small enough to feel live, big enough to be efficient
const CHUNK: usize = 64 << 10;

// Frame on the wire: u16 meta-len | meta | u32 payload-len | payload.
// Meta is a content tag: b"text", or b"bin:<filename>" for file chunks.
async fn write_frame(
    w: &mut (impl AsyncWriteExt + Unpin),
    meta: &[u8],
    payload: &[u8],
) -> std::io::Result<()> {
    w.write_u16(meta.len() as u16).await?;
    w.write_all(meta).await?;
    w.write_u32(payload.len() as u32).await?;
    w.write_all(payload).await?;
    Ok(())
}

async fn read_frame(r: &mut (impl AsyncReadExt + Unpin)) -> std::io::Result<(Vec<u8>, Vec<u8>)> {
    let ml = r.read_u16().await? as usize;
    let mut meta = vec![0u8; ml];
    r.read_exact(&mut meta).await?;
    let len = r.read_u32().await? as usize;
    let mut payload = vec![0u8; len];
    r.read_exact(&mut payload).await?;
    Ok((meta, payload))
}

// Byte source -> peer. Same framed path for stdin text and file chunks:
// text frames carry one typed line, file frames carry raw CHUNK bytes.
async fn send_stream(
    w: &mut (impl AsyncWriteExt + Unpin),
    mut src: impl AsyncReadExt + Unpin,
    meta: &str,
    by_line: bool,
) -> Result<()> {
    if by_line {
        let mut buf = Vec::new();
        loop {
            buf.clear();
            let mut byte = [0u8; 1];
            loop {
                let n = src.read(&mut byte).await?;
                if n == 0 {
                    if !buf.is_empty() {
                        write_frame(w, meta.as_bytes(), &buf).await?;
                    }
                    w.shutdown().await?;
                    return Ok(());
                }
                if byte[0] == b'\n' {
                    break;
                }
                buf.push(byte[0]);
            }
            if !buf.is_empty() {
                write_frame(w, meta.as_bytes(), &buf).await?;
            }
        }
    }
    let mut chunk = vec![0u8; CHUNK];
    loop {
        let n = src.read(&mut chunk).await?;
        if n == 0 {
            break;
        }
        write_frame(w, meta.as_bytes(), &chunk[..n]).await?;
    }
    w.shutdown().await?;
    Ok(())
}
// Peer frames -> stdout for text, appended to one file per bin:<name> stream.
async fn recv_loop(r: &mut (impl AsyncReadExt + Unpin)) -> Result<()> {
    use tokio::io::AsyncWriteExt;
    let mut out: Option<(tokio::fs::File, String, u64)> = None;
    loop {
        match read_frame(r).await {
            Ok((meta, payload)) => {
                let meta = String::from_utf8_lossy(&meta).into_owned();
                if meta == "text" {
                    println!("[text] {}", String::from_utf8_lossy(&payload));
                } else {
                    let raw = meta.strip_prefix("bin:").unwrap_or("stream");
                    // ponytail: strip peer-supplied path — never write outside /tmp
                    let name: String = std::path::Path::new(raw).file_name().map(|s| s.to_string_lossy().into_owned()).unwrap_or_else(|| "stream".into());
                    // ponytail: one file per stream name, append chunks in order
                    let fresh = !matches!(&out, Some((_, n, _)) if n == &name);
                    if fresh {
                        if let Some((_, n, total)) = out.take() {
                            println!("[bin:{n}] done, {total} bytes");
                        }
                        let p = std::env::temp_dir().join(format!("rx_{name}.bin"));
                        let _ = tokio::fs::remove_file(&p).await;
                        let f = tokio::fs::OpenOptions::new()
                            .create(true)
                            .append(true)
                            .open(&p)
                            .await?;
                        println!("[bin:{name}] -> {}", p.display());
                        out = Some((f, name.to_owned(), 0));
                    }
                    if let Some((f, _, total)) = out.as_mut() {
                        f.write_all(&payload).await?;
                        *total += payload.len() as u64;
                    }
                }
            }
            Err(e) if e.kind() == std::io::ErrorKind::UnexpectedEof => {
                if let Some((_, n, total)) = out {
                    println!("[bin:{n}] done, {total} bytes");
                }
                return Ok(());
            }
            Err(e) => return Err(e.into()),
        }
    }
}

// Both sides identical once the bi stream exists: send our source, print peer's.
// Peer going away mid-chat is a clean end; exit follows our own send path.
async fn chat(
    mut send: impl AsyncWriteExt + Unpin,
    mut recv: impl AsyncReadExt + Unpin,
    src: impl AsyncReadExt + Unpin,
    meta: String,
    by_line: bool,
) -> Result<()> {
    let (send_res, recv_res) =
        tokio::join!(send_stream(&mut send, src, &meta, by_line), recv_loop(&mut recv));
    if let Err(e) = &recv_res {
        eprintln!("[peer] {e:#}");
    }
    send_res
}

#[derive(Debug, Clone)]
struct ChatProto {
    file: Option<String>,
}
impl iroh::protocol::ProtocolHandler for ChatProto {
    async fn accept(
        &self,
        conn: iroh::endpoint::Connection,
    ) -> Result<(), iroh::protocol::AcceptError> {
        println!("connected to {}", conn.remote_id());
        let (send, recv) = conn
            .accept_bi()
            .await
            .map_err(|e| iroh::protocol::AcceptError::from_err(std::io::Error::other(e)))?;
        // Serve side mirrors the dialer's mode: file arg serves chunks, else stdin text.
        if let Some(path) = &self.file {
            let f = tokio::fs::File::open(path).await.map_err(|e| {
                iroh::protocol::AcceptError::from_err(std::io::Error::other(e))
            })?;
            let meta = format!("bin:{}", std::path::Path::new(path).file_name().map(|s| s.to_string_lossy().into_owned()).unwrap_or_else(|| path.clone()));
            chat(send, recv, f, meta, false).await.map_err(|e| {
                iroh::protocol::AcceptError::from_err(std::io::Error::other(format!("{e:#}")))
            })
        } else {
            chat(send, recv, tokio::io::stdin(), "text".into(), true)
                .await
                .map_err(|e| {
                    iroh::protocol::AcceptError::from_err(std::io::Error::other(format!("{e:#}")))
                })
        }
    }
}

async fn serve(ep: Endpoint, file: Option<String>) -> Result<()> {
    let router = iroh::protocol::Router::builder(ep.clone())
        .accept(ALPN, ChatProto { file })
        .spawn();
    println!("ticket: {}", EndpointTicket::new(ep.addr()));
    tokio::signal::ctrl_c().await?;
    router.shutdown().await?;
    Ok(())
}

async fn dial(ep: Endpoint, ticket: &str, file: Option<String>) -> Result<()> {
    let addr = ticket.parse::<EndpointTicket>()?.endpoint_addr().clone();
    let conn = ep.connect(addr, ALPN).await?;
    println!("connected to {}", conn.remote_id());
    let (send, recv) = conn.open_bi().await?;
    if let Some(path) = file {
        let f = tokio::fs::File::open(&path).await?;
        let name = std::path::Path::new(&path)
            .file_name()
            .map(|s| s.to_string_lossy().into_owned())
            .unwrap_or(path);
        chat(send, recv, f, format!("bin:{name}"), false).await
    } else {
        chat(send, recv, tokio::io::stdin(), "text".into(), true).await
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    // Usage: desktop [--file PATH] | desktop --connect TICKET [--file PATH]
    let mut file: Option<String> = None;
    let mut ticket: Option<String> = None;
    let mut it = std::env::args().skip(1).peekable();
    while let Some(a) = it.next() {
        match a.as_str() {
            "--file" => file = it.next(),
            "--connect" => ticket = it.next(),
            _ => {
                eprintln!("usage: desktop [--file PATH] | desktop --connect TICKET [--file PATH]");
                std::process::exit(2);
            }
        }
    }
    // ponytail: keep stdin prompt on tty only — pipes stay clean for tests
    if file.is_none() && std::io::IsTerminal::is_terminal(&std::io::stdin()) {
        print!("> ");
        io::stdout().flush().expect("stdout");
    }
    let ep = Endpoint::builder(N0).bind().await?;
    if let Some(t) = ticket {
        dial(ep, &t, file).await
    } else {
        serve(ep, file).await
    }
}
