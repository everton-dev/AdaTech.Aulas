using System.Net;
using Ada.Aula06.ProductsApi.Models;
using Microsoft.Azure.Functions.Worker.Http;

namespace Ada.Aula06.ProductsApi.Http;

/// <summary>
/// Small helpers that keep the function bodies focused on business rules.
/// </summary>
internal static class HttpResponseExtensions
{
    public static async Task<HttpResponseData> JsonAsync<T>(this HttpRequestData request, HttpStatusCode statusCode, T payload)
    {
        var response = request.CreateResponse();
        await response.WriteAsJsonAsync(payload).ConfigureAwait(false);
        response.StatusCode = statusCode;
        return response;
    }

    public static async Task<HttpResponseData> CreatedAsync(this HttpRequestData request, Product product)
    {
        var response = request.CreateResponse();
        response.Headers.Add("Location", $"{request.Url.GetLeftPart(UriPartial.Path).TrimEnd('/')}/{product.Id}");
        await response.WriteAsJsonAsync(product).ConfigureAwait(false);
        response.StatusCode = HttpStatusCode.Created;
        return response;
    }

    public static HttpResponseData NoContent(this HttpRequestData request) =>
        request.CreateResponse(HttpStatusCode.NoContent);

    public static Task<HttpResponseData> ErrorAsync(
        this HttpRequestData request,
        HttpStatusCode statusCode,
        string code,
        string message,
        IReadOnlyCollection<string>? details = null,
        string? traceId = null) =>
        request.JsonAsync(statusCode, ErrorResponse.Create(code, message, details, traceId));
}
