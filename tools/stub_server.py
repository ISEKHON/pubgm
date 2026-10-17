"""Local stand-in for the dead/undesired PUBGM startup HTTP endpoints.

Purpose is diagnostic first: log exactly what the client asks for, then answer
in a way that might clear the update gate (see docs/06-startup-network.md).

The client requests
    /<appid>/20/apkupdate/<version>/..._apkupdate.json
having ALREADY decided <version> is the latest, so the JSON only supplies the
download package. Whether suppressing it clears the popup is exactly what this
tests.

Modes (--mode):
  404   answer every apkupdate request with 404        (default)
  same  answer with a package whose version equals the INSTALLED build
  empty answer with an empty JSON object

Usage:  python -I tools/stub_server.py [--port 80] [--mode 404]
"""
import argparse
import datetime
import json
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

INSTALLED = "0.3.2.3212"
MODE = "404"


def ts():
    return datetime.datetime.now().strftime("%H:%M:%S")


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, *a):          # silence the default stderr spam
        pass

    def _log(self):
        host = self.headers.get("Host", "?")
        print(f"[{ts()}] {self.command} http://{host}{self.path}")
        for k in ("User-Agent", "Range", "If-Modified-Since"):
            if self.headers.get(k):
                print(f"           {k}: {self.headers.get(k)}")
        sys.stdout.flush()

    def _send(self, code, body=b"", ctype="application/json"):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Connection", "keep-alive")
        self.end_headers()
        if body and self.command != "HEAD":
            self.wfile.write(body)

    def _handle(self):
        self._log()
        p = self.path.lower()
        if "apkupdate" in p and p.endswith(".json"):
            if MODE == "404":
                print("           -> 404 (claiming no such update package)")
                self._send(404, b'{"error":"not found"}')
            elif MODE == "empty":
                print("           -> {} (empty)")
                self._send(200, b"{}")
            else:
                # Mirror the real shape but point at the installed version, so
                # the client sees nothing newer than what it already has.
                body = json.dumps({
                    "AllChannelsFull": {
                        "md5": "0" * 32,
                        "name": f"stub_{INSTALLED}_apkupdate.apk",
                        "size": 0,
                        "url": "",
                        "version": INSTALLED,
                    }
                }).encode()
                print(f"           -> package advertising {INSTALLED}")
                self._send(200, body)
            sys.stdout.flush()
            return
        print("           -> 404 (unhandled path)")
        sys.stdout.flush()
        self._send(404, b'{"error":"not found"}')

    do_GET = _handle
    do_HEAD = _handle
    do_POST = _handle


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=80)
    ap.add_argument("--mode", default="404", choices=["404", "same", "empty"])
    a = ap.parse_args()
    global MODE
    MODE = a.mode
    srv = ThreadingHTTPServer(("0.0.0.0", a.port), Handler)
    print(f"stub server on 0.0.0.0:{a.port} mode={a.mode} (installed={INSTALLED})")
    sys.stdout.flush()
    srv.serve_forever()


if __name__ == "__main__":
    main()
