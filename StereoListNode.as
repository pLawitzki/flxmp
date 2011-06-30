// EXPERIMENTAL
package flxmp 
{
	public class StereoListNode
	{
		public var left:Number;
		public var right:Number;
		public var next:StereoListNode;
		
		public function StereoListNode(Left:Number = 0.0, Right:Number = 0.0, Next:StereoListNode = null) 
		{
			left = Left;
			right = Right;
			next = Next;
		}
		
	}

}