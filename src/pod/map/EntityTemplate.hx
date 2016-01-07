package pod.map;
import haxe.ds.Vector;
import pod.common.Anim;

/**
 * ...
 * @author Luca
 * 29/12/2014 13:53
 * 
 * All entities will have the methods for movement. The overhead is not too much.
 * 
 * People will wear clothes, hair colour, eye colour etc that
 * are subject to randomization and mix-matching. Each such element
 * will be stored as a gif.
 * 
 * 2 Methods in mind for the animations:
 * 1) All entities *can* have multiple gifs that need
 * to be animated together.Usually they have one.
 * They will be stored as an array, along with offset
 * data (not delegated to GifData class), and applied one by one for every frame of animation.
 * 2) One gif per EntityData, but the gif will be generated
 * taking multiple gifs during initialization and drawing them in.
 * (i.e. dynamic spritesheets)
 * 
 * Obviously method 2 is superior in speed but relies on
 * garbage to remove abandoned gifs, and method 1 is slower
 * 
 * 
 * Update: The Zwinky system in EntitySprite suggests that method 1 is being implemented, not 2
 * Also, in the case of method 2, any change of clothes would result in the tilesheet
 * being abandoned, a new one being created with the new spritesheet, and the map being
 * re-rendered. The TilesheetData class would also need a system to remember
 * where it stitched a spritesheet so that it may replace it.
 * Change of clothes is not that often, so this might not be terrible, but surely
 * method 1 cannot be *that* slow. I mean, how many Zwinkys will an entity have?
 * 5 or 6 at max I say, and we are already rendering 2000+ tiles on a max LOS render
 * Even 50 entities on the map would add 300 more tiles at most, and 50 is a far-fetched
 * number.
 * 
 * I do not know which will result in a smaller texture file for the tilesheet though.
 * Method 1 will require a large fixed area of bitmapdata, while method 2's consumption
 * depends on the number of unique looking entities on the map.
 * Method 1 seems to be more predictable and accountable in this accord, and unlike
 * method 2 it will also not discourage randomization of villagers etc.
 * 
 * The texture consumption thing in the end comes down to the number of zwinky's in
 * the game vs unique looking characters per map. Since I don't think we will make too
 * many kinds of zwinky's and we can use hue-changes etc to cause certain variations,
 * I think method 1 wins.
 * 
 * Going forward with method 1: Zwinkys
 * 
 */

class PoDaSound
{
	//DEBUG: Placeholder wrapper for sounds.
}
 
class EntityTemplate
{
	public var ghost(default, null):Int;	//0 = block all, 1 = solid, 2 = ghost, 3=candy
	public var shadowDistance(default, null):Float; //non-0 for flying/floating entities. Tile dependant shadow is tricky because of overlaps when standing on edge
	public var soundlist:Array<PoDaSound>;
	//public var animations(default, null):Array<Anim>;
	private var walkModes(default, null):Vector<Bool>;	//if walkModes[0] is true, it can walk on grass etc. See TileTemplate.col
	public var radius:Float;	//This is used by the collision checker. Don't want just the center to be checked, since we allow fractional movement.
								//This assumes all entities are circular, since entities can turn. We do not want to prevent turning.
	
	public function new()
	{
		
	}
	
}