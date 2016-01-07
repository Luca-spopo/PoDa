//Stores the data for one "map" in the game.

package pod.map ;

import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import pod.map.TileTemplate;
import pod.battle.BattleTemplate;
import pod.map.Tile;
import pod.map.EntitySprite;
import flash.display.MovieClip;
import haxe.ds.StringMap;
import pod.map.Trigger;
import pod.map.Coord;

//TODO: Add screen fg (like bg, but rendered on top). (eg mist).

class Map
{
	public var tileset:Array<TileTemplate>;
	public var sheet:TilesheetData;
	public var battles:Array<BattleTemplate>;
	public var bg:MovieClip; //seen through transparent/translucent tiles. Usually cloud-sky with water, or star-sky for water at a clear night, or star-planet-night-sky with spaceship window
	public var name:String;
	public var id(default, null):Int;
	public var xbound(default, null):Int;
	public var ybound(default, null):Int;
	public var entry:Array<Coord>; //All possible entry points to the map
	public var autofun:Array<Void -> Void>; //function to be executed on entry on the respective entry point
	public var partyfun:StringMap<Void -> Void>; //function to be executed when party member with given name(ID?) is interacted with
	public var tilefun:Array<Trigger>; //Array of triggers. Each tile has a "trigger number", which makes the function tn+1 execute from this array. 0 means no action. If a trigger is only supposed to run once, remember to make it self-deactivating
	public var tiles:Array<Array<Tile>>;
	public var entities:Array<EntitySprite>;
	public var bchance:Float; //Map's "difficulty", usually 1. Reduced when enough grinding done.
	public var deflos:Int; //default line of sight
	public var entitySheetRequest(default, null):Array<Int>;
	
	
	/*
	 * Returns a Map instance corresponding to the parameters you enter.
	 * ID: A unique number associated with each map.
	 * Name: The name of the map. Does not have to be unique.
	 * Entry: Possible entry locations.
	 * AutoFun: Functions to be executed on entry (Depending on which entry)
	 * PartyFun: Functions to be executed when particular party members are interacted with.
	 * BG: Background visible through transparent tiles.
	 */
	public function new (nid:Int, nname:String, tilesetData:TilesetData, tileArray:Array<Array<Tile>>, nentities:Array<EntitySprite>, nentry:Array<Coord>, nautofun:Array<Void -> Void>, npartyfun:StringMap<Void  -> Void>, ntilefun:Array<Trigger>, nbattles:Array<BattleTemplate>, nbg:MovieClip, ndeflos:Int, entitySheetRequest:Array<Int>)
	{
		this.entitySheetRequest = entitySheetRequest;
		bchance = 1;
		var valid:Bool = true;
		var enumber:Int = 0;
		var tnumber:Int = -1;
		var bnumber:Int = -1;
		var ntileset = tilesetData.templates;
		id = nid;
		
		sheet = tilesetData.tilesheetData;	//TODO: Verification
		
		if(nname!=null && nname.length>0)		//TODO: More rigerous validation. This is because maps may be custom made.
			name = nname;
		else
		{
			valid=false;
			trace("Bad name (arg2) @ Map.new");
		}
		
		tilefun = ntilefun;
		if(ntilefun!=null)
		{
			tnumber = ntilefun.length;
		}
		
		entities = nentities;
		if(nentities!=null)
		{
			enumber = nentities.length;
		}
		
		battles = nbattles;
		if(nbattles!=null)
		{
			bnumber = nbattles.length-1;
		}
		
		if(ntileset!=null && ntileset.length>0)
		{
			if(valid)
			{	
				for(i in 0...ntileset.length)
					if(ntileset[i].battletemplates!=null)
						for(j in 0...ntileset[i].battletemplates.length)
							if(ntileset[i].battletemplates[j]>bnumber)
								valid=false;
				
				if(valid)
				{
					tileset = ntileset;
					
					if(tileArray!=null && tileArray.length>0 && tileArray[0]!=null && tileArray[0].length>0)
					{
						var xlen=tileArray.length;
						var ylen=tileArray[0].length;
						
						for(i in 1...xlen)
							if(tileArray[i]==null || tileArray[i].length!=ylen)
								valid=false;
						if(valid)
						{
							for(i in 0...xlen)
							for(j in 0...ylen)
								if(tileArray[i][j].template > tileset.length-1 || tileArray[i][j].los > 15 || tileArray[i][j].trigger > tnumber) // tileArray[i][j].entity>enumber || tileArray[i][j].entityx>enumber ||
									valid=false;
					
						
							if(valid)	
							{
								tiles = tileArray;
								xbound = xlen-1;
								ybound = ylen-1;
							
								if(nentry!=null && nentry.length>0)
									for(i in 0...nentry.length)
										if(nentry[i].x<0 || nentry[i].x>xlen-1 || nentry[i].y<0 || nentry[i].y>ylen-1)
											valid=false;
							
								if(valid)
								{
									entry = nentry;
									if(nautofun!=null && nautofun.length == nentry.length)
									autofun = nautofun;
									else
									{
										valid=false;
										trace("Bad autofun (arg7) @ Map.new");
									}
								}	
								else
									trace("Bad entry (arg6) @ Map.new");	
	
							}
							else
								trace("Bad tileArray (arg3) @ Map.new");
				
						}				
					}
					else
					{
						valid=false;
						trace("Bad tileArray (arg3) @ Map.new");
					}
				}
				else
				{
					trace("Bad battletemplates (arg10) @ Map.new");
				}
			
			
			}	
		}
		else
		{
			valid=false;
			trace("Bad tileset (arg3) @ Map.new");
		}
		
		
		
		
		partyfun = npartyfun;
		bg = nbg;
		
		if(ndeflos>=0 && ndeflos<=15)
			deflos = ndeflos;
		else
		{
			deflos = 4;
		}
		
		if(!valid)
		{
			trace("Error making Map");
		}
				
	}
	
	///Returns a 2D array of Tile instances based on given parameters.
	public static function tilemapper(templateArray:Array<Array<Int>>, zoomArray:Array<Array<Int>>, triggerArray:Array<{c:Coord, t:Int}>):Array<Array<Tile>>
	{
		var xlen:Int = 0;
		var ylen:Int = 0;
		var valid:Bool = true;
		if(templateArray!=null && templateArray[0]!=null)
		{
			ylen = templateArray[0].length;
			xlen = templateArray.length;
		}
				
		for(i in 1...xlen)
			if(templateArray[i]==null || templateArray[i].length!=ylen)
				valid=false;
				
		if(xlen<1 || ylen<1)
			valid=false;
		
		if(!valid)
		{
			trace("Bad templateArray @ Map.tilemapper");
			return null;
		}
		
		valid=true;
		
		if(zoomArray!=null && zoomArray.length==xlen)
		{
			for(i in 0...xlen)
				if(zoomArray[i].length!=ylen)
					valid=false;
		}
		else
			valid=false;
			
		if(!valid)
		{
			trace("Bad zoomArray @ Map.tilemapper");
			return null;
		}
		
		var tilemap:Array<Array<Tile>> = new Array<Array<Tile>>();
		for(i in 0...xlen)
		{
			tilemap[i] = new Array<Tile>();
			for(j in 0...ylen)
			{
				tilemap[i][j] = new Tile(i, j);
				tilemap[i][j].template = templateArray[i][j];
				tilemap[i][j].los = zoomArray[i][j];
			}
		}
		
		if(triggerArray!=null)
			for(i in 0...triggerArray.length)
			{
				if(triggerArray[i].c.x<0 || triggerArray[i].c.x>xlen-1 || triggerArray[i].c.y<0 || triggerArray[i].c.y>ylen-1)
				{
					trace("Bad triggerArray @ Map.tileMapper");
					return null;
				}
				tilemap[triggerArray[i].c.x][triggerArray[i].c.y].trigger = triggerArray[i].t;
			}
			
		return tilemap;
		
	}
	
}
