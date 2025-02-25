#!/bin/bash

# Ensure gum is installed
if ! command -v gum &> /dev/null; then
    echo "gum could not be found, please install it first."
    exit 1
fi

# Ensure terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "terraform could not be found, please install it first."
    exit 1
fi

# Get the list of subdirectories inside 'terraform/'
if [ ! -d "environments" ]; then
    echo "No 'environments' directory found."
    exit 1
fi

OPTIONS=$(find environments -mindepth 1 -maxdepth 1 -type d -printf "%f\n")

# If there are no subdirectories, exit
if [ -z "$OPTIONS" ]; then
    echo "No subdirectories found in environments/."
    exit 1
fi

# Use gum to select a subfolder
ENVIRONMENT=$(echo "$OPTIONS" | gum choose)

# If no environment was selected, exit
if [ -z "$ENVIRONMENT" ]; then
    echo "No environment selected. Exiting."
    exit 1
fi

# Check if a command argument is provided
COMMAND=$1
if [[ "$COMMAND" != "apply" && "$COMMAND" != "destroy" && "$COMMAND" != "init" && "$COMMAND" != "plan" ]]; then
    echo "Invalid or missing command. Please provide one of: apply, destroy, init, plan"
    exit 1
fi

# Execute the terraform command inside the selected directory
echo "Running 'terraform $COMMAND' in environments/$ENVIRONMENT"
cd "environments/$ENVIRONMENT" || exit 1
terraform "$COMMAND"

echo "IP Address: "
awk -F'"' '/static_ip/ {print $2}' variables.tf | awk -F '/' '{print $1}' | xargs