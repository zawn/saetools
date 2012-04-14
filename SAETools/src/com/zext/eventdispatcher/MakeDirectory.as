package com.zext.eventdispatcher
{
	import com.zext.event.SAEToolEvent;
	
	import flash.events.*;
	import flash.filesystem.File;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	import spark.components.TextArea;
	
	public class MakeDirectory extends EventDispatcher
	{
		private var debugInfo:TextArea = null;
		private var uploadURL:String;
		private var app_id:String;
		private var last:String // 父目录
		private var params:Object;
		private var flashvar:Object;
		
		private var current_item:String // 正在创建的目录名称
		private var dirNameQueue:Array = new Array;
		
		public function MakeDirectory(dir_queue:Array,uploadURL:String,params:Object,flashvar:Object,debugInfo:TextArea = null,target:IEventDispatcher=null)
		{
			super(target);
			this.debugInfo = debugInfo;
			this.app_id = params["app_id"];
			this.last = params["last"];
			this.uploadURL = uploadURL+"&a=makedir&domName="+params["domName"]+ "&app_id="+app_id+"&last="+last;
			this.debugInfo = debugInfo;
			for(var i:String in dir_queue){
				dirNameQueue.push(dir_queue[i].name)
			}
		}
		public function strat():void{
			if(dirNameQueue.length>0){
				this.current_item = dirNameQueue.shift();
				var loader:URLLoader = new URLLoader();
				loader.addEventListener(Event.COMPLETE, completeHandler); 
				loader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS,responseHandler);
				loader.addEventListener(IOErrorEvent.IO_ERROR,ioHandler);
				try 
				{ 
					loader.load(this.BuildRequest(this.current_item)); 
				} 
				catch (error:ArgumentError) 
				{ 
					trace("An ArgumentError has occurred."); 
				} 
				catch (error:SecurityError) 
				{ 
					trace("A SecurityError has occurred."); 
				} 
			}else{
				this.uploadSuccess();
			}
		}
		
		private function ioHandler(event:IOErrorEvent):void
		{
			Debug(this.current_item +" creater error");
		}
		private function responseHandler(event:HTTPStatusEvent):void
		{
			Debug(event.status +"");
			Debug(event.responseURL);
			for each (var i:URLRequestHeader in event.responseHeaders){
				Debug(i.name+":"+i.value);
				
			}
		}
		private function completeHandler(event:Event):void 
		{ 
			this.current_item = null;
			this.strat();
		} 
		
		/**
		 * 文件上传完成后的回调函数 
		 * @param event
		 * 
		 */		
		private function uploadSuccess():void
		{
			var e:SAEToolEvent = new SAEToolEvent(SAEToolEvent.MAKE_DIR_COMPLETE);
			this.dispatchEvent(e);
		}
		
		private function BuildRequest(foldername:String):URLRequest {
			// Create the request object
			var request:URLRequest = new URLRequest();
			request.requestHeaders.push(new URLRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:11.0) Gecko/20100101 Firefox/11.0"));
			request.requestHeaders.push(new URLRequestHeader("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"));
			request.requestHeaders.push(new URLRequestHeader("Accept-Language", "zh-cn,zh;q=0.8,en-us;q=0.5,en;q=0.3"));
			request.requestHeaders.push(new URLRequestHeader("Accept-Encoding", "gzip, deflate"));
			request.requestHeaders.push(new URLRequestHeader("DNT", "1"));
			request.requestHeaders.push(new URLRequestHeader("Referer", this.uploadURL));
			
			request.method = URLRequestMethod.POST;
			
			var key:String;
			var post:URLVariables = new URLVariables();
			post["app_id"] = this.app_id;
			post["last"] = this.last;
			post["foldername"] = foldername;
			
			request.url = this.uploadURL;
			request.data = post;
			
			return request;
		}
		
		private function Debug(msg:String):void {
			try {
				if (this.debugInfo != null) {
					var lines:Array = msg.split("\n");
					for (var i:Number=0; i < lines.length; i++) {
						lines[i] ="                    " + lines[i];
						var str:String = new String;
						debugInfo.text +="\n"+ lines[i];
					}
					trace(lines.join("\n"));
				}
			} catch (ex:Error) {
				trace(ex);
			}
		}
		
	}
}