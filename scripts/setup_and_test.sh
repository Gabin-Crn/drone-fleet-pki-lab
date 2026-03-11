#!/usr/bin/env bash
set -uo pipefail

#=============================================================================
# setup_and_test.sh - Recrée toute la PKI et exécute les tests
#=============================================================================

PASS=0
FAIL=0

ok()   { echo -e "\033[32m[✓ PASS]\033[0m $1"; PASS=$((PASS+1)); }
fail() { echo -e "\033[31m[✗ FAIL]\033[0m $1"; FAIL=$((FAIL+1)); }

check() {
    # $1 = description, $2 = commande à tester
    if eval "$2" > /dev/null 2>&1; then
        ok "$1"
    else
        fail "$1"
    fi
}

summary() {
    echo ""
    echo "========================================="
    echo "  RÉSULTATS : $PASS passed / $FAIL failed"
    echo "========================================="
    if [[ $FAIL -gt 0 ]]; then
        exit 1
    fi
}

trap summary EXIT

echo ""
echo "========================================="
echo "  ÉTAPE 1 : Nettoyage complet"
echo "========================================="

rm -rf pki ca-bundle.crt ca-bundle-crl.pem logs
echo "[+] Suppression pki/, bundles, logs"

echo ""
echo "========================================="
echo "  ÉTAPE 2 : Initialisation Root CA"
echo "========================================="

./scripts/init_ca.sh || exit 1

check "Répertoire pki/rootca créé"         "[ -d pki/rootca ]"
check "Répertoire pki/intermediate créé"    "[ -d pki/intermediate ]"
check "Répertoire pki/endpoint créé"        "[ -d pki/endpoint ]"
check "Root CA key générée"                 "[ -f pki/rootca/private/rootca.key ]"
check "Root CA cert généré"                 "[ -f pki/rootca/certs/rootca.crt ]"
check "Permissions rootca.key (400)"        "[ \$(stat -f '%Lp' pki/rootca/private/rootca.key) = '400' ]"
check "Permissions private/ (700)"          "[ \$(stat -f '%Lp' pki/rootca/private) = '700' ]"
check "index.txt rootca existe"             "[ -f pki/rootca/index.txt ]"
check "serial rootca existe"                "[ -f pki/rootca/serial ]"

echo ""
echo "========================================="
echo "  ÉTAPE 3 : Émission certificats serveur"
echo "========================================="

./scripts/issue_certs.sh server GCS || exit 1

check "Intermediate key générée"            "[ -f pki/intermediate/private/intermediate.key ]"
check "Intermediate CSR généré"             "[ -f pki/csr/intermediate.csr ]"
check "Intermediate cert généré"            "[ -f pki/intermediate/certs/intermediate.crt ]"
check "Serveur GCS-0 key générée"           "[ -f pki/endpoint/private/GCS-0.key ]"
check "Serveur GCS-0 cert généré"           "[ -f pki/endpoint/certs/GCS-0.crt ]"

echo ""
echo "========================================="
echo "  ÉTAPE 4 : Émission certificats drones"
echo "========================================="

./scripts/issue_certs.sh drone drone-fr 3 || exit 1

check "Drone drone-fr-0 key"               "[ -f pki/endpoint/private/drone-fr-0.key ]"
check "Drone drone-fr-1 key"               "[ -f pki/endpoint/private/drone-fr-1.key ]"
check "Drone drone-fr-2 key"               "[ -f pki/endpoint/private/drone-fr-2.key ]"
check "Drone drone-fr-0 cert"              "[ -f pki/endpoint/certs/drone-fr-0.crt ]"
check "Drone drone-fr-1 cert"              "[ -f pki/endpoint/certs/drone-fr-1.crt ]"
check "Drone drone-fr-2 cert"              "[ -f pki/endpoint/certs/drone-fr-2.crt ]"

echo ""
echo "========================================="
echo "  ÉTAPE 5 : Génération CRL"
echo "========================================="

./scripts/gen_crl.sh both || exit 1

check "CRL rootca générée"                 "[ -f pki/rootca/crl/rootca.crl.pem ]"
check "CRL intermediate générée"           "[ -f pki/intermediate/crl/intermediate.crl.pem ]"

echo ""
echo "========================================="
echo "  ÉTAPE 6 : Création bundles CA"
echo "========================================="

cat pki/rootca/certs/rootca.crt pki/intermediate/certs/intermediate.crt > ca-bundle.crt
cat ca-bundle.crt pki/rootca/crl/rootca.crl.pem pki/intermediate/crl/intermediate.crl.pem > ca-bundle-crl.pem

check "ca-bundle.crt créé"                 "[ -f ca-bundle.crt ]"
check "ca-bundle-crl.pem créé"             "[ -f ca-bundle-crl.pem ]"

echo ""
echo "========================================="
echo "  ÉTAPE 7 : Vérification chaîne de certs"
echo "========================================="

check "Intermediate cert valide (chaîne)"  "openssl verify -CAfile pki/rootca/certs/rootca.crt pki/intermediate/certs/intermediate.crt"
check "GCS-0 cert valide (chaîne)"         "openssl verify -CAfile ca-bundle.crt pki/endpoint/certs/GCS-0.crt"
check "drone-fr-0 cert valide (chaîne)"    "openssl verify -CAfile ca-bundle.crt pki/endpoint/certs/drone-fr-0.crt"
check "drone-fr-1 cert valide (chaîne)"    "openssl verify -CAfile ca-bundle.crt pki/endpoint/certs/drone-fr-1.crt"
check "drone-fr-2 cert valide (chaîne)"    "openssl verify -CAfile ca-bundle.crt pki/endpoint/certs/drone-fr-2.crt"


echo ""
echo "========================================="
echo "  ÉTAPE 8 : Test TLS (serveur + client)"
echo "========================================="

SERVER_PID=""
cleanup_server() {
    if [[ -n "$SERVER_PID" ]] && kill -0 "$SERVER_PID" 2>/dev/null; then
        kill "$SERVER_PID" 2>/dev/null || true
        wait "$SERVER_PID" 2>/dev/null || true
    fi
}

# Lancer le serveur en arrière-plan
python3 ./simulator/server.py -c pki/endpoint/certs/GCS-0.crt -k pki/endpoint/private/GCS-0.key -p passphrase.txt -s > /dev/null 2>&1 &
SERVER_PID=$!
sleep 2

# Test connexion avec drone valide
OUTPUT=$(python3 ./simulator/client.py -c pki/endpoint/certs/drone-fr-0.crt -k pki/endpoint/private/drone-fr-0.key -p passphrase.txt 2>&1)
if echo "$OUTPUT" | grep -q "Connected to"; then
    ok "Connexion TLS drone-fr-0 -> GCS réussie"
else
    fail "Connexion TLS drone-fr-0 -> GCS échouée"
fi

cleanup_server
sleep 1

echo ""
echo "========================================="
echo "  ÉTAPE 9 : Test révocation + CRL"
echo "========================================="

# Révoquer drone-fr-1
openssl ca -config openssl-intermediate.cnf -revoke pki/endpoint/certs/drone-fr-1.crt -passin file:passphrase.txt 2>/dev/null
check "drone-fr-1 révoqué"                 "grep -q 'R' pki/intermediate/index.txt"

# Régénérer CRL + bundle
./scripts/gen_crl.sh intermediate || exit 1
cat ca-bundle.crt pki/rootca/cert/rootca.crt pki/intermediate/cert/intermediate.crt pki/intermediate/crl/intermediate.crl.pem > ca-bundle-crl.pem
check "CRL mise à jour après révocation"   "[ -f pki/intermediate/crl/intermediate.crl.pem ]"

# Relancer le serveur
python3 ./simulator/server.py -c pki/endpoint/certs/GCS-0.crt -k pki/endpoint/private/GCS-0.key -p passphrase.txt -s > /dev/null 2>&1 &
SERVER_PID=$!
sleep 2

# Test avec drone révoqué -> doit échouer
OUTPUT=$(python3 ./simulator/client.py -c pki/endpoint/certs/drone-fr-1.crt -k pki/endpoint/private/drone-fr-1.key -p passphrase.txt 2>&1)
if echo "$OUTPUT" | grep -qi "revoked\|error\|verification"; then
    ok "Connexion drone-fr-1 (révoqué) rejetée"
else
    fail "Connexion drone-fr-1 (révoqué) aurait dû être rejetée"
fi

cleanup_server
sleep 1

# Relancer le serveur pour le test suivant
python3 ./simulator/server.py -c pki/endpoint/certs/GCS-0.crt -k pki/endpoint/private/GCS-0.key -p passphrase.txt -s > /dev/null 2>&1 &
SERVER_PID=$!
sleep 2

# Test avec drone non révoqué -> doit fonctionner
OUTPUT=$(python3 ./simulator/client.py -c pki/endpoint/certs/drone-fr-2.crt -k pki/endpoint/private/drone-fr-2.key -p passphrase.txt 2>&1)
if echo "$OUTPUT"  | grep -q "Connected to";then
    ok "Connexion TLS drone-fr-2 (valide) -> GCS réussie"
else
    fail "Connexion TLS drone-fr-2 (valide) -> GCS échouée"
fi

cleanup_server
