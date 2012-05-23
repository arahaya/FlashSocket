import os.path
import mimetypes
import tornado.httpserver
import tornado.ioloop
import tornado.web
import tornado.websocket

ROOT_PATH = '../'

class FileHandler(tornado.web.RequestHandler):
    def get(self, path):
        path = os.path.join(ROOT_PATH, path)
        
        if os.path.isdir(path):
            path = os.path.join(path, 'index.html')
        
        if not os.path.exists(path):
            raise tornado.web.HTTPError(404)
        
        mime_type, encoding = mimetypes.guess_type(path)
        if mime_type:
            self.set_header("Content-Type", mime_type)
        
        file = open(path, "rb")
        try:
            self.write(file.read())
        finally:
            file.close()

class WebSocketHandler(tornado.websocket.WebSocketHandler):
    def open(self):
        print "WebSocket opened"

    def on_message(self, message):
        print "Recieved: %s" % message
        self.write_message(u"You said: " + message)

    def on_close(self):
        print "WebSocket closed"

application = tornado.web.Application([
    (r"/websocket", WebSocketHandler),
    (r"/(.*)", FileHandler),
])

def main():
    http_server = tornado.httpserver.HTTPServer(application)
    http_server.listen(8080)
    tornado.ioloop.IOLoop.instance().start()

if __name__ == "__main__":
    main()
