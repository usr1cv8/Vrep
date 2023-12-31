////////////////////////////////////////////////////////////////////////////////
// Subsystem "Change prohibition dates".
// 
////////////////////////////////////////////////////////////////////////////////

#Region ProgramInterface

// Checks the existence of the data item change prohibition.
//  Function operation requires the FillDataSourcesForChangeProhibitionCheck
// procedure of the ChangeProhibitionDatesOverridable module setup.
//
//  If Data - metadata object full name, then data for checking
// will be received from database through DataId.
//  If Data - object, then data for checking will be received from
// the object instance or set of records.
//  If Data - object, and DataId is set, then two
// checks will be performed, data will be received from object/record set and from database through DataId.
//
// Parameters:
//  Data              - String - (metadata object full name).
//                      - CatalogObject.<Name>,
//                        DocumentObject.<Name>,
//                        ChartOfCharacteristicTypesObject.<Name>,
//                        ChartOfAccountsObject.<Name>,
//                        ChartOfCalculationTypesObject.<Name>,
//                        BusinessProcessObject.<Name>,
//                        TaskObject.<Name>,
//                        ExchangePlanObject - data object.
//                      - InformationRegisterRecordSet.<Name>.Filter,
//                        AccumulationRegisterRecordSet.<Name>.Filter,
//                        AccountingRegisterRecordSet.<Name>.Filter,
//                        CalculationRegisterRecordSet.<Name>.Filter - record set.
//
//  DataId - CatalogRef.<Name>,
//                        DocumentRef.<Name>,
//                        ChartOfCharacteristicTypesRef.<Name>,
//                        ChartOfAccountsRef.<Name>,
//                        ChartOfCalculationTypesRef.<Name>,
//                        BusinessProcessRef.<Name>,
//                        TaskRef.<Name>,
//                        ExchangePlanRef.<Name> - ref for data object.
//                      - InformationRegisterRecordSet.<Name>.Filter,
//                        AccumulationRegisterRecordSet.<Name>.Filter,
//                        AccountingRegisterRecordSet.<Name>.Filter,
//                        CalculationRegisterRecordSet.<Name>.Filter - records set filter.
//
//  InformAboutProhibition    - Boolean - If False is passed,
//                        the message about data change prohibition will not be sent to user.
//
// Returns:
//  Boolean - If True changing is prohibited.
//
Function ChangingProhibited(Val Data,
                           Val DataId  = Undefined,
                           Val InformAboutProhibition     = True,
                           // Expired. Following parameters are out of
                           // date and will be deleted in the next edition of SSL. The ImportingIsProhibited function is used instead of it.
                           Val StandardProcessing = True,
                           Val ExchangePlanNode      = Undefined,
                                FoundProhibitions     = Undefined) Export
	
	Return ChangeProhibitionDatesService.ChangingOrImportingIsProhibited(
		Data,
		DataId,
		InformAboutProhibition,
		StandardProcessing,
		ExchangePlanNode,
		FoundProhibitions);
	
EndFunction

// Checks the existence of the data item import prohibition.
//  Function operation requires the setup
// of the DataForChangingProhibitionCheck procedure of the ChangeProhibitionDatesOverridable module.
//
// Parameters:
//  Data              - CatalogObject.<Name>,
//                        DocumentObject.<Name>,
//                        ChartOfCharacteristicTypesObject.<Name>,
//                        ChartOfAccountsObject.<Name>,
//                        ChartOfCalculationTypesObject.<Name>,
//                        BusinessProcessObject.<Name>,
//                        TaskObject.<Name>,
//                        ExchangePlanObject.<Name>,
//                        ObjectDeletion - data object.
//                        InformationRegisterRecordSet.<Name>,
//                        AccumulationRegisterRecordSet.<Name>,
//                        AccountingRegisterRecordSet.<Name>,
//                        CalculationRegisterRecordSet.<Name> - record set.
//
//  ExchangePlanNode     - ExchangePlansRef.<Exchange plan name> - node
//                        for which the check will be executed.
//
//  ErrorInfo   - String (return value) - description of importing prohibition.
//
// Returns:
//  Boolean - If True import is prohibited.
//
Function ImportingIsProhibited(Data, ExchangePlanNode, ErrorInfo = "") Export
	
	If TypeOf(Data) = Type("ObjectDeletion") Then
		MetadataObject = Data.Ref.Metadata();
	Else
		MetadataObject = Data.Metadata();
	EndIf;
	
	
	DataSources = ChangeProhibitionDatesServiceReUse.DataSourcesForChangeProhibitionCheck(
		).FindRows(New Structure("Table", MetadataObject.FullName()));
	
	If DataSources.Count() = 0 Then
		Return False; // Prohibitions by dates are not defined for current object type.
	EndIf;
	
	Cancel = False;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("InformAboutProhibition",     False);
	AdditionalParameters.Insert("StandardProcessing", False);
	AdditionalParameters.Insert("ExchangePlanNode",      ExchangePlanNode);
	AdditionalParameters.Insert("FoundProhibitions",     New Structure);
	
	ChangeProhibitionDatesService.CheckDataImportChangeProhibitionDates(
		Data,
		Cancel,
		CommonUse.ThisIsRegister(MetadataObject),
		False,
		TypeOf(Data) = Type("ObjectDeletion"),
		AdditionalParameters);
	
	If Cancel Then
		ErrorInfo = AdditionalParameters.FoundProhibitions.DataImportProhibitionFound;
	EndIf;
	
	Return Cancel;
	
EndFunction

// Event handler of the WhenReadOnServer form that is embedded
// into the forms of catalogs, documents, register records, and others, in order to lock the form if there is a change prohibition.
//
// Parameters:
//  Form               - ManagedForm - data object or register record form.
//
//  CurrentObject       - CatalogObject.<Name>,
//                        DocumentObject.<Name>,
//                        ChartOfCharacteristicTypesObject.<Name>,
//                        ChartOfAccountsObject.<Name>,
//                        ChartOfCalculationTypesObject.<Name>,
//                        BusinessProcessObject.<Name>,
//                        TaskObject.<Name>,
//                        ExchangePlanObject.<Name> - ref for data object.
//                        InformationRegisterRecordManager.<Name>,
//                        RegisterAccumulationRecordManager.<Name>,
//                        RegisterAccountingRecordManager.<Name>,
//                        CalculationRegisterRecordManager.<Name> - record manager.
//
Function ObjectOnReadAtServer(Form, CurrentObject) Export
	
	MetadataObject = Metadata.FindByType(TypeOf(CurrentObject));
	FullName = MetadataObject.FullName();
	
	If CommonUse.ThisIsRegister(MetadataObject) Then
		// Adjust the record manager to the set of records with one record.
		DataManager = CommonUse.ObjectManagerByFullName(FullName);
		Source = DataManager.CreateRecordSet();
		For Each FilterItem IN Source.Filter Do
			FilterItem.Set(CurrentObject[FilterItem.Name], True);
		EndDo;
		DataId = Source.Filter;
		FillPropertyValues(Source.Add(), CurrentObject);
	Else
		Source = CurrentObject;
		DataId = CurrentObject.Ref;
	EndIf;
	
	If ChangeProhibitionDatesService.SkipProhibitionDatesCheck(
	         Source, False, True, Undefined) Then
		
		Return True;
	EndIf;
	
	If ChangingProhibited(FullName, DataId, False) Then
		Form.ReadOnly = True;
	EndIf;
	
EndFunction

// Adds data source description line for the change prohibition check.
// Used in
// the FillDataSourcesForChangeProhibitionCheck procedure of the ChangeProhibitionDatesOverridable common module.
// 
// Parameters:
//  Data      - ValueTable - is passed to the FillDataSourcesForChangeProhibitionCheck procedure.
//  Table     - String - full name of the metadata object, for example "Document.SupplierInvoice".
//  DataField    - String - name of the object attribute or tabular section, for example, "Date", "Goods.ShipmentDate".
//  Section      - String - name of the predefined item "ChartOfCharacteristicTypesRef.ProhibitionDatesSections".
//  ObjectField - String - name of the object attribute or tabular section attribute, for example, "Company", "Goods".Warehouse".
//
Procedure AddLine(Data, Table, DataField, Section = "", ObjectField = "") Export
	
	NewRow = Data.Add();
	NewRow.Table     = Table;
	NewRow.DataField    = DataField;
	NewRow.Section      = Section;
	NewRow.ObjectField = ObjectField;
	
EndProcedure

// Performs search for prohibition dates
// by verifiable data for authorized user and/or exchange plan node.
//
// Parameters:
//  DataForChecking    - ValueTable - is returned by function.
//                         DataTemplateForChecking of common ChangeProhibitionDates module.
//
//  InformAboutProhibition     - Boolean - if true, the message
//                         about the prohibitions found when verifying data will be displayed.
//
//  DataId  - Ref - on data object to get
//                         the presentation used in message about prohibition.
//
//  StandardProcessing - Boolean - If False, then changing prohibition check
//                         (for users) will be skipped.
//
//  ExchangePlanNode      - Undefined, PlansExchangeRef.<Exchange plan name> -
//                         if you specify a node, the import prohibition will be checked.
//
//  FoundProhibitions     - Structure - return value.
//                         If the data change prohibition is
//                         found, then there is the
//                         FoundDataChangeProhibition property if the data import prohibition is found, then there is the FoundDataImportProhibition property.
//
// Returns:
//  Boolean - if True, it means that at least one change prohibition is found.
//
Function DataChangeProhibitionFound(Val DataForChecking,
                                    Val InformAboutProhibition,
                                    Val DataId,
                                    Val StandardProcessing = True,
                                    Val ExchangePlanNode      = Undefined,
                                         FoundProhibitions     = Undefined) Export
	
	SetPrivilegedMode(True);
	
	If TypeOf(DataForChecking) = Type("Structure") Then
		DataId = DataForChecking.DataIdForPresentation;
		DataTable       = DataForChecking.Table;
		DataForChecking = GetDataForChecking(DataForChecking);
	Else
		If DataId = Undefined Then
			DataTable = Undefined;
		Else
			DataTable = DataId.Metadata().FullName();
		EndIf;
	EndIf;
	
	// Adjusting the objects empty references to a single Undefined value.
	For Each String IN DataForChecking Do
		If Not ValueIsFilled(String.Object) Then
			String.Object = Undefined;
		EndIf;
	EndDo;
	
	// Convolution of useless lines to reduce the number of checks and messages.
	DataForChecking.GroupBy("Date, Section, Object");
	// Function keys for individual tests.
	DataForChecking.Columns.Add("RowKey", New TypeDescription("Number"));
	CurrentRowKey = 0;
	For Each String IN DataForChecking Do
		String.RowKey = CurrentRowKey;
		CurrentRowKey = CurrentRowKey + 1;
	EndDo;
	
	EmbeddingProperties = ChangeProhibitionDatesServiceReUse.SectionsProperties();
	
	BeginTransaction();
	Try
		Query = New Query;
		Query.SetParameter("DataForChecking",     DataForChecking);
		Query.SetParameter("WithoutSectionsAndObjects",  EmbeddingProperties.WithoutSectionsAndObjects);
		Query.SetParameter("AllSectionsWithoutObjects", EmbeddingProperties.AllSectionsWithoutObjects);
		Query.SetParameter("SingleSection",    EmbeddingProperties.SingleSection);
		Query.SetParameter("FirstSection",          ?(EmbeddingProperties.SingleSection,
		                                                     EmbeddingProperties.SectionObjectsTypes[0].Section,
		                                                     Undefined));
		Query.TempTablesManager = New TempTablesManager;
		Query.Text =
		"SELECT
		|	DataForChecking.Section,
		|	DataForChecking.Object,
		|	DataForChecking.Date,
		|	DataForChecking.RowKey
		|INTO InitialData
		|FROM
		|	&DataForChecking AS DataForChecking
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Data.Section,
		|	Data.Object,
		|	MIN(Data.Date) AS Date,
		|	MIN(Data.RowKey) AS RowKey
		|INTO DataForChecking
		|FROM
		|	(SELECT
		|		CASE
		|			WHEN &WithoutSectionsAndObjects
		|				THEN VALUE(ChartOfCharacteristicTypes.ChangingProhibitionDatesSections.EmptyRef)
		|			WHEN &SingleSection
		|				THEN &FirstSection
		|			ELSE InitialData.Section
		|		END AS Section,
		|		CASE
		|			WHEN &WithoutSectionsAndObjects
		|				THEN VALUE(ChartOfCharacteristicTypes.ChangingProhibitionDatesSections.EmptyRef)
		|			ELSE CASE
		|					WHEN &AllSectionsWithoutObjects
		|							OR InitialData.Object = UNDEFINED
		|						THEN CASE
		|								WHEN &SingleSection
		|									THEN &FirstSection
		|								ELSE InitialData.Section
		|							END
		|					ELSE InitialData.Object
		|				END
		|		END AS Object,
		|		InitialData.Date AS Date,
		|		InitialData.RowKey AS RowKey
		|	FROM
		|		InitialData AS InitialData) AS Data
		|
		|GROUP BY
		|	Data.Section,
		|	Data.Object
		|
		|HAVING
		|	(NOT(Data.Object <> Data.Section
		|			AND VALUETYPE(Data.Object) = Type(ChartOfCharacteristicTypes.ChangingProhibitionDatesSections))) AND
		|	(NOT(Data.Object <> Data.Section
		|			AND Data.Section = VALUE(ChartOfCharacteristicTypes.ChangingProhibitionDatesSections.EmptyRef)))";
		Query.Execute();
		
		FoundProhibitions = New Structure;
		Query.SetParameter("ExchangePlansNodesEmptyRefs", EmbeddingProperties.ExchangePlansNodesEmptyRefs);
		Message = "";
		
		If StandardProcessing Then
			
			Query.SetParameter("PurposeKindOfForAllProhibitionDates",
				Enums.ProhibitionDatesPurposeKinds.ForAllUsers);
			
			Query.SetParameter("User", Users.AuthorizedUser());
			
			If DataChangeOrImportProhibitionFound(
					Query,
					InformAboutProhibition,
					DataId,
					DataTable,
					EmbeddingProperties,
					False,
					Message) Then
					
				FoundProhibitions.Insert("DataChangeProhibitionFound", Message);
			EndIf;
		EndIf;
		
		If ExchangePlanNode <> Undefined Then
			
			Query.SetParameter("PurposeKindOfForAllProhibitionDates",
				Enums.ProhibitionDatesPurposeKinds.ForAllDatabases);
			
			Query.SetParameter("User", ExchangePlanNode);
			
			If DataChangeOrImportProhibitionFound(
					Query,
					InformAboutProhibition,
					DataId,
					DataTable,
					EmbeddingProperties,
					True,
					Message) Then
					
				FoundProhibitions.Insert("DataImportProhibitionFound", Message);
			EndIf;
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return FoundProhibitions.Count() > 0;
	
EndFunction

// Returns ready empty table of values (with Date, Section,
// Object columns) for filling and subsequent transfer to
// the DataChangeProhibitionFound function of ChangeProhibitionDates common module.
//
// Returns:
//  ValueTable - with columns:
//   * Table     - String - full name of the metadata object, for example "Document.SupplierInvoice".
//   * DateField    - String - name of the object attribute or tabular section, for example, "Date", "Goods.ShipmentDate".
//   * Section      - String - name of the predefined item "ChartOfCharacteristicTypesRef.ProhibitionDatesSections".
//   * ObjectField - String - name of the object attribute or tabular section
//                            attribute, for example, "Company", "Goods".Warehouse".
//
Function DataTemplateForChecking() Export
	
	Return ChangeProhibitionDatesServiceReUse.DataTemplateForChecking().Copy();
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Handlers of the subscriptions to events.

// Handler of the BeforeWrite event subscription for change prohibition check.
//
// Parameters:
//  Source   - CatalogObject,
//               ChartOfCharacteristicTypesObject,
//               ChartOfAccountsObject,
//               ChartOfCalculationTypesObject,
//               BusinessProcessObject,
//               TaskObject,
//               ExchangePlanObject - data object passed to the BeforeWrite event subscription.
//
//  Cancel      - Boolean - parameter passed to the BeforeWrite event subscription.
//
Procedure CheckEditProhibitionDateBeforeWrite(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	CheckDataImportChangeProhibitionDates(Source, Cancel);
	
EndProcedure

// Handler of the BeforeWrite event subscription for change prohibition check.
//
// Parameters:
//  Source        - DocumentObject - data object passed to the BeforeWrite event subscription.
//  Cancel           - Boolean - parameter passed to the BeforeWrite event subscription.
//  WriteMode     - Boolean - parameter passed to the BeforeWrite event subscription.
//  PostingMode - Boolean - parameter passed to the BeforeWrite event subscription.
//
Procedure CheckEditProhibitionDateBeforeWriteDocument(Source, Cancel, WriteMode, PostingMode) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	CheckDataImportChangeProhibitionDates(Source, Cancel);
	
EndProcedure

// Handler of the BeforeWrite event subscription for change prohibition check.
//
// Parameters:
//  Source   - InformationRegisterRecordSet, AccumulationRegisterRecordSet - records
//               set passed to the BeforeWrite event subscription.
//  Cancel      - Boolean - parameter passed to the BeforeWrite event subscription.
//  Replacing  - Boolean - parameter passed to the BeforeWrite event subscription.
//
Procedure CheckEditProhibitionDateBeforeWriteRecordSet(Source, Cancel, Replacing) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	CheckDataImportChangeProhibitionDates(Source, Cancel, True, Replacing);
	
EndProcedure

// Handler of the BeforeWrite event subscription for change prohibition check.
//
// Parameters:
//  Source    - AccountingRegisterRecordSet - records set
//                passed to the BeforeWrite event subscription.
//  Cancel       - Boolean - parameter passed to the BeforeWrite event subscription.
//  WriteMode - Boolean - parameter passed to the BeforeWrite event subscription.
//
Procedure CheckEditProhibitionDateBeforeWriteAccountingRegisterRecordSet(
		Source, Cancel, WriteMode) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	CheckDataImportChangeProhibitionDates(Source, Cancel, True);
	
EndProcedure

// Handler of the BeforeWrite event subscription for change prohibition check.
//
// Parameters:
//  Source     - CalculationRegisterRecordSet - records set
//                 passed to the BeforeWrite event subscription.
//  Cancel        - Boolean - parameter passed to the BeforeWrite event subscription.
//  Replacing    - Boolean - parameter passed to the BeforeWrite event subscription.
//  WriteOnly - Boolean - parameter passed to the BeforeWrite event subscription.
//  WriteActualActionPeriod - Boolean - parameter passed to the BeforeWrite event subscription.
//  WriteRecalculations - Boolean - parameter passed to the BeforeWrite event subscription.
//
Procedure CheckDateBeforeProhibitionWriteEditRecordSetRegisterCalculation(
		Source,
		Cancel,
		Replacing,
		WriteOnly,
		WriteActualActionPeriod,
		WriteRecalculations) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	CheckDataImportChangeProhibitionDates(Source, Cancel, True, Replacing);
	
EndProcedure

// The BeforeDelete event subscription handler for change prohibition check.
//
// Parameters:
//  Source   - CatalogObject,
//               DocumentObject,
//               ChartOfCharacteristicTypesObject,
//               ChartChartOfAccountsObject,
//               ChartOfCalculationTypesObject,
//               BusinessProcessObject,
//               TaskObject,
//               ExchangePlanObject - data object passed to the BeforeWrite event subscription.
//
//  Cancel      - Boolean - parameter passed to the BeforeWrite event subscription.
//
Procedure CheckEditProhibitionDateBeforeDelete(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If Source.DeletionMark Then
		Return;
	EndIf;
	
	CheckDataImportChangeProhibitionDates(Source, Cancel, , , True);
	
EndProcedure

// Outdated. It will be deleted in the next edition of the SSL.
// ImportingIsProhibited and ChangingProhibited functions should be used.
//
Procedure VerifyChangeProhibitionDate(Source, Cancel) Export
	
	If ChangingProhibited(Source) Then
		Cancel = True;
	ElsIf ImportingIsProhibited(Source, Undefined) Then
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

Procedure CheckDataImportChangeProhibitionDates(
		Source, Cancel, SourceRegister = False, Replacing = True, Delete = False)
	
	ChangeProhibitionDatesService.CheckDataImportChangeProhibitionDates(
		Source, Cancel, SourceRegister, Replacing, Delete);
	
EndProcedure

Function GetDataForChecking(PreliminaryData)
	
	DataForChecking = DataTemplateForChecking();
	
	TablesDataSources = ChangeProhibitionDatesServiceReUse.DataSourcesForChangeProhibitionCheck();
	
	Filter = New Structure("Table", PreliminaryData.Table);
	DataSources = TablesDataSources.FindRows(Filter);
	
	If DataSources.Count() = 0 Then
		Raise(StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='Data sources for table ""%1"""
"for change prohibition check are not found.';ru='Для проверки запрета"
"изменения не найдены источники данных для таблицы ""%1"".';vi='Để kiểm tra việc cấm"
"thay đổi không tìm thấy nguồn dữ liệu đối với bảng ""%1"".'"),
			Filter.Table));
	EndIf;
	
	MetadataObject = Metadata.FindByFullName(PreliminaryData.Table);
	
	ThisIsRecordSet = CommonUse.ThisIsRegister(MetadataObject);
	MOClass = StringFunctionsClientServer.DecomposeStringIntoSubstringsArray(Filter.Table, ".")[0];
	
	FieldsValues = Undefined;
	
	BeginTransaction();
	Try
		If PreliminaryData.DataId <> Undefined Then
			
			If ThisIsRecordSet Then
				// Filling the fields values from the data base.
				Fields = ChangeProhibitionDatesService.GetRegisterFields(
					DataSources, Filter.Table);
				
				Query = New Query;
				Query.Text =
				"SELECT
				|	&Fields
				|FROM
				|	&Table AS Table
				|WHERE
				|	&FilterCondition";
				InsertParametersAndFilterCondition(Query, PreliminaryData.DataId);
				Query.Text = StrReplace(Query.Text, "&Fields",    Fields);
				Query.Text = StrReplace(Query.Text, "&Table", Filter.Table);
				FieldsValues = Query.Execute().Unload();
				FieldsValues.GroupBy(Fields);
				
			ElsIf ValueIsFilled(PreliminaryData.DataId) Then
				// Filling the fields values from the data base.
				FieldsValues = ChangeProhibitionDatesService.GetObjectFieldsStructure(
					MetadataObject, DataSources, Filter.Table);
				// Field values setting.
				Fields = "";
				For Each Field IN FieldsValues Do
					If MetadataObject.TabularSections.Find(Field.Key) <> Undefined Then
						Fields = Fields + Field.Key + ".(" + Field.Value + "),";
					Else
						Fields = Fields + Field.Key + ",";
					EndIf;
				EndDo;
				Fields = Left(Fields, StrLen(Fields)-1);
				Query = New Query;
				Query.Text =
				"SELECT
				|	&Fields
				|FROM
				|	&Table AS Table
				|WHERE
				|	Table.Ref = &Ref";
				Query.Text = StrReplace(Query.Text, "&Fields",    Fields);
				Query.Text = StrReplace(Query.Text, "&Table", Filter.Table);
				Query.SetParameter("Ref", PreliminaryData.DataId);
				DataFromBase = Query.Execute().Unload();
				For Each Field IN FieldsValues Do
					If MetadataObject.TabularSections.Find(Field.Key) <> Undefined Then
						Fields = Field.Value;
						FieldsValues[Field.Key] = DataFromBase[0][Field.Key].Copy(, Fields);
						FieldsValues[Field.Key].GroupBy(Fields);
					Else
						FieldsValues[Field.Key] = DataFromBase[0][Field.Key];
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		
		If PreliminaryData.FieldValuesFromObject <> Undefined Then
			AddDataForCheck(
				DataForChecking,
				DataSources,
				PreliminaryData.FieldValuesFromObject,
				ThisIsRecordSet,
				MetadataObject);
		EndIf;
		
		If FieldsValues <> Undefined Then
			AddDataForCheck(
				DataForChecking,
				DataSources,
				FieldsValues,
				ThisIsRecordSet,
				MetadataObject);
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return DataForChecking;
	
EndFunction

Procedure AddDataForCheck(Val DataForChecking,
                                    Val DataSources,
                                    Val FieldsValues,
                                    Val ThisIsRecordSet,
                                    Val MetadataObject)
	
	For Each DataSource IN DataSources Do
		If ThisIsRecordSet Then
			For Each String IN FieldsValues Do
				AddDataRow(String, String, DataSource, DataForChecking);
			EndDo;
		Else
			AdditDataSource = New Structure("DataField, Section, ObjectField, Table");
			FillPropertyValues(AdditDataSource, DataSource);
			DataFieldTS = "";
			DotPosition = Find(AdditDataSource.DataField, ".");
			If DotPosition <> 0 Then
				DataFieldTS = Left( AdditDataSource.DataField, DotPosition-1);
				If MetadataObject.TabularSections.Find(DataFieldTS) = Undefined Then
					DataFieldTS = "";
				Else
					AdditDataSource.DataField = Mid(AdditDataSource.DataField, DotPosition+1);
				EndIf;
			EndIf;
			ObjectFieldTS = "";
			ObjectField = "";
			If ValueIsFilled(AdditDataSource.ObjectField) Then
				DotPosition = Find(AdditDataSource.ObjectField, ".");
				If DotPosition <> 0 Then
					ObjectFieldTS = Left( AdditDataSource.ObjectField, DotPosition-1);
					If MetadataObject.TabularSections.Find(ObjectFieldTS) = Undefined Then
						ObjectFieldTS = "";
					Else
						AdditDataSource.ObjectField = Mid(
							AdditDataSource.ObjectField, DotPosition + 1);
					EndIf;
				EndIf;
			EndIf;
			If ValueIsFilled(DataFieldTS) AND ValueIsFilled(ObjectFieldTS) Then
				If DataFieldTS = ObjectFieldTS Then
					For Each String IN FieldsValues[DataFieldTS] Do
						AddDataRow(String, String, AdditDataSource, DataForChecking);
					EndDo;
				Else
					For Each DateRow IN FieldsValues[DataFieldTS] Do
						For Each ObjectString IN FieldsValues[ObjectFieldTS] Do
							AddDataRow(
								DateRow, ObjectString, AdditDataSource, DataForChecking);
						EndDo;
					EndDo;
				EndIf;
			ElsIf ValueIsFilled(DataFieldTS) Then
				For Each String IN FieldsValues[DataFieldTS] Do
					AddDataRow(
						String, FieldsValues, AdditDataSource, DataForChecking);
				EndDo;
			ElsIf ValueIsFilled(ObjectFieldTS) Then
				For Each String IN FieldsValues[ObjectFieldTS] Do
					AddDataRow(FieldsValues, String, AdditDataSource, DataForChecking);
				EndDo;
			Else
				AddDataRow(FieldsValues, FieldsValues, AdditDataSource, DataForChecking);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

Procedure AddDataRow(Val DateRow,
                               Val ObjectString,
                               Val DataSource,
                               Val DataForChecking)
	
	NewRow = DataForChecking.Add();
	SetFieldValue(DateRow, NewRow.Date, DataSource.DataField);
	
	If ValueIsFilled(DataSource.Section) Then
		NewRow.Section = ChartsOfCharacteristicTypes.ChangingProhibitionDatesSections[
			DataSource.Section];
	EndIf;
	
	If ValueIsFilled(DataSource.ObjectField) Then
		SetFieldValue(ObjectString, NewRow.Object, DataSource.ObjectField)
	EndIf;
	
EndProcedure

Procedure SetFieldValue(Val String, DataField, Val SourceField)
	
	DotPosition = Find(SourceField, ".");
	If DotPosition = 0 Then
		DataField = String[SourceField];
	Else
		Value = String[Left(SourceField, DotPosition-1)];
		Attribute = Mid(SourceField, DotPosition+1);
		DataField = AttributeValue(Value, Attribute);
	EndIf;
	
EndProcedure

Function DataChangeOrImportProhibitionFound(Query,
                                               InformAboutProhibition,
                                               DataId,
                                               DataTable,
                                               EmbeddingProperties,
                                               ImportProhibitionsSearch,
                                               Text)
	
	Query.Text =
	"SELECT
	|	DataForChecking.RowKey,
	|	ChangeProhibitionDates.Section,
	|	ChangeProhibitionDates.Object,
	|	DataForChecking.Date,
	|	ChangeProhibitionDates.User,
	|	ChangeProhibitionDates.ProhibitionDate,
	|	CASE
	|		WHEN VALUETYPE(ChangeProhibitionDates.User) = Type(Enum.ProhibitionDatesPurposeKinds)
	|			THEN 0
	|		WHEN VALUETYPE(ChangeProhibitionDates.User) = Type(Catalog.UsersGroups)
	|			THEN 1
	|		WHEN VALUETYPE(ChangeProhibitionDates.User) = Type(Catalog.ExternalUsersGroups)
	|			THEN 1
	|		WHEN ChangeProhibitionDates.User IN (&ExchangePlansNodesEmptyRefs)
	|			THEN 1
	|		ELSE 10
	|	END + CASE
	|		WHEN ChangeProhibitionDates.Object = ChangeProhibitionDates.Section
	|			THEN 0
	|		ELSE 100
	|	END + CASE
	|		WHEN ChangeProhibitionDates.Section = VALUE(ChartOfCharacteristicTypes.ChangingProhibitionDatesSections.EmptyRef)
	|			THEN 0
	|		ELSE 1000
	|	END AS Priority
	|INTO ProhibitionDatesWithoutPriority
	|FROM
	|	DataForChecking AS DataForChecking
	|		INNER JOIN InformationRegister.ChangeProhibitionDates AS ChangeProhibitionDates
	|		ON (ChangeProhibitionDates.Section IN (DataForChecking.Section, VALUE(ChartOfCharacteristicTypes.ChangingProhibitionDatesSections.EmptyRef)))
	|			AND (ChangeProhibitionDates.Object IN (DataForChecking.Object, ChangeProhibitionDates.Section))
	|			AND (CASE
	|				WHEN ChangeProhibitionDates.User = &PurposeKindOfForAllProhibitionDates
	|					THEN TRUE
	|				WHEN ChangeProhibitionDates.User = &User
	|						OR ChangeProhibitionDates.User IN (&ExchangePlansNodesEmptyRefs)
	|							AND VALUETYPE(ChangeProhibitionDates.User) = VALUETYPE(&User)
	|					THEN TRUE
	|				ELSE ChangeProhibitionDates.User In
	|						(SELECT
	|							UsersGroupsContents.UsersGroup
	|						FROM
	|							InformationRegister.UsersGroupsContents AS UsersGroupsContents
	|						WHERE
	|							UsersGroupsContents.User = &User)
	|			END)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataForChecking.Section,
	|	DataForChecking.Object,
	|	DataForChecking.Date,
	|	DataForChecking.RowKey
	|FROM
	|	DataForChecking AS DataForChecking
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ProhibitionDates.RowKey AS RowKey,
	|	ProhibitionDates.Section,
	|	ProhibitionDates.Object,
	|	ProhibitionDates.User,
	|	ProhibitionDates.ProhibitionDate
	|FROM
	|	ProhibitionDatesWithoutPriority AS ProhibitionDates
	|		INNER JOIN (SELECT
	|			ProhibitionDates.RowKey AS RowKey,
	|			ProhibitionDates.Priority AS Priority,
	|			MAX(ProhibitionDates.ProhibitionDate) AS ProhibitionDate
	|		FROM
	|			ProhibitionDatesWithoutPriority AS ProhibitionDates
	|				INNER JOIN (SELECT
	|					ProhibitionDates.RowKey AS RowKey,
	|					MAX(ProhibitionDates.Priority) AS Priority
	|				FROM
	|					ProhibitionDatesWithoutPriority AS ProhibitionDates
	|				
	|				GROUP BY
	|					ProhibitionDates.RowKey) AS MaxPriority
	|				ON ProhibitionDates.RowKey = MaxPriority.RowKey
	|					AND ProhibitionDates.Priority = MaxPriority.Priority
	|		
	|		GROUP BY
	|			ProhibitionDates.RowKey,
	|			ProhibitionDates.Priority) AS PriorityProhibitionDates
	|		ON ProhibitionDates.RowKey = PriorityProhibitionDates.RowKey
	|			AND ProhibitionDates.Priority = PriorityProhibitionDates.Priority
	|			AND ProhibitionDates.ProhibitionDate = PriorityProhibitionDates.ProhibitionDate
	|WHERE
	|	ProhibitionDates.ProhibitionDate >= ProhibitionDates.Date
	|
	|ORDER BY
	|	RowKey
	|TOTALS BY
	|	RowKey
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP ProhibitionDatesWithoutPriority";
	
	ResultsOfQuery = Query.ExecuteBatch();
	
	DataProhibitions = ResultsOfQuery[2].Unload(QueryResultIteration.ByGroups);
	
	If DataProhibitions.Rows.Count() > 0 Then
		
		Checks = ResultsOfQuery[1].Unload();
		Text = GetDataPresentation(DataId, DataTable);
		If ValueIsFilled(Text) Then
			If ImportProhibitionsSearch Then
				Text = Text
					+ NStr("en=' load in prohibited period is not allowed';ru=' запрещено загружать в запрещенный период.';vi=' cấm kết nhập vào kỳ bị cấm.'")
					+ Chars.LF
					+ Chars.LF;
			Else
				Text = Text
					+ NStr("en=' changing or moving in prohibited period is not allowed';ru=' запрещено изменять или перемещать в запрещенный период.';vi=' cấm thay đổi hoặc chuyển vào kỳ bị cấm.'")
					+ Chars.LF
					+ Chars.LF;
			EndIf;
		EndIf;
		
		For Each ProhibitionsDescription IN DataProhibitions.Rows Do
			Prohibitions  = ProhibitionsDescription.Rows;
			Checking = Checks.Find(ProhibitionsDescription.RowKey, "RowKey");
			If Checking.Section = Checking.Object Then
				If Checking.Section = ChartsOfCharacteristicTypes.ChangingProhibitionDatesSections.EmptyRef() Then
					Text = Text + NStr("en='Date %1';ru='Дате %1';vi='Ngày %1'");
				Else
					Text = Text + NStr("en='Date %1 by the ""%2"" section';ru='Дате %1 по разделу ""%2""';vi='Ngày %1 theo phần hành ""%2""'");
				EndIf;
			ElsIf EmbeddingProperties.SingleSection Then
				Text = Text + NStr("en='Date %1 by the ""%3"" object';ru='Дате %1 по объекту ""%3""';vi='Ngày %1 theo đối tượng ""%3""'");
			Else
				Text = Text + NStr("en='Date %1 by the ""%3"" object of the ""%2"" section';ru='Дате %1 по объекту ""%3"" раздела ""%2""';vi='Ngày %1 theo đối tượng ""%3"" phần hành ""%2""'");
			EndIf;
			Text = Text + " ";
			If Prohibitions.Count() = 1 Then
				Text = Text + NStr("en='match data change prevention';ru='соответствует запрет изменения данных';vi='không có cấm thay đổi dữ liệu'") + " ";
			Else
				Text = Text + NStr("en='match data change preventions:';ru='соответствуют запреты изменения данных:';vi='tương ứng cấm thay đổi dữ liệu:'") + Chars.LF;
			EndIf;
			For Each Prohibition IN Prohibitions Do
				Text = Text + ?(Prohibitions.Count() = 1, "", Chars.LF + "- ");
				If Prohibition.User = Enums.ProhibitionDatesPurposeKinds.ForAllUsers Then
					Text = Text + NStr("en='for all users';ru='для всех пользователей';vi='đối với tất cả người sử dụng'");
					
				ElsIf Prohibition.User = Enums.ProhibitionDatesPurposeKinds.ForAllDatabases Then
					Text = Text + NStr("en='for all infobases';ru='для всех информационных баз';vi='đối với tất cả cơ sở thông tin'");
					
				ElsIf TypeOf(Prohibition.User) = Type("CatalogRef.UsersGroups")
				      OR TypeOf(Prohibition.User) = Type("CatalogRef.ExternalUsersGroups") Then
					Text = Text + NStr("en='for the ""%4"" user group';ru='для группы пользователей ""%4""';vi='đối với nhóm người sử dụng ""%4""'");
					
				ElsIf TypeOf(Prohibition.User) = Type("CatalogRef.Users")
				      OR TypeOf(Prohibition.User) = Type("CatalogRef.ExternalUsers") Then
					Text = Text + NStr("en='for the ""%4"" user';ru='для пользователя ""%4""';vi='đối với người sử dụng ""%4""'");
					
				ElsIf ValueIsFilled(Prohibition.User) Then
					Text = Text + NStr("en='for the ""%4"" infobase';ru='для информационной базы ""%4""';vi='đối với cơ sở thông tin ""%4""'");
				Else
					Text = Text + NStr("en='for all infobases ""%6""';ru='для всех информационных баз ""%6""';vi='đối với tất cả cơ sở thông tin ""%6""'");
				EndIf;
				Text = Text + " " + NStr("en='by %5';ru='по %5';vi='đến %5'");
				If Not EmbeddingProperties.WithoutSectionsAndObjects Then
					If ValueIsFilled(Prohibition.Section) Then
						If Prohibition.Object = Prohibition.Section Then
							Text = Text + " " + NStr("en='(section ""%2"" is prohibited)';ru='(запрет установлен на раздел ""%2"")';vi='(cấm thiết lập đối với phần ""%2"")'");
						ElsIf EmbeddingProperties.SingleSection Then
							Text = Text + " " + NStr("en='(object ""%3""  is prohibited)';ru='(запрет установлен на объект ""%3"")';vi='(cấm thiết lập đối với đối tượng ""%3"")'");
						Else
							Text = Text + " " + NStr("en='(object ""%3"" of section ""%2"" is prohibited)';ru='(запрет установлен на объект ""%3"" раздела ""%2"")';vi='(cấm thiết lập đối với đối tượng ""%3"" của phần ""%2"")'");
						EndIf;
					Else
						Text = Text + " " + NStr("en='(common closing date is set)';ru='(установлена общая дата запрета)';vi='(thiết lập ngày cấm chung)'");
					EndIf;
				EndIf;
				Text = StringFunctionsClientServer.SubstituteParametersInString(
						Text,
						Format(Checking.Date, "DLF=D"),
						Checking.Section,
						Checking.Object,
						Prohibition.User,
						Format(Prohibition.ProhibitionDate, "DLF=D"),
						Prohibition.User.Metadata().Presentation()) + Chars.LF;
			EndDo;
			Text = Text + Chars.LF;
		EndDo;
		
		If InformAboutProhibition Then
			CommonUseClientServer.MessageToUser(Text);
			WriteLogEvent(
				?(ImportProhibitionsSearch,
				  NStr("en='Change closing date.Import prohibitions are found';ru='Даты запрета изменения.Найдены запреты загрузки';vi='Ngày cấm thay đổi.Tìm thấy cấm kết nhập'",
				       CommonUseClientServer.MainLanguageCode()),
				  NStr("en='Change closing date.Change prohibitions are found';ru='Даты запрета изменения.Найдены запреты изменения';vi='Ngày cấm thay đổi. Tìm thấy cấm thay đổi'",
				       CommonUseClientServer.MainLanguageCode())),
				EventLogLevel.Error,
				,
				,
				Text,
				EventLogEntryTransactionMode.Transactional);
		EndIf;
	EndIf;
	
	Return DataProhibitions.Rows.Count() > 0;
	
EndFunction

Function AttributeValue(Ref, AttributeName)
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	IsNULL(" + AttributeName + ", Undefined) AS
		|AttributeValue FROM
		|	" + Ref.Metadata().FullName() + " AS
		|Table
		|	WHERE Table.Link = & Link";
	Query.SetParameter("Ref", Ref);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Return Selection.AttributeValue;
	
EndFunction

Function GetDataPresentation(DataId, DataTable)
	
	DataPresentation = "";
	MetadataObject = Metadata.FindByFullName(DataTable);
	
	If Metadata.InformationRegisters.Contains(MetadataObject) Then
		DataPresentation = NStr("en='Records of the ""%1"" information register';ru='Записи регистра сведений ""%1""';vi='Bản ghi biểu ghi thông tin ""%1""'");
		
	ElsIf Metadata.AccumulationRegisters.Contains(MetadataObject) Then
		DataPresentation = NStr("en='Records of the ""%1"" accumulation register';ru='Записи регистра накопления ""%1""';vi='Bản ghi của biểu ghi tích lũy ""%1""'");
		
	ElsIf Metadata.AccountingRegisters.Contains(MetadataObject) Then
		DataPresentation = NStr("en='Records of the ""%1"" accounting register';ru='Записи регистра бухгалтерии ""%1""';vi='Bản ghi của biểu ghi kế toán ""%1""'");
		
	ElsIf Metadata.CalculationRegisters.Contains(MetadataObject) Then
		DataPresentation = NStr("en='Records of the ""%1"" calculation register';ru='Записи регистра расчета ""%1""';vi='Bản ghi của biểu ghi tính toán ""%1""'");
		
	EndIf;
	
	If ValueIsFilled(DataPresentation) Then
		
		FieldsCount = 0;
		For Each FilterItem IN DataId Do
			FieldsCount = FieldsCount + 1;
		EndDo;
		
		If FieldsCount = 1 Then
			DataPresentation = DataPresentation
				+ " " + NStr("en='with field';ru='с полем';vi='với trường'")  + " " + String(DataId);
			
		ElsIf FieldsCount > 1 Then
			DataPresentation = DataPresentation
				+ " " + NStr("en='with fields';ru='с полями';vi='với trường'") + " " + String(DataId);
		EndIf;
	Else
		If Metadata.Catalogs.Contains(MetadataObject) Then
			DataPresentation = NStr("en='The ""%1"" catalog item';ru='Элемент справочника ""%1""';vi='Phần tử danh mục ""%1""'");
		
		ElsIf Metadata.Documents.Contains(MetadataObject) Then
			DataPresentation = NStr("en='Document';ru='документ';vi='chứng từ'");
		
		ElsIf Metadata.ChartsOfCharacteristicTypes.Contains(MetadataObject) Then
			DataPresentation = NStr("en='The ""%1"" chart of characteristic types';ru='План видов характеристик ""%1""';vi='Hệ thống dạng đặc tính ""%1""'");
			
		ElsIf Metadata.ChartsOfAccounts.Contains(MetadataObject) Then
			DataPresentation = NStr("en='The ""%1"" chart of accounts';ru='План счетов ""%1""';vi='Hệ thống tài khoản ""%1""'");
			
		ElsIf Metadata.ChartsOfCalculationTypes.Contains(MetadataObject) Then
			DataPresentation = NStr("en='The ""%1"" chart of calculation types';ru='План видов расчета ""%1""';vi='Hệ thống dạng tính toán ""%1""'");
			
		ElsIf Metadata.BusinessProcesses.Contains(MetadataObject) Then
			DataPresentation = NStr("en='Business process';ru='Бизнес-процесс';vi='Quy trình nghiệp vụ'");
			
		ElsIf Metadata.Tasks.Contains(MetadataObject) Then
			DataPresentation = NStr("en='Task';ru='Задача';vi='Nhiệm vụ'");
			
		ElsIf Metadata.ExchangePlans.Contains(MetadataObject) Then
			DataPresentation = NStr("en='The ""%1"" exchange plan';ru='План обмена ""%1""';vi='Sơ đồ trao đổi ""%1""'");
		EndIf;
		
		If ValueIsFilled(DataPresentation) AND ValueIsFilled(DataId) Then
			DataPresentation = DataPresentation + " " + String(DataId);
		Else
			DataPresentation = "";
		EndIf;
	EndIf;
	
	DataPresentation = StringFunctionsClientServer.SubstituteParametersInString(
		DataPresentation, MetadataObject.Synonym);
	
	Return DataPresentation;
	
EndFunction

// Function converts a Filter into condition on queries language and inserts in a query.
//
// Parameters:
//  Query             - Query.
//
//  Filter              - InformationRegisterRecordSet.Filter,
//                       AccumulationRegisterRecordSet.Filter,
//                       AccountingRegisterRecordSet.Filter,
//                       CalculationRegisterRecordSet.Filter.
//
//  TablePseudonym   - String - register alias in a query.
//
//  FilterConditionPlace - String - Identifier of condition
//                       location in the query, for example &SearchCondition.
//
// Returns:
//  Row.
//
Procedure InsertParametersAndFilterCondition(Query,
                                          Filter,
                                          TablePseudonym = "Table",
                                          FilterConditionPlace = "&FilterCondition")
	
	Condition = "";
	For Each FilterItem IN Filter Do
		
		If FilterItem.Use Then
			If Not IsBlankString(Condition) Then
				Condition = Condition + Chars.LF + "AND ";
			EndIf;
			Query.SetParameter(FilterItem.Name, FilterItem.Value);
			Condition = Condition
				+ TablePseudonym + "." + FilterItem.Name + " = &" + FilterItem.Name;
		EndIf;
	EndDo;
	Condition = ?(ValueIsFilled(Condition), Condition, "True");
	Query.Text = StrReplace(Query.Text, FilterConditionPlace, Condition);
	
EndProcedure

#EndRegion
