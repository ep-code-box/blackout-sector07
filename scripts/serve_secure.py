import http.server
import socketserver
import os

class SecureHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        super().end_headers()

os.chdir('make/web_build')
PORT = 8090
with socketserver.TCPServer(("", PORT), SecureHTTPRequestHandler) as httpd:
    print(f"Serving at port {PORT} with COOP/COEP headers for SharedArrayBuffer...")
    httpd.serve_forever()
