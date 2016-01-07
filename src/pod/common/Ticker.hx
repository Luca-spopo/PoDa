package pod.common ;

//To run many "timers" on a single thread.
//Used by Mapper

import haxe.Timer;

class Ticker
{
	private var timer:Timer;
	//private var counter:Int;
	private var funs:Array<{fun:Void->Void, time:Int, init:Int}>;
	//Init is a misnomer. Read as "Number of timHandler calls left to execute function again"
	private var paused:Bool;
	public function new (period:Int)
	{
		timer = new Timer(period);
		timer.run = timHandler;
		//counter = 0;
		paused = true; //to prevent sync issues arising from laggy computers. The functions must get added before the timer runs off.
		funs = new Array<{fun:Void->Void, time:Int, init:Int}>();
	}
	
	///Add a timer. 1 unit of delay = one period (Should be called "interval"). Starts AFTER one cycle. Returns the index number of Timer added.
	public function addTimer(fun:Void->Void, delay:Int)
	{
		//return funs.push({fun:fun, time:delay, init:counter%delay})-1;
		return funs.push({fun:fun, time:delay, init:delay})-1;
	}
	
	///Remove a timer using its index number.
	public function removeTimer(index:Int)
	{
		if(index < 0 || index > funs.length-1)
			trace("Invalid index @ Ticker.removeTimer");
		for(i in index...funs.length-1)
		{
			funs[i] = funs[i+1];
		}
		funs.pop();
	}
	
	///Error margin: period
	public function pause()
	{
		paused = true;
	}
	
	///Error margin: period
	public function resume()
	{
		paused = false;
	}
	
	private function timHandler()	
	{
		if(!paused)
		{
			//counter++;
			//if(counter<0)
			//	counter=0;
			for(i in funs)
			{
				i.init--;
				//if( counter%funs[i].time == funs[i].init )
				if(i.init<=0)
				{
					i.fun();
					i.init=i.time;
				}
			}
		}
	}
	
}
