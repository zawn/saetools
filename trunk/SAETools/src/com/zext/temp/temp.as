package com.zext.temp
{
	import com.zext.SAEToolsHandler;
	
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.html.*;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	
	import mx.controls.Alert;
	import mx.controls.HTML;
	import mx.core.UIComponent;
	import mx.events.FileEvent;
	import mx.events.FlexNativeWindowBoundsEvent;
	import mx.events.ListEvent;
	
	import org.osmf.elements.HTMLElement;
	
	import spark.components.TextInput;

	public class temp
	{
		public function temp()
		{
			
			
			
			[Bindable]
			private var customHost:CustomHost = new CustomHost(false);
			
			private var file:File = new File;
			
			private var htmlContainer:HTML = new HTML;
			private var urlString:TextInput = new TextInput;
			
			protected function button1_clickHandler(event:MouseEvent):void
			{
				// TODO Auto-generated method stub
				htmlContainer.htmlLoader.historyBack();
			}
			
			protected function button2_clickHandler(event:MouseEvent):void
			{
				// TODO Auto-generated method stub
				htmlContainer.htmlLoader.historyForward();
			}
			
			protected function button3_clickHandler(event:MouseEvent):void
			{
				// TODO Auto-generated method stub
				htmlContainer.htmlLoader.reload();
			}
			
			protected function button4_clickHandler(event:MouseEvent):void
			{
				// TODO Auto-generated method stub
				loader();
				
			} 
			
			private function loadSESSID(url:String):void
			{
				var request:URLRequest = new URLRequest(url);
				
				//设置http请求头
				request.requestHeaders.push(new URLRequestHeader("Host", "sae.sina.com.cn"));
				request.requestHeaders.push(new URLRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:11.0) Gecko/20100101 Firefox/11.0"));
				request.requestHeaders.push(new URLRequestHeader("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"));
				request.requestHeaders.push(new URLRequestHeader("Accept-Language", "zh-cn,zh;q=0.8,en-us;q=0.5,en;q=0.3"));
				request.requestHeaders.push(new URLRequestHeader("Accept-Encoding", "gzip, deflate"));
				request.requestHeaders.push(new URLRequestHeader("DNT", "1"));
				request.requestHeaders.push(new URLRequestHeader("Referer", "http://sae.sina.com.cn/"));
				
				var loader:URLLoader = new URLLoader();
				loader.addEventListener(Event.COMPLETE, completeHandler); 
				loader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS,responseHandler);
				loader.addEventListener(IOErrorEvent.IO_ERROR,ioHandler);
				try 
				{ 
					loader.load(request); 
				} 
				catch (error:ArgumentError) 
				{ 
					trace("An ArgumentError has occurred."); 
				} 
				catch (error:SecurityError) 
				{ 
					trace("A SecurityError has occurred."); 
				} 
			}
			
			private function ioHandler(event:IOErrorEvent):void
			{
				trace(event.errorID);
			}
			private function responseHandler(event:HTTPStatusEvent):void
			{
				trace(event.status);
				trace(event.responseURL);
				for each (var i:URLRequestHeader in event.responseHeaders){
					trace(i.name+":"+i.value);
					if(i.name == "Set-Cookie"){						
						trace("              "+i.value);
					}
				}
			}
			private function completeHandler(event:Event):void 
			{ 
				trace("----------------------------------------------------"); 
			} 
			private function htmlCompleteHandler(event:Event):void 
			{ 
				trace("html complete------------------------------------------------");
			} 
			
			private function loader():void 
			{ 
				var url:String = urlString.text; 
				if(url==""){
					url = "sae.sina.com.cn/?m=myapp";
					urlString.text = url;
				}
				if(!url.match("^http://")){
					url = "http://"+url;
				}
				
				if(url.match("^(http://(([0-9a-zA-Z])+([-\w]*[0-9a-zA-Z])*\.)+[0-9a-zA-Z]{2,9})"))
				{
					var urlReq:URLRequest = new URLRequest(url); 
					urlReq.requestHeaders.push(new URLRequestHeader("Host", "sae.sina.com.cn"));
					urlReq.requestHeaders.push(new URLRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:11.0) Gecko/20100101 Firefox/11.0"));
					urlReq.requestHeaders.push(new URLRequestHeader("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"));
					urlReq.requestHeaders.push(new URLRequestHeader("Accept-Language", "zh-cn,zh;q=0.8,en-us;q=0.5,en;q=0.3"));
					urlReq.requestHeaders.push(new URLRequestHeader("Accept-Encoding", "gzip, deflate"));
					urlReq.requestHeaders.push(new URLRequestHeader("DNT", "1"));
					urlReq.requestHeaders.push(new URLRequestHeader("Referer", "http://sae.sina.com.cn/"));
					htmlContainer.htmlLoader.addEventListener(Event.COMPLETE,htmlCompleteHandler);
					//					htmlContainer.htmlLoader.htmlHost = null;
					htmlContainer.htmlLoader.load(urlReq);
				}else{
					Alert.show("非法地址："+url);
				}
			} 
			
			protected function button5_clickHandler(event:MouseEvent):void
			{
				// TODO Auto-generated method stub
				var url:String = urlString.text;
				if(url==""){
					url = "sae.sina.com.cn/?m=myapp";
					urlString.text = url;
				}
				if(!url.match("^http://")){
					url = "http://"+url;
				}
				if(url.match("^(http://(([0-9a-zA-Z])+([-\w]*[0-9a-zA-Z])*\.)+[a-zA-Z]{2,9})"))
				{
					loadSESSID(url);
				}else{
					Alert.show("非法地址："+url);
				}
			}
			
			//			protected function windowedapplication1_windowResizeHandler(event:FlexNativeWindowBoundsEvent):void
			//			{
			//			}
			
			private function dispatchLocationChange (e:Event):void
			{
				urlString.text =  htmlContainer.location
			}
			
			protected function filesystemtree1_changeHandler(event:ListEvent):void
			{
				// TODO Auto-generated method stub
				trace(event.target.toString())
			}
			
			protected function filesystemtree1_directoryChangeHandler(event:FileEvent):void
			{
				// TODO Auto-generated method stub
				trace(event.target.name);
			}
			
			protected function filesystemtree1_fileChooseHandler(event:FileEvent):void
			{
				// TODO Auto-generated method stub
				trace("---------"+event.target.name);
			}
			
			protected function upload_clickHandler(event:MouseEvent):void
			{
				var html:HTMLLoader = htmlContainer.htmlLoader;
				var o:Object = html.window.document.getElementsByName("flashvars");
				if(o.length>0){
					trace(o[0].value)
					var flashvars:String = o[0].value;
					var lines:Array = flashvars.split("&");
					var flashvarKeyValue:Object = new Object;
					for (var i:Number=0; i < lines.length; i++) {
						var temp:Array = lines[i].split("=");
						trace(lines[i]);
						flashvarKeyValue[temp[0]] = temp[1];
					}
					var paramsArray:Array = flashvarKeyValue["params"].split("%26");
					var params:Object = new Object;
					for (i=0; i < paramsArray.length; i++) {
						temp = paramsArray[i].split("%3D");
						temp[0] = temp[0].replace("amp%3B","");
						params[temp[0]] = temp[1];
					}
					file.addEventListener(Event.SELECT, function():void{
						dirSelected(event,params,flashvarKeyValue);
					}); 
					file.browseForDirectory("Select a directory"); 
				}else{
					Alert.show("获取参数失败.请确人已近打开上传对话框!");
				}
			}
			private function dirSelected(event:Event,params:Object,flashvar:Object):void {
				trace(file.nativePath);
				var url:String = "http://sae.sina.com.cn"; 
				var toolsHandler:SAEToolsHandler = new SAEToolsHandler(file,url,params,flashvar);
				toolsHandler.SetDebugEnabled(true);
				toolsHandler.start();
			}
			
			private function makedir(url:String,last:String,foldername:String):void{
				var request:URLRequest = new URLRequest(url+"&foldername="+foldername+"&last="+last);
				
				//设置http请求头
				request.requestHeaders.push(new URLRequestHeader("Host", "sae.sina.com.cn"));
				request.requestHeaders.push(new URLRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:11.0) Gecko/20100101 Firefox/11.0"));
				request.requestHeaders.push(new URLRequestHeader("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"));
				request.requestHeaders.push(new URLRequestHeader("Accept-Language", "zh-cn,zh;q=0.8,en-us;q=0.5,en;q=0.3"));
				request.requestHeaders.push(new URLRequestHeader("Accept-Encoding", "gzip, deflate"));
				request.requestHeaders.push(new URLRequestHeader("DNT", "1"));
				request.requestHeaders.push(new URLRequestHeader("Referer", url+"&last="+last));
				
				var loader:URLLoader = new URLLoader();
				loader.addEventListener(Event.COMPLETE, completeHandler); 
				loader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS,responseHandler);
				loader.addEventListener(IOErrorEvent.IO_ERROR,ioHandler);
				try 
				{ 
					loader.load(request); 
				} 
				catch (error:ArgumentError) 
				{ 
					trace("An ArgumentError has occurred."); 
				} 
				catch (error:SecurityError) 
				{ 
					trace("A SecurityError has occurred."); 
				} 
			}
		}
	}
}