package com.zext
{
	import com.zext.event.*;
	import com.zext.eventdispatcher.MakeDirectory;
	import com.zext.eventdispatcher.UploadFiles;
	
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filesystem.File;
	
	import mx.core.Window;
	
	import spark.components.TextArea;

	public class SAEToolsHandler extends EventDispatcher
	{
		private const build_number:String = "SAETools 0.0.1";
		
		// 初始化变量
		private var uploadURL:String // 服务器路径包括通用变量，如app_id等
		private var last:String // 父目录
		private var params:Object;
		private var flashvar:Object;
		
		// 用于跟状态的变量
		private var file:File = new File;		// 保存所有将要上传的文件的队列.
		private var current_file_item:FileItem = null;	// 当前正要上传的项目.
		private var current_dir:File = null; //  当前正在处理的子目录
		
		private var file_index:Array = new Array();   // 保存上传的项目
		
		private var successful_uploads:Number = 0;		// 当前已经完成上传的文件数量
		private var queue_errors:Number = 0;			// Tracks files rejected during queueing
		private var upload_errors:Number = 0;			// Tracks files that fail upload
		private var upload_cancelled:Number = 0;		// Tracks number of cancelled files
		private var queued_uploads:Number = 0;			// 当前正在排队等待上传的文件数量
		
		private var dir_queue:Array = new Array;  //保存当前目录下需要新建的目录
		private var file_queue:Array = new Array; //保存当前目录下等待上传的文件
		
		private var debugEnabled:Boolean = false;  //开关,控制日志输出
		private var debugInfo:TextArea = null;
		
		public function SAEToolsHandler(file:File,uploadURL:String,params:Object,flashvar:Object,debugInfo:TextArea = null)
		{
			this.file = file;
			this.uploadURL = uploadURL;
			this.params = params;
			this.flashvar = flashvar;
			this.debugInfo = debugInfo;
		}
		
		/**
		 * 开始文件上传 
		 * 
		 */		
		public function start():void{
			Debug("Start Upload")
			if(!file.isDirectory){
				return
			}
			file_queue = file.getDirectoryListing();
			dir_queue = new Array;
			for(var i:int= 0;i<file_queue.length;i++){
				if(file_queue[i].isDirectory){
					dir_queue.push(file_queue.splice(i,1)[0]);
					i--;
				}
			}
			// 上传当前目录下的文件
			var uHandler:UploadFiles = new UploadFiles(file_queue,uploadURL,params,flashvar,debugInfo);
			uHandler.addEventListener(SAEToolEvent.UPLOAD_COMPLETE,uploadSuccess);
			Debug("Upload Files Start ")
			uHandler.strat();
		}
		
		/**
		 * 文件上完成之后的回调函数 ,开始新建当前目录的子目录
		 * @param event
		 * 
		 */		
		private function uploadSuccess(event:SAEToolEvent):void{
			Debug("Upload Files Success and Next Make SubDirectory ")
			var mHandler:MakeDirectory = new MakeDirectory(dir_queue,uploadURL,params,flashvar,debugInfo);
			mHandler.addEventListener(SAEToolEvent.MAKE_DIR_COMPLETE,makeDirSuccess);
			mHandler.strat();
		}
		/**
		 * 新建目录完成后的回调函数 ,开始上传子目录的内容
		 * @param event
		 * 
		 */		
		private function makeDirSuccess(event:SAEToolEvent):void{
			Debug("Make SubDirectory Success and Next Process SubDirectory")
			processNextSubDir();
		}
		/**
		 * 当前子目录上传完成后的回调函数,继续处理下一个子目录 
		 * @param event
		 * 
		 */		
		private function processNextSubDir(event:SAEToolEvent=null):void{
			if(dir_queue.length>0){
				current_dir = this.dir_queue.shift();
				Debug("Process SubDirectory: " + current_dir.name)
				var subParams:Object = new Object;
				for (var key:String in params){
					if (params.hasOwnProperty(key)) {
						subParams[key] = params[key];
					}
				}
				subParams["last"]=subParams["last"]+"/"+ current_dir.name;
				var uploadSubDir:SAEToolsHandler = new SAEToolsHandler(current_dir,uploadURL,subParams,flashvar,debugInfo);
				uploadSubDir.addEventListener(SAEToolEvent.CURRENT_DIR_COMPLETE,processNextSubDir);
				uploadSubDir.SetDebugEnabled(this.debugEnabled);
				uploadSubDir.start();
			}else{
				currentDirComplete();
			}
		}
		/**
		 * 当前目录上传处理完成 
		 * 
		 */		
		private function currentDirComplete():void{
			Debug("Current Directory Process Complete");
			
			var e:SAEToolEvent = new SAEToolEvent(SAEToolEvent.CURRENT_DIR_COMPLETE);
			this.dispatchEvent(e);
		}
		
		
		public function SetDebugEnabled(debug_enabled:Boolean):void {
			this.debugEnabled = debug_enabled;
			if(debugEnabled){
				if (this.debugInfo == null){					
					var newWindow:Window = new Window(); 
					newWindow.title = "DebugWindow"; 
					newWindow.width = 500; 
					newWindow.height = 600; 
					newWindow.open(true);
					debugInfo = new TextArea;
					debugInfo.percentHeight = 100;
					debugInfo.percentWidth = 100;
					debugInfo.editable = false;
					debugInfo.text = "SetDebugEnabled";
					newWindow.addElement(debugInfo);
					PrintDebugInfo();
				}
			}
		}
		private function Debug(msg:String):void {
			try {
				if (this.debugEnabled) {
					var lines:Array = msg.split("\n");
					for (var i:Number=0; i < lines.length; i++) {
						lines[i] = file.nativePath+"    " + lines[i];
						var str:String = new String;
						debugInfo.text +="\n"+ lines[i];
					}
					trace(lines.join("\n"));
				}
			} catch (ex:Error) {
				trace(ex);
			}
		}
		
		private function PrintDebugInfo():void {
			var debug_info:String = "\n----- SWF DEBUG OUTPUT ----\n";
			debug_info += "Build Number:           " + this.build_number + "\n";
			debug_info += "Upload URL:             " + this.uploadURL + "\n";
			debug_info += "File Directory:         " + this.file.nativePath + "\n";
			debug_info += "Params:\n";
			for (var key:String in this.params) {
				if (this.params.hasOwnProperty(key)) {
					debug_info += "                        " + key + "=" + this.params[key] + "\n";
				}
			}
			debug_info += "Flashvar:\n";
			for (key in this.flashvar) {
				if (this.flashvar.hasOwnProperty(key)) {
					debug_info += "                        " + key + "=" + this.flashvar[key] + "\n";
				}
			}
			debug_info += "----- END SWF DEBUG OUTPUT ----\n";			
			this.Debug(debug_info);
		}
	}
}