#!/bin/bash

# List of servers
servers=("server1" "server2" "server3")

# Apache installation command
install_apache="sudo apt-get update && sudo apt-get install -y apache2"

# Loop through each server and install Apache
for server in "${servers[@]}"; do
    echo "Installing Apache on $server..."
    ssh "$server" "$install_apache"
    if [ $? -eq 0 ]; then
        echo "Apache installed successfully on $server"
    else
        echo "Failed to install Apache on $server. Check the error message."
    fi
done
