#!/bin/bash

# Exit immediately if a command fails
set -e

echo "=================================================="
echo "      Azure Resource Group Deletion Script        "
echo "=================================================="
echo ""

# 1. Automatic Azure Login Check
echo "🔐 Checking Azure authentication status..."
if ! az account show &> /dev/null; then
    echo "⚠️  Not logged into Azure. Initiating login process..."
    az login --output table
else
    echo "✅ Already authenticated with Azure."
fi

# 2. Fetch and List Active Resource Groups with Locations
echo ""
echo "📊 Fetching your active Resource Groups..."
echo "------------------------------------------------------------"
printf "  %-35s %-15s\n" "RESOURCE GROUP NAME" "REGION/LOCATION"
echo "------------------------------------------------------------"

# Fetch name and location separated by a tab character
RG_DATA=$(az group list --query "[].{name:name, location:location}" --output tsv)

if [ -z "$RG_DATA" ]; then
    echo "❌ No Resource Groups found in this subscription."
    exit 0
fi

# Print the list cleanly aligned into columns
echo "$RG_DATA" | while IFS=$'\t' read -r name location; do
    printf "  🔹 %-32s [%s]\n" "$name" "$location"
done
echo "------------------------------------------------------------"

# 3. Ask the user for the Resource Group name
echo ""
read -p "Enter the name of the Resource Group you want to DELETE: " RG_NAME

# Trim any accidental leading/trailing spaces from user input
RG_NAME=$(echo "$RG_NAME" | xargs)

# 4. Validation check: Ensure the entered group actually exists in the fetched list
if [ -z "$RG_NAME" ]; then
    echo "❌ Error: Resource Group name cannot be blank."
    echo "Deletion aborted."
    exit 1
fi

# Extract just the names into a standalone list for easy validation checking
RG_LIST=$(echo "$RG_DATA" | cut -f1)

if ! echo "$RG_LIST" | grep -qxF "$RG_NAME"; then
    echo "❌ Error: '$RG_NAME' is not a valid Resource Group in this subscription."
    echo "Deletion aborted."
    exit 1
fi

# 5. Critical Confirmation Step
echo ""
echo "⚠️  WARNING: You are about to permanently DELETE the Resource Group: '$RG_NAME'"
read -p "Are you absolutely sure? Type 'yes' to confirm: " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "🛑 Deletion cancelled by user."
    exit 0
fi

# 6. Execute the Deletion
echo ""
echo "🔥 Initiating deletion for Resource Group '$RG_NAME'..."
echo "ℹ️  Using '--no-wait'. The deletion will run in the background on Azure."

az group delete --name "$RG_NAME" --yes --no-wait

echo ""
echo "✅ Deletion command successfully sent to Azure for '$RG_NAME'."
echo "   It may take a few minutes for the resources to fully disappear from your portal."

