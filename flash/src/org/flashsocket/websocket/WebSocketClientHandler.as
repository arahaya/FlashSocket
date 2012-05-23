package org.flashsocket.websocket {
	import com.hurlant.crypto.tls.TLSConfig;
	import com.hurlant.crypto.tls.TLSEngine;
	import com.hurlant.crypto.tls.TLSSecurityParameters;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;
	import flash.utils.clearTimeout;
	import flash.utils.Timer;
	import com.hurlant.crypto.tls.TLSSocket;
	import org.flashsocket.utils.Base64;
	import org.flashsocket.utils.Debugger;
	import org.flashsocket.utils.SHA1;
	import org.flashsocket.utils.StringUtil;
	import org.flashsocket.websocket.events.ReadyStateEvent;
	import org.flashsocket.websocket.events.CloseEvent;
	import org.flashsocket.websocket.events.ExceptionEvent;
	import org.flashsocket.websocket.events.MessageEvent;
	
	/**
	 * Websocket protocol v13 (RFC 6455 aka HyBi-17)
	 */
	[Event(name = "open", type = "flash.events.Event")]
	[Event(name = "error", type = "flash.events.Event")]
	[Event(name = "close", type = "org.flashsocket.websocket.events.CloseEvent")]
	[Event(name = "message", type = "org.flashsocket.websocket.events.MessageEvent")]
	[Event(name = "exception", type = "org.flashsocket.websocket.events.ExceptionEvent")]
	
	public class WebSocketClientHandler extends EventDispatcher {
		public static const WEBSOCKET_VERSION:String = "13";
		public static const MAGIC_GUID:String = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';
		
		public static const OPCODE_CONT:int   = 0x0;
		public static const OPCODE_TEXT:int   = 0x1;
		public static const OPCODE_BINARY:int = 0x2;
		public static const OPCODE_CLOSE:int  = 0x8;
		public static const OPCODE_PING:int   = 0x9;
		public static const OPCODE_PONG:int   = 0xA;
		
		public static const STATE_CONNECTING:int = 0;
		public static const STATE_OPEN:int       = 1;
		public static const STATE_CLOSING:int    = 2;
		public static const STATE_CLOSED:int     = 3;
		
		public static const STATUS_NORMAL_CLOSURE:int         = 1000;
		public static const STATUS_GOING_AWAY:int             = 1001;
		public static const STATUS_PROTOCOL_ERROR:int         = 1002;
		public static const STATUS_CANNOT_ACCEPT:int          = 1003;
		public static const STATUS_NO_CODE:int                = 1005;
		public static const STATUS_CLOSED_ABNORMALLY:int      = 1006;
		public static const STATUS_MESSAGE_NOT_CONSISTENT:int = 1007;
		public static const STATUS_VIOLATES_POLICY:int        = 1008;
		public static const STATUS_MESSAGE_TOO_BIG:int        = 1009;
		public static const STATUS_MISSING_EXTENSION:int      = 1010;
		public static const STATUS_UNEXPECTED_CONDITION:int   = 1011;
		public static const STATUS_TLS_FAILURE:int            = 1015;
		
		private var _socket:Socket;
		private var _expectedChallengeResponse:String;
		private var _fragment:WebSocketFrame;
		private var _emptyBufferTimeout:int;
		private var _closingHandshakeTimeout:int;
		
		private var _secure:Boolean;
		private var _host:String;
		private var _port:uint;
		private var _resource:String;
		private var _hostport:String; // if not_default_port then host:port else host
		private var _origin:String;
		private var _protocols:Array = [];
		private var _extensions:Array = [];
		private var _readyState:int = STATE_CONNECTING;
		private var _bufferedAmount:uint = 0;
		private var _sendedAmount:uint = 0;
		
		private function setReadyState(state:int):void {
			Debugger.log("setReadyState", state);
			
			if (state !== _readyState) {
				_readyState = state;
				dispatchEvent(new ReadyStateEvent("readyStateChange", state));
			}
		}
		
		private function sendOpeningHandshake():void {
			Debugger.log("sendOpeningHandshake");
			
			var key:String = Base64.encodeBytes(WebSocketUtil.randomBytes(16));
			var headers:Array;
			
			_expectedChallengeResponse = Base64.encode(SHA1.hash(key + MAGIC_GUID)).toLowerCase();
			
			headers = [];
			headers.push('GET ' + _resource + ' HTTP/1.1');
			headers.push('Upgrade: websocket');
			headers.push('Connection: Upgrade');
			headers.push('Host: ' + _hostport);
			headers.push('Origin: ' + _origin);
			if (_protocols) {
				headers.push('Sec-WebSocket-Protocol: ' + _protocols.join(", "));
			}
			headers.push('Sec-WebSocket-Key: ' + key);
			headers.push('Sec-WebSocket-Version: ' + WEBSOCKET_VERSION);
			headers.push('');
			headers.push('');
			
			_socket.writeUTFBytes(headers.join('\r\n'));
			_socket.flush();
		}
		
		private function readOpeningHandshake(buffer:ByteArray):void {
			Debugger.log("readOpeningHandshake");
			
			var line:String;
			var matcher:Object;
			var i:int;
			var l:int;
			
			// Parse Response code
			line = WebSocketUtil.readLine(buffer);
			matcher = /\s(\d+)\s/.exec(line);
			var responseCode:int;
			
			if (matcher === null) {
				abort("No response code found: " + line);
			}
			
			responseCode = int(matcher[1]);
			
			if (responseCode !== 101) {
				abort("Unexpected response code: " + responseCode);
			}
			
			// Parse remaining headers
			var headers:Object = { };
			var key:String;
			var value:String;
			
			while ((line = WebSocketUtil.readLine(buffer)) !== "") {
				matcher = /^([^:]+):\s*([^\s]*)$/.exec(line);
				
				if (matcher !== null) {
					key = matcher[1].toLowerCase();
					value = matcher[2].toLowerCase();
					
					// Only use the first found value
					if (headers[key] === undefined) {
						headers[key] = value;
					}
				}
			}
			
			// Check for required headers
			if (headers['upgrade'] === undefined) {
				abort("'Upgrade' header is missing");
			} else if (headers['connection'] === undefined) {
				abort("'Connection' header is missing");
			} else if (headers['sec-websocket-accept'] === undefined) {
				abort("'Sec-WebSocket-Accept' header is missing");
			}
			
			// Check for required values
			if (headers['upgrade'] !== 'websocket') {
				abort("'Upgrade' header value is not 'WebSocket'");
			} else if (headers['connection'] !== 'upgrade') {
				abort("'Connection' header value is not 'Upgrade'");
			} else if (headers['sec-websocket-accept'] !== _expectedChallengeResponse) {
				abort("Sec-WebSocket-Accept mismatch");
			}
			
			// SubProtocols
			if (headers['sec-websocket-protocol']) {
				var subprotocols:Array = headers['sec-websocket-protocol'].split(",");
				
				_protocols = subprotocols.map(function (element:*, index:int, arr:Array):void {
					if (_protocols.indexOf(element) === -1) {
						abort("'Sec-WebSocket-Protocol' indicates an unknown subprotocol '" + element + "'");
					}
				});
			}
			
			// TODO: Handle Sec-WebSocket-Extensions header
		}
		
		private function sendClosingHandshake(code:int = -1, reason:String = ""):void {
			Debugger.log("sendClosingHandshake", code, reason);
			
			// 4. Run the first matching steps from the following list:
			// 4.1 If the readyState attribute is in the CLOSING (2) or CLOSED (3) state
			
			if (_readyState === STATE_CLOSING || _readyState === STATE_CLOSED) {
				// Do nothing.
				// Note: The connection is already closing or is already closed. If it has not already, a close event will 
				//       eventually fire.
				return;
			}
			
			// 4.2 If the WebSocket connection is not yet established
			
			if (_readyState === STATE_CONNECTING) {
				// Fail the WebSocket connection and set the readyState attribute's value to CLOSING (2).
				// Note: The start the WebSocket closing handshake algorithm eventually invokes the close the WebSocket 
				//       connection algorithm, which then establishes that the WebSocket connection is closed, which fires 
				//       the close event.
				
				setReadyState(STATE_CLOSING);
				abort("WebSocket is closed before the connection is established.");
			}
			
			// 4.3 If the WebSocket closing handshake has not yet been started
			
			if (_readyState === STATE_OPEN) {
				// Start the WebSocket closing handshake and set the readyState attribute's value to CLOSING (2).
				
				setReadyState(STATE_CLOSING);
				
				// If the first argument is present, then the status code to use in the WebSocket Close message must be 
				// the integer given by the first argument.
				// If the second argument is also present, then reason must be provided in the Close message after the 
				// status code.
				
				var frame:WebSocketFrame = new WebSocketFrame(OPCODE_CLOSE, true, 0, null);
				
				// If the first argument is present, then the status code to use in the WebSocket Close message must be 
				// the integer given by the first argument.
				
				if (code !== -1) {
					frame.payload.writeShort(code);
					
					// If the second argument is also present, then reason must be provided in the Close message after the 
                    // status code.
					
					if (reason !== "") {
						frame.payload.writeUTFBytes(reason);
					}
				}
				
				sendFrame(frame);
				
				// Set a timer to fail the closing handshake if the server doesn't respond
				
				_closingHandshakeTimeout = setTimeout(closeConnection, 20000);
				
				// Note: The start the WebSocket closing handshake algorithm eventually invokes the close the WebSocket 
				//       connection algorithm, which then establishes that the WebSocket connection is closed, which fires 
				//       the close event.
			}
		}
		
		private function sendFrame(frame:WebSocketFrame):void {
			Debugger.log("sendFrame", frame.opcode);
			
			if (_readyState === STATE_CLOSED) {
				return;
			}
			
			var payload:ByteArray = frame.payload;
			var payloadLength:uint = payload.length;
			var header:ByteArray = new ByteArray();
			var body:ByteArray = new ByteArray();
			var mask:ByteArray;
			var i:uint;
			
			// FIN: 1 bit
			// RSV1, RSV2, RSV3: 1 bit each
			// Opcode: 4 bits
			header.writeByte((frame.finalFragment ? 0x80 : 0x00) | (frame.rsv << 4) | frame.opcode);
			
			// Mask: 1 bit
			// Payload length: 7 bits, 7+16 bits, or 7+64 bits
			if (payloadLength <= 125) {
				header.writeByte(0x80 | payloadLength);
			} else if (payloadLength <= 0xFFFF) {
				header.writeByte(0x80 | 126);
				header.writeShort(payloadLength);
			} else if (payloadLength <= 0xFFFFFFFF) {
				header.writeByte(0x80 | 127);
				// 64 bit Long
				header.writeUnsignedInt(0);
				header.writeUnsignedInt(payloadLength);
			} else {
				// Can't handle a message larger than 0xFFFFFFFF
				abort("Payload length too long");
			}
			
			// Masking-key: 4 bytes
			mask = new ByteArray();
			mask.writeInt(WebSocketUtil.randomInt());
			header.writeBytes(mask);
			
			// Extension data: x bytes
			// Application data: y bytes
			// Payload data: (x+y) bytes
			body.length = payloadLength;
			
			for (i = 0; i < payloadLength; i++) {
				body[i] = payload[i] ^ mask[i % 4];
			}
			
			_socket.writeBytes(header);
			_socket.writeBytes(body);
			_socket.flush();
		}
		
		private function readFrame(buffer:ByteArray):WebSocketFrame {
			Debugger.log("readFrame");
			
			var bufferLength:uint = buffer.length;
			var byte:int;
			var finalFragment:Boolean;
			var rsv:int;
			var opcode:int;
			var payloadMasked:Boolean;
			var payloadLength:uint;
			var payload:ByteArray;
			
			if (bufferLength < 2) {
				abort("Received invalid frame");
			}
			
			// FIN: 1 bit
			// RSV1, RSV2, RSV3: 1 bit each
			// Opcode: 4 bits
			byte = buffer.readByte();
			finalFragment = (byte & 0x80) !== 0;
			rsv = (byte & 0x70) >> 4;
			opcode = byte & 0x0F;
			
			// Mask: 1 bit
			// Payload length: 7 bits, 7+16 bits, or 7+64 bits
			byte = buffer.readByte();
			payloadMasked = (byte & 0x80) !== 0;
			
			if (payloadMasked) {
				// Server message should never be masked
				abort("Received masked payload");
			}
			
			payloadLength = byte & 0x7F;
			
			if (payloadLength === 126) {
				payloadLength = buffer.readUnsignedShort();
			} else if (payloadLength === 127) {
				if (buffer.readUnsignedInt() > 0) {
					// Can't handle a message larger than 0xFFFFFFFF
					abort("Payload length too long");
				}
				
				payloadLength = buffer.readUnsignedInt();
			}
			
			if (payloadLength > (bufferLength - buffer.position)) {
				// Not enough bytes left
				// should we wait for the next SOCKET_DATA event?
				abort("Received invalid frame");
			}
			
			// Extension data: x bytes
			// Application data: y bytes
			// Payload data: (x+y) bytes
			payload = new ByteArray();
			
			if (payloadLength) {
				buffer.readBytes(payload, 0, payloadLength);
			}
			
			return new WebSocketFrame(opcode, finalFragment, rsv, payload);
		}
		
		private function handleControlFrame(frame:WebSocketFrame):void {
			Debugger.log("handleControlFrame", frame.opcode);
			
			// All control frames MUST have a payload length of 125 bytes or less
			// and MUST NOT be fragmented.
			
			if (!frame.finalFragment || frame.payload.length > 125) {
				abort("Received invalid control frame");
			}
			
			switch (frame.opcode) {
				case OPCODE_CLOSE:
					var code:int;
					var reason:String;
					
					// Parse code and reason if exists
					if (frame.payload.length >= 2) {
						code   = frame.payload.readShort();
						reason = frame.payload.readUTFBytes(frame.payload.length - 2);
					} else {
						code   = STATUS_NO_CODE;
						reason = "";
					}
					
					if (_readyState !== STATE_CLOSING) {
						// Closing handshake started at server
						// Respond with a close frame and close socket
						sendClosingHandshake(code);
						
						// Closing handshake finished
						setReadyState(STATE_CLOSED);
						
						// Notify a clean close
						dispatchEvent(new CloseEvent(code, reason, true));
						
						// Wait for the server to close the TCP connection
					} else {
						// Closing handshake finished
						setReadyState(STATE_CLOSED);
						
						// Terminate the TCP connection
						closeConnection();
						
						// Notify a clean close
						dispatchEvent(new CloseEvent(code, reason, true));
					}
					break;
				case OPCODE_PING:
					if (_readyState !== STATE_CLOSING) {
						pong(frame.payload);
					}
					break;
				case OPCODE_PONG:
					break;
				default:
					abort("Received unrecognized frame opcode: " + frame.opcode);
					break;
			}
		}
		
		private function handleDataFrame(frame:WebSocketFrame):void {
			Debugger.log("handleDataFrame", frame.opcode);
			
			if (_readyState === STATE_CLOSING) {
				// Ignore frame
				return;
			}
			
			if (frame.opcode === OPCODE_CONT) {
				// Continuation frame
				if (!_fragment) {
					abort("Received unexpected Continuation frame");
				}
				
				// Append Continuation frame to fragment
				_fragment.payload.writeBytes(frame.payload);
				
				if (frame.finalFragment) {
					handleMessageFrame(_fragment);
				}
			} else {
				// Text/Binary frame
				if (_fragment) {
					// Ignore fragment
					// Should we abort?
					_fragment = null;
				}
				
				if (frame.finalFragment) {
					handleMessageFrame(frame);
				} else {
					_fragment = frame;
				}
			}
		}
		
		private function handleMessageFrame(frame:WebSocketFrame):void {
			Debugger.log("handleMessageFrame", frame.opcode);
			
			switch (frame.opcode) {
				case OPCODE_TEXT:
					dispatchEvent(new MessageEvent(frame.payload.toString()));
					break;
				case OPCODE_BINARY:
					dispatchEvent(new MessageEvent(frame.payload));
					break;
				default:
					abort("Received unrecognized frame opcode: " + frame.opcode);
					break;
			}
		}
		
		private function ping(data:ByteArray):void {
			sendFrame(new WebSocketFrame(OPCODE_PING, true, 0, data));
		}
		
		private function pong(data:ByteArray):void {
			sendFrame(new WebSocketFrame(OPCODE_PONG, true, 0, data));
		}
		
		private function abort(reason:String):void {
			Debugger.log('abort', reason);
			
			setReadyState(STATE_CLOSED);
			
			if (_socket.connected) {
				_socket.close();
			}
			
			var error:Error = new Error(reason);
			
			// Notify the client asynchronously
			setTimeout(function ():void {
				dispatchEvent(new Event("error"));
				dispatchEvent(new ExceptionEvent(error));
				dispatchEvent(new CloseEvent(STATUS_CLOSED_ABNORMALLY, "", false));
			}, 1);
			
			// Throw an error to stop current task
			throw error;
		}
		
		private function closeConnection():void {
			Debugger.log("closeConnection");
			
			clearTimeout(_closingHandshakeTimeout);
			
			if (_socket.connected) {
				_socket.close();
			}
			
			if (_readyState === STATE_CLOSED) {
				// Closed cleanly
				return;
			}
			
			if (_readyState !== STATE_CLOSING) {
				// Unexpected close
				dispatchEvent(new Event("error"));
			}
			
			setReadyState(STATE_CLOSED);
			dispatchEvent(new CloseEvent(STATUS_CLOSED_ABNORMALLY, "", false));
		}
		
		private function emptyBuffer():void {
			// This does not actually empty any buffer
			// just resets the bufferedAmount property and notifies the client
			// TODO
			// The function and event name do not match the actual logic
			// updateBuffer() and Event(bufferChange) might be good
			clearTimeout(_emptyBufferTimeout);
			_emptyBufferTimeout = 0;
			
			if (_sendedAmount) {
				_bufferedAmount -= _sendedAmount;
				dispatchEvent(new Event("bufferEmpty"));
			}
		}
		
		private function onSocketConnect(e:Event = null):void {
			Debugger.log('onSocketConnect');
			
			if (_readyState === STATE_CLOSED) {
				_socket.close();
				return;
			}
			
			sendOpeningHandshake();
		}
		
		private function onSocketClose(e:Event = null):void {
			Debugger.log('onSocketClose');
			closeConnection();
		}
		
		private function onSocketIOError(e:IOErrorEvent = null):void {
			Debugger.log('onSocketIOError');
			
			if (_readyState === STATE_CLOSED) {
				return;
			}
			
			abort("Socket IO Error. URL: " + url);
		}
		
		private function onSocketSecurityError(e:SecurityErrorEvent = null):void {
			Debugger.log('onSocketSecurityError');
			
			if (_readyState === STATE_CLOSED) {
				return;
			}
			
			abort("Socket Security Error. URL: " + url);
		}
		
		private function onSocketData(e:ProgressEvent = null):void {
			Debugger.log('onSocketData');
			
			var frame:WebSocketFrame;
			
			if (_readyState === STATE_CLOSED) {
				_socket.close();
				return;
			}
			
			var buffer:ByteArray = new ByteArray();
			_socket.readBytes(buffer);
			
			if (_readyState === STATE_CONNECTING) {
				// Expecting handshake response
				readOpeningHandshake(buffer);
				
				// When the WebSocket connection is established, the user agent must queue a task to run these steps:
				
				// 1. Change the readyState attribute's value to OPEN (1).
				setReadyState(STATE_OPEN);
				
				// 2. Change the extensions attribute's value to the extensions in use, if is not the null value.
				// 3. Change the protocol attribute's value to the subprotocol in use, if is not the null value.
				
				// TODO
				// 4. Act as if the user agent had received a set-cookie-string consisting of the cookies set during the server's opening handshake, for the URL url given to the WebSocket() constructor.
				
				// 5. Fire a simple event named open at the WebSocket object.
				dispatchEvent(new Event('open'));
			}
			
			while (buffer.bytesAvailable) {
				frame = readFrame(buffer);
				
				if (frame.opcode >> 3 === 1) {
					handleControlFrame(frame);
				} else {
					handleDataFrame(frame);
				}
			}
		}
		
		public function WebSocketClientHandler(host:String, port:uint, resource:String, secure:Boolean, protocols:Array, extensions:Array, origin:String, cookies:String) {
			//setReadyState(STATE_CONNECTING);
			
			_host     = host;
			_hostport = host + ((!secure && port !== 80) || (secure && port !== 443) ? ":" + port : "");
			_port     = port;
			_resource = resource;
			_secure   = secure;
			_origin   = origin;
			
			if (secure) {
				var config:TLSConfig = new TLSConfig(TLSEngine.CLIENT, null, null, null, null, null, TLSSecurityParameters.PROTOCOL_VERSION);
				config.trustAllCertificates = true;
				config.ignoreCommonNameMismatch = true;
				_socket = new TLSSocket(_host, _port, config);
			} else {
				_socket = new Socket(_host, _port);
			}
			_socket.addEventListener(Event.CONNECT, onSocketConnect);
			_socket.addEventListener(Event.CLOSE, onSocketClose);
			_socket.addEventListener(IOErrorEvent.IO_ERROR, onSocketIOError);
			_socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSocketSecurityError);
			_socket.addEventListener(ProgressEvent.SOCKET_DATA, onSocketData);
		}
		
		public function get url():String {
			return (_secure ? 'wss' : 'ws') + '://' + _hostport + _resource;
		}
		
		public function get protocol():String {
			if (_readyState === STATE_CONNECTING) {
				return "";
			} else {
				return _protocols.join(", ");
			}
		}
		
		public function get extensions():String {
			if (_readyState === STATE_CONNECTING) {
				return "";
			} else {
				return _extensions.join(", ");
			}
		}
		
		public function get readyState():int {
			return _readyState;
		}
		
		public function get bufferedAmount():uint {
			return _bufferedAmount;
		}
		
		public function send(data:*):void {
			var frame:WebSocketFrame;
			
			if (data is ByteArray) {
				frame = new WebSocketFrame(OPCODE_BINARY, true, 0, data as ByteArray);
			} else {
				frame = new WebSocketFrame(OPCODE_TEXT, true, 0, null);
				frame.payload.writeUTFBytes(data as String);
			}
			
			_bufferedAmount += frame.payload.length;
			
			if (_readyState === STATE_OPEN) {
				try {
					sendFrame(frame);
				} catch (e:Error) {
					// Throw errors asynchronously in public methods
					var error:Error = e; // for some reason we need a local copy
					setTimeout(function ():void {
						throw error;
					}, 1);
					return;
				}
				
				// Increase the amount of data that was actually sent
				_sendedAmount += frame.payload.length;
				
				// Reserve a timer to update the bufferedAmount in the next event loop
				if (!_emptyBufferTimeout) {
					_emptyBufferTimeout = setTimeout(emptyBuffer, 1);
				}
			}
		}
		
		public function close(code:int = -1, reason:String = ""):void {
			try {
				sendClosingHandshake(code, reason);
			} catch (e:Error) {
				// Throw errors asynchronously in public methods
				var error:Error = e; // for some reason we need a local copy
				setTimeout(function ():void {
					throw error;
				}, 1);
			}
		}
		
		override public function dispatchEvent(event:Event):Boolean {
			var ret:Boolean;
			
			try {
				ret = super.dispatchEvent(event);
			} catch (e:Error) {
				// pass
			}
			
			return ret;
		}
	}
}