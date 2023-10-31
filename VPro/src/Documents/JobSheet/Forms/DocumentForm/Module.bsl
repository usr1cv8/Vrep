
////////////////////////////////////////////////////////////////////////////////
// GENERAL PURPOSE PROCEDURES AND FUNCTIONS

&AtServerNoContext
// It receives data set from server for the DateOnChange procedure.
//
Function GetDataDateOnChange(DocumentRef, DateNew, DateBeforeChange)
	
	StructureData = New Structure();
	StructureData.Insert("DATEDIFF", SmallBusinessServer.CheckDocumentNumber(DocumentRef, DateNew, DateBeforeChange));
	
	Return StructureData;
	
EndFunction // GetDataDateOnChange()

&AtServerNoContext
// Gets data set from server.
//
Function GetCompanyDataOnChange(Company)
	
	StructureData = New Structure();
	StructureData.Insert("Counterparty", SmallBusinessServer.GetCompany(Company));
	
	Return StructureData;
	
EndFunction // GetCompanyDataOnChange()

&AtServerNoContext
// Receives the set of data from the server for the ProductsAndServicesOnChange procedure.
//
Function GetDataProductsAndServicesOnChange(StructureData)
	
	If StructureData.Property("Characteristic") Then
		StructureData.Insert("Specification", SmallBusinessServer.GetDefaultSpecification(StructureData.ProductsAndServices, StructureData.Characteristic));
	Else
		StructureData.Insert("Specification", SmallBusinessServer.GetDefaultSpecification(StructureData.ProductsAndServices));
	EndIf;
	
	Return StructureData;
	
EndFunction // ReceiveDataProductsAndServicesOnChange()

&AtServerNoContext
// Receives employee ID with the server.
//
Function GetTabNumber(Performer)
	
	Return Performer.Code;
	
EndFunction // GetCompanyDataOnChange()

&AtServer
// Procedure fills team members.
//
Procedure FillTeamMembersAtServer()

	Document = FormAttributeToValue("Object");
	Document.FillTeamMembers();
	ValueToFormAttribute(Document, "Object");
	Modified = True;	

EndProcedure

&AtServerNoContext
// It receives data set from server to operation.
//
Function GetOperationData(StructureData)
	
	StructureData.Insert("TimeNorm", StructureData.ProductsAndServices.TimeNorm);
	StructureData.Insert("MeasurementUnit", StructureData.ProductsAndServices.MeasurementUnit);
	StructureData.Insert("PriceKind", Catalogs.PriceKinds.Accounting);
	StructureData.Insert("Characteristic", Catalogs.ProductsAndServicesCharacteristics.EmptyRef());
	StructureData.Insert("Factor", 1);
	StructureData.Insert("AmountIncludesVAT", Catalogs.PriceKinds.Accounting.PriceIncludesVAT);
	
	StructureData.Insert("Price", SmallBusinessServer.GetProductsAndServicesPriceByPriceKind(StructureData));
	
	Return StructureData;
	
EndFunction // ReceiveDataProductsAndServicesOnChange()

&AtServerNoContext
// Gets the data set from the server for procedure MeasurementUnitOnChange.
//
Function GetDataMeasurementUnitOnChange(CurrentMeasurementUnit = Undefined, MeasurementUnit = Undefined)
	
	StructureData = New Structure;
	
	If CurrentMeasurementUnit = Undefined Then
		StructureData.Insert("CurrentFactor", 1);
	Else
		StructureData.Insert("CurrentFactor", CurrentMeasurementUnit.Factor);
	EndIf;
	
	If MeasurementUnit = Undefined Then
		StructureData.Insert("Factor", 1);
	Else
		StructureData.Insert("Factor", MeasurementUnit.Factor);
	EndIf;
	
	Return StructureData;
	
EndFunction // GetDataMeasurementUnitOnChange()

&AtClient
// Procedure calculates the operation duration.
//
// Parameters:
//  No.
//
Procedure CalculateDuration()

	CurrentRow = Items.Operations.CurrentData;
	CurrentRow.StandardHours = CurrentRow.TimeNorm * CurrentRow.QuantityFact;	
	
EndProcedure

&AtClient
// Procedure calculates operation performing cost.
//
// Parameters:
//  No.
//
Procedure CalculateCost()

	CurrentRow = Items.Operations.CurrentData;
	CurrentRow.Cost = CurrentRow.Tariff * CurrentRow.QuantityFact;
		
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// PROCEDURES AND FUNCTIONS FOR CONTROL OF THE FORM APPEARANCE

&AtServer
// Procedure sets availability of form items according to the type of server.
//
// Parameters:
//  No.
//
Procedure SetVisibleAndEnabledFromExecutor()
	
	If TypeOf(Object.Performer) = Type("CatalogRef.Teams") Then
		
		Items.GroupTeamMembers.Visible = True;
		Items.FillTeamMembers.Visible = True;
		Items.TabNumber.Visible = False;
		
	Else
		
		Items.GroupTeamMembers.Visible = False;
		Items.FillTeamMembers.Visible = False;
		Items.TabNumber.Visible = True;
		
		Object.TeamMembers.Clear();
		
	EndIf;
	
EndProcedure // SetVisibleAndEnabled()

////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - FORM EVENT HANDLERS

&AtServer
// Procedure - OnCreateAtServer event handler.
//
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SmallBusinessServer.FillDocumentHeader(Object,
	,
	Parameters.CopyingValue,
	Parameters.Basis,
	PostingIsAllowed);
	
	If Not ValueIsFilled(Object.Ref)
		AND Not ValueIsFilled(Parameters.Basis)
		AND Not ValueIsFilled(Parameters.CopyingValue) Then
		Object.DocumentCurrency = Constants.AccountingCurrency.Get();
	EndIf;
	
	If Object.Ref.IsEmpty() Then
		FillFormParameters();
	EndIf;
	
	SetConditionalAppearance();
	TabularSectionName = "Operations";
	
	// Form attributes setting.
	DocumentDate = Object.Date;
	If Not ValueIsFilled(DocumentDate) Then
		DocumentDate = CurrentDate();
	EndIf;
	
	SubsidiaryCompany = SmallBusinessServer.GetCompany(Object.Company);
	
	If TypeOf(Object.Performer) = Type("CatalogRef.Employees") Then
		TabNumber = Object.Performer.Code;
	Else
		TabNumber = "";
	EndIf;
	
	SetVisibleAndEnabledFromExecutor();
	Items.ClosingDate.AutoMarkIncomplete = Object.Closed;
	
	If Not Constants.FunctionalOptionUseJobSharing.Get() Then
		If Items.Find("TeamMembersEmployeeCode") <> Undefined Then
			Items.TeamMembersEmployeeCode.Visible = False;
		EndIf;
	EndIf;
	
	If ValueIsFilled(Object.Ref) Then
		NotifyWorkCalendar = False;	
	Else
		NotifyWorkCalendar = True;
	EndIf; 
	DocumentModified = False;
		
	If Parameters.Key.IsEmpty() Then
		FillStagesUsingAttributes();
	EndIf;
	
	SmallBusinessClientServer.SetPictureForComment(Items.GroupAdditional, Object.Comment);
	
	Items.BasisDocumentLabel.Title = WorkWithDocumentFormClientServer.FormLetteringBasisDocument(Object.BasisDocument);
	FillBasisDocumentsList();

	
	UpdateDataCacheServer();
	FillServiceDataTS(ЭтотОбъект);

	// Setting the visibility of details from user settings
	SetVisibleFromUserSettings(ЭтотОбъект); 
	
	// StandardSubsystems.ObjectVersioning
	ObjectVersioning.OnCreateAtServer(ThisForm);
	// End StandardSubsystems.ObjectVersioning
	
	// StandardSubsystems.AdditionalReportsAndDataProcessors
	AdditionalReportsAndDataProcessors.OnCreateAtServer(ThisForm);
	// End StandardSubsystems.AdditionalReportsAndDataProcessors
	
	// StandardSubsystems.Printing
	PrintManagement.OnCreateAtServer(ThisForm, Items.ImportantCommandsGroup);
	// End StandardSubsystems.Printing
	
EndProcedure // OnCreateAtServer()

// Procedure - OnReadAtServer event handler.
//
&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	FillFormParameters();
	
	ChangeProhibitionDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	FillStagesUsingAttributes();

EndProcedure // OnReadAtServer()

&AtClient
// Procedure - event handler AfterWriting.
//
Procedure AfterWrite(WriteParameters)
	
	If DocumentModified Then
		NotifyWorkCalendar = True;
		DocumentModified = False;
	EndIf;
	
	FillServiceDataTS(ThisObject);
	
EndProcedure // AfterWrite()

&AtServer
// Procedure-handler of the BeforeWriteAtServer event.
// Performs initial attributes forms filling.
//
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Modified Then
		DocumentModified = True;
	EndIf;
	
EndProcedure // BeforeWriteAtServer()

///////////////////////////////////////////////////////////////////////////////
// PROCEDURE - EVENT HANDLERS OF HEADER ATTRIBUTES

&AtClient
// Procedure - event handler OnChange of the Date input field.
// The procedure determines the situation when after changing the date
// of a document this document is found in another period
// of documents enumeration, and in this case the procedure assigns new unique number to the document.
// Overrides the corresponding form parameter.
//
Procedure DateOnChange(Item)
	
	// Date change event DataProcessor.
	DateBeforeChange = DocumentDate;
	DocumentDate = Object.Date;
	If Object.Date <> DateBeforeChange Then
		StructureData = GetDataDateOnChange(Object.Ref, Object.Date, DateBeforeChange);
		If StructureData.DATEDIFF <> 0 Then
			Object.Number = "";
		EndIf;
	EndIf;
	
EndProcedure // DateOnChange()

&AtClient
// Procedure - event handler OnChange of the Company input field.
// IN procedure the document number
// is cleared, and also the form functional options are configured.
// Overrides the corresponding form parameter.
//
Procedure CompanyOnChange(Item)

	// Company change event data processor.
	Object.Number = "";
	StructureData = GetCompanyDataOnChange(Object.Company);
	Counterparty = StructureData.Counterparty;
	
EndProcedure // CompanyOnChange()

&AtClient
// Procedure - event handler OnChange input field Performer.
//
Procedure AssigneeOnChange(Item)
	
	SetVisibleAndEnabledFromExecutor();
	SetVisibleFromUserSettings(ThisObject);
	Object.TeamMembers.Clear();
	
	If TypeOf(Object.Performer) = Type("CatalogRef.Employees") Then
		TabNumber = GetTabNumber(Object.Performer);
	Else
		TabNumber = "";
	EndIf;
	
	If ValueIsFilled(Object.Performer) And TypeOf(Object.Performer)=Type("СправочникСсылка.Teams") Then
		FillTeamContentOnServer(Object.Performer);
	ElsIf ValueIsFilled(Object.Performer) And TypeOf(Object.Performer)=Type("СправочникСсылка.Employees") Then
		UpdateDataCaches();
		Var_TabNumber = TabNumberCash.Get(Object.Performer);
		Department = DepartmentCash.Get(Object.Performer);
		If Not FormParameters.AccountingBySeveralDepartments Then
			Object.StructuralUnit = PredefinedValue("Справочник.StructuralUnits.MainDepartment");
		ElsIf Object.StructuralUnitPosition=PredefinedValue("Enum.AttributePositionOnForm.InHeader") Then
			Object.StructuralUnit = Department;
		ElsIf Object.StructuralUnitPosition=PredefinedValue("Enum.AttributePositionOnForm.InTabularSection") Then
			For Each TabSecRow In Object.Operations Do
				TabSecRow.StructuralUnit = Department;
			EndDo; 
			For Each TabSecRow In Object.TeamMembers Do
				TabSecRow.StructuralUnit = Department;
			EndDo; 
		EndIf;
	EndIf; 
	
EndProcedure

&AtClient
// Procedure - event handler OnChange of attribute ItIsClosed.
//
Procedure ClosedOnChange(Item)
	
	If Not ValueIsFilled(Object.ClosingDate) AND Object.Closed Then
		Object.ClosingDate = CurrentDate();	
	EndIf;
	
	If Object.Closed Then
		Items.ClosingDate.AutoMarkIncomplete = True;
	Else	
		Items.ClosingDate.AutoMarkIncomplete = False;
		ClearMarkIncomplete();
	EndIf;
	
EndProcedure

&AtClient
// Procedure - event handler OnChange of attribute CloseDate.
//
Procedure ClosingDateOnChange(Item)
	
	If ValueIsFilled(Object.ClosingDate) Then
		Object.Closed = True;	
	EndIf; 
	
EndProcedure

// Procedure - OnChange event handler of the Comment input field.
//
&AtClient
Procedure CommentOnChange(Item)
	
	AttachIdleHandler("Attachable_SetPictureForComment", 0.5, True);
	
EndProcedure // CommentOnChange()

&AtClient
Procedure Attachable_SetPictureForComment()
	
	SmallBusinessClientServer.SetPictureForComment(Items.GroupAdditional, Object.Comment);
	
EndProcedure
////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - TABLE PARTS ATTRIBUTE EVENT HANDLERS

&AtClient
// Procedure - event handler OnChange of attribute Period of tabular section Operations.
//
Procedure OperationsPeriodOnChange(Item)
	
	CurrentRow = Items.Operations.CurrentData;
	StructureData = New Structure();
	StructureData.Insert("ProcessingDate", 	CurrentRow.Period);
	StructureData.Insert("ProductsAndServices", 	CurrentRow.Operation);
	StructureData.Insert("DocumentCurrency", Object.DocumentCurrency);	
	CurrentRow.Tariff = GetOperationData(StructureData).Price;
	
	CalculateCost();
	
EndProcedure

&AtClient
// Procedure - event handler OnChange of attribute Operation of tabular section Operations.
//
Procedure OperationsOperationOnChange(Item)
	
	CurrentRow = Items.Operations.CurrentData;
	StructureData = New Structure();
	StructureData.Insert("ProcessingDate", 	CurrentRow.Period);
	StructureData.Insert("ProductsAndServices", 	CurrentRow.Operation);
	StructureData.Insert("DocumentCurrency", Object.DocumentCurrency);
	ResultStructure 				= GetOperationData(StructureData);
	CurrentRow.Tariff 			= ResultStructure.Price;
	CurrentRow.MeasurementUnit 	= ResultStructure.MeasurementUnit;
	CurrentRow.TimeNorm 		= ResultStructure.TimeNorm;
	
	CalculateDuration();
	CalculateCost();
	
EndProcedure // InventoryProductsAndServicesOnChange()

&AtClient
// Procedure - event handler OnChange of the ProductsAndServices input field.
//
Procedure OperationsProductsAndServicesOnChange(Item)
	
	TabularSectionRow = Items.Operations.CurrentData;
	
	StructureData = New Structure();
	StructureData.Insert("ProductsAndServices", TabularSectionRow.ProductsAndServices);
	
	StructureData = GetDataProductsAndServicesOnChange(StructureData);
	
	TabularSectionRow.Specification = StructureData.Specification;
	
EndProcedure // OperationsProductsAndServicesOnChange()

// Procedure - event handler OnChange of the Characteristic input field.
//
&AtClient
Procedure OperationCharacteristicChange(Item)
	
	TabularSectionRow = Items.Operations.CurrentData;
	
	StructureData = New Structure;
	StructureData.Insert("ProductsAndServices", TabularSectionRow.ProductsAndServices);
	StructureData.Insert("Characteristic", TabularSectionRow.Characteristic);
	
	StructureData = GetDataProductsAndServicesOnChange(StructureData);
	
	TabularSectionRow.Specification = StructureData.Specification;
	
EndProcedure // OperationCharacteristicChange()

&AtClient
// Procedure - handler of the OnChange event of the Quantity attribute of the Operation tabular section.
//
Procedure OperationsQuantityOnChange(Item)
	
	CalculateDuration();
	CalculateCost();
	
EndProcedure

&AtClient
// Procedure - handler of the OnChange event of the StandartHours attribute of the Operation tabular section.
//
Procedure OperationsTimeNormOnChange(Item)
	
	CalculateDuration();
	CalculateCost();
	
EndProcedure

&AtClient
// Procedure - handler of the OnChange event of the StandardHours attribute of the Operations tabular section.
//
Procedure OperationsStandardHoursOnChange(Item)
	
	CalculateCost();
	
EndProcedure // OperationsStandardHoursOnChange()

&AtClient
// Procedure - OnChange event handler of Tariff attribute of Operations tabular section.
//
Procedure OperationsTariffOnChange(Item)
	
	CalculateCost();
	
EndProcedure

&AtClient
// Procedure - event handler ChoiceProcessing of the MeasurementUnit input field.
//
Procedure OperationsMeasurementUnitChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	TabularSectionRow = Items.Operations.CurrentData;
	
	If TabularSectionRow.MeasurementUnit = ValueSelected 
	 OR TabularSectionRow.Tariff = 0 Then
		Return;
	EndIf;
	
	CurrentFactor = 0;
	If TypeOf(TabularSectionRow.MeasurementUnit) = Type("CatalogRef.UOMClassifier") Then
		CurrentFactor = 1;
	EndIf;
	
	Factor = 0;
	If TypeOf(ValueSelected) = Type("CatalogRef.UOMClassifier") Then
		Factor = 1;
	EndIf;
	
	If CurrentFactor = 0 AND Factor = 0 Then
		StructureData = GetDataMeasurementUnitOnChange(TabularSectionRow.MeasurementUnit, ValueSelected);
	ElsIf CurrentFactor = 0 Then
		StructureData = GetDataMeasurementUnitOnChange(TabularSectionRow.MeasurementUnit);
	ElsIf Factor = 0 Then
		StructureData = GetDataMeasurementUnitOnChange(,ValueSelected);
	ElsIf CurrentFactor = 1 AND Factor = 1 Then
		StructureData = New Structure("CurrentFactor, Factor", 1, 1);
	EndIf;
	
	If StructureData.CurrentFactor <> 0 Then
		TabularSectionRow.Tariff = TabularSectionRow.Tariff * StructureData.Factor / StructureData.CurrentFactor;
		TabularSectionRow.TimeNorm = TabularSectionRow.TimeNorm * StructureData.Factor / StructureData.CurrentFactor;
		CalculateDuration();
		CalculateCost();
	EndIf;
	
	CalculateCost();
	
EndProcedure // InventoryMeasurementUnitChoiceProcessing()

&AtClient
// Procedure - handler of the OnChange event of the Employee attribute of the TeamMembers tabular section.
//
Procedure TeamMembersEmployeeOnChange(Item)
	
	Items.TeamMembers.CurrentData.LPF = 1;
	
EndProcedure

&AtClient
// Procedure - command handler FillTeamMembers.
//
Procedure FillTeamMembers(Command)
	
	FillTeamMembersAtServer();
	
EndProcedure

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

&AtClient
Procedure OperationsStageStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure OperationsStageAutoComplete(Item, Text, ChoiceData, DataGetParameters, Wait, StandardProcessing)
	
	StandardProcessing = False;
	
	TabSecRow = Items.Operations.CurrentData;
	If ValueIsFilled(TabSecRow.Specification) Then
		SelectionData = New ValueList;
		SelectionData.LoadValues(ProductionStages(TabSecRow.Specification, TabSecRow.ProductionOrder));
		UpdateEmptyStageDescriptiion(SelectionData); 
	EndIf;

EndProcedure

&AtServerNoContext
Function ProductionStages(Specifications, ProductionOrder)
	
	If ValueIsFilled(ProductionOrder) 
		And CommonUse.ObjectAttributeValue(ProductionOrder, "OperationKind") = Enums.OperationKindsProductionOrder.Disassembly Then
		Return New Array;
	EndIf; 
	
	Return ProductionServer.ProductionStagesOfSpecifications(Specifications);
	
EndFunction

&AtClientAtServerNoContext
Procedure UpdateEmptyStageDescriptiion(List)
	
	If List.Count()>0 And Not ValueIsFilled(List[0].Value) Then
		List[0].Description = NStr("En='<No stage>';ru='<Без этапов>';vi='<Không có công đoạn>'");
	EndIf; 
	
EndProcedure

&AtClient
Procedure DocumentSetting(Command)
	
	// 1. Form parameter structure to fill "Document setting" form.
	ParametersStructure = New Structure;
	ParametersStructure.Insert("PerformerPositionJobSheet", Object.PerformerPosition);
	ParametersStructure.Insert("ProductionOrderPositionJobSheet", Object.ProductionOrderPosition);
	ParametersStructure.Insert("StructuralUnitPositionJobSheet", Object.StructuralUnitPosition);
	
	ParametersStructure.Insert("WereMadeChanges", 								False);
	
	StructureDocumentSetting = Undefined;
	
	OpenForm("CommonForm.DocumentSetting", ParametersStructure,,,,, New NotifyDescription("DocumentSettingEnd", ThisObject));
	
EndProcedure

&AtClient
Procedure DocumentSettingEnd(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Structure") AND Result.WereMadeChanges Then
		
		DocumentSettingEndServer(Result);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DocumentSettingEndServer(Result)
	
	If Object.PerformerPosition<>Result.PerformerPositionJobSheet Then
		
		For Each TabSecRow In Object.Operations Do
			TabSecRow.Performer = Object.Performer;
		EndDo;
		
		If Result.PerformerPositionJobSheet = Enums.AttributePositionOnForm.InTabularSection Then
			If TypeOf(Object.Performer)=Type("CatalogRef.Teams") Then
				FilterStructure = New Structure;
				FilterStructure.Insert("ConnectionKey", 0);
				ContentRows = Object.TeamMembers.FindRows(FilterStructure);
				For Each RowOperations In Object.Operations Do
					If RowOperations.ConnectionKey=0 Then
						TabularSectionName = "Operations";
						RowOperations.ConnectionKey = SmallBusinessServer.NewConnectionKey(ThisObject);
					EndIf; 
					For Each ContentRow In ContentRows Do
						NewRow = Object.TeamMembers.Add();
						FillPropertyValues(NewRow, ContentRow);
						NewRow.ConnectionKey = RowOperations.ConnectionKey;
					EndDo; 
				EndDo; 
				For Each ContentRow In ContentRows Do
					Object.TeamMembers.Delete(ContentRow);
				EndDo; 
			EndIf; 
			Object.Performer = Undefined;
		Else
			Object.TeamMembers.Clear();
		EndIf; 
		Object.PerformerPosition = Result.PerformerPositionJobSheet;
		
	EndIf; 
	
	If Object.StructuralUnitPosition<>Result.StructuralUnitPositionJobSheet Then
		If Result.StructuralUnitPositionJobSheet = Enums.AttributePositionOnForm.InHeader Then
			Object.StructuralUnit = SmallBusinessReUse.GetValueOfSetting("MainDepartment");
			For Each TabSecRow In Object.Operations Do
				TabSecRow.StructuralUnit = Object.StructuralUnit;
			EndDo; 
			For Each TabSecRow In Object.TeamMembers Do
				TabSecRow.StructuralUnit = Object.StructuralUnit;
			EndDo; 
		Else
			For Each TabSecRow In Object.Operations Do
				TabSecRow.StructuralUnit = Object.StructuralUnit;
			EndDo; 
			For Each TabSecRow In Object.TeamMembers Do
				TabSecRow.StructuralUnit = Object.StructuralUnit;
			EndDo; 
			Object.StructuralUnit = Catalogs.StructuralUnits.EmptyRef();
		EndIf; 
		Object.StructuralUnitPosition = Result.StructuralUnitPositionJobSheet;
	EndIf; 
	
	If Object.ProductionOrderPosition<>Result.ProductionOrderPositionJobSheet Then
		If Result.ProductionOrderPositionJobSheet = Enums.AttributePositionOnForm.InHeader Then
			For Each TabSecRow In Object.Operations Do
				TabSecRow.ProductionOrder = Object.ProductionOrder;
			EndDo;
		Else
			Object.ProductionOrder = Undefined;
		EndIf; 
		Object.ProductionOrderPosition = Result.ProductionOrderPositionJobSheet;
	EndIf;
	
	SetVisibleFromUserSettings(ThisObject);
	FillServiceDataTS(ThisObject);
	
EndProcedure

&НаКлиентеНаСервереБезКонтекста
Procedure SetVisibleFromUserSettings(Form)
	
	Items = Form.Items;
	Object = Form.Object;
	
	If Object.PerformerPosition = PredefinedValue("Enum.AttributePositionOnForm.InTabularSection") Then
		CommonUseClientServer.SetFormItemProperty(Items, "PerformerGroup", "Visible", False);
		CommonUseClientServer.SetFormItemProperty(Items, "PerfomerTNContent", "Visible", True);
		CommonUseClientServer.SetFormItemProperty(Items, "GroupTeamMembers", "Visible", ShowPageTeam(Object));
	Else
		CommonUseClientServer.SetFormItemProperty(Items, "PerformerGroup", "Visible", True);
		CommonUseClientServer.SetFormItemProperty(Items, "PerfomerTNContent", "Visible", False);
		CommonUseClientServer.SetFormItemProperty(Items, "GroupTeamMembers", "Visible", ShowPageTeam(Object));
	EndIf;
	
	If Object.StructuralUnitPosition = PredefinedValue("Enum.AttributePositionOnForm.InTabularSection") Then
		CommonUseClientServer.SetFormItemProperty(Items, "StructuralUnit", "Visible", False);
		CommonUseClientServer.SetFormItemProperty(Items, "OperationsStructuralUnit", "Visible", Not ShowPageTeam(Object));
		CommonUseClientServer.SetFormItemProperty(Items, "TeamMembersStructuralUnit", "Visible", ShowPageTeam(Object));
	Else
		CommonUseClientServer.SetFormItemProperty(Items, "StructuralUnit", "Visible", True);
		CommonUseClientServer.SetFormItemProperty(Items, "OperationsStructuralUnit", "Visible", False);
		CommonUseClientServer.SetFormItemProperty(Items, "TeamMembersStructuralUnit", "Visible", False);
	EndIf;
	
	If Form.Object.ProductionOrderPosition = PredefinedValue("Enum.AttributePositionOnForm.InTabularSection") Then
		CommonUseClientServer.SetFormItemProperty(Items, "ProductionOrder", "Visible", False);
		CommonUseClientServer.SetFormItemProperty(Items, "FillByProductionOrder", "Visible", False);
		CommonUseClientServer.SetFormItemProperty(Items, "OperationsProductionOrder", "Visible", True);
	Else
		CommonUseClientServer.SetFormItemProperty(Items, "ProductionOrder", "Visible", True);
		CommonUseClientServer.SetFormItemProperty(Items, "FillByProductionOrder", "Visible", True);
		CommonUseClientServer.SetFormItemProperty(Items, "OperationsProductionOrder", "Visible", False);
	EndIf;
	
EndProcedure // УстановитьВидимостьОтПользовательскихНастроек()


&НаКлиентеНаСервереБезКонтекста
Procedure FillServiceDataTS(Form, TabSecName = "Operations", TabSecRow = Undefined)
	
	Object = Form.Object;
	If TabSecRow<>Undefined Then
		If TabSecName="Operations" Then
			TabSecRow.PerfomerIsTeam = (TypeOf(TabSecRow.Performer)=Type("CatalogRef.Teams"));
			If Not TabSecRow.PerfomerIsTeam Then
				TabSecRow.TabNumber = Form.TabNumberCash.Get(TabSecRow.Performer);
			Else
				TabSecRow.ChangeContent = NStr("En='Change content and LPF';ru='Изменить состав и КТУ';vi='Thay đổi thành phần LPF'");
			EndIf;
		ElsIf TabSecName="TeamMembers" Then
			TabSecRow.TabNumber = Form.TabNumberCash.Get(TabSecRow.Employee);
		EndIf; 
	ElsIf Object.PerformerPosition=PredefinedValue("Enum.AttributePositionOnForm.InTabularSection") Then
		For Each CurrentRow In Object.Operations Do
			CurrentRow.PerfomerIsTeam = (TypeOf(CurrentRow.Performer)=Type("CatalogRef.Teams"));
			If Not CurrentRow.PerfomerIsTeam Then
				CurrentRow.TabNumber = Form.TabNumberCash.Get(CurrentRow.Performer);
			Else
				CurrentRow.ChangeContent = NStr("En='Change content and LPF';ru='Изменить состав и КТУ';vi='Thay đổi thành phần LPF'");
			EndIf;
		EndDo;
		For Each CurrentRow In Object.TeamMembers Do
			CurrentRow.TabNumber = Form.TabNumberCash.Get(CurrentRow.Employee); 
		EndDo;
	ElsIf Object.PerformerPosition=PredefinedValue("Enum.AttributePositionOnForm.InHeader") Then
		If ShowPageTeam(Object) Then
			For Each CurrentRow In Object.TeamMembers Do
				CurrentRow.TabNumber = Form.TabNumberCash.Get(CurrentRow.Employee); 
			EndDo;
		Else
			Form.TabNumber = Form.TabNumberCash.Get(Object.Performer);
		EndIf;
		For Each CurrentRow In Object.Operations Do
			CurrentRow.PerfomerIsTeam = False;
		EndDo;
	EndIf;
	
	If TabSecName="Operations" Then
		If TabSecRow<>Undefined Then
			TabSecRow.FixedCost = Form.FixedCostCash.Get(TabSecRow.Operation);
		Else
			For Each CurrentRow In Object.Operations Do
				CurrentRow.FixedCost = Form.FixedCostCash.Get(CurrentRow.Operation);
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function ShowPageTeam(Object)
	
	Return ValueIsFilled(Object.Performer) 
		And TypeOf(Object.Performer)=Type("CatalogRef.Teams") 
		And Object.PerformerPosition=PredefinedValue("Enum.AttributePositionOnForm.InHeader");
	
EndFunction 

&AtServer
Procedure UpdateDataCacheServer(StaffArray = Undefined, OperationsArray = Undefined)
	
	If StaffArray=Undefined Then
		StaffArray = New Array;
		If Object.PerformerPosition=PredefinedValue("Enum.AttributePositionOnForm.InTabularSection") Then
			For Each TabSecRow In Object.Operations Do
				If Not ValueIsFilled(TabSecRow.Performer) Or TypeOf(TabSecRow.Performer)<>Type("CatalogRef.Employees") Then
					Continue;
				EndIf; 
				StaffArray.Add(TabSecRow.Performer);
			EndDo;
			For Each TabSecRow In Object.TeamMembers Do
				If Not ValueIsFilled(TabSecRow.Employee) Then
					Continue;
				EndIf; 
				StaffArray.Add(TabSecRow.Employee);
			EndDo;
		ElsIf Object.PerformerPosition=PredefinedValue("Enum.AttributePositionOnForm.InHeader") Then
			If ValueIsFilled(Object.Performer) And TypeOf(Object.Performer)=Type("CatalogRef.Employees") Then
				StaffArray.Add(Object.Performer);
			ElsIf TypeOf(Object.Performer)=Type("СправочникСсылка.Teams") Then
				For Each TabSecRow In Object.TeamMembers Do
					If Not ValueIsFilled(TabSecRow.Employee) Then
						Continue;
					EndIf; 
					StaffArray.Add(TabSecRow.Employee);
				EndDo;
			EndIf; 
		EndIf;
	EndIf;
	
	If OperationsArray=Undefined Then
		OperationsArray = New Array;
		For Each TabSecRow In Object.Operations Do
			If ValueIsFilled(TabSecRow.Operation) Then
				OperationsArray.Add(TabSecRow.Operation);
			EndIf; 
		EndDo; 
	EndIf;
	
	StaffArray = CommonUseClientServer.CollapseArray(StaffArray);
	OperationsArray = CommonUseClientServer.CollapseArray(OperationsArray);
	
	Query = New Query;
	Query.SetParameter("Company", Object.Company);
	Query.SetParameter("StaffArray", StaffArray);
	Query.SetParameter("OperationsArray", OperationsArray);
	Query.SetParameter("SlicePeriod", ?(ValueIsFilled(Object.Date), Object.Date, EndOfDay(CurrentDate())));
	Query.Text =
	"SELECT
	|	Employees.Ref AS Employee,
	|	ISNULL(EmployeesSliceLast.StructuralUnit, VALUE(Catalog.StructuralUnits.EmptyRef)) AS StructuralUnit,
	|	Employees.Code AS TabNumber
	|FROM
	|	Catalog.Employees AS Employees
	|		LEFT JOIN InformationRegister.Employees.SliceLast(&SlicePeriod, Company = &Company) AS EmployeesSliceLast
	|		ON (EmployeesSliceLast.Employee = Employees.Ref)
	|WHERE
	|	Employees.Ref IN(&StaffArray)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductsAndServices.Ref AS Operation,
	|	ProductsAndServices.FixedCost AS FixedCost
	|FROM
	|	Catalog.ProductsAndServices AS ProductsAndServices
	|WHERE
	|	ProductsAndServices.Ref IN(&OperationsArray)";
	Result = Query.ExecuteBatch();
	
	If TypeOf(DepartmentCash)=Type("FixedMap") Then
		DepartmentsMap = New Map(DepartmentCash);
	Else
		DepartmentsMap = New Map;
	EndIf; 
	If TypeOf(TabNumberCash)=Type("FixedMap") Then
		TabNumbersMap = New Map(TabNumberCash);
	Else
		TabNumbersMap = New Map;
	EndIf;
	
	Selection = Result.Get(0).Select();
	While Selection.Next() Do
		DepartmentsMap.Insert(Selection.Employee, Selection.StructuralUnit);
		TabNumbersMap.Insert(Selection.Employee, Selection.TabNumber);
	EndDo;
	
	If TypeOf(FixedCostCash)=Type("FixedMap") Then
		FixedCostMap = New Map(FixedCostCash);
	Else
		FixedCostMap = New Map;
	EndIf; 
	Selection = Result.Get(1).Select();
	While Selection.Next() Do
		FixedCostMap.Insert(Selection.Operation, Selection.FixedCost);
	EndDo;
	
	DepartmentCash = New FixedMap(DepartmentsMap);
	TabNumberCash = New FixedMap(TabNumbersMap);
	FixedCostCash = New FixedMap(FixedCostMap);
	
EndProcedure

&AtServer
Procedure FillStagesUsingAttributes()
	
	If Not FormParameters.UseProductionStages Then
		Return;
	EndIf;
	
	SpecsArray = New Array;
	For Each TabSecRow In Object.Operations Do
		TabSecRow.UseProductionStages = False;
		If ValueIsFilled(TabSecRow.Specification) And SpecsArray.Find(TabSecRow.Specification)=Undefined Then
			SpecsArray.Add(TabSecRow.Specification);
		EndIf; 
	EndDo;
	
	If SpecsArray.Count()=0 Then
		Return;
	EndIf;
	
	SpecificationsWithStageProduction = ProductionServer.ProductionStagesOfSpecifications(SpecsArray);
	For Each TabSecRow In Object.Operations Do
		If Not ValueIsFilled(TabSecRow.Specification) Then
			Continue;
		EndIf;
		TabSecRow.UseProductionStages = (SpecificationsWithStageProduction.Find(TabSecRow.Specification)<>Undefined);
	EndDo;
	
EndProcedure


// End StandardSubsystems.Printing

&AtServer
Procedure FillFormParameters()
	
	FormParameters = Новый Структура;
	FormParameters.Вставить("UseProductionStages", ПолучитьФункциональнуюОпцию("UseProductionStages"));
	FormParameters.Вставить("AccountingBySeveralDepartments", ПолучитьФункциональнуюОпцию("AccountingBySeveralDepartments"));
	
EndProcedure


&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.Operations.PerfomerIsTeam", True);
	WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, "OperationsTabNumber");
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Visible", False);
	
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.Operations.PerfomerIsTeam", False);
	WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, "OperationsChangeContent");
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Visible", False);
	
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.Operations.PerfomerIsTeam", True);
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.StructuralUnitPosition", Enums.AttributePositionOnForm.InTabularSection);
	WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, "OperationsStructuralUnit");
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Visible", False);
	
	// Этапы производства
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.Operations.UseProductionStages", False);
	WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, "OperationsCompletiveStageDepartment");
	WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, "OperationsStage");
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Enabled", False);
	
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.Operations.UseProductionStages", True);
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.Operations.CompletiveStageDepartment", Catalogs.StructuralUnits.EmptyRef());
	WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, "OperationsCompletiveStageDepartment");
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "MarkIncomplete", True);
	
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.Operations.UseProductionStages", True);
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.Operations.Stage", Catalogs.ProductionStages.EmptyRef());
	WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, "OperationsStage");
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "MarkIncomplete", True);
	
EndProcedure

&AtClient
Procedure FillByProductionOrder(Command)
	FillByDocument(Object.ProductionOrder);
EndProcedure

&AtServer
Procedure FillByDocument(ProductionOrder)
	
	
	Document = FormAttributeToValue("Object");
	Document.Fill(ProductionOrder);
	ValueToFormAttribute(Document, "Object");
	Modified = True;
	
	If Object.PerformerPosition = Enums.AttributePositionOnForm.InTabularSection Then
		Object.TeamMembers.Clear();
	EndIf; 
		
	UpdateDataCacheServer();
	FillServiceDataTS(ThisObject);
	
	FillStagesUsingAttributes();
	
EndProcedure


&AtClient
Procedure OperationsPerfomerOnChange(Item)
	
	UpdateDataCaches();
	TabSecRow = Items.Operations.CurrentData;
	FillServiceDataTS(ThisObject, , TabSecRow);
	If Object.StructuralUnitPosition=PredefinedValue("Enum.AttributePositionOnForm.InTabularSection") And Not TabSecRow.PerfomerIsTeam Then
		TabSecRow.StructuralUnit = DepartmentCash.Get(TabSecRow.Performer);
	ElsIf Object.StructuralUnitPosition=PredefinedValue("Enum.AttributePositionOnForm.InHeader") Then
		TabSecRow.StructuralUnit = Object.StructuralUnit;
	EndIf;
	If TabSecRow.PerfomerIsTeam Then
		If TabSecRow.ConnectionKey=0 Then
			TabularSectionName = "Operations";
			SmallBusinessClient.AddConnectionKeyToTabularSectionLine(ThisObject);
		EndIf;
		SmallBusinessClientServer.DeleteRowsByConnectionKey(Object.TeamMembers, TabSecRow);
		FillTeamContentOnServer(TabSecRow.Performer, TabSecRow.ConnectionKey);
	EndIf; 

EndProcedure

&AtServer
// Procedure заполняет состав бригады.
//
Procedure FillTeamContentOnServer(Team, ConectionKey = Undefined)

	If ConectionKey=Undefined Then
		Object.TeamMembers.Clear();
	EndIf; 
	
	If ValueIsFilled(Team) And TypeOf(Team) = Type("CatalogRef.Teams") Then
		
		ContentTable = Catalogs.Teams.TeamsContent(Team, Object.Company, Object.Date);
		
		For Each TabSecRow In ContentTable Do
			NewRow = Object.TeamMembers.Add();
			FillPropertyValues(NewRow, TabSecRow);
			NewRow.LPF = 1;
			If Object.StructuralUnitPosition=Enums.AttributePositionOnForm.InHeader Then
				NewRow.StructuralUnit = Object.StructuralUnit;
			EndIf;
			If ConectionKey<>Undefined Then
				NewRow.ConnectionKey = ConectionKey;
			EndIf; 
		EndDo; 
		
	EndIf;	
	
	Modified = True;
EndProcedure

&AtClient
Procedure UpdateDataCaches()
	
	StaffForUpdate = New Array;
	If Object.PerformerPosition=PredefinedValue("Enum.AttributePositionOnForm.InTabularSection") Then
		For Each TabSecRow In Object.Operations Do
			If Not ValueIsFilled(TabSecRow.Performer) Or TypeOf(TabSecRow.Performer)<>Type("CatalogRef.Employees") Then
				Continue;
			EndIf; 
			If DepartmentCash.Get(TabSecRow.Performer)=Undefined
				Or TabNumberCash.Get(TabSecRow.Performer)=Undefined Then
				StaffForUpdate.Add(TabSecRow.Performer);
			EndIf; 
		EndDo;
		For Each TabSecRow In Object.TeamMembers Do
			If Not ValueIsFilled(TabSecRow.Employee) Then
				Continue;
			EndIf; 
			If DepartmentCash.Get(TabSecRow.Employee)=Undefined
				Or TabNumberCash.Get(TabSecRow.Employee)=Undefined Then
				StaffForUpdate.Add(TabSecRow.Employee);
			EndIf; 
		EndDo;
	ElsIf Object.PerformerPosition=PredefinedValue("Enum.AttributePositionOnForm.InHeader") Then
		If ValueIsFilled(Object.Performer) And TypeOf(Object.Performer)=Type("CatalogRef.Employees") Then
			If DepartmentCash.Get(Object.Performer)=Undefined
				Or TabNumberCash.Get(Object.Performer)=Undefined Then
				StaffForUpdate.Add(Object.Performer);
			EndIf;
		ElsIf TypeOf(Object.Performer)=Type("CatalogRef.Teams") Then
			For Each TabSecRow In Object.TeamMembers Do
				If Not ValueIsFilled(TabSecRow.Employee) Then
					Continue;
				EndIf; 
				If DepartmentCash.Get(TabSecRow.Employee)=Undefined
					Or TabNumberCash.Get(TabSecRow.Employee)=Undefined Then
					StaffForUpdate.Add(TabSecRow.Employee);
				EndIf; 
			EndDo;
		EndIf; 
	EndIf;
	
	OperationsToUpdate = New Array;
	For Each TabSecRow In Object.Operations Do
		If ValueIsFilled(TabSecRow.Operation) And FixedCostCash.Get(TabSecRow.Operation)=Undefined Then
			OperationsToUpdate.Add(TabSecRow.Operation);
		EndIf; 
	EndDo; 
	
	If StaffForUpdate.Count()>0 Or OperationsToUpdate.Count()>0 Then
		UpdateDataCacheServer(StaffForUpdate, OperationsToUpdate);
	EndIf; 
	
EndProcedure

&AtClient
Procedure OperationsSelection(Item, SelectedRow, Field, StandardProcessing)
	
	If Field.Name = "OperationsChangeContent" Then
		Var_StandardProcessing = False;
		OpenChangeContentForm(SelectedRow);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenChangeContentForm(ID)
	
	TabSecRow = Object.Operations.FindByID(ID);
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("ConnectionKey", TabSecRow.ConnectionKey);
	OpeningParameters.Insert("ID", TabSecRow.GetID());
	OpeningParameters.Insert("StructuralUnitPosition", Object.StructuralUnitPosition);
	OpeningParameters.Insert("StructuralUnit", Object.StructuralUnit);
	OpeningParameters.Insert("BrigadeContent", New Array);
	OpeningParameters.Insert("Brigade", TabSecRow.Performer);
	OpeningParameters.Insert("Company", Object.Company);
	OpeningParameters.Insert("Date", Object.Date);
	
	FilterStructure = New Structure;
	FilterStructure.Insert("ConnectionKey", TabSecRow.ConnectionKey);
	ContentRows = Object.TeamMembers.FindRows(FilterStructure);
	For Each TabSecRow In ContentRows Do
		RowDescription = New Structure("Employee, LPF, StructuralUnit");
		FillPropertyValues(RowDescription, TabSecRow);
		OpeningParameters.BrigadeContent.Add(RowDescription);
	EndDo;
	
	OpenForm("Document.JobSheet.Form.FormChangeBrigadeContent", OpeningParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure OperationsOnStartEdit(Item, NewRow, Clone)
	
	CurrentRow = Item.CurrentData;
	
	If NewRow And Clone Then
		CurrentRow.ConnectionKey = 0;
	EndIf;	
	
	If NewRow Or CurrentRow.ConnectionKey=0 Then
		TabularSectionName = "Operations";
		SmallBusinessClient.AddConnectionKeyToTabularSectionLine(ThisObject);
	EndIf; 

EndProcedure

&AtClient
Procedure OperationsBeforeDeleteRow(Item, Cancel)
	
	SmallBusinessClient.DeleteRowsOfSubordinateTabularSection(ThisObject, "TeamMembers");

EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	
	If TypeOf(SelectedValue)=Type("Structure") And SelectedValue.Property("Event") And SelectedValue.Event="ChangingBrigadeContent" Then
		TabSecRow = Object.Operations.FindByID(SelectedValue.ID);
		If TabSecRow.ConnectionKey=0 Then
			TabularSectionName = "Operations";
			SmallBusinessClient.AddConnectionKeyToTabularSectionLine(ThisObject);
		EndIf;
		SmallBusinessClientServer.DeleteRowsByConnectionKey(Object.TeamMembers, TabSecRow);
		For Each RowDescription In SelectedValue.BrigadeContent Do
			NewRow = Object.TeamMembers.Add();
			FillPropertyValues(NewRow, RowDescription);
			NewRow.ConnectionKey = TabSecRow.ConnectionKey;
		EndDo; 
	EndIf; 	

EndProcedure

&AtClient
Procedure BasisDocumentLetteringURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	If FormattedStringURL = "delete" Then
		Object.BasisDocument = Undefined;
		Items.BasisDocumentLabel.Title = WorkWithDocumentFormClientServer.FormLetteringBasisDocument(Undefined);
		Modified = True;
	ElsIf FormattedStringURL = "fill" Then
		FillByBasisStart();
	ElsIf FormattedStringURL = "select" Then
		//Выбрать основание
		NotifyDescription = New NotifyDescription("ChooseBasisTypeEnding", ThisObject);
		ShowChooseFromMenu(NotifyDescription, BasisDocumentList, Items.BasisDocumentLabel);
		
	ElsIf FormattedStringURL = "open" Then
		
		If Not ValueIsFilled(Object.ДокументОснование) Then
			Return;
		EndIf;
		
		WorkWithDocumentFormClient.ОткрытьФормуДокументаПоТипу(Object.ДокументОснование);
		
	EndIf;

EndProcedure

&AtClient
Procedure ChooseBasisTypeEnding(ChooseFormName, Parameters) Export
	
	If ChooseFormName<>Undefined Then
		
		FilterParameters = New Structure();
		_ClosingNotification = New NotifyDescription("ChoseBasisEnding", ThisObject);
		OpenForm(ChooseFormName.Value, FilterParameters, ThisObject, ,,,_ClosingNotification);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoseBasisEnding(ChooseValue, Parameters) Export

	If ChooseValue<>Undefined Then
		Object.BasisDocument = ChooseValue;
		Items.BasisDocumentLabel.Title = WorkWithDocumentFormClientServer.FormLetteringBasisDocument(ChooseValue);
		Modified = True;
		
		FillByBasisStart();
	EndIf;

EndProcedure

&AtServer
Procedure FillBasisDocumentsList()
	
	BasisDocumentList.Clear();
	BasisDocumentList.Add("Document.CustomerOrder.ChoiceForm", NStr("en='Customer order';ru='Заказ покупателя';vi='Đơn hàng của khách'"));
	BasisDocumentList.Add("Document.ProductionOrder.ChoiceForm", NStr("en='Production order';ru='Заказ на производство';vi='Đơn hàng sản xuất'"));
	BasisDocumentList.Add("Document.InventoryAssembly.ChoiceForm", NStr("en = 'Production'; ru = 'Производство'; vi = 'Sản xuất'"));
	
EndProcedure

&AtClient
Procedure FillByBasisStart() Export

	NotifyDescription = New NotifyDescription("FillByBasisEnding", ThisObject);
	ShowQueryBox(
		NotifyDescription, 
		NStr("en = 'Fill in the document by the selected basis?'; ru = 'Заполнить документ по выбранному основанию?'; vi = 'Điền chứng từ theo cơ sở được chọn?'"), 
		QuestionDialogMode.YesNo, 0);

EndProcedure

&AtClient
Procedure FillByBasisEnding(Result, AdditionalParameters) Export
	
	Answer = Result;
	If Answer = DialogReturnCode.Yes Then
		FillByDocument(Object.BasisDocument);
	EndIf;

EndProcedure



#EndRegion