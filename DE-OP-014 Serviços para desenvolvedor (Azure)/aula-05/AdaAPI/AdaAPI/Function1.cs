using AdaAPI.Repositories;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace AdaAPI
{
    public class Function1
    {
        private readonly ILogger<Function1> _logger;
        private readonly IConfiguration _configuration;
        private readonly CarRepository _carRepository;

        public Function1(ILogger<Function1> logger, IConfiguration configuration)
        {
            _logger = logger;
            _configuration = configuration;

            _carRepository = new CarRepository(_logger, _configuration);
            logger.LogInformation("API has been initialized.");
        }

        [Function("RetrieveAll")]
        public async Task<IActionResult> RetrieveAll([HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "cars")] HttpRequest req)
        {
            _logger.LogInformation($"RetrieveAll response [{DateTime.Now.ToString("dd/MM/yyyy HH:mm:ss")}].");
            return new OkObjectResult(new List<Car>() 
            { 
                new Car() { Id = 1, Brand = "b1", Model = "m1", Year = 2026 },
                new Car() { Id = 2, Brand = "b2", Model = "m2", Year = 2026 },
                new Car() { Id = 3, Brand = "b3", Model = "m3", Year = 2026 }
            });
            //return new OkObjectResult(new OkObjectResult(await _carRepository.RetrieveAll()));
        }

        [Function("RetrieveById")]
        public async Task<IActionResult> RetrieveById([HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "cars/{id}")] HttpRequest req, int id)
        {
            _logger.LogInformation($"RetrieveAll response [{DateTime.Now.ToString("dd/MM/yyyy HH:mm:ss")}].");
            return new OkObjectResult(new Car() { Id = 1, Brand = "b1", Model = "m1", Year = 2026 });
            //return new OkObjectResult(new OkObjectResult(await _carRepository.RetrieveById(id)));
        }

        [Function("Insert")]
        public async Task<IActionResult> Insert([HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "cars")] HttpRequest req)
        {
            _logger.LogInformation($"Insert response [{DateTime.Now.ToString("dd/MM/yyyy HH:mm:ss")}].");
            //var requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            //var car = JsonConvert.DeserializeObject<Car>(requestBody);
            //car.Id = await _carRepository.Insert(car);
            //return new OkObjectResult(new OkObjectResult(car));
            return new OkObjectResult(new Car() { Id = 1, Brand = "b1", Model = "m1", Year = 2026 });
        }

        [Function("Update")]
        public async Task<IActionResult> Update([HttpTrigger(AuthorizationLevel.Anonymous, "put", Route = "cars/{id}")] HttpRequest req, int id)
        {
            _logger.LogInformation($"Update response [{DateTime.Now.ToString("dd/MM/yyyy HH:mm:ss")}].");
            //var requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            //var car = JsonConvert.DeserializeObject<Car>(requestBody);
            //var rowsAffected = await _carRepository.Insert(car);
            //return new OkObjectResult(new OkObjectResult(car));
            return new OkObjectResult(new Car() { Id = 1, Brand = "b1", Model = "m1", Year = 2026 });
        }

        [Function("Delete")]
        public async Task<IActionResult> Delete([HttpTrigger(AuthorizationLevel.Anonymous, "delete", Route = "cars/{id}")] HttpRequest req, int id)
        {
            _logger.LogInformation($"delete response [{DateTime.Now.ToString("dd/MM/yyyy HH:mm:ss")}].");
            var rowsAffected = await _carRepository.Delete(id);
            return new OkObjectResult(new OkResult());
        }

        [Function("RequestError")]
        public async Task<IActionResult> RequestError([HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "cars/error")] HttpRequest req)
        {
            _logger.LogInformation($"RequestError response [{DateTime.Now.ToString("dd/MM/yyyy HH:mm:ss")}].");
            await Task.CompletedTask;
            throw new Exception("Custom Error on request.");
        }
    }
}