use std::io::{self, Write};
use std::path::PathBuf;

use anyhow::Result;
use iroh::endpoint::presets::N0;
use iroh::endpoint::Connection;
use iroh::Endpoint;
use iroh_tickets::endpoint::EndpointTicket;
use n0_future::StreamExt;
use tokio::io::{AsyncBufReadExt, BufReader};

const ALPN: &[u8] = b"metamuse-poc/0";
const MAX: usize = 10 << 20;

fn normal_ticket(ep: &Endpoint) -> EndpointTicket {
    EndpointTicket::new(ep.addr())
}

async fn show(
    kind: u8,
    data: &[u8],
    blobs: &iroh_blobs::BlobsProtocol,
    ep: &Endpoint,
) -> Result<()> {
    match kind {
        b'b' => {
            use iroh_blobs::ticket::BlobTicket;
            let ticket: BlobTicket = std::str::from_utf8(data)?.parse()?;
            let hash = ticket.hash();
            eprintln!("[recv] downloading {} from {}", hash, ticket.addr().id);
            // ponytail: hold TempTag alive until export finishes or GC may collect it
            let downloader = blobs.store().downloader(ep);
            let progress = downloader.download(hash, [ticket.addr().id]);
            let mut stream = Box::pin(progress.stream().await?);
            while let Some(item) = stream.next().await {
                use iroh_blobs::api::downloader::DownloadProgressItem;
                match item {
                    DownloadProgressItem::Progress(n) => {
                        eprintln!("[recv] {n} bytes");
                    }
                    DownloadProgressItem::TryProvider { id, .. } => {
                        eprintln!("[recv] trying provider {id}");
                    }
                    DownloadProgressItem::ProviderFailed { id, .. } => {
                        eprintln!("[recv] provider failed: {id}");
                    }
                    DownloadProgressItem::PartComplete { .. } => {
                        eprintln!("[recv] part complete");
                    }
                    DownloadProgressItem::Error(e) => {
                        anyhow::bail!("download error: {e:#}");
                    }
                    DownloadProgressItem::DownloadError => {
                        anyhow::bail!("download failed");
                    }
                }
            }
            eprintln!("[recv] downloaded {hash}, exporting…");
            let out = std::env::temp_dir().join(format!("rx_{hash}.bin"));
            blobs.store().blobs().export(hash, &out).await?;
            println!("got blob -> {}", out.display());
        }
        b'f' => {
            let name: String = data.iter().take(4).map(|b| format!("{b:02x}")).collect();
            let p = std::env::temp_dir().join(format!("rx_{name}.bin"));
            std::fs::write(&p, data).expect("write file");
            println!("got image -> {}", p.display());
        }
        _ => println!("got text: {}", String::from_utf8_lossy(data)),
    }
    Ok(())
}

/// Reads stdin lines and sends each as one message. EOF (Ctrl-D) ends it.
/// A file path is imported into the blob store and announced as a
/// `BlobTicket` (kind `b`); anything else goes as plain text (kind `t`).
async fn send_loop(
    conn: &Connection,
    blobs: &iroh_blobs::BlobsProtocol,
    ep: &Endpoint,
) -> Result<()> {
    let mut lines = BufReader::new(tokio::io::stdin()).lines();
    loop {
        print!("path or text> ");
        io::stdout().flush().expect("stdout");
        let Some(line) = lines.next_line().await? else {
            break;
        };
        let input = line.trim().to_owned();
        if input.is_empty() {
            continue;
        }
        let p = PathBuf::from(&input);
        let (kind, data) = if p.is_file() {
            use iroh_blobs::api::blobs::{AddPathOptions, ImportMode};
            let abs = std::path::absolute(&p)?;
            let total = std::fs::metadata(&abs)?.len();
            eprintln!("[send] hashing {} ({total} bytes)…", p.display());
            let tag = blobs
                .store()
                .blobs()
                .add_path_with_opts(AddPathOptions {
                    path: abs,
                    mode: ImportMode::TryReference,
                    format: iroh_blobs::BlobFormat::Raw,
                })
                .temp_tag()
                .await?;
            let ticket =
                iroh_blobs::ticket::BlobTicket::new(ep.addr().clone(), tag.hash(), tag.format());
            eprintln!("[send] sharing {} ({total} bytes)", p.display());
            (b'b', ticket.to_string().into_bytes())
        } else {
            (b't', input.into_bytes())
        };
        let mut send = conn.open_uni().await?;
        send.write_all(&[kind]).await?;
        send.write_all(&data).await?;
        send.finish()?;
    }
    Ok(())
}

async fn recv_loop(
    conn: &Connection,
    blobs: &iroh_blobs::BlobsProtocol,
    ep: &Endpoint,
) -> Result<()> {
    loop {
        let mut recv = conn.accept_uni().await?;
        let mut kind = [0u8; 1];
        recv.read_exact(&mut kind).await?;
        let data = recv.read_to_end(MAX).await?;
        show(kind[0], &data, blobs, ep).await?;
    }
}

/// Server side: receive only, per the docs transfer.rs pattern. Never reads
/// stdin (headless under hub) and never closes — the dialer owns `close`.
async fn serve_chat(conn: Connection, blobs: iroh_blobs::BlobsProtocol, ep: Endpoint) -> Result<()> {
    println!("connected to {}", conn.remote_id());
    recv_loop(&conn, &blobs, &ep).await
}

/// Dial side: duplex send/recv. After stdin EOF, lingers so the peer can
/// finish fetching blobs before we close and exit.
async fn dial_chat(conn: Connection, blobs: iroh_blobs::BlobsProtocol, ep: Endpoint) -> Result<()> {
    println!("connected to {}", conn.remote_id());
    let recv_task = tokio::spawn({
        let conn = conn.clone();
        let blobs = blobs.clone();
        let ep = ep.clone();
        async move { recv_loop(&conn, &blobs, &ep).await }
    });
    let send_res = send_loop(&conn, &blobs, &ep).await;
    // ponytail: fixed 60s drain so the peer can fetch blobs before we exit
    eprintln!("[send] stdin done; lingering 60s for peer blob fetch…");
    tokio::time::sleep(std::time::Duration::from_secs(60)).await;
    conn.close(0u32.into(), b"done");
    match recv_task.await {
        Ok(recv_res) => send_res.and(recv_res),
        Err(e) => Err(anyhow::anyhow!("recv task failed: {e}")),
    }
}

#[derive(Debug, Clone)]
struct ChatProto {
    blobs: iroh_blobs::BlobsProtocol,
    ep: Endpoint,
}
impl iroh::protocol::ProtocolHandler for ChatProto {
    async fn accept(
        &self,
        conn: iroh::endpoint::Connection,
    ) -> Result<(), iroh::protocol::AcceptError> {
        serve_chat(conn, self.blobs.clone(), self.ep.clone())
            .await
            .map_err(|e| {
                iroh::protocol::AcceptError::from_err(std::io::Error::other(format!("{e:#}")))
            })
    }
}

async fn serve(ep: Endpoint) -> Result<()> {
    let dir = std::env::temp_dir().join(format!("metamuse-serve-{}", std::process::id()));
    std::fs::create_dir_all(&dir)?;
    let store = iroh_blobs::store::fs::FsStore::load(&dir).await?;
    let blobs = iroh_blobs::BlobsProtocol::new(&store.into(), None);
    let router = iroh::protocol::Router::builder(ep.clone())
        .accept(iroh_blobs::ALPN, blobs.clone())
        .accept(
            ALPN,
            ChatProto {
                blobs,
                ep: ep.clone(),
            },
        )
        .spawn();
    let ticket = normal_ticket(&ep);
    println!("ticket: {ticket}");
    tokio::signal::ctrl_c().await?;
    router.shutdown().await?;
    Ok(())
}

async fn dial(ep: Endpoint, ticket: &str) -> Result<()> {
    let addr = ticket.parse::<EndpointTicket>()?.endpoint_addr().clone();
    let dir = std::env::temp_dir().join(format!("metamuse-dial-{}", std::process::id()));
    std::fs::create_dir_all(&dir)?;
    let store = iroh_blobs::store::fs::FsStore::load(&dir).await?;
    let blobs = iroh_blobs::BlobsProtocol::new(&store.into(), None);
    let _router = iroh::protocol::Router::builder(ep.clone())
        .accept(iroh_blobs::ALPN, blobs.clone())
        .spawn();
    let conn = ep.connect(addr, ALPN).await?;
    dial_chat(conn, blobs, ep).await
}

#[tokio::main]
async fn main() -> Result<()> {
    let args: Vec<String> = std::env::args().collect();
    let ep = Endpoint::builder(N0).bind().await?;
    if args.len() == 3 && args[1] == "--connect" {
        dial(ep, &args[2]).await?;
    } else {
        serve(ep).await?;
    }
    Ok(())
}
