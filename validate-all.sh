echo "Validating yang modes"

pyang --ietf --max-line-length 69 ietf-bmp.yang ietf-bmp-bgp-dependencies.yang ietf-bmp-tcp-dependencies.yang

yanglint -p . -p /Users/camilo/Documents/Projects/drafts/bmp_yang_model/other_examples/yang/experimental  ietf-bmp.yang ietf-bmp-bgp-dependencies.yang ietf-bmp-tcp-dependencies.yang -f yang > /dev/null

