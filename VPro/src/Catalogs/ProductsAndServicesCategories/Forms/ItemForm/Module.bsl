&AtClient
Var SortingOrderChanged; 

#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
//	If Not ValueIsFilled(Object.Ref) Then
//		FillTypesList();
//	EndIf;
//	
//	If Not Constants.FunctionalOptionUseTechOperations.Get() Then
//		FoundOperation = Items.ТипНоменклатурыПоУмолчанию.ChoiceList.FindByValue(Enums.ProductsAndServicesTypes.Operation);
//		If FoundOperation <> Undefined Then
//			Items.ТипНоменклатурыПоУмолчанию.ChoiceList.Delete(FoundOperation);
//		EndIf;
//	EndIf;
	
	MetadataObject = Catalogs.ProductsAndServices.EmptyRef().Metadata();
	ProductsAndServicesEditAllowed =
		SmallBusinessAccessManagementReUse.HasAccessRight(
			"Insert",
			CommonUse.MetadataObjectID(MetadataObject))
		Or SmallBusinessAccessManagementReUse.HasAccessRight(
			"Update", 
			CommonUse.MetadataObjectID(MetadataObject));
	
	SetFieldForSortingSign(); 
	
	If Not Constants.FunctionalOptionUseCharacteristics.Get() Then
		Items.GroupCharacteristics.Visible = False;
	EndIf;
	
	FOUseSubsystemProduction = GetFunctionalOption("UseSubsystemProduction");
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	FillAdditionalAttributesList();
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	PropertiesSetObject = Object.PropertySet.GetObject();
	TabSec = PropertiesSetObject.AdditionalAttributes;
	IndexOf = 0;
	For Each Property In ProductsAndServicesProperty Do
		
		Row = TabSec.Find(Property.Ref, "Property");
		TabSec.Move(Row, IndexOf - TabSec.IndexOf(Row));
		IndexOf = IndexOf + 1;
		
	EndDo;
	PropertiesSetObject.Write();
	
	PropertiesSetObject = Object.CharacteristicPropertySet.GetObject();
	TabSec = PropertiesSetObject.AdditionalAttributes;
	IndexOf = 0;
	For Each Property In CharacteristicProperties Do
		
		Row = TabSec.Find(Property.Ref, "Property");
		TabSec.Move(Row, IndexOf - TabSec.IndexOf(Row));
		IndexOf = IndexOf + 1;
		
	EndDo;
	PropertiesSetObject.Write();
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	If SortingOrderChanged Then
		Notify("OrderChanged", Object.Ref);
	EndIf;
	
	Notify("Write_ProductsAndServicesCategory ", Object.Ref);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters) 
	
	SortingOrderChanged = False;
	CurrentPropertiesArray = New Array;
	
	For Each SortingLine In Object.SortingOrder Do
		CurrentPropertiesArray.Add(SortingLine.Property);
	EndDo;
	
	Object.SortingOrder.Clear();
	
	For Each TableRowCharacteristicProperties In CharacteristicProperties Do
		If TableRowCharacteristicProperties.Sort
			Then
			NewRow = Object.SortingOrder.Add();
			NewRow.Property = TableRowCharacteristicProperties.Ref;
			
			SortingOrderChanged = ?(CurrentPropertiesArray.Find(NewRow.Property) = Undefined, True, False);        
		EndIf;
	EndDo;
	
	If Not SortingOrderChanged And Not CurrentPropertiesArray.Count() = Object.SortingOrder.Count()
		Then
		SortingOrderChanged = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "ValueChangeUseCharacteristics" Then
		Items.GroupCharacteristics.Visible = Parameter
	EndIf;
	
	If EventName = "Writing_AdditionalAttributesAndInformationSets" Or EventName = "Writing_AdditionalAttributesAndInformation" Then
		FillAdditionalAttributesList();
	EndIf;
	
EndProcedure

#EndRegion

#Region ProductsAndServicesPropertiesFormTableEventHandlers

&AtClient
Procedure ProductsAndServicesPropertyOnChange(Item)
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure ProductsAndServicesPropertySelection(Item, SelectedRow, Field, StandardProcessing)
	
	StandardProcessing = False;
	AdditionalAttributesTableRowSelect(Item.CurrentData.Ref);
	
EndProcedure

&AtClient
Procedure ProductsAndServicesPropertyBeforeAddRow(Item, Cancel, Copy, Parent, Group, Parameter)
	
	Cancel = True;
	AddAdditionalAttribute("ProductsAndServices");
	
EndProcedure

&AtClient
Procedure ProductsAndServicesPropertyBeforeRowChange(Item, Cancel)
	
	AdditionalAttributesTableRowSelect(Item.CurrentData.Ref);
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ProductsAndServicesPropertyBeforeDeleteRow(Item, Cancel)
	
	For Each RemovedRow In Item.SelectedRows Do
		PropertyToDelete = ProductsAndServicesProperty.FindByID(RemovedRow).Ref;
		ProductsAndServicesPropertyBeforeDeleteRowAtServer(PropertyToDelete);
	EndDo;
	
EndProcedure

&AtServer
Procedure ProductsAndServicesPropertyBeforeDeleteRowAtServer(PropertyToDelete)
	
	PropertiesSetObject = Object.PropertySet.GetObject();
	TabSec = PropertiesSetObject.AdditionalAttributes;
	Row = TabSec.Find(PropertyToDelete, "Property");
	TabSec.Delete(Row);
	PropertiesSetObject.Write();
	
EndProcedure

&AtClient
Procedure ProductsAndServicesPropertyChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	ProductsAndServicesPropertyChoiceProcessingAtServer(SelectedValue);
	Modified = True;
	FillPropertyListOfCurrentSet("ProductsAndServices");
	
EndProcedure

&AtServer
Procedure ProductsAndServicesPropertyChoiceProcessingAtServer(ArraySelectedValues)
	
	For Each SelectedValue In ArraySelectedValues Do
		
		If SelectedValue.PropertySet <> Object.PropertySet
			And SelectedValue.PropertySet = Object.CharacteristicPropertySet Then
			
			SelectedValueObject = SelectedValue.GetObject();
			SelectedValueObject.PropertySet = Object.CharacteristicPropertySet;
			SelectedValueObject.Write();
			
		EndIf;
		
		PropertiesSetObject = Object.PropertySet.GetObject();
		TabSec = PropertiesSetObject.AdditionalAttributes;
		Row = TabSec.Add();
		Row.Property = SelectedValue;
		PropertiesSetObject.Write();
	EndDo;
	
EndProcedure

#EndRegion

#Region CharacteristicPropertiesFormTableEventHandlers

&AtClient
Procedure CharacteristicPropertiesOnChange(Item)
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure CharacteristicPropertiesSelection(Item, SelectedRow, Field, StandardProcessing)
	
	StandardProcessing = False;
	AdditionalAttributesTableRowSelect(Item.CurrentData.Ref);
	
EndProcedure

&AtClient
Procedure CharacteristicPropertiesBeforeAddRow(Item, Cancel, Copy, Parent, Group, Parameter)
	
	Cancel = True;
	AddAdditionalAttribute("Characteristics");
	
EndProcedure

&AtClient
Procedure CharacteristicPropertiesBeforeRowChange(Item, Cancel)
	
	If Not Item.CurrentItem.Name = "CharacteristicPropertiesSort" 
		Then	
		AdditionalAttributesTableRowSelect(Item.CurrentData.Ref);
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure CharacteristicPropertiesBeforeDeleteRow(Item, Cancel)
	
	PropertyToDelete = Item.CurrentData.Ref;
	CharacteristicPropertiesBeforeDeleteRowAtServer(PropertyToDelete);
		
EndProcedure

&AtServer
Procedure CharacteristicPropertiesBeforeDeleteRowAtServer(PropertyToDelete)

	PropertiesSetObject = Object.CharacteristicPropertySet.GetObject();
	TabSec = PropertiesSetObject.AdditionalAttributes;
	Row = TabSec.Find(PropertyToDelete, "Property");
	
	If Not Row = Undefined Then
		TabSec.Delete(Row);
		PropertiesSetObject.Write();
	EndIf;
	
	FilterParameters = New Structure("Property", PropertyToDelete);
	
	SortingRows = Object.SortingOrder.FindRows(FilterParameters);
	
	For Each SortingLine In SortingRows Do
		Object.SortingOrder.Delete(SortingLine);
	EndDo;

EndProcedure

&AtClient
Procedure CharacteristicPropertiesChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	CharacteristicPropertiesChoiceProcessingAtServer(SelectedValue);
	Modified = True;
	FillPropertyListOfCurrentSet("Characteristics");
	
EndProcedure

&AtServer
Procedure CharacteristicPropertiesChoiceProcessingAtServer(ArraySelectedValues)
	
	For Each SelectedValue In ArraySelectedValues Do
		
		If SelectedValue.PropertySet = Object.PropertySet
			And SelectedValue.PropertySet <> Object.CharacteristicPropertySet Then
			
			SelectedValueObject = SelectedValue.GetObject();
			SelectedValueObject.PropertySet = Object.CharacteristicPropertySet;
			SelectedValueObject.Write();
			
		EndIf;
		
		PropertiesSetObject = Object.CharacteristicPropertySet.GetObject();
		TabSec = PropertiesSetObject.AdditionalAttributes;
		Row = TabSec.Add();
		Row.Property = SelectedValue;
		PropertiesSetObject.Write();
	EndDo;
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Procedure FillTypesList()
	
	List = Items.DefaultProductsAndServicesType.ChoiceList;
	
	ProductAndServicesTypeRestriction = Undefined;
	Parameters.FillingValues.Property("ProductsAndServicesType", ProductAndServicesTypeRestriction);
	
	If Not ProductAndServicesTypeRestriction = Undefined Then
		If (TypeOf(ProductAndServicesTypeRestriction) = Type("Array") Or TypeOf(ProductAndServicesTypeRestriction) = Type("FixedArray")) 
			And ProductAndServicesTypeRestriction.Count() > 0 Then
			
			List.Clear();
			For Each Type In ProductAndServicesTypeRestriction Do
				List.Add(Type);
			EndDo;
			
		ElsIf TypeOf(ProductAndServicesTypeRestriction) = Type("EnumRef.ProductsAndServicesTypes") Then
			
			List.Clear();
			List.Add(ProductAndServicesTypeRestriction);
			
		EndIf;
		
	EndIf;
	
	If Not Constants.FunctionalOptionUseTechOperations.Get() Then
		FoundOperation = Items.DefaultProductsAndServicesType.ChoiceList.FindByValue(Enums.ProductsAndServicesTypes.Operation);
		If FoundOperation <> Undefined Then
			Items.DefaultProductsAndServicesType.ChoiceList.Delete(FoundOperation);
		EndIf;
	EndIf;
	
	If Items.DefaultProductsAndServicesType.ChoiceList.FindByValue(Object.DefaultProductsAndServicesType) = Undefined Then
		Object.DefaultProductsAndServicesType = List.Get(0).Value;
	EndIf;
	
	If List.Count() = 1 Then
		Items.DefaultProductsAndServicesType.Enabled = False;
	EndIf;
	
EndProcedure

&AtServer
Function TypeOfAdditionalAttributeContainsPropertyValues(ValueType)
	
	Return ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues"))
		Or ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValuesHierarchy"));
	
EndFunction

&AtServer
Function ThisIsAdditionalInformation(AttributeType)
	
	If AttributeType.Types().Find(Type("CatalogRef.ObjectsPropertiesValues")) <> Undefined Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

&AtServer
Procedure FillPropertyListOfCurrentSet(ItemSetOwner)
	
	If ItemSetOwner = "ProductsAndServices" Then
		PropertySet = Object.PropertySet;
		Table = ProductsAndServicesProperty;
	ElsIf ItemSetOwner = "Characteristics" Then
		PropertySet = Object.CharacteristicPropertySet;
		Table = CharacteristicProperties;
	EndIf;
	
	Table.Clear();
	
	Query = New Query;
	Query.SetParameter("PropertySet", PropertySet);
	Query.Text = 
	"SELECT
	|	AddAttributes.Property AS Ref,
	|	AddAttributes.LineNumber AS LineNumberForSorting
	|FROM
	|	Catalog.AdditionalAttributesAndInformationSets.AdditionalAttributes AS AddAttributes
	|WHERE
	|	AddAttributes.Ref = &PropertySet
	|";
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		NewRow = Table.Add();
		NewRow.Ref = Selection.Ref;
		NewRow.Title = Selection.Ref.Title;
		
		If TypeOfAdditionalAttributeContainsPropertyValues(Selection.Ref.ValueType) Then
			
			NewRow.ValueType = String(New TypeDescription(Selection.Ref.ValueType,,
				"CatalogRef.ObjectsPropertiesValuesHierarchy,CatalogRef.ObjectsPropertiesValues"));
			
			ValuesPresentation = PropertyValuesPresentation(Selection.Ref);
			If ValueIsFilled(NewRow.ValueType) Then
				ValuesPresentation = ValuesPresentation + ", ";
			EndIf;
			
			NewRow.ValueType = ValuesPresentation + NewRow.ValueType;
			
		Else
			
			NewRow.ValueType = String(Selection.Ref.ValueType);
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Function PropertyValuesPresentation(AdditionalAttribute)
	
	Query = New Query;
	AdditionalValuesOwner = CommonUse.ObjectAttributeValue(AdditionalAttribute, "AdditionalValuesOwner");
	If ValueIsFilled(AdditionalValuesOwner) Then
		Query.SetParameter("Owner", AdditionalValuesOwner);
	Else
		Query.SetParameter("Owner", AdditionalAttribute);
	EndIf;
	
	Query.Text =
	"SELECT TOP 4
	|	ObjectsPropertiesValues.Description AS Description
	|FROM
	|	Catalog.ObjectsPropertiesValues AS ObjectsPropertiesValues
	|WHERE
	|	ObjectsPropertiesValues.Owner = &Owner
	|	AND NOT ObjectsPropertiesValues.IsFolder
	|	AND NOT ObjectsPropertiesValues.DeletionMark
	|
	|UNION
	|
	|SELECT TOP 4
	|	ObjectsPropertiesValuesHierarchy.Description
	|FROM
	|	Catalog.ObjectsPropertiesValuesHierarchy AS ObjectsPropertiesValuesHierarchy
	|WHERE
	|	ObjectsPropertiesValuesHierarchy.Owner = &Owner
	|	AND NOT ObjectsPropertiesValuesHierarchy.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	TRUE AS TrueValue
	|FROM
	|	Catalog.ObjectsPropertiesValues AS ObjectsPropertiesValues
	|WHERE
	|	ObjectsPropertiesValues.Owner = &Owner
	|	AND NOT ObjectsPropertiesValues.IsFolder
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	Catalog.ObjectsPropertiesValuesHierarchy AS ObjectsPropertiesValuesHierarchy
	|WHERE
	|	ObjectsPropertiesValuesHierarchy.Owner = &Owner";
	ResultsOfQuery = Query.ExecuteBatch();
	
	FirstValues = ResultsOfQuery[0].Unload().UnloadColumn("Description");
	
	If FirstValues.Count() = 0 Then
		If ResultsOfQuery[1].IsEmpty() Then
			ValuesPresentation = NStr("en='Values not yet entered';ru='Значения еще не введены';vi='Chưa nhập các giá trị'");
		Else
			ValuesPresentation = NStr("en='Values marked for deletion';ru='Значения помечены на удаление';vi='Giá trị đã bị đánh dấu xóa'");
		EndIf;
	Else
		ValuesPresentation = "";
		Number = 0;
		For Each Value In FirstValues Do
			Number = Number + 1;
			If Number = 4 Then
				ValuesPresentation = ValuesPresentation + ",...";
				Break;
			EndIf;
			ValuesPresentation = ValuesPresentation + ?(Number > 1, ", ", "") + Value;
		EndDo;
	EndIf;
	
	ValuesPresentation = "<" + ValuesPresentation + ">";
	
	Return ValuesPresentation;
	
EndFunction

&AtServer
Procedure SetFieldForSortingSign()
	
	If Object.SortingOrder.Count()
		Then
		For Each RowSortingOrder In Object.SortingOrder Do
			
			RowWithSorting = CharacteristicProperties.FindRows(New Structure("Ref", RowSortingOrder.Property));
			
			If RowWithSorting.Count()
				Then
				RowWithSorting[0].Sort = True;
			EndIf;
		EndDo;	
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillAdditionalAttributesList()
	
	FillPropertyListOfCurrentSet("ProductsAndServices");
	FillPropertyListOfCurrentSet("Characteristics");
	
EndProcedure

&AtClient
Procedure AdditionalAttributesTableRowSelect(Property)
	
	FormParameters = New Structure("Key", Property);
	
	OpenForm(
		"ChartOfCharacteristicTypes.AdditionalAttributesAndInformation.Form.ItemForm", 
		FormParameters, 
		ThisForm
	);
	
EndProcedure

&AtClient
Procedure AddAdditionalAttribute(ItemSetOwner)
	
	If Not ValueIsFilled(Object.Ref) Then
		
		QuestionText = NStr("en='Before you start managing properties, you need to write down the object. Write?';ru='Перед началом управления свойствами необходимо записать объект. Записать?';vi='Trước khi bạn bắt đầu quản lý các thuộc tính, cần ghi lại đối tượng. Ghi lại?'");
		Response = Undefined;
		
		AdditionalParameters = New Structure("ItemSetOwner", ItemSetOwner);
		ShowQueryBox(
			New NotifyDescription("AddAdditionalAttributeCompletion", ThisObject, AdditionalParameters),
			QuestionText,
			QuestionDialogMode.YesNo
		);
		
	Else
		
		OpenFormOfSelectedAdditionalAttribute(ItemSetOwner);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AddAdditionalAttributeCompletion(Result, AdditionalParameters) Export
	
	Response = Result;
	
	If Response = DialogReturnCode.Yes Then
		Write();
	Else
		Return;
	EndIf;
	
	OpenFormOfSelectedAdditionalAttribute(AdditionalParameters.ItemSetOwner);
	
EndProcedure

&AtClient
Procedure OpenFormOfSelectedAdditionalAttribute(ItemSetOwner)
	
	If Not ValueIsFilled(Object.Ref) Then
		Return;
	EndIf;
	
	ThisIsAdditionalInformation = False;
	SelectedAdditionalAttributes = SelectedAdditionalAttributesOfSet(ItemSetOwner);
	
	Filter = New Structure("ThisIsAdditionalInformation", ThisIsAdditionalInformation);
	PropertiesSets = New Array;
	PropertiesSets.Add(Object.PropertySet);
	PropertiesSets.Add(Object.CharacteristicPropertySet);
	Filter.Insert("PropertySet", PropertiesSets);
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", Filter);
	FormParameters.Insert("MultipleChoice", True);
	FormParameters.Insert("ThisIsAdditionalInformation", ThisIsAdditionalInformation);
	FormParameters.Insert("SelectedValues", SelectedAdditionalAttributes);
	
	If ValueIsFilled(Object.PropertySet) And ItemSetOwner="ProductsAndServices" Then
		FormParameters.Insert("PropertySet", Object.PropertySet);
	ElsIf ValueIsFilled(Object.CharacteristicPropertySet) And ItemSetOwner="Characteristics" Then
		FormParameters.Insert("PropertySet", Object.CharacteristicPropertySet);
	Else
		FormParameters.Insert("PropertySet", PredefinedValue("Catalog.AdditionalAttributesAndInformationSets.Catalog_"+ItemSetOwner));
	EndIf;
	
	ChoiceFormOwner = AdditionalAttributesFormTable(ItemSetOwner);
	
	OpenForm(
		"Catalog.ProductsAndServicesCategories.Form.AdditionalAttributeChoiceForm",
		FormParameters, 
		ChoiceFormOwner,
		UUID
	);
	
EndProcedure

// Функция возвращает массив выбранных доп. реквизитов соответсвующего набора.
//
&AtClient
Function SelectedAdditionalAttributesOfSet(ItemSetOwner)
	
	AdditionalAttributesOfSet = New Array;
	AdditionalAttributeCollection = AdditionalAttributeCollection(ThisForm, ItemSetOwner);
	
	For Each CollectionItem In AdditionalAttributeCollection Do
		AdditionalAttributesOfSet.Add(CollectionItem.Ref);
	EndDo;
	
	Return AdditionalAttributesOfSet;
	
EndFunction

// Функция возвращает таблицу формы - таблицу доп. реквизитов,
// относящуюся к нужному набору.
//
&AtClient
Function AdditionalAttributesFormTable(ItemSetOwner)
	
	If ItemSetOwner = "ProductsAndServices" Then
		Return Items.ProductsAndServicesProperty;
	ElsIf ItemSetOwner = "Characteristics" Then
		Return Items.CharacteristicProperties;
	EndIf;
	
EndFunction

// Функция возвращает коллекцию - таблицу доп. ревизитов,
// относящуюся к нужному набору (набору товаров и услуг, характеристик).
//
&AtClientAtServerNoContext
Function AdditionalAttributeCollection(Form, ItemSetOwner)
	
	If ItemSetOwner = "ProductsAndServices" Then
		Return Form.ProductsAndServicesProperty;
	ElsIf ItemSetOwner = "Characteristics" Then
		Return Form.CharacteristicProperties;
	EndIf;
	
EndFunction

#EndRegion

#Region LibrariesHandlers

// StandardSubsystems.AdditionalReportsAndDataProcessors
&AtClient
Procedure Attachable_ExecuteAssignedCommand(Command)
	If Not AdditionalReportsAndDataProcessorsClient.ExecuteAllocatedCommandAtClient(ThisForm, Command.Name) Then
		ExecutionResult = Undefined;
		AdditionalReportsAndProcessingsExecuteAllocatedCommandAtServer(Command.Name, ExecutionResult);
		AdditionalReportsAndDataProcessorsClient.ShowCommandExecutionResult(ThisForm, ExecutionResult);
	EndIf;
EndProcedure

&AtServer
Procedure AdditionalReportsAndProcessingsExecuteAllocatedCommandAtServer(ItemName, ExecutionResult)
	AdditionalReportsAndDataProcessors.ExecuteAllocatedCommandAtServer(ThisForm, ItemName, ExecutionResult);
EndProcedure
// End StandardSubsystems.AdditionalReportsAndDataProcessors

// StandardSubsystems.Printing
&AtClient
Procedure Attachable_ExecutePrintCommand(Command)
	PrintManagementClient.ExecuteConnectedPrintCommand(Command, ThisObject, Object);
EndProcedure
// End StandardSubsystems.Printing

#EndRegion

