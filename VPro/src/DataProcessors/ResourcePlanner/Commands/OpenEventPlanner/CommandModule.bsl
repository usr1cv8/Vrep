&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure("SubsystemNumber", 3);
	OpenForm("DataProcessor.ResourcePlanner.Form.PlannerForm", FormParameters, CommandExecuteParameters.Source, "ProductionScheduler", CommandExecuteParameters.Window);
	
EndProcedure
