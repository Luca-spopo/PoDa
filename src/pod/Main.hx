/*
 @Author: Luca
 12/2014
 katoch.anirudh@gmail.com
 Do not copy
 */
 
 /*
  * ISSUES WITH OpenFL:
	  * 1) Alpha doesn't work for drawTiles on flash target
	  * 2) Weird borders when fractional numbers are sent as X and Y for drawTiles on Neko
  * 
  * 
  * TODO: Research suggests Vector is better than Array when dealing with fixed number of elements.
  * i.e. Vector is like the C++ array.
  * May want to hunt down places where Vectors are better. This is premature optimization though,
  * so don't do it until later.
  */

package pod ;

import openfl.display.Bitmap;
import openfl.display.Shape;
import openfl.display.Tilesheet;
import openfl.events.Event;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import pod.common.Anim;
import pod.map.TilesetData;
//import pod.common.Gif;
import pod.common.GifData;
import pod.common.Ticker;
import pod.debug.Console;
import flash.display.Sprite;
import flash.display.Stage;
import flash.events.KeyboardEvent;
import flash.text.TextField;
import pod.map.Coord;
import pod.map.Map;
import pod.map.Mapper;
import pod.map.Tile;
import pod.map.TilesheetData;
import pod.map.TileTemplate;
import pod.map.Trigger;
import openfl.Assets;
import openfl.display.FPS;
import openfl.text.TextFormat;
import flash.Lib;

class Main extends Sprite
{
	public static inline var version:String = "08/01/2015 02:19";
	
	public static var console(default, null):Console;
	public static var mapper(default, null):Mapper;
	public static var _stage(default, null):Stage;
	public static var tim(default, null):Ticker;
	
	public static var speedx:Float = 0;
	public static var speedy:Float = 0;
	public static var speed:Float;
	//DEBUG: Remove these
	
	
	public static inline function breakPoint(i:Int)
	{
		trace("Breaking: ", i);
		var temp = new Anim(null, null);
		temp.anim[0];
	}
	
	private static function dbug(v:Dynamic, ?pos:haxe.PosInfos)
	{
		console.stdOut(v, 0, pos);
	}
	
	private function new()
	{
		super();
	}
	
	private static function main()
	{
		
		Console.main();
		console = new Console();
		haxe.Log.trace = dbug;
		
		trace("Hello world!");
		
		var temp:TileTemplate;
		var temp2:TileTemplate;
		var map:Map;
		
		
		_stage = flash.Lib.current.stage;
		
		tim = new Ticker(100);
		
		var tilarr = Map.tilemapper(
		
		/*
		[[0, 0, 0, 0, 0, 0, 0], 
		[0, 0, 0, 0, 0, 0, 0], 
		[0, 0, 0, 1, 0, 0, 0], 
		 [0, 0, 0, 0, 0, 0, 0], 
		[0, 0, 0, 0, 0, 0, 0], 
		[0, 0, 0, 0, 0, 0, 0]], 
		 
		[[7, 7, 7, 7, 7, 7, 7],
		 [7, 7, 7, 7, 7, 7, 7],
		 [7, 7, 7, 7, 7, 7, 7],
		 [7, 7, 7, 7, 7, 7, 7],
		 [7, 7, 7, 7, 7, 7, 7],
		 [7, 7, 7, 7, 7, 7, 7]],
		 */

		/*
			[[1, 4, 1, 4, 1, 1, 7, 4, 4, 1, 1, 1, 2, 4, 1, 1, 4, 1, 7], 
			 [5, 0, 7, 1, 4, 4, 4, 1, 3, 5, 1, 4, 1, 0, 2, 1, 5, 5, 4],
			 [4, 0, 2, 5, 1, 4, 5, 0, 3, 1, 4, 4, 4, 6, 3, 4, 1, 4, 4],
			 [1, 0, 7, 1, 1, 4, 4, 6, 0, 5, 4, 4, 4, 0, 0, 5, 5, 1, 1],
			 [1, 0, 1, 1, 4, 4, 4, 6, 4, 5, 5, 5, 7, 3, 1, 1, 1, 1, 2], 
			 [1, 2, 1, 5, 5, 5, 2, 3, 1, 1, 1, 5, 3, 3, 5, 5, 5, 5, 2],
			 [1, 2, 1, 1, 1, 5, 7, 2, 5, 1, 1, 1, 7, 3, 5, 1, 1, 1, 3],
			 [1, 2, 5, 5, 5, 5, 2, 7, 1, 1, 1, 0, 3, 3, 0, 1, 5, 5, 3],
			 [5, 7, 1, 1, 0, 5, 7, 2, 1, 1, 1, 1, 7, 3, 5, 5, 5, 1, 3],
			 [1, 2, 1, 1, 1, 1, 2, 2, 5, 5, 5, 1, 7, 3, 1, 1, 1, 1, 3],
			 [1, 7, 1, 5, 5, 0, 0, 2, 5, 1, 1, 1, 7, 7, 1, 1, 1, 5, 3],
			 [1, 2, 1, 1, 1, 5, 3, 3, 5, 5, 5, 5, 7, 3, 5, 5, 5, 5, 3],
			 [1, 7, 1, 1, 5, 5, 7, 2, 1, 1, 1, 1, 2, 3, 1, 5, 5, 1, 3],
			 [1, 3, 1, 1, 1, 1, 7, 7, 1, 1, 1, 1, 2, 3, 1, 5, 1, 1, 3],
			 [1, 1, 0, 1, 5, 5, 5, 3, 1, 1, 1, 1, 2, 2, 5, 1, 1, 1, 2],
			 [1, 3, 1, 5, 5, 5, 7, 2, 5, 5, 1, 1, 7, 3, 1, 1, 5, 5, 2],
			 [5, 2, 5, 1, 1, 1, 3, 7, 1, 1, 5, 5, 7, 3, 5, 5, 5, 1, 3],
			 [1, 2, 1, 1, 1, 1, 2, 2, 1, 1, 1, 5, 7, 7, 1, 1, 1, 1, 7],
			 [5, 2, 5, 5, 1, 1, 3, 7, 1, 5, 5, 1, 2, 3, 1, 5, 5, 1, 7]], 
			*/
		///*	
			 
			[[1, 0, 1, 0, 1, 1, 2, 0, 0, 1, 1, 1, 2, 0, 1, 1, 0, 1, 2], 
			 [0, 0, 2, 1, 0, 0, 0, 1, 3, 0, 1, 0, 1, 0, 2, 1, 0, 0, 0],
			 [0, 0, 2, 0, 1, 0, 0, 0, 3, 1, 0, 0, 0, 1, 3, 0, 1, 0, 0],
			 [1, 0, 2, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1],
			 [1, 0, 1, 1, 0, 0, 0, 2, 0, 0, 0, 0, 2, 3, 1, 1, 1, 1, 2], 
			 [1, 2, 1, 0, 0, 0, 2, 3, 1, 1, 1, 0, 3, 3, 0, 0, 0, 0, 2],
			 [1, 2, 1, 1, 1, 0, 2, 2, 0, 1, 1, 1, 2, 3, 0, 1, 1, 1, 3],
			 [1, 2, 0, 0, 0, 0, 2, 2, 1, 1, 1, 0, 3, 3, 0, 1, 0, 0, 3],
			 [0, 2, 1, 1, 0, 0, 2, 2, 1, 1, 1, 1, 2, 3, 0, 0, 0, 1, 3],
			 [1, 2, 1, 1, 1, 1, 2, 2, 0, 0, 0, 1, 2, 3, 1, 1, 1, 1, 3],
			 [1, 2, 1, 0, 0, 0, 0, 2, 0, 1, 1, 1, 2, 2, 1, 1, 1, 0, 3],
			 [1, 2, 1, 1, 1, 0, 3, 3, 0, 0, 0, 0, 2, 3, 0, 0, 0, 0, 3],
			 [1, 2, 1, 1, 0, 0, 2, 2, 1, 1, 1, 1, 2, 3, 1, 0, 0, 1, 3],
			 [1, 3, 1, 1, 1, 1, 2, 2, 1, 1, 1, 1, 2, 3, 1, 0, 1, 1, 3],
			 [1, 1, 0, 1, 0, 0, 0, 3, 1, 1, 1, 1, 2, 2, 0, 1, 1, 1, 2],
			 [1, 3, 1, 0, 0, 0, 2, 2, 0, 0, 1, 1, 2, 3, 1, 1, 0, 0, 2],
			 [0, 2, 0, 1, 1, 1, 3, 2, 1, 1, 0, 0, 2, 3, 0, 0, 0, 1, 3],
			 [1, 2, 1, 1, 1, 1, 2, 2, 1, 1, 1, 0, 2, 2, 1, 1, 1, 1, 2],
			 [0, 2, 0, 0, 1, 1, 3, 2, 1, 0, 0, 1, 2, 3, 1, 0, 0, 1, 2]], 
		//*/
			 [[ 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7],
			 [ 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7],
			 [ 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7],
			 [ 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7],
			 [ 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7],
			 [ 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7],
			 [ 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7],
			 [ 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7],
			 [ 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7],
			 [ 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7],
			 [ 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7],
			 [ 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7],
			 [ 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7],
			 [ 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7],
			 [ 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7],
			 [ 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7],
			 [ 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7],
			 [ 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7],
			 [ 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7]
			 ],
		
		
			 /*All such maps will be mirrored along the diagonal 
			  * in their display representation. This is because 
			  * the convention I am following is arr[x][y], not
			  * arr[y][x]. So:
				 
			 ->X+
			|	01
			v	23
			Y+ 
						 
			would be written on a map like this as:
						 
			 ->Y+
			|	02
			v	13
			X+
						
			Map editing will be done using tools, so we would 
			never need to write maps in arrays like this, so no
			problem. I could add an "inverter" in the Map.tilemapper
			method, but the overhead is not worth it since maps
			will be made using tools.
						
			 */
						 						 
			 [{c:new Coord(1, 1), t:1}]
		);
		
		var gif3 = new GifData([new Anim([new Frame(3, 0, 12, -114)], null)]);
		var gif2 = new GifData([new Anim([new Frame(2, 0)], null)]);
		var gif1 = new GifData([new Anim([new Frame(0, 1)], [0, 1]), new Anim([new Frame(1, 1)], [0, 1])]);
		var gif4 = new GifData([new Anim([new Frame(4, 0, -42, -273)], null)]);
		
		var temp1 = new TileTemplate(gif1, null, 0, 0, 0, 0, 0, 0);
		var temp2 = new TileTemplate(gif2, null, 1, 1, 1, 1, 0, 0);
		var temp3 = new TileTemplate(gif2, gif3, 1, 1, 1, 1, 0, 0);
		//smalltree offset: -82, -273

		speed = 0.3;

		mapper = new Mapper(200);
		
		var sheet1 = new TilesheetData();
		var sheet2 = new TilesheetData();
		var sheet = new TilesheetData();
		
		var charsheet1 = new TilesheetData();
		charsheet1.bitmap = Assets.getBitmapData ("img/pingu.png", false);
		charsheet1.tiles = new Array<Rectangle>();
		charsheet1.tiles[0] = new Rectangle(47, 2, 50, 65);
		charsheet1.tiles[1] = new Rectangle(143, 2, 50, 65);
		charsheet1.tiles[2] = new Rectangle(237, 2, 50, 65);
		charsheet1.tiles[3] = new Rectangle(337, 2, 50, 65);
		
		var charsheet2 = new TilesheetData();
		charsheet2.bitmap = Assets.getBitmapData ("img/spin.png", false);
		charsheet2.tiles = new Array<Rectangle>();
		charsheet2.tiles[0] = new Rectangle(1, 2, 50, 85);
		charsheet2.tiles[1] = new Rectangle(45, 2, 50, 85);
		charsheet2.tiles[2] = new Rectangle(92, 2, 50, 85);
		charsheet2.tiles[3] = new Rectangle(140, 2, 50, 85);
		
		Mapper.entitysheets = [charsheet1, charsheet2];
		
		sheet1.bitmap = Assets.getBitmapData ("img/tileset.png", false);
		sheet1.tiles = new Array<Rectangle>();
		sheet1.tiles[2] = new Rectangle(0, 17, 90, 45);
		sheet1.tiles[0] = new Rectangle(109, 20, 90, 45);
		sheet1.tiles[1] = new Rectangle(108, 69, 90, 45);
		sheet1.tiles[3] = new Rectangle(115, 118, 183 - 114, 266 - 117);
		sheet1.tiles[4] = new Rectangle(223, 0, 197, 306);
		
		
		sheet2.bitmap = Assets.getBitmapData ("img/tileset2.png", false);
		sheet2.tiles = new Array<Rectangle>();
		sheet2.tiles[2] = new Rectangle(0, 17, 90, 45);
		sheet2.tiles[0] = new Rectangle(109, 20, 90, 45);
		sheet2.tiles[1] = new Rectangle(108, 69, 90, 45);
		sheet2.tiles[3] = new Rectangle(115, 118, 183 - 114, 266 - 117);
		sheet2.tiles[4] = new Rectangle(223, 0, 197, 306);
		
		var setdata = new TilesetData();
		setdata.tilesheetData = sheet1;
		setdata.templates = [temp1, temp2, temp3, new TileTemplate(gif2, gif4, 1, 1, 1, 1, 0, 0)];
		
		
		var gif32 = new GifData([new Anim([new Frame(3, 10, 12, -104)], null)]);
		var gif22 = new GifData([new Anim([new Frame(2, 10)], null)]);
		var gif12 = new GifData([new Anim([new Frame(0, 1)], [0, 1]), new Anim([new Frame(1, 1)], [0, 1])]);
		var gif42 = new GifData([new Anim([new Frame(4, 10, -42, -273)], null)]);
		/* Here is the first compramise to your paradigm.
		 * GifData's "base" feild is mutable and depends on the tileset.
		 * So if you want to use it with multiple Mappers, you will need to make copies.
		 * 
		 * TODO: This may sound silly, but the paradigm is important. You may face the same problem
		 * for other things in the future. Thus, this is intolerable. Fix it.
		 */
		
		var temp12 = new TileTemplate(gif12, null, 0, 0, 0, 0, 0, 0);
		var temp22 = new TileTemplate(gif22, null, 1, 1, 1, 1, 0, 0);
		var temp32 = new TileTemplate(gif12, gif32, 1, 1, 1, 1, 0, 0);
		var temp42 = new TileTemplate(gif22, gif42, 1, 1, 1, 1, 0, 0);
		var setdata2 = new TilesetData();
		setdata2.tilesheetData = sheet2;
		setdata2.templates = [temp12, temp22, temp32, temp42];
		
		map = new Map(1, "Test", setdata/*TilesetData.merge([setdata, setdata2])*/, tilarr, null, [new Coord(2, 3)], [function(){console.stdOut("Entered the map!", 1);}], null, [new Trigger(function() {console.stdOut("ouch", 1);} )], null, null, 7, [1]);
		mapper.loadMap(map, 0);
		
		//TODO: Delegate this keyboard work to a UI
		//{ Keyboard Listeners }
		_stage.addEventListener(KeyboardEvent.KEY_UP,
			function(e)
			{
				switch(e.keyCode)
				{
					//~ 192
					case 192	:	console.toggleShow();
						
					// ? or /
					case 191	:	//TODO: Pop up command prompt
					
					//Enter
					case 13	:	console.runInput();
					
					
					//Up Arrow
					case 38	:	console.putLastCommand();
					
					//P
					case 80	:	trace(mapper.mapcanvas.x + " " + mapper.mapcanvas.y);
					
					default		:	
				}
			}
		);

		_stage.addEventListener(Event.ENTER_FRAME, function(e) { mapper.moveCam(speedx / 100, speedy / 100); } );
		
		_stage.addEventListener(KeyboardEvent.KEY_DOWN,
			function(e)
			{
				switch(e.keyCode)	//37 = right, 38 = up, 39 = left, 40 = down
				{
					case 37	:	mapper.x+=3;//mapper.moveCam(speed, 0);
					case 38	:	mapper.y -=3;//mapper.moveCam(0, -speed);
					case 39	:	mapper.x-=3;//mapper.moveCam(-speed, 0);					
					case 40	:	mapper.y +=3;//mapper.moveCam(0, speed);
					
					/*
					case 37	:	mapper.mapcanvas.x+=3;//mapper.moveCam(speed, 0);
					case 38	:	mapper.mapcanvas.y -=3;//mapper.moveCam(0, -speed);
					case 39	:	mapper.mapcanvas.x-=3;//mapper.moveCam(-speed, 0);					
					case 40	:	mapper.mapcanvas.y +=3;//mapper.moveCam(0, speed);
					*/
					/*
					//W
					case 87	:	mapper.moveCam(0, speed);
					//A	
					case 65	:	mapper.moveCam(-speed, 0);
					//S
					case 83	:	mapper.moveCam(0, -speed);
					//D
					case 68	:	mapper.moveCam(speed, 0);
					*/
					
					//W
					case 87	:	speedy++;
					//A	
					case 65	:	speedx--;
					//S
					case 83	:	speedy--;
					//D
					case 68	:	speedx++;
					
				}
			}
		);
		//}
		
			
		//Order of adding child dictates depth
		_stage.addChild(mapper);
		_stage.addChild(console);
		
		mapper.x = _stage.stageWidth/2 - 100;
		mapper.y = _stage.stageHeight/2 - 50;
		
		
		tim.resume();
	}
}
