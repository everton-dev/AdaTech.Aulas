const http = require('node:http');

const port = 3000;

function sendJson(response, statusCode, body) {
  response.writeHead(statusCode, { 'Content-Type': 'application/json; charset=utf-8' });
  response.end(JSON.stringify(body, null, 2));
}

const server = http.createServer((request, response) => {
  const requestId = request.headers['x-request-id'] || 'direct-request';
  const isHealthCheck = request.headers['x-health-check'] === 'true';
  const startedAt = Date.now();

  if (!isHealthCheck) {
    console.log(`MESSAGES [${requestId}] -> ${request.method} ${request.url}`);
    response.once('finish', () => {
      console.log(`MESSAGES [${requestId}] <- ${response.statusCode} (${Date.now() - startedAt}ms)`);
    });
  }

  if (request.method === 'GET' && request.url === '/day') {
    sendJson(response, 200, { message: 'Every day is a new opportunity.' });
    return;
  }

  sendJson(response, 404, { error: 'not found' });
});

server.listen(port, '0.0.0.0', () => {
  console.log(`Messages API listening on port ${port}`);
});