package org.flashsocket {
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.system.Security;
	import org.flashsocket.utils.Browser;
	import org.flashsocket.utils.Debugger;
	import org.flashsocket.websocket.events.CloseEvent;
	import org.flashsocket.websocket.events.ExceptionEvent;
	import org.flashsocket.websocket.events.MessageEvent;
	import org.flashsocket.websocket.events.ReadyStateEvent;
	import org.flashsocket.websocket.WebSocket;
	
	public class FlashSocket extends Sprite {
		private const JS_PREFIX:String = "FlashSocket.ExternalInterface.";
		
		private var instances:Array = [];
		private var origin:String;
		private var cookie:String;
		private var lastException:Error;
		
		public function FlashSocket():void {
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			Debugger.initialize(this);
			Security.allowDomain("*");
			
			initExternalInterface();
			
			
			if (CONFIG::debug && new RegExp("file://").test(loaderInfo.url)) {
				var instance:WebSocket = new WebSocket("ws://localhost:8080/websocket", []);
				
				instance.addEventListener("open", function (e:Event):void {
					Debugger.log("onopen");
					instance.send("hello world");
				});
				instance.addEventListener("error", function (e:Event):void {
					Debugger.log("onerror");
				});
				instance.addEventListener("close", function (e:CloseEvent):void {
					Debugger.log("onclose", e.code, e.reason, e.wasClean);
				});
				instance.addEventListener("message", function (e:MessageEvent):void {
					Debugger.log("onmessage", String(e.data));
					instance.close();
				});
				instance.addEventListener("exception", function (e:ExceptionEvent):void {
					Debugger.log("onexception", e.error.name, e.error.message);
				});
				instance.addEventListener("readyStateChange", function (e:ReadyStateEvent):void {
					Debugger.log("onreadyStateChange", e.state);
				});
				instance.addEventListener("bufferEmpty", function (e:Event):void {
					Debugger.log("onbufferEmpty");
				});
			}
		}
		
		private function initExternalInterface():void {
			if (!ExternalInterface.available) {
				return;
			}
			
			// Enable throwing exceptions to JavaScript
			// This is used in the constructor, send and close calls.
			// FIXME: Chrome doesn't seem to get the message correctly
			// FIXED: Added ExternalInterface.getLastException()
			ExternalInterface.marshallExceptions = true;
			
			// Get the origin of the html page
			origin = Browser.origin || 'null';
			Debugger.log("origin", origin);
			
			// Get the cookie of the html page
			cookie = Browser.cookie || '';
			Debugger.log("cookie", cookie);
			
			ExternalInterface.addCallback("connect", onExternalConnect);
			ExternalInterface.addCallback("send", onExternalSend);
			ExternalInterface.addCallback("close", onExternalClose);
			
			ExternalInterface.addCallback("getUrl", onExternalGetUrl);
			ExternalInterface.addCallback("getReadyState", onExternalGetReadyState);
			ExternalInterface.addCallback("getBufferedAmount", onExternalGetBufferedAmount);
			ExternalInterface.addCallback("getExtensions", onExternalGetExtensions);
			ExternalInterface.addCallback("getProtocol", onExternalGetProtocol);
			// binaryType not supported
			
			ExternalInterface.addCallback("getLastException", onExternalGetLastException);
			
			callExternalReady();
		}
		
		/* ------------------------------------------------------------
		 * ExternalInterface call handlers
		 * ------------------------------------------------------------ */
		private function callExternalReady():void {
			ExternalInterface.call(JS_PREFIX + "onready");
		}
		
		private function callExternalOpen(instanceId:int, url:String, extensions:String, protocol:String):void {
			ExternalInterface.call(JS_PREFIX + "onopen", instanceId, url, extensions, protocol);
		}
		
		private function callExternalError(instanceId:int):void {
			ExternalInterface.call(JS_PREFIX + "onerror", instanceId);
		}
		
		private function callExternalClose(instanceId:int, code:int, reason:String, wasClean:Boolean):void {
			ExternalInterface.call(JS_PREFIX + "onclose", instanceId, code, reason, wasClean);
		}
		
		private function callExternalMessage(instanceId:int, data:String):void {
			ExternalInterface.call(JS_PREFIX + "onmessage", instanceId, data);
		}
		
		private function callExternalException(instanceId:int, name:String, message:String):void {
			ExternalInterface.call(JS_PREFIX + "onexception", instanceId, name, message);
		}
		
		private function callExternalReadyStateChange(instanceId:int, state:int):void {
			ExternalInterface.call(JS_PREFIX + "onreadystatechange", instanceId, state);
		}
		
		private function callExternalBufferEmpty(instanceId:int):void {
			ExternalInterface.call(JS_PREFIX + "onbufferempty", instanceId);
		}
		 
		/* ------------------------------------------------------------
		 * ExternalInterface callback handlers
		 * ------------------------------------------------------------ */
		private function onExternalConnect(instanceId:int, url:String, protocols:Array):void {
			Debugger.log("onExternalConnect", instanceId, url, protocols);
			
			var instance:WebSocket;
			
			try {
				instance = new WebSocket(url, protocols, origin, cookie);
			} catch (e:Error) {
				lastException = e;
				throw e;
			}
			
			instance.addEventListener("open", function (e:Event):void {
				callExternalOpen(instanceId, instance.url, instance.extensions, instance.protocol);
			});
			instance.addEventListener("error", function (e:Event):void {
				callExternalError(instanceId);
			});
			instance.addEventListener("close", function (e:CloseEvent):void {
				callExternalClose(instanceId, e.code, e.reason, e.wasClean);
			});
			instance.addEventListener("message", function (e:MessageEvent):void {
				callExternalMessage(instanceId, e.data);
			});
			instance.addEventListener("exception", function (e:ExceptionEvent):void {
				callExternalException(instanceId, e.error.name, e.error.message);
			});
			instance.addEventListener("readyStateChange", function (e:ReadyStateEvent):void {
				callExternalReadyStateChange(instanceId, e.state);
			});
			instance.addEventListener("bufferEmpty", function (e:Event):void {
				callExternalBufferEmpty(instanceId);
			});
			
			instances[instanceId] = instance;
		}
		
		private function onExternalSend(instanceId:int, data:String):uint {
			Debugger.log("onExternalSend", instanceId, data);
			
			try {
				instances[instanceId].send(data);
			} catch (e:Error) {
				lastException = e;
				throw e;
			}
			
			return instances[instanceId].bufferedAmount;
		}
		
		private function onExternalClose(instanceId:int, code:int = -1, reason:String = ""):void {
			Debugger.log("onExternalClose", instanceId, code, reason);
			
			try {
				instances[instanceId].close(code, reason);
			} catch (e:Error) {
				lastException = e;
				throw e;
			}
		}
		
		private function onExternalGetUrl(instanceId:int):String {
			return instances[instanceId] ? instances[instanceId].url : "";
		}
		
		private function onExternalGetReadyState(instanceId:int):int {
			return instances[instanceId] ? instances[instanceId].readyState : 0;
		}
		
		private function onExternalGetBufferedAmount(instanceId:int):uint {
			return instances[instanceId] ? instances[instanceId].bufferedAmount : 0;
		}
		
		private function onExternalGetExtensions(instanceId:int):String {
			return instances[instanceId] ? instances[instanceId].extensions : "";
		}
		
		private function onExternalGetProtocol(instanceId:int):String {
			return instances[instanceId] ? instances[instanceId].protocol : "";
		}
		
		private function onExternalGetLastException(instanceId:int):String {
			return lastException ? lastException.message : "";
		}
	}
}