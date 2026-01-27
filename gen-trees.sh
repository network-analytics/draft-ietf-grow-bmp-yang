#!/bin/bash

# based on the file from the repo https://github.com/netconf-wg/tls-client-server/

YANG_PATH="/Users/camilo/Documents/Projects/drafts/bmp_yang_model/other_examples/yang/experimental"
#PYANG_OPTS="--ietf -p $YANG_PATH -f tree --tree-line-length 65"
PYANG_OPTS="-p $YANG_PATH -f tree "

echo "Generating tree diagrams..."

# Full tree for Appendix (with augments from tcp-dependencies)
pyang $PYANG_OPTS ietf-bmp.yang ietf-bmp-tcp-dependencies.yang > ietf-bmp-trees.txt

echo "Generating subtrees for sections..."

# Section 3 - Model description intro: High-level overview (depth 4)
pyang $PYANG_OPTS --tree-depth 4 ietf-bmp.yang > trees/tree-overview.txt

# Section 3.1-3.3 - Connection (includes active/passive, tcp-options, backoff)
# Full connection subtree with tcp-dependencies augments
pyang $PYANG_OPTS \
  --tree-path "/bmp/monitoring-stations/monitoring-station/connection" \
  ietf-bmp.yang ietf-bmp-tcp-dependencies.yang > trees/tree-connection.txt

# Section 3.4 - BMP data (depth 7 to show containers but hide route-monitoring internals)
pyang $PYANG_OPTS --tree-depth 7 \
  --tree-path "/bmp/monitoring-stations/monitoring-station/bmp-data" \
  ietf-bmp.yang > trees/tree-bmp-data.txt

# Section 3.4.1 - Route monitoring detail (depth 11 to show structure)
pyang $PYANG_OPTS --tree-depth 11 \
  --tree-path "/bmp/monitoring-stations/monitoring-station/bmp-data/route-monitoring" \
  ietf-bmp.yang > trees/tree-route-monitoring.txt

# Section 3.5 - Session stats
pyang $PYANG_OPTS \
  --tree-path "/bmp/monitoring-stations/monitoring-station/session-stats" \
  ietf-bmp.yang > trees/tree-session-stats.txt

# Section 3.6 - Session actions
pyang $PYANG_OPTS \
  --tree-path "/bmp/monitoring-stations/monitoring-station/actions" \
  ietf-bmp.yang > trees/tree-actions.txt

echo "Done. Trees generated in trees/ directory."
echo "Full tree: ietf-bmp-trees.txt"
echo ""
echo "Generated files:"
ls -la trees/

