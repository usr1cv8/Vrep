&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpenForm("Report.SupplierInvoiceForPaymentAnalysis.Form",
		New Structure("UsePurposeKey, Filter, GenerateOnOpen", CommandParameter, New Structure("Account", CommandParameter), True),
		,
		"Account=" + CommandParameter,
		CommandExecuteParameters.Window
	);
	
EndProcedure // CommandProcessing()
