using AdaAPI.Repositories;
using Microsoft.ApplicationInsights;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace AdaAPI
{
    public class Function1
    {
        private readonly ILogger<Function1> _logger;
        private readonly CarRepository _carRepository;
        private readonly TelemetryClient _telemetryClient;

        public Function1(ILogger<Function1> logger, TelemetryClient telemetryClient)
        {
            _logger = logger;
            _carRepository = new CarRepository();
            _telemetryClient = telemetryClient;
            logger.LogInformation("API has been initialized.");
        }

        [Function("RetrieveAll")]
        public IActionResult RetrieveAll([HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "cars")] HttpRequest req)
        {
            return new OkObjectResult(_carRepository.RetrieveAll().GetAwaiter().GetResult());
            //_logger.LogInformation("RetrieveAll");

            //// Track a custom event
            //_telemetryClient.TrackEvent("MyCustomEvent", new Dictionary<string, string> { { "Key", "Value" } });

            //// Track a custom metric
            //_telemetryClient.TrackMetric("MyCustomMetric", 123.45);
            //var cars = new List<Car>();

            //for (int i = 1; i <= 10; i++)
            //{
            //    cars.Add(new Car() { Id = i, Brand = $"VW-{i}", Model = $"New Beattle-{i}", Year = (2010 + i) });
            //}

            //return new OkObjectResult(cars);
        }

        [Function("RetrieveById")]
        public IActionResult RetrieveById([HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "cars/{id}")] HttpRequest req, int id) =>
            new OkObjectResult(_carRepository.RetrieveById(id).GetAwaiter().GetResult());
            //new OkObjectResult(new OkObjectResult(new Car() { Id = id, Brand = $"VW-{id}", Model = $"New Beattle - {id}", Year = (2010 + id) }));
    }
}