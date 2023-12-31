////////////////////////////////////////////////////////////////////////////////
// GENERAL PURPOSE PROCEDURES AND FUNCTIONS

&AtClient
// The procedure handles the change of the Price kind and Settlement currency document attributes
//
Procedure HandleCounterpartiesPriceKindChangeAndSettlementsCurrency(DocumentParameters)
	
	ContractBeforeChange = DocumentParameters.ContractBeforeChange;
	SettlementsCurrencyBeforeChange = DocumentParameters.SettlementsCurrencyBeforeChange;
	ContractData = DocumentParameters.ContractData;
	PriceKindChanged = DocumentParameters.PriceKindChanged;
	QuestionCounterpartyPriceKind = DocumentParameters.QuestionCounterpartyPriceKind;
	OpenFormPricesAndCurrencies = DocumentParameters.OpenFormPricesAndCurrencies;
	
	If Not ContractData.AmountIncludesVAT = Undefined Then
		
		Object.AmountIncludesVAT = ContractData.AmountIncludesVAT;
		
	EndIf;
	
	If ValueIsFilled(Object.Contract) Then 
		Object.ExchangeRate      = ?(ContractData.SettlementsCurrencyRateRepetition.ExchangeRate = 0, 1, ContractData.SettlementsCurrencyRateRepetition.ExchangeRate);
		Object.Multiplicity = ?(ContractData.SettlementsCurrencyRateRepetition.Multiplicity = 0, 1, ContractData.SettlementsCurrencyRateRepetition.Multiplicity);
	EndIf;
	
	If PriceKindChanged Then
		
		Object.CounterpartyPriceKind = ContractData.CounterpartyPriceKind;
		
	EndIf;
	
	LabelStructure = New Structure("DocumentCurrency, SettlementsCurrency, ExchangeRate, RateNationalCurrency, AmountIncludesVAT, CurrencyTransactionsAccounting, CounterpartyPriceKind, VATTaxation", 
		Object.DocumentCurrency, 
		SettlementsCurrency, 
		Object.ExchangeRate, 
		RateNationalCurrency, 
		Object.AmountIncludesVAT, 
		CurrencyTransactionsAccounting, 
		Object.CounterpartyPriceKind, 
		Object.VATTaxation
		);
	
	PricesAndCurrency = GenerateLabelPricesAndCurrency(LabelStructure);
	
	Object.DocumentCurrency = ContractData.SettlementsCurrency;
	
	If OpenFormPricesAndCurrencies Then
		
		WarningText = "";
		If PriceKindChanged Then
			
			WarningText = NStr("en='The counterparty contract allows for the kind of prices other than prescribed in the document! "
"Recalculate the document according to the contract?';ru='Договор с контрагентом предусматривает вид цен, отличный от установленного в документе! "
"Пересчитать документ в соответствии с договором?';vi='Hợp đồng với đối tác xem xét dạng giá mà khác với dạng giá đã đặt trong chứng từ!"
"Đọc lại chứng từ tương ứng với hợp đồng?'") + Chars.LF + Chars.LF;
			
		EndIf;
		
		WarningText = WarningText + NStr("en='Settlement currency of the contract with counterparty changed! "
"It is necessary to check the document currency!';ru='Изменилась валюта расчетов по договору с контрагентом! "
"Необходимо проверить валюту документа!';vi='Đã trhay đổi tiền tệ hạch toán theo hợp đồng với đối tác!"
"Cần kiểm tra tiền tệ của chứng từ!'");
		
		ProcessChangesOnButtonPricesAndCurrencies(SettlementsCurrencyBeforeChange, True, PriceKindChanged, WarningText);
		
	ElsIf QuestionCounterpartyPriceKind Then
		
		If Object.Inventory.Count() > 0 Then
			
			QuestionText = NStr("en='The counterparty contract allows for the kind of prices other than prescribed in the document! "
"Recalculate the document according to the contract?';ru='Договор с контрагентом предусматривает вид цен, отличный от установленного в документе! "
"Пересчитать документ в соответствии с договором?';vi='Hợp đồng với đối tác xem xét dạng giá mà khác với dạng giá đã đặt trong chứng từ!"
"Đọc lại chứng từ tương ứng với hợp đồng?'");
			
			NotifyDescription = New NotifyDescription("DefineDocumentRecalculateNeedByContractTerms", ThisObject, DocumentParameters);
			ShowQueryBox(NOTifyDescription, QuestionText, QuestionDialogMode.YesNo);
			
		EndIf;
		
	EndIf;
	
EndProcedure // HandleCounterpartiesPriceKindChangeAndSettlementsCurrency()

&AtServerNoContext
// It receives data set from server for the DateOnChange procedure.
//
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

&AtServerNoContext
// Receives the data set from the server for the CompanyOnChange procedure.
//
Function GetCompanyDataOnChange(Company)
	
	StructureData = New Structure();
	StructureData.Insert("Company", SmallBusinessServer.GetCompany(Company));
	StructureData.Insert("VATRate", StructureData.Company.DefaultVATRate);
	
	Return StructureData;
	
EndFunction // GetCompanyDataOnChange()

&AtServerNoContext
// Receives the set of data from the server for the ProductsAndServicesOnChange procedure.
//
Function GetDataProductsAndServicesOnChange(StructureData)
	
	ProductsAndServicesData = CommonUse.ObjectAttributesValues(StructureData.ProductsAndServices,
		"MeasurementUnit, VATRate, CountryOfOrigin");
	
	StructureData.Insert("MeasurementUnit", ProductsAndServicesData.MeasurementUnit);
	StructureData.Insert("CountryOfOrigin", ProductsAndServicesData.CountryOfOrigin);
	
	If StructureData.Property("VATTaxation") 
		AND Not StructureData.VATTaxation = Enums.VATTaxationTypes.TaxableByVAT Then
		
		If StructureData.VATTaxation = Enums.VATTaxationTypes.NotTaxableByVAT Then
			StructureData.Insert("VATRate", SmallBusinessReUse.GetVATRateWithoutVAT());
		Else
			StructureData.Insert("VATRate", SmallBusinessReUse.GetVATRateZero());
		EndIf;	
																
	ElsIf ValueIsFilled(ProductsAndServicesData.VATRate) Then
		StructureData.Insert("VATRate", ProductsAndServicesData.VATRate);
	Else
		StructureData.Insert("VATRate", StructureData.Company.DefaultVATRate);
	EndIf;
	
	If StructureData.Property("CounterpartyPriceKind") Then
		
		ReceiptPrice = SmallBusinessServer.GetPriceProductsAndServicesByCounterpartyPriceKind(StructureData);
		StructureData.Insert("ReceiptPrice", ReceiptPrice);
		
	Else
		
		StructureData.Insert("ReceiptPrice", 0);
		
	EndIf;
	
	Return StructureData;
	
EndFunction // ReceiveDataProductsAndServicesOnChange()	

&AtServerNoContext
// It receives data set from server for the CharacteristicOnChange procedure.
//
Function GetDataCharacteristicOnChange(StructureData)
	
	If StructureData.Property("CounterpartyPriceKind") Then
		
		If TypeOf(StructureData.MeasurementUnit) = Type("CatalogRef.UOMClassifier") Then
			StructureData.Insert("Factor", 1);
		Else
			StructureData.Insert("Factor", StructureData.MeasurementUnit.Factor);
		EndIf;		
		
		ReceiptPrice = SmallBusinessServer.GetPriceProductsAndServicesByCounterpartyPriceKind(StructureData);
		StructureData.Insert("ReceiptPrice", ReceiptPrice);
		
	EndIf;
		
	Return StructureData;
	
EndFunction // GetDataCharacteristicOnChange()	

&AtServerNoContext
// Gets the data set from the server for procedure MeasurementUnitOnChange.
//
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

&AtServer
// It receives data set from the server for the CounterpartyOnChange procedure.
//
Function GetDataCounterpartyOnChange(Date, DocumentCurrency, Counterparty, Company)
	
	ContractByDefault = GetContractByDefault(Object.Ref, Counterparty, Company);
	
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
		"CounterpartyPriceKind",
		ContractByDefault.CounterpartyPriceKind
	);
	
	StructureData.Insert(
		"AmountIncludesVAT",
		?(ValueIsFilled(ContractByDefault.CounterpartyPriceKind), ContractByDefault.CounterpartyPriceKind.PriceIncludesVAT, Undefined)
	);
	
	SetContractVisible();
	
	Return StructureData;
	
EndFunction // GetDataCounterpartyOnChange()

&AtServerNoContext
// It receives data set from server for the ContractOnChange procedure.
//
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
		"PriceKind",
		Contract.PriceKind
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

&AtServer
// Procedure fills the VAT rate in the tabular section according to the taxation system.
// 
Procedure FillVATRateByVATTaxation()
	
	If Object.VATTaxation = Enums.VATTaxationTypes.TaxableByVAT Then
		
		Items.InventoryVATRate.Visible = True;
		Items.InventoryVATAmount.Visible = True;
		Items.InventoryAmountTotal.Visible = True;
		Items.InventoryVATSummOfArrival.Visible = True;
		
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
											
			TabularSectionRow.ReceiptVATAmount = ?(Object.AmountIncludesVAT, 
													TabularSectionRow.AmountReceipt - (TabularSectionRow.AmountReceipt) / ((VATRate + 100) / 100),
													TabularSectionRow.AmountReceipt * VATRate / 100);								
											
			TabularSectionRow.Total = TabularSectionRow.Amount + ?(Object.AmountIncludesVAT, 0, TabularSectionRow.VATAmount);
			
		EndDo;	
		
	Else
		
		Items.InventoryVATRate.Visible = False;
		Items.InventoryVATAmount.Visible = False;
		Items.InventoryAmountTotal.Visible = False;
		Items.InventoryVATSummOfArrival.Visible = False;
		
		If Object.VATTaxation = Enums.VATTaxationTypes.NotTaxableByVAT Then	
		    DefaultVATRate = SmallBusinessReUse.GetVATRateWithoutVAT();
		Else
			DefaultVATRate = SmallBusinessReUse.GetVATRateZero();
		EndIf;	
		
		For Each TabularSectionRow IN Object.Inventory Do
		
			TabularSectionRow.VATRate = DefaultVATRate;
			TabularSectionRow.VATAmount = 0;
			TabularSectionRow.ReceiptVATAmount = 0;
			TabularSectionRow.Total = TabularSectionRow.Amount;
			
		EndDo;	
		
	EndIf;	
	
EndProcedure // FillVATRateByVATTaxation()	

&AtClient
// VAT amount is calculated in the row of tabular section.
//
Procedure CalculateVATSUM(TabularSectionRow)
	
	VATRate = SmallBusinessReUse.GetVATRateValue(TabularSectionRow.VATRate);
	
	TabularSectionRow.VATAmount = ?(Object.AmountIncludesVAT, 
									  TabularSectionRow.Amount - (TabularSectionRow.Amount) / ((VATRate + 100) / 100),
									  TabularSectionRow.Amount * VATRate / 100);
	
EndProcedure // CalculateVATAmount() 

&AtClient
// Procedure calculates the amount in the row of tabular section.
//
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
	
	// Serial numbers
	If UseSerialNumbersBalance <> Undefined Then
		WorkWithSerialNumbersClientServer.UpdateSerialNumbersQuantity(Object, TabularSectionRow);
	EndIf;
	
EndProcedure // CalculateAmountInTabularSectionLine()	

&AtClient
// Calculates the brokerage in the row of the document tabular section
//
// Parameters:
//  TabularSectionRow - String of the document tabular sectionю
//
Procedure CalculateCommissionRemuneration(TabularSectionRow)
	
	If Object.BrokerageCalculationMethod = PredefinedValue("Enum.CommissionFeeCalculationMethods.PercentFromSaleAmount") Then
		
		TabularSectionRow.BrokerageAmount = Object.CommissionFeePercent * TabularSectionRow.Amount / 100;
		
	ElsIf Object.BrokerageCalculationMethod = PredefinedValue("Enum.CommissionFeeCalculationMethods.PercentFromDifferenceOfSaleAndAmountReceipts") Then
		
		TabularSectionRow.BrokerageAmount = Object.CommissionFeePercent * (TabularSectionRow.Amount - TabularSectionRow.AmountReceipt) / 100;
		
	Else // Enum.CommissionFeeCalculationMethods.IsNotCalculating
		
		TabularSectionRow.BrokerageAmount = 0;
		
	EndIf;
	
	VATRate = SmallBusinessReUse.GetVATRateValue(Object.VATCommissionFeePercent);
	
	TabularSectionRow.BrokerageVATAmount = ?(Object.AmountIncludesVAT, 
	TabularSectionRow.BrokerageAmount - (TabularSectionRow.BrokerageAmount) / ((VATRate + 100) / 100),
	TabularSectionRow.BrokerageAmount * VATRate / 100);
	
EndProcedure

&AtClient
// Recalculate price by document tabular section currency after changes in the "Prices and currency" form.
//
// Parameters:
//  PreviousCurrency - CatalogRef.Currencies,
//                 contains reference to the previous currency.
//
Procedure RecalculateReceiptPricesOfTabularSectionByCurrency(DocumentForm, PreviousCurrency, TabularSectionName) 
	
	RatesStructure = SmallBusinessServer.GetCurrencyRates(PreviousCurrency, DocumentForm.Object.DocumentCurrency, DocumentForm.Object.Date);
																   
	For Each TabularSectionRow IN DocumentForm.Object[TabularSectionName] Do
		
		// Price.
		If TabularSectionRow.Property("ReceiptPrice") Then
			
			TabularSectionRow.ReceiptPrice = SmallBusinessClient.RecalculateFromCurrencyToCurrency(TabularSectionRow.ReceiptPrice, 
																	RatesStructure.InitRate, 
																	RatesStructure.ExchangeRate, 
																	RatesStructure.RepetitionBeg, 
																	RatesStructure.Multiplicity);
																	
																	
			TabularSectionRow.AmountReceipt = TabularSectionRow.Quantity * TabularSectionRow.ReceiptPrice;
	
			VATRate = SmallBusinessReUse.GetVATRateValue(TabularSectionRow.VATRate);

			TabularSectionRow.ReceiptVATAmount = ?(Object.AmountIncludesVAT, 
													TabularSectionRow.AmountReceipt - (TabularSectionRow.AmountReceipt) / ((VATRate + 100) / 100),
													TabularSectionRow.AmountReceipt * VATRate / 100);														
						
		// Amount.	
		ElsIf TabularSectionRow.Property("AmountReceipt") Then
			
			TabularSectionRow.AmountReceipt = SmallBusinessClient.RecalculateFromCurrencyToCurrency(TabularSectionRow.AmountReceipt, 
																	RatesStructure.InitRate, 
																	RatesStructure.ExchangeRate, 
																	RatesStructure.RepetitionBeg, 
																	RatesStructure.Multiplicity);																												
			
			VATRate = SmallBusinessReUse.GetVATRateValue(TabularSectionRow.VATRate);
			
	        TabularSectionRow.ReceiptVATAmount = ?(DocumentForm.Object.AmountIncludesVAT, 
								  				TabularSectionRow.AmountReceipt - (TabularSectionRow.AmountReceipt) / ((VATRate + 100) / 100),
								  				TabularSectionRow.AmountReceipt * VATRate / 100);
			
		EndIf;
        		        
	EndDo; 

EndProcedure // RecalculateReceiptPricesOfTabularSectionByCurrency()

&AtClient
// Recalculate prices by the AmountIncludesVAT check box of the tabular section after changes in form "Prices and currency".
//
// Parameters:
//  PreviousCurrency - CatalogRef.Currencies,
//                 contains reference to the previous currency.
//
Procedure RecalculateTabularSectionAmountReceiptByFlagAmountIncludesVAT(DocumentForm, TabularSectionName)
																	   
	For Each TabularSectionRow IN DocumentForm.Object[TabularSectionName] Do
		
		VATRate = SmallBusinessReUse.GetVATRateValue(TabularSectionRow.VATRate);
		
		If TabularSectionRow.Property("ReceiptPrice") Then
			If DocumentForm.Object.AmountIncludesVAT Then
				TabularSectionRow.ReceiptPrice = (TabularSectionRow.ReceiptPrice * (100 + VATRate)) / 100;
			Else
				TabularSectionRow.ReceiptPrice = (TabularSectionRow.ReceiptPrice * 100) / (100 + VATRate);
			EndIf;
		EndIf;
		
		TabularSectionRow.AmountReceipt = TabularSectionRow.Quantity * TabularSectionRow.ReceiptPrice;
	
		VATRate = SmallBusinessReUse.GetVATRateValue(TabularSectionRow.VATRate);

		TabularSectionRow.ReceiptVATAmount = ?(Object.AmountIncludesVAT, 
													TabularSectionRow.AmountReceipt - (TabularSectionRow.AmountReceipt) / ((VATRate + 100) / 100),
													TabularSectionRow.AmountReceipt * VATRate / 100);
		        
	EndDo;

EndProcedure // RecalculateTabularSectionAmountReceiptByFlagAmountIncludesVAT()

&AtClient
// Procedure recalculates the rate and multiplicity of
// settlement currency when document date change.
//
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
		
		ShowQueryBox(New NotifyDescription("RecalculatePaymentCurrencyRateConversionFactorEnd", ThisObject,
			New Structure("NewUnitConversionFactor, NewExchangeRate", NewRatio, NewExchangeRate)), MessageText, Mode, 0);
		Return;
		
	EndIf;
	
	// Generate price and currency label.
	RecalculatePaymentCurrencyRateConversionFactorFragment();
EndProcedure

&AtClient
Procedure RecalculatePaymentCurrencyRateConversionFactorEnd(Result, AdditionalParameters) Export
	
	NewRatio = AdditionalParameters.NewRatio;
	NewExchangeRate = AdditionalParameters.NewExchangeRate;
	
	If Result = DialogReturnCode.Yes Then
		
		Object.ExchangeRate = NewExchangeRate;
		Object.Multiplicity = NewRatio;
		
		For Each TabularSectionRow IN Object.Prepayment Do
			TabularSectionRow.PaymentAmount = SmallBusinessClient.RecalculateFromCurrencyToCurrency(
			TabularSectionRow.SettlementsAmount,
			TabularSectionRow.ExchangeRate,
			?(Object.DocumentCurrency = NationalCurrency, RateNationalCurrency, Object.ExchangeRate),
			TabularSectionRow.Multiplicity,
			?(Object.DocumentCurrency = NationalCurrency, RepetitionNationalCurrency, Object.Multiplicity));
		EndDo;
		
	EndIf;
	
	RecalculatePaymentCurrencyRateConversionFactorFragment();
	
EndProcedure

&AtClient
Procedure RecalculatePaymentCurrencyRateConversionFactorFragment()
    
    Var LabelStructure;
    
    LabelStructure = New Structure("CounterpartyPriceKind, DocumentCurrency, SettlementsCurrency, ExchangeRate, RateNationalCurrency, AmountIncludesVAT, CurrencyTransactionsAccounting, VATTaxation", Object.CounterpartyPriceKind, Object.DocumentCurrency, SettlementsCurrency, Object.ExchangeRate, RateNationalCurrency, Object.AmountIncludesVAT, CurrencyTransactionsAccounting, Object.VATTaxation);
    PricesAndCurrency = GenerateLabelPricesAndCurrency(LabelStructure);

EndProcedure // RecalculateRateAccountCurrencyRepetition()

&AtClient
// Procedure executes recalculate in the document tabular section
// after changes in "Prices and currency" form.Column recalculation is executed:
// price, discount, amount, VAT amount, total.
//
Procedure ProcessChangesOnButtonPricesAndCurrencies(Val SettlementsCurrencyBeforeChange, RecalculatePrices = False, RefillPrices = False, WarningText = "")
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("DocumentCurrency",		Object.DocumentCurrency);
	ParametersStructure.Insert("ExchangeRate",				Object.ExchangeRate);
	ParametersStructure.Insert("Multiplicity",			Object.Multiplicity);
	ParametersStructure.Insert("VATTaxation",	Object.VATTaxation);
	ParametersStructure.Insert("AmountIncludesVAT",	Object.AmountIncludesVAT);
	ParametersStructure.Insert("IncludeVATInPrice",Object.IncludeVATInPrice);
	ParametersStructure.Insert("Counterparty",			Object.Counterparty);
	ParametersStructure.Insert("Contract",				Object.Contract);
	ParametersStructure.Insert("Company",			SubsidiaryCompany);
	ParametersStructure.Insert("DocumentDate",		Object.Date);
	ParametersStructure.Insert("RefillPrices",	RefillPrices);
	ParametersStructure.Insert("RecalculatePrices",		RecalculatePrices);
	ParametersStructure.Insert("WereMadeChanges",False);
	ParametersStructure.Insert("CounterpartyPriceKind", 	Object.CounterpartyPriceKind);
	ParametersStructure.Insert("WarningText", WarningText);
	
	NotifyDescription = New NotifyDescription("OpenPricesAndCurrencyFormEnd", ThisObject, New Structure("SettlementsCurrencyBeforeChange", SettlementsCurrencyBeforeChange));
	OpenForm("CommonForm.PricesAndCurrencyForm", ParametersStructure, ThisForm, , , , NotifyDescription, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure // ProcessChangesByButtonPricesAndCurrencies()

&AtClientAtServerNoContext
// Function returns the label text "Prices and currency".
//
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
	
	Return LabelText;
	
EndFunction // GenerateLabelPricesAndCurrency()

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
			TSRowsArray = Object.Inventory.FindRows(New Structure("ProductsAndServices,Characteristic,Batch,MeasurementUnit",BarcodeData.ProductsAndServices,BarcodeData.Characteristic,BarcodeData.Batch,BarcodeData.MeasurementUnit));
			If TSRowsArray.Count() = 0 Then
				NewRow = Object.Inventory.Add();
				NewRow.ProductsAndServices = BarcodeData.ProductsAndServices;
				NewRow.Characteristic = BarcodeData.Characteristic;
				NewRow.Batch = BarcodeData.Batch;
				NewRow.Quantity = CurBarcode.Quantity;
				NewRow.MeasurementUnit = ?(ValueIsFilled(BarcodeData.MeasurementUnit), BarcodeData.MeasurementUnit, BarcodeData.StructureProductsAndServicesData.MeasurementUnit);
				NewRow.ReceiptPrice = BarcodeData.StructureProductsAndServicesData.ReceiptPrice;
				NewRow.VATRate = BarcodeData.StructureProductsAndServicesData.VATRate;
				NewRow.AmountReceipt = NewRow.Quantity * NewRow.ReceiptPrice;
				VATRate = SmallBusinessReUse.GetVATRateValue(NewRow.VATRate);
				NewRow.ReceiptVATAmount = ?(
					Object.AmountIncludesVAT,
					NewRow.AmountReceipt
					- (NewRow.AmountReceipt)
					/ ((VATRate + 100)
					/ 100),
					NewRow.AmountReceipt
					*
					VATRate
					/ 100
				);
				CalculateAmountInTabularSectionLine(NewRow);
				CalculateCommissionRemuneration(NewRow);
				Items.Inventory.CurrentRow = NewRow.GetID();
			Else
				NewRow = TSRowsArray[0];
				NewRow.Quantity = NewRow.Quantity + CurBarcode.Quantity;
				CalculateAmountInTabularSectionLine(NewRow);
				CalculateCommissionRemuneration(NewRow);
				Items.Inventory.CurrentRow = NewRow.GetID();
			EndIf;
			
			If BarcodeData.Property("SerialNumber") AND ValueIsFilled(BarcodeData.SerialNumber) Then
				WorkWithSerialNumbersClientServer.AddSerialNumberToString(NewRow, BarcodeData.SerialNumber, Object);
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

// Procedure calls the data processor for document filling by basis.
//
&AtServer
Procedure FillByBasis(Basis)
	
	Document = FormAttributeToValue("Object");
	
	If TypeOf(Basis) = Type("CatalogRef.Counterparties") Then
	
		// Add attributes to the filling structure, that have already been specified in the document
		FillingData = New Structure();
		FillingData.Insert("Counterparty",  Basis);
		FillingData.Insert("Contract", 	 Object.Contract);
		FillingData.Insert("Company", Object.Company);
		FillingData.Insert("CounterpartyPriceKind", Object.CounterpartyPriceKind);
		Document.Filling(FillingData, );
		
	Else
		
		Document.Filling(Basis, );
		
	EndIf;
	
	ValueToFormAttribute(Document, "Object");
	Modified = True;
	
	If Object.VATTaxation = Enums.VATTaxationTypes.TaxableByVAT Then
		
		Items.InventoryVATRate.Visible = True;
		Items.InventoryVATAmount.Visible = True;
		Items.InventoryAmountTotal.Visible = True;
		
    Else
		
		Items.InventoryVATRate.Visible = False;
		Items.InventoryVATAmount.Visible = False;
		Items.InventoryAmountTotal.Visible = False;
		
     EndIf;
	
EndProcedure // FillByDocument()

// Procedure sets the contract visible depending on the parameter set to the counterparty.
//
&AtServer
Procedure SetContractVisible()
	
	CounterpartyDoSettlementsByOrders = Object.Counterparty.DoOperationsByOrders;
	Items.Contract.Visible = Object.Counterparty.DoOperationsByContracts;
	
EndProcedure // SetContractVisible()

// Checks the match of the "Company" and "ContractKind" contract attributes to the terms of the document.
//
&AtServerNoContext
Procedure CheckContractToDocumentConditionAccordance(MessageText, Contract, Document, Company, Counterparty, Cancel)
	
	If Not SmallBusinessReUse.CounterpartyContractsControlNeeded()
		OR Not Counterparty.DoOperationsByContracts Then
		
		Return;
	EndIf;
	
	ManagerOfCatalog = Catalogs.CounterpartyContracts;
	ContractKindsList = ManagerOfCatalog.GetContractKindsListForDocument(Document);
	
	If Not ManagerOfCatalog.ContractMeetsDocumentTerms(MessageText, Contract, Company, Counterparty, ContractKindsList)
		AND Constants.DoNotPostDocumentsWithIncorrectContracts.Get() Then
		
		Cancel = True;
	EndIf;
	
EndProcedure

// It gets counterparty contract selection form parameter structure.
//
&AtServerNoContext
Function GetChoiceFormParameters(Document, Company, Counterparty, Contract)
	
	ContractTypesList = Catalogs.CounterpartyContracts.GetContractKindsListForDocument(Document);
	
	FormParameters = New Structure;
	FormParameters.Insert("ControlContractChoice", Counterparty.DoOperationsByContracts);
	FormParameters.Insert("Counterparty", Counterparty);
	FormParameters.Insert("Company", Company);
	FormParameters.Insert("ContractKinds", ContractTypesList);
	FormParameters.Insert("CurrentRow", Contract);
	
	Return FormParameters;
	
EndFunction

// Gets the default contract depending on the settlements method.
//
&AtServerNoContext
Function GetContractByDefault(Document, Counterparty, Company)
	
	If Not Counterparty.DoOperationsByContracts Then
		Return Counterparty.ContractByDefault;
	EndIf;
	
	ManagerOfCatalog = Catalogs.CounterpartyContracts;
	
	ContractTypesList = ManagerOfCatalog.GetContractKindsListForDocument(Document);
	ContractByDefault = ManagerOfCatalog.GetDefaultContractByCompanyContractKind(Counterparty, Company, ContractTypesList);
	
	Return ContractByDefault;
	
EndFunction

// Performs actions when counterparty contract is changed.
//
&AtClient
Procedure ProcessContractChange(ContractData = Undefined)
	
	ContractBeforeChange = Contract;
	Contract = Object.Contract;
	
	If ContractBeforeChange <> Object.Contract Then
		
		DocumentParameters = New Structure;
		If ContractData = Undefined Then
			
			ContractData = GetDataContractOnChange(Object.Date, Object.DocumentCurrency, Object.Contract);
			
		Else
			
			DocumentParameters.Insert("CounterpartyDoSettlementsByOrdersBeforeChange", ContractData.CounterpartyDoSettlementsByOrdersBeforeChange);
			DocumentParameters.Insert("CounterpartyBeforeChange", ContractData.CounterpartyBeforeChange);
			
		EndIf;
		
		QueryBoxPrepayment = (Object.Prepayment.Count() > 0 AND Object.Contract <> ContractBeforeChange);
		
		PriceKindChanged = Object.CounterpartyPriceKind <> ContractData.CounterpartyPriceKind AND ValueIsFilled(ContractData.CounterpartyPriceKind);
		QuestionCounterpartyPriceKind = (ValueIsFilled(Object.Contract) AND PriceKindChanged);
		
		SettlementsCurrencyBeforeChange = SettlementsCurrency;
		SettlementsCurrency = ContractData.SettlementsCurrency;
		
		NewContractAndCalculationCurrency = ValueIsFilled(Object.Contract) AND ValueIsFilled(SettlementsCurrency) 
			AND Object.Contract <> ContractBeforeChange AND SettlementsCurrencyBeforeChange <> ContractData.SettlementsCurrency;
		OpenFormPricesAndCurrencies = NewContractAndCalculationCurrency AND Object.DocumentCurrency <> ContractData.SettlementsCurrency
			AND Object.Inventory.Count() > 0;
		
		DocumentParameters.Insert("ContractBeforeChange", ContractBeforeChange);
		DocumentParameters.Insert("SettlementsCurrencyBeforeChange", SettlementsCurrencyBeforeChange);
		DocumentParameters.Insert("ContractData", ContractData);
		DocumentParameters.Insert("PriceKindChanged", PriceKindChanged);
		DocumentParameters.Insert("QuestionCounterpartyPriceKind", QuestionCounterpartyPriceKind);
		DocumentParameters.Insert("OpenFormPricesAndCurrencies", OpenFormPricesAndCurrencies);
		DocumentParameters.Insert("ContractVisibleBeforeChange", Items.Contract.Visible);
		
		If QueryBoxPrepayment = True Then
			
			QuestionText = NStr("en='Prepayment setoff will be cleared, continue?';ru='Зачет предоплаты будет очищен, продолжить?';vi='Sẽ hủy việc khấu trừ khoản trả trước, tiếp tục?'");
			
			NotifyDescription = New NotifyDescription("DefineAdvancePaymentOffsetsRefreshNeed", ThisObject, DocumentParameters);
			ShowQueryBox(NOTifyDescription, QuestionText, QuestionDialogMode.YesNo);
			
		Else
			
			HandleCounterpartiesPriceKindChangeAndSettlementsCurrency(DocumentParameters);
			
		EndIf;
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// PROCEDURES FOR WORK WITH THE SELECTION

&AtClient
// Procedure - event handler Action of the Pick command
//
Procedure Pick(Command)
	
	TabularSectionName 	= "Inventory";
	
	SelectionParameters = New Structure;
	
	SelectionParameters.Insert("Period", 				Object.Date);
	SelectionParameters.Insert("Company", 			SubsidiaryCompany);
	SelectionParameters.Insert("VATTaxation",	   	Object.VATTaxation);
	SelectionParameters.Insert("CounterpartyPriceKind", 		Object.CounterpartyPriceKind);
	SelectionParameters.Insert("Currency", 				Object.DocumentCurrency);
	SelectionParameters.Insert("AmountIncludesVAT", 		Object.AmountIncludesVAT);
	SelectionParameters.Insert("DocumentOrganization", 	Object.Company);
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
		
	BatchStatus = New ValueList;
	For Each ArrayElement IN Items[TabularSectionName + "Batch"].ChoiceParameters Do
		If ArrayElement.Name = "Filter.Status" Then
			If TypeOf(ArrayElement.Value) = Type("FixedArray") Then
				For Each FixArrayItem IN ArrayElement.Value Do
					BatchStatus.Add(FixArrayItem);
				EndDo; 
			Else
				BatchStatus.Add(ArrayElement.Value);
			EndIf;
		EndIf;
	EndDo;
	
	SelectionParameters.Insert("BatchStatus", BatchStatus);
	
	SelectionParameters.Insert("OwnerFormUUID", UUID);
	
	OpenForm("CommonForm.PickForm", SelectionParameters, ThisForm);
	
EndProcedure // ExecutePick()

// Procedure - event handler Action of the command Pick of sales.
//
&AtClient
Procedure SelectionBySales(Command)
	
	Cancel = False;
	
	If Not ValueIsFilled(Object.Company) Then
		MessageText = NStr("en='Company is not filled in';ru='Поле ""Организация"" не заполнено';vi='Chưa điền trường ""Doanh nghiệp""'");
		SmallBusinessClient.ShowMessageAboutError(ThisForm, MessageText,,, "Company", Cancel);
	EndIf;
	If Not ValueIsFilled(Object.Counterparty) Then
		MessageText = NStr("en='Counterparty is not filled in';ru='Поле ""Контрагент"" не заполнено';vi='Chưa điền trường ""Đối tác""'");
		SmallBusinessClient.ShowMessageAboutError(ThisForm, MessageText,,, "Counterparty", Cancel);
	EndIf;
	If Not ValueIsFilled(Object.Contract) Then
		MessageText = NStr("en='Contract is not filled in.';ru='Поле ""Договор"" не заполнено';vi='Chưa điền trường ""Hợp đồng""'");
		SmallBusinessClient.ShowMessageAboutError(ThisForm, MessageText,,, "Contract", Cancel);
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	SelectionParameters = New Structure("
		|SubsidiaryCompany,
		|Company,
		|Counterparty,
		|Contract,
		|DocumentCurrency,
		|CounterpartyPriceKind,
		|DocumentDate,
		|CurrentDocument",
		SubsidiaryCompany,
		Object.Company,
		Object.Counterparty,
		Object.Contract,
		Object.DocumentCurrency,
		Object.CounterpartyPriceKind,
		Object.Date,
		Object.Ref
	);
	
	OpenForm("Document.ReportToPrincipal.Form.PickFormBySales", SelectionParameters, ThisForm);
	
EndProcedure // SelectionBySales()

&AtServer
// Function gets a product list from the temporary storage
//
Procedure GetInventoryFromStorage(InventoryAddressInStorage, TabularSectionName, AreCharacteristics, AreBatches)
	
	TableForImport = GetFromTempStorage(InventoryAddressInStorage);
	
	For Each ImportRow IN TableForImport Do
		
		NewRow 					= Object[TabularSectionName].Add();
		NewRow.ReceiptPrice 	= ImportRow.Price;
		NewRow.AmountReceipt 	= ImportRow.Amount;
		NewRow.ReceiptVATAmount = ImportRow.VATAmount;
		
		ImportRow.Price 	= 0;
		ImportRow.Amount 	= 0;
		ImportRow.VATAmount = 0;
		ImportRow.Total 	= 0;
		
		FillPropertyValues(NewRow, ImportRow);
		
	EndDo;
	
EndProcedure // GetInventoryFromStorage()

// Function gets the list of inventory accepted from the temporary storage
//
&AtServer
Procedure GetInventoryAcceptedFromStorage(AddressInventoryAcceptedInStorage)
	
	InventoryReceived = GetFromTempStorage(AddressInventoryAcceptedInStorage);
	
	For Each TabularSectionRow IN InventoryReceived Do
		
		NewRow = Object.Inventory.Add();
		FillPropertyValues(NewRow, TabularSectionRow);
		
		StructureData = New Structure;
		StructureData.Insert("Company", Object.Company);
		StructureData.Insert("ProductsAndServices", TabularSectionRow.ProductsAndServices);
		StructureData.Insert("VATTaxation", Object.VATTaxation);
		
		StructureData = GetDataProductsAndServicesOnChange(StructureData);
		
		NewRow.MeasurementUnit = StructureData.MeasurementUnit;
		NewRow.VATRate = StructureData.VATRate;
		
		If TabularSectionRow.Quantity > TabularSectionRow.Balance
			OR TabularSectionRow.Quantity = 0 Then
			NewRow.Price = 0;
			NewRow.Amount = 0;
			NewRow.ReceiptPrice = 0;
		ElsIf TabularSectionRow.Quantity < TabularSectionRow.Balance Then
			NewRow.Amount = NewRow.Price * NewRow.Quantity;
		EndIf;
		NewRow.AmountReceipt = NewRow.ReceiptPrice * NewRow.Quantity;
		
		VATRate = SmallBusinessReUse.GetVATRateValue(NewRow.VATRate);
		
		NewRow.VATAmount = ?(Object.AmountIncludesVAT,
								NewRow.Amount - (NewRow.Amount) / ((VATRate + 100) / 100),
								NewRow.Amount * VATRate / 100);
								
		If Object.VATTaxation = Enums.VATTaxationTypes.TaxableByVAT Then
			VATAmount = ?(Object.AmountIncludesVAT, 0, TabularSectionRow.VATAmount);
		Else
			VATAmount = 0
		EndIf;
		NewRow.Total = TabularSectionRow.Amount + VATAmount;
		
		NewRow.ReceiptVATAmount = ?(Object.AmountIncludesVAT,
											NewRow.AmountReceipt - (NewRow.AmountReceipt) / ((VATRate + 100) / 100),
											NewRow.AmountReceipt * VATRate / 100);
		
		If Object.BrokerageCalculationMethod = PredefinedValue("Enum.CommissionFeeCalculationMethods.IsNotCalculating") Then
		ElsIf Object.BrokerageCalculationMethod = PredefinedValue("Enum.CommissionFeeCalculationMethods.PercentFromSaleAmount") Then
			NewRow.BrokerageAmount = Object.CommissionFeePercent * NewRow.Amount / 100;
		ElsIf Object.BrokerageCalculationMethod = PredefinedValue("Enum.CommissionFeeCalculationMethods.PercentFromDifferenceOfSaleAndAmountReceipts") Then
			NewRow.BrokerageAmount = Object.CommissionFeePercent * (NewRow.Amount - NewRow.AmountReceipt) / 100;
		Else
			NewRow.BrokerageAmount = 0;
		EndIf;
		VATRate = SmallBusinessReUse.GetVATRateValue(Object.VATCommissionFeePercent);
		NewRow.BrokerageVATAmount = ?(Object.AmountIncludesVAT,
												NewRow.BrokerageAmount - (NewRow.BrokerageAmount) / ((VATRate + 100) / 100),
												NewRow.BrokerageAmount * VATRate / 100);
		
	EndDo;
	
EndProcedure // GetInventoryAcceptedFromStorage()

&AtServer
// Function places the list of advances into temporary storage and returns the address
//
Function PlacePrepaymentToStorage()
	
	Return PutToTempStorage(
		Object.Prepayment.Unload(,
			"Document,
			|Order,
			|SettlementsAmount,
			|ExchangeRate,
			|Multiplicity,
			|PaymentAmount"),
		UUID
	);
	
EndFunction // PlacePrepaymentToStorage()

&AtServer
// Function gets the list of advances from the temporary storage
//
Procedure GetPrepaymentFromStorage(AddressPrepaymentInStorage)
	
	TableForImport = GetFromTempStorage(AddressPrepaymentInStorage);
	Object.Prepayment.Load(TableForImport);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - FORM EVENT HANDLERS

&AtServer
// Procedure - OnCreateAtServer event handler.
//
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
			Object.ExchangeRate      = ?(SettlementsCurrencyRateRepetition.ExchangeRate = 0, 1, SettlementsCurrencyRateRepetition.ExchangeRate);
			Object.Multiplicity = ?(SettlementsCurrencyRateRepetition.Multiplicity = 0, 1, SettlementsCurrencyRateRepetition.Multiplicity);
			Object.CounterpartyPriceKind = Object.Contract.CounterpartyPriceKind;
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
	
	If Not ValueIsFilled(Object.Ref)
		AND Not ValueIsFilled(Parameters.Basis) 
		AND Not ValueIsFilled(Parameters.CopyingValue) Then
		FillVATRateByVATTaxation();
	ElsIf Object.VATTaxation = Enums.VATTaxationTypes.TaxableByVAT Then	
		Items.InventoryVATRate.Visible = True;
		Items.InventoryVATAmount.Visible = True;
		Items.InventoryAmountTotal.Visible = True;
		Items.InventoryVATSummOfArrival.Visible = True;
	Else
		Items.InventoryVATRate.Visible = False;
		Items.InventoryVATAmount.Visible = False;
		Items.InventoryAmountTotal.Visible = False;
		Items.InventoryVATSummOfArrival.Visible = False;
	EndIf;
	
	// Generate price and currency label.
	CurrencyTransactionsAccounting = Constants.FunctionalCurrencyTransactionsAccounting.Get();
	LabelStructure = New Structure("CounterpartyPriceKind, DocumentCurrency, SettlementsCurrency, ExchangeRate, RateNationalCurrency, AmountIncludesVAT, CurrencyTransactionsAccounting, VATTaxation", Object.CounterpartyPriceKind, Object.DocumentCurrency, SettlementsCurrency, Object.ExchangeRate, RateNationalCurrency, Object.AmountIncludesVAT, CurrencyTransactionsAccounting, Object.VATTaxation);
	PricesAndCurrency = GenerateLabelPricesAndCurrency(LabelStructure);
	
	Object.VATCommissionFeePercent = SubsidiaryCompany.DefaultVATRate;
	
	Items.CommissionFeePercent.Enabled = Not (Object.BrokerageCalculationMethod = PredefinedValue("Enum.CommissionFeeCalculationMethods.IsNotCalculating"));
	
	// Setting contract visible.
	SetContractVisible();
	
	SmallBusinessClientServer.SetPictureForComment(Items.GroupAdditional, Object.Comment);
	
	// StandardSubsystems.AdditionalReportsAndDataProcessors
	AdditionalReportsAndDataProcessors.OnCreateAtServer(ThisForm);
	// End StandardSubsystems.AdditionalReportsAndDataProcessors
	
	// StandardSubsystems.Printing
	PrintManagement.OnCreateAtServer(ThisForm, Items.ImportantCommandsGroup);
	// End StandardSubsystems.Printing
	
	// Peripherals
	UsePeripherals = SmallBusinessReUse.UsePeripherals();
	ListOfElectronicScales = EquipmentManagerServerCall.GetEquipmentList("ElectronicScales", , EquipmentManagerServerCall.GetClientWorkplace());
	If ListOfElectronicScales.Count() = 0 Then
		// There are no connected scales.
		Items.InventoryGetWeight.Visible = False;
	EndIf;
	Items.InventoryImportDataFromDCT.Visible = UsePeripherals;
	// End Peripherals
	
	TSNames = New Array;
	TSNames.Add(New Structure("CheckFieldName, AppearanceFieldName", "Object.Inventory.CountryOfOrigin", "InventoryCCDNo"));
	
	CargoCustomsDeclarationsServer.OnCreateAtServer(ThisForm, TSNames, CashValues);

EndProcedure // OnCreateAtServer()

// Procedure - OnReadAtServer event handler.
//
&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	ChangeProhibitionDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
EndProcedure // OnReadAtServer()

// Procedure-handler of the BeforeWriteAtServer event.
//
&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		
		MessageText = "";
		CheckContractToDocumentConditionAccordance(MessageText, Object.Contract, Object.Ref, Object.Company, Object.Counterparty, Cancel);
		
		If MessageText <> "" Then
			
			Message = New UserMessage;
			Message.Text = ?(Cancel, NStr("en='Document is not posted! ';ru='Документ не проведен! ';vi='Chứng từ chưa được kết chuyển!'") + MessageText, MessageText);
			
			If Cancel Then
				Message.DataPath = "Object";
				Message.Field = "Contract";
				Message.Message();
				Return;
			Else
				Message.Message();
			EndIf;
		EndIf;
		
		If SmallBusinessReUse.GetAdvanceOffsettingSettingValue() = Enums.YesNo.Yes
			AND CurrentObject.Prepayment.Count() = 0 Then
			FillPrepayment(CurrentObject);
		EndIf;
		
	EndIf;
	
EndProcedure // BeforeWriteAtServer()

// Procedure fills advances.
//
&AtServer
Procedure FillPrepayment(CurrentObject)
	
	CurrentObject.FillPrepayment();
	
EndProcedure // FillPrepayment()

&AtClient
// Procedure - event handler AfterWriting.
//
Procedure AfterWrite(WriteParameters)
	
	Notify("NotificationAboutChangingDebt");
	
EndProcedure // AfterWrite()

&AtClient
// Procedure - event handler OnOpen.
//
Procedure OnOpen(Cancel)
	
	// Peripherals
	EquipmentManagerClientOverridable.StartConnectingEquipmentOnFormOpen(ThisForm, "BarCodeScanner");
	// End Peripherals
	
EndProcedure // OnOpen()

&AtClient
// Procedure - event handler OnClose.
//
Procedure OnClose()
	
	// Peripherals
	EquipmentManagerClientOverridable.StartDisablingEquipmentOnCloseForm(ThisForm);
	// End Peripherals
	
EndProcedure // OnClose()

&AtClient
// Procedure - event handler of the form NotificationProcessing.
//
Procedure NotificationProcessing(EventName, Parameter, Source)
	
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
		
		InventoryAddressInStorage = Parameter;
		
		GetInventoryFromStorage(InventoryAddressInStorage, "Inventory", True, True);
		
	ElsIf EventName = "SerialNumbersSelection"
		AND ValueIsFilled(Parameter)
		//Form owner checkup
		AND Source <> New UUID("00000000-0000-0000-0000-000000000000")
		AND Source = UUID
		Then
		
		ChangedCount = GetSerialNumbersFromStorage(Parameter.AddressInTemporaryStorage, Parameter.RowKey);
		If ChangedCount Then
			CalculateAmountInTabularSectionLine();
		EndIf;
		
	EndIf;
	
EndProcedure // NotificationProcessing()

// Procedure - selection handler.
//
&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "Document.ReportToPrincipal.Form.PickFormBySales" Then
		
		GetInventoryAcceptedFromStorage(ValueSelected);
		
	EndIf;
	
EndProcedure

// Procedure is called when clicking the "FillByCounterparty" button 
//
&AtClient
Procedure FillByCounterparty(Command)
	ShowQueryBox(New NotifyDescription("FillByCounterpartyEnd", ThisObject), NStr("en='The document will be fully filled out. Continue?';ru='Документ будет полностью перезаполнен! Продолжить?';vi='Chứng từ sẽ được điền lại đầy đủ! Tiếp tục?'"), QuestionDialogMode.YesNo, 0);
EndProcedure

&AtClient
Procedure FillByCounterpartyEnd(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		FillByBasis(Object.Counterparty);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - ACTIONS OF THE FORM COMMAND PANELS

&AtClient
// Procedure is called by clicking the PricesCurrency button of the command bar tabular field.
//
Procedure EditPricesAndCurrency(Item, StandardProcessing)
	
	StandardProcessing = False;
	ProcessChangesOnButtonPricesAndCurrencies(Object.DocumentCurrency);
	Modified = True;
	
EndProcedure // EditPricesAndCurrency()

&AtClient
// Procedure - command handler of the tabular section command panel.
//
Procedure EditPrepaymentOffset(Command)
	
	If Not ValueIsFilled(Object.Counterparty) Then
		ShowMessageBox(, NStr("en='Specify the counterparty first.';ru='Укажите вначале контрагента!';vi='Trước tiên, hãy chỉ ra đối tác!'"));
		Return;
	EndIf;
	
	If Not ValueIsFilled(Object.Contract) Then
		ShowMessageBox(, NStr("en='Specify the counterparty contract first.';ru='Укажите вначале договор контрагента!';vi='Trước tiên, hãy chỉ ra hợp đồng với đối tác!'"));
		Return;
	EndIf;
	
	OrdersArray = New Array;
	For Each CurItem IN Object.Inventory Do
		OrderStructure = New Structure("Order, Total");
		OrderStructure.Order = CurItem.PurchaseOrder;
		OrderStructure.Total = CurItem.Total;
		OrdersArray.Add(OrderStructure);
	EndDo;
	
	AddressPrepaymentInStorage = PlacePrepaymentToStorage();
	SelectionParameters = New Structure(
		"AddressPrepaymentInStorage,
		|Pick,
		|IsOrder,
		|OrderInHeader,
		|Company,
		|Order,
		|Date,
		|Ref,
		|Counterparty,
		|Contract,
		|ExchangeRate,
		|Multiplicity,
		|DocumentCurrency,
		|DocumentAmount",
		AddressPrepaymentInStorage, // AddressPrepaymentInStorage
		True, // Pick
		True, // IsOrder
		False, // OrderInHeader
		SubsidiaryCompany, // Company
		?(CounterpartyDoSettlementsByOrders, OrdersArray, Undefined), // Order
		Object.Date, // Date
		Object.Ref, // Ref
		Object.Counterparty, // Counterparty
		Object.Contract, // Contract
		Object.ExchangeRate, // ExchangeRate
		Object.Multiplicity, // Multiplicity
		Object.DocumentCurrency, // DocumentCurrency
		Object.Inventory.Total("Total") // DocumentAmount
	);
	
	ReturnCode = Undefined;

	
	OpenForm("CommonForm.SupplierAdvancesPickForm", SelectionParameters,,,,, New NotifyDescription("EditPrepaymentOffsetEnd", ThisObject, New Structure("AddressPrepaymentInStorage", AddressPrepaymentInStorage)));
	
EndProcedure

&AtClient
Procedure EditPrepaymentOffsetEnd(Result, AdditionalParameters) Export
    
    AddressPrepaymentInStorage = AdditionalParameters.AddressPrepaymentInStorage;
    
    
    ReturnCode = Result;
    
    If ReturnCode = DialogReturnCode.OK Then
        GetPrepaymentFromStorage(AddressPrepaymentInStorage);
    EndIf;

EndProcedure // EditPrepaymentOffset()

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
			CalculateAmountInTabularSectionLine(TabularSectionRow);
			
			// Amount of income.
			TabularSectionRow.AmountReceipt = TabularSectionRow.ReceiptPrice * TabularSectionRow.Quantity;
			
			VATRate = SmallBusinessReUse.GetVATRateValue(TabularSectionRow.VATRate);
			TabularSectionRow.ReceiptVATAmount = ?(
				Object.AmountIncludesVAT, 
				TabularSectionRow.AmountReceipt - (TabularSectionRow.AmountReceipt) / ((VATRate + 100) / 100),
				TabularSectionRow.AmountReceipt * VATRate / 100
			);
			
			// Amount of brokerage
			CalculateCommissionRemuneration(TabularSectionRow);
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

////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - EVENT HANDLERS OF HEADER ATTRIBUTES

&AtClient
// Procedure - event handler OnChange of the Date input field.
// IN procedure situation is determined when date change document is
// into document numbering another period and in this case
// assigns to the document new unique number.
// Overrides the corresponding form parameter.
//
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

&AtClient
// Procedure - event handler OnChange of the Company input field.
// IN procedure is executed document
// number clearing and also make parameter set of the form functional options.
// Overrides the corresponding form parameter.
//
Procedure CompanyOnChange(Item)

	// Company change event data processor.
	Object.Number = "";
	StructureData = GetCompanyDataOnChange(Object.Company);
	SubsidiaryCompany = StructureData.Company;
	Object.VATCommissionFeePercent = StructureData.VATRate;
	
	Object.Contract = GetContractByDefault(Object.Ref, Object.Counterparty, Object.Company);
	ProcessContractChange();
	
EndProcedure // CompanyOnChange()

&AtClient
// Procedure - event handler OnChange of the BrokerageCalculationMethod input field.
//
Procedure BrokerageCalculationMethodOnChange(Item)
	
	NeedToRecalculate = False;
	If Object.BrokerageCalculationMethod = PredefinedValue("Enum.CommissionFeeCalculationMethods.IsNotCalculating")
		And ValueIsFilled(Object.CommissionFeePercent) Then
		
		Object.CommissionFeePercent = 0;
		If Object.Inventory.Count() > 0 And Object.Inventory.Total("BrokerageAmount") > 0 Then
			NeedToRecalculate = True;
		EndIf;
		
	EndIf;
	
	If NeedToRecalculate Or (Object.BrokerageCalculationMethod <> PredefinedValue("Enum.CommissionFeeCalculationMethods.IsNotCalculating")
		And ValueIsFilled(Object.CommissionFeePercent) And Object.Inventory.Count() > 0) Then
		
		ShowQueryBox(New NotifyDescription("BrokerageCalculationMethodOnChangeEnd", ThisObject),
			NStr("en='Calculation method has been changed. Do you want to recalculate the brokerage?';ru='Изменился способ расчета. Пересчитать комиссионное вознаграждение?';vi='Đã thay đổi phương pháp tính hoa hồng. Tính lại hoa hồng?'"),
			QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
		
	EndIf;
	
	Items.CommissionFeePercent.Enabled = Not (Object.BrokerageCalculationMethod = PredefinedValue("Enum.CommissionFeeCalculationMethods.IsNotCalculating"));
	
EndProcedure

&AtClient
Procedure BrokerageCalculationMethodOnChangeEnd(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		For Each TabularSectionRow IN Object.Inventory Do
			CalculateCommissionRemuneration(TabularSectionRow);
		EndDo;
	EndIf; 
	
EndProcedure

&AtClient
// Procedure - handler of the OnChange event of the BrokerageVATRate input field.
//
Procedure VATCommissionFeePercentOnChange(Item)
	
	If Object.Inventory.Count() = 0 Then
		Return;
	EndIf;
	
	ShowQueryBox(New NotifyDescription("BrokerageVATRateOnChangeEnd", ThisObject), "Do you want to recalculate VAT amounts of remuneration?",
		QuestionDialogMode.YesNo, , DialogReturnCode.No);
	
EndProcedure

&AtClient
Procedure BrokerageVATRateOnChangeEnd(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.No Then
		Return;
	EndIf;
	
	VATRate = SmallBusinessReUse.GetVATRateValue(Object.VATCommissionFeePercent);
	
	For Each TabularSectionRow IN Object.Inventory Do
		
		TabularSectionRow.BrokerageVATAmount = ?(Object.AmountIncludesVAT, 
		TabularSectionRow.BrokerageAmount - (TabularSectionRow.BrokerageAmount) / ((VATRate + 100) / 100),
		TabularSectionRow.BrokerageAmount * VATRate / 100);
		
	EndDo;
	
EndProcedure

&AtClient
// Procedure - event handler OnChange of the BrokeragePercent.
//
Procedure CommissionFeePercentOnChange(Item)
	
	If Object.Inventory.Count() > 0 Then
		ShowQueryBox(New NotifyDescription("BrokeragePercentOnChangeEnd", ThisObject), 
			NStr("en='Brokerage percent has been changed. Recalculate the brokerage?';ru='Изменился процент вознаграждения. Пересчитать комиссионное вознаграждение?';vi='Đã thay đổi phần trăm hoa hồng. Tính lại hoa hồng?'"),
			QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
	EndIf;
	
EndProcedure

&AtClient
Procedure BrokeragePercentOnChangeEnd(Result, AdditionalParameters) Export
	
	// We must offer to recalculate brokerage.
	If Result = DialogReturnCode.Yes Then
		For Each TabularSectionRow IN Object.Inventory Do
			CalculateCommissionRemuneration(TabularSectionRow);
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
// Procedure - event handler OnChange of the Counterparty input field.
// Clears the contract and tabular section.
//
Procedure CounterpartyOnChange(Item)
	
	CounterpartyBeforeChange = Counterparty;
	Counterparty = Object.Counterparty;
	CounterpartyDoSettlementsByOrdersBeforeChange = CounterpartyDoSettlementsByOrders;
	
	If CounterpartyBeforeChange <> Object.Counterparty Then
		
		StructureData = GetDataCounterpartyOnChange(Object.Date, Object.DocumentCurrency, Object.Counterparty, Object.Company);
		Object.Contract = StructureData.Contract;
		
		StructureData.Insert("CounterpartyDoSettlementsByOrdersBeforeChange", CounterpartyDoSettlementsByOrdersBeforeChange);
		StructureData.Insert("CounterpartyBeforeChange", CounterpartyBeforeChange);
		
		ProcessContractChange(StructureData);
		
	Else
		
		Object.Contract = Contract; // Restore the cleared contract automatically.
		
	EndIf;
	
EndProcedure

&AtClient
// Procedure - event handler OnChange of the Contract input field.
// Fills form attributes - exchange rate and multiplicity.
//
Procedure ContractOnChange(Item)
	
	ProcessContractChange();
	
EndProcedure // ContractOnChange()

// Procedure - event handler StartChoice of the Contract input field.
//
&AtClient
Procedure ContractStartChoice(Item, ChoiceData, StandardProcessing)
	
	FormParameters = GetChoiceFormParameters(Object.Ref, Object.Company, Object.Counterparty, Object.Contract);
	If FormParameters.ControlContractChoice Then
		
		StandardProcessing = False;
		OpenForm("Catalog.CounterpartyContracts.Form.ChoiceForm", FormParameters, Item);
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////PROCEDURE - TABULAR SECTION ATTRIBUTE EVENT HANDLERS

&AtClient
// Procedure - event handler OnChange of the ProductsAndServices input field.
//
Procedure InventoryProductsAndServicesOnChange(Item)
	
	TabularSectionRow = Items.Inventory.CurrentData;
	
	StructureData = New Structure;
	StructureData.Insert("Company", Object.Company);
	StructureData.Insert("ProductsAndServices", TabularSectionRow.ProductsAndServices);
	StructureData.Insert("VATTaxation", Object.VATTaxation);
	
	If ValueIsFilled(Object.CounterpartyPriceKind) Then
		
		StructureData.Insert("ProcessingDate", Object.Date);
		StructureData.Insert("CounterpartyPriceKind", Object.CounterpartyPriceKind);
		StructureData.Insert("DocumentCurrency", Object.DocumentCurrency);
		StructureData.Insert("AmountIncludesVAT", Object.AmountIncludesVAT);
		StructureData.Insert("Characteristic", TabularSectionRow.Characteristic);
		StructureData.Insert("Factor", 1);
		
	EndIf;
	
	StructureData = GetDataProductsAndServicesOnChange(StructureData);
	
	FillPropertyValues(TabularSectionRow, StructureData);
	
	TabularSectionRow.Quantity = 1;
	TabularSectionRow.Price = 0;
	
	TabularSectionRow.AmountReceipt = TabularSectionRow.Quantity * TabularSectionRow.ReceiptPrice;
	
	VATRate = SmallBusinessReUse.GetVATRateValue(TabularSectionRow.VATRate);
	
	TabularSectionRow.ReceiptVATAmount = ?(
		Object.AmountIncludesVAT,
		TabularSectionRow.AmountReceipt
		- (TabularSectionRow.AmountReceipt)
		/ ((VATRate + 100)
		/ 100),
		TabularSectionRow.AmountReceipt
		* VATRate
		/ 100
	);
	
	CalculateAmountInTabularSectionLine();
	CalculateCommissionRemuneration(TabularSectionRow);
	
	//Serial numbers
	WorkWithSerialNumbersClientServer.DeleteSerialNumbersByConnectionKey(Object.SerialNumbers, TabularSectionRow, , UseSerialNumbersBalance);
	
EndProcedure // InventoryProductsAndServicesOnChange()

&AtClient
// Procedure - event handler OnChange of the Characteristic input field.
//
Procedure InventoryCharacteristicOnChange(Item)
	
	If ValueIsFilled(Object.CounterpartyPriceKind) Then
	
		TabularSectionRow = Items.Inventory.CurrentData;
		
		StructureData = New Structure;
		StructureData.Insert("ProcessingDate",		Object.Date);
		StructureData.Insert("CounterpartyPriceKind",	Object.CounterpartyPriceKind);
		StructureData.Insert("DocumentCurrency",		Object.DocumentCurrency);
		StructureData.Insert("AmountIncludesVAT",	Object.AmountIncludesVAT);
		
		StructureData.Insert("VATRate", 		 	TabularSectionRow.VATRate);
		StructureData.Insert("ProductsAndServices",		TabularSectionRow.ProductsAndServices);
		StructureData.Insert("Characteristic",		TabularSectionRow.Characteristic);
		StructureData.Insert("MeasurementUnit",	TabularSectionRow.MeasurementUnit);
		StructureData.Insert("ReceiptPrice",		TabularSectionRow.ReceiptPrice);
		
		StructureData = GetDataCharacteristicOnChange(StructureData);
		
		TabularSectionRow.ReceiptPrice = StructureData.ReceiptPrice;
		
		TabularSectionRow.AmountReceipt = TabularSectionRow.Quantity * TabularSectionRow.ReceiptPrice;
	
		VATRate = SmallBusinessReUse.GetVATRateValue(TabularSectionRow.VATRate);

		TabularSectionRow.ReceiptVATAmount = ?(Object.AmountIncludesVAT, 
													TabularSectionRow.AmountReceipt - (TabularSectionRow.AmountReceipt) / ((VATRate + 100) / 100),
													TabularSectionRow.AmountReceipt * VATRate / 100);
    		
        CalculateAmountInTabularSectionLine();
		CalculateCommissionRemuneration(TabularSectionRow);
		
	EndIf;
	
EndProcedure // InventoryCharacteristicOnChange()

&AtClient
// Procedure - event handler OnChange of the Count input field.
//
Procedure InventoryQuantityOnChange(Item)
	
	CalculateAmountInTabularSectionLine();
	
	TabularSectionRow = Items.Inventory.CurrentData;
	
	// Amount of income.
	TabularSectionRow.AmountReceipt = TabularSectionRow.ReceiptPrice * TabularSectionRow.Quantity;
	
	VATRate = SmallBusinessReUse.GetVATRateValue(TabularSectionRow.VATRate);
	
	TabularSectionRow.ReceiptVATAmount = ?(Object.AmountIncludesVAT, 
													TabularSectionRow.AmountReceipt - (TabularSectionRow.AmountReceipt) / ((VATRate + 100) / 100),
													TabularSectionRow.AmountReceipt * VATRate / 100);
	// Amount of brokerage
	CalculateCommissionRemuneration(TabularSectionRow);
	
EndProcedure // InventoryQuantityOnChange()

&AtClient
// Procedure - event handler ChoiceProcessing of the MeasurementUnit input field.
//
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
	CalculateCommissionRemuneration(TabularSectionRow);
	
EndProcedure // InventoryMeasurementUnitChoiceProcessing()

&AtClient
// Procedure - event handler OnChange of the Price input field.
//
Procedure InventoryPriceOnChange(Item)
	
	CalculateAmountInTabularSectionLine();
	
	TabularSectionRow = Items.Inventory.CurrentData;
	CalculateCommissionRemuneration(TabularSectionRow);
	
EndProcedure // InventoryPriceOnChange()

&AtClient
// Procedure - event handler OnChange of the Amount input field.
//
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
	
	// Amount of brokerage
	CalculateCommissionRemuneration(TabularSectionRow);
	
EndProcedure // InventoryAmountOnChange()

&AtClient
// Procedure - event handler OnChange of the VATRate input field.
//
Procedure InventoryVATRateOnChange(Item)
	
	TabularSectionRow = Items.Inventory.CurrentData;
	
	// VAT amount.
	CalculateVATSUM(TabularSectionRow);
	
	// Total.
	TabularSectionRow.Total = TabularSectionRow.Amount + ?(Object.AmountIncludesVAT, 0, TabularSectionRow.VATAmount);
	
	VATRate = SmallBusinessReUse.GetVATRateValue(TabularSectionRow.VATRate);
			
	TabularSectionRow.ReceiptVATAmount = ?(Object.AmountIncludesVAT, 
													TabularSectionRow.AmountReceipt - (TabularSectionRow.AmountReceipt) / ((VATRate + 100) / 100),
													TabularSectionRow.AmountReceipt * VATRate / 100);
	
EndProcedure // InventoryVATRateOnChange()

&AtClient
// Procedure - event handler OnChange of the VATRate input field.
//
Procedure InventoryVATAmountOnChange(Item)
	
	TabularSectionRow = Items.Inventory.CurrentData;
	
	// Total.
	TabularSectionRow.Total = TabularSectionRow.Amount + ?(Object.AmountIncludesVAT, 0, TabularSectionRow.VATAmount);
	
EndProcedure // InventoryVATAmountOnChange()

&AtClient
// Procedure - event handler OnChange of the ReceiptPrice input field.
//
Procedure InventoryReceiptPriceOnChange(Item)
	
	TabularSectionRow = Items.Inventory.CurrentData;
	
	// Amount of income.
	TabularSectionRow.AmountReceipt = TabularSectionRow.Quantity * TabularSectionRow.ReceiptPrice;
	
	VATRate = SmallBusinessReUse.GetVATRateValue(TabularSectionRow.VATRate);
			
	TabularSectionRow.ReceiptVATAmount = ?(Object.AmountIncludesVAT, 
													TabularSectionRow.AmountReceipt - (TabularSectionRow.AmountReceipt) / ((VATRate + 100) / 100),
													TabularSectionRow.AmountReceipt * VATRate / 100);
	
	// Amount of brokerage
	CalculateCommissionRemuneration(TabularSectionRow);
	
EndProcedure // InventoryReceiptPriceOnChange()

&AtClient
// Procedure - event handler OnChange of the AmountReceipt input field.
//
Procedure InventoryAmountReceiptOnChange(Item)
	
	TabularSectionRow = Items.Inventory.CurrentData;
	
	// Price.
	If TabularSectionRow.Quantity <> 0 Then
		TabularSectionRow.ReceiptPrice = TabularSectionRow.AmountReceipt / TabularSectionRow.Quantity;
	EndIf;
	
	// VAT amount received.
	VATRate = SmallBusinessReUse.GetVATRateValue(TabularSectionRow.VATRate);
			
	TabularSectionRow.ReceiptVATAmount = ?(Object.AmountIncludesVAT, 
													TabularSectionRow.AmountReceipt - (TabularSectionRow.AmountReceipt) / ((VATRate + 100) / 100),
													TabularSectionRow.AmountReceipt * VATRate / 100);
		
	// Amount of brokerage
	CalculateCommissionRemuneration(TabularSectionRow);

EndProcedure // InventoryAmountReceiptOnChange

&AtClient
// Procedure - event handler OnChange of the BrokerageAmount input field.
//
Procedure InventoryBrokerageAmountOnChange(Item)
	
	TabularSectionRow = Items.Inventory.CurrentData;
	
	VATRate = SmallBusinessReUse.GetVATRateValue(Object.VATCommissionFeePercent);
			
	TabularSectionRow.BrokerageVATAmount = ?(Object.AmountIncludesVAT, 
													TabularSectionRow.BrokerageAmount - (TabularSectionRow.BrokerageAmount) / ((VATRate + 100) / 100),
													TabularSectionRow.BrokerageAmount * VATRate / 100);
	
EndProcedure // InventoryBrokerageAmountOnChange(Item)

&AtClient
Procedure InventorySerialNumbersStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSerialNumbersSelection();

EndProcedure

&AtClient
Procedure InventoryBeforeDeleteRow(Item, Cancel)
	
	// Serial numbers
	CurrentData = Items.Inventory.CurrentData;
	WorkWithSerialNumbersClientServer.DeleteSerialNumbersByConnectionKey(Object.SerialNumbers, CurrentData, , UseSerialNumbersBalance);
	
EndProcedure

&AtClient
Procedure InventoryOnStartEdit(Item, NewRow, Clone)
	
	If NewRow AND Clone Then
		Item.CurrentData.ConnectionKey = 0;
		Item.CurrentData.SerialNumbers = "";
	EndIf;	
	
	If Item.CurrentItem.Name = "InventorySerialNumbers" Then
		OpenSerialNumbersSelection();
	EndIf;
	
EndProcedure

&AtClient
Procedure PrepaymentAccountsAmountOnChange(Item)
	
	TabularSectionRow = Items.Prepayment.CurrentData;
		
	TabularSectionRow.ExchangeRate = ?(
		TabularSectionRow.ExchangeRate = 0,
			?(Object.ExchangeRate = 0,
			1,
			Object.ExchangeRate),
		TabularSectionRow.ExchangeRate
	);
	
	TabularSectionRow.Multiplicity = ?(
		TabularSectionRow.Multiplicity = 0,
			?(Object.Multiplicity = 0,
			1,
			Object.Multiplicity),
		TabularSectionRow.Multiplicity
	);
	
	TabularSectionRow.PaymentAmount = SmallBusinessClient.RecalculateFromCurrencyToCurrency(
		TabularSectionRow.SettlementsAmount,
		TabularSectionRow.ExchangeRate,
		?(Object.DocumentCurrency = NationalCurrency, RateNationalCurrency, Object.ExchangeRate),
		TabularSectionRow.Multiplicity,
		?(Object.DocumentCurrency = NationalCurrency,RepetitionNationalCurrency, Object.Multiplicity)
	);

EndProcedure

&AtClient
Procedure PrepaymentRateOnChange(Item)
	
	TabularSectionRow = Items.Prepayment.CurrentData;
	
	TabularSectionRow.ExchangeRate = ?(
		TabularSectionRow.ExchangeRate = 0,
		1,
		TabularSectionRow.ExchangeRate
	);
	
	TabularSectionRow.Multiplicity = ?(
		TabularSectionRow.Multiplicity = 0,
		1,
		TabularSectionRow.Multiplicity
	);
	
	TabularSectionRow.PaymentAmount = SmallBusinessClient.RecalculateFromCurrencyToCurrency(
		TabularSectionRow.SettlementsAmount,
		TabularSectionRow.ExchangeRate,
		?(Object.DocumentCurrency = NationalCurrency, RateNationalCurrency, Object.ExchangeRate),
		TabularSectionRow.Multiplicity,
		?(Object.DocumentCurrency = NationalCurrency,RepetitionNationalCurrency, Object.Multiplicity)
	);
	
EndProcedure

&AtClient
Procedure PrepaymentMultiplicityOnChange(Item)
	
	TabularSectionRow = Items.Prepayment.CurrentData;
	
	TabularSectionRow.ExchangeRate = ?(
		TabularSectionRow.ExchangeRate = 0,
		1,
		TabularSectionRow.ExchangeRate
	);
	
	TabularSectionRow.Multiplicity = ?(
		TabularSectionRow.Multiplicity = 0,
		1,
		TabularSectionRow.Multiplicity
	);
	
	TabularSectionRow.PaymentAmount = SmallBusinessClient.RecalculateFromCurrencyToCurrency(
		TabularSectionRow.SettlementsAmount,
		TabularSectionRow.ExchangeRate,
		?(Object.DocumentCurrency = NationalCurrency, RateNationalCurrency, Object.ExchangeRate),
		TabularSectionRow.Multiplicity,
		?(Object.DocumentCurrency = NationalCurrency,RepetitionNationalCurrency, Object.Multiplicity)
	);
	
EndProcedure

&AtClient
Procedure PrepaymentPaymentAmountOnChange(Item)
	
	TabularSectionRow = Items.Prepayment.CurrentData;
	
	TabularSectionRow.ExchangeRate = ?(
		TabularSectionRow.ExchangeRate = 0,
		1,
		TabularSectionRow.ExchangeRate
	);
	
	TabularSectionRow.Multiplicity = 1;
	
	TabularSectionRow.ExchangeRate =
		?(TabularSectionRow.SettlementsAmount = 0,
			1,
			TabularSectionRow.PaymentAmount
		  / TabularSectionRow.SettlementsAmount
		  * Object.ExchangeRate
	);
	
EndProcedure

// Procedure - OnChange event handler of the Comment input field.
//
&AtClient
Procedure CommentOnChange(Item)
	
	AttachIdleHandler("Attachable_SetPictureForComment", 0.5, True);
	
EndProcedure // CommentOnChange()

&AtClient
Procedure Attachable_SetPictureForComment()
	
	SmallBusinessClientServer.SetPictureForComment(Items.GroupAdditional, Object.Comment);
	
EndProcedure

#Region InteractiveActionResultHandlers

&AtClient
// Procedure-handler of the result of opening the "Prices and currencies" form
//
Procedure OpenPricesAndCurrencyFormEnd(ClosingResult, AdditionalParameters) Export
	
	If TypeOf(ClosingResult) = Type("Structure") 
		AND ClosingResult.WereMadeChanges Then
		
		Object.DocumentCurrency = ClosingResult.DocumentCurrency;
		Object.ExchangeRate = ClosingResult.PaymentsRate;
		Object.Multiplicity = ClosingResult.SettlementsMultiplicity;
		Object.VATTaxation = ClosingResult.VATTaxation;
		Object.AmountIncludesVAT = ClosingResult.AmountIncludesVAT;
		Object.IncludeVATInPrice = ClosingResult.IncludeVATInPrice;
		Object.CounterpartyPriceKind = ClosingResult.CounterpartyPriceKind;
		
		// Recalculate prices by kind of prices.
		If ClosingResult.RefillPrices Then
			
			SmallBusinessClient.RefillTabularSectionPricesByCounterpartyPriceKind(ThisForm, "Inventory")
			
		EndIf;
		
		// Recalculate prices by currency.
		If Not ClosingResult.RefillPrices
			AND ClosingResult.RecalculatePrices Then	
			
			SmallBusinessClient.RecalculateTabularSectionPricesByCurrency(ThisForm, AdditionalParameters.SettlementsCurrencyBeforeChange, "Inventory");
			RecalculateReceiptPricesOfTabularSectionByCurrency(ThisForm, AdditionalParameters.SettlementsCurrencyBeforeChange, "Inventory");
			
		EndIf;
		
		// Recalculate the amount if VAT taxation flag is changed.
		If ClosingResult.VATTaxation <> ClosingResult.PrevVATTaxation Then
			
			FillVATRateByVATTaxation();
			
		EndIf;
		
		// Recalculate the amount if the "Amount includes VAT" flag is changed.
		If Not ClosingResult.RefillPrices
			AND Not ClosingResult.AmountIncludesVAT = ClosingResult.PrevAmountIncludesVAT Then
			
			SmallBusinessClient.RecalculateTabularSectionAmountByFlagAmountIncludesVAT(ThisForm, "Inventory");
			RecalculateTabularSectionAmountReceiptByFlagAmountIncludesVAT(ThisForm, "Inventory");
			
		EndIf;
		
		For Each TabularSectionRow IN Object.Inventory Do
			// Amount of brokerage
			CalculateCommissionRemuneration(TabularSectionRow);
		EndDo;
		
		For Each TabularSectionRow IN Object.Prepayment Do
			
			TabularSectionRow.PaymentAmount = SmallBusinessClient.RecalculateFromCurrencyToCurrency(
				TabularSectionRow.SettlementsAmount,
				TabularSectionRow.ExchangeRate,
				?(Object.DocumentCurrency = NationalCurrency, RateNationalCurrency, Object.ExchangeRate),
				TabularSectionRow.Multiplicity,
				?(Object.DocumentCurrency = NationalCurrency, RepetitionNationalCurrency, Object.Multiplicity)
				);
				
		EndDo;
		
	EndIf;
	
	LabelStructure = New Structure("CounterpartyPriceKind, DocumentCurrency, SettlementsCurrency, ExchangeRate, RateNationalCurrency, AmountIncludesVAT, CurrencyTransactionsAccounting, VATTaxation", 
		Object.CounterpartyPriceKind, 
		Object.DocumentCurrency, 
		SettlementsCurrency, 
		Object.ExchangeRate, 
		RateNationalCurrency, 
		Object.AmountIncludesVAT, 
		CurrencyTransactionsAccounting, 
		Object.VATTaxation
		);
	
	PricesAndCurrency = GenerateLabelPricesAndCurrency(LabelStructure);
	
EndProcedure // OpenPricesAndCurrencyFormEnd()

&AtClient
// Procedure-handler of the answer to the question about repeated advances offset
//
Procedure DefineAdvancePaymentOffsetsRefreshNeed(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult = DialogReturnCode.Yes Then
		
		Object.Prepayment.Clear();
		HandleCounterpartiesPriceKindChangeAndSettlementsCurrency(AdditionalParameters);
		
	Else
		
		Object.Contract = AdditionalParameters.ContractBeforeChange;
		Contract = AdditionalParameters.ContractBeforeChange;
		
		If AdditionalParameters.Property("CounterpartyBeforeChange") Then
			
			Object.Counterparty = AdditionalParameters.CounterpartyBeforeChange;
			Counterparty = AdditionalParameters.CounterpartyBeforeChange;
			CounterpartyDoSettlementsByOrders = AdditionalParameters.CounterpartyDoSettlementsByOrdersBeforeChange;
			Items.Contract.Visible = AdditionalParameters.ContractVisibleBeforeChange;
			
		EndIf;
		
	EndIf;
	
EndProcedure // DefineAdvancePaymentRefreshNeed()

&AtClient
// Procedure-handler response on question about document recalculate by contract data
//
Procedure DefineDocumentRecalculateNeedByContractTerms(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult = DialogReturnCode.Yes Then
		
		ContractData = AdditionalParameters.ContractData;
		
		Object.CounterpartyPriceKind = ContractData.CounterpartyPriceKind;
		LabelStructure = New Structure("DocumentCurrency, SettlementsCurrency, ExchangeRate, RateNationalCurrency, AmountIncludesVAT, CurrencyTransactionsAccounting, CounterpartyPriceKind, VATTaxation", 
			Object.DocumentCurrency, 
			SettlementsCurrency, 
			Object.ExchangeRate, 
			RateNationalCurrency, 
			Object.AmountIncludesVAT, 
			CurrencyTransactionsAccounting, 
			Object.CounterpartyPriceKind, 
			Object.VATTaxation
			);
			
		PricesAndCurrency = GenerateLabelPricesAndCurrency(LabelStructure);
		
		// Recalculate prices by kind of prices.
		If Object.Inventory.Count() > 0 Then
			
			SmallBusinessClient.RefillTabularSectionPricesByCounterpartyPriceKind(ThisForm, "Inventory");
			
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

// StandardSubsystems.Printing
&AtClient
Procedure Attachable_ExecutePrintCommand(Command)
	PrintManagementClient.ExecuteConnectedPrintCommand(Command, ThisObject, Object);
EndProcedure

// End StandardSubsystems.Printing

#EndRegion

#Region ServiceProceduresAndFunctions

&AtClient
Procedure OpenSerialNumbersSelection()
		
	CurrentDataIdentifier = Items.Inventory.CurrentData.GetID();
	ParametersOfSerialNumbers = SerialNumberPickParameters(CurrentDataIdentifier);
	
	OpenForm("DataProcessor.SerialNumbersSelection.Form", ParametersOfSerialNumbers, ThisObject);

EndProcedure

&AtServer
Function SerialNumberPickParameters(CurrentDataIdentifier)
	
	Return WorkWithSerialNumbers.SerialNumberPickParameters(Object, ThisObject.UUID, CurrentDataIdentifier, False);
	
EndFunction

Function GetSerialNumbersFromStorage(AddressInTemporaryStorage, RowKey)
	
	Modified = True;
	Return WorkWithSerialNumbers.GetSerialNumbersFromStorage(Object, AddressInTemporaryStorage, RowKey);
	
EndFunction

&AtClient
Procedure InventoryCountryOfOriginOnChange(Item)
	
	If CashValues.AccountingCCD Then
	
		TabularSectionRow = Items.Inventory.CurrentData;
		If Not ValueIsFilled(TabularSectionRow.CountryOfOrigin)
			Or TabularSectionRow.CountryOfOrigin = CashValues.RUSSIA Then
			
			TabularSectionRow.CCDNo = Undefined;
			
		EndIf;
		
	EndIf;

EndProcedure

&AtClient
Procedure InventoryCCDNoOnChange(Item)
	
	TabularSectionRow = Items.Inventory.CurrentData;
	If TabularSectionRow <> Undefined
		And ValueIsFilled(TabularSectionRow.CCDNo) Then
		
		DateCCD = CargoCustomsDeclarationsClient.SelectDateFromCCDNumber(String(TabularSectionRow.CCDNo));
		If DateCCD > EndOfDay(Object.Date) Then
			
			MessageText = NStr("en='Attention! The selected CCD is dated at a later date than the current document';ru='Выбранная ГТД датирована более поздней датой, чем текущий документ';vi='Chú ý! Tờ khai hải quan đã chọn có ngày muộn hơn so với chứng từ hiện tại'");
			Stick = StrTemplate("Object.Inventory[%1].CCDNo", TabularSectionRow.GetID());
			
			CommonUseClient.MessageToUser(MessageText, , Stick);
			
		EndIf;
		
	EndIf;

EndProcedure

#EndRegion