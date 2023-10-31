
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then // Return if the form for analysis is received.
		Return;
	EndIf;
	
	MarkedObjectDeletion = Parameters.MarkedObjectDeletion;
	If MarkedObjectDeletion Then
		Title = NStr("en='Cannot delete the marked objects';ru='Не удалось выполнить удаление помеченных объектов';vi='Không thể xóa đối tượng bị đánh dấu'");
		Items.ErrorMessageText.Title = NStr("en='Cannot delete selected objects as other users are using the application:';ru='Невозможно выполнить удаление помеченных объектов, т.к. в программе работают другие пользователи:';vi='Không thể xóa các đối tượng bị đánh dấu, bởi vì những người sử dụng khác đang làm việc trong chương trình.'");
	EndIf;
	
	ActiveUsersTemplate = NStr("en='Active users (%1)';ru='Активные пользователи (%1)';vi='Người sử dụng đang làm việc (%1)'");
	
	ActiveConnectionCount = InfobaseConnections.InfobaseSessionCount();
	Items.ActiveUsers.Title = StringFunctionsClientServer.
		SubstituteParametersInString(ActiveUsersTemplate, ActiveConnectionCount);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	AttachIdleHandler("RefreshActiveSessionCount", 30);
EndProcedure

#EndRegion

#Region HeaderFormItemsEventsHandlers

&AtClient
Procedure ActiveUsersClick(Item)
	
	OpenForm("DataProcessor.ActiveUsers.Form.ActiveUsersListForm", New Structure("ExclusiveModeSetupError"));
	
EndProcedure

&AtClient
Procedure ActiveUsers2Click(Item)
	
	OpenForm("DataProcessor.ActiveUsers.Form.ActiveUsersListForm");
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure CompleteSessionsAndRestartApplication(Command)
	
	Items.GroupPages.CurrentPage = Items.Page2;
	AssistantCurrentPage = "Page2";
	Items.FormRetryApplicationStart.Visible = False;
	Items.FormCompleteSessionsAndRestartApplication.Visible = False;
	
	// Setting IB lock parameters.
	RefreshActiveSessionCount();
	InstallLockOfFileBase();
	InfobaseConnectionsClient.SetIdleHandlerOfUserSessionsTermination(True);
	AttachIdleHandler("TimeOutCompleteWorkUsers", 60);
	
EndProcedure

&AtClient
Procedure CancelApplicationStart(Command)
	
	UnlockFileBase();
	
	Close(True);
	
EndProcedure

&AtClient
Procedure RetryRunApplication(Command)
	
	Close(False);
	
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

&AtClient
Procedure RefreshActiveSessionCount()
	
	Result = RefreshEnabledNumberOfActiveSessionsAtServer();
	If Result Then
		Close(False);
	EndIf;
	
EndProcedure

&AtServer
Function RefreshEnabledNumberOfActiveSessionsAtServer()
	
	If AssistantCurrentPage = "Page2" Then
		ActiveUsers = "ActiveUsers2";
	Else
		ActiveUsers = "ActiveUsers";
	EndIf;

	InfobaseSessions = GetInfobaseSessions();
	ActiveConnectionCount = InfobaseSessions.Count();
	Items[ActiveUsers].Title = StringFunctionsClientServer.
		SubstituteParametersInString(ActiveUsersTemplate, ActiveConnectionCount);
	
	QuantityOfSessionImpedingToUpdate = 0;
	For Each InfobaseSession IN InfobaseSessions Do
		
		If InfobaseSession.ApplicationName = "Designer" Then
			Continue;
		EndIf;
		
		QuantityOfSessionImpedingToUpdate = QuantityOfSessionImpedingToUpdate + 1;
	EndDo;
	
	If QuantityOfSessionImpedingToUpdate = 1 Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

&AtClient
Procedure TimeOutCompleteWorkUsers()
	
	DurationOfUsersWorkCompletion = DurationOfUsersWorkCompletion + 1;
	
	If DurationOfUsersWorkCompletion >= 3 Then
		UnlockFileBase();
		Items.GroupPages.CurrentPage = Items.Page1;
		AssistantCurrentPage = "Page1";
		Items.ErrorMessageText.Title = NStr("en='Cannot update application version as some user sessions are still active:';ru='Невозможно выполнить обновление версии программы, т.к. не удалось завершить работу пользователей:';vi='Không thể thực hiện cập nhật phiên bản chương trình vì không thể kết thúc công việc của người sử dụng:'");
		Items.FormRetryApplicationStart.Visible = True;
		Items.FormCompleteSessionsAndRestartApplication.Visible = True;
		DetachIdleHandler("TimeOutCompleteWorkUsers");
		DurationOfUsersWorkCompletion = 0;
	EndIf;
	
EndProcedure

&AtServer
Procedure InstallLockOfFileBase()
	
	Object.ProhibitUserWorkTemporarily = True;
	If MarkedObjectDeletion Then
		Object.LockBegin = CurrentSessionDate() + 2*60;
		Object.LockEnding = Object.LockBegin + 60;
		Object.MessageForUsers = NStr("en='The application is locked for deleting selected objects.';ru='Программа заблокирована для удаления помеченных объектов.';vi='Chương trình bị phong tỏa để xóa các đối tượng đã đánh dấu.'");
	Else
		Object.LockBegin = CurrentSessionDate() + 2*60;
		Object.LockEnding = Object.LockBegin + 5*60;
		Object.MessageForUsers = NStr("en='The application is locked for updating.';ru='Программа заблокирована для выполнения обновления.';vi='Chương trình bị phong tỏa để thực hiện cập nhật'");
	EndIf;
	
	Try
		FormAttributeToValue("Object").RunSetup();
	Except
		WriteLogEvent(InfobaseConnectionsClientServer.EventLogMonitorEvent(),
			EventLogLevel.Error,,, 
			DetailErrorDescription(ErrorInfo()));
		CommonUseClientServer.MessageToUser(ErrorShortInfo(ErrorDescription()), , );
	EndTry;
	
EndProcedure

&AtServer
Procedure UnlockFileBase()
	
	FormAttributeToValue("Object").Unlock();
	
EndProcedure

&AtServer
Function ErrorShortInfo(ErrorDescription)
	
	ErrorText = ErrorDescription;
	Position = Find(ErrorText, "}:");
	If Position > 0 Then
		ErrorText = TrimAll(Mid(ErrorText, Position + 2, StrLen(ErrorText)));
	EndIf;
	
	Return ErrorText;
EndFunction

#EndRegion
