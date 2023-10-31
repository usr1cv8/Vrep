
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Raise NStr("en='Самостоятельное использование формы не предусмотрено.';ru='Самостоятельное использование формы не предусмотрено.';vi='Tự sử dụng biểu mẫu không được xem xét'");
	
EndProcedure

#EndRegion
