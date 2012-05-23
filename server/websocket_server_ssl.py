import tornado.httpserver
import tornado.ioloop
import tornado.web
from websocket_server import WebSocketHandler, FileHandler

application = tornado.web.Application([
    (r"/websocket", WebSocketHandler),
    (r"/(.*)", FileHandler),
])

def main():
    http_server = tornado.httpserver.HTTPServer(application, ssl_options={ 
        "certfile": "localhost.crt", 
        "keyfile": "localhost.key", 
    })
    http_server.listen(8443)
    tornado.ioloop.IOLoop.instance().start()

if __name__ == "__main__":
    main()
