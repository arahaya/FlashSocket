package org.flashsocket.websocket.events {
	import flash.events.Event;
	
	public class ExceptionEvent extends Event {
		private var _error:Error;
		public function get error():Error {
			return _error;
		}
		
		public function ExceptionEvent(error:Error) {
			super("exception", false, false);
			
			_error = error;
		}
		
		public override function clone():Event {
			return new ExceptionEvent(_error);
		}
		
		public override function toString():String {
			return formatToString("ExceptionEvent", "type", "bubbles", "cancelable");
		}
	}
}