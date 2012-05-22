package org.flashsocket.websocket.events {
	import flash.events.Event;
	
	public class CloseEvent extends Event {
		
		private var _wasClean:Boolean;
		public function get wasClean():Boolean {
			return _wasClean;
		}
		
		private var _code:int;
		public function get code():int {
			return _code;
		}
		
		private var _reason:String;
		public function get reason():String {
			return _reason;
		}
		
		public function CloseEvent(code:int = 0, reason:String = "", wasClean:Boolean = false) {
			super("close", false, false);
			
			_wasClean = wasClean;
			_code = code;
			_reason = reason;
		}
		
		public override function clone():Event {
			return new CloseEvent(code, reason, wasClean);
		}
		
		public override function toString():String {
			return formatToString("CloseEvent", "code", "reason", "wasClean");
		}
	}
}