
RG=rg-agent-rag
LOCATION=eastus2
STO_NAME="agentsto${RANDOM}"

az group create -n $RG --location $LOCATION

SEARCH_SVC_NAME="searchsvc${RANDOM}"

echo "Creating search service $SEARCH_SVC_NAME in $RG"
az search service create -n $SEARCH_SVC_NAME -g $RG --sku "basic" --location $LOCATION

echo "enable managed identity for search service"
az search service update -n $SEARCH_SVC_NAME -g $RG --set identity.type=SystemAssigned
az search service show -n $SEARCH_SVC_NAME -g $RG --query identity.principalId -o tsv > principal_id.txt
PRINCIPAL_ID=$(cat principal_id.txt)


echo "Creating storage account $STO_NAME in $RG"
az storage account create -n $STO_NAME -g $RG --location $LOCATION --sku Standard_LRS

echo "Creating blob container in $STO_NAME"
az storage container create -n "doc" --account-name $STO_NAME

echo "uploading files in doc to blob container"
az storage blob upload-batch -d "doc" -s "doc" --account-name $STO_NAME

echo "listing blobs in doc container"
az storage blob list -c "doc" --account-name $STO_NAME --query "[].{name:name}" -o table


# echo "storage account connection string"
# az storage account show-connection-string -n $STO_NAME -g $RG --query connectionString -o tsv > connection_string.txt


echo "assigning search service identity to storage account"
az role assignment create --role "Storage Blob Data Contributor" --assignee $PRINCIPAL_ID --scope /subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RG/providers/Microsoft.Storage/storageAccounts/$STO_NAME

