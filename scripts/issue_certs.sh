#!/usr/bin/env bash 
set -euo pipefail 

PKI_DIR="pki"
PKI_CSR="${PKI_DIR}/csr"
PKI_CERT="${PKI_DIR}/issue/certs"
PKI_PRIVATE="${PKI_DIR}/issue/private"
NUMBER_OF_DRONES="$1"
OPENSSL_CONFIG_CA="openssl-rootca.cnf"
OPENSSL_CONFIG_ISSUE="openssl-issue.cnf"

## Check if files exists

# Issue key generation
if [[  -f "${PKI/PRIVATE}/issue.key" ]]; then
    echo "[+] Issue key already exists"
else
    openssl genrsa -aes256 -out "${PKI_PRIVATE}/issue.key" -passout file:passphrase.txt 4096
    chmod 400 "${PKI_PRIVATE}/issue.key"

    echo "[+] Issue key has been generated"
fi

# Drone key generation
for (( i=0 ; i<NUMBER_OF_DRONES ; i++ )); do 
    if [[ -f "${PKI_PRIVATE}/drone.${i}.key" ]]; then
        echo "[+] Drone ${i} already exists"
    else
        openssl genrsa -aes256 -out "${PKI_PRIVATE}/drone-${i}.key" -passout file:passphrase.txt 4096
        chmod 400 "${PKI_PRIVATE}/drone-${i}.key"
        echo "[+] Drone ${i} has been generated"
    fi
done


# Generation csr 

if [[ -f "${PKI_CSR}/issue.csr" ]]; then
    echo "[+] Issue csr already exists"
else
    openssl req -new -config "${OPENSSL_CONFIG_CA}" -key "${PKI_PRIVATE}/issue.key" -out "${PKI_CSR}/issue.csr" -passin file:passphrase.txt -subj "/C=FR/O=Drone Fleet/OU=Security/CN=Drone Issue CA"
    echo "[+] Issue csr has been generated"
fi

for ((i=0; i<NUMBER_OF_DRONES; i++)); do
    if [[ -f "${PKI_CSR}/drone.${i}.csr" ]]; then
        echo "[+] Drone ${i} csr already exists"
    else
        openssl req -new -config "${OPENSSL_CONFIG_ISSUE}" -key "${PKI_PRIVATE}/drone-${i}.key" -out "${PKI_CSR}/drone-${i}.csr" -passin file:passphrase.txt -subj "/C=FR/O=Drone Fleet/OU=Security/CN=drone-00${i}"
        echo "[+] Drone ${i} csr has been generated"
    fi
done


#------------------------------------------------------------------------------------------------------------------------------------------------------------
# Issue + Drones certificate generation
#------------------------------------------------------------------------------------------------------------------------------------------------------------


if [[ -f "${PKI_CERT}/issue.crt" ]]; then
    echo "[+] Issue cert already exists"
else
    openssl ca -config "${OPENSSL_CONFIG_CA}" -in "${PKI_CSR}/issue.csr" -out "${PKI_CERT}/issue.crt" -passin file:passphrase.txt -extensions v3_root_ca
    echo "[+] Issue cert has been generated"
fi

for (( i=0; i < NUMBER_OF_DRONES; i++)); do
    if [[ -f "${PKI_CERT}/drone.${i}.crt" ]]; then
        echo "[+] Drone-${i} already exists"
    else
        openssl ca -config "${OPENSSL_CONFIG_ISSUE}" -in "${PKI_CSR}/drone-${i}.csr" -out "${PKI_CERT}/drone-${i}.crt" -passin file:passphrase.txt -extensions v3_issue_ca
        echo "[+] Drone-${i} has been generated"
    fi
done