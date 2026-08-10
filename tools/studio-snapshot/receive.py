#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "docs" / "snapshots"
PORT = 8765


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt: str, *args) -> None:
        sys.stderr.write("%s - %s\n" % (self.address_string(), fmt % args))

    def do_POST(self) -> None:
        if self.path.rstrip("/") != "/snapshot":
            self.send_error(404)
            return

        length = int(self.headers.get("Content-Length", "0"))
        raw = self.rfile.read(length)

        try:
            data = json.loads(raw.decode("utf-8"))
        except json.JSONDecodeError as exc:
            self.send_error(400, f"invalid json: {exc}")
            return

        OUT_DIR.mkdir(parents=True, exist_ok=True)
        stamp = datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%S")
        mode = data.get("mode") or "map"
        latest = OUT_DIR / "latest.json"
        stamped = OUT_DIR / f"{mode}-{stamp}.json"

        text = json.dumps(data, ensure_ascii=False, indent=2)
        stamped.write_text(text + "\n", encoding="utf-8")
        latest.write_text(text + "\n", encoding="utf-8")

        body = json.dumps(
            {
                "ok": True,
                "wrote": [str(stamped.relative_to(ROOT)), str(latest.relative_to(ROOT))],
                "bytes": len(raw),
            }
        ).encode("utf-8")

        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

        print(f"saved {stamped.relative_to(ROOT)} ({len(raw)} bytes)")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    server = HTTPServer(("127.0.0.1", PORT), Handler)
    print(f"listening on http://127.0.0.1:{PORT}/snapshot")
    print(f"writes to {OUT_DIR}")
    print("in Studio: Plugins → Map Snapshot → Snapshot Map / Selection")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nbye")


if __name__ == "__main__":
    main()
