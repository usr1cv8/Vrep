
////////////////////////////////////////////////////////////////////////////////
// FORM EVENT HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then // Return if the form for analysis is received.
		Return;
	EndIf;
	
	MessagePattern = NStr("en='You can not view the information on the %1 user as "
"this is a service account which is provided for the service administrators.';ru='Просмотр сведений о пользователе %1 не доступен, т.к. это "
"служебная учетная запись, предусмотренная для администраторов сервиса.';vi='Xem thông tin theo người sử dụng %1 không sử dụng được, bởi vì đây là"
"trương mục Email hệ thống dự tính đối với người quản trị dịch vụ.'");
	Items.SharedUser.Title = 
		StringFunctionsClientServer.SubstituteParametersInString(MessagePattern, Parameters.Key.Description);
	
EndProcedure
