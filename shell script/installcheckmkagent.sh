#Samaple Script for monitoring agent installation.

#!/bin/bash

# List of servers
servers=("server1" "server2" "server3")

# Checkmk agent download URL
checkmk_agent_url="https://checkmk.example.com/check_mk/agents/check-mk-agent-2.0.0p13-<ARCH>.rpm"

# Set initial configuration parameters
checkmk_server="checkmk.example.com"
checkmk_agent_name="MyAgent"

# Loop through each server and install Checkmk agent
for server in "${servers[@]}"; do
    echo "Installing Checkmk agent on $server..."

    # Download the agent package
    wget -O check-mk-agent.rpm "$checkmk_agent_url"

    # Transfer and install the agent on the server
    scp check-mk-agent.rpm "$server":/tmp/
    ssh "$server" "sudo yum install -y /tmp/check-mk-agent.rpm && rm /tmp/check-mk-agent.rpm"

    # Configure the agent
    ssh "$server" "sudo tee /etc/check_mk/check_mk.ini > /dev/null <<EOL
    [global]
    server = $checkmk_server

    [client]
    name = $checkmk_agent_name
EOL"

    if [ $? -eq 0 ]; then
        echo "Checkmk agent installed and configured successfully on $server"
    else
        echo "Failed to install or configure Checkmk agent on $server. Check the error message."
    fi
done


