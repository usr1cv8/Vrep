#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

// Initializes the tables of values that contain the data of the document table sections.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure InitializeDocumentData(DocumentRefPayroll, StructureAdditionalProperties) Export
	
	Query = New Query(
	"SELECT
	|	&Company AS Company,
	|	PayrollAccrualRetention.LineNumber AS LineNumber,
	|	PayrollAccrualRetention.Ref.Date AS Period,
	|	PayrollAccrualRetention.Ref.RegistrationPeriod AS RegistrationPeriod,
	|	PayrollAccrualRetention.Ref.DocumentCurrency AS Currency,
	|	PayrollAccrualRetention.Ref.StructuralUnit AS StructuralUnit,
	|	PayrollAccrualRetention.Employee AS Employee,
	|	PayrollAccrualRetention.GLExpenseAccount AS GLExpenseAccount,
	|	PayrollAccrualRetention.CustomerOrder AS CustomerOrder,
	|	PayrollAccrualRetention.BusinessActivity AS BusinessActivity,
	|	PayrollAccrualRetention.StartDate AS StartDate,
	|	PayrollAccrualRetention.EndDate AS EndDate,
	|	PayrollAccrualRetention.DaysWorked AS DaysWorked,
	|	PayrollAccrualRetention.HoursWorked AS HoursWorked,
	|	PayrollAccrualRetention.Size AS Size,
	|	PayrollAccrualRetention.AccrualDeductionKind AS AccrualDeductionKind,
	|	CAST(PayrollAccrualRetention.Amount * SettlementsCurrencyRates.ExchangeRate * AccountingCurrencyRates.Multiplicity / (AccountingCurrencyRates.ExchangeRate * SettlementsCurrencyRates.Multiplicity) AS NUMBER(15, 2)) AS Amount,
	|	PayrollAccrualRetention.Amount AS AmountCur
	|INTO TableAccrual
	|FROM
	|	Document.Payroll.AccrualsDeductions AS PayrollAccrualRetention
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
	|				&PointInTime,
	|				Currency In
	|					(SELECT
	|						Constants.AccountingCurrency
	|					FROM
	|						Constants AS Constants)) AS AccountingCurrencyRates
	|		ON (TRUE)
	|		LEFT JOIN Constants AS Constants
	|		ON (TRUE)
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(&PointInTime, ) AS SettlementsCurrencyRates
	|		ON PayrollAccrualRetention.Ref.DocumentCurrency = SettlementsCurrencyRates.Currency
	|WHERE
	|	PayrollAccrualRetention.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	&Company,
	|	PayrollAccrualRetention.LineNumber,
	|	PayrollAccrualRetention.Ref.Date,
	|	PayrollAccrualRetention.Ref.RegistrationPeriod,
	|	PayrollAccrualRetention.Ref.DocumentCurrency,
	|	PayrollAccrualRetention.Ref.StructuralUnit,
	|	PayrollAccrualRetention.Employee,
	|	PayrollAccrualRetention.AccrualDeductionKind.TaxKind.GLAccount,
	|	VALUE(Document.CustomerOrder.EmptyRef),
	|	VALUE(Catalog.BusinessActivities.EmptyRef),
	|	PayrollAccrualRetention.Ref.RegistrationPeriod,
	|	ENDOFPERIOD(PayrollAccrualRetention.Ref.RegistrationPeriod, MONTH),
	|	0,
	|	0,
	|	0,
	|	PayrollAccrualRetention.AccrualDeductionKind,
	|	CAST(PayrollAccrualRetention.Amount * SettlementsCurrencyRates.ExchangeRate * AccountingCurrencyRates.Multiplicity / (AccountingCurrencyRates.ExchangeRate * SettlementsCurrencyRates.Multiplicity) AS NUMBER(15, 2)),
	|	PayrollAccrualRetention.Amount
	|FROM
	|	Document.Payroll.IncomeTaxes AS PayrollAccrualRetention
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
	|				&PointInTime,
	|				Currency In
	|					(SELECT
	|						Constants.AccountingCurrency
	|					FROM
	|						Constants AS Constants)) AS AccountingCurrencyRates
	|		ON (TRUE)
	|		LEFT JOIN Constants AS Constants
	|		ON (TRUE)
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(&PointInTime, ) AS SettlementsCurrencyRates
	|		ON PayrollAccrualRetention.Ref.DocumentCurrency = SettlementsCurrencyRates.Currency
	|WHERE
	|	PayrollAccrualRetention.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&Company AS Company,
	|	PayrollAccrualRetention.Period AS Period,
	|	PayrollAccrualRetention.RegistrationPeriod AS RegistrationPeriod,
	|	PayrollAccrualRetention.Currency AS Currency,
	|	PayrollAccrualRetention.StructuralUnit AS StructuralUnit,
	|	PayrollAccrualRetention.Employee AS Employee,
	|	PayrollAccrualRetention.StartDate AS StartDate,
	|	PayrollAccrualRetention.EndDate AS EndDate,
	|	PayrollAccrualRetention.DaysWorked AS DaysWorked,
	|	PayrollAccrualRetention.HoursWorked AS HoursWorked,
	|	PayrollAccrualRetention.Size AS Size,
	|	PayrollAccrualRetention.AccrualDeductionKind AS AccrualDeductionKind,
	|	PayrollAccrualRetention.Amount AS Amount,
	|	PayrollAccrualRetention.AmountCur AS AmountCur
	|FROM
	|	TableAccrual AS PayrollAccrualRetention
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&Company AS Company,
	|	PayrollAccrualRetention.Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	PayrollAccrualRetention.RegistrationPeriod AS RegistrationPeriod,
	|	PayrollAccrualRetention.Currency AS Currency,
	|	PayrollAccrualRetention.StructuralUnit AS StructuralUnit,
	|	PayrollAccrualRetention.Employee AS Employee,
	|	CASE
	|		WHEN PayrollAccrualRetention.AccrualDeductionKind.Type = VALUE(Enum.AccrualAndDeductionTypes.Accrual)
	|			THEN PayrollAccrualRetention.AmountCur
	|		ELSE -1 * PayrollAccrualRetention.AmountCur
	|	END AS AmountCur,
	|	CASE
	|		WHEN PayrollAccrualRetention.AccrualDeductionKind.Type = VALUE(Enum.AccrualAndDeductionTypes.Accrual)
	|			THEN PayrollAccrualRetention.Amount
	|		ELSE -1 * PayrollAccrualRetention.Amount
	|	END AS Amount,
	|	PayrollAccrualRetention.Employee.SettlementsHumanResourcesGLAccount AS GLAccount,
	|	VALUE(AccountingRecordType.Credit) AS RecordKindManagerial,
	|	CASE
	|		WHEN PayrollAccrualRetention.AccrualDeductionKind.Type = VALUE(Enum.AccrualAndDeductionTypes.Tax)
	|			THEN &AddedTax
	|		ELSE &Payroll
	|	END AS ContentOfAccountingRecord
	|FROM
	|	TableAccrual AS PayrollAccrualRetention
	|WHERE
	|	PayrollAccrualRetention.AmountCur <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PayrollAccrualRetention.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	PayrollAccrualRetention.RegistrationPeriod AS Period,
	|	&Company AS Company,
	|	PayrollAccrualRetention.StructuralUnit AS StructuralUnit,
	|	PayrollAccrualRetention.GLExpenseAccount AS GLExpenseAccount,
	|	PayrollAccrualRetention.GLExpenseAccount AS GLAccount,
	|	PayrollAccrualRetention.CustomerOrder AS CustomerOrder,
	|	CASE
	|		WHEN PayrollAccrualRetention.AccrualDeductionKind.Type = VALUE(Enum.AccrualAndDeductionTypes.Deduction)
	|			THEN -1 * PayrollAccrualRetention.Amount
	|		ELSE PayrollAccrualRetention.Amount
	|	END AS Amount,
	|	VALUE(AccountingRecordType.Debit) AS RecordKindManagerial,
	|	TRUE AS FixedCost,
	|	&Payroll AS ContentOfAccountingRecord
	|FROM
	|	TableAccrual AS PayrollAccrualRetention
	|WHERE
	|	PayrollAccrualRetention.AccrualDeductionKind.Type <> VALUE(Enum.AccrualAndDeductionTypes.Tax)
	|	AND (PayrollAccrualRetention.GLExpenseAccount.TypeOfAccount = VALUE(Enum.GLAccountsTypes.UnfinishedProduction)
	|			OR PayrollAccrualRetention.GLExpenseAccount.TypeOfAccount = VALUE(Enum.GLAccountsTypes.IndirectExpenses))
	|	AND PayrollAccrualRetention.AmountCur <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PayrollAccrualRetention.LineNumber AS LineNumber,
	|	PayrollAccrualRetention.RegistrationPeriod AS Period,
	|	&Company AS Company,
	|	CASE
	|		WHEN PayrollAccrualRetention.GLExpenseAccount.TypeOfAccount = VALUE(Enum.GLAccountsTypes.Expenses)
	|			THEN PayrollAccrualRetention.BusinessActivity
	|		ELSE VALUE(Catalog.BusinessActivities.Other)
	|	END AS BusinessActivity,
	|	CASE
	|		WHEN PayrollAccrualRetention.GLExpenseAccount.TypeOfAccount = VALUE(Enum.GLAccountsTypes.Expenses)
	|			THEN PayrollAccrualRetention.StructuralUnit
	|		ELSE UNDEFINED
	|	END AS StructuralUnit,
	|	PayrollAccrualRetention.GLExpenseAccount AS GLAccount,
	|	PayrollAccrualRetention.GLExpenseAccount AS GLExpenseAccount,
	|	CASE
	|		WHEN PayrollAccrualRetention.AccrualDeductionKind.Type = VALUE(Enum.AccrualAndDeductionTypes.Accrual)
	|			THEN PayrollAccrualRetention.Amount
	|		ELSE 0
	|	END AS AmountExpense,
	|	CASE
	|		WHEN PayrollAccrualRetention.AccrualDeductionKind.Type = VALUE(Enum.AccrualAndDeductionTypes.Deduction)
	|			THEN PayrollAccrualRetention.Amount
	|		ELSE 0
	|	END AS AmountIncome,
	|	CASE
	|		WHEN PayrollAccrualRetention.AccrualDeductionKind.Type = VALUE(Enum.AccrualAndDeductionTypes.Deduction)
	|			THEN -1 * PayrollAccrualRetention.Amount
	|		ELSE PayrollAccrualRetention.Amount
	|	END AS Amount,
	|	CASE
	|		WHEN PayrollAccrualRetention.GLExpenseAccount.TypeOfAccount = VALUE(Enum.GLAccountsTypes.Expenses)
	|			THEN PayrollAccrualRetention.CustomerOrder
	|		ELSE UNDEFINED
	|	END AS CustomerOrder,
	|	VALUE(AccountingRecordType.Debit) AS RecordKindManagerial,
	|	&Payroll AS ContentOfAccountingRecord
	|FROM
	|	TableAccrual AS PayrollAccrualRetention
	|WHERE
	|	PayrollAccrualRetention.AccrualDeductionKind.Type <> VALUE(Enum.AccrualAndDeductionTypes.Tax)
	|	AND PayrollAccrualRetention.GLExpenseAccount.TypeOfAccount IN (VALUE(Enum.GLAccountsTypes.Expenses), VALUE(Enum.GLAccountsTypes.OtherExpenses), VALUE(Enum.GLAccountsTypes.Incomings), VALUE(Enum.GLAccountsTypes.OtherIncome))
	|	AND PayrollAccrualRetention.AmountCur <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&Company AS Company,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	PayrollAccrualRetention.RegistrationPeriod AS Period,
	|	PayrollAccrualRetention.AccrualDeductionKind.TaxKind AS TaxKind,
	|	PayrollAccrualRetention.AccrualDeductionKind.TaxKind.GLAccount AS GLAccount,
	|	PayrollAccrualRetention.Amount,
	|	&AddedTax AS ContentOfAccountingRecord
	|FROM
	|	TableAccrual AS PayrollAccrualRetention
	|WHERE
	|	PayrollAccrualRetention.AccrualDeductionKind.Type = VALUE(Enum.AccrualAndDeductionTypes.Tax)
	|	AND PayrollAccrualRetention.AmountCur <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PayrollAccrualRetention.LineNumber AS LineNumber,
	|	PayrollAccrualRetention.RegistrationPeriod AS Period,
	|	&Company AS Company,
	|	VALUE(Catalog.PlanningPeriods.Actual) AS PlanningPeriod,
	|	CASE
	|		WHEN PayrollAccrualRetention.AccrualDeductionKind.Type = VALUE(Enum.AccrualAndDeductionTypes.Accrual)
	|			THEN PayrollAccrualRetention.GLExpenseAccount
	|		ELSE PayrollAccrualRetention.Employee.SettlementsHumanResourcesGLAccount
	|	END AS AccountDr,
	|	CASE
	|		WHEN (PayrollAccrualRetention.AccrualDeductionKind.Type = VALUE(Enum.AccrualAndDeductionTypes.Deduction)
	|					OR PayrollAccrualRetention.AccrualDeductionKind.Type = VALUE(Enum.AccrualAndDeductionTypes.Tax))
	|					AND PayrollAccrualRetention.Employee.SettlementsHumanResourcesGLAccount.Currency
	|				OR PayrollAccrualRetention.AccrualDeductionKind.Type = VALUE(Enum.AccrualAndDeductionTypes.Accrual)
	|					AND PayrollAccrualRetention.GLExpenseAccount.Currency
	|			THEN PayrollAccrualRetention.Currency
	|		ELSE UNDEFINED
	|	END AS CurrencyDr,
	|	CASE
	|		WHEN (PayrollAccrualRetention.AccrualDeductionKind.Type = VALUE(Enum.AccrualAndDeductionTypes.Deduction)
	|					OR PayrollAccrualRetention.AccrualDeductionKind.Type = VALUE(Enum.AccrualAndDeductionTypes.Tax))
	|					AND PayrollAccrualRetention.Employee.SettlementsHumanResourcesGLAccount.Currency
	|				OR PayrollAccrualRetention.AccrualDeductionKind.Type = VALUE(Enum.AccrualAndDeductionTypes.Accrual)
	|					AND PayrollAccrualRetention.GLExpenseAccount.Currency
	|			THEN PayrollAccrualRetention.AmountCur
	|		ELSE 0
	|	END AS AmountCurDr,
	|	CASE
	|		WHEN PayrollAccrualRetention.AccrualDeductionKind.Type = VALUE(Enum.AccrualAndDeductionTypes.Accrual)
	|			THEN PayrollAccrualRetention.Employee.SettlementsHumanResourcesGLAccount
	|		ELSE PayrollAccrualRetention.GLExpenseAccount
	|	END AS AccountCr,
	|	CASE
	|		WHEN (PayrollAccrualRetention.AccrualDeductionKind.Type = VALUE(Enum.AccrualAndDeductionTypes.Deduction)
	|					OR PayrollAccrualRetention.AccrualDeductionKind.Type = VALUE(Enum.AccrualAndDeductionTypes.Tax))
	|					AND PayrollAccrualRetention.GLExpenseAccount.Currency
	|				OR PayrollAccrualRetention.AccrualDeductionKind.Type = VALUE(Enum.AccrualAndDeductionTypes.Accrual)
	|					AND PayrollAccrualRetention.Employee.SettlementsHumanResourcesGLAccount.Currency
	|			THEN PayrollAccrualRetention.Currency
	|		ELSE UNDEFINED
	|	END AS CurrencyCr,
	|	CASE
	|		WHEN (PayrollAccrualRetention.AccrualDeductionKind.Type = VALUE(Enum.AccrualAndDeductionTypes.Deduction)
	|					OR PayrollAccrualRetention.AccrualDeductionKind.Type = VALUE(Enum.AccrualAndDeductionTypes.Tax))
	|					AND PayrollAccrualRetention.GLExpenseAccount.Currency
	|				OR PayrollAccrualRetention.AccrualDeductionKind.Type = VALUE(Enum.AccrualAndDeductionTypes.Accrual)
	|					AND PayrollAccrualRetention.Employee.SettlementsHumanResourcesGLAccount.Currency
	|			THEN PayrollAccrualRetention.AmountCur
	|		ELSE 0
	|	END AS AmountCurCr,
	|	PayrollAccrualRetention.Amount AS Amount,
	|	CASE
	|		WHEN PayrollAccrualRetention.AccrualDeductionKind.Type = VALUE(Enum.AccrualAndDeductionTypes.Tax)
	|			THEN &AddedTax
	|		ELSE &Payroll
	|	END AS Content
	|FROM
	|	TableAccrual AS PayrollAccrualRetention
	|WHERE
	|	PayrollAccrualRetention.AmountCur <> 0");
	
	Query.SetParameter("Ref", DocumentRefPayroll);
	Query.SetParameter("PointInTime", New Boundary(StructureAdditionalProperties.ForPosting.PointInTime, BoundaryType.Including));
	Query.SetParameter("Company", StructureAdditionalProperties.ForPosting.Company);
	Query.SetParameter("Payroll", NStr("en='Payroll';ru='Начисление зарплаты';vi='Trả lương'"));
	Query.SetParameter("AddedTax", NStr("en='Tax accrued';ru='Начисленные налоги';vi='Thuế đã tính'"));
	    	
	ResultsArray = Query.ExecuteBatch();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableAccrualsAndDeductions", ResultsArray[1].Unload());
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TablePayrollPayments", ResultsArray[2].Unload());
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableInventory", ResultsArray[3].Unload());
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableIncomeAndExpenses", ResultsArray[4].Unload());
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableTaxAccounting", ResultsArray[5].Unload());
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableManagerial", ResultsArray[6].Unload());
	
	//Other settlements
	GenerateTableLoanSettlements(DocumentRefPayroll, StructureAdditionalProperties);
	GenerateTableAccountOfLoans(DocumentRefPayroll, StructureAdditionalProperties);
	//End Other settlements
	
EndProcedure // DocumentDataInitialization()

// Controls the occurrence of negative balances.
//
Procedure RunControl(DocumentRefPayroll, AdditionalProperties, Cancel, PostingDelete = False) Export
	
	If Not SmallBusinessServer.RunBalanceControl() Then
		Return;
	EndIf;

	StructureTemporaryTables = AdditionalProperties.ForPosting.StructureTemporaryTables;
	
EndProcedure

#Region PrintInterface

// Fills in the list of printing commands.
// 
// Parameters:
//   PrintCommands - ValueTable - see fields' content in the PrintManagement.CreatePrintCommandsCollection function.
//
Procedure AddPrintCommands(PrintCommands) Export
	
	
	
EndProcedure

#EndRegion

#Region LoanSettlements

Procedure GenerateTableLoanSettlements(DocumentRefPayroll, StructureAdditionalProperties)

	If DocumentRefPayroll.LoanRepayment.Count() = 0 Then
		StructureAdditionalProperties.TableForRegisterRecords.Insert("TableLoanSettlements", New ValueTable);
		Return;
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	
	Query.SetParameter("Company", 					StructureAdditionalProperties.ForPosting.Company);
	Query.SetParameter("InterestOfAccrualOnLoan",	NStr("en='Interest of accrual on loan';ru='Начисление процентов по займу';vi='Tính lãi theo khoản vay'"));
	Query.SetParameter("InterestOfChargeOnLoan",	NStr("en='Interest of charge on loan';ru='Удержание процентов по займу';vi='Giữ lại lãi theo khoản nợ'"));
	Query.SetParameter("PrincipalOfChargeOnLoan",	NStr("en='Principal of charge on loan';ru='Удержание основного долга по займу';vi='Giữ lại nợ chính theo khoản nợ'"));
	Query.SetParameter("Ref", 						DocumentRefPayroll);
	Query.SetParameter("PointInTime", 				New Boundary(StructureAdditionalProperties.ForPosting.PointInTime,BoundaryType.Including));
	Query.SetParameter("ControlPeriod", 			StructureAdditionalProperties.ForPosting.PointInTime.Date);
	Query.SetParameter("ExchangeRateDifference", 		NStr("en='Exchange difference';ru='Курсовая разница';vi='Chênh lệch tỷ giá'"));
	
	Query.SetParameter("AccountingCurrency", 		Constants.NationalCurrency.Get());
	Query.SetParameter("CurrencyDR", 				DocumentRefPayroll.DocumentCurrency);
	
	Query.Text = 
	"SELECT
	|	&Company,
	|	PayrollLoanRepayment.LineNumber,
	|	PayrollLoanRepayment.Ref,
	|	PayrollLoanRepayment.Ref.Date AS Period,
	|	PayrollLoanRepayment.Ref.StructuralUnit,
	|	PayrollLoanRepayment.Ref.RegistrationPeriod,
	|	PayrollLoanRepayment.Ref.DocumentCurrency AS Currency,
	|	PayrollLoanRepayment.Employee,
	|	PayrollLoanRepayment.Employee.SettlementsHumanResourcesGLAccount AS SettlementsHumanResourcesGLAccount,
	|	PayrollLoanRepayment.LoanContract,
	|	PayrollLoanRepayment.LoanContract.GLAccount AS GLAccountLoanContract,
	|	PayrollLoanRepayment.LoanContract.SettlementsCurrency AS CurrencyLoanContract,
	|	PayrollLoanRepayment.LoanContract.InterestGLAccount AS InterestGLAccount,
	|	PayrollLoanRepayment.LoanContract.CostAccount AS CostAccount,
	|	PayrollLoanRepayment.LoanContract.BusinessArea AS BusinessArea,
	|	PayrollLoanRepayment.PrincipalCharged + PayrollLoanRepayment.InterestCharged AS AmountCur,
	|	CAST((PayrollLoanRepayment.PrincipalCharged + PayrollLoanRepayment.InterestCharged) * SettlementsCurrencyRates.ExchangeRate * AcoountCurrencyRates.Multiplicity / (AcoountCurrencyRates.ExchangeRate * SettlementsCurrencyRates.Multiplicity) AS NUMBER(15, 2)) AS Amount,
	|	CAST((PayrollLoanRepayment.PrincipalCharged + PayrollLoanRepayment.InterestCharged) * SettlementsCurrencyRates.ExchangeRate * LoanContractCurrencyRates.Multiplicity / (LoanContractCurrencyRates.ExchangeRate * SettlementsCurrencyRates.Multiplicity) AS NUMBER(15, 2)) AS ContractAmountCur,
	|	PayrollLoanRepayment.PrincipalCharged AS PrincipalChargedCur,
	|	CAST(PayrollLoanRepayment.PrincipalCharged * SettlementsCurrencyRates.ExchangeRate * AcoountCurrencyRates.Multiplicity / (AcoountCurrencyRates.ExchangeRate * SettlementsCurrencyRates.Multiplicity) AS NUMBER(15, 2)) AS PrincipalCharged,
	|	CAST(PayrollLoanRepayment.PrincipalCharged * LoanContractCurrencyRates.ExchangeRate * AcoountCurrencyRates.Multiplicity / (AcoountCurrencyRates.ExchangeRate * LoanContractCurrencyRates.Multiplicity) AS NUMBER(15, 2)) AS ContractPrincipalChargedCur,
	|	PayrollLoanRepayment.InterestCharged AS InterestChargedCur,
	|	CAST(PayrollLoanRepayment.InterestCharged * SettlementsCurrencyRates.ExchangeRate * AcoountCurrencyRates.Multiplicity / (AcoountCurrencyRates.ExchangeRate * SettlementsCurrencyRates.Multiplicity) AS NUMBER(15, 2)) AS InterestCharged,
	|	CAST(PayrollLoanRepayment.InterestCharged * LoanContractCurrencyRates.ExchangeRate * AcoountCurrencyRates.Multiplicity / (AcoountCurrencyRates.ExchangeRate * LoanContractCurrencyRates.Multiplicity) AS NUMBER(15, 2)) AS ContractInterestChargedCur,
	|	PayrollLoanRepayment.InterestAccrued AS InterestAccruedCur,
	|	CAST(PayrollLoanRepayment.InterestAccrued * SettlementsCurrencyRates.ExchangeRate * AcoountCurrencyRates.Multiplicity / (AcoountCurrencyRates.ExchangeRate * SettlementsCurrencyRates.Multiplicity) AS NUMBER(15, 2)) AS InterestAccrued,
	|	CAST(PayrollLoanRepayment.InterestAccrued * LoanContractCurrencyRates.ExchangeRate * AcoountCurrencyRates.Multiplicity / (AcoountCurrencyRates.ExchangeRate * LoanContractCurrencyRates.Multiplicity) AS NUMBER(15, 2)) AS ContractInterestAccruedCur
	|INTO TableLoans
	|FROM
	|	Document.Payroll.LoanRepayment AS PayrollLoanRepayment
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
	|				&PointInTime,
	|				Currency IN
	|					(SELECT
	|						Constants.NationalCurrency
	|					FROM
	|						Constants AS Constants)) AS AcoountCurrencyRates
	|		ON (TRUE)
	|		LEFT JOIN Constants AS Constants
	|		ON (TRUE)
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(&PointInTime, ) AS SettlementsCurrencyRates
	|		ON PayrollLoanRepayment.Ref.DocumentCurrency = SettlementsCurrencyRates.Currency
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(&PointInTime, ) AS LoanContractCurrencyRates
	|		ON PayrollLoanRepayment.LoanContract.SettlementsCurrency = LoanContractCurrencyRates.Currency
	|WHERE
	|	PayrollLoanRepayment.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&Company,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	TableLoans.Period AS Date,
	|	TableLoans.Period AS Period,
	|	&PrincipalOfChargeOnLoan AS ContentOfAccountingRecord,
	|	TableLoans.Employee AS Counterparty,
	|	TableLoans.ContractPrincipalChargedCur AS PrincipalDebtCur,
	|	TableLoans.PrincipalCharged AS PrincipalDebt,
	|	TableLoans.ContractPrincipalChargedCur AS PrincipalChargedCurForBalance,
	|	TableLoans.PrincipalCharged AS PrincipalChargedForBalance,
	|	0 AS InterestCur,
	|	0 AS Interest,
	|	0 AS InterestCurForBalance,
	|	0 AS InterestForBalance,
	|	0 AS CommissionCur,
	|	0 AS Commission,
	|	0 AS CommissionCurForBalance,
	|	0 AS CommissionForBalance,
	|	TableLoans.LoanContract AS LoanContract,
	|	TableLoans.Currency,
	|	TableLoans.GLAccountLoanContract AS GLAccount,
	|	TRUE AS DeductedFromSalary,
	|	TableLoans.LoanContract.LoanKind AS LoanKind,
	|	TableLoans.StructuralUnit,
	|	TableLoans.ContractPrincipalChargedCur AS AmountCur,
	|	TableLoans.PrincipalCharged AS Amount
	|INTO TemporaryTableLoanSettlements
	|FROM
	|	TableLoans AS TableLoans
	|WHERE
	|	TableLoans.PrincipalChargedCur <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	&Company,
	|	VALUE(AccumulationRecordType.Expense),
	|	TableLoans.Period,
	|	TableLoans.Period,
	|	&InterestOfChargeOnLoan,
	|	TableLoans.Employee,
	|	0,
	|	0,
	|	0,
	|	0,
	|	TableLoans.ContractInterestChargedCur,
	|	TableLoans.InterestCharged,
	|	TableLoans.ContractInterestChargedCur,
	|	TableLoans.InterestCharged,
	|	0,
	|	0,
	|	0,
	|	0,
	|	TableLoans.LoanContract,
	|	TableLoans.Currency,
	|	TableLoans.InterestGLAccount,
	|	TRUE,
	|	TableLoans.LoanContract.LoanKind,
	|	TableLoans.StructuralUnit,
	|	TableLoans.ContractInterestChargedCur,
	|	TableLoans.InterestCharged
	|FROM
	|	TableLoans AS TableLoans
	|WHERE
	|	TableLoans.PrincipalChargedCur <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	&Company,
	|	VALUE(AccumulationRecordType.Receipt),
	|	TableLoans.Period,
	|	TableLoans.Period,
	|	&InterestOfAccrualOnLoan,
	|	TableLoans.Employee,
	|	0,
	|	0,
	|	0,
	|	0,
	|	TableLoans.ContractInterestAccruedCur,
	|	TableLoans.InterestAccrued,
	|	-TableLoans.ContractInterestAccruedCur,
	|	-TableLoans.InterestAccrued,
	|	0,
	|	0,
	|	0,
	|	0,
	|	TableLoans.LoanContract,
	|	TableLoans.Currency,
	|	TableLoans.InterestGLAccount,
	|	FALSE,
	|	TableLoans.LoanContract.LoanKind,
	|	TableLoans.StructuralUnit,
	|	TableLoans.ContractInterestAccruedCur,
	|	TableLoans.InterestAccrued
	|FROM
	|	TableLoans AS TableLoans
	|WHERE
	|	TableLoans.PrincipalChargedCur <> 0";
	
	QueryResult = Query.Execute();
	
	Query.Text = 
	"SELECT
	|	TemporaryTableLoanSettlements.Company,
	|	TemporaryTableLoanSettlements.Counterparty,
	|	TemporaryTableLoanSettlements.LoanContract
	|FROM
	|	TemporaryTableLoanSettlements AS TemporaryTableLoanSettlements";
	
	QueryResult = Query.Execute();
	
	Blocking = New DataLock;
	LockItem = Blocking.Add("AccumulationRegister.LoanSettlements");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = QueryResult;
	
	For Each QueryResultColumn In QueryResult.Columns Do
		LockItem.UseFromDataSource(QueryResultColumn.Name, QueryResultColumn.Name);
	EndDo;
	Blocking.Lock();
	
	QueryNumber = 0;
	
	IsBusinessUnit = True;
	Query.Text = SmallBusinessServer.GetQueryTextExchangeRateDifferencesLoanSettlements(Query.TempTablesManager, QueryNumber, IsBusinessUnit);
	ResultsArray = Query.ExecuteBatch();
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableLoanSettlements", ResultsArray[QueryNumber].Unload());
	
EndProcedure
	
Procedure GenerateTableAccountOfLoans(DocumentRefPayroll, StructureAdditionalProperties)

	If DocumentRefPayroll.LoanRepayment.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	
	Query.SetParameter("Ref", 										DocumentRefPayroll);
	Query.SetParameter("PointInTime", 								New Boundary(StructureAdditionalProperties.ForPosting.PointInTime,BoundaryType.Including));
	Query.SetParameter("Company", 									StructureAdditionalProperties.ForPosting.Company);
	Query.SetParameter("ExchangeRateDifference", 						NStr("en='Exchange difference';ru='Курсовая разница';vi='Chênh lệch tỷ giá'"));
	Query.SetParameter("Payroll",									NStr("en='Payroll';ru='Начисление зарплаты';vi='Tính lương'"));
	Query.SetParameter("TaxAccrued",								NStr("en='Tax accrued';ru='Начислен налог';vi='Đã tính thuế'"));
	Query.SetParameter("ChargeForRepaymentPrincipalAndInterest",	NStr("en='Charge for repayment principal and interest';ru='Удержание в счет погашения займа и процентов';vi='Giữ lại để trả nợ và lãi'"));
	Query.SetParameter("InterestOfChargeOnLoan",					NStr("en='Interest of charge on loan';ru='Удержание процентов по займу';vi='Giữ lại lãi theo khoản nợ'"));
	Query.Text = 
	"SELECT
	|	&Company,
	|	TableLoans.Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TableLoans.RegistrationPeriod,
	|	TableLoans.Currency,
	|	TableLoans.StructuralUnit,
	|	TableLoans.Employee,
	|	-TableLoans.AmountCur AS AmountCur,
	|	-TableLoans.Amount AS Amount,
	|	TableLoans.GLAccountLoanContract,
	|	VALUE(AccountingRecordType.Credit) AS ManagerialRecordType,
	|	CAST(&ChargeForRepaymentPrincipalAndInterest AS STRING(100)) AS ContentOfAccountingRecord
	|FROM
	|	TableLoans AS TableLoans
	|WHERE
	|	TableLoans.Amount <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableLoans.LineNumber,
	|	TableLoans.RegistrationPeriod AS Period,
	|	TableLoans.Company,
	|	CASE
	|		WHEN TableLoans.InterestGLAccount.TypeOfAccount = VALUE(Enum.GLAccountsTypes.Expenses)
	|			THEN TableLoans.BusinessArea
	|		ELSE VALUE(Catalog.BusinessActivities.Other)
	|	END AS BusinessActivity,
	|	CASE
	|		WHEN TableLoans.InterestGLAccount.TypeOfAccount = VALUE(Enum.GLAccountsTypes.Expenses)
	|			THEN TableLoans.StructuralUnit
	|		ELSE UNDEFINED
	|	END AS StructuralUnit,
	|	TableLoans.CostAccount AS GLAccount,
	|	TableLoans.Employee AS Analytics,
	|	0 AS AmountExpense,
	|	TableLoans.InterestAccrued AS AmountIncome,
	|	CAST(&InterestOfChargeOnLoan AS STRING(100)) AS ContentOfAccountingRecord
	|FROM
	|	TableLoans AS TableLoans
	|WHERE
	|	TableLoans.InterestAccrued <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentTable.Date,
	|	DocumentTable.Company,
	|	CAST(CASE
	|			WHEN DocumentTable.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN DocumentTable.Counterparty.SettlementsHumanResourcesGLAccount
	|			ELSE DocumentTable.LoanContract.GLAccount
	|		END AS ChartOfAccounts.Managerial) AS AccountDr,
	|	CAST(CASE
	|			WHEN DocumentTable.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN DocumentTable.GLAccount
	|			ELSE DocumentTable.LoanContract.CostAccount
	|		END AS ChartOfAccounts.Managerial) AS AccountCr,
	|	DocumentTable.Currency,
	|	DocumentTable.AmountCur,
	|	DocumentTable.Amount,
	|	CAST(DocumentTable.ContentOfAccountingRecord AS STRING(100)) AS ContentOfAccountingRecord
	|INTO TemporaryTableLoanSettlementsForRegisterRecord
	|FROM
	|	TemporaryTableLoanSettlements AS DocumentTable
	|WHERE
	|	DocumentTable.Amount <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	1 AS LineNumber,
	|	DocumentTable.Date AS Period,
	|	DocumentTable.Company,
	|	VALUE(Catalog.PlanningPeriods.Actual) AS PlanningPeriod,
	|	DocumentTable.AccountDr,
	|	DocumentTable.AccountCr,
	|	CASE
	|		WHEN DocumentTable.AccountDr.Currency
	|			THEN DocumentTable.Currency
	|		ELSE UNDEFINED
	|	END AS CurrencyDr,
	|	CASE
	|		WHEN DocumentTable.AccountCr.Currency
	|			THEN DocumentTable.Currency
	|		ELSE UNDEFINED
	|	END AS CurrencyCr,
	|	CASE
	|		WHEN DocumentTable.AccountDr.Currency
	|			THEN DocumentTable.AmountCur
	|		ELSE 0
	|	END AS AmountCurDr,
	|	CASE
	|		WHEN DocumentTable.AccountCr.Currency
	|			THEN DocumentTable.AmountCur
	|		ELSE 0
	|	END AS AmountCurСr,
	|	DocumentTable.Amount,
	|	CAST(DocumentTable.ContentOfAccountingRecord AS STRING(100)) AS Content
	|FROM
	|	TemporaryTableLoanSettlementsForRegisterRecord AS DocumentTable
	|WHERE
	|	DocumentTable.Amount <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	1,
	|	TemporaryTableExchangeRateDifferencesLoanSettlements.Date,
	|	TemporaryTableExchangeRateDifferencesLoanSettlements.Company,
	|	VALUE(Catalog.PlanningPeriods.Actual),
	|	CASE
	|		WHEN TemporaryTableExchangeRateDifferencesLoanSettlements.ExchangeRateDifferenceAmount > 0
	|			THEN TemporaryTableExchangeRateDifferencesLoanSettlements.GLAccount
	|		ELSE VALUE(ChartOfAccounts.Managerial.OtherExpenses)
	|	END,
	|	CASE
	|		WHEN TemporaryTableExchangeRateDifferencesLoanSettlements.ExchangeRateDifferenceAmount > 0
	|			THEN VALUE(ChartOfAccounts.Managerial.OtherExpenses)
	|		ELSE TemporaryTableExchangeRateDifferencesLoanSettlements.GLAccount
	|	END,
	|	CASE
	|		WHEN TemporaryTableExchangeRateDifferencesLoanSettlements.ExchangeRateDifferenceAmount > 0
	|				AND TemporaryTableExchangeRateDifferencesLoanSettlements.GLAccount.Currency
	|			THEN TemporaryTableExchangeRateDifferencesLoanSettlements.Currency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN TemporaryTableExchangeRateDifferencesLoanSettlements.ExchangeRateDifferenceAmount < 0
	|				AND TemporaryTableExchangeRateDifferencesLoanSettlements.GLAccount.Currency
	|			THEN TemporaryTableExchangeRateDifferencesLoanSettlements.Currency
	|		ELSE UNDEFINED
	|	END,
	|	0,
	|	0,
	|	CASE
	|		WHEN TemporaryTableExchangeRateDifferencesLoanSettlements.ExchangeRateDifferenceAmount > 0
	|			THEN TemporaryTableExchangeRateDifferencesLoanSettlements.ExchangeRateDifferenceAmount
	|		ELSE -TemporaryTableExchangeRateDifferencesLoanSettlements.ExchangeRateDifferenceAmount
	|	END,
	|	CAST(&ExchangeRateDifference AS STRING(100))
	|FROM
	|	TemporaryTableExchangeRateDifferencesLoanSettlements AS TemporaryTableExchangeRateDifferencesLoanSettlements
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&Company,
	|	PayrollLoanRepayment.LineNumber,
	|	PayrollLoanRepayment.Ref.Date AS Period,
	|	PayrollLoanRepayment.Ref.RegistrationPeriod,
	|	PayrollLoanRepayment.Ref.DocumentCurrency AS Currency,
	|	PayrollLoanRepayment.Ref.StructuralUnit,
	|	PayrollLoanRepayment.Employee,
	|	PayrollLoanRepayment.LoanContract.GLAccount AS CostAccount,
	|	VALUE(Document.CustomerOrder.EmptyRef) AS CustomerOrder,
	|	VALUE(Catalog.BusinessActivities.EmptyRef) AS BusinessArea,
	|	PayrollLoanRepayment.Ref.RegistrationPeriod AS StartDate,
	|	ENDOFPERIOD(PayrollLoanRepayment.Ref.RegistrationPeriod, MONTH) AS EndDate,
	|	0 AS DaysWorked,
	|	0 AS HoursWorked,
	|	0 AS Size,
	|	CASE
	|		WHEN PayrollLoanRepayment.LoanContract.DeductionPrincipalDebt = UNDEFINED
	|				OR PayrollLoanRepayment.LoanContract.DeductionPrincipalDebt = VALUE(Catalog.AccrualAndDeductionKinds.EmptyRef)
	|			THEN VALUE(Catalog.AccrualAndDeductionKinds.RepaymentOfLoanFromSalary)
	|		ELSE PayrollLoanRepayment.LoanContract.DeductionPrincipalDebt
	|	END AS AccrualDeductionKind,
	|	CAST(PayrollLoanRepayment.PrincipalCharged * SettlementsCurrencyRates.ExchangeRate * AccountingCurrencyRates.Multiplicity / (AccountingCurrencyRates.ExchangeRate * SettlementsCurrencyRates.Multiplicity) AS NUMBER(15, 2)) AS Amount,
	|	PayrollLoanRepayment.PrincipalCharged AS AmountCur
	|FROM
	|	Document.Payroll.LoanRepayment AS PayrollLoanRepayment
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
	|				&PointInTime,
	|				Currency IN
	|					(SELECT
	|						Constants.NationalCurrency
	|					FROM
	|						Constants AS Constants)) AS AccountingCurrencyRates
	|		ON (TRUE)
	|		LEFT JOIN Constants AS Constants
	|		ON (TRUE)
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast AS SettlementsCurrencyRates
	|		ON PayrollLoanRepayment.Ref.DocumentCurrency = SettlementsCurrencyRates.Currency
	|WHERE
	|	PayrollLoanRepayment.Ref = &Ref
	|	AND PayrollLoanRepayment.PrincipalCharged > 0
	|
	|UNION ALL
	|
	|SELECT
	|	&Company,
	|	PayrollLoanRepayment.LineNumber,
	|	PayrollLoanRepayment.Ref.Date,
	|	PayrollLoanRepayment.Ref.RegistrationPeriod,
	|	PayrollLoanRepayment.Ref.DocumentCurrency,
	|	PayrollLoanRepayment.Ref.StructuralUnit,
	|	PayrollLoanRepayment.Employee,
	|	PayrollLoanRepayment.LoanContract.GLAccount,
	|	VALUE(Document.CustomerOrder.EmptyRef),
	|	VALUE(Catalog.BusinessActivities.EmptyRef),
	|	PayrollLoanRepayment.Ref.RegistrationPeriod,
	|	ENDOFPERIOD(PayrollLoanRepayment.Ref.RegistrationPeriod, MONTH),
	|	0,
	|	0,
	|	0,
	|	CASE
	|		WHEN PayrollLoanRepayment.LoanContract.DeductionInterest = UNDEFINED
	|				OR PayrollLoanRepayment.LoanContract.DeductionInterest = VALUE(Catalog.AccrualAndDeductionKinds.EmptyRef)
	|			THEN VALUE(Catalog.AccrualAndDeductionKinds.InterestOnLoan)
	|		ELSE PayrollLoanRepayment.LoanContract.DeductionInterest
	|	END,
	|	CAST(PayrollLoanRepayment.InterestCharged * SettlementsCurrencyRates.ExchangeRate * AccountingCurrencyRates.Multiplicity / (AccountingCurrencyRates.ExchangeRate * SettlementsCurrencyRates.Multiplicity) AS NUMBER(15, 2)),
	|	PayrollLoanRepayment.InterestCharged
	|FROM
	|	Document.Payroll.LoanRepayment AS PayrollLoanRepayment
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
	|				&PointInTime,
	|				Currency IN
	|					(SELECT
	|						Constants.NationalCurrency
	|					FROM
	|						Constants AS Constants)) AS AccountingCurrencyRates
	|		ON (TRUE)
	|		LEFT JOIN Constants AS Constants
	|		ON (TRUE)
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast AS SettlementsCurrencyRates
	|		ON PayrollLoanRepayment.Ref.DocumentCurrency = SettlementsCurrencyRates.Currency
	|WHERE
	|	PayrollLoanRepayment.Ref = &Ref
	|	AND PayrollLoanRepayment.InterestCharged > 0";
	
	ResultsArray = Query.ExecuteBatch();
	
	CurrentTable = ResultsArray[0].Unload();
	If ValueIsFilled(StructureAdditionalProperties.TableForRegisterRecords.TablePayrollPayments) Then
		For Each CurrentRow In CurrentTable Do
			NewRow = StructureAdditionalProperties.TableForRegisterRecords.TablePayrollPayments.Add();
			FillPropertyValues(NewRow, CurrentRow);
		EndDo;
	Else
		StructureAdditionalProperties.TableForRegisterRecords.Insert("TablePayrollPayments", CurrentTable);
	EndIf;
	
	CurrentTable = ResultsArray[1].Unload();
	If ValueIsFilled(StructureAdditionalProperties.TableForRegisterRecords.TableIncomeAndExpenses) Then
		For Each CurrentRow In CurrentTable Do
			NewRow = StructureAdditionalProperties.TableForRegisterRecords.TableIncomeAndExpenses.Add();
			FillPropertyValues(NewRow, CurrentRow);
		EndDo;
	Else
		StructureAdditionalProperties.TableForRegisterRecords.Insert("TableIncomeAndExpenses", CurrentTable);
	EndIf;
	
	CurrentTable = ResultsArray[3].Unload();
	If ValueIsFilled(StructureAdditionalProperties.TableForRegisterRecords.TableManagerial) Then
		For Each CurrentRow In CurrentTable Do
			NewRow = StructureAdditionalProperties.TableForRegisterRecords.TableManagerial.Add();
			FillPropertyValues(NewRow, CurrentRow);
		EndDo;
	Else
		StructureAdditionalProperties.TableForRegisterRecords.Insert("TableManagerial", CurrentTable);
	EndIf;
	
	CurrentTable = ResultsArray[4].Unload();
	If ValueIsFilled(StructureAdditionalProperties.TableForRegisterRecords.TableAccrualsAndDeductions) Then
		For Each CurrentRow In CurrentTable Do
			NewRow = StructureAdditionalProperties.TableForRegisterRecords.TableAccrualsAndDeductions.Add();
			FillPropertyValues(NewRow, CurrentRow);
		EndDo;
	Else
		StructureAdditionalProperties.TableForRegisterRecords.Insert("TableAccrualsAndDeductions", CurrentTable);
	EndIf;

EndProcedure

#EndRegion

#EndIf