
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	CallParameters = New Structure("Source, Window");
	FillPropertyValues(CallParameters, CommandExecuteParameters);
	
	CallParameters.Insert("Uniqueness", "Panel_Services");
	
	ReportsVariantsClient.ShowReportsPanel("Services", CallParameters, NStr("en='Service reports';ru='Отчеты по сервису';vi='Báo cáo theo dịch vụ'"));
	
EndProcedure
