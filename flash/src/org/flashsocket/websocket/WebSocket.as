package org.flashsocket.websocket {
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;
	import mx.utils.StringUtil;
	import org.flashsocket.utils.Debugger;
	
	/**
	 * The WebSocket API
	 * W3C Candidate Recommendation 08 December 2011
	 * http://www.w3.org/TR/websockets/
	 */
	[Event(name = "open", type = "flash.events.Event")]
	[Event(name = "error", type = "flash.events.Event")]
	[Event(name = "close", type = "org.flashsocket.websocket.events.CloseEvent")]
	[Event(name = "message", type = "org.flashsocket.websocket.events.MessageEvent")]
	[Event(name = "exception", type = "org.flashsocket.websocket.events.ExceptionEvent")]
	[Event(name = "readyStateChange", type = "org.flashsocket.websocket.events.ReadyStateEvent")]
	[Event(name = "bufferEmpty", type = "flash.events.Event")]

	public class WebSocket extends EventDispatcher {
		private var _onopen:Function;
		private var _onerror:Function;
		private var _onclose:Function;
		private var _onmessage:Function;
		private var _onexception:Function;
		private var _handler:WebSocketClientHandler;
		
		// Constructor
		// ------------------------------------------------------------
		public function WebSocket(url:String, protocols:* = undefined, origin:String = "null", cookie:String = "") {
			// When the WebSocket() constructor is invoked, the UA must run these steps:
			
			// 1. Parse a WebSocket URL's components from the url argument, to
			//    obtain host, port, resource name, and secure. If this fails, 
			//    throw a SyntaxError exception and abort these steps.
			
			// Eliminate leading/trailing whitespace
			url = StringUtil.trim(url);
			// Encode if necessary
			url = (decodeURI(url) === url) ? encodeURI(url) : url;
			
			var parsedUrl:Object = WebSocketUtil.parseUrl(url),
				secure:Boolean = parsedUrl.secure,
				host:String = parsedUrl.host,
				port:uint = parsedUrl.port,
				resource:String = parsedUrl.resource;
			
			// 2. If secure is false but the origin of the entry script has a
			//    scheme component that is itself a secure protocol, e.g. 
			//    HTTPS, then throw a SecurityError exception.
			
			if (!secure && /^https:/i.test(origin)) {
				// Opera11.62 and Chrome18 seem to allow this..
				throw new SecurityError("Protocol does not match origin protocol");
			}
			
			// SKIP
			// 3. If port is a port to which the user agent is configured to
			//    block access, then throw a SecurityError exception. (User 
			//    agents typically block access to well-known ports like SMTP.)
			//    Access to ports 80 and 443 should not be blocked, including 
			//    the unlikely cases when secure is false but port is 443 or 
			//    secure is true but port is 80.
			
			// 4. If protocols is absent, let protocols be an empty array.
			//    Otherwise, if protocols is present and a string, let
			//    protocols instead be an array consisting of just that string.

			if (protocols === undefined) {
				protocols = [];
			} else if (!(protocols is Array)) {
				protocols = [protocols];
			}
			
			// 5. If any of the values in protocols occur more than once or 
			//    otherwise fail to match the requirements for elements that 
			//    comprise the value of Sec-WebSocket-Protocol header fields as 
			//    defined by the WebSocket protocol specification, then throw a 
			//    SyntaxError exception and abort these steps.
			
			protocols.forEach(function (element:*, index:int, arr:Array):void {
				element = String(element);
				
				if (arr.indexOf(element) !== index) {
					throw new SyntaxError("WebSocket protocols contain duplicates: '" + element + "'");
				}
				
				// TODO: Not really sure about the regex pattern
				// document says it's described in http://tools.ietf.org/html/rfc2616
				if (!/^[\w\-\.]+$/.test(element)) {
					throw new SyntaxError("Wrong protocol for WebSocket '" + element + "'");
				}
				
				arr[index] = element;
			});
			
			// 6. Let origin be the ASCII serialization of the origin of the 
			//    entry script, converted to ASCII lowercase.
			
			origin = String(origin).toLowerCase();
			
			// 7. Return a new WebSocket object, and continue these steps in 
			//    the background (without blocking scripts).
			// 8. Establish a WebSocket connection given the set (host, port, 
			//    resource name, secure), along with the protocols list, an 
			//    empty list for the extensions, and origin. The headers to 
			//    send appropriate cookies must be a Cookie header whose value 
			//    is the cookie-string computed from the user's cookie store 
			//    and the URL url; for these purposes this is not a "non-HTTP" 
			//    API.
			
			_handler = new WebSocketClientHandler(host, port, resource, secure, protocols, [], origin, cookie);
			_handler.addEventListener("open", dispatchEvent);
			_handler.addEventListener("error", dispatchEvent);
			_handler.addEventListener("close", dispatchEvent);
			_handler.addEventListener("message", dispatchEvent);
			_handler.addEventListener("exception", dispatchEvent);
			_handler.addEventListener("readyStateChange", dispatchEvent);
			_handler.addEventListener("bufferEmpty", dispatchEvent);
		}
		
		// Ready state
		// ------------------------------------------------------------
		public static const CONNECTING:int = 0;
		public static const OPEN:int = 1;
		public static const CLOSING:int = 2;
		public static const CLOSED:int = 3;
		
		public function get url():String {
			return _handler.url;
		}
		
		public function get readyState():int {
			return _handler.readyState;
		}
		
		public function get bufferedAmount():uint {
			return _handler.bufferedAmount;
		}
		
		// Networking
		// ------------------------------------------------------------
		public function set onopen(handler:Function):void {
			if (_onopen is Function) {
				removeEventListener('open', _onopen);
			}
			
			_onopen = handler;
			
			if (_onopen is Function) {
				addEventListener('open', _onopen);
			}
		}
		
		public function get onopen():Function {
			return _onopen;
		}
		
		public function set onerror(handler:Function):void {
			if (_onerror is Function) {
				removeEventListener('error', _onerror);
			}
			
			_onerror = handler;
			
			if (_onerror is Function) {
				addEventListener('error', _onerror);
			}
		}
		
		public function get onerror():Function {
			return _onopen;
		}
		
		public function set onclose(handler:Function):void {
			if (_onclose is Function) {
				removeEventListener('close', _onclose);
			}
			
			_onclose = handler;
			
			if (_onclose is Function) {
				addEventListener('close', _onclose);
			}
		}
		
		public function get onclose():Function {
			return _onclose;
		}
		
		public function get extensions():String {
			return _handler.extensions;
		}
		
		public function get protocol():String {
			return _handler.protocol;
		}
		
		public function close(code:int = -1, reason:String = ""):void {
			if (code !== -1) {
				// 1. If the method's first argument is present but is not an integer equal to 1000 or in the range 3000 
				//    to 4999, throw an InvalidAccessError exception and abort these steps.
				
				if (code !== 1000 && (code < 3000 || code > 4999)) {
					throw new InvalidAccessError("Invalid code '" + code + "'");
				}
				
				if (reason !== "") {
					// TODO
					// 2. If the method's second argument has any unpaired surrogates, then throw a SyntaxError exception 
					//    and abort these steps.
					
					// 3. If the method's second argument is present, then let reason be the result of encoding that 
					//    argument as UTF-8. If reason is longer than 123 bytes, then throw a SyntaxError exception and 
					//    abort these steps.
					
					var reasonBytes:ByteArray = new ByteArray();
					reasonBytes.writeUTFBytes(reason);
					
					if (reasonBytes.length > 123) {
						throw new SyntaxError("Invalid reason '" + reason + "'");
					}
				}
			}
			
			_handler.close(code, reason);
		}
		
		// Messaging
		// ------------------------------------------------------------
		public function set onmessage(handler:Function):void {
			if (_onmessage is Function) {
				removeEventListener('message', _onmessage);
			}
			
			_onmessage = handler;
			
			if (_onmessage is Function) {
				addEventListener('message', _onmessage);
			}
		}
		
		public function get onmessage():Function {
			return _onmessage;
		}
		
		public function get binaryType():String {
			return "bytearray";
		}
		
		public function set binaryType(value:String):void {
			if (value !== "bytearray") {
				throw new SyntaxError("binaryType '" + value + "' is not supported");
			}
		}
		
		public function send(...args):void {
			if (args.length < 1) {
				throw new SyntaxError("Not enough arguments");
			}
			
			if (readyState === CONNECTING) {
				throw new InvalidStateError("Data is sent before the connection is established.");
			}
			
			_handler.send(args[0]);
		}
		
		// Exception handling (Unspecified API)
		// ------------------------------------------------------------
		public function set onexception(handler:Function):void {
			if (_onexception is Function) {
				removeEventListener('message', _onexception);
			}
			
			_onexception = handler;
			
			if (_onexception is Function) {
				addEventListener('exception', _onexception);
			}
		}
		
		public function get onexception():Function {
			return _onexception;
		}
	}
}