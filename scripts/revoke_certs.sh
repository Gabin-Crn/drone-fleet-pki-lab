#!/usr/bin/env bash

if [[ $# -ne 2 ]]; then 
    echo "Usage : $0 <common_name>"
    exit 1
fi

CN=$1
CERT_PATH="pki/endpoints/${CN}.crt"

if [[ ! -f "$CERT_PATH" ]]; then
    echo "Certificate not found: $CERT_PATH"
    exit 1
fi


openssl ca -config opensskl-intermediate.cnf -revoke "$CN"
echo "[+] ${CN} Revoked"
