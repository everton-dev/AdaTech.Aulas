using System.ComponentModel.DataAnnotations;

namespace Ada.Aula06.ProductsApi.Data;

/// <summary>
/// Connectivity settings for the Azure SQL database.
/// </summary>
public sealed class SqlDatabaseOptions
{
    public const string SectionName = "SqlDatabase";

    /// <summary>
    /// ADO.NET connection string. Prefer <c>Authentication=Active Directory Default</c> with a managed
    /// identity so that no secret is stored in the application settings.
    /// </summary>
    [Required(AllowEmptyStrings = false, ErrorMessage = "A connection string for the products database must be configured.")]
    public string ConnectionString { get; set; } = string.Empty;

    /// <summary>Command timeout, in seconds, applied to every query.</summary>
    [Range(1, 300)]
    public int CommandTimeoutSeconds { get; set; } = 30;
}
