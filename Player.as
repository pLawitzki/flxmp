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
	import flash.events.SampleDataEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.utils.ByteArray;
	import org.flashdevelop.utils.FlashConnect;
	
	public class Player
	{
		private var mod:Module;
		private var sound:Sound;
		private var soundChannel:SoundChannel;
		private var bufferL:Vector.<Number>;
		private var bufferR:Vector.<Number>;
		private var tickCnt:int;
		private var smpTick:int;
		private var smpDone:int;
		private var chan:Channel;
		private var pattern:ByteArray;
		private var patternIndex:int;
		private var gVolume:Number;
		private var playing:Boolean;
		private var channelPos:int;
		
		// helper variables
		private var smpIncrement:int;
		private var i:int;
		private var j:int;
		private var sample:Number;
		private var lastPos:int;
		private var nextPos:int;
		private var lastValue:Number;
		private var nextValue:Number;
		
		public function Player(InitModule:Module) 
		{
			mod					= InitModule;
			sound 				= new Sound();
			bufferL 			= new Vector.<Number>(8192, true);
			bufferR 			= new Vector.<Number>(8192, true);
			tickCnt 			= 0;
			smpTick 			= int(110250 / mod.bpm);
			patternIndex		= 0;
			pattern				= mod.patterns[mod.patternOrder[patternIndex]];
			pattern.position	= 0;
			gVolume				= 1.0;
			playing				= false;
			channelPos			= 0;
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
			smpIncrement 	= 0;
			lastPos 		= 0;
			nextPos 		= 0;
			
			smpDone = 0;
			smpIncrement = smpTick;
			while(smpDone < 8192)
			{
				if (++tickCnt == mod.tempo)
				{
					tickCnt = 0;
					nextRow();
				}
				perTickProcessing();
				
				if ((smpDone + smpIncrement) > 8192)
					smpIncrement = 8192 - smpDone;
				
				nextPos = lastPos + smpIncrement;
					
				for (j = lastPos; j < nextPos; j++)
				{
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
							
						//TODO: try to move this somewhere outside the sample processing loop
						if ((tickCnt == (mod.tempo - 1)) && chan.nextNote != 0 && chan.nextNote < 97)
							chan.targetVolume	= 0.0;
							
						// volume ramping
						if (chan.volume != chan.targetVolume)
						{
							if (chan.volume > chan.targetVolume)
							{
								if ((chan.volume 	-= 5e-3) < chan.targetVolume)
									chan.volume		= chan.targetVolume;
							}else {
								if ((chan.volume		+= 5e-3) > chan.targetVolume)
									chan.volume		= chan.targetVolume;
							}
						}else {
							if (chan.volume == 0.0)
							{
								chan.wavePos	= 0.0;
								continue;
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
						
						lastValue	= chan.waveData[chan.lastIndex];
						nextValue	= chan.waveData[chan.nextIndex];
						sample		= lastValue + (nextValue - lastValue) * (chan.wavePos - Number(int(chan.wavePos)));
						sample		*= gVolume;
						sample		*= chan.volume;
						
						bufferL[j] += sample * (1.0 - chan.panning);
						bufferR[j] += sample * chan.panning;
						
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
					}
				}
				smpDone += smpIncrement; 
				lastPos = nextPos;
			}
			
			for (i = 0; i < 8192; i++)
			{
				e.data.writeFloat(bufferL[i]);
				bufferL[i] = 0.0;
				e.data.writeFloat(bufferR[i]);
				bufferR[i] = 0.0;
			}
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
				}
				else
					chan.nextNote			= pattern.readUnsignedByte();
					
				pattern.position	= tempPos;
				
				// read new instrument
				var inst:int		= pattern.readUnsignedByte();
				if (inst > 0 && chan.note < 97)
				{
					chan.wavePos		= 0.0;
					chan.volEnvPos		= 0;
					chan.panEnvPos		= 0;
					chan.lastIndex		= 0;
					chan.nextIndex		= 1;
					chan.instrument		= mod.instruments[int(inst - 1)];
					
					if (chan.instrument.numSamples > 0)
					{
						chan.wave			= chan.instrument.waves[chan.instrument.smpNotes[chan.note]]; 
						chan.waveLength		= Number(chan.wave.length) - 1;
						chan.loopStart		= Number(chan.wave.loopStart);
						chan.loopEnd		= Number(chan.wave.loopEnd);
						chan.loopLength		= Number(chan.wave.loopLength);
						chan.waveData		= chan.wave.samples;
						chan.waveVolume		= chan.wave.volume;
						chan.wavePanning	= chan.wave.panning;
						chan.waveType		= chan.wave.type;
					}
				}
					
				chan.volumeCommand	= pattern.readUnsignedByte();
				chan.effect			= pattern.readUnsignedByte();
				
				chan.parameter		= pattern.readUnsignedByte();
				if (chan.parameter > 0)
					chan.oldParameter = chan.parameter;
					
				// process note command
				if (chan.note > 0)
				{
					if (chan.note < 97)
					{
						chan.wavePos		= 0.0;
						chan.lastIndex		= 0;
						chan.nextIndex		= 1;
						chan.realNote		= chan.note + chan.wave.relNote;
						chan.keyDown 		= true;
						chan.fadeout		= 1.0;
						chan.volEnvPos		= 0;
						chan.panEnvPos		= 0;
						chan.columnVolume	= 1.0;
						chan.oldPeriod		= chan.period;
						chan.period			= 7680 - (chan.realNote-1) * 64 - (chan.wave.finetune * 0.5);
						chan.targetPeriod	= chan.period;
						chan.waveStep 		= 0.189637188 * Math.pow(2, ((4608 - chan.period) * 1.3020833333333e-3));
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
						chan.columnVolume 	= Number((0x10 - chan.volumeCommand) / 0x40);
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
					if ((chan.volumeCommand & 0xF0) == 0x60)
					{
						// TODO:	Volume slide down
					}
					else if ((chan.volumeCommand & 0xF0) == 0x60)
					{
						// TODO:	Volume slide up
					}
					else if ((chan.volumeCommand & 0xF0) == 0x70)
					{
						// TODO:	Volume slide down
					}
					else if ((chan.volumeCommand & 0xF0) == 0x80)
					{
						// TODO:	Fine volume slide down
					}
					else if ((chan.volumeCommand & 0xF0) == 0x90)
					{
						// TODO:	Fine volume slide up
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
							chan.targetVolume	= 0.0;
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
							mod.bpm		= chan.parameter - 10;	// FT2 manual states: "--- -- F40 -> Sets the tempo to 54 BPM"
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
						chan.targetVolume = 0.0;
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