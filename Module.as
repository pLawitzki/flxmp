package flxmp
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import org.flashdevelop.utils.FlashConnect;
	
	public class Module
	{
		public var numChannels:int;
		public var songLength:int;
		public var restartPos:int;
		public var defaultTempo:int;
		public var defaultBPM:int;
		public var bpm:int;
		public var tempo:int;
		public var patternOrder:Vector.<uint>;
		public var instruments:Vector.<Instrument>;
		public var patterns:Vector.<ByteArray>;
		
		public var channels:Vector.<Channel>;
		
		public function Module(ModuleBin:Class) 
		{
			var i:int, j:int, k:int;
			var bytes:ByteArray = new ModuleBin() as ByteArray;
			var headerSize:uint;
			var numPatterns:uint;
			var numInstruments:uint;
			
			bytes.endian = Endian.LITTLE_ENDIAN;
			
			bytes.position 	= 60;
			headerSize 		= bytes.readUnsignedInt();
			songLength 		= bytes.readUnsignedShort();
			restartPos 		= bytes.readUnsignedShort();
			numChannels 	= bytes.readUnsignedShort();
			numPatterns		= bytes.readUnsignedShort();
			numInstruments	= bytes.readUnsignedShort();
			
			bytes.position 	= 76;
			defaultTempo	= bytes.readUnsignedShort();
			defaultBPM		= bytes.readUnsignedShort();
			bpm				= defaultBPM;
			tempo			= defaultTempo;
			
			patternOrder = new Vector.<uint>(songLength, true);
			for (i = 0; i < songLength; i++)
				patternOrder[i] = bytes.readUnsignedByte();
				
			bytes.position	= (headerSize + 60);
			
			channels		= new Vector.<Channel>(numChannels, true);
			for (i = 0; i < numChannels; i++)
				channels[i]	= new Channel(this);
				
			patterns		= new Vector.<ByteArray>(numPatterns, true);
			for (i = 0; i < numPatterns; i++)
			{
				var headerLength:uint	= bytes.readUnsignedInt();
				bytes.position++;
				var numRows:uint 		= bytes.readUnsignedShort();
				var dataSize:uint		= bytes.readUnsignedShort();
				patterns[i] = new ByteArray();
				for (j = 0; j < dataSize; j++)
				{
					var byte:uint = bytes.readUnsignedByte();
					if ((byte & 0x80) > 0)
					{
						var packMask:uint = 0x1;
						for (k = 0; k < 5; k++)
						{
							if ((byte & packMask) > 0)
							{
								patterns[i].writeByte(bytes.readUnsignedByte());
								j++;
							}else {
								patterns[i].writeByte(0);
							}
							packMask = packMask << 1;
						}						
					}else {
						patterns[i].writeByte(byte);
						patterns[i].writeByte(bytes.readUnsignedByte());
						patterns[i].writeByte(bytes.readUnsignedByte());
						patterns[i].writeByte(bytes.readUnsignedByte());
						patterns[i].writeByte(bytes.readUnsignedByte());
						j += 4;
					}
				}
			}
			
			
			instruments = new Vector.<Instrument>(numInstruments, true);
			for (i = 0; i < numInstruments; i++)
			{
				var offset:int				= bytes.position;
				
				instruments[i] 				= new Instrument();
				var instrumentSize:uint 	= bytes.readUnsignedInt();
				instruments[i].name			= bytes.readMultiByte(22, "us-ascii");
				bytes.position++;
				instruments[i].numSamples	= bytes.readUnsignedShort();
				
				if (instruments[i].numSamples > 0)
				{
					var smpHeadSize:int			= bytes.readUnsignedInt();
					
					for (j = 0; j < 96; j++)
						instruments[i].smpNotes[j] = bytes.readUnsignedByte();
					var volEnvX:Vector.<int> 	= new Vector.<int>(12, true);
					var volEnvY:Vector.<int> 	= new Vector.<int>(12, true);
					var volPanX:Vector.<int> 	= new Vector.<int>(12, true);
					var volPanY:Vector.<int> 	= new Vector.<int>(12, true);
					for (j = 0; j < 12; j++)
					{
						volEnvX[j] 				= bytes.readUnsignedShort();
						volEnvY[j]				= bytes.readUnsignedShort();
					}
					for (j = 0; j < 12; j++)
					{
						volPanX[j] 				= bytes.readUnsignedShort();
						volPanY[j]				= bytes.readUnsignedShort();
					}
					var numVolEnvPts:uint		= bytes.readUnsignedByte();
					var numPanEnvPts:uint		= bytes.readUnsignedByte();
					
					var fstX:int, fstY:int, sndX:int, sndY:int;
					var pointIndex:int;
					if (numVolEnvPts > 0)
					{
						instruments[i].volumeEnvelope 	= new Vector.<Number>(volEnvX[numVolEnvPts - 1], true); 
						instruments[i].volEnvLength		= instruments[i].volumeEnvelope.length;
						pointIndex = 0;
						for (j = 0; j < instruments[i].volumeEnvelope.length; j++)
						{
							if (j > sndX)
								pointIndex++;
							fstX = volEnvX[pointIndex];
							fstY = volEnvY[pointIndex];
							sndX = volEnvX[pointIndex + 1];
							sndY = volEnvY[pointIndex + 1];
							instruments[i].volumeEnvelope[j] = (fstY + ((sndY - fstY) / (sndX - fstX)) * (j - fstX))/64;
						}
					}
					if (numPanEnvPts > 0)
					{
						instruments[i].panningEnvelope 	= new Vector.<Number>(volPanX[numPanEnvPts - 1], true);
						instruments[i].panEnvLength		= instruments[i].panningEnvelope.length;
						pointIndex = 0;
						for (j = 0; j < instruments[i].panningEnvelope.length; j++)
						{
							if (j > sndX)
								pointIndex++;
							fstX = volPanX[pointIndex];
							fstY = volPanY[pointIndex];
							sndX = volPanX[pointIndex + 1];
							sndY = volPanY[pointIndex + 1];
							instruments[i].panningEnvelope[j] = fstY + ((sndY - fstY) / (sndX - fstX)) * (j - fstX);
						}
					}
					
					instruments[i].volSustain		= volEnvX[bytes.readUnsignedByte()];
					instruments[i].volLoopStart		= volEnvX[bytes.readUnsignedByte()];
					instruments[i].volLoopEnd		= volEnvX[bytes.readUnsignedByte()] - 1;
					instruments[i].panSustain		= volPanX[bytes.readUnsignedByte()];
					instruments[i].panLoopStart		= volPanX[bytes.readUnsignedByte()];
					instruments[i].panLoopEnd		= volPanX[bytes.readUnsignedByte()] - 1;
					var volType:int					= bytes.readUnsignedByte();
					if ((volType & 0x1) > 0) instruments[i].volON = true; else instruments[i].volON = false;
					if ((volType & 0x2) > 0) instruments[i].volSUS = true; else instruments[i].volSUS = false;
					if ((volType & 0x4) > 0) instruments[i].volLOOP = true; else instruments[i].volLOOP = false;
					var panType:uint				= bytes.readUnsignedByte();
					if ((panType & 0x1) > 0) instruments[i].panON = true; else instruments[i].panON = false;
					if ((panType & 0x2) > 0) instruments[i].panSUS = true; else instruments[i].panSUS = false;
					if ((panType & 0x4) > 0) instruments[i].panLOOP = true; else instruments[i].panLOOP = false;
					instruments[i].vibType			= bytes.readUnsignedByte();
					instruments[i].vibSweep			= bytes.readUnsignedByte();
					instruments[i].vibDepth			= bytes.readUnsignedByte();
					instruments[i].vibRate			= bytes.readUnsignedByte();
					instruments[i].fadeout			= Number(bytes.readUnsignedShort());
					bytes.position 					+= instrumentSize - 241;
					
					instruments[i].waves			= new Vector.<Wave>(instruments[i].numSamples, true);
					for (j = 0; j < instruments[i].numSamples; j++)
					{
						instruments[i].waves[j]				= new Wave();
						instruments[i].waves[j].length		= bytes.readUnsignedInt();
						instruments[i].waves[j].samples		= new Vector.<Number>(instruments[i].waves[j].length, true);
						instruments[i].waves[j].loopStart	= bytes.readUnsignedInt();
						instruments[i].waves[j].loopLength	= bytes.readUnsignedInt();
						instruments[i].waves[j].loopEnd		= instruments[i].waves[j].loopStart + instruments[i].waves[j].loopLength;
						instruments[i].waves[j].volume		= Number(bytes.readUnsignedByte())/64;
						instruments[i].waves[j].finetune	= Number(bytes.readByte());
						instruments[i].waves[j].type		= bytes.readUnsignedByte();
						if ((instruments[i].waves[j].type & 0x10) > 0) instruments[i].waves[j].sixteenbit = true; else instruments[i].waves[j].sixteenbit = false;
						instruments[i].waves[j].type		= instruments[i].waves[j].type & 0x3;
						instruments[i].waves[j].panning		= bytes.readUnsignedByte();
						instruments[i].waves[j].relNote		= bytes.readByte();
						bytes.position						+= 1;
						instruments[i].waves[j].name		= bytes.readMultiByte(22, "us-ascii");
						bytes.position 						+= (40 - smpHeadSize);
						
						var oldSampleValue:Number = 0.0;
						var newSampleValue:Number;
						if (instruments[i].waves[j].sixteenbit) {
							instruments[i].waves[j].length = instruments[i].waves[j].length >> 1
							for (k = 0; k < instruments[i].waves[j].length; k++) {
								instruments[i].waves[j].samples[k] = bytes.readShort();
								if (oldSampleValue + instruments[i].waves[j].samples[k] < -32768)
									newSampleValue =  oldSampleValue + instruments[i].waves[j].samples[k] + 65536;
								else {
									if(oldSampleValue + instruments[i].waves[j].samples[k] > 32767)
										newSampleValue =  oldSampleValue + instruments[i].waves[j].samples[k] - 65536;
									else
										newSampleValue =  oldSampleValue + instruments[i].waves[j].samples[k];
								}
								instruments[i].waves[j].samples[k] = Number(newSampleValue) * 3.0517578125e-5;
								oldSampleValue = newSampleValue;
							}
						}else {
							for (k = 0; k < instruments[i].waves[j].length; k++) {
								instruments[i].waves[j].samples[k] = bytes.readByte();
								if (oldSampleValue + instruments[i].waves[j].samples[k] < -128)
									newSampleValue =  oldSampleValue + instruments[i].waves[j].samples[k] + 256;
								else 
								{
									if(oldSampleValue + instruments[i].waves[j].samples[k] > 127)
										newSampleValue =  oldSampleValue + instruments[i].waves[j].samples[k] - 256;
									else
										newSampleValue =  oldSampleValue + instruments[i].waves[j].samples[k];
								}
								instruments[i].waves[j].samples[k] = newSampleValue * 0.0078125;
								oldSampleValue = newSampleValue;
							}
						}
					}
					
				}
				else
					bytes.position = offset + instrumentSize;
			}
		}
		
	}

}