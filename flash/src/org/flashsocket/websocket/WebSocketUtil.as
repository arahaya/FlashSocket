package org.flashsocket.websocket {
	import flash.utils.ByteArray;
	import org.flashsocket.utils.Debugger;
	
	public class WebSocketUtil {
		
		public static function parseUrl(url:String):Object {
			// Regexp pattern from http://blog.stevenlevithan.com/archives/parseuri
			var m:Array = /^(?:(?![^:@]+:[^:@\/]*@)([^:\/?#.]+):)?(?:\/\/)?(?:(?:(?:(?:[^:@]*)(?::(?:[^:@]*))?)?@)?([^:\/?#]*)(?::(\d*))?)(?:((?:\/(?:[^?#](?![^?#\/]*\.[^?#\/.]+(?:[?#]|$)))*\/?)?(?:[^?#\/]*))(?:\?([^#]*))?(?:#(.*))?)/.exec(url),
				scheme:String = m[1],
				host:String = m[2],
				port:String = m[3],
				path:String = m[4],
				query:String = m[5],
				fragment:String = m[6],
				ret:Object = {};
			
			// 1. If the url string is not an absolute URL, then fail this 
			//    algorithm.
			
			if (!host) {
				throw new SyntaxError('Invalid url for WebSocket ' + url);
			}
			
			// 2. Resolve the url (as per Resolving URLs) string, with the URL 
			//    character encoding set to UTF-8. [RFC3629]
			//    Note: It doesn't matter what it is resolved relative to, 
			//    since we already know it is an absolute URL at this point.
			
			// 3. If url does not have a <scheme> component whose value, when 
			//    converted to ASCII lowercase, is either "ws" or "wss", then 
			//    fail this algorithm.
			
			if (!/^wss?$/i.test(scheme)) {
				throw new SyntaxError('Wrong url scheme for WebSocket ' + url);
			}

			// 4. If url has a <fragment> component, then fail this algorithm.
			
			if (fragment) {
				throw new SyntaxError('URL has fragment component ' + url);
			}

			// 5. If the <scheme> component of url is "ws", set secure to 
			//    false; otherwise, the <scheme> component is "wss", set secure 
			//    to true.
			
			ret.secure = scheme.toLowerCase() === 'ws' ? false : true;

			// 6. Let host be the value of the <host> component of url, 
			//    converted to ASCII lowercase.
			
			ret.host = host.toLowerCase();

			// 7. If url has a <port> component, then let port be that 
			//    component's value; otherwise, there is no explicit port.
			// 8. If there is no explicit port, then: if secure is false, let 
			//    port be 80, otherwise let port be 443.
			
			if (port === null) {
				ret.port = ret.secure ? 443 : 80;
			} else {
				ret.port = uint(port);
			}

			// 9. Let resource name be the value of the <path> component (which 
			//    might be empty) of url.
			// 10. If resource name is the empty string, set it to a single 
			//    character U+002F SOLIDUS (/).
			
			ret.resource = path || '/';

			// 11. If url has a <query> component, then append a single U+003F 
			//    QUESTION MARK character (?) to resource name, followed by the 
			//    value of the <query> component.
			
			if (query) {
				ret.resource += '?' + query;
			}

			// 12. Return host, port, resource name, and secure.
			
			return ret;
		}
		
		public static function randomBytes(size:int):ByteArray {
			var bytes:ByteArray = new ByteArray();
			var i:int;
			
			for (i = 0; i < size; i++) {
				bytes.writeByte(randomByte());
			}
			
			return bytes;
		}
		
		public static function randomByte():int {
			return randomInt(0, 255);
		}
		
		public static function randomInt(min:int = int.MIN_VALUE, max:int = int.MAX_VALUE):int {
			return Math.floor(Math.random() * (max - min + 1)) + min;
		}
		
		/**
		 * Read ByteArray until "\n" char and return a new String
		 * with line breaks trimed off
		 * @param	bytes
		 * @return  line
		 */
		public static function readLine(bytes:ByteArray):String {
			var read:int = -1; // Bytes to read
			var offset:int = bytes.position;
			var length:int = bytes.length;
			var i:int;
			var next:int;
			var line:String;
			
			// \r => 13
			// \n => 10
			
			for (i = offset; i < length; i++) {
				if (bytes[i] === 10) {
					// found "\n"
					next = i + 1;
					read = i - offset;
					
					if (i > offset && bytes[i - 1] === 13) {
						// found "\r\n"
						read -= 1;
					}
					
					break;
				}
			}
			
			if (read === -1) {
				// not found, read remaining bytes
				read = length - offset;
				next = length;
			}
			
			line = bytes.readUTFBytes(read);
			
			// Set position right after the found "\n"
			bytes.position = next;
			return line;
		}
	}
}