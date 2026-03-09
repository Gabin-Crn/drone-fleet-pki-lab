import os 
import socket
import ssl 
import json

def create_server(host="localhost", port=8443):
    
    ctx = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH) # On crée un contexte SSL
    ctx.load_cert_chain(certfile="pki/endpoint/certs/GCS-1-0.crt", keyfile="pki/endpoint/private/GCS-1-0.key") # On charge le certificat et sa clé 
    ctx.verify_mode = ssl.CERT_REQUIRED
    ctx.load_verify_locations("ca-bundle.crt")
    message = b''

    with socket.create_server((host, port), backlog=10, reuse_port=True) as server:
        server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server.listen(10)
        server = ctx.wrap_socket(server, server_side=True)
        print(f"Server listening on {host}:{port}")
        while True:
            conn, addr = server.accept()
            print(f"Connection from {addr}")
            conn.send(b"Hello World")
            while True:
                tmp = conn.recv(1024)
                if not tmp:
                    break
                message += tmp
                
            message = json.loads(message.decode("utf-8"))
            print(message)
            conn.close()


if __name__ == "__main__":
    create_server()
