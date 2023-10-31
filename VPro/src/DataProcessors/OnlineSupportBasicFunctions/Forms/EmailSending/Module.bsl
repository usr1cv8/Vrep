
// Storing context of interaction with the service
&AtClient
Var InteractionContext Export;

#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then
		Return;
	EndIf;
	
	// Create email document depending on the transferred parameters
	WriteEmail(Parameters);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	OnlineUserSupportClient.HandleFormOpening(InteractionContext, ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure Send(Command)
	
	// Check field filling
	If IsBlankString(Email) Then
		UserMessage = New UserMessage;
		UserMessage.Text = NStr("en='The ""Email for feedback"" field is not filled in.';ru='Поле ""E-mail для обратной связи"" не заполнено.';vi='Chưa điền trường ""Email để liên hệ lại"".'");
		UserMessage.Field  = "Email";
		UserMessage.Message();
		Return;
	EndIf;
	
	If IsBlankString(Subject) Then
		UserMessage = New UserMessage;
		UserMessage.Text = NStr("en='The ""Email subject"" field is not filled in.';ru='Поле ""Тема сообщения"" не заполнено.';vi='Chưa điền trường ""Chủ đề thông báo"".'");
		UserMessage.Field  = "Subject";
		UserMessage.Message();
		Return;
	EndIf;
	
	If IsBlankString(Message) Then
		UserMessage = New UserMessage;
		UserMessage.Text = NStr("en='Email text is not filled in.';ru='Не заполнен тест письма.';vi='Chưa điền nội dung thư.'");
		UserMessage.Field  = "Message";
		UserMessage.Message();
		Return;
	EndIf;
	
	EmailParameters = New Structure("FromWhom, Subject, Message", Email, Subject, Message);
	If Not IsBlankString(ConditionalRecipientName) Then
		EmailParameters.Insert("ConditionalRecipientName", ConditionalRecipientName);
	EndIf;
	
	Status(NStr("en='Send';ru='Отправка';vi='Gửi'")
		,
		,
		NStr("en='Sending email to the technical support.';ru='Выполняется отправка электронного письма в службу тех. поддержки.';vi='Đang gửi email đến bộ phận hỗ trợ kỹ thuật.'"),
		PictureLib.OnlineUserSupportSendingLetter);
	
	SendingResult = OnlineUserSupportClient.SendEmailToSupportService(
		EmailParameters,
		InteractionContext);
	
	Status();
	
	If Not SendingResult Then
		ShowMessageBox(,
			NStr("en='An error occurred while sending email."
"For more details see the event log.';ru='При отправке письма произошла ошибка."
"Подробнее см. в журнале регистрации.';vi='Khi gửi thư đã xảy ra lỗi."
"Chi tiết xem trong nhật ký sự kiện.'"));
	Else
		Close();
		ShowMessageBox(, NStr("en='Message is sent successfully.';ru='Сообщение успешно отправлено.';vi='Đã gửi thông báo thành công.'"));
	EndIf;
	
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

// Fills in email template depending on the parameters value.
//
// Parameters:
// - Parameters (FormDataStructure, Structure) - Parameters of template creation.
//
&AtServer
Procedure WriteEmail(Parameters)
	
	Subject = Parameters.Subject;
	
	Message = StrReplace(
		Parameters.MessageText,
		"%TechnicalParameters%",
		TechnicalParametersText(Parameters.OnStart));
	
	If IsBlankString(Parameters.Whom) Then
		EMailForSending = "webits-info@1c.ru";
	Else
		EMailForSending = Parameters.Whom;
	EndIf;
	
	Items.TitleExplanation.Title = StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en='The email will be sent to technical support to %1';ru='Письмо будет отправлено в техподдержку пользователей на адрес %1';vi='Đã gửi thư đến bộ phận hỗ trơ người sử dụng đến địa chỉ %1'"),
		EMailForSending);
	
	If Not IsBlankString(Parameters.FromWhom) Then
		Email = Parameters.FromWhom;
	EndIf;
	
	ConditionalRecipientName = Parameters.ConditionalRecipientName;
	
	If IsBlankString(Subject) Then
		Subject = NStr("en='<Specify email subject>';ru='<Укажите тему сообщения>';vi='<Hãy chỉ ra chủ đề thông báo>'");
	EndIf;
	
	If IsBlankString(Message) Then
		Message = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='<Enter email content>,"
""
"Login: %1"
"Kind Regards, .';ru='<Заполните"
""
"содержимое письма>,"
"Логин: %1 С уважением, .';vi='<Hãy điền"
""
"nội dung thư>,"
"Đăng nhập: %1 Trân trọng, .'"),
			Parameters.Login);
	EndIf;
	
EndProcedure

// Creates template for the text of technical parameters.
//
// Return value - String - template of technical parameters.
//
&AtServer
Function TechnicalParametersText(OnStart)
	
	SysInfo = New SystemInfo;
	
	If OnStart Then
		CallServicePosition = NStr("en='auto';ru='автоматический';vi='tự động'");
	Else
		CallServicePosition = NStr("en='manual';ru='руководство';vi='hướng dẫn'");
	EndIf;
	
	TechnicalParameters = NStr("en='Technical parameters of connection:"
"(needed to simulate the described issue) "
""
"- configuration name: %1,"
"- configuration version: %2,"
"- platform version: %3,"
"- online support library version: %4,"
"- user language: %5,"
"- application kind: managed,"
"- service call: %6.';ru='Технические параметры подключения:"
"(нужны для воспроизведения описанной проблемы)"
""
"- имя конфигурации: %1,"
"- номер версии конфигурации: %2,"
"- номер версии платформы: %3,"
"- версия библиотеки Интернет-поддержки: %4,"
"- язык пользователя: %5,"
"- вид приложения: управляемый,"
"- вызов сервиса: %6.';vi='Tham số kết nối kỹ thuật:"
"(cần để tái hiện lỗi đã mô tả)"
""
"- tên cấu hình: %1,"
"- số phiên bản cấu hình: %2,"
"- số phiên bản nền tảng: %3,"
"- phiên bản thư viện hỗ trợ qua Internet: %4,"
"- ngôn ngữ người sử dụng: %5,"
"- dạng ứng dụng: quản lý,"
"- gọi dịch vụ: %6.'")
		+ Chars.LF;
	
	TechnicalParameters = StringFunctionsClientServer.SubstituteParametersInString(
		TechnicalParameters,
		String(OnlineUserSupportClientServer.ConfigurationName()),
		String(OnlineUserSupportClientServer.ConfigurationVersion()),
		String(SysInfo.AppVersion),
		OnlineUserSupportClientServer.LibraryVersion(),
		CurrentLocaleCode(),
		CallServicePosition);
	
	Return TechnicalParameters;
	
EndFunction

#EndRegion
