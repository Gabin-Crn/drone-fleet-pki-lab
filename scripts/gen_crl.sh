#!/usr/bin/env bash
set -euo pipefail 

if [[ $# -ne 1 ]];then
    echo "Usage : $0 <rootca|intermediate || both>"
    exit 1
fi

WHICH_CRL="$1"

if [[ "$WHICH_CRL" == "both" ]];then
    for i in "rootca" "intermediate";do
        openssl ca -config openssl-$i.cnf -gencrl -out pki/$i/crl/$i.crl.pem -passin file:passphrase.txt
        openssl crl -in pki/$i/crl/$i.crl.pem -noout -text | grep -E "Last Update|Next Update|Serial Number" || true
    done
elif [[ "$WHICH_CRL" == "rootca" ]];then
    openssl ca -config openssl-rootca.cnf -gencrl -out pki/ca/crl/rootca.crl.pem -passin file:passphrase.txt
    openssl crl -in pki/ca/crl/rootca.crl.pem -noout -text | grep -E "Last Update|Next Update|Serial Number" || true
elif [[ "$WHICH_CRL" == "intermediate" ]];then
    openssl ca -config openssl-intermediate.cnf -gencrl -out pki/intermediate/crl/intermediate.crl.pem -passin file:passphrase.txt
    openssl crl -in pki/intermediate/crl/intermediate.crl.pem -noout -text | grep -E "Last Update|Next Update|Serial Number" || true
else
    echo "Usage : $0 <rootca|intermediate || both>"
fi

# Generate CRL
