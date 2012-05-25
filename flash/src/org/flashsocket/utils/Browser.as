package org.flashsocket.utils {
	import flash.external.ExternalInterface;
	
	public class Browser {
		public static function get origin():String {
			return JavaScript.call("function () { return location.protocol + '//' + location.host }");
		}
		
		public static function get cookie():String {
			return JavaScript.call("document.cookie.toString");
		}
	}
}