#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

///////////////////////////////////////////////////////////////////////////////
// PROCEDURES OF FILLING THE DOCUMENT

// Procedure of document filling on the basis of the goods receipt.
//
// Parameters:
//  BasisDocument - DocumentRef.PaymentReceiptPlan - Planned payment
//  FillingData - Structure - Document filling data
//	
Procedure FillByGoodsReceipt(FillingData)
	
	Company = FillingData.Company;
	BasisDocument = FillingData.Ref;
	Inventory.Clear();
	
	For Each CurStringInventory IN FillingData.Inventory Do
		
		NewRow = Inventory.Add();
		NewRow.MeasurementUnit = CurStringInventory.MeasurementUnit;
		NewRow.Quantity = CurStringInventory.Quantity;
		NewRow.ProductsAndServices = CurStringInventory.ProductsAndServices;
		NewRow.Batch = CurStringInventory.Batch;
		NewRow.Characteristic = CurStringInventory.Characteristic;
		NewRow.StructuralUnit = FillingData.StructuralUnit;
		NewRow.Cell = FillingData.Cell;
		
	EndDo;
	
EndProcedure // FillByCashTransferPlan()

// Procedure of document filling on the basis of the cash payment.
//
// Parameters:
//  BasisDocument - DocumentRef.PaymentReceiptPlan - Planned payment
//  FillingData - Structure - Document filling data
//	
Procedure FillByCashPayment(FillingData)
	
	If FillingData.OperationKind <> Enums.OperationKindsCashPayment.ToAdvanceHolder Then
		Raise NStr("en='Cannot enter expense report based on the expenses from cash fund with this operation kind.';ru='Нельзя ввести Авансовый отчет на основании расхода из кассы с этим видом операции!';vi='Không thể nhập Giấy thanh toán tiền tạm ứng trên cơ sở chi từ quỹ tiền mặt với dạng giao dịch này!'");
	EndIf;
	
	Company = FillingData.Company;
	BasisDocument = FillingData.Ref;
	Employee = FillingData.AdvanceHolder;
	DocumentCurrency = FillingData.CashCurrency;
	
	StructureByCurrency = InformationRegisters.CurrencyRates.GetLast(Date, New Structure("Currency", DocumentCurrency));
	ExchangeRate = ?(
		StructureByCurrency.ExchangeRate = 0,
		1,
		StructureByCurrency.ExchangeRate
	);
	Multiplicity = ?(
		StructureByCurrency.ExchangeRate = 0,
		1,
		StructureByCurrency.Multiplicity
	);
	
	AdvancesPaid.Clear();
	NewRow = AdvancesPaid.Add();
	NewRow.Document = FillingData.Ref;
	NewRow.Amount = FillingData.DocumentAmount;
	
EndProcedure // FillByCashPayment()

// Procedure of document filling based on the payment expense.
//
// Parameters:
//  BasisDocument - DocumentRef.PaymentReceiptPlan - Planned payment 
//  FillingData - Structure - Document filling data
//	
Procedure FillByPaymentExpense(FillingData)
	
	If FillingData.OperationKind <> Enums.OperationKindsPaymentExpense.ToAdvanceHolder Then
		Raise NStr("en='Cannot enter expense report based on the expenses from account with this operation kind.';ru='Нельзя ввести Авансовый отчет на основании расхода со счета с этим видом операции!';vi='Không thể nhập Giấy thanh toán tiền tạm ứng trên cơ sở chi từ tài khoản với dạng giao dịch này!'");
	EndIf;
	
	Company = FillingData.Company;
	BasisDocument = FillingData.Ref;
	Employee = FillingData.AdvanceHolder;
	DocumentCurrency = FillingData.CashCurrency;
	
	StructureByCurrency = InformationRegisters.CurrencyRates.GetLast(Date, New Structure("Currency", DocumentCurrency));
	ExchangeRate = ?(
		StructureByCurrency.ExchangeRate = 0,
		1,
		StructureByCurrency.ExchangeRate
	);
	Multiplicity = ?(
		StructureByCurrency.ExchangeRate = 0,
		1,
		StructureByCurrency.Multiplicity
	);
	
	AdvancesPaid.Clear();
	NewRow = AdvancesPaid.Add();
	NewRow.Document = FillingData.Ref;
	NewRow.Amount = FillingData.DocumentAmount;
	
EndProcedure // FillByPaymentExpense()

////////////////////////////////////////////////////////////////////////////////
// EVENT HANDLERS

// Procedure - handler of the FillingProcessor event.
//
Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("DocumentRef.GoodsReceipt") Then
		FillByGoodsReceipt(FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.CashPayment") Then
		FillByCashPayment(FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.PaymentExpense") Then
		FillByPaymentExpense(FillingData);
	EndIf;
	
EndProcedure // FillingProcessor()

// Procedure - event handler FillCheckProcessing object.
//
Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	TotalExpences = AdvancesPaid.Total("Amount");
	InventoryTotal = Inventory.Total("Total");
	ExpencesTotal = Expenses.Total("Total");
	PaymentsTotals = Payments.Total("PaymentAmount");
	
	If TotalExpences > InventoryTotal + ExpencesTotal + PaymentsTotals Then
		MessageText = NStr("en='Spent advance amount exceeds the amount of the document.';ru='Израсходованная сумма авансов превышает сумму по документу!';vi='Số tiền đã chi ứng trước vượt quá số tiền theo chứng từ!'");
		SmallBusinessServer.ShowMessageAboutError(
			ThisObject,
			MessageText,
			"AdvancesPaid",
			1,
			"Amount",
			Cancel
		);
	EndIf;
	
	For Each PaymentRow IN Payments Do
		If PaymentRow.Counterparty.DoOperationsByDocuments
		   AND Not PaymentRow.AdvanceFlag
		   AND Not ValueIsFilled(PaymentRow.Document) Then
			MessageText = NStr("en='The ""Settlement document"" column is not populated in the %LineNumber% line of the ""Payments"" list.';ru='Не заполнена колонка ""Документ расчетов"" в строке %НомерСтроки% списка ""Оплаты"".';vi='Chưa điền cột ""Chứng từ thanh toán"" tại dòng %LineNumber% của danh sách ""Thanh toán"".'");
			MessageText = StrReplace(MessageText, "%LineNumber%", String(PaymentRow.LineNumber));
			SmallBusinessServer.ShowMessageAboutError(
				ThisObject,
				MessageText,
				"Payments",
				PaymentRow.LineNumber,
				"Document",
				Cancel
			);
		EndIf;
	EndDo;
	
	For Each RowsExpenses IN Expenses Do
		
		If GetFunctionalOption("AccountingBySeveralDepartments")
		   AND (RowsExpenses.ProductsAndServices.ExpensesGLAccount.TypeOfAccount = Enums.GLAccountsTypes.UnfinishedProduction
		 OR RowsExpenses.ProductsAndServices.ExpensesGLAccount.TypeOfAccount = Enums.GLAccountsTypes.IndirectExpenses
		 OR RowsExpenses.ProductsAndServices.ExpensesGLAccount.TypeOfAccount = Enums.GLAccountsTypes.Incomings
		 OR RowsExpenses.ProductsAndServices.ExpensesGLAccount.TypeOfAccount = Enums.GLAccountsTypes.Expenses)
		 AND Not ValueIsFilled(RowsExpenses.StructuralUnit) Then
			MessageText = NStr("en='The ""Department"" attribute must be filled in for the %ProductsAndServices%"" products and services in the %LineNumber% line of the ""Expenses"" list.';ru='Для номенклатуры ""%Номенклатура%"" указанной в строке %НомерСтроки% списка ""Расходы"", должен быть заполнен реквизит ""Подразделение"".';vi='Đối với mặt hàng ""%ProductsAndServices%"" đã chỉ ra trong dòng %LineNumber% của danh sách ""Chi phí"", cần điền mục tin ""Bộ phận"".'"
			);
			MessageText = StrReplace(MessageText, "%ProductsAndServices%", TrimAll(String(RowsExpenses.ProductsAndServices))); 
			MessageText = StrReplace(MessageText, "%LineNumber%",String(RowsExpenses.LineNumber));
			SmallBusinessServer.ShowMessageAboutError(
				ThisObject,
				MessageText,
				"Expenses",
				RowsExpenses.LineNumber,
				"StructuralUnit",
				Cancel
			);
		EndIf;
		
	EndDo;
	
EndProcedure // FillCheckProcessing()

// Procedure - event handler BeforeWrite object.
//
Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentAmount = Inventory.Total("Total") + Expenses.Total("Total") + Payments.Total("PaymentAmount");
	
	If Not Constants.FunctionalOptionAccountingByMultipleBusinessActivities.Get() Then
		
		For Each RowsExpenses in Expenses Do
			
			If RowsExpenses.ProductsAndServices.ExpensesGLAccount.TypeOfAccount = Enums.GLAccountsTypes.Expenses Then
				
				RowsExpenses.BusinessActivity = Catalogs.BusinessActivities.MainActivity;
				
			Else
				
				RowsExpenses.BusinessActivity = Undefined;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	For Each TSRow IN Payments Do
		If ValueIsFilled(TSRow.Counterparty)
		AND Not TSRow.Counterparty.DoOperationsByContracts
		AND Not ValueIsFilled(TSRow.Contract) Then
			TSRow.Contract = TSRow.Counterparty.ContractByDefault;
		EndIf;
	EndDo;
	
EndProcedure // BeforeWrite()

// Procedure - event handler Posting object.
//
Procedure Posting(Cancel, PostingMode)
	
	// Initialization of additional properties for document posting.
	SmallBusinessServer.InitializeAdditionalPropertiesForPosting(Ref, AdditionalProperties);
	
	// Document data initialization.
	Documents.ExpenseReport.InitializeDocumentData(Ref, AdditionalProperties);
	
	// Preparation of records sets.
	SmallBusinessServer.PrepareRecordSetsForRecording(ThisObject);
	
	// Account for in accounting sections.
	SmallBusinessServer.ReflectInventoryForWarehouses(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectInventoryInWarehouses(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectInventory(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectAdvanceHolderPayments(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectAccountsPayable(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectIncomeAndExpenses(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectIncomeAndExpensesCashMethod(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectIncomeAndExpensesUndistributed(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectIncomeAndExpensesRetained(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectPurchasing(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectInvoicesAndOrdersPayment(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectPaymentCalendar(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectManagerial(AdditionalProperties, RegisterRecords, Cancel);
	
	// Record of the records sets.
	SmallBusinessServer.WriteRecordSets(ThisObject);
	
	// Control of occurrence of a negative balance.
	Documents.ExpenseReport.RunControl(Ref, AdditionalProperties, Cancel);
	
	AdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager.Close();
	
EndProcedure // Posting()

// Procedure - event handler UndoPosting object.
//
Procedure UndoPosting(Cancel)
	
	// Initialization of additional properties to undo document posting
	SmallBusinessServer.InitializeAdditionalPropertiesForPosting(Ref, AdditionalProperties);
	
	// Preparation of records sets.
	SmallBusinessServer.PrepareRecordSetsForRecording(ThisObject);
	
	// Record of the records sets.
	SmallBusinessServer.WriteRecordSets(ThisObject);
	
	// Control of occurrence of a negative balance.
	Documents.ExpenseReport.RunControl(Ref, AdditionalProperties, Cancel, True);
	
EndProcedure // UndoPosting()

#EndIf