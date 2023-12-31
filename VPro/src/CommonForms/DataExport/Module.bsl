&AtClient
Var CheckIteration;

////////////////////////////////////////////////////////////////////////////////
// FORM EVENT HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then // Return if the form for analysis is received.
		Return;
	EndIf;
	
	If CommonUseReUse.DataSeparationEnabled() Then
		FormHeaderText = NStr("en='Export data to local version';ru='Выгрузить данные в локальную версию';vi='Kết xuất dữ liệu vào phiên bản cục bộ'");
		MessageText      = NStr("en='Data from the service will be exported to the"
"file for its following import and use in the local version.';ru='Данные из сервиса будут выгружены в файл"
"для последующей их загрузки и использования в локальной версии.';vi='Dữ liệu từ đám mây sẽ được kết xuất vào tệp"
"để kết nhập lần sau và sử dụng ở phiên bản cục bộ.'");
	Else
		FormHeaderText = NStr("en='Export data for migration to the service';ru='Выгрузить данные для перехода в сервис';vi='Kết xuất dữ liệu để chuyển sang mô hình dịch vụ'");
		MessageText      = NStr("en='Data from the local version will be exported to the"
"file for its following import and use in the service mode.';ru='Данные из локальной версии будут выгружены в"
"файл для последующей их загрузки и использования в режиме сервиса.';vi='Dữ liệu từ phiên bản cục bộ sẽ được kết xuất vào tệp"
"để kết xuất lần sau và sử dụng ở chế độ đám mây.'");
	EndIf;
	Items.WarningDecoration.Title = MessageText;
	Title = FormHeaderText;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// FORM HEADER ITEM EVENT HANDLERS

&AtClient
Procedure OpenActiveUsersForm(Command)
	
	OpenForm("DataProcessor.ActiveUsers.Form.ActiveUsersListForm");
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// FORM COMMAND HANDLERS

&AtClient
Procedure ExportData(Command)
	
	StartDataExportAtServer();
	
	Items.GroupPages.CurrentPage = Items.Export;
	
	CheckIteration = 1;
	
	AttachIdleHandler("CheckExportReadyState", 15);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// SERVICE PROCEDURES AND FUNCTIONS

&AtClient 
Procedure SaveExportFile()
	
	FileName = "data_dump.zip";
	
	DialogueParameters = New Structure;
	DialogueParameters.Insert("Filter", "ZIP archive(*.zip)|*.zip");
	DialogueParameters.Insert("Extension", "zip");
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("FileName", FileName);
	AdditionalParameters.Insert("DialogueParameters", DialogueParameters);
	
	AlertFileOperationsConnectionExtension = New NotifyDescription(
		"SelectAndSaveFileAfterConnectionFileOperationsExtension",
		ThisForm, AdditionalParameters);
	
	BeginAttachingFileSystemExtension(AlertFileOperationsConnectionExtension);
	
EndProcedure

&AtClient 
Procedure SelectAndSaveFileAfterConnectionFileOperationsExtension(Attached, AdditionalParameters) Export
	
	If Attached Then
		
		FileDialog = New FileDialog(FileDialogMode.Save);
		FillPropertyValues(FileDialog, AdditionalParameters.DialogueParameters);
		
		FilesToReceive = New Array;
		FilesToReceive.Add(New TransferableFileDescription(AdditionalParameters.FileName, StorageAddress));
		
		FilesReceiptAlertDescription = New NotifyDescription(
			"SelectAndSaveFile",
			ThisForm, AdditionalParameters);
		
		BeginGettingFiles(FilesReceiptAlertDescription, FilesToReceive, FileDialog, True);
		
	Else
		
		GetFile(StorageAddress, AdditionalParameters.FileName, True);
		Close();
		
	EndIf;
	
EndProcedure

&AtClient 
Procedure SelectAndSaveFile(ReceivedFiles, AdditionalParameters) Export
	
	Close();
	
EndProcedure

&AtServerNoContext
Procedure SwitchOffExclusiveModeAfterExport()
	
	SetExclusiveMode(False);
	
EndProcedure

&AtClient
Procedure CheckExportReadyState()
	
	Try
		ExportReadyState = ExportDataReady();
	Except
		
		ErrorInfo = ErrorInfo();
		
		DetachIdleHandler("CheckExportReadyState");
		SwitchOffExclusiveModeAfterExport();
		
		HandleError(
			BriefErrorDescription(ErrorInfo),
			DetailErrorDescription(ErrorInfo));
		
	EndTry;
	
	If ExportReadyState Then
		SwitchOffExclusiveModeAfterExport();
		DetachIdleHandler("CheckExportReadyState");
		SaveExportFile();
	Else
		
		CheckIteration = CheckIteration + 1;
		
		If CheckIteration = 3 Then
			DetachIdleHandler("CheckExportReadyState");
			AttachIdleHandler("CheckExportReadyState", 30);
		ElsIf CheckIteration = 4 Then
			DetachIdleHandler("CheckExportReadyState");
			AttachIdleHandler("CheckExportReadyState", 60);
		EndIf;
			
	EndIf;
	
EndProcedure

&AtServerNoContext
Function FindJobByID(ID)
	
	Task = BackgroundJobs.FindByUUID(ID);
	
	Return Task;
	
EndFunction

&AtServer
Function ExportDataReady()
	
	Task = FindJobByID(JobID);
	
	If Task <> Undefined
		AND Task.State = BackgroundJobState.Active Then
		
		Return False;
	EndIf;
	
	Items.GroupPages.CurrentPage = Items.Warning;
	
	If Task = Undefined Then
		Raise(NStr("en='An error occurred when preparing export, export preparation job is not found.';ru='При подготовке выгрузки произошла ошибка - не найдено задание подготавливающее выгрузку.';vi='Khi chuẩn bị kết xuất, đã xảy ra lỗi - không tìm thấy nhiệm vụ chuẩn bị kết xuất.'"));
	EndIf;
	
	If Task.State = BackgroundJobState.Failed Then
		JobError = Task.ErrorInfo;
		If JobError <> Undefined Then
			Raise(DetailErrorDescription(JobError));
		Else
			Raise(NStr("en='An error occurred when preparing export, export preparation job was completed with an unknown error.';ru='При подготовке выгрузки произошла ошибка - задание подготавливающее выгрузку завершилось с неизвестной ошибкой.';vi='Khi chuẩn bị kết xuất, đã xảy ra lỗi - nhiệm vụ chuẩn bị kết xuất kết thúc có lỗi không xác định.'"));
		EndIf;
	ElsIf Task.State = BackgroundJobState.Canceled Then
		Raise(NStr("en='An error occurred when preparing export, export preparation job was canceled by the administrator.';ru='При подготовке выгрузки произошла ошибка - задание подготавливающее выгрузку было отменено администратором.';vi='Khi chuẩn bị kết xuất, đã xảy ra lỗi - nhiệm vụ chuẩn bị kết xuất đã bị hủy bỏ bởi người quản trị hệ thống.'"));
	Else
		JobID = Undefined;
		Return True;
	EndIf;
	
EndFunction

&AtServer
Procedure StartDataExportAtServer()
	
	SetExclusiveMode(True);
	
	Try
		
		StorageAddress = PutToTempStorage(Undefined, UUID);
		
		JobParameters = New Array;
		JobParameters.Add(StorageAddress);
		
		Task = BackgroundJobs.Execute("DataAreasExportImport.ExportCurrentDataAreaIntoTemporaryStorage", 
			JobParameters,
			,
			NStr("en='Prepare data area export';ru='Подготовка выгрузки области данных';vi='Chuẩn bị kết xuất vùng dữ liệu'"));
			
		JobID = Task.UUID;
		
	Except
		
		ErrorInfo = ErrorInfo();
		SetExclusiveMode(False);
		HandleError(
			BriefErrorDescription(ErrorInfo),
			DetailErrorDescription(ErrorInfo));
		
	EndTry;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;

	If ValueIsFilled(JobID) Then
		CancelInitializationJob(JobID);
		SwitchOffExclusiveModeAfterExport();
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure CancelInitializationJob(Val JobID)
	
	Task = FindJobByID(JobID);
	If Task = Undefined
		OR Task.State <> BackgroundJobState.Active Then
		
		Return;
	EndIf;
	
	Try
		Task.Cancel();
	Except
		// The job might end at the moment and there is no error.
		WriteLogEvent(NStr("en='Job execution on data area export preparation canceled';ru='Отмена выполнения задания подготовки выгрузки области данных';vi='Hủy bỏ thực hiện nhiệm vụ chuẩn bị kết xuất vùng dữ liệu'", 
			CommonUseClientServer.MainLanguageCode()),
			EventLogLevel.Error,,,
			DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

&AtServerNoContext
Procedure HandleError(Val ShortPresentation, Val DetailedPresentation)
	
	WriteLogEventTemplate = NStr("en='An error occurred when exporting data: ----------------------------------------- %1 -----------------------------------------';ru='При выгрузке данных произошла ошибка: ----------------------------------------- %1 -----------------------------------------';vi='Khi kết xuất dữ liệu, đã xảy ra lỗi: ----------------------------------------- %1 -----------------------------------------'");
	WriteLogEventText = StringFunctionsClientServer.SubstituteParametersInString(WriteLogEventTemplate, DetailedPresentation);
	
	WriteLogEvent(
		NStr("en='Data export';ru='Экспорт данных';vi='Xuất dữ liệu'"),
		EventLogLevel.Error,
		,
		,
		WriteLogEventText);
	
	ExceptionPattern = NStr("en='An error occurred while exporting the data: %1."
""
"Detailed information for support service is written to the events log monitor. If you do not know the reason of error, you are recommended to contact the technical support service providing to them the infobase and exported event log monitor for investigation.';ru='При выгрузке данных произошла ошибка: %1."
""
"Расширенная информация для службы поддержки записана в журнал регистрации. Если Вам неизвестна причина ошибки - рекомендуется обратиться в службу технической поддержки, предоставив для расследования информационную базу и выгрузку журнала регистрации.';vi='Đã xảy ra lỗi khi kết nhập dữ liệu: %1."
""
"Thông tin mở rộng dành cho bộ phận hỗ trợ được ghi trong nhật ký sự kiện. Nếu bạn không biết nguyên nhân lỗi thì nên liên hệ với bộ phận hỗ trợ kỹ thuật, tạo điều kiện để tìm hiểu cơ sở thông tin và kết xuất nhật ký chứng từ.'");
	
	Raise StringFunctionsClientServer.SubstituteParametersInString(ExceptionPattern, ShortPresentation);
	
EndProcedure
