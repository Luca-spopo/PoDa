package pod.map;
import pod.common.Anim;
import pod.common.Gif;
import pod.common.GifData;

/**
 * ...
 * @author Luca
 * 29/12/2014 00:36
 * Im thinking that the eye candy class and this dude (Well, his EntitySprite class) should have common ancestors...
 * Well, even TileSprite now that I think about it...
 * 
 * examples of entites include the player, NPCs, little butterflies in the background, treasure chests... fires...
 */

 /*
  * Each entity will (may?) have it's own spritesheet. This is because of
  * something I am dubbing "Zwinking" (After the annoying Zwinky game)
  * We can mix and match different hair colours, eye colours, clothes,
  * skins etc. To store them in a format appropriate for serialization,
  * I am creating this class: ZwinkyData.
  */
 
private class ZwinkyDataHelper
{
	public var sheet:Int;	//One per layer of zwinky. e.g. a pair of eyes
							//Index given by Mapper.
							//Must belong to the Map's entityRequest thing
	public var gifData:GifData;	//And it's animations and offsets.
	
	public var gif:Gif; //No problem having the actual Gif here too, right?
	
	/*
	 * In the current model, each gifData will have to have an equal number
	 * of anims and frames for each anim. The times should also be equal for
	 * it to make any sense.
	 * 
	 * Currently working on a gif class. (EDIT: Done, check "Gif.animateByTime") Then the number of anims will still be equal, but
	 * the frames don't have to be. Instead of animate function taking "frames left", it will take
	 * "intervals passed". Then, things like "cap" that need only 2 frames per walk cycle,
	 * will not get redundant frames.
	 * 
	 * You will still need to make sure the total interval for a particular animation is
	 * suitable in all the gifdatas so that they sync up.
	 * 
	 * ...wait, so you plan to make a new Gif object for every ZwinkyDataHelper?
	 * Well, that's ok, but you will be calling a timHandler for *each* ZwinkyDataHelper
	 * which is going to be very slow.
	 * Inline it m8
	 * Inline doesn't work as expected... If there is massive lag, try doing something
	 * about these propogated timHandlers... maybe each propogating element can carry
	 * an array of functions (timHandlers) which they get by concating the ones from
	 * their children. So when timHandler is run on a root element, it executes the
	 * functions of the children through the array rather than asking them to do it
	 * themselves.
	 */
	
}
  
//May want to rename to just "Zwinky"
typedef ZwinkyData = Array<ZwinkyDataHelper>;

class PathData
{
	public var destination:Coord;
	public var acceptable_closeness:Float;
	public var run_to:Bool;
	public var min_stop_time:Int;
	public var max_stop_time:Int;
	public var next:Array<Int>;
}
/*If children are running in a circle, then min_stop = max_stop = 0, and run_to = true, and the "next" will always have the next node in the circle.
 * In such a case, when the stop time is lower than a certain value, the run/walk would never change to a walk/stand. This is because they
 * will "touch and go". Program accordingly.
 * 
 * Also, "acceptable_closeness" is not "Mission complete when distance < X", it is
 * "Destination = destination + random variation determined by acceptable closeness"
 * It is to make the walks less robotic, by making them a few blocks off randomly.
 * 
 * min and max stop time determine how long one can loiter there.
 */

class EntitySprite
{
	public var template:EntityTemplate;
	public var index:Int;	//Position in the entity index. Used to dump to tile.
	public var xpos:Int;
	public var ypos:Int;	//Position (tile)
	public var xposF:Float;
	public var yposF:Float;	//Position on the tile.
	public var trigger(default, null):Trigger;
	public var anim:Int; //Animation number in progress
	public var freeze:Bool; //Animation currently frozen or not
	public var paths:Array<PathData>;
	public var zwinkyData(default, null):ZwinkyData;
	public function new(_index:Int, _xpos:Int, _ypos:Int, _zwinkyData:ZwinkyData, _template:EntityTemplate) 
	{
		template = _template;
		zwinkyData = _zwinkyData;
		index = _index;
		xpos = _xpos;
		ypos = _ypos;
	}
	
	public function timHandler()
	{
		//WIP: This
		if(!freeze)
		{
			for (i in zwinkyData)
			{
				i.gif.timHandler();
			}
		}
	}
	
	public function animate(an:Int, time:Int, freeze:Bool)
	{
		for (i in zwinkyData)
			i.gif.animByTime(an, -time, freeze);
	}	
}