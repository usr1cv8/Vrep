
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	FormParameters = New Structure("Filter", New Structure("Owner",CommandParameter));
	OpenForm("DataProcessor.WorkSchedules.Form", FormParameters, CommandExecuteParameters.Source,,CommandExecuteParameters.Window);
EndProcedure
