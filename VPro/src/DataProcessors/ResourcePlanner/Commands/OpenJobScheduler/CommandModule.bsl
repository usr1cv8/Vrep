
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure("SubsystemNumber", 1);
	OpenForm("DataProcessor.ResourcePlanner.Form.PlannerForm", FormParameters, CommandExecuteParameters.Source, "WorkScheduler", CommandExecuteParameters.Window);
	
EndProcedure
