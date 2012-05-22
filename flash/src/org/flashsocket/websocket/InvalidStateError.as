package org.flashsocket.websocket {
	public class InvalidStateError extends Error {
		public function InvalidStateError(message:String, errorID:int=0) { 
			super(message, errorID); 
		}
		
		public function toString():String {
			return "InvalidStateError: " + message;
		}
	}
}