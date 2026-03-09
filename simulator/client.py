import os 
import socket
import ssl
import json


def create_client(host="localhost", port=8443):
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)

    ctx.load_cert_chain(certfile="pki/endpoint/certs/drone-fr-1.crt", keyfile="pki/endpoint/private/drone-fr-1.key")

    ctx.load_verify_locations("ca-bundle-crl.pem") # Verification Chain + CRL 
    ctx.check_hostname = True # Verification si on a le même hostname
    ctx.verify_flags = ssl.VERIFY_CRL_CHECK_LEAF


    payload = {
        "alt" : 1.38,
        "long" : 38.7,
        "Lat": 100.6
    }
    json_pay = json.dumps(payload).encode("utf-8")
    
    with socket.create_connection((host,port)) as sock: # Socket TCP "normal
        try: 
            with ctx.wrap_socket(sock, server_hostname=host) as tls_sock: # Socket TLS
                print(f"Connecté à {host}:{port}")
                tls_sock.sendall(json_pay)
                response = tls_sock.recv(1024)
                print(f"Réponse : {response.decode()}")
        except ssl.SSLCertVerificationError as e:
            print("Certification Verification Error :", e.verify_message)


if __name__ == "__main__":
    create_client()