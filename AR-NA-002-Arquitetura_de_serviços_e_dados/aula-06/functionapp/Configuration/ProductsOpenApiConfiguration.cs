using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Configurations;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Enums;
using Microsoft.Extensions.Configuration;
using Microsoft.OpenApi.Models;

namespace Ada.Aula06.ProductsApi.Configuration;

/// <summary>
/// Describes the generated OpenAPI document exposed at <c>/api/swagger.json</c> and <c>/api/swagger/ui</c>.
/// </summary>
public sealed class ProductsOpenApiConfiguration : DefaultOpenApiConfigurationOptions
{
    public ProductsOpenApiConfiguration(IConfiguration configuration)
    {
        var isDevelopment = string.Equals(
            configuration["AZURE_FUNCTIONS_ENVIRONMENT"], "Development", StringComparison.OrdinalIgnoreCase);

        IncludeRequestingHostName = true;
        ForceHttps = !isDevelopment;
        ForceHttp = false;
    }

    public override OpenApiInfo Info { get; set; } = new()
    {
        Version = "1.0.0",
        Title = "Products API",
        Description =
            "Azure Functions (.NET 10, isolated worker) REST API that manages the product catalog stored in Azure SQL Database.\n\n"
            + "**Capabilities**\n"
            + "- List, read, create, update and delete products\n"
            + "- Structured logging and custom metrics shipped to Application Insights / Log Analytics\n"
            + "- Fully parameterized SQL statements\n\n"
            + "**Data model** — table `dbo.products` with columns `id INT`, `name VARCHAR(50)` and `price DECIMAL(10,2)`.",
        Contact = new OpenApiContact
        {
            Name = "Ada - Arquitetura de Servicos e Dados",
            Email = "arquitetura@ada.tech"
        },
        License = new OpenApiLicense
        {
            Name = "MIT",
            Url = new Uri("https://opensource.org/licenses/MIT")
        }
    };

    public override OpenApiVersionType OpenApiVersion { get; set; } = OpenApiVersionType.V3;
}
