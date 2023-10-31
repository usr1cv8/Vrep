#Region EventsHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	NotifyDescription = New NotifyDescription("ImportCurrencyClient", ThisObject);
	ShowQueryBox(NOTifyDescription, 
		NStr("en='The files will be imported from the service manager with full data on the exchange rates of all currencies for the whole period."
"The exchange rates marked in the data areas for import from the Internet will be replaced in the background job. Continue?';ru='Будет произведена загрузка файла с полной информацией по курсами всех валют за все время из менеджера сервиса."
"Курсы валют, помеченных в областях данных для загрузки из сети Интернет, будут заменены в фоновом задании. Продолжить?';vi='Sẽ tiến hành kết nhập tệp với đầy đủ thông tin theo tỷ giá của tất cả tiền tệ trong toàn thời gian quản lý Service."
"Tỷ giá hối đoái mà được đánh dấu trong vùng dữ liệu để kết nhập từ mạng Internet sẽ được thay thế trong nhiệm vụ nền. Tiếp tục?'"), 
		QuestionDialogMode.YesNo);
	
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

&AtClient
Procedure ImportCurrencyClient(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	ImportRates();
	
	ShowUserNotification(
		NStr("en='Rates will be imported in background after some time.';ru='Курсы будут загружены в фоновом режиме через непродолжительное время.';vi='Sẽ kết nhập tỷ giá theo nhiệm vụ nền qua thời gian ngắn.'"), ,
		NStr("en='Rates will be imported in background after some time.';ru='Курсы будут загружены в фоновом режиме через непродолжительное время.';vi='Sẽ kết nhập tỷ giá theo nhiệm vụ nền qua thời gian ngắn.'"),
		PictureLib.Information32);
	
EndProcedure

&AtServer
Procedure ImportRates()
	
	CurrencyRatesServiceSaaS.ImportRates();
	
EndProcedure

#EndRegion
