#!/bin/bash

# Set the source directory to be backed up
source_directory="local/dev/root/scripts"

# Set the destination directory where the backup will be stored
backup_directory="/staging/backup/directory"

# Create a timestamp for the backup filename
timestamp=$(date +"%Y%m%d%H%M%S")

# Set the filename for the backup archive
backup_filename="backup_$timestamp.tar.gz"

# Create the backup using tar
tar -czvf "$backup_directory/$backup_filename" "$source_directory"

# Check if the backup was successful
if [ $? -eq 0 ]; then
    echo "Backup completed successfully. Backup saved to $backup_directory/$backup_filename"
else
    echo "Backup failed. Please check for errors."
fi
