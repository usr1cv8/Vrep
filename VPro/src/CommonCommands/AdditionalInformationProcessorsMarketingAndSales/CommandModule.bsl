
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	AdditionalReportsAndDataProcessorsClient.OpenFormOfCommandsOfAdditionalReportsAndDataProcessors(
			CommandParameter,
			CommandExecuteParameters,
			AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindAdditionalInformationProcessor(),
			"MarketingAndSales");
	
EndProcedure
