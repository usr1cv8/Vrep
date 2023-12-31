#Region FormEventsHandlers

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Not ValueIsFilled(DataProcessorFileName) Or Not ValueIsFilled(DataProcessorFileAddress) Then
		
		CommonUseClientServer.MessageToUser(NStr("en='Specify an external report or a data processor file';ru='Укажите файл внешнего отчета или обработки';vi='Hãy chỉ ra tệp của báo cáo hoặc bộ xử lý ngoài'"), , "DataProcessorFileAddress");
		Cancel = True;
		
	EndIf;
	
	If Not ValueIsFilled(SafeMode) Then
		
		CommonUseClientServer.MessageToUser(NStr("en='Specify the safe mode for the external module connection';ru='Укажите безопасный режим для подключения внешнего модуля';vi='Hãy chỉ ra chế độ an toàn để kết nối mô-đun ngoài'"), , "SafeMode");
		Cancel = True;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormManagementItemsEventsHandlers

&AtClient
Procedure DataProcessorFileNameStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = True;
	
	Notification = New NotifyDescription("DataProcessorFileNameStartChoiceAfterPlacingFile", ThisObject);
	BeginPutFile(Notification, , , True, ThisObject.UUID);
	
EndProcedure

&AtClient
Procedure DataProcessorFileNameStartChoiceAfterPlacingFile(Result, Address, SelectedFileName, Context) Export
	
	If Result Then
		
		DataProcessorFileName = SelectedFileName;
		DataProcessorFileAddress = Address;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DataProcessorFileNameClearing(Item, StandardProcessing)
	
	DeleteFromTempStorage(DataProcessorFileAddress);
	
	DataProcessorFileAddress = "";
	DataProcessorFileName = "";
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure ConnectAndOpen(Command)
	
	If CheckFilling() Then
		
		Name = EnableOnServer();
		
		Extension = Right(Lower(TrimAll(DataProcessorFileName)), 3);
		
		If Extension = "epf" Then
			
			ExternalModuleFormName = "ExternalDataProcessor." + Name + ".Form";
			
		Else
			
			ExternalModuleFormName = "ExternalReport." + Name + ".Form";
			
		EndIf;
		
		OpenForm(ExternalModuleFormName, , ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

&AtServer
Function EnableOnServer()
	
	If Not Users.InfobaseUserWithFullAccess(, True) Then
		Raise NStr("en='Insufficient access rights.';ru='Недостаточно прав доступа.';vi='Không đủ quyền truy cập.'");
	EndIf;
	
	Extension = Right(Lower(TrimAll(DataProcessorFileName)), 3);
	
	If Extension = "epf" Then
		
		Manager = ExternalDataProcessors;
		
	ElsIf Extension = "erf" Then
		
		Manager = ExternalReports;
		
	Else
		
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'File %1 is not a file of an external report or data processor"), DataProcessorFileName);
		
	EndIf;
	
	Name = Manager.Connect(DataProcessorFileAddress, , SafeMode);
	
	Return Name;
	
EndFunction

#EndRegion
