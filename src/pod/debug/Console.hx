package pod.debug ;

/**
 * ...
 * @author Luca
 * 27/12/2014 17:33
 * Do not copy
 */

import haxe.crypto.Md5;
import haxe.ds.Vector;
import haxe.PosInfos;
import openfl.display.FPS;
import flash.display.InteractiveObject;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
 
class Console extends Sprite
{
//	private var previousFocus:InteractiveObject;
	
	private var input:TextField;
	private var log:TextField;
	private var lastCmd:String;
	private var hud:FPS;
	private var show:Bool;
	public var debugLevel:Int;
	public var _root(default, null):Bool;
	private var cooldown:Int;
	private var timerIndex:Int;
	private static inline var consoleWidth = 300;
	private static inline var historyLimit = 300;
	
	public static function main()
	{
		Parser.main();
	}
	
	
	public function new() 
	{
		super();
		hud = new FPS();
		log = new TextField();
		input = new TextField();
		
		log.width = consoleWidth;
		log.height = 300;
		log.border = true;
		log.y = 50;
		log.multiline = true;
		log.defaultTextFormat = (new TextFormat("Lucida Console", 10, 0x8F8F8F));
		log.background = true;
		log.backgroundColor = 0x272727;
		
		input.defaultTextFormat = (new TextFormat("Lucida Console", 12, 0xFFFFFF));
		input.type = TextFieldType.INPUT;
		input.width = consoleWidth;
		input.height = 15;
		input.border = true;
		input.y = 350;
		input.background = true;
		input.backgroundColor = 0x272727;
		
		show = false;
		debugLevel = 0;
		_root = false;
		cooldown = 0;
	}
	
	///Toggles visibility of the console and associated elements. 1=force show, 2=force hide
	public function toggleShow(_show:Int=0)
	{
		switch(_show)
		{
			case 1	:	show = false;
			case 2	:	show = true;
			default	:
		}
		if (show)
		{
			#if (flash)	//TODO: Optamize for all platforms. Make a wrapper class maybe.
						//TODO: We are removing the last letter because of UI problems. Make sure to remove this when the new UI is implemented.
				input.replaceText(input.length - 1, input.length, "");
			#else
				input.text = input.text.substr(0, input.text.length-1);
			#end
			removeChild(hud);
			removeChild(log);
			removeChild(input);
			Main._stage.focus = null;
			show = false;
		}
		else
		{
			addChild(hud);
			addChild(log);
			addChild(input);
			Main._stage.focus = input;
			show = true;
		}
	}
	
	private function countdown()
	{
		if(cooldown>0)
			cooldown--;
		else
		{
			cooldown = 0;
			Main.tim.removeTimer(timerIndex);
		}
	}
	
	///1 = You are now root. 0 = Wrong pass. -ve = x*-100ms cooldown left
	public function su(pass:String):Int
	{
		if (_root)
			return 2;
		if (cooldown <= 0)   
		{
			//oppaiordiesalt42
			if (pass!=null && Md5.encode(pass + "salt42") == "4cdacf7eee337bd456e05e52cc8c0163")
			{
				_root = true;
				return 1;
			}
			else
			{
				cooldown = 30;
				timerIndex = Main.tim.addTimer(countdown, 1);
				return 0;
			}
		}
		else
			return -cooldown;
	}
	
	///Clears the log
	public function clear()
	{
		log.text = "";
	}
	
	public function runInput()
	{
		if (input.text.length != 0)
		{
			if(_root)
				stdOut("# " + input.text, 3);
			else
				stdOut("$ " + input.text, 3);
			stdOut(Parser.parse(input.text, _root), 3);
			lastCmd = new String(input.text);
			input.text = "";
		}
	}
	
	public function putLastCommand()
	{
		if(lastCmd!=null)
			input.text = lastCmd;
	}
	
	///Send output to the console. DBL: 0 = info, 1 = message, 2 = error, 3 = response.
	public function stdOut(output:Dynamic, dbl:Int, ?pos:PosInfos)
	{
		
		#if (flash9 || flash10)
			untyped __global__["trace"]("DEBUG LEVEL "+dbl+" "+pos.fileName+":"+pos.lineNumber+":\t", output, " @ "+pos.className+"."+pos.methodName);
        #elseif flash
			flash.Lib.trace("DEBUG LEVEL "+dbl+" "+pos.fileName+":"+pos.lineNumber+":\t"+output+" @ "+pos.className+"."+pos.methodName);
        #end
		
		
		
		if (dbl >= debugLevel)
		{
			if (dbl >= 2)
				toggleShow(1);
			#if (flash)
				if (log.numLines >= historyLimit)
					log.replaceText(0, log.getLineLength(0), "");
			#end
			log.appendText (output + "\n");
			#if (flash)
				if (log.selectedText == "")
			#end
					log.scrollV = log.maxScrollV;
		}
	}
	
}