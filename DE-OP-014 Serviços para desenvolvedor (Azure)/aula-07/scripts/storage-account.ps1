# login no Azure
az login --use-device-code

# create storage account
az storage account create --name adatechstorage --resource-group ada-tech-rg --location brazilsouth --sku Standard_LRS

# create storage container
az storage container create --name ada-files --account-name adatechstorage