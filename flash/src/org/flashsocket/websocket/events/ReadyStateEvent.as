package org.flashsocket.websocket.events {
	import flash.events.Event;
	
	public class ReadyStateEvent extends Event {
		public static const CHANGE:String = "readyStateChange";
		
		private var _state:int;
		public function get state():* {
			return _state;
		}
		
		public function ReadyStateEvent(type:String, state:int) {
			super(type, false, false);
			
			_state = state;
		}
		
		public override function clone():Event {
			return new ReadyStateEvent(type, _state);
		}
		
		public override function toString():String {
			return formatToString("ReadyStateEvent", "type", "bubbles", "cancelable");
		}
	}
}