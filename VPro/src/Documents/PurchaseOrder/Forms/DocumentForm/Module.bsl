
////////////////////////////////////////////////////////////////////////////////
// GENERAL PURPOSE PROCEDURES AND FUNCTIONS

&AtClient
// The procedure handles the change of the Price kind and Settlement currency document attributes
//
Procedure ProcessPricesKindAndSettlementsCurrencyChange(DocumentParameters)
	
	ContractBeforeChange = DocumentParameters.ContractBeforeChange;
	SettlementsCurrencyBeforeChange = DocumentParameters.SettlementsCurrencyBeforeChange;
	ContractData = DocumentParameters.ContractData;
	QueryPriceKind = DocumentParameters.QueryPriceKind;
	OpenFormPricesAndCurrencies = DocumentParameters.OpenFormPricesAndCurrencies;
	PriceKindChanged = DocumentParameters.PriceKindChanged;
	RecalculationRequired = DocumentParameters.RecalculationRequired;
	
	If Not ContractData.AmountIncludesVAT = Undefined Then
		
		Object.AmountIncludesVAT = ContractData.AmountIncludesVAT;
		
	EndIf;
	
	If ValueIsFilled(Object.Contract) Then 
		
		Object.ExchangeRate	  = ?(ContractData.SettlementsCurrencyRateRepetition.ExchangeRate = 0, 1, ContractData.SettlementsCurrencyRateRepetition.ExchangeRate);
		Object.Multiplicity = ?(ContractData.SettlementsCurrencyRateRepetition.Multiplicity = 0, 1, ContractData.SettlementsCurrencyRateRepetition.Multiplicity);
		
	EndIf;
	
	If PriceKindChanged Then
		
		Object.CounterpartyPriceKind	= ContractData.CounterpartyPriceKind;
		
	EndIf;
	
	If Object.DocumentCurrency <> ContractData.SettlementsCurrency Then
		
		Object.BankAccount = Undefined;
		
	EndIf;
	
	Object.DocumentCurrency = ContractData.SettlementsCurrency;
	
	If OpenFormPricesAndCurrencies Then
		
		WarningText = "";
		If PriceKindChanged Then
			
			WarningText = NStr("en='Counterparty contract specifies the counterparty"
"price kind that differs from the kind specified for the document! "
"Perhaps you have to refill prices.';ru='Договор с контрагентом"
"предусматривает вид цен контрагента, отличный от установленного в документе! "
"Возможно, необходимо перезаполнить цены.';vi='Hợp đồng với đối tác"
"xem xét dạng giá đối tác mà khác với dạng giá đã thiết lập trong chứng từ!"
"Có thể, cần điền lại đơn giá.'") + Chars.LF + Chars.LF;
			
		EndIf;
		
		WarningText = WarningText + NStr("en='Settlement currency of the contract with counterparty changed!"
"It is necessary to check the document currency!';ru='Изменилась валюта расчетов по договору с контрагентом!"
"Необходимо проверить валюту документа!';vi='Đã trhay đổi tiền tệ hạch toán theo hợp đồng với đối tác!"
"Cần kiểm tra tiền tệ của chứng từ!'");
		
		ProcessChangesOnButtonPricesAndCurrencies(SettlementsCurrencyBeforeChange, True, PriceKindChanged, WarningText);
		
	ElsIf QueryPriceKind Then
		
		LabelStructure 			= New Structure("DocumentCurrency, SettlementsCurrency, ExchangeRate, RateNationalCurrency, AmountIncludesVAT, CurrencyTransactionsAccounting, CounterpartyPriceKind, VATTaxation", 
			Object.DocumentCurrency, 
			SettlementsCurrency, 
			Object.ExchangeRate, 
			RateNationalCurrency, 
			Object.AmountIncludesVAT, 
			CurrencyTransactionsAccounting, 
			Object.CounterpartyPriceKind, 
			Object.VATTaxation);
		
		PricesAndCurrency = GenerateLabelPricesAndCurrency(LabelStructure);
		
		If RecalculationRequired Then
			
			QuestionText = NStr("en='The counterparty contract allows for the kind of prices other than prescribed in the document! "
"Recalculate the document according to the contract?';ru='Договор с контрагентом предусматривает вид цен, отличный от установленного в документе! "
"Пересчитать документ в соответствии с договором?';vi='Hợp đồng với đối tác xem xét dạng giá mà khác với dạng giá đã đặt trong chứng từ!"
"Đọc lại chứng từ tương ứng với hợp đồng?'");
			
			NotifyDescription = New NotifyDescription("DefineDocumentRecalculateNeedByContractTerms", ThisObject, DocumentParameters);
			ShowQueryBox(NOTifyDescription, QuestionText, QuestionDialogMode.YesNo);
			
		EndIf;
		
	Else
		
		LabelStructure 			= New Structure("DocumentCurrency, SettlementsCurrency, ExchangeRate, RateNationalCurrency, AmountIncludesVAT, CurrencyTransactionsAccounting, CounterpartyPriceKind, VATTaxation", 
			Object.DocumentCurrency, 
			SettlementsCurrency, 
			Object.ExchangeRate, 
			RateNationalCurrency, 
			Object.AmountIncludesVAT, 
			CurrencyTransactionsAccounting, 
			Object.CounterpartyPriceKind, 
			Object.VATTaxation);
		
		PricesAndCurrency = GenerateLabelPricesAndCurrency(LabelStructure);
		
	EndIf;
	
EndProcedure // ProcessPricesKindAndSettlementsCurrencyChange()

// It receives data set from server for the DateOnChange procedure.
//
&AtServerNoContext
Function GetDataDateOnChange(DocumentRef, DateNew, DateBeforeChange, SettlementsCurrency)
	
	DATEDIFF = SmallBusinessServer.CheckDocumentNumber(DocumentRef, DateNew, DateBeforeChange);
	CurrencyRateRepetition = InformationRegisters.CurrencyRates.GetLast(DateNew, New Structure("Currency", SettlementsCurrency));
	
	StructureData = New Structure;
	
	StructureData.Insert(
		"DATEDIFF",
		DATEDIFF
	);
	StructureData.Insert(
		"CurrencyRateRepetition",
		CurrencyRateRepetition
	);
	
	Return StructureData;
	
EndFunction // GetDataDateOnChange()

// Gets data set from server.
//
&AtServerNoContext
Function GetCompanyDataOnChange(Company)
	
	StructureData = New Structure();
	StructureData.Insert("Counterparty", SmallBusinessServer.GetCompany(Company));
	StructureData.Insert("BankAccount", Company.BankAccountByDefault);
	StructureData.Insert("BankAccountCashAssetsCurrency", Company.BankAccountByDefault.CashCurrency);
	
	Return StructureData;
	
EndFunction // GetCompanyDataOnChange()

// Receives the set of data from the server for the ProductsAndServicesOnChange procedure.
//
&AtServerNoContext
Function GetDataProductsAndServicesOnChange(StructureData)
	
	StructureData.Insert("MeasurementUnit", StructureData.ProductsAndServices.MeasurementUnit);
	
	If StructureData.Property("VATTaxation") 
		AND Not StructureData.VATTaxation = Enums.VATTaxationTypes.TaxableByVAT Then
		
		If StructureData.VATTaxation = Enums.VATTaxationTypes.NotTaxableByVAT Then
			StructureData.Insert("VATRate", SmallBusinessReUse.GetVATRateWithoutVAT());
		Else
			StructureData.Insert("VATRate", SmallBusinessReUse.GetVATRateZero());
		EndIf;	
																
	ElsIf ValueIsFilled(StructureData.ProductsAndServices.VATRate) Then
		StructureData.Insert("VATRate", StructureData.ProductsAndServices.VATRate);
	Else
		StructureData.Insert("VATRate", StructureData.Company.DefaultVATRate);
	EndIf;
	
	If StructureData.Property("CounterpartyPriceKind") Then
		
		Price = SmallBusinessServer.GetPriceProductsAndServicesByCounterpartyPriceKind(StructureData);
		StructureData.Insert("Price", Price);
		
	Else
		
		StructureData.Insert("Price", 0);
		
	EndIf;
	
	Return StructureData;
	
EndFunction // ReceiveDataProductsAndServicesOnChange()

// It receives data set from server for the CharacteristicOnChange procedure.
//
&AtServerNoContext
Function GetDataCharacteristicOnChange(StructureData)
	
	If StructureData.Property("CounterpartyPriceKind") Then
		
		If TypeOf(StructureData.MeasurementUnit) = Type("CatalogRef.UOMClassifier") Then
			StructureData.Insert("Factor", 1);
		Else
			StructureData.Insert("Factor", StructureData.MeasurementUnit.Factor);
		EndIf;		
		
		Price = SmallBusinessServer.GetPriceProductsAndServicesByCounterpartyPriceKind(StructureData);
		StructureData.Insert("Price", Price);
		
	Else
		
		StructureData.Insert("Price", 0);
		
	EndIf;	
	
	Return StructureData;
	
EndFunction // GetDataCharacteristicOnChange()

// Gets the data set from the server for procedure MeasurementUnitOnChange.
//
&AtServerNoContext
Function GetDataMeasurementUnitOnChange(CurrentMeasurementUnit = Undefined, MeasurementUnit = Undefined)
	
	StructureData = New Structure();
	
	If CurrentMeasurementUnit = Undefined Then
		StructureData.Insert("CurrentFactor", 1);
	Else
		StructureData.Insert("CurrentFactor", CurrentMeasurementUnit.Factor);
	EndIf;	
	
	If MeasurementUnit = Undefined Then
		StructureData.Insert("Factor", 1);
	Else	
		StructureData.Insert("Factor", MeasurementUnit.Factor);
	EndIf;	
	
	Return StructureData;
	
EndFunction // GetDataMeasurementUnitOnChange()

// Gets payment term by the contract.
//
&AtServerNoContext
Function GetVendorPaymentDueDate(Contract)
	
	Return Contract.VendorPaymentDueDate;
	
EndFunction // GetCustomerPaymentDueDate()

// It receives data set from the server for the CounterpartyOnChange procedure.
//
&AtServer
Function GetDataCounterpartyOnChange(Date, DocumentCurrency, Counterparty, Company)
	
	ContractByDefault = GetContractByDefault(Object.Ref, Counterparty, Company, Object.OperationKind);
	
	StructureData = New Structure();
	
	StructureData.Insert(
		"Contract",
		ContractByDefault
	);
	
	StructureData.Insert(
		"SettlementsCurrency",
		ContractByDefault.SettlementsCurrency
	);
	
	StructureData.Insert(
		"SettlementsCurrencyRateRepetition",
		InformationRegisters.CurrencyRates.GetLast(Date, New Structure("Currency", ContractByDefault.SettlementsCurrency))
	);
	
	StructureData.Insert(
		"CounterpartyPriceKind",
		ContractByDefault.CounterpartyPriceKind
	);
	
	StructureData.Insert(
		"SettlementsInStandardUnits",
		ContractByDefault.SettlementsInStandardUnits
	);
	
	StructureData.Insert(
		"AmountIncludesVAT",
		?(ValueIsFilled(ContractByDefault.CounterpartyPriceKind), ContractByDefault.CounterpartyPriceKind.PriceIncludesVAT, Undefined)
	);
	
	SetContractVisible();
	
	Return StructureData;
	
EndFunction // GetDataCounterpartyOnChange()

// It receives data set from server for the ContractOnChange procedure.
//
&AtServerNoContext
Function GetDataContractOnChange(Date, DocumentCurrency, Contract)
	
	StructureData = New Structure();
	
	StructureData.Insert(
	"SettlementsCurrency",
	Contract.SettlementsCurrency
	);
	
	StructureData.Insert(
	"SettlementsCurrencyRateRepetition",
	InformationRegisters.CurrencyRates.GetLast(Date, New Structure("Currency", Contract.SettlementsCurrency))
	);
	
	StructureData.Insert(
	"SettlementsInStandardUnits",
	Contract.SettlementsInStandardUnits
	);
	
	StructureData.Insert(
	"CounterpartyPriceKind",
	Contract.CounterpartyPriceKind
	);
	
	StructureData.Insert(
		"AmountIncludesVAT",
		?(ValueIsFilled(Contract.CounterpartyPriceKind), Contract.CounterpartyPriceKind.PriceIncludesVAT, Undefined)
	);
	
	Return StructureData;
	
EndFunction // GetDataContractOnChange()

// Procedure fills the VAT rate in the tabular section according to the taxation system.
// 
&AtServer
Procedure FillVATRateByVATTaxation()
	
	If Object.VATTaxation = Enums.VATTaxationTypes.TaxableByVAT Then
		
		Items.InventoryVATRate.Visible = True;
		Items.InventoryVATAmount.Visible = True;
		Items.InventoryAmountTotal.Visible = True;
		Items.PaymentCalendarPayVATAmount.Visible = True;
		Items.ListPaymentsCalendarSumVatOfPayment.Visible = True;
		
		For Each TabularSectionRow IN Object.Inventory Do
			
			If ValueIsFilled(TabularSectionRow.ProductsAndServices.VATRate) Then
				TabularSectionRow.VATRate = TabularSectionRow.ProductsAndServices.VATRate;
			Else
				TabularSectionRow.VATRate = Object.Company.DefaultVATRate;
			EndIf;	
			
			VATRate = SmallBusinessReUse.GetVATRateValue(TabularSectionRow.VATRate);
			TabularSectionRow.VATAmount = ?(Object.AmountIncludesVAT, 
									  		TabularSectionRow.Amount - (TabularSectionRow.Amount) / ((VATRate + 100) / 100),
									  		TabularSectionRow.Amount * VATRate / 100);
			TabularSectionRow.Total = TabularSectionRow.Amount + ?(Object.AmountIncludesVAT, 0, TabularSectionRow.VATAmount);
			
		EndDo;	
		
	Else
		
		Items.InventoryVATRate.Visible = False;
		Items.InventoryVATAmount.Visible = False;
		Items.InventoryAmountTotal.Visible = False;
		Items.PaymentCalendarPayVATAmount.Visible = False;
		Items.ListPaymentsCalendarSumVatOfPayment.Visible = False;

		If Object.VATTaxation = Enums.VATTaxationTypes.NotTaxableByVAT Then	
			DefaultVATRate = SmallBusinessReUse.GetVATRateWithoutVAT();
		Else
			DefaultVATRate = SmallBusinessReUse.GetVATRateZero();
		EndIf;	
		
		For Each TabularSectionRow IN Object.Inventory Do
		
			TabularSectionRow.VATRate = DefaultVATRate;
			TabularSectionRow.VATAmount = 0;
			
			TabularSectionRow.Total = TabularSectionRow.Amount;
			
		EndDo;	
		
	EndIf;	
	
EndProcedure // FillVATRateByVATTaxation()	

// VAT amount is calculated in the row of tabular section.
//
&AtClient
Procedure CalculateVATSUM(TabularSectionRow)
	
	VATRate = SmallBusinessReUse.GetVATRateValue(TabularSectionRow.VATRate);
	
	TabularSectionRow.VATAmount = ?(Object.AmountIncludesVAT, 
	TabularSectionRow.Amount - (TabularSectionRow.Amount) / ((VATRate + 100) / 100),
	TabularSectionRow.Amount * VATRate / 100);
	
EndProcedure // RecalculateDocumentAmounts() 

// Procedure calculates the amount in the row of tabular section.
//
&AtClient
Procedure CalculateAmountInTabularSectionLine(TabularSectionRow = Undefined)
	
	If TabularSectionRow = Undefined Then
		TabularSectionRow = Items.Inventory.CurrentData;
	EndIf;
	
	// Amount.
	TabularSectionRow.Amount = TabularSectionRow.Quantity * TabularSectionRow.Price;
	
	// VAT amount.
	CalculateVATSUM(TabularSectionRow);
	
	// Total.
	TabularSectionRow.Total = TabularSectionRow.Amount + ?(Object.AmountIncludesVAT, 0, TabularSectionRow.VATAmount);
	
EndProcedure // CalculateAmountInTabularSectionLine()	

// Procedure recalculates amounts in the payment calendar.
//
&AtClient
Procedure RecalculatePaymentCalendar()
	
	For Each CurRow IN Object.PaymentCalendar Do
		CurRow.PaymentAmount = Round(Object.Inventory.Total("Total") * CurRow.PaymentPercentage / 100, 2, 1);
		CurRow.PayVATAmount = Round(Object.Inventory.Total("VATAmount") * CurRow.PaymentPercentage / 100, 2, 1);
	EndDo;
	
EndProcedure // RecalculatePaymentCalendar()

// Procedure recalculates the rate and multiplicity of
// settlement currency when document date change.
//
&AtClient
Procedure RecalculateExchangeRateMultiplicitySettlementCurrency(StructureData)
	
	NewExchangeRate = ?(StructureData.CurrencyRateRepetition.ExchangeRate = 0, 1, StructureData.CurrencyRateRepetition.ExchangeRate);
	NewRatio = ?(StructureData.CurrencyRateRepetition.Multiplicity = 0, 1, StructureData.CurrencyRateRepetition.Multiplicity);
	
	If Object.ExchangeRate <> NewExchangeRate
		OR Object.Multiplicity <> NewRatio Then
		
		CurrencyRateInLetters = String(Object.Multiplicity) + " " + TrimAll(SettlementsCurrency) + " = " + String(Object.ExchangeRate) + " " + TrimAll(NationalCurrency);
		RateNewCurrenciesInLetters = String(NewRatio) + " " + TrimAll(SettlementsCurrency) + " = " + String(NewExchangeRate) + " " + TrimAll(NationalCurrency);
		
		MessageText = NStr("en = 'As of the date of document the settlement currency (" + CurrencyRateInLetters + ") exchange rate was specified.
									|Set the settlements rate (" + RateNewCurrenciesInLetters + ") according to exchange rate?'");
		
		Mode = QuestionDialogMode.YesNo;
		ShowQueryBox(New NotifyDescription("RecalculatePaymentCurrencyRateConversionFactorEnd", ThisObject, New Structure("NewRatio, NewExchangeRate", NewRatio, NewExchangeRate)), MessageText, Mode, 0);
		Return;
		
	EndIf;
	
	RecalculatePaymentCurrencyRateConversionFactorFragment();
	
EndProcedure

&AtClient
Procedure RecalculatePaymentCurrencyRateConversionFactorEnd(Result, AdditionalParameters) Export
	
	NewRatio = AdditionalParameters.NewRatio;
	NewExchangeRate = AdditionalParameters.NewExchangeRate;
	
	Response = Result;
	
	If Response = DialogReturnCode.Yes Then
		
		Object.ExchangeRate = NewExchangeRate;
		Object.Multiplicity = NewRatio;
		
	EndIf;
	
	RecalculatePaymentCurrencyRateConversionFactorFragment();
	
EndProcedure

&AtClient
Procedure RecalculatePaymentCurrencyRateConversionFactorFragment()
	
	LabelStructure = New Structure("DocumentCurrency, SettlementsCurrency, ExchangeRate, RateNationalCurrency, AmountIncludesVAT, CurrencyTransactionsAccounting, CounterpartyPriceKind, VATTaxation", Object.DocumentCurrency, SettlementsCurrency, Object.ExchangeRate, RateNationalCurrency, Object.AmountIncludesVAT, CurrencyTransactionsAccounting, Object.CounterpartyPriceKind, Object.VATTaxation);
	PricesAndCurrency = GenerateLabelPricesAndCurrency(LabelStructure);
	
EndProcedure // RecalculateRateAccountCurrencyRepetition()

// Procedure executes recalculate in the document tabular section
// after changes in "Prices and currency" form.Column recalculation is executed:
// price, discount, amount, VAT amount, total.
//
&AtClient
Procedure ProcessChangesOnButtonPricesAndCurrencies(Val SettlementsCurrencyBeforeChange, RecalculatePrices = False, RefillPrices = False, WarningText = "")
	
	// 1. Form parameter structure to fill the "Prices and Currency" form.
	ParametersStructure = New Structure;
	ParametersStructure.Insert("DocumentCurrency",		Object.DocumentCurrency);
	ParametersStructure.Insert("ExchangeRate",				Object.ExchangeRate);
	ParametersStructure.Insert("Multiplicity",			Object.Multiplicity);
	ParametersStructure.Insert("VATTaxation",	Object.VATTaxation);
	ParametersStructure.Insert("AmountIncludesVAT",	Object.AmountIncludesVAT);
	ParametersStructure.Insert("IncludeVATInPrice", Object.IncludeVATInPrice);
	ParametersStructure.Insert("Counterparty",			Object.Counterparty);
	ParametersStructure.Insert("Contract",				Object.Contract);
	ParametersStructure.Insert("Company",			Counterparty);
	ParametersStructure.Insert("DocumentDate",		Object.Date);
	ParametersStructure.Insert("RefillPrices",	RefillPrices);
	ParametersStructure.Insert("RecalculatePrices",		RecalculatePrices);
	ParametersStructure.Insert("WereMadeChanges",False);
	ParametersStructure.Insert("CounterpartyPriceKind", 	Object.CounterpartyPriceKind);
	ParametersStructure.Insert("WarningText",	WarningText);
	
	NotifyDescription = New NotifyDescription("ProcessChangesOnButtonPricesAndCurrenciesEnd", ThisObject, New Structure("SettlementsCurrencyBeforeChange", SettlementsCurrencyBeforeChange));
	OpenForm("CommonForm.PricesAndCurrencyForm", ParametersStructure, ThisForm, , , , NotifyDescription, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure // ProcessChangesByButtonPricesAndCurrencies()

// Function returns the label text "Prices and currency".
//
&AtClientAtServerNoContext
Function GenerateLabelPricesAndCurrency(LabelStructure)
	
	LabelText = "";
	
	// Currency.
	If LabelStructure.CurrencyTransactionsAccounting Then
		If ValueIsFilled(LabelStructure.DocumentCurrency) Then
			LabelText = "%Currency%";
			LabelText = StrReplace(LabelText, "%Currency%", TrimAll(String(LabelStructure.DocumentCurrency)));
		EndIf;
	EndIf;
		
	// Kind of counterparty prices.
	If ValueIsFilled(LabelStructure.CounterpartyPriceKind) Then
		If IsBlankString(LabelText) Then
			LabelText = LabelText + "%CounterpartyPriceKind%";
		Else
			LabelText = LabelText + " • %CounterpartyPriceKind%";
		EndIf;	
		LabelText = StrReplace(LabelText, "%CounterpartyPriceKind%", TrimAll(String(LabelStructure.CounterpartyPriceKind)));
	EndIf;
	
	If SmallBusinessServer.GetFunctionalOptionValue("UseVAT") Then
		
		// VAT taxation.
		If ValueIsFilled(LabelStructure.VATTaxation) Then
			If IsBlankString(LabelText) Then
				LabelText = LabelText + "%VATTaxation%";
			Else
				LabelText = LabelText + " • %VATTaxation%";
			EndIf;	
			LabelText = StrReplace(LabelText, "%VATTaxation%", TrimAll(String(LabelStructure.VATTaxation)));
		EndIf;
		
		// Flag showing that amount includes VAT.
		If IsBlankString(LabelText) Then	
			If LabelStructure.AmountIncludesVAT Then	
				LabelText = NStr("en='Amount includes VAT';ru='Сумма включает НДС';vi='Số tiền gồm thuế GTGT'");
			Else		
				LabelText = NStr("en='Amount does not include VAT';ru='Сумма не включает НДС';vi='Số tiền không gồm thuế GTGT'");
			EndIf;	
		EndIf;	
	
	EndIf;	

	Return LabelText;
	
EndFunction // GenerateLabelPricesAndCurrency()

// Procedure calls the data processor for document filling by basis.
//
&AtServer
Procedure FillByDocument()
	
	Document = FormAttributeToValue("Object");
	Document.Filling(Object.CustomerOrder, );
	ValueToFormAttribute(Document, "Object");
	Modified = True;	
	
	If Object.VATTaxation = Enums.VATTaxationTypes.TaxableByVAT Then	
		Items.InventoryVATRate.Visible = True;
		Items.InventoryVATAmount.Visible = True;
		Items.InventoryAmountTotal.Visible = True;
		Items.PaymentCalendarPayVATAmount.Visible = True;
		Items.ListPaymentsCalendarSumVatOfPayment.Visible = True;

	Else	
		Items.InventoryVATRate.Visible = False;
		Items.InventoryVATAmount.Visible = False;
		Items.InventoryAmountTotal.Visible = False;
		Items.PaymentCalendarPayVATAmount.Visible = False;
		Items.ListPaymentsCalendarSumVatOfPayment.Visible = False;
	EndIf;
	
	SetContractVisible();
	
EndProcedure // FillByDocument()

// Peripherals
// Procedure gets data by barcodes.
//
&AtServerNoContext
Procedure GetDataByBarCodes(StructureData)
	
	// Transform weight barcodes.
	For Each CurBarcode IN StructureData.BarcodesArray Do
		
		InformationRegisters.ProductsAndServicesBarcodes.ConvertWeightBarcode(CurBarcode);
		
	EndDo;
	
	DataByBarCodes = InformationRegisters.ProductsAndServicesBarcodes.GetDataByBarCodes(StructureData.BarcodesArray);
	
	For Each CurBarcode IN StructureData.BarcodesArray Do
		
		BarcodeData = DataByBarCodes[CurBarcode.Barcode];
		
		If BarcodeData <> Undefined
		   AND BarcodeData.Count() <> 0 Then
			
			StructureProductsAndServicesData = New Structure();
			StructureProductsAndServicesData.Insert("Company", StructureData.Company);
			StructureProductsAndServicesData.Insert("ProductsAndServices", BarcodeData.ProductsAndServices);
			StructureProductsAndServicesData.Insert("Characteristic", BarcodeData.Characteristic);
			StructureProductsAndServicesData.Insert("VATTaxation", StructureData.VATTaxation);
			If ValueIsFilled(StructureData.CounterpartyPriceKind) Then
				StructureProductsAndServicesData.Insert("ProcessingDate", StructureData.Date);
				StructureProductsAndServicesData.Insert("DocumentCurrency", StructureData.DocumentCurrency);
				StructureProductsAndServicesData.Insert("AmountIncludesVAT", StructureData.AmountIncludesVAT);
				StructureProductsAndServicesData.Insert("CounterpartyPriceKind", StructureData.CounterpartyPriceKind);
				If ValueIsFilled(BarcodeData.MeasurementUnit)
					AND TypeOf(BarcodeData.MeasurementUnit) = Type("CatalogRef.UOM") Then
					StructureProductsAndServicesData.Insert("Factor", BarcodeData.MeasurementUnit.Factor);
				Else
					StructureProductsAndServicesData.Insert("Factor", 1);
				EndIf;
			EndIf;
			BarcodeData.Insert("StructureProductsAndServicesData", GetDataProductsAndServicesOnChange(StructureProductsAndServicesData));
			
			If Not ValueIsFilled(BarcodeData.MeasurementUnit) Then
				BarcodeData.MeasurementUnit  = BarcodeData.ProductsAndServices.MeasurementUnit;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	StructureData.Insert("DataByBarCodes", DataByBarCodes);
	
EndProcedure // GetDataByBarCodes()

&AtClient
Function FillByBarcodesData(BarcodesData)
	
	UnknownBarcodes = New Array;
	
	If TypeOf(BarcodesData) = Type("Array") Then
		BarcodesArray = BarcodesData;
	Else
		BarcodesArray = New Array;
		BarcodesArray.Add(BarcodesData);
	EndIf;
	
	StructureData = New Structure();
	StructureData.Insert("BarcodesArray", BarcodesArray);
	StructureData.Insert("Company", Object.Company);
	StructureData.Insert("CounterpartyPriceKind", Object.CounterpartyPriceKind);
	StructureData.Insert("Date", Object.Date);
	StructureData.Insert("DocumentCurrency", Object.DocumentCurrency);
	StructureData.Insert("AmountIncludesVAT", Object.AmountIncludesVAT);
	StructureData.Insert("VATTaxation", Object.VATTaxation);
	
	GetDataByBarCodes(StructureData);
	
	For Each CurBarcode IN StructureData.BarcodesArray Do
		BarcodeData = StructureData.DataByBarCodes[CurBarcode.Barcode];
		
		If BarcodeData <> Undefined
		   AND BarcodeData.Count() = 0 Then
			UnknownBarcodes.Add(CurBarcode);
		Else
			TSRowsArray = Object.Inventory.FindRows(New Structure("ProductsAndServices,Characteristic,MeasurementUnit",BarcodeData.ProductsAndServices,BarcodeData.Characteristic,BarcodeData.MeasurementUnit));
			If TSRowsArray.Count() = 0 Then
				NewRow = Object.Inventory.Add();
				NewRow.ProductsAndServices = BarcodeData.ProductsAndServices;
				NewRow.Characteristic = BarcodeData.Characteristic;
				NewRow.Quantity = CurBarcode.Quantity;
				NewRow.MeasurementUnit = ?(ValueIsFilled(BarcodeData.MeasurementUnit), BarcodeData.MeasurementUnit, BarcodeData.StructureProductsAndServicesData.MeasurementUnit);
				NewRow.Price = BarcodeData.StructureProductsAndServicesData.Price;
				NewRow.VATRate = BarcodeData.StructureProductsAndServicesData.VATRate;
				CalculateAmountInTabularSectionLine(NewRow);
				Items.Inventory.CurrentRow = NewRow.GetID();
			Else
				FoundString = TSRowsArray[0];
				FoundString.Quantity = FoundString.Quantity + CurBarcode.Quantity;
				CalculateAmountInTabularSectionLine(FoundString);
				Items.Inventory.CurrentRow = FoundString.GetID();
			EndIf;
		EndIf;
	EndDo;
	
	Return UnknownBarcodes;
	
EndFunction // FillByBarcodesData()

// Procedure processes the received barcodes.
//
&AtClient
Procedure BarcodesReceived(BarcodesData)
	
	Modified = True;
	
	UnknownBarcodes = FillByBarcodesData(BarcodesData);
	
	ReturnParameters = Undefined;
	
	If UnknownBarcodes.Count() > 0 Then
		
		Notification = New NotifyDescription("BarcodesAreReceivedEnd", ThisForm, UnknownBarcodes);
		
		OpenForm(
			"InformationRegister.ProductsAndServicesBarcodes.Form.ProductsAndServicesBarcodesRegistration",
			New Structure("UnknownBarcodes", UnknownBarcodes), ThisForm,,,,Notification
		);
		
		Return;
		
	EndIf;
	
	BarcodesAreReceivedFragment(UnknownBarcodes);
	
EndProcedure // BarcodesAreReceived()

&AtClient
Procedure BarcodesAreReceivedEnd(ReturnParameters, Parameters) Export
	
	UnknownBarcodes = Parameters;
	
	If ReturnParameters <> Undefined Then
		
		BarcodesArray = New Array;
		
		For Each ArrayElement IN ReturnParameters.RegisteredBarcodes Do
			BarcodesArray.Add(ArrayElement);
		EndDo;
		
		For Each ArrayElement IN ReturnParameters.ReceivedNewBarcodes Do
			BarcodesArray.Add(ArrayElement);
		EndDo;
		
		UnknownBarcodes = FillByBarcodesData(BarcodesArray);
		
	EndIf;
	
	BarcodesAreReceivedFragment(UnknownBarcodes);
	
EndProcedure

&AtClient
Procedure BarcodesAreReceivedFragment(UnknownBarcodes) Export
	
	For Each CurUndefinedBarcode IN UnknownBarcodes Do
		
		MessageString = NStr("en='Barcode data is not found: %1%; quantity: %2%';ru='Данные по штрихкоду не найдены: %1%; количество: %2%';vi='Không tìm thấy dữ liệu về mã vạch: %1%; số lượng: %2%'");
		MessageString = StrReplace(MessageString, "%1%", CurUndefinedBarcode.Barcode);
		MessageString = StrReplace(MessageString, "%2%", CurUndefinedBarcode.Quantity);
		CommonUseClientServer.MessageToUser(MessageString);
		
	EndDo;
	
EndProcedure

// End Peripherals

// It receives the data set from the server for the OrderStateOnChange procedure.
//
&AtServerNoContext
Function GetDataOrderStateOnChange(OrderState)
	
	If ValueIsFilled(OrderState) Then
		Return String(OrderState.OrderStatus);
	Else
		Return "";
	EndIf;
	
EndFunction // GetDataMeasurementUnitOnChange()

// Procedure fills the column Reserve by free balances on stock.
//
&AtServer
Procedure FillColumnReserveByBalancesAtServer()
	
	Document = FormAttributeToValue("Object");
	Document.FillColumnReserveByBalances();
	ValueToFormAttribute(Document, "Object");
	
EndProcedure // FillColumnReserveByBalancesAtServer()

// Checks the match of the "Company" and "ContractKind" contract attributes to the terms of the document.
//
&AtServerNoContext
Procedure CheckContractToDocumentConditionAccordance(MessageText, Contract, Document, Company, Counterparty, OperationKind, Cancel)
	
	If Not SmallBusinessReUse.CounterpartyContractsControlNeeded()
		OR Not Counterparty.DoOperationsByContracts Then
		
		Return;
	EndIf;
	
	ManagerOfCatalog = Catalogs.CounterpartyContracts;
	ContractKindsList = ManagerOfCatalog.GetContractKindsListForDocument(Document, OperationKind);
	
	If Not ManagerOfCatalog.ContractMeetsDocumentTerms(MessageText, Contract, Company, Counterparty, ContractKindsList)
		AND Constants.DoNotPostDocumentsWithIncorrectContracts.Get() Then
		
		Cancel = True;
	EndIf;
	
EndProcedure

// It gets counterparty contract selection form parameter structure.
//
&AtServerNoContext
Function GetChoiceFormOfContractParameters(Document, Company, Counterparty, Contract, OperationKind)
	
	ContractTypesList = Catalogs.CounterpartyContracts.GetContractKindsListForDocument(Document, OperationKind);
	
	FormParameters = New Structure;
	FormParameters.Insert("ControlContractChoice", Counterparty.DoOperationsByContracts);
	FormParameters.Insert("Counterparty", Counterparty);
	FormParameters.Insert("Company", Company);
	FormParameters.Insert("ContractKinds", ContractTypesList);
	FormParameters.Insert("CurrentRow", Contract);
	
	Return FormParameters;
	
EndFunction

// Gets the banking account selection form parameter structure.
//
&AtServerNoContext
Function GetChoiceFormParametersBankAccount(Contract, Company, NationalCurrency)
	
	AttributesContract = CommonUse.ObjectAttributesValues(Contract, "SettlementsCurrency, SettlementsInStandardUnits");
	
	CurrenciesList = New ValueList;
	CurrenciesList.Add(AttributesContract.SettlementsCurrency);
	CurrenciesList.Add(NationalCurrency);
	
	FormParameters = New Structure;
	FormParameters.Insert("SettlementsInStandardUnits", AttributesContract.SettlementsInStandardUnits);
	FormParameters.Insert("Owner", Company);
	FormParameters.Insert("CurrenciesList", CurrenciesList);
	
	Return FormParameters;
	
EndFunction

// Gets the default contract depending on the settlements method.
//
&AtServerNoContext
Function GetContractByDefault(Document, Counterparty, Company, OperationKind)
	
	If Not Counterparty.DoOperationsByContracts Then
		Return Counterparty.ContractByDefault;
	EndIf;
	
	ManagerOfCatalog = Catalogs.CounterpartyContracts;
	
	ContractTypesList = ManagerOfCatalog.GetContractKindsListForDocument(Document, OperationKind);
	ContractByDefault = ManagerOfCatalog.GetDefaultContractByCompanyContractKind(Counterparty, Company, ContractTypesList);
	
	Return ContractByDefault;
	
EndFunction

// Performs actions when the operation kind changes.
//
&AtServer
Procedure ProcessOperationKindChange()
	
	SetVisibleAndEnabled();
	Object.Materials.Clear();
	
	Object.Contract = GetContractByDefault(Object.Ref, Object.Counterparty, Object.Company, Object.OperationKind);
	
EndProcedure

// Performs actions when counterparty contract is changed.
//
&AtClient
Procedure ProcessContractChange(ContractData = Undefined)
	
	ContractBeforeChange = Contract;
	Contract = Object.Contract;
	
	If ContractBeforeChange <> Object.Contract Then
		
		If ContractData = Undefined Then
			
			ContractData = GetDataContractOnChange(Object.Date, Object.DocumentCurrency, Object.Contract);
			
		EndIf;
		
		PriceKindChanged = Object.CounterpartyPriceKind <> ContractData.CounterpartyPriceKind;
		QueryPriceKind = ValueIsFilled(Object.Contract) AND PriceKindChanged;
		
		SettlementsCurrencyBeforeChange = SettlementsCurrency;
		SettlementsCurrency = ContractData.SettlementsCurrency;
		
		NewContractAndCalculationCurrency = ValueIsFilled(Object.Contract) AND ValueIsFilled(SettlementsCurrency) 
			AND Object.Contract <> ContractBeforeChange AND SettlementsCurrencyBeforeChange <> ContractData.SettlementsCurrency;
		OpenFormPricesAndCurrencies = NewContractAndCalculationCurrency AND Object.DocumentCurrency <> ContractData.SettlementsCurrency
			AND Object.Inventory.Count() > 0;
		
		DocumentParameters = New Structure;
		DocumentParameters.Insert("ContractBeforeChange", ContractBeforeChange);
		DocumentParameters.Insert("SettlementsCurrencyBeforeChange", SettlementsCurrencyBeforeChange);
		DocumentParameters.Insert("ContractData", ContractData);
		DocumentParameters.Insert("QueryPriceKind", QueryPriceKind);
		DocumentParameters.Insert("OpenFormPricesAndCurrencies", OpenFormPricesAndCurrencies);
		DocumentParameters.Insert("PriceKindChanged", PriceKindChanged);
		DocumentParameters.Insert("RecalculationRequired", Object.Inventory.Count() > 0);
		
		ProcessPricesKindAndSettlementsCurrencyChange(DocumentParameters);
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// PROCEDURES FOR WORK WITH THE SELECTION

// Procedure - event handler Action of the Pick command
//
&AtClient
Procedure InventoryPick(Command)
	
	TabularSectionName 	= "Inventory";
	
	If Not IsBlankString(SelectionOpenParameters[TabularSectionName]) Then
		
		PickProductsAndServicesInDocumentsClient.OpenPick(ThisForm, TabularSectionName, SelectionOpenParameters[TabularSectionName]);
		Return;
		
	EndIf;
	
	SelectionParameters = New Structure;
	
	SelectionParameters.Insert("Period", 				Object.Date);
	SelectionParameters.Insert("Company", 			Counterparty);
	SelectionParameters.Insert("VATTaxation",		Object.VATTaxation);
	
	SelectionParameters.Insert("AmountIncludesVAT", 		Object.AmountIncludesVAT);
	SelectionParameters.Insert("DocumentOrganization",	Object.Company);
	SelectionParameters.Insert("CounterpartyPriceKind",		Object.CounterpartyPriceKind);
	SelectionParameters.Insert("Currency", 				Object.DocumentCurrency);
	SelectionParameters.Insert("ThisIsReceiptDocument", 	True);
	
	ProductsAndServicesType = New ValueList;
	For Each ArrayElement IN Items[TabularSectionName + "ProductsAndServices"].ChoiceParameters Do
		If ArrayElement.Name = "Filter.ProductsAndServicesType" Then
			If TypeOf(ArrayElement.Value) = Type("FixedArray") Then
				For Each FixArrayItem IN ArrayElement.Value Do
					ProductsAndServicesType.Add(FixArrayItem);
				EndDo; 
			Else
				ProductsAndServicesType.Add(ArrayElement.Value);
			EndIf;
		EndIf;
	EndDo;
	
	SelectionParameters.Insert("ProductsAndServicesType", ProductsAndServicesType);
	
	SelectionParameters.Insert("OwnerFormUUID", UUID);
	
	OpenForm("CommonForm.PickForm", SelectionParameters, ThisForm);
	
EndProcedure // ExecutePick()

// Procedure - event handler Action of the Pick command
//
&AtClient
Procedure MaterialsPick(Command)
	
	TabularSectionName 	= "Materials";
	
	SelectionParameters = New Structure;
	
	SelectionParameters.Insert("Period", 					Object.Date);
	SelectionParameters.Insert("Company", 				Counterparty);
	SelectionParameters.Insert("ReservationUsed",	True);
	
	ProductsAndServicesType = New ValueList;
	For Each ArrayElement IN Items[TabularSectionName + "ProductsAndServices"].ChoiceParameters Do
		If ArrayElement.Name = "Filter.ProductsAndServicesType" Then
			If TypeOf(ArrayElement.Value) = Type("FixedArray") Then
				For Each FixArrayItem IN ArrayElement.Value Do
					ProductsAndServicesType.Add(FixArrayItem);
				EndDo; 
			Else
				ProductsAndServicesType.Add(ArrayElement.Value);
			EndIf;
		EndIf;
	EndDo;
	
	SelectionParameters.Insert("ProductsAndServicesType", ProductsAndServicesType);
	
	SelectionParameters.Insert("OwnerFormUUID", UUID);
	
	OpenForm("CommonForm.PickForm", SelectionParameters, ThisForm);
	
EndProcedure // ExecutePick()

// Function gets a product list from the temporary storage
//
&AtServer
Procedure GetInventoryFromStorage(InventoryAddressInStorage, TabularSectionName, AreCharacteristics, AreBatches)
	
	TableForImport = GetFromTempStorage(InventoryAddressInStorage);
	
	For Each ImportRow IN TableForImport Do
		
		NewRow = Object[TabularSectionName].Add();
		FillPropertyValues(NewRow, ImportRow);
		
	EndDo;
	
EndProcedure // GetInventoryFromStorage()

////////////////////////////////////////////////////////////////////////////////
// PROCEDURES AND FUNCTIONS FOR CONTROL OF THE FORM APPEARANCE

// Procedure sets availability of the form items.
//
// Parameters:
//  No.
//
&AtServer
Procedure SetVisibleAndEnabled()
	
	If Object.OrderState.OrderStatus = Enums.OrderStatuses.Open Then
		
		Items.SchedulePayment.Enabled = False;
		Object.SchedulePayment = False;
		If Object.PaymentCalendar.Count() > 0 Then
			Object.PaymentCalendar.Clear();
		EndIf;
		
	EndIf;
	
	If Object.OperationKind = PredefinedValue("Enum.OperationKindsPurchaseOrder.OrderForPurchase")
		AND Not Object.SchedulePayment Then
		
		Items.GroupPaymentsCalendar.Visible = False;
		Items.GroupMaterials.Visible = False;
		
	ElsIf Object.OperationKind = PredefinedValue("Enum.OperationKindsPurchaseOrder.OrderForPurchase")
		AND Object.SchedulePayment Then
		
		Items.GroupPaymentsCalendar.Visible = True;
		Items.GroupMaterials.Visible = False;
	
	ElsIf Object.OperationKind = PredefinedValue("Enum.OperationKindsPurchaseOrder.OrderForProcessing")
		AND Not Object.SchedulePayment Then
		
		Items.GroupPaymentsCalendar.Visible = False;
		Items.GroupMaterials.Visible = True;
		
	ElsIf Object.OperationKind = PredefinedValue("Enum.OperationKindsPurchaseOrder.OrderForProcessing")
		AND Object.SchedulePayment Then
		
		Items.GroupPaymentsCalendar.Visible = True;
		Items.GroupMaterials.Visible = True;
		
	EndIf;
	
	// ProductsAndServices.
	If Object.OperationKind = PredefinedValue("Enum.OperationKindsPurchaseOrder.OrderForPurchase") Then
		NewArray = New Array();
		NewArray.Add(Enums.ProductsAndServicesTypes.InventoryItem);
		NewArray.Add(Enums.ProductsAndServicesTypes.Service);
		ArrayInventoryAndExpenses = New FixedArray(NewArray);
		NewParameter = New ChoiceParameter("Filter.ProductsAndServicesType", ArrayInventoryAndExpenses);
		NewParameter2 = New ChoiceParameter("Additionally.TypeRestriction", ArrayInventoryAndExpenses);
		NewArray = New Array();
		NewArray.Add(NewParameter);
		NewArray.Add(NewParameter2);
		NewParameters = New FixedArray(NewArray);
		Items.Inventory.ChildItems.InventoryProductsAndServices.ChoiceParameters = NewParameters;
		
		Items.GroupInventory.Title = NStr("en='Products and services'; ru = 'Товары и услуги'; vi = 'Hàng hóa và dịch vụ'");
		
	Else
		NewParameter = New ChoiceParameter("Filter.ProductsAndServicesType", Enums.ProductsAndServicesTypes.InventoryItem);
		NewArray = New Array();
		NewArray.Add(NewParameter);
		NewParameters = New FixedArray(NewArray);
		Items.Inventory.ChildItems.InventoryProductsAndServices.ChoiceParameters = NewParameters;
		
		Items.GroupInventory.Title = NStr("en='Products'; ru = 'Товары'; vi = 'Hàng hóa'");
		
		For Each StringInventory IN Object.Inventory Do
			If StringInventory.ProductsAndServices.ProductsAndServicesType = Enums.ProductsAndServicesTypes.Service Then
				StringInventory.ProductsAndServices = Undefined;
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure // SetVisibleAndEnabled()

// Procedure sets the form item visible.
//
// Parameters:
//  No.
//
&AtServer
Procedure SetVisibleFromUserSettings()	
	
	If Object.ReceiptDatePosition = Enums.AttributePositionOnForm.InHeader Then
		Items.ReceiptDate.Visible = True;
		Items.InventoryReceiptDate.Visible = False;	
	Else
		Items.ReceiptDate.Visible = False;
		Items.InventoryReceiptDate.Visible = True;
	EndIf;	
	
EndProcedure // SetVisibleFromUserSettings()

// The procedure forms the operation kind structure.
//
&AtServer
Procedure GetOperationKindsStructure()
	
	If Constants.FunctionalOptionTransferRawMaterialsForProcessing.Get() Then
		
		Items.OperationKind.ChoiceList.Add(Enums.OperationKindsPurchaseOrder.OrderForProcessing);
		
	EndIf;
	
EndProcedure // GetOperationKindMatching()

// Procedure - Set edit by list option.
//
&AtClient
Procedure SetEditInListOption()
	
	Items.EditInList.Check = Not Items.EditInList.Check;
	
	LineCount = Object.PaymentCalendar.Count();
	
	If Not Items.EditInList.Check
		  AND Object.PaymentCalendar.Count() > 1 Then
		
		Response = Undefined;
		ShowQueryBox(New NotifyDescription("SetEditInListEndOption", ThisObject, New Structure("LineCount", LineCount)), 
			NStr("en='All lines except for the first one will be deleted. Continue?';ru='Все строки кроме первой будут удалены. Продолжить?';vi='Tất cả các dòng trừ dòng đầu tiên sẽ bị xóa. Tiếp tục?'"),
			QuestionDialogMode.YesNo
		);
		Return;
	EndIf;
	
	SetEditInListFragmentOption();
	
EndProcedure

&AtClient
Procedure SetEditInListEndOption(Result, AdditionalParameters) Export
	
	LineCount = AdditionalParameters.LineCount;
	
	
	Response = Result;
	
	If Response = DialogReturnCode.No Then
		Items.EditInList.Check = True;
		Return;
	EndIf;
	
	While LineCount > 1 Do
		Object.PaymentCalendar.Delete(Object.PaymentCalendar[LineCount - 1]);
		LineCount = LineCount - 1;
	EndDo;
	Items.PaymentCalendar.CurrentRow = Object.PaymentCalendar[0].GetID();
	
	SetEditInListFragmentOption();

EndProcedure

&AtClient
Procedure SetEditInListFragmentOption()
	
	If Items.EditInList.Check Then
		Items.GroupPaymentCalendarListString.CurrentPage = Items.GroupPaymentCalendarList;
	Else
		Items.GroupPaymentCalendarListString.CurrentPage = Items.GroupBillingCalendarString;
	EndIf;

EndProcedure // SetEditByListOption()

// Sets the current page for document operation kind.
//
// Parameters:
// BusinessOperation - EnumRef.EconomicOperations - Economic operations
//
&AtClient
Procedure SetCurrentPage()
	
	PageName = "";
	
	If Object.CashAssetsType = PredefinedValue("Enum.CashAssetTypes.Noncash") Then
		PageName = "PageBankAccount";
	ElsIf Object.CashAssetsType = PredefinedValue("Enum.CashAssetTypes.Cash") Then
		PageName = "PagePettyCash";
	EndIf;  

	PageItem = Items.Find(PageName);
	If PageItem <> Undefined Then
		Items.CashboxBankAccount.Visible = True;
		Items.CashboxBankAccount.CurrentPage = PageItem;
	Else
		Items.CashboxBankAccount.Visible = False;
	EndIf;
	
EndProcedure // SetCurrentPage()

////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - FORM EVENT HANDLERS

&AtClient
Procedure AddAdditionalAttribute(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("CurrentSetOfProperties", PredefinedValue("Catalog.AdditionalAttributesAndInformationSets.Document_PurchaseOrder"));
	FormParameters.Insert("ThisIsAdditionalInformation", False);
	
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInformation.ObjectForm", FormParameters,,,,,,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Procedure - OnCreateAtServer event handler.
//
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SmallBusinessServer.FillDocumentHeader(
		Object,
		,
		Parameters.CopyingValue,
		Parameters.Basis,
		PostingIsAllowed,
		Parameters.FillingValues
	);
	
	If Not ValueIsFilled(Object.Ref)
		  AND ValueIsFilled(Object.Counterparty)
		  AND Not ValueIsFilled(Parameters.CopyingValue) Then
		If Not ValueIsFilled(Object.Contract) Then
			Object.Contract = Object.Counterparty.ContractByDefault;
		EndIf;
		If ValueIsFilled(Object.Contract) Then
			Object.DocumentCurrency = Object.Contract.SettlementsCurrency;
			SettlementsCurrencyRateRepetition = InformationRegisters.CurrencyRates.GetLast(Object.Date, New Structure("Currency", Object.Contract.SettlementsCurrency));
			Object.ExchangeRate	  = ?(SettlementsCurrencyRateRepetition.ExchangeRate = 0, 1, SettlementsCurrencyRateRepetition.ExchangeRate);
			Object.Multiplicity = ?(SettlementsCurrencyRateRepetition.Multiplicity = 0, 1, SettlementsCurrencyRateRepetition.Multiplicity);
			If Not ValueIsFilled(Object.CounterpartyPriceKind) Then
				Object.CounterpartyPriceKind = Object.Contract.CounterpartyPriceKind;
			EndIf;
		EndIf;
	EndIf;
	
	// Form attributes setting.
	DocumentDate = Object.Date;
	If Not ValueIsFilled(DocumentDate) Then
		DocumentDate = CurrentDate();
	EndIf;
	
	SubsidiaryCompany = SmallBusinessServer.GetCompany(Object.Company);
	Counterparty = Object.Counterparty;
	Contract = Object.Contract;
	SettlementsCurrency = Object.Contract.SettlementsCurrency;
	NationalCurrency = Constants.NationalCurrency.Get();
	StructureByCurrency = InformationRegisters.CurrencyRates.GetLast(Object.Date, New Structure("Currency", NationalCurrency));
	RateNationalCurrency = StructureByCurrency.ExchangeRate;
	RepetitionNationalCurrency = StructureByCurrency.Multiplicity;
	
	If Not Constants.UsePurchaseOrderStates.Get() Then
		
		Items.StateGroup.Visible = False;
		
		InProcessStatus = Constants.PurchaseOrdersInProgressStatus.Get();
		CompletedStatus = Constants.PurchaseOrdersCompletedStatus.Get();
		
		Items.Status.ChoiceList.Add("InProcess", NStr("en='In process';ru='В работе';vi='Đang xử lý'"));
		Items.Status.ChoiceList.Add("Completed", NStr("en='Completed';ru='Выполнен';vi='Đã thực hiện'"));
		Items.Status.ChoiceList.Add("Canceled", NStr("en='Canceled';ru='Отменен';vi='Đã hủy'"));
		
		If Object.OrderState.OrderStatus = Enums.OrderStatuses.InProcess AND Not Object.Closed Then
			Status = "InProcess";
		ElsIf Object.OrderState.OrderStatus = Enums.OrderStatuses.Completed Then
			Status = "Completed";
		Else
			Status = "Canceled";
		EndIf;
		
	Else
		
		Items.GroupStatuses.Visible = False;
		
	EndIf;
	
	GetOperationKindsStructure();
	
	//Object.IncludeVATInPrice = True;
		
	If Not ValueIsFilled(Object.Ref)
	   AND Not ValueIsFilled(Parameters.CopyingValue) Then
		
		Query = New Query(
		"SELECT ALLOWED
		|	CASE
		|		WHEN Companies.BankAccountByDefault.CashCurrency = &CashCurrency
		|			THEN Companies.BankAccountByDefault
		|		ELSE UNDEFINED
		|	END AS BankAccount
		|FROM
		|	Catalog.Companies AS Companies
		|WHERE
		|	Companies.Ref = &Company");
		Query.SetParameter("Company", Object.Company);
		Query.SetParameter("CashCurrency", Object.DocumentCurrency);
		QueryResult = Query.Execute();
		Selection = QueryResult.Select();
		If Selection.Next() Then
			Object.BankAccount = Selection.BankAccount;
		EndIf;
		Object.PettyCash = Catalogs.PettyCashes.GetPettyCashByDefault(Object.Company);
		
	EndIf;
	
	If Not ValueIsFilled(Object.Ref)
		AND Not ValueIsFilled(Parameters.Basis)
		AND Not ValueIsFilled(Parameters.CopyingValue) Then
		FillVATRateByVATTaxation();
	ElsIf Object.VATTaxation = Enums.VATTaxationTypes.TaxableByVAT Then
		Items.InventoryVATRate.Visible = True;
		Items.InventoryVATAmount.Visible = True;
		Items.InventoryAmountTotal.Visible = True;
		Items.PaymentCalendarPayVATAmount.Visible = True;
		Items.ListPaymentsCalendarSumVatOfPayment.Visible = True;
	Else
		Items.InventoryVATRate.Visible = False;
		Items.InventoryVATAmount.Visible = False;
		Items.InventoryAmountTotal.Visible = False;
		Items.PaymentCalendarPayVATAmount.Visible = False;
		Items.ListPaymentsCalendarSumVatOfPayment.Visible = False;
	EndIf;
	
	// Generate price and currency label.
	CurrencyTransactionsAccounting = Constants.FunctionalCurrencyTransactionsAccounting.Get();
	LabelStructure = New Structure("DocumentCurrency, SettlementsCurrency, ExchangeRate, RateNationalCurrency, AmountIncludesVAT, CurrencyTransactionsAccounting, CounterpartyPriceKind, VATTaxation", Object.DocumentCurrency, SettlementsCurrency, Object.ExchangeRate, RateNationalCurrency, Object.AmountIncludesVAT, CurrencyTransactionsAccounting, Object.CounterpartyPriceKind, Object.VATTaxation);
	PricesAndCurrency = GenerateLabelPricesAndCurrency(LabelStructure); 
	
	SetVisibleAndEnabled();
	
	// Attribute visible set from user settings
	SetVisibleFromUserSettings(); 
	
	If ValueIsFilled(Object.Ref) Then
		NotifyWorkCalendar = False;
	Else
		NotifyWorkCalendar = True;
	EndIf; 
	DocumentModified = False;
	
	// If the document is opened from pick, fill the tabular section products
	If Parameters.FillingValues.Property("InventoryAddressInStorage") 
		AND ValueIsFilled(Parameters.FillingValues.InventoryAddressInStorage) Then
		
		GetInventoryFromStorage(Parameters.FillingValues.InventoryAddressInStorage, 
							Parameters.FillingValues.TabularSectionName,
							Parameters.FillingValues.AreCharacteristics,
							Parameters.FillingValues.AreBatches);
		
	EndIf;
	
	// Setting contract visible.
	SetContractVisible();
	
	// PickProductsAndServicesInDocuments
	PickProductsAndServicesInDocuments.AssignPickForm(SelectionOpenParameters, Object.Ref.Metadata().Name, "Inventory");
	// End PickProductsAndServicesInDocuments
	
	// StandardSubsystems.ObjectVersioning
	ObjectVersioning.OnCreateAtServer(ThisForm);
	// End StandardSubsystems.ObjectVersioning
	
	// StandardSubsystems.AdditionalReportsAndDataProcessors
	AdditionalReportsAndDataProcessors.OnCreateAtServer(ThisForm);
	// End StandardSubsystems.AdditionalReportsAndDataProcessors
	
	// StandardSubsystems.DataImportFromExternalSources
	DataImportFromExternalSources.OnCreateAtServer(Metadata.Documents.PurchaseOrder.TabularSections.Inventory, DataLoadSettings, ThisObject);
	// End StandardSubsystems.DataImportFromExternalSource
	
	// StandardSubsystems.Printing
	PrintManagement.OnCreateAtServer(ThisForm, Items.ImportantCommandsGroup);
	// End StandardSubsystems.Printing
	
	// StandardSubsystems.Properties
	AdditionalParameters = PropertiesManagementOverridable.FillAdditionalParameters(Object, "AdditionalAttributesGroup");
	PropertiesManagement.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// Peripherals
	UsePeripherals = SmallBusinessReUse.UsePeripherals();
	ListOfElectronicScales = EquipmentManagerServerCall.GetEquipmentList("ElectronicScales", , EquipmentManagerServerCall.GetClientWorkplace());
	If ListOfElectronicScales.Count() = 0 Then
		// There are no connected scales.
		Items.InventoryGetWeight.Visible = False;
	EndIf;
	Items.InventoryImportDataFromDCT.Visible = UsePeripherals;
	// End Peripherals
	
EndProcedure // OnCreateAtServer()

// Procedure - OnReadAtServer event handler.
//
&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	ChangeProhibitionDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.Properties
	PropertiesManagement.OnReadAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.Properties
	
EndProcedure // OnReadAtServer()

// Procedure - event handler AfterWriting.
//
&AtClient
Procedure AfterWrite(WriteParameters)
	
	If DocumentModified Then
		NotifyWorkCalendar = True;
		DocumentModified = False;
	EndIf;
	
EndProcedure // AfterWrite()

&AtServer
// Procedure-handler of the OnCreateAtServer event.
// Performs initial attributes forms filling.
//
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		
		MessageText = "";
		CheckContractToDocumentConditionAccordance(MessageText, Object.Contract, Object.Ref, Object.Company, Object.Counterparty, Object.OperationKind, Cancel);
		
		If MessageText <> "" Then
			
			Message = New UserMessage;
			Message.Text = ?(Cancel, NStr("en='Document is not posted! ';ru='Документ не проведен! ';vi='Chứng từ chưa được kết chuyển!'") + MessageText, MessageText);
			
			If Cancel Then
				Message.DataPath = "Object";
				Message.Field = "Contract";
			EndIf;
			Message.Message();
			
		EndIf;
		
	EndIf;
	
	// "Properties" mechanism handler
	PropertiesManagement.BeforeWriteAtServer(ThisForm, CurrentObject);
	// "Properties" mechanism handler
	
	If Modified
		OR (CurrentObject.Posted AND WriteParameters.WriteMode = DocumentWriteMode.UndoPosting)
		OR (NOT CurrentObject.Posted AND WriteParameters.WriteMode = DocumentWriteMode.Posting) Then
		
		DocumentModified = True;
	EndIf;
	
EndProcedure // BeforeWriteAtServer()

// Procedure - BeforeWrite event handler.
//
&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	// StandardSubsystems.PerformanceEstimation
	PerformanceEstimationClientServer.StartTimeMeasurement("DocumentPurchaseOrderPosting");
	// StandardSubsystems.PerformanceEstimation
	
EndProcedure // BeforeWrite()

// Procedure - event handler OnOpen.
//
&AtClient
Procedure OnOpen(Cancel)
	
	// Peripherals
	EquipmentManagerClientOverridable.StartConnectingEquipmentOnFormOpen(ThisForm, "BarCodeScanner");
	// End Peripherals
	
	SetCurrentPage();
	
	LineCount = Object.PaymentCalendar.Count();
	Items.EditInList.Check = LineCount > 1;
	
	If Object.PaymentCalendar.Count() > 0 Then
		Items.PaymentCalendar.CurrentRow = Object.PaymentCalendar[0].GetID();
	EndIf;
	
	If Items.EditInList.Check Then
		Items.GroupPaymentCalendarListString.CurrentPage = Items.GroupPaymentCalendarList;
	Else
		Items.GroupPaymentCalendarListString.CurrentPage = Items.GroupBillingCalendarString;
	EndIf;
	
	// StandardSubsystems.Properties
	PropertiesManagementClient.AfterLoadAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
EndProcedure // OnOpen()

// Procedure - event handler OnClose.
//
&AtClient
Procedure OnClose()
	
	// Peripherals
	EquipmentManagerClientOverridable.StartDisablingEquipmentOnCloseForm(ThisForm);
	// End Peripherals
	
	If NotifyWorkCalendar Then
		Notify("ChangedOrderVendor", Object.Responsible);
	EndIf;
	
EndProcedure // OnClose()

// Procedure - event handler of the form NotificationProcessing.
//
&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Properties subsystem
	If PropertiesManagementClient.ProcessAlerts(ThisForm, EventName, Parameter) Then
		
		UpdateAdditionalAttributesItems();
		
	EndIf;
	
	// Peripherals
	If Source = "Peripherals"
		AND IsInputAvailable() Then
		If EventName = "ScanData" Then
			//Transform preliminary to the expected format
			Data = New Array();
			If Parameter[1] = Undefined Then
				Data.Add(New Structure("Barcode, Quantity", Parameter[0], 1)); // Get a barcode from the basic data
			Else
				Data.Add(New Structure("Barcode, Quantity", Parameter[1][1], 1)); // Get a barcode from the additional data
			EndIf;
			
			BarcodesReceived(Data);
		EndIf;
	EndIf;
	// End Peripherals
	
	If EventName = "AfterRecordingOfCounterparty"
		AND ValueIsFilled(Parameter)
		AND Object.Counterparty = Parameter Then
		
		SetContractVisible();
		
	ElsIf EventName = "SelectionIsMade" 
		AND ValueIsFilled(Parameter) 
		//Check for the form owner
		AND Source <> New UUID("00000000-0000-0000-0000-000000000000")
		AND Source = UUID
		Then
		
		InventoryAddressInStorage	= Parameter;
		CurrentPagesInventory	= (Items.Pages.CurrentPage = Items.GroupInventory);
		TabularSectionName		= ?(CurrentPagesInventory, "Inventory", "Materials");
		
		GetInventoryFromStorage(InventoryAddressInStorage, TabularSectionName, True, False);
		
		If CurrentPagesInventory Then
			
			// Payment calendar.
			RecalculatePaymentCalendar();
			
		EndIf;
		
	EndIf;
	
EndProcedure // NotificationProcessing()

&AtServer
// Procedure-handler of the FillCheckProcessingAtServer event.
//
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertiesManagement.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure // FillCheckProcessingAtServer()

////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - ACTIONS OF THE FORM COMMAND PANELS

// Procedure is called by clicking the PricesCurrency button of the command bar tabular field.
//
&AtClient
Procedure EditPricesAndCurrency(Item, StandardProcessing)
	
	StandardProcessing = False;
	ProcessChangesOnButtonPricesAndCurrencies(Object.DocumentCurrency);
	Modified = True;
	
EndProcedure // EditPricesAndCurrency()

// Procedure - click handler on the FillByBasis button.
//
&AtClient
Procedure FillByBasis(Command)
	
	Response = Undefined;
	
	ShowQueryBox(New NotifyDescription("FillByBasisEnd", ThisObject), NStr("en='The  document will be completely refilled on the ""Customer''s order""! Continue?';ru='Документ будет полностью перезаполнен по ""Заказу покупателя""! Продолжить выполнение операции?';vi='Chứng từ sẽ được điền lại toàn bộ theo ""Đơn hàng của khách""! Tiếp tục thực hiện thao tác?'"), QuestionDialogMode.YesNo, 0);
	
EndProcedure

&AtClient
Procedure FillByBasisEnd(Result, AdditionalParameters) Export
	
	Response = Result;
	If Response = DialogReturnCode.Yes Then
		FillByDocument();
		
		LabelStructure = New Structure("DocumentCurrency, SettlementsCurrency, ExchangeRate, RateNationalCurrency, AmountIncludesVAT, CurrencyTransactionsAccounting, CounterpartyPriceKind, VATTaxation", Object.DocumentCurrency, SettlementsCurrency, Object.ExchangeRate, RateNationalCurrency, Object.AmountIncludesVAT, CurrencyTransactionsAccounting, Object.CounterpartyPriceKind, Object.VATTaxation);
		PricesAndCurrency = GenerateLabelPricesAndCurrency(LabelStructure);
		
	EndIf;

EndProcedure  // FillExecute()

// Peripherals
// Procedure - command handler of the tabular section command panel.
//
&AtClient
Procedure SearchByBarcode(Command)
	
	CurBarcode = "";
	ShowInputValue(New NotifyDescription("SearchByBarcodeEnd", ThisObject, New Structure("CurBarcode", CurBarcode)), CurBarcode, NStr("en='Enter barcode';ru='Введите штрихкод';vi='Hãy nhập mã vạch'"));
	
EndProcedure

&AtClient
Procedure SearchByBarcodeEnd(Result, AdditionalParameters) Export
	
	CurBarcode = ?(Result = Undefined, AdditionalParameters.CurBarcode, Result);
	
	
	If Not IsBlankString(CurBarcode) Then
		BarcodesReceived(New Structure("Barcode, Quantity", CurBarcode, 1));
	EndIf;
	
	// Payment calendar.
	RecalculatePaymentCalendar();

EndProcedure // SearchByBarcode()

// Procedure - event handler Action of the GetWeight command
//
&AtClient
Procedure GetWeight(Command)
	
	TabularSectionRow = Items.Inventory.CurrentData;
	
	If TabularSectionRow = Undefined Then
		
		ShowMessageBox(Undefined, NStr("en='Select a line for which the weight should be received.';ru='Необходимо выбрать строку, для которой необходимо получить вес.';vi='Cần chọn dòng mà theo đó cần nhận trọng lượng.'"));
		
	ElsIf EquipmentManagerClient.RefreshClientWorkplace() Then // Checks if the operator's workplace is specified
		
		NotifyDescription = New NotifyDescription("GetWeightEnd", ThisObject, TabularSectionRow);
		EquipmentManagerClient.StartWeightReceivingFromElectronicScales(NOTifyDescription, UUID);
		
	EndIf;
	
EndProcedure // GetWeight()

&AtClient
Procedure GetWeightEnd(Weight, Parameters) Export
	
	TabularSectionRow = Parameters;
	
	If Not Weight = Undefined Then
		If Weight = 0 Then
			MessageText = NStr("en='Electronic scales returned zero weight.';ru='Электронные весы вернули нулевой вес.';vi='Cân điện tử trả lại trọng lượng bằng 0.'");
			CommonUseClientServer.MessageToUser(MessageText);
		Else
			// Weight is received.
			TabularSectionRow.Quantity = Weight;
			CalculateAmountInTabularSectionLine();
			RecalculatePaymentCalendar();
		EndIf;
	EndIf;
	
EndProcedure

// Procedure - ImportDataFromDTC command handler.
//
&AtClient
Procedure ImportDataFromDCT(Command)
	
	NotificationsAtImportFromDCT = New NotifyDescription("ImportFromDCTEnd", ThisObject);
	EquipmentManagerClient.StartImportDataFromDCT(NotificationsAtImportFromDCT, UUID);
	
EndProcedure // ImportDataFromDCT()

&AtClient
Procedure ImportFromDCTEnd(Result, Parameters) Export
	
	If TypeOf(Result) = Type("Array") 
	   AND Result.Count() > 0 Then
		BarcodesReceived(Result);
	EndIf;
	
EndProcedure

// End Peripherals

// Procedure - EditByList command handler.
//
&AtClient
Procedure EditInList(Command)
	
	SetEditInListOption();
	
EndProcedure // EditByList()

// Procedure - command handler DocumentSetting.
//
&AtClient
Procedure DocumentSetting(Command)
	
	// 1. Form parameter structure to fill "Document setting" form.
	ParametersStructure = New Structure;
	ParametersStructure.Insert("ReceiptDatePositionInPurchaseOrder", 	Object.ReceiptDatePosition);
	ParametersStructure.Insert("WereMadeChanges", 						False);
	
	StructureDocumentSetting = Undefined;

	
	OpenForm("CommonForm.DocumentSetting", ParametersStructure,,,,, New NotifyDescription("DocumentSettingEnd", ThisObject));
	
EndProcedure

&AtClient
Procedure DocumentSettingEnd(Result, AdditionalParameters) Export
	
	// 2. Open the form "Prices and Currency".
	StructureDocumentSetting = Result;
	
	// 3. Apply changes made in "Document setting" form.
	If TypeOf(StructureDocumentSetting) = Type("Structure") AND StructureDocumentSetting.WereMadeChanges Then
		
		Object.ReceiptDatePosition = StructureDocumentSetting.ReceiptDatePositionInPurchaseOrder;
		
		PrevReceiptDateVisible = Items.ReceiptDate.Visible;
		
		SetVisibleFromUserSettings();
		
		If PrevReceiptDateVisible = False // It was in TS.
			AND Items.ReceiptDate.Visible = True Then // It is in the header.
			
			If Object.Inventory.Count() > 0 Then
				Object.ReceiptDate = Object.Inventory[0].ReceiptDate;	
			EndIf;
			
		EndIf;
		
	EndIf;

EndProcedure

// Procedure - command handler FillByBalance submenu ChangeReserve.
//
&AtClient
Procedure ChangeReserveFillByBalances(Command)
	
	If Object.Materials.Count() = 0 Then
		Message = New UserMessage;
		Message.Text = NStr("en='Tabular section ""Materials"" is not filled in.';ru='Табличная часть ""Материалы"" не заполнена!';vi='Phần bảng ""Nguyên vật liệu"" chưa điền!'");
		Message.Message();
		Return;
	EndIf;
	
	FillColumnReserveByBalancesAtServer();
	
EndProcedure // ChangeReserveFillByBalances()

// Procedure - command handler ClearReserve of the ChangeReserve submenu.
//
&AtClient
Procedure ChangeReserveClearReserve(Command)
	
	If Object.Materials.Count() = 0 Then
		Message = New UserMessage;
		Message.Text = NStr("en='Tabular section ""Materials"" is not filled in.';ru='Табличная часть ""Материалы"" не заполнена!';vi='Phần bảng ""Nguyên vật liệu"" chưa điền!'");
		Message.Message();
		Return;
	EndIf;
	
	For Each TabularSectionRow IN Object.Materials Do
		TabularSectionRow.Reserve = 0;
	EndDo;
	
EndProcedure // ChangeReserveFillByBalances()

////////////////////////////////////////////////////////////////////////////////
// COMMANDS ACTIONS OF THE ORDERS STATUS PANEL

// Procedure - event handler OnChange input field Status.
//
&AtClient
Procedure StatusOnChange(Item)
	
	If Status = "InProcess" Then
		Object.OrderState = InProcessStatus;
		Object.Closed = False;
	ElsIf Status = "Completed" Then
		Object.OrderState = CompletedStatus;
		Object.Closed = True;
	ElsIf Status = "Canceled" Then
		Object.OrderState = InProcessStatus;
		Object.Closed = True;
	EndIf;
	
	Modified = True;
	
EndProcedure // StatusOnChange()

////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - EVENT HANDLERS OF HEADER ATTRIBUTES

// Procedure - event handler OnChange of the Date input field.
// IN procedure situation is determined when date change document is
// into document numbering another period and in this case
// assigns to the document new unique number.
// Overrides the corresponding form parameter.
//
&AtClient
Procedure DateOnChange(Item)
	
	// Date change event DataProcessor.
	DateBeforeChange = DocumentDate;
	DocumentDate = Object.Date;
	If Object.Date <> DateBeforeChange Then
		StructureData = GetDataDateOnChange(Object.Ref, Object.Date, DateBeforeChange, SettlementsCurrency);
		If StructureData.DATEDIFF <> 0 Then
			Object.Number = "";
		EndIf;
		
		If ValueIsFilled(SettlementsCurrency) Then
			RecalculateExchangeRateMultiplicitySettlementCurrency(StructureData);
		EndIf;
				
	EndIf;
	
EndProcedure // DateOnChange()

// Procedure - event handler OnChange of the Company input field.
// IN procedure is executed document
// number clearing and also make parameter set of the form functional options.
// Overrides the corresponding form parameter.
//
&AtClient
Procedure CompanyOnChange(Item)
	
	// Company change event data processor.
	Object.Number = "";
	
	Object.Contract = GetContractByDefault(Object.Ref, Object.Counterparty, Object.Company, Object.OperationKind);
	ProcessContractChange();
	
	StructureData = GetCompanyDataOnChange(Object.Company);
	Counterparty = StructureData.Counterparty;
	If Object.DocumentCurrency = StructureData.BankAccountCashAssetsCurrency Then
		Object.BankAccount = StructureData.BankAccount;
	EndIf;
	
EndProcedure // CompanyOnChange()

// Procedure - event handler OnChange of the OperationKind input field.
//
&AtClient
Procedure OperationKindOnChange(Item)
	
	ProcessOperationKindChange();
	ProcessContractChange();
	
EndProcedure // OperationKindOnChange()

// Procedure - event handler OnChange of the Counterparty input field.
// Clears the contract and tabular section.
//
&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyBeforeChange = Counterparty;
	Counterparty = Object.Counterparty;
	
	If CounterpartyBeforeChange <> Object.Counterparty Then
		
		StructureData = GetDataCounterpartyOnChange(Object.Date, Object.DocumentCurrency, Object.Counterparty, Object.Company);
		Object.Contract = StructureData.Contract;
		ProcessContractChange(StructureData);
		
	Else
		
		Object.Contract = Contract; // Restore the cleared contract automatically.
		
	EndIf;
	
EndProcedure

// Procedure - event handler OnChange of the Contract input field.
// Fills form attributes - exchange rate and multiplicity.
//
&AtClient
Procedure ContractOnChange(Item)
	
	ProcessContractChange();
	
EndProcedure // ContractOnChange()

// Procedure - event handler StartChoice of the Contract input field.
//
&AtClient
Procedure ContractStartChoice(Item, ChoiceData, StandardProcessing)
	
	If Not ValueIsFilled(Object.OperationKind) Then
		Return;
	EndIf;
	
	FormParameters = GetChoiceFormOfContractParameters(Object.Ref, Object.Company, Object.Counterparty, Object.Contract, Object.OperationKind);
	If FormParameters.ControlContractChoice Then
		
		StandardProcessing = False;
		OpenForm("Catalog.CounterpartyContracts.Form.ChoiceForm", FormParameters, Item);
		
	EndIf;
	
EndProcedure

// Procedure - event handler SelectionStart input field BankAccount.
//
&AtClient
Procedure BankAccountStartChoice(Item, ChoiceData, StandardProcessing)
	
	If Not ValueIsFilled(Object.Contract) Then
		Return;
	EndIf;
	
	FormParameters = GetChoiceFormParametersBankAccount(Object.Contract, Object.Company, NationalCurrency);
	If FormParameters.SettlementsInStandardUnits Then
		
		StandardProcessing = False;
		OpenForm("Catalog.BankAccounts.ChoiceForm", FormParameters, Item);
		
	EndIf;
	
EndProcedure

// Procedure - event handler OnChange input field CashAssetsType.
//
&AtClient
Procedure CashAssetsTypeOnChange(Item)
	
	SetCurrentPage();
	
EndProcedure // CashAssetsTypeOnChange()

// Procedure - event handler OnChange of the ReflectInPaymentCalendar input field.
//
&AtClient
Procedure SchedulePayOnChange(Item)
	
	SetVisibleAndEnabled();
	
	If Object.SchedulePayment
		AND Object.PaymentCalendar.Count() = 0 Then
		
		NewRow 				= Object.PaymentCalendar.Add();
		NewRow.PayDate 		= Object.Date + GetVendorPaymentDueDate(Object.Contract) * 86400;
		NewRow.PaymentPercentage 	= 100;
		NewRow.PaymentAmount 	= Object.Inventory.Total("Total");
		NewRow.PayVATAmount 	= Object.Inventory.Total("VATAmount");
		Items.PaymentCalendar.CurrentRow = NewRow.GetID();
		
	ElsIf Not Object.SchedulePayment
		AND Object.PaymentCalendar.Count() > 0 Then
		
		Object.PaymentCalendar.Clear();
		Object.BankAccount = Undefined;
		
	EndIf;
	
EndProcedure // SchedulePayOnChange()

// Procedure - event handler OnChange of the PaymentCalendarPaymentPercent input field.
//
&AtClient
Procedure PaymentCalendarPaymentPercentageOnChange(Item)
	
	CurrentRow = Items.PaymentCalendar.CurrentData;
	PercentOfPaymentTotal = Object.PaymentCalendar.Total("PaymentPercentage");
	
	If PercentOfPaymentTotal > 100 Then
		CurrentRow.PaymentPercentage = CurrentRow.PaymentPercentage - (PercentOfPaymentTotal - 100);
	EndIf;
	
	CurrentRow.PaymentAmount = Round(Object.Inventory.Total("Total") * CurrentRow.PaymentPercentage / 100, 2, 1);
	CurrentRow.PayVATAmount = Round(Object.Inventory.Total("VATAmount") * CurrentRow.PaymentPercentage / 100, 2, 1);
	
EndProcedure // PaymentCalendarPaymentPercentOnChange()

// Procedure - event handler OnChange of the PaymentCalendarPaymentAmount input field.
//
&AtClient
Procedure PaymentCalendarPaymentSumOnChange(Item)
	
	CurrentRow = Items.PaymentCalendar.CurrentData;
	
	InventoryTotal = Object.Inventory.Total("Total");
	PaymentCalendarTotal = Object.PaymentCalendar.Total("PaymentAmount");
		
	If PaymentCalendarTotal > InventoryTotal Then
		CurrentRow.PaymentAmount = CurrentRow.PaymentAmount - (PaymentCalendarTotal - InventoryTotal);
	EndIf;
	
	CurrentRow.PaymentPercentage = ?(InventoryTotal = 0, 0, Round(CurrentRow.PaymentAmount / InventoryTotal * 100, 2, 1));
	CurrentRow.PayVATAmount = Round(Object.Inventory.Total("VATAmount") * CurrentRow.PaymentPercentage / 100, 2, 1);
	
EndProcedure // PaymentCalendarPaymentSumOnChange()

// Procedure - event handler OnChange of the PaymentCalendarPayVATAmount input field.
//
&AtClient
Procedure PaymentCalendarPayVATAmountOnChange(Item)
	
	CurrentRow = Items.PaymentCalendar.CurrentData;
	
	InventoryTotal = Object.Inventory.Total("VATAmount");
	PaymentCalendarTotal = Object.PaymentCalendar.Total("PayVATAmount");
	
	If PaymentCalendarTotal > InventoryTotal Then
		CurrentRow.PayVATAmount = CurrentRow.PayVATAmount - (PaymentCalendarTotal - InventoryTotal);
	EndIf;
	
EndProcedure // PaymentCalendarPayVATAmountOnChange()

// Procedure - event handler OnChange of the OrderState input field.
//
&AtClient
Procedure OrderStateOnChange(Item)
	
	Status = GetDataOrderStateOnChange(Object.OrderState);
		
	If Not  TrimAll(Status) = "Open" Then
	
		Items.SchedulePayment.Enabled = True;
		
	EndIf;
	
	SetVisibleAndEnabled();
	
EndProcedure // OrderStateOnChange()

////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - EVENT HANDLERS OF THE INVENTORY TABULAR SECTION ATTRIBUTES

// Procedure - OnEditEnd event handler of the Inventory tabular section.
//
&AtClient
Procedure InventoryOnEditEnd(Item, NewRow, CancelEdit)
	
	// Payment calendar.
	RecalculatePaymentCalendar();

EndProcedure // InventoryOnEditEnd()

// Procedure - AfterDeletion event handler of the Inventory tabular section.
//
&AtClient
Procedure InventoryAfterDeleteRow(Item)
	
	// Payment calendar.
	RecalculatePaymentCalendar();
	
EndProcedure // InventoryAfterDeletion()

// Procedure - event handler OnChange of the ProductsAndServices input field.
//
&AtClient
Procedure InventoryProductsAndServicesOnChange(Item)
	
	TabularSectionRow = Items.Inventory.CurrentData;
	
	StructureData = New Structure;
	StructureData.Insert("Company", Object.Company);
	StructureData.Insert("ProductsAndServices", TabularSectionRow.ProductsAndServices);
	StructureData.Insert("Characteristic", TabularSectionRow.Characteristic);
	StructureData.Insert("VATTaxation", Object.VATTaxation);
	
	If ValueIsFilled(Object.CounterpartyPriceKind) Then
		
		StructureData.Insert("ProcessingDate", Object.Date);
		StructureData.Insert("DocumentCurrency", Object.DocumentCurrency);
		StructureData.Insert("AmountIncludesVAT", Object.AmountIncludesVAT);
		StructureData.Insert("CounterpartyPriceKind", Object.CounterpartyPriceKind);
		StructureData.Insert("Factor", 1);
		
	EndIf;
	
	StructureData = GetDataProductsAndServicesOnChange(StructureData);
	
	TabularSectionRow.MeasurementUnit = StructureData.MeasurementUnit;
	TabularSectionRow.Quantity = 1;
	TabularSectionRow.Price = StructureData.Price;
	TabularSectionRow.VATRate = StructureData.VATRate;
	TabularSectionRow.Content = "";
	
	CalculateAmountInTabularSectionLine();
	
EndProcedure // InventoryProductsAndServicesOnChange()

// Procedure - event handler OnChange of the Characteristic input field.
//
&AtClient
Procedure InventoryCharacteristicOnChange(Item)
	
	TabularSectionRow = Items.Inventory.CurrentData;
		
	StructureData = New Structure;
	StructureData.Insert("ProductsAndServices", 			TabularSectionRow.ProductsAndServices);
	StructureData.Insert("Characteristic", 			TabularSectionRow.Characteristic);
	
	If ValueIsFilled(Object.CounterpartyPriceKind) Then
		
		StructureData.Insert("ProcessingDate", 			Object.Date);
		StructureData.Insert("DocumentCurrency", 		Object.DocumentCurrency);
		StructureData.Insert("AmountIncludesVAT", 		Object.AmountIncludesVAT);
		
		StructureData.Insert("VATRate", 				TabularSectionRow.VATRate);
		StructureData.Insert("Price", 					TabularSectionRow.Price);
		
		StructureData.Insert("CounterpartyPriceKind", Object.CounterpartyPriceKind);
		StructureData.Insert("MeasurementUnit", TabularSectionRow.MeasurementUnit);
		
	EndIf;
		
	StructureData = GetDataCharacteristicOnChange(StructureData);
	
	TabularSectionRow.Price = StructureData.Price;
	TabularSectionRow.Content = "";
	
	CalculateAmountInTabularSectionLine();
	
EndProcedure // InventoryCharacteristicOnChange()

// Procedure - event handler AutoPick of the Content input field.
//
&AtClient
Procedure InventoryContentAutoComplete(Item, Text, ChoiceData, Parameters, Wait, StandardProcessing)
	
	If Wait = 0 Then
		
		StandardProcessing = False;
		
		TabularSectionRow = Items.Inventory.CurrentData;
		ContentPattern = SmallBusinessServer.GetContentText(TabularSectionRow.ProductsAndServices, TabularSectionRow.Characteristic);
		
		ChoiceData = New ValueList;
		ChoiceData.Add(ContentPattern);
		
	EndIf;
	
EndProcedure

// Procedure - event handler OnChange of the Count input field.
//
&AtClient
Procedure InventoryQuantityOnChange(Item)
	
	CalculateAmountInTabularSectionLine();
	
	// Payment calendar.
	RecalculatePaymentCalendar();
	
EndProcedure // InventoryQuantityOnChange()

// Procedure - event handler ChoiceProcessing of the MeasurementUnit input field.
//
&AtClient
Procedure InventoryMeasurementUnitChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	TabularSectionRow = Items.Inventory.CurrentData;
	
	If TabularSectionRow.MeasurementUnit = ValueSelected 
		OR TabularSectionRow.Price = 0 Then
		Return;
	EndIf;	
	
	CurrentFactor = 0;
	If TypeOf(TabularSectionRow.MeasurementUnit) = Type("CatalogRef.UOMClassifier") Then
		CurrentFactor = 1;
	EndIf;	
	
	Factor = 0;
	If TypeOf(ValueSelected) = Type("CatalogRef.UOMClassifier") Then
		Factor = 1;
	EndIf;
	
	If CurrentFactor = 0 AND Factor = 0 Then
		StructureData = GetDataMeasurementUnitOnChange(TabularSectionRow.MeasurementUnit, ValueSelected);
	ElsIf CurrentFactor = 0 Then
		StructureData = GetDataMeasurementUnitOnChange(TabularSectionRow.MeasurementUnit);
	ElsIf Factor = 0 Then
		StructureData = GetDataMeasurementUnitOnChange(,ValueSelected);
	ElsIf CurrentFactor = 1 AND Factor = 1 Then
		StructureData = New Structure("CurrentFactor, Factor", 1, 1);
	EndIf;
	
	// Price.
	If StructureData.CurrentFactor <> 0 Then
		TabularSectionRow.Price = TabularSectionRow.Price * StructureData.Factor / StructureData.CurrentFactor;
	EndIf; 		
	
	CalculateAmountInTabularSectionLine();
	
EndProcedure // InventoryMeasurementUnitChoiceProcessing()

// Procedure - event handler OnChange of the Price input field.
//
&AtClient
Procedure InventoryPriceOnChange(Item)
	
	CalculateAmountInTabularSectionLine();
	
	// Payment calendar.
	RecalculatePaymentCalendar();
	
EndProcedure // InventoryPriceOnChange()

// Procedure - event handler OnChange of the Amount input field.
//
&AtClient
Procedure InventoryAmountOnChange(Item)
	
	TabularSectionRow = Items.Inventory.CurrentData;
	
	// Price.
	If TabularSectionRow.Quantity <> 0 Then
		TabularSectionRow.Price = TabularSectionRow.Amount / TabularSectionRow.Quantity;
	EndIf;
	
	// VAT amount.
	CalculateVATSUM(TabularSectionRow);
	
	// Total.	
	TabularSectionRow.Total = TabularSectionRow.Amount + ?(Object.AmountIncludesVAT, 0, TabularSectionRow.VATAmount);
	
	// Payment calendar.
	RecalculatePaymentCalendar();
	
EndProcedure // InventoryAmountOnChange()

// Procedure - event handler OnChange of the VATRate input field.
//
&AtClient
Procedure InventoryVATRateOnChange(Item)
	
	TabularSectionRow = Items.Inventory.CurrentData;
	
	// VAT amount.
	CalculateVATSUM(TabularSectionRow);
	
	// Total.
	TabularSectionRow.Total = TabularSectionRow.Amount + ?(Object.AmountIncludesVAT, 0, TabularSectionRow.VATAmount);
	
	// Payment calendar.
	RecalculatePaymentCalendar();
	
EndProcedure  // InventoryVATRateOnChange()

// Procedure - event handler OnChange of the VATRate input field.
//
&AtClient
Procedure InventoryVATAmountOnChange(Item)
	
	TabularSectionRow = Items.Inventory.CurrentData;
	
	// Total.
	TabularSectionRow.Total = TabularSectionRow.Amount + ?(Object.AmountIncludesVAT, 0, TabularSectionRow.VATAmount);
	
	// Payment calendar.
	RecalculatePaymentCalendar();
	
EndProcedure // InventoryVATAmountOnChange()

////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - TABULAR SECTION ATTRIBUTE EVENT HANDLERS

// Procedure - event handler OnChange of the ProductsAndServices input field.
//
&AtClient
Procedure MaterialsProductsAndServicesOnChange(Item)
	
	TabularSectionRow = Items.Materials.CurrentData;
	
	StructureData = New Structure;
	StructureData.Insert("Company", Counterparty);
	StructureData.Insert("ProductsAndServices", TabularSectionRow.ProductsAndServices);
	StructureData.Insert("Characteristic", TabularSectionRow.Characteristic);
	
	StructureData = GetDataProductsAndServicesOnChange(StructureData);
	TabularSectionRow.MeasurementUnit = StructureData.MeasurementUnit;
	TabularSectionRow.Quantity = 1;
	
EndProcedure // MaterialsProductsAndServicesOnChange()

// Procedure - OnStartEdit event handler of the .PaymentCalendar list
//
&AtClient
Procedure PaymentCalendarOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		CurrentRow = Items.PaymentCalendar.CurrentData;
		PercentOfPaymentTotal = Object.PaymentCalendar.Total("PaymentPercentage");
		
		If PercentOfPaymentTotal > 100 Then
			CurrentRow.PaymentPercentage = CurrentRow.PaymentPercentage - (PercentOfPaymentTotal - 100);
		EndIf;
		
		CurrentRow.PaymentAmount = Round(Object.Inventory.Total("Total") * CurrentRow.PaymentPercentage / 100, 2, 1);
		CurrentRow.PayVATAmount = Round(Object.Inventory.Total("VATAmount") * CurrentRow.PaymentPercentage / 100, 2, 1);
	EndIf;
	
EndProcedure // PaymentCalendarOnStartEdit()

// Procedure - event handler OnChange input field ListPaymentCalendarPaymentPercent.
//
&AtClient
Procedure ListPaymentCalendarPaymentPercentageOnChange(Item)
	
	CurrentRow = Items.PaymentCalendar.CurrentData;
	PercentOfPaymentTotal = Object.PaymentCalendar.Total("PaymentPercentage");
	
	If PercentOfPaymentTotal > 100 Then
		CurrentRow.PaymentPercentage = CurrentRow.PaymentPercentage - (PercentOfPaymentTotal - 100);
	EndIf;
	
	CurrentRow.PaymentAmount = Round(Object.Inventory.Total("Total") * CurrentRow.PaymentPercentage / 100, 2, 1);
	CurrentRow.PayVATAmount = Round(Object.Inventory.Total("VATAmount") * CurrentRow.PaymentPercentage / 100, 2, 1);
	
EndProcedure // ListPaymentCalendarPaymentPercentOnChange()

// Procedure - event handler OnChange of the ListPaymentCalendarPaymentAmount input field.
//
&AtClient
Procedure ListPaymentCalendarPaymentSumOnChange(Item)
	
	CurrentRow = Items.PaymentCalendar.CurrentData;
	InventoryTotal = Object.Inventory.Total("Total");
	PaymentCalendarTotal = Object.PaymentCalendar.Total("PaymentAmount");
	
	If PaymentCalendarTotal > InventoryTotal Then
		CurrentRow.PaymentAmount = CurrentRow.PaymentAmount - (PaymentCalendarTotal - InventoryTotal);
	EndIf;
	
	CurrentRow.PaymentPercentage = ?(InventoryTotal = 0, 0, Round(CurrentRow.PaymentAmount / InventoryTotal * 100, 2, 1));
	CurrentRow.PayVATAmount = Round(Object.Inventory.Total("VATAmount") * CurrentRow.PaymentPercentage / 100, 2, 1);
	
EndProcedure // ListPaymentCalendarPaymentSumOnChange()

// Procedure - event handler OnChange of the ListPaymentCalendarPayVATAmount input field.
//
&AtClient
Procedure ListPaymentCalendarPayVATAmountOnChange(Item)
	
	CurrentRow = Items.PaymentCalendar.CurrentData;
	
	InventoryTotal = Object.Inventory.Total("VATAmount");
	PaymentCalendarTotal = Object.PaymentCalendar.Total("PayVATAmount");
	
	If PaymentCalendarTotal > InventoryTotal Then
		CurrentRow.PayVATAmount = CurrentRow.PayVATAmount - (PaymentCalendarTotal - InventoryTotal);
	EndIf;

EndProcedure // ListPaymentCalendarPayVATAmountOnChange()

// Procedure - BeforeDeletion event handler of the PaymentCalendar tabular section.
//
&AtClient
Procedure PaymentCalendarBeforeDelete(Item, Cancel)
	
	If Object.PaymentCalendar.Count() = 1 Then
		Cancel = True;
	EndIf;
	
EndProcedure // PaymentCalendarBeforeDelete()

////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - TOOLTIP EVENTS HANDLERS

&AtClient
Procedure StatusExtendedTooltipNavigationLinkProcessing(Item, URL, StandardProcessing)
	
	StandardProcessing = False;
	OpenForm("DataProcessor.AdministrationPanelSB.Form.PurchaseSection");
	
EndProcedure

// Procedure sets the contract visible in dependence on established parameter to counterparty.
//
&AtServer
Procedure SetContractVisible()
	
	Items.Contract.Visible = Object.Counterparty.DoOperationsByContracts;
	
EndProcedure // SetContractVisible()

#Region InteractiveActionResultHandlers

// Procedure-handler of the result of opening the "Prices and currencies" form
//
&AtClient
Procedure ProcessChangesOnButtonPricesAndCurrenciesEnd(ClosingResult, AdditionalParameters) Export
	
	// Refill the tabular section "Inventory" if changes were made to the form "Prices and Currency".
	If TypeOf(ClosingResult) = Type("Structure")
	   AND ClosingResult.WereMadeChanges Then
		
		If Object.DocumentCurrency <> ClosingResult.DocumentCurrency Then
			Object.BankAccount = Undefined;
		EndIf;
		
		Object.DocumentCurrency = ClosingResult.DocumentCurrency;
		Object.ExchangeRate = ClosingResult.PaymentsRate;
		Object.Multiplicity = ClosingResult.SettlementsMultiplicity;
		Object.VATTaxation = ClosingResult.VATTaxation;
		Object.AmountIncludesVAT = ClosingResult.AmountIncludesVAT;
		Object.IncludeVATInPrice = ClosingResult.IncludeVATInPrice;
		Object.CounterpartyPriceKind = ClosingResult.CounterpartyPriceKind;
		
		// Recalculate prices by kind of prices.
		If ClosingResult.RefillPrices Then
			SmallBusinessClient.RefillTabularSectionPricesByCounterpartyPriceKind(ThisForm, "Inventory");
		EndIf;
		
		// Recalculate prices by currency.
		If Not ClosingResult.RefillPrices
			  AND ClosingResult.RecalculatePrices Then
			SmallBusinessClient.RecalculateTabularSectionPricesByCurrency(ThisForm, AdditionalParameters.SettlementsCurrencyBeforeChange, "Inventory");
		EndIf;
		
		// Recalculate the amount if VAT taxation flag is changed.
		If ClosingResult.VATTaxation <> ClosingResult.PrevVATTaxation Then
			FillVATRateByVATTaxation();
		EndIf;
		
		// Recalculate the amount if the "Amount includes VAT" flag is changed.
		If Not ClosingResult.RefillPrices
			AND Not ClosingResult.AmountIncludesVAT = ClosingResult.PrevAmountIncludesVAT Then
			SmallBusinessClient.RecalculateTabularSectionAmountByFlagAmountIncludesVAT(ThisForm, "Inventory");
		EndIf;
		
	EndIf;
	
	LabelStructure = New Structure("DocumentCurrency, SettlementsCurrency, ExchangeRate, RateNationalCurrency, AmountIncludesVAT, CurrencyTransactionsAccounting, CounterpartyPriceKind, VATTaxation", Object.DocumentCurrency, SettlementsCurrency, Object.ExchangeRate, RateNationalCurrency, Object.AmountIncludesVAT, CurrencyTransactionsAccounting, Object.CounterpartyPriceKind, Object.VATTaxation);
	PricesAndCurrency = GenerateLabelPricesAndCurrency(LabelStructure);
	
	RecalculatePaymentCalendar();
	
EndProcedure // ProcessChangesOnButtonPricesAndCurrenciesEnd()

&AtClient
// Procedure-handler response on question about document recalculate by contract data
//
Procedure DefineDocumentRecalculateNeedByContractTerms(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult = DialogReturnCode.Yes Then
		
		If AdditionalParameters.RecalculationRequired Then
			
			SmallBusinessClient.RefillTabularSectionPricesByCounterpartyPriceKind(ThisForm, "Inventory");
			RecalculatePaymentCalendar();
			
		EndIf;
		
	EndIf;
	
EndProcedure // DefineDocumentRecalculateNeedByContractTerms()

#EndRegion

#Region LibrariesHandlers

// StandardSubsystems.AdditionalReportsAndDataProcessors
&AtClient
Procedure Attachable_ExecuteAssignedCommand(Command)
	If Not AdditionalReportsAndDataProcessorsClient.ExecuteAllocatedCommandAtClient(ThisForm, Command.Name) Then
		ExecutionResult = Undefined;
		AdditionalReportsAndProcessingsExecuteAllocatedCommandAtServer(Command.Name, ExecutionResult);
		AdditionalReportsAndDataProcessorsClient.ShowCommandExecutionResult(ThisForm, ExecutionResult);
	EndIf;
EndProcedure

&AtServer
Procedure AdditionalReportsAndProcessingsExecuteAllocatedCommandAtServer(ItemName, ExecutionResult)
	AdditionalReportsAndDataProcessors.ExecuteAllocatedCommandAtServer(ThisForm, ItemName, ExecutionResult);
EndProcedure
// End StandardSubsystems.AdditionalReportsAndDataProcessors

// StandardSubsystems.DataImportFromExternalSources

&AtClient
Procedure LoadFromFileInventory(Command)
	
	NotifyDescription = New NotifyDescription("ImportDataFromExternalSourceResultDataProcessor", ThisObject, DataLoadSettings);
	
	DataLoadSettings.Insert("TabularSectionFullName",	"PurchaseOrder.Inventory");
	DataLoadSettings.Insert("Title",					NStr("en='Import inventory from file';ru='Загрузка запасов из файла';vi='Kết nhập vật tư từ tệp'"));
	
	DataImportFromExternalSourcesClient.ShowDataImportFormFromExternalSource(DataLoadSettings, NotifyDescription, ThisObject);
	
EndProcedure

&AtClient
Procedure ImportDataFromExternalSourceResultDataProcessor(ImportResult, AdditionalParameters) Export
	
	If TypeOf(ImportResult) = Type("Structure") Then
		ProcessPreparedData(ImportResult);
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessPreparedData(ImportResult)
	
	DataImportFromExternalSourcesOverridable.ImportDataFromExternalSourceResultDataProcessor(ImportResult, Object);
	
EndProcedure

// End StandardSubsystems.DataImportFromExternalSource


// StandardSubsystems.Printing
&AtClient
Procedure Attachable_ExecutePrintCommand(Command)
	PrintManagementClient.ExecuteConnectedPrintCommand(Command, ThisObject, Object);
EndProcedure
// End StandardSubsystems.Printing

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesRunCommand(ItemOrCommand, URL = Undefined, StandardProcessing = Undefined)
	PropertiesManagementClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure // Подключаемый_РедактироватьСоставСвойств()

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertiesManagement.UpdateAdditionalAttributesItems(ThisObject, FormAttributeToValue("Object"));
	
EndProcedure // ОбновитьЭлементыДополнительныхРеквизитов()

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertiesManagementClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_AdditionalAttributeOnChange(Item)
	PropertiesManagementClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure
// End StandardSubsystems.Properties

#EndRegion