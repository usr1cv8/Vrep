////////////////////////////////////////////////////////////////////////////////
// Subsystem "Report variants" (server, overridable).
// 
// It is executed on the server, is
// changed for the applied configuration specific but is intended to use only this subsystem.
////////////////////////////////////////////////////////////////////////////////

#Region ProgramInterface

////////////////////////////////////////////////////////////////////////////////
// PROGRAMMING INTERFACE

// Identifies the sections in which reports panel is available.
//
// Parameters:
//   Sections - ValueList - Sections containing reports panel open commands.
//       * Value - MetadataObject: Subsystem - Subsystem metadata.
//       * Presentation - String - Title of the reports panel of this section.
//
// Definition:
//   It is necessary to add to the Sections
//   the metadata of those first-level subsystems that contain the reports panels call commands.
//
// ForExample:
// Sections.Add(Metadata.Subsystems.SubsystemName);
//
Procedure DetermineSectionsWithReportVariants(Sections) Export
	
	Sections.Add(Metadata.Subsystems.CRM, NStr("en='CRM';ru='CRM';vi='CRM'"));
	Sections.Add(Metadata.Subsystems.MarketingAndSales, NStr("en='Marketing and sales';ru='Маркетинг и продажи';vi='Marketing và bán hàng'"));
	Sections.Add(Metadata.Subsystems.InventoryAndPurchasing, NStr("en='Inventory and purchases';ru='Запасы и закупки';vi='Báo cáo mua hàng và kho bãi'"));
	Sections.Add(Metadata.Subsystems.Services, NStr("en='Service';ru='Работы';vi='Công việc'"));
	Sections.Add(Metadata.Subsystems.KittingAndProduction, NStr("en='Production';ru='Производство';vi='Sản xuất'"));
	Sections.Add(Metadata.Subsystems.Finances, NStr("en='Funds';ru='Деньги';vi='Vốn bằng tiền'"));
	Sections.Add(Metadata.Subsystems.PayrollAndHumanResources, NStr("en='Payroll and HR';ru='Зарплата и персонал';vi='Tiền lương và nhân sự'"));
	Sections.Add(Metadata.Subsystems.Enterprise, NStr("en='Company';ru='Предприятие';vi='Doanh nghiệp'"));
	Sections.Add(Metadata.Subsystems.Analysis, NStr("en='Analysis';ru='Анализ';vi='Phân tích'"));
	
EndProcedure // DetermineSectionsWithReportVariants

Procedure MakeMain(Settings,ReportName, OptionsAsString)

	OptionsArray = StringFunctionsClientServer.DecomposeStringIntoSubstringsArray(OptionsAsString);
	
	For Each VariantName IN OptionsArray Do
	
		Try
			Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports[ReportName], VariantName);
		Except
			Continue;
		EndTry;
		
		For Each PlacementInSubsystem IN Variant.Placement Do
		
			Variant.Placement.Insert(PlacementInSubsystem.Key,"Important");
		
		EndDo; 
	
	EndDo;

EndProcedure // MakeSecondary()

// Moves the specified variants of specified report into SeeAlso
//
// Parameters
//   Settings (ValueTree) Used to describe settings of reports
//   and variants see description to ReportsVariants.ReportVariantsConfigurationSettingsTree()
//
//  ReportName  - String - Report name that shall be transferred to SeeAlso
//
//  Variants  - String - Report variants, separated
//                 by comma, that shall be transferred into SeeAlso
//
Procedure MakeSecondary(Settings,ReportName, OptionsAsString)

	OptionsArray = StringFunctionsClientServer.DecomposeStringIntoSubstringsArray(OptionsAsString);
	
	For Each VariantName IN OptionsArray Do
	
		Try
			Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports[ReportName], VariantName);
		Except
			Continue;
		EndTry;
		
		For Each PlacementInSubsystem IN Variant.Placement Do
		
			Variant.Placement.Insert(PlacementInSubsystem.Key,"SeeAlso");
		
		EndDo; 
	
	EndDo;

EndProcedure // MakeSecondary()

Procedure HighlightKeyReports(Settings)

	MakeMain(Settings,"AvailabilityAnalysis","Default");
	MakeMain(Settings,"MutualSettlements","Statement in currency (briefly)");
	MakeMain(Settings,"SalesReportTORG29","Default");
	MakeMain(Settings,"CustomersOrdersConsolidatedAnalysis","Default");
	MakeMain(Settings,"PurchaseOrdersConsolidatedAnalysis","Default");
	MakeMain(Settings,"DemandAnalysis","Default");
	MakeMain(Settings,"Warehouse","Statement");
	MakeMain(Settings,"ProductRelease","Default");
	MakeMain(Settings,"CashAssets","Balance");
	MakeMain(Settings,"CashAssets","Statement");
	MakeMain(Settings,"PaymentCalendar","Default");
	MakeMain(Settings,"AccrualsAndDeductions","InCurrency");
	MakeMain(Settings,"PayrollPayments","StatementInCurrency");
	MakeMain(Settings,"Sales","GrossProfit");
	MakeMain(Settings,"Sales","SalesDynamics");
	MakeMain(Settings,"IncomeAndExpenses","Statement");
	MakeMain(Settings,"IncomeAndExpensesByCashMethod","Default");
	MakeMain(Settings,"TurnoverBalanceSheet","TBS");
	// DiscountCards
	MakeMain(Settings,"SalesByDiscountCards","SalesByDiscountCards");
	// End
	// DiscountCards AutomaticDiscounts
	MakeMain(Settings,"AutomaticDiscounts","AutomaticDiscounts");
	// End AutomaticDiscounts

EndProcedure

// Removes part of reports into "SeeAlso" section
//
// Parameters:
//   Settings (ValueTree) Used to describe settings of reports
//       and variants see description to ReportsVariants.ReportVariantsConfigurationSettingsTree()
//
Procedure HighlightSecondaryReports(Settings)

	MakeSecondary(Settings,"MutualSettlements","Statement,Balance,Statement in currency,Balance in currency");
	MakeSecondary(Settings,"AccountsReceivableAgingRegister","Default");
	MakeSecondary(Settings,"CashInCashRegisters","Statement,Balance,BalanceInCurrency");
	MakeSecondary(Settings,"RetailAmountAccounting","Statement,Balance,BalanceInCurrency");
	MakeSecondary(Settings,"SalesReportTORG29","Default");
	MakeSecondary(Settings,"Inventory","Statement,Balance");
	MakeSecondary(Settings,"OrdersPlacement","Statement");
	MakeSecondary(Settings,"CashAssets","Statement,Balance,Movements analysis");
	MakeSecondary(Settings,"CashAssetsForecast","Default,Planfact analysis");
	MakeSecondary(Settings,"AccrualsAndDeductions","Default");
	MakeSecondary(Settings,"PayrollPayments","Statement,Balance,BalanceInCurrency");
	MakeSecondary(Settings,"CashFlowStatementBudget","Planfact analysis");
	MakeSecondary(Settings,"ProfitsAndLossesBudget","Planfact analysis");
	MakeSecondary(Settings,"Cost","Full");
	MakeSecondary(Settings,"Purchases","Default");
	MakeSecondary(Settings,"Warehouse","Balance");
	MakeSecondary(Settings,"SurplusesAndShortages","Default");
	MakeSecondary(Settings,"InventoryByCCD","Statement,Balance");
	MakeSecondary(Settings,"InventoryReceived","Statement,Balance");
	MakeSecondary(Settings,"InventoryTransferred","Statement,Balance");
	MakeSecondary(Settings,"ProductionOrders","Balance");
	MakeSecondary(Settings,"AdvanceHolderPayments","Statement,Balance,BalanceInCurrency");
	MakeSecondary(Settings,"AccountsReceivable","Statement,StatementInCurrency,Balance,BalanceInCurrency");
	MakeSecondary(Settings,"MutualSettlementsBriefly","Statement in currency (briefly)");
	MakeSecondary(Settings,"CustomerOrders","Statement,Balance");
	MakeSecondary(Settings,"PurchaseOrders","Statement,Balance");
	MakeSecondary(Settings,"OrdersPlacement","Statement,Balance");
	MakeSecondary(Settings,"AccountsPayable","Statement,Balance,StatementInCurrency,BalanceInCurrency");
	MakeSecondary(Settings,"AccountsPayableAgingRegister","Default");
	MakeSecondary(Settings,"TaxesSettlements","Balance");
	MakeSecondary(Settings,"UFP","Balance");
	
EndProcedure // HighlightSecondaryReports()

// Contains the settings of reports variants placement in reports panel.
//   
// Parameters:
//   Settings - Collection - Used for the description of reports
//       settings and options, see description to ReportsVariants.ConfigurationReportVariantsSetupTree().
//   
// Definition:
//   IN this procedure it is required to specify how the
//   reports predefined variants will be registered in application and shown in the reports panel.
//   
// Auxiliary methods:
//   ReportSettings   = ReportsVariants.ReportDescription(Settings, Metadata.Reports.<ReportName>);
//   VariantSettings = ReportsVariants.VariantDesc(Settings, ReportSettings, "<VariantName>");
//   ReportsVariants.SetOutputModeInReportPanels(Settings, Metadata.Reports.<ReportName>/Metadata.Subsystems.<SubsystemName>, True/False);
//   ReportsVariants.SetReportInManagerModule(Settings, Metadata.Reports.<ReportName>);
//   
//   These functions receive respectively report settings and report variant settings of the next structure:
//       * Enabled - Boolean -
//           If False then the report variant is not registered in the subsystem.
//           Used to delete technical and contextual report variants from all interfaces.
//           These report variants can still be opened applicationmatically as report
//           using opening parameters (see help on "Managed form extension for the VariantKeys" report).
//       * VisibleByDefault - Boolean -
//           If False then the report variant is hidden by default in the reports panel.
//           User can "enable" it in the reports
//           panel setting mode or open via the "All reports" form.
//       *Description - String - Additional information on the report variant.
//           It is displayed as a tooltip in the reports panel.
//           Must decrypt for user the report
//           variant content and should not duplicate the report variant name.
//           Used for searching.
//       * Placement - Map - Settings for report variant location in sections.
//           ** Key     - MetadataObject: Subsystem - Subsystem that hosts the report or the report variant.
//           ** Value - String - Optional. Settings for location in the subsystem.
//               ""        - Output report in its group in regular font.
//               WithImportant"  - Output report in its group in bold.
//               WithSeeAlso" - Output report in the group "See also".
//       * FunctionalOptions - Array from String -
//            Names of the functional report variant options.
//       * SettingsForSearch - Structure - Additional settings for this report variant search.
//           These settings are to be set only in case DCS is not used or is not fully used.
//           For example, DCS can be used only for
//           parameterization and data receiving, and data can be output into fixed tabular document template.
//           ** FieldsDescription - String - Report variant fields names. Names separator: Chars.LF.
//           ** ParametersAndReportsDescriptions - String - Names of report variant settings. Names separator: Chars.LF.
//       * DefineFormSettings - Boolean - Report has application interface for close integration with
//           the report form. It can also predefine some form settings and subscribe to its events.
//           If True, and the report is connected to
//           common form ReportForm, then a procedure should be defined from a template in the report object module:
//               
//               // Settings of common form for subsystem report "Reports options".
//                 
//                Parameters:
//               //   Form - ManagedForm, Undefined - Report form or report settings form.
//                  //    Undefined when call is without context.
//                  VariantKey - String, Undefined - Name
//                      of the pre//defined one or unique identifier of user report variant.
//                      Undefined when call is without context.
//                  Settings - Structure - see return
//                      value Re//portsClientServer.GetReportSettingsByDefault().
//                 
//               Procedure DefineFormSettings(Form, VariantKey, Settings)
//               	 Export Procedure code.
//               EndProcedure
//               
//   
// ForExample:
//   
//  (1) Add a report variant to the subsystem.
// Variant = ReportsVariants.VariantDescription(Settings, Metadata.Reports.ReportName, "VariantName1");
// Variant.Location.Insert(Metadata.Subsystems.SectionName.Subsystems.SubsystemName);
//   
//  (2) Disable report variant.
// Variant = ReportsVariants.VariantDescription(Settings, Metadata.Reports.ReportName, "VariantName1");
// Variant.Enabled = False;
//   
//  (3) Disable all report variants except for the required one.
// Report = ReportsVariants.ReportDescription(Settings, Metadata.Reports.ReportName);
// Report.Enabled = False;
// Variant = ReportsVariants.VariantDescription (Settings, Report, "VariantName");
// Variant.Enabled = True;
//   
//  (4) Fill the names of fields parameters and filters:
// Variant = ReportsVariants.VariantDescription(Settings, Metadata.Reports.ReportNameWithoutScheme, "");
// Variant.SearchSettings.FieldNames =
// 	NStr("en = 'Counterparty
// 	|Contract
// 	|Responsible
// 	|Discount
// 	|Date'");
// Variant.SearchSettings.ParametersAndFiltersNames =
// 	NStr("en = 'Period
// 	|Responsible
// 	|Contract
// 	|Counterparty'");
//   
//  (5) Change the output mode in the reports panel:
//  (5.1) By reports:
// ReportsVariants.SetOutputModeInReportPanels(Settings, Metadata.Reports.ReportName, "ByReports");
//  (5.2) By variants:
// Report = ReportsVariants.ReportDescription(Settings, Metadata.Reports.ReportName);
// ReportsVariants.SetOutputModeInReportPanels(Settings, Report, "ByVariants");
//   
// IMPORTANT:
//   Report serves as variants container.
//     By modifying the report settings you can change the settings of all its variants at the same time.
//     However if you receive report variant settings directly, they
//     will become the self-service ones, i.e. will not inherit settings changes from the report.See example 3.
//   
//   Initial setting of reports locating by the subsystems
//     is read from metadata and it is not required to duplicate it in the code.
//   
//   Variant functional options are united with the functional options of this report according to the rules as follows:
//     (FO1_Report OR FO2_Report) AND (FO3_Variant OR FO4_Variant).
//   Reports functional options are
//     not read from the metadata, they are applied when the user uses the subsystem.
//   Through the ReportDescription you can add functional options that will be combined
//     according to the rules specified above, but you should keep in mind that these functional options will be valid for predefined report variants only.
//   For user report variants only functional report variants are valid.
//     - they are disabled only along with total report disabling.
//
Procedure ConfigureReportsVariants(Settings) Export
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.CustomerOrdersAnalysis, "Default");
	Variant.Definition = NStr("en='The report is used to analyze fulfillment of customer orders';ru='Отчет позволяет проанализировать выполнение заказов покупателей';vi='Báo cáo cho phép phân tích việc thực hiện đơn hàng của khách'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.CustomerOrderAnalysis, "Default");
	Variant.Enabled = False;
	Variant.Placement.Clear();
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.PurchaseOrderAnalysis, "Default");
	Variant.Enabled = False;
	Variant.Placement.Clear();
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.MutualSettlements, "StatementBrieflyContext");
	Variant.Enabled = False;
	Variant.Placement.Clear();
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.AvailabilityAnalysis, "AvailableBalanceContext");
	Variant.Enabled = False;
	Variant.Placement.Clear();
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.Sales, "SalesContext");
	Variant.Enabled = False;
	Variant.Placement.Clear();
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.CustomerOrdersPaymentAnalysis, "Default");
	Variant.Definition = NStr("en='The report is used to analyze payments of customer orders';ru='Отчет позволяет проанализировать оплату заказов покупателей';vi='Báo cáo cho phép phân tích việc thanh toán đơn hàng của khách'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.PurchaseOrdersPaymentAnalysis, "Default");
	Variant.Definition = NStr("en='The report is used to analyze purchase orders payments';ru='Отчет позволяет проанализировать оплату заказов поставщикам';vi='Báo cáo cho phép phân tích việc thanh toán đơn hàng đặt nhà cung cấp'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.DemandAnalysis, "Default");
	Variant.Definition = NStr("en='The report is used to analyze supplying of raw materials and materials required to perform works, provide services, and manufacture of products';ru='Отчет позволяет проанализировать обеспечение потребности в сырье и материалах, необходимых для выполнения работ, оказания услуг, производства продукции';vi='Báo cáo cho phép phân tích việc đảm bảo nguyên vật liệu cần thiết để thực hiện công việc, cung cấp dịch vụ, sản xuất thành phẩm'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.InvoiceForPaymentAnalysis, "Default");
	Variant.Definition = NStr("en='The report is used to analyze order payments by customers';ru='Отчет позволяет проанализировать оплату счетов покупателями';vi='Báo cáo cho phép phân tích việc khách hàng thanh toán các hóa đơn'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.SupplierInvoiceForPaymentAnalysis, "Default");
	Variant.Definition = NStr("en='The report is used to analyze payments of supplier invoices';ru='Отчет позволяет проанализировать оплату счетов поставщиков';vi='Báo cáo cho phép phân tích việc thanh toán các hóa đơn của nhà cung cấp'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.BalanceSheet, "Default");
	Variant.Definition = NStr("en='The report generates balance sheet statement for the specified period';ru='Отчет формирует управленческий баланс на указанный период';vi='Báo cáo lập bảng cân đối quản trị theo kỳ đã chỉ ra'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.CashFlowStatementBudget, "Default");
	Variant.Definition = NStr("en='The report generates cash flow budget by the specified scenario';ru='Отчет формирует бюджет движения денежных средств по указанному сценарию';vi='Báo cáo lập ngân sách lưu chuyển tiền tệ theo kịch bản đã chỉ ra'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.CashFlowStatementBudget, "Planfact analysis");
	Variant.Definition = NStr("en='The report generates cash flow budget by the specified scenario';ru='Отчет формирует бюджет движения денежных средств по указанному сценарию';vi='Báo cáo lập ngân sách lưu chuyển tiền tệ theo kịch bản đã chỉ ra'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.ProfitsAndLossesBudget, "Default");
	Variant.Definition = NStr("en='The report generates profit and loss budget by the specified scenario';ru='Отчет формирует бюджет прибылей и убытков по указанному сценарию';vi='Báo cáo lập ngân sách lãi và lỗ theo kịch bản đã chỉ ra '");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.ProfitsAndLossesBudget, "Planfact analysis");
	Variant.Definition = NStr("en='The report generates variance analysis of profit and loss budgets by the specified scenario';ru='Отчет формирует план-фактный анализ бюджета прибылей и убытков по указанному сценарию';vi='Báo cáo có lập phân tích theo kế hoạch-thực tế ngân sách lãi và lỗ theo kịch bản đã chỉ ra'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.SheetByGoodsOnWarehousesInProductsAndServicesPrices, "Default");
	Variant.Definition = NStr("en='The report is used to evaluate the cost of goods in stock according to the price kind specified';ru='Отчет предназначен для оценки стоимости товаров на складах указанному виду цен';vi='Báo cáo được dùng để đánh giá giá trị hàng hóa trong kho theo dạng giá đã chỉ ra'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.MutualSettlements, "Statement");
	Variant.Definition = NStr("en='The report displays dynamics of mutual settlements with customers and suppliers for the specified period';ru='Отчет отображает динамику взаиморасчетов с покупателями и поставщиками сводно за выбранный период времени';vi='Báo cáo hiển thị sự biến động công nợ với khách hàng và nhà cung cấp tổng hợp trong kỳ đã chọn'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.MutualSettlements, "Balance");
	Variant.Definition = NStr("en='The report reflects the state of mutual settlements with customers and suppliers for the specified period';ru='Отчет отображает состояние взаиморасчетов с покупателями и поставщиками сводно за выбранный период времени';vi='Báo cáo hiển thị trạng thái công nợ với khách hàng và nhà cung cấp tổng hợp trong kỳ đã chọn'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.MutualSettlements, "Statement in currency");
	Variant.Definition = NStr("en='The report displays dynamics of mutual settlements with customers and suppliers for the specified period in the currency of settlements';ru='Отчет отображает динамику взаиморасчетов с покупателями и поставщиками сводно за выбранный период времени в валюте расчетов';vi='Báo cáo hiển thị sự biến động công nợ với khách hàng và nhà cung cấp tổng hợp theo kỳ đã chọn bằng tiền tệ hạch toán'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.MutualSettlements, "Balance in currency");
	Variant.Definition = NStr("en='The report shows state of mutual settlements with customers and suppliers for the specified date in the currency of settlements';ru='Отчет отображает состояние взаиморасчетов с покупателями и поставщиками сводно на указанною дату в валюте расчетов';vi='Báo cáo hiển thị tổng hợp tình trạng hạch toán với khách hàng và nhà cung cấp của ngày đã chỉ ra dưới dạng tiền tệ hạch toán'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.MutualSettlements, "Statement in currency (briefly)");
	Variant.Definition = NStr("en='The report displays dynamics of settlements with customers and suppliers for the specified period in the currency of settlements (briefly)';ru='Отчет отображает динамику взаиморасчетов с покупателями и поставщиками сводно за выбранный период времени в валюте расчетов (кратко)';vi='Báo cáo hiển thị biến động hạch toán công nợ với khách hàng và nhà cung cấp tổng hợp trong kỳ đã chọn theo tiền tệ hạch toán (ngắn gọn)'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.MutualSettlementsBriefly, "Statement in currency (briefly)");
	Variant.Definition = NStr("en='The report shows dynamics of mutual settlements with customers and suppliers for the specified accounting period (briefly without contract details)';ru='Отчет отображает динамику взаиморасчетов с покупателями и поставщиками сводно за выбранный период времени расчетов (кратко без использования детализации по договорам)';vi='Báo cáo hiển thị biến động hạch toán công nợ với khách hàng và nhà cung cấp tổng hợp trong kỳ hạch toán đã chọn (ngắn gọn không sử dụng chi tiết hóa theo hợp đồng)'");
	Variant.Enabled = False;
	Variant.Placement.Clear();
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.FixedAssets, "Statement");
	Variant.Definition = NStr("en='The report provides common data on property depreciation';ru='В отчете отображаются сводные сведения об амортизации имущества';vi='Trong báo cáo có hiển thị thông tin tổng hợp về khấu hao tài sản cố định'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.FixedAssets, "Card");
	Variant.Definition = NStr("en='Inventory card';ru='Инвентарная карточка';vi='Thẻ kiểm kê'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.ProductRelease, "Default");
	Variant.Definition = NStr("en='The report on works performed, services rendered and products released';ru='Отчет по выполнению работ, оказанию услуг и выпуску продукции';vi='Báo cáo bàn giao công việc, cung cấp dịch vụ và xuất xưởng thành phẩm'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.FixedAssetsOutput, "Default");
	Variant.Definition = NStr("en='The report shows information on property output for the specified period of time';ru='В отчете отображаются сведения о выработке имущества за выбранный период времени';vi='Trong báo cáo có hiển thị thông tin về sản lượng tính cho tài sản cố định trong kỳ làm việc đã chọn'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.InventoryTransferSchedule, "Default");
	Variant.Definition = NStr("en='The report shows planned receipt and shipment of products and services by orders for the specified period in quantitative terms';ru='Отчет показывает плановые поступления и отгрузки номенклатуры по заказам в количественном выражении за выбранный период времени';vi='Báo cáo hiển thị dự tính nhập xuất hàng hàng theo đơn hàng theo số lượng trong kỳ đã chọn'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.AvailabilityAnalysis, "Default");
	Variant.Definition = NStr("en='The report shows unrestricted stock of goods at warehouses';ru='Отчет отображает свободный остаток товара на складах.';vi='Báo cáo hiển thị số dư tổng hợp của hàng hóa trong kho.'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.CashFlow, "Default");
	Variant.Definition = NStr("en='Cash flow statement of a company for the specified period';ru='Отчет о движении денежных средств организации за указанный период';vi='Báo cáo lưu chuyển tiền tệ của doanh nghiệp trong kỳ đã chỉ ra'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.CashAssets, "Statement");
	Variant.Definition = NStr("en='The report generates a cash flow statement drilled down by cash funds and bank accounts for the selected period';ru='Отчет формирует ведомость движения денежных средств с детализацией по кассам и банковским счетам за выбранный период времени';vi='Báo cáo lập bảng kê lưu chuyển tiền tệ có chi tiết hóa theo quỹ tiền mặt và tài khoản ngân hàng trong kỳ đã chọn'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.CashAssets, "Balance");
	Variant.Definition = NStr("en='The report shows cash balance on accounts and in cash funds for the specified date';ru='Отчет показывает остатки денежных средств на счетах и в кассах на указанную дату';vi='Báo cáo hiển thị số dư vốn bằng tiền trong các tài khoản và quỹ tiền mặt tại ngày đã chỉ ra'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.CashAssets, "Movements analysis");
	Variant.Definition = NStr("en='The report shows cash flow drilled down by items for the specified period';ru='Отчет показывает движение денежных средств с детализацией по статьям за выбранный период времени';vi='Báo cáo hiển thị lưu chuyển tiền tệ có chi tiết theo các chỉ tiêu trong kỳ đã chọn'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.CashAssets, "StatementInCurrency");
	Variant.Definition = NStr("en='The report generates a cash flow statement drilled down by cash funds and bank accounts for the selected period in cash currency';ru='Отчет формирует ведомость движения денежных средств с детализацией по кассам и банковским счетам за выбранный период времени в валюте денежных средств';vi='Báo cáo lập bảng kê lưu chuyển tiền tệ có chi tiết hóa theo quỹ tiền mặt và tài khoản ngân hàng trong kỳ đã chọn theo tiền tệ của vốn bằng tiền'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.CashAssets, "BalanceInCurrency");
	Variant.Definition = NStr("en='The report shows cash balance on accounts and in cash funds for the specified date in cash currency';ru='Отчет показывает остатки денежных средств на счетах и в кассах на указанную дату в валюте денежных средств';vi='Báo cáo hiển thị số dư vốn bằng tiền trong các tài khoản và quỹ tiền mặt tại ngày đã chỉ ra theo tiền tệ của vốn bằng tiền'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.CashAssets, "Analysis of movements in currency");
	Variant.Definition = NStr("en='The report shows cash flow drilled down by items for the specified period in cash currency';ru='Отчет показывает движение денежных средств с детализацией по статьям за выбранный период времени в валюте денежных средств';vi='Báo cáo hiển thị lưu chuyển tiền tệ có chi tiết theo các chỉ tiêu trong kỳ đã chọn bằng tiền tệ của vốn bằng tiền'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.CashAssets, "CashReceiptsDynamics");
	Variant.Definition = NStr("en='The report shows the dynamics of cash receipt drilled down by items for the specified period of time in accounting currency';ru='Отчет показывает динамику поступления денежных средств с детализацией по статьям за выбранный период времени в валюте учета';vi='Báo cáo hiển thị biến động tiếp nhận vốn bằng tiền, chi tiết đến từng dạng vốn cho kỳ đã chọn dưới dạng tiền tệ kế toán'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.CashAssets, "CashExpenseDynamics");
	Variant.Definition = NStr("en='The report shows the dynamics of cash expense drilled down by items for the specified period of time in accounting currency';ru='Отчет показывает динамику расхода денежных средств с детализацией по статьям за выбранный период времени в валюте учета';vi='Báo cáo hiển thị biến động chi phí vốn bằng tiền với chi tiết đến từng dạng chi phí cho kỳ đã chọn dưới dạng tiền tệ kế toán'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.CashInCashRegisters, "Statement");
	Variant.Definition = NStr("en='The report shows cash flow in the cash registers for the specified period';ru='Отчет отображает движения денежных средств в кассах ККМ за выбранный период времени';vi='Báo cáo hiển thị sự lưu chuyển tiền tại quầy thu ngân trong kỳ đã chọn '");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.CashInCashRegisters, "Balance");
	Variant.Definition = NStr("en='The report shows cash balance in the cash registers for the specified date';ru='Отчет выводит остатки денежных средств в кассах ККМ на указанную дату';vi='Báo cáo hiển thị số dư tiền trong quỹ tiền mặt máy tính tiền vào ngày đã chọn'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.CashInCashRegisters, "StatementInCurrency");
	Variant.Definition = NStr("en='The report shows cash flow in the cash registers for the specified period in the cash currency';ru='Отчет отображает движения денежных средств в кассах ККМ за выбранный период времени в валюте денежных средств';vi='Báo cáo hiển thị sự sự lưu chuyển tiền tại quầy thu ngân trong kỳ đã chọn bằng tiền tệ của vốn theo tiền tệ của vốn bằng tiền'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.CashInCashRegisters, "BalanceInCurrency");
	Variant.Definition = NStr("en='The report shows cash balance in the cash registers for the specified date in cash currency';ru='Отчет выводит остатки денежных средств в кассах ККМ на указанную дату в валюте денежных средств';vi='Báo cáo hiển thị số dư tiền mặt trong quỹ tiền mặt máy tính tiền vào ngày đã chọn theo tiền tệ tiền mặt'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.CashAssetsForecast, "Default");
	Variant.Definition = NStr("en='The report shows planned cash flow by the specified scenario';ru='Отчет показывает запланированные движения денежных средств по указанному сценарию';vi='Báo cáo hiển thị lưu chuyển tiền tệ dự tính theo kịch bản đã chỉ ra'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.CashAssetsForecast, "InCurrency");
	Variant.Definition = NStr("en='The report shows planned cash flow by the specified scenario in cash currency';ru='Отчет показывает запланированные движения денежных средств по указанному сценарию в валюте денежных средств';vi='Báo cáo hiển thị lưu chuyển tiền tệ dự tính theo kịch bản đã chỉ ra theo tiền tệ của vốn bằng tiền'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.CashAssetsForecast, "Planfact analysis");
	Variant.Definition = NStr("en='The report shows cash flow variance analysis';ru='Отчет показывает план-фактный анализ движения денежных средств';vi='Báo cáo hiển thị phân tích lưu chuyển theo kế hoạch-thực tế vốn bằng tiền '");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.CashAssetsForecast, "Planfact analysis (cur.)");
	Variant.Definition = NStr("en='The report shows cash flow variance analysis in the cash currency';ru='Отчет показывает план-фактный анализ движения денежных средств в валюте денежных средств';vi='Báo cáo hiển thị phân tích lưu chuyển tiền tệ theo kế hoạch-thực tế với tiền tệ của vốn bằng tiền'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.BankCharges, "BankCharges");
	Variant.Definition = NStr("en='The report shows information on expenses for bank charges';ru='Отчет показывает информацию по расходам на банковские комиссии';vi='Báo cáo hiển thị thông tin về phí ngân hàng'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.PlannedCashBalance, "Default");
	Variant.Definition = NStr("en='The report displays information on planned cash balance in the selected currency';ru='Отчет показывает информацию о планируемых остатках денежных средств в выбранной валюте';vi='Báo cáo hiển thị thông tin về số dư vốn bằng tiền dự tính dưới dạng tiền tệ đã chọn'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.IncomeAndExpenses, "Statement");
	Variant.Definition = NStr("en='The report provides forecast data on income and expenses (by shipment)';ru='Отчет содержит прогнозные данные о доходах и расходах (по отгрузке)';vi='Báo cáo có dữ liệu dự tính về thu nhập và chi phí (phương pháp dồn tích)'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.IncomeAndExpenses, "IncomeAndExpensesByOrders");
	Variant.Definition = NStr("en='The report contains data on income and expenses by customer orders (shipment)';ru='Отчет содержит данные о доходах и расходах по заказам покупателей(по отгрузке)';vi='Báo cáo có chứa dữ liệu về thu nhập, chi phí theo đơn hàng của khách (theo xuất hàng)'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.IncomeAndExpenses, "IncomeAndExpensesDynamics");
	Variant.Definition = NStr("en='The report shows the dynamics changes of income, expenses and profit (by shipment) for the specified period of time';ru='Отчет показывает динамику изменения доходов, расходов и прибыли (по отгрузке) за выбранный период времени';vi='Báo cáo hiển thị biến độn thay đổi thu nhập, chi phí và doanh thu (theo xuất hàng) cho kỳ đã chọn'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.IncomeAndExpensesByCashMethod, "Default");
	Variant.Definition = NStr("en='The report shows data on income and expenses (payroll)';ru='Отчет содержит данные о доходах и расходах (по оплате)';vi='Báo cáo có dữ liệu về thu nhập và chi phí (khi thanh toán)'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.IncomeAndExpensesByCashMethod, "IncomeAndExpensesDynamics");
	Variant.Definition = NStr("en='The report shows the dynamics changes of income, expenses and profit (by payment) for the specified period of time';ru='Отчет показывает динамику изменения доходов, расходов и прибыли (по оплате) за выбранный период времени';vi='Báo cáo hiển thị biến động thay đổi thu nhập, chi phí và doanh thu (theo thanh toán) cho kỳ đã chọn'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.IncomeAndExpensesForecast, "Statement");
	Variant.Definition = NStr("en='The report provides forecast data on income and expenses (by shipment)';ru='Отчет содержит прогнозные данные о доходах и расходах (по отгрузке)';vi='Báo cáo có dữ liệu dự tính về thu nhập và chi phí (phương pháp dồn tích)'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.IncomeAndExpensesForecast, "Planfact analysis");
	Variant.Definition = NStr("en='The report provides variance analysis of income and expenses (by shipment)';ru='Отчет содержит план-фактный анализ доходов и расходов (по отгрузке)';vi='Báo cáo gồm có phân tích thu nhập và chi phí (phương pháp dồn tích) theo kế hoạch và thực tế'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.WorkOrders, "Default");
	Variant.Definition = NStr("en='The report shows scheduled and completed work orders.';ru='Отчет показывает запланированные и выполненные задания на работу';vi='Báo cáo hiển thị nhiệm vụ dự tính và đã thực hiện cho công việc'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.WorkOrders, "ReportToCustomer");
	Variant.Definition = NStr("en='The report provides information about performed work orders to the customer';ru='Отчет предназначен для предоставления сведений заказчику о выполненных заданиях на работу';vi='Báo cáo được dùng để cung cấp thông tin cho người đặt hàng về nhiệm vụ công việc đã thực hiện'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.ProductionOrders, "Statement");
	Variant.Definition = NStr("en='The report shows order processing dynamics for the specified period';ru='Отчет отображает динамику работы с заказами за выбранный период';vi='Báo cáo hiển thị sự biến động khi làm việc với các đơn hàng trong kỳ đã chọn'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.ProductionOrders, "Balance");
	Variant.Definition = NStr("en='The report is used to analyze the state of orders for the specified date.';ru='Отчет предназначен для анализа состояния заказов на указанную дату.';vi='Báo cáo được dùng để phân tích trạng thái đơn hàng tại ngày đã chỉ ra.'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.CustomerOrders, "Statement");
	Variant.Definition = NStr("en='The report shows order processing dynamics for the specified period';ru='Отчет отображает динамику работы с заказами за выбранный период';vi='Báo cáo hiển thị sự biến động khi làm việc với các đơn hàng trong kỳ đã chọn'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.CustomerOrders, "Balance");
	Variant.Definition = NStr("en='The report shows state of orders for the specified date';ru='Отчет отображает состояние заказов на указанную дату';vi='Báo cáo hiển thị trạng thái đơn hàng tại ngày đã chỉ ra'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.PurchaseOrders, "Statement");
	Variant.Definition = NStr("en='The report shows order processing dynamics for the specified period';ru='Отчет отображает динамику работы с заказами за выбранный период';vi='Báo cáo hiển thị sự biến động khi làm việc với các đơn hàng trong kỳ đã chọn'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.PurchaseOrders, "Balance");
	Variant.Definition = NStr("en='The report shows state of orders for the specified date';ru='Отчет отображает состояние заказов на указанную дату';vi='Báo cáo hiển thị trạng thái đơn hàng tại ngày đã chỉ ra'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.Purchases, "Default");
	Variant.Definition = NStr("en='The report is used to analyze products and services purchased by the company within the specified period of time';ru='Отчет предназначен для анализа закупок номенклатуры, совершенных предприятием в течение заданного периода времени';vi='Báo cáo được dùng để phân tích việc bán hàng hóa do doanh nghiệp thực hiện trong kỳ đã đặt'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.Inventory, "Statement");
	Variant.Definition = NStr("en='The report provides information on receipt, shipment and quantity of inventory in unrestricted stock and reserve under customer orders';ru='Отчет позволяет получить информацию о поступлении, отгрузке и текущем количестве запасов в свободном остатке и в резерве по заказам покупателей';vi='Báo cáo cho phép nhận thông tin về việc nhập xuất và số lượng vật tư hiện tại có số dư tự do và được dự phòng theo đơn hàng của khách'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.Inventory, "Balance");
	Variant.Definition = NStr("en='The report reflects inventory state for the specified date.';ru='Отчет отображает состояние запасов на указанную дату';vi='Báo cáo hiển thị trạng thái vật tư tại ngày đã chỉ ra'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.SurplusesAndShortages, "Default");
	Variant.Definition = NStr("en='The report provides information on surpluses and shortages according to the physical inventory results';ru='Отчет позволяет получить информацию об излишках и недостачах по итогам инвентаризации';vi='Báo cáo cho phép nhận thông tin về hàng thừa, hàng thiếu theo tổng kết kiểm kê'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.InventoryByCCD, "Statement");
	Variant.Definition = NStr("en='The report provides information on receipt, shipment, and quantity of any imported product available that has a CCD number assigned';ru='Отчет позволяет получить информацию о поступлении, отгрузке и текущем количестве любого импортного товара, которому присвоен номер ГТД';vi='Báo cáo cho phép nhận thông tin về việc nhập xuất và số lượng hiện tại của các hàng hóa nhập khẩu có kèm số tờ khai hải quan'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.InventoryByCCD, "Balance");
	Variant.Definition = NStr("en='The report provides information on the quantity of any imported product available that has a CCD number assigned';ru='Отчет позволяет получить информацию о текущем количестве любого импортного товара, которому присвоен номер ГТД';vi='Báo cáo cho phép nhận thông tin về số lượng hiện tại của bất kỳ hàng hóa nhập khẩu có kèm số tờ khai hải quan'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.InventoryTransferred, "Statement");
	Variant.Definition = NStr("en='The report provides information about changes of inventory balance received for commission, processing, and safe custody for the specified period';ru='Отчет позволяет получить информацию об изменении запасов, принятых на комиссию, в переработку и на ответственное хранение за указанный период времени';vi='Báo cáo cho phép nhận thông tin về sự thay đổi vật tư đã tiếp nhận vào ký gửi, gia công và kho thuê ngoài trong kỳ đã chỉ ra'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.InventoryTransferred, "Balance");
	Variant.Definition = NStr("en='The report provides information about inventory balance received for commission, processing, and safe custody.';ru='Отчет позволяет получить информацию об остатках запасов, принятых на комиссию, в переработку и на ответственное хранение.';vi='Báo cáo cho phép nhận thông tin về số dư vật tư đã tiếp nhận vào ký gửi, gia công và kho thuê ngoài'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.InventoryReceived, "Statement");
	Variant.Definition = NStr("en='The report provides information about changes of inventory balance received for commission, processing, and safe custody for the specified period';ru='Отчет позволяет получить информацию об изменении запасов, принятых на комиссию, в переработку и на ответственное хранение за указанный период времени';vi='Báo cáo cho phép nhận thông tin về sự thay đổi vật tư đã tiếp nhận vào ký gửi, gia công và kho thuê ngoài trong kỳ đã chỉ ra'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.InventoryReceived, "Balance");
	Variant.Definition = NStr("en='The report provides information about inventory balance received for commission, processing, and safe custody.';ru='Отчет позволяет получить информацию об остатках запасов, принятых на комиссию, в переработку и на ответственное хранение.';vi='Báo cáo cho phép nhận thông tin về số dư vật tư đã tiếp nhận vào ký gửi, gia công và kho thuê ngoài'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.EventCalendar, "Default");
	Variant.Definition = NStr("en='The report provides information on events grouped by their statuses (overdue, for today, scheduled)';ru='Отчет позволяет получить информацию по событиям, сгруппированным по статусам (просроченные, на сегодня, запланированные).';vi='Báo cáo cho phép nhận thông tin về sự kiện, gom nhóm theo trạng thái (quá hạn, hôm nay, dự tính).'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.CounterpartyContactInformation, "Counterparty contact information");
	Variant.Enabled = False;
	Variant.Placement.Clear();
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.AccrualsAndDeductions, "Default");
	Variant.Definition = NStr("en='The report shows data on employee accruals and deductions drilled down to the accrual/deduction kind';ru='В отчете отражаются данные по начислениям и удержаниям сотрудников с детализацией до вида начисления/удержания';vi='Trong báo cáo có hiển thị dữ liệu về tính lương và giữ lại của người lao động có độ chi tiết hóa đến dạng tính lương/giữ lại'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.AccrualsAndDeductions, "InCurrency");
	Variant.Definition = NStr("en='The report displays data on employee accruals and deductions drilled down to the accrual/deduction kind';ru='В отчете отражаются данные по начислениям и удержаниям сотрудников в валюте с детализацией до вида начисления/удержания';vi='Trong báo cáo có hiển thị dữ liệu về tính lương và giữ lại của người lao động theo tiền tệ có độ chi tiết hóa đến dạng tính lượng/giữ lại'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.UFP, "Statement");
	Variant.Definition = NStr("en='The report displays data on changes of direct and indirect costs of the company. The data is shown by departments drilled down by customer orders';ru='Отчет предоставляет информацию об изменениях прямых и косвенных затрат предприятия. Данные представлены в разрезе подразделений с детализацией по заказам покупателей';vi='Báo cáo cung cấp thông tin về sự thay đổi chi phí trực tiếp và chi phí gián tiếp của doanh nghiệp. Dữ liệu được trình bày theo từng bộ phận có chi tiết hóa theo đơn hàng của khách '");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.UFP, "Balance");
	Variant.Definition = NStr("en='The report displays data on the state of direct and indirect costs of the company. The data is shown by departments drilled down by customer orders';ru='Отчет предоставляет информацию о состоянии прямых и косвенных затрат предприятия. Данные представлены в разрезе подразделений с детализацией по заказам покупателей';vi='Báo cáo cung cấp thông tin về trạng thái chi phí trực tiếp và chi phí gián tiếp của doanh nghiệp. Dữ liệu được trình bày theo từng bộ phận có chi tiết theo đơn hàng của khách'");
	Variant.VisibleByDefault = False;
	
	Report = ReportsVariants.ReportDescription(Settings, Metadata.Reports.StandardBOM); //Variant does not exist, the description shall be set for report.
	ReportsVariants.SetOutputModeInReportPanels(Settings, Report, True);	
	Report.Definition = NStr("en='The report provides information on standards and technologies of works and products';ru='Отчет предоставляет информацию о нормативном составе и технологии работ, продукции';vi='Báo cáo cung cấp thông tin về thành phần định mức và kỹ thuật thực hiện công việc, sản phẩm'");
	Report.SearchSettings.FieldNames =
		NStr("en='Products"
"and services"
"Technological operation Accounting price';ru='Номенклатура"
"Технологическая"
"операция Учетная цена';vi='Mặt hàng"
"Dịch vụ công nghệ"
"Đơn giá kế toán'");
	Report.SearchSettings.ParametersAndFiltersNames =
		NStr("en='Date"
"of calculation"
"Prices"
"kind"
"Products and services Characteristic Specification';ru='Дата"
"расчета"
"Вид"
"цен"
"Номенклатура Характеристика Спецификация';vi='Ngày"
"hạch toán"
"Dạng"
"đơn giá"
"Mặt hàng Đặc tính Bảng kê chi tiết'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.InventoryTurnover, "Default");
	Variant.Definition = NStr("en='The report shows daily work time expenditures by days for the specified period';ru='В отчете отображаются сведения о ежедневных затратах рабочего времени по дням за указанный период';vi='Trong báo cáo có hiển thị thông tin về chi phí thời gian làm việc hàng ngày theo ngày trong kỳ đã chọn'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.TurnoverBalanceSheet, "TBS");
	Variant.Definition = NStr("en='The report displays data on total work time expenditures drilled down to the work time kind for the specified period';ru='В отчет выводятся данные о суммарных затратах рабочего времени с детализацией до вида рабочего времени за указанный период';vi='Trong báo cáo hiển thị dữ liệu và tổng chi phí thời gian làm việc có chi tiết hóa đến dạng thời gian làm việc trong kỳ đã chọn'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.WorkedTime, "ByDays");
	Variant.Definition = NStr("en='The report is used to analyze correlation of planned and actual sales';ru='С помощью отчета можно проанализировать соотношение запланированных и фактических продаж';vi='Nhờ báo cáo, có thể phân tích mối tương quan giữa bán hàng dự tính và bán hàng thực tế'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.WorkedTime, "TotalForPeriod");
	Variant.Definition = NStr("en='The report is designed to perform variance analysis of performed works, services rendered, manufacture of products';ru='Отчет предназначен для план-фактного анализа выполнения работ, оказания услуг, производства продукции';vi='Báo cáo được dùng để phân tích theo kế hoạch-thực tế thực hiện công việc, cung cấp dịch vụ, sản xuất thành phẩm'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.SalesPlanActualAnalysis, "Default");
	Variant.Definition = NStr("en='The report shows information about planned sales of products and services grouped by departments';ru='В отчете отображаются данные о планируемых продажах номенклатуры, сгруппированные по подразделениям';vi='Trong báo cáo hiển thị dữ liệu về bán hàng dự tính của mặt hàng được gom nhóm theo bộ phận'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.ProductionPlanActualAnalysis, "Default");
	Variant.Definition = NStr("en='Payment calendar';ru='Платежный календарь';vi='Lịch thanh toán'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.SalesTargets, "Default");
	Variant.Definition = NStr("en='The report provides information about profits and losses for the specified period';ru='В отчет выводится информация о прибылях и убытках за указанный период';vi='Trong báo cáo hiển thị thông tin về lợi nhuận và thu lỗ trong kỳ đã chọn'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.PaymentCalendar, "Default");
	Variant.Definition = NStr("en='The report generates budget by balance sheet using the specified scenario';ru='Отчет формирует бюджет по балансовому листу по указанному сценарию';vi='Báo cáo lập ngân sách theo bảng cân đối với kịch bản đã chỉ ra'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.ProfitsAndLosses, "Default");
	Variant.Definition = NStr("en='The report shows variance analysis of budget implementation by balance sheet';ru='Отчет показывает план-фактный анализ исполнения бюджета по балансовому листу';vi='Báo cáo hiển thị phân tích theo kế hoạch-thực tế về các khoản phải nộp ngân sách theo bảng cân đối'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.BalanceEstimation, "Default");
	Variant.Definition = NStr("en='The report displays information on products and services items sold for the specified period in quantitative and monetary terms';ru='Отчет отображает сведения о проданных позициях номенклатуры в количественном и суммовом выражении за определенный период времени';vi='Báo cáo hiển thị thông tin về hàng bán dưới dạng số lượng và giá trị trong kỳ nhất định'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.BalanceEstimation, "Planfact analysis");
	Variant.Definition = NStr("en='The report shows variance analysis of budget implementation by balance sheet';ru='Отчет показывает план-фактный анализ исполнения бюджета по балансовому листу';vi='Báo cáo hiển thị phân tích theo kế hoạch-thực tế về các khoản phải nộp ngân sách theo bảng cân đối'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.Sales, "Default");
	Variant.Definition = NStr("en='The report displays information on products and services items sold for the specified period in quantitative and monetary terms';ru='Отчет отображает сведения о проданных позициях номенклатуры в количественном и суммовом выражении за определенный период времени';vi='Báo cáo hiển thị thông tin về hàng bán dưới dạng số lượng và giá trị trong kỳ nhất định'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.Sales, "GrossProfit");
	Variant.Definition = NStr("en='The report displays gross profit for the specified period';ru='Отчет отображает валовую прибыль за определенный период времени';vi='Báo cáo hiển thị doanh thu thuần trong kỳ nhất định'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.Sales, "GrossProfitByProductsAndServicesCategories");
	Variant.Definition = NStr("en='The report displays gross profit by products and services groups for a certain period of time';ru='Отчет отображает валовую прибыль по номенклатурным группам за определенный период времени';vi='Báo cáo hiển thị lãi gộp theo nhóm mặt hàng trong kỳ nhất định'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.Sales, "GrossProfitByCustomers");
	Variant.Definition = NStr("en='The report displays gross profit by customers for a certain period of time';ru='Отчет отображает валовую прибыль по покупателям за определенный период времени';vi='Báo cáo hiển thị lãi gộp theo khách hàng trong kỳ nhất định'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.Sales, "GrossProfitByManagers");
	Variant.Definition = NStr("en='The report displays gross profit by managers for a certain period of time';ru='Отчет отображает валовую прибыль по менеджерам за определенный период времени';vi='Báo cáo hiển thị lãi gộp theo người quản lý trong kỳ nhất định'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.Sales, "SalesDynamics");
	Variant.Definition = NStr("en='The report shows sales dynamics by periods for a certain period of time';ru='Отчет отображает динамику продаж по периодам за определенный период времени';vi='Báo cáo hiển thị biến động bán hàng theo kỳ trong kỳ nhất định'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.Sales, "SalesDynamicsByProductsAndServices");
	Variant.Definition = NStr("en='The report shows sales dynamics by products and services for a certain period of time';ru='Отчет отображает динамику продаж по номенклатуре за определенный период времени';vi='Báo cáo hiển thị biến động bán hàng theo mặt hàng trong kỳ nhất định'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.Sales, "SalesDynamicsByProductsAndServicesCategories");
	Variant.Definition = NStr("en='The report shows sales dynamics by products and services groups for a certain period of time';ru='Отчет отображает динамику продаж по номенклатурным группам за определенный период времени';vi='Báo cáo hiển thị biến động bán hàng theo nhóm mặt hàng trong kỳ nhất định'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.Sales, "SalesDynamicsByCustomers");
	Variant.Definition = NStr("en='The report shows sales dynamics by customers for a certain period of time';ru='Отчет отображает динамику продаж по покупателям за определенный период времени';vi='Báo cáo hiển thị biến động bán hàng theo khách hàng trong kỳ nhất định'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.Sales, "SalesDynamicsByManagers");
	Variant.Definition = NStr("en='The report shows sales dynamics by managers for a certain period of time';ru='Отчет отображает динамику продаж по менеджерам за определенный период времени';vi='Báo cáo hiển thị biến động bán hàng theo người quản lý trong kỳ nhất định'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.OrdersPlacement, "Statement");
	Variant.Definition = NStr("en='The report shows changes of data on customer orders that are fulfilled due to receipts under other orders: purchase orders, picking, production';ru='В отчете отражаются изменение данных о заказах покупателей, выполнение которых обеспечивается за счет поступлений по другим заказам - поставщикам и на комплектацию, производство';vi='Trong báo cáo có hiển thị thay đổi dữ liệu về đơn hàng của khách, thực hiện đơn hàng được đảm bảo do tiếp nhận theo đơn hàng khác - nhà cung cấp và để đóng bộ sản phẩm, sản xuất'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.OrdersPlacement, "Balance");
	Variant.Definition = NStr("en='The report shows data on customer orders that are fulfilled due to receipts under other orders: purchase orders, picking, production';ru='В отчете отражаются данные о заказах покупателей, выполнение которых обеспечивается за счет поступлений по другим заказам - поставщикам и на комплектацию, производство';vi='Trong báo cáo có hiển thị dữ liệu về đơn hàng của khách, thực hiện đơn hàng được đảm bảo nhờ tiếp nhận theo đơn hàng khác - nhà cung cấp và để đóng bộ sản phẩm, sản xuất'");
	Variant.VisibleByDefault = False;
	
	Report = ReportsVariants.ReportDescription(Settings, Metadata.Reports.PaySheet);
	ReportsVariants.SetOutputModeInReportPanels(Settings, Report, True);	
	Report.Definition = NStr("en='Payroll of an arbitrary form. Intended for internal reporting of the company';ru='Расчетная ведомость произвольной формы. Предназначена для внутренней отчетности предприятия';vi='Bảng kê thanh toán của biểu mẫu tùy ý. Được dùng để báo cáo nội bộ trong doanh nghiệp'");
	Report.SearchSettings.FieldNames =
		NStr("en='Registration"
"period"
"Department"
"Currency Company';ru='Период"
"регистрации"
"Подразделение"
"Валюта Организация';vi='Kỳ"
"ghi nhận"
"Bộ phận"
"Tiền tệ Doanh nghiệp'");
	Report.SearchSettings.ParametersAndFiltersNames =
		NStr("en='Registration"
"period"
"Department"
"Currency Company';ru='Период"
"регистрации"
"Подразделение"
"Валюта Организация';vi='Kỳ"
"ghi nhận"
"Bộ phận"
"Tiền tệ Doanh nghiệp'");
	
	Report = ReportsVariants.ReportDescription(Settings, Metadata.Reports.PayrollSheets);
	ReportsVariants.SetOutputModeInReportPanels(Settings, Report, True);	
	Report.Definition = NStr("en='The report is used to generate payslips selected and grouped by companies and departments';ru='Отчет предоставляет возможность сформировать расчетные листки, отобранные и сгруппированные по организациям и подразделениям';vi='Báo cáo cung cấp tính năng lập các tờ thanh toán được lấy ra và gom nhóm theo doanh nghiệp và bộ phận'");
	Report.SearchSettings.FieldNames =
		NStr("en='Personnel number"
"Employee"
"Position"
"Rate"
"Department Company';ru='Табельный номер Сотрудник Должность Тарифная ставка Подразделение Организация';vi='Mã số nhân sự Nhân viên Chức vụ Mức thuế Bộ phận Doanh nghiệp'");
	Report.SearchSettings.ParametersAndFiltersNames =
		NStr("en='Registration"
"period"
"Department"
"Currency Employee';ru='Период"
"регистрации"
"Подразделение"
"Валюта Сотрудник';vi='Kỳ"
"ghi nhận"
"Bộ phận"
"Tiền tệ Người lao động'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.TaxesSettlements, "Statement");
	Variant.Definition = NStr("en='The report provides information about settlements with tax and levy department of the treasury drilled down by tax kinds';ru='Отчет позволяет получить информацию о расчетах с бюджетом по налогам и сборам, в разрезе видов налогов';vi='Báo cáo cho phép nhận thông tin về các khoản phải nộp ngân sách về thuế và lệ phí, theo từng dạng thuế'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.TaxesSettlements, "Balance");
	Variant.Definition = NStr("en='The report shows changes of salary debts to employees in the currency of settlements for the specified period';ru='Отчет отображает изменение задолженности по заработной плате сотрудникам в валюте расчетов в течение выбранного периода времени';vi='Báo cáo hiển thị sự thay đổi công nợ tiền lương phải trả cho người lao động bằng tiền tệ hạch toán trong kỳ đã chọn'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.PayrollPayments, "Statement");
	Variant.Definition = NStr("en='The report shows changes of salary debts to employees for the specified period';ru='Отчет отображает изменение задолженности по заработной плате сотрудникам в течение выбранного периода времени';vi='Báo cáo hiển thị thay đổi công nợ tiền lương phải trả người lao động trong kỳ đã chọn'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.PayrollPayments, "Balance");
	Variant.Definition = NStr("en='The report shows salary debts to employees for the specified period';ru='Отчет отображает состояние задолженности по заработной плате сотрудникам в течение выбранного периода времени';vi='Báo cáo hiển thị trạng thái công nợ về tiền lương trả cho người lao động trong kỳ đã chọn'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.PayrollPayments, "StatementInCurrency");
	Variant.Definition = NStr("en='The report shows changes of salary debts to employees in the currency of settlements for the specified period';ru='Отчет отображает изменение задолженности по заработной плате сотрудникам в валюте расчетов в течение выбранного периода времени';vi='Báo cáo hiển thị sự thay đổi công nợ tiền lương phải trả cho người lao động bằng tiền tệ hạch toán trong kỳ đã chọn'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.PayrollPayments, "BalanceInCurrency");
	Variant.Definition = NStr("en='The report shows debts changes in the currency of settlements with advance holders for the specified period';ru='Отчет отображает изменение задолженностей в валюте расчетов в течение выбранного периода времени, возникающих при расчетах с подотчетными лицами';vi='Báo cáo hiển thị sự thay đổi công nợ bằng tiền tệ hạch toán trong kỳ đã chọn, phát sinh khi hạch toán với người nhận tạm ứng'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.AdvanceHolderPayments, "Statement");
	Variant.Definition = NStr("en='The report shows debts changes in settlements with advance holders for the specified period';ru='Отчет отображает изменение задолженностей в течение выбранного периода времени, возникающих при расчетах с подотчетными лицами';vi='Báo cáo hiển thị sự thay đổi công nợ trong kỳ đã chọn, phát sinh khi hạch toán với người nhận tạm ứng'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.AdvanceHolderPayments, "Balance");
	Variant.Definition = NStr("en='The report shows state of debts in settlements with advance holders for the specified period';ru='Отчет отображает состояние задолженностей в течение выбранного периода времени, возникающих при расчетах с подотчетными лицами';vi='Báo cáo hiển thị trạng thái công nợ trong kỳ đã chọn, phát sinh khi hạch toán với người nhận tạm ứng'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.AdvanceHolderPayments, "StatementInCurrency");
	Variant.Definition = NStr("en='The report shows debts changes in the currency of settlements with advance holders for the specified period';ru='Отчет отображает изменение задолженностей в валюте расчетов в течение выбранного периода времени, возникающих при расчетах с подотчетными лицами';vi='Báo cáo hiển thị sự thay đổi công nợ bằng tiền tệ hạch toán trong kỳ đã chọn, phát sinh khi hạch toán với người nhận tạm ứng'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.AdvanceHolderPayments, "BalanceInCurrency");
	Variant.Definition = NStr("en='The report shows information on settlements with customers in the currency of settlements including orders and contracts under which there were transactions made between the company and counterparties';ru='В отчете отображаются сведения о расчетах компании с покупателями в валюте расчетов, включая заказы и договоры, в рамках которых заключались сделки между компанией и контрагентами';vi='Trong báo cáo có hiển thị thông tin về việc hạch toán của công ty với khách hàng theo tiền tệ hạch toán, bao gồm đơn hàng và hợp đồng, trong khuôn khổ hợp đồng đã ký kết giữa công ty và đối tác'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.AccountsReceivable, "Statement");
	Variant.Definition = NStr("en='The report shows information on settlements with customers including orders and contracts under which there were transactions made between the company and counterparties';ru='В отчете отображаются сведения о расчетах компании с покупателями, включая заказы и договоры, в рамках которых заключались сделки между компанией и контрагентами';vi='Trong báo cáo có hiển thị thông tin về việc hạch toán của công ty với khách hàng, bao gồm đơn hàng và hợp đồng, trong khuôn khổ hợp đồng đã ký kết giữa công ty và đối tác'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.AccountsReceivable, "Balance");
	Variant.Definition = NStr("en='The report shows information on the balance of settlements with customers including orders and contracts under which there were transactions made between the company and counterparties';ru='В отчете отображаются сведения об остатках расчетов компании с покупателями, включая заказы и договоры, в рамках которых заключались сделки между компанией и контрагентами';vi='Trong báo cáo có hiển thị thông tin về số dư hạch toán của công ty với khách hàng, bao gồm đơn hàng và hợp đồng, trong khuôn khổ hợp đồng đã ký kết giữa công ty và đối tác'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.AccountsReceivable, "StatementInCurrency");
	Variant.Definition = NStr("en='The report shows information on settlements with customers in the currency of settlements including orders and contracts under which there were transactions made between the company and counterparties';ru='В отчете отображаются сведения о расчетах компании с покупателями в валюте расчетов, включая заказы и договоры, в рамках которых заключались сделки между компанией и контрагентами';vi='Trong báo cáo có hiển thị thông tin về việc hạch toán của công ty với khách hàng theo tiền tệ hạch toán, bao gồm đơn hàng và hợp đồng, trong khuôn khổ hợp đồng đã ký kết giữa công ty và đối tác'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.AccountsReceivable, "BalanceInCurrency");
	Variant.Definition = NStr("en='The report shows information on the balance of settlements with customers in the currency of settlements including orders and contracts under which there were transactions made between the company and counterparties';ru='В отчете отображаются сведения об остатках расчетов компании с покупателями в валюте расчетов, включая заказы и договоры, в рамках которых заключались сделки между компанией и контрагентами';vi='Trong báo cáo có hiển thị thông tin về số dư hạch toán của công ty với khách hàng theo tiền tệ hạch toán, bao gồm đơn hàng và hợp đồng, trong khuôn khổ hợp đồng đã ký kết giữa công ty và đối tác'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.AccountsReceivableDynamics, "DebtDynamics");
	Variant.Definition = NStr("en='The report shows the dynamics changes of total and overdue debts of customers for the specified period of time';ru='Отчет показывает динамику изменения общей и просроченной задолженности покупателей за выбранный период времени';vi='Báo cáo hiển thị biến động thay đổi nợ chung và nợ quá hạn của khách hàng trong kỳ đã chọn'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.AccountsPayable, "Statement");
	Variant.Definition = NStr("en='The report shows information on settlements with suppliers including orders and contracts under which there were transactions made between the company and counterparties';ru='В отчете отображаются сведения о расчетах компании с поставщиками, включая заказы и договоры, в рамках которых заключались сделки между компанией и контрагентами';vi='Trong báo cáo có hiển thị thông tin về việc hạch toán của công ty với nhà cung cấp, bao gồm đơn hàng và hợp đồng, trong khuôn khổ hợp đồng đã ký kết giữa công ty và đối tác'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.AccountsPayable, "Balance");
	Variant.Definition = NStr("en='The report shows information on the balance of settlements with suppliers including orders and contracts under which there were transactions made between the company and counterparties';ru='В отчете отображаются сведения об остатках расчетов компании с поставщиками, включая заказы и договоры, в рамках которых заключались сделки между компанией и контрагентами';vi='Trong báo cáo có hiển thị thông tin về số dư hạch toán của công ty với nhà cung cấp, bao gồm đơn hàng và hợp đồng, trong khuôn khổ hợp đồng đã ký kết giữa công ty và đối tác'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.AccountsPayable, "StatementInCurrency");
	Variant.Definition = NStr("en='The report shows information on settlements with suppliers in the currency of settlements including orders and contracts under which there were transactions made between the company and counterparties';ru='В отчете отображаются сведения о расчетах компании с поставщиками в валюте расчетов, включая заказы и договоры, в рамках которых заключались сделки между компанией и контрагентами';vi='Trong báo cáo có hiển thị thông tin về việc hạch toán của công ty với nhà cung cấp theo tiền tệ hạch toán, bao gồm đơn hàng và hợp đồng, trong khuôn khổ hợp đồng đã ký kết giữa công ty và đối tác'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.AccountsPayable, "BalanceInCurrency");
	Variant.Definition = NStr("en='The report shows information on the balance of settlements with suppliers in the currency of settlements including orders and contracts under which there were transactions made between the company and counterparties';ru='В отчете отображаются сведения об остатках расчетов компании с поставщиками в валюте расчетов, включая заказы и договоры, в рамках которых заключались сделки между компанией и контрагентами';vi='Trong báo cáo có hiển thị thông tin về số dư hạch toán của công ty với nhà cung cấp theo tiền tệ hạch toán, bao gồm đơn hàng và hợp đồng, trong khuôn khổ hợp đồng đã ký kết giữa công ty và đối tác'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.DynamicsOfDebtToSuppliers, "DebtDynamics");
	Variant.Definition = NStr("en='The report shows the dynamics changes of total and overdue debts to suppliers for the specified period of time';ru='Отчет показывает динамику изменения общей и просроченной задолженности поставщикам за выбранный период времени';vi='Báo cáo hiển thị biến động thay đổi nợ chung và nợ quá hạn nhà cung cấp trong kỳ đã chọn'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.AccountsReceivableAgingRegister, "Default");
	Variant.Definition = NStr("en='The report shows amount of counterparty debts to company with period outstanding';ru='Отчет отображает суммы задолженностей контрагентов перед компанией с указанием сроков задолженности';vi='Báo cáo hiển thị số tiền nợ công ty phải thu đối tác có chỉ ra thời hạn công nợ'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.AccountsReceivableAgingRegister, "InCurrency");
	Variant.Definition = NStr("en='The report shows amount of counterparty debts to company in the currency of settlements with period outstanding';ru='Отчет отображает суммы задолженностей контрагентов перед компанией в валюте расчетов с указанием сроков задолженности';vi='Báo cáo hiển thị số tiền nợ công ty phải thu đối tác bằng tiền tệ hạch toán có chỉ ra thời hạn nợ'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.AccountsPayableAgingRegister, "Default");
	Variant.Definition = NStr("en='The report shows amount of company debts to counterparties with period outstanding';ru='Отчет отображает суммы задолженностей компании перед контрагентами с указанием сроков задолженности';vi='Báo cáo hiển thị số tiền nợ công ty phải trả đối tác có chỉ ra thời hạn công nợ'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.AccountsPayableAgingRegister, "InCurrency");
	Variant.Definition = NStr("en='The report shows data on costs of made products, works, and services with a breakdown by expenses incurred';ru='Отчет содержит данные о себестоимости выпущенной продукции, работ и услуг с расшифровкой понесенных при этом затрат';vi='Báo cáo có dữ liệu về giá thành thành phẩm xuất xưởng, công việc và dịch vụ đã cung cấp có diễn giải cho phí đã sử dụng'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.CustomersOrdersConsolidatedAnalysis, "Default");
	Variant.Definition = NStr("en='The report shows data on costs of made products, works, and services';ru='Отчет содержит данные о себестоимости выпущенной продукции, работ и услуг';vi='Báo cáo có dữ liệu về giá thành thành phẩm xuất xưởng, công việc và dịch vụ đã cung cấp'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.PurchaseOrdersConsolidatedAnalysis, "Default");
	Variant.Definition = NStr("en='The report is designed to perform variance analysis of the products release costs';ru='Отчет предназначен для проведения план-фактного анализа затрат на выпуск продукции';vi='Báo cáo được dùng để tiến hành phân tích theo kế hoạch-thực tế chi phí xuất xưởng sản phẩm'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.JobSheets, "Default");
	Variant.Definition = NStr("en='The report provides complete information on receipt, shipment and the quantity of products available at the specified storage location';ru='Отчет позволяет получить полную информацию о поступлении, отгрузке и текущем количестве товаров в выбранном месте хранения';vi='Báo cáo cho phép nhận thông tin đầy đủ về việc nhập xuất và số lượng hàng hóa hiện thời tại nơi cất giữ'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.Cost, "Full");
	Variant.Definition = NStr("en='The report shows the state of warehouse, information for storekeeper.';ru='Отчет отображает состояние склада, информацию для кладовщика';vi='Báo cáo hiển thị trạng thái kho bãi, thông tin dành cho thủ kho'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.Cost, "Default");
	Variant.Definition = NStr("en='The report shows data on costs of made products, works, and services';ru='Отчет содержит данные о себестоимости выпущенной продукции, работ и услуг';vi='Báo cáo có dữ liệu về giá thành thành phẩm xuất xưởng, công việc và dịch vụ đã cung cấp'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.OutputNetCostPlanActualAnalysis, "Default");
	Variant.Definition = NStr("en='The report is designed to perform variance analysis of the products release costs';ru='Отчет предназначен для проведения план-фактного анализа затрат на выпуск продукции';vi='Báo cáo được dùng để tiến hành phân tích theo kế hoạch-thực tế chi phí xuất xưởng sản phẩm'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.Warehouse, "Statement");
	Variant.Definition = NStr("en='The report provides complete information on receipt, shipment and the quantity of products available at the specified storage location';ru='Отчет позволяет получить полную информацию о поступлении, отгрузке и текущем количестве товаров в выбранном месте хранения';vi='Báo cáo cho phép nhận thông tin đầy đủ về việc nhập xuất và số lượng hàng hóa hiện thời tại nơi cất giữ'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.Warehouse, "Balance");
	Variant.Definition = NStr("en='The report shows the state of warehouse, information for storekeeper.';ru='Отчет отображает состояние склада, информацию для кладовщика';vi='Báo cáo hiển thị trạng thái kho bãi, thông tin dành cho thủ kho'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.EmployeesLists, "EmployeesList");
	Variant.Definition = NStr("en='The report is used to analyze sales of a retail outlet using value accounting';ru='Отчет предназначен для анализа продаж в розничной точке с суммовым учетом';vi='Báo cáo được dùng để phân tích công việc bán hàng tại điểm bán lẻ với kế toán giá trị'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.EmployeesLists, "AccrualsPlan");
	Variant.Definition = NStr("en='The report provides information on planned accruals to employees';ru='Отчет отображает информацию о плановых начислениях сотрудников';vi='Báo cáo hiển thị thông tin về mức lương dự tính của người lao động'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.EmployeesLists, "PassportData");
	Variant.Definition = NStr("en='The report shows passport data of individuals';ru='Отчет отображает паспортные данные физических лиц';vi='Báo cáo hiển thị thông tin về giấy tờ tùy thân của cá nhân'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.EmployeesLists, "ContactInformation");
	Variant.Definition = NStr("en='The report displays contact information of individuals';ru='Отчет отображает контактную информацию физических лиц';vi='Báo cáo hiển thị thông tin liên hệ của cá nhân'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.RetailAmountAccounting, "Statement");
	Variant.Definition = NStr("en='The report is used to analyze sales of a retail outlet using value accounting';ru='Отчет предназначен для анализа продаж в розничной точке с суммовым учетом';vi='Báo cáo được dùng để phân tích công việc bán hàng tại điểm bán lẻ với kế toán giá trị'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.RetailAmountAccounting, "Balance");
	Variant.Definition = NStr("en='The report is used to analyze the state of sales of a retail outlet using value accounting';ru='Отчет предназначен для анализа состояния продаж в розничной точке с суммовым учетом';vi='Báo cáo được dùng để phân tích trạng thái bán hàng tại điểm bán lẻ có kế toán giá trị'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.RetailAmountAccounting, "StatementInCurrency");
	Variant.Definition = NStr("en='The report is used to analyze the state of sales of a retail outlet using value accounting in foreign currency';ru='Отчет предназначен для анализа состояния продаж в розничной точке с суммовым учетом в валюте';vi='Báo cáo được dùng để phân tích trạng thái bán hàng tại điểm bán lẻ có kế toán giá trị theo tiền tệ'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.RetailAmountAccounting, "BalanceInCurrency");
	Variant.Definition = NStr("en='The report is used to analyze the state of retail sales debt using value accounting in foreign currency';ru='Отчет предназначен для анализа состояния задолженности розницы с суммовым учетом в валюте';vi='Báo cáo được dùng để phân tích trạng thái công nợ bán lẻ với kế toán giá trị theo tiền tệ'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.SalesReportTORG29, "Default");
	Variant.Definition = NStr("en='The report compares forecast and actual financial results';ru='В отчете сравнивается прогнозный и фактический финансовый результат';vi='Trong báo cáo có so sánh kết quả hoạt động kinh doanh dự báo và thực tế'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.AlcoholicProductsSalesBook, "Default");
	Variant.Definition = NStr("en='The report shows information on the state of the staff list of the company';ru='Отчет предназначен для предоставления информации о состоянии штатного расписания организации';vi='Báo cáo được dùng để cung cấp thông tin về trạng thái biên chế của doanh nghiệp'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.FinancialResult, "Statement");
	Variant.Definition = NStr("en='The report displays data on financial results';ru='Отчет содержит данные о финансовых результатах работы';vi='Báo cáo có dữ liệu về kết quả công việc kinh doanh'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.FinancialResultForecast, "Default");
	Variant.Definition = NStr("en='Report presents financial result forecast of the selected scenario';ru='В отчет выводятся сведения о прогнозе финансового результата по указанному сценарию';vi='Trong báo cáo hiển thị thông tin về dự báo kết quả hoạt động kinh doanh theo kịch bản đã chọn'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.FinancialResultForecast, "Planfact analysis");
	Variant.Definition = NStr("en='The report compares forecast and actual financial results';ru='В отчете сравнивается прогнозный и фактический финансовый результат';vi='Trong báo cáo có so sánh kết quả hoạt động kinh doanh dự báo và thực tế'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.StaffList, "Default");
	Variant.Definition = NStr("en='The report shows information on the state of the staff list of the company';ru='Отчет предназначен для предоставления информации о состоянии штатного расписания организации';vi='Báo cáo được dùng để cung cấp thông tin về trạng thái biên chế của doanh nghiệp'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.MaterialsDistribution, "Default");
	Variant.Placement.Clear();
	
	// DiscountCards
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.SalesByDiscountCards, "SalesByDiscountCards");
	Variant.Definition = NStr("en='The report shows information on sales by discount cards for a certain period of time in monetary terms';ru='Отчет отображает сведения о продажах по дисконтным картам в суммовом выражении за определенный период времени';vi='Báo cáo hiển thị thông tin về bán hàng theo thẻ ưu đãi dưới dạng biểu thức giá trị trong kỳ nhất định'");	
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.SalesByDiscountCards, "SalesByDiscountCard");
	Variant.Definition = NStr("en='The report is called from the ""Discount cards"" data processor and displays data on sales by discount cards for a certain period of time in monetary terms';ru='Отчет вызывается из обработки ""Дисконтные карты"" и отображает сведения о продажах по дисконтной карте в суммовом выражении за определенный период времени';vi='Báo cáo được gọi ra từ bộ xử lý ""Thẻ ưu đãi"" và hiển thị thông tin bán hàng qua thẻ ưu đãi trong biểu thức giá trị cho kỳ nhất định'");	
	Variant.Enabled = False;
	Variant.VisibleByDefault = False;
	// End DiscountCards
	
	// AutomaticDiscounts
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.AutomaticDiscounts, "AutomaticDiscounts");
	Variant.Definition = NStr("en='The report provides data on granted automatic discounts in total amounts for a certain period of time';ru='Отчет отображает сведения о предоставленных автоматических скидках в суммовом выражении за определенный период времени';vi='Báo cáo hiển thị thông tin về các chiết khấu tự động được cung cấp dưới dạng biểu thức giá trị trong kỳ xác định'");	
	// End AutomaticDiscounts
	
	// Other settlements
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.SettlementsOnOtherOperations, "Statement");
	Variant.Definition = НСтр("en='The report shows information about other settlements of the company, including orders and contracts, in which deals were made between the company and counterparties.';ru='В отчете отображаются сведения о прочих расчетах компании, включая заказы и договоры, в рамках которых заключались сделки между компанией и контрагентами.';vi='Trong báo cáo hiển thị thông tin hạch toán khác của công ty, bao gồm các đơn hàng và hợp đồng, trong đó có các vụ việc giữa công ty và đối tác.'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.SettlementsOnOtherOperations, "Balances");
	Variant.Definition = НСтр("en='The report shows information about other settlements of the company, including orders and contracts, in which deals were made between the company and counterparties.';ru='В отчете отображаются сведения о прочих расчетах компании, включая заказы и договоры, в рамках которых заключались сделки между компанией и контрагентами.';vi='Trong báo cáo hiển thị thông tin hạch toán khác của công ty, bao gồm các đơn hàng và hợp đồng, trong đó có các vụ việc giữa công ty và đối tác.'");
	Variant.VisibleByDefault = False;
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.SettlementsOnOtherOperations, "StatementInCurrency");
	Variant.Definition = НСтр("en='The report shows information about other settlements of the company in the settlement currency, including orders and contracts, in which deals were made between the company and counterparties.';ru='В отчете отображаются сведения о прочих расчетах компании в валюте расчетов, включая заказы и договоры, в рамках которых заключались сделки между компанией и контрагентами.';vi='Trong báo cáo có hiển thị thông tin hạch toán khác của công ty bằng tiền tệ hạch toán, bao gồm các đơn hàng và hợp đồng, trong đó có các vụ việc liên quan giữa công ty và đối tác.'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.SettlementsOnOtherOperations, "BalancesInCurrency");
	Variant.Definition = НСтр("en='The report shows information about other settlements of the company in the settlement currency, including orders and contracts, in which deals were made between the company and counterparties.';ru='В отчете отображаются сведения о прочих расчетах компании в валюте расчетов, включая заказы и договоры, в рамках которых заключались сделки между компанией и контрагентами.';vi='Trong báo cáo có hiển thị thông tin hạch toán khác của công ty bằng tiền tệ hạch toán, bao gồm các đơn hàng và hợp đồng, trong đó có các vụ việc liên quan giữa công ty và đối tác.'");
	Variant.VisibleByDefault = False;
	// End Other settlements
	
	// Serial numbers
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.SerialNumbersRecords, "Default");
	Variant.Definition = NStr("en='The report displays the movement of goods, taking into account the serial numbers.';ru='Отчет отображает движения товаров с учетом серийных номеров.';vi='Báo cáo hiển thị lưu chuyển hàng hóa có tính đến số sê-ri.'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.SerialNumbersWarehouse, "Balance");
	Variant.Definition = NStr("en='The report displays the rest of the goods in the warehouses with the details by serial number.';ru='Отчет отображает остаток товаров на складах с детализацией по серийным номерам.';vi='Báo cáo hiển thị số dư hàng hóa trong kho có chi tiết theo số sê-ri.'");
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.SerialNumbersWarehouse, "Statement");
	Variant.Definition = NStr("en='The report displays a list of goods movement in warehouses with detailed information on serial numbers.';ru='Отчет отображает ведомость движения товаров на складах с детализацией по серийным номерам.';vi='Báo cáo hiển thị bảng kê lưu chuyển hàng hóa trong kho có chi tiết theo số sê-ri.'");
	// End Serial numbers
	
	//Settlements on credits and loans
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.LoanSettlements, "LoansToEmployees");
	Variant.Definition = NStr("ru = 'ru = 'Отчет отображает сведения о расчетах по предоставленным займам сотрудникам.'; en = 'The report shows information about settlements of loans to employees.'");
	
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.LoanSettlements, "LoansReceived");
	Variant.Definition = NStr("en='The report shows information about settlements of received loans.';ru='Отчет отображает сведения о расчетах по полученным кредитам.';vi='Báo cáo hiển thị thông tin về hạch toán theo khoản vay đã nhận.'");
	//End Settlements on credits and loans
	
	// Universal report
	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.UniversalReport, "UniversalReport");
	Variant.Definition = NStr("en='Universal report on catalogs, documents, registers';ru='Универсальный отчет по справочками, документам, регистрам.';vi='Báo cáo chung theo danh mục, chứng từ, sổ đăng ký.'");

	Variant = ReportsVariants.VariantDesc(Settings, Metadata.Reports.SegmentComposition, "SegmentCompositionContext");
	Variant.Definition = NStr("en='The report displays the current counterparty segment.';ru='Отчет отображает текущий состав сегмента контрагентов';vi='Báo cáo hiển thị thành phần hiện tại của phân nhóm đối tác'");
	Variant.Enabled = False;
	Variant.Placement.Clear();
	
	HighlightKeyReports(Settings);
	HighlightSecondaryReports(Settings);
	
EndProcedure // ConfigureReportsVariants

// Contains the descriptions of names and report variants changes. It
//   is used when updating the infobase in order to
//   control the referential integrity and save variant settings made by the administrator.
//
// Parameters:
//   Changes - ValueTable - Variant names changes table. Columns:
//       * Report - MetadataObject - Report metadata in the schema of which variant name is changed.
//       * VariantOldName - String - Variant old name before change.
//       * VariantActualName - String - Variant current (last relevant) name.
//
// Definition:
//   Descriptions of changes of variants names
//   of the reports connected to the subsystem shall be added to Changes.
//
// ForExample:
// Change = Changes.Add();
// Change.Report = Metadata.Reports.<ReportName>;
// Update.VariantOldName = "<VariantOldName>";
// Update.VariantActualName = "<VariantActualName>";
//
// IMPORTANT:
//   Variant old name is reserved and can not be used further.
//   If several changes were made, each update shall
//   be registered specifying the report variant last (current) name in the actual variant name.
//   Since the names of the report variants are
//   not displayed in user interface it is recommended to specify them so that they won't be changed.
//
Procedure RegisterReportVariantsKeysChanges(Changes) Export
	
EndProcedure // RegisterReportVariantsKeysChanges

// Global settings applied as defaults for subsystem objects.
//
// Parameters:
//   Settings - Subsystem settings collection. Attributes:
//       * OutputReportsInsteadVariants - Boolean - Default hyperlinks output in the reports panel:
//           - True - The report variants are hidden by default while the reports are enabled and visible.
//           - False   - Value by default. The report variants are visible by default while the reports are disabled.
//       * OutputDescription - Boolean - Default descriptions output in the reports panel:
//           - True - Value by default. Show descriptions in the form of
//               inscriptions under the variants hyperlinks (descriptions reading mode).
//           - False   - Show descriptions in
//               the form of tooltips (as before).
//       * Search - Structure - Settings of reports variants search.
//           * InputHint - String - ToolTip text is displayed in the search field when search is not specified.
//               It is recommended to specify frequently used terms of applied configuration as an example.
//       * OtherReports - Structure - Form settings "Other reports":
//           * CloseAfterSelection - Boolean - Whether to close the form after selection of the report hyperlink.
//               - True - Value by default. Close "Other reports" after selection.
//               - False   - Do not close.
//           * ShowCheckBox - Boolean - Whether to show the CloseAfterSelection check box.
//               - True - Show the "Close this window after going to another report" check box.
//               - False   - Value by default. Do not show check box.
//
// ForExample:
// Settings.Search.InputHint = NStr("en='For example, cost';ru='Например, себестоимость';vi='Ví dụ, giá vốn'");
// Settings OtherReports.CloseAfterSelection = False;
// Settings.OtherReports.ShowCheckBox = True;
//
Procedure DefineGlobalSettings(Settings) Export
	
	Settings.OutputDescription = False;
	
EndProcedure

#EndRegion