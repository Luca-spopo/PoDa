/*
 @Author: Luca
 12/2014
 katoch.anirudh@gmail.com
 Do not copy
 */

package pod.map ;

//Purpose: Stores all the data for a type of tile, a collection of these would be a tileset.

//Any changes should be accounted for in Mapper.toTileSprite(Tile)

import pod.common.GifData;

class TileTemplate
{
	public var col(default, null):Array<Int>; //COLLISION, 0 to 3, clockwise from top. 0=free 1=blocked 2=water 3=lava 4=chasm, 5=marsh etc 
	public var fg(default, null):GifData; //MAY BE NULL (but why?) (because foreground images are optional.)
	public var bg(default, null):GifData;
	
	//TODO: Stalker gif
	//TODO: Stalker filter
	//TODO: Y Depth (Camera should follow this too)
	//TODO: Blur area and amount (Entities above it will have Blur filter applied with amount X up to Y pixels above their bottom).
	//TODO: Entity function (static function triggered when entity steps on it.
	// func(entity, tile){}
	

	
//	public var animbg(default, null):Bool;	//Original intent was to keep this as a check before even trying to play the "gif", but I guess you may wanna give this job to TileData.
//	public var animfg(default, null):Bool;
	public var battlechance(default, null):Float; //Actual battle chance = this * Map's difficulty. Map's difficulty is 1 by default, but reduced when enough grinding is done. bchance = -1 will always trigger, even if Map's difficulty is 0
	public var soundtype(default, null):Int; //0=no sound, 1=dirt/grass, 2=water, 3=metal etc. Actual sound will depend on the entity too (e.g. if entity is heavy/robot/has wheels)
	public var battletemplates(default, null):Array<Int>; //Indexes of battle templates possible on this tile, taken from parent Map. Can only be null if bchance == 0, Int type should not be a problem, since it is not called often, infact it might save some trouble
	
	
	//Battles are dependent on the tile being walked on (Like pokemon), not just the map (like Mardek)
	
	public function new (background:GifData, foreground:GifData, coln:Int, cole:Int, cols:Int, colw:Int, sound:Int=0, bchance:Float=0, btem:Array<Int>=null)
	{
		col = new Array<Int>();
		col[0] = coln; //Add validation for collision modes once you have a full list.
		col[1] = cole;
		col[2] = cols;
		col[3] = colw;
		fg = (foreground);
		bg = (background);
		soundtype = sound;
		battlechance = bchance;
		
		if(bg==null)
		{
			Main.console.stdOut("Bad BG @ TileTemplate", 2);
		}
		
		if(bchance!=0 && btem==null)
		{
			Main.console.stdOut("Bad battletemplates @ TileTemplate", 2);
		}
		
		
	}
}
