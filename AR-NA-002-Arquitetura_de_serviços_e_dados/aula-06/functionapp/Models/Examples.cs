using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Abstractions;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Resolvers;
using Newtonsoft.Json.Serialization;

namespace Ada.Aula06.ProductsApi.Models;

/// <summary>Sample value rendered by Swagger UI for the <c>id</c> route parameter.</summary>
public sealed class ProductIdExample : OpenApiExample<int>
{
    public override IOpenApiExample<int> Build(NamingStrategy? namingStrategy = null)
    {
        Examples.Add(OpenApiExampleResolver.Resolve("id", 1, namingStrategy));
        return this;
    }
}

/// <summary>Sample payload rendered by Swagger UI for <see cref="Product"/>.</summary>
public sealed class ProductExample : OpenApiExample<Product>
{
    public override IOpenApiExample<Product> Build(NamingStrategy? namingStrategy = null)
    {
        Examples.Add(OpenApiExampleResolver.Resolve(
            "keyboard",
            "Mechanical keyboard",
            new Product { Id = 1, Name = "Mechanical Keyboard", Price = 349.90m },
            namingStrategy));

        return this;
    }
}

/// <summary>Sample payload rendered by Swagger UI for a collection of products.</summary>
public sealed class ProductListExample : OpenApiExample<List<Product>>
{
    public override IOpenApiExample<List<Product>> Build(NamingStrategy? namingStrategy = null)
    {
        Examples.Add(OpenApiExampleResolver.Resolve(
            "catalog",
            "Two products from the catalog",
            new List<Product>
            {
                new() { Id = 1, Name = "Mechanical Keyboard", Price = 349.90m },
                new() { Id = 2, Name = "Wireless Mouse", Price = 129.50m }
            },
            namingStrategy));

        return this;
    }
}

/// <summary>Sample payload rendered by Swagger UI for <see cref="CreateProductRequest"/>.</summary>
public sealed class CreateProductRequestExample : OpenApiExample<CreateProductRequest>
{
    public override IOpenApiExample<CreateProductRequest> Build(NamingStrategy? namingStrategy = null)
    {
        Examples.Add(OpenApiExampleResolver.Resolve(
            "newProduct",
            "New product to be created",
            new CreateProductRequest { Name = "Noise Cancelling Headphones", Price = 899.00m },
            namingStrategy));

        return this;
    }
}

/// <summary>Sample payload rendered by Swagger UI for <see cref="UpdateProductRequest"/>.</summary>
public sealed class UpdateProductRequestExample : OpenApiExample<UpdateProductRequest>
{
    public override IOpenApiExample<UpdateProductRequest> Build(NamingStrategy? namingStrategy = null)
    {
        Examples.Add(OpenApiExampleResolver.Resolve(
            "priceOnly",
            "Change only the price",
            new UpdateProductRequest { Price = 799.00m },
            namingStrategy));

        Examples.Add(OpenApiExampleResolver.Resolve(
            "nameAndPrice",
            "Change name and price",
            new UpdateProductRequest { Name = "Noise Cancelling Headphones Pro", Price = 1099.00m },
            namingStrategy));

        return this;
    }
}

/// <summary>Sample payload rendered by Swagger UI for <see cref="ErrorResponse"/>.</summary>
public sealed class ErrorResponseExample : OpenApiExample<ErrorResponse>
{
    public override IOpenApiExample<ErrorResponse> Build(NamingStrategy? namingStrategy = null)
    {
        Examples.Add(OpenApiExampleResolver.Resolve(
            "validationFailed",
            "Validation failed",
            ErrorResponse.Create(
                "validation_error",
                "The request payload is invalid.",
                ["'name' is required and must not exceed 50 characters.", "'price' must be greater than or equal to zero."],
                "7f9c1d2e4b6a4f0f9a1c2d3e4f5a6b7c"),
            namingStrategy));

        Examples.Add(OpenApiExampleResolver.Resolve(
            "notFound",
            "Product not found",
            ErrorResponse.Create("product_not_found", "Product with id 42 was not found.", traceId: "7f9c1d2e4b6a4f0f9a1c2d3e4f5a6b7c"),
            namingStrategy));

        return this;
    }
}
