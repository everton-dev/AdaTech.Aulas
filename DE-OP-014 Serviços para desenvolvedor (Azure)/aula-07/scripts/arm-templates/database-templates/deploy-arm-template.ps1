$resourceGroupName = "azure-for-devs"
$templateFilePath = "database.template.json"
$parametersFilePath = "database.parameters.json"

# az login --use-device-code
az deployment group create --resource-group $resourceGroupName `
    --template-file $templateFilePath `
    --parameters $parametersFilePath