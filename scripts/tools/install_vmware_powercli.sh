#!/bin/bash

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root."
    exit 1
fi


VMWARE_POWERCLI_HOME="/opt/vmware-powercli"
mkdir -p $VMWARE_POWERCLI_HOME

cat << EOF > "$VMWARE_POWERCLI_HOME/powercli"
#!/bin/bash

# Display help message if the user passes -h or --help
if [[ "\$1" == "-h" || "\$1" == "--help" ]]; then
    echo "Usage: \$0 <PowerShell script> [local_directory] [options]"
    echo ""
    echo "Arguments:"
    echo "  <PowerShell script>   The PowerShell script to run inside the Docker container (e.g., example.ps1)."
    echo "  [local_directory]     The local directory to mount into the Docker container (default: ~/scripts)."
    echo ""
    echo "Options:"
    echo "  --powercli-help       Show help for the PowerCLI container (inside the Docker environment)."
    echo "  -h, --help            Show this help message."
    echo ""
    echo "Examples:"
    echo "  \$0 example.ps1"
    echo "    - Runs example.ps1 using the default ~/scripts directory."
    echo ""
    echo "  \$0 example.ps1 /path/to/local/dir"
    echo "    - Runs example.ps1 using the specified local directory."
    echo ""
    echo "  \$0 --powercli-help"
    echo "    - Shows help for PowerCLI inside the Docker container."
    exit 0
fi

# If the user wants PowerCLI help, run it inside the container
if [[ "\$1" == "--powercli-help" ]]; then
    docker run --rm --entrypoint="/usr/bin/pwsh" vmware/powerclicore -h
    exit 0
fi

# Ensure a script is passed as an argument
if [ \$# -lt 1 ]; then
    echo "Error: No PowerShell script provided."
    echo "Usage: \$0 <PowerShell script> [local_directory]"
    exit 1
fi

# The first argument is the PowerShell script to run
PS_SCRIPT="\$1"

# The second argument is an optional local directory to mount
LOCAL_DIR="\${2:-\$HOME/scripts}"  # Default to ~/scripts if no local directory is provided

# Check if the local directory exists
if [ ! -d "\$LOCAL_DIR" ]; then
    echo "Error: Local directory '\$LOCAL_DIR' does not exist."
    exit 1
fi

# Run the Docker container with the provided PowerShell script
docker run --rm --entrypoint="/usr/bin/pwsh" -v "\$LOCAL_DIR:/tmp/scripts" vmware/powerclicore /tmp/scripts/\$PS_SCRIPT

EOF

chmod +x "$VMWARE_POWERCLI_HOME/powercli"
ln -s "$VMWARE_POWERCLI_HOME/powercli" "/usr/local/bin/powercli"

