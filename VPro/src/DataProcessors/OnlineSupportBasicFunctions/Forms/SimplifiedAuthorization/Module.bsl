
// Storing context of interaction with the service
&AtClient
Var InteractionContext Export;

#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then
		Return;
	EndIf;
	
	ThisDataProcessor = DataProcessorObject();
	
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
Procedure SiteUsersConnectionAuthorizationClick(Item)
	
	PageAddress = "https://1c-dn.com/user/profile/";
	PageTitle = NStr("en='Support users of 1C:Enterprise 8';ru='Поддержка пользователей системы 1С:Предприятие 8';vi='Hỗ trợ người sử dụng hệ thống 1C:DOANH NGHIỆP 8'");
	OnlineUserSupportClient.OpenInternetPage(
		PageAddress,
		PageTitle);
	
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

// Returns the value of the external handling.
//
// Return value: object of ExternalProcessor type - External handling.
//
&AtServer
Function DataProcessorObject()
	
	Return FormAttributeToValue("Object");
	
EndFunction

// Performs initial filling of form fields
&AtServer
Procedure FillForm()
	
	UserTitle = NStr("en='Authorize:';ru='Авторизоваться:';vi='Được đăng nhập:'") + " " + Parameters.login;
	
	Login  = Parameters.login;
	Password = Parameters.password;
	
	StorePassword = (Parameters.savePassword <> "false");
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Field filling check.

// Checks Username and Password fields filling
//
// Return value: Boolean. True - Fields are
// 	filled Inorrectly, False - otherwise.
//
&AtClient
Function FieldsAreFilledCorrectly()
	
	If IsBlankString(Login) Then
		
		Message = New UserMessage;
		Message.Text = NStr("en='Login is not filled in';ru='Не заполнено поле ""Логин""';vi='Chưa điền trường ""Tên đăng nhập""'");
		Message.Field  = "Login";
		Message.Message();
		Return False;
		
	EndIf;
	
	If IsBlankString(Password) Then
		
		Message = New UserMessage;
		Message.Text = NStr("en='Password is not filled in';ru='Не заполнено поле ""Пароль""';vi='Chưa điền trường ""Mật khẩu""'");
		Message.Field  = "Password";
		Message.Message();
		
		Return False;
		
	EndIf;
	
	Return True;
	
EndFunction

&AtClient
Function MessageParametersToTechicalSupport()
	
	Result = New Structure;
	Result.Insert("Subject", NStr("en='Online support. Authorization.';ru='Интернет-поддержка. Авторизация.';vi='Hỗ trợ qua Internet. Đăng nhập.'"));
	
	MessageText = StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en=""Hello! I can't authorize and connect Online support. My login and password are entered correctly. Please, help me to solve the problem. Login: %1. %TechnicalParameters% ----------------------------------------------- Yours sincerely, ."";ru='Здравствуйте! У меня не получается пройти авторизацию и подключить Интернет-поддержку. Логин и пароль мной введены правильно. Прошу помочь разобраться с проблемой. Логин: %1. %ТехническиеПараметры% ----------------------------------------------- С уважени';vi='Xin chào! Tôi chưa thể đăng nhập và kết nối hỗ trợ qua Internet. Tôi đã nhập đúng tên đăng nhập và mật khẩu. Tôi yêu cầu xử lý vấn đề này. Tên đăng nhập: %1. %TechnicalParameters% ----------------------------------------------- Trân trọng,'"),
		Login);
	
	Result.Insert("MessageText", MessageText);
	
	Return Result;
	
EndFunction

#EndRegion
