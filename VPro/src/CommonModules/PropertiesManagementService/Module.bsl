////////////////////////////////////////////////////////////////////////////////
// Properties subsystem
// 
////////////////////////////////////////////////////////////////////////////////

#Region ServiceProgramInterface

// See details of the same procedure in the StandardSubsystemsServer module.
Procedure OnAddHandlersOfServiceEvents(ClientHandlers, ServerHandlers) Export
	
	// SERVERSIDE HANDLERS.
	
	ServerHandlers["StandardSubsystems.InfobaseVersionUpdate\OnAddUpdateHandlers"].Add(
		"PropertiesManagementService");
		
	ServerHandlers["StandardSubsystems.BasicFunctionality\OnAddExceptionsSearchLinks"].Add(
		"PropertiesManagementService");
	
	ServerHandlers["StandardSubsystems.BasicFunctionality\OnGettingObligatoryExchangePlanObjects"].Add(
		"PropertiesManagementService");
	
	ServerHandlers["StandardSubsystems.BasicFunctionality\OnGetPrimaryImagePlanExchangeObjects"].Add(
		"PropertiesManagementService");
	
	ServerHandlers["StandardSubsystems.BasicFunctionality\OnAddSessionSettingsSetupHandler"].Add(
		"PropertiesManagementService");
	
	If CommonUse.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ServerHandlers["StandardSubsystems.AccessManagement\OnFillingKindsOfRestrictionsRightsOfMetadataObjects"].Add(
			"PropertiesManagementService");
		
		ServerHandlers["StandardSubsystems.AccessManagement\OnFillAccessKinds"].Add(
			"PropertiesManagementService");
	EndIf;
	
EndProcedure

// Returns the list of all properties for metadata object.
//
// Parameters:
//  ObjectsKind - String - Full metadata object name;
//  PropertiesKind  - String - "AdditionalAttributes" or "AdditionalInformation".
//
// ReturnValue:
//  ValueTable - Property, Description, ValueType.
//  Undefined    - there is no set of properties for specified kind of object.
//
Function PropertyListForObjectKind(ObjectsKind, Val PropertiesKind) Export
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	PropertiesSets.Ref AS Ref,
		|	PropertiesSets.PredefinedDataName AS PredefinedDataName
		|FROM
		|	Catalog.AdditionalAttributesAndInformationSets AS PropertiesSets
		|WHERE
		|	PropertiesSets.Predefined";
	Selection = Query.Execute().Select();
	
	PredefinedDataName = StrReplace(ObjectsKind, ".", "_");
	SetReference = Undefined;
	
	While Selection.Next() Do
		If StrStartsWith(Selection.PredefinedDataName, "Delete") Then
			Continue;
		EndIf;
		
		If Selection.PredefinedDataName = PredefinedDataName Then
			SetReference = Selection.Ref;
			Break;
		EndIf;
	EndDo;
	
	If SetReference = Undefined Then
		SetReference = PropertiesManagement.PropertySetByName(PredefinedDataName);
		If SetReference = Undefined Then
			Return Undefined;
		EndIf;
	EndIf;
	
	QueryText = 
		"SELECT
		|	PropertyTable.Property AS Property,
		|	PropertyTable.Property.Description AS Description,
		|	PropertyTable.Property.ValueType AS ValueType
		|FROM
		|	&PropertyTable AS PropertyTable
		|WHERE
		|	PropertyTable.Ref IN HIERARCHY(&Ref)";
	
	FullTableName = "Catalog.AdditionalAttributesAndInformationSets." + PropertiesKind;
	QueryText = StrReplace(QueryText, "&PropertyTable", FullTableName);
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", SetReference);
	
	Result = Query.Execute().Unload();
	Result.GroupBy("Property,Description,ValueType");
	Result.Sort("Description Asc");
	
	Return Result;
	
EndFunction

// Дополняет список колонки для загрузки данных колонками дополнительных реквизитов и свойств.
//
// Parameters:
//  CatalogMetadata	 - MetadataObject - Метаданные справочника.
//  InformationByColumns	 - ТаблицаЗначение - колонки макета.
//
Procedure ColumnsForDataImport(CatalogMetadata, InformationByColumns) Export
	
	If CatalogMetadata.TabularSections.Find("AdditionalAttributes") <> Undefined Then
		
		Position = InformationByColumns.Count() + 1;
		Properties = PropertiesManagement.PropertiesOfObject(Catalogs[CatalogMetadata.Name].EmptyRef());
		
		AdditionalInformation = New Array;
		For Each Property In Properties Do
			If Not Property.ThisIsAdditionalInformation Then
				RowInfoAboutColumns = InformationByColumns.Add();
				ColumnName = StandardSubsystemsServer.TransformStringToValidColumnDescription(String(Property));
				RowInfoAboutColumns.ColumnName = "AdditionalAttribute_" + ColumnName;
				RowInfoAboutColumns.ColumnPresentation = String(Property);
				RowInfoAboutColumns.ColumnType = Property.ValueType;
				RowInfoAboutColumns.ObligatoryToComplete = Property.FillObligatory;
				RowInfoAboutColumns.Position = Position;
				RowInfoAboutColumns.Group = NStr("en='Additional attributes';ru='Доп. реквизиты';vi='Thuộc tính bổ sung'");
				RowInfoAboutColumns.Visible = True;
				RowInfoAboutColumns.Comment = String(Property);
				RowInfoAboutColumns.Width = 30;
				Position = Position + 1;
				
				Values = PropertyAdditionalValues(Property);
				If Values.Count() > 0 Then
					RowInfoAboutColumns.Comment = RowInfoAboutColumns.Comment  + Chars.LF + NStr("en='Options for values:';ru='Варианты значений:';vi='Tùy chọn giá trị:'") + Chars.LF;
					For Each Value In Values Do
						Code = ?(ValueIsFilled(Value.Code), " (" + Value.Code + ")", "");
						RowInfoAboutColumns.Comment = RowInfoAboutColumns.Comment + Value.Description + Code +Chars.LF;
					EndDo;
				EndIf;
			Else
				AdditionalInformation.Add(Property);
			EndIf;
		EndDo;
		
		For Each Property In AdditionalInformation Do
			RowInfoAboutColumns = InformationByColumns.Add();
			ColumnName =  StandardSubsystemsServer.TransformStringToValidColumnDescription(String(Property));
			RowInfoAboutColumns.ColumnName = "Property_" + ColumnName;
			RowInfoAboutColumns.ColumnPresentation = String(Property);
			RowInfoAboutColumns.ColumnType = Property.ValueType;
			RowInfoAboutColumns.ObligatoryToComplete = Property.FillObligatory;
			RowInfoAboutColumns.Position = Position;
			RowInfoAboutColumns.Group = NStr("en='Additional properties';ru='Доп. свойства';vi='Thuộc tính bổ sung'");
			RowInfoAboutColumns.Visible = True;
			RowInfoAboutColumns.Comment = String(Property);
			RowInfoAboutColumns.Width = 30;
			Position = Position + 1;
			
			Values = PropertyAdditionalValues(Property);
			If Values.Count() > 0 Then
				RowInfoAboutColumns.Comment = RowInfoAboutColumns.Comment  + Chars.LF + NStr("en='Options for values:';ru='Варианты значений:';vi='Tùy chọn giá trị:'") + Chars.LF;
				For Each Value In Values Do
					Code = ?(ValueIsFilled(Value.Code), " (" + Value.Code + ")", "");
					RowInfoAboutColumns.Comment = RowInfoAboutColumns.Comment + Value.Description + Code +Chars.LF;
				EndDo;
			EndIf;
			
		EndDo;

	EndIf;

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Обработчики событий подсистем конфигурации.

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.SharedData = True;
	Handler.HandlersManagement = True;
	Handler.Version = "*";
	Handler.PerformModes = "Promptly";
	Handler.Procedure = "PropertiesManagementService.FillSeparatedDataHandlers";
	
	Handler = Handlers.Add();
	Handler.Version = "*";
	Handler.Procedure = "PropertiesManagementService.CreatePredefinedPropertySets";
	Handler.PerformModes = "Promptly";
	Handler.InitialFilling = True;
	
	Handler = Handlers.Add();
	Handler.Version = "2.2.5.20";
	Handler.Procedure = "PropertiesManagementService.SetSignUsedValue";
	Handler.PerformModes = "Promptly";
	Handler.InitialFilling = True;
	
	Handler = Handlers.Add();
	Handler.Version = "2.2.5.20";
	Handler.Procedure = "ChartsOfCharacteristicTypes.AdditionalAttributesAndInformation.ОбработатьДанныеДляПереходаНаНовуюВерсию";
	Handler.Comment = NStr("en='Fills in a unique name and updates the dependencies of additional details and information."
"Editing additional details and information will not be available until the update is complete.';ru='Заполняет уникальное имя и обновляет зависимости дополнительных реквизитов и сведений."
"Редактирование дополнительных реквизитов и сведений будет недоступно до завершения обновления.';vi='Tạo một tên duy nhất và cập nhật thêm các mục tin và thông tin phụ thuộc. Chỉnh sửa mục tin và thông tin bổ sung sẽ không có sẵn cho đến khi cập nhật hoàn tất.'");
	Handler.PerformModes = "Delay";
	
	Handler = Handlers.Add();
	Handler.Version = "*";
	Handler.PerformModes = "Delay";
	Handler.Comment = NStr("en='Restructuring additional details and information."
"Additional details and details of some documents are completed until processing is complete"
"and guides will not be available.';ru='Реструктуризация дополнительных реквизитов и сведений."
"До завершения обработки дополнительные реквизиты и сведения некоторых документов"
"и справочников будут недоступны.';vi='Tái cấu trúc các yêu cầu và thông tin bổ sung."
"Cho đến khi xử lý hoàn tất, các chi tiết và thông tin bổ sung của một số chứng từ và danh mục sẽ không có sẵn.'");
	Handler.Procedure = "Catalogs.AdditionalAttributesAndInformationSets.ProcessPropertySetsForNewVersionUpdgrade";
	
EndProcedure

// See ObjectsAttributesEditProhibitionOverridable.OnDetermineObjectsWithLockedAttributes.
Procedure OnDetermineObjectsWithLockedAttributes(Objects) Export
	Objects.Insert(Metadata.ChartsOfCharacteristicTypes.AdditionalAttributesAndInformation.FullName(), "");
EndProcedure

// See GroupObjectChangeOverridable.WhenDefiningObjectsWithEditableAttributes.
Procedure WhenDefiningObjectsWithEditableAttributes(Objects) Export
	Objects.Insert(Metadata.ChartsOfCharacteristicTypes.AdditionalAttributesAndInformation.FullName(), "EditedAttributesInGroupDataProcessing");
	Objects.Insert(Metadata.Catalogs.ObjectsPropertiesValues.FullName(), "EditedAttributesInGroupDataProcessing");
	Objects.Insert(Metadata.Catalogs.ObjectsPropertiesValuesHierarchy.FullName(), "EditedAttributesInGroupDataProcessing");
	Objects.Insert(Metadata.Catalogs.AdditionalAttributesAndInformationSets.FullName(), "EditedAttributesInGroupDataProcessing");
EndProcedure

// See ObjectsVersioningOverridable.OnPrepareObjectData.
Procedure OnPrepareObjectData(Object, AdditionalAttributes) Export 
	
	GetAdditAttributes = PropertiesManagement.UseAdditAttributes(Object.Ref);
	GetAdditInfo = PropertiesManagement.UseAdditInfo(Object.Ref);
	
	If GetAdditAttributes Or GetAdditInfo Then
		For Each PropertyValue In PropertiesManagement.PropertiesValues(Object.Ref, GetAdditAttributes, GetAdditInfo) Do
			Attribute = AdditionalAttributes.Add();
			Attribute.Title = PropertyValue.Property;
			Attribute.Value = PropertyValue.Value;
		EndDo;
	EndIf;
	
EndProcedure

// Восстанавливает значения реквизитов объекта, хранящихся отдельно от объекта.
Procedure OnRestoreObjectVersion(Object, AdditionalAttributes) Export
	
	For Each Attribute In AdditionalAttributes Do
		If TypeOf(Attribute.Title) = Type("ChartOfCharacteristicTypesRef.AdditionalAttributesAndInformation") Then
			ThisIsAdditionalInformation = CommonUse.ObjectAttributeValue(Attribute.Title, "ThisIsAdditionalInformation");
			If ThisIsAdditionalInformation Then
				RecordSet = InformationRegisters.AdditionalInformation.CreateRecordSet();
				RecordSet.Filter.Object.Set(Object.Ref);
				RecordSet.Filter.Property.Set(Attribute.Title);
				
				Record = RecordSet.Add();
				Record.Property = Attribute.Title;
				Record.Value = Attribute.Value;
				Record.Object = Object.Ref;
				RecordSet.Write();
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// See CommonUseOverridable.OnAddExceptionsSearchLinks.
Procedure OnAddExceptionsSearchLinks(Array) Export
	
	Array.Add(Metadata.Catalogs.AdditionalAttributesAndInformationSets.FullName());
	Array.Add("ChartOfCharacteristicTypes.AdditionalAttributesAndInformation.TabularSection.AdditionalAttributeDependencies.Attribute.Value");
	
EndProcedure

// See AccessManagementOverridable.OnFillAccessKinds.
Procedure OnFillAccessKinds(AccessKinds) Export
	
	AccessKind = AccessKinds.Add();
	AccessKind.Name = "AdditionalInformation";
	AccessKind.Presentation = NStr("en='Find out more';ru='Дополнительные сведения';vi='Thông tin bổ sung'");
	AccessKind.ValuesType   = Type("ChartOfCharacteristicTypesRef.AdditionalAttributesAndInformation");
	
EndProcedure

// Used to receive metadata objects mandatory for an exchange plan.
// If the subsystem has metadata objects that have to be included
// in the exchange plan, then these metadata objects should be added to the <Object> parameter.
//
// Parameters:
// Objects - Array. Array of the configuration metadata objects that should be included into the exchange plan.
// DistributedInfobase (read only) - Boolean. Flag showing that objects for DIB exchange plan were received.
// True - need to receive a list of RIB exchange plan;
// False - it is required to receive a list for an exchange plan NOT RIB.
//
Procedure OnGettingObligatoryExchangePlanObjects(Objects, Val DistributedInfobase) Export
	
	If DistributedInfobase Then
		Objects.Add(Metadata.Constants.AdditionalAttributesAndInformationParameters);
	EndIf;
	
EndProcedure

// Used to receive metadata objects that should be included in the
// content of the exchange plan and should NOT be included in the content of subscriptions to the events of changes registration for this plan.
// These metadata objects are used only at the time of creation
// of the initial image of the subnode and do not migrate during the exchange.
// If the subsystem has metadata objects that take part in creating an initial
// image of the subnode, the <Object> parameter needs to be added to these metadata objects.
//
// Parameters:
// Objects - Array. Array of the configuration metadata objects.
//
Procedure OnGetPrimaryImagePlanExchangeObjects(Objects) Export
	
	Objects.Add(Metadata.Constants.AdditionalAttributesAndInformationParameters);
	
EndProcedure

// See AccessManagementOverridable.OnFillListWithAccessRestriction.
Procedure OnFillListWithAccessRestriction(Lists) Export
	
	Lists.Insert(Metadata.Catalogs.ObjectsPropertiesValues, True);
	Lists.Insert(Metadata.Catalogs.ObjectsPropertiesValuesHierarchy, True);
	Lists.Insert(Metadata.ChartsOfCharacteristicTypes.AdditionalAttributesAndInformation, True);
	Lists.Insert(Metadata.InformationRegisters.AdditionalInformation, True);
	
EndProcedure

// See AccessManagementOverridable.OnFillingAccessTypeUse.
Procedure OnFillingAccessTypeUse(AccessKind, Use) Export
	
	SetPrivilegedMode(True);
	
	If AccessKind = "AdditionalInformation" Then
		Use = Constants.UseAdditionalAttributesAndInformation.Get();
	EndIf;
	
EndProcedure

// See AccessManagementOverridable.OnFillingKindsOfRestrictionsRightsOfMetadataObjects.
Procedure OnFillingKindsOfRestrictionsRightsOfMetadataObjects(LongDesc) Export
	
	If Not CommonUse.SubsystemExists("StandardSubsystems.AccessManagement") Then
		Return;
	EndIf;
	
	ModuleAccessManagementService = CommonUse.CommonModule("AccessManagementService");
	
	If ModuleAccessManagementService.AccessKindExists("AdditionalInformation") Then
		
		LongDesc = LongDesc + "
		|
		|Catalog.ObjectsPropertiesValues.Read.AdditionalInformation
		|Catalog.ObjectsPropertiesValuesHierarchy.Read.AdditionalInformation
		|ChartOfCharacteristicTypes.AdditionalAttributesAndInformation.Read.AdditionalInformation
		|InformationRegister.AdditionalInformation.Read.AdditionalInformation
		|InformationRegister.AdditionalInformation.Update.AdditionalInformation
		|";
	EndIf;
	
EndProcedure

// See CommonUseOverridable.OnAddSessionSettingsSetupHandler.
Procedure OnAddSessionSettingsSetupHandler(Handlers) Export
	Handlers.Insert("InteractivePropertyFillCheck", "PropertiesManagementService.SessionParametersSetting");
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

Procedure AdditionalAttributesFillCheckProcessing(Src, Cancel, CheckedAttributes) Export
	
	If Not CommonUseReUse.CanUseSeparatedData() Then
		Return;
	EndIf;
	
	If Not GetFunctionalOption("UseAdditionalAttributesAndInformation") Then
		Return;
	EndIf;
	
	If Not AccessRight("Read", Metadata.Catalogs.AdditionalAttributesAndInformationSets) Then
		Return;
	EndIf;
	
	If TypeOf(Src.Ref) = Type("CatalogRef.AdditionalAttributesAndInformationSets") Then
		Return;
	EndIf;
	
	If SessionParameters.InteractivePropertyFillCheck Then
		SessionParameters.InteractivePropertyFillCheck = False;
		Return;
	EndIf;
	
	// Дополнительные реквизиты подключены к объекту.
	Checking = New Structure;
	Checking.Insert("AdditionalAttributes", Undefined);
	Checking.Insert("IsFolder", False);
	FillPropertyValues(Checking, Src);
	
	If Checking.AdditionalAttributes = Undefined Then
		Return; // Не подключены дополнительные реквизиты.
	EndIf;
	
	If Checking.IsFolder Then
		Return; // Для групп дополнительные реквизиты не подключаются.
	EndIf;
	
	SetsTable = GetObjectPropertiesSets(Src);
	Sets = SetsTable.UnloadColumn("Set");
	
	Query = New Query;
	Query.SetParameter("References", Sets);
	Query.Text =
		"SELECT
		|	SetAttributes.Property AS Property
		|FROM
		|	Catalog.AdditionalAttributesAndInformationSets.AdditionalAttributes AS SetAttributes
		|		LEFT JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInformation AS AdditionalAttributes
		|		ON SetAttributes.Property = AdditionalAttributes.Ref
		|WHERE
		|	SetAttributes.Ref IN(&References)
		|	AND AdditionalAttributes.FillObligatory = TRUE";
	Result = Query.Execute().Unload();
	
	If Result.Count() = 0 Then
		Return; // Нет обязательных для заполнения.
	EndIf;
	Attributes = Result.UnloadColumn("Property");
	
	PropertiesValues = PropertiesManagement.PropertiesValues(Src.Ref, True, False, Attributes);
	If PropertiesValues.Count() = Result.Count() Then
		Return; // Реквизиты заполнены.
	EndIf;
	
	Messages = New Array;
	
	Dependencies = CommonUse.ObjectAttributeValues(Attributes, "AdditionalAttributeDependencies");
	For Each Item In Dependencies Do
		DependenciesTable = Item.Value.AdditionalAttributeDependencies.Unload();
		Filter = New Structure;
		Filter.Insert("DependentProperty", "FillObligatory");
		RequiredFillingDependencies = DependenciesTable.FindRows(Filter);
		If RequiredFillingDependencies.Count() = 0 Then
			Text = NStr("en='The attribute ""%1"" are not filled.';ru='Реквизит ""%1"" не заполнен.';vi='Mục tin ""%1"" không được điền.'");
			Text = StringFunctionsClientServer.SubstituteParametersInString(Text, Item.Key);
			Messages.Add(Text);
		Else
			// Нужно получить все реквизиты объекта на случай, если по ним настроена зависимость.
			ObjectAdditionalAttributes = PropertiesManagement.PropertiesOfObject(Src, True, False);
			AttributeValues = New Structure;
			For Each AdditionalAttribute In ObjectAdditionalAttributes Do
				Row   = Checking.AdditionalAttributes.Find(AdditionalAttribute, "Property");
				Properties = CommonUse.ObjectAttributesValues(AdditionalAttribute, "Name,ValueType");
				AttributeName = "_" + Properties.Name;
				If Row = Undefined Then
					AttributeValues.Insert(AttributeName, Properties.ValueType.AdjustValue(Undefined));
				Else
					AttributeValues.Insert(AttributeName, Row.Value);
				EndIf;
			EndDo;
			
			DependentAttributeDescription = New Structure;
			DependentAttributeDescription.Insert("RequiredFillingCondition", Undefined);
			For Each DependencyRow In RequiredFillingDependencies Do
				If TypeOf(DependencyRow.Attribute) = Type("String") Then
					PathToAttribute = "Parameters.ObjectDescription." + DependencyRow.Attribute;
				Else
					AttributeName = "_" + CommonUse.ObjectAttributeValue(DependencyRow.Attribute, "Name");
					PathToAttribute = "Parameters.Form." + AttributeName;
				EndIf;
				
				BuildDependencyConditions(DependentAttributeDescription, PathToAttribute, DependencyRow);
				Parameters = DependentAttributeDescription.RequiredFillingCondition;
			EndDo;
			
			ConditionParameters = New Structure;
			ConditionParameters.Insert("ParameterValues", Parameters.ParameterValues);
			ConditionParameters.Insert("Form", AttributeValues);
			ConditionParameters.Insert("ObjectDescription", Src);
			
			FillRequred = WorkInSafeMode.EvalInSafeMode(Parameters.ConditionCode, ConditionParameters);
			If FillRequred Then
				Text = NStr("en='The attribute ""%1"" are not filled.';ru='Реквизит ""%1"" не заполнен.';vi='Mục tin ""%1"" không được điền.'");
				Text = StringFunctionsClientServer.SubstituteParametersInString(Text, Item.Key);
				Messages.Add(Text);
			EndIf;
		EndIf;
	EndDo;
	
	If Messages.Count() > 0 Then
		CommonUseClientServer.MessageToUser(StrConcat(Messages, Chars.LF), , , , Cancel);
	EndIf;
	
EndProcedure

Procedure BuildDependencyConditions(DependentAttributeDescription, PathToAttribute, TableRow) Export
	
	// Преобразование старого условия для обратной совместимости.
	ConditionParts = StrSplit(TableRow.Condition, " ");
	NewCondition = "";
	If ConditionParts.Count() > 0 Then
		For Each ConditionPart In ConditionParts Do
			NewCondition = NewCondition + Upper(Left(ConditionPart, 1)) + Mid(ConditionPart, 2);
		EndDo;
	EndIf;
	
	If ValueIsFilled(NewCondition) Then
		TableRow.Condition = NewCondition;
	EndIf;
	
	ConditionPattern = "";
	If TableRow.Condition = "Equal" Then
		ConditionPattern = "%1 = %2";
	ElsIf TableRow.Condition = "NotEqual" Then
		ConditionPattern = "%1 <> %2";
	EndIf;
	
	If TableRow.Condition = "InList" Then
		ConditionPattern = "%2.FindByValue(%1) <> Undefined";
	ElsIf TableRow.Condition = "NotInList" Then
		ConditionPattern = "%2.FindByValue(%1) = Undefined";
	EndIf;
	
	RightValue = "";
	If ValueIsFilled(ConditionPattern) Then
		RightValue = "Parameters.ParameterValues[""" + PathToAttribute + """]";
	EndIf;
	
	If TableRow.Condition = "Filled" Then
		ConditionPattern = "ValueIsFilled(%1)";
	ElsIf TableRow.Condition = "NotFilled" Then
		ConditionPattern = "NOT ValueIsFilled(%1)";
	EndIf;
	
	If ValueIsFilled(RightValue) Then
		ConditionCode = StringFunctionsClientServer.SubstituteParametersInString(ConditionPattern, PathToAttribute, RightValue);
	Else
		ConditionCode = StringFunctionsClientServer.SubstituteParametersInString(ConditionPattern, PathToAttribute);
	EndIf;
	
	If TableRow.DependentProperty = "Available" Then
		SetDependencyCondition(DependentAttributeDescription.AccessibilityCondition, PathToAttribute, TableRow, ConditionCode, TableRow.Condition);
	ElsIf TableRow.DependentProperty = "Visible" Then
		SetDependencyCondition(DependentAttributeDescription.VisibilityCondition, PathToAttribute, TableRow, ConditionCode, TableRow.Condition);
	Else
		SetDependencyCondition(DependentAttributeDescription.RequiredFillingCondition, PathToAttribute, TableRow, ConditionCode, TableRow.Condition);
	EndIf;

EndProcedure

Procedure SetDependencyCondition(DependencyStructure, PathToAttribute, TableRow, ConditionCode, Condition)
	If DependencyStructure = Undefined Then
		ParameterValues = New Map;
		If Condition = "InList"
			Or Condition = "NotInList" Then
			Value = New ValueList;
			Value.Add(TableRow.Value);
		Else
			Value = TableRow.Value;
		EndIf;
		ParameterValues.Insert(PathToAttribute, Value);
		DependencyStructure = New Structure;
		DependencyStructure.Insert("ConditionCode", ConditionCode);
		DependencyStructure.Insert("ParameterValues", ParameterValues);
	ElsIf (Condition = "InList" Or Condition = "NotInList")
		And TypeOf(DependencyStructure.ParameterValues[PathToAttribute]) = Type("ValueList") Then
		DependencyStructure.ParameterValues[PathToAttribute].Add(TableRow.Value);
	Else
		DependencyStructure.ConditionCode = DependencyStructure.ConditionCode + " AND " + ConditionCode;
		If Condition = "InList" Or Condition = "NotInList" Then
			Value = New ValueList;
			Value.Add(TableRow.Value);
		Else
			Value = TableRow.Value;
		EndIf;
		DependencyStructure.ParameterValues.Insert(PathToAttribute, Value);
	EndIf;
EndProcedure

Procedure SessionParametersSetting(Val ParameterName, SpecifiedParameters) Export
	If ParameterName = "InteractivePropertyFillCheck" Then
		SessionParameters.InteractivePropertyFillCheck = False;
		SpecifiedParameters.Add("InteractivePropertyFillCheck");
	EndIf;
EndProcedure

// See PropertiesManagement.MoveValuesFromFormAttributesToObject.
Procedure MoveValuesFromFormAttributesToObject(Form, Object = Undefined, BeforeWrite = False) Export
	
	Receiver = New Structure;
	Receiver.Insert("ProperyParameters", Undefined);
	FillPropertyValues(Receiver, Form);
	
	If Not Form.Properties_UseProperties
		Or Not Form.Properties_UseAdditionalAttributes
		Or (TypeOf(Receiver.ProperyParameters) = Type("Structure")
			And Receiver.ProperyParameters.Property("ExecutedDeferredInitialization")
			And Not Receiver.ProperyParameters.ExecutedDeferredInitialization) Then
		
		Return;
	EndIf;
	
	If Object = Undefined Then
		ObjectDescription = Form.Object;
	Else
		ObjectDescription = Object;
	EndIf;
	
	OldValues = ObjectDescription.AdditionalAttributes.Unload();
	ObjectDescription.AdditionalAttributes.Clear();
	
	For Each Row In Form.Properties_AdditionalAttributesDescription Do
		
		Value = Form[Row.AttributeNameValue];
		
		If Value = Undefined Then
			Continue;
		EndIf;
		
		If Row.ValueType.Types().Count() = 1
		   And (Not ValueIsFilled(Value) Or Value = False) Then
			
			Continue;
		EndIf;
		
		If Row.Deleted Then
			If ValueIsFilled(Value) And Not (BeforeWrite And Form.Properties_HideDeleted) Then
				FoundString = OldValues.Find(Row.Property, "Property");
				If FoundString <> Undefined Then
					FillPropertyValues(ObjectDescription.AdditionalAttributes.Add(), FoundString);
				EndIf;
			EndIf;
			Continue;
		EndIf;
		
		// Поддержка строк гиперссылок.
		UseStringAsLink = UseStringAsLink(
			Row.ValueType, Row.DisplayAsHyperlink, Row.MultilineTextBox);
		
		NewRow = ObjectDescription.AdditionalAttributes.Add();
		NewRow.Property = Row.Property;
		If UseStringAsLink Then
			AddressAndPresentation = AddressAndPresentation(Value);
			NewRow.Value = AddressAndPresentation.Presentation;
		Else
			NewRow.Value = Value;
		EndIf;
		
		// Поддержка строк неограниченной длины.
		UseOpenEndedString = UseOpenEndedString(
			Row.ValueType, Row.MultilineTextBox);
		
		If UseOpenEndedString Or UseStringAsLink Then
			NewRow.TextString = Value;
		EndIf;
	EndDo;
	
	If BeforeWrite Then
		Form.Properties_HideDeleted = False;
	EndIf;
	
EndProcedure

// Возвращает таблицу наборов доступных свойств владельца.
//
// Parameters:
//  PropertiesOwner - Ссылка на владельца свойств.
//                    Объект владельца свойств.
//                    ДанныеФормыСтруктура (по типу объекта владельца свойств).
//
Function GetObjectPropertiesSets(Val PropertiesOwner, PurposeKey = Undefined) Export
	
	If TypeOf(PropertiesOwner) = Type("FormDataStructure") Then
		ReferenceType = TypeOf(PropertiesOwner.Ref)
		
	ElsIf CommonUse.IsReference(TypeOf(PropertiesOwner)) Then
		ReferenceType = TypeOf(PropertiesOwner);
	Else
		ReferenceType = TypeOf(PropertiesOwner.Ref)
	EndIf;
	
	GetMainSet = True;
	
	PropertiesSets = New ValueTable;
	PropertiesSets.Columns.Add("Set");
	PropertiesSets.Columns.Add("Height");
	PropertiesSets.Columns.Add("Title");
	PropertiesSets.Columns.Add("ToolTip");
	PropertiesSets.Columns.Add("VerticalStretch");
	PropertiesSets.Columns.Add("HorizontalStretch");
	PropertiesSets.Columns.Add("ReadOnly");
	PropertiesSets.Columns.Add("TitleTextColor");
	PropertiesSets.Columns.Add("Width");
	PropertiesSets.Columns.Add("TitleFont");
	PropertiesSets.Columns.Add("Group");
	PropertiesSets.Columns.Add("Representation");
	PropertiesSets.Columns.Add("Picture");
	PropertiesSets.Columns.Add("ShowTitle");
	PropertiesSets.Columns.Add("CommonSet", New TypeDescription("Boolean"));
	// Устарело:
	PropertiesSets.Columns.Add("ChildItemsWidth");
	
	PropertiesManagementOverridable.FillObjectPropertiesSets(
		PropertiesOwner, ReferenceType, PropertiesSets, GetMainSet, PurposeKey);
	
	If PropertiesSets.Count() = 0
	   And GetMainSet = True Then
		
		MainSet = GetMainPropertiesSetForObject(PropertiesOwner);
		
		If ValueIsFilled(MainSet) Then
			PropertiesSets.Add().Set = MainSet;
		EndIf;
	EndIf;
	
	Return PropertiesSets;
	
EndFunction

// Возвращает заполненную таблицу значений свойств объекта.
Function PropertiesValues(AdditionalObjectProperties, Sets, ThisIsAdditionalInformation) Export
	
	If AdditionalObjectProperties.Count() = 0 Then
		// Предварительная быстрая проверка использования дополнительных свойств.
		PropertiesNotFound = AdditionalAttributesAndInformationNotFound(Sets, ThisIsAdditionalInformation);
		
		If PropertiesNotFound Then
			PropertiesDescription = New ValueTable;
			PropertiesDescription.Columns.Add("Set");
			PropertiesDescription.Columns.Add("Property");
			PropertiesDescription.Columns.Add("AdditionalValuesOwner");
			PropertiesDescription.Columns.Add("FillObligatory");
			PropertiesDescription.Columns.Add("Description");
			PropertiesDescription.Columns.Add("ValueType");
			PropertiesDescription.Columns.Add("FormatProperties");
			PropertiesDescription.Columns.Add("MultilineTextBox");
			PropertiesDescription.Columns.Add("Deleted");
			PropertiesDescription.Columns.Add("Value");
			Return PropertiesDescription;
		EndIf;
	EndIf;
	
	Properties = AdditionalObjectProperties.UnloadColumn("Property");
	
	PropertiesSets = New ValueTable;
	
	PropertiesSets.Columns.Add(
		"Set", New TypeDescription("CatalogRef.AdditionalAttributesAndInformationSets"));
	
	PropertiesSets.Columns.Add(
		"SetOrder", New TypeDescription("Number"));
	
	For Each ListElement In Sets Do
		NewRow = PropertiesSets.Add();
		NewRow.Set         = ListElement.Value;
		NewRow.SetOrder = Sets.IndexOf(ListElement);
	EndDo;
	
	Query = New Query;
	Query.SetParameter("Properties",      Properties);
	Query.SetParameter("PropertiesSets", PropertiesSets);
	Query.SetParameter("IsMainLanguage", CurrentLanguage() = Metadata.DefaultLanguage);
	Query.SetParameter("LanguageCode", CurrentLanguage().LanguageCode);
	
	Query.Text =
	"SELECT
	|	PropertiesSets.Set AS Set,
	|	PropertiesSets.SetOrder AS SetOrder
	|INTO PropertiesSets
	|FROM
	|	&PropertiesSets AS PropertiesSets
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	PropertiesSets.Set AS Set,
	|	PropertiesSets.SetOrder AS SetOrder,
	|	SetsProperties.Property AS Property,
	|	SetsProperties.DeletionMark AS DeletionMark,
	|	SetsProperties.LineNumber AS PropertyOrder
	|INTO SetsProperties
	|FROM
	|	PropertiesSets AS PropertiesSets
	|		INNER JOIN Catalog.AdditionalAttributesAndInformationSets.AdditionalAttributes AS SetsProperties
	|		ON (SetsProperties.Ref = PropertiesSets.Set)
	|		INNER JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInformation AS Properties
	|		ON (SetsProperties.Property = Properties.Ref)
	|WHERE
	|	NOT SetsProperties.DeletionMark
	|	AND NOT Properties.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Properties.Ref AS Property
	|INTO FilledProperties
	|FROM
	|	ChartOfCharacteristicTypes.AdditionalAttributesAndInformation AS Properties
	|WHERE
	|	Properties.Ref IN(&Properties)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetsProperties.Set AS Set,
	|	SetsProperties.SetOrder AS SetOrder,
	|	SetsProperties.Property AS Property,
	|	SetsProperties.PropertyOrder AS PropertyOrder,
	|	SetsProperties.DeletionMark AS Deleted
	|INTO AllProperties
	|FROM
	|	SetsProperties AS SetsProperties
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Catalog.AdditionalAttributesAndInformationSets.EmptyRef),
	|	0,
	|	FilledProperties.Property,
	|	0,
	|	TRUE
	|FROM
	|	FilledProperties AS FilledProperties
	|		LEFT JOIN SetsProperties AS SetsProperties
	|		ON FilledProperties.Property = SetsProperties.Property
	|WHERE
	|	SetsProperties.Property IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	AllProperties.Set AS Set,
	|	AllProperties.Property AS Property,
	|	AdditionalAttributesAndInformation.AdditionalValuesOwner AS AdditionalValuesOwner,
	|	AdditionalAttributesAndInformation.FillObligatory AS FillObligatory,
	|	CASE
	|		WHEN &IsMainLanguage
	|			THEN AdditionalAttributesAndInformation.Title
	|		ELSE CAST(ISNULL(PresentationProperties.Title, AdditionalAttributesAndInformation.Title) AS STRING(150))
	|	END AS Description,
	|	AdditionalAttributesAndInformation.ValueType AS ValueType,
	|	AdditionalAttributesAndInformation.FormatProperties AS FormatProperties,
	|	AdditionalAttributesAndInformation.MultilineTextBox AS MultilineTextBox,
	|	AllProperties.Deleted AS Deleted,
	|	AdditionalAttributesAndInformation.Available AS Available,
	|	AdditionalAttributesAndInformation.Visible AS Visible,
	|	CASE
	|		WHEN &IsMainLanguage
	|			THEN AdditionalAttributesAndInformation.ToolTip
	|		ELSE CAST(ISNULL(PresentationProperties.ToolTip, AdditionalAttributesAndInformation.ToolTip) AS STRING(150))
	|	END AS ToolTip,
	|	AdditionalAttributesAndInformation.DisplayAsHyperlink AS DisplayAsHyperlink,
	|	AdditionalAttributesAndInformation.AdditionalAttributeDependencies.(
	|		DependentProperty AS DependentProperty,
	|		Attribute AS Attribute,
	|		Condition AS Condition,
	|		Value AS Value,
	|		PropertySet AS PropertySet
	|	) AS AdditionalAttributeDependencies
	|FROM
	|	AllProperties AS AllProperties
	|		INNER JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInformation AS AdditionalAttributesAndInformation
	|		ON AllProperties.Property = AdditionalAttributesAndInformation.Ref
	|		LEFT JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInformation.Presentations AS PresentationProperties
	|		ON (PresentationProperties.Ref = AdditionalAttributesAndInformation.Ref)
	|			AND (PresentationProperties.LanguageCode = &LanguageCode)
	|
	|ORDER BY
	|	Deleted,
	|	AllProperties.SetOrder,
	|	AllProperties.PropertyOrder";
	
	If ThisIsAdditionalInformation Then
		Query.Text = StrReplace(
			Query.Text,
			"Catalog.AdditionalAttributesAndInformationSets.AdditionalAttributes",
			"Catalog.AdditionalAttributesAndInformationSets.AdditionalInformation");
	EndIf;
	
	PropertiesDescription = Query.Execute().Unload();
	PropertiesDescription.Indexes.Add("Property");
	PropertiesDescription.Columns.Add("Value");
	
	// Удаление дублей свойств в нижестоящих наборах свойств.
	If Sets.Count() > 1 Then
		IndexOf = PropertiesDescription.Count()-1;
		
		While IndexOf >= 0 Do
			Row = PropertiesDescription[IndexOf];
			FoundString = PropertiesDescription.Find(Row.Property, "Property");
			
			If FoundString <> Undefined
			   And FoundString <> Row Then
				
				PropertiesDescription.Delete(IndexOf);
			EndIf;
			
			IndexOf = IndexOf-1;
		EndDo;
	EndIf;
	
	// Заполнение значений свойств.
	For Each Row In AdditionalObjectProperties Do
		PropertyDetails = PropertiesDescription.Find(Row.Property, "Property");
		If PropertyDetails <> Undefined Then
			// Поддержка строк неограниченной длины.
			If Not ThisIsAdditionalInformation Then
				UseStringAsLink = UseStringAsLink(
					PropertyDetails.ValueType,
					PropertyDetails.DisplayAsHyperlink,
					PropertyDetails.MultilineTextBox);
				UseOpenEndedString = UseOpenEndedString(
					PropertyDetails.ValueType,
					PropertyDetails.MultilineTextBox);
				MustTransferValueFromLink = MustTransferValueFromLink(
						Row.TextString,
						Row.Value);
				If (UseOpenEndedString
						Or UseStringAsLink
						Or MustTransferValueFromLink)
					And Not IsBlankString(Row.TextString) Then
					If Not UseStringAsLink And MustTransferValueFromLink Then
						ValueWithoutRef = ValueWithoutRef(Row.TextString, Row.Value);
						PropertyDetails.Value = ValueWithoutRef;
					Else
						PropertyDetails.Value = Row.TextString;
					EndIf;
				Else
					PropertyDetails.Value = Row.Value;
				EndIf;
			Else
				PropertyDetails.Value = Row.Value;
			EndIf;
		EndIf;
	EndDo;
	
	Return PropertiesDescription;
	
EndFunction

// Только для внутреннего использования.
//
Function AdditionalAttributesAndInformationNotFound(Sets, ThisIsAdditionalInformation, DeferredInitialization = False)
	
	Query = New Query;
	Query.SetParameter("PropertiesSets", Sets.UnloadValues());
	Query.Text =
	"SELECT TOP 1
	|	SetsProperties.Property AS Property
	|FROM
	|	Catalog.AdditionalAttributesAndInformationSets.AdditionalAttributes AS SetsProperties
	|WHERE
	|	SetsProperties.Ref IN(&PropertiesSets)
	|	AND NOT SetsProperties.DeletionMark";
	
	If ThisIsAdditionalInformation Then
		Query.Text = StrReplace(
			Query.Text,
			"Catalog.AdditionalAttributesAndInformationSets.AdditionalAttributes",
			"Catalog.AdditionalAttributesAndInformationSets.AdditionalInformation");
	EndIf;
	
	SetPrivilegedMode(True);
	PropertiesNotFound = Query.Execute().IsEmpty();
	SetPrivilegedMode(False);
	
	Return PropertiesNotFound;
EndFunction

Function ShowTabAdditionally(Ref, Sets) Export
	
	Query = New Query;
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("PropertiesSets", Sets.UnloadValues());
	Query.Text = 
		"SELECT TOP 1
		|	AdditionalAttributes.Property AS Property
		|FROM
		|	[TableName].AdditionalAttributes AS AdditionalAttributes
		|WHERE
		|	AdditionalAttributes.Ref = &Ref
		|;
		|
		|SELECT TOP 1
		|	SetsProperties.Property AS Property
		|FROM
		|	Catalog.AdditionalAttributesAndInformationSets.AdditionalAttributes AS SetsProperties
		|WHERE
		|	SetsProperties.Ref IN(&PropertiesSets)
		|	AND NOT SetsProperties.DeletionMark";
	Query.Text = StrReplace(Query.Text, "[TableName]", Ref.Metadata().FullName());
	Result = Query.ExecuteBatch();
	
	Return Not (Result[0].IsEmpty() And Result[1].IsEmpty());
	
EndFunction

// Возвращает объект метаданных, который является владельцем значений
// свойств набора дополнительных реквизитов и сведений.
//
Function PropertiesSetValuesOwnerMetadata(Ref, ConsiderMarkRemoval = True, ReferenceType = Undefined) Export
	
	If Not ValueIsFilled(Ref) Then
		Return Undefined;
	EndIf;
	
	PredefinedPropertySets = PropertiesManagementReUse.PredefinedPropertySets();
	
	If TypeOf(Ref) = Type("Structure") Then
		RefProperties = Ref;
	Else
		RefProperties = CommonUse.ObjectAttributesValues(
			Ref, "DeletionMark, IsFolder, Predefined, Parent, PredefinedDataName, PredefinedSetName");
	EndIf;
	
	If ValueIsFilled(RefProperties.PredefinedSetName) Then
		RefProperties.PredefinedDataName = RefProperties.PredefinedSetName;
		RefProperties.Predefined          = True;
	EndIf;
	
	If ConsiderMarkRemoval And RefProperties.DeletionMark Then
		Return Undefined;
	EndIf;
	
	If RefProperties.IsFolder Then
		RefOfPredefined = Ref;
		
	ElsIf RefProperties.Predefined
	        And RefProperties.Parent = Catalogs.AdditionalAttributesAndInformationSets.EmptyRef()
	        Or RefProperties.Parent = Undefined Then
		
		RefOfPredefined = Ref;
	Else
		RefOfPredefined = RefProperties.Parent;
	EndIf;
	
	If Ref <> RefOfPredefined Then
		PropertiesSet = PredefinedPropertySets.Get(RefProperties.Parent);
		If PropertiesSet <> Undefined Then
			PredefinedName = PredefinedPropertySets.Get(RefOfPredefined).Name;
		Else
			PredefinedName = CommonUse.ObjectAttributeValue(RefOfPredefined, "PredefinedDataName");
		EndIf;
	Else
		PredefinedName = RefProperties.PredefinedDataName;
	EndIf;
	
	Position = StrFind(PredefinedName, "_");
	
	FirstPartOfTheName =  Left(PredefinedName, Position - 1);
	SecondPartOfName = Right(PredefinedName, StrLen(PredefinedName) - Position);
	
	OwnerMetadata = Metadata.FindByFullName(FirstPartOfTheName + "." + SecondPartOfName);
	
	If OwnerMetadata <> Undefined Then
		ReferenceType = Type(FirstPartOfTheName + "Ref." + SecondPartOfName);
	EndIf;
	
	Return OwnerMetadata;
	
EndFunction

// Возвращает использование набором дополнительных реквизитов и сведений.
Function SetPropertyTypes(Ref, ConsiderMarkRemoval = True) Export
	
	SetPropertyTypes = New Structure;
	SetPropertyTypes.Insert("AdditionalAttributes", False);
	SetPropertyTypes.Insert("AdditionalInformation",  False);
	
	ReferenceType = Undefined;
	OwnerMetadata = PropertiesSetValuesOwnerMetadata(Ref, ConsiderMarkRemoval, ReferenceType);
	
	If OwnerMetadata = Undefined Then
		Return SetPropertyTypes;
	EndIf;
	
	// Проверка использования дополнительных реквизитов.
	SetPropertyTypes.Insert(
		"AdditionalAttributes",
		OwnerMetadata <> Undefined
		And OwnerMetadata.TabularSections.Find("AdditionalAttributes") <> Undefined );
	
	// Проверка использования дополнительных сведений.
	SetPropertyTypes.Insert(
		"AdditionalInformation",
		      Metadata.CommonCommands.Find("AdditionalInformationCommandBar") <> Undefined
		    And Metadata.CommonCommands.AdditionalInformationCommandBar.CommandParameterType.ContainsType(ReferenceType));
	
	Return SetPropertyTypes;
	
EndFunction

Procedure FillSetsWithAdditionalAttributes(AllSets, SetsWithAttributes) Export
	
	References = AllSets.UnloadColumn("Set");
	IndexOf = References.Find(Undefined);
	While IndexOf <> Undefined Do
		References.Delete(IndexOf);
		IndexOf = References.Find(Undefined);
	EndDo;
	
	ReferenceProperties = CommonUse.ObjectAttributeValues(
		References, "DeletionMark, IsFolder, Predefined, Parent, PredefinedDataName, PredefinedSetName");
	
	For Each RefProperties In ReferenceProperties Do
		ReferenceType = Undefined;
		OwnerMetadata = PropertiesSetValuesOwnerMetadata(RefProperties.Value, True, ReferenceType);
		
		If OwnerMetadata = Undefined Then
			Return;
		EndIf;
		
		// Проверка использования дополнительных реквизитов.
		If OwnerMetadata.TabularSections.Find("AdditionalAttributes") <> Undefined Then
			Row = AllSets.Find(RefProperties.Key, "Set");
			SetsWithAttributes.Add(Row.Set, Row.Title);
		EndIf;
		
	EndDo;
	
EndProcedure

// Определяет, что тип значения содержит тип дополнительных значений свойств.
Function ValueTypeContainsPropertiesValues(ValueType) Export
	
	Return ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues"))
	    Or ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValuesHierarchy"));
	
EndFunction

// Проверяет возможность использования для свойства строки неограниченный длины.
Function UseOpenEndedString(PropertyValueType, MultilineTextBox) Export
	
	If PropertyValueType.ContainsType(Type("String"))
	   And PropertyValueType.Types().Count() = 1
	   And (PropertyValueType.StringQualifiers.Length = 0
		   Or MultilineTextBox > 1) Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

Function UseStringAsLink(PropertyValueType, DisplayAsHyperlink, MultilineTextBox)
	TypeList = PropertyValueType.Types();
	
	If Not UseOpenEndedString(PropertyValueType, MultilineTextBox)
		And TypeList.Count() = 1
		And TypeList[0] = Type("String")
		And DisplayAsHyperlink Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

Function AddressAndPresentation(Row) Export
	
	Result = New Structure;
	SelectionStart = StrFind(Row, "<a href = ");
	
	RowAfterOpeningTag = Mid(Row, SelectionStart + 9);
	ClosingTag = StrFind(RowAfterOpeningTag, ">");
	
	Ref = TrimAll(Left(RowAfterOpeningTag, ClosingTag - 2));
	If StrStartsWith(Ref, """") Then
		Ref = Mid(Ref, 2, StrLen(Ref) - 1);
	EndIf;
	If StrEndsWith(Ref, """") Then
		Ref = Mid(Ref, 1, StrLen(Ref) - 1);
	EndIf;
	
	RowAfterRef = Mid(RowAfterOpeningTag, ClosingTag + 1);
	SelectionEnd = StrFind(RowAfterRef, "</a>");
	HyperlinkText = Left(RowAfterRef, SelectionEnd - 1);
	Result.Insert("Presentation", HyperlinkText);
	Result.Insert("Ref", Ref);
	
	Return Result;
	
EndFunction

// Обработчик события СвойстваПередУдалениемСсылочногоОбъекта.
// Выполняет поиск ссылок на удаляемые объекты в таблице зависимостей дополнительных реквизитов.
//
Procedure BeforeReferenceObjectDelete(Object, Cancel) Export
	If Object.DataExchange.Load = True
		Or Cancel Then
		Return;
	EndIf;
	
	If Not CommonUseReUse.CanUseSeparatedData() Then
		// В неразделенном режиме не проверяем.
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
		"SELECT DISTINCT
		|	Dependencies.Ref AS Ref
		|FROM
		|	ChartOfCharacteristicTypes.AdditionalAttributesAndInformation.AdditionalAttributeDependencies AS Dependencies
		|WHERE
		|	Dependencies.Value = &Value
		|
		|ORDER BY
		|	Ref";
	Query.SetParameter("Value", Object.Ref);
	Result = Query.Execute().Unload();
	
	For Each Row In Result Do
		Block = New DataLock;
		LockItem = Block.Add("ChartOfCharacteristicTypes.AdditionalAttributesAndInformation");
		LockItem.SetValue("Ref", Row.Ref);
		Block.Lock();
		
		AttributeObject = Row.Ref.GetObject();
		FilterParameters = New Structure("Value", Object.Ref);
		FoundStrings = AttributeObject.AdditionalAttributeDependencies.FindRows(FilterParameters);
		For Each Dependence In FoundStrings Do
			AttributeObject.AdditionalAttributeDependencies.Delete(Dependence);
		EndDo;
		AttributeObject.Write();
	EndDo;
EndProcedure

// Проверяет наличие объектов, использующих свойство.
//
// Parameters:
//  Property - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInformation
//
// Returns:
//  Boolean -  True, если найден хотя бы один объект.
//
Function AdditionalPropertyInUse(Property) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.SetParameter("Property", Property);
	Query.Text =
	"SELECT TOP 1
	|	TRUE AS TrueValue
	|FROM
	|	InformationRegister.AdditionalInformation AS AdditionalInformation
	|WHERE
	|	AdditionalInformation.Property = &Property";
	
	If Not Query.Execute().IsEmpty() Then
		Return True;
	EndIf;
	
	MetadataObjectKinds = New Array;
	MetadataObjectKinds.Add("ExchangePlans");
	MetadataObjectKinds.Add("Catalogs");
	MetadataObjectKinds.Add("Documents");
	MetadataObjectKinds.Add("ChartsOfCharacteristicTypes");
	MetadataObjectKinds.Add("ChartsOfAccounts");
	MetadataObjectKinds.Add("ChartsOfCalculationTypes");
	MetadataObjectKinds.Add("BusinessProcesses");
	MetadataObjectKinds.Add("Tasks");
	
	TablesObjects = New Array;
	For Each KindMetadataObjects In MetadataObjectKinds Do
		For Each MetadataObject In Metadata[KindMetadataObjects] Do
			
			If IsMetadataObjectWithAdditionalDetails(MetadataObject) Then
				TablesObjects.Add(MetadataObject.FullName());
			EndIf;
			
		EndDo;
	EndDo;
	
	QueryText =
	"SELECT TOP 1
	|	TRUE AS TrueValue
	|FROM
	|	TableName AS CurrentTable
	|WHERE
	|	CurrentTable.Property = &Property";
	
	For Each Table In TablesObjects Do
		Query.Text = StrReplace(QueryText, "TableName", Table + ".AdditionalAttributes");
		If Not Query.Execute().IsEmpty() Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// Проверяет использует ли объект метаданных дополнительные реквизиты.
// Проверка предназначена для контроля ссылочной целостности, поэтому
// проверка встраивания пропускается.
//
Function IsMetadataObjectWithAdditionalDetails(MetadataObject) Export
	
	If MetadataObject = Metadata.Catalogs.AdditionalAttributesAndInformationSets Then
		Return False;
	EndIf;
	
	TabularSection = MetadataObject.TabularSections.Find("AdditionalAttributes");
	If TabularSection = Undefined Then
		Return False;
	EndIf;
	
	Attribute = TabularSection.Attributes.Find("Property");
	If Attribute = Undefined Then
		Return False;
	EndIf;
	
	If Not Attribute.Type.ContainsType(Type("ChartOfCharacteristicTypesRef.AdditionalAttributesAndInformation")) Then
		Return False;
	EndIf;
	
	Attribute = TabularSection.Attributes.Find("Value");
	If Attribute = Undefined Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Возвращает наименование предопределенного набора полученное
// из объекта метаданных, найденного через имя предопределенного набора.
// 
// Parameters:
//  Set - CatalogRef.AdditionalAttributesAndInformationSets,
//        - String - полное имя предопределенного элемента.
//
Function DescriptionPredefinedSet(Set) Export
	
	PredefinedPropertySets = PropertiesManagementReUse.PredefinedPropertySets();
	
	If TypeOf(Set) = Type("String") Then
		PredefinedName = Set;
	Else
		PredefinedName = CommonUse.ObjectAttributeValue(Set, "PredefinedDataName");
	EndIf;
	
	Position = StrFind(PredefinedName, "_");
	FirstPartOfTheName =  Left(PredefinedName, Position - 1);
	SecondPartOfName = Right(PredefinedName, StrLen(PredefinedName) - Position);
	
	FullName = FirstPartOfTheName + "." + SecondPartOfName;
	
	MetadataObject = Metadata.FindByFullName(FullName);
	If MetadataObject = Undefined Then
		If TypeOf(Set) = Type("String") Then
			Return "";
		Else
			Return CommonUse.ObjectAttributeValue(Set, "Description");
		EndIf;
	EndIf;
	
	If ValueIsFilled(MetadataObject.ListPresentation) Then
		Description = MetadataObject.ListPresentation;
		
	ElsIf ValueIsFilled(MetadataObject.Synonym) Then
		Description = MetadataObject.Synonym;
	Else
		If TypeOf(Set) = Type("String") Then
			Description = "";
		Else
			Description = CommonUse.ObjectAttributeValue(Set, "Description");
		EndIf;
	EndIf;
	
	Return Description;
	
EndFunction

// Обновление состава верхней группы для использования при настройке
// состава полей динамического списка и его настройки (отборы, ...).
//
// Parameters:
//  Group        - CatalogRef.AdditionalAttributesAndInformationSets,
//                  с признаком ЭтоГруппа = True.
//
Procedure CheckRefreshContentFoldersProperties(Group) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.SetParameter("Group", Group);
	Query.Text =
	"SELECT DISTINCT
	|	AdditionalAttributes.Property AS Property,
	|	AdditionalAttributes.PredefinedSetName AS PredefinedSetName
	|FROM
	|	Catalog.AdditionalAttributesAndInformationSets.AdditionalAttributes AS AdditionalAttributes
	|WHERE
	|	AdditionalAttributes.Ref.Parent = &Group
	|
	|ORDER BY
	|	Property
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	AdditionalInformation.Property AS Property,
	|	AdditionalInformation.PredefinedSetName AS PredefinedSetName
	|FROM
	|	Catalog.AdditionalAttributesAndInformationSets.AdditionalInformation AS AdditionalInformation
	|WHERE
	|	AdditionalInformation.Ref.Parent = &Group
	|
	|ORDER BY
	|	Property";
	
	QueryResult = Query.ExecuteBatch();
	AdditionalAttributesGroups = QueryResult[0].Unload();
	AdditionalInformationGroups  = QueryResult[1].Unload();
	
	Block = New DataLock;
	LockItem = Block.Add("Catalog.AdditionalAttributesAndInformationSets");
	LockItem.SetValue("Ref", Group);
	Block.Lock();
	
	ObjectGroup = Group.GetObject();
	
	Refresh = False;
	
	If ObjectGroup.AdditionalAttributes.Count() <> AdditionalAttributesGroups.Count() Then
		Refresh = True;
	EndIf;
	
	If ObjectGroup.AdditionalInformation.Count() <> AdditionalInformationGroups.Count() Then
		Refresh = True;
	EndIf;
	
	If Not Refresh Then
		IndexOf = 0;
		For Each Row In ObjectGroup.AdditionalAttributes Do
			If Row.Property <> AdditionalAttributesGroups[IndexOf].Property Then
				Refresh = True;
			EndIf;
			IndexOf = IndexOf + 1;
		EndDo;
	EndIf;
	
	If Not Refresh Then
		IndexOf = 0;
		For Each Row In ObjectGroup.AdditionalInformation Do
			If Row.Property <> AdditionalInformationGroups[IndexOf].Property Then
				Refresh = True;
			EndIf;
			IndexOf = IndexOf + 1;
		EndDo;
	EndIf;
	
	If Not Refresh Then
		Return;
	EndIf;
	
	ObjectGroup.AdditionalAttributes.Load(AdditionalAttributesGroups);
	ObjectGroup.AdditionalInformation.Load(AdditionalInformationGroups);
	ObjectGroup.Write();
	
EndProcedure

// Возвращает перечисляемые значения указанного свойства.
//
// Parameters:
//  Property - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInformation - свойство для
//             которого нужно получить перечисляемые значения.
// 
// Returns:
//  Array - значения:
//    * CatalogRef.ObjectsPropertiesValues, СправочникСсылка.ЗначенияСвойствОбъектовИерархия - значения
//      свойства, если есть.
//
Function PropertyAdditionalValues(Property) Export
	
	ValueType = CommonUse.ObjectAttributeValue(Property, "ValueType");
	
	If ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValuesHierarchy")) Then
		QueryText =
		"SELECT
		|	Ref AS Ref
		|FROM
		|	Catalog.ObjectsPropertiesValuesHierarchy AS ObjectsPropertiesValues
		|WHERE
		|	ObjectsPropertiesValues.Owner = &Property";
	Else
		QueryText =
		"SELECT
		|	Ref AS Ref
		|FROM
		|	Catalog.ObjectsPropertiesValues AS ObjectsPropertiesValues
		|WHERE
		|	ObjectsPropertiesValues.Owner = &Property";
	EndIf;
	
	Query = New Query;
	Query.Text = QueryText;
	Query.Parameters.Insert("Property", Property);
	Result = Query.Execute().Unload().UnloadColumn("Ref");
	
	Return Result;
	
EndFunction

Function LocalizedAttributeValues(Ref, Attributes) Export
	
	QueryText = "SELECT
		|%1
		|
		|FROM
		|	ChartOfCharacteristicTypes.AdditionalAttributesAndInformation AS Table
		|	LEFT JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInformation.Presentations AS TablePresentations
		|		ON TablePresentations.Ref = Table.Ref
		|		AND TablePresentations.LanguageCode = &LanguageCode
		|
		|WHERE
		|	Table.Ref = &Ref";
	
	InsertText = "";
	Pattern = "CAST(ISNULL(TablePresentations.%1, Table.%1) AS STRING(150)) AS %1";
	For Each Attribute In Attributes Do
		If Not ValueIsFilled(InsertText) Then
			InsertText = StringFunctionsClientServer.SubstituteParametersInString(Pattern, Attribute);
		Else
			InsertText = InsertText + "," + Chars.LF + StringFunctionsClientServer.SubstituteParametersInString(Pattern, Attribute);
		EndIf;
	EndDo;
	
	QueryText = StringFunctionsClientServer.SubstituteParametersInString(QueryText, InsertText);
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("LanguageCode", CurrentLanguage().LanguageCode);
	Result = Query.Execute().Unload();
	
	Return Result[0];
	
EndFunction

Procedure CreatePredefinedPropertySets() Export
	
	PredefinedPropertySets = PropertiesManagementReUse.PredefinedPropertySets();
	PropertySetDescriptions    = PropertiesManagementReUse.PropertySetDescriptions();
	
	For Each PredefinedSet In PredefinedPropertySets Do
		If TypeOf(PredefinedSet.Key) = Type("String") Or ValueIsFilled(PredefinedSet.Value.Parent) Then
			Continue;
		EndIf;
		PropertiesSet = PredefinedSet.Value;
		Object         = PropertiesSet.Ref.GetObject();
		CreatePropertySet(Object, PropertiesSet);
		
		For Each ChildSet In PropertiesSet.ChildSets Do
			PropertiesSet = ChildSet.Value;
			ChildObject = PropertiesSet.Ref.GetObject();
			CreatePropertySet(ChildObject, PropertiesSet, PropertySetDescriptions, Object.Ref);
		EndDo;
	EndDo;
	
EndProcedure

Procedure CreatePropertySet(Object, PropertiesSet, PropertySetDescriptions = Undefined, Parent = Undefined)
	
	Write = False;
	If Object = Undefined Then
		If PropertiesSet.ChildSets = Undefined
			Or PropertiesSet.ChildSets.Count() = 0 Then
			Object = Catalogs.AdditionalAttributesAndInformationSets.CreateItem();
		Else
			Object = Catalogs.AdditionalAttributesAndInformationSets.CreateFolder();
		EndIf;
		If Parent <> Undefined Then
			Object.Parent = Parent;
		EndIf;
		Object.SetNewObjectRef(PropertiesSet.Ref);
		Object.PredefinedSetName = PropertiesSet.Name;
		Write = True;
	EndIf;
	
	If PropertiesSet.Used <> Undefined Then
		If Object.Used <> PropertiesSet.Used Then
			Object.Used = PropertiesSet.Used;
			Write = True;
		EndIf;
	Else
		If Object.Used <> True Then
			Object.Used = True;
			Write = True;
		EndIf;
	EndIf;
	
	If Object.Description <> PropertiesSet.Description Then
		Object.Description = PropertiesSet.Description;
		Write = True;
	EndIf;
	
	If Object.PredefinedSetName <> PropertiesSet.Name Then
		Object.PredefinedSetName = PropertiesSet.Name;
		Write = True;
	EndIf;
	
	If Parent = Undefined Then
		For Each TableRow In Object.AdditionalAttributes Do
			If TableRow.PredefinedSetName <> PropertiesSet.Name Then
				TableRow.PredefinedSetName = PropertiesSet.Name;
				Write = True;
			EndIf;
		EndDo;
	EndIf;
	
	If Parent = Undefined Then
		For Each TableRow In Object.AdditionalInformation Do
			If TableRow.PredefinedSetName <> PropertiesSet.Name Then
				TableRow.PredefinedSetName = PropertiesSet.Name;
				Write = True;
			EndIf;
		EndDo;
	EndIf;
	
	If Object.DeletionMark Then
		Object.DeletionMark = False;
		Write = True;
	EndIf;
	
	If PropertySetDescriptions <> Undefined Then
		For Each Language In Metadata.Languages Do
			If Language.LanguageCode = CurrentLanguage().LanguageCode Then
				Continue;
			EndIf;
			LocalizedDescriprions = PropertySetDescriptions[Language.LanguageCode];
			LocalizedDescriprion = LocalizedDescriprions[PropertiesSet.Name];
			PresentationRow = Object.Presentations.Find(Language.LanguageCode, "LanguageCode");
			If PresentationRow = Undefined And ValueIsFilled(LocalizedDescriprion) Then
				Row = Object.Presentations.Add();
				Row.LanguageCode     = Language.LanguageCode;
				Row.Description = LocalizedDescriprion;
				Write = True;
			ElsIf PresentationRow <> Undefined And ValueIsFilled(LocalizedDescriprion) Then
				PresentationRow.Description = LocalizedDescriprion;
				Write = True;
			EndIf;
		EndDo;
	EndIf;
	
	If Write Then
		InfobaseUpdate.WriteObject(Object, False);
	EndIf;
	
EndProcedure

Function PropertySetDescriptions() Export
	Result = New Map;
	For Each Language In Metadata.Languages Do
		Descriptions = New Map;
		PropertiesManagementOverridable.OnGetPropertySetDescription(Descriptions, Language.LanguageCode);
		Result[Language.LanguageCode] = Descriptions;
	EndDo;
	
	Return New FixedMap(Result);
EndFunction

Procedure DeleteInvalidCharacters(Row) Export
	InvalidCharacters = """'`/\[]{}:;|-=?*<>,.()+#№@!%^&~";
	Row = StrConcat(StrSplit(Row, InvalidCharacters, True));
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Вспомогательные процедуры и функции.

// Возвращает основной набор свойств владельца.
//
// Parameters:
//  PropertiesOwner - Ссылка или Объект владельца свойств.
//
// Returns:
//  CatalogRef.AdditionalAttributesAndInformationSets -
//   когда для типа владельца свойств не задано имя реквизита вида объекта в процедуре.
//         УправлениеСвойствамиПереопределяемый.ПолучитьИмяРеквизитаВидаОбъекта(),
//   тогда возвращается предопределенный элемент с именем в формате полное имя
//         объекта метаданных, у которого символ "." заменен символом "_",
//   иначе возвращается значение реквизита НаборСвойств того вида, который
//         содержится в реквизите владельца свойств с именем заданным в
//         переопределяемой процедуре.
//
//  Неопределено - когда владелец свойств - группа элементов справочника или
//                 группа элементов плана видов характеристик.
//  
Function GetMainPropertiesSetForObject(PropertiesOwner)
	
	If CommonUse.ReferenceTypeValue(PropertiesOwner) Then
		Ref = PropertiesOwner;
	Else
		Ref = PropertiesOwner.Ref;
	EndIf;
	
	ObjectMetadata = Ref.Metadata();
	MetadataObjectName = ObjectMetadata.Name;
	
	MetadataObjectKind = CommonUse.ObjectKindByRef(Ref);
	
	If MetadataObjectKind = "Catalog" Or MetadataObjectKind = "ChartOfCharacteristicTypes" Then
		If CommonUse.ObjectIsFolder(PropertiesOwner) Then
			Return Undefined;
		EndIf;
	EndIf;
	ItemName = MetadataObjectKind + "_" + MetadataObjectName;
	MainSet = PropertiesManagement.PropertySetByName(ItemName);
	If MainSet = Undefined Then
		MainSet = Catalogs.AdditionalAttributesAndInformationSets[ItemName];
	EndIf;
	
	Return MainSet;
	
EndFunction

// Is used at updating an infobase.
Function HasChangesMetadataObjectsWithPropertiesOfPresentation()
	
	SetPrivilegedMode(True);
	
	Catalogs.AdditionalAttributesAndInformationSets
		.RefreshContentOfPredefinedSets();
	
	Parameters = StandardSubsystemsServer.ApplicationWorkParameters(
		"AdditionalAttributesAndInformationParameters");
	
	LastChanges = StandardSubsystemsServer.ApplicationPerformenceParameterChanging(
		Parameters, "PredefinedSetsOfAdditionalDetailsAndInformation");
		
	If LastChanges = Undefined
	 OR LastChanges.Count() > 0 Then
		
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

Function MustTransferValueFromLink(Value, Presentation)
	
	If ValueIsFilled(Presentation) And Left(Value, 7) = "<a href" Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

Function ValueWithoutRef(Value, Presentation)
	
	If Not ValueIsFilled(Presentation) Or Left(Value, 7) <> "<a href" Then
		Return Value;
	EndIf;
	
	LinkBegin = "<a href = """;
	LinkEnd = StringFunctionsClientServer.SubstituteParametersInString(""">%1</a>", Presentation);
	
	Result = StrReplace(Value, LinkBegin, "");
	Result = StrReplace(Result, LinkEnd, "");
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Обновление информационной базы.

// Заполняет обработчик разделенных данных, зависимый от изменения неразделенных данных.
//
// Parameters:
//   Обработчики - ТаблицаЗначений, Неопределено - See описание 
//    функции НоваяТаблицаОбработчиковОбновления общего модуля.
//    ОбновлениеИнформационнойБазы.
//    В случае прямого вызова (не через механизм обновления 
//    версии ИБ) передается Неопределено.
// 
Procedure FillSeparatedDataHandlers(Parameters = Undefined) Export
	
	If Parameters <> Undefined And HasChangesMetadataObjectsWithPropertiesOfPresentation() Then
		Handlers = Parameters.SeparatedHandlers;
		Handler = Handlers.Add();
		Handler.Version = "*";
		Handler.PerformModes = "Promptly";
		Handler.Procedure = "PropertiesManagementService.CreatePredefinedPropertySets";
	EndIf;
	
EndProcedure

// Устанавливает значения свойства Используется в значение True.
//
Procedure SetSignUsedValue() Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	AdditionalAttributesAndInformationSets.Ref
	|FROM
	|	Catalog.AdditionalAttributesAndInformationSets AS AdditionalAttributesAndInformationSets
	|WHERE
	|	NOT AdditionalAttributesAndInformationSets.Used";
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		ObjectSet = Selection.Ref.GetObject();
		ObjectSet.Used = True;
		InfobaseUpdate.WriteData(ObjectSet);
		
	EndDo;
	
EndProcedure

#EndRegion
