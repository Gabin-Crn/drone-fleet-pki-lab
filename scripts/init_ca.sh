#!/usr/bin/env bash
set -euo pipefail 


# Variables 

PKI_DIR="pki"
PKI_CA="${PKI_DIR}/ca"
PKI_ISSUE="${PKI_DIR}/issue"


OPENSSL_CONFIG="openssl-rootca.cnf"

# Creation directories

if [ -d "pki" ]; then
    echo "[+] pki directory already exists"
else
    mkdir -p "${PKI_CA}" "${PKI_CA}/newcerts" "${PKI_CA}/private" "${PKI_CA}/certs" "${PKI_CA}/crl" 
    mkdir -p "${PKI_ISSUE}" "${PKI_ISSUE}/newcerts" "${PKI_ISSUE}/private" "${PKI_ISSUE}/certs" "${PKI_ISSUE}/crl"
    mkdir -p "${PKI_DIR}/csr"
    echo "[+] Creation (CA -> newcerts, private, certs, crl, csr) directories"
    for d in "${PKI_CA}" "${PKI_ISSUE}"; do
        touch "${d}/index.txt"
        echo 1000 > "${d}/crlnumber"
        echo 1000 > "${d}/serial"
    done
    echo "[+] Creation index.txt, serial, crl_number files & initial values for serial and crl_number"  
fi

# RootCA Key generation

if [ -f "${PKI_CA}/private/root-ca.key" ]; then
    echo "[+] Root CA key already exists"
else
    openssl genrsa -aes256 -out "${PKI_CA}/private/root-ca.key" -passout file:passphrase.txt 4096
    echo "[+] Root CA key generated"
fi


# RootCA Certificate generation

if [ -f "${PKI_CA}/certs/root-ca.crt" ]; then
    echo "[+] Root CA certificate already exists"
else
    openssl req -new -x509 -config ${OPENSSL_CONFIG} -key ${PKI_CA}/private/root-ca.key -out ${PKI_CA}/certs/root-ca.crt -extensions v3_root_ca -passin file:passphrase.txt -subj "/C=FR/O=Drone Fleet/OU=Security/CN=Drone Fleet Root CA"
    echo "[+] Root CA certificate generated"
fi

# Permission management 
chmod 744 "${PKI_CA}/private"
chmod 444 "${PKI_CA}/private/root-ca.key"

echo "Private directory permission: $(ls -ld "${PKI_CA}/private")"
echo "Root-ca key permission: $(ls -l "${PKI_CA}/private/root-ca.key")"