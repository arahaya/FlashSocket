package org.flashsocket.utils {
	CONFIG::debug {
		import com.demonsters.debugger.MonsterDebugger;
	}
	
	public class Debugger {
		private static var _target:Object;
		private static var _number:Number;
		
		public static function initialize(target:Object):void {
			_target = target;
			_number = 0;
			
			CONFIG::debug {
				MonsterDebugger.initialize(target);
			}
		}
		
		public static function log(...rest):void {
			trace.apply(null, [++_number].concat(rest));
			
			CONFIG::debug {
				MonsterDebugger.trace(_target, rest.join(" "))
			}
		}
	}
}