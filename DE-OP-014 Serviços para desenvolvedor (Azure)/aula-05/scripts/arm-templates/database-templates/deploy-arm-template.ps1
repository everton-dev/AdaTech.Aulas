$resourceGroupName = "azure-for-devs"
$templateFilePath = "C:\UserData\z004stze\Documents\Private\mine\ada\.1351\aula-05\scripts\arm-templates\database-templates\database.template.json"
$parametersFilePath = "C:\UserData\z004stze\Documents\Private\mine\ada\.1351\aula-05\scripts\arm-templates\database-templates\database.parameters.json"

# az login --use-device-code
az deployment group create --resource-group $resourceGroupName `
    --template-file $templateFilePath `
    --parameters $parametersFilePath