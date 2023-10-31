
#Region FormCommandsHandlers

&AtClient
Procedure ReportPrintingWithoutBlankingExecute()
	
	Context = New Structure("Action", "PrintXReport");
	NotifyDescription = New NotifyDescription("ReportPrintEnd", ThisObject, Context);
	EquipmentManagerClient.OfferSelectDevice(NOTifyDescription, "FiscalRegister",
		NStr("en='Select a fiscal data recorder';ru='Выберите фискальный регистратор';vi='Hãy chọn máy ghi nhận tiền mặt'"), NStr("en='Fiscal data recorder is not connected.';ru='Фискальный регистратор не подключен.';vi='Chưa kết nối máy ghi nhận tiền mặt.'"));
	
EndProcedure

&AtClient
Procedure ReportPrintingWithBlankingExecute()
	
	Context = New Structure("Action", "PrintZReport");
	NotifyDescription = New NotifyDescription("ReportPrintEnd", ThisObject, Context);
	EquipmentManagerClient.OfferSelectDevice(NOTifyDescription, "FiscalRegister",
		NStr("en='Select a fiscal data recorder';ru='Выберите фискальный регистратор';vi='Hãy chọn máy ghi nhận tiền mặt'"), NStr("en='Fiscal data recorder is not connected.';ru='Фискальный регистратор не подключен.';vi='Chưa kết nối máy ghi nhận tiền mặt.'"));
	
EndProcedure

&AtClient
Procedure ReportPrintEnd(DeviceIdentifier, Parameters) Export
	
	If Not Parameters.Property("Action") Then
		Return;
	EndIf;
	
	ErrorDescription = "";
	
	Result = EquipmentManagerClient.ConnectEquipmentByID(UUID, DeviceIdentifier, ErrorDescription);
	If Result Then
		InputParameters  = Undefined;
		Output_Parameters = Undefined;
		Result = EquipmentManagerClient.RunCommand(DeviceIdentifier, Parameters.Action, InputParameters, Output_Parameters);
		
		If Not Result Then
			MessageText = NStr("en='An error occurred while getting the report from fiscal register."
"%ErrorDescription%"
"Report on fiscal register is not formed.';ru='При снятии отчета на фискальном регистраторе произошла ошибка."
"%ОписаниеОшибки%"
"Отчет на фискальном регистраторе не сформирован.';vi='Khi xóa báo cáo trên máy ghi nhận tiền mặt đã xảy ra lỗi."
"%ErrorDescription%"
"Chưa tạo báo cáo trên máy ghi nhận tiền mặt."
"'");
				MessageText = StrReplace(MessageText, "%ErrorDescription%", Output_Parameters[1]);
			CommonUseClientServer.MessageToUser(MessageText);
		EndIf;
		
		EquipmentManagerClient.DisableEquipmentById(UUID, DeviceIdentifier);
		
	Else
		MessageText = NStr("en='An error occurred when connecting the device.';ru='При подключении устройства произошла ошибка.';vi='Khi kết nối thiết bị xảy ra lỗi'") + Chars.LF + ErrorDescription;
		CommonUseClientServer.MessageToUser(MessageText);
	EndIf;
	
EndProcedure

#EndRegion