
&AtClient
Procedure Connect(Command)
	
	Notification = New NotifyDescription("AfterChoosingFromMenu", ThisObject);
	UsersList = GetUsersList();
	
	If UsersList.Count() > 1 Then
		ShowChooseFromMenu(Notification, UsersList);
	Else
		OpenForm("ExchangePlan.MobileApplications.Form.ConnectionForm");
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterChoosingFromMenu(SelectedItem, Parameters) Export
	
	If SelectedItem <> Undefined AND ValueIsFilled(SelectedItem.Value) Then
		OpenForm("ExchangePlan.MobileApplications.Form.ConnectionForm", New Structure("User", SelectedItem.Value));
	EndIf;

EndProcedure

&AtServer
Function GetUsersList()
	
	SetPrivilegedMode(True);
	
	UsersList = New ValueList();
	
	Selection = Catalogs.Users.Select();
	
	While Selection.Next() Do
		If Selection.Description <> "<No set>"
			AND NOT Selection.Service
			AND NOT Selection.NotValid Then
			
			UserParameters = InfoBaseUsers.FindByUUID(Selection.InfobaseUserID);
			
			If UserParameters <> Undefined Then
				Login = UserParameters.Name;
				UsersList.Add(Login, Login,,PictureLib.User);
			EndIf;
		EndIf;
	EndDo;
	
	SetPrivilegedMode(False);
	
	Return UsersList;
	
EndFunction

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "CustomizeMobileApplicationsReady" Then
		Items.List.Refresh();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.List.ChoiceMode = Parameters.ChoiceMode;
	
EndProcedure