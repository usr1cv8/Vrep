
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then // Return if the form for analysis is received.
		Return;
	EndIf;
	
	BigFiles = Parameters.BigFiles;
	
	MaximumFileSize = Int(FileFunctions.MaximumFileSize() / (1024 * 1024));
	
	Message =
	StringFunctionsClientServer.SubstituteParametersInString(
	    NStr("en='Some of the files exceed the size limit (%1 Mb) and will not be added to storage."
"Continue import?';ru='Некоторые файлы превышают предельный размер (%1 Мб) и не будут добавлены в хранилище."
"Продолжить импорт?';vi='Nhiều tệp vượt quá dung lượng tối đa (%1 Mb) và không thể thêm vào kho chứa."
"Tiếp tục kết nhập?'"),
	    String(MaximumFileSize) );
		
	If Parameters.Property("Title") Then
		Title = Parameters.Title;
	EndIf;
	
EndProcedure

#EndRegion
