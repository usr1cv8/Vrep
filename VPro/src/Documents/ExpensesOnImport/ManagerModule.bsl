#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region ProgramInterface

#Region ForCallsFromOtherSubsystems

// СтандартныеПодсистемы.УправлениеДоступом

// See AccessManagementOverridable.OnFillListWithAccessRestriction.
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Company)
	|	AND ValueAllowed(Counterparty)";

EndProcedure

// Конец СтандартныеПодсистемы.УправлениеДоступом

#EndRegion

#Region PrintInterface

// Fills in the list of printing commands.
// 
// Parameters:
//   PrintCommands - ValueTable - состав полей See в функции УправлениеПечатью.СоздатьКоллекциюКомандПечати.
//
Procedure AddPrintCommands(PrintCommands) Export
	
	Return;
	
EndProcedure

#EndRegion

// Initializes the tables of values that contain the data of the document table sections.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
// Parameters:
//  DocumentRefExpensesOnImport	 - DocumentRef.ExpensesOnImport - ссылка на документ,
//  StructureAdditionalProperties - Structure - поле "ДополнительныеСвойства" документа.
//
Procedure DocumentDataInitialization(DocumentRefExpensesOnImport, StructureAdditionalProperties) Export
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	ExpensesOnImportInventory.LineNumber AS LineNumber,
	|	ExpensesOnImportInventory.Ref.Date AS Period,
	|	&Company AS Company,
	|	ExpensesOnImportInventory.Ref.Counterparty AS Counterparty,
	|	ExpensesOnImportInventory.Ref.Counterparty.DoOperationsByContracts AS DoOperationsByContracts,
	|	ExpensesOnImportInventory.Ref.Counterparty.DoOperationsByDocuments AS DoOperationsByDocuments,
	|	ExpensesOnImportInventory.Ref.Counterparty.DoOperationsByOrders AS DoOperationsByOrders,
	|	ExpensesOnImportInventory.Ref.Counterparty.TrackPaymentsByBills AS TrackPaymentsByBills,
	|	ExpensesOnImportInventory.Ref.Counterparty.GLAccountCustomerSettlements AS GLAccountCustomerSettlements,
	|	ExpensesOnImportInventory.Ref.Counterparty.GLAccountVendorSettlements AS GLAccountVendorSettlements,
	|	ExpensesOnImportInventory.Ref.Contract AS Contract,
	|	ExpensesOnImportInventory.Ref.Contract.SettlementsCurrency AS SettlementsCurrency,
	|	ExpensesOnImportInventory.Ref.PurchaseOrder AS PurchaseOrder,
	|	CASE
	|		WHEN
	|			ExpensesOnImportInventory.Ref.WarehousePosition = VALUE(Enum.AttributePositionOnForm.InTabularSection)
	|			THEN ExpensesOnImportInventory.StructuralUnit
	|		ELSE ExpensesOnImportInventory.Ref.StructuralUnit
	|	END AS StructuralUnit,
	|	ExpensesOnImportInventory.ProductsAndServices.InventoryGLAccount AS GLAccount,
	|	ExpensesOnImportInventory.ProductsAndServices AS ProductsAndServices,
	|	CASE
	|		WHEN &UseCharacteristics
	|			THEN ExpensesOnImportInventory.CHARACTERISTIC
	|		ELSE VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	|	END AS CHARACTERISTIC,
	|	CASE
	|		WHEN &UseBatches
	|			THEN ExpensesOnImportInventory.Batch
	|		ELSE VALUE(Catalog.ProductsAndServicesBatches.EmptyRef)
	|	END AS Batch,
	|	ExpensesOnImportInventory.CustomerOrder AS CustomerOrder,
	|	ExpensesOnImportInventory.Quantity AS Quantity,
	|	CAST(CASE
	|		WHEN ExpensesOnImportInventory.Ref.DocumentCurrency = ConstantNationalCurrency.Value
	|			THEN ExpensesOnImportInventory.FeeAmount * RegCurrencyRates.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate *
	|				RegCurrencyRates.Multiplicity)
	|		ELSE ExpensesOnImportInventory.FeeAmount * ExpensesOnImportInventory.Ref.ExchangeRate * ManagCurrencyRates.Multiplicity /
	|			(ManagCurrencyRates.ExchangeRate * ExpensesOnImportInventory.Ref.Multiplicity)
	|	END AS NUMBER(15, 2)) AS FeeAmount,
	|	CAST(CASE
	|		WHEN ExpensesOnImportInventory.Ref.DocumentCurrency = ConstantNationalCurrency.Value
	|			THEN ExpensesOnImportInventory.FeeAmount * RegCurrencyRates.ExchangeRate * ExpensesOnImportInventory.Ref.Multiplicity /
	|				(ExpensesOnImportInventory.Ref.ExchangeRate * RegCurrencyRates.Multiplicity)
	|		ELSE ExpensesOnImportInventory.FeeAmount
	|	END AS NUMBER(15, 2)) AS FeeAmountCur,
	|	CAST(CASE
	|		WHEN ExpensesOnImportInventory.Ref.DocumentCurrency = ConstantNationalCurrency.Value
	|			THEN ExpensesOnImportInventory.DutyAmount * RegCurrencyRates.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate
	|				* RegCurrencyRates.Multiplicity)
	|		ELSE ExpensesOnImportInventory.DutyAmount * ExpensesOnImportInventory.Ref.ExchangeRate * ManagCurrencyRates.Multiplicity /
	|			(ManagCurrencyRates.ExchangeRate * ExpensesOnImportInventory.Ref.Multiplicity)
	|	END AS NUMBER(15, 2)) AS DutyAmount,
	|	CAST(CASE
	|		WHEN ExpensesOnImportInventory.Ref.DocumentCurrency = ConstantNationalCurrency.Value
	|			THEN ExpensesOnImportInventory.DutyAmount * RegCurrencyRates.ExchangeRate * ExpensesOnImportInventory.Ref.Multiplicity /
	|				(ExpensesOnImportInventory.Ref.ExchangeRate * RegCurrencyRates.Multiplicity)
	|		ELSE ExpensesOnImportInventory.DutyAmount
	|	END AS NUMBER(15, 2)) AS DutyAmountCur,
	|	CAST(CASE
	|		WHEN ExpensesOnImportInventory.Ref.DocumentCurrency = ConstantNationalCurrency.Value
	|			THEN ExpensesOnImportInventory.VATAmount * RegCurrencyRates.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate *
	|				RegCurrencyRates.Multiplicity)
	|		ELSE ExpensesOnImportInventory.VATAmount * ExpensesOnImportInventory.Ref.ExchangeRate * ManagCurrencyRates.Multiplicity /
	|			(ManagCurrencyRates.ExchangeRate * ExpensesOnImportInventory.Ref.Multiplicity)
	|	END AS NUMBER(15, 2)) AS VATAmount,
	|	CAST(CASE
	|		WHEN ExpensesOnImportInventory.Ref.DocumentCurrency = ConstantNationalCurrency.Value
	|			THEN ExpensesOnImportInventory.VATAmount * RegCurrencyRates.ExchangeRate * ExpensesOnImportInventory.Ref.Multiplicity /
	|				(ExpensesOnImportInventory.Ref.ExchangeRate * RegCurrencyRates.Multiplicity)
	|		ELSE ExpensesOnImportInventory.VATAmount
	|	END AS NUMBER(15, 2)) AS VATAmountCur
	|INTO TemporaryTableInventory
	|FROM
	|	Document.ExpensesOnImport.Inventory AS ExpensesOnImportInventory
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(&PointInTime, Currency IN
	|			(SELECT
	|				ConstantAccountingCurrency.Value
	|			FROM
	|				Constant.AccountingCurrency AS ConstantAccountingCurrency)) AS ManagCurrencyRates
	|		ON (TRUE)
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(&PointInTime, Currency IN
	|			(SELECT
	|				ConstantNationalCurrency.Value
	|			FROM
	|				Constant.NationalCurrency AS ConstantNationalCurrency)) AS RegCurrencyRates
	|		ON (TRUE),
	|	Constant.NationalCurrency AS ConstantNationalCurrency
	|WHERE
	|	ExpensesOnImportInventory.Ref = &Ref
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	1 AS LineNumber,
	|	ExpensesOnImportExpenses.Counterparty.DoOperationsByContracts AS DoOperationsByContracts,
	|	ExpensesOnImportExpenses.Counterparty.DoOperationsByDocuments AS DoOperationsByDocuments,
	|	ExpensesOnImportExpenses.Counterparty.DoOperationsByOrders AS DoOperationsByOrders,
	|	ExpensesOnImportExpenses.Counterparty.TrackPaymentsByBills AS TrackPaymentsByBills,
	|	ExpensesOnImportExpenses.Counterparty AS Counterparty,
	|	ExpensesOnImportExpenses.Contract AS Contract,
	|	ExpensesOnImportExpenses.Counterparty.GLAccountVendorSettlements AS GLAccountVendorSettlements,
	|	ExpensesOnImportExpenses.Contract.SettlementsCurrency AS SettlementsCurrency,
	|	ExpensesOnImportExpenses.StructuralUnit AS StructuralUnit,
	|	ExpensesOnImportExpenses.Date AS Period,
	|	ExpensesOnImportExpenses.Ref AS Document,
	|	ExpensesOnImportExpenses.ExpensesGLAccount AS GLAccount,
	|	ExpensesOnImportExpenses.BusinessActivity AS BusinessActivity,
	|	&Company AS Company,
	|	ExpensesOnImportExpenses.PurchaseOrder AS PurchaseOrder,
	|	CAST(CASE
	|		WHEN ExpensesOnImportExpenses.DocumentCurrency = ConstantNationalCurrency.Value
	|			THEN ExpensesOnImportExpenses.CustomsPenalty * RegCurrencyRates.ExchangeRate * ManagCurrencyRates.Multiplicity /
	|				(ManagCurrencyRates.ExchangeRate * RegCurrencyRates.Multiplicity)
	|		ELSE ExpensesOnImportExpenses.CustomsPenalty * ExpensesOnImportExpenses.ExchangeRate * ManagCurrencyRates.Multiplicity /
	|			(ManagCurrencyRates.ExchangeRate * ExpensesOnImportExpenses.Multiplicity)
	|	END AS NUMBER(15, 2)) AS AmountFine,
	|	CAST(CASE
	|		WHEN ExpensesOnImportExpenses.DocumentCurrency = ConstantNationalCurrency.Value
	|			THEN ExpensesOnImportExpenses.CustomsPenalty * RegCurrencyRates.ExchangeRate * ExpensesOnImportExpenses.Multiplicity /
	|				(ExpensesOnImportExpenses.ExchangeRate * RegCurrencyRates.Multiplicity)
	|		ELSE ExpensesOnImportExpenses.CustomsPenalty
	|	END AS NUMBER(15, 2)) AS AmountFineCur
	|INTO TemporaryTableExpenses
	|FROM
	|	Document.ExpensesOnImport AS ExpensesOnImportExpenses
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(&PointInTime, Currency IN
	|			(SELECT
	|				ConstantAccountingCurrency.Value
	|			FROM
	|				Constant.AccountingCurrency AS ConstantAccountingCurrency)) AS ManagCurrencyRates
	|		ON (TRUE)
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(&PointInTime, Currency IN
	|			(SELECT
	|				ConstantNationalCurrency.Value
	|			FROM
	|				Constant.NationalCurrency AS ConstantNationalCurrency)) AS RegCurrencyRates
	|		ON (TRUE),
	|	Constant.NationalCurrency AS ConstantNationalCurrency
	|WHERE
	|	ExpensesOnImportExpenses.Ref = &Ref
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExpensesOnImportVATInventory.LineNumber AS LineNumber,
	|	ExpensesOnImportVATInventory.Ref.Counterparty.DoOperationsByContracts AS DoOperationsByContracts,
	|	ExpensesOnImportVATInventory.Ref.Counterparty.DoOperationsByDocuments AS DoOperationsByDocuments,
	|	ExpensesOnImportVATInventory.Ref.Counterparty.DoOperationsByOrders AS DoOperationsByOrders,
	|	ExpensesOnImportVATInventory.Ref.Counterparty.TrackPaymentsByBills AS TrackPaymentsByBills,
	|	ExpensesOnImportVATInventory.Ref.Counterparty AS Counterparty,
	|	ExpensesOnImportVATInventory.Ref.Contract AS Contract,
	|	ExpensesOnImportVATInventory.Ref.Counterparty.GLAccountVendorSettlements AS GLAccountVendorSettlements,
	|	ExpensesOnImportVATInventory.Ref.Contract.SettlementsCurrency AS SettlementsCurrency,
	|	CASE
	|		WHEN
	|			ExpensesOnImportVATInventory.Ref.WarehousePosition = VALUE(Enum.AttributePositionOnForm.InTabularSection)
	|			THEN ExpensesOnImportVATInventory.StructuralUnit
	|		ELSE ExpensesOnImportVATInventory.Ref.StructuralUnit
	|	END AS StructuralUnit,
	|	ExpensesOnImportVATInventory.Ref.Date AS Period,
	|	ExpensesOnImportVATInventory.Ref AS Document,
	|	ExpensesOnImportVATInventory.ProductsAndServices.InventoryGLAccount AS GLAccount,
	|	ExpensesOnImportVATInventory.ProductsAndServices.BusinessActivity AS BusinessActivity,
	|	&Company AS Company,
	|	ExpensesOnImportVATInventory.Ref.PurchaseOrder AS PurchaseOrder,
	|	CAST(CASE
	|		WHEN ExpensesOnImportVATInventory.Ref.DocumentCurrency = ConstantNationalCurrency.Value
	|			THEN ExpensesOnImportVATInventory.VATAmount * RegCurrencyRates.ExchangeRate * ManagCurrencyRates.Multiplicity / (ManagCurrencyRates.ExchangeRate *
	|				RegCurrencyRates.Multiplicity)
	|		ELSE ExpensesOnImportVATInventory.VATAmount * ExpensesOnImportVATInventory.Ref.ExchangeRate * ManagCurrencyRates.Multiplicity /
	|			(ManagCurrencyRates.ExchangeRate * ExpensesOnImportVATInventory.Ref.Multiplicity)
	|	END AS NUMBER(15, 2)) AS VATAmount,
	|	CAST(CASE
	|		WHEN ExpensesOnImportVATInventory.Ref.DocumentCurrency = ConstantNationalCurrency.Value
	|			THEN ExpensesOnImportVATInventory.VATAmount * RegCurrencyRates.ExchangeRate * ExpensesOnImportVATInventory.Ref.Multiplicity /
	|				(ExpensesOnImportVATInventory.Ref.ExchangeRate * RegCurrencyRates.Multiplicity)
	|		ELSE ExpensesOnImportVATInventory.VATAmount
	|	END AS NUMBER(15, 2)) AS VATAmountCur
	|INTO TemporaryTableVAT
	|FROM
	|	Document.ExpensesOnImport.Inventory AS ExpensesOnImportVATInventory
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(&PointInTime, Currency IN
	|			(SELECT
	|				ConstantAccountingCurrency.Value
	|			FROM
	|				Constant.AccountingCurrency AS ConstantAccountingCurrency)) AS ManagCurrencyRates
	|		ON (TRUE)
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(&PointInTime, Currency IN
	|			(SELECT
	|				ConstantNationalCurrency.Value
	|			FROM
	|				Constant.NationalCurrency AS ConstantNationalCurrency)) AS RegCurrencyRates
	|		ON (TRUE),
	|	Constant.NationalCurrency AS ConstantNationalCurrency
	|WHERE
	|	ExpensesOnImportVATInventory.Ref = &Ref
	|	AND ExpensesOnImportVATInventory.VATAmount <> 0";
	
	Query.SetParameter("Ref", DocumentRefExpensesOnImport);
	Query.SetParameter("Company", StructureAdditionalProperties.ForPosting.Company);
	Query.SetParameter("PointInTime", New Boundary(StructureAdditionalProperties.ForPosting.PointInTime, BoundaryType.Including));
	Query.SetParameter("UseCharacteristics", StructureAdditionalProperties.AccountingPolicy.UseCharacteristics);
	Query.SetParameter("UseBatches", StructureAdditionalProperties.AccountingPolicy.UseBatches);
	
	Query.ExecuteBatch();
	
	GenerateTableInventory(DocumentRefExpensesOnImport, StructureAdditionalProperties);
	GenerateTableSettlementsWithOtherCounterparties(DocumentRefExpensesOnImport, StructureAdditionalProperties);
	GenerateTableIncomeAndExpenses(DocumentRefExpensesOnImport, StructureAdditionalProperties);
	
	GenerateTableManagerial(DocumentRefExpensesOnImport, StructureAdditionalProperties);
	
EndProcedure // ИнициализироватьДанныеДокумента()

// Controls the occurrence of negative balances.
//
// Parameters:
//  DocumentRefExpensesOnImport - DocumentRef.ExpensesOnImport - ссылка на документ,
//  AdditionalProperties -  - Структура - поле "ДополнительныеСвойства" документа,
//  cancel - Boolean - признак "Отказ",
//  PostingDelete - Boolean - выполняется отмена проведения.
//
Procedure RunControl(DocumentRefExpensesOnImport, AdditionalProperties, cancel, PostingDelete = False) Export
	
	If Not SmallBusinessServer.RunBalanceControl() Then
		Return;
	EndIf;
	
	StructureTemporaryTables = AdditionalProperties.ForPosting.StructureTemporaryTables;
	
	// Если временные таблицы "ДвиженияРасчетыСПоставщикамиИзменение", "ДвиженияЗаказыПоставщикамИзменение",
	// содержат записи, необходимо выполнить контроль реализации товаров.
	
	If Not StructureTemporaryTables.RegisterRecordsInventoryChange Then
		Return;
	EndIf;
	
	Query = New Query("SELECT
	|	RegisterRecordsInventoryChange.LineNumber AS LineNumber,
	|	RegisterRecordsInventoryChange.Company AS CompanyPresentation,
	|	RegisterRecordsInventoryChange.StructuralUnit AS StructuralUnitPresentation,
	|	RegisterRecordsInventoryChange.GLAccount AS GLAccountPresentation,
	|	RegisterRecordsInventoryChange.ProductsAndServices AS ProductsAndServicesPresentation,
	|	RegisterRecordsInventoryChange.CHARACTERISTIC AS CharacteristicPresentation,
	|	RegisterRecordsInventoryChange.Batch AS BatchPresentation,
	|	RegisterRecordsInventoryChange.CustomerOrder AS CustomerOrderPresentation,
	|	InventoryBalance.StructuralUnit.StructuralUnitType AS StructuralUnitType,
	|	InventoryBalance.ProductsAndServices.MeasurementUnit AS MeasurementUnitPresentation,
	|	ISNULL(RegisterRecordsInventoryChange.QuantityChange, 0) + ISNULL(InventoryBalance.QuantityBalance, 0) AS
	|		BalanceInventory,
	|	ISNULL(InventoryBalance.QuantityBalance, 0) AS QuantityBalanceInventory,
	|	ISNULL(InventoryBalance.AmountBalance, 0) AS AmountBalanceInventory
	|FROM
	|	RegisterRecordsInventoryChange AS RegisterRecordsInventoryChange
	|		INNER JOIN AccumulationRegister.Inventory.Balance(&ControlTime,) AS InventoryBalance
	|		ON RegisterRecordsInventoryChange.Company = InventoryBalance.Company
	|		AND RegisterRecordsInventoryChange.StructuralUnit = InventoryBalance.StructuralUnit
	|		AND RegisterRecordsInventoryChange.GLAccount = InventoryBalance.GLAccount
	|		AND RegisterRecordsInventoryChange.ProductsAndServices = InventoryBalance.ProductsAndServices
	|		AND RegisterRecordsInventoryChange.CHARACTERISTIC = InventoryBalance.CHARACTERISTIC
	|		AND RegisterRecordsInventoryChange.Batch = InventoryBalance.Batch
	|		AND RegisterRecordsInventoryChange.CustomerOrder = InventoryBalance.CustomerOrder
	|		AND (ISNULL(InventoryBalance.QuantityBalance, 0) < 0)
	|ORDER BY
	|	LineNumber");

	Query.TempTablesManager = StructureTemporaryTables.TempTablesManager;
	Query.SetParameter("ControlTime", AdditionalProperties.ForPosting.ControlTime);

	ResultsArray = Query.ExecuteBatch();

	If Not ResultsArray[0].IsEmpty() Then

		DocumentObjectExpensesOnImport = DocumentRefExpensesOnImport.GetObject();

	EndIf;

	// Отрицательный остаток учета запасов.
	If Not ResultsArray[0].IsEmpty() Then

		QueryResultSelection = ResultsArray[1].Select();
		SmallBusinessServer.ShowMessageAboutPostingToInventoryRegisterErrors(DocumentObjectExpensesOnImport, QueryResultSelection, cancel);

	EndIf;

EndProcedure // ВыполнитьКонтроль()

#EndRegion

#Region InternalProceduresAndFunctions

Procedure GenerateTableInventory(DocumentRefExpensesOnImport, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	MIN(TableInventory.LineNumber) AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TableInventory.Period AS Period,
	|	TableInventory.Company AS Company,
	|	TableInventory.StructuralUnit AS StructuralUnit,
	|	TableInventory.GLAccount AS GLAccount,
	|	TableInventory.ProductsAndServices AS ProductsAndServices,
	|	TableInventory.CHARACTERISTIC AS CHARACTERISTIC,
	|	TableInventory.Batch AS Batch,
	|	TableInventory.CustomerOrder AS CustomerOrder,
	|	TRUE AS FixedCost,
	|	&CustomsDuty AS ContentOfAccountingRecord,
	|	0 AS Quantity,
	|	SUM(TableInventory.DutyAmount) AS Amount
	|INTO SummaryTableInventory
	|FROM
	|	TemporaryTableInventory AS TableInventory
	|GROUP BY
	|	TableInventory.Period,
	|	TableInventory.Company,
	|	TableInventory.StructuralUnit,
	|	TableInventory.GLAccount,
	|	TableInventory.ProductsAndServices,
	|	TableInventory.CHARACTERISTIC,
	|	TableInventory.Batch,
	|	TableInventory.CustomerOrder,
	|	VALUE(AccumulationRecordType.Receipt)
	|
	|UNION ALL
	|
	|SELECT
	|	MIN(TableInventory.LineNumber),
	|	VALUE(AccumulationRecordType.Receipt),
	|	TableInventory.Period,
	|	TableInventory.Company,
	|	TableInventory.StructuralUnit,
	|	TableInventory.GLAccount,
	|	TableInventory.ProductsAndServices,
	|	TableInventory.CHARACTERISTIC,
	|	TableInventory.Batch,
	|	TableInventory.CustomerOrder,
	|	TRUE,
	|	&CustomsFee,
	|	0,
	|	SUM(TableInventory.FeeAmount)
	|FROM
	|	TemporaryTableInventory AS TableInventory
	|GROUP BY
	|	TableInventory.Period,
	|	TableInventory.Company,
	|	TableInventory.StructuralUnit,
	|	TableInventory.GLAccount,
	|	TableInventory.ProductsAndServices,
	|	TableInventory.CHARACTERISTIC,
	|	TableInventory.Batch,
	|	TableInventory.CustomerOrder,
	|	VALUE(AccumulationRecordType.Receipt)
	|
	|UNION ALL
	|
	|SELECT
	|	MIN(TableInventory.LineNumber),
	|	VALUE(AccumulationRecordType.Receipt),
	|	TableInventory.Period,
	|	TableInventory.Company,
	|	TableInventory.StructuralUnit,
	|	TableInventory.GLAccount,
	|	TableInventory.ProductsAndServices,
	|	TableInventory.CHARACTERISTIC,
	|	TableInventory.Batch,
	|	TableInventory.CustomerOrder,
	|	TRUE,
	|	&CustomsVAT,
	|	0,
	|	SUM(TableInventory.VATAmount)
	|FROM
	|	TemporaryTableInventory AS TableInventory
	|GROUP BY
	|	TableInventory.Period,
	|	TableInventory.Company,
	|	TableInventory.StructuralUnit,
	|	TableInventory.GLAccount,
	|	TableInventory.ProductsAndServices,
	|	TableInventory.CHARACTERISTIC,
	|	TableInventory.Batch,
	|	TableInventory.CustomerOrder,
	|	VALUE(AccumulationRecordType.Receipt)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SummaryTableInventory.LineNumber,
	|	SummaryTableInventory.RecordType,
	|	SummaryTableInventory.Period,
	|	SummaryTableInventory.Company,
	|	SummaryTableInventory.StructuralUnit,
	|	SummaryTableInventory.GLAccount,
	|	SummaryTableInventory.ProductsAndServices,
	|	SummaryTableInventory.CHARACTERISTIC,
	|	SummaryTableInventory.Batch,
	|	SummaryTableInventory.CustomerOrder,
	|	SummaryTableInventory.FixedCost,
	|	SummaryTableInventory.ContentOfAccountingRecord,
	|	SummaryTableInventory.Quantity,
	|	SummaryTableInventory.Amount
	|FROM
	|	SummaryTableInventory AS SummaryTableInventory
	|WHERE
	|	SummaryTableInventory.Amount > 0
	|ORDER BY
	|	SummaryTableInventory.LineNumber";
	
	Query.SetParameter("CustomsDuty", NStr("en='Таможенная пошлина';ru='Таможенная пошлина';vi='Thuế hải quan'"));
	Query.SetParameter("CustomsFee", NStr("en='Таможенный сбор';ru='Таможенный сбор';vi='Phí hải quan'"));
	Query.SetParameter("CustomsVAT", NStr("en='НДС, уплаченный таможенным органам';ru='НДС, уплаченный таможенным органам';vi='Thuế GTGT đã nộp cho hải quan'"));
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableInventory", QueryResult.Unload());
	
EndProcedure

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableSettlementsWithOtherCounterparties(DocumentRefExpensesOnImport, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	
	Query.SetParameter("Ref", DocumentRefExpensesOnImport);
	Query.SetParameter("PointInTime", New Boundary(StructureAdditionalProperties.ForPosting.PointInTime, BoundaryType.Including));
	Query.SetParameter("ControlPeriod", StructureAdditionalProperties.ForPosting.PointInTime.Date);
	Query.SetParameter("Company", StructureAdditionalProperties.ForPosting.Company);
	Query.SetParameter("CustomsFee", NStr("en='Customs duty';ru='Таможенный сбор';vi='Phí hải quan'"));
	Query.SetParameter("CustomsDuty", NStr("en='Customs duty';ru='Таможенная пошлина';vi='Thuế hải quan'"));
	Query.SetParameter("CustomsPenalty", NStr("en='Customs pealty';ru='Таможенный штраф';vi='Tiền phạt hải quan'"));
	Query.SetParameter("CustomsVAT", NStr("en='VAT payed to customs';ru='НДС, уплаченный таможенным органам';vi='Thuế GTGT đã nộp cho hải quan'"));
	Query.SetParameter("ExchangeDifference", NStr("en='Exchange rate differences';ru='Курсовая разница';vi='Chênh lệch tỉ giá'"));
	
	Query.Text =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DocumentTableFees.LineNumber AS LineNumber,
	|	DocumentTableFees.Period AS Date,
	|	DocumentTableFees.Company AS Company,
	|	DocumentTableFees.Counterparty AS Counterparty,
	|	DocumentTableFees.DoOperationsByDocuments AS DoOperationsByDocuments,
	|	DocumentTableFees.GLAccountVendorSettlements AS GLAccount,
	|	DocumentTableFees.Contract AS Contract,
	|	CASE
	|		WHEN DocumentTableFees.DoOperationsByDocuments
	|			THEN &Ref
	|		ELSE UNDEFINED
	|	END AS Document,
	|	CASE
	|		WHEN DocumentTableFees.PurchaseOrder REFS Document.PurchaseOrder
	|				AND DocumentTableFees.PurchaseOrder <> VALUE(Document.PurchaseOrder.EmptyRef)
	|				AND DocumentTableFees.DoOperationsByOrders
	|			THEN DocumentTableFees.PurchaseOrder
	|		ELSE VALUE(Document.PurchaseOrder.EmptyRef)
	|	END AS DocOrder,
	|	DocumentTableFees.SettlementsCurrency AS Currency,
	|	VALUE(Enum.SettlementsTypes.Debt) AS SettlementsType,
	|	SUM(DocumentTableFees.FeeAmount) AS Amount,
	|	SUM(DocumentTableFees.FeeAmountCur) AS AmountCur,
	|	SUM(DocumentTableFees.FeeAmount) AS AmountForBalance,
	|	SUM(DocumentTableFees.FeeAmountCur) AS AmountCurForBalance,
	|	&CustomsFee AS ContentOfAccountingRecord
	|INTO TemporaryTableSettlementsWithOtherCounterparties
	|FROM
	|	TemporaryTableInventory AS DocumentTableFees
	|
	|GROUP BY
	|	DocumentTableFees.LineNumber,
	|	DocumentTableFees.Period,
	|	DocumentTableFees.Company,
	|	DocumentTableFees.Counterparty,
	|	DocumentTableFees.DoOperationsByDocuments,
	|	DocumentTableFees.Contract,
	|	CASE
	|		WHEN DocumentTableFees.PurchaseOrder REFS Document.PurchaseOrder
	|				AND DocumentTableFees.PurchaseOrder <> VALUE(Document.PurchaseOrder.EmptyRef)
	|				AND DocumentTableFees.DoOperationsByOrders
	|			THEN DocumentTableFees.PurchaseOrder
	|		ELSE VALUE(Document.PurchaseOrder.EmptyRef)
	|	END,
	|	DocumentTableFees.SettlementsCurrency,
	|	DocumentTableFees.GLAccountVendorSettlements,
	|	CASE
	|		WHEN DocumentTableFees.DoOperationsByDocuments
	|			THEN &Ref
	|		ELSE UNDEFINED
	|	END
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense),
	|	DocumentTableDuty.LineNumber,
	|	DocumentTableDuty.Period,
	|	DocumentTableDuty.Company,
	|	DocumentTableDuty.Counterparty,
	|	DocumentTableDuty.DoOperationsByDocuments,
	|	DocumentTableDuty.GLAccountVendorSettlements,
	|	DocumentTableDuty.Contract,
	|	CASE
	|		WHEN DocumentTableDuty.DoOperationsByDocuments
	|			THEN &Ref
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTableDuty.PurchaseOrder REFS Document.PurchaseOrder
	|				AND DocumentTableDuty.PurchaseOrder <> VALUE(Document.PurchaseOrder.EmptyRef)
	|				AND DocumentTableDuty.DoOperationsByOrders
	|			THEN DocumentTableDuty.PurchaseOrder
	|		ELSE VALUE(Document.PurchaseOrder.EmptyRef)
	|	END,
	|	DocumentTableDuty.SettlementsCurrency,
	|	VALUE(Enum.SettlementsTypes.Debt),
	|	SUM(DocumentTableDuty.DutyAmount),
	|	SUM(DocumentTableDuty.DutyAmountCur),
	|	SUM(DocumentTableDuty.DutyAmount),
	|	SUM(DocumentTableDuty.DutyAmountCur),
	|	&CustomsDuty
	|FROM
	|	TemporaryTableInventory AS DocumentTableDuty
	|
	|GROUP BY
	|	DocumentTableDuty.LineNumber,
	|	DocumentTableDuty.Period,
	|	DocumentTableDuty.Company,
	|	DocumentTableDuty.Counterparty,
	|	DocumentTableDuty.DoOperationsByDocuments,
	|	DocumentTableDuty.Contract,
	|	CASE
	|		WHEN DocumentTableDuty.PurchaseOrder REFS Document.PurchaseOrder
	|				AND DocumentTableDuty.PurchaseOrder <> VALUE(Document.PurchaseOrder.EmptyRef)
	|				AND DocumentTableDuty.DoOperationsByOrders
	|			THEN DocumentTableDuty.PurchaseOrder
	|		ELSE VALUE(Document.PurchaseOrder.EmptyRef)
	|	END,
	|	DocumentTableDuty.SettlementsCurrency,
	|	DocumentTableDuty.GLAccountVendorSettlements,
	|	CASE
	|		WHEN DocumentTableDuty.DoOperationsByDocuments
	|			THEN &Ref
	|		ELSE UNDEFINED
	|	END
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense),
	|	DocumentTable.LineNumber,
	|	DocumentTable.Period,
	|	DocumentTable.Company,
	|	DocumentTable.Counterparty,
	|	DocumentTable.DoOperationsByDocuments,
	|	DocumentTable.GLAccountVendorSettlements,
	|	DocumentTable.Contract,
	|	CASE
	|		WHEN DocumentTable.DoOperationsByDocuments
	|			THEN &Ref
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.PurchaseOrder REFS Document.PurchaseOrder
	|				AND DocumentTable.PurchaseOrder <> VALUE(Document.PurchaseOrder.EmptyRef)
	|				AND DocumentTable.DoOperationsByOrders
	|			THEN DocumentTable.PurchaseOrder
	|		ELSE VALUE(Document.PurchaseOrder.EmptyRef)
	|	END,
	|	DocumentTable.SettlementsCurrency,
	|	VALUE(Enum.SettlementsTypes.Debt),
	|	SUM(DocumentTable.AmountFine),
	|	SUM(DocumentTable.AmountFineCur),
	|	SUM(DocumentTable.AmountFine),
	|	SUM(DocumentTable.AmountFineCur),
	|	&CustomsPenalty
	|FROM
	|	TemporaryTableExpenses AS DocumentTable
	|WHERE
	|	DocumentTable.AmountFine > 0
	|
	|GROUP BY
	|	DocumentTable.LineNumber,
	|	DocumentTable.Period,
	|	DocumentTable.Company,
	|	DocumentTable.Counterparty,
	|	DocumentTable.DoOperationsByDocuments,
	|	DocumentTable.Contract,
	|	CASE
	|		WHEN DocumentTable.PurchaseOrder REFS Document.PurchaseOrder
	|				AND DocumentTable.PurchaseOrder <> VALUE(Document.PurchaseOrder.EmptyRef)
	|				AND DocumentTable.DoOperationsByOrders
	|			THEN DocumentTable.PurchaseOrder
	|		ELSE VALUE(Document.PurchaseOrder.EmptyRef)
	|	END,
	|	DocumentTable.SettlementsCurrency,
	|	DocumentTable.GLAccountVendorSettlements,
	|	CASE
	|		WHEN DocumentTable.DoOperationsByDocuments
	|			THEN &Ref
	|		ELSE UNDEFINED
	|	END
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense),
	|	DocumentTable.LineNumber,
	|	DocumentTable.Period,
	|	DocumentTable.Company,
	|	DocumentTable.Counterparty,
	|	DocumentTable.DoOperationsByDocuments,
	|	DocumentTable.GLAccountVendorSettlements,
	|	DocumentTable.Contract,
	|	CASE
	|		WHEN DocumentTable.DoOperationsByDocuments
	|			THEN &Ref
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DocumentTable.PurchaseOrder REFS Document.PurchaseOrder
	|				AND DocumentTable.PurchaseOrder <> VALUE(Document.PurchaseOrder.EmptyRef)
	|				AND DocumentTable.DoOperationsByOrders
	|			THEN DocumentTable.PurchaseOrder
	|		ELSE VALUE(Document.PurchaseOrder.EmptyRef)
	|	END,
	|	DocumentTable.SettlementsCurrency,
	|	VALUE(Enum.SettlementsTypes.Debt),
	|	SUM(DocumentTable.VATAmount),
	|	SUM(DocumentTable.VATAmountCur),
	|	SUM(DocumentTable.VATAmount),
	|	SUM(DocumentTable.VATAmountCur),
	|	&CustomsVAT
	|FROM
	|	TemporaryTableVAT AS DocumentTable
	|WHERE
	|	DocumentTable.VATAmount > 0
	|
	|GROUP BY
	|	DocumentTable.LineNumber,
	|	DocumentTable.Period,
	|	DocumentTable.Company,
	|	DocumentTable.Counterparty,
	|	DocumentTable.DoOperationsByDocuments,
	|	DocumentTable.Contract,
	|	CASE
	|		WHEN DocumentTable.PurchaseOrder REFS Document.PurchaseOrder
	|				AND DocumentTable.PurchaseOrder <> VALUE(Document.PurchaseOrder.EmptyRef)
	|				AND DocumentTable.DoOperationsByOrders
	|			THEN DocumentTable.PurchaseOrder
	|		ELSE VALUE(Document.PurchaseOrder.EmptyRef)
	|	END,
	|	DocumentTable.SettlementsCurrency,
	|	DocumentTable.GLAccountVendorSettlements,
	|	CASE
	|		WHEN DocumentTable.DoOperationsByDocuments
	|			THEN &Ref
	|		ELSE UNDEFINED
	|	END";
	
	Query.Execute();
	
	// Установка исключительной блокировки контролируемых остатков расчетов с контрагентами.
	Query.Text =
	"SELECT
	|	TemporaryTableSettlementsWithOtherCounterparties.GLAccount AS GLAccount
	|	,TemporaryTableSettlementsWithOtherCounterparties.Company AS Company
	|	,TemporaryTableSettlementsWithOtherCounterparties.Counterparty AS Counterparty
	|	,TemporaryTableSettlementsWithOtherCounterparties.Contract AS Contract
	|FROM
	|	TemporaryTableSettlementsWithOtherCounterparties AS TemporaryTableSettlementsWithOtherCounterparties";
	
	QueryResult = Query.Execute();
	
	Block = New DataLock;
	LockItem = Block.Add("AccumulationRegister.SettlementsWithOtherCounterparties");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = QueryResult;
	
	For Each ColumnQueryResult In QueryResult.Columns Do
		LockItem.UseFromDataSource(ColumnQueryResult.Name, ColumnQueryResult.Name);
	EndDo;
	Block.Lock();
	
	QueryNumber = 0;
	Query.Text = SmallBusinessServer.GetQueryTextExchangeRateDifferencesSettlementsWithOtherCounterparties(Query.TempTablesManager, False, QueryNumber);
	ResultsArray = Query.ExecuteBatch();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableSettlementsWithOtherCounterparties", ResultsArray[QueryNumber].Unload());
	
EndProcedure

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableIncomeAndExpenses(DocumentRefAdditionalCosts, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	1 AS LineNumber,
	|	DocumentTable.Date AS Period,
	|	DocumentTable.Company AS Company,
	|	UNDEFINED AS StructuralUnit,
	|	VALUE(Catalog.BusinessActivities.Other) AS BusinessActivity,
	|	UNDEFINED AS CustomerOrder,
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|			THEN &NegativeExchangeDifferenceAccountOfAccounting
	|		ELSE &PositiveExchangeDifferenceGLAccount
	|	END AS GLAccount,
	|	DocumentTable.Currency AS Analytics,
	|	&ExchangeDifference AS ContentOfAccountingRecord,
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|			THEN 0
	|		ELSE -DocumentTable.AmountOfExchangeDifferences
	|	END AS AmountIncome,
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|			THEN DocumentTable.AmountOfExchangeDifferences
	|		ELSE 0
	|	END AS AmountExpense,
	|	CASE
	|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
	|			THEN DocumentTable.AmountOfExchangeDifferences
	|		ELSE -DocumentTable.AmountOfExchangeDifferences
	|	END AS Amount
	|FROM
	|	(SELECT
	|		TableOfExchangeRateDifferencesAccountsPayable.Date AS Date,
	|		TableOfExchangeRateDifferencesAccountsPayable.Company AS Company,
	|		TableOfExchangeRateDifferencesAccountsPayable.Currency,
	|		SUM(TableOfExchangeRateDifferencesAccountsPayable.AmountOfExchangeDifferences) AS AmountOfExchangeDifferences
	|	FROM
	|		(SELECT
	|			DocumentTable.Date AS Date,
	|			DocumentTable.Company AS Company,
	|			DocumentTable.Currency,
	|			DocumentTable.AmountOfExchangeDifferences AS AmountOfExchangeDifferences
	|		FROM
	|			TemporaryTableCurrencyExchangeRateDifferencesSettlementsWithOtherCounterparties AS DocumentTable
	|		WHERE
	|			DocumentTable.SettlementsType = VALUE(Enum.SettlementsTypes.Debt)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			DocumentTable.Date,
	|			DocumentTable.Company,
	|			DocumentTable.Currency,
	|			DocumentTable.AmountOfExchangeDifferences
	|		FROM
	|			TemporaryTableCurrencyExchangeRateDifferencesSettlementsWithOtherCounterparties AS DocumentTable
	|		WHERE
	|			DocumentTable.SettlementsType = VALUE(Enum.SettlementsTypes.Advance)) AS TableOfExchangeRateDifferencesAccountsPayable
	|	
	|	GROUP BY
	|		TableOfExchangeRateDifferencesAccountsPayable.Date,
	|		TableOfExchangeRateDifferencesAccountsPayable.Company,
	|		TableOfExchangeRateDifferencesAccountsPayable.Currency
	|	
	|	HAVING
	|		(SUM(TableOfExchangeRateDifferencesAccountsPayable.AmountOfExchangeDifferences) >= 0.005
	|			OR SUM(TableOfExchangeRateDifferencesAccountsPayable.AmountOfExchangeDifferences) <= -0.005)) AS DocumentTable
	|
	|ORDER BY
	|	LineNumber";
	
	Query.SetParameter("PositiveExchangeDifferenceGLAccount", ChartsOfAccounts.Managerial.OtherIncome);
	Query.SetParameter("NegativeExchangeDifferenceAccountOfAccounting", ChartsOfAccounts.Managerial.OtherExpenses);
	Query.SetParameter("ExchangeDifference", NStr("en='Курсовая разница';ru='Курсовая разница';vi='Chênh lệch tỉ giá'"));
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableIncomeAndExpenses", QueryResult.Unload());
	
EndProcedure // СформироватьТаблицаДоходыИРасходы()

// Generates a table of values that contains the data for the register.
// Saves the tables of values in the properties of the structure "AdditionalProperties".
//
Procedure GenerateTableManagerial(DocumentRefAdditionalCosts, StructureAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	1 AS Order,
	|	TableCustomsFees.LineNumber AS LineNumber,
	|	TableCustomsFees.Period AS Period,
	|	TableCustomsFees.Company AS Company,
	|	VALUE(Catalog.PlanningPeriods.Actual) AS PlanningPeriod,
	|	TableCustomsFees.GLAccount AS AccountDr,
	|	CASE
	|		WHEN TableCustomsFees.GLAccount.Currency
	|			THEN TableCustomsFees.SettlementsCurrency
	|		ELSE UNDEFINED
	|	END AS CurrencyDr,
	|	CASE
	|		WHEN TableCustomsFees.GLAccount.Currency
	|			THEN TableCustomsFees.FeeAmountCur
	|		ELSE 0
	|	END AS AmountCurDr,
	|	TableCustomsFees.GLAccountVendorSettlements AS AccountCr,
	|	CASE
	|		WHEN TableCustomsFees.GLAccountVendorSettlements.Currency
	|			THEN TableCustomsFees.SettlementsCurrency
	|		ELSE UNDEFINED
	|	END AS CurrencyCr,
	|	CASE
	|		WHEN TableCustomsFees.GLAccountVendorSettlements.Currency
	|			THEN TableCustomsFees.FeeAmountCur
	|		ELSE 0
	|	END AS AmountCurCr,
	|	TableCustomsFees.FeeAmount AS Amount,
	|	&CustomsFee AS Content
	|INTO TemporaryTableManagementRegister
	|FROM
	|	TemporaryTableInventory AS TableCustomsFees
	|
	|UNION ALL
	|
	|SELECT
	|	1,
	|	TableCustomsDuty.LineNumber,
	|	TableCustomsDuty.Period,
	|	TableCustomsDuty.Company,
	|	VALUE(Catalog.PlanningPeriods.Actual),
	|	TableCustomsDuty.GLAccount,
	|	CASE
	|		WHEN TableCustomsDuty.GLAccount.Currency
	|			THEN TableCustomsDuty.SettlementsCurrency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN TableCustomsDuty.GLAccount.Currency
	|			THEN TableCustomsDuty.DutyAmountCur
	|		ELSE 0
	|	END,
	|	TableCustomsDuty.GLAccountVendorSettlements,
	|	CASE
	|		WHEN TableCustomsDuty.GLAccountVendorSettlements.Currency
	|			THEN TableCustomsDuty.SettlementsCurrency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN TableCustomsDuty.GLAccountVendorSettlements.Currency
	|			THEN TableCustomsDuty.DutyAmountCur
	|		ELSE 0
	|	END,
	|	TableCustomsDuty.DutyAmount,
	|	&CustomsDuty
	|FROM
	|	TemporaryTableInventory AS TableCustomsDuty
	|
	|UNION ALL
	|
	|SELECT
	|	2,
	|	TableCustomsFine.LineNumber,
	|	TableCustomsFine.Period,
	|	TableCustomsFine.Company,
	|	VALUE(Catalog.PlanningPeriods.Actual),
	|	TableCustomsFine.GLAccount,
	|	CASE
	|		WHEN TableCustomsFine.GLAccount.Currency
	|			THEN TableCustomsFine.SettlementsCurrency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN TableCustomsFine.GLAccount.Currency
	|			THEN TableCustomsFine.AmountFineCur
	|		ELSE 0
	|	END,
	|	TableCustomsFine.GLAccountVendorSettlements,
	|	CASE
	|		WHEN TableCustomsFine.GLAccountVendorSettlements.Currency
	|			THEN TableCustomsFine.SettlementsCurrency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN TableCustomsFine.GLAccountVendorSettlements.Currency
	|			THEN TableCustomsFine.AmountFineCur
	|		ELSE 0
	|	END,
	|	TableCustomsFine.AmountFine,
	|	&CustomsPenalty
	|FROM
	|	TemporaryTableExpenses AS TableCustomsFine
	|
	|UNION ALL
	|
	|SELECT
	|	3,
	|	TemporaryTableVAT.LineNumber,
	|	TemporaryTableVAT.Period,
	|	TemporaryTableVAT.Company,
	|	VALUE(Catalog.PlanningPeriods.Actual),
	|	TemporaryTableVAT.GLAccount,
	|	CASE
	|		WHEN TemporaryTableVAT.GLAccount.Currency
	|			THEN TemporaryTableVAT.SettlementsCurrency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN TemporaryTableVAT.GLAccount.Currency
	|			THEN TemporaryTableVAT.VATAmountCur
	|		ELSE 0
	|	END,
	|	TemporaryTableVAT.GLAccountVendorSettlements,
	|	CASE
	|		WHEN TemporaryTableVAT.GLAccountVendorSettlements.Currency
	|			THEN TemporaryTableVAT.SettlementsCurrency
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN TemporaryTableVAT.GLAccountVendorSettlements.Currency
	|			THEN TemporaryTableVAT.VATAmountCur
	|		ELSE 0
	|	END,
	|	TemporaryTableVAT.VATAmount,
	|	&CustomsVAT
	|FROM
	|	TemporaryTableVAT AS TemporaryTableVAT
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
	|			TemporaryTableCurrencyExchangeRateDifferencesSettlementsWithOtherCounterparties AS DocumentTable
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
	|			TemporaryTableCurrencyExchangeRateDifferencesSettlementsWithOtherCounterparties AS DocumentTable
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
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TemporaryTableManagementRegister.Order AS Order,
	|	TemporaryTableManagementRegister.LineNumber AS LineNumber,
	|	TemporaryTableManagementRegister.Period AS Period,
	|	TemporaryTableManagementRegister.Company AS Company,
	|	TemporaryTableManagementRegister.PlanningPeriod AS PlanningPeriod,
	|	TemporaryTableManagementRegister.AccountDr AS AccountDr,
	|	TemporaryTableManagementRegister.CurrencyDr AS CurrencyDr,
	|	TemporaryTableManagementRegister.AmountCurDr AS AmountCurDr,
	|	TemporaryTableManagementRegister.AccountCr AS AccountCr,
	|	TemporaryTableManagementRegister.CurrencyCr AS CurrencyCr,
	|	TemporaryTableManagementRegister.AmountCurCr AS AmountCurCr,
	|	TemporaryTableManagementRegister.Amount AS Amount,
	|	TemporaryTableManagementRegister.Content AS Content
	|FROM
	|	TemporaryTableManagementRegister AS TemporaryTableManagementRegister
	|WHERE
	|	TemporaryTableManagementRegister.Amount > 0
	|
	|ORDER BY
	|	Order,
	|	LineNumber";
	
	Query.SetParameter("CustomsFee", NStr("en='Сustoms duty';ru='Таможенный сбор';vi='Phí hải quan'"));
	Query.SetParameter("CustomsDuty", NStr("en='Сustoms fee';ru='Таможенная пошлина';vi='Thuế hải quan'"));
	Query.SetParameter("CustomsPenalty", NStr("en='Сustoms penalty';ru='Таможенный штраф';vi='Tiền phạt hải quan'"));
	Query.SetParameter("CustomsVAT", NStr("en='VAT amount paid to customs';ru='НДС, уплаченный таможенным органам';vi='Thuế GTGT đã nộp cho hải quan'"));
	Query.SetParameter("ExchangeDifference", NStr("en='Exchange difference';ru='Курсовая разница';vi='Chênh lệch tỉ giá'"));
	Query.SetParameter("PositiveExchangeDifferenceGLAccount", ChartsOfAccounts.Managerial.OtherIncome);
	Query.SetParameter("NegativeExchangeDifferenceAccountOfAccounting", ChartsOfAccounts.Managerial.OtherExpenses);
	
	QueryResult = Query.Execute();
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableManagerial", QueryResult.Unload());
	
EndProcedure // СформироватьТаблицаУправленческий()

#EndRegion


#EndIf
