#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

// Initializes the tables of values that contain the data of the document table sections.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure InitializeDocumentData(DocumentRefInventoryReceipt, StructureAdditionalProperties) Export

	Query = New Query(
	"SELECT
	|	InventoryReceiptInventory.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	InventoryReceiptInventory.Ref.Date AS Period,
	|	&Company AS Company,
	|	InventoryReceiptInventory.Ref.StructuralUnit AS StructuralUnit,
	|	CASE
	|		WHEN InventoryReceiptInventory.Ref.StructuralUnit.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Warehouse)
	|				OR InventoryReceiptInventory.Ref.StructuralUnit.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Retail)
	|			THEN InventoryReceiptInventory.ProductsAndServices.InventoryGLAccount
	|		ELSE InventoryReceiptInventory.ProductsAndServices.ExpensesGLAccount
	|	END AS GLAccount,
	|	InventoryReceiptInventory.ProductsAndServices AS ProductsAndServices,
	|	CASE
	|		WHEN &UseCharacteristics
	|			THEN InventoryReceiptInventory.Characteristic
	|		ELSE VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	|	END AS Characteristic,
	|	CASE
	|		WHEN &UseBatches
	|			THEN InventoryReceiptInventory.Batch
	|		ELSE VALUE(Catalog.ProductsAndServicesBatches.EmptyRef)
	|	END AS Batch,
	|	CASE
	|		WHEN VALUETYPE(InventoryReceiptInventory.MeasurementUnit) = TYPE(Catalog.UOMClassifier)
	|			THEN InventoryReceiptInventory.Quantity
	|		ELSE InventoryReceiptInventory.Quantity * InventoryReceiptInventory.MeasurementUnit.Factor
	|	END AS Quantity,
	|	TRUE AS FixedCost,
	|	InventoryReceiptInventory.Amount AS Amount,
	|	VALUE(AccountingRecordType.Debit) AS RecordKindManagerial,
	|	&InventoryReceipt AS ContentOfAccountingRecord
	|FROM
	|	Document.InventoryReceipt.Inventory AS InventoryReceiptInventory
	|WHERE
	|	InventoryReceiptInventory.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryReceiptInventory.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	InventoryReceiptInventory.Ref.Date AS Period,
	|	&Company AS Company,
	|	InventoryReceiptInventory.Ref.StructuralUnit AS StructuralUnit,
	|	CASE
	|		WHEN &AccountingByCells
	|			THEN InventoryReceiptInventory.Ref.Cell
	|		ELSE UNDEFINED
	|	END AS Cell,
	|	InventoryReceiptInventory.ProductsAndServices AS ProductsAndServices,
	|	CASE
	|		WHEN &UseCharacteristics
	|			THEN InventoryReceiptInventory.Characteristic
	|		ELSE VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	|	END AS Characteristic,
	|	CASE
	|		WHEN &UseBatches
	|			THEN InventoryReceiptInventory.Batch
	|		ELSE VALUE(Catalog.ProductsAndServicesBatches.EmptyRef)
	|	END AS Batch,
	|	CASE
	|		WHEN VALUETYPE(InventoryReceiptInventory.MeasurementUnit) = TYPE(Catalog.UOMClassifier)
	|			THEN InventoryReceiptInventory.Quantity
	|		ELSE InventoryReceiptInventory.Quantity * InventoryReceiptInventory.MeasurementUnit.Factor
	|	END AS Quantity
	|FROM
	|	Document.InventoryReceipt.Inventory AS InventoryReceiptInventory
	|WHERE
	|	InventoryReceiptInventory.Ref = &Ref
	|	AND InventoryReceiptInventory.Ref.StructuralUnit.OrderWarehouse = FALSE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryReceiptInventory.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	InventoryReceiptInventory.Ref.Date AS Period,
	|	&Company AS Company,
	|	InventoryReceiptInventory.Ref.StructuralUnit AS StructuralUnit,
	|	InventoryReceiptInventory.ProductsAndServices AS ProductsAndServices,
	|	CASE
	|		WHEN &UseCharacteristics
	|			THEN InventoryReceiptInventory.Characteristic
	|		ELSE VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	|	END AS Characteristic,
	|	CASE
	|		WHEN &UseBatches
	|			THEN InventoryReceiptInventory.Batch
	|		ELSE VALUE(Catalog.ProductsAndServicesBatches.EmptyRef)
	|	END AS Batch,
	|	CASE
	|		WHEN VALUETYPE(InventoryReceiptInventory.MeasurementUnit) = TYPE(Catalog.UOMClassifier)
	|			THEN InventoryReceiptInventory.Quantity
	|		ELSE InventoryReceiptInventory.Quantity * InventoryReceiptInventory.MeasurementUnit.Factor
	|	END AS Quantity
	|FROM
	|	Document.InventoryReceipt.Inventory AS InventoryReceiptInventory
	|WHERE
	|	InventoryReceiptInventory.Ref = &Ref
	|	AND InventoryReceiptInventory.Ref.StructuralUnit.OrderWarehouse = TRUE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryReceiptInventory.Ref.Date AS Period,
	|	&Company AS Company,
	|	VALUE(Catalog.BusinessActivities.Other) AS BusinessActivity,
	|	SUM(InventoryReceiptInventory.Amount) AS AmountIncome,
	|	SUM(InventoryReceiptInventory.Amount) AS Amount,
	|	InventoryReceiptInventory.Ref.Correspondence AS GLAccount,
	|	VALUE(AccountingRecordType.Credit) AS RecordKindManagerial,
	|	&RevenueIncomes AS ContentOfAccountingRecord
	|FROM
	|	Document.InventoryReceipt.Inventory AS InventoryReceiptInventory
	|WHERE
	|	InventoryReceiptInventory.Ref = &Ref
	|	AND InventoryReceiptInventory.Ref.Correspondence.TypeOfAccount = VALUE(Enum.GLAccountsTypes.OtherIncome)
	|	AND InventoryReceiptInventory.Amount > 0
	|
	|GROUP BY
	|	InventoryReceiptInventory.Ref,
	|	InventoryReceiptInventory.Ref.Date,
	|	InventoryReceiptInventory.Ref.Correspondence
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(InventoryReceiptInventory.LineNumber) AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	InventoryReceiptInventory.Ref.Date AS Period,
	|	InventoryReceiptInventory.Ref.Company AS Company,
	|	InventoryReceiptInventory.ProductsAndServices AS ProductsAndServices,
	|	InventoryReceiptInventory.Characteristic AS Characteristic,
	|	InventoryReceiptInventory.Batch AS Batch,
	|	InventoryReceiptInventory.CCDNo AS CCDNo,
	|	InventoryReceiptInventory.CountryOfOrigin AS CountryOfOrigin,
	|	SUM(InventoryReceiptInventory.Quantity) AS Quantity
	|FROM
	|	Document.InventoryReceipt.Inventory AS InventoryReceiptInventory
	|WHERE
	|	InventoryReceiptInventory.Ref = &REf
	|	AND InventoryReceiptInventory.CountryOfOrigin <> VALUE(Справочник.WorldCountries.Russia)
	|	AND InventoryReceiptInventory.CountryOfOrigin <> VALUE(Справочник.WorldCountries.EmptyRef)
	|	AND InventoryReceiptInventory.CCDNo <> VALUE(Справочник.CCDNumbers.EmptyRef)
	|
	|GROUP BY
	|	InventoryReceiptInventory.Ref.Date,
	|	InventoryReceiptInventory.Ref.Company,
	|	InventoryReceiptInventory.ProductsAndServices,
	|	InventoryReceiptInventory.Characteristic,
	|	InventoryReceiptInventory.Batch,
	|	InventoryReceiptInventory.CCDNo,
	|	InventoryReceiptInventory.CountryOfOrigin
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryReceiptInventory.Ref.Date AS Period,
	|	&Company AS Company,
	|	VALUE(Catalog.PlanningPeriods.Actual) AS PlanningPeriod,
	|	CASE
	|		WHEN InventoryReceiptInventory.Ref.StructuralUnit.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Warehouse)
	|				OR InventoryReceiptInventory.Ref.StructuralUnit.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Retail)
	|			THEN InventoryReceiptInventory.ProductsAndServices.InventoryGLAccount
	|		ELSE InventoryReceiptInventory.ProductsAndServices.ExpensesGLAccount
	|	END AS AccountDr,
	|	UNDEFINED AS CurrencyDr,
	|	0 AS AmountCurDr,
	|	InventoryReceiptInventory.Ref.Correspondence AS AccountCr,
	|	UNDEFINED AS CurrencyCr,
	|	0 AS AmountCurCr,
	|	SUM(InventoryReceiptInventory.Amount) AS Amount,
	|	&InventoryReceipt AS Content
	|FROM
	|	Document.InventoryReceipt.Inventory AS InventoryReceiptInventory
	|WHERE
	|	InventoryReceiptInventory.Ref = &Ref
	|	AND InventoryReceiptInventory.Amount > 0
	|
	|GROUP BY
	|	InventoryReceiptInventory.Ref.Date,
	|	CASE
	|		WHEN InventoryReceiptInventory.Ref.StructuralUnit.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Warehouse)
	|				OR InventoryReceiptInventory.Ref.StructuralUnit.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Retail)
	|			THEN InventoryReceiptInventory.ProductsAndServices.InventoryGLAccount
	|		ELSE InventoryReceiptInventory.ProductsAndServices.ExpensesGLAccount
	|	END,
	|	InventoryReceiptInventory.Ref.Correspondence
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableInventory.Ref.Date AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TableInventory.Ref.Date AS EventDate,
	|	VALUE(Enum.SerialNumbersOperations.Receipt) AS Operation,
	|	TableSerialNumbers.SerialNumber AS SerialNumber,
	|	&Company AS Company,
	|	TableInventory.ProductsAndServices AS ProductsAndServices,
	|	TableInventory.Characteristic AS Characteristic,
	|	TableInventory.Batch AS Batch,
	|	TableInventory.Ref.StructuralUnit AS StructuralUnit,
	|	TableInventory.Ref.Cell AS Cell,
	|	1 AS Quantity
	|FROM
	|	Document.InventoryReceipt.Inventory AS TableInventory
	|		INNER JOIN Document.InventoryReceipt.SerialNumbers AS TableSerialNumbers
	|		ON TableInventory.Ref = TableSerialNumbers.Ref
	|			AND TableInventory.ConnectionKey = TableSerialNumbers.ConnectionKey
	|WHERE
	|	TableSerialNumbers.Ref = &Ref
	|	AND TableInventory.Ref = &Ref
	|	AND &UseSerialNumbers
	|	AND NOT TableInventory.Ref.StructuralUnit.OrderWarehouse");
	
	Query.SetParameter("Ref", DocumentRefInventoryReceipt);
	Query.SetParameter("Company", StructureAdditionalProperties.ForPosting.Company);
	Query.SetParameter("UseCharacteristics", StructureAdditionalProperties.AccountingPolicy.UseCharacteristics);
	Query.SetParameter("AccountingByCells", StructureAdditionalProperties.AccountingPolicy.AccountingByCells);
	Query.SetParameter("UseBatches", StructureAdditionalProperties.AccountingPolicy.UseBatches);
	
	Query.SetParameter("InventoryReceipt", NStr("en='Inventory receiving';ru='Inventory receiving';vi='Tiếp nhận vật tư'"));
	Query.SetParameter("RevenueIncomes", NStr("en='Receipt of other income';ru='Поступление прочих доходов';vi='Tiếp nhận chi phí khác'"));
	Query.SetParameter("OtherIncome", NStr("en='Other inventory capitalization';ru='Прочее оприходование запасов';vi='Ghi tăng vật tư khác'"));
	
	Query.SetParameter("UseSerialNumbers", StructureAdditionalProperties.AccountingPolicy.UseSerialNumbers);
	
	ResultsArray = Query.ExecuteBatch();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableInventory", ResultsArray[0].Unload());
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableInventoryInWarehouses", ResultsArray[1].Unload());
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableInventoryForWarehouses", ResultsArray[2].Unload());
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableIncomeAndExpenses", ResultsArray[3].Unload());
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableInventoryByCCD", ResultsArray[4].Unload());
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableManagerial", ResultsArray[5].Unload());
	
	ResultOfAQuery5 = ResultsArray[6].Unload();
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableSerialNumbersGuarantees", ResultOfAQuery5);
	If StructureAdditionalProperties.AccountingPolicy.SerialNumbersBalance Then
		StructureAdditionalProperties.TableForRegisterRecords.Insert("TableSerialNumbersBalance", ResultOfAQuery5);
	Else
		StructureAdditionalProperties.TableForRegisterRecords.Insert("TableSerialNumbersBalance", New ValueTable);
	EndIf;
	
EndProcedure // DocumentDataInitialization()

// Controls the occurrence of negative balances.
//
Procedure RunControl(DocumentRefInventoryReceipt, AdditionalProperties, Cancel, PostingDelete = False) Export
	
	If Not SmallBusinessServer.RunBalanceControl() Then
		Return;
	EndIf;

	StructureTemporaryTables = AdditionalProperties.ForPosting.StructureTemporaryTables;
	
	// If the "InventoryTransferAtWarehouseChange",
	// "RegisterRecordsInventoryChange" temporary tables contain records, it is necessary to control the sales of goods.
	
	If StructureTemporaryTables.RegisterRecordsInventoryInWarehousesChange
		OR StructureTemporaryTables.RegisterRecordsInventoryByCCDChange 
		OR StructureTemporaryTables.RegisterRecordsInventoryChange Then

		QueryText = 
		"SELECT
		|	RegisterRecordsInventoryInWarehousesChange.LineNumber AS LineNumber,
		|	REFPRESENTATION(RegisterRecordsInventoryInWarehousesChange.Company) AS CompanyPresentation,
		|	REFPRESENTATION(RegisterRecordsInventoryInWarehousesChange.StructuralUnit) AS StructuralUnitPresentation,
		|	REFPRESENTATION(RegisterRecordsInventoryInWarehousesChange.ProductsAndServices) AS ProductsAndServicesPresentation,
		|	REFPRESENTATION(RegisterRecordsInventoryInWarehousesChange.Characteristic) AS CharacteristicPresentation,
		|	REFPRESENTATION(RegisterRecordsInventoryInWarehousesChange.Batch) AS BatchPresentation,
		|	REFPRESENTATION(RegisterRecordsInventoryInWarehousesChange.Cell) AS PresentationCell,
		|	InventoryInWarehousesOfBalance.StructuralUnit.StructuralUnitType AS StructuralUnitType,
		|	REFPRESENTATION(InventoryInWarehousesOfBalance.ProductsAndServices.MeasurementUnit) AS MeasurementUnitPresentation,
		|	ISNULL(RegisterRecordsInventoryInWarehousesChange.QuantityChange, 0) + ISNULL(InventoryInWarehousesOfBalance.QuantityBalance, 0) AS BalanceInventoryInWarehouses,
		|	ISNULL(InventoryInWarehousesOfBalance.QuantityBalance, 0) AS QuantityBalanceInventoryInWarehouses
		|FROM
		|	RegisterRecordsInventoryInWarehousesChange AS RegisterRecordsInventoryInWarehousesChange
		|		LEFT JOIN AccumulationRegister.InventoryInWarehouses.Balance(
		|				&ControlTime,
		|				(Company, StructuralUnit, ProductsAndServices, Characteristic, Batch, Cell) In
		|					(SELECT
		|						RegisterRecordsInventoryInWarehousesChange.Company AS Company,
		|						RegisterRecordsInventoryInWarehousesChange.StructuralUnit AS StructuralUnit,
		|						RegisterRecordsInventoryInWarehousesChange.ProductsAndServices AS ProductsAndServices,
		|						RegisterRecordsInventoryInWarehousesChange.Characteristic AS Characteristic,
		|						RegisterRecordsInventoryInWarehousesChange.Batch AS Batch,
		|						RegisterRecordsInventoryInWarehousesChange.Cell AS Cell
		|					FROM
		|						RegisterRecordsInventoryInWarehousesChange AS RegisterRecordsInventoryInWarehousesChange)) AS InventoryInWarehousesOfBalance
		|		ON RegisterRecordsInventoryInWarehousesChange.Company = InventoryInWarehousesOfBalance.Company
		|			AND RegisterRecordsInventoryInWarehousesChange.StructuralUnit = InventoryInWarehousesOfBalance.StructuralUnit
		|			AND RegisterRecordsInventoryInWarehousesChange.ProductsAndServices = InventoryInWarehousesOfBalance.ProductsAndServices
		|			AND RegisterRecordsInventoryInWarehousesChange.Characteristic = InventoryInWarehousesOfBalance.Characteristic
		|			AND RegisterRecordsInventoryInWarehousesChange.Batch = InventoryInWarehousesOfBalance.Batch
		|			AND RegisterRecordsInventoryInWarehousesChange.Cell = InventoryInWarehousesOfBalance.Cell
		|WHERE
		|	ISNULL(InventoryInWarehousesOfBalance.QuantityBalance, 0) < 0
		|
		|ORDER BY
		|	LineNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RegisterRecordsInventoryChange.LineNumber AS LineNumber,
		|	REFPRESENTATION(RegisterRecordsInventoryChange.Company) AS CompanyPresentation,
		|	REFPRESENTATION(RegisterRecordsInventoryChange.StructuralUnit) AS StructuralUnitPresentation,
		|	REFPRESENTATION(RegisterRecordsInventoryChange.GLAccount) AS GLAccountPresentation,
		|	REFPRESENTATION(RegisterRecordsInventoryChange.ProductsAndServices) AS ProductsAndServicesPresentation,
		|	REFPRESENTATION(RegisterRecordsInventoryChange.Characteristic) AS CharacteristicPresentation,
		|	REFPRESENTATION(RegisterRecordsInventoryChange.Batch) AS BatchPresentation,
		|	REFPRESENTATION(RegisterRecordsInventoryChange.CustomerOrder) AS CustomerOrderPresentation,
		|	InventoryBalances.StructuralUnit.StructuralUnitType AS StructuralUnitType,
		|	REFPRESENTATION(InventoryBalances.ProductsAndServices.MeasurementUnit) AS MeasurementUnitPresentation,
		|	ISNULL(RegisterRecordsInventoryChange.QuantityChange, 0) + ISNULL(InventoryBalances.QuantityBalance, 0) AS BalanceInventory,
		|	ISNULL(InventoryBalances.QuantityBalance, 0) AS QuantityBalanceInventory,
		|	ISNULL(InventoryBalances.AmountBalance, 0) AS AmountBalanceInventory
		|FROM
		|	RegisterRecordsInventoryChange AS RegisterRecordsInventoryChange
		|		LEFT JOIN AccumulationRegister.Inventory.Balance(
		|				&ControlTime,
		|				(Company, StructuralUnit, GLAccount, ProductsAndServices, Characteristic, Batch, CustomerOrder) In
		|					(SELECT
		|						RegisterRecordsInventoryChange.Company AS Company,
		|						RegisterRecordsInventoryChange.StructuralUnit AS StructuralUnit,
		|						RegisterRecordsInventoryChange.GLAccount AS GLAccount,
		|						RegisterRecordsInventoryChange.ProductsAndServices AS ProductsAndServices,
		|						RegisterRecordsInventoryChange.Characteristic AS Characteristic,
		|						RegisterRecordsInventoryChange.Batch AS Batch,
		|						RegisterRecordsInventoryChange.CustomerOrder AS CustomerOrder
		|					FROM
		|						RegisterRecordsInventoryChange AS RegisterRecordsInventoryChange)) AS InventoryBalances
		|		ON RegisterRecordsInventoryChange.Company = InventoryBalances.Company
		|			AND RegisterRecordsInventoryChange.StructuralUnit = InventoryBalances.StructuralUnit
		|			AND RegisterRecordsInventoryChange.GLAccount = InventoryBalances.GLAccount
		|			AND RegisterRecordsInventoryChange.ProductsAndServices = InventoryBalances.ProductsAndServices
		|			AND RegisterRecordsInventoryChange.Characteristic = InventoryBalances.Characteristic
		|			AND RegisterRecordsInventoryChange.Batch = InventoryBalances.Batch
		|			AND RegisterRecordsInventoryChange.CustomerOrder = InventoryBalances.CustomerOrder
		|WHERE
		|	ISNULL(InventoryBalances.QuantityBalance, 0) < 0
		|
		|ORDER BY
		|	LineNumber";
		
		QueryText = QueryText + SmallBusinessServer.GenerateBatchQueryTemplate();
		AccumulationRegisters.InventoryByCCD.AddTextInventoryByCCD(QueryText);
		
		Query = New Query(QueryText);
		Query.TempTablesManager = StructureTemporaryTables.TempTablesManager;
		Query.SetParameter("ControlTime", AdditionalProperties.ForPosting.ControlTime);
		
		ResultsArray = Query.ExecuteBatch();

		If Not ResultsArray[0].IsEmpty()
			OR Not ResultsArray[1].IsEmpty() 
			OR Not ResultsArray[2].IsEmpty() Then
			DocumentObjectInventoryReceipt = DocumentRefInventoryReceipt.GetObject()
		EndIf;
		
		// Negative balance of inventory in the warehouse.
		If Not ResultsArray[0].IsEmpty() Then
			QueryResultSelection = ResultsArray[0].Select();
			SmallBusinessServer.ShowMessageAboutPostingToInventoryInWarehousesRegisterErrors(DocumentObjectInventoryReceipt, QueryResultSelection, Cancel);
		EndIf;
		
		// Negative balance of inventory and cost accounting.
		If Not ResultsArray[1].IsEmpty() Then
			QueryResultSelection = ResultsArray[1].Select();
			SmallBusinessServer.ShowMessageAboutPostingToInventoryRegisterErrors(DocumentObjectInventoryReceipt, QueryResultSelection, Cancel);
		EndIf;
		
		If Not ResultsArray[2].IsEmpty() Then
			QueryResultSelection = ResultsArray[2].Select();
			SmallBusinessServer.ShowMessageAboutPostingToInventoryByCCDRegisterErrors(DocumentObjectInventoryReceipt, QueryResultSelection, Cancel);
		EndIf;


	EndIf;

EndProcedure // RunControl()

#Region PrintInterface

// Fills in the list of printing commands.
// 
// Parameters:
//   PrintCommands - ValueTable - see fields' content in the PrintManagement.CreatePrintCommandsCollection function.
//
Procedure AddPrintCommands(PrintCommands) Export
	
	// 1C - CHIENTN - 27-12-2018
	PrintCommand = PrintCommands.Add();
	PrintCommand.ID 						= "WarehouseInputSlip";
	PrintCommand.Presentation 				= NStr("en='Warehouse input slip (01-VT)';ru='Приходный ордер на товары (01-VT)';vi='Phiếu nhập kho (01-VT)'");
	PrintCommand.FormsList 					= "DocumentForm,ListForm,DocumentsListForm";
	PrintCommand.CheckPostingBeforePrint 	= False;
	PrintCommand.Order 						= 1; 	
	// 1C
	
	
EndProcedure

// Generate objects printing forms.
//
// Incoming:
//   TemplateNames    - String    - Names of layouts separated
//   by commas ObjectsArray  - Array    - Array of refs to objects that
//   need to be printed PrintParameters - Structure - Structure of additional printing parameters
//
// Outgoing:
//   PrintFormsCollection - Values table - Generated
//   table documents OutputParameters       - Structure        - Parameters of generated table documents
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	// 1C - CHIENTN - 27-12-2018
	If PrintManagement.NeedToPrintTemplate(PrintFormsCollection, "WarehouseInputSlip") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "WarehouseInputSlip", "Warehouse input slip (01-VT)", PrintForm(ObjectsArray, PrintObjects, "WarehouseInputSlip"));
		
	EndIf;
	// 1C 
	
	// parameters of sending printing forms by email
	SmallBusinessServer.FillSendingParameters(OutputParameters.SendingParameters, ObjectsArray, PrintFormsCollection);
	
EndProcedure // Print()

// Function checks if the document is posted and calls the procedure of document printing.
//
Function PrintForm(ObjectsArray, PrintObjects, TemplateName)
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersKey = "PrintParameters_InventoryReceipt";
	
	FirstDocument = True;
	
	For Each CurrentDocument IN ObjectsArray Do
	
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		FirstDocument = False;
		
		FirstLineNumber = SpreadsheetDocument.TableHeight + 1;
				
		// 1C - CHIENTN - 27-12-2018	
		If TemplateName = "WarehouseInputSlip" Then
		
			GenerateWarehouseInputSlip(SpreadsheetDocument, CurrentDocument); 		
			
		EndIf;	
	    // 1C	
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, FirstLineNumber, PrintObjects, CurrentDocument);
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;
	
EndFunction // PrintForm()

// 1C - CHIENTN - 27-12-2018
Procedure GenerateWarehouseInputSlip(SpreadsheetDocument, CurrentDocument)
	
	Query = New Query();
	Query.SetParameter("CurrentDocument", CurrentDocument); 
	Query.Text = 		
	"SELECT
	|	InventoryReceipt.Date AS DocumentDate,
	|	InventoryReceipt.Number AS Number,
	|	InventoryReceipt.Company AS Company,
	|	InventoryReceipt.Company.Prefix AS Prefix,
	|	InventoryReceipt.StructuralUnit AS Warehouse,
	|	InventoryReceipt.Author AS Author,
	|	InventoryReceipt.Inventory.(
	|		LineNumber AS LineNumber,
	|		CASE
	|			WHEN (CAST(InventoryReceipt.Inventory.ProductsAndServices.DescriptionFull AS STRING(1000))) = """"
	|				THEN InventoryReceipt.Inventory.ProductsAndServices.Description
	|			ELSE CAST(InventoryReceipt.Inventory.ProductsAndServices.DescriptionFull AS STRING(1000))
	|		END AS Product,
	|		ProductsAndServices.SKU AS SKU,
	|		ProductsAndServices.Code AS ProductCode,
	|		MeasurementUnit AS Unit,
	|		Quantity AS Quantity
	|	) AS Inventory
	|FROM
	|	Document.InventoryReceipt AS InventoryReceipt
	|WHERE
	|	InventoryReceipt.Ref = &CurrentDocument";	
		
	Selection = Query.Execute().Select();
	Selection.Next();
	
	ProductsSelection = Selection.Inventory.Select();
				
	SpreadsheetDocument.PrintParametersName = "PRINT_PARAMETERS_PF_MXL_WarehouseInputSlip_01VT";
	
	Template = PrintManagement.GetTemplate("CommonTemplate.PF_MXL_WarehouseInputSlip_01VT");
	InfoAboutCompany 		= SmallBusinessServer.InfoAboutLegalEntityIndividual(Selection.Company, Selection.DocumentDate, ,);	
	
	FillStructureSection = New Structure();
	FillStructureSection.Insert("Company", 	InfoAboutCompany.FullDescr);
	FillStructureSection.Insert("Date", 	SmallBusinessServer.GetFormatingDateByLanguageForPrinting(Selection.DocumentDate)); 

	TemplateArea = Template.GetArea("Header");							
	TemplateArea.Parameters.Fill(Selection);
	TemplateArea.Parameters.Fill(FillStructureSection);
	SpreadsheetDocument.Put(TemplateArea);
	
	TemplateArea = Template.GetArea("TableRow");   
	
	Amount		= 0;
	VATAmount	= 0;
	Total		= 0;
	Quantity	= 0;
	
	While ProductsSelection.Next() Do  				
		TemplateArea.Parameters.Fill(ProductsSelection);								
		SpreadsheetDocument.Put(TemplateArea);
		
		////Amount		= Amount	+ LinesSelectionInventory.Amount;
		////VATAmount	= VATAmount	+ LinesSelectionInventory.VATAmount;
		////Total		= Total		+ LinesSelectionInventory.Total;
		Quantity	= Quantity  + ProductsSelection.Quantity;  				
	EndDo;
	
	TemplateArea = Template.GetArea("Total");
	FillStructureSection.Insert("Quantity", Quantity);
	FillStructureSection.Insert("Total", 	Total);   
	TemplateArea.Parameters.Fill(FillStructureSection);
	////TemplateArea.Parameters.TotalAmountInWords 	= WorkWithCurrencyRates.GenerateAmountInWords(Total, Selection.DocumentCurrency);
	SpreadsheetDocument.Put(TemplateArea);
	
	TemplateArea = Template.GetArea("Footer"); 
	ResponsiblePersons = SmallBusinessServer.OrganizationalUnitsResponsiblePersons(Selection.Company, Selection.DocumentDate);
	TemplateArea.Parameters.Fill(Selection); 
	TemplateArea.Parameters.Fill(FillStructureSection);
	TemplateArea.Parameters.Fill(ResponsiblePersons);
	SpreadsheetDocument.Put(TemplateArea);			
	
EndProcedure // GenerateInvoice()

#EndRegion

#EndIf