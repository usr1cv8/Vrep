#Region FormEventsHandlers

&AtClient
Procedure OnOpen(Cancel)
	Cancel = True;
	ShowMessageBox(, NStr("en='Data processor is not intended for direct usage.';ru='Обработка не предназначена для непосредственного использования.';vi='Bộ xử lý không được dùng để sử dụng trực tiếp.'"));
EndProcedure

#EndRegion