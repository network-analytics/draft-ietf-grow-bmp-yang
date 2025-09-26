echo "Validating yang modes"

PYANG_INPUT='ietf-bmp.yang ietf-bmp-bgp-dependencies.yang ietf-bmp-tcp-dependencies.yang'

pyang --ietf --max-line-length 69 $PYANG_INPUT

# now make sure the format works	
pyang -f yang --yang-canonical "$PYANG_INPUT" > /tmp/canonical.yang

# Compare
if ! diff -u "$orig" /tmp/canonical.yang; then
  echo "ERROR: File is not canonical, run it with pyang -f yang --yang-canonical before"
  exit 1
fi

yanglint -p . -p /Users/camilo/Documents/Projects/drafts/bmp_yang_model/other_examples/yang/experimental  ietf-bmp.yang ietf-bmp-bgp-dependencies.yang ietf-bmp-tcp-dependencies.yang -f yang > /dev/null

