
// Storing context of interaction with the service
&AtClient
Var InteractionContext Export;

#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then
		Return;
	EndIf;
	
	LaunchLocation = Parameters.LaunchLocation;
	
	// Form filling with required parameters.
	FillForm();
	
	// If login and password are empty, user name and
	// password filling are overridden by default.
	If IsBlankString(Login) Then
		UserData = OnlineUserSupportClientServer.NewOnlineSupportUserData();
		OnlineUserSupportOverridable.OnDefineOnlineSupportUserData(
			UserData);
		If TypeOf(UserData) = Type("Structure") Then
			If UserData.Property("Login") Then
				Login = UserData.Login;
				If UserData.Property("Password") Then
					Password = UserData.Password;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	If ClientApplicationInterfaceCurrentVariant() = ClientApplicationInterfaceVariant.Taxi Then
		Items.HeaderExplanationGroupAuthorization.Representation = UsualGroupRepresentation.None;
		Items.AuthorizationContentFillGroup.Representation = UsualGroupRepresentation.None;
	EndIf;
	
	DoNotRemindAboutAuthorizationBeforeDate = OnlineUserSupportServerCall.SettingValueDoNotRemindAboutAuthorizationBefore();
	If DoNotRemindAboutAuthorizationBeforeDate <> '00010101'
		AND CurrentSessionDate() > DoNotRemindAboutAuthorizationBeforeDate Then
		OnlineUserSupportServerCall.CustomizeSettingDoNotRemindAboutAuthorizationBefore(False);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	OnlineUserSupportClient.HandleFormOpening(InteractionContext, ThisObject);
	
EndProcedure

&AtClient
Procedure OnClose()
	
	If Not SoftwareClosing Then
		OnlineUserSupportClient.EndBusinessProcess(InteractionContext);
	EndIf;
	
EndProcedure

#EndRegion

#Region HeaderFormItemsEventsHandlers

&AtClient
Procedure ConnectionExplanationLabelAuthorizationNavigationRefProcessing(Item, URL, StandardProcessing)
	
	If URL = "openUsersSite" Then
		
		StandardProcessing = False;
		PageAddress		= "https://1c-dn.com/user/profile/";
		PageTitle 	= NStr("en='Support users of 1C:Enterprise 8';ru='Поддержка пользователей системы 1С:Предприятие 8';vi='Hỗ trợ người sử dụng hệ thống 1C:DOANH NGHIỆP 8'");
		OnlineUserSupportClient.OpenInternetPage(
			PageAddress,
			PageTitle);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PasswordRecoveryLabelAuthorizationClick(Item)
	
	QueryParameters = New Array;
	QueryParameters.Add(New Structure("Name, Value", "remindPassword", "true"));
	
	OnlineUserSupportClient.ServiceCommandsDataProcessor(InteractionContext, ThisObject, QueryParameters);
	
EndProcedure

&AtClient
Procedure HeaderExplanationAuthorizationNavigationRefProcessing(Item, URL, StandardProcessing)
	
	If URL = "TechSupport" Then
		StandardProcessing = False;
		OnlineUserSupportClient.OpenDialogForSendingEmail(
			InteractionContext,
			MessageParametersToTechicalSupport());
	EndIf;
	
EndProcedure

&AtClient
Procedure DoNotRemindAboutAuthorizationBeforeOnChange(Item)
	
	CustomizeSettingDoNotRemindAboutAuthorizationBeforeServer(DoNotRemindAboutAuthorizationBefore);
	
EndProcedure

&AtClient
Procedure LabelNoLoginAndPasswordAuthorizationClick(Item)
	
	QueryParameters = New Array;
	QueryParameters.Add(New Structure("Name, Value", "registration", "true"));
	OnlineUserSupportClient.ServiceCommandsDataProcessor(InteractionContext, ThisObject, QueryParameters);
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure LoginAuthorization(Command)
	
	If Not FieldsAreFilledCorrectly() Then
		Return;
	EndIf;
	
	OnlineUserSupportClientServer.WriteContextParameter(
		InteractionContext.COPContext,
		"login",
		Login);
	OnlineUserSupportClientServer.WriteContextParameter(
		InteractionContext.COPContext,
		"password",
		Password);
	OnlineUserSupportClientServer.WriteContextParameter(
		InteractionContext.COPContext,
		"savePassword",
		?(StorePassword, "true", "false"));
	
	// User login and password saving, in
	// case of successful authorizaion
	// they are transferred to UserInternetSupportOverridden method. AtUserAuthorizationInInternetSupport()
	
	InteractionContext.COPContext.Login  = Login;
	
	QueryParameters = New Array;
	QueryParameters.Add(New Structure("Name, Value", "login", Login));
	QueryParameters.Add(New Structure("Name, Value", "password", Password));
	QueryParameters.Add(New Structure("Name, Value", "savePassword", ?(StorePassword, "true", "false")));
	
	OnlineUserSupportClient.ServiceCommandsDataProcessor(InteractionContext, ThisObject, QueryParameters);
	
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

// Performs initial filling of the form fields
&AtServer
Procedure FillForm()
	
	If Parameters.OnStart Then
		ShowSettingDateDoNotRemindAboutAuthorizationBefore();
	Else
		Items.DoNotRemindAboutAuthorizationBefore.Visible = False;
	EndIf;
	
	Login  = Parameters.login;
	Password = Parameters.password;
	
	StorePassword = (Parameters.savePassword <> "false");
	
EndProcedure

&AtServer
Procedure ShowSettingDateDoNotRemindAboutAuthorizationBefore()
	
	CommonCheckBoxTitle = NStr("en='Do not remind of connection during seven days';ru='Не напоминать о подключении семь дней';vi='Không nhắc về việc kết nối trong vòng 30 ngày'");
	
	SettingValue = OnlineUserSupportServerCall.SettingValueDoNotRemindAboutAuthorizationBefore();
	DoNotRemindAboutAuthorizationBefore = ?(SettingValue = '00010101', False, True);
	
	CheckBoxLine = CommonCheckBoxTitle
		+ ?(SettingValue = '00010101',
			"",
			" " + NStr("en='(o';ru='(o';vi='(o'") + " " + Format(SettingValue, "DF=dd.MM.yyyy") + ")");
	
	Items.DoNotRemindAboutAuthorizationBefore.Title = CheckBoxLine;
	
EndProcedure

&AtServer
Procedure CustomizeSettingDoNotRemindAboutAuthorizationBeforeServer(Value)
	
	OnlineUserSupportServerCall.CustomizeSettingDoNotRemindAboutAuthorizationBefore(Value);
	ShowSettingDateDoNotRemindAboutAuthorizationBefore();
	
EndProcedure

// Checks Username and Password fields filling
//
// Return value: Boolean. True - Fields are
// 	filled Incorrectly, False - otherwise.
//
&AtClient
Function FieldsAreFilledCorrectly()
	
	Result = True;
	
	If IsBlankString(Login) Then
		
		Message = New UserMessage;
		Message.Text = NStr("en='Login is not filled in';ru='Не заполнено поле ""Логин""';vi='Chưa điền trường ""Tên đăng nhập""'");
		Message.Field  = "Login";
		Message.Message();
		Result = False;
		
	EndIf;
	
	If IsBlankString(Password) Then
		
		Message = New UserMessage;
		Message.Text = NStr("en='Password is not filled in';ru='Не заполнено поле ""Пароль""';vi='Chưa điền trường ""Mật khẩu""'");
		Message.Field  = "Password";
		Message.Message();
		
		Result = False;
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Function MessageParametersToTechicalSupport()
	
	Result = New Structure;
	Result.Insert("Subject", NStr("en='Online support. Authorization.';ru='Интернет-поддержка. Авторизация.';vi='Hỗ trợ qua Internet. Đăng nhập.'"));
	
	MessageText = StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en='Hello!"
"I can not authorize and connect to online support."
"My login and password are entered correctly. Please help me to solve the issue."
""
"Login: %1."
"%TechnicalParameters%"
"-----------------------------------------------"
"Best regards, .';ru='Здравствуйте!"
"У меня не получается пройти авторизацию и подключить Интернет-поддержку."
"Логин и пароль мной введены правильно. Прошу помочь разобраться с проблемой."
""
"Логин: %1."
""
"%ТехническиеПараметры%"
"-----------------------------------------------"
"С уважением, .';vi='Xin chào!"
"Tôi không thể đăng nhập và kết nối với bộ phận hỗ trợ kỹ thuật."
"Tôi đã nhập đúng tên và mật khẩu. Hãy giúp tôi giải quyết vấn đề này."
""
"Tên đăng nhập: %1."
"%TechnicalParameters%"
"-----------------------------------------------"
"Trân trọng, .'"),
		Login);
	
	Result.Insert("MessageText", MessageText);
	
	Return Result;
	
EndFunction

#EndRegion
