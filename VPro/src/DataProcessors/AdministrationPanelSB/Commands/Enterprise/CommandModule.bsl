////////////////////////////////////////////////////////////////////////////////
// EVENT HANDLERS

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpenForm(
		"DataProcessor.AdministrationPanelSB.Form.SectionEnterprise",
		New Structure,
		CommandExecuteParameters.Source,
		"DataProcessor.AdministrationPanelSB.Form.SectionEnterprise" + ?(CommandExecuteParameters.Window = Undefined, ".SingleWindow", ""),
		CommandExecuteParameters.Window
	);
	
EndProcedure
