#!/usr/bin/env bash 
set -euo pipefail 

PKI_DIR="pki"
PKI_CSR="${PKI_DIR}/ca/csr"
PKI_PRIVATE="${PKI_DIR}/ca/private"


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
for (( i=0; i<3; i++)); do 
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

for ((i=0; i<3; i++)); do
    if [[ -f "${PKI_CSR}/drone.${i}"]]; then
        echo "[+] Drone ${i} csr already exists"
    else
        openssl -req -new -config "${OPENSSL_CONFIG}" -key "${PKI_PRIVATE}/drone-${i}.key" -out "${PKI_CSR}/drone-${i}.csr"
        echo "[+] Drone ${i} csr has been generated"
    fi
done




