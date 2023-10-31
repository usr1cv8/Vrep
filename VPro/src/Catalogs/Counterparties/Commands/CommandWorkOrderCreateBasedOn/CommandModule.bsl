
&AtServer
Procedure GetFillParameters(FillStructure)
	
	FillStructure.Insert("Contract", FillStructure.Counterparty.ContractByDefault);
	FillStructure.Insert("OperationKind", Enums.OperationKindsCustomerOrder.WorkOrder);
	FillStructure.Insert("IsFolder", FillStructure.Counterparty.IsFolder);
	
EndProcedure

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	If Not ValueIsFilled(CommandParameter) Then
		Return;
	EndIf;
	
	FillStructure = New Structure();
	FillStructure.Insert("Counterparty", CommandParameter);
	GetFillParameters(FillStructure);
	
	If FillStructure.IsFolder Then
		Raise NStr("en='You cannot select a counterparty group.';ru='Нельзя выбирать группу контрагентов.';vi='Không thể chọn nhóm đối tác.'");
	EndIf;
	
	OpenForm("Document.CustomerOrder.ObjectForm", New Structure("FillingValues", FillStructure));
	
EndProcedure
