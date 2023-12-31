
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then // Return if the form for analysis is received.
		Return;
	EndIf;

	LeadingEndPointSettingEventLogMonitorMessageText = MessageExchangeInternal.LeadingEndPointSettingEventLogMonitorMessageText();
	
	EndPoint = Parameters.EndPoint;
	
	// Read connection setting values.
	FillPropertyValues(ThisObject, InformationRegisters.ExchangeTransportSettings.TransportSettingsWS(EndPoint));
	
	Title = StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en='Set leading endpoint for ""%1""';ru='Установка ведущей конечной точки для ""%1""';vi='Đặt điểm cuối chính đối với ""%1""'"),
		CommonUse.ObjectAttributeValue(EndPoint, "Description"));
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	WarningText = NStr("en='Cancel operation?';ru='Отменить выполнение операции?';vi='Hủy bỏ thực hiện giao dịch?'");
	CommonUseClient.ShowArbitraryFormClosingConfirmation(
		ThisObject, Cancel, WarningText, "ForceCloseForm");
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure Set(Command)
	
	Status(NStr("en='Setting the leading endpoint. Please wait...';ru='Выполняется установка ведущей конечной точки. Пожалуйста, подождите..';vi='Đang thiết lập điểm cuối quan trọng. Vui lòng chờ trong giây lát...'"));
	
	Cancel = False;
	FillError = False;
	
	SetLeadingEndPointAtServer(Cancel, FillError);
	
	If FillError Then
		Return;
	EndIf;
	
	If Cancel Then
		
		NString = NStr("en='Errors occurred when setting the leading end point."
"Do you want to open the event log?';ru='При установке ведущей конечной точки возникли ошибки."
"Перейти в журнал регистрации?';vi='Khi đặt điểm cuối chính phát sinh lỗi."
"Chuyển sang nhật ký sự kiện?'");
		NotifyDescription = New NotifyDescription("OpenEventLogMonitor", ThisObject);
		ShowQueryBox(NOTifyDescription, NString, QuestionDialogMode.YesNo, ,DialogReturnCode.No);
		Return;
	EndIf;
	
	Notify(MessageExchangeClient.EventNameLeadingEndPointSet());
	
	ShowUserNotification(,, NStr("en='Leading endpoint is set successfully.';ru='Установка ведущей конечной точки успешно завершена.';vi='Đặt điểm cuối chính đã kết thúc thành công.'"));
	
	ForceCloseForm = True;
	
	Close();
	
EndProcedure

&AtClient
Procedure OpenEventLogMonitor(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		
		Filter = New Structure;
		Filter.Insert("EventLogMonitorEvent", LeadingEndPointSettingEventLogMonitorMessageText);
		OpenForm("DataProcessor.EventLogMonitor.Form", Filter, ThisObject);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

&AtServer
Procedure SetLeadingEndPointAtServer(Cancel, FillError)
	
	If Not CheckFilling() Then
		FillError = True;
		Return;
	EndIf;
	
	WSConnectionSettings = DataExchangeServer.WSParameterStructure();
	
	FillPropertyValues(WSConnectionSettings, ThisObject);
	
	MessageExchangeInternal.SetLeadingEndPointAtSender(Cancel, WSConnectionSettings, EndPoint);
	
EndProcedure

#EndRegion
