import argparse
import select
import socket
import socketserver
import sys
import threading

import paramiko


def parse_args():
    parser = argparse.ArgumentParser(description="Local port forward over SSH.")
    parser.add_argument("--ssh-host", required=True)
    parser.add_argument("--ssh-port", type=int, default=22)
    parser.add_argument("--ssh-user", required=True)
    parser.add_argument("--ssh-password", required=True)
    parser.add_argument("--remote-host", default="127.0.0.1")
    parser.add_argument("--remote-port", type=int, required=True)
    parser.add_argument("--local-host", default="127.0.0.1")
    parser.add_argument("--local-port", type=int, required=True)
    return parser.parse_args()


class ForwardHandler(socketserver.BaseRequestHandler):
    ssh_transport = None
    remote_host = None
    remote_port = None

    def handle(self):
        try:
            channel = self.ssh_transport.open_channel(
                "direct-tcpip",
                (self.remote_host, self.remote_port),
                self.request.getpeername(),
            )
        except Exception as exc:
            print(f"[ERROR] Tunnel open failed: {exc}", flush=True)
            return

        if channel is None:
            print("[ERROR] SSH server refused the tunnel request", flush=True)
            return

        try:
            while True:
                readable, _, _ = select.select([self.request, channel], [], [])
                if self.request in readable:
                    data = self.request.recv(32768)
                    if not data:
                        break
                    channel.sendall(data)
                if channel in readable:
                    data = channel.recv(32768)
                    if not data:
                        break
                    self.request.sendall(data)
        finally:
            channel.close()
            self.request.close()


class ThreadedTCPServer(socketserver.ThreadingTCPServer):
    daemon_threads = True
    allow_reuse_address = True


def main():
    args = parse_args()

    ssh_client = paramiko.SSHClient()
    ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh_client.connect(
        args.ssh_host,
        port=args.ssh_port,
        username=args.ssh_user,
        password=args.ssh_password,
    )
    transport = ssh_client.get_transport()

    ForwardHandler.ssh_transport = transport
    ForwardHandler.remote_host = args.remote_host
    ForwardHandler.remote_port = args.remote_port

    server = ThreadedTCPServer((args.local_host, args.local_port), ForwardHandler)
    print(
        f"[INFO] Tunnel ready: http://{args.local_host}:{args.local_port} -> {args.remote_host}:{args.remote_port}",
        flush=True,
    )

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.shutdown()
        server.server_close()
        ssh_client.close()


if __name__ == "__main__":
    sys.exit(main())
