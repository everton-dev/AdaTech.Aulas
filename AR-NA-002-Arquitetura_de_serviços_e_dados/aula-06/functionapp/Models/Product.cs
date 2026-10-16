using System.Text.Json.Serialization;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Attributes;

namespace Ada.Aula06.ProductsApi.Models;

/// <summary>
/// A product stored in the <c>products</c> table.
/// </summary>
[OpenApiExample(typeof(ProductExample))]
public sealed class Product
{
    /// <summary>Unique identifier of the product.</summary>
    [JsonPropertyName("id")]
    [OpenApiProperty(Description = "Unique identifier of the product.")]
    public int Id { get; set; }

    /// <summary>Display name of the product (max. 50 characters).</summary>
    [JsonPropertyName("name")]
    [OpenApiProperty(Description = "Display name of the product. Maximum of 50 characters.")]
    public string Name { get; set; } = string.Empty;

    /// <summary>Unit price of the product.</summary>
    [JsonPropertyName("price")]
    [OpenApiProperty(Description = "Unit price of the product with two decimal places.")]
    public decimal Price { get; set; }
}
