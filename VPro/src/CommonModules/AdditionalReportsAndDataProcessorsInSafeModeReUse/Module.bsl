////////////////////////////////////////////////////////////////////////////////
// Subsystem "Additional reports and data processors", safe mode extension.
// Procedures and functions with repeated use of returned values.
// 
////////////////////////////////////////////////////////////////////////////////

#Region ProgramInterface

// Returns an array of methods that can
// be run by the safe mode expansion.
//
// Return values: Array(String).
//
Function GetAllowedMethods() Export
	
	Result = New Array();
	
	// AdditionalReportsAndDataProcessorsInSafeMode
	Result.Add("AdditionalReportsAndDataProcessorsInSafeMode.XMLReaderFromBinaryData");
	Result.Add("AdditionalReportsAndDataProcessorsInSafeMode.XMLWriterToBinaryData");
	Result.Add("AdditionalReportsAndDataProcessorsInSafeMode.HTMLReadFromBinaryData");
	Result.Add("AdditionalReportsAndDataProcessorsInSafeMode.RecordHTMLToBinaryData");
	Result.Add("AdditionalReportsAndDataProcessorsInSafeMode.FastInfosetReadingFromBinaryData");
	Result.Add("AdditionalReportsAndDataProcessorsInSafeMode.RecordFastInfosetToBinaryData");
	Result.Add("AdditionalReportsAndDataProcessorsInSafeMode.CreateComObject");
	Result.Add("AdditionalReportsAndDataProcessorsInSafeMode.ConnectExternalComponentFromCommonConfigurationTemplate");
	Result.Add("AdditionalReportsAndDataProcessorsInSafeMode.ConnectExternalComponentFromConfigurationTemplate");
	Result.Add("AdditionalReportsAndDataProcessorsInSafeMode.GetFileFromExternalObject");
	Result.Add("AdditionalReportsAndDataProcessorsInSafeMode.TransferFileToExternalObject");
	Result.Add("AdditionalReportsAndDataProcessorsInSafeMode.GetFileFromInternet");
	Result.Add("AdditionalReportsAndDataProcessorsInSafeMode.ImportFileInInternet");
	Result.Add("AdditionalReportsAndDataProcessorsInSafeMode.WSConnection");
	Result.Add("AdditionalReportsAndDataProcessorsInSafeMode.PostingDocuments");
	Result.Add("AdditionalReportsAndDataProcessorsInSafeMode.WriteObjects");
	// AdditionalReportsAndDataProcessorsInSafeMode
	
	// AdditionalReportsAndDataProcessorsInSafeModeServerCall
	Result.Add("AdditionalReportsAndDataProcessorsInSafeModeServerCall.DocumentTextFromBinaryData");
	Result.Add("AdditionalReportsAndDataProcessorsInSafeModeServerCall.TextDocumentInBinaryData");
	Result.Add("AdditionalReportsAndDataProcessorsInSafeModeServerCall.SpreadsheetDocumentFormBinaryData");
	Result.Add("AdditionalReportsAndDataProcessorsInSafeModeServerCall.TabularDocumentInBinaryData");
	Result.Add("AdditionalReportsAndDataProcessorsInSafeModeServerCall.FormattedDocumentInBinaryData");
	Result.Add("AdditionalReportsAndDataProcessorsInSafeModeServerCall.BinaryDataRow");
	Result.Add("AdditionalReportsAndDataProcessorsInSafeModeServerCall.StringToBinaryData");
	Result.Add("AdditionalReportsAndDataProcessorsInSafeModeServerCall.UnpackArchive");
	Result.Add("AdditionalReportsAndDataProcessorsInSafeModeServerCall.PackFilesInArchive");
	Result.Add("AdditionalReportsAndDataProcessorsInSafeModeServerCall.ExecuteScriptInSafeMode");
	// End AdditionalReportsAndDataProcessorsInSafeModeServerCall
	
	Return New FixedArray(Result);
	
EndFunction

// Returns a dictionary of permissions additional reports and
// data processors kinds synonyms for and their parameters (for display in the user interface).
//
// Returns:
//  FixedMap:
//    Key - XDTOType corresponding
//    permission kind, Value - Structure, keys:
//      Presentation - String, brief presentation type
//      permissions, Description - String, detailed description
//      of permission kind, Parameters - ValueTable, columns:
//        Name - String, property name that
//        is defined for XDTOType, Description - String, description of the permission
//          parameter consequences for
//        the specified parameter value, AnyValueDescription - String, description of
//          the permission parameter consequences for unspecified parameter value.
//
Function Dictionary() Export
	
	Result = New Map();
	
	// {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}GetFileFromInternet
	
	Presentation = NStr("en='Receiving data from the Internet';ru='Получение данных из сети Интернет';vi='Nhận dữ liệu từ mạng Internet'");
	Definition = NStr("en='Additional report or data processor will be allowed to receive data from the Internet';ru='Дополнительному отчету или обработке будет разрешено получать данные из сети Интернет';vi='Sẽ cho phép báo cáo hoặc bộ xử lý bổ sung nhận dữ liệu từ mạng Internet'");
	
	Parameters = ParameterTable();
	AddParameter(Parameters, "Host", NStr("en='from server %1';ru='с сервера %1';vi='từ Server %1'"), NStr("en='from any server';ru='с любого сервера';vi='từ Server bất kỳ'"));
	AddParameter(Parameters, "Protocol", NStr("en='by protocol %1';ru='по протоколу %1';vi='theo giao thức %1'"), NStr("en='by any protocol';ru='по любому протоколу';vi='theo giao thức bất kỳ'"));
	AddParameter(Parameters, "Port", NStr("en='via port %1';ru='через порт %1';vi='qua cổng %1'"), NStr("en='via any port';ru='через любой порт';vi='qua cổng bất kỳ'"));
	
	Result.Insert(
		AdditionalReportsAndDataProcessorsInSafeModeInterface.GetDataTypeOfInternet(),
		New Structure(
			"Presentation,Definition,Parameters",
			Presentation,
			Definition,
			Parameters));
	
	// End {http://www.1c.ru/1CFresh/ApplicationExtensions/Permissions/a.b.c.d}GetFileFromInternet
	
	// {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}SendFileToInternet
	
	Presentation = NStr("en='Data transfer to Internet';ru='Передача данных в сеть Интернет';vi='Chuyển dữ liệu vào mạng Internet'");
	Definition = NStr("en='Additional report or data processor will be allowed to send data to the Internet';ru='Дополнительному отчету или обработке будет разрешено отправлять данные в сеть Интернет';vi='Sẽ cho phép báo cáo hoặc bộ xử lý bổ sung gửi dữ liệu đến mạng Internet'");
	Effects = NStr("en='Warning! Data sending potentially can"
"used by an additional report or data processor for"
"acts that are not alleged by administrator of infobases."
""
"Use this additional report or data processor only if you trust"
"the developer and control restriction (server, protocol and port),"
"attached to issued permissions.';ru='Внимание! Отправка данных потенциально может использоваться дополнительным"
"отчетом или обработкой для совершения действий, не предполагаемых администратором"
"информационной базы."
""
"Используйте данный дополнительный отчет или обработку только в том случае, если Вы доверяете"
"ее разработчику и контролируйте ограничения (сервер, протокол и порт), накладываемые на"
"выданные разрешения.';vi='Chú ý! Việc gửi dữ liệu có thể có khả năng sử dụng báo cáo hoặc bộ xử lý bổ sung để hoàn tất thao tác mà người quản trị cơ sở thông tin."
""
"Hãy sử dụng báo cáo hoặc bộ xử lý này chỉ trong trường hợp, nếu Bạn tin tưởng nhà phát triển và hãy kiểm soát các hạn chế (server, giao thức và cổng) được áp dụng cho giấy phép đã cấp.'");
	
	Parameters = ParameterTable();
	AddParameter(Parameters, "Host", NStr("en='via port %1';ru='через порт %1';vi='qua cổng %1'"), NStr("en='on any server';ru='на любой сервера';vi='trên Server bất kỳ'"));
	AddParameter(Parameters, "Protocol", NStr("en='by protocol %1';ru='по протоколу %1';vi='theo giao thức %1'"), NStr("en='by any protocol';ru='по любому протоколу';vi='theo giao thức bất kỳ'"));
	AddParameter(Parameters, "Port", NStr("en='via port %1';ru='через порт %1';vi='qua cổng %1'"), NStr("en='via any port';ru='через любой порт';vi='qua cổng bất kỳ'"));
	
	Result.Insert(
		AdditionalReportsAndDataProcessorsInSafeModeInterface.TypeOfTransferDataOnInternet(),
		New Structure(
			"Presentation,Definition,Effects,Parameters",
			Presentation,
			Definition,
			Effects,
			Parameters));
	
	// End {http://www.1c.ru/1CFresh/ApplicationExtensions/Permissions/a.b.c.d}SendFileToInternet
	
	// {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}SoapConnect
	
	Presentation = NStr("en='Contacting web services in Internet';ru='Обращение к веб-сервисам в сети Интернет';vi='Truy cập đến web-service trong mạng Internet'");
	Definition = NStr("en='Additional report or data processor will be allowed to refer to web services on the Internet (additional report or data processor may receive and send some information on the Internet.';ru='Дополнительному отчету или обработке будет разрешено обращаться к веб-сервисам, расположенным в сети Интернет (при этом возможно как получение дополнительным отчетом или обработкой информации из сети Интернет, так и передача.';vi='Báo cáo hoặc bộ xử lý ngoài sẽ được phép sử dụng đối với Web-service trên mạng Internet (đồng thời có thể nhận hoặc truyền thông tin từ mạng Internet thông qua báo cáo hoặc bộ xử lý bổ sung).'");
	Effects = NStr("en='Warning! Appeal to web services potentially"
"can be used by an additional report or data"
"processor for actions that are not alleged by infobases administrator."
""
"Use this additional report or data processor only if you"
"trust the developer and control restriction (connection address), attached"
"to issued permissions.';ru='Внимание! Обращение к веб-сервисам потенциально может использоваться дополнительным"
"отчетом или обработкой для совершения действий, не предполагаемых администратором"
"информационной базы."
""
"Используйте данный дополнительный отчет или обработку только в том случае, если Вы доверяете"
"ее разработчику и контролируйте ограничения (адрес подключения), накладываемые на"
"выданные разрешения.';vi='Chú ý! Việc truy cập đến dịch vụ Web có thể có khả năng sử dụng báo cáo hoặc bộ xử lý bổ sung để hoàn tất các thao tác mà người quản trị cơ sở thông tin chưa định trước."
""
"Hãy sử dụng báo cáo hoặc bộ xử lý này chỉ trong trường hợp, nếu Bạn tin tưởng nhà phát triển và hãy kiểm soát các hạn chế (địa chỉ kết nối) được áp dụng cho giấy phép đã cấp.'");
	
	Parameters = ParameterTable();
	AddParameter(Parameters, "WsdlDestination", NStr("en='at address %1';ru='по адресу %1';vi='theo địa chỉ %1'"), NStr("en='by any address';ru='по любому адресу';vi='theo địa chỉ bất kỳ'"));
	
	Result.Insert(
		AdditionalReportsAndDataProcessorsInSafeModeInterface.TypeWSConnection(),
		New Structure(
			"Presentation,Definition,Effects,Parameters",
			Presentation,
			Definition,
			Effects,
			Parameters));
	
	// End {http://www.1c.ru/1CFresh/ApplicationExtensions/Permissions/a.b.c.d}SoapConnect
	
	// {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}CreateComObject
	
	Presentation = NStr("en='Create COM object';ru='Создание COM-объекта';vi='Tạo đối tượng COM'");
	Definition = NStr("en='Additional report or data processor will be allowed to use mechanisms of external software using COM connection';ru='Дополнительному отчету или обработке будет разрешено использовать механизмы внешнего программного обеспечения с помощью COM-соединения';vi='Báo cáo hoặc bộ xử lý bổ sung sẽ được phép sử dụng cơ chế phần mềm bên ngoài thông qua kết nối COM'");
	Effects = NStr("en='Warning! Use of thirdparty software funds can"
"be used by an additional report or data processor for"
"actions that are not alleged by infobase administrator, and also for"
"unauthorized circumvention of the restrictions imposed by the additional processing in safe mode."
""
"Use this additional report or data processor only if"
"you trust the developer and control restriction (application ID),"
"attached to issued permissions.';ru='Внимание! Использование средств стороннего программного обеспечения может использоваться"
"дополнительным отчетом или обработкой для совершения действий, не предполагаемых администратором"
"информационной базы, а также для несанкционированного обхода ограничений, накладываемых на дополнительную обработку"
"в безопасном режиме."
""
"Используйте данный дополнительный отчет или обработку только в том случае, если Вы доверяете"
"ее разработчику и контролируйте ограничения (программный идентификатор), накладываемые на"
"выданные разрешения.';vi='Chú ý! Việc sử dụng công cụ phần mềm của bên thứ ba có thể sử dụng báo cáo hoặc bộ xử lý bổ sung để hoàn tất các thao tác do người quản trị cơ sở thông tin chưa được định trước, ngoài ra để bỏ qua các hạn chế không được phép đã sắp xếp vào bộ xử lý bổ sung ở chế độ an toàn."
""
"Hãy sử dụng báo cáo hoặc bộ xử lý này chỉ trong trường hợp, nếu Bạn tin tưởng nhà phát triển và hãy kiểm soát các hạn chế (tên chương trình) được áp dụng cho giấy phép đã cấp.'");
	
	Parameters = ParameterTable();
	AddParameter(Parameters, "ProgId", NStr("en='with programmatic identifier %1';ru='с программным идентификатором %1';vi='với ID (tên) chương trình %1'"), NStr("en='with any programmatic identifier';ru='с любым программным идентификатором';vi='với ID (tên) chương trình bất kỳ'"));
	
	Result.Insert(
		AdditionalReportsAndDataProcessorsInSafeModeInterface.TypeCreatingCOMObject(),
		New Structure(
			"Presentation,Definition,Effects,Parameters",
			Presentation,
			Definition,
			Effects,
			Parameters));
	
	// End {http://www.1c.ru/1CFresh/ApplicationExtensions/Permissions/a.b.c.d}CreateComObject
	
	// {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}AttachAddin
	
	Presentation = NStr("en='Create object of external component';ru='Создание объекта внешней компоненту';vi='Tạo đối tượng cho cấu phần ngoài'");
	Definition = NStr("en='Additional report or data processor  will be allowed to use mechanisms of external software by creating object of external component, which is supplied in the configuration template';ru='Дополнительному отчету или обработке будет разрешено использовать механизмы внешнего программного обеспечения с помощью создания объекта внешней компоненты, поставляемой в макете конфигурации';vi='Báo cáo hoặc bộ xử lý ngoài sẽ được phép sử dụng cơ chế phần mềm bên ngoài bằng cách tạo đối tượng cấu phần ngoài đặt trong khuôn in cấu hình'");
	Effects = NStr("en='Warning! Use of thirdparty software funds can"
"be used by an additional report or data processor for"
"actions that are not alleged by infobase administrator, and also for"
"unauthorized circumvention of the restrictions imposed by the additional processing in safe mode."
""
"Use this additional report or data processor only if you"
"trust the developer and control restriction (template name, from which connection"
"is external component), attached to issued permissions.';ru='Внимание! Использование средств стороннего программного обеспечения может использоваться"
"дополнительным отчетом или обработкой для совершения действий, не предполагаемых администратором"
"информационной базы, а также для несанкционированного обхода ограничений, накладываемых на дополнительную обработку"
"в безопасном режиме."
""
"Используйте данный дополнительный отчет или обработку только в том случае, если Вы доверяете"
"ее разработчику и контролируйте ограничения (имя макета, из которого выполняется подключение внешней"
"компоненты), накладываемые на выданные разрешения.';vi='Chú ý! Việc sử dụng công cụ phần mềm của bên thứ ba có thể sử dụng báo cáo hoặc bộ xử lý bổ sung để hoàn tất các thao tác do người quản trị cơ sở thông tin chưa được định trước, ngoài ra để bỏ qua các hạn chế không được phép đã sắp xếp vào bộ xử lý bổ sung ở chế độ an toàn."
""
"Hãy sử dụng báo cáo hoặc bộ xử lý này chỉ trong trường hợp, nếu Bạn tin tưởng nhà phát triển và hãy kiểm soát các hạn chế (tên khuôn in mà từ đó thực hiện kết nối cấu phần ngoài) được áp dụng cho giấy phép đã cấp.'");
	
	Parameters = ParameterTable();
	AddParameter(Parameters, "TemplateName", NStr("en='from template %1';ru='из макета %1';vi='từ khuôn in %1'"), NStr("en='from any template';ru='из любого макета';vi='từ khuôn in bất kỳ'"));
	
	Result.Insert(
		AdditionalReportsAndDataProcessorsInSafeModeInterface.TypeOfConnectionOfExternalComponents(),
		New Structure(
			"Presentation,Definition,Effects,Parameters",
			Presentation,
			Definition,
			Effects,
			Parameters));
	
	// End {http://www.1c.ru/1CFresh/ApplicationExtensions/Permissions/a.b.c.d}AttachAddin
	
	// {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}GetFileFromExternalSoftware
	
	Presentation = NStr("en='Receive files from external object';ru='Получение файлов из внешнего объекта';vi='Nhận tệp từ đối tượng ngoài'");
	Definition = NStr("en='Additional report or data processor will be allowed to receive files from external software (for example, using COM connection or external component)';ru='Дополнительному отчету или обработке будет разрешено получать файлы из внешнего программного обеспечения (например, с помощью COM-соединения или внешней компоненты)';vi='Báo cáo hoặc bộ xử lý ngoài sẽ được phép nhận tệp từ phần mềm bên ngoài (ví dụ, thông qua kết nối COM hoặc cấu phần ngoài)'");
	
	Result.Insert(
		AdditionalReportsAndDataProcessorsInSafeModeInterface.GetFileTypeFromExternalObject(),
		New Structure(
			"Presentation,Description",
			Presentation,
			Definition));
	
	// End {http://www.1c.ru/1CFresh/ApplicationExtensions/Permissions/a.b.c.d}GetFileFromExternalSoftware
	
	// {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}SendFileToExternalSoftware
	
	Presentation = NStr("en='File transfer to the external object';ru='Передача файлов во внешний объект';vi='Chuyển tệp vào đối tượng bên ngoài'");
	Definition = NStr("en='Additional report or data processor will be allowed to transfer files to external software (for example, using COM connection or external component)';ru='Дополнительному отчету или обработке будет разрешено передавать файлы во внешнее программное обеспечение (например, с помощью COM-соединения или внешней компоненты)';vi='Báo cáo hoặc bộ xử lý bổ sung được phép chuyển tệp vào phần mềm bên ngoài (ví dụ, thông qua kết nối COM hoặc cấu phần ngoài)'");
	
	Result.Insert(
		AdditionalReportsAndDataProcessorsInSafeModeInterface.TypeFileTransferIntoExternalObject(),
		New Structure(
			"Presentation,Description",
			Presentation,
			Definition));
	
	// End {http://www.1c.ru/1CFresh/ApplicationExtensions/Permissions/a.b.c.d}SendFileToExternalSoftware
	
	// {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}SendFileToInternet
	
	Presentation = NStr("en='Documents posting';ru='Проведение документов';vi='Kết chuyển chứng từ'");
	Definition = NStr("en='Additional report or data processor will be allowed to change document posting state';ru='Дополнительному отчету или обработке будет разрешено изменять состояние проведенности документов';vi='Sẽ cho phép báo cáo và bộ xử lý bổ sung thay đổi trạng thái kết chuyển chứng từ'");
	
	Parameters = ParameterTable();
	AddParameter(Parameters, "DocumentType", NStr("en='documents with type %1';ru='документы с типом %1';vi='chứng từ có kiểu %1'"), NStr("en='any documents';ru='любые документы';vi='chứng từ bất kỳ'"));
	AddParameter(Parameters, "Action", NStr("en='allowed action: %1';ru='разрешенное действие: %1';vi='thao tác được phép: %1'"), NStr("en='any posting state change';ru='любое изменение состояния проведения';vi='thay đổi bất kỳ trạng thái kết chuyển'"));
	
	Result.Insert(
		AdditionalReportsAndDataProcessorsInSafeModeInterface.TypePostingDocuments(),
		New Structure(
			"Presentation,Definition,Parameters,ShowToUser",
			Presentation,
			Definition,
			Parameters));
	
	// End {http://www.1c.ru/1CFresh/ApplicationExtensions/Permissions/a.b.c.d}SendFileToInternet
	
	Return Result;
	
EndFunction

#EndRegion

#Region ServiceProceduresAndFunctions

Procedure AddParameter(Val ParameterTable, Val Name, Val Definition, Val DescriptionOfAnyValue)
	
	Parameter = ParameterTable.Add();
	Parameter.Name = Name;
	Parameter.Definition = Definition;
	Parameter.DescriptionOfAnyValue = DescriptionOfAnyValue;
	
EndProcedure

Function ParameterTable()
	
	Result = New ValueTable();
	Result.Columns.Add("Name", New TypeDescription("String"));
	Result.Columns.Add("Definition", New TypeDescription("String"));
	Result.Columns.Add("DescriptionOfAnyValue", New TypeDescription("String"));
	
	Return Result;
	
EndFunction

#EndRegion
