package pod.map;

/**
 * ...
 * @author Luca
 * 06/01/2015 20:57
 */
class TilesetData
{
	public var templates:Array<TileTemplate>;
	public var tilesheetData:TilesheetData;	
	
	public function new()
	{
	}
	
	///Creates a larger tileset from smaller ones. Example: Desert + Grassland for maps that use both.
	public static function merge(tilesets:Array<TilesetData>):TilesetData
	{
		var result = new TilesetData();
		var tshdarr = new Array<TilesheetData>();
		result.templates = new Array<TileTemplate>();
		var k:Int = 0;
		for (i in tilesets)
		{
			tshdarr.push(i.tilesheetData);
			for (j in i.templates)
			{
				j.bg.setbase(k);
				if (j.fg != null)
					j.fg.setbase(k);
				result.templates.push(j);
			}
			k += i.tilesheetData.tiles.length;
		}
		var temp = new TilesheetData();
		TilesheetData.stitch(temp, tshdarr);
		result.tilesheetData = temp;
		return result;
	}
}