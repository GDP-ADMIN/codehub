from http.server import BaseHTTPRequestHandler, HTTPServer

class HelloHandler(BaseHTTPRequestHandler):
  def do_GET(self):
    self.send_response(200)
    self.send_header('Content-type', 'text/plain')
    self.end_headers()
    self.wfile.write(b'Hello from Firecracker Python HTTP server!\n')

if __name__ == '__main__':
  server = HTTPServer(('0.0.0.0', 80), HelloHandler)
  print('Serving HTTP on port 80...')
  server.serve_forever()
