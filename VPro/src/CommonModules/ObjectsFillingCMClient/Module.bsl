
#Region ProgramInterface

Procedure ShowTemplateChoiceForDocumentAddingFromList(Val FullMetadataObjectName, Val DynamicListFilterItems, Val DocumentRef, Val ExcludeTypes = Undefined) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("FullMetadataObjectName", FullMetadataObjectName);
	FormParameters.Insert("OperationKinds", OperationKindsListForFilter(DynamicListFilterItems));
	FormParameters.Insert("DocumentRef", DocumentRef);
	FormParameters.Insert("ExcludeTypes", ExcludeTypes);
	
	OpenForm("Catalog.ШаблоныДокументов.ChoiceForm", FormParameters);
	
EndProcedure

Procedure SaveDocumentAsTemplate(Object, ShowedAttributes, NotifyDescription) Export
	
	If TypeOf(NotifyDescription) = Type("NotifyDescription") Then
		
		OpenForm("Catalog.ШаблоныДокументов.ObjectForm",
		New Structure("Object, ShowedAttributes", Object, ShowedAttributes),,,,,
		NotifyDescription);
		
	Else
		
		OpenForm("Catalog.ШаблоныДокументов.ObjectForm",
		New Structure("Object, ShowedAttributes", Object, ShowedAttributes));
		
	EndIf;
	
EndProcedure

Procedure FillWarehouseInventoryTS(Val TSInventoryRow, Val DocumentObject, Val ProductsAndServicesData) Export
	
	If TypeOf(ProductsAndServicesData)=Type("Structure") Then
		If ProductsAndServicesData.Property("Warehouse") And ValueIsFilled(ProductsAndServicesData.Warehouse) Then
			TSInventoryRow.StructuralUnit = ProductsAndServicesData.Warehouse;
		EndIf;
		If ProductsAndServicesData.Property("Cell") And ValueIsFilled(ProductsAndServicesData.Cell) And TSInventoryRow.Property("Cell") Then
			TSInventoryRow.Cell = ProductsAndServicesData.Cell;
		EndIf;
	EndIf;
	
	HasAttributeWarehousePosition = CommonUseClientServer.HasAttributeOrObjectProperty(DocumentObject, "WarehousePosition");
	WarehousePosition = ?(HasAttributeWarehousePosition, DocumentObject.WarehousePosition, PredefinedValue("Enum.AttributePositionOnForm.InTabularSection"));
	
	If Not ValueIsFilled(TSInventoryRow.StructuralUnit) 
		And WarehousePosition<>PredefinedValue("Enum.AttributePositionOnForm.InTabularSection") Then
		TSInventoryRow.StructuralUnit = DocumentObject.StructuralUnit;
		If TSInventoryRow.Property("Cell") Then
			TSInventoryRow.Cell = DocumentObject.Cell;
		EndIf; 
	EndIf;
	
EndProcedure

// Заполняет реквизит строки табличной части по шапке. 
// 
// Parameters:
//  TSRow - FormDataStructure - Строка табличной части для заполнения.
//  DocumentObject - ДанныеФормы - Обрабатываемый документ.
//  FieldName - String - Имя заполняемого поля.
//  PositionFieldName - String - Имя поля текущего положения реквизита.
// 
Procedure FillRowByHeader(Val TSRow, Val DocumentObject, FieldName, PositionFieldName) Export
	
	ObjectsFillingCMClientServer.FillRowByHeader(TSRow, DocumentObject, FieldName, PositionFieldName);
	
EndProcedure

// Выполняет стандартные действия после смены положения реквизита на форме. 
// 
// Parameters:
//  DocumentObject - ДанныеФормы - Обрабатываемый документ.
//  TSName - String - Имя обрабатываемой табличной части.
//  FieldName - String - Имя реквизита, изменившего положение.
//  PositionFieldName - String - Имя поля текущего положения реквизита.
// 
Procedure ProcessPositionChange(Val DocumentObject, TSName, FieldName, PositionFieldName) Export
	
	If DocumentObject[PositionFieldName]<>PredefinedValue("Enum.AttributePositionOnForm.InTabularSection") Then
		DocumentObject[FieldName] = ValueForHeader(DocumentObject[TSName], FieldName);
	EndIf;
	
	For Each TabularSectionRow In DocumentObject[TSName] Do
		TabularSectionRow[FieldName] = DocumentObject[FieldName];
	EndDo; 
	
EndProcedure

// Возвращает наиболее часто встречающиеся в табличной части значение поля. 
// 
// Parameters:
//  TabularSection - TabularSection - Обрабатываемая табличная часть.
//  FieldName - String - Имя анализируемого поля.
// 
// Returns:
//  ЛюбоеЗначение - Наиболее часто встречающиеся в табличной части значение поля.
//
Function ValueForHeader(TabularSection, FieldName) Export
	
	If TabularSection.Count()=0 Then
		Return Undefined;
	EndIf; 
	
	ValueMap = New Map;
	For Each TabularSectionRow In TabularSection Do
		Value = TabularSectionRow[FieldName];
		If Not ValueIsFilled(Value) Then
			Value = Undefined;
		EndIf;
		Quantity = ValueMap.Get(Value);
		If Quantity=Undefined Then
			Quantity = 0;
		EndIf; 
		ValueMap.Insert(Value, Quantity + 1);
	EndDo; 
	
	MaxValue = Undefined;
	For Each KeyAndValue In ValueMap Do
		If MaxValue=Undefined Then
			MaxValue = KeyAndValue;
			Continue;
		EndIf;
		If KeyAndValue.Value>MaxValue.Value Then
			MaxValue = KeyAndValue;
		EndIf; 
	EndDo;
	If MaxValue=Undefined Then
		Return Undefined;
	Else
		Return MaxValue.Key;
	EndIf; 
	
EndFunction

// Заполняет пустые реквизиты положений перед открытием формы "Шапка / табличная часть". 
// 
// Parameters:
//  Object - ДанныеФормы - Обрабатываемый документ.
//  NamesOfFields - String - Имена полей, которые следует проверить и заполнить, разделенные занятой.
// 
Procedure FillEmptyPositions(Object, NamesOfFields) Export
	
	Fields = StringFunctionsClientServer.DecomposeStringIntoSubstringArray(NamesOfFields, , , True);
	For Each Field In Fields Do
		If Not ValueIsFilled(Object[Field]) Then
			Object[Field] = PredefinedValue("Enum.AttributePositionOnForm.InHeader");
		EndIf; 
	EndDo; 
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

Function OperationKindsListForFilter(DynamicListFilterItems)
	
	Result = New ValueList;
	
	For Each CurrentFilterItem In DynamicListFilterItems Do
		
		If Not CurrentFilterItem.Use Then
			Continue;
		EndIf;
		
		If TypeOf(CurrentFilterItem) = Type("DataCompositionFilterItemGroup") Then
			Continue;
		EndIf;
		
		If CurrentFilterItem.LeftValue <> New DataCompositionField("OperationKind") Then
			Continue;
		EndIf;
		
		If CurrentFilterItem.ComparisonType = DataCompositionComparisonType.Equal Then
			Result.Add(CurrentFilterItem.RightValue);
			Return Result;
		EndIf;
		
		If CurrentFilterItem.ComparisonType = DataCompositionComparisonType.InList Then
			Result.LoadValues(CurrentFilterItem.RightValue.UnloadValues());
			Return Result;
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion