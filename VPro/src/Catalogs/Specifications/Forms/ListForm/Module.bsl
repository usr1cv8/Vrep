
#Region FormEventsHandlers

&AtServer
// Процедура - обработчик события ПриСозданииНаСервере.
//
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then // Возврат при получении формы для анализа.
		Return;
	EndIf;
	
	SetConditionalAppearance();
	
	If Parameters.Property("Filter") And Parameters.Filter.Property("Owner") Then
		
		ProductsAndServices = Parameters.Filter.Owner;
		
		UseSubsystemProduction = Constants.FunctionalOptionUseSubsystemProduction.Get();
		UseWorkSubsystem = Constants.FunctionalOptionUseWorkSubsystem.Get();
		
		AttributeValues = CommonUse.ObjectAttributesValues(ProductsAndServices, "ProductsAndServicesType");
	
		If Not ValueIsFilled(ProductsAndServices)
			Or AttributeValues.ProductsAndServicesType = Enums.ProductsAndServicesTypes.WorkKind
			Or AttributeValues.ProductsAndServicesType = Enums.ProductsAndServicesTypes.Service
			Or AttributeValues.ProductsAndServicesType = Enums.ProductsAndServicesTypes.Operation Then
			
			AutoTitle = False;
			If UseSubsystemProduction And UseWorkSubsystem Then
				Title = NStr("en='Specifications are stored only for stocks and works';ru='Спецификации хранятся только для запасов и работ';vi='Chỉ lưu bảng kê chi tiết vật tư và công việc'");
			ElsIf UseSubsystemProduction Then
				Title = NStr("en='Specifications are only stored for stocks';ru='Спецификации хранятся только для запасов';vi='Chỉ lưu bảng kê chi tiết vật tư'");
			Else
				Title = NStr("en='Specifications are only stored for work';ru='Спецификации хранятся только для работ';vi='Chỉ lưu bảng kê chi tiết công việc'");
			EndIf;
			Items.List.ReadOnly = True;
			
		ElsIf AttributeValues.ProductsAndServicesType = Enums.ProductsAndServicesTypes.InventoryItem And Not UseSubsystemProduction Then
			
			AutoTitle = False;
			Title = NStr("en='Specifications are only stored for work';ru='Спецификации хранятся только для работ';vi='Chỉ lưu bảng kê chi tiết công việc'");
			Items.List.ReadOnly = True;
			
		ElsIf AttributeValues.ProductsAndServicesType = Enums.ProductsAndServicesTypes.Work And Not UseWorkSubsystem Then
			
			AutoTitle = False;
			Title = NStr("en='Specifications are only stored for stocks';ru='Спецификации хранятся только для запасов';vi='Chỉ lưu bảng kê chi tiết vật tư'");
			Items.List.ReadOnly = True;
			
		EndIf;
		
	EndIf;
	
	//УНФ.ОтборыСписка
	WorkWithFilters.RestoreFilterSettings(ThisObject, List, , , , , False);
	DownloadNonstandardFilters();
	//Конец УНФ.ОтборыСписка
	
	If Not GetFunctionalOption("UseTechOperations") Then
		Items.FilterMaterialOperation.InputHint = NStr("en='Material';ru='Материал';vi='Nguyên vật liệu'");
	EndIf;
	If Not GetFunctionalOption("UseProductionStages") Then
		Items.FilterStage.Visible = False;
	EndIf; 
	
	If ValueIsFilled(ProductsAndServices) Then
		CommonUseClientServer.SetFormItemProperty(Items, "GroupFilterProducts", 	"Visible", False);
		CommonUseClientServer.SetFormItemProperty(Items, "Owner", 				"Visible", False);
	EndIf; 
	
	If Not ShowOrdersSpecifications Then
		EmptyValuesList = New ValueList;
		EmptyValuesList.Add(Undefined);
		EmptyValuesList.Add(Documents.CustomerOrder.EmptyRef());
		EmptyValuesList.Add(Documents.ProductionOrder.EmptyRef());
		SmallBusinessClientServer.SetListFilterItem(List, "DocOrder", EmptyValuesList, 
			True, DataCompositionComparisonType.InList);
	EndIf; 
	
	// StandardSubsystems.ГрупповоеИзменениеОбъектов
	If Items.Find("ListBatchObjectChanging") <> Undefined Then
		
		YouCanEdit = AccessRight("Edit", Metadata.Catalogs.ProductsAndServices);
		CommonUseClientServer.SetFormItemProperty(Items, "ListBatchObjectChanging", "Visible", YouCanEdit);
		
	EndIf;
	// End StandardSubsystems.ГрупповоеИзменениеОбъектов
	
	FormManagement(ThisObject);
	SetFilterInvalid(ThisObject);
	
	// МобильныйКлиент
	If CommonUse.IsMobileClient() Then
		IsMobileClient = True;
	EndIf;
	// Конец МобильныйКлиент
	
EndProcedure // ПриСозданииНаСервере()

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit Then
		//УНФ.ОтборыСписка
		SaveFiltersSettings();
		//Конец УНФ.ОтборыСписка
	EndIf;
	
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

&AtClient
Procedure ShowOrdersSpecificationsOnChange(Item)
	
	FormManagement(ThisObject);
	
	FilterStructure = New Structure;
	FilterStructure.Insert("FilterFieldName", "DocOrder");
	Rows = LabelData.FindRows(FilterStructure);
	For Each LabelRow In Rows Do
		DeleteFilterLabel(LabelData.IndexOf(LabelRow));
	EndDo;
	
	If Not ShowOrdersSpecifications Then
		EmptyValuesList = New ValueList;
		EmptyValuesList.Add(Undefined);
		EmptyValuesList.Add(PredefinedValue("Document.CustomerOrder.EmptyRef"));
		EmptyValuesList.Add(PredefinedValue("Document.ProductionOrder.EmptyRef"));
		SmallBusinessClientServer.SetListFilterItem(List, "DocOrder", EmptyValuesList, 
			True, DataCompositionComparisonType.InList);
	Else
		SmallBusinessClientServer.DeleteListFilterItem(List, "DocOrder");	
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterOwnerChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	If Not ValueIsFilled(SelectedValue) Then
		Return;
	EndIf;
	
	SetListLabelAndFilter("Owner", Item.Parent.Name, SelectedValue);
	SelectedValue = Undefined;

	FormManagement(ThisObject);

EndProcedure

&AtClient
Procedure FilterProductsCategoryChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	If Not ValueIsFilled(SelectedValue) Then
		Return;
	EndIf;
	
	SetListLabelAndFilter("Owner.ProductsAndServicesCategory", Item.Parent.Name, SelectedValue);
	SelectedValue = Undefined;

EndProcedure

&AtClient
Procedure FilterOrderChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	If Not ValueIsFilled(SelectedValue) Then
		Return;
	EndIf;
	
	SetListLabelAndFilter("DocOrder", Item.Parent.Name, SelectedValue);
	SelectedValue = Undefined;

EndProcedure

&AtClient
Procedure FilterMaterialOperationChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	If Not ValueIsFilled(SelectedValue) Then
		Return;
	EndIf;
	
	UpdateNonstandardFilters("Content.Material", SelectedValue, Item.Parent.Name);
	SelectedValue = Undefined;
	
EndProcedure

&AtClient
Procedure FilterStageChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	If Not ValueIsFilled(SelectedValue) Then
		Return;
	EndIf;
	
	SetListLabelAndFilter("ProductionKind.Stages.Stage", Item.Parent.Name, SelectedValue);
	SelectedValue = Undefined;
	
EndProcedure

&AtClient
Procedure FilterProductionKindChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	If Not ValueIsFilled(SelectedValue) Then
		Return;
	EndIf;
	
	SetListLabelAndFilter("ProductionKind", Item.Parent.Name, SelectedValue);
	SelectedValue = Undefined;
	
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

&AtClient
Procedure ChangeSelected(Command)
	
	GroupObjectsChangeClient.ChangeSelected(Items.List);
	
EndProcedure

#EndRegion 

#Region InternalProceduresAndFunctions

&AtServer
Procedure SetConditionalAppearance()

	NewConditionalAppearance = List.ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "NotValid", True, DataCompositionComparisonType.Equal);
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.TabularSectionUnavailableTextColor); 

EndProcedure

&AtClientAtServerNoContext
Procedure FormManagement(Form)
	
	Items = Form.Items;
	
	CommonUseClientServer.SetFormItemProperty(Items, "GroupFilterOrder", 	"Visible", Form.ShowOrdersSpecifications);
	CommonUseClientServer.SetFormItemProperty(Items, "DocOrder", 			"Visible", Form.ShowOrdersSpecifications);
	
	LabelData = Form.LabelData;
	FilterStructure = New Structure;
	FilterStructure.Insert("FilterFieldName", "Owner");
	Form.ChangeBasicSpecification = (LabelData.FindRows(FilterStructure).Count()>0);
	
	CommonUseClientServer.SetFormItemProperty(Items, "FormUseAsBasic", 					"Visible", Form.ChangeBasicSpecification);
	CommonUseClientServer.SetFormItemProperty(Items, "ListContextMenuUseAsBasic", 	"Visible", Form.ChangeBasicSpecification);
	CommonUseClientServer.SetFormItemProperty(Items, "Default", 										"Visible", Form.ChangeBasicSpecification);
	
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

#Region PerformanceMeasurements

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Group)
	
	PerformanceEstimationClientServer.StartTimeMeasurement("FormCreatingSpecifications");
	
EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	PerformanceEstimationClientServer.StartTimeMeasurement("FormOpeningSpecifications");
	
EndProcedure

#EndRegion

#Region FiltersLabels

&AtServer
Procedure SetListLabelAndFilter(ListFilterFieldName, GroupLabelParent, SelectedValue, ValueDescription="")
	
	If ValueDescription="" Then
		ValueDescription=String(SelectedValue);
	EndIf; 
	
	WorkWithFilters.AttachFilterLabel(ThisObject, ListFilterFieldName, GroupLabelParent, SelectedValue, ValueDescription);
	WorkWithFilters.SetListFilter(ThisObject, List, ListFilterFieldName);
	
EndProcedure

&AtServer
Procedure DownloadNonstandardFilters()
	
	ObjectKeyName = StrReplace(FormName,".","");
	ShowOrdersSpecifications = CommonUse.CommonSettingsStorageImport(ObjectKeyName, "ShowOrdersSpecifications", False);
	
	NonstandardFieldsNames = StringFunctionsClientServer.DecomposeStringIntoSubstringsArray("Content.Material");
	For Each DCFieldName In NonstandardFieldsNames Do
		SmallBusinessClientServer.DeleteListFilterItem(List, DCFieldName);
		UpdateNonstandardFilters(DCFieldName);
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateNonstandardFilters(FilterFieldName, SelectedValue = Undefined, GroupName = "")
	
	If SelectedValue<>Undefined Then
		ValueDescription = String(SelectedValue);
		WorkWithFilters.AttachFilterLabel(ThisObject, FilterFieldName, GroupName, SelectedValue, ValueDescription);
	EndIf; 
	
	Values = New ValueList;
	For Each Str In LabelData Do
		If Str.FilterFieldName = FilterFieldName Then
			If TypeOf(Str.Label)=Type("ValueList") Then
				For Each ListValue In Str.Label Do
				    Values.Add(ListValue.Value);
				EndDo; 
			Else	
				Values.Add(Str.Label);
			EndIf;
		EndIf;
	EndDo;
	FilterUsage = Values.Count()>0;
	
	FilterGroup = Undefined; 
	For Each FilterItem In List.SettingsComposer.Settings.Filter.Items Do
		If TypeOf(FilterItem)=Type("DataCompositionFilterItemGroup") And FilterItem.Presentation=FilterFieldName Then
			FilterGroup = FilterItem;
			Break;
		EndIf; 
	EndDo;
	If FilterGroup=Undefined Then
		FilterGroup = List.SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
		FilterGroup.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
		FilterGroup.Presentation = FilterFieldName;
		If FilterFieldName="Content.Material" Then
			NamesOfFields = StringFunctionsClientServer.DecomposeStringIntoSubstringsArray("Content.ProductsAndServices,Operations.Operation");
			For Each FieldName In NamesOfFields Do
				FilterItem = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
				FilterItem.LeftValue = New DataCompositionField(FieldName);
				FilterItem.ComparisonType = DataCompositionComparisonType.InList;
				FilterItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
				FilterItem.Use = True;
			EndDo;
		Else
			Return;
		EndIf; 
	EndIf;
	FilterGroup.Use = FilterUsage;
	For Each FilterItem In FilterGroup.Items Do
		FilterItem.RightValue = Values;
	EndDo; 
	
EndProcedure

&AtClient
Procedure Attachable_LabelURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	LabelID = Mid(Item.Name, StrLen("Label_")+1);
	DeleteFilterLabel(LabelID);
	
EndProcedure

&AtServer
Procedure DeleteFilterLabel(LabelID)
	
	LabelsRow = LabelData[Number(LabelID)];
	FilterFieldName = LabelsRow.FilterFieldName;
	If FilterFieldName="Content.Material" Then
		AddedItemsRemovalFormGroupsList = WorkWithFilters.GetListNameGroupParent(LabelData);
		LabelData.Delete(LabelsRow);
		WorkWithFilters.RefreshLabelItems(ThisObject, AddedItemsRemovalFormGroupsList);
		UpdateNonstandardFilters(FilterFieldName);
	Else
		WorkWithFilters.DeleteFilterLabelServer(ThisObject, List, LabelID);
	EndIf;
	
	If FilterFieldName="Owner" Then
		FormManagement(ThisObject);
	EndIf; 

EndProcedure

&AtServer
Procedure SaveFiltersSettings()
	
	WorkWithFilters.SaveFilterSettings(ThisObject, , , , False);
	
	ObjectKeyName = StrReplace(FormName,".","");
	CommonUse.CommonSettingsStorageSave(ObjectKeyName, "ShowOrdersSpecifications", ShowOrdersSpecifications);
	
EndProcedure

&AtClient
Procedure CollapseExpandFiltersPanel(Item)
	
	NewValueVisibility = Not Items.FiltersSettingsAndExtraInfo.Visible;
	WorkWithFiltersClient.CollapseExpandFiltersPanel(ThisObject, NewValueVisibility);
		
EndProcedure

#EndRegion

#Region LibrariesHandlers

#EndRegion 


