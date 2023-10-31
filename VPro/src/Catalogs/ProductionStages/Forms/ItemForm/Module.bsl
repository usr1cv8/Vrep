
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetupConditionalAppearance();
	
EndProcedure

#EndRegion

#Region FormItemEventsHandlers

&AtClient
Procedure StructuralUnitsOnStartEdit(Item, NewRow, Clone)
	
	CurrentRow = Items.StructuralUnits.CurrentData;
	If NewRow And Object.StructuralUnits.Count()=1 Then
		CurrentRow.Default = True;
	EndIf; 
	
EndProcedure

&AtClient
Procedure StructuralUnitsChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	If ТипЗнч(SelectedValue)=Тип("Массив") Then
		StructuralUnitsArray = SelectedValue;
	Else
		StructuralUnitsArray = CommonUseClientServer.ValueInArray(SelectedValue);
	EndIf;
	
	For Each StructuralUnit In StructuralUnitsArray Do
		
		If TypeOf(StructuralUnit)<>Тип("CatalogRef.StructuralUnits") Or Not ValueIsFilled(StructuralUnit) Then
			Return;
		EndIf; 
		
		Filter = New Structure;
		Filter.Insert("StructuralUnit", StructuralUnit);
		If Object.StructuralUnits.FindRows(Filter).Count()=0 Then
			NewRow = Object.StructuralUnits.Add();
			NewRow.StructuralUnit = StructuralUnit;
			NewRow.Default = (Object.StructuralUnits.Количество()=1);
			Modified = True;
		EndIf; 
		
	EndDo;
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure Select(Command)
	
	FormParameters = Новый Структура;
	FormParameters.Insert("ChoiceMode", True);
	FormParameters.Insert("CloseOnChoice", False);
	FormParameters.Insert("Filter", Новый Структура);
	FormParameters.Filter.Insert("StructuralUnitType", PredefinedValue("Enum.StructuralUnitsTypes.Department"));
	OpenForm("Справочник.StructuralUnits.ChoiceForm", FormParameters, Items.StructuralUnits, , , , , FormWindowOpeningMode.LockOwnerWindow);	
	
EndProcedure

&AtClient
Procedure UseAsDefault(Command)
	
	CurrentRow = Items.StructuralUnits.CurrentData;
	CurrentRow.Default = NOT CurrentRow.Default;
	If CurrentRow.Default Then
		Для каждого TabularSectionRow Из Object.StructuralUnits Цикл
			If CurrentRow=TabularSectionRow ИЛИ NOT TabularSectionRow.Default Then
				Продолжить;
			EndIf; 
			TabularSectionRow.Default = False;
		КонецЦикла; 
	EndIf; 
	
EndProcedure

#EndRegion

#Region ServiceMethods

&AtServer
Procedure SetupConditionalAppearance()
	
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "StructuralUnitsStructuralUnit");
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.StructuralUnits.Default", True);
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Font", Новый Шрифт(Новый Шрифт, , , True));
	
EndProcedure

#EndRegion
 
