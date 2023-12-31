#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableProductRelease(DocumentRefCustomerOrder, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	MIN(TableProductRelease.LineNumber) AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TableProductRelease.Finish AS Period,
	|	TableProductRelease.Company AS Company,
	|	TableProductRelease.StructuralUnit AS StructuralUnit,
	|	TableProductRelease.ProductsAndServices AS ProductsAndServices,
	|	TableProductRelease.Characteristic AS Characteristic,
	|	TableProductRelease.Batch AS Batch,
	|	CASE
	|		WHEN Constants.FunctionalOptionInventoryReservation
	|			THEN TableProductRelease.CustomerOrder
	|		ELSE VALUE(Document.CustomerOrder.EmptyRef)
	|	END AS CustomerOrder,
	|	TableProductRelease.Specification AS Specification,
	|	SUM(TableProductRelease.Quantity) AS Quantity,
	|	0 AS QuantityPlan
	|FROM
	|	TemporaryTableWorks AS TableProductRelease,
	|	Constants AS Constants
	|WHERE
	|	TableProductRelease.ProductsAndServicesType = VALUE(Enum.ProductsAndServicesTypes.Work)
	|	AND TableProductRelease.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|
	|GROUP BY
	|	TableProductRelease.Finish,
	|	TableProductRelease.Company,
	|	TableProductRelease.StructuralUnit,
	|	TableProductRelease.ProductsAndServices,
	|	TableProductRelease.Characteristic,
	|	TableProductRelease.Batch,
	|	TableProductRelease.CustomerOrder,
	|	TableProductRelease.Specification,
	|	Constants.FunctionalOptionInventoryReservation
	|
	|UNION ALL
	|
	|SELECT
	|	MIN(TableProductRelease.LineNumber),
	|	VALUE(AccumulationRecordType.Receipt),
	|	TableProductRelease.Finish,
	|	TableProductRelease.Company,
	|	TableProductRelease.StructuralUnit,
	|	TableProductRelease.ProductsAndServices,
	|	TableProductRelease.Characteristic,
	|	TableProductRelease.Batch,
	|	CASE
	|		WHEN Constants.FunctionalOptionInventoryReservation
	|			THEN TableProductRelease.CustomerOrder
	|		ELSE VALUE(Document.CustomerOrder.EmptyRef)
	|	END,
	|	TableProductRelease.Specification,
	|	0,
	|	SUM(TableProductRelease.Quantity)
	|FROM
	|	TemporaryTableWorks AS TableProductRelease,
	|	Constants AS Constants
	|WHERE
	|	TableProductRelease.ProductsAndServicesType = VALUE(Enum.ProductsAndServicesTypes.Work)
	|	AND (TableProductRelease.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|			OR TableProductRelease.OrderStatus = VALUE(Enum.OrderStatuses.InProcess)
	|				AND (NOT TableProductRelease.Closed))
	|
	|GROUP BY
	|	TableProductRelease.Finish,
	|	TableProductRelease.Company,
	|	TableProductRelease.StructuralUnit,
	|	TableProductRelease.ProductsAndServices,
	|	TableProductRelease.Characteristic,
	|	TableProductRelease.Batch,
	|	TableProductRelease.CustomerOrder,
	|	TableProductRelease.Specification,
	|	Constants.FunctionalOptionInventoryReservation";
	
	QueryResult = Query.Execute();
	         
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableProductRelease", QueryResult.Unload());
	
EndProcedure // GenerateTableProductRelease()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableInventoryTransferSchedule(DocumentRefCustomerOrder, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	1 AS Ordering,
	|	TableWorks.LineNumber AS LineNumber,
	|	BEGINOFPERIOD(TableWorks.Finish, Day) AS Period,
	|	TableWorks.Company AS Company,
	|	VALUE(Enum.InventoryMovementTypes.Shipment) AS MovementType,
	|	TableWorks.CustomerOrder AS Order,
	|	TableWorks.ProductsAndServices AS ProductsAndServices,
	|	TableWorks.Characteristic AS Characteristic,
	|	TableWorks.Quantity AS Quantity
	|FROM
	|	TemporaryTableWorks AS TableWorks
	|
	|UNION ALL
	|
	|SELECT
	|	2,
	|	TableProducts.LineNumber,
	|	BEGINOFPERIOD(TableProducts.Start, Day),
	|	TableProducts.Company,
	|	VALUE(Enum.InventoryMovementTypes.Shipment),
	|	TableProducts.Order,
	|	TableProducts.ProductsAndServices,
	|	TableProducts.Characteristic,
	|	TableProducts.Quantity
	|FROM
	|	TemporaryTableProducts AS TableProducts
	|
	|UNION ALL
	|
	|SELECT
	|	3,
	|	TableMaterials.LineNumber,
	|	BEGINOFPERIOD(TableMaterials.Start, Day),
	|	TableMaterials.Company,
	|	VALUE(Enum.InventoryMovementTypes.Shipment),
	|	TableMaterials.Order,
	|	TableMaterials.ProductsAndServices,
	|	TableMaterials.Characteristic,
	|	TableMaterials.Quantity
	|FROM
	|	TemporaryTableConsumables AS TableMaterials
	|
	|ORDER BY
	|	Ordering,
	|	LineNumber";
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableInventoryTransferSchedule", QueryResult.Unload());
	
EndProcedure // GenerateTableProductRelease()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableCustomerAccounts(DocumentRefCustomerOrder, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	
	Query.SetParameter("Ref", DocumentRefCustomerOrder);
	Query.SetParameter("PointInTime", New Boundary(StructureAdditionalProperties.ForPosting.PointInTime, BoundaryType.Including));
	Query.SetParameter("ControlPeriod", StructureAdditionalProperties.ForPosting.PointInTime.Date);
	Query.SetParameter("Company", StructureAdditionalProperties.ForPosting.Company);
	Query.SetParameter("AppearenceOfCustomerLiability", NStr("en='Incurrence of customer liabilities';ru='Возникновение обязательств покупателя';vi='Phát sinh công nợ phải thu khách hàng'"));
	Query.SetParameter("AdvanceCredit", NStr("en='Prepayment setoff';ru='Зачет предоплаты';vi='Khấu trừ trả trước'"));
	Query.SetParameter("ExchangeDifference", NStr("en='Exchange rate difference';ru='Курсовая разница';vi='Chênh lệch tỷ giá'"));
	
	Query.Text =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentTable.Finish AS Date,
	|	DocumentTable.Company AS Company,
	|	DocumentTable.Counterparty AS Counterparty,
	|	DocumentTable.DoOperationsByDocuments,
	|	DocumentTable.GLAccountCustomerSettlements AS GLAccount,
	|	DocumentTable.Contract AS Contract,
	|	CASE
	|		WHEN DocumentTable.DoOperationsByDocuments
	|			THEN DocumentTable.Document
	|		ELSE UNDEFINED
	|	END AS Document,
	|	CASE
	|		WHEN DocumentTable.DoOperationsByOrders
	|			THEN DocumentTable.CustomerOrder
	|		ELSE VALUE(Document.CustomerOrder.EmptyRef)
	|	END AS Order,
	|	DocumentTable.SettlementsCurrency AS Currency,
	|	VALUE(Enum.SettlementsTypes.Debt) AS SettlementsType,
	|	SUM(DocumentTable.Amount) AS Amount,
	|	SUM(DocumentTable.AmountCur) AS AmountCur,
	|	SUM(DocumentTable.Amount) AS AmountForBalance,
	|	SUM(DocumentTable.AmountCur) AS AmountCurForBalance,
	|	CAST(&AppearenceOfCustomerLiability AS String(100)) AS ContentOfAccountingRecord
	|INTO TemporaryTableAccountsReceivable
	|FROM
	|	TemporaryTableWorks AS DocumentTable
	|WHERE
	|	DocumentTable.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|	AND DocumentTable.Amount <> 0
	|
	|GROUP BY
	|	DocumentTable.Finish,
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
	|			THEN DocumentTable.CustomerOrder
	|		ELSE VALUE(Document.CustomerOrder.EmptyRef)
	|	END,
	|	DocumentTable.SettlementsCurrency,
	|	DocumentTable.GLAccountCustomerSettlements
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt),
	|	DocumentTable.Finish,
	|	DocumentTable.Company,
	|	DocumentTable.Counterparty,
	|	DocumentTable.DoOperationsByDocuments,
	|	DocumentTable.GLAccountCustomerSettlements,
	|	DocumentTable.Contract,
	|	CASE
	|		WHEN DocumentTable.DoOperationsByDocuments
	|			THEN DocumentTable.Document
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.DoOperationsByOrders
	|			THEN DocumentTable.CustomerOrder
	|		ELSE VALUE(Document.CustomerOrder.EmptyRef)
	|	END,
	|	DocumentTable.SettlementsCurrency,
	|	VALUE(Enum.SettlementsTypes.Debt),
	|	SUM(DocumentTable.Amount),
	|	SUM(DocumentTable.AmountCur),
	|	SUM(DocumentTable.Amount),
	|	SUM(DocumentTable.AmountCur),
	|	CAST(&AppearenceOfCustomerLiability AS String(100))
	|FROM
	|	TemporaryTableProducts AS DocumentTable
	|WHERE
	|	DocumentTable.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|	AND DocumentTable.Amount <> 0
	|
	|GROUP BY
	|	DocumentTable.Finish,
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
	|			THEN DocumentTable.CustomerOrder
	|		ELSE VALUE(Document.CustomerOrder.EmptyRef)
	|	END,
	|	DocumentTable.SettlementsCurrency,
	|	DocumentTable.GLAccountCustomerSettlements
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt),
	|	DocumentTable.Finish,
	|	DocumentTable.Company,
	|	DocumentTable.Counterparty,
	|	DocumentTable.DoOperationsByDocuments,
	|	DocumentTable.CustomerAdvancesGLAccount,
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
	|	SUM(DocumentTable.Amount),
	|	SUM(DocumentTable.AmountCur),
	|	SUM(DocumentTable.Amount),
	|	SUM(DocumentTable.AmountCur),
	|	CAST(&AdvanceCredit AS String(100))
	|FROM
	|	TemporaryTablePrepayment AS DocumentTable
	|
	|GROUP BY
	|	DocumentTable.Finish,
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
	|		WHEN DocumentTable.Order = UNDEFINED
	|				OR Not DocumentTable.DoOperationsByOrders
	|			THEN VALUE(Document.CustomerOrder.EmptyRef)
	|		ELSE DocumentTable.Order
	|	END,
	|	DocumentTable.SettlementsType,
	|	DocumentTable.SettlementsCurrency,
	|	DocumentTable.CustomerAdvancesGLAccount
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense),
	|	DocumentTable.Finish,
	|	DocumentTable.Company,
	|	DocumentTable.Counterparty,
	|	DocumentTable.DoOperationsByDocuments,
	|	DocumentTable.GLAccountCustomerSettlements,
	|	DocumentTable.Contract,
	|	CASE
	|		WHEN DocumentTable.DoOperationsByDocuments
	|			THEN DocumentTable.DocumentWhere
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
	|	SUM(DocumentTable.Amount),
	|	SUM(DocumentTable.AmountCur),
	|	-SUM(DocumentTable.Amount),
	|	-SUM(DocumentTable.AmountCur),
	|	CAST(&AdvanceCredit AS String(100))
	|FROM
	|	TemporaryTablePrepayment AS DocumentTable
	|
	|GROUP BY
	|	DocumentTable.Finish,
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
	|		WHEN DocumentTable.Order = UNDEFINED
	|				OR Not DocumentTable.DoOperationsByOrders
	|			THEN VALUE(Document.CustomerOrder.EmptyRef)
	|		ELSE DocumentTable.Order
	|	END,
	|	DocumentTable.GLAccountCustomerSettlements,
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
	|	TemporaryTableAccountsReceivable.Company AS Company,
	|	TemporaryTableAccountsReceivable.Counterparty AS Counterparty,
	|	TemporaryTableAccountsReceivable.Contract AS Contract,
	|	TemporaryTableAccountsReceivable.Document AS Document,
	|	TemporaryTableAccountsReceivable.Order AS Order,
	|	TemporaryTableAccountsReceivable.SettlementsType AS SettlementsType
	|FROM
	|	TemporaryTableAccountsReceivable AS TemporaryTableAccountsReceivable";
	
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
	Query.Text = SmallBusinessServer.GetQueryTextCurrencyExchangeRateAccountsReceivable(Query.TempTablesManager, True, QueryNumber);
	ResultsArray = Query.ExecuteBatch();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableAccountsReceivable", ResultsArray[QueryNumber].Unload());
	
EndProcedure // GenerateTableAccountsReceivable()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableIncomeAndExpenses(DocumentRefCustomerOrder, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	1 AS Ordering,
	|	TableIncomeAndExpenses.LineNumber AS LineNumber,
	|	TableIncomeAndExpenses.Finish AS Period,
	|	TableIncomeAndExpenses.Company AS Company,
	|	TableIncomeAndExpenses.DepartmentSales AS StructuralUnit,
	|	TableIncomeAndExpenses.BusinessActivitySales AS BusinessActivity,
	|	TableIncomeAndExpenses.CustomerOrder AS CustomerOrder,
	|	TableIncomeAndExpenses.AccountStatementSales AS GLAccount,
	|	CAST(&IncomeReflection AS String(100)) AS ContentOfAccountingRecord,
	//( elmi #11
	//|	SUM(TableIncomeAndExpenses.Amount) AS AmountIncome,
	|	SUM(TableIncomeAndExpenses.Amount - TableIncomeAndExpenses.VATAmount) AS AmountIncome,         
	|	0 AS AmountExpense,
	//|	SUM(TableIncomeAndExpenses.Amount) AS Amount
	|	SUM(TableIncomeAndExpenses.Amount - TableIncomeAndExpenses.VATAmount) AS Amount              
	//) elmi
	|FROM
	|	TemporaryTableWorks AS TableIncomeAndExpenses
	|WHERE
	|	TableIncomeAndExpenses.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|	AND TableIncomeAndExpenses.Amount <> 0
	|
	|GROUP BY
	|	TableIncomeAndExpenses.Finish,
	|	TableIncomeAndExpenses.LineNumber,
	|	TableIncomeAndExpenses.Company,
	|	TableIncomeAndExpenses.DepartmentSales,
	|	TableIncomeAndExpenses.BusinessActivitySales,
	|	TableIncomeAndExpenses.CustomerOrder,
	|	TableIncomeAndExpenses.AccountStatementSales
	|
	|UNION ALL
	|
	|SELECT
	|	2,
	|	TableIncomeAndExpenses.LineNumber,
	|	TableIncomeAndExpenses.Finish,
	|	TableIncomeAndExpenses.Company,
	|	TableIncomeAndExpenses.DepartmentSales,
	|	TableIncomeAndExpenses.BusinessActivitySales,
	|	TableIncomeAndExpenses.CustomerOrder,
	|	TableIncomeAndExpenses.AccountStatementSales,
	|	CAST(&IncomeReflection AS String(100)),
	//( elmi #11
	//|	SUM(TableIncomeAndExpenses.Amount),
	|	SUM(TableIncomeAndExpenses.Amount  - TableIncomeAndExpenses.VATAmount),        
	|	0,
	//|	SUM(TableIncomeAndExpenses.Amount)
	|	SUM(TableIncomeAndExpenses.Amount  - TableIncomeAndExpenses.VATAmount)         
	//) elmi
	|FROM
	|	TemporaryTableProducts AS TableIncomeAndExpenses
	|WHERE
	|	TableIncomeAndExpenses.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|	AND TableIncomeAndExpenses.Amount <> 0
	|
	|GROUP BY
	|	TableIncomeAndExpenses.Finish,
	|	TableIncomeAndExpenses.LineNumber,
	|	TableIncomeAndExpenses.Company,
	|	TableIncomeAndExpenses.DepartmentSales,
	|	TableIncomeAndExpenses.BusinessActivitySales,
	|	TableIncomeAndExpenses.CustomerOrder,
	|	TableIncomeAndExpenses.AccountStatementSales
	|
	|UNION ALL
	|
	|SELECT
	|	3,
	|	1,
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
	|	(SELECT
	|		TableExchangeRateDifferencesAccountsReceivable.Date AS Date,
	|		TableExchangeRateDifferencesAccountsReceivable.Company AS Company,
	|		SUM(TableExchangeRateDifferencesAccountsReceivable.AmountOfExchangeDifferences) AS AmountOfExchangeDifferences
	|	FROM
	|		(SELECT
	|			DocumentTable.Date AS Date,
	|			DocumentTable.Company AS Company,
	|			DocumentTable.AmountOfExchangeDifferences AS AmountOfExchangeDifferences
	|		FROM
	|			TemporaryTableExchangeRateDifferencesAccountsReceivable AS DocumentTable
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
	|			TemporaryTableExchangeRateDifferencesAccountsReceivable AS DocumentTable
	|		WHERE
	|			DocumentTable.SettlementsType = VALUE(Enum.SettlementsTypes.Advance)) AS TableExchangeRateDifferencesAccountsReceivable
	|	
	|	GROUP BY
	|		TableExchangeRateDifferencesAccountsReceivable.Date,
	|		TableExchangeRateDifferencesAccountsReceivable.Company
	|	
	|	HAVING
	|		(SUM(TableExchangeRateDifferencesAccountsReceivable.AmountOfExchangeDifferences) >= 0.005
	|			OR SUM(TableExchangeRateDifferencesAccountsReceivable.AmountOfExchangeDifferences) <= -0.005)) AS DocumentTable
	|
	|ORDER BY
	|	Ordering,
	|	LineNumber";
	
	Query.SetParameter("PositiveExchangeDifferenceGLAccount", ChartsOfAccounts.Managerial.OtherIncome);
	Query.SetParameter("NegativeExchangeDifferenceAccountOfAccounting", ChartsOfAccounts.Managerial.OtherExpenses);
	Query.SetParameter("IncomeReflection", NStr("en='Record income';ru='Отражение доходов';vi='Phản ánh thu nhập'"));
	Query.SetParameter("ExchangeDifference", NStr("en='Exchange rate difference';ru='Курсовая разница';vi='Chênh lệch tỷ giá'"));
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableIncomeAndExpenses", QueryResult.Unload());
	
EndProcedure // GenerateTableIncomeAndExpenses()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableIncomeAndExpensesRetained(DocumentRefCustomerOrder, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	
	Query.SetParameter("Ref", DocumentRefCustomerOrder);
	Query.SetParameter("Company", StructureAdditionalProperties.ForPosting.Company);
	Query.SetParameter("IncomeAndExpensesAccountingCashMethod", StructureAdditionalProperties.AccountingPolicy.IncomeAndExpensesAccountingCashMethod);
	
	Query.Text =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.Finish AS Period,
	|	DocumentTable.Company AS Company,
	|	CASE
	|		WHEN DocumentTable.DoOperationsByDocuments
	|			THEN &Ref
	|		ELSE UNDEFINED
	|	END AS Document,
	|	DocumentTable.BusinessActivitySales AS BusinessActivity,
	//( elmi #11
	//|	DocumentTable.Amount AS AmountIncome
	|	DocumentTable.Amount - DocumentTable.VATAmount AS AmountIncome        
	//) elmi
	|FROM
	|	TemporaryTableWorks AS DocumentTable
	|WHERE
	|	&IncomeAndExpensesAccountingCashMethod
	|	AND DocumentTable.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|	AND DocumentTable.Amount <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt),
	|	DocumentTable.LineNumber,
	|	DocumentTable.Finish,
	|	DocumentTable.Company,
	|	CASE
	|		WHEN DocumentTable.DoOperationsByDocuments
	|			THEN &Ref
	|		ELSE UNDEFINED
	|	END,
	|	DocumentTable.BusinessActivitySales,
	//( elmi #11
	//|	DocumentTable.Amount
	|	DocumentTable.Amount - DocumentTable.VATAmount                   
	//) elmi
	|FROM
	|	TemporaryTableProducts AS DocumentTable
	|WHERE
	|	&IncomeAndExpensesAccountingCashMethod
	|	AND DocumentTable.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|	AND DocumentTable.Amount <> 0
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
			ElsIf StringInventoryIncomeAndExpensesRetained.AmountIncome <= AmountToBeWrittenOff Then
				StringPrepaymentIncomeAndExpensesRetained = TablePrepaymentIncomeAndExpensesRetained.Add();
				FillPropertyValues(StringPrepaymentIncomeAndExpensesRetained, StringInventoryIncomeAndExpensesRetained);
				AmountToBeWrittenOff = AmountToBeWrittenOff - StringInventoryIncomeAndExpensesRetained.AmountIncome;
			ElsIf StringInventoryIncomeAndExpensesRetained.AmountIncome > AmountToBeWrittenOff Then
				StringPrepaymentIncomeAndExpensesRetained = TablePrepaymentIncomeAndExpensesRetained.Add();
				FillPropertyValues(StringPrepaymentIncomeAndExpensesRetained, StringInventoryIncomeAndExpensesRetained);
				StringPrepaymentIncomeAndExpensesRetained.AmountIncome = AmountToBeWrittenOff;
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
		Item = Catalogs.CashFlowItems.PaymentFromCustomers;
	EndIf;
	
	Query.Text =
	"SELECT
	|	Table.LineNumber AS LineNumber,
	|	Table.Period AS Period,
	|	Table.Company AS Company,
	|	Table.Document AS Document,
	|	Table.BusinessActivity AS BusinessActivity,
	|	&Item AS Item,
	|	Table.AmountIncome AS AmountIncome
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
Procedure GenerateTableIncomeAndExpensesUndistributed(DocumentRefCustomerOrder, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	
	Query.SetParameter("IncomeAndExpensesAccountingCashMethod", StructureAdditionalProperties.AccountingPolicy.IncomeAndExpensesAccountingCashMethod);
	
	Query.Text =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DocumentTable.Finish AS Period,
	|	DocumentTable.Company AS Company,
	|	CASE
	|		WHEN DocumentTable.DoOperationsByDocuments
	|			THEN DocumentTable.Document
	|		ELSE UNDEFINED
	|	END AS Document,
	|	DocumentTable.Item AS Item,
	|	DocumentTable.Amount AS AmountIncome
	|FROM
	|	TemporaryTablePrepayment AS DocumentTable
	|WHERE
	|	&IncomeAndExpensesAccountingCashMethod";
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableIncomeAndExpensesUndistributed", QueryResult.Unload());
	
EndProcedure // GenerateTableIncomeAndExpensesUndistributed()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableIncomeAndExpensesCashMethod(DocumentRefCustomerOrder, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	
	Query.SetParameter("Ref", DocumentRefCustomerOrder);
	Query.SetParameter("Company", StructureAdditionalProperties.ForPosting.Company);
	Query.SetParameter("PointInTime", New Boundary(StructureAdditionalProperties.ForPosting.PointInTime, BoundaryType.Including));
	Query.SetParameter("IncomeAndExpensesAccountingCashMethod", StructureAdditionalProperties.AccountingPolicy.IncomeAndExpensesAccountingCashMethod);
	
	Query.Text =
	"SELECT
	|	DocumentTable.Finish AS Period,
	|	DocumentTable.Company AS Company,
	|	UNDEFINED AS BusinessActivity,
	|	DocumentTable.Item AS Item,
	|	-DocumentTable.Amount AS AmountIncome
	|FROM
	|	TemporaryTablePrepayment AS DocumentTable
	|WHERE
	|	&IncomeAndExpensesAccountingCashMethod
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Period,
	|	Table.Company,
	|	Table.BusinessActivity,
	|	Table.Item,
	|	Table.AmountIncome
	|FROM
	|	TemporaryTablePrepaidIncomeAndExpensesRetained AS Table";
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableIncomeAndExpensesCashMethod", QueryResult.Unload());
	
EndProcedure // GenerateTableIncomeAndExpensesCashMethod()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableCustomerOrders(DocumentRefCustomerOrder, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	MIN(TableCustomerOrders.LineNumber) AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TableCustomerOrders.Period AS Period,
	|	TableCustomerOrders.Company AS Company,
	|	TableCustomerOrders.ProductsAndServices AS ProductsAndServices,
	|	TableCustomerOrders.Characteristic AS Characteristic,
	|	TableCustomerOrders.CustomerOrder AS CustomerOrder,
	|	SUM(TableCustomerOrders.QuantityPlan) AS Quantity
	|FROM
	|	TemporaryTableWorks AS TableCustomerOrders
	|
	|GROUP BY
	|	TableCustomerOrders.Period,
	|	TableCustomerOrders.Company,
	|	TableCustomerOrders.ProductsAndServices,
	|	TableCustomerOrders.Characteristic,
	|	TableCustomerOrders.CustomerOrder
	|
	|UNION ALL
	|
	|SELECT
	|	MIN(TableCustomerOrders.LineNumber),
	|	VALUE(AccumulationRecordType.Receipt),
	|	TableCustomerOrders.Period,
	|	TableCustomerOrders.Company,
	|	TableCustomerOrders.ProductsAndServices,
	|	TableCustomerOrders.Characteristic,
	|	TableCustomerOrders.CustomerOrder,
	|	SUM(TableCustomerOrders.Quantity)
	|FROM
	|	TemporaryTableProducts AS TableCustomerOrders
	|
	|GROUP BY
	|	TableCustomerOrders.Period,
	|	TableCustomerOrders.Company,
	|	TableCustomerOrders.ProductsAndServices,
	|	TableCustomerOrders.Characteristic,
	|	TableCustomerOrders.CustomerOrder
	|
	|UNION ALL
	|
	|SELECT
	|	MIN(TableCustomerOrders.LineNumber),
	|	VALUE(AccumulationRecordType.Expense),
	|	TableCustomerOrders.Finish,
	|	TableCustomerOrders.Company,
	|	TableCustomerOrders.ProductsAndServices,
	|	TableCustomerOrders.Characteristic,
	|	TableCustomerOrders.CustomerOrder,
	|	SUM(TableCustomerOrders.Quantity)
	|FROM
	|	TemporaryTableWorks AS TableCustomerOrders
	|WHERE
	|	TableCustomerOrders.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|
	|GROUP BY
	|	TableCustomerOrders.Finish,
	|	TableCustomerOrders.Company,
	|	TableCustomerOrders.ProductsAndServices,
	|	TableCustomerOrders.Characteristic,
	|	TableCustomerOrders.CustomerOrder
	|
	|UNION ALL
	|
	|SELECT
	|	MIN(TableCustomerOrders.LineNumber),
	|	VALUE(AccumulationRecordType.Expense),
	|	TableCustomerOrders.Finish,
	|	TableCustomerOrders.Company,
	|	TableCustomerOrders.ProductsAndServices,
	|	TableCustomerOrders.Characteristic,
	|	TableCustomerOrders.CustomerOrder,
	|	SUM(TableCustomerOrders.Quantity)
	|FROM
	|	TemporaryTableProducts AS TableCustomerOrders
	|WHERE
	|	TableCustomerOrders.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|
	|GROUP BY
	|	TableCustomerOrders.Finish,
	|	TableCustomerOrders.Company,
	|	TableCustomerOrders.ProductsAndServices,
	|	TableCustomerOrders.Characteristic,
	|	TableCustomerOrders.CustomerOrder";
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableCustomerOrders", QueryResult.Unload());
	
EndProcedure // GenerateTableCustomerOrders()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableInventoryInWarehouses(DocumentRefCustomerOrder, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	MIN(TableInventoryInWarehouses.LineNumber) AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	TableInventoryInWarehouses.Finish AS Period,
	|	TableInventoryInWarehouses.Company AS Company,
	|	TableInventoryInWarehouses.ProductsAndServices AS ProductsAndServices,
	|	TableInventoryInWarehouses.Characteristic AS Characteristic,
	|	TableInventoryInWarehouses.Batch AS Batch,
	|	TableInventoryInWarehouses.StructuralUnit AS StructuralUnit,
	|	TableInventoryInWarehouses.Cell AS Cell,
	|	SUM(TableInventoryInWarehouses.Quantity) AS Quantity
	|FROM
	|	TemporaryTableProducts AS TableInventoryInWarehouses
	|WHERE
	|	(NOT TableInventoryInWarehouses.OrderWarehouse)
	|	AND TableInventoryInWarehouses.ProductsAndServicesType = VALUE(Enum.ProductsAndServicesTypes.InventoryItem)
	|	AND TableInventoryInWarehouses.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|
	|GROUP BY
	|	TableInventoryInWarehouses.Finish,
	|	TableInventoryInWarehouses.Company,
	|	TableInventoryInWarehouses.ProductsAndServices,
	|	TableInventoryInWarehouses.Characteristic,
	|	TableInventoryInWarehouses.Batch,
	|	TableInventoryInWarehouses.StructuralUnit,
	|	TableInventoryInWarehouses.Cell
	|
	|UNION ALL
	|
	|SELECT
	|	MIN(TableInventoryInWarehouses.LineNumber),
	|	VALUE(AccumulationRecordType.Expense),
	|	TableInventoryInWarehouses.Finish,
	|	TableInventoryInWarehouses.Company,
	|	TableInventoryInWarehouses.ProductsAndServices,
	|	TableInventoryInWarehouses.Characteristic,
	|	TableInventoryInWarehouses.Batch,
	|	TableInventoryInWarehouses.InventoryStructuralUnit,
	|	TableInventoryInWarehouses.Cell,
	|	SUM(TableInventoryInWarehouses.Quantity)
	|FROM
	|	TemporaryTableConsumables AS TableInventoryInWarehouses
	|WHERE
	|	(NOT TableInventoryInWarehouses.OrderWarehouse)
	|	AND TableInventoryInWarehouses.ProductsAndServicesType = VALUE(Enum.ProductsAndServicesTypes.InventoryItem)
	|	AND TableInventoryInWarehouses.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|
	|GROUP BY
	|	TableInventoryInWarehouses.Finish,
	|	TableInventoryInWarehouses.Company,
	|	TableInventoryInWarehouses.ProductsAndServices,
	|	TableInventoryInWarehouses.Characteristic,
	|	TableInventoryInWarehouses.Batch,
	|	TableInventoryInWarehouses.InventoryStructuralUnit,
	|	TableInventoryInWarehouses.Cell
	|
	|UNION ALL
	|
	|SELECT
	|	MIN(TableInventoryInWarehouses.LineNumber),
	|	VALUE(AccumulationRecordType.Receipt),
	|	TableInventoryInWarehouses.Finish,
	|	TableInventoryInWarehouses.Company,
	|	TableInventoryInWarehouses.ProductsAndServices,
	|	TableInventoryInWarehouses.Characteristic,
	|	TableInventoryInWarehouses.Batch,
	|	TableInventoryInWarehouses.StructuralUnit,
	|	VALUE(Catalog.Cells.EmptyRef),
	|	SUM(TableInventoryInWarehouses.Quantity)
	|FROM
	|	TemporaryTableConsumables AS TableInventoryInWarehouses
	|WHERE
	|	TableInventoryInWarehouses.ProductsAndServicesType = VALUE(Enum.ProductsAndServicesTypes.InventoryItem)
	|	AND TableInventoryInWarehouses.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|
	|GROUP BY
	|	TableInventoryInWarehouses.Finish,
	|	TableInventoryInWarehouses.Company,
	|	TableInventoryInWarehouses.ProductsAndServices,
	|	TableInventoryInWarehouses.Characteristic,
	|	TableInventoryInWarehouses.Batch,
	|	TableInventoryInWarehouses.StructuralUnit
	|
	|UNION ALL
	|
	|SELECT
	|	MIN(TableInventoryInWarehouses.LineNumber),
	|	VALUE(AccumulationRecordType.Expense),
	|	TableInventoryInWarehouses.Finish,
	|	TableInventoryInWarehouses.Company,
	|	TableInventoryInWarehouses.ProductsAndServices,
	|	TableInventoryInWarehouses.Characteristic,
	|	TableInventoryInWarehouses.Batch,
	|	TableInventoryInWarehouses.StructuralUnit,
	|	VALUE(Catalog.Cells.EmptyRef),
	|	SUM(TableInventoryInWarehouses.Quantity)
	|FROM
	|	TemporaryTableConsumables AS TableInventoryInWarehouses
	|WHERE
	|	TableInventoryInWarehouses.ProductsAndServicesType = VALUE(Enum.ProductsAndServicesTypes.InventoryItem)
	|	AND TableInventoryInWarehouses.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|
	|GROUP BY
	|	TableInventoryInWarehouses.Finish,
	|	TableInventoryInWarehouses.Company,
	|	TableInventoryInWarehouses.ProductsAndServices,
	|	TableInventoryInWarehouses.Characteristic,
	|	TableInventoryInWarehouses.Batch,
	|	TableInventoryInWarehouses.StructuralUnit";
		
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableInventoryInWarehouses", QueryResult.Unload());
	
EndProcedure // GenerateTableInventoryInWarehouses()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableInventoryForExpenseFromWarehouses(DocumentRefCustomerOrder, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	TableInventory.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TableInventory.Period AS Period,
	|	TableInventory.Company AS Company,
	|	TableInventory.InventoryStructuralUnit AS StructuralUnit,
	|	TableInventory.ProductsAndServices AS ProductsAndServices,
	|	TableInventory.Characteristic AS Characteristic,
	|	TableInventory.Batch AS Batch,
	|	TableInventory.Quantity AS Quantity
	|FROM
	|	TemporaryTableConsumables AS TableInventory
	|WHERE
	|	TableInventory.OrderWarehouse
	|	AND TableInventory.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|
	|UNION ALL
	|
	|SELECT
	|	TableInventory.LineNumber,
	|	VALUE(AccumulationRecordType.Receipt),
	|	TableInventory.Period,
	|	TableInventory.Company,
	|	TableInventory.StructuralUnit,
	|	TableInventory.ProductsAndServices,
	|	TableInventory.Characteristic,
	|	TableInventory.Batch,
	|	TableInventory.Quantity
	|FROM
	|	TemporaryTableProducts AS TableInventory
	|WHERE
	|	TableInventory.OrderWarehouse
	|	AND TableInventory.OrderStatus = VALUE(Enum.OrderStatuses.Completed)";
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableInventoryForExpenseFromWarehouses", QueryResult.Unload());
	
EndProcedure // GenerateTableInventoryForExpenseFromWarehouses()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableAccrualsAndDeductions(DocumentRefCustomerOrder, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	TableAccrualsAndDeductions.Company AS Company,
	|	TableAccrualsAndDeductions.Period AS Period,
	|	TableAccrualsAndDeductions.RegistrationPeriod AS RegistrationPeriod,
	|	TableAccrualsAndDeductions.Currency AS Currency,
	|	TableAccrualsAndDeductions.StructuralUnit AS StructuralUnit,
	|	TableAccrualsAndDeductions.Employee AS Employee,
	|	TableAccrualsAndDeductions.StartDate AS StartDate,
	|	TableAccrualsAndDeductions.EndDate AS EndDate,
	|	TableAccrualsAndDeductions.DaysWorked AS DaysWorked,
	|	TableAccrualsAndDeductions.HoursWorked AS HoursWorked,
	|	TableAccrualsAndDeductions.Size AS Size,
	|	TableAccrualsAndDeductions.AccrualDeductionKind AS AccrualDeductionKind,
	|	TableAccrualsAndDeductions.AmountCur AS AmountCur,
	|	TableAccrualsAndDeductions.Amount AS Amount
	|FROM
	|	TemporaryTableArtist AS TableAccrualsAndDeductions";
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableAccrualsAndDeductions", QueryResult.Unload());
	
EndProcedure // GenerateTableSales()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTablePayrollPayments(DocumentRefCustomerOrder, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	TablePayrollPayments.Company AS Company,
	|	TablePayrollPayments.Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TablePayrollPayments.RegistrationPeriod AS RegistrationPeriod,
	|	TablePayrollPayments.Currency AS Currency,
	|	TablePayrollPayments.StructuralUnit AS StructuralUnit,
	|	TablePayrollPayments.Employee AS Employee,
	|	TablePayrollPayments.Amount AS Amount,
	|	TablePayrollPayments.AmountCur AS AmountCur,
	|	TablePayrollPayments.GLAccount AS GLAccount,
	|	&Payroll AS ContentOfAccountingRecord
	|FROM
	|	TemporaryTableArtist AS TablePayrollPayments";
	
	Query.SetParameter("Payroll", NStr("en='Payroll';ru='Начисление зарплаты';vi='Trả lương'"));
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TablePayrollPayments", QueryResult.Unload());
	
EndProcedure // GenerateTableSales()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableSales(DocumentRefCustomerOrder, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	TableSales.Finish AS Period,
	|	TableSales.Company AS Company,
	|	TableSales.ProductsAndServices AS ProductsAndServices,
	|	TableSales.Characteristic AS Characteristic,
	|	TableSales.Batch AS Batch,
	|	TableSales.CustomerOrder AS CustomerOrder,
	|	TableSales.Document AS Document,
	|	TableSales.VATRate AS VATRate,
	|	TableSales.StructuralUnit AS Department,
	|	TableSales.Responsible AS Responsible,
	|	SUM(TableSales.Quantity) AS Quantity,
	|	SUM(TableSales.VATAmountSales) AS VATAmount,
	|	SUM(TableSales.Amount) AS Amount,
	|	0 AS Cost
	|FROM
	|	TemporaryTableWorks AS TableSales
	|WHERE
	|	TableSales.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|
	|GROUP BY
	|	TableSales.Finish,
	|	TableSales.Company,
	|	TableSales.ProductsAndServices,
	|	TableSales.Characteristic,
	|	TableSales.Batch,
	|	TableSales.CustomerOrder,
	|	TableSales.Document,
	|	TableSales.VATRate,
	|	TableSales.StructuralUnit,
	|	TableSales.Responsible
	|
	|UNION ALL
	|
	|SELECT
	|	TableSales.Finish,
	|	TableSales.Company,
	|	TableSales.ProductsAndServices,
	|	TableSales.Characteristic,
	|	TableSales.Batch,
	|	TableSales.CustomerOrder,
	|	TableSales.Document,
	|	TableSales.VATRate,
	|	TableSales.DepartmentSales,
	|	TableSales.Responsible,
	|	SUM(TableSales.Quantity),
	|	SUM(TableSales.AmountVATPurchaseSale),
	|	SUM(TableSales.Amount),
	|	0
	|FROM
	|	TemporaryTableProducts AS TableSales
	|WHERE
	|	TableSales.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|
	|GROUP BY
	|	TableSales.Finish,
	|	TableSales.Company,
	|	TableSales.ProductsAndServices,
	|	TableSales.Characteristic,
	|	TableSales.Batch,
	|	TableSales.CustomerOrder,
	|	TableSales.Document,
	|	TableSales.VATRate,
	|	TableSales.DepartmentSales,
	|	TableSales.Responsible";
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableSales", QueryResult.Unload());
	
EndProcedure // GenerateTableSales()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableInventoryDemand(DocumentRefCustomerOrder, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	TableInventoryDemand.LineNumber,
	|	BEGINOFPERIOD(TableInventoryDemand.Start, Day) AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TableInventoryDemand.Company,
	|	VALUE(Enum.InventoryMovementTypes.Shipment) AS MovementType,
	|	CASE
	|		WHEN Constants.FunctionalOptionInventoryReservation
	|			THEN TableInventoryDemand.CustomerOrder
	|		ELSE VALUE(Document.CustomerOrder.EmptyRef)
	|	END AS CustomerOrder,
	|	TableInventoryDemand.ProductsAndServices,
	|	TableInventoryDemand.Characteristic,
	|	TableInventoryDemand.Quantity
	|FROM
	|	TemporaryTableConsumables AS TableInventoryDemand,
	|	Constants AS Constants
	|
	|UNION ALL
	|
	|SELECT
	|	TableInventoryDemand.LineNumber,
	|	BEGINOFPERIOD(TableInventoryDemand.Finish, Day),
	|	VALUE(AccumulationRecordType.Expense),
	|	TableInventoryDemand.Company,
	|	VALUE(Enum.InventoryMovementTypes.Shipment),
	|	CASE
	|		WHEN Constants.FunctionalOptionInventoryReservation
	|			THEN TableInventoryDemand.CustomerOrder
	|		ELSE VALUE(Document.CustomerOrder.EmptyRef)
	|	END,
	|	TableInventoryDemand.ProductsAndServices,
	|	TableInventoryDemand.Characteristic,
	|	TableInventoryDemand.Quantity
	|FROM
	|	TemporaryTableConsumables AS TableInventoryDemand,
	|	Constants AS Constants
	|WHERE
	|	TableInventoryDemand.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|
	|ORDER BY
	|	TableInventoryDemand.LineNumber";
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableInventoryDemand", QueryResult.Unload());
	
EndProcedure // GenerateTableSales()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableInventoryReceived(DocumentRefCustomerOrder, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	MIN(TableInventoryReceived.LineNumber) AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TableInventoryReceived.Finish AS Period,
	|	TableInventoryReceived.Company AS Company,
	|	TableInventoryReceived.ProductsAndServices AS ProductsAndServices,
	|	TableInventoryReceived.Characteristic AS Characteristic,
	|	TableInventoryReceived.Batch AS Batch,
	|	TableInventoryReceived.Order AS Order,
	|	TableInventoryReceived.GLAccount AS GLAccount,
	|	VALUE(Enum.ProductsReceiptTransferTypes.ReportToPrincipal) AS ReceptionTransmissionType,
	|	SUM(TableInventoryReceived.Quantity) AS Quantity,
	|	0 AS SettlementsAmount,
	|	SUM(TableInventoryReceived.Amount) AS Amount,
	|	SUM(TableInventoryReceived.Amount) AS SalesAmount,
	|	&AdmAccountingCurrency AS Currency,
	|	SUM(TableInventoryReceived.Amount) AS AmountCur,
	|	CAST(&InventoryReceiptProductsOnCommission AS String(100)) AS ContentOfAccountingRecord
	|FROM
	|	TemporaryTableProducts AS TableInventoryReceived
	|WHERE
	|	TableInventoryReceived.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|	AND TableInventoryReceived.ProductsAndServicesType = VALUE(Enum.ProductsAndServicesTypes.InventoryItem)
	|	AND TableInventoryReceived.ProductsOnCommission
	|
	|GROUP BY
	|	TableInventoryReceived.Finish,
	|	TableInventoryReceived.Company,
	|	TableInventoryReceived.ProductsAndServices,
	|	TableInventoryReceived.Characteristic,
	|	TableInventoryReceived.Batch,
	|	TableInventoryReceived.Order,
	|	TableInventoryReceived.GLAccount";
	
	Query.SetParameter("InventoryReceiptProductsOnCommission", NStr("en='Inventory receipt';ru='Прием запасов';vi='Tiếp nhận vật tư'"));
	Query.SetParameter("AdmAccountingCurrency", Constants.AccountingCurrency.Get());
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableInventoryReceived", QueryResult.Unload());
	
EndProcedure // GenerateTableInventoryReceived()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableInventoryWorks(DocumentRefCustomerOrder, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	MIN(TableInventory.LineNumber) AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TableInventory.Finish AS Period,
	|	TableInventory.PlanningPeriod AS PlanningPeriod,
	|	TableInventory.Company AS Company,
	|	TableInventory.Document AS Document,
	|	TableInventory.Document AS SalesDocument,
	|	TableInventory.CustomerOrder AS OrderSales,
	|	TableInventory.DepartmentSales AS Department,
	|	TableInventory.Responsible AS Responsible,
	|	TableInventory.BusinessActivitySales AS BusinessActivity,
	|	TableInventory.GLAccountCost AS GLAccountCost,
	|	TableInventory.StructuralUnit AS StructuralUnit,
	|	TableInventory.GLAccount AS GLAccount,
	|	TableInventory.ProductsAndServices AS ProductsAndServices,
	|	TableInventory.Characteristic AS Characteristic,
	|	TableInventory.Batch AS Batch,
	|	CASE
	|		WHEN Constants.FunctionalOptionInventoryReservation
	|			THEN TableInventory.CustomerOrder
	|		ELSE VALUE(Document.CustomerOrder.EmptyRef)
	|	END AS CustomerOrder,
	|	TableInventory.VATRate AS VATRate,
	|	SUM(TableInventory.Quantity) AS Quantity,
	|	0 AS Amount,
	|	SUM(TableInventory.VATAmount) AS VATAmount,
	|	FALSE AS FixedCost,
	|	TableInventory.GLAccountCost AS AccountDr,
	|	TableInventory.GLAccount AS AccountCr,
	|	CAST(&InventoryAssembly AS String(100)) AS ContentOfAccountingRecord,
	|	CAST(&InventoryAssembly AS String(100)) AS Content,
	|	FALSE AS ProductionExpenses,
	|	VALUE(Catalog.StructuralUnits.EmptyRef) AS StructuralUnitCorr,
	|	VALUE(ChartOfAccounts.Managerial.EmptyRef) AS CorrGLAccount,
	|	VALUE(Catalog.ProductsAndServices.EmptyRef) AS ProductsAndServicesCorr,
	|	VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef) AS CharacteristicCorr,
	|	VALUE(Catalog.ProductsAndServicesBatches.EmptyRef) AS BatchCorr,
	|	UNDEFINED AS CustomerCorrOrder,
	|	TableInventory.Specification AS Specification,
	|	VALUE(Catalog.Specifications.EmptyRef) AS SpecificationCorr
	|FROM
	|	TemporaryTableWorks AS TableInventory
	|		LEFT JOIN Constants AS Constants
	|		ON (TRUE)
	|WHERE
	|	TableInventory.ProductsAndServicesType = VALUE(Enum.ProductsAndServicesTypes.Work)
	|	AND TableInventory.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|
	|GROUP BY
	|	TableInventory.Finish,
	|	TableInventory.Company,
	|	TableInventory.PlanningPeriod,
	|	TableInventory.Document,
	|	TableInventory.BusinessActivitySales,
	|	TableInventory.GLAccountCost,
	|	TableInventory.StructuralUnit,
	|	TableInventory.GLAccount,
	|	TableInventory.ProductsAndServices,
	|	TableInventory.Characteristic,
	|	TableInventory.Batch,
	|	TableInventory.CustomerOrder,
	|	TableInventory.Specification,
	|	TableInventory.VATRate,
	|	Constants.FunctionalOptionInventoryReservation,
	|	TableInventory.Responsible,
	|	TableInventory.DepartmentSales,
	|	TableInventory.Document,
	|	TableInventory.GLAccountCost,
	|	TableInventory.GLAccount";
	
	Query.SetParameter("InventoryAssembly", NStr("en='Production';ru='Производство';vi='Sản xuất'"));
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableInventory", QueryResult.Unload());
	
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	
	OrderBlankRef = Documents.CustomerOrder.EmptyRef();
	
	TemporaryTableInventory = StructureAdditionalProperties.TableForRegisterRecords.TableInventory.CopyColumns();
	
	For n = 0 To StructureAdditionalProperties.TableForRegisterRecords.TableInventory.Count() - 1 Do
		
		RowTableInventory = StructureAdditionalProperties.TableForRegisterRecords.TableInventory[n];
		
		QuantityWanted = RowTableInventory.Quantity;
		
		If QuantityWanted > 0 Then
			
			// Adding work release.
			TableRowReceipt = TemporaryTableInventory.Add();
			FillPropertyValues(TableRowReceipt, RowTableInventory);
			
			TableRowReceipt.SalesDocument = Undefined;
			TableRowReceipt.OrderSales = Undefined;
			TableRowReceipt.Department = Undefined;
			TableRowReceipt.Responsible = Undefined;
			
			QuantityBalance = 0;
			AmountBalance = 0;
			AmountToBeWrittenOff = 0;
			
			// Adding work completion.
			TableRowExpense = TemporaryTableInventory.Add();
			FillPropertyValues(TableRowExpense, RowTableInventory);
			
			TableRowExpense.RecordType = AccumulationRecordType.Expense;
			TableRowExpense.ContentOfAccountingRecord = NStr("en='Inventory write-off';ru='Списание запасов';vi='Ghi giảm vật tư'");
			
			TableRowExpense.Amount = AmountToBeWrittenOff;
				
		EndIf;
			
	EndDo;
	
	StructureAdditionalProperties.TableForRegisterRecords.TableInventory = TemporaryTableInventory;
	
EndProcedure // GenerateTableInventory()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableInventoryMaterials(DocumentRefCustomerOrder, StructureAdditionalProperties)
	
	// AutomaticWriteOff
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	MIN(TableInventory.LineNumber) AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	TableInventory.PlanningPeriod AS PlanningPeriod,
	|	TableInventory.Finish AS Period,
	|	TableInventory.Period AS DocumentDate,
	|	TableInventory.Company AS Company,
	|	TableInventory.InventoryStructuralUnit AS StructuralUnit,
	|	TableInventory.StructuralUnit AS StructuralUnitCorr,
	|	TableInventory.InventoryGLAccount AS GLAccount,
	|	TableInventory.GLAccount AS CorrGLAccount,
	|	TableInventory.ProductsAndServices AS ProductsAndServices,
	|	TableInventory.OrderStatus AS OrderStatus,
	|	TableInventory.ProductsAndServices AS ProductsAndServicesCorr,
	|	TableInventory.Characteristic AS Characteristic,
	|	TableInventory.Characteristic AS CharacteristicCorr,
	|	TableInventory.Batch AS Batch,
	|	TableInventory.Batch AS BatchCorr,
	|	TableInventory.Specification AS Specification,
	|	TableInventory.SpecificationCorr AS SpecificationCorr,
	|	TableInventory.CustomerOrder AS CustomerOrder,
	|	TableInventory.CustomerOrder AS CustomerCorrOrder,
	|	UNDEFINED AS SalesDocument,
	|	UNDEFINED AS OrderSales,
	|	UNDEFINED AS Department,
	|	UNDEFINED AS Responsible,
	|	TableInventory.GLAccount AS AccountDr,
	|	TableInventory.InventoryGLAccount AS AccountCr,
	|	&InventoryTransfer AS Content,
	|	&InventoryTransfer AS ContentOfAccountingRecord,
	|	SUM(TableInventory.Quantity) AS Quantity,
	|	SUM(TableInventory.Reserve) AS Reserve,
	|	SUM(TableInventory.ReserveShipment) AS ReserveShipment,
	|	SUM(TableInventory.Amount) AS Amount,
	|	FALSE AS FixedCost
	|FROM
	|	TemporaryTableConsumables AS TableInventory
	|WHERE
	|	(TableInventory.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|			OR TableInventory.OrderStatus = VALUE(Enum.OrderStatuses.InProcess))
	|
	|GROUP BY
	|	TableInventory.Finish,
	|	TableInventory.Period,
	|	TableInventory.OrderStatus,
	|	TableInventory.Company,
	|	TableInventory.PlanningPeriod,
	|	TableInventory.StructuralUnit,
	|	TableInventory.InventoryStructuralUnit,
	|	TableInventory.GLAccount,
	|	TableInventory.InventoryGLAccount,
	|	TableInventory.ProductsAndServices,
	|	TableInventory.Characteristic,
	|	TableInventory.Batch,
	|	TableInventory.Specification,
	|	TableInventory.SpecificationCorr,
	|	TableInventory.CustomerOrder,
	|	TableInventory.CorrGLAccount,
	|	TableInventory.ProductsAndServices,
	|	TableInventory.Characteristic,
	|	TableInventory.Batch,
	|	TableInventory.CustomerOrder,
	|	TableInventory.GLAccount,
	|	TableInventory.InventoryGLAccount";
	
	Query.SetParameter("InventoryTransfer", NStr("en='Inventory movement';ru='Перемещение запасов';vi='Điều chuyển vật tư'"));
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableInventoryMove", Query.Execute().Unload());
	
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
	|	TableInventory.CustomerOrder AS CustomerOrder
	|FROM
	|	(SELECT
	|		TableInventory.Company AS Company,
	|		TableInventory.InventoryStructuralUnit AS StructuralUnit,
	|		TableInventory.InventoryGLAccount AS GLAccount,
	|		TableInventory.ProductsAndServices AS ProductsAndServices,
	|		TableInventory.Characteristic AS Characteristic,
	|		TableInventory.Batch AS Batch,
	|		TableInventory.CustomerOrder AS CustomerOrder
	|	FROM
	|		TemporaryTableConsumables AS TableInventory
	|	WHERE
	|		TableInventory.CustomerOrder <> VALUE(Document.CustomerOrder.EmptyRef)
	|		AND TableInventory.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableInventory.Company,
	|		TableInventory.InventoryStructuralUnit,
	|		TableInventory.InventoryGLAccount,
	|		TableInventory.ProductsAndServices,
	|		TableInventory.Characteristic,
	|		TableInventory.Batch,
	|		VALUE(Document.CustomerOrder.EmptyRef)
	|	FROM
	|		TemporaryTableConsumables AS TableInventory
	|	WHERE
	|		TableInventory.OrderStatus = VALUE(Enum.OrderStatuses.Completed)) AS TableInventory
	|
	|GROUP BY
	|	TableInventory.Company,
	|	TableInventory.StructuralUnit,
	|	TableInventory.GLAccount,
	|	TableInventory.ProductsAndServices,
	|	TableInventory.Characteristic,
	|	TableInventory.Batch,
	|	TableInventory.CustomerOrder";
	
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
	|						TableInventory.Company,
	|						TableInventory.InventoryStructuralUnit AS StructuralUnit,
	|						TableInventory.InventoryGLAccount AS GLAccount,
	|						TableInventory.ProductsAndServices,
	|						TableInventory.Characteristic,
	|						TableInventory.Batch,
	|						TableInventory.CustomerOrder
	|					FROM
	|						TemporaryTableConsumables AS TableInventory
	|					WHERE
	|						TableInventory.CustomerOrder <> VALUE(Document.CustomerOrder.EmptyRef)
	|						AND TableInventory.OrderStatus = VALUE(Enum.OrderStatuses.Completed))) AS InventoryBalances
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
	|		InventoryBalances.Company,
	|		InventoryBalances.StructuralUnit,
	|		InventoryBalances.GLAccount,
	|		InventoryBalances.ProductsAndServices,
	|		InventoryBalances.Characteristic,
	|		InventoryBalances.Batch,
	|		InventoryBalances.CustomerOrder,
	|		SUM(InventoryBalances.QuantityBalance),
	|		SUM(InventoryBalances.AmountBalance)
	|	FROM
	|		AccumulationRegister.Inventory.Balance(
	|				&ControlTime,
	|				(Company, StructuralUnit, GLAccount, ProductsAndServices, Characteristic, Batch, CustomerOrder) In
	|					(SELECT
	|						TableInventory.Company,
	|						TableInventory.InventoryStructuralUnit AS StructuralUnit,
	|						TableInventory.InventoryGLAccount AS GLAccount,
	|						TableInventory.ProductsAndServices,
	|						TableInventory.Characteristic,
	|						TableInventory.Batch,
	|						VALUE(Document.CustomerOrder.EmptyRef)
	|					FROM
	|						TemporaryTableConsumables AS TableInventory
	|					WHERE
	|						(TableInventory.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|							OR TableInventory.OrderStatus = VALUE(Enum.OrderStatuses.InProcess)))) AS InventoryBalances
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
	
	Query.SetParameter("Ref", DocumentRefCustomerOrder);
	Query.SetParameter("ControlTime", New Boundary(StructureAdditionalProperties.ForPosting.Ref.Finish, BoundaryType.Including));
	Query.SetParameter("ControlPeriod", StructureAdditionalProperties.ForPosting.Ref.Finish);
	
	QueryResult = Query.Execute();
	
	TableInventoryBalancesMove = QueryResult.Unload();
	TableInventoryBalancesMove.Indexes.Add("Company,StructuralUnit,GLAccount,ProductsAndServices,Characteristic,Batch,CustomerOrder");
	
	TemporaryTableInventoryTransfer = StructureAdditionalProperties.TableForRegisterRecords.TableInventoryMove.CopyColumns();
	
	IsEmptyStructuralUnit = Catalogs.StructuralUnits.EmptyRef();
	EmptyAccount = ChartsOfAccounts.Managerial.EmptyRef();
	EmptyProductsAndServices = Catalogs.ProductsAndServices.EmptyRef();
	EmptyCharacteristic = Catalogs.ProductsAndServicesCharacteristics.EmptyRef();
	EmptyBatch = Catalogs.ProductsAndServicesBatches.EmptyRef();
	EmptySpecification = Catalogs.Specifications.EmptyRef();
	EmptyCustomerOrder = Documents.CustomerOrder.EmptyRef();
	InventoryReservation = Constants.FunctionalOptionInventoryReservation.Get();
	
	For n = 0 To StructureAdditionalProperties.TableForRegisterRecords.TableInventoryMove.Count() - 1 Do
		
		RowTableInventoryTransfer = StructureAdditionalProperties.TableForRegisterRecords.TableInventoryMove[n];
		
		StructureForSearchTransfer = New Structure;
		StructureForSearchTransfer.Insert("Company", RowTableInventoryTransfer.Company);
		StructureForSearchTransfer.Insert("StructuralUnit", RowTableInventoryTransfer.StructuralUnit);
		StructureForSearchTransfer.Insert("GLAccount", RowTableInventoryTransfer.GLAccount);
		StructureForSearchTransfer.Insert("ProductsAndServices", RowTableInventoryTransfer.ProductsAndServices);
		StructureForSearchTransfer.Insert("Characteristic", RowTableInventoryTransfer.Characteristic);
		StructureForSearchTransfer.Insert("Batch", RowTableInventoryTransfer.Batch);
		
		QuantityRequiredReserveTransfer = RowTableInventoryTransfer.Reserve;
		QuantityReserveShipmentTransfer = RowTableInventoryTransfer.ReserveShipment;
		QuantityRequiredAvailableBalanceTransfer = RowTableInventoryTransfer.Quantity;
		
		If QuantityRequiredReserveTransfer > 0 Then
			
			// Reservation
			
			RowTableInventoryTransfer = StructureAdditionalProperties.TableForRegisterRecords.TableInventoryMove[n];
			
			QuantityRequiredAvailableBalanceTransfer = QuantityRequiredAvailableBalanceTransfer - QuantityRequiredReserveTransfer;
			
			StructureForSearchTransfer.Insert("CustomerOrder", EmptyCustomerOrder);
			
			BalanceRowsArrayDisplacement = TableInventoryBalancesMove.FindRows(StructureForSearchTransfer);
			
			QuantityBalanceDisplacement = 0;
			AmountBalanceMove = 0;
			
			If BalanceRowsArrayDisplacement.Count() > 0 Then
				QuantityBalanceDisplacement = BalanceRowsArrayDisplacement[0].QuantityBalance;
				AmountBalanceMove = BalanceRowsArrayDisplacement[0].AmountBalance;
			EndIf;
			
			If QuantityBalanceDisplacement > 0 AND QuantityBalanceDisplacement > QuantityRequiredReserveTransfer Then
				
				AmountToBeWrittenOffMove = Round(AmountBalanceMove * QuantityRequiredReserveTransfer / QuantityBalanceDisplacement , 2, 1);
				
				BalanceRowsArrayDisplacement[0].QuantityBalance = BalanceRowsArrayDisplacement[0].QuantityBalance - QuantityRequiredReserveTransfer;
				BalanceRowsArrayDisplacement[0].AmountBalance = BalanceRowsArrayDisplacement[0].AmountBalance - AmountToBeWrittenOffMove;
				
			ElsIf QuantityBalanceDisplacement = QuantityRequiredReserveTransfer Then
				
				AmountToBeWrittenOffMove = AmountBalanceMove;
				
				BalanceRowsArrayDisplacement[0].QuantityBalance = 0;
				BalanceRowsArrayDisplacement[0].AmountBalance = 0;
				
			Else
				AmountToBeWrittenOffMove = 0;
			EndIf;
			
			// Expense.
			TableRowExpenseMove = TemporaryTableInventoryTransfer.Add();
			FillPropertyValues(TableRowExpenseMove, RowTableInventoryTransfer);
			
			TableRowExpenseMove.CustomerOrder = Documents.CustomerOrder.EmptyRef();
			
			TableRowExpenseMove.Period = RowTableInventoryTransfer.DocumentDate;
			TableRowExpenseMove.Specification = Undefined;
			TableRowExpenseMove.SpecificationCorr = Undefined;
			TableRowExpenseMove.StructuralUnitCorr = RowTableInventoryTransfer.StructuralUnit;
			TableRowExpenseMove.CorrGLAccount = RowTableInventoryTransfer.GLAccount;
			
			TableRowExpenseMove.Amount = AmountToBeWrittenOffMove;
			TableRowExpenseMove.Quantity = QuantityRequiredReserveTransfer;
			
			// Receipt.
			If Round(AmountToBeWrittenOffMove, 2, 1) <> 0 OR QuantityRequiredReserveTransfer > 0 Then
				
				TableRowReceiptMove = TemporaryTableInventoryTransfer.Add();
				FillPropertyValues(TableRowReceiptMove, RowTableInventoryTransfer);
				
				TableRowReceiptMove.CustomerOrder = RowTableInventoryTransfer.CustomerOrder;
				TableRowReceiptMove.CustomerCorrOrder = Documents.CustomerOrder.EmptyRef();
				TableRowReceiptMove.StructuralUnitCorr = RowTableInventoryTransfer.StructuralUnit;
				TableRowReceiptMove.CorrGLAccount = RowTableInventoryTransfer.GLAccount;
				
				TableRowReceiptMove.RecordType = AccumulationRecordType.Receipt;
				TableRowReceiptMove.Period = RowTableInventoryTransfer.DocumentDate;
				TableRowReceiptMove.Specification = Undefined;
				TableRowReceiptMove.SpecificationCorr = Undefined;
				
				TableRowReceiptMove.Amount = AmountToBeWrittenOffMove;
				TableRowReceiptMove.Quantity = QuantityRequiredReserveTransfer;
				
			EndIf;
			
			If RowTableInventoryTransfer.OrderStatus = Enums.OrderStatuses.Completed Then
				
				// Move
				
				TableInventoryBalancesMove = QueryResult.Unload();
				TableInventoryBalancesMove.Indexes.Add("Company,StructuralUnit,GLAccount,ProductsAndServices,Characteristic,Batch,CustomerOrder");
				
				QuantityRequiredReserveTransfer = RowTableInventoryTransfer.Reserve;
				QuantityRequiredAvailableBalanceTransfer = RowTableInventoryTransfer.Quantity;
				QuantityRequiredReserveShipmentTransfer = RowTableInventoryTransfer.ReserveShipment;
				
				QuantityReserveShipmentTransfer = QuantityRequiredReserveShipmentTransfer - QuantityRequiredReserveTransfer;
				If QuantityReserveShipmentTransfer > 0 Then
					QuantityRequiredAvailableBalanceTransfer = QuantityRequiredAvailableBalanceTransfer - QuantityRequiredReserveTransfer - QuantityReserveShipmentTransfer;
				Else
					QuantityRequiredAvailableBalanceTransfer = QuantityRequiredAvailableBalanceTransfer - QuantityRequiredReserveTransfer;
				EndIf;
				
				StructureForSearchTransfer.Insert("CustomerOrder", EmptyCustomerOrder);
				
				BalanceRowsArrayDisplacement = TableInventoryBalancesMove.FindRows(StructureForSearchTransfer);
				
				QuantityBalanceDisplacement = 0;
				AmountBalanceMove = 0;
				
				If BalanceRowsArrayDisplacement.Count() > 0 Then
					QuantityBalanceDisplacement = BalanceRowsArrayDisplacement[0].QuantityBalance;
					AmountBalanceMove = BalanceRowsArrayDisplacement[0].AmountBalance;
				EndIf;
				
				If QuantityBalanceDisplacement > 0 AND QuantityBalanceDisplacement > QuantityRequiredReserveTransfer Then
					
					AmountToBeWrittenOffMove = Round(AmountBalanceMove * QuantityRequiredReserveTransfer / QuantityBalanceDisplacement , 2, 1);
					
					BalanceRowsArrayDisplacement[0].QuantityBalance = BalanceRowsArrayDisplacement[0].QuantityBalance - QuantityRequiredReserveTransfer;
					BalanceRowsArrayDisplacement[0].AmountBalance = BalanceRowsArrayDisplacement[0].AmountBalance - AmountToBeWrittenOffMove;
					
				ElsIf QuantityBalanceDisplacement = QuantityRequiredReserveTransfer Then
					
					AmountToBeWrittenOffMove = AmountBalanceMove;
					
					BalanceRowsArrayDisplacement[0].QuantityBalance = 0;
					BalanceRowsArrayDisplacement[0].AmountBalance = 0;
					
				Else
					AmountToBeWrittenOffMove = 0;
				EndIf;
				
				// Expense.
				TableRowExpenseMove = TemporaryTableInventoryTransfer.Add();
				FillPropertyValues(TableRowExpenseMove, RowTableInventoryTransfer);
				
				TableRowExpenseMove.Period = RowTableInventoryTransfer.Period;
				TableRowExpenseMove.Specification = Undefined;
				TableRowExpenseMove.SpecificationCorr = Undefined;
				
				TableRowExpenseMove.Amount = AmountToBeWrittenOffMove;
				TableRowExpenseMove.Quantity = QuantityRequiredReserveTransfer;
				
				// Generate postings.
				If Round(AmountToBeWrittenOffMove, 2, 1) <> 0 Then
					RowTableManagerialMove = StructureAdditionalProperties.TableForRegisterRecords.TableManagerial.Add();
					FillPropertyValues(RowTableManagerialMove, RowTableInventoryTransfer);
					RowTableManagerialMove.Amount = AmountToBeWrittenOffMove;
				EndIf;
				
				// Receipt.
				If Round(AmountToBeWrittenOffMove, 2, 1) <> 0 OR QuantityRequiredReserveTransfer > 0 Then
					
					TableRowReceiptMove = TemporaryTableInventoryTransfer.Add();
					FillPropertyValues(TableRowReceiptMove, RowTableInventoryTransfer);
					
					TableRowReceiptMove.Period = RowTableInventoryTransfer.Period;
					TableRowReceiptMove.RecordType = AccumulationRecordType.Receipt;
					
					TableRowReceiptMove.Company = RowTableInventoryTransfer.Company;
					TableRowReceiptMove.StructuralUnit = RowTableInventoryTransfer.StructuralUnitCorr;
					TableRowReceiptMove.GLAccount = RowTableInventoryTransfer.CorrGLAccount;
					TableRowReceiptMove.ProductsAndServices = RowTableInventoryTransfer.ProductsAndServicesCorr;
					TableRowReceiptMove.Characteristic = RowTableInventoryTransfer.CharacteristicCorr;
					TableRowReceiptMove.Batch = RowTableInventoryTransfer.BatchCorr;
					TableRowReceiptMove.Specification = Undefined;
					
					TableRowReceiptMove.CustomerOrder = RowTableInventoryTransfer.CustomerCorrOrder;
					
					TableRowReceiptMove.StructuralUnitCorr = RowTableInventoryTransfer.StructuralUnit;
					TableRowReceiptMove.CorrGLAccount = RowTableInventoryTransfer.GLAccount;
					TableRowReceiptMove.ProductsAndServicesCorr = RowTableInventoryTransfer.ProductsAndServices;
					TableRowReceiptMove.CharacteristicCorr = RowTableInventoryTransfer.Characteristic;
					TableRowReceiptMove.BatchCorr = RowTableInventoryTransfer.Batch;
					TableRowReceiptMove.SpecificationCorr = Undefined;
					
					TableRowReceiptMove.CustomerCorrOrder = RowTableInventoryTransfer.CustomerOrder;
					
					TableRowReceiptMove.Amount = AmountToBeWrittenOffMove;
					
					TableRowReceiptMove.Quantity = QuantityRequiredReserveTransfer;
					
					TableRowReceiptMove.GLAccount = RowTableInventoryTransfer.CorrGLAccount;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
		If QuantityReserveShipmentTransfer > 0 
			AND RowTableInventoryTransfer.OrderStatus = Enums.OrderStatuses.Completed Then
			
			// Transfer of reserved materials by other documents.
			
			QuantityRequiredReserveTransfer = RowTableInventoryTransfer.Reserve;
			QuantityRequiredAvailableBalanceTransfer = RowTableInventoryTransfer.Quantity;
			QuantityRequiredReserveShipmentTransfer = RowTableInventoryTransfer.ReserveShipment;
			
			QuantityReserveShipmentTransfer = QuantityRequiredReserveShipmentTransfer - QuantityRequiredReserveTransfer;
			If QuantityReserveShipmentTransfer > 0 Then
				QuantityRequiredAvailableBalanceTransfer = QuantityRequiredAvailableBalanceTransfer - QuantityRequiredReserveTransfer - QuantityReserveShipmentTransfer;
			Else
				QuantityRequiredAvailableBalanceTransfer = QuantityRequiredAvailableBalanceTransfer - QuantityRequiredReserveTransfer;
			EndIf;
			
			StructureForSearchTransfer.Insert("CustomerOrder", DocumentRefCustomerOrder);
			
			ArrayOfBalanceRowsShipmentTransfer = TableInventoryBalancesMove.FindRows(StructureForSearchTransfer);
			
			QuantityBalanceShipmentDisplacement = 0;
			SumBalanceShipmentMove = 0;
			
			If ArrayOfBalanceRowsShipmentTransfer.Count() > 0 Then
				QuantityBalanceShipmentDisplacement = ArrayOfBalanceRowsShipmentTransfer[0].QuantityBalance;
				SumBalanceShipmentMove = ArrayOfBalanceRowsShipmentTransfer[0].AmountBalance;
			EndIf;
			
			If QuantityBalanceShipmentDisplacement > 0 AND QuantityBalanceShipmentDisplacement > QuantityReserveShipmentTransfer Then
				
				AmountToBeWrittenOffShipmentMove = Round(SumBalanceShipmentMove * QuantityReserveShipmentTransfer / QuantityBalanceShipmentDisplacement , 2, 1);
				
				ArrayOfBalanceRowsShipmentTransfer[0].QuantityBalance = ArrayOfBalanceRowsShipmentTransfer[0].QuantityBalance - QuantityReserveShipmentTransfer;
				ArrayOfBalanceRowsShipmentTransfer[0].AmountBalance = ArrayOfBalanceRowsShipmentTransfer[0].AmountBalance - AmountToBeWrittenOffShipmentMove;
				
			ElsIf QuantityBalanceShipmentDisplacement = QuantityReserveShipmentTransfer Then
				
				AmountToBeWrittenOffShipmentMove = SumBalanceShipmentMove;
				
				ArrayOfBalanceRowsShipmentTransfer[0].QuantityBalance = 0;
				ArrayOfBalanceRowsShipmentTransfer[0].AmountBalance = 0;
				
			Else
				AmountToBeWrittenOffShipmentMove = 0;
			EndIf;
			
			// Expense.
			TableRowExpenseMove = TemporaryTableInventoryTransfer.Add();
			FillPropertyValues(TableRowExpenseMove, RowTableInventoryTransfer);
			
			TableRowExpenseMove.Period = RowTableInventoryTransfer.Period;
			TableRowExpenseMove.Specification = Undefined;
			TableRowExpenseMove.SpecificationCorr = Undefined;
			
			TableRowExpenseMove.Amount = AmountToBeWrittenOffShipmentMove;
			TableRowExpenseMove.Quantity = QuantityReserveShipmentTransfer;
			
			// Generate postings.
			If Round(AmountToBeWrittenOffShipmentMove, 2, 1) <> 0 Then
				RowTableManagerialMove = StructureAdditionalProperties.TableForRegisterRecords.TableManagerial.Add();
				FillPropertyValues(RowTableManagerialMove, RowTableInventoryTransfer);
				RowTableManagerialMove.Amount = AmountToBeWrittenOffShipmentMove;
			EndIf;
			
			// Receipt.
			If Round(AmountToBeWrittenOffShipmentMove, 2, 1) <> 0 OR QuantityReserveShipmentTransfer > 0 Then
				
				TableRowReceiptMove = TemporaryTableInventoryTransfer.Add();
				FillPropertyValues(TableRowReceiptMove, RowTableInventoryTransfer);
				
				TableRowReceiptMove.Period = RowTableInventoryTransfer.Period;
				TableRowReceiptMove.RecordType = AccumulationRecordType.Receipt;
				
				TableRowReceiptMove.Company = RowTableInventoryTransfer.Company;
				TableRowReceiptMove.StructuralUnit = RowTableInventoryTransfer.StructuralUnitCorr;
				TableRowReceiptMove.GLAccount = RowTableInventoryTransfer.CorrGLAccount;
				TableRowReceiptMove.ProductsAndServices = RowTableInventoryTransfer.ProductsAndServicesCorr;
				TableRowReceiptMove.Characteristic = RowTableInventoryTransfer.CharacteristicCorr;
				TableRowReceiptMove.Batch = RowTableInventoryTransfer.BatchCorr;
				TableRowReceiptMove.Specification = Undefined;
				
				TableRowReceiptMove.CustomerOrder = RowTableInventoryTransfer.CustomerCorrOrder;
				
				TableRowReceiptMove.StructuralUnitCorr = RowTableInventoryTransfer.StructuralUnit;
				TableRowReceiptMove.CorrGLAccount = RowTableInventoryTransfer.GLAccount;
				TableRowReceiptMove.ProductsAndServicesCorr = RowTableInventoryTransfer.ProductsAndServices;
				TableRowReceiptMove.CharacteristicCorr = RowTableInventoryTransfer.Characteristic;
				TableRowReceiptMove.BatchCorr = RowTableInventoryTransfer.Batch;
				TableRowReceiptMove.SpecificationCorr = Undefined;
				
				TableRowReceiptMove.CustomerCorrOrder = RowTableInventoryTransfer.CustomerOrder;
				
				TableRowReceiptMove.Amount = AmountToBeWrittenOffShipmentMove;
				
				TableRowReceiptMove.Quantity = QuantityReserveShipmentTransfer;
				
				TableRowReceiptMove.GLAccount = RowTableInventoryTransfer.CorrGLAccount;
				
			EndIf;
			
		EndIf;
		
		If QuantityRequiredAvailableBalanceTransfer > 0
			AND RowTableInventoryTransfer.OrderStatus = Enums.OrderStatuses.Completed Then
			
			StructureForSearchTransfer.Insert("CustomerOrder", EmptyCustomerOrder);
			
			BalanceRowsArrayDisplacement = TableInventoryBalancesMove.FindRows(StructureForSearchTransfer);
			
			QuantityBalanceDisplacement = 0;
			AmountBalanceMove = 0;
			
			If BalanceRowsArrayDisplacement.Count() > 0 Then
				QuantityBalanceDisplacement = BalanceRowsArrayDisplacement[0].QuantityBalance;
				AmountBalanceMove = BalanceRowsArrayDisplacement[0].AmountBalance;
			EndIf;
			
			If QuantityBalanceDisplacement > 0 AND QuantityBalanceDisplacement > QuantityRequiredAvailableBalanceTransfer Then
				
				AmountToBeWrittenOffMove = Round(AmountBalanceMove * QuantityRequiredAvailableBalanceTransfer / QuantityBalanceDisplacement , 2, 1);
				
				BalanceRowsArrayDisplacement[0].QuantityBalance = BalanceRowsArrayDisplacement[0].QuantityBalance - QuantityRequiredAvailableBalanceTransfer;
				BalanceRowsArrayDisplacement[0].AmountBalance = BalanceRowsArrayDisplacement[0].AmountBalance - AmountToBeWrittenOffMove;
				
			ElsIf QuantityBalanceDisplacement = QuantityRequiredAvailableBalanceTransfer Then
				
				AmountToBeWrittenOffMove = AmountBalanceMove;
				
				BalanceRowsArrayDisplacement[0].QuantityBalance = 0;
				BalanceRowsArrayDisplacement[0].AmountBalance = 0;
				
			Else
				AmountToBeWrittenOffMove = 0;
			EndIf;
			
			// Expense.
			TableRowExpenseMove = TemporaryTableInventoryTransfer.Add();
			FillPropertyValues(TableRowExpenseMove, RowTableInventoryTransfer);
			
			TableRowExpenseMove.Amount = AmountToBeWrittenOffMove;
			TableRowExpenseMove.Quantity = QuantityRequiredAvailableBalanceTransfer;
			TableRowExpenseMove.CustomerOrder = EmptyCustomerOrder;
			TableRowExpenseMove.Specification = Undefined;
			TableRowExpenseMove.SpecificationCorr = Undefined;
			
			If Not InventoryReservation Then
				TableRowExpenseMove.CustomerCorrOrder = EmptyCustomerOrder;
			EndIf;
			
			// Generate postings.
			If Round(AmountToBeWrittenOffMove, 2, 1) <> 0 Then
				RowTableManagerialMove = StructureAdditionalProperties.TableForRegisterRecords.TableManagerial.Add();
				FillPropertyValues(RowTableManagerialMove, RowTableInventoryTransfer);
				RowTableManagerialMove.Amount = AmountToBeWrittenOffMove;
			EndIf;
			
			// Receipt.
			If Round(AmountToBeWrittenOffMove, 2, 1) <> 0 OR QuantityRequiredAvailableBalanceTransfer > 0 Then
				
				TableRowReceiptMove = TemporaryTableInventoryTransfer.Add();
				FillPropertyValues(TableRowReceiptMove, RowTableInventoryTransfer);
				
				TableRowReceiptMove.RecordType = AccumulationRecordType.Receipt;
				
				TableRowReceiptMove.Company = RowTableInventoryTransfer.Company;
				TableRowReceiptMove.StructuralUnit = RowTableInventoryTransfer.StructuralUnitCorr;
				TableRowReceiptMove.GLAccount = RowTableInventoryTransfer.CorrGLAccount;
				TableRowReceiptMove.ProductsAndServices = RowTableInventoryTransfer.ProductsAndServicesCorr;
				TableRowReceiptMove.Characteristic = RowTableInventoryTransfer.CharacteristicCorr;
				TableRowReceiptMove.Batch = RowTableInventoryTransfer.BatchCorr;
				TableRowReceiptMove.Specification = Undefined;
				
				TableRowReceiptMove.StructuralUnitCorr = RowTableInventoryTransfer.StructuralUnit;
				TableRowReceiptMove.CorrGLAccount = RowTableInventoryTransfer.GLAccount;
				TableRowReceiptMove.ProductsAndServicesCorr = RowTableInventoryTransfer.ProductsAndServices;
				TableRowReceiptMove.CharacteristicCorr = RowTableInventoryTransfer.Characteristic;
				TableRowReceiptMove.BatchCorr = RowTableInventoryTransfer.Batch;
				TableRowReceiptMove.SpecificationCorr = Undefined;
				
				TableRowReceiptMove.CustomerCorrOrder = EmptyCustomerOrder;
				
				TableRowReceiptMove.Amount = AmountToBeWrittenOffMove;
				
				TableRowReceiptMove.Quantity = QuantityRequiredAvailableBalanceTransfer;
				
				TableRowReceiptMove.GLAccount = RowTableInventoryTransfer.CorrGLAccount;
				
				If InventoryReservation Then
					TableRowReceiptMove.CustomerOrder = DocumentRefCustomerOrder;
				Else
					TableRowReceiptMove.CustomerOrder = EmptyCustomerOrder;
				EndIf;
				
			EndIf;
				
		EndIf;
			
	EndDo;
	
	StructureAdditionalProperties.TableForRegisterRecords.TableInventoryMove = TemporaryTableInventoryTransfer;
	
	For n = 0 To StructureAdditionalProperties.TableForRegisterRecords.TableInventoryMove.Count() - 1 Do
		
		RowTableInventory = StructureAdditionalProperties.TableForRegisterRecords.TableInventoryMove[n];
		
		TableRowReceipt = StructureAdditionalProperties.TableForRegisterRecords.TableInventory.Add();
		FillPropertyValues(TableRowReceipt, RowTableInventory);

	EndDo;
	
	// End AutomaticWriteOff
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text = 
	"SELECT
	|	MIN(TableInventory.LineNumber) AS LineNumber,
	|	TableInventory.Finish AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	TableInventory.Company AS Company,
	|	TableInventory.PlanningPeriod AS PlanningPeriod,
	|	TableInventory.InventoryStructuralUnit AS InventoryStructuralUnit,
	|	TableInventory.StructuralUnit AS StructuralUnit,
	|	TableInventory.StructuralUnit AS StructuralUnitCorr,
	|	TableInventory.GLAccount AS GLAccount,
	|	TableInventory.InventoryGLAccount AS InventoryGLAccount,
	|	TableInventory.CorrGLAccount AS CorrGLAccount,
	|	TableInventory.ProductsAndServices AS ProductsAndServices,
	|	TableInventory.ProductsAndServicesCorr AS ProductsAndServicesCorr,
	|	TableInventory.Characteristic AS Characteristic,
	|	TableInventory.CharacteristicCorr AS CharacteristicCorr,
	|	TableInventory.Batch AS Batch,
	|	TableInventory.BatchCorr AS BatchCorr,
	|	TableInventory.Specification AS Specification,
	|	TableInventory.SpecificationCorr AS SpecificationCorr,
	|	TableInventory.CustomerOrder AS CustomerOrder,
	|	TableInventory.CustomerOrder AS CustomerCorrOrder,
	|	TableInventory.AccountDr AS AccountDr,
	|	TableInventory.AccountCr AS AccountCr,
	|	TableInventory.ContentOfAccountingRecord AS Content,
	|	TableInventory.ContentOfAccountingRecord AS ContentOfAccountingRecord,
	|	FALSE AS ProductionExpenses,
	|	SUM(TableInventory.Quantity) AS Quantity,
	|	SUM(TableInventory.Reserve) AS Reserve,
	|	SUM(TableInventory.ReserveShipment) AS ReserveShipment,
	|	0 AS Amount
	|FROM
	|	TemporaryTableConsumables AS TableInventory
	|WHERE
	|	TableInventory.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|
	|GROUP BY
	|	TableInventory.Finish,
	|	TableInventory.Company,
	|	TableInventory.PlanningPeriod,
	|	TableInventory.StructuralUnit,
	|	TableInventory.GLAccount,
	|	TableInventory.InventoryGLAccount,
	|	TableInventory.CorrGLAccount,
	|	TableInventory.ProductsAndServices,
	|	TableInventory.ProductsAndServicesCorr,
	|	TableInventory.Characteristic,
	|	TableInventory.CharacteristicCorr,
	|	TableInventory.Batch,
	|	TableInventory.BatchCorr,
	|	TableInventory.Specification,
	|	TableInventory.SpecificationCorr,
	|	TableInventory.CustomerOrder,
	|	TableInventory.AccountDr,
	|	TableInventory.AccountCr,
	|	TableInventory.ContentOfAccountingRecord,
	|	TableInventory.InventoryStructuralUnit,
	|	TableInventory.StructuralUnit,
	|	TableInventory.CustomerOrder,
	|	TableInventory.ContentOfAccountingRecord
	|
	|ORDER BY
	|	LineNumber";
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableInventoryInventory", Query.Execute().Unload());
	
	For n = 0 To StructureAdditionalProperties.TableForRegisterRecords.TableInventoryInventory.Count() - 1 Do
		
		RowTableInventory = StructureAdditionalProperties.TableForRegisterRecords.TableInventoryInventory[n];
		
		StructureForSearch = New Structure;
		StructureForSearch.Insert("Company", RowTableInventory.Company);
		StructureForSearch.Insert("StructuralUnit", RowTableInventory.InventoryStructuralUnit);
		StructureForSearch.Insert("GLAccount", RowTableInventory.InventoryGLAccount);
		StructureForSearch.Insert("ProductsAndServices", RowTableInventory.ProductsAndServices);
		StructureForSearch.Insert("Characteristic", RowTableInventory.Characteristic);
		StructureForSearch.Insert("Batch", RowTableInventory.Batch);
		
		QuantityRequiredReserve = RowTableInventory.Reserve;
		QuantityRequiredReserveShipment = RowTableInventory.ReserveShipment;
		QuantityRequiredAvailableBalance = RowTableInventory.Quantity;
		
		TableInventoryBalancesMove = QueryResult.Unload();
		TableInventoryBalancesMove.Indexes.Add("Company,StructuralUnit,GLAccount,ProductsAndServices,Characteristic,Batch,CustomerOrder");
		
		If QuantityRequiredReserve > 0 Then
			
			QuantityRequiredAvailableBalance = QuantityRequiredAvailableBalance - QuantityRequiredReserve;
			
			StructureForSearch.Insert("CustomerOrder", EmptyCustomerOrder);
			
			BalanceRowsArray = TableInventoryBalancesMove.FindRows(StructureForSearch);
			
			QuantityBalance = 0;
			AmountBalance = 0;
			
			If BalanceRowsArray.Count() > 0 Then
				QuantityBalance = BalanceRowsArray[0].QuantityBalance;
				AmountBalance = BalanceRowsArray[0].AmountBalance;
			EndIf;
			
			If QuantityBalance > 0 AND QuantityBalance > QuantityRequiredReserve Then
				
				AmountToBeWrittenOff = Round(AmountBalance * QuantityRequiredReserve / QuantityBalance , 2, 1);
				
				BalanceRowsArray[0].QuantityBalance = BalanceRowsArray[0].QuantityBalance - QuantityRequiredReserve;
				BalanceRowsArray[0].AmountBalance = BalanceRowsArray[0].AmountBalance - AmountToBeWrittenOff;
				
			ElsIf QuantityBalance = QuantityRequiredReserve Then
				
				AmountToBeWrittenOff = AmountBalance;
				
				BalanceRowsArray[0].QuantityBalance = 0;
				BalanceRowsArray[0].AmountBalance = 0;
				
			Else
				AmountToBeWrittenOff = 0;
			EndIf;
			
			// Write inventory off the warehouse (production department).
			TableRowExpense = StructureAdditionalProperties.TableForRegisterRecords.TableInventory.Add();
			FillPropertyValues(TableRowExpense, RowTableInventory);
			
			TableRowExpense.ProductionExpenses = True;
			TableRowExpense.Amount = AmountToBeWrittenOff;
			TableRowExpense.Quantity = QuantityRequiredReserve;
			
			// Assign written off stocks to either inventory cost in the warehouse, or to WIP costs.
			If Round(AmountToBeWrittenOff, 2, 1) <> 0 Then
				
				TableRowReceipt = StructureAdditionalProperties.TableForRegisterRecords.TableInventory.Add();
				FillPropertyValues(TableRowReceipt, RowTableInventory);
				
				TableRowReceipt.RecordType = AccumulationRecordType.Receipt;
				
				TableRowReceipt.StructuralUnit = RowTableInventory.StructuralUnitCorr;
				TableRowReceipt.GLAccount = RowTableInventory.CorrGLAccount;
				TableRowReceipt.ProductsAndServices = RowTableInventory.ProductsAndServicesCorr;
				TableRowReceipt.Characteristic = RowTableInventory.CharacteristicCorr;
				TableRowReceipt.Batch = RowTableInventory.BatchCorr;
				TableRowReceipt.Specification = RowTableInventory.SpecificationCorr;
				TableRowReceipt.CustomerOrder = DocumentRefCustomerOrder;
				
				TableRowReceipt.StructuralUnitCorr = RowTableInventory.StructuralUnit;
				TableRowReceipt.CorrGLAccount = RowTableInventory.GLAccount;
				TableRowReceipt.ProductsAndServicesCorr = RowTableInventory.ProductsAndServices;
				TableRowReceipt.CharacteristicCorr = RowTableInventory.Characteristic;
				TableRowReceipt.BatchCorr = RowTableInventory.Batch;
				TableRowReceipt.SpecificationCorr = RowTableInventory.Specification;
				TableRowReceipt.CustomerCorrOrder = DocumentRefCustomerOrder;
				
				TableRowReceipt.Amount = AmountToBeWrittenOff;
				TableRowReceipt.Quantity = 0;
				
				TableRowReceipt.GLAccount = RowTableInventory.CorrGLAccount;
				
				// Generate postings.
				If Round(AmountToBeWrittenOff, 2, 1) <> 0 Then
					RowTableManagerial = StructureAdditionalProperties.TableForRegisterRecords.TableManagerial.Add();
					FillPropertyValues(RowTableManagerial, TableRowReceipt);
				EndIf;
				
			EndIf;
			
		EndIf;
		
		// Write off the materials reserved by other documents.
		QuantityShipmentReserve = QuantityRequiredReserveShipment - QuantityRequiredReserve;
		If QuantityShipmentReserve > 0 Then
			
			QuantityRequiredAvailableBalance = QuantityRequiredAvailableBalance - QuantityShipmentReserve;
			
			StructureForSearch.Insert("CustomerOrder", DocumentRefCustomerOrder);
			
			RowsArrayBalancesShipment = TableInventoryBalancesMove.FindRows(StructureForSearch);
			
			CountShipmentRemain = 0;
			SumShipmentBalance = 0;
			
			If RowsArrayBalancesShipment.Count() > 0 Then
				CountShipmentRemain = RowsArrayBalancesShipment[0].QuantityBalance;
				SumShipmentBalance = RowsArrayBalancesShipment[0].AmountBalance;
			EndIf;
			
			If CountShipmentRemain > 0 AND CountShipmentRemain > QuantityShipmentReserve Then
				
				AmountShipmentToBeWrittenOff = Round(SumShipmentBalance * QuantityShipmentReserve / CountShipmentRemain , 2, 1);
				
				RowsArrayBalancesShipment[0].QuantityBalance = RowsArrayBalancesShipment[0].QuantityBalance - QuantityShipmentReserve;
				RowsArrayBalancesShipment[0].AmountBalance = RowsArrayBalancesShipment[0].AmountBalance - AmountShipmentToBeWrittenOff;
				
			ElsIf CountShipmentRemain = QuantityShipmentReserve Then
				
				AmountShipmentToBeWrittenOff = SumShipmentBalance;
				
				RowsArrayBalancesShipment[0].QuantityBalance = 0;
				RowsArrayBalancesShipment[0].AmountBalance = 0;
				
			Else
				AmountShipmentToBeWrittenOff = 0;
			EndIf;
			
			// Write inventory off the warehouse (production department).
			TableRowExpense = StructureAdditionalProperties.TableForRegisterRecords.TableInventory.Add();
			FillPropertyValues(TableRowExpense, RowTableInventory);
			
			TableRowExpense.ProductionExpenses = True;
			TableRowExpense.Amount = AmountShipmentToBeWrittenOff;
			TableRowExpense.Quantity = QuantityShipmentReserve;
			
			// Assign written off stocks to either inventory cost in the warehouse, or to WIP costs.
			If Round(AmountShipmentToBeWrittenOff, 2, 1) <> 0 Then
				
				TableRowReceipt = StructureAdditionalProperties.TableForRegisterRecords.TableInventory.Add();
				FillPropertyValues(TableRowReceipt, RowTableInventory);
				
				TableRowReceipt.RecordType = AccumulationRecordType.Receipt;
				
				TableRowReceipt.StructuralUnit = RowTableInventory.StructuralUnitCorr;
				TableRowReceipt.GLAccount = RowTableInventory.CorrGLAccount;
				TableRowReceipt.ProductsAndServices = RowTableInventory.ProductsAndServicesCorr;
				TableRowReceipt.Characteristic = RowTableInventory.CharacteristicCorr;
				TableRowReceipt.Batch = RowTableInventory.BatchCorr;
				TableRowReceipt.Specification = RowTableInventory.SpecificationCorr;
				TableRowReceipt.CustomerOrder = DocumentRefCustomerOrder;
				
				TableRowReceipt.StructuralUnitCorr = RowTableInventory.StructuralUnit;
				TableRowReceipt.CorrGLAccount = RowTableInventory.GLAccount;
				TableRowReceipt.ProductsAndServicesCorr = RowTableInventory.ProductsAndServices;
				TableRowReceipt.CharacteristicCorr = RowTableInventory.Characteristic;
				TableRowReceipt.BatchCorr = RowTableInventory.Batch;
				TableRowReceipt.SpecificationCorr = RowTableInventory.Specification;
				TableRowReceipt.CustomerCorrOrder = DocumentRefCustomerOrder;
				
				TableRowReceipt.Amount = AmountShipmentToBeWrittenOff;
				TableRowReceipt.Quantity = 0;
				
				TableRowReceipt.GLAccount = RowTableInventory.CorrGLAccount;
				
				// Generate postings.
				If Round(AmountShipmentToBeWrittenOff, 2, 1) <> 0 Then
					RowTableManagerial = StructureAdditionalProperties.TableForRegisterRecords.TableManagerial.Add();
					FillPropertyValues(RowTableManagerial, TableRowReceipt);
				EndIf;
				
			EndIf;
			
		EndIf;
		
		If QuantityRequiredAvailableBalance > 0 Then
			
			StructureForSearch.Insert("CustomerOrder", EmptyCustomerOrder);
			
			BalanceRowsArray = TableInventoryBalancesMove.FindRows(StructureForSearch);
			
			QuantityBalance = 0;
			AmountBalance = 0;
			
			If BalanceRowsArray.Count() > 0 Then
				QuantityBalance = BalanceRowsArray[0].QuantityBalance;
				AmountBalance = BalanceRowsArray[0].AmountBalance;
			EndIf;
			
			If QuantityBalance > 0 AND QuantityBalance > QuantityRequiredAvailableBalance Then
				
				AmountToBeWrittenOff = Round(AmountBalance * QuantityRequiredAvailableBalance / QuantityBalance , 2, 1);
				
				BalanceRowsArray[0].QuantityBalance = BalanceRowsArray[0].QuantityBalance - QuantityRequiredAvailableBalance;
				BalanceRowsArray[0].AmountBalance = BalanceRowsArray[0].AmountBalance - AmountToBeWrittenOff;
				
			ElsIf QuantityBalance = QuantityRequiredAvailableBalance Then
				
				AmountToBeWrittenOff = AmountBalance;
				
				BalanceRowsArray[0].QuantityBalance = 0;
				BalanceRowsArray[0].AmountBalance = 0;
				
			Else
				AmountToBeWrittenOff = 0;
			EndIf;
			
			// Expense.
			TableRowExpense = StructureAdditionalProperties.TableForRegisterRecords.TableInventory.Add();
			FillPropertyValues(TableRowExpense, RowTableInventory);
			
			TableRowExpense.Amount = AmountToBeWrittenOff;
			TableRowExpense.Quantity = QuantityRequiredAvailableBalance;
			TableRowExpense.ProductionExpenses = True;
			
			If InventoryReservation Then
				TableRowExpense.CustomerOrder = DocumentRefCustomerOrder;
			Else
				TableRowExpense.CustomerOrder = EmptyCustomerOrder;
				TableRowExpense.CustomerCorrOrder = EmptyCustomerOrder;
			EndIf;
			
			// Receipt
			If Round(AmountToBeWrittenOff, 2, 1) <> 0 Then
				
				TableRowReceipt = StructureAdditionalProperties.TableForRegisterRecords.TableInventory.Add();
				FillPropertyValues(TableRowReceipt, RowTableInventory);
				
				TableRowReceipt.RecordType = AccumulationRecordType.Receipt;
				
				TableRowReceipt.StructuralUnit = RowTableInventory.StructuralUnitCorr;
				TableRowReceipt.GLAccount = RowTableInventory.CorrGLAccount;
				TableRowReceipt.ProductsAndServices = RowTableInventory.ProductsAndServicesCorr;
				TableRowReceipt.Characteristic = RowTableInventory.CharacteristicCorr;
				TableRowReceipt.Batch = RowTableInventory.BatchCorr;
				TableRowReceipt.Specification = RowTableInventory.SpecificationCorr;
				
				TableRowReceipt.StructuralUnitCorr = RowTableInventory.StructuralUnit;
				TableRowReceipt.CorrGLAccount = RowTableInventory.GLAccount;
				TableRowReceipt.ProductsAndServicesCorr = RowTableInventory.ProductsAndServices;
				TableRowReceipt.CharacteristicCorr = RowTableInventory.Characteristic;
				TableRowReceipt.BatchCorr = RowTableInventory.Batch;
				TableRowReceipt.SpecificationCorr = RowTableInventory.Specification;
				
				TableRowReceipt.Amount = AmountToBeWrittenOff;
				TableRowReceipt.Quantity = 0;
				
				TableRowReceipt.GLAccount = RowTableInventory.CorrGLAccount;
				
				If InventoryReservation Then
					TableRowReceipt.CustomerOrder = DocumentRefCustomerOrder;
					TableRowReceipt.CustomerCorrOrder = DocumentRefCustomerOrder;
				Else
					TableRowReceipt.CustomerOrder = EmptyCustomerOrder;
					TableRowReceipt.CustomerCorrOrder = EmptyCustomerOrder;
				EndIf;
				
				// Generate postings.
				If Round(AmountToBeWrittenOff, 2, 1) <> 0 Then
					RowTableManagerial = StructureAdditionalProperties.TableForRegisterRecords.TableManagerial.Add();
					FillPropertyValues(RowTableManagerial, TableRowReceipt);
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	StructureAdditionalProperties.TableForRegisterRecords.Delete("TableInventoryInventory");
	
EndProcedure // GenerateTableInventoryMaterials()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableInventoryPerformers(DocumentRefCustomerOrder, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	MIN(TableInventoryPerformers.LineNumber) AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TableInventoryPerformers.PlanningPeriod AS PlanningPeriod,
	|	TableInventoryPerformers.Period AS Period,
	|	TableInventoryPerformers.Company AS Company,
	|	TableInventoryPerformers.StructuralUnit AS StructuralUnit,
	|	TableInventoryPerformers.StructuralUnit AS StructuralUnitCorr,
	|	TableInventoryPerformers.InventoryGLAccount AS GLAccount,
	|	TableInventoryPerformers.CorrespondentAccountAccountingInventory AS CorrGLAccount,
	|	TableInventoryPerformers.ProductsAndServicesCorr AS ProductsAndServicesCorr,
	|	TableInventoryPerformers.CharacteristicCorr AS CharacteristicCorr,
	|	TableInventoryPerformers.BatchCorr AS BatchCorr,
	|	TableInventoryPerformers.SpecificationCorr AS SpecificationCorr,
	|	VALUE(Catalog.Specifications.EmptyRef) AS Specification,
	|	VALUE(Catalog.ProductsAndServices.EmptyRef) AS ProductsAndServices,
	|	VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef) AS Characteristic,
	|	VALUE(Catalog.ProductsAndServicesBatches.EmptyRef) AS Batch,
	|	CASE
	|		WHEN Constants.FunctionalOptionInventoryReservation
	|			THEN TableInventoryPerformers.CustomerOrder
	|		ELSE VALUE(Document.CustomerOrder.EmptyRef)
	|	END AS CustomerOrder,
	|	CASE
	|		WHEN Constants.FunctionalOptionInventoryReservation
	|			THEN TableInventoryPerformers.CustomerOrder
	|		ELSE VALUE(Document.CustomerOrder.EmptyRef)
	|	END AS CustomerCorrOrder,
	|	SUM(TableInventoryPerformers.Amount) AS Amount,
	|	TRUE AS FixedCost,
	|	FALSE AS ProductionExpenses,
	|	&Payroll AS ContentOfAccountingRecord
	|FROM
	|	TemporaryTableArtist AS TableInventoryPerformers,
	|	Constants AS Constants
	|
	|GROUP BY
	|	TableInventoryPerformers.Period,
	|	TableInventoryPerformers.PlanningPeriod,
	|	TableInventoryPerformers.InventoryGLAccount,
	|	TableInventoryPerformers.CorrespondentAccountAccountingInventory,
	|	TableInventoryPerformers.ProductsAndServicesCorr,
	|	TableInventoryPerformers.CharacteristicCorr,
	|	TableInventoryPerformers.BatchCorr,
	|	TableInventoryPerformers.SpecificationCorr,
	|	TableInventoryPerformers.Company,
	|	TableInventoryPerformers.StructuralUnit,
	|	TableInventoryPerformers.CustomerOrder,
	|	Constants.FunctionalOptionInventoryReservation,
	|	TableInventoryPerformers.StructuralUnit
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableInventoryPerformers.LineNumber AS LineNumber,
	|	TableInventoryPerformers.Period AS Period,
	|	TableInventoryPerformers.Company AS Company,
	|	VALUE(Catalog.PlanningPeriods.Actual) AS PlanningPeriod,
	|	TableInventoryPerformers.InventoryGLAccount AS AccountDr,
	|	CASE
	|		WHEN TableInventoryPerformers.InventoryGLAccount.Currency
	|			THEN TableInventoryPerformers.Currency
	|		ELSE UNDEFINED
	|	END AS CurrencyDr,
	|	CASE
	|		WHEN TableInventoryPerformers.InventoryGLAccount.Currency
	|			THEN TableInventoryPerformers.AmountCur
	|		ELSE 0
	|	END AS AmountCurDr,
	|	TableInventoryPerformers.GLAccount AS AccountCr,
	|	CASE
	|		WHEN TableInventoryPerformers.GLAccount.Currency
	|			THEN TableInventoryPerformers.Currency
	|		ELSE UNDEFINED
	|	END AS CurrencyCr,
	|	CASE
	|		WHEN TableInventoryPerformers.GLAccount.Currency
	|			THEN TableInventoryPerformers.AmountCur
	|		ELSE 0
	|	END AS AmountCurCr,
	|	TableInventoryPerformers.Amount AS Amount,
	|	&Payroll AS Content
	|FROM
	|	TemporaryTableArtist AS TableInventoryPerformers
	|WHERE
	|	TableInventoryPerformers.Amount > 0
	|
	|UNION ALL
	|
	|SELECT
	|	TableInventoryPerformers.LineNumber,
	|	TableInventoryPerformers.Period,
	|	TableInventoryPerformers.Company,
	|	VALUE(Catalog.PlanningPeriods.Actual),
	|	TableInventoryPerformers.CorrespondentAccountAccountingInventory,
	|	CASE
	|		WHEN TableInventoryPerformers.CorrespondentAccountAccountingInventory.Currency
	|			THEN TableInventoryPerformers.Currency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN TableInventoryPerformers.CorrespondentAccountAccountingInventory.Currency
	|			THEN TableInventoryPerformers.AmountCur
	|		ELSE 0
	|	END,
	|	TableInventoryPerformers.InventoryGLAccount,
	|	CASE
	|		WHEN TableInventoryPerformers.InventoryGLAccount.Currency
	|			THEN TableInventoryPerformers.Currency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN TableInventoryPerformers.InventoryGLAccount.Currency
	|			THEN TableInventoryPerformers.AmountCur
	|		ELSE 0
	|	END,
	|	TableInventoryPerformers.Amount,
	|	&SalaryDistribution
	|FROM
	|	TemporaryTableArtist AS TableInventoryPerformers
	|WHERE
	|	TableInventoryPerformers.Amount > 0";
	
	Query.SetParameter("Payroll", NStr("en='Payroll';ru='Начисление зарплаты';vi='Trả lương'"));	
	Query.SetParameter("SalaryDistribution", 	NStr("en='Attribution of expenses for products';ru='Отнесение затрат на продукцию';vi='Ghi nhận chi phí cho sản phẩm'"));	
	
	ResultsArray = Query.ExecuteBatch();
	
	TableInventoryPerformers = ResultsArray[0].Unload();
	TableManagerial = ResultsArray[1].Unload();
	
	For Each TableRow IN TableManagerial Do
		RowTableManagerial = StructureAdditionalProperties.TableForRegisterRecords.TableManagerial.Add();
		FillPropertyValues(RowTableManagerial, TableRow);	
	EndDo; 
	
	IsEmptyStructuralUnit = Catalogs.StructuralUnits.EmptyRef();
	EmptyAccount = ChartsOfAccounts.Managerial.EmptyRef();
	EmptyProductsAndServices = Catalogs.ProductsAndServices.EmptyRef();
	EmptyCharacteristic = Catalogs.ProductsAndServicesCharacteristics.EmptyRef();
	EmptyBatch = Catalogs.ProductsAndServicesBatches.EmptyRef();
    EmptySpecification = Catalogs.Specifications.EmptyRef();
    EmptyCustomerOrder = Documents.CustomerOrder.EmptyRef();
	
	For n = 0 To TableInventoryPerformers.Count() - 1 Do
		
		RowTableInventoryPerformers = TableInventoryPerformers[n];
		
		// Credit payroll costs in the UFP.
		TableRowReceipt = StructureAdditionalProperties.TableForRegisterRecords.TableInventory.Add();
		FillPropertyValues(TableRowReceipt, RowTableInventoryPerformers);
		
		TableRowReceipt.StructuralUnitCorr = IsEmptyStructuralUnit;
		TableRowReceipt.CorrGLAccount = EmptyAccount;
		TableRowReceipt.ProductsAndServicesCorr = EmptyProductsAndServices;
		TableRowReceipt.CharacteristicCorr = EmptyCharacteristic;
		TableRowReceipt.BatchCorr = EmptyBatch;
		TableRowReceipt.SpecificationCorr = EmptySpecification;
		TableRowReceipt.CustomerCorrOrder = EmptyCustomerOrder;
		
		// We will write off them on production.
		TableRowExpense = StructureAdditionalProperties.TableForRegisterRecords.TableInventory.Add();
		FillPropertyValues(TableRowExpense, RowTableInventoryPerformers);
		TableRowExpense.RecordType = AccumulationRecordType.Expense;
		TableRowExpense.FixedCost = False;
		TableRowExpense.ProductionExpenses = True;

		// Include in the product cost.
		TableRowReceipt = StructureAdditionalProperties.TableForRegisterRecords.TableInventory.Add();
		FillPropertyValues(TableRowReceipt, RowTableInventoryPerformers);
		
		TableRowReceipt.StructuralUnit = RowTableInventoryPerformers.StructuralUnitCorr;
		TableRowReceipt.GLAccount = RowTableInventoryPerformers.CorrGLAccount;
		TableRowReceipt.ProductsAndServices = RowTableInventoryPerformers.ProductsAndServicesCorr;
		TableRowReceipt.Characteristic = RowTableInventoryPerformers.CharacteristicCorr;
		TableRowReceipt.Batch = RowTableInventoryPerformers.BatchCorr;
		TableRowReceipt.Specification = RowTableInventoryPerformers.SpecificationCorr;
		TableRowReceipt.CustomerOrder = RowTableInventoryPerformers.CustomerCorrOrder;
		
		TableRowReceipt.StructuralUnitCorr = RowTableInventoryPerformers.StructuralUnit;
		TableRowReceipt.CorrGLAccount = RowTableInventoryPerformers.GLAccount;
		TableRowReceipt.ProductsAndServicesCorr = RowTableInventoryPerformers.ProductsAndServices;
		TableRowReceipt.CharacteristicCorr = RowTableInventoryPerformers.Characteristic;
		TableRowReceipt.BatchCorr = RowTableInventoryPerformers.Batch;
		TableRowReceipt.SpecificationCorr = RowTableInventoryPerformers.Specification;
		TableRowReceipt.CustomerCorrOrder = RowTableInventoryPerformers.CustomerOrder;
		
		TableRowReceipt.FixedCost = False;
		
	EndDo;
	
EndProcedure // GenerateTableInventory()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableInventoryProducts(DocumentRefCustomerOrder, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	TableInventory.LineNumber AS LineNumber,
	|	TableInventory.Finish AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	CASE
	|		WHEN TableInventory.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Completed,
	|	TableInventory.Company AS Company,
	|	VALUE(Catalog.PlanningPeriods.Actual) AS PlanningPeriod,
	|	TableInventory.Document AS Document,
	|	TableInventory.Document AS SalesDocument,
	|	TableInventory.Order AS OrderSales,
	|	TableInventory.DepartmentSales AS Department,
	|	TableInventory.Responsible AS Responsible,
	|	TableInventory.BusinessActivitySales AS BusinessActivity,
	|	TableInventory.DepartmentSales AS DepartmentSales,
	|	TableInventory.GLAccountCost AS GLAccountCost,
	|	TableInventory.CorrOrganization AS CorrOrganization,
	|	ISNULL(TableInventory.StructuralUnit, VALUE(Catalog.StructuralUnits.EmptyRef)) AS StructuralUnit,
	|	ISNULL(TableInventory.StructuralUnitCorr, VALUE(Catalog.StructuralUnits.EmptyRef)) AS StructuralUnitCorr,
	|	TableInventory.GLAccount AS GLAccount,
	|	TableInventory.CorrGLAccount AS CorrGLAccount,
	|	TableInventory.ProductsOnCommission AS ProductsOnCommission,
	|	TableInventory.ProductsAndServices AS ProductsAndServices,
	|	TableInventory.ProductsAndServicesCorr AS ProductsAndServicesCorr,
	|	TableInventory.Characteristic AS Characteristic,
	|	TableInventory.CharacteristicCorr AS CharacteristicCorr,
	|	TableInventory.Batch AS Batch,
	|	TableInventory.BatchCorr AS BatchCorr,
	|	VALUE(Document.CustomerOrder.EmptyRef) AS CustomerOrder,
	|	TableInventory.CorrOrder AS CustomerCorrOrder,
	|	TableInventory.Quantity AS Quantity,
	|	TableInventory.Reserve AS Reserve,
	|	TableInventory.ReserveShipment AS ReserveShipment,
	|	TableInventory.VATRate AS VATRate,
	|	TableInventory.VATAmount AS VATAmount,
	|	TableInventory.Amount AS Amount,
	|	0 AS Cost,
	|	FALSE AS FixedCost,
	|	TableInventory.GLAccountCost AS AccountDr,
	|	TableInventory.GLAccount AS AccountCr,
	|	CAST(&InventoryWriteOff AS String(100)) AS Content,
	|	CAST(&InventoryWriteOff AS String(100)) AS ContentOfAccountingRecord
	|FROM
	|	TemporaryTableProducts AS TableInventory
	|WHERE
	|	TableInventory.ProductsAndServicesType = VALUE(Enum.ProductsAndServicesTypes.InventoryItem)
	|
	|GROUP BY
	|	TableInventory.LineNumber,
	|	CASE
	|		WHEN TableInventory.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	TableInventory.Finish,
	|	TableInventory.Company,
	|	TableInventory.Order,
	|	TableInventory.BusinessActivitySales,
	|	TableInventory.DepartmentSales,
	|	TableInventory.Responsible,
	|	TableInventory.CorrOrganization,
	|	ISNULL(TableInventory.StructuralUnitCorr, VALUE(Catalog.StructuralUnits.EmptyRef)),
	|	TableInventory.CorrGLAccount,
	|	TableInventory.ProductsOnCommission,
	|	TableInventory.ProductsAndServices,
	|	TableInventory.ProductsAndServicesCorr,
	|	TableInventory.Characteristic,
	|	TableInventory.CharacteristicCorr,
	|	TableInventory.Batch,
	|	TableInventory.BatchCorr,
	|	TableInventory.CorrOrder,
	|	TableInventory.Quantity,
	|	TableInventory.Reserve,
	|	TableInventory.ReserveShipment,
	|	TableInventory.VATRate,
	|	TableInventory.VATAmount,
	|	TableInventory.Amount,
	|	TableInventory.Document,
	|	TableInventory.GLAccountCost,
	|	TableInventory.GLAccount,
	|	ISNULL(TableInventory.StructuralUnit, VALUE(Catalog.StructuralUnits.EmptyRef)),
	|	TableInventory.Document,
	|	TableInventory.DepartmentSales,
	|	TableInventory.GLAccountCost,
	|	TableInventory.GLAccount";
	
	Query.SetParameter("InventoryWriteOff", NStr("en='Inventory write-off';ru='Списание запасов';vi='Ghi giảm vật tư'"));
	
	//TableQueryResult = Query.Execute().Unload();
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableInventoryInventory", Query.Execute().Unload());
	
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
	|	TableInventory.CustomerOrder AS CustomerOrder
	|FROM
	|	(SELECT
	|		TableInventory.Company AS Company,
	|		TableInventory.StructuralUnit AS StructuralUnit,
	|		TableInventory.GLAccount AS GLAccount,
	|		TableInventory.ProductsAndServices AS ProductsAndServices,
	|		TableInventory.Characteristic AS Characteristic,
	|		TableInventory.Batch AS Batch,
	|		CASE
	|			WHEN TableInventory.Order REFS Document.CustomerOrder
	|				THEN TableInventory.Order
	|			ELSE VALUE(Document.CustomerOrder.EmptyRef)
	|		END AS CustomerOrder
	|	FROM
	|		TemporaryTableProducts AS TableInventory
	|	WHERE
	|		TableInventory.Order <> UNDEFINED
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableInventory.Company,
	|		TableInventory.StructuralUnit,
	|		TableInventory.GLAccount,
	|		TableInventory.ProductsAndServices,
	|		TableInventory.Characteristic,
	|		TableInventory.Batch,
	|		VALUE(Document.CustomerOrder.EmptyRef)
	|	FROM
	|		TemporaryTableProducts AS TableInventory) AS TableInventory
	|
	|GROUP BY
	|	TableInventory.Company,
	|	TableInventory.StructuralUnit,
	|	TableInventory.GLAccount,
	|	TableInventory.ProductsAndServices,
	|	TableInventory.Characteristic,
	|	TableInventory.Batch,
	|	TableInventory.CustomerOrder";
    
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
    |						TableInventory.Company AS Company,
    |						TableInventory.StructuralUnit AS StructuralUnit,
    |						TableInventory.GLAccount AS GLAccount,
    |						TableInventory.ProductsAndServices AS ProductsAndServices,
    |						TableInventory.Characteristic AS Characteristic,
    |						TableInventory.Batch AS Batch,
    |						CASE
    |							WHEN TableInventory.Order REFS Document.CustomerOrder
    |								THEN TableInventory.Order
    |							ELSE VALUE(Document.CustomerOrder.EmptyRef)
    |						END
    |					FROM
    |						TemporaryTableProducts AS TableInventory
    |					WHERE
    |						TableInventory.Order <> UNDEFINED)) AS InventoryBalances
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
    |		InventoryBalances.Company,
    |		InventoryBalances.StructuralUnit,
    |		InventoryBalances.GLAccount,
    |		InventoryBalances.ProductsAndServices,
    |		InventoryBalances.Characteristic,
    |		InventoryBalances.Batch,
    |		VALUE(Document.CustomerOrder.EmptyRef),
    |		SUM(InventoryBalances.QuantityBalance),
    |		SUM(InventoryBalances.AmountBalance)
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
    |						VALUE(Document.CustomerOrder.EmptyRef)
    |					FROM
    |						TemporaryTableProducts AS TableInventory)) AS InventoryBalances
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
    
    Query.SetParameter("Ref", DocumentRefCustomerOrder);
	Query.SetParameter("ControlTime", New Boundary(StructureAdditionalProperties.ForPosting.Ref.Finish, BoundaryType.Including));
	Query.SetParameter("ControlPeriod", StructureAdditionalProperties.ForPosting.Ref.Finish);
    
    QueryResult = Query.Execute();
    
    TableInventoryBalances = QueryResult.Unload();
    TableInventoryBalances.Indexes.Add("Company,StructuralUnit,GLAccount,ProductsAndServices,Characteristic,Batch,CustomerOrder");
		
	IsEmptyStructuralUnit = Catalogs.StructuralUnits.EmptyRef();
	EmptyAccount = ChartsOfAccounts.Managerial.EmptyRef();
	EmptyProductsAndServices = Catalogs.ProductsAndServices.EmptyRef();
	EmptyCharacteristic = Catalogs.ProductsAndServicesCharacteristics.EmptyRef();
	EmptyBatch = Catalogs.ProductsAndServicesBatches.EmptyRef();
    EmptyCustomerOrder = Documents.CustomerOrder.EmptyRef();
	InventoryReservation = Constants.FunctionalOptionInventoryReservation.Get();
	
	For n = 0 To StructureAdditionalProperties.TableForRegisterRecords.TableInventoryInventory.Count() - 1 Do
		
		RowTableInventory = StructureAdditionalProperties.TableForRegisterRecords.TableInventoryInventory[n];
				
		StructureForSearch = New Structure;
		StructureForSearch.Insert("Company", RowTableInventory.Company);
		StructureForSearch.Insert("StructuralUnit", RowTableInventory.StructuralUnit);
		StructureForSearch.Insert("GLAccount", RowTableInventory.GLAccount);
		StructureForSearch.Insert("ProductsAndServices", RowTableInventory.ProductsAndServices);
		StructureForSearch.Insert("Characteristic", RowTableInventory.Characteristic);
		StructureForSearch.Insert("Batch", RowTableInventory.Batch);
				
		// T.k. if in work order you reserve and write off yourself, always write off all quantity from clear balance.
		QuantityRequiredTotal = RowTableInventory.Quantity;
		
		QuantityRequiredReserve = RowTableInventory.Reserve;
		QuantityRequiredReserveShipment = RowTableInventory.ReserveShipment;
		QuantityRequiredAvailableBalance = QuantityRequiredTotal - QuantityRequiredReserve;
		
		If QuantityRequiredTotal > 0 Then
			
			StructureForSearch.Insert("CustomerOrder", EmptyCustomerOrder);
			
			BalanceRowsArray = TableInventoryBalances.FindRows(StructureForSearch);
			
			QuantityBalance = 0;
			AmountBalance = 0;
			
			If BalanceRowsArray.Count() > 0 Then
				QuantityBalance = BalanceRowsArray[0].QuantityBalance;
				AmountBalance = BalanceRowsArray[0].AmountBalance;
			EndIf;
			
			If QuantityRequiredReserve > 0 Then // It is required to make a reserve.
				
				If QuantityBalance > 0 AND QuantityBalance > QuantityRequiredReserve Then

					AmountToBeWrittenOff = Round(AmountBalance * QuantityRequiredReserve / QuantityBalance , 2, 1);

					BalanceRowsArray[0].QuantityBalance = BalanceRowsArray[0].QuantityBalance - QuantityRequiredReserve;
					BalanceRowsArray[0].AmountBalance = BalanceRowsArray[0].AmountBalance - AmountToBeWrittenOff;

				ElsIf QuantityBalance = QuantityRequiredReserve Then

					AmountToBeWrittenOff = AmountBalance;

					BalanceRowsArray[0].QuantityBalance = 0;
					BalanceRowsArray[0].AmountBalance = 0;

				Else
					AmountToBeWrittenOff = 0;
				EndIf;
				
				// Write off the stock of clear balance.
				TableRowExpense = StructureAdditionalProperties.TableForRegisterRecords.TableInventory.Add();
				FillPropertyValues(TableRowExpense, RowTableInventory);
				
				TableRowExpense.CorrGLAccount = RowTableInventory.GLAccount;
				TableRowExpense.StructuralUnitCorr = RowTableInventory.StructuralUnit;
				TableRowExpense.ProductsAndServicesCorr = RowTableInventory.ProductsAndServices;
				TableRowExpense.CharacteristicCorr = RowTableInventory.Characteristic;
				TableRowExpense.BatchCorr = RowTableInventory.Batch;
				TableRowExpense.CustomerCorrOrder = DocumentRefCustomerOrder;
				
				TableRowExpense.OrderSales = Undefined;
				TableRowExpense.SalesDocument = Undefined;
				TableRowExpense.Department = Undefined;
				TableRowExpense.Responsible = Undefined;
				TableRowExpense.VATRate = Undefined;
				
				TableRowExpense.ProductionExpenses = False;
				TableRowExpense.Amount = AmountToBeWrittenOff;
				TableRowExpense.Quantity = QuantityRequiredReserve;
				TableRowExpense.ContentOfAccountingRecord = NStr("en='Inventory write-off from unrestricted stock to reserve';ru='Списание запасов из свободного остатка в резерв';vi='Ghi giảm vật tư từ số dư tự do vào dự phòng'");
				
				// Put them in reserve.
				TableRowReceipt = StructureAdditionalProperties.TableForRegisterRecords.TableInventory.Add();
				FillPropertyValues(TableRowReceipt, RowTableInventory);
				
				TableRowReceipt.RecordType = AccumulationRecordType.Receipt;
				
				TableRowReceipt.GLAccount = RowTableInventory.GLAccount;
				TableRowReceipt.StructuralUnit = RowTableInventory.StructuralUnit;
				TableRowReceipt.ProductsAndServices = RowTableInventory.ProductsAndServices;
				TableRowReceipt.Characteristic = RowTableInventory.Characteristic;
				TableRowReceipt.Batch = RowTableInventory.Batch;
				TableRowReceipt.CustomerOrder = DocumentRefCustomerOrder;
				
				TableRowReceipt.CorrGLAccount = RowTableInventory.GLAccount;
				TableRowReceipt.StructuralUnitCorr = RowTableInventory.StructuralUnit;
				TableRowReceipt.ProductsAndServicesCorr = RowTableInventory.ProductsAndServices;
				TableRowReceipt.CharacteristicCorr = RowTableInventory.Characteristic;
				TableRowReceipt.BatchCorr = RowTableInventory.Batch;
				TableRowReceipt.CustomerCorrOrder = EmptyCustomerOrder;
				
				TableRowReceipt.OrderSales = Undefined;
				TableRowReceipt.SalesDocument = Undefined;
				TableRowReceipt.Department = Undefined;
				TableRowReceipt.Responsible = Undefined;
				TableRowReceipt.VATRate = Undefined;
				
				TableRowReceipt.ProductionExpenses = False;
				TableRowReceipt.Amount = AmountToBeWrittenOff;
				TableRowReceipt.Quantity = QuantityRequiredReserve;
				TableRowReceipt.ContentOfAccountingRecord = NStr("en='Receipt of inventory to reserve from unrestricted stock';ru='Поступление запасов в резерв из свободного остатка';vi='Tiếp nhận vật tư vào dự phòng từ số dư tự do'");
				
				If RowTableInventory.Completed Then // If the order is completed - required and sell.
					
					// Write off the stock from the reserve.
					TableRowExpense = StructureAdditionalProperties.TableForRegisterRecords.TableInventory.Add();
					FillPropertyValues(TableRowExpense, RowTableInventory);
					
					TableRowExpense.CustomerOrder = DocumentRefCustomerOrder;
					TableRowExpense.ProductionExpenses = False;
					TableRowExpense.Amount = AmountToBeWrittenOff;
					TableRowExpense.Quantity = QuantityRequiredReserve;
					TableRowExpense.ContentOfAccountingRecord = NStr("en='Sale of inventory from reserve';ru='Продажа запасов из резерва';vi='Bán vật tư từ lượng hàng dự phòng'");
					
					If Round(AmountToBeWrittenOff, 2, 1) <> 0 Then
						
						// Generate postings.
						RowTableManagerial = StructureAdditionalProperties.TableForRegisterRecords.TableManagerial.Add();
						FillPropertyValues(RowTableManagerial, RowTableInventory);
						RowTableManagerial.Amount = AmountToBeWrittenOff;
						
						// Move income and expenses.
						RowIncomeAndExpenses = StructureAdditionalProperties.TableForRegisterRecords.TableIncomeAndExpenses.Add();
						FillPropertyValues(RowIncomeAndExpenses, RowTableInventory);
						
						RowIncomeAndExpenses.StructuralUnit = RowTableInventory.DepartmentSales;
						RowIncomeAndExpenses.CustomerOrder = DocumentRefCustomerOrder;
						RowIncomeAndExpenses.GLAccount = RowTableInventory.GLAccountCost;
						RowIncomeAndExpenses.AmountIncome = 0;
						RowIncomeAndExpenses.AmountExpense = AmountToBeWrittenOff;
						RowIncomeAndExpenses.Amount = AmountToBeWrittenOff;
						
						RowIncomeAndExpenses.ContentOfAccountingRecord = NStr("en='Record expenses';ru='Отражение расходов';vi='Phản ánh chi phí'");
						
						// Move the cost of sales.
						SaleString = StructureAdditionalProperties.TableForRegisterRecords.TableSales.Add();
						FillPropertyValues(SaleString, RowTableInventory);
						SaleString.CustomerOrder = DocumentRefCustomerOrder;
						SaleString.Quantity = 0;
						SaleString.Amount = 0;
						SaleString.VATAmount = 0;
						SaleString.Cost = AmountToBeWrittenOff;				
						
					EndIf;
						
				EndIf;
				
			EndIf;
			
			// If the order is in progress - required to write off the reserve of other documents.
			QuantityReserveShipment = QuantityRequiredReserveShipment - QuantityRequiredReserve;
			If RowTableInventory.Completed 
				AND QuantityReserveShipment > 0 Then
				
				QuantityRequiredAvailableBalance = QuantityRequiredAvailableBalance - QuantityReserveShipment;
				
				StructureForSearch.Insert("CustomerOrder", DocumentRefCustomerOrder);
			
				BalanceRowsArrayShipment = TableInventoryBalances.FindRows(StructureForSearch);
				
				CountRemainShipment = 0;
				SumBalanceShipment = 0;
				
				If BalanceRowsArrayShipment.Count() > 0 Then
					CountRemainShipment = BalanceRowsArrayShipment[0].QuantityBalance;
					SumBalanceShipment = BalanceRowsArrayShipment[0].AmountBalance;
				EndIf;
				
				If CountRemainShipment > 0 AND CountRemainShipment > QuantityReserveShipment Then

					AmountToBeWrittenOffShipment = Round(SumBalanceShipment * QuantityReserveShipment / CountRemainShipment , 2, 1);

					BalanceRowsArrayShipment[0].QuantityBalance = BalanceRowsArrayShipment[0].QuantityBalance - QuantityReserveShipment;
					BalanceRowsArrayShipment[0].AmountBalance = BalanceRowsArrayShipment[0].AmountBalance - AmountToBeWrittenOffShipment;

				ElsIf CountRemainShipment = QuantityReserveShipment Then

					AmountToBeWrittenOffShipment = SumBalanceShipment;

					BalanceRowsArrayShipment[0].QuantityBalance = 0;
					BalanceRowsArrayShipment[0].AmountBalance = 0;

				Else
					AmountToBeWrittenOffShipment = 0;	
				EndIf;
				
				// Write off the stock from the reserve.
				TableRowExpense = StructureAdditionalProperties.TableForRegisterRecords.TableInventory.Add();
				FillPropertyValues(TableRowExpense, RowTableInventory);
					
				TableRowExpense.CustomerOrder = DocumentRefCustomerOrder;
				TableRowExpense.ProductionExpenses = False;
				TableRowExpense.Amount = AmountToBeWrittenOffShipment;
				
				TableRowExpense.Quantity = QuantityReserveShipment;
				
				TableRowExpense.ContentOfAccountingRecord = NStr("en='Sale of inventory from reserve';ru='Продажа запасов из резерва';vi='Bán vật tư từ lượng hàng dự phòng'");
				
				If Round(AmountToBeWrittenOffShipment, 2, 1) <> 0 Then
					
					// Generate postings.
					RowTableManagerial = StructureAdditionalProperties.TableForRegisterRecords.TableManagerial.Add();
					FillPropertyValues(RowTableManagerial, RowTableInventory);
					RowTableManagerial.Amount = AmountToBeWrittenOffShipment;
					
					// Move income and expenses.
					RowIncomeAndExpenses = StructureAdditionalProperties.TableForRegisterRecords.TableIncomeAndExpenses.Add();
					FillPropertyValues(RowIncomeAndExpenses, RowTableInventory);
					
					RowIncomeAndExpenses.StructuralUnit = RowTableInventory.DepartmentSales;
					RowIncomeAndExpenses.CustomerOrder = DocumentRefCustomerOrder;
					RowIncomeAndExpenses.GLAccount = RowTableInventory.GLAccountCost;
					RowIncomeAndExpenses.AmountIncome = 0;
					RowIncomeAndExpenses.AmountExpense = AmountToBeWrittenOffShipment;
					RowIncomeAndExpenses.Amount = AmountToBeWrittenOffShipment;
					
					RowIncomeAndExpenses.ContentOfAccountingRecord = NStr("en='Record expenses';ru='Отражение расходов';vi='Phản ánh chi phí'");
					
					// Move the cost of sales.
					SaleString = StructureAdditionalProperties.TableForRegisterRecords.TableSales.Add();
					FillPropertyValues(SaleString, RowTableInventory);
					SaleString.CustomerOrder = DocumentRefCustomerOrder;
					SaleString.Quantity = 0;
					SaleString.Amount = 0;
					SaleString.VATAmount = 0;
					SaleString.Cost = AmountToBeWrittenOffShipment;				
					
				EndIf;
				
			EndIf;
			
			If QuantityRequiredAvailableBalance > 0 Then
				
				If RowTableInventory.Completed Then // If the order is completed - required and sell.
					
					If QuantityBalance > 0 AND QuantityBalance > QuantityRequiredAvailableBalance Then

						AmountToBeWrittenOff = Round(AmountBalance * QuantityRequiredAvailableBalance / QuantityBalance , 2, 1);

						BalanceRowsArray[0].QuantityBalance = BalanceRowsArray[0].QuantityBalance - QuantityRequiredAvailableBalance;
						BalanceRowsArray[0].AmountBalance = BalanceRowsArray[0].AmountBalance - AmountToBeWrittenOff;

					ElsIf QuantityBalance = QuantityRequiredAvailableBalance Then

						AmountToBeWrittenOff = AmountBalance;

						BalanceRowsArray[0].QuantityBalance = 0;
						BalanceRowsArray[0].AmountBalance = 0;

					Else
						AmountToBeWrittenOff = 0;	
					EndIf;	
				
					// Write off the stock of clear balance.
					TableRowExpense = StructureAdditionalProperties.TableForRegisterRecords.TableInventory.Add();
					FillPropertyValues(TableRowExpense, RowTableInventory);
						
					TableRowExpense.CustomerOrder = EmptyCustomerOrder;
					TableRowExpense.ProductionExpenses = False;
					TableRowExpense.Amount = AmountToBeWrittenOff;
					TableRowExpense.Quantity = QuantityRequiredAvailableBalance;
					TableRowExpense.ContentOfAccountingRecord = NStr("en='Sale of unrestricted stock';ru='Продажа запасов из свободного остатка';vi='Bán vật tư từ lượng hàng tồn tự do'");
					
					If Not InventoryReservation Then
						TableRowExpense.CustomerCorrOrder = EmptyCustomerOrder;
					EndIf;
					
					If Round(AmountToBeWrittenOff, 2, 1) <> 0 Then
						
						// Generate postings.
						RowTableManagerial = StructureAdditionalProperties.TableForRegisterRecords.TableManagerial.Add();
						FillPropertyValues(RowTableManagerial, RowTableInventory);
						RowTableManagerial.Amount = AmountToBeWrittenOff;
						
						// Move income and expenses.
						RowIncomeAndExpenses = StructureAdditionalProperties.TableForRegisterRecords.TableIncomeAndExpenses.Add();
						FillPropertyValues(RowIncomeAndExpenses, RowTableInventory);
						
						RowIncomeAndExpenses.StructuralUnit = RowTableInventory.DepartmentSales;
						RowIncomeAndExpenses.CustomerOrder = DocumentRefCustomerOrder;
						RowIncomeAndExpenses.GLAccount = RowTableInventory.GLAccountCost;
						RowIncomeAndExpenses.AmountIncome = 0;
						RowIncomeAndExpenses.AmountExpense = AmountToBeWrittenOff;
						RowIncomeAndExpenses.Amount = AmountToBeWrittenOff;
						
						RowIncomeAndExpenses.ContentOfAccountingRecord = NStr("en='Record expenses';ru='Отражение расходов';vi='Phản ánh chi phí'");
						
						// Move the cost of sales.
						SaleString = StructureAdditionalProperties.TableForRegisterRecords.TableSales.Add();
						FillPropertyValues(SaleString, RowTableInventory);
						SaleString.CustomerOrder = DocumentRefCustomerOrder;
						SaleString.Quantity = 0;
						SaleString.Amount = 0;
						SaleString.VATAmount = 0;
						SaleString.Cost = AmountToBeWrittenOff;				
						
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	StructureAdditionalProperties.TableForRegisterRecords.Delete("TableInventoryInventory");
	
EndProcedure // GenerateTableInventory()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableManagerial(DocumentRefCustomerOrder, StructureAdditionalProperties)
	
	//( elmi #11
    Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
    "SELECT
	|	Sum(TemporaryTable.VATAmount) AS VATInventory ,
	|	Sum(TemporaryTable.VATAmountCur) AS VATInventoryCur 
	|FROM
	|	TemporaryTableProducts AS TemporaryTable
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
	|	Sum(TemporaryTable.VATAmount) AS VATWorks ,
	|	Sum(TemporaryTable.VATAmountCur) AS VATWorksCur 
	|FROM
	|	TemporaryTableWorks AS TemporaryTable
	|GROUP BY
	|TemporaryTable.Period,
	|TemporaryTable.Company	";
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	VATWorks = 0;
	VATWorksCur = 0;
	
	While Selection.Next() Do  
		  VATWorks        = Selection.VATWorks;
	      VATWorksCur     = Selection.VATWorksCur;
	EndDo;
	//) elmi

	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	1 AS Ordering,
	|	TableManagerial.LineNumber AS LineNumber,
	|	TableManagerial.Finish AS Period,
	|	TableManagerial.Company AS Company,
	|	VALUE(Catalog.PlanningPeriods.Actual) AS PlanningPeriod,
	|	TableManagerial.GLAccountCustomerSettlements AS AccountDr,
	|	CASE
	|		WHEN TableManagerial.GLAccountCustomerSettlements.Currency
	|			THEN TableManagerial.SettlementsCurrency
	|		ELSE UNDEFINED
	|	END AS CurrencyDr,
	|	CASE
	|		WHEN TableManagerial.GLAccountCustomerSettlements.Currency
	//( elmi #11
	//|			THEN TableManagerial.AmountCur
	|			THEN TableManagerial.AmountCur -TableManagerial.VATAmountCur          
	//) elmi
	|		ELSE 0
	|	END AS AmountCurDr,
	|	TableManagerial.AccountStatementSales AS AccountCr,
	|	CASE
	|		WHEN TableManagerial.AccountStatementSales.Currency
	|			THEN TableManagerial.SettlementsCurrency
	|		ELSE UNDEFINED
	|	END AS CurrencyCr,
	|	CASE
	|		WHEN TableManagerial.AccountStatementSales.Currency
	//( elmi #11
	//|			THEN TableManagerial.AmountCur
	|			THEN TableManagerial.AmountCur -TableManagerial.VATAmountCur          
	|		ELSE 0
	|	END AS AmountCurCr,
	//|	TableManagerial.Amount AS Amount,
	|	TableManagerial.Amount - TableManagerial.VATAmount  AS Amount,               
	//) elmi
    |	&IncomeReflection AS Content
	|FROM
	|	TemporaryTableWorks AS TableManagerial
	|WHERE
	|	TableManagerial.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|	AND TableManagerial.Amount <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	2,
	|	TableManagerial.LineNumber,
	|	TableManagerial.Finish,
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
	//|			THEN TableManagerial.AmountCur
	|			THEN TableManagerial.AmountCur - TableManagerial.VATAmountCur          
	//) elmi
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN TableManagerial.ProductsOnCommission
	|			THEN TableManagerial.GLAccountVendorSettlements
	|		ELSE TableManagerial.AccountStatementSales
	|	END,
	|	CASE
	|		WHEN TableManagerial.ProductsOnCommission
	|			THEN &AccountingCurrency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN TableManagerial.ProductsOnCommission
	//( elmi #11
	//|			THEN TableManagerial.Amount
	|	THEN TableManagerial.Amount -TableManagerial.VATAmount                       
	|		ELSE 0
	|	END,
	//|	TableManagerial.Amount,
	|	TableManagerial.Amount -TableManagerial.VATAmount,                       
	//) elmi
	|	&IncomeReflection
	|FROM
	|	TemporaryTableProducts AS TableManagerial
	|WHERE
	|	TableManagerial.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|	AND TableManagerial.Amount <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	3,
	|	1,
	|	DocumentTable.Period,
	|	DocumentTable.Company,
	|	VALUE(Catalog.PlanningPeriods.Actual),
	|	DocumentTable.CustomerAdvancesGLAccount,
	|	CASE
	|		WHEN DocumentTable.CustomerAdvancesGLAccountForeignCurrency
	|			THEN DocumentTable.SettlementsCurrency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.CustomerAdvancesGLAccountForeignCurrency
	|			THEN DocumentTable.AmountCur
	|		ELSE 0
	|	END,
	|	DocumentTable.GLAccountCustomerSettlements,
	|	CASE
	|		WHEN DocumentTable.GLAccountCustomerSettlementsCurrency
	|			THEN DocumentTable.SettlementsCurrency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.GLAccountCustomerSettlementsCurrency
	|			THEN DocumentTable.AmountCur
	|		ELSE 0
	|	END,
	|	DocumentTable.Amount,
	|	&SetOffAdvancePayment
	|FROM
	|	(SELECT
	|		DocumentTable.Period AS Period,
	|		DocumentTable.Company AS Company,
	|		DocumentTable.CustomerAdvancesGLAccount AS CustomerAdvancesGLAccount,
	|		DocumentTable.CustomerAdvancesGLAccountForeignCurrency AS CustomerAdvancesGLAccountForeignCurrency,
	|		DocumentTable.GLAccountCustomerSettlements AS GLAccountCustomerSettlements,
	|		DocumentTable.GLAccountCustomerSettlementsCurrency AS GLAccountCustomerSettlementsCurrency,
	|		DocumentTable.SettlementsCurrency AS SettlementsCurrency,
	|		SUM(DocumentTable.AmountCur) AS AmountCur,
	|		SUM(DocumentTable.Amount) AS Amount
	|	FROM
	|		(SELECT
	|			DocumentTable.Period AS Period,
	|			DocumentTable.Company AS Company,
	|			DocumentTable.CustomerAdvancesGLAccount AS CustomerAdvancesGLAccount,
	|			DocumentTable.CustomerAdvancesGLAccount.Currency AS CustomerAdvancesGLAccountForeignCurrency,
	|			DocumentTable.GLAccountCustomerSettlements AS GLAccountCustomerSettlements,
	|			DocumentTable.GLAccountCustomerSettlements.Currency AS GLAccountCustomerSettlementsCurrency,
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
	|			DocumentTable.Counterparty.CustomerAdvancesGLAccount,
	|			DocumentTable.Counterparty.CustomerAdvancesGLAccount.Currency,
	|			DocumentTable.Counterparty.GLAccountCustomerSettlements,
	|			DocumentTable.Counterparty.GLAccountCustomerSettlements.Currency,
	|			DocumentTable.Currency,
	|			0,
	|			DocumentTable.AmountOfExchangeDifferences
	|		FROM
	|			TemporaryTableExchangeRateDifferencesAccountsReceivable AS DocumentTable
	|		WHERE
	|			DocumentTable.SettlementsType = VALUE(Enum.SettlementsTypes.Advance)) AS DocumentTable
	|	
	|	GROUP BY
	|		DocumentTable.Period,
	|		DocumentTable.Company,
	|		DocumentTable.CustomerAdvancesGLAccount,
	|		DocumentTable.CustomerAdvancesGLAccountForeignCurrency,
	|		DocumentTable.GLAccountCustomerSettlements,
	|		DocumentTable.GLAccountCustomerSettlementsCurrency,
	|		DocumentTable.SettlementsCurrency
	|	
	|	HAVING
	|		(SUM(DocumentTable.Amount) >= 0.005
	|			OR SUM(DocumentTable.Amount) <= -0.005
	|			OR SUM(DocumentTable.AmountCur) >= 0.005
	|			OR SUM(DocumentTable.AmountCur) <= -0.005)) AS DocumentTable
	|
	|UNION ALL
	|
	|SELECT
	|	4,
	|	1,
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
	|				AND TableManagerial.GLAccountForeignCurrency
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
	|		TableExchangeRateDifferencesAccountsReceivable.Date AS Date,
	|		TableExchangeRateDifferencesAccountsReceivable.Company AS Company,
	|		TableExchangeRateDifferencesAccountsReceivable.GLAccount AS GLAccount,
	|		TableExchangeRateDifferencesAccountsReceivable.GLAccountForeignCurrency AS GLAccountForeignCurrency,
	|		TableExchangeRateDifferencesAccountsReceivable.Currency AS Currency,
	|		SUM(TableExchangeRateDifferencesAccountsReceivable.AmountOfExchangeDifferences) AS AmountOfExchangeDifferences
	|	FROM
	|		(SELECT
	|			DocumentTable.Date AS Date,
	|			DocumentTable.Company AS Company,
	|			DocumentTable.GLAccount AS GLAccount,
	|			DocumentTable.GLAccount.Currency AS GLAccountForeignCurrency,
	|			DocumentTable.Currency AS Currency,
	|			DocumentTable.AmountOfExchangeDifferences AS AmountOfExchangeDifferences
	|		FROM
	|			TemporaryTableExchangeRateDifferencesAccountsReceivable AS DocumentTable
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
	|			TemporaryTableExchangeRateDifferencesAccountsReceivable AS DocumentTable
	|		WHERE
	|			DocumentTable.SettlementsType = VALUE(Enum.SettlementsTypes.Advance)) AS TableExchangeRateDifferencesAccountsReceivable
	|	
	|	GROUP BY
	|		TableExchangeRateDifferencesAccountsReceivable.Date,
	|		TableExchangeRateDifferencesAccountsReceivable.Company,
	|		TableExchangeRateDifferencesAccountsReceivable.GLAccount,
	|		TableExchangeRateDifferencesAccountsReceivable.GLAccountForeignCurrency,
	|		TableExchangeRateDifferencesAccountsReceivable.Currency
	|	
	|	HAVING
	|		(SUM(TableExchangeRateDifferencesAccountsReceivable.AmountOfExchangeDifferences) >= 0.005
	|			OR SUM(TableExchangeRateDifferencesAccountsReceivable.AmountOfExchangeDifferences) <= -0.005)) AS TableManagerial
	|
	|UNION ALL
	|
	//( elmi #11
	| SELECT TOP 1
	|	5 AS Ordering,
	|	TableManagerial.LineNumber AS LineNumber,
	|	TableManagerial.Finish AS Period,
	|	TableManagerial.Company AS Company,
	|	VALUE(Catalog.PlanningPeriods.Actual) AS PlanningPeriod,
	|	TableManagerial.GLAccountCustomerSettlements AS AccountDr,
	|	CASE
	|		WHEN TableManagerial.GLAccountCustomerSettlements.Currency
	|			THEN TableManagerial.SettlementsCurrency
	|		ELSE UNDEFINED
	|	END AS CurrencyDr,
	|	CASE
	|		WHEN TableManagerial.GLAccountCustomerSettlements.Currency
	|			THEN &VATWorksCur
	|		ELSE 0
	|	END AS AmountCurDr,
	|	&TextVAT,
	|	UNDEFINED,
	|	0,
	|	&VATWorks,
    |	&VAT AS Content
	|FROM
	|	TemporaryTableWorks AS TableManagerial
	|WHERE
	|	TableManagerial.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|	AND &VATWorks <> 0
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	6,
	|	TableManagerial.LineNumber,
	|	TableManagerial.Finish,
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
	|			THEN &VATInventoryCur
	|		ELSE 0
	|	END,
	|	&TextVAT,
 	|   UNDEFINED,
	|	0,
	|	&VATInventory,
	|	&VAT
	|FROM
	|	TemporaryTableProducts AS TableManagerial
	|WHERE
	|	TableManagerial.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|	AND &VATInventory <> 0
	|
	//) elmi
	|
	|ORDER BY
	|	Ordering,
	|	LineNumber";                                                                          	
	
	Query.SetParameter("SetOffAdvancePayment", NStr("en='Prepayment setoff';ru='Зачет предоплаты';vi='Khấu trừ trả trước'"));
	Query.SetParameter("IncomeReflection", NStr("en='Revenue from sale';ru='Выручка от продажи';vi='Doanh thu bán hàng'"));
	Query.SetParameter("ExchangeDifference", NStr("en='Exchange rate difference';ru='Курсовая разница';vi='Chênh lệch tỷ giá'"));
	Query.SetParameter("PositiveExchangeDifferenceGLAccount", ChartsOfAccounts.Managerial.OtherIncome);
	Query.SetParameter("NegativeExchangeDifferenceAccountOfAccounting", ChartsOfAccounts.Managerial.OtherExpenses);
	Query.SetParameter("AccountingCurrency", Constants.AccountingCurrency.Get());
	//( elmi #11
	Query.SetParameter("VAT", NStr("en=' VAT ';vi='Thuế GTGT'"));
	Query.SetParameter("TextVAT",  ChartsOfAccounts.Managerial.Taxes);
	Query.SetParameter("VATWorksCur", VATWorksCur);
	Query.SetParameter("VATWorks",    VATWorks);
	Query.SetParameter("VATInventoryCur", VATInventoryCur);
	Query.SetParameter("VATInventory", VATInventory);

	//) elmi
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		NewEntry = StructureAdditionalProperties.TableForRegisterRecords.TableManagerial.Add();
		FillPropertyValues(NewEntry, Selection);
	EndDo;
	
EndProcedure // GenerateTableManagerial()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableInventory(DocumentRefCustomerOrder, StructureAdditionalProperties)
	
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
	|		AND DocumentRegisterRecordsInventory.Period <= &ControlPeriod
	|		AND DocumentRegisterRecordsInventory.RecordType = VALUE(AccumulationRecordType.Expense)) AS InventoryBalances
	|
	|GROUP BY
	|	InventoryBalances.Company,
	|	InventoryBalances.StructuralUnit,
	|	InventoryBalances.GLAccount,
	|	InventoryBalances.ProductsAndServices,
	|	InventoryBalances.Characteristic,
	|	InventoryBalances.Batch";
	
	Query.SetParameter("Ref", DocumentRefCustomerOrder);
	Query.SetParameter("ControlTime", New Boundary(StructureAdditionalProperties.ForPosting.PointInTime, BoundaryType.Including));
	Query.SetParameter("ControlPeriod", StructureAdditionalProperties.ForPosting.PointInTime.Date);
	
	QueryResult = Query.Execute();
	
	TableInventoryBalances = QueryResult.Unload();
	TableInventoryBalances.Indexes.Add("Company,StructuralUnit,GLAccount,ProductsAndServices,Characteristic,Batch");
	
	TemporaryTableInventory = StructureAdditionalProperties.TableForRegisterRecords.TableInventory.CopyColumns();

	For n = 0 To StructureAdditionalProperties.TableForRegisterRecords.TableInventory.Count() - 1 Do
		
		RowTableInventory = StructureAdditionalProperties.TableForRegisterRecords.TableInventory[n];
		
		StructureForSearch = New Structure;
		StructureForSearch.Insert("Company", RowTableInventory.Company);
		StructureForSearch.Insert("StructuralUnit", RowTableInventory.StructuralUnit);
		StructureForSearch.Insert("GLAccount", RowTableInventory.GLAccount);
		StructureForSearch.Insert("ProductsAndServices", RowTableInventory.ProductsAndServices);
		StructureForSearch.Insert("Characteristic", RowTableInventory.Characteristic);
		StructureForSearch.Insert("Batch", RowTableInventory.Batch);
		
		QuantityRequiredReserve = RowTableInventory.Quantity;
		
		If QuantityRequiredReserve > 0 Then
			
			BalanceRowsArray = TableInventoryBalances.FindRows(StructureForSearch);
			
			QuantityBalance = 0;
			AmountBalance = 0;
			
			If BalanceRowsArray.Count() > 0 Then
				QuantityBalance = BalanceRowsArray[0].QuantityBalance;
				AmountBalance = BalanceRowsArray[0].AmountBalance;
			EndIf;
			
			If QuantityBalance > 0 AND QuantityBalance > QuantityRequiredReserve Then

				AmountToBeWrittenOff = Round(AmountBalance * QuantityRequiredReserve / QuantityBalance , 2, 1);

				BalanceRowsArray[0].QuantityBalance = BalanceRowsArray[0].QuantityBalance - QuantityRequiredReserve;
				BalanceRowsArray[0].AmountBalance = BalanceRowsArray[0].AmountBalance - AmountToBeWrittenOff;

			ElsIf QuantityBalance = QuantityRequiredReserve Then

				AmountToBeWrittenOff = AmountBalance;

				BalanceRowsArray[0].QuantityBalance = 0;
				BalanceRowsArray[0].AmountBalance = 0;

			Else
				AmountToBeWrittenOff = 0;	
			EndIf;
	
			// Expense.
			TableRowExpense = TemporaryTableInventory.Add();
			FillPropertyValues(TableRowExpense, RowTableInventory);
			
			TableRowExpense.Amount = AmountToBeWrittenOff;
			TableRowExpense.Quantity = QuantityRequiredReserve;
			TableRowExpense.CustomerOrder = Undefined;
			
			// Receipt
			If Round(AmountToBeWrittenOff, 2, 1) <> 0 OR QuantityRequiredReserve > 0 Then
				
				TableRowReceipt = TemporaryTableInventory.Add();
				FillPropertyValues(TableRowReceipt, RowTableInventory);
					
				TableRowReceipt.RecordType = AccumulationRecordType.Receipt;
					
				TableRowReceipt.StructuralUnit = RowTableInventory.StructuralUnitCorr;
				TableRowReceipt.GLAccount = RowTableInventory.CorrGLAccount;
				TableRowReceipt.ProductsAndServices = RowTableInventory.ProductsAndServicesCorr;
				TableRowReceipt.Characteristic = RowTableInventory.CharacteristicCorr;
				TableRowReceipt.Batch = RowTableInventory.BatchCorr;
				TableRowReceipt.CustomerOrder = RowTableInventory.CustomerCorrOrder;
					
				TableRowReceipt.StructuralUnitCorr = RowTableInventory.StructuralUnit;
				TableRowReceipt.CorrGLAccount = RowTableInventory.GLAccount;
				TableRowReceipt.ProductsAndServicesCorr = RowTableInventory.ProductsAndServices;
				TableRowReceipt.CharacteristicCorr = RowTableInventory.Characteristic;
				TableRowReceipt.BatchCorr = RowTableInventory.Batch;
				TableRowReceipt.CustomerCorrOrder = Undefined;
					
				TableRowReceipt.Amount = AmountToBeWrittenOff;
				TableRowReceipt.Quantity = QuantityRequiredReserve;
					
				TableRowReceipt.GLAccount = RowTableInventory.CorrGLAccount;
					
			EndIf;
			
		EndIf;
		
	EndDo;
	
	StructureAdditionalProperties.TableForRegisterRecords.TableInventory = TemporaryTableInventory;
	
EndProcedure // GenerateInventoryTable()

// Refers the expenses to work cost
//
Procedure IncludeCostsInWorks(DocumentRefCustomerOrder, StructureAdditionalProperties)

	For n = 0 To StructureAdditionalProperties.TableForRegisterRecords.TableInventory.Count() - 1 Do
		
		RowTableInventory = StructureAdditionalProperties.TableForRegisterRecords.TableInventory[n];
		
		If RowTableInventory.RecordType = AccumulationRecordType.Expense 
			AND RowTableInventory.ProductsAndServices.ProductsAndServicesType = Enums.ProductsAndServicesTypes.Work Then
		
			StructureForSearch = New Structure;
			StructureForSearch.Insert("Company", RowTableInventory.Company);
			StructureForSearch.Insert("StructuralUnitCorr", RowTableInventory.StructuralUnit);
			StructureForSearch.Insert("CorrGLAccount", RowTableInventory.GLAccount);
			StructureForSearch.Insert("ProductsAndServicesCorr", RowTableInventory.ProductsAndServices);
			StructureForSearch.Insert("CharacteristicCorr", RowTableInventory.Characteristic);
			StructureForSearch.Insert("BatchCorr", RowTableInventory.Batch);
			StructureForSearch.Insert("RecordType", AccumulationRecordType.Expense);
			
			FoundStrings = StructureAdditionalProperties.TableForRegisterRecords.TableInventory.FindRows(StructureForSearch);
			
			For Each FoundString IN FoundStrings Do
			
				RowTableInventory.Amount = RowTableInventory.Amount + FoundString.Amount;
				If RowTableInventory.Amount <> 0 Then
				
					// Generate postings.
					RowTableManagerial = StructureAdditionalProperties.TableForRegisterRecords.TableManagerial.Add();
					FillPropertyValues(RowTableManagerial, RowTableInventory);
					RowTableManagerial.PlanningPeriod = Catalogs.PlanningPeriods.Actual;
					RowTableManagerial.Content = NStr("en='Inventory write-off';ru='Списание запасов';vi='Ghi giảm vật tư'");
					RowTableManagerial.Amount = FoundString.Amount;
					
					// Move the cost of sales.
					StringTableSale = StructureAdditionalProperties.TableForRegisterRecords.TableSales.Add();
					FillPropertyValues(StringTableSale, RowTableInventory);
					
					StringTableSale.CustomerOrder = DocumentRefCustomerOrder;
					StringTableSale.Quantity = 0;
					StringTableSale.Amount = 0;
					StringTableSale.VATAmount = 0;
					StringTableSale.Cost = FoundString.Amount;

					// Move income and expenses.
					RowIncomeAndExpenses = StructureAdditionalProperties.TableForRegisterRecords.TableIncomeAndExpenses.Add();
					FillPropertyValues(RowIncomeAndExpenses, RowTableInventory);
					
					RowIncomeAndExpenses.CustomerOrder = DocumentRefCustomerOrder;
					RowIncomeAndExpenses.GLAccount = RowTableInventory.GLAccountCost;
					RowIncomeAndExpenses.AmountIncome = 0;
					RowIncomeAndExpenses.AmountExpense = FoundString.Amount;
					RowIncomeAndExpenses.Amount = FoundString.Amount;
					
					RowIncomeAndExpenses.ContentOfAccountingRecord = NStr("en='Record expenses';ru='Отражение расходов';vi='Phản ánh chi phí'");
				
				EndIf;
			
			EndDo;
		
		EndIf; 
		
	EndDo;		
	

EndProcedure // IncludeWorksCosts()

// Payment calendar table formation procedure.
//
// Parameters:
// DocumentRef - DocumentRef.PaymentReceiptPlan - Current
// document AdditionalProperties - AdditionalProperties - Additional properties of the document
//
Procedure GenerateTablePaymentCalendar(DocumentRefCustomerOrder, StructureAdditionalProperties)
	
	Query = New Query;
	
	Query.SetParameter("Ref", DocumentRefCustomerOrder);
	Query.SetParameter("PointInTime", New Boundary(StructureAdditionalProperties.ForPosting.PointInTime, BoundaryType.Including));
	Query.SetParameter("Company", StructureAdditionalProperties.ForPosting.Company);
	
	Query.Text =
	"SELECT
	|	DocumentTable.PayDate AS Period,
	|	&Company AS Company,
	|	DocumentTable.Ref.CashAssetsType,
	|	VALUE(Enum.PaymentApprovalStatuses.Approved) AS PaymentConfirmationStatus,
	|	DocumentTable.Ref AS InvoiceForPayment,
	|	VALUE(Catalog.CashFlowItems.PaymentFromCustomers) AS Item,
	|	CASE
	|		WHEN DocumentTable.Ref.CashAssetsType = VALUE(Enum.CashAssetTypes.Cash)
	|			THEN DocumentTable.Ref.PettyCash
	|		WHEN DocumentTable.Ref.CashAssetsType = VALUE(Enum.CashAssetTypes.Noncash)
	|			THEN DocumentTable.Ref.BankAccount
	|		ELSE UNDEFINED
	|	END AS BankAccountPettyCash,
	|	CASE
	|		WHEN DocumentTable.Ref.Contract.SettlementsInStandardUnits
	|			THEN DocumentTable.Ref.Contract.SettlementsCurrency
	|		ELSE DocumentTable.Ref.DocumentCurrency
	|	END AS Currency,
	|	CASE
	|		WHEN DocumentTable.Ref.Contract.SettlementsInStandardUnits
	|			THEN CAST(DocumentTable.PaymentAmount * CASE
	|						WHEN SettlementsCurrencyRates.ExchangeRate <> 0
	|								AND CurrencyRatesOfDocument.Multiplicity <> 0
	|							THEN CurrencyRatesOfDocument.ExchangeRate * SettlementsCurrencyRates.Multiplicity / (ISNULL(SettlementsCurrencyRates.ExchangeRate, 1) * ISNULL(CurrencyRatesOfDocument.Multiplicity, 1))
	|						ELSE 1
	|					END AS NUMBER(15, 2))
	|		ELSE DocumentTable.PaymentAmount
	|	END AS Amount
	|FROM
	|	Document.CustomerOrder.PaymentCalendar AS DocumentTable
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(&PointInTime, ) AS SettlementsCurrencyRates
	|		ON DocumentTable.Ref.Contract.SettlementsCurrency = SettlementsCurrencyRates.Currency
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(&PointInTime, ) AS CurrencyRatesOfDocument
	|		ON DocumentTable.Ref.DocumentCurrency = CurrencyRatesOfDocument.Currency
	|WHERE
	|	DocumentTable.Ref = &Ref
	|	AND Not DocumentTable.Ref.OrderState.OrderStatus = VALUE(Enum.OrderStatuses.Open)
	|	AND Not(DocumentTable.Ref.OrderState.OrderStatus = VALUE(Enum.OrderStatuses.InProcess)
	|				AND DocumentTable.Ref.Closed)";
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TablePaymentCalendar", QueryResult.Unload());
	
EndProcedure // GenerateTablePaymentCalendar()

// Generating procedure for the table of invoices for payment.
//
// Parameters:
// DocumentRef - DocumentRef.PaymentReceiptPlan - Current
// document AdditionalProperties - AdditionalProperties - Additional properties of the document
//
Procedure GenerateTableInvoicesAndOrdersPayment(DocumentRefCustomerOrder, StructureAdditionalProperties)
	
	Query = New Query;
	
	Query.SetParameter("Ref", DocumentRefCustomerOrder);
	Query.SetParameter("PointInTime", New Boundary(StructureAdditionalProperties.ForPosting.PointInTime, BoundaryType.Including));
	Query.SetParameter("Company", StructureAdditionalProperties.ForPosting.Company);
	
	Query.Text =
	"SELECT
	|	DocumentTable.Date AS Period,
	|	&Company AS Company,
	|	DocumentTable.Ref AS InvoiceForPayment,
	|	DocumentTable.DocumentAmount AS Amount
	|FROM
	|	Document.CustomerOrder AS DocumentTable
	|WHERE
	|	DocumentTable.Counterparty.TrackPaymentsByBills
	|	AND DocumentTable.Ref = &Ref
	|	AND (NOT DocumentTable.Ref.OrderState.OrderStatus = VALUE(Enum.OrderStatuses.Open))
	|	AND (NOT(DocumentTable.Ref.OrderState.OrderStatus = VALUE(Enum.OrderStatuses.InProcess)
	|				AND DocumentTable.Ref.Closed))
	|	AND DocumentTable.DocumentAmount <> 0";
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableInvoicesAndOrdersPayment", QueryResult.Unload());
	
EndProcedure // GenerateTableInvoicesAndOrdersPayment()

// Generates a table of values that contains the data for the SerialNumbersGuarantees information register.
// Tables of values saves into the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableSerialNumbers(DocumentRef, StructureAdditionalProperties)
	
	If DocumentRef.SerialNumbers.Count()=0 AND DocumentRef.SerialNumbersMaterials.Count()=0 Then
		StructureAdditionalProperties.TableForRegisterRecords.Insert("TableSerialNumbersBalance", New ValueTable);
		StructureAdditionalProperties.TableForRegisterRecords.Insert("TableSerialNumbersGuarantees", New ValueTable);
		Return;
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT DISTINCT
	|	SNCommonTable.Period,
	|	SNCommonTable.RecordType,
	|	SNCommonTable.EventDate,
	|	SNCommonTable.Operation,
	|	SNCommonTable.SerialNumber,
	|	SNCommonTable.Company,
	|	SNCommonTable.ProductsAndServices,
	|	SNCommonTable.Characteristic,
	|	SNCommonTable.Batch,
	|	SNCommonTable.StructuralUnit,
	|	SNCommonTable.Cell,
	|	SUM(SNCommonTable.Quantity) AS Quantity
	|FROM
	|	(SELECT
	|		TemporaryTableInventory.Period AS Period,
	|		VALUE(AccumulationRecordType.Expense) AS RecordType,
	|		TemporaryTableInventory.Period AS EventDate,
	|		VALUE(Enum.SerialNumbersOperations.Expense) AS Operation,
	|		SerialNumbers.SerialNumber AS SerialNumber,
	|		TemporaryTableInventory.Company AS Company,
	|		TemporaryTableInventory.ProductsAndServices AS ProductsAndServices,
	|		TemporaryTableInventory.Characteristic AS Characteristic,
	|		TemporaryTableInventory.Batch AS Batch,
	|		TemporaryTableInventory.StructuralUnit AS StructuralUnit,
	|		TemporaryTableInventory.Cell AS Cell,
	|		1 AS Quantity
	|	FROM
	|		TemporaryTableProducts AS TemporaryTableInventory
	|			INNER JOIN TemporaryTableSerialNumbers AS SerialNumbers
	|			ON TemporaryTableInventory.ConnectionKey = SerialNumbers.ConnectionKey
	|	WHERE
	|		TemporaryTableInventory.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TemporaryTableConsumables.Period,
	|		VALUE(AccumulationRecordType.Expense),
	|		TemporaryTableConsumables.Period,
	|		VALUE(Enum.SerialNumbersOperations.Expense),
	|		SerialNumbers.SerialNumber,
	|		TemporaryTableConsumables.Company,
	|		TemporaryTableConsumables.ProductsAndServices,
	|		TemporaryTableConsumables.Characteristic,
	|		TemporaryTableConsumables.Batch,
	|		TemporaryTableConsumables.InventoryStructuralUnit,
	|		TemporaryTableConsumables.Cell,
	|		1
	|	FROM
	|		TemporaryTableConsumables AS TemporaryTableConsumables
	|			INNER JOIN TemporaryTableSerialNumbersMaterials AS SerialNumbers
	|			ON TemporaryTableConsumables.ConnectionKeySerialNumbers = SerialNumbers.ConnectionKey
	|	WHERE
	|		TemporaryTableConsumables.OrderStatus = VALUE(Enum.OrderStatuses.Completed)) AS SNCommonTable
	|
	|GROUP BY
	|	SNCommonTable.Period,
	|	SNCommonTable.EventDate,
	|	SNCommonTable.Operation,
	|	SNCommonTable.SerialNumber,
	|	SNCommonTable.Company,
	|	SNCommonTable.ProductsAndServices,
	|	SNCommonTable.Characteristic,
	|	SNCommonTable.Batch,
	|	SNCommonTable.StructuralUnit,
	|	SNCommonTable.Cell,
	|	SNCommonTable.RecordType";
	
	QueryResult = Query.Execute().Unload();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableSerialNumbersGuarantees", QueryResult);
	If StructureAdditionalProperties.AccountingPolicy.SerialNumbersBalance Then
		StructureAdditionalProperties.TableForRegisterRecords.Insert("TableSerialNumbersBalance", QueryResult);
	Else
		StructureAdditionalProperties.TableForRegisterRecords.Insert("TableSerialNumbersBalance", New ValueTable);
	EndIf; 
	
EndProcedure

Procedure GenerateTableServiceContractExecution(DocumentRefCustomerOrder, StructureAdditionalProperties)
	
	If Not GetFunctionalOption("UseBilling") Then
		StructureAdditionalProperties.TableForRegisterRecords.Insert("TableServiceContractExecution", New ValueTable);
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	TemporaryTableWorks.Period,
	|	TemporaryTableWorks.Contract,
	|	TemporaryTableWorks.ProductsAndServices AS ServiceContractObject,
	|	TemporaryTableWorks.CHARACTERISTIC,
	|	TRUE AS CostSpecified,
	|	TemporaryTableWorks.QuantityPlan AS Quantity,
	|	TemporaryTableWorks.AmountCur AS Amount
	|FROM
	|	TemporaryTableWorks AS TemporaryTableWorks,
	|	TemporaryTableHeader AS TemporaryTableHeader
	|WHERE
	|	TemporaryTableHeader.IsServiceContract
	|
	|UNION
	|
	|SELECT
	|	TemporaryTableProducts.Period,
	|	TemporaryTableProducts.Contract,
	|	TemporaryTableProducts.ProductsAndServices,
	|	TemporaryTableProducts.CHARACTERISTIC,
	|	TRUE,
	|	TemporaryTableProducts.Quantity,
	|	TemporaryTableProducts.AmountCur
	|FROM
	|	TemporaryTableProducts AS TemporaryTableProducts,
	|	TemporaryTableHeader AS TemporaryTableHeader
	|WHERE
	|	TemporaryTableHeader.IsServiceContract";
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableServiceContractExecution", QueryResult.Unload());
	
EndProcedure

Procedure GenerateTableInventoryByCCD(DocumentRef, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	MIN(TemporaryTableInventory.LineNumber) AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	TemporaryTableInventory.Period AS Period,
	|	TemporaryTableInventory.Company AS Company,
	|	TemporaryTableInventory.ProductsAndServices AS ProductsAndServices,
	|	TemporaryTableInventory.Characteristic AS Characteristic,
	|	TemporaryTableInventory.Batch AS Batch,
	|	TemporaryTableInventory.CCDNo AS CCDNo,
	|	TemporaryTableInventory.CountryOfOrigin AS CountryOfOrigin,
	|	SUM(TemporaryTableInventory.Quantity) AS Quantity
	|FROM
	|	TemporaryTableInventory AS TemporaryTableInventory
	|WHERE
	|	TemporaryTableInventory.CountryOfOrigin <> VALUE(Catalog.WorldCountries.Russia)
	|	AND TemporaryTableInventory.CountryOfOrigin <> VALUE(Catalog.WorldCountries.ПустаяССылка)
	|	AND TemporaryTableInventory.CCDNo <> VALUE(Catalog.CCDNumbers.ПустаяССылка)
	|
	|GROUP BY
	|	TemporaryTableInventory.Period,
	|	TemporaryTableInventory.Company,
	|	TemporaryTableInventory.ProductsAndServices,
	|	TemporaryTableInventory.Characteristic,
	|	TemporaryTableInventory.Batch,
	|	TemporaryTableInventory.CCDNo,
	|	TemporaryTableInventory.CountryOfOrigin";
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableInventoryByCCD", QueryResult.Unload());
	
EndProcedure

#Region DiscountCards

// Generates values table creating data for posting by the SalesByDiscountCards register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableSalesByDiscountCard(DocumentRefCustomerOrder, StructureAdditionalProperties)
	
	If DocumentRefCustomerOrder.DiscountCard.IsEmpty() Then
		StructureAdditionalProperties.TableForRegisterRecords.Insert("SaleByDiscountCardTable", New ValueTable);
		Return;
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	TableSales.Finish AS Period,
	|	TableSales.Document.DiscountCard AS DiscountCard,
	|	TableSales.Document.DiscountCard.CardOwner AS CardOwner,
	|	TableSales.Amount AS Amount
	|INTO TU_WorksAndProducts
	|FROM
	|	TemporaryTableWorks AS TableSales
	|WHERE
	|	TableSales.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|
	|UNION ALL
	|
	|SELECT
	|	TableSales.Finish,
	|	TableSales.Document.DiscountCard,
	|	TableSales.Document.DiscountCard.CardOwner,
	|	TableSales.Amount
	|FROM
	|	TemporaryTableProducts AS TableSales
	|WHERE
	|	TableSales.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TU_WorksAndProducts.Period,
	|	TU_WorksAndProducts.DiscountCard,
	|	TU_WorksAndProducts.CardOwner,
	|	SUM(TU_WorksAndProducts.Amount) AS Amount
	|FROM
	|	TU_WorksAndProducts AS TU_WorksAndProducts
	|
	|GROUP BY
	|	TU_WorksAndProducts.CardOwner,
	|	TU_WorksAndProducts.Period,
	|	TU_WorksAndProducts.DiscountCard";
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("SaleByDiscountCardTable", QueryResult.Unload());
	
EndProcedure // GenerateTableSalesByDiscountCard()

#EndRegion

#Region AutomaticDiscounts

// Generates a table of values that contains the data for posting by the register AutomaticDiscountsApplied.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableSalesByAutomaticDiscountsApplied(DocumentRefCustomerOrder, StructureAdditionalProperties)
	
	If DocumentRefCustomerOrder.DiscountsMarkups.Count() = 0 Or Not GetFunctionalOption("UseAutomaticDiscountsMarkups") Then
		StructureAdditionalProperties.TableForRegisterRecords.Insert("TableAutomaticDiscountsApplied", New ValueTable);
		Return;
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	TemporaryTableAutoDiscountsMarkups.Period,
	|	TemporaryTableAutoDiscountsMarkups.DiscountMarkup AS AutomaticDiscount,
	|	TemporaryTableAutoDiscountsMarkups.Amount AS DiscountAmount,
	|	TemporaryTableProducts.ProductsAndServices,
	|	TemporaryTableProducts.Characteristic,
	|	TemporaryTableProducts.Document AS DocumentDiscounts,
	|	TemporaryTableProducts.Counterparty AS RecipientDiscounts
	|FROM
	|	TemporaryTableProducts AS TemporaryTableProducts
	|		INNER JOIN TemporaryTableAutoDiscountsMarkups AS TemporaryTableAutoDiscountsMarkups
	|		ON TemporaryTableProducts.ConnectionKey = TemporaryTableAutoDiscountsMarkups.ConnectionKey
	|WHERE
	|	TemporaryTableProducts.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|
	|UNION ALL
	|
	|SELECT
	|	TemporaryTableAutoDiscountsMarkups.Period,
	|	TemporaryTableAutoDiscountsMarkups.DiscountMarkup,
	|	TemporaryTableAutoDiscountsMarkups.Amount,
	|	TemporaryTableWorks.ProductsAndServices,
	|	TemporaryTableWorks.Characteristic,
	|	TemporaryTableWorks.Document,
	|	TemporaryTableWorks.Counterparty
	|FROM
	|	TemporaryTableWorks AS TemporaryTableWorks
	|		INNER JOIN TemporaryTableAutoDiscountsMarkups AS TemporaryTableAutoDiscountsMarkups
	|		ON TemporaryTableWorks.ConnectionKeyForMarkupsDiscounts = TemporaryTableAutoDiscountsMarkups.ConnectionKey
	|WHERE
	|	TemporaryTableWorks.OrderStatus = VALUE(Enum.OrderStatuses.Completed)";
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableAutomaticDiscountsApplied", QueryResult.Unload());
	
EndProcedure // GenerateTableSalesByAutomaticDiscountsApplied()

#EndRegion

// Initializes the tables of values that contain the data of the document table sections.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure InitializeDocumentDataWorkOrder(DocumentRefCustomerOrder, StructureAdditionalProperties) 
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	JobOrder.Contract.IsServiceContract AS IsServiceContract,
	|	CASE
	|		WHEN JobOrder.Contract.IsServiceContract
	|				AND JobOrder.Contract.ServiceContractBusinessActivity <> VALUE(Catalog.BusinessActivities.EmptyRef)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS KeepAccountingExpensesByServiceContracts,
	|	JobOrder.Contract.ServiceContractBusinessActivity AS BusinessActivity,
	|	JobOrder.DiscountMarkupKind AS DiscountMarkupKind,
	|	JobOrder.Ref AS Ref,
	|	JobOrder.Date AS Period,
	|	JobOrder.Counterparty AS Counterparty,
	|	JobOrder.Contract AS Contract,
	|	JobOrder.Date AS Date,
	|	JobOrder.Contract.SettlementsCurrency AS ContractSettlementsCurrency,
	|	JobOrder.OperationKind AS OperationKind,
	|	JobOrder.Contract.SettlementsInStandardUnits AS ContractSettlementsInStandardUnits,
	|	JobOrder.ExchangeRate AS ExchangeRate,
	|	JobOrder.Multiplicity AS Multiplicity,
	|	JobOrder.DocumentCurrency AS DocumentCurrency,
	|	JobOrder.Counterparty.DoOperationsByDocuments AS DoOperationsByDocuments,
	|	JobOrder.Counterparty.DoOperationsByOrders AS DoOperationsByOrders,
	|	JobOrder.Finish AS Finish
	|INTO TemporaryTableHeader
	|FROM
	|	Document.CustomerOrder AS JobOrder
	|WHERE
	|	JobOrder.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
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
	|	WorkOrderWorks.LineNumber AS LineNumber,
	|	WorkOrderWorks.Ref.Date AS Period,
	|	WorkOrderWorks.Ref.Finish,
	|	&Company AS Company,
	|	WorkOrderWorks.Ref.SalesStructuralUnit AS StructuralUnit,
	|	WorkOrderWorks.Ref.Responsible AS Responsible,
	|	VALUE(Catalog.PlanningPeriods.Actual) AS PlanningPeriod,
	|	WorkOrderWorks.ProductsAndServices.ExpensesGLAccount AS GLAccount,
	|	WorkOrderWorks.ProductsAndServices AS ProductsAndServices,
	|	CASE
	|		WHEN &UseCharacteristics
	|			THEN WorkOrderWorks.Characteristic
	|		ELSE VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	|	END AS Characteristic,
	|	VALUE(Catalog.ProductsAndServicesBatches.EmptyRef) AS Batch,
	|	WorkOrderWorks.Ref AS CustomerOrder,
	|	WorkOrderWorks.Ref AS Document,
	|	WorkOrderWorks.Ref.Counterparty AS Counterparty,
	|	WorkOrderWorks.Ref.Counterparty.DoOperationsByContracts AS DoOperationsByContracts,
	|	WorkOrderWorks.Ref.Counterparty.DoOperationsByDocuments AS DoOperationsByDocuments,
	|	WorkOrderWorks.Ref.Counterparty.DoOperationsByOrders AS DoOperationsByOrders,
	|	WorkOrderWorks.Ref.Counterparty.TrackPaymentsByBills AS TrackPaymentsByBills,
	|	WorkOrderWorks.Ref.Counterparty.GLAccountCustomerSettlements AS GLAccountCustomerSettlements,
	|	WorkOrderWorks.Ref.Contract.SettlementsCurrency AS SettlementsCurrency,
	|	WorkOrderWorks.Ref.Contract AS Contract,
	|	WorkOrderWorks.Ref.SalesStructuralUnit AS DepartmentSales,
	|	CASE
	|		WHEN TemporaryTableHeader.KeepAccountingExpensesByServiceContracts
	|			THEN TemporaryTableHeader.BusinessActivity
	|		ELSE WorkOrderWorks.ProductsAndServices.BusinessActivity
	|	END AS BusinessActivitySales,
	|	CASE
	|		WHEN TemporaryTableHeader.KeepAccountingExpensesByServiceContracts
	|			THEN TemporaryTableHeader.BusinessActivity.GLAccountRevenueFromSales
	|		ELSE WorkOrderWorks.ProductsAndServices.BusinessActivity.GLAccountRevenueFromSales
	|	END AS AccountStatementSales,
	|	CASE
	|		WHEN TemporaryTableHeader.KeepAccountingExpensesByServiceContracts
	|			THEN TemporaryTableHeader.BusinessActivity.GLAccountCostOfSales
	|		ELSE WorkOrderWorks.ProductsAndServices.BusinessActivity.GLAccountCostOfSales
	|	END AS GLAccountCost,
	|	WorkOrderWorks.ProductsAndServices.ProductsAndServicesType AS ProductsAndServicesType,
	|	WorkOrderWorks.Quantity * WorkOrderWorks.Factor * WorkOrderWorks.Multiplicity AS Quantity,
	|	WorkOrderWorks.VATRate AS VATRate,
	|	CAST(CASE
	|			WHEN WorkOrderWorks.Ref.DocumentCurrency = &CurrencyNational
	|				THEN WorkOrderWorks.Total * RegCurrencyRates.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate * RegCurrencyRates.Multiplicity)
	|			ELSE WorkOrderWorks.Total * WorkOrderWorks.Ref.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate * WorkOrderWorks.Ref.Multiplicity)
	|		END AS NUMBER(15, 2)) AS Amount,
	|	CAST(CASE
	|			WHEN WorkOrderWorks.Ref.IncludeVATInPrice
	|				THEN 0
	|			ELSE CASE
	|					WHEN WorkOrderWorks.Ref.DocumentCurrency = &CurrencyNational
	|						THEN WorkOrderWorks.VATAmount * RegCurrencyRates.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate * RegCurrencyRates.Multiplicity)
	|					ELSE WorkOrderWorks.VATAmount * WorkOrderWorks.Ref.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate * WorkOrderWorks.Ref.Multiplicity)
	|				END
	|		END AS NUMBER(15, 2)) AS VATAmount,
	|	CAST(CASE
	|			WHEN WorkOrderWorks.Ref.DocumentCurrency = &CurrencyNational
	|				THEN WorkOrderWorks.VATAmount * RegCurrencyRates.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate * RegCurrencyRates.Multiplicity)
	|			ELSE WorkOrderWorks.VATAmount * WorkOrderWorks.Ref.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate * WorkOrderWorks.Ref.Multiplicity)
	|		END AS NUMBER(15, 2)) AS VATAmountSales,
	|	CAST(CASE
	|			WHEN WorkOrderWorks.Ref.IncludeVATInPrice
	|				THEN 0
	|			ELSE CASE
	|					WHEN WorkOrderWorks.Ref.DocumentCurrency = &CurrencyNational
	|						THEN WorkOrderWorks.VATAmount * RegCurrencyRates.ExchangeRate * WorkOrderWorks.Ref.Multiplicity / (WorkOrderWorks.Ref.ExchangeRate * RegCurrencyRates.Multiplicity)
	|					ELSE WorkOrderWorks.VATAmount
	|				END
	|		END AS NUMBER(15, 2)) AS VATAmountCur,
	|	CAST(CASE
	|			WHEN WorkOrderWorks.Ref.DocumentCurrency = &CurrencyNational
	|				THEN WorkOrderWorks.Total * RegCurrencyRates.ExchangeRate * WorkOrderWorks.Ref.Multiplicity / (WorkOrderWorks.Ref.ExchangeRate * RegCurrencyRates.Multiplicity)
	|			ELSE WorkOrderWorks.Total
	|		END AS NUMBER(15, 2)) AS AmountCur,
	|	WorkOrderWorks.Quantity * WorkOrderWorks.Factor * WorkOrderWorks.Multiplicity AS QuantityPlan,
	|	WorkOrderWorks.Ref.OrderState.OrderStatus AS OrderStatus,
	|	WorkOrderWorks.Ref.Closed AS Closed,
	|	WorkOrderWorks.Specification,
	|	WorkOrderWorks.ConnectionKeyForMarkupsDiscounts
	|INTO TemporaryTableWorks
	|FROM
	|	Document.CustomerOrder.Works AS WorkOrderWorks
	|		LEFT JOIN TemporaryTableCurrencyRatesSliceLatest AS ManagCurrencyRates
	|		ON (ManagCurrencyRates.Currency = &AccountingCurrency)
	|		LEFT JOIN TemporaryTableCurrencyRatesSliceLatest AS RegCurrencyRates
	|		ON (RegCurrencyRates.Currency = &CurrencyNational),
	|	TemporaryTableHeader AS TemporaryTableHeader
	|WHERE
	|	WorkOrderWorks.Ref = &Ref
	|	AND WorkOrderWorks.Ref.OperationKind = VALUE(Enum.OperationKindsCustomerOrder.WorkOrder)
	|	AND NOT WorkOrderWorks.Ref.OrderState.OrderStatus = VALUE(Enum.OrderStatuses.Open)
	|	AND NOT(WorkOrderWorks.Ref.OrderState.OrderStatus = VALUE(Enum.OrderStatuses.InProcess)
	|				AND WorkOrderWorks.Ref.Closed)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	WorkOrderProducts.LineNumber AS LineNumber,
	|	WorkOrderProducts.Ref AS Document,
	|	WorkOrderProducts.Ref.Counterparty AS Counterparty,
	|	WorkOrderProducts.Ref.Counterparty.DoOperationsByContracts AS DoOperationsByContracts,
	|	WorkOrderProducts.Ref.Counterparty.DoOperationsByDocuments AS DoOperationsByDocuments,
	|	WorkOrderProducts.Ref.Counterparty.DoOperationsByOrders AS DoOperationsByOrders,
	|	WorkOrderProducts.Ref.Counterparty.TrackPaymentsByBills AS TrackPaymentsByBills,
	|	WorkOrderProducts.Ref.Contract AS Contract,
	|	WorkOrderProducts.Ref.Date AS Period,
	|	WorkOrderProducts.Ref.Finish,
	|	WorkOrderProducts.Ref.Start,
	|	&Company AS Company,
	|	UNDEFINED AS CorrOrganization,
	|	WorkOrderProducts.Ref.SalesStructuralUnit AS DepartmentSales,
	|	WorkOrderProducts.Ref.Responsible AS Responsible,
	|	CASE
	|		WHEN TemporaryTableHeader.KeepAccountingExpensesByServiceContracts
	|			THEN TemporaryTableHeader.BusinessActivity
	|		ELSE WorkOrderProducts.ProductsAndServices.BusinessActivity
	|	END AS BusinessActivitySales,
	|	CASE
	|		WHEN TemporaryTableHeader.KeepAccountingExpensesByServiceContracts
	|			THEN TemporaryTableHeader.BusinessActivity.GLAccountRevenueFromSales
	|		ELSE WorkOrderProducts.ProductsAndServices.BusinessActivity.GLAccountRevenueFromSales
	|	END AS AccountStatementSales,
	|	CASE
	|		WHEN TemporaryTableHeader.KeepAccountingExpensesByServiceContracts
	|			THEN TemporaryTableHeader.BusinessActivity.GLAccountCostOfSales
	|		ELSE WorkOrderProducts.ProductsAndServices.BusinessActivity.GLAccountCostOfSales
	|	END AS GLAccountCost,
	|	WorkOrderProducts.ProductsAndServices.ProductsAndServicesType AS ProductsAndServicesType,
	|	WorkOrderProducts.Ref.StructuralUnitReserve AS StructuralUnit,
	|	UNDEFINED AS StructuralUnitCorr,
	|	CASE
	|		WHEN WorkOrderProducts.Ref.StructuralUnitReserve.OrderWarehouse
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS OrderWarehouse,
	|	CASE
	|		WHEN &AccountingByCells
	|			THEN WorkOrderProducts.Ref.Cell
	|		ELSE UNDEFINED
	|	END AS Cell,
	|	WorkOrderProducts.ProductsAndServices.InventoryGLAccount AS GLAccount,
	|	UNDEFINED AS CorrGLAccount,
	|	CASE
	|		WHEN &UseBatches
	|				AND WorkOrderProducts.Batch.Status = VALUE(Enum.BatchStatuses.ProductsOnCommission)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ProductsOnCommission,
	|	WorkOrderProducts.ProductsAndServices AS ProductsAndServices,
	|	UNDEFINED AS ProductsAndServicesCorr,
	|	CASE
	|		WHEN &UseCharacteristics
	|			THEN WorkOrderProducts.Characteristic
	|		ELSE VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	|	END AS Characteristic,
	|	UNDEFINED AS CharacteristicCorr,
	|	CASE
	|		WHEN &UseBatches
	|			THEN WorkOrderProducts.Batch
	|		ELSE VALUE(Catalog.ProductsAndServicesBatches.EmptyRef)
	|	END AS Batch,
	|	UNDEFINED AS BatchCorr,
	|	WorkOrderProducts.Ref AS Order,
	|	WorkOrderProducts.Ref AS CustomerOrder,
	|	UNDEFINED AS CorrOrder,
	|	CASE
	|		WHEN VALUETYPE(WorkOrderProducts.MeasurementUnit) = TYPE(Catalog.UOMClassifier)
	|			THEN WorkOrderProducts.Quantity
	|		ELSE WorkOrderProducts.Quantity * WorkOrderProducts.MeasurementUnit.Factor
	|	END AS Quantity,
	|	CASE
	|		WHEN VALUETYPE(WorkOrderProducts.MeasurementUnit) = TYPE(Catalog.UOMClassifier)
	|			THEN WorkOrderProducts.Reserve
	|		ELSE WorkOrderProducts.Reserve * WorkOrderProducts.MeasurementUnit.Factor
	|	END AS Reserve,
	|	CASE
	|		WHEN VALUETYPE(WorkOrderProducts.MeasurementUnit) = TYPE(Catalog.UOMClassifier)
	|			THEN WorkOrderProducts.ReserveShipment
	|		ELSE WorkOrderProducts.ReserveShipment * WorkOrderProducts.MeasurementUnit.Factor
	|	END AS ReserveShipment,
	|	WorkOrderProducts.VATRate AS VATRate,
	|	CAST(CASE
	|			WHEN WorkOrderProducts.Ref.IncludeVATInPrice
	|				THEN 0
	|			ELSE CASE
	|					WHEN WorkOrderProducts.Ref.DocumentCurrency = &CurrencyNational
	|						THEN WorkOrderProducts.VATAmount * RegCurrencyRates.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate * RegCurrencyRates.Multiplicity)
	|					ELSE WorkOrderProducts.VATAmount * WorkOrderProducts.Ref.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate * WorkOrderProducts.Ref.Multiplicity)
	|				END
	|		END AS NUMBER(15, 2)) AS VATAmount,
	|	CAST(CASE
	|			WHEN WorkOrderProducts.Ref.DocumentCurrency = &CurrencyNational
	|				THEN WorkOrderProducts.VATAmount * RegCurrencyRates.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate * RegCurrencyRates.Multiplicity)
	|			ELSE WorkOrderProducts.VATAmount * WorkOrderProducts.Ref.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate * WorkOrderProducts.Ref.Multiplicity)
	|		END AS NUMBER(15, 2)) AS AmountVATPurchaseSale,
	|	CAST(CASE
	|			WHEN WorkOrderProducts.Ref.DocumentCurrency = &CurrencyNational
	|				THEN WorkOrderProducts.Total * RegCurrencyRates.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate * RegCurrencyRates.Multiplicity)
	|			ELSE WorkOrderProducts.Total * WorkOrderProducts.Ref.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate * WorkOrderProducts.Ref.Multiplicity)
	|		END AS NUMBER(15, 2)) AS Amount,
	|	CAST(CASE
	|			WHEN WorkOrderProducts.Ref.IncludeVATInPrice
	|				THEN 0
	|			ELSE CASE
	|					WHEN WorkOrderProducts.Ref.DocumentCurrency = &CurrencyNational
	|						THEN WorkOrderProducts.VATAmount * RegCurrencyRates.ExchangeRate * WorkOrderProducts.Ref.Multiplicity / (WorkOrderProducts.Ref.ExchangeRate * RegCurrencyRates.Multiplicity)
	|					ELSE WorkOrderProducts.VATAmount
	|				END
	|		END AS NUMBER(15, 2)) AS VATAmountCur,
	|	CAST(CASE
	|			WHEN WorkOrderProducts.Ref.DocumentCurrency = &CurrencyNational
	|				THEN WorkOrderProducts.Total * RegCurrencyRates.ExchangeRate * WorkOrderProducts.Ref.Multiplicity / (WorkOrderProducts.Ref.ExchangeRate * RegCurrencyRates.Multiplicity)
	|			ELSE WorkOrderProducts.Total
	|		END AS NUMBER(15, 2)) AS AmountCur,
	|	WorkOrderProducts.Total AS SettlementsAmountTakenPassed,
	|	WorkOrderProducts.Ref.Counterparty.GLAccountCustomerSettlements AS GLAccountCustomerSettlements,
	|	WorkOrderProducts.Ref.Counterparty.GLAccountVendorSettlements AS GLAccountVendorSettlements,
	|	WorkOrderProducts.Ref.Contract.SettlementsCurrency AS SettlementsCurrency,
	|	WorkOrderProducts.Ref.OrderState.OrderStatus AS OrderStatus,
	|	WorkOrderProducts.ConnectionKey
	|INTO TemporaryTableProducts
	|FROM
	|	Document.CustomerOrder.Inventory AS WorkOrderProducts
	|		LEFT JOIN TemporaryTableCurrencyRatesSliceLatest AS ManagCurrencyRates
	|		ON (ManagCurrencyRates.Currency = &AccountingCurrency)
	|		LEFT JOIN TemporaryTableCurrencyRatesSliceLatest AS RegCurrencyRates
	|		ON (RegCurrencyRates.Currency = &CurrencyNational),
	|	TemporaryTableHeader AS TemporaryTableHeader
	|WHERE
	|	WorkOrderProducts.Ref = &Ref
	|	AND WorkOrderProducts.Ref.OperationKind = VALUE(Enum.OperationKindsCustomerOrder.WorkOrder)
	|	AND NOT WorkOrderProducts.Ref.OrderState.OrderStatus = VALUE(Enum.OrderStatuses.Open)
	|	AND NOT(WorkOrderProducts.Ref.OrderState.OrderStatus = VALUE(Enum.OrderStatuses.InProcess)
	|				AND WorkOrderProducts.Ref.Closed)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	WorkOrderMaterials.LineNumber AS LineNumber,
	|	WorkOrderMaterials.Ref.Date AS Period,
	|	WorkOrderMaterials.Ref.Finish,
	|	WorkOrderMaterials.Ref.Start,
	|	&Company AS Company,
	|	VALUE(Catalog.PlanningPeriods.Actual) AS PlanningPeriod,
	|	WorkOrderMaterials.Ref AS Order,
	|	WorkOrderMaterials.Ref.SalesStructuralUnit AS StructuralUnit,
	|	CASE
	|		WHEN &AccountingByCells
	|			THEN WorkOrderMaterials.Ref.Cell
	|		ELSE VALUE(Catalog.Cells.EmptyRef)
	|	END AS Cell,
	|	WorkOrderMaterials.Ref.StructuralUnitReserve AS InventoryStructuralUnit,
	|	CASE
	|		WHEN &AccountingByCells
	|			THEN WorkOrderMaterials.Ref.Cell
	|		ELSE VALUE(Catalog.Cells.EmptyRef)
	|	END AS CellInventory,
	|	CASE
	|		WHEN WorkOrderMaterials.Ref.StructuralUnitReserve.OrderWarehouse
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS OrderWarehouse,
	|	CASE
	|		WHEN WorkOrderMaterials.Batch.Status = VALUE(Enum.BatchStatuses.SafeCustody)
	|				OR WorkOrderMaterials.Batch.Status = VALUE(Enum.BatchStatuses.CommissionMaterials)
	|			THEN WorkOrderMaterials.ProductsAndServices.InventoryGLAccount
	|		ELSE CASE
	|				WHEN WorkOrderMaterials.Ref.SalesStructuralUnit.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Warehouse)
	|					THEN WorkOrderMaterials.ProductsAndServices.InventoryGLAccount
	|				ELSE WorkOrderMaterials.ProductsAndServices.ExpensesGLAccount
	|			END
	|	END AS GLAccount,
	|	CASE
	|		WHEN WorkOrderMaterials.Batch.Status = VALUE(Enum.BatchStatuses.SafeCustody)
	|				OR WorkOrderMaterials.Batch.Status = VALUE(Enum.BatchStatuses.CommissionMaterials)
	|			THEN WorkOrderMaterials.ProductsAndServices.InventoryGLAccount
	|		ELSE CASE
	|				WHEN WorkOrderMaterials.Ref.StructuralUnitReserve.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Warehouse)
	|					THEN WorkOrderMaterials.ProductsAndServices.InventoryGLAccount
	|				ELSE WorkOrderMaterials.ProductsAndServices.ExpensesGLAccount
	|			END
	|	END AS InventoryGLAccount,
	|	CASE
	|		WHEN WorkOrderMaterials.Ref.SalesStructuralUnit.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Warehouse)
	|			THEN WorkOrderWorks.ProductsAndServices.InventoryGLAccount
	|		ELSE WorkOrderWorks.ProductsAndServices.ExpensesGLAccount
	|	END AS CorrGLAccount,
	|	WorkOrderMaterials.ProductsAndServices AS ProductsAndServices,
	|	WorkOrderWorks.ProductsAndServices AS ProductsAndServicesCorr,
	|	CASE
	|		WHEN &UseCharacteristics
	|			THEN WorkOrderMaterials.Characteristic
	|		ELSE VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	|	END AS Characteristic,
	|	CASE
	|		WHEN &UseCharacteristics
	|			THEN WorkOrderWorks.Characteristic
	|		ELSE VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	|	END AS CharacteristicCorr,
	|	CASE
	|		WHEN &UseBatches
	|			THEN WorkOrderMaterials.Batch
	|		ELSE VALUE(Catalog.ProductsAndServicesBatches.EmptyRef)
	|	END AS Batch,
	|	VALUE(Catalog.ProductsAndServicesBatches.EmptyRef) AS BatchCorr,
	|	WorkOrderWorks.Specification AS SpecificationCorr,
	|	VALUE(Catalog.Specifications.EmptyRef) AS Specification,
	|	WorkOrderMaterials.Ref AS CustomerOrder,
	|	CASE
	|		WHEN VALUETYPE(WorkOrderMaterials.MeasurementUnit) = TYPE(Catalog.UOMClassifier)
	|			THEN WorkOrderMaterials.Quantity
	|		ELSE WorkOrderMaterials.Quantity * WorkOrderMaterials.MeasurementUnit.Factor
	|	END AS Quantity,
	|	CASE
	|		WHEN VALUETYPE(WorkOrderMaterials.MeasurementUnit) = TYPE(Catalog.UOMClassifier)
	|			THEN WorkOrderMaterials.Reserve
	|		ELSE WorkOrderMaterials.Reserve * WorkOrderMaterials.MeasurementUnit.Factor
	|	END AS Reserve,
	|	CASE
	|		WHEN VALUETYPE(WorkOrderMaterials.MeasurementUnit) = TYPE(Catalog.UOMClassifier)
	|			THEN WorkOrderMaterials.ReserveShipment
	|		ELSE WorkOrderMaterials.ReserveShipment * WorkOrderMaterials.MeasurementUnit.Factor
	|	END AS ReserveShipment,
	|	0 AS Amount,
	|	WorkOrderWorks.ProductsAndServices.ExpensesGLAccount AS AccountDr,
	|	CASE
	|		WHEN WorkOrderMaterials.Batch.Status = VALUE(Enum.BatchStatuses.SafeCustody)
	|				OR WorkOrderMaterials.Batch.Status = VALUE(Enum.BatchStatuses.CommissionMaterials)
	|			THEN WorkOrderMaterials.ProductsAndServices.InventoryGLAccount
	|		ELSE CASE
	|				WHEN WorkOrderMaterials.Ref.SalesStructuralUnit.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Warehouse)
	|					THEN WorkOrderMaterials.ProductsAndServices.InventoryGLAccount
	|				ELSE WorkOrderMaterials.ProductsAndServices.ExpensesGLAccount
	|			END
	|	END AS AccountCr,
	|	CAST(&InventoryDistribution AS STRING(100)) AS ContentOfAccountingRecord,
	|	CAST(&InventoryDistribution AS STRING(100)) AS Content,
	|	WorkOrderMaterials.ProductsAndServices.ProductsAndServicesType AS ProductsAndServicesType,
	|	WorkOrderMaterials.Ref.Start AS Start1,
	|	WorkOrderMaterials.Ref.OrderState.OrderStatus AS OrderStatus,
	|	WorkOrderMaterials.ConnectionKeySerialNumbers
	|INTO TemporaryTableConsumables
	|FROM
	|	Document.CustomerOrder.Materials AS WorkOrderMaterials
	|		LEFT JOIN Document.CustomerOrder.Works AS WorkOrderWorks
	|		ON WorkOrderMaterials.ConnectionKey = WorkOrderWorks.ConnectionKey
	|WHERE
	|	WorkOrderMaterials.Ref = &Ref
	|	AND WorkOrderWorks.Ref = &Ref
	|	AND WorkOrderMaterials.Ref.OperationKind = VALUE(Enum.OperationKindsCustomerOrder.WorkOrder)
	|	AND NOT WorkOrderMaterials.Ref.OrderState.OrderStatus = VALUE(Enum.OrderStatuses.Open)
	|	AND NOT(WorkOrderMaterials.Ref.OrderState.OrderStatus = VALUE(Enum.OrderStatuses.InProcess)
	|				AND WorkOrderMaterials.Ref.Closed)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	WorkOrderPerformers.LineNumber AS LineNumber,
	|	WorkOrderPerformers.Ref.Finish AS Period,
	|	&Company AS Company,
	|	VALUE(Catalog.PlanningPeriods.Actual) AS PlanningPeriod,
	|	BEGINOFPERIOD(WorkOrderPerformers.Ref.Finish, MONTH) AS RegistrationPeriod,
	|	WorkOrderPerformers.Ref.DocumentCurrency AS Currency,
	|	WorkOrderPerformers.Ref.SalesStructuralUnit AS StructuralUnit,
	|	WorkOrderPerformers.Employee,
	|	WorkOrderPerformers.Ref.Start AS StartDate,
	|	WorkOrderPerformers.Ref.Finish AS EndDate,
	|	0 AS DaysWorked,
	|	WorkOrderWorks.Quantity * WorkOrderWorks.Factor * WorkOrderWorks.Multiplicity AS HoursWorked,
	|	WorkOrderPerformers.AccruedAmount AS AmountCur,
	|	WorkOrderPerformers.AccrualDeductionKind AS AccrualDeductionKind,
	|	WorkOrderPerformers.Employee.SettlementsHumanResourcesGLAccount AS GLAccount,
	|	WorkOrderPerformers.AccrualDeductionKind.GLExpenseAccount AS InventoryGLAccount,
	|	WorkOrderWorks.ProductsAndServices.ExpensesGLAccount AS CorrespondentAccountAccountingInventory,
	|	WorkOrderWorks.ProductsAndServices AS ProductsAndServicesCorr,
	|	WorkOrderWorks.Characteristic AS CharacteristicCorr,
	|	VALUE(Catalog.ProductsAndServicesBatches.EmptyRef) AS BatchCorr,
	|	WorkOrderWorks.Specification AS SpecificationCorr,
	|	WorkOrderPerformers.Ref AS CustomerOrder,
	|	WorkOrderPerformers.AmountAccrualDeduction AS Size,
	|	CAST(WorkOrderPerformers.AccruedAmount * CASE
	|			WHEN WorkOrderPerformers.Ref.DocumentCurrency = &CurrencyNational
	|				THEN RegCurrencyRates.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate * RegCurrencyRates.Multiplicity)
	|			ELSE WorkOrderPerformers.Ref.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate * WorkOrderPerformers.Ref.Multiplicity)
	|		END AS NUMBER(15, 2)) AS Amount,
	|	WorkOrderPerformers.Ref AS CorrOrder,
	|	WorkOrderPerformers.Ref.OrderState.OrderStatus AS OrderStatus
	|INTO TemporaryTableArtist
	|FROM
	|	Document.CustomerOrder.Performers AS WorkOrderPerformers
	|		INNER JOIN Document.CustomerOrder.Works AS WorkOrderWorks
	|		ON WorkOrderPerformers.ConnectionKey = WorkOrderWorks.ConnectionKey
	|		LEFT JOIN TemporaryTableCurrencyRatesSliceLatest AS ManagCurrencyRates
	|		ON (ManagCurrencyRates.Currency = &AccountingCurrency)
	|		LEFT JOIN TemporaryTableCurrencyRatesSliceLatest AS RegCurrencyRates
	|		ON (RegCurrencyRates.Currency = &CurrencyNational)
	|WHERE
	|	WorkOrderPerformers.Ref = &Ref
	|	AND WorkOrderWorks.Ref = &Ref
	|	AND WorkOrderWorks.ProductsAndServices.ProductsAndServicesType = VALUE(Enum.ProductsAndServicesTypes.Work)
	|	AND WorkOrderPerformers.Ref.OperationKind = VALUE(Enum.OperationKindsCustomerOrder.WorkOrder)
	|	AND WorkOrderPerformers.Ref.OrderState.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(DocumentTable.LineNumber) AS LineNumber,
	|	DocumentTable.Ref.Finish AS Period,
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
	|	DocumentTable.Ref AS Order,
	|	VALUE(Catalog.BusinessActivities.Other) AS BusinessActivitySales,
	|	VALUE(Enum.SettlementsTypes.Advance) AS SettlementsType,
	|	VALUE(Enum.SettlementsTypes.Debt) AS SettlemensTypeWhere,
	|	&Ref AS DocumentWhere,
	|	DocumentTable.Document AS Document,
	|	CASE
	|		WHEN NOT DocumentTable.Ref.Counterparty.DoOperationsByDocuments
	|				OR VALUETYPE(DocumentTable.Document) = TYPE(Document.Netting)
	|			THEN VALUE(Catalog.CashFlowItems.PaymentFromCustomers)
	|		ELSE CASE
	|				WHEN DocumentTable.Document REFS Document.PaymentExpense
	|					THEN CAST(DocumentTable.Document AS Document.PaymentExpense).Item
	|				WHEN DocumentTable.Document REFS Document.CashReceipt
	|					THEN CAST(DocumentTable.Document AS Document.CashReceipt).Item
	|				WHEN DocumentTable.Document REFS Document.CashPayment
	|					THEN CAST(DocumentTable.Document AS Document.CashPayment).Item
	|				WHEN DocumentTable.Document REFS Document.PaymentReceipt
	|					THEN CAST(DocumentTable.Document AS Document.PaymentReceipt).Item
	|				ELSE VALUE(Catalog.CashFlowItems.PaymentFromCustomers)
	|			END
	|	END AS Item,
	|	CASE
	|		WHEN DocumentTable.Ref.Counterparty.DoOperationsByDocuments
	|			THEN CASE
	|					WHEN DocumentTable.Document REFS Document.PaymentExpense
	|						THEN CAST(DocumentTable.Document AS Document.PaymentExpense).Date
	|					WHEN DocumentTable.Document REFS Document.CashReceipt
	|						THEN CAST(DocumentTable.Document AS Document.CashReceipt).Date
	|					WHEN DocumentTable.Document REFS Document.CashPayment
	|						THEN CAST(DocumentTable.Document AS Document.CashPayment).Date
	|					WHEN DocumentTable.Document REFS Document.PaymentReceipt
	|						THEN CAST(DocumentTable.Document AS Document.PaymentReceipt).Date
	|					WHEN DocumentTable.Document REFS Document.Netting
	|						THEN CAST(DocumentTable.Document AS Document.Netting).Date
	|				END
	|		ELSE DocumentTable.Ref.Date
	|	END AS DocumentDate,
	|	SUM(CAST(DocumentTable.SettlementsAmount * DocumentTable.Ref.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * DocumentTable.Ref.Multiplicity) AS NUMBER(15, 2))) AS Amount,
	|	SUM(DocumentTable.SettlementsAmount) AS AmountCur,
	|	DocumentTable.Ref.Finish
	|INTO TemporaryTablePrepayment
	|FROM
	|	Document.CustomerOrder.Prepayment AS DocumentTable
	|		LEFT JOIN TemporaryTableCurrencyRatesSliceLatest AS AccountingCurrencyRatesSliceLast
	|		ON (AccountingCurrencyRatesSliceLast.Currency = &AccountingCurrency)
	|WHERE
	|	DocumentTable.Ref = &Ref
	|	AND DocumentTable.Ref.OperationKind = VALUE(Enum.OperationKindsCustomerOrder.WorkOrder)
	|	AND DocumentTable.Ref.OrderState.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|
	|GROUP BY
	|	DocumentTable.Ref,
	|	DocumentTable.Document,
	|	DocumentTable.Ref.Counterparty,
	|	DocumentTable.Ref.Contract,
	|	DocumentTable.Ref.Contract.SettlementsCurrency,
	|	DocumentTable.Ref.Counterparty.GLAccountCustomerSettlements,
	|	DocumentTable.Ref.Counterparty.CustomerAdvancesGLAccount,
	|	DocumentTable.Ref.Counterparty.GLAccountVendorSettlements,
	|	DocumentTable.Ref.Counterparty.VendorAdvancesGLAccount,
	|	CASE
	|		WHEN NOT DocumentTable.Ref.Counterparty.DoOperationsByDocuments
	|				OR VALUETYPE(DocumentTable.Document) = TYPE(Document.Netting)
	|			THEN VALUE(Catalog.CashFlowItems.PaymentFromCustomers)
	|		ELSE CASE
	|				WHEN DocumentTable.Document REFS Document.PaymentExpense
	|					THEN CAST(DocumentTable.Document AS Document.PaymentExpense).Item
	|				WHEN DocumentTable.Document REFS Document.CashReceipt
	|					THEN CAST(DocumentTable.Document AS Document.CashReceipt).Item
	|				WHEN DocumentTable.Document REFS Document.CashPayment
	|					THEN CAST(DocumentTable.Document AS Document.CashPayment).Item
	|				WHEN DocumentTable.Document REFS Document.PaymentReceipt
	|					THEN CAST(DocumentTable.Document AS Document.PaymentReceipt).Item
	|				ELSE VALUE(Catalog.CashFlowItems.PaymentFromCustomers)
	|			END
	|	END,
	|	CASE
	|		WHEN DocumentTable.Ref.Counterparty.DoOperationsByDocuments
	|			THEN CASE
	|					WHEN DocumentTable.Document REFS Document.PaymentExpense
	|						THEN CAST(DocumentTable.Document AS Document.PaymentExpense).Date
	|					WHEN DocumentTable.Document REFS Document.CashReceipt
	|						THEN CAST(DocumentTable.Document AS Document.CashReceipt).Date
	|					WHEN DocumentTable.Document REFS Document.CashPayment
	|						THEN CAST(DocumentTable.Document AS Document.CashPayment).Date
	|					WHEN DocumentTable.Document REFS Document.PaymentReceipt
	|						THEN CAST(DocumentTable.Document AS Document.PaymentReceipt).Date
	|					WHEN DocumentTable.Document REFS Document.Netting
	|						THEN CAST(DocumentTable.Document AS Document.Netting).Date
	|				END
	|		ELSE DocumentTable.Ref.Date
	|	END,
	|	DocumentTable.Ref.Counterparty.DoOperationsByContracts,
	|	DocumentTable.Ref.Counterparty.DoOperationsByDocuments,
	|	DocumentTable.Ref.Counterparty.DoOperationsByOrders,
	|	DocumentTable.Ref.Counterparty.TrackPaymentsByBills,
	|	DocumentTable.Ref.Finish
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomerOrderDiscountsMarkups.ConnectionKey,
	|	CustomerOrderDiscountsMarkups.DiscountMarkup,
	|	CAST(CASE
	|			WHEN CustomerOrderDiscountsMarkups.Ref.DocumentCurrency = ConstantNationalCurrency.Value
	|				THEN CustomerOrderDiscountsMarkups.Amount * RegCurrencyRates.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate * RegCurrencyRates.Multiplicity)
	|			ELSE CustomerOrderDiscountsMarkups.Amount * CustomerOrderDiscountsMarkups.Ref.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate * CustomerOrderDiscountsMarkups.Ref.Multiplicity)
	|		END AS NUMBER(15, 2)) AS Amount,
	|	CustomerOrderDiscountsMarkups.Ref.Date AS Period,
	|	CustomerOrderDiscountsMarkups.Ref.Counterparty AS StructuralUnit
	|INTO TemporaryTableAutoDiscountsMarkups
	|FROM
	|	Document.CustomerOrder.DiscountsMarkups AS CustomerOrderDiscountsMarkups
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
	|				&PointInTime,
	|				Currency IN
	|					(SELECT
	|						ConstantAccountingCurrency.Value
	|					FROM
	|						Constant.AccountingCurrency AS ConstantAccountingCurrency)) AS ManagCurrencyRates
	|		ON (TRUE)
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
	|				&PointInTime,
	|				Currency IN
	|					(SELECT
	|						ConstantNationalCurrency.Value
	|					FROM
	|						Constant.NationalCurrency AS ConstantNationalCurrency)) AS RegCurrencyRates
	|		ON (TRUE),
	|	Constant.NationalCurrency AS ConstantNationalCurrency
	|WHERE
	|	CustomerOrderDiscountsMarkups.Ref = &Ref
	|	AND CustomerOrderDiscountsMarkups.Amount <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomerOrderSerialNumbers.ConnectionKey,
	|	CustomerOrderSerialNumbers.SerialNumber
	|INTO TemporaryTableSerialNumbers
	|FROM
	|	Document.CustomerOrder.SerialNumbers AS CustomerOrderSerialNumbers
	|WHERE
	|	CustomerOrderSerialNumbers.Ref = &Ref
	|	AND &UseSerialNumbers
	|	AND NOT CustomerOrderSerialNumbers.Ref.StructuralUnitReserve.OrderWarehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomerOrderSerialNumbers.ConnectionKey,
	|	CustomerOrderSerialNumbers.SerialNumber
	|INTO TemporaryTableSerialNumbersMaterials
	|FROM
	|	Document.CustomerOrder.SerialNumbersMaterials AS CustomerOrderSerialNumbers
	|WHERE
	|	CustomerOrderSerialNumbers.Ref = &Ref
	|	AND &UseSerialNumbers
	|	AND NOT CustomerOrderSerialNumbers.Ref.StructuralUnitReserve.OrderWarehouse";
	
	Query.SetParameter("Ref", DocumentRefCustomerOrder);
	Query.SetParameter("Company", StructureAdditionalProperties.ForPosting.Company);
	Query.SetParameter("PointInTime", New Boundary(StructureAdditionalProperties.ForPosting.PointInTime, BoundaryType.Including));
	Query.SetParameter("UseCharacteristics", StructureAdditionalProperties.AccountingPolicy.UseCharacteristics);
	Query.SetParameter("UseBatches", StructureAdditionalProperties.AccountingPolicy.UseBatches);
	Query.SetParameter("AccountingByCells", StructureAdditionalProperties.AccountingPolicy.AccountingByCells);
	Query.SetParameter("InventoryDistribution", NStr("en='Inventory allocation';ru='Распределение запасов';vi='Phân bổ vật tư'"));
	
	Query.SetParameter("UseSerialNumbers", StructureAdditionalProperties.AccountingPolicy.UseSerialNumbers);
	
	Query.SetParameter("AccountingCurrency", Constants.AccountingCurrency.Get());
	Query.SetParameter("CurrencyNational", Constants.NationalCurrency.Get());
	
	Query.ExecuteBatch();
	
	// Creation of document postings.
	SmallBusinessServer.GenerateTransactionsTable(DocumentRefCustomerOrder, StructureAdditionalProperties);
	
	GenerateTableProductRelease(DocumentRefCustomerOrder, StructureAdditionalProperties);
	GenerateTableInventoryTransferSchedule(DocumentRefCustomerOrder, StructureAdditionalProperties);
	GenerateTableCustomerAccounts(DocumentRefCustomerOrder, StructureAdditionalProperties);
	GenerateTableIncomeAndExpenses(DocumentRefCustomerOrder, StructureAdditionalProperties);
	GenerateTableIncomeAndExpensesRetained(DocumentRefCustomerOrder, StructureAdditionalProperties);
	GenerateTableIncomeAndExpensesUndistributed(DocumentRefCustomerOrder, StructureAdditionalProperties);
	GenerateTableIncomeAndExpensesCashMethod(DocumentRefCustomerOrder, StructureAdditionalProperties);
	GenerateTableCustomerOrders(DocumentRefCustomerOrder, StructureAdditionalProperties);
	GenerateTableInventoryInWarehouses(DocumentRefCustomerOrder, StructureAdditionalProperties);
	GenerateTableInventoryForExpenseFromWarehouses(DocumentRefCustomerOrder, StructureAdditionalProperties);
	GenerateTableAccrualsAndDeductions(DocumentRefCustomerOrder, StructureAdditionalProperties);
	GenerateTablePayrollPayments(DocumentRefCustomerOrder, StructureAdditionalProperties);
	GenerateTableSales(DocumentRefCustomerOrder, StructureAdditionalProperties);
	GenerateTableInventoryDemand(DocumentRefCustomerOrder, StructureAdditionalProperties);
	GenerateTableInventoryWorks(DocumentRefCustomerOrder, StructureAdditionalProperties);
	GenerateTableInventoryMaterials(DocumentRefCustomerOrder, StructureAdditionalProperties);
	GenerateTableInventoryPerformers(DocumentRefCustomerOrder, StructureAdditionalProperties);
	GenerateTableInventoryProducts(DocumentRefCustomerOrder, StructureAdditionalProperties);
	GenerateTableInventoryReceived(DocumentRefCustomerOrder, StructureAdditionalProperties);
	IncludeCostsInWorks(DocumentRefCustomerOrder, StructureAdditionalProperties);
	GenerateTablePaymentCalendar(DocumentRefCustomerOrder, StructureAdditionalProperties);
	GenerateTableInvoicesAndOrdersPayment(DocumentRefCustomerOrder, StructureAdditionalProperties);
	
	// DiscountCards
	GenerateTableSalesByDiscountCard(DocumentRefCustomerOrder, StructureAdditionalProperties);
	// AutomaticDiscounts
	GenerateTableSalesByAutomaticDiscountsApplied(DocumentRefCustomerOrder, StructureAdditionalProperties);
	
	// Serial numbers
	GenerateTableSerialNumbers(DocumentRefCustomerOrder, StructureAdditionalProperties);
	
	// Billing
	GenerateTableServiceContractExecution(DocumentRefCustomerOrder, StructureAdditionalProperties);
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableOrdersPlacement", New ValueTable);
	
	GenerateTableManagerial(DocumentRefCustomerOrder, StructureAdditionalProperties);
	
	//Ресурсы
	If GetFunctionalOption("PlanCompanyResourcesLoading") Then
		ResourcesRecordsTable = ResourcePlanningCM.DocumentsRecordsTable(DocumentRefCustomerOrder);
		StructureAdditionalProperties.TableForRegisterRecords.Insert("TableCompanyResources", ResourcesRecordsTable);
	EndIf;
	
EndProcedure // DocumentDataInitialization()

// Initializes the tables of values that contain the data of the document table sections.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
Procedure InitializeDocumentDataCustomerOrder(DocumentRefCustomerOrder, StructureAdditionalProperties) 

	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text = 
	"SELECT
	|	CustomerOrderInventory.LineNumber AS LineNumber,
	|	CustomerOrderInventory.Ref.Date AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Company AS Company,
	|	CustomerOrderInventory.Ref AS CustomerOrder,
	|	CustomerOrderInventory.ProductsAndServices AS ProductsAndServices,
	|	CASE
	|		WHEN &UseCharacteristics
	|			THEN CustomerOrderInventory.Characteristic
	|		ELSE VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	|	END AS Characteristic,
	|	CASE
	|		WHEN VALUETYPE(CustomerOrderInventory.MeasurementUnit) = Type(Catalog.UOMClassifier)
	|			THEN CustomerOrderInventory.Quantity
	|		ELSE CustomerOrderInventory.Quantity * CustomerOrderInventory.MeasurementUnit.Factor
	|	END AS Quantity,
	|	CustomerOrderInventory.ShipmentDate AS ShipmentDate
	|FROM
	|	Document.CustomerOrder.Inventory AS CustomerOrderInventory
	|WHERE
	|	CustomerOrderInventory.Ref = &Ref
	|	AND (CustomerOrderInventory.Ref.OrderState.OrderStatus = VALUE(Enum.OrderStatuses.InProcess)
	|				AND CustomerOrderInventory.Ref.Closed = FALSE
	|			OR CustomerOrderInventory.Ref.OrderState.OrderStatus = VALUE(Enum.OrderStatuses.Completed))
	|
	|ORDER BY
	|	LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomerOrderMaterials.LineNumber AS LineNumber,
	|	CustomerOrderMaterials.Ref.Date AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Company AS Company,
	|	VALUE(Enum.InventoryMovementTypes.Receipt) AS MovementType,
	|	CustomerOrderMaterials.Ref AS CustomerOrder,
	|	CustomerOrderMaterials.ProductsAndServices AS ProductsAndServices,
	|	CASE
	|		WHEN &UseCharacteristics
	|			THEN CustomerOrderMaterials.Characteristic
	|		ELSE VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	|	END AS Characteristic,
	|	CASE
	|		WHEN VALUETYPE(CustomerOrderMaterials.MeasurementUnit) = Type(Catalog.UOMClassifier)
	|			THEN CustomerOrderMaterials.Quantity
	|		ELSE CustomerOrderMaterials.Quantity * CustomerOrderMaterials.MeasurementUnit.Factor
	|	END AS Quantity
	|FROM
	|	Document.CustomerOrder.ConsumerMaterials AS CustomerOrderMaterials
	|WHERE
	|	CustomerOrderMaterials.Ref = &Ref
	|	AND CustomerOrderMaterials.Ref.OperationKind = VALUE(Enum.OperationKindsCustomerOrder.OrderForProcessing)
	|	AND (CustomerOrderMaterials.Ref.OrderState.OrderStatus = VALUE(Enum.OrderStatuses.InProcess)
	|				AND CustomerOrderMaterials.Ref.Closed = FALSE
	|			OR CustomerOrderMaterials.Ref.OrderState.OrderStatus = VALUE(Enum.OrderStatuses.Completed))
	|
	|ORDER BY
	|	LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	1 AS Ordering,
	|	CustomerOrderInventory.LineNumber AS LineNumber,
	|	CustomerOrderInventory.ShipmentDate AS Period,
	|	&Company AS Company,
	|	VALUE(Enum.InventoryMovementTypes.Shipment) AS MovementType,
	|	CustomerOrderInventory.Ref AS Order,
	|	CustomerOrderInventory.ProductsAndServices AS ProductsAndServices,
	|	CASE
	|		WHEN &UseCharacteristics
	|			THEN CustomerOrderInventory.Characteristic
	|		ELSE VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	|	END AS Characteristic,
	|	CASE
	|		WHEN VALUETYPE(CustomerOrderInventory.MeasurementUnit) = Type(Catalog.UOMClassifier)
	|			THEN CustomerOrderInventory.Quantity
	|		ELSE CustomerOrderInventory.Quantity * CustomerOrderInventory.MeasurementUnit.Factor
	|	END AS Quantity
	|FROM
	|	Document.CustomerOrder.Inventory AS CustomerOrderInventory
	|WHERE
	|	CustomerOrderInventory.Ref = &Ref
	|	AND (CustomerOrderInventory.Ref.OrderState.OrderStatus = VALUE(Enum.OrderStatuses.InProcess)
	|				AND CustomerOrderInventory.Ref.Closed = FALSE
	|			OR CustomerOrderInventory.Ref.OrderState.OrderStatus = VALUE(Enum.OrderStatuses.Completed))
	|
	|UNION ALL
	|
	|SELECT
	|	2,
	|	CustomerOrderMaterials.LineNumber,
	|	CustomerOrderMaterials.ReceiptDate,
	|	&Company,
	|	VALUE(Enum.InventoryMovementTypes.Receipt),
	|	CustomerOrderMaterials.Ref,
	|	CustomerOrderMaterials.ProductsAndServices,
	|	CASE
	|		WHEN &UseCharacteristics
	|			THEN CustomerOrderMaterials.Characteristic
	|		ELSE VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	|	END,
	|	CASE
	|		WHEN VALUETYPE(CustomerOrderMaterials.MeasurementUnit) = Type(Catalog.UOMClassifier)
	|			THEN CustomerOrderMaterials.Quantity
	|		ELSE CustomerOrderMaterials.Quantity * CustomerOrderMaterials.MeasurementUnit.Factor
	|	END
	|FROM
	|	Document.CustomerOrder.ConsumerMaterials AS CustomerOrderMaterials
	|WHERE
	|	CustomerOrderMaterials.Ref = &Ref
	|	AND CustomerOrderMaterials.Ref.OperationKind = VALUE(Enum.OperationKindsCustomerOrder.OrderForProcessing)
	|	AND (CustomerOrderMaterials.Ref.OrderState.OrderStatus = VALUE(Enum.OrderStatuses.InProcess)
	|				AND CustomerOrderMaterials.Ref.Closed = FALSE
	|			OR CustomerOrderMaterials.Ref.OrderState.OrderStatus = VALUE(Enum.OrderStatuses.Completed))
	|
	|ORDER BY
	|	Ordering,
	|	LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomerOrderMaterials.LineNumber AS LineNumber,
	|	CustomerOrderMaterials.Ref.Date AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Company AS Company,
	|	CustomerOrderMaterials.Ref AS CustomerOrder,
	|	CustomerOrderMaterials.ProductsAndServices AS ProductsAndServices,
	|	CASE
	|		WHEN &UseCharacteristics
	|			THEN CustomerOrderMaterials.Characteristic
	|		ELSE VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	|	END AS Characteristic,
	|	CustomerOrderMaterials.Ref AS SupplySource,
	|	CASE
	|		WHEN VALUETYPE(CustomerOrderMaterials.MeasurementUnit) = Type(Catalog.UOMClassifier)
	|			THEN CustomerOrderMaterials.Quantity
	|		ELSE CustomerOrderMaterials.Quantity * CustomerOrderMaterials.MeasurementUnit.Factor
	|	END AS Quantity
	|FROM
	|	Document.CustomerOrder.ConsumerMaterials AS CustomerOrderMaterials
	|WHERE
	|	CustomerOrderMaterials.Ref = &Ref
	|	AND CustomerOrderMaterials.Ref.OperationKind = VALUE(Enum.OperationKindsCustomerOrder.OrderForProcessing)
	|	AND (CustomerOrderMaterials.Ref.OrderState.OrderStatus = VALUE(Enum.OrderStatuses.InProcess)
	|				AND CustomerOrderMaterials.Ref.Closed = FALSE
	|			OR CustomerOrderMaterials.Ref.OrderState.OrderStatus = VALUE(Enum.OrderStatuses.Completed))
	|
	|ORDER BY
	|	CustomerOrderMaterials.LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomerOrderInventory.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	CustomerOrderInventory.Ref.Date AS Period,
	|	&Company AS Company,
	|	CustomerOrderInventory.Ref.StructuralUnitReserve AS StructuralUnit,
	|	CustomerOrderInventory.ProductsAndServices.InventoryGLAccount AS GLAccount,
	|	CustomerOrderInventory.ProductsAndServices AS ProductsAndServices,
	|	CASE
	|		WHEN &UseCharacteristics
	|			THEN CustomerOrderInventory.Characteristic
	|		ELSE VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	|	END AS Characteristic,
	|	CASE
	|		WHEN &UseBatches
	|			THEN CustomerOrderInventory.Batch
	|		ELSE VALUE(Catalog.ProductsAndServicesBatches.EmptyRef)
	|	END AS Batch,
	|	CASE
	|		WHEN &AccountingCCD
	|			THEN CustomerOrderInventory.CCDNo
	|		ELSE VALUE(Catalog.CCDNumbers.EmptyRef)
	|	END AS CCDNo,
	|	CASE
	|		WHEN &AccountingCCD
	|			THEN CustomerOrderInventory.CountryOfOrigin
	|		ELSE VALUE(Catalog.WorldCountries.EmptyRef)
	|	END AS CountryOfOrigin,
	|	VALUE(Document.CustomerOrder.EmptyRef) AS CustomerOrder,
	|	CustomerOrderInventory.Ref AS CustomerCorrOrder,
	|	CASE
	|		WHEN VALUETYPE(CustomerOrderInventory.MeasurementUnit) = Type(Catalog.UOMClassifier)
	|			THEN CustomerOrderInventory.Reserve
	|		ELSE CustomerOrderInventory.Reserve * CustomerOrderInventory.MeasurementUnit.Factor
	|	END AS Quantity,
	|	0 AS Amount,
	|	&InventoryReservation AS ContentOfAccountingRecord
	|INTO TemporaryTableInventory
	|FROM
	|	Document.CustomerOrder.Inventory AS CustomerOrderInventory
	|WHERE
	|	CustomerOrderInventory.Ref = &Ref
	|	AND CustomerOrderInventory.Reserve > 0
	|	AND (CustomerOrderInventory.Ref.OrderState.OrderStatus = VALUE(Enum.OrderStatuses.InProcess)
	|				AND CustomerOrderInventory.Ref.Closed = FALSE
	|			OR CustomerOrderInventory.Ref.OrderState.OrderStatus = VALUE(Enum.OrderStatuses.Completed))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(TableInventory.LineNumber) AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	TableInventory.Period AS Period,
	|	TableInventory.Company AS Company,
	|	TableInventory.StructuralUnit AS StructuralUnit,
	|	TableInventory.StructuralUnit AS StructuralUnitCorr,
	|	TableInventory.GLAccount AS GLAccount,
	|	TableInventory.GLAccount AS CorrGLAccount,
	|	TableInventory.ProductsAndServices AS ProductsAndServices,
	|	TableInventory.ProductsAndServices AS ProductsAndServicesCorr,
	|	TableInventory.Characteristic AS Characteristic,
	|	TableInventory.Characteristic AS CharacteristicCorr,
	|	TableInventory.Batch AS Batch,
	|	TableInventory.Batch AS BatchCorr,
	|	TableInventory.CustomerOrder AS CustomerOrder,
	|	TableInventory.CustomerCorrOrder AS CustomerCorrOrder,
	|	TableInventory.ContentOfAccountingRecord AS ContentOfAccountingRecord,
	|	SUM(TableInventory.Quantity) AS Quantity,
	|	SUM(TableInventory.Amount) AS Amount,
	|	FALSE AS FixedCost
	|FROM
	|	TemporaryTableInventory AS TableInventory
	|
	|GROUP BY
	|	TableInventory.Period,
	|	TableInventory.Company,
	|	TableInventory.StructuralUnit,
	|	TableInventory.GLAccount,
	|	TableInventory.ProductsAndServices,
	|	TableInventory.Characteristic,
	|	TableInventory.Batch,
	|	TableInventory.CustomerOrder,
	|	TableInventory.CustomerCorrOrder,
	|	TableInventory.ContentOfAccountingRecord,
	|	TableInventory.StructuralUnit,
	|	TableInventory.GLAccount,
	|	TableInventory.ProductsAndServices,
	|	TableInventory.Characteristic,
	|	TableInventory.Batch";
	
	Query.SetParameter("Ref", DocumentRefCustomerOrder);
	Query.SetParameter("PointInTime", New Boundary(StructureAdditionalProperties.ForPosting.PointInTime, BoundaryType.Including));
	Query.SetParameter("Company", StructureAdditionalProperties.ForPosting.Company);
	Query.SetParameter("UseCharacteristics", StructureAdditionalProperties.AccountingPolicy.UseCharacteristics);
	Query.SetParameter("UseBatches",  StructureAdditionalProperties.AccountingPolicy.UseBatches);
	Query.SetParameter("AccountingCCD",  StructureAdditionalProperties.AccountingPolicy.AccountingCCD);
	Query.SetParameter("InventoryReservation", NStr("en='Inventory reservation';ru='Резервирование запасов';vi='Lập dự phòng vật tư'"));
	
	ResultsArray = Query.ExecuteBatch();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableCustomerOrders", ResultsArray[0].Unload());
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableInventoryDemand", ResultsArray[1].Unload());
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableInventoryTransferSchedule", ResultsArray[2].Unload());
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableOrdersPlacement", ResultsArray[3].Unload());
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableInventory", ResultsArray[5].Unload());
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableProductRelease", New ValueTable);
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableAccountsReceivable", New ValueTable);
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableIncomeAndExpenses", New ValueTable);
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableIncomeAndExpensesCashMethod", New ValueTable);
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableIncomeAndExpensesUndistributed", New ValueTable);
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableIncomeAndExpensesRetained", New ValueTable);
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableInventoryInWarehouses", New ValueTable);
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableInventoryForExpenseFromWarehouses", New ValueTable);
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableInventoryReceived", New ValueTable);
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableAccrualsAndDeductions", New ValueTable);
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TablePayrollPayments", New ValueTable);
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableSales", New ValueTable);
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableManagerial", New ValueTable);
	
	// DiscountCards
	StructureAdditionalProperties.TableForRegisterRecords.Insert("SaleByDiscountCardTable", New ValueTable);
	// AutomaticDiscounts
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableAutomaticDiscountsApplied", New ValueTable);
	
	//Serial numbers - only for work order
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableSerialNumbersBalance", New ValueTable);
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableSerialNumbersGuarantees", New ValueTable);
	
	PerformanceEstimationClientServer.StartTimeMeasurement("CustomerOrderDocumentPostingGeneratingCostTable");
	
	GenerateTableInventory(DocumentRefCustomerOrder, StructureAdditionalProperties);
	
	PerformanceEstimationClientServer.StartTimeMeasurement("CustomerOrderDocumentPostingGeneratingTable");
	
	GenerateTablePaymentCalendar(DocumentRefCustomerOrder, StructureAdditionalProperties);
	GenerateTableInvoicesAndOrdersPayment(DocumentRefCustomerOrder, StructureAdditionalProperties);
	
	GenerateTableInventoryByCCD(DocumentRefCustomerOrder, StructureAdditionalProperties);
	
EndProcedure

// Initializes the tables of values that contain the data of the document table sections.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
Procedure InitializeDocumentData(DocumentRefCustomerOrder, StructureAdditionalProperties, DocumentObjectCustomerOrder) Export

	If DocumentObjectCustomerOrder.OperationKind = Enums.OperationKindsCustomerOrder.WorkOrder Then
		InitializeDocumentDataWorkOrder(DocumentRefCustomerOrder, StructureAdditionalProperties);
	Else
		InitializeDocumentDataCustomerOrder(DocumentRefCustomerOrder, StructureAdditionalProperties);
	EndIf;
	
EndProcedure

// Returns the matching kinds of customer order operations to opened forms.
//
// Parameters:
//  ListForms	 - Boolean	 - A flag showing the return of document forms or lists
Function GetOperationKindMapToForms(ListForms = False) Export
	
	CustomerOrderForms = New Map;
	
	If ListForms Then
		
		CustomerOrderForms.Insert(Enums.OperationKindsCustomerOrder.WorkOrder,			"ListFormWorkOrder");
		CustomerOrderForms.Insert(Enums.OperationKindsCustomerOrder.OrderForSale,		"ListForm");
		CustomerOrderForms.Insert(Enums.OperationKindsCustomerOrder.OrderForProcessing, "ListForm");
		
	Else
		
		CustomerOrderForms.Insert(Enums.OperationKindsCustomerOrder.WorkOrder,			"FormWorkOrder");
		CustomerOrderForms.Insert(Enums.OperationKindsCustomerOrder.OrderForSale,		"DocumentForm");
		CustomerOrderForms.Insert(Enums.OperationKindsCustomerOrder.OrderForProcessing, "DocumentForm");
		
	EndIf;
	
	Return CustomerOrderForms;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// PROCEDURES AND FUNCTIONS OF NEGATIVE BALANCE CONTROL

// Function returns batch query template.
//
Function GenerateBatchQueryTemplate()
	
	QueryText =
	Chars.LF +
	";
	|
	|////////////////////////////////////////////////////////////////////////////////"
	+ Chars.LF;
	
	Return QueryText;
	
EndFunction // GenerateBatchQueryTemplate()

// Function returns query text by the balance of InventoryInWarehouses register.
//
Function GenerateQueryTextBalancesInventoryInWarehouses()
	
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
	|	LineNumber";
	
	Return QueryText + GenerateBatchQueryTemplate();
	
EndFunction // GenerateQueryTextBalancesInventoryInWarehouses()

// Function returns query text by the balance of Inventory register.
//
Function GenerateQueryTextBalancesInventory()
	
	QueryText =
	"SELECT
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
	|	LineNumber";
	
	Return QueryText + GenerateBatchQueryTemplate();
	
EndFunction // GenerateQueryTextBalancesInventory()

// Function returns query text by the balance of CustomerOrders register.
//
Function GenerateQueryTextBalancesCustomersOrders()
	
	QueryText =
	"SELECT
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
	|	LineNumber";
	
	Return QueryText + GenerateBatchQueryTemplate();
	
EndFunction // GenerateQueryTextBalancesCustomerOrders()

// Function returns query text by the balance of InventoryDemand register.
//
Function GenerateQueryTextBalancesInventoryDemand()
	
	QueryText =
	"SELECT
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
	|	LineNumber";
	
	Return QueryText + GenerateBatchQueryTemplate();
	
EndFunction // GenerateQueryTextBalancesInventoryDemand()

// Function returns query text by the balance of AccountsReceivable register.
//
Function GenerateQueryTextBalancesAccountsReceivable()
	
	QueryText =
	"SELECT
	|	RegisterRecordsAccountsReceivableChange.LineNumber AS LineNumber,
	|	RegisterRecordsAccountsReceivableChange.Company AS CompanyPresentation,
	|	RegisterRecordsAccountsReceivableChange.Counterparty AS CounterpartyPresentation,
	|	RegisterRecordsAccountsReceivableChange.Contract AS ContractPresentation,
	|	RegisterRecordsAccountsReceivableChange.Contract.SettlementsCurrency AS CurrencyPresentation,
	|	RegisterRecordsAccountsReceivableChange.Document AS DocumentPresentation,
	|	RegisterRecordsAccountsReceivableChange.Order AS OrderPresentation,
	|	RegisterRecordsAccountsReceivableChange.SettlementsType AS CalculationsTypesPresentation,
	|	FALSE AS RegisterRecordsOfCashDocuments,
	|	RegisterRecordsAccountsReceivableChange.SumBeforeWrite AS SumBeforeWrite,
	|	RegisterRecordsAccountsReceivableChange.AmountOnWrite AS AmountOnWrite,
	|	RegisterRecordsAccountsReceivableChange.AmountChange AS AmountChange,
	|	RegisterRecordsAccountsReceivableChange.AmountCurBeforeWrite AS AmountCurBeforeWrite,
	|	RegisterRecordsAccountsReceivableChange.SumCurOnWrite AS SumCurOnWrite,
	|	RegisterRecordsAccountsReceivableChange.SumCurChange AS SumCurChange,
	|	RegisterRecordsAccountsReceivableChange.SumCurOnWrite - ISNULL(AccountsReceivableBalances.AmountCurBalance, 0) AS AdvanceAmountsReceived,
	|	RegisterRecordsAccountsReceivableChange.SumCurChange + ISNULL(AccountsReceivableBalances.AmountCurBalance, 0) AS AmountOfOutstandingDebt,
	|	ISNULL(AccountsReceivableBalances.AmountBalance, 0) AS AmountBalance,
	|	ISNULL(AccountsReceivableBalances.AmountCurBalance, 0) AS AmountCurBalance,
	|	RegisterRecordsAccountsReceivableChange.SettlementsType AS SettlementsType
	|FROM
	|	RegisterRecordsAccountsReceivableChange AS RegisterRecordsAccountsReceivableChange
	|		INNER JOIN AccumulationRegister.AccountsReceivable.Balance(&ControlTime, ) AS AccountsReceivableBalances
	|		ON RegisterRecordsAccountsReceivableChange.Company = AccountsReceivableBalances.Company
	|			AND RegisterRecordsAccountsReceivableChange.Counterparty = AccountsReceivableBalances.Counterparty
	|			AND RegisterRecordsAccountsReceivableChange.Contract = AccountsReceivableBalances.Contract
	|			AND RegisterRecordsAccountsReceivableChange.Document = AccountsReceivableBalances.Document
	|			AND RegisterRecordsAccountsReceivableChange.Order = AccountsReceivableBalances.Order
	|			AND RegisterRecordsAccountsReceivableChange.SettlementsType = AccountsReceivableBalances.SettlementsType
	|			AND (CASE
	|				WHEN RegisterRecordsAccountsReceivableChange.SettlementsType = VALUE(Enum.SettlementsTypes.Advance)
	|					THEN ISNULL(AccountsReceivableBalances.AmountCurBalance, 0) > 0
	|				ELSE ISNULL(AccountsReceivableBalances.AmountCurBalance, 0) < 0
	|			END)
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText + GenerateBatchQueryTemplate();
	
EndFunction // GenerateQueryTextBalancesAccountsReceivable()

Function GenerateQueryTextBalancesSerialNumbers()
	
	RequestText =
	"SELECT
	|	RegisterRecordsSerialNumbersChange.LineNumber AS LineNumber,
	|	RegisterRecordsSerialNumbersChange.SerialNumber AS SerialNumberPresentation,
	|	RegisterRecordsSerialNumbersChange.StructuralUnit AS StructuralUnitPresentation,
	|	RegisterRecordsSerialNumbersChange.ProductsAndServices AS ProductsAndServicesPresentation,
	|	RegisterRecordsSerialNumbersChange.Characteristic AS CharacteristicPresentation,
	|	RegisterRecordsSerialNumbersChange.Batch AS BatchPresentation,
	|	RegisterRecordsSerialNumbersChange.Cell AS CellPresentation,
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
	
	Return RequestText + GenerateBatchQueryTemplate();
	
EndFunction // GenerateQueryTextBalancesSerialNumbers()

// Controls the occurrence of negative balances.
//
Procedure RunControl(DocumentObjectCustomerOrder, AdditionalProperties, Cancel, PostingDelete = False) Export
	
	If Not SmallBusinessServer.RunBalanceControl() Then
		Return;
	EndIf;
	
	StructureTemporaryTables = AdditionalProperties.ForPosting.StructureTemporaryTables;
	
	// If temporary tables "RegisterRecordsInventoryInWarehousesChange",
	// "RegisterRecordsInventoryChange" "RegisterRecordsCustomerOrdersChange",
	// "RegisterRecordsInventoryDemandChange", "RegisterRecordsAccountsReceivableChange" contain records, execute
	// the control of balances.
		
	If StructureTemporaryTables.RegisterRecordsInventoryInWarehousesChange
		OR StructureTemporaryTables.RegisterRecordsInventoryChange
		OR StructureTemporaryTables.RegisterRecordsCustomerOrdersChange
		OR StructureTemporaryTables.RegisterRecordsInventoryDemandChange
		OR StructureTemporaryTables.RegisterRecordsAccountsReceivableChange
		OR StructureTemporaryTables.RegisterRecordsSerialNumbersChange Then
		
		Query = New Query;
		Query.Text = GenerateQueryTextBalancesInventoryInWarehouses() // [0]
		+ GenerateQueryTextBalancesInventory() // [1]
		+ GenerateQueryTextBalancesCustomersOrders() // [2]
		+ GenerateQueryTextBalancesInventoryDemand() // [3]
		+ GenerateQueryTextBalancesAccountsReceivable() // [4]
		+ GenerateQueryTextBalancesSerialNumbers(); // [5]
		
		Query.TempTablesManager = StructureTemporaryTables.TempTablesManager;
		Query.SetParameter("ControlTime", AdditionalProperties.ForPosting.ControlTime);
		
		ResultsArray = Query.ExecuteBatch();
		
		// Negative balance of inventory in the warehouse.
		If Not ResultsArray[0].IsEmpty() Then
			QueryResultSelection = ResultsArray[0].Select();
			SmallBusinessServer.ShowMessageAboutPostingToInventoryInWarehousesRegisterErrors(DocumentObjectCustomerOrder, QueryResultSelection, Cancel);
		EndIf;
		
		// Negative balance of inventory.
		If Not ResultsArray[1].IsEmpty() Then
			QueryResultSelection = ResultsArray[1].Select();
			SmallBusinessServer.ShowMessageAboutPostingToInventoryRegisterErrors(DocumentObjectCustomerOrder, QueryResultSelection, Cancel);
		EndIf;
		
		// Negative balance on customer order.
		If Not ResultsArray[2].IsEmpty() Then
			QueryResultSelection = ResultsArray[2].Select();
			SmallBusinessServer.ShowMessageAboutPostingToCustomerOrdersRegisterErrors(DocumentObjectCustomerOrder, QueryResultSelection, Cancel);
		EndIf;
		
		// Negative balance of need for inventory.
		If Not ResultsArray[3].IsEmpty() Then
			QueryResultSelection = ResultsArray[3].Select();
			SmallBusinessServer.ShowMessageAboutPostingToInventoryDemandRegisterErrors(DocumentObjectCustomerOrder, QueryResultSelection, Cancel);
		EndIf;
		
		// Negative balance on accounts receivable.
		If Not ResultsArray[4].IsEmpty() Then
			QueryResultSelection = ResultsArray[4].Select();
			SmallBusinessServer.ShowMessageAboutPostingToAccountsReceivableRegisterErrors(DocumentObjectCustomerOrder, QueryResultSelection, Cancel);
		EndIf;
		
		// Negative balance of serial numbers in the warehouse.
		If Not ResultsArray[5].IsEmpty() Then
			QueryResultSelection = ResultsArray[5].Select();
			SmallBusinessServer.ShowMessageAboutPostingSerialNumbersRegisterErrors(DocumentObjectCustomerOrder, QueryResultSelection, Cancel);
		EndIf;
		
	EndIf;
	
EndProcedure // RunControl()

////////////////////////////////////////////////////////////////////////////////
// PROCEDURES AND FUNCTIONS of PAYROLL ACCRUAL

//Calculates accruals amount for assignee row
//
//
Function ComputeAccrualValueByRowAtServer(WorkCoefficients, WorkAmount, LPF, AmountLPF, AccrualDeductionKind, Size) Export
	
	If AccrualDeductionKind = Catalogs.AccrualAndDeductionKinds.FixedAmount Then
		
		Return Size;
		
	ElsIf AccrualDeductionKind = Catalogs.AccrualAndDeductionKinds.PieceRatePayment Then
		
		Return WorkCoefficients * Size * (LPF / AmountLPF);
		
	ElsIf AccrualDeductionKind = Catalogs.AccrualAndDeductionKinds.PieceRatePaymentPercent Then
		
		Return (WorkAmount / 100 * Size) * (LPF / AmountLPF);
		
	EndIf;
	
EndFunction // CalculateAccrualValueByRowOnServer()

// Returns the row from TS Works to specified key
//
// TabularSectionWorks - TS of Work, wob order document;
// ConnectionKey - ConnectionKey attribute value;
//
Function GetRowWorksByConnectionKey(TabularSectionWorks, ConnectionKey) Export
	
	ArrayFoundStrings = TabularSectionWorks.FindRows(New Structure("ConnectionKey", ConnectionKey));
	
	Return ?(ArrayFoundStrings.Count() <> 1, Undefined, ArrayFoundStrings[0]);
	
EndFunction // GetWorkByConnectionKeyRow()

// Returns the rows of Performers TS by received connection key
//
// TabularSectionPerformers - TS Performers of Work order document;
// ConnectionKey - ConnectionKey attribute value;
//
Function GetRowsPerformersByConnectionKey(TabularSectionPerformers, ConnectionKey) Export
	
	Return TabularSectionPerformers.FindRows(New Structure("ConnectionKey", ConnectionKey));
	
EndFunction // GetPerformersByConnectionKeyRows()

// Returns the amount of Performers LPC included in the accrual for specified work
// 
// TabularSectionPerformers - TS Performers of Work order document;
// ConnectionKey - ConnectionKey attribute value;
//
Function ComputeLPFSumByConnectionKey(TabularSectionPerformers, ConnectionKey) Export
	
	If Not ValueIsFilled(ConnectionKey) Then
		
		Return 1; 
		
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	
	Query.Text = 
	"SELECT *
	|INTO CWT_Performers
	|FROM
	|	&TabularSection AS CustomerOrderPerformers
	| WHERE CustomerOrderPerformers.ConnectionKey = &ConnectionKey";
	
	Query.SetParameter("ConnectionKey", ConnectionKey);
	Query.SetParameter("TabularSection", TabularSectionPerformers.Unload());
	Query.Execute();
	
	Query.Text = 
	"SELECT
	|	SUM(CWT_Performers.LPF) AS AmountLPF
	|FROM
	|	CWT_Performers AS CWT_Performers
	|WHERE 
	|	CWT_Performers.AccrualDeductionKind <> Value(Catalog.AccrualAndDeductionKinds.FixedAmount)";
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then 
		
		Return 1;
		
	EndIf;
		
	Selection = QueryResult.Select();
	Selection.Next();
	
	Return ?(Selection.AmountLPF = 0, 1, Selection.AmountLPF);
	
EndFunction // CalculateLPCSumByConnectionKey()

Function ArePerformersWithEmptyAccrualSum(Performers) Export
	
	Var Errors;
	MessageTextTemplate = NStr("en='Accrual amount for employee %1 in row %2 is specified incorrectly.';ru='Не верно указана сумма начисления для сотрудника %1 в строке %2.';vi='Đã chỉ ra sai số tiền tính lương đối với người lao động %1 trong dòng %2.'");
	
	For Each Performer IN Performers Do
		
		If Performer.AccruedAmount = 0 Then
			
			SingleErrorText = 
				StringFunctionsClientServer.SubstituteParametersInString(MessageTextTemplate, Performer.Employee.Description, Performer.LineNumber);
			
			CommonUseClientServer.AddUserError(
				Errors, 
				"Object.Performers[%1].Employee", 
				SingleErrorText, 
				Undefined, 
				Performer.LineNumber, 
				);
			
		EndIf;
		
	EndDo;
	
	If ValueIsFilled(Errors) Then
		
		CommonUseClientServer.ShowErrorsToUser(Errors);
		Return True;
		
	EndIf;
	
	Return False;
	
EndFunction

///////////////////////////////////////////////////////////////////////////////
// FILLING PROCEDURES

// Checks the possibility of input on the basis.
//
Procedure CheckAbilityOfEnteringByCustomerOrder(FillingData, AttributeValues) Export
	
	If AttributeValues.Property("Posted") Then
		If Not AttributeValues.Posted Then
			ErrorText = NStr("en='Document %Document% is not posted. Cannot use the ""input on basis"" method for an unposted document.';ru='Документ %Документ% не проведен. Ввод на основании непроведенного документа запрещен.';vi='Chứng từ %Document% chưa được kết chuyển. Cấm nhập trên cơ sở chứng từ chưa kết chuyển.'");
			ErrorText = StrReplace(ErrorText, "%Document%", FillingData);
			Raise ErrorText;
		EndIf;
	EndIf;
	
	If AttributeValues.Property("Closed") Then
		If (AttributeValues.Property("WorkOrderReturn") AND Constants.UseCustomerOrderStates.Get())
			OR Not AttributeValues.Property("WorkOrderReturn") Then
			If AttributeValues.Closed Then
				ErrorText = NStr("en='The %Document% document is closed (completed). Cannot enter on the basis of the closed order.';ru='Документ %Document% закрыт (выполнен). Ввод на основании закрытого заказа запрещен.';vi='Chứng từ %Document% đã đóng (đã thực hiện). Cấm nhập trên cơ sở đơn hàng đã đóng.'");
				ErrorText = StrReplace(ErrorText, "%Document%", FillingData);
				Raise ErrorText;
			EndIf;
		EndIf;
	EndIf;
	
	If AttributeValues.Property("OrderState") Then
		If AttributeValues.OrderState.OrderStatus = Enums.OrderStatuses.Open Then
			ErrorText = NStr("en='The %Document% document in the %OrderState% state. Cannot enter on the basis.';ru='Документ %Document% в состоянии %OrderState%. Ввод на основании запрещен.';vi='Chứng từ %Document% trong trạng thái %OrderState%. Cấm nhập trên cơ sở.'");
			ErrorText = StrReplace(ErrorText, "%Document%", FillingData);
			ErrorText = StrReplace(ErrorText, "%OrderState%", AttributeValues.OrderState);
			Raise ErrorText;
		EndIf;
		If AttributeValues.Property("OperationKind") Then
			If AttributeValues.OperationKind = Enums.OperationKindsCustomerOrder.WorkOrder Then
				If AttributeValues.Property("WorkOrderReturn") Then
					If AttributeValues.OrderState.OrderStatus <> Enums.OrderStatuses.Completed Then
						ErrorText = NStr("en='The %Document% document in the %OrderState% state. Cannot enter the return from the customer on the basis.';ru='Документ %Document% в состоянии %OrderState%. Ввод возврата от покупателя на основании запрещен.';vi='Chứng từ %Document% trong trạng thái %OrderState%. Cấm nhập hàng bán bị trả lại trên cơ sở.'");
						ErrorText = StrReplace(ErrorText, "%Document%", FillingData);
						ErrorText = StrReplace(ErrorText, "%OrderState%", AttributeValues.OrderState);
						Raise ErrorText;
					EndIf;
				ElsIf AttributeValues.OrderState.OrderStatus <> Enums.OrderStatuses.InProcess Then
					ErrorText = NStr("en='The %Document% document in the %OrderState% state. Cannot enter on the basis.';ru='Документ %Document% в состоянии %OrderState%. Ввод на основании запрещен.';vi='Chứng từ %Document% trong trạng thái %OrderState%. Cấm nhập trên cơ sở.'");
					ErrorText = StrReplace(ErrorText, "%Document%", FillingData);
					ErrorText = StrReplace(ErrorText, "%OrderState%", AttributeValues.OrderState);
					Raise ErrorText;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure // CheckPossibilityToInputBasedOnCustomerOrder()

#Region EventsHandlers

#EndRegion

#Region PrintInterface

// Document printing procedure.
//
Function PrintCustomerOrder(ObjectsArray, PrintObjects, TemplateName)
	
	Var Errors;
	
	UseVAT	= GetFunctionalOption("UseVAT");
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersKey = "PrintParameters_CustomerOrder";
	
	Query = New Query();
	Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.Text = 
	"SELECT
	|	CustomerOrder.Ref AS Ref,
	|	CustomerOrder.Number AS DocumentNumber,
	|	CustomerOrder.Date AS DocumentDate,
	|	CustomerOrder.Company AS Company,
	|	CustomerOrder.Counterparty AS Counterparty,
	|	CustomerOrder.AmountIncludesVAT AS AmountIncludesVAT,
	|	CustomerOrder.DocumentCurrency AS DocumentCurrency,
	|	CustomerOrder.Responsible,
	|	CustomerOrder.Company.Prefix AS Prefix,
	|	CustomerOrder.Works.(
	|		LineNumber AS LineNumber,
	|		CASE
	|			WHEN (CAST(CustomerOrder.Works.ProductsAndServices.DescriptionFull AS String(1000))) = """"
	|				THEN CustomerOrder.Works.ProductsAndServices.Description
	|			ELSE CAST(CustomerOrder.Works.ProductsAndServices.DescriptionFull AS String(1000))
	|		END AS InventoryItem,
	|		ProductsAndServices.SKU AS SKU,
	|		ProductsAndServices.MeasurementUnit.Description AS MeasurementUnit,
	|		CustomerOrder.Works.Quantity * CustomerOrder.Works.Factor * CustomerOrder.Works.Multiplicity AS Quantity,
	|		Price AS Price,
	|		Amount AS Amount,
	|		VATAmount AS VATAmount,
	|		Total AS Total,
	|		Characteristic,
	|		DiscountMarkupPercent,
	|		CASE
	|			WHEN CustomerOrder.Works.DiscountMarkupPercent <> 0
	|					OR CustomerOrder.Works.AutomaticDiscountAmount <> 0
	|				THEN 1
	|			ELSE 0
	|		END AS IsDiscount,
	|		Content,
	|		Ref.Start AS ShipmentDate,
	|		AutomaticDiscountAmount
	|	),
	|	CustomerOrder.Inventory.(
	|		LineNumber AS LineNumber,
	|		CASE
	|			WHEN (CAST(CustomerOrder.Inventory.ProductsAndServices.DescriptionFull AS String(1000))) = """"
	|				THEN CustomerOrder.Inventory.ProductsAndServices.Description
	|			ELSE CAST(CustomerOrder.Inventory.ProductsAndServices.DescriptionFull AS String(1000))
	|		END AS InventoryItem,
	|		ProductsAndServices.SKU AS SKU,
	|		MeasurementUnit.Description AS UnitOfMeasure,
	|		Quantity AS Quantity,
	|		Price AS Price,
	|		Amount AS Amount,
	|		VATAmount AS VATAmount,
	|		Total AS Total,
	|		CASE
	|			WHEN CustomerOrder.Inventory.Ref.OperationKind = VALUE(Enum.OperationKindsCustomerOrder.WorkOrder)
	|				THEN CustomerOrder.Inventory.Ref.Start
	|			ELSE CustomerOrder.Inventory.ShipmentDate
	|		END AS ShipmentDate,
	|		Characteristic,
	|		Content,
	|		DiscountMarkupPercent,
	|		CASE
	|			WHEN CustomerOrder.Inventory.DiscountMarkupPercent <> 0
	|					OR CustomerOrder.Inventory.AutomaticDiscountAmount <> 0
	|				THEN 1
	|			ELSE 0
	|		END AS IsDiscount,
	|		AutomaticDiscountAmount
	|	)
	|FROM
	|	Document.CustomerOrder AS CustomerOrder
	|WHERE
	|	CustomerOrder.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Ref,
	|	LineNumber";
	
	Header = Query.Execute().Select();
	
	FirstDocument = True;
	
	While Header.Next() Do
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		FirstDocument = False;
		
		FirstLineNumber = SpreadsheetDocument.TableHeight + 1;
		
		SpreadsheetDocument.PrintParametersName = "PRINT_PARAMETERS_CustomerOrder_CustomerOrder";
		
		Template = PrintManagement.PrintedFormsTemplate("Document.CustomerOrder.PF_MXL_CustomerOrderTemplate");
		
		InfoAboutCompany = SmallBusinessServer.InfoAboutLegalEntityIndividual(Header.Company, Header.DocumentDate, ,);
		InfoAboutCounterparty = SmallBusinessServer.InfoAboutLegalEntityIndividual(Header.Counterparty, Header.DocumentDate, ,);
		
		If Template.Areas.Find("TitleWithLogo") <> Undefined
			AND Template.Areas.Find("TitleWithoutLogo") <> Undefined Then
			
			If ValueIsFilled(Header.Company.LogoFile) Then
				
				TemplateArea = Template.GetArea("TitleWithLogo");
				TemplateArea.Parameters.Fill(Header);
				
				PictureData = AttachedFiles.GetFileBinaryData(Header.Company.LogoFile);
				If ValueIsFilled(PictureData) Then
					
					TemplateArea.Drawings.Logo.Picture = New Picture(PictureData);
					
				EndIf;
				
			Else // If images are not selected, print regular header
				
				TemplateArea = Template.GetArea("TitleWithoutLogo");
				TemplateArea.Parameters.Fill(Header);
				
			EndIf;
			
			SpreadsheetDocument.Put(TemplateArea);
			
		Else
			
			MessageText = NStr("en='ATTENTION! Maybe, custom template is being used. Default procedures of account printing may work incorrectly.';ru='ВНИМАНИЕ! Возможно используется пользовательский макет. Штатный механизм печати счетов может работать некоректно.';vi='CHÚ Ý! Có thể sử dụng khuôn mẫu tự tạo. Cơ chế thông thường khi in hóa đơn có thể hoạt động không chính xác.'");
			CommonUseClientServer.AddUserError(Errors, , MessageText, Undefined);
			
		EndIf;
		
		TemplateArea = Template.GetArea("InvoiceHeaderVendor");
		
		TemplateArea.Parameters.Fill(Header);
		
		VendorPresentation	= SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCompany, "FullDescr");
		
		TemplateArea.Parameters.VendorPresentation	= VendorPresentation;
		TemplateArea.Parameters.VendorAddress		= SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCompany, "LegalAddress");
		TemplateArea.Parameters.VendorPhoneFax		= SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCompany, "PhoneNumbers,Fax");
		TemplateArea.Parameters.VendorEmail			= SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCompany, "Email");
		
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("InvoiceHeaderCustomer");
		
		TemplateArea.Parameters.CustomerPresentation	= SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCounterparty, "FullDescr");;
		TemplateArea.Parameters.CustomerAddress			= SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCounterparty, "LegalAddress");;
		TemplateArea.Parameters.CustomerPhoneFax		= SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCounterparty, "PhoneNumbers,Fax");;
		
		SpreadsheetDocument.Put(TemplateArea);
		
		LinesSelectionInventory = Header.Inventory.Select();
		SelectionRowsWork = Header.Works.Select();
		
		AreDiscounts = (Header.Inventory.Unload().Total("IsDiscount") + Header.Works.Unload().Total("IsDiscount")) <> 0;
		
		If AreDiscounts Then
			
			TemplateArea = Template.GetArea("TableHeaderWithDiscount");
			TemplateArea.Parameters.Currency	= Header.DocumentCurrency;
			SpreadsheetDocument.Put(TemplateArea);
			TemplateArea = Template.GetArea("TableRowWithDiscount");
			
		Else
			
			TemplateArea = Template.GetArea("TableHeader");
			TemplateArea.Parameters.Currency	= Header.DocumentCurrency;
			SpreadsheetDocument.Put(TemplateArea);
			TemplateArea = Template.GetArea("TableRow");
			
		EndIf;
		
		Amount		= 0;
		VATAmount	= 0;
		Total		= 0;
		Quantity	= 0;
		
		While SelectionRowsWork.Next() Do
			TemplateArea.Parameters.Fill(SelectionRowsWork);
			
			If ValueIsFilled(SelectionRowsWork.Content) Then
				TemplateArea.Parameters.ProductDescription = SelectionRowsWork.Content;
			Else
				TemplateArea.Parameters.ProductDescription = SmallBusinessServer.GetProductsAndServicesPresentationForPrinting(SelectionRowsWork.InventoryItem, 
																	SelectionRowsWork.Characteristic, SelectionRowsWork.SKU);
			EndIf;
																
			If AreDiscounts Then
				If SelectionRowsWork.DiscountMarkupPercent = 100 Then
					Discount = SelectionRowsWork.Price * SelectionRowsWork.Quantity;
					TemplateArea.Parameters.Discount         = Discount;
					TemplateArea.Parameters.AmountWithoutDiscount = Discount;
				ElsIf SelectionRowsWork.DiscountMarkupPercent = 0 AND SelectionRowsWork.AutomaticDiscountAmount = 0 Then
					TemplateArea.Parameters.Discount         = 0;
					TemplateArea.Parameters.AmountWithoutDiscount = SelectionRowsWork.Amount;
				Else
					Discount = SelectionRowsWork.Quantity * SelectionRowsWork.Price - SelectionRowsWork.Amount; // AutomaticDiscounts
					TemplateArea.Parameters.Discount         = Discount;
					TemplateArea.Parameters.AmountWithoutDiscount = SelectionRowsWork.Amount + Discount;
				EndIf;
			EndIf;
			
			SpreadsheetDocument.Put(TemplateArea);
			
			Amount		= Amount		+ SelectionRowsWork.Amount;
			VATAmount	= VATAmount	+ SelectionRowsWork.VATAmount;
			Total		= Total		+ SelectionRowsWork.Total;
			Quantity	= Quantity+ 1;
			
		EndDo;
		
		While LinesSelectionInventory.Next() Do
			TemplateArea.Parameters.Fill(LinesSelectionInventory);
			
			If ValueIsFilled(LinesSelectionInventory.Content) Then
				TemplateArea.Parameters.ProductDescription = LinesSelectionInventory.Content;
			Else
				TemplateArea.Parameters.ProductDescription = SmallBusinessServer.GetProductsAndServicesPresentationForPrinting(LinesSelectionInventory.InventoryItem, 
																	LinesSelectionInventory.Characteristic, LinesSelectionInventory.SKU);
			EndIf;
																
			If AreDiscounts Then
				If LinesSelectionInventory.DiscountMarkupPercent = 100 Then
					Discount = LinesSelectionInventory.Price * LinesSelectionInventory.Quantity;
					TemplateArea.Parameters.Discount         = Discount;
					TemplateArea.Parameters.AmountWithoutDiscount = Discount;
				ElsIf LinesSelectionInventory.DiscountMarkupPercent = 0 AND LinesSelectionInventory.AutomaticDiscountAmount = 0 Then
					TemplateArea.Parameters.Discount         = 0;
					TemplateArea.Parameters.AmountWithoutDiscount = LinesSelectionInventory.Amount;
				Else
					Discount = LinesSelectionInventory.Quantity * LinesSelectionInventory.Price - LinesSelectionInventory.Amount; // AutomaticDiscounts
					TemplateArea.Parameters.Discount         = Discount;
					TemplateArea.Parameters.AmountWithoutDiscount = LinesSelectionInventory.Amount + Discount;
				EndIf;
			EndIf;
			
			SpreadsheetDocument.Put(TemplateArea);
			
			Amount		= Amount		+ LinesSelectionInventory.Amount;
			VATAmount	= VATAmount	+ LinesSelectionInventory.VATAmount;
			Total		= Total		+ LinesSelectionInventory.Total;
			Quantity	= Quantity+ 1;
			
		EndDo;
		
		TemplateArea = Template.GetArea("Total");
		TemplateArea.Parameters.Total		= SmallBusinessServer.AmountsFormat(Amount);
		TemplateArea.Parameters.Currency	= Header.DocumentCurrency;
		SpreadsheetDocument.Put(TemplateArea);
		
		If UseVAT Then
			
			TemplateArea = Template.GetArea("TotalVAT");
			If VATAmount = 0 Then
				TemplateArea.Parameters.VAT = NStr("en='Without tax (VAT)';vi='Không bao gồm thuế GTGT '");
				TemplateArea.Parameters.TotalVAT = "-";
			Else
				TemplateArea.Parameters.VAT = ?(Header.AmountIncludesVAT, NStr("en='Including VAT:';vi='Gồm thuế GTGT:';"), NStr("en='VAT Amount:';vi='Thuế GTGT:';"));
				TemplateArea.Parameters.TotalVAT = SmallBusinessServer.AmountsFormat(VATAmount);
			EndIf; 
			SpreadsheetDocument.Put(TemplateArea);
			
		EndIf;
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, FirstLineNumber, PrintObjects, Header.Ref);
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;	

EndFunction // PrintForm()

// Document printing procedure.
//
Function PrintProformaInvoice(ObjectsArray, PrintObjects, TemplateName, Signature = False) Export
	
	Var Errors;
	
	UseVAT	= GetFunctionalOption("UseVAT");
	
	SpreadsheetDocument = New SpreadsheetDocument;
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	CustomerOrder.Ref AS Ref,
	|	CustomerOrder.AmountIncludesVAT AS AmountIncludesVAT,
	|	CustomerOrder.DocumentCurrency AS DocumentCurrency,
	|	CustomerOrder.Date AS DocumentDate,
	|	CustomerOrder.Number AS DocumentNumber,
	|	CustomerOrder.BankAccount AS BankAccount,
	|	CustomerOrder.Counterparty AS Counterparty,
	|	CustomerOrder.Company AS Company,
	|	CustomerOrder.Company.Prefix AS Prefix,
	|	CustomerOrder.Works.(
	|		CASE
	|			WHEN (CAST(CustomerOrder.Works.ProductsAndServices.DescriptionFull AS String(1000))) = """"
	|				THEN CustomerOrder.Works.ProductsAndServices.Description
	|			ELSE CAST(CustomerOrder.Works.ProductsAndServices.DescriptionFull AS String(1000))
	|		END AS InventoryItem,
	|		ProductsAndServices.SKU AS SKU,
	|		ProductsAndServices.MeasurementUnit AS UnitOfMeasure,
	|		Price AS Price,
	|		Amount AS Amount,
	|		VATAmount AS VATAmount,
	|		Total AS Total,
	|		CustomerOrder.Works.Quantity * CustomerOrder.Works.Factor * CustomerOrder.Works.Multiplicity AS Quantity,
	|		Characteristic,
	|		Content,
	|		DiscountMarkupPercent,
	|		CASE
	|			WHEN CustomerOrder.Works.DiscountMarkupPercent <> 0
	|					OR CustomerOrder.Works.AutomaticDiscountAmount <> 0
	|				THEN 1
	|			ELSE 0
	|		END AS IsDiscount,
	|		LineNumber AS LineNumber,
	|		AutomaticDiscountAmount
	|	),
	|	CustomerOrder.Inventory.(
	|		CASE
	|			WHEN (CAST(CustomerOrder.Inventory.ProductsAndServices.DescriptionFull AS String(1000))) = """"
	|				THEN CustomerOrder.Inventory.ProductsAndServices.Description
	|			ELSE CAST(CustomerOrder.Inventory.ProductsAndServices.DescriptionFull AS String(1000))
	|		END AS InventoryItem,
	|		ProductsAndServices.SKU AS SKU,
	|		MeasurementUnit AS UnitOfMeasure,
	|		Price AS Price,
	|		Amount AS Amount,
	|		VATAmount AS VATAmount,
	|		Total AS Total,
	|		Quantity AS Quantity,
	|		Characteristic,
	|		Content,
	|		DiscountMarkupPercent,
	|		CASE
	|			WHEN CustomerOrder.Inventory.DiscountMarkupPercent <> 0
	|					OR CustomerOrder.Inventory.AutomaticDiscountAmount <> 0
	|				THEN 1
	|			ELSE 0
	|		END AS IsDiscount,
	|		LineNumber AS LineNumber,
	|		AutomaticDiscountAmount
	|	),
	|	CustomerOrder.PaymentCalendar.(
	|		PaymentPercentage,
	|		PaymentAmount,
	|		PayVATAmount
	|	)
	|FROM
	|	Document.CustomerOrder AS CustomerOrder
	|WHERE
	|	CustomerOrder.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Ref,
	|	LineNumber";
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	
	Header = Query.Execute().Select();
	
	FirstDocument = True;
	
	While Header.Next() Do
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		FirstDocument = False;
		
		FirstLineNumber = SpreadsheetDocument.TableHeight + 1;
		
		LinesSelectionInventory = Header.Inventory.Select();
		SelectionRowsWork = Header.Works.Select();
		PrepaymentTable = Header.PaymentCalendar.Unload(); 
				
		SpreadsheetDocument.PrintParametersName = "PARAMETERS_PRINT_" + TemplateName + "_" + TemplateName;
		
		Template = PrintManagement.PrintedFormsTemplate("Document.CustomerOrder.PF_MXL_" + TemplateName);
		
		InfoAboutCompany = SmallBusinessServer.InfoAboutLegalEntityIndividual(Header.Company, Header.DocumentDate, ,Header.BankAccount);
		InfoAboutCounterparty = SmallBusinessServer.InfoAboutLegalEntityIndividual(Header.Counterparty, Header.DocumentDate, ,);
		
		//If user template is used - there were no such sections
		If Template.Areas.Find("TitleWithLogo") <> Undefined
			AND Template.Areas.Find("TitleWithoutLogo") <> Undefined Then
			
			If ValueIsFilled(Header.Company.LogoFile) Then
				
				TemplateArea = Template.GetArea("TitleWithLogo");
				TemplateArea.Parameters.Fill(Header);
				
				PictureData = AttachedFiles.GetFileBinaryData(Header.Company.LogoFile);
				If ValueIsFilled(PictureData) Then
					
					TemplateArea.Drawings.Logo.Picture = New Picture(PictureData);
					
				EndIf;
				
			Else // If images are not selected, print regular header
				
				TemplateArea = Template.GetArea("TitleWithoutLogo");
				TemplateArea.Parameters.Fill(Header);
				
			EndIf;
			
			SpreadsheetDocument.Put(TemplateArea);
			
		Else
			
			MessageText = NStr("en='ATTENTION! Maybe, custom template is being used. Default procedures of account printing may work incorrectly.';ru='ВНИМАНИЕ! Возможно используется пользовательский макет. Штатный механизм печати счетов может работать некоректно.';vi='CHÚ Ý! Có thể sử dụng khuôn mẫu tự tạo. Cơ chế thông thường khi in hóa đơn có thể hoạt động không chính xác.'");
			CommonUseClientServer.AddUserError(Errors, , MessageText, Undefined);
			
		EndIf;
		
		TemplateArea = Template.GetArea("InvoiceHeaderVendor");
		
		TemplateArea.Parameters.Fill(Header);
		
		VendorPresentation	= SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCompany, "FullDescr");
		
		TemplateArea.Parameters.VendorPresentation	= VendorPresentation;
		TemplateArea.Parameters.VendorAddress		= SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCompany, "LegalAddress");
		TemplateArea.Parameters.VendorPhoneFax		= SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCompany, "PhoneNumbers,Fax");
		TemplateArea.Parameters.VendorEmail			= SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCompany, "Email");
		
		TemplateArea.Parameters.BankPresentation	=  SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCompany, "Bank", False);
		TemplateArea.Parameters.BankAccountNumber	=  SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCompany, "AccountNo", False);
		TemplateArea.Parameters.BankSWIFT			=  SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCompany, "SWIFT", False);
		
		CorrespondentText	= SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCompany, "CorrespondentText", False);
		TemplateArea.Parameters.BankBeneficiary		=  ?(ValueIsFilled(CorrespondentText), CorrespondentText, VendorPresentation);
		
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("InvoiceHeaderCustomer");
		
		TemplateArea.Parameters.CustomerPresentation	= SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCounterparty, "FullDescr");;
		TemplateArea.Parameters.CustomerAddress			= SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCounterparty, "LegalAddress");;
		TemplateArea.Parameters.CustomerPhoneFax		= SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCounterparty, "PhoneNumbers,Fax");;
		
		SpreadsheetDocument.Put(TemplateArea);

		AreDiscounts = (Header.Inventory.Unload().Total("IsDiscount") + Header.Works.Unload().Total("IsDiscount")) <> 0;
		
		If AreDiscounts Then
			
			TemplateArea = Template.GetArea("TableHeaderWithDiscount");
			TemplateArea.Parameters.Currency	= Header.DocumentCurrency;
			SpreadsheetDocument.Put(TemplateArea);
			TemplateArea = Template.GetArea("TableRowWithDiscount");
			
		Else
			
			TemplateArea = Template.GetArea("TableHeader");
			TemplateArea.Parameters.Currency	= Header.DocumentCurrency;
			SpreadsheetDocument.Put(TemplateArea);
			TemplateArea = Template.GetArea("TableRow");
			
		EndIf;
		
		Amount		= 0;
		VATAmount	= 0;
		Total		= 0;
		Quantity	= 0;

		While SelectionRowsWork.Next() Do
			
			Quantity = Quantity + 1;
			TemplateArea.Parameters.Fill(SelectionRowsWork);
			TemplateArea.Parameters.LineNumber = Quantity;
			
			If ValueIsFilled(SelectionRowsWork.Content) Then
				TemplateArea.Parameters.ProductDescription = SelectionRowsWork.Content;
			Else
				TemplateArea.Parameters.ProductDescription = SmallBusinessServer.GetProductsAndServicesPresentationForPrinting(SelectionRowsWork.InventoryItem, 
																	SelectionRowsWork.Characteristic, SelectionRowsWork.SKU);
			EndIf;
						
			If AreDiscounts Then
				If SelectionRowsWork.DiscountMarkupPercent = 100 Then
					Discount = SelectionRowsWork.Price * SelectionRowsWork.Quantity;
					TemplateArea.Parameters.Discount         = Discount;
					TemplateArea.Parameters.AmountWithoutDiscount = Discount;
				ElsIf SelectionRowsWork.DiscountMarkupPercent = 0 AND SelectionRowsWork.AutomaticDiscountAmount = 0 Then
					TemplateArea.Parameters.Discount         = 0;
					TemplateArea.Parameters.AmountWithoutDiscount = SelectionRowsWork.Amount;
				Else
					Discount = SelectionRowsWork.Quantity * SelectionRowsWork.Price - SelectionRowsWork.Amount; // AutomaticDiscounts
					TemplateArea.Parameters.Discount         = Discount;
					TemplateArea.Parameters.AmountWithoutDiscount = SelectionRowsWork.Amount + Discount;
				EndIf;
			EndIf;
			
			SpreadsheetDocument.Put(TemplateArea);
			
			Amount	= Amount 	+ SelectionRowsWork.Amount;
			VATAmount= VATAmount	+ SelectionRowsWork.VATAmount;
			Total	= Total		+ SelectionRowsWork.Total;
			
		EndDo;
		
		While LinesSelectionInventory.Next() Do
			
			Quantity = Quantity + 1;
			TemplateArea.Parameters.Fill(LinesSelectionInventory);
			TemplateArea.Parameters.LineNumber = Quantity;
			
			If ValueIsFilled(LinesSelectionInventory.Content) Then
				TemplateArea.Parameters.ProductDescription = LinesSelectionInventory.Content;
			Else
				TemplateArea.Parameters.ProductDescription = SmallBusinessServer.GetProductsAndServicesPresentationForPrinting(LinesSelectionInventory.InventoryItem, 
																	LinesSelectionInventory.Characteristic, LinesSelectionInventory.SKU);
			EndIf;
																
			If AreDiscounts Then
				If LinesSelectionInventory.DiscountMarkupPercent = 100 Then
					Discount = LinesSelectionInventory.Price * LinesSelectionInventory.Quantity;
					TemplateArea.Parameters.Discount         = Discount;
					TemplateArea.Parameters.AmountWithoutDiscount = Discount;
				ElsIf LinesSelectionInventory.DiscountMarkupPercent = 0 AND SelectionRowsWork.AutomaticDiscountAmount = 0 Then
					TemplateArea.Parameters.Discount         = 0;
					TemplateArea.Parameters.AmountWithoutDiscount = LinesSelectionInventory.Amount;
				Else
					Discount = LinesSelectionInventory.Quantity * LinesSelectionInventory.Price - LinesSelectionInventory.Amount; // AutomaticDiscounts
					TemplateArea.Parameters.Discount         = Discount;
					TemplateArea.Parameters.AmountWithoutDiscount = LinesSelectionInventory.Amount + Discount;
				EndIf;
			EndIf;
			
			SpreadsheetDocument.Put(TemplateArea);
			
			Amount	= Amount		+ LinesSelectionInventory.Amount;
			VATAmount= VATAmount	+ LinesSelectionInventory.VATAmount;
			Total	= Total		+ LinesSelectionInventory.Total;
			
		EndDo;
		
		TemplateArea = Template.GetArea("Total");
		TemplateArea.Parameters.Total		= SmallBusinessServer.AmountsFormat(Amount);
		TemplateArea.Parameters.Currency	= Header.DocumentCurrency;
		SpreadsheetDocument.Put(TemplateArea);
	
		If UseVAT Then
			
			TemplateArea = Template.GetArea("TotalVAT");
			If VATAmount = 0 Then
				TemplateArea.Parameters.VAT = NStr("en='Without tax (VAT)';vi='Không bao gồm thuế GTGT '");
				TemplateArea.Parameters.TotalVAT = "-";
			Else
				TemplateArea.Parameters.VAT = ?(Header.AmountIncludesVAT, NStr("en='Including VAT:';vi='Gồm thuế GTGT:';"), NStr("en='VAT Amount:';vi='Thuế GTGT:';"));
				TemplateArea.Parameters.TotalVAT = SmallBusinessServer.AmountsFormat(VATAmount);
			EndIf; 
			SpreadsheetDocument.Put(TemplateArea);
		
		EndIf;
		
		If Signature Then
		
			If Template.Areas.Find("InvoiceFooterWithSignature") <> Undefined Then
				
				If ValueIsFilled(Header.Company.FileFacsimilePrinting) Then
					
					TemplateArea = Template.GetArea("InvoiceFooterWithSignature");
					
					PictureData = AttachedFiles.GetFileBinaryData(Header.Company.FileFacsimilePrinting);
					If ValueIsFilled(PictureData) Then
						
						TemplateArea.Drawings.FacsimilePrint.Picture = New Picture(PictureData);
						
					EndIf;
					
				Else
					
					MessageText = NStr("en='Facsimile for company is not set. Facsimile is set in the company card, the ""Printing setting"" section.';ru='Факсимиле для организации не установлена. Установка факсимиле выполняется в карточке организации, раздел ""Настройка печати"".';vi='Chưa thiết lập mẫu con dấu qua Fax đối với doanh nghiệp. Cần đặt mẫu con dấu cho Fax trên thẻ doanh nghiệp, phần ""Logo và con dấu"".'");
					CommonUseClientServer.AddUserError(Errors, , MessageText, Undefined);
					
					TemplateArea = Template.GetArea("InvoiceFooter");
					
				EndIf;
				
			Else
				
				// You do not need to add the second warning as the warning is added while trying to output a title.
				
			EndIf;
			
			SpreadsheetDocument.Put(TemplateArea);
		
		EndIf;	
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, FirstLineNumber, PrintObjects, Header.Ref);
		
	EndDo;
	
	CommonUseClientServer.ShowErrorsToUser(Errors);
	
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;

EndFunction // PrintProformaInvoice()

// Document printing procedure.
//
Function PrintServicesAcceptanceCertificate(ObjectsArray, PrintObjects, TemplateName)
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersKey = "PrintParameters_CustomerOrder";
	
	Query = New Query();
	Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.Text = 
	"SELECT
	|	CustomerOrder.Ref AS Ref,
	|	CustomerOrder.Number AS Number,
	|	CustomerOrder.Finish AS DocumentDate,
	|	CustomerOrder.Date AS Date,
	|	CustomerOrder.Company AS Company,
	|	CustomerOrder.Counterparty AS Counterparty,
	|	CustomerOrder.AmountIncludesVAT AS AmountIncludesVAT,
	|	CustomerOrder.DocumentCurrency AS DocumentCurrency,
	|	CustomerOrder.Company.Prefix AS Prefix,
	|	CustomerOrder.Works.(
	|		LineNumber AS LineNumber,
	|		CASE
	|			WHEN (CAST(CustomerOrder.Works.ProductsAndServices.DescriptionFull AS String(1000))) = """"
	|				THEN CustomerOrder.Works.ProductsAndServices.Description
	|			ELSE CAST(CustomerOrder.Works.ProductsAndServices.DescriptionFull AS String(1000))
	|		END AS Product,
	|		ProductsAndServices.SKU AS SKU,
	|		ProductsAndServices.MeasurementUnit.Description AS MeasurementUnit,
	|		CustomerOrder.Works.Quantity * CustomerOrder.Works.Factor * CustomerOrder.Works.Multiplicity AS Quantity,
	|		Price AS Price,
	|		Amount AS Amount,
	|		VATAmount AS VATAmount,
	|		Total AS Total,
	|		Characteristic,
	|		Content,
	|		DiscountMarkupPercent,
	|		CASE
	|			WHEN CustomerOrder.Works.DiscountMarkupPercent <> 0
	|					OR CustomerOrder.Works.AutomaticDiscountAmount <> 0
	|				THEN 1
	|			ELSE 0
	|		END AS IsDiscount,
	|		Quantity AS Time,
	|		Multiplicity,
	|		Factor,
	|		AutomaticDiscountAmount
	|	)
	|FROM
	|	Document.CustomerOrder AS CustomerOrder
	|WHERE
	|	CustomerOrder.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Ref,
	|	LineNumber";
	
	Header = Query.Execute().Select();
	
	FirstDocument = True;
	
	While Header.Next() Do
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		FirstDocument = False;
		
		FirstLineNumber = SpreadsheetDocument.TableHeight + 1;
		
		StringSelectionProducts = Header.Works.Select();
		
		SpreadsheetDocument.PrintParametersName = "PRINT_PARAMETERS_CustomerOrder_PF_MXL_" + TemplateName;
		
		Template = PrintManagement.PrintedFormsTemplate("Document.CustomerOrder.PF_MXL_" + TemplateName);
		
		InfoAboutCompany = SmallBusinessServer.InfoAboutLegalEntityIndividual(Header.Company, Header.DocumentDate, ,);
		InfoAboutCounterparty = SmallBusinessServer.InfoAboutLegalEntityIndividual(Header.Counterparty, Header.DocumentDate, ,);
		
		If Header.Date < Date('20110101') Then
			DocumentNumber = SmallBusinessServer.GetNumberForPrinting(Header.Number, Header.Prefix);
		Else
			DocumentNumber = ObjectPrefixationClientServer.GetNumberForPrinting(Header.Number, True, True);
		EndIf;		
		
		TemplateArea = Template.GetArea("Title");
		TemplateArea.Parameters.HeaderText = NStr("en='Act # ';vi='Biên bản số '")
		                                        + DocumentNumber
		                                        + NStr("en=' dated ';vi=' '")
		                                        + Format(Header.DocumentDate, "DLF=DD");
		
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("Vendor");
		TemplateArea.Parameters.VendorPresentation = SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCompany, "FullDescr,TIN,LegalAddress,PhoneNumbers,");
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("Customer");
		TemplateArea.Parameters.RecipientPresentation = SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCounterparty, "FullDescr,TIN,LegalAddress,PhoneNumbers,");
		SpreadsheetDocument.Put(TemplateArea);
		
		AreDiscounts = Header.Works.Unload().Total("IsDiscount") <> 0;
		
		If AreDiscounts Then
			
			TemplateArea = Template.GetArea("TableWithDiscountHeader");
			SpreadsheetDocument.Put(TemplateArea);
			TemplateArea = Template.GetArea("RowWithDiscount");
			
		Else
			
			TemplateArea = Template.GetArea("TableHeader");
			SpreadsheetDocument.Put(TemplateArea);
			TemplateArea = Template.GetArea("String");
			
		EndIf;
		
		Amount		= 0;
		VATAmount	= 0;
		Total		= 0;
		Quantity	= 0;
		
		While StringSelectionProducts.Next() Do
			TemplateArea.Parameters.Fill(StringSelectionProducts);
			
			If ValueIsFilled(StringSelectionProducts.Content) Then
				TemplateArea.Parameters.Product = StringSelectionProducts.Content;
			Else
				TemplateArea.Parameters.Product = SmallBusinessServer.GetProductsAndServicesPresentationForPrinting(StringSelectionProducts.Product, 
																	StringSelectionProducts.Characteristic, StringSelectionProducts.SKU);
			EndIf;
																
			If AreDiscounts Then
				If StringSelectionProducts.DiscountMarkupPercent = 100 Then
					Discount = StringSelectionProducts.Price * StringSelectionProducts.Quantity;
					TemplateArea.Parameters.Discount         = Discount;
					TemplateArea.Parameters.AmountWithoutDiscount = Discount;
				ElsIf StringSelectionProducts.DiscountMarkupPercent = 0 AND StringSelectionProducts.AutomaticDiscountAmount = 0 Then
					TemplateArea.Parameters.Discount         = 0;
					TemplateArea.Parameters.AmountWithoutDiscount = StringSelectionProducts.Amount;
				Else
					Discount = StringSelectionProducts.Quantity * StringSelectionProducts.Price - StringSelectionProducts.Amount; // AutomaticDiscounts
					TemplateArea.Parameters.Discount         = Discount;
					TemplateArea.Parameters.AmountWithoutDiscount = StringSelectionProducts.Amount + Discount;
				EndIf;
			EndIf;
			
			SpreadsheetDocument.Put(TemplateArea);
			
			Amount		= Amount		+ StringSelectionProducts.Amount;
			VATAmount	= VATAmount	+ StringSelectionProducts.VATAmount;
			Total		= Total 	+ StringSelectionProducts.Total;
			Quantity	= Quantity+ 1;
			
		EndDo;
		
		TemplateArea = Template.GetArea("Total");
		TemplateArea.Parameters.Total = SmallBusinessServer.AmountsFormat(Amount);
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("TotalVAT");
		If VATAmount = 0 Then
			TemplateArea.Parameters.VAT = NStr("en='Without tax (VAT)';vi='Không bao gồm thuế GTGT '");
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
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, FirstLineNumber, PrintObjects, Header.Ref);
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;

EndFunction // PrintForm()

// Document printing procedure.
//
Function PrintCustomerInvoice(ObjectsArray, PrintObjects, TemplateName)
	
	Var Errors;
	
	UseVAT	= GetFunctionalOption("UseVAT");
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersKey = "PRINT_PARAMETRS_CustomerOrder_CustomerInvoice";

	FirstDocument = True;
	
	For Each CurrentDocument IN ObjectsArray Do
	
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		FirstDocument = False;
		
		FirstLineNumber = SpreadsheetDocument.TableHeight + 1;
		
		Query = New Query();
		Query.SetParameter("CurrentDocument", CurrentDocument);
		Query.Text = 
		"SELECT
		|	CustomerOrder.Finish AS DocumentDate,
		|	CustomerOrder.Date AS Date,
		|	CustomerOrder.Number AS DocumentNumber,
		|	CustomerOrder.Company AS Company,
		|	CustomerOrder.Counterparty AS Counterparty,
		|	CustomerOrder.AmountIncludesVAT AS AmountIncludesVAT,
		|	CustomerOrder.DocumentCurrency AS DocumentCurrency,
		|	CustomerOrder.Company.Prefix AS Prefix,
		|	CustomerOrder.SerialNumbers.(
		|		SerialNumber,
		|		ConnectionKey
		|	)
		|FROM
		|	Document.CustomerOrder AS CustomerOrder
		|WHERE
		|	CustomerOrder.Ref = &CurrentDocument
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CustomerOrderInventory.Ref,
		|	CustomerOrderInventory.LineNumber AS LineNumber,
		|	CustomerOrderInventory.ProductsAndServices.Ref AS ProductsAndServices,
		|	CASE
		|		WHEN (CAST(CustomerOrderInventory.ProductsAndServices.DescriptionFull AS String(100))) = """"""""
		|			THEN CustomerOrderInventory.ProductsAndServices.Description
		|		ELSE CustomerOrderInventory.ProductsAndServices.DescriptionFull
		|	END AS InventoryItem,
		|	CustomerOrderInventory.ProductsAndServices.SKU AS SKU,
		|	CustomerOrderInventory.ProductsAndServices.Code AS Code,
		|	CustomerOrderInventory.MeasurementUnit AS UnitOfMeasure,
		|	CustomerOrderInventory.Quantity AS Quantity,
		|	CustomerOrderInventory.Price AS Price,
		|	CustomerOrderInventory.Amount AS Amount,
		|	CustomerOrderInventory.VATAmount AS VATAmount,
		|	CustomerOrderInventory.Total AS Total,
		|	CustomerOrderInventory.Characteristic AS Characteristic,
		|	CustomerOrderInventory.Content AS Content,
		|	CustomerOrderInventory.DiscountMarkupPercent AS DiscountMarkupPercent,
		|	CASE
		|		WHEN CustomerOrderInventory.DiscountMarkupPercent <> 0
		|			THEN 1
		|		ELSE 0
		|	END AS IsDiscount,
		|	CustomerOrderInventory.ProductsAndServices.ProductsAndServicesType AS ProductsAndServicesType,
		|	0 AS Priority,
		|	CustomerOrderInventory.ConnectionKey
		|FROM
		|	Document.CustomerOrder.Inventory AS CustomerOrderInventory
		|WHERE
		|	CustomerOrderInventory.Ref = &CurrentDocument
		|
		|UNION ALL
		|
		|SELECT
		|	CustomerOrderWorks.Ref,
		|	CustomerOrderWorks.LineNumber,
		|	CustomerOrderWorks.ProductsAndServices.Ref,
		|	CASE
		|		WHEN (CAST(CustomerOrderWorks.ProductsAndServices.DescriptionFull AS String(100))) = """"""""
		|			THEN CustomerOrderWorks.ProductsAndServices.Description
		|		ELSE CustomerOrderWorks.ProductsAndServices.DescriptionFull
		|	END,
		|	CustomerOrderWorks.ProductsAndServices.SKU,
		|	CustomerOrderWorks.ProductsAndServices.Code,
		|	CustomerOrderWorks.ProductsAndServices.MeasurementUnit,
		|	CustomerOrderWorks.Quantity,
		|	CustomerOrderWorks.Price,
		|	CustomerOrderWorks.Amount,
		|	CustomerOrderWorks.VATAmount,
		|	CustomerOrderWorks.Total,
		|	CustomerOrderWorks.Characteristic,
		|	CustomerOrderWorks.Content,
		|	CustomerOrderWorks.DiscountMarkupPercent,
		|	CASE
		|		WHEN CustomerOrderWorks.DiscountMarkupPercent <> 0
		|			THEN 1
		|		ELSE 0
		|	END,
		|	CustomerOrderWorks.ProductsAndServices.ProductsAndServicesType,
		|	1,
		|	NULL
		|FROM
		|	Document.CustomerOrder.Works AS CustomerOrderWorks
		|WHERE
		|	CustomerOrderWorks.Ref = &CurrentDocument
		|
		|ORDER BY
		|	Priority,
		|	LineNumber";
		
		BatchQueryExecutionResult = Query.ExecuteBatch();
		
		Header = BatchQueryExecutionResult[0].Select();
		Header.Next();
		
		LinesSelectionSerialNumbers = Header.SerialNumbers.Select();
		LinesSelectionInventory = BatchQueryExecutionResult[1].Select();

		SpreadsheetDocument.PrintParametersName = "PRINT_PARAMETRS_CustomerOrder_CustomerInvoice";
									  
		Template = PrintManagement.PrintedFormsTemplate("Document.CustomerOrder.PF_MXL_CustomerInvoice");
		InfoAboutCompany = SmallBusinessServer.InfoAboutLegalEntityIndividual(Header.Company, Header.DocumentDate, ,);
		InfoAboutCounterparty = SmallBusinessServer.InfoAboutLegalEntityIndividual(Header.Counterparty, Header.DocumentDate, ,);

		If Template.Areas.Find("TitleWithLogo") <> Undefined
			AND Template.Areas.Find("TitleWithoutLogo") <> Undefined Then
			
			If ValueIsFilled(Header.Company.LogoFile) Then
				
				TemplateArea = Template.GetArea("TitleWithLogo");
				TemplateArea.Parameters.Fill(Header);
				
				PictureData = AttachedFiles.GetFileBinaryData(Header.Company.LogoFile);
				If ValueIsFilled(PictureData) Then
					
					TemplateArea.Drawings.Logo.Picture = New Picture(PictureData);
					
				EndIf;
				
			Else // If images are not selected, print regular header
				
				TemplateArea = Template.GetArea("TitleWithoutLogo");
				TemplateArea.Parameters.Fill(Header);
				
			EndIf;
			
			SpreadsheetDocument.Put(TemplateArea);
			
		Else
			
			MessageText = NStr("en='ATTENTION! Maybe, custom template is being used. Default procedures of account printing may work incorrectly.';ru='ВНИМАНИЕ! Возможно используется пользовательский макет. Штатный механизм печати счетов может работать некоректно.';vi='CHÚ Ý! Có thể sử dụng khuôn mẫu tự tạo. Cơ chế thông thường khi in hóa đơn có thể hoạt động không chính xác.'");
			CommonUseClientServer.AddUserError(Errors, , MessageText, Undefined);
			
		EndIf;
	
		TemplateArea = Template.GetArea("InvoiceHeaderVendor");
		
		TemplateArea.Parameters.Fill(Header);
		
		VendorPresentation	= SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCompany, "FullDescr");
		
		TemplateArea.Parameters.VendorPresentation	= VendorPresentation;
		TemplateArea.Parameters.VendorAddress		= SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCompany, "LegalAddress");
		TemplateArea.Parameters.VendorPhoneFax		= SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCompany, "PhoneNumbers,Fax");
		TemplateArea.Parameters.VendorEmail			= SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCompany, "Email");
		
		TemplateArea.Parameters.BankPresentation	=  SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCompany, "Bank", False);
		TemplateArea.Parameters.BankAccountNumber	=  SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCompany, "AccountNo", False);
		TemplateArea.Parameters.BankSWIFT			=  SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCompany, "SWIFT", False);
		
		CorrespondentText	= SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCompany, "CorrespondentText", False);
		TemplateArea.Parameters.BankBeneficiary		=  ?(ValueIsFilled(CorrespondentText), CorrespondentText, VendorPresentation);
		
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("InvoiceHeaderCustomer");
		
		TemplateArea.Parameters.CustomerPresentation	= SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCounterparty, "FullDescr");;
		TemplateArea.Parameters.CustomerAddress			= SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCounterparty, "LegalAddress");;
		TemplateArea.Parameters.CustomerPhoneFax		= SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCounterparty, "PhoneNumbers,Fax");;
		
		SpreadsheetDocument.Put(TemplateArea);

		AreDiscounts = BatchQueryExecutionResult[1].Unload().Total("IsDiscount") <> 0;
	
		If AreDiscounts Then
			
			TemplateArea = Template.GetArea("TableHeaderWithDiscount");
			TemplateArea.Parameters.Currency	= Header.DocumentCurrency;
			SpreadsheetDocument.Put(TemplateArea);
			TemplateArea = Template.GetArea("TableRowWithDiscount");
			
		Else
			
			TemplateArea = Template.GetArea("TableHeader");
			TemplateArea.Parameters.Currency	= Header.DocumentCurrency;
			SpreadsheetDocument.Put(TemplateArea);
			TemplateArea = Template.GetArea("TableRow");
			
		EndIf;
		
		Amount		= 0;
		VATAmount	= 0;
		Total		= 0;
		Quantity	= 0;
		
		While LinesSelectionInventory.Next() Do
		
			TemplateArea.Parameters.Fill(LinesSelectionInventory);
			
			If ValueIsFilled(LinesSelectionInventory.Content) Then
				TemplateArea.Parameters.ProductDescription = LinesSelectionInventory.Content;
			Else
				StringSerialNumbers = WorkWithSerialNumbers.SerialNumbersStringFromSelection(LinesSelectionSerialNumbers, LinesSelectionInventory.ConnectionKey);
				TemplateArea.Parameters.ProductDescription = SmallBusinessServer.GetProductsAndServicesPresentationForPrinting(LinesSelectionInventory.InventoryItem, 
																	LinesSelectionInventory.Characteristic, LinesSelectionInventory.SKU, StringSerialNumbers);
			EndIf;
																
			If AreDiscounts Then
				If LinesSelectionInventory.DiscountMarkupPercent = 100 Then
					Discount = LinesSelectionInventory.Price * LinesSelectionInventory.Quantity;
					TemplateArea.Parameters.Discount			= Discount;
					TemplateArea.Parameters.AmountWithoutDiscount	= Discount;
				ElsIf LinesSelectionInventory.DiscountMarkupPercent = 0 Then
					TemplateArea.Parameters.Discount			= 0;
					TemplateArea.Parameters.AmountWithoutDiscount	= LinesSelectionInventory.Amount;
				Else
					Discount = LinesSelectionInventory.Amount * LinesSelectionInventory.DiscountMarkupPercent / (100 - LinesSelectionInventory.DiscountMarkupPercent);
					TemplateArea.Parameters.Discount			= Discount;
					TemplateArea.Parameters.AmountWithoutDiscount	= LinesSelectionInventory.Amount + Discount;
				EndIf;
			EndIf;
			
			Quantity	= Quantity + 1;
			TemplateArea.Parameters.LineNumber = Quantity;
			
			SpreadsheetDocument.Put(TemplateArea);
			
			Amount	= Amount		+ LinesSelectionInventory.Amount;
			VATAmount= VATAmount	+ LinesSelectionInventory.VATAmount;
			Total	= Total 	+ LinesSelectionInventory.Total;
			
		EndDo;
		
		TemplateArea = Template.GetArea("Total");
		TemplateArea.Parameters.Total		= SmallBusinessServer.AmountsFormat(Amount);
		TemplateArea.Parameters.Currency	= Header.DocumentCurrency;
		SpreadsheetDocument.Put(TemplateArea);
		
		If UseVAT Then
			
			TemplateArea = Template.GetArea("TotalVAT");
			If VATAmount = 0 Then
				TemplateArea.Parameters.VAT = NStr("en='Without tax (VAT)';vi='Không bao gồm thuế GTGT '");
				TemplateArea.Parameters.TotalVAT = "-";
			Else
				TemplateArea.Parameters.VAT = ?(Header.AmountIncludesVAT, NStr("en='Including VAT:';vi='Gồm thuế GTGT:';"), NStr("en='VAT Amount:';vi='Thuế GTGT:';"));
				TemplateArea.Parameters.TotalVAT = SmallBusinessServer.AmountsFormat(VATAmount);
			EndIf; 
			SpreadsheetDocument.Put(TemplateArea);
		
		EndIf;

		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, FirstLineNumber, PrintObjects, CurrentDocument);
	
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;
	
EndFunction // PrintCustomerInvoice()

// Document printing procedure.
//
Function PrintWorkOrder(ObjectsArray, PrintObjects, TemplateName)
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersKey = "PrintParameters_CustomerOrder";

	FirstDocument = True;
	
	For Each CurrentDocument IN ObjectsArray Do
	
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		FirstDocument = False;
		
		FirstLineNumber = SpreadsheetDocument.TableHeight + 1;
		
		Query = New Query;
		Query.SetParameter("CurrentDocument", CurrentDocument);
		Query.Text = 
		"SELECT
		|	CustomerOrder.Ref AS Ref,
		|	CustomerOrder.Number AS Number,
		|	CustomerOrder.Date AS DocumentDate,
		|	CustomerOrder.Start,
		|	CustomerOrder.Finish,
		|	CustomerOrder.Company AS Company,
		|	CustomerOrder.Counterparty AS Counterparty,
		|	CustomerOrder.AmountIncludesVAT AS AmountIncludesVAT,
		|	CustomerOrder.DocumentCurrency AS DocumentCurrency,
		|	CustomerOrder.Company.Prefix AS Prefix,
		|	CustomerOrder.Inventory.(
		|		LineNumber AS LineNumber,
		|		CASE
		|			WHEN (CAST(CustomerOrder.Inventory.ProductsAndServices.DescriptionFull AS String(1000))) = """"
		|				THEN CustomerOrder.Inventory.ProductsAndServices.Description
		|			ELSE CAST(CustomerOrder.Inventory.ProductsAndServices.DescriptionFull AS String(1000))
		|		END AS Product,
		|		ProductsAndServices.SKU AS SKU,
		|		MeasurementUnit.Description AS MeasurementUnit,
		|		Quantity AS Quantity,
		|		Price AS Price,
		|		Amount AS Amount,
		|		VATAmount AS VATAmount,
		|		Total AS Total,
		|		Characteristic,
		|		Content AS Content,
		|		DiscountMarkupPercent,
		|		CASE
		|			WHEN CustomerOrder.Inventory.DiscountMarkupPercent <> 0
		|					OR CustomerOrder.Inventory.AutomaticDiscountAmount <> 0
		|				THEN 1
		|			ELSE 0
		|		END AS IsDiscount,
		|		AutomaticDiscountAmount,
		|		ConnectionKey
		|	),
		|	CustomerOrder.ConsumerMaterials.(
		|		LineNumber AS LineNumber,
		|		CASE
		|			WHEN (CAST(CustomerOrder.ConsumerMaterials.ProductsAndServices.DescriptionFull AS String(1000))) = """"
		|				THEN CustomerOrder.ConsumerMaterials.ProductsAndServices.Description
		|			ELSE CAST(CustomerOrder.ConsumerMaterials.ProductsAndServices.DescriptionFull AS String(1000))
		|		END AS Product,
		|		ProductsAndServices.SKU AS SKU,
		|		MeasurementUnit.Description AS MeasurementUnit,
		|		Quantity AS Quantity,
		|		Characteristic
		|	),
		|	CustomerOrder.SerialNumbers.(
		|		SerialNumber,
		|		ConnectionKey
		|	)
		|FROM
		|	Document.CustomerOrder AS CustomerOrder
		|WHERE
		|	CustomerOrder.Ref = &CurrentDocument";
		
		Header = Query.Execute().Select();
		Header.Next();

		Query = New Query;
		Query.SetParameter("CurrentDocument", CurrentDocument);
		Query.SetParameter("ToDate", Header.DocumentDate);
		Query.Text = 
		"SELECT
		|	CustomerOrderWorks.LineNumber AS LineNumber,
		|	CASE
		|		WHEN (CAST(CustomerOrderWorks.ProductsAndServices.DescriptionFull AS String(1000))) = """"
		|			THEN CustomerOrderWorks.ProductsAndServices.Description
		|		ELSE CAST(CustomerOrderWorks.ProductsAndServices.DescriptionFull AS String(1000))
		|	END AS Product,
		|	CustomerOrderWorks.ProductsAndServices.SKU AS SKU,
		|	CustomerOrderWorks.ProductsAndServices.MeasurementUnit.Description AS MeasurementUnit,
		|	CustomerOrderWorks.Quantity AS Quantity,
		|	CustomerOrderWorks.Quantity * CustomerOrderWorks.Multiplicity * CustomerOrderWorks.Factor AS CountRepetitionFactor,
		|	CustomerOrderWorks.Price AS Price,
		|	CustomerOrderWorks.Amount AS Amount,
		|	CustomerOrderWorks.VATAmount AS VATAmount,
		|	ISNULL(CustomerOrderWorks.Total, 0) AS Total,
		|	CustomerOrderWorks.Characteristic AS Characteristic,
		|	CustomerOrderWorks.Content AS Content,
		|	CustomerOrderWorks.DiscountMarkupPercent AS DiscountMarkupPercent,
		|	CASE
		|		WHEN CustomerOrderWorks.DiscountMarkupPercent <> 0
		|				OR CustomerOrderWorks.AutomaticDiscountAmount <> 0
		|			THEN 1
		|		ELSE 0
		|	END AS IsDiscount,
		|	IndividualsDescriptionFullSliceLast.Surname,
		|	IndividualsDescriptionFullSliceLast.Name,
		|	IndividualsDescriptionFullSliceLast.Patronymic,
		|	CustomerOrderPerformers.Employee.Ind AS Ind,
		|	CustomerOrderWorks.ConnectionKey AS ConnectionKey,
		|	CustomerOrderWorks.AutomaticDiscountAmount
		|FROM
		|	Document.CustomerOrder.Works AS CustomerOrderWorks
		|		LEFT JOIN Document.CustomerOrder.Performers AS CustomerOrderPerformers
		|			LEFT JOIN InformationRegister.IndividualsDescriptionFull.SliceLast(&ToDate, ) AS IndividualsDescriptionFullSliceLast
		|			ON CustomerOrderPerformers.Employee.Ind = IndividualsDescriptionFullSliceLast.Ind
		|		ON CustomerOrderWorks.ConnectionKey = CustomerOrderPerformers.ConnectionKey
		|			AND (CustomerOrderPerformers.Ref = &CurrentDocument)
		|WHERE
		|	CustomerOrderWorks.Ref = &CurrentDocument
		|TOTALS
		|	MAX(Product),
		|	MAX(SKU),
		|	MAX(MeasurementUnit),
		|	MAX(Quantity),
		|	MAX(CountRepetitionFactor),
		|	MAX(Price),
		|	MAX(Amount),
		|	MAX(VATAmount),
		|	MAX(Total),
		|	MAX(Characteristic),
		|	MAX(Content),
		|	MAX(DiscountMarkupPercent),
		|	MAX(IsDiscount)
		|BY
		|	ConnectionKey";
		
		QueryResultWork = Query.Execute();
		SelectionRowsWork = QueryResultWork.Select(QueryResultIteration.ByGroups, "ConnectionKey");
		StringSelectionProducts = Header.Inventory.Select();
		RowsOfCustomerMaterialsSelection = Header.ConsumerMaterials.Select();
		LinesSelectionSerialNumbers = Header.SerialNumbers.Select();
		
		SpreadsheetDocument.PrintParametersName = "PRINT_PARAMETERS_PF_MXL_OrderCustomerWorkOrder";
		
		Template = PrintManagement.PrintedFormsTemplate("Document.CustomerOrder.PF_MXL_WorkOrder");
		
		InfoAboutCompany = SmallBusinessServer.InfoAboutLegalEntityIndividual(Header.Company, Header.DocumentDate, ,);
		InfoAboutCounterparty = SmallBusinessServer.InfoAboutLegalEntityIndividual(Header.Counterparty, Header.DocumentDate, ,);
		
		If Header.DocumentDate < Date('20110101') Then
			DocumentNumber = SmallBusinessServer.GetNumberForPrinting(Header.Number, Header.Prefix);
		Else
			DocumentNumber = ObjectPrefixationClientServer.GetNumberForPrinting(Header.Number, True, True);
		EndIf;		
		
		TemplateArea = Template.GetArea("Title");
		TemplateArea.Parameters.HeaderText = NStr("en='Work order No ';vi='Đơn hàng trọn gói số '")
												+ DocumentNumber
												+ NStr("en=' from ';vi=' '")
												+ Format(Header.DocumentDate, "DLF=DD");
		
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("Vendor");
		TemplateArea.Parameters.VendorPresentation = SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCompany, "FullDescr,TIN,LegalAddress,PhoneNumbers,");
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("Customer");
		TemplateArea.Parameters.RecipientPresentation = SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCounterparty, "FullDescr,TIN,LegalAddress,PhoneNumbers,");
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("terms");
		FillPropertyValues(TemplateArea.Parameters, Header);
		SpreadsheetDocument.Put(TemplateArea);
		
		LineNumber		= 0;
		WorkAmount		= 0;
		AmountVATWork	= 0;
		Amount			= 0;
		VATAmount		= 0;
		Total			= 0;
		Quantity		= 0;
		
		// WORKS
		AreDiscounts = QueryResultWork.Unload().Total("IsDiscount") <> 0;
		
		If AreDiscounts Then
			
			TemplateArea = Template.GetArea("TableHeaderWithDiscountWorks");
			SpreadsheetDocument.Put(TemplateArea);
			TemplateArea = Template.GetArea("RowWithDiscountWork");
			
		Else
			
			TemplateArea = Template.GetArea("WorkTableHeader");
			SpreadsheetDocument.Put(TemplateArea);
			TemplateArea = Template.GetArea("WorkRow");
			
		EndIf;
		
		While SelectionRowsWork.Next() Do
			
			LineNumber = LineNumber + 1;
			TemplateArea.Parameters.Fill(SelectionRowsWork);
			
			TemplateArea.Parameters.LineNumber = LineNumber;
			If ValueIsFilled(SelectionRowsWork.Content) Then
				TemplateArea.Parameters.Product = SelectionRowsWork.Content;
			Else
				TemplateArea.Parameters.Product = SmallBusinessServer.GetProductsAndServicesPresentationForPrinting(SelectionRowsWork.Product, 
																	SelectionRowsWork.Characteristic, SelectionRowsWork.SKU);
			EndIf;
																
			If AreDiscounts Then
				If SelectionRowsWork.DiscountMarkupPercent = 100 Then
					Discount = SelectionRowsWork.Price * SelectionRowsWork.CountRepetitionFactor;
					TemplateArea.Parameters.Discount         = Discount;
					TemplateArea.Parameters.AmountWithoutDiscount = Discount;
				ElsIf SelectionRowsWork.DiscountMarkupPercent = 0 AND SelectionRowsWork.AutomaticDiscountAmount = 0 Then
					TemplateArea.Parameters.Discount         = 0;
					TemplateArea.Parameters.AmountWithoutDiscount = SelectionRowsWork.Amount;
				Else
					Discount = SelectionRowsWork.CountRepetitionFactor * SelectionRowsWork.Price - SelectionRowsWork.Amount; // AutomaticDiscounts
					TemplateArea.Parameters.Discount         = Discount;
					TemplateArea.Parameters.AmountWithoutDiscount = SelectionRowsWork.Amount + Discount;
				EndIf;
			EndIf;
			
			Selection = SelectionRowsWork.Select();
			StringPerformers = "";
			While Selection.Next() Do
				PresentationEmployee = SmallBusinessServer.GetSurnameNamePatronymic(Selection.Surname, Selection.Name, Selection.Patronymic, False);
				StringPerformers = StringPerformers + ?(StringPerformers = "", "", ", ") 
									+ ?(ValueIsFilled(PresentationEmployee), PresentationEmployee, Selection.Ind);
				TemplateArea.Parameters.Performers = StringPerformers;
			EndDo;
			
			SpreadsheetDocument.Put(TemplateArea);
			
			Amount			= Amount			+ SelectionRowsWork.Amount;
			VATAmount		= VATAmount		+ SelectionRowsWork.VATAmount;
			Total			= Total			+ SelectionRowsWork.Total;
			WorkAmount		= WorkAmount	+ SelectionRowsWork.Amount;
			AmountVATWork	= AmountVATWork+ SelectionRowsWork.VATAmount;
			Quantity		= Quantity	+ 1; 
			
		EndDo;
		
		TemplateArea = Template.GetArea("TotalWork");
		TemplateArea.Parameters.Total = SmallBusinessServer.AmountsFormat(WorkAmount);
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("TotalVATWork");
		If VATAmount = 0 Then
			TemplateArea.Parameters.VAT = NStr("en='Without tax (VAT)';vi='Không bao gồm thuế GTGT '");
			TemplateArea.Parameters.TotalVAT = "-";
		Else
			TemplateArea.Parameters.VAT = ?(Header.AmountIncludesVAT, NStr("en='Including VAT:';vi='Gồm thuế GTGT:';"), NStr("en='VAT Amount:';vi='Thuế GTGT:';"));
			TemplateArea.Parameters.TotalVAT = SmallBusinessServer.AmountsFormat(AmountVATWork);
		EndIf; 
		SpreadsheetDocument.Put(TemplateArea);
		
		// PRODUCTS
		If Header.Inventory.Unload().Count() > 0 Then
		
			AreDiscounts = Header.Inventory.Unload().Total("IsDiscount") <> 0;
			
			If AreDiscounts Then
				
				TemplateArea = Template.GetArea("TableHeaderWithDiscountProducts");
				SpreadsheetDocument.Put(TemplateArea);
				TemplateArea = Template.GetArea("RowWithDiscountProducts");
				
			Else
				
				TemplateArea = Template.GetArea("ProductsTableHeader");
				SpreadsheetDocument.Put(TemplateArea);
				TemplateArea = Template.GetArea("ProductsRow");
				
			EndIf;
			
			AmountProducts		= 0;
			AmountVATProducts	= 0;
			
			While StringSelectionProducts.Next() Do
				
				TemplateArea.Parameters.Fill(StringSelectionProducts);
				
				If ValueIsFilled(StringSelectionProducts.Content) Then
					TemplateArea.Parameters.Product = StringSelectionProducts.Content;
				Else
					StringSerialNumbers = WorkWithSerialNumbers.SerialNumbersStringFromSelection(LinesSelectionSerialNumbers, StringSelectionProducts.ConnectionKey);
					TemplateArea.Parameters.Product = SmallBusinessServer.GetProductsAndServicesPresentationForPrinting(StringSelectionProducts.Product, 
																		StringSelectionProducts.Characteristic, StringSelectionProducts.SKU, StringSerialNumbers);
				EndIf;
				
				If AreDiscounts Then
					If StringSelectionProducts.DiscountMarkupPercent = 100 Then
						Discount = StringSelectionProducts.Price * StringSelectionProducts.Quantity;
						TemplateArea.Parameters.Discount         = Discount;
						TemplateArea.Parameters.AmountWithoutDiscount = Discount;
					ElsIf StringSelectionProducts.DiscountMarkupPercent = 0 AND StringSelectionProducts.AutomaticDiscountAmount = 0 Then
						TemplateArea.Parameters.Discount         = 0;
						TemplateArea.Parameters.AmountWithoutDiscount = StringSelectionProducts.Amount;
					Else
						Discount = StringSelectionProducts.Quantity * StringSelectionProducts.Price - StringSelectionProducts.Amount; // AutomaticDiscounts
						TemplateArea.Parameters.Discount         = Discount;
						TemplateArea.Parameters.AmountWithoutDiscount = StringSelectionProducts.Amount + Discount;
					EndIf;
				EndIf;
				
				SpreadsheetDocument.Put(TemplateArea);
				
				AmountProducts		= AmountProducts	+ StringSelectionProducts.Amount;
				AmountVATProducts	= AmountVATProducts+ StringSelectionProducts.VATAmount;
				Amount			= Amount			+ StringSelectionProducts.Amount;
				VATAmount		= VATAmount		+ StringSelectionProducts.VATAmount;
				Total 			= Total			+ StringSelectionProducts.Total;
				Quantity		= Quantity	+ 1;
				
			EndDo;
			
			TemplateArea = Template.GetArea("TotalProducts");
			TemplateArea.Parameters.Total = SmallBusinessServer.AmountsFormat(AmountProducts);
			SpreadsheetDocument.Put(TemplateArea);
			
			TemplateArea = Template.GetArea("TotalVATProducts");
			If VATAmount = 0 Then
				TemplateArea.Parameters.VAT = NStr("en='Without tax (VAT)';vi='Không bao gồm thuế GTGT '");
				TemplateArea.Parameters.TotalVAT = "-";
			Else
				TemplateArea.Parameters.VAT = ?(Header.AmountIncludesVAT, NStr("en='Including VAT:';vi='Gồm thuế GTGT:';"), NStr("en='VAT Amount:';vi='Thuế GTGT:';"));
				TemplateArea.Parameters.TotalVAT = SmallBusinessServer.AmountsFormat(AmountVATProducts);
			EndIf; 
			SpreadsheetDocument.Put(TemplateArea);
			
		EndIf; 
		
		// CUSTOMER MATERIALS
		If Header.ConsumerMaterials.Unload().Count() > 0 Then
		
			TemplateArea = Template.GetArea("TableHeaderOfCustomerMaterials");
			SpreadsheetDocument.Put(TemplateArea);
			TemplateArea = Template.GetArea("RowCustomerMaterials");
			
			While RowsOfCustomerMaterialsSelection.Next() Do
				TemplateArea.Parameters.Fill(RowsOfCustomerMaterialsSelection);
				
				TemplateArea.Parameters.Product = SmallBusinessServer.GetProductsAndServicesPresentationForPrinting(RowsOfCustomerMaterialsSelection.Product, 
																		RowsOfCustomerMaterialsSelection.Characteristic, RowsOfCustomerMaterialsSelection.SKU);
				SpreadsheetDocument.Put(TemplateArea);
				
			EndDo;
			
			TemplateArea = Template.GetArea("TotalCustomerMaterials");
			SpreadsheetDocument.Put(TemplateArea);
		
		EndIf; 
		
		// FOOTER
		TemplateArea = Template.GetArea("AmountInWords");
		AmountToBeWrittenInWords = Total;
		TemplateArea.Parameters.TotalRow = NStr("en='Total titles ';vi='Tổng số dòng '")
												+ String(Quantity)
												+ NStr("en=', in the amount of ';vi=', với tổng số tiền '")
												+ SmallBusinessServer.AmountsFormat(AmountToBeWrittenInWords, Header.DocumentCurrency);
		
		TemplateArea.Parameters.AmountInWords = WorkWithCurrencyRates.GenerateAmountInWords(AmountToBeWrittenInWords, Header.DocumentCurrency);
		
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("Signatures");
		
		SpreadsheetDocument.Put(TemplateArea);
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, FirstLineNumber, PrintObjects, Header.Ref);
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;

EndFunction // PrintForm()

// Function checks if the document is posted and calls
// the procedure of document printing.
//
Function PrintForm(ObjectsArray, PrintObjects, TemplateName)
	
	If TemplateName = "CustomerOrderTemplate" Then
		
		Return PrintCustomerOrder(ObjectsArray, PrintObjects, TemplateName);
		
	ElsIf TemplateName = "ProformaInvoice" Then
		
		Return PrintProformaInvoice(ObjectsArray, PrintObjects, TemplateName);
		
	ElsIf TemplateName = "ProformaInvoiceWithSignature" Then
		
		Return PrintProformaInvoice(ObjectsArray, PrintObjects, "ProformaInvoice", True);
		
	ElsIf TemplateName = "ServicesAcceptanceCertificate" OR TemplateName = "ServicesAcceptanceCertificateDetailed" Then
		
		Return PrintServicesAcceptanceCertificate(ObjectsArray, PrintObjects, TemplateName);
		
	ElsIf TemplateName = "CustomerInvoice" Then
		
		Return PrintCustomerInvoice(ObjectsArray, PrintObjects, TemplateName);
		
	ElsIf TemplateName = "WorkOrder" Then
		
		Return PrintWorkOrder(ObjectsArray, PrintObjects, TemplateName);
		
	ElsIf TemplateName = "GuaranteeCard" Then
		
		Return WorkWithProductsServer.PrintGuaranteeCard(ObjectsArray, PrintObjects);
		
	EndIf;
	
EndFunction // PrintForm()

// Generate printed forms of objects
//
// Incoming:
//  TemplateNames   - String	- Names of layouts separated by commas 
//	ObjectsArray	- Array		- Array of refs to objects that need to be printed 
//	PrintParameters - Structure - Structure of additional printing parameters
//
// Outgoing:
//   PrintFormsCollection	- Values table	- Generated table documents 
//	OutputParameters		- Structure     - Parameters of generated table documents
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.NeedToPrintTemplate(PrintFormsCollection, "CustomerOrderTemplate") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "CustomerOrderTemplate", NStr("en='Customer order';vi='Đơn hàng của khách';ru='Заказ покупателя'"), PrintForm(ObjectsArray, PrintObjects, "CustomerOrderTemplate"));
		
	ElsIf PrintManagement.NeedToPrintTemplate(PrintFormsCollection, "ProformaInvoice") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "ProformaInvoice", NStr("en='Proforma invoice';vi='Hóa đơn thanh toán';ru='Счет на оплату'"), PrintForm(ObjectsArray, PrintObjects, "ProformaInvoice"));
		
	ElsIf PrintManagement.NeedToPrintTemplate(PrintFormsCollection, "ProformaInvoiceWithSignature") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "ProformaInvoiceWithSignature", NStr("en='Proforma invoice';vi='Hóa đơn thanh toán';ru='Счет на оплату'"), PrintForm(ObjectsArray, PrintObjects, "ProformaInvoiceWithSignature"));
		
	ElsIf PrintManagement.NeedToPrintTemplate(PrintFormsCollection, "ServicesAcceptanceCertificate") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "ServicesAcceptanceCertificate", NStr("en='Services acceptance certificate';vi='Biên bản'"), PrintForm(ObjectsArray, PrintObjects, "ServicesAcceptanceCertificate"));
		
	ElsIf PrintManagement.NeedToPrintTemplate(PrintFormsCollection, "ServicesAcceptanceCertificateDetailed") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "ServicesAcceptanceCertificateDetailed", NStr("en='Services acceptance certificate (detailed)';vi='Biên bản (chi tiết)'"), PrintForm(ObjectsArray, PrintObjects, "ServicesAcceptanceCertificateDetailed"));
		
	ElsIf PrintManagement.NeedToPrintTemplate(PrintFormsCollection, "CustomerInvoice") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "CustomerInvoice", NStr("en='Customer Invoice';vi='Hóa đơn '"), PrintForm(ObjectsArray, PrintObjects, "CustomerInvoice"));
		
	ElsIf PrintManagement.NeedToPrintTemplate(PrintFormsCollection, "WorkOrder") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "WorkOrder", NStr("en='Work-order';vi='Đơn hàng trọn gói'"), PrintForm(ObjectsArray, PrintObjects, "WorkOrder"));
		
	ElsIf PrintManagement.NeedToPrintTemplate(PrintFormsCollection, "GuaranteeCard") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "GuaranteeCard", NStr("en='Guarantee card';vi='Thẻ bảo hành';ru='Гарантийный талон'"), PrintForm(ObjectsArray, PrintObjects, "GuaranteeCard"));
		
	EndIf;
	
	// parameters of sending printing forms by email
	SmallBusinessServer.FillSendingParameters(OutputParameters.SendingParameters, ObjectsArray, PrintFormsCollection);
	
EndProcedure

// Fills in Customer order printing commands list
// 
// Parameters:
//   PrintCommands - ValueTable - see fields' content in the PrintManagement.CreatePrintCommandsCollection function.
//
Procedure AddPrintCommands(PrintCommands) Export
	
	//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
	// Customer order
	//
	
	// Customer order
	PrintCommand = PrintCommands.Add();
	PrintCommand.ID							= "CustomerOrderTemplate";
	PrintCommand.Presentation				= NStr("en='Customer order';ru='Заказ покупателя';vi='Đơn hàng của khách'");
	PrintCommand.FormsList					= "DocumentForm,ListForm,ShipmentDocumentsListForm,PaymentDocumentsListForm";
	PrintCommand.CheckPostingBeforePrint	= False;
	PrintCommand.PlaceProperties			= "GroupImportantCommandsCustomerOrder";
	PrintCommand.Order						= 1;
	
	// Proforma invoice
	PrintCommand = PrintCommands.Add();
	PrintCommand.ID							= "ProformaInvoice";
	PrintCommand.Presentation				= NStr("en='Proforma invoice';ru='Счет на оплату';vi='Hóa đơn thanh toán'");
	PrintCommand.FormsList					= "DocumentForm,ListForm,ShipmentDocumentsListForm,PaymentDocumentsListForm";
	PrintCommand.CheckPostingBeforePrint	= False;
	PrintCommand.PlaceProperties			= "GroupImportantCommandsCustomerOrder";
	PrintCommand.Order						= 4;
	
	// Proforma invoice with signature
	PrintCommand = PrintCommands.Add();
	PrintCommand.ID							= "ProformaInvoiceWithSignature";
	PrintCommand.Presentation				= NStr("en='Proforma invoice (with signature)';ru='Счет на оплату (с подписями)';vi='Hóa đơn thanh toán (có chữ ký)'");
	PrintCommand.FormsList					= "DocumentForm,ListForm,ShipmentDocumentsListForm,PaymentDocumentsListForm";
	PrintCommand.CheckPostingBeforePrint	= False;
	PrintCommand.PlaceProperties			= "GroupImportantCommandsCustomerOrder";
	PrintCommand.Order						= 10;
	
	// Contract
	PrintCommand = PrintCommands.Add();
	PrintCommand.Handler = "SmallBusinessClient.GenerateContractForms";
	PrintCommand.ID = "ContractForm";
	PrintCommand.Presentation = NStr("en='Contract form';ru='Бланк договора';vi='Mẫu hợp đồng'");
	PrintCommand.FormsList = "DocumentForm,ListForm,ShipmentDocumentsListForm,PaymentDocumentsListForm";
	PrintCommand.CheckPostingBeforePrint = False;
	PrintCommand.PlaceProperties = "GroupImportantCommandsCustomerOrder";
	PrintCommand.Order = 17;
	
	//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
	// Work order
	//
	
	// Documents set
	PrintCommand = PrintCommands.Add();
	IdentifierValue = "CustomerOrderTemplate,WorkOrder,ServicesAcceptanceCertificate,ServicesAcceptanceCertificateDetailed,CustomerInvoice,ProformaInvoice,ProformaInvoiceWithSignature,GuaranteeCard";
	IdentifierValue = StrReplace(IdentifierValue, ",GuaranteeCard", ?(GetFunctionalOption("UseSerialNumbers"), ",GuaranteeCard", ""));
	PrintCommand.ID = IdentifierValue;
	PrintCommand.Presentation = NStr("en='Customized document set';ru='Настраиваемый комплект документов';vi='Bộ chứng từ được tùy chỉnh'");
	PrintCommand.FormsList = "FormWorkOrder,ListFormWorkOrder,ShipmentDocumentsListForm,PaymentDocumentsListForm";
	PrintCommand.CheckPostingBeforePrint = False;
	PrintCommand.PlaceProperties = "GroupImportantCommandsWorkOrder";
	PrintCommand.Order = 51;
	
	
	// Customer order
	PrintCommand = PrintCommands.Add();
	PrintCommand.ID = "CustomerOrderTemplate";
	PrintCommand.Presentation = NStr("en='Customer order';ru='Заказ покупателя';vi='Đơn hàng của khách'");
	PrintCommand.FormsList = "FormWorkOrder,ListFormWorkOrder,ShipmentDocumentsListForm,PaymentDocumentsListForm";
	PrintCommand.CheckPostingBeforePrint = False;
	PrintCommand.PlaceProperties = "GroupImportantCommandsWorkOrder";
	PrintCommand.Order = 54;
	
	// Work order
	PrintCommand = PrintCommands.Add();
	PrintCommand.ID = "WorkOrder";
	PrintCommand.Presentation = NStr("en='Operating procedure';ru='Порядок работы';vi='Đơn hàng trọn gói'");
	PrintCommand.FormsList = "FormWorkOrder,ListFormWorkOrder,ShipmentDocumentsListForm,PaymentDocumentsListForm";
	PrintCommand.CheckPostingBeforePrint = False;
	PrintCommand.PlaceProperties = "GroupImportantCommandsWorkOrder";
	PrintCommand.Order = 57;
	
	// Services acceptance certificate
	PrintCommand = PrintCommands.Add();
	PrintCommand.ID = "ServicesAcceptanceCertificate";
	PrintCommand.Presentation = NStr("en='Acceptance certificate';ru='Акт выполненных работ';vi='Biên bản cung cấp dịch vụ'");
	PrintCommand.FormsList = "FormWorkOrder,ListFormWorkOrder,ShipmentDocumentsListForm,PaymentDocumentsListForm";
	PrintCommand.CheckPostingBeforePrint = False;
	PrintCommand.PlaceProperties = "GroupImportantCommandsWorkOrder";
	PrintCommand.Order = 60;
	
	// Services acceptance certificate (detailed)
	PrintCommand = PrintCommands.Add();
	PrintCommand.ID = "ServicesAcceptanceCertificateDetailed";
	PrintCommand.Presentation = NStr("en='Certificate of services rendered (detailed)';ru='Акт об оказании услуг (подробно)';vi='Biên bản cung cấp dịch vụ (chi tiết)'");
	PrintCommand.FormsList = "FormWorkOrder,ListFormWorkOrder,ShipmentDocumentsListForm,PaymentDocumentsListForm";
	PrintCommand.CheckPostingBeforePrint = False;
	PrintCommand.PlaceProperties = "GroupImportantCommandsWorkOrder";
	PrintCommand.Order = 63;
	
	// Customer invoice
	PrintCommand = PrintCommands.Add();
	PrintCommand.ID							= "CustomerInvoice";
	PrintCommand.Presentation				= NStr("en='Invoice';ru='Расходная накладная';vi='Hóa đơn giao hàng'");
	PrintCommand.FormsList					= "FormWorkOrder,ListFormWorkOrder,ShipmentDocumentsListForm,PaymentDocumentsListForm";
	PrintCommand.CheckPostingBeforePrint	= False;
	PrintCommand.PlaceProperties			= "GroupImportantCommandsWorkOrder";
	PrintCommand.Order						= 66;
	
	// Invoice for payment
	PrintCommand = PrintCommands.Add();
	PrintCommand.ID							= "ProformaInvoice";
	PrintCommand.Presentation				= NStr("en='Proforma invoice';ru='Счет на оплату';vi='Hóa đơn thanh toán'");
	PrintCommand.FormsList					= "FormWorkOrder,ListFormWorkOrder,ShipmentDocumentsListForm,PaymentDocumentsListForm";
	PrintCommand.CheckPostingBeforePrint	= False;
	PrintCommand.PlaceProperties			= "GroupImportantCommandsWorkOrder";
	PrintCommand.Order						= 72;
	
	// The invoice for payment with facsimile
	PrintCommand = PrintCommands.Add();
	PrintCommand.ID							= "ProformaInvoiceWithSignature";
	PrintCommand.Presentation				= NStr("en='Proforma invoice (with signature)';ru='Счет на оплату (с подписями)';vi='Hóa đơn thanh toán (có chữ ký)'");
	PrintCommand.FormsList					= "FormWorkOrder,ListFormWorkOrder,ShipmentDocumentsListForm,PaymentDocumentsListForm";
	PrintCommand.CheckPostingBeforePrint	= False;
	PrintCommand.PlaceProperties			= "GroupImportantCommandsWorkOrder";
	PrintCommand.Order						= 78;
	
	// Contract
	PrintCommand = PrintCommands.Add();
	PrintCommand.Handler = "SmallBusinessClient.GenerateContractForms";
	PrintCommand.ID = "ContractForm";
	PrintCommand.Presentation = NStr("en='Contract form';ru='Бланк договора';vi='Mẫu hợp đồng'");
	PrintCommand.FormsList = "FormWorkOrder,ListFormWorkOrder,ShipmentDocumentsListForm,PaymentDocumentsListForm";
	PrintCommand.CheckPostingBeforePrint = False;
	PrintCommand.PlaceProperties = "GroupImportantCommandsWorkOrder";
	PrintCommand.Order = 96;
	
	// Appendix to contract
	PrintCommand = PrintCommands.Add();
	PrintCommand.ID = "GuaranteeCard";
	PrintCommand.Presentation = NStr("en='Guarantee card';ru='Гарантийный талон';vi='Thẻ bảo hành'");
	PrintCommand.FormsList = "FormWorkOrder,FormWorkOrderList";
	PrintCommand.CheckPostingBeforePrint = False;
	PrintCommand.FunctionalOptions = "UseSerialNumbers";
	PrintCommand.PlaceProperties = "GroupImportantCommandsWorkOrder";
	PrintCommand.Order = 102;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure FormGetProcessing(FormKind, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	OperationKind = Undefined;
	
	If FormKind = "DocumentForm" Or FormKind = "ObjectForm" Then
		
		If Parameters.Property("Key") AND ValueIsFilled(Parameters.Key) Then
			OperationKind = CommonUse.ObjectAttributeValue(Parameters.Key, "OperationKind");
		EndIf;
		
		// If the document is copied, you receive the kind of operation from copied document.
		If Not ValueIsFilled(OperationKind) Then
			If Parameters.Property("CopyingValue")
				AND ValueIsFilled(Parameters.CopyingValue) Then
				OperationKind = CommonUse.ObjectAttributeValue(Parameters.CopyingValue, "OperationKind");
			EndIf;
		EndIf;
		
		If Not ValueIsFilled(OperationKind) Then
			If Parameters.Property("FillingValues") 
				AND TypeOf(Parameters.FillingValues) = Type("Structure") Then
				If Parameters.FillingValues.Property("OperationKind") Then
					OperationKind = Parameters.FillingValues.OperationKind;
				EndIf;
			EndIf;
		EndIf;
		
		StandardProcessing = False;
		CustomerOrderForms = GetOperationKindMapToForms();
		SelectedForm = CustomerOrderForms[OperationKind];
		If SelectedForm = Undefined Then
			SelectedForm = "DocumentForm";
		EndIf;
		
	ElsIf FormKind = "ListForm" Then
		
		If Parameters.Property("WorkOrder") Then
			OperationKind = Enums.OperationKindsCustomerOrder.WorkOrder;
		EndIf;
		
		// If a selection is set, then you receive operation kind from selection.
		If Not ValueIsFilled(OperationKind) Then
			If Parameters.Property("Filter") AND Parameters.Filter.Property("OperationKind")
				AND TypeOf(Parameters.Filter.OperationKind) = Type("EnumRef.OperationKindsCustomerOrder") Then
				OperationKind = Parameters.Filter.OperationKind;
			EndIf;
		EndIf;
		
		StandardProcessing = False;
		CustomerOrderForms = GetOperationKindMapToForms(True);
		SelectedForm = CustomerOrderForms[OperationKind];
		If SelectedForm = Undefined Then
			SelectedForm = "ListForm";
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	Fields.Add("Ref");
	Fields.Add("Date");
	Fields.Add("Number");
	Fields.Add("OperationKind");
	Fields.Add("Posted");
	Fields.Add("DeletionMark");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	If Data.Number = Null Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	If Data.Posted Then
		State = "";
	Else
		If Data.DeletionMark Then
			State = NStr("en='(deleted)';ru='(удален)';vi='(đã xóa)'");
		ElsIf Data.Property("Posted") AND Not Data.Posted Then
			State = NStr("en='(not posted)';ru='(не проведен)';vi='(chưa kết chuyển)'");
		EndIf;
	EndIf;
	
	If Data.OperationKind = PredefinedValue("Enum.OperationKindsCustomerOrder.WorkOrder") Then
		TitlePresentation = NStr("en='Work order';ru='Заказ-наряд';vi='Đơn hàng trọn gói'");
	Else
		TitlePresentation = NStr("en='Customer order';ru='Заказ покупателя';vi='Đơn hàng của khách'");
	EndIf;
	
	Presentation = StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en='%1 %2 from %3 %4';ru='%1 %2 от %3 %4';vi='%1 %2 ngày %3 %4'"),
		TitlePresentation,
		?(Data.Property("Number"), ObjectPrefixationClientServer.GetNumberForPrinting(Data.Number, True, True), ""),
		Format(Data.Date, "DLF=D"),
		State);
	
EndProcedure

#EndRegion
// Процедура заполняет таблицу описаний расширенного ввода записи календаря
//
// Параметры:
//  ТаблицаОписаний	 - ТаблицаЗначений	 - описание колонок см. Справочник.ЗаписиКалендаряСотрудника.ПриЗаполненииРасширенногоВводаЗаписиКалендаря()
//
Procedure OnFillingExtendedInputCalendarRecorder(DescriptionTable) Export
	
	NewRow = DescriptionTable.Добавить();
	NewRow.FormName = "Document.CustomerOrder.FormWorkOrder";
	NewRow.FormParameters = New Structure("FillValue", Новый Структура("OperationKind", Enums.OperationKindsCustomerOrder.WorkOrder));
	NewRow.Presentation = NStr("en='Work order:';ru='Заказ-наряд:';vi='Đơn hàng sản xuất:'");
	
EndProcedure

// Функция определяет пиктограмму для элемента записи календаря
//
// Параметры:
//  Событие	 - ДокументСсылка.Событие	 - событие, для записи календаря которого подбирается картинка
// 
// Возвращаемое значение:
//  Картинка - пиктограмма записи календаря
//
Function CalendarRecordPicture(Source) Export
	
	Picture = PictureLib.SectionService;
	
	Return Picture;
	
EndFunction

// Функция определяет цвет текста для элемента записи календаря
//
// Параметры:
//  Событие	 - ДокументСсылка.Событие	 - событие, для записи календаря которого подбирается цвет
// 
// Возвращаемое значение:
//  Цвет - цвет текста записи календаря
//
Function CalendarRecorTextColor(Source) Export
	
	StateColor = New Color;

	Return StateColor;
	
EndFunction

#EndIf
