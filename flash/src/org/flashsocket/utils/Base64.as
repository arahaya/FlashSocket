package org.flashsocket.utils {
	import flash.utils.ByteArray;
	
	public class Base64 {
		private static const CHARS:Array = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/', '='];
		
		public static function encode(input:String):String {
			return encodeBytes(StringUtil.toBytes(input));
		}
		
		public static function encodeBytes(input:ByteArray):String {
            var output:String = '',
                chr1:int, chr2:int, chr3:int,
				enc1:int, enc2:int, enc3:int, enc4:int,
                i:int = 0,
                l:int = input.length;

            while (i < l) {
                chr1 = input[i++] & 0xFF;
                chr2 = input[i++] & 0xFF;
                chr3 = input[i++] & 0xFF;
				
                enc1 = chr1 >> 2;
                enc2 = ((chr1 & 3) << 4) | (chr2 >> 4);
                enc3 = ((chr2 & 15) << 2) | (chr3 >> 6);
                enc4 = chr3 & 63;
				
                if (i > l) {
                    enc4 = 64;
					
                    if (i > l + 1) {
                        enc3 = 64;
                    }
                }
				
                output += (CHARS[enc1] + CHARS[enc2] + CHARS[enc3] + CHARS[enc4]);
            }

            return output;
		}
	}
}