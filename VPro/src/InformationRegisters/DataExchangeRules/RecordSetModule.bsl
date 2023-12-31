#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventsHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	For Each Record IN ThisObject Do
		
		If Record.DebugMode Then
			
			ExchangePlanID = CommonUse.MetadataObjectID(Metadata.ExchangePlans[Record.ExchangePlanName]);
			SecurityProfileName = WorkInSafeModeService.ExternalModuleConnectionMode(ExchangePlanID);
			
			If SecurityProfileName <> Undefined Then
				SetSafeMode(SecurityProfileName);
			EndIf;
			
			ThisIsFileBase = CommonUse.FileInfobase();
			
			If Record.ExportDebuggingMode Then
				
				ValidateExistenceOfFileExternalDataProcessors(Record.DataProcessorFileNameForExportDebugging, ThisIsFileBase, Cancel);
				
			EndIf;
			
			If Record.ImportDebuggingMode Then
				
				ValidateExistenceOfFileExternalDataProcessors(Record.DataProcessorFileNameForImportDebugging, ThisIsFileBase, Cancel);
				
			EndIf;
			
			If Record.DataExchangeLoggingMode Then
				
				CheckExchangeLogFileAvailability(Record.ExchangeProtocolFileName, Cancel);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

Procedure ValidateExistenceOfFileExternalDataProcessors(VerifiedFileName, ThisIsFileBase, Cancel)
	
	FileNameStructure = CommonUseClientServer.SplitFullFileName(VerifiedFileName);
	FileName = FileNameStructure.BaseName;
	CheckDirectoryName	 = FileNameStructure.Path;
	CheckDirectory = New File(CheckDirectoryName);
	FileOnDrive = New File(VerifiedFileName);
	DirectoryLocation = ? (ThisIsFileBase, NStr("en='on client';ru='на клиенте';vi='trên Client'"), NStr("en='on server';ru='на сервере';vi='trên Server'"));
	
	If Not CheckDirectory.Exist() Then
		
		MessageString = NStr("en='The ""%1"" directory is not found %2.';ru='Каталог ""%1"" не найден %2.';vi='Không tìm thấy %2 thư mục ""%1"".'");
		MessageString = StringFunctionsClientServer.SubstituteParametersInString(MessageString, CheckDirectoryName, DirectoryLocation);
		Cancel = True;
		
	ElsIf Not FileOnDrive.Exist() Then 
		
		MessageString = NStr("en='External data processor file ""%1"" is not found %2.';ru='Файл внешней обработки ""%1"" не найден %2.';vi='Tệp bộ xử lý ngoài ""%1"" không tìm thấy %2.'");
		MessageString = StringFunctionsClientServer.SubstituteParametersInString(MessageString, VerifiedFileName, DirectoryLocation);
		Cancel = True;
		
	Else
		
		Return;
		
	EndIf;
	
	CommonUseClientServer.MessageToUser(MessageString,,,, Cancel);
	
EndProcedure

Procedure CheckExchangeLogFileAvailability(ExchangeProtocolFileName, Cancel)
	
	FileNameStructure = CommonUseClientServer.SplitFullFileName(ExchangeProtocolFileName);
	CheckDirectoryName = FileNameStructure.Path;
	CheckDirectory = New File(CheckDirectoryName);
	CheckFileName = "test.tmp";
	
	If Not CheckDirectory.Exist() Then
		
		MessageString = NStr("en='The ""%1"" exchange protocol file directory is not found.';ru='Каталог файла протокола обмена ""%1"" не найден.';vi='Thư mục tệp giao thức trao đổi ""%1"" không tìm thấy.'");
		MessageString = StringFunctionsClientServer.SubstituteParametersInString(MessageString, CheckDirectoryName);
		Cancel = True;
		
	ElsIf Not CreateVerificationFile(CheckDirectoryName, CheckFileName) Then
		
		MessageString = NStr("en='Cannot create a file in the exchange protocol folder: ""%1"".';ru='Не удалось создать файл в папке протокола обмена: ""%1"".';vi='Không thể tạo tệp trong thư mục giao thức trao đổi: ""%1"".'");
		MessageString = StringFunctionsClientServer.SubstituteParametersInString(MessageString, CheckDirectoryName);
		Cancel = True;
		
	ElsIf Not DeleteCheckFile(CheckDirectoryName, CheckFileName) Then
		
		MessageString = NStr("en='Cannot delete file from the exchange protocol folder: ""%1"".';ru='Не удалось удалить файл в папке протокола обмена: ""%1"".';vi='Không thể xóa bỏ tệp trong thư mục giao thức trao đổi: ""%1"".'");
		MessageString = StringFunctionsClientServer.SubstituteParametersInString(MessageString, CheckDirectoryName);
		Cancel = True;
		
	Else
		
		Return;
		
	EndIf;
	
	CommonUseClientServer.MessageToUser(MessageString,,,, Cancel);
	
EndProcedure

Function CreateVerificationFile(CheckDirectoryName, CheckFileName)
	
	TextDocument = New TextDocument;
	TextDocument.AddLine(NStr("en='Temporary check file';ru='Временный файл проверки';vi='Tệp kiểm tra tạm thời'"));
	
	Try
		TextDocument.Write(CheckDirectoryName + "/" + CheckFileName);
	Except
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

Function DeleteCheckFile(CheckDirectoryName, CheckFileName)
	
	Try
		DeleteFiles(CheckDirectoryName, CheckFileName);
	Except
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

#EndRegion

#EndIf