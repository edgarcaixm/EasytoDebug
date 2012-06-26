package
{
	import com.demonsters.debugger.MonsterDebugger;
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.net.*;
	import flash.sampler.*;
	import flash.system.*;
	import flash.text.StaticText;
	import flash.ui.*;
	import flash.utils.*;
	
	import swfParser.SWFParser;
	
	public class MicroProfiler extends Sprite
	{
		public static var MySprite:Sprite = null;
		public static var MainStage:Stage = null;
		public static var MainSprite:Sprite = null;
		
		private static var needReloading:Boolean = false;	//Only for class merging
		private static var reloaded:Boolean = false;	//Only for class merging
		
		//add edgarcai's sign
		private static var author:String = "edgarcai"; 
		
		public function MicroProfiler()
		{
			if(!stage)
			{
				this.addEventListener(Event.ADDED_TO_STAGE,onstartup);
			}else
			{
				onstartup();
			}
		}
		
		protected function onstartup(event:Event=null):void
		{
			if(event)
			{
				this.removeEventListener(Event.ADDED_TO_STAGE,onstartup);
			}
			MonsterDebugger.initialize(this);
			MonsterDebugger.trace(this, "microprofiler startup");
			
			flash.system.Security.allowDomain("*");
			flash.system.Security.allowInsecureDomain("*");
			
			MySprite = this;
			root.addEventListener("allComplete", this.allCompleteHandler);
			
			//Preloaded Params
			var paramName:String = null;
			var paramValue:String = null;
			for (paramName in this.loaderInfo.parameters)
			{
				paramValue = this.loaderInfo.parameters[paramName];
				MonsterDebugger.trace(this,"PreloadSWF Params:"+paramName+ " = "+paramValue);
			}
			
		}
		
		protected function allCompleteHandler(event:Event):void
		{
			if (reloaded) return;
			
			var loaderInfo:LoaderInfo;
			var theValue:String;
			
			try
			{
				loaderInfo = LoaderInfo(event.target);
				
				if (loaderInfo.content.root.stage == null) { 
					return; 
				}
				
				MainSprite = loaderInfo.content.root as Sprite;
				MainStage = MainSprite.stage;
				
				//Remove all previous sprite
				if (needReloading)
				{
					while (MainStage.numChildren > 0)
					{
						var obj:Sprite = MainStage.removeChildAt(0) as Sprite;
						obj.mouseChildren = false;
						obj.mouseEnabled = false;
						obj.visible = false;
					}
				}
				MainStage.addChild(this);				
				
				if (needReloading) 
				{
					var loader:Loader = new Loader();
					loader.contentLoaderInfo.addEventListener(Event.COMPLETE, OnReLoadCompleted);
					loader.loadBytes(MainStage.loaderInfo.bytes, new LoaderContext(false, ApplicationDomain.currentDomain));
				}
				
				var paramName:String;
				var paramValue:String;
				while (paramName in loaderInfo.parameters)
				{
					paramValue = loaderInfo.parameters[paramName];
					MonsterDebugger.trace(this,"Main Params:"+ paramName+" = "+ theValue);
				}
				reloaded = true;
				var swf:SWFParser = new SWFParser(MainStage.loaderInfo.bytes);
				MainStage.frameRate = swf.frameRate;
			}
			catch (e:Error)
			{
				MonsterDebugger.trace(this,e.toString());
			}
		}
		
		protected function OnReLoadCompleted(event:Event):void
		{
			var exist:Boolean = ApplicationDomain.currentDomain.hasDefinition("AnyClass");
			MonsterDebugger.trace(this,"Reloaded, class exist?"+exist);
			MainStage.addChild(event.target.content);
			MonsterDebugger.inspect(event.target.content);
			reloaded = true;
		}
	}
}