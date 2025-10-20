#!/bin/bash

# based on the file from the repo https://github.com/netconf-wg/tls-client-server/

echo "Generating tree diagrams..."

pyang  --ietf -f tree --tree-line-length 65 ietf-bmp.yang ietf-bmp-tcp-dependencies.yang > ietf-bmp-trees.txt

