
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	StructureAdvancedOptions = New Structure("FormTitle", NStr("en='How can I quickly and easily create fax signature and printing?';ru='Как быстро и просто создать факсимильную подпись и печать?';vi='Làm thế nào để tạo nhanh và đơn giản bản Fax?'"));
	
	PrintCommandParameters = New Array;
	PrintCommandParameters.Add(CommandParameter);
	
	PrintManagementClient.ExecutePrintCommand("Catalog.Companies", "PrintFaxPrintWorkAssistant", PrintCommandParameters, CommandExecuteParameters, StructureAdvancedOptions);
	
EndProcedure
