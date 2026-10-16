$resourceGroupName = "azure-for-devs"
$templateFilePath = "functionapp.template.json"
$parametersFilePath = "functionapp.parameters.json"

# az login --use-device-code
# az deployment group create --resource-group $resourceGroupName --template-file $templateFilePath
az deployment group create --resource-group $resourceGroupName `
    --template-file $templateFilePath `
    --parameters $parametersFilePath