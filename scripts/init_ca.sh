#!/usr/bin/env bash
set -euo pipefail 

# Variables 

PKI_DIR="pki"
PKI_CA="${PKI_DIR}/ca"
PKI_CERTS="${PKI_CA}/certs"
PKI_CRL="${PKI_CA}/crl"
PKI_PRIVATE="${PKI_CA}/private"
PKI_NEWCERTS="${PKI_CA}/newcerts"
PKI_SERIAL="${PKI_CA}/serial"
PKI_CRL_NUMBER="${PKI_CA}/crl_number"





if [ -d "pki" ]; then
    echo "pki directory already exists"
    exit 1

else
    mkdir -p pki/{newcerts,private,certs}
    touch pki/index.txt
    echo 1000 > pki/serial
    echo 1000 > pki/crlnumber
fi

chmod 700 pki/private



chmod 400 pki/private/rootca.key

if [ -f "pki/certs/rootca.crt" ]; then
    echo "rootca.crt already exists"
elif [ -f "pki/private/rootca.key" ]; then
    echo "rootca.key already exists"
else  
    openssl genrsa -aes256 -out pki/private/rootca.key 4096
    openssl req -new -x509 -config openssl.cnf -key pki/private/rootca.key -out pki/certs/rootca.crt 
fi

