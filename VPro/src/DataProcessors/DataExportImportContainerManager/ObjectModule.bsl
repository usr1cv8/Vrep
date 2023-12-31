#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

//
Var ForExport;
Var ForImport;
//
Var ContainerInitialized;
Var RootDirectory;
Var DirectoriesStructure;
Var Content;
//
Var Parameters;


////////////////////////////////////////////////////////////////////////////////
// EXPORT

// Initializes export.
//
// Parameters:
// ExportDirectory - String - export directory path.
//
Procedure InitializeExport(Val ExportDirectory, Val ExportParameters) Export
	
	CheckContainerInitialization(True);
	
	ExportDirectory = TrimAll(ExportDirectory);
	If Right(ExportDirectory, 1) = "\" Then
		RootDirectory = ExportDirectory;
	Else
		RootDirectory = ExportDirectory + "\";
	EndIf;
	
	Parameters = ExportParameters;
	
	ForExport = True;
	ContainerInitialized = True;
	
EndProcedure

Function ExportParameters() Export
	
	CheckContainerInitialization();
	
	If ForExport Then
		Return New FixedStructure(Parameters);
	Else
		Raise NStr("en='The container is not initialized for data export.';ru='Контейнер не инициализирован для выгрузки данных!';vi='Chưa khởi tạo container để kết xuất dữ liệu!'");
	EndIf;
	
EndFunction

Procedure SetExportParameters(ExportParameters) Export
	
	Parameters = ExportParameters;
	
EndProcedure

// Creates a file in the export directory.
//
// Parameters:
// FileKind - String - export file kind.
// DataType - String - data type.
//
// Returns:
// String - attachment file name.
//
Function CreateFile(Val FileKind, Val DataType = Undefined) Export
	
	CheckContainerInitialization();
	
	Return AddFile(FileKind, "xml", DataType);
	
EndFunction

// Creates an arbitrary export file.
//
// Parameters:
// Extension - String - file extension.
// DataType - String - data type.
//
// Returns:
// String - attachment file name.
//
Function CreateRandomFile(Val Extension, Val DataType = Undefined) Export
	
	CheckContainerInitialization();
	
	Return AddFile(DataExportImportService.CustomData(), Extension, DataType);
	
EndFunction

Procedure SetObjectsQuantity(Val FullPathToFile, Val ObjectsCount = Undefined) Export
	
	CheckContainerInitialization();
	
	Filter = New Structure;
	Filter.Insert("DescriptionFull", FullPathToFile);
	FilesInSet = Content.FindRows(Filter);
	If FilesInSet.Count() = 0 Or FilesInSet.Count() > 1 Then 
		Raise NStr("en='File is not found';ru='Файл не найден';vi='Chưa tìm thấy tệp'");
	EndIf;
	
	FilesInSet[0].ObjectsCount = ObjectsCount;
	
EndProcedure

Procedure DeleteFile(Val FullPathToFile) Export
	
	CheckContainerInitialization();
	
	ContentRow = Content.Find(FullPathToFile, "DescriptionFull");
	If ContentRow = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='File %1 was not found in the container.';ru='Файл %1 не найден в составе контейнера!';vi='Chưa tìm thấy tệp %1 trong thành phần nội dung!'"), FullPathToFile);
	Else
		
		Content.Delete(ContentRow);
		DeleteFiles(FullPathToFile);
		
	EndIf;
	
EndProcedure

Procedure ReplaceFile(Val NameInContainer, Val FullPathToFile, Val DeleteReplacementFileFromDisk = False) Export
	
	CheckContainerInitialization();
	
	SourceFileRow = Content.Find(NameInContainer, "Name");
	If SourceFileRow = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='File with ID %1 was not found in the container.';ru='Файл с идентификатором %1 не найден в составе контейнера!';vi='Chưa tìm thấy tệp có tên %1 trong thành phần nội dung!'"), NameInContainer);
	Else
		
		SourceFileName = SourceFileRow.DescriptionFull;
		MoveFile(FullPathToFile, SourceFileName);
		
		If DeleteReplacementFileFromDisk Then
			DeleteFiles(FullPathToFile);
		EndIf;
		
	EndIf;
	
EndProcedure

// Finishes exporting. Writes information on exporting to the file.
//
Procedure FinishExport() Export
	
	CheckContainerInitialization();
	
	UpdateImportedFilesContent();
	FileName = CreateFile(DataExportImportService.PackageContents());
	WriteContainerContentToFile(FileName);
	
EndProcedure

Procedure UpdateImportedFilesContent()
	
	For Each CurrentFile IN Content Do 
		
		File = New File(CurrentFile.DescriptionFull);
		If Not File.Exist() Then 
			Raise NStr("en='The file was deleted';ru='Файл был удален';vi='Chưa xóa tệp'");
		EndIf;
		
		CurrentFile.Size = File.Size();
		CurrentFile.Hash    = CalculateHash(File.DescriptionFull);
		
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Import

// Initializes import.
//
// Parameters:
// ImportingDirectory - String - import directory path.
//
Procedure InitializeImport(Val ImportingDirectory, Val ImportParameters) Export
	
	CheckContainerInitialization(True);
	
	ImportingDirectory = TrimAll(ImportingDirectory);
	If Right(ImportingDirectory, 1) = "\" Then
		RootDirectory = ImportingDirectory;
	Else
		RootDirectory = ImportingDirectory + "\";
	EndIf;
	
	ContentFileName = ImportingDirectory + GetFileName(DataExportImportService.PackageContents());
	
	ContentFile = New File(ContentFileName);
	If Not ContentFile.Exist() Then
		
		Raise NStr("en='An error occurred while importing the data. Incorrect file format. File PackageContents.xml is not found in the archive."
"The file might have been received from previous versions or corrupted.';ru='Ошибка загрузки данных. Неверный формат файла. В архиве не обнаржен файл PackageContents.xml."
"Возможно, файл был получен из предыдущих версий программы или поврежден!';vi='Lỗi kết nhập dữ liệu. Sai định dạng tệp. Trong phần lưu trữ, chưa tìm thấy tệp PackageContents.xml."
"Có thể, đã nhận tệp từ các phiên bản trước của chương trình hoặc tệp bị hư hỏng!'");
		
	EndIf;
	
	ReadStream = New XMLReader();
	ReadStream.OpenFile(ContentFileName);
	ReadStream.MoveToContent();
	
	If ReadStream.NodeType <> XMLNodeType.StartElement
			Or ReadStream.Name <> "Data" Then
		
		Raise ServiceTechnologyIntegrationWithSSL.SubstituteParametersInString(
			NStr("en='XML reading error. Invalid file format. Awaiting %1 item start.';ru='Ошибка чтения XML. Неверный формат файла. Ожидается начало элемента %1.';vi='Lỗi đọc XML. Sai định dạng tệp. Đang chờ bắt đầu phần tử %1.'"),
			"Data"
		);
		
	EndIf;
	
	If Not ReadStream.Read() Then
		Raise NStr("en='XML reading error. File end is detected.';ru='Ошибка чтения XML. Обнаружено завершение файла.';vi='Lỗi đọc XML. Tìm thấy sự kết thúc tệp.'");
	EndIf;
	
	While ReadStream.NodeType = XMLNodeType.StartElement Do
		
		ContainerItem = XDTOFactory.ReadXML(ReadStream, XDTOFactory.Type("http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1", "File"));
		ReadContainerItem(ContainerItem);
		
	EndDo;
	
	ReadStream.Close();
	
	For Each Item IN Content Do
		Item.DescriptionFull = ImportingDirectory + Item.Folder + "\" + Item.Name;
	EndDo;
	
	Parameters = ImportParameters;
	
	ForImport = True;
	ContainerInitialized = True;
	
EndProcedure

Function ImportParameters() Export
	
	CheckContainerInitialization();
	
	If ForImport Then
		Return New FixedStructure(Parameters);
	Else
		Raise NStr("en='The container is not initialized for data import.';ru='Контейнер не инициализирован для загрузки данных!';vi='Chưa khởi tạo container để kết nhập dữ liệu!'");
	EndIf;
	
EndFunction

Procedure SetImportParameters(ImportParameters) Export
	
	Parameters = ImportParameters;
	
EndProcedure

// Gets a file from the directory.
//
// Parameters:
// FileKind - String - export file kind.
// DataType - String - data type.
//
// Returns:
// ValueTableRow - see Content value table
//
Function GetFileFromDirectory(Val FileKind, Val DataType = Undefined) Export
	
	CheckContainerInitialization();
	
	Files = GetFilesFromSet(FileKind, DataType);
	If Files.Count() = 0 Then
		Return Undefined;
	ElsIf Files.Count() > 1 Then
		Raise NStr("en='Export contains duplicate information';ru='В выгрузке содержится дублирующаяся информация';vi='Khi kết xuất có thông tin bị lặp'");
	EndIf;
	
	Return Files[0].DescriptionFull;
	
EndFunction

// Gets an arbitrary file from the directory.
//
// Parameters:
// DataType - String - data type.
//
// Returns:
// ValueTableRow - see Content value table
//
Function GetRandomFile(Val DataType = Undefined) Export
	
	CheckContainerInitialization();
	
	Files = GetFilesFromSet(DataExportImportService.CustomData() , DataType);
	If Files.Count() = 0 Then
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='There is no arbitrary file with data type %1 in export.';ru='В выгрузке отсутствует произвольный файл с типом данным %1!';vi='Khi kết xuất thiếu tệp tùy ý có kiểu dữ liệu %1!'"),
			DataType
		);
	ElsIf Files.Count() > 1 Then
		Raise NStr("en='Export contains duplicate information';ru='В выгрузке содержится дублирующаяся информация';vi='Khi kết xuất có thông tin bị lặp'");
	EndIf;
	
	Return Files[0].DescriptionFull;
	
EndFunction

Function GetFilesFromDirectory(Val FileKind, Val DataType = Undefined) Export
	
	CheckContainerInitialization();
	
	Return GetFileDescriptionsFromDirectory(FileKind, DataType).UnloadColumn("DescriptionFull");
	
EndFunction

Function GetFileDescriptionsFromDirectory(Val FileKind, Val DataType = Undefined) Export
	
	CheckContainerInitialization();
	
	FileTable = Undefined;
	
	If TypeOf(FileKind) = Type("Array") Then 
		
		For Each SeparateType IN FileKind Do
			AddFilesToValuesTable(FileTable, GetFilesFromSet(SeparateType , DataType));
		EndDo;
		Return FileTable;
		
	ElsIf TypeOf(FileKind) = Type("String") Then 
		
		Return GetFilesFromSet(FileKind, DataType);
		
	Else
		
		Raise NStr("en='Unknown file type';ru='Неизвестный вид файла';vi='Kiểu tệp chưa xác định'");
		
	EndIf;
	
EndFunction

Function GetArbitraryFiles(Val DataType = Undefined) Export
	
	CheckContainerInitialization();
	
	Return GetArbitraryFilesDescriptions(DataType).UnloadColumn("DescriptionFull");
	
EndFunction

Function GetArbitraryFilesDescriptions(Val DataType = Undefined) Export
	
	CheckContainerInitialization();
	
	Return GetFilesFromSet(DataExportImportService.CustomData(), DataType);
	
EndFunction

Procedure AddFilesToValuesTable(FileTable, Val FilesFromSet)
	
	If FileTable = Undefined Then 
		FileTable = FilesFromSet;
		Return;
	EndIf;
	
	ServiceTechnologyIntegrationWithSSL.SupplementTable(FilesFromSet, FileTable);
	
EndProcedure

Function GetFullFileName(Val RelativeFileName) Export
	
	CheckContainerInitialization();
	
	ContentRow = Content.Find(RelativeFileName, "Name");
	
	If ContentRow = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='There is no file with relative name %1 in the container.';ru='В контейнере не обнаружен файл с относительным именем %1!';vi='Trong container chưa tìm thấy tệp có tên tương ứng %1!'"),
			RelativeFileName
		);
	Else
		Return ContentRow.DescriptionFull;
	EndIf;
	
EndFunction

Function GetRelativeFileName(Val FullFileName) Export
	
	CheckContainerInitialization();
	
	ContentRow = Content.Find(FullFileName, "DescriptionFull");
	
	If ContentRow = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='There is no file %1 in the container.';ru='В контейнере не обнаружен файл %1!';vi='Trong container chưa tìm thấy tệp %1!'"),
			FullFileName
		);
	Else
		Return ContentRow.Name;
	EndIf;
	
EndFunction

Procedure FinishImport() Export
	
	CheckContainerInitialization();
	
EndProcedure

Function GetFilesFromSet(Val FileKind = Undefined, Val DataType = Undefined)
	
	Filter = New Structure;
	If FileKind <> Undefined Then
		Filter.Insert("FileKind", FileKind);
	EndIf;
	If DataType <> Undefined Then
		Filter.Insert("DataType", DataType);
	EndIf;
	
	Return Content.Copy(Filter);
	
EndFunction

//

Procedure CheckContainerInitialization(Val WhenInitializing = False)
	
	If ForExport AND ForImport Then
		Raise NStr("en='Incorrect container initialization';ru='Некорректная инициализация контейнера!';vi='Khởi tạo sai container!'");
	EndIf;
	
	If WhenInitializing Then
		
		If ContainerInitialized <> Undefined AND ContainerInitialized Then
			Raise NStr("en='Export container has already been initialized.';ru='Контейнер выгрузки уже был инициализирован ранее!';vi='Đã khởi tạo container kết xuất từ trước!'");
		EndIf;
		
	Else
		
		If Not ContainerInitialized Then
			Raise NStr("en='Export container is not initialized.';ru='Контейнер выгрузки не инициализирован!';vi='Chưa khởi tạo container kết xuất!'");
		EndIf;
		
	EndIf;
	
EndProcedure

// Work with files inside a container.

Function AddFile(Val FileKind, Val Extension = "xml", Val DataType = Undefined)
	
	FileName = GetFileName(FileKind, Extension, DataType);
	
	DirectoryByFileType = GetDirectoryToLocateFile(FileKind);
	If IsBlankString(DirectoryByFileType) Then
		
		DescriptionFull = RootDirectory + FileName;
		
	Else
		
		NumberedDirectory = GetNumberedDirectory(FileKind, DirectoryByFileType);
		DescriptionFull = RootDirectory + NumberedDirectory + "\" + FileName;
		
	EndIf;
	
	File = Content.Add();
	File.Name = FileName;
	File.Directory = NumberedDirectory;
	File.DescriptionFull = DescriptionFull;
	File.DataType = DataType;
	File.FileKind = FileKind;
	
	Return DescriptionFull;
	
EndFunction

Function GetFileName(Val FileKind, Val Extension = "xml", Val DataType = Undefined)
	
	If FileKind = DataExportImportService.DumpInfo() Then
		FileName = DataExportImportService.DumpInfo();
	ElsIf FileKind = DataExportImportService.PackageContents() Then
		FileName = DataExportImportService.PackageContents();
	ElsIf FileKind = DataExportImportService.Users() Then
		FileName = DataExportImportService.Users();
	Else
		FileName = String(New UUID);
	EndIf;
	
	FileName = FileName + "." + Extension;
	
	Return FileName;
	
EndFunction

// Work with the directory structure

Function GetDirectoryToLocateFile(Val FileKind)
	
	Rules = DataExportImportService.DirectoriesStructureCreationRules();
	If Rules.Property(FileKind) Then
		
		Subdirectory = Rules[FileKind];
		If IsBlankString(Subdirectory) Then
			
			Return "";
			
		Else
			
			// Checks if the the data type directory exists
			If Not DirectoriesStructure.Property(FileKind) Then
				CreateDirectory(RootDirectory + Subdirectory);
				DirectoriesStructure.Insert(FileKind, 1);
			EndIf;
			
			Return Subdirectory;
			
		EndIf;
		
	Else
		Raise ServiceTechnologyIntegrationWithSSL.SubstituteParametersInString(
			NStr("en='The %1 file kind is not supported.';ru='Вид файла %1 не поддерживается!';vi='Không hỗ trợ dạng tệp %1!'"), FileKind);
	EndIf;
		
EndFunction

Function GetNumberedDirectory(Val FileKind, Val Subdirectory)
	
	FilesCount = Content.Copy(New Structure("FileKind", FileKind), "Name").Count();
	
	MaxFilesCountInDirectory = 1000;
	If FilesCount >= MaxFilesCountInDirectory 
		AND FilesCount % MaxFilesCountInDirectory = 0 Then
		
			DirectoryDigit = DirectoriesStructure[FileKind] + 1;
			DirectoryName = RootDirectory + Subdirectory + Format(DirectoryDigit, "NG=0");
			DirectoryWithFiles = New File(DirectoryName);
			DirectoriesStructure[FileKind] = DirectoryDigit;
			CreateDirectory(DirectoryName);
		
	EndIf;
	
	NumberedDirectory = ?(DirectoriesStructure[FileKind] = 1, "", Format(DirectoriesStructure[FileKind], "NG=0"));
	
	Return Subdirectory + NumberedDirectory;
	
EndFunction

// Work with the container content description.

Procedure WriteContainerContentToFile(FileName)
	
	Rules = ContainerContentSerializationRules();
	
	WriteStream = New XMLWriter();
	WriteStream.OpenFile(FileName);
	WriteStream.WriteXMLDeclaration();
	WriteStream.WriteStartElement("Data");
	
	FileType = XDTOFactory.Type("http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1", "File");
	For Each String IN Content Do
		
		FileData = XDTOFactory.Create(FileType);
		
		For Each Rule IN Rules Do
			
			If ValueIsFilled(String[Rule.ObjectField]) Then
				FileData[Rule.XDTOObjectField] = String[Rule.ObjectField];
			EndIf;
			
		EndDo;
		
		XDTOFactory.WriteXML(WriteStream, FileData);
		
	EndDo;
	
	WriteStream.WriteEndElement();
	WriteStream.Close();
	
EndProcedure

Procedure ReadContainerItem(Val ContainerItemDescription)
	
	Rules = ContainerContentSerializationRules();
	
	File = Content.Add();
	For Each Rule IN Rules Do
		File[Rule.ObjectField] = ContainerItemDescription[Rule.XDTOObjectField]
	EndDo;
	
EndProcedure

Function ContainerContentSerializationRules()
	
	Rules = New ValueTable();
	Rules.Columns.Add("ObjectField", New TypeDescription("String"));
	Rules.Columns.Add("XDTOObjectField", New TypeDescription("String"));
	
	AddRuleSerializeContentsOfContainer(Rules, "Name", "Name");
	AddRuleSerializeContentsOfContainer(Rules, "Folder", "Directory");
	AddRuleSerializeContentsOfContainer(Rules, "Size", "Size");
	AddRuleSerializeContentsOfContainer(Rules, "FileKind", "Type");
	AddRuleSerializeContentsOfContainer(Rules, "Hash", "Hash");
	AddRuleSerializeContentsOfContainer(Rules, "ObjectsCount", "Count");
	AddRuleSerializeContentsOfContainer(Rules, "DataType", "DataType");
	
	Return Rules;
	
EndFunction

Procedure AddRuleSerializeContentsOfContainer(Rules, Val ObjectField, Val XDTOObjectField)
	
	Rule = Rules.Add();
	Rule.ObjectField = ObjectField;
	Rule.XDTOObjectField = XDTOObjectField;
	
EndProcedure

Function CalculateHash(Val PathToFile)
	
	Try
		SetSafeMode(True);
		FunctionMD5 = Eval("HashFunction.MD5");
		SetSafeMode(False);
	Except
		Return "";
	EndTry;
	
	TypeParameters = New Array;
	TypeParameters.Add(FunctionMD5);
	
	TypeName = "DataHashing";
	DataHashing = New(TypeName, TypeParameters);
	DataHashing.AddFile(PathToFile);
	Return MD5VString(DataHashing.HashSum);
	
EndFunction

Function MD5VString(Val BinaryData)
	
	Value = XDTOFactory.Create(XDTOFactory.Type("http://www.w3.org/2001/XMLSchema", "hexBinary"), BinaryData);
	Return Value.LexicalMeaning;
	
EndFunction


// Initializes a default state container

AdditionalProperties = New Structure();

DirectoriesStructure = New Structure();

ForExport = False;
ForImport = False;

NumberedFolders = New Map();

Content = New ValueTable;
Content.Columns.Add("Name", New TypeDescription("String"));
Content.Columns.Add("Folder", New TypeDescription("String"));
Content.Columns.Add("DescriptionFull", New TypeDescription("String"));
Content.Columns.Add("Size", New TypeDescription("Number"));
Content.Columns.Add("FileKind", New TypeDescription("String"));
Content.Columns.Add("Hash", New TypeDescription("String"));
Content.Columns.Add("ObjectsCount", New TypeDescription("Number"));
Content.Columns.Add("DataType", New TypeDescription("String"));

Content.Indexes.Add("FileKind, DataType");
Content.Indexes.Add("FileKind");
Content.Indexes.Add("DescriptionFull");
Content.Indexes.Add("Folder");

#EndIf