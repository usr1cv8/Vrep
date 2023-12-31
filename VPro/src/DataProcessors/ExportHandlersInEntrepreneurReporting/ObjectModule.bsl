#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

////////////////////////////////////////////////////////////////////////////////
// Conversion export handlers SmallBusiness --> EnterpreneurReporting {31e0f9a3-4b4d-11e2-a4ef-00055d4ef1e7}                                                                   
// 
// This module contains export procedures of conversion event handlers and is intended for exchange rule debugging. After debugging
// it is recommended to copy module text to the clipboard and
// import it in base "Data conversion".
//
// /////////////////////////////////////////////////////////////////////////////
// USED SHORT NAMES VARIABLES (ABBREVIATIONS)
//
//  OCR  - object conversion rule  
//  PCR  - object property conversion rule
//  PGCR - object property group conversion rule
//  DDR  - data export rule
//  DCR  - data clearing rule

////////////////////////////////////////////////////////////////////////////////
// DATA PROCESSOR VARIABLES
// It is prohibited to change this section.

Var Parameters;
Var Algorithms;
Var Queries;
Var NodeForExchange;
Var CommonProcedureFunctions;

////////////////////////////////////////////////////////////////////////////////
// CONVERSION HANDLERS (GLOBAL)
// It is allowed to modify the procedure implementation in this section.

Procedure Conversion_BeforeDataExport(ExchangeFile, Cancel) Export

	
	NationalCurrency = Constants.NationalCurrency.Get();
	Parameters.Insert("NationalCurrency", NationalCurrency);

EndProcedure

Procedure Conversion_BeforeSendDeletionInfo(Ref, Cancel) Export

	
	If TypeOf(Ref) = Type("DocumentRef.CashReceipt")
		OR TypeOf(Ref) = Type("DocumentRef.CashPayment")
		OR TypeOf(Ref) = Type("DocumentRef.PaymentReceipt")
		OR TypeOf(Ref) = Type("DocumentRef.PaymentExpense") Then
	
		Cancel = True;
	
		RecordSet = New ValueTable;
		GenerateSetOfRecordsOfRegister (Ref, RecordSet, Parameters);
	
		DumpRegister(RecordSet,,,True, "PaymentDocument");	
		
	EndIf;

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// OBJECT CONVERSION HANDLERS
// It is allowed to modify the procedure implementation in this section.

Procedure OCR_Companies_BeforeObjectExport(ExchangeFile, Source, IncomingData, OutgoingData, OCRName, OCR,
	ExportedObjects, Cancel, ExportedDataKey, RememberExported,
	DoNotReplaceObjectOnImport, AllObjectsAreExported, GetRefNodeOnly,
	Receiver, WriteMode, PostingMode, DoNotCreateIfNotFound) Export

	If ValueIsFilled(Source.Individual) Then
		
		Query = New Query(
		"SELECT
		|	IndividualsDescriptionFullSliceLast.Surname AS Surname,
		|	IndividualsDescriptionFullSliceLast.Name AS Name,
		|	IndividualsDescriptionFullSliceLast.Patronymic AS Patronymic,
		|	IndividualsDescriptionFullSliceLast.Ind.BirthDate AS BirthDate,
		|	IndividualsDescriptionFullSliceLast.Ind.Gender AS Gender
		|FROM
		|	InformationRegister.IndividualsDescriptionFull.SliceLast(&Period, Ind = &Ind) AS IndividualsDescriptionFullSliceLast");
	
		Query.SetParameter("Period",  CurrentDate());
		Query.SetParameter("Ind", Source.Individual);
	
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			
			IndData = New Structure;
			IndData.Insert("Surname", Selection.Surname);
			IndData.Insert("Name", Selection.Name);
			IndData.Insert("Patronymic", Selection.Patronymic);
			IndData.Insert("BirthDate", Selection.BirthDate);
			IndData.Insert("Gender", Selection.Gender);
			
			Parameters.Insert("IndData", IndData);
			
		EndIf;
		
	EndIf;

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// OBJECT PROPERTY CONVERSION HANDLERS
// It is allowed to modify the procedure implementation in this section.

Procedure PCR_Companies_Surname_BeforeExportProperty_10_11(ExchangeFile, Source, Receiver, IncomingData, OutgoingData,
	PCR, OCR, CollectionObject, Cancel, Value, ReceiverType, OCRName,
	OCRNameextdimensiontype, Empty, Expression, PropertyCollectionNode, Donotreplace,
	ExportObject) Export

	If Parameters.Property("IndData") Then
		Value = Parameters.IndData.Surname;
	EndIf;

EndProcedure

Procedure PCR_Companies_Name_BeforeExportProperty_11_11(ExchangeFile, Source, Receiver, IncomingData, OutgoingData,
	PCR, OCR, CollectionObject, Cancel, Value, ReceiverType, OCRName,
	OCRNameextdimensiontype, Empty, Expression, PropertyCollectionNode, Donotreplace,
	ExportObject) Export

	If Parameters.Property("IndData") Then
		Value = Parameters.IndData.Name;
	EndIf;

EndProcedure

Procedure PCR_Companies_Patronymic_BeforeExportProperty_12_11(ExchangeFile, Source, Receiver, IncomingData, OutgoingData,
	PCR, OCR, CollectionObject, Cancel, Value, ReceiverType, OCRName,
	OCRNameextdimensiontype, Empty, Expression, PropertyCollectionNode, Donotreplace,
	ExportObject) Export

	If Parameters.Property("IndData") Then
		Value = Parameters.IndData.Patronymic;
	EndIf;

EndProcedure

Procedure PCR_Companies_Gender_BeforeExportProperty_13_11(ExchangeFile, Source, Receiver, IncomingData, OutgoingData,
	PCR, OCR, CollectionObject, Cancel, Value, ReceiverType, OCRName,
	OCRNameextdimensiontype, Empty, Expression, PropertyCollectionNode, Donotreplace,
	ExportObject) Export

	If Parameters.Property("IndData") Then
		Value = Parameters.IndData.Gender;
	EndIf;

EndProcedure

Procedure PCR_Companies_BirthDate_BeforeExportProperty_14_11(ExchangeFile, Source, Receiver, IncomingData, OutgoingData,
	PCR, OCR, CollectionObject, Cancel, Value, ReceiverType, OCRName,
	OCRNameextdimensiontype, Empty, Expression, PropertyCollectionNode, Donotreplace,
	ExportObject) Export

	If Parameters.Property("IndData") Then
		Value = Parameters.IndData.BirthDate;
	EndIf;

EndProcedure

Procedure PCR_Companies_ContactInformation_FieldsValues_OnExportProperty_20_11(ExchangeFile, Source, Receiver, IncomingData, OutgoingData,
	PCR, OCR, CollectionObject, Cancel, Value, KeyAndValue, ExtDimensionType,
	ExtDimension, Empty, OCRName, OCRProperties,Propirtiesnode, PropertyCollectionNode,
	OCRNameextdimensiontype, ExportObject) Export

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// OBJECT PROPERTY GROUP CONVERSION HANDLERS
// It is allowed to modify the procedure implementation in this section.

////////////////////////////////////////////////////////////////////////////////
// DATA EXPORT HANDLERS
// It is allowed to modify the procedure implementation in this section.

Procedure DDR_CashReceipt_BeforeObjectExport(ExchangeFile, Cancel, OCRName, Rule, IncomingData, OutgoingData, Object) Export

	
	Cancel = True;
	
	RecordSet = New ValueTable;
	Ref = Object.Ref;
	
	GenerateSetOfRecordsOfRegister (Ref, RecordSet, Parameters);
	
	DumpRegister(RecordSet,,,True, "PaymentDocument");

EndProcedure

Procedure DDR_PaymentReceipt_BeforeObjectExport(ExchangeFile, Cancel, OCRName, Rule, IncomingData, OutgoingData, Object) Export

	
	Cancel = True;
	
	RecordSet = New ValueTable;
	Ref = Object.Ref;
	
	GenerateSetOfRecordsOfRegister (Ref, RecordSet, Parameters);
	
	DumpRegister(RecordSet,,,True, "PaymentDocument");

EndProcedure

Procedure DDR_CashPayment_BeforeObjectExport(ExchangeFile, Cancel, OCRName, Rule, IncomingData, OutgoingData, Object) Export

	
	Cancel = True;
	
	RecordSet = New ValueTable;
	Ref = Object.Ref;
	
	GenerateSetOfRecordsOfRegister (Ref, RecordSet, Parameters);
	
	DumpRegister(RecordSet,,,True, "PaymentDocument");

EndProcedure

Procedure DDR_PaymentExpense_BeforeObjectExport(ExchangeFile, Cancel, OCRName, Rule, IncomingData, OutgoingData, Object) Export

	
	Cancel = True;
	
	RecordSet = New ValueTable;
	Ref = Object.Ref;
	
	GenerateSetOfRecordsOfRegister (Ref, RecordSet, Parameters);
	
	DumpRegister(RecordSet,,,True, "PaymentDocument");

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// DATA CLEARING
// HANDLERS It is allowed to modify the procedure implementation in this section.

////////////////////////////////////////////////////////////////////////////////
// PARAMETER HANDLERS
// It is allowed to modify the procedure implementation in this section.

////////////////////////////////////////////////////////////////////////////////
// ALGORITHMS
// It is allowed to change this section.
// Also it is allowed to place procedure with algorithms in any section above.

Procedure GenerateSetOfRecordsOfRegister(Ref, RecordSet, Parameters) Export

	
	Filter = New ValueTable;
	Filter.Columns.Add("Use");
	Filter.Columns.Add("Name");
	Filter.Columns.Add("Value");
	
	Rows = New ValueTable;
	Rows.Columns.Add("Company");
	Rows.Columns.Add("ObjectID");
	Rows.Columns.Add("Counterparty");
	Rows.Columns.Add("Content");
	Rows.Columns.Add("Income");
	Rows.Columns.Add("Expense");
	Rows.Columns.Add("PrimaryDocumentDate");
	Rows.Columns.Add("NumberOfPrimaryDocument");
	
	Rows.Columns.Add("Ref"); // Technical field
	
	FilterItem = Filter.Add();
	FilterItem.Use = True;
	FilterItem.Name = "ObjectID";
	FilterItem.Value = String(Ref.UUID());
	
		If Ref.Posted Then // For non-posted documents export a blank record set
			
			Record = Rows.Add();
			Record.Company = Ref.Company;
			Record.ObjectID = String(Ref.UUID());
			Record.Counterparty = Ref.Counterparty.Description;
			
			OperationKindRow = "";
			If TypeOf(Ref) = Type("DocumentRef.CashReceipt") Then
				
				If Ref.OperationKind = Enums.OperationKindsCashReceipt.FromCustomer Then
					OperationKindRow = StringFunctionsClientServer.SubstituteParametersInString(NStr("en='Cash receipt from the ""%1"" customer';ru='Поступление наличных денежных средств от покупателя ""%1""';vi='Thu tiền từ khách hàng ""%1""'"), TrimAll(Ref.Counterparty));
				ElsIf Ref.OperationKind = Enums.OperationKindsCashReceipt.FromVendor Then
					OperationKindRow = StringFunctionsClientServer.SubstituteParametersInString(NStr("en='Cash receipt from supplier ""%1""';ru='Поступление наличных денежных средств от поставщика ""%1""';vi='Thu tiền từ nhà cung cấp ""%1""'"), TrimAll(Ref.Counterparty));
				ElsIf Ref.OperationKind = Enums.OperationKindsCashReceipt.FromAdvanceHolder Then
					OperationKindRow = StringFunctionsClientServer.SubstituteParametersInString(NStr("en='Cash receipt from the ""%1"" advance holder';ru='Поступление наличных денежных средств от подотчетника ""%1""';vi='Thu tiền mặt từ người nhận tạm ứng ""%1""'"), TrimAll(Ref.AdvanceHolder));
				ElsIf Ref.OperationKind = Enums.OperationKindsCashReceipt.RetailIncome
					OR Ref.OperationKind = Enums.OperationKindsCashReceipt.RetailIncomeAccrualAccounting Then
					OperationKindRow = NStr("en='Retail Revenue Receipt';ru='Поступление розничной выручки';vi='Tiếp nhận doanh thu bán lẻ'");
				ElsIf Ref.OperationKind = Enums.OperationKindsCashReceipt.CurrencyPurchase Then
					OperationKindRow = NStr("en='Receipt of currency transaction cash';ru='Поступление наличных денежных средств по валютным операциям';vi='Thu tiền theo các giao dịch ngoại tệ'");
				ElsIf Ref.OperationKind = Enums.OperationKindsCashReceipt.Other Then
					OperationKindRow = NStr("en='Receipt of other transaction cash';ru='Поступление наличных денежных средств по прочим операциям';vi='Thu tiền theo các giao dịch khác'");
				EndIf;
				
			ElsIf TypeOf(Ref) = Type("DocumentRef.PaymentReceipt") Then
				
				If Ref.OperationKind = Enums.OperationKindsPaymentReceipt.FromCustomer Then
					OperationKindRow = StringFunctionsClientServer.SubstituteParametersInString(NStr("en='Non-cash receipt from customer ""%1""';ru='Поступление безналичных денежных средств от покупателя ""%1""';vi='Tiếp nhận tiền gửi từ khách hàng ""%1""'"), TrimAll(Ref.Counterparty));
				ElsIf Ref.OperationKind = Enums.OperationKindsPaymentReceipt.FromVendor Then
					OperationKindRow = StringFunctionsClientServer.SubstituteParametersInString(NStr("en='Non-cash receipt from supplier ""%1""';ru='Поступление безналичных денежных средств от поставщика ""%1""';vi='Tiếp nhận tiền gửi từ nhà cung cấp ""%1""'"), TrimAll(Ref.Counterparty));
				ElsIf Ref.OperationKind = Enums.OperationKindsPaymentReceipt.FromAdvanceHolder Then
					OperationKindRow = StringFunctionsClientServer.SubstituteParametersInString(NStr("en='Non-cash receipt from advance holder ""%1""';ru='Поступление безналичных денежных средств от подотчетника ""%1""';vi='Tiếp nhận tiền gửi từ người nhận tạm ứng ""%1""'"), TrimAll(Ref.AdvanceHolder));
				ElsIf Ref.OperationKind = Enums.OperationKindsPaymentReceipt.CurrencyPurchase Then
					OperationKindRow = NStr("en='Receipt of non-cash of the currency transactions';ru='Поступление безналичных денежных средств по валютным операциям';vi='Tiếp nhận tiền gửi theo giao dịch tiền tệ'");
				ElsIf Ref.OperationKind = Enums.OperationKindsPaymentReceipt.Other Then
					OperationKindRow = NStr("en='Non-cash receipt by other operations';ru='Поступление безналичных денежных средств по прочим операциям';vi='Thu tiền mặt theo các giao dịch khác'");
				EndIf;
				
				If ValueIsFilled(Ref.PaymentDestination) Then
					OperationKindRow = OperationKindRow + ", " + Chars.LF + TrimAll(Ref.PaymentDestination);
				EndIf;
				
			ElsIf TypeOf(Ref) = Type("DocumentRef.CashPayment") Then
				
				If Ref.OperationKind = Enums.OperationKindsCashPayment.Vendor Then
					OperationKindRow = StringFunctionsClientServer.SubstituteParametersInString(NStr("en='Cash expense for payment to the ""%1"" supplier';ru='Расход наличных денежных средств на оплату поставщику ""%1""';vi='Chi phí tiền mặt để thanh toán cho người bán ""%1""'"), TrimAll(Ref.Counterparty));
				ElsIf Ref.OperationKind = Enums.OperationKindsCashPayment.ToCustomer Then
					OperationKindRow = StringFunctionsClientServer.SubstituteParametersInString(NStr("en='Cash expense for payment to the ""%1"" customer';ru='Расход наличных денежных средств на оплату покупателю ""%1""';vi='Chi phí tiền mặt để thanh toán cho người mua ""%1""'"), TrimAll(Ref.Counterparty));
				ElsIf Ref.OperationKind = Enums.OperationKindsCashPayment.ToAdvanceHolder Then
					OperationKindRow = StringFunctionsClientServer.SubstituteParametersInString(NStr("en='Issue funds to the ""%1"" advance holder';ru='Выдача наличных денежных средств подотчетнику ""%1""';vi='Chi tiền cho người nhận tạm ứng ""%1""'"), TrimAll(Ref.AdvanceHolder));
				ElsIf Ref.OperationKind = Enums.OperationKindsCashPayment.Salary
					OR Ref.OperationKind = Enums.OperationKindsCashPayment.SalaryForEmployee Then
					OperationKindRow = NStr("en='Cash expense for salary payment';ru='Расход наличных денежных средств на выплату заработной платы';vi='Chi phí tiền mặt để thanh toán lương'");
				ElsIf Ref.OperationKind = Enums.OperationKindsCashPayment.Taxes Then
					OperationKindRow = NStr("en='Cash expense for tax payment';ru='Расход наличных денежных средств на уплату налогов';vi='Chi phí tiền mặt để nộp thuế'");
				ElsIf Ref.OperationKind = Enums.OperationKindsCashPayment.TransferToCashCR Then
					OperationKindRow = NStr("en='Cash transfer to cash register';ru='Перемещение наличных денежных средств в кассу ККМ';vi='Chuyển tiền vào quầy thu ngân'");
				ElsIf Ref.OperationKind = Enums.OperationKindsCashPayment.Other Then
					OperationKindRow = NStr("en='Other operation cash expense';ru='Расход наличных денежных средств по прочим операциям';vi='Chi phí tiền mặt theo các giao dịch khác'");
				EndIf;
				
			ElsIf TypeOf(Ref) = Type("DocumentRef.PaymentExpense") Then
				
				If Ref.OperationKind = Enums.OperationKindsPaymentExpense.Vendor Then
					OperationKindRow = StringFunctionsClientServer.SubstituteParametersInString(NStr("en='Non-cash expense for payment to supplier ""%1""';ru='Расход безналичных денежных средств на оплату поставщику ""%1""';vi='Chi phí tiền gửi để thanh toán cho nhà cung cấp ""%1""'"), TrimAll(Ref.Counterparty));
				ElsIf Ref.OperationKind = Enums.OperationKindsPaymentExpense.ToCustomer Then
					OperationKindRow = StringFunctionsClientServer.SubstituteParametersInString(NStr("en='Non-cash expense for payment to customer ""%1""';ru='Расход безналичных денежных средств на оплату покупателю ""%1""';vi='Chi phí tiền gửi để thanh toán cho khách hàng ""%1""'"), TrimAll(Ref.Counterparty));
				ElsIf Ref.OperationKind = Enums.OperationKindsPaymentExpense.ToAdvanceHolder Then
					OperationKindRow = StringFunctionsClientServer.SubstituteParametersInString(NStr("en='Non-cash issue to advance holder ""%1""';ru='Выдача безналичных денежных средств подотчетнику ""%1""';vi='Chi tiền cho người nhận tạm ứng ""%1""'"), TrimAll(Ref.AdvanceHolder));
				ElsIf Ref.OperationKind = Enums.OperationKindsPaymentExpense.Salary Then
					OperationKindRow = NStr("en='Expense of the non-cash for salary payment';ru='Расход безналичных денежных средств на выплату заработной платы';vi='Chi phí tiền gửi để thanh toán tiền lương'");
				ElsIf Ref.OperationKind = Enums.OperationKindsPaymentExpense.Taxes Then
					OperationKindRow = NStr("en='Non-cash expense for tax payment';ru='Расход безналичных денежных средств на уплату налогов';vi='Chi phí tiền gửi để thanh toán thuế'");
				ElsIf Ref.OperationKind = Enums.OperationKindsPaymentExpense.Other Then
					OperationKindRow = NStr("en='Non-cash expense for other operations';ru='Расход безналичных денежных средств по прочим операциям';vi='Chi phí tiền gửi theo các giao dịch khác'");
				EndIf;
				
				If ValueIsFilled(Ref.PaymentDestination) Then
					OperationKindRow = OperationKindRow + ", " + Chars.LF + TrimAll(Ref.PaymentDestination);
				EndIf;
				
			EndIf;
			
			OperationKindRow = OperationKindRow + ".";
			Record.Content = OperationKindRow;
			
			If (TypeOf(Ref) = Type("DocumentRef.PaymentReceipt") 
				OR TypeOf(Ref) = Type("DocumentRef.PaymentExpense"))
				AND ValueIsFilled(Ref.IncomingDocumentNumber) Then
				
				Record.NumberOfPrimaryDocument = ObjectPrefixationClientServer.GetNumberForPrinting(Ref.IncomingDocumentNumber, True, True);
			Else
				Record.NumberOfPrimaryDocument = ObjectPrefixationClientServer.GetNumberForPrinting(Ref.Number, True, True);
			EndIf;
			Record.PrimaryDocumentDate = Ref.Date;
			
			If Ref.CashCurrency = Parameters.NationalCurrency Then
				
				Amount = Ref.DocumentAmount;
				
			Else
				
				Query = New Query(
				"SELECT
				|	CASE
				|		WHEN ISNULL(DocumentCurrencyCurrencyRates.Multiplicity, 0) > 0
				|				AND ISNULL(DocumentCurrencyCurrencyRates.ExchangeRate, 0) > 0
				|				AND ISNULL(ExchangeRateOfNationalCurrencies.Multiplicity, 0) > 0
				|				AND ISNULL(ExchangeRateOfNationalCurrencies.ExchangeRate, 0) > 0
				|			THEN DocumentCurrencyCurrencyRates.ExchangeRate * ExchangeRateOfNationalCurrencies.Multiplicity / (ExchangeRateOfNationalCurrencies.ExchangeRate * DocumentCurrencyCurrencyRates.Multiplicity)
				|		ELSE 0
				|	END AS Factor
				|FROM
				|	InformationRegister.CurrencyRates.SliceLast(&Date, Currency = &DocumentCurrency) AS DocumentCurrencyCurrencyRates
				|		INNER JOIN InformationRegister.CurrencyRates.SliceLast(&Date, Currency = &NationalCurrency) AS ExchangeRateOfNationalCurrencies
				|		ON (TRUE)");
				
				Query.SetParameter("Date", Ref.Date);
				Query.SetParameter("NationalCurrency", Parameters.NationalCurrency);
				Query.SetParameter("DocumentCurrency", Ref.CashCurrency);
				
				Selection = Query.Execute().Select();
				If Selection.Next() Then
					Amount = Ref.DocumentAmount * Selection.Factor;
				Else
					Amount = 0;
				EndIf;
				
			EndIf;
			
			If TypeOf(Ref) = Type("DocumentRef.CashReceipt")
				OR TypeOf(Ref) = Type("DocumentRef.PaymentReceipt") Then
				
				Record.Income = Amount;
				Record.Expense = 0;
				
			Else
				
				Record.Income = 0;
				Record.Expense = Amount;
				
			EndIf;
			
		EndIf;
		
		RecordSet = New Structure("Filter, Rows", Filter, Rows);

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// SERVICE PROCEDURES AND FUNCTIONS
// It is prohibited to change this section.

// Exports register by filter.
// 
// Parameters:
//  RecordSetForExport - Structure or RecordSet - Filter
//
Procedure DumpRegister(RecordSetForExport, 
							Rule = Undefined, 
							IncomingData = Undefined, 
							DoNotDumpObjectsByRefs = False, 
							OCRName = "",
							DataExportRule = Undefined)
							
	CommonProcedureFunctions.DumpRegister(RecordSetForExport, Rule, IncomingData, DoNotDumpObjectsByRefs, OCRName, DataExportRule);

EndProcedure

// Initializes the variables necessary for debugging
//
// Parameters:
//  Owner - Data processor InfobaseObjectConversion
//
Procedure ConnectProcessingForDebugging(Owner) Export

	Parameters            	 = Owner.Parameters;
	CommonProcedureFunctions = Owner;
	Queries              	  = Owner.Queries;
	NodeForExchange		 	    = Owner.NodeForExchange;

EndProcedure

#EndIf
