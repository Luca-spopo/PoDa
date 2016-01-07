/*
 @Author: Luca
 12/2014
 katoch.anirudh@gmail.com
 Do not copy or use
 */

/*
 * MAJOR MAKEOVER:
	 * THIS IS THE DAWN OF THE TILESPRITE AGE
	 * KNEEL BEFORE IT, AND GET TO THE TEDIOUS WORK
	 * 29/12/2014 23:22
	 * 
	 * Done.
	 * 09/01/2015 03:44
	 * 
	 * Also, the tilesheet will be made dynamically. ALL images (Terrain, entities, stalkers) will
	 * be batch rendered from a single tilesheet. This tilesheet will be made dynamically on loadmap.
	 * 
	 * Making the tilesheet from individual tiles is too much work. You would need an algorithm
	 * to minimize the wasted area as FG tiles are rarely 90x45. You would also need to
	 * precalcualte the size of the canvas since there is apparantly no way to increase
	 * the canvas size of an existing BitmapData (Or you would need to keep it a very big
	 * size to begin with)
	 * 
	 * The better alternative would be to keep groups of tilesheets of a specific width.
	 * Each group would be modular, things that can't be used without each other, but would
	 * do justice to the space as a single tilesheet
	 * 
	 * Then, their heights would be added and the new tilesheet stitched together from that.
	 * 
	 * Basically dynamic spritesheets but as groups instead of individual tiles.
	 * This also seems to be better for the PNG compression
	 * 2 individual tiles (10+kb) vs tilesheet of the 2 (9.51kb)
	 * (Neglegible factor)
	 * 
	 * You can also stich them side by side, using this algorithm (Not tested):
		 * Sort by height
		 * Add tallest on left
		 * Add second tallest on right
		 * Add third tallest to current cumalative shortest
		 * etc.
		 * ...but why bother
*/	

/*TODO: The trees suddenly springing up from the bottom DOES look bad.
 * Here is the idea: camX and camY will not be in the center of localmap anymore. localmap will be
 * extended in +x and +y by a given parameter, to stream objects from there before they
 * actually come up. Their BG will not be rendered. Only FG and entity.
 * This will require reprogramming some stuff. Look into it.
 * (EDIT: This won't work, keep reading)
 * 
 * Hmm, something like that big tree will need 12-15 extra blocks... that's an
 * impractical overhead.
 * Any other solutuon?
 * 
 * 2 things come to mind.
 * 
 * The first is to stream new FG with an alpha tween, so it *does* still just pop up when it's on
 * a nearby tile, but it streams in gradually. This may not look too bad, kinda like MTA's
 * streaming objects.
 * 
 * The second idea is to mark each tile the fg overlaps with with the fg's tile number
 * and particularly render that fg later.
 * 
 * A third idea is a modification of the first. Let alpha of an FG appear to be
 * a function of it's distance to the camera, such that it's alpha is 0 when at LOS+losbuff+1, and
 * 1 when at los+1. So they would still look streaming, but would stop streaming and stay in alpha
 * mode if the camera stops moving and they are on the fringe.
 * Similarly, they would tween from 1 to 0 when being unloaded from the map.
 * This would appear to be a consistant artstyle and we embrace our problem.
 */


package pod.map ;

import flash.display.Sprite;
import haxe.remoting.FlashJsConnection;
import openfl.display.DisplayObject;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Shape;
import openfl.display.Tilesheet;
import pod.map.Tile;
import openfl.geom.Point;
import openfl.geom.Rectangle;
//import pod.common.Gif;
import pod.common.Ticker;
import pod.Main;
import pod.map.Container;
import pod.map.Map;
import pod.map.TileSprite;


//Debug:

import openfl.Assets;
import openfl.display.Shape;
import openfl.display.Tilesheet;
import openfl.geom.Rectangle;

/*TODO: Any FG shrouding an entity and flagged for "hide" should be alpha'd.
 * (Grass/water would not be flagged, trees and walls would)
 * For this, you scan all the FGs for tiles ahead of this tile, and check their
 * width and height. Then, using tileH and tileW you determine if they are
 * covering the entity tile. If yes, tween their alpha to 0.5, and that coord
 * to a "Queue for opacity" array. Everytime the camera moves, the
 * TileSprites corresponding to the coords in Queue for Opacity are
 * checked for still meeting the condition (start by checking if they are ahead of
 * this tile) and made solid if needed.
 * Also, everytime the camera moves, the queue is checked for any tiles that
 * would have been unloaded (since they crossed the edge), and if there are such tiles,
 * they are removed from the queue.
 */


///Responsible for loading, interacting with, and everything else-ing maps.
class Mapper extends Sprite
{
	//{properties}
	inline static private var tileW:Float=88;
	private inline static var tileH:Float=44;
	private inline static var localmapSide:Int = 33; //Length of the side of the localmap (in tiles). Set to 33 later
	//localmapSide = (max_los+losbuff)*2 + 1, and always odd (to keep a center tile)
	private inline static var rrange:Int=Std.int((localmapSide-1)/2); //used often
	private inline static var losbuff:Int = 2;	//The buffer between los and the render boundary
	//TODO: Make sure losbuff + los <= rrange everywhere
	public var container:Container;	//DEBUG: Make private
	public var los(default, null):Int;
	public var xlen(default, null):Int; //Size of the display
	public var ylen(default, null):Int;
	private var map:Map;
	public var camXInt(default, null):Int;	//Position of camera (Tile)
	public var camYInt(default, null):Int;
	public var camXFloat(default, null):Float;	//Position of camera in current tile
	public var camYFloat(default, null):Float;	//Absolute cam position = camInt + camFloat
	private var localmap:Array<Array<TileSprite>>;
	private var magx:Float; //magnification
	private var magy:Float;
	private var tim:Ticker;
	private var xmarker:Int;
	private var ymarker:Int; //These are used internally to efficiently shiftmap
	private var bg:DisplayObject;
	public var mapcanvas:Shape;	//DEBUG: Make private
	private var fg:DisplayObject;
	private var tilesheet:Tilesheet;
	
	public static var globalentitylist:Array<Int> = [0];
	public static var entitysheets:Array<TilesheetData>;
	
	//DEBUG: Remove
	public static var flag = true;
	
	//}
	
	public function new (yl:Int)
	{
		
		super ();
		
		xlen = yl*2;
		ylen = yl;
		if(ylen<=0)
		{
			xlen=800;
			ylen=400;
			Main.console.stdOut("bad args @ Mapper.new", 2);
		}
		container = new Container();
		addChild(container);
		//DEBUG: Uncomment the scrollRect
		//container.scrollRect = new Rectangle(0, 0, xlen, ylen);
		
		container.x = 0;// -xlen / 2;
		container.y = 0;//-ylen / 2;
		mapcanvas = new Shape();
		mapcanvas.x = 174;
		mapcanvas.y = -350;
		container.addChild(mapcanvas);

		
		
		xmarker = ymarker = 0;
		localmap = new Array<Array<TileSprite>>();
		for(i in 0...localmapSide)		//for in haxe runs one less apparantly, so from 0 to 32 here
		{
			localmap[i] = new Array<TileSprite>();
			for(j in 0...localmapSide)
			{
				localmap[i][j] = new TileSprite();
			}
		}
		tim = new Ticker(50);
		tim.addTimer(timHandler, 1);
	}
	
	public function debug(arg:Int, args:Array<Int>):Dynamic	//DEBUG: idk, wanna keep it? //Yes, but let it take a string password as param
	{
		switch(arg)
		{
			case 1	:	for (i in map.tileset)
						{
								//Since offsets are frame specific now, redo this.
						//	i.fgoffx += args[0];
						//	i.fgoffy += args[1];
						}
						for (i in localmap)
							for (j in i)
							{
						//		j.fgoffx += args[0];
						//		j.fgoffy += args[1];
							}
						renderMap();
						return ('FG offset ');//of tile 0, 0: ${localmap[xmarker][ymarker].fgoffx}, ${localmap[xmarker][ymarker].fgoffy}');
		
			case 2	:	var str = "";
						for (i in map.tiles)
						{
							for (j in i)
								str += j.b_anim + " ";
							str += "\n";
						}
						return str;
		}
		return "Unknown debugger call to Mapper. You should never be able to see this, but oh well. Do not worry it's no big problem";
	}
	
	private function timHandler()
	{	
		/*If in the future you decide that when new tiles
		 * are turned into TileSprite and loaded into localmap,
		 * then there should be some "compensation time"
		 * series of timHandlers (or something more optimized
		 * for the job) to prevent the world outside
		 * your LOS looking frozen, and you implement such a thing
		 * in renderMap, then don't forget to make this compatible
		 */
		for(i in 0...localmapSide)
			for(j in 0...localmapSide)
			{
				localmap[i][j].timHandler();
			}
		renderMap();
	}
	
	private inline function loopint(n:Int):Int
	{
			if(n<0)
				n+=localmapSide;
			else if (n>localmapSide-1)
				n-=localmapSide;
			//DEBUG:
			if(n<0 || n>localmapSide-1)
				Main.console.stdOut("loopint done goofed up with n = "+n+" Maybe max_los is not being enforced somewhere", 2);
			//
			return n;
	}
	
	///Fills a TileSprite from a Tile (Which only has indices for data)
	
	private inline function changeTileSprite(ts:TileSprite, tile:Tile):Void
	{
		
		//TODO: Add support for entities when they are added
		if(tile!=null)
		{
			ts.setTemplate(map.tileset[tile.template], tile.b_anim, tile.b_frame, tile.b_time, tile.b_freeze   , tile.f_anim, tile.f_frame, tile.f_time, tile.f_freeze);
			ts.ascii = tile.template;
			ts.los = tile.los;
			ts.trigger = map.tilefun[tile.trigger-1];
		}
		else
		{
			/*If the map's fg or bg (or both) start repeating once you go out of bounds
			 * into the null tiles territory, then there is something wrong here. The
			 * data of the TileSprite is not being cleared properly.
			 */
			ts.setTemplate(map.tileset[0], 0, 0, 0, false, 0, 0, 0, false);
			ts.ascii = 0;
			ts.los = map.deflos;
			ts.trigger = null;
		}
	}
	
	private inline function changeTile(tile:Tile, ts:TileSprite):Void
	{
		
		//TODO: Add support for entities when they are added
		if(tile!=null)
		{
			tile.b_anim = ts.bg.anim;
			tile.b_frame = ts.bg.framesLeft;
			tile.b_freeze = ts.bg.frozen;
			tile.b_time = ts.bg.time;
			tile.entities = ts.entitiesForTile;
			tile.f_anim = ts.fg.anim;
			tile.f_frame = ts.fg.framesLeft;
			tile.f_freeze = ts.fg.frozen;
			tile.f_time = ts.fg.time;
		}
	}
	
	///Shift localmap by one. 1=X-, 2=Y-, 3=X+, 4=Y+ for cam position
	public inline function shiftLocalMap(direction:Int)
	{
		//You're loading the tiles from the map just fine, but implement a saving mechanism to save the tilesprites being unloaded back to the map.
		//On it! 09/01/2015 16:43
		//Done. 13/01/2015 21:47
		
		switch(direction)
		{
			case 3	:	camXInt++;
			case 2	:	camYInt--;
			case 1	:	camXInt--;
			case 4	:	camYInt++;
		}
	
		var camxx:Int = camXInt;
		var camyy:Int = camYInt;
		var m:Map = map;
		
		
		
		//	add the new row or coloumn
		switch(direction)
		{
			//may be WIP
			case 3	:	//x++ (i.e. ground will move in the X- direction i.e. Cam in X+ direction)
				//		trace('importing xrow ${camxx}+${rrange}=${camxx+rrange} for x++ case 3');
				
						if (m.tiles[camxx - rrange - 1] != null)
						{
							for(i in 0...localmapSide)
								if (m.tiles[camxx - rrange - 1][camyy - rrange+i] != null)
								{
									changeTile(m.tiles[camxx - rrange - 1][camyy - rrange+i], localmap[xmarker][loopint(i + ymarker)]);
								}
						}
							
				
						if(m.tiles[camxx+rrange]!=null)
						{	
							for(i in 0...localmapSide)
							{
								changeTileSprite(localmap[xmarker][loopint(i + ymarker)], m.tiles[camxx + rrange][camyy - rrange+i]);
							}
						}
						else
							for(i in 0...localmapSide)
								changeTileSprite(localmap[xmarker][loopint(ymarker+i)], null);

		
			case 4	:	//y++
						
						for (i in 0...localmapSide)
						{		
							if (m.tiles[camxx - rrange+i] != null)
							{
								if(m.tiles[camxx-rrange+i][camyy-rrange-1]!=null)
									changeTile(m.tiles[camxx-rrange+i][camyy-rrange-1], localmap[loopint(i+xmarker)][ymarker]);
		
								changeTileSprite(localmap[loopint(i+xmarker)][ymarker], m.tiles[camxx-rrange+i][camyy+rrange]);
							}
							else
									changeTileSprite(localmap[loopint(xmarker + i)][ymarker], null);
						}
			case 1	:	//x++
				
						if (m.tiles[camxx + rrange + 1] != null)
						{
							for(i in 0...localmapSide)
								if (m.tiles[camxx + rrange + 1][camyy - rrange+i] != null)
								{
									changeTile(m.tiles[camxx + rrange +1][camyy-rrange+i], localmap[loopint(xmarker+localmapSide-1)][loopint(i + ymarker)]);
								}
						}
				
						if(m.tiles[camxx-rrange]!=null)
						{
							for(i in 0...localmapSide)
								changeTileSprite(localmap[loopint(xmarker+localmapSide-1)][loopint(ymarker+i)], m.tiles[camxx-rrange][camyy-rrange+i]);
						}
						else
						{
							for(i in 0...localmapSide)
								changeTileSprite(localmap[loopint(xmarker+localmapSide-1)][loopint(ymarker+i)], null);
						}
			case 2	:	//y--;
						for (i in 0...localmapSide)
						{
							if (m.tiles[camxx - rrange+i] != null)
							{
								if(m.tiles[camxx - rrange+i][camyy + rrange + 1]!=null)
									changeTile(m.tiles[camxx - rrange+i][camyy + rrange + 1], localmap[loopint(xmarker + i)][loopint(ymarker + localmapSide-1)]);	
						
								changeTileSprite(localmap[loopint(xmarker + i)][loopint(ymarker + localmapSide-1)] , m.tiles[camxx - rrange+i][camyy - rrange]);	
							}
							else
								changeTileSprite(	localmap[loopint(xmarker+i)][loopint(ymarker+localmapSide-1)] , null);
		
						}
		}
		
		
	//	trace("cp4");


		switch(direction)
		{
			case 3	:	xmarker++;
			case 2	:	ymarker--;
			case 1	:	xmarker--;
			case 4	:	ymarker++;
		}
		
		xmarker = loopint(xmarker);
		ymarker = loopint(ymarker);
	}
	
	/*Calculates distance from target, and then deploys
	 * a series of moveCams or reloads localmap (if
	 * target is too far away), and then renders.
	 * I will only make this if I feel I need it, at
	 * a later date.
	 */
	//public function setCam(x:Float, y:Float)
	
	///Displace the camera by dx and dy.
	public inline function moveCam(dx:Float, dy:Float)
	{
		
		var temp:Int = Math.floor(camXInt + camXFloat + dx);
		var temp2:Int = Math.floor(camYInt + camYFloat + dy);
		
		var ndxi:Int = temp - camXInt;	//new dx for shiftmap (integer);
		camXFloat = camXInt + camXFloat + dx - temp;	//new camXFloat
		var ndyi:Int = temp2 - camYInt;
		camYFloat = camYInt + camYFloat + dy - temp2;
		
		//camInt is already changed by shiftMap
		
		if (ndxi > 0)
		{
			for (i in 0...ndxi)
				shiftLocalMap(1);
		}
		else if (ndxi < 0)
		{
			for (i in ndxi...0)
				shiftLocalMap(3);
		}
		
		if (ndyi > 0)
		{
			for (i in 0...ndyi)
				shiftLocalMap(2);
		}
		else if (ndyi < 0)
		{
			for (i in ndyi...0)
				shiftLocalMap(4);
		}
		renderMap();
	}
	
	
	
	///Apply visual changes
	inline private function renderMap()
	{
		
		/*TODO: A cooldown on rendermap. If more calls are made during the cooldown,
		 * then the "render pending" flag is set to true and one call is made after the cooldown.
		 * This is to prevent things from forcing a re-render faster than a particular
		 * FPS.
		 * 
		 * There are two approaches. One is to render map onEnterFrame, and the other is
		 * to render it whenever something changes. I chose the latter because I think it
		 * is a waste to clear graphics and draw it again when nothing has changed.
		 * 
		 * The drawback the this option is that if many things change in succession
		 * and each change calls a renderMap, then multiple renders would be made on
		 * perhaps a single frame. So far (at time of writing) the only things that make
		 * rendermap calls are the timHandler and the moveCam. Only moveCam has the potential
		 * to make redundant calls, but even that can be mitigated with careful programming.
		 * 
		 * This "cooldown" should be implemented if in the future you think that your
		 * code could call redundant rendermaps in quick succession.
		 */
		
		var renderQueue = new Array<Float>();		
		inline function addToRenderQueue(x:Float, y:Float, index:Int, alpha:Float)
		{
			renderQueue.push(x);	
			renderQueue.push(y);
			renderQueue.push(index);
			renderQueue.push(alpha);
		}
		
		inline function cabs(arg:Float)
		{
			return arg > 0?arg: -arg;
		}
		
		inline function addToRenderQueueTS(ts:TileSprite, i:Int, j:Int)
		{
			addToRenderQueue( (i+camXFloat) * tileW / 2 - (j+camYFloat) * tileW / 2, (i+camXFloat) * tileH / 2 + (j+camYFloat) * tileH / 2 , ts.bg.tileNumber + ts.bg.getBase(), 1);
			if (ts.fg.dataExists())
			{
				var fgAlpha:Float = 1;
				var dist:Float = cabs(rrange - (i+camXFloat)) + cabs(rrange  - (j+camYFloat));
				if (dist>los && (rrange-i)<0 || (rrange-j)<0) //The other constraints are to prevent the unneeded fade out for elements on top.
				{
					fgAlpha = 1 - (dist-los)/(losbuff+1);
				}
				addToRenderQueue( (i+camXFloat) * tileW / 2 - (j+camYFloat) * tileW / 2 + ts.fg.offsetX, (i+camXFloat) * tileH / 2 + (j+camYFloat) * tileH / 2 + ts.fg.offsetY, ts.fg.tileNumber + ts.fg.getBase(), fgAlpha);
			}
		}
		
		
		var bla = -1;	
		for(i in rrange-los-losbuff...rrange+1)
		{
			bla++;
			for (j in rrange-bla...bla+rrange+1)
			{
				addToRenderQueueTS(localmap[loopint(xmarker + i)][loopint(ymarker + j)], i, j);
			}
		}
		
		
		for(i in rrange+1...rrange+los+losbuff+1) //should be 2*los+camwidth. localmap should have an even number if main char takes 4 blocks
		{
			bla--;
			for(j in rrange-bla...bla+rrange+1)
			{
				addToRenderQueueTS(localmap[loopint(xmarker + i)][loopint(ymarker + j)], i, j);
			}
		}
		
		
		/*  //The crude, diamond rendering.
		  
			for(i in 0...localmapSide)
			{
				for(j in 0...localmapSide)
				{
					ts = localmap[loopint(xmarker + i)][loopint(ymarker + j)];
					addToRenderQueue( i * tileW / 2 - j * tileW / 2, i * tileH / 2 + j * tileH / 2 , ts.b_tileNumber);
					if (ts.f_data != null)
					{
						addToRenderQueue( i * tileW / 2 - j * tileW / 2 + ts.fgoffsetX, i * tileH / 2 + j * tileH / 2 + ts.fgoffsetY, ts.f_tileNumber);
					}
				}
			}	
		*/
		
			
		var ym16 = loopint(ymarker+rrange);
		var xm16 = loopint(xmarker+rrange);	//the new 'center' block for the localmap (taking the markers into account)
		
		if(localmap[xm16][ym16].los!=-1)
			los = localmap[xm16][ym16].los;
		else
			los = map.deflos;
			
		magx=xlen/(tileW*(los+0.5));
		magy = ylen / (tileH * (los + 0.5));
		
		mapcanvas.scaleX =  magx;
		mapcanvas.scaleY =  magy;
		
		
		mapcanvas.graphics.clear();
		
		tilesheet.drawTiles(mapcanvas.graphics, renderQueue, true, Tilesheet.TILE_ALPHA); //DEBUG: Remove the comment

		/*TODO: In Neko runtime, the borders show up around the tiles
		 * when bitmap smoothing is on and the shape (or it's parent) is scaled.
		 */
		
		 /*
		  * About the black border on the tiles on neko/cpp target....
		  * 
		  * Known facts:
			  * There are partially transparent pixels on the edges of the tiles when smoothing is on
			  * The lines only appear when smoothing is on
			  * The lines only appear where two tiles overlap (Seems that way)
			  * There are no partially transparent pixels when smoothing is off, and the problem disappears
			  * The original texture atlas does not have any partially transparent border for tiles
		  * 
		  * Here is my theory:
		  * 
		  * It is quite obvious that the partially transparent pixels are there
		  * due to linear sampling of neighbouring pixels when a fractional
		  * coordinate is fetched from the texture atlas. The coord is fractional
		  * because of the scaling. This is the idea behind smoothing.
		  * 
		  * But, it is turning dark where the alpha is being superpositioned
		  * on top of the other texture.
		  * 
		  * I think this is because of some bad way the alpha is being added internally.
		  * I have read something about bad alpha multiplication, look it up.
		  * 
		  * Also, flash uses pre-multiplied alpha values, and so does OpenFL:next (Only
		  * implemented for flash and html5 yet).
		  * It so happens that this problem is not present on flash and html5.
		  * 
		  * OpenFL:next will be implemented for all platforms eventually. Let's hope the
		  * problem gets fixed then. If it doesn't, then fix it yourself.
		  * Until then, ignore the lines.
		  */
			
		//ascii render
		/*
		for(j in 1-localmapSide...1)		//VERTICALLY INVERTED SO YOU CAN READ IT WHILE TILTING YOUR HEAD
										//This happened because my array convention is arr[x][y] not arr[y][x]
		{
			var str:String = "";
			for(i in 0...localmapSide)
			{
				str+=localmap[loopint(xmarker+i)][loopint(ymarker-j)].ascii+" ";	//inverted all the j's because HaXe "..." is retarded. It doesn't allow LHS > RHS
			}
			trace(str);
		}
		trace("raw:");
		for(j in 0...localmapSide)
		{
			var str:String = "";
			for(i in 0...localmapSide)
			{
				str+=localmap[i][j].ascii+" ";
			}
			trace(str);
		}
		
		trace("");
		trace("***");
		*/
		//
		
	}
	
	//Shamelessly copy pasted from the old Mapper:
	///Load a map and enter it at given entry point index.
	public function loadMap(m:Map, e:Int)
	{
	
		
		if(m!=null)
			map = m;
		else
			Main.console.stdOut("Bad map @ Mapper.loadmap", 2);
			
			
		var camx:Int = 0;
		var camy:Int = 0;
		camXFloat = camYFloat = 0;
		if(m.entry[e]!=null)
		{
			camx = m.entry[e].x;
			camy = m.entry[e].y;
		}
		else
			Main.console.stdOut("Bad map @ Mapper.loadmap (invalid entry point)", 2);
		
		camXInt = camx;
		camYInt = camy;
		Main.console.stdOut('Entering map at ${camXInt}, ${camYInt}', 0);
		
		if(m.tiles[camx]!=null && m.tiles[camx][camy]!=null && m.tiles[camx][camy].los!=-1)
			los = m.tiles[camx][camy].los;
		else
			los = m.deflos; 
		if(m.autofun[e]!=null)
			m.autofun[e]();
		else
			Main.console.stdOut("Invalid entry function @ Mapper.loadmap", 2);
			
		xmarker = ymarker = 0;
		
		for(i in 0...localmapSide)
			for(j in 0...localmapSide)
			{
				if(m.tiles[camx-rrange+i]!=null)
					changeTileSprite(localmap[i][j], m.tiles[camx-rrange+i][camy-rrange+j]);
				else
					changeTileSprite(localmap[i][j], null);
			}
		
		if (map.bg != null)
		{
			bg = map.bg;
			container.addChildAt(bg, container.getChildIndex(mapcanvas));
		}
		
		/*So how to implement the entity spritesheets?
		 * 
		 * Mapper (or Main) will contain an array of tilesheetdata for different zwinkys. Each Map
		 * will come with an integer array that lists the indices of the zwinkys it will need.
		 * Thus, only the zwinkys needed will be stitched to the texture atlas.
		 * There will also be a mandatory list kept by Mapper (or Main). These tilesheetdata will
		 * contain entities that will be stiched regardless of the Map's request.
		 * 
		 * I want to keep the entity sheets independant of the tileset, since they will be reused
		 * very often. It also helps us edit a character's spritesheet easily at runtime.
		 */
		
		var tsarray = new Array<TilesheetData>();
		tsarray.push(map.sheet);
		
		for (i in globalentitylist)
		{
			tsarray.push(entitysheets[i]);
		}
		for (i in map.entitySheetRequest)
		{
			if (globalentitylist.indexOf(i) != -1)
			{
				tsarray.push(entitysheets[i]);
			}
		}
		
		 /*WIP: Above and below.
		  * Basically, I still need to figure out how the bases for
		  * the tilesheets will work.
		  * 		
		//Neko invisibility bug narrowed to this WIP. Something to do with stitching I suppose
		  */
		 
		var tempsheetdata = new TilesheetData();
		//basearray = 
		TilesheetData.stitch(tempsheetdata, tsarray);
		
		
		tilesheet = map.sheet.toTilesheet();//tempsheetdata.toTilesheet();
		
		/*Here is how it will work:
		 *GifData consists of all the animation data. It stores animations as a collection of
		 * integers that represent frames. They are set assuming their tilesheet starts with 0.
		 * But, the texture atlas will have lots of tilesheets stitched together. Thus, a base number
		 * will be added to them before rendering. This base is returned by the stitch function and
		 * will be stored. This number will be added by the render function.
		 * The tileset always starts with 0. Only entities need the base.
		 * 
		 * Some ad-hoc system the previous you implemented makes GifData store the bases, but that
		 * means the GifData is mutable, which breaks your paradigm. (I mean, your system lets you
		 * make multiple Mappers. GifData "data" must be immutable)
		 * 
		 * Thus, I will have to make a new clas, the GifDataData, which will not have a base, and will
		 * be used for storage only. Main will only supply GifDataData, and Mapper (or Map?) will create GifData
		 * that it needs.
		*/
		
	//	timHandler();
		//You may put a timHandler() here, if the norm becomes to make the first frame empty with list of possible first animations. For example, water could start with anim1 or anim2, with the first anim0 having just a single frame with 1 time that calls on anim1 or anim2 randomly, and never comes back.
		
		renderMap();
		
		tim.resume();
	}
}