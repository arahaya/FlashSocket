package org.flashsocket.utils {
	import flash.utils.ByteArray;
	
	public class SHA1 {
		public static function hash(input:String):String {
			var inputLength:int = input.length;
			// Number of 8-bit bytes to represent the 512-bit blocks
			var numberOfBytes:int = (inputLength + 9) + ((55 - inputLength) & 0x3f);
			// Number of 512-bit blocks required
			var numberOfBlocks:int = numberOfBytes >> 6;
			// Convert input String to ByteArray
			var bytes:ByteArray = StringUtil.toBytes(input);
			
			// Insert the first padding bit "1" right after the message
			bytes.writeByte(0x80);
			
			// Insert the message length as the last 8 bytes
			bytes.position = numberOfBytes - 8;
			bytes.writeUnsignedInt(inputLength >>> 29);
			bytes.writeUnsignedInt(inputLength << 3);
			bytes.position = 0;
			
			// Compute the Message Digest
			// algorithm based on the C code demonstration shown at
			// http://www.faqs.org/rfcs/rfc3174.html
			var H0:int = 0x67452301;
			var H1:int = 0xefcdab89;
			var H2:int = 0x98badcfe;
			var H3:int = 0x10325476;
			var H4:int = 0xc3d2e1f0;
			var W:Array = new Array(80);
			var temp:int;
			var A:int;
			var B:int;
			var C:int;
			var D:int;
			var E:int;
			var t:int;
			
			while (numberOfBlocks--) {
				A = H0;
				B = H1;
				C = H2;
				D = H3;
				E = H4;
				
				for (t = 0; t < 16; t++) {
					W[t] = bytes.readUnsignedInt();
				}
				
				for (t = 16; t < 80; t++) {
					temp = int(W[t - 3]) ^ int(W[t - 8]) ^ int(W[t - 14]) ^ int(W[t - 16]);
					W[t] = (temp << 1) | (temp >>> 31);
				}
				
				for (t = 0; t < 20; t++) {
					temp =  ((A << 5) | (A >>> 27)) + ((B & C) | ((~B) & D)) + E + int(W[t]) + 0x5a827999;
					E = D;
					D = C;
					C = (B << 30) | (B >>> 2);
					B = A;
					A = temp;
				}
				
				for (t = 20; t < 40; t++) {
					temp = ((A << 5) | (A >>> 27)) + (B ^ C ^ D) + E + int(W[t]) + 0x6ed9eba1;
					E = D;
					D = C;
					C = (B << 30) | (B >>> 2);
					B = A;
					A = temp;
				}

				for (t = 40; t < 60; t++) {
					temp = ((A << 5) | (A >>> 27)) + ((B & C) | (B & D) | (C & D)) + E + int(W[t]) + 0x8f1bbcdc;
					E = D;
					D = C;
					C = (B << 30) | (B >>> 2);
					B = A;
					A = temp;
				}

				for (t = 60; t < 80; t++) {
					temp = ((A << 5) | (A >>> 27)) + (B ^ C ^ D) + E + int(W[t]) + 0xca62c1d6;
					E = D;
					D = C;
					C = (B << 30) | (B >>> 2);
					B = A;
					A = temp;
				}
				
				H0 += A;
				H1 += B;
				H2 += C;
				H3 += D;
				H4 += E;
			}
			
			return String.fromCharCode(
				H0 >> 24 & 0xff,
				H0 >> 16 & 0xff,
				H0 >> 8  & 0xff,
				H0       & 0xff,
				
				H1 >> 24 & 0xff,
				H1 >> 16 & 0xff,
				H1 >> 8  & 0xff,
				H1       & 0xff,
				
				H2 >> 24 & 0xff,
				H2 >> 16 & 0xff,
				H2 >> 8  & 0xff,
				H2       & 0xff,
				
				H3 >> 24 & 0xff,
				H3 >> 16 & 0xff,
				H3 >> 8  & 0xff,
				H3       & 0xff,
				
				H4 >> 24 & 0xff,
				H4 >> 16 & 0xff,
				H4 >> 8  & 0xff,
				H4       & 0xff
			);
		}
		
		public static function test():void {
			var tests:Array = [
				"abc",
				"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
				"a",
				"0123456701234567012345670123456701234567012345670123456701234567"
			];
			var results:Array = [
				"A9 99 3E 36 47 06 81 6A BA 3E 25 71 78 50 C2 6C 9C D0 D8 9D",
				"84 98 3E 44 1C 3B D2 6E BA AE 4A A1 F9 51 29 E5 E5 46 70 F1",
				"86 F7 E4 37 FA A5 A7 FC E1 5D 1D DC B9 EA EA EA 37 76 67 B8",
				"E0 C0 94 E8 67 EF 46 C3 50 EF 54 A7 F5 9D D6 0B ED 92 AE 83"
			];
			
			for (var t:int = 0; t < tests.length; t++) {
				trace("Test " + (t + 1) + ":   " + tests[t]);
				trace("expected: " + results[t]);
				
				var hashed:String = hash(tests[t]);
				var hex:Array = [];
				for (var h:int = 0; h < hashed.length; h++) {
					hex.push((0x100 + hashed.charCodeAt(h)).toString(16).replace('1', '').toUpperCase());
				}
				var result:String = hex.join(" ");
				trace("result:   " + result);
				trace("correct:  " + (result === results[t]));
				trace();
			}
		}
	}
}