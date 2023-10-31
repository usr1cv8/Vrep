
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then // Return if the form for analysis is received.
		Return;
	EndIf;
	
	If Not Parameters.Property("OpenByScenario") Then
		Raise NStr("en='Data processor is not intended for direct usage.';ru='Обработка не предназначена для непосредственного использования.';vi='Bộ xử lý không được dùng để sử dụng trực tiếp.'");
	EndIf;
	
	SkipExit = Parameters.SkipExit;
	
	Items.MessageText.Title = Parameters.MessageText;
	Items.RecommendedPlatformVersion.Title = Parameters.RecommendedPlatformVersion;
	SystemInfo = New SystemInfo;
	
	TextCondition = ?(Parameters.Done, NStr("en='Required';ru='Required';vi='Cần thiết'"), NStr("en='recommended';ru='рекомендуемые';vi='khuyến cáo'"));
	Items.Version.Title = StringFunctionsClientServer.SubstituteParametersInString(
		Items.Version.Title, TextCondition, SystemInfo.AppVersion);
	
	If Parameters.Done Then
		Items.QuestionText.Visible = False;
		Items.FormNo.Visible     = False;
		Title = NStr("en='Update platform version';ru='Необходимо обновить версию платформы';vi='Cần cập nhật phiên bản nền tảng'");
	EndIf;
	
	If (ClientApplicationInterfaceCurrentVariant() <> ClientApplicationInterfaceVariant.Taxi) Then
		Items.RecommendedPlatformVersion.Font = New Font(,, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose()
	
	If Not ActionDetermined Then
		ActionDetermined = True;
		
		If Not SkipExit Then
			Terminate();
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region HeaderFormItemsEventsHandlers

&AtClient
Procedure HyperlinkTextClick(Item)
	
	OpenForm("DataProcessor.NotRecommendedPlatformVersion.Form.PlatformUpdateOrder",,ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure ContinueWork(Command)
	
	ActionDetermined = True;
	Close("Continue");
	
EndProcedure

&AtClient
Procedure Done(Command)
	
	ActionDetermined = True;
	If Not SkipExit Then
		Terminate();
	EndIf;
	Close();
	
EndProcedure

#EndRegion
