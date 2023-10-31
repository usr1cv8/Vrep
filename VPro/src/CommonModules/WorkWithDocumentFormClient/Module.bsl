Function FormLetteringBasisDocument(Val BasisDocument, Val pViewOnly = False) Export
	
	FSComponents = New Array;
	
	BasisDocDescription = WorkWithDocumentForm.BasisDocumentDescription(BasisDocument);
	
	If BasisDocDescription = "NoObject" Then
		
		FSComponents = New Array;
		FSComponents.Add(New FormattedString(NStr("En='null';vi='không'")));
		
	ElsIf ValueIsFilled(BasisDocument) Then
				
		BasisDocumentText = BasisDocDescription;
		
		BasisDocumentText = StrReplace(BasisDocumentText, NStr("En='null';vi='không'"),"");
		BasisDocumentText = StrReplace(BasisDocumentText, NStr("En='null';vi='không'"),"");

		FSComponents = New Array;
		FSComponents.Add(New FormattedString(NStr("en='Basis';vi='Cơ sở'")));
		FSComponents.Add(New FormattedString(BasisDocumentText, , , , NStr("en='open';ru='открыть';vi='mở'")));
		If Not pViewOnly Then
			FSComponents.Add(New FormattedString(" "));
			FSComponents.Add(New FormattedString(PictureLib.FillByBasis12х12, , , , NStr("En='fill';ru='заполнить';vi='điền'")));
			FSComponents.Add(New FormattedString(" "));
			FSComponents.Add(New FormattedString(PictureLib.Clear, , , , NStr("En='delete';ru='удалить';vi='xóa'")));
		EndIf;
	Else
		FSComponents = New Array;
		FSComponents.Add(New FormattedString(NStr("En='Basis';ru='Основание';vi='Cơ sở'")));
		FSComponents.Add(New FormattedString(NStr("En='null';vi='không'"), , , , NStr("En='null';vi='không'")));
	EndIf;
	
	Return New FormattedString(FSComponents);

EndFunction

Procedure OpenDocumentFormByType(DocumentRef) Export
	
	FormNameString = DocumentNameByType(TypeOf(DocumentRef));
	OpenForm("Document."+FormNameString+".ObjectForm", New Structure("Key", DocumentRef), ThisObject);
		
EndProcedure

// Get the name of the document by type, on the client without accessing the serve
Function DocumentNameByType(DocumentType) Export
	
	TypesMap = New Map;
	
	TypesMap.Insert(Type("DocumentRef.AcceptanceCertificate"), "AcceptanceCertificate");
	TypesMap.Insert(Type("DocumentRef.AdditionalCosts"), "AdditionalCosts");
	TypesMap.Insert(Type("DocumentRef.AgentReport"), "AgentReport");
	TypesMap.Insert(Type("DocumentRef.Budget"), "Budget");
	TypesMap.Insert(Type("DocumentRef.BulkMail"), "BulkMail");
	TypesMap.Insert(Type("DocumentRef.CashOutflowPlan"), "CashOutflowPlan");
	TypesMap.Insert(Type("DocumentRef.CashPayment"), "CashPayment");
	TypesMap.Insert(Type("DocumentRef.CashReceipt"), "CashReceipt");
	TypesMap.Insert(Type("DocumentRef.CashTransfer"), "CashTransfer");
	TypesMap.Insert(Type("DocumentRef.CashTransferPlan"), "CashTransferPlan");
	TypesMap.Insert(Type("DocumentRef.CostAllocation"), "CostAllocation");
	TypesMap.Insert(Type("DocumentRef.CustomerInvoice"), "CustomerInvoice");
	TypesMap.Insert(Type("DocumentRef.CustomerOrder"), "CustomerOrder");
	TypesMap.Insert(Type("DocumentRef.Dismissal"), "Dismissal");
	TypesMap.Insert(Type("DocumentRef.EmployeeOccupationChange"), "EmployeeOccupationChange");
	TypesMap.Insert(Type("DocumentRef.EmploymentContract"), "EmploymentContract");
	TypesMap.Insert(Type("DocumentRef.EnterOpeningBalance"), "EnterOpeningBalance");
	TypesMap.Insert(Type("DocumentRef.Event"), "Event");
	TypesMap.Insert(Type("DocumentRef.ExpenseReport"), "ExpenseReport");
	TypesMap.Insert(Type("DocumentRef.FixedAssetsDepreciation"), "FixedAssetsDepreciation");
	TypesMap.Insert(Type("DocumentRef.FixedAssetsEnter"), "FixedAssetsEnter");
	TypesMap.Insert(Type("DocumentRef.FixedAssetsModernization"), "FixedAssetsModernization");
	TypesMap.Insert(Type("DocumentRef.FixedAssetsOutput"), "FixedAssetsOutput");
	TypesMap.Insert(Type("DocumentRef.FixedAssetsTransfer"), "FixedAssetsTransfer");
	TypesMap.Insert(Type("DocumentRef.FixedAssetsWriteOff"), "FixedAssetsWriteOff");
	TypesMap.Insert(Type("DocumentRef.GoodsExpense"), "GoodsExpense");
	TypesMap.Insert(Type("DocumentRef.GoodsReceipt"), "GoodsReceipt");
	TypesMap.Insert(Type("DocumentRef.InventoryAssembly"), "InventoryAssembly");
	TypesMap.Insert(Type("DocumentRef.InventoryReceipt"), "InventoryReceipt");
	TypesMap.Insert(Type("DocumentRef.InventoryReconciliation"), "InventoryReconciliation");
	TypesMap.Insert(Type("DocumentRef.InventoryReservation"), "InventoryReservation");
	TypesMap.Insert(Type("DocumentRef.InventoryTransfer"), "InventoryTransfer");
	TypesMap.Insert(Type("DocumentRef.InventoryWriteOff"), "InventoryWriteOff");
	TypesMap.Insert(Type("DocumentRef.InvoiceForPayment"), "InvoiceForPayment");
	TypesMap.Insert(Type("DocumentRef.JobSheet"), "JobSheet");
	TypesMap.Insert(Type("DocumentRef.LoanContract"), "LoanContract");
	TypesMap.Insert(Type("DocumentRef.LoanInterestCommissionAccruals"), "LoanInterestCommissionAccruals");
	TypesMap.Insert(Type("DocumentRef.MonthEnd"), "MonthEnd");
	TypesMap.Insert(Type("DocumentRef.Netting"), "Netting");
	TypesMap.Insert(Type("DocumentRef.Operation"), "Operation");
	TypesMap.Insert(Type("DocumentRef.OtherExpenses"), "OtherExpenses");
	TypesMap.Insert(Type("DocumentRef.PaymentExpense"), "PaymentExpense");
	TypesMap.Insert(Type("DocumentRef.PaymentOrder"), "PaymentOrder");
	TypesMap.Insert(Type("DocumentRef.PaymentReceipt"), "PaymentReceipt");
	TypesMap.Insert(Type("DocumentRef.PaymentReceiptPlan"), "PaymentReceiptPlan");
	TypesMap.Insert(Type("DocumentRef.Payroll"), "Payroll");
	TypesMap.Insert(Type("DocumentRef.PayrollSheet"), "PayrollSheet");
	TypesMap.Insert(Type("DocumentRef.PowerOfAttorney"), "PowerOfAttorney");
	TypesMap.Insert(Type("DocumentRef.ProcessingReport"), "ProcessingReport");
	TypesMap.Insert(Type("DocumentRef.ProductionOrder"), "ProductionOrde");
	TypesMap.Insert(Type("DocumentRef.PurchaseOrder"), "PurchaseOrder");
	TypesMap.Insert(Type("DocumentRef.ReceiptCR"), "ReceiptCR");
	TypesMap.Insert(Type("DocumentRef.ReceiptCRReturn"), "ReceiptCRReturn");
	TypesMap.Insert(Type("DocumentRef.RegistersCorrection"), "RegistersCorrection");
	TypesMap.Insert(Type("DocumentRef.ReportToPrincipal"), "ReportToPrincipal");
	TypesMap.Insert(Type("DocumentRef.RetailReport"), "RetailReport");
	TypesMap.Insert(Type("DocumentRef.RetailRevaluation"), "RetailRevaluation");
	TypesMap.Insert(Type("DocumentRef.SalesTarget"), "SalesTarget");
	TypesMap.Insert(Type("DocumentRef.SettlementsReconciliation"), "SettlementsReconciliation");
	TypesMap.Insert(Type("DocumentRef.SubcontractorReport"), "SubcontractorReport");
	TypesMap.Insert(Type("DocumentRef.SupplierInvoice"), "SupplierInvoice");
	TypesMap.Insert(Type("DocumentRef.SupplierInvoiceForPayment"), "SupplierInvoiceForPayment");
	TypesMap.Insert(Type("DocumentRef.TaxAccrual"), "TaxAccrual");
	TypesMap.Insert(Type("DocumentRef.Timesheet"), "Timesheet");
	TypesMap.Insert(Type("DocumentRef.TimeTracking"), "TimeTracking");
	TypesMap.Insert(Type("DocumentRef.TransferBetweenCells"), "TransferBetweenCells");
	TypesMap.Insert(Type("DocumentRef.WorkOrder"), "WorkOrder");
	
	Return TypesMap.Get(DocumentType);

EndFunction
