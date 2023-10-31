////////////////////////////////////////////////////////////////////////////////
// Infobase update (SB)
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// PROGRAMMING INTERFACE

////////////////////////////////////////////////////////////////////////////////
// Information about library (or configuration).

// Fills out basic information about the library or default configuration.
// Library which name matches configuration name in metadata is defined as default configuration.
// 
// Parameters:
//  Definition - Structure - information about the library:
//
//   Name                 - String - name of the library, for example, "StandardSubsystems".
//   Version              - String - version in the format of 4 digits, for example, "2.1.3.1".
//
//   RequiredSubsystems - Array - names of other libraries (String) on which this library depends.
//                                  Update handlers of such libraries should
//                                  be called before update handlers of this library.
//                                  IN case of circular dependencies or, on
//                                  the contrary, absence of any dependencies, call out
//                                  procedure of update handlers is defined by the order of modules addition in procedure WhenAddingSubsystems of common module ConfigurationSubsystemsOverridable.
//
Procedure OnAddSubsystem(Definition) Export
	
	Definition.Name = "CompanyManagement";
	Definition.Version = "1.1.2.5";
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Infobase update handlers

// Adds to the list of
// procedures (IB data update handlers) for all supported versions of the library or configuration.
// Appears before the start of IB data update to build up the update plan.
//
// Parameters:
//  Handlers - ValueTable - See description
// of the fields in the procedure InfobaseUpdate.UpdateHandlersNewTable
//
// Example of adding the procedure-processor to the list:
//  Handler = Handlers.Add();
//  Handler.Version              = "1.0.0.0";
//  Handler.Procedure           = "IBUpdate.SwitchToVersion_1_0_0_0";
//  Handler.ExclusiveMode    = False;
//  Handler.Optional        = True;
// 
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version = "1.0.0.1";
	Handler.InitialFilling = True;
	Handler.Procedure = "InfobaseUpdateSB.FirstLaunch";
	
	Handler = Handlers.Add();
	Handler.Version = "1.0.1.5";
	Handler.Procedure = "InfobaseUpdateSB.FillStructuralUnitTypes";
	Handler.Comment = "Filling StructuralUnitTypes for Warehouses Access Restrict";
	
	Handler = Handlers.Add();
	Handler.Version = "1.1.0.2";
	Handler.Procedure = "InfobaseUpdateSB.SetupFunctionalOptionAccountingByMultipleCompanies";
	Handler.Comment = "Filling constant FunctionalOptionAccountingByMultipleCompanies value from constant UseSeveralCompanies";
	
	Handler = Handlers.Add();
	Handler.Version = "1.1.0.5";
	Handler.Procedure = "InfobaseUpdateSB.FillEnterOpeningBalanceAccountingSection";
	Handler.Comment = "Filling attribute AccountingSection of EnterOpeningBalance document";

	Handler = Handlers.Add();
	Handler.Version = "1.1.0.6";
	Handler.Procedure = "InfobaseUpdateSB.FillDocumentsAttributePosition";
	Handler.Comment = "Filling CustomerOrderPosition in InventoryAssembly documents";
	
	Handler = Handlers.Add();
	Handler.Version = "1.1.0.6";
	Handler.Procedure = "InfobaseUpdateSB.ManualInventoryDistributionByDefault";
	Handler.Comment = "Filling distribution method by default";

	Handler = Handlers.Add();
	Handler.Procedure = "InfobaseUpdateSB.UpdateHardwareDriversInPeripherialsCatalog";
	Handler.Version = "1.1.0.7";
	Handler.Comment = НСтр("en='Update Hardware Drivers In Peripherials Catalog handler.';ru='Update Hardware Drivers In Peripherials Catalog handler.';vi='Cập nhật trình điều khiển phần cứng trong trình xử lý danh mục ngoại vi.'");

	Handler = Handlers.Add();
	Handler.Procedure = "InfobaseUpdateSB.UpdatePredefinedAccountsSettings1_1_0_8";
	Handler.Version = "1.1.0.8";
	Handler.Comment = НСтр("en='Update predefined accounts settings';ru='Обновление настроек предопределённых счетов.';vi='Update predefined accounts settings'");

	Handler = Handlers.Add();
	Handler.Procedure = "InfobaseUpdateSB.FillOperationQuantityInSpecifications";
	Handler.Version = "1.1.1.1";
	Handler.Comment = NStr("en='Fills the number of operations in specifications.';ru='Заполняет количество операций в спецификациях.';vi='Điền số lượng giao dịch vào bảng chi tiết nguyên vật liệu'");

	Handler = Handlers.Add();
	Handler.Procedure = "InfobaseUpdateSB.UpdateAdditionalAttributesAndInformationSetOfSpecification";
	Handler.Version = "1.1.1.1";
	Handler.Comment = NStr("en='Filling out predefined sets of additional attributes and information of specifications.';ru='Заполнение предопределенных наборов дополнительных реквизитов и сведений спецификаций.';vi='Điền vào các bộ được xác định trước của các mục tin bổ sung và thông tin bảng chi tiết nguyên vật liệu.'");

	Handler = Handlers.Add();
	Handler.Procedure = "InfobaseUpdateSB.FillPredefinedTaxTypes";
	Handler.Version = "1.1.2.3";
	Handler.Comment = NStr("en = 'Filling predefined tax types.'; ru = 'Заполнение предопределенных видов налогов.'; vi = 'Điền các loại thuế xác định trước.'");

	Handler = Handlers.Add();
	Handler.Procedure = "InfobaseUpdateSB.UpdateHardwareDriversInPeripherialsCatalog";
	Handler.Version = "1.1.2.5";
	Handler.Comment = НСтр("en='Update Hardware Drivers In Peripherials Catalog handler.';ru='Update Hardware Drivers In Peripherials Catalog handler.';vi='Cập nhật trình điều khiển phần cứng trong trình xử lý danh mục ngoại vi.'");

EndProcedure

// Called before the procedures-handlers of IB data update.
//
Procedure BeforeInformationBaseUpdating() Export
	
	
	
EndProcedure

// Called after the completion of IB data update.
//		
// Parameters:
//   PreviousVersion       - String - version before update. 0.0.0.0 for an empty IB.
//   CurrentVersion          - String - version after update.
//   ExecutedHandlers - ValueTree - list of completed
//                                             update procedures-handlers grouped by version number.
//   PutSystemChangesDescription - Boolean - (return value) if
//                                you set True, then form with events description will be output. By default True.
//   ExclusiveMode           - Boolean - True if the update was executed in the exclusive mode.
//		
// Example of bypass of executed update handlers:
//		
// For Each Version From ExecutedHandlers.Rows Cycle
//		
// 	If Version.Version =
// 		 * Then Ha//ndler that can be run every time the version changes.
// 	Otherwise,
// 		 Handler runs for a definite version.
// 	EndIf;
//		
// 	For Each Handler From Version.Rows
// 		Cycle ...
// 	EndDo;
//		
// EndDo;
//
Procedure AfterInformationBaseUpdate(Val PreviousVersion, Val CurrentVersion,
		Val ExecutedHandlers, PutSystemChangesDescription, ExclusiveMode) Export
	
	
	
EndProcedure

// Called when you prepare a tabular document with description of changes in the application.
//
// Parameters:
//   Template - SpreadsheetDocument - description of update of all libraries and the configuration.
//           You can append or replace the template.
//          See also common template SystemChangesDescription.
//
Procedure OnPreparationOfUpdatesDescriptionTemplate(Val Template) Export
	
EndProcedure

// Adds procedure-processors of transition from another application to the list (with another configuration name).
// For example, for the transition between different but related configurations: base -> prof -> corp.
// Called before the beginning of the IB data update.
//
// Parameters:
//  Handlers - ValueTable - with columns:
//    * PreviousConfigurationName - String - name of the configuration, with which the transition is run;
//    * Procedure                 - String - full name of the procedure-processor of the transition from the PreviousConfigurationName application. 
//                                  ForExample, UpdatedERPInfobase.FillExportPolicy
//                                  is required to be export.
//
// Example of adding the procedure-processor to the list:
//  Handler = Handlers.Add();
//  Handler.PreviousConfigurationName  = TradeManagement;
//  Handler.Procedure                  = ERPInfobaseUpdate.FillAccountingPolicy;
//
Procedure OnAddTransitionFromAnotherApplicationHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.PreviousConfigurationName = "Drive";
	Handler.Procedure = "InfobaseUpdateSB.FillStructuralUnitTypes";
	
	Handler = Handlers.Add();
	Handler.PreviousConfigurationName = "Drive";
	Handler.Procedure = "InfobaseUpdateSB.SetupFunctionalOptionAccountingByMultipleCompanies";

	
EndProcedure // OnAddHandlersOnTransitionFromAnotherApplication()

// Helps to override mode of the infobase data update.
// To use in rare (emergency) cases of transition that
// do not happen in a standard procedure of the update mode.
//
// Parameters:
//   DataUpdateMode - String - you can set one of the values in the handler:
//              InitialFilling     - if it is the first launch of an empty base (data field);
//              VersionUpdate        - if it is the first launch after the update of the data base configuration;
//              TransitionFromAnotherApplication - if first launch is run after the update of
// the data base configuration with changed name of the main configuration.
//
//   StandardProcessing  - Boolean - if you set False, then
//                                    a standard procedure of the update
//                                    mode fails and the DataUpdateMode value is used.
//
Procedure OnDefineDataUpdateMode(DataUpdateMode, StandardProcessing) Export
	
EndProcedure

// Called after all procedures-processors of transfer from another application (with another
// configuration name) and before beginning of the IB data update.
//
// Parameters:
//  PreviousConfigurationName    - String - name of configuration before transition.
//  PreviousConfigurationVersion - String - name of the previous configuration (before transition).
//  Parameters                    - Structure - 
//    * UpdateFromVersion   - Boolean - True by default. If you set
// False, only the mandatory handlers of the update will be run (with the * version).
//    * ConfigurationVersion           - String - version No after transition. 
//        By default it equals to the value of the configuration version in the metadata properties.
//        To run, for example, all update handlers from the PreviousConfigurationVersion version,
// you should set parameter value in PreviousConfigurationVersion.
//        To process all updates, set the 0.0.0.1 value.
//    * ClearInformationAboutPreviousConfiguration - Boolean - True by default. 
//        For cases when the previous configuration matches by name with the subsystem of the current configuration, set False.
//
Procedure OnEndTransitionFromAnotherApplication(Val PreviousConfigurationName, Val PreviousConfigurationVersion, Parameters) Export
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// SERVICE INTERFACE 

// Procedures supporting the first start (<step number on the first start>)

//(1) Procedure imports accounts management plan from layout.
//
Procedure ImportManagerialChartOfAccountsFirstLaunch()
	
	// 00.
	Account = ChartsOfAccounts.Managerial.Service.GetObject();
	Account.TypeOfAccount = Enums.GLAccountsTypes.AccountsGroup;
	Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
	Account.Write();
	
	// 01.
	Account = ChartsOfAccounts.Managerial.FixedAssets.GetObject();
	Account.TypeOfAccount = Enums.GLAccountsTypes.FixedAssets;
	Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
	Account.Write();
	
	// 02.
	Account = ChartsOfAccounts.Managerial.DepreciationFixedAssets.GetObject();
	Account.TypeOfAccount = Enums.GLAccountsTypes.DepreciationFixedAssets;
	Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
	Account.Write();
	
	// 08.
	Account = ChartsOfAccounts.Managerial.InvestmentsInFixedAssets.GetObject();
	Account.TypeOfAccount = Enums.GLAccountsTypes.OtherFixedAssets;
	Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
	Account.Write();
	
	// 10.
	Account = ChartsOfAccounts.Managerial.RawMaterialsAndMaterials.GetObject();
	Account.TypeOfAccount = Enums.GLAccountsTypes.Inventory;
	Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
	Account.Write();
	
	// 20.
	Account = ChartsOfAccounts.Managerial.UnfinishedProduction.GetObject();
	Account.TypeOfAccount = Enums.GLAccountsTypes.UnfinishedProduction;
	Account.ClosingAccount = ChartsOfAccounts.Managerial.ProductsFinishedProducts;
	Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
	Account.Write();
	
	// 25.
	Account = ChartsOfAccounts.Managerial.IndirectExpenses.GetObject();
	Account.TypeOfAccount = Enums.GLAccountsTypes.IndirectExpenses;
	Account.ClosingAccount = ChartsOfAccounts.Managerial.UnfinishedProduction;
	Account.MethodOfDistribution = Enums.CostingBases.ProductionVolume;
	Account.Write();
	
	// 41.
	Account = ChartsOfAccounts.Managerial.ProductsFinishedProducts.GetObject();
	Account.TypeOfAccount = Enums.GLAccountsTypes.Inventory;
	Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
	Account.Write();
	
	// 42.
	Account = ChartsOfAccounts.Managerial.TradeMarkup.GetObject();
	Account.TypeOfAccount = Enums.GLAccountsTypes.TradeMarkup;
	Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
	Account.Write();
	
	// 50.
	Account = ChartsOfAccounts.Managerial.PettyCash.GetObject();
	Account.TypeOfAccount = Enums.GLAccountsTypes.CashAssets;
	Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
	Account.Write();
	
	// 51.
	Account = ChartsOfAccounts.Managerial.Bank.GetObject();
	Account.TypeOfAccount = Enums.GLAccountsTypes.CashAssets;
	Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
	Account.Write();
	
	// 57.
	Account = ChartsOfAccounts.Managerial.TransfersInProcess.GetObject();
	Account.TypeOfAccount = Enums.GLAccountsTypes.CashAssets;
	Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
	Account.Write();
	
	// 58.
	Account = ChartsOfAccounts.Managerial.FinancialInvestments.GetObject();
	Account.TypeOfAccount = Enums.GLAccountsTypes.CashAssets;
	Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
	Account.Write();
	
	// 60.
	Account = ChartsOfAccounts.Managerial.AccountsPayableAndContractors.GetObject();
	Account.TypeOfAccount = Enums.GLAccountsTypes.AccountsGroup;
	Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
	Account.Write();
	
		// 60.01
		Account = ChartsOfAccounts.Managerial.AccountsPayable.GetObject();
		Account.Parent = ChartsOfAccounts.Managerial.AccountsPayableAndContractors;
		Account.TypeOfAccount = Enums.GLAccountsTypes.Creditors;
		Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
		Account.Write();
		
		// 60.02
		Account = ChartsOfAccounts.Managerial.SettlementsByAdvancesIssued.GetObject();
		Account.Parent = ChartsOfAccounts.Managerial.AccountsPayableAndContractors;
		Account.TypeOfAccount = Enums.GLAccountsTypes.Debitors;
		Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
		Account.Write();
		
	// 62.
	Account = ChartsOfAccounts.Managerial.AccountsReceivableAndCustomers.GetObject();
	Account.TypeOfAccount = Enums.GLAccountsTypes.AccountsGroup;
	Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
	Account.Write();
	
		// 62.01
		Account = ChartsOfAccounts.Managerial.AccountsReceivable.GetObject();
		Account.Parent = ChartsOfAccounts.Managerial.AccountsReceivableAndCustomers;
		Account.TypeOfAccount = Enums.GLAccountsTypes.Debitors;
		Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
		Account.Write();
		
		// 62.02
		Account = ChartsOfAccounts.Managerial.AccountsByAdvancesReceived.GetObject();
		Account.Parent = ChartsOfAccounts.Managerial.AccountsReceivableAndCustomers;
		Account.TypeOfAccount = Enums.GLAccountsTypes.Creditors;
		Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
		Account.Write();
		
	// 66.
	Account = ChartsOfAccounts.Managerial.SettlementsByShorttermLoans.GetObject();
	Account.TypeOfAccount = Enums.GLAccountsTypes.Loans;
	Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
	Account.Write();
	
	// 67.
	Account = ChartsOfAccounts.Managerial.AccountsByLongtermLoans.GetObject();
	Account.TypeOfAccount = Enums.GLAccountsTypes.LongtermObligations;
	Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
	Account.Write();
	
	// 68.
	Account = ChartsOfAccounts.Managerial.TaxesSettlements.GetObject();
	Account.TypeOfAccount = Enums.GLAccountsTypes.AccountsGroup;
	Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
	Account.Write();
	
		// 68.01
		Account = ChartsOfAccounts.Managerial.Taxes.GetObject();
		Account.Parent = ChartsOfAccounts.Managerial.TaxesSettlements;
		Account.TypeOfAccount = Enums.GLAccountsTypes.Creditors;
		Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
		Account.Write();
		
		// 68.02
		Account = ChartsOfAccounts.Managerial.TaxesToRefund.GetObject();
		Account.Parent = ChartsOfAccounts.Managerial.TaxesSettlements;
		Account.TypeOfAccount = Enums.GLAccountsTypes.Debitors;
		Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
		Account.Write();
	
	// 70.
	Account = ChartsOfAccounts.Managerial.PayrollPaymentsOnPay.GetObject();
	Account.TypeOfAccount = Enums.GLAccountsTypes.Creditors;
	Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
	Account.Write();
	
	// 71.
	Account = ChartsOfAccounts.Managerial.SettlementsWithAdvanceHolders.GetObject();
	Account.TypeOfAccount = Enums.GLAccountsTypes.AccountsGroup;
	Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
	Account.Write();
	
		// 71.01
		Account = ChartsOfAccounts.Managerial.AdvanceHolderPayments.GetObject();
		Account.Parent = ChartsOfAccounts.Managerial.SettlementsWithAdvanceHolders;
		Account.TypeOfAccount = Enums.GLAccountsTypes.Debitors;
		Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
		Account.Write();
		
		// 71.02
		Account = ChartsOfAccounts.Managerial.OverrunOfAdvanceHolders.GetObject();
		Account.Parent = ChartsOfAccounts.Managerial.SettlementsWithAdvanceHolders;
		Account.TypeOfAccount = Enums.GLAccountsTypes.Creditors;
		Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
		Account.Write();
		
	// 80.
	Account = ChartsOfAccounts.Managerial.StatutoryCapital.GetObject();
	Account.TypeOfAccount = Enums.GLAccountsTypes.Capital;
	Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
	Account.Write();
	
	// 82.
	Account = ChartsOfAccounts.Managerial.ReserveAndAdditionalCapital.GetObject();
	Account.TypeOfAccount = Enums.GLAccountsTypes.ReserveAndAdditionalCapital;
	Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
	Account.Write();
	
	// 84.
	Account = ChartsOfAccounts.Managerial.UndistributedProfit.GetObject();
	Account.TypeOfAccount = Enums.GLAccountsTypes.UndistributedProfit;
	Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
	Account.Write();

	// 90.
	Account = ChartsOfAccounts.Managerial.Sales.GetObject();
	Account.TypeOfAccount = Enums.GLAccountsTypes.AccountsGroup;
	Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
	Account.Write();
	
		// 90.01
		Account = ChartsOfAccounts.Managerial.SalesRevenue.GetObject();
		Account.Parent = ChartsOfAccounts.Managerial.Sales;
		Account.TypeOfAccount = Enums.GLAccountsTypes.Incomings;
		Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
		Account.Write();
		
		// 90.02
		Account = ChartsOfAccounts.Managerial.CostOfGoodsSold.GetObject();
		Account.Parent = ChartsOfAccounts.Managerial.Sales;
		Account.TypeOfAccount = Enums.GLAccountsTypes.CostOfGoodsSold;
		Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
		Account.Write();
		
		// 90.07
		Account = ChartsOfAccounts.Managerial.CommercialExpenses.GetObject();
		Account.Parent = ChartsOfAccounts.Managerial.Sales;
		Account.TypeOfAccount = Enums.GLAccountsTypes.Expenses;
		Account.MethodOfDistribution = Enums.CostingBases.SalesVolume;
		Account.Write();
		
		// 90.08
		Account = ChartsOfAccounts.Managerial.AdministrativeExpenses.GetObject();
		Account.Parent = ChartsOfAccounts.Managerial.Sales;
		Account.TypeOfAccount = Enums.GLAccountsTypes.Expenses;
		Account.MethodOfDistribution = Enums.CostingBases.SalesVolume;
		Account.Write();
		
	// 91.
	Account = ChartsOfAccounts.Managerial.OtherIncomeAndExpenses.GetObject();
	Account.TypeOfAccount = Enums.GLAccountsTypes.AccountsGroup;
	Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
	Account.Write();
	
		// 91.01
		Account = ChartsOfAccounts.Managerial.OtherIncome.GetObject();
		Account.Parent = ChartsOfAccounts.Managerial.OtherIncomeAndExpenses;
		Account.TypeOfAccount = Enums.GLAccountsTypes.OtherIncome;
		Account.MethodOfDistribution = Enums.CostingBases.SalesVolume;
		Account.Write();
		
		// 91.02
		Account = ChartsOfAccounts.Managerial.OtherExpenses.GetObject();
		Account.Parent = ChartsOfAccounts.Managerial.OtherIncomeAndExpenses;
		Account.TypeOfAccount = Enums.GLAccountsTypes.OtherExpenses;
		Account.MethodOfDistribution = Enums.CostingBases.SalesVolume;
		Account.Write();
		
		// 91.03
		Account = ChartsOfAccounts.Managerial.CreditInterestRates.GetObject();
		Account.Parent = ChartsOfAccounts.Managerial.OtherIncomeAndExpenses;
		Account.TypeOfAccount = Enums.GLAccountsTypes.LoanInterest;
		Account.MethodOfDistribution = Enums.CostingBases.SalesVolume;
		Account.Write();
		
	// 94.
	Account = ChartsOfAccounts.Managerial.DeficiencyAndLossFromPropertySpoilage.GetObject();
	Account.TypeOfAccount = Enums.GLAccountsTypes.OtherCurrentAssets;
	Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
	Account.Write();
	
	// 97.
	Account = ChartsOfAccounts.Managerial.CostsOfFuturePeriods.GetObject();
	Account.TypeOfAccount = Enums.GLAccountsTypes.OtherCurrentAssets;
	Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
	Account.Write();
	
	// 99.
	Account = ChartsOfAccounts.Managerial.ProfitsAndLosses.GetObject();
	Account.TypeOfAccount = Enums.GLAccountsTypes.AccountsGroup;
	Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
	Account.Write();
	
		// 99.01
		Account = ChartsOfAccounts.Managerial.ProfitsAndLossesWithoutProfitTax.GetObject();
		Account.Parent = ChartsOfAccounts.Managerial.ProfitsAndLosses;
		Account.TypeOfAccount = Enums.GLAccountsTypes.ProfitLosses;
		Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
		Account.Write();
		
		// 99.02
		Account = ChartsOfAccounts.Managerial.ProfitsAndLosses_ProfitTax.GetObject();
		Account.Parent = ChartsOfAccounts.Managerial.ProfitsAndLosses;
		Account.TypeOfAccount = Enums.GLAccountsTypes.ProfitTax;
		Account.MethodOfDistribution = Enums.CostingBases.DoNotDistribute;
		Account.Write();		
		
EndProcedure // ImportManagerialChartOfAccountsFirstLaunch()

//(3) Procedure fills in “Taxes kinds” catalog to IB.
//
Procedure FillTaxTypesFirstLaunch()

	// 1. VAT.
	TaxKind = Catalogs.TaxTypes.CreateItem();
	TaxKind.Description = "VAT";
	TaxKind.GLAccount = ChartsOfAccounts.Managerial.Taxes;
	TaxKind.GLAccountForReimbursement = ChartsOfAccounts.Managerial.TaxesToRefund;
	TaxKind.Write();

	// 2. Profit Tax.
	TaxKind = Catalogs.TaxTypes.CreateItem();
	TaxKind.Description = "Income tax";
	TaxKind.GLAccount = ChartsOfAccounts.Managerial.Taxes;
	TaxKind.GLAccountForReimbursement = ChartsOfAccounts.Managerial.TaxesToRefund;
	TaxKind.Write();

	FillPredefinedTaxTypes();

EndProcedure // FillTaxTypesFirstLaunch()

//(4) Returns object by code.
//    If the object is not found in the directory, it creates a new object and fills it from the classifier.
Function CatalogObjectCurrenciesByCode(Val CurrencyCode)
	
	CurrencyRef = Catalogs.Currencies.FindByCode(CurrencyCode);
	If ValueIsFilled(CurrencyRef) Then
		Return CurrencyRef.GetObject();
	EndIf;
	
	Result = Catalogs.Currencies.CreateItem();
	
	ClassifierXML = Catalogs.Currencies.GetTemplate("CurrencyClassifier").GetText();
	
	ClassifierTable = CommonUse.ReadXMLToTable(ClassifierXML).Data;
	
	CCRecord = ClassifierTable.Find(CurrencyCode, "Code"); 
	If CCRecord = Undefined Then
		Return Result;
	EndIf;
	
	Result.Code				= CCRecord.Code;
	Result.Description		= CCRecord.CodeSymbol;
	Result.DescriptionFull	= CCRecord.Name;
	If CCRecord.RBCLoading Then
		Result.SetRateMethod = Enums.CurrencyRateSetMethods.ExportFromInternet;
	Else
		Result.SetRateMethod = Enums.CurrencyRateSetMethods.ManualInput;
	EndIf;
	Result.InWordParametersInHomeLanguage = CCRecord.NumerationItemOptions;
	
	Return Result;
	
EndFunction

//(5) The function fills in "VAT rates" IB
// catalog and returns a reference to 18% VAT rate for the future use.
//
Function FillVATRatesFirstLaunch()

	// 5%
	VATRate = Catalogs.VATRates.CreateItem();
	VATRate.Description = "5%";
	VATRate.Rate = 5;
	VATRate.Write();
	
	// 10%
	VATRate = Catalogs.VATRates.CreateItem();
	VATRate.Description = "10%";
	VATRate.Rate = 10;
	VATRate.Write();
	
	// 0%
	VATRate = Catalogs.VATRates.CreateItem();
	VATRate.Description = "0%";
	VATRate.Rate = 0;
	VATRate.Write();
	
	// Without VAT
	VATRate = Catalogs.VATRates.CreateItem();
	VATRate.Description = NStr("en = 'Without VAT'; vi = 'Không chịu thuế GTGT'");
	VATRate.NotTaxable = True;
	VATRate.Rate = 0;
	VATRate.Write(); 
	
	Return VATRate.Ref;

EndFunction // FillVATRatesFirstLaunch()

//(7) Procedure creates a work schedule based on the business calendar of the Russian Federation according to the "Five-day working week" template
// 
Procedure CreateRussianFederationFiveDaysCalendar() Export
	
	BusinessCalendar = CalendarSchedules.BusinessCalendarOfRussiaFederation();
	If BusinessCalendar = Undefined Then 
		Return;
	EndIf;
	
	If Not Catalogs.Calendars.FindByAttribute("BusinessCalendar", BusinessCalendar).IsEmpty() Then
		Return;
	EndIf;
	
	NewWorkSchedule = Catalogs.Calendars.CreateItem();
	NewWorkSchedule.Description = CommonUse.GetAttributeValue(BusinessCalendar, "Description");
	NewWorkSchedule.BusinessCalendar = BusinessCalendar;
	NewWorkSchedule.FillMethod = Enums.WorkScheduleFillingMethods.ByWeeks;
	NewWorkSchedule.StartDate = BegOfYear(CurrentSessionDate());
	NewWorkSchedule.ConsiderHolidays = True;
	
	// Fill in week cycle as five-day working week
	For DayNumber = 1 To 7 Do
		NewWorkSchedule.FillTemplate.Add().DayIncludedInSchedule = DayNumber <= 5;
	EndDo;
	
	InfobaseUpdate.WriteData(NewWorkSchedule, True, True);
	
EndProcedure // CreateRussianFederationFiveDaysCalendar()

//(13) Procedure fills in "Planning ObjectPeriod" catalog to IB.
//
Procedure FillPlanningPeriodFirstLaunch()

	Period = Catalogs.PlanningPeriods.Actual;
	ObjectPeriod = Period.GetObject();
	ObjectPeriod.Periodicity = Enums.Periodicity.Month;
	ObjectPeriod.Write();

EndProcedure // FillPlanningPeriodFirstLaunch()

//(14) Procedure fills in classifier of using the work time.
//
Procedure FillClassifierOfWorkingTimeUsage()

    // B.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.Disease;
    WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
    WorkingHoursKinds.FullDescr = NStr("en='Temporary incapacity to labor with benefit assignment according to the law';vi='Mất sức lao động tạm thời có hưởng lợi ích đã quy định theo luật pháp'");
    WorkingHoursKinds.Write();

    // V.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.WeekEnd;
    WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
    WorkingHoursKinds.FullDescr = NStr("en='Weekends (weekly leave) and public holidays';vi='Làm thêm ngày nghỉ'");
    WorkingHoursKinds.Write();

    // VP.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.DowntimeByEmployeeFault;
    WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
    WorkingHoursKinds.FullDescr = NStr("en='Dead time by the employees fault';vi='Thời gian chết do lỗi của người lao động'");
    WorkingHoursKinds.Write();

	// VCH.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.WorkEveningClock;
    WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
    WorkingHoursKinds.FullDescr = NStr("en='Working hours in the evenings';vi='Thời gian làm việc vào buổi tối'");
    WorkingHoursKinds.Write();

    // G.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.PublicResponsibilities;
    WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
    WorkingHoursKinds.FullDescr = NStr("en='Absenteeism at the time of state or public duties according to the law';vi='Vắng mặt trong thời gian thực hiện nghĩa vụ nhà nước hoặc nghĩa vụ cộng đồng theo luật'");
    WorkingHoursKinds.Write();

    // DB.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.UnpaidAdditionalVacation;
    WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
    WorkingHoursKinds.FullDescr = NStr("en='Annual additional leave without salary';vi='Nghỉ phép hàng năm không lương'");
    WorkingHoursKinds.Write();

    // TO.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.UnpaidVacationByEmployerPermission;
    WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
    WorkingHoursKinds.FullDescr = NStr("en='Leave without pay provided to employee with employer permission';vi='Nghỉ làm nhưng chủ lao động không thanh toán cho người lao động'");
    WorkingHoursKinds.Write();

    // ZB.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.Strike;
    WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
    WorkingHoursKinds.FullDescr = NStr("en='Strike (in conditions and order provided by legislation)';vi='Đình công (có điều kiện và theo trình tự do luật pháp quy định)'");
    WorkingHoursKinds.Write();

    // TO.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.BusinessTrip;
    WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
    WorkingHoursKinds.FullDescr = NStr("en='Business trip';vi='Chuyến công tác'");
    WorkingHoursKinds.Write();

    // N.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.WorkNightHours;
    WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
    WorkingHoursKinds.FullDescr = NStr("en='Working hours at night time';vi='Làm việc vào ban đêm'");
    WorkingHoursKinds.Write();

    // NB.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.RemovalFromWorkWithoutPayments;
    WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
    WorkingHoursKinds.FullDescr = NStr("en='Suspension from work (disqualification) as required by the Law, without payroll';vi='Đình chỉ công việc (không đủ trình độ) theo yêu cầu của pháp luật mà không có lương'");
    WorkingHoursKinds.Write();

    // NV.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.AdditionalWeekEndDaysNotPaid;
    WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
    WorkingHoursKinds.FullDescr = NStr("en='Additional days off (without salary)';vi='Ngày nghỉ bổ sung (không có lương)'");
    WorkingHoursKinds.Write();

    // NZ.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.SalaryPayoffDelay;
    WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
    WorkingHoursKinds.FullDescr = NStr("en='Suspension of work in case of delayed salary';vi='Dừng làm việc do tiền lương bị trì hoãn'");
    WorkingHoursKinds.Write();

    // NN.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.NotAppearsByUnknownReasons;
    WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
    WorkingHoursKinds.FullDescr = NStr("en='Unjustified absence from work (until the circumstances are clarified)';vi='Vắng mặt vô lý (đến giờ vẫn chưa làm rõ trường hợp này)'");
    WorkingHoursKinds.Write();

    // NO.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.RemovalFromJobsWithPayment;
    WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
    WorkingHoursKinds.FullDescr = NStr("en='Suspension from work (disqualification) with payment (benefit) according to the law';vi='Đình chỉ làm việc (không đủ điều kiện) có thanh toán (lợi ích) theo pháp luật'");
    WorkingHoursKinds.Write();

    // NP.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.Simple;
    WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
    WorkingHoursKinds.FullDescr = NStr("en='Downtime due to reasons regardless of the employer and the employee';vi='Nguyên nhân thời gian nhàn rỗi có thể do chủ lao động và người lao động'");
    WorkingHoursKinds.Write();

    // OV.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.AdditionalWeekEndDaysPaid;
    WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
    WorkingHoursKinds.FullDescr = NStr("en='Additional days-off (paid)';vi='Ngày nghỉ bổ sung (đã thanh toán)'");
    WorkingHoursKinds.Write();

    // OD.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.AdditionalVacation;
    WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
    WorkingHoursKinds.FullDescr = NStr("en='Annual additional paid leave';vi='Nghỉ phép hàng năm có lương'");
    WorkingHoursKinds.Write();

    // OZH.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.VacationByCareForBaby;
    WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
    WorkingHoursKinds.FullDescr = NStr("en='Maternity leave up to the age of three';vi='Nghỉ thai sản đến khi trẻ ba tuổi'");
    WorkingHoursKinds.Write();

    // OZ.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.UnpaidVacationByLegislation;
    WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
    WorkingHoursKinds.FullDescr = NStr("en='Leave without pay in cases provided by law';vi='Nghỉ không lương trong các trường hợp được pháp luật quy định'");
    WorkingHoursKinds.Write();

    // OT.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.MainVacation;
    WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
    WorkingHoursKinds.FullDescr = NStr("en='Annual paid leave';vi='Nghỉ phép hàng năm có lương'");
    WorkingHoursKinds.Write();

    // PV.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.ForcedTruancy;
    WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
    WorkingHoursKinds.FullDescr = NStr("en='Time of the forced absenteeism in case of the dismissal recognition, transition to another work place or dismissal from work with reemployment on the former one';vi='Thời gian vắng mặt bắt buộc trong trường hợp công nhận sa thải, chuyển sang chỗ làm việc khác hoặc từ bỏ công việc lặp đi lặp lãi ở chỗ cũ.'");
    WorkingHoursKinds.Write();

    // PK.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.QualificationRaise;
    WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
    WorkingHoursKinds.FullDescr = NStr("en='On-the-job further training';vi='Đào tạo về sau tại chỗ làm việc'");
    WorkingHoursKinds.Write();

    // PM.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.QualificationRaiseInAnotherTerrain;
    WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
    WorkingHoursKinds.FullDescr = NStr("en='Further training off-the-job in other area';vi='Đào tạo cho tương lai mà chưa làm việc trong lĩnh vực khác'");
    WorkingHoursKinds.Write();

    // PR.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.Truancies;
    WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
    WorkingHoursKinds.FullDescr = NStr("en='Absenteeism (absence from work place without valid reasons within the time fixed by the law)';vi='Tình trạng vắng mặt (vắng mặt tại nơi làm việc mà không có lý do hợp lệ trong thời hạn quy định của luật pháp)'");
    WorkingHoursKinds.Write();

    // R.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.VacationByPregnancyAndChildbirth;
    WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
    WorkingHoursKinds.FullDescr = NStr("en='Maternity leave (vacation because of newborn baby adoption)';vi='Nghỉ thai sản (nghỉ phép do nuôi con nhỏ hoặc con nuôi)'");
    WorkingHoursKinds.Write();

    // RV.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.Holidays;
    WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
    WorkingHoursKinds.FullDescr = NStr("en='Working hours at weekends and non-work days, holidays';vi='Làm thêm ngày nghỉ lễ'");
    WorkingHoursKinds.Write();

    // RP.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.DowntimeByEmployerFault;
    WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
    WorkingHoursKinds.FullDescr = NStr("en='Dead time by employers fault';vi='Thời gian chết do lỗi của chủ lao động'");
	WorkingHoursKinds.Write();

    // C.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.Overtime;
    WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
    WorkingHoursKinds.FullDescr = NStr("en='Overtime duration';vi='Thời gian làm thêm'");
    WorkingHoursKinds.Write();

    // T.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.DiseaseWithoutPay;
    WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
    WorkingHoursKinds.FullDescr = NStr("en='Temporary incapacity to labor without benefit assignment in cases provided by the law';vi='Mất sức lao động tạm thời không được hưởng lợi ích trong trường hợp do pháp luật quy định'");
	WorkingHoursKinds.Write();

    // Y.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.VacationForTraining;
    WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
    WorkingHoursKinds.FullDescr = NStr("en='Additional leave due to training with an average pay, combining work and training';vi='Nghỉ phép bổ sung do đào tạo có lương trung bình mà có kết hợp công việc và đào tạo'");
	WorkingHoursKinds.Write();

	// YD.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.VacationForTrainingUnpaid;
    WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
    WorkingHoursKinds.FullDescr = NStr("en='Additional leave because of the training without salary';vi='Nghỉ bổ sung do đào tạo không lương'");
	WorkingHoursKinds.Write();

	// I.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.Work;
    WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
    WorkingHoursKinds.FullDescr = NStr("en='Working hours in the daytime';vi='Thời gian làm việc vào ban ngày'");
	WorkingHoursKinds.Write();

EndProcedure // FillWorkingTimeUsageClassifier()

//(15) Procedure fills in "Calculation parameters" and "Accruals and deductions kinds" catalogs.
//
Procedure FillCalculationParametersAndAccrualKinds()
	
	// Calculation parameters.
	
	// Sales amount by responsible (SAR)
	If Not SmallBusinessServer.SettlementsParameterExist("SalesAmountForResponsible") Then
		
		SARCalculationsParameters = Catalogs.CalculationsParameters.CreateItem();
		
		SARCalculationsParameters.Description 		 = NStr("en='Sales amount by responsible';vi='Số tiền bán hàng theo người chịu trách nhiệm'");
		SARCalculationsParameters.ID 	 = "SalesAmountForResponsible"; 
		SARCalculationsParameters.CustomQuery = True;
		SARCalculationsParameters.SpecifyValueAtPayrollCalculation = False;
		
		NewQueryParameter 						 = SARCalculationsParameters.QueryParameters.Add();
		NewQueryParameter.Name 					 = "AccountingCurrencyExchangeRate";
		NewQueryParameter.Presentation 			 = NStr("en='AccountingCurrencyExchangeRate';vi='Tiền tệ kế toán Tỷ giá hối đoái'");
		
		NewQueryParameter 						 = SARCalculationsParameters.QueryParameters.Add();
		NewQueryParameter.Name 					 = "DocumentCurrencyMultiplicity";
		NewQueryParameter.Presentation 			 = NStr("en='DocumentCurrencyMultiplicity';vi='Tiền tệ chứng từ đa tiền tệ'");
		
		NewQueryParameter 						 = SARCalculationsParameters.QueryParameters.Add();
		NewQueryParameter.Name 					 = "DocumentCurrencyRate";
		NewQueryParameter.Presentation 			 = NStr("en='DocumentCurrencyRate';vi='Tỷ lệ tiền tệ chứng từ'");
		
		NewQueryParameter 						 = SARCalculationsParameters.QueryParameters.Add();
		NewQueryParameter.Name 					 = "AccountingCurrecyFrequency";
		NewQueryParameter.Presentation 			 = NStr("en='AccountingCurrecyFrequency';vi='Tiền tệ kế toán Tần suất'");
		
		NewQueryParameter 						 = SARCalculationsParameters.QueryParameters.Add();
		NewQueryParameter.Name 					 = "RegistrationPeriod";
		NewQueryParameter.Presentation 			 = NStr("en='RegistrationPeriod';vi='Ghi nhận kỳ'");
		
		NewQueryParameter 						 = SARCalculationsParameters.QueryParameters.Add();
		NewQueryParameter.Name 					 = "Company";
		NewQueryParameter.Presentation 			 = NStr("en='Company';vi='Doanh nghiệp'");
		
		NewQueryParameter 						 = SARCalculationsParameters.QueryParameters.Add();
		NewQueryParameter.Name 					 = "Department";
		NewQueryParameter.Presentation 			 = NStr("en='Department';vi='Bộ phận'");
		
		NewQueryParameter 						 = SARCalculationsParameters.QueryParameters.Add();
		NewQueryParameter.Name 					 = "Employee";
		NewQueryParameter.Presentation 			 = NStr("en='Employee';vi='Người lao động'");
		
		
		SARCalculationsParameters.Query 			 = 
		"SELECT ALLOWED
		|	SUM(ISNULL(Sales.Amount * &AccountingCurrencyExchangeRate * &DocumentCurrencyMultiplicity / (&DocumentCurrencyRate * &AccountingCurrecyFrequency), 0)) AS SalesAmount
		|FROM
		|	AccumulationRegister.Sales AS Sales
		|WHERE
		|	Sales.Amount >= 0
		|	AND Sales.Period between BEGINOFPERIOD(&RegistrationPeriod, MONTH) AND ENDOFPERIOD(&RegistrationPeriod, MONTH)
		|	AND Sales.Company = &Company
		|	AND Sales.Department = &Department
		|	AND Sales.Document.Responsible = &Employee
		|	AND (CAST(Sales.Recorder AS Document.AcceptanceCertificate) REFS Document.AcceptanceCertificate
		|			OR CAST(Sales.Recorder AS Document.CustomerOrder) REFS Document.CustomerOrder
		|			OR CAST(Sales.Recorder AS Document.ProcessingReport) REFS Document.ProcessingReport
		|			OR CAST(Sales.Recorder AS Document.RetailReport) REFS Document.RetailReport
		|			OR CAST(Sales.Recorder AS Document.CustomerInvoice) REFS Document.CustomerInvoice
		|			OR CAST(Sales.Recorder AS Document.ReceiptCR) REFS Document.ReceiptCR)
		|
		|GROUP BY
		|	Sales.Document.Responsible";
		
		SARCalculationsParameters.Write();
		
	EndIf;
	
	// Fixed amount
	If Not SmallBusinessServer.SettlementsParameterExist("FixedAmount") Then
		
		ParameterCalculationsFixedAmount = Catalogs.CalculationsParameters.CreateItem();
		ParameterCalculationsFixedAmount.Description 				= NStr("en='Fixed amount';vi='Số tiền cố định'");
		ParameterCalculationsFixedAmount.ID 	 			= "FixedAmount";
		ParameterCalculationsFixedAmount.CustomQuery 			= False;
		ParameterCalculationsFixedAmount.SpecifyValueAtPayrollCalculation = True;
		ParameterCalculationsFixedAmount.Write();
		
	EndIf;
	
	// Norm of days
	If Not SmallBusinessServer.SettlementsParameterExist("NormDays") Then
		
		SettlementsParameterNormDays = Catalogs.CalculationsParameters.CreateItem();
		SettlementsParameterNormDays.Description 		 = NStr("en='Norm of days';vi='Định mức ngày'");
		SettlementsParameterNormDays.ID 	 = "NormDays";
		SettlementsParameterNormDays.CustomQuery = True;
		SettlementsParameterNormDays.SpecifyValueAtPayrollCalculation = False;
		NewQueryParameter 						 = SettlementsParameterNormDays.QueryParameters.Add();
		NewQueryParameter.Name 					 = "Company";
		NewQueryParameter.Presentation 			 = NStr("en='Company';vi='Doanh nghiệp'");
		NewQueryParameter 						 = SettlementsParameterNormDays.QueryParameters.Add();
		NewQueryParameter.Name 					 = "RegistrationPeriod";
		NewQueryParameter.Presentation 			 = NStr("en='Registration period';vi='Ghi nhận kỳ'");
		SettlementsParameterNormDays.Query 			 = 
		"SELECT
		|	SUM(1) AS NormDays
		|FROM
		|	InformationRegister.CalendarSchedules AS CalendarSchedules
		|		INNER JOIN Catalog.Companies AS Companies
		|		ON CalendarSchedules.Calendar = Companies.BusinessCalendar
		|			AND (Companies.Ref = &Company)
		|WHERE
		|	CalendarSchedules.Year = YEAR(&RegistrationPeriod)
		|	AND CalendarSchedules.ScheduleDate between BEGINOFPERIOD(&RegistrationPeriod, MONTH) AND ENDOFPERIOD(&RegistrationPeriod, MONTH)
		|	AND CalendarSchedules.DayIncludedInSchedule";
		
		SettlementsParameterNormDays.Write();
		
	EndIf;
	
	// Norm of hours
	If Not SmallBusinessServer.SettlementsParameterExist("NormHours") Then
		
		ParameterCalculationsNormHours = Catalogs.CalculationsParameters.CreateItem();
		ParameterCalculationsNormHours.Description 	  = NStr("en='Norm of hours';vi='Định mức giờ'");
		ParameterCalculationsNormHours.ID 	  = "NormHours";
		ParameterCalculationsNormHours.CustomQuery = True;
		ParameterCalculationsNormHours.SpecifyValueAtPayrollCalculation = False;
		NewQueryParameter 						 = ParameterCalculationsNormHours.QueryParameters.Add();
		NewQueryParameter.Name 					 = "Company";
		NewQueryParameter.Presentation 			 = NStr("en='Company';vi='Doanh nghiệp'");
		NewQueryParameter 						 = ParameterCalculationsNormHours.QueryParameters.Add();
		NewQueryParameter.Name 					 = "RegistrationPeriod";
		NewQueryParameter.Presentation 			 = NStr("en='Registration period';vi='Ghi nhận kỳ'");
		ParameterCalculationsNormHours.Query 			 = 
		"SELECT
		|	SUM(8) AS NormHours
		|FROM
		|	InformationRegister.CalendarSchedules AS CalendarSchedules
		|		INNER JOIN Catalog.Companies AS Companies
		|		ON CalendarSchedules.Calendar = Companies.BusinessCalendar
		|			AND (Companies.Ref = &Company)
		|WHERE
		|	CalendarSchedules.Year = YEAR(&RegistrationPeriod)
		|	AND CalendarSchedules.ScheduleDate between BEGINOFPERIOD(&RegistrationPeriod, MONTH) AND ENDOFPERIOD(&RegistrationPeriod, MONTH)
		|	AND CalendarSchedules.DayIncludedInSchedule";
		ParameterCalculationsNormHours.Write();
		
	EndIf;
	
	// Days worked
	If Not SmallBusinessServer.SettlementsParameterExist("DaysWorked") Then
		
		ParameterCalculationsDaysWorked = Catalogs.CalculationsParameters.CreateItem();
		ParameterCalculationsDaysWorked.Description 	  = NStr("en='Days worked';vi='Ngày làm việc'");
		ParameterCalculationsDaysWorked.ID	  = "DaysWorked";
		ParameterCalculationsDaysWorked.CustomQuery = False;
		ParameterCalculationsDaysWorked.SpecifyValueAtPayrollCalculation = True;
		ParameterCalculationsDaysWorked.Write();
		
	EndIf;
	
	// Hours worked
	If Not SmallBusinessServer.SettlementsParameterExist("HoursWorked") Then
		
		ParameterCalculationsHoursWorked = Catalogs.CalculationsParameters.CreateItem();
		ParameterCalculationsHoursWorked.Description 	   = NStr("en='Hours worked';vi='Giờ làm việc'");
		ParameterCalculationsHoursWorked.ID 	   = "HoursWorked";
		ParameterCalculationsHoursWorked.CustomQuery = False;
		ParameterCalculationsHoursWorked.SpecifyValueAtPayrollCalculation = True;
		ParameterCalculationsHoursWorked.Write();
		
	EndIf;
	
	// Tariff rate
	If Not SmallBusinessServer.SettlementsParameterExist("TariffRate") Then
		
		CalculationsParameterTariffRate = Catalogs.CalculationsParameters.CreateItem();
		CalculationsParameterTariffRate.Description 	  = NStr("en='Tariff rate';vi='Thuế suất'");
		CalculationsParameterTariffRate.ID 	  = "TariffRate";
		CalculationsParameterTariffRate.CustomQuery = False;
		CalculationsParameterTariffRate.SpecifyValueAtPayrollCalculation = True;
		CalculationsParameterTariffRate.Write();
		
	EndIf;
	
	// Worked by jobs
	If Not SmallBusinessServer.SettlementsParameterExist("HoursWorkedByJobs") Then
		
		ParameterCalculationsPieceDevelopment = Catalogs.CalculationsParameters.CreateItem();
		ParameterCalculationsPieceDevelopment.Description 	= NStr("en='Hours worked by jobs';vi='Giờ làm việc theo công việc'");
		ParameterCalculationsPieceDevelopment.ID = "HoursWorkedByJobs";
		ParameterCalculationsPieceDevelopment.CustomQuery = True;
		ParameterCalculationsPieceDevelopment.SpecifyValueAtPayrollCalculation = False;
		
		NewQueryParameter = ParameterCalculationsPieceDevelopment.QueryParameters.Add();
		NewQueryParameter.Name = "BeginOfPeriod"; 
		NewQueryParameter.Presentation = NStr("en='Begin of period';vi='Đầu kỳ'"); 
		
		NewQueryParameter = ParameterCalculationsPieceDevelopment.QueryParameters.Add();
		NewQueryParameter.Name = "EndOfPeriod";
		NewQueryParameter.Presentation = NStr("en='End of period';vi='Cuối kỳ'");
		
		NewQueryParameter = ParameterCalculationsPieceDevelopment.QueryParameters.Add();
		NewQueryParameter.Name = "Employee";
		NewQueryParameter.Presentation = NStr("en='Employee';vi='Người lao động'");
		
		NewQueryParameter = ParameterCalculationsPieceDevelopment.QueryParameters.Add();
		NewQueryParameter.Name = "Company"; 
		NewQueryParameter.Presentation = NStr("en='Company';vi='Doanh nghiệp'"); 
		
		NewQueryParameter = ParameterCalculationsPieceDevelopment.QueryParameters.Add();
		NewQueryParameter.Name = "Department";
		NewQueryParameter.Presentation = NStr("en='Department';vi='Bộ phận'");
		
		ParameterCalculationsPieceDevelopment.Query =
		"SELECT
		|	Source.ImportActualTurnover
		|FROM
		|	AccumulationRegister.WorkOrders.Turnovers(&BeginOfPeriod, &EndOfPeriod, Auto, ) AS Source
		|WHERE
		|	Source.Employee = &Employee
		|	AND Source.StructuralUnit = &Department
		|	AND Source.Company = &Company";
		
		ParameterCalculationsPieceDevelopment.Write();
		
	EndIf;
	
	// Accruals kinds
	If Not SmallBusinessServer.AccrualAndDeductionKindsInitialFillingPerformed() Then
		
		// Groups
		NewAccrual = Catalogs.AccrualAndDeductionKinds.CreateFolder();
		NewAccrual.Description = NStr("en='Accruals';vi='Tích lũy'");
		NewAccrual.Write();
		GroupAccrual = NewAccrual.Ref;
		
		NewAccrual = Catalogs.AccrualAndDeductionKinds.CreateFolder();
		NewAccrual.Description = NStr("en='Deductions';vi='Khấu trừ'");
		NewAccrual.Write();
		GroupDeduction = NewAccrual.Ref;
		
		// Salary by days
		NewAccrual = Catalogs.AccrualAndDeductionKinds.CreateItem();
		NewAccrual.Parent = GroupAccrual;
		NewAccrual.Description = NStr("en='Salary by days';vi='Mức lương theo ngày'");
		NewAccrual.Type = Enums.AccrualAndDeductionTypes.Accrual;
		NewAccrual.GLExpenseAccount = ChartsOfAccounts.Managerial.AdministrativeExpenses;
		NewAccrual.Formula = "[TariffRate] * [DaysWorked] / [NormDays]";
		NewAccrual.Write();
		
		// Salary by hours
		NewAccrual = Catalogs.AccrualAndDeductionKinds.CreateItem();
		NewAccrual.Parent = GroupAccrual;
		NewAccrual.Description = NStr("en='Salary by hours';vi='Mức lương theo giờ'");
		NewAccrual.Type = Enums.AccrualAndDeductionTypes.Accrual;
		NewAccrual.GLExpenseAccount = ChartsOfAccounts.Managerial.IndirectExpenses;
		NewAccrual.Formula = "[TariffRate] * [HoursWorked] / [NormHours]";
		NewAccrual.Write();
		
		// Payment by jobs
		NewAccrual = Catalogs.AccrualAndDeductionKinds.CreateItem();
		NewAccrual.Parent = GroupAccrual;
		NewAccrual.Description = NStr("en='Payment by jobs';vi='Thạnh toán theo công việc'");
		NewAccrual.Type = Enums.AccrualAndDeductionTypes.Accrual;
		NewAccrual.GLExpenseAccount = ChartsOfAccounts.Managerial.UnfinishedProduction;
		NewAccrual.Formula = "[TariffRate] * [HoursProcessedByJobs]";
		NewAccrual.Write();
		
		// Sales fee by responsible
		NewAccrual = Catalogs.AccrualAndDeductionKinds.CreateItem();
		NewAccrual.Parent = GroupAccrual;
		NewAccrual.Description = NStr("en='Sales fee by responsible';vi='Phí bán hàng theo người chịu trách nhiệm'");
		NewAccrual.Type = Enums.AccrualAndDeductionTypes.Accrual;
		NewAccrual.GLExpenseAccount = ChartsOfAccounts.Managerial.UnfinishedProduction;
		NewAccrual.Formula = "[SalesAmountByResponsible]  /  100 * [TariffRate]";
		NewAccrual.Write();
		
		// Payment by job sheets
		NewAccrualReference = Catalogs.AccrualAndDeductionKinds.PieceRatePayment;
		NewAccrual = NewAccrualReference.GetObject();
		NewAccrual.Parent = GroupAccrual;
		NewAccrual.Description = NStr("en='Accord payment (tariff)';vi='Lương khoán (biểu phí)'");
		NewAccrual.Type = Enums.AccrualAndDeductionTypes.Accrual;
		NewAccrual.GLExpenseAccount = ChartsOfAccounts.Managerial.UnfinishedProduction;
		NewAccrual.Formula = "";
		NewAccrual.Write();
		
		// Accord payment in percent
		NewAccrualReference = Catalogs.AccrualAndDeductionKinds.PieceRatePaymentPercent;
		NewAccrual = NewAccrualReference.GetObject();
		NewAccrual.Parent = GroupAccrual;
		NewAccrual.Description = NStr("en='Accord payment (% from amount)';vi='Lương khoán (% từ số tiền)'");
		NewAccrual.Type = Enums.AccrualAndDeductionTypes.Accrual;
		NewAccrual.GLExpenseAccount = ChartsOfAccounts.Managerial.UnfinishedProduction;
		NewAccrual.Formula = "";
		NewAccrual.Write();
		
		//Fixed amount
		NewAccrualReference = Catalogs.AccrualAndDeductionKinds.FixedAmount;
		NewAccrual = NewAccrualReference.GetObject();
		NewAccrual.Code = "";
		NewAccrual.Parent = GroupAccrual;
		NewAccrual.Description = NStr("en='Accord payment (fixed amount)';vi='Lương khoán (số tiền cố định)'");
		NewAccrual.Type = Enums.AccrualAndDeductionTypes.Accrual;
		NewAccrual.GLExpenseAccount = ChartsOfAccounts.Managerial.UnfinishedProduction;
		NewAccrual.Formula = "[FixedAmount]";
		NewAccrual.SetNewCode();
		NewAccrual.Write();
		
		//Interest on loan
		NewAccrualReference = Catalogs.AccrualAndDeductionKinds.InterestOnLoan;
		NewAccrual = NewAccrualReference.GetObject();
		NewAccrual.Code = "";
		NewAccrual.Parent = GroupDeduction;
		NewAccrual.Description = NStr("en='Interest on loan';vi='Lãi vay'");
		NewAccrual.Type = Enums.AccrualAndDeductionTypes.Deduction;
		NewAccrual.SetNewCode();
		NewAccrual.Write();
		
		//Repayment of loan from salary
		NewAccrualReference = Catalogs.AccrualAndDeductionKinds.RepaymentOfLoanFromSalary;
		NewAccrual = NewAccrualReference.GetObject();
		NewAccrual.Code = "";
		NewAccrual.Parent = GroupDeduction;
		NewAccrual.Description = NStr("en='Repayment of loan from salary';vi='Trả nợ vay từ lương'");
		NewAccrual.Type = Enums.AccrualAndDeductionTypes.Deduction;
		NewAccrual.SetNewCode();
		NewAccrual.Write();
		
	EndIf;
	
EndProcedure // FillCalculationAndAccrualKindsParameters()

//(24) Procedure fills in the selection settings on the first start
//
Procedure FillFilterUserSettings()
	
	CurrentUser = Users.CurrentUser();
	
	SmallBusinessServer.SetStandardFilterSettings(CurrentUser);
	
EndProcedure // FillCustomSelectionSettings()

//(29) procedure fills in contracts forms from layout.
//
Procedure FillContractsForms()
	
	LeaseAgreementTemplate 			= Catalogs.ContractForms.GetTemplate("LeaseAgreementTemplate");
	PurchaseAndSaleContractTemplate 	= Catalogs.ContractForms.GetTemplate("PurchaseAndSaleContractTemplate");
	ServicesContractTemplate 	= Catalogs.ContractForms.GetTemplate("ServicesContractTemplate");
	SupplyContractTemplate 		= Catalogs.ContractForms.GetTemplate("SupplyContractTemplate");
	
	Templates = New Array(4);
	Templates[0] = LeaseAgreementTemplate;
	Templates[1] = PurchaseAndSaleContractTemplate;
	Templates[2] = ServicesContractTemplate;
	Templates[3] = SupplyContractTemplate;
	
	LayoutNames = New Array(4);
	LayoutNames[0] = "LeaseAgreementTemplate";
	LayoutNames[1] = "PurchaseAndSaleContractTemplate";
	LayoutNames[2] = "ServicesContractTemplate";
	LayoutNames[3] = "SupplyContractTemplate";
	
	Forms = New Array(4);
	Forms[0] = Catalogs.ContractForms.LeaseAgreement.Ref.GetObject();
	Forms[1] = Catalogs.ContractForms.PurchaseAndSaleContract.Ref.GetObject();
	Forms[2] = Catalogs.ContractForms.ServicesContract.Ref.GetObject();
	Forms[3] = Catalogs.ContractForms.SupplyContract.Ref.GetObject();
	
	Iterator = 0;
	While Iterator < Templates.Count() Do 
		
		ContractTemplate = Catalogs.ContractForms.GetTemplate(LayoutNames[Iterator]);
		
		TextHTML = ContractTemplate.GetText();
		Attachments = New Structure;
		
		EditableParametersNumber = StrOccurrenceCount(TextHTML, "{FilledField");
		
		Forms[Iterator].EditableParameters.Clear();
		ParameterNumber = 1;
		While ParameterNumber <= EditableParametersNumber Do 
			NewRow = Forms[Iterator].EditableParameters.Add();
			NewRow.Presentation = "{FilledField" + ParameterNumber + "}";
			NewRow.ID = "parameter" + ParameterNumber;
			
			ParameterNumber = ParameterNumber + 1;
		EndDo;
		
		FormattedDocumentStructure = New Structure;
		FormattedDocumentStructure.Insert("HTMLText", TextHTML);
		FormattedDocumentStructure.Insert("Attachments", Attachments);
		
		Forms[Iterator].Form = New ValueStorage(FormattedDocumentStructure);
		Forms[Iterator].PredefinedFormTemplate = LayoutNames[Iterator];
		Forms[Iterator].EditableParametersNumber = EditableParametersNumber;
		Forms[Iterator].Write();
		
		Iterator = Iterator + 1;
		
	EndDo;
	
EndProcedure

// Procedure fills in the passed object catalog and outputs message.
// It is intended to invoke from procedures of filling and processing the infobase directories.
//
// Parameters:
//  CatalogObject - an object that required record.
//
Procedure WriteCatalogObject(CatalogObject, Inform = False) Export

	If Not CatalogObject.Modified() Then
		Return;
	EndIf;

	If CatalogObject.IsNew() Then
		If CatalogObject.IsFolder Then
			MessageStr = NStr("en='Group of catalog ""%1"" is created, code: ""%2"", name: ""%3""';ru='Создана группа справочника ""%1"", код: ""%2"", наименование: ""%3""';vi='Tạo nhóm danh mục ""%1"", mã: ""%2"", tên gọi: ""%3""'") ;
		Else
			MessageStr = NStr("en='Item of catalog ""%1"" is created, code: ""%2"", name: ""%3""';ru='Создан элемент справочника ""%1"", код: ""%2"", наименование: ""%3""';vi='Tạo phần tử danh mục ""%1"", mã: ""%2"", tên gọi: ""%3""'") ;
		EndIf; 
	Else
		If CatalogObject.IsFolder Then
			MessageStr = NStr("en='Catalog group ""%1"" is processed, code: ""%2"", name: ""%3""';ru='Обработана группа справочника ""%1"", код: ""%2"", наименование: ""%3""';vi='Đã xử lý phần tử danh mục ""%1"", mã: ""%2"", tên gọi: ""%3""'") ;
		Else
			MessageStr = NStr("en='Catalog item ""%1"" is processed, code: ""%2"", name: ""%3""';ru='Обработан элемент справочника ""%1"", код: ""%2"", наименование: ""%3""';vi='Đã xử lý phần tử danh mục ""%1"", mã: ""%2"", tên gọi: ""%3""'") ;
		EndIf; 
	EndIf;

	If CatalogObject.Metadata().CodeLength > 0 Then
		FullCode = CatalogObject.FullCode();
	Else
		FullCode = NStr("en='<without code>';ru='<без кода>';vi='<không có mã>'");
	EndIf; 
	MessageStr = StringFunctionsClientServer.SubstituteParametersInString(MessageStr, CatalogObject.Metadata().Synonym, FullCode, CatalogObject.Description);

	Try
		CatalogObject.Write();
		If Inform = True Then
			CommonUseClientServer.MessageToUser(MessageStr, CatalogObject);
		EndIf;

	Except

		MessageText = NStr("en='Cannot finish action: %1';ru='Не удалось завершить действие: %1';vi='Không thể kết thúc thao tác: %1'");
		MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText, MessageStr);

		CommonUseClientServer.MessageToUser(MessageText);

		ErrorDescription = ErrorInfo();
		WriteLogEvent(MessageText, EventLogLevel.Error,,, ErrorDescription.Definition);

	EndTry;

EndProcedure

// End. Procedures supporting the first start

///////////////////////////////////////////////////////////////////////////////
// First start handlers (SB)

// Procedure fills in empty IB.
//
Procedure FirstLaunch() Export
	
	BeginTransaction();
	
	// 1. We will load chart of accounts.
	ImportManagerialChartOfAccountsFirstLaunch();
	
	// 2. Fill in kind and area of business.
	Constants.ActivityKind.Set(Enums.CompanyActivityKinds.TradeAndServices);
	Constants.FunctionalOptionUseWorkSubsystem.Set(True);
	
	OthersBusinessActivityRefs	= Catalogs.BusinessActivities.Other;
	OthersBusinessActivity								= OthersBusinessActivityRefs.GetObject();
	OthersBusinessActivity.GLAccountRevenueFromSales	= ChartsOfAccounts.Managerial.OtherIncome;
	OthersBusinessActivity.GLAccountCostOfSales			= ChartsOfAccounts.Managerial.OtherExpenses;
	OthersBusinessActivity.ProfitGLAccount				= ChartsOfAccounts.Managerial.ProfitsAndLossesWithoutProfitTax;
	OthersBusinessActivity.Write();
	
	IsMainBusinessActivityReference	= Catalogs.BusinessActivities.MainActivity;
	IsMainBusinessActivity								= IsMainBusinessActivityReference.GetObject();
	IsMainBusinessActivity.GLAccountRevenueFromSales	= ChartsOfAccounts.Managerial.SalesRevenue;
	IsMainBusinessActivity.GLAccountCostOfSales			= ChartsOfAccounts.Managerial.CostOfGoodsSold;
	IsMainBusinessActivity.ProfitGLAccount				= ChartsOfAccounts.Managerial.ProfitsAndLossesWithoutProfitTax;
	IsMainBusinessActivity.Write();
	
	Constants.HomeCountry.Set(Catalogs.WorldCountries.Russia);
	
	// 7. Fill the Calendar under BusinessCalendar.
	Calendar = SmallBusinessServer.GetCalendarByProductionCalendaRF(); 
	If Calendar = Undefined Then
		
		CreateRussianFederationFiveDaysCalendar();
		Calendar = SmallBusinessServer.GetCalendarByProductionCalendaRF(); 
		
	EndIf;
	
	// 8. Fill in companies.
	OurCompanyRef	= Catalogs.Companies.MainCompany;
	OurCompany		= OurCompanyRef.Ref;
	
	// 9. Fill in departments.
	MainDepartmentReference	= Catalogs.StructuralUnits.MainDepartment;
	MainDepartment						= MainDepartmentReference.GetObject();
	MainDepartment.Company				= OurCompany.Ref;
	MainDepartment.StructuralUnitType	= Enums.StructuralUnitsTypes.Department;
	MainDepartment.Write();
	
	// 10. Fill in the main warehouse.
	MainWarehouseReference	= Catalogs.StructuralUnits.MainWarehouse;
	MainWarehouse						= MainWarehouseReference.GetObject();
	MainWarehouse.StructuralUnitType	= Enums.StructuralUnitsTypes.Warehouse;
	MainWarehouse.Company				= OurCompany.Ref;
	MainWarehouse.Write();
	
	// 12. Fill in constants.
	Constants.ControlBalancesOnPosting.Set(True);
	Constants.FunctionalOptionUseVAT.Set(True);
	
	If Not CommonUseReUse.CanUseSeparatedData() Then
		
		Constants.ExtractFileTextsAtServer.Set(true);
		
	EndIf;
	
	Constants.DoNotPostDocumentsWithIncorrectContracts.Set(False);
	Constants.ExchangeRateDifferencesCalculationFrequency.Set(Enums.ExchangeRateDifferencesCalculationFrequency.OnlyOnPeriodClosure);
	If Not CommonUseReUse.DataSeparationEnabled() Then
		Constants.DistributedInformationBaseNodePrefix.Set(DataExchangeOverridable.InfobasePrefixByDefault());
	EndIf;
	
	// 13. Fill in planning period.
	FillPlanningPeriodFirstLaunch();
	
	// 15. Fill in calculation and accruals kinds parameters.
	FillCalculationParametersAndAccrualKinds();
	
	// 16. Fill in properties sets.
	MainNYReference = Catalogs.ProductsAndServicesCategories.WithoutCategory;
	MainNG = MainNYReference.GetObject();
	MainNG.Write();
	MainNG.Write();
	
	// 17. Fill in attributes of the predefined measurement units.
		
	// Piece.
	PcsRefs = Catalogs.UOMClassifier.pcs;
	PcsObject = PcsRefs.GetObject();
	PcsObject.DescriptionFull			= "Piece";
	PcsObject.InternationalAbbreviation	= "PCE";
	PcsObject.Write();
	
	// Hour.
	hRef = Catalogs.UOMClassifier.h;
	chObject = hRef.GetObject();
	chObject.DescriptionFull			= "Hour";
	chObject.InternationalAbbreviation	= "HUR";
	chObject.Write();
	
	// 18. Fill in customer orders states.
	OpenOrderState = Catalogs.CustomerOrderStates.Open;
	OpenOrderStateObject				= OpenOrderState.GetObject();
	OpenOrderStateObject.OrderStatus	= Enums.OrderStatuses.Open;
	OpenOrderStateObject.Write();
	
	PlannedObjectOrderStatus = Catalogs.CustomerOrderStates.CreateItem();
	PlannedObjectOrderStatus.Description	= NStr("en = 'In process'; vi = 'Đang thực hiện'");
	PlannedObjectOrderStatus.OrderStatus	= Enums.OrderStatuses.InProcess;
	PlannedObjectOrderStatus.Write();
	
	Constants.CustomerOrdersInProgressStatus.Set(PlannedObjectOrderStatus.Ref);
	
	Color = StyleColors.PastEvent;
	CompletedOrderStateObject = Catalogs.CustomerOrderStates.CreateItem();
	CompletedOrderStateObject.Description	= NStr("en = 'Completed'; vi = 'Đã hoàn thành'");
	CompletedOrderStateObject.OrderStatus	= Enums.OrderStatuses.Completed;
	CompletedOrderStateObject.Color			= New ValueStorage(Color);
	CompletedOrderStateObject.Write();
	
	Color = StyleColors.ExplanationTextError;
	CompletedOrderStateObject = Catalogs.CustomerOrderStates.CreateItem();
	CompletedOrderStateObject.Description	= NStr("en = 'Closed'; vi = 'Đã đóng'");
	CompletedOrderStateObject.OrderStatus	= Enums.OrderStatuses.Closed;
	CompletedOrderStateObject.Color			= New ValueStorage(Color);
	CompletedOrderStateObject.Write();
	
	Constants.CustomerOrdersCompletedStatus.Set(CompletedOrderStateObject.Ref);
	
	// 19. Purchase orders.
	OpenOrderState = Catalogs.PurchaseOrderStates.Open;
	OpenOrderStateObject				= OpenOrderState.GetObject();
	OpenOrderStateObject.OrderStatus	= Enums.OrderStatuses.Open;
	OpenOrderStateObject.Write();
	
	PlannedObjectOrderStatus = Catalogs.PurchaseOrderStates.CreateItem();
	PlannedObjectOrderStatus.Description	= NStr("en = 'In process'; vi = 'Đang thực hiện'");
	PlannedObjectOrderStatus.OrderStatus	= Enums.OrderStatuses.InProcess;
	PlannedObjectOrderStatus.Write();
	
	Constants.PurchaseOrdersInProgressStatus.Set(PlannedObjectOrderStatus.Ref);
	
	Color = StyleColors.PastEvent;
	CompletedOrderStateObject = Catalogs.PurchaseOrderStates.CreateItem();
	CompletedOrderStateObject.Description	= NStr("en = 'Completed'; vi = 'Đã hoàn thành'");
	CompletedOrderStateObject.OrderStatus	= Enums.OrderStatuses.Completed;
	CompletedOrderStateObject.Color			= New ValueStorage(Color);
	CompletedOrderStateObject.Write();
	
	Constants.PurchaseOrdersCompletedStatus.Set(CompletedOrderStateObject.Ref);
	
	// 20. Fill in production orders states.
	OpenOrderState = Catalogs.ProductionOrderStates.Open;
	OpenOrderStateObject = OpenOrderState.GetObject();
	OpenOrderStateObject.OrderStatus = Enums.OrderStatuses.Open;
	OpenOrderStateObject.Write();
	
	PlannedObjectOrderStatus = Catalogs.ProductionOrderStates.CreateItem();
	PlannedObjectOrderStatus.Description = NStr("en = 'In process'; vi = 'Đang thực hiện'");
	PlannedObjectOrderStatus.OrderStatus = Enums.OrderStatuses.InProcess;
	PlannedObjectOrderStatus.Write();
	
	Constants.ProductionOrdersInProgressStatus.Set(PlannedObjectOrderStatus.Ref);
	
	CompletedOrderStateObject = Catalogs.ProductionOrderStates.CreateItem();
	CompletedOrderStateObject.Description = NStr("en = 'Completed'; vi = 'Đã hoàn thành'");
	CompletedOrderStateObject.OrderStatus = Enums.OrderStatuses.Completed;
	Color = StyleColors.PastEvent;
	CompletedOrderStateObject.Color = New ValueStorage(Color);
	CompletedOrderStateObject.Write();

	Constants.ProductionOrdersCompletedStatus.Set(CompletedOrderStateObject.Ref);
	
	// 21. Set the date of movements change by order warehouse.
	Constants.UpdateDateToRelease_1_2_1.Set("19800101");
	
	// 22. Set a balances control flag when the CR receipts are given.
	Constants.ControlBalancesDuringCreationCRReceipts.Set(True);
	
	// 23. Selection settings
	FillFilterUserSettings();
	
	// 24. Constant PlannedTotalsOptimizationDate
	Constants.PlannedTotalsOptimizationDate.Set(EndOfMonth(AddMonth(CurrentSessionDate(), 1)));
	
	// 25. Contact information
	ContactInformationSB.SetPropertiesPredefinedContactInformationKinds();
	
	// 26. Price-list constants.
	Constants.PriceListShowCode.Set(Enums.YesNo.Yes);
	Constants.PriceListShowFullDescr.Set(Enums.YesNo.No);
	Constants.PriceListUseProductsAndServicesHierarchy.Set(True);
	Constants.FormPriceListByAvailabilityInWarehouses.Set(False);
	
	// 29. Fill in contracts forms.
	FillContractsForms();

	// 31. Constant.OffsetAdvancesDebtsAutomatically
	Constants.OffsetAdvancesDebtsAutomatically.Set(Enums.YesNo.No);
	
	// 32. BPO
	EquipmentManagerServerCallOverridable.RefreshSuppliedDrivers();
	
	// 33. Fill customer acquisition channels.
	Catalogs.CustomerAcquisitionChannels.FillAvailableCustomerAcquisitionChannels();
	
	// 34. Fill default distribution constant.
	ManualInventoryDistributionByDefault();
	
	CommitTransaction();
	
EndProcedure // FirstLaunch()

Procedure DefaultFirstLaunch() Export
	
	BeginTransaction();
	
	// 1. We will load chart of accounts.
	// It fills chart of accounts from template
	FillManagerialChartOfAccountsByDefault();
	
	// 3. Fill in taxes kinds.
	FillTaxTypesFirstLaunch();
	
	// 4. Fill in currencies.
	CurrencyObject = CatalogObjectCurrenciesByCode("704");
	InfobaseUpdate.WriteData(CurrencyObject);
	WorkWithCurrencyRates.CheckRateOn01Correctness_01_1980(CurrencyObject.Ref);
	
	USRef = CatalogObjectCurrenciesByCode("840");
	InfobaseUpdate.WriteData(USRef);
	WorkWithCurrencyRates.CheckRateOn01Correctness_01_1980(USRef.Ref);
	
	// 5. Fill in VAT rates.
	WithoutVAT	= FillVATRatesFirstLaunch();
	
	// 6. Fill petty cashes.
	PettyCashDefault = Catalogs.PettyCashes.CreateItem();
	PettyCashDefault.Description		= NStr("en='Main petty cash';ru='Основная касса';vi='Quỹ tiền mặt chính'");
	PettyCashDefault.CurrencyByDefault	= CurrencyObject.Ref;
	PettyCashDefault.GLAccount			= ChartsOfAccounts.Managerial.PettyCash;
	PettyCashDefault.Write();
	
	// 8. Fill in companies.
	OurCompanyRef	= Catalogs.Companies.MainCompany;
	OurCompany							= OurCompanyRef.GetObject();
	OurCompany.DescriptionFull			= NStr("en='LLC ""Our company""';ru='ООО ""Наша фирма""';vi='Công ty TNHH ""Doanh nghiệp chúng ta""'");
	OurCompany.Prefix					= NStr("en='OF-';ru='НФ-';vi='VP'");
	OurCompany.LegalEntityIndividual	= Enums.CounterpartyKinds.LegalEntity;
	OurCompany.IncludeVATInPrice		= False;
	OurCompany.PettyCashByDefault		= PettyCashDefault.Ref;
	OurCompany.DefaultVATRate			= WithoutVAT;
	OurCompany.BusinessCalendar      	= SmallBusinessServer.GetCalendarByProductionCalendaRF();
	OurCompany.Write();
	
	// 11. Fill in prices kinds.
	// Wholesale.
	WholesaleRef = Catalogs.PriceKinds.Wholesale;
	Wholesale					= WholesaleRef.GetObject();
	Wholesale.PriceCurrency		= CurrencyObject.Ref;
	Wholesale.PriceIncludesVAT	= False;
	Wholesale.RoundingOrder		= Enums.RoundingMethods.Round1;
	Wholesale.RoundUp			= False;
	Wholesale.PriceFormat		= "ND=15; NFD=2";
	Wholesale.Write();
	
	// Accountable.
	AccountingReference = Catalogs.PriceKinds.Accounting;
	Accounting1					= AccountingReference.GetObject();
	Accounting1.PriceCurrency	= CurrencyObject.Ref;
	Accounting1.PriceIncludesVAT	= False;
	Accounting1.RoundingOrder	= Enums.RoundingMethods.Round1;
	Accounting1.RoundUp			= False;
	Accounting1.PriceFormat		= "ND=15; NFD=2";
	Accounting1.Write();
	
	// 12. Fill in constants.
	Constants.AccountingCurrency.Set(CurrencyObject.Ref);
	Constants.NationalCurrency.Set(CurrencyObject.Ref);
	
	// 14. Fill in classifier of the working time use.
	FillClassifierOfWorkingTimeUsage();
	
	// 34. Fill legal forms
	Catalogs.LegalForms.FillAvailableLegalForms();
	
	CommitTransaction();
	
EndProcedure // FirstLaunch()

Procedure FillManagerialChartOfAccountsByDefault()

	AccountingServer.FillChartOfAccountsByDefault();

EndProcedure

// Update handlers
Procedure FillStructuralUnitTypes() Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Doc.Ref AS Production
	|FROM
	|	Document.InventoryAssembly AS Doc
	|WHERE
	|	NOT Doc.StructuralUnit = VALUE(Catalog.StructuralUnits.EmptyRef)
	|	AND Doc.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.EmptyRef)
	|	AND NOT Doc.ProductsStructuralUnit = VALUE(Catalog.StructuralUnits.EmptyRef)
	|	AND Doc.ProductsStructuralUnitType = VALUE(Enum.StructuralUnitsTypes.EmptyRef)
	|	AND NOT Doc.DisposalsStructuralUnit = VALUE(Catalog.StructuralUnits.EmptyRef)
	|	AND Doc.DisposalsStructuralUnitType = VALUE(Enum.StructuralUnitsTypes.EmptyRef)
	|	AND NOT Doc.InventoryStructuralUnit = VALUE(Catalog.StructuralUnits.EmptyRef)
	|	AND Doc.InventoryStructuralUnitType = VALUE(Enum.StructuralUnitsTypes.EmptyRef)";
	
	Result = Query.Execute();
	Selection = Result.Select();
	While Selection.Next() Do
		
		DocInventoryAssembly = Selection.Production.GetObject();
		DocInventoryAssembly.FillStructuralUnitsTypes();
		DocInventoryAssembly.DataExchange.Load = True;
		DocInventoryAssembly.Write();
		
	EndDo;
	
	 Query.Text = 
	"SELECT
	|	Doc.Ref AS Doc
	|FROM
	|	Document.InventoryReceipt AS Doc
	|WHERE
	|	NOT Doc.StructuralUnit = VALUE(Catalog.StructuralUnits.EmptyRef)
	|	AND Doc.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.EmptyRef)";
	
	Result = Query.Execute();
	Selection = Result.Select();
	While Selection.Next() Do
		
		DocInventoryReceipt = Selection.Doc.GetObject();
		DocInventoryReceipt.FillStructuralUnitsTypes();
		DocInventoryReceipt.DataExchange.Load = True;
		DocInventoryReceipt.Write();
		
	EndDo;

	Query.Text = 
	"SELECT
	|	Doc.Ref AS Doc
	|FROM
	|	Document.InventoryReconciliation AS Doc
	|WHERE
	|	NOT Doc.StructuralUnit = VALUE(Catalog.StructuralUnits.EmptyRef)
	|	AND Doc.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.EmptyRef)";
	
	Result = Query.Execute();
	Selection = Result.Select();
	While Selection.Next() Do
		
		DocInventoryReconciliation = Selection.Doc.GetObject();
		DocInventoryReconciliation.FillStructuralUnitsTypes();
		DocInventoryReconciliation.DataExchange.Load = True;
		DocInventoryReconciliation.Write();
		
	EndDo;
	
	Query.Text = 
	"SELECT
	|	Doc.Ref AS Doc
	|FROM
	|	Document.InventoryTransfer AS Doc
	|WHERE
	|	NOT Doc.StructuralUnit = VALUE(Catalog.StructuralUnits.EmptyRef)
	|	AND Doc.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.EmptyRef)
	|	AND NOT Doc.StructuralUnitPayee = VALUE(Catalog.StructuralUnits.EmptyRef)
	|	AND Doc.StructuralUnitPayeeType = VALUE(Enum.StructuralUnitsTypes.EmptyRef)";

	Result = Query.Execute();
	Selection = Result.Select();
	While Selection.Next() Do
		
		DocInventoryTransfer = Selection.Doc.GetObject();
		DocInventoryTransfer.FillStructuralUnitsTypes();
		DocInventoryTransfer.DataExchange.Load = True;
		DocInventoryTransfer.Write();
		
	EndDo;

	Query.Text = 
	"SELECT
	|	Doc.Ref AS Doc
	|FROM
	|	Document.InventoryWriteOff AS Doc
	|WHERE
	|	NOT Doc.StructuralUnit = VALUE(Catalog.StructuralUnits.EmptyRef)
	|	AND Doc.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.EmptyRef)";

	Result = Query.Execute();
	Selection = Result.Select();
	While Selection.Next() Do
		
		DocInventoryWriteOff = Selection.Doc.GetObject();
		DocInventoryWriteOff.FillStructuralUnitsTypes();
		DocInventoryWriteOff.DataExchange.Load = True;
		DocInventoryWriteOff.Write();
		
	EndDo;
	
	
	Query.Text = 
	"SELECT
	|	Doc.Ref AS Doc
	|FROM
	|	Document.ProductionOrder AS Doc
	|WHERE
	|	NOT Doc.StructuralUnit = VALUE(Catalog.StructuralUnits.EmptyRef)
	|	AND Doc.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.EmptyRef)
	|	AND NOT Doc.StructuralUnitReserve = VALUE(Catalog.StructuralUnits.EmptyRef)
	|	AND Doc.StructuralUnitReserveType = VALUE(Enum.StructuralUnitsTypes.EmptyRef)";

	Result = Query.Execute();
	Selection = Result.Select();
	While Selection.Next() Do
		
		DocProductionOrder = Selection.Doc.GetObject();
		DocProductionOrder.FillStructuralUnitsTypes();
		DocProductionOrder.DataExchange.Load = True;
		DocProductionOrder.Write();
		
	EndDo;

	Query.Text = 
	"SELECT
	|	Doc.Ref AS Doc
	|FROM
	|	Document.RetailReport AS Doc
	|WHERE
	|	NOT Doc.StructuralUnit = VALUE(Catalog.StructuralUnits.EmptyRef)
	|	AND Doc.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.EmptyRef)";

	Result = Query.Execute();
	Selection = Result.Select();
	While Selection.Next() Do
		
		DocRetailReport = Selection.Doc.GetObject();
		DocRetailReport.FillStructuralUnitsTypes();
		DocRetailReport.DataExchange.Load = True;
		DocRetailReport.Write();
		
	EndDo;

	
	Query.Text = 
	"SELECT
	|	Doc.Ref AS Doc
	|FROM
	|	Document.SubcontractorReport AS Doc
	|WHERE
	|	NOT Doc.StructuralUnit = VALUE(Catalog.StructuralUnits.EmptyRef)
	|	AND Doc.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.EmptyRef)";

	Result = Query.Execute();
	Selection = Result.Select();
	While Selection.Next() Do
		
		DocSubcontractorReport = Selection.Doc.GetObject();
		DocSubcontractorReport.FillStructuralUnitsTypes();
		DocSubcontractorReport.DataExchange.Load = True;
		DocSubcontractorReport.Write();
		
	EndDo;
	
	Query.Text = 
	"SELECT
	|	Doc.Ref AS Doc
	|FROM
	|	Document.SupplierInvoice AS Doc
	|WHERE
	|	NOT Doc.StructuralUnit = VALUE(Catalog.StructuralUnits.EmptyRef)
	|	AND Doc.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.EmptyRef)";

	Result = Query.Execute();
	Selection = Result.Select();
	While Selection.Next() Do
		
		DocSupplierInvoice = Selection.Doc.GetObject();
		DocSupplierInvoice.FillStructuralUnitsTypes();
		DocSupplierInvoice.DataExchange.Load = True;
		DocSupplierInvoice.Write();
		
	EndDo;
	
	Query.Text = 
	"SELECT
	|	Doc.Ref AS Doc
	|FROM
	|	Document.TransferBetweenCells AS Doc
	|WHERE
	|	NOT Doc.StructuralUnit = VALUE(Catalog.StructuralUnits.EmptyRef)
	|	AND Doc.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.EmptyRef)";

	Result = Query.Execute();
	Selection = Result.Select();
	While Selection.Next() Do
		
		DocTransferBetweenCells = Selection.Doc.GetObject();
		DocTransferBetweenCells.FillStructuralUnitsTypes();
		DocTransferBetweenCells.DataExchange.Load = True;
		DocTransferBetweenCells.Write();
		
	EndDo;
	
	
	Query.Text = 
	"SELECT
	|	Cat.Ref AS Cat
	|FROM
	|	Catalog.CashRegisters AS Cat
	|WHERE
	|	NOT Cat.StructuralUnit = VALUE(Catalog.StructuralUnits.EmptyRef)
	|	AND Cat.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.EmptyRef)";

	Result = Query.Execute();
	Selection = Result.Select();
	While Selection.Next() Do
		
		CatCashRegisters = Selection.Cat.GetObject();
		CatCashRegisters.FillStructuralUnitsTypes();
		CatCashRegisters.DataExchange.Load = True;
		CatCashRegisters.Write();
		
	EndDo;


EndProcedure

Procedure FillDocumentsAttributePosition() Export
	
	// 
	Query = New Query;
	Query.Text = 
	"SELECT
	|	InventoryAssembly.Ref AS Ref
	|FROM
	|	Document.InventoryAssembly AS InventoryAssembly
	|WHERE
	|	InventoryAssembly.CustomerOrderPosition = &EmptyPosition";
	Query.SetParameter("EmptyPosition", Enums.AttributePositionOnForm.EmptyRef());
	Result = Query.Execute();
	Selection = Result.Select();
	While Selection.Next() Do
		DocObj = Selection.Ref.GetObject();
		DocObj.CustomerOrderPosition = Enums.AttributePositionOnForm.InHeader;
		DocObj.Write();
	EndDo;
	
	
	Query.Text = 
	"SELECT
	|	JobSheet.Ref AS Ref
	|FROM
	|	Document.JobSheet AS JobSheet
	|WHERE
	|	JobSheet.StructuralUnitPosition = &EmptyPosition
	|
	|UNION ALL
	|
	|SELECT
	|	JobSheet.Ref
	|FROM
	|	Document.JobSheet AS JobSheet
	|WHERE
	|	JobSheet.PerformerPosition = &EmptyPosition
	|
	|UNION ALL
	|
	|SELECT
	|	JobSheet.Ref
	|FROM
	|	Document.JobSheet AS JobSheet
	|WHERE
	|	JobSheet.ProductionOrderPosition = &EmptyPosition";
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		DocObj = Selection.Ref.GetObject();
		DocObj.StructuralUnitPosition = Enums.AttributePositionOnForm.InHeader;
		DocObj.PerformerPosition = Enums.AttributePositionOnForm.InHeader;
		DocObj.ProductionOrderPosition = Enums.AttributePositionOnForm.InHeader;
		DocObj.Write();
		
	EndDo;
	
	Query.Text = 
	"SELECT
	|	ProductionOrder.Ref AS Ref
	|FROM
	|	Document.ProductionOrder AS ProductionOrder
	|WHERE
	|	ProductionOrder.CustomerOrderPosition = &EmptyPosition
	|
	|UNION ALL
	|
	|SELECT
	|	ProductionOrder.Ref
	|FROM
	|	Document.ProductionOrder AS ProductionOrder
	|WHERE
	|	ProductionOrder.StructuralUnitOperationPosition = &EmptyPosition
	|
	|UNION ALL
	|
	|SELECT
	|	ProductionOrder.Ref
	|FROM
	|	Document.ProductionOrder AS ProductionOrder
	|WHERE
	|	ProductionOrder.WarehousePosition = &EmptyPosition
	|
	|UNION ALL
	|
	|SELECT
	|	ProductionOrder.Ref
	|FROM
	|	Document.ProductionOrder AS ProductionOrder
	|WHERE
	|	ProductionOrder.PerformerPosition = &EmptyPosition";
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		DocObj = Selection.Ref.GetObject();
		DocObj.CustomerOrderPosition = Enums.AttributePositionOnForm.InHeader;
		DocObj.StructuralUnitOperationPosition = Enums.AttributePositionOnForm.InHeader;
		DocObj.WarehousePosition = Enums.AttributePositionOnForm.InHeader;
		DocObj.PerformerPosition = Enums.AttributePositionOnForm.InHeader;
		DocObj.Write();
		
	EndDo;
	
EndProcedure

Procedure ManualInventoryDistributionByDefault() Export 
	
	Constants.ManualInventoryDistributionByDefault.Set(Enums.YesNo.No);
	
EndProcedure

Procedure SetupFunctionalOptionAccountingByMultipleCompanies() Export
	
	ConstantValue = Constants.UseSeveralCompanies.Get();
	Constants.FunctionalOptionAccountingByMultipleCompanies.Set(ConstantValue);
	
EndProcedure

Procedure FillEnterOpeningBalanceAccountingSection() Export
	
	Selection = Documents.EnterOpeningBalance.Select();
	
	While Selection.Next() Do
		If not ValueIsFilled(Selection.AccountingSection) Then
			DocObject = Selection.GetObject();
			DocObject.AccountingSection = Enums.AccountingSections[StrReplace(Selection.DeleteAccountingSection, " ", "")];
			DocObject.Write();
		EndIf;
	EndDo;
	
EndProcedure

#Region Update_1_1_0_7

Procedure UpdateHardwareDriversInPeripherialsCatalog() Export
	
	SetPrivilegedMode(True);
	
	Try
		
		EquipmentManagerServerCallOverridable.RefreshSuppliedDrivers();
		EquipmentManagerServerCallOverridable.RefreshDriversConnectedEquipmentHandbook();
		
	Except
		
		WriteLogEvent("Update", EventLogLevel.Error, , , ErrorDescription());
		
	EndTry;
	
	SetPrivilegedMode(False);
	
EndProcedure 

#EndRegion   

#Region Update_1_1_0_8

Procedure UpdatePredefinedAccountsSettings1_1_0_8() Export
	
	SetPrivilegedMode(True);
	
	Try
		
		AccountObject = ChartsOfAccounts.Managerial.AccountsReceivable.GetObject();
		AccountObject.Parent = ChartsOfAccounts.Managerial.AccountsReceivableAndCustomers;
		AccountObject.Description = "Thanh toán với khách hàng";
		AccountObject.Code = "1311";
		AccountObject.Order = "1311";
		AccountObject.Write();
		
		AccountObject = ChartsOfAccounts.Managerial.AccountsByAdvancesReceived.GetObject();
		AccountObject.Parent = ChartsOfAccounts.Managerial.AccountsReceivableAndCustomers;
		AccountObject.Description = "Nhận ứng trước từ khách hàng";
		AccountObject.Code = "1312";
		AccountObject.Order = "1312";
		AccountObject.Write();
		
		AccountObject = ChartsOfAccounts.Managerial.AdvanceHolderPayments.GetObject();
		AccountObject.Parent = ChartsOfAccounts.Managerial.SettlementsWithAdvanceHolders;
		AccountObject.Description = "Tạm ứng";
		AccountObject.Code = "1411";
		AccountObject.Order = "1411";
		AccountObject.Write();
		
		AccountObject = ChartsOfAccounts.Managerial.OverrunOfAdvanceHolders.GetObject();
		AccountObject.Parent = ChartsOfAccounts.Managerial.SettlementsWithAdvanceHolders;
		AccountObject.Description = "Chi quá tạm ứng";
		AccountObject.Code = "1412";
		AccountObject.Order = "1412";
		AccountObject.Write();
		
		AccountObject = ChartsOfAccounts.Managerial.AccountsPayable.GetObject();
		AccountObject.Parent = ChartsOfAccounts.Managerial.AccountsPayableAndContractors;
		AccountObject.Description = "Thanh toán với người bán";
		AccountObject.Code = "3311";
		AccountObject.Order = "3311";
		AccountObject.Write();
		
		AccountObject = ChartsOfAccounts.Managerial.SettlementsByAdvancesIssued.GetObject();
		AccountObject.Parent = ChartsOfAccounts.Managerial.AccountsPayableAndContractors;
		AccountObject.Description = "Ứng trước cho người bán";
		AccountObject.Code = "3312";
		AccountObject.Order = "3312";
		AccountObject.Write();
		
	Except
		
		WriteLogEvent("Update", EventLogLevel.Error, , , ErrorDescription());
		
	EndTry;
	
	SetPrivilegedMode(False);
	
EndProcedure 

#EndRegion  

#Region Update_1_1_1_1

Procedure FillOperationQuantityInSpecifications() Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	OperationSpecification.Ref AS Ref
	|FROM
	|	Catalog.Specifications.Operations AS OperationSpecification
	|WHERE
	|	OperationSpecification.Quantity = 0
	|
	|GROUP BY
	|	OperationSpecification.Ref";
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Specification = Selection.Ref.GetObject();
		For Each TabularSectionRow In Specification.Operations Do
			TabularSectionRow.Quantity = 1;
		EndDo;
		InfobaseUpdate.WriteObject(Specification, False, False);
	EndDo; 
	
EndProcedure

Procedure UpdateAdditionalAttributesAndInformationSetOfSpecification() Export
	
	// Заполнение реквизитов предопределенных наборов
	PropertiesSetObject = Catalogs.AdditionalAttributesAndInformationSets.Catalog_Specifications.GetObject();
	PropertiesSetObject.Parent = Catalogs.AdditionalAttributesAndInformationSets.EmptyRef();
	PropertiesSetObject.Used = True;
	PropertiesSetObject.AdditionalAttributes.Clear();
	InfobaseUpdate.WriteObject(PropertiesSetObject, False, False);
	
	PropertiesSetObject = Catalogs.AdditionalAttributesAndInformationSets.Catalog_Specifications_Common.GetObject();
	PropertiesSetObject.Parent = Catalogs.AdditionalAttributesAndInformationSets.Catalog_Specifications;
	PropertiesSetObject.Used = True;
	
	// Перенос существующих реквизитов и сведений
	Query = New Query;
	Query.Text =
	"SELECT
	|	AdditionalAttributesAndInformation.Ref AS Ref
	|FROM
	|	ChartOfCharacteristicTypes.AdditionalAttributesAndInformation AS AdditionalAttributesAndInformation
	|WHERE
	|	AdditionalAttributesAndInformation.PropertySet = VALUE(Catalog.AdditionalAttributesAndInformationSets.Catalog_Specifications)";
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		AttributeObject = Selection.Ref.GetObject();
		AttributeObject.PropertySet = Catalogs.AdditionalAttributesAndInformationSets.Catalog_Specifications_Common;
		InfobaseUpdate.WriteObject(PropertiesSetObject, False, False);
		If PropertiesSetObject.AdditionalAttributes.Find(Selection.Ref, "Property")=Undefined Then
			NewRow = PropertiesSetObject.AdditionalAttributes.Add();
			NewRow.Property = Selection.Ref;
		EndIf; 
	EndDo; 
	InfobaseUpdate.WriteObject(PropertiesSetObject, False, False);
	
	// Создание наборов дополнительных реквизитов и сведений спецификаций по категориям номенклатуры
	Query = New Query;
	Query.Text =
	"SELECT
	|	ProductsAndServicesCategories.Ref AS Ref,
	|	ProductsAndServicesCategories.DeletionMark AS DeletionMark,
	|	ProductsAndServicesCategories.Description AS Description
	|FROM
	|	Catalog.ProductsAndServicesCategories AS ProductsAndServicesCategories
	|WHERE
	|	ProductsAndServicesCategories.SpecificationAttributesArray = VALUE(Catalog.AdditionalAttributesAndInformationSets.EmptyRef)";
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		PropertiesSetObject = Catalogs.AdditionalAttributesAndInformationSets.CreateItem();
		PropertiesSetObject.Used = True;
		PropertiesSetObject.Description = Selection.Description;
		PropertiesSetObject.DeletionMark = Selection.DeletionMark;
		PropertiesSetObject.Parent = Catalogs.AdditionalAttributesAndInformationSets.Catalog_Specifications;
		InfobaseUpdate.WriteObject(PropertiesSetObject, False, False);
		CategoryObject = Selection.Ref.GetObject();
		CategoryObject.SpecificationAttributesArray = PropertiesSetObject.Ref;
		InfobaseUpdate.WriteObject(CategoryObject, False, False);
	EndDo; 
	
EndProcedure

#EndRegion 

#Region Update_1_1_2_3

Procedure FillPredefinedTaxTypes() Export

	// 1. TaxOnImport_EnvironmentalFee.
	TaxKind = Catalogs.TaxTypes.TaxOnImport_EnvironmentalFee.GetObject();
	TaxKind.Description = "Thuế BVMT";
	TaxKind.GLAccount = ChartsOfAccounts.Managerial.FindByCode("3338");
	TaxKind.GLAccountForReimbursement = ChartsOfAccounts.Managerial.FindByCode("3338");
	TaxKind.Write();

	// 2. TaxOnImport_Fee.
	TaxKind = Catalogs.TaxTypes.TaxOnImport_Fee.GetObject();
	TaxKind.Description = "Thuế nhập khẩu";
	TaxKind.GLAccount = ChartsOfAccounts.Managerial.FindByCode("3333");
	TaxKind.GLAccountForReimbursement = ChartsOfAccounts.Managerial.FindByCode("3333");
	TaxKind.Write();

	// 3. TaxOnImport_Excise.
	TaxKind = Catalogs.TaxTypes.TaxOnImport_Excise.GetObject();
	TaxKind.Description = "Thuế TTĐB";
	TaxKind.GLAccount = ChartsOfAccounts.Managerial.FindByCode("3332");
	TaxKind.GLAccountForReimbursement = ChartsOfAccounts.Managerial.FindByCode("3332");
	TaxKind.Write();

EndProcedure // FillPredefinedTaxTypes()

#EndRegion 

