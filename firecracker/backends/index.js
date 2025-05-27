const http = require('http');
const PORT = 80;
const server = http.createServer((req, res) => {
    res.writeHead(200, {'Content-Type': 'text/plain'});
    res.end('Hello World from Node.js on Firecracker!\n');
});
server.listen(PORT, () => {
    console.log("Server running at http://0.0.0.0:" + PORT + "/");
});
