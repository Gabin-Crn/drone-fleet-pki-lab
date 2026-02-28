#!/usr/bin/env bash 
set -euo pipefail 

PKI_DIR="pki"
PKI_CSR="${PKI_DIR}/ca/csr"
PKI_CERT="${PKI_DIR}/ca/certs"
PKI_PRIVATE="${PKI_DIR}/ca/private"
NUMBER-OF-DRONES=$1

## Check if files exists

# Issue key generation
if [[  -f "${PKI/PRIVATE}/issue.key" ]]; then
    echo "[+] Issue key already exists"
else
    openssl genrsa -aes256 -out "${PKI_PRIVATE}/issue.key" 4096
    chmod 400 "${PKI_PRIVATE}/issue.key"

    echo "[+] Issue key has been generated"
fi

# Drone key generation
for (( i=0; i<$1; i++)); do 
    if [[ -f "${PKI/PRIVATE}/drones.${i}.key"]]; then
        echo "[+] Drone ${i} already exists"
    else
        openssl genrsa -aes256 -out "${PKI_PRIVATE}/drones.${i}.key" 4096
        chmod 400 "${PKI_PRIVATE}/drones.${i}.key"
        echo "[+] Drone ${i} has been generated"
    fi
done


# Generation csr 

if [[ -f "${PKI_CSR}/issue.csr"]]; then
    echo "[+] Issue csr already exists"
else
    openssl req -new -config "${OPENSSL_CONFIG}" -key "${PKI_PRIVATE}/issue.key" -out "${PKI_CSR}/issue.csr" 
    echo "[+] Issue csr has been generated"
fi

for ((i=0; i<$1; i++)); do
    if [[ -f "${PKI_CSR}/drone.${i}.csr"]]; then
        echo "[+] Drone ${i} csr already exists"
    else
        openssl -req -new -config "${OPENSSL_CONFIG}" -key "${PKI_PRIVATE}/drone-${i}.key" -out "${PKI_CSR}/drone-${i}.csr"
        echo "[+] Drone ${i} csr has been generated"
    fi
done


#------------------------------------------------------------------------------------------------------------------------------------------------------------
# Issue + Drones certificate generation
#------------------------------------------------------------------------------------------------------------------------------------------------------------


if [[ -f "${PKI_CERTS}/issue.crt" ]]; then
    echo "[+] Issue cert already exists"
else
    openssl x509 -req -config "openssl-rootca.cnf" -in "${$PKI_CSR}/issue.csr" -out "${PKI_CERTS}/issue.crt"
    echo "[+] Issue cert has been generated"
fi

for (( i=0; i < $1; i++)); do
    if [[ -f "${PKI_CERTS}/drone.${i}.crt"]]; then
        echo "[+] Drone-${i} already exists"
    else
        openssl x509 -req -config "openssl-issue.cnf" -in "${PKI_CSR}/drone-${i}.csr" -out "${PKI_CERTS}/drone-${i}.crt"
        echo "[+] Drone-${i} has been generated"
done