
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	AttributesTable = GetFromTempStorage(Parameters.ObjectAttributes);
	ValueToFormAttribute(AttributesTable, "ObjectAttributes");
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure ChooseCommand(Command)
	ChooseItemAndClose();
EndProcedure

&AtClient
Procedure CommandCancel(Command)
	Close();
EndProcedure

&AtClient
Procedure ObjectAttributesSelection(Item, SelectedRow, Field, StandardProcessing)
	ChooseItemAndClose();
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtClient
Procedure ChooseItemAndClose()
	SelectedRow = Items.ObjectAttributes.CurrentData;
	ChoiceParameters = New Structure;
	ChoiceParameters.Insert("Attribute", SelectedRow.Attribute);
	ChoiceParameters.Insert("Presentation", SelectedRow.Presentation);
	ChoiceParameters.Insert("ValueType", SelectedRow.ValueType);
	ChoiceParameters.Insert("ChoiceMode", SelectedRow.ChoiceMode);
	
	Notify("Properties_ObjectAttributeSelect", ChoiceParameters);
	
	Close();
EndProcedure

#EndRegion