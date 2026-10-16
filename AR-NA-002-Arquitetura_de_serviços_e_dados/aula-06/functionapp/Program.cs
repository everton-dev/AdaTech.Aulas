using System.Text.Json;
using System.Text.Json.Serialization;
using Ada.Aula06.ProductsApi.Configuration;
using Ada.Aula06.ProductsApi.Data;
using Azure.Core.Serialization;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Abstractions;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Logging.ApplicationInsights;

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults(workerOptions =>
    {
        workerOptions.Serializer = new JsonObjectSerializer(new JsonSerializerOptions(JsonSerializerDefaults.Web)
        {
            DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
            PropertyNameCaseInsensitive = true
        });
    })
    .ConfigureServices((context, services) =>
    {
        // Telemetry: traces, requests, dependencies and custom metrics flow to Application Insights,
        // which stores everything in the linked Log Analytics workspace.
        services.AddApplicationInsightsTelemetryWorkerService();
        services.ConfigureFunctionsApplicationInsights();

        services
            .AddOptions<SqlDatabaseOptions>()
            .Configure(options =>
            {
                options.ConnectionString =
                    context.Configuration.GetConnectionString("ProductsDatabase")
                    ?? context.Configuration["SqlDatabase:ConnectionString"]
                    ?? string.Empty;

                if (int.TryParse(context.Configuration["SqlDatabase:CommandTimeoutSeconds"], out var timeout))
                {
                    options.CommandTimeoutSeconds = timeout;
                }
            })
            .ValidateDataAnnotations()
            .ValidateOnStart();

        services.AddSingleton<ISqlConnectionFactory, SqlConnectionFactory>();
        services.AddScoped<IProductRepository, ProductRepository>();

        services.AddSingleton<IOpenApiConfigurationOptions>(provider =>
            new ProductsOpenApiConfiguration(provider.GetRequiredService<IConfiguration>()));
    })
    .ConfigureLogging(logging =>
    {
        // The Application Insights provider defaults to Warning; remove the rule so Information logs are exported.
        logging.Services.Configure<LoggerFilterOptions>(options =>
        {
            var defaultRule = options.Rules.FirstOrDefault(
                rule => rule.ProviderName == typeof(ApplicationInsightsLoggerProvider).FullName);

            if (defaultRule is not null)
            {
                options.Rules.Remove(defaultRule);
            }
        });
    })
    .Build();

await host.RunAsync();
