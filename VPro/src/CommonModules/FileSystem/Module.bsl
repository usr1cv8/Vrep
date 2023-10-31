///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2020, ООО 1С-Софт
// Все права защищены. Эта программа и сопроводительные материалы предоставляются 
// в соответствии с условиями лицензии Attribution 4.0 International (CC BY 4.0)
// Текст лицензии доступен по ссылке:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region ProgramInterface

#Region TemporaryFiles

////////////////////////////////////////////////////////////////////////////////
// Процедуры и функции для работы с временными файлами.

// Создает временный каталог. После окончания работы с временным каталогом его необходимо удалить 
// с помощью ФайловаяСистема.УдалитьВременныйКаталог.
//
// Parameters:
//   Extension - String - расширение каталога, которое идентифицирует назначение временного каталога
//                         и подсистему, которая его создала.
//                         Рекомендуется указывать на английском языке.
//
// Returns:
//   String - полный путь к каталогу с разделителем пути.
//
Function CreateTemporaryDirectory(Val Extension = "") Export
	
	PathToDirectory = CommonUseClientServer.AddFinalPathSeparator(GetTempFileName(Extension));
	CreateDirectory(PathToDirectory);
	Return PathToDirectory;
	
EndFunction

// Удаляет временный каталог вместе с его содержимым, если возможно.
// Если временный каталог не может быть удален (например, он занят каким-то процессом),
// то в журнал регистрации записывается соответствующее предупреждение, а процедура завершается.
//
// Для совместного использования с ФайловаяСистема.СоздатьВременныйКаталог, 
// после окончания работы с временным каталогом.
//
// Parameters:
//   Path - String - полный путь к временному каталогу.
//
Procedure DeleteTemporaryDirectory(Val Path) Export
	
	If IsTempFileName(Path) Then
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='Неверное значение параметра Путь в ФайловаяСистема.УдалитьВременныйКаталог:"
"Каталог не является временным ""%1""';ru='Неверное значение параметра Путь в ФайловаяСистема.УдалитьВременныйКаталог:"
"Каталог не является временным ""%1""';vi='Sai giá trị tham số Đường dẫn đến ФайловаяСистема.УдалитьВременныйКаталог:"
"Thư mục không phải là tạm thời ""%1""'"), 
			Path);
	EndIf;
	
	DeleteTemporaryFiles(Path);
	
EndProcedure

// Deletes a temporary file.
// Если временный файл не может быть удален (например, он занят каким-то процессом),
// то в журнал регистрации записывается соответствующее предупреждение, а процедура завершается.
//
// Для совместного использования с методом ПолучитьИмяВременногоФайла, 
// после окончания работы с временным файлом.
//
// Parameters:
//   Path - String - полный путь к временному файлу.
//
Procedure DeleteTemporaryFile(Val Path) Export
	
	If IsTempFileName(Path) Then
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='Неверное значение параметра Путь в ФайловаяСистема.УдалитьВременныйФайл:"
"Файл не является временным ""%1""';ru='Неверное значение параметра Путь в ФайловаяСистема.УдалитьВременныйФайл:"
"Файл не является временным ""%1""';vi='Sai giá trị tham số Đường dẫn đến ФайловаяСистема.УдалитьВременныйФайл:"
"Tệp không phải là tạm thời ""%1""'"), 
			Path);
	EndIf;
	
	DeleteTemporaryFiles(Path);
	
EndProcedure

#EndRegion


#EndRegion

#Region InternalProceduresAndFunctions

Procedure DeleteTemporaryFiles(Val Path)
	
	Try
		DeleteFiles(Path);
	Except
		WriteLogEvent(
			NStr("en='Стандартные подсистемы';ru='Стандартные подсистемы';vi='Phân hệ chuẩn'", CommonUseClientServer.MainLanguageCode()),
			EventLogLevel.Error,,,
			StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en='Не удалось удалить временный файл ""%1"" по причине:"
"%2';ru='Не удалось удалить временный файл ""%1"" по причине:"
"%2';vi='Không thể xóa tệp tạm thời ""%1"" do:"
"%2'"),
				Path,
				DetailErrorDescription(ErrorInfo())));
	EndTry;
	
EndProcedure

Function IsTempFileName(Path)
	
	// Ожидается, что Путь получен методом ПолучитьИмяВременногоФайла().
	// Перед проверкой разворачиваем слэши в одну сторону.
	Return Not StrStartsWith(StrReplace(Path, "/", "\"), StrReplace(TempFilesDir(), "/", "\"));
	
EndFunction


#EndRegion