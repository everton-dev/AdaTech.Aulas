using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Attributes;
using Microsoft.Extensions.Logging;
using Microsoft.OpenApi.Models;
using System.Net;
using AdaTech.Products.Api.Repositories;

namespace AdaTech.Products.Api;

public class ProductsFunction
{
    private readonly ILogger<ProductsFunction> _logger;
    private readonly ProductRepository _repository;

    public ProductsFunction(ILogger<ProductsFunction> logger, ProductRepository repository)
    {
        _logger = logger;
        _repository = repository;
    }

    [Function("GetAllProducts")]
    [OpenApiOperation(operationId: "GetAllProducts", tags: ["Products"], Summary = "Get all products", Description = "Returns all products from the database.")]
    [OpenApiResponseWithBody(statusCode: HttpStatusCode.OK, contentType: "application/json", bodyType: typeof(IEnumerable<Product>), Description = "List of products")]
    public async Task<IActionResult> GetAll(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "products")] HttpRequest req)
    {
        _logger.LogInformation("Getting all products.");
        var products = await _repository.RetrieveAll();
        return new OkObjectResult(products);
    }

    [Function("GetProductById")]
    [OpenApiOperation(operationId: "GetProductById", tags: ["Products"], Summary = "Get product by ID", Description = "Returns a single product by its ID.")]
    [OpenApiParameter(name: "id", In = ParameterLocation.Path, Required = true, Type = typeof(int), Description = "Product ID")]
    [OpenApiResponseWithBody(statusCode: HttpStatusCode.OK, contentType: "application/json", bodyType: typeof(Product), Description = "The product")]
    [OpenApiResponseWithoutBody(statusCode: HttpStatusCode.NotFound, Description = "Product not found")]
    public async Task<IActionResult> GetById(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "products/{id:int}")] HttpRequest req,
        int id)
    {
        _logger.LogInformation("Getting product with Id={Id}.", id);
        var product = await _repository.RetrieveById(id);
        if (product == null)
            return new NotFoundResult();

        return new OkObjectResult(product);
    }

    [Function("CreateProduct")]
    [OpenApiOperation(operationId: "CreateProduct", tags: ["Products"], Summary = "Create a product", Description = "Creates a new product in the database.")]
    [OpenApiRequestBody(contentType: "application/json", bodyType: typeof(Product), Required = true, Description = "Product to create")]
    [OpenApiResponseWithBody(statusCode: HttpStatusCode.Created, contentType: "application/json", bodyType: typeof(Product), Description = "Created product")]
    [OpenApiResponseWithBody(statusCode: HttpStatusCode.BadRequest, contentType: "application/json", bodyType: typeof(string), Description = "Invalid payload")]
    public async Task<IActionResult> Create(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "products")] HttpRequest req)
    {
        var product = await req.ReadFromJsonAsync<Product>();
        if (product == null)
            return new BadRequestObjectResult("Invalid product payload.");

        _logger.LogInformation("Creating product {Name}.", product.Name);
        var newId = await _repository.Insert(product);
        product.Id = newId;

        return new CreatedResult($"/api/products/{newId}", product);
    }

    [Function("UpdateProduct")]
    [OpenApiOperation(operationId: "UpdateProduct", tags: ["Products"], Summary = "Update a product", Description = "Updates an existing product by its ID.")]
    [OpenApiParameter(name: "id", In = ParameterLocation.Path, Required = true, Type = typeof(int), Description = "Product ID")]
    [OpenApiRequestBody(contentType: "application/json", bodyType: typeof(Product), Required = true, Description = "Updated product data")]
    [OpenApiResponseWithBody(statusCode: HttpStatusCode.OK, contentType: "application/json", bodyType: typeof(Product), Description = "Updated product")]
    [OpenApiResponseWithoutBody(statusCode: HttpStatusCode.BadRequest, Description = "Invalid payload")]
    [OpenApiResponseWithoutBody(statusCode: HttpStatusCode.NotFound, Description = "Product not found")]
    public async Task<IActionResult> Update(
        [HttpTrigger(AuthorizationLevel.Anonymous, "put", Route = "products/{id:int}")] HttpRequest req,
        int id)
    {
        var product = await req.ReadFromJsonAsync<Product>();
        if (product == null)
            return new BadRequestObjectResult("Invalid product payload.");

        _logger.LogInformation("Updating product Id={Id}.", id);
        var rows = await _repository.Update(id, product);
        if (rows == 0)
            return new NotFoundResult();

        return new OkObjectResult(product);
    }

    [Function("DeleteProduct")]
    [OpenApiOperation(operationId: "DeleteProduct", tags: ["Products"], Summary = "Delete a product", Description = "Deletes a product by its ID.")]
    [OpenApiParameter(name: "id", In = ParameterLocation.Path, Required = true, Type = typeof(int), Description = "Product ID")]
    [OpenApiResponseWithoutBody(statusCode: HttpStatusCode.NoContent, Description = "Product deleted")]
    [OpenApiResponseWithoutBody(statusCode: HttpStatusCode.NotFound, Description = "Product not found")]
    public async Task<IActionResult> Delete(
        [HttpTrigger(AuthorizationLevel.Anonymous, "delete", Route = "products/{id:int}")] HttpRequest req,
        int id)
    {
        _logger.LogInformation("Deleting product Id={Id}.", id);
        var rows = await _repository.Delete(id);
        if (rows == 0)
            return new NotFoundResult();

        return new NoContentResult();
    }
}