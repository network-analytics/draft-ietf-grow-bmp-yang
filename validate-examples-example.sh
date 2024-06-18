#!/bin/bash
set -x
set -e


# Specify the directory and the command
DIRECTORY="clean_examples"
COMMAND="yanglint -p . -p path -p path ietf-tcp-common@2023-04-17.yang ietf-bgp-types@2022-03-06.yang ietf-bmp.yang -t config"

# Loop through all files in the directory
for FILE in "$DIRECTORY"/*
do
  # Check if it's a file (not a directory)
  if [ -f "$FILE" ]; then
    # Run the command on the file
    $COMMAND "$FILE"
  fi
done
