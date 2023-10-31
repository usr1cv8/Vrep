
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("ConnectionKey", ConnectionKey);
	Parameters.Property("Specification", Specification);
	
	CurrentObject = Specification.GetObject();
	If Parameters.Attributes.Count()>0 Then
		CurrentObject.AdditionalAttributes.Clear();
		For Each AdditionalAttributesData In Parameters.Attributes Do
			NewRow = CurrentObject.AdditionalAttributes.Add();
			FillPropertyValues(NewRow, AdditionalAttributesData);
		EndDo;
	EndIf; 
	PropertiesManagement.OnReadAtServer(ThisObject, CurrentObject);
	ValueToFormAttribute(CurrentObject, "Object");
	
	AdditionalParameters = PropertiesManagementOverridable.FillAdditionalParameters(Object, "AdditionalAttributesGroup");
	PropertiesManagement.OnCreateAtServer(ThisObject, AdditionalParameters);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	PropertiesManagementClient.AfterLoadAdditionalAttributes(ThisObject);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	PropertiesManagement.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

#EndRegion 

#Region FormCommandsHandlers

&AtClient
Procedure OK(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	SaveChangesServer();
	
	Result = New Structure;
	Result.Insert("ConnectionKey", ConnectionKey);
	Result.Insert("Attributes", New Array);
	For Each DescriptionString In ThisObject.Properties_AdditionalAttributesDescription Do
		StringStructure = New Structure;
		StringStructure.Insert("Property", DescriptionString.Property);
		StringStructure.Insert("Value", ThisObject[DescriptionString.AttributeNameValue]);
		Result.Attributes.Add(StringStructure);
	EndDo;
	Close(Result);
	
EndProcedure

&AtServer
Procedure SaveChangesServer()
	
	CurrentObject = FormAttributeToValue("Object");
	PropertiesManagement.BeforeWriteAtServer(ThisObject, CurrentObject);
	
EndProcedure

#EndRegion 

#Region LibrariesHandlers

&AtClient
Procedure Attachable_PropertiesRunCommand(ItemOrCommand, URL = Undefined, StandardProcessing = Undefined)
	
	PropertiesManagementClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertiesManagementClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_AdditionalAttributeOnChange(Item)
	PropertiesManagementClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

#EndRegion 

