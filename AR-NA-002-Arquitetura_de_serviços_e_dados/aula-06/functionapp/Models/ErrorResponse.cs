using System.Text.Json.Serialization;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Attributes;

namespace Ada.Aula06.ProductsApi.Models;

/// <summary>
/// Standard error payload returned by the API.
/// </summary>
[OpenApiExample(typeof(ErrorResponseExample))]
public sealed class ErrorResponse
{
    /// <summary>Short, machine friendly error code.</summary>
    [JsonPropertyName("code")]
    [OpenApiProperty(Description = "Short, machine friendly error code.")]
    public string Code { get; set; } = string.Empty;

    /// <summary>Human readable description of the problem.</summary>
    [JsonPropertyName("message")]
    [OpenApiProperty(Description = "Human readable description of the problem.")]
    public string Message { get; set; } = string.Empty;

    /// <summary>Field level validation messages, when applicable.</summary>
    [JsonPropertyName("details")]
    [OpenApiProperty(Description = "Field level validation messages, when applicable.")]
    public IReadOnlyCollection<string> Details { get; set; } = [];

    /// <summary>Correlation identifier that can be used to find the request in Application Insights.</summary>
    [JsonPropertyName("traceId")]
    [OpenApiProperty(Description = "Correlation identifier that can be used to find the request in Application Insights.")]
    public string? TraceId { get; set; }

    public static ErrorResponse Create(string code, string message, IReadOnlyCollection<string>? details = null, string? traceId = null) => new()
    {
        Code = code,
        Message = message,
        Details = details ?? [],
        TraceId = traceId
    };
}
