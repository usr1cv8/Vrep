
#Region EventsHandlers
	
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	If DevicesConnected() Then
		OpenForm("ExchangePlan.MobileApplications.ListForm",
			,
			,
			CommandParameter,
			CommandExecuteParameters.Window
		);
	Else
		OpenForm("ExchangePlan.MobileApplications.Form.ConnectionForm",
			,
			,
			CommandParameter,
			CommandExecuteParameters.Window
		);
	EndIf;
	
EndProcedure

&AtServer
Function DevicesConnected()
	
	Selection = ExchangePlans.MobileApplications.Select();
	Selection.Next();
	If Selection.Next() Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

#EndRegion
