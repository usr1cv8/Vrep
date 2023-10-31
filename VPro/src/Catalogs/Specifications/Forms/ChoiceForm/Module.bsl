
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	ProductionServer.AddSpecificationFilters(Parameters, Cancel);
	
	SetFilterInvalid(ThisObject);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Src)
	
	If EventName = "SpecificationSaved" Then
		
		ListRow = Items.List.CurrentData;
		If ListRow<>Undefined And Parameter.Ref=ListRow.Ref Then
			ShowAvailabilityOfSettingSpecificationAsBasic(Parameter.NotValid);
		EndIf; 
		
	EndIf;
	
EndProcedure

#EndRegion 

#Region FormItemEventsHandlers

&AtClient
Procedure ListOnActivateRow(Item)
	
	ShowAvailabilityOfSettingSpecificationAsBasic();
	
EndProcedure

#EndRegion 

#Region FormCommandsHandlers

&AtClient
Procedure UseAsBasic(Command)
	
	ListRow = Items.List.CurrentData;
	If ListRow=Undefined Then
		Return;
	EndIf; 
	UseAsBasicServer(ListRow.Owner, ListRow.ProductCharacteristic, ListRow.Ref);
	
EndProcedure

&AtServer
Procedure UseAsBasicServer(ProductsAndServices, Characteristic, Specification)
	
	Catalogs.Specifications.ChangeSignBasicSpecification(ProductsAndServices, Characteristic, Specification); 
	
	Items.List.Refresh();
	Items.List.CurrentRow = Specification;
	
EndProcedure

&AtClient
Procedure ShowInvalid(Command)
	
	Items.FormShowInvalid.Check = Not Items.FormShowInvalid.Check;
	
	SetFilterInvalid(ThisObject)
	
EndProcedure

#EndRegion 

#Region InternalProceduresAndFunctions

&AtServer
Procedure SetConditionalAppearance()

	NewConditionalAppearance = List.ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "NotValid", True, DataCompositionComparisonType.Equal);
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.TabularSectionUnavailableTextColor); 

EndProcedure

&AtClient
Procedure ShowAvailabilityOfSettingSpecificationAsBasic(NotValid = Undefined)
	
	If NotValid=Undefined Then
		ListRow = Items.List.CurrentData;
		If ListRow=Undefined Then
			NotValid = False;
		Else
			NotValid = ListRow.NotValid;
		EndIf; 
	EndIf; 
	CommonUseClientServer.SetFormItemProperty(Items, "FormUseAsBasic", "Enabled", Not NotValid);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetFilterInvalid(Form)
	
	CommonUseClientServer.SetFilterDynamicListItem(
		Form.List,
		"NotValid",
		False,
		,
		,
		Not Form.Items.FormShowInvalid.Check);
	
EndProcedure

#EndRegion
 
