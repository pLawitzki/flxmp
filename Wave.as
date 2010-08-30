package flxmp
{
	import flash.display.Shape;
	public class Wave
	{
		public var name:String;
		public var samples:Vector.<Number>;
		public var length:int;
		public var loopStart:int;
		public var loopLength:int;
		public var loopEnd:int;
		public var volume:Number;
		public var finetune:Number;
		public var sixteenbit:Boolean;
		public var type:int;
		public var panning:int;
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