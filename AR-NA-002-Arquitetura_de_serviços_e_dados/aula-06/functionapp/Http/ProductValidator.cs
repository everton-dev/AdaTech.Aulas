using Ada.Aula06.ProductsApi.Models;

namespace Ada.Aula06.ProductsApi.Http;

/// <summary>
/// Input validation rules derived from the <c>products</c> table schema.
/// </summary>
internal static class ProductValidator
{
    private const int MaxNameLength = 50;
    private const decimal MaxPrice = 99_999_999.99m;

    public static IReadOnlyCollection<string> Validate(CreateProductRequest request)
    {
        var errors = new List<string>();

        ValidateName(request.Name, required: true, errors);
        ValidatePrice(request.Price, required: true, errors);

        return errors;
    }

    public static IReadOnlyCollection<string> Validate(UpdateProductRequest request)
    {
        var errors = new List<string>();

        if (!request.HasChanges)
        {
            errors.Add("At least one of 'name' or 'price' must be supplied.");
            return errors;
        }

        ValidateName(request.Name, required: false, errors);
        ValidatePrice(request.Price, required: false, errors);

        return errors;
    }

    private static void ValidateName(string? name, bool required, List<string> errors)
    {
        if (name is null)
        {
            if (required)
            {
                errors.Add("'name' is required.");
            }

            return;
        }

        if (string.IsNullOrWhiteSpace(name))
        {
            errors.Add("'name' must not be empty or whitespace.");
        }
        else if (name.Length > MaxNameLength)
        {
            errors.Add($"'name' must not exceed {MaxNameLength} characters.");
        }
    }

    private static void ValidatePrice(decimal? price, bool required, List<string> errors)
    {
        if (price is null)
        {
            if (required)
            {
                errors.Add("'price' is required.");
            }

            return;
        }

        if (price < 0m)
        {
            errors.Add("'price' must be greater than or equal to zero.");
        }
        else if (price > MaxPrice)
        {
            errors.Add($"'price' must not exceed {MaxPrice}.");
        }
        else if (decimal.Round(price.Value, 2) != price.Value)
        {
            errors.Add("'price' must not have more than two decimal places.");
        }
    }
}
