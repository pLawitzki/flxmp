/*
 * Copyright (c) 2010 Paul Lawitzki
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this
 * software and associated documentation files (the "Software"), to deal in the Software
 * without restriction, including without limitation the rights to use, copy, modify, merge,
 * publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to
 * whom the Software is furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all copies or
 * substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
 * BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

package flxmp
{
	import flash.display.Shape;
	public class Wave
	{
		public var name:String;
		public var samples:Vector.<Number>;
		public var sampleList:Vector.<MonoListNode>;
		public var length:int;
		public var loopStart:int;
		public var loopStartNode:MonoListNode;
		public var loopLength:int;
		public var loopEnd:int;
		public var loopEndNode:MonoListNode;
		public var volume:Number;
		public var finetune:Number;
		public var sixteenbit:Boolean;
		public var type:int;
		public var panning:Number;
		public var relNote:int;
		
		public function Wave()
		{
			
		}
		
		public function drawWave():Shape
		{
			var shp:Shape = new Shape();
			var t:Number = 0.0;
			shp.graphics.moveTo(0, 300);
			shp.graphics.lineStyle(1);
			for each(var s:Number in samples)
			{
				shp.graphics.lineTo(t, 300 - (s*300));
				t += 0.1;
			}
			return shp;
		}
	}

}