FlashSocket.js
=========================

FlashSocket is a JavaScript/Flash library which adds WebSocket support to old browsers such as IE6.

This project is aimed to enable WebSocket in old browsers while maintaining a decent performance.  
**Currently all features are implemented but still in a beta state**.

If IE6 support is not required I highly recommend you use one of the libraries listed below. They are more stable and well maintained.  
[https://github.com/Modernizr/Modernizr/wiki/HTML5-Cross-browser-Polyfills](https://github.com/Modernizr/Modernizr/wiki/HTML5-Cross-browser-Polyfills)


Example
-------------------------

    <!DOCTYPE html>
    <html>
    <script src="swfobject.js"></script>
    <script src="flashsocket.js"></script>
    <script>
    var socket = new FlashSocket("ws://localhost:8080/websocket");

    socket.onopen = function (e) {
        console.log("Socket opened");
        socket.send("hello world");
    };
    socket.onmessage = function (e) {
        console.log("Recieved message: " + e.data);
        socket.close();
    };
    socket.onclose = function (e) {
        console.log("Socket closed");
    };
    </script>
    </html>


Client Requirements
-------------------------

Adobe Flash Player 9 or above.


Tested browsers
-------------------------

* Internet Explorer: 6 and 9
* Opera 11.62
* Firefox 3.6.16
* Safari 5.1.5 (Win7)


Dependencies
-------------------------

[SWFObject 2.2][SWFObject]


[SWFObject]: http://code.google.com/p/swfobject/