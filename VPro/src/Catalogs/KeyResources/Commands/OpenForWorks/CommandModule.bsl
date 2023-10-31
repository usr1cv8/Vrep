
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	FormParameters = New Structure();
	OpenForm("Catalog.KeyResources.ListForm", FormParameters, CommandExecuteParameters.Source, "WorkScheduler", CommandExecuteParameters.Window);
EndProcedure
