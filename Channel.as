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
		public var targetVolume:Number;
		public var tempVol:Number;
		public var volumeCommand:int;
		public var volL:Number;
		public var volR:Number;
		public var fadeout:Number;
		public var panEnvPos:int;
		public var volEnvPos:int;
		public var effect:int;
		public var parameter:int;
		public var oldParameter:int;
		public var wave:Wave;
		public var waveData:Vector.<Number>;
		public var waveType:int;
		public var wavePos:Number;
		public var waveVolume:Number;
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
		public var rampOffset:Number;
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
			waveData.push(0.0);
			loopStart	= 0.0;
			loopEnd		= 1.0;
			loopLength	= 1.0;
			waveType	= 0;
			keyDown		= false;
			rampOffset	= 0.0;
			waveReverse	= false;
			fadeout		= 1.0;
			volL		= 0.5;
			volR		= 0.5;
			volEnvPos	= 0;
			panEnvPos	= 0;
			vib			= false;
			vibdepth	= 0;
			vibrate		= 0.0;
			vibform		= 0;
			vibtime		= 0.0;
			volume		= 0.0;
			targetVolume = 0.0;
		}
		
	}

}