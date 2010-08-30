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

	public class Instrument
	{
		public var name:String;
		public var volumeEnvelope:Vector.<Number>;
		public var volEnvLength:int;
		public var panningEnvelope:Vector.<Number>;
		public var panEnvLength:int;
		public var numSamples:int;
		public var waves:Vector.<Wave>;
		public var smpNotes:Vector.<uint>;
		public var volSustain:int;
		public var volLoopStart:int;
		public var volLoopEnd:int;
		public var panSustain:int;
		public var panLoopStart:int;
		public var panLoopEnd:int;
		public var volON:Boolean;
		public var volSUS:Boolean;
		public var volLOOP:Boolean;
		public var panON:Boolean;
		public var panSUS:Boolean;
		public var panLOOP:Boolean;
		public var vibType:int;
		public var vibSweep:int;
		public var vibDepth:int;
		public var vibRate:int;
		public var fadeout:Number;
		
		public function Instrument()
		{
			smpNotes 	= new Vector.<uint>(96, true);
			numSamples	= 0;
		}
		
	}

}