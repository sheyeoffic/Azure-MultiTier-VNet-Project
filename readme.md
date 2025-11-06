Project 1: Deploy a VNet-Based Multi-Tier Architecture and Enforce Access Control
Group: 1
Student: Emmanuel Faniseyi
Platform: Microsoft Azure
Tools Used: Azure CLI, GitHub, Bash, Ubuntu 22.04
Objective

To design and deploy a secure multi-tier architecture on Microsoft Azure using Azure CLI and GitHub for version control.
The project aims to enforce access control and verify communication between the tiers using Network Security Groups (NSGs) and private IP addressing.

Architecture Overview

This project implements a three-tier VNet-based architecture consisting of:

Web Tier (Web-VM) – Publicly accessible VM to serve as the frontend.

App Tier (App-VM) – Internal VM accessible only from the Web tier.

DB Tier (DB-VM) – Private VM accessible only from the App tier.

Each tier is placed in its own subnet inside a single Virtual Network.
Access control is enforced using Network Security Groups (NSGs).

Project Architecture Diagram (optional if you have one)


Deployment Steps
1. Create Resource Group
az group create --name Capstone-Project-Group1 --location uksouth

2. Create Virtual Network and Subnets
az network vnet create \
  --resource-group Capstone-Project-Group1 \
  --name CapstoneProjectVNet \
  --address-prefix 10.0.0.0/16 \
  --subnet-name WebSubnet \
  --subnet-prefix 10.0.1.0/24

az network vnet subnet create \
  --resource-group Capstone-Project-Group1 \
  --vnet-name CapstoneProjectVNet \
  --name AppSubnet \
  --address-prefix 10.0.2.0/24

az network vnet subnet create \
  --resource-group Capstone-Project-Group1 \
  --vnet-name CapstoneProjectVNet \
  --name DBSubnet \
  --address-prefix 10.0.3.0/24

3. Create Network Security Groups (NSGs)
az network nsg create --resource-group Capstone-Project-Group1 --name WebNSG
az network nsg create --resource-group Capstone-Project-Group1 --name AppNSG
az network nsg create --resource-group Capstone-Project-Group1 --name DBNSG

Configure NSG Rules:

WebNSG: Allow SSH (22), HTTP (80)

AppNSG: Allow SSH (22) and traffic from WebSubnet

DBNSG: Allow SSH (22) and traffic from AppSubnet only

4. Generate SSH Key
ssh-keygen -t rsa -b 2048

5. Create Virtual Machines
az vm create \
  --resource-group Capstone-Project-Group1 \
  --name Web-VM \
  --image Ubuntu2204 \
  --vnet-name CapstoneProjectVNet \
  --subnet WebSubnet \
  --nsg WebNSG \
  --admin-username azureuser \
  --ssh-key-values ~/.ssh/id_rsa.pub

App-VM (Private Only)
az vm create \
  --resource-group Capstone-Project-Group1 \
  --name App-VM \
  --image Ubuntu2204 \
  --vnet-name CapstoneProjectVNet \
  --subnet AppSubnet \
  --nsg AppNSG \
  --public-ip-address "" \
  --admin-username azureuser \
  --ssh-key-values ~/.ssh/id_rsa.pub

DB-VM (Private Only)
az vm create \
  --resource-group Capstone-Project-Group1 \
  --name DB-VM \
  --image Ubuntu2204 \
  --vnet-name CapstoneProjectVNet \
  --subnet DBSubnet \
  --nsg DBNSG \
  --public-ip-address "" \
  --admin-username azureuser \
  --ssh-key-values ~/.ssh/id_rsa.pub

6. Verify Network Connectivity
SSH into Web-VM using its public IP:
ssh azureuser@<Web-VM-Public-IP>

From inside Web-VM, ping the other two VMs:
ping -c 4 <App-VM-Private-IP>
ping -c 4 <DB-VM-Private-IP>

Expected Result:
4 packets transmitted, 4 received, 0% packet loss

7. Access Control Verification
Only Web-VM can be accessed from the internet via SSH.
App-VM and DB-VM have no public IPs (internal only).
Web → App → DB traffic allowed internally.
Direct access from Web to DB or external sources to App/DB is blocked.


