
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then
		Return;
	EndIf;
	
	Raise NStr("en='Data processor is not intended for direct usage.';ru='Обработка не предназначена для непосредственного использования.';vi='Bộ xử lý không được dùng để sử dụng trực tiếp.'");
	
EndProcedure
