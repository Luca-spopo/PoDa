/*
 @Author: Luca
 12/2014
 katoch.anirudh@gmail.com
 Do not copy
 */

package pod.map ;

import pod.common.Gif;
import pod.map.TileTemplate;
import pod.map.Trigger;
import pod.common.GifData;
import pod.Main;


//A fixed number of these are supposed to be on the mapper, this is what localmap should be made of
//However, these are not the actual display objects. The display objects would be the class "Gif.hx", which is an extension of bitmap.
//Update: Gif is not exactly an extension of bitmap. All rendering is done using batch spriting. Details of Gif are in Gif class.

class TileSprite
{
	//Shouldn't it contain a pointer to the actual Tile it is representing?	//It actually contains more data than a tile, so no need...
	public var template(default, null):TileTemplate;
	public var entities(default, null):Array<EntitySprite>;
	public var entitiesForTile:Array<Int>;	//Only used to dump info in the tiles while unloading
	public var trigger:Trigger;	//use trigger.doo=function(){do stuff; this.doo=null} to make them self-disabling, probably
	public var los:Int;
	
	//for foreground
	public var fg:Gif;
	/*Caching the gif's properties turned out to be a maintainance nightmare (and premature optimization)
	 * Consider doing it AFTER everything is complete.
	 * Not adding a TODO, because not really needed.
	 */
	
	//for background
	public var bg:Gif;
	
	public var fgoffsetX:Int;
	public var fgoffsetY:Int;
	//DEBUG: Make this (default, null)
	
	public var ascii:Int;
	//DEBUG: Used for ascii rendering, remove later.
	
	
	public var soundtype(default, null):Int;
	
	public function new ()
	{
//		entityx=0;
//		entity=0;
		los = -1;
		bg = new Gif();
		fg = new Gif();
	}
	
	public function setTemplate(temp:TileTemplate, ba:Int, bfr:Int, btl:Int, bf:Bool, fa:Int, ffr:Int, ftl:Int, ff:Bool  )
	{
		template = temp;
		bg.setGifData(temp.bg, ba, bfr, btl, bf);
		fg.setGifData(temp.fg, fa, ffr, ftl, ff);
		soundtype = temp.soundtype;
		
	}
	
	public inline function timHandler()
	{
		
		fg.timHandler();
		bg.timHandler();
	}
	
}
