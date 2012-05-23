This folder contains server scripts for development use.

These Python scripts require the [Tornado Web Server] library.  
Tested in Python version 2.7.1


## socket-policy-file-server.py

Runs a Flash socket policy file server on port `843`.  
This is required (even within the same domain) to enable flash to connect to a WebSocket server.


## websocket-server.py

Runs a HTTP file server and a WebSocket server on port `9000`  
Server root is mounted to `PROJECT_ROOT/` to serve static files.  
WebSocket entry point is mounted to `/websocket`.


[Tornado Web Server]: http://www.tornadoweb.org/
