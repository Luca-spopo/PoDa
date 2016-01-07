/*
 @Author: Luca
 12/2014
 katoch.anirudh@gmail.com
 Do not copy
 */

//REDOING THE WHOLE THING
//Only leave template-ish stuff here. All tile specific actions will now be handled by Tile.hx
//Formerly known as TileData.hx
//purpose: Stores data for animations and some degree of programmable random animations. Used by TileTemplate and Gif. Maybe also TileSprite.hx
//One GifData is a collection of sequential animations ("Anim"s), that can play one after the other not neccesarrily in a sequence
//Mind the bad spellings, if any, Luca needs spellcheck

package pod.common ;


import pod.common.Anim;

private typedef Anims = Array<Anim>;

class GifData
{
	public var anims(default, null):Anims;
	public var base(default, null):Int;
	public function new (nanims:Anims)
	{
		if(nanims==null) Main.console.stdOut("Bad args at GifData.new", 2);
		anims = nanims;
		base = 0;
	}
	
	public function copy()
	{
		var data = new GifData(anims);
		data.setbase(base);
		return data;
	}
	
	//Base is relative to the tilesheet.
	
	public function setbase(nbase:Int)
	{
	/*	for (i in anims)
		{
			i.setbase(nbase-base);
		}
	*/	base = nbase;
	}
	
	public function addbase(nbase:Int)
	{
	/*	for (i in anims)
		{
			i.setbase(nbase);
		}
	*/	base += nbase;
	}
	
}