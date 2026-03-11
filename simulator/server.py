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
        logging.FileHandler("logs/server.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("GCS-Server")

def create_server(host="localhost", port=8443, certfile="pki/endpoint/certs/GCS-0.crt", keyfile="pki/endpoint/private/GCS-0.key", passphrase=None, single=False):
    
    ctx = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH) # On crée un contexte SSL
    ctx.load_cert_chain(certfile=certfile, keyfile=keyfile, password=passphrase) # On charge le certificat et sa clé
    logger.info(f"Cert: {certfile} | Key: {keyfile}")
    ctx.verify_mode = ssl.CERT_REQUIRED
    ctx.load_verify_locations("ca-bundle-crl.pem") # Verification Chain + CRL 
    ctx.verify_flags = ssl.VERIFY_CRL_CHECK_LEAF
    logger.info("SSL context created")
    message = b''

    with socket.create_server((host, port), backlog=10, reuse_port=True) as server:
        server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server.listen(10)
        server = ctx.wrap_socket(server, server_side=True)
        logger.info(f"Server listening on {host}:{port}")
        while True:
            conn, addr = server.accept()
            peer_cert = conn.getpeercert()
            cn = dict(x[0] for x in peer_cert["subject"])["commonName"]
            logger.info(f"Connection from {addr} | CN={cn}")
            conn.send(b"Hello World")
            while True:
                tmp = conn.recv(1024)
                if not tmp:
                    break
                message += tmp

            message = json.loads(message.decode("utf-8"))
            logger.info(f"Data received from {cn}: {message}")
            conn.close()
            logger.info(f"Connection closed for {cn}")
            if single:
                break
            


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="GCS TLS Server")
    parser.add_argument("-c", "--cert", default="pki/endpoint/certs/GCS-0.crt", help="Path to server certificate")
    parser.add_argument("-k", "--key", default="pki/endpoint/private/GCS-0.key", help="Path to server private key")
    parser.add_argument("-p", "--passphrase", default=None, help="Path to passphrase file")
    parser.add_argument("-s", "--single", action="store_true", help="Accept one connection then exit")
    args = parser.parse_args()

    passphrase = None
    if args.passphrase:
        with open(args.passphrase, "r") as f:
            passphrase = f.read().strip().encode()

    create_server(certfile=args.cert, keyfile=args.key, passphrase=passphrase, single=args.single)
