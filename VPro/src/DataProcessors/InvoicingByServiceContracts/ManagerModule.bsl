 #If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region ProgramInterface

// Подготавливает информацию о выполнении актуальных договоров обслуживания (сколько оказано, выставлено, осталось выставить).
// Вызывается в фоновом задании из формы обработки выставления счетов.
//
// Parameters:
//  Parameters - Structure - Параметры, используемые для отбора данных. Обязательные ключи:
//					* BeginDate    - Date - Начало рассматриваемого интервала времени.
//					* EndDate - Date - Конец рассматриваемого интервала времени.
//					* Periodicity - EnumRef.BillingServiceContractPeriodicity - 
//													Периодичность рассматриваемых договоров.
//  ResultTempStorage - String - Возвращаемый в родительский сеанс параметр.
//											Хранит адрес результирующих данных во временном хранилище.
//
Procedure GetDataByServiceContracts(Parameters, ResultTempStorage) Export
	
	Var Errors;
	
	Result = New Structure;
	ExecuteDataReceivingByServiceContracts(Parameters, Result, Errors);
	IncludeErrorsInExecutionResult(Result, Errors);
	
	PutToTempStorage(Result, ResultTempStorage);
	
EndProcedure

// По выбранным договорам обслуживания выполняет создание документов (Счета на оплату, Акты выполненных работ)
// и актуализирует информацию (сколько оказано, выставлено, осталось выставить).
// Вызывается в фоновом задании из формы обработки выставления счетов.
//
// Parameters:
//  Parameters - Structure - Параметры, используемые для отбора данных. Обязательные ключи:
//					* BeginDate    - Date - Начало рассматриваемого интервала времени.
//					* EndDate - Date - Конец рассматриваемого интервала времени.
//					* DocumentsGenerationDateInvoices - Date
//					* DocumentGenerationDateActs  - Date
//					* Periodicities                         - СписокЗначений (ПеречислениеСсылка.БиллингПериодичностьДоговораОбслуживания)
//					* ListServiceContracts            - ValueTable
//					* ListServiceContractsExecution - ValueTable
//					* ListBillingDetails             - ValueTable
//					* GenerateActs                        - Boolean
//					* GenerateActsPost               - Boolean
//					* GenerateActsSendByEmail       - Boolean
//					* GenerateActsGenerateInvoices - Boolean
//					* GenerateInvoicesSendByEmail      - Boolean
//					* MessagePattern                          - CatalogRef.MessageTemplates
//  ResultTempStorage - String - Возвращаемый в родительский сеанс параметр.
//											Хранит адрес результирующих данных во временном хранилище.
//
Procedure CreateDocumentPackage(Parameters, ResultTempStorage) Export
	
	Var Errors;
	
	Result = New Structure;
	ExecuteDocumentPackageCreation(Parameters, Result, Errors);
	ExecuteDataReceivingByServiceContracts(Parameters, Result, Errors);
	IncludeErrorsInExecutionResult(Result, Errors);
	
	PutToTempStorage(Result, ResultTempStorage);
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

Procedure ExecuteDataReceivingByServiceContracts(Parameters, Result, Errors)
	
	ListServiceContracts = New ValueTable;
	ListServiceContracts.Columns.Add("GenerateInvoice",           New TypeDescription("Boolean"));
	ListServiceContracts.Columns.Add("GenerateAct",            New TypeDescription("Boolean"));
	ListServiceContracts.Columns.Add("PictureNumber",             New TypeDescription("Number",,, New NumberQualifiers(1,0,AllowedSign.Nonnegative)));
	ListServiceContracts.Columns.Add("DocumentsInvoicingDate", New TypeDescription("Date",,,,, New DateQualifiers(DateFractions.Date)));
	ListServiceContracts.Columns.Add("Counterparty",                New TypeDescription("CatalogRef.Counterparties"));
	ListServiceContracts.Columns.Add("Contract",                   New TypeDescription("CatalogRef.CounterpartyContracts"));
	ListServiceContracts.Columns.Add("TariffPlan",              New TypeDescription("CatalogRef.ServiceContractsTariffPlans"));
	ListServiceContracts.Columns.Add("Amount",                     New TypeDescription("Number", New NumberQualifiers(15, 3, AllowedSign.Nonnegative)));
	ListServiceContracts.Columns.Add("SettlementsCurrencyCharPresentation", New TypeDescription("String",,,, New StringQualifiers(3, AllowedLength.Variable)));
	ListServiceContracts.Columns.Add("HasItemsWithoutPrice",               New TypeDescription("Boolean"));
	ListServiceContracts.Columns.Add("HasItemsWithPrice",                New TypeDescription("Boolean"));
	ListServiceContracts.Columns.Add("HasItemsWithoutInvoicingAmount",   New TypeDescription("Boolean"));
	
	ListServiceContractsExecution = New ValueTable;
	ListServiceContractsExecution.Columns.Add("Contract",                  New TypeDescription("CatalogRef.CounterpartyContracts"));
	ListServiceContractsExecution.Columns.Add("ProductsAndServices",             New TypeDescription("CatalogRef.ProductsAndServices"));
	ListServiceContractsExecution.Columns.Add("CHARACTERISTIC",           New TypeDescription("CatalogRef.ProductsAndServicesCharacteristics"));
	ListServiceContractsExecution.Columns.Add("QuantityRenderedWithPrice",  New TypeDescription("Number", New NumberQualifiers(15, 3, AllowedSign.Nonnegative)));
	ListServiceContractsExecution.Columns.Add("QuantityRenderedWithoutPrice", New TypeDescription("Number", New NumberQualifiers(15, 3, AllowedSign.Nonnegative)));
	ListServiceContractsExecution.Columns.Add("AmountRenderedWithPrice",       New TypeDescription("Number", New NumberQualifiers(15, 2, AllowedSign.Nonnegative)));
	ListServiceContractsExecution.Columns.Add("AmountRenderedWithoutPrice",      New TypeDescription("Number", New NumberQualifiers(15, 2, AllowedSign.Nonnegative)));
	ListServiceContractsExecution.Columns.Add("QuantityInvoiced",     New TypeDescription("Number", New NumberQualifiers(15, 3, AllowedSign.Nonnegative)));
	ListServiceContractsExecution.Columns.Add("AmountInvoiced",          New TypeDescription("Number", New NumberQualifiers(15, 2, AllowedSign.Nonnegative)));
	ListServiceContractsExecution.Columns.Add("QuantityToInvoice",   New TypeDescription("Number", New NumberQualifiers(15, 3, AllowedSign.Nonnegative)));
	ListServiceContractsExecution.Columns.Add("AmountToInvoice",        New TypeDescription("Number", New NumberQualifiers(15, 2, AllowedSign.Nonnegative)));
	
	ListBillingDetails = New ValueTable;
	ListBillingDetails.Columns.Add("Contract",                    New TypeDescription("CatalogRef.CounterpartyContracts"));
	ListBillingDetails.Columns.Add("ServiceContractObject", New TypeDescription("CatalogRef.ProductsAndServices,ChartOfAccountsRef.Managerial"));
	ListBillingDetails.Columns.Add("CHARACTERISTIC",             New TypeDescription("CatalogRef.ProductsAndServicesCharacteristics"));
	ListBillingDetails.Columns.Add("PresentationInAccount",        New TypeDescription("CatalogRef.ProductsAndServices"));
	ListBillingDetails.Columns.Add("MeasurementUnit",           New TypeDescription("CatalogRef.UOMClassifier,CatalogRef.UOM"));
	ListBillingDetails.Columns.Add("Quantity",                 New TypeDescription("Number", New NumberQualifiers(15, 3, AllowedSign.Nonnegative)));
	ListBillingDetails.Columns.Add("Amount",                      New TypeDescription("Number", New NumberQualifiers(15, 2, AllowedSign.Nonnegative)));
	ListBillingDetails.Columns.Add("AddPeriodToContent", New TypeDescription("Boolean"));
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	CounterpartyContracts.Ref AS Contract,
	|	CASE
	|		WHEN CounterpartyContracts.ServiceContractPeriodicity = VALUE(Enum.BillingServiceContractPeriodicity.DAY)
	|			THEN &BeginDate
	|		WHEN CounterpartyContracts.ServiceContractPeriodicity = VALUE(Enum.BillingServiceContractPeriodicity.WEEK)
	|			THEN DATEADD(&BeginDate, DAY, CounterpartyContracts.ServiceContractDaysBeforeInvoicing - 1)
	|		WHEN CounterpartyContracts.ServiceContractPeriodicity = VALUE(Enum.BillingServiceContractPeriodicity.MONTH)
	|			THEN CASE
	|					WHEN DATEADD(&BeginDate, DAY, CounterpartyContracts.ServiceContractDaysBeforeInvoicing - 1) > &EndDate
	|						THEN &EndDate
	|					ELSE DATEADD(&BeginDate, DAY, CounterpartyContracts.ServiceContractDaysBeforeInvoicing - 1)
	|				END
	|		WHEN CounterpartyContracts.ServiceContractPeriodicity = VALUE(Enum.BillingServiceContractPeriodicity.QUARTER)
	|			THEN CASE
	|					WHEN DATEADD(DATEADD(BEGINOFPERIOD(&BeginDate, QUARTER), MONTH, CounterpartyContracts.ServiceContractMonthsBeforeInvoicing - 1), DAY, CounterpartyContracts.ServiceContractDaysBeforeInvoicing - 1) > ENDOFPERIOD(DATEADD(BEGINOFPERIOD(&BeginDate, QUARTER), MONTH, CounterpartyContracts.ServiceContractMonthsBeforeInvoicing - 1), MONTH)
	|						THEN ENDOFPERIOD(DATEADD(BEGINOFPERIOD(&BeginDate, QUARTER), MONTH, CounterpartyContracts.ServiceContractMonthsBeforeInvoicing - 1), MONTH)
	|					ELSE DATEADD(DATEADD(BEGINOFPERIOD(&BeginDate, QUARTER), MONTH, CounterpartyContracts.ServiceContractMonthsBeforeInvoicing - 1), DAY, CounterpartyContracts.ServiceContractDaysBeforeInvoicing - 1)
	|				END
	|		WHEN CounterpartyContracts.ServiceContractPeriodicity = VALUE(Enum.BillingServiceContractPeriodicity.HalfYear)
	|			THEN CASE
	|					WHEN DATEADD(DATEADD(BEGINOFPERIOD(&BeginDate, HALFYEAR), MONTH, CounterpartyContracts.ServiceContractMonthsBeforeInvoicing - 1), DAY, CounterpartyContracts.ServiceContractDaysBeforeInvoicing - 1) > ENDOFPERIOD(DATEADD(BEGINOFPERIOD(&BeginDate, HALFYEAR), MONTH, CounterpartyContracts.ServiceContractMonthsBeforeInvoicing - 1), MONTH)
	|						THEN ENDOFPERIOD(DATEADD(BEGINOFPERIOD(&BeginDate, HALFYEAR), MONTH, CounterpartyContracts.ServiceContractMonthsBeforeInvoicing - 1), MONTH)
	|					ELSE DATEADD(DATEADD(BEGINOFPERIOD(&BeginDate, HALFYEAR), MONTH, CounterpartyContracts.ServiceContractMonthsBeforeInvoicing - 1), DAY, CounterpartyContracts.ServiceContractDaysBeforeInvoicing - 1)
	|				END
	|		WHEN CounterpartyContracts.ServiceContractPeriodicity = VALUE(Enum.BillingServiceContractPeriodicity.YEAR)
	|			THEN CASE
	|					WHEN DATEADD(DATEADD(BEGINOFPERIOD(&BeginDate, YEAR), MONTH, CounterpartyContracts.ServiceContractMonthsBeforeInvoicing - 1), DAY, CounterpartyContracts.ServiceContractDaysBeforeInvoicing - 1) > ENDOFPERIOD(DATEADD(BEGINOFPERIOD(&BeginDate, YEAR), MONTH, CounterpartyContracts.ServiceContractMonthsBeforeInvoicing - 1), MONTH)
	|						THEN ENDOFPERIOD(DATEADD(BEGINOFPERIOD(&BeginDate, YEAR), MONTH, CounterpartyContracts.ServiceContractMonthsBeforeInvoicing - 1), MONTH)
	|					ELSE DATEADD(DATEADD(BEGINOFPERIOD(&BeginDate, YEAR), MONTH, CounterpartyContracts.ServiceContractMonthsBeforeInvoicing - 1), DAY, CounterpartyContracts.ServiceContractDaysBeforeInvoicing - 1)
	|				END
	|	END AS DocumentsInvoicingDate
	|INTO TTServiceContracts
	|FROM
	|	Catalog.CounterpartyContracts AS CounterpartyContracts
	|WHERE
	|	CounterpartyContracts.IsServiceContract
	|	AND CounterpartyContracts.ServiceContractStartDate <= &EndDate
	|	AND (CounterpartyContracts.ServiceContractEndDate = DATETIME(1, 1, 1, 0, 0, 0)
	|			OR CounterpartyContracts.ServiceContractEndDate >= &BeginDate)
	|	AND CounterpartyContracts.ServiceContractPeriodicity IN(&Periodicities)
	|	AND NOT CounterpartyContracts.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTServiceContracts.Contract AS Contract,
	|	TTServiceContracts.DocumentsInvoicingDate AS DocumentsInvoicingDate,
	|	CounterpartyContracts.ServiceContractStartDate AS BeginDate,
	|	CounterpartyContracts.Owner AS Counterparty,
	|	CounterpartyContracts.ServiceContractTariffPlan AS TariffPlan,
	|	CounterpartyContracts.PriceKind AS PriceKind,
//	|	CounterpartyContracts.SettlementsCurrency.SymbolicPresentation AS SettlementsCurrencyCharPresentation
	|	CounterpartyContracts.SettlementsCurrency.Description AS SettlementsCurrencyCharPresentation
	|INTO TTContractsCounterparties
	|FROM
	|	TTServiceContracts AS TTServiceContracts
	|		LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
	|		ON TTServiceContracts.Contract = CounterpartyContracts.Ref
	|WHERE
	|	TTServiceContracts.DocumentsInvoicingDate >= &BeginDate
	|	AND TTServiceContracts.DocumentsInvoicingDate <= &EndDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ServiceContractsTariffPlans.Ref AS TariffPlan,
	|	ServiceContractsTariffPlans.UnplannedItemsIncludeInInvoice AS UnplannedItemsIncludeInInvoice,
	|	ServiceContractsTariffPlans.UnplannedItemsPresentationInInvoice AS UnplannedItemsPresentationInInvoice,
	|	ServiceContractsTariffPlans.UnplannedCostsIncludeInInvoice AS UnplannedCostsIncludeInInvoice,
	|	ServiceContractsTariffPlans.UnplannedCostsPricingMethod AS UnplannedCostsPricingMethod,
	|	ServiceContractsTariffPlans.UnplannedCostsPresentationInInvoice AS UnplannedCostsPresentationInInvoice,
	|	ServiceContractsTariffPlans.UnplannedCostsFixedPrice AS UnplannedCostsFixedPrice,
	|	ServiceContractsTariffPlans.UnplannedCostsMarkup AS UnplannedCostsMarkup
	|INTO TTTariffPlansConditions
	|FROM
	|	Catalog.ServiceContractsTariffPlans AS ServiceContractsTariffPlans
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ServiceContractsTariffPlansProductsAndServicesAccounting.Ref AS TariffPlan,
	|	ServiceContractsTariffPlansProductsAndServicesAccounting.ProductsAndServices AS ServiceContractObject,
	|	ServiceContractsTariffPlansProductsAndServicesAccounting.CHARACTERISTIC AS CHARACTERISTIC,
	|	ServiceContractsTariffPlansProductsAndServicesAccounting.IncludeInInvoice AS IncludeInInvoice,
	|	CASE
	|		WHEN VALUETYPE(ServiceContractsTariffPlansProductsAndServicesAccounting.MeasurementUnit) = TYPE(Catalog.UOMClassifier)
	|			THEN ServiceContractsTariffPlansProductsAndServicesAccounting.Quantity
	|		ELSE ServiceContractsTariffPlansProductsAndServicesAccounting.Quantity / ServiceContractsTariffPlansProductsAndServicesAccounting.MeasurementUnit.Factor
	|	END AS Quantity,
	|	ServiceContractsTariffPlansProductsAndServicesAccounting.Price AS Price,
	|	ServiceContractsTariffPlansProductsAndServicesAccounting.MeasurementUnit AS MeasurementUnit,
	|	0 AS Discount,
	|	ServiceContractsTariffPlansProductsAndServicesAccounting.PricingMethod AS PricingMethod,
	|	ServiceContractsTariffPlansProductsAndServicesAccounting.PresentationInAccount AS PresentationInAccount,
	|	ServiceContractsTariffPlansProductsAndServicesAccounting.AddPeriodToContent AS AddPeriodToContent
	|INTO TTConditionsByTariffPlansItems
	|FROM
	|	Catalog.ServiceContractsTariffPlans.ProductsAndServicesAccounting AS ServiceContractsTariffPlansProductsAndServicesAccounting
	|
	|UNION
	|
	|SELECT
	|	ServiceContractsTariffPlansCostAccounting.Ref,
	|	ServiceContractsTariffPlansCostAccounting.CostsItem,
	|	VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef),
	|	ServiceContractsTariffPlansCostAccounting.IncludeInInvoice,
	|	0,
	|	ServiceContractsTariffPlansCostAccounting.Price,
	|	VALUE(Catalog.UOMClassifier.EmptyRef),
	|	ServiceContractsTariffPlansCostAccounting.Discount,
	|	ServiceContractsTariffPlansCostAccounting.PricingMethod,
	|	ServiceContractsTariffPlansCostAccounting.PresentationInAccount,
	|	ServiceContractsTariffPlansCostAccounting.AddPeriodToContent
	|FROM
	|	Catalog.ServiceContractsTariffPlans.CostAccounting AS ServiceContractsTariffPlansCostAccounting
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTContractsCounterparties.Contract AS Contract,
	|	TTConditionsByTariffPlansItems.ServiceContractObject AS ServiceContractObject,
	|	TTConditionsByTariffPlansItems.CHARACTERISTIC AS CHARACTERISTIC,
	|	TTConditionsByTariffPlansItems.IncludeInInvoice AS IncludeInInvoice,
	|	CASE
	|		WHEN VALUETYPE(TTConditionsByTariffPlansItems.MeasurementUnit) = TYPE(Catalog.UOMClassifier)
	|			THEN TTConditionsByTariffPlansItems.Quantity
	|		ELSE TTConditionsByTariffPlansItems.Quantity / TTConditionsByTariffPlansItems.MeasurementUnit.Factor
	|	END AS Quantity,
	|	TTConditionsByTariffPlansItems.Quantity * TTConditionsByTariffPlansItems.Price AS Amount,
	|	TTConditionsByTariffPlansItems.PresentationInAccount AS PresentationInAccount,
	|	TTConditionsByTariffPlansItems.AddPeriodToContent AS AddPeriodToContent
	|INTO TTServiceContractsSubscrPart
	|FROM
	|	TTContractsCounterparties AS TTContractsCounterparties
	|		INNER JOIN TTConditionsByTariffPlansItems AS TTConditionsByTariffPlansItems
	|		ON TTContractsCounterparties.TariffPlan = TTConditionsByTariffPlansItems.TariffPlan
	|WHERE
	|	TTConditionsByTariffPlansItems.Quantity <> 0
	|	AND TTConditionsByTariffPlansItems.PricingMethod = VALUE(Enum.BillingProductsAndServicesPricingMethod.FixedValue)
	|
	|UNION
	|
	|SELECT
	|	TTContractsCounterparties.Contract,
	|	TTConditionsByTariffPlansItems.ServiceContractObject,
	|	TTConditionsByTariffPlansItems.CHARACTERISTIC,
	|	TTConditionsByTariffPlansItems.IncludeInInvoice,
	|	TTConditionsByTariffPlansItems.Quantity,
	|	TTConditionsByTariffPlansItems.Quantity * ISNULL(ProductsAndServicesPricesSliceLast.Price, 0),
	|	TTConditionsByTariffPlansItems.PresentationInAccount,
	|	TTConditionsByTariffPlansItems.AddPeriodToContent
	|FROM
	|	TTContractsCounterparties AS TTContractsCounterparties
	|		INNER JOIN TTConditionsByTariffPlansItems AS TTConditionsByTariffPlansItems
	|		ON TTContractsCounterparties.TariffPlan = TTConditionsByTariffPlansItems.TariffPlan
	|		LEFT JOIN InformationRegister.ProductsAndServicesPrices.SliceLast(&DocumentsGenerationDateInvoices, ) AS ProductsAndServicesPricesSliceLast
	|		ON (ProductsAndServicesPricesSliceLast.PriceKind = TTContractsCounterparties.PriceKind)
	|			AND (ProductsAndServicesPricesSliceLast.ProductsAndServices = TTConditionsByTariffPlansItems.ServiceContractObject)
	|			AND (ProductsAndServicesPricesSliceLast.CHARACTERISTIC = TTConditionsByTariffPlansItems.CHARACTERISTIC)
	|WHERE
	|	TTConditionsByTariffPlansItems.Quantity <> 0
	|	AND TTConditionsByTariffPlansItems.PricingMethod = VALUE(Enum.BillingProductsAndServicesPricingMethod.ByContractPriceKind)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTContractsCounterparties.Contract AS Contract,
	|	TTContractsCounterparties.TariffPlan AS TariffPlan,
	|	ServiceContractsExecutionTurnovers.ServiceContractObject AS ServiceContractObject,
	|	ServiceContractsExecutionTurnovers.CHARACTERISTIC AS CHARACTERISTIC,
	|	ServiceContractsExecutionTurnovers.CostSpecified AS CostSpecified,
	|	ServiceContractsExecutionTurnovers.QuantityTurnover AS Quantity,
	|	CASE
	|		WHEN ServiceContractsExecutionTurnovers.ServiceContractObject REFS Catalog.ProductsAndServices
	|			THEN ServiceContractsExecutionTurnovers.AmountTurnover
	|		ELSE CASE
	|				WHEN ISNULL(TTConditionsByTariffPlansItems.PricingMethod, TTTariffPlansConditions.UnplannedCostsPricingMethod) = VALUE(Enum.BillingCostsPricingMethod.ByCost)
	|					THEN ServiceContractsExecutionTurnovers.AmountTurnover
	|				WHEN ISNULL(TTConditionsByTariffPlansItems.PricingMethod, TTTariffPlansConditions.UnplannedCostsPricingMethod) = VALUE(Enum.BillingCostsPricingMethod.ByCostWithMarkup)
	|					THEN ServiceContractsExecutionTurnovers.AmountTurnover + ServiceContractsExecutionTurnovers.AmountTurnover * ISNULL(TTConditionsByTariffPlansItems.Discount, TTTariffPlansConditions.UnplannedCostsMarkup) / 100
	|				WHEN ISNULL(TTConditionsByTariffPlansItems.PricingMethod, TTTariffPlansConditions.UnplannedCostsPricingMethod) = VALUE(Enum.BillingCostsPricingMethod.FixedValue)
	|					THEN ISNULL(TTConditionsByTariffPlansItems.Price, TTTariffPlansConditions.UnplannedCostsFixedPrice) * ServiceContractsExecutionTurnovers.QuantityTurnover
	|			END
	|	END AS Amount,
	|	CASE
	|		WHEN ServiceContractsExecutionTurnovers.ServiceContractObject REFS Catalog.ProductsAndServices
	|			THEN ISNULL(TTConditionsByTariffPlansItems.PresentationInAccount, TTTariffPlansConditions.UnplannedItemsPresentationInInvoice)
	|		ELSE ISNULL(TTConditionsByTariffPlansItems.PresentationInAccount, TTTariffPlansConditions.UnplannedCostsPresentationInInvoice)
	|	END AS PresentationInAccount,
	|	CASE
	|		WHEN ServiceContractsExecutionTurnovers.ServiceContractObject REFS Catalog.ProductsAndServices
	|			THEN ISNULL(TTConditionsByTariffPlansItems.IncludeInInvoice, TTTariffPlansConditions.UnplannedItemsIncludeInInvoice)
	|		ELSE ISNULL(TTConditionsByTariffPlansItems.IncludeInInvoice, TTTariffPlansConditions.UnplannedCostsIncludeInInvoice)
	|	END AS IncludeInInvoice
	|INTO TTTurnovers
	|FROM
	|	AccumulationRegister.ServiceContractsExecution.Turnovers(&StartDateBoundary, &EndDateBoundary, , ) AS ServiceContractsExecutionTurnovers
	|		LEFT JOIN TTContractsCounterparties AS TTContractsCounterparties
	|		ON ServiceContractsExecutionTurnovers.Contract = TTContractsCounterparties.Contract
	|		LEFT JOIN TTConditionsByTariffPlansItems AS TTConditionsByTariffPlansItems
	|		ON (TTContractsCounterparties.TariffPlan = TTConditionsByTariffPlansItems.TariffPlan)
	|			AND ServiceContractsExecutionTurnovers.ServiceContractObject = TTConditionsByTariffPlansItems.ServiceContractObject
	|			AND ServiceContractsExecutionTurnovers.ServiceContractObject = TTConditionsByTariffPlansItems.ServiceContractObject
	|		LEFT JOIN TTTariffPlansConditions AS TTTariffPlansConditions
	|		ON (TTContractsCounterparties.TariffPlan = TTTariffPlansConditions.TariffPlan)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTTurnovers.Contract AS Contract,
	|	TTTurnovers.TariffPlan AS TariffPlan,
	|	TTTurnovers.ServiceContractObject AS ServiceContractObject,
	|	TTTurnovers.CHARACTERISTIC AS CHARACTERISTIC,
	|	TTTurnovers.Quantity AS QuantityWithPrice,
	|	TTTurnovers.Amount AS AmountWithPrice,
	|	0 AS QuantityWithoutPrice,
	|	0 AS AmountWithoutPrice,
	|	0 AS PriceByPriceKind,
	|	TTTurnovers.PresentationInAccount AS PresentationInAccount,
	|	TTTurnovers.IncludeInInvoice AS IncludeInInvoice
	|INTO TTTurnoversRenderedWithoutGrouping
	|FROM
	|	TTTurnovers AS TTTurnovers
	|WHERE
	|	TTTurnovers.CostSpecified
	|
	|UNION
	|
	|SELECT
	|	TTTurnovers.Contract,
	|	TTTurnovers.TariffPlan,
	|	TTTurnovers.ServiceContractObject,
	|	TTTurnovers.CHARACTERISTIC,
	|	0,
	|	0,
	|	TTTurnovers.Quantity,
	|	TTTurnovers.Quantity * ISNULL(ProductsAndServicesPricesSliceLast.Price, 0),
	|	ISNULL(ProductsAndServicesPricesSliceLast.Price, 0),
	|	TTTurnovers.PresentationInAccount,
	|	TTTurnovers.IncludeInInvoice
	|FROM
	|	TTTurnovers AS TTTurnovers
	|		LEFT JOIN TTContractsCounterparties AS TTContractsCounterparties
	|		ON TTTurnovers.Contract = TTContractsCounterparties.Contract
	|		LEFT JOIN InformationRegister.ProductsAndServicesPrices.SliceLast(&DocumentsGenerationDateInvoices, ) AS ProductsAndServicesPricesSliceLast
	|		ON (ProductsAndServicesPricesSliceLast.PriceKind = TTContractsCounterparties.PriceKind)
	|			AND (ProductsAndServicesPricesSliceLast.ProductsAndServices = TTTurnovers.ServiceContractObject)
	|			AND (ProductsAndServicesPricesSliceLast.CHARACTERISTIC = TTTurnovers.CHARACTERISTIC)
	|WHERE
	|	NOT TTTurnovers.CostSpecified
	|	AND VALUETYPE(TTTurnovers.ServiceContractObject) = TYPE(Catalog.ProductsAndServices)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTTurnoversRenderedWithoutGrouping.Contract AS Contract,
	|	TTTurnoversRenderedWithoutGrouping.TariffPlan AS TariffPlan,
	|	TTTurnoversRenderedWithoutGrouping.ServiceContractObject AS ServiceContractObject,
	|	TTTurnoversRenderedWithoutGrouping.CHARACTERISTIC AS CHARACTERISTIC,
	|	SUM(TTTurnoversRenderedWithoutGrouping.QuantityWithPrice) AS QuantityWithPrice,
	|	SUM(TTTurnoversRenderedWithoutGrouping.AmountWithPrice) AS AmountWithPrice,
	|	SUM(TTTurnoversRenderedWithoutGrouping.QuantityWithoutPrice) AS QuantityWithoutPrice,
	|	SUM(TTTurnoversRenderedWithoutGrouping.AmountWithoutPrice) AS AmountWithoutPrice,
	|	SUM(TTTurnoversRenderedWithoutGrouping.PriceByPriceKind) AS PriceByPriceKind,
	|	TTTurnoversRenderedWithoutGrouping.PresentationInAccount AS PresentationInAccount,
	|	TTTurnoversRenderedWithoutGrouping.IncludeInInvoice AS IncludeInInvoice
	|INTO TTTurnoversRendered
	|FROM
	|	TTTurnoversRenderedWithoutGrouping AS TTTurnoversRenderedWithoutGrouping
	|
	|GROUP BY
	|	TTTurnoversRenderedWithoutGrouping.Contract,
	|	TTTurnoversRenderedWithoutGrouping.TariffPlan,
	|	TTTurnoversRenderedWithoutGrouping.ServiceContractObject,
	|	TTTurnoversRenderedWithoutGrouping.CHARACTERISTIC,
	|	TTTurnoversRenderedWithoutGrouping.IncludeInInvoice,
	|	TTTurnoversRenderedWithoutGrouping.PresentationInAccount
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	InvoiceForPayment.Ref AS Ref,
	|	TTServiceContracts.Contract AS Contract
	|INTO TTInvoicesByServiceContracts
	|FROM
	|	TTServiceContracts AS TTServiceContracts
	|		INNER JOIN Document.InvoiceForPayment AS InvoiceForPayment
	|		ON TTServiceContracts.Contract = InvoiceForPayment.Contract
	|WHERE
	|	InvoiceForPayment.Posted
	|	AND InvoiceForPayment.Date >= &BeginDate
	|	AND InvoiceForPayment.Date <= &EndDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTInvoicesByServiceContracts.Contract AS Contract,
	|	InvoiceForPaymentBillingDetails.ServiceContractObject AS ServiceContractObject,
	|	InvoiceForPaymentBillingDetails.CHARACTERISTIC AS CHARACTERISTIC,
	|	SUM(CASE
	|			WHEN InvoiceForPaymentBillingDetails.MeasurementUnit = UNDEFINED
	|				THEN InvoiceForPaymentBillingDetails.Quantity
	|			WHEN VALUETYPE(InvoiceForPaymentBillingDetails.MeasurementUnit) = TYPE(Catalog.UOMClassifier)
	|				THEN InvoiceForPaymentBillingDetails.Quantity
	|			ELSE InvoiceForPaymentBillingDetails.Quantity / InvoiceForPaymentBillingDetails.MeasurementUnit.Factor
	|		END) AS Quantity,
	|	SUM(InvoiceForPaymentBillingDetails.Amount) AS Amount
	|INTO TTTurnoversInvoiced
	|FROM
	|	TTInvoicesByServiceContracts AS TTInvoicesByServiceContracts
	|		LEFT JOIN Document.InvoiceForPayment.BillingDetails AS InvoiceForPaymentBillingDetails
	|		ON TTInvoicesByServiceContracts.Ref = InvoiceForPaymentBillingDetails.Ref
	|
	|GROUP BY
	|	TTInvoicesByServiceContracts.Contract,
	|	InvoiceForPaymentBillingDetails.ServiceContractObject,
	|	InvoiceForPaymentBillingDetails.CHARACTERISTIC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(TTServiceContractsSubscrPart.Contract, TTTurnoversRendered.Contract) AS Contract,
	|	ISNULL(TTServiceContractsSubscrPart.ServiceContractObject, TTTurnoversRendered.ServiceContractObject) AS ServiceContractObject,
	|	ISNULL(TTServiceContractsSubscrPart.CHARACTERISTIC, TTTurnoversRendered.CHARACTERISTIC) AS CHARACTERISTIC,
	|	ISNULL(TTServiceContractsSubscrPart.PresentationInAccount, TTTurnoversRendered.PresentationInAccount) AS PresentationInAccount,
	|	ISNULL(TTServiceContractsSubscrPart.AddPeriodToContent, FALSE) AS AddPeriodToContent,
	|	ISNULL(TTServiceContractsSubscrPart.IncludeInInvoice, TTTurnoversRendered.IncludeInInvoice) AS IncludeInInvoice,
	|	ISNULL(TTServiceContractsSubscrPart.Quantity, 0) AS ContractQuantity,
	|	ISNULL(TTServiceContractsSubscrPart.Amount, 0) AS ContractAmount,
	|	ISNULL(TTTurnoversRendered.QuantityWithPrice, 0) AS QuantityRenderedWithPrice,
	|	ISNULL(TTTurnoversRendered.AmountWithPrice, 0) AS AmountRenderedWithPrice,
	|	ISNULL(TTTurnoversRendered.QuantityWithoutPrice, 0) AS QuantityRenderedWithoutPrice,
	|	ISNULL(TTTurnoversRendered.PriceByPriceKind, 0) AS PriceByPriceKind,
	|	ISNULL(TTTurnoversRendered.AmountWithoutPrice, 0) AS AmountRenderedWithoutPrice,
	|	ISNULL(TTTurnoversInvoiced.Quantity, 0) AS QuantityInvoiced,
	|	ISNULL(TTTurnoversInvoiced.Amount, 0) AS AmountInvoiced
	|INTO TTAllTurnovers
	|FROM
	|	TTServiceContractsSubscrPart AS TTServiceContractsSubscrPart
	|		FULL JOIN TTTurnoversRendered AS TTTurnoversRendered
	|		ON TTServiceContractsSubscrPart.Contract = TTTurnoversRendered.Contract
	|			AND TTServiceContractsSubscrPart.ServiceContractObject = TTTurnoversRendered.ServiceContractObject
	|			AND TTServiceContractsSubscrPart.CHARACTERISTIC = TTTurnoversRendered.CHARACTERISTIC
	|		LEFT JOIN TTTurnoversInvoiced AS TTTurnoversInvoiced
	|		ON (ISNULL(TTServiceContractsSubscrPart.Contract, TTTurnoversRendered.Contract) = TTTurnoversInvoiced.Contract)
	|			AND (ISNULL(TTServiceContractsSubscrPart.ServiceContractObject, TTTurnoversRendered.ServiceContractObject) = TTTurnoversInvoiced.ServiceContractObject)
	|			AND (ISNULL(TTServiceContractsSubscrPart.CHARACTERISTIC, TTTurnoversRendered.CHARACTERISTIC) = TTTurnoversInvoiced.CHARACTERISTIC)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTAllTurnovers.Contract AS Contract,
	|	TTAllTurnovers.ServiceContractObject AS ServiceContractObject,
	|	TTAllTurnovers.CHARACTERISTIC AS CHARACTERISTIC,
	|	TTAllTurnovers.PresentationInAccount AS PresentationInAccount,
	|	TTAllTurnovers.AddPeriodToContent AS AddPeriodToContent,
	|	TTAllTurnovers.IncludeInInvoice AS IncludeInInvoice,
	|	CASE
	|		WHEN VALUETYPE(TTConditionsByTariffPlansItems.MeasurementUnit) = TYPE(Catalog.UOMClassifier)
	|				OR TTConditionsByTariffPlansItems.MeasurementUnit IS NULL
	|			THEN TTAllTurnovers.ContractQuantity
	|		ELSE TTAllTurnovers.ContractQuantity * TTConditionsByTariffPlansItems.MeasurementUnit.Factor
	|	END AS ContractQuantity,
	|	TTAllTurnovers.ContractAmount AS ContractAmount,
	|	CASE
	|		WHEN VALUETYPE(TTConditionsByTariffPlansItems.MeasurementUnit) = TYPE(Catalog.UOMClassifier)
	|				OR TTConditionsByTariffPlansItems.MeasurementUnit IS NULL
	|			THEN TTAllTurnovers.QuantityRenderedWithPrice
	|		ELSE TTAllTurnovers.QuantityRenderedWithPrice * TTConditionsByTariffPlansItems.MeasurementUnit.Factor
	|	END AS QuantityRenderedWithPrice,
	|	TTAllTurnovers.AmountRenderedWithPrice AS AmountRenderedWithPrice,
	|	CASE
	|		WHEN VALUETYPE(TTConditionsByTariffPlansItems.MeasurementUnit) = TYPE(Catalog.UOMClassifier)
	|				OR TTConditionsByTariffPlansItems.MeasurementUnit IS NULL
	|			THEN TTAllTurnovers.QuantityRenderedWithoutPrice
	|		ELSE TTAllTurnovers.QuantityRenderedWithoutPrice * TTConditionsByTariffPlansItems.MeasurementUnit.Factor
	|	END AS QuantityRenderedWithoutPrice,
	|	TTAllTurnovers.PriceByPriceKind AS PriceByPriceKind,
	|	TTAllTurnovers.AmountRenderedWithoutPrice AS AmountRenderedWithoutPrice,
	|	CASE
	|		WHEN VALUETYPE(TTConditionsByTariffPlansItems.MeasurementUnit) = TYPE(Catalog.UOMClassifier)
	|				OR TTConditionsByTariffPlansItems.MeasurementUnit IS NULL
	|			THEN TTAllTurnovers.QuantityInvoiced
	|		ELSE TTAllTurnovers.QuantityInvoiced * TTConditionsByTariffPlansItems.MeasurementUnit.Factor
	|	END AS QuantityInvoiced,
	|	TTAllTurnovers.AmountInvoiced AS AmountInvoiced,
	|	CASE
	|		WHEN NOT TTConditionsByTariffPlansItems.MeasurementUnit IS NULL
	|			THEN TTConditionsByTariffPlansItems.MeasurementUnit
	|		WHEN TTConditionsByTariffPlansItems.MeasurementUnit IS NULL
	|				AND VALUETYPE(TTAllTurnovers.ServiceContractObject) = TYPE(Catalog.ProductsAndServices)
	|			THEN TTAllTurnovers.ServiceContractObject.MeasurementUnit
	|		ELSE NULL
	|	END AS MeasurementUnit
	|INTO TTAllTurnoversInMeasurementUnits
	|FROM
	|	TTAllTurnovers AS TTAllTurnovers
	|		LEFT JOIN TTConditionsByTariffPlansItems AS TTConditionsByTariffPlansItems
	|		ON TTAllTurnovers.Contract.ServiceContractTariffPlan = TTConditionsByTariffPlansItems.TariffPlan
	|			AND TTAllTurnovers.ServiceContractObject = TTConditionsByTariffPlansItems.ServiceContractObject
	|			AND TTAllTurnovers.CHARACTERISTIC = TTConditionsByTariffPlansItems.CHARACTERISTIC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTContractsCounterparties.Counterparty AS Counterparty,
	|	TTContractsCounterparties.TariffPlan AS TariffPlan,
	|	TTAllTurnoversInMeasurementUnits.Contract AS Contract,
	|	TTContractsCounterparties.DocumentsInvoicingDate AS DocumentsInvoicingDate,
	|	TTContractsCounterparties.SettlementsCurrencyCharPresentation AS SettlementsCurrencyCharPresentation,
	|	CASE
	|		WHEN TTAllTurnoversInMeasurementUnits.PresentationInAccount <> VALUE(Catalog.ProductsAndServices.EmptyRef)
	|			THEN TTAllTurnoversInMeasurementUnits.PresentationInAccount
	|		ELSE TTAllTurnoversInMeasurementUnits.ServiceContractObject
	|	END AS ProductsAndServices,
	|	CASE
	|		WHEN TTAllTurnoversInMeasurementUnits.PresentationInAccount <> VALUE(Catalog.ProductsAndServices.EmptyRef)
	|			THEN VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	|		ELSE TTAllTurnoversInMeasurementUnits.CHARACTERISTIC
	|	END AS CHARACTERISTIC,
	|	SUM(TTAllTurnoversInMeasurementUnits.ContractQuantity) AS ContractQuantity,
	|	SUM(TTAllTurnoversInMeasurementUnits.ContractAmount) AS ContractAmount,
	|	SUM(TTAllTurnoversInMeasurementUnits.QuantityRenderedWithPrice) AS QuantityRenderedWithPrice,
	|	SUM(TTAllTurnoversInMeasurementUnits.AmountRenderedWithPrice) AS AmountRenderedWithPrice,
	|	SUM(TTAllTurnoversInMeasurementUnits.QuantityRenderedWithoutPrice) AS QuantityRenderedWithoutPrice,
	|	SUM(TTAllTurnoversInMeasurementUnits.AmountRenderedWithoutPrice) AS AmountRenderedWithoutPrice,
	|	TTAllTurnoversInMeasurementUnits.PriceByPriceKind AS PriceByPriceKind,
	|	SUM(TTAllTurnoversInMeasurementUnits.QuantityInvoiced) AS QuantityInvoiced,
	|	SUM(TTAllTurnoversInMeasurementUnits.AmountInvoiced) AS AmountInvoiced
	|FROM
	|	TTAllTurnoversInMeasurementUnits AS TTAllTurnoversInMeasurementUnits
	|		FULL JOIN TTContractsCounterparties AS TTContractsCounterparties
	|		ON TTAllTurnoversInMeasurementUnits.Contract = TTContractsCounterparties.Contract
	|WHERE
	|	TTAllTurnoversInMeasurementUnits.IncludeInInvoice
	|
	|GROUP BY
	|	TTContractsCounterparties.Counterparty,
	|	TTContractsCounterparties.TariffPlan,
	|	TTAllTurnoversInMeasurementUnits.Contract,
	|	TTContractsCounterparties.DocumentsInvoicingDate,
	|	TTContractsCounterparties.SettlementsCurrencyCharPresentation,
	|	CASE
	|		WHEN TTAllTurnoversInMeasurementUnits.PresentationInAccount <> VALUE(Catalog.ProductsAndServices.EmptyRef)
	|			THEN TTAllTurnoversInMeasurementUnits.PresentationInAccount
	|		ELSE TTAllTurnoversInMeasurementUnits.ServiceContractObject
	|	END,
	|	CASE
	|		WHEN TTAllTurnoversInMeasurementUnits.PresentationInAccount <> VALUE(Catalog.ProductsAndServices.EmptyRef)
	|			THEN VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	|		ELSE TTAllTurnoversInMeasurementUnits.CHARACTERISTIC
	|	END,
	|	TTAllTurnoversInMeasurementUnits.PriceByPriceKind
	|
	|ORDER BY
	|	DocumentsInvoicingDate
	|TOTALS BY
	|	Contract
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTAllTurnoversInMeasurementUnits.Contract AS Contract,
	|	TTAllTurnoversInMeasurementUnits.ServiceContractObject AS ServiceContractObject,
	|	TTAllTurnoversInMeasurementUnits.CHARACTERISTIC AS CHARACTERISTIC,
	|	TTAllTurnoversInMeasurementUnits.PresentationInAccount AS PresentationInAccount,
	|	TTAllTurnoversInMeasurementUnits.MeasurementUnit AS MeasurementUnit,
	|	TTAllTurnoversInMeasurementUnits.ContractQuantity AS ContractQuantity,
	|	TTAllTurnoversInMeasurementUnits.ContractAmount AS ContractAmount,
	|	TTAllTurnoversInMeasurementUnits.QuantityRenderedWithPrice AS QuantityRenderedWithPrice,
	|	TTAllTurnoversInMeasurementUnits.AmountRenderedWithPrice AS AmountRenderedWithPrice,
	|	TTAllTurnoversInMeasurementUnits.QuantityRenderedWithoutPrice AS QuantityRenderedWithoutPrice,
	|	TTAllTurnoversInMeasurementUnits.AmountRenderedWithoutPrice AS AmountRenderedWithoutPrice,
	|	TTAllTurnoversInMeasurementUnits.PriceByPriceKind AS PriceByPriceKind,
	|	TTAllTurnoversInMeasurementUnits.QuantityInvoiced AS QuantityInvoiced,
	|	TTAllTurnoversInMeasurementUnits.AmountInvoiced AS AmountInvoiced,
	|	TTAllTurnoversInMeasurementUnits.AddPeriodToContent AS AddPeriodToContent
	|FROM
	|	TTAllTurnoversInMeasurementUnits AS TTAllTurnoversInMeasurementUnits
	|WHERE
	|	TTAllTurnoversInMeasurementUnits.IncludeInInvoice";
	
	Query.SetParameter("StartDateBoundary", New Boundary(Parameters.BeginDate, BoundaryType.Including));
	Query.SetParameter("EndDateBoundary", New Boundary(Parameters.EndDate, BoundaryType.Including));
	Query.SetParameter("BeginDate", Parameters.BeginDate);
	Query.SetParameter("EndDate", Parameters.EndDate);
	Query.SetParameter("DocumentsGenerationDateInvoices", Parameters.DocumentsGenerationDateInvoices);
	Query.SetParameter("Periodicities", Parameters.Periodicities);
	Query.SetParameter("CurrentSessionDate", BegOfDay(CurrentSessionDate()));
	
	QueryResult = Query.ExecuteBatch();
	
	SelectionContracts = QueryResult[12].Select(QueryResultIteration.ByGroupsWithHierarchy);
	
	MarksCounterInvoices = 0;
	MarkCounterActs = 0;
	
	CurrentDate = BegOfDay(CurrentSessionDate());
	
	While SelectionContracts.Next() Do
		
		HasItemsWithoutPrice = False;
		HasItemsWithPrice = False;
		HasItemsWithoutInvoicingAmount = False;
		
		DocumentsInvoicingDate = Undefined;
		PictureNumber = Undefined;
		Contract       = Undefined;
		Counterparty    = Undefined;
		TariffPlan  = Undefined;
		SettlementsCurrencyCharPresentation = Undefined;
		QuantityToInvoice = 0;
		AmountToInvoice      = 0;
		
		SelectionTurnovers = SelectionContracts.Select();
		Iterator = 0;
		While SelectionTurnovers.Next() Do
			
			DocumentsInvoicingDate = SelectionTurnovers.DocumentsInvoicingDate;
			Contract       = SelectionTurnovers.Contract;
			Counterparty    = SelectionTurnovers.Counterparty;
			TariffPlan  = SelectionTurnovers.TariffPlan;
			SettlementsCurrencyCharPresentation = SelectionTurnovers.SettlementsCurrencyCharPresentation;
			
			If SelectionTurnovers.ProductsAndServices = Null
				Or Not ValueIsFilled(SelectionTurnovers.ProductsAndServices) Then
				Continue;
			EndIf;
			
			NewRow = ListServiceContractsExecution.Add();
			NewRow.Contract                    = SelectionTurnovers.Contract;
			NewRow.ProductsAndServices               = SelectionTurnovers.ProductsAndServices;
			NewRow.CHARACTERISTIC             = SelectionTurnovers.CHARACTERISTIC;
			NewRow.QuantityRenderedWithPrice    = SelectionTurnovers.QuantityRenderedWithPrice;
			NewRow.QuantityRenderedWithoutPrice   = SelectionTurnovers.QuantityRenderedWithoutPrice;
			NewRow.AmountRenderedWithPrice         = SelectionTurnovers.AmountRenderedWithPrice;
			NewRow.AmountRenderedWithoutPrice        = SelectionTurnovers.AmountRenderedWithoutPrice;
			NewRow.QuantityInvoiced       = SelectionTurnovers.QuantityInvoiced;
			NewRow.AmountInvoiced            = SelectionTurnovers.AmountInvoiced;
			
			// Добавляем абонентские условия.
			If NewRow.QuantityRenderedWithPrice <= SelectionTurnovers.ContractQuantity Then
				
				ReplacedQuantityWithPrice = SelectionTurnovers.ContractQuantity - NewRow.QuantityRenderedWithPrice;
				If NewRow.QuantityRenderedWithoutPrice > ReplacedQuantityWithPrice Then
					NewRow.QuantityRenderedWithoutPrice = NewRow.QuantityRenderedWithoutPrice - ReplacedQuantityWithPrice;
					NewRow.AmountRenderedWithoutPrice = NewRow.QuantityRenderedWithoutPrice * SelectionTurnovers.PriceByPriceKind;
				Else
					NewRow.QuantityRenderedWithoutPrice = 0;
					NewRow.AmountRenderedWithoutPrice = 0;
				EndIf;
				
				NewRow.QuantityRenderedWithPrice = SelectionTurnovers.ContractQuantity;
				NewRow.AmountRenderedWithPrice      = SelectionTurnovers.ContractAmount;
				
			EndIf;
			
			NewRow.QuantityToInvoice =
				NewRow.QuantityRenderedWithPrice +
				NewRow.QuantityRenderedWithoutPrice -
				NewRow.QuantityInvoiced
			;
			
			NewRow.AmountToInvoice =
				NewRow.AmountRenderedWithPrice +
				NewRow.AmountRenderedWithoutPrice -
				NewRow.AmountInvoiced
			;
			
			If NewRow.AmountToInvoice = 0 Then
				PictureNumber = 0;
			Else
				If DocumentsInvoicingDate > CurrentDate Then
					PictureNumber = 1;
				ElsIf DocumentsInvoicingDate = CurrentDate Then
					PictureNumber = 2;
				ElsIf DocumentsInvoicingDate < CurrentDate Then
					PictureNumber = 3;
				EndIf;
			EndIf;
			
			QuantityToInvoice = QuantityToInvoice + NewRow.QuantityToInvoice;
			AmountToInvoice = AmountToInvoice + NewRow.AmountToInvoice;
			
			If NewRow.QuantityRenderedWithPrice <> 0 Then
				HasItemsWithPrice = True;
			EndIf;
			
			If NewRow.QuantityRenderedWithoutPrice <> 0 Then
				HasItemsWithoutPrice = True;
			EndIf;
			
			// Проверяем на то, есть ли цена для позиции.
			If NewRow.QuantityRenderedWithoutPrice <> 0 And NewRow.AmountRenderedWithoutPrice = 0
				Or NewRow.QuantityRenderedWithPrice <> 0 And NewRow.AmountRenderedWithPrice = 0 Then
				
				HasItemsWithoutInvoicingAmount = True;
				
			EndIf;
			
			Iterator = Iterator + 1;
			
		EndDo;
		
		NewRow = ListServiceContracts.Add();
		NewRow.GenerateInvoice           = QuantityToInvoice <> 0 And AmountToInvoice <> 0;
		NewRow.GenerateAct            = QuantityToInvoice <> 0 And AmountToInvoice <> 0;
		NewRow.DocumentsInvoicingDate = DocumentsInvoicingDate;
		NewRow.PictureNumber             = PictureNumber;
		NewRow.Counterparty                = Counterparty;
		NewRow.Contract                   = Contract;
		NewRow.TariffPlan              = TariffPlan;
		NewRow.Amount                     = AmountToInvoice;
		NewRow.SettlementsCurrencyCharPresentation = ?(ValueIsFilled(AmountToInvoice), SettlementsCurrencyCharPresentation, "");
		
		NewRow.HasItemsWithPrice  = HasItemsWithPrice;
		NewRow.HasItemsWithoutPrice = HasItemsWithoutPrice;
		NewRow.HasItemsWithoutInvoicingAmount = HasItemsWithoutInvoicingAmount;
		
		If NewRow.GenerateInvoice Then
			MarksCounterInvoices = MarksCounterInvoices + 1;
		EndIf;
		If NewRow.GenerateAct Then
			MarkCounterActs = MarkCounterActs + 1;
		EndIf;
		
	EndDo;
	
	SelectionBillingDetails = QueryResult[13].Select();
	While SelectionBillingDetails.Next() Do
		
		NewRow = ListBillingDetails.Add();
		FillPropertyValues(NewRow, SelectionBillingDetails);
		
		QuantityRenderedWithPrice    = SelectionBillingDetails.QuantityRenderedWithPrice;
		QuantityRenderedWithoutPrice   = SelectionBillingDetails.QuantityRenderedWithoutPrice;
		AmountRenderedWithPrice         = SelectionBillingDetails.AmountRenderedWithPrice;
		AmountRenderedWithoutPrice        = SelectionBillingDetails.AmountRenderedWithoutPrice;
		QuantityInvoiced       = SelectionBillingDetails.QuantityInvoiced;
		AmountInvoiced            = SelectionBillingDetails.AmountInvoiced;
		
		// Добавляем абонентские условия.
		If QuantityRenderedWithPrice <= SelectionBillingDetails.ContractQuantity Then
			
			ReplacedQuantityWithPrice = SelectionBillingDetails.ContractQuantity - QuantityRenderedWithPrice;
			If QuantityRenderedWithoutPrice > ReplacedQuantityWithPrice Then
				QuantityRenderedWithoutPrice = QuantityRenderedWithoutPrice - ReplacedQuantityWithPrice;
				AmountRenderedWithoutPrice = QuantityRenderedWithoutPrice * SelectionBillingDetails.PriceByPriceKind;
			Else
				QuantityRenderedWithoutPrice = 0;
				AmountRenderedWithoutPrice = 0;
			EndIf;
			
			QuantityRenderedWithPrice = SelectionBillingDetails.ContractQuantity;
			AmountRenderedWithPrice      = SelectionBillingDetails.ContractAmount;
			
		EndIf;
		
		If TypeOf(NewRow.ServiceContractObject) = Type("CatalogRef.ProductsAndServices") Then
			If QuantityRenderedWithoutPrice <> 0 And AmountRenderedWithoutPrice = 0
				Or QuantityRenderedWithPrice <> 0 And AmountRenderedWithPrice = 0 Then
				
				ErrorText = StrTemplate(
					NStr("en='Under the contract %1: %2 an Invoice cannot be generated! For the product %3 no price is set for contract price kind: %4';ru='По договору %1: %2 не может быть сформирован Счет! Для номенклатуры %3 не установлена цена во виду цен договора: %4';vi='Theo hợp đồng %1: %2 không thể lập Yêu cầu thanh toán! Đối với mặt hàng %3 chưa đặt đơn giá theo dạng giá hợp đồng: %4'"),
					NewRow.Contract.Owner,
					NewRow.Contract,
					SmallBusinessServer.PresentationOfProductsAndServices(NewRow.ServiceContractObject, NewRow.CHARACTERISTIC),
					NewRow.Contract.PriceKind
				);
				
				AddUserError(
					Errors,
					ErrorText,
					NewRow.ServiceContractObject
				);
				
			EndIf;
		EndIf;
		
		NewRow.Quantity =
			QuantityRenderedWithPrice +
			QuantityRenderedWithoutPrice -
			QuantityInvoiced
		;
		
		NewRow.Amount =
			AmountRenderedWithPrice +
			AmountRenderedWithoutPrice -
			AmountInvoiced
		;
		
	EndDo;
	
	Result.Insert("ListServiceContracts", ListServiceContracts);
	Result.Insert("ListServiceContractsExecution", ListServiceContractsExecution);
	Result.Insert("ListBillingDetails", ListBillingDetails);
	Result.Insert("MarksCounterInvoices", MarksCounterInvoices);
	Result.Insert("MarkCounterActs", MarkCounterActs);
	
EndProcedure

Procedure ExecuteDocumentPackageCreation(Parameters, Result, Errors)
	
	If BegOfDay(Parameters.DocumentsGenerationDateInvoices) = BegOfDay(CurrentSessionDate()) Then
		InvoiceForPaymentDate = CurrentSessionDate();
	Else
		InvoiceForPaymentDate = Parameters.DocumentsGenerationDateInvoices;
	EndIf;
	
	If BegOfDay(Parameters.DocumentGenerationDateActs) = BegOfDay(CurrentSessionDate()) Then
		AcceptanceCertificateDate = CurrentSessionDate();
	Else
		AcceptanceCertificateDate = Parameters.DocumentGenerationDateActs;
	EndIf;
	
	FilterParameters = New Structure;
	FilterParameters.Insert("Contract", Undefined);
	
	Result.Insert("InvoicesForPayment", New Array);
	If Parameters.GenerateActs Then
		Result.Insert("AcceptanceCertificates", New Array);
	EndIf;
	If Parameters.GenerateActsGenerateInvoices Then
		Result.Insert("AccountsInvoice", New Array);
	EndIf;
	If Parameters.GenerateInvoicesSendByEmail Or Parameters.GenerateActsSendByEmail Then
		Result.Insert("Emails", New Array);
	EndIf;
	
	For Iterator = 0 To Parameters.ListServiceContracts.Count() - 1 Do
		
		RowContract = Parameters.ListServiceContracts[Iterator];
		ContractPresentation = String(RowContract.Contract);
		
		If Not RowContract.GenerateInvoice And Not RowContract.GenerateAct Then
			Continue;
		EndIf;
		
		If RowContract.HasItemsWithoutInvoicingAmount Then
			Continue;
		EndIf;
		
		FilterParameters.Contract = RowContract.Contract;
		
		InvoiceForPayment        = Undefined;
		AcceptanceCertificate = Undefined;
		InvoiceNote         = Undefined;
		EmailMessage   = Undefined;
		
		BeginTransaction();
		Try
			If RowContract.GenerateInvoice Then
				
				BillingDetails = Parameters.ListBillingDetails.FindRows(FilterParameters);
				
				InvoiceForPayment = CreateInvoiceForPayment(
					InvoiceForPaymentDate,
					RowContract.Contract,
					RowContract.Counterparty,
					BillingDetails
				);
				
			EndIf;
			
			If Parameters.GenerateActs
				And RowContract.GenerateInvoice
				And RowContract.GenerateAct
				And InvoiceForPayment <> Undefined Then
				
				AcceptanceCertificate = CreateAcceptanceCertificatesByInvoice(
					AcceptanceCertificateDate,
					InvoiceForPayment.Ref,
					Parameters.GenerateActsPost
				);
				
				If Parameters.GenerateActsGenerateInvoices
					And AcceptanceCertificate <> Undefined Then
					
					InvoiceNote = CreateInvoiceByAcceptanceCertificate(
						AcceptanceCertificateDate, AcceptanceCertificate.Ref
					);
				EndIf;
				
			EndIf;
			
			If Parameters.GenerateInvoicesSendByEmail Or Parameters.GenerateActsSendByEmail Then
				
				DocumentsToBeSent = New Array;
				If InvoiceForPayment <> Undefined And Parameters.GenerateInvoicesSendByEmail Then
					DocumentsToBeSent.Add(InvoiceForPayment.Ref);
				EndIf;
				If AcceptanceCertificate <> Undefined And Parameters.GenerateActsSendByEmail Then
					DocumentsToBeSent.Add(AcceptanceCertificate.Ref);
				EndIf;
				If InvoiceNote <> Undefined  And Parameters.GenerateActsSendByEmail Then
					DocumentsToBeSent.Add(InvoiceNote.Ref);
				EndIf;
				
				EmailMessage = CreateEmail(Parameters.MessagePattern, RowContract.Contract, DocumentsToBeSent);
				
			EndIf;
			
			If Result.Property("InvoicesForPayment") And InvoiceForPayment <> Undefined Then
				Result.InvoicesForPayment.Add(InvoiceForPayment.Ref);
			EndIf;
			If Result.Property("AcceptanceCertificates") And AcceptanceCertificate <> Undefined Then
				Result.AcceptanceCertificates.Add(AcceptanceCertificate.Ref);
			EndIf;
			If Result.Property("AccountsInvoice") And InvoiceNote <> Undefined Then
				Result.AccountsInvoice.Add(InvoiceNote.Ref);
			EndIf;
			If Result.Property("Emails") And EmailMessage <> Undefined Then
				Result.Emails.Add(EmailMessage.Ref);
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ErrorInfo = ErrorInfo();
			ErrorText = DetailErrorDescription(ErrorInfo());
			
			WriteLogEvent(
				NStr("en='Batch generation of invoices and e-mails';ru='Пакетное формирование счетов и электронных писем';vi='Tạo hàng loạt yêu cầu thanh toán và E-mail'"),
				EventLogLevel.Error,,,
				ErrorText
			);
			
			ErrorText = StrTemplate(
				NStr("en='Can not to create a package of documents for the contract %1 because: %2';ru='Для договора %1 не удалось создать пакет документов по причине: %2';vi='Đối với hợp đồng %1, không thể tạo gói chứng từ do: %2'"),
				ContractPresentation,
				ErrorText
			);
			
			AddUserError(Errors, ErrorText);
			
		EndTry;
		
	EndDo; // Параметры.СписокДоговорыОбслуживания
	
EndProcedure // ВыполнитьСозданиеПакетаДокументов()

Function CreateInvoiceForPayment(Date, Contract, Counterparty, ContractTurnovers)
	
	If ContractTurnovers.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	FillingData = New Structure;
	FillingData.Insert("Contract", Contract);
	FillingData.Insert("Counterparty", Counterparty);
	FillingData.Insert("Company", CommonUse.ObjectAttributeValue(Contract, "Company"));
	
	InvoiceForPayment = Documents.InvoiceForPayment.CreateDocument();
	InvoiceForPayment.Date = Date;
	InvoiceForPayment.Fill(FillingData);
	If Not InvoiceForPayment.CheckFilling() Then
		Messages = GetUserMessages(True);
	EndIf;
	InvoiceForPayment.StampBase = String(Contract);
	InvoiceForPayment.PrintBasisRef = Contract;
	
	For Each Str In ContractTurnovers Do
		
		If Str.Quantity = 0 Then
			Continue;
		EndIf;
		
		NewRow = InvoiceForPayment.BillingDetails.Add();
		NewRow.ServiceContractObject = Str.ServiceContractObject;
		NewRow.CHARACTERISTIC      = Str.CHARACTERISTIC;
		NewRow.PresentationInAccount = Str.PresentationInAccount;
		NewRow.Quantity          = Str.Quantity;
		NewRow.MeasurementUnit    = ?(ValueIsFilled(Str.MeasurementUnit), Str.MeasurementUnit, Undefined);
		NewRow.Amount               = Str.Amount;
		NewRow.Price                = Str.Amount / Str.Quantity;
		
		If Str.AddPeriodToContent Then
			Periodicity = CommonUse.ObjectAttributeValue(Str.Contract, "ServiceContractPeriodicity");
			
			ProductsAndServicesParameters = New Structure;
			If ValueIsFilled(NewRow.PresentationInAccount) Then
				ProductsAndServicesParameters.Insert("ProductsAndServicesPresentation", NewRow.PresentationInAccount);
			Else
				ProductsAndServicesParameters.Insert("ProductsAndServicesPresentation", NewRow.ServiceContractObject);
				ProductsAndServicesParameters.Insert("CharacteristicPresentation", NewRow.CHARACTERISTIC);
			EndIf;
			
			ProductsAndServicesPresentation = PrintDocumentsCM.ProductsAndServicesPresentation(ProductsAndServicesParameters);
			NewRow.Content = ProductsAndServicesInDocumentsClientServer.ProductsAndServicesContentWithPeriod(
				ProductsAndServicesPresentation, InvoiceForPayment.Date, Periodicity);
		EndIf;
		
	EndDo;
	
	If InvoiceForPayment.BillingDetails.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	Documents.InvoiceForPayment.RefillInventoryByBillingDetails(InvoiceForPayment);
	
	// АвтоматическиеСкидки
	ParameterStructure = New Structure;
	ParameterStructure.Insert("ApplyToObject",           True);
	ParameterStructure.Insert("OnlyPreliminaryCalculation", False);
	ParameterStructure.Insert("Workplace", "");
	DiscountsMarkupsServerOverridable.Calculate(InvoiceForPayment, ParameterStructure);
	// Конец АвтоматическиеСкидки
	
	InvoiceForPayment.Write(DocumentWriteMode.Posting);
	
	Return InvoiceForPayment;
	
EndFunction

Function CreateAcceptanceCertificatesByInvoice(Date, InvoiceForPayment, CheckDocument)
	
	AcceptanceCertificate = Documents.AcceptanceCertificate.CreateDocument();
	AcceptanceCertificate.Date = Date;
	AcceptanceCertificate.Fill(InvoiceForPayment);
	
	If AcceptanceCertificate.WorksAndServices.Count() = 0 Then
		AcceptanceCertificate = Undefined;
		Return Undefined;
	EndIf;
	
	If CheckDocument Then
		PostingMode = DocumentWriteMode.Posting;
	Else
		PostingMode = DocumentWriteMode.Write;
	EndIf;
	AcceptanceCertificate.Write(PostingMode);
	
	Return AcceptanceCertificate;
	
EndFunction

Function CreateInvoiceByAcceptanceCertificate(Date, AcceptanceCertificate)
	Var InvoiceNote;
	
	If AcceptanceCertificate.WorksAndServices.Total("VATAmount") > 0 Then
		
		InvoiceNote = Documents.InvoiceNote.CreateDocument();
		InvoiceNote.Date = Date;
		InvoiceNote.Fill(AcceptanceCertificate);
		InvoiceNote.Write(DocumentWriteMode.Posting);
		
	EndIf;
	
	Return InvoiceNote;
	
EndFunction

Function CreateEmail(MessagePattern, Contract, DocumentsToBeSent)
	
	If Contract.ServiceContractMailingRecipients.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	FillingData = GetEmailFillingData(MessagePattern, Contract, DocumentsToBeSent);
	
	EmailMessage = Documents.Event.CreateDocument();
	EmailMessage.Fill(Undefined);
	EmailMessage.EventType     = Enums.EventTypes.Email;
	EmailMessage.State      = Catalogs.EventStates.Planned;
	EmailMessage.UserAccount  = SmallBusinessReUse.GetValueByDefaultUser(Users.CurrentUser(), "DefaultEmailAccount");
	EmailMessage.Subject           = FillingData.Subject;
	EmailMessage.Content     = FillingData.Content;
	EmailMessage.ContentHTML = FillingData.ContentHTML;
	EmailMessage.ImagesHTML   = FillingData.ImagesHTML;
	
	EmailAttachments = FillingData.Attachments;
	
	For Each BasisDocument In DocumentsToBeSent Do
		EmailMessage.BasisDocuments.Add().BasisDocument = BasisDocument;
	EndDo;
	
	For Each Recipient In Contract.ServiceContractMailingRecipients Do
		NewRow = EmailMessage.Attendees.Add();
		NewRow.Contact      = Recipient.Contact;
		NewRow.HowToContact = Recipient.EmailAddress;
	EndDo;
	
	Try
		EmailMessage.SendByEmail(False, EmailAttachments);
	Except
		MessageText = StrTemplate(
			NStr("en='Could not send an email automatically because: %2';ru='Не удалось автоматически отправить электронное письмо по причине: %2';vi='Không thể tự động gửi E-mail vì lý do: %2'"),
			DetailErrorDescription(ErrorInfo())
		);
		WriteLogEvent(
			NStr("en='Batch generation of invoices and e-mails';ru='Пакетное формирование счетов и электронных писем';vi='Tạo hàng loạt yêu cầu thanh toán và E-mail'"),
			EventLogLevel.Error,
			Metadata.Documents.Event,
			EmailMessage.Ref,
			MessageText
		);
		Raise;
	EndTry;
	
	EmailMessage.AdditionalProperties.Insert("Attachments", EmailAttachments);
	EmailMessage.Write();
	
	Return EmailMessage;
	
EndFunction

Function GetEmailFillingData(MessagePattern, Contract, DocumentsToBeSent)
	
	If Not ValueIsFilled(MessagePattern) Then
		Return Undefined;
	EndIf;
	
	FillingData = New Structure("Sender,Subject,Content,ContentHTML,ImagesHTML,Attachments");
	
//	ArbitraryParameters = New Map;
//	For Each Document In DocumentsToBeSent Do
//		ArbitraryParameters.Insert(Document.Metadata().Name, Document);
//	EndDo;
//	
//	EmailAdditionalParameters = New Structure;
//	EmailAdditionalParameters.Insert("ConvertHTMLForFormattedDocument", True);
//	EmailAdditionalParameters.Insert("ArbitraryParameters", ArbitraryParameters);
//	
//	GeneratedMessage = MessageTemplates.GenerateMessage(
//		MessagePattern,
//		Contract,
//		New UUID,
//		EmailAdditionalParameters
//	);
//	FD = New FormattedDocument;
//	FD.SetHTML(GeneratedMessage.Text, New Structure);
//	FillingData.Subject           = GeneratedMessage.Subject;
//	FillingData.Content     = FD.GetText();
//	FillingData.ContentHTML = GeneratedMessage.Text;
//	
//	EmailAttachments = New Map; // для вызова API отправки сообщения, см. СобытиеОбъект.ОтправитьЭлектронноеПисьмо()
//	
//	If GeneratedMessage.Attachments.Count() > 0 Then
//		
//		PicturesFD = New Structure; // Для сохранения картинок вставленных непосредственно в тело письма
//		IndexOf = GeneratedMessage.Attachments.Count()-1;
//		While IndexOf >= 0 Do
//			Attachment = GeneratedMessage.Attachments[IndexOf];
//			EmailAttachments.Insert(Attachment.Presentation, Attachment.AddressInTemporaryStorage);
//			If ValueIsFilled(Attachment.ID) Then
//				PicturesFD.Insert(
//					Attachment.Presentation,
//					New Picture(GetFromTempStorage(Attachment.AddressInTemporaryStorage)));
//				GeneratedMessage.Attachments.Delete(Attachment); // Удаляем из всех вложений, вложения которые вставлены в тело письма, их не надо сохранять отдельно в присоединенных файлах
//			EndIf;
//			IndexOf = IndexOf - 1;
//		EndDo;
//		
//		// Запишем картинки, вставленные в тело письма, в реквизит-хранилище
//		FillingData.ImagesHTML = New ValueStorage(PicturesFD);
//		
//	EndIf;
//	
//	FillingData.Attachments = EmailAttachments;
	
	Return FillingData;
	
EndFunction

Procedure AddUserError(Errors, Text, DataKey = Undefined)
	
	If Errors = Undefined Then
		Errors = New Array;
	EndIf;
	
	Error = New Structure;
	Error.Insert("Text", Text);
	If DataKey <> Undefined Then
		Error.Insert("DataKey", DataKey);
	EndIf;
	
	Errors.Add(Error);
	
EndProcedure

Procedure IncludeErrorsInExecutionResult(Result, Errors)
	
	If TypeOf(Errors) = Type("Array") And Errors.Count() <> 0 Then
		Result.Insert("Errors", Errors);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf