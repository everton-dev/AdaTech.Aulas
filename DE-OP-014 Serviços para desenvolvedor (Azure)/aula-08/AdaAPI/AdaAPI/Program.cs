using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

var host = new HostBuilder()
    .ConfigureFunctionsWebApplication()
    .ConfigureServices((context, services) =>
    {
        var configuration = context.Configuration;
        services.AddApplicationInsightsTelemetryWorkerService(options =>
        {
            options.ApplicationVersion = "1.0.0";
            options.ConnectionString = configuration["APPINSIGHTS_INSTRUMENTATIONKEY"];
            options.DependencyCollectionOptions.EnableLegacyCorrelationHeadersInjection = true;
            options.EnableQuickPulseMetricStream = true;
            options.EnablePerformanceCounterCollectionModule = true;
            options.EnableQuickPulseMetricStream = true;
            options.EnableAdaptiveSampling = true;
            options.EnableDependencyTrackingTelemetryModule = true;
            options.EnableHeartbeat = true;
            options.EnableDebugLogger = true;
            options.EnableDiagnosticsTelemetryModule = true;
            options.EnableEventCounterCollectionModule = true;
            options.AddAutoCollectedMetricExtractor = true;
            options.DeveloperMode = true;
            options.EnableAdaptiveSampling = true;
            options.EnableAppServicesHeartbeatTelemetryModule = true;
            options.EnableAzureInstanceMetadataTelemetryModule = true;
            options.EnableDebugLogger = true;
            options.EnablePerformanceCounterCollectionModule = true;
            options.EnableQuickPulseMetricStream = true;
        });
        services.ConfigureFunctionsApplicationInsights();
    }).ConfigureLogging(logging =>
    {
        logging.AddApplicationInsights();
        logging.SetMinimumLevel(LogLevel.Information);
    })
    .Build();

host.Run();