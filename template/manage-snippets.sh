#!/bin/bash

# Proxmox Snippet Management Script
# Usage: ./manage-snippets.sh [COMMAND] [OPTIONS]
#
# Commands:
#   list                     List snippets on Proxmox
#   upload                   Upload a local file as a snippet
#   download                 Download a snippet from Proxmox
#   delete                   Delete a snippet from Proxmox
#
# Global Options:
#   --ssh-host HOST          SSH host to connect to Proxmox (Required)
#   --storage STORAGE        Proxmox storage name (default: nfslorien)
#
# Upload/Download/Delete Options:
#   --file FILE              File path (local for upload, remote filename for others)
#   --local-path PATH        Local destination path for download (optional)

set -e

# Default values
STORAGE="nfslorien"
SSH_HOST=""
COMMAND=""
FILE=""
LOCAL_PATH=""

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [COMMAND] --ssh-host HOST [OPTIONS]

Commands:
    list                        List all snippets in the specified storage
    upload --file PATH          Upload a local file to Proxmox snippets
    download --file NAME        Download a snippet from Proxmox to local
    delete --file NAME          Delete a snippet from Proxmox

Global Options:
    --ssh-host HOST             SSH host to connect to Proxmox
    --storage STORAGE           Proxmox storage name (default: nfslorien)

Options:
    --file FILE                 Filename (local path for upload, remote name for others)
    --local-path PATH           Destination path for download (default: current dir)
    -h, --help                  Show this help message

Examples:
    $0 list --ssh-host root@pve
    $0 upload --ssh-host root@pve --file my-config.yaml
    $0 download --ssh-host root@pve --file my-config.yaml --local-path ./backups/
    $0 delete --ssh-host root@pve --file old-config.yaml
EOF
    exit 1
}

# Parse command (must be first)
if [[ $# -gt 0 && ! $1 =~ ^-- ]]; then
    COMMAND="$1"
    shift
fi

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --ssh-host) SSH_HOST="$2"; shift 2 ;;
        --storage) STORAGE="$2"; shift 2 ;;
        --file) FILE="$2"; shift 2 ;;
        --local-path) LOCAL_PATH="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "Error: Unknown option: $1"; usage ;;
    esac
done

# Validate required arguments
if [ -z "$COMMAND" ]; then echo "Error: Command is required"; usage; fi
if [ -z "$SSH_HOST" ]; then echo "Error: --ssh-host is required"; usage; fi

# SSH command prefix
SSH="ssh $SSH_HOST"

# Step 1: Identify storage path
get_storage_path() {
    # Try using pvesh (API tool)
    # Use grep/sed to extract path from JSON-like output without jq
    local path=$($SSH "pvesh get /storage/$STORAGE --output-format json 2>/dev/null | grep -o '\"path\":\"[^\"]*\"' | sed 's/\"path\":\"//;s/\"//'")
    
    # Fallback to pvesm status - much easier to parse in text mode
    if [ -z "$path" ]; then
        # pvesm status -storage <name> returns a header and a data line
        # The path is usually the last column. We filter for absolute paths starting with /
        path=$($SSH "pvesm status -storage $STORAGE | awk 'NR>1 {print \$NF}' | grep '^/' || true")
    fi

    # Final fallback: most common Proxmox mount point pattern
    if [ -z "$path" ] || [ "$path" == "null" ]; then
        echo "/mnt/pve/$STORAGE"
    else
        echo "$path"
    fi
}

STORAGE_PATH=$(get_storage_path)
SNIPPETS_DIR="$STORAGE_PATH/snippets"

case $COMMAND in
    list)
        echo "=== Snippets in $STORAGE ($SNIPPETS_DIR) ==="
        $SSH "ls -1 $SNIPPETS_DIR 2>/dev/null || echo '(No snippets found or directory does not exist)'"
        ;;

    upload)
        if [ -z "$FILE" ]; then echo "Error: --file is required for upload"; exit 1; fi
        if [ ! -f "$FILE" ]; then echo "Error: Local file not found: $FILE"; exit 1; fi
        
        REMOTE_NAME=$(basename "$FILE")
        echo "Uploading $FILE to $SNIPPETS_DIR/$REMOTE_NAME..."
        $SSH "mkdir -p $SNIPPETS_DIR"
        scp "$FILE" "$SSH_HOST:$SNIPPETS_DIR/$REMOTE_NAME"
        echo "Done!"
        ;;

    download)
        if [ -z "$FILE" ]; then echo "Error: --file (remote name) is required for download"; exit 1; fi
        
        TARGET_PATH=${LOCAL_PATH:-"."}
        if [ -d "$TARGET_PATH" ]; then
            TARGET_FILE="$TARGET_PATH/$(basename "$FILE")"
        else
            TARGET_FILE="$TARGET_PATH"
        fi

        echo "Downloading $STORAGE:$FILE to $TARGET_FILE..."
        scp "$SSH_HOST:$SNIPPETS_DIR/$FILE" "$TARGET_FILE"
        echo "Done!"
        ;;

    delete)
        if [ -z "$FILE" ]; then echo "Error: --file (remote name) is required for delete"; exit 1; fi
        
        read -p "Are you sure you want to delete snippet '$FILE' from $STORAGE? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            $SSH "rm $SNIPPETS_DIR/$FILE"
            echo "Deleted snippet $FILE."
        else
            echo "Delete cancelled."
        fi
        ;;

    *)
        echo "Error: Unknown command: $COMMAND"
        usage
        ;;
esac
