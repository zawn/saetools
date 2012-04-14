package com.zext.temp
{
	import flash.display.*;
	import flash.geom.Rectangle;
	import flash.html.HTMLHost;
	import flash.html.HTMLLoader;
	import flash.net.*;
	import flash.text.TextField;
	
	public class CustomHost extends HTMLHost
	{
		import flash.html.*;
		public var statusField:TextField;
		public function CustomHost(defaultBehaviors:Boolean=false)
		{
			super(false);
		}
		override public function createWindow(windowCreateOptions:HTMLWindowCreateOptions):HTMLLoader 
		{ 
			var initOptions:NativeWindowInitOptions = new NativeWindowInitOptions(); 
			var bounds:Rectangle = new Rectangle(windowCreateOptions.x, 
				windowCreateOptions.y, 
				windowCreateOptions.width, 
				windowCreateOptions.height); 
			var htmlControl:HTMLLoader = HTMLLoader.createRootWindow(true, initOptions, 
				windowCreateOptions.scrollBarsVisible, bounds); 
			htmlControl.htmlHost = new CustomHost(); 
			if(windowCreateOptions.fullscreen){ 
				htmlControl.stage.displayState = 
					StageDisplayState.FULL_SCREEN_INTERACTIVE; 
			} 
			return htmlControl; 
		} 
		override public function updateTitle(title:String):void 
		{ 
			htmlLoader.stage.nativeWindow.title = title; 
		} 
		
		override public function windowClose():void 
		{ 
			htmlLoader.stage.nativeWindow.close(); 
		}
		
		override public function updateLocation(locationURL:String):void 
		{ 
			super.updateLocation(locationURL);
		}
		override public function windowBlur():void
		{
			htmlLoader.alpha = 0.5;
		}
		override public function windowFocus():void
		{
			htmlLoader.alpha = 1;
		}
	}
}