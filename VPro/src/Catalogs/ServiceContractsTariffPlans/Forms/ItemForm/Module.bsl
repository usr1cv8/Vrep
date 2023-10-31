#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetFormConditionalAppearance();
	
	InitializeObjectTables();
	
	If Not Constants.BillingKeepExpensesAccountingByServiceContracts.Get() Then
		
		Items.Pages.PagesRepresentation = FormPagesRepresentation.None;
		Items.CostPage.Visible = False;
		
	EndIf;
	
	UnplannedCostsSetItemsVisibilityAvailability();
	UnplannedPositionsSetItemsAvailability();
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	InitializeObjectTables();
	
EndProcedure

#EndRegion

#Region FormTableEventHandlersProductsAndServicesAccounting

&AtClient
Procedure ProductsAndServicesAccountingProductsAndServicesOnChange(Item)
	
	CurrentRow = Items.ProductsAndServicesAccounting.CurrentData;
	
	StructureData = New Structure;
	StructureData.Insert("ProductsAndServices", CurrentRow.ProductsAndServices);
	If ValueIsFilled(CurrentRow.PresentationInAccount) Then
		StructureData.Insert("ProductsAndServicesInInvoice", CurrentRow.PresentationInAccount);
	Else
		StructureData.Insert("ProductsAndServicesInInvoice", CurrentRow.ProductsAndServices);
		StructureData.Insert("CharacteristicPresentation", CurrentRow.CHARACTERISTIC);
	EndIf;
	StructureData.Insert("AddPeriodToContent", CurrentRow.AddPeriodToContent);
	GetRowDataProductsAndServicesOnChange(StructureData);
	
	CurrentRow.CHARACTERISTIC    = Undefined;
	CurrentRow.IncludeInInvoice     = True;
	CurrentRow.MeasurementUnit  = StructureData.MeasurementUnit;
	CurrentRow.Quantity        = 0;
	CurrentRow.Price              = 0;
	CurrentRow.PricePresentation = PredefinedValue("Enum.BillingProductsAndServicesPricingMethod.ByContractPriceKind");
	CurrentRow.PricingMethod  = PredefinedValue("Enum.BillingProductsAndServicesPricingMethod.ByContractPriceKind");
	
	If StructureData.Property("ProductsAndServicesContentExample") Then
		CurrentRow.ProductsAndServicesContentExample = StructureData.ProductsAndServicesContentExample;
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsAndServicesAccountingIncludeInInvoiceOnChange(Item)
	
	CurrentRow = Items.ProductsAndServicesAccounting.CurrentData;
	
	CurrentRow.Quantity        = 0;
	CurrentRow.Price              = 0;
	
	If CurrentRow.IncludeInInvoice Then
		CurrentRow.PricePresentation = PredefinedValue("Enum.BillingProductsAndServicesPricingMethod.ByContractPriceKind");
		CurrentRow.PricingMethod  = PredefinedValue("Enum.BillingProductsAndServicesPricingMethod.ByContractPriceKind");
	Else
		CurrentRow.PricePresentation   = Undefined;
		CurrentRow.PricingMethod    = Undefined;
		CurrentRow.PresentationInAccount = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsAndServicesAccountingQuantityOnChange(Item)
	
	CurrentRow = Items.ProductsAndServicesAccounting.CurrentData;
	
	If CurrentRow.Quantity = 0 Then
		
		CurrentRow.Price              = 0;
		CurrentRow.PricePresentation = PredefinedValue("Enum.BillingProductsAndServicesPricingMethod.ByContractPriceKind");
		CurrentRow.PricingMethod  = PredefinedValue("Enum.BillingProductsAndServicesPricingMethod.ByContractPriceKind");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsAndServicesAccountingPricePresentationOnChange(Item)
	
	CurrentRow = Items.ProductsAndServicesAccounting.CurrentData;
	
	If TypeOf(CurrentRow.PricePresentation) = Type("EnumRef.BillingProductsAndServicesPricingMethod") Then
		CurrentRow.Price = 0;
		CurrentRow.PricingMethod = CurrentRow.PricePresentation;
	Else
		CurrentRow.Price = CurrentRow.PricePresentation;
		CurrentRow.PricingMethod = PredefinedValue("Enum.BillingProductsAndServicesPricingMethod.FixedValue");
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsAndServicesAccountingPricePresentationStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	NotifyDescription = New NotifyDescription(
		"ProductsAndServicesAccountingPricePresentationChoiceCompletion",
		ThisObject
	);
	
	Values = New ValueList;
	Values.Add(PredefinedValue("Enum.BillingProductsAndServicesPricingMethod.ByContractPriceKind"));
	Values.Add(PredefinedValue("Enum.BillingProductsAndServicesPricingMethod.FixedValue"));
	
	ShowChooseFromMenu(NotifyDescription, Values, Item);
	
EndProcedure

&AtClient
Procedure ProductsAndServicesAccountingPricePresentationChoiceCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	CurrentRow = Items.ProductsAndServicesAccounting.CurrentData;
	
	If Result.Value = PredefinedValue("Enum.BillingProductsAndServicesPricingMethod.FixedValue") Then
		CurrentRow.PricePresentation = 0;
	Else
		CurrentRow.PricePresentation = PredefinedValue("Enum.BillingProductsAndServicesPricingMethod.ByContractPriceKind");
	EndIf;
	
	CurrentRow.Price = 0;
	CurrentRow.PricingMethod = Result.Value;
	
EndProcedure

&AtClient
Procedure ProductsAndServicesAccountingPresentationInAccountOnChange(Item)
	
	CurrentRow = Items.ProductsAndServicesAccounting.CurrentData;
	
	StructureData = New Structure;
	StructureData.Insert("ProductsAndServices", CurrentRow.ProductsAndServices);
	If ValueIsFilled(CurrentRow.PresentationInAccount) Then
		StructureData.Insert("ProductsAndServicesInInvoice", CurrentRow.PresentationInAccount);
	Else
		StructureData.Insert("ProductsAndServicesInInvoice", CurrentRow.ProductsAndServices);
		StructureData.Insert("CharacteristicPresentation", CurrentRow.CHARACTERISTIC);
	EndIf;
	StructureData.Insert("AddPeriodToContent", CurrentRow.AddPeriodToContent);
	GetRowDataProductsAndServicesOnChange(StructureData);
	
	If StructureData.Property("ProductsAndServicesContentExample") Then
		CurrentRow.ProductsAndServicesContentExample = StructureData.ProductsAndServicesContentExample;
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsAndServicesAccountingAddPeriodToContentOnChange(Item)
	
	CurrentRow = Items.ProductsAndServicesAccounting.CurrentData;
	
	StructureData = New Structure;
	StructureData.Insert("ProductsAndServices", CurrentRow.ProductsAndServices);
	If ValueIsFilled(CurrentRow.PresentationInAccount) Then
		StructureData.Insert("ProductsAndServicesInInvoice", CurrentRow.PresentationInAccount);
	Else
		StructureData.Insert("ProductsAndServicesInInvoice", CurrentRow.ProductsAndServices);
		StructureData.Insert("CharacteristicPresentation", CurrentRow.CHARACTERISTIC);
	EndIf;
	StructureData.Insert("AddPeriodToContent", CurrentRow.AddPeriodToContent);
	GetRowDataProductsAndServicesOnChange(StructureData);
	
	If StructureData.Property("ProductsAndServicesContentExample") Then
		CurrentRow.ProductsAndServicesContentExample = StructureData.ProductsAndServicesContentExample;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableEventHandlersCostAccounting

&AtClient
Procedure CostAccountingCostsItemOnChange(Item)
	
	CurrentRow = Items.CostAccounting.CurrentData;
	CurrentRow.IncludeInInvoice     = True;
	CurrentRow.PricePresentation = PredefinedValue("Enum.BillingCostsPricingMethod.ByCost");
	CurrentRow.PricingMethod  = PredefinedValue("Enum.BillingCostsPricingMethod.ByCost");
	
EndProcedure

&AtClient
Procedure CostAccountingIncludeInInvoiceOnChange(Item)
	
	CurrentRow = Items.CostAccounting.CurrentData;
	
	//CurrentRow.Quantity = 0;
	CurrentRow.Price       = 0;
	CurrentRow.Discount    = 0;
	
	If CurrentRow.IncludeInInvoice Then
		CurrentRow.PricingMethod  = PredefinedValue("Enum.BillingCostsPricingMethod.ByCost");
		CurrentRow.PricePresentation = PredefinedValue("Enum.BillingCostsPricingMethod.ByCost");
	Else
		CurrentRow.PricingMethod    = Undefined;
		CurrentRow.PresentationInAccount = Undefined;
		CurrentRow.PricePresentation   = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure CostAccountingPricePresentationOnChange(Item)
	
	CurrentRow = Items.CostAccounting.CurrentData;
	
	If TypeOf(CurrentRow.PricePresentation) = Type("EnumRef.BillingCostsPricingMethod") Then
		CurrentRow.Price = 0;
		CurrentRow.PricingMethod = CurrentRow.PricePresentation;
	Else
		CurrentRow.Price = CurrentRow.PricePresentation;
		CurrentRow.Discount = 0;
		CurrentRow.PricingMethod = PredefinedValue("Enum.BillingCostsPricingMethod.FixedValue");
	EndIf;
	
EndProcedure

&AtClient
Procedure CostAccountingPricePresentationStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	NotifyDescription = New NotifyDescription(
		"CostAccountingPricePresentationChoiceCompletion",
		ThisObject
	);
	
	Values = New ValueList;
	Values.Add(PredefinedValue("Enum.BillingCostsPricingMethod.ByCost"));
	Values.Add(PredefinedValue("Enum.BillingCostsPricingMethod.ByCostWithMarkup"));
	Values.Add(PredefinedValue("Enum.BillingCostsPricingMethod.FixedValue"));
	
	ShowChooseFromMenu(NotifyDescription, Values, Item);
	
EndProcedure

&AtClient
Procedure CostAccountingPricePresentationChoiceCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	CurrentRow = Items.CostAccounting.CurrentData;
	
	If Result.Value = PredefinedValue("Enum.BillingCostsPricingMethod.ByCost")
		Or Result.Value = PredefinedValue("Enum.BillingCostsPricingMethod.ByCostWithMarkup") Then
		CurrentRow.PricePresentation = Result.Value;
	Else
		CurrentRow.PricePresentation = 0;
	EndIf;
	
	CurrentRow.Price = 0;
	CurrentRow.Discount = 0;
	CurrentRow.PricingMethod = Result.Value;
	
EndProcedure

&AtClient
Procedure CostAccountingPresentationInAccountOnChange(Item)
	
	CurrentRow = Items.CostAccounting.CurrentData;
	
	StructureData = New Structure;
	StructureData.Insert("ProductsAndServicesInInvoice", CurrentRow.PresentationInAccount);
	StructureData.Insert("AddPeriodToContent", CurrentRow.AddPeriodToContent);
	GetRowDataProductsAndServicesOnChange(StructureData);
	
	If StructureData.Property("ProductsAndServicesContentExample") Then
		CurrentRow.ProductsAndServicesContentExample = StructureData.ProductsAndServicesContentExample;
	EndIf;
	
EndProcedure

&AtClient
Procedure CostAccountingAddPeriodToContentOnChange(Item)
	
	CurrentRow = Items.CostAccounting.CurrentData;
	
	StructureData = New Structure;
	StructureData.Insert("ProductsAndServicesInInvoice", CurrentRow.PresentationInAccount);
	StructureData.Insert("AddPeriodToContent", CurrentRow.AddPeriodToContent);
	GetRowDataProductsAndServicesOnChange(StructureData);
	
	If StructureData.Property("ProductsAndServicesContentExample") Then
		CurrentRow.ProductsAndServicesContentExample = StructureData.ProductsAndServicesContentExample;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormItemEventsHandlers

&AtClient
Procedure UnplannedItemsProhibitOnChange(Item)
	
	UnplannedPositionsSetItemsAvailability();
	
EndProcedure

&AtClient
Procedure UnplannedItemsIncludeInInvoiceOnChange(Item)
	
	UnplannedPositionsSetItemsAvailability();
	
EndProcedure

&AtClient
Procedure UnplannedCostsProhibitOnChange(Item)
	
	UnplannedCostsSetItemsVisibilityAvailability();
	
EndProcedure

&AtClient
Procedure UnplannedCostsIncludeInInvoiceOnChange(Item)
	
	UnplannedCostsSetItemsVisibilityAvailability();
	
EndProcedure

&AtClient
Procedure UnplannedCostsPricingMethodOnChange(Item)
	
	UnplannedCostsSetItemsVisibilityAvailability();
	
	Object.UnplannedCostsMarkup = 0;
	Object.UnplannedCostsFixedPrice = 0;
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Procedure SetFormConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Учет номенклатуры.
	
	// 1. не включать в счет.
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	
	Filter = NewConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.ComparisonType   = DataCompositionComparisonType.Equal;
	Filter.Use  = True;
	Filter.LeftValue  = New DataCompositionField(Items.ProductsAndServicesAccountingIncludeInInvoice.DataPath);
	Filter.RightValue = False;
	
	MadeOutField                = NewConditionalAppearance.Fields.Items.Add();
	MadeOutField.Field           = New DataCompositionField(Items.ProductsAndServicesAccountingMeasurementUnit.Name);
	MadeOutField.Use  = True;
	
	MadeOutField                = NewConditionalAppearance.Fields.Items.Add();
	MadeOutField.Field           = New DataCompositionField(Items.ProductsAndServicesAccountingPricePresentation.Name);
	MadeOutField.Use  = True;
	
	MadeOutField                = NewConditionalAppearance.Fields.Items.Add();
	MadeOutField.Field           = New DataCompositionField(Items.ProductsAndServicesAccountingQuantity.Name);
	MadeOutField.Use  = True;
	
	MadeOutField                = NewConditionalAppearance.Fields.Items.Add();
	MadeOutField.Field           = New DataCompositionField(Items.ProductsAndServicesAccountingPresentationInAccount.Name);
	MadeOutField.Use  = True;
	
	Appearance = NewConditionalAppearance.Appearance.Items.Find("ReadOnly");
	Appearance.Value      = True;
	Appearance.Use = True;
	
	Appearance = NewConditionalAppearance.Appearance.Items.Find("Text");
	Appearance.Value      = NStr("en='<..>';ru='<..>';vi='<..>'");
	Appearance.Use = True;
	
	// 2. включать в счет.
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	
	Filter = NewConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.ComparisonType   = DataCompositionComparisonType.Equal;
	Filter.Use  = True;
	Filter.LeftValue  = New DataCompositionField(Items.ProductsAndServicesAccountingQuantity.DataPath);
	Filter.RightValue = 0;
	
	Filter = NewConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.ComparisonType   = DataCompositionComparisonType.Equal;
	Filter.Use  = True;
	Filter.LeftValue  = New DataCompositionField(Items.ProductsAndServicesAccountingIncludeInInvoice.DataPath);
	Filter.RightValue = True;
	
	MadeOutField                = NewConditionalAppearance.Fields.Items.Add();
	MadeOutField.Field           = New DataCompositionField(Items.ProductsAndServicesAccountingMeasurementUnit.Name);
	MadeOutField.Use  = True;
	
	MadeOutField                = NewConditionalAppearance.Fields.Items.Add();
	MadeOutField.Field           = New DataCompositionField(Items.ProductsAndServicesAccountingPricePresentation.Name);
	MadeOutField.Use  = True;
	
	Appearance = NewConditionalAppearance.Appearance.Items.Find("ReadOnly");
	Appearance.Value      = True;
	Appearance.Use = True;
	
	// 3. если выбрана фиксированная цена, то включаем отметку незаполненного.
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	
	Filter = NewConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.ComparisonType   = DataCompositionComparisonType.Equal;
	Filter.Use  = True;
	Filter.LeftValue  = New DataCompositionField(Items.ProductsAndServicesAccountingPricingMethod.DataPath);
	Filter.RightValue = Enums.BillingProductsAndServicesPricingMethod.FixedValue;
	
	Filter = NewConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.ComparisonType   = DataCompositionComparisonType.NotFilled;
	Filter.Use  = True;
	Filter.LeftValue  = New DataCompositionField(Items.ProductsAndServicesAccountingPricePresentation.DataPath);
	
	MadeOutField                = NewConditionalAppearance.Fields.Items.Add();
	MadeOutField.Field           = New DataCompositionField(Items.ProductsAndServicesAccountingPricePresentation.Name);
	MadeOutField.Use  = True;
	
	Appearance = NewConditionalAppearance.Appearance.Items.Find("MarkIncomplete");
	Appearance.Value      = True;
	Appearance.Use = True;
	
	// Учет затрат.
	
	//1. если формирование цены затрат выполняется без наценки — колонка недостуна для редактирования.
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	
	EnumValues = New ValueList;
	EnumValues.Add(Enums.BillingCostsPricingMethod.ByCost);
	EnumValues.Add(Enums.BillingCostsPricingMethod.FixedValue);
	
	Filter = NewConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.ComparisonType   = DataCompositionComparisonType.InList;
	Filter.Use  = True;
	Filter.LeftValue  = New DataCompositionField(Items.CostAccountingPricingMethod.DataPath);
	Filter.RightValue = EnumValues;
	
	MadeOutField                = NewConditionalAppearance.Fields.Items.Add();
	MadeOutField.Field           = New DataCompositionField(Items.CostAccountingDiscount.Name);
	MadeOutField.Use  = True;
	
	Appearance = NewConditionalAppearance.Appearance.Items.Find("ReadOnly");
	Appearance.Value      = True;
	Appearance.Use = True;
	
	Appearance = NewConditionalAppearance.Appearance.Items.Find("Text");
	Appearance.Value      = NStr("en='<..>';ru='<..>';vi='<..>'");
	Appearance.Use = True;
	
	// 2. если выбрана фиксированная цена, то включаем отметку незаполненного.
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	
	Filter = NewConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.ComparisonType   = DataCompositionComparisonType.Equal;
	Filter.Use  = True;
	Filter.LeftValue  = New DataCompositionField(Items.CostAccountingPricingMethod.DataPath);
	Filter.RightValue = Enums.BillingCostsPricingMethod.FixedValue;
	
	Filter = NewConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.ComparisonType   = DataCompositionComparisonType.NotFilled;
	Filter.Use  = True;
	Filter.LeftValue  = New DataCompositionField(Items.CostAccountingPricePresentation.DataPath);
	
	MadeOutField                = NewConditionalAppearance.Fields.Items.Add();
	MadeOutField.Field           = New DataCompositionField(Items.CostAccountingPricePresentation.Name);
	MadeOutField.Use  = True;
	
	Appearance = NewConditionalAppearance.Appearance.Items.Find("MarkIncomplete");
	Appearance.Value      = True;
	Appearance.Use = True;
	
EndProcedure

&AtServer
Procedure InitializeObjectTables()
	
	For Each Row In Object.ProductsAndServicesAccounting Do
		If Row.PricingMethod = Enums.BillingProductsAndServicesPricingMethod.FixedValue Then
			Row.PricePresentation = Row.Price;
		Else
			Row.PricePresentation = Row.PricingMethod;
		EndIf;
		
		If Row.AddPeriodToContent Then
			ProductsAndServicesParameters = New Structure;
			If ValueIsFilled(Row.PresentationInAccount) Then
				ProductsAndServicesParameters.Insert("ProductsAndServicesPresentation", Row.PresentationInAccount);
			Else
				ProductsAndServicesParameters.Insert("ProductsAndServicesPresentation", Row.ProductsAndServices);
				ProductsAndServicesParameters.Insert("CharacteristicPresentation", Row.CHARACTERISTIC);
			EndIf;
			
			ProductsAndServicesPresentation = PrintDocumentsCM.ProductsAndServicesPresentation(ProductsAndServicesParameters);
			Row.ProductsAndServicesContentExample = ProductsAndServicesContentWithPeriod(ProductsAndServicesPresentation);
		EndIf;
	EndDo;
	
	For Each Row In Object.CostAccounting Do
		If Row.PricingMethod = Enums.BillingCostsPricingMethod.FixedValue Then
			Row.PricePresentation = Row.Price;
		Else
			Row.PricePresentation = Row.PricingMethod;
		EndIf;
		
		If Row.AddPeriodToContent Then
			ProductsAndServicesPresentation = PrintDocumentsCM.ProductsAndServicesPresentation(
				New Structure("ProductsAndServicesPresentation", Row.PresentationInAccount));
			Row.ProductsAndServicesContentExample = ProductsAndServicesContentWithPeriod(ProductsAndServicesPresentation);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure GetRowDataProductsAndServicesOnChange(StructureData)
	
	If StructureData.Property("ProductsAndServices") Then
		ProductsAndServicesData = CommonUse.ObjectAttributesValues(
			StructureData.ProductsAndServices, "MeasurementUnit,Description,DescriptionFull");
		StructureData.Insert("MeasurementUnit", ProductsAndServicesData.MeasurementUnit);
	EndIf;
	
	If StructureData.Property("ProductsAndServicesInInvoice") And StructureData.Property("AddPeriodToContent") Then
		ProductsAndServicesParameters = New Structure;
		ProductsAndServicesParameters.Insert("ProductsAndServicesPresentation", StructureData.ProductsAndServicesInInvoice);
		If StructureData.Property("CharacteristicPresentation") Then
			ProductsAndServicesParameters.Insert("CharacteristicPresentation", StructureData.CharacteristicPresentation);
		EndIf;
		
		ProductsAndServicesPresentation = PrintDocumentsCM.ProductsAndServicesPresentation(ProductsAndServicesParameters);
		StructureData.Insert("ProductsAndServicesContentExample", 
			ProductsAndServicesContentWithPeriod(ProductsAndServicesPresentation, StructureData.AddPeriodToContent));
	EndIf;
	
EndProcedure

&AtServer
Procedure UnplannedPositionsSetItemsAvailability()
	
	If Object.UnplannedItemsProhibit Then
		
		Object.UnplannedItemsIncludeInInvoice = False;
		Object.UnplannedItemsPresentationInInvoice = Undefined;
		
		Items.UnplannedItemsIncludeInInvoice.Enabled = False;
		Items.UnplannedItemsPresentationInInvoice.Enabled = False;
		
	Else
		
		Items.UnplannedItemsIncludeInInvoice.Enabled = True;
		Items.UnplannedItemsPresentationInInvoice.Enabled = True;
		
	EndIf;
	
	If Not Object.UnplannedItemsIncludeInInvoice Then
		
		Object.UnplannedItemsPresentationInInvoice = Undefined;
		Items.UnplannedItemsPresentationInInvoice.Enabled = False;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UnplannedCostsSetItemsVisibilityAvailability()
	
	If Object.UnplannedCostsProhibit Then
		
		Object.UnplannedCostsIncludeInInvoice = False;
		Object.UnplannedCostsPresentationInInvoice = Undefined;
		Object.UnplannedCostsPricingMethod = Undefined;
		
		Items.UnplannedCostsIncludeInInvoice.Enabled = False;
		Items.UnplannedCostsPresentationInInvoice.Enabled = False;
		Items.UnplannedCostsPricingMethod.Enabled = False;
		
	Else
		
		Items.UnplannedCostsIncludeInInvoice.Enabled = True;
		Items.UnplannedCostsPresentationInInvoice.Enabled = True;
		Items.UnplannedCostsPricingMethod.Enabled = True;
		
	EndIf;
	
	If Not Object.UnplannedCostsIncludeInInvoice Then
		
		Object.UnplannedCostsPresentationInInvoice = Undefined;
		Object.UnplannedCostsPricingMethod = Undefined;
		
		Items.UnplannedCostsPresentationInInvoice.Enabled = False;
		Items.UnplannedCostsPricingMethod.Enabled = False;
		
	Else
		
		Items.UnplannedCostsPresentationInInvoice.Enabled = True;
		Items.UnplannedCostsPricingMethod.Enabled = True;
		
	EndIf;
	
	If ValueIsFilled(Object.UnplannedCostsPricingMethod) Then
		If Object.UnplannedCostsPricingMethod = Enums.BillingCostsPricingMethod.ByCost Then
			Items.UnplannedCostsMarkup.Visible = False;
			Items.UnplannedCostsFixedPrice.Visible = False;
		ElsIf Object.UnplannedCostsPricingMethod = Enums.BillingCostsPricingMethod.ByCostWithMarkup Then
			Items.UnplannedCostsMarkup.Visible = True;
			Items.UnplannedCostsFixedPrice.Visible = False;
		ElsIf Object.UnplannedCostsPricingMethod = Enums.BillingCostsPricingMethod.FixedValue Then
			Items.UnplannedCostsMarkup.Visible = False;
			Items.UnplannedCostsFixedPrice.Visible = True;
		EndIf;
	Else
		Items.UnplannedCostsMarkup.Visible = False;
		Items.UnplannedCostsFixedPrice.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Function ProductsAndServicesContentWithPeriod(ProductsAndServicesPresentation, AddPeriodToContent = True)
	
	If Not AddPeriodToContent Then
		Return "";
	EndIf;
	
	Return StrTemplate(
		NStr("en='Example: %1';ru='Пример: %1';vi='Ví dụ: %1'"),
		ProductsAndServicesInDocumentsClientServer.ProductsAndServicesContentWithPeriod(
			ProductsAndServicesPresentation, CurrentSessionDate(), Enums.BillingServiceContractPeriodicity.Month)
		);
	
EndFunction

#EndRegion
