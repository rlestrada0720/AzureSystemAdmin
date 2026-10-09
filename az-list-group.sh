#!/bin/bash

# Check if user is logged into Azure
if ! az account show &> /dev/null; then
    echo "You are not logged in. Running 'az login'..."
    az login
fi

echo "----------------------------------------"
echo "Fetching Resource Groups and Regions..."
echo "----------------------------------------"

# List resource groups in a clean, readable table format
az group list --query "[].{Name:name, Location:location}" --output table

