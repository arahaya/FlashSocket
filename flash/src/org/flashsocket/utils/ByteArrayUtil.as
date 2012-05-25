package org.flashsocket.utils {
	import flash.utils.ByteArray;
	
	public class ByteArrayUtil {
		/**
		 * Return a new copy of byteArray.position to byteArray.length
		 * @param	byteArray:ByteArray
		 * @return  remaining:ByteArray
		 */
		public static function remainingBytes(byteArray:ByteArray):ByteArray {
			var remaining:ByteArray = new ByteArray();
			byteArray.readBytes(remaining);
			remaining.position = 0;
			return remaining;
		}
	}
}