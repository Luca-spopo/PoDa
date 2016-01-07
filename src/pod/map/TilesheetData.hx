package pod.map;

import openfl.display.BitmapData;
import openfl.display.Tilesheet;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;

/**
 * ...
 * @author Luca
 * 05/01/2015 16:15
 */
class TilesheetData
{
	/*Apparantly there are limits to the texture size, depending on platform.
	 * I have not researched much, but 2048x2048 seems to be the largest safe value.
	 * Keep sprites 32 pixels for this reason. This gives you 64*64 tiles.
	 * Keeping things 64 pixels gives you 32 x 32 tiles. Since just 8
	 * walk cycles is 32 tiles, and you're storing all "zwinkys" too,
	 * this would be unfeasable.
	 * 
	 * Reassessment: Most zwinkydata does not take the space of an entire square.
	 * All BG map tiles will be half the height of the width, and can be packed in such
	 * a way that has their transparent areas overlapping, increasing usable area
	 * 64pixel may just work.
	 * Keep this shit for later, I guess.
	 */
	public inline static var sheetW:Int = 2048;
	public var bitmap:BitmapData;
	public var tiles:Array<Rectangle>;
	public function new() 
	{
	}
	
	///Returns a TileSheet based on this TilesheetData
	public function toTilesheet():Tilesheet
	{
		var tilesheet = new Tilesheet(bitmap);
		for (i in tiles)
		{
			tilesheet.addTileRect(i);
		}
		return tilesheet;
	}
	
	///Creates a TilesheetData that will contain the tiles from all given TilesheetDatas. Returns base indices of source TileDatas.
	public static function stitch(result:TilesheetData, tsDatas:Array<TilesheetData>): Array<Int>
	{
		var tiles:Array<Rectangle> = tsDatas[0].tiles.copy();
		var height:Int = tsDatas[0].bitmap.height;
		var bases = new Array<Int>();
		bases[0] = 0;
		var k:Int = 0;
		var bitmapData:BitmapData;
		var mat = new Matrix();
		
		//DEBUG: This condition:
		if (tsDatas.length < 2)
			Main.console.stdOut("Not enough tilesheetdatas to stitch! @ TileData.stitch", 2);
		
		for (i in 1...tsDatas.length)
		{
			k += tsDatas[i-1].tiles.length;
			bases[i] = k;
			for (j in tsDatas[i].tiles)
			{
				tiles.push(new Rectangle(j.x, j.y + height, j.width, j.height));
			}
			height += tsDatas[i].bitmap.height;
		}
		
		bitmapData = new BitmapData(sheetW, height, true, 0x00000000);
		
		for (i in tsDatas)
		{
			bitmapData.draw(i.bitmap, mat);
			mat.translate(0, i.bitmap.height);
		}
		
		result.bitmap = bitmapData;
		result.tiles = tiles;
		return bases;
	}
}