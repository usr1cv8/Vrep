
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not Parameters.Filter.Property("ProductsAndServices", ProductsAndServices) Then
		Cancel = True;
		Return;
	EndIf;
	
	SetConditionalAppearance();
	
	Items.GroupCopy.Visible = ValueIsFilled(ProductsAndServices);
	
	SetFormConditionalAppearance();
	
	SetFilter(List.Filter, "Owner", ProductsAndServices);
	EmptyValuesList = New ValueList;
	EmptyValuesList.Add(Undefined);
	EmptyValuesList.Add(PredefinedValue("Document.CustomerOrder.EmptyRef"));
	EmptyValuesList.Add(PredefinedValue("Document.ProductionOrder.EmptyRef"));
	SetFilter(List.Filter, "DocOrder", EmptyValuesList);	
	
	SpecificationsUsageCheck();
	
	FillCharacteristics();
	UpdateDisplayOptions();
	FormManagement(ThisObject);
	SetFilterInvalid(ThisObject);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Src)
	
	If EventName = "SpecificationsCopying" And ValueIsFilled(ProductsAndServices) And Parameter=ProductsAndServices Then
		
		Items.List.Refresh();
		
	ElsIf EventName = "SpecificationSaved" Then
		
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
Procedure ModeOnChange(Item)
	
	If Mode=0 Then
		CurrentCharacteristic = Undefined;
		SetFilter(List.Filter, "ProductCharacteristic", CurrentCharacteristic);
	ElsIf Mode=2 Then
		CurrentCharacteristic = PredefinedValue("Catalog.ProductsAndServicesCharacteristics.EmptyRef");
		SetFilter(List.Filter, "ProductCharacteristic", CurrentCharacteristic);
	ElsIf Mode=1 And Items.Characteristics.CurrentData<>Undefined Then
		CurrentCharacteristic = Items.Characteristics.CurrentData.Characteristic;
		SetFilter(List.Filter, "ProductCharacteristic", CurrentCharacteristic);
	Else
		CurrentCharacteristic = Undefined;
	EndIf;
	
	FormManagement(ThisObject);
	
EndProcedure

&AtClient
Procedure CharacteristicsOnActivateRow(Item)

	If Item.CurrentData=Undefined Or Item.CurrentData.Characteristic=CurrentCharacteristic Then
		Return;
	EndIf; 
	
	CurrentCharacteristic = Item.CurrentData.Characteristic;
	SetFilter(List.Filter, "ProductCharacteristic", CurrentCharacteristic);	
	
EndProcedure
 
&AtClient
Procedure ShowOrdersSpecificationsOnChange(Item)
	
	EmptyValuesList = New ValueList;
	EmptyValuesList.Add(Undefined);
	EmptyValuesList.Add(PredefinedValue("Document.CustomerOrder.EmptyRef"));
	EmptyValuesList.Add(PredefinedValue("Document.ProductionOrder.EmptyRef"));
	SetFilter(List.Filter, "DocOrder", ?(ShowOrdersSpecifications, Undefined, EmptyValuesList));
	FormManagement(ThisObject);
	
EndProcedure

&AtClient
Procedure CharacteristicsDrag(Item, DragParameters, StandardProcessing, Row, Field)
	
	TabularSectionRow = Characteristics.FindByID(Row);
	
	SpecificationsArray = New Array;
	If TypeOf(DragParameters.Value)=Type("CatalogRef.Specifications") Then
		SpecificationsArray.Add(DragParameters.Value);
	ElsIf TypeOf(DragParameters.Value)=Type("Array") Then
		For Each Specification In DragParameters.Value Do
			If TypeOf(Specification)=Type("CatalogRef.Specifications") Then
				SpecificationsArray.Add(Specification);
			EndIf; 
		EndDo;
	Else
		StandardProcessing = False;
		Return;
	EndIf;
	
	If SpecificationsArray.Count()=0 Then
		StandardProcessing = False;
		Return;
	EndIf;
	
	ChangeSpecificationsCharacteristic(SpecificationsArray, TabularSectionRow.Characteristic);
	
EndProcedure

&AtClient
Procedure CollapseExpandFiltersPanel(Item)
	
	NewValueVisibility = Not Items.FiltersSettingsAndExtraInfo.Visible;
	
	ItemsNamesStructure = New Structure("FiltersSettingsAndExtraInfo, DecorationExpandFilters, RightPanel",
	    "FiltersSettingsAndExtraInfo","DecorationExpandFilters","RightPanel"
		);
	WorkWithFiltersClient.CollapseExpandFiltersPanel(ThisObject, NewValueVisibility, ItemsNamesStructure);
		
EndProcedure

#EndRegion 

#Region FormCommandsHandlers

&AtClient
Procedure UseAsBasic(Command)
	
	TabularSectionRow = Items.List.CurrentData;
	If TabularSectionRow=Undefined Then
		Return;
	EndIf; 
	UseAsBasicServer(ProductsAndServices, TabularSectionRow.ProductCharacteristic, TabularSectionRow.Ref);
	
EndProcedure

&AtServer
Procedure UseAsBasicServer(ProductsAndServices, Characteristic, Specification)
	
	Catalogs.Specifications.ChangeSignBasicSpecification(ProductsAndServices, Characteristic, Specification); 
	
	Items.List.Refresh();
	Items.List.CurrentRow = Specification;
	
EndProcedure

&AtClient
Procedure CopyFrom(Command)
	
	OpeningStructure = New Structure;
	OpeningStructure.Insert("ProductsAndServices", ProductsAndServices);
	OpeningStructure.Insert("CopySpecifications", True);
	OpeningStructure.Insert("CopyFromSelected", True);
	OpenForm("Catalog.ProductsAndServices.Form.RelatedInformationCopyingForm", OpeningStructure, ThisObject);
	
EndProcedure

&AtClient
Procedure CopyOther(Command)
	
	OpeningStructure = New Structure;
	OpeningStructure.Insert("ProductsAndServices", ProductsAndServices);
	OpeningStructure.Insert("CopySpecifications", True);
	OpeningStructure.Insert("CopyFromSelected", False);
	OpenForm("Catalog.ProductsAndServices.Form.RelatedInformationCopyingForm", OpeningStructure, ThisObject);
	
EndProcedure

&AtClient
Procedure ShowInvalid(Command)
	
	Items.FormShowInvalid.Check = Not Items.FormShowInvalid.Check;
	
	SetFilterInvalid(ThisObject)
	
EndProcedure

#EndRegion 

#Region InternalProceduresAndFunctions

&AtServer
Procedure SetFormConditionalAppearance()
	
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Characteristics.Outdated", True);
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "CharacteristicsPresentation");
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.TabularSectionUnavailableTextColor);
	
	NewConditionalAppearance = List.ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "NotValid", True, DataCompositionComparisonType.Equal);
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.TabularSectionUnavailableTextColor); 

EndProcedure

&AtServer
Procedure UpdateDisplayOptions()
	
	CharacteristicsUsed = (Characteristics.Count()>0);
	
	If ValueIsFilled(ProductsAndServices) Then
		Query = New Query;
		Query.SetParameter("ProductsAndServices", ProductsAndServices);
		Query.Text =
		"SELECT TOP 1
		|	Specifications.Ref AS Ref
		|FROM
		|	Catalog.Specifications AS Specifications
		|WHERE
		|	Specifications.Owner = &ProductsAndServices
		|	AND Specifications.DocOrder <> Undefined
		|	AND Specifications.DocOrder <> VALUE(Document.CustomerOrder.EmptyRef)
		|	AND Specifications.DocOrder <> VALUE(Document.ProductionOrder.EmptyRef)";
		OrdersUsed = Not Query.Execute().IsEmpty();
	Else
		OrdersUsed = False;
	EndIf; 	
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "List.NotValid", True, DataCompositionComparisonType.Equal);
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "Description");
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.TabularSectionUnavailableTextColor); 

EndProcedure

&AtClientAtServerNoContext
Procedure FormManagement(Form)
	
	Items = Form.Items;
	
	CommonUseClientServer.SetFormItemProperty(Items, "DocOrder", "Visible", Form.ShowOrdersSpecifications);
	CommonUseClientServer.SetFormItemProperty(Items, "ProductCharacteristic", "Visible", Form.CharacteristicsUsed And Form.Mode=0);
	CommonUseClientServer.SetFormItemProperty(Items, "GroupCharacteristics", "Visible", Form.CharacteristicsUsed And Form.Mode=1);
	CommonUseClientServer.SetFormItemProperty(Items, "Mode", "Visible", Form.CharacteristicsUsed);
	CommonUseClientServer.SetFormItemProperty(Items, "ShowOrdersSpecifications", "Visible", Form.OrdersUsed);
	CommonUseClientServer.SetFormItemProperty(Items, "RightPanel", "Visible", Form.CharacteristicsUsed Or Form.OrdersUsed);
	
EndProcedure

&AtServer
Procedure SpecificationsUsageCheck()
	
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
		Items.FiltersSettingsAndExtraInfo.Enabled = False;
		Items.FormUseAsBasic.Visible = False;
		Items.GroupCopy.Enabled = False;
		
	ElsIf AttributeValues.ProductsAndServicesType = Enums.ProductsAndServicesTypes.InventoryItem And Not UseSubsystemProduction Then
		
		AutoTitle = False;
		Title = NStr("en='Specifications are only stored for work';ru='Спецификации хранятся только для работ';vi='Chỉ lưu bảng kê chi tiết công việc'");
		Items.List.ReadOnly = True;
		Items.FiltersSettingsAndExtraInfo.Enabled = False;
		Items.FormUseAsBasic.Visible = False;
		Items.GroupCopy.Enabled = False;
		
	ElsIf AttributeValues.ProductsAndServicesType = Enums.ProductsAndServicesTypes.Work And Not UseWorkSubsystem Then
		
		AutoTitle = False;
		Title = NStr("en='Specifications are only stored for stocks';ru='Спецификации хранятся только для запасов';vi='Chỉ lưu bảng kê chi tiết vật tư'");
		Items.List.ReadOnly = True;
		Items.FiltersSettingsAndExtraInfo.Enabled = False;
		Items.FormUseAsBasic.Visible = False;
		Items.GroupCopy.Enabled = False;
		
	ElsIf Not AccessRight("Insert", Metadata.Catalogs.Specifications) Then
		
		Items.GroupCopy.Enabled = False;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCharacteristics()
	
	Query = New Query;
	Query.SetParameter("ProductsAndServices", ProductsAndServices);
	Query.Text =
	"SELECT
	|	ProductsAndServicesCharacteristics.Ref AS Characteristic,
	|	ProductsAndServicesCharacteristics.Description AS Description
	|INTO TabCharacteristics
	|FROM
	|	Catalog.ProductsAndServicesCharacteristics AS ProductsAndServicesCharacteristics
	|WHERE
	|	(ProductsAndServicesCharacteristics.Owner = &ProductsAndServices
	|			OR ProductsAndServicesCharacteristics.Owner = CAST(&ProductsAndServices AS Catalog.ProductsAndServices).ProductsAndServicesCategory)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Characteristics.Characteristic AS Characteristic,
	|	FALSE AS Outdated,
	|	Characteristics.Description AS Presentation,
	|	0 AS Order
	|FROM
	|	TabCharacteristics AS Characteristics
	|
	|UNION ALL
	|
	|SELECT
	|	Specifications.ProductCharacteristic,
	|	TRUE,
	|	Specifications.ProductCharacteristic.Description + ""(obsolete)"",
	|	1
	|FROM
	|	Catalog.Specifications AS Specifications
	|WHERE
	|	Specifications.ProductCharacteristic <> VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	|	AND Specifications.Owner = &ProductsAndServices
	|	AND NOT Specifications.ProductCharacteristic IN
	|				(SELECT
	|					TabCharacteristics.Characteristic
	|				FROM
	|					TabCharacteristics)
	|
	|GROUP BY
	|	Specifications.ProductCharacteristic,
	|	Specifications.ProductCharacteristic.Description + ""(obsolete)""
	|
	|ORDER BY
	|	Order,
	|	Presentation";
	Characteristics.Load(Query.Execute().Unload());
	
	CurrentCharacteristic = Undefined;
	SetFilter(List.Filter, "ProductCharacteristic", Undefined);
	If Characteristics.Count()>0 Then
		Items.Characteristics.CurrentRow = Characteristics[0].GetID();
	EndIf; 
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetFilter(FilterItemGroup, FieldDataPath, Value) Export
	
	FoundItem = Undefined;
	Field = New DataCompositionField(FieldDataPath);
	For Each FilterItem In FilterItemGroup.Items Do
		If FilterItem.LeftValue=Field Then
			FoundItem = FilterItem;
			Break;
		EndIf; 
	EndDo; 
	
	If FoundItem=Undefined And Value=Undefined Then
		Return;
	ElsIf FoundItem=Undefined Then
		Filter = FilterItemGroup.Items.Add(Type("DataCompositionFilterItem"));
		Filter.LeftValue  = Field;
	Else
		Filter = FoundItem;
	EndIf; 
	Filter.Use  = Value<>Undefined;
	If TypeOf(Value)=Type("ValueList") Then
		Filter.ComparisonType   = DataCompositionComparisonType.InList;
	Else
		Filter.ComparisonType   = DataCompositionComparisonType.Equal;
	EndIf; 
	Filter.RightValue = Value;
	
EndProcedure

&AtServer
Procedure ChangeSpecificationsCharacteristic(SpecificationsArray, Characteristic)

	For Each Specification In SpecificationsArray Do
		SpecificationObject = Specification.GetObject();
		SpecificationObject.ProductCharacteristic = Characteristic;
		SpecificationObject.Write();
	EndDo;
	
	Items.List.Refresh();
	
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

