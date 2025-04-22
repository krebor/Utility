#!/bin/bash

# --- Configuration ---
# !!! SET THIS VARIABLE BEFORE RUNNING !!!
# The name of the text file containing the FULL RESOURCE IDs of the resources (alerts) to delete, one per line.
FILENAME="alert_ids.txt"

# --- Script Logic ---
echo "Starting resource deletion process using 'az resource delete'..."
echo "Reading Resource IDs from: $FILENAME"
# Using the current time provided by the system context
CURRENT_DATE=$(date '+%Y-%m-%d %H:%M:%S %Z') # Adjusted based on context
echo "Script started around: $CURRENT_DATE"

# Check if the input file exists
if [ ! -f "$FILENAME" ]; then
    echo "Error: File '$FILENAME' not found in the current directory ($(pwd))."
    echo "Please upload the file containing full Resource IDs to Cloud Shell."
    exit 1
fi

# Read the file line by line
deleted_count=0
failed_count=0
skipped_count=0
line_number=0

while IFS= read -r resource_id || [[ -n "$resource_id" ]]; do
    ((line_number++))

    # Trim potential leading/trailing whitespace (like carriage returns if file came from Windows)
    resource_id=$(echo "$resource_id" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # Basic validation: Skip empty lines or lines that don't look like resource IDs
    if [ -z "$resource_id" ]; then
        echo "Skipping line $line_number: Empty line."
        ((skipped_count++))
        continue
    fi
    # Basic check that it starts with the subscription path format
    if [[ ! "$resource_id" == /subscriptions/* ]]; then
         echo "Skipping line $line_number: Does not look like a valid Azure Resource ID (must begin with /subscriptions/): '$resource_id'"
         ((skipped_count++))
         continue
    fi

    echo "----------------------------------------"
    echo "Attempting to delete resource (Line $line_number): '$resource_id'"

    # Execute the Azure CLI command to delete the resource using its ID
    # Using --yes to bypass the confirmation prompt that 'az resource delete' normally shows
    # Using --verbose to get more detailed output, especially useful on failure
    az resource delete --ids "$resource_id" --verbose

    # Check the exit status of the command
    if [ $? -eq 0 ]; then
        echo "Successfully deleted resource: '$resource_id'"
        ((deleted_count++))
    else
        # Check the verbose output above for detailed error messages from Azure
        echo "Error: Failed to delete resource: '$resource_id'. Check permissions, ID validity, or if the resource still exists."
        ((failed_count++))
    fi

done < "$FILENAME"

echo "========================================"
echo "Resource deletion process finished."
echo "Successfully deleted: $deleted_count resource(s)."
echo "Failed attempts:      $failed_count resource(s)."
echo "Skipped lines:        $skipped_count (due to empty lines or invalid format)."
echo "========================================"
