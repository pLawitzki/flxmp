// EXPERIMENTAL
package flxmp 
{
	public class MonoListNode
	{
		public var value:Number;
		public var next:MonoListNode;
		public var prev:MonoListNode;
		
		public function MonoListNode(Value:Number = 0.0, Next:MonoListNode = null, Prev:MonoListNode = null) 
		{
			value = Value;
			next = Next;
			prev = Prev;
		}
		
	}

}