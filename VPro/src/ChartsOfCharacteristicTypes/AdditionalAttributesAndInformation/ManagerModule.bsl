
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region ProgramInterface

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.ГрупповоеИзменениеОбъектов

// Returns the list of
// attributes allowed to be changed with the help of the group change data processor.
//
// Returns:
//  Array - список имен реквизитов объекта.
Function EditedAttributesInGroupDataProcessing() Export
	
	EditableAttributes = New Array;
	
	EditableAttributes.Add("MultilineTextBox");
	EditableAttributes.Add("ValueFormHeader");
	EditableAttributes.Add("ValueChoiceFormHeader");
	EditableAttributes.Add("FormatProperties");
	EditableAttributes.Add("Comment");
	EditableAttributes.Add("ToolTip");
	
	Return EditableAttributes;
	
EndFunction

// End StandardSubsystems.ГрупповоеИзменениеОбъектов

// StandardSubsystems.ЗапретРедактированияРеквизитовОбъектов

// See ObjectsAttributesEditProhibitionOverridable.OnDetermineObjectsWithLockedAttributes.
Function GetObjectAttributesBeingLocked() Export
	
	Result = New Array;
	
	Result.Add("ValueType");
	Result.Add("Name");
	
	Return Result;
	
EndFunction

// End StandardSubsystems.ЗапретРедактированияРеквизитовОбъектов

// StandardSubsystems.УправлениеДоступом

// See AccessManagementOverridable.OnFillListWithAccessRestriction.
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowReadChange
	|WHERE
	|	ValueAllowed(Ref)
	|	OR NOT ThisIsAdditionalInformation";
	
EndProcedure

// End StandardSubsystems.УправлениеДоступом

#EndRegion

#EndRegion

#EndIf

#Region EventsHandlers

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Parameters.Property("IsAccessValueSelect") Then
		Parameters.Filter.Insert("ThisIsAdditionalInformation", True);
	EndIf;
	
EndProcedure

#EndIf

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	Fields.Add("PropertySet");
	Fields.Add("Title");
	Fields.Add("Ref");
	
	StandardProcessing = False;
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	If Not ValueIsFilled(Presentation) Then
		Presentation = Data.Title;
	EndIf;
	
	If ValueIsFilled(Data.PropertySet) Then
		Presentation = Presentation + " (" + String(Data.PropertySet) + ")";
	EndIf;
	StandardProcessing = False;
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region InternalProceduresAndFunctions

// Changes property setting from the common property or the
// common list of the property values into the separate property with separate properties list.
//
Procedure ChangePropertiesConfiguration(Parameters, StorageAddress) Export
	
	Property            = Parameters.Property;
	CurrentSetOfProperties = Parameters.CurrentSetOfProperties;
	
	OpenProperty = Undefined;
	Block = New DataLock;
	
	LockItem = Block.Add("ChartOfCharacteristicTypes.AdditionalAttributesAndInformation");
	LockItem.SetValue("Ref", Property);
	
	LockItem = Block.Add("Catalog.AdditionalAttributesAndInformationSets");
	LockItem.SetValue("Ref", CurrentSetOfProperties);
	
	LockItem = Block.Add("Catalog.ObjectsPropertiesValues");
	LockItem = Block.Add("Catalog.ObjectsPropertiesValuesHierarchy");
	
	BeginTransaction();
	Try
		Block.Lock();
		
		PropertyObject = Property.GetObject();
		
		Query = New Query;
		If ValueIsFilled(PropertyObject.AdditionalValuesOwner) Then
			Query.SetParameter("Owner", PropertyObject.AdditionalValuesOwner);
			PropertyObject.AdditionalValuesOwner = Undefined;
			PropertyObject.Write();
		Else
			Query.SetParameter("Owner", Property);
			NewObject = CreateItem();
			FillPropertyValues(NewObject, PropertyObject, , "Parent");
			
			Filter = New Structure;
			Filter.Insert("PropertySet", CurrentSetOfProperties);
			SetDependencies = PropertyObject.AdditionalAttributeDependencies.FindRows(Filter);
			For Each Dependence In SetDependencies Do
				FillPropertyValues(NewObject.AdditionalAttributeDependencies.Add(), Dependence);
			EndDo;
			
			PropertyObject = NewObject;
			If ValueIsFilled(PropertyObject.Name) Then
				NameParts = StrSplit(PropertyObject.Name, "_");
				Name = NameParts[0];
				
				UID = New UUID();
				StringAtID = StrReplace(String(UID), "-", "");
				PropertyObject.Name = Name + "_" + StringAtID;
			EndIf;
			PropertyObject.PropertySet = CurrentSetOfProperties;
			PropertyObject.Write();
			
			PropertiesSetObject = CurrentSetOfProperties.GetObject();
			If PropertyObject.ThisIsAdditionalInformation Then
				FoundString = PropertiesSetObject.AdditionalInformation.Find(Property, "Property");
				If FoundString = Undefined Then
					PropertiesSetObject.AdditionalInformation.Add().Property = PropertyObject.Ref;
				Else
					FoundString.Property = PropertyObject.Ref;
					FoundString.DeletionMark = False;
				EndIf;
			Else
				FoundString = PropertiesSetObject.AdditionalAttributes.Find(Property, "Property");
				If FoundString = Undefined Then
					PropertiesSetObject.AdditionalAttributes.Add().Property = PropertyObject.Ref;
				Else
					FoundString.Property = PropertyObject.Ref;
					FoundString.DeletionMark = False;
				EndIf;
			EndIf;
			PropertiesSetObject.Write();
		EndIf;
		
		OpenProperty = PropertyObject.Ref;
		
		OwnerMetadata = PropertiesManagementService.PropertiesSetValuesOwnerMetadata(
			CurrentSetOfProperties, False);
		
		If OwnerMetadata = Undefined Then
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en='Error when changing settings of the %1 property."
"Properties set %2 is not associated with any owner of property values.';ru='Ошибка при изменении настройки свойства %1."
"Набор свойств %2 не связан ни с одним владельцем значений свойств.';vi='Lỗi khi thay đổi tùy chỉnh thuộc tính %1."
"Tập hợp thuộc tính %2 không có liên quan đến bất kỳ đối tượng chủ giá trị thuộc tính.'"),
				Property,
				CurrentSetOfProperties);
		EndIf;
		
		OwnerFullName = OwnerMetadata.FullName();
		ReferenceMap = New Map;
		
		HasAdditionalValues = PropertiesManagementService.ValueTypeContainsPropertiesValues(
			PropertyObject.ValueType);
		
		If HasAdditionalValues Then
			
			If PropertyObject.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues")) Then
				CatalogName = "ObjectsPropertiesValues";
				IsFolder      = "Values.IsFolder";
			Else
				CatalogName = "ObjectsPropertiesValuesHierarchy";
				IsFolder      = "FALSE AS IsFolder";
			EndIf;
			
			Query.Text =
			"SELECT
			|	Values.Ref AS Ref,
			|	Values.Parent AS ParentReferences,
			|	Values.IsFolder,
			|	Values.DeletionMark,
			|	Values.Description,
			|	Values.Weight
			|FROM
			|	Catalog.ObjectsPropertiesValues AS Values
			|WHERE
			|	Values.Owner = &Owner
			|TOTALS BY
			|	Ref HIERARCHY";
			Query.Text = StrReplace(Query.Text, "ObjectsPropertiesValues", CatalogName);
			Query.Text = StrReplace(Query.Text, "Values.IsFolder", IsFolder);
			
			Unloading = Query.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy);
			CreateGroupsAndValues(Unloading.Rows, ReferenceMap, CatalogName, PropertyObject.Ref);
			
		ElsIf Property = PropertyObject.Ref Then
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en='Error when changing settings of the %1 property."
"Value type does not contain the additional values.';ru='Ошибка при изменении настройки свойства %1."
"Тип значения не содержит дополнительных значений.';vi='Lỗi khi thay đổi tùy chỉnh thuộc tính %1."
"Kiểu giá trị không có giá trị bổ sung.'"),
				Property);
		EndIf;
		
		If Property <> PropertyObject.Ref
		 OR ReferenceMap.Count() > 0 Then
			
			Block = New DataLock;
			
			LockItem = Block.Add("InformationRegister.AdditionalInformation");
			LockItem.SetValue("Property", Property);
			
			LockItem = Block.Add("InformationRegister.AdditionalInformation");
			LockItem.SetValue("Property", PropertyObject.Ref);
			
			// If the original property is common then it
			// is necessary to get an object sets list (for each
			// ref), and if not only the target dataset has the replaced common  property then it is necessary to add new property and value.
			//
			// For the original common properties when the owners of their
			// values have some sets of properties, the procedure can be too long, as requires sets analysis for each
			// owner object as the procedure FillObjectPropertiesSets
			// of the common module PropertyRunPredefined has sets content predefining.
			
			OwnerWithAdditionalDetails = False;
			
			If PropertiesManagementService.IsMetadataObjectWithAdditionalDetails(OwnerMetadata) Then
				OwnerWithAdditionalDetails = True;
				LockItem = Block.Add(OwnerFullName);
			EndIf;
			
			Block.Lock();
			
			SetsAnalysisOfEachObjectOwnerRequired = False;
			
			If Property <> PropertyObject.Ref Then
				
				PredefinedName = StrReplace(OwnerMetadata.FullName(), ".", "_");
				PropertySet = PropertiesManagement.PropertySetByName(PredefinedName);
				If PropertySet = Undefined Then
					SetsAnalysisOfEachObjectOwnerRequired = CommonUse.ObjectAttributeValue(
						"Catalog.AdditionalAttributesAndInformationSets." + PredefinedName, "IsFolder");
				Else
					SetsAnalysisOfEachObjectOwnerRequired = CommonUse.ObjectAttributeValue(
						PropertySet, "IsFolder");
				EndIf;
				// Если предопределенного нет в ИБ.
				If SetsAnalysisOfEachObjectOwnerRequired = Undefined Then 
					SetsAnalysisOfEachObjectOwnerRequired = False;
				EndIf;
				
			EndIf;
			
			If SetsAnalysisOfEachObjectOwnerRequired Then
				QueryAnalysis = New Query;
				QueryAnalysis.SetParameter("CommonProperty", Property);
				QueryAnalysis.SetParameter("NewPropertySet", CurrentSetOfProperties);
				QueryAnalysis.Text =
				"SELECT TOP 1
				|	TRUE AS TrueValue
				|FROM
				|	Catalog.AdditionalAttributesAndInformationSets.AdditionalInformation AS PropertiesSets
				|WHERE
				|	PropertiesSets.Ref <> &NewPropertySet
				|	AND PropertiesSets.Ref IN(&AllObjectSet)
				|	AND PropertiesSets.Property = &CommonProperty";
			EndIf;
			
			Query = New Query;
			
			If Property = PropertyObject.Ref Then
				// If the property is not changed (already separate) and only additional
				// values list is common,  then only additional values replacement is required.
				Query.TempTablesManager = New TempTablesManager;
				
				ValueTable = New ValueTable;
				ValueTable.Columns.Add("Value", New TypeDescription(
					"CatalogRef." + CatalogName));
				
				For Each KeyAndValue IN ReferenceMap Do
					ValueTable.Add().Value = KeyAndValue.Key;
				EndDo;
				
				Query.SetParameter("ValueTable", ValueTable);
				
				Query.Text =
				"SELECT
				|	ValueTable.Value AS Value
				|INTO OldValues
				|FROM
				|	&ValueTable AS ValueTable
				|
				|INDEX BY
				|	Value";
				Query.Execute();
			EndIf;
			
			Query.SetParameter("Property", Property);
			AdditionalValuesTypes = New Map;
			AdditionalValuesTypes.Insert(Type("CatalogRef.ObjectsPropertiesValues"), True);
			AdditionalValuesTypes.Insert(Type("CatalogRef.ObjectsPropertiesValuesHierarchy"), True);
			
			// Additional information replacement.
			
			If Property = PropertyObject.Ref Then
				// If the property is not changed (already separate) and only additional
				// values list is common,  then only additional values replacement is required.
				Query.Text =
				"SELECT TOP 1000
				|	AdditionalInformation.Object
				|FROM
				|	InformationRegister.AdditionalInformation AS AdditionalInformation
				|		INNER JOIN OldValues AS OldValues
				|		ON (VALUETYPE(AdditionalInformation.Object) = Type(Catalog.ObjectsPropertiesValues))
				|			AND (NOT AdditionalInformation.Object IN (&ProcessedObjects))
				|			AND (AdditionalInformation.Property = &Property)
				|			AND AdditionalInformation.Value = OldValues.Value";
			Else
				// If the property is changed (common property becomes separated and
				// additional values are copied),then property and additional values replacement is required.
				Query.Text =
				"SELECT TOP 1000
				|	AdditionalInformation.Object
				|FROM
				|	InformationRegister.AdditionalInformation AS AdditionalInformation
				|WHERE
				|	VALUETYPE(AdditionalInformation.Object) = Type(Catalog.ObjectsPropertiesValues)
				|	AND Not AdditionalInformation.Object IN (&ProcessedObjects)
				|	AND AdditionalInformation.Property = &Property";
			EndIf;
			
			Query.Text = StrReplace(Query.Text, "Catalog.ObjectsPropertiesValues", OwnerFullName);
			
			SetOfOldRecords = InformationRegisters.AdditionalInformation.CreateRecordSet();
			NewRecordSet  = InformationRegisters.AdditionalInformation.CreateRecordSet();
			NewRecordSet.Add();
			
			ProcessedObjects = New Array;
			
			While True Do
				Query.SetParameter("ProcessedObjects", ProcessedObjects);
				Selection = Query.Execute().Select();
				If Selection.Count() = 0 Then
					Break;
				EndIf;
				While Selection.Next() Do
					Replace = True;
					If SetsAnalysisOfEachObjectOwnerRequired Then
						QueryAnalysis.SetParameter("AllObjectSet",
							PropertiesManagementService.GetObjectPropertiesSets(
								Selection.Object).UnloadColumn("Set"));
						Replace = QueryAnalysis.Execute().IsEmpty();
					EndIf;
					SetOfOldRecords.Filter.Object.Set(Selection.Object);
					SetOfOldRecords.Filter.Property.Set(Property);
					SetOfOldRecords.Read();
					If SetOfOldRecords.Count() > 0 Then
						NewRecordSet[0].Object   = Selection.Object;
						NewRecordSet[0].Property = PropertyObject.Ref;
						Value = SetOfOldRecords[0].Value;
						If AdditionalValuesTypes[TypeOf(Value)] = Undefined Then
							NewRecordSet[0].Value = Value;
						Else
							NewRecordSet[0].Value = ReferenceMap[Value];
						EndIf;
						NewRecordSet.Filter.Object.Set(Selection.Object);
						NewRecordSet.Filter.Property.Set(NewRecordSet[0].Property);
						If Replace Then
							SetOfOldRecords.Clear();
							SetOfOldRecords.DataExchange.Load = True;
							SetOfOldRecords.Write();
						Else
							ProcessedObjects.Add(Selection.Object);
						EndIf;
						NewRecordSet.DataExchange.Load = True;
						NewRecordSet.Write();
					EndIf;
				EndDo;
			EndDo;
			
			// Additional attributes replacement.
			
			If OwnerWithAdditionalDetails Then
				
				If SetsAnalysisOfEachObjectOwnerRequired Then
					QueryAnalysis = New Query;
					QueryAnalysis.SetParameter("CommonProperty", Property);
					QueryAnalysis.SetParameter("NewPropertySet", CurrentSetOfProperties);
					QueryAnalysis.Text =
					"SELECT TOP 1
					|	TRUE AS TrueValue
					|FROM
					|	Catalog.AdditionalAttributesAndInformationSets.AdditionalAttributes AS PropertiesSets
					|WHERE
					|	PropertiesSets.Ref <> &NewPropertySet
					|	AND PropertiesSets.Ref IN(&AllObjectSet)
					|	AND PropertiesSets.Property = &CommonProperty";
				EndIf;
				
				If Property = PropertyObject.Ref Then
					// If the property is not changed (already separate) and only additional
					// values list is common,  then only additional values replacement is required.
					Query.Text =
					"SELECT TOP 1000
					|	CurrentTable.Ref AS Ref
					|FROM
					|	TableName AS CurrentTable
					|		INNER JOIN OldValues AS OldValues
					|		ON (NOT CurrentTable.Ref IN (&ProcessedObjects))
					|			AND (CurrentTable.Property = &Property)
					|			AND CurrentTable.Value = OldValues.Value";
				Else
					// If the property is changed (common property becomes separated and
					// additional values are copied),then property and additional values replacement is required.
					Query.Text =
					"SELECT TOP 1000
					|	CurrentTable.Ref AS Ref
					|FROM
					|	TableName AS CurrentTable
					|WHERE
					|	Not CurrentTable.Ref IN (&ProcessedObjects)
					|	AND CurrentTable.Property = &Property";
				EndIf;
				Query.Text = StrReplace(Query.Text, "TableName", OwnerFullName + ".AdditionalAttributes");
				
				ProcessedObjects = New Array;
				
				While True Do
					Query.SetParameter("ProcessedObjects", ProcessedObjects);
					Selection = Query.Execute().Select();
					If Selection.Count() = 0 Then
						Break;
					EndIf;
					While Selection.Next() Do
						CurrentObject = Selection.Ref.GetObject();
						Replace = True;
						If SetsAnalysisOfEachObjectOwnerRequired Then
							QueryAnalysis.SetParameter("AllObjectSet",
								PropertiesManagementService.GetObjectPropertiesSets(
									Selection.Ref).UnloadColumn("Set"));
							Replace = QueryAnalysis.Execute().IsEmpty();
						EndIf;
						For Each Row In CurrentObject.AdditionalAttributes Do
							If Row.Property = Property Then
								Value = Row.Value;
								If AdditionalValuesTypes[TypeOf(Value)] <> Undefined Then
									Value = ReferenceMap[Value];
								EndIf;
								If Replace Then
									If Row.Property <> PropertyObject.Ref Then
										Row.Property = PropertyObject.Ref;
									EndIf;
									If Row.Value <> Value Then
										Row.Value = Value;
									EndIf;
								Else
									NewRow = CurrentObject.AdditionalAttributes.Add();
									NewRow.Property = PropertyObject.Ref;
									NewRow.Value = Value;
									ProcessedObjects.Add(CurrentObject.Ref);
									Break;
								EndIf;
							EndIf;
						EndDo;
						If CurrentObject.Modified() Then
							CurrentObject.DataExchange.Load = True;
							CurrentObject.Write();
						EndIf;
					EndDo;
				EndDo;
			EndIf;
			
			If Property = PropertyObject.Ref Then
				Query.TempTablesManager.Close();
			EndIf;
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	PutToTempStorage(OpenProperty, StorageAddress);
	
EndProcedure

Procedure CreateGroupsAndValues(Rows, ReferenceMap, CatalogName, Property, OldParent = Undefined)
	
	For Each Row In Rows Do
		If Row.Ref = OldParent Then
			Continue;
		EndIf;
		
		If Row.IsFolder = True Then
			NewObject = Catalogs[CatalogName].CreateFolder();
			FillPropertyValues(NewObject, Row, "Description, DeletionMark");
		Else
			NewObject = Catalogs[CatalogName].CreateItem();
			FillPropertyValues(NewObject, Row, "Description, Weight, DeletionMark");
		EndIf;
		NewObject.Owner = Property;
		If ValueIsFilled(Row.ParentReferences) Then
			NewObject.Parent = ReferenceMap[Row.ParentReferences];
		EndIf;
		NewObject.Write();
		ReferenceMap.Insert(Row.Ref, NewObject.Ref);
		
		CreateGroupsAndValues(Row.Rows, ReferenceMap, CatalogName, Property, Row.Ref);
	EndDo;
	
EndProcedure

Procedure ОбработатьДанныеДляПереходаНаНовуюВерсию(Parameters) Export
	
	FullName = "ChartOfCharacteristicTypes.AdditionalAttributesAndInformation";

	Query = New Query;
	Query.Text =
		"SELECT
		|	AdditionalAttributesAndInformation.Ref AS Ref
		|FROM
		|	ChartOfCharacteristicTypes.AdditionalAttributesAndInformation AS AdditionalAttributesAndInformation
		|WHERE
		|	AdditionalAttributesAndInformation.Name LIKE """"
		|	OR AdditionalAttributesAndInformation.Name LIKE ""%-%""
		|
		|UNION ALL
		|
		|SELECT
		|	AdditionalAttributeDependencies.Ref AS Ref
		|FROM
		|	ChartOfCharacteristicTypes.AdditionalAttributesAndInformation.AdditionalAttributeDependencies AS AdditionalAttributeDependencies
		|WHERE
		|	AdditionalAttributeDependencies.PropertySet = &PropertySet";
		
	Query.SetParameter("PropertySet", Catalogs.AdditionalAttributesAndInformationSets.EmptyRef());
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	ProblemObjects = 0;
	ObjectsProcessed = 0;
	
	While Selection.Next() Do
		
		BeginTransaction();
		Try
			// Блокируем объект от изменения другими сеансами.
			Block = New DataLock;
			LockItem = Block.Add(FullName);
			LockItem.SetValue("Ref", Selection.Ref);
			Block.Lock();
			
			Object = Selection.Ref.GetObject();
			
			If Not ValueIsFilled(Object.Name) Then
				SetAttributeName(Selection, Object);
			Else
				PropertiesManagementService.DeleteInvalidCharacters(Object.Name);
			EndIf;
			
			For Each Dependence In Object.AdditionalAttributeDependencies Do
				If ValueIsFilled(Dependence.PropertySet) Then
					Continue;
				EndIf;
				Dependence.PropertySet = Object.PropertySet;
			EndDo;
			
			InfobaseUpdate.WriteData(Object);
			ObjectsProcessed = ObjectsProcessed + 1;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			ProblemObjects = ProblemObjects + 1;
			
			TextOfMessage = StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en='It was not possible to process additional attribute (intelligence): %1 for the reason:"
"%2';ru='Не удалось обработать дополнительный реквизит (сведение): %1 по причине:"
"%2';vi='Không thể xử lý mục tin (thông tin) bổ sung: %1 do: %2'"), 
					Selection.Ref, DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(InfobaseUpdate.EventLogMonitorEvent(), EventLogLevel.Warning,
				Metadata.ChartsOfCharacteristicTypes.AdditionalAttributesAndInformation, Selection.Ref, TextOfMessage);
		EndTry;
		
	EndDo;
	
	If ObjectsProcessed = 0 And ProblemObjects <> 0 Then
		TextOfMessage = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='Unable to process some additional attributes or information (skipped): %1';ru='Не удалось обработать некоторые дополнительные реквизиты или сведения (пропущены): %1';vi='Không thể xử lý một số mục tin hoặc thông tin bổ sung (đã bỏ qua): %1'"), 
				ProblemObjects);
		Raise TextOfMessage;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogMonitorEvent(), EventLogLevel.Information,
			Metadata.ChartsOfCharacteristicTypes.AdditionalAttributesAndInformation,,
				StringFunctionsClientServer.SubstituteParametersInString(NStr("en='Processed another portion of additional attributes (information): %1';ru='Обработана очередная порция дополнительных реквизитов (сведений): %1';vi='Đã xử lý phần tiếp theo của các mục tin (thông tin) bổ sung: %1'"),
					ObjectsProcessed));
	EndIf;
	
EndProcedure

Procedure SetAttributeName(Selection, Object)
	
	ObjectHeader = Object.Title;
	PropertiesManagementService.DeleteInvalidCharacters(ObjectHeader);
	ObjectHeaderParts = StrSplit(ObjectHeader, " ", False);
	For Each HeaderPart In ObjectHeaderParts Do
		Object.Name = Object.Name + Upper(Left(HeaderPart, 1)) + Mid(HeaderPart, 2);
	EndDo;
	
	// Проверка уникальности имени.
	If NameUsed(Selection.Ref, Object.Name) Then
		UID = New UUID();
		StringAtID = StrReplace(String(UID), "-", "");
		Object.Name = Object.Name + "_" + StringAtID;
	EndIf;

EndProcedure

Function NameUsed(Ref, Name)
	
	Query = New Query;
	Query.Text =
		"SELECT TOP 1
		|	Properties.ThisIsAdditionalInformation
		|FROM
		|	ChartOfCharacteristicTypes.AdditionalAttributesAndInformation AS Properties
		|WHERE
		|	Properties.Name = &Name
		|	AND Properties.Ref <> &Ref";
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Name",    Name);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

#EndRegion

#EndIf