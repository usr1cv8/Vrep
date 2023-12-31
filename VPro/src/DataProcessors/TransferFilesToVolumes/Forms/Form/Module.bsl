
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then // Return if the form for analysis is received.
		Return;
	EndIf;
	
	VersionsInBaseNumber = GetNumberOfVersionsInDatabase();
	StorageTypeInValues = Enums.FileStorageTypes.InVolumesOnDrive;
	
	SizeInBytesOfDatabaseVersions = GetSizeOfVersionInDatabase();
	VersionsInBaseSize = SizeInBytesOfDatabaseVersions / 1048576;
	
	AdditionalParameters = New Structure;
	
	AdditionalParameters.Insert(
		"WhenYouOpenStoreFilesOnDiskVolumes",
		FileFunctionsService.StoringFilesInVolumesOnDrive());
	
	AdditionalParameters.Insert(
		"WhenYouOpenFileStorageVolume",
		FileFunctions.AreFileStorageVolumes());
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not AdditionalParameters.WhenYouOpenStoreFilesOnDiskVolumes Then
		ShowMessageBox(, NStr("en='File storage type ""In volumes on the hard disk"" is not set';ru='Не установлен тип хранения файлов ""В томах на диске""';vi='Chưa đặt kiểu lưu tệp ""Trong quyển trên đĩa""'"));
		Cancel = True;
		Return;
	EndIf;
	
	If Not AdditionalParameters.WhenYouOpenFileStorageVolume Then 
		ShowMessageBox(, NStr("en='There are no volumes to place files in';ru='Нет ни одного тома для размещения файлов';vi='Không có bất kỳ quyển nào để sắp xếp tệp'"));
		Cancel = True;
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure PerformFilesTransferToVolumes(Command)
	
	PropertyStoreFiles = PropertyStoreFiles();
	
	If PropertyStoreFiles.TypeOfFileStorage <> StorageTypeInValues Then
		ShowMessageBox(, NStr("en='File storage type ""In volumes on the hard disk"" is not set';ru='Не установлен тип хранения файлов ""В томах на диске""';vi='Chưa đặt kiểu lưu tệp ""Trong quyển trên đĩa""'"));
		Return;
	EndIf;
	
	If Not PropertyStoreFiles.AreFileStorageVolumes Then
		ShowMessageBox(, NStr("en='There are no volumes to place files in';ru='Нет ни одного тома для размещения файлов';vi='Không có bất kỳ quyển nào để sắp xếp tệp'"));
		Return;
	EndIf;
	
	If VersionsInBaseNumber = 0 Then
		ShowMessageBox(, NStr("en='There are no files in the infobase';ru='Нет ни одного файла в информационной базе';vi='Không có bất kỳ tệp nào trong cơ sở thông tin'"));
		Return;
	EndIf;
	
	QuestionText = NStr("en='Do you want to perform the files transfer in"
""
"the infobase files to the storage volumes? This operation can take a long time.';ru='Выполнить перенос файлов в информационной базе в тома хранения файлов?"
""
"Эта операция может занять продолжительное время';vi='Đang thực hiện chuyển đổi tệp trong cơ sở thông tin vào thư mục?"
""
"Thao tác này có thể mất nhiều thời gian'");
	Handler = New NotifyDescription("PerformFilesTransferToVolumesEnd", ThisObject);
	ShowQueryBox(Handler, QuestionText, QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

&AtClient
Procedure PerformFilesTransferToVolumesEnd(Response, ExecuteParameters) Export
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	Status(NStr("en='Receiving a file list...';ru='Выполняется получение списка файлов...';vi='Đang thực hiện nhận danh sách tệp...'"));
	
	VersionArray = GetArrayOfVersionsInDatabase();
	LoopNumber = 0;
	NumberOf = 0;
	
	NumberOfVersionsInPackage = 10;
	PackageVersions = New Array;
	
	FileArrayWithErrors = New Array;
	ProcessingAborted = False;
	
	For Each VersionStructure IN VersionArray Do
		
		Progress = 0;
		If VersionsInBaseNumber <> 0 Then
			Progress = LoopNumber * 100 / VersionsInBaseNumber;
		EndIf;
		
		Status(NStr("en='Transferring file to volume...';ru='Выполняется перенос файла в том...';vi='Đang thực hiện chuyển tệp sang quyển...'"), Progress, VersionStructure.Text, PictureLib.SetTime);
		
		PackageVersions.Add(VersionStructure);
		
		If PackageVersions.Count() >= NumberOfVersionsInPackage Then
			NumberOfPackage = MigrateArrayOfVersions(PackageVersions, FileArrayWithErrors);
			
			If NumberOfPackage = 0 AND PackageVersions.Count() = NumberOfVersionsInPackage Then
				ProcessingAborted = True; // Entire package could not be transferred - stop operation.
				Break;
			EndIf;	
			
			NumberOf = NumberOf + NumberOfPackage;
			PackageVersions.Clear();
			
		EndIf;	
		
		LoopNumber = LoopNumber + 1;
	EndDo;	
	
	If PackageVersions.Count() <> 0 Then
		NumberOfPackage = MigrateArrayOfVersions(PackageVersions, FileArrayWithErrors);
		
		If NumberOfPackage = 0 Then
			ProcessingAborted = True; // Entire package could not be transferred - stop operation.
		EndIf;	
		
		NumberOf = NumberOf + NumberOfPackage;
		PackageVersions.Clear();
	EndIf;	
	
	VersionsInBaseNumber = GetNumberOfVersionsInDatabase();
	SizeInBytesOfDatabaseVersions = GetSizeOfVersionInDatabase();
	VersionsInBaseSize = SizeInBytesOfDatabaseVersions / 1048576;
	
	If NumberOf <> 0 Then
		WarningText = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='Files transfer to the volumes is completed."
"Transferred files: %1';ru='Завершен перенос файлов в тома."
"Перенесено файлов: %1';vi='Đã kết thúc chuyển tệp vào quyển."
"Đã chuyển %1 tệp'"),
			NumberOf);
		ShowMessageBox(, WarningText);
	EndIf;
	
	If FileArrayWithErrors.Count() <> 0 Then
		
		Explanation = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='Number of errors on transfer: %1';ru='Количество ошибок при переносе: %1';vi='Số lượng lỗi khi chuyển: %1'"),
			FileArrayWithErrors.Count());
			
		If ProcessingAborted Then
			Explanation = NStr("en='Failed to transfer neither one file out of the package."
"Transfer aborted.';ru='Не удалось перенести ни одного файла из пакета."
"Перенос прерван.';vi='Không thể chuyển tệp nào từ bộ hồ sơ."
"Đã ngừng chuyển.'");
		EndIf;
		
		FormParameters = New Structure;
		FormParameters.Insert("Explanation", Explanation);
		FormParameters.Insert("FileArrayWithErrors", FileArrayWithErrors);
		
		OpenForm("DataProcessor.TransferFilesToVolumes.Form.ReportForm", FormParameters);
		
	EndIf;
	
	Close();
	
EndProcedure

&AtServer
Function GetSizeOfVersionInDatabase()
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	ISNULL(SUM(FileVersions.Size), 0) AS Size
		|FROM
		|	Catalog.FileVersions AS FileVersions
		|WHERE
		|	FileVersions.FileStorageType = &FileStorageType";
	Query.SetParameter("FileStorageType", Enums.FileStorageTypes.InInfobase);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return 0;
	EndIf;	
	
	Selection = Result.Select();
	Selection.Next();
	Return Selection.Size;
	
EndFunction

&AtServer
Function GetNumberOfVersionsInDatabase()
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	COUNT(*) AS Quantity
		|FROM
		|	Catalog.FileVersions AS FileVersions
		|WHERE
		|	FileVersions.FileStorageType = &FileStorageType";
	Query.SetParameter("FileStorageType", Enums.FileStorageTypes.InInfobase);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return 0;
	EndIf;	
	
	Selection = Result.Select();
	Selection.Next();
	Return Selection.Quantity;
	
EndFunction

&AtServer
Function GetArrayOfVersionsInDatabase()
	
	VersionArray = New Array;
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	FileVersions.Ref AS Ref,
		|	FileVersions.FullDescr AS FullDescr,
		|	FileVersions.Size AS Size
		|FROM
		|	Catalog.FileVersions AS FileVersions
		|WHERE
		|	FileVersions.FileStorageType = &FileStorageType";
	Query.SetParameter("FileStorageType", Enums.FileStorageTypes.InInfobase);
	
	Result = Query.Execute();
	ExportingTable = Result.Unload();
	
	For Each String IN ExportingTable Do
		VersionStructure = New Structure("Refs, Text, Size", 
			String.Ref, String.FullDescr, String.Size);
		VersionArray.Add(VersionStructure);
	EndDo;
	
	Return VersionArray;
	
EndFunction

&AtServerNoContext
Function PropertyStoreFiles()
	
	PropertyStoreFiles = New Structure;
	
	PropertyStoreFiles.Insert(
		"TypeOfFileStorage", FileFunctionsService.TypeOfFileStorage());
	
	PropertyStoreFiles.Insert(
		"AreFileStorageVolumes", FileFunctions.AreFileStorageVolumes());
	
	Return PropertyStoreFiles;
	
EndFunction

&AtServer
Function MigrateArrayOfVersions(PackageVersions, FileArrayWithErrors)
	
	SetPrivilegedMode(True);
	
	NumberProcessed = 0;
	MaximumFileSize = FileFunctions.MaximumFileSize();
	
	For Each VersionStructure IN PackageVersions Do
		
		If MoveVersion(VersionStructure, MaximumFileSize, FileArrayWithErrors) Then
			NumberProcessed = NumberProcessed + 1;
		EndIf;
		
	EndDo;
	
	Return NumberProcessed;
	
EndFunction

&AtServer
Function MoveVersion(VersionStructure, MaximumFileSize, FileArrayWithErrors)
	
	ReturnCode = True;
	
	VersionRef = VersionStructure.Ref;
	FileRef = VersionRef.Owner;
	Size = VersionStructure.Size;
	ANameForLog = "";
	
	If Size > MaximumFileSize Then
		
		ANameForLog = VersionStructure.Text;
		WriteLogEvent(NStr("en='Files.Cannot transfer the file to the volume';ru='Файлы.Ошибка переноса файла в том';vi='Tệp. Lỗi chuyển tệp vào quyển'", CommonUseClientServer.MainLanguageCode()),
			EventLogLevel.Information,, FileRef,
			StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en='When transferring to the file volume"
"""%1"""
"an error occurred:"
"""Size exceeds the maximum"".';ru='При переносе в том файла"
"""%1"""
"возникла ошибка:"
"""Размер превышает максимальный"".';vi='Khi chuyển sang quyển tệp"
"""%1"""
"đã xuất hiện lỗi:"
"""Dung lượng đã vượt quá mức tối đa"".'"),
				ANameForLog));
		
		Return False; // do not inform anything 
	EndIf;
	
	ANameForLog = VersionStructure.Text;
	WriteLogEvent(NStr("en='Files.File transfer to the volume has started';ru='Файлы.Начат перенос файла в том';vi='Tệp.Đã bắt đầu chuyển tệp vào quyển'", CommonUseClientServer.MainLanguageCode()),
		EventLogLevel.Information,, FileRef,
		StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='Start transfer to the file volume"
"""%1"".';ru='Начат перенос в"
"том файла ""%1"".';vi='Đã bắt đầu chuyển vào"
"quyển tệp ""%1"".'"),
			ANameForLog));
	
	Try
		LockDataForEdit(FileRef);
	Except
		Return False; // do not inform anything 
	EndTry;
	
	Try
		LockDataForEdit(VersionRef);
	Except
		UnlockDataForEdit(FileRef);
		Return False; // do not inform anything 
	EndTry;
	
	Try
		
		FileStorageType = CommonUse.ObjectAttributeValue(VersionRef, "FileStorageType");
		If FileStorageType <> Enums.FileStorageTypes.InInfobase Then
			// Here is a file on disk - it must not be so.
			UnlockDataForEdit(FileRef);
			UnlockDataForEdit(VersionRef);
			Return False;
		EndIf;
		
		BeginTransaction();
		
		VersionObject = VersionRef.GetObject();
		FileStorage = FileOperationsServiceServerCall.GetFileStorageFromInformationBase(VersionRef);
		FileInformation = FileFunctionsService.AddFileToVolume(FileStorage.Get(), VersionObject.ModificationDateUniversal, 
			VersionObject.FullDescr, VersionObject.Extension, VersionObject.VersionNumber,	FileRef.Encrypted, 
			// IN order not to let all files be placed in the same folder within this day - substitute the file creation date.
			VersionObject.ModificationDateUniversal);
			
		VersionObject.Volume = FileInformation.Volume;
		VersionObject.PathToFile = FileInformation.PathToFile;
		VersionObject.FileStorageType = Enums.FileStorageTypes.InVolumesOnDrive;
		VersionObject.FileStorage = New ValueStorage("");
		// To record a previously signed object.
		VersionObject.AdditionalProperties.Insert("DigitallySignedObjectRecord", True);
		VersionObject.Write();
		
		FileObject = FileRef.GetObject();
		// To record a previously signed object.
		FileObject.AdditionalProperties.Insert("DigitallySignedObjectRecord", True);
		FileObject.Write(); // For transfer the version fields in the file.
		
		FileOperationsServiceServerCall.DeleteRecordFromStoragedFileVersionsRegister(VersionRef);
		
		WriteLogEvent(
			NStr("en='Files.File transfer to the volume is completed';ru='Файлы.Завершен перенос файла в том';vi='Tệp. Đã kết thúc chuyển tệp vào quyển'", CommonUseClientServer.MainLanguageCode()),
			EventLogLevel.Information,, FileRef,
			StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en='Transfer to the file volume is completed"
"""%1"".';ru='Завершен перенос в том файла"
"""%1"".';vi='Kết thúc chuyển vào thư mục lưu"
"""%1"".'"), ANameForLog));
		
		CommitTransaction();
	Except
		ErrorInfo = ErrorInfo();
		RollbackTransaction();
		
		ErrorStructure = New Structure;
		ErrorStructure.Insert("FileName", ANameForLog);
		ErrorStructure.Insert("Error",   BriefErrorDescription(ErrorInfo));
		ErrorStructure.Insert("Version",   VersionRef);
		
		FileArrayWithErrors.Add(ErrorStructure);
		
		WriteLogEvent(NStr("en='Files.Cannot transfer the file to the volume';ru='Файлы.Ошибка переноса файла в том';vi='Tệp. Lỗi chuyển tệp vào quyển'", CommonUseClientServer.MainLanguageCode()),
			EventLogLevel.Information,, FileRef,
			StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en='When transferring to the file volume"
"""%1"""
"an error occurred:"
"""%2"".';ru='При переносе в том файла"
"""%1"""
"возникла"
"ошибка: ""%2"".';vi='Khi chuyển vào quyển của tệp"
"""%1"""
"đã xảy ra"
"lỗi: ""%2"".'"),
				ANameForLog,
				DetailErrorDescription(ErrorInfo)));
				
		ReturnCode = False;
		
	EndTry;
	
	UnlockDataForEdit(FileRef);
	UnlockDataForEdit(VersionRef);
	
	Return ReturnCode;
	
EndFunction

#EndRegion
