#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableInventory(DocumentRefPurchaseInvoice, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	MIN(TableInventory.LineNumber) AS LineNumber,
	|	TableInventory.RecordType AS RecordType,
	|	TableInventory.Period AS Period,
	|	TableInventory.Company AS Company,
	|	VALUE(Catalog.PlanningPeriods.Actual) AS PlanningPeriod,
	|	TableInventory.CorrOrganization AS CorrOrganization,
	|	ISNULL(TableInventory.StructuralUnit, VALUE(Catalog.Counterparties.EmptyRef)) AS StructuralUnit,
	|	ISNULL(TableInventory.StructuralUnitCorr, VALUE(Catalog.StructuralUnits.EmptyRef)) AS StructuralUnitCorr,
	|	TableInventory.GLAccount AS GLAccount,
	|	TableInventory.CorrGLAccount AS CorrGLAccount,
	|	TableInventory.ProductsAndServices AS ProductsAndServices,
	|	TableInventory.ProductsAndServicesCorr AS ProductsAndServicesCorr,
	|	TableInventory.Characteristic AS Characteristic,
	|	TableInventory.CharacteristicCorr AS CharacteristicCorr,
	|	TableInventory.Batch AS Batch,
	|	TableInventory.BatchCorr AS BatchCorr,
	|	TableInventory.VATRate AS VATRate,
	|	CASE
	|		WHEN TableInventory.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromCustomer)
	|			THEN TableInventory.BasisDocument.Responsible
	|		ELSE VALUE(Catalog.Employees.EmptyRef)
	|	END AS Responsible,
	|	CASE
	|		WHEN TableInventory.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromCustomer)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Return,
	|	CASE
	|		WHEN TableInventory.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromCustomer)
	|				AND (ISNULL(TableInventory.BasisDocument.OperationKind, VALUE(Enum.OperationKindsCustomerInvoice.EmptyRef)) = VALUE(Enum.OperationKindsCustomerInvoice.SaleToCustomer)
	|					OR ISNULL(TableInventory.BasisDocument.OperationKind, VALUE(Enum.OperationKindsCustomerOrder.EmptyRef)) = VALUE(Enum.OperationKindsCustomerOrder.WorkOrder))
	|			THEN TableInventory.BasisDocument
	|		ELSE UNDEFINED
	|	END AS SalesDocument,
	|	CASE
	|		WHEN TableInventory.Order REFS Document.CustomerOrder
	|				AND Not TableInventory.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromCustomer)
	|				AND Not(TableInventory.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionIntoProcessing)
	|						AND Not FunctionalOptionInventoryReservation.Value)
	|			THEN TableInventory.Order
	|		ELSE VALUE(Document.CustomerOrder.EmptyRef)
	|	END AS CustomerOrder,
	|	CASE
	|		WHEN TableInventory.Order REFS Document.CustomerOrder
	|				AND TableInventory.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromCustomer)
	|			THEN TableInventory.Order
	|		ELSE VALUE(Document.CustomerOrder.EmptyRef)
	|	END AS OrderSales,
	|	CASE
	|		WHEN TableInventory.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromCustomer)
	|			THEN TableInventory.DepartmentSales
	|		ELSE VALUE(Catalog.StructuralUnits.EmptyRef)
	|	END AS Department,
	|	CASE
	|		WHEN TableInventory.Order REFS Document.PurchaseOrder
	|				AND (TableInventory.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceiptFromVendor)
	|					OR TableInventory.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionForCommission))
	|			THEN TableInventory.Order
	|		ELSE UNDEFINED
	|	END AS SupplySource,
	|	CASE
	|		WHEN TableInventory.CorrOrder REFS Document.CustomerOrder
	|			THEN TableInventory.CorrOrder
	|		ELSE VALUE(Document.CustomerOrder.EmptyRef)
	|	END AS CustomerCorrOrder,
	|	TableInventory.FixedCost AS FixedCost,
	|	TableInventory.ContentOfAccountingRecord AS ContentOfAccountingRecord,
	|	SUM(CASE
	|			WHEN TableInventory.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromCustomer)
	|				THEN -1 * TableInventory.Quantity
	|			ELSE TableInventory.Quantity
	|		END) AS Quantity,
	|	SUM(CASE
	|			WHEN TableInventory.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionForCommission)
	|					OR TableInventory.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionIntoProcessing)
	|					OR TableInventory.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionForSafeCustody)
	|					OR TableInventory.ProductsOnCommission
	|					OR TableInventory.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromCustomer)
	|						AND (ISNULL(TableInventory.BasisDocument.OperationKind, VALUE(Enum.OperationKindsCustomerInvoice.EmptyRef)) = VALUE(Enum.OperationKindsCustomerInvoice.SaleToCustomer)
	|							OR ISNULL(TableInventory.BasisDocument.OperationKind, VALUE(Enum.OperationKindsCustomerOrder.EmptyRef)) = VALUE(Enum.OperationKindsCustomerOrder.WorkOrder))
	|				THEN 0
	|			WHEN TableInventory.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromCustomer)
	|				THEN -1 * TableInventory.Cost
	|			WHEN TableInventory.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceiptFromVendor)
	|					AND TableInventory.IncludeExpensesInCostPrice
	//( elmi #11
	//| 			THEN TableInventory.Amount + TableInventory.AmountExpenses
	//|			ELSE TableInventory.Amount
	| 			THEN TableInventory.Amount + TableInventory.AmountExpenses - TableInventory.VATAmount  
	|			ELSE TableInventory.Amount - TableInventory.VATAmount                                  
	//) elmi
	|		END) AS Amount,
	|	SUM(CASE
	|			WHEN TableInventory.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromCustomer)
	|					AND ISNULL(TableInventory.BasisDocument.OperationKind, VALUE(Enum.OperationKindsCustomerInvoice.EmptyRef)) <> VALUE(Enum.OperationKindsCustomerInvoice.SaleToCustomer)
	|					AND ISNULL(TableInventory.BasisDocument.OperationKind, VALUE(Enum.OperationKindsCustomerOrder.EmptyRef)) <> VALUE(Enum.OperationKindsCustomerOrder.WorkOrder)
	|				THEN TableInventory.Cost
	|			ELSE 0
	|		END) AS Cost
	|FROM
	|	TemporaryTableInventory AS TableInventory,
	|	Constant.FunctionalOptionInventoryReservation AS FunctionalOptionInventoryReservation
	|WHERE
	|	Not TableInventory.RetailTransferAccrualAccounting
	|
	|GROUP BY
	|	TableInventory.Period,
	|	TableInventory.Company,
	|	TableInventory.CorrOrganization,
	|	TableInventory.StructuralUnit,
	|	TableInventory.StructuralUnitCorr,
	|	TableInventory.GLAccount,
	|	TableInventory.CorrGLAccount,
	|	TableInventory.ProductsAndServices,
	|	TableInventory.Characteristic,
	|	TableInventory.Batch,
	|	TableInventory.ProductsAndServicesCorr,
	|	TableInventory.CharacteristicCorr,
	|	TableInventory.BatchCorr,
	|	TableInventory.VATRate,
	|	CASE
	|		WHEN TableInventory.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromCustomer)
	|			THEN TableInventory.BasisDocument.Responsible
	|		ELSE VALUE(Catalog.Employees.EmptyRef)
	|	END,
	|	CASE
	|		WHEN TableInventory.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromCustomer)
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	TableInventory.FixedCost,
	|	TableInventory.ContentOfAccountingRecord,
	|	TableInventory.RecordType,
	|	CASE
	|		WHEN TableInventory.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromCustomer)
	|				AND (ISNULL(TableInventory.BasisDocument.OperationKind, VALUE(Enum.OperationKindsCustomerInvoice.EmptyRef)) = VALUE(Enum.OperationKindsCustomerInvoice.SaleToCustomer)
	|					OR ISNULL(TableInventory.BasisDocument.OperationKind, VALUE(Enum.OperationKindsCustomerOrder.EmptyRef)) = VALUE(Enum.OperationKindsCustomerOrder.WorkOrder))
	|			THEN TableInventory.BasisDocument
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN TableInventory.Order REFS Document.CustomerOrder
	|				AND Not TableInventory.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromCustomer)
	|				AND Not(TableInventory.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionIntoProcessing)
	|						AND Not FunctionalOptionInventoryReservation.Value)
	|			THEN TableInventory.Order
	|		ELSE VALUE(Document.CustomerOrder.EmptyRef)
	|	END,
	|	CASE
	|		WHEN TableInventory.Order REFS Document.CustomerOrder
	|				AND TableInventory.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromCustomer)
	|			THEN TableInventory.Order
	|		ELSE VALUE(Document.CustomerOrder.EmptyRef)
	|	END,
	|	CASE
	|		WHEN TableInventory.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromCustomer)
	|			THEN TableInventory.DepartmentSales
	|		ELSE VALUE(Catalog.StructuralUnits.EmptyRef)
	|	END,
	|	CASE
	|		WHEN TableInventory.Order REFS Document.PurchaseOrder
	|				AND (TableInventory.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceiptFromVendor)
	|					OR TableInventory.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionForCommission))
	|			THEN TableInventory.Order
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN TableInventory.CorrOrder REFS Document.CustomerOrder
	|			THEN TableInventory.CorrOrder
	|		ELSE VALUE(Document.CustomerOrder.EmptyRef)
	|	END";
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableInventory", QueryResult.Unload());
	
	If DocumentRefPurchaseInvoice.OperationKind = Enums.OperationKindsSupplierInvoice.ReceiptFromVendor
	 OR DocumentRefPurchaseInvoice.OperationKind = Enums.OperationKindsSupplierInvoice.ReceptionForCommission
	 OR DocumentRefPurchaseInvoice.OperationKind = Enums.OperationKindsSupplierInvoice.ReceptionForSafeCustody Then
		
		GenerateTableInventoryReceipt(DocumentRefPurchaseInvoice, StructureAdditionalProperties);
		
	ElsIf DocumentRefPurchaseInvoice.OperationKind = Enums.OperationKindsSupplierInvoice.ReturnFromAgent
		OR DocumentRefPurchaseInvoice.OperationKind = Enums.OperationKindsSupplierInvoice.ReturnFromSubcontractor
		OR DocumentRefPurchaseInvoice.OperationKind = Enums.OperationKindsSupplierInvoice.ReturnFromSafeCustody Then
		
		GenerateTableInventoryReturn(DocumentRefPurchaseInvoice, StructureAdditionalProperties);
		
	EndIf;
		
	If DocumentRefPurchaseInvoice.OperationKind = Enums.OperationKindsSupplierInvoice.ReceiptFromVendor Then
		
		GenerateTableCustomerInvoices(DocumentRefPurchaseInvoice, StructureAdditionalProperties);
		
	EndIf;
	
EndProcedure // GenerateTableInventory()



// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableInventoryReceipt(DocumentRefPurchaseInvoice, StructureAdditionalProperties)
	
	TableInventory = StructureAdditionalProperties.TableForRegisterRecords.TableInventory.CopyColumns();
	TableOrdersPlacement = StructureAdditionalProperties.TableForRegisterRecords.TableOrdersPlacement.CopyColumns();
	
	PlacementsNumber = StructureAdditionalProperties.TableForRegisterRecords.TableOrdersPlacement.Total("Quantity");
	
	For n = 0 To StructureAdditionalProperties.TableForRegisterRecords.TableInventory.Count() - 1 Do
		
		RowTableInventory = TableInventory.Add();
		FillPropertyValues(RowTableInventory, StructureAdditionalProperties.TableForRegisterRecords.TableInventory[n]);
		
		StructureForSearch = New Structure;
		StructureForSearch.Insert("SupplySource",	RowTableInventory.SupplySource);
		StructureForSearch.Insert("ProductsAndServices",			RowTableInventory.ProductsAndServices);
		StructureForSearch.Insert("Characteristic",		RowTableInventory.Characteristic);
		
		RowTableInventory.CustomerOrder = Documents.CustomerOrder.EmptyRef();
		
		If PlacementsNumber = 0 Then
			Continue;
		EndIf;
		
		PlacedOrdersArray = StructureAdditionalProperties.TableForRegisterRecords.TableOrdersPlacement.FindRows(StructureForSearch);
		
		RowTableInventoryQuantity = RowTableInventory.Quantity;
		
		If PlacedOrdersArray.Count() > 0 Then
			
			For Each ArrayRow IN PlacedOrdersArray Do
				
				If RowTableInventoryQuantity > 0 AND ArrayRow.Quantity >= RowTableInventoryQuantity Then
					
					// Placement
					NewRowTableOrdersPlacement = TableOrdersPlacement.Add();
					FillPropertyValues(NewRowTableOrdersPlacement, ArrayRow);
					
					NewRowTableOrdersPlacement.Quantity = RowTableInventoryQuantity;
					
					// Inventory
					RowTableInventory.CustomerOrder = ArrayRow.CustomerOrder;
					RowTableInventoryQuantity = 0;
					
				ElsIf RowTableInventoryQuantity > 0 AND ArrayRow.Quantity < RowTableInventoryQuantity Then
					
					// Placement
					NewRowTableOrdersPlacement = TableOrdersPlacement.Add();
					FillPropertyValues(NewRowTableOrdersPlacement, ArrayRow);
					
					// Inventory
					AmountToBeWrittenOff = Round(RowTableInventory.Amount * ArrayRow.Quantity / RowTableInventoryQuantity, 2, 1);
					
					NewRowTableSupplies = TableInventory.Add();
					FillPropertyValues(NewRowTableSupplies, RowTableInventory);
					NewRowTableSupplies.CustomerOrder = ArrayRow.CustomerOrder;
					NewRowTableSupplies.Quantity = ArrayRow.Quantity;
					NewRowTableSupplies.Amount = AmountToBeWrittenOff;
					
					RowTableInventoryQuantity = RowTableInventoryQuantity - ArrayRow.Quantity;
					
					RowTableInventory.Quantity = RowTableInventoryQuantity;
					RowTableInventory.Amount = RowTableInventory.Amount - AmountToBeWrittenOff;
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
	StructureAdditionalProperties.TableForRegisterRecords.TableInventory = TableInventory;
	
	StructureAdditionalProperties.TableForRegisterRecords.TableOrdersPlacement = TableOrdersPlacement;
	TableOrdersPlacement = Undefined;
	
EndProcedure // GenerateTableInventoryReceipt()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableCustomerInvoices(DocumentRefPurchaseInvoice, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	MIN(TableInventory.LineNumber) AS LineNumber,
	|	TableInventory.RecordType AS RecordType,
	|	TableInventory.Period AS Period,
	|	TableInventory.Company AS Company,
	|	TableInventory.StructuralUnit AS StructuralUnit,
	|	TableInventory.GLAccount AS GLAccount,
	|	VALUE(Catalog.ProductsAndServices.EmptyRef) AS ProductsAndServices,
	|	TableInventory.Characteristic AS Characteristic,
	|	TableInventory.Batch AS Batch,
	|	TableInventory.Order AS CustomerOrder,
	|	0 AS Quantity,
	//( elmi #11
	//|	SUM(TableInventory.Amount) AS Amount,
	|	SUM(TableInventory.Amount - TableInventory.VATAmount ) КАК Amount,
	//) elmi
	|	TRUE AS FixedCost,
	|	&OtherExpenses AS ContentOfAccountingRecord
	|FROM
	|	TemporaryTableExpenses AS TableInventory
	|WHERE
	|	(NOT TableInventory.IncludeExpensesInCostPrice)
	|	AND (TableInventory.TypeOfAccount = VALUE(Enum.GLAccountsTypes.UnfinishedProduction)
	|			OR TableInventory.TypeOfAccount = VALUE(Enum.GLAccountsTypes.IndirectExpenses))
	|
	|GROUP BY
	|	TableInventory.Period,
	|	TableInventory.Company,
	|	TableInventory.StructuralUnit,
	|	TableInventory.GLAccount,
	|	TableInventory.Characteristic,
	|	TableInventory.Batch,
	|	TableInventory.Order,
	|	TableInventory.RecordType";
	
	Query.SetParameter("OtherExpenses", NStr("en='Expense recording';ru='Отражение затрат';vi='Phản ánh chi phí'"));
	
	QueryResult = Query.Execute();
	
	If StructureAdditionalProperties.TableForRegisterRecords.TableInventory.Count() = 0 Then
		StructureAdditionalProperties.TableForRegisterRecords.Insert("TableInventory", QueryResult.Unload());		
	Else
		
		Selection = QueryResult.Select();
		While Selection.Next() Do
			
			NewRow = StructureAdditionalProperties.TableForRegisterRecords.TableInventory.Add();
			FillPropertyValues(NewRow, Selection);
			
		EndDo;
		
	EndIf;
	
EndProcedure // GenerateTableInventoryExpenses()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableInventoryReturn(DocumentRefPurchaseInvoice, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	
	// Setting the exclusive lock for the controlled inventory balances.
	Query.Text =
	"SELECT
	|	TableInventory.CorrOrganization AS Company,
	|	TableInventory.StructuralUnitCorr AS StructuralUnit,
	|	TableInventory.CorrGLAccount AS GLAccount,
	|	TableInventory.ProductsAndServicesCorr AS ProductsAndServices,
	|	TableInventory.CharacteristicCorr AS Characteristic,
	|	TableInventory.BatchCorr AS Batch,
	|	CASE
	|		WHEN TableInventory.CorrOrder REFS Document.CustomerOrder
	|			THEN TableInventory.CorrOrder
	|		ELSE VALUE(Document.CustomerOrder.EmptyRef)
	|	END AS CustomerOrder
	|FROM
	|	TemporaryTableInventory AS TableInventory
	|WHERE
	|	(NOT TableInventory.RetailTransferAccrualAccounting)
	|
	|GROUP BY
	|	TableInventory.CorrOrganization,
	|	TableInventory.StructuralUnitCorr,
	|	TableInventory.CorrGLAccount,
	|	TableInventory.ProductsAndServicesCorr,
	|	TableInventory.CharacteristicCorr,
	|	TableInventory.BatchCorr,
	|	CASE
	|		WHEN TableInventory.CorrOrder REFS Document.CustomerOrder
	|			THEN TableInventory.CorrOrder
	|		ELSE VALUE(Document.CustomerOrder.EmptyRef)
	|	END";
	
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
	|	InventoryBalances.CustomerOrder AS CustomerOrder,
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
	|		InventoryBalances.CustomerOrder AS CustomerOrder,
	|		SUM(InventoryBalances.QuantityBalance) AS QuantityBalance,
	|		SUM(InventoryBalances.AmountBalance) AS AmountBalance
	|	FROM
	|		AccumulationRegister.Inventory.Balance(
	|				&ControlTime,
	|				(Company, StructuralUnit, GLAccount, ProductsAndServices, Characteristic, Batch, CustomerOrder) In
	|					(SELECT
	|						TableInventory.CorrOrganization,
	|						TableInventory.StructuralUnitCorr,
	|						TableInventory.CorrGLAccount,
	|						TableInventory.ProductsAndServicesCorr,
	|						TableInventory.CharacteristicCorr,
	|						TableInventory.BatchCorr,
	|						CASE
	|							WHEN TableInventory.CorrOrder REFS Document.CustomerOrder
	|								THEN TableInventory.CorrOrder
	|							ELSE VALUE(Document.CustomerOrder.EmptyRef)
	|						END
	|					FROM
	|						TemporaryTableInventory AS TableInventory)) AS InventoryBalances
	|	
	|	GROUP BY
	|		InventoryBalances.Company,
	|		InventoryBalances.StructuralUnit,
	|		InventoryBalances.GLAccount,
	|		InventoryBalances.ProductsAndServices,
	|		InventoryBalances.Characteristic,
	|		InventoryBalances.Batch,
	|		InventoryBalances.CustomerOrder
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
	|		DocumentRegisterRecordsInventory.CustomerOrder,
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
	|	InventoryBalances.Batch,
	|	InventoryBalances.CustomerOrder";
	
	Query.SetParameter("Ref", DocumentRefPurchaseInvoice);
	Query.SetParameter("ControlTime", New Boundary(StructureAdditionalProperties.ForPosting.PointInTime, BoundaryType.Including));
	Query.SetParameter("ControlPeriod", StructureAdditionalProperties.ForPosting.PointInTime.Date);
	
	QueryResult = Query.Execute();
	
	TableInventoryBalances = QueryResult.Unload();
	TableInventoryBalances.Indexes.Add("Company,StructuralUnit,GLAccount,ProductsAndServices,Characteristic,Batch,CustomerOrder");
	
	TableInventory = StructureAdditionalProperties.TableForRegisterRecords.TableInventory.CopyColumns();
	For n = 0 To StructureAdditionalProperties.TableForRegisterRecords.TableInventory.Count() - 1 Do
		
		RowTableInventory = StructureAdditionalProperties.TableForRegisterRecords.TableInventory[n];
				
		StructureForSearch = New Structure;
		StructureForSearch.Insert("Company", RowTableInventory.Company);
		StructureForSearch.Insert("StructuralUnit", RowTableInventory.StructuralUnitCorr);
		StructureForSearch.Insert("GLAccount", RowTableInventory.CorrGLAccount);
		StructureForSearch.Insert("ProductsAndServices", RowTableInventory.ProductsAndServicesCorr);
		StructureForSearch.Insert("Characteristic", RowTableInventory.CharacteristicCorr);
		StructureForSearch.Insert("Batch", RowTableInventory.BatchCorr);

		StructureForSearch.Insert("CustomerOrder", RowTableInventory.CustomerCorrOrder);
		
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
			
			// Expense.
			TableRowExpense = TableInventory.Add();
			FillPropertyValues(TableRowExpense, RowTableInventory);
			
			TableRowExpense.Amount = - AmountToBeWrittenOff;
			TableRowExpense.Quantity = - QuantityWanted;
			
			TableRowExpense.CustomerOrder = Documents.CustomerOrder.EmptyRef();
			
			TableRowExpense.Return = True;
			
			// Generate postings.
			If Round(AmountToBeWrittenOff, 2, 1) <> 0 Then
				RowTableManagerial = StructureAdditionalProperties.TableForRegisterRecords.TableManagerial.Add();
				FillPropertyValues(RowTableManagerial, RowTableInventory);
				RowTableManagerial.AccountDr = RowTableInventory.GLAccount;
				RowTableManagerial.CurrencyDr = Undefined;
				RowTableManagerial.AmountCurDr = 0;
				RowTableManagerial.AccountCr = RowTableInventory.CorrGLAccount;
				RowTableManagerial.CurrencyCr = Undefined;
				RowTableManagerial.AmountCurCr = 0;
				RowTableManagerial.Amount = - AmountToBeWrittenOff;
			EndIf;
			
			// Receipt.
			TableRowReceipt = TableInventory.Add();
			FillPropertyValues(TableRowReceipt, RowTableInventory,,"StructuralUnit, StructuralUnitCorr");
			
			TableRowReceipt.RecordType = AccumulationRecordType.Receipt;
						
			TableRowReceipt.Company = RowTableInventory.CorrOrganization;
			TableRowReceipt.StructuralUnit = RowTableInventory.StructuralUnitCorr;
			TableRowReceipt.GLAccount = RowTableInventory.CorrGLAccount;
			TableRowReceipt.ProductsAndServices = RowTableInventory.ProductsAndServicesCorr;
			TableRowReceipt.Characteristic = RowTableInventory.CharacteristicCorr;
			TableRowReceipt.Batch = RowTableInventory.BatchCorr;
			
			TableRowReceipt.CustomerOrder = RowTableInventory.CustomerCorrOrder;
			                                                          			
			TableRowReceipt.CorrOrganization = RowTableInventory.Company;
			TableRowReceipt.StructuralUnitCorr = RowTableInventory.StructuralUnit;
			TableRowReceipt.CorrGLAccount = RowTableInventory.GLAccount;
			TableRowReceipt.ProductsAndServicesCorr = RowTableInventory.ProductsAndServices;
			TableRowReceipt.CharacteristicCorr = RowTableInventory.Characteristic;
			TableRowReceipt.BatchCorr = RowTableInventory.Batch;
									
			TableRowReceipt.CustomerCorrOrder = Documents.CustomerOrder.EmptyRef();
			
			TableRowReceipt.Amount = - AmountToBeWrittenOff;
			TableRowReceipt.Quantity = - QuantityWanted;
			
			TableRowReceipt.ContentOfAccountingRecord = NStr("en='Inventory movement';ru='Перемещение запасов';vi='Điều chuyển vật tư'");
			
			TableRowReceipt.GLAccount = RowTableInventory.CorrGLAccount;
			
			TableRowReceipt.Return = True;
			
		EndIf;
		
	EndDo;
	
	StructureAdditionalProperties.TableForRegisterRecords.TableInventory = TableInventory;
	
EndProcedure // GenerateTableInventoryReturn()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableIncomeAndExpenses(DocumentRefPurchaseInvoice, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	1 AS Ordering,
	|	MIN(TableIncomeAndExpenses.LineNumber) AS LineNumber,
	|	TableIncomeAndExpenses.Period AS Period,
	|	TableIncomeAndExpenses.Company AS Company,
	|	TableIncomeAndExpenses.StructuralUnit AS StructuralUnit,
	|	CASE
	|		WHEN TableIncomeAndExpenses.TypeOfAccount = VALUE(Enum.GLAccountsTypes.OtherExpenses)
	|			THEN VALUE(Catalog.BusinessActivities.Other)
	|		ELSE TableIncomeAndExpenses.BusinessActivity
	|	END AS BusinessActivity,
	|	CASE
	|		WHEN TableIncomeAndExpenses.TypeOfAccount = VALUE(Enum.GLAccountsTypes.OtherExpenses)
	|			THEN UNDEFINED
	|		ELSE TableIncomeAndExpenses.Order
	|	END AS CustomerOrder,
	|	TableIncomeAndExpenses.GLAccount AS GLAccount,
	|	CAST(&OtherExpenses AS String(100)) AS ContentOfAccountingRecord,
	|	0 AS AmountIncome,
	//( elmi #11
	//|	SUM(TableIncomeAndExpenses.Amount) AS AmountExpenses,
	//|	SUM(TableIncomeAndExpenses.Amount) AS Amount
	|	SUM(TableIncomeAndExpenses.Amount-TableIncomeAndExpenses.VATAmount) AS AmountExpense,
	|	SUM(TableIncomeAndExpenses.Amount-TableIncomeAndExpenses.VATAmount) AS Amount
	//) elmi
	|FROM
	|	TemporaryTableExpenses AS TableIncomeAndExpenses
	|WHERE
	|	TableIncomeAndExpenses.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceiptFromVendor)
	|	AND Not TableIncomeAndExpenses.IncludeExpensesInCostPrice
	|	AND (TableIncomeAndExpenses.TypeOfAccount = VALUE(Enum.GLAccountsTypes.Expenses)
	|			OR TableIncomeAndExpenses.TypeOfAccount = VALUE(Enum.GLAccountsTypes.OtherExpenses))
	|
	|GROUP BY
	|	TableIncomeAndExpenses.Period,
	|	TableIncomeAndExpenses.Company,
	|	TableIncomeAndExpenses.StructuralUnit,
	|	CASE
	|		WHEN TableIncomeAndExpenses.TypeOfAccount = VALUE(Enum.GLAccountsTypes.OtherExpenses)
	|			THEN VALUE(Catalog.BusinessActivities.Other)
	|		ELSE TableIncomeAndExpenses.BusinessActivity
	|	END,
	|	CASE
	|		WHEN TableIncomeAndExpenses.TypeOfAccount = VALUE(Enum.GLAccountsTypes.OtherExpenses)
	|			THEN UNDEFINED
	|		ELSE TableIncomeAndExpenses.Order
	|	END,
	|	TableIncomeAndExpenses.GLAccount
	|
	|UNION ALL
	|
	|SELECT
	|	2,
	|	MIN(TableIncomeAndExpenses.LineNumber),
	|	TableIncomeAndExpenses.Period,
	|	TableIncomeAndExpenses.Company,
	|	TableIncomeAndExpenses.DepartmentSales,
	|	TableIncomeAndExpenses.BusinessActivitySales,
	|	TableIncomeAndExpenses.Order,
	|	TableIncomeAndExpenses.AccountStatementSales,
	|	CAST(&IncomeReflection AS String(100)),
	//( elmi #11
	//|	-SUM(TableIncomeAndExpenses.Amount),
	//|	0,
	//|	-SUM(TableIncomeAndExpenses.Amount)
	|	-SUM(TableIncomeAndExpenses.Amount-TableIncomeAndExpenses.VATAmount),
	|	0,
	|	-SUM(TableIncomeAndExpenses.Amount-TableIncomeAndExpenses.VATAmount)
	//) elmi
	|FROM
	|	TemporaryTableInventory AS TableIncomeAndExpenses
	|WHERE
	|	TableIncomeAndExpenses.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromCustomer)
	|	AND Not TableIncomeAndExpenses.ProductsOnCommission
	|
	|GROUP BY
	|	TableIncomeAndExpenses.Period,
	|	TableIncomeAndExpenses.Company,
	|	TableIncomeAndExpenses.DepartmentSales,
	|	TableIncomeAndExpenses.BusinessActivitySales,
	|	TableIncomeAndExpenses.Order,
	|	TableIncomeAndExpenses.AccountStatementSales
	|
	|UNION ALL
	|
	|SELECT
	|	3,
	|	MIN(TableIncomeAndExpenses.LineNumber),
	|	TableIncomeAndExpenses.Period,
	|	TableIncomeAndExpenses.Company,
	|	TableIncomeAndExpenses.DepartmentSales,
	|	TableIncomeAndExpenses.BusinessActivitySales,
	|	TableIncomeAndExpenses.Order,
	|	TableIncomeAndExpenses.GLAccountCost,
	|	CAST(&CostsReflection AS String(100)),
	|	0,
	|	-SUM(TableIncomeAndExpenses.Cost),
	|	-SUM(TableIncomeAndExpenses.Cost)
	|FROM
	|	TemporaryTableInventory AS TableIncomeAndExpenses
	|WHERE
	|	TableIncomeAndExpenses.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromCustomer)
	|	AND ISNULL(TableIncomeAndExpenses.BasisDocument.OperationKind, VALUE(Enum.OperationKindsCustomerInvoice.EmptyRef)) <> VALUE(Enum.OperationKindsCustomerInvoice.SaleToCustomer)
	|	AND ISNULL(TableIncomeAndExpenses.BasisDocument.OperationKind, VALUE(Enum.OperationKindsCustomerOrder.EmptyRef)) <> VALUE(Enum.OperationKindsCustomerOrder.WorkOrder)
	|	AND Not TableIncomeAndExpenses.ProductsOnCommission
	|	AND TableIncomeAndExpenses.Cost > 0
	|
	|GROUP BY
	|	TableIncomeAndExpenses.Period,
	|	TableIncomeAndExpenses.Company,
	|	TableIncomeAndExpenses.DepartmentSales,
	|	TableIncomeAndExpenses.BusinessActivitySales,
	|	TableIncomeAndExpenses.Order,
	|	TableIncomeAndExpenses.GLAccountCost
	|
	|UNION ALL
	|
	|SELECT
	|	4,
	|	1,
	|	DocumentTable.Date,
	|	DocumentTable.Company,
	|	UNDEFINED,
	|	VALUE(Catalog.BusinessActivities.Other),
	|	UNDEFINED,
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|			THEN &NegativeExchangeDifferenceAccountOfAccounting
	|		ELSE &PositiveExchangeDifferenceGLAccount
	|	END,
	|	&ExchangeDifference,
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|			THEN 0
	|		ELSE -DocumentTable.AmountOfExchangeDifferences
	|	END,
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|			THEN DocumentTable.AmountOfExchangeDifferences
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|			THEN DocumentTable.AmountOfExchangeDifferences
	|		ELSE -DocumentTable.AmountOfExchangeDifferences
	|	END
	|FROM
	|	(SELECT
	|		TableOfExchangeRateDifferencesAccountsPayable.Date AS Date,
	|		TableOfExchangeRateDifferencesAccountsPayable.Company AS Company,
	|		SUM(TableOfExchangeRateDifferencesAccountsPayable.AmountOfExchangeDifferences) AS AmountOfExchangeDifferences
	|	FROM
	|		(SELECT
	|			DocumentTable.Date AS Date,
	|			DocumentTable.Company AS Company,
	|			DocumentTable.AmountOfExchangeDifferences AS AmountOfExchangeDifferences
	|		FROM
	|			TemporaryTableOfExchangeRateDifferencesAccountsPayable AS DocumentTable
	|		WHERE
	|			DocumentTable.SettlementsType = VALUE(Enum.SettlementsTypes.Debt)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			DocumentTable.Date,
	|			DocumentTable.Company,
	|			DocumentTable.AmountOfExchangeDifferences
	|		FROM
	|			TemporaryTableOfExchangeRateDifferencesAccountsPayable AS DocumentTable
	|		WHERE
	|			DocumentTable.SettlementsType = VALUE(Enum.SettlementsTypes.Advance)) AS TableOfExchangeRateDifferencesAccountsPayable
	|	
	|	GROUP BY
	|		TableOfExchangeRateDifferencesAccountsPayable.Date,
	|		TableOfExchangeRateDifferencesAccountsPayable.Company
	|	
	|	HAVING
	|		(SUM(TableOfExchangeRateDifferencesAccountsPayable.AmountOfExchangeDifferences) >= 0.005
	|			OR SUM(TableOfExchangeRateDifferencesAccountsPayable.AmountOfExchangeDifferences) <= -0.005)) AS DocumentTable
	|
	|UNION ALL
	|
	|SELECT
	|	5,
	|	DocumentTable.LineNumber,
	|	DocumentTable.Date,
	|	DocumentTable.Company,
	|	UNDEFINED,
	|	VALUE(Catalog.BusinessActivities.Other),
	|	UNDEFINED,
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|			THEN &PositiveExchangeDifferenceGLAccount
	|		ELSE &NegativeExchangeDifferenceAccountOfAccounting
	|	END,
	|	&ExchangeDifference,
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|			THEN DocumentTable.AmountOfExchangeDifferences
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|			THEN 0
	|		ELSE -DocumentTable.AmountOfExchangeDifferences
	|	END,
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|			THEN DocumentTable.AmountOfExchangeDifferences
	|		ELSE -DocumentTable.AmountOfExchangeDifferences
	|	END
	|FROM
	|	TemporaryTableExchangeRateDifferencesAccountsReceivable AS DocumentTable
	|
	|ORDER BY
	|	Ordering,
	|	LineNumber";
	
	Query.SetParameter("OtherExpenses", NStr("en='Expense recording';ru='Отражение затрат';vi='Phản ánh chi phí'"));
	Query.SetParameter("PositiveExchangeDifferenceGLAccount", ChartsOfAccounts.Managerial.OtherIncome);
	Query.SetParameter("NegativeExchangeDifferenceAccountOfAccounting", ChartsOfAccounts.Managerial.OtherExpenses);
	Query.SetParameter("ExchangeDifference", NStr("en='Exchange rate difference';ru='Курсовая разница';vi='Chênh lệch tỷ giá'"));
	Query.SetParameter("IncomeReflection", NStr("en='Record income';ru='Отражение доходов';vi='Phản ánh thu nhập'"));
	Query.SetParameter("CostsReflection", NStr("en='Record expenses';ru='Отражение расходов';vi='Phản ánh chi phí'"));
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableIncomeAndExpenses", QueryResult.Unload());
	
EndProcedure // GenerateTableIncomeAndExpenses()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTablePurchasing(DocumentRefPurchaseInvoice, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	TablePurchasing.Period AS Period,
	|	TablePurchasing.Company AS Company,
	|	TablePurchasing.ProductsAndServices AS ProductsAndServices,
	|	TablePurchasing.Characteristic AS Characteristic,
	|	TablePurchasing.Batch AS Batch,
	|	TablePurchasing.Order AS PurchaseOrder,
	|	TablePurchasing.Document AS Document,
	|	TablePurchasing.VATRate AS VATRate,
	|	SUM(TablePurchasing.Quantity) AS Quantity,
	|	SUM(TablePurchasing.AmountVATPurchaseSale) AS VATAmount,
	|	SUM(TablePurchasing.Amount) AS Amount
	|FROM
	|	TemporaryTableInventory AS TablePurchasing
	|WHERE
	|	(TablePurchasing.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceiptFromVendor)
	|			OR TablePurchasing.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionForCommission))
	|
	|GROUP BY
	|	TablePurchasing.Period,
	|	TablePurchasing.Company,
	|	TablePurchasing.ProductsAndServices,
	|	TablePurchasing.Characteristic,
	|	TablePurchasing.Batch,
	|	TablePurchasing.Order,
	|	TablePurchasing.Document,
	|	TablePurchasing.VATRate
	|
	|UNION ALL
	|
	|SELECT
	|	TablePurchasing.Period,
	|	TablePurchasing.Company,
	|	TablePurchasing.ProductsAndServices,
	|	TablePurchasing.Characteristic,
	|	TablePurchasing.Batch,
	|	TablePurchasing.PurchaseOrder,
	|	TablePurchasing.Document,
	|	TablePurchasing.VATRate,
	|	SUM(TablePurchasing.Quantity),
	|	SUM(TablePurchasing.AmountVATPurchaseSale),
	|	SUM(TablePurchasing.Amount)
	|FROM
	|	TemporaryTableExpenses AS TablePurchasing
	|WHERE
	|	TablePurchasing.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceiptFromVendor)
	|
	|GROUP BY
	|	TablePurchasing.Period,
	|	TablePurchasing.Company,
	|	TablePurchasing.ProductsAndServices,
	|	TablePurchasing.Characteristic,
	|	TablePurchasing.Batch,
	|	TablePurchasing.PurchaseOrder,
	|	TablePurchasing.Document,
	|	TablePurchasing.VATRate";
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TablePurchasing", QueryResult.Unload());
	
EndProcedure // GeneratePurchasingTable()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableSales(DocumentRefPurchaseInvoice, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	TableSales.Period AS Period,
	|	TableSales.Company AS Company,
	|	TableSales.ProductsAndServices AS ProductsAndServices,
	|	TableSales.Characteristic AS Characteristic,
	|	TableSales.Batch AS Batch,
	|	TableSales.Order AS CustomerOrder,
	|	CASE
	|		WHEN TableSales.BasisDocument = VALUE(Document.CustomerInvoice.EmptyRef)
	|				OR TableSales.BasisDocument = VALUE(Document.CustomerOrder.EmptyRef)
	|				OR TableSales.BasisDocument = VALUE(Document.PurchaseOrder.EmptyRef)
	|				OR TableSales.BasisDocument = VALUE(Document.GoodsReceipt.EmptyRef)
	|				OR TableSales.BasisDocument = VALUE(Document.SupplierInvoiceForPayment.EmptyRef)
	|				OR TableSales.BasisDocument = UNDEFINED
	|			THEN TableSales.Document
	|		ELSE TableSales.BasisDocument
	|	END AS Document,
	|	TableSales.VATRate AS VATRate,
	|	TableSales.DepartmentSales AS Department,
	|	TableSales.BasisDocument.Responsible AS Responsible,
	|	-SUM(TableSales.Quantity) AS Quantity,
	|	-SUM(TableSales.AmountVATPurchaseSale) AS VATAmount,
	|	-SUM(TableSales.Amount) AS Amount,
	|	-SUM(CASE
	|			WHEN TableSales.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromCustomer)
	|					AND ISNULL(TableSales.BasisDocument.OperationKind, VALUE(Enum.OperationKindsCustomerInvoice.EmptyRef)) <> VALUE(Enum.OperationKindsCustomerInvoice.SaleToCustomer)
	|					AND ISNULL(TableSales.BasisDocument.OperationKind, VALUE(Enum.OperationKindsCustomerOrder.EmptyRef)) <> VALUE(Enum.OperationKindsCustomerOrder.WorkOrder)
	|				THEN TableSales.Cost
	|			ELSE 0
	|		END) AS Cost
	|FROM
	|	TemporaryTableInventory AS TableSales
	|WHERE
	|	TableSales.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromCustomer)
	|
	|GROUP BY
	|	TableSales.Period,
	|	TableSales.Company,
	|	TableSales.ProductsAndServices,
	|	TableSales.Characteristic,
	|	TableSales.Batch,
	|	TableSales.Order,
	|	CASE
	|		WHEN TableSales.BasisDocument = VALUE(Document.CustomerInvoice.EmptyRef)
	|				OR TableSales.BasisDocument = VALUE(Document.CustomerOrder.EmptyRef)
	|				OR TableSales.BasisDocument = VALUE(Document.PurchaseOrder.EmptyRef)
	|				OR TableSales.BasisDocument = VALUE(Document.GoodsReceipt.EmptyRef)
	|				OR TableSales.BasisDocument = VALUE(Document.SupplierInvoiceForPayment.EmptyRef)
	|				OR TableSales.BasisDocument = UNDEFINED
	|			THEN TableSales.Document
	|		ELSE TableSales.BasisDocument
	|	END,
	|	TableSales.VATRate,
	|	TableSales.DepartmentSales,
	|	TableSales.BasisDocument.Responsible";
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableSales", QueryResult.Unload());
	
EndProcedure // GenerateTableSales()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableInventoryInWarehouses(DocumentRefPurchaseInvoice, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	MIN(TableInventoryInWarehouses.LineNumber) AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TableInventoryInWarehouses.Period AS Period,
	|	TableInventoryInWarehouses.Company AS Company,
	|	TableInventoryInWarehouses.ProductsAndServices AS ProductsAndServices,
	|	TableInventoryInWarehouses.Characteristic AS Characteristic,
	|	TableInventoryInWarehouses.Batch AS Batch,
	|	TableInventoryInWarehouses.StructuralUnit AS StructuralUnit,
	|	TableInventoryInWarehouses.Cell AS Cell,
	|	SUM(TableInventoryInWarehouses.Quantity) AS Quantity
	|FROM
	|	TemporaryTableInventory AS TableInventoryInWarehouses
	|WHERE
	|	(NOT TableInventoryInWarehouses.RetailTransferAccrualAccounting)
	|	AND (NOT TableInventoryInWarehouses.OrderWarehouse)
	|
	|GROUP BY
	|	TableInventoryInWarehouses.Period,
	|	TableInventoryInWarehouses.Company,
	|	TableInventoryInWarehouses.ProductsAndServices,
	|	TableInventoryInWarehouses.Characteristic,
	|	TableInventoryInWarehouses.Batch,
	|	TableInventoryInWarehouses.StructuralUnit,
	|	TableInventoryInWarehouses.Cell";
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableInventoryInWarehouses", QueryResult.Unload());
	
EndProcedure // GenerateTableInventoryInWarehouses()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableInventoryForWarehouses(DocumentRefPurchaseInvoice, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	MIN(TableInventoryForWarehouses.LineNumber) AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	TableInventoryForWarehouses.Period AS Period,
	|	TableInventoryForWarehouses.Company AS Company,
	|	TableInventoryForWarehouses.ProductsAndServices AS ProductsAndServices,
	|	TableInventoryForWarehouses.Characteristic AS Characteristic,
	|	TableInventoryForWarehouses.Batch AS Batch,
	|	TableInventoryForWarehouses.StructuralUnit AS StructuralUnit,
	|	SUM(TableInventoryForWarehouses.Quantity) AS Quantity
	|FROM
	|	TemporaryTableInventory AS TableInventoryForWarehouses
	|WHERE
	|	(NOT TableInventoryForWarehouses.RetailTransferAccrualAccounting)
	|	AND TableInventoryForWarehouses.OrderWarehouse
	|
	|GROUP BY
	|	TableInventoryForWarehouses.Period,
	|	TableInventoryForWarehouses.Company,
	|	TableInventoryForWarehouses.ProductsAndServices,
	|	TableInventoryForWarehouses.Characteristic,
	|	TableInventoryForWarehouses.Batch,
	|	TableInventoryForWarehouses.StructuralUnit";
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableInventoryForWarehouses", QueryResult.Unload());
	
EndProcedure // GenerateTableInventoryForWarehouses()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableInventoryReceived(DocumentRefPurchaseInvoice, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	MIN(TableInventoryReceived.LineNumber) AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TableInventoryReceived.Period AS Period,
	|	TableInventoryReceived.Company AS Company,
	|	TableInventoryReceived.ProductsAndServices AS ProductsAndServices,
	|	TableInventoryReceived.Characteristic AS Characteristic,
	|	TableInventoryReceived.Batch AS Batch,
	|	TableInventoryReceived.Counterparty AS Counterparty,
	|	TableInventoryReceived.Contract AS Contract,
	|	TableInventoryReceived.Order AS Order,
	|	TableInventoryReceived.GLAccount AS GLAccount,
	|	CASE
	|		WHEN TableInventoryReceived.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionForCommission)
	|			THEN VALUE(Enum.ProductsReceiptTransferTypes.ReceiptFromPrincipal)
	|		WHEN TableInventoryReceived.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionIntoProcessing)
	|			THEN VALUE(Enum.ProductsReceiptTransferTypes.ReceiptToProcessing)
	|		ELSE VALUE(Enum.ProductsReceiptTransferTypes.SafeCustody)
	|	END AS ReceptionTransmissionType,
	|	SUM(TableInventoryReceived.Quantity) AS Quantity,
	//( elmi #11
	//|	SUM(TableInventoryReceived.SettlementsAmountTakenPassed) AS SettlementsAmount,
	//|	SUM(TableInventoryReceived.SettlementsAmountTakenPassed) AS Amount,
	|	SUM(TableInventoryReceived.SettlementsAmountTakenPassed - TableInventoryReceived.VATAmount) AS SettlementsAmount,
	|	SUM(TableInventoryReceived.SettlementsAmountTakenPassed - TableInventoryReceived.VATAmount) AS Amount,
	//) elmi
	|	0 AS SalesAmount,
	|	&AdmAccountingCurrency AS Currency,
	|	SUM(TableInventoryReceived.SettlementsAmountTakenPassed) AS AmountCur,
	|	CAST(&InventoryReception AS String(100)) AS ContentOfAccountingRecord
	|FROM
	|	TemporaryTableInventory AS TableInventoryReceived
	|WHERE
	|	(TableInventoryReceived.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionForCommission)
	|			OR TableInventoryReceived.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionIntoProcessing)
	|			OR TableInventoryReceived.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionForSafeCustody))
	|
	|GROUP BY
	|	TableInventoryReceived.Period,
	|	TableInventoryReceived.Company,
	|	TableInventoryReceived.ProductsAndServices,
	|	TableInventoryReceived.Characteristic,
	|	TableInventoryReceived.Batch,
	|	TableInventoryReceived.Counterparty,
	|	TableInventoryReceived.Contract,
	|	TableInventoryReceived.Order,
	|	TableInventoryReceived.GLAccount,
	|	CASE
	|		WHEN TableInventoryReceived.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionForCommission)
	|			THEN VALUE(Enum.ProductsReceiptTransferTypes.ReceiptFromPrincipal)
	|		WHEN TableInventoryReceived.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionIntoProcessing)
	|			THEN VALUE(Enum.ProductsReceiptTransferTypes.ReceiptToProcessing)
	|		ELSE VALUE(Enum.ProductsReceiptTransferTypes.SafeCustody)
	|	END
	|
	|UNION ALL
	|
	|SELECT
	|	MIN(TableInventoryReceived.LineNumber),
	|	VALUE(AccumulationRecordType.Receipt),
	|	TableInventoryReceived.Period,
	|	TableInventoryReceived.Company,
	|	TableInventoryReceived.ProductsAndServices,
	|	TableInventoryReceived.Characteristic,
	|	TableInventoryReceived.Batch,
	|	UNDEFINED,
	|	UNDEFINED,
	|	TableInventoryReceived.Order,
	|	TableInventoryReceived.GLAccountVendorSettlements,
	|	VALUE(Enum.ProductsReceiptTransferTypes.ReportToPrincipal),
	|	-SUM(TableInventoryReceived.Quantity),
	|	0,
	//( elmi #11
	//|	-SUM(TableInventoryReceived.Amount),
	//|	-SUM(TableInventoryReceived.Amount),
	|	-SUM(TableInventoryReceived.Amount - TableInventoryReceived.VATAmount),
	|	-SUM(TableInventoryReceived.Amount - TableInventoryReceived.VATAmount),
	//) elmi
	|	&AdmAccountingCurrency,
	|	SUM(TableInventoryReceived.Amount),
	|	CAST(&InventoryIncomeReturn AS String(100))
	|FROM
	|	TemporaryTableInventory AS TableInventoryReceived
	|WHERE
	|	TableInventoryReceived.ProductsOnCommission
	|
	|GROUP BY
	|	TableInventoryReceived.Period,
	|	TableInventoryReceived.Company,
	|	TableInventoryReceived.ProductsAndServices,
	|	TableInventoryReceived.Characteristic,
	|	TableInventoryReceived.Batch,
	|	TableInventoryReceived.Order,
	|	TableInventoryReceived.GLAccountVendorSettlements";
		
	Query.SetParameter("InventoryReception", "");
	Query.SetParameter("InventoryIncomeReturn", NStr("en='Inventory receipt';ru='Прием запасов';vi='Tiếp nhận vật tư'"));
	Query.SetParameter("AdmAccountingCurrency", Constants.AccountingCurrency.Get());
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableInventoryReceived", QueryResult.Unload());
	
EndProcedure // GenerateTableInventoryReceived()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableInventoryTransferred(DocumentRefPurchaseInvoice, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	MIN(TableInventoryTransferred.LineNumber) AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TableInventoryTransferred.Period AS Period,
	|	TableInventoryTransferred.Company AS Company,
	|	TableInventoryTransferred.ProductsAndServices AS ProductsAndServices,
	|	TableInventoryTransferred.Characteristic AS Characteristic,
	|	TableInventoryTransferred.Batch AS Batch,
	|	TableInventoryTransferred.Counterparty AS Counterparty,
	|	TableInventoryTransferred.Contract AS Contract,
	|	TableInventoryTransferred.Order AS Order,
	|	CASE
	|		WHEN TableInventoryTransferred.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromAgent)
	|			THEN VALUE(Enum.ProductsReceiptTransferTypes.TransferToAgent)
	|		WHEN TableInventoryTransferred.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromSubcontractor)
	|			THEN VALUE(Enum.ProductsReceiptTransferTypes.TransferToProcessing)
	|		ELSE VALUE(Enum.ProductsReceiptTransferTypes.SafeCustody)
	|	END AS ReceptionTransmissionType,
	|	-SUM(TableInventoryTransferred.Quantity) AS Quantity,
	//( elmi #11
	//|	-SUM(TableInventoryTransferred.SettlementsAmountTakenPassed) AS SettlementsAmount
	|	-SUM(TableInventoryTransferred.SettlementsAmountTakenPassed - TableInventoryTransferred.VatAmount) КАК SettlementsAmount
	//) elmi
	|FROM
	|	TemporaryTableInventory AS TableInventoryTransferred
	|WHERE
	|	(TableInventoryTransferred.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromAgent)
	|			OR TableInventoryTransferred.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromSubcontractor)
	|			OR TableInventoryTransferred.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromSafeCustody))
	|
	|GROUP BY
	|	TableInventoryTransferred.Period,
	|	TableInventoryTransferred.Company,
	|	TableInventoryTransferred.ProductsAndServices,
	|	TableInventoryTransferred.Characteristic,
	|	TableInventoryTransferred.Batch,
	|	TableInventoryTransferred.Counterparty,
	|	TableInventoryTransferred.Contract,
	|	TableInventoryTransferred.Order,
	|	CASE
	|		WHEN TableInventoryTransferred.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromAgent)
	|			THEN VALUE(Enum.ProductsReceiptTransferTypes.TransferToAgent)
	|		WHEN TableInventoryTransferred.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromSubcontractor)
	|			THEN VALUE(Enum.ProductsReceiptTransferTypes.TransferToProcessing)
	|		ELSE VALUE(Enum.ProductsReceiptTransferTypes.SafeCustody)
	|	END";
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableInventoryTransferred", QueryResult.Unload());
	
EndProcedure // GenerateTableInventoryTransferred()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableCustomerOrders(DocumentRefPurchaseInvoice, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	MIN(TableCustomerOrders.LineNumber) AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	TableCustomerOrders.Period AS Period,
	|	TableCustomerOrders.Company AS Company,
	|	TableCustomerOrders.ProductsAndServices AS ProductsAndServices,
	|	TableCustomerOrders.Characteristic AS Characteristic,
	|	TableCustomerOrders.Order AS CustomerOrder,
	|	-SUM(TableCustomerOrders.Quantity) AS Quantity
	|FROM
	|	TemporaryTableInventory AS TableCustomerOrders
	|WHERE
	|	TableCustomerOrders.Order <> UNDEFINED
	|	AND (NOT TableCustomerOrders.WorkOrder)
	|	AND (TableCustomerOrders.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromCustomer)
	|			OR TableCustomerOrders.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromAgent)
	|			OR TableCustomerOrders.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromSafeCustody))
	|
	|GROUP BY
	|	TableCustomerOrders.Period,
	|	TableCustomerOrders.Company,
	|	TableCustomerOrders.ProductsAndServices,
	|	TableCustomerOrders.Characteristic,
	|	TableCustomerOrders.Order";
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableCustomerOrders", QueryResult.Unload());
	
EndProcedure // GenerateTableCustomerOrders()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTablePurchaseOrders(DocumentRefPurchaseInvoice, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	MIN(TablePurchaseOrders.LineNumber) AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	TablePurchaseOrders.Period AS Period,
	|	TablePurchaseOrders.Company AS Company,
	|	TablePurchaseOrders.ProductsAndServices AS ProductsAndServices,
	|	TablePurchaseOrders.Characteristic AS Characteristic,
	|	TablePurchaseOrders.Order AS PurchaseOrder,
	|	SUM(TablePurchaseOrders.Quantity) AS Quantity
	|FROM
	|	TemporaryTableInventory AS TablePurchaseOrders
	|WHERE
	|	TablePurchaseOrders.Order <> UNDEFINED
	|	AND (TablePurchaseOrders.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceiptFromVendor)
	|			OR TablePurchaseOrders.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionForCommission)
	|			OR TablePurchaseOrders.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionForSafeCustody))
	|
	|GROUP BY
	|	TablePurchaseOrders.Period,
	|	TablePurchaseOrders.Company,
	|	TablePurchaseOrders.ProductsAndServices,
	|	TablePurchaseOrders.Characteristic,
	|	TablePurchaseOrders.Order
	|
	|UNION ALL
	|
	|SELECT
	|	MIN(TablePurchaseOrders.LineNumber),
	|	VALUE(AccumulationRecordType.Expense),
	|	TablePurchaseOrders.Period,
	|	TablePurchaseOrders.Company,
	|	TablePurchaseOrders.ProductsAndServices,
	|	TablePurchaseOrders.Characteristic,
	|	TablePurchaseOrders.PurchaseOrder,
	|	SUM(TablePurchaseOrders.Quantity)
	|FROM
	|	TemporaryTableExpenses AS TablePurchaseOrders
	|WHERE
	|	TablePurchaseOrders.PurchaseOrder <> VALUE(Document.PurchaseOrder.EmptyRef)
	|	AND TablePurchaseOrders.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceiptFromVendor)
	|
	|GROUP BY
	|	TablePurchaseOrders.Period,
	|	TablePurchaseOrders.Company,
	|	TablePurchaseOrders.ProductsAndServices,
	|	TablePurchaseOrders.Characteristic,
	|	TablePurchaseOrders.PurchaseOrder";
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TablePurchaseOrders", QueryResult.Unload());
	
EndProcedure // GenerateTablePurchaseOrders()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableOrdersPlacement(DocumentRefPurchaseInvoice, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	
	// Inventory and expenses placement.
	Query.Text =
	"SELECT
	|	TablePlacement.Period AS Period,
	|	TablePlacement.Company AS Company,
	|	TablePlacement.ProductsAndServices AS ProductsAndServices,
	|	TablePlacement.Characteristic AS Characteristic,
	|	TablePlacement.Order AS Order,
	|	SUM(TablePlacement.Quantity) AS Quantity
	|INTO TemporaryTablePlacement
	|FROM
	|	(SELECT
	|		TablePlacementInventory.Period AS Period,
	|		TablePlacementInventory.Company AS Company,
	|		TablePlacementInventory.ProductsAndServices AS ProductsAndServices,
	|		TablePlacementInventory.Characteristic AS Characteristic,
	|		TablePlacementInventory.Order AS Order,
	|		TablePlacementInventory.Quantity AS Quantity
	|	FROM
	|		TemporaryTableInventory AS TablePlacementInventory
	|	WHERE
	|		Not TablePlacementInventory.Order IN (VALUE(Document.CustomerOrder.EmptyRef), VALUE(Document.PurchaseOrder.EmptyRef), VALUE(Document.ProductionOrder.EmptyRef), UNDEFINED)
	|		AND (TablePlacementInventory.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceiptFromVendor)
	|				OR TablePlacementInventory.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionForCommission)
	|				OR TablePlacementInventory.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionIntoProcessing))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TablePlacementExpenses.Period,
	|		TablePlacementExpenses.Company,
	|		TablePlacementExpenses.ProductsAndServices,
	|		TablePlacementExpenses.Characteristic,
	|		TablePlacementExpenses.PurchaseOrder,
	|		TablePlacementExpenses.Quantity
	|	FROM
	|		TemporaryTableExpenses AS TablePlacementExpenses
	|	WHERE
	|		Not TablePlacementExpenses.PurchaseOrder IN (VALUE(Document.PurchaseOrder.EmptyRef), UNDEFINED)
	|		AND TablePlacementExpenses.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceiptFromVendor)) AS TablePlacement
	|
	|GROUP BY
	|	TablePlacement.Period,
	|	TablePlacement.Company,
	|	TablePlacement.ProductsAndServices,
	|	TablePlacement.Characteristic,
	|	TablePlacement.Order";
	
	Query.Execute();
	
	// Set exclusive lock of the controlled orders placement.
	Query.Text = 
	"SELECT
	|	TableOrdersPlacement.Company AS Company,
	|	TableOrdersPlacement.ProductsAndServices AS ProductsAndServices,
	|	TableOrdersPlacement.Characteristic AS Characteristic,
	|	TableOrdersPlacement.Order AS SupplySource
	|FROM
	|	TemporaryTablePlacement AS TableOrdersPlacement";
	
	QueryResult = Query.Execute();
	
	Block = New DataLock;
	LockItem = Block.Add("AccumulationRegister.OrdersPlacement");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = QueryResult;
	
	For Each ColumnQueryResult in QueryResult.Columns Do
		LockItem.UseFromDataSource(ColumnQueryResult.Name, ColumnQueryResult.Name);
	EndDo;
	Block.Lock();
	
	// Receive balance.
	Query.Text =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	TableOrdersPlacement.Period AS Period,
	|	TableOrdersPlacement.Company AS Company,
	|	OrdersPlacementBalances.CustomerOrder AS CustomerOrder,
	|	TableOrdersPlacement.ProductsAndServices AS ProductsAndServices,
	|	TableOrdersPlacement.Characteristic AS Characteristic,
	|	TableOrdersPlacement.Order AS SupplySource,
	|	CASE
	|		WHEN TableOrdersPlacement.Quantity > ISNULL(OrdersPlacementBalances.Quantity, 0)
	|			THEN ISNULL(OrdersPlacementBalances.Quantity, 0)
	|		WHEN TableOrdersPlacement.Quantity <= ISNULL(OrdersPlacementBalances.Quantity, 0)
	|			THEN TableOrdersPlacement.Quantity
	|	END AS Quantity
	|FROM
	|	TemporaryTablePlacement AS TableOrdersPlacement
	|		LEFT JOIN (SELECT
	|			OrdersPlacementBalances.Company AS Company,
	|			OrdersPlacementBalances.ProductsAndServices AS ProductsAndServices,
	|			OrdersPlacementBalances.Characteristic AS Characteristic,
	|			OrdersPlacementBalances.CustomerOrder AS CustomerOrder,
	|			OrdersPlacementBalances.SupplySource AS SupplySource,
	|			SUM(OrdersPlacementBalances.QuantityBalance) AS Quantity
	|		FROM
	|			(SELECT
	|				OrdersPlacementBalances.Company AS Company,
	|				OrdersPlacementBalances.ProductsAndServices AS ProductsAndServices,
	|				OrdersPlacementBalances.Characteristic AS Characteristic,
	|				OrdersPlacementBalances.CustomerOrder AS CustomerOrder,
	|				OrdersPlacementBalances.SupplySource AS SupplySource,
	|				OrdersPlacementBalances.QuantityBalance AS QuantityBalance
	|			FROM
	|				AccumulationRegister.OrdersPlacement.Balance(
	|						&ControlTime,
	|						(Company, ProductsAndServices, Characteristic, SupplySource) In
	|							(SELECT
	|								TableOrdersPlacement.Company AS Company,
	|								TableOrdersPlacement.ProductsAndServices AS ProductsAndServices,
	|								TableOrdersPlacement.Characteristic AS Characteristic,
	|								TableOrdersPlacement.Order AS SupplySource
	|							FROM
	|								TemporaryTablePlacement AS TableOrdersPlacement)) AS OrdersPlacementBalances
			
	|			UNION ALL
			
	|			SELECT
	|				DocumentRegisterRecordsOrdersPlacement.Company,
	|				DocumentRegisterRecordsOrdersPlacement.ProductsAndServices,
	|				DocumentRegisterRecordsOrdersPlacement.Characteristic,
	|				DocumentRegisterRecordsOrdersPlacement.CustomerOrder,
	|				DocumentRegisterRecordsOrdersPlacement.SupplySource,
	|				CASE
	|					WHEN DocumentRegisterRecordsOrdersPlacement.RecordType = VALUE(AccumulationRecordType.Expense)
	|						THEN ISNULL(DocumentRegisterRecordsOrdersPlacement.Quantity, 0)
	|					ELSE -ISNULL(DocumentRegisterRecordsOrdersPlacement.Quantity, 0)
	|				END
	|			FROM
	|				AccumulationRegister.OrdersPlacement AS DocumentRegisterRecordsOrdersPlacement
	|			WHERE
	|				DocumentRegisterRecordsOrdersPlacement.Recorder = &Ref
	|				AND DocumentRegisterRecordsOrdersPlacement.Period <= &ControlPeriod) AS OrdersPlacementBalances
		
	|		GROUP BY
	|			OrdersPlacementBalances.Company,
	|			OrdersPlacementBalances.ProductsAndServices,
	|			OrdersPlacementBalances.Characteristic,
	|			OrdersPlacementBalances.CustomerOrder,
	|			OrdersPlacementBalances.SupplySource) AS OrdersPlacementBalances
	|		ON TableOrdersPlacement.Company = OrdersPlacementBalances.Company
	|			AND TableOrdersPlacement.ProductsAndServices = OrdersPlacementBalances.ProductsAndServices
	|			AND TableOrdersPlacement.Characteristic = OrdersPlacementBalances.Characteristic
	|			AND TableOrdersPlacement.Order = OrdersPlacementBalances.SupplySource
	|WHERE
	|	OrdersPlacementBalances.CustomerOrder IS Not NULL ";
	
	Query.SetParameter("Ref", DocumentRefPurchaseInvoice);
	Query.SetParameter("ControlTime", StructureAdditionalProperties.ForPosting.ControlTime);
	Query.SetParameter("ControlPeriod", StructureAdditionalProperties.ForPosting.ControlPeriod);
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableOrdersPlacement", QueryResult.Unload());
	
EndProcedure // GenerateTableOrdersPlacement()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableInventoryDemand(DocumentRefPurchaseInvoice, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	MIN(TableInventory.LineNumber) AS LineNumber,
	|	TableInventory.Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	VALUE(Enum.InventoryMovementTypes.Receipt) AS MovementType,
	|	TableInventory.Company AS Company,
	|	CASE
	|		WHEN TableInventory.Order REFS Document.CustomerOrder
	|			THEN TableInventory.Order
	|		ELSE VALUE(Document.CustomerOrder.EmptyRef)
	|	END AS CustomerOrder,
	|	TableInventory.ProductsAndServices AS ProductsAndServices,
	|	TableInventory.Characteristic AS Characteristic,
	|	SUM(TableInventory.Quantity) AS Quantity
	|FROM
	|	TemporaryTableInventory AS TableInventory
	|WHERE
	|	TableInventory.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionIntoProcessing)
	|
	|GROUP BY
	|	TableInventory.Period,
	|	TableInventory.Company,
	|	TableInventory.Order,
	|	TableInventory.ProductsAndServices,
	|	TableInventory.Characteristic
	|
	|ORDER BY
	|	LineNumber";
		
	QueryResult = Query.Execute();
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableInventoryDemand", QueryResult.Unload());
		
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	TableInventoryDemand.Company AS Company,
	|	VALUE(Enum.InventoryMovementTypes.Receipt) AS MovementType,
	|	CASE
	|		WHEN TableInventoryDemand.Order REFS Document.CustomerOrder
	|			THEN TableInventoryDemand.Order
	|		ELSE VALUE(Document.CustomerOrder.EmptyRef)
	|	END AS CustomerOrder,
	|	TableInventoryDemand.ProductsAndServices AS ProductsAndServices,
	|	TableInventoryDemand.Characteristic AS Characteristic
	|FROM
	|	TemporaryTableInventory AS TableInventoryDemand
	|WHERE
	|	TableInventoryDemand.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionIntoProcessing)";
	
	QueryResult = Query.Execute();
	
	Block = New DataLock;
	LockItem = Block.Add("AccumulationRegister.InventoryDemand");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = QueryResult;

	For Each ColumnQueryResult in QueryResult.Columns Do
		LockItem.UseFromDataSource(ColumnQueryResult.Name, ColumnQueryResult.Name);
	EndDo;
	Block.Lock();

	// Receive balance.
	Query.Text = 	
	"SELECT
	|	InventoryDemandBalances.Company AS Company,
	|	InventoryDemandBalances.CustomerOrder AS CustomerOrder,
	|	InventoryDemandBalances.ProductsAndServices AS ProductsAndServices,
	|	InventoryDemandBalances.Characteristic AS Characteristic,
	|	SUM(InventoryDemandBalances.Quantity) AS QuantityBalance
	|FROM
	|	(SELECT
	|		InventoryDemandBalances.Company AS Company,
	|		InventoryDemandBalances.CustomerOrder AS CustomerOrder,
	|		InventoryDemandBalances.ProductsAndServices AS ProductsAndServices,
	|		InventoryDemandBalances.Characteristic AS Characteristic,
	|		SUM(InventoryDemandBalances.QuantityBalance) AS Quantity
	|	FROM
	|		AccumulationRegister.InventoryDemand.Balance(
	|				&ControlTime,
	|				(Company, MovementType, CustomerOrder, ProductsAndServices, Characteristic) In
	|					(SELECT
	|						TemporaryTableInventory.Company AS Company,
	|						VALUE(Enum.InventoryMovementTypes.Receipt) AS MovementType,
	|						CASE
	|							WHEN TemporaryTableInventory.Order REFS Document.CustomerOrder
	|								THEN TemporaryTableInventory.Order
	|							ELSE VALUE(Document.CustomerOrder.EmptyRef)
	|						END AS CustomerOrder,
	|						TemporaryTableInventory.ProductsAndServices AS ProductsAndServices,
	|						TemporaryTableInventory.Characteristic AS Characteristic
	|					FROM
	|						TemporaryTableInventory AS TemporaryTableInventory
	|					WHERE
	|						TemporaryTableInventory.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionIntoProcessing))) AS InventoryDemandBalances
	|	
	|	GROUP BY
	|		InventoryDemandBalances.Company,
	|		InventoryDemandBalances.CustomerOrder,
	|		InventoryDemandBalances.ProductsAndServices,
	|		InventoryDemandBalances.Characteristic
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentRegisterRecordsInventoryDemand.Company,
	|		DocumentRegisterRecordsInventoryDemand.CustomerOrder,
	|		DocumentRegisterRecordsInventoryDemand.ProductsAndServices,
	|		DocumentRegisterRecordsInventoryDemand.Characteristic,
	|		CASE
	|			WHEN DocumentRegisterRecordsInventoryDemand.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN ISNULL(DocumentRegisterRecordsInventoryDemand.Quantity, 0)
	|			ELSE -ISNULL(DocumentRegisterRecordsInventoryDemand.Quantity, 0)
	|		END
	|	FROM
	|		AccumulationRegister.InventoryDemand AS DocumentRegisterRecordsInventoryDemand
	|	WHERE
	|		DocumentRegisterRecordsInventoryDemand.Recorder = &Ref
	|		AND DocumentRegisterRecordsInventoryDemand.Period <= &ControlPeriod) AS InventoryDemandBalances
	|
	|GROUP BY
	|	InventoryDemandBalances.Company,
	|	InventoryDemandBalances.CustomerOrder,
	|	InventoryDemandBalances.ProductsAndServices,
	|	InventoryDemandBalances.Characteristic";
	
	Query.SetParameter("Ref", DocumentRefPurchaseInvoice);
	Query.SetParameter("ControlTime", StructureAdditionalProperties.ForPosting.ControlTime);
	Query.SetParameter("ControlPeriod", StructureAdditionalProperties.ForPosting.ControlPeriod);

	QueryResult = Query.Execute();
	
	TableInventoryDemandBalance = QueryResult.Unload();
	TableInventoryDemandBalance.Indexes.Add("Company,CustomerOrder,ProductsAndServices,Characteristic");

	TemporaryTableInventoryDemand = StructureAdditionalProperties.TableForRegisterRecords.TableInventoryDemand.CopyColumns();
	
	For Each RowTablesForInventory IN StructureAdditionalProperties.TableForRegisterRecords.TableInventoryDemand Do
		
		StructureForSearch = New Structure;
		StructureForSearch.Insert("Company", 		RowTablesForInventory.Company);
		StructureForSearch.Insert("CustomerOrder", 	RowTablesForInventory.CustomerOrder);
		StructureForSearch.Insert("ProductsAndServices", 	RowTablesForInventory.ProductsAndServices);
		StructureForSearch.Insert("Characteristic", 	RowTablesForInventory.Characteristic);
		
		BalanceRowsArray = TableInventoryDemandBalance.FindRows(StructureForSearch);
		If BalanceRowsArray.Count() > 0 Then
			
			If RowTablesForInventory.Quantity > BalanceRowsArray[0].QuantityBalance Then
				RowTablesForInventory.Quantity = BalanceRowsArray[0].QuantityBalance;
			EndIf;	
			
			TableRowExpense = TemporaryTableInventoryDemand.Add();
			FillPropertyValues(TableRowExpense, RowTablesForInventory);
			
         EndIf;
		
	EndDo;	
	
	StructureAdditionalProperties.TableForRegisterRecords.TableInventoryDemand = TemporaryTableInventoryDemand;
			
EndProcedure // GenerateTableNeedForInventory()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableAccountsPayable(DocumentRefPurchaseInvoice, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	
	Query.SetParameter("Ref", DocumentRefPurchaseInvoice);
	Query.SetParameter("PointInTime", New Boundary(StructureAdditionalProperties.ForPosting.PointInTime, BoundaryType.Including));
	Query.SetParameter("ControlPeriod", StructureAdditionalProperties.ForPosting.PointInTime.Date);
	Query.SetParameter("Company", StructureAdditionalProperties.ForPosting.Company);
	Query.SetParameter("AppearenceOfLiabilityToVendor", NStr("en='Incurrence of liabilities to supplier';ru='Возникновение обязательств перед поставщиком';vi='Phát sinh nợ phải trả nhà cung cấp'"));
	Query.SetParameter("AdvanceCredit", NStr("en='Prepayment setoff';ru='Зачет предоплаты';vi='Khấu trừ trả trước'"));
	Query.SetParameter("ExchangeDifference", NStr("en='Exchange rate difference';ru='Курсовая разница';vi='Chênh lệch tỷ giá'"));
	
	Query.Text =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentTable.Period AS Date,
	|	DocumentTable.Company AS Company,
	|	DocumentTable.Counterparty AS Counterparty,
	|	DocumentTable.DoOperationsByDocuments AS DoOperationsByDocuments,
	|	DocumentTable.GLAccountVendorSettlements AS GLAccount,
	|	DocumentTable.Contract AS Contract,
	|	CASE
	|		WHEN DocumentTable.DoOperationsByDocuments
	|			THEN DocumentTable.Document
	|		ELSE UNDEFINED
	|	END AS Document,
	|	CASE
	|		WHEN DocumentTable.Order REFS Document.PurchaseOrder
	|				AND DocumentTable.Order <> VALUE(Document.PurchaseOrder.EmptyRef)
	|				AND DocumentTable.DoOperationsByOrders
	|			THEN DocumentTable.Order
	|		ELSE VALUE(Document.PurchaseOrder.EmptyRef)
	|	END AS Order,
	|	DocumentTable.SettlementsCurrency AS Currency,
	|	VALUE(Enum.SettlementsTypes.Debt) AS SettlementsType,
	//( elmi #11
	//|	SUM(CASE
	//|			WHEN DocumentTable.IncludeExpensesInCostPrice
	//|				THEN DocumentTable.Amount + DocumentTable.AmountExpenses
	//|			ELSE DocumentTable.Amount
	//|		END) AS Amount,
	//|	SUM(CASE
	//|			WHEN DocumentTable.IncludeExpensesInCostPrice
	//|				THEN DocumentTable.AmountCur + DocumentTable.AmountExpensesCur
	//|			ELSE DocumentTable.AmountCur
	//|		END) AS AmountCur,
	//|	SUM(CASE
	//|			WHEN DocumentTable.IncludeExpensesInCostPrice
	//|				THEN DocumentTable.Amount + DocumentTable.AmountExpenses
	//|			ELSE DocumentTable.Amount
	//|		END) AS AmountForBalance,
	//|	SUM(CASE
	//|			WHEN DocumentTable.IncludeExpensesInCostPrice
	//|				THEN DocumentTable.AmountCur + DocumentTable.AmountExpensesCur
	//|			ELSE DocumentTable.AmountCur
	//|		END) AS AmountCurForBalance,
	|	SUM(DocumentTable.Amount) AS Amount,
	|	SUM(DocumentTable.AmountCur) AS AmountCur,
	|	SUM(DocumentTable.Amount) AS AmountForBalance,
	|	SUM(DocumentTable.AmountCur) AS AmountCurForBalance,
    //) elmi
	|	CAST(&AppearenceOfLiabilityToVendor AS String(100)) AS ContentOfAccountingRecord
	|INTO TemporaryTableAccountsPayable
	|FROM
	|	TemporaryTableInventory AS DocumentTable
	|WHERE
	|	DocumentTable.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceiptFromVendor)
	|
	|GROUP BY
	|	DocumentTable.Period,
	|	DocumentTable.Company,
	|	DocumentTable.Counterparty,
	|	DocumentTable.DoOperationsByDocuments,
	|	DocumentTable.Contract,
	|	CASE
	|		WHEN DocumentTable.DoOperationsByDocuments
	|			THEN DocumentTable.Document
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.Order REFS Document.PurchaseOrder
	|				AND DocumentTable.Order <> VALUE(Document.PurchaseOrder.EmptyRef)
	|				AND DocumentTable.DoOperationsByOrders
	|			THEN DocumentTable.Order
	|		ELSE VALUE(Document.PurchaseOrder.EmptyRef)
	|	END,
	|	DocumentTable.SettlementsCurrency,
	|	DocumentTable.GLAccountVendorSettlements
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt),
	|	DocumentTable.Period,
	|	DocumentTable.Company,
	|	DocumentTable.Counterparty,
	|	DocumentTable.DoOperationsByDocuments,
	|	DocumentTable.GLAccountVendorSettlements,
	|	DocumentTable.Contract,
	|	CASE
	|		WHEN DocumentTable.DoOperationsByDocuments
	|			THEN DocumentTable.Document
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.DoOperationsByOrders
	|			THEN DocumentTable.PurchaseOrder
	|		ELSE VALUE(Document.PurchaseOrder.EmptyRef)
	|	END,
	|	DocumentTable.SettlementsCurrency,
	|	VALUE(Enum.SettlementsTypes.Debt),
	|	SUM(DocumentTable.Amount),
	|	SUM(DocumentTable.AmountCur),
	|	SUM(DocumentTable.Amount),
	|	SUM(DocumentTable.AmountCur),
	|	CAST(&AppearenceOfLiabilityToVendor AS String(100))
	|FROM
	|	TemporaryTableExpenses AS DocumentTable
	|WHERE
	|	DocumentTable.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceiptFromVendor)
	//( elmi #11
	//|	AND Not DocumentTable.IncludeExpensesInCostPrice 
	//) elmi
	|
	|GROUP BY
	|	DocumentTable.Period,
	|	DocumentTable.Company,
	|	DocumentTable.Counterparty,
	|	DocumentTable.DoOperationsByDocuments,
	|	DocumentTable.Contract,
	|	CASE
	|		WHEN DocumentTable.DoOperationsByDocuments
	|			THEN DocumentTable.Document
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.DoOperationsByOrders
	|			THEN DocumentTable.PurchaseOrder
	|		ELSE VALUE(Document.PurchaseOrder.EmptyRef)
	|	END,
	|	DocumentTable.SettlementsCurrency,
	|	DocumentTable.GLAccountVendorSettlements
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt),
	|	DocumentTable.Period,
	|	DocumentTable.Company,
	|	DocumentTable.Counterparty,
	|	DocumentTable.DoOperationsByDocuments,
	|	DocumentTable.VendorAdvancesGLAccount,
	|	DocumentTable.Contract,
	|	CASE
	|		WHEN DocumentTable.DoOperationsByDocuments
	|			THEN DocumentTable.Document
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.Order REFS Document.PurchaseOrder
	|				AND DocumentTable.Order <> VALUE(Document.PurchaseOrder.EmptyRef)
	|				AND DocumentTable.DoOperationsByOrders
	|			THEN DocumentTable.Order
	|		ELSE VALUE(Document.PurchaseOrder.EmptyRef)
	|	END,
	|	DocumentTable.SettlementsCurrency,
	|	DocumentTable.SettlementsType,
	|	SUM(DocumentTable.Amount),
	|	SUM(DocumentTable.AmountCur),
	|	SUM(DocumentTable.Amount),
	|	SUM(DocumentTable.AmountCur),
	|	CAST(&AdvanceCredit AS String(100))
	|FROM
	|	TemporaryTablePrepayment AS DocumentTable
	|WHERE
	|	DocumentTable.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceiptFromVendor)
	|
	|GROUP BY
	|	DocumentTable.Period,
	|	DocumentTable.Company,
	|	DocumentTable.Counterparty,
	|	DocumentTable.DoOperationsByDocuments,
	|	DocumentTable.Contract,
	|	CASE
	|		WHEN DocumentTable.DoOperationsByDocuments
	|			THEN DocumentTable.Document
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.Order REFS Document.PurchaseOrder
	|				AND DocumentTable.Order <> VALUE(Document.PurchaseOrder.EmptyRef)
	|				AND DocumentTable.DoOperationsByOrders
	|			THEN DocumentTable.Order
	|		ELSE VALUE(Document.PurchaseOrder.EmptyRef)
	|	END,
	|	DocumentTable.SettlementsType,
	|	DocumentTable.SettlementsCurrency,
	|	DocumentTable.VendorAdvancesGLAccount
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense),
	|	DocumentTable.Period,
	|	DocumentTable.Company,
	|	DocumentTable.Counterparty,
	|	DocumentTable.DoOperationsByDocuments,
	|	DocumentTable.GLAccountVendorSettlements,
	|	DocumentTable.Contract,
	|	CASE
	|		WHEN DocumentTable.DoOperationsByDocuments
	|			THEN DocumentTable.DocumentWhere
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.Order REFS Document.PurchaseOrder
	|				AND DocumentTable.Order <> VALUE(Document.PurchaseOrder.EmptyRef)
	|				AND DocumentTable.DoOperationsByOrders
	|			THEN DocumentTable.Order
	|		ELSE VALUE(Document.PurchaseOrder.EmptyRef)
	|	END,
	|	DocumentTable.SettlementsCurrency,
	|	DocumentTable.SettlemensTypeWhere,
	|	SUM(DocumentTable.Amount),
	|	SUM(DocumentTable.AmountCur),
	|	-SUM(DocumentTable.Amount),
	|	-SUM(DocumentTable.AmountCur),
	|	CAST(&AdvanceCredit AS String(100))
	|FROM
	|	TemporaryTablePrepayment AS DocumentTable
	|WHERE
	|	DocumentTable.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceiptFromVendor)
	|
	|GROUP BY
	|	DocumentTable.Period,
	|	DocumentTable.Company,
	|	DocumentTable.Counterparty,
	|	DocumentTable.DoOperationsByDocuments,
	|	DocumentTable.Contract,
	|	CASE
	|		WHEN DocumentTable.DoOperationsByDocuments
	|			THEN DocumentTable.DocumentWhere
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.Order REFS Document.PurchaseOrder
	|				AND DocumentTable.Order <> VALUE(Document.PurchaseOrder.EmptyRef)
	|				AND DocumentTable.DoOperationsByOrders
	|			THEN DocumentTable.Order
	|		ELSE VALUE(Document.PurchaseOrder.EmptyRef)
	|	END,
	|	DocumentTable.GLAccountVendorSettlements,
	|	DocumentTable.SettlementsCurrency,
	|	DocumentTable.SettlemensTypeWhere
	|
	|INDEX BY
	|	Company,
	|	Counterparty,
	|	Contract,
	|	Currency,
	|	Document,
	|	Order,
	|	SettlementsType,
	|	GLAccount";
	
	Query.Execute();
	
	// Setting the exclusive lock for the controlled balances of settlements with suppliers.
	Query.Text =
	"SELECT
	|	TemporaryTableAccountsPayable.Company AS Company,
	|	TemporaryTableAccountsPayable.Counterparty AS Counterparty,
	|	TemporaryTableAccountsPayable.Contract AS Contract,
	|	TemporaryTableAccountsPayable.Document AS Document,
	|	TemporaryTableAccountsPayable.Order AS Order,
	|	TemporaryTableAccountsPayable.SettlementsType AS SettlementsType
	|FROM
	|	TemporaryTableAccountsPayable AS TemporaryTableAccountsPayable";
	
	QueryResult = Query.Execute();
	
	Block = New DataLock;
	LockItem = Block.Add("AccumulationRegister.AccountsPayable");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = QueryResult;
	
	For Each ColumnQueryResult IN QueryResult.Columns Do
		LockItem.UseFromDataSource(ColumnQueryResult.Name, ColumnQueryResult.Name);
	EndDo;
	Block.Lock();
	
	QueryNumber = 0;
	Query.Text = SmallBusinessServer.GetQueryTextExchangeRatesDifferencesAccountsPayable(Query.TempTablesManager, True, QueryNumber);
	ResultsArray = Query.ExecuteBatch();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableAccountsPayable", ResultsArray[QueryNumber].Unload());
	
EndProcedure

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableCustomerAccounts(DocumentRefPurchaseInvoice, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	
	Query.SetParameter("Ref", DocumentRefPurchaseInvoice);
	Query.SetParameter("PointInTime", New Boundary(StructureAdditionalProperties.ForPosting.PointInTime, BoundaryType.Including));
	Query.SetParameter("ControlPeriod", StructureAdditionalProperties.ForPosting.PointInTime.Date);
	Query.SetParameter("Company", StructureAdditionalProperties.ForPosting.Company);
	Query.SetParameter("DebtCancelling", NStr("en='Debt reversal';ru='Сторнирование долга';vi='Ghi đảo nợ'"));
	Query.SetParameter("PrepaymentRecovery", NStr("en='Restore prepayment';ru='Восстановление предоплаты';vi='Khôi phục trả trước'"));
	Query.SetParameter("ExchangeDifference", NStr("en='Exchange rate difference';ru='Курсовая разница';vi='Chênh lệch tỷ giá'"));
	
	Query.Text =
	"SELECT
	|	MAX(DocumentTable.LineNumber) AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&DebtCancelling AS ContentOfAccountingRecord,
	|	DocumentTable.Period AS Date,
	|	DocumentTable.Company AS Company,
	|	DocumentTable.Counterparty AS Counterparty,
	|	DocumentTable.GLAccountCustomerSettlements AS GLAccount,
	|	DocumentTable.Contract AS Contract,
	|	CASE
	|		WHEN DocumentTable.DoOperationsByDocuments
	|			THEN CASE
	|					WHEN DocumentTable.BasisDocument = VALUE(Document.CustomerInvoice.EmptyRef)
	|							OR DocumentTable.BasisDocument = VALUE(Document.CustomerOrder.EmptyRef)
	|							OR DocumentTable.BasisDocument = VALUE(Document.PurchaseOrder.EmptyRef)
	|							OR DocumentTable.BasisDocument = VALUE(Document.GoodsReceipt.EmptyRef)
	|							OR DocumentTable.BasisDocument = VALUE(Document.SupplierInvoiceForPayment.EmptyRef)
	|							OR DocumentTable.BasisDocument = UNDEFINED
	|						THEN DocumentTable.Document
	|					ELSE DocumentTable.BasisDocument
	|				END
	|		ELSE UNDEFINED
	|	END AS Document,
	|	CASE
	|		WHEN DocumentTable.Order = UNDEFINED
	|				OR Not DocumentTable.DoOperationsByOrders
	|			THEN VALUE(Document.CustomerOrder.EmptyRef)
	|		ELSE DocumentTable.Order
	|	END AS Order,
	|	DocumentTable.SettlementsCurrency AS Currency,
	|	VALUE(Enum.SettlementsTypes.Debt) AS SettlementsType,
	|	-SUM(DocumentTable.Amount) AS Amount,
	|	-SUM(DocumentTable.AmountCur) AS AmountCur,
	|	-SUM(DocumentTable.Amount) AS AmountForBalance,
	|	-SUM(DocumentTable.AmountCur) AS AmountCurForBalance
	|INTO TemporaryTableAccountsReceivable
	|FROM
	|	TemporaryTableInventory AS DocumentTable
	|WHERE
	|	DocumentTable.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromCustomer)
	|
	|GROUP BY
	|	DocumentTable.Period,
	|	DocumentTable.Company,
	|	DocumentTable.Counterparty,
	|	DocumentTable.Contract,
	|	CASE
	|		WHEN DocumentTable.DoOperationsByDocuments
	|			THEN CASE
	|					WHEN DocumentTable.BasisDocument = VALUE(Document.CustomerInvoice.EmptyRef)
	|							OR DocumentTable.BasisDocument = VALUE(Document.CustomerOrder.EmptyRef)
	|							OR DocumentTable.BasisDocument = VALUE(Document.PurchaseOrder.EmptyRef)
	|							OR DocumentTable.BasisDocument = VALUE(Document.GoodsReceipt.EmptyRef)
	|							OR DocumentTable.BasisDocument = VALUE(Document.SupplierInvoiceForPayment.EmptyRef)
	|							OR DocumentTable.BasisDocument = UNDEFINED
	|						THEN DocumentTable.Document
	|					ELSE DocumentTable.BasisDocument
	|				END
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.Order = UNDEFINED
	|				OR Not DocumentTable.DoOperationsByOrders
	|			THEN VALUE(Document.CustomerOrder.EmptyRef)
	|		ELSE DocumentTable.Order
	|	END,
	|	DocumentTable.SettlementsCurrency,
	|	DocumentTable.GLAccountCustomerSettlements
	|
	|UNION ALL
	|
	|SELECT
	|	MAX(DocumentTable.LineNumber),
	|	VALUE(AccumulationRecordType.Expense),
	|	&PrepaymentRecovery,
	|	DocumentTable.Period,
	|	DocumentTable.Company,
	|	DocumentTable.Counterparty,
	|	DocumentTable.GLAccountCustomerSettlements,
	|	DocumentTable.Contract,
	|	CASE
	|		WHEN DocumentTable.DoOperationsByDocuments
	|			THEN CASE
	|					WHEN DocumentTable.BasisDocument = VALUE(Document.CustomerInvoice.EmptyRef)
	|							OR DocumentTable.BasisDocument = VALUE(Document.CustomerOrder.EmptyRef)
	|							OR DocumentTable.BasisDocument = VALUE(Document.PurchaseOrder.EmptyRef)
	|							OR DocumentTable.BasisDocument = VALUE(Document.GoodsReceipt.EmptyRef)
	|							OR DocumentTable.BasisDocument = VALUE(Document.SupplierInvoiceForPayment.EmptyRef)
	|							OR DocumentTable.BasisDocument = UNDEFINED
	|						THEN DocumentTable.Document
	|					ELSE DocumentTable.BasisDocument
	|				END
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.Order = UNDEFINED
	|				OR Not DocumentTable.DoOperationsByOrders
	|			THEN VALUE(Document.CustomerOrder.EmptyRef)
	|		ELSE DocumentTable.Order
	|	END,
	|	DocumentTable.SettlementsCurrency,
	|	DocumentTable.SettlemensTypeWhere,
	|	-SUM(DocumentTable.Amount),
	|	-SUM(DocumentTable.AmountCur),
	|	-SUM(DocumentTable.Amount),
	|	-SUM(DocumentTable.AmountCur)
	|FROM
	|	TemporaryTablePrepayment AS DocumentTable
	|WHERE
	|	DocumentTable.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromCustomer)
	|
	|GROUP BY
	|	DocumentTable.Period,
	|	DocumentTable.Company,
	|	DocumentTable.Counterparty,
	|	DocumentTable.Contract,
	|	CASE
	|		WHEN DocumentTable.DoOperationsByDocuments
	|			THEN CASE
	|					WHEN DocumentTable.BasisDocument = VALUE(Document.CustomerInvoice.EmptyRef)
	|							OR DocumentTable.BasisDocument = VALUE(Document.CustomerOrder.EmptyRef)
	|							OR DocumentTable.BasisDocument = VALUE(Document.PurchaseOrder.EmptyRef)
	|							OR DocumentTable.BasisDocument = VALUE(Document.GoodsReceipt.EmptyRef)
	|							OR DocumentTable.BasisDocument = VALUE(Document.SupplierInvoiceForPayment.EmptyRef)
	|							OR DocumentTable.BasisDocument = UNDEFINED
	|						THEN DocumentTable.Document
	|					ELSE DocumentTable.BasisDocument
	|				END
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.Order = UNDEFINED
	|				OR Not DocumentTable.DoOperationsByOrders
	|			THEN VALUE(Document.CustomerOrder.EmptyRef)
	|		ELSE DocumentTable.Order
	|	END,
	|	DocumentTable.SettlemensTypeWhere,
	|	DocumentTable.SettlementsCurrency,
	|	DocumentTable.GLAccountCustomerSettlements
	|
	|UNION ALL
	|
	|SELECT
	|	MAX(DocumentTable.LineNumber),
	|	VALUE(AccumulationRecordType.Receipt),
	|	&PrepaymentRecovery,
	|	DocumentTable.Period,
	|	DocumentTable.Company,
	|	DocumentTable.Counterparty,
	|	DocumentTable.VendorAdvancesGLAccount,
	|	DocumentTable.Contract,
	|	CASE
	|		WHEN DocumentTable.DoOperationsByDocuments
	|			THEN DocumentTable.Document
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.Order = UNDEFINED
	|				OR Not DocumentTable.DoOperationsByOrders
	|			THEN VALUE(Document.CustomerOrder.EmptyRef)
	|		ELSE DocumentTable.Order
	|	END,
	|	DocumentTable.SettlementsCurrency,
	|	DocumentTable.SettlementsType,
	|	-SUM(DocumentTable.Amount),
	|	-SUM(DocumentTable.AmountCur),
	|	SUM(DocumentTable.Amount),
	|	SUM(DocumentTable.AmountCur)
	|FROM
	|	TemporaryTablePrepayment AS DocumentTable
	|WHERE
	|	DocumentTable.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromCustomer)
	|
	|GROUP BY
	|	DocumentTable.Period,
	|	DocumentTable.Company,
	|	DocumentTable.Counterparty,
	|	DocumentTable.Contract,
	|	CASE
	|		WHEN DocumentTable.DoOperationsByDocuments
	|			THEN DocumentTable.Document
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.Order = UNDEFINED
	|				OR Not DocumentTable.DoOperationsByOrders
	|			THEN VALUE(Document.CustomerOrder.EmptyRef)
	|		ELSE DocumentTable.Order
	|	END,
	|	DocumentTable.VendorAdvancesGLAccount,
	|	DocumentTable.SettlementsCurrency,
	|	DocumentTable.SettlementsType";
	
	Query.Execute();
	
	// Setting the exclusive lock for the controlled balances of settlements with suppliers.
	Query.Text =
	"SELECT
	|	TemporaryTableAccountsReceivable.Company AS Company,
	|	TemporaryTableAccountsReceivable.Counterparty AS Counterparty,
	|	TemporaryTableAccountsReceivable.Contract AS Contract,
	|	TemporaryTableAccountsReceivable.Document AS Document,
	|	TemporaryTableAccountsReceivable.Order AS Order,
	|	TemporaryTableAccountsReceivable.SettlementsType AS SettlementsType
	|FROM
	|	TemporaryTableAccountsReceivable";
	
	QueryResult = Query.Execute();
	
	Block = New DataLock;
	LockItem = Block.Add("AccumulationRegister.AccountsReceivable");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = QueryResult;
	
	For Each ColumnQueryResult IN QueryResult.Columns Do
		LockItem.UseFromDataSource(ColumnQueryResult.Name, ColumnQueryResult.Name);
	EndDo;
	Block.Lock();
	
	QueryNumber = 0;
	Query.Text = SmallBusinessServer.GetQueryTextCurrencyExchangeRateAccountsReceivable(Query.TempTablesManager, False, QueryNumber);
	ResultsArray = Query.ExecuteBatch();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableAccountsReceivable", ResultsArray[QueryNumber].Unload());
	
EndProcedure

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableIncomeAndExpensesRetained(DocumentRefPurchaseInvoice, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	
	Query.SetParameter("Ref", DocumentRefPurchaseInvoice);
	Query.SetParameter("Company", StructureAdditionalProperties.ForPosting.Company);
	Query.SetParameter("IncomeAndExpensesAccountingCashMethod", StructureAdditionalProperties.AccountingPolicy.IncomeAndExpensesAccountingCashMethod);
	
	Query.Text =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.Period AS Period,
	|	DocumentTable.Company AS Company,
	|	CASE
	|		WHEN DocumentTable.DoOperationsByDocuments
	|			THEN &Ref
	|		ELSE UNDEFINED
	|	END AS Document,
	|	DocumentTable.BusinessActivitySales AS BusinessActivity,
	//( elmi #11
	//|	DocumentTable.Amount AS AmountExpenses
	|	DocumentTable.Amount - DocumentTable.VATAmount AS AmountExpense
	//) elmi
	|FROM
	|	TemporaryTableInventory AS DocumentTable
	|WHERE
	|	&IncomeAndExpensesAccountingCashMethod
	|	AND DocumentTable.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceiptFromVendor)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt),
	|	DocumentTable.LineNumber,
	|	DocumentTable.Period,
	|	DocumentTable.Company,
	|	CASE
	|		WHEN DocumentTable.DoOperationsByDocuments
	|			THEN &Ref
	|		ELSE UNDEFINED
	|	END,
	|	DocumentTable.BusinessActivity,
	//( elmi #11
	//|	DocumentTable.Amount
	|	DocumentTable.Amount - DocumentTable.VATAmount
	//) elmi
	|FROM
	|	TemporaryTableExpenses AS DocumentTable
	|WHERE
	|	&IncomeAndExpensesAccountingCashMethod
	|	AND DocumentTable.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceiptFromVendor)
	|
	|ORDER BY
	|	LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentTable.Company AS Company,
	|	SUM(DocumentTable.Amount) AS AmountToBeWrittenOff
	|FROM
	|	TemporaryTablePrepayment AS DocumentTable
	|WHERE
	|	&IncomeAndExpensesAccountingCashMethod
	|	AND DocumentTable.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceiptFromVendor)
	|
	|GROUP BY
	|	DocumentTable.Company
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.Item AS Item
	|FROM
	|	TemporaryTablePrepayment AS DocumentTable
	|WHERE
	|	&IncomeAndExpensesAccountingCashMethod
	|	AND DocumentTable.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceiptFromVendor)
	|
	|ORDER BY
	|	LineNumber";

	ResultsArray = Query.ExecuteBatch();
	
	TableInventoryIncomeAndExpensesRetained = ResultsArray[0].Unload();
	SelectionOfQueryResult = ResultsArray[1].Select();
	
	TablePrepaymentIncomeAndExpensesRetained = TableInventoryIncomeAndExpensesRetained.Copy();
	TablePrepaymentIncomeAndExpensesRetained.Clear();
	
	If SelectionOfQueryResult.Next() Then
		AmountToBeWrittenOff = SelectionOfQueryResult.AmountToBeWrittenOff;
		For Each StringInventoryIncomeAndExpensesRetained IN TableInventoryIncomeAndExpensesRetained Do
			If AmountToBeWrittenOff = 0 Then
				Continue
			ElsIf StringInventoryIncomeAndExpensesRetained.AmountExpense <= AmountToBeWrittenOff Then
				StringPrepaymentIncomeAndExpensesRetained = TablePrepaymentIncomeAndExpensesRetained.Add();
				FillPropertyValues(StringPrepaymentIncomeAndExpensesRetained, StringInventoryIncomeAndExpensesRetained);
				AmountToBeWrittenOff = AmountToBeWrittenOff - StringInventoryIncomeAndExpensesRetained.AmountExpense;
			ElsIf StringInventoryIncomeAndExpensesRetained.AmountExpense > AmountToBeWrittenOff Then
				StringPrepaymentIncomeAndExpensesRetained = TablePrepaymentIncomeAndExpensesRetained.Add();
				FillPropertyValues(StringPrepaymentIncomeAndExpensesRetained, StringInventoryIncomeAndExpensesRetained);
				StringPrepaymentIncomeAndExpensesRetained.AmountExpense = AmountToBeWrittenOff;
				AmountToBeWrittenOff = 0;
			EndIf;
		EndDo;
	EndIf;
	
	For Each StringPrepaymentIncomeAndExpensesRetained IN TablePrepaymentIncomeAndExpensesRetained Do
		StringInventoryIncomeAndExpensesRetained = TableInventoryIncomeAndExpensesRetained.Add();
		FillPropertyValues(StringInventoryIncomeAndExpensesRetained, StringPrepaymentIncomeAndExpensesRetained);
		StringInventoryIncomeAndExpensesRetained.RecordType = AccumulationRecordType.Expense;
	EndDo;
	
	SelectionOfQueryResult = ResultsArray[2].Select();
	
	If SelectionOfQueryResult.Next() Then
		Item = SelectionOfQueryResult.Item;
	Else
		Item = Catalogs.CashFlowItems.PaymentToVendor;
	EndIf;

	Query.Text =
	"SELECT
	|	Table.LineNumber AS LineNumber,
	|	Table.Period AS Period,
	|	Table.Company AS Company,
	|	Table.Document AS Document,
	|	&Item AS Item,
	|	Table.BusinessActivity AS BusinessActivity,
	|	Table.AmountExpense AS AmountExpense
	|INTO TemporaryTablePrepaidIncomeAndExpensesRetained
	|FROM
	|	&Table AS Table";
	Query.SetParameter("Table", TablePrepaymentIncomeAndExpensesRetained);
	Query.SetParameter("Item", Item);
	
	Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableIncomeAndExpensesRetained", TableInventoryIncomeAndExpensesRetained);
	
EndProcedure // GenerateTableIncomeAndExpensesRetained()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableIncomeAndExpensesUndistributed(DocumentRefPurchaseInvoice, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	
	Query.SetParameter("IncomeAndExpensesAccountingCashMethod", StructureAdditionalProperties.AccountingPolicy.IncomeAndExpensesAccountingCashMethod);
	
	Query.Text =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DocumentTable.Period AS Period,
	|	DocumentTable.Company AS Company,
	|	CASE
	|		WHEN DocumentTable.DoOperationsByDocuments
	|			THEN DocumentTable.Document
	|		ELSE UNDEFINED
	|	END AS Document,
	|	DocumentTable.Item AS Item,
	|	DocumentTable.Amount AS AmountExpense
	|FROM
	|	TemporaryTablePrepayment AS DocumentTable
	|WHERE
	|	&IncomeAndExpensesAccountingCashMethod
	|	AND DocumentTable.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceiptFromVendor)";
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableIncomeAndExpensesUndistributed", QueryResult.Unload());
	
EndProcedure // GenerateTableIncomeAndExpensesUndistributed()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableIncomeAndExpensesCashMethod(DocumentRefPurchaseInvoice, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	
	Query.SetParameter("Ref", DocumentRefPurchaseInvoice);
	Query.SetParameter("Company", StructureAdditionalProperties.ForPosting.Company);
	Query.SetParameter("PointInTime", New Boundary(StructureAdditionalProperties.ForPosting.PointInTime, BoundaryType.Including));
	Query.SetParameter("IncomeAndExpensesAccountingCashMethod", StructureAdditionalProperties.AccountingPolicy.IncomeAndExpensesAccountingCashMethod);
	
	Query.Text =
	"SELECT
	|	DocumentTable.DocumentDate AS Period,
	|	DocumentTable.Company AS Company,
	|	UNDEFINED AS BusinessActivity,
	|	DocumentTable.Item AS Item,
	|	-DocumentTable.Amount AS AmountExpense
	|FROM
	|	TemporaryTablePrepayment AS DocumentTable
	|WHERE
	|	&IncomeAndExpensesAccountingCashMethod
	|	AND DocumentTable.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceiptFromVendor)
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Period,
	|	Table.Company,
	|	Table.BusinessActivity,
	|	Table.Item,
	|	Table.AmountExpense
	|FROM
	|	TemporaryTablePrepaidIncomeAndExpensesRetained AS Table";
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableIncomeAndExpensesCashMethod", QueryResult.Unload());
	
EndProcedure // GenerateTableIncomeAndExpensesCashMethod() 

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableRetailAmountAccounting(DocumentRefPurchaseInvoice, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.SetParameter("Ref", DocumentRefPurchaseInvoice);
	Query.SetParameter("PointInTime", New Boundary(StructureAdditionalProperties.ForPosting.PointInTime, BoundaryType.Including));
	Query.SetParameter("ControlPeriod", StructureAdditionalProperties.ForPosting.PointInTime.Date);
	Query.SetParameter("Company", StructureAdditionalProperties.ForPosting.Company);
	Query.SetParameter("RetailIncome", NStr("en='Receipt to retail';ru='Поступление в розницу';vi='Thu tiền bán lẻ'"));
	Query.SetParameter("ExchangeDifference", NStr("en='Exchange rate difference';ru='Курсовая разница';vi='Chênh lệch tỷ giá'"));
	
	Query.Text =
	"SELECT
	|	DocumentTable.Period AS Date,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.Company AS Company,
	|	DocumentTable.RetailPriceKind AS RetailPriceKind,
	|	DocumentTable.ProductsAndServices AS ProductsAndServices,
	|	DocumentTable.Characteristic AS Characteristic,
	|	DocumentTable.StructuralUnit AS StructuralUnit,
	|	DocumentTable.PriceCurrency AS Currency,
	|	DocumentTable.GLAccountInRetail AS GLAccount,
	|	DocumentTable.MarkupGLAccount AS MarkupGLAccount,
	|	SUM(CAST(ProductsAndServicesPricesSliceLast.Price * DocumentTable.Quantity * CurrencyPriceExchangeRate.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate * CurrencyPriceExchangeRate.Multiplicity) / ISNULL(ProductsAndServicesPricesSliceLast.MeasurementUnit.Factor, 1) AS NUMBER(15, 2))) AS Amount,
	|	SUM(CAST(ProductsAndServicesPricesSliceLast.Price * DocumentTable.Quantity / ISNULL(ProductsAndServicesPricesSliceLast.MeasurementUnit.Factor, 1) AS NUMBER(15, 2))) AS AmountCur,
	|	SUM(CAST(ProductsAndServicesPricesSliceLast.Price * DocumentTable.Quantity * CurrencyPriceExchangeRate.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate * CurrencyPriceExchangeRate.Multiplicity) / ISNULL(ProductsAndServicesPricesSliceLast.MeasurementUnit.Factor, 1) AS NUMBER(15, 2))) AS AmountForBalance,
	|	SUM(CAST(ProductsAndServicesPricesSliceLast.Price * DocumentTable.Quantity / ISNULL(ProductsAndServicesPricesSliceLast.MeasurementUnit.Factor, 1) AS NUMBER(15, 2))) AS AmountCurForBalance,
	|	SUM(CASE
	|			WHEN DocumentTable.IncludeExpensesInCostPrice
	|				THEN DocumentTable.Amount + DocumentTable.AmountExpenses
	|			ELSE DocumentTable.Amount
	|		END) AS Cost,
	|	&RetailIncome AS ContentOfAccountingRecord
	|INTO TemporaryTableRetailAmountAccounting
	|FROM
	|	TemporaryTableInventory AS DocumentTable
	|		LEFT JOIN InformationRegister.ProductsAndServicesPrices.SliceLast(
	|				&PointInTime,
	|				(PriceKind, ProductsAndServices, Characteristic) In
	|					(SELECT
	|						TemporaryTableInventory.RetailPriceKind,
	|						TemporaryTableInventory.ProductsAndServices,
	|						TemporaryTableInventory.Characteristic
	|					FROM
	|						TemporaryTableInventory)) AS ProductsAndServicesPricesSliceLast
	|		ON DocumentTable.ProductsAndServices = ProductsAndServicesPricesSliceLast.ProductsAndServices
	|			AND DocumentTable.RetailPriceKind = ProductsAndServicesPricesSliceLast.PriceKind
	|			AND DocumentTable.Characteristic = ProductsAndServicesPricesSliceLast.Characteristic
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
	|				&PointInTime,
	|				Currency In
	|					(SELECT
	|						ConstantAccountingCurrency.Value
	|					FROM
	|						Constant.AccountingCurrency AS ConstantAccountingCurrency)) AS ManagCurrencyRates
	|		ON (TRUE)
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(&PointInTime, ) AS CurrencyPriceExchangeRate
	|		ON DocumentTable.PriceCurrency = CurrencyPriceExchangeRate.Currency
	|WHERE
	|	DocumentTable.RetailTransferAccrualAccounting
	|
	|GROUP BY
	|	DocumentTable.Period,
	|	DocumentTable.LineNumber,
	|	DocumentTable.Company,
	|	DocumentTable.RetailPriceKind,
	|	DocumentTable.ProductsAndServices,
	|	DocumentTable.Characteristic,
	|	DocumentTable.StructuralUnit,
	|	DocumentTable.PriceCurrency,
	|	DocumentTable.GLAccountInRetail,
	|	DocumentTable.MarkupGLAccount
	|
	|INDEX BY
	|	Company,
	|	StructuralUnit,
	|	Currency,
	|	GLAccount";
	
	Query.Execute();
	
	// Setting of the exclusive lock of the cash funds controlled balances.
	Query.Text =
	"SELECT
	|	TemporaryTableRetailAmountAccounting.Company AS Company,
	|	TemporaryTableRetailAmountAccounting.StructuralUnit AS StructuralUnit,
	|	TemporaryTableRetailAmountAccounting.Currency AS Currency
	|FROM
	|	TemporaryTableRetailAmountAccounting AS TemporaryTableRetailAmountAccounting";
	
	QueryResult = Query.Execute();
	
	Block = New DataLock;
	LockItem = Block.Add("AccumulationRegister.RetailAmountAccounting");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = QueryResult;
	
	For Each ColumnQueryResult IN QueryResult.Columns Do
		LockItem.UseFromDataSource(ColumnQueryResult.Name, ColumnQueryResult.Name);
	EndDo;
	Block.Lock();
	
	QueryNumber = 0;
	Query.Text = SmallBusinessServer.GetQueryTextExchangeRateDifferencesRetailAmountAccounting(Query.TempTablesManager, QueryNumber);
	ResultsArray = Query.ExecuteBatch();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableRetailAmountAccounting", ResultsArray[QueryNumber].Unload());
	
EndProcedure // GenerateTableIncomeAndExpenses()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableManagerial(DocumentRefPurchaseInvoice, StructureAdditionalProperties)
	
	//( elmi #11
    Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
    "SELECT
	|	Sum(TemporaryTable.VATAmount) AS VATInventory ,
	|	Sum(TemporaryTable.VATAmountCur) AS VATInventoryCur 
	|FROM
	|	TemporaryTableInventory AS TemporaryTable
	|GROUP BY
	|TemporaryTable.Period,
	|TemporaryTable.Company	";
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	VATInventory = 0;
	VATInventoryCur = 0;
	
	While Selection.Next() Do  
		  VATInventory    = Selection.VATInventory;
	      VATInventoryCur = Selection.VATInventoryCur;
	EndDo;

    Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
    "SELECT
	|	Sum(TemporaryTable.VATAmount) AS VATExpenses ,
	|	Sum(TemporaryTable.VATAmountCur) AS VATExpensesCur 
	|FROM
	|	TemporaryTableExpenses AS TemporaryTable
	|GROUP BY
	|TemporaryTable.Period,
	|TemporaryTable.Company	";
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	VATExpenses = 0;
	VATExpensesCur = 0;
	
	While Selection.Next() Do  
		  VATExpenses    = Selection.VATExpenses;
	      VATExpensesCur = Selection.VATExpensesCur;
	EndDo;
	//) elmi
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	1 AS Ordering,
	|	TableManagerial.LineNumber AS LineNumber,
	|	TableManagerial.Period AS Period,
	|	TableManagerial.Company AS Company,
	|	VALUE(Catalog.PlanningPeriods.Actual) AS PlanningPeriod,
	|	TableManagerial.GLAccount AS AccountDr,
	|	CASE
	|		WHEN TableManagerial.GLAccount.Currency
	|			THEN TableManagerial.SettlementsCurrency
	|		ELSE UNDEFINED
	|	END AS CurrencyDr,
	|	CASE
	|		WHEN TableManagerial.GLAccount.Currency
	//( elmi #11
	//|			THEN TableManagerial.AmountCur
	|			THEN TableManagerial.AmountCur - TableManagerial.VATAmountCur
	//) elmi
	|		ELSE 0
	|	END AS AmountCurDr,
	|	TableManagerial.GLAccountVendorSettlements AS AccountCr,
	|	CASE
	|		WHEN TableManagerial.GLAccountVendorSettlements.Currency
	|			THEN TableManagerial.SettlementsCurrency
	|		ELSE UNDEFINED
	|	END AS CurrencyCr,
	|	CASE
	|		WHEN TableManagerial.GLAccountVendorSettlements.Currency
	//( elmi #11
	//|			THEN TableManagerial.AmountCur
	|			THEN TableManagerial.AmountCur - TableManagerial.VATAmountCur
	//) elmi
	|		ELSE 0
	|	END AS AmountCurCr,
	//( elmi #11
	//|	TableManagerial.Amount AS Amount,
	|	TableManagerial.Amount - TableManagerial.VATAmount AS Amount,
	//) elmi
	|	&InventoryReceipt AS Content
	|FROM
	|	TemporaryTableInventory AS TableManagerial
	|WHERE
	|	TableManagerial.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceiptFromVendor)
	|	AND Not TableManagerial.IncludeExpensesInCostPrice
	|
	|UNION ALL
	|
	|SELECT
	|	2,
	|	TableManagerial.LineNumber,
	|	TableManagerial.Period,
	|	TableManagerial.Company,
	|	VALUE(Catalog.PlanningPeriods.Actual),
	|	TableManagerial.GLAccount,
	|	CASE
	|		WHEN TableManagerial.GLAccount.Currency
	|			THEN TableManagerial.SettlementsCurrency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN TableManagerial.GLAccount.Currency
	//( elmi #11
	//|			THEN TableManagerial.AmountCur + TableManagerial.AmountExpensesCur
	|			THEN TableManagerial.AmountCur + TableManagerial.AmountExpensesCur -  TableManagerial.VATAmountCur
	//) elmi

	|		ELSE 0
	|	END,
	|	TableManagerial.GLAccountVendorSettlements,
	|	CASE
	|		WHEN TableManagerial.GLAccountVendorSettlements.Currency
	|			THEN TableManagerial.SettlementsCurrency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN TableManagerial.GLAccountVendorSettlements.Currency
	//( elmi #11
	//|			THEN TableManagerial.AmountCur + TableManagerial.AmountExpensesCur
	|			THEN TableManagerial.AmountCur + TableManagerial.AmountExpensesCur -  TableManagerial.VATAmountCur
	//) elmi
	|		ELSE 0
	|	END,
	//( elmi #11
	//|	TableManagerial.Amount + TableManagerial.AmountExpenses,
	|	TableManagerial.Amount + TableManagerial.AmountExpenses - TableManagerial.VATAmount,
	//) elmi
	|	&InventoryReceipt
	|FROM
	|	TemporaryTableInventory AS TableManagerial
	|WHERE
	|	TableManagerial.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceiptFromVendor)
	|	AND TableManagerial.IncludeExpensesInCostPrice
	|
	|UNION ALL
	|
	|SELECT
	|	3,
	|	TableManagerial.LineNumber,
	|	TableManagerial.Period,
	|	TableManagerial.Company,
	|	VALUE(Catalog.PlanningPeriods.Actual),
	|	TableManagerial.GLAccount,
	|	CASE
	|		WHEN TableManagerial.GLAccount.Currency
	|			THEN TableManagerial.SettlementsCurrency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN TableManagerial.GLAccount.Currency
	//( elmi #11
	//|			THEN TableManagerial.AmountCur
	|			THEN TableManagerial.AmountCur  -  TableManagerial.VATAmountCur
	//) elmi
	|		ELSE 0
	|	END,
	|	TableManagerial.GLAccountVendorSettlements,
	|	CASE
	|		WHEN TableManagerial.GLAccountVendorSettlements.Currency
	|			THEN TableManagerial.SettlementsCurrency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN TableManagerial.GLAccountVendorSettlements.Currency
	//( elmi #11
	//|			THEN TableManagerial.AmountCur
	|			THEN TableManagerial.AmountCur  -  TableManagerial.VATAmountCur
	//) elmi
	|		ELSE 0
	|	END,
	//( elmi #11
	//|	TableManagerial.Amount,
	|	TableManagerial.Amount - TableManagerial.VATAmount,
	//) elmi
	|	&OtherExpenses
	|FROM
	|	TemporaryTableExpenses AS TableManagerial
	|WHERE
	|	TableManagerial.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceiptFromVendor)
	|	AND Not TableManagerial.IncludeExpensesInCostPrice
	|
	|UNION ALL
	|
	|SELECT
	|	5,
	|	TableManagerial.LineNumber,
	|	TableManagerial.Period,
	|	TableManagerial.Company,
	|	VALUE(Catalog.PlanningPeriods.Actual),
	|	TableManagerial.GLAccountCustomerSettlements,
	|	CASE
	|		WHEN TableManagerial.GLAccountCustomerSettlements.Currency
	|			THEN TableManagerial.SettlementsCurrency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN TableManagerial.GLAccountCustomerSettlements.Currency
	//( elmi #11
	//|			THEN -TableManagerial.AmountCur
	|			THEN - (TableManagerial.AmountCur - TableManagerial.VATAmountCur)
	//) elmi
	|		ELSE 0
	|	END,
	|	TableManagerial.AccountStatementSales,
	|	UNDEFINED,
	|	0,
	//( elmi #11
	//|	-TableManagerial.Amount,
	|	-TableManagerial.Amount - TableManagerial.VATAmount ,
	//) elmi
	|	&IncomeReversal
	|FROM
	|	TemporaryTableInventory AS TableManagerial
	|WHERE
	|	TableManagerial.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromCustomer)
	|	AND Not TableManagerial.ProductsOnCommission
	|
	|UNION ALL
	|
	|SELECT
	|	6,
	|	TableManagerial.LineNumber,
	|	TableManagerial.Period,
	|	TableManagerial.Company,
	|	VALUE(Catalog.PlanningPeriods.Actual),
	|	TableManagerial.GLAccountCost,
	|	UNDEFINED,
	|	0,
	|	TableManagerial.GLAccount,
	|	UNDEFINED,
	|	0,
	|	-TableManagerial.Cost,
	|	&ReversalOfReserves
	|FROM
	|	TemporaryTableInventory AS TableManagerial
	|WHERE
	|	TableManagerial.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromCustomer)
	|	AND ISNULL(TableManagerial.BasisDocument.OperationKind, VALUE(Enum.OperationKindsCustomerInvoice.EmptyRef)) <> VALUE(Enum.OperationKindsCustomerInvoice.SaleToCustomer)
	|	AND ISNULL(TableManagerial.BasisDocument.OperationKind, VALUE(Enum.OperationKindsCustomerOrder.EmptyRef)) <> VALUE(Enum.OperationKindsCustomerOrder.WorkOrder)
	|	AND Not TableManagerial.ProductsOnCommission
	|	AND TableManagerial.Cost > 0
	|
	|UNION ALL
	|
	|SELECT
	|	7,
	|	1,
	|	DocumentTable.Period,
	|	DocumentTable.Company,
	|	VALUE(Catalog.PlanningPeriods.Actual),
	|	DocumentTable.GLAccountVendorSettlements,
	|	CASE
	|		WHEN DocumentTable.GLAccountVendorSettlementsCurrency
	|			THEN DocumentTable.SettlementsCurrency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.GLAccountVendorSettlementsCurrency
	|			THEN DocumentTable.AmountCur
	|		ELSE 0
	|	END,
	|	DocumentTable.VendorAdvancesGLAccount,
	|	CASE
	|		WHEN DocumentTable.VendorAdvancesGLAccountCurrency
	|			THEN DocumentTable.SettlementsCurrency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.VendorAdvancesGLAccountCurrency
	|			THEN DocumentTable.AmountCur
	|		ELSE 0
	|	END,
	|	DocumentTable.Amount,
	|	&SetOffAdvancePayment
	|FROM
	|	(SELECT
	|		DocumentTable.Period AS Period,
	|		DocumentTable.Company AS Company,
	|		DocumentTable.VendorAdvancesGLAccount AS VendorAdvancesGLAccount,
	|		DocumentTable.VendorAdvancesGLAccountCurrency AS VendorAdvancesGLAccountCurrency,
	|		DocumentTable.GLAccountVendorSettlements AS GLAccountVendorSettlements,
	|		DocumentTable.GLAccountVendorSettlementsCurrency AS GLAccountVendorSettlementsCurrency,
	|		DocumentTable.SettlementsCurrency AS SettlementsCurrency,
	|		SUM(DocumentTable.AmountCur) AS AmountCur,
	|		SUM(DocumentTable.Amount) AS Amount
	|	FROM
	|		(SELECT
	|			DocumentTable.Period AS Period,
	|			DocumentTable.Company AS Company,
	|			DocumentTable.VendorAdvancesGLAccount AS VendorAdvancesGLAccount,
	|			DocumentTable.VendorAdvancesGLAccount.Currency AS VendorAdvancesGLAccountCurrency,
	|			DocumentTable.GLAccountVendorSettlements AS GLAccountVendorSettlements,
	|			DocumentTable.GLAccountVendorSettlements.Currency AS GLAccountVendorSettlementsCurrency,
	|			DocumentTable.SettlementsCurrency AS SettlementsCurrency,
	|			DocumentTable.AmountCur AS AmountCur,
	|			DocumentTable.Amount AS Amount
	|		FROM
	|			TemporaryTablePrepayment AS DocumentTable
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			DocumentTable.Date,
	|			DocumentTable.Company,
	|			DocumentTable.Counterparty.VendorAdvancesGLAccount,
	|			DocumentTable.Counterparty.VendorAdvancesGLAccount.Currency,
	|			DocumentTable.Counterparty.GLAccountVendorSettlements,
	|			DocumentTable.Counterparty.GLAccountVendorSettlements.Currency,
	|			DocumentTable.Currency,
	|			0,
	|			DocumentTable.AmountOfExchangeDifferences
	|		FROM
	|			TemporaryTableOfExchangeRateDifferencesAccountsPayable AS DocumentTable
	|		WHERE
	|			DocumentTable.SettlementsType = VALUE(Enum.SettlementsTypes.Advance)) AS DocumentTable
	|	
	|	GROUP BY
	|		DocumentTable.Period,
	|		DocumentTable.Company,
	|		DocumentTable.VendorAdvancesGLAccount,
	|		DocumentTable.VendorAdvancesGLAccountCurrency,
	|		DocumentTable.GLAccountVendorSettlements,
	|		DocumentTable.GLAccountVendorSettlementsCurrency,
	|		DocumentTable.SettlementsCurrency
	|	
	|	HAVING
	|		(SUM(DocumentTable.Amount) >= 0.005
	|			OR SUM(DocumentTable.Amount) <= -0.005
	|			OR SUM(DocumentTable.AmountCur) >= 0.005
	|			OR SUM(DocumentTable.AmountCur) <= -0.005)) AS DocumentTable
	|WHERE
	|	&OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceiptFromVendor)
	|
	|UNION ALL
	|
	|SELECT
	|	8,
	|	DocumentTable.LineNumber,
	|	DocumentTable.Period,
	|	DocumentTable.Company,
	|	VALUE(Catalog.PlanningPeriods.Actual),
	|	DocumentTable.CustomerAdvancesGLAccount,
	|	CASE
	|		WHEN DocumentTable.CustomerAdvancesGLAccount.Currency
	|			THEN DocumentTable.SettlementsCurrency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.CustomerAdvancesGLAccount.Currency
	|			THEN -DocumentTable.AmountCur
	|		ELSE 0
	|	END,
	|	DocumentTable.GLAccountCustomerSettlements,
	|	CASE
	|		WHEN DocumentTable.GLAccountCustomerSettlements.Currency
	|			THEN DocumentTable.SettlementsCurrency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.GLAccountCustomerSettlements.Currency
	|			THEN -DocumentTable.AmountCur
	|		ELSE 0
	|	END,
	|	-DocumentTable.Amount,
	|	&PrepaymentReversal
	|FROM
	|	TemporaryTablePrepayment AS DocumentTable
	|WHERE
	|	DocumentTable.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromCustomer)
	|
	|UNION ALL
	|
	|SELECT
	|	9,
	|	1,
	|	TableManagerial.Date,
	|	TableManagerial.Company,
	|	VALUE(Catalog.PlanningPeriods.Actual),
	|	CASE
	|		WHEN TableManagerial.AmountOfExchangeDifferences > 0
	|			THEN &NegativeExchangeDifferenceAccountOfAccounting
	|		ELSE TableManagerial.GLAccount
	|	END,
	|	CASE
	|		WHEN TableManagerial.AmountOfExchangeDifferences < 0
	|				AND TableManagerial.GLAccountForeignCurrency
	|			THEN TableManagerial.Currency
	|		ELSE UNDEFINED
	|	END,
	|	0,
	|	CASE
	|		WHEN TableManagerial.AmountOfExchangeDifferences > 0
	|			THEN TableManagerial.GLAccount
	|		ELSE &PositiveExchangeDifferenceGLAccount
	|	END,
	|	CASE
	|		WHEN TableManagerial.AmountOfExchangeDifferences > 0
	|				AND TableManagerial.GLAccountForeignCurrency
	|			THEN TableManagerial.Currency
	|		ELSE UNDEFINED
	|	END,
	|	0,
	|	CASE
	|		WHEN TableManagerial.AmountOfExchangeDifferences > 0
	|			THEN TableManagerial.AmountOfExchangeDifferences
	|		ELSE -TableManagerial.AmountOfExchangeDifferences
	|	END,
	|	&ExchangeDifference
	|FROM
	|	(SELECT
	|		TableOfExchangeRateDifferencesAccountsPayable.Date AS Date,
	|		TableOfExchangeRateDifferencesAccountsPayable.Company AS Company,
	|		TableOfExchangeRateDifferencesAccountsPayable.GLAccount AS GLAccount,
	|		TableOfExchangeRateDifferencesAccountsPayable.GLAccountForeignCurrency AS GLAccountForeignCurrency,
	|		TableOfExchangeRateDifferencesAccountsPayable.Currency AS Currency,
	|		SUM(TableOfExchangeRateDifferencesAccountsPayable.AmountOfExchangeDifferences) AS AmountOfExchangeDifferences
	|	FROM
	|		(SELECT
	|			DocumentTable.Date AS Date,
	|			DocumentTable.Company AS Company,
	|			DocumentTable.GLAccount AS GLAccount,
	|			DocumentTable.GLAccount.Currency AS GLAccountForeignCurrency,
	|			DocumentTable.Currency AS Currency,
	|			DocumentTable.AmountOfExchangeDifferences AS AmountOfExchangeDifferences
	|		FROM
	|			TemporaryTableOfExchangeRateDifferencesAccountsPayable AS DocumentTable
	|		WHERE
	|			DocumentTable.SettlementsType = VALUE(Enum.SettlementsTypes.Debt)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			DocumentTable.Date,
	|			DocumentTable.Company,
	|			DocumentTable.GLAccount,
	|			DocumentTable.GLAccount.Currency,
	|			DocumentTable.Currency,
	|			DocumentTable.AmountOfExchangeDifferences
	|		FROM
	|			TemporaryTableOfExchangeRateDifferencesAccountsPayable AS DocumentTable
	|		WHERE
	|			DocumentTable.SettlementsType = VALUE(Enum.SettlementsTypes.Advance)) AS TableOfExchangeRateDifferencesAccountsPayable
	|	
	|	GROUP BY
	|		TableOfExchangeRateDifferencesAccountsPayable.Date,
	|		TableOfExchangeRateDifferencesAccountsPayable.Company,
	|		TableOfExchangeRateDifferencesAccountsPayable.GLAccount,
	|		TableOfExchangeRateDifferencesAccountsPayable.GLAccountForeignCurrency,
	|		TableOfExchangeRateDifferencesAccountsPayable.Currency
	|	
	|	HAVING
	|		(SUM(TableOfExchangeRateDifferencesAccountsPayable.AmountOfExchangeDifferences) >= 0.005
	|			OR SUM(TableOfExchangeRateDifferencesAccountsPayable.AmountOfExchangeDifferences) <= -0.005)) AS TableManagerial
	|
	|UNION ALL
	|
	|SELECT
	|	10,
	|	TableManagerial.LineNumber,
	|	TableManagerial.Date,
	|	TableManagerial.Company,
	|	VALUE(Catalog.PlanningPeriods.Actual),
	|	CASE
	|		WHEN TableManagerial.AmountOfExchangeDifferences > 0
	|			THEN TableManagerial.GLAccount
	|		ELSE &NegativeExchangeDifferenceAccountOfAccounting
	|	END,
	|	CASE
	|		WHEN TableManagerial.AmountOfExchangeDifferences > 0
	|				AND TableManagerial.GLAccount.Currency
	|			THEN TableManagerial.Currency
	|		ELSE UNDEFINED
	|	END,
	|	0,
	|	CASE
	|		WHEN TableManagerial.AmountOfExchangeDifferences > 0
	|			THEN &PositiveExchangeDifferenceGLAccount
	|		ELSE TableManagerial.GLAccount
	|	END,
	|	CASE
	|		WHEN TableManagerial.AmountOfExchangeDifferences < 0
	|				AND TableManagerial.GLAccount.Currency
	|			THEN TableManagerial.Currency
	|		ELSE UNDEFINED
	|	END,
	|	0,
	|	CASE
	|		WHEN TableManagerial.AmountOfExchangeDifferences > 0
	|			THEN TableManagerial.AmountOfExchangeDifferences
	|		ELSE -TableManagerial.AmountOfExchangeDifferences
	|	END,
	|	&ExchangeDifference
	|FROM
	|	TemporaryTableExchangeRateDifferencesAccountsReceivable AS TableManagerial
	|
	|UNION ALL
	|
	|SELECT
	|	11,
	|	TableManagerial.LineNumber,
	|	TableManagerial.Date,
	|	TableManagerial.Company,
	|	VALUE(Catalog.PlanningPeriods.Actual),
	|	TableManagerial.GLAccount,
	|	CASE
	|		WHEN TableManagerial.GLAccount.Currency
	|			THEN TableManagerial.Currency
	|		ELSE UNDEFINED
	|	END,
	|	0,
	|	TableManagerial.MarkupGLAccount,
	|	CASE
	|		WHEN TableManagerial.MarkupGLAccount.Currency
	|			THEN TableManagerial.Currency
	|		ELSE UNDEFINED
	|	END,
	|	0,
	|	TableManagerial.Amount - TableManagerial.Cost,
	|	&Markup
	|FROM
	|	TemporaryTableRetailAmountAccounting AS TableManagerial
	|
	//( elmi #11
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	12,
	|	TableManagerial.LineNumber,
	|	TableManagerial.Period,
	|	TableManagerial.Company,
	|	VALUE(Catalog.PlanningPeriods.Actual),
	|	&TextVATExpenses,
	|	UNDEFINED,
	|	0,
	|	TableManagerial.GLAccountVendorSettlements,
	|	CASE
	|		WHEN TableManagerial.GLAccountVendorSettlements.Currency
	|			THEN TableManagerial.SettlementsCurrency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN TableManagerial.GLAccountVendorSettlements.Currency
	|			THEN &VATInventoryCur + &VATExpensesCur
	|		ELSE 0
	|	END,
	|	&VATInventory + &VATExpenses,
	|	&PreVAT
	|FROM
	|	TemporaryTableInventory AS TableManagerial
    |WHERE
	|	TableManagerial.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceiptFromVendor)
	|	AND  TableManagerial.IncludeExpensesInCostPrice AND  &VATInventory + &VATExpenses > 0
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	13,
	|	TableManagerial.LineNumber,
	|	TableManagerial.Period,
	|	TableManagerial.Company,
	|	VALUE(Catalog.PlanningPeriods.Actual),
	|	&TextVATExpenses,
	|	UNDEFINED,
	|	0,
	|	TableManagerial.GLAccountVendorSettlements,
	|	CASE
	|		WHEN TableManagerial.GLAccountVendorSettlements.Currency
	|			THEN TableManagerial.SettlementsCurrency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN TableManagerial.GLAccountVendorSettlements.Currency
	|			THEN &VATInventoryCur 
	|		ELSE 0
	|	END,
	|	&VATInventory ,
	|	&PreVATInventory
	|FROM
	|	TemporaryTableInventory AS TableManagerial
	|
	|WHERE
	|	TableManagerial.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceiptFromVendor)
	|	AND NOT TableManagerial.IncludeExpensesInCostPrice AND  &VATInventory  > 0
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	14,
	|	TableManagerial.LineNumber,
	|	TableManagerial.Period,
	|	TableManagerial.Company,
	|	VALUE(Catalog.PlanningPeriods.Actual),
	|	&TextVATExpenses,
	|	UNDEFINED,
	|	0,
	|	TableManagerial.GLAccountVendorSettlements,
	|	CASE
	|		WHEN TableManagerial.GLAccountVendorSettlements.Currency
	|			THEN TableManagerial.SettlementsCurrency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN TableManagerial.GLAccountVendorSettlements.Currency
	|			THEN &VATExpensesCur 
	|		ELSE 0
	|	END,
	|	&VATExpenses ,
	|	&PreVATExpenses
	|FROM
	|	TemporaryTableInventory AS TableManagerial
	|
	|WHERE
	|	TableManagerial.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceiptFromVendor)
	|	AND NOT TableManagerial.IncludeExpensesInCostPrice AND  &VATExpenses  > 0
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	15,
	|	TableManagerial.LineNumber,
	|	TableManagerial.Period,
	|	TableManagerial.Company,
	|	VALUE(Catalog.PlanningPeriods.Actual),
	|	TableManagerial.GLAccountCustomerSettlements,
	|	UNDEFINED,
	|	0,
	|	&TextVATExpenses,
	|	UNDEFINED,
	|	0,
	|	-&VATInventory,
	|	&PreVATInventory
	|FROM
	|	TemporaryTableInventory AS TableManagerial
	|
	|WHERE
	|	TableManagerial.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromCustomer)
	|	AND  (NOT TableManagerial.IncludeExpensesInCostPrice) AND  &VATInventory  > 0
	//) elmi
	|
	|ORDER BY
	|	Ordering,
	|	LineNumber";
		
	Query.SetParameter("InventoryReceipt", NStr("en='Inventory receipt';ru='Прием запасов';vi='Tiếp nhận vật tư'"));
	Query.SetParameter("OtherExpenses", NStr("en='Expense recording';ru='Отражение затрат';vi='Phản ánh chi phí'"));
	Query.SetParameter("SetOffAdvancePayment", NStr("en='Prepayment setoff';ru='Зачет предоплаты';vi='Khấu trừ trả trước'"));
	Query.SetParameter("PrepaymentReversal", NStr("en='Prepayment reversal';ru='Сторнирование предоплаты';vi='Sửa lại khoản trả trước'"));
	Query.SetParameter("ReversalOfReserves", NStr("en='Cost reversal';ru='Сторнирование себестоимости';vi='Ghi đảo giá thành'"));
	Query.SetParameter("IncomeReversal", NStr("en='Revenue reversal';ru='Сторнирование выручки';vi='Ghi đảo doanh thu'"));
	Query.SetParameter("Markup", NStr("en='Markup';ru='Наценка';vi='Phụ thu'"));
	Query.SetParameter("PositiveExchangeDifferenceGLAccount", ChartsOfAccounts.Managerial.OtherIncome);
	Query.SetParameter("NegativeExchangeDifferenceAccountOfAccounting", ChartsOfAccounts.Managerial.OtherExpenses);
	Query.SetParameter("ExchangeDifference", NStr("en='Exchange rate difference';ru='Курсовая разница';vi='Chênh lệch tỷ giá'"));
	Query.SetParameter("OperationKind", DocumentRefPurchaseInvoice.OperationKind);
	//( elmi #11
	Query.SetParameter("PreVATInventory", NStr("en='pre VAT goods';vi='hàng hóa trước VAT'"));
	Query.SetParameter("PreVATExpenses", NStr("en='pre VAT expenses';vi='chi phí trước VAT'"));
	Query.SetParameter("PreVAT", NStr("en=' pre VAT';vi='trước thuế GTGt'"));
	Query.SetParameter("TextVATExpenses",  ChartsOfAccounts.Managerial.Taxes);
	Query.SetParameter("VATExpenses", VATExpenses);
	Query.SetParameter("VATInventory", VATInventory);
	Query.SetParameter("VATExpensesCur", VATExpensesCur);
	Query.SetParameter("VATInventoryCur", VATInventoryCur);
	//) elmi
	
	
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	
	While Selection.Next() Do  
		NewEntry = StructureAdditionalProperties.TableForRegisterRecords.TableManagerial.Add();
		FillPropertyValues(NewEntry, Selection);
	EndDo;
	
EndProcedure // GenerateTableManagerial()



#Region DiscountCards

// Generates values table containing data for posting on the SalesByDiscountCard register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableSalesByDiscountCard(DocumentRefPurchaseInvoice, StructureAdditionalProperties)
	
	If DocumentRefPurchaseInvoice.OperationKind <> Enums.OperationKindsSupplierInvoice.ReturnFromCustomer Then
		StructureAdditionalProperties.TableForRegisterRecords.Insert("SaleByDiscountCardTable", New ValueTable);
		Return;
	EndIf;
	If DocumentRefPurchaseInvoice.DiscountCard.IsEmpty() Then
		StructureAdditionalProperties.TableForRegisterRecords.Insert("SaleByDiscountCardTable", New ValueTable);
		Return;
	EndIf;
	
	DiscountCardInDocument = DocumentRefPurchaseInvoice.DiscountCard;
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Parameters.Insert("DiscountCard", DiscountCardInDocument);
	Query.Parameters.Insert("CardOwner", DiscountCardInDocument.CardOwner);
	Query.Text =
	"SELECT
	|	TableSales.Period AS Period,
	|	&DiscountCard AS DiscountCard,
	|	&CardOwner AS CardOwner,
	|	-SUM(TableSales.Amount) AS Amount
	|FROM
	|	TemporaryTableInventory AS TableSales
	|WHERE
	|	TableSales.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromCustomer)
	|
	|GROUP BY
	|	TableSales.Period";
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("SaleByDiscountCardTable", QueryResult.Unload());
	
EndProcedure // GenerateTableSalesByDiscountCard()

#EndRegion

// Initializes the tables of values that contain the data of the document table sections.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure InitializeDocumentData(DocumentRefPurchaseInvoice, StructureAdditionalProperties) Export
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	CurrencyRatesSliceLast.Currency AS Currency,
	|	CurrencyRatesSliceLast.ExchangeRate AS ExchangeRate,
	|	CurrencyRatesSliceLast.Multiplicity AS Multiplicity
	|INTO TemporaryTableCurrencyRatesSliceLatest
	|FROM
	|	InformationRegister.CurrencyRates.SliceLast(&PointInTime, Currency IN (&AccountingCurrency, &CurrencyNational)) AS CurrencyRatesSliceLast
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SupplierInvoiceInventory.LineNumber AS LineNumber,
	|	SupplierInvoiceInventory.Ref.OperationKind AS OperationKind,
	|	SupplierInvoiceInventory.Ref AS Document,
	|	SupplierInvoiceInventory.Ref.BasisDocument AS BasisDocument,
	|	SupplierInvoiceInventory.Ref.Counterparty AS Counterparty,
	|	SupplierInvoiceInventory.Ref.Counterparty.DoOperationsByContracts AS DoOperationsByContracts,
	|	SupplierInvoiceInventory.Ref.Counterparty.DoOperationsByDocuments AS DoOperationsByDocuments,
	|	SupplierInvoiceInventory.Ref.Counterparty.DoOperationsByOrders AS DoOperationsByOrders,
	|	SupplierInvoiceInventory.Ref.Counterparty.TrackPaymentsByBills AS TrackPaymentsByBills,
	|	SupplierInvoiceInventory.Ref.Contract AS Contract,
	|	SupplierInvoiceInventory.Ref.Responsible AS Responsible,
	|	SupplierInvoiceInventory.Ref.StructuralUnit.MarkupGLAccount AS MarkupGLAccount,
	|	SupplierInvoiceInventory.Ref.StructuralUnit.RetailPriceKind AS RetailPriceKind,
	|	SupplierInvoiceInventory.Ref.StructuralUnit.RetailPriceKind.PriceCurrency AS PriceCurrency,
	|	SupplierInvoiceInventory.Ref.StructuralUnit.GLAccountInRetail AS GLAccountInRetail,
	|	CASE
	|		WHEN SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceiptFromVendor)
	|				OR SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionForCommission)
	|				OR SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionIntoProcessing)
	|				OR SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionForSafeCustody)
	|			THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	CASE
	|		WHEN SupplierInvoiceInventory.Ref.StructuralUnit.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.RetailAccrualAccounting)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS RetailTransferAccrualAccounting,
	|	SupplierInvoiceInventory.Ref.Date AS Period,
	|	&Company AS Company,
	|	CASE
	|		WHEN SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromAgent)
	|				OR SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromSubcontractor)
	|				OR SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromSafeCustody)
	|			THEN &Company
	|		ELSE UNDEFINED
	|	END AS CorrOrganization,
	|	SupplierInvoiceInventory.Ref.StructuralUnit AS StructuralUnit,
	|	CASE
	|		WHEN SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromAgent)
	|				OR SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromSubcontractor)
	|				OR SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromSafeCustody)
	|			THEN SupplierInvoiceInventory.Ref.Counterparty
	|		ELSE UNDEFINED
	|	END AS StructuralUnitCorr,
	|	CASE
	|		WHEN SupplierInvoiceInventory.Ref.StructuralUnit.OrderWarehouse
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS OrderWarehouse,
	|	CASE
	|		WHEN &AccountingByCells
	|			THEN SupplierInvoiceInventory.Ref.Cell
	|		ELSE UNDEFINED
	|	END AS Cell,
	|	CASE
	|		WHEN SupplierInvoiceInventory.Ref.StructuralUnit.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.RetailAccrualAccounting)
	|			THEN SupplierInvoiceInventory.Ref.StructuralUnit.GLAccountInRetail
	|		ELSE SupplierInvoiceInventory.ProductsAndServices.InventoryGLAccount
	|	END AS GLAccount,
	|	CASE
	|		WHEN SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromAgent)
	|				OR SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromSubcontractor)
	|				OR SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromSafeCustody)
	|			THEN SupplierInvoiceInventory.ProductsAndServices.InventoryGLAccount
	|		ELSE UNDEFINED
	|	END AS CorrGLAccount,
	|	SupplierInvoiceInventory.ProductsAndServices AS ProductsAndServices,
	|	CASE
	|		WHEN SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromAgent)
	|				OR SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromSubcontractor)
	|				OR SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromSafeCustody)
	|			THEN SupplierInvoiceInventory.ProductsAndServices
	|		ELSE UNDEFINED
	|	END AS ProductsAndServicesCorr,
	|	CASE
	|		WHEN &UseCharacteristics
	|			THEN SupplierInvoiceInventory.Characteristic
	|		ELSE VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	|	END AS Characteristic,
	|	CASE
	|		WHEN SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromAgent)
	|				OR SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromSubcontractor)
	|				OR SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromSafeCustody)
	|			THEN CASE
	|					WHEN &UseCharacteristics
	|						THEN SupplierInvoiceInventory.Characteristic
	|					ELSE VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	|				END
	|		ELSE UNDEFINED
	|	END AS CharacteristicCorr,
	|	CASE
	|		WHEN &UseBatches
	|			THEN SupplierInvoiceInventory.Batch
	|		ELSE VALUE(Catalog.ProductsAndServicesBatches.EmptyRef)
	|	END AS Batch,
	|	CASE
	|		WHEN SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromAgent)
	|				OR SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromSubcontractor)
	|				OR SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromSafeCustody)
	|			THEN CASE
	|					WHEN &UseBatches
	|						THEN SupplierInvoiceInventory.Batch
	|					ELSE VALUE(Catalog.ProductsAndServicesBatches.EmptyRef)
	|				END
	|		ELSE UNDEFINED
	|	END AS BatchCorr,
	|	CASE
	|		WHEN SupplierInvoiceInventory.Order REFS Document.CustomerOrder
	|				AND SupplierInvoiceInventory.Order <> VALUE(Document.CustomerOrder.EmptyRef)
	|			THEN SupplierInvoiceInventory.Order
	|		WHEN SupplierInvoiceInventory.Order REFS Document.PurchaseOrder
	|				AND SupplierInvoiceInventory.Order <> VALUE(Document.PurchaseOrder.EmptyRef)
	|			THEN SupplierInvoiceInventory.Order
	|		ELSE UNDEFINED
	|	END AS Order,
	|	CASE
	|		WHEN SupplierInvoiceInventory.Order REFS Document.CustomerOrder
	|				AND SupplierInvoiceInventory.Order.OperationKind = VALUE(Enum.OperationKindsCustomerOrder.WorkOrder)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS WorkOrder,
	|	CASE
	|		WHEN SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromAgent)
	|				OR SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromSubcontractor)
	|				OR SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromSafeCustody)
	|			THEN CASE
	|					WHEN SupplierInvoiceInventory.Order REFS Document.CustomerOrder
	|							AND SupplierInvoiceInventory.Order <> VALUE(Document.CustomerOrder.EmptyRef)
	|						THEN SupplierInvoiceInventory.Order
	|					WHEN SupplierInvoiceInventory.Order REFS Document.PurchaseOrder
	|							AND SupplierInvoiceInventory.Order <> VALUE(Document.PurchaseOrder.EmptyRef)
	|						THEN SupplierInvoiceInventory.Order
	|					ELSE UNDEFINED
	|				END
	|		ELSE UNDEFINED
	|	END AS CorrOrder,
	|	CASE
	|		WHEN &UseBatches
	|				AND SupplierInvoiceInventory.Batch.Status = VALUE(Enum.BatchStatuses.ProductsOnCommission)
	|				AND SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromCustomer)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ProductsOnCommission,
	|	CASE
	|		WHEN SupplierInvoiceInventory.Ref.BasisDocument REFS Document.CustomerInvoice
	|				AND SupplierInvoiceInventory.Ref.BasisDocument <> VALUE(Document.CustomerInvoice.EmptyRef)
	|			THEN SupplierInvoiceInventory.Ref.BasisDocument.Department
	|		ELSE SupplierInvoiceInventory.Ref.Department
	|	END AS DepartmentSales,
	|	SupplierInvoiceInventory.CountryOfOrigin As CountryOfOrigin,
	|	SupplierInvoiceInventory.CCDNo As CCDNo,
	|	SupplierInvoiceInventory.ProductsAndServices.BusinessActivity AS BusinessActivitySales,
	|	SupplierInvoiceInventory.ProductsAndServices.BusinessActivity.GLAccountRevenueFromSales AS AccountStatementSales,
	|	SupplierInvoiceInventory.ProductsAndServices.BusinessActivity.GLAccountCostOfSales AS GLAccountCost,
	|	CASE
	|		WHEN VALUETYPE(SupplierInvoiceInventory.MeasurementUnit) = Type(Catalog.UOMClassifier)
	|			THEN SupplierInvoiceInventory.Quantity
	|		ELSE SupplierInvoiceInventory.Quantity * SupplierInvoiceInventory.MeasurementUnit.Factor
	|	END AS Quantity,
	|	SupplierInvoiceInventory.VATRate AS VATRate,
	|	CAST(CASE
	|			WHEN SupplierInvoiceInventory.Ref.IncludeVATInPrice
	|				THEN 0
	|			ELSE CASE
	|					WHEN SupplierInvoiceInventory.Ref.DocumentCurrency = &CurrencyNational
	|						THEN SupplierInvoiceInventory.VATAmount * RegCurrencyRates.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate * RegCurrencyRates.Multiplicity)
	|					ELSE SupplierInvoiceInventory.VATAmount * SupplierInvoiceInventory.Ref.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate * SupplierInvoiceInventory.Ref.Multiplicity)
	|				END
	|		END AS NUMBER(15, 2)) AS VATAmount,
	|	CAST(CASE
	|			WHEN SupplierInvoiceInventory.Ref.DocumentCurrency = &CurrencyNational
	|				THEN SupplierInvoiceInventory.VATAmount * RegCurrencyRates.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate * RegCurrencyRates.Multiplicity)
	|			ELSE SupplierInvoiceInventory.VATAmount * SupplierInvoiceInventory.Ref.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate * SupplierInvoiceInventory.Ref.Multiplicity)
	|		END AS NUMBER(15, 2)) AS AmountVATPurchaseSale,
	|	CAST(CASE
	|			WHEN SupplierInvoiceInventory.Ref.DocumentCurrency = &CurrencyNational
	|				THEN SupplierInvoiceInventory.Total * RegCurrencyRates.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate * RegCurrencyRates.Multiplicity)
	|			ELSE SupplierInvoiceInventory.Total * SupplierInvoiceInventory.Ref.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate * SupplierInvoiceInventory.Ref.Multiplicity)
	|		END AS NUMBER(15, 2)) AS Amount,
	|	CAST(CASE
	|			WHEN SupplierInvoiceInventory.Ref.DocumentCurrency = &CurrencyNational
	|				THEN SupplierInvoiceInventory.AmountExpenses * RegCurrencyRates.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate * RegCurrencyRates.Multiplicity)
	|			ELSE SupplierInvoiceInventory.AmountExpenses * SupplierInvoiceInventory.Ref.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate * SupplierInvoiceInventory.Ref.Multiplicity)
	|		END AS NUMBER(15, 2)) AS AmountExpenses,
	|	CAST(CASE
	|			WHEN SupplierInvoiceInventory.Ref.DocumentCurrency = &CurrencyNational
	|				THEN SupplierInvoiceInventory.AmountExpenses * RegCurrencyRates.ExchangeRate * SupplierInvoiceInventory.Ref.Multiplicity / (SupplierInvoiceInventory.Ref.ExchangeRate * RegCurrencyRates.Multiplicity)
	|			ELSE SupplierInvoiceInventory.AmountExpenses
	|		END AS NUMBER(15, 2)) AS AmountExpensesCur,
	|	CAST(CASE
	|			WHEN SupplierInvoiceInventory.Ref.DocumentCurrency = &CurrencyNational
	|				THEN SupplierInvoiceInventory.Cost * RegCurrencyRates.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate * RegCurrencyRates.Multiplicity)
	|			ELSE SupplierInvoiceInventory.Cost * SupplierInvoiceInventory.Ref.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate * SupplierInvoiceInventory.Ref.Multiplicity)
	|		END AS NUMBER(15, 2)) AS Cost,
	|	SupplierInvoiceInventory.Total AS SettlementsAmountTakenPassed,
	|	SupplierInvoiceInventory.Ref.IncludeExpensesInCostPrice AS IncludeExpensesInCostPrice,
	|	CASE
	|		WHEN SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromAgent)
	|				OR SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromSubcontractor)
	|				OR SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromSafeCustody)
	|				OR SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromCustomer)
	|					AND (ISNULL(SupplierInvoiceInventory.Ref.BasisDocument.OperationKind, VALUE(Enum.OperationKindsCustomerInvoice.EmptyRef)) = VALUE(Enum.OperationKindsCustomerInvoice.SaleToCustomer)
	|						OR ISNULL(SupplierInvoiceInventory.Ref.BasisDocument.OperationKind, VALUE(Enum.OperationKindsCustomerOrder.EmptyRef)) = VALUE(Enum.OperationKindsCustomerOrder.WorkOrder))
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS FixedCost,
	|	CASE
	|		WHEN SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceiptFromVendor)
	|				OR SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionForCommission)
	|				OR SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionIntoProcessing)
	|				OR SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionForSafeCustody)
	|			THEN CAST(&InventoryReceipt AS String(100))
	|		WHEN SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromCustomer)
	|				OR SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromAgent)
	|				OR SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromSubcontractor)
	|				OR SupplierInvoiceInventory.Ref.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromSafeCustody)
	|			THEN CAST(&InventoryWriteOff AS String(100))
	|	END AS ContentOfAccountingRecord,
	|	SupplierInvoiceInventory.Ref.Counterparty.GLAccountCustomerSettlements AS GLAccountCustomerSettlements,
	|	SupplierInvoiceInventory.Ref.Counterparty.GLAccountVendorSettlements AS GLAccountVendorSettlements,
	|	SupplierInvoiceInventory.Ref.Contract.SettlementsCurrency AS SettlementsCurrency,
	|	CAST(CASE
	|			WHEN SupplierInvoiceInventory.Ref.DocumentCurrency = &CurrencyNational
	|				THEN SupplierInvoiceInventory.Total * RegCurrencyRates.ExchangeRate * SupplierInvoiceInventory.Ref.Multiplicity / (SupplierInvoiceInventory.Ref.ExchangeRate * RegCurrencyRates.Multiplicity)
	|			ELSE SupplierInvoiceInventory.Total
	|		END AS NUMBER(15, 2)) AS AmountCur,
	|	CAST(CASE
	|			WHEN SupplierInvoiceInventory.Ref.IncludeVATInPrice
	|				THEN 0
	|			ELSE CASE
	|					WHEN SupplierInvoiceInventory.Ref.DocumentCurrency = &CurrencyNational
	|						THEN SupplierInvoiceInventory.VATAmount * RegCurrencyRates.ExchangeRate * SupplierInvoiceInventory.Ref.Multiplicity / (SupplierInvoiceInventory.Ref.ExchangeRate * RegCurrencyRates.Multiplicity)
	|					ELSE SupplierInvoiceInventory.VATAmount
	|				END
	|		END AS NUMBER(15, 2)) AS VATAmountCur,
	|	SupplierInvoiceInventory.ConnectionKey AS ConnectionKey
	|INTO TemporaryTableInventory
	|FROM
	|	Document.SupplierInvoice.Inventory AS SupplierInvoiceInventory
	|		LEFT JOIN TemporaryTableCurrencyRatesSliceLatest AS ManagCurrencyRates
	|		ON (ManagCurrencyRates.Currency = &AccountingCurrency)
	|		LEFT JOIN TemporaryTableCurrencyRatesSliceLatest AS RegCurrencyRates
	|		ON (RegCurrencyRates.Currency = &CurrencyNational)
	|WHERE
	|	SupplierInvoiceInventory.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PurchaseInvoiceExpenses.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	PurchaseInvoiceExpenses.Ref.Date AS Period,
	|	PurchaseInvoiceExpenses.Ref AS Document,
	|	PurchaseInvoiceExpenses.Ref.OperationKind AS OperationKind,
	|	&Company AS Company,
	|	PurchaseInvoiceExpenses.StructuralUnit AS StructuralUnit,
	|	PurchaseInvoiceExpenses.Ref.DocumentCurrency AS Currency,
	|	PurchaseInvoiceExpenses.ProductsAndServices.ExpensesGLAccount AS GLAccount,
	|	PurchaseInvoiceExpenses.ProductsAndServices AS ProductsAndServices,
	|	VALUE(Catalog.ProductsAndServices.EmptyRef) AS InventoryProductsAndServices,
	|	VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef) AS Characteristic,
	|	VALUE(Catalog.ProductsAndServicesBatches.EmptyRef) AS Batch,
	|	PurchaseInvoiceExpenses.Order AS Order,
	|	PurchaseInvoiceExpenses.PurchaseOrder AS PurchaseOrder,
	|	CASE
	|		WHEN VALUETYPE(PurchaseInvoiceExpenses.MeasurementUnit) = Type(Catalog.UOMClassifier)
	|			THEN PurchaseInvoiceExpenses.Quantity
	|		ELSE PurchaseInvoiceExpenses.Quantity * PurchaseInvoiceExpenses.MeasurementUnit.Factor
	|	END AS Quantity,
	|	PurchaseInvoiceExpenses.VATRate AS VATRate,
	|	CAST(CASE
	|			WHEN PurchaseInvoiceExpenses.Ref.DocumentCurrency = &CurrencyNational
	|				THEN PurchaseInvoiceExpenses.Total * RegCurrencyRates.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate * RegCurrencyRates.Multiplicity)
	|			ELSE PurchaseInvoiceExpenses.Total * PurchaseInvoiceExpenses.Ref.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate * PurchaseInvoiceExpenses.Ref.Multiplicity)
	|		END AS NUMBER(15, 2)) AS Amount,
	|	CAST(CASE
	|			WHEN PurchaseInvoiceExpenses.Ref.DocumentCurrency = &CurrencyNational
	|				THEN PurchaseInvoiceExpenses.Total * RegCurrencyRates.ExchangeRate * PurchaseInvoiceExpenses.Ref.Multiplicity / (PurchaseInvoiceExpenses.Ref.ExchangeRate * RegCurrencyRates.Multiplicity)
	|			ELSE PurchaseInvoiceExpenses.Total
	|		END AS NUMBER(15, 2)) AS AmountCur,
	|	CAST(CASE
	|			WHEN PurchaseInvoiceExpenses.Ref.IncludeVATInPrice
	|				THEN 0
	|			ELSE CASE
	|					WHEN PurchaseInvoiceExpenses.Ref.DocumentCurrency = &CurrencyNational
	|						THEN PurchaseInvoiceExpenses.VATAmount * RegCurrencyRates.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate * RegCurrencyRates.Multiplicity)
	|					ELSE PurchaseInvoiceExpenses.VATAmount * PurchaseInvoiceExpenses.Ref.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate * PurchaseInvoiceExpenses.Ref.Multiplicity)
	|				END
	|		END AS NUMBER(15, 2)) AS VATAmount,
	//( elmi #11
	|	CAST(CASE
	|			WHEN PurchaseInvoiceExpenses.Ref.IncludeVATInPrice
	|				THEN 0
	|			ELSE CASE
	|					WHEN PurchaseInvoiceExpenses.Ref.DocumentCurrency = &CurrencyNational
	|						THEN PurchaseInvoiceExpenses.VATAmount * RegCurrencyRates.ExchangeRate * PurchaseInvoiceExpenses.Ref.Multiplicity / (PurchaseInvoiceExpenses.Ref.ExchangeRate * RegCurrencyRates.Multiplicity)
	|					ELSE PurchaseInvoiceExpenses.VATAmount
	|				END
	|		END AS NUMBER(15, 2)) AS VATAmountCur,
	//) elmi
	|	CAST(CASE
	|			WHEN PurchaseInvoiceExpenses.Ref.DocumentCurrency = &CurrencyNational
	|				THEN PurchaseInvoiceExpenses.VATAmount * RegCurrencyRates.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate * RegCurrencyRates.Multiplicity)
	|			ELSE PurchaseInvoiceExpenses.VATAmount * PurchaseInvoiceExpenses.Ref.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate * PurchaseInvoiceExpenses.Ref.Multiplicity)
	|		END AS NUMBER(15, 2)) AS AmountVATPurchaseSale,
	|	PurchaseInvoiceExpenses.Ref.IncludeExpensesInCostPrice AS IncludeExpensesInCostPrice,
	|	CASE
	|		WHEN PurchaseInvoiceExpenses.ProductsAndServices.ExpensesGLAccount.TypeOfAccount = VALUE(Enum.GLAccountsTypes.Expenses)
	|				AND Not PurchaseInvoiceExpenses.Ref.IncludeExpensesInCostPrice
	|			THEN PurchaseInvoiceExpenses.BusinessActivity
	|		ELSE PurchaseInvoiceExpenses.ProductsAndServices.BusinessActivity
	|	END AS BusinessActivity,
	|	PurchaseInvoiceExpenses.Ref.Counterparty AS Counterparty,
	|	PurchaseInvoiceExpenses.Ref.Counterparty.DoOperationsByContracts AS DoOperationsByContracts,
	|	PurchaseInvoiceExpenses.Ref.Counterparty.DoOperationsByDocuments AS DoOperationsByDocuments,
	|	PurchaseInvoiceExpenses.Ref.Counterparty.DoOperationsByOrders AS DoOperationsByOrders,
	|	PurchaseInvoiceExpenses.Ref.Counterparty.TrackPaymentsByBills AS TrackPaymentsByBills,
	|	PurchaseInvoiceExpenses.Ref.Contract AS Contract,
	|	PurchaseInvoiceExpenses.Ref.Contract.SettlementsCurrency AS SettlementsCurrency,
	|	PurchaseInvoiceExpenses.Ref.Counterparty.GLAccountVendorSettlements AS GLAccountVendorSettlements,
	|	PurchaseInvoiceExpenses.ProductsAndServices.ExpensesGLAccount.TypeOfAccount AS TypeOfAccount
	|INTO TemporaryTableExpenses
	|FROM
	|	Document.SupplierInvoice.Expenses AS PurchaseInvoiceExpenses
	|		LEFT JOIN TemporaryTableCurrencyRatesSliceLatest AS ManagCurrencyRates
	|		ON (ManagCurrencyRates.Currency = &AccountingCurrency)
	|		LEFT JOIN TemporaryTableCurrencyRatesSliceLatest AS RegCurrencyRates
	|		ON (RegCurrencyRates.Currency = &CurrencyNational)
	|WHERE
	|	PurchaseInvoiceExpenses.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(DocumentTable.LineNumber) AS LineNumber,
	|	DocumentTable.Ref.OperationKind AS OperationKind,
	|	DocumentTable.Ref.Date AS Period,
	|	&Company AS Company,
	|	DocumentTable.Ref.Counterparty AS Counterparty,
	|	DocumentTable.Ref.Counterparty.DoOperationsByContracts AS DoOperationsByContracts,
	|	DocumentTable.Ref.Counterparty.DoOperationsByDocuments AS DoOperationsByDocuments,
	|	DocumentTable.Ref.Counterparty.DoOperationsByOrders AS DoOperationsByOrders,
	|	DocumentTable.Ref.Counterparty.TrackPaymentsByBills AS TrackPaymentsByBills,
	|	DocumentTable.Ref.Counterparty.GLAccountCustomerSettlements AS GLAccountCustomerSettlements,
	|	DocumentTable.Ref.Counterparty.CustomerAdvancesGLAccount AS CustomerAdvancesGLAccount,
	|	DocumentTable.Ref.Counterparty.GLAccountVendorSettlements AS GLAccountVendorSettlements,
	|	DocumentTable.Ref.Counterparty.VendorAdvancesGLAccount AS VendorAdvancesGLAccount,
	|	DocumentTable.Ref.Contract AS Contract,
	|	DocumentTable.Ref.Contract.SettlementsCurrency AS SettlementsCurrency,
	|	DocumentTable.Order AS Order,
	|	VALUE(Catalog.BusinessActivities.Other) AS BusinessActivitySales,
	|	VALUE(Enum.SettlementsTypes.Advance) AS SettlementsType,
	|	VALUE(Enum.SettlementsTypes.Debt) AS SettlemensTypeWhere,
	|	&Ref AS DocumentWhere,
	|	DocumentTable.Document AS Document,
	|	DocumentTable.Ref.BasisDocument AS BasisDocument,
	|	CASE
	|		WHEN Not DocumentTable.Ref.Counterparty.DoOperationsByDocuments
	|				OR VALUETYPE(DocumentTable.Document) = Type(Document.ExpenseReport)
	|				OR VALUETYPE(DocumentTable.Document) = Type(Document.Netting)
	|			THEN VALUE(Catalog.CashFlowItems.PaymentToVendor)
	|		ELSE CASE
	|				WHEN DocumentTable.Document REFS Document.PaymentExpense
	|					THEN CAST(DocumentTable.Document AS Document.PaymentExpense).Item
	|				WHEN DocumentTable.Document REFS Document.PaymentReceipt
	|					THEN CAST(DocumentTable.Document AS Document.PaymentReceipt).Item
	|				WHEN DocumentTable.Document REFS Document.CashReceipt
	|					THEN CAST(DocumentTable.Document AS Document.CashReceipt).Item
	|				WHEN DocumentTable.Document REFS Document.CashPayment
	|					THEN CAST(DocumentTable.Document AS Document.CashPayment).Item
	|				ELSE VALUE(Catalog.CashFlowItems.PaymentToVendor)
	|			END
	|	END AS Item,
	|	CASE
	|		WHEN DocumentTable.Ref.Counterparty.DoOperationsByDocuments
	|			THEN CASE
	|					WHEN DocumentTable.Document REFS Document.PaymentExpense
	|						THEN CAST(DocumentTable.Document AS Document.PaymentExpense).Date
	|					WHEN DocumentTable.Document REFS Document.PaymentReceipt
	|						THEN CAST(DocumentTable.Document AS Document.PaymentReceipt).Date
	|					WHEN DocumentTable.Document REFS Document.CashReceipt
	|						THEN CAST(DocumentTable.Document AS Document.CashReceipt).Date
	|					WHEN DocumentTable.Document REFS Document.CashPayment
	|						THEN CAST(DocumentTable.Document AS Document.CashPayment).Date
	|					WHEN DocumentTable.Document REFS Document.ExpenseReport
	|						THEN CAST(DocumentTable.Document AS Document.ExpenseReport).Date
	|					WHEN DocumentTable.Document REFS Document.Netting
	|						THEN CAST(DocumentTable.Document AS Document.Netting).Date
	|				END
	|		ELSE DocumentTable.Ref.Date
	|	END AS DocumentDate,
	|	SUM(CAST(DocumentTable.SettlementsAmount * DocumentTable.Ref.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * DocumentTable.Ref.Multiplicity) AS NUMBER(15, 2))) AS Amount,
	|	SUM(DocumentTable.SettlementsAmount) AS AmountCur
	|INTO TemporaryTablePrepayment
	|FROM
	|	Document.SupplierInvoice.Prepayment AS DocumentTable
	|		LEFT JOIN TemporaryTableCurrencyRatesSliceLatest AS AccountingCurrencyRatesSliceLast
	|		ON (AccountingCurrencyRatesSliceLast.Currency = &AccountingCurrency)
	|WHERE
	|	DocumentTable.Ref = &Ref
	|
	|GROUP BY
	|	DocumentTable.Ref,
	|	DocumentTable.Document,
	|	DocumentTable.Ref.Date,
	|	DocumentTable.Ref.Counterparty,
	|	DocumentTable.Ref.Contract,
	|	DocumentTable.Order,
	|	DocumentTable.Ref.Contract.SettlementsCurrency,
	|	DocumentTable.Ref.Counterparty.GLAccountCustomerSettlements,
	|	DocumentTable.Ref.Counterparty.CustomerAdvancesGLAccount,
	|	DocumentTable.Ref.Counterparty.GLAccountVendorSettlements,
	|	DocumentTable.Ref.Counterparty.VendorAdvancesGLAccount,
	|	DocumentTable.Ref.OperationKind,
	|	DocumentTable.Ref.BasisDocument,
	|	CASE
	|		WHEN Not DocumentTable.Ref.Counterparty.DoOperationsByDocuments
	|				OR VALUETYPE(DocumentTable.Document) = Type(Document.ExpenseReport)
	|				OR VALUETYPE(DocumentTable.Document) = Type(Document.Netting)
	|			THEN VALUE(Catalog.CashFlowItems.PaymentToVendor)
	|		ELSE CASE
	|				WHEN DocumentTable.Document REFS Document.PaymentExpense
	|					THEN CAST(DocumentTable.Document AS Document.PaymentExpense).Item
	|				WHEN DocumentTable.Document REFS Document.PaymentReceipt
	|					THEN CAST(DocumentTable.Document AS Document.PaymentReceipt).Item
	|				WHEN DocumentTable.Document REFS Document.CashReceipt
	|					THEN CAST(DocumentTable.Document AS Document.CashReceipt).Item
	|				WHEN DocumentTable.Document REFS Document.CashPayment
	|					THEN CAST(DocumentTable.Document AS Document.CashPayment).Item
	|				ELSE VALUE(Catalog.CashFlowItems.PaymentToVendor)
	|			END
	|	END,
	|	CASE
	|		WHEN DocumentTable.Ref.Counterparty.DoOperationsByDocuments
	|			THEN CASE
	|					WHEN DocumentTable.Document REFS Document.PaymentExpense
	|						THEN CAST(DocumentTable.Document AS Document.PaymentExpense).Date
	|					WHEN DocumentTable.Document REFS Document.PaymentReceipt
	|						THEN CAST(DocumentTable.Document AS Document.PaymentReceipt).Date
	|					WHEN DocumentTable.Document REFS Document.CashReceipt
	|						THEN CAST(DocumentTable.Document AS Document.CashReceipt).Date
	|					WHEN DocumentTable.Document REFS Document.CashPayment
	|						THEN CAST(DocumentTable.Document AS Document.CashPayment).Date
	|					WHEN DocumentTable.Document REFS Document.ExpenseReport
	|						THEN CAST(DocumentTable.Document AS Document.ExpenseReport).Date
	|					WHEN DocumentTable.Document REFS Document.Netting
	|						THEN CAST(DocumentTable.Document AS Document.Netting).Date
	|				END
	|		ELSE DocumentTable.Ref.Date
	|	END,
	|	DocumentTable.Ref.Counterparty.DoOperationsByContracts,
	|	DocumentTable.Ref.Counterparty.DoOperationsByDocuments,
	|	DocumentTable.Ref.Counterparty.DoOperationsByOrders,
	|	DocumentTable.Ref.Counterparty.TrackPaymentsByBills
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomerInvoiceSerialNumbers.ConnectionKey,
	|	CustomerInvoiceSerialNumbers.SerialNumber
	|INTO TemporaryTableSerialNumbers
	|FROM
	|	Document.SupplierInvoice.SerialNumbers AS CustomerInvoiceSerialNumbers
	|WHERE
	|	CustomerInvoiceSerialNumbers.Ref = &Ref 
	|	AND &UseSerialNumbers
	|	AND NOT CustomerInvoiceSerialNumbers.Ref.StructuralUnit.OrderWarehouse";
	
	Query.SetParameter("Ref", DocumentRefPurchaseInvoice);
	Query.SetParameter("Company", StructureAdditionalProperties.ForPosting.Company);
	Query.SetParameter("PointInTime", New Boundary(StructureAdditionalProperties.ForPosting.PointInTime, BoundaryType.Including));
	Query.SetParameter("UseCharacteristics", StructureAdditionalProperties.AccountingPolicy.UseCharacteristics);
	Query.SetParameter("UseBatches", StructureAdditionalProperties.AccountingPolicy.UseBatches);
	Query.SetParameter("AccountingByCells", StructureAdditionalProperties.AccountingPolicy.AccountingByCells);
	Query.SetParameter("UseSerialNumbers", StructureAdditionalProperties.AccountingPolicy.UseSerialNumbers);
	
	Query.SetParameter("InventoryReceipt", NStr("en='Inventory receipt';ru='Прием запасов';vi='Tiếp nhận vật tư'"));
	Query.SetParameter("InventoryWriteOff", NStr("en='Inventory write-off';ru='Списание запасов';vi='Ghi giảm vật tư'"));
	
	Query.SetParameter("AccountingCurrency", Constants.AccountingCurrency.Get());
	Query.SetParameter("CurrencyNational", Constants.NationalCurrency.Get());
	
	Query.ExecuteBatch();
	
	// Creation of document postings.
	SmallBusinessServer.GenerateTransactionsTable(DocumentRefPurchaseInvoice, StructureAdditionalProperties);
	
	GenerateTablePurchasing(DocumentRefPurchaseInvoice, StructureAdditionalProperties);
	GenerateTableSales(DocumentRefPurchaseInvoice, StructureAdditionalProperties);
	GenerateTableInventoryInWarehouses(DocumentRefPurchaseInvoice, StructureAdditionalProperties);
	GenerateTableInventoryForWarehouses(DocumentRefPurchaseInvoice, StructureAdditionalProperties);
	GenerateTableInventoryReceived(DocumentRefPurchaseInvoice, StructureAdditionalProperties);
	GenerateTableInventoryTransferred(DocumentRefPurchaseInvoice, StructureAdditionalProperties);
	GenerateTableCustomerOrders(DocumentRefPurchaseInvoice, StructureAdditionalProperties);
	GenerateTablePurchaseOrders(DocumentRefPurchaseInvoice, StructureAdditionalProperties);
	GenerateTableOrdersPlacement(DocumentRefPurchaseInvoice, StructureAdditionalProperties);
	GenerateTableInventoryDemand(DocumentRefPurchaseInvoice, StructureAdditionalProperties);
	GenerateTableInventory(DocumentRefPurchaseInvoice, StructureAdditionalProperties);
	GenerateTableAccountsPayable(DocumentRefPurchaseInvoice, StructureAdditionalProperties);
	GenerateTableCustomerAccounts(DocumentRefPurchaseInvoice, StructureAdditionalProperties);
	GenerateTableIncomeAndExpenses(DocumentRefPurchaseInvoice, StructureAdditionalProperties);
	GenerateTableIncomeAndExpensesRetained(DocumentRefPurchaseInvoice, StructureAdditionalProperties);
	GenerateTableIncomeAndExpensesUndistributed(DocumentRefPurchaseInvoice, StructureAdditionalProperties);
	GenerateTableIncomeAndExpensesCashMethod(DocumentRefPurchaseInvoice, StructureAdditionalProperties);
	GenerateTableRetailAmountAccounting(DocumentRefPurchaseInvoice, StructureAdditionalProperties);
	
	GenerateTableManagerial(DocumentRefPurchaseInvoice, StructureAdditionalProperties);
	
	// DiscountCards
	GenerateTableSalesByDiscountCard(DocumentRefPurchaseInvoice, StructureAdditionalProperties);
	
	// Serial numbers
	GenerateTableSerialNumbers(DocumentRefPurchaseInvoice, StructureAdditionalProperties);

	// Inventory by CCD
	SmallBusinessServer.GenerateTableInventoryByCCD(DocumentRefPurchaseInvoice, StructureAdditionalProperties);
EndProcedure // DocumentDataInitialization()

// Controls the occurrence of negative balances.
//
Procedure RunControl(DocumentRefPurchaseInvoice, AdditionalProperties, Cancel, PostingDelete = False) Export
	
	If Not SmallBusinessServer.RunBalanceControl() Then
		Return;
	EndIf;
	
	StructureTemporaryTables = AdditionalProperties.ForPosting.StructureTemporaryTables;
	
	// If temporary tables “RegisterRecordsInventoryChange”, “MovementsInventoryInWarehousesChange”,
	// “MovementsInventoryForWarehousesChange”,
	// “MovementsPassedInventoryChange”, “RegisterRecordsInventoryReceivedChange”,
	// “RegisterRecordsOrdersPlacementChange”, “RegisterRecordsInventoryDemandChange” contain records, it is required
	// to control goods implementation.
	If StructureTemporaryTables.RegisterRecordsInventoryChange
	 OR StructureTemporaryTables.RegisterRecordsInventoryInWarehousesChange
	 OR StructureTemporaryTables.RegisterRecordsInventoryForWarehousesChange
	 OR StructureTemporaryTables.RegisterRecordsInventoryTransferredChange
	 OR StructureTemporaryTables.RegisterRecordsInventoryReceivedChange
	 OR StructureTemporaryTables.RegisterRecordsOrdersPlacementChange
	 OR StructureTemporaryTables.RegisterRecordsCustomerOrdersChange
	 OR StructureTemporaryTables.RegisterRecordsPurchaseOrdersChange
	 OR StructureTemporaryTables.RegisterRecordsInventoryDemandChange
	 OR StructureTemporaryTables.RegisterRecordsSuppliersSettlementsChange
	 OR StructureTemporaryTables.RegisterRecordsInventoryByCCDChange
	 OR StructureTemporaryTables.RegisterRecordsRetailAmountAccountingUpdate Then
		
		QueryText =
		"SELECT
		|	RegisterRecordsInventoryInWarehousesChange.LineNumber AS LineNumber,
		|	RegisterRecordsInventoryInWarehousesChange.Company AS CompanyPresentation,
		|	RegisterRecordsInventoryInWarehousesChange.StructuralUnit AS StructuralUnitPresentation,
		|	RegisterRecordsInventoryInWarehousesChange.ProductsAndServices AS ProductsAndServicesPresentation,
		|	RegisterRecordsInventoryInWarehousesChange.Characteristic AS CharacteristicPresentation,
		|	RegisterRecordsInventoryInWarehousesChange.Batch AS BatchPresentation,
		|	RegisterRecordsInventoryInWarehousesChange.Cell AS PresentationCell,
		|	InventoryInWarehousesOfBalance.StructuralUnit.StructuralUnitType AS StructuralUnitType,
		|	InventoryInWarehousesOfBalance.ProductsAndServices.MeasurementUnit AS MeasurementUnitPresentation,
		|	ISNULL(RegisterRecordsInventoryInWarehousesChange.QuantityChange, 0) + ISNULL(InventoryInWarehousesOfBalance.QuantityBalance, 0) AS BalanceInventoryInWarehouses,
		|	ISNULL(InventoryInWarehousesOfBalance.QuantityBalance, 0) AS QuantityBalanceInventoryInWarehouses
		|FROM
		|	RegisterRecordsInventoryInWarehousesChange AS RegisterRecordsInventoryInWarehousesChange
		|		INNER JOIN AccumulationRegister.InventoryInWarehouses.Balance(&ControlTime, ) AS InventoryInWarehousesOfBalance
		|		ON RegisterRecordsInventoryInWarehousesChange.Company = InventoryInWarehousesOfBalance.Company
		|			AND RegisterRecordsInventoryInWarehousesChange.StructuralUnit = InventoryInWarehousesOfBalance.StructuralUnit
		|			AND RegisterRecordsInventoryInWarehousesChange.ProductsAndServices = InventoryInWarehousesOfBalance.ProductsAndServices
		|			AND RegisterRecordsInventoryInWarehousesChange.Characteristic = InventoryInWarehousesOfBalance.Characteristic
		|			AND RegisterRecordsInventoryInWarehousesChange.Batch = InventoryInWarehousesOfBalance.Batch
		|			AND RegisterRecordsInventoryInWarehousesChange.Cell = InventoryInWarehousesOfBalance.Cell
		|			AND (ISNULL(InventoryInWarehousesOfBalance.QuantityBalance, 0) < 0)
		|
		|ORDER BY
		|	LineNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RegisterRecordsInventoryChange.LineNumber AS LineNumber,
		|	RegisterRecordsInventoryChange.Company AS CompanyPresentation,
		|	RegisterRecordsInventoryChange.StructuralUnit AS StructuralUnitPresentation,
		|	RegisterRecordsInventoryChange.GLAccount AS GLAccountPresentation,
		|	RegisterRecordsInventoryChange.ProductsAndServices AS ProductsAndServicesPresentation,
		|	RegisterRecordsInventoryChange.Characteristic AS CharacteristicPresentation,
		|	RegisterRecordsInventoryChange.Batch AS BatchPresentation,
		|	RegisterRecordsInventoryChange.CustomerOrder AS CustomerOrderPresentation,
		|	InventoryBalances.StructuralUnit.StructuralUnitType AS StructuralUnitType,
		|	InventoryBalances.ProductsAndServices.MeasurementUnit AS MeasurementUnitPresentation,
		|	ISNULL(RegisterRecordsInventoryChange.QuantityChange, 0) + ISNULL(InventoryBalances.QuantityBalance, 0) AS BalanceInventory,
		|	ISNULL(InventoryBalances.QuantityBalance, 0) AS QuantityBalanceInventory,
		|	ISNULL(InventoryBalances.AmountBalance, 0) AS AmountBalanceInventory
		|FROM
		|	RegisterRecordsInventoryChange AS RegisterRecordsInventoryChange
		|		INNER JOIN AccumulationRegister.Inventory.Balance(&ControlTime, ) AS InventoryBalances
		|		ON RegisterRecordsInventoryChange.Company = InventoryBalances.Company
		|			AND RegisterRecordsInventoryChange.StructuralUnit = InventoryBalances.StructuralUnit
		|			AND RegisterRecordsInventoryChange.GLAccount = InventoryBalances.GLAccount
		|			AND RegisterRecordsInventoryChange.ProductsAndServices = InventoryBalances.ProductsAndServices
		|			AND RegisterRecordsInventoryChange.Characteristic = InventoryBalances.Characteristic
		|			AND RegisterRecordsInventoryChange.Batch = InventoryBalances.Batch
		|			AND RegisterRecordsInventoryChange.CustomerOrder = InventoryBalances.CustomerOrder
		|			AND (ISNULL(InventoryBalances.QuantityBalance, 0) < 0)
		|
		|ORDER BY
		|	LineNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RegisterRecordsInventoryTransferredChange.LineNumber AS LineNumber,
		|	RegisterRecordsInventoryTransferredChange.Company AS CompanyPresentation,
		|	RegisterRecordsInventoryTransferredChange.ProductsAndServices AS ProductsAndServicesPresentation,
		|	RegisterRecordsInventoryTransferredChange.Characteristic AS CharacteristicPresentation,
		|	RegisterRecordsInventoryTransferredChange.Batch AS BatchPresentation,
		|	RegisterRecordsInventoryTransferredChange.Counterparty AS CounterpartyPresentation,
		|	RegisterRecordsInventoryTransferredChange.Contract AS ContractPresentation,
		|	RegisterRecordsInventoryTransferredChange.Order AS OrderPresentation,
		|	RegisterRecordsInventoryTransferredChange.ReceptionTransmissionType AS ReceptionTransmissionTypePresentation,
		|	InventoryTransferredBalances.ProductsAndServices.MeasurementUnit AS MeasurementUnitPresentation,
		|	ISNULL(RegisterRecordsInventoryTransferredChange.QuantityChange, 0) + ISNULL(InventoryTransferredBalances.QuantityBalance, 0) AS BalanceInventoryTransferred,
		|	ISNULL(InventoryTransferredBalances.QuantityBalance, 0) AS QuantityBalanceInventoryTransferred,
		|	ISNULL(RegisterRecordsInventoryTransferredChange.SettlementsAmountChange, 0) + ISNULL(InventoryTransferredBalances.SettlementsAmountBalance, 0) AS SettlementsAmountInventoryTransferred,
		|	ISNULL(InventoryTransferredBalances.SettlementsAmountBalance, 0) AS SettlementsAmountBalanceInventoryTransferred
		|FROM
		|	RegisterRecordsInventoryTransferredChange AS RegisterRecordsInventoryTransferredChange
		|		INNER JOIN AccumulationRegister.InventoryTransferred.Balance(&ControlTime, ) AS InventoryTransferredBalances
		|		ON RegisterRecordsInventoryTransferredChange.Company = InventoryTransferredBalances.Company
		|			AND RegisterRecordsInventoryTransferredChange.ProductsAndServices = InventoryTransferredBalances.ProductsAndServices
		|			AND RegisterRecordsInventoryTransferredChange.Characteristic = InventoryTransferredBalances.Characteristic
		|			AND RegisterRecordsInventoryTransferredChange.Batch = InventoryTransferredBalances.Batch
		|			AND RegisterRecordsInventoryTransferredChange.Counterparty = InventoryTransferredBalances.Counterparty
		|			AND RegisterRecordsInventoryTransferredChange.Contract = InventoryTransferredBalances.Contract
		|			AND RegisterRecordsInventoryTransferredChange.Order = InventoryTransferredBalances.Order
		|			AND RegisterRecordsInventoryTransferredChange.ReceptionTransmissionType = InventoryTransferredBalances.ReceptionTransmissionType
		|			AND (ISNULL(InventoryTransferredBalances.QuantityBalance, 0) < 0
		|				OR ISNULL(InventoryTransferredBalances.SettlementsAmountBalance, 0) < 0)
		|
		|ORDER BY
		|	LineNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RegisterRecordsInventoryReceivedChange.LineNumber AS LineNumber,
		|	RegisterRecordsInventoryReceivedChange.Company AS CompanyPresentation,
		|	RegisterRecordsInventoryReceivedChange.ProductsAndServices AS ProductsAndServicesPresentation,
		|	RegisterRecordsInventoryReceivedChange.Characteristic AS CharacteristicPresentation,
		|	RegisterRecordsInventoryReceivedChange.Batch AS BatchPresentation,
		|	RegisterRecordsInventoryReceivedChange.Counterparty AS CounterpartyPresentation,
		|	RegisterRecordsInventoryReceivedChange.Contract AS ContractPresentation,
		|	RegisterRecordsInventoryReceivedChange.Order AS OrderPresentation,
		|	RegisterRecordsInventoryReceivedChange.ReceptionTransmissionType AS ReceptionTransmissionTypePresentation,
		|	InventoryReceivedBalances.ProductsAndServices.MeasurementUnit AS MeasurementUnitPresentation,
		|	ISNULL(RegisterRecordsInventoryReceivedChange.QuantityChange, 0) + ISNULL(InventoryReceivedBalances.QuantityBalance, 0) AS BalanceInventoryReceived,
		|	ISNULL(InventoryReceivedBalances.QuantityBalance, 0) AS QuantityBalanceInventoryReceived,
		|	ISNULL(RegisterRecordsInventoryReceivedChange.SettlementsAmountChange, 0) + ISNULL(InventoryReceivedBalances.SettlementsAmountBalance, 0) AS SettlementsAmountInventoryReceived,
		|	ISNULL(InventoryReceivedBalances.SettlementsAmountBalance, 0) AS SettlementsAmountBalanceInventoryReceived
		|FROM
		|	RegisterRecordsInventoryReceivedChange AS RegisterRecordsInventoryReceivedChange
		|		INNER JOIN AccumulationRegister.InventoryReceived.Balance(&ControlTime, ) AS InventoryReceivedBalances
		|		ON RegisterRecordsInventoryReceivedChange.Company = InventoryReceivedBalances.Company
		|			AND RegisterRecordsInventoryReceivedChange.ProductsAndServices = InventoryReceivedBalances.ProductsAndServices
		|			AND RegisterRecordsInventoryReceivedChange.Characteristic = InventoryReceivedBalances.Characteristic
		|			AND RegisterRecordsInventoryReceivedChange.Batch = InventoryReceivedBalances.Batch
		|			AND RegisterRecordsInventoryReceivedChange.Counterparty = InventoryReceivedBalances.Counterparty
		|			AND RegisterRecordsInventoryReceivedChange.Contract = InventoryReceivedBalances.Contract
		|			AND RegisterRecordsInventoryReceivedChange.Order = InventoryReceivedBalances.Order
		|			AND RegisterRecordsInventoryReceivedChange.ReceptionTransmissionType = InventoryReceivedBalances.ReceptionTransmissionType
		|			AND (ISNULL(InventoryReceivedBalances.QuantityBalance, 0) < 0
		|				OR ISNULL(InventoryReceivedBalances.SettlementsAmountBalance, 0) < 0)
		|
		|ORDER BY
		|	LineNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RegisterRecordsCustomerOrdersChange.LineNumber AS LineNumber,
		|	RegisterRecordsCustomerOrdersChange.Company AS CompanyPresentation,
		|	RegisterRecordsCustomerOrdersChange.CustomerOrder AS OrderPresentation,
		|	RegisterRecordsCustomerOrdersChange.ProductsAndServices AS ProductsAndServicesPresentation,
		|	RegisterRecordsCustomerOrdersChange.Characteristic AS CharacteristicPresentation,
		|	CustomerOrdersBalances.ProductsAndServices.MeasurementUnit AS MeasurementUnitPresentation,
		|	ISNULL(RegisterRecordsCustomerOrdersChange.QuantityChange, 0) + ISNULL(CustomerOrdersBalances.QuantityBalance, 0) AS BalanceCustomerOrders,
		|	ISNULL(CustomerOrdersBalances.QuantityBalance, 0) AS QuantityBalanceCustomerOrders
		|FROM
		|	RegisterRecordsCustomerOrdersChange AS RegisterRecordsCustomerOrdersChange
		|		INNER JOIN AccumulationRegister.CustomerOrders.Balance(&ControlTime, ) AS CustomerOrdersBalances
		|		ON RegisterRecordsCustomerOrdersChange.Company = CustomerOrdersBalances.Company
		|			AND RegisterRecordsCustomerOrdersChange.CustomerOrder = CustomerOrdersBalances.CustomerOrder
		|			AND RegisterRecordsCustomerOrdersChange.ProductsAndServices = CustomerOrdersBalances.ProductsAndServices
		|			AND RegisterRecordsCustomerOrdersChange.Characteristic = CustomerOrdersBalances.Characteristic
		|			AND (ISNULL(CustomerOrdersBalances.QuantityBalance, 0) < 0)
		|
		|ORDER BY
		|	LineNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RegisterRecordsPurchaseOrdersChange.LineNumber AS LineNumber,
		|	RegisterRecordsPurchaseOrdersChange.Company AS CompanyPresentation,
		|	RegisterRecordsPurchaseOrdersChange.PurchaseOrder AS PurchaseOrderPresentation,
		|	RegisterRecordsPurchaseOrdersChange.ProductsAndServices AS ProductsAndServicesPresentation,
		|	RegisterRecordsPurchaseOrdersChange.Characteristic AS CharacteristicPresentation,
		|	PurchaseOrdersBalances.ProductsAndServices.MeasurementUnit AS MeasurementUnitPresentation,
		|	ISNULL(RegisterRecordsPurchaseOrdersChange.QuantityChange, 0) + ISNULL(PurchaseOrdersBalances.QuantityBalance, 0) AS BalancePurchaseOrders,
		|	ISNULL(PurchaseOrdersBalances.QuantityBalance, 0) AS QuantityBalancePurchaseOrders
		|FROM
		|	RegisterRecordsPurchaseOrdersChange AS RegisterRecordsPurchaseOrdersChange
		|		INNER JOIN AccumulationRegister.PurchaseOrders.Balance(&ControlTime, ) AS PurchaseOrdersBalances
		|		ON RegisterRecordsPurchaseOrdersChange.Company = PurchaseOrdersBalances.Company
		|			AND RegisterRecordsPurchaseOrdersChange.PurchaseOrder = PurchaseOrdersBalances.PurchaseOrder
		|			AND RegisterRecordsPurchaseOrdersChange.ProductsAndServices = PurchaseOrdersBalances.ProductsAndServices
		|			AND RegisterRecordsPurchaseOrdersChange.Characteristic = PurchaseOrdersBalances.Characteristic
		|			AND (ISNULL(PurchaseOrdersBalances.QuantityBalance, 0) < 0)
		|
		|ORDER BY
		|	LineNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RegisterRecordsInventoryDemandChange.LineNumber AS LineNumber,
		|	RegisterRecordsInventoryDemandChange.Company AS CompanyPresentation,
		|	RegisterRecordsInventoryDemandChange.MovementType AS MovementTypePresentation,
		|	RegisterRecordsInventoryDemandChange.CustomerOrder AS CustomerOrderPresentation,
		|	RegisterRecordsInventoryDemandChange.ProductsAndServices AS ProductsAndServicesPresentation,
		|	RegisterRecordsInventoryDemandChange.Characteristic AS CharacteristicPresentation,
		|	InventoryDemandBalances.ProductsAndServices.MeasurementUnit AS MeasurementUnitPresentation,
		|	ISNULL(RegisterRecordsInventoryDemandChange.QuantityChange, 0) + ISNULL(InventoryDemandBalances.QuantityBalance, 0) AS BalanceInventoryDemand,
		|	ISNULL(InventoryDemandBalances.QuantityBalance, 0) AS QuantityBalanceInventoryDemand
		|FROM
		|	RegisterRecordsInventoryDemandChange AS RegisterRecordsInventoryDemandChange
		|		INNER JOIN AccumulationRegister.InventoryDemand.Balance(&ControlTime, ) AS InventoryDemandBalances
		|		ON RegisterRecordsInventoryDemandChange.Company = InventoryDemandBalances.Company
		|			AND RegisterRecordsInventoryDemandChange.MovementType = InventoryDemandBalances.MovementType
		|			AND RegisterRecordsInventoryDemandChange.CustomerOrder = InventoryDemandBalances.CustomerOrder
		|			AND RegisterRecordsInventoryDemandChange.ProductsAndServices = InventoryDemandBalances.ProductsAndServices
		|			AND RegisterRecordsInventoryDemandChange.Characteristic = InventoryDemandBalances.Characteristic
		|			AND (ISNULL(InventoryDemandBalances.QuantityBalance, 0) < 0)
		|
		|ORDER BY
		|	LineNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RegisterRecordsOrdersPlacementChange.LineNumber AS LineNumber,
		|	RegisterRecordsOrdersPlacementChange.Company AS CompanyPresentation,
		|	RegisterRecordsOrdersPlacementChange.CustomerOrder AS CustomerOrderPresentation,
		|	RegisterRecordsOrdersPlacementChange.ProductsAndServices AS ProductsAndServicesPresentation,
		|	RegisterRecordsOrdersPlacementChange.Characteristic AS CharacteristicPresentation,
		|	RegisterRecordsOrdersPlacementChange.SupplySource AS SupplySourcePresentation,
		|	OrdersPlacementBalances.ProductsAndServices.MeasurementUnit AS MeasurementUnitPresentation,
		|	ISNULL(RegisterRecordsOrdersPlacementChange.QuantityChange, 0) + ISNULL(OrdersPlacementBalances.QuantityBalance, 0) AS BalanceOrdersPlacement,
		|	ISNULL(OrdersPlacementBalances.QuantityBalance, 0) AS QuantityBalanceOrdersPlacement
		|FROM
		|	RegisterRecordsOrdersPlacementChange AS RegisterRecordsOrdersPlacementChange
		|		INNER JOIN AccumulationRegister.OrdersPlacement.Balance(&ControlTime, ) AS OrdersPlacementBalances
		|		ON RegisterRecordsOrdersPlacementChange.Company = OrdersPlacementBalances.Company
		|			AND RegisterRecordsOrdersPlacementChange.CustomerOrder = OrdersPlacementBalances.CustomerOrder
		|			AND RegisterRecordsOrdersPlacementChange.ProductsAndServices = OrdersPlacementBalances.ProductsAndServices
		|			AND RegisterRecordsOrdersPlacementChange.Characteristic = OrdersPlacementBalances.Characteristic
		|			AND RegisterRecordsOrdersPlacementChange.SupplySource = OrdersPlacementBalances.SupplySource
		|			AND (ISNULL(OrdersPlacementBalances.QuantityBalance, 0) < 0)
		|
		|ORDER BY
		|	LineNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RegisterRecordsSuppliersSettlementsChange.LineNumber AS LineNumber,
		|	RegisterRecordsSuppliersSettlementsChange.Company AS CompanyPresentation,
		|	RegisterRecordsSuppliersSettlementsChange.Counterparty AS CounterpartyPresentation,
		|	RegisterRecordsSuppliersSettlementsChange.Contract AS ContractPresentation,
		|	RegisterRecordsSuppliersSettlementsChange.Contract.SettlementsCurrency AS CurrencyPresentation,
		|	RegisterRecordsSuppliersSettlementsChange.Document AS DocumentPresentation,
		|	RegisterRecordsSuppliersSettlementsChange.Order AS OrderPresentation,
		|	RegisterRecordsSuppliersSettlementsChange.SettlementsType AS CalculationsTypesPresentation,
		|	FALSE AS RegisterRecordsOfCashDocuments,
		|	RegisterRecordsSuppliersSettlementsChange.SumBeforeWrite AS SumBeforeWrite,
		|	RegisterRecordsSuppliersSettlementsChange.AmountOnWrite AS AmountOnWrite,
		|	RegisterRecordsSuppliersSettlementsChange.AmountChange AS AmountChange,
		|	RegisterRecordsSuppliersSettlementsChange.AmountCurBeforeWrite AS AmountCurBeforeWrite,
		|	RegisterRecordsSuppliersSettlementsChange.SumCurOnWrite AS SumCurOnWrite,
		|	RegisterRecordsSuppliersSettlementsChange.SumCurChange AS SumCurChange,
		|	RegisterRecordsSuppliersSettlementsChange.SumCurOnWrite - ISNULL(AccountsPayableBalances.AmountCurBalance, 0) AS AdvanceAmountsPaid,
		|	RegisterRecordsSuppliersSettlementsChange.SumCurChange + ISNULL(AccountsPayableBalances.AmountCurBalance, 0) AS AmountOfOutstandingDebt,
		|	ISNULL(AccountsPayableBalances.AmountBalance, 0) AS AmountBalance,
		|	ISNULL(AccountsPayableBalances.AmountCurBalance, 0) AS AmountCurBalance,
		|	RegisterRecordsSuppliersSettlementsChange.SettlementsType AS SettlementsType
		|FROM
		|	RegisterRecordsSuppliersSettlementsChange AS RegisterRecordsSuppliersSettlementsChange
		|		INNER JOIN AccumulationRegister.AccountsPayable.Balance(&ControlTime, ) AS AccountsPayableBalances
		|		ON RegisterRecordsSuppliersSettlementsChange.Company = AccountsPayableBalances.Company
		|			AND RegisterRecordsSuppliersSettlementsChange.Counterparty = AccountsPayableBalances.Counterparty
		|			AND RegisterRecordsSuppliersSettlementsChange.Contract = AccountsPayableBalances.Contract
		|			AND RegisterRecordsSuppliersSettlementsChange.Document = AccountsPayableBalances.Document
		|			AND RegisterRecordsSuppliersSettlementsChange.Order = AccountsPayableBalances.Order
		|			AND RegisterRecordsSuppliersSettlementsChange.SettlementsType = AccountsPayableBalances.SettlementsType
		|			AND (CASE
		|				WHEN RegisterRecordsSuppliersSettlementsChange.SettlementsType = VALUE(Enum.SettlementsTypes.Advance)
		|					THEN ISNULL(AccountsPayableBalances.AmountCurBalance, 0) > 0
		|				ELSE ISNULL(AccountsPayableBalances.AmountCurBalance, 0) < 0
		|			END)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RegisterRecordsRetailAmountAccountingUpdate.LineNumber AS LineNumber,
		|	RegisterRecordsRetailAmountAccountingUpdate.Company AS CompanyPresentation,
		|	RegisterRecordsRetailAmountAccountingUpdate.StructuralUnit AS StructuralUnitPresentation,
		|	RegisterRecordsRetailAmountAccountingUpdate.StructuralUnit.RetailPriceKind.PriceCurrency AS CurrencyPresentation,
		|	ISNULL(RetailAmountAccountingBalances.AmountBalance, 0) AS AmountBalance,
		|	RegisterRecordsRetailAmountAccountingUpdate.SumCurChange + ISNULL(RetailAmountAccountingBalances.AmountCurBalance, 0) AS BalanceInRetail,
		|	RegisterRecordsRetailAmountAccountingUpdate.SumBeforeWrite AS SumBeforeWrite,
		|	RegisterRecordsRetailAmountAccountingUpdate.AmountOnWrite AS AmountOnWrite,
		|	RegisterRecordsRetailAmountAccountingUpdate.AmountChange AS AmountChange,
		|	RegisterRecordsRetailAmountAccountingUpdate.AmountCurBeforeWrite AS AmountCurBeforeWrite,
		|	RegisterRecordsRetailAmountAccountingUpdate.SumCurOnWrite AS SumCurOnWrite,
		|	RegisterRecordsRetailAmountAccountingUpdate.SumCurChange AS SumCurChange,
		|	RegisterRecordsRetailAmountAccountingUpdate.CostBeforeWrite AS CostBeforeWrite,
		|	RegisterRecordsRetailAmountAccountingUpdate.CostOnWrite AS CostOnWrite,
		|	RegisterRecordsRetailAmountAccountingUpdate.CostUpdate AS CostUpdate
		|FROM
		|	RegisterRecordsRetailAmountAccountingUpdate AS RegisterRecordsRetailAmountAccountingUpdate
		|		INNER JOIN AccumulationRegister.RetailAmountAccounting.Balance(&ControlTime, ) AS RetailAmountAccountingBalances
		|		ON RegisterRecordsRetailAmountAccountingUpdate.Company = RetailAmountAccountingBalances.Company
		|			AND RegisterRecordsRetailAmountAccountingUpdate.StructuralUnit = RetailAmountAccountingBalances.StructuralUnit
		|			AND (ISNULL(RetailAmountAccountingBalances.AmountCurBalance, 0) < 0)
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
			OR Not ResultsArray[2].IsEmpty()
			OR Not ResultsArray[3].IsEmpty()
			OR Not ResultsArray[4].IsEmpty()
			OR Not ResultsArray[5].IsEmpty()
			OR Not ResultsArray[6].IsEmpty()
			OR Not ResultsArray[7].IsEmpty()
			OR Not ResultsArray[8].IsEmpty()
			OR Not ResultsArray[9].IsEmpty()
			OR Not ResultsArray[10].IsEmpty() Then
			DocumentObjectSupplierInvoice = DocumentRefPurchaseInvoice.GetObject()
		EndIf;
		
		// Negative balance of inventory in the warehouse.
		If Not ResultsArray[0].IsEmpty() Then
			QueryResultSelection = ResultsArray[0].Select();
			SmallBusinessServer.ShowMessageAboutPostingToInventoryInWarehousesRegisterErrors(DocumentObjectSupplierInvoice, QueryResultSelection, Cancel);
		EndIf;
		
		// Negative balance of inventory.
		If Not ResultsArray[1].IsEmpty() Then
			QueryResultSelection = ResultsArray[1].Select();
			SmallBusinessServer.ShowMessageAboutPostingToInventoryRegisterErrors(DocumentObjectSupplierInvoice, QueryResultSelection, Cancel);
		EndIf;
		
		// The negative balance of transferred inventory.
		If Not ResultsArray[2].IsEmpty() Then
			QueryResultSelection = ResultsArray[2].Select();
			SmallBusinessServer.ShowMessageAboutPostingToInventoryTransferredRegisterErrors(DocumentObjectSupplierInvoice, QueryResultSelection, Cancel);
		EndIf;
		
		// Negative balance of inventory received.
		If Not ResultsArray[3].IsEmpty() Then
			QueryResultSelection = ResultsArray[3].Select();
			SmallBusinessServer.ShowMessageAboutPostingToInventoryReceivedRegisterErrors(DocumentObjectSupplierInvoice, QueryResultSelection, Cancel);
		EndIf;
		
		// Negative balance on customer order.
		If Not ResultsArray[4].IsEmpty() Then
			QueryResultSelection = ResultsArray[4].Select();
			SmallBusinessServer.ShowMessageAboutPostingToCustomerOrdersRegisterErrors(DocumentObjectSupplierInvoice, QueryResultSelection, Cancel);
		EndIf;
		
		// Negative balance by the purchase order.
		If Not ResultsArray[5].IsEmpty() Then
			QueryResultSelection = ResultsArray[5].Select();
			SmallBusinessServer.ShowMessageAboutPostingToPurchaseOrdersRegisterErrors(DocumentObjectSupplierInvoice, QueryResultSelection, Cancel);
		EndIf;
		
		// Negative balance of needs in inventory.
		If Not ResultsArray[6].IsEmpty() Then
			QueryResultSelection = ResultsArray[6].Select();
			SmallBusinessServer.ShowMessageAboutPostingToInventoryDemandRegisterErrors(DocumentObjectSupplierInvoice, QueryResultSelection, Cancel);
		EndIf;
		
		// Negative balance of inventory placement.
		If Not ResultsArray[7].IsEmpty() Then
			QueryResultSelection = ResultsArray[7].Select();
			SmallBusinessServer.ShowMessageAboutPostingToOrdersPlacementRegisterErrors(DocumentObjectSupplierInvoice, QueryResultSelection, Cancel);
		EndIf;
		
		// Negative balance on accounts payable.
		If Not ResultsArray[8].IsEmpty() Then
			QueryResultSelection = ResultsArray[8].Select();
			SmallBusinessServer.ShowMessageAboutPostingToAccountsPayableRegisterErrors(DocumentObjectSupplierInvoice, QueryResultSelection, Cancel);
		EndIf;
		
		// Negative balance according to the amount-based account in retail.
		If Not ResultsArray[9].IsEmpty() Then
			QueryResultSelection = ResultsArray[9].Select();
			SmallBusinessServer.ShowMessageAboutPostingToRetailAmountAccountingRegisterErrors(DocumentObjectSupplierInvoice, QueryResultSelection, Cancel);
		EndIf;
		
		// Negative balance Inventory By CCD
		If Not ResultsArray[10].IsEmpty() Then
			QueryResultSelection = ResultsArray[10].Select();
			SmallBusinessServer.ShowMessageAboutPostingToInventoryByCCDRegisterErrors(DocumentObjectSupplierInvoice, QueryResultSelection, Cancel);
		EndIf;
		
	EndIf;
	
EndProcedure // RunControl()

// Writes to the Counterparties products and services prices information register.
//
Procedure RecordVendorPrices(DocumentRefPurchaseInvoice) Export

	If DocumentRefPurchaseInvoice.Posted Then
		DeleteVendorPrices(DocumentRefPurchaseInvoice);
	EndIf;
	
	If Not ValueIsFilled(DocumentRefPurchaseInvoice.CounterpartyPriceKind) Then
		Return;
	EndIf; 
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TablePrices.Ref.Date AS Period
	|	,TablePrices.Ref.CounterpartyPriceKind AS CounterpartyPriceKind
	|	,TablePrices.ProductsAndServices AS ProductsAndServices
	|	,TablePrices.Characteristic AS Characteristic
	|	,Max(CASE
	|		WHEN TablePrices.Ref.AmountIncludesVAT = TablePrices.Ref.CounterpartyPriceKind.PriceIncludesVAT
	|			THEN ISNULL(TablePrices.Price * DocumentCurrencyRate.ExchangeRate * RateCurrencyTypePrices.Multiplicity / (RateCurrencyTypePrices.ExchangeRate * DocumentCurrencyRate.Multiplicity), 0)
	|		WHEN TablePrices.Ref.AmountIncludesVAT > TablePrices.Ref.CounterpartyPriceKind.PriceIncludesVAT
	|			THEN ISNULL((TablePrices.Price * DocumentCurrencyRate.ExchangeRate * RateCurrencyTypePrices.Multiplicity / (RateCurrencyTypePrices.ExchangeRate * DocumentCurrencyRate.Multiplicity)) * 100 / (100 + TablePrices.VATRate.Rate), 0)
	|		ELSE ISNULL((TablePrices.Price * DocumentCurrencyRate.ExchangeRate * RateCurrencyTypePrices.Multiplicity / (RateCurrencyTypePrices.ExchangeRate * DocumentCurrencyRate.Multiplicity)) * (100 + TablePrices.VATRate.Rate) / 100, 0)
	|	END) AS Price
	|	,TablePrices.MeasurementUnit AS MeasurementUnit
	|	,TRUE AS Actuality
	|	,TablePrices.Ref AS DocumentRecorder
	|	,TablePrices.Ref.Author AS Author
	|FROM
	|	Document.SupplierInvoice.Inventory AS TablePrices
	|		LEFT JOIN InformationRegister.CounterpartyProductsAndServicesPrices AS CounterpartyProductsAndServicesPrices
	|		ON TablePrices.Ref.CounterpartyPriceKind = CounterpartyProductsAndServicesPrices.CounterpartyPriceKind
	|			AND TablePrices.ProductsAndServices = CounterpartyProductsAndServicesPrices.ProductsAndServices
	|			AND TablePrices.Characteristic = CounterpartyProductsAndServicesPrices.Characteristic
	|			AND (BEGINOFPERIOD(TablePrices.Ref.Date, Day) = CounterpartyProductsAndServicesPrices.Period)
	|			AND TablePrices.Ref.Date <= CounterpartyProductsAndServicesPrices.DocumentRecorder.Date
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(&ProcessingDate, ) AS RateCurrencyTypePrices
	|		ON TablePrices.Ref.CounterpartyPriceKind.PriceCurrency = RateCurrencyTypePrices.Currency,
	|	InformationRegister.CurrencyRates.SliceLast(&ProcessingDate, Currency = &DocumentCurrency) AS DocumentCurrencyRate
	|WHERE
	|	TablePrices.Ref.RegisterVendorPrices
	|	AND CounterpartyProductsAndServicesPrices.CounterpartyPriceKind IS NULL 
	|	AND TablePrices.Ref = &Ref
	|	AND TablePrices.Price <> 0
	|	
	|GROUP BY
	|	TablePrices.ProductsAndServices
	|	,TablePrices.Characteristic
	|	,TablePrices.MeasurementUnit
	|	,TablePrices.Ref.Date
	|	,TablePrices.Ref.CounterpartyPriceKind
	|	,TablePrices.Ref
	|	,TablePrices.Ref.Author";
	
	Query.SetParameter("Ref", DocumentRefPurchaseInvoice);
	Query.SetParameter("DocumentCurrency", DocumentRefPurchaseInvoice.DocumentCurrency);
	Query.SetParameter("ProcessingDate", DocumentRefPurchaseInvoice.Date);
	
	QueryResult = Query.Execute();
	RecordsTable = QueryResult.Unload();
	
	// IR set record
	RecordSet = InformationRegisters.CounterpartyProductsAndServicesPrices.CreateRecordSet();
	RecordSet.Filter.Period.Set(DocumentRefPurchaseInvoice.Date);
	RecordSet.Filter.CounterpartyPriceKind.Set(DocumentRefPurchaseInvoice.CounterpartyPriceKind);
	For Each TableRow IN RecordsTable Do
		NewRecord = RecordSet.Add();
		FillPropertyValues(NewRecord, TableRow);
	EndDo; 
	RecordSet.Write();
	
EndProcedure // RegisterVendorPrices()

// Deletes records from the Counterparties products and services prices information register.
//
Procedure DeleteVendorPrices(DocumentRefPurchaseInvoice) Export

	Query = New Query;
	Query.Text =
	"SELECT
	|	CounterpartyProductsAndServicesPrices.Period,
	|	CounterpartyProductsAndServicesPrices.CounterpartyPriceKind,
	|	CounterpartyProductsAndServicesPrices.ProductsAndServices,
	|	CounterpartyProductsAndServicesPrices.Characteristic
	|FROM
	|	InformationRegister.CounterpartyProductsAndServicesPrices AS CounterpartyProductsAndServicesPrices
	|WHERE
	|	CounterpartyProductsAndServicesPrices.DocumentRecorder = &DocumentRecorder";
	
	Query.SetParameter("DocumentRecorder", DocumentRefPurchaseInvoice);
	
	QueryResult = Query.Execute();
	RecordsTable = QueryResult.Unload();	
	
	For Each TableRow IN RecordsTable Do
		RecordSet = InformationRegisters.CounterpartyProductsAndServicesPrices.CreateRecordSet();
		RecordSet.Filter.Period.Set(TableRow.Period);
		RecordSet.Filter.CounterpartyPriceKind.Set(TableRow.CounterpartyPriceKind);
		RecordSet.Filter.ProductsAndServices.Set(TableRow.ProductsAndServices);
		RecordSet.Filter.Characteristic.Set(TableRow.Characteristic);
		RecordSet.Write();
	EndDo;	

EndProcedure // DeleteVendorPrices()

#Region DataImportFromExternalSources

Procedure DataImportFieldsFromExternalSource(ImportFieldsTable, FillingObjectFullName) Export
	
	//
	// The group of fields complies with rule: at least one field in the group must be selected in columns
	//
	
	TypeDescriptionString25 = New TypeDescription("String", , , , New StringQualifiers(25));
	TypeDescriptionString50 = New TypeDescription("String", , , , New StringQualifiers(50));
	TypeDescriptionString100 = New TypeDescription("String", , , , New StringQualifiers(100));
	TypeDescriptionString150 = New TypeDescription("String", , , , New StringQualifiers(150));
	TypeDescriptionString200 = New TypeDescription("String", , , , New StringQualifiers(200));
	TypeDescriptionNumber15_2 = New TypeDescription("Number", , , , New NumberQualifiers(15, 2, AllowedSign.Nonnegative));
	TypeDescriptionNumber15_3 = New TypeDescription("Number", , , , New NumberQualifiers(15, 3, AllowedSign.Nonnegative));
	
	IsInventory = (FillingObjectFullName = "Document.SupplierInvoice.TabularSection.Inventory");
	
	TypeDescriptionColumn = New TypeDescription("CatalogRef.ProductsAndServices");
	DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Barcode", "Barcode", TypeDescriptionString200, TypeDescriptionColumn, "ProductsAndServices", 1, , True, IsInventory);
	DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "SKU", "SKU", TypeDescriptionString25, TypeDescriptionColumn, "ProductsAndServices", 2, , True);
	DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "ProductsAndServicesDescription", "Products and services (name)", TypeDescriptionString100, TypeDescriptionColumn, "ProductsAndServices", 3, , True);
	
	If GetFunctionalOption("UseCharacteristics") Then
		
		TypeDescriptionColumn = New TypeDescription("CatalogRef.ProductsAndServicesCharacteristics");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Characteristic", "Characteristic (name)", TypeDescriptionString150, TypeDescriptionColumn);
		
	EndIf;
	
	If GetFunctionalOption("UseBatches") Then
		
		TypeDescriptionColumn = New TypeDescription("CatalogRef.ProductsAndServicesBatches");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Batch", "Batch (name)", TypeDescriptionString150, TypeDescriptionColumn);
		
	EndIf;
	
	DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Quantity", "Quantity", TypeDescriptionString25, TypeDescriptionNumber15_3, , , True);
	
	TypeDescriptionColumn = New TypeDescription("CatalogRef.UOMClassifier");
	DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "MeasurementUnit", "Unit of Measure", TypeDescriptionString25, TypeDescriptionColumn, , , , , GetFunctionalOption("AccountingInVariousUOM"));
	
	DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Price", "Price", TypeDescriptionString25, TypeDescriptionNumber15_2, , , True);
	
	TypeDescriptionColumn = New TypeDescription("CatalogRef.VATRates");
	DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "VATRate", "VAT rate", TypeDescriptionString50, TypeDescriptionColumn);
	
	DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "VATAmount", "VAT amount", TypeDescriptionString25, TypeDescriptionNumber15_2);
	
	TypeArray = New Array;
	TypeArray.Add(Type("DocumentRef.CustomerOrder"));
	TypeArray.Add(Type("DocumentRef.PurchaseOrder"));
	
	TypeDescriptionColumn = New TypeDescription(TypeArray);
	DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Order", "Order (customer/vendor)", TypeDescriptionString50, TypeDescriptionColumn);
	
EndProcedure

Procedure OnDefineDataImportSamples(DataLoadSettings, UUID) Export
	
	Sample_xlsx = GetTemplate("DataImportTemplate_xlsx");
	DataImportTemplate_xlsx = PutToTempStorage(Sample_xlsx, UUID);
	DataLoadSettings.Insert("DataImportTemplate_xlsx", DataImportTemplate_xlsx);
	
	DataLoadSettings.Insert("DataImportTemplate_mxl", "DataImportTemplate_mxl");
	
	Sample_csv = GetTemplate("DataImportTemplate_csv");
	DataImportTemplate_csv = PutToTempStorage(Sample_csv, UUID);
	DataLoadSettings.Insert("DataImportTemplate_csv", DataImportTemplate_csv);
	
EndProcedure

Procedure MatchImportedDataFromExternalSource(DataMatchingTable, AdditionalParameters) Export
	
	FillingObjectFullName = AdditionalParameters.DataLoadSettings.FillingObjectFullName;
	
	// DataMatchingTable - Type FormDataCollection
	For Each FormTableRow IN DataMatchingTable Do
		
		// Products and services by Barcode, SKU, Description
		DataImportFromExternalSourcesOverridable.CompareProductsAndServices(FormTableRow.ProductsAndServices, FormTableRow.Barcode, FormTableRow.SKU, FormTableRow.ProductsAndServicesDescription);
		If FillingObjectFullName = "Document.SupplierInvoice.TabularSection.Expenses" Then
			
			If FormTableRow.ProductsAndServices.ProductsAndServicesType <> Enums.ProductsAndServicesTypes.Service Then
				
				FormTableRow.ProductsAndServices = Undefined;
				
			EndIf;
			
		EndIf;
		
		If FillingObjectFullName = "Document.SupplierInvoice.TabularSection.Inventory" Then
			
			If FormTableRow.ProductsAndServices.ProductsAndServicesType <> Enums.ProductsAndServicesTypes.InventoryItem Then
				
				FormTableRow.ProductsAndServices = Undefined;
				
			EndIf;
			
			If GetFunctionalOption("UseCharacteristics") Then
				
				If ValueIsFilled(FormTableRow.ProductsAndServices) Then
					
					// Characteristic by Owner and Name
					DataImportFromExternalSourcesOverridable.MapCharacteristic(FormTableRow.Characteristic, FormTableRow.ProductsAndServices, FormTableRow.Barcode, FormTableRow.Characteristic_IncomingData);
					
				EndIf;
				
			EndIf;
			
			If GetFunctionalOption("UseBatches") Then
				
				If ValueIsFilled(FormTableRow.ProductsAndServices) Then
					
					// Batch by Owner and Name
					DataImportFromExternalSourcesOverridable.MapBatch(FormTableRow.Batch, FormTableRow.ProductsAndServices, FormTableRow.Barcode, FormTableRow.Batch_IncomingData);
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
		// Quantity
		DataImportFromExternalSourcesOverridable.ConvertRowToNumber(FormTableRow.Quantity, FormTableRow.Quantity_IncomingData, 1);
		
		// MeasurementUnits by Description (also consider the option to bind user MU)
		DefaultValue = ?(ValueIsFilled(FormTableRow.ProductsAndServices), FormTableRow.ProductsAndServices.MeasurementUnit, Catalogs.UOMClassifier.pcs);
		DataImportFromExternalSourcesOverridable.MapUOM(FormTableRow.ProductsAndServices, FormTableRow.MeasurementUnit, FormTableRow.MeasurementUnit_IncomingData, DefaultValue);
		
		// Price
		DataImportFromExternalSourcesOverridable.ConvertRowToNumber(FormTableRow.Price, FormTableRow.Price_IncomingData, 1);
		
		// VATRate
		//by name DefaultValue = ?(ValueFilled(FormTableString.ProductsAnsServices), FormTableString.ProductsAnsServices.VATRate, Catalogs.Companies.MainCompany.DefaultVATRate);
		DataImportFromExternalSourcesOverridable.MapVATRate(FormTableRow.VATRate, FormTableRow.VATRate_IncomingData, Undefined);
		
		// VATAmount
		DataImportFromExternalSourcesOverridable.ConvertRowToNumber(FormTableRow.VATAmount, FormTableRow.VATAmount_IncomingData, 0);
		
		// Order by number, date, flag
		DataImportFromExternalSourcesOverridable.MatchOrder(FormTableRow.Order, FormTableRow.Order_IncomingData);
		
		CheckDataCorrectnessInTableRow(FormTableRow, FillingObjectFullName);
		
	EndDo;
	
EndProcedure

Procedure CheckDataCorrectnessInTableRow(FormTableRow, FillingObjectFullName = "") Export
	
	ServiceFieldName = DataImportFromExternalSources.ServiceFieldNameImportToApplicationPossible();
	
	If FillingObjectFullName = "Document.SupplierInvoice.TabularSection.Inventory" Then
		
		FormTableRow[ServiceFieldName] = ValueIsFilled(FormTableRow.ProductsAndServices)
			AND FormTableRow.ProductsAndServices.ProductsAndServicesType = Enums.ProductsAndServicesTypes.InventoryItem
			AND FormTableRow.Quantity <> 0;
			
	ElsIf FillingObjectFullName = "Document.SupplierInvoice.TabularSection.Expenses" Then
			
		FormTableRow[ServiceFieldName] = ValueIsFilled(FormTableRow.ProductsAndServices)
			AND FormTableRow.ProductsAndServices.ProductsAndServicesType = Enums.ProductsAndServicesTypes.Service
			AND FormTableRow.Quantity <> 0;
			
	EndIf;
	
EndProcedure

#EndRegion

#Region PrintInterface

Procedure GenerateSupplierInvoiceWithExpenses(Query, SpreadsheetDocument)
	
	Query.Text = 
	"SELECT
	|	SupplierInvoice.Date AS DocumentDate,
	|	SupplierInvoice.Counterparty AS Company,
	|	SupplierInvoice.Company AS Counterparty,
	|	SupplierInvoice.AmountIncludesVAT AS AmountIncludesVAT,
	|	SupplierInvoice.Number,
	|	SupplierInvoice.Company.Prefix AS Prefix,
	|	SupplierInvoice.DocumentCurrency AS DocumentCurrency,
	|	CASE
	|		WHEN SupplierInvoice.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceiptFromVendor)
	|			THEN ""(Receipt from vendor)""
	|		WHEN SupplierInvoice.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionForCommission)
	|			THEN ""(Receipt for commission)""
	|		WHEN SupplierInvoice.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionIntoProcessing)
	|			THEN ""(Receipt to processing)""
	|		WHEN SupplierInvoice.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionForSafeCustody)
	|			THEN ""(Receive from counterparty to the responsible storage)""
	|		WHEN SupplierInvoice.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromCustomer)
	|			THEN ""(Return from customer)""
	|		WHEN SupplierInvoice.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromAgent)
	|			THEN ""(Return from commission agent)""
	|		WHEN SupplierInvoice.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromSubcontractor)
	|			THEN ""(Return from processor)""
	|		WHEN SupplierInvoice.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromSafeCustody)
	|			THEN ""(Return counterparty from the responsible storage)""
	|	END AS OperationKind,
	|	SupplierInvoice.Inventory.(
	|		LineNumber AS LineNumber,
	|		CASE
	|			WHEN (CAST(SupplierInvoice.Inventory.ProductsAndServices.DescriptionFull AS String(1000))) = """"
	|				THEN SupplierInvoice.Inventory.ProductsAndServices.Description
	|			ELSE CAST(SupplierInvoice.Inventory.ProductsAndServices.DescriptionFull AS String(1000))
	|		END AS InventoryItem,
	|		ProductsAndServices.SKU AS SKU,
	|		ProductsAndServices.Code AS Code,
	|		MeasurementUnit AS StorageUnit,
	|		Quantity AS Quantity,
	|		Price AS Price,
	|		Amount AS Amount,
	|		VATAmount,
	|		Total,
	|		Characteristic,
	|		Content,
	|		ConnectionKey
	|	),
	|	SupplierInvoice.Expenses.(
	|		Ref,
	|		LineNumber,
	|		CASE
	|			WHEN (CAST(SupplierInvoice.Expenses.ProductsAndServices.DescriptionFull AS String(1000))) = """"
	|				THEN SupplierInvoice.Expenses.ProductsAndServices.Description
	|			ELSE CAST(SupplierInvoice.Expenses.ProductsAndServices.DescriptionFull AS String(1000))
	|		END AS Expense,
	|		ProductsAndServices,
	|		ProductsAndServices.Code AS Code,
	|		ProductsAndServices.SKU AS SKU,
	|		MeasurementUnit AS StorageUnit,
	|		Quantity,
	|		Price,
	|		Amount,
	|		VATRate,
	|		VATAmount,
	|		Total,
	|		PurchaseOrder,
	|		Total AS Total1,
	|		Order,
	|		StructuralUnit,
	|		BusinessActivity,
	|		Content
	|	),
	|	SupplierInvoice.SerialNumbers.(
	|		SerialNumber,
	|		ConnectionKey
	|	)
	|FROM
	|	Document.SupplierInvoice AS SupplierInvoice
	|WHERE
	|	SupplierInvoice.Ref = &CurrentDocument
	|
	|ORDER BY
	|	LineNumber";
	
	Header = Query.Execute().Select();
	Header.Next();
	
	LinesSelectionInventory = Header.Inventory.Select();
	RowSelectionExpenses = Header.Expenses.Select();
	LinesSelectionSerialNumbers = Header.SerialNumbers.Select();

	SpreadsheetDocument.PrintParametersName = "PRINT_PARAMETERS_SupplierInvoice_Bill";
	
	Template = PrintManagement.GetTemplate("Document.SupplierInvoice.PF_MXL_Bill");
	InfoAboutCompany = SmallBusinessServer.InfoAboutLegalEntityIndividual(Header.Company, Header.DocumentDate, ,);
	InfoAboutCounterparty = SmallBusinessServer.InfoAboutLegalEntityIndividual(Header.Counterparty, Header.DocumentDate, ,);
	
	If Header.DocumentDate < Date('20110101') Then
		DocumentNumber = SmallBusinessServer.GetNumberForPrinting(Header.Number, Header.Prefix);
	Else
		DocumentNumber = ObjectPrefixationClientServer.GetNumberForPrinting(Header.Number, True, True);
	EndIf;
	
	TemplateArea = Template.GetArea("Title");
	TemplateArea.Parameters.HeaderText = NStr("en='Supplier invoice No ';vi='Hóa đơn nhận hàng số '")
		+ DocumentNumber
		+ NStr("en=' from ';vi='ngày'")
		+ Format(Header.DocumentDate, "DLF=DD");
		
	TemplateArea.Parameters.OperationKind = Header.OperationKind;
	SpreadsheetDocument.Put(TemplateArea);
	
	TemplateArea = Template.GetArea("Vendor");
	TemplateArea.Parameters.VendorPresentation = SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCompany, "FullDescr,TIN,LegalAddress,PhoneNumbers,");
	SpreadsheetDocument.Put(TemplateArea);
	
	TemplateArea = Template.GetArea("Customer");
	TemplateArea.Parameters.RecipientPresentation = SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCounterparty, "FullDescr,TIN,LegalAddress,PhoneNumbers,");
	SpreadsheetDocument.Put(TemplateArea);
	
	TemplateArea = Template.GetArea("TableHeader");
	SpreadsheetDocument.Put(TemplateArea);
	
	TemplateArea = Template.GetArea("String");
	
	Amount		= 0;
	VATAmount	= 0;
	Total		= 0;
	Quantity	= 0;
	LineNumber	= 0;
	
	// Inventory
	While LinesSelectionInventory.Next() Do
		
		TemplateArea.Parameters.Fill(LinesSelectionInventory);
		
		If ValueIsFilled(LinesSelectionInventory.Content) Then
			TemplateArea.Parameters.InventoryItem = LinesSelectionInventory.Content;
		Else
			StringSerialNumbers = WorkWithSerialNumbers.SerialNumbersStringFromSelection(LinesSelectionSerialNumbers, LinesSelectionInventory.ConnectionKey);
			TemplateArea.Parameters.InventoryItem = SmallBusinessServer.GetProductsAndServicesPresentationForPrinting(
				LinesSelectionInventory.InventoryItem,
				LinesSelectionInventory.Characteristic, LinesSelectionInventory.SKU, StringSerialNumbers
			);
		EndIf;
		
		LineNumber = LineNumber + 1;
		
		TemplateArea.Parameters.LineNumber = LineNumber;
		
		SpreadsheetDocument.Put(TemplateArea);
		
		Amount		= Amount		+ LinesSelectionInventory.Amount;
		VATAmount	= VATAmount	+ LinesSelectionInventory.VATAmount;
		Total		= Total		+ LinesSelectionInventory.Total;
		Quantity	= Quantity+ 1;
		
	EndDo;
	
	TemplateArea = Template.GetArea("RowExpenses");
	
	// Expenses
	While RowSelectionExpenses.Next() Do
		
		TemplateArea.Parameters.Fill(RowSelectionExpenses);
		
		If ValueIsFilled(RowSelectionExpenses.Content) Then
			TemplateArea.Parameters.Expense = RowSelectionExpenses.Content;
		Else
			TemplateArea.Parameters.Expense = SmallBusinessServer.GetProductsAndServicesPresentationForPrinting(
				RowSelectionExpenses.Expense, , RowSelectionExpenses.SKU
			);
		EndIf;
		
		LineNumber = LineNumber + 1;
		
		TemplateArea.Parameters.LineNumber = LineNumber;
		
		SpreadsheetDocument.Put(TemplateArea);
		
		Amount		= Amount		+ RowSelectionExpenses.Amount;
		VATAmount	= VATAmount	+ RowSelectionExpenses.VATAmount;
		Total		= Total		+ RowSelectionExpenses.Total;
		Quantity	= Quantity+ 1;
		
	EndDo;
	
	TemplateArea = Template.GetArea("Total");
	TemplateArea.Parameters.Total = SmallBusinessServer.AmountsFormat(Amount);
	SpreadsheetDocument.Put(TemplateArea);
	
	TemplateArea = Template.GetArea("TotalVAT");
	If VATAmount = 0 Then
		
		TemplateArea.Parameters.VAT = NStr("en='Without tax (VAT)';vi='Không bao gồm thuế GTGT'");
		TemplateArea.Parameters.TotalVAT = "-";
		
	Else
		
		TemplateArea.Parameters.VAT = ?(Header.AmountIncludesVAT, NStr("en='Including VAT:';vi='Gồm thuế GTGT:';"), NStr("en='VAT Amount:';vi='Thuế GTGT:';"));
		TemplateArea.Parameters.TotalVAT = SmallBusinessServer.AmountsFormat(VATAmount);
		
	EndIf; 
	
	SpreadsheetDocument.Put(TemplateArea);
	
	TemplateArea = Template.GetArea("AmountInWords");
	AmountToBeWrittenInWords = Total;
	TemplateArea.Parameters.TotalRow = NStr("en='Total titles ';vi='Tổng số ';")
										+ String(Quantity)
										+ NStr("en=', in the amount of ';vi=', với tổng số tiền ';")
										+ SmallBusinessServer.AmountsFormat(AmountToBeWrittenInWords, Header.DocumentCurrency);
	
	TemplateArea.Parameters.AmountInWords = WorkWithCurrencyRates.GenerateAmountInWords(AmountToBeWrittenInWords, Header.DocumentCurrency);
	
	SpreadsheetDocument.Put(TemplateArea);
	
	TemplateArea = Template.GetArea("Signatures");
	SpreadsheetDocument.Put(TemplateArea);
	
EndProcedure

// Function generates document printing form by specified layout.
//
// Parameters:
// SpreadsheetDocument - TabularDocument in which
// 			   printing form will be displayed.
//  TemplateName    - String, printing form layout name.
//
Function PrintForm(ObjectsArray, PrintObjects, TemplateName)
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersKey = "PrintParameters_SupplierInvoice";
	
	FirstDocument = True;
	
	For Each CurrentDocument IN ObjectsArray Do
	
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		FirstDocument = False;
		
		FirstLineNumber = SpreadsheetDocument.TableHeight + 1;
		
		Query = New Query();
		Query.SetParameter("CurrentDocument", CurrentDocument);
		
		If TemplateName = "Consignment" Then
		
			Query.Text = 
			"SELECT
			|	SupplierInvoice.Date AS DocumentDate,
			|	SupplierInvoice.Counterparty AS Company,
			|	SupplierInvoice.Company AS Counterparty,
			|	SupplierInvoice.AmountIncludesVAT AS AmountIncludesVAT,
			|	SupplierInvoice.Number,
			|	SupplierInvoice.Company.Prefix AS Prefix,
			|	SupplierInvoice.DocumentCurrency AS DocumentCurrency,
			|	CASE
			|		WHEN SupplierInvoice.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceiptFromVendor)
			|			THEN ""(Receipt from vendor)""
			|		WHEN SupplierInvoice.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionForCommission)
			|			THEN ""(Receipt for commission)""
			|		WHEN SupplierInvoice.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionIntoProcessing)
			|			THEN ""(Receipt to processing)""
			|		WHEN SupplierInvoice.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionForSafeCustody)
			|			THEN ""(Receive from counterparty to the responsible storage)""
			|		WHEN SupplierInvoice.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromCustomer)
			|			THEN ""(Return from customer)""
			|		WHEN SupplierInvoice.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromAgent)
			|			THEN ""(Return from commission agent)""
			|		WHEN SupplierInvoice.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromSubcontractor)
			|			THEN ""(Return from processor)""
			|		WHEN SupplierInvoice.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromSafeCustody)
			|			THEN ""(Return counterparty from the responsible storage)""
			|	END AS OperationKind,
			|	SupplierInvoice.Inventory.(
			|		LineNumber AS LineNumber,
			|		CASE
			|			WHEN (CAST(SupplierInvoice.Inventory.ProductsAndServices.DescriptionFull AS String(1000))) = """"
			|				THEN SupplierInvoice.Inventory.ProductsAndServices.Description
			|			ELSE CAST(SupplierInvoice.Inventory.ProductsAndServices.DescriptionFull AS String(1000))
			|		END AS InventoryItem,
			|		ProductsAndServices.SKU AS SKU,
			|		ProductsAndServices.Code AS Code,
			|		MeasurementUnit AS StorageUnit,
			|		Quantity AS Quantity,
			|		Price AS Price,
			|		Amount AS Amount,
			|		VATAmount,
			|		Total,
			|		Characteristic,
			|		Content,
			|		ConnectionKey
			|	),
			|	SupplierInvoice.SerialNumbers.(
			|		SerialNumber,
			|		ConnectionKey
			|	)			
			|FROM
			|	Document.SupplierInvoice AS SupplierInvoice
			|WHERE
			|	SupplierInvoice.Ref = &CurrentDocument
			|
			|ORDER BY
			|	LineNumber";
			
			Header = Query.Execute().Select();
			Header.Next();
			
			LinesSelectionInventory = Header.Inventory.Select();
			LinesSelectionSerialNumbers = Header.SerialNumbers.Select();
			
			SpreadsheetDocument.PrintParametersName = "PRINT_PARAMETERS_SupplierInvoice_Bill";
			
			Template = PrintManagement.GetTemplate("Document.SupplierInvoice.PF_MXL_Bill");
			InfoAboutCompany = SmallBusinessServer.InfoAboutLegalEntityIndividual(Header.Company, Header.DocumentDate, ,);
			InfoAboutCounterparty = SmallBusinessServer.InfoAboutLegalEntityIndividual(Header.Counterparty, Header.DocumentDate, ,);
			
			If Header.DocumentDate < Date('20110101') Then
				DocumentNumber = SmallBusinessServer.GetNumberForPrinting(Header.Number, Header.Prefix);
			Else
				DocumentNumber = ObjectPrefixationClientServer.GetNumberForPrinting(Header.Number, True, True);
			EndIf;
			
			TemplateArea = Template.GetArea("Title");
			TemplateArea.Parameters.HeaderText = NStr("en='Supplier invoice No ';vi='Hóa đơn nhận hàng số '")
				+ DocumentNumber
				+ NStr("en=' from ';vi='ngày'")
				+ Format(Header.DocumentDate, "DLF=DD");
				
			TemplateArea.Parameters.OperationKind = Header.OperationKind;
			SpreadsheetDocument.Put(TemplateArea);
			
			TemplateArea = Template.GetArea("Vendor");
			TemplateArea.Parameters.VendorPresentation = SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCompany, "FullDescr,TIN,LegalAddress,PhoneNumbers,");
			SpreadsheetDocument.Put(TemplateArea);
			
			TemplateArea = Template.GetArea("Customer");
			TemplateArea.Parameters.RecipientPresentation = SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCounterparty, "FullDescr,TIN,LegalAddress,PhoneNumbers,");
			SpreadsheetDocument.Put(TemplateArea);
			
			TemplateArea = Template.GetArea("TableHeader");
			SpreadsheetDocument.Put(TemplateArea);
			
			TemplateArea = Template.GetArea("String");
			
			Amount		= 0;
			VATAmount	= 0;
			Total		= 0;
			Quantity	= 0;
			
			While LinesSelectionInventory.Next() Do
				
				TemplateArea.Parameters.Fill(LinesSelectionInventory);
				
				If ValueIsFilled(LinesSelectionInventory.Content) Then
					TemplateArea.Parameters.InventoryItem = LinesSelectionInventory.Content;
				Else
					StringSerialNumbers = WorkWithSerialNumbers.SerialNumbersStringFromSelection(LinesSelectionSerialNumbers, LinesSelectionInventory.ConnectionKey);
					TemplateArea.Parameters.InventoryItem = SmallBusinessServer.GetProductsAndServicesPresentationForPrinting(
						LinesSelectionInventory.InventoryItem,
						LinesSelectionInventory.Characteristic, LinesSelectionInventory.SKU, StringSerialNumbers
					);
				EndIf;
				
				SpreadsheetDocument.Put(TemplateArea);
				
				Amount		= Amount		+ LinesSelectionInventory.Amount;
				VATAmount	= VATAmount	+ LinesSelectionInventory.VATAmount;
				Total		= Total		+ LinesSelectionInventory.Total;
				Quantity	= Quantity+ 1;
				
			EndDo;
			
			TemplateArea = Template.GetArea("Total");
			TemplateArea.Parameters.Total = SmallBusinessServer.AmountsFormat(Amount);
			SpreadsheetDocument.Put(TemplateArea);
			
			TemplateArea = Template.GetArea("TotalVAT");
			If VATAmount = 0 Then
				
				TemplateArea.Parameters.VAT = NStr("en='Without tax (VAT)';vi='Không bao gồm thuế GTGT'");
				TemplateArea.Parameters.TotalVAT = "-";
				
			Else
				
				TemplateArea.Parameters.VAT = ?(Header.AmountIncludesVAT, NStr("en='Including VAT:';vi='Gồm thuế GTGT:';"), NStr("en='VAT Amount:';vi='Thuế GTGT:';"));
				TemplateArea.Parameters.TotalVAT = SmallBusinessServer.AmountsFormat(VATAmount);
				
			EndIf; 
			
			SpreadsheetDocument.Put(TemplateArea);
			
			TemplateArea = Template.GetArea("AmountInWords");
			AmountToBeWrittenInWords = Total;
			TemplateArea.Parameters.TotalRow = NStr("en='Total titles ';vi='Tổng số '")
									+ String(Quantity)
									+ NStr("en=', in the amount of ';vi=', với tổng số tiền '")
									+ SmallBusinessServer.AmountsFormat(AmountToBeWrittenInWords, Header.DocumentCurrency);
			
			TemplateArea.Parameters.AmountInWords = WorkWithCurrencyRates.GenerateAmountInWords(AmountToBeWrittenInWords, Header.DocumentCurrency);
			
			SpreadsheetDocument.Put(TemplateArea);
			
			TemplateArea = Template.GetArea("Signatures");
			SpreadsheetDocument.Put(TemplateArea);
			
		ElsIf TemplateName = "InvoiceWithCost" Then
			
			GenerateSupplierInvoiceWithExpenses(Query, SpreadsheetDocument);
			
		ElsIf  TemplateName = "InvoiceInRetailPrices" Then
			
			Query.Text =
			"SELECT
			|	DocumentHeader.Date AS DocumentDate,
			|	DocumentHeader.Counterparty AS Company,
			|	DocumentHeader.Company AS Counterparty,
			|	DocumentHeader.AmountIncludesVAT AS AmountIncludesVAT,
			|	DocumentHeader.DocumentCurrency AS DocumentCurrency,
			|	CASE
			|		WHEN DocumentHeader.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceiptFromVendor)
			|			THEN ""(Receipt from vendor)""
			|		WHEN DocumentHeader.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionForCommission)
			|			THEN ""(Receipt for commission)""
			|		WHEN DocumentHeader.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionIntoProcessing)
			|			THEN ""(Receipt to processing)""
			|		WHEN DocumentHeader.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReceptionForSafeCustody)
			|			THEN ""(Receive from counterparty to the responsible storage)""
			|		WHEN DocumentHeader.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromCustomer)
			|			THEN ""(Return from customer)""
			|		WHEN DocumentHeader.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromAgent)
			|			THEN ""(Return from commission agent)""
			|		WHEN DocumentHeader.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromSubcontractor)
			|			THEN ""(Return from processor)""
			|		WHEN DocumentHeader.OperationKind = VALUE(Enum.OperationKindsSupplierInvoice.ReturnFromSafeCustody)
			|			THEN ""(Return counterparty from the responsible storage)""
			|	END AS OperationKind,
			|	DocumentHeader.StructuralUnit.StructuralUnitType AS StructuralUnitOfTypeUnit,
			|	DocumentHeader.Number AS Number,
			|	DocumentHeader.Company.Prefix AS Prefix
			|FROM
			|	Document.SupplierInvoice AS DocumentHeader
			|WHERE
			|	DocumentHeader.Ref = &CurrentDocument
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	SupplierInvoice.LineNumber AS LineNumber,
			|	CASE
			|		WHEN (CAST(SupplierInvoice.ProductsAndServices.DescriptionFull AS String(1000))) = """"
			|			THEN SupplierInvoice.ProductsAndServices.Description
			|		ELSE CAST(SupplierInvoice.ProductsAndServices.DescriptionFull AS String(1000))
			|	END AS InventoryItem,
			|	SupplierInvoice.ProductsAndServices.SKU AS SKU,
			|	SupplierInvoice.ProductsAndServices.Code AS Code,
			|	SupplierInvoice.MeasurementUnit AS StorageUnit,
			|	SupplierInvoice.Quantity AS Quantity,
			|	ISNULL(ProductsAndServicesPricesSliceLast.Price, 0) AS Price,
			|	ISNULL(ProductsAndServicesPricesSliceLast.Price * SupplierInvoice.Quantity, 0) AS Amount,
			|	ISNULL(ProductsAndServicesPricesSliceLast.Price * SupplierInvoice.Quantity * SupplierInvoice.VATRate.Rate / 100, 0) AS VATAmount,
			|	SupplierInvoice.Characteristic AS Characteristic,
			|	SupplierInvoice.Content AS Content,
			|	SupplierInvoice.ConnectionKey AS ConnectionKey
			|FROM
			|	Document.SupplierInvoice.Inventory AS SupplierInvoice
			|		LEFT JOIN InformationRegister.ProductsAndServicesPrices.SliceLast(
			|				&DocumentDate,
			|				ProductsAndServices IN (&ListProductsAndServices)
			|					AND Characteristic IN (&ListCharacteristic)
			|					AND PriceKind = &PriceKind) AS ProductsAndServicesPricesSliceLast
			|		ON SupplierInvoice.ProductsAndServices = ProductsAndServicesPricesSliceLast.ProductsAndServices
			|			AND SupplierInvoice.Characteristic = ProductsAndServicesPricesSliceLast.Characteristic
			|			AND SupplierInvoice.Ref.StructuralUnit.RetailPriceKind = ProductsAndServicesPricesSliceLast.PriceKind
			|WHERE
			|	SupplierInvoice.Ref = &CurrentDocument
			|
			|ORDER BY
			|	LineNumber
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	CustomerInvoiceSerialNumbers.SerialNumber,
			|	CustomerInvoiceSerialNumbers.ConnectionKey
			|FROM
			|	Document.SupplierInvoice.SerialNumbers AS CustomerInvoiceSerialNumbers
			|WHERE
			|	CustomerInvoiceSerialNumbers.Ref = &CurrentDocument";
			
			Query.SetParameter("PriceKind", CurrentDocument.StructuralUnit.RetailPriceKind);
			Query.SetParameter("DocumentDate", CurrentDocument.Date);
			Query.SetParameter("ListProductsAndServices", CurrentDocument.Inventory.UnloadColumn("ProductsAndServices"));
			Query.SetParameter("ListCharacteristic", CurrentDocument.Inventory.UnloadColumn("Characteristic"));
			
			ResultsArray = Query.ExecuteBatch();
		
			Header = ResultsArray[0].Select();
			Header.Next();
			
			LinesSelectionInventory = ResultsArray[1].Select();
			LinesSelectionSerialNumbers = ResultsArray[2].Select();
			
			SpreadsheetDocument.PrintParametersName = "PRINT_PARAMETERS_SupplierInvoice_Bill";
			
			Template = PrintManagement.GetTemplate("Document.SupplierInvoice.PF_MXL_Bill");
			InfoAboutCompany = SmallBusinessServer.InfoAboutLegalEntityIndividual(Header.Company, Header.DocumentDate, ,);
			InfoAboutCounterparty = SmallBusinessServer.InfoAboutLegalEntityIndividual(Header.Counterparty, Header.DocumentDate, ,);
			
			If Header.DocumentDate < Date('20110101') Then
				DocumentNumber = SmallBusinessServer.GetNumberForPrinting(Header.Number, Header.Prefix);
			Else
				DocumentNumber = ObjectPrefixationClientServer.GetNumberForPrinting(Header.Number, True, True);
			EndIf;
			
			TemplateArea = Template.GetArea("Title");
			TemplateArea.Parameters.HeaderText =
				NStr("en='Supplier invoice No ';vi='Hóa đơn nhận hàng số '")
				+ DocumentNumber
				+ NStr("en=' from ';vi='ngày'")
				+ Format(Header.DocumentDate, "DLF=DD");
			
			TemplateArea.Parameters.OperationKind = Header.OperationKind;
			
			SpreadsheetDocument.Put(TemplateArea);
			
			TemplateArea = Template.GetArea("Vendor");
			TemplateArea.Parameters.VendorPresentation = SmallBusinessServer.CompaniesDescriptionFull(
				InfoAboutCompany,
				"FullDescr,TIN,LegalAddress,PhoneNumbers,"
			);
			
			SpreadsheetDocument.Put(TemplateArea);
			
			TemplateArea = Template.GetArea("Customer");
			TemplateArea.Parameters.RecipientPresentation = SmallBusinessServer.CompaniesDescriptionFull(
				InfoAboutCounterparty,
				"FullDescr,TIN,LegalAddress,PhoneNumbers,"
			);
			
			SpreadsheetDocument.Put(TemplateArea);
			
			TemplateArea = Template.GetArea("TableHeader");
			SpreadsheetDocument.Put(TemplateArea);
			
			TemplateArea = Template.GetArea("String");
			
			Amount	   = 0;
			VATAmount   = 0;
			Quantity = 0;
			
			While LinesSelectionInventory.Next() Do
			
				TemplateArea.Parameters.Fill(LinesSelectionInventory);
				
				If ValueIsFilled(LinesSelectionInventory.Content) Then
					TemplateArea.Parameters.InventoryItem = LinesSelectionInventory.Content;
				Else
					StringSerialNumbers = WorkWithSerialNumbers.SerialNumbersStringFromSelection(LinesSelectionSerialNumbers, LinesSelectionInventory.ConnectionKey);
					TemplateArea.Parameters.InventoryItem = SmallBusinessServer.GetProductsAndServicesPresentationForPrinting(
						LinesSelectionInventory.InventoryItem,
						LinesSelectionInventory.Characteristic,
						LinesSelectionInventory.SKU,
						StringSerialNumbers
					);
				EndIf;
				
				SpreadsheetDocument.Put(TemplateArea);
				
				Amount = Amount + LinesSelectionInventory.Amount;
				VATAmount = VATAmount + LinesSelectionInventory.VATAmount;
				Quantity = Quantity + 1;
				
			EndDo;
			
			TemplateArea = Template.GetArea("Total");
			TemplateArea.Parameters.Total = SmallBusinessServer.AmountsFormat(Amount);
			SpreadsheetDocument.Put(TemplateArea);
			
			TemplateArea = Template.GetArea("TotalVAT");
			If VATAmount = 0 Then
				TemplateArea.Parameters.VAT = NStr("en='Without tax (VAT)';vi='Không bao gồm thuế GTGT'");
				TemplateArea.Parameters.TotalVAT = "-";
			Else
				TemplateArea.Parameters.VAT = ?(Header.AmountIncludesVAT, NStr("en='Including VAT:';vi='Gồm thuế GTGT:';"), NStr("en='VAT Amount:';vi='Thuế GTGT:';"));
				TemplateArea.Parameters.TotalVAT = SmallBusinessServer.AmountsFormat(VATAmount);
			EndIf;
			SpreadsheetDocument.Put(TemplateArea);
			
			TemplateArea = Template.GetArea("AmountInWords");
			AmountToBeWrittenInWords = Amount + ?(Header.AmountIncludesVAT, 0, VATAmount);
			TemplateArea.Parameters.TotalRow =
				NStr("en='Total titles ';vi='Tổng số '")
			  + String(Quantity)
			  + NStr("en=', in the amount of ';vi=', với tổng số tiền '")
			  + SmallBusinessServer.AmountsFormat(AmountToBeWrittenInWords, Header.DocumentCurrency);
			
			TemplateArea.Parameters.AmountInWords = WorkWithCurrencyRates.GenerateAmountInWords(
				AmountToBeWrittenInWords,
				Header.DocumentCurrency);
			
			SpreadsheetDocument.Put(TemplateArea);
			
			TemplateArea = Template.GetArea("Signatures");
			SpreadsheetDocument.Put(TemplateArea);
			
		ElsIf TemplateName = "MerchandiseFillingForm" Then
			
			Query.Text = 
			"SELECT
			|	SupplierInvoice.Date AS DocumentDate,
			|	SupplierInvoice.StructuralUnit AS WarehousePresentation,
			|	SupplierInvoice.Cell AS CellPresentation,
			|	SupplierInvoice.Number,
			|	SupplierInvoice.Company.Prefix AS Prefix,
			|	SupplierInvoice.Inventory.(
			|		LineNumber AS LineNumber,
			|		ProductsAndServices.Warehouse AS Warehouse,
			|		ProductsAndServices.Cell AS Cell,
			|		CASE
			|			WHEN (CAST(SupplierInvoice.Inventory.ProductsAndServices.DescriptionFull AS String(100))) = """"
			|				THEN SupplierInvoice.Inventory.ProductsAndServices.Description
			|			ELSE SupplierInvoice.Inventory.ProductsAndServices.DescriptionFull
			|		END AS InventoryItem,
			|		ProductsAndServices.SKU AS SKU,
			|		ProductsAndServices.Code AS Code,
			|		MeasurementUnit.Description AS MeasurementUnit,
			|		Quantity AS Quantity,
			|		Characteristic,
			|		ProductsAndServices.ProductsAndServicesType AS ProductsAndServicesType,
			|		ConnectionKey
			|	),
			|	SupplierInvoice.SerialNumbers.(
			|		SerialNumber,
			|		ConnectionKey
			|	)
			|FROM
			|	Document.SupplierInvoice AS SupplierInvoice
			|WHERE
			|	SupplierInvoice.Ref = &CurrentDocument
			|
			|ORDER BY
			|	LineNumber";
			
			Header = Query.Execute().Select();
			Header.Next();
			
			LinesSelectionInventory = Header.Inventory.Select();
			LinesSelectionSerialNumbers = Header.SerialNumbers.Select();
			
			SpreadsheetDocument.PrintParametersName = "PRINT_PARAMETERS_IncomeOrder_FormOfFilling";
			
			Template = PrintManagement.GetTemplate("Document.SupplierInvoice.PF_MXL_MerchandiseFillingForm");
			
			If Header.DocumentDate < Date('20110101') Then
				DocumentNumber = SmallBusinessServer.GetNumberForPrinting(Header.Number, Header.Prefix);
			Else
				DocumentNumber = ObjectPrefixationClientServer.GetNumberForPrinting(Header.Number, True, True);
			EndIf;
			
			TemplateArea = Template.GetArea("Title");
			TemplateArea.Parameters.HeaderText =
				NStr("en='Supplier invoice No ';vi='Hóa đơn nhận hàng số '")
			  + DocumentNumber
			  + NStr("en=' from ';vi=''")
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
			TemplateArea.Parameters.PrintingTime =
				NStr("en='Date and time of printing: ';vi='Ngày và giờ in: ';")
			  + CurrentDate()
			  + NStr("en='. User: ';vi='. Người dùng: ';")
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
				TemplateArea.Parameters.InventoryItem = SmallBusinessServer.GetProductsAndServicesPresentationForPrinting(
					LinesSelectionInventory.InventoryItem,
					LinesSelectionInventory.Characteristic,
					LinesSelectionInventory.SKU,
					StringSerialNumbers
				);
				
				SpreadsheetDocument.Put(TemplateArea);
				
			EndDo;
			
			TemplateArea = Template.GetArea("Total");
			SpreadsheetDocument.Put(TemplateArea);
			
		// 1C - CHIENTN - 21-12-2018	
		ElsIf TemplateName = "WarehouseInputSlip" Then                        		
			GenerateWarehouseInputSlip(SpreadsheetDocument, CurrentDocument);  		
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
//   TemplateNames    - String    - Names of layouts separated
//   by commas ObjectsArray  - Array    - Array of refs to objects that
//   need to be printed PrintParameters - Structure - Structure of additional printing parameters
//
// Outgoing:
//   PrintFormsCollection - Values table - Generated
//   table documents OutputParameters       - Structure        - Parameters of generated table documents
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.NeedToPrintTemplate(PrintFormsCollection, "Consignment") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "Consignment", "Supplier invoice", PrintForm(ObjectsArray, PrintObjects, "Consignment"));
		
	ElsIf PrintManagement.NeedToPrintTemplate(PrintFormsCollection, "InvoiceWithCost") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "InvoiceWithCost", "Purchase invoice (with expenses)", PrintForm(ObjectsArray, PrintObjects, "InvoiceWithCost"));
		
	ElsIf PrintManagement.NeedToPrintTemplate(PrintFormsCollection, "InvoiceInRetailPrices") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "InvoiceInRetailPrices", "Supplier invoice", PrintForm(ObjectsArray, PrintObjects, "InvoiceInRetailPrices"));
		
	ElsIf PrintManagement.NeedToPrintTemplate(PrintFormsCollection, "MerchandiseFillingForm") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "MerchandiseFillingForm", "Merchandise filling form", PrintForm(ObjectsArray, PrintObjects, "MerchandiseFillingForm"));
		
	// 1C - CHIENTN - 27-12-2018
	ElsIf PrintManagement.NeedToPrintTemplate(PrintFormsCollection, "WarehouseInputSlip") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "WarehouseInputSlip", "Warehouse input slip (01-VT)", PrintForm(ObjectsArray, PrintObjects, "WarehouseInputSlip"));
	// 1C
	EndIf;
	
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
	PrintCommand.ID = "WarehouseInputSlip";
	PrintCommand.Presentation = NStr("en='Warehouse input slip (01-VT)';ru='Приходный ордер на товары (01-VT)';vi='Phiếu nhập kho (01-VT)'");
	PrintCommand.FormsList = "DocumentForm,ListForm,DocumentsListForm";
	PrintCommand.CheckPostingBeforePrint = False;
	PrintCommand.Order = 1; 
	// 1C
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.ID = "Consignment";
	PrintCommand.Presentation = NStr("en='Supplier invoice';ru='Приходная накладная';vi='Hóa đơn nhận hàng'");
	PrintCommand.FormsList = "DocumentForm,ListForm,DocumentsListForm";
	PrintCommand.CheckPostingBeforePrint = False;
	PrintCommand.Order = 2;
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.ID = "InvoiceWithCost";
	PrintCommand.Presentation = NStr("en='Supplier invoice (including services)';ru='Приходная накладная (с услугами)';vi='Hóa đơn nhận hàng (có dịch vụ)'");
	PrintCommand.FormsList = "DocumentForm,ListForm,DocumentsListForm";
	PrintCommand.CheckPostingBeforePrint = False;
	PrintCommand.Order = 4;
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.ID = "InvoiceInRetailPrices";
	PrintCommand.Presentation = NStr("en='Supplier invoice (in retail prices)';ru='Приходная накладная (в розничных ценах)';vi='Hóa đơn nhận hàng (theo giá bán lẻ)'");
	PrintCommand.FormsList = "DocumentForm,ListForm,DocumentsListForm";
	PrintCommand.CheckPostingBeforePrint = False;
	PrintCommand.Order = 7;
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.ID = "MerchandiseFillingForm";
	PrintCommand.Presentation = NStr("en='Goods content form';ru='Бланк товарного наполнения';vi='Mẫu bổ sung hàng hóa'");
	PrintCommand.FormsList = "DocumentForm,ListForm,DocumentsListForm";
	PrintCommand.CheckPostingBeforePrint = False;
	PrintCommand.Order = 10;
	
	If AccessRight("view", Metadata.DataProcessors.PrintLabelsAndTags) Then
		
		PrintCommand = PrintCommands.Add();
		PrintCommand.Handler = "SmallBusinessClient.PrintLabelsAndPriceTagsFromDocuments";
		PrintCommand.ID = "LabelsPrintingFromSupplierInvoice";
		PrintCommand.Presentation = NStr("en='Print labels';ru='Печать этикеток';vi='In nhãn tem'");
		PrintCommand.FormsList = "DocumentForm,ListForm,DocumentsListForm";
		PrintCommand.CheckPostingBeforePrint = False;
		PrintCommand.Order = 14;
		
		PrintCommand = PrintCommands.Add();
		PrintCommand.Handler = "SmallBusinessClient.PrintLabelsAndPriceTagsFromDocuments";
		PrintCommand.ID = "PriceTagsPrintingFromSupplierInvoice";
		PrintCommand.Presentation = NStr("en='Print price tags';ru='Печать ценников';vi='In nhãn giá'");
		PrintCommand.FormsList = "DocumentForm,ListForm,DocumentsListForm";
		PrintCommand.CheckPostingBeforePrint = False;
		PrintCommand.Order = 17;
		
	EndIf;
	
EndProcedure

// Procedure of generating printed form SupplierInvoice
// 1C - CHIENTN - 27-12-2018
Procedure GenerateWarehouseInputSlip(SpreadsheetDocument, CurrentDocument)
	
	Query = New Query();
	Query.SetParameter("CurrentDocument", CurrentDocument);  		
	Query.Text = 
	"SELECT
	|	SupplierInvoice.Date AS DocumentDate,
	|	SupplierInvoice.Number AS Number,
	|	SupplierInvoice.Company AS Company,
	|	SupplierInvoice.Company.Prefix AS Prefix,
	|	SupplierInvoice.Department AS Department,
	|	SupplierInvoice.StructuralUnit AS Warehouse,
	|	SupplierInvoice.Counterparty AS Deliverer,
	|	SupplierInvoice.Author AS Author,
	|	SupplierInvoice.DocumentCurrency AS DocumentCurrency,
	|	SupplierInvoice.AmountIncludesVAT AS AmountIncludesVAT,
	|	SupplierInvoice.Inventory.(
	|		LineNumber AS LineNumber,
	|		CASE
	|			WHEN (CAST(SupplierInvoice.Inventory.ProductsAndServices.DescriptionFull AS STRING(1000))) = """"
	|				THEN SupplierInvoice.Inventory.ProductsAndServices.Description
	|			ELSE CAST(SupplierInvoice.Inventory.ProductsAndServices.DescriptionFull AS STRING(1000))
	|		END AS Product,
	|		ProductsAndServices.SKU AS SKU,
	|		ProductsAndServices.Code AS ProductCode,
	|		MeasurementUnit AS Unit,
	|		Quantity AS Quantity,
	|		Price AS Price,
	|		Amount AS Amount,
	|		VATAmount AS VATAmount,
	|		Total AS Total
	|	) AS Inventory
	|FROM
	|	Document.SupplierInvoice AS SupplierInvoice
	|WHERE
	|	SupplierInvoice.Ref = &CurrentDocument
	|
	|ORDER BY
	|	LineNumber";
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	LinesSelectionInventory = Selection.Inventory.Select();
				
	SpreadsheetDocument.PrintParametersName = "PRINT_PARAMETERS_PF_MXL_WarehouseInputSlip_01VT";
	
	Template = PrintManagement.GetTemplate("CommonTemplate.PF_MXL_WarehouseInputSlip_01VT");
	InfoAboutCompany 		= SmallBusinessServer.InfoAboutLegalEntityIndividual(Selection.Company, Selection.DocumentDate, ,);
	InfoAboutCounterparty 	= SmallBusinessServer.InfoAboutLegalEntityIndividual(Selection.Deliverer, Selection.DocumentDate, ,);
	
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
	
	While LinesSelectionInventory.Next() Do  				
		TemplateArea.Parameters.Fill(LinesSelectionInventory);								
		SpreadsheetDocument.Put(TemplateArea);
		
		Amount		= Amount	+ LinesSelectionInventory.Amount;
		VATAmount	= VATAmount	+ LinesSelectionInventory.VATAmount;
		Total		= Total		+ LinesSelectionInventory.Total;
		Quantity	= Quantity  + LinesSelectionInventory.Quantity;  				
	EndDo;
	
	TemplateArea = Template.GetArea("Total");
	FillStructureSection.Insert("Quantity", 			Quantity);
	FillStructureSection.Insert("Total", 				Total); 
	FillStructureSection.Insert("TotalAmountInWords", 	WorkWithCurrencyRates.GenerateAmountInWords(Total, Selection.DocumentCurrency));  
	TemplateArea.Parameters.Fill(FillStructureSection);    
	SpreadsheetDocument.Put(TemplateArea);
	
	TemplateArea = Template.GetArea("Footer"); 
	ResponsiblePersons = SmallBusinessServer.OrganizationalUnitsResponsiblePersons(Selection.Company, Selection.DocumentDate);
	TemplateArea.Parameters.Fill(Selection); 
	TemplateArea.Parameters.Fill(FillStructureSection);
	TemplateArea.Parameters.Fill(ResponsiblePersons);
	SpreadsheetDocument.Put(TemplateArea);				
	
EndProcedure // GenerateWarehouseInputSlip()

#EndRegion

#Region WorkWithSerialNumbers

// Generates a table of values that contains the data for the SerialNumbersGuarantees information register.
// Tables of values saves into the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableSerialNumbers(DocumentRef, StructureAdditionalProperties)
	
	If DocumentRef.SerialNumbers.Count()=0 Then
		StructureAdditionalProperties.TableForRegisterRecords.Insert("TableSerialNumbersBalance", New ValueTable);
		StructureAdditionalProperties.TableForRegisterRecords.Insert("TableSerialNumbersGuarantees", New ValueTable);
		Return;
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	TemporaryTableInventory.Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	VALUE(Enum.SerialNumbersOperations.Receipt) AS Operation,
	|	TemporaryTableInventory.Period AS EventDate,
	|	SerialNumbers.SerialNumber AS SerialNumber,
	|	TemporaryTableInventory.Company AS Company,
	|	TemporaryTableInventory.ProductsAndServices AS ProductsAndServices,
	|	TemporaryTableInventory.Characteristic AS Characteristic,
	|	TemporaryTableInventory.Batch AS Batch,
	|	TemporaryTableInventory.StructuralUnit AS StructuralUnit,
	|	TemporaryTableInventory.Cell AS Cell,
	|	TemporaryTableInventory.OrderWarehouse AS OrderWarehouse,
	|	1 AS Quantity
	|FROM
	|	TemporaryTableInventory AS TemporaryTableInventory
	|		INNER JOIN TemporaryTableSerialNumbers AS SerialNumbers
	|		ON TemporaryTableInventory.ConnectionKey = SerialNumbers.ConnectionKey";
	
	QueryResult = Query.Execute().Unload();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableSerialNumbersGuarantees", QueryResult);
	If StructureAdditionalProperties.AccountingPolicy.SerialNumbersBalance Then
		StructureAdditionalProperties.TableForRegisterRecords.Insert("TableSerialNumbersBalance", QueryResult);
	Else
		StructureAdditionalProperties.TableForRegisterRecords.Insert("TableSerialNumbersBalance", New ValueTable);
	EndIf; 
	
EndProcedure // GenerateTableSerialNumbers()

#EndRegion

#EndIf