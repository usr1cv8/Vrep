
#Region ProgramInterface

// Выполняет проверку формулы.
//
// Parameters:
//  Errors - Undefined, ValueList - Возвращает список ошибок, возникших при проверке.
//  Formula - String - Проверяемая формула.
//  TypeRestriction - TypeDescription - Ожидаемый тип результата расчета.
//  ProductsAndServicesCategory - CatalogRef.ProductsAndServicesCategories - Категория номенклатуры для определения дополнительных реквизитов.
//
Procedure CheckFormula(Errors, Formula, TypeRestriction, ProductsAndServicesCategory) Export
	Var OperandMapping, EstimatedData;
	
	FormulaText = TrimAll(Formula);
	If StrOccurrenceCount(FormulaText, OperandBeginString()) <> StrOccurrenceCount(FormulaText, OperandEndString()) Then
		
		ErrorText = NStr("en='The number of open opera houses does not equal the number of closed ones.';ru='Количество открытых операндов не равно количеству закрытых.';vi='Số lượng toán hạng mở không bằng số lượng toán hạng đóng.'");
		CommonUseClientServer.AddUserError(Errors, "Formula", ErrorText, "");
		
	EndIf;
	
	If StrOccurrenceCount(FormulaText, "(") <> StrOccurrenceCount(FormulaText, ")") Then
		
		ErrorText = NStr("en='The number of open brackets is not equal to the number of closed ones.';ru='Количество открытых скобок не равно количеству закрытых.';vi='Số lượng dấu ngoặc mở không bằng số lượng dấu ngoặc đóng.'");
		CommonUseClientServer.AddUserError(Errors, "Formula", ErrorText, "");
		
	EndIf;
	
	OperandTable = GetFormulaOperandTable(CurrentSessionDate(), Formula);
	OperandValuesMapping = OperandMappingForCheck(ProductsAndServicesCategory);
	For Each Row In OperandTable Do
		
		ID = Mid(Row.Operand, 2, StrLen(Row.Operand) - 2);
		DefaultValue = OperandValuesMapping.Get(ID);
		
		If DefaultValue=Undefined Then
		
			ErrorText = NStr("en='It is not recognized by operand %1."
"Check the correct spelling of the formula.';ru='Не распознан операнд %1."
"Проверьте правильность написания формулы.';vi='Toán tử %1 không được công nhận."
"Kiểm tra công thức.'");
			ErrorText = StrTemplate(ErrorText, Row.Operand);
			
			CommonUseClientServer.AddUserError(Errors, "Formula", ErrorText, "");
			
			Continue;
			
		EndIf;
		
		AddOperandToStructure(OperandMapping, Row.Operand, DefaultValue);
		
	EndDo;
	
	If Errors<>Undefined Then
		
		Return;
		
	EndIf; 
	
	DataCalculationByFormula(FormulaText, OperandMapping, EstimatedData);
	
	If EstimatedData.CalculationError Then
		
		ErrorText = StrTemplate(NStr("en='There were errors in the calculation. Check the correct spelling of the formula."
"Detailed description:"
"%1';ru='При расчете возникли ошибки. Проверьте правильность написания формулы."
"Подробное описание:"
"%1';vi='Có lỗi trong tính toán. Kiểm tra công thức."
"Mô tả chi tiết:"
"%1'"), EstimatedData.ErrorText);
		
		CommonUseClientServer.AddUserError(Errors, "Formula", ErrorText, "");
		
	ElsIf TypeRestriction<>Undefined And Not TypeRestriction.ContainsType(TypeOf(EstimatedData.Result)) Then 
		
		ErrorText = StrTemplate(NStr("en='The type of value received does not correspond to the expected ""%2""';ru='Тип полученного значения <%1> не соответствует ожидаемому <%2>';vi='Loại giá trị nhận được <%1> không khớp với mong đợi <%2>'"), String(TypeOf(EstimatedData.Result)), String(TypeRestriction));
		CommonUseClientServer.AddUserError(Errors, "Formula", ErrorText, "");
		
	EndIf;
		
EndProcedure

// Выполняет расчет параметрических спецификации по табличной части заказа. В результате расчета формируются
//		рабочие спецификации, привязанные к заказу.
//
// Parameters:
//  OrderObject - DocumentObject.CustomerOrder, DocumentObject.ProductionOrder - Объект заказа.
//  TabularSectionName - String - Имя обрабатываемой табличной части.
//  Cancel - Boolean - Признак наличия ошибок при расчете формул.
//
Procedure CalculateParametricSpecifications(OrderObject, TabularSectionName, Cancel) Export
	Var Errors;
	
	If Cancel Then
		Return;
	EndIf; 
	If Not GetFunctionalOption("UseParametricSpecifications") Then
		Return;
	EndIf;
	If Not AccessRight("Read", Metadata.Catalogs.Specifications) Then
		Return;
	EndIf; 
	
	TypeProductsAndServices = New TypeDescription("CatalogRef.ProductsAndServices");
	TypeCharacteristic = New TypeDescription("CatalogRef.ProductsAndServicesCharacteristics");
	TypeNumber = New TypeDescription("Number");
	
	ChangedInformation = New Map;
	TabularSection = OrderObject[TabularSectionName];
	
	CheckedSpecifications = New Array;
	For Each TabularSectionRow In TabularSection Do
		If ValueIsFilled(TabularSectionRow.Specification) Then
			CheckedSpecifications.Add(TabularSectionRow.Specification);
		EndIf; 
	EndDo;
	ParametricSpecifications = SelectParametric(CheckedSpecifications);
	If ParametricSpecifications.Count()=0 Then
		Return;
	EndIf;
	If Not AccessRight("Insert", Metadata.Catalogs.Specifications) Then
		ErrorText = NStr("en='The document contains parametric specifications, holding is possible only for the profile of the rights ""Production.""';ru='Документ содержит параметрические спецификации, проведение возможно только для профиля прав ""Производство"".';vi='Chứng từ chứa tham số bảng chi tiết nguyên vật liệu, chỉ có thể  kết chuyển chứng từ với quyền ""Sản xuất"".'");
		CommonUseClientServer.MessageToUser(ErrorText, , , , Cancel);
	EndIf;
	If Cancel Then
		Return;
	EndIf; 
	
	For Each TabularSectionRow In TabularSection Do
		If Not ValueIsFilled(TabularSectionRow.Specification) Then
			Continue;
		EndIf;
		If ParametricSpecifications.Find(TabularSectionRow.Specification)=Undefined Then
			Continue;
		EndIf; 
		If TypeOf(OrderObject.Ref)=Type("DocumentRef.ProductionOrder") Then
			CustomerOrder = TabularSectionRow.CustomerOrder;
		Else
			CustomerOrder = Undefined;
		EndIf; 
		Data = CalculationData(OrderObject, CustomerOrder, TabularSectionRow.ProductsAndServices, TabularSectionRow.Characteristic, TabularSectionRow.Specification, TabularSectionRow.ConnectionKey);
		RowIndex = TabularSection.IndexOf(TabularSectionRow);
		ChangedInformation.Insert(RowIndex, New Structure("Content, Operations", New Map, New Map));
		PathToField = StrTemplate("Object.%1[%2].Specification", TabularSectionName, RowIndex);
		ChoiceParameters = Metadata.Catalogs.Specifications.TabularSections.Content.Attributes.ProductsAndServices.ChoiceParameters;
		
		For Each ContentRow In Data["Specification.Content"] Do
			AttributesStructure = New Structure;
			If ContentRow.MappingUsed Then
				EstimatedData = Undefined;
				DataCalculationByMapping(Data["Specification.ContentMapping"], ContentRow, Data, EstimatedData);
				If Not CalculationErrorsExists(EstimatedData, Errors, , ChoiceParameters, PathToField) Then
					AttributesStructure.Insert("ProductsAndServices", EstimatedData.Result.ProductsAndServices);
					AttributesStructure.Insert("Characteristic", EstimatedData.Result.Characteristic);
					AttributesStructure.Insert("MeasurementUnit", CommonUse.ObjectAttributeValue(AttributesStructure.ProductsAndServices, "MeasurementUnit")); 
					AttributesStructure.Insert("Specification", SmallBusinessServer.GetDefaultSpecification(AttributesStructure.ProductsAndServices, AttributesStructure.Characteristic));
				EndIf; 
			Else
				If Not IsBlankString(ContentRow.FormulaProductsAndServices) Then
					EstimatedData = Undefined;
					FillOperandsAndCalculate(ContentRow.FormulaProductsAndServices, Data, EstimatedData);
					If Not CalculationErrorsExists(EstimatedData, Errors, TypeProductsAndServices, ChoiceParameters, PathToField) Then
						AttributesStructure.Insert("ProductsAndServices", EstimatedData.Result);
						AttributeValues = CommonUse.ObjectAttributesValues(AttributesStructure.ProductsAndServices, "MeasurementUnit, UseCharacteristics");
						AttributesStructure.Insert("MeasurementUnit", AttributeValues.MeasurementUnit);
						AttributesStructure.Insert("Characteristic", Catalogs.ProductsAndServicesCharacteristics.EmptyRef());
						AttributesStructure.Insert("Specification", SmallBusinessServer.GetDefaultSpecification(AttributesStructure.ProductsAndServices, AttributesStructure.Characteristic));
					EndIf; 
				EndIf; 
			EndIf;
			If Not IsBlankString(ContentRow.FormulaNumber) Then
				EstimatedData = Undefined;
				FillOperandsAndCalculate(ContentRow.FormulaNumber, Data, EstimatedData);
				If Not CalculationErrorsExists(EstimatedData, Errors, TypeNumber, , PathToField) Then
					AttributesStructure.Insert("Quantity", EstimatedData.Result);
				EndIf; 
			EndIf;
			If AttributesStructure.Count()>0 Then
				AttributesStructure.Insert("MappingUsed", False);
				AttributesStructure.Insert("FormulaProductsAndServices", "");
				AttributesStructure.Insert("FormulaNumber", "");
				ContentIndex = Data["Specification.Content"].IndexOf(ContentRow);
				ChangedInformation[RowIndex].Content.Insert(ContentIndex, AttributesStructure);
			EndIf; 
		EndDo;
		
		ChoiceParameters = Metadata.Catalogs.Specifications.TabularSections.Operations.Attributes.Operation.ChoiceParameters;
		For Each OperationRow In Data["Specification.Operations"] Do
			AttributesStructure = New Structure;
			If OperationRow.MappingUsed Then
				EstimatedData = Undefined;
				DataCalculationByMapping(Data["Specification.OperationsMapping"], OperationRow, Data, EstimatedData);
				If Not CalculationErrorsExists(EstimatedData, Errors, , ChoiceParameters, PathToField) Then
					AttributesStructure.Insert("Operation", EstimatedData.Result.Operation);
				EndIf; 
			Else
				If Not IsBlankString(OperationRow.FormulaOperation) Then
					EstimatedData = Undefined;
					FillOperandsAndCalculate(OperationRow.FormulaOperation, Data, EstimatedData);
					If Not CalculationErrorsExists(EstimatedData, Errors, TypeProductsAndServices, ChoiceParameters, PathToField) Then
						AttributesStructure.Insert("Operation", EstimatedData.Result);
					EndIf; 
				EndIf; 
			EndIf;
			If Not IsBlankString(OperationRow.FormulaNumber) Then
				EstimatedData = Undefined;
				FillOperandsAndCalculate(OperationRow.FormulaNumber, Data, EstimatedData);
				If Not CalculationErrorsExists(EstimatedData, Errors, TypeNumber, , PathToField) Then
					AttributesStructure.Insert("Quantity", EstimatedData.Result);
				EndIf; 
			EndIf; 
			If Not IsBlankString(OperationRow.FormulaTimeNorm) Then
				EstimatedData = Undefined;
				FillOperandsAndCalculate(OperationRow.FormulaTimeNorm, Data, EstimatedData);
				If Not CalculationErrorsExists(EstimatedData, Errors, TypeNumber, , PathToField) Then
					AttributesStructure.Insert("TimeNorm", EstimatedData.Result);
				EndIf; 
			EndIf; 
			If AttributesStructure.Count()>0 Then
				AttributesStructure.Insert("MappingUsed", False);
				AttributesStructure.Insert("FormulaOperation", "");
				AttributesStructure.Insert("FormulaNumber", "");
				AttributesStructure.Insert("FormulaTimeNorm", "");
				OperationIndex = Data["Specification.Operations"].IndexOf(OperationRow);
				ChangedInformation[RowIndex].Operations.Insert(OperationIndex, AttributesStructure);
			EndIf; 
		EndDo; 
		
	EndDo;
	
	If Errors<>Undefined Then
		CommonUseClientServer.ShowErrorsToUser(Errors);
		Cancel = True;
	EndIf; 
	
	If Cancel Then
		Return;
	EndIf; 
	
	If CommonUse.ThisIsObjectOfReferentialType(OrderObject.Ref.Metadata()) And OrderObject.IsNew() Then
		ReferenceToOrder = OrderObject.GetNewObjectRef();
		If ReferenceToOrder.IsEmpty() Then
			ObjectMetadata = ReferenceToOrder.Metadata();
			Manager = CommonUse.ObjectManagerByFullName(ObjectMetadata.FullName());
			ReferenceToOrder = Manager.GetRef(New UUID);
			OrderObject.SetNewObjectRef(ReferenceToOrder);
		EndIf;
		If IsBlankString(OrderObject.Number) Then
			OrderObject.SetNewNumber();
		EndIf; 
	Else
		ReferenceToOrder = OrderObject.Ref;
	EndIf; 
	
	For Each KeyAndValue In ChangedInformation Do
		
		TabularSectionRow = TabularSection[KeyAndValue.Key];
		
		NewSpecification = TabularSectionRow.Specification.Copy();
		NewSpecification.Description = NewSpecification.Description + StrTemplate(" (%1)", OrderPresentation(Data, OrderObject.Ref.Metadata().Name));
		NewSpecification.DocOrder = ReferenceToOrder;
		NewSpecification.IsTemplate = False;
		NewSpecification.BaseSpecification = TabularSectionRow.Specification;
		
		RowsToDelete = New Array;
		For Each RowKeyAndValue In KeyAndValue.Value.Content Do
			SpecificationRow = NewSpecification.Content[RowKeyAndValue.Key];
			FillPropertyValues(SpecificationRow, RowKeyAndValue.Value);
			If (RowKeyAndValue.Value.Property("Quantity") And RowKeyAndValue.Value.Quantity=0)
				Or (RowKeyAndValue.Value.Property("ProductsAndServices") And Not ValueIsFilled(RowKeyAndValue.Value.ProductsAndServices)) Then
				RowsToDelete.Add(SpecificationRow);
			EndIf; 
		EndDo;
		For Each SpecificationRow In RowsToDelete Do
			NewSpecification.Content.Delete(SpecificationRow);
		EndDo;
		
		RowsToDelete = New Array;
		For Each RowKeyAndValue In KeyAndValue.Value.Operations Do
			SpecificationRow = NewSpecification.Operations[RowKeyAndValue.Key];
			FillPropertyValues(SpecificationRow, RowKeyAndValue.Value);
			If (RowKeyAndValue.Value.Property("Quantity") And RowKeyAndValue.Value.Quantity=0)
				Or (RowKeyAndValue.Value.Property("TimeNorm") And RowKeyAndValue.Value.TimeNorm=0)
				Or (RowKeyAndValue.Value.Property("Operation") And Not ValueIsFilled(RowKeyAndValue.Value.Operation)) Then
				RowsToDelete.Add(SpecificationRow);
			EndIf; 
		EndDo; 
		For Each SpecificationRow In RowsToDelete Do
			NewSpecification.Operations.Delete(SpecificationRow);
		EndDo;
		
		NewSpecification.AdditionalAttributes.Clear();
		FilterStructure = New Structure;
		FilterStructure.Insert("ConnectionKey", TabularSectionRow.ConnectionKey);
		RowsSpecificationAttributes = OrderObject.ParametricSpecificationsAttributes.FindRows(FilterStructure);
		For Each RowAdditionalAttribute In RowsSpecificationAttributes Do
			NewAttribute = NewSpecification.AdditionalAttributes.Add();
			FillPropertyValues(NewAttribute, RowAdditionalAttribute);
		EndDo;
		
		NewSpecification.ContentMapping.Clear(); 
		NewSpecification.OperationsMapping.Clear();
		NewSpecification.Write();
		TabularSectionRow.Specification = NewSpecification.Ref;
		
	EndDo; 
	
EndProcedure

// Перезаполняет состав и операции спецификации по базовой с расчетом формул.
//
// Parameters:
//  SpecificationObject - ДанныеФормы, СправочникОбъект.Спецификация - Объект спецификации, которые следует перезаполнить.
//  Cancel - Boolean - Признак наличия ошибок при расчете формул.
//
Procedure FillSpecification(SpecificationObject, Cancel) Export
	Var Errors;
	
	TypeProductsAndServices = New TypeDescription("CatalogRef.ProductsAndServices");
	TypeCharacteristic = New TypeDescription("CatalogRef.ProductsAndServicesCharacteristics");
	TypeNumber = New TypeDescription("Number");
	
	BaseSpecification = SpecificationObject.BaseSpecification;
	
	CacheContent = SpecificationObject.Content.Unload();
	CacheOperations = SpecificationObject.Operations.Unload();
	If ValueIsFilled(BaseSpecification) Then
		SpecificationObject.Content.Load(BaseSpecification.Content.Unload());
		SpecificationObject.Operations.Load(BaseSpecification.Operations.Unload());
		ContentMapping = BaseSpecification.ContentMapping.Unload();
		OperationsMapping = BaseSpecification.OperationsMapping.Unload();
	Else
		ContentMapping = SpecificationObject.ContentMapping.Unload();
		OperationsMapping = SpecificationObject.OperationsMapping.Unload();
	EndIf; 
	
	Data = CalculationData(Undefined, SpecificationObject.DocOrder, SpecificationObject.Owner, SpecificationObject.ProductCharacteristic, SpecificationObject, Undefined);
	
	ChoiceParameters = Metadata.Catalogs.Specifications.TabularSections.Content.Attributes.ProductsAndServices.ChoiceParameters;
	For Each ContentRow In SpecificationObject.Content Do
		If ContentRow.MappingUsed Then
			EstimatedData = Undefined;
			DataCalculationByMapping(ContentMapping, ContentRow, Data, EstimatedData);
			If Not CalculationErrorsExists(EstimatedData, Errors, , ChoiceParameters) Then
				ContentRow.ProductsAndServices = EstimatedData.Result.ProductsAndServices;
				ContentRow.Characteristic = EstimatedData.Result.Characteristic;
				ContentRow.MeasurementUnit = CommonUse.ObjectAttributeValue(ContentRow.ProductsAndServices, "MeasurementUnit");
				ContentRow.Specification = SmallBusinessServer.GetDefaultSpecification(ContentRow.ProductsAndServices, ContentRow.Characteristic);
			EndIf;
		Else
			If Not IsBlankString(ContentRow.FormulaProductsAndServices) Then
				EstimatedData = Undefined;
				FillOperandsAndCalculate(ContentRow.FormulaProductsAndServices, Data, EstimatedData);
				If Not CalculationErrorsExists(EstimatedData, Errors, TypeProductsAndServices, ChoiceParameters) Then
					ContentRow.ProductsAndServices = EstimatedData.Result;
					AttributeValues = CommonUse.ObjectAttributesValues(ContentRow.ProductsAndServices, "MeasurementUnit, UseCharacteristics");
					ContentRow.MeasurementUnit = AttributeValues.MeasurementUnit;
					ContentRow.Characteristic = Catalogs.ProductsAndServicesCharacteristics.EmptyRef();
					ContentRow.Specification = SmallBusinessServer.GetDefaultSpecification(ContentRow.ProductsAndServices, ContentRow.Characteristic);
				EndIf; 
			EndIf; 
		EndIf;
		If Not IsBlankString(ContentRow.FormulaNumber) Then
			EstimatedData = Undefined;
			FillOperandsAndCalculate(ContentRow.FormulaNumber, Data, EstimatedData);
			If Not CalculationErrorsExists(EstimatedData, Errors, TypeNumber) Then
				ContentRow.Quantity = EstimatedData.Result;
			EndIf; 
		EndIf;
		ContentRow.MappingUsed = False;
		ContentRow.FormulaProductsAndServices = "";
		ContentRow.FormulaNumber = "";
	EndDo;
	
	ChoiceParameters = Metadata.Catalogs.Specifications.TabularSections.Operations.Attributes.Operation.ChoiceParameters;
	For Each OperationRow In SpecificationObject.Operations Do
		If OperationRow.MappingUsed Then
			EstimatedData = Undefined;
			DataCalculationByMapping(OperationsMapping, OperationRow, Data, EstimatedData);
			If Not CalculationErrorsExists(EstimatedData, Errors, , ChoiceParameters) Then
				OperationRow.Operation = EstimatedData.Result.Operation;
			EndIf; 
		Else
			If Not IsBlankString(OperationRow.FormulaOperation) Then
				EstimatedData = Undefined;
				FillOperandsAndCalculate(OperationRow.FormulaOperation, Data, EstimatedData);
				If Not CalculationErrorsExists(EstimatedData, Errors, TypeProductsAndServices, ChoiceParameters) Then
					OperationRow.Operation = EstimatedData.Result;
				EndIf; 
			EndIf; 
		EndIf;
		If Not IsBlankString(OperationRow.FormulaNumber) Then
			EstimatedData = Undefined;
			FillOperandsAndCalculate(OperationRow.FormulaNumber, Data, EstimatedData);
			If Not CalculationErrorsExists(EstimatedData, Errors, TypeNumber) Then
				OperationRow.Quantity = EstimatedData.Result;
			EndIf; 
		EndIf; 
		If Not IsBlankString(OperationRow.FormulaTimeNorm) Then
			EstimatedData = Undefined;
			FillOperandsAndCalculate(OperationRow.FormulaTimeNorm, Data, EstimatedData);
			If Not CalculationErrorsExists(EstimatedData, Errors, TypeNumber) Then
				OperationRow.TimeNorm = EstimatedData.Result;
			EndIf; 
		EndIf; 
		OperationRow.MappingUsed = False;
		OperationRow.FormulaOperation = "";
		OperationRow.FormulaNumber = "";
		OperationRow.FormulaTimeNorm = "";
	EndDo; 
		
	If Errors<>Undefined Then
		CommonUseClientServer.ShowErrorsToUser(Errors);
		SpecificationObject.Content.Load(CacheContent);
		SpecificationObject.Operations.Load(CacheOperations);
		Cancel = True;
	EndIf;
	
EndProcedure
 
// Возвращает только параметрические спецификации из массива спецификаций, переданого в функцию.
//
// Parameters:
//  Specifications - Array - Массив спецификаций, из которого нужно выбрать параметрические
// Returns:
//  Array - Массив параметрических спецификаций.
//
Function SelectParametric(Specifications) Export
	
	Query = New Query;
	Query.SetParameter("Specifications", Specifications);
	Query.Text =
	"SELECT
	|	Specifications.Ref AS Ref
	|FROM
	|	Catalog.Specifications AS Specifications
	|WHERE
	|	Specifications.Ref IN(&Specifications)
	|	AND Specifications.IsTemplate";
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction
 
// Проверяет заполнение обязательных доп. реквизитов параметрических спецификаций в заказе.
//
// Parameters:
//  Object - ДанныеФормы - Обрабатываемый заказ.
//  TSName - String - Имя табличной части запасов.
//  Cancel - Boolean - Признак наличия незаполненных обязательных реквизитов.
//
Procedure CheckSpecificationsAdditAttributesFilling(Object, TSName, Cancel) Export
	
	If Not GetFunctionalOption("UseParametricSpecifications") Then
		Return;
	EndIf;
	
	TabularSection = Object[TSName];
	
	SelectionTable = New ValueTable;
	SelectionTable.Columns.Add("Specification", New TypeDescription("CatalogRef.Specifications"));
	SelectionTable.Columns.Add("ConnectionKey", New TypeDescription("Number", New NumberQualifiers(5, 0)));
	
	For Each TabularSectionRow In TabularSection Do
		If Not ValueIsFilled(TabularSectionRow. Specification) Or TabularSectionRow.ConnectionKey=0 Then
			Continue;
		EndIf;
		NewRow = SelectionTable.Add();
		FillPropertyValues(NewRow, TabularSectionRow);
	EndDo;
	
	If SelectionTable.Count()=0 Then
		Return;
	EndIf; 
	
	Query = New Query;
	Query.SetParameter("SelectionTable", SelectionTable);
	Query.Text =
	"SELECT
	|	SelectionTable.Specification AS Specification,
	|	SelectionTable.ConnectionKey AS ConnectionKey
	|INTO SelectionTable
	|FROM
	|	&SelectionTable AS SelectionTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SelectionTable.Specification AS Specification,
	|	SelectionTable.ConnectionKey AS ConnectionKey,
	|	ProductsAndServices.ProductsAndServicesCategory AS ProductsAndServicesCategory
	|INTO SpecificationsAndCategories
	|FROM
	|	SelectionTable AS SelectionTable
	|		LEFT JOIN Catalog.Specifications AS Specifications
	|			LEFT JOIN Catalog.ProductsAndServices AS ProductsAndServices
	|			ON Specifications.Owner = ProductsAndServices.Ref
	|		ON SelectionTable.Specification = Specifications.Ref
	|WHERE
	|	Specifications.IsTemplate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SpecificationsAndCategories.Specification AS Specification,
	|	SpecificationsAndCategories.ConnectionKey AS ConnectionKey,
	|	AdditionalAttributesByCategory.Property AS Property,
	|	AdditionalAttributesByCategory.Property.FillObligatory AS FillObligatory
	|FROM
	|	SpecificationsAndCategories AS SpecificationsAndCategories
	|		LEFT JOIN Catalog.ProductsAndServicesCategories AS ProductsAndServicesCategories
	|			LEFT JOIN Catalog.AdditionalAttributesAndInformationSets.AdditionalAttributes AS AdditionalAttributesByCategory
	|			ON ProductsAndServicesCategories.SpecificationAttributesArray = AdditionalAttributesByCategory.Ref
	|		ON SpecificationsAndCategories.ProductsAndServicesCategory = ProductsAndServicesCategories.Ref
	|WHERE
	|	ISNULL(AdditionalAttributesByCategory.Property.FillObligatory, FALSE)
	|
	|UNION ALL
	|
	|SELECT
	|	SelectionTable.Specification,
	|	SelectionTable.ConnectionKey,
	|	AdditionalAttributesCommon.Property,
	|	AdditionalAttributesCommon.Property.FillObligatory
	|FROM
	|	SelectionTable AS SelectionTable
	|		LEFT JOIN Catalog.AdditionalAttributesAndInformationSets.AdditionalAttributes AS AdditionalAttributesCommon
	|		ON (AdditionalAttributesCommon.Ref = VALUE(Catalog.AdditionalAttributesAndInformationSets.Catalog_Specifications_Common))
	|WHERE
	|	ISNULL(AdditionalAttributesCommon.Property.FillObligatory, FALSE)";
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		FilterStructure = New Structure;
		FilterStructure.Insert("ConnectionKey", Selection.ConnectionKey);
		TSRows = TabularSection.FindRows(FilterStructure);
		FilterStructure.Insert("Property", Selection.Property);
		ValuesRows = Object.ParametricSpecificationsAttributes.FindRows(FilterStructure);
		If ValuesRows.Count()>0 And ValueIsFilled(ValuesRows[0].Value) Then
			Continue;
		EndIf;
		
		DependenciesTable = CommonUse.ObjectAttributeValue(Selection.Property, "AdditionalAttributeDependencies").Unload();
		FilterStructure = New Structure;
		FilterStructure.Insert("DependentProperty", "FillObligatory");
		DependenciesTable = DependenciesTable.Copy(FilterStructure);
		
		If DependenciesTable.Count() > 0 Then
			
			// Нужно получить все реквизиты объекта на случай, если по ним настроена зависимость.
			ObjectAdditionalAttributes = PropertiesManagement.PropertiesOfObject(Selection.Specification, True, False);
			AttributeValues = New Structure;
			For Each AdditionalAttribute In ObjectAdditionalAttributes Do
				Properties = CommonUse.ObjectAttributesValues(AdditionalAttribute, "Name,ValueType");
				FilterStructure = New Structure;
				FilterStructure.Insert("ConnectionKey", Selection.ConnectionKey);
				FilterStructure.Insert("Property", AdditionalAttribute);
				ValuesRows = Object.ParametricSpecificationsAttributes.FindRows(FilterStructure);
				Value = ?(ValuesRows.Count()>0, Properties.ValueType.AdjustValue(ValuesRows[0].Value), Properties.ValueType.AdjustValue(Undefined));
				AttributeValues.Insert(Properties.Name, Value);
			EndDo;
			
			DependentAttributeDescription = New Structure;
			DependentAttributeDescription.Insert("RequiredFillingCondition", Undefined);
			For Each DependencyRow In DependenciesTable Do
				If TypeOf(DependencyRow.Attribute) = Type("String") Then
					PathToAttribute = "Parameters.ObjectDescription." + DependencyRow.Attribute;
				Else
					PathToAttribute = "Parameters.Form." + CommonUse.ObjectAttributeValue(DependencyRow.Attribute, "Name");
				EndIf;
				PropertiesManagementService.BuildDependencyConditions(DependentAttributeDescription, PathToAttribute, DependencyRow);
				Parameters = DependentAttributeDescription.RequiredFillingCondition;
			EndDo;
			
			ConditionParameters = New Structure;
			ConditionParameters.Insert("ParameterValues", Parameters.ParameterValues);
			ConditionParameters.Insert("Form", AttributeValues);
			ConditionParameters.Insert("ObjectDescription", Selection.Specification);
			
			FillRequred = WorkInSafeMode.EvalInSafeMode(Parameters.ConditionCode, ConditionParameters);
			If Not FillRequred Then
				Continue;
			EndIf;
			
		EndIf;
		
		TabularSectionRow = TSRows[0];
		RowIndex = TabularSection.IndexOf(TabularSectionRow);
		TextOfMessage = NStr("en='The ""%1"" attribute for the ""%2"" BOM are not filled.';ru='Не заполнен реквизит ""%1"" для спецификации ""%2"".';vi='Chưa điền mục tin ""%1"" cho bảng chi tiết nguyên vật liệu ""%2"".'");
		TextOfMessage = StrTemplate(TextOfMessage, Selection.Property, Selection.Specification);
		Field = CommonUseClientServer.PathToTabularSection(TSName, TabularSectionRow.LineNumber, "SpecificationParameters");
		CommonUseClientServer.MessageToUser(TextOfMessage, , "Object." + Field, , Cancel);
		
	EndDo; 
	
EndProcedure

#EndRegion

#Region ServiceProgramInterface

Function OperandEndString() Export
	
	Return "]";
	
EndFunction

Function OperandBeginString() Export
	
	Return "[";
	
EndFunction

#EndRegion 

#Region InternalProceduresAndFunctions

Function GetFormulaOperandTable(RecordPeriod, FormulaStorage)
	
	Operands = New ValueTable;
	Operands.Columns.Add("Operand");
	Operands.Indexes.Add("Operand");
	
	If TypeOf(FormulaStorage) = Type("String") Then
		
		ParseFormulaToOperands(RecordPeriod, FormulaStorage, Operands);
		
	ElsIf TypeOf(FormulaStorage) = Type("Array") Then
		
		For Each ArrayElement In FormulaStorage Do
			
			ParseFormulaToOperands(RecordPeriod, ArrayElement, Operands);
			
		EndDo;
		
	EndIf;
	
	Return Operands;
	
EndFunction

Function OperandMappingForCheck(ProductsAndServicesCategory)
	
	OperandMapping = New Map;
	
	Scheme = Catalogs.Specifications.GetTemplate("FormulaDesignerScheme");
	If ValueIsFilled(ProductsAndServicesCategory) Then
		CategoryAttributes = CommonUse.ObjectAttributesValues(ProductsAndServicesCategory, "PropertySet, CharacteristicPropertySet, SpecificationAttributesArray");
		Scheme.Parameters.PropertySet.Value = CategoryAttributes.PropertySet;
		Scheme.Parameters.CharacteristicPropertySet.Value = CategoryAttributes.CharacteristicPropertySet;
		Scheme.Parameters.SpecificationAttributesArray.Value = CategoryAttributes.SpecificationAttributesArray;
	EndIf; 
	SchemaURL = PutToTempStorage(Scheme);
	Composer = New DataCompositionSettingsComposer;
	Composer.Initialize(New DataCompositionAvailableSettingsSource(SchemaURL));
	AvailableFields = Composer.Settings.GroupAvailableFields.Items;
	
	For Each Field In AvailableFields Do
		If Field.Folder Or Field.Resource Then
			Continue;
		EndIf;
		FieldName = String(Field.Field);
		For Each Attribute In Field.Items Do
			AttributeName = String(Attribute.Field);
			IsProductionRow = (AttributeName="CustomerOrder.Inventory" Or AttributeName="ProductionOrder.Products");
			If Attribute.Folder And Not IsProductionRow Then
				// Прочие табличные части
				Continue;
			EndIf;
			If Not Attribute.Folder Then
				OperandMapping.Insert(String(Attribute.Field), DefaultValue(Attribute.ValueType));
			Else
				For Each TSAttribute In Attribute.Items Do
					OperandMapping.Insert(String(TSAttribute.Field), DefaultValue(TSAttribute.ValueType));
				EndDo; 
			EndIf;
		EndDo;
	EndDo;
	
	Return OperandMapping;
	
EndFunction

Function DefaultValue(TypeDescription)
	
	Types = TypeDescription.Types();
	If Types.Count()=0 Then
		Return Undefined;
	EndIf;
	Type = Types[0];
	If Type=Type("Number") Then
		Return 10; // При проверке формулы значения всех числовых операндов принимаем равным 10
	ElsIf Type=Type("Boolean") Then
		Return True; // При проверке формулы значения всех булевых операндов принимаем равным "True"
	ElsIf Type=Type("String") Then
		Return ""; // При проверке формулы значения всех строковых операндов принимаем равным пустой строке
	ElsIf Type=Type("Date") Then
		Return CurrentSessionDate(); // При проверке формулы значения всех периодических операндов принимаем равным текущей дате
	Else
		Return New(Types[0]);
	EndIf; 
	
EndFunction
 
Procedure ParseFormulaToOperands(RecordPeriod, Formula, Operands)
	
	FormulaText = TrimAll(Formula);
	If IsBlankString(Formula) Then
		
		Return;
		
	EndIf;
	
	CharacterOperandBegin = OperandBeginString();
	CharacterOperandEnd	= OperandEndString();
	
	OperandsNumber = StrOccurrenceCount(FormulaText, CharacterOperandBegin);
	While OperandsNumber > 0 Do
		
		OperandBeginning = Find(FormulaText, CharacterOperandBegin);
		EndOfOperand = Find(FormulaText, CharacterOperandEnd);
		
		Operand = Mid(FormulaText, OperandBeginning, EndOfOperand - OperandBeginning + 1);
		OccurrencesNumber = StrOccurrenceCount(Operand, CharacterOperandBegin);
		If OccurrencesNumber>1 Then
			// Частный случай: имена дополнительных реквизитов также берутся в квадратные скобки
			EndOfOperand = StrFind(FormulaText, CharacterOperandEnd, , , OccurrencesNumber);
			Operand = Mid(FormulaText, OperandBeginning, EndOfOperand - OperandBeginning + 1);
			ID = Mid(Operand, 2, StrLen(Operand) - 2);
		Else
			ID = StrReplace(StrReplace(Operand, CharacterOperandBegin, ""), CharacterOperandEnd, "");
		EndIf; 
		
		If Operands.Find(Operand, "Operand") <> Undefined Then
			
			Return;
			
		EndIf;
		
		NewOperand = Operands.Add();
		NewOperand.Operand = Operand;
		
		FormulaText = StrReplace(FormulaText, Operand, "");
		OperandsNumber = StrOccurrenceCount(FormulaText, CharacterOperandBegin);
		
	EndDo;
	
EndProcedure

Function OrderPresentation(Data, ObjectName)
	
	OrderSynonym = Metadata.Documents[ObjectName].Synonym;
	Date = Data[ObjectName + ".Date"];
	Number = Data[ObjectName + ".Number"];
	NumberForPrinting = ObjectPrefixationClientServer.GetNumberForPrinting(Number, True, True);
	
	Return StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en = '%1 %2 of %3'; ru = '%1 %2 от %3'; vi = '%1 %2 of %3'"),
		OrderSynonym,
		NumberForPrinting,
		Format(Date, "DLF=D"));
	
EndFunction

Function CalculationData(OrderObject, DocOrder, ProductsAndServices, Characteristic, Specification, ConnectionKey)
	
	AccordingToSpecification = (TypeOf(Specification)<>Type("CatalogRef.Specifications"));
	If AccordingToSpecification Then
		ConnectionKey  = DefineLinkKeyBySpecification(DocOrder, Specification.Ref);
	EndIf; 
	Data = New Map;
	
	Query = New Query;
	Query.SetParameter("DocOrder", DocOrder);
	Query.SetParameter("ProductsAndServices", ProductsAndServices);
	Query.SetParameter("Characteristic", Characteristic);
	Query.SetParameter("Specification", ?(AccordingToSpecification, Undefined, Specification));
	Query.SetParameter("ConnectionKey", ConnectionKey);
	Query.Text = DataSelectionQueryText();
	Result = Query.ExecuteBatch();
	
	TableProductsAndServices = Result[0].Unload();
	SupplementCalculationData(Data, TableProductsAndServices);
	
	TableCharacteristic = Result[1].Unload();
	SupplementCalculationData(Data, TableCharacteristic);
	
	If AccordingToSpecification Then
		SpecificationMetadata = Metadata.Catalogs.Specifications;
		TableName = "Specification";
		Data.Insert(TableName, Specification.Ref);
		For Each Attribute In SpecificationMetadata.StandardAttributes Do
			PropertyName = StrTemplate("%1.%2", TableName, Attribute.Name);
			Data.Insert(PropertyName, Specification[Attribute.Name]);
		EndDo; 
		For Each Attribute In SpecificationMetadata.Attributes Do
			PropertyName = StrTemplate("%1.%2", TableName, Attribute.Name);
			Data.Insert(PropertyName, Specification[Attribute.Name]);
		EndDo;
		For Each RowAdditionalAttribute In Specification.AdditionalAttributes Do
			PropertyName = StrTemplate("%1.[%2]", TableName, String(RowAdditionalAttribute.Property));
			Data.Insert(PropertyName, RowAdditionalAttribute.Value);
		EndDo;
	Else
		TableSpecifications = Result[2].Unload();
		SupplementCalculationData(Data, TableSpecifications);
		Data["Specification.Content"].Sort("LineNumber");
		Data["Specification.Operations"].Sort("LineNumber");
		Data["Specification.ContentMapping"].Sort("LineNumber");
		Data["Specification.OperationsMapping"].Sort("LineNumber");
	EndIf; 

	TableCustomerOrder = Result[3].Unload();
	SupplementCalculationData(Data, TableCustomerOrder);

	TableProductionOrder = Result[4].Unload();
	SupplementCalculationData(Data, TableProductionOrder);
	
	If OrderObject<>Undefined Then
		DocumentMetadata = OrderObject.Ref.Metadata();
		TableName = DocumentMetadata.Name;
		Data.Insert(TableName, OrderObject.Ref);
		For Each Attribute In DocumentMetadata.StandardAttributes Do
			PropertyName = StrTemplate("%1.%2", TableName, Attribute.Name);
			Data.Insert(PropertyName, OrderObject[Attribute.Name]);
		EndDo; 
		For Each Attribute In DocumentMetadata.Attributes Do
			PropertyName = StrTemplate("%1.%2", TableName, Attribute.Name);
			Data.Insert(PropertyName, OrderObject[Attribute.Name]);
		EndDo;
		For Each RowAdditionalAttribute In OrderObject.AdditionalAttributes Do
			AdditAttributesProperties = CommonUse.ObjectAttributesValues(RowAdditionalAttribute.Property, "Presentation, ValueType");
			PropertyName = StrTemplate("%1.[%2]", TableName, AdditAttributesProperties.Presentation);
			Data.Insert(PropertyName, RowAdditionalAttribute.Value);
		EndDo;
		ObjectAdditionalAttributes = PropertiesManagement.PropertiesOfObject(OrderObject.Ref, True, False);
		For Each AdditionalAttribute In ObjectAdditionalAttributes Do
			AdditAttributesProperties = CommonUse.ObjectAttributesValues(AdditionalAttribute, "Presentation, ValueType");
			PropertyName = StrTemplate("%1.[%2]", TableName, AdditAttributesProperties.Presentation);
			If Data.Get(PropertyName)=Undefined Then
				Data.Insert(PropertyName, AdditAttributesProperties.ValueType.AdjustValue(Undefined));
			EndIf; 
		EndDo;
		FilterStructure = New Structure;
		FilterStructure.Insert("ConnectionKey", ConnectionKey);
		RowsSpecificationAttributes = OrderObject.ParametricSpecificationsAttributes.FindRows(FilterStructure);
		For Each RowAdditionalAttribute In RowsSpecificationAttributes Do
			PropertyName = StrTemplate("%1.[%2]", "Specification", String(RowAdditionalAttribute.Property));
			Data.Insert(PropertyName, RowAdditionalAttribute.Value);
		EndDo;
		If DocumentMetadata=Metadata.Documents.ProductionOrder Then
			MetadataTS = DocumentMetadata.TabularSections.Products;
		Else
			MetadataTS = DocumentMetadata.TabularSections.Inventory;
		EndIf; 
		OrderRows = OrderObject[MetadataTS.Name].FindRows(FilterStructure);
		If OrderRows.Count()=1 Then
			OrderRow = OrderRows[0];
			For Each TSAttribute In MetadataTS.Attributes Do
				PropertyName = StrTemplate("%1.%2.%3", TableName, MetadataTS.Name, TSAttribute.Name);
				Data.Insert(PropertyName, OrderRow[TSAttribute.Name]);
			EndDo; 
		EndIf; 
	EndIf; 
	
	Return Data;
	
EndFunction

Procedure SupplementCalculationData(Data, Table)
		
	If Table.Count()>0 Then
		TableRow = Table[0];
		Data.Insert(TableRow.TableName, TableRow.Ref);
		For Each Column In Table.Columns Do
			If Column.Name="AdditionalAttributes" Then
				Continue;
			EndIf;
			If TypeOf(TableRow[Column.Name])=Type("ValueTable") And (Column.Name="Inventory" Or Column.Name="Products") Then
				TableOfPM = TableRow[Column.Name];
				If TableOfPM.Count()=1 Then
					TSRow = TableOfPM[0];
					For Each ColumnTS In TableOfPM.Columns Do
						PropertyName = StrTemplate("%1.%2.%3", TableRow.TableName, Column.Name, ColumnTS.Name);
						Data.Insert(PropertyName, TSRow[ColumnTS.Name]);
					EndDo; 
				EndIf; 
			Else
				PropertyName = StrTemplate("%1.%2", TableRow.TableName, Column.Name);
				Data.Insert(PropertyName, TableRow[Column.Name]);
			EndIf; 
		EndDo;
		For Each RowAdditionalAttribute In TableRow.AdditionalAttributes Do
			PropertyName = StrTemplate("%1.[%2]", TableRow.TableName, RowAdditionalAttribute.Presentation);
			Data.Insert(PropertyName, RowAdditionalAttribute.Value);
		EndDo;
		ObjectAdditionalAttributes = PropertiesManagement.PropertiesOfObject(TableRow.Ref, True, False);
		For Each AdditionalAttribute In ObjectAdditionalAttributes Do
			AdditAttributesProperties = CommonUse.ObjectAttributesValues(AdditionalAttribute, "Presentation, ValueType");
			PropertyName = StrTemplate("%1.[%2]", TableRow.TableName, AdditAttributesProperties.Presentation);
			If Data.Get(PropertyName)=Undefined Then
				Data.Insert(PropertyName, AdditAttributesProperties.ValueType.AdjustValue(Undefined));
			EndIf; 
		EndDo;
	EndIf;
	
EndProcedure

Function DefineLinkKeyBySpecification(DocOrder, Specification)
	
	If Not ValueIsFilled(DocOrder) Then
		Return Undefined;
	EndIf; 
	
	If TypeOf(DocOrder)=Type("DocumentRef.ProductionOrder") Then
		TSName = Metadata.Documents.ProductionOrder.TabularSections.Products.Name;
	Else
		TSName = Metadata.Documents.CustomerOrder.TabularSections.Inventory.Name;
	EndIf;
	
	FilterStructure = New Structure;
	FilterStructure.Insert("Specification", Specification);
	Rows = DocOrder[TSName].FindRows(FilterStructure);
	If Rows.Count()=1 Then
		Return Rows[0].ConnectionKey;
	Else
		Return Undefined;
	EndIf; 
	
EndFunction

Function DataSelectionQueryText()
	
	Return 
	"SELECT ALLOWED
	|	""ProductsAndServices"" AS TableName,
	|	ProductsAndServices.Ref AS Ref,
	|	ProductsAndServices.DeletionMark AS DeletionMark,
	|	ProductsAndServices.Parent AS Parent,
	|	ProductsAndServices.IsFolder AS IsFolder,
	|	ProductsAndServices.Code AS Code,
	|	ProductsAndServices.Description AS Description,
	|	ProductsAndServices.Sku AS Sku,
	|	ProductsAndServices.AlcoholicProductsKind AS AlcoholicProductsKind,
	|	ProductsAndServices.WriteOutTheGuaranteeCard AS WriteOutTheGuaranteeCard,
	|	ProductsAndServices.GuaranteePeriod AS GuaranteePeriod,
	|	ProductsAndServices.ChangeDate AS ChangeDate,
	|	ProductsAndServices.MeasurementUnit AS MeasurementUnit,
	|	ProductsAndServices.ImportedAlcoholicProducts AS ImportedAlcoholicProducts,
	|	ProductsAndServices.UseBatches AS UseBatches,
	|	ProductsAndServices.UseSerialNumbers AS UseSerialNumbers,
	|	ProductsAndServices.UseCharacteristics AS UseCharacteristics,
	|	ProductsAndServices.ProductsAndServicesCategory AS ProductsAndServicesCategory,
	|	ProductsAndServices.Comment AS Comment,
	|	ProductsAndServices.EstimationMethod AS EstimationMethod,
	|	ProductsAndServices.DescriptionFull AS DescriptionFull,
	|	ProductsAndServices.BusinessActivity AS BusinessActivity,
	|	ProductsAndServices.TimeNorm AS TimeNorm,
	|	ProductsAndServices.VolumeDAL AS VolumeDAL,
	|	ProductsAndServices.Vendor AS Vendor,
	|	ProductsAndServices.AlcoholicProductsManufacturerImporter AS AlcoholicProductsManufacturerImporter,
	|	ProductsAndServices.Warehouse AS Warehouse,
	|	ProductsAndServices.ReplenishmentMethod AS ReplenishmentMethod,
	|	ProductsAndServices.OrderCompletionDeadline AS OrderCompletionDeadline,
	|	ProductsAndServices.ReplenishmentDeadline AS ReplenishmentDeadline,
	|	ProductsAndServices.CountryOfOrigin AS CountryOfOrigin,
	|	ProductsAndServices.InventoryGLAccount AS InventoryGLAccount,
	|	ProductsAndServices.ExpensesGLAccount AS ExpensesGLAccount,
	|	ProductsAndServices.ProductsAndServicesType AS ProductsAndServicesType,
	|	ProductsAndServices.PictureFile AS PictureFile,
	|	ProductsAndServices.FixedCost AS FixedCost,
	|	ProductsAndServices.PriceGroup AS PriceGroup,
	|	ProductsAndServices.Cell AS Cell,
	|	ProductsAndServices.AdditionalAttributes.(
	|		Property AS Property,
	|		Value AS Value,
	|		Property.Presentation AS Presentation
	|	) AS AdditionalAttributes
	|FROM
	|	Catalog.ProductsAndServices AS ProductsAndServices
	|WHERE
	|	ProductsAndServices.Ref = &ProductsAndServices
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	""Characteristic"" AS TableName,
	|	ProductsAndServicesCharacteristics.Ref AS Ref,
	|	ProductsAndServicesCharacteristics.DeletionMark AS DeletionMark,
	|	ProductsAndServicesCharacteristics.Owner AS Owner,
	|	ProductsAndServicesCharacteristics.Code AS Code,
	|	ProductsAndServicesCharacteristics.Description AS Description,
	|	ProductsAndServicesCharacteristics.AdditionalAttributes.(
	|		Property AS Property,
	|		Value AS Value,
	|		Property.Presentation AS Presentation
	|	) AS AdditionalAttributes
	|FROM
	|	Catalog.ProductsAndServicesCharacteristics AS ProductsAndServicesCharacteristics
	|WHERE
	|	ProductsAndServicesCharacteristics.Ref = &Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	""Specification"" AS TableName,
	|	Specifications.Ref AS Ref,
	|	Specifications.DeletionMark AS DeletionMark,
	|	Specifications.Owner AS Owner,
	|	Specifications.Code AS Code,
	|	Specifications.Description AS Description,
	|	Specifications.ProductCharacteristic AS ProductCharacteristic,
	|	Specifications.DocOrder AS DocOrder,
	|	Specifications.Comment AS Comment,
	|	Specifications.ProductionKind AS ProductionKind,
	|	Specifications.NotValid AS NotValid,
	|	Specifications.IsTemplate AS IsTemplate,
	|	Specifications.BaseSpecification AS BaseSpecification,
	|	Specifications.AdditionalAttributes.(
	|		Property AS Property,
	|		Value AS Value,
	|		Property.Presentation AS Presentation
	|	) AS AdditionalAttributes,
	|	Specifications.Content.(
	|		LineNumber AS LineNumber,
	|		ContentRowType AS ContentRowType,
	|		ProductsAndServices AS ProductsAndServices,
	|		Characteristic AS Characteristic,
	|		MeasurementUnit AS MeasurementUnit,
	|		Specification AS Specification,
	|		Quantity AS Quantity,
	|		ProductsQuantity AS ProductsQuantity,
	|		CostPercentage AS CostPercentage,
	|		Stage AS Stage,
	|		FormulaProductsAndServices AS FormulaProductsAndServices,
	|		FormulaNumber AS FormulaNumber,
	|		ConnectionKey AS ConnectionKey,
	|		MappingUsed AS MappingUsed,
	|		LongDesc AS LongDesc
	|	) AS Content,
	|	Specifications.Operations.(
	|		LineNumber AS LineNumber,
	|		Operation AS Operation,
	|		TimeNorm AS TimeNorm,
	|		Quantity AS Quantity,
	|		ProductsQuantity AS ProductsQuantity,
	|		Stage AS Stage,
	|		FormulaOperation AS FormulaOperation,
	|		FormulaNumber AS FormulaNumber,
	|		FormulaTimeNorm AS FormulaTimeNorm,
	|		ConnectionKey AS ConnectionKey,
	|		MappingUsed AS MappingUsed,
	|		LongDesc AS LongDesc
	|	) AS Operations,
	|	Specifications.ContentMapping.(
	|		LineNumber AS LineNumber,
	|		ConnectionKey AS ConnectionKey,
	|		ProductsAndServices AS ProductsAndServices,
	|		Characteristic AS Characteristic,
	|		MappingAttribute AS MappingAttribute,
	|		ValueOfAttribute AS ValueOfAttribute,
	|		RulesRowKey AS RulesRowKey
	|	) AS ContentMapping,
	|	Specifications.OperationsMapping.(
	|		LineNumber AS LineNumber,
	|		ConnectionKey AS ConnectionKey,
	|		Operation AS Operation,
	|		MappingAttribute AS MappingAttribute,
	|		ValueOfAttribute AS ValueOfAttribute,
	|		RulesRowKey AS RulesRowKey
	|	) AS OperationsMapping
	|FROM
	|	Catalog.Specifications AS Specifications
	|WHERE
	|	Specifications.Ref = &Specification
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	""CustomerOrder"" AS TableName,
	|	CustomerOrder.Ref AS Ref,
	|	CustomerOrder.DeletionMark AS DeletionMark,
	|	CustomerOrder.Number AS Number,
	|	CustomerOrder.Date AS Date,
	|	CustomerOrder.Posted AS Posted,
	|	CustomerOrder.Author AS Author,
	|	CustomerOrder.BankAccount AS BankAccount,
	|	CustomerOrder.DocumentCurrency AS DocumentCurrency,
	|	CustomerOrder.OperationKind AS OperationKind,
	|	CustomerOrder.WorkKind AS WorkKind,
	|	CustomerOrder.DiscountMarkupKind AS DiscountMarkupKind,
	|	CustomerOrder.PriceKind AS PriceKind,
	|	CustomerOrder.IncomingDocumentDate AS IncomingDocumentDate,
	|	CustomerOrder.ChangeDate AS ChangeDate,
	|	CustomerOrder.ShipmentDate AS ShipmentDate,
	|	CustomerOrder.DiscountCard AS DiscountCard,
	|	CustomerOrder.Contract AS Contract,
	|	CustomerOrder.SchedulePayment AS SchedulePayment,
	|	CustomerOrder.UsePerformerSalaries AS UsePerformerSalaries,
	|	CustomerOrder.UseMaterials AS UseMaterials,
	|	CustomerOrder.UseConsumerMaterials AS UseConsumerMaterials,
	|	CustomerOrder.UseProducts AS UseProducts,
	|	CustomerOrder.PettyCash AS PettyCash,
	|	CustomerOrder.Comment AS Comment,
	|	CustomerOrder.Counterparty AS Counterparty,
	|	CustomerOrder.Multiplicity AS Multiplicity,
	|	CustomerOrder.ExchangeRate AS ExchangeRate,
	|	CustomerOrder.VATTaxation AS VATTaxation,
	|	CustomerOrder.IncludeVATInPrice AS IncludeVATInPrice,
	|	CustomerOrder.IncomingDocumentNumber AS IncomingDocumentNumber,
	|	CustomerOrder.Company AS Company,
	|	CustomerOrder.Responsible AS Responsible,
	|	CustomerOrder.WorkKindPosition AS WorkKindPosition,
	|	CustomerOrder.ShipmentDatePosition AS ShipmentDatePosition,
	|	CustomerOrder.WarehousePosition AS WarehousePosition,
	|	CustomerOrder.Project AS Project,
	|	CustomerOrder.DiscountPercentByDiscountCard AS DiscountPercentByDiscountCard,
	|	CustomerOrder.DiscountsAreCalculated AS DiscountsAreCalculated,
	|	CustomerOrder.Event AS Event,
	|	CustomerOrder.OrderState AS OrderState,
	|	CustomerOrder.ProductsAndServicesList AS ProductsAndServicesList,
	|	CustomerOrder.ResourcesList AS ResourcesList,
	|	CustomerOrder.Start AS Start,
	|	CustomerOrder.SalesStructuralUnit AS SalesStructuralUnit,
	|	CustomerOrder.StructuralUnitReserve AS StructuralUnitReserve,
	|	CustomerOrder.AmountIncludesVAT AS AmountIncludesVAT,
	|	CustomerOrder.DocumentAmount AS DocumentAmount,
	|	CustomerOrder.CashAssetsType AS CashAssetsType,
	|	CustomerOrder.Finish AS Finish,
	|	CustomerOrder.Cell AS Cell,
	|	CustomerOrder.AdditionalAttributes.(
	|		Property AS Property,
	|		Value AS Value,
	|		Property.Presentation AS Presentation
	|	) AS AdditionalAttributes,
	|	CustomerOrder.Inventory.(
	|		LineNumber AS LineNumber,
	|		ProductsAndServicesTypeInventory AS ProductsAndServicesTypeInventory,
	|		ProductsAndServices AS ProductsAndServices,
	|		Characteristic AS Characteristic,
	|		SerialNumbers AS SerialNumbers,
	|		Reserve AS Reserve,
	|		MeasurementUnit AS MeasurementUnit,
	|		Price AS Price,
	|		DiscountMarkupPercent AS DiscountMarkupPercent,
	|		Amount AS Amount,
	|		VATRate AS VATRate,
	|		VATAmount AS VATAmount,
	|		Total AS Total,
	|		ShipmentDate AS ShipmentDate,
	|		Specification AS Specification,
	|		Content AS Content,
	|		AutomaticDiscountsPercent AS AutomaticDiscountsPercent,
	|		AutomaticDiscountAmount AS AutomaticDiscountAmount,
	|		Quantity AS Quantity,
	|		ConnectionKey AS ConnectionKey,
	|		Batch AS Batch,
	|		StructuralUnitReserve AS StructuralUnitReserve,
	|		Cell AS Cell
	|	) AS Inventory
	|FROM
	|	Document.CustomerOrder AS CustomerOrder
	|WHERE
	|	CustomerOrder.Ref = &DocOrder
	|	AND (&ConnectionKey = UNDEFINED
	|			OR CustomerOrder.Inventory.ConnectionKey = &ConnectionKey)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	""ProductionOrder"" AS TableName,
	|	ProductionOrder.Ref AS Ref,
	|	ProductionOrder.DeletionMark AS DeletionMark,
	|	ProductionOrder.Number AS Number,
	|	ProductionOrder.Date AS Date,
	|	ProductionOrder.Posted AS Posted,
	|	ProductionOrder.Author AS Author,
	|	ProductionOrder.OperationKind AS OperationKind,
	|	ProductionOrder.BasisDocument AS BasisDocument,
	|	ProductionOrder.CustomerOrder AS CustomerOrder,
	|	ProductionOrder.Comment AS Comment,
	|	ProductionOrder.Company AS Company,
	|	ProductionOrder.Responsible AS Responsible,
	|	ProductionOrder.OrderState AS OrderState,
	|	ProductionOrder.ProductsAndServicesList AS ProductsAndServicesList,
	|	ProductionOrder.ResourcesList AS ResourcesList,
	|	ProductionOrder.Start AS Start,
	|	ProductionOrder.StructuralUnit AS StructuralUnit,
	|	ProductionOrder.StructuralUnitReserve AS StructuralUnitReserve,
	|	ProductionOrder.Finish AS Finish,
	|	ProductionOrder.WarehousePosition AS WarehousePosition,
	|	ProductionOrder.CustomerOrderPosition AS CustomerOrderPosition,
	|	ProductionOrder.Performer AS Performer,
	|	ProductionOrder.AdditionalAttributes.(
	|		Ref AS Ref,
	|		LineNumber AS LineNumber,
	|		Property AS Property,
	|		Value AS Value,
	|		TextString AS TextString
	|	) AS AdditionalAttributes,
	|	ProductionOrder.Products.(
	|		LineNumber AS LineNumber,
	|		ProductsAndServices AS ProductsAndServices,
	|		ProductsAndServicesType AS ProductsAndServicesType,
	|		Characteristic AS Characteristic,
	|		Quantity AS Quantity,
	|		Reserve AS Reserve,
	|		MeasurementUnit AS MeasurementUnit,
	|		Specification AS Specification,
	|		Batch AS Batch,
	|		StructuralUnit AS StructuralUnit,
	|		CustomerOrder AS CustomerOrder,
	|		ConnectionKey AS ConnectionKey,
	|		CompletiveStageDepartment AS CompletiveStageDepartment
	|	) AS Products
	|FROM
	|	Document.ProductionOrder AS ProductionOrder
	|WHERE
	|	ProductionOrder.Ref = &DocOrder
	|	AND (&ConnectionKey = UNDEFINED
	|			OR ProductionOrder.Products.ConnectionKey = &ConnectionKey)";
	
EndFunction

Procedure AddOperandToStructure(OperandMapping, Operand, Value)
	
	If TypeOf(OperandMapping) <> Type("Map") Then
		
		OperandMapping = New Map;
		
	EndIf;
	
	OperandMapping.Insert(Operand, Value);
	
EndProcedure

Procedure DataCalculationByMapping(MappingTable, SpecificationRow, Data, EstimatedData)
	
	If EstimatedData = Undefined Then
		EstimatedData = New Structure("Result, CalculationError, ByMapping, ErrorText", Undefined, False, True);
	EndIf;
	
	ByOperations = MappingTable.Columns.Find("Operation")<>Undefined;
	Result = New Structure;
	
	QueryText = 
	"SELECT
	|	MappingTable.ConnectionKey AS ConnectionKey,
	|	MappingTable.RulesRowKey AS RulesRowKey,
	|	MappingTable.MappingAttribute AS MappingAttribute,
	|	MappingTable.ValueOfAttribute AS ValueOfAttribute,
	|	%AreaProductsAndServices%
	|	
	|INTO MappingTable
	|FROM
	|	&MappingTable AS MappingTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MappingTable.ConnectionKey AS ConnectionKey,
	|	MappingTable.RulesRowKey AS RulesRowKey,
	|	MappingTable.MappingAttribute AS MappingAttribute,
	|	MappingTable.ValueOfAttribute AS ValueOfAttribute,
	|	%AreaProductsAndServices%
	|FROM
	|	MappingTable AS MappingTable
	|WHERE
	|	MappingTable.ConnectionKey = &ConnectionKey
	|TOTALS BY
	|	RulesRowKey";
	
	If ByOperations Then
		QueryText = StrReplace(
		QueryText, 
		"%AreaProductsAndServices%",
		"MappingTable.Operation AS Operation");
	Else
		QueryText = StrReplace(
		QueryText, 
		"%AreaProductsAndServices%",
		"MappingTable.ProductsAndServices AS ProductsAndServices,
		|	MappingTable.Characteristic AS Characteristic");
	EndIf; 
	
	Query = New Query;
	Query.SetParameter("MappingTable", MappingTable);
	Query.SetParameter("ConnectionKey", SpecificationRow.ConnectionKey);
	Query.Text = QueryText;
	SelectionRules = Query.Execute().Select(QueryResultIteration.ByGroups);
	While SelectionRules.Next() Do
		Completed = True;
		SelectionItems = SelectionRules.Select();
		If SelectionItems.Count()=0 Then
			Continue;
		EndIf; 
		While SelectionItems.Next() Do
			Value = Data.Get(SelectionItems.MappingAttribute);
			If Value<>SelectionItems.ValueOfAttribute Then
				Completed = False;
				Break;
			EndIf; 
		EndDo;
		If Completed Then
			SelectionItems.Reset();
			SelectionItems.Next();
			If ByOperations Then
				Result.Insert("Operation", SelectionItems.Operation);
			Else
				Result.Insert("ProductsAndServices", SelectionItems.ProductsAndServices);
				Result.Insert("Characteristic", SelectionItems.Characteristic);
			EndIf; 
			Break;
		EndIf; 
	EndDo;
	
	If Result.Count()=0 Then
		EstimatedData.CalculationError = True;
		EstimatedData.ErrorText = StrTemplate(
		NStr("en='Can not find %1 on mapping %2';ru='Не удалось определить %1 по сопоставлению %2';vi='Không thể xác định %1 theo khớp %2'"), 
		?(ByOperations, NStr("en='Operation';ru='операцию';vi='Thao tác'"), NStr("en='inventory';ru='запас';vi='hàng tồn kho'")),
		SpecificationRow.LongDesc);
	Else 
		EstimatedData.Result = Result;
	EndIf; 
	
EndProcedure

Procedure FillOperandsAndCalculate(StringFormula, Data, EstimatedData)
	Var OperandMapping;	
	
	AbsentAttributes = New Array;
	OperandTable = GetFormulaOperandTable(CurrentSessionDate(), StringFormula);
	For Each Row In OperandTable Do
		
		ID = Mid(Row.Operand, 2, StrLen(Row.Operand) - 2);
		If MappingKeyExists(Data, ID) Then
			Value = Data.Get(ID);
			AddOperandToStructure(OperandMapping, Row.Operand, Value);
		Else
			AbsentAttributes.Add(ID); 
		EndIf; 
		
	EndDo;
	
	If AbsentAttributes.Count()>0 Then
		If EstimatedData = Undefined Then
			EstimatedData = New Structure("Result, CalculationError, ErrorText", Undefined, False);
		EndIf;
		EstimatedData.CalculationError = True;
		EstimatedData.ErrorText = StrTemplate(NStr("en='Not available attribute required to calculate the formula: %1';ru='Недоступны реквизиты, требующиеся для расчета формулы: %1';vi='Các yêu cầu cần thiết để tính công thức không có sẵn: %1'"), StrConcat(AbsentAttributes, ", "));
	Else
		DataCalculationByFormula(StringFormula, OperandMapping, EstimatedData);
	EndIf; 

EndProcedure

Procedure DataCalculationByFormula(Val StringFormula, OperandStructure, EstimatedData)
	
	If EstimatedData = Undefined Then
		EstimatedData = New Structure("Result, CalculationError, ErrorText", Undefined, False);
	EndIf;
	
	If Find(StringFormula, "#IF") > 0 Then
		StringFormula = StrReplace(StringFormula, "#IF",		"?(");
		StringFormula = StrReplace(StringFormula, "#THEN",		",");
		StringFormula = StrReplace(StringFormula, "#ELSE",		",");
		StringFormula = StrReplace(StringFormula, "#ENDIF",	")");
		StringFormula = StrReplace(StringFormula, Chars.LF,	"");
	EndIf;
	
	CalculationParameters = New Structure;
	
	If OperandStructure<>Undefined Then
		
		ParameterNumber = 1;
		For Each Operand In OperandStructure Do
			
			If TypeOf(Operand.Value)=Type("Number") Then
				ValueByString = Format(Operand.Value, "NDS=.; NZ=0; NG=0");
			ElsIf TypeOf(Operand.Value)=Type("String") Then
				ValueByString = StrTemplate("""%1""", Operand.Value);
			ElsIf TypeOf(Operand.Value)=Type("Boolean") Then
				ValueByString = Format(Operand.Value, "BF=False; BT=True");
			ElsIf TypeOf(Operand.Value)=Type("Date") Then
				ValueByString = StrTemplate("'%1'", Format(Operand.Value, "DF='yyyy-MM-dd HH:mm:ss'"));
			Else
				ParameterName = "Parameter" + ParameterNumber;
				CalculationParameters.Insert(ParameterName, Operand.Value);
				ValueByString = "Parameters." + ParameterName;
				ParameterNumber = ParameterNumber + 1;
			EndIf; 
			StringFormula = StrReplace(StringFormula, Operand.Key, ValueByString);
			
		EndDo;
		
	EndIf; 
	
	Try
		
		Result = WorkInSafeMode.EvalInSafeMode(StringFormula, CalculationParameters);
		EstimatedData.Result = Result;
		
	Except
		
		EstimatedData.CalculationError = True;
		EstimatedData.ErrorText = DetailErrorDescription(ErrorInfo());
		
	EndTry;
	
EndProcedure

Function CalculationErrorsExists(EstimatedData, Errors, TypeRestriction = Undefined, ChoiceParameters = Undefined, PathToField = "")
	
	// Тест расчета формулы
	If EstimatedData.CalculationError Then
		
		If EstimatedData.Property("ByMapping") And EstimatedData.ByMapping Then
			ErrorText = StrTemplate(NStr("en='There were errors in the calculation. Check the match is correct."
"Detailed description:"
"%1';ru='При расчете возникли ошибки. Проверьте правильность сопоставления."
"Подробное описание:"
"%1';vi='Có lỗi trong tính toán. Kiểm tra xem khớp có đúng không."
"Mô tả chi tiết:"
"%1'"), EstimatedData.ErrorText);
		Else
			ErrorText = StrTemplate(NStr("en='There were errors in the calculation. Check the correct spelling of the formula."
"Detailed description:"
"%1';ru='При расчете возникли ошибки. Проверьте правильность написания формулы."
"Подробное описание:"
"%1';vi='Có lỗi trong tính toán. Kiểm tra công thức."
"Mô tả chi tiết:"
"%1'"), EstimatedData.ErrorText);
		EndIf; 
		
		CommonUseClientServer.AddUserError(Errors, PathToField, ErrorText, "");
		Return True;
		
	EndIf;
	
	// Проверка типа результата 
	If TypeRestriction<>Undefined 
		And Not TypeRestriction.ContainsType(TypeOf(EstimatedData.Result)) Then
		
		ErrorText = StrTemplate(NStr("en='The type of value received does not match the expected: %1';ru='Тип полученного значения не соответствует ожидаемому: %1';vi='Loại giá trị được trả về không như mong đợi:%1'"), String(TypeOf(EstimatedData.Result)));
		CommonUseClientServer.AddUserError(Errors, PathToField, ErrorText, "");
		Return True;
		
	EndIf;
	
	// Проверка ограничений типа результата по параметрам выбора
	If ChoiceParameters<>Undefined And ChoiceParameters.Count()>0 Then
		VerifiedValue = EstimatedData.Result;
		If TypeOf(VerifiedValue)=Type("Structure") Then
			If VerifiedValue.Property("ProductsAndServices") Then
				VerifiedValue = VerifiedValue.ProductsAndServices;
			ElsIf VerifiedValue.Property("Operation") Then
				VerifiedValue = VerifiedValue.Operation;
			Else
				VerifiedValue = Undefined;
			EndIf; 
		EndIf;
		If ValueIsFilled(VerifiedValue) Then
			RestrictionStructure = New Structure;
			NamesOfFields = New Array;
			For Each ChoiceParameter In ChoiceParameters Do
				FieldName = StrReplace(ChoiceParameter.Name, "Filter.", "");
				RestrictionStructure.Insert(FieldName, ChoiceParameter.Value);
				NamesOfFields.Add(FieldName);
			EndDo; 
			FieldValues = CommonUse.ObjectAttributesValues(VerifiedValue, StrConcat(NamesOfFields, ","));
			For Each Rstrictions In RestrictionStructure Do
				CurrentValue = FieldValues[Rstrictions.Key];
				If (TypeOf(Rstrictions.Value)=Type("FixedArray") And Rstrictions.Value.Find(CurrentValue)=Undefined)
					Or (TypeOf(Rstrictions.Value)<>Type("FixedArray") And Rstrictions.Value<>CurrentValue) Then
					
					ErrorText = StrTemplate(NStr("en='Inappropriate result of %1 per field: %2';ru='Неподходящий результат расчета %1 по полю: %2';vi='Kết quả tính toán không phù hợp %1 theo trường: %2'"), VerifiedValue, Rstrictions.Key);
					CommonUseClientServer.AddUserError(Errors, PathToField, ErrorText, "");
					Return True;
					
				EndIf; 
			EndDo; 
		EndIf; 
	EndIf; 
	
	Return False;
	
EndFunction

Function MappingKeyExists(Map, Key) Export
	
	For Each KeyAndValue In Map Do
		If KeyAndValue.Key=Key Then
			Return True;
		EndIf; 
	EndDo; 
	
	Return False;
	
EndFunction

#EndRegion 

 