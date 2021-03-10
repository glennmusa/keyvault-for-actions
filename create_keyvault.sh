#!/bin/bash
#
# Creates a Key Vault and Service Principal that has Contributor scope only for that Key Vault
# Returns a JSON object to store in a GitHub secret for logging in with

function error_log () {
  echo "Error: ${1}" >&2
}

# Check for Azure CLI
if ! command -v az &> /dev/null; then
    error_log "az could not be found. This script requires the Azure CLI."
    echo "see https://docs.microsoft.com/en-us/cli/azure/install-azure-cli for installation instructions."
    exit 1
fi

# Check for Azure CLI account
if ! az account show &> /dev/null; then
    error_log "Please login to Azure CLI before running this script."
    echo "To set the cloud: az cloud set --name <cloud name>"
    echo "To login interactively: az login"
    exit 1
fi

default_sub_id=$(az account show --query id --output tsv)
default_location="eastus"

sub_id=${1:-$default_sub_id}
location=${2:-$default_location}

timestamp=$(date +%s)
prefix="ghactions"
rg_name="${prefix}rg${timestamp}"
kv_name="${prefix}kv${timestamp}"
sp_name="http://${kv_name}-reader-service-principal"

echo
echo "RUNNING..."

az group create \
  --subscription "${sub_id}" \
  --location "${location}" \
  --name "${rg_name}" \
  --only-show-errors \
  --output none

kv_resource_id=$(az keyvault create \
  --subscription "${sub_id}" \
  --location "${location}" \
  --resource-group "${rg_name}" \
  --name "${kv_name}" \
  --only-show-errors \
  --query id \
  --output tsv)

azure_credentials=$(az ad sp create-for-rbac \
  --name "${sp_name}" \
  --role reader \
  --scopes "${kv_resource_id}" \
  --only-show-errors \
  --sdk-auth)

sp_id=$(az ad sp show \
  --id "${sp_name}" \
  --query objectId \
  --only-show-errors \
  --output tsv)

az keyvault set-policy \
  --name "${kv_name}" \
  --secret-permissions get list \
  --object-id "${sp_id}" \
  --only-show-errors \
  --output none

echo
echo "FINISHED!"
echo
echo "**********"
echo "WARNING: The JSON output includes credentials that you must protect."
echo "Be sure that you do not include these credentials in your code or check the credentials into your source control."
echo "For more information, see https://aka.ms/azadsp-cli"
echo "**********"
echo
echo "Here's the Key Vault name. Paste the entire JSON output below into a GitHub secret value named KEY_VAULT_NAME."
echo "KEY VAULT NAME:"
echo "${kv_name}"
echo
echo "Here's the AZURE CREDENTIALS. Paste the entire JSON output below into a GitHub secret value named AZURE_CREDENTIALS."
echo "AZURE_CREDENTIALS:"
echo
echo "${azure_credentials}"
echo
