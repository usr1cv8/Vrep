
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	CallParameters = New Structure("Source, Window");
	FillPropertyValues(CallParameters, CommandExecuteParameters);
	
	CallParameters.Insert("Uniqueness", "Panel_Enterprise");
	
	ReportsVariantsClient.ShowReportsPanel("Enterprise", CallParameters, NStr("en='Company reports';ru='Отчеты по предприятию';vi='Báo cáo theo doanh nghiệp'"));
	
EndProcedure
