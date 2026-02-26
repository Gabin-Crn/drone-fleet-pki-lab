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
PKI_INDEX="${PKI_CA}/index.txt"
PKI_CRL_NUMBER="${PKI_CA}/crl_number"

OPENSSL_CONFIG="openssl.cnf"

# Creation directories

if [ -d "pki" ]; then
    echo "[+] pki directory already exists"
else
    mkdir -p "${PKI_CA}" "${PKI_NEWCERTS}" "${PKI_PRIVATE}" "${PKI_CERTS}" "${PKI_CRL}"
    echo "[+] Creation (CA -> newcerts, private, certs, crl) directories"
    touch "${PKI_INDEX}"
    echo 1000 > ${PKI_SERIAL}
    echo 1000 > ${PKI_CRL_NUMBER}
    echo "[+] Creation index.txt, serial, crl_number files & initial values for serial and crl_number"  
fi

# RootCA Key generation

if [ -f "${PKI_PRIVATE}/root-ca.key" ]; then
    echo "[+] Root CA key already exists"
else
    openssl genrsa -aes256 -out "${PKI_PRIVATE}/root-ca.key" 4096
    echo "[+] Root CA key generated"
fi


# RootCA Certificate generation

if [ -f "${PKI_CERTS}/root-ca.crt" ]; then
    echo "[+] Root CA certificate already exists"
else
    openssl req -new -x509 -config ${OPENSSL_CONFIG} -key ${PKI_PRIVATE}/root-ca.key -out ${PKI_CERTS}/root-ca.crt -days 7300
    echo "[+] Root CA certificate generated"
fi

# Permission management 
chmod 700 "${PKI_PRIVATE}"
chmod 400 "${PKI_PRIVATE}/root-ca.key"