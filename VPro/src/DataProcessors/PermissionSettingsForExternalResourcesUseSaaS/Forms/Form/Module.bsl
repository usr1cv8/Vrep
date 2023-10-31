
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Raise NStr("en='Data processor is not for interactive use.';ru='Обработка не предназначена для интерактивного использования!';vi='Bộ xử lý không được dùng để sử dụng trực tác!'");
	
EndProcedure
