$resourceGroupName = "azure-for-devs"
$templateFilePath = "functionapp.template.json"

# Define parameters
$functionsVersion = "4"
$location = "brazilsouth"
$skuStorage = "Standard_LRS"
$sqlServerName = "adatechsrv"
$sqlServerDatabaseName = "AdaTechDb"
$sqlServerDatabaseUser = "ada"
$sqlServerDatabasePassword = "@datech123"
$qtyFunctions = 4

# az login --use-device-code
for ($i = 1; $i -le $qtyFunctions; $i++) {
    if ($i -eq 1) {
        $location = "brazilsouth"
    }
    elseif ($i -eq 2) {
        $location = "eastus"
    }
    elseif ($i -eq 3) {
        $location = "westus"
    }
    elseif ($i -eq 4) {
        $location = "westeurope"
    }
    else {
        $location = "brazilsouth"
    }

    $functionAppName = $("adatech-cars-ejb-" + $i.ToString())
    $storageAccountName = $("adatechstorageejb" + $i.ToString())

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
}