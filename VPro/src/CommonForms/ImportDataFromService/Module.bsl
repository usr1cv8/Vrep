///////////////////////////////////////////////////////////////////////////////
// FORM HEADER ITEM EVENT HANDLERS

&AtClient
Procedure OpenActiveUsersForm(Item)
	
	OpenForm("DataProcessor.ActiveUsers.Form.ActiveUsersListForm");
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// FORM COMMAND HANDLERS

&AtClient
Procedure Import(Command)
	
	NotifyDescription = New NotifyDescription("ContinueDataImport", ThisObject);
	BeginPutFile(NOTifyDescription, , "data_dump.zip");
	
EndProcedure

&AtClient
Procedure ContinueDataImport(SelectionComplete, StorageAddress, SelectedFileName, AdditionalParameters) Export
	
	If SelectionComplete Then
		
		Status(
			NStr("en='Data is being imported from the service."
"Operation can take a long time, please, wait...';ru='Выполняется загрузка данных из сервиса. Операция может занять продолжительное время, пожалуйста, подождите...';vi='Đang kết nhập dữ liệu từ đám mây. Giao dịch có thể mất nhiều thời gian, vui lòng chờ trong giây lát...'"),);
		
		RunImport(StorageAddress, ExportInformationAboutUsers);
		Terminate(True);
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// SERVICE PROCEDURES AND FUNCTIONS

&AtServerNoContext
Procedure RunImport(Val FileURL, Val ExportInformationAboutUsers)
	
	SetExclusiveMode(True);
	
	Try
		
		ArchiveData = GetFromTempStorage(FileURL);
		ArchiveName = GetTempFileName("zip");
		ArchiveData.Write(ArchiveName);
		
		DataAreasExportImport.ImportCurrentDataAreaFromArchive(ArchiveName, ExportInformationAboutUsers, True);
		
		DataExportImportService.DeleteTemporaryFile(ArchiveName);
		
		SetExclusiveMode(False);
		
	Except
		
		ErrorInfo = ErrorInfo();
		
		SetExclusiveMode(False);
		
		WriteLogEventTemplate = NStr("en='An error occurred while importing data:  ----------------------------------------- %1 -----------------------------------------';ru='При загрузке данных произошла ошибка: ----------------------------------------- %1 -----------------------------------------';vi='Khi kết nhập dữ liệu, đã xảy ra lỗi: ----------------------------------------- %1 -----------------------------------------'");
		WriteLogEventText = StringFunctionsClientServer.SubstituteParametersInString(WriteLogEventTemplate, DetailErrorDescription(ErrorInfo));

		WriteLogEvent(
			NStr("en='Data Import';ru='Загрузка данных';vi='Kết nhập dữ liệu'"),
			EventLogLevel.Error,
			,
			,
			WriteLogEventText);

		ExceptionPattern = NStr("en='An error occurred during data import: %1."
""
"Detailed information for support service is written to the events log monitor. If you do not know the cause of error, you should contact technical support service providing the donwloaded events log monitor and file from which it was attempted to import data.';ru='При загрузке данных произошла ошибка: %1."
""
"Расширенная информация для службы поддержки записана в журнал регистрации. Если Вам неизвестна причина ошибки - рекомендуется обратиться в службу технической поддержки, предоставив для расследования выгрузку журнала регистрации и файл, из которого предпринималась попытка ззагрузить данные.';vi='Đã xảy ra lỗi khi kết nhập dữ liệu: %1."
""
"Thông tin mở rộng dành cho bộ phận hỗ trợ được ghi trong nhật ký sự kiện. Nếu bạn không biết nguyên nhân lỗi thì nên liên hệ với bộ phận hỗ trợ kỹ thuật, tạo điều kiện để tìm hiểu việc kết xuất nhật ký chứng từ và tệp - những chứng từ (tệp) mà được dùng để kết nhập.'");

		Raise StringFunctionsClientServer.SubstituteParametersInString(ExceptionPattern, BriefErrorDescription(ErrorInfo));
		
	EndTry;
	
EndProcedure











