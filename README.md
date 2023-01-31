# Requierments

- xml2rfc. `pip install xml2rfc`
- Pyang. `pip install pyang`. `https://github.com/mbj4668/pyang`. 
- rfcfold. `https://github.com/ietf-tools/rfcfold`. It is a bash script, install it in the system as you prefer.

This yang model depends on other IETF models. One way of obtaining them can be:

Obtain the `https://github.com/YangModels/yang/` repository:
```
git clone https://github.com/YangModels/yang/
```

Refresh it before building the draft:
```
cd yang
git pull
```

Configure pyang to read from the IETF drafts and RFCs from the repo. One method for achiving this is modifying the 
```
export YANG_MODPATH=/path/to/yang/standard/iana:/path/to/yang/standard/ietf:/path/to/yang/experimental
```

# Draft preparation instructions

`make clean`, `make`
