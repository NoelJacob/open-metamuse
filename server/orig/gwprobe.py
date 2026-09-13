#!/usr/bin/env python3
"""TLS probe: terminates TLS with mitm-CA-signed cert, logs raw client bytes.

Run: python3 gwprobe.py  (listens 0.0.0.0:9443, certs in /tmp/gwprobe/)
Holds each connection open 60s so the client speaks first.
"""
import socket
import ssl
import threading
import time

CERT = "/tmp/gwprobe/leaf.crt"
KEY = "/tmp/gwprobe/leaf.key"
LOG = "/tmp/gwprobe/bytes.log"


def handle(conn, addr):
    print(f"conn from {addr}", flush=True)
    conn.settimeout(60)
    try:
        data = conn.recv(65536)
        n = 0
        while data:
            n += 1
            with open(LOG, "ab") as f:
                f.write(f"\n--- frame {n} {len(data)}b ---\n".encode())
                f.write(data[:4096])
            print(f"frame {n}: {len(data)}b head={data[:64].hex()}", flush=True)
            try:
                txt = data[:400].decode("utf-8", "replace")
                print(f"  text: {txt[:200]!r}", flush=True)
            except Exception:
                pass
            data = conn.recv(65536)
    except socket.timeout:
        print("idle timeout, holding", flush=True)
        time.sleep(60)
    except Exception as e:
        print(f"err {e}", flush=True)
    finally:
        try:
            conn.close()
        except Exception:
            pass


def main():
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.load_cert_chain(CERT, KEY)
    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    srv.bind(("0.0.0.0", 9443))
    srv.listen(5)
    print("gwprobe on :9443", flush=True)
    while True:
        raw, addr = srv.accept()
        try:
            conn = ctx.wrap_socket(raw, server_side=True)
        except Exception as e:
            print(f"tls fail {addr}: {e}", flush=True)
            raw.close()
            continue
        threading.Thread(target=handle, args=(conn, addr), daemon=True).start()


main()
