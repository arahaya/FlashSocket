package org.flashsocket.websocket.events {
	import flash.events.Event;
	
	public class MessageEvent extends Event {
		
		private var _data:*; // String or ByteArray
		public function get data():* {
			return _data;
		}
		
		public function MessageEvent(data:*) {
			super("message", false, false);
			
			_data = data;
		}
		
		public override function clone():Event {
			return new MessageEvent(_data);
		}
		
		public override function toString():String {
			return formatToString("MessageEvent", "type", "bubbles", "cancelable");
		}
	}
}