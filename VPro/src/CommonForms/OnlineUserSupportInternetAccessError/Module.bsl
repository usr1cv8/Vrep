
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then
		Return;
	EndIf;
	
	LaunchLocation = Parameters.LaunchLocation;
	
	ErrorDescription = Parameters.ErrorDescription;
	ErrorDescriptionFilled = Not IsBlankString(ErrorDescription);
	
	WindowOptionsKey = LaunchLocation + String(ErrorDescriptionFilled);
	
	If TypeOf(Parameters.LaunchParameters) = Type("Structure") Then
		LaunchParameters = Parameters.LaunchParameters;
	Else
		LaunchParameters = New Structure;
	EndIf;
	
	Items.ErrorDescription.Visible = ErrorDescriptionFilled;
	
	Items.DecorationParameters.Visible =
		OnlineUserSupportServerCall.AvailableOnlineSupportConnectionParametersSetting();
	
	If Parameters.OnStart Then
		LaunchOnStart = True;
	Else
		Items.LaunchOnStart.Visible = False;
	EndIf;
	
	// Form appearance setting
	If ClientApplicationInterfaceCurrentVariant() = ClientApplicationInterfaceVariant.Taxi Then
		Items.GroupHeader.Representation           = UsualGroupRepresentation.WeakSeparation;
		Items.DetailsGroup.Representation = UsualGroupRepresentation.WeakSeparation;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Items.DecorationParameters.Visible Then
		Items.DecorationParameters.Visible = Not InternetSupportParametersFormIsOpenable();
	EndIf;
	
EndProcedure

#EndRegion

#Region HeaderFormItemsEventsHandlers

&AtClient
Procedure DecorationParametersURLProcessing(Item, URL, StandardProcessing)
	
	If URL = "WebITSParams" Then
		StandardProcessing = False;
		OnlineUserSupportClient.OpenConnectionParametersSettingsForm(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure SupportMessageLabelURLProcessing(Item, URL, StandardProcessing)
	
	If URL = "SendMail" Then
		
		StandardProcessing = False;
		
		#If WebClient Or MobileClient Then
		
		// Asynchronous launch with extention connection to work with files.
		Notification = New NotifyDescription("SendMessageToSupport", ThisObject);
		MessageText = NStr("en='To send messages, connect the file operation extension.';ru='Для отправки сообщения необходимо подключить расширение работы с файлами.';vi='Để gửi thông báo, cần kết nối phần mở rộng làm việc với tệp.'");
		CommonUseClient.CheckFileOperationsExtensionConnected(Notification, MessageText);
		
		#Else
		
		// Synchronous launch
		Try
			RunApp("mailto:webits-info@1c.ru");
		Except
			OnlineUserSupportServerCall.WriteErrorInEventLogMonitor(
				NStr("en='Cannot open email client:';ru='Не удалось открыть почтовый клиент:';vi='Không thể mở Client E-mail:'")
					+ " " + DetailErrorDescription(ErrorInfo()));
			ShowMessageBox(,
				NStr("en='Cannot start the application to operate with email.';ru='Не удалось запустить приложение для работы с электронной почтой.';vi='Không thể khởi động ứng dụng để làm việc với E-mail.'"));
		EndTry;
		
		#EndIf
		
	EndIf;
	
EndProcedure

&AtClient
Procedure LaunchOnStartOnChange(Item)
	
	SetLaunchOnStartSetting(LaunchOnStart);
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure RetryConnectionAttempt(Command)
	
	Close();
	
	OnlineUserSupportClient.LaunchMechanism(LaunchLocation, LaunchParameters, True);
	
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

&AtClient
Function InternetSupportParametersFormIsOpenable()
	
	NotificationParameters = New Structure("FormIsOpened", False);
	Notify("CheckOnlineSupportParametersFormOpening", NotificationParameters);
	Return NotificationParameters.FormIsOpened;
	
EndFunction

&AtServerNoContext
Procedure SetLaunchOnStartSetting(SettingValue)
	
	CommonSettingsStorage.Save(
		"OnlineUserSupport",
		"AlwaysShowOnApplicationStart",
		SettingValue);
	
EndProcedure

&AtClient
Procedure SendMessageToSupport(ExtensionAttached, AdditParameters) Export
	
	ApplicationLaunchNotification = New NotifyDescription(
		"ApplicationLaunchEnding",
		ThisObject,
		,
		"ApplicationLaunchException",
		ThisObject);
	
	BeginRunningApplication(ApplicationLaunchNotification, "mailto:webits-info@1c.ru");
	
EndProcedure

&AtClient
Procedure ApplicationLaunchEnding(ReturnCode, AdditParameters) Export
	
	Return;
	
EndProcedure

&AtClient
Procedure ApplicationLaunchException(InfError, StandardProcessing, AdditParameters) Export
	
	StandardProcessing = False;
	
	OnlineUserSupportServerCall.WriteErrorInEventLogMonitor(
		NStr("en='Cannot open email client.';ru='Не удалось открыть почтовый клиент.';vi='Không thể mở Client E-mail.'")
			+ " " + DetailErrorDescription(InfError));
	
	ShowMessageBox(,
		NStr("en='Cannot start the application to operate with email.';ru='Не удалось запустить приложение для работы с электронной почтой.';vi='Không thể khởi động ứng dụng để làm việc với E-mail.'"));
	
EndProcedure

#EndRegion
