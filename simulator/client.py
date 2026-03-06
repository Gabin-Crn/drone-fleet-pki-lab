import os 
import socket
import ssl


def create_client(host="localhost", port=8443):
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)

    ctx.load_cert_chain(certfile="pki/endpoint/certs/drone-fr-1.crt", keyfile="pki/endpoint/private/drone-fr-1.key")

    ctx.load_verify_locations("ca-bundle.crt")
    ctx.check_hostname = True

    with socket.create_connection((host,port)) as sock:
        with ctx.wrap_socket(sock, server_hostname=host) as tls_sock:
            print(f"Connecté à {host}:{port}")
            tls_sock.sendall(b"Hello mTLS")
            response = tls_sock.recv(1024)
            print(f"Réponse : {response.decode()}")

if __name__ == "__main__":
    create_client()