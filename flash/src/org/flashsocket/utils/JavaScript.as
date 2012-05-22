package org.flashsocket.utils {
	import flash.external.ExternalInterface;
	
	/**
	 * ExternalInterface wrapper
	 */
	public class JavaScript {
		public static function call(functionName:String, ...args):* {
			if (ExternalInterface.available) {
				try {
					return ExternalInterface.call.apply(ExternalInterface, [functionName].concat(args));
				} catch (e:Error) { trace(e) }
			}
		}
		
		public static function addCallback(functionName:String, closure:Function):void {
			if (ExternalInterface.available) {
				try {
					ExternalInterface.addCallback(functionName, closure);
				} catch (e:Error) { trace(e) }
			}
		}
	}
}