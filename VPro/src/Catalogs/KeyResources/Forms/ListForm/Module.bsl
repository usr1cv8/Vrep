
&AtClient
Procedure UpdateResourcesList()
	
	CurRow = Items.ListResourcesKinds.CurrentData;
	
	If CurRow <> Undefined Then
		ResourcesList.Parameters.SetParameterValue("CurrentResourceKind", CurRow.Ref);
	Else
		ResourcesList.Parameters.SetParameterValue("CurrentResourceKind", PredefinedValue("Catalog.EnterpriseResourcesKinds.AllResources"));
	EndIf;
	
EndProcedure

&AtClient
Procedure ListResourcesKindsOnActivateRow(Item)
	
	UpdateResourcesList();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Record_EnterpriseResourcesKinds" Then
		
		UpdateResourcesList();
		
	EndIf;
	
EndProcedure
