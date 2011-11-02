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

	public class Channel
	{
		private var parentMod:Module;
		public var note:int;
		public var nextNote:int;
		public var realNote:int;
		public var period:int;
		public var targetPeriod:int;
		public var oldPeriod:int;
		public var instrument:Instrument;
		public var volume:Number;
		public var panning:Number;
		public var columnVolume:Number;
		public var targetVolume:Number;
		public var targetPanning:Number;
		public var volumeCommand:int;
		public var volumeTabIndex:int;
		public var fadeout:Number;
		public var panEnvPos:int;
		public var volEnvPos:int;
		public var effect:int;
		public var nextEffect:int;
		public var ignoreInstrument:Boolean;
		public var ignoreNextInstrument:Boolean;
		public var parameter:int;
		public var oldParameter:int;
		public var wave:Wave;
		public var waveData:Vector.<Number>;
		public var waveList:Vector.<MonoListNode>;
		public var waveType:int;
		public var wavePos:Number;
		public var waveVolume:Number;
		public var wavePanning:Number;
		public var lastIndex:int;
		public var nextIndex:int;
		public var waveStep:Number;
		public var targetWaveStep:Number;
		public var waveReverse:Boolean;
		public var waveLength:Number;
		public var loopStart:Number;
		public var loopEnd:Number;
		public var loopLength:Number;
		public var keyDown:Boolean;
		public var vibdepth:int;
		public var vibrate:Number;
		public var vibform:int;
		public var vibtime:Number;
		public var vib:Boolean;
		
		public function Channel(Parent:Module) 
		{
			parentMod 	= Parent;
			nextNote	= 0;
			wavePos		= 0.0;
			lastIndex	= 0;
			nextIndex	= 1;
			waveStep	= 0.0;
			waveData	= new Vector.<Number>;
			waveList	= new Vector.<MonoListNode>;
			waveData.push(0.0);
			wavePanning	= 0.5;
			waveVolume	= 1.0;
			loopStart	= 0.0;
			loopEnd		= 1.0;
			loopLength	= 1.0;
			waveType	= 0;
			keyDown		= false;
			waveReverse	= false;
			fadeout		= 1.0;
			volEnvPos	= 0;
			panEnvPos	= 0;
			vib			= false;
			vibdepth	= 0;
			vibrate		= 0.0;
			vibform		= 0;
			vibtime		= 0.0;
			columnVolume = 1.0;
			volumeTabIndex = 0x40;
			volume		= 0.0;
			panning		= 0.5;
			targetVolume = 0.0;
			targetPanning = 0.5;
			ignoreInstrument = false;
			ignoreNextInstrument = false;
		}
		
	}

}