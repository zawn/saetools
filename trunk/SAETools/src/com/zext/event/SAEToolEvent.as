package com.zext.event
{
	import flash.events.Event;
	
	public class SAEToolEvent extends Event
	{
		public static var UPLOAD_COMPLETE:String = "upload_complete";
		public static var MAKE_DIR_COMPLETE:String = "make_dir_complete";
		public static var CURRENT_DIR_COMPLETE:String = "current_dir_complete";
		
		public function SAEToolEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}