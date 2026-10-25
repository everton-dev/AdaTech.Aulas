using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace AdaSupplyDemo
{
    public class InventoryFunctions
    {
        private readonly ILogger<InventoryFunctions> _logger;

        public InventoryFunctions(ILogger<InventoryFunctions> logger)
        {
            _logger = logger;
        }

        [Function("Ping")]
        public IActionResult Ping([HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "ping")] HttpRequest req)
        {
            return new OkObjectResult(new { status = "ok" });
        }

        // Usa Newtonsoft.Json (12.0.1, CVE-2024-21907) de verdade, nao so declarado no csproj,
        // para que a dependencia vulneravel esteja efetivamente em uso pela aplicacao.
        [Function("EchoPayload")]
        public IActionResult EchoPayload([HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "inventory/echo")] HttpRequest req)
        {
            using var reader = new StreamReader(req.Body);
            var body = reader.ReadToEnd();
            var payload = JsonConvert.DeserializeObject(body);
            _logger.LogInformation("Payload recebido via EchoPayload.");
            return new OkObjectResult(payload);
        }
    }
}
