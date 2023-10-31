////////////////////////////////////////////////////////////////////////////////
// Процедуры и функции, предназначенные для группового изменения строк в табличной
//  части и управления оформлением панели редактирования.
////////////////////////////////////////////////////////////////////////////////

#Region ProgramInterface

Function CustomizeEditPanelAppearance(ThisForm, SetElements, State, Value, ModifiesData = Undefined, ChoiceParameterLinks = Undefined) Export
	
	If State = 2 And SetElements.Action = PredefinedValue("Enum.BulkRowChangeActions.DeleteRows") Then
		SetElements.ValueItem.Visible = False;
		State = 3;
	EndIf;
	
	SetChoiceParameterLinks = Undefined;
	If State = 0 Then
		
		// 0. Панель скрыта
		If ValueIsFilled(ModifiesData) And ModifiesData Then
			ThisForm.Modified = True;
		EndIf;
		
		SetElements.EditPanel.Visible = False;
		SetElements.ColumnMark.Visible = False;
		SetElements.ColumnLineNumber.Visible = True;
		
	ElsIf State = 1 Then
		
		// 1. Выбор действия
		SetElements.ColumnMark.Visible = True;
		SetElements.ColumnLineNumber.Visible = False;
		SetElements.EditPanel.Visible = True;
		
		Value = SetElements.ValueItem.TypeRestriction.AdjustValue("");
		
	ElsIf State = 2 Then
		
		// 2. Выбор значения
		If SetElements.Action <> PredefinedValue("Enum.BulkRowChangeActions.DeleteRows") Then
			SetElements.ValueItem.Visible = True;
		EndIf;
		
		SetChoiceParameterLinks = False;
		BulkRowChangeClientServer.SetActionPresentation(SetElements, SetChoiceParameterLinks);
		
		Value = SetElements.ValueItem.TypeRestriction.AdjustValue("");
		
		If SetElements.Action = PredefinedValue("Enum.BulkRowChangeActions.CreateProductsAndServicesBatches")
			Then
			Value = SetElements.Value
		Else
			Value = SetElements.ValueItem.TypeRestriction.AdjustValue("");
		EndIf;
		
		// Курсор на ввод значения
		ThisForm.CurrentItem = SetElements.ValueItem;
		
	ElsIf State = 3 Then
		
		// 3. Осталось нажать на кнопку "Выполнить"
		// Курсор на кнопке выполнить
		ThisForm.CurrentItem = SetElements.ButtonExecuteAction;
		
	ElsIf State = 4 Then
		
		// 4. Представление изменений
		// Сдвиг табличной части на измененную колонку
		If ValueIsFilled(SetElements.ChangingObject) Then
			ThisForm.CurrentItem = SetElements.ColumnChangingObject;
		EndIf;
		
	EndIf;
	
	Result = New Structure;
	If SetChoiceParameterLinks <> Undefined And SetChoiceParameterLinks Then
		Result.Insert("SetChoiceParameterLinks", SetChoiceParameterLinks);
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Procedure RowMarkOnChange(Table, ItemSetMarkups, UnmarkItem) Export
	
	If Table.FindRows(New Structure("Check", True)).Count() = 0 Then
		ItemSetMarkups.Visible = True;
		UnmarkItem.Visible = False;
	Else
		ItemSetMarkups.Visible = False;
		UnmarkItem.Visible = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearActionValue(Action, Value) Export
	
	Action = PredefinedValue("Enum.BulkRowChangeActions.EmptyRef");
	Value = "";
	
EndProcedure

// Получает строковое представление действия.
//
// Parameters:
//  ActionEnum - EnumRef.BulkRowChangeActions - Действие, описание которого необходимо получить.
// Returns:
//  String - Представление действия.
Function ActionPresentation(ActionEnum) Export
	
	ActionPresentation = String(ActionEnum);
	Return Left(ActionPresentation, StrFind(ActionPresentation, "@") - 1);
	
EndFunction


#EndRegion