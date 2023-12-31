
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skipping the initialization to guarantee that the form will be received if the AutoTest parameter is passed.
	If Parameters.Property("AutoTest") Then
		Return;
	EndIf;
	
	PatternData = Parameters.PatternData;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	// Peripherals
	If EquipmentManagerClient.RefreshClientWorkplace() Then
		ErrorDescription = "";

		SupporTypesVO = New Array();
		SupporTypesVO.Add("MagneticCardReader");

		If Not EquipmentManagerClient.ConnectEquipmentByType(UUID, SupporTypesVO, ErrorDescription) Then
			MessageText = NStr("en='An error occurred while"
"connecting peripherals: ""%ErrorDetails%"".';ru='При подключении оборудования"
"произошла ошибка: ""%ОписаниеОшибки%"".';vi='Khi kết nối thiết bị"
"đã xảy ra lỗi: ""%ОписаниеОшибки%"".'");
			MessageText = StrReplace(MessageText, "%ErrorDescription%", ErrorDescription);
			CommonUseClientServer.MessageToUser(MessageText);
		EndIf;
	EndIf;
	// End Peripherals
EndProcedure

&AtClient
Procedure OnClose()
	// Peripherals
	SupporTypesVO = New Array();
	SupporTypesVO.Add("MagneticCardReader");

	EquipmentManagerClient.DisableEquipmentByType(UUID, SupporTypesVO);
	// End Peripherals
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	// Peripherals
	If Source = "Peripherals"
	   AND IsInputAvailable() Then
		If EventName = "TracksData" Then
			If Parameter[1] = Undefined Then
				TracksData = Parameter[0];
			Else
				TracksData = Parameter[1][1];
			EndIf;
			
			ClearMessages();
			If Not EquipmentManagerClient.CodeCorrespondsToMCTemplate(TracksData, PatternData) Then
				CommonUseClientServer.MessageToUser(NStr("en='The card does not match template.';ru='Карта не соответствует шаблону!';vi='Thẻ không tương ứng với khuôn mẫu!'"));
				Return;
			EndIf;
			
			// Display encrypted fields
			If Parameter[1][3] = Undefined
				OR Parameter[1][3].Count() = 0 Then
				CommonUseClientServer.MessageToUser(NStr("en='Failed to identify any field. Maybe, template fields configured incorrectly.';ru='Не удалось распознать ни одного поля. Возможно, поля шаблона настроены неверно.';vi='Không thể nhận biết bất kỳ trường nào. Có thể trường khuôn mẫu đã thiết lập sai.'"));
			Else
				TemplateFound = Undefined;
				For Each curTemplate IN Parameter[1][3] Do
					If curTemplate.Pattern = PatternData.Ref Then
						TemplateFound = curTemplate;
					EndIf;
				EndDo;
				If TemplateFound = Undefined Then
					CommonUseClientServer.MessageToUser(NStr("en='The code does not match this template. Maybe, the template is configured incorrectly.';ru='Код не соответствует данному шаблону. Возможно, шаблон настроен неверно.';vi='Mã không tương ứng với khuôn mẫu này. Có thể, khuôn mẫu đã thiết lập sai.'"));
				Else
					MessageText = NStr("en='The card matches the template and contains the following fields:';ru='Карта соответствует шаблону и содержит следующие поля:';vi='Thẻ tương ứng với khuôn mẫu và có các trường sau:'")+Chars.LF+Chars.LF;
					Iterator = 1;
					For Each curField IN TemplateFound.TracksData Do
						MessageText = MessageText + String(Iterator)+". "+?(ValueIsFilled(curField.Field), String(curField.Field), "")+" = "+String(curField.FieldValue)+Chars.LF;
						Iterator = Iterator + 1;
					EndDo;
					ShowMessageBox(,MessageText, , NStr("en='Card code decryption result';ru='Результат расшифровки кода карты';vi='Kết quả diễn giải mã thẻ'"));
				EndIf;
			EndIf;
			
		EndIf;
	EndIf;
	// End Peripherals
EndProcedure

&AtClient
Procedure ExternalEvent(Source, Event, Data)
	
	If IsInputAvailable() Then
		
		DetailsEvents = New Structure();
		ErrorDescription  = "";
		DetailsEvents.Insert("Source", Source);
		DetailsEvents.Insert("Event",  Event);
		DetailsEvents.Insert("Data",   Data);
		
		Result = EquipmentManagerClient.GetEventFromDevice(DetailsEvents, ErrorDescription);
		If Result = Undefined Then 
			MessageText = NStr("en='An error occurred during the processing of external event from the device:';ru='При обработке внешнего события от устройства произошла ошибка:';vi='Khi xử lý sự kiện bên ngoài từ thiết bị, đã xảy ra lỗi:'")
								+ Chars.LF + ErrorDescription;
			CommonUseClientServer.MessageToUser(MessageText);
		Else
			NotificationProcessing(Result.EventName, Result.Parameter, Result.Source);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion