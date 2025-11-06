#!/bin/bash
# Capstone Project 1 — Multi-Tier Architecture Deployment
# Author: Sheye Emmanuel

RESOURCE_GROUP="Capstone-Project-Group1"
LOCATION="uksouth"
VNET_NAME="CapstoneProjectVNet"
ADDRESS_PREFIX="10.0.0.0/16"

# Subnets
WEB_SUBNET="WebSubnet"
APP_SUBNET="AppSubnet"
DB_SUBNET="DBSubnet"
WEB_PREFIX="10.0.1.0/24"
APP_PREFIX="10.0.2.0/24"
DB_PREFIX="10.0.3.0/24"

# VM names
WEB_VM="Web-VM"
APP_VM="App-VM"
DB_VM="DB-VM"
USERNAME="azureuser"
IMAGE="Canonical:0001-com-ubuntu-server-jammy:22_04-lts:latest"

# 🔹 Create Resource Group
echo "Creating resource group..."
az group create --name $RESOURCE_GROUP --location $LOCATION

# 🔹 Create Virtual Network and Subnets
echo "Creating VNet and subnets..."
az network vnet create \
  --resource-group $RESOURCE_GROUP \
  --name $VNET_NAME \
  --address-prefix $ADDRESS_PREFIX \
  --subnet-name $WEB_SUBNET \
  --subnet-prefix $WEB_PREFIX

az network vnet subnet create \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name $APP_SUBNET \
  --address-prefix $APP_PREFIX

az network vnet subnet create \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name $DB_SUBNET \
  --address-prefix $DB_PREFIX

# 🔹 Create NSGs and rules
echo "Creating NSGs..."
az network nsg create --resource-group $RESOURCE_GROUP --name WebNSG
az network nsg create --resource-group $RESOURCE_GROUP --name AppNSG
az network nsg create --resource-group $RESOURCE_GROUP --name DBNSG

# Web → allow HTTP + SSH
az network nsg rule create \
  --resource-group $RESOURCE_GROUP --nsg-name WebNSG \
  --name Allow-HTTP --protocol Tcp --priority 1001 --destination-port-range 80 --access Allow

az network nsg rule create \
  --resource-group $RESOURCE_GROUP --nsg-name WebNSG \
  --name Allow-SSH --protocol Tcp --priority 1002 --destination-port-range 22 --access Allow

# App → allow only from Web subnet
az network nsg rule create \
  --resource-group $RESOURCE_GROUP --nsg-name AppNSG \
  --name Allow-Web-to-App --protocol Tcp --priority 1001 \
  --source-address-prefixes $WEB_PREFIX --destination-port-range 22 --access Allow

# DB → allow only from App subnet
az network nsg rule create \
  --resource-group $RESOURCE_GROUP --nsg-name DBNSG \
  --name Allow-App-to-DB --protocol Tcp --priority 1001 \
  --source-address-prefixes $APP_PREFIX --destination-port-range 3306 --access Allow

  # ===== SSH Key Setup =====
SSH_KEY_PATH="$HOME/.ssh/id_rsa"

# Check if SSH key exists
if [ ! -f "$SSH_KEY_PATH" ]; then
  echo "SSH key not found at $SSH_KEY_PATH — generating a new one..."
  ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH" -N ""
else
  echo "Existing SSH key found at $SSH_KEY_PATH"
fi

# Define the public key path (used later in VM creation)
PUBKEY_PATH="${SSH_KEY_PATH}.pub"

# Optional: Display it for verification
echo "Using SSH public key:"
cat "$PUBKEY_PATH"
echo ""


# 🔹 Create VMs
echo "Creating Web VM..."
az vm create \
  --resource-group Capstone-Project-Group1 \
  --name Web-VM \
  --image $IMAGE \
  --vnet-name CapstoneProjectVNet \
  --subnet WebSubnet \
  --nsg WebNSG \
  --size Standard_B1s \
  --admin-username azureuser \
  --ssh-key-values ~/.ssh/id_rsa.pub

echo "Creating App VM..."
az vm create \                                                                                                                                                                       --resource-group Capstone-Project-Group1 \
  --name App-VM \
  --image $IMAGE \
  --vnet-name CapstoneProjectVNet \
  --subnet AppSubnet \
  --nsg AppNSG \
  --size Standard_B1s \
  --public-ip-address "" \
  --admin-username azureuser \
  --ssh-key-values ~/.ssh/id_rsa.pub

echo "Creating DB VM..."
az vm create \                                                                                                                                                                       --resource-group Capstone-Project-Group1 \
  --name DB-VM \
  --image $IMAGE \
  --vnet-name CapstoneProjectVNet \
  --subnet DBSubnet \
  --nsg DBNSG \
  --size Standard_B1s \
  --public-ip-address "" \
  --admin-username azureuser \
  --ssh-key-values ~/.ssh/id_rsa.pub

echo "✅ Deployment complete!"
