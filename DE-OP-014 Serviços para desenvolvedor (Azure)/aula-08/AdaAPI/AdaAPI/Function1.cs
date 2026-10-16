using AdaAPI.Repositories;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace AdaAPI
{
    public class Function1
    {
        private readonly ILogger<Function1> _logger;
        private readonly CarRepository _carRepository;
        private readonly IConfiguration _configuration;

        public Function1(ILogger<Function1> logger, IConfiguration configuration)
        {
            _logger = logger;
            _configuration = configuration;
            _carRepository = new CarRepository(logger, _configuration);
            logger.LogInformation("API has been initialized.");
        }

        [Function("RetrieveAll")]
        public IActionResult RetrieveAll([HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "cars")] HttpRequest req)
        {
            _logger.LogInformation($"RetrieveAll response [{DateTime.Now.ToString("dd/MM/yyyy HH:mm:ss")}].");
            return new OkObjectResult(_carRepository.RetrieveAll().GetAwaiter().GetResult());
        }

        [Function("RetrieveById")]
        public IActionResult RetrieveById([HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "cars/{id}")] HttpRequest req, int id)
        {
            _logger.LogInformation($"RetrieveAll response [{DateTime.Now.ToString("dd/MM/yyyy HH:mm:ss")}].");
            var carFound = _carRepository.RetrieveById(id).GetAwaiter().GetResult();
            var result = default(IActionResult);
            
            if (carFound == null)
                result = new NotFoundObjectResult($"Car with id {id} not found.");
            else
                result = new OkObjectResult(carFound);

            return result;
        }

        [Function("RequestError")]
        public IActionResult RequestError([HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "cars/error/{text}")] HttpRequest req, string text)
        {
            _logger.LogInformation($"RequestError response [{DateTime.Now.ToString("dd/MM/yyyy HH:mm:ss")}].");
            throw new Exception($"Custom Error on request: {text}");
        }
    }
}