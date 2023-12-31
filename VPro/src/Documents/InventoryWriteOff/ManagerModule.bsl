#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableInventory(DocumentRefInventoryWriteOff, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	
	// Setting the exclusive lock for the controlled inventory balances.
	Query.Text = 
	"SELECT
	|	TableInventory.Company AS Company,
	|	TableInventory.StructuralUnit AS StructuralUnit,
	|	TableInventory.GLAccount AS GLAccount,
	|	TableInventory.ProductsAndServices AS ProductsAndServices,
	|	TableInventory.Characteristic AS Characteristic,
	|	TableInventory.Batch AS Batch,
	|	VALUE(Document.CustomerOrder.EmptyRef) AS CustomerOrder
	|FROM
	|	TemporaryTableInventory AS TableInventory
	|
	|GROUP BY
	|	TableInventory.Company,
	|	TableInventory.StructuralUnit,
	|	TableInventory.GLAccount,
	|	TableInventory.ProductsAndServices,
	|	TableInventory.Characteristic,
	|	TableInventory.Batch";
	
	QueryResult = Query.Execute();
	
	Block = New DataLock;
	LockItem = Block.Add("AccumulationRegister.Inventory");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = QueryResult;

	For Each ColumnQueryResult in QueryResult.Columns Do
		LockItem.UseFromDataSource(ColumnQueryResult.Name, ColumnQueryResult.Name);
	EndDo;
	Block.Lock();
	
	// Receiving inventory balances by cost.
	Query.Text = 	
	"SELECT
	|	InventoryBalances.Company AS Company,
	|	InventoryBalances.StructuralUnit AS StructuralUnit,
	|	InventoryBalances.GLAccount AS GLAccount,
	|	InventoryBalances.ProductsAndServices AS ProductsAndServices,
	|	InventoryBalances.Characteristic AS Characteristic,
	|	InventoryBalances.Batch AS Batch,
	|	SUM(InventoryBalances.QuantityBalance) AS QuantityBalance,
	|	SUM(InventoryBalances.AmountBalance) AS AmountBalance
	|FROM
	|	(SELECT
	|		InventoryBalances.Company AS Company,
	|		InventoryBalances.StructuralUnit AS StructuralUnit,
	|		InventoryBalances.GLAccount AS GLAccount,
	|		InventoryBalances.ProductsAndServices AS ProductsAndServices,
	|		InventoryBalances.Characteristic AS Characteristic,
	|		InventoryBalances.Batch AS Batch,
	|		SUM(InventoryBalances.QuantityBalance) AS QuantityBalance,
	|		SUM(InventoryBalances.AmountBalance) AS AmountBalance
	|	FROM
	|		AccumulationRegister.Inventory.Balance(
	|				&ControlTime,
	|				(Company, StructuralUnit, GLAccount, ProductsAndServices, Characteristic, Batch, CustomerOrder) In
	|					(SELECT
	|						TableInventory.Company,
	|						TableInventory.StructuralUnit,
	|						TableInventory.GLAccount,
	|						TableInventory.ProductsAndServices,
	|						TableInventory.Characteristic,
	|						TableInventory.Batch,
	|						VALUE(Document.CustomerOrder.EmptyRef) AS CustomerOrder
	|					FROM
	|						TemporaryTableInventory AS TableInventory)) AS InventoryBalances
	|	
	|	GROUP BY
	|		InventoryBalances.Company,
	|		InventoryBalances.StructuralUnit,
	|		InventoryBalances.GLAccount,
	|		InventoryBalances.ProductsAndServices,
	|		InventoryBalances.Characteristic,
	|		InventoryBalances.Batch
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentRegisterRecordsInventory.Company,
	|		DocumentRegisterRecordsInventory.StructuralUnit,
	|		DocumentRegisterRecordsInventory.GLAccount,
	|		DocumentRegisterRecordsInventory.ProductsAndServices,
	|		DocumentRegisterRecordsInventory.Characteristic,
	|		DocumentRegisterRecordsInventory.Batch,
	|		CASE
	|			WHEN DocumentRegisterRecordsInventory.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN ISNULL(DocumentRegisterRecordsInventory.Quantity, 0)
	|			ELSE -ISNULL(DocumentRegisterRecordsInventory.Quantity, 0)
	|		END,
	|		CASE
	|			WHEN DocumentRegisterRecordsInventory.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN ISNULL(DocumentRegisterRecordsInventory.Amount, 0)
	|			ELSE -ISNULL(DocumentRegisterRecordsInventory.Amount, 0)
	|		END
	|	FROM
	|		AccumulationRegister.Inventory AS DocumentRegisterRecordsInventory
	|	WHERE
	|		DocumentRegisterRecordsInventory.Recorder = &Ref
	|		AND DocumentRegisterRecordsInventory.Period <= &ControlPeriod) AS InventoryBalances
	|
	|GROUP BY
	|	InventoryBalances.Company,
	|	InventoryBalances.StructuralUnit,
	|	InventoryBalances.GLAccount,
	|	InventoryBalances.ProductsAndServices,
	|	InventoryBalances.Characteristic,
	|	InventoryBalances.Batch";
	
	Query.SetParameter("Ref", DocumentRefInventoryWriteOff);
	Query.SetParameter("ControlTime", New Boundary(StructureAdditionalProperties.ForPosting.PointInTime, BoundaryType.Including));
	Query.SetParameter("ControlPeriod", StructureAdditionalProperties.ForPosting.PointInTime.Date);
	
	QueryResult = Query.Execute();
	
	TableInventoryBalances = QueryResult.Unload();
	TableInventoryBalances.Indexes.Add("Company,StructuralUnit,GLAccount,ProductsAndServices,Characteristic,Batch");
	
	For n = 0 To StructureAdditionalProperties.TableForRegisterRecords.TableInventory.Count() - 1 Do
		
		RowTableInventory = StructureAdditionalProperties.TableForRegisterRecords.TableInventory[n];
		
		StructureForSearch = New Structure;
		StructureForSearch.Insert("Company", RowTableInventory.Company);
		StructureForSearch.Insert("StructuralUnit", RowTableInventory.StructuralUnit);
		StructureForSearch.Insert("GLAccount", RowTableInventory.GLAccount);
		StructureForSearch.Insert("ProductsAndServices", RowTableInventory.ProductsAndServices);
		StructureForSearch.Insert("Characteristic", RowTableInventory.Characteristic);
		StructureForSearch.Insert("Batch", RowTableInventory.Batch);
		
		QuantityWanted = RowTableInventory.Quantity;
		
		If QuantityWanted > 0 Then
			
			BalanceRowsArray = TableInventoryBalances.FindRows(StructureForSearch);
			
			QuantityBalance = 0;
			AmountBalance = 0;
			
			If BalanceRowsArray.Count() > 0 Then
				QuantityBalance = BalanceRowsArray[0].QuantityBalance;
				AmountBalance = BalanceRowsArray[0].AmountBalance;
			EndIf;
			
			If QuantityBalance > 0 AND QuantityBalance > QuantityWanted Then

				AmountToBeWrittenOff = Round(AmountBalance * QuantityWanted / QuantityBalance , 2, 1);

				BalanceRowsArray[0].QuantityBalance = BalanceRowsArray[0].QuantityBalance - QuantityWanted;
				BalanceRowsArray[0].AmountBalance = BalanceRowsArray[0].AmountBalance - AmountToBeWrittenOff;

			ElsIf QuantityBalance = QuantityWanted Then

				AmountToBeWrittenOff = AmountBalance;

				BalanceRowsArray[0].QuantityBalance = 0;
				BalanceRowsArray[0].AmountBalance = 0;

			Else
				AmountToBeWrittenOff = 0;	
			EndIf;
	
			RowTableInventory.Amount = AmountToBeWrittenOff;
			RowTableInventory.Quantity = QuantityWanted;
					
		EndIf;
		
		// Generate postings.
		If Round(RowTableInventory.Amount, 2, 1) <> 0 Then
			RowTableManagerial = StructureAdditionalProperties.TableForRegisterRecords.TableManagerial.Add();
			FillPropertyValues(RowTableManagerial, RowTableInventory);
		EndIf;
		
	EndDo;
	
EndProcedure // GenerateInventoryTable()

// Initializes the tables of values that contain the data of the document table sections.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure InitializeDocumentData(DocumentRefInventoryWriteOff, StructureAdditionalProperties) Export

	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text = 
	"SELECT
	|	InventoryWriteOffInventory.LineNumber AS LineNumber,
	|	InventoryWriteOffInventory.ConnectionKey AS ConnectionKey,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	InventoryWriteOffInventory.Ref AS Ref,
	|	InventoryWriteOffInventory.Ref.Date AS Period,
	|	InventoryWriteOffInventory.Ref.StructuralUnit.OrderWarehouse AS OrderWarehouse,
	|	&Company AS Company,
	|	VALUE(Catalog.PlanningPeriods.Actual) AS PlanningPeriod,
	|	InventoryWriteOffInventory.Ref.StructuralUnit AS StructuralUnit,
	|	InventoryWriteOffInventory.Ref.Cell AS Cell,
	|	CASE
	|		WHEN InventoryWriteOffInventory.Ref.StructuralUnit.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Warehouse)
	|				OR InventoryWriteOffInventory.Ref.StructuralUnit.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Retail)
	|				OR InventoryWriteOffInventory.Ref.RetireInventoryFromOperation
	|			THEN InventoryWriteOffInventory.ProductsAndServices.InventoryGLAccount
	|		ELSE InventoryWriteOffInventory.ProductsAndServices.ExpensesGLAccount
	|	END AS GLAccount,
	|	InventoryWriteOffInventory.ProductsAndServices AS ProductsAndServices,
	|	InventoryWriteOffInventory.CountryOfOrigin AS CountryOfOrigin,
	|	InventoryWriteOffInventory.CCDNo AS CCDNo,
	|	CASE
	|		WHEN &UseCharacteristics
	|			THEN InventoryWriteOffInventory.Characteristic
	|		ELSE VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	|	END AS Characteristic,
	|	CASE
	|		WHEN &UseBatches
	|			THEN InventoryWriteOffInventory.Batch
	|		ELSE VALUE(Catalog.ProductsAndServicesBatches.EmptyRef)
	|	END AS Batch,
	|	CASE
	|		WHEN VALUETYPE(InventoryWriteOffInventory.MeasurementUnit) = TYPE(Catalog.UOMClassifier)
	|			THEN InventoryWriteOffInventory.Quantity
	|		ELSE InventoryWriteOffInventory.Quantity * InventoryWriteOffInventory.MeasurementUnit.Factor
	|	END AS Quantity,
	|	0 AS Amount,
	|	InventoryWriteOffInventory.Ref.Correspondence AS AccountDr,
	|	CASE
	|		WHEN InventoryWriteOffInventory.Ref.StructuralUnit.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Warehouse)
	|				OR InventoryWriteOffInventory.Ref.StructuralUnit.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Retail)
	|				OR InventoryWriteOffInventory.Ref.RetireInventoryFromOperation
	|			THEN InventoryWriteOffInventory.ProductsAndServices.InventoryGLAccount
	|		ELSE InventoryWriteOffInventory.ProductsAndServices.ExpensesGLAccount
	|	END AS AccountCr,
	|	&InventoryWriteOff AS ContentOfAccountingRecord
	|INTO TemporaryTableInventory
	|FROM
	|	Document.InventoryWriteOff.Inventory AS InventoryWriteOffInventory
	|WHERE
	|	InventoryWriteOffInventory.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(TableInventory.LineNumber) AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	TableInventory.Period AS Period,
	|	TableInventory.Company AS Company,
	|	TableInventory.PlanningPeriod AS PlanningPeriod,
	|	TableInventory.StructuralUnit AS StructuralUnit,
	|	TableInventory.GLAccount AS GLAccount,
	|	TableInventory.ProductsAndServices AS ProductsAndServices,
	|	TableInventory.Characteristic AS Characteristic,
	|	TableInventory.Batch AS Batch,
	|	TableInventory.Ref AS SalesDocument,
	|	TableInventory.AccountDr AS AccountDr,
	|	TableInventory.AccountCr AS AccountCr,
	|	TableInventory.ContentOfAccountingRecord AS ContentOfAccountingRecord,
	|	TableInventory.ContentOfAccountingRecord AS Content,
	|	SUM(TableInventory.Quantity) AS Quantity,
	|	SUM(TableInventory.Amount) AS Amount
	|FROM
	|	TemporaryTableInventory AS TableInventory
	|
	|GROUP BY
	|	TableInventory.Period,
	|	TableInventory.Ref,
	|	TableInventory.Company,
	|	TableInventory.PlanningPeriod,
	|	TableInventory.StructuralUnit,
	|	TableInventory.GLAccount,
	|	TableInventory.ProductsAndServices,
	|	TableInventory.Characteristic,
	|	TableInventory.Batch,
	|	TableInventory.ContentOfAccountingRecord,
	|	TableInventory.AccountDr,
	|	TableInventory.AccountCr,
	|	TableInventory.ContentOfAccountingRecord
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableInventory.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	TableInventory.Period AS Period,
	|	TableInventory.StructuralUnit AS StructuralUnit,
	|	TableInventory.Cell AS Cell,
	|	TableInventory.Company AS Company,
	|	TableInventory.ProductsAndServices AS ProductsAndServices,
	|	TableInventory.Characteristic AS Characteristic,
	|	TableInventory.Batch AS Batch,
	|	TableInventory.Quantity AS Quantity
	|FROM
	|	TemporaryTableInventory AS TableInventory
	|WHERE
	|	TableInventory.OrderWarehouse = FALSE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableInventory.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TableInventory.Period AS Period,
	|	TableInventory.Company AS Company,
	|	TableInventory.StructuralUnit AS StructuralUnit,
	|	TableInventory.ProductsAndServices AS ProductsAndServices,
	|	TableInventory.Characteristic AS Characteristic,
	|	TableInventory.Batch AS Batch,
	|	TableInventory.Quantity AS Quantity
	|FROM
	|	TemporaryTableInventory AS TableInventory
	|WHERE
	|	TableInventory.OrderWarehouse = TRUE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableInventory.Ref.Date AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	TableInventory.Period AS EventDate,
	|	VALUE(Enum.SerialNumbersOperations.Expense) AS Operation,
	|	TableSerialNumbers.SerialNumber AS SerialNumber,
	|	&Company AS Company,
	|	TableInventory.ProductsAndServices AS ProductsAndServices,
	|	TableInventory.Characteristic AS Characteristic,
	|	TableInventory.Batch AS Batch,
	|	TableInventory.StructuralUnit AS StructuralUnit,
	|	TableInventory.Cell AS Cell,
	|	1 AS Quantity
	|FROM
	|	TemporaryTableInventory AS TableInventory
	|		INNER JOIN Document.InventoryWriteOff.SerialNumbers AS TableSerialNumbers
	|		ON TableInventory.Ref = TableSerialNumbers.Ref
	|			AND TableInventory.ConnectionKey = TableSerialNumbers.ConnectionKey
	|WHERE
	|	TableSerialNumbers.Ref = &Ref
	|	AND TableInventory.Ref = &Ref
	|	AND &UseSerialNumbers
	|	AND NOT TableInventory.OrderWarehouse";
	
	Query.SetParameter("Ref", DocumentRefInventoryWriteOff);
	Query.SetParameter("Company", StructureAdditionalProperties.ForPosting.Company);
	Query.SetParameter("UseCharacteristics", StructureAdditionalProperties.AccountingPolicy.UseCharacteristics);
	Query.SetParameter("AccountingByCells", StructureAdditionalProperties.AccountingPolicy.AccountingByCells);
	Query.SetParameter("UseBatches", StructureAdditionalProperties.AccountingPolicy.UseBatches);
	
	Query.SetParameter("UseSerialNumbers", StructureAdditionalProperties.AccountingPolicy.UseSerialNumbers);

	Query.SetParameter("InventoryWriteOff", NStr("en='Inventory write-off';ru='Списание запасов';vi='Ghi giảm vật tư'"));
	
	ResultsArray = Query.ExecuteBatch();
	
    StructureAdditionalProperties.TableForRegisterRecords.Insert("TableInventory", ResultsArray[1].Unload());
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableInventoryInWarehouses", ResultsArray[2].Unload());
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableInventoryForExpenseFromWarehouses", ResultsArray[3].Unload());
	
	// Serial numbers
	QueryResult4 = ResultsArray[4].Unload();
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableSerialNumbersGuarantees", QueryResult4);
	If StructureAdditionalProperties.AccountingPolicy.SerialNumbersBalance Then
		StructureAdditionalProperties.TableForRegisterRecords.Insert("TableSerialNumbersBalance", QueryResult4);
	Else
		StructureAdditionalProperties.TableForRegisterRecords.Insert("TableSerialNumbersBalance", New ValueTable);
	EndIf; 
	
	// Generate an empty table of postings.
	SmallBusinessServer.GenerateTransactionsTable(DocumentRefInventoryWriteOff, StructureAdditionalProperties);
	
	// Inventory by CCD
	SmallBusinessServer.GenerateTableInventoryByCCD(DocumentRefInventoryWriteOff, StructureAdditionalProperties, True);
	
	// Calculation of the inventory write-off cost.
	GenerateTableInventory(DocumentRefInventoryWriteOff, StructureAdditionalProperties);
	
	Query = New Query(
	"SELECT
	|	InventoryWriteOffInventory.Ref.Date
	|	AS Period, &Company
	|	AS Company, VALUE(Catalog.BusinessActivities.Other)
	|	AS BusinessActivity, &Amount
	|	AS AmountExpense, &Amount
	|	AS Amount, InventoryWriteOffInventory.Ref.Correspondence
	|	AS GLAccount, &ReceiptExpenses
	|AS
	|	ContentOfAccountingRecord FROM Document.InventoryWriteOff.Inventory
	|AS
	|	InventoryWriteOffInventory WHERE InventoryWriteOffInventory.Ref
	|	= &Ref AND &Amount
	|	> 0 AND InventoryWriteOffInventory.Ref.Correspondence.TypeOfAccount
	|=
	|VALUE(Enum.GLAccountsTypes.OtherExpenses) GROUP
	|	BY
	|	InventoryWriteOffInventory.Ref,
	|	InventoryWriteOffInventory.Ref.Date, InventoryWriteOffInventory.Ref.Correspondence");
	
	Query.SetParameter("Ref", DocumentRefInventoryWriteOff);
	Query.SetParameter("Company", StructureAdditionalProperties.ForPosting.Company);
	Query.SetParameter("Amount", StructureAdditionalProperties.TableForRegisterRecords.TableInventory.Total("Amount"));
	
	Query.SetParameter("ReceiptExpenses", NStr("en='Other costs (expenses)';ru='Прочих затраты (расходы)';vi='Chi phí khác'"));
	
	ResultsArray = Query.ExecuteBatch();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableIncomeAndExpenses", ResultsArray[0].Unload());
	
EndProcedure // DocumentDataInitialization()

// Controls the occurrence of negative balances.
//
Procedure RunControl(DocumentRefInventoryWriteOff, AdditionalProperties, Cancel, PostingDelete = False) Export
	
	If Not SmallBusinessServer.RunBalanceControl() Then
		Return;
	EndIf;

	StructureTemporaryTables = AdditionalProperties.ForPosting.StructureTemporaryTables;
	
	// If the "InventoryTransferAtWarehouseChange",
	// "RegisterRecordsInventoryChange" temporary tables contain records, it is necessary to control the sales of goods.
	If StructureTemporaryTables.RegisterRecordsInventoryInWarehousesChange
		OR StructureTemporaryTables.RegisterRecordsInventoryChange
		OR StructureTemporaryTables. RegisterRecordsInventoryByCCDChange
		OR StructureTemporaryTables.RegisterRecordsSerialNumbersChange Then
		
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
		|				(Company, StructuralUnit, ProductsAndServices, Characteristic, Batch, Cell) IN
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
		|				(Company, StructuralUnit, GLAccount, ProductsAndServices, Characteristic, Batch, CustomerOrder) IN
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
		|	LineNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RegisterRecordsSerialNumbersChange.LineNumber AS LineNumber,
		|	RegisterRecordsSerialNumbersChange.SerialNumber AS SerialNumberPresentation,
		|	RegisterRecordsSerialNumbersChange.StructuralUnit AS StructuralUnitPresentation,
		|	RegisterRecordsSerialNumbersChange.ProductsAndServices AS ProductsAndServicesPresentation,
		|	RegisterRecordsSerialNumbersChange.Characteristic AS CharacteristicPresentation,
		|	RegisterRecordsSerialNumbersChange.Batch AS BatchPresentation,
		|	RegisterRecordsSerialNumbersChange.Cell AS PresentationCell,
		|	SerialNumbersBalance.StructuralUnit.StructuralUnitType AS StructuralUnitType,
		|	SerialNumbersBalance.ProductsAndServices.MeasurementUnit AS MeasurementUnitPresentation,
		|	ISNULL(RegisterRecordsSerialNumbersChange.QuantityChange, 0) + ISNULL(SerialNumbersBalance.QuantityBalance, 0) AS BalanceSerialNumbers,
		|	ISNULL(SerialNumbersBalance.QuantityBalance, 0) AS QuantityBalanceSerialNumbers
		|FROM
		|	RegisterRecordsSerialNumbersChange AS RegisterRecordsSerialNumbersChange
		|		INNER JOIN AccumulationRegister.SerialNumbers.Balance(&ControlTime, ) AS SerialNumbersBalance
		|		ON RegisterRecordsSerialNumbersChange.StructuralUnit = SerialNumbersBalance.StructuralUnit
		|			AND RegisterRecordsSerialNumbersChange.ProductsAndServices = SerialNumbersBalance.ProductsAndServices
		|			AND RegisterRecordsSerialNumbersChange.Characteristic = SerialNumbersBalance.Characteristic
		|			AND RegisterRecordsSerialNumbersChange.Batch = SerialNumbersBalance.Batch
		|			AND RegisterRecordsSerialNumbersChange.SerialNumber = SerialNumbersBalance.SerialNumber
		|			AND RegisterRecordsSerialNumbersChange.Cell = SerialNumbersBalance.Cell
		|			AND (ISNULL(SerialNumbersBalance.QuantityBalance, 0) < 0)
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
			OR NOT ResultsArray[2].IsEmpty()
			OR NOT ResultsArray[3].IsEmpty() Then
			DocumentObjectInventoryWriteOff = DocumentRefInventoryWriteOff.GetObject()
		EndIf;
		
		// Negative balance of inventory in the warehouse.
		If Not ResultsArray[0].IsEmpty() Then
			QueryResultSelection = ResultsArray[0].Select();
			SmallBusinessServer.ShowMessageAboutPostingToInventoryInWarehousesRegisterErrors(DocumentObjectInventoryWriteOff, QueryResultSelection, Cancel);
		EndIf;
		
		// Negative balance of inventory and cost accounting.
		If Not ResultsArray[1].IsEmpty() Then
			QueryResultSelection = ResultsArray[1].Select();
			SmallBusinessServer.ShowMessageAboutPostingToInventoryRegisterErrors(DocumentObjectInventoryWriteOff, QueryResultSelection, Cancel);
		EndIf;
		
		// Negative balance of serial numbers in the warehouse.
		If NOT ResultsArray[2].IsEmpty() Then
			QueryResultSelection = ResultsArray[2].Select();
			SmallBusinessServer.ShowMessageAboutPostingSerialNumbersRegisterErrors(DocumentObjectInventoryWriteOff, QueryResultSelection, Cancel);
		EndIf;
		
		If Not ResultsArray[3].IsEmpty() Then
			QueryResultSelection = ResultsArray[3].Select();
			SmallBusinessServer.ShowMessageAboutPostingToInventoryByCCDRegisterErrors(DocumentObjectInventoryWriteOff, QueryResultSelection, Cancel);
		EndIf;
		
	EndIf;
	
EndProcedure // RunControl()

#Region PrintInterface

Procedure GenerateMerchandiseFillingForm(SpreadsheetDocument, CurrentDocument)
	
	Query = New Query();
	Query.SetParameter("CurrentDocument", CurrentDocument);
	Query.Text = 
	"SELECT
	|	InventoryWriteOff.Date AS DocumentDate,
	|	InventoryWriteOff.Number AS Number,
	|	InventoryWriteOff.Company.Prefix AS Prefix,
	|	InventoryWriteOff.StructuralUnit AS WarehousePresentation,
	|	InventoryWriteOff.Cell AS CellPresentation,
	|	InventoryWriteOff.Inventory.(
	|		LineNumber AS LineNumber,
	|		ProductsAndServices.Warehouse AS Warehouse,
	|		ProductsAndServices.Cell AS Cell,
	|		CASE
	|			WHEN (CAST(InventoryWriteOff.Inventory.ProductsAndServices.DescriptionFull AS String(100))) = """"
	|				THEN InventoryWriteOff.Inventory.ProductsAndServices.Description
	|			ELSE InventoryWriteOff.Inventory.ProductsAndServices.DescriptionFull
	|		END AS InventoryItem,
	|		ProductsAndServices.SKU AS SKU,
	|		ProductsAndServices.Code AS Code,
	|		MeasurementUnit.Description AS MeasurementUnit,
	|		Quantity AS Quantity,
	|		Characteristic,
	|		ProductsAndServices.ProductsAndServicesType AS ProductsAndServicesType,
	|		ConnectionKey
	|	),
	|	InventoryWriteOff.SerialNumbers.(
	|		SerialNumber,
	|		ConnectionKey
	|	)
	|FROM
	|	Document.InventoryWriteOff AS InventoryWriteOff
	|WHERE
	|	InventoryWriteOff.Ref = &CurrentDocument
	|
	|ORDER BY
	|	LineNumber";
	
	Header = Query.Execute().Select();
	Header.Next();
	
	LinesSelectionInventory = Header.Inventory.Select();
	LinesSelectionSerialNumbers = Header.SerialNumbers.Select();
	
	SpreadsheetDocument.PrintParametersName = "PRINT_PARAMETERS_InventoryWriteOff_MerchandiseFillingForm";
	
	Template = PrintManagement.PrintedFormsTemplate("Document.InventoryWriteOff.PF_MXL_MerchandiseFillingForm");
	
	If Header.DocumentDate < Date('20110101') Then
		DocumentNumber = SmallBusinessServer.GetNumberForPrinting(Header.Number, Header.Prefix);
	Else
		DocumentNumber = ObjectPrefixationClientServer.GetNumberForPrinting(Header.Number, True, True);
	EndIf;		
	
	TemplateArea = Template.GetArea("Title");
	TemplateArea.Parameters.HeaderText = NStr("en='Inventory write off No';vi='Ghi giảm vật tư số';")
											+ DocumentNumber
											+ NStr("en=' from ';vi='  '")
											+ Format(Header.DocumentDate, "DLF=DD");
											
	SpreadsheetDocument.Put(TemplateArea);
	
	TemplateArea = Template.GetArea("Warehouse");
	TemplateArea.Parameters.WarehousePresentation = Header.WarehousePresentation;
	SpreadsheetDocument.Put(TemplateArea);
	
	If Constants.FunctionalOptionAccountingByCells.Get() Then
		
		TemplateArea = Template.GetArea("Cell");
		TemplateArea.Parameters.CellPresentation = Header.CellPresentation;
		SpreadsheetDocument.Put(TemplateArea);
		
	EndIf;			
	
	TemplateArea = Template.GetArea("PrintingTime");
	TemplateArea.Parameters.PrintingTime = NStr("en='Date and time of printing: ';vi='Ngày và giờ in: ';")
										 	+ CurrentDate()
											+ NStr("en='. User: ';vi='.Người dùng: ';")
											+ Users.CurrentUser();
	SpreadsheetDocument.Put(TemplateArea);
	
	TemplateArea = Template.GetArea("TableHeader");
	SpreadsheetDocument.Put(TemplateArea);
	TemplateArea = Template.GetArea("String");
	
	While LinesSelectionInventory.Next() Do

		If Not LinesSelectionInventory.ProductsAndServicesType = Enums.ProductsAndServicesTypes.InventoryItem Then
			Continue;
		EndIf;	
			
		TemplateArea.Parameters.Fill(LinesSelectionInventory);
		
		StringSerialNumbers = WorkWithSerialNumbers.SerialNumbersStringFromSelection(LinesSelectionSerialNumbers, LinesSelectionInventory.ConnectionKey);
		TemplateArea.Parameters.InventoryItem = SmallBusinessServer.GetProductsAndServicesPresentationForPrinting(LinesSelectionInventory.InventoryItem, 
																LinesSelectionInventory.Characteristic, LinesSelectionInventory.SKU, StringSerialNumbers);
								
		SpreadsheetDocument.Put(TemplateArea);
						
	EndDo;

	TemplateArea = Template.GetArea("Total");
	SpreadsheetDocument.Put(TemplateArea);

	
EndProcedure

Function PrintForm(ObjectsArray, PrintObjects, TemplateName)
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersKey = "PrintParameters_InventoryWriteOff";

	FirstDocument = True;
	
	For Each CurrentDocument IN ObjectsArray Do
	
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		FirstDocument = False;
		
		FirstLineNumber = SpreadsheetDocument.TableHeight + 1;
		
		If TemplateName = "MerchandiseFillingForm" Then
			
			GenerateMerchandiseFillingForm(SpreadsheetDocument, CurrentDocument);
			
		// 1C - CHIENTN - 27-12-2018	
		ElsIf TemplateName = "WarehouseOutputSlip" Then
			
			GenerateWarehouseOutputSlip(SpreadsheetDocument, CurrentDocument);
	    // 1C			
		EndIf;
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, FirstLineNumber, PrintObjects, CurrentDocument);
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;
	
EndFunction // PrintForm()

// Generate printed forms of objects
//
// Incoming:
//   TemplateNames   - String    - Names of layouts separated by commas
//   ObjectsArray    - Array     - Array of refs to objects that need to be printed 
//   PrintParameters - Structure - Structure of additional printing parameters
//
// Outgoing:
//   PrintFormsCollection - Values table - Generated table documents 
//   OutputParameters     - Structure    - Parameters of generated table documents
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.NeedToPrintTemplate(PrintFormsCollection, "MerchandiseFillingForm") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "MerchandiseFillingForm", NStr("en='Merchandise filling form';vi='Biểu mẫu điền hàng hóa';"), PrintForm(ObjectsArray, PrintObjects, "MerchandiseFillingForm"));
		
	EndIf;
	
	// 1C - CHIENTN - 27-12-2018	
	If PrintManagement.NeedToPrintTemplate(PrintFormsCollection, "WarehouseOutputSlip") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "WarehouseOutputSlip", NStr("en='Warehouse output slip (02-VT)';vi='Phiếu xuất kho (02-VT)';"), PrintForm(ObjectsArray, PrintObjects, "WarehouseOutputSlip"));
		
	EndIf;	
	// 1C 

	
	// parameters of sending printing forms by email
	SmallBusinessServer.FillSendingParameters(OutputParameters.SendingParameters, ObjectsArray, PrintFormsCollection);
	
EndProcedure

// Fills in the list of printing commands.
// 
// Parameters:
//   PrintCommands - ValueTable - see fields' content in the PrintManagement.CreatePrintCommandsCollection function.
//
Procedure AddPrintCommands(PrintCommands) Export
	
	// 1C - CHIENTN - 27-12-2018		
	PrintCommand = PrintCommands.Add();
	PrintCommand.ID							= "WarehouseOutputSlip";
	PrintCommand.Presentation				= NStr("en='Warehouse output slip (02-VT)';ru='Расходный ордер на товары (02-VT)';vi='Phiếu xuất kho (02-VT)'");
	PrintCommand.CheckPostingBeforePrint	= False;
	PrintCommand.Order						= 1;
	// 1C      
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.ID = "MerchandiseFillingForm";
	PrintCommand.Presentation = NStr("en='Goods content form';ru='Бланк товарного наполнения';vi='Mẫu bổ sung hàng hóa'");
	PrintCommand.FormsList = "DocumentForm,ListForm";
	PrintCommand.CheckPostingBeforePrint = False;
	PrintCommand.Order = 2;
	
EndProcedure

// 1C - CHIENTN - 27-12-2018
Procedure GenerateWarehouseOutputSlip(SpreadsheetDocument, CurrentDocument)
			
	Query = New Query();
	Query.SetParameter("CurrentDocument", CurrentDocument);
	Query.Text = 		
	"SELECT
	|	InventoryWriteOff.Date AS DocumentDate,
	|	InventoryWriteOff.Number AS Number,
	|	InventoryWriteOff.Company AS Company,
	|	InventoryWriteOff.Company.Prefix AS Prefix,
	|	InventoryWriteOff.StructuralUnit AS Warehouse,
	|	InventoryWriteOff.Author AS Author,
	|	InventoryWriteOff.Comment AS Comment,
	|	InventoryWriteOff.Inventory.(
	|		LineNumber AS LineNumber,
	|		CASE
	|			WHEN (CAST(InventoryWriteOff.Inventory.ProductsAndServices.DescriptionFull AS STRING(1000))) = """"
	|				THEN InventoryWriteOff.Inventory.ProductsAndServices.Description
	|			ELSE CAST(InventoryWriteOff.Inventory.ProductsAndServices.DescriptionFull AS STRING(1000))
	|		END AS Product,
	|		ProductsAndServices.SKU AS SKU,
	|		ProductsAndServices.Code AS ProductCode,
	|		MeasurementUnit AS Unit,
	|		Quantity AS Quantity
	|	) AS Inventory
	|FROM
	|	Document.InventoryWriteOff AS InventoryWriteOff
	|WHERE
	|	InventoryWriteOff.Ref = &CurrentDocument";

	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	InventorySelection = Selection.Inventory.Select();
				
	SpreadsheetDocument.PrintParametersName = "PRINT_PARAMETERS_PF_MXL_WarehouseOutputSlip_02VT";
	
	Template = PrintManagement.GetTemplate("CommonTemplate.PF_MXL_WarehouseOutputSlip_02VT");
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
	
	While InventorySelection.Next() Do  				
		TemplateArea.Parameters.Fill(InventorySelection);								
		SpreadsheetDocument.Put(TemplateArea);
		
		////Amount		= Amount	+ LinesSelectionProducts.Amount;
		////VATAmount	= VATAmount	+ LinesSelectionProducts.VATAmount;
		////Total		= Total		+ LinesSelectionProducts.Total;
		Quantity	= Quantity  + InventorySelection.Quantity;  				
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
	
EndProcedure // GenerateWarehouseOutputSlip()

#EndRegion

#EndIf