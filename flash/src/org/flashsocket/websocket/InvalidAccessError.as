package org.flashsocket.websocket {
	public class InvalidAccessError extends Error {
		public function InvalidAccessError(message:String, errorID:int=0) { 
			super(message, errorID); 
		}
		
		public function toString():String {
			return "InvalidAccessError: " + message;
		}
	}
}