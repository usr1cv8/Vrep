
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
	
	If ClientApplicationInterfaceCurrentVariant() = ClientApplicationInterfaceVariant.Taxi Then
		Items.HeaderGroupRegNumbers.Representation = UsualGroupRepresentation.None;
		Items.ContentGroupRegNumber.Representation = UsualGroupRepresentation.None;
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
Procedure UserLogoutLabelRegNumberClick(Item)
	
	OnlineUserSupportClient.HandleUserExit(InteractionContext, ThisObject);
	
EndProcedure

&AtClient
Procedure RegisteredProductsListRegNumberClick(Item)
	
	RefAddress       = "https://1c-dn.com/user/updates/registration/";
	AddressSupplement = OnlineUserSupportClientServer.SessionParameterValue(
		InteractionContext.COPContext,
		"authUrlPassword");
	AddressSupplement = String(AddressSupplement);
	RefAddress       = AddressSupplement + RefAddress;
	
	PageTitle = NStr("en='List of registered products';ru='Список зарегистрированных продуктов';vi='Danh sách sản phẩm đã đăng ký'");
	OnlineUserSupportClient.OpenInternetPage(
		RefAddress,
		PageTitle);
	
EndProcedure

&AtClient
Procedure RegisterProductRegNumberClick(Item)
	
	QueryParameters = New Array;
	QueryParameters.Add(New Structure("Name, Value", "registerProduct", "true"));
	
	OnlineUserSupportClient.ServiceCommandsDataProcessor(InteractionContext, ThisObject, QueryParameters);
	
EndProcedure

&AtClient
Procedure HeaderExplanationRegNumberNavigationRefProcessing(Item, URL, StandardProcessing)
	
	If URL = "TechSupport" Then
		
		StandardProcessing = False;
		OnlineUserSupportClient.OpenDialogForSendingEmail(
			InteractionContext,
			MessageParametersToTechicalSupport());
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DoNotRemindAboutAuthorizationBefore1OnChange(Item)
	
	CustomizeSettingDoNotRemindAboutAuthorizationBeforeServer(DoNotRemindAboutAuthorizationBefore);
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure OKRegNumber(Command)
	
	If Not FieldsAreFilledCorrectly() Then
		Return;
	EndIf;
	
	OnlineUserSupportClientServer.WriteContextParameter(
		InteractionContext.COPContext,
		"regnumber",
		RegistrationNumberRegNumber);
	
	QueryParameters = New Array;
	QueryParameters.Add(New Structure("Name, Value", "regnumber", RegistrationNumberRegNumber));
	
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
	
	UserTitle = NStr("en='Authorize:';ru='Авторизоваться:';vi='Được đăng nhập:'") + " " + Parameters.login;
	
	Items.UserLoginLabelRegNumber.Title = UserTitle;
	RegistrationNumberRegNumber = Parameters.regNumber;
	
	StorePassword = True;
	
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

&AtClient
Function FieldsAreFilledCorrectly()
	
	Result = True;
	
	If IsBlankString(RegistrationNumberRegNumber) Then
		
		Message = New UserMessage;
		Message.Text = NStr("en='Registration number is not filled in';ru='Не заполнено поле ""Регистрационный номер""';vi='Chưa điền trường ""Số đăng ký""'");
		Message.Field  = "RegistrationNumberRegNumber";
		Message.Message();
		
		Result = False;
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Function MessageParametersToTechicalSupport()
	
	Result = New Structure;
	Result.Insert("Subject", NStr("en='Online support. Enter registration number.';ru='Интернет-поддержка. Ввод регистрационного номера.';vi='Hỗ trợ qua Internet. Nhập số đăng ký.'"));
	
	MessageText = NStr("en='Hello!"
"I can not enter registration number for the software product"
"to connect to Online Support."
"Please help me to solve this issue."
""
"Login: %1."
"Registration number: %2."
"%TechnicalParameters%"
"-----------------------------------------------"
"Kind Regards, .';ru='Здравствуйте!"
"У меня не получается ввести регистрационный номер программного продукта"
"для подключения Интернет-поддержки."
"Прошу помочь разобраться с проблемой."
""
"Логин: %1."
"Регистрационный номер: %2."
""
"%ТехническиеПараметры%"
"-----------------------------------------------"
"С уважением, .';vi='Xin chào!"
"Tôi không thể nhập số đăng ký của phần mềm"
"để kết nối đến bộ phận hỗ trợ qua Internet."
"Hãy giúp tôi giải quyết vấn đề này."
""
"Tên đăng nhập: %1."
"Số đăng ký: %2."
""
"%TechnicalParameters%"
"-----------------------------------------------"
"Trân trọng, .'");
	
	UserLogin = OnlineUserSupportClientServer.SessionParameterValue(
		InteractionContext.COPContext,
		"login");
	
	MessageText = StringFunctionsClientServer.SubstituteParametersInString(
		MessageText,
		UserLogin,
		RegistrationNumberRegNumber);
	
	Result.Insert("MessageText", MessageText);
	
	Return Result;
	
EndFunction

#EndRegion
