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
	import flash.events.SampleDataEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.utils.ByteArray;
	
	public class Player
	{
		private var mod:Module;
		private var sound:Sound;
		private var soundChannel:SoundChannel;
		private var bufferL:Vector.<Number>;
		private var bufferR:Vector.<Number>;
		private var stereoBuffer:Vector.<StereoListNode>;
		private var nextPosNode:StereoListNode;
		private var bufferPtr:StereoListNode;
		private var tickCnt:int;
		private var sampleCountdown:int;
		private var smpRest:int;
		private var smpTick:int;
		private var smpDone:int;
		private var chan:Channel;
		private var pattern:ByteArray;
		private var patternIndex:int;
		private var gVolume:Number;
		private var playing:Boolean;
		private var channelPos:int;
		
		public var startTime:Date;
		public var endTime:Date;
		public var cycleMonitorText:String;
		
		// linear volume table			
		private const VOL_TAB_LIN:Vector.<Number> = Vector.<Number>([
			0.0,	0.015625,	0.03125,	0.046875,	0.0625,		0.078125,		0.09375,	0.109375,
			0.125,	0.140625,	0.15625,	0.171875,	0.1875,		0.203125,		0.21875,	0.234375,
			0.25,	0.265625,	0.28125,	0.296875,	0.3125,		0.328125,		0.34375,	0.359375,
			0.375,	0.390625,	0.40625,	0.421875,	0.4375,		0.453125,		0.46875,	0.484375,
			0.5,	0.515625,	0.53125,	0.546875,	0.5625,		0.578125,		0.59375,	0.609375,
			0.625,	0.640625,	0.65625,	0.671875,	0.6875,		0.703125,		0.71875,	0.734375,
			0.75,	0.765625,	0.78125,	0.796875,	0.8125,		0.828125,		0.84375,	0.859375,
			0.875,	0.890625,	0.90625,	0.921875,	0.9375,		0.953125,		0.96875,	0.984375,
			1.0]);

		// logarithmic volume table			
		private const VOL_TAB_LOG:Vector.<Number> = Vector.<Number>([
			0.0,			0.070036183,	0.128709969,	0.179535514,	0.224366822,	0.264469794,	0.300747344,	0.333866153,
			0.364332504,	0.392539939,	0.418800433,	0.443365484,	0.466440803,	0.488196792,	0.508776192,	0.528299764,
			0.546870578,	0.564577314,	0.581496819,	0.597696123,	0.613234043,	0.628162474,	0.642527431,	0.656369909,
			0.669726584,	0.682630403,	0.695111068,	0.707195454,	0.718907953,	0.730270773,	0.741304188,	0.752026762,
			0.762455529,	0.772606162,	0.782493113,	0.792129734,	0.801528389,	0.810700548,	0.819656871,	0.828407284,
			0.836961042,	0.845326789,	0.853512614,	0.861526093,	0.869374334,	0.877064013,	0.884601412,	0.891992444,
			0.899242686,	0.906357401,	0.913341564,	0.920199879,	0.926936801,	0.933556554,	0.940063143,	0.946460373,
			0.952751858,	0.958941038,	0.965031187,	0.971025424,	0.976926723,	0.982737923,	0.988461733,	0.994100743,
			1.0]);
			
		// helper variables
		private var smpIncrement:int;
		private var i:int;
		private var j:int;
		private var sample:Number;
		private var lastPos:int;
		private var nextPos:int;
		private var lastValue:Number;
		private var nextValue:Number;
		
		public var wave:Shape;
		public var env:Shape;
		public var tick:Shape;
		public var waveX:Number;
		
		public function Player(InitModule:Module) 
		{
			mod					= InitModule;
			sound 				= new Sound();
			bufferL 			= new Vector.<Number>(8192, true);
			bufferR 			= new Vector.<Number>(8192, true);
			stereoBuffer		= new Vector.<StereoListNode>(8192, true);
			tickCnt 			= 0;
			smpTick 			= int(110250 / mod.bpm);
			sampleCountdown		= smpTick;
			smpRest				= 0;
			patternIndex		= 0;
			pattern				= mod.patterns[mod.patternOrder[patternIndex]];
			pattern.position	= 0;
			gVolume				= 1.0;
			playing				= false;
			channelPos			= 0;
			
			wave = new Shape();
			env = new Shape();
			tick = new Shape();
			wave.graphics.lineStyle(0.1, 0xff0000);
			env.graphics.lineStyle(0.1, 0x0000ff);
			tick.graphics.lineStyle(0.1, 0x00ff00);
			wave.graphics.moveTo(0, 0);
			env.graphics.moveTo(0, 0);
			tick.graphics.moveTo(0, 0);
			waveX = 0;
			
			for (i = 0; i < 8192; i++) {
				stereoBuffer[i] = new StereoListNode();
				if (i)
					stereoBuffer[i - 1].next = stereoBuffer[i];
			}
			
			cycleMonitorText = new String();
		}
		
		public function play():void
		{			
			sound.addEventListener(SampleDataEvent.SAMPLE_DATA, onSampleData);
			soundChannel 		= sound.play(channelPos);
			playing 			= true;
		}
		
		public function stop():void
		{
			if (soundChannel)
				soundChannel.stop();
			sound.removeEventListener(SampleDataEvent.SAMPLE_DATA, onSampleData);
			tickCnt 			= 0;
			patternIndex		= 0;
			pattern				= mod.patterns[mod.patternOrder[patternIndex]];
			pattern.position	= 0;
			playing				= false;
			channelPos			= 0;
			nextRow();
		}
		
		public function pause():void
		{
			channelPos 			= soundChannel.position;
			soundChannel.stop();
			sound.removeEventListener(SampleDataEvent.SAMPLE_DATA, onSampleData);
			playing				= false;
		}
		
		public function get isPlaying():Boolean	{ return playing; }
		public function get peakL():Number		{ if(soundChannel) return soundChannel.leftPeak; else return 0.0 }
		public function get peakR():Number		{ if(soundChannel) return soundChannel.rightPeak; else return 0.0 }
		
		// TODO: there are still clicks on at pattern transitions!
		// TODO: first position of volume envelope sometimes fails to be played correctly
		
		private function onSampleData(e:SampleDataEvent):void
		{
			startTime = new Date();
			
			smpIncrement 	= 0;
			lastPos 		= 0;
			nextPos 		= 0;
			
			var lastNode:MonoListNode;
			
			smpDone = 0;
			smpIncrement = smpTick;
			sampleCountdown = smpTick;
			while(smpDone < 8192)
			{
				if (smpRest < 1)
				{
					sampleCountdown = smpTick;
					if (++tickCnt == mod.tempo)
					{
						tickCnt = 0;
						nextRow();
					}
					perTickProcessing();
				}
				
				if (smpRest > 0)
				{
					smpIncrement = smpRest;
				}
				else
				{
					smpIncrement = smpTick;
					if ((smpDone + smpIncrement) > 8192)
						smpIncrement = 8192 - smpDone;
				}
				
				nextPos = lastPos + smpIncrement;
				
				bufferPtr = stereoBuffer[lastPos];
				nextPosNode = stereoBuffer[nextPos - 1];
				
				//for (j = lastPos; j < nextPos; j++)
				while(true)
				{
					if (nextPosNode.next == bufferPtr)
						break;
						
					for (i = 0; i < mod.numChannels; i++)
					{
						chan = mod.channels[i];
						
						if (chan.waveStep == 0.0)
						{
							chan.wavePos	= 0.0;
							continue;
						}
						
						if (chan.instrument == null)
							continue;
						
						if (chan.instrument.numSamples <= 0)
							continue;
							
						lastNode = chan.waveList[0];
							
						// TODO: there is a sound glitch when portamento to note is triggered (check ignoreInstrument)
						// ramp down when there is a new note command in the following row
						if ((tickCnt >= (mod.tempo - 1)) && chan.nextNote != 0 && chan.nextNote < 97 && !chan.ignoreNextInstrument)
						{
							if( sampleCountdown <= 200)
								chan.targetVolume	= 0.0;
						}
						
						// volume ramping
						if (chan.volume != chan.targetVolume)
						{
							if (chan.volume > chan.targetVolume)
							{
								if ((chan.volume 	-= 3e-3) < chan.targetVolume)
									chan.volume		= chan.targetVolume;
							}else {
								if ((chan.volume		+= 3e-3) > chan.targetVolume)
									chan.volume		= chan.targetVolume;
							}
						}
						
						// panning ramping
						if (chan.panning != chan.targetPanning)
						{
							if (chan.panning > chan.targetPanning)
							{
								if ((chan.panning 	-= 5e-3) < chan.targetPanning)
									chan.panning		= chan.targetPanning;
							}else {
								if ((chan.panning	+= 5e-3) > chan.targetPanning)
									chan.panning		= chan.targetPanning;
							}
						}
						
						// value interpolation
						lastValue	= chan.waveData[chan.lastIndex];
						nextValue	= chan.waveData[chan.nextIndex];
						sample		= lastValue + (nextValue - lastValue) * (chan.wavePos - Number(int(chan.wavePos)));
						sample		*= gVolume;
						sample		*= chan.volume;
						
						bufferPtr.left += sample * (1.0 - chan.panning);
						bufferPtr.right += sample * chan.panning;
						
						//bufferL[j] += sample * (1.0 - chan.panning);
						//bufferR[j] += sample * chan.panning;
						
						if(chan.waveType > 0)
						{
							if (chan.waveType > 1)
							{
								if (chan.waveType > 2)
								{
									// one shot
									chan.wavePos += chan.waveStep;
									if (chan.wavePos > chan.loopEnd)
										chan.wavePos = 0.0;
									chan.lastIndex	= int(chan.wavePos);
									chan.nextIndex	= chan.lastIndex + 1;
								}else {
									// ping-pong loop
									if (chan.waveReverse)
									{
										if ((chan.wavePos -= chan.waveStep) < chan.loopStart)
										{
											chan.waveReverse 	= false
											chan.wavePos 		= chan.loopStart;
										}
									}else {
										if ((chan.wavePos += chan.waveStep) >= chan.loopEnd)
										{
											chan.waveReverse 	= true;
											chan.wavePos 		= chan.loopEnd - 1;
										}
									}
										
									chan.lastIndex	= int(chan.wavePos);
									if ((chan.nextIndex = chan.lastIndex + 1) >= chan.loopEnd)
										chan.nextIndex	= int(chan.loopStart);
								}
							}else {
								// forward loop
								if ((chan.wavePos += chan.waveStep) >= chan.loopEnd)
									chan.wavePos	-= chan.loopLength;
								chan.lastIndex		= int(chan.wavePos);
								if ((chan.nextIndex = int(chan.wavePos) + 1) >= chan.loopEnd)
									chan.nextIndex	= int(chan.loopStart);
							}
						}else {
							// no loop
							if ((chan.wavePos += chan.waveStep) >= chan.waveLength)
							{
								chan.wavePos = chan.waveLength;
								chan.nextIndex	= 0;
							}
							else
							{
								chan.lastIndex	= int(chan.wavePos);
								chan.nextIndex	= chan.lastIndex + 1;
							}
						}
						
						// Debug graphics
						/*if (pattern.position > 400 && pattern.position < 1750 && i == 0)
						{
							waveX += 0.005;
							wave.graphics.lineTo(waveX, bufferL[j] * 20);
							env.graphics.lineTo(waveX, chan.instrument.volumeEnvelope[chan.volEnvPos] * 20);
							tick.graphics.lineTo(waveX, tickCnt * 2);
						}*/
					}
					bufferPtr = bufferPtr.next;
					sampleCountdown--;
				}
				smpDone += smpIncrement; 
				lastPos = nextPos;
				
				if (smpRest > 0)
					smpRest = 0;
			}
				
			if (smpIncrement < smpTick)
				smpRest = smpTick - smpIncrement;
			
			/*for (i = 0; i < 8192; i++)
			{
				e.data.writeFloat(bufferL[i]);
				bufferL[i] = 0.0;
				e.data.writeFloat(bufferR[i]);
				bufferR[i] = 0.0;
			}*/
			bufferPtr = stereoBuffer[0];
			while (bufferPtr) {
				e.data.writeFloat(bufferPtr.left);
				e.data.writeFloat(bufferPtr.right);
				bufferPtr.left = 0.0;
				bufferPtr.right = 0.0;
				bufferPtr = bufferPtr.next;
			}
			
			endTime = new Date();
			
			cycleMonitorText = (endTime.time - startTime.time).toString();
		}
		
		private function nextRow():void
		{
			// next pattern if end is reached
			if (pattern.bytesAvailable == 0)
			{
				patternIndex++;
				if(patternIndex == mod.songLength)
					patternIndex = mod.restartPos;
				
				pattern = mod.patterns[mod.patternOrder[patternIndex]];
				pattern.position = 0;
			}
			
			for (var i:int = 0; i < mod.numChannels; i++)
			{
				chan 				= mod.channels[i];
				chan.note 			= pattern.readUnsignedByte();
				
				// read the next note of this channel and return to old position in pattern
				// the next note is needed to predict whether a volume ramp down needs to be made in order to prevent clicks
				var tempPos:int		= pattern.position;
				pattern.position	+= 5 * mod.numChannels - 1;
				if (pattern.position	>= pattern.length)
				{
					// if next row exceeds current pattern
					var nextPattern:ByteArray
					if ((patternIndex + 1) == mod.songLength)
						nextPattern 		= mod.patterns[mod.patternOrder[0]];
					else
						nextPattern 		= mod.patterns[mod.patternOrder[patternIndex + 1]];
						
					// need to get note from first row of next pattern
					nextPattern.position	= 5 * mod.numChannels - 1;
					chan.nextNote			= nextPattern.readUnsignedByte();
					nextPattern.position	+= 2;
					chan.nextEffect			= nextPattern.readUnsignedByte();
				}
				else
				{
					// check the note and effect command of next channel
					chan.nextNote			= pattern.readUnsignedByte();
					pattern.position 		+= 2;
					chan.nextEffect			= pattern.readUnsignedByte();
				}
				
				// return to original pattern position
				pattern.position	= tempPos;
				
				// read instrument column
				var inst:int		= pattern.readUnsignedByte();
				
				// read volume column command
				chan.volumeCommand	= pattern.readUnsignedByte();
				
				// read effect column command
				chan.effect			= pattern.readUnsignedByte();
				chan.parameter		= pattern.readUnsignedByte();
				
				// ignore next instrument command when porta to note effect is triggered THIS or NEXT ROW
				if (chan.effect == 0x3)
					chan.ignoreInstrument = true;
				else
					chan.ignoreInstrument = false;
				
				if (chan.nextEffect == 0x3)
					chan.ignoreNextInstrument = true;
				else
					chan.ignoreNextInstrument = false;
					
				if (chan.parameter > 0)
					chan.oldParameter = chan.parameter;
				
				if (inst > 0 && chan.note < 97 && !chan.ignoreInstrument)
				{
					chan.wavePos		= 0.0;
					chan.volEnvPos		= 0;
					chan.panEnvPos		= 0;
					chan.lastIndex		= 0;
					chan.nextIndex		= 1;
					chan.targetVolume	= 1.0;
					chan.instrument		= mod.instruments[int(inst - 1)];
					
					if (chan.instrument.numSamples > 0)
					{
						chan.wave			= chan.instrument.waves[chan.instrument.smpNotes[chan.note]]; 
						chan.waveLength		= Number(chan.wave.length) - 1;
						chan.loopStart		= Number(chan.wave.loopStart);
						chan.loopEnd		= Number(chan.wave.loopEnd);
						chan.loopLength		= Number(chan.wave.loopLength);
						chan.waveData		= chan.wave.samples;
						chan.waveList		= chan.wave.sampleList;
						chan.waveVolume		= chan.wave.volume;
						chan.wavePanning	= chan.wave.panning;
						chan.waveType		= chan.wave.type;
					}
				}
					
				// process note command
				if (chan.note > 0)
				{
					if (chan.note < 97)
					{
						if (!chan.ignoreInstrument)
						{
							chan.wavePos		= 0.0;
							chan.lastIndex		= 0;
							chan.nextIndex		= 1;
							chan.volEnvPos		= 0;
							chan.panEnvPos		= 0;
						}
						
						if (chan.wave != null)
						{
							chan.realNote		= chan.note + chan.wave.relNote;
						
							chan.keyDown 		= true;
							chan.fadeout		= 1.0;
							chan.volumeTabIndex	= 0x40;
							chan.columnVolume	= 1.0;
							
							// calculate period and/or target period
							if (chan.effect == 0x3)
							{
								chan.oldPeriod		= chan.period;
								chan.targetPeriod	= 7680 - (chan.realNote-1) * 64 - (chan.wave.finetune * 0.5);
							}
							else
							{
								chan.period			= 7680 - (chan.realNote-1) * 64 - (chan.wave.finetune * 0.5);
								chan.oldPeriod		= chan.period;
							}
							
							// calculate wave step length from period
							chan.waveStep 		= 0.189637188 * Math.pow(2, ((4608 - chan.period) * 1.3020833333333e-3));
						}else {
							chan.waveStep		= 0.0;
						}
					}else {
						chan.keyDown 		= false;
						
						if (chan.instrument != null)
						{
							if (!chan.instrument.volON)
								chan.columnVolume 	= 0.0;
						}
					}
					chan.vibtime			= 0;
				}
				
				// volume column
				if (chan.volumeCommand > 0xF && chan.volumeCommand < 0x51)
				{
					chan.volumeTabIndex = chan.volumeCommand - 0x10
					chan.columnVolume 	= VOL_TAB_LIN[chan.volumeTabIndex];
				}
				
				chan.targetVolume	= chan.waveVolume * chan.columnVolume;
			}
		}
		
		private function perTickProcessing():void
		{
			for (var i:int = 0; i < mod.numChannels; i++)
			{
				chan 				= mod.channels[i];
				
				// volume commands
				if (chan.volumeCommand > 0x50)
				{
					if ((chan.volumeCommand & 0xF0) == 0x60)		// Volume slide down
					{
						if ((chan.volumeTabIndex -= (chan.volumeCommand & 0xF)) < 0)
							chan.volumeTabIndex = 0;
							
						chan.columnVolume	= VOL_TAB_LIN[chan.volumeTabIndex];
					}
					else if ((chan.volumeCommand & 0xF0) == 0x70)	// Volume slide up
					{
						if ((chan.volumeTabIndex += (chan.volumeCommand & 0xF)) > 64)
							chan.volumeTabIndex = 64;
							
						chan.columnVolume	= VOL_TAB_LIN[chan.volumeTabIndex];
					}
					else if ((chan.volumeCommand & 0xF0) == 0x80)	// Fine volume slide down
					{
						if (tickCnt == 0)
						{
							if ((chan.volumeTabIndex -= (chan.volumeCommand & 0xF)) < 0)
								chan.volumeTabIndex = 0;
								
							chan.columnVolume	= VOL_TAB_LIN[chan.volumeTabIndex];
						}
					}
					else if ((chan.volumeCommand & 0xF0) == 0x90)	// Fine volume slide up
					{
						if (tickCnt == 0)
						{
							if ((chan.volumeTabIndex += (chan.volumeCommand & 0xF)) > 64)
								chan.volumeTabIndex = 64;
								
							chan.columnVolume	= VOL_TAB_LIN[chan.volumeTabIndex];
						}
					}
					else if ((chan.volumeCommand & 0xF0) == 0xA0)
					{
						// TODO:	Set vibrato speed
					}
					else if ((chan.volumeCommand & 0xF0) == 0xB0)
					{
						// TODO:	Vibrato
					}
					else if ((chan.volumeCommand & 0xF0) == 0xC0)	// Set panning
					{
						chan.wavePanning	= Number(chan.volumeCommand & 0xF) * 6.25e-2
					}
					else if ((chan.volumeCommand & 0xF0) == 0xD0)	
					{
						// TODO:	Panning slide left
					}
					else if ((chan.volumeCommand & 0xF0) == 0xE0)
					{
						// TODO:	Panning slide right
					}
					else if ((chan.volumeCommand & 0xF0) == 0xF0)
					{
						// TODO:	Tone Porta
					}
				}
				
				chan.targetVolume	= chan.waveVolume * chan.columnVolume;
				chan.targetPanning 	= chan.wavePanning
				
				// EFFECTS
				if (chan.effect == 0x0)
				{
					//TODO: implement arpeggio
				}
				else if (chan.effect == 0x1)	// portamento up
				{
					if (chan.parameter == 0)
						chan.parameter 	= chan.oldParameter;
					if (tickCnt > 0)
						chan.period 	-= int(Number(chan.parameter) * 4);
					chan.waveStep 		= 0.189637188 * Math.pow(2, ((4608 - chan.period) * 1.3020833333333e-3));
				}
				else if (chan.effect == 0x2)	// portamento down
				{
					if (chan.parameter == 0)
						chan.parameter 	= chan.oldParameter;
					if (tickCnt > 0)
						chan.period 	+= int(Number(chan.parameter) * 4);
					chan.waveStep 		= 0.189637188 * Math.pow(2, ((4608 - chan.period) * 1.3020833333333e-3));
				}
				else if (chan.effect == 0x3)	// tone portamento
				{
					if (chan.parameter == 0)
						chan.parameter = chan.oldParameter;
					
					if (chan.oldPeriod >= chan.targetPeriod)
					{
						chan.period		= chan.oldPeriod;
						if (tickCnt > 0)
						{
							if ((chan.period -= int(Number(chan.parameter) * 4)) < chan.targetPeriod)
								chan.period = chan.targetPeriod;
						}
					}else {
						chan.period		= chan.oldPeriod;
						if (tickCnt > 0)
						{
							if ((chan.period += int(Number(chan.parameter) * 4)) > chan.targetPeriod)
								chan.period = chan.targetPeriod;
						}
					}
					chan.oldPeriod		= chan.period;
					chan.waveStep 		= 0.189637188 * Math.pow(2, ((4608 - chan.period) * 1.3020833333333e-3));
				}
				else if (chan.effect == 0x4)	// vibrato
				{
					if (chan.parameter == 0)
						chan.parameter = chan.oldParameter;
						
					chan.vibrate 	= Number((chan.parameter & 0xF0)>>4);
					chan.vibdepth 	= (chan.parameter & 0xF)<<3;
					
					chan.vibtime	+= chan.vibrate * 0.025 * Math.PI;
					
					if (chan.vibform == 0)
						chan.period	= chan.targetPeriod + int(Math.sin(chan.vibtime)*Number(chan.vibdepth));
					else if (chan.vibform == 1)
					{
						//TODO: implement ramp up waveform for vibrato
					}
					else if (chan.vibform == 2)
					{
						//TODO: implement square waveform for vibrato
					}
					chan.waveStep 		= 0.189637188 * Math.pow(2, ((4608 - chan.period) * 1.3020833333333e-3));
				}
				else if (chan.effect == 0x5)
				{
					// TODO: implement Tone porta+Volume slide
				}
				else if (chan.effect == 0x6)
				{
					// TODO: implement Vibrato+Volume slide
				}
				else if (chan.effect == 0x7)
				{
					// TODO: implement Tremolo
				}
				else if (chan.effect == 0x8)	// Set panning
				{
					chan.wavePanning	= Number(chan.parameter) * 3.90625e-3;
				}
				else if (chan.effect == 0x9)	// Sample offset
				{
					chan.wavePos 	+= chan.parameter * 0x100;
					if (chan.wavePos > chan.waveLength)
						chan.wavePos = chan.waveLength;
					chan.parameter	= 0;
				}
				else if (chan.effect == 0xA)
				{
					// TODO: implement Volume slide
				}
				else if (chan.effect == 0xB)
				{
					// TODO: implement Position Jump
					// Jumps to the specified song position and play the pattern from the beginning
				}
				else if (chan.effect == 0xC)
				{
					// TODO: implement Set Volume
					// Ex:	C-5 1 --[C40]-> Plays the sample at volume $40
					//		---   -- C10 -> Changes the volume to $10
					// NOTE: The volume can't be greater than $40 If no volume is specified the sample will be played at defined volume in the instrument editor (see 4.xxx)
				}
				else if (chan.effect == 0xD)	// pattern break
				{
					if (tickCnt == 0)
					{
						patternIndex++;
						if(patternIndex == mod.songLength)
							patternIndex = mod.restartPos;
						
						pattern = mod.patterns[mod.patternOrder[patternIndex]];
						pattern.position = chan.parameter * 5 * mod.numChannels;
						// TODO: catch array access fault, when target position is outside of pattern length!
					}
				}
				else if (chan.effect == 0xE)
				{
					// E-COMMANDS
					var upperByte:int = chan.parameter & 0xF0;
					if (upperByte == 0x10)
					{
						// TODO: implement Fine Porta up
					}
					else if (upperByte ==  0x20)
					{
						// TODO: implement Fine Porta down
					}
					else if (upperByte ==  0x30)
					{
						// TODO: implement Set glissando control
					}
					else if (upperByte == 0x40)
					{
						// TODO: implement Set vibrato control
					}
					else if (upperByte == 0x50)
					{
						// TODO: implement Set finetune
					}
					else if (upperByte == 0x60)
					{
						// TODO: implement Set loop begin/loop
					}
					else if (upperByte == 0x70)
					{
						// TODO: implement Set tremolo control
					}
					else if (upperByte == 0x90)
					{
						// TODO: implement Retrig note
					}
					else if (upperByte == 0xA0)
					{
						if (chan.parameter == 0)
							chan.parameter = chan.oldParameter;
							
						// TODO: implement Fine volume slide up
					}
					else if (upperByte == 0xB0)
					{
						// TODO: implement Fine volume slide down
					}
					else if (upperByte == 0xC0)	// note cut
					{
						if (tickCnt >= (chan.parameter & 0xF))
						{
							chan.targetVolume	= 0.0;
							chan.columnVolume	= 0;
						}
					}
					else if (upperByte == 0xD0)
					{
						// TODO: implement Note delay
					}
					else if (upperByte == 0xE0)
					{
						// TODO: implement Pattern delay
					}
				}
				else if (chan.effect == 0xF)	// set tempo / BPM
				{	
					if (chan.parameter > 0)
					{
						if (chan.parameter < 0x20)
							mod.tempo 	= chan.parameter;
						else
						{
							mod.bpm		= chan.parameter;	// FT2 manual states: "--- -- F40 -> Sets the tempo to 54 BPM"
							smpTick		= int(110250 / mod.bpm);
						}
					}
				}
				else if (chan.effect == 0x10) 	// set global volume
				{
					gVolume = chan.parameter * 1.5625e-2;
				}
				else if (chan.effect == 0x11)	// global volume slide
				{
					if (chan.parameter == 0)
						chan.parameter = chan.oldParameter;
						
					if ((chan.parameter & 0xF0) > 0)
						gVolume += Number(chan.parameter >> 4) * 0.0625 / Number(mod.tempo);
					else
						gVolume -= Number(chan.parameter) * 0.0625 / Number(mod.tempo);
					if (gVolume > 1.0)
						gVolume = 1.0;
					if (gVolume < 0.0)
						gVolume = 0.0;
				}
				else if (chan.effect == 0x15)
				{
					//TODO: implement Set envelope position
				}
				else if (chan.effect == 0x19)
				{
					//TODO: implement Panning slide
				}
				else if (chan.effect == 0x1B)	// Multi retrig note
				{
					if (chan.parameter == 0)
						chan.parameter = chan.oldParameter;
						
					if (tickCnt % (chan.parameter & 0xF) == 0)
					{
						//chan.volEnvPos = 0;
						//chan.panEnvPos = 0;
						chan.wavePos = 0;
					}
					
					// volume change
					var volChange:int	= chan.parameter >> 4;
					if (volChange == 1)
						chan.targetVolume -= 1.5625e-2;
					else if (volChange == 0x2)
						chan.targetVolume -= 3.125e-2;
					else if (volChange == 0x3)
						chan.targetVolume -= 6.25e-2;
					else if (volChange == 0x4)
						chan.targetVolume -= 0.125;
					else if (volChange == 0x5)
						chan.targetVolume -= 0.25;
					else if (volChange == 0x6)
						chan.targetVolume *= 0.666666666666667;
					else if (volChange == 0x7)
						chan.targetVolume *= 0.5;
					else if (volChange == 0x9)
						chan.targetVolume += 1.5625e-2;
					else if (volChange == 0xA)
						chan.targetVolume += 3.125e-2;
					else if (volChange == 0xB)
						chan.targetVolume += 6.25e-2;
					else if (volChange == 0xC)
						chan.targetVolume += 0.125;
					else if (volChange == 0xD)
						chan.targetVolume += 0.25;
					else if (volChange == 0xE)
						chan.targetVolume *= 1.5;
					else if (volChange == 0xF)
						chan.targetVolume *= 2;
						
					// respect volume bounds (0.0 <= volume <= 1.0)
					if (chan.targetVolume < 0.0)
						chan.targetVolume = 0.0;
						
					if (chan.targetVolume > 1.0)
						chan.targetVolume = 1.0;
				}
				else if (chan.effect == 0x1D)
				{
					//TODO: implement Tremor
				}
				else if (chan.effect == 0x21)
				{
					//TODO: implement Extra fine porta up
				}
				else if (chan.effect == 0x22)
				{
					//TODO: implement Extra fine porta down
				}
				
				if (chan.instrument == null)
					continue;
					
				// process volume envelope and fadeout
				if(chan.instrument.volON)
				{
					chan.targetVolume		*= chan.instrument.volumeEnvelope[chan.volEnvPos];
					
					chan.volEnvPos++;
					if (chan.keyDown)
					{
						if (chan.instrument.volSUS)
						{
							if (chan.volEnvPos > chan.instrument.volSustain)
								chan.volEnvPos = chan.instrument.volSustain;
						}
					}else {
						if (chan.fadeout > 0.0)
						{
							chan.fadeout		-= chan.instrument.fadeout * 3.0517578125e-5;
							if (chan.fadeout < 0.0)
								chan.fadeout = 0.0;
								
							chan.targetVolume	*= chan.fadeout;
						}else {
							chan.targetVolume = 0.0;
						}
					}
					
					if (chan.instrument.volLOOP)
					{
						if (chan.volEnvPos >= chan.instrument.volLoopEnd)
							chan.volEnvPos = chan.instrument.volLoopStart;
					}
					else
					{
						if (chan.volEnvPos >= chan.instrument.volEnvLength)
							chan.volEnvPos	= chan.instrument.volEnvLength-1;
					}
				}
				
				// process panning
				if (chan.instrument.panON)
				{
					chan.targetPanning		+= ((chan.instrument.panningEnvelope[chan.panEnvPos]-0.5) * (0.5 - Math.abs(chan.targetPanning-0.5)));
					
					chan.panEnvPos++;
					if (chan.keyDown)
					{
						if (chan.instrument.panSUS)
						{
							if (chan.panEnvPos > chan.instrument.panSustain)
								chan.panEnvPos = chan.instrument.panSustain;
						}
					}
					
					if (chan.instrument.panLOOP)
					{
						if (chan.panEnvPos >= chan.instrument.panLoopEnd)
							chan.panEnvPos = chan.instrument.panLoopStart;
					}
					else
					{
						if (chan.panEnvPos >= chan.instrument.panEnvLength)
							chan.panEnvPos	= chan.instrument.panEnvLength-1;
					}
				}
			}
		}
	}

}