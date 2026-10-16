# login no Azure
az login --use-device-code

# Criar um Grupo de Recursos se não existir
az group create --name azure-for-devs --location brazilsouth

# Criar servidor de banco de dados
az sql server create --name adatechsrv --resource-group azure-for-devs --location brazilsouth --admin-user ada --admin-password "@datech123"

# Criar database
az sql db create --resource-group azure-for-devs --server adatechsrv --name AdaTechDb --service-objective S0 --backup-storage-redundancy Local

# Add firewall rules
az sql server firewall-rule create --name EvertonRules --resource-group azure-for-devs --server adatechsrv --end-ip-address "255.255.255.255" --start-ip-address "0.0.0.0"