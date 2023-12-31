#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Var ErrorMessageString Export;
Var ErrorMessageStringEL Export;

Var ErrorMessages; // mapping with the messages of the processing errors.
Var ObjectName; // metadata object name

Var ExchangeMessageTemporaryFile; // exchange message temporary file for import/export data.
Var TemporaryDirectoryOfExchangeMessages; // Temporary directory for the exchange messages.
Var InformationExchangeDirectory; // network exchange message directory

#Region ServiceProceduresAndFunctions

////////////////////////////////////////////////////////////////////////////////
// Export service procedures and functions.

// Creates a temporary directory in the temporary files directory of the operating system user.
// 
// Parameters:
//  No.
// 
//  Returns:
//   Boolean - True - managed to execute a function, False - an error occurred.
// 
Function ExecuteActionsBeforeMessageProcessing() Export
	
	MessagesInitialization();
	
	Return CreateTemporaryDirectoryOfExchangeMessages();
	
EndFunction

// Sends the exchange message to the specified resource from the temporary exchange message directory.
// 
// Parameters:
//  No.
// 
//  Returns:
//   Boolean - True - managed to execute a function, False - an error occurred.
// 
Function SendMessage() Export
	
	Result = True;
	
	MessagesInitialization();
	
	Try
		
		If UseTempDirectoryForSendingAndReceivingMessages Then
			
			Result = SendExchangeMessage();
			
		EndIf;
		
	Except
		Result = False;
	EndTry;
	
	Return Result;
	
EndFunction

// Receives an exchange message from the specified resource and puts it into the temporary exchange message directory.
// 
// Parameters:
//  No.
// 
//  Returns:
//  Boolean - True - managed to execute a function, False - an error occurred.
// 
Function GetMessage() Export
	
	MessagesInitialization();
	
	Try
		Result = GetExchangeMessage();
	Except
		Result = False;
	EndTry;
	
	Return Result;
EndFunction

// Deletes the temporary exchange message directory after executing data export or import.
// 
// Parameters:
//  No.
// 
//  Returns:
//  Boolean - True
//
Function ExecuteActionsAfterMessageProcessing() Export
	
	MessagesInitialization();
	
	If UseTempDirectoryForSendingAndReceivingMessages Then
		
		DeleteTemporaryDirectoryOfExchangeMessages();
		
	EndIf;
	
	Return True;
EndFunction

// Checking whether the specified resource contains an exchange message.
// 
// Parameters:
//  No.
// 
//  Returns:
//  Boolean - True - there is an exchange message on the specified resource; False - no.
//
Function ExchangeMessageFileExists() Export
	
	Return (FindFiles(InformationExchangeDirectoryName(), MessageFileTemplateName + ".*", False).Count() > 0);
	
EndFunction

// Initializes the data processor properties with initial values and constants.
//
// Parameters:
//  No.
// 
Procedure Initialization() Export
	
	InformationExchangeDirectory = New File(FILEInformationExchangeDirectory);
	
EndProcedure

// Checks whether the connection to the specified resource can be established.
// 
// Parameters:
//  No.
// 
//  Returns:
//  Boolean - True - connection can be established; False - no.
//
Function ConnectionIsDone() Export
	
	MessagesInitialization();
	
	If IsBlankString(FILEInformationExchangeDirectory) Then
		
		GetMessageAboutError(1);
		Return False;
		
	ElsIf Not InformationExchangeDirectory.Exist() Then
		
		GetMessageAboutError(2);
		Return False;
		
	ElsIf Not CreateVerificationFile() Then
		
		GetMessageAboutError(8);
		Return False;
		
	ElsIf Not DeleteCheckFile() Then
		
		GetMessageAboutError(9);
		Return False;
		
	EndIf;
	
	Return True;
	
EndFunction

///////////////////////////////////////////////////////////////////////////////
// Functions-properties

// Function-property: full name of the exchange message file.
//
// Returns:
//  String - full name of the exchange message file.
//
Function ExchangeMessageFileName() Export
	
	Name = "";
	
	If TypeOf(ExchangeMessageTemporaryFile) = Type("File") Then
		
		Name = ExchangeMessageTemporaryFile.FullName;
		
	EndIf;
	
	Return Name;
	
EndFunction

// Function-property: full name of the exchange message directory.
//
// Returns:
//  String - full name of the exchange message directory.
//
Function ExchangeMessageDirectoryName() Export
	
	Name = "";
	
	If TypeOf(TemporaryDirectoryOfExchangeMessages) = Type("File") Then
		
		Name = TemporaryDirectoryOfExchangeMessages.FullName;
		
	EndIf;
	
	Return Name;
	
EndFunction

// Function-property: full name of the data exchange directory (network or local resource).
//
// Returns:
//  String - full name of the data exchange directory (network or local resource).
//
Function InformationExchangeDirectoryName() Export
	
	Name = "";
	
	If TypeOf(InformationExchangeDirectory) = Type("File") Then
		
		Name = InformationExchangeDirectory.FullName;
		
	EndIf;
	
	Return Name;
	
EndFunction

// Function-property: time of the exchange message file change.
//
// Returns:
//  Date - time of the exchange message file change.
//
Function ExchangeMessageFileDate() Export
	
	Result = Undefined;
	
	If TypeOf(ExchangeMessageTemporaryFile) = Type("File") Then
		
		If ExchangeMessageTemporaryFile.Exist() Then
			
			Result = ExchangeMessageTemporaryFile.GetModificationTime();
			
		EndIf;
		
	EndIf;
	
	Return Result;
EndFunction

///////////////////////////////////////////////////////////////////////////////
// Local service procedures and functions.

Function CreateTemporaryDirectoryOfExchangeMessages()
	
	If UseTempDirectoryForSendingAndReceivingMessages Then
		
		// Create the temporary directory for the exchange messages.
		Try
			TempDirectoryName = DataExchangeServer.CreateTemporaryDirectoryOfExchangeMessages();
		Except
			GetMessageAboutError(6);
			SupplementErrorMessage(BriefErrorDescription(ErrorInfo()));
			Return False;
		EndTry;
		
		TemporaryDirectoryOfExchangeMessages = New File(TempDirectoryName);
		
	Else
		
		TemporaryDirectoryOfExchangeMessages = New File(InformationExchangeDirectoryName());
		
	EndIf;
	
	MessageFileName = CommonUseClientServer.GetFullFileName(ExchangeMessageDirectoryName(), MessageFileTemplateName + ".xml");
	
	ExchangeMessageTemporaryFile = New File(MessageFileName);
	
	Return True;
EndFunction

Function DeleteTemporaryDirectoryOfExchangeMessages()
	
	Try
		
		If Not IsBlankString(ExchangeMessageDirectoryName()) Then
			
			DeleteFiles(ExchangeMessageDirectoryName());
			
			TemporaryDirectoryOfExchangeMessages = Undefined;
			
		EndIf;
		
	Except
		Return False;
	EndTry;
	
	Return True;
EndFunction

Function SendExchangeMessage()
	
	Result = True;
	
	Extension = ?(CompressOutgoingMessageFile(), "zip", "xml");
	
	OutgoingMessageFileName = CommonUseClientServer.GetFullFileName(InformationExchangeDirectoryName(), MessageFileTemplateName + "." + Extension);
	
	If CompressOutgoingMessageFile() Then
		
		// Getting the name for the temporary archive file.
		ArchiveTempFileName = CommonUseClientServer.GetFullFileName(ExchangeMessageDirectoryName(), MessageFileTemplateName + ".zip");
		
		Try
			
			Archiver = New ZipFileWriter(ArchiveTempFileName, ExchangeMessageArchivePassword, NStr("en='Exchange message file';ru='Файл сообщения обмена';vi='Tệp thông điệp trao đổi'"));
			Archiver.Add(ExchangeMessageFileName());
			Archiver.Write();
			
		Except
			Result = False;
			GetMessageAboutError(5);
			SupplementErrorMessage(BriefErrorDescription(ErrorInfo()));
		EndTry;
		
		Archiver = Undefined;
		
		If Result Then
			
			// Copying the archive file to the data exchange directory.
			If Not RunCopyingFile(ArchiveTempFileName, OutgoingMessageFileName) Then
				Result = False;
			EndIf;
			
		EndIf;
		
	Else
		
		// Copy the message file to the data exchange directory.
		If Not RunCopyingFile(ExchangeMessageFileName(), OutgoingMessageFileName) Then
			Result = False;
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function GetExchangeMessage()
	
	ExchangeMessageFileTable = New ValueTable;
	ExchangeMessageFileTable.Columns.Add("File", New TypeDescription("File"));
	ExchangeMessageFileTable.Columns.Add("ModifiedAt");
	
	FoundFileArray = FindFiles(InformationExchangeDirectoryName(), MessageFileTemplateName + ".*", False);
	
	For Each CurrentFile IN FoundFileArray Do
		
		// Check the needed extension.
		If ((Upper(CurrentFile.Extension) <> ".ZIP")
			AND (Upper(CurrentFile.Extension) <> ".XML")) Then
			
			Continue;
			
		// Checking that it is a file, not a directory.
		ElsIf (CurrentFile.IsFile() = False) Then
			
			Continue;
			
		// Checking that the file size is greater than 0.
		ElsIf (CurrentFile.Size() = 0) Then
			
			Continue;
			
		EndIf;
		
		// File is the required exchange message; Adding the file to the table.
		TableRow = ExchangeMessageFileTable.Add();
		TableRow.File           = CurrentFile;
		TableRow.ModifiedAt = CurrentFile.GetModificationTime();
		
	EndDo;
	
	If ExchangeMessageFileTable.Count() = 0 Then
		
		GetMessageAboutError(3);
		
		MessageString = NStr("en='Data exchange directory: ""%1""';ru='Каталог обмена информацией: ""%1""';vi='Thư mục trao đổi thông tin: ""%1""'");
		MessageString = StringFunctionsClientServer.SubstituteParametersInString(MessageString, InformationExchangeDirectoryName());
		SupplementErrorMessage(MessageString);
		
		MessageString = NStr("en='Exchange message file name: ""%1"" or ""%2""';ru='Имя файла сообщения обмена: ""%1"" или ""%2""';vi='Tên tệp thông điệp trao đổi: ""%1"" hoặc ""%2""'");
		MessageString = StringFunctionsClientServer.SubstituteParametersInString(MessageString, MessageFileTemplateName + ".xml", MessageFileTemplateName + ".zip");
		SupplementErrorMessage(MessageString);
		
		Return False;
		
	Else
		
		ExchangeMessageFileTable.Sort("ModifiedAt Desc");
		
		// get the table of the "fresh" the exchange message file.
		IncomingMessageFile = ExchangeMessageFileTable[0].File;
		
		FilePacked = (Upper(IncomingMessageFile.Extension) = ".ZIP");
		
		If FilePacked Then
			
			// Getting the name for the temporary archive file.
			ArchiveTempFileName = CommonUseClientServer.GetFullFileName(ExchangeMessageDirectoryName(), MessageFileTemplateName + ".zip");
			
			// Copy the archive file from the network directory to the temporary one.
			If Not RunCopyingFile(IncomingMessageFile.FullName, ArchiveTempFileName) Then
				Return False;
			EndIf;
			
			// Unpacking the temporary archive file.
			UnpackedSuccessfully = DataExchangeServer.UnpackZIPFile(ArchiveTempFileName, ExchangeMessageDirectoryName(), ExchangeMessageArchivePassword);
			
			If Not UnpackedSuccessfully Then
				GetMessageAboutError(4);
				Return False;
			EndIf;
			
			// Check whether there is a message file.
			File = New File(ExchangeMessageFileName());
			
			If Not File.Exist() Then
				
				GetMessageAboutError(7);
				Return False;
				
			EndIf;
			
		Else
			
			// Copy the file of the incoming message from the exchange directory to the temporary files directory.
			If UseTempDirectoryForSendingAndReceivingMessages AND Not RunCopyingFile(IncomingMessageFile.FullName, ExchangeMessageFileName()) Then
				
				Return False;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return True;
EndFunction

Function CreateVerificationFile()
	
	TextDocument = New TextDocument;
	TextDocument.AddLine(NStr("en='Temporary check file';ru='Временный файл проверки';vi='Tệp kiểm tra tạm thời'"));
	
	Try
		
		TextDocument.Write(CommonUseClientServer.GetFullFileName(InformationExchangeDirectoryName(), TemporaryFlagFileName()));
		
	Except
		WriteLogEvent(DataExchangeServer.EventLogMonitorMessageTextDataExchange(), EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
		Return False;
	EndTry;
	
	Return True;
EndFunction

Function DeleteCheckFile()
	
	Try
		
		DeleteFiles(InformationExchangeDirectoryName(), TemporaryFlagFileName());
		
	Except
		WriteLogEvent(DataExchangeServer.EventLogMonitorMessageTextDataExchange(), EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
		Return False;
	EndTry;
	
	Return True;
EndFunction

Function RunCopyingFile(Val SourceFileName, Val TargetFileName)
	
	Try
		
		DeleteFiles(TargetFileName);
		FileCopy(SourceFileName, TargetFileName);
		
	Except
		
		MessageString = NStr("en='An error occurred when copying a file from %1 to %2. Error description: %3';ru='Ошибка при копировании файла из %1 в %2. Описание ошибки: %3';vi='Lỗi khi sao chép tệp từ %1 sang %2. Mô tả lỗi: %3'");
		MessageString = StringFunctionsClientServer.SubstituteParametersInString(MessageString,
							SourceFileName,
							TargetFileName,
							BriefErrorDescription(ErrorInfo()));
		SetStatusBarMessageAboutError(MessageString);
		
		Return False
		
	EndTry;
	
	Return True;
	
EndFunction

Procedure GetMessageAboutError(MessageNo)
	
	SetStatusBarMessageAboutError(ErrorMessages[MessageNo])
	
EndProcedure

Procedure SetStatusBarMessageAboutError(Val Message)
	
	If Message = Undefined Then
		Message = NStr("en='Internal error';ru='Внутренняя ошибка';vi='Lỗi bên trong'");
	EndIf;
	
	ErrorMessageString   = Message;
	ErrorMessageStringEL = ObjectName + ": " + Message;
	
EndProcedure

Procedure SupplementErrorMessage(Message)
	
	ErrorMessageStringEL = ErrorMessageStringEL + Chars.LF + Message;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////
// Functions-properties

Function CompressOutgoingMessageFile()
	
	Return FILECompressOutgoingMessageFile;
	
EndFunction

Function TemporaryFlagFileName()
	
	Return "flag.tmp";
	
EndFunction

///////////////////////////////////////////////////////////////////////////////
// Initialization

Procedure MessagesInitialization()
	
	ErrorMessageString   = "";
	ErrorMessageStringEL = "";
	
EndProcedure

Procedure ErrorMessagesInitialization()
	
	ErrorMessages = New Map;
	ErrorMessages.Insert(1, NStr("en='Connection error: Information exchange directory is not specified.';ru='Ошибка подключения: Не указан каталог обмена информацией.';vi='Lỗi kết nối: Chưa chỉ ra thư mục trao đổi thông tin.'"));
	ErrorMessages.Insert(2, NStr("en='Connection error: Information exchange directory does not exist.';ru='Ошибка подключения: Каталог обмена информацией не существует.';vi='Lỗi kết nối: Thư mục trao đổi thông tin không tồn tại.'"));
	
	ErrorMessages.Insert(3, NStr("en='Information exchange directory does not contain a message file with data.';ru='В каталоге обмена информацией не был обнаружен файл сообщения с данными.';vi='Trong thư mục trao đổi thông tin không tìm thấy tệp thông điệp trao đổi có dữ liệu.'"));
	ErrorMessages.Insert(4, NStr("en='An error occurred when unpacking a compressed message file.';ru='Ошибка при распаковке сжатого файла сообщения.';vi='Lỗi khi giải nén tệp thông báo.'"));
	ErrorMessages.Insert(5, NStr("en='An error occurred when compressing the exchange message file.';ru='Ошибка при сжатии файла сообщения обмена.';vi='Lỗi khi nén tệp thông điệp trao đổi.'"));
	ErrorMessages.Insert(6, NStr("en='An error occurred when creating a temporary directory';ru='Ошибка при создании временного каталога';vi='Lỗi khi tạo thư mục tạm thời'"));
	ErrorMessages.Insert(7, NStr("en='Archive does not include an exchange message file';ru='Архив не содержит файл сообщения обмена';vi='Nơi lưu trữ không chứa tệp thông điệp trao đổi'"));
	
	ErrorMessages.Insert(8, NStr("en='An error occurred when writing the file to the information exchange directory. Check if the user is authorized to access the directory.';ru='Ошибка записи файла в каталог обмена информацией. Проверьте права пользователя на доступ к каталогу.';vi='Lỗi ghi lại tệp vào thư mục trao đổi thông tin. Hãy kiểm tra quyền truy cập của người sử dụng đến thư mục.'"));
	ErrorMessages.Insert(9, NStr("en='An error occurred when removing a file from the information exchange directory. Check user access rights to the directory.';ru='Ошибка удаления файла из каталога обмена информацией. Проверьте права пользователя на доступ к каталогу.';vi='Lỗi xóa tệp từ thư mục trao đổi thông tin. Hãy kiểm tra quyền truy cập của người sử dụng đến thư mục.'"));
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Operators of the main application.

MessagesInitialization();
ErrorMessagesInitialization();

TemporaryDirectoryOfExchangeMessages = Undefined;
ExchangeMessageTemporaryFile    = Undefined;

ObjectName = NStr("en='Data processor: %1';ru='Обработка: %1';vi='Bộ xử lý: %1'");
ObjectName = StringFunctionsClientServer.SubstituteParametersInString(ObjectName, Metadata().Name);

#EndRegion

#EndIf
