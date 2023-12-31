////////////////////////////////////////////////////////////////////////////////
// FORM EVENT HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skipping the initialization to guarantee that the form will be received if the AutoTest parameter is passed.
	If Parameters.Property("AutoTest") Then
		Return;
	EndIf;
	
	IdeaIdentifier = Parameters.IdeaIdentifier;
	CommentIdentifier = Parameters.CommentIdentifier;
	UserID = Users.CurrentUser().ServiceUserID;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// FORM HEADER ITEM EVENT HANDLERS


////////////////////////////////////////////////////////////////////////////////
// FORM COMMAND HANDLERS

&AtClient
Procedure Add(Command)
	
	If IsBlankString(Text) Then 
		Raise NStr("en='The ""Comment"" field is required';ru='Поле комментарий должно быть заполнено';vi='Cần điền trường ghi chú'");
	EndIf;
	AddComment();
	Notify("CommentToIdeaAdded");
	Close();
	
	ShowUserNotification("en = 'Comment is added'");
	
EndProcedure


////////////////////////////////////////////////////////////////////////////////
// SERVICE PROCEDURES AND FUNCTIONS

&AtServer
Procedure AddComment()
	
	Try
		WSProxy = InformationCenterServer.GetIdeasCenterProxy();
		WSProxy.addIdeaComment(IdeaIdentifier, String(UserID), CommentIdentifier, Text);
	Except
		ErrorText = DetailErrorDescription(ErrorInfo());
		WriteLogEvent(InformationCenterServer.GetEventNameForEventLogMonitor(), 
		                         EventLogLevel.Error,
		                         ,
		                         ,ErrorText);
		OutputText = InformationCenterServer.ErrorInformationOutputTextInIdeasCenter();
		Raise OutputText;
	EndTry;
	
EndProcedure
