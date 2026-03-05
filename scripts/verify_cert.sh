#!/usr/bin/env bash

if [[ $# -ne 1 ]]; then 
    echo "Usage : $0 <certificate_path>"
    exit 1
fi

CERT_PATH=$1

openssl verify  -CAfile "pki/ca/certs/root-ca.crt" -untrusted "pki/intermediate/certs/intermediate.crt"   -crl_check  -CRLfile "pki/intermediate/crl/intermediate.crl.pem"  "$CERT_PATH"