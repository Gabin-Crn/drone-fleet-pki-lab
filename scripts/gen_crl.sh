#!/usr/bin/env bash

# Generate CRL
openssl ca -config openssl-intermediate.cnf -gencrl -out pki/intermediate/crl/intermediate.crl.pem

openssl crl -in pki/intermediate/crl/intermediate.crl.pem -noout -text | grep -E "Last Update|Next Update|Serial Number" || true
