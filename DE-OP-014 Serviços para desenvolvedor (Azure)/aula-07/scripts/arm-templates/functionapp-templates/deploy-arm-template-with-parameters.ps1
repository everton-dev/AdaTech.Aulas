$resourceGroupName = "azure-for-devs"
$templateFilePath = "functionapp.template.json"

# Define parameters
$storageAccountName = "adatechstorage"
$functionAppName = "adatech-cars"
$functionsVersion = "4"
$location = "brazilsouth"
$skuStorage = "Standard_LRS"
$sqlServerName = "adatechsrv"
$sqlServerDatabaseName = "AdaTechDb"
$sqlServerDatabaseUser = "ada"
$sqlServerDatabasePassword = "@datech123"

# az login --use-device-code
az deployment group create --resource-group $resourceGroupName `
    --template-file $templateFilePath `
    --parameters storageAccountName=$storageAccountName `
                 functionAppName=$functionAppName `
                 functionsVersion=$functionsVersion `
                 location=$location `
                 skuStorage=$skuStorage `
                 sqlServerName=$sqlServerName `
                 sqlServerDatabaseName=$sqlServerDatabaseName `
                 sqlServerDatabaseUser=$sqlServerDatabaseUser `
                 sqlServerDatabasePassword=$sqlServerDatabasePassword