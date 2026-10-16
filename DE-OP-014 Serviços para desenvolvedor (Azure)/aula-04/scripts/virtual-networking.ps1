# login no Azure
az login --use-device-code

# Criar um grupo de recursos se não existir
az group create --name azure-for-devs --location BrazilSouth

# Criar uma rede virtual
az network vnet create --resource-group azure-for-devs --name AdaVNet --address-prefix 10.1.0.0/16 --subnet-name AdaSubRede1 --subnet-prefix 10.1.1.0/24

# Criar um grupos de segurança de rede (NSG)
az network nsg create --resource-group azure-for-devs --name AdaNSG

# Criar regras de segurança
az network nsg rule create --resource-group azure-for-devs --nsg-name AdaNSG --name PermitirSSH --protocol Tcp --direction Inbound --priority 1000 --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 22 --access Allow

# Associar o NSG a uma Sub-Rede
az network vnet subnet update --vnet-name AdaVNet --name AdaSubRede1 --resource-group azure-for-devs --network-security-group AdaNSG