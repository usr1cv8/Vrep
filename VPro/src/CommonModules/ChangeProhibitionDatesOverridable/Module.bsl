////////////////////////////////////////////////////////////////////////////////
// Subsystem "Change prohibition dates".
// 
////////////////////////////////////////////////////////////////////////////////

#Region ProgramInterface

// Allows to change the interface operation when embedding.
//
// Parameters:
//  InterfaceWorkSettings - Structure - contains property:
//   * UseExternalUsers - Boolean - (initial value
//     False) if True is set, then it will be possible to setup the date of prohibition for external users.
//
Procedure InterfaceSetting(InterfaceWorkSettings) Export
	
	InterfaceWorkSettings.UseExternalUsers = False;
	
EndProcedure

// Contains description of tables and object fields for data changing prohibition check.
//   Called from the ChangingProhibited procedure of ChangingProhibitionDates common
// module used to subscribe to  BeforeWrite object event in order to check existence of prohibitions and cancelation of prohibited object changes.
//
// Parameters:
//  DataSources - ValueTable - with columns:
//   * Table     - String - full name of the metadata object, for example "Document.SupplierInvoice".
//   * DateField    - String - name of the object attribute or tabular section, for example, "Date", "Goods.ShipmentDate".
//   * Section      - String - name of the predefined item "ChartOfCharacteristicTypesRef.ProhibitionDatesSections".
//   * ObjectField - String - name of object attribute or tabular section attribute,
//                            for example, "Organization", "Goods.Warehouse".
//
//  There is AddLine procedure in ChangeProhibitionDates common module for line adding.
//
Procedure FillDataSourcesForChangeProhibitionCheck(DataSources) Export
	
	// Data(Table, DataField, Section, ObjectField)
	
	ChangeProhibitionDates.AddLine(DataSources, "Document.ExpenseReport", 				"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.AcceptanceCertificate",			"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.FixedAssetsDepreciation", 					"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.Budget", 						"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.EnterOpeningBalance",	 		"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.Netting", 					"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.FixedAssetsOutput", 					"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.PowerOfAttorney", 					"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.AdditionalCosts", 			"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.WorkOrder", 				"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.ProductionOrder", 			"Date", "ManagementAccounting", "Company");
	// "Document.CustomerOrder" - moved into
	// a separate  "Document.PurchaseOrder" section - moved into separate section
	ChangeProhibitionDates.AddLine(DataSources, "Document.MonthEnd", 				"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.FixedAssetsModernization", 			"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.InventoryReconciliation", 			"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.EmployeeOcupationChange", 			"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.Payroll", 			"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.TaxAccrual", 				"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.Operation", 						"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.InventoryReceipt", 			"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.AgentReport", 				"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.ReportToPrincipal", 				"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.ProcessingReport", 				"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.RetailReport",		"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.SubcontractorReport", 			"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.FixedAssetsTransfer", 					"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.CashTransfer", 					"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.CashTransferPlan", 				"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.InventoryTransfer", 			"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.TransferBetweenCells", 			"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.RetailRevaluation", "Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.SalesTarget", 					"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.PayrollSheet", 			"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.PaymentOrder", 			"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.CashReceipt", 				"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.PaymentReceiptPlan", 				"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.PaymentReceipt", 				"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.EmploymentContract", 					"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.FixedAssetsEnter", 				"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.SupplierInvoice", 			"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.GoodsReceipt", 				"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.OtherExpenses", 					"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.CostAllocation", 			"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.CashOutflowPlan", 					"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.CashPayment", 					"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.CustomerInvoice", 			"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.GoodsExpense", 				"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.PaymentExpense", 					"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.InventoryReservation", 			"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.InventoryAssembly", 					"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.JobSheet", 					"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.FixedAssetsWriteOff", 					"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.InventoryWriteOff", 				"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.InvoiceForPayment", 					"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.SupplierInvoiceForPayment",			"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.Timesheet", 						"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.Dismissal", 					"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.TimeTracking", 					"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.ReceiptCR", 						"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.ReceiptCRReturn", 					"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.LoanContract", 					"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.LoanInterestCommissionAccruals", 					"Date", "ManagementAccounting", "Company");
	ChangeProhibitionDates.AddLine(DataSources, "Document.ExpensesOnImport", 					"Date", "ManagementAccounting", "Company");
	
	// Additional sections for Customer order, Purchase order documents
	ChangeProhibitionDates.AddLine(DataSources, "Document.CustomerOrder", 				"Date", "CustomerOrders", "OrderState");
	ChangeProhibitionDates.AddLine(DataSources, "Document.PurchaseOrder", 				"Date", "PurchaseOrders", "OrderState");
	
EndProcedure

// Allows to override execution of prohibitions checks by random condition.
//
// Parameters:
//  Object       - CatalogObject,
//                 DocumentObject,
//                 ChartOfCharacteristicTypesObject,
//                 ChartChartOfAccountsObject,
//                 ChartOfCalculationTypesObject,
//                 BusinessProcessObject,
//                 TaskObject,
//                 ExchangePlanObject - data object (BeforeRecording or OnReadAtServer).
//               - InformationRegisterRecordSet,
//                 AccumulationRegisterRecordSet,
//                 AccountingRegisterRecordSet,
//                 CalculationRegisterRecordSet - records set (BeforeRecording or OnReadAtServer).
//  
//  ProhibitionChangeCheck - Boolean - If install False Checking
//                             prohibition change will not be executed.
//
//  ImportingProhibitionCheckNode - Undefined, LinkExchangePlans -
//                 When Undefined, loading prohibition check is not executed.
//
//  InformAboutProhibition - Boolean - initial value is True. If False
//                 is set, then error message will not be sent to user.
//                 For example, only recording denial will be visible during the online recording.
//                 The message will be recorded into a log in any case.
//
Procedure BeforeChangeProhibitionCheck(Object,
                                         ProhibitionChangeCheck,
                                         ImportingProhibitionCheckNode,
                                         InformAboutProhibition) Export
	
	If Object.Metadata().FullName() = "Document.CustomerOrder" Then
		
		If Object.OperationKind = Enums.OperationKindsCustomerOrder.WorkOrder Then
			
			ProhibitionChangeCheck = False;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions
////////////////////////////////////////////////////////////////////////////////
// SB

// Allows to override execution of prohibitions checks by random condition.
//
Procedure CheckDateBanEditingWorkOrder(Form, CurrentObject, ImportingProhibitionCheckNode = Undefined, InformAboutProhibition = False) Export
	
	DataForChecking	= ChangeProhibitionDates.DataTemplateForChecking();
	
	NewRow			= DataForChecking.Add();
	NewRow.Date	= CurrentObject.Finish;
	NewRow.Object	= CurrentObject.Company;
	NewRow.Section	= ChartsOfCharacteristicTypes.ChangingProhibitionDatesSections.ManagementAccounting;
	
	FoundProhibitions	= Undefined;
	StandardProcessing= True;
	Form.ReadOnly= ChangeProhibitionDates.DataChangeProhibitionFound(DataForChecking, InformAboutProhibition, CurrentObject.Ref, StandardProcessing, ImportingProhibitionCheckNode, FoundProhibitions);
	
EndProcedure // CheckWorkOrder()

// Starting availability for use new sections.
//
// - CustomerOrders;
// - PurchaseOrders;
//
// Therefore the option to edit (or prohibition to edit) these documents is set separately.
//
Procedure UpdateChangesProhibitionDatesSections(DataProcessorCompleted) Export
	
	Query = New Query(
	"SELECT
	|	SectionCustomerOrders.User,
	|	TRUE AS Use
	|INTO SectionCustomerOrders
	|FROM
	|	InformationRegister.ChangeProhibitionDates AS SectionCustomerOrders
	|WHERE
	|	SectionCustomerOrders.Section = VALUE(ChartOfCharacteristicTypes.ChangingProhibitionDatesSections.CustomerOrders)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SectionPurchaseOrders.User,
	|	TRUE AS Use
	|INTO SectionPurchaseOrders
	|FROM
	|	InformationRegister.ChangeProhibitionDates AS SectionPurchaseOrders
	|WHERE
	|	SectionPurchaseOrders.Section = VALUE(ChartOfCharacteristicTypes.ChangingProhibitionDatesSections.PurchaseOrders)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SectionMain.User AS User,
	|	SectionMain.ProhibitionDateDescription AS ProhibitionDateDescription,
	|	SectionMain.ProhibitionDate AS ProhibitionDate,
	|	ISNULL(SectionCustomerOrders.Use, FALSE) AS SectionCustomerOrdersUsed,
	|	ISNULL(SectionPurchaseOrders.Use, FALSE) AS SectionPurchaseOrdersUsed
	|FROM
	|	InformationRegister.ChangeProhibitionDates AS SectionMain
	|		LEFT JOIN SectionCustomerOrders AS SectionCustomerOrders
	|		ON SectionMain.User = SectionCustomerOrders.User
	|		LEFT JOIN SectionPurchaseOrders AS SectionPurchaseOrders
	|		ON SectionMain.User = SectionPurchaseOrders.User
	|WHERE
	|	SectionMain.Section = VALUE(ChartOfCharacteristicTypes.ChangingProhibitionDatesSections.ManagementAccounting)"
	);
	
	BeginTransaction();
	Try
		
		DataProcessorCompleted = True;
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			
			If Selection.SectionCustomerOrdersUsed
				OR Selection.SectionPurchaseOrdersUsed Then
				
				Continue;
				
			EndIf;
			
			// do not need to translate!
			Comment = "Section is added automatically when the Programm was updated";
			
			ManagerRegister = InformationRegisters.ChangeProhibitionDates.CreateRecordManager();
			ManagerRegister.User = Selection.User;
			ManagerRegister.ProhibitionDate = Selection.ProhibitionDate;
			ManagerRegister.Section = ChartsOfCharacteristicTypes.ChangingProhibitionDatesSections.CustomerOrders;
			ManagerRegister.Object = ChartsOfCharacteristicTypes.ChangingProhibitionDatesSections.CustomerOrders;
			ManagerRegister.ProhibitionDateDescription = Selection.ProhibitionDateDescription;
			ManagerRegister.Comment = Comment;
			ManagerRegister.Write();
			
			ManagerRegister = InformationRegisters.ChangeProhibitionDates.CreateRecordManager();
			ManagerRegister.User = Selection.User;
			ManagerRegister.ProhibitionDate = Selection.ProhibitionDate;
			ManagerRegister.Section = ChartsOfCharacteristicTypes.ChangingProhibitionDatesSections.PurchaseOrders;
			ManagerRegister.Object = ChartsOfCharacteristicTypes.ChangingProhibitionDatesSections.PurchaseOrders;
			ManagerRegister.ProhibitionDateDescription = Selection.ProhibitionDateDescription;
			ManagerRegister.Comment = Comment;
			ManagerRegister.Write();
			
			DataProcessorCompleted = False; // Update handler is considered executed if records are not added
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		DataProcessorCompleted = False;
		WriteLogEvent("Update of changes prohibition dates sections", EventLogLevel.Error, Metadata.InformationRegisters.ChangeProhibitionDates, , ErrorDescription());
		
	EndTry;
	
EndProcedure

#EndRegion