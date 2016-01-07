package pod.debug ;
import haxe.ds.StringMap;

/**
 * ...
 * @author Luca
 * 27/12/2014 17:52
 * Do not copy
 */

private class FunPair
{
	public var root(default, null):Bool;
	public var fun(default, null):Array<String>->Dynamic;
	public function new(root:Bool, fun:Array<String>->Dynamic)
	{
		this.fun = fun;
		this.root = root;
	}
}
 
class Parser
{
	
	private static var commandMap:StringMap<FunPair>;
	
	public static function main()
	{
		commandMap  = new StringMap<FunPair>();
		
		//TODO: Your debugging is not really secure, since the class's debuggers are public. Fix that.
		
		commandMap.set("help", new FunPair(false,
			function(args:Array<String>)
			{
				if(Main.console._root)
					return 
					"LIST OF COMMANDS (rooted):\nhelp : Show this list\nclear : Clear log\npos : Display camera position\ndebugmode <0|1|2|3> : Change verbosity\nfgoffset <dx> <dy> : Change mapper's fgmap offset\nabout : Print info";
				else
					return
					"LIST OF COMMANDS:\nhelp : Show this list\nclear : Clear log\npos : Display camera position\nsu <Password> : Acquire root privileges\nabout : Print info";

			}
		));
		
		commandMap.set("clear", new FunPair(false,
			function(args:Array<String>)
			{
				Main.console.clear();
				return 'Screen cleared...';
			}
		));
		
		commandMap.set("su", new FunPair(false,
			function(args:Array<String>)
			{
				var i:Int = Main.console.su(args[0]);
				if(i<0)
					return "You cant try again so soon! Try again in "+ '${-i/10} seconds!';
				switch(i)
				{
					case 0	:	return "Wrong password. Please check spellings.";
					case 1	:	return "You now have elevated privilages";
					case 2	:	return "You are already root!";
				}
				return "Unknown exception!";
			}
		));
		
		commandMap.set("debugmode", new FunPair(true,
			function(args:Array<String>)
			{
				var i:Int = Std.parseInt(args[0]);
				if (i >= 0 && i <= 3)
				{
					Main.console.debugLevel = i;
					return 'debugLevel is now set to $i';
				}
				else
					return '$i is not a valid value for debugmode.';
				return "Unknown exception!";
			}
		));
		
		commandMap.set("about", new FunPair(false,
			function(args:Array<String>)
			{
				return 'PIE OR DIE ENGINE A (PoDa)\nVersion ${Main.version}\nMade by Luca (katoch.anirudh@gmail.com)'+"\nDo not copy, not worth copying.";
			}
		));
		
		commandMap.set("pos", new FunPair(false,
			function(args:Array<String>)
			{
				return 'Central tile: ${Main.mapper.camXInt}, ${Main.mapper.camYInt}';
			}
		));
		
		commandMap.set("cam", new FunPair(false,
			function(args:Array<String>)
			{
				return 'Camera position: ${Main.mapper.camXInt+Main.mapper.camXFloat}, ${Main.mapper.camYInt+Main.mapper.camYFloat}';
			}
		));
		
		commandMap.set("fgoffset", new FunPair(true, //Does it need root?
			function(args:Array<String>)
			{
				return Main.mapper.debug(1, [Std.parseInt(args[0]), Std.parseInt(args[1])]);
			}
		));
		
		commandMap.set("setSpeed", new FunPair(false, //Does it need root?
			function(args:Array<String>)
			{
				Main.speed=Std.parseInt(args[0]);
				return Main.speed;
			}
		));
		
			commandMap.set("printmap", new FunPair(true, //Does it need root?
			function(args:Array<String>)
			{
				return Main.mapper.debug(2, null);
				//Don't forget to add it to "help" text!
			}
		));
		
		/*
		 * Template to add a command:
			
		commandMap.set("command", new FunPair(true, //Does it need root?
			function(args:Array<String>)
			{
				//Std.parseInt(args[?]);	//If you need to parse a string as a number
				//Do stuff
				return 'Acknowledgement message';
				//Don't forget to add it to "help" text!
			}
		));
		
		 */
		
	}
	
	///Takes a string, parses and executes it.
	public static function parse(input:String, _root:Bool):Dynamic
	{
		if (input == null || input.length == 0)
		{
			return null;
		}
		
		var args:Array<String> = input.split(" ").filter(function(str:String) { if (str != "" && str != null) return true; else return false; } );
	/*
	 * This comment block may be useful for other platforms if they dont have
	 * certain array functions implemented...
	 * 
	 * var validArgs:Int = args.length;
		var i:Int = 0;
		while (i<validArgs)	//This is supposed to be to mitigate double spaces.
		{
			if (args[i] == "" || args[i] == null)
			{
				validArgs--;
				for (j in i...validArgs)
				{
					args[j] = args[j + 1];
				}
			}
			else
				i++;
		}
	*/
		var command:String = args.shift();
		
		if (commandMap.get(command)!=null )
		{
			if (commandMap.get(command).root == true && _root == false)
				return 'You do not have permission to use "$command"';
			else
				return commandMap.get(command).fun(args);
		}
		else
			return '"$command" is not a recognized command.\nType "help" for list of commands.';
	}
}