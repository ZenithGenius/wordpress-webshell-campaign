#!/usr/bin/env python3
"""Local, harmless stand-in for the campaign's redirect and C2 infrastructure.

It plays three roles on the isolated lab network so nothing ever reaches the real
attacker hosts:
  - shortener target: the injected redirect points here instead of ushort[.]company
  - C2 stager host:   the neutered stager fetches from here instead of the real C2
  - beacon collector: logs check-ins so you can see the pattern in one place

Every response is benign text. There is no payload, no redirect chain, no tracking.
"""
import http.server, socketserver, datetime, sys

PORT = 8080

BANNER = "LAB SINK  (stands in for shortener + C2, serves nothing harmful)\n"

class Handler(http.server.BaseHTTPRequestHandler):
    def _log(self, kind):
        ts = datetime.datetime.now(datetime.timezone.utc).strftime("%H:%M:%S")
        sys.stdout.write(f"[{ts}] {kind:6} {self.client_address[0]:>15}  {self.path}\n")
        sys.stdout.flush()

    def _send(self, body, ctype="text/plain"):
        data = body.encode()
        self.send_response(200)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        self._log("GET")
        # C2 stager path: the real campaign would return PHP to eval(). We return an
        # inert marker so the neutered stager has something to display, never run.
        if self.path.endswith(".txt") or self.path.startswith("/door"):
            self._send("// lab-c2: no payload served. This is a benign sink.\n")
        else:
            # shortener / promo landing the redirect points at
            self._send(BANNER + "You were 'redirected' here by the lab injection.\n"
                       "On a real victim this would be a monetized shortener page.\n")

    def do_POST(self):
        self._log("BEACON")
        length = int(self.headers.get("Content-Length", 0) or 0)
        if length:
            self.rfile.read(length)
        self._send("ok\n")

    def log_message(self, *a):
        pass  # we do our own logging

if __name__ == "__main__":
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("0.0.0.0", PORT), Handler) as httpd:
        sys.stdout.write(f"lab sink listening on :{PORT}\n"); sys.stdout.flush()
        httpd.serve_forever()
