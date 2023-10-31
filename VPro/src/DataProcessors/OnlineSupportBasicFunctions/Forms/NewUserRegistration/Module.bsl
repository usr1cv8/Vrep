
// Storing context of interaction with the service
&AtClient
Var InteractionContext Export;

#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then
		Return;
	EndIf;
	
	If ClientApplicationInterfaceCurrentVariant() = ClientApplicationInterfaceVariant.Taxi Then
		Items.DecorationHeaderName.Width = 8;
		Items.DecorationHeaderCity.Width = 8;
		Items.GroupHeaderExplanations.Representation = UsualGroupRepresentation.None;
		Items.GroupContent.Representation = UsualGroupRepresentation.None;
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
Procedure LoginOnChange(Item)
	
	Login = TrimAll(Login);
	
EndProcedure

&AtClient
Procedure EmailOnChange(Item)
	
	Email = TrimAll(Email);
	
EndProcedure

&AtClient
Procedure HeaderExplanationTwoNavigationRefProcessing(Item, URL, StandardProcessing)
	
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
Procedure RegisterAndLogin(Command)
	
	If Not FieldsAreFilledCorrectly() Then
		Return;
	EndIf;
	
	QueryParameters = New Array;
	QueryParameters.Add(New Structure("Name, Value", "login"      , Login));
	QueryParameters.Add(New Structure("Name, Value", "password"   , Password));
	QueryParameters.Add(New Structure("Name, Value", "email"      , Email));
	QueryParameters.Add(New Structure("Name, Value", "SecondName" , Surname));
	QueryParameters.Add(New Structure("Name, Value", "FirstName"  , Name));
	QueryParameters.Add(New Structure("Name, Value", "MiddleName" , Patronymic));
	QueryParameters.Add(New Structure("Name, Value", "City"       , City));
	QueryParameters.Add(New Structure("Name, Value", "PhoneNumber", Phone));
	QueryParameters.Add(New Structure("Name, Value", "workPlace"  , Workplace));
	
	OnlineUserSupportClient.ServiceCommandsDataProcessor(InteractionContext, ThisObject, QueryParameters);
	
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

&AtClient
Procedure MessageToUser(MessageText, FieldName, Cancel)
	
	Cancel = True;
	Message = New UserMessage;
	Message.Text = MessageText;
	Message.Field  = FieldName;
	Message.Message();
	
EndProcedure

// Checks form fields filling
//
// Return value: Boolean. True - Fields are
// 	filled Incorrectly, False - otherwise.
//
&AtClient
Function FieldsAreFilledCorrectly()
	
	Cancel = False;
	
	If IsBlankString(Login) Then
		MessageToUser(
			NStr("en='Login is not filled in.';ru='Поле ""Логин"" не заполнено.';vi='Chưa điền trường ""Tên đăng nhập"".'"),
			"Login",
			Cancel);
	EndIf;
	
	If IsBlankString(Password) Then
		MessageToUser(
			NStr("en='Password is not filled in.';ru='Поле ""Пароль"" не заполнено.';vi='Chưa điền trường ""Mật khẩu"".'"),
			"Password",
			Cancel);
	ElsIf Password <> PasswordConfirmation Then
		MessageToUser(
			NStr("en='Password and its confirmation do not match.';ru='Не совпадают пароль и его подтверждение.';vi='Không trùng mật khẩu và việc xác nhận mật khẩu.'"),
			"PasswordConfirmation",
			Cancel);
	EndIf;
	
	If IsBlankString(Email) Then
		MessageToUser(
			NStr("en='Email is not filled in.';ru='Поле ""E-mail"" не заполнено.';vi='Chưa điền trường ""Email"".'"),
			"Email",
			Cancel);
	EndIf;
	
	Return (NOT Cancel);
	
EndFunction

&AtClient
Function MessageParametersToTechicalSupport()
	
	Result = New Structure;
	Result.Insert("Subject"  , NStr("en='Online support. Register new user.';ru='Интернет-поддержка. Регистрация нового пользователя.';vi='Hỗ trợ qua Internet. Đăng ký người sử dụng mới.'"));
	Result.Insert("FromWhom", Email);
	
	MessageText = NStr("en='Dear Sir or Madam, I cannot register a new user to connect online support. Please help me to deal with the issue. Login: %1 Email: %2 Last name: %3 Name: %4 Patronymic: %5 City: %6 Phone: %7 Place of employment: %8. %TechnicalParameters% ----------------------------------------------- Sincerely, .';ru='Здравствуйте! У меня не получается зарегистрировать нового пользователя для подключения Интернет-поддержки. Прошу помочь разобраться с проблемой. Логин: %1 E-mail: %2 Фамилия: %3 Имя: %4 Отчество: %5 Город: %6 Телефон: %7 Место работы: %8. %ТехническиеПараметры% ----------------------------------------------- С уважением, .';vi='Xin chào! Tôi chưa thể đăng ký người sử dụng mới để kết nối hỗ trợ qua Internet. Tôi yêu cầu xử lý vấn đề này."
"Tên đăng nhập: %1 Email: %2 Họ: %3 Tên: %4 Tên đệm: %5 Thành phố: %6 Điện thoại: %7 Nơi làm việc: %8 TechnicalParameters% ----------------------------------------------- Trân trọng,'");
	
	MessageText = StringFunctionsClientServer.SubstituteParametersInString(
		MessageText,
		Login,
		Email,
		Surname,
		Name,
		Patronymic,
		City,
		Phone,
		Workplace);
	
	Result.Insert("MessageText", MessageText);
	
	Return Result;
	
EndFunction

#EndRegion
