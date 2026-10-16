using System.Diagnostics;
using System.Net;
using System.Text.Json;
using Ada.Aula06.ProductsApi.Data;
using Ada.Aula06.ProductsApi.Http;
using Ada.Aula06.ProductsApi.Models;
using Microsoft.ApplicationInsights;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Attributes;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Enums;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using Microsoft.OpenApi.Models;

namespace Ada.Aula06.ProductsApi.Functions;

/// <summary>
/// CRUD endpoints for the product catalog stored in Azure SQL.
/// </summary>
public sealed class ProductsFunctions(
    IProductRepository repository,
    TelemetryClient telemetryClient,
    ILogger<ProductsFunctions> logger)
{
    private const string Tag = "Products";
    private const string JsonContentType = "application/json";

    private static string TraceId => Activity.Current?.TraceId.ToString() ?? string.Empty;

    // ---------------------------------------------------------------------
    // GET /api/products
    // ---------------------------------------------------------------------

    [Function(nameof(GetProducts))]
    [OpenApiOperation(
        operationId: "getProducts",
        tags: [Tag],
        Summary = "List all products",
        Description = "Returns every row of the `products` table ordered by `id`.",
        Visibility = OpenApiVisibilityType.Important)]
    [OpenApiResponseWithBody(
        statusCode: HttpStatusCode.OK,
        contentType: JsonContentType,
        bodyType: typeof(List<Product>),
        Summary = "The full product catalog",
        Description = "A JSON array with every product currently stored.",
        Example = typeof(ProductListExample))]
    [OpenApiResponseWithBody(
        statusCode: HttpStatusCode.InternalServerError,
        contentType: JsonContentType,
        bodyType: typeof(ErrorResponse),
        Summary = "Unexpected failure",
        Description = "The database could not be reached or an unhandled error occurred.")]
    public async Task<HttpResponseData> GetProducts(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "products")] HttpRequestData request,
        CancellationToken cancellationToken)
    {
        try
        {
            var products = await repository.GetAllAsync(cancellationToken).ConfigureAwait(false);

            telemetryClient.GetMetric("Products.ListSize").TrackValue(products.Count);
            return await request.JsonAsync(HttpStatusCode.OK, products).ConfigureAwait(false);
        }
        catch (Exception exception) when (exception is not OperationCanceledException)
        {
            return await HandleUnexpectedAsync(request, exception, nameof(GetProducts)).ConfigureAwait(false);
        }
    }

    // ---------------------------------------------------------------------
    // GET /api/products/{id}
    // ---------------------------------------------------------------------

    [Function(nameof(GetProductById))]
    [OpenApiOperation(
        operationId: "getProductById",
        tags: [Tag],
        Summary = "Get a product by id",
        Description = "Returns a single product identified by its primary key.",
        Visibility = OpenApiVisibilityType.Important)]
    [OpenApiParameter(
        name: "id",
        In = ParameterLocation.Path,
        Required = true,
        Type = typeof(int),
        Summary = "Product id",
        Description = "Primary key of the product to retrieve.",
        Example = typeof(ProductIdExample))]
    [OpenApiResponseWithBody(
        statusCode: HttpStatusCode.OK,
        contentType: JsonContentType,
        bodyType: typeof(Product),
        Summary = "The requested product",
        Example = typeof(ProductExample))]
    [OpenApiResponseWithBody(
        statusCode: HttpStatusCode.NotFound,
        contentType: JsonContentType,
        bodyType: typeof(ErrorResponse),
        Summary = "Product not found")]
    [OpenApiResponseWithBody(
        statusCode: HttpStatusCode.InternalServerError,
        contentType: JsonContentType,
        bodyType: typeof(ErrorResponse),
        Summary = "Unexpected failure")]
    public async Task<HttpResponseData> GetProductById(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "products/{id:int}")] HttpRequestData request,
        int id,
        CancellationToken cancellationToken)
    {
        try
        {
            var product = await repository.GetByIdAsync(id, cancellationToken).ConfigureAwait(false);

            if (product is null)
            {
                return await NotFoundAsync(request, id).ConfigureAwait(false);
            }

            return await request.JsonAsync(HttpStatusCode.OK, product).ConfigureAwait(false);
        }
        catch (Exception exception) when (exception is not OperationCanceledException)
        {
            return await HandleUnexpectedAsync(request, exception, nameof(GetProductById)).ConfigureAwait(false);
        }
    }

    // ---------------------------------------------------------------------
    // POST /api/products
    // ---------------------------------------------------------------------

    [Function(nameof(CreateProduct))]
    [OpenApiOperation(
        operationId: "createProduct",
        tags: [Tag],
        Summary = "Create a product",
        Description = "Inserts a new row into the `products` table. The `id` is generated by the database.",
        Visibility = OpenApiVisibilityType.Important)]
    [OpenApiRequestBody(
        contentType: JsonContentType,
        bodyType: typeof(CreateProductRequest),
        Required = true,
        Description = "Name and price of the product to create.",
        Example = typeof(CreateProductRequestExample))]
    [OpenApiResponseWithBody(
        statusCode: HttpStatusCode.Created,
        contentType: JsonContentType,
        bodyType: typeof(Product),
        Summary = "Product created",
        Description = "The created product, including the generated `id`. The `Location` header points to the new resource.",
        Example = typeof(ProductExample))]
    [OpenApiResponseWithBody(
        statusCode: HttpStatusCode.BadRequest,
        contentType: JsonContentType,
        bodyType: typeof(ErrorResponse),
        Summary = "Invalid payload",
        Example = typeof(ErrorResponseExample))]
    [OpenApiResponseWithBody(
        statusCode: HttpStatusCode.InternalServerError,
        contentType: JsonContentType,
        bodyType: typeof(ErrorResponse),
        Summary = "Unexpected failure")]
    public async Task<HttpResponseData> CreateProduct(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "products")] HttpRequestData request,
        CancellationToken cancellationToken)
    {
        try
        {
            CreateProductRequest? payload;
            try
            {
                payload = await request.ReadFromJsonAsync<CreateProductRequest>(cancellationToken).ConfigureAwait(false);
            }
            catch (JsonException exception)
            {
                return await MalformedJsonAsync(request, exception).ConfigureAwait(false);
            }

            if (payload is null)
            {
                return await request.ErrorAsync(
                    HttpStatusCode.BadRequest, "empty_body", "A JSON body is required.", traceId: TraceId).ConfigureAwait(false);
            }

            var errors = ProductValidator.Validate(payload);
            if (errors.Count > 0)
            {
                return await ValidationFailedAsync(request, errors).ConfigureAwait(false);
            }

            var created = await repository
                .CreateAsync(payload.Name!.Trim(), payload.Price!.Value, cancellationToken)
                .ConfigureAwait(false);

            telemetryClient.TrackEvent("ProductCreated", new Dictionary<string, string> { ["productId"] = created.Id.ToString() });
            return await request.CreatedAsync(created).ConfigureAwait(false);
        }
        catch (Exception exception) when (exception is not OperationCanceledException)
        {
            return await HandleUnexpectedAsync(request, exception, nameof(CreateProduct)).ConfigureAwait(false);
        }
    }

    // ---------------------------------------------------------------------
    // PUT /api/products/{id}
    // ---------------------------------------------------------------------

    [Function(nameof(UpdateProduct))]
    [OpenApiOperation(
        operationId: "updateProduct",
        tags: [Tag],
        Summary = "Update a product",
        Description = "Updates an existing product. Only the fields present in the payload are changed.",
        Visibility = OpenApiVisibilityType.Important)]
    [OpenApiParameter(
        name: "id",
        In = ParameterLocation.Path,
        Required = true,
        Type = typeof(int),
        Summary = "Product id",
        Description = "Primary key of the product to update.",
        Example = typeof(ProductIdExample))]
    [OpenApiRequestBody(
        contentType: JsonContentType,
        bodyType: typeof(UpdateProductRequest),
        Required = true,
        Description = "Fields to change. Omitted fields keep their current value.",
        Example = typeof(UpdateProductRequestExample))]
    [OpenApiResponseWithBody(
        statusCode: HttpStatusCode.OK,
        contentType: JsonContentType,
        bodyType: typeof(Product),
        Summary = "Product updated",
        Example = typeof(ProductExample))]
    [OpenApiResponseWithBody(
        statusCode: HttpStatusCode.BadRequest,
        contentType: JsonContentType,
        bodyType: typeof(ErrorResponse),
        Summary = "Invalid payload",
        Example = typeof(ErrorResponseExample))]
    [OpenApiResponseWithBody(
        statusCode: HttpStatusCode.NotFound,
        contentType: JsonContentType,
        bodyType: typeof(ErrorResponse),
        Summary = "Product not found")]
    [OpenApiResponseWithBody(
        statusCode: HttpStatusCode.InternalServerError,
        contentType: JsonContentType,
        bodyType: typeof(ErrorResponse),
        Summary = "Unexpected failure")]
    public async Task<HttpResponseData> UpdateProduct(
        [HttpTrigger(AuthorizationLevel.Anonymous, "put", Route = "products/{id:int}")] HttpRequestData request,
        int id,
        CancellationToken cancellationToken)
    {
        try
        {
            UpdateProductRequest? payload;
            try
            {
                payload = await request.ReadFromJsonAsync<UpdateProductRequest>(cancellationToken).ConfigureAwait(false);
            }
            catch (JsonException exception)
            {
                return await MalformedJsonAsync(request, exception).ConfigureAwait(false);
            }

            if (payload is null)
            {
                return await request.ErrorAsync(
                    HttpStatusCode.BadRequest, "empty_body", "A JSON body is required.", traceId: TraceId).ConfigureAwait(false);
            }

            var errors = ProductValidator.Validate(payload);
            if (errors.Count > 0)
            {
                return await ValidationFailedAsync(request, errors).ConfigureAwait(false);
            }

            var updated = await repository
                .UpdateAsync(id, payload.Name?.Trim(), payload.Price, cancellationToken)
                .ConfigureAwait(false);

            if (updated is null)
            {
                return await NotFoundAsync(request, id).ConfigureAwait(false);
            }

            telemetryClient.TrackEvent("ProductUpdated", new Dictionary<string, string> { ["productId"] = id.ToString() });
            return await request.JsonAsync(HttpStatusCode.OK, updated).ConfigureAwait(false);
        }
        catch (Exception exception) when (exception is not OperationCanceledException)
        {
            return await HandleUnexpectedAsync(request, exception, nameof(UpdateProduct)).ConfigureAwait(false);
        }
    }

    // ---------------------------------------------------------------------
    // DELETE /api/products/{id}
    // ---------------------------------------------------------------------

    [Function(nameof(DeleteProduct))]
    [OpenApiOperation(
        operationId: "deleteProduct",
        tags: [Tag],
        Summary = "Delete a product",
        Description = "Removes a product from the `products` table.",
        Visibility = OpenApiVisibilityType.Important)]
    [OpenApiParameter(
        name: "id",
        In = ParameterLocation.Path,
        Required = true,
        Type = typeof(int),
        Summary = "Product id",
        Description = "Primary key of the product to delete.",
        Example = typeof(ProductIdExample))]
    [OpenApiResponseWithoutBody(
        statusCode: HttpStatusCode.NoContent,
        Summary = "Product deleted",
        Description = "The product was removed and no content is returned.")]
    [OpenApiResponseWithBody(
        statusCode: HttpStatusCode.NotFound,
        contentType: JsonContentType,
        bodyType: typeof(ErrorResponse),
        Summary = "Product not found")]
    [OpenApiResponseWithBody(
        statusCode: HttpStatusCode.InternalServerError,
        contentType: JsonContentType,
        bodyType: typeof(ErrorResponse),
        Summary = "Unexpected failure")]
    public async Task<HttpResponseData> DeleteProduct(
        [HttpTrigger(AuthorizationLevel.Anonymous, "delete", Route = "products/{id:int}")] HttpRequestData request,
        int id,
        CancellationToken cancellationToken)
    {
        try
        {
            var deleted = await repository.DeleteAsync(id, cancellationToken).ConfigureAwait(false);

            if (!deleted)
            {
                return await NotFoundAsync(request, id).ConfigureAwait(false);
            }

            telemetryClient.TrackEvent("ProductDeleted", new Dictionary<string, string> { ["productId"] = id.ToString() });
            return request.NoContent();
        }
        catch (Exception exception) when (exception is not OperationCanceledException)
        {
            return await HandleUnexpectedAsync(request, exception, nameof(DeleteProduct)).ConfigureAwait(false);
        }
    }

    // ---------------------------------------------------------------------
    // Shared responses
    // ---------------------------------------------------------------------

    private Task<HttpResponseData> NotFoundAsync(HttpRequestData request, int id)
    {
        logger.LogWarning("Product {ProductId} was not found.", id);
        return request.ErrorAsync(
            HttpStatusCode.NotFound, "product_not_found", $"Product with id {id} was not found.", traceId: TraceId);
    }

    private Task<HttpResponseData> ValidationFailedAsync(HttpRequestData request, IReadOnlyCollection<string> errors)
    {
        logger.LogWarning("Request rejected with {ErrorCount} validation error(s).", errors.Count);
        return request.ErrorAsync(
            HttpStatusCode.BadRequest, "validation_error", "The request payload is invalid.", errors, TraceId);
    }

    private Task<HttpResponseData> MalformedJsonAsync(HttpRequestData request, JsonException exception)
    {
        logger.LogWarning(exception, "Request body could not be parsed as JSON.");
        return request.ErrorAsync(
            HttpStatusCode.BadRequest, "malformed_json", "The request body is not valid JSON.", traceId: TraceId);
    }

    private async Task<HttpResponseData> HandleUnexpectedAsync(HttpRequestData request, Exception exception, string operation)
    {
        var isDatabaseFailure = exception is SqlException;

        logger.LogError(exception, "Operation {Operation} failed. Database failure: {IsDatabaseFailure}.", operation, isDatabaseFailure);
        telemetryClient.TrackException(exception, new Dictionary<string, string> { ["operation"] = operation });

        var (code, message) = isDatabaseFailure
            ? ("database_unavailable", "The product database could not be reached. Please try again later.")
            : ("internal_error", "An unexpected error occurred while processing the request.");

        return await request.ErrorAsync(HttpStatusCode.InternalServerError, code, message, traceId: TraceId).ConfigureAwait(false);
    }
}
