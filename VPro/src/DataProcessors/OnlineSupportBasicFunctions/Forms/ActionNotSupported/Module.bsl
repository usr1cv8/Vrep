
// Storing context of interaction with the service
&AtClient
Var InteractionContext Export;

#Region FormEventsHandlers

&AtClient
Procedure OnOpen(Cancel)
	
	OnlineUserSupportClient.HandleFormOpening(InteractionContext, ThisObject);
	
	If InteractionContext.Property("MessageActionsUnavailable") Then
		Items.Decoration1.Title = InteractionContext.MessageActionsUnavailable;
	Else
		Items.Decoration1.Title = NStr("en='Selected action is not available for this configuration.';ru='Выбранное действие недоступно для этой конфигурации.';vi='Thao tác đã chọn không được sử dụng cho cấu hình này.'");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure CommandOK(Command)
	
	Close();
	
EndProcedure

#EndRegion