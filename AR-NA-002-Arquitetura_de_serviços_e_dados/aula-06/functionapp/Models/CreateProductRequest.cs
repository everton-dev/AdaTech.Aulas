using System.Text.Json.Serialization;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Attributes;

namespace Ada.Aula06.ProductsApi.Models;

/// <summary>
/// Payload used to create a new product.
/// </summary>
[OpenApiExample(typeof(CreateProductRequestExample))]
public sealed class CreateProductRequest
{
    /// <summary>Display name of the product (required, max. 50 characters).</summary>
    [JsonPropertyName("name")]
    [OpenApiProperty(Description = "Display name of the product. Required, maximum of 50 characters.", Nullable = false)]
    public string? Name { get; set; }

    /// <summary>Unit price of the product (required, greater than or equal to zero).</summary>
    [JsonPropertyName("price")]
    [OpenApiProperty(Description = "Unit price of the product. Required, must be greater than or equal to zero.", Nullable = false)]
    public decimal? Price { get; set; }
}
