/*
 @Author: Luca
 12/2014
 katoch.anirudh@gmail.com
 Do not copy
 */



package pod.common ;

import pod.common.GifData;

class Gif
{
	private var data:GifData;
	public var framesLeft(default, null):Int;
	public var time(default, null):Int;
	public var anim(default, null):Int;	//Current Anim in progress
	public var offsetX:Int;
	public var offsetY:Int;
	public var frozen:Bool;
	public var tileNumber(default, null):Int;
	public function new ()
	{
		frozen=true;
		anim = 0;
		framesLeft = 0;
		offsetX = offsetY = 0;
	}
	
	public function getBase():Int
	{
		return data.base;
	}
	
	public function setGifData(_data:GifData, _anim:Int=0, _frame:Int = 0, _timeLeft:Int=0, _frozen:Bool=false)
	{
		data = _data;
		if(_data!=null)
			animByTime(_anim, _timeLeft, _frozen, _frame);
		/*
		framesLeft = _data.anims[_anim].anim.length;
		time = _data.anims[_anim].anim[framesLeft].time;
		anim=_anim;	//not validating
		frozen = false;
		for (i in 0...passed_time)
		{
			timHandler();
		}
		frozen = _frozen;
		*/
	}
	
	public inline function timHandler()
	{
		if(data != null && !frozen)
		{
			var bla = data.anims[anim];
			if (time < 0)
			{
				time += bla.anim[framesLeft].time;
			}
			if(time>0)
			{
				time--;
			}
			else
			{
				framesLeft--;
				if(framesLeft<0)
				{
					if(bla.next!=null)
					{
						anim = bla.next[Std.random(bla.next.length)];
						bla = data.anims[anim];
	  					framesLeft = bla.anim.length - 2 - framesLeft;
						/*Don't ask me why framesLeft is needed. I do not understand
						 *this magic myself, but it doesn't work without it. Do the maths
						 *yourself to see why.
						 */
					}
					else
					{
						frozen=true;
						framesLeft=0;
					}	
				}
				var cf =  bla.anim[framesLeft];
				tileNumber = cf.frame;
				time = cf.time;
				offsetX = cf.offsetX;
				offsetY = cf.offsetY;
			}
		}
	}
	
	/*Plays a particular animation, starting at the beginning of a frame, determined by the argument given.
	 * Positive values for frame: Expresses the number of FRAMES REMAINING before current animation is complete.
	 * Negative values: -1 means "first frame", -2 means "Second frame" etc.
	 * This is faster than function animByTime()
	 */
	public function animByFrame(a:Int, frame:Int, freeze:Bool ):Bool	//force animate to a particular part
	{
	if(data!=null)
	{
		if(a<0 || a>=data.anims.length)
		{
			Main.console.stdOut("invalid a @ Gif.animByFrame", 2);
			anim=0;
		}
		else
			anim=a;
			
		frozen = freeze;
		var bla = data.anims[a];
		var something = bla.anim.length;
		if(frame<0)
			framesLeft= something+frame; //-1 means "First" frame, -2 means "second" frame
		else
			framesLeft = frame;
		if(framesLeft>=something || framesLeft <0)
		{
			Main.console.stdOut("invalid frame @ Gif.anim", 2);
			framesLeft=0;
		}
		var bla2 = bla.anim[framesLeft];
		tileNumber = bla2.frame;
		time = bla2.time;
		
		offsetX = bla2.offsetX;
		offsetY = bla2.offsetY;
		return true;
	}
	else
	{
		return false;
	}	
	}
	
	/* Plays a particular animation from the start or a frame and fast-forwards by
	 * complement of the given number of intervals of time (Since time = 0 means
	 * "End of animation")
	 * 
	 * -1 means "the beginning of the frame", -2 means "1 interval later", etc.
	 */
	public function animByTime(a:Int,timeLeft:Int, freeze:Bool,  frame:Int = -1 )	//force animate to a particular part
	{
		if (timeLeft < 0)
		{
			timeLeft += 1 +  data.anims[a].anim[framesLeft].time;
		}
		if(animByFrame(a, frame, freeze))
			for (i in 0...(data.anims[a].anim[framesLeft].time-timeLeft))
				timHandler();
	}
			
	public inline function dataExists():Bool
	{
		return data != null;
	}
	
}
