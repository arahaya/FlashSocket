package org.flashsocket.utils {
	import flash.utils.ByteArray;
	
	public class StringUtil {
		public static function trim(input:String):String {
			return input.replace(/^([\s|\t|\n]+)?(.*)([\s|\t|\n]+)?$/gm, "$2");
		}
		
		public static function toBytes(input:String):ByteArray {
			var bytes:ByteArray = new ByteArray(),
				length:int = input.length,
				i:int = 0;
			
			bytes.length = length;
			
			while (i < length) {
				bytes[i] = input.charCodeAt(i++);
			}
			
			bytes.position = length;
			
			return bytes;
		}
	}
}