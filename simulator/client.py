import os 
import socket
import ssl
import json
import logging
import argparse
import sys

os.makedirs("logs", exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler("logs/client.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("Drone-Client")

def create_client(host="localhost", port=8443, certfile="pki/endpoint/certs/drone-fr-1.crt", keyfile="pki/endpoint/private/drone-fr-1.key", passphrase=None):
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)

    ctx.load_cert_chain(certfile=certfile, keyfile=keyfile, password=passphrase)
    logger.info(f"Cert: {certfile} | Key: {keyfile}")

    ctx.load_verify_locations("ca-bundle-crl.pem") # Verification Chain + CRL 
    ctx.check_hostname = True # Verification si on a le même hostname
    ctx.verify_flags = ssl.VERIFY_CRL_CHECK_LEAF
    logger.info("SSL context created")


    payload = {
        "alt" : 1.38,
        "long" : 38.7,
        "Lat": 100.6
    }
    json_pay = json.dumps(payload).encode("utf-8")
    
    with socket.create_connection((host,port)) as sock: # Socket TCP "normal
        try: 
            with ctx.wrap_socket(sock, server_hostname=host) as tls_sock: # Socket TLS
                peer_cert = tls_sock.getpeercert()
                server_cn = dict(x[0] for x in peer_cert["subject"])["commonName"]
                logger.info(f"Connected to {host}:{port} | Server CN={server_cn}")
                tls_sock.sendall(json_pay)
                logger.info(f"Payload sent: {payload}")
                response = tls_sock.recv(1024)
                logger.info(f"Response: {response.decode()}")
        except ssl.SSLCertVerificationError as e:
            logger.error(f"Certification Verification Error: {e.verify_message}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Drone TLS Client")
    parser.add_argument("-c", "--cert", default="pki/endpoint/certs/drone-fr-1.crt", help="Path to drone certificate")
    parser.add_argument("-k", "--key", default="pki/endpoint/private/drone-fr-1.key", help="Path to drone private key")
    parser.add_argument("-p", "--passphrase", default=None, help="Path to passphrase file")
    args = parser.parse_args()

    passphrase = None
    if args.passphrase:
        with open(args.passphrase, "r") as f:
            passphrase = f.read().strip().encode()

    create_client(certfile=args.cert, keyfile=args.key, passphrase=passphrase)