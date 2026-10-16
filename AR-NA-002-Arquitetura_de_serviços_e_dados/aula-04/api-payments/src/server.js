const http = require('node:http');

const port = 4000;
const paymentMessages = {
  pix: 'PIX payment of {value} was completed successfully!',
  creditcard: 'Credit card payment of {value} was completed successfully!',
  debit: 'Debit payment of {value} was completed successfully!',
};

function sendJson(response, statusCode, body) {
  response.writeHead(statusCode, { 'Content-Type': 'application/json; charset=utf-8' });
  response.end(JSON.stringify(body, null, 2));
}

const server = http.createServer((request, response) => {
  const requestId = request.headers['x-request-id'] || 'direct-request';
  const isHealthCheck = request.headers['x-health-check'] === 'true';
  const startedAt = Date.now();

  if (!isHealthCheck) {
    console.log(`PAYMENTS [${requestId}] -> ${request.method} ${request.url}`);
    response.once('finish', () => {
      console.log(`PAYMENTS [${requestId}] <- ${response.statusCode} (${Date.now() - startedAt}ms)`);
    });
  }

  const match = request.url.match(/^\/(pix|creditcard|debit)\/([^/]+)$/);

  if (request.method === 'POST' && match) {
    const paymentType = match[1];
    const value = Number(decodeURIComponent(match[2]));

    if (!Number.isFinite(value) || value < 0) {
      sendJson(response, 400, { error: 'Value must be a valid non-negative number.' });
      return;
    }

    const formattedValue = value.toFixed(2);
    sendJson(response, 200, {
      message: paymentMessages[paymentType].replace('{value}', formattedValue),
    });
    return;
  }

  sendJson(response, 404, { error: 'not found' });
});

server.listen(port, '0.0.0.0', () => {
  console.log(`Payments API listening on port ${port}`);
});