# IaC deployment

The deployment process has several stages:
- Prerequisites: manual set up a storage account for maintaining the Terraform status files.
- First stage: create a resource group and services, where data for the second deployment stage should be stored.
- Data upload: ETL license, TLS certificates etc. The remaining resources depend on this information.
- Second stage: create remaining resouces

## Prerequisites

- Create a storage account and a container `tfstate` in an Azure resource group, which will contain Terraform status files
- Login to Azure using your account, set and verify the default subscription, e.g.:
```
az login --use-device-code
az account set --subscription CLN-EMEA-App-Market-NonProd
az account list -o table
```
- Download terraform binaries, if not yet installed, from https://www.terraform.io/downloads
- Prepare a backend configuration file with the Azure storage account details, where Terraform will store its state, e.g. `backend-cln-dev.conf`
```
resource_group_name  = "RG-CLN-EMEA-App-Market-IaC"
storage_account_name = "clna2mktdev100"
```
**NOTE**: `backend-*.conf` files should be ignored by Git.

## Manual deployment
This section describes how to create resources and deploy the Market application using command line tools.

Environemnt specific values have to be defined in a values file, e.g. `values-cln-dev.tfvars`:
```
aad_group_admins     = "AAD-PRJ-Market-EMEA-AppOwner-NonProd"
aad_group_developers = "AAD-PRJ-Market-EMEA-AppOwner-NonProd"
global_index         = "101"
resource_group_name  = "RG-CLN-EMEA-App-Market-Dev"
```


### Initialize and first stage deployment 
Make sure the proper values are set in the backend config file and run:
```
terraform init  --backend-config=backend-cln-dev.conf [--reconfigure]
terraform plan  --var-file=values-cln-dev.tfvars
terraform apply --var-file=values-cln-dev.tfvars --auto-approve
```
Note: optional parameter `--reconfigure` should be used when switching to another environment.

Note: if the resource group already exist, it needs to be imported into Terraform state, e.g.:
```bash
terraform import --var-file=values-cln-dev.tfvars azurerm_resource_group.rg "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/RG-CLN-EMEA-App-Market-Dev" 
```

The first stage should create some resources and exit with the following errors:
- Missing ETL license:
```
Error: KeyVault Secret "ETLLicense" (KeyVault URI "https://KEY-VAULT-NAME.vault.azure.net/") does not exist
```
- Missing TLS frontend certificate:
```
Error: Resource postcondition failed
PEM frontend certificate must be uploaded to key vault 'KEY-VAULT-NAME' as 'market'
```

### Data upload

A customer's ETL license and a TLS certificate should be uploaded into the key vault created in the previous step.
Make sure, the correct name of the key vault is used:

```bash
terraform state show azurerm_key_vault.kv
```

- ETL license

Upload the file with Azure Cli tool, as Azure portal removes new line breaks when copy-pasting, e.g.:

```bash
az keyvault secret set --vault-name KEY-VAULT-NAME --name ETLLicense -f "/path/to/ETLLicense.lic" -o none
```

- TLS certificate

Upload into the same key vault the corresponding TLS PKCS12 (PFX) certificate as `market` (file: `iac-key-vault.tf`, local variable: `kv_cert_name_frontend`) for the frontend application.
```bash
az keyvault certificate import --vault-name KEY-VAULT-NAME -n market -f "/PATH/TO/PKCS12_cert_and_priv_key.pfx" [--password CERT_PASSWORD] -o none
```

## Second stage deployment

Run Terraform apply again:
```bash
terraform apply --var-file=values-cln-dev.tfvars --auto-approve
```

## AKS management

### Browser

### AZ tunnel

### AZ & Kubectl setup

```bash
az login --use-device-code # Use browser to authenticate
az account set --subscription CLN-EMEA-App-Market-NonProd
az configure -d group=RG-CLN-EMEA-App-Market-Dev
az aks get-credentials --name aks-mkt-dev-westeurope101 

kubectl get nodes -A # Use browser to authenticate
```