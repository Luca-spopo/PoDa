//Interect with a tile or talk to a party member or something, doo a Trigger!

package pod.map ;

class Trigger
{
	public var touch:Bool;
	public var NPCtriggerable:Int; //0 for all NPCs and players, 1 for NPC only, 2 for allies only etc.
	public var doo:Void->Void;
	public function new (d:Void->Void, t:Bool=false)
	{	
		touch = t;
		doo = d;
	}
}
