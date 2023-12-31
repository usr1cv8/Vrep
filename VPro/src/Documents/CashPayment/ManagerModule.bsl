#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableCashAssets(DocumentRefCashPayment, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	
	Query.SetParameter("Ref", DocumentRefCashPayment);
	Query.SetParameter("PointInTime", New Boundary(StructureAdditionalProperties.ForPosting.PointInTime, BoundaryType.Including));
	Query.SetParameter("ControlPeriod", StructureAdditionalProperties.ForPosting.PointInTime.Date);
	Query.SetParameter("Company", StructureAdditionalProperties.ForPosting.Company);
	Query.SetParameter("CashExpense", NStr("en='Funds expense:';ru='Расход денежных средств:';vi='Chi tiền:'"));
	Query.SetParameter("ExchangeDifference", NStr("en='Exchange rate difference';ru='Курсовая разница';vi='Chênh lệch tỷ giá'"));
	
	Query.Text =
	"SELECT
	|	1 AS LineNumber,
	|	&CashExpense AS ContentOfAccountingRecord,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DocumentTable.Date AS Date,
	|	DocumentTable.Company AS Company,
	|	VALUE(Enum.CashAssetTypes.Cash) AS CashAssetsType,
	|	DocumentTable.Item AS Item,
	|	DocumentTable.PettyCash AS BankAccountPettyCash,
	|	DocumentTable.CashCurrency AS Currency,
	|	SUM(DocumentTable.Amount) AS Amount,
	|	SUM(DocumentTable.AmountCur) AS AmountCur,
	|	-SUM(DocumentTable.Amount) AS AmountForBalance,
	|	-SUM(DocumentTable.AmountCur) AS AmountCurForBalance,
	|	DocumentTable.PettyCashGLAccount AS GLAccount
	|INTO TemporaryTableCashAssets
	|FROM
	|	TemporaryTableHeader AS DocumentTable
	|WHERE
	|	(DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.ToAdvanceHolder)
	|			OR DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.Other)
	|			OR DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.OtherSettlements)
	|			OR DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.LoanSettlements)
	|			OR DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.IssueLoanToEmployee)
	|			OR DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.TransferToCashCR)
	|			OR DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.Taxes)
	|			OR DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.SalaryForEmployee))
	|
	|GROUP BY
	|	DocumentTable.Date,
	|	DocumentTable.Company,
	|	DocumentTable.Item,
	|	DocumentTable.PettyCash,
	|	DocumentTable.CashCurrency,
	|	DocumentTable.PettyCashGLAccount
	|
	|UNION ALL
	|
	|SELECT
	|	TemporaryTablePaymentDetails.LineNumber,
	|	&CashExpense,
	|	VALUE(AccumulationRecordType.Expense),
	|	TemporaryTablePaymentDetails.Date,
	|	&Company,
	|	VALUE(Enum.CashAssetTypes.Cash),
	|	TemporaryTablePaymentDetails.Item,
	|	TemporaryTablePaymentDetails.PettyCash,
	|	TemporaryTablePaymentDetails.CashCurrency,
	|	SUM(TemporaryTablePaymentDetails.AccountingAmount),
	|	SUM(TemporaryTablePaymentDetails.PaymentAmount),
	|	-SUM(TemporaryTablePaymentDetails.AccountingAmount),
	|	-SUM(TemporaryTablePaymentDetails.PaymentAmount),
	|	TemporaryTablePaymentDetails.BankAccountCashGLAccount
	|FROM
	|	TemporaryTablePaymentDetails AS TemporaryTablePaymentDetails
	|		LEFT JOIN Constants AS Constants
	|		ON (TRUE)
	|WHERE
	|	(TemporaryTablePaymentDetails.OperationKind = VALUE(Enum.OperationKindsCashPayment.Vendor)
	|			OR TemporaryTablePaymentDetails.OperationKind = VALUE(Enum.OperationKindsCashPayment.ToCustomer))
	|
	|GROUP BY
	|	TemporaryTablePaymentDetails.LineNumber,
	|	TemporaryTablePaymentDetails.Date,
	|	TemporaryTablePaymentDetails.Item,
	|	TemporaryTablePaymentDetails.PettyCash,
	|	TemporaryTablePaymentDetails.CashCurrency,
	|	TemporaryTablePaymentDetails.BankAccountCashGLAccount
	|
	|UNION ALL
	|
	|SELECT
	|	MAX(PayrollPayment.LineNumber),
	|	&CashExpense,
	|	VALUE(AccumulationRecordType.Expense),
	|	PayrollPayment.Ref.Date,
	|	&Company,
	|	VALUE(Enum.CashAssetTypes.Cash),
	|	PayrollPayment.Ref.Item,
	|	PayrollPayment.Ref.PettyCash,
	|	PayrollPayment.Ref.CashCurrency,
	|	SUM(CAST(PayrollSheetEmployees.PaymentAmount * CurrencyRatesOfPettyCashe.ExchangeRate * AccountingCurrencyRates.Multiplicity / (AccountingCurrencyRates.ExchangeRate * CurrencyRatesOfPettyCashe.Multiplicity) AS NUMBER(15, 2))),
	|	MIN(PayrollPayment.Ref.DocumentAmount),
	|	-SUM(CAST(PayrollSheetEmployees.PaymentAmount * CurrencyRatesOfPettyCashe.ExchangeRate * AccountingCurrencyRates.Multiplicity / (AccountingCurrencyRates.ExchangeRate * CurrencyRatesOfPettyCashe.Multiplicity) AS NUMBER(15, 2))),
	|	-MIN(PayrollPayment.Ref.DocumentAmount),
	|	PayrollPayment.Ref.PettyCash.GLAccount
	|FROM
	|	Document.PayrollSheet.Employees AS PayrollSheetEmployees
	|		INNER JOIN Document.CashPayment.PayrollPayment AS PayrollPayment
	|			LEFT JOIN InformationRegister.CurrencyRates.SliceLast(&PointInTime, ) AS CurrencyRatesOfPettyCashe
	|			ON PayrollPayment.Ref.CashCurrency = CurrencyRatesOfPettyCashe.Currency
	|		ON PayrollSheetEmployees.Ref = PayrollPayment.Statement
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
	|				&PointInTime,
	|				Currency IN
	|					(SELECT
	|						Constants.AccountingCurrency
	|					FROM
	|						Constants AS Constants)) AS AccountingCurrencyRates
	|		ON (TRUE)
	|		LEFT JOIN Constants AS Constants
	|		ON (TRUE)
	|WHERE
	|	PayrollPayment.Ref = &Ref
	|	AND PayrollPayment.Ref.OperationKind = VALUE(Enum.OperationKindsCashPayment.Salary)
	|
	|GROUP BY
	|	PayrollPayment.Ref.Date,
	|	PayrollPayment.Ref.Item,
	|	PayrollPayment.Ref.PettyCash,
	|	PayrollPayment.Ref.CashCurrency,
	|	PayrollPayment.Ref.PettyCash.GLAccount
	|
	|INDEX BY
	|	Company,
	|	CashAssetsType,
	|	BankAccountPettyCash,
	|	Currency,
	|	GLAccount";
	
	Query.Execute();
	
	// Setting of the exclusive lock of the cash funds controlled balances.
	Query.Text =
	"SELECT
	|	TemporaryTableCashAssets.Company AS Company,
	|	TemporaryTableCashAssets.CashAssetsType AS CashAssetsType,
	|	TemporaryTableCashAssets.BankAccountPettyCash AS BankAccountPettyCash,
	|	TemporaryTableCashAssets.Currency AS Currency
	|FROM
	|	TemporaryTableCashAssets AS TemporaryTableCashAssets";
	
	QueryResult = Query.Execute();
	
	Block = New DataLock;
	LockItem = Block.Add("AccumulationRegister.CashAssets");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = QueryResult;
	
	For Each ColumnQueryResult IN QueryResult.Columns Do
		LockItem.UseFromDataSource(ColumnQueryResult.Name, ColumnQueryResult.Name);
	EndDo;
	Block.Lock();
	
	QueryNumber = 0;
	Query.Text = SmallBusinessServer.GetQueryTextExchangeRateDifferencesCashAssets(Query.TempTablesManager, QueryNumber);
	ResultsArray = Query.ExecuteBatch();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableCashAssets", ResultsArray[QueryNumber].Unload());
	
EndProcedure // GenerateTableCashAssets()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableCashAssetsInCashRegisters(DocumentRefCashReceipt, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	
	"SELECT
	|	1 AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentTable.Date AS Date,
	|	DocumentTable.Company AS Company,
	|	DocumentTable.CashCR AS CashCR,
	|	DocumentTable.CashCurrency AS Currency,
	|	SUM(DocumentTable.Amount) AS Amount,
	|	SUM(DocumentTable.AmountCur) AS AmountCur,
	|	SUM(DocumentTable.Amount) AS AmountForBalance,
	|	SUM(DocumentTable.AmountCur) AS AmountCurForBalance,
	|	DocumentTable.CashCRGLAccount AS GLAccount,
	|	&CashFundsReceipt AS ContentOfAccountingRecord
	|INTO TemporaryTableCashAssetsInRetailCashes
	|FROM
	|	TemporaryTableHeader AS DocumentTable
	|WHERE
	|	DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.TransferToCashCR)
	|
	|GROUP BY
	|	DocumentTable.Date,
	|	DocumentTable.Company,
	|	DocumentTable.CashCR,
	|	DocumentTable.CashCurrency,
	|	DocumentTable.CashCRGLAccount
	|
	|INDEX BY
	|	Company,
	|	CashCR,
	|	Currency,
	|	GLAccount";
	
	Query.SetParameter("Company", StructureAdditionalProperties.ForPosting.Company);
	Query.SetParameter("Ref", DocumentRefCashReceipt);
	Query.SetParameter("PointInTime", New Boundary(StructureAdditionalProperties.ForPosting.PointInTime, BoundaryType.Including));
	Query.SetParameter("ControlPeriod", StructureAdditionalProperties.ForPosting.PointInTime.Date);
	Query.SetParameter("CashFundsReceipt", NStr("en='Cash receipt to cash register';ru='Поступление денежных средств в кассу ККМ';vi='Thu tiền vào quầy thu ngân'"));
	Query.SetParameter("ExchangeDifference", NStr("en='Exchange rate difference';ru='Курсовая разница';vi='Chênh lệch tỷ giá'"));
	
	Query.Execute();
	
	// Setting of the exclusive lock of the cash funds controlled balances.
	Query.Text =
	"SELECT
	|	TemporaryTableCashAssetsInRetailCashes.Company AS Company,
	|	TemporaryTableCashAssetsInRetailCashes.CashCR AS CashCR
	|FROM
	|	TemporaryTableCashAssetsInRetailCashes";
	
	QueryResult = Query.Execute();
	
	Block = New DataLock;
	LockItem = Block.Add("AccumulationRegister.CashInCashRegisters");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = QueryResult;
	
	For Each ColumnQueryResult IN QueryResult.Columns Do
		LockItem.UseFromDataSource(ColumnQueryResult.Name, ColumnQueryResult.Name);
	EndDo;
	Block.Lock();
	
	QueryNumber = 0;
	Query.Text = SmallBusinessServer.GetQueryTextExchangeRateDifferencesCashInCashRegisters(Query.TempTablesManager, QueryNumber);
	ResultsArray = Query.ExecuteBatch();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableCashInCashRegisters", ResultsArray[QueryNumber].Unload());
	
EndProcedure // GenerateTableCashAssetsInCashRegisters()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateAdvanceHolderPaymentsTable(DocumentRefCashPayment, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	
	Query.SetParameter("Ref", DocumentRefCashPayment);
	Query.SetParameter("PointInTime", New Boundary(StructureAdditionalProperties.ForPosting.PointInTime, BoundaryType.Including));
	Query.SetParameter("ControlPeriod", StructureAdditionalProperties.ForPosting.PointInTime.Date);
	Query.SetParameter("Company", StructureAdditionalProperties.ForPosting.Company);
	Query.SetParameter("AdvanceHolderDebtEmergence", NStr("en=""Incurring of advance holder's debt"";ru='Возникновение долга подотчетника';vi='Phát sinh công nợ của người nhận tạm ứng'"));
	Query.SetParameter("ExchangeDifference", NStr("en='Exchange rate difference';ru='Курсовая разница';vi='Chênh lệch tỷ giá'"));
	
	Query.Text =
	"SELECT
	|	1 AS LineNumber,
	|	&AdvanceHolderDebtEmergence AS ContentOfAccountingRecord,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentTable.PettyCash AS PettyCash,
	|	CASE
	|		WHEN DocumentTable.Document = VALUE(Document.ExpenseReport.EmptyRef)
	|			THEN &Ref
	|		ELSE DocumentTable.Document
	|	END AS Document,
	|	DocumentTable.AdvanceHolder AS Employee,
	|	DocumentTable.Date AS Date,
	|	&Company AS Company,
	|	DocumentTable.CashCurrency AS Currency,
	|	SUM(DocumentTable.Amount) AS Amount,
	|	SUM(DocumentTable.AmountCur) AS AmountCur,
	|	SUM(DocumentTable.Amount) AS AmountForBalance,
	|	SUM(DocumentTable.AmountCur) AS AmountCurForBalance,
	|	CASE
	|		WHEN DocumentTable.Document = VALUE(Document.ExpenseReport.EmptyRef)
	|			THEN DocumentTable.AdvanceHolder.AdvanceHoldersGLAccount
	|		ELSE DocumentTable.AdvanceHolder.OverrunGLAccount
	|	END AS GLAccount
	|INTO TemporaryTableAdvanceHolderPayments
	|FROM
	|	TemporaryTableHeader AS DocumentTable
	|WHERE
	|	DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.ToAdvanceHolder)
	|
	|GROUP BY
	|	DocumentTable.PettyCash,
	|	DocumentTable.AdvanceHolder,
	|	DocumentTable.Date,
	|	DocumentTable.CashCurrency,
	|	CASE
	|		WHEN DocumentTable.Document = VALUE(Document.ExpenseReport.EmptyRef)
	|			THEN &Ref
	|		ELSE DocumentTable.Document
	|	END,
	|	CASE
	|		WHEN DocumentTable.Document = VALUE(Document.ExpenseReport.EmptyRef)
	|			THEN DocumentTable.AdvanceHolder.AdvanceHoldersGLAccount
	|		ELSE DocumentTable.AdvanceHolder.OverrunGLAccount
	|	END
	|
	|INDEX BY
	|	Company,
	|	Employee,
	|	Currency,
	|	Document,
	|	GLAccount";
	
	Query.Execute();
	
	// Setting the exclusive lock of controlled balances of payments to accountable persons.
	Query.Text =
	"SELECT
	|	TemporaryTableAdvanceHolderPayments.Company AS Company,
	|	TemporaryTableAdvanceHolderPayments.Employee AS Employee,
	|	TemporaryTableAdvanceHolderPayments.Currency AS Currency,
	|	TemporaryTableAdvanceHolderPayments.Document AS Document
	|FROM
	|	TemporaryTableAdvanceHolderPayments AS TemporaryTableAdvanceHolderPayments";
	
	QueryResult = Query.Execute();
	
	Block = New DataLock;
	LockItem = Block.Add("AccumulationRegister.AdvanceHolderPayments");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = QueryResult;
	
	For Each ColumnQueryResult IN QueryResult.Columns Do
		LockItem.UseFromDataSource(ColumnQueryResult.Name, ColumnQueryResult.Name);
	EndDo;
	Block.Lock();
	
	QueryNumber = 0;
	Query.Text = SmallBusinessServer.GetQueryTextCurrencyExchangeRateAdvanceHolderPayments(Query.TempTablesManager, QueryNumber);
	ResultsArray = Query.ExecuteBatch();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableSettlementsWithAdvanceHolders", ResultsArray[QueryNumber].Unload());
	
EndProcedure // GenerateTableAdvanceHolderPayments()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableAccountsPayable(DocumentRefCashPayment, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	
	Query.SetParameter("Ref", DocumentRefCashPayment);
	Query.SetParameter("PointInTime", New Boundary(StructureAdditionalProperties.ForPosting.PointInTime, BoundaryType.Including));
	Query.SetParameter("ControlPeriod", StructureAdditionalProperties.ForPosting.PointInTime.Date);
	Query.SetParameter("Company", StructureAdditionalProperties.ForPosting.Company);
	Query.SetParameter("AppearenceOfVendorAdvance", "Appearence of vendor advance");
	Query.SetParameter("VendorObligationsRepayment", "Repayment of obligations to vendor");
	Query.SetParameter("ExchangeDifference", NStr("en='Exchange rate difference';ru='Курсовая разница';vi='Chênh lệch tỷ giá'"));
	
	Query.Text =
	"SELECT
	|	TemporaryTablePaymentDetails.LineNumber AS LineNumber,
	|	CASE
	|		WHEN TemporaryTablePaymentDetails.DoOperationsByDocuments
	|			THEN CASE
	|					WHEN TemporaryTablePaymentDetails.AdvanceFlag
	|						THEN &Ref
	|					ELSE TemporaryTablePaymentDetails.Document
	|				END
	|		ELSE UNDEFINED
	|	END AS Document,
	|	&Company AS Company,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	TemporaryTablePaymentDetails.PettyCash AS PettyCash,
	|	TemporaryTablePaymentDetails.Counterparty AS Counterparty,
	|	TemporaryTablePaymentDetails.Contract AS Contract,
	|	CASE
	|		WHEN TemporaryTablePaymentDetails.DoOperationsByOrders
	|			THEN TemporaryTablePaymentDetails.Order
	|		ELSE VALUE(Document.PurchaseOrder.EmptyRef)
	|	END AS Order,
	|	CASE
	|		WHEN TemporaryTablePaymentDetails.AdvanceFlag
	|			THEN VALUE(Enum.SettlementsTypes.Advance)
	|		ELSE VALUE(Enum.SettlementsTypes.Debt)
	|	END AS SettlementsType,
	|	TemporaryTablePaymentDetails.Date AS Date,
	|	SUM(TemporaryTablePaymentDetails.PaymentAmount) AS PaymentAmount,
	|	SUM(TemporaryTablePaymentDetails.AccountingAmount) AS Amount,
	|	SUM(TemporaryTablePaymentDetails.SettlementsAmount) AS AmountCur,
	|	-SUM(TemporaryTablePaymentDetails.AccountingAmount) AS AmountForBalance,
	|	-SUM(TemporaryTablePaymentDetails.SettlementsAmount) AS AmountCurForBalance,
	|	CASE
	|		WHEN TemporaryTablePaymentDetails.AdvanceFlag
	|			THEN TemporaryTablePaymentDetails.VendorAdvancesGLAccount
	|		ELSE TemporaryTablePaymentDetails.GLAccountVendorSettlements
	|	END AS GLAccount,
	|	TemporaryTablePaymentDetails.SettlementsCurrency AS Currency,
	|	TemporaryTablePaymentDetails.CashCurrency AS CashCurrency,
	|	CASE
	|		WHEN TemporaryTablePaymentDetails.AdvanceFlag
	|			THEN &AppearenceOfVendorAdvance
	|		ELSE &VendorObligationsRepayment
	|	END AS ContentOfAccountingRecord
	|INTO TemporaryTableAccountsPayable
	|FROM
	|	TemporaryTablePaymentDetails AS TemporaryTablePaymentDetails
	|WHERE
	|	TemporaryTablePaymentDetails.OperationKind = VALUE(Enum.OperationKindsCashPayment.Vendor)
	|
	|GROUP BY
	|	TemporaryTablePaymentDetails.LineNumber,
	|	TemporaryTablePaymentDetails.PettyCash,
	|	TemporaryTablePaymentDetails.Counterparty,
	|	TemporaryTablePaymentDetails.Contract,
	|	TemporaryTablePaymentDetails.Date,
	|	TemporaryTablePaymentDetails.SettlementsCurrency,
	|	TemporaryTablePaymentDetails.CashCurrency,
	|	CASE
	|		WHEN TemporaryTablePaymentDetails.DoOperationsByDocuments
	|			THEN CASE
	|					WHEN TemporaryTablePaymentDetails.AdvanceFlag
	|						THEN &Ref
	|					ELSE TemporaryTablePaymentDetails.Document
	|				END
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN TemporaryTablePaymentDetails.DoOperationsByOrders
	|			THEN TemporaryTablePaymentDetails.Order
	|		ELSE VALUE(Document.PurchaseOrder.EmptyRef)
	|	END,
	|	CASE
	|		WHEN TemporaryTablePaymentDetails.AdvanceFlag
	|			THEN VALUE(Enum.SettlementsTypes.Advance)
	|		ELSE VALUE(Enum.SettlementsTypes.Debt)
	|	END,
	|	CASE
	|		WHEN TemporaryTablePaymentDetails.AdvanceFlag
	|			THEN TemporaryTablePaymentDetails.VendorAdvancesGLAccount
	|		ELSE TemporaryTablePaymentDetails.GLAccountVendorSettlements
	|	END,
	|	CASE
	|		WHEN TemporaryTablePaymentDetails.AdvanceFlag
	|			THEN &AppearenceOfVendorAdvance
	|		ELSE &VendorObligationsRepayment
	|	END
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
	|	TemporaryTableAccountsPayable";
	
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
	Query.Text = SmallBusinessServer.GetQueryTextExchangeRatesDifferencesAccountsPayable(Query.TempTablesManager, False, QueryNumber);
	ResultsArray = Query.ExecuteBatch();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableAccountsPayable", ResultsArray[QueryNumber].Unload());
	
EndProcedure // GenerateTableAccountsPayable()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableCustomerAccounts(DocumentRefCashPayment, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	
	Query.SetParameter("Ref", DocumentRefCashPayment);
	Query.SetParameter("PointInTime", New Boundary(StructureAdditionalProperties.ForPosting.PointInTime, BoundaryType.Including));
	Query.SetParameter("ControlPeriod", StructureAdditionalProperties.ForPosting.PointInTime.Date);
	Query.SetParameter("Company", StructureAdditionalProperties.ForPosting.Company);
	Query.SetParameter("CustomerAdvanceRepayment", NStr("en='Customer advance repayment';ru='Погашение аванса покупателя';vi='Khách hàng trả tiền ứng trước'"));
	Query.SetParameter("AppearenceOfCustomerLiability", NStr("en='Incurrence of customer liabilities';ru='Возникновение обязательств покупателя';vi='Phát sinh công nợ phải thu khách hàng'"));
	Query.SetParameter("ExchangeDifference", NStr("en='Exchange rate difference';ru='Курсовая разница';vi='Chênh lệch tỷ giá'"));
	
	Query.Text =
	"SELECT
	|	TemporaryTablePaymentDetails.LineNumber AS LineNumber,
	|	CASE
	|		WHEN TemporaryTablePaymentDetails.DoOperationsByDocuments
	|			THEN TemporaryTablePaymentDetails.Document
	|		ELSE UNDEFINED
	|	END AS Document,
	|	&Company AS Company,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TemporaryTablePaymentDetails.PettyCash AS PettyCash,
	|	TemporaryTablePaymentDetails.Counterparty AS Counterparty,
	|	TemporaryTablePaymentDetails.Contract AS Contract,
	|	CASE
	|		WHEN TemporaryTablePaymentDetails.DoOperationsByOrders
	|			THEN TemporaryTablePaymentDetails.Order
	|		ELSE VALUE(Document.CustomerOrder.EmptyRef)
	|	END AS Order,
	|	CASE
	|		WHEN TemporaryTablePaymentDetails.AdvanceFlag
	|			THEN VALUE(Enum.SettlementsTypes.Advance)
	|		ELSE VALUE(Enum.SettlementsTypes.Debt)
	|	END AS SettlementsType,
	|	TemporaryTablePaymentDetails.Date AS Date,
	|	SUM(TemporaryTablePaymentDetails.PaymentAmount) AS PaymentAmount,
	|	SUM(TemporaryTablePaymentDetails.AccountingAmount) AS Amount,
	|	SUM(TemporaryTablePaymentDetails.SettlementsAmount) AS AmountCur,
	|	SUM(TemporaryTablePaymentDetails.AccountingAmount) AS AmountForBalance,
	|	SUM(TemporaryTablePaymentDetails.SettlementsAmount) AS AmountCurForBalance,
	|	CASE
	|		WHEN TemporaryTablePaymentDetails.AdvanceFlag
	|			THEN TemporaryTablePaymentDetails.CustomerAdvancesGLAccount
	|		ELSE TemporaryTablePaymentDetails.GLAccountCustomerSettlements
	|	END AS GLAccount,
	|	TemporaryTablePaymentDetails.SettlementsCurrency AS Currency,
	|	TemporaryTablePaymentDetails.CashCurrency AS CashCurrency,
	|	CASE
	|		WHEN TemporaryTablePaymentDetails.AdvanceFlag
	|			THEN &CustomerAdvanceRepayment
	|		ELSE &AppearenceOfCustomerLiability
	|	END AS ContentOfAccountingRecord
	|INTO TemporaryTableAccountsReceivable
	|FROM
	|	TemporaryTablePaymentDetails AS TemporaryTablePaymentDetails
	|WHERE
	|	TemporaryTablePaymentDetails.OperationKind = VALUE(Enum.OperationKindsCashPayment.ToCustomer)
	|
	|GROUP BY
	|	TemporaryTablePaymentDetails.LineNumber,
	|	TemporaryTablePaymentDetails.PettyCash,
	|	TemporaryTablePaymentDetails.Counterparty,
	|	TemporaryTablePaymentDetails.Contract,
	|	TemporaryTablePaymentDetails.Date,
	|	TemporaryTablePaymentDetails.SettlementsCurrency,
	|	TemporaryTablePaymentDetails.CashCurrency,
	|	CASE
	|		WHEN TemporaryTablePaymentDetails.DoOperationsByDocuments
	|			THEN TemporaryTablePaymentDetails.Document
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN TemporaryTablePaymentDetails.DoOperationsByOrders
	|			THEN TemporaryTablePaymentDetails.Order
	|		ELSE VALUE(Document.CustomerOrder.EmptyRef)
	|	END,
	|	CASE
	|		WHEN TemporaryTablePaymentDetails.AdvanceFlag
	|			THEN VALUE(Enum.SettlementsTypes.Advance)
	|		ELSE VALUE(Enum.SettlementsTypes.Debt)
	|	END,
	|	CASE
	|		WHEN TemporaryTablePaymentDetails.AdvanceFlag
	|			THEN TemporaryTablePaymentDetails.CustomerAdvancesGLAccount
	|		ELSE TemporaryTablePaymentDetails.GLAccountCustomerSettlements
	|	END,
	|	CASE
	|		WHEN TemporaryTablePaymentDetails.AdvanceFlag
	|			THEN &CustomerAdvanceRepayment
	|		ELSE &AppearenceOfCustomerLiability
	|	END
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
	
EndProcedure // GenerateTableAccountsReceivable()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTablePayrollPayments(DocumentRefCashPayment, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	
	Query.SetParameter("Ref", DocumentRefCashPayment);
	Query.SetParameter("PointInTime", New Boundary(StructureAdditionalProperties.ForPosting.PointInTime, BoundaryType.Including));
	Query.SetParameter("ControlPeriod", StructureAdditionalProperties.ForPosting.PointInTime.Date);
	Query.SetParameter("Company", StructureAdditionalProperties.ForPosting.Company);
	Query.SetParameter("RepaymentLiabilitiesToEmployees", NStr("en=""Employees' liability repayment to personnel"";ru='Погашение обязательств перед персоналом';vi='Giảm trừ công nợ phải trả người lao động'"));
	Query.SetParameter("ExchangeDifference", NStr("en='Exchange rate difference';ru='Курсовая разница';vi='Chênh lệch tỷ giá'"));
	
	Query.Text =
	"SELECT
	|	PayrollSheet.Ref
	|FROM
	|	Document.PayrollSheet AS PayrollSheet
	|WHERE
	|	PayrollSheet.Ref In
	|			(SELECT
	|				PayrollPayment.Statement
	|			FROM
	|				Document.CashPayment.PayrollPayment AS PayrollPayment
	|			WHERE
	|				PayrollPayment.Ref = &Ref
	|				AND PayrollPayment.Ref.OperationKind = VALUE(Enum.OperationKindsCashPayment.Salary))";
	
	QueryResult = Query.Execute();
	
	Block = New DataLock;
	LockItem = Block.Add("Document.PayrollSheet");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = QueryResult;
	
	For Each ColumnQueryResult in QueryResult.Columns Do
		LockItem.UseFromDataSource(ColumnQueryResult.Name, ColumnQueryResult.Name);
	EndDo;
	Block.Lock();
	
	Query.Text =
	"SELECT
	|	MAX(PayrollPayment.LineNumber) AS LineNumber,
	|	&Company AS Company,
	|	PayrollPayment.Ref.Date AS Date,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	PayrollSheetEmployees.Ref.StructuralUnit AS StructuralUnit,
	|	PayrollSheetEmployees.Employee AS Employee,
	|	PayrollSheetEmployees.Ref.SettlementsCurrency AS Currency,
	|	PayrollSheetEmployees.Ref.RegistrationPeriod AS RegistrationPeriod,
	|	SUM(CAST(PayrollSheetEmployees.PaymentAmount * CurrencyRatesOfPettyCashe.ExchangeRate * AccountingCurrencyRates.Multiplicity / (AccountingCurrencyRates.ExchangeRate * CurrencyRatesOfPettyCashe.Multiplicity) AS NUMBER(15, 2))) AS Amount,
	|	SUM(PayrollSheetEmployees.SettlementsAmount) AS AmountCur,
	|	-SUM(CAST(PayrollSheetEmployees.PaymentAmount * CurrencyRatesOfPettyCashe.ExchangeRate * AccountingCurrencyRates.Multiplicity / (AccountingCurrencyRates.ExchangeRate * CurrencyRatesOfPettyCashe.Multiplicity) AS NUMBER(15, 2))) AS AmountForBalance,
	|	-SUM(PayrollSheetEmployees.SettlementsAmount) AS AmountCurForBalance,
	|	PayrollSheetEmployees.Employee.SettlementsHumanResourcesGLAccount AS GLAccount,
	|	&RepaymentLiabilitiesToEmployees AS ContentOfAccountingRecord,
	|	PayrollPayment.Ref.PettyCash.GLAccount AS PettyCashGLAccount
	|INTO TemporaryTablePayrollPayments
	|FROM
	|	Document.PayrollSheet.Employees AS PayrollSheetEmployees
	|		INNER JOIN Document.CashPayment.PayrollPayment AS PayrollPayment
	|			LEFT JOIN InformationRegister.CurrencyRates.SliceLast(&PointInTime, ) AS CurrencyRatesOfPettyCashe
	|			ON PayrollPayment.Ref.CashCurrency = CurrencyRatesOfPettyCashe.Currency
	|		ON PayrollSheetEmployees.Ref = PayrollPayment.Statement
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
	|				&PointInTime,
	|				Currency In
	|					(SELECT
	|						Constants.AccountingCurrency
	|					FROM
	|						Constants AS Constants)) AS AccountingCurrencyRates
	|		ON (TRUE)
	|WHERE
	|	PayrollPayment.Ref = &Ref
	|	AND PayrollPayment.Ref.OperationKind = VALUE(Enum.OperationKindsCashPayment.Salary)
	|
	|GROUP BY
	|	PayrollPayment.Ref.Date,
	|	PayrollSheetEmployees.Ref.StructuralUnit,
	|	PayrollSheetEmployees.Employee,
	|	PayrollSheetEmployees.Ref.SettlementsCurrency,
	|	PayrollSheetEmployees.Ref.RegistrationPeriod,
	|	PayrollSheetEmployees.Employee.SettlementsHumanResourcesGLAccount,
	|	PayrollPayment.Ref.PettyCash,
	|	PayrollPayment.Ref.PettyCash.GLAccount
	|
	|UNION ALL
	|
	|SELECT
	|	1,
	|	&Company,
	|	DocumentTable.Date,
	|	VALUE(AccumulationRecordType.Expense),
	|	DocumentTable.Department,
	|	DocumentTable.AdvanceHolder,
	|	DocumentTable.CashCurrency,
	|	DocumentTable.RegistrationPeriod,
	|	SUM(DocumentTable.Amount),
	|	SUM(DocumentTable.AmountCur),
	|	-SUM(DocumentTable.Amount),
	|	-SUM(DocumentTable.AmountCur),
	|	DocumentTable.AdvanceHolderPersonnelGLAccount,
	|	&RepaymentLiabilitiesToEmployees,
	|	DocumentTable.PettyCashGLAccount
	|FROM
	|	TemporaryTableHeader AS DocumentTable
	|WHERE
	|	DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.SalaryForEmployee)
	|
	|GROUP BY
	|	DocumentTable.Date,
	|	DocumentTable.Department,
	|	DocumentTable.AdvanceHolder,
	|	DocumentTable.CashCurrency,
	|	DocumentTable.RegistrationPeriod,
	|	DocumentTable.AdvanceHolderPersonnelGLAccount,
	|	DocumentTable.PettyCashGLAccount
	|
	|INDEX BY
	|	Company,
	|	StructuralUnit,
	|	Employee,
	|	Currency,
	|	RegistrationPeriod,
	|	GLAccount";
	
	Query.Execute();
	
	// Setting the exclusive lock for the controlled balances of settlements with suppliers.
	Query.Text =
	"SELECT
	|	TemporaryTablePayrollPayments.Company AS Company,
	|	TemporaryTablePayrollPayments.StructuralUnit AS StructuralUnit,
	|	TemporaryTablePayrollPayments.Employee AS Employee,
	|	TemporaryTablePayrollPayments.Currency AS Currency,
	|	TemporaryTablePayrollPayments.RegistrationPeriod AS RegistrationPeriod
	|FROM
	|	TemporaryTablePayrollPayments AS TemporaryTablePayrollPayments";
	
	QueryResult = Query.Execute();
	
	Block = New DataLock;
	LockItem = Block.Add("AccumulationRegister.PayrollPayments");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = QueryResult;
	
	For Each ColumnQueryResult in QueryResult.Columns Do
		LockItem.UseFromDataSource(ColumnQueryResult.Name, ColumnQueryResult.Name);
	EndDo;
	Block.Lock();
	
	QueryNumber = 0;
	Query.Text = SmallBusinessServer.GetQueryTextExchangeRateDifferencesPayrollPayments(Query.TempTablesManager, QueryNumber);
	ResultsArray = Query.ExecuteBatch();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TablePayrollPayments", ResultsArray[QueryNumber].Unload());
	
EndProcedure // GenerateTablePayrollPayments()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableIncomeAndExpenses(DocumentRefCashPayment, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	
	Query.SetParameter("Ref", DocumentRefCashPayment);
	Query.SetParameter("Company", StructureAdditionalProperties.ForPosting.Company);
	Query.SetParameter("PointInTime", New Boundary(StructureAdditionalProperties.ForPosting.PointInTime, BoundaryType.Including));
	Query.SetParameter("CostsReflection", NStr("en='Record expenses';ru='Отражение расходов';vi='Phản ánh chi phí'"));
	Query.SetParameter("ExchangeDifference", NStr("en='Exchange rate difference';ru='Курсовая разница';vi='Chênh lệch tỷ giá'"));
	
	Query.Text =
	"SELECT
	|	1 AS Order,
	|	2 AS LineNumber,
	|	DocumentTable.Date AS Period,
	|	&Company AS Company,
	|	CASE
	|		WHEN DocumentTable.CorrespondenceGLAccountType = VALUE(Enum.GLAccountsTypes.Expenses)
	|			THEN DocumentTable.Department
	|		ELSE UNDEFINED
	|	END AS StructuralUnit,
	|	CASE
	|		WHEN DocumentTable.CorrespondenceGLAccountType = VALUE(Enum.GLAccountsTypes.Expenses)
	|			THEN DocumentTable.Order
	|		ELSE UNDEFINED
	|	END AS CustomerOrder,
	|	CASE
	|		WHEN DocumentTable.CorrespondenceGLAccountType = VALUE(Enum.GLAccountsTypes.Expenses)
	|			THEN DocumentTable.BusinessActivity
	|		ELSE VALUE(Catalog.BusinessActivities.Other)
	|	END AS BusinessActivity,
	|	DocumentTable.Correspondence AS GLAccount,
	|	&CostsReflection AS ContentOfAccountingRecord,
	|	0 AS AmountIncome,
	|	DocumentTable.Amount AS AmountExpense,
	|	DocumentTable.Amount AS Amount
	|FROM
	|	TemporaryTableHeader AS DocumentTable
	|WHERE
	|	(DocumentTable.Correspondence.TypeOfAccount = VALUE(Enum.GLAccountsTypes.Expenses)
	|			OR DocumentTable.Correspondence.TypeOfAccount = VALUE(Enum.GLAccountsTypes.OtherExpenses))
	|	AND (DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.Other)
	|			OR DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.OtherSettlements))
	|
	|UNION ALL
	|
	|SELECT
	|	2,
	|	DocumentTable.LineNumber,
	|	DocumentTable.Date,
	|	DocumentTable.Company,
	|	UNDEFINED,
	|	UNDEFINED,
	|	VALUE(Catalog.BusinessActivities.Other),
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|			THEN VALUE(ChartOfAccounts.Managerial.OtherIncome)
	|		ELSE VALUE(ChartOfAccounts.Managerial.OtherExpenses)
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
	|	TemporaryTableExchangeRateLossesBanking AS DocumentTable
	|
	|UNION ALL
	|
	|SELECT
	|	3,
	|	DocumentTable.LineNumber,
	|	DocumentTable.Date,
	|	DocumentTable.Company,
	|	UNDEFINED,
	|	UNDEFINED,
	|	VALUE(Catalog.BusinessActivities.Other),
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|			THEN VALUE(ChartOfAccounts.Managerial.OtherIncome)
	|		ELSE VALUE(ChartOfAccounts.Managerial.OtherExpenses)
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
	|	TemporaryTableExchangeDifferencesCalculationWithAdvanceHolder AS DocumentTable
	|
	|UNION ALL
	|
	|SELECT
	|	4,
	|	DocumentTable.LineNumber,
	|	DocumentTable.Date,
	|	DocumentTable.Company,
	|	UNDEFINED,
	|	UNDEFINED,
	|	VALUE(Catalog.BusinessActivities.Other),
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|			THEN VALUE(ChartOfAccounts.Managerial.OtherExpenses)
	|		ELSE VALUE(ChartOfAccounts.Managerial.OtherIncome)
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
	|	TemporaryTableOfExchangeRateDifferencesAccountsPayable AS DocumentTable
	|
	|UNION ALL
	|
	|SELECT
	|	5,
	|	DocumentTable.LineNumber,
	|	DocumentTable.Date,
	|	DocumentTable.Company,
	|	UNDEFINED,
	|	UNDEFINED,
	|	VALUE(Catalog.BusinessActivities.Other),
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|			THEN VALUE(ChartOfAccounts.Managerial.OtherIncome)
	|		ELSE VALUE(ChartOfAccounts.Managerial.OtherExpenses)
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
	|UNION ALL
	|
	|SELECT
	|	6,
	|	DocumentTable.LineNumber,
	|	DocumentTable.Date,
	|	DocumentTable.Company,
	|	UNDEFINED,
	|	UNDEFINED,
	|	VALUE(Catalog.BusinessActivities.Other),
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|			THEN VALUE(ChartOfAccounts.Managerial.OtherExpenses)
	|		ELSE VALUE(ChartOfAccounts.Managerial.OtherIncome)
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
	|	TemporaryTableExchangeDifferencesPayrollPayments AS DocumentTable
	|
	|UNION ALL
	|
	|SELECT
	|	7,
	|	DocumentTable.LineNumber,
	|	DocumentTable.Date,
	|	DocumentTable.Company,
	|	UNDEFINED,
	|	UNDEFINED,
	|	VALUE(Catalog.BusinessActivities.Other),
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|			THEN VALUE(ChartOfAccounts.Managerial.OtherIncome)
	|		ELSE VALUE(ChartOfAccounts.Managerial.OtherExpenses)
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
	|	TemporaryTableExchangeRateLossesCashAssetsInRetailCashes AS DocumentTable
	|
	|UNION ALL
	|
	|SELECT
	|	8,
	|	DocumentTable.LineNumber,
	|	DocumentTable.Date,
	|	DocumentTable.Company,
	|	UNDEFINED,
	|	UNDEFINED,
	|	VALUE(Catalog.BusinessActivities.Other),
	|	CASE
	|		WHEN DocumentTable.ExchangeRateDifferenceAmount > 0
	|			THEN VALUE(ChartOfAccounts.Managerial.OtherIncome)
	|		ELSE VALUE(ChartOfAccounts.Managerial.OtherExpenses)
	|	END,
	|	&ExchangeDifference,
	|	CASE
	|		WHEN DocumentTable.ExchangeRateDifferenceAmount > 0
	|			THEN DocumentTable.ExchangeRateDifferenceAmount
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DocumentTable.ExchangeRateDifferenceAmount > 0
	|			THEN 0
	|		ELSE -DocumentTable.ExchangeRateDifferenceAmount
	|	END,
	|	CASE
	|		WHEN DocumentTable.ExchangeRateDifferenceAmount > 0
	|			THEN DocumentTable.ExchangeRateDifferenceAmount
	|		ELSE -DocumentTable.ExchangeRateDifferenceAmount
	|	END
	|FROM
	|	ExchangeDifferencesTemporaryTableOtherSettlements AS DocumentTable
	|
	|UNION ALL
	|
	|SELECT
	|	9,
	|	DocumentTable.LineNumber,
	|	DocumentTable.Date,
	|	DocumentTable.Company,
	|	UNDEFINED,
	|	UNDEFINED,
	|	VALUE(Catalog.BusinessActivities.Other),
	|	CASE
	|		WHEN DocumentTable.ExchangeRateDifferenceAmount > 0
	|			THEN VALUE(ChartOfAccounts.Managerial.OtherIncome)
	|		ELSE VALUE(ChartOfAccounts.Managerial.OtherExpenses)
	|	END,
	|	&ExchangeDifference,
	|	CASE
	|		WHEN DocumentTable.ExchangeRateDifferenceAmount > 0
	|			THEN DocumentTable.ExchangeRateDifferenceAmount
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DocumentTable.ExchangeRateDifferenceAmount > 0
	|			THEN 0
	|		ELSE -DocumentTable.ExchangeRateDifferenceAmount
	|	END,
	|	CASE
	|		WHEN DocumentTable.ExchangeRateDifferenceAmount > 0
	|			THEN DocumentTable.ExchangeRateDifferenceAmount
	|		ELSE -DocumentTable.ExchangeRateDifferenceAmount
	|	END
	|FROM
	|	TemporaryTableExchangeRateDifferencesLoanSettlements AS DocumentTable
	|
	|ORDER BY
	|	Order,
	|	LineNumber";
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableIncomeAndExpenses", QueryResult.Unload());
	
EndProcedure // GenerateTableIncomeAndExpenses()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableManagerial(DocumentRefCashPayment, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	
	Query.SetParameter("Ref", DocumentRefCashPayment);
	Query.SetParameter("Company", StructureAdditionalProperties.ForPosting.Company);
	Query.SetParameter("PointInTime", New Boundary(StructureAdditionalProperties.ForPosting.PointInTime, BoundaryType.Including));
	Query.SetParameter("ExchangeDifference", NStr("en='Exchange rate difference';ru='Курсовая разница';vi='Chênh lệch tỷ giá'"));
	Query.SetParameter("Content", NStr("en='Funds debiting to arbitrary account';ru='Списание денежных средств на произвольный счет';vi='Ghi giảm tiền vào tài khoản tùy ý'"));
	Query.SetParameter("ContentTransferToCashCR", NStr("en='Cash transfer to cash register';ru='Перемещение денежных средств в кассу ККМ';vi='Chuyển tiền vào quầy thu ngân'"));
	Query.SetParameter("TaxPay", NStr("en='Tax payment';ru='Оплата налога';vi='Trả tiền thuế'"));
	
	Query.Text =
	"SELECT
	|	1 AS Order,
	|	1 AS LineNumber,
	|	DocumentTable.Date AS Period,
	|	&Company AS Company,
	|	VALUE(Catalog.PlanningPeriods.Actual) AS PlanningPeriod,
	|	DocumentTable.Correspondence AS AccountDr,
	|	DocumentTable.PettyCashGLAccount AS AccountCr,
	|	CASE
	|		WHEN DocumentTable.Correspondence.Currency
	|			THEN DocumentTable.CashCurrency
	|		ELSE UNDEFINED
	|	END AS CurrencyDr,
	|	CASE
	|		WHEN DocumentTable.PettyCash.GLAccount.Currency
	|			THEN DocumentTable.CashCurrency
	|		ELSE UNDEFINED
	|	END AS CurrencyCr,
	|	CASE
	|		WHEN DocumentTable.Correspondence.Currency
	|			THEN DocumentTable.AmountCur
	|		ELSE 0
	|	END AS AmountCurDr,
	|	CASE
	|		WHEN DocumentTable.PettyCash.GLAccount.Currency
	|			THEN DocumentTable.AmountCur
	|		ELSE 0
	|	END AS AmountCurCr,
	|	DocumentTable.Amount AS Amount,
	|	CAST(&Content AS STRING(100)) AS Content
	|FROM
	|	TemporaryTableHeader AS DocumentTable
	|WHERE
	|	DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.Other)
	|
	|UNION ALL
	|
	|SELECT
	|	2,
	|	1,
	|	DocumentTable.Date,
	|	&Company,
	|	VALUE(Catalog.PlanningPeriods.Actual),
	|	DocumentTable.CashCRGLAccount,
	|	DocumentTable.PettyCashGLAccount,
	|	CASE
	|		WHEN DocumentTable.CashCRGLAccount.Currency
	|			THEN DocumentTable.CashCurrency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.PettyCashGLAccount.Currency
	|			THEN DocumentTable.CashCurrency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.CashCRGLAccount.Currency
	|			THEN DocumentTable.AmountCur
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DocumentTable.PettyCashGLAccount.Currency
	|			THEN DocumentTable.AmountCur
	|		ELSE 0
	|	END,
	|	DocumentTable.Amount,
	|	CAST(&ContentTransferToCashCR AS STRING(100))
	|FROM
	|	TemporaryTableHeader AS DocumentTable
	|WHERE
	|	DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.TransferToCashCR)
	|
	|UNION ALL
	|
	|SELECT
	|	3,
	|	1,
	|	DocumentTable.Date,
	|	&Company,
	|	VALUE(Catalog.PlanningPeriods.Actual),
	|	DocumentTable.TaxKindGLAccount,
	|	DocumentTable.PettyCashGLAccount,
	|	CASE
	|		WHEN DocumentTable.TaxKind.GLAccount.Currency
	|			THEN DocumentTable.CashCurrency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.PettyCash.GLAccount.Currency
	|			THEN DocumentTable.CashCurrency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.TaxKind.GLAccount.Currency
	|			THEN DocumentTable.AmountCur
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DocumentTable.PettyCash.GLAccount.Currency
	|			THEN DocumentTable.AmountCur
	|		ELSE 0
	|	END,
	|	DocumentTable.Amount,
	|	CAST(&TaxPay AS STRING(100))
	|FROM
	|	TemporaryTableHeader AS DocumentTable
	|WHERE
	|	DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.Taxes)
	|
	|UNION ALL
	|
	|SELECT
	|	4,
	|	DocumentTable.LineNumber,
	|	DocumentTable.Date,
	|	DocumentTable.Company,
	|	VALUE(Catalog.PlanningPeriods.Actual),
	|	DocumentTable.GLAccount,
	|	DocumentTable.PettyCash.GLAccount,
	|	CASE
	|		WHEN DocumentTable.GLAccount.Currency
	|			THEN DocumentTable.Currency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.PettyCash.GLAccount.Currency
	|			THEN DocumentTable.Currency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.GLAccount.Currency
	|			THEN DocumentTable.AmountCur
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DocumentTable.PettyCash.GLAccount.Currency
	|			THEN DocumentTable.AmountCur
	|		ELSE 0
	|	END,
	|	DocumentTable.Amount,
	|	DocumentTable.ContentOfAccountingRecord
	|FROM
	|	TemporaryTableAdvanceHolderPayments AS DocumentTable
	|
	|UNION ALL
	|
	|SELECT
	|	5,
	|	DocumentTable.LineNumber,
	|	DocumentTable.Date,
	|	DocumentTable.Company,
	|	VALUE(Catalog.PlanningPeriods.Actual),
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|			THEN DocumentTable.GLAccount
	|		ELSE VALUE(ChartOfAccounts.Managerial.OtherExpenses)
	|	END,
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|			THEN VALUE(ChartOfAccounts.Managerial.OtherIncome)
	|		ELSE DocumentTable.GLAccount
	|	END,
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|				AND DocumentTable.GLAccount.Currency
	|			THEN DocumentTable.Currency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences < 0
	|				AND DocumentTable.GLAccount.Currency
	|			THEN DocumentTable.Currency
	|		ELSE UNDEFINED
	|	END,
	|	0,
	|	0,
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|			THEN DocumentTable.AmountOfExchangeDifferences
	|		ELSE -DocumentTable.AmountOfExchangeDifferences
	|	END,
	|	&ExchangeDifference
	|FROM
	|	TemporaryTableExchangeDifferencesCalculationWithAdvanceHolder AS DocumentTable
	|
	|UNION ALL
	|
	|SELECT
	|	6,
	|	DocumentTable.LineNumber,
	|	DocumentTable.Date,
	|	DocumentTable.Company,
	|	VALUE(Catalog.PlanningPeriods.Actual),
	|	DocumentTable.GLAccount,
	|	DocumentTable.PettyCash.GLAccount,
	|	CASE
	|		WHEN DocumentTable.GLAccount.Currency
	|			THEN DocumentTable.Currency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.PettyCash.GLAccount.Currency
	|			THEN DocumentTable.CashCurrency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.GLAccount.Currency
	|			THEN DocumentTable.AmountCur
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DocumentTable.PettyCash.GLAccount.Currency
	|			THEN DocumentTable.PaymentAmount
	|		ELSE 0
	|	END,
	|	DocumentTable.Amount,
	|	DocumentTable.ContentOfAccountingRecord
	|FROM
	|	TemporaryTableAccountsReceivable AS DocumentTable
	|
	|UNION ALL
	|
	|SELECT
	|	7,
	|	DocumentTable.LineNumber,
	|	DocumentTable.Date,
	|	DocumentTable.Company,
	|	VALUE(Catalog.PlanningPeriods.Actual),
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|			THEN DocumentTable.GLAccount
	|		ELSE VALUE(ChartOfAccounts.Managerial.OtherExpenses)
	|	END,
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|			THEN VALUE(ChartOfAccounts.Managerial.OtherIncome)
	|		ELSE DocumentTable.GLAccount
	|	END,
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|				AND DocumentTable.GLAccount.Currency
	|			THEN DocumentTable.Currency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences < 0
	|				AND DocumentTable.GLAccount.Currency
	|			THEN DocumentTable.Currency
	|		ELSE UNDEFINED
	|	END,
	|	0,
	|	0,
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|			THEN DocumentTable.AmountOfExchangeDifferences
	|		ELSE -DocumentTable.AmountOfExchangeDifferences
	|	END,
	|	&ExchangeDifference
	|FROM
	|	TemporaryTableExchangeRateDifferencesAccountsReceivable AS DocumentTable
	|
	|UNION ALL
	|
	|SELECT
	|	8,
	|	DocumentTable.LineNumber,
	|	DocumentTable.Date,
	|	DocumentTable.Company,
	|	VALUE(Catalog.PlanningPeriods.Actual),
	|	DocumentTable.GLAccount,
	|	DocumentTable.PettyCash.GLAccount,
	|	CASE
	|		WHEN DocumentTable.GLAccount.Currency
	|			THEN DocumentTable.Currency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.PettyCash.GLAccount.Currency
	|			THEN DocumentTable.CashCurrency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.GLAccount.Currency
	|			THEN DocumentTable.AmountCur
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DocumentTable.PettyCash.GLAccount.Currency
	|			THEN DocumentTable.PaymentAmount
	|		ELSE 0
	|	END,
	|	DocumentTable.Amount,
	|	DocumentTable.ContentOfAccountingRecord
	|FROM
	|	TemporaryTableAccountsPayable AS DocumentTable
	|
	|UNION ALL
	|
	|SELECT
	|	9,
	|	DocumentTable.LineNumber,
	|	DocumentTable.Date,
	|	DocumentTable.Company,
	|	VALUE(Catalog.PlanningPeriods.Actual),
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|			THEN VALUE(ChartOfAccounts.Managerial.OtherExpenses)
	|		ELSE DocumentTable.GLAccount
	|	END,
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|			THEN DocumentTable.GLAccount
	|		ELSE VALUE(ChartOfAccounts.Managerial.OtherIncome)
	|	END,
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences < 0
	|				AND DocumentTable.GLAccount.Currency
	|			THEN DocumentTable.Currency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|				AND DocumentTable.GLAccount.Currency
	|			THEN DocumentTable.Currency
	|		ELSE UNDEFINED
	|	END,
	|	0,
	|	0,
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|			THEN DocumentTable.AmountOfExchangeDifferences
	|		ELSE -DocumentTable.AmountOfExchangeDifferences
	|	END,
	|	&ExchangeDifference
	|FROM
	|	TemporaryTableOfExchangeRateDifferencesAccountsPayable AS DocumentTable
	|
	|UNION ALL
	|
	|SELECT
	|	10,
	|	DocumentTable.LineNumber,
	|	DocumentTable.Date,
	|	DocumentTable.Company,
	|	VALUE(Catalog.PlanningPeriods.Actual),
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|			THEN DocumentTable.GLAccount
	|		ELSE VALUE(ChartOfAccounts.Managerial.OtherExpenses)
	|	END,
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|			THEN VALUE(ChartOfAccounts.Managerial.OtherIncome)
	|		ELSE DocumentTable.GLAccount
	|	END,
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|				AND DocumentTable.GLAccount.Currency
	|			THEN DocumentTable.Currency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences < 0
	|				AND DocumentTable.GLAccount.Currency
	|			THEN DocumentTable.Currency
	|		ELSE UNDEFINED
	|	END,
	|	0,
	|	0,
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|			THEN DocumentTable.AmountOfExchangeDifferences
	|		ELSE -DocumentTable.AmountOfExchangeDifferences
	|	END,
	|	&ExchangeDifference
	|FROM
	|	TemporaryTableExchangeRateLossesBanking AS DocumentTable
	|
	|UNION ALL
	|
	|SELECT
	|	11,
	|	DocumentTable.LineNumber,
	|	DocumentTable.Date,
	|	DocumentTable.Company,
	|	VALUE(Catalog.PlanningPeriods.Actual),
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|			THEN DocumentTable.GLAccount
	|		ELSE VALUE(ChartOfAccounts.Managerial.OtherExpenses)
	|	END,
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|			THEN VALUE(ChartOfAccounts.Managerial.OtherIncome)
	|		ELSE DocumentTable.GLAccount
	|	END,
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|				AND DocumentTable.GLAccount.Currency
	|			THEN DocumentTable.Currency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences < 0
	|				AND DocumentTable.GLAccount.Currency
	|			THEN DocumentTable.Currency
	|		ELSE UNDEFINED
	|	END,
	|	0,
	|	0,
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|			THEN DocumentTable.AmountOfExchangeDifferences
	|		ELSE -DocumentTable.AmountOfExchangeDifferences
	|	END,
	|	&ExchangeDifference
	|FROM
	|	TemporaryTableExchangeRateLossesCashAssetsInRetailCashes AS DocumentTable
	|
	|UNION ALL
	|
	|SELECT
	|	12,
	|	DocumentTable.LineNumber,
	|	DocumentTable.Date,
	|	DocumentTable.Company,
	|	VALUE(Catalog.PlanningPeriods.Actual),
	|	DocumentTable.GLAccount,
	|	DocumentTable.PettyCashGLAccount,
	|	CASE
	|		WHEN DocumentTable.GLAccount.Currency
	|			THEN DocumentTable.Currency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.PettyCashGLAccount.Currency
	|			THEN DocumentTable.Currency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.GLAccount.Currency
	|			THEN DocumentTable.AmountCur
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DocumentTable.PettyCashGLAccount.Currency
	|			THEN DocumentTable.AmountCur
	|		ELSE 0
	|	END,
	|	DocumentTable.Amount,
	|	DocumentTable.ContentOfAccountingRecord
	|FROM
	|	TemporaryTablePayrollPayments AS DocumentTable
	|
	|UNION ALL
	|
	|SELECT
	|	13,
	|	DocumentTable.LineNumber,
	|	DocumentTable.Date,
	|	DocumentTable.Company,
	|	VALUE(Catalog.PlanningPeriods.Actual),
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|			THEN VALUE(ChartOfAccounts.Managerial.OtherExpenses)
	|		ELSE DocumentTable.GLAccount
	|	END,
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|			THEN DocumentTable.GLAccount
	|		ELSE VALUE(ChartOfAccounts.Managerial.OtherIncome)
	|	END,
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences < 0
	|				AND DocumentTable.GLAccount.Currency
	|			THEN DocumentTable.Currency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|				AND DocumentTable.GLAccount.Currency
	|			THEN DocumentTable.Currency
	|		ELSE UNDEFINED
	|	END,
	|	0,
	|	0,
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|			THEN DocumentTable.AmountOfExchangeDifferences
	|		ELSE -DocumentTable.AmountOfExchangeDifferences
	|	END,
	|	&ExchangeDifference
	|FROM
	|	TemporaryTableExchangeDifferencesPayrollPayments AS DocumentTable
	|
	|UNION ALL
	|
	|SELECT
	|	14,
	|	1,
	|	DocumentTable.Date,
	|	DocumentTable.Company,
	|	VALUE(Catalog.PlanningPeriods.Actual),
	|	CASE
	|		WHEN DocumentTable.ExchangeRateDifferenceAmount > 0
	|			THEN DocumentTable.GLAccount
	|		ELSE VALUE(ChartOfAccounts.Managerial.OtherExpenses)
	|	END,
	|	CASE
	|		WHEN DocumentTable.ExchangeRateDifferenceAmount > 0
	|			THEN VALUE(ChartOfAccounts.Managerial.OtherIncome)
	|		ELSE DocumentTable.GLAccount
	|	END,
	|	CASE
	|		WHEN DocumentTable.ExchangeRateDifferenceAmount > 0
	|				AND DocumentTable.GLAccount.Currency
	|			THEN DocumentTable.Currency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.ExchangeRateDifferenceAmount < 0
	|				AND DocumentTable.GLAccount.Currency
	|			THEN DocumentTable.Currency
	|		ELSE UNDEFINED
	|	END,
	|	0,
	|	0,
	|	CASE
	|		WHEN DocumentTable.ExchangeRateDifferenceAmount > 0
	|			THEN DocumentTable.ExchangeRateDifferenceAmount
	|		ELSE -DocumentTable.ExchangeRateDifferenceAmount
	|	END,
	|	&ExchangeDifference
	|FROM
	|	ExchangeDifferencesTemporaryTableOtherSettlements AS DocumentTable
	|
	|UNION ALL
	|
	|SELECT
	|	15,
	|	DocumentTable.LineNumber,
	|	DocumentTable.Date,
	|	DocumentTable.Company,
	|	VALUE(Catalog.PlanningPeriods.Actual),
	|	DocumentTable.GLAccount,
	|	DocumentTable.PettyCash.GLAccount,
	|	CASE
	|		WHEN DocumentTable.GLAccount.Currency
	|			THEN DocumentTable.Currency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.PettyCash.GLAccount.Currency
	|			THEN DocumentTable.CashCurrency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.GLAccount.Currency
	|			THEN DocumentTable.AmountCur
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DocumentTable.PettyCash.GLAccount.Currency
	|			THEN DocumentTable.PaymentAmount
	|		ELSE 0
	|	END,
	|	DocumentTable.Amount,
	|	DocumentTable.ContentOfAccountingRecord
	|FROM
	|	TemporaryTableOtherSettlements AS DocumentTable
	|
	|UNION ALL
	|
	|SELECT
	|	16,
	|	1,
	|	DocumentTable.Date,
	|	DocumentTable.Company,
	|	VALUE(Catalog.PlanningPeriods.Actual),
	|	DocumentTable.GLAccount,
	|	DocumentTable.PettyCash.GLAccount,
	|	CASE
	|		WHEN DocumentTable.GLAccount.Currency
	|			THEN DocumentTable.Currency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.PettyCash.GLAccount.Currency
	|			THEN DocumentTable.CashCurrency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.GLAccount.Currency
	|			THEN DocumentTable.AmountCur
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DocumentTable.PettyCash.GLAccount.Currency
	|			THEN DocumentTable.PaymentAmount
	|		ELSE 0
	|	END,
	|	DocumentTable.Amount,
	|	DocumentTable.ContentOfAccountingRecord
	|FROM
	|	TemporaryTableLoanSettlements AS DocumentTable
	|
	|UNION ALL
	|
	|SELECT
	|	17,
	|	1,
	|	DocumentTable.Date,
	|	DocumentTable.Company,
	|	VALUE(Catalog.PlanningPeriods.Actual),
	|	CASE
	|		WHEN DocumentTable.ExchangeRateDifferenceAmount > 0
	|			THEN DocumentTable.GLAccount
	|		ELSE VALUE(ChartOfAccounts.Managerial.OtherExpenses)
	|	END,
	|	CASE
	|		WHEN DocumentTable.ExchangeRateDifferenceAmount > 0
	|			THEN VALUE(ChartOfAccounts.Managerial.OtherIncome)
	|		ELSE DocumentTable.GLAccount
	|	END,
	|	CASE
	|		WHEN DocumentTable.ExchangeRateDifferenceAmount > 0
	|				AND DocumentTable.GLAccount.Currency
	|			THEN DocumentTable.Currency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.ExchangeRateDifferenceAmount < 0
	|				AND DocumentTable.GLAccount.Currency
	|			THEN DocumentTable.Currency
	|		ELSE UNDEFINED
	|	END,
	|	0,
	|	0,
	|	CASE
	|		WHEN DocumentTable.ExchangeRateDifferenceAmount > 0
	|			THEN DocumentTable.ExchangeRateDifferenceAmount
	|		ELSE -DocumentTable.ExchangeRateDifferenceAmount
	|	END,
	|	&ExchangeDifference
	|FROM
	|	TemporaryTableExchangeRateDifferencesLoanSettlements AS DocumentTable
	|
	|ORDER BY
	|	Order,
	|	LineNumber";
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableManagerial", QueryResult.Unload());
	
EndProcedure // GenerateTableManagerial()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableIncomeAndExpensesCashMethod(DocumentRefCashPayment, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	
	Query.SetParameter("Ref", DocumentRefCashPayment);
	Query.SetParameter("Company", StructureAdditionalProperties.ForPosting.Company);
	Query.SetParameter("PointInTime", New Boundary(StructureAdditionalProperties.ForPosting.PointInTime, BoundaryType.Including));
	Query.SetParameter("IncomeAndExpensesAccountingCashMethod", StructureAdditionalProperties.AccountingPolicy.IncomeAndExpensesAccountingCashMethod);
	
	Query.Text =
	"SELECT
	|	DocumentTable.Date AS Period,
	|	&Company AS Company,
	|	CASE
	|		WHEN DocumentTable.KeepAccountingExpensesByServiceContracts
	|			THEN DocumentTable.ServiceContractBusinessActivity
	|		ELSE UNDEFINED
	|	END AS BusinessActivity,
	|	DocumentTable.Item AS Item,
	|	0 AS AmountIncome,
	|	DocumentTable.AccountingAmount AS AmountExpense
	|FROM
	|	TemporaryTablePaymentDetails AS DocumentTable
	|WHERE
	|	&IncomeAndExpensesAccountingCashMethod
	|	AND DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.Vendor)
	|	AND (DocumentTable.AdvanceFlag
	|			OR DocumentTable.KeepAccountingExpensesByServiceContracts)
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Period,
	|	Table.Company,
	|	Table.BusinessActivity,
	|	Table.Item,
	|	0,
	|	Table.AmountExpense
	|FROM
	|	TemporaryTableTableDeferredIncomeAndExpenditure AS Table
	|WHERE
	|	Table.AmountExpense > 0
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentTable.Date,
	|	&Company,
	|	CASE
	|		WHEN DocumentTable.BusinessActivity <> VALUE(Catalog.BusinessActivities.EmptyRef)
	|			THEN DocumentTable.BusinessActivity
	|		ELSE VALUE(Catalog.BusinessActivities.Other)
	|	END,
	|	DocumentTable.Item,
	|	0,
	|	DocumentTable.Amount
	|FROM
	|	TemporaryTableHeader AS DocumentTable
	|WHERE
	|	&IncomeAndExpensesAccountingCashMethod
	|	AND (DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.Other)
	|			OR DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.OtherSettlements)
	|			OR DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.LoanSettlements)
	|			OR DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.IssueLoanToEmployee)
	|			OR DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.Salary)
	|			OR DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.SalaryForEmployee)
	|			OR DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.Taxes))
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentTable.Date,
	|	&Company,
	|	CASE
	|		WHEN DocumentTable.KeepAccountingExpensesByServiceContracts
	|			THEN DocumentTable.ServiceContractBusinessActivity
	|		ELSE UNDEFINED
	|	END,
	|	DocumentTable.Item,
	|	-DocumentTable.AccountingAmount,
	|	0
	|FROM
	|	TemporaryTablePaymentDetails AS DocumentTable
	|WHERE
	|	&IncomeAndExpensesAccountingCashMethod
	|	AND DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.ToCustomer)
	|	AND (DocumentTable.AdvanceFlag
	|			OR DocumentTable.KeepAccountingExpensesByServiceContracts)
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Period,
	|	Table.Company,
	|	Table.BusinessActivity,
	|	Table.Item,
	|	-Table.AmountIncome,
	|	0
	|FROM
	|	TemporaryTableTableDeferredIncomeAndExpenditure AS Table
	|WHERE
	|	Table.AmountIncome > 0";
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableIncomeAndExpensesCashMethod", QueryResult.Unload());
	
EndProcedure // GenerateTableIncomeAndExpensesCashMethod()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableIncomeAndExpensesUndistributed(DocumentRefCashPayment, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	
	Query.SetParameter("Ref", DocumentRefCashPayment);
	Query.SetParameter("Company", StructureAdditionalProperties.ForPosting.Company);
	Query.SetParameter("IncomeAndExpensesAccountingCashMethod", StructureAdditionalProperties.AccountingPolicy.IncomeAndExpensesAccountingCashMethod);
	
	Query.Text =
	"SELECT
	|	1 AS Order,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.Date AS Period,
	|	&Company AS Company,
	|	CASE
	|		WHEN DocumentTable.DoOperationsByDocuments
	|			THEN &Ref
	|		ELSE UNDEFINED
	|	END AS Document,
	|	DocumentTable.Item AS Item,
	|	0 AS AmountIncome,
	|	DocumentTable.AccountingAmount AS AmountExpense
	|FROM
	|	TemporaryTablePaymentDetails AS DocumentTable
	|WHERE
	|	&IncomeAndExpensesAccountingCashMethod
	|	AND DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.Vendor)
	|	AND NOT DocumentTable.KeepAccountingExpensesByServiceContracts
	|	AND DocumentTable.AdvanceFlag
	|
	|UNION ALL
	|
	|SELECT
	|	2,
	|	VALUE(AccumulationRecordType.Receipt),
	|	DocumentTable.LineNumber,
	|	DocumentTable.Date,
	|	&Company,
	|	CASE
	|		WHEN DocumentTable.DoOperationsByDocuments
	|			THEN &Ref
	|		ELSE UNDEFINED
	|	END,
	|	DocumentTable.Item,
	|	-DocumentTable.AccountingAmount,
	|	0
	|FROM
	|	TemporaryTablePaymentDetails AS DocumentTable
	|WHERE
	|	&IncomeAndExpensesAccountingCashMethod
	|	AND DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.ToCustomer)
	|	AND NOT DocumentTable.KeepAccountingExpensesByServiceContracts
	|	AND DocumentTable.AdvanceFlag
	|
	|ORDER BY
	|	Order,
	|	LineNumber";
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableIncomeAndExpensesUndistributed", QueryResult.Unload());
	
EndProcedure // GenerateTableIncomeAndExpensesUndistributed()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableIncomeAndExpensesRetained(DocumentRefCashPayment, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	
	Query.SetParameter("Ref", DocumentRefCashPayment);
	Query.SetParameter("Company", StructureAdditionalProperties.ForPosting.Company);
	Query.SetParameter("IncomeAndExpensesAccountingCashMethod", StructureAdditionalProperties.AccountingPolicy.IncomeAndExpensesAccountingCashMethod);
	Query.SetParameter("Period", StructureAdditionalProperties.ForPosting.PointInTime.Date);
	
	// Generating the table with charge amounts.
	Query.Text =
	"SELECT
	|	&Company AS Company,
	|	CASE
	|		WHEN DocumentTable.DoOperationsByDocuments
	|			THEN DocumentTable.Document
	|		ELSE UNDEFINED
	|	END AS Document,
	|	DocumentTable.Item AS Item,
	|	SUM(DocumentTable.AccountingAmount) AS AmountToBeWrittenOff
	|FROM
	|	TemporaryTablePaymentDetails AS DocumentTable
	|WHERE
	|	&IncomeAndExpensesAccountingCashMethod
	|	AND DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.Vendor)
	|	AND NOT DocumentTable.KeepAccountingExpensesByServiceContracts
	|	AND Not DocumentTable.AdvanceFlag
	|
	|GROUP BY
	|	CASE
	|		WHEN DocumentTable.DoOperationsByDocuments
	|			THEN DocumentTable.Document
	|		ELSE UNDEFINED
	|	END,
	|	DocumentTable.Item";
	
	QueryResult = Query.Execute();
	
	// Setting of the exclusive lock of the cash funds controlled balances.
	Block = New DataLock;
	LockItem = Block.Add("AccumulationRegister.IncomeAndExpensesRetained");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = QueryResult;
	LockItem.UseFromDataSource("Company", "Company");
	LockItem.UseFromDataSource("Document", "Document");
	Block.Lock();
	
	TableAmountForWriteOff = QueryResult.Unload();
	
	// Generating the table with remaining balance.
	Query.Text =
	"SELECT
	|	&Period AS Period,
	|	IncomeAndExpensesRetainedBalances.Company AS Company,
	|	IncomeAndExpensesRetainedBalances.Document AS Document,
	|	IncomeAndExpensesRetainedBalances.BusinessActivity AS BusinessActivity,
	|	VALUE(Catalog.CashFlowItems.EmptyRef) AS Item,
	|	0 AS AmountIncome,
	|	0 AS AmountExpense,
	|	-SUM(IncomeAndExpensesRetainedBalances.AmountIncomeBalance) AS AmountIncomeBalance,
	|	SUM(IncomeAndExpensesRetainedBalances.AmountExpensesBalance) AS AmountExpensesBalance
	|FROM
	|	(SELECT
	|		IncomeAndExpensesRetainedBalances.Company AS Company,
	|		IncomeAndExpensesRetainedBalances.Document AS Document,
	|		IncomeAndExpensesRetainedBalances.BusinessActivity AS BusinessActivity,
	|		IncomeAndExpensesRetainedBalances.AmountIncomeBalance AS AmountIncomeBalance,
	|		IncomeAndExpensesRetainedBalances.AmountExpenseBalance AS AmountExpensesBalance
	|	FROM
	|		AccumulationRegister.IncomeAndExpensesRetained.Balance(
	|				,
	|				Company = &Company
	|					AND Document In
	|						(SELECT
	|							DocumentTable.Document
	|						FROM
	|							TemporaryTablePaymentDetails AS DocumentTable
	|						WHERE
	|							(DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.Vendor)
	|								OR DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.ToCustomer)))) AS IncomeAndExpensesRetainedBalances
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentRegisterRecordsOfIncomeAndExpensesPending.Company,
	|		DocumentRegisterRecordsOfIncomeAndExpensesPending.Document,
	|		DocumentRegisterRecordsOfIncomeAndExpensesPending.BusinessActivity,
	|		CASE
	|			WHEN DocumentRegisterRecordsOfIncomeAndExpensesPending.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -ISNULL(DocumentRegisterRecordsOfIncomeAndExpensesPending.AmountIncome, 0)
	|			ELSE ISNULL(DocumentRegisterRecordsOfIncomeAndExpensesPending.AmountIncome, 0)
	|		END,
	|		CASE
	|			WHEN DocumentRegisterRecordsOfIncomeAndExpensesPending.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -ISNULL(DocumentRegisterRecordsOfIncomeAndExpensesPending.AmountExpense, 0)
	|			ELSE ISNULL(DocumentRegisterRecordsOfIncomeAndExpensesPending.AmountExpense, 0)
	|		END
	|	FROM
	|		AccumulationRegister.IncomeAndExpensesRetained AS DocumentRegisterRecordsOfIncomeAndExpensesPending
	|	WHERE
	|		DocumentRegisterRecordsOfIncomeAndExpensesPending.Recorder = &Ref) AS IncomeAndExpensesRetainedBalances
	|
	|GROUP BY
	|	IncomeAndExpensesRetainedBalances.Company,
	|	IncomeAndExpensesRetainedBalances.Document,
	|	IncomeAndExpensesRetainedBalances.BusinessActivity
	|
	|ORDER BY
	|	Document";
	
	TableSumBalance = Query.Execute().Unload();

	TableSumBalance.Indexes.Add("Document");
	
	// Calculation of the write-off amounts.
	For Each StringSumToBeWrittenOff IN TableAmountForWriteOff Do
		AmountToBeWrittenOff = StringSumToBeWrittenOff.AmountToBeWrittenOff;
		Filter = New Structure("Document", StringSumToBeWrittenOff.Document);
		RowsArrayAmountsBalances = TableSumBalance.FindRows(Filter);
		For Each AmountRowBalances IN RowsArrayAmountsBalances Do
			If AmountToBeWrittenOff = 0 Then
				Continue
			ElsIf AmountRowBalances.AmountExpensesBalance < AmountToBeWrittenOff Then
				AmountRowBalances.AmountExpense = AmountRowBalances.AmountExpensesBalance;
				AmountRowBalances.Item = StringSumToBeWrittenOff.Item;
				AmountToBeWrittenOff = AmountToBeWrittenOff - AmountRowBalances.AmountExpensesBalance;
			ElsIf AmountRowBalances.AmountExpensesBalance >= AmountToBeWrittenOff Then
				AmountRowBalances.AmountExpense = AmountToBeWrittenOff;
				AmountRowBalances.Item = StringSumToBeWrittenOff.Item;
				AmountToBeWrittenOff = 0;
			EndIf;
		EndDo;
	EndDo;
	
	// Generating the table with charge amounts.
	Query.Text =
	"SELECT
	|	&Company AS Company,
	|	CASE
	|		WHEN DocumentTable.DoOperationsByDocuments
	|			THEN DocumentTable.Document
	|		ELSE UNDEFINED
	|	END AS Document,
	|	DocumentTable.Item AS Item,
	|	SUM(DocumentTable.AccountingAmount) AS AmountToBeWrittenOff
	|FROM
	|	TemporaryTablePaymentDetails AS DocumentTable
	|WHERE
	|	&IncomeAndExpensesAccountingCashMethod
	|	AND DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.ToCustomer)
	|	AND Not DocumentTable.AdvanceFlag
	|
	|GROUP BY
	|	CASE
	|		WHEN DocumentTable.DoOperationsByDocuments
	|			THEN DocumentTable.Document
	|		ELSE UNDEFINED
	|	END,
	|	DocumentTable.Item"; 
	
	TableAmountForWriteOff = Query.Execute().Unload();
	
	For Each StringSumToBeWrittenOff IN TableAmountForWriteOff Do
		AmountToBeWrittenOff = StringSumToBeWrittenOff.AmountToBeWrittenOff;
		Filter = New Structure("Document", StringSumToBeWrittenOff.Document);
		RowsArrayAmountsBalances = TableSumBalance.FindRows(Filter);
		For Each AmountRowBalances IN RowsArrayAmountsBalances Do
			If AmountToBeWrittenOff = 0 Then
				Continue
			ElsIf AmountRowBalances.AmountIncomeBalance < AmountToBeWrittenOff Then
				AmountRowBalances.AmountIncome = AmountRowBalances.AmountIncomeBalance;
				AmountRowBalances.Item = StringSumToBeWrittenOff.Item;
				AmountToBeWrittenOff = AmountToBeWrittenOff - AmountRowBalances.AmountIncomeBalance;
			ElsIf AmountRowBalances.AmountIncomeBalance >= AmountToBeWrittenOff Then
				AmountRowBalances.AmountIncome = AmountToBeWrittenOff;
				AmountRowBalances.Item = StringSumToBeWrittenOff.Item;
				AmountToBeWrittenOff = 0;
			EndIf;
		EndDo;
	EndDo;
	
	// Generating a temporary table with amounts,
	// items and directions of activities. Required to generate movements of income
	// and expenses by cash method.
	Query.Text =
	"SELECT
	|	Table.Period AS Period,
	|	Table.Company AS Company,
	|	Table.Document AS Document,
	|	Table.Item AS Item,
	|	Table.AmountIncome AS AmountIncome,
	|	Table.AmountExpense AS AmountExpense,
	|	Table.BusinessActivity AS BusinessActivity
	|INTO TemporaryTableTableDeferredIncomeAndExpenditure
	|FROM
	|	&Table AS Table
	|WHERE
	|	(Table.AmountIncome > 0
	|			OR Table.AmountExpense > 0)";
	
	Query.SetParameter("Table", TableSumBalance);
	
	Query.Execute();
	
	// Generating the table for recording in the register.
	Query.Text =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	Table.Period AS Period,
	|	Table.Company AS Company,
	|	Table.Document AS Document,
	|	Table.Item AS Item,
	|	-Table.AmountIncome AS AmountIncome,
	|	Table.AmountExpense AS AmountExpense,
	|	Table.BusinessActivity AS BusinessActivity
	|FROM
	|	TemporaryTableTableDeferredIncomeAndExpenditure AS Table";
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableIncomeAndExpensesRetained", QueryResult.Unload());
	
EndProcedure // GenerateTableIncomeAndExpensesUndistributed()  

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableTaxesSettlements(DocumentRefCashPayment, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	
	Query.SetParameter("Ref", DocumentRefCashPayment);
	Query.SetParameter("Company", StructureAdditionalProperties.ForPosting.Company);
	Query.SetParameter("PointInTime", New Boundary(StructureAdditionalProperties.ForPosting.PointInTime, BoundaryType.Including));
	Query.SetParameter("TaxPay", NStr("en='Tax payment';ru='Оплата налога';vi='Trả tiền thuế'"));
	
	Query.Text =
	"SELECT
	|	DocumentTable.Date AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Company AS Company,
	|	DocumentTable.TaxKind AS TaxKind,
	|	DocumentTable.Amount AS Amount,
	|	DocumentTable.TaxKindGLAccount AS GLAccount,
	|	&TaxPay AS ContentOfAccountingRecord
	|FROM
	|	TemporaryTableHeader AS DocumentTable
	|WHERE
	|	DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.Taxes)";
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableTaxAccounting", QueryResult.Unload());
	
EndProcedure // GenerateTableTaxesSettlements()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTablePaymentCalendar(DocumentRefCashPayment, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	
	Query.SetParameter("Ref", DocumentRefCashPayment);
	Query.SetParameter("Company", StructureAdditionalProperties.ForPosting.Company);
	Query.SetParameter("UsePaymentCalendar", Constants.FunctionalOptionPaymentCalendar.Get());
	
	Query.Text =
	"SELECT
	|	1 AS Order,
	|	MAX(DocumentTable.LineNumber) AS LineNumber,
	|	DocumentTable.Date AS Period,
	|	&Company AS Company,
	|	DocumentTable.Item AS Item,
	|	VALUE(Enum.CashAssetTypes.Cash) AS CashAssetTypes,
	|	VALUE(Enum.PaymentApprovalStatuses.Approved) AS PaymentConfirmationStatus,
	|	DocumentTable.PettyCash AS BankAccountPettyCash,
	|	CASE
	|		WHEN DocumentTable.Contract.SettlementsInStandardUnits
	|			THEN DocumentTable.SettlementsCurrency
	|		ELSE DocumentTable.CashCurrency
	|	END AS Currency,
	|	DocumentTable.InvoiceForPaymentToPaymentCalendar AS InvoiceForPayment,
	|	SUM(CASE
	|			WHEN DocumentTable.Contract.SettlementsInStandardUnits
	|				THEN -DocumentTable.SettlementsAmount
	|			ELSE -DocumentTable.PaymentAmount
	|		END) AS PaymentAmount
	|FROM
	|	TemporaryTablePaymentDetails AS DocumentTable
	|WHERE
	|	&UsePaymentCalendar
	|	AND DocumentTable.OperationKind <> VALUE(Enum.OperationKindsCashPayment.Salary)
	|
	|GROUP BY
	|	DocumentTable.Item,
	|	DocumentTable.Date,
	|	DocumentTable.PettyCash,
	|	CASE
	|		WHEN DocumentTable.Contract.SettlementsInStandardUnits
	|			THEN DocumentTable.SettlementsCurrency
	|		ELSE DocumentTable.CashCurrency
	|	END,
	|	DocumentTable.InvoiceForPaymentToPaymentCalendar
	|
	|UNION ALL
	|
	|SELECT
	|	2,
	|	MAX(DocumentTable.LineNumber),
	|	DocumentTable.Ref.Date,
	|	&Company,
	|	DocumentTable.Ref.Item,
	|	VALUE(Enum.CashAssetTypes.Cash),
	|	VALUE(Enum.PaymentApprovalStatuses.Approved),
	|	DocumentTable.Ref.PettyCash,
	|	DocumentTable.Ref.CashCurrency,
	|	DocumentTable.PlanningDocument,
	|	SUM(-DocumentTable.PaymentAmount)
	|FROM
	|	Document.CashPayment.PayrollPayment AS DocumentTable
	|WHERE
	|	&UsePaymentCalendar
	|	AND DocumentTable.Ref = &Ref
	|	AND DocumentTable.Ref.OperationKind = VALUE(Enum.OperationKindsCashPayment.Salary)
	|
	|GROUP BY
	|	DocumentTable.Ref,
	|	DocumentTable.PlanningDocument,
	|	DocumentTable.Ref.Date,
	|	DocumentTable.Ref.Item,
	|	DocumentTable.Ref.PettyCash,
	|	DocumentTable.Ref.CashCurrency
	|
	|UNION ALL
	|
	|SELECT
	|	3,
	|	1,
	|	DocumentTable.Date,
	|	&Company,
	|	DocumentTable.Item,
	|	VALUE(Enum.CashAssetTypes.Cash),
	|	VALUE(Enum.PaymentApprovalStatuses.Approved),
	|	DocumentTable.PettyCash,
	|	DocumentTable.CashCurrency,
	|	UNDEFINED,
	|	-DocumentTable.DocumentAmount
	|FROM
	|	Document.CashPayment AS DocumentTable
	|		LEFT JOIN (SELECT
	|			COUNT(ISNULL(TemporaryTablePaymentDetails.LineNumber, 0)) AS Quantity
	|		FROM
	|			TemporaryTablePaymentDetails AS TemporaryTablePaymentDetails) AS NestedSelect
	|		ON (TRUE)
	|WHERE
	|	&UsePaymentCalendar
	|	AND DocumentTable.Ref = &Ref
	|	AND NestedSelect.Quantity = 0
	|
	|ORDER BY
	|	Order,
	|	LineNumber";
	
	Query.SetParameter("Ref", DocumentRefCashPayment);
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TablePaymentCalendar", QueryResult.Unload());
	
EndProcedure // GenerateTablePaymentCalendar()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableInvoicesAndOrdersPayment(DocumentRefCashPayment, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	
	Query.SetParameter("Company", StructureAdditionalProperties.ForPosting.Company);
	Query.SetParameter("PointInTime", New Boundary(StructureAdditionalProperties.ForPosting.PointInTime, BoundaryType.Including));
	
	Query.Text =
	"SELECT
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.Date AS Period,
	|	&Company AS Company,
	|	DocumentTable.InvoiceForPayment AS InvoiceForPayment,
	|	SUM(CASE
	|			WHEN Not DocumentTable.AdvanceFlag
	|				THEN 0
	|			WHEN DocumentTable.CashCurrency = DocumentTable.InvoiceForPayment.DocumentCurrency
	|				THEN DocumentTable.PaymentAmount
	|			WHEN DocumentTable.SettlementsCurrency = DocumentTable.InvoiceForPayment.DocumentCurrency
	|				THEN DocumentTable.SettlementsAmount
	|			ELSE CAST(DocumentTable.PaymentAmount * CurrencyRatesOfPettyCashe.ExchangeRate * CurrencyRatesOfAccount.Multiplicity / (CurrencyRatesOfAccount.ExchangeRate * CurrencyRatesOfPettyCashe.Multiplicity) AS NUMBER(15, 2))
	|		END) * CASE
	|		WHEN DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.ToCustomer)
	|			THEN -1
	|		ELSE 1
	|	END AS AdvanceAmount,
	|	SUM(CASE
	|			WHEN DocumentTable.AdvanceFlag
	|				THEN 0
	|			WHEN DocumentTable.CashCurrency = DocumentTable.InvoiceForPayment.DocumentCurrency
	|				THEN DocumentTable.PaymentAmount
	|			WHEN DocumentTable.SettlementsCurrency = DocumentTable.InvoiceForPayment.DocumentCurrency
	|				THEN DocumentTable.SettlementsAmount
	|			ELSE CAST(DocumentTable.PaymentAmount * CurrencyRatesOfPettyCashe.ExchangeRate * CurrencyRatesOfAccount.Multiplicity / (CurrencyRatesOfAccount.ExchangeRate * CurrencyRatesOfPettyCashe.Multiplicity) AS NUMBER(15, 2))
	|		END) * CASE
	|		WHEN DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.ToCustomer)
	|			THEN -1
	|		ELSE 1
	|	END AS PaymentAmount
	|FROM
	|	TemporaryTablePaymentDetails AS DocumentTable
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(&PointInTime, ) AS CurrencyRatesOfAccount
	|		ON DocumentTable.InvoiceForPayment.DocumentCurrency = CurrencyRatesOfAccount.Currency
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(&PointInTime, ) AS CurrencyRatesOfPettyCashe
	|		ON DocumentTable.CashCurrency = CurrencyRatesOfPettyCashe.Currency
	|WHERE
	|	DocumentTable.TrackPaymentsByBills
	|	AND DocumentTable.InvoiceForPayment <> VALUE(Document.InvoiceForPayment.EmptyRef)
	|	AND DocumentTable.InvoiceForPayment <> VALUE(Document.SupplierInvoiceForPayment.EmptyRef)
	|	AND DocumentTable.InvoiceForPayment <> UNDEFINED
	|	AND (DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.Vendor)
	|			OR DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.ToCustomer))
	|
	|GROUP BY
	|	DocumentTable.LineNumber,
	|	DocumentTable.Date,
	|	DocumentTable.InvoiceForPayment,
	|	DocumentTable.OperationKind
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentTable.LineNumber,
	|	DocumentTable.Date,
	|	&Company,
	|	DocumentTable.Order,
	|	SUM(CASE
	|			WHEN Not DocumentTable.AdvanceFlag
	|				THEN 0
	|			WHEN DocumentTable.CashCurrency = DocumentTable.Order.DocumentCurrency
	|				THEN DocumentTable.PaymentAmount
	|			WHEN DocumentTable.SettlementsCurrency = DocumentTable.Order.DocumentCurrency
	|				THEN DocumentTable.SettlementsAmount
	|			ELSE CAST(DocumentTable.PaymentAmount * CurrencyRatesOfPettyCashe.ExchangeRate * CurrencyRatesOfAccount.Multiplicity / (CurrencyRatesOfAccount.ExchangeRate * CurrencyRatesOfPettyCashe.Multiplicity) AS NUMBER(15, 2))
	|		END) * CASE
	|		WHEN DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.ToCustomer)
	|			THEN -1
	|		ELSE 1
	|	END,
	|	SUM(CASE
	|			WHEN DocumentTable.AdvanceFlag
	|				THEN 0
	|			WHEN DocumentTable.CashCurrency = DocumentTable.Order.DocumentCurrency
	|				THEN DocumentTable.PaymentAmount
	|			WHEN DocumentTable.SettlementsCurrency = DocumentTable.Order.DocumentCurrency
	|				THEN DocumentTable.SettlementsAmount
	|			ELSE CAST(DocumentTable.PaymentAmount * CurrencyRatesOfPettyCashe.ExchangeRate * CurrencyRatesOfAccount.Multiplicity / (CurrencyRatesOfAccount.ExchangeRate * CurrencyRatesOfPettyCashe.Multiplicity) AS NUMBER(15, 2))
	|		END) * CASE
	|		WHEN DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.ToCustomer)
	|			THEN -1
	|		ELSE 1
	|	END
	|FROM
	|	TemporaryTablePaymentDetails AS DocumentTable
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(&PointInTime, ) AS CurrencyRatesOfAccount
	|		ON DocumentTable.Order.DocumentCurrency = CurrencyRatesOfAccount.Currency
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(&PointInTime, ) AS CurrencyRatesOfPettyCashe
	|		ON DocumentTable.CashCurrency = CurrencyRatesOfPettyCashe.Currency
	|WHERE
	|	DocumentTable.TrackPaymentsByBills
	|	AND (VALUETYPE(DocumentTable.Order) = Type(Document.CustomerOrder)
	|				AND DocumentTable.Order <> VALUE(Document.CustomerOrder.EmptyRef)
	|			OR VALUETYPE(DocumentTable.Order) = Type(Document.PurchaseOrder)
	|				AND DocumentTable.Order <> VALUE(Document.PurchaseOrder.EmptyRef))
	|	AND (DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.Vendor)
	|			OR DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.ToCustomer))
	|
	|GROUP BY
	|	DocumentTable.LineNumber,
	|	DocumentTable.Date,
	|	DocumentTable.Order,
	|	DocumentTable.OperationKind
	|
	|ORDER BY
	|	LineNumber";
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableInvoicesAndOrdersPayment", QueryResult.Unload());
	
EndProcedure // GenerateTableInvoicesAndOrdersPayment()

Procedure GenerateTableLoanSettlements(DocumentRefCashPayment, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	
	Query.SetParameter("Company", 					StructureAdditionalProperties.ForPosting.Company);
	Query.SetParameter("AccountingForWorkersLoans",	NStr("en='Issue loan to employee';ru='Выдача займа сотруднику';vi='Cấp khoản vay cho nhân viên'"));
	Query.SetParameter("Ref",						DocumentRefCashPayment);
	Query.SetParameter("PointInTime",				New Boundary(StructureAdditionalProperties.ForPosting.PointInTime, BoundaryType.Including));
	Query.SetParameter("ControlPeriod",				StructureAdditionalProperties.ForPosting.PointInTime.Date);
	Query.SetParameter("ExchangeRateDifference",	NStr("en='Exchange rate difference';ru='Курсовая разница';vi='Chênh lệch tỷ giá'"));	
	Query.SetParameter("AccountingCurrency",		Constants.AccountingCurrency.Get());
	Query.SetParameter("CashCurrency",				DocumentRefCashPayment.CashCurrency);
	
	Query.Text =
	"SELECT
	|	&Company AS Company,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	CASE
	|		WHEN CashPayment.OperationKind = VALUE(Enum.OperationKindsCashPayment.LoanSettlements)
	|			THEN VALUE(Enum.LoanContractTypes.Borrowed)
	|		ELSE VALUE(Enum.LoanContractTypes.EmployeeLoanAgreement)
	|	END AS LoanKind,
	|	CashPayment.Date AS Date,
	|	CashPayment.Date AS Period,
	|	&AccountingForWorkersLoans AS ContentOfAccountingRecord,
	|	CashPayment.AdvanceHolder AS Counterparty,
	|	CashPayment.DocumentAmount AS PaymentAmount,
	|	CAST(CashPayment.DocumentAmount * CurrencyRatesOfPettyCashe.ExchangeRate * CurrencyRatesOfContract.Multiplicity / (CurrencyRatesOfContract.ExchangeRate * CurrencyRatesOfPettyCashe.Multiplicity) AS NUMBER(15, 2)) AS PrincipalDebtCur,
	|	CAST(CashPayment.DocumentAmount * CurrencyRatesOfPettyCashe.ExchangeRate * CurrencyRatesOfAccount.Multiplicity / (CurrencyRatesOfAccount.ExchangeRate * CurrencyRatesOfPettyCashe.Multiplicity) AS NUMBER(15, 2)) AS PrincipalDebt,
	|	CAST(CashPayment.DocumentAmount * CurrencyRatesOfPettyCashe.ExchangeRate * CurrencyRatesOfContract.Multiplicity / (CurrencyRatesOfContract.ExchangeRate * CurrencyRatesOfPettyCashe.Multiplicity) AS NUMBER(15, 2)) AS PrincipalDebtCurForBalance,
	|	CAST(CashPayment.DocumentAmount * CurrencyRatesOfPettyCashe.ExchangeRate * CurrencyRatesOfAccount.Multiplicity / (CurrencyRatesOfAccount.ExchangeRate * CurrencyRatesOfPettyCashe.Multiplicity) AS NUMBER(15, 2)) AS PrincipalDebtForBalance,
	|	0 AS InterestCur,
	|	0 AS Interest,
	|	0 AS InterestCurForBalance,
	|	0 AS InterestForBalance,
	|	0 AS CommissionCur,
	|	0 AS Commission,
	|	0 AS CommissionCurForBalance,
	|	0 AS CommissionForBalance,
	|	CAST(CashPayment.DocumentAmount * CurrencyRatesOfPettyCashe.ExchangeRate * CurrencyRatesOfContract.Multiplicity / (CurrencyRatesOfContract.ExchangeRate * CurrencyRatesOfPettyCashe.Multiplicity) AS NUMBER(15, 2)) AS AmountCur,
	|	CAST(CashPayment.DocumentAmount * CurrencyRatesOfPettyCashe.ExchangeRate * CurrencyRatesOfAccount.Multiplicity / (CurrencyRatesOfAccount.ExchangeRate * CurrencyRatesOfPettyCashe.Multiplicity) AS NUMBER(15, 2)) AS Amount,
	|	CashPayment.LoanContract AS LoanContract,
	|	CashPayment.LoanContract.SettlementsCurrency AS Currency,
	|	CashPayment.CashCurrency AS CashCurrency,
	|	CashPayment.LoanContract.GLAccount AS GLAccount,
	|	CashPayment.PettyCash,
	|	FALSE AS DeductedFromSalary
	|INTO TemporaryTableLoanSettlements
	|FROM
	|	Document.CashPayment AS CashPayment
	|		LEFT JOIN TemporaryTableCurrencyRatesSliceLatest AS CurrencyRatesOfAccount
	|		ON (CurrencyRatesOfAccount.Currency = &AccountingCurrency)
	|		LEFT JOIN TemporaryTableCurrencyRatesSliceLatest AS CurrencyRatesOfPettyCashe
	|		ON (CurrencyRatesOfPettyCashe.Currency = &CashCurrency)
	|		LEFT JOIN TemporaryTableCurrencyRatesSliceLatest AS CurrencyRatesOfContract
	|		ON (CurrencyRatesOfContract.Currency = CashPayment.LoanContract.SettlementsCurrency)
	|WHERE
	|	CashPayment.OperationKind = VALUE(Enum.OperationKindsCashPayment.IssueLoanToEmployee)
	|	AND CashPayment.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	&Company,
	|	VALUE(AccumulationRecordType.Receipt),
	|	CASE
	|		WHEN DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.LoanSettlements)
	|			THEN VALUE(Enum.LoanContractTypes.Borrowed)
	|		ELSE VALUE(Enum.LoanContractTypes.EmployeeLoanAgreement)
	|	END,
	|	DocumentTable.Date,
	|	DocumentTable.Date,
	|	DocumentTable.ContentByTypeOfAmount,
	|	DocumentTable.Counterparty,
	|	DocumentTable.PaymentAmount,
	|	CASE
	|		WHEN DocumentTable.TypeOfAmount = VALUE(Enum.LoanScheduleAmountTypes.Principal)
	|			THEN DocumentTable.SettlementsAmount
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DocumentTable.TypeOfAmount = VALUE(Enum.LoanScheduleAmountTypes.Principal)
	|			THEN DocumentTable.AccountingAmount
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DocumentTable.TypeOfAmount = VALUE(Enum.LoanScheduleAmountTypes.Principal)
	|			THEN DocumentTable.SettlementsAmount
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DocumentTable.TypeOfAmount = VALUE(Enum.LoanScheduleAmountTypes.Principal)
	|			THEN DocumentTable.AccountingAmount
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DocumentTable.TypeOfAmount = VALUE(Enum.LoanScheduleAmountTypes.Interest)
	|			THEN DocumentTable.SettlementsAmount
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DocumentTable.TypeOfAmount = VALUE(Enum.LoanScheduleAmountTypes.Interest)
	|			THEN DocumentTable.AccountingAmount
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DocumentTable.TypeOfAmount = VALUE(Enum.LoanScheduleAmountTypes.Interest)
	|			THEN DocumentTable.SettlementsAmount
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DocumentTable.TypeOfAmount = VALUE(Enum.LoanScheduleAmountTypes.Interest)
	|			THEN DocumentTable.AccountingAmount
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DocumentTable.TypeOfAmount = VALUE(Enum.LoanScheduleAmountTypes.Commission)
	|			THEN DocumentTable.SettlementsAmount
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DocumentTable.TypeOfAmount = VALUE(Enum.LoanScheduleAmountTypes.Commission)
	|			THEN DocumentTable.AccountingAmount
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DocumentTable.TypeOfAmount = VALUE(Enum.LoanScheduleAmountTypes.Commission)
	|			THEN DocumentTable.SettlementsAmount
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DocumentTable.TypeOfAmount = VALUE(Enum.LoanScheduleAmountTypes.Commission)
	|			THEN DocumentTable.AccountingAmount
	|		ELSE 0
	|	END,
	|	DocumentTable.SettlementsAmount,
	|	DocumentTable.AccountingAmount,
	|	DocumentTable.LoanContract,
	|	DocumentTable.LoanContract.SettlementsCurrency,
	|	DocumentTable.CashCurrency,
	|	CASE
	|		WHEN DocumentTable.TypeOfAmount = VALUE(Enum.LoanScheduleAmountTypes.Principal)
	|			THEN DocumentTable.LoanContract.GLAccount
	|		WHEN DocumentTable.TypeOfAmount = VALUE(Enum.LoanScheduleAmountTypes.Interest)
	|			THEN DocumentTable.LoanContract.InterestGLAccount
	|		WHEN DocumentTable.TypeOfAmount = VALUE(Enum.LoanScheduleAmountTypes.Commission)
	|			THEN DocumentTable.LoanContract.CommissionGLAccount
	|		ELSE 0
	|	END,
	|	DocumentTable.PettyCash,
	|	FALSE
	|FROM
	|	TemporaryTablePaymentDetails AS DocumentTable
	|WHERE
	|	DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.LoanSettlements)";
	
	QueryResult = Query.Execute();
	
	Query.Text =
	"SELECT
	|	TemporaryTableLoanSettlements.Company AS Company,
	|	TemporaryTableLoanSettlements.Counterparty AS Counterparty,
	|	TemporaryTableLoanSettlements.LoanContract AS LoanContract
	|FROM
	|	TemporaryTableLoanSettlements AS TemporaryTableLoanSettlements";
	
	QueryResult = Query.Execute();
	
	DataLock			= New DataLock;
	LockItem			= DataLock.Add("AccumulationRegister.LoanSettlements");
	LockItem.Mode		= DataLockMode.Exclusive;
	LockItem.DataSource	= QueryResult;
	
	For Each Column In QueryResult.Columns Do
		LockItem.UseFromDataSource(Column.Name, Column.Name);
	EndDo;
	
	DataLock.Lock();
	
	QueryNumber = 0;
	
	Query.Text = SmallBusinessServer.GetQueryTextExchangeRateDifferencesLoanSettlements(Query.TempTablesManager, QueryNumber);
	ResultsArray = Query.ExecuteBatch();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableLoanSettlements", ResultsArray[QueryNumber].Unload());
	
EndProcedure

#Region Billing

// Формирует таблицу значений, содержащую данные для проведения по регистру ВыполнениеДоговоровОбслуживания.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableServiceContractExecution(DocumentRefCashPayment, StructureAdditionalProperties)
	
	If Not ValueIsFilled(DocumentRefCashPayment.BusinessActivity)
		Or Not GetFunctionalOption("UseBilling")
		Or Not Constants.BillingKeepExpensesAccountingByServiceContracts.Get() Then
		StructureAdditionalProperties.TableForRegisterRecords.Insert("TableServiceContractExecution", New ValueTable);
		Return;
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	TemporaryTableHeader.Date AS Period,
	|	CounterpartyContracts.Ref AS Contract,
	|	TemporaryTableHeader.Correspondence AS ServiceContractObject,
	|	TRUE AS CostSpecified,
	|	1 AS Quantity,
	|	TemporaryTableHeader.AmountByServiceContract AS Amount
	|FROM
	|	TemporaryTableHeader AS TemporaryTableHeader
	|		INNER JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
	|		ON TemporaryTableHeader.BusinessActivity = CounterpartyContracts.ServiceContractBusinessActivity
	|WHERE
	|	(TemporaryTableHeader.OperationKind = VALUE(Enum.OperationKindsCashPayment.Other))
	|	AND CounterpartyContracts.IsServiceContract";
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableServiceContractExecution", QueryResult.Unload());
	
EndProcedure

#EndRegion

// Initializes the tables of values that contain the data of the document table sections.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure InitializeDocumentData(DocumentRefCashPayment, StructureAdditionalProperties) Export
	
	Query = New Query;
	
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	
	Query.SetParameter("Ref", DocumentRefCashPayment);
	Query.SetParameter("Company", StructureAdditionalProperties.ForPosting.Company);
	Query.SetParameter("PointInTime", New Boundary(StructureAdditionalProperties.ForPosting.PointInTime, BoundaryType.Including));
	
	Query.SetParameter("AccountingCurrency", Constants.AccountingCurrency.Get());
	Query.SetParameter("CashCurrency", DocumentRefCashPayment.CashCurrency);
	Query.SetParameter("LoanContractCurrency", DocumentRefCashPayment.LoanContract.SettlementsCurrency);
	If Not ValueIsFilled(DocumentRefCashPayment.BusinessActivity)
		Or Not GetFunctionalOption("UseBilling")
		Or Not Constants.BillingKeepExpensesAccountingByServiceContracts.Get() Then
		Query.SetParameter("ServiceContractCurrency", Catalogs.Currencies.EmptyRef());
	Else
		ServiceContract = Catalogs.CounterpartyContracts.FindByAttribute("ServiceContractBusinessActivity", DocumentRefCashPayment.BusinessActivity);
		Query.SetParameter("ServiceContractCurrency", ?(ValueIsFilled(ServiceContract), ServiceContract.SettlementsCurrency, Catalogs.Currencies.EmptyRef()));
	EndIf;
	
	Query.Text =
	"SELECT
	|	CurrencyRatesSliceLast.Currency AS Currency,
	|	CurrencyRatesSliceLast.ExchangeRate AS ExchangeRate,
	|	CurrencyRatesSliceLast.Multiplicity AS Multiplicity
	|INTO TemporaryTableCurrencyRatesSliceLatest
	|FROM
	|	InformationRegister.CurrencyRates.SliceLast(&PointInTime, Currency IN (&AccountingCurrency, &CashCurrency, &LoanContractCurrency, &ServiceContractCurrency)) AS CurrencyRatesSliceLast
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(DocumentTable.LineNumber) AS LineNumber,
	|	DocumentTable.Ref.CashCurrency AS CashCurrency,
	|	DocumentTable.Document AS Document,
	|	DocumentTable.Ref.OperationKind AS OperationKind,
	|	DocumentTable.Ref.Counterparty AS Counterparty,
	|	DocumentTable.Ref.Counterparty.DoOperationsByContracts AS DoOperationsByContracts,
	|	DocumentTable.Ref.Counterparty.DoOperationsByDocuments AS DoOperationsByDocuments,
	|	DocumentTable.Ref.Counterparty.DoOperationsByOrders AS DoOperationsByOrders,
	|	DocumentTable.Ref.Counterparty.TrackPaymentsByBills AS TrackPaymentsByBills,
	|	DocumentTable.Contract AS Contract,
	|	CASE
	|		WHEN DocumentTable.Contract.IsServiceContract
	|				AND DocumentTable.Contract.ServiceContractBusinessActivity <> VALUE(Catalog.BusinessActivities.EmptyRef)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS KeepAccountingExpensesByServiceContracts,
	|	DocumentTable.Contract.ServiceContractBusinessActivity AS ServiceContractBusinessActivity,
	|	DocumentTable.Contract.SettlementsCurrency AS SettlementsCurrency,
	|	DocumentTable.Ref.PettyCash AS PettyCash,
	|	DocumentTable.Ref.Correspondence AS Correspondence,
	|	DocumentTable.Ref.Item AS Item,
	|	CASE
	|		WHEN DocumentTable.Order = UNDEFINED
	|				AND DocumentTable.Ref.OperationKind = VALUE(Enum.OperationKindsCashPayment.ToCustomer)
	|			THEN VALUE(Document.CustomerOrder.EmptyRef)
	|		WHEN DocumentTable.Order = UNDEFINED
	|				AND DocumentTable.Ref.OperationKind = VALUE(Enum.OperationKindsCashPayment.Vendor)
	|			THEN VALUE(Document.PurchaseOrder.EmptyRef)
	|		WHEN DocumentTable.Ref.OperationKind = VALUE(Enum.OperationKindsCashPayment.ToCustomer)
	|				AND DocumentTable.Order = VALUE(Document.PurchaseOrder.EmptyRef)
	|			THEN VALUE(Document.CustomerOrder.EmptyRef)
	|		WHEN DocumentTable.Ref.OperationKind = VALUE(Enum.OperationKindsCashPayment.Vendor)
	|				AND DocumentTable.Order = VALUE(Document.CustomerOrder.EmptyRef)
	|			THEN VALUE(Document.PurchaseOrder.EmptyRef)
	|		ELSE DocumentTable.Order
	|	END AS Order,
	|	DocumentTable.AdvanceFlag AS AdvanceFlag,
	|	DocumentTable.Ref.Date AS Date,
	|	SUM(CAST(DocumentTable.PaymentAmount * CurrencyRatesOfPettyCashe.ExchangeRate * AccountingCurrencyRates.Multiplicity / (AccountingCurrencyRates.ExchangeRate * CurrencyRatesOfPettyCashe.Multiplicity) AS NUMBER(15, 2))) AS AccountingAmount,
	|	SUM(DocumentTable.SettlementsAmount) AS SettlementsAmount,
	|	SUM(DocumentTable.PaymentAmount) AS PaymentAmount,
	|	CASE
	|		WHEN VALUETYPE(DocumentTable.PlanningDocument) = TYPE(Document.CashOutflowPlan)
	|				AND DocumentTable.PlanningDocument <> VALUE(Document.CashOutflowPlan.EmptyRef)
	|			THEN DocumentTable.PlanningDocument
	|		WHEN VALUETYPE(DocumentTable.PlanningDocument) = TYPE(Document.CashTransferPlan)
	|				AND DocumentTable.PlanningDocument <> VALUE(Document.CashTransferPlan.EmptyRef)
	|			THEN DocumentTable.PlanningDocument
	|		WHEN DocumentTable.InvoiceForPayment.SchedulePayment
	|			THEN DocumentTable.InvoiceForPayment
	|		WHEN DocumentTable.Order.SchedulePayment
	|			THEN DocumentTable.Order
	|		ELSE UNDEFINED
	|	END AS InvoiceForPaymentToPaymentCalendar,
	|	DocumentTable.InvoiceForPayment AS InvoiceForPayment,
	|	DocumentTable.Ref.PettyCash.GLAccount AS BankAccountCashGLAccount,
	|	DocumentTable.Ref.Counterparty.GLAccountCustomerSettlements AS GLAccountCustomerSettlements,
	|	DocumentTable.Ref.Counterparty.CustomerAdvancesGLAccount AS CustomerAdvancesGLAccount,
	|	DocumentTable.Ref.Counterparty.GLAccountVendorSettlements AS GLAccountVendorSettlements,
	|	DocumentTable.Ref.Counterparty.VendorAdvancesGLAccount AS VendorAdvancesGLAccount,
	|	DocumentTable.Ref.LoanContract,
	|	DocumentTable.TypeOfAmount,
	|	DocumentTable.Ref.AdvanceHolder AS Employee,
	|	CASE
	|		WHEN DocumentTable.TypeOfAmount = VALUE(Enum.LoanScheduleAmountTypes.Principal)
	|			THEN DocumentTable.Ref.LoanContract.GLAccount
	|		WHEN DocumentTable.TypeOfAmount = VALUE(Enum.LoanScheduleAmountTypes.Interest)
	|			THEN DocumentTable.Ref.LoanContract.InterestGLAccount
	|		WHEN DocumentTable.TypeOfAmount = VALUE(Enum.LoanScheduleAmountTypes.Commission)
	|			THEN DocumentTable.Ref.LoanContract.CommissionGLAccount
	|	END AS GLAccountByTypeOfAmount,
	|	CASE
	|		WHEN DocumentTable.TypeOfAmount = VALUE(Enum.LoanScheduleAmountTypes.Principal)
	|			THEN ""Credit principal debt payment""
	|		WHEN DocumentTable.TypeOfAmount = VALUE(Enum.LoanScheduleAmountTypes.Interest)
	|			THEN ""Credit interest payment""
	|		WHEN DocumentTable.TypeOfAmount = VALUE(Enum.LoanScheduleAmountTypes.Commission)
	|			THEN ""Credit comission payment""
	|	END AS ContentByTypeOfAmount
	|INTO TemporaryTablePaymentDetails
	|FROM
	|	Document.CashPayment.PaymentDetails AS DocumentTable
	|		LEFT JOIN TemporaryTableCurrencyRatesSliceLatest AS AccountingCurrencyRates
	|		ON (AccountingCurrencyRates.Currency = &AccountingCurrency)
	|		LEFT JOIN TemporaryTableCurrencyRatesSliceLatest AS CurrencyRatesOfPettyCashe
	|		ON (CurrencyRatesOfPettyCashe.Currency = &CashCurrency)
	|WHERE
	|	DocumentTable.Ref = &Ref
	|
	|GROUP BY
	|	DocumentTable.Ref.CashCurrency,
	|	DocumentTable.Document,
	|	DocumentTable.Ref.OperationKind,
	|	DocumentTable.Ref.Counterparty,
	|	DocumentTable.Contract,
	|	DocumentTable.Ref.PettyCash,
	|	DocumentTable.Ref.Item,
	|	DocumentTable.Ref.Correspondence,
	|	CASE
	|		WHEN DocumentTable.Order = UNDEFINED
	|				AND DocumentTable.Ref.OperationKind = VALUE(Enum.OperationKindsCashPayment.ToCustomer)
	|			THEN VALUE(Document.CustomerOrder.EmptyRef)
	|		WHEN DocumentTable.Order = UNDEFINED
	|				AND DocumentTable.Ref.OperationKind = VALUE(Enum.OperationKindsCashPayment.Vendor)
	|			THEN VALUE(Document.PurchaseOrder.EmptyRef)
	|		WHEN DocumentTable.Ref.OperationKind = VALUE(Enum.OperationKindsCashPayment.ToCustomer)
	|				AND DocumentTable.Order = VALUE(Document.PurchaseOrder.EmptyRef)
	|			THEN VALUE(Document.CustomerOrder.EmptyRef)
	|		WHEN DocumentTable.Ref.OperationKind = VALUE(Enum.OperationKindsCashPayment.Vendor)
	|				AND DocumentTable.Order = VALUE(Document.CustomerOrder.EmptyRef)
	|			THEN VALUE(Document.PurchaseOrder.EmptyRef)
	|		ELSE DocumentTable.Order
	|	END,
	|	DocumentTable.AdvanceFlag,
	|	DocumentTable.Ref.Date,
	|	DocumentTable.Contract.SettlementsCurrency,
	|	CASE
	|		WHEN VALUETYPE(DocumentTable.PlanningDocument) = TYPE(Document.CashOutflowPlan)
	|				AND DocumentTable.PlanningDocument <> VALUE(Document.CashOutflowPlan.EmptyRef)
	|			THEN DocumentTable.PlanningDocument
	|		WHEN VALUETYPE(DocumentTable.PlanningDocument) = TYPE(Document.CashTransferPlan)
	|				AND DocumentTable.PlanningDocument <> VALUE(Document.CashTransferPlan.EmptyRef)
	|			THEN DocumentTable.PlanningDocument
	|		WHEN DocumentTable.InvoiceForPayment.SchedulePayment
	|			THEN DocumentTable.InvoiceForPayment
	|		WHEN DocumentTable.Order.SchedulePayment
	|			THEN DocumentTable.Order
	|		ELSE UNDEFINED
	|	END,
	|	DocumentTable.InvoiceForPayment,
	|	DocumentTable.Order,
	|	DocumentTable.Ref.Counterparty.GLAccountCustomerSettlements,
	|	DocumentTable.Ref.Counterparty.CustomerAdvancesGLAccount,
	|	DocumentTable.Ref.Counterparty.GLAccountVendorSettlements,
	|	DocumentTable.Ref.Counterparty.VendorAdvancesGLAccount,
	|	DocumentTable.Ref.PettyCash.GLAccount,
	|	DocumentTable.Ref.Counterparty.DoOperationsByContracts,
	|	DocumentTable.Ref.Counterparty.DoOperationsByDocuments,
	|	DocumentTable.Ref.Counterparty.DoOperationsByOrders,
	|	DocumentTable.Ref.Counterparty.TrackPaymentsByBills,
	|	DocumentTable.Ref.LoanContract,
	|	DocumentTable.TypeOfAmount,
	|	DocumentTable.Ref.AdvanceHolder,
	|	CASE
	|		WHEN DocumentTable.TypeOfAmount = VALUE(Enum.LoanScheduleAmountTypes.Principal)
	|			THEN DocumentTable.Ref.LoanContract.GLAccount
	|		WHEN DocumentTable.TypeOfAmount = VALUE(Enum.LoanScheduleAmountTypes.Interest)
	|			THEN DocumentTable.Ref.LoanContract.InterestGLAccount
	|		WHEN DocumentTable.TypeOfAmount = VALUE(Enum.LoanScheduleAmountTypes.Commission)
	|			THEN DocumentTable.Ref.LoanContract.CommissionGLAccount
	|	END,
	|	CASE
	|		WHEN DocumentTable.TypeOfAmount = VALUE(Enum.LoanScheduleAmountTypes.Principal)
	|			THEN ""Credit principal debt payment""
	|		WHEN DocumentTable.TypeOfAmount = VALUE(Enum.LoanScheduleAmountTypes.Interest)
	|			THEN ""Credit interest payment""
	|		WHEN DocumentTable.TypeOfAmount = VALUE(Enum.LoanScheduleAmountTypes.Commission)
	|			THEN ""Credit comission payment""
	|	END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	1 AS LineNumber,
	|	DocumentTable.OperationKind AS OperationKind,
	|	DocumentTable.Date AS Date,
	|	&Company AS Company,
	|	DocumentTable.Item AS Item,
	|	DocumentTable.PettyCash AS PettyCash,
	|	DocumentTable.CashCR AS CashCR,
	|	DocumentTable.CashCurrency AS CashCurrency,
	|	CAST(DocumentTable.DocumentAmount * CurrencyRatesOfPettyCashe.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * CurrencyRatesOfPettyCashe.Multiplicity) AS NUMBER(15, 2)) AS Amount,
	|	DocumentTable.DocumentAmount AS AmountCur,
	|	CAST(CASE
	|			WHEN &ServiceContractCurrency <> VALUE(Catalog.Currencies.EmptyRef)
	|					AND &ServiceContractCurrency = DocumentTable.CashCurrency
	|				THEN DocumentTable.DocumentAmount
	|			WHEN &ServiceContractCurrency <> VALUE(Catalog.Currencies.EmptyRef)
	|					AND &ServiceContractCurrency <> DocumentTable.CashCurrency
	|				THEN DocumentTable.DocumentAmount * CurrencyRatesOfPettyCashe.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity * CurrencyRatesServiceContract.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * CurrencyRatesOfPettyCashe.Multiplicity * CurrencyRatesServiceContract.ExchangeRate)
	|			ELSE 0
	|		END AS NUMBER(15, 2)) AS AmountByServiceContract,
	|	DocumentTable.PettyCash.GLAccount AS PettyCashGLAccount,
	|	DocumentTable.CashCR.GLAccount AS CashCRGLAccount,
	|	DocumentTable.TaxKind AS TaxKind,
	|	DocumentTable.TaxKind.GLAccount AS TaxKindGLAccount,
	|	DocumentTable.Department AS Department,
	|	DocumentTable.BusinessActivity AS BusinessActivity,
	|	DocumentTable.BusinessActivity.GLAccountRevenueFromSales AS BusinessActivityGLAccountOfRevenueFromSales,
	|	DocumentTable.BusinessActivity.GLAccountCostOfSales AS BusinessActivityGLAccountOfSalesCost,
	|	DocumentTable.Order AS Order,
	|	DocumentTable.Correspondence AS Correspondence,
	|	DocumentTable.Correspondence.TypeOfAccount AS CorrespondenceGLAccountType,
	|	DocumentTable.AdvanceHolder AS AdvanceHolder,
	|	DocumentTable.AdvanceHolder.SettlementsHumanResourcesGLAccount AS AdvanceHolderPersonnelGLAccount,
	|	DocumentTable.RegistrationPeriod AS RegistrationPeriod,
	|	DocumentTable.AdvanceHolder.AdvanceHoldersGLAccount AS AdvanceHolderAdvanceHoldersGLAccount,
	|	DocumentTable.Document AS Document,
	|	CASE
	|		WHEN DocumentTable.OperationKind = VALUE(Enum.OperationKindsCashPayment.OtherSettlements)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS AccountingOtherSettlements
	|INTO TemporaryTableHeader
	|FROM
	|	Document.CashPayment AS DocumentTable
	|		LEFT JOIN TemporaryTableCurrencyRatesSliceLatest AS AccountingCurrencyRatesSliceLast
	|		ON (AccountingCurrencyRatesSliceLast.Currency = &AccountingCurrency)
	|		LEFT JOIN TemporaryTableCurrencyRatesSliceLatest AS CurrencyRatesOfPettyCashe
	|		ON (CurrencyRatesOfPettyCashe.Currency = &CashCurrency)
	|		LEFT JOIN TemporaryTableCurrencyRatesSliceLatest AS CurrencyRatesServiceContract
	|		ON (CurrencyRatesServiceContract.Currency = &ServiceContractCurrency)
	|WHERE
	|	DocumentTable.Ref = &Ref";
	
	Query.Execute();
	
	// Register record table creation by account sections.
	GenerateTableCashAssets(DocumentRefCashPayment, StructureAdditionalProperties);
	GenerateTableCashAssetsInCashRegisters(DocumentRefCashPayment, StructureAdditionalProperties);
	GenerateAdvanceHolderPaymentsTable(DocumentRefCashPayment, StructureAdditionalProperties);
	GenerateTableAccountsPayable(DocumentRefCashPayment, StructureAdditionalProperties);
	GenerateTableCustomerAccounts(DocumentRefCashPayment, StructureAdditionalProperties);
	GenerateTablePayrollPayments(DocumentRefCashPayment, StructureAdditionalProperties);
	// Other settlements
	GenerateTableSettlementsWithOtherCounterparties(DocumentRefCashPayment, StructureAdditionalProperties);
	GenerateTableLoanSettlements(DocumentRefCashPayment, StructureAdditionalProperties);
	// End Other settlements
	GenerateTableIncomeAndExpenses(DocumentRefCashPayment, StructureAdditionalProperties);
	GenerateTableTaxesSettlements(DocumentRefCashPayment, StructureAdditionalProperties);
	GenerateTableManagerial(DocumentRefCashPayment, StructureAdditionalProperties);
	GenerateTableIncomeAndExpensesUndistributed(DocumentRefCashPayment, StructureAdditionalProperties);
	GenerateTableIncomeAndExpensesRetained(DocumentRefCashPayment, StructureAdditionalProperties);
	GenerateTableIncomeAndExpensesCashMethod(DocumentRefCashPayment, StructureAdditionalProperties);
	GenerateTablePaymentCalendar(DocumentRefCashPayment, StructureAdditionalProperties);
	GenerateTableInvoicesAndOrdersPayment(DocumentRefCashPayment, StructureAdditionalProperties);
	// Billing
	GenerateTableServiceContractExecution(DocumentRefCashPayment, StructureAdditionalProperties);
	
EndProcedure // DocumentDataInitialization()

// Controls the occurrence of negative balances.
//
Procedure RunControl(DocumentRefCashPayment, AdditionalProperties, Cancel, PostingDelete = False) Export
	
	If Not Constants.ControlBalancesOnPosting.Get() Then
		Return;
	EndIf;
	
	StructureTemporaryTables = AdditionalProperties.ForPosting.StructureTemporaryTables;
	
	// If temporary tables contain records, it is
	// necessary to execute negative balance control.
	If StructureTemporaryTables.RegisterRecordsCashAssetsChange
	 OR StructureTemporaryTables.RegisterRecordsAdvanceHolderPaymentsChange
	 OR StructureTemporaryTables.RegisterRecordsSuppliersSettlementsChange
	 OR StructureTemporaryTables.RegisterRecordsCashInCashRegistersChange Then
		
		Query = New Query(
		"SELECT
		|	RegisterRecordsCashAssetsChange.LineNumber AS LineNumber,
		|	RegisterRecordsCashAssetsChange.Company AS CompanyPresentation,
		|	RegisterRecordsCashAssetsChange.BankAccountPettyCash AS BankAccountCashPresentation,
		|	RegisterRecordsCashAssetsChange.Currency AS CurrencyPresentation,
		|	RegisterRecordsCashAssetsChange.CashAssetsType AS CashAssetsTypeRepresentation,
		|	RegisterRecordsCashAssetsChange.CashAssetsType AS CashAssetsType,
		|	ISNULL(CashAssetsBalances.AmountBalance, 0) AS AmountBalance,
		|	ISNULL(CashAssetsBalances.AmountCurBalance, 0) AS AmountCurBalance,
		|	RegisterRecordsCashAssetsChange.SumCurChange + ISNULL(CashAssetsBalances.AmountCurBalance, 0) AS BalanceCashAssets,
		|	RegisterRecordsCashAssetsChange.SumBeforeWrite AS SumBeforeWrite,
		|	RegisterRecordsCashAssetsChange.AmountOnWrite AS AmountOnWrite,
		|	RegisterRecordsCashAssetsChange.AmountChange AS AmountChange,
		|	RegisterRecordsCashAssetsChange.AmountCurBeforeWrite AS AmountCurBeforeWrite,
		|	RegisterRecordsCashAssetsChange.SumCurOnWrite AS SumCurOnWrite,
		|	RegisterRecordsCashAssetsChange.SumCurChange AS SumCurChange
		|FROM
		|	RegisterRecordsCashAssetsChange AS RegisterRecordsCashAssetsChange
		|		LEFT JOIN AccumulationRegister.CashAssets.Balance(&ControlTime, ) AS CashAssetsBalances
		|		ON RegisterRecordsCashAssetsChange.Company = CashAssetsBalances.Company
		|			AND RegisterRecordsCashAssetsChange.CashAssetsType = CashAssetsBalances.CashAssetsType
		|			AND RegisterRecordsCashAssetsChange.BankAccountPettyCash = CashAssetsBalances.BankAccountPettyCash
		|			AND RegisterRecordsCashAssetsChange.Currency = CashAssetsBalances.Currency
		|WHERE
		|	ISNULL(CashAssetsBalances.AmountCurBalance, 0) < 0
		|
		|ORDER BY
		|	LineNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RegisterRecordsAdvanceHolderPaymentsChange.LineNumber AS LineNumber,
		|	RegisterRecordsAdvanceHolderPaymentsChange.Company AS CompanyPresentation,
		|	RegisterRecordsAdvanceHolderPaymentsChange.Employee AS EmployeePresentation,
		|	RegisterRecordsAdvanceHolderPaymentsChange.Currency AS CurrencyPresentation,
		|	RegisterRecordsAdvanceHolderPaymentsChange.Document AS DocumentPresentation,
		|	ISNULL(AdvanceHolderPaymentsBalances.AmountBalance, 0) AS AmountBalance,
		|	ISNULL(AdvanceHolderPaymentsBalances.AmountCurBalance, 0) AS AmountCurBalance,
		|	RegisterRecordsAdvanceHolderPaymentsChange.SumCurChange + ISNULL(AdvanceHolderPaymentsBalances.AmountCurBalance, 0) AS AccountablePersonBalance,
		|	RegisterRecordsAdvanceHolderPaymentsChange.SumBeforeWrite AS SumBeforeWrite,
		|	RegisterRecordsAdvanceHolderPaymentsChange.AmountOnWrite AS AmountOnWrite,
		|	RegisterRecordsAdvanceHolderPaymentsChange.AmountChange AS AmountChange,
		|	RegisterRecordsAdvanceHolderPaymentsChange.AmountCurBeforeWrite AS AmountCurBeforeWrite,
		|	RegisterRecordsAdvanceHolderPaymentsChange.SumCurOnWrite AS SumCurOnWrite,
		|	RegisterRecordsAdvanceHolderPaymentsChange.SumCurChange AS SumCurChange
		|FROM
		|	RegisterRecordsAdvanceHolderPaymentsChange AS RegisterRecordsAdvanceHolderPaymentsChange
		|		LEFT JOIN AccumulationRegister.AdvanceHolderPayments.Balance(&ControlTime, ) AS AdvanceHolderPaymentsBalances
		|		ON RegisterRecordsAdvanceHolderPaymentsChange.Company = AdvanceHolderPaymentsBalances.Company
		|			AND RegisterRecordsAdvanceHolderPaymentsChange.Employee = AdvanceHolderPaymentsBalances.Employee
		|			AND RegisterRecordsAdvanceHolderPaymentsChange.Currency = AdvanceHolderPaymentsBalances.Currency
		|			AND RegisterRecordsAdvanceHolderPaymentsChange.Document = AdvanceHolderPaymentsBalances.Document
		|WHERE
		|	(VALUETYPE(AdvanceHolderPaymentsBalances.Document) = Type(Document.ExpenseReport)
		|				AND ISNULL(AdvanceHolderPaymentsBalances.AmountCurBalance, 0) > 0
		|			OR VALUETYPE(AdvanceHolderPaymentsBalances.Document) <> Type(Document.ExpenseReport)
		|				AND ISNULL(AdvanceHolderPaymentsBalances.AmountCurBalance, 0) < 0)
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
		|	TRUE AS RegisterRecordsOfCashDocuments,
		|	RegisterRecordsSuppliersSettlementsChange.SumBeforeWrite AS SumBeforeWrite,
		|	RegisterRecordsSuppliersSettlementsChange.AmountOnWrite AS AmountOnWrite,
		|	RegisterRecordsSuppliersSettlementsChange.AmountChange AS AmountChange,
		|	RegisterRecordsSuppliersSettlementsChange.AmountCurBeforeWrite AS AmountCurBeforeWrite,
		|	RegisterRecordsSuppliersSettlementsChange.SumCurOnWrite AS SumCurOnWrite,
		|	RegisterRecordsSuppliersSettlementsChange.SumCurChange AS SumCurChange,
		|	RegisterRecordsSuppliersSettlementsChange.SumCurChange + ISNULL(AccountsPayableBalances.AmountCurBalance, 0) AS DebtBalanceAmount,
		|	-(RegisterRecordsSuppliersSettlementsChange.SumCurChange + ISNULL(AccountsPayableBalances.AmountCurBalance, 0)) AS AmountOfOutstandingAdvances,
		|	ISNULL(AccountsPayableBalances.AmountBalance, 0) AS AmountBalance,
		|	ISNULL(AccountsPayableBalances.AmountCurBalance, 0) AS AmountCurBalance,
		|	RegisterRecordsSuppliersSettlementsChange.SettlementsType AS SettlementsType
		|FROM
		|	RegisterRecordsSuppliersSettlementsChange AS RegisterRecordsSuppliersSettlementsChange
		|		LEFT JOIN AccumulationRegister.AccountsPayable.Balance(&ControlTime, ) AS AccountsPayableBalances
		|		ON RegisterRecordsSuppliersSettlementsChange.Company = AccountsPayableBalances.Company
		|			AND RegisterRecordsSuppliersSettlementsChange.Counterparty = AccountsPayableBalances.Counterparty
		|			AND RegisterRecordsSuppliersSettlementsChange.Contract = AccountsPayableBalances.Contract
		|			AND RegisterRecordsSuppliersSettlementsChange.Document = AccountsPayableBalances.Document
		|			AND RegisterRecordsSuppliersSettlementsChange.Order = AccountsPayableBalances.Order
		|			AND RegisterRecordsSuppliersSettlementsChange.SettlementsType = AccountsPayableBalances.SettlementsType
		|WHERE
		|	CASE
		|			WHEN RegisterRecordsSuppliersSettlementsChange.SettlementsType = VALUE(Enum.SettlementsTypes.Advance)
		|				THEN ISNULL(AccountsPayableBalances.AmountCurBalance, 0) > 0
		|			ELSE ISNULL(AccountsPayableBalances.AmountCurBalance, 0) < 0
		|		END
		|
		|ORDER BY
		|	LineNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RegisterRecordsCashInCashRegistersChange.LineNumber AS LineNumber,
		|	RegisterRecordsCashInCashRegistersChange.Company AS CompanyPresentation,
		|	RegisterRecordsCashInCashRegistersChange.CashCR AS CashCRDescription,
		|	RegisterRecordsCashInCashRegistersChange.CashCR.CashCurrency AS CurrencyPresentation,
		|	ISNULL(CashAssetsInRetailCashesBalances.AmountBalance, 0) AS AmountBalance,
		|	ISNULL(CashAssetsInRetailCashesBalances.AmountCurBalance, 0) AS AmountCurBalance,
		|	RegisterRecordsCashInCashRegistersChange.SumCurChange + ISNULL(CashAssetsInRetailCashesBalances.AmountCurBalance, 0) AS BalanceCashAssets,
		|	RegisterRecordsCashInCashRegistersChange.SumBeforeWrite AS SumBeforeWrite,
		|	RegisterRecordsCashInCashRegistersChange.AmountOnWrite AS AmountOnWrite,
		|	RegisterRecordsCashInCashRegistersChange.AmountChange AS AmountChange,
		|	RegisterRecordsCashInCashRegistersChange.AmountCurBeforeWrite AS AmountCurBeforeWrite,
		|	RegisterRecordsCashInCashRegistersChange.SumCurOnWrite AS SumCurOnWrite,
		|	RegisterRecordsCashInCashRegistersChange.SumCurChange AS SumCurChange
		|FROM
		|	RegisterRecordsCashInCashRegistersChange AS RegisterRecordsCashInCashRegistersChange
		|		LEFT JOIN AccumulationRegister.CashInCashRegisters.Balance(&ControlTime, ) AS CashAssetsInRetailCashesBalances
		|		ON RegisterRecordsCashInCashRegistersChange.Company = CashAssetsInRetailCashesBalances.Company
		|			AND RegisterRecordsCashInCashRegistersChange.CashCR = CashAssetsInRetailCashesBalances.CashCR
		|WHERE
		|	ISNULL(CashAssetsInRetailCashesBalances.AmountCurBalance, 0) < 0
		|
		|ORDER BY
		|	LineNumber");
		
		Query.TempTablesManager = StructureTemporaryTables.TempTablesManager;
		Query.SetParameter("ControlTime", AdditionalProperties.ForPosting.ControlTime);
		
		ResultsArray = Query.ExecuteBatch();
		
		If Not ResultsArray[0].IsEmpty()
			OR Not ResultsArray[1].IsEmpty()
			OR Not ResultsArray[2].IsEmpty()
			OR Not ResultsArray[3].IsEmpty() Then
			DocumentObjectCashPayment = DocumentRefCashPayment.GetObject()
		EndIf;
		
		// Negative balance on cash.
		If Not ResultsArray[0].IsEmpty() Then
			QueryResultSelection = ResultsArray[0].Select();
			SmallBusinessServer.ShowMessageAboutPostingToCashAssetsRegisterErrors(DocumentObjectCashPayment, QueryResultSelection, Cancel);
		EndIf;
		
		// Negative balance on advance holder payments.
		If Not ResultsArray[1].IsEmpty() Then
			QueryResultSelection = ResultsArray[1].Select();
			SmallBusinessServer.ShowMessageAboutPostingToAdvanceHolderPaymentsRegisterErrors(DocumentObjectCashPayment, QueryResultSelection, Cancel);
		EndIf;
		
		// Negative balance on accounts payable.
		If Not ResultsArray[2].IsEmpty() Then
			QueryResultSelection = ResultsArray[2].Select();
			SmallBusinessServer.ShowMessageAboutPostingToAccountsPayableRegisterErrors(DocumentObjectCashPayment, QueryResultSelection, Cancel);
		EndIf;
		
		// Negative balance in cash CR.
		If Not ResultsArray[3].IsEmpty() Then
			QueryResultSelection = ResultsArray[3].Select();
			SmallBusinessServer.ErrorMessageOfPostingOnRegisterOfCashAtCashRegisters(DocumentObjectCashPayment, QueryResultSelection, Cancel);
		EndIf;
		
	EndIf;
	
EndProcedure // RunControl()

#Region PrintInterface

// Procedure forms and displays a printable document form by the specified layout.
//
// Parameters:
// SpreadsheetDocument - TabularDocument in which
// 			   printing form will be displayed.
//  TemplateName    - String, printing form layout name.
//
Function PrintForm(ObjectsArray, PrintObjects, TemplateName)
	
	Var Errors;
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersKey = "PrintParameters_CashPayment";
	
	FirstDocument = True;
	
	For Each CurrentDocument IN ObjectsArray Do
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		FirstDocument = False;
		
		FirstLineNumber = SpreadsheetDocument.TableHeight + 1;
		
		If TemplateName = "CashExpenseVoucher" Then
			Query = New Query();
			Query.SetParameter("CurrentDocument", CurrentDocument);
			
			Query.Text = 
			"SELECT
			|	CashPayment.Number AS DocumentNumber,
			|	CashPayment.Date AS DocumentDate,
			|	CashPayment.Company AS Company,
			|	CashPayment.Company.LegalEntityIndividual AS LegalEntityIndividual,
			|	CashPayment.Company.Prefix AS Prefix,
			|	CashPayment.Company.DescriptionFull AS CompanyPresentation,
			|	CashPayment.Issue AS Issue,
			|	CashPayment.Basis AS Basis,
			|	CashPayment.DocumentAmount AS DocumentAmount,
			|	CashPayment.ByDocument AS DocumentAttributesWhichIdentifiesPerson,
			|	CashPayment.PettyCash.GLAccount.Code AS CreditSubAccount,
			|	CashPayment.CashCurrency AS CashCurrency,
			|	CASE
			|		WHEN CashPayment.OperationKind = VALUE(Enum.OperationKindsCashPayment.ToCustomer)
			|				OR CashPayment.OperationKind = VALUE(Enum.OperationKindsCashPayment.Vendor)
			|				OR CashPayment.OperationKind = VALUE(Enum.OperationKindsCashPayment.OtherSettlements)
			|			THEN CashPayment.Counterparty.DescriptionFull
			|		WHEN CashPayment.OperationKind = VALUE(Enum.OperationKindsCashPayment.ToAdvanceHolder)
			|				OR CashPayment.OperationKind = VALUE(Enum.OperationKindsCashPayment.SalaryForEmployee)
			|			THEN CashPayment.AdvanceHolder.Description
			|		ELSE CashPayment.Issue
			|	END AS Recipient
			|FROM
			|	Document.CashPayment AS CashPayment
			|WHERE
			|	CashPayment.Ref = &CurrentDocument";
			
			Header = Query.Execute().Select();
			
			Header.Next();
			
			SpreadsheetDocument.PrintParametersKey = "PRINT_PARAMETERS_CashPayment_CashExpenseVoucher";
			Template = GetTemplate("PF_MXL_CashExpenseVoucher");
			
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
			
			InfoAboutCompany	= SmallBusinessServer.InfoAboutLegalEntityIndividual(Header.Company, Header.DocumentDate, ,);
			
			TemplateArea = Template.GetArea("HeaderPayer");
			
			TemplateArea.Parameters.Fill(Header);
			
			PayerPresentation	= SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCompany, "FullDescr");
			
			TemplateArea.Parameters.PayerPresentation	= PayerPresentation;
			TemplateArea.Parameters.PayerAddress		= SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCompany, "LegalAddress");
			TemplateArea.Parameters.PayerPhoneFax		= SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCompany, "PhoneNumbers,Fax");
			TemplateArea.Parameters.PayerEmail			= SmallBusinessServer.CompaniesDescriptionFull(InfoAboutCompany, "Email");
			
			SpreadsheetDocument.Put(TemplateArea);
			
			TemplateArea = Template.GetArea("HeaderRecipient");
			
			TemplateArea.Parameters.Recipient	= TrimAll(Header.Recipient);
			If ValueIsFilled(Header.Issue)
				And TrimAll(Header.Issue) <> TrimAll(Header.Recipient) Then
			
				TemplateArea.Parameters.Issue	= TrimAll(Header.Issue);
			
			EndIf;
			
			SpreadsheetDocument.Put(TemplateArea);
			
			TemplateArea = Template.GetArea("PaymentBasis");
			TemplateArea.Parameters.Fill(Header);
			SpreadsheetDocument.Put(TemplateArea);
			
			TemplateArea = Template.GetArea("TotalAmount");
			TemplateArea.Parameters.Total	= Format(Header.DocumentAmount,"NFD=2") + " " + Header.CashCurrency;
			SpreadsheetDocument.Put(TemplateArea);
			
			TemplateArea = Template.GetArea("Footer");
			SpreadsheetDocument.Put(TemplateArea);
		
		// 1C - CHIENTN - 27-12-2018
		ElsIf TemplateName = "CashPayment" Then 			
			GenerateCashPayment(SpreadsheetDocument, CurrentDocument);
		// 1C		
		EndIf; 

		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, FirstLineNumber, PrintObjects, CurrentDocument.Ref);
		
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
	
	If PrintManagement.NeedToPrintTemplate(PrintFormsCollection, "CashExpenseVoucher") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "CashExpenseVoucher", NStr("en='Debit slip';ru='Расходный кассовый ордер';vi='Phiếu chi'"), PrintForm(ObjectsArray, PrintObjects, "CashExpenseVoucher"));
		
	// 1C - CHIENTN - 27-12-2018
	ElsIf PrintManagement.NeedToPrintTemplate(PrintFormsCollection, "CashPayment") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "CashPayment", NStr("en='Cash payment (02-TT)';ru='Расходный кассовый ордер (02-TT)';vi='Phiếu chi (02-TT)'"), PrintForm(ObjectsArray, PrintObjects, "CashPayment"));
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
	PrintCommand.ID							= "CashPayment";
	PrintCommand.Presentation				= NStr("en='Cash payment (02-TT)';ru='Расходный кассовый ордер (02-TT)';vi='Phiếu chi (02-TT)'");
	PrintCommand.FormsList					= "DocumentForm,ListForm";
	PrintCommand.CheckPostingBeforePrint	= False;
	PrintCommand.Order						= 1;
	// 1C
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.ID							= "CashExpenseVoucher";
	PrintCommand.Presentation				= NStr("en='Debit slip';ru='Расходный кассовый ордер';vi='Phiếu chi'");
	PrintCommand.FormsList					= "DocumentForm,ListForm";
	PrintCommand.CheckPostingBeforePrint	= False;
	PrintCommand.Order						= 2;
	
EndProcedure

// Procedure of generating printed form Cash payment
// 1C - CHIENTN - 27-12-2018
Procedure GenerateCashPayment(SpreadsheetDocument, CurrentDocument)
			
	Query = New Query();
	Query.SetParameter("CurrentDocument", 	CurrentDocument);
	Query.SetParameter("DocumentDate", 		CurrentDocument.Date);
	Query.Text = 
	"SELECT
	|	Managerial.AccountDr AS AccountDr,
	|	Managerial.AccountCr AS AccountCr
	|FROM
	|	AccountingRegister.Managerial AS Managerial
	|WHERE
	|	Managerial.Active
	|	AND Managerial.Recorder = &CurrentDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CashPayment.Date AS DocumentDate,
	|	CashPayment.Number AS Number,
	|	CashPayment.Company AS Company,
	|	CashPayment.Company.Prefix AS Prefix,
	|	CashPayment.Department AS Department,
	|	CashPayment.DocumentAmount AS Amount,
	|	CashPayment.CashCurrency AS CashCurrency,
	|	CashPayment.Counterparty AS Counterparty,
	|	CashPayment.Issue AS Issue,
	|	CashPayment.Author AS Author,
	|	CashPayment.Comment AS Reason,
	|	CashPayment.Application AS Attachments,
	|	CurrencyRatesSliceLast.ExchangeRate AS ExchangeRate,
	|	ISNULL(CurrencyRatesSliceLast.ExchangeRate, 0) * CashPayment.DocumentAmount AS ExchangeAmount
	|FROM
	|	Document.CashPayment AS CashPayment
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(&DocumentDate, ) AS CurrencyRatesSliceLast
	|		ON CashPayment.CashCurrency = CurrencyRatesSliceLast.Currency
	|WHERE
	|	CashPayment.Ref = &CurrentDocument";
	
	Results = Query.ExecuteBatch();
	AccountSelection 	= Results[0].Select();
	Selection 			= Results[1].Select();
	Selection.Next(); 	
					
	SpreadsheetDocument.PrintParametersName = "PRINT_PARAMETERS_PF_MXL_CashPayment_02TT"; 	
	Template = PrintManagement.GetTemplate("CommonTemplate.PF_MXL_CashPayment_02TT");
	Copy = 2;
	If Copy = 1 Then
		TemplateArea = Template.GetArea("_1Copy");
		SpreadsheetDocument.TopMargin 		= 10;
		SpreadsheetDocument.BottomMargin 	= 10;
	ElsIf Copy = 2 Then
		TemplateArea = Template.GetArea("_2Copy");
		SpreadsheetDocument.TopMargin 		= 0;
		SpreadsheetDocument.BottomMargin 	= 0;
	ElsIf Copy = 3 Then
		TemplateArea = Template.GetArea("_3Copy");
		SpreadsheetDocument.TopMargin 		= 0;
		SpreadsheetDocument.BottomMargin 	= 0;
	EndIf;

	InfoAboutCompany 		= SmallBusinessServer.InfoAboutLegalEntityIndividual(Selection.Company, Selection.DocumentDate, ,);
	InfoAboutCounterparty 	= SmallBusinessServer.InfoAboutLegalEntityIndividual(Selection.Counterparty, Selection.DocumentDate, ,);
	ResponsiblePersons 		= SmallBusinessServer.OrganizationalUnitsResponsiblePersons(Selection.Company, Selection.DocumentDate);

	AccountsDr 	= "";
	AccountsCr 	= "";
	While AccountSelection.Next() Do
		AccountDrCode = TrimAll(String(AccountSelection.AccountDr.Code));
		AccountsDr = StrReplace(AccountsDr, AccountDrCode, "");
		AccountsDr = AccountsDr + ?(IsBlankString(AccountsDr), "", ";") + AccountDrCode;
		
		AccountCrCode = TrimAll(String(AccountSelection.AccountCr.Code));
		AccountsCr = StrReplace(AccountsCr, AccountCrCode, "");
		AccountsCr = AccountsCr + ?(IsBlankString(AccountsCr), "", ";") + AccountCrCode;
	EndDo;

	FillStructureSection = New Structure();
	FillStructureSection.Insert("Date", 	SmallBusinessServer.GetFormatingDateByLanguageForPrinting(Selection.DocumentDate));  
	FillStructureSection.Insert("Company", 	InfoAboutCompany.FullDescr);
	FillStructureSection.Insert("Address", 	InfoAboutCompany.LegalAddress);
	FillStructureSection.Insert("Telephone",InfoAboutCompany.PhoneNumbers); 	
	FillStructureSection.Insert("AddressOfIssue", 	InfoAboutCounterparty.LegalAddress);		
	FillStructureSection.Insert("AmountInWords", 	WorkWithCurrencyRates.GenerateAmountInWords(Selection.Amount, Selection.CashCurrency)); 
	FillStructureSection.Insert("AccountsDr", 	AccountsDr); 	
	FillStructureSection.Insert("AccountsCr",	AccountsCr); 	

	TemplateArea.Parameters.Fill(Selection); 
	TemplateArea.Parameters.Fill(FillStructureSection); 
	TemplateArea.Parameters.Fill(ResponsiblePersons);
	SpreadsheetDocument.Put(TemplateArea);					
		
EndProcedure // GenerateCashPayment()

#EndRegion

#Region OtherSettlements

Procedure GenerateTableSettlementsWithOtherCounterparties(DocumentRefCashPayment, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	
	Query.SetParameter("Company",						StructureAdditionalProperties.ForPosting.Company);
	Query.SetParameter("AccountingForOtherOperations",	NStr("en='Accounting for other operations';ru='Учет расчетов по прочим операциям';vi='Kế toán hạch toán theo các giao dịch khác'",	Metadata.DefaultLanguage.LanguageCode));
	Query.SetParameter("Comment",						NStr("en='Increase in counterparty debt';ru='Увеличение долга контрагента';vi='Tăng nợ của đối tác'", Metadata.DefaultLanguage.LanguageCode));
	Query.SetParameter("Ref",							DocumentRefCashPayment);
	Query.SetParameter("PointInTime",					New Boundary(StructureAdditionalProperties.ForPosting.PointInTime, BoundaryType.Including));
	Query.SetParameter("ControlPeriod",					StructureAdditionalProperties.ForPosting.PointInTime.Date);
	Query.SetParameter("ExchangeRateDifference",		NStr("en='Exchange rate difference';ru='Курсовая разница';vi='Chênh lệch tỷ giá'", Metadata.DefaultLanguage.LanguageCode));
	
	Query.Text =
	"SELECT
	|	TemporaryTablePaymentDetails.LineNumber AS LineNumber,
	|	&Company AS Company,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TemporaryTablePaymentDetails.Counterparty AS Counterparty,
	|	TemporaryTablePaymentDetails.Contract AS Contract,
	|	CASE
	|		WHEN TemporaryTablePaymentDetails.DoOperationsByDocuments
	|			THEN CASE
	|					WHEN TemporaryTablePaymentDetails.Document = VALUE(Document.CustomerOrder.EmptyRef)
	|							OR TemporaryTablePaymentDetails.Document = VALUE(Document.PurchaseOrder.EmptyRef)
	|							OR TemporaryTablePaymentDetails.Document = UNDEFINED
	|						THEN &Ref
	|					ELSE TemporaryTablePaymentDetails.Document
	|				END
	|		ELSE UNDEFINED
	|	END AS Document,
	|	CASE
	|		WHEN TemporaryTablePaymentDetails.DoOperationsByOrders
	|			THEN TemporaryTablePaymentDetails.Order
	|		ELSE VALUE(Document.CustomerOrder.EmptyRef)
	|	END AS Order,
	|	TemporaryTablePaymentDetails.SettlementsCurrency AS Currency,
	|	TemporaryTableHeader.CashCurrency AS CashCurrency,
	|	TemporaryTablePaymentDetails.Date AS Date,
	|	SUM(TemporaryTablePaymentDetails.PaymentAmount) AS PaymentAmount,
	|	SUM(TemporaryTablePaymentDetails.AccountingAmount) AS Amount,
	|	SUM(TemporaryTablePaymentDetails.SettlementsAmount) AS AmountCur,
	|	SUM(TemporaryTablePaymentDetails.AccountingAmount) AS AmountForBalance,
	|	SUM(TemporaryTablePaymentDetails.SettlementsAmount) AS AmountCurForBalance,
	|	&AccountingForOtherOperations AS ContentOfAccountingRecord,
	|	&Comment AS Comment,
	|	TemporaryTableHeader.Correspondence AS GLAccount,
	|	TemporaryTableHeader.PettyCash AS PettyCash,
	|	TemporaryTablePaymentDetails.Date AS Period
	|INTO TemporaryTableOtherSettlements
	|FROM
	|	TemporaryTablePaymentDetails AS TemporaryTablePaymentDetails
	|		INNER JOIN TemporaryTableHeader AS TemporaryTableHeader
	|		ON (TemporaryTableHeader.AccountingOtherSettlements)
	|WHERE
	|	TemporaryTablePaymentDetails.OperationKind = VALUE(Enum.OperationKindsCashPayment.OtherSettlements)
	|
	|GROUP BY
	|	TemporaryTablePaymentDetails.LineNumber,
	|	TemporaryTablePaymentDetails.Counterparty,
	|	TemporaryTablePaymentDetails.Contract,
	|	TemporaryTablePaymentDetails.SettlementsCurrency,
	|	TemporaryTableHeader.CashCurrency,
	|	TemporaryTablePaymentDetails.Date,
	|	CASE
	|		WHEN TemporaryTablePaymentDetails.DoOperationsByDocuments
	|			THEN CASE
	|					WHEN TemporaryTablePaymentDetails.Document = VALUE(Document.CustomerOrder.EmptyRef)
	|							OR TemporaryTablePaymentDetails.Document = VALUE(Document.PurchaseOrder.EmptyRef)
	|							OR TemporaryTablePaymentDetails.Document = UNDEFINED
	|						THEN &Ref
	|					ELSE TemporaryTablePaymentDetails.Document
	|				END
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN TemporaryTablePaymentDetails.DoOperationsByOrders
	|			THEN TemporaryTablePaymentDetails.Order
	|		ELSE VALUE(Document.CustomerOrder.EmptyRef)
	|	END,
	|	TemporaryTableHeader.Correspondence,
	|	TemporaryTableHeader.PettyCash,
	|	TemporaryTablePaymentDetails.Date";
	
	QueryResult = Query.Execute();
	
	Query.Text =
	"SELECT
	|	TemporaryTableOtherSettlements.GLAccount AS GLAccount,
	|	TemporaryTableOtherSettlements.Company AS Company,
	|	TemporaryTableOtherSettlements.Counterparty AS Counterparty,
	|	TemporaryTableOtherSettlements.Contract AS Contract
	|FROM
	|	TemporaryTableOtherSettlements AS TemporaryTableOtherSettlements";
	
	QueryResult = Query.Execute();
	
	DataLock 			= New DataLock;
	LockItem 			= DataLock.Add("AccumulationRegister.SettlementsWithOtherCounterparties");
	LockItem.Mode 		= DataLockMode.Exclusive;
	LockItem.DataSource	= QueryResult;
	
	For Each QueryResultColumn IN QueryResult.Columns Do
		LockItem.UseFromDataSource(QueryResultColumn.Name, QueryResultColumn.Name);
	EndDo;
	DataLock.Lock();
	
	QueryNumber = 0;
	
	Query.Text = SmallBusinessServer.GetQueryTextExchangeRateDifferencesAccountingForOtherOperations(Query.TempTablesManager, QueryNumber);
	ResultsArray = Query.ExecuteBatch();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableSettlementsWithOtherCounterparties", ResultsArray[QueryNumber].Unload());
	
EndProcedure // GenerateTableSettlementsWithOtherCounterparties()

#EndRegion

#EndIf

