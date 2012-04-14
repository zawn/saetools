package com.zext.eventdispatcher
{
	import com.zext.ExternalCall;
	import com.zext.FileItem;
	import com.zext.event.SAEToolEvent;
	
	import flash.events.*;
	import flash.net.FileReference;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.Timer;
	
	import spark.components.TextArea;
	
	public class UploadFiles extends  EventDispatcher
	{
		private var debugInfo:TextArea = null;
		private var progressbar:ProgressImg = new ProgressImg();
	
		private var fileWaitQueue:Array = new Array;
		
		private var file_queue:Array = new Array();		// holds a list of all items that are to be uploaded.
		private var current_file_item:FileItem = null;	// the item that is currently being uploaded.

		
		private var file_index:Array = new Array();
				
		private var successful_uploads:Number = 0;		// Tracks the uploads that have been completed
		private var queue_errors:Number = 0;			// Tracks files rejected during queueing
		private var upload_errors:Number = 0;			// Tracks files that fail upload
		private var upload_cancelled:Number = 0;		// Tracks number of cancelled files
		private var queued_uploads:Number = 0;			// Tracks the FileItems that are waiting to be uploaded.
		
		private var movieName:String = "SAETools";
		private var uploadURL:String;
		private var filePostName:String;
		private var uploadPostObject:Object;
		private var fileTypes:String;
		private var fileTypesDescription:String;
		private var fileSizeLimit:Number;
		private var fileUploadLimit:Number = 0;
		private var fileQueueLimit:Number = 0;
		private var useQueryString:Boolean = false;
		private var requeueOnError:Boolean = false;
		private var httpSuccess:Array = [];
		private var assumeSuccessTimeout:Number = 0;
		private var debugEnabled:Boolean;
		
		private var serverDataTimer:Timer = null;
		private var assumeSuccessTimer:Timer = null;
		
		// Error code "constants"
		// Size check constants
		private var SIZE_TOO_BIG:Number		= 1;
		private var SIZE_ZERO_BYTE:Number	= -1;
		private var SIZE_OK:Number			= 0;
		
		// Queue errors
		private var ERROR_CODE_QUEUE_LIMIT_EXCEEDED:Number 			= -100;
		private var ERROR_CODE_FILE_EXCEEDS_SIZE_LIMIT:Number 		= -110;
		private var ERROR_CODE_ZERO_BYTE_FILE:Number 				= -120;
		private var ERROR_CODE_INVALID_FILETYPE:Number          	= -130;
		
		// Upload Errors
		private var ERROR_CODE_HTTP_ERROR:Number 					= -200;
		private var ERROR_CODE_MISSING_UPLOAD_URL:Number        	= -210;
		private var ERROR_CODE_IO_ERROR:Number 						= -220;
		private var ERROR_CODE_SECURITY_ERROR:Number 				= -230;
		private var ERROR_CODE_UPLOAD_LIMIT_EXCEEDED:Number			= -240;
		private var ERROR_CODE_UPLOAD_FAILED:Number 				= -250;
		private var ERROR_CODE_SPECIFIED_FILE_ID_NOT_FOUND:Number 	= -260;
		private var ERROR_CODE_FILE_VALIDATION_FAILED:Number		= -270;
		private var ERROR_CODE_FILE_CANCELLED:Number				= -280;
		private var ERROR_CODE_UPLOAD_STOPPED:Number				= -290;
		
		// Callbacks Has no effect here But keep 
		private var flashReady_Callback:String;
		private var fileDialogStart_Callback:String;
		private var fileQueued_Callback:String;
		private var fileQueueError_Callback:String;
		private var fileDialogComplete_Callback:String;
		
		private var uploadStart_Callback:String;
		private var uploadProgress_Callback:String;
		private var uploadError_Callback:String;
		private var uploadSuccess_Callback:String;
		
		private var uploadComplete_Callback:String;
		
		private var debug_Callback:String;
		private var testExternalInterface_Callback:String;
		private var cleanUp_Callback:String;
		
		private var valid_file_extensions:Array = new Array();// Holds the parsed valid extensions.
		
		public function UploadFiles(fileWaitQueue:Array,uploadURL:String,params:Object,flashvar:Object,debugInfo:TextArea = null,target:IEventDispatcher=null)
		{
			super(target);
			this.debugInfo = debugInfo;
			this.fileWaitQueue = fileWaitQueue;
			
			// Get the Flash Vars
			this.uploadURL = uploadURL+"&a=upload";
			this.filePostName = flashvar.filePostName;
			this.fileTypes = flashvar.fileTypes;
			this.fileTypesDescription = flashvar.fileTypesDescription + " (" + this.fileTypes + ")";
			this.loadPostParams(params);
			
			
			if (!this.filePostName) {
				this.filePostName = "Filedata";
			}
			if (!this.fileTypes) {
				this.fileTypes = "*.*";
			}
			if (!this.fileTypesDescription) {
				this.fileTypesDescription = "All Files";
			}
			
			this.LoadFileExensions(this.fileTypes);
			
			try {
				this.debugEnabled = debugInfo != null ? true : false;
			} catch (ex:Object) {
				this.debugEnabled = false;
			}
			
			try {
				this.SetFileSizeLimit(String(flashvar.fileSizeLimit));
			} catch (ex:Object) {
				this.fileSizeLimit = 0;
			}
			
			
			try {
				this.fileUploadLimit = Number(flashvar.fileUploadLimit);
				if (this.fileUploadLimit < 0) this.fileUploadLimit = 0;
			} catch (ex:Object) {
				this.fileUploadLimit = 0;
			}
			
			try {
				this.fileQueueLimit = Number(flashvar.fileQueueLimit);
				if (this.fileQueueLimit < 0) this.fileQueueLimit = 0;
			} catch (ex:Object) {
				this.fileQueueLimit = 0;
			}
			
			// Set the queue limit to match the upload limit when the queue limit is bigger than the upload limit
			if (this.fileQueueLimit > this.fileUploadLimit && this.fileUploadLimit != 0) this.fileQueueLimit = this.fileUploadLimit;
			// The the queue limit is unlimited and the upload limit is not then set the queue limit to the upload limit
			if (this.fileQueueLimit == 0 && this.fileUploadLimit != 0) this.fileQueueLimit = this.fileUploadLimit;
			
			try {
				this.useQueryString = flashvar.useQueryString == "true" ? true : false;
			} catch (ex:Object) {
				this.useQueryString = false;
			}
			
			try {
				this.requeueOnError = flashvar.requeueOnError == "true" ? true : false;
			} catch (ex:Object) {
				this.requeueOnError = false;
			}
			
			try {
				this.SetHTTPSuccess(String(flashvar.httpSuccess));
			} catch (ex:Object) {
				this.SetHTTPSuccess([]);
			}
			
			try {
				this.SetAssumeSuccessTimeout(Number(flashvar.assumeSuccessTimeout));
			} catch (ex:Object) {
				this.SetAssumeSuccessTimeout(0);
			}
			
//			this.Debug("SWFUpload Init Complete");
		}
		
		public function strat():void{
			Select_Many_Handler();
		}
		/**
		 * 文件上传完成后的回调函数 
		 * @param event
		 * 
		 */		
		private function allFileUploaded():void
		{
			var e:SAEToolEvent = new SAEToolEvent(SAEToolEvent.UPLOAD_COMPLETE);
			this.dispatchEvent(e);
		}
		
		
		/**
		 * 以下为SWF代码
		 * 
		 */
		/* *****************************************
		* FileReference Event Handlers
		* *************************************** */
		private function Open_Handler(event:Event):void {
			this.Debug("Event: uploadProgress (OPEN): File ID: " + this.current_file_item.id);
			ExternalCall.UploadProgress(this.uploadProgress_Callback, this.current_file_item.ToJavaScriptObject(), 0, this.current_file_item.file_reference.size);
		}
		
		private function FileProgress_Handler(event:ProgressEvent):void {
			
			this.progressbar.progs.source = event.target;
			// On early than Mac OS X 10.3 bytesLoaded is always -1, convert this to zero. Do bytesTotal for good measure.
			//  http://livedocs.adobe.com/flex/3/langref/flash/net/FileReference.html#event:progress
			var bytesLoaded:Number = event.bytesLoaded < 0 ? 0 : event.bytesLoaded;
			var bytesTotal:Number = event.bytesTotal < 0 ? 0 : event.bytesTotal;
			
			// Because Flash never fires a complete event if the server doesn't respond after 30 seconds or on Macs if there
			// is no content in the response we'll set a timer and assume that the upload is successful after the defined amount of
			// time.  If the timeout is zero then we won't use the timer.
			if (bytesLoaded === bytesTotal && bytesTotal > 0 && this.assumeSuccessTimeout > 0) {
				if (this.assumeSuccessTimer !== null) {
					this.assumeSuccessTimer.stop();
					this.assumeSuccessTimer = null;
				}
				
				this.assumeSuccessTimer = new Timer(this.assumeSuccessTimeout * 1000, 1);
				this.assumeSuccessTimer.addEventListener(TimerEvent.TIMER_COMPLETE, AssumeSuccessTimer_Handler);
				this.assumeSuccessTimer.start();
			}
			
			this.Debug("Event: uploadProgress: File ID: " + this.current_file_item.id + ". Bytes: " + bytesLoaded + ". Total: " + bytesTotal);
			ExternalCall.UploadProgress(this.uploadProgress_Callback, this.current_file_item.ToJavaScriptObject(), bytesLoaded, bytesTotal);
		}
		
		private function AssumeSuccessTimer_Handler(event:TimerEvent):void {
			this.Debug("Event: AssumeSuccess: " + this.assumeSuccessTimeout + " passed without server response");
			this.UploadSuccess(this.current_file_item, "", false);
		}
		
		private function Complete_Handler(event:Event):void {
			/* Because we can't do COMPLETE or DATA events (we have to do both) we can't
			* just call uploadSuccess from the complete handler, we have to wait for
			* the Data event which may never come. However, testing shows it always comes
			* within a couple milliseconds if it is going to come so the solution is:
			* 
			* Set a timer in the COMPLETE event (which always fires) and if DATA is fired
			* it will stop the timer and call uploadComplete
			* 
			* If the timer expires then DATA won't be fired and we call uploadComplete
			* */
			
			// Set the timer
			if (serverDataTimer != null) {
				this.serverDataTimer.stop();
				this.serverDataTimer = null;
			}
			
			this.serverDataTimer = new Timer(100, 1);
			//var self:SWFUpload = this;
			this.serverDataTimer.addEventListener(TimerEvent.TIMER, this.ServerDataTimer_Handler);
			this.serverDataTimer.start();
		}
		private function ServerDataTimer_Handler(event:TimerEvent):void {
			this.UploadSuccess(this.current_file_item, "");
		}
		
		private function ServerData_Handler(event:DataEvent):void {
			this.UploadSuccess(this.current_file_item, event.data);
		}
		
		private function UploadSuccess(file:FileItem, serverData:String, responseReceived:Boolean = true):void {
			if (this.serverDataTimer !== null) {
				this.serverDataTimer.stop();
				this.serverDataTimer = null;
			}
			if (this.assumeSuccessTimer !== null) {
				this.assumeSuccessTimer.stop();
				this.assumeSuccessTimer = null;
			}
			
			this.successful_uploads++;
			file.file_status = FileItem.FILE_STATUS_SUCCESS;
			
			this.Debug("Event: uploadSuccess: File ID: " + file.id + " Response Received: " + responseReceived.toString() + " Data: " + serverData);
			ExternalCall.UploadSuccess(this.uploadSuccess_Callback, file.ToJavaScriptObject(), serverData, responseReceived);
			
			this.UploadComplete(false);
			
		}
		
		private function HTTPError_Handler(event:HTTPStatusEvent):void {
			var isSuccessStatus:Boolean = false;
			for (var i:Number = 0; i < this.httpSuccess.length; i++) {
				if (this.httpSuccess[i] === event.status) {
					isSuccessStatus = true;
					break;
				}
			}
			
			
			if (isSuccessStatus) {
				this.Debug("Event: httpError: Translating status code " + event.status + " to uploadSuccess");
				
				var serverDataEvent:DataEvent = new DataEvent(DataEvent.UPLOAD_COMPLETE_DATA, event.bubbles, event.cancelable, "");
				this.ServerData_Handler(serverDataEvent);
			} else {
				this.upload_errors++;
				this.current_file_item.file_status = FileItem.FILE_STATUS_ERROR;
				
				this.Debug("Event: uploadError: HTTP ERROR : File ID: " + this.current_file_item.id + ". HTTP Status: " + event.status + ".");
				ExternalCall.UploadError(this.uploadError_Callback, this.ERROR_CODE_HTTP_ERROR, this.current_file_item.ToJavaScriptObject(), event.status.toString());
//				this.UploadComplete(true); 	// An IO Error is also called so we don't want to complete the upload yet.
			}
		}
		
		// Note: Flash Player does not support Uploads that require authentication. Attempting this will trigger an
		// IO Error or it will prompt for a username and password and may crash the browser (FireFox/Opera)
		private function IOError_Handler(event:IOErrorEvent):void {
			// Only trigger an IO Error event if we haven't already done an HTTP error
			if (this.current_file_item.file_status != FileItem.FILE_STATUS_ERROR) {
				this.upload_errors++;
				this.current_file_item.file_status = FileItem.FILE_STATUS_ERROR;
				
				this.Debug("Event: uploadError : IO Error : File ID: " + this.current_file_item.id + ". IO Error: " + event.text);
				ExternalCall.UploadError(this.uploadError_Callback, this.ERROR_CODE_IO_ERROR, this.current_file_item.ToJavaScriptObject(), event.text);
			}
			
			this.UploadComplete(true);
		}
		
		private function SecurityError_Handler(event:SecurityErrorEvent):void {
			this.upload_errors++;
			this.current_file_item.file_status = FileItem.FILE_STATUS_ERROR;
			
			this.Debug("Event: uploadError : Security Error : File Number: " + this.current_file_item.id + ". Error text: " + event.text);
			ExternalCall.UploadError(this.uploadError_Callback, this.ERROR_CODE_SECURITY_ERROR, this.current_file_item.ToJavaScriptObject(), event.text);
			
			this.UploadComplete(true);
		}
		
		private function Select_Many_Handler(event:Event=null):void {
			this.Select_Handler(this.fileWaitQueue);
		}
		
		/**
		 * 在Flash弹出的打开文件对话框中选择文件确定打开文件后的逻辑处理函数
		 */
		private function Select_Handler(file_reference_list:Array):void {
			this.Debug("Select Handler: Received the files selected from the dialog. Processing the file list...");
			
			var num_files_queued:Number = 0;
			
			// 确定等待上传队列中还剩下多少位置(检查限制设置,以及已成功上传的数量和正在排队等待上传的数量)
			var queue_slots_remaining:Number = 0;  // 等待上传队列的空闲数量
			if (this.fileUploadLimit == 0) {
				// 如果上传队列的大小没有限制,则上传队列剩下的位置数等于选择的文件数量或者......
				queue_slots_remaining = this.fileQueueLimit == 0 ? file_reference_list.length : (this.fileQueueLimit - this.queued_uploads);	// If unlimited queue make the allowed size match however many files were selected.
			} else {
				var remaining_uploads:Number = this.fileUploadLimit - this.successful_uploads - this.queued_uploads;
				if (remaining_uploads < 0) remaining_uploads = 0;
				if (this.fileQueueLimit == 0 || this.fileQueueLimit >= remaining_uploads) {
					queue_slots_remaining = remaining_uploads;
				} else if (this.fileQueueLimit < remaining_uploads) {
					queue_slots_remaining = this.fileQueueLimit - this.queued_uploads;
				}
			}
			
			if (queue_slots_remaining < 0) queue_slots_remaining = 0;
			
			// 检查当前选中的文件数量是否大于当前队列允许添加的最大值
			if (queue_slots_remaining < file_reference_list.length) {
				this.Debug("Event: fileQueueError : Selected Files (" + file_reference_list.length + ") exceeds remaining Queue size (" + queue_slots_remaining + ").");
				ExternalCall.FileQueueError(this.fileQueueError_Callback, this.ERROR_CODE_QUEUE_LIMIT_EXCEEDED, null, queue_slots_remaining.toString());
			} else {
				// 处理每个选中的文件
				for (var i:Number = 0; i < file_reference_list.length; i++) {
					var file_item:FileItem = new FileItem(file_reference_list[i], this.movieName, this.file_index.length);
					this.file_index[file_item.index] = file_item;
					
					// 确认该文件是可访问的。零字节的文件和其他可能的条件下可以导致文件无法访问。
					var jsFileObj:Object = file_item.ToJavaScriptObject();
					var is_valid_file_reference:Boolean = (jsFileObj.filestatus !== FileItem.FILE_STATUS_ERROR);
					
					if (is_valid_file_reference) {
						// 验证文件大小,如果文件在限制范围只内,则添加到上传队列中
						var size_result:Number = this.CheckFileSize(file_item);
						var is_valid_filetype:Boolean = this.CheckFileType(file_item);
						if(size_result == this.SIZE_OK && is_valid_filetype) {
							file_item.file_status = FileItem.FILE_STATUS_QUEUED;
							this.file_queue.push(file_item);
							this.queued_uploads++;
							num_files_queued++;
							this.Debug("Event: fileQueued : File ID: " + file_item.id);
							
							
							//*************************************************************************
							//这里添加的定制代码,用于向flash中添加选中文件的缩略图
							FileQueuedSucceed(file_item);								
							//*************************************************************************
							ExternalCall.FileQueued(this.fileQueued_Callback, file_item.ToJavaScriptObject());
						}
						else if (!is_valid_filetype) {
							file_item.file_reference = null; 	// Cleanup the object
							this.queue_errors++;
							this.Debug("Event: fileQueueError : File not of a valid type.");
							ExternalCall.FileQueueError(this.fileQueueError_Callback, this.ERROR_CODE_INVALID_FILETYPE, file_item.ToJavaScriptObject(), "File is not an allowed file type.");
						}
						else if (size_result == this.SIZE_TOO_BIG) {
							file_item.file_reference = null; 	// Cleanup the object
							this.queue_errors++;
							this.Debug("Event: fileQueueError : File exceeds size limit.");
							ExternalCall.FileQueueError(this.fileQueueError_Callback, this.ERROR_CODE_FILE_EXCEEDS_SIZE_LIMIT, file_item.ToJavaScriptObject(), "File size exceeds allowed limit.");
						}
						else if (size_result == this.SIZE_ZERO_BYTE) {
							file_item.file_reference = null; 	// Cleanup the object
							this.queue_errors++;
							this.Debug("Event: fileQueueError : File is zero bytes.");
							ExternalCall.FileQueueError(this.fileQueueError_Callback, this.ERROR_CODE_ZERO_BYTE_FILE, file_item.ToJavaScriptObject(), "File is zero bytes and cannot be uploaded.");
						}
					} else {
						file_item.file_reference = null; 	// Cleanup the object
						this.queue_errors++;
						this.Debug("Event: fileQueueError : File is zero bytes or FileReference is invalid.");
						ExternalCall.FileQueueError(this.fileQueueError_Callback, this.ERROR_CODE_ZERO_BYTE_FILE, file_item.ToJavaScriptObject(), "File is zero bytes or cannot be accessed and cannot be uploaded.");
					}
				}
			}
			
			this.Debug("Event: fileDialogComplete : Finished processing selected files. Files selected: " + file_reference_list.length + ". Files Queued: " + num_files_queued);
			ExternalCall.FileDialogComplete(this.fileDialogComplete_Callback, file_reference_list.length, num_files_queued, this.queued_uploads);
			
			this.StartUpload();
		}
		
		
		
		
		private function SetAssumeSuccessTimeout(timeout_seconds:Number):void {
			this.assumeSuccessTimeout = timeout_seconds < 0 ? 0 : timeout_seconds;
		}
		
		private function loadPostParams(param_string:Object):void {
			this.uploadPostObject = param_string;			
		}
		// Parse the file extensions in to an array so we can validate them agains
		// the files selected later.
		private function LoadFileExensions(filetypes:String):void {
			var extensions:Array = filetypes.split(";");
			this.valid_file_extensions = new Array();
			
			for (var i:Number=0; i < extensions.length; i++) {
				var extension:String = String(extensions[i]);
				var dot_index:Number = extension.lastIndexOf(".");
				
				if (dot_index >= 0) {
					extension = extension.substr(dot_index + 1).toLowerCase();
				} else {
					extension = extension.toLowerCase();
				}
				
				// If one of the extensions is * then we allow all files
				if (extension == "*") {
					this.valid_file_extensions = new Array();
					break;
				}
				
				this.valid_file_extensions.push(extension);
			}
		}
		
		// Sets the file size limit.  Accepts size values with units: 100 b, 1KB, 23Mb, 4 Gb
		// Parsing is not robust. "100 200 MB KB B GB" parses as "100 MB"
		private function SetFileSizeLimit(size:String):void {
			var value:Number = 0;
			var unit:String = "kb";
			
			// Trim the string
			var trimPattern:RegExp = /^\s*|\s*$/;
			
			size = size.toLowerCase();
			size = size.replace(trimPattern, "");
			
			
			// Get the value part
			var values:Array = size.match(/^\d+/);
			if (values !== null && values.length > 0) {
				value = parseInt(values[0]);
			}
			if (isNaN(value) || value < 0) value = 0;
			
			// Get the units part
			var units:Array = size.match(/(b|kb|mb|gb)/);
			if (units != null && units.length > 0) {
				unit = units[0];
			}
			
			// Set the multiplier for converting the unit to bytes
			var multiplier:Number = 1024;
			if (unit === "b")
				multiplier = 1;
			else if (unit === "mb")
				multiplier = 1048576;
			else if (unit === "gb")
				multiplier = 1073741824;
			
			this.fileSizeLimit = value * multiplier;
		}
		
		private function SetHTTPSuccess(http_status_codes:*):void {
			this.httpSuccess = [];
			
			if (typeof http_status_codes === "string") {
				var status_code_strings:Array = http_status_codes.replace(" ", "").split(",");
				for each (var http_status_string:String in status_code_strings) 
				{
					try {
						this.httpSuccess.push(Number(http_status_string));
					} catch (ex:Object) {
						// Ignore errors
						this.Debug("Could not add HTTP Success code: " + http_status_string);
					}
				}
			}
			else if (typeof http_status_codes === "object" && typeof http_status_codes.length === "number") {
				for each (var http_status:* in http_status_codes) 
				{
					try {
						this.Debug("adding: " + http_status);
						this.httpSuccess.push(Number(http_status));
					} catch (ex:Object) {
						this.Debug("Could not add HTTP Success code: " + http_status);
					}
				}
			}
		}
		
		
		/* *************************************************************
		File processing and handling functions
		*************************************************************** */
		private function StartUpload(file_id:String = ""):void {
			// Only upload a file uploads are being processed.
			if (this.current_file_item != null) {
				this.Debug("StartUpload(): Upload already in progress. Not starting another upload.");
				return;
			}
			
			this.Debug("StartUpload: " + (file_id ? "File ID: " + file_id : "First file in queue"));
			
			// Check the upload limit
			if (this.successful_uploads >= this.fileUploadLimit && this.fileUploadLimit != 0) {
				this.Debug("Event: uploadError : Upload limit reached. No more files can be uploaded.");
				ExternalCall.UploadError(this.uploadError_Callback, this.ERROR_CODE_UPLOAD_LIMIT_EXCEEDED, null, "The upload limit has been reached.");
				this.current_file_item = null;
				return;
			}
			
			// Get the next file to upload
			if (!file_id) {
				while (this.file_queue.length > 0 && this.current_file_item == null) {
					this.current_file_item = FileItem(this.file_queue.shift());
					if (typeof(this.current_file_item) == "undefined") {
						this.current_file_item = null;
					}
				}
			} else {
				var file_index:Number = this.FindIndexInFileQueue(file_id);
				if (file_index >= 0) {
					// Set the file as the current upload and remove it from the queue
					this.current_file_item = FileItem(this.file_queue[file_index]);
					this.file_queue[file_index] = null;
				} else {
					this.Debug("Event: uploadError : File ID not found in queue: " + file_id);
					ExternalCall.UploadError(this.uploadError_Callback, this.ERROR_CODE_SPECIFIED_FILE_ID_NOT_FOUND, null, "File ID not found in the queue.");
				}
			}
			
			
			if (this.current_file_item != null) {
				// 触发uploadStart事件，它将调用ReturnUploadStart开始实际上传
				this.Debug("Event: uploadStart : File ID: " + this.current_file_item.id);
				
				this.current_file_item.file_status = FileItem.FILE_STATUS_IN_PROGRESS;
				var thumb:Thumbnail;
				for(var i:int;i<SAETools.progressView.numElements;i++){
					thumb = SAETools.progressView.getElementAt(i) as Thumbnail;
					if(thumb.name == this.current_file_item.id)
						break;
				}

				thumb.addElement(this.progressbar);
				this.progressbar.progs.source = null;
//				imgDescOnFocus(this.current_file_item.id);
				
				ExternalCall.UploadStart(this.uploadStart_Callback, this.current_file_item.ToJavaScriptObject());
				
				/*
					添加调用函数				
				*/
				ReturnUploadStart(true)
			}
				// 否则则意味着我们遍历了所有FileItems,这时候可以确定队列是空的
			else {
				this.Debug("StartUpload(): No files found in the queue.");
				this.allFileUploaded();
			}
		}
		
		// This starts the upload when the user returns TRUE from the uploadStart event.  Rather than just have the value returned from
		// the function we do a return function call so we can use the setTimeout work-around for Flash/JS circular calls.
		private function ReturnUploadStart(start_upload:Boolean):void {
			if (this.current_file_item == null) {
				this.Debug("ReturnUploadStart called but no file was prepped for uploading. The file may have been cancelled or stopped.");
				return;
			}
			
			var js_object:Object;
			
			if (start_upload) {
				try {
					// Set the event handlers
					this.current_file_item.file_reference.addEventListener(Event.OPEN, this.Open_Handler);//在上载操作开始时调度
					this.current_file_item.file_reference.addEventListener(ProgressEvent.PROGRESS, this.FileProgress_Handler);//以字节为单位上载文件中的数据时定期调度
					//正在读取、写入或传输文件时发生输入/输出错误,SWF 尝试将文件上载到要求身份验证（如用户名和密码）的服务器,url 参数包含无效协议
					this.current_file_item.file_reference.addEventListener(IOErrorEvent.IO_ERROR, this.IOError_Handler);
					this.current_file_item.file_reference.addEventListener(SecurityErrorEvent.SECURITY_ERROR, this.SecurityError_Handler);//上载操作因违反安全规则而失败时调度
					this.current_file_item.file_reference.addEventListener(HTTPStatusEvent.HTTP_STATUS, this.HTTPError_Handler);//上载过程因 HTTP 错误而失败时调度
					this.current_file_item.file_reference.addEventListener(Event.COMPLETE, this.Complete_Handler);//上载操作成功完成时调度
					this.current_file_item.file_reference.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA, this.ServerData_Handler);//成功上载并从服务器接收数据之后调度
					
					
					// Get the request (post values, etc)
					var request:URLRequest = this.BuildRequest();
					
					if (this.uploadURL.length == 0) {
						this.Debug("Event: uploadError : IO Error : File ID: " + this.current_file_item.id + ". Upload URL string is empty.");
						
						// Remove the event handlers
						this.removeFileReferenceEventListeners(this.current_file_item);
						
						this.current_file_item.file_status = FileItem.FILE_STATUS_QUEUED;
						this.file_queue.unshift(this.current_file_item);
						js_object = this.current_file_item.ToJavaScriptObject();
						this.current_file_item = null;
						
						ExternalCall.UploadError(this.uploadError_Callback, this.ERROR_CODE_MISSING_UPLOAD_URL, js_object, "Upload URL string is empty.");
					} else {
						this.Debug("ReturnUploadStart(): File accepted by startUpload event and readied for upload.  Starting upload to " + request.url + " for File ID: " + this.current_file_item.id);
						this.current_file_item.file_status = FileItem.FILE_STATUS_IN_PROGRESS;
						this.current_file_item.file_reference.upload(request, this.filePostName, false);
					}
				} catch (ex:Error) {
					this.Debug("ReturnUploadStart: Exception occurred: " + message);
					
					this.upload_errors++;
					this.current_file_item.file_status = FileItem.FILE_STATUS_ERROR;
					
					var message:String = ex.errorID + "\n" + ex.name + "\n" + ex.message + "\n" + ex.getStackTrace();
					this.Debug("Event: uploadError(): Upload Failed. Exception occurred: " + message);
					ExternalCall.UploadError(this.uploadError_Callback, this.ERROR_CODE_UPLOAD_FAILED, this.current_file_item.ToJavaScriptObject(), message);
					
					this.UploadComplete(true);
				}
			} else {
				// Remove the event handlers
				this.removeFileReferenceEventListeners(this.current_file_item);
				
				// Re-queue the FileItem
				this.current_file_item.file_status = FileItem.FILE_STATUS_QUEUED;
				js_object = this.current_file_item.ToJavaScriptObject();
				this.file_queue.unshift(this.current_file_item);
				this.current_file_item = null;
				
				this.Debug("Event: uploadError : Call to uploadStart returned false. Not uploading the file.");
				ExternalCall.UploadError(this.uploadError_Callback, this.ERROR_CODE_FILE_VALIDATION_FAILED, js_object, "Call to uploadStart return false. Not uploading file.");
				this.Debug("Event: uploadComplete : Call to uploadStart returned false. Not uploading the file.");
				ExternalCall.UploadComplete(this.uploadComplete_Callback, js_object);
			}
		}
		
		/**
		 * 文件成功加入上传队列后回调函数
		 * 
		 */
		private function FileQueuedSucceed(file_item:FileItem):void{
			
			var thumb:Thumbnail = new Thumbnail;
			
			SAETools.progressView.addElement(thumb);
			thumb.file_item_id = file_item.id;
			thumb.name = file_item.id;
			thumb.file_name = file_item.file_reference.name;
			thumb.file_name_label.text = thumb.file_name;
		}
		
		/**
		 * 文件上传完成，删去引用，推进指针。一旦这个事件触发则可以启动一个新的上传。
		 *  
		 * @param eligible_for_requeue 指定文件时候有资格重新排队,true:文件可以重新排队等待上传,false:文件不需要重新排队,并被丢弃 
		 */	
		private function UploadComplete(eligible_for_requeue:Boolean):void {
			var jsFileObj:Object = this.current_file_item.ToJavaScriptObject();
			
			this.removeFileReferenceEventListeners(this.current_file_item);
			
			if (!eligible_for_requeue || this.requeueOnError == false) {
				this.current_file_item.file_reference = null;
				this.queued_uploads--;
				if(!eligible_for_requeue){
					var thumb:Thumbnail =SAETools.progressView.getChildByName(this.current_file_item.id)  as Thumbnail;
					thumb.removeChild(progressbar);					
					var upLoadOK:UpLoadOK = new UpLoadOK();
					upLoadOK.x = 65;
					upLoadOK.y = 0;
					thumb.addChild(upLoadOK);
				}
			} else if (this.requeueOnError == true) {
				this.current_file_item.file_status = FileItem.FILE_STATUS_QUEUED;
				this.file_queue.unshift(this.current_file_item);
			}
			
			this.current_file_item = null;
			
			Debug("Event: uploadComplete : Upload cycle complete.");
			this.StartUpload();
			ExternalCall.UploadComplete(this.uploadComplete_Callback, jsFileObj);
		}
		
//		public function imgDescOnFocus(file_id:String):Boolean{
//			this.pointing.alpha = 0;
//			var thumb:Thumbnail =SAETools.progressView.getChildByName(file_id)  as Thumbnail;
//			this.current_Edit = thumb;
//			var temp:Number = thumb.x-SAETools.progressView.horizontalScrollPosition;
//			if(temp<0){
//				var hsPos:Number = thumb.x;
//				TweenLite.to(hbox_thumbnail, 0.5, {horizontalScrollPosition:hsPos, onComplete:buttonStateHandler});						
//			}else if(temp>SAETools.progressView.width - SWFUpload.IMG_MAXWIDTH){
//				hsPos = thumb.x -SAETools.progressView.width + SWFUpload.IMG_MAXWIDTH;
//				TweenLite.to(hbox_thumbnail, 0.5, {horizontalScrollPosition:hsPos, onComplete:buttonStateHandler});	
//			}else{
//				this.piontStateHandler();
//			}
//			return true;
//		}
//		
//		public function piontStateHandler():void{			
//			
//			if(this.current_Edit !=null){
//				var temp:Number = this.current_Edit.x-SAETools.progressView.horizontalScrollPosition+SWFUpload.IMG_MAXWIDTH/2-this.pointing.width/2;
//				if(temp<0){
//					this.pointing.alpha = 0;
//					this.pointing.x = SAETools.progressView.x;
//				}else if(temp>SAETools.progressView.width-this.pointing.width){
//					this.pointing.alpha = 0;
//					this.pointing.x = SAETools.progressView.x+this.hbox_thumbnail.width-this.pointing.width;
//				}else {
//					TweenLite.to(this.pointing, 0.2, {alpha:1});
//					this.pointing.x = this.hbox_thumbnail.x+temp;
//				}
//			}else{
//				this.pointing.alpha = 0;
//				this.pointing.x = this.hbox_thumbnail.x;
//			}
//		}
		
		/* *************************************************************
		Utility Functions
		*************************************************************** */
		
		private function BuildRequest():URLRequest {
			// Create the request object
			var request:URLRequest = new URLRequest();
			request.method = URLRequestMethod.POST;
			
			var file_post:Object = this.current_file_item.GetPostObject();
			
			if (this.useQueryString) {
				var pairs:Array = new Array();
				for (key in this.uploadPostObject) {
					this.Debug("Global URL Item: " + key + "=" + this.uploadPostObject[key]);
					if (this.uploadPostObject.hasOwnProperty(key)) {
						pairs.push(escape(key) + "=" + escape(this.uploadPostObject[key]));
					}
				}
				
				for (key in file_post) {
					this.Debug("File Post Item: " + key + "=" + file_post[key]);
					if (file_post.hasOwnProperty(key)) {
						pairs.push(escape(key) + "=" + escape(file_post[key]));
					}
				}
				
				request.url = this.uploadURL  + (this.uploadURL.indexOf("?") > -1 ? "&" : "?") + pairs.join("&");
				
			} else {
				var key:String;
				var post:URLVariables = new URLVariables();
				for (key in this.uploadPostObject) {
					this.Debug("Global Post Item: " + key + "=" + this.uploadPostObject[key]);
					if (this.uploadPostObject.hasOwnProperty(key)) {
						post[key] = this.uploadPostObject[key];
					}
				}
				
				for (key in file_post) {
					this.Debug("File Post Item: " + key + "=" + file_post[key]);
					if (file_post.hasOwnProperty(key)) {
						post[key] = file_post[key];
					}
				}
				
				request.url = this.uploadURL;
				request.data = post;
			}
			
			return request;
		}
		
		// Check the size of the file against the allowed file size. If it is less the return TRUE. If it is too large return FALSE
		private function CheckFileSize(file_item:FileItem):Number {
			if (file_item.file_reference.size == 0) {
				return this.SIZE_ZERO_BYTE;
			} else if (this.fileSizeLimit != 0 && file_item.file_reference.size > this.fileSizeLimit) {
				return this.SIZE_TOO_BIG;
			} else {
				return this.SIZE_OK;
			}
		}
		
		private function CheckFileType(file_item:FileItem):Boolean {
			// If no extensions are defined then a *.* was passed and the check is unnecessary
			if (this.valid_file_extensions.length == 0) {
				return true;
			}
			
			var fileRef:FileReference = file_item.file_reference;
			var last_dot_index:Number = fileRef.name.lastIndexOf(".");
			var extension:String = "";
			if (last_dot_index >= 0) {
				extension = fileRef.name.substr(last_dot_index + 1).toLowerCase();
			}
			
			var is_valid_filetype:Boolean = false;
			for (var i:Number=0; i < this.valid_file_extensions.length; i++) {
				if (String(this.valid_file_extensions[i]) == extension) {
					is_valid_filetype = true;
					break;
				}
			}
			
			return is_valid_filetype;
		}
		
		private function FindIndexInFileQueue(file_id:String):Number {
			for (var i:Number = 0; i < this.file_queue.length; i++) {
				var item:FileItem = this.file_queue[i];
				if (item != null && item.id == file_id) return i;
			}
			
			return -1;
		}
		
		private function FindFileInFileIndex(file_id:String):FileItem {
			for (var i:Number = 0; i < this.file_index.length; i++) {
				var item:FileItem = this.file_index[i];
				if (item != null && item.id == file_id) return item;
			}
			
			return null;
		}
		
		private function removeFileReferenceEventListeners(file_item:FileItem):void {
			if (file_item != null && file_item.file_reference != null) {
				file_item.file_reference.removeEventListener(Event.OPEN, this.Open_Handler);
				file_item.file_reference.removeEventListener(ProgressEvent.PROGRESS, this.FileProgress_Handler);
				file_item.file_reference.removeEventListener(IOErrorEvent.IO_ERROR, this.IOError_Handler);
				file_item.file_reference.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, this.SecurityError_Handler);
				file_item.file_reference.removeEventListener(HTTPStatusEvent.HTTP_STATUS, this.HTTPError_Handler);
				file_item.file_reference.removeEventListener(DataEvent.UPLOAD_COMPLETE_DATA, this.ServerData_Handler);
			}
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