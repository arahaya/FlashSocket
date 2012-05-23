import tornado.ioloop
import tornado.netutil

POLICY_DATA = """<?xml version="1.0"?>
<cross-domain-policy>
    <site-control permitted-cross-domain-policies="all"/>
    <allow-access-from domain="*" to-ports="*" />
</cross-domain-policy>"""

class SocketPolicyFileServer(tornado.netutil.TCPServer):
    def handle_stream(self, stream, address):
        RequestHandler(stream)

class RequestHandler(object):
    def __init__(self, stream):
        self.stream = stream
        self.stream.read_bytes(22, self._on_read)
    
    def _on_read(self, data):
        if data == "<policy-file-request/>":
            self.stream.write(POLICY_DATA + '\0', self.stream.close)
        else:
            self.stream.close()

def main():
    policy_server = SocketPolicyFileServer()
    policy_server.listen(843)
    tornado.ioloop.IOLoop.instance().start()

if __name__ == '__main__':
    main()