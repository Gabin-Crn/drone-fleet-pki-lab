# Drone Fleet PKI Lab

Laboratoire d'infrastructure à clés publiques (PKI) pour une flotte de drones avec authentification mutuelle TLS et gestion de révocation de certificats (CRL).

## 📋 Table des matières

- [Architecture](#architecture)
- [Prérequis](#prérequis)
- [Installation](#installation)
- [Utilisation](#utilisation)
- [Structure du projet](#structure-du-projet)
- [Scénarios de test](#scénarios-de-test)
- [Sécurité](#sécurité)

## 🏗️ Architecture

### Hiérarchie PKI

```
Root CA (root-ca.key/crt)
    └── Intermediate CA (intermediate.key/crt)
            ├── Server Certificates (GCS-*.crt)
            └── Drone Certificates (drone-*.crt)
```

**Composants :**
- **Root CA** : Autorité de certification racine (offline, usage limité)
- **Intermediate CA** : CA intermédiaire pour émettre les certificats endpoints
- **Server Certificates** : Certificats pour les serveurs GCS (Ground Control Station)
- **Drone Certificates** : Certificats d'identité pour les drones

### Communication TLS

```
┌─────────┐                    ┌─────────┐
│  Drone  │ ←── mTLS + CRL ──→ │   GCS   │
│ (Client)│                    │(Server) │
└─────────┘                    └─────────┘
```

- **Authentification mutuelle** (mTLS) : client et serveur vérifient leurs certificats
- **Vérification CRL** : validation que les certificats ne sont pas révoqués
- **Communication chiffrée** : échange de données JSON sécurisé

## 🔧 Prérequis

- **OpenSSL** 1.1.1+ ou 3.x
- **Python** 3.7+
- **Bash** 4.0+

### Installation des dépendances

```bash
# macOS
brew install openssl

# Ubuntu/Debian
sudo apt-get install openssl

# Python (aucune dépendance externe requise, utilise la stdlib)
python3 --version
```

## 🚀 Installation

### 1. Cloner le projet

```bash
git clone <votre-repo>
cd drone-fleet-pki-lab
```

### 2. Créer le fichier de passphrase

```bash
echo "VotreMotDePasseSecurise123!" > passphrase.txt
chmod 600 passphrase.txt
```

⚠️ **Important** : Ce fichier contient la passphrase pour toutes les clés privées. Ne jamais le commiter.

### 3. Initialiser la PKI

```bash
# Créer la Root CA
./scripts/init_ca.sh

# Émettre les certificats intermédiaires et endpoints
./scripts/issue_certs.sh server GCS 1      # 1 serveur GCS
./scripts/issue_certs.sh drone drone-fr 3  # 3 drones

# Générer les CRL
./scripts/gen_crl.sh both

# Créer les bundles CA
cat pki/ca/certs/root-ca.crt pki/intermediate/certs/intermediate.crt > ca-bundle.crt
cat ca-bundle.crt pki/ca/crl/rootca.crl.pem pki/intermediate/crl/intermediate.crl.pem > ca-bundle-crl.pem
```

## 📖 Utilisation

### Scripts disponibles

#### `init_ca.sh`
Initialise la Root CA et crée la structure de répertoires PKI.

```bash
./scripts/init_ca.sh
```

#### `issue_certs.sh`
Émet des certificats pour serveurs ou drones.

```bash
# Syntaxe
./scripts/issue_certs.sh <server|drone> <common-name> [nombre-de-drones]

# Exemples
./scripts/issue_certs.sh server GCS-1-0
./scripts/issue_certs.sh drone drone-fr 5
```

#### `gen_crl.sh`
Génère les listes de révocation de certificats.

```bash
# Syntaxe
./scripts/gen_crl.sh <rootca|intermediate|both>

# Exemples
./scripts/gen_crl.sh both
./scripts/gen_crl.sh intermediate
```

#### `revoke_certs.sh`
Révoque un certificat endpoint.

```bash
# Syntaxe
./scripts/revoke_certs.sh <common-name>

# Exemple
./scripts/revoke_certs.sh drone-fr-1
```

#### `verify_cert.sh`
Vérifie la validité d'un certificat (chaîne + CRL).

```bash
# Syntaxe
./scripts/verify_cert.sh <certificate-path>

# Exemple
./scripts/verify_cert.sh pki/endpoint/certs/drone-fr-0.crt
```

### Simulateur TLS

#### Démarrer le serveur GCS

```bash
cd simulator
python3 server.py
```

Le serveur écoute sur `localhost:8443` avec :
- Certificat serveur : `pki/endpoint/certs/GCS-1-0.crt`
- Vérification client obligatoire
- CA bundle : `ca-bundle.crt`

#### Démarrer un client drone

```bash
cd simulator
python3 client.py
```

Le client se connecte avec :
- Certificat client : `pki/endpoint/certs/drone-fr-1.crt`
- Vérification CRL active
- CA bundle + CRL : `ca-bundle-crl.pem`

## 📁 Structure du projet

```
drone-fleet-pki-lab/
├── scripts/
│   ├── init_ca.sh           # Initialisation Root CA
│   ├── issue_certs.sh       # Émission certificats
│   ├── gen_crl.sh           # Génération CRL
│   ├── revoke_certs.sh      # Révocation certificats
│   └── verify_cert.sh       # Vérification certificats
├── simulator/
│   ├── server.py            # Serveur GCS (TLS)
│   └── client.py            # Client drone (TLS)
├── logs/                    # Logs générés (auto-créé)
│   ├── server.log           # Logs du serveur GCS
│   └── client.log           # Logs du client drone
├── pki/                     # Structure PKI (généré)
│   ├── ca/                  # Root CA
│   ├── intermediate/        # Intermediate CA
│   ├── endpoint/            # Certificats endpoints
│   └── csr/                 # Certificate Signing Requests
├── openssl-rootca.cnf       # Config OpenSSL Root CA
├── openssl-intermediate.cnf # Config OpenSSL Intermediate CA
├── passphrase.txt           # Passphrase clés (NON COMMITÉ)
├── ca-bundle.crt            # Bundle Root + Intermediate
└── ca-bundle-crl.pem        # Bundle CA + CRL
```

## 🧪 Scénarios de test

### Scénario 1 : Communication normale

```bash
# Terminal 1 : Démarrer le serveur
python3 simulator/server.py

# Terminal 2 : Connecter un drone
python3 simulator/client.py
```

**Résultat attendu** : Connexion réussie, échange de données JSON.

### Scénario 2 : Révocation d'un certificat

```bash
# 1. Révoquer le certificat du drone
./scripts/revoke_certs.sh drone-fr-1

# 2. Régénérer la CRL
./scripts/gen_crl.sh intermediate

# 3. Mettre à jour le bundle CRL
cat ca-bundle.crt pki/ca/crl/rootca.crl.pem pki/intermediate/crl/intermediate.crl.pem > ca-bundle-crl.pem

# 4. Tenter une connexion
python3 simulator/client.py
```

**Résultat attendu** : `Certification Verification Error: certificate revoked`

### Scénario 3 : Vérification manuelle

```bash
# Vérifier un certificat valide
./scripts/verify_cert.sh pki/endpoint/certs/drone-fr-0.crt
# Output: OK

# Vérifier un certificat révoqué
./scripts/verify_cert.sh pki/endpoint/certs/drone-fr-1.crt
# Output: certificate revoked
```

## 🔒 Sécurité

### Bonnes pratiques implémentées

✅ **Hiérarchie CA** : Séparation Root/Intermediate pour limiter l'exposition  
✅ **Permissions strictes** : `chmod 700` sur répertoires privés, `chmod 400` sur clés  
✅ **Authentification mutuelle** : Client et serveur vérifient leurs identités  
✅ **Vérification CRL** : Détection des certificats révoqués  
✅ **Chiffrement fort** : RSA 4096 bits, SHA-256

### ⚠️ Avertissements

- **Passphrase en clair** : `passphrase.txt` est stocké en clair (acceptable pour un lab, pas en production)
- **Pas de HSM** : Les clés privées sont sur disque (utiliser un HSM en production)
- **CRL manuelle** : La régénération des CRL n'est pas automatisée
- **Certificats auto-signés** : Ne pas utiliser en production sans CA publique

### Recommandations production

1. Utiliser un HSM pour stocker les clés privées
2. Automatiser la rotation des CRL (cron job)
3. Implémenter OCSP en complément des CRL
4. Monitorer les expirations de certificats
5. Utiliser des passphrases générées aléatoirement
6. Séparer physiquement la Root CA (offline)

## 📝 Notes

- **Durée de validité** : Certificats valides 365 jours, CRL 30 jours
- **Algorithme** : RSA 4096 bits (Root/Intermediate), SHA-256
- **Extensions** : `serverAuth` pour GCS, `clientAuth` pour drones
- **SAN** : `localhost` et `127.0.0.1` pour les certificats serveur

## � Logs

Le serveur et le client génèrent des logs dans le répertoire `logs/` (créé automatiquement au lancement).

### Fichiers de logs

- **`logs/server.log`** : Connexions entrantes, CN du client, données reçues
- **`logs/client.log`** : Connexion au serveur, CN du serveur, payload envoyé, erreurs TLS

### Format

```
2026-03-11 12:30:00,123 [INFO] SSL context created
2026-03-11 12:30:00,456 [INFO] Server listening on localhost:8443
2026-03-11 12:30:05,789 [INFO] Connection from ('127.0.0.1', 52341) | CN=drone-fr-001
2026-03-11 12:30:05,890 [INFO] Data received from drone-fr-001: {'alt': 1.38, 'long': 38.7, 'Lat': 100.6}
2026-03-11 12:30:05,891 [INFO] Connection closed for drone-fr-001
```

### Consulter les logs

```bash
# Dernières lignes en temps réel
tail -f logs/server.log
tail -f logs/client.log

# Filtrer les erreurs
grep ERROR logs/client.log
```

## �🐛 Dépannage

### Erreur : "Permission denied" sur root-ca.key

```bash
chmod 700 pki/ca/private
chmod 400 pki/ca/private/root-ca.key
```

### Erreur : "cannot lookup how long until the next CRL is issued"

Vérifier que `default_crl_days` est présent dans `openssl-rootca.cnf` et `openssl-intermediate.cnf`.

### Erreur : "certificate revoked" alors que non révoqué

Régénérer les bundles CRL :

```bash
./scripts/gen_crl.sh both
cat ca-bundle.crt pki/ca/crl/rootca.crl.pem pki/intermediate/crl/intermediate.crl.pem > ca-bundle-crl.pem
```

## 📚 Ressources

- [OpenSSL CA Documentation](https://www.openssl.org/docs/man1.1.1/man1/ca.html)
- [RFC 5280 - X.509 PKI](https://datatracker.ietf.org/doc/html/rfc5280)
- [Python SSL Module](https://docs.python.org/3/library/ssl.html)

## 📄 Licence

Projet éducatif - Libre d'utilisation pour l'apprentissage.