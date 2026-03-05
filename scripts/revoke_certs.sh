#!/usr/bin/env bash

if [[ $# -ne 1 ]]; then 
    echo "Usage : $0 <common_name>"
    exit 1
fi

CN=$1
CERT_PATH="pki/endpoint/certs/${CN}.crt"

if [[ ! -f "$CERT_PATH" ]]; then
    echo "Certificate not found: $CERT_PATH"
    exit 1
fi


openssl ca -config openssl-intermediate.cnf -revoke "$CERT_PATH"
echo "[+] ${CN} Revoked"
