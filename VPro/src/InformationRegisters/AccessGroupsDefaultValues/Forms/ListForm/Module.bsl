
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then // Return if the form for analysis is received.
		Return;
	EndIf;
	
	SetConditionalAppearance();
	
	ReadOnly = True;
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure EnableEditingAbility(Command)
	
	ReadOnly = False;
	
EndProcedure

&AtClient
Procedure RefreshDataRegister(Command)
	
	HasChanges = False;
	
	RegisterDataUpdateOnServer(HasChanges);
	
	If HasChanges Then
		Text = NStr("en='Update was successful.';ru='Обновление выполнено успешно.';vi='Cập nhật thực hiện thành công.'");
	Else
		Text = NStr("en='Update is not required.';ru='Обновление не требуется.';vi='Cập nhật không cần.'");
	EndIf;
	
	ShowMessageBox(, Text);
	
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

&AtServer
Procedure RegisterDataUpdateOnServer(HasChanges)
	
	SetPrivilegedMode(True);
	
	InformationRegisters.AccessGroupsValues.RefreshDataRegister(, HasChanges);
	
	Items.List.Refresh();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	AccessValuesTypes = Metadata.DefinedTypes.AccessValue.Type.Types();
	
	For Each Type IN AccessValuesTypes Do
		
		Types = New Array;
		Types.Add(Type);
		DescriptionOfType = New TypeDescription(Types);
		TypeEmptyRef = DescriptionOfType.AdjustValue(Undefined);
		
		// Design.
		ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
		
		ItemColorsDesign = ConditionalAppearanceItem.Appearance.Items.Find("Text");
		ItemColorsDesign.Value = String(Type);
		ItemColorsDesign.Use = True;
		
		DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		DataFilterItem.LeftValue  = New DataCompositionField("List.AccessValuesType");
		DataFilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
		DataFilterItem.RightValue = TypeEmptyRef;
		DataFilterItem.Use  = True;
		
		ItemProcessedFields = ConditionalAppearanceItem.Fields.Items.Add();
		ItemProcessedFields.Field = New DataCompositionField(Items.ListAccessValuesType.Name);
		ItemProcessedFields.Use = True;
	EndDo;
	
EndProcedure

#EndRegion
