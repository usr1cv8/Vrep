
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	If CommandExecuteParameters.Source=Undefined Then
		Return;
	EndIf;
	
	If Left(CommandExecuteParameters.Source.FormName,17) = "DocumentJournal." Then
		ParametersStructure = New Structure();
		WorkWithDocumentFormClient.AddLastFieldFilterValue(CommandExecuteParameters.Source.LabelsData, ParametersStructure, "Counterparty");
		WorkWithDocumentFormClient.AddLastFieldFilterValue(CommandExecuteParameters.Source.LabelsData, ParametersStructure, "OperationKind");
		WorkWithDocumentFormClient.AddLastFieldFilterValue(CommandExecuteParameters.Source.LabelsData, ParametersStructure, "Company");
			
		OpenForm("Document.ExpensesOnImport.ObjectForm", New Structure("FillingValues",ParametersStructure));
	EndIf; 
	
	
EndProcedure
