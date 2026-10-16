$resourceGroupName = "azure-for-devs"
$templateFilePath = "database.template.json"

# Define parameters
$serverName = "adatechsrv"
$adminUsername = "ada"
$adminPassword = "@datech123"
$databaseName = "AdaTechDb"
$firewallRuleName = "EvertonRules"
$startIpAddress = "0.0.0.0"
$endIpAddress = "255.255.255.255"

# az login --use-device-code
az deployment group create --resource-group $resourceGroupName `
    --template-file $templateFilePath `
    --parameters serverName=$serverName `
                 adminUsername=$adminUsername `
                 adminPassword=$adminPassword `
                 databaseName=$databaseName `
                 firewallRuleName=$firewallRuleName `
                 startIpAddress=$startIpAddress `
                 endIpAddress=$endIpAddress