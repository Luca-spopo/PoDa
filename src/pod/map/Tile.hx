/*
A "map" would be stored as a 2D array of these.
This stores the data of one individual tile on the map, but is itself independent of the tileset (uses indices only)
Ought to be named "TileData"
*/


package pod.map ;


class Tile
{
	public var template:Int;	//I know you think pointer would be faster, but this thing should be independant of the map. Consider making a "TileSprite" class to take care of rendering optimizations.
	public var entities:Array<Int>;
	public var xpos(default, null):Int;
	public var ypos(default, null):Int;
	public var trigger:Int;
	public var los:Int;
	
	//TODO: Turn the entity pair to entity array. //May be done, WIP
	
	//for foreground
	public var f_anim:Int; //Animation number in progress
	public var f_frame:Int; //Frame number in that animation
	public var f_freeze:Bool; //Animation currently frozen or not
	public var f_time:Int; //Time left until next frame
	
	//for background
	public var b_anim:Int; //Animation number in progress
	public var b_frame:Int; //Frame number in that animation
	public var b_freeze:Bool; //Animation currently frozen or not
	public var b_time:Int;
	
	//I cant imagine a scenario where fg and bg are not frozen or unfrozen TOGETHER, but I'll leave
	//the option here

	//You may be tempted to remove these and put them in the future TileSprite class, but imagine a plant blooming onscreen after a beautiful animation, and it magically closes when even 1 second offscreen. Storing animation isn't bad.
	
	
	
	public function new (xpos:Int, ypos:Int)
	{
		this.xpos=xpos;
		this.ypos=ypos;
		trigger = 0;
		los = -1;
		template = 0;
		b_anim=0;
		b_frame = 0;
		b_time = 1;
		b_freeze=false;
		f_anim=0;
		f_frame=0;
		f_freeze=false;
	}
	
}
