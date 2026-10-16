using System.Text.Json.Serialization;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Attributes;

namespace Ada.Aula06.ProductsApi.Models;

/// <summary>
/// Payload used to update an existing product. Only the supplied fields are changed.
/// </summary>
[OpenApiExample(typeof(UpdateProductRequestExample))]
public sealed class UpdateProductRequest
{
    /// <summary>New display name. Omit or send <c>null</c> to keep the current value.</summary>
    [JsonPropertyName("name")]
    [OpenApiProperty(Description = "New display name. Omit the field to keep the current value. Maximum of 50 characters.")]
    public string? Name { get; set; }

    /// <summary>New unit price. Omit or send <c>null</c> to keep the current value.</summary>
    [JsonPropertyName("price")]
    [OpenApiProperty(Description = "New unit price. Omit the field to keep the current value. Must be greater than or equal to zero.")]
    public decimal? Price { get; set; }

    /// <summary>Indicates whether at least one field was supplied.</summary>
    [JsonIgnore]
    public bool HasChanges => Name is not null || Price is not null;
}
