
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ProductionDate = CurrentDate();
	ProductionDateBefore = ProductionDate;
	PlaningDate = ProductionDate;
	PlaningDateBefore = PlaningDate;
		
	RestoreFilterSettings();
	
	UseTechnicalOperation = GetFunctionalOption("UseTechOperations");
	UseStructuralUnits = GetFunctionalOption("AccountingBySeveralDepartments");
	UseWarehouses = GetFunctionalOption("AccountingBySeveralWarehouses");
	PerformByDifferentDepartments = GetFunctionalOption("PerformStagesByDifferentDepartments");
	
	Items.OrdersStructuralUnit.Visible = UseStructuralUnits;
	If Not UseTechnicalOperation Then
		Items.ProductionDate.Title = NStr("En='null';vi='không'");
	EndIf;
	
	ShowDescription = CommonUse.FormDataSettingsStorageImport("ПроизводствоЗаСмену", "ПоказатьОписаниеПриОткрытии", True);
	If ShowDescription Then
		Items.Pages.CurrentPage = Items.DescriptionPanel;
		Items.PerfomStages.Enabled = False;
		Items.GroupCollapseExpand.Enabled = False;
		CommonUse.FormDataSettingsStorageSave("ПроизводствоЗаСмену", "ПоказатьОписаниеПриОткрытии", False);
	EndIf; 
	
	FillOrderTree();
	
	FormManagment(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ОбновитьЗаголовок();
	
	If Not ShowDescription Then
		ExpandOrderTree(); 
	EndIf; 
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
		
	If Not Exit Then
		//УНФ.ОтборыСписка
		SaveFilterSettings();
		//Конец УНФ.ОтборыСписка
	EndIf; 

EndProcedure

#EndRegion

#Region FormItemsEventsHadlers

&AtClient
Procedure Attachable_StageMarkOnchange(Item)
	
	Modified = True;
	
	StageNumber = StrReplace(Item.Name, "OrdersStageLabel", "");
	
	CurrentRow = Items.Orders.CurrentData;
	OnChangeStageMark(CurrentRow, StageNumber);
	
EndProcedure

&AtClient
Procedure OrdersStructuralUnitAutoComplete(Item, Text, ChoiceData, DataGetParameters, Wait, StandardProcessing)
	
	If Wait=0 Then
		
		CurrentRow = Items.Orders.CurrentData;
		SelectionData = ПодразделенияПоЭтапу(PredefinedValue("Справочник.ProductionStages.ProductionComplete"));
		StandardProcessing = (SelectionData.Count()=0);
		
	EndIf; 
	
EndProcedure

&AtClient
Procedure Attachable_StageStructuralUnitAutoComplete(Item, Text, SelectionData, GetingDataParameters, Waiting, StandardProcessing)
	
	If Waiting=0 Then
		
		StageNumber = StrReplace(Item.Name, "OrdersStageStructuralUnit", "");
		CurrentRow = Items.Orders.CurrentData;
		SelectionData = ПодразделенияПоЭтапу(CurrentRow["Stage" + StageNumber]);
		StandardProcessing = (SelectionData.Count()=0);
		
	EndIf; 
	
EndProcedure

&AtClient
Procedure OrdersStructuralUnitOnChange(Item)
	
	CurrentRow = Items.Orders.CurrentData;
	StructuralUnitOnChange(CurrentRow);
	
EndProcedure

&AtClient
Procedure StructuralUnitOnChange(CurrentRow)
	
	If CurrentRow.Level=1 Then
		If Not PerformByDifferentDepartments Then
			For ii = 1 To StagesQuantity Do
				CurrentRow["StructuralUnit" + ii] = CurrentRow.StructuralUnit;
			EndDo; 
		EndIf; 
		For Each SubString In CurrentRow.GetItems() Do
			If SubString.ЕстьНедоступныеЭтапы Or SubString.ЕстьСохраненныеДокументы Then
				Continue;
			EndIf; 
			SubString.StructuralUnit = CurrentRow.StructuralUnit;
			If Not PerformByDifferentDepartments Then
				For ii = 1 To StagesQuantity Do
					SubString["StructuralUnit" + ii] = SubString.StructuralUnit;
				EndDo; 
			EndIf; 
		EndDo;
		CurrentRow.StructuralUnit = EqualValue(CurrentRow, "StructuralUnit");
	ElsIf CurrentRow.Level=2 Then
		ParentRow = CurrentRow.GetParent();
		ParentRow.StructuralUnit = EqualValue(ParentRow, "StructuralUnit");
		If Not PerformByDifferentDepartments Then
			For ii = 1 To StagesQuantity Do
				CurrentRow["StructuralUnit" + ii] = CurrentRow.StructuralUnit;
				ParentRow["StructuralUnit" + ii] = EqualValue(ParentRow, "StructuralUnit", ii);
			EndDo; 
		EndIf; 
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_StageStructuralUnitOnChange(Item)
	
	Modified = True;
	StageNumber = StrReplace(Item.Name, "OrdersStageStructuralUnit", "");
	CurrentRow = Items.Orders.CurrentData;
	OnChangeStageStructuralUnit(CurrentRow, StageNumber);
	
EndProcedure

&AtClient
Procedure OnChangeStageStructuralUnit(CurrentRow, StageNumber)
	
	If CurrentRow.Level=1 Then
		For Each SubString In CurrentRow.GetItems() Do
			If SubString["StageDisable" + StageNumber] Or SubString["StageHide" + StageNumber] Then
				Continue;
			EndIf; 
			SubString["StructuralUnit" + StageNumber] = CurrentRow["StructuralUnit" + StageNumber];
		EndDo;
	ElsIf CurrentRow.Level=2 Then
		ParentRow = CurrentRow.GetParent();
		ParentRow["StructuralUnit" + StageNumber] = EqualValue(ParentRow, "StructuralUnit", StageNumber);
	EndIf; 	
	
EndProcedure

&AtClient
Procedure Attachable_StagePerfomerOnchange(Item)
	
	Modified = True;
	StageNumber = StrReplace(Item.Name, "OrdersStagePerformer", "");
	CurrentRow = Items.Orders.CurrentData;
	OnChangeStagePerfomer(CurrentRow, StageNumber);
	
EndProcedure

&AtClient
Procedure OnChangeStagePerfomer(CurrentRow, StageNumber)
	
	If CurrentRow.Level=1 Then
		For Each SubString In CurrentRow.GetItems() Do
			If SubString["StageDisable" + StageNumber] 
				Or SubString["StageHide" + StageNumber]
				Or SubString["PerformerHide" + StageNumber]
				Or Not SubString["ChoosePerformer" + StageNumber]
				Then
				Continue;
			EndIf; 
			SubString["Performer" + StageNumber] = CurrentRow["Performer" + StageNumber];
		EndDo;
	ElsIf CurrentRow.Level=2 Then
		ParentRow = CurrentRow.GetParent();
		ParentRow["Performer" + StageNumber] = EqualValue(ParentRow, "Performer", StageNumber);
	EndIf; 	
	
EndProcedure

&AtClient
Procedure OrdersSelection(Item, SelectedRow, Field, StandardProcessing)
	
	CurrentRow = Items.Orders.CurrentData;
	If CurrentRow.Level=2 Then
		RowOrder = CurrentRow.GetParent();
	Else
		RowOrder = CurrentRow;
	EndIf; 
	
	If Find(Field.Name, "OrdersStageTitle")>0 Then
		
		Modified = True;
		
		StageNumber = StrReplace(Field.Name, "OrdersStageTitle", "");
		
		If CurrentRow["StageDisable" + StageNumber] Then
			Return;
		EndIf; 
		
		CurrentRow["StageLabel" + StageNumber] = Not CurrentRow["StageLabel" + StageNumber];
		OnChangeStageMark(CurrentRow, StageNumber);
		
	ElsIf Find(Field.Name, "OrdersStageInventoryAssemblyDescription")>0 Then 
		
		StageNumber = StrReplace(Field.Name, "OrdersStageInventoryAssemblyDescription", "");
		If ValueIsFilled(CurrentRow["InventoryAssembly" + StageNumber]) Then
			ShowValue(, CurrentRow["InventoryAssembly" + StageNumber]);
		ElsIf Not IsBlankString(CurrentRow["InventoryAssemblyDescription" + StageNumber]) Then
			DocumentList = DocumentsByStage(
			CurrentRow.ProductsAndServices,
			CurrentRow.Characteristic,
			CurrentRow.Batch,
			CurrentRow.Specification,
			?(ValueIsFilled(RowOrder.CustomerOrder), RowOrder.CustomerOrder, RowOrder.ProductionOrder),
			CurrentRow["Stage" + StageNumber],
			"InventoryAssembly");
			Notification = New NotifyDescription("OrdersSelectCompleting", ThisObject);
			ShowChooseFromMenu(Notification, DocumentList, Item);
		EndIf; 
		
	ElsIf Find(Field.Name, "OrdersStageJobSheetDescription")>0 Then 
		
		StageNumber = StrReplace(Field.Name, "OrdersStageJobSheetDescription", "");
		If ValueIsFilled(CurrentRow["JobSheet" + StageNumber]) Then
			ShowValue(, CurrentRow["JobSheet" + StageNumber]);
		ElsIf Not IsBlankString(CurrentRow["JobSheetDescription" + StageNumber]) Then 
			DocumentList = DocumentsByStage(
			CurrentRow.ProductsAndServices,
			CurrentRow.Characteristic,
			CurrentRow.Batch,
			CurrentRow.Specification,
			?(ValueIsFilled(RowOrder.CustomerOrder), RowOrder.CustomerOrder, RowOrder.ProductionOrder),
			CurrentRow["Stage" + StageNumber],
			"JobSheet");
			Notification = New NotifyDescription("OrdersSelectCompleting", ThisObject);
			ShowChooseFromMenu(Notification, DocumentList, Item);
		EndIf;
		
	ElsIf Field.Name="OrdersDescription" And CurrentRow.Level=1 Then
		
		StandardProcessing = False;
		If ValueIsFilled(CurrentRow.ProductionOrder) Then
			ShowValue(, CurrentRow.ProductionOrder);
		Else
			ShowValue(, CurrentRow.CustomerOrder);
		EndIf; 
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OrdersSelectCompleting(SelectedValue, AdditionalParameters) Export
	
	If TypeOf(SelectedValue)<>Type("ValueListItem") Then
		Return;
	EndIf;
	
	ShowValue(, SelectedValue.Value);
	
EndProcedure

&AtClient
Procedure OnChangeStageMark(CurrentRow, StageNumber)
	
	UndoPreviousStages(CurrentRow, StageNumber);
	UndoNextStages(CurrentRow, StageNumber);
	If CurrentRow.Level=1 Then
		For Each SubString In CurrentRow.GetItems() Do
			SubString["StageLabel" + StageNumber] = CurrentRow["StageLabel" + StageNumber];
			UndoPreviousStages(SubString, StageNumber);
			UndoNextStages(SubString, StageNumber);
			SetupDefaultStructuralUnit(SubString, StageNumber);
		EndDo;
	ElsIf CurrentRow.Level=2 Then
		UpdateParent(CurrentRow, StageNumber);
		SetupDefaultStructuralUnit(CurrentRow, StageNumber);
	EndIf; 	
	
EndProcedure

&AtClient
Procedure UpdateParent(CurrentRow, StageNumber)
	
	If CurrentRow.Level <> 2 Then
		Return;
	EndIf; 
	
	If CurrentRow["StageDisable" + StageNumber] Or CurrentRow["StageHide" + StageNumber] Then
		Return;
	EndIf;
	
	RowOrder = CurrentRow.GetParent();
	
	If RowOrder["StageDisable" + StageNumber] Or RowOrder["StageHide" + StageNumber] Then
		Return;
	EndIf; 
	
	If Not CurrentRow["StageLabel" + StageNumber] And RowOrder["StageLabel" + StageNumber] Then
		RowOrder["StageLabel" + StageNumber] = False;
	ElsIf CurrentRow["StageLabel" + StageNumber] And Not RowOrder["StageLabel" + StageNumber] Then 
		RowOrder["StageLabel" + StageNumber] = EqualValue(RowOrder, "StageLabel", StageNumber);
	EndIf;
	UpdateComplitingMark(RowOrder);
	
EndProcedure

&AtClient
Procedure UndoPreviousStages(CurrentRow, StageNumber)
	
	If Not CurrentRow["StageLabel" + StageNumber] Then
		Return;
	EndIf; 
	
	For ii = 1 To Number(StageNumber) - 1 Do
		If CurrentRow["StageDisable" + ii] Or CurrentRow["StageHide" + ii] Then
			Continue;
		EndIf;
		CurrentRow["StageLabel" + ii] = CurrentRow["StageLabel" + StageNumber];
		SetupDefaultStructuralUnit(CurrentRow, ii);
		UpdateParent(CurrentRow, ii);
	EndDo;
	
	UpdateComplitingMark(CurrentRow);
	
EndProcedure

&AtClient
Procedure UndoNextStages(CurrentRow, StageNumber)
	
	If CurrentRow["StageLabel" + StageNumber] Then
		Return;
	EndIf; 
	
	For ii = Number(StageNumber) + 1 To StagesQuantity Do
		If CurrentRow["StageDisable" + ii] Or CurrentRow["StageHide" + ii] Then
			Continue;
		EndIf;
		CurrentRow["StageLabel" + ii] = CurrentRow["StageLabel" + StageNumber];
		UpdateParent(CurrentRow, ii);
	EndDo; 
	
	UpdateComplitingMark(CurrentRow);
	
EndProcedure

&AtClient
Procedure UpdateComplitingMark(CurrentRow)
	
	CurrentRow.IsPerformedStages = False;
	CurrentRow.IsSavedDocuments = False;
	CurrentRow.IsUnavailableStages = False;
	For ii = 1 To StagesQuantity Do
		If CurrentRow["StageLabel" + ii] Then
			CurrentRow.IsPerformedStages = True;
		EndIf; 
		If CurrentRow["StageLabelOld" + ii] Then
			CurrentRow.IsSavedDocuments = True;
		EndIf; 
		If CurrentRow["StageDisable" + ii] Then
			CurrentRow.IsUnavailableStages = True;
		EndIf; 
	EndDo; 	
	
EndProcedure

&AtClient
Procedure SetupDefaultStructuralUnit(CurrentRow, StageNumber)
	
	If Not PerformByDifferentDepartments Then
		Return;
	EndIf; 
	
	If CurrentRow.Level<>2 Then
		Return;
	EndIf; 
	
	If CurrentRow["StageLabel" + StageNumber] And Not ValueIsFilled(CurrentRow["StructuralUnit" + StageNumber]) Then
		DepartmentList = ПодразделенияПоЭтапу(CurrentRow["Stage" + StageNumber]);
		MainStructuralUnit = Undefined;
		For Each ListElement In DepartmentList Do
			If ListElement.Check Then
				MainStructuralUnit = ListElement.Value;
			EndIf; 
		EndDo;
		CurrentRow["StructuralUnit" + StageNumber] = MainStructuralUnit;
		If CurrentRow.Level=2 Then
			ParentRow = CurrentRow.GetParent();
			ParentRow["StructuralUnit" + StageNumber] = EqualValue(ParentRow, "StructuralUnit", StageNumber);
		EndIf; 
	EndIf;
	
	If CurrentRow.IsPerformedStages And Not CurrentRow.IsUnavailableStages And Not ValueIsFilled(CurrentRow.StructuralUnit) Then
		DepartmentList = ПодразделенияПоЭтапу(PredefinedValue("Справочник.ProductionStages.ProductionComplete"));
		MainStructuralUnit = Undefined;
		For Each ListElement In DepartmentList Do
			If ListElement.Check Then
				MainStructuralUnit = ListElement.Value;
			EndIf; 
		EndDo;
		CurrentRow.StructuralUnit = MainStructuralUnit;
		If CurrentRow.Level=2 Then
			ParentRow = CurrentRow.GetParent();
			ParentRow.StructuralUnit = EqualValue(ParentRow, "StructuralUnit");
		EndIf; 
	EndIf;
	
	If CurrentRow["Stage" + StageNumber]=PredefinedValue("Справочник.ProductionStages.ProductionComplete")
		And ValueIsFilled(CurrentRow.StructuralUnit) Then
		CurrentRow["StructuralUnit" + StageNumber] = CurrentRow.StructuralUnit;
		If CurrentRow.Level=2 Then
			ParentRow = CurrentRow.GetParent();
			ParentRow["StructuralUnit" + StageNumber] = EqualValue(ParentRow, "StructuralUnit", StageNumber);
		EndIf; 
	EndIf; 
	
EndProcedure

&AtClient
Procedure DescriptionOnClick(Item, EventData, StandardProcessing)
	
	StandardProcessing = False;
	If TypeOf(EventData)<>Type("FixedStructure") Or Not EventData.Property("Href") Then
		Return;
	EndIf; 
	
	If Find(EventData.Href, "Update")>0 Then
		ShowDescription = False;
		FillOrderTreeClient();
		FormManagment(ThisObject);
	ElsIf Find(EventData.Href, "DepartmentList")>0 Then
		FilterStructure = New Structure("StructuralUnitType", PredefinedValue("Enum.StructuralUnitsTypes.Department"));
		FormParameters = New Structure;
		FormParameters.Insert("Filter", FilterStructure);
		FormParameters.Insert("PurposeUseKey", "Departments");
		OpenForm("Catalog.StructuralUnits.ListForm", FormParameters);
	ElsIf Find(EventData.Href, "AitotransferConfig")>0 Then
		ParametersStructure = StructureOpeningAutotransferConfig();
		Notification = New NotifyDescription("AutotransferConfigEnding", ThisObject);
		OpenForm("CommonForm.AutoTransferInventoryForm", ParametersStructure,,,,,Notification);
	ElsIf Find(EventData.Href, "ProductionKind")>0 Then
		OpenForm("Catalog.ProductionKind.ListForm");
	ElsIf Find(EventData.Href, "Specifications")>0 Then
		OpenForm("Справочник.Specifications.ListForm");
	EndIf;  
	
EndProcedure

&AtServerNoContext
Function StructureOpeningAutotransferConfig()
	
	ParametersStructure = CommonUse.ЗначенияРеквизитовОбъекта(Catalogs.StructuralUnits.MainDepartment,
		"TransferSource,TransferRecipient,DisposalsRecipient,WriteOffToExpensesSource,WriteOffToExpensesRecipient,PassToOperationSource,"
		+"PassToOperationRecipient,ReturnFromOperationSource,ReturnFromOperationRecipient,TransferSourceCell,TransferRecipientCell,"
		+"DisposalsRecipientCell,WriteOffToExpensesSourceCell,WriteOffToExpensesRecipientCell,PassToOperationSourceCell,"
		+"PassToOperationRecipientCell,ReturnFromOperationSourceCell,ReturnFromOperationRecipientCell,StructuralUnitType");
	Return ParametersStructure;
	
EndFunction

&AtClient
Procedure AutotransferConfigCompleting(FillParameters, AdditionalParameters) Export
	
	If TypeOf(FillParameters) = Type("Structure") Then
		SaveAutotransferConfigs(FillParameters);
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure SaveAutotransferConfigs(FillParameters)
	
	CatalogObject = Catalogs.StructuralUnits.ОсновноеПодразделение.GetObject();
	FillPropertyValues(CatalogObject, FillParameters);
	CatalogObject.Write();
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure Update(Command)
	
	StructureData = New Structure;
	Notification = New NotifyDescription("UpdateCompletion", ThisObject, StructureData);
	CheckModificationAndContinue(Notification);
	
EndProcedure

&AtClient
Procedure UpdateCompletion(Result, AdditionalData) Export
	
	If Result<>DialogReturnCode.OK Then
		Return;
	EndIf; 
	
	FillOrderTreeClient();
	
EndProcedure

&AtClient
Procedure SaveChanges(Command)
	
	If Not RequiredAttrFilled() Then
		Return;
	EndIf; 
	
	RunBackgroundJob();
	
EndProcedure

&AtClient
Procedure FillManufacture(Command)
	
	For Each RowOrder In Orders.GetItems() Do
		For Each ProductsRow In RowOrder.GetItems() Do
			If PerformByDifferentDepartments Then
				For ii = 1 To StagesQuantity Do
					If ProductsRow["StageDisable" + ii] Then
						Continue;
					EndIf;
					If Not ProductsRow.IsSavedDocuments 
						And Not ProductsRow.IsUnavailableStages 
						And Not ValueIsFilled(ProductsRow.ProductionOrder)
						And ProductsRow.IsPerformedStages Then
						ProductsRow.StructuralUnit = Manufacturer;
					EndIf; 
					If ProductsRow["StageLabel" + ii] And Not ProductsRow["StageLabelOld" + ii] Then
						ProductsRow["StructuralUnit" + ii] = Manufacturer;
						OnChangeStageStructuralUnit(ProductsRow, ii);
					EndIf; 
				EndDo;
			ElsIf ProductsRow.IsPerformedStages 
				And Not ProductsRow.IsSavedDocuments 
				And Not ValueIsFilled(ProductsRow.ProductionOrder) Then 
				ProductsRow.StructuralUnit = Manufacturer;
				StructuralUnitOnChange(ProductsRow);
			EndIf; 
		EndDo; 
	EndDo;
	Manufacturer = Undefined;
	FormManagment(ThisObject);
	
EndProcedure

&AtClient
Procedure FillAdministrator(Command)
	
	For Each RowOrder In Orders.GetItems() Do
		For Each ProductsRow In RowOrder.GetItems() Do
			For ii = 1 To StagesQuantity Do
				If ProductsRow["StageDisable" + ii] Or Not ProductsRow["ChoosePerformer" + ii] Then
					Continue;
				EndIf;
				If ProductsRow["StageLabel" + ii] And Not ProductsRow["StageLabelOld" + ii] Then
					ProductsRow["Performer" + ii] = Performer;
					OnChangeStagePerfomer(ProductsRow, ii);
				EndIf; 
			EndDo;
		EndDo; 
	EndDo;
	Performer = Undefined;
	FormManagment(ThisObject);
	
EndProcedure

&AtClient
Procedure PerfomStage(Command)
	
	If Not ValueIsFilled(MarkStage) Then
		Return;
	EndIf; 
	
	For Each RowOrder In Orders.GetItems() Do
		For Each ProductsRow In RowOrder.GetItems() Do
			For ii = 1 To StagesQuantity Do
				If ProductsRow["StageDisable" + ii] 
					Or ProductsRow["StageHide" + ii] 
					Or ProductsRow["Stage" + ii]<>MarkStage Then
					Continue;
				EndIf;
				ProductsRow["StageLabel" + ii] = True;
				OnChangeStageMark(ProductsRow, ii);
			EndDo; 
		EndDo; 
	EndDo;
	MarkStage = Undefined;
	
EndProcedure

&AtClient
Procedure ExpandAll(Command)
	
	ExpandOrderTree();
	
EndProcedure

&AtClient
Procedure CollapseAll(Command)
	
	CollapseOrderTree();
	
EndProcedure

#EndRegion

#Region ServiceMethods

&AtClient
Procedure FillOrderTreeClient()
	
	FillOrderTree();
	ExpandOrderTree();
	
EndProcedure

&AtClient
Procedure ExpandOrderTree()
	
	For Each Str In Orders.GetItems() Do
		Items.Orders.Expand(Str.GetID());
	EndDo; 
	
EndProcedure

&AtClient
Procedure CollapseOrderTree()
	
	For Each Str In Orders.GetItems() Do
		Items.Orders.Collapse(Str.GetID());
	EndDo; 
	
EndProcedure

&AtServer
Procedure FillOrderTree()
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	ProductionKinds.Ref AS Ref
	|FROM
	|	Catalog.ProductionKinds AS ProductionKinds";
	IsProductionKind = Not Query.Execute().IsEmpty();
	
	Items.MarkStage.ChoiceList.Clear();
	
	DataCompositionSchema = DataProcessors.StageManagement.GetTemplate("FillingScheme");
	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
	SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	ComposerSettings = SettingsComposer.Settings;
	
	SettingsParameters = ComposerSettings.DataParameters;

	Parameter = SettingsParameters.Items.Find("PlaningDate");
	Parameter.Use = True;
	Parameter.Value = PlaningDate;

	Parameter = SettingsParameters.Items.Find("ProductionDate");
	Parameter.Use = True;
	Parameter.Value = ProductionDate;

	Parameter = SettingsParameters.Items.Find("OnlyPlanned");
	Parameter.Use = True;
	Parameter.Value = OnlyPlaned;
	
	// Фильтры из боковой панели
	For Each MarkRow In LabelData Do
		Field = New DataCompositionField(MarkRow.FilterFieldName);
		FindedItem = Undefined;
		For Each FilterItem In ComposerSettings.Filter.Items Do
			If FilterItem.LeftValue=Field 
				And FilterItem.ComparisonType=DataCompositionComparisonType.InList Then
				FindedItem = FilterItem;
				Break;
			EndIf; 
		EndDo; 
		If FindedItem=Undefined Then
			FindedItem = ComposerSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
			FindedItem.LeftValue = Field;
			FindedItem.ComparisonType = DataCompositionComparisonType.InList;
			FindedItem.RightValue = New ValueList;
		EndIf; 
		FindedItem.RightValue.Add(MarkRow.Label);
	EndDo; 

	TemplateComposer = New DataCompositionTemplateComposer;
	DataCompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ComposerSettings, , , Type("DataCompositionValueCollectionTemplateGenerator"));
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(DataCompositionTemplate);
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	OrderTree = New ValueTree;
	OutputProcessor.SetObject(OrderTree);
	OutputProcessor.Output(DataCompositionProcessor);
	
	Orders.GetItems().Clear();
	
	NewStageQuantity = 0;
	For Each RowOrder In OrderTree.Rows Do
		For Each ProductsRow In RowOrder.Rows Do
			NewStageQuantity = Max(NewStageQuantity, ProductsRow.StagesQuantity);
		EndDo; 
	EndDo;  
	
	UpdateOrderTreeAttributes(NewStageQuantity);
	UpdateFormItems(NewStageQuantity);
	
	If NewStageQuantity<>StagesQuantity Then
		StagesQuantity = NewStageQuantity;
		UpdateConditionalAppearance();
	EndIf; 
	
	WithoutIBPrefix = True;
	WithoutUserPrefix = True;
	
	// Заполнение дерева заказов и продукции
	For Each RowOrder In OrderTree.Rows Do
		
		NewRowOrder = Orders.GetItems().Add();
		FillPropertyValues(NewRowOrder, RowOrder, "Company, CustomerOrder, ProductionOrder, CounterParty");
		NewRowOrder.Level = 1;
		NewRowOrder.Description = OrdersPresentation(NewRowOrder);
		For ii = RowOrder.StagesQuantity + 1 To StagesQuantity Do
			NewRowOrder["StageHide" + ii] = True;
		EndDo; 
		For Each ProductsRow In RowOrder.Rows Do
			If OnlyStage And ProductsRow.StagesQuantity<=1 Then
				Continue;
			EndIf; 
			NewRowProduction = NewRowOrder.GetItems().Add();
			FillPropertyValues(NewRowProduction, ProductsRow);
			NewRowProduction.Level = 2;
			NewRowProduction.Description = ProductAndServicesPresentation(NewRowProduction);
			If Not UseStructuralUnits Then
				NewRowProduction.StructuralUnit = Catalogs.StructuralUnits.MainDepartment;
			ElsIf Not PerformByDifferentDepartments And Not ValueIsFilled(NewRowProduction.StructuralUnit) Then
				NewRowProduction.StructuralUnit = ProductsRow.ProductionOrderStructuralUnit;
			EndIf; 
			For ii = ProductsRow.StagesQuantity + 1 To StagesQuantity Do
				NewRowProduction["StageHide" + ii] = True;
			EndDo; 
			StageNumber = 1;
			For Each RowStage In ProductsRow.Rows Do
				NewRowProduction["PerformerDescription" + StageNumber] = String(RowStage.PerformerByDefault);
				NewRowProduction["Stage" + StageNumber] = RowStage.Stage;
				If ValueIsFilled(RowStage.Stage) And Items.MarkStage.ChoiceList.FindByValue(RowStage.Stage)=Undefined Then
					Items.MarkStage.ChoiceList.Add(RowStage.Stage, String(RowStage.Stage));
				EndIf; 
				NewRowProduction["InventoryAssembly" + StageNumber] = RowStage.InventoryAssembly;
				If ValueIsFilled(RowStage.InventoryAssembly) Then
					NewRowProduction["InventoryAssemblyDescription" + StageNumber] = 
						StrTemplate(NStr("en='№%1 form %2';ru='№%1 от %2';vi='№%1 ngày  %2'"), 
						ObjectPrefixationClientServer.GetNumberForPrinting(RowStage.InventoryAssemblyNumber, WithoutIBPrefix, WithoutUserPrefix),
						Format(RowStage.InventoryAssemblyDate, "ДЛФ=D"));
				ElsIf RowStage.InventoryAssemblyQuantity>1 Then
					NewRowProduction["InventoryAssemblyDescription" + StageNumber] = 
					StrTemplate(NStr("ru = 'Производство (%1)';
									|en = 'Production (%1)';
									|vi = 'Xuất xưởng thành phẩm (%1)';"), 
					RowStage.InventoryAssemblyQuantity);
					NewRowProduction["StageDisable" + StageNumber] = True;
				EndIf; 
				NewRowProduction["JobSheet" + StageNumber] = RowStage.JobSheet;
				If ValueIsFilled(RowStage.JobSheet) Then
					NewRowProduction["JobSheetDescription" + StageNumber] = 
					StrTemplate(NStr("en='№%1 form %2';ru='№%1 от %2';vi='№%1 ngày  %2'"), 
					ObjectPrefixationClientServer.GetNumberForPrinting(RowStage.JobSheetNumber, WithoutIBPrefix, WithoutUserPrefix),
					Format(RowStage.JobSheet, "ДЛФ=D"));
				ElsIf RowStage.JobSheetQuantity>1 Then
					NewRowProduction["JobSheetDescription" + StageNumber] = 
					StrTemplate(NStr("ru = 'Сдельный наряд (%1)';
									|en = 'Job sheet (%1)';
									|vi = 'Công khoán (%1)';"), 
					RowStage.JobSheetQuantity);
					NewRowProduction["StageDisable" + StageNumber] = True;
				EndIf;
				If PerformByDifferentDepartments Then
					NewRowProduction["StructuralUnit" + StageNumber] = RowStage.InventoryAssemblyPerformer;
				Else
					NewRowProduction["StructuralUnit" + StageNumber] = NewRowProduction.StructuralUnit;
				EndIf; 
				NewRowProduction["Performer" + StageNumber] = RowStage.JobSheetPerformer;
				NewRowProduction["PerformerHide" + StageNumber] = RowStage.PerformerHide;
				NewRowProduction["ChoosePerformer" + StageNumber] = RowStage.ChoosePerformer;
				If RowStage.Performed And Not RowStage.OnThisDay Then
					NewRowProduction["StageDisable" + StageNumber] = True;
				EndIf;
				NewRowProduction["StageLabel" + StageNumber] = RowStage.Performed;
				NewRowProduction["StageLabelOld" + StageNumber] = RowStage.Performed;
				NewRowProduction.IsPerformedStages = (NewRowProduction.IsPerformedStages Or RowStage.Performed);
				NewRowProduction.IsSavedDocuments = (NewRowProduction.IsSavedDocuments Or RowStage.Performed);
				NewRowProduction.IsUnavailableStages = (NewRowProduction.IsUnavailableStages Or NewRowProduction["StageDisable" + StageNumber]);
				StageNumber = StageNumber + 1;
				If StageNumber>StagesQuantity Then
					Break;
				EndIf; 
			EndDo;
			NewRowOrder.IsPerformedStages = EqualValue(NewRowOrder, "IsPerformedStages");
			NewRowOrder.IsSavedDocuments = EqualValue(NewRowOrder, "IsSavedDocuments");
		EndDo;
		
		If NewRowOrder.GetItems().Count()=0 Then
			Orders.GetItems().Delete(NewRowOrder);
			Continue;
		EndIf; 
		
		// Настройка отображения строки заказа
		// 1. Проверка что в колонках располагаются одинаковые этапы
		PreviousRow = Undefined;
		If NewRowOrder.GetItems().Count()<=1 Then
			For ii = 1 To StagesQuantity Do
				NewRowOrder["StageHide" + ii] = True;
			EndDo;
			NewRowOrder.IsUnavailableStages = True;
		Else
			For Each ProductsRow In NewRowOrder.GetItems() Do
				If PreviousRow=Undefined Then
					PreviousRow = ProductsRow;
					Continue;
				EndIf; 
				For ii = 1 To StagesQuantity Do
					Hide = False;
					If PreviousRow["Stage" + ii]<>ProductsRow["Stage" + ii] 
						Or Not ValueIsFilled(PreviousRow["Stage" + ii]) 
						Or Not ValueIsFilled(ProductsRow["Stage" + ii]) Then
						Hide = True;
					EndIf; 
					If Hide And Not NewRowOrder["StageHide" + ii] Then
						NewRowOrder["StageHide" + ii] = True;
					EndIf;
				EndDo;
				PreviousRow = ProductsRow;
			EndDo;
			If PreviousRow<>Undefined Then
				For ii = 1 To StagesQuantity Do
					If Not NewRowOrder["StageDisable" + ii] Then
						NewRowOrder["Stage" + ii] = PreviousRow["Stage" + ii];
					EndIf; 
				EndDo; 
			EndIf;
		EndIf; 
		// 2. Отметка выполненных этапов для заказов
		For ii = 1 To StagesQuantity Do
			NewRowOrder["StageLabel" + ii] = ValueIsFilled(NewRowOrder["Stage" + ii]);
		EndDo; 
		For Each ProductsRow In NewRowOrder.GetItems() Do
			For ii = 1 To StagesQuantity Do
				If NewRowOrder["StageLabel" + ii] And Not ProductsRow["StageLabel" + ii] Then
					NewRowOrder["StageLabel" + ii] = False;
				EndIf; 
			    If NewRowOrder["StageDisable" + ii] Or NewRowOrder["StageHide" + ii] Then
					Continue;
				EndIf;
				If ProductsRow["StageDisable" + ii] Then
					 NewRowOrder["StageDisable" + ii] = True;
				EndIf; 
			EndDo;
		EndDo;
		For ii = 1 To StagesQuantity Do
			NewRowOrder["StageLabelOld" + ii] = NewRowOrder["StageLabel" + ii];
		EndDo;
		// 3. Доступность операций для этапов
		For ii = 1 To StagesQuantity Do
			NewRowOrder["PerformerHide" + ii] = True;
			NewRowOrder["ChoosePerformer" + ii] = False;
		EndDo; 
		For Each ProductsRow In NewRowOrder.GetItems() Do
			For ii = 1 To StagesQuantity Do
				If Not NewRowOrder["StageDisable" + ii] 
					And NewRowOrder["PerformerHide" + ii] 
					And Not ProductsRow["PerformerHide" + ii] Then
					NewRowOrder["PerformerHide" + ii] = False;
				EndIf;
				If Not NewRowOrder["StageDisable" + ii] 
					And Not NewRowOrder["ChoosePerformer" + ii] 
					And ProductsRow["ChoosePerformer" + ii] Then
					NewRowOrder["ChoosePerformer" + ii] = True;
				EndIf;
				If Not IsBlankString(ProductsRow["PerformerDescription" + ii]) 
					And Find(NewRowOrder["PerformerDescription" + ii], ProductsRow["PerformerDescription" + ii])=0 Then
					NewRowOrder["PerformerDescription" + ii] = NewRowOrder["PerformerDescription" + ii] + ?(IsBlankString(NewRowOrder["PerformerDescription" + ii]), "", ", ") + ProductsRow["PerformerDescription" + ii];
				EndIf; 
			EndDo;
		EndDo;
		// 4. Поля расшифровки
		For ii = 1 To StagesQuantity Do
			NewRowOrder["InventoryAssembly" + ii] = EqualValue(NewRowOrder, "InventoryAssembly", ii);
			If ValueIsFilled(NewRowOrder["InventoryAssembly" + ii]) 
				And NewRowOrder.GetItems().Count()>=1 Then
				NewRowOrder["InventoryAssemblyDescription" + ii] = NewRowOrder.GetItems().Get(0)["InventoryAssemblyDescription" + ii];
			EndIf; 
			NewRowOrder["InventoryAssembly" + ii] = EqualValue(NewRowOrder, "InventoryAssembly", ii);
			If ValueIsFilled(NewRowOrder["InventoryAssembly" + ii]) 
				And NewRowOrder.GetItems().Count()>=1 Then
				NewRowOrder["InventoryAssemblyDescription" + ii] = NewRowOrder.GetItems().Get(0)["InventoryAssemblyDescription" + ii];
			EndIf; 
			NewRowOrder["StructuralUnit" + ii] = EqualValue(NewRowOrder, "StructuralUnit", ii);
			NewRowOrder["Performer" + ii] = EqualValue(NewRowOrder, "Performer", ii);
		EndDo;
		// 5. Структурная единица завершающего этапа
		NewRowOrder.StructuralUnit = EqualValue(NewRowOrder, "StructuralUnit");
		
	EndDo;
	
	// Заголовки колонок
	MoveToHeader = True;
	For ii = 1 To StagesQuantity Do
		FirstRow = Undefined;
		For Each RowOrder In Orders.GetItems() Do
			For Each ProductsRow In RowOrder.GetItems() Do
				If ProductsRow["StageHide" + ii] Then
					MoveToHeader = False;
					Break;
				EndIf; 
				If FirstRow=Undefined Then
					FirstRow = ProductsRow;
					Continue;
				EndIf; 
				If FirstRow["Stage" + ii]<>ProductsRow["Stage" + ii] Then
					MoveToHeader = False;
					Break;
				EndIf; 
			EndDo;
			If Not MoveToHeader Then
				Break;
			EndIf; 
		EndDo; 
		If FirstRow<>Undefined Then
			Items["OrdersGroupStageVertical" + ii].Title = String(FirstRow["Stage" + ii]);
		EndIf; 
	EndDo;
	For ii = 1 To StagesQuantity Do
		Items["OrdersStageTitle" + ii].Visible = Not MoveToHeader;
		Items["OrdersGroupStageVertical" + ii].ShowInHeader = MoveToHeader;
	EndDo;
	
	Modified = False;
	
	If Not IsProductionKind Or ShowDescription Then
		Items.Pages.CurrentPage = Items.DescriptionPanel;
		Items.PerfomStages.Enabled = False;
		Items.GroupCollapseExpand.Enabled = False;
	Else
		Items.Pages.CurrentPage = Items.MainPanel;
		Items.PerfomStages.Enabled = True;
		Items.GroupCollapseExpand.Enabled = True;
	EndIf;
	
	UpdateDescription();
	Items.MarkStage.ChoiceList.SortByPresentation();
	
EndProcedure

&AtServer
Procedure UpdateOrderTreeAttributes(NewStageQuantity)
	
	// Обновление реквизитов формы
	DeletedAttrArray = New Array;
	AddedAttrArray = New Array;
	
	If NewStageQuantity>StagesQuantity Then
		
		For ii = StagesQuantity + 1 To NewStageQuantity Do
			AddedAttrArray.Add(New FormAttribute("Stage" + ii, New TypeDescription("CatalogRef.ProductionStages"), "Orders"));
			AddedAttrArray.Add(New FormAttribute("StageLabel" + ii, New TypeDescription("Boolean"), "Orders"));
			AddedAttrArray.Add(New FormAttribute("StageLabelOld" + ii, New TypeDescription("Boolean"), "Orders"));
			AddedAttrArray.Add(New FormAttribute("StageDisable" + ii, New TypeDescription("Boolean"), "Orders"));
			AddedAttrArray.Add(New FormAttribute("StageHide" + ii, New TypeDescription("Boolean"), "Orders"));
			AddedAttrArray.Add(New FormAttribute("StructuralUnit" + ii, New TypeDescription("CatalogRef.StructuralUnits"), "Orders"));
			AddedAttrArray.Add(New FormAttribute("PerformerHide" + ii, New TypeDescription("Boolean"), "Orders"));
			AddedAttrArray.Add(New FormAttribute("ChoosePerformer" + ii, New TypeDescription("Boolean"), "Orders"));
			AddedAttrArray.Add(New FormAttribute("Performer" + ii, New TypeDescription("CatalogRef.Employees, СправочникСсылка.Teams"), "Orders"));
			AddedAttrArray.Add(New FormAttribute("PerformerDescription" + ii, New TypeDescription("String", New StringQualifiers(0)), "Orders"));
			AddedAttrArray.Add(New FormAttribute("InventoryAssembly" + ii, New TypeDescription("DocumentRef.InventoryAssembly"), "Orders"));
			AddedAttrArray.Add(New FormAttribute("InventoryAssemblyDescription" + ii, New TypeDescription("String", New StringQualifiers(0)), "Orders"));
			AddedAttrArray.Add(New FormAttribute("JobSheet" + ii, New TypeDescription("DocumentRef.JobSheet"), "Orders"));
			AddedAttrArray.Add(New FormAttribute("JobSheetDescription" + ii, New TypeDescription("String", New StringQualifiers(0)), "Orders"));
		EndDo; 
		
	ElsIf NewStageQuantity<StagesQuantity Then
		
		For ii = NewStageQuantity + 1 To StagesQuantity Do
			DeletedAttrArray.Add("Orders.Stage" + ii);
			DeletedAttrArray.Add("Orders.StageLabel" + ii);
			DeletedAttrArray.Add("Orders.StageLabelOld" + ii);
			DeletedAttrArray.Add("Orders.StageDisable" + ii);
			DeletedAttrArray.Add("Orders.StageHide" + ii);
			DeletedAttrArray.Add("Orders.StructuralUnit" + ii);
			DeletedAttrArray.Add("Orders.PerformerHide" + ii);
			DeletedAttrArray.Add("Orders.ChoosePerformer" + ii);
			DeletedAttrArray.Add("Orders.Performer" + ii);
			DeletedAttrArray.Add("Orders.PerformerDescription" + ii);
			DeletedAttrArray.Add("Orders.InventoryAssembly" + ii);
			DeletedAttrArray.Add("Orders.InventoryAssemblyDescription" + ii);
			DeletedAttrArray.Add("Orders.JobSheet" + ii);
			DeletedAttrArray.Add("Orders.JobSheetDescription" + ii);
		EndDo; 
		
	EndIf;
	
	If AddedAttrArray.Count()>0 Or DeletedAttrArray.Count()>0 Then
		
		ChangeAttributes(AddedAttrArray, DeletedAttrArray);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateFormItems(NewStageQuantity)
	
	If NewStageQuantity>StagesQuantity Then
		
		For ii = StagesQuantity + 1 To NewStageQuantity Do
			
			GroupVertichal = Items.Add("OrdersGroupStageVertical" + ii, Type("FormGroup"), Items.Orders);
			GroupVertichal.Type = FormGroupType.ColumnGroup;
			GroupVertichal.Group = ColumnsGroup.Vertical;
			GroupVertichal.ShowInHeader = False;
			GroupVertichal.HorizontalStretch = False;
			GroupVertichal.Width = 30;
			
			Var_Group = Items.Add("OrdersGroupStage" + ii, Type("FormGroup"), GroupVertichal);
			Var_Group.Type = FormGroupType.ColumnGroup;
			Var_Group.Group = ColumnsGroup.InCell;
			Var_Group.ShowInHeader = False;
			Var_Group.HorizontalStretch = False;
			Var_Group.Width = 30;
			
			ItemMark = Items.Add("OrdersStageLabel" + ii, Type("FormField"), Var_Group);
			ItemMark.Type = FormFieldType.CheckBoxField;
			ItemMark.DataPath = "Orders.StageLabel" + ii;
			ItemMark.ShowInHeader = False;
			ItemMark.EditMode = ColumnEditMode.Directly;
			ItemMark.SetAction("ПриИзменении", "Attachable_StageMarkOnchange");
			
			ItemHeadline = Items.Add("OrdersStageTitle" + ii, Type("FormField"), Var_Group);
			ItemHeadline.Type = FormFieldType.LabelField;
			ItemHeadline.DataPath = "Orders.Stage" + ii;
			ItemHeadline.ShowInHeader = False;
			ItemHeadline.Width = 30;
			
			GroupDetails = Items.Add("OrderGroupDetails" + ii, Type("FormGroup"), GroupVertichal);
			GroupDetails.Type = FormGroupType.ColumnGroup;
			GroupDetails.Group = ColumnsGroup.Vertical;
			GroupDetails.ShowInHeader = False;
			
			// Реквизиты этапов
			Var_Group = Items.Add("OrdersGroupFields" + ii, Type("FormGroup"), GroupDetails);
			Var_Group.Type = FormGroupType.ColumnGroup;
			Var_Group.Group = ColumnsGroup.Horizontal;
			Var_Group.ShowInHeader = False;
			Var_Group.HorizontalStretch = False;
			Var_Group.Width = 30;
			
			If UseStructuralUnits And PerformByDifferentDepartments Then
				
				ItemField = Items.Add("OrdersStageStructuralUnit" + ii, Type("FormField"), Var_Group);
				ItemField.Type = FormFieldType.InputField;
				ItemField.EditMode = ColumnEditMode.Directly;
				ItemField.DataPath = "Orders.StructuralUnit" + ii;
				ItemField.ShowInHeader = False;
				ItemField.Width = 15;
				ItemField.InputHint = NStr("en='Stage department';vi='Công đoạn bộ phận'");
				ItemField.OpenButton = False;
				ItemField.CreateButton = False;
				If PerformByDifferentDepartments Then
					ItemField.ChoiceHistoryOnInput = ChoiceHistoryOnInput.DontUse;
				EndIf; 
				ItemField.SetAction("Автоподбор", "Attachable_StageStructuralUnitAutoComplete");
				ItemField.SetAction("ПриИзменении", "Attachable_StageStructuralUnitOnChange");
				ItemField.ChoiceParameters = Items.OrdersStructuralUnit.ChoiceParameters;
				
			EndIf;
			
			If UseTechnicalOperation Then
				
				GroupTechOperations = Items.Add("OrdersGroupTechOperation" + ii, Type("FormGroup"), Var_Group);
				GroupTechOperations.Type = FormGroupType.ColumnGroup;
				GroupTechOperations.Group = ColumnsGroup.Vertical;
				GroupTechOperations.ShowInHeader = False;
				
				ItemField = Items.Add("OrdersStagePerformer" + ii, Type("FormField"), GroupTechOperations);
				ItemField.Type = FormFieldType.InputField;
				ItemField.EditMode = ColumnEditMode.Directly;
				ItemField.DataPath = "Orders.Performer" + ii;
				ItemField.ShowInHeader = False;
				ItemField.Width = 15;
				ItemField.InputHint = NStr("en='Stage performer';vi='Người thực hiện công đoạn'");
				ItemField.OpenButton = False;
				ItemField.CreateButton = False;
				ItemField.InputHint = NStr("en='Stage performer';vi='Người thực hiện công đoạn'");
				ItemField.SetAction("ПриИзменении", "Attachable_StagePerfomerOnchange");
				
				ItemField = Items.Add("OrdersStagePerformerDescription" + ii, Type("FormField"), GroupTechOperations);
				ItemField.Type = FormFieldType.InputField;
				ItemField.DataPath = "Orders.PerformerDescription" + ii;
				ItemField.ShowInHeader = False;
				ItemField.TextColor = StyleColors.InaccessibleDataColor;
				ItemField.Width = 15;
				ItemField.ReadOnly = True;
				
			EndIf; 
			
			// Сформированные документы
			Var_Group = Items.Add("OrdersGroupDocuments" + ii, Type("FormGroup"), GroupDetails);
			Var_Group.Type = FormGroupType.ColumnGroup;
			Var_Group.Group = ColumnsGroup.Horizontal;
			Var_Group.ShowInHeader = False;
			Var_Group.HorizontalStretch = False;
			Var_Group.Width = 30;
			
			ItemField = Items.Add("OrdersStageInventoryAssemblyDescription" + ii, Type("FormField"), Var_Group);
			ItemField.Type = FormFieldType.LabelField;
			ItemField.DataPath = "Orders.InventoryAssemblyDescription" + ii;
			ItemField.ShowInHeader = False;
			ItemField.Hyperlink = True;
			ItemField.CellHyperlink = True;
			ItemField.Width = 30;
			
			If UseTechnicalOperation Then
				
				ItemField = Items.Add("OrdersStageJobSheetDescription" + ii, Type("FormField"), Var_Group);
				ItemField.Type = FormFieldType.LabelField;
				ItemField.DataPath = "Orders.JobSheetDescription" + ii;
				ItemField.ShowInHeader = False;
				ItemField.Hyperlink = True;
				ItemField.CellHyperlink = True;
				ItemField.Width = 30;
				
			EndIf; 
			
		EndDo;
		
	ElsIf NewStageQuantity<StagesQuantity Then
		
		For ii = NewStageQuantity + 1 To StagesQuantity Do
			DeleteFormItem("OrdersStageLabel" + ii);
			DeleteFormItem("OrdersStageЗаголовок" + ii);
			DeleteFormItem("OrdersStageStructuralUnit" + ii);
			DeleteFormItem("OrdersStagePerformer" + ii);
			DeleteFormItem("OrdersStageInventoryAssemblyDescription" + ii);
			DeleteFormItem("OrdersStageJobSheetDescription" + ii);
			DeleteFormItem("OrdersGroupStage" + ii);
			DeleteFormItem("OrdersGroupDocuments" + ii);
			DeleteFormItem("OrdersGroupTechOperations" + ii);
			DeleteFormItem("OrdersGroupFields" + ii);
			DeleteFormItem("OrdersGroupDetails" + ii);
			DeleteFormItem("OrdersGroupStageVertical" + ii);
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateDescription()
	
	Description = DataProcessors.StageManagement.GetTemplate("Description").GetText();
	
	If UseStructuralUnits Then
		Description = StrReplace(Description, "%РазныеПодразделения%", " и на разных подразделениях (при включении опции ""Этапы могут выполняться разными подразделениями"" раздела ""Производство"" в настройках программы)");
	Else
		Description = StrReplace(Description, "%РазныеПодразделения%", "");
	EndIf; 
	
	If UseWarehouses And UseStructuralUnits Then
		Description = StrReplace(Description, "%Склады%", "Склады списания материалов и хранения готовой продукции устанавливаются в настройках автоперемещения подразделений (<A href=""СписокПодразделений"">открыть список подразделений</A>)");
	ElsIf UseWarehouses Then
		Description = StrReplace(Description, "%Склады%", "Склады списания материалов и хранения готовой продукции устанавливаются в настройках автоперемещения (<A href=""НастройкиАвтоперемещения"">изменить настройки</A>)");
	Else
		Description = StrReplace(Description, "%Склады%", "");
	EndIf; 
	
	If UseTechnicalOperation Then
		Description = StrReplace(Description, "%Техоперации%", " Для этапов с операциями нужно указать исполнителя. Если выполнение операций запланировано заказом на производство, то Performer будет заполнен автоматически. При использовании бригады в качестве исполнителя, в сформированном сдельном наряде будет заполнен состав по умолчанию.");
	Else
		Description = StrReplace(Description, "%Техоперации%", " Эта информация также может быть указана заранее, в заказах на производство.");
	EndIf; 
	
	If Not IsProductionKind Then
		Description = StrReplace(Description, "%Переход%", "Для начала работы с АРМ следует выполнить настройку <A href=""ВидыПроизводства"">этапов производства</A> и <A href=""Update"">Update форму</A>");
	ElsIf Orders.GetItems().Count()=0 Then
		Description = StrReplace(Description, "%Переход%", "В данный момент запланированные к поэтапному производству заказы отсутствуют (<A href=""Update"">Update форму</A>)");
	Else
		Description = StrReplace(Description, "%Переход%", "<A href=""Update"">Показать заказы</A>");
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckModificationAndContinue(Notification)
	
	If Modified Then
		ShowQueryBox(Notification, NStr("en='Changed performance marks of part of the stages. When performing the operation, the changes will be reset. Continue?';ru='Изменены отметки выполнения части этапов. При выполнении операции изменения будут сброшены. Продолжить?';vi='Đã thay đổi đánh dấu thực hiện các phần của công đoạn. Khi thực hiện thao tác, sẽ hủy các thay đổi. Tiếp tục?'"), QuestionDialogMode.OKCancel, , DialogReturnCode.Cancel);
	Else
		ExecuteNotifyProcessing(Notification, DialogReturnCode.OK);
	EndIf;
	
EndProcedure

&AtClient
Function RequiredAttrFilled()
	
	Cancel = False;
	Errors = Undefined;
	
	If Not ValueIsFilled(ProductionDate) Then
		CommonUseClientServer.AddUserError(
			Errors,
			,
			NStr("ru = 'Не указана дата производства'';
				|en = 'Not specified production date';"),
			"ProductionDate",
			,
			);
	EndIf; 
	
	If Not ValueIsFilled(StagesQuantity) Then
		CommonUseClientServer.AddUserError(
			Errors,
			,
			NStr("en='No data for production';ru='Нет данных для производства';vi='Không có dữ liệu cho sản xuất'"),
			"Orders",
			,
			);
	EndIf; 
	
	For Each RowOrder In Orders.GetItems() Do
		For Each ProductsRow In RowOrder.GetItems() Do
			// Структурная единица завершающего этапа
			If ProductsRow.IsPerformedStages
				And Not ValueIsFilled(ProductsRow.StructuralUnit) Then
				CommonUseClientServer.AddUserError(
					Errors,
					,
					NStr("en='Not specified manufacturer';ru='Не указан изготовитель';vi='Chưa chỉ ra nhà sản xuất'"),
					"Orders.StructuralUnit",
					,
					StrTemplate(NStr("en = 'null'; ru = 'Не указан изготовитель номенклатуры ""%1"" (%2)'; vi = 'Nhà sản xuất mặt hàng ""%1"" (%2) không được chỉ định'"), ProductsRow.Description, RowOrder.Description));
			EndIf;
			// Структурная единица этапа
			For ii = 1 To StagesQuantity Do
		        If ProductsRow["StageLabel" + ii]=ProductsRow["StageLabelOld" + ii] Then
					Continue;
				EndIf;
		        If ProductsRow["Stage" + ii]=PredefinedValue("Справочник.ProductionStages.ProductionComplete") Then
					Continue;
				EndIf;
				If ProductsRow["StageLabel" + ii]
					And Not ValueIsFilled(ProductsRow["StructuralUnit" + ii]) Then
					CommonUseClientServer.AddUserError(
						Errors,
						,
						NStr("en='Not specified stage structural unit';ru='Не указана структурная единица этапа';vi='Không quy định đơn vị cấu trúc giai đoạn'"),
						"Orders.StructuralUnit" + ii,
						,
						StrTemplate(NStr("en='There is no structural unit in stage %1 product and services %2 (%3)';ru='Не указана структурная единица этапа %1 номенклатуры %2 (%3)';vi='Chưa chỉ ra đơn vị cấu trúc trong công đoạn %1 của mặt hàng %2 (%3)'"), ProductsRow["Stage" + ii], ProductsRow.Description, RowOrder.Description));
				EndIf; 
			EndDo;
			// Исполнитель
			For ii = 1 To StagesQuantity Do
				If ProductsRow["StageLabel" + ii] 
					And Not ProductsRow["StageLabelOld" + ii]
					And ProductsRow["ChoosePerformer" + ii]
					And Not ValueIsFilled(ProductsRow["Performer" + ii]) Then
					CommonUseClientServer.AddUserError(
						Errors,
						,
						NStr("En='not specified performer of stage operation';ru='Не указан исполнитель операций этапа';vi='không chỉ định thực hiện công đoạn'"),
						"Orders.Performer" + ii,
						,
						StrTemplate(NStr("En='Not specified operation performer in stage ""%1"" product and services ""%2"" (%3)';ru='Не указан исполнитель операций этапа ""%1"" номенклатуры ""%2"" (%3)';vi='Chưa chỉ ra người thực hiện công đoạn ""%1"" mặt hàng ""%2"" (%3)'"), ProductsRow["Stage" + ii], ProductsRow.Description, RowOrder.Description));
				EndIf; 
			EndDo; 
		EndDo; 
	EndDo;
	
	CommonUseClientServer.ShowErrorsToUser(Errors, Cancel);
	
	Return Not Cancel;
	
EndFunction

&AtServer
Procedure DeleteFormItem(ItemName)
	
	Item = Items.Find(ItemName);
	If Item<>Undefined Then
		Items.Delete(Item);
	EndIf; 
	
EndProcedure
 
&AtClientAtServerNoContext
Function ProductAndServicesPresentation(TreeRow)
	
	If Not ValueIsFilled(TreeRow.ProductsAndServices) Then
		Return NStr("en='<Product not specified>';ru='<Номенклатура не указана>';vi='<Chưa chỉ ra mặt hàng>'");
	EndIf;
	
	Presentation = String(TreeRow.ProductsAndServices);
	If ValueIsFilled(TreeRow.Characteristic) Then
		Presentation = Presentation + ", " + String(TreeRow.Characteristic);
	EndIf; 
	If ValueIsFilled(TreeRow.Batch) Then
		Presentation = Presentation + ", " + String(TreeRow.Batch);
	EndIf; 
	If ValueIsFilled(TreeRow.Specification) Then
		Presentation = Presentation + ", " + String(TreeRow.Specification);
	EndIf; 
	
	Return Presentation;
	
EndFunction 

&AtClientAtServerNoContext
Function OrdersPresentation(TreeRow)
	
	If Not ValueIsFilled(TreeRow.CustomerOrder) And Not ValueIsFilled(TreeRow.ProductionOrder) Then
		Return NStr("en='<without order>';ru='<Без заказа>';vi='<Không có đơn hàng>'");
	EndIf;
	
	FillBothOrders = (ValueIsFilled(TreeRow.CustomerOrder) And ValueIsFilled(TreeRow.ProductionOrder));
	
	Presentation = "";
	If ValueIsFilled(TreeRow.CustomerOrder) Then
		Presentation = Presentation + ?(FillBothOrders, StrReplace(String(TreeRow.CustomerOrder), "Order ", ""), String(TreeRow.CustomerOrder));
		If ValueIsFilled(TreeRow.Counterparty) Then
			Presentation = Presentation + " (" + String(TreeRow.Counterparty) + ")";
		EndIf; 
	EndIf; 
	If ValueIsFilled(TreeRow.ProductionOrder) Then
		Presentation = Presentation + ?(FillBothOrders, ", ", "") + ?(FillBothOrders, StrReplace(String(TreeRow.ProductionOrder), "Order ", ""), String(TreeRow.ProductionOrder));
	EndIf; 
	
	Presentation = ?(FillBothOrders, NStr("en = 'Orders:'; ru = 'Заказы:'; vi = 'Đơn hàng:'"), "") + Presentation;
	
	Return Presentation;
	
EndFunction 

&AtServerNoContext
Function DocumentsByStage(ProductsAndServices, Characteristic, Batch, Specification, Order, Stage, DocumentName = "InventoryAssembly")
	
	WithoutIBPrefix = Constants.ПредставлениеНомераДокументаБезПрефиксаИнформационнойБазы.Get();
	WithoutUserPrefix = Constants.ПредставлениеНомераДокументаБезПрефиксаПользователя.Get();
	
	Query = New Query;
	Query.SetParameter("Order", Order);
	Query.SetParameter("ProductsAndServices", ProductsAndServices);
	Query.SetParameter("Characteristic", Characteristic);
	Query.SetParameter("Batch", Batch);
	Query.SetParameter("Specification", Specification);
	Query.SetParameter("Stage", Stage);
	Query.Text =
	"SELECT
	|	ProductionStages.Recorder AS Recoreder,
	|	CASE
	|		WHEN ProductionStages.Recorder REFS Document.CustomerOrder
	|			THEN CAST(ProductionStages.Recorder AS Document.CustomerOrder).БУЛЕВО
	|		WHEN ProductionStages.Recorder REFS Document.ProductionOrder
	|			THEN CAST(ProductionStages.Recorder AS Document.ProductionOrder).БУЛЕВО
	|		WHEN ProductionStages.Recorder REFS Document.InventoryAssembly
	|			THEN CAST(ProductionStages.Recorder AS Document.InventoryAssembly).БУЛЕВО
	|		WHEN ProductionStages.Recorder REFS Document.JobSheet
	|			THEN CAST(ProductionStages.Recorder AS Document.JobSheet).БУЛЕВО
	|		ELSE """"
	|	END AS Number,
	|	CASE
	|		WHEN ProductionStages.Recorder REFS Document.CustomerOrder
	|			THEN CAST(ProductionStages.Recorder AS Document.CustomerOrder).СТРОКА
	|		WHEN ProductionStages.Recorder REFS Document.ProductionOrder
	|			THEN CAST(ProductionStages.Recorder AS Document.ProductionOrder).СТРОКА
	|		WHEN ProductionStages.Recorder REFS Document.InventoryAssembly
	|			THEN CAST(ProductionStages.Recorder AS Document.InventoryAssembly).СТРОКА
	|		WHEN ProductionStages.Recorder REFS Document.JobSheet
	|			THEN CAST(ProductionStages.Recorder AS Document.JobSheet).СТРОКА
	|		ELSE DATETIME(1, 1, 1)
	|	END AS Date
	|FROM
	|	AccumulationRegister.ProductionStages AS ProductionStages
	|WHERE
	|	ProductionStages.ORDER = &Order
	|	AND ProductionStages.ProductsAndServices = &ProductsAndServices
	|	AND ProductionStages.ПОЛЕВИДА = &Characteristic
	|	AND ProductionStages.Specification = &Specification
	|	AND ProductionStages.Batch = &Batch
	|	AND ProductionStages.Stage = &Stage
	|	AND ProductionStages.Recorder REFS Document.InventoryAssembly
	|
	|ORDER BY
	|	Date";
	Query.Text = StrReplace(Query.Text, "Document.InventoryAssembly", "Document." + DocumentName);
	Selection = Query.Execute().Select();
	Result = New ValueList;
	While Selection.Next() Do
		DocumentPresentation = StrTemplate(NStr("en = '№%1 от %2'; ru = '№%1 от %2'; vi = '№%1 ngày %2'"), 
		ObjectPrefixationClientServer.GetNumberForPrinting(Selection.Number, WithoutIBPrefix, WithoutUserPrefix),
		Format(Selection.Date, "ДЛФ=D"));
		Result.Add(Selection.Recoreder, DocumentPresentation);	
	EndDo;
	Return Result;  
	
EndFunction

&AtClient
Function ПодразделенияПоЭтапу(Stage)
	
	If TypeOf(CasheDepartments)<>Type("FixedMap")
		Or CasheDepartments.Get(Stage)=Undefined Then
		Return DepartmentsByStage(Stage);
	Else
		Return CasheDepartments.Get(Stage);
	EndIf; 	
	
EndFunction

&AtServer
Function DepartmentsByStage(Stage)
	
	Query = New Query;
	Query.SetParameter("Stage", Stage);
	Query.Text =
	"SELECT
	|	ProductionStructuralUnits.StructuralUnit AS StructuralUnit,
	|	ProductionStructuralUnits.Default AS Default
	|FROM
	|	Catalog.ProductionStages.StructuralUnits AS ProductionStructuralUnits
	|WHERE
	|	ProductionStructuralUnits.Ref = &Stage";
	Selection = Query.Execute().Select();
	DepartmentList = New ValueList;
	While Selection.Next() Do
		DepartmentList.Add(Selection.StructuralUnit, , Selection.Default);
	EndDo; 
	
	If TypeOf(CasheDepartments)=Type("FixedMap") Then
		Cache = New Map(CasheDepartments);
	Else
		Cache = New Map;
	EndIf; 
	Cache.Insert(Stage, DepartmentList);
	CasheDepartments = New FixedMap(Cache);
	
	Return DepartmentList;
	
EndFunction

&AtClientAtServerNoContext
Function EqualValue(OrderRow, Name, StageNumber = Undefined)
	
	If OrderRow.GetItems().Count()<=1 Then
		Return Undefined;
	EndIf; 
	
	If StageNumber=Undefined Then
		FieldName = Name;
	Else
		FieldName = Name + StageNumber;
	EndIf; 
	
	If StageNumber<>Undefined And (OrderRow["StageDisable" + StageNumber] Or OrderRow["StageHide" + StageNumber]) Then
		Return Undefined;
	EndIf; 
	
	FirstValue = Undefined;
	For Each SubString In OrderRow.GetItems() Do
		If FirstValue=Undefined Then
			FirstValue = SubString[FieldName];
		ElsIf FirstValue<>SubString[FieldName] Then 
			FirstValue = Undefined;
			Break;
		EndIf; 
	EndDo; 
	
	Return FirstValue;
	
EndFunction

#EndRegion

#Region FiltreMarks

&AtClient
Procedure СвернутьРазвернутьПанельОтборов(Item)
	
	NewVisibleValue = Not Items.FiltersSettingsAndExtraInfo.Visible;
	WorkWithFiltersClient.CollapseExpandFiltesPanel(ThisObject, NewVisibleValue);
	ОбновитьЗаголовок();
		
EndProcedure

&AtClient
Procedure ProductionDateOnChange(Item)
	
	Notification = New NotifyDescription("ProductionDateOnChangeCompletion", ThisObject);
	CheckModificationAndContinue(Notification);
	
EndProcedure

&AtClient
Procedure ProductionDateOnChangeCompletion(Result, AdditionalData) Export
	
	If Result<>DialogReturnCode.OK Then
		ProductionDate = ProductionDateBefore;
		Return;
	EndIf;
	
	ProductionDateBefore = ProductionDate;
	
	If IsProductionKind And Not ShowDescription Then
		FillOrderTreeClient();
	EndIf; 
	
	ОбновитьЗаголовок();
	
EndProcedure

&AtClient
Procedure ТолькоЗапланированныеПриИзменении(Item)
	
	If OnlyPlaned And Not ValueIsFilled(PlaningDate) Then
		Return;
	EndIf; 
	
	Notification = New NotifyDescription("OnlyPlanedOnChangeCompletion", ThisObject);
	CheckModificationAndContinue(Notification);
	
EndProcedure

&AtClient
Procedure OnlyPlanedOnChangeCompletion(Result, AdditionalData) Export
	
	If Result<>DialogReturnCode.OK Then
		OnlyPlaned = Not OnlyPlaned;
		Return;
	EndIf; 
	
	If IsProductionKind And Not ShowDescription Then
		FillOrderTreeClient();
	EndIf; 
	
	FormManagment(ThisObject);
	
EndProcedure

&AtClient
Procedure ДатаПланированияПриИзменении(Item)
	
	Notification = New NotifyDescription("PlaningDateOnChangeCompleting", ThisObject);
	CheckModificationAndContinue(Notification);
	
EndProcedure

&AtClient
Procedure PlaningDateOnChangeCompleting(Result, AdditionalData) Export
	
	If Result<>DialogReturnCode.OK Then
		PlaningDate = PlaningDateBefore;
		Return;
	EndIf;
	PlaningDateBefore = PlaningDate;
	
	If IsProductionKind And Not ShowDescription Then
		FillOrderTreeClient();
	EndIf; 
	
	FormManagment(ThisObject);
	
EndProcedure

&AtClient
Procedure ТолькоПоэтапноеПриИзменении(Item)
	
	Notification = New NotifyDescription("OnlyStagedOnChangeCompleting", ThisObject);
	CheckModificationAndContinue(Notification);
	
EndProcedure

&AtClient
Procedure OnlyStagedOnChangeCompleting(Result, AdditionalData) Export
	
	If Result<>DialogReturnCode.OK Then
		OnlyStage = Not OnlyStage;
		Return;
	EndIf; 
	
	If IsProductionKind And Not ShowDescription Then
		FillOrderTreeClient();
	EndIf; 
	
EndProcedure

&AtClient
Procedure ОтборЗаказНаПроизводствоОбработкаВыбора(Item, SelectedValue, StandardProcessing)
	
	If Not ValueIsFilled(SelectedValue) Then
		Return;
	EndIf;

	StructureData = New Structure;
	StructureData.Insert("SelectedValue", SelectedValue);
	StructureData.Insert("ParentName", Item.Parent.Name);
	Notification = New NotifyDescription("FilterProductionOrderChoiceProcessing", ThisObject, StructureData);
	CheckModificationAndContinue(Notification);
	SelectedValue = Undefined;
	
EndProcedure

&AtClient
Procedure FilterProductionOrderChoiceProcessing(Result, AdditionalData) Export
	
	If Result<>DialogReturnCode.OK Then
		FilterProductionOrder = Undefined;
		Return;
	EndIf; 
	
	ValueDescription = StrReplace(String(AdditionalData.SelectedValue), NStr("En='null';vi='không'"), NStr("En='null';vi='không'"));
	SetupMarkAndFilter("ProductionOrder", AdditionalData.ParentName, AdditionalData.SelectedValue, ValueDescription);
	ExpandOrderTree();
	
EndProcedure

&AtClient
Procedure ОтборКонтрагентОбработкаВыбора(Item, SelectedValue, StandardProcessing)
	
	If Not ValueIsFilled(SelectedValue) Then
		Return;
	EndIf;

	StructureData = New Structure;
	StructureData.Insert("SelectedValue", SelectedValue);
	StructureData.Insert("ParentName", Item.Parent.Name);
	Notification = New NotifyDescription("FilterCounterpartyChoiceProcessingCompletion", ThisObject, StructureData);
	CheckModificationAndContinue(Notification);
	SelectedValue = Undefined;
	
EndProcedure

&AtClient
Procedure FilterCounterpartyChoiceProcessingCompletion(Result, AdditionalData) Export
	
	If Result<>DialogReturnCode.OK Then
		FilterCounterparty = Undefined;
		Return;
	EndIf; 
	
	SetupMarkAndFilter("Counterparty", AdditionalData.ParentName, AdditionalData.SelectedValue);
	ExpandOrderTree(); 
	
EndProcedure

&AtClient
Procedure ОтборЗаказПокупателяОбработкаВыбора(Item, SelectedValue, StandardProcessing)
	
	If Not ValueIsFilled(SelectedValue) Then
		Return;
	EndIf;
	
	StructureData = New Structure;
	StructureData.Insert("SelectedValue", SelectedValue);
	StructureData.Insert("ParentName", Item.Parent.Name);
	Notification = New NotifyDescription("FilterCustomerOrderChoiceProcessingCompletion", ThisObject, StructureData);
	CheckModificationAndContinue(Notification);
	SelectedValue = Undefined;
	
EndProcedure

&AtClient
Procedure FilterCustomerOrderChoiceProcessingCompletion(Result, AdditionalData) Export
	
	If Result<>DialogReturnCode.OK Then
		FilterCustomerOrder = Undefined;
		Return;
	EndIf; 
	
	ValueDescription = StrReplace(String(AdditionalData.SelectedValue), NStr("En='null';vi='không'"), NStr("En='null';vi='không'"));
	SetupMarkAndFilter("CustomerOrder", AdditionalData.ParentName, AdditionalData.SelectedValue, ValueDescription);
	ExpandOrderTree(); 
	
EndProcedure

&AtClient
Procedure ОтборВидПроизводстваОбработкаВыбора(Item, SelectedValue, StandardProcessing)
	
	If Not ValueIsFilled(SelectedValue) Then
		Return;
	EndIf;

	StructureData = New Structure;
	StructureData.Insert("SelectedValue", SelectedValue);
	StructureData.Insert("ParentName", Item.Parent.Name);
	Notification = New NotifyDescription("FilterProductionKindChoiceProcessingCompletion", ThisObject, StructureData);
	CheckModificationAndContinue(Notification);
	SelectedValue = Undefined;
	
EndProcedure

&AtClient
Procedure FilterProductionKindChoiceProcessingCompletion(Result, AdditionalData) Export
	
	If Result<>DialogReturnCode.OK Then
		FilterProductsAndServices = Undefined;
		Return;
	EndIf; 
	
	SetupMarkAndFilter("ProductionKind", AdditionalData.ParentName, AdditionalData.SelectedValue);
	ExpandOrderTree(); 
	
EndProcedure

&AtClient
Procedure ОтборНоменклатураОбработкаВыбора(Item, SelectedValue, StandardProcessing)
	
	If Not ValueIsFilled(SelectedValue) Then
		Return;
	EndIf;

	StructureData = New Structure;
	StructureData.Insert("SelectedValue", SelectedValue);
	StructureData.Insert("ParentName", Item.Parent.Name);
	Notification = New NotifyDescription("FilterProductionAndServicesChoiceProcessingCompletion", ThisObject, StructureData);
	CheckModificationAndContinue(Notification);
	SelectedValue = Undefined;
	
EndProcedure

&AtClient
Procedure FilterProductionAndServicesChoiceProcessingCompletion(Result, AdditionalData) Export
	
	If Result<>DialogReturnCode.OK Then
		FilterProductsAndServices = Undefined;
		Return;
	EndIf; 
	
	SetupMarkAndFilter("ProductsAndServices", AdditionalData.ParentName, AdditionalData.SelectedValue);
	ExpandOrderTree(); 
	
EndProcedure

&AtClient
Procedure ИзготовительПриИзменении(Item)
	
	FormManagment(ThisObject);
	
EndProcedure

&AtClient
Procedure ИсполнительПриИзменении(Item)
	
	FormManagment(ThisObject);
	
EndProcedure

&AtClient
Procedure ОтметитьЭтапПриИзменении(Item)
	
	FormManagment(ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_LabelURLProcessing(Item, URLRefFormatingString, StandardProcessing)
	
	StandardProcessing = False;
	MarkId = Mid(Item.Name, StrLen("Label_")+1);
	StructureData = New Structure;
	StructureData.Insert("MarkId", MarkId);
	Notification = New NotifyDescription("Attachable_MarkURLProcessing", ThisObject, StructureData);
	CheckModificationAndContinue(Notification);
	
EndProcedure

&AtClient
Procedure Attachable_MarkURLProcessing(Result, AdditionalData) Export
	
	If Result<>DialogReturnCode.OK Then
		Return;
	EndIf; 
	
	DeleteFilterMark(AdditionalData.MarkId);
	ExpandOrderTree(); 
	
EndProcedure

&AtServer
Procedure SetupMarkAndFilter(ListFilterFieldName, GroupMarkParent, SelectedValue, ValueDescription="")
	
	If ValueDescription="" Then
		ValueDescription=String(SelectedValue);
	EndIf; 
	
	WorkWithFilters.AttachFilterLabel(ThisObject, ListFilterFieldName, GroupMarkParent, SelectedValue, ValueDescription);
	
	If Not IsProductionKind Or ShowDescription Then
		Return;
	EndIf; 
	
	FillOrderTree();
	
EndProcedure

&AtServer
Procedure DeleteFilterMark(MarkId)
	
	MarksRow = LabelData[Number(MarkId)];
	FilterFieldName = MarksRow.FilterFieldName;

	GroupFormListForAddDelete = WorkWithFilters.ListParentsGroupName(LabelData);
	LabelData.Delete(MarksRow);
	WorkWithFilters.RefreshLabelItems(ThisObject, GroupFormListForAddDelete);
	WorkWithFilters.SetTitleRightPanelMobileClient(ThisObject);
	FillOrderTree();

EndProcedure

&AtServer
Procedure SaveFilterSettings()
	
	ObjectKeyName = StrReplace(FormName,".","");
	
	WorkWithFilters.SaveFilterSettings(ThisObject, , , , False);
	CommonUse.CommonSettingsStorageSave(ObjectKeyName, ObjectKeyName+"_OnlyPlanned", OnlyPlaned);
	CommonUse.CommonSettingsStorageSave(ObjectKeyName, ObjectKeyName+"_OnlyStaged", OnlyStage);
	
EndProcedure

&AtServer
Procedure RestoreFilterSettings()
	
	DataCompositionSchema = DataProcessors.StageManagement.GetTemplate("FillingScheme");
	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
	SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	ComposerSettings = SettingsComposer.Settings;
	
	ObjectKeyName = StrReplace(FormName,".","");
	
	//Отбор по полям правой панели
	SavedValue = CommonUse.SystemSettingsStorageImport(ObjectKeyName, ObjectKeyName+"_MarkData");
	CurrentListFilterExist = False;
	
	If ValueIsFilled(SavedValue) Then
		
		//Проверить сохраненные отборы, удалить строки, которых нет ДоступныхПоляхКомпоновкиДанных
		If SavedValue.Columns.Find("QueryParameterName")=Undefined Then
			AvailableFieldArrayDataComposition = New Array;
			For Each FilterField In ComposerSettings.FilterAvailableFields.Items Do
				AvailableFieldArrayDataComposition.Add(String(FilterField.Field));
			EndDo;
			DeleteFiltersArray = New Array;
			For Each SavedFilterField In SavedValue Do
				If StrFind(SavedFilterField.FilterFieldName,".")<>0 Then
					//Для полей табличной части, которые представлены через точку
					FieldsArray = StrSplit(SavedFilterField.FilterFieldName, ".");
					If FieldsArray.Count()>0 Then
						SavedFilterFieldName = FieldsArray[0];
					EndIf;
				Else
					SavedFilterFieldName = SavedFilterField.FilterFieldName;
				EndIf;
				If AvailableFieldArrayDataComposition.Find(SavedFilterFieldName)=Undefined Then
					DeleteFiltersArray.Add(SavedFilterField);
				EndIf;
			EndDo;
			For Each RowDelete In DeleteFiltersArray Do
				SavedValue.Delete(RowDelete);
			EndDo;
		EndIf; 
		
		LabelData.Load(SavedValue);
		
		WorkWithFilters.RefreshLabelItems(ThisObject);
		
	EndIf;
	
	SavedValue = CommonUse.CommonSettingsStorageImport(ObjectKeyName, ObjectKeyName+"_OnlyPlanned");
	If SavedValue=True Then
		OnlyPlaned = SavedValue;
		CurrentListFilterExist = True;
	EndIf;
	
	SavedValue = CommonUse.CommonSettingsStorageImport(ObjectKeyName, ObjectKeyName+"_OnlyStaged");
	If SavedValue=True Then
		OnlyStage = SavedValue;
		CurrentListFilterExist = True;
	EndIf;
	
	//Видимость панели отборов
	If Not CurrentListFilterExist Then
		SavedValue = CommonUse.CommonSettingsStorageImport(ObjectKeyName, ObjectKeyName+"_VisibleFilterPanel", True);
		If ValueIsFilled(SavedValue) Then
			WorkWithFilters.CollapseExpandFiltersAtServer(ThisObject, SavedValue);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormOutsideManagement

&AtServer
Procedure UpdateConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	For ii = 1 To StagesQuantity Do
		
		NewConditionalAppearance = ConditionalAppearance.Items.Add();
		WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "OrdersStageLabel" + ii);
		WorkWithForm.ADDDataCompositionFilterItem(NewConditionalAppearance.Filter, "Orders.StageDisable" + ii, True);
		WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "ReadOnly", True);
		
		NewConditionalAppearance = ConditionalAppearance.Items.Add();
		WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "OrdersStageTitle" + ii);
		ItemFilter = NewConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Orders.StageLabel" + ii);
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
		ItemFilter.RightValue = New DataCompositionField("Orders.StageLabelOld" + ii);
		WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Font", New Font(New Font, , , True));
		
		// Структурная единица
		If UseStructuralUnits And PerformByDifferentDepartments Then
			
			NewConditionalAppearance = ConditionalAppearance.Items.Add();
			WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "OrdersStageStructuralUnit" + ii);
			WorkWithForm.ADDDataCompositionFilterItem(NewConditionalAppearance.Filter, "Orders.Stage" + ii, Catalogs.ProductionStages.ProductionComplete);
			WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Visible", False);
			
			NewConditionalAppearance = ConditionalAppearance.Items.Add();
			WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "OrdersStageStructuralUnit" + ii);
			WorkWithForm.ADDDataCompositionFilterItem(NewConditionalAppearance.Filter, "Orders.StructuralUnit" + ii, Undefined, DataCompositionComparisonType.NotFilled);
			WorkWithForm.ADDDataCompositionFilterItem(NewConditionalAppearance.Filter, "Orders.Level", 2);
			WorkWithForm.ADDDataCompositionFilterItem(NewConditionalAppearance.Filter, "Orders.StageLabel" + ii, True);
			WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "MarkIncomplete", True);
			
			NewConditionalAppearance = ConditionalAppearance.Items.Add();
			WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "OrdersStageStructuralUnit" + ii);
			ConditionGroup = WorkWithForm.AddDataCompositionFilterItemGroup(NewConditionalAppearance.Filter, DataCompositionFilterItemsGroupType.OrGroup);
			WorkWithForm.ADDDataCompositionFilterItem(ConditionGroup, "Orders.InventoryAssembly" + ii, Undefined, DataCompositionComparisonType.Filled);
			WorkWithForm.ADDDataCompositionFilterItem(ConditionGroup, "Orders.StageLabelOld" + ii, True);
			WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Visible", False);
			
			NewConditionalAppearance = ConditionalAppearance.Items.Add();
			WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "OrdersStageStructuralUnit" + ii);
			ConditionGroup = WorkWithForm.AddDataCompositionFilterItemGroup(NewConditionalAppearance.Filter, DataCompositionFilterItemsGroupType.OrGroup);
			WorkWithForm.ADDDataCompositionFilterItem(ConditionGroup, "Orders.StageDisable" + ii, True);
			WorkWithForm.ADDDataCompositionFilterItem(ConditionGroup, "Orders.StageLabel" + ii, False);
			WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "ReadOnly", True);
			WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.InaccessibleDataColor);
			
		EndIf; 
		
		// Исполнитель
		If UseTechnicalOperation Then
			
			NewConditionalAppearance = ConditionalAppearance.Items.Add();
			WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "OrdersStagePerformer" + ii);
			WorkWithForm.ADDDataCompositionFilterItem(NewConditionalAppearance.Filter, "Orders.Performer" + ii, Undefined, DataCompositionComparisonType.NotFilled);
			WorkWithForm.ADDDataCompositionFilterItem(NewConditionalAppearance.Filter, "Orders.StageLabel" + ii, True);
			WorkWithForm.ADDDataCompositionFilterItem(NewConditionalAppearance.Filter, "Orders.ChoosePerformer" + ii, True);
			WorkWithForm.ADDDataCompositionFilterItem(NewConditionalAppearance.Filter, "Orders.Level", 2);
			WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "MarkIncomplete", True);
			
			NewConditionalAppearance = ConditionalAppearance.Items.Add();
			WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "OrdersStagePerformer" + ii);
			ConditionGroup = WorkWithForm.AddDataCompositionFilterItemGroup(NewConditionalAppearance.Filter, DataCompositionFilterItemsGroupType.OrGroup);
			WorkWithForm.ADDDataCompositionFilterItem(ConditionGroup, "Orders.StageLabel" + ii, False);
			WorkWithForm.ADDDataCompositionFilterItem(ConditionGroup, "Orders.StageDisable" + ii, True);
			WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "ReadOnly", True);
			WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.InaccessibleDataColor);
			
			NewConditionalAppearance = ConditionalAppearance.Items.Add();
			WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "OrdersStagePerformer" + ii);
			ConditionGroup = WorkWithForm.AddDataCompositionFilterItemGroup(NewConditionalAppearance.Filter, DataCompositionFilterItemsGroupType.OrGroup);
			WorkWithForm.ADDDataCompositionFilterItem(ConditionGroup, "Orders.StageDisable" + ii, True);
			WorkWithForm.ADDDataCompositionFilterItem(ConditionGroup, "Orders.PerformerHide" + ii, True);
			WorkWithForm.ADDDataCompositionFilterItem(ConditionGroup, "Orders.ChoosePerformer" + ii, False);
			WorkWithForm.ADDDataCompositionFilterItem(ConditionGroup, "Orders.JobSheet" + ii, Undefined, DataCompositionComparisonType.Filled);
			WorkWithForm.ADDDataCompositionFilterItem(ConditionGroup, "Orders.StageLabelOld" + ii, True);
			WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Visible", False);
			
			NewConditionalAppearance = ConditionalAppearance.Items.Add();
			WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "OrdersStagePerformerDescription" + ii);
			ConditionGroup = WorkWithForm.AddDataCompositionFilterItemGroup(NewConditionalAppearance.Filter, DataCompositionFilterItemsGroupType.OrGroup);
			WorkWithForm.ADDDataCompositionFilterItem(ConditionGroup, "Orders.StageDisable" + ii, True);
			WorkWithForm.ADDDataCompositionFilterItem(ConditionGroup, "Orders.PerformerHide" + ii, True);
			WorkWithForm.ADDDataCompositionFilterItem(ConditionGroup, "Orders.ChoosePerformer" + ii, True);
			WorkWithForm.ADDDataCompositionFilterItem(ConditionGroup, "Orders.JobSheet" + ii, Undefined, DataCompositionComparisonType.Filled);
			WorkWithForm.ADDDataCompositionFilterItem(ConditionGroup, "Orders.StageLabelOld" + ii, True);
			WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Visible", False);
			
		EndIf; 
		
		// Производство
		NewConditionalAppearance = ConditionalAppearance.Items.Add();
		WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "OrdersStageInventoryAssemblyDescription" + ii);
		WorkWithForm.ADDDataCompositionFilterItem(NewConditionalAppearance.Filter, "Orders.InventoryAssemblyDescription" + ii, Undefined, DataCompositionComparisonType.NotFilled);
		// Для скрытых этапов элемент используется как разделитель
		WorkWithForm.ADDDataCompositionFilterItem(NewConditionalAppearance.Filter, "Orders.StageHide" + ii, False);
		WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Visible", False);
		
		// Сдельный наряд
		NewConditionalAppearance = ConditionalAppearance.Items.Add();
		WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "OrdersStageJobSheetDescription" + ii);
		WorkWithForm.ADDDataCompositionFilterItem(NewConditionalAppearance.Filter, "Orders.JobSheetDescription" + ii, Undefined, DataCompositionComparisonType.NotFilled);
		ConditionGroup = WorkWithForm.AddDataCompositionFilterItemGroup(NewConditionalAppearance.Filter, DataCompositionFilterItemsGroupType.OrGroup);
		WorkWithForm.ADDDataCompositionFilterItem(ConditionGroup, "Orders.StageDisable" + ii, False);
		WorkWithForm.ADDDataCompositionFilterItem(ConditionGroup, "Orders.PerformerHide" + ii, True);
		WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Visible", False);
		
		// Скрытые этапы
		NewConditionalAppearance = ConditionalAppearance.Items.Add();
		WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "OrdersStageLabel" + ii);
		WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "OrdersStageTitle" + ii);
		WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "OrdersStageStructuralUnit" + ii);
		WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "OrdersStagePerformer" + ii);
		WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "OrdersStageJobSheetDescription" + ii);
		WorkWithForm.ADDDataCompositionFilterItem(NewConditionalAppearance.Filter, "Orders.StageHide" + ii, True);
		WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Visible", False);
	
	EndDo; 
	
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "Orders");
	WorkWithForm.ADDDataCompositionFilterItem(NewConditionalAppearance.Filter, "Orders.Level", 1);
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "BackColor", StyleColors.ReportGroupBackground1);
	
	// Структурная единица завершения производства
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "OrdersStructuralUnit");
	WorkWithForm.ADDDataCompositionFilterItem(NewConditionalAppearance.Filter, "Orders.Level", 2);
	WorkWithForm.ADDDataCompositionFilterItem(NewConditionalAppearance.Filter, "Orders.IsPerformedStages", True);
	WorkWithForm.ADDDataCompositionFilterItem(NewConditionalAppearance.Filter, "Orders.StructuralUnit", Undefined, DataCompositionComparisonType.NotFilled);
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "MarkIncomplete", True);
	
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "OrdersStructuralUnit");
	ConditionGroup = WorkWithForm.AddDataCompositionFilterItemGroup(NewConditionalAppearance.Filter, DataCompositionFilterItemsGroupType.OrGroup);
	WorkWithForm.ADDDataCompositionFilterItem(ConditionGroup, "Orders.IsUnavailableStages", True);
	WorkWithForm.ADDDataCompositionFilterItem(ConditionGroup, "Orders.IsSavedDocuments", True);
	WorkWithForm.ADDDataCompositionFilterItem(ConditionGroup, "Orders.ProductionOrder", Documents.ProductionOrder.EmptyRef(), DataCompositionComparisonType.NotEqual);
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "ReadOnly", True);
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.UnavailableCellTextColor);
	
EndProcedure

&AtClient
Procedure ОбновитьЗаголовок()
	
	Title = NStr("en='Stage management';ru='Выполнение этапов';vi='Quản lý công đoạn'")
	+ ?(Not Items.FiltersSettingsAndExtraInfo.Visible, ": " + Format(ProductionDate, "DLF=D"), "");
	
EndProcedure

&AtClientAtServerNoContext
Procedure FormManagment(Form)
	
	Items = Form.Items;
	CommonUseClientServer.SetFormItemProperty(Items, "PlaningDate", "ReadOnly", Not Form.OnlyPlaned);
	CommonUseClientServer.SetFormItemProperty(Items, "FillManufacturer", "Enabled", ValueIsFilled(Form.Manufacturer) And Not Form.ShowDescription);	
	CommonUseClientServer.SetFormItemProperty(Items, "FillPerfomer", "Enabled", ValueIsFilled(Form.Performer) And Not Form.ShowDescription);
	CommonUseClientServer.SetFormItemProperty(Items, "PerfomStage", "Enabled", ValueIsFilled(Form.MarkStage) And Not Form.ShowDescription);
	If Form.PerformByDifferentDepartments Then
		CommonUseClientServer.SetFormItemProperty(Items, "OrdersStructuralUnit", "ChoiceHistoryOnInput", ChoiceHistoryOnInput.DontUse);
	EndIf; 
	
EndProcedure

#EndRegion

#Region BackgroundJob

&AtClient
Procedure RunBackgroundJob()
	
	SetupFormAvailable(False);
	ClearMessages();
	
	Job = JobFormProductionDocuments();
	If Job=Undefined Then
		Return;
	EndIf; 
	
	WaitingParameters = LongActionsClient.WaitingParameters(ThisObject);
	WaitingParameters.ShowWaitingWindow = False;
	WaitingParameters.ShowProgress = True;
	WaitingParameters.ProgressNotification = New NotifyDescription("ProgressFormDocuments", ThisObject); 
	
	LongActionsClient.WaitForCompletion(
		Job,
		New NotifyDescription ("HandleDocumentForm", ThisObject),
		WaitingParameters);
	
EndProcedure

&AtClient
Procedure ProgressFormDocuments(Progress, AdditionalParameters) Export
	
	If Progress = Undefined Then
		Return;
	EndIf;
	
	If Progress.Status <> "Perfoming" Or Progress.Progress=Undefined Then
		Return;
	EndIf;
	
	ProgressBar = Progress.Progress.Percent;
	LongOperationStage = Progress.Progress.Text;
	LongOperationObject = Progress.Progress.AdditionalParameters;
	
EndProcedure

&AtClient
Procedure HandleDocumentForm(Result, Parameters) Export
	
	SetupFormAvailable(True);
	
	If Result.Status <> "Completed" Then
		If Result.Property("ShortErrorDescription") Then
			CommonUseClientServer.MessageToUser(
			Result.ShortErrorDescription);
		EndIf; 
		Items.PagesBackgroundJobStatus.CurrentPage = Items.JobFailed;
		Return;
	EndIf;
	
	WithoutErrors = HandleFormDocunemtsAtServer(Result, Parameters);
	If WithoutErrors Then
		FillOrderTreeClient();
	Else
		ExpandOrderTree();
	EndIf; 
	CommonUseClientServer.SetFormItemProperty(Items, "PagesBackgroundJobStatus", "Visible", False);
	
EndProcedure

&AtServer
Function HandleFormDocunemtsAtServer(Result, Parameters)
	
	PerfomingResult = GetFromTempStorage(Result.ResultAddress);
	If Not TypeOf(PerfomingResult)=Type("Structure") Then
		Return True;
	EndIf; 
	If PerfomingResult.Property("Errors") And TypeOf(PerfomingResult.Errors)=Type("ValueList") And PerfomingResult.Errors.Count()>0 Then
		For Each Error In PerfomingResult.Errors Do
			CommonUseClientServer.MessageToUser(
				Error.Presentation,
				Error.Value);
		EndDo;
		Items.PagesBackgroundJobStatus.CurrentPage = Items.JobFailed;
		If PerfomingResult.Property("Orders") And TypeOf(PerfomingResult.Orders)=Type("ValueTree") Then
			ValueToFormAttribute(PerfomingResult.Orders, "Orders");
		EndIf; 
		Return False;
	ElsIf PerfomingResult.Property("CreatedDocuments") And PerfomingResult.Property("ChangedDocuments") Then
		MessageText = "";
		If ValueIsFilled(PerfomingResult.CreatedDocuments) Then
			MessageText = ?(PerfomingResult.CreatedDocuments=1, NStr("ru = 'создан %1 документ';
																			|en = 'create %1 document';vi = 'tạo tài liệu %1';"), ?(PerfomingResult.CreatedDocuments<5, NStr("ru = 'создано %1 документа';
																																						|en = 'create %1 documents'; vi = 'tạo tài liệu %1'; "), NStr("ru = 'создано %1 документов';
																																															|en = 'create %1 documents'; vi = 'tạo tài liệu %1';")));
			MessageText = StrTemplate(MessageText, PerfomingResult.CreatedDocuments);
		EndIf; 
		If ValueIsFilled(PerfomingResult.ChangedDocuments) Then
			MessageText = MessageText + ?(IsBlankString(MessageText), "", ", ") + ?(PerfomingResult.ChangedDocuments=1, NStr("ru = 'изменен %1 документ';
																																		|en = 'change %1 document';vi = 'thay đổi tài liệu %1';"), ?(PerfomingResult.ChangedDocuments<5, NStr("ru = 'изменено %1 документа';
																																																						|en = 'change %1 documents';vi = 'thay đổi tài liệu %1'; "), NStr("ru = 'изменено %1 документов';
																																																															|en = 'change %1 documents';vi = 'thay đổi tài liệu %1';")));
			MessageText = StrTemplate(MessageText, PerfomingResult.ChangedDocuments);
		EndIf; 
		If Not IsBlankString(MessageText) Then
			Message = New UserMessage;
			Message.Text = NStr("ru = 'Выполнено успешно, ';
									|en = 'Success, ';
									|vi = 'Sự thành công, ';") + MessageText;
			Message.Message();
		EndIf; 
	EndIf;
	
	Return True;
	
EndFunction

&AtClient
Procedure SetupFormAvailable(Availability)
	
	ReadOnly = Not Availability;
	CommonUseClientServer.SetFormItemProperty(Items, "Orders", "ReadOnly", Not Availability);
	CommonUseClientServer.SetFormItemProperty(Items, "GroupAllFilters", "Enabled", Availability);
	
EndProcedure

&AtServer
Function JobFormProductionDocuments()
	
	CommonUseClientServer.SetFormItemProperty(Items, "PagesBackgroundJobStatus", "Visible", True);
	Items.PagesBackgroundJobStatus.CurrentPage = Items.JobPerfoming;
	LongOperationObject = "";
	ProgressBar = 0;
	
	CompletingParameters = LongActions.AttributesExecuteInBackground(UUID);
	CompletingParameters.WaitForCompletion = 0;
	
	PlanTree = FormAttributeToValue("Orders");
	
	JobParameters = New Structure;
	JobParameters.Insert("Orders", PlanTree);
	JobParameters.Insert("StagesQuantity", StagesQuantity);
	JobParameters.Insert("ProductionDate", ProductionDate);
	JobParameters.Insert("Author", Users.CurrentUser());
	
	Result = LongActions.ExecuteBackground(
		"DataProcessors.StageManagement.FormDocuments",
		JobParameters,
		CompletingParameters);
	
	Return Result;
	
EndFunction

#EndRegion
