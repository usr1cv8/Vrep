
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FilterField = New DataCompositionField("NotValid");
	
	НовыйОтбор = List.Filter.Items.Add(Type("DataCompositionFilterItem"));
	НовыйОтбор.Use = True;
	НовыйОтбор.LeftValue = FilterField;
	НовыйОтбор.RightValue = False;
	НовыйОтбор.ComparisonType = DataCompositionComparisonType.Equal;
	
	SetConditionalAppearance();
	
EndProcedure

&AtClient
Procedure ShowInvalid(Command)
	
	FilterField = New DataCompositionField("NotValid");
	FoundItem = Undefined;
	
	For Each FilterItem In List.Filter.Items Do
		
		If TypeOf(FilterItem) = Type("DataCompositionFilterItemGroup")
			Then
			Continue;
		EndIf;
		
		If FilterItem.LeftValue = FilterField
			Then
			FoundItem = FilterItem;
			Break
		EndIf;
	EndDo;
	
	If FoundItem = Undefined
		Then
		Return;
	EndIf;
	
	НовыйОтбор = FoundItem;
	НовыйОтбор.Use = Not НовыйОтбор.Use;

EndProcedure

&AtServer
Procedure SetConditionalAppearance()

		NewConditionalAppearance = ConditionalAppearance.Items.Add();
		WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "List.NotValid", True, DataCompositionComparisonType.Equal);
		WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "Description");
		WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.TabularSectionUnavailableTextColor); 

EndProcedure

&AtClient
Procedure ListValueChoice(Item, Value, StandardProcessing)
	
	CurrentData = Items.List.CurrentData;
	If CurrentData = Undefined Then 
		StandardProcessing = False;
		Return 
	EndIf;
	
	If CurrentData.IsFolder Then
		StandardProcessing = False;
		Return 
	EndIf;
	
EndProcedure

