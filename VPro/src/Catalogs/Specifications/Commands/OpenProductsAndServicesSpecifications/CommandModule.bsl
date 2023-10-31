
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	Filter 			= New Structure("ProductsAndServices", CommandParameter);
	FormParameters	= New Structure("Filter", Filter);
	
	OpenForm("Catalog.Specifications.Form.FormProductsAndServicesSpecification", FormParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);
	
EndProcedure
