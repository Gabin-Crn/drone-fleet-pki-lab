#!/usr/bin/env bash 
set -euo pipefail 


if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <server|drone> <common-name> [third-param-for-drone]"
  exit 1
fi

type="$1"

if [[ "$type" == "drone" ]]; then
  if [[ $# -ne 3 ]]; then
    echo "Usage: $0 drone <common-name> <third-param>"
    exit 1
  fi
  EXT="drone_cert"
  cn="$2"
  number_of_drone="$3"

elif [[ "$type" == "server" ]]; then
  if [[ $# -ne 2 ]]; then
    echo "Usage: $0 server <common-name>"
    exit 1
  fi
  EXT="server_cert"
  cn="$2"
  number_of_drone=1


else
  echo "Usage: $0 <server|drone> <common-name> [third-param-for-drone]"
  exit 1
fi

PKI_DIR="pki"
PKI_CSR="${PKI_DIR}/csr"
PKI_CERT="${PKI_DIR}/intermediate/certs"
PKI_PRIVATE="${PKI_DIR}/intermediate/private"

PKI_CERT_ED="${PKI_DIR}/endpoint/certs"
PKI_PRIVATE_ED="${PKI_DIR}/endpoint/private"
OPENSSL_CONFIG_CA="openssl-rootca.cnf"
OPENSSL_CONFIG_intermediate="openssl-intermediate.cnf"

## Check if files exists

# intermediate key generation
if [[  -f "${PKI_PRIVATE}/intermediate.key" ]]; then
    echo "[+] intermediate key already exists"
else
    openssl genrsa -aes256 -out "${PKI_PRIVATE}/intermediate.key" -passout file:passphrase.txt 4096
    chmod 400 "${PKI_PRIVATE}/intermediate.key"

    echo "[+] intermediate key has been generated"
fi

# Drone key generation
for (( i=0 ; i<number_of_drone ; i++ )); do 
    if [[ -f "${PKI_PRIVATE_ED}/${cn}-${i}.key" ]]; then
        echo "[+] ${cn} ${i} already exists"
    else
        openssl genrsa -aes256 -out "${PKI_PRIVATE_ED}/${cn}-${i}.key" -passout file:passphrase.txt 4096
        chmod 400 "${PKI_PRIVATE_ED}/${cn}-${i}.key"
        echo "[+] ${cn} ${i} has been generated"
    fi
done


# Generation csr 

if [[ -f "${PKI_CSR}/intermediate.csr" ]]; then
    echo "[+] intermediate csr already exists"
else
    openssl req -new -config "${OPENSSL_CONFIG_CA}" -key "${PKI_PRIVATE}/intermediate.key" -out "${PKI_CSR}/intermediate.csr" -passin file:passphrase.txt -subj "/C=FR/O=Drone Fleet/OU=Security/CN=Drone intermediate CA"
    echo "[+] intermediate csr has been generated"
fi

for ((i=0; i<number_of_drone; i++)); do
    if [[ -f "${PKI_CSR}/${cn}.${i}.csr" ]]; then
        echo "[+] ${cn} ${i} csr already exists"
    else
        openssl req -new -config "${OPENSSL_CONFIG_intermediate}" -key "${PKI_PRIVATE_ED}/${cn}-${i}.key" -out "${PKI_CSR}/${cn}-${i}.csr" -passin file:passphrase.txt -subj "/C=FR/O=Drone Fleet/OU=Security/CN=${cn}-00${i}"
        echo "[+] ${cn} ${i} csr has been generated"
    fi
done


#------------------------------------------------------------------------------------------------------------------------------------------------------------
# intermediate + Drones certificate generation
#------------------------------------------------------------------------------------------------------------------------------------------------------------


if [[ -f "${PKI_CERT}/intermediate.crt" ]]; then
    echo "[+] intermediate cert already exists"
else
    openssl ca -batch -config "${OPENSSL_CONFIG_CA}" -in "${PKI_CSR}/intermediate.csr" -out "${PKI_CERT}/intermediate.crt" -passin file:passphrase.txt -extensions v3_intermediate_ca
    echo "[+] intermediate cert has been generated"
fi

for (( i=0; i < number_of_drone; i++)); do
    if [[ -f "${PKI_CERT_ED}/${cn}.${i}.crt" ]]; then
        echo "[+] ${cn}-${i} already exists"
    else
        openssl ca -batch -config "${OPENSSL_CONFIG_intermediate}" -in "${PKI_CSR}/${cn}-${i}.csr" -out "${PKI_CERT_ED}/${cn}-${i}.crt" -passin file:passphrase.txt -extensions "${EXT}"
        echo "[+] ${cn}-${i} has been generated"
    fi
done