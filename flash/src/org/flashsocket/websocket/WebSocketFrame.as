package org.flashsocket.websocket {
	import flash.utils.ByteArray;
	
	public class WebSocketFrame {
		private var _opcode:int;
		private var _finalFragment:Boolean = true;
		private var _rsv:int = 0;
		private var _payload:ByteArray;
		
		public function WebSocketFrame(opcode:int, finalFragment:Boolean = true, rsv:int = 0, payload:ByteArray = null) {
			_opcode = opcode;
			_finalFragment = finalFragment;
			_rsv = rsv;
			_payload = payload || new ByteArray();
		}
		
		public function get opcode():int {
			return _opcode;
		}
		
		public function set opcode(value:int):void {
			_opcode = value;
		}
		
		public function get finalFragment():Boolean {
			return _finalFragment;
		}
		
		public function set finalFragment(value:Boolean):void {
			_finalFragment = value;
		}
		
		public function get rsv():int {
			return _rsv;
		}
		
		public function set rsv(value:int):void {
			_rsv = value;
		}
		
		public function get payload():ByteArray {
			return _payload;
		}
		
		public function set payload(value:ByteArray):void {
			_payload = value;
		}
	}
}