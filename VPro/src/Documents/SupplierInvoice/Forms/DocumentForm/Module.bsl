////////////////////////////////////////////////////////////////////////////////
// MODULE VARIABLES

&AtClient
Var LineCopyInventory;

&AtClient
Var CloneRowsCosts;

////////////////////////////////////////////////////////////////////////////////
// GENERAL PURPOSE PROCEDURES AND FUNCTIONS

// Procedure calls the data processor for document filling by basis.
//
&AtServer
Procedure FillByDocument(BasisDocument)
	
	Document = FormAttributeToValue("Object");
	Document.Filling(BasisDocument, );
	ValueToFormAttribute(Document, "Object");
	Modified = True;
	
	If Object.VATTaxation = Enums.VATTaxationTypes.TaxableByVAT Then
		
		Items.InventoryVATRate.Visible = True;
		Items.InventoryVATAmount.Visible = True;
		Items.InventoryAmountTotal.Visible = True;
		
		Items.ExpencesVATRate.Visible = True;
		Items.ExpencesAmountVAT.Visible = True;
		Items.TotalExpences.Visible = True;
		
	Else
		
		Items.InventoryVATRate.Visible = False;
		Items.InventoryVATAmount.Visible = False;
		Items.InventoryAmountTotal.Visible = False;
		
		Items.ExpencesVATRate.Visible = False;
		Items.ExpencesAmountVAT.Visible = False;
		Items.TotalExpences.Visible = False;
		
	EndIf;
	
	SetContractVisible();
	
EndProcedure // FillByDocument()

// Procedure clears the document basis by communication: counterparty, contract.
//
&AtClient
Procedure ClearBasisOnChangeCounterpartyContract()
	
	If Not TypeOf(Object.BasisDocument) = Type("DocumentRef.GoodsReceipt") Then
		
		Object.BasisDocument = Undefined;
		
	EndIf;
	
EndProcedure // ClearBasisOnChangeCounterpartyContract()

// Procedure fills the column "Payment sum", etc. Inventory.
//
&AtServer
Procedure DistributeTabSectExpensesByQuantity()
	
	Document = FormAttributeToValue("Object");
	Document.DistributeTabSectExpensesByQuantity();
	ValueToFormAttribute(Document, "Object");
	
EndProcedure // DistributeTabSectionExpensesByCount()

// Procedure fills the column "Payment sum", etc. Inventory.
//
&AtServer
Procedure DistributeTabSectExpensesByAmount()
	
	Document = FormAttributeToValue("Object");
	Document.DistributeTabSectExpensesByAmount();
	ValueToFormAttribute(Document, "Object");
	
EndProcedure // DistributeTabSectionExpensesByAmount()

// It receives data set from server for the DateOnChange procedure.
//
&AtServer
Function GetDataDateOnChange(DateBeforeChange, SettlementsCurrency)
	
	DATEDIFF = SmallBusinessServer.CheckDocumentNumber(Object.Ref, Object.Date, DateBeforeChange);
	CurrencyRateRepetition = InformationRegisters.CurrencyRates.GetLast(Object.Date, New Structure("Currency", SettlementsCurrency));
	
	StructureData = New Structure;
	
	StructureData.Insert(
		"DATEDIFF",
		DATEDIFF
	);
	StructureData.Insert(
		"CurrencyRateRepetition",
		CurrencyRateRepetition
	);
	
	FillVATRateByCompanyVATTaxation();
	
	Return StructureData;
	
EndFunction // GetDataDateOnChange()

// Gets data set from server.
//
&AtServer
Function GetCompanyDataOnChange()
	
	StructureData = New Structure;
	
	StructureData.Insert("Company", SmallBusinessServer.GetCompany(Object.Company));
	FillVATRateByCompanyVATTaxation();

	Return StructureData;
	
EndFunction // GetCompanyDataOnChange()

// Receives the set of data from the server for the ProductsAndServicesOnChange procedure.
//
&AtServerNoContext
Function GetDataProductsAndServicesOnChange(StructureData)
	
	ProductsAndServicesData = CommonUse.ObjectAttributesValues(StructureData.ProductsAndServices,
		"MeasurementUnit, VATRate, BusinessActivity, ExpensesGLAccount.TypeOfAccount, CountryOfOrigin");
	
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
		
		Price = SmallBusinessServer.GetPriceProductsAndServicesByCounterpartyPriceKind(StructureData);
		StructureData.Insert("Price", Price);
		
	Else
		
		StructureData.Insert("Price", 0);
		
	EndIf;
	
	StructureData.Insert("ClearOrderAndDepartment", False);
	StructureData.Insert("ClearBusinessActivity", False);
	StructureData.Insert("BusinessActivity", ProductsAndServicesData.BusinessActivity);
	
	If ProductsAndServicesData.ExpensesGLAccountTypeOfAccount <> Enums.GLAccountsTypes.Expenses
	   AND ProductsAndServicesData.ExpensesGLAccountTypeOfAccount <> Enums.GLAccountsTypes.Incomings
	   AND ProductsAndServicesData.ExpensesGLAccountTypeOfAccount <> Enums.GLAccountsTypes.UnfinishedProduction
	   AND ProductsAndServicesData.ExpensesGLAccountTypeOfAccount <> Enums.GLAccountsTypes.IndirectExpenses Then
		StructureData.ClearOrderAndDepartment = True;
	EndIf;
	
	If ProductsAndServicesData.ExpensesGLAccountTypeOfAccount  <> Enums.GLAccountsTypes.Expenses
	   AND ProductsAndServicesData.ExpensesGLAccountTypeOfAccount  <> Enums.GLAccountsTypes.CostOfGoodsSold
	   AND ProductsAndServicesData.ExpensesGLAccountTypeOfAccount  <> Enums.GLAccountsTypes.Incomings Then
		StructureData.ClearBusinessActivity = True;
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
	
	StructureData = New Structure;
	
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

// Gets the data set from the server for procedure MeasurementUnitOnChange.
//
&AtServerNoContext
Function GetDataBusinessActivityStartChoice(ProductsAndServices)
	
	StructureData = New Structure;
	
	AvailabilityOfPointingBusinessActivities = True;
	
	If ProductsAndServices.ExpensesGLAccount.TypeOfAccount <> Enums.GLAccountsTypes.Expenses
		AND ProductsAndServices.ExpensesGLAccount.TypeOfAccount <> Enums.GLAccountsTypes.CostOfGoodsSold
		AND ProductsAndServices.ExpensesGLAccount.TypeOfAccount <> Enums.GLAccountsTypes.Incomings Then
			AvailabilityOfPointingBusinessActivities = False;
	EndIf;
	
	StructureData.Insert("AvailabilityOfPointingBusinessActivities", AvailabilityOfPointingBusinessActivities);
	
	Return StructureData;
	
EndFunction // GetDataBusinessActivityStartChoice()

&AtServerNoContext
// Gets the data set from the server for procedure MeasurementUnitOnChange.
//
Function GetDataStructuralUnitStartChoice(ProductsAndServices)
	
	StructureData = New Structure;
	
	AbilityToSpecifyDepartments = True;
	
	If ProductsAndServices.ExpensesGLAccount.TypeOfAccount <> Enums.GLAccountsTypes.Expenses
	   AND ProductsAndServices.ExpensesGLAccount.TypeOfAccount <> Enums.GLAccountsTypes.Incomings
	   AND ProductsAndServices.ExpensesGLAccount.TypeOfAccount <> Enums.GLAccountsTypes.UnfinishedProduction
	   AND ProductsAndServices.ExpensesGLAccount.TypeOfAccount <> Enums.GLAccountsTypes.IndirectExpenses Then
		AbilityToSpecifyDepartments = False;
	EndIf;
	
	StructureData.Insert("AbilityToSpecifyDepartments", AbilityToSpecifyDepartments);
	
	Return StructureData;
	
EndFunction // GetDataStructuralUnitStartChoice()

&AtServerNoContext
// Gets the data set from the server for procedure MeasurementUnitOnChange.
//
Function GetDataOrderStartChoice(ProductsAndServices)
	
	StructureData = New Structure;
	
	AbilityToSpecifyOrder = True;
	
	If ProductsAndServices.ExpensesGLAccount.TypeOfAccount <> Enums.GLAccountsTypes.Expenses
	   AND ProductsAndServices.ExpensesGLAccount.TypeOfAccount <> Enums.GLAccountsTypes.Incomings
	   AND ProductsAndServices.ExpensesGLAccount.TypeOfAccount <> Enums.GLAccountsTypes.UnfinishedProduction
	   AND ProductsAndServices.ExpensesGLAccount.TypeOfAccount <> Enums.GLAccountsTypes.IndirectExpenses Then
		AbilityToSpecifyOrder = False;
	EndIf;
	
	StructureData.Insert("AbilityToSpecifyOrder", AbilityToSpecifyOrder);
	
	Return StructureData;
	
EndFunction // GetDataStructuralUnitStartChoice()

// It receives data set from server for the ContractOnChange procedure.
//
&AtServer
Function GetDataCounterpartyOnChange(Date, DocumentCurrency, Counterparty, Company)
	
	ContractByDefault = GetContractByDefault(Object.Ref, Counterparty, Company, Object.OperationKind);
	
	StructureData = New Structure;
	
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
	
	StructureData = New Structure;
	
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

// Returns the kind of base document operation.
//
&AtServer
Function GetBaseDocumentOperationKind()
	
	Return Object.BasisDocument.OperationKind;
	
EndFunction // GetBaseDocumentOperationKind()

// Procedure fills VAT Rate in tabular section
// by company taxation system.
// 
&AtServer
Procedure FillVATRateByCompanyVATTaxation()
	
	TaxationBeforeChange = Object.VATTaxation;
	
	If Object.OperationKind = Enums.OperationKindsSupplierInvoice.ReturnFromCustomer
		OR Object.OperationKind = Enums.OperationKindsSupplierInvoice.ReturnFromAgent
		OR Object.OperationKind = Enums.OperationKindsSupplierInvoice.ReturnFromSubcontractor
		OR Object.OperationKind = Enums.OperationKindsSupplierInvoice.ReturnFromSafeCustody Then
		
		Object.VATTaxation = SmallBusinessServer.VATTaxation(Object.Company,, Object.Date);
		
	ElsIf Not ValueIsFilled(Object.VATTaxation) Then
		
		Object.VATTaxation = Enums.VATTaxationTypes.TaxableByVAT;
		
	EndIf;
	
	If Not TaxationBeforeChange = Object.VATTaxation Then
		FillVATRateByVATTaxation();
	EndIf;
	
EndProcedure // FillVATRateByVATTaxation()

// Procedure fills the VAT rate in the tabular section according to the taxation system.
// 
&AtServer
Procedure FillVATRateByVATTaxation()
	
	If Object.VATTaxation = Enums.VATTaxationTypes.TaxableByVAT Then
		
		Items.InventoryVATRate.Visible = True;
		Items.InventoryVATAmount.Visible = True;
		Items.InventoryAmountTotal.Visible = True;
					
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
		
		Items.ExpencesVATRate.Visible = True;
		Items.ExpencesAmountVAT.Visible = True;
		Items.TotalExpences.Visible = True;
		
		For Each TabularSectionRow IN Object.Expenses Do
			
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
		
		Items.ExpencesVATRate.Visible = False;
		Items.ExpencesAmountVAT.Visible = False;
		Items.TotalExpences.Visible = False;
		
		For Each TabularSectionRow IN Object.Expenses Do
		
			TabularSectionRow.VATRate = DefaultVATRate;
			TabularSectionRow.VATAmount = 0;
			
			TabularSectionRow.Total = TabularSectionRow.Amount;
			
		EndDo;
		
	EndIf;	
	
	// Update the form footer.
	TotalTotal = Object.Inventory.Total("Total") + Object.Expenses.Total("Total");
	TotalVATAmount = Object.Inventory.Total("VATAmount") + Object.Expenses.Total("VATAmount");
	
EndProcedure // FillVATRateByVATTaxation()	

// VAT amount is calculated in the row of tabular section.
//
&AtClient
Procedure CalculateVATSUM(TabularSectionRow)
	
	VATRate = SmallBusinessReUse.GetVATRateValue(TabularSectionRow.VATRate);
	
	TabularSectionRow.VATAmount = ?(Object.AmountIncludesVAT, 
									  TabularSectionRow.Amount - (TabularSectionRow.Amount) / ((VATRate + 100) / 100),
									  TabularSectionRow.Amount * VATRate / 100);
	
EndProcedure // CalculateVATAmount()

// Procedure calculates the amount in the row of tabular section.
//
&AtClient
Procedure CalculateAmountInTabularSectionLine(TabularSectionName, TabularSectionRow = Undefined)
	
	If TabularSectionRow = Undefined Then
		TabularSectionRow = Items[TabularSectionName].CurrentData;
	EndIf;
	
	TabularSectionRow.Amount = TabularSectionRow.Quantity * TabularSectionRow.Price;
	CalculateVATSUM(TabularSectionRow);
	TabularSectionRow.Total = TabularSectionRow.Amount + ?(Object.AmountIncludesVAT, 0, TabularSectionRow.VATAmount);
	
	// Serial numbers
	If UseSerialNumbersBalance<>Undefined AND TabularSectionName="Inventory" Then
		WorkWithSerialNumbersClientServer.UpdateSerialNumbersQuantity(Object, TabularSectionRow);
	EndIf;
	
EndProcedure // CalculateAmountInTabularSectionLine()

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
	
EndProcedure // RecalculateRateAccountCurrencyRepetition()

&AtClient
Procedure RecalculatePaymentCurrencyRateConversionFactorEnd(Result, AdditionalParameters) Export
	
	NewRatio = AdditionalParameters.NewRatio;
	NewExchangeRate = AdditionalParameters.NewExchangeRate;
	
	Response = Result;
	
	If Response = DialogReturnCode.Yes Then
		
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
	
	// Generate price and currency label.
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
	ParametersStructure.Insert("DocumentCurrency",		  Object.DocumentCurrency);
	ParametersStructure.Insert("ExchangeRate",				  Object.ExchangeRate);
	ParametersStructure.Insert("Multiplicity",			  Object.Multiplicity);
	ParametersStructure.Insert("VATTaxation",	  Object.VATTaxation);
	ParametersStructure.Insert("AmountIncludesVAT",	  Object.AmountIncludesVAT);
	ParametersStructure.Insert("IncludeVATInPrice", Object.IncludeVATInPrice);
	ParametersStructure.Insert("Counterparty",			  Object.Counterparty);
	ParametersStructure.Insert("Contract",				  Object.Contract);
	ParametersStructure.Insert("Company",			  Company);
	ParametersStructure.Insert("DocumentDate",		  Object.Date);
	ParametersStructure.Insert("RefillPrices",	  RefillPrices);
	ParametersStructure.Insert("RecalculatePrices",		  RecalculatePrices);
	ParametersStructure.Insert("WereMadeChanges",  False);
	ParametersStructure.Insert("CounterpartyPriceKind", 	  Object.CounterpartyPriceKind);
	ParametersStructure.Insert("RegisterVendorPrices", Object.RegisterVendorPrices);
	ParametersStructure.Insert("WarningText",	  WarningText);
	// DiscountCards
	If Object.OperationKind = PredefinedValue("Enum.OperationKindsSupplierInvoice.ReturnFromCustomer") Then
		ParametersStructure.Insert("DiscountCard",	  Object.DiscountCard);
	EndIf;
	// End DiscountCards
	
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

// Procedure updates data in form footer.
//
&AtClient
Procedure RefreshFormFooter()
	
	TotalTotal = Object.Inventory.Total("Total") + Object.Expenses.Total("Total");
	TotalVATAmount = Object.Inventory.Total("VATAmount") + Object.Expenses.Total("VATAmount");
	
EndProcedure // UpdateFormFooter()

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
				NewRow.Price = BarcodeData.StructureProductsAndServicesData.Price;
				NewRow.VATRate = BarcodeData.StructureProductsAndServicesData.VATRate;
				CalculateAmountInTabularSectionLine("Inventory", NewRow);
				Items.Inventory.CurrentRow = NewRow.GetID();
			Else
				NewRow = TSRowsArray[0];
				NewRow.Quantity = NewRow.Quantity + CurBarcode.Quantity;
				CalculateAmountInTabularSectionLine("Inventory", NewRow);
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
Function GetChoiceFormParameters(Document, Company, Counterparty, Contract, OperationKind)
	
	ContractTypesList = Catalogs.CounterpartyContracts.GetContractKindsListForDocument(Document, OperationKind);
	
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
	
	Object.StructuralUnit = MainWarehouse;
	
	Object.Prepayment.Clear();
	SetVisibleAndEnabled(True);
	
	Object.Contract = GetContractByDefault(Object.Ref, Object.Counterparty, Object.Company, Object.OperationKind);
	
	LabelStructure = New Structure("DocumentCurrency, SettlementsCurrency, ExchangeRate, RateNationalCurrency, AmountIncludesVAT, CurrencyTransactionsAccounting, CounterpartyPriceKind, VATTaxation", Object.DocumentCurrency, SettlementsCurrency, Object.ExchangeRate, RateNationalCurrency, Object.AmountIncludesVAT, CurrencyTransactionsAccounting, Object.CounterpartyPriceKind, Object.VATTaxation);
	PricesAndCurrency = GenerateLabelPricesAndCurrency(LabelStructure);
	
EndProcedure

// Performs actions when counterparty contract is changed.
//
&AtClient
Procedure ProcessContractChange()
	
	ContractBeforeChange = Contract;
	Contract = Object.Contract;
	
	If ContractBeforeChange <> Object.Contract Then
		
		ClearBasisOnChangeCounterpartyContract();
		
		If Object.Prepayment.Count() > 0
		   AND Object.Contract <> ContractBeforeChange Then
			
			ShowQueryBox(New NotifyDescription("ProcessContractChangeEnd", ThisObject, New Structure("ContractBeforeChange", ContractBeforeChange)),
				NStr("en='Prepayment setoff will be cleared, continue?';ru='Зачет предоплаты будет очищен, продолжить?';vi='Sẽ hủy việc khấu trừ khoản trả trước, tiếp tục?'"),
				QuestionDialogMode.YesNo
			);
			Return;
			
		EndIf;
		
		ProcessContractChangeFragment(ContractBeforeChange);
		
	Else
		
		Object.Contract = Contract; // Restore the cleared contract automatically.
		Order = Object.Order;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessContractChangeEnd(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		Object.Prepayment.Clear();
	Else
		Object.Contract = AdditionalParameters.ContractBeforeChange;
		Contract = AdditionalParameters.ContractBeforeChange;
		Object.Order = Order;
		Return;
	EndIf;
	
	ProcessContractChangeFragment(AdditionalParameters.ContractBeforeChange);
	
EndProcedure

&AtClient
Procedure ProcessContractChangeFragment(ContractBeforeChange)
	
	StructureData = GetDataContractOnChange(Object.Date, Object.DocumentCurrency, Object.Contract);
	
	SettlementsCurrencyBeforeChange = SettlementsCurrency;
	SettlementsCurrency = StructureData.SettlementsCurrency;
	
	If Not StructureData.AmountIncludesVAT = Undefined Then
		Object.AmountIncludesVAT = StructureData.AmountIncludesVAT;
	EndIf;
	
	If ValueIsFilled(Object.Contract) Then 
		Object.ExchangeRate      = ?(StructureData.SettlementsCurrencyRateRepetition.ExchangeRate = 0, 1, StructureData.SettlementsCurrencyRateRepetition.ExchangeRate);
		Object.Multiplicity = ?(StructureData.SettlementsCurrencyRateRepetition.Multiplicity = 0, 1, StructureData.SettlementsCurrencyRateRepetition.Multiplicity);
	EndIf;
	
	PriceKindChanged = Object.CounterpartyPriceKind <> StructureData.CounterpartyPriceKind 
		AND ValueIsFilled(StructureData.CounterpartyPriceKind);
	NewContractAndCalculationCurrency = ValueIsFilled(Object.Contract) AND ValueIsFilled(SettlementsCurrency) 
		AND Object.Contract <> ContractBeforeChange AND SettlementsCurrencyBeforeChange <> StructureData.SettlementsCurrency;
	OpenFormPricesAndCurrencies = NewContractAndCalculationCurrency AND Object.DocumentCurrency <> StructureData.SettlementsCurrency
		AND (Object.Inventory.Count() > 0 OR Object.Expenses.Count() > 0);
		
	StructureData.Insert("PriceKindChanged", PriceKindChanged);
	
	// If the contract has changed and the kind of counterparty prices is selected, automatically register incoming prices
	Object.RegisterVendorPrices = StructureData.PriceKindChanged AND Not Object.CounterpartyPriceKind.IsEmpty();
	Order = Object.Order;
	
	If PriceKindChanged Then
		Object.CounterpartyPriceKind = StructureData.CounterpartyPriceKind;
	EndIf;
	Object.RegisterVendorPrices = True;
	Object.DocumentCurrency = StructureData.SettlementsCurrency;
	
	If OpenFormPricesAndCurrencies Then
		
		WarningText = "";
		
		If PriceKindChanged Then
			WarningText = NStr("en='The price and discount conditions in the contract with counterparty differ from price and discount in the document! "
"Perhaps you have to refill prices.';ru='Договор с контрагентом предусматривает условия цен и скидок, отличные от установленных в документе! "
"Возможно, необходимо перезаполнить цены.';vi='Hợp đồng với đối tác xem xét điều kiện giá và chiết khấu mà khác với điều kiện đã thiết lập trong chứng từ!"
"Có thể, cần điền lại đơn giá."
"'") + Chars.LF + Chars.LF;
		EndIf;
		
		WarningText = WarningText + NStr("en='Settlement currency of the contract with counterparty changed!"
"It is necessary to check the document currency!';ru='Изменилась валюта расчетов по договору с контрагентом!"
"Необходимо проверить валюту документа!';vi='Đã trhay đổi tiền tệ hạch toán theo hợp đồng với đối tác!"
"Cần kiểm tra tiền tệ của chứng từ!'");
		ProcessChangesOnButtonPricesAndCurrencies(SettlementsCurrencyBeforeChange, True, PriceKindChanged, WarningText);
		
	ElsIf ValueIsFilled(Object.Contract) 
		AND PriceKindChanged Then
		
		RecalculationRequired = (Object.Inventory.Count() > 0);
		
		Object.CounterpartyPriceKind	= StructureData.CounterpartyPriceKind;
		LabelStructure 			= 
			New Structure("DocumentCurrency, SettlementsCurrency, ExchangeRate, RateNationalCurrency, AmountIncludesVAT, CurrencyTransactionsAccounting, CounterpartyPriceKind, VATTaxation", 
							Object.DocumentCurrency, 
							SettlementsCurrency, 
							Object.ExchangeRate, 
							RateNationalCurrency, 
							Object.AmountIncludesVAT, 
							CurrencyTransactionsAccounting, 
							Object.CounterpartyPriceKind, 
							Object.VATTaxation);
		
		PricesAndCurrency 				= GenerateLabelPricesAndCurrency(LabelStructure);
		
		If RecalculationRequired Then
			
			Message = NStr("en='The counterparty contract allows for the kind of prices other than prescribed in the document! "
"Recalculate the document according to the contract?';ru='Договор с контрагентом предусматривает вид цен, отличный от установленного в документе! "
"Пересчитать документ в соответствии с договором?';vi='Hợp đồng với đối tác xem xét dạng giá mà khác với dạng giá đã đặt trong chứng từ!"
"Đọc lại chứng từ tương ứng với hợp đồng?'");
										
			ShowQueryBox(New NotifyDescription("ProcessContractChangeFragmentEnd", ThisObject, New Structure("ContractBeforeChange, SettlementsCurrencyBeforeChange, StructureData", ContractBeforeChange, SettlementsCurrencyBeforeChange, StructureData)), 
				Message,
				QuestionDialogMode.YesNo
			);
			Return;
		
		EndIf;
		
	Else
		
		LabelStructure 			= 
			New Structure("DocumentCurrency, SettlementsCurrency, ExchangeRate, RateNationalCurrency, AmountIncludesVAT, CurrencyTransactionsAccounting, CounterpartyPriceKind, VATTaxation", 
							Object.DocumentCurrency, 
							SettlementsCurrency, 
							Object.ExchangeRate, 
							RateNationalCurrency, 
							Object.AmountIncludesVAT, 
							CurrencyTransactionsAccounting, 
							Object.CounterpartyPriceKind, 
							Object.VATTaxation);
		
		PricesAndCurrency 				= GenerateLabelPricesAndCurrency(LabelStructure);
		
	EndIf;
	
	RefreshFormFooter();
	
EndProcedure

&AtClient
Procedure ProcessContractChangeFragmentEnd(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		SmallBusinessClient.RefillTabularSectionPricesByCounterpartyPriceKind(ThisForm, "Inventory");
		RefreshFormFooter();
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// PROCEDURES FOR WORK WITH THE SELECTION

// Procedure - event handler Action of the Pick command
//
&AtClient
Procedure InventoryPick(Command)
	
	TabularSectionName	= "Inventory";
	
	If Not IsBlankString(SelectionOpenParameters[TabularSectionName]) Then
		
		PickProductsAndServicesInDocumentsClient.OpenPick(ThisForm, TabularSectionName, SelectionOpenParameters[TabularSectionName]);
		Return;
		
	EndIf;
	
	SelectionParameters = New Structure;
	
	SelectionParameters.Insert("Period",					Object.Date);
	SelectionParameters.Insert("Company",			Company);
	SelectionParameters.Insert("StructuralUnit",		Object.StructuralUnit);
	SelectionParameters.Insert("VATTaxation",		Object.VATTaxation);
	SelectionParameters.Insert("AmountIncludesVAT",		Object.AmountIncludesVAT);
	SelectionParameters.Insert("DocumentOrganization",	Object.Company);
	SelectionParameters.Insert("CounterpartyPriceKind",		Object.CounterpartyPriceKind);
	SelectionParameters.Insert("Currency", 				Object.DocumentCurrency);
	SelectionParameters.Insert("ThisIsReceiptDocument",	True);
	SelectionParameters.Insert("AvailablePriceChanging",	Not Items.InventoryPrice.ReadOnly);
	
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
	
EndProcedure // InventoryPick()

// Procedure - event handler Action of the Pick command
//
&AtClient
Procedure ExpensesPick(Command)
	
	TabularSectionName	= "Expenses";
	
	If Not IsBlankString(SelectionOpenParameters[TabularSectionName]) Then
		
		PickProductsAndServicesInDocumentsClient.OpenPick(ThisForm, TabularSectionName, SelectionOpenParameters[TabularSectionName]);
		Return;
		
	EndIf;
	
	SelectionParameters = New Structure;
	
	SelectionParameters.Insert("Period",					Object.Date);
	SelectionParameters.Insert("Company",			Company);
	SelectionParameters.Insert("StructuralUnit",		Object.StructuralUnit);
	SelectionParameters.Insert("VATTaxation",		Object.VATTaxation);
	SelectionParameters.Insert("AmountIncludesVAT",		Object.AmountIncludesVAT);
	SelectionParameters.Insert("DocumentOrganization",	Object.Company);
	SelectionParameters.Insert("PriceKind",					Undefined);
	SelectionParameters.Insert("CharacteristicsUsed", False);
	SelectionParameters.Insert("BatchesUsed",		False);
	SelectionParameters.Insert("ThisIsReceiptDocument",	True);
	
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

// Function places the list of advances into temporary storage and returns the address
//
&AtServer
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

// Function gets the list of advances from the temporary storage
//
&AtServer
Procedure GetPrepaymentFromStorage(AddressPrepaymentInStorage)
	
	TableForImport = GetFromTempStorage(AddressPrepaymentInStorage);
	Object.Prepayment.Load(TableForImport);
	
EndProcedure // GetPrepaymentFromStorage()

////////////////////////////////////////////////////////////////////////////////
// PROCEDURES AND FUNCTIONS FOR CONTROL OF THE FORM APPEARANCE

// Procedure sets availability of the form items.
//
// Parameters:
//  No.
//
&AtServer
Procedure SetVisibleAndEnabled(ChangedTypeOperations = False)
	
	If Object.OperationKind = PredefinedValue("Enum.OperationKindsSupplierInvoice.ReturnFromSubcontractor")
	 OR Object.OperationKind = PredefinedValue("Enum.OperationKindsSupplierInvoice.ReceiptFromVendor")
	 OR Object.OperationKind = PredefinedValue("Enum.OperationKindsSupplierInvoice.ReceptionForCommission") Then
		
		ValidTypes = New TypeDescription("DocumentRef.PurchaseOrder");
		
	ElsIf Object.OperationKind = PredefinedValue("Enum.OperationKindsSupplierInvoice.ReceptionIntoProcessing")
	 OR Object.OperationKind = PredefinedValue("Enum.OperationKindsSupplierInvoice.ReturnFromCustomer")
	 OR Object.OperationKind = PredefinedValue("Enum.OperationKindsSupplierInvoice.ReturnFromAgent") Then
		
		ValidTypes = New TypeDescription("DocumentRef.CustomerOrder");
		
	Else
		
		FilterArray = New Array;
		FilterArray.Add(Type("DocumentRef.PurchaseOrder"));
		FilterArray.Add(Type("DocumentRef.CustomerOrder"));
		ValidTypes = New TypeDescription(FilterArray);
		
	EndIf;
	
	Items.Order.TypeRestriction = ValidTypes;
	Items.Inventory.ChildItems.InventoryOrder.TypeRestriction = ValidTypes;
	
	// ГрупповоеИзменениеСтрок
	If ChangedTypeOperations Then
		FillActionsList(NameTSInventory());
	EndIf;

	If InventoryRowsChangeAction = Enums.BulkRowChangeActions.SetPurchaseOrderCustomerOrder Then
		Items.InventoryRowsChangeValue.TypeRestriction = ValidTypes;
	EndIf;
	// Конец ГрупповоеИзменениеСтрок

	
	If Object.OperationKind = PredefinedValue("Enum.OperationKindsSupplierInvoice.ReceiptFromVendor") Then
		
		Items.IncludeExpensesInCostPrice.Visible = True;
		Items.Expenses.Visible = True;
		Items.Inventory.ChildItems.InventoryAmountExpenses.Visible = True;
		
		If Object.IncludeExpensesInCostPrice Then
			
			Items.Expenses.ChildItems.ExpensesOrder.Visible = False;
			Items.Expenses.ChildItems.ExpensesStructuralUnit.Visible = False;
			Items.Expenses.ChildItems.ExpensesBusinessActivity.Visible = False;
			Items.AllocateExpenses.Visible = True;
			Items.Inventory.ChildItems.InventoryAmountExpenses.Visible = True;
			
		Else
			
			Items.Expenses.ChildItems.ExpensesOrder.Visible = True;
			Items.Expenses.ChildItems.ExpensesStructuralUnit.Visible = True;
			Items.Expenses.ChildItems.ExpensesBusinessActivity.Visible = True;
			Items.AllocateExpenses.Visible = False;
			Items.Inventory.ChildItems.InventoryAmountExpenses.Visible = False;
			
		EndIf;
		
		NewArray = New Array();
		NewArray.Add(Enums.StructuralUnitsTypes.Warehouse);
		NewArray.Add(Enums.StructuralUnitsTypes.Retail);
		NewArray.Add(Enums.StructuralUnitsTypes.RetailAccrualAccounting);
		ArrayOwnInventoryAndGoodsOnCommission = New FixedArray(NewArray);
		NewParameter = New ChoiceParameter("Filter.StructuralUnitType", ArrayOwnInventoryAndGoodsOnCommission);
		NewArray = New Array();
		NewArray.Add(NewParameter);
		NewParameters = New FixedArray(NewArray);
		Items.StructuralUnit.ChoiceParameters = NewParameters;
		
	Else
		
		Items.IncludeExpensesInCostPrice.Visible = False;
		Items.Expenses.Visible = False;
		Items.AllocateExpenses.Visible = False;
		
		Object.IncludeExpensesInCostPrice = False;
		Object.Expenses.Clear();
		
		Items.Inventory.ChildItems.InventoryAmountExpenses.Visible = False;
		If Object.Inventory.Count() > 0 Then
			For Each StringInventory IN Object.Inventory Do
				StringInventory.AmountExpenses = 0;
			EndDo;
		EndIf;
		
		NewArray = New Array();
		
		If Object.OperationKind = PredefinedValue("Enum.OperationKindsSupplierInvoice.ReceptionForCommission")
		 OR Object.OperationKind = PredefinedValue("Enum.OperationKindsSupplierInvoice.ReturnFromCustomer") Then
			NewArray.Add(Enums.StructuralUnitsTypes.Warehouse);
			NewArray.Add(Enums.StructuralUnitsTypes.Retail);
		Else
			NewArray.Add(Enums.StructuralUnitsTypes.Warehouse);
		EndIf;
		
		ArrayOwnInventoryAndGoodsOnCommission = New FixedArray(NewArray);
		NewParameter = New ChoiceParameter("Filter.StructuralUnitType", ArrayOwnInventoryAndGoodsOnCommission);
		NewArray = New Array();
		NewArray.Add(NewParameter);
		NewParameters = New FixedArray(NewArray);
		Items.StructuralUnit.ChoiceParameters = NewParameters;
		
	EndIf;
	
	If Object.OperationKind = PredefinedValue("Enum.OperationKindsSupplierInvoice.ReturnFromCustomer")
		AND (NOT ValueIsFilled(Object.BasisDocument)
		OR (ValueIsFilled(Object.BasisDocument)
			AND TypeOf(Object.BasisDocument) <> Type("DocumentRef.CustomerInvoice")
			AND (TypeOf(Object.BasisDocument) = Type("DocumentRef.CustomerOrder")
			AND Object.BasisDocument.OperationKind <> Enums.OperationKindsCustomerOrder.WorkOrder))) Then
		
		Items.Inventory.ChildItems.InventoryCostPrice.Visible = True;
		
	Else
		
		Items.Inventory.ChildItems.InventoryCostPrice.Visible = False; //!
		If Object.Inventory.Count() > 0 Then
			For Each StringInventory IN Object.Inventory Do
				StringInventory.Cost = 0;
			EndDo;
		EndIf;
		
	EndIf;
	
	ThisIsNotReturn = Object.OperationKind <> PredefinedValue("Enum.OperationKindsSupplierInvoice.ReturnFromSubcontractor")
					AND Object.OperationKind <> PredefinedValue("Enum.OperationKindsSupplierInvoice.ReturnFromCustomer")
					AND Object.OperationKind <> PredefinedValue("Enum.OperationKindsSupplierInvoice.ReturnFromAgent")
					AND Object.OperationKind <> PredefinedValue("Enum.OperationKindsSupplierInvoice.ReturnFromSafeCustody");
					
	CommonUseClientServer.SetFormItemProperty(Items, "InventoryLoadFromFileInventory", "Visible", ThisIsNotReturn);
	CommonUseClientServer.SetFormItemProperty(Items, "ExpensesLoadFromFileServices", "Visible", ThisIsNotReturn);
	
	// Batches.
	If Object.OperationKind = PredefinedValue("Enum.OperationKindsSupplierInvoice.ReceptionForCommission") Then
		
		NewParameter = New ChoiceParameter("Filter.Status", PredefinedValue("Enum.BatchStatuses.ProductsOnCommission"));
		NewArray = New Array();
		NewArray.Add(NewParameter);
		NewParameters = New FixedArray(NewArray);
		Items.Inventory.ChildItems.InventoryBatch.ChoiceParameters = NewParameters;
		
	ElsIf Object.OperationKind = PredefinedValue("Enum.OperationKindsSupplierInvoice.ReceptionIntoProcessing") Then
		
		NewParameter = New ChoiceParameter("Filter.Status", PredefinedValue("Enum.BatchStatuses.CommissionMaterials"));
		NewArray = New Array();
		NewArray.Add(NewParameter);
		NewParameters = New FixedArray(NewArray);
		Items.Inventory.ChildItems.InventoryBatch.ChoiceParameters = NewParameters;
		
	ElsIf Object.OperationKind = PredefinedValue("Enum.OperationKindsSupplierInvoice.ReceptionForSafeCustody") Then
		
		NewParameter = New ChoiceParameter("Filter.Status", PredefinedValue("Enum.BatchStatuses.SafeCustody"));
		NewArray = New Array();
		NewArray.Add(NewParameter);
		NewParameters = New FixedArray(NewArray);
		Items.Inventory.ChildItems.InventoryBatch.ChoiceParameters = NewParameters;
		
	ElsIf Object.OperationKind = PredefinedValue("Enum.OperationKindsSupplierInvoice.ReturnFromCustomer") Then
		
		NewArray = New Array();
		NewArray.Add(PredefinedValue("Enum.BatchStatuses.OwnInventory"));
		NewArray.Add(PredefinedValue("Enum.BatchStatuses.ProductsOnCommission"));
		ArrayOwnInventoryAndGoodsOnCommission = New FixedArray(NewArray);
		NewParameter = New ChoiceParameter("Filter.Status", ArrayOwnInventoryAndGoodsOnCommission);
		NewParameter2 = New ChoiceParameter("Additionally.StatusRestriction", ArrayOwnInventoryAndGoodsOnCommission);
		NewArray = New Array();
		NewArray.Add(NewParameter);
		NewArray.Add(NewParameter2);
		NewParameters = New FixedArray(NewArray);
		Items.Inventory.ChildItems.InventoryBatch.ChoiceParameters = NewParameters;
		
	Else
		
		NewParameter = New ChoiceParameter("Filter.Status", PredefinedValue("Enum.BatchStatuses.OwnInventory"));
		NewArray = New Array();
		NewArray.Add(NewParameter);
		NewParameters = New FixedArray(NewArray);
		Items.Inventory.ChildItems.InventoryBatch.ChoiceParameters = NewParameters;
		
	EndIf;
	
	// Prepayment set-off.
	If Object.OperationKind = PredefinedValue("Enum.OperationKindsSupplierInvoice.ReceiptFromVendor")
	 OR Object.OperationKind = PredefinedValue("Enum.OperationKindsSupplierInvoice.ReturnFromCustomer") Then
		Items.Prepayment.Visible = True;
	Else
		Items.Prepayment.Visible = False;
	EndIf;
	
	// Order when responsible location.
	If Object.OperationKind = PredefinedValue("Enum.OperationKindsSupplierInvoice.ReceptionForSafeCustody")
	 OR Object.OperationKind = PredefinedValue("Enum.OperationKindsSupplierInvoice.ReturnFromSafeCustody") Then
		Items.Order.Visible = False;
		Items.FillByOrder.Visible = False;
		Items.Inventory.ChildItems.InventoryOrder.Visible = False;
	Else
		Items.Order.Visible = True;
		Items.FillByOrder.Visible = True;
		Items.Inventory.ChildItems.InventoryOrder.Visible = True;
	EndIf;
	
	If Object.StructuralUnit.StructuralUnitType = Enums.StructuralUnitsTypes.Retail
	 OR Object.StructuralUnit.StructuralUnitType = Enums.StructuralUnitsTypes.RetailAccrualAccounting Then
		Items.Expenses.ChildItems.ExpensesOrder.Visible = False;
	Else
		Items.Expenses.ChildItems.ExpensesOrder.Visible = True;
	EndIf;
	
	If Not ValueIsFilled(Object.StructuralUnit)
		OR Object.StructuralUnit.OrderWarehouse
		OR Object.StructuralUnit.StructuralUnitType = Enums.StructuralUnitsTypes.Retail
		OR Object.StructuralUnit.StructuralUnitType = Enums.StructuralUnitsTypes.RetailAccrualAccounting Then
		Items.Cell.Visible = False;
	Else
		Items.Cell.Visible = True;
	EndIf;
	
	// VAT Rate, VAT Amount, Total.
	If ChangedTypeOperations Then
		FillVATRateByCompanyVATTaxation();
	Else
		
		If Object.VATTaxation = Enums.VATTaxationTypes.TaxableByVAT Then
			
			Items.InventoryVATRate.Visible = True;
			Items.InventoryVATAmount.Visible = True;
			Items.InventoryAmountTotal.Visible = True;
			Items.ExpencesVATRate.Visible = True;
			Items.ExpencesAmountVAT.Visible = True;
			Items.TotalExpences.Visible = True;
			
		Else
			
			Items.InventoryVATRate.Visible = False;
			Items.InventoryVATAmount.Visible = False;
			Items.InventoryAmountTotal.Visible = False;
			Items.ExpencesVATRate.Visible = False;
			Items.ExpencesAmountVAT.Visible = False;
			Items.TotalExpences.Visible = False;
			
		EndIf;
		
	EndIf;
	
	// Price accessibility setup for editing.
	AllowedEditDocumentPrices = SmallBusinessAccessManagementReUse.AllowedEditDocumentPrices()
		OR IsInRole("AddChangePurchasesSubsystem");
		
	Items.InventoryPrice.ReadOnly 		= Not AllowedEditDocumentPrices;
	Items.InventoryAmount.ReadOnly 	= Not AllowedEditDocumentPrices;
	Items.InventoryVATAmount.ReadOnly 	= Not AllowedEditDocumentPrices;
	
	// Update the form footer.
	TotalTotal = Object.Inventory.Total("Total") + Object.Expenses.Total("Total");
	TotalVATAmount = Object.Inventory.Total("VATAmount") + Object.Expenses.Total("VATAmount");
	
	SetVisibleFromUserSettings();

	Items.InventoryTotalAmountOfVAT.Visible	= UseVAT;	
	
EndProcedure // SetVisibleAndEnabled()

// Procedure sets the form item visible.
//
// Parameters:
//  No.
//
&AtServer
Procedure SetVisibleFromUserSettings()
	
	If Object.PurchaseOrderPosition = Enums.AttributePositionOnForm.InHeader Then
		Items.Order.Visible = True;
		Items.FillByOrder.Visible = True;
		Items.InventoryOrder.Visible = False;
		OrderInHeader = True;
	Else
		Items.Order.Visible = False;
		Items.FillByOrder.Visible = False;
		Items.InventoryOrder.Visible = True;
		OrderInHeader = False;
	EndIf;
	
EndProcedure // SetVisibleFromUserSettings()

// Procedure is forming the mapping of operation kinds.
//
&AtServer
Procedure GetOperationKindsStructure()
	
	If Parameters.Property("OperationKindReturn") Then
		
		Items.OperationKind.ChoiceList.Clear();
		
	Else
		
		If Constants.FunctionalOptionReceiveGoodsOnCommission.Get() Then
			Items.OperationKind.ChoiceList.Add(Enums.OperationKindsSupplierInvoice.ReceptionForCommission);
		EndIf;
		
		If Constants.FunctionalOptionTolling.Get() Then
			Items.OperationKind.ChoiceList.Add(Enums.OperationKindsSupplierInvoice.ReceptionIntoProcessing);
		EndIf;
		
		If Constants.FunctionalOptionTransferInventoryOnSafeCustody.Get() Then
			Items.OperationKind.ChoiceList.Add(Enums.OperationKindsSupplierInvoice.ReceptionForSafeCustody);
		EndIf;
		
	EndIf;
	
	Items.OperationKind.ChoiceList.Add(Enums.OperationKindsSupplierInvoice.ReturnFromCustomer);
	
	If Constants.FunctionalOptionTransferGoodsOnCommission.Get() Then
		Items.OperationKind.ChoiceList.Add(Enums.OperationKindsSupplierInvoice.ReturnFromAgent);
	EndIf;
	
	If Constants.FunctionalOptionTransferRawMaterialsForProcessing.Get() Then
		Items.OperationKind.ChoiceList.Add(Enums.OperationKindsSupplierInvoice.ReturnFromSubcontractor);
	EndIf;
	
	If Constants.FunctionalOptionTransferInventoryOnSafeCustody.Get() Then
		Items.OperationKind.ChoiceList.Add(Enums.OperationKindsSupplierInvoice.ReturnFromSafeCustody);
	EndIf;
	
EndProcedure // GetOperationKindsStructure()

////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - FORM EVENT HANDLERS

&AtClient
Procedure AddAdditionalAttribute(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("CurrentSetOfProperties", PredefinedValue("Catalog.AdditionalAttributesAndInformationSets.Document_SupplierInvoice"));
	FormParameters.Insert("ThisIsAdditionalInformation", False);
	
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInformation.ObjectForm", FormParameters,,,,,,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Procedure - OnCreateAtServer event handler.
//
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	UseVAT	= SmallBusinessServer.GetFunctionalOptionValue("UseVAT");
	
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
			If Object.DocumentCurrency <> Object.Contract.SettlementsCurrency Then
				Object.DocumentCurrency = Object.Contract.SettlementsCurrency;
				SettlementsCurrencyRateRepetition = InformationRegisters.CurrencyRates.GetLast(Object.Date, New Structure("Currency", Object.Contract.SettlementsCurrency));
				Object.ExchangeRate      = ?(SettlementsCurrencyRateRepetition.ExchangeRate = 0, 1, SettlementsCurrencyRateRepetition.ExchangeRate);
				Object.Multiplicity = ?(SettlementsCurrencyRateRepetition.Multiplicity = 0, 1, SettlementsCurrencyRateRepetition.Multiplicity);
			EndIf;
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
	
	Company = SmallBusinessServer.GetCompany(Object.Company);
	Counterparty = Object.Counterparty;
	Contract = Object.Contract;
	Order = Object.Order;
	SettlementsCurrency = Object.Contract.SettlementsCurrency;
	NationalCurrency = Constants.NationalCurrency.Get();
	StructureByCurrency = InformationRegisters.CurrencyRates.GetLast(Object.Date, New Structure("Currency", NationalCurrency));
	RateNationalCurrency = StructureByCurrency.ExchangeRate;
	RepetitionNationalCurrency = StructureByCurrency.Multiplicity;
	
	If Not ValueIsFilled(Object.Ref) Then 
		If Parameters.Property("OperationKindReturn") Then
			Object.OperationKind = Enums.OperationKindsSupplierInvoice.ReturnFromCustomer;
		EndIf;
		If Not ValueIsFilled(Parameters.Basis) AND Not ValueIsFilled(Parameters.CopyingValue) Then
			FillVATRateByCompanyVATTaxation();
		EndIf;
	EndIf;
	
	GetOperationKindsStructure();
	
	// Update the form footer.
	TotalTotal = Object.Inventory.Total("Total") + Object.Expenses.Total("Total");
	TotalVATAmount = Object.Inventory.Total("VATAmount") + Object.Expenses.Total("VATAmount");
	
	// Generate price and currency label.
	CurrencyTransactionsAccounting = Constants.FunctionalCurrencyTransactionsAccounting.Get();
	LabelStructure = New Structure("DocumentCurrency, SettlementsCurrency, ExchangeRate, RateNationalCurrency, AmountIncludesVAT, CurrencyTransactionsAccounting, CounterpartyPriceKind, VATTaxation", Object.DocumentCurrency, SettlementsCurrency, Object.ExchangeRate, RateNationalCurrency, Object.AmountIncludesVAT, CurrencyTransactionsAccounting, Object.CounterpartyPriceKind, Object.VATTaxation);
	PricesAndCurrency = GenerateLabelPricesAndCurrency(LabelStructure);
	
	SetVisibleAndEnabled();
	
	User = Users.CurrentUser();
	
	SettingValue = SmallBusinessReUse.GetValueByDefaultUser(User, "MainWarehouse");
	MainWarehouse = ?(ValueIsFilled(SettingValue), SettingValue, SmallBusinessServer.MainWarehouse());
	
	SettingValue = SmallBusinessReUse.GetValueByDefaultUser(User, "MainDepartment");
	MainDepartment = ?(ValueIsFilled(SettingValue), SettingValue, Catalogs.StructuralUnits.MainDepartment);
	
	// Setting contract visible.
	SetContractVisible();
	
	// PickProductsAndServicesInDocuments
	PickProductsAndServicesInDocuments.AssignPickForm(SelectionOpenParameters, Object.Ref.Metadata().Name, "Inventory");
	PickProductsAndServicesInDocuments.AssignPickForm(SelectionOpenParameters, Object.Ref.Metadata().Name, "Expenses");
	// End PickProductsAndServicesInDocuments
	
	// StandardSubsystems.AdditionalReportsAndDataProcessors
	AdditionalReportsAndDataProcessors.OnCreateAtServer(ThisForm);
	// End StandardSubsystems.AdditionalReportsAndDataProcessors
	
	// StandardSubsystems.DataImportFromExternalSources
	DataImportFromExternalSources.OnCreateAtServer(Metadata.Documents.SupplierInvoice.TabularSections.Inventory, DataLoadSettings, ThisObject);
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
	
	// Serial numbers
	UseSerialNumbersBalance = WorkWithSerialNumbers.UseSerialNumbersBalance();
	
	// ССВ Numbers
	TSNames = New Array;
	TSNames.Add(New Structure("CheckFieldName, AppearanceFieldName", "Object.Inventory.CountryOfOrigin", "InventoryCCDNo"));
	
	CargoCustomsDeclarationsServer.OnCreateAtServer(ThisForm, TSNames, CashValues);
	CashValues.Insert("FormModified", False);
	CashValues.Insert("AttributesToProcess", New Array);
	
	// GroupRowsChange
	FillActionsList(NameTSInventory());
	GroupRowsChangeServer.OnCreateAtServer(GroupRowsChangeItemsServer(NameTSInventory()), ThisObject.InventoryRowsChangeAction);
	InventoryRowsChangeActionOnOpen = InventoryRowsChangeAction;
	SetMark(NameTSInventory(), True);
	
	If InventoryRowsChangeActionOnOpen = Enums.BulkRowChangeActions.CreateProductsAndServicesBatches Then
		InventoryRowsChangeValue = NStr("en='Партия создана автоматически';ru='Партия создана автоматически';vi='Lô hàng được tạo tự động'");
	EndIf;
	
	FillActionsList(TSNameExpenses());
	GroupRowsChangeServer.OnCreateAtServer(GroupRowsChangeItemsServer(TSNameExpenses()), ThisObject.ExpensesRowsChangeAction);
	ExpensesRowsChangeActionOnOpen = ExpensesRowsChangeAction;
	SetMark(TSNameExpenses(), True);
	// End GroupRowsChange

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
	
	OrderIsFilled = False;
	FilledOrderReturn = False;
	For Each TSRow IN Object.Inventory Do
		If ValueIsFilled(TSRow.Order) Then
			If TypeOf(TSRow.Order) = Type("DocumentRef.PurchaseOrder") Then
				OrderIsFilled = True;
			Else
				FilledOrderReturn = True;
			EndIf;
			Break;
		EndIf;
	EndDo;
	
	If OrderIsFilled Then
		Notify("Record_SupplierInvoice", Object.Ref);
	EndIf;
	
	If FilledOrderReturn Then
		Notify("Record_SupplierInvoiceReturn", Object.Ref);
	EndIf;
	
	Notify("NotificationAboutChangingDebt");
	
	// CWP
	If TypeOf(ThisForm.FormOwner) = Type("ManagedForm")
		AND Find(ThisForm.FormOwner.FormName, "DocumentForm_CWP") > 0 
		Then
		Notify("CWP_Write_SupplierInvoiceReturn", New Structure("Ref, Number, Date, OperationKind", Object.Ref, Object.Number, Object.Date, Object.OperationKind));
	EndIf;
	// End CWP
	
EndProcedure // AfterWrite()

// Procedure - event handler of the form BeforeWrite
//
&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	// StandardSubsystems.PerformanceEstimation
	PerformanceEstimationClientServer.StartTimeMeasurement("DocumentSupplierInvoicePosting");
	// StandardSubsystems.PerformanceEstimation
	
EndProcedure

&AtServer
// Procedure-handler of the BeforeWriteAtServer event.
// 
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
				Message.Message();
				Return;
			Else
				Message.Message();
			EndIf;
		EndIf;
		
		If SmallBusinessReUse.GetAdvanceOffsettingSettingValue() = Enums.YesNo.Yes
			AND CurrentObject.OperationKind = Enums.OperationKindsSupplierInvoice.ReceiptFromVendor
			AND CurrentObject.Prepayment.Count() = 0 Then
			FillPrepayment(CurrentObject);
		EndIf;
		
	EndIf;
	
	// "Properties" mechanism handler
	PropertiesManagement.BeforeWriteAtServer(ThisForm, CurrentObject);
	// "Properties" mechanism handler
	
EndProcedure // BeforeWriteAtServer()

// Procedure - event handler OnOpen.
//
&AtClient
Procedure OnOpen(Cancel)
	
	// Peripherals
	EquipmentManagerClientOverridable.StartConnectingEquipmentOnFormOpen(ThisForm, "BarCodeScanner");
	// End Peripherals
	
	// StandardSubsystems.Properties
	PropertiesManagementClient.AfterLoadAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// ГрупповоеИзменениеСтрок
	DefineChangeObject(NameTSInventory());
	DefineChangeObject(TSNameExpenses());
	// Конец ГрупповоеИзменениеСтрок

EndProcedure // OnOpen()

// Procedure - event handler OnClose.
//
&AtClient
Procedure OnClose(Exit)
	
	If Not Exit Then
		// ГрупповоеИзменениеСтрок
		SaveCurrentRowChangeAction();
	EndIf;

	// Peripherals
	EquipmentManagerClientOverridable.StartDisablingEquipmentOnCloseForm(ThisForm);
	// End Peripherals
	
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
		
		CurrentPageInventory	= Items.Pages.CurrentPage = Items.GroupInventory;
		TabularSectionName 		= ?(CurrentPageInventory, "Inventory", "Expenses");
		
		GetInventoryFromStorage(InventoryAddressInStorage, TabularSectionName, CurrentPageInventory, CurrentPageInventory);
		
		RefreshFormFooter();
		
	ElsIf EventName = "SerialNumbersSelection"
		AND ValueIsFilled(Parameter) 
		//Form owner checkup
		AND Source <> New UUID("00000000-0000-0000-0000-000000000000")
		AND Source = UUID
		Then
		
		ChangedCount = GetSerialNumbersFromStorage(Parameter.AddressInTemporaryStorage, Parameter.RowKey);
		If ChangedCount Then
			CalculateAmountInTabularSectionLine("Inventory");
		EndIf; 		
		
	EndIf;
	
EndProcedure // NotificationProcessing()

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

// Procedure - command handler of the tabular section command panel.
//
&AtClient
Procedure DistributeExpensesByQuantity(Command)
	
	DistributeTabSectExpensesByQuantity();
		
EndProcedure // DistributeExpensesByCount()

// Procedure - command handler of the tabular section command panel.
//
&AtClient
Procedure DistributeExpensesByAmount(Command)
	
	DistributeTabSectExpensesByAmount();
		
EndProcedure // DistributeExpensesByAmount()

// Procedure - command handler of the tabular section command panel.
//
&AtClient
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
		OrderStructure.Order = ?(CurItem.Order = Undefined, PredefinedValue("Document.PurchaseOrder.EmptyRef"), CurItem.Order);
		OrderStructure.Total = CurItem.Total;
		OrdersArray.Add(OrderStructure);
	EndDo;
	For Each CurItem IN Object.Expenses Do
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
		?(Object.OperationKind = PredefinedValue("Enum.OperationKindsSupplierInvoice.ReceiptFromVendor"), True, False), // Pick
		True, // IsOrder
		OrderInHeader, // OrderInHeader
		Company, // Company
		?(CounterpartyDoSettlementsByOrders, ?(OrderInHeader, Object.Order, OrdersArray), Undefined), // Order
		Object.Date, // Date
		Object.Ref, // Ref
		Object.Counterparty, // Counterparty
		Object.Contract, // Contract
		Object.ExchangeRate, // ExchangeRate
		Object.Multiplicity, // Multiplicity
		Object.DocumentCurrency, // DocumentCurrency
		Object.Inventory.Total("Total") + Object.Expenses.Total("Total")
	);
	
	If Object.OperationKind = PredefinedValue("Enum.OperationKindsSupplierInvoice.ReceiptFromVendor") Then
		ReturnCode = Undefined;

		OpenForm("CommonForm.SupplierAdvancesPickForm", SelectionParameters,,,,, New NotifyDescription("EditPrepaymentOffsetEnd1", ThisObject, New Structure("AddressPrepaymentInStorage, SelectionParameters", AddressPrepaymentInStorage, SelectionParameters)));
        Return;
	ElsIf Object.OperationKind = PredefinedValue("Enum.OperationKindsSupplierInvoice.ReturnFromCustomer") Then
		OpenForm("CommonForm.CustomerAdvancesPickForm", SelectionParameters,,,,, New NotifyDescription("EditPrepaymentOffsetEnd", ThisObject, New Structure("AddressPrepaymentInStorage", AddressPrepaymentInStorage)));
        Return;
	EndIf;
	
	EditPrepaymentOffsetFragment1(AddressPrepaymentInStorage, ReturnCode);
EndProcedure

&AtClient
Procedure EditPrepaymentOffsetEnd1(Result, AdditionalParameters) Export
    
    AddressPrepaymentInStorage = AdditionalParameters.AddressPrepaymentInStorage;
    SelectionParameters = AdditionalParameters.SelectionParameters;
    
    
    ReturnCode = Result;
    
    EditPrepaymentOffsetFragment1(AddressPrepaymentInStorage, ReturnCode);

EndProcedure

&AtClient
Procedure EditPrepaymentOffsetFragment1(Val AddressPrepaymentInStorage, Val ReturnCode)
    
    EditPrepaymentOffsetFragment(AddressPrepaymentInStorage, ReturnCode);

EndProcedure

&AtClient
Procedure EditPrepaymentOffsetEnd(Result, AdditionalParameters) Export
    
    AddressPrepaymentInStorage = AdditionalParameters.AddressPrepaymentInStorage;
    
    
    ReturnCode = Result;
    
    EditPrepaymentOffsetFragment(AddressPrepaymentInStorage, ReturnCode);

EndProcedure

&AtClient
Procedure EditPrepaymentOffsetFragment(Val AddressPrepaymentInStorage, Val ReturnCode)
    
    If (Object.OperationKind = PredefinedValue("Enum.OperationKindsSupplierInvoice.ReceiptFromVendor")
        OR Object.OperationKind = PredefinedValue("Enum.OperationKindsSupplierInvoice.ReturnFromCustomer"))
        AND (ReturnCode = DialogReturnCode.OK) Then
        GetPrepaymentFromStorage(AddressPrepaymentInStorage);
    EndIf;

EndProcedure // EditPrepaymentOffset()

// You can call the procedure by clicking
// the button "FillByBasis" of the tabular field command panel.
//
&AtClient
Procedure FillByBasis(Command)
	
	Response = Undefined;
	ShowQueryBox(New NotifyDescription("FillByBasisEnd", ThisObject), NStr("en='The  document will be fully filled out according to the ""Basis"". Continue?';ru='Документ будет полностью перезаполнен по ""Основанию""! Продолжить?';vi='Chứng từ sẽ được điền lại toàn bộ theo ""Cơ sở""! Tiếp tục?'"), QuestionDialogMode.YesNo, 0);
	
EndProcedure

&AtClient
Procedure FillByBasisEnd(Result, AdditionalParameters) Export
    
    Response = Result;
    If Response = DialogReturnCode.Yes Then
        
        FillByDocument(Object.BasisDocument);
        SetVisibleAndEnabled();
        
        LabelStructure = New Structure("DocumentCurrency, SettlementsCurrency, ExchangeRate, RateNationalCurrency, AmountIncludesVAT, CurrencyTransactionsAccounting, CounterpartyPriceKind, VATTaxation", Object.DocumentCurrency, SettlementsCurrency, Object.ExchangeRate, RateNationalCurrency, Object.AmountIncludesVAT, CurrencyTransactionsAccounting, Object.CounterpartyPriceKind, Object.VATTaxation);
        PricesAndCurrency = GenerateLabelPricesAndCurrency(LabelStructure);
        
        RefreshFormFooter();
        
    EndIf;

EndProcedure // FillByBasis()

// You can call the procedure by clicking
// the button "FillByOrder" of the tabular field command panel.
//
&AtClient
Procedure FillByOrder(Command)
	
	Response = Undefined;
	ShowQueryBox(New NotifyDescription("FillEndByOrder", ThisObject), NStr("en='The  document will be fully filled out according to the ""Order"". Continue?';ru='Документ будет полностью перезаполнен по ""Заказу""! Продолжить выполнение операции?';vi='Chứng từ sẽ được điền lại toàn bộ theo ""Đơn hàng""! Tiếp tục thực hiện thao tác?'"), QuestionDialogMode.YesNo, 0);
	
EndProcedure

&AtClient
Procedure FillEndByOrder(Result, AdditionalParameters) Export
    
    Response = Result;
    If Response = DialogReturnCode.Yes Then
        FillByDocument(Object.Order);
        SetVisibleAndEnabled();
        
        LabelStructure = New Structure("DocumentCurrency, SettlementsCurrency, ExchangeRate, RateNationalCurrency, AmountIncludesVAT, CurrencyTransactionsAccounting, CounterpartyPriceKind, VATTaxation", Object.DocumentCurrency, SettlementsCurrency, Object.ExchangeRate, RateNationalCurrency, Object.AmountIncludesVAT, CurrencyTransactionsAccounting, Object.CounterpartyPriceKind, Object.VATTaxation);
        PricesAndCurrency = GenerateLabelPricesAndCurrency(LabelStructure);
        
        RefreshFormFooter();
        
    EndIf;

EndProcedure // FillByOrder()

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
			CalculateAmountInTabularSectionLine("Inventory", TabularSectionRow);
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

// Procedure - command handler DocumentSetting.
//
&AtClient
Procedure DocumentSetting(Command)
	
	// 1. Form parameter structure to fill "Document setting" form.
	ParametersStructure = New Structure;
	ParametersStructure.Insert("PurchaseOrderPositionInReceiptDocuments", 	Object.PurchaseOrderPosition);
	ParametersStructure.Insert("WereMadeChanges", 								False);
	
	StructureDocumentSetting = Undefined;

	
	OpenForm("CommonForm.DocumentSetting", ParametersStructure,,,,, New NotifyDescription("DocumentSettingEnd", ThisObject));
	
EndProcedure

&AtClient
Procedure DocumentSettingEnd(Result, AdditionalParameters) Export
    
    // 2. Open the form "Prices and Currency".
    StructureDocumentSetting = Result;
    
    // 3. Apply changes made in "Document setting" form.
    If TypeOf(StructureDocumentSetting) = Type("Structure") AND StructureDocumentSetting.WereMadeChanges Then
        
        Object.PurchaseOrderPosition = StructureDocumentSetting.PurchaseOrderPositionInReceiptDocuments;
        SetVisibleFromUserSettings();
        
    EndIf;

EndProcedure

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
		StructureData = GetDataDateOnChange(DateBeforeChange, SettlementsCurrency);
		If StructureData.DATEDIFF <> 0 Then
			Object.Number = "";
		EndIf;
		
		If ValueIsFilled(SettlementsCurrency) Then
			RecalculateExchangeRateMultiplicitySettlementCurrency(StructureData);
		EndIf;	
		
		LabelStructure = New Structure("DocumentCurrency, SettlementsCurrency, ExchangeRate, RateNationalCurrency, AmountIncludesVAT, CurrencyTransactionsAccounting, CounterpartyPriceKind, VATTaxation", Object.DocumentCurrency, SettlementsCurrency, Object.ExchangeRate, RateNationalCurrency, Object.AmountIncludesVAT, CurrencyTransactionsAccounting, Object.CounterpartyPriceKind, Object.VATTaxation);
		PricesAndCurrency = GenerateLabelPricesAndCurrency(LabelStructure);
		
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
	StructureData = GetCompanyDataOnChange();
	Company = StructureData.Company;
	
	Object.Contract = GetContractByDefault(Object.Ref, Object.Counterparty, Object.Company, Object.OperationKind);
	ProcessContractChange();
	
	LabelStructure = New Structure("DocumentCurrency, SettlementsCurrency, ExchangeRate, RateNationalCurrency, AmountIncludesVAT, CurrencyTransactionsAccounting, CounterpartyPriceKind, VATTaxation", Object.DocumentCurrency, SettlementsCurrency, Object.ExchangeRate, RateNationalCurrency, Object.AmountIncludesVAT, CurrencyTransactionsAccounting, Object.CounterpartyPriceKind, Object.VATTaxation);
	PricesAndCurrency = GenerateLabelPricesAndCurrency(LabelStructure);
	
EndProcedure // CompanyOnChange()

// Procedure - event handler OnChange of the OperationKind input field.
//
&AtClient
Procedure OperationKindOnChange(Item)
	
	ProcessOperationKindChange();
	ProcessContractChange();
	
EndProcedure // OperationKindOnChange()

// Procedure - event handler OnChange of the StructuralUnit input field.
//
&AtClient
Procedure StructuralUnitOnChange(Item)
	
	SetVisibleAndEnabled();
	
EndProcedure // StructuralUnitOnChange()

// Procedure - event handler OnChange of the input field IncludeExpensesInCostPrice.
//
&AtClient
Procedure IncludeExpensesInCostPriceOnChange(Item)
	
	If Object.IncludeExpensesInCostPrice Then
		Items.Expenses.ChildItems.ExpensesOrder.Visible = False;
		Items.Expenses.ChildItems.ExpensesStructuralUnit.Visible = False;
		Items.Expenses.ChildItems.ExpensesBusinessActivity.Visible = False;
		Items.AllocateExpenses.Visible = True;
		
		Items.Inventory.ChildItems.InventoryAmountExpenses.Visible = True;
		
	Else
		Items.Expenses.ChildItems.ExpensesOrder.Visible = True;
		Items.Expenses.ChildItems.ExpensesStructuralUnit.Visible = True;
		Items.Expenses.ChildItems.ExpensesBusinessActivity.Visible = True;
		Items.AllocateExpenses.Visible = False;
		
		Items.Inventory.ChildItems.InventoryAmountExpenses.Visible = False;
		
		For Each StringInventory IN Object.Inventory Do
			StringInventory.AmountExpenses = 0;
		EndDo;
		
		For Each RowsExpenses in Object.Expenses Do
			RowsExpenses.StructuralUnit = MainDepartment;
		EndDo;
		
	EndIf;
	
EndProcedure // IncludeExpensesInCostPriceOnChange()

// Procedure - event handler OnChange of the Counterparty input field.
// Clears the contract and tabular section.
//
&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyBeforeChange = Counterparty;
	CounterpartyDoSettlementsByOrdersBeforeChange = CounterpartyDoSettlementsByOrders;
	Counterparty = Object.Counterparty;
	
	If CounterpartyBeforeChange <> Object.Counterparty Then
		
		ClearBasisOnChangeCounterpartyContract();
		
		ContractVisibleBeforeChange = Items.Contract.Visible;
		
		StructureData = GetDataCounterpartyOnChange(Object.Date, Object.DocumentCurrency, Object.Counterparty, Object.Company);
		
		Object.Contract = StructureData.Contract;
		ContractBeforeChange = Contract;
		Contract = Object.Contract;
		
		If Object.Prepayment.Count() > 0
		   AND Object.Contract <> ContractBeforeChange Then
			
			ShowQueryBox(New NotifyDescription("CounterpartyOnChangeEnd", ThisObject, New Structure("CounterpartyBeforeChange, ContractBeforeChange, CounterpartyDoSettlementsByOrdersBeforeChange, ContractVisibleBeforeChange, StructureData", CounterpartyBeforeChange, ContractBeforeChange, CounterpartyDoSettlementsByOrdersBeforeChange, ContractVisibleBeforeChange, StructureData)),
				NStr("en='Prepayment setoff will be cleared, continue?';ru='Зачет предоплаты будет очищен, продолжить?';vi='Sẽ hủy việc khấu trừ khoản trả trước, tiếp tục?'"),
				QuestionDialogMode.YesNo
			);
			Return;
			
		EndIf;
		
		CounterpartyOnChangeFragment(ContractBeforeChange, StructureData);
		
	Else
		
		Object.Contract = Contract; // Restore the cleared contract automatically.
		Object.Order = Order;
		
	EndIf;
	
EndProcedure // CounterpartyOnChange()

&AtClient
Procedure CounterpartyOnChangeEnd(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		Object.Prepayment.Clear();
	Else 
		Object.Counterparty = AdditionalParameters.CounterpartyBeforeChange;
		Counterparty = AdditionalParameters.CounterpartyBeforeChange;
		Object.Contract = AdditionalParameters.ContractBeforeChange;
		Contract = AdditionalParameters.ContractBeforeChange;
		Object.Order = Order;
		CounterpartyDoSettlementsByOrders = AdditionalParameters.CounterpartyDoSettlementsByOrdersBeforeChange;
		Items.Contract.Visible = AdditionalParameters.ContractVisibleBeforeChange;
		Return;
	EndIf;
	
	CounterpartyOnChangeFragment(AdditionalParameters.ContractBeforeChange, AdditionalParameters.StructureData);
	
EndProcedure

&AtClient
Procedure CounterpartyOnChangeFragment(ContractBeforeChange, StructureData)
	
	SettlementsCurrencyBeforeChange = SettlementsCurrency;
	SettlementsCurrency = StructureData.SettlementsCurrency;
	
	If Not StructureData.AmountIncludesVAT = Undefined Then
		Object.AmountIncludesVAT = StructureData.AmountIncludesVAT;
	EndIf;
	
	If ValueIsFilled(Object.Contract) Then 
		Object.ExchangeRate      = ?(StructureData.SettlementsCurrencyRateRepetition.ExchangeRate = 0, 1, StructureData.SettlementsCurrencyRateRepetition.ExchangeRate);
		Object.Multiplicity = ?(StructureData.SettlementsCurrencyRateRepetition.Multiplicity = 0, 1, StructureData.SettlementsCurrencyRateRepetition.Multiplicity);
	EndIf;
	
	PriceKindChanged = Object.CounterpartyPriceKind <> StructureData.CounterpartyPriceKind 
		AND ValueIsFilled(StructureData.CounterpartyPriceKind);
	NewContractAndCalculationCurrency = ValueIsFilled(Object.Contract) AND ValueIsFilled(SettlementsCurrency) 
		AND Object.Contract <> ContractBeforeChange AND SettlementsCurrencyBeforeChange <> StructureData.SettlementsCurrency;
	OpenFormPricesAndCurrencies = NewContractAndCalculationCurrency AND Object.DocumentCurrency <> StructureData.SettlementsCurrency
		AND (Object.Inventory.Count() > 0 OR Object.Expenses.Count() > 0);
	
	StructureData.Insert("PriceKindChanged", PriceKindChanged);
	
	// If the contract has changed and the kind of counterparty prices is selected, automatically register incoming prices/
	Object.RegisterVendorPrices = StructureData.PriceKindChanged AND Not Object.CounterpartyPriceKind.IsEmpty();
	Order = Object.Order;
	
	If PriceKindChanged Then
		Object.CounterpartyPriceKind = StructureData.CounterpartyPriceKind;
	EndIf;
	Object.RegisterVendorPrices = True;
	Object.DocumentCurrency = StructureData.SettlementsCurrency;
	
	If OpenFormPricesAndCurrencies Then
		
		WarningText = "";
		
		If PriceKindChanged Then
			WarningText = NStr("en='The price and discount conditions in the contract with counterparty differ from price and discount in the document! "
"Perhaps you have to refill prices.';ru='Договор с контрагентом предусматривает условия цен и скидок, отличные от установленных в документе! "
"Возможно, необходимо перезаполнить цены.';vi='Hợp đồng với đối tác xem xét điều kiện giá và chiết khấu mà khác với điều kiện đã thiết lập trong chứng từ!"
"Có thể, cần điền lại đơn giá."
"'") + Chars.LF + Chars.LF;
		EndIf;
		
		WarningText = WarningText + NStr("en='Settlement currency of the contract with counterparty changed!"
"It is necessary to check the document currency!';ru='Изменилась валюта расчетов по договору с контрагентом!"
"Необходимо проверить валюту документа!';vi='Đã trhay đổi tiền tệ hạch toán theo hợp đồng với đối tác!"
"Cần kiểm tra tiền tệ của chứng từ!'"
		);
		ProcessChangesOnButtonPricesAndCurrencies(SettlementsCurrencyBeforeChange, True, PriceKindChanged, WarningText);
		
	ElsIf ValueIsFilled(Object.Contract) 
		AND PriceKindChanged Then
		
		RecalculationRequired = (Object.Inventory.Count() > 0);
		
		Object.CounterpartyPriceKind	= StructureData.CounterpartyPriceKind;
		LabelStructure 			= 
			New Structure("DocumentCurrency, SettlementsCurrency, ExchangeRate, RateNationalCurrency, AmountIncludesVAT, CurrencyTransactionsAccounting, CounterpartyPriceKind, VATTaxation", 
							Object.DocumentCurrency, 
							SettlementsCurrency, 
							Object.ExchangeRate, 
							RateNationalCurrency, 
							Object.AmountIncludesVAT, 
							CurrencyTransactionsAccounting, 
							Object.CounterpartyPriceKind, 
							Object.VATTaxation);
							
		PricesAndCurrency 				= GenerateLabelPricesAndCurrency(LabelStructure);
		
		If RecalculationRequired Then
			
			Message = NStr("en='The counterparty contract allows for the kind of prices other than prescribed in the document! "
"Recalculate the document according to the contract?';ru='Договор с контрагентом предусматривает вид цен, отличный от установленного в документе! "
"Пересчитать документ в соответствии с договором?';vi='Hợp đồng với đối tác xem xét dạng giá mà khác với dạng giá đã đặt trong chứng từ!"
"Đọc lại chứng từ tương ứng với hợp đồng?'");
			ShowQueryBox(New NotifyDescription("CounterpartyOnChangeFragmentEnd", ThisObject, New Structure("ContractBeforeChange, SettlementsCurrencyBeforeChange, StructureData", ContractBeforeChange, SettlementsCurrencyBeforeChange, StructureData)), 
				Message,
				QuestionDialogMode.YesNo
			);
			Return;
			
		EndIf;
		
	Else
		
		LabelStructure 			= 
			New Structure("DocumentCurrency, SettlementsCurrency, ExchangeRate, RateNationalCurrency, AmountIncludesVAT, CurrencyTransactionsAccounting, CounterpartyPriceKind, VATTaxation", 
							Object.DocumentCurrency, 
							SettlementsCurrency, 
							Object.ExchangeRate, 
							RateNationalCurrency, 
							Object.AmountIncludesVAT, 
							CurrencyTransactionsAccounting, 
							Object.CounterpartyPriceKind, 
							Object.VATTaxation);
							
		PricesAndCurrency 				= GenerateLabelPricesAndCurrency(LabelStructure);
		
	EndIf;
	
	RefreshFormFooter();
	
EndProcedure

&AtClient
Procedure CounterpartyOnChangeFragmentEnd(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		SmallBusinessClient.RefillTabularSectionPricesByCounterpartyPriceKind(ThisForm, "Inventory");
		RefreshFormFooter();
		
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
	
	FormParameters = GetChoiceFormParameters(Object.Ref, Object.Company, Object.Counterparty, Object.Contract, Object.OperationKind);
	If FormParameters.ControlContractChoice Then
		
		StandardProcessing = False;
		OpenForm("Catalog.CounterpartyContracts.Form.ChoiceForm", FormParameters, Item);
		
	EndIf;
	
EndProcedure

// Procedure - event handler OnChange of the input field Order.
//
&AtClient
Procedure OrderOnChange(Item)
	
	OrderBefore = Order;
	Order = Object.Order;
	
	If Object.Prepayment.Count() > 0
	   AND OrderBefore <> Object.Order
	   AND Object.OperationKind = PredefinedValue("Enum.OperationKindsSupplierInvoice.ReceiptFromVendor") Then
		Mode = QuestionDialogMode.YesNo;
		Response = Undefined;
		ShowQueryBox(New NotifyDescription("OrderOnChangeEnd", ThisObject, New Structure("OrderBefore", OrderBefore)), NStr("en='Prepayment setoff will be cleared, continue?';ru='Зачет предоплаты будет очищен, продолжить?';vi='Sẽ hủy việc khấu trừ khoản trả trước, tiếp tục?'"), Mode, 0);
	EndIf;
	
EndProcedure

&AtClient
Procedure OrderOnChangeEnd(Result, AdditionalParameters) Export
    
    OrderBefore = AdditionalParameters.OrderBefore;
    
    
    Response = Result;
    If Response = DialogReturnCode.Yes Then
        Object.Prepayment.Clear();
    Else
        Object.Order = OrderBefore;
        Order = OrderBefore;
        Return;
    EndIf;

EndProcedure // OrderOnChange()

&AtClient
Procedure Attachable_ClickOnInformationLink(Item)
	
	InformationCenterClient.ClickOnInformationLink(ThisForm, Item);
	
EndProcedure

&AtClient
Procedure Attachable_ReferenceClickAllInformationLinks(Item)
	
	InformationCenterClient.ReferenceClickAllInformationLinks(ThisForm.FormName);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////PROCEDURE - EVENT HANDLERS OF TABULAR SECTION INVENTORY

&AtClient
Procedure InventoryOnStartEdit(Item, NewRow, Copy)
	
	If NewRow AND Copy Then
		Item.CurrentData.ConnectionKey = 0;
		Item.CurrentData.SerialNumbers = "";
	EndIf;	
		
	If Item.CurrentItem.Name = "SerialNumbersInventory" Then
		OpenSerialNumbersSelection();
	EndIf;
	
	// ГрупповоеИзменениеСтрок
	Item.CurrentData.Check = True;
	// Конец ГрупповоеИзменениеСтрок
	
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - EVENT HANDLERS OF TABULAR SECTION INVENTORY

// Procedure - event handler OnChange of the "Invetory" tabular section.
//
&AtClient
Procedure InventoryOnChange(Item)
	
	If LineCopyInventory = Undefined OR Not LineCopyInventory Then
		RefreshFormFooter();
	Else
		LineCopyInventory = False;
	EndIf;	
	
EndProcedure // InventoryOnChange()

// Procedure - event handler BeforeStartAdd of the "Inventory" tabular section.
//
&AtClient
Procedure InventoryBeforeAddRow(Item, Cancel, Copy, Parent, Group)
	
	If Copy Then
		TotalTotal = Object.Inventory.Total("Total") + Object.Expenses.Total("Total") + Item.CurrentData.Total;
		TotalVATAmount = Object.Inventory.Total("VATAmount") + Object.Expenses.Total("VATAmount") + Item.CurrentData.VATAmount;
		LineCopyInventory = True;
    EndIf;
	
EndProcedure // InventoryBeforeAddStart()

&AtClient
Procedure InventoryBeforeDeleteRow(Item, Cancel)
	
	CurrentData = Items.Inventory.CurrentData;
	
	// Serial numbers
	WorkWithSerialNumbersClientServer.DeleteSerialNumbersByConnectionKey(Object.SerialNumbers, CurrentData,,UseSerialNumbersBalance);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - EVENT HANDLERS OF THE INVENTORY TABULAR SECTION ATTRIBUTES

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
		StructureData.Insert("Characteristic", TabularSectionRow.Characteristic);
		StructureData.Insert("CounterpartyPriceKind", Object.CounterpartyPriceKind);
		StructureData.Insert("Factor", 1);
		
	EndIf;
	
	StructureData = GetDataProductsAndServicesOnChange(StructureData);
	
	TabularSectionRow.MeasurementUnit = StructureData.MeasurementUnit;
	TabularSectionRow.Quantity = 1;
	TabularSectionRow.Price = StructureData.Price;
	TabularSectionRow.VATRate = StructureData.VATRate;
	TabularSectionRow.Content = "";
	
	//Serial numbers
	WorkWithSerialNumbersClientServer.DeleteSerialNumbersByConnectionKey(Object.SerialNumbers, TabularSectionRow,,UseSerialNumbersBalance);
	
	CalculateAmountInTabularSectionLine("Inventory");
	
EndProcedure // InventoryProductsAndServicesOnChange()

// Procedure - event handler OnChange of the Characteristic input field.
//
&AtClient
Procedure InventoryCharacteristicOnChange(Item)
	
	TabularSectionRow = Items.Inventory.CurrentData;
		
	StructureData = New Structure;
	StructureData.Insert("ProductsAndServices",	 TabularSectionRow.ProductsAndServices);
	StructureData.Insert("Characteristic",	 TabularSectionRow.Characteristic);
		
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
	
	CalculateAmountInTabularSectionLine("Inventory");
	
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
	
	CalculateAmountInTabularSectionLine("Inventory");
	
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
	
	If StructureData.CurrentFactor <> 0 Then
		TabularSectionRow.Price = TabularSectionRow.Price * StructureData.Factor / StructureData.CurrentFactor;
	EndIf;
	
	CalculateAmountInTabularSectionLine("Inventory");
		
EndProcedure // InventoryMeasurementUnitChoiceProcessing()

// Procedure - event handler OnChange of the Price input field.
//
&AtClient
Procedure InventoryPriceOnChange(Item)
	
	CalculateAmountInTabularSectionLine("Inventory");
		
EndProcedure // InventoryPriceOnChange()

// Procedure - event handler OnChange of the Amount input field.
//
&AtClient
Procedure InventoryAmountOnChange(Item)
	
	TabularSectionRow = Items.Inventory.CurrentData;
	
	If TabularSectionRow.Quantity <> 0 Then
		TabularSectionRow.Price = TabularSectionRow.Amount / TabularSectionRow.Quantity;
	EndIf;
	
	CalculateVATSUM(TabularSectionRow);
	TabularSectionRow.Total = TabularSectionRow.Amount + ?(Object.AmountIncludesVAT, 0, TabularSectionRow.VATAmount);
	
EndProcedure // InventoryAmountOnChange()

// Procedure - event handler OnChange of the VATRate input field.
//
&AtClient
Procedure InventoryVATRateOnChange(Item)
	
	TabularSectionRow = Items.Inventory.CurrentData;
	
	CalculateVATSUM(TabularSectionRow);
	TabularSectionRow.Total = TabularSectionRow.Amount + ?(Object.AmountIncludesVAT, 0, TabularSectionRow.VATAmount);
	
EndProcedure  // InventoryVATRateOnChange()

// Procedure - event handler OnChange of the VATRate input field.
//
&AtClient
Procedure InventoryVATAmountOnChange(Item)
	
	TabularSectionRow = Items.Inventory.CurrentData;
	
	TabularSectionRow.Total = TabularSectionRow.Amount + ?(Object.AmountIncludesVAT, 0, TabularSectionRow.VATAmount);
	
EndProcedure // InventoryVATAmountOnChange()

////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - EVENT HANDLERS OF TABULAR SECTION INVENTORY

// Procedure - event handler OnChange of the "Costs" tabular section.
//
&AtClient
Procedure ExpensesOnChange(Item)
	
	If CloneRowsCosts = Undefined OR Not CloneRowsCosts Then
		RefreshFormFooter();
	Else
		CloneRowsCosts = False;
	EndIf;
	
EndProcedure // ExpensesOnChange()

// Procedure - event handler BeforeStartAdd of the "Inventory" tabular section.
//
&AtClient
Procedure ExpensesBeforeAddRow(Item, Cancel, Copy, Parent, Group)
	
	If Copy Then
		TotalTotal = Object.Inventory.Total("Total") + Object.Expenses.Total("Total") + Item.CurrentData.Total;
		TotalVATAmount = Object.Inventory.Total("VATAmount") + Object.Expenses.Total("VATAmount") + Item.CurrentData.VATAmount;
		CloneRowsCosts = True;
    EndIf;
	
EndProcedure // ExpensesBeforeStartAdd()

// Procedure - event handler AtStartEdit of the "Costs" tabular section.
//
&AtClient
Procedure ExpensesOnStartEdit(Item, NewRow, Copy)
	
	TabularSectionRow = Item.CurrentData;
	
	If NewRow Then
		
		TabularSectionRow = Items.Expenses.CurrentData;
		TabularSectionRow.StructuralUnit = MainDepartment;
		
	EndIf;
	
	// ГрупповоеИзменениеСтрок
	TabularSectionRow.Check = True;
	// Конец ГрупповоеИзменениеСтрок

	
EndProcedure // ExpensesOnStartEdit()

////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - EVENT HANDLERS OF THE COSTS TABULAR SECTION ATTRIBUTES

// Procedure - event handler OnChange of the ProductsAndServices input field.
//
&AtClient
Procedure ExpensesProductsAndServicesOnChange(Item)
	
	TabularSectionRow = Items.Expenses.CurrentData;
	
	StructureData = New Structure();
	StructureData.Insert("Company", Object.Company);
	StructureData.Insert("ProductsAndServices", TabularSectionRow.ProductsAndServices);
	StructureData.Insert("Characteristic", "");
	StructureData.Insert("VATTaxation", Object.VATTaxation);
	
	StructureData = GetDataProductsAndServicesOnChange(StructureData);
	
	TabularSectionRow.MeasurementUnit = StructureData.MeasurementUnit;
	TabularSectionRow.Quantity = 1;
	TabularSectionRow.Price = 0;
	TabularSectionRow.Amount = 0;
	TabularSectionRow.VATRate = StructureData.VATRate;
	TabularSectionRow.VATAmount = 0;
	TabularSectionRow.Total = 0;
	TabularSectionRow.Content = "";
	
	If StructureData.ClearOrderAndDepartment Then
		TabularSectionRow.StructuralUnit = Undefined;
		TabularSectionRow.Order = Undefined;
	ElsIf Not ValueIsFilled(TabularSectionRow.StructuralUnit) Then
		TabularSectionRow.StructuralUnit = MainDepartment;
	EndIf;
	
	If StructureData.ClearBusinessActivity Then
		TabularSectionRow.BusinessActivity = Undefined;
	Else
		TabularSectionRow.BusinessActivity = StructureData.BusinessActivity;
	EndIf;
	
EndProcedure // ExpensesProductsAndServicesOnChange()

// Procedure - event handler AutoPick of the Content input field.
//
&AtClient
Procedure CostsContentAutoComplete(Item, Text, ChoiceData, Parameters, Wait, StandardProcessing)
	
	If Wait = 0 Then
		
		StandardProcessing = False;
		
		TabularSectionRow = Items.Expenses.CurrentData;
		ContentPattern = SmallBusinessServer.GetContentText(TabularSectionRow.ProductsAndServices);
		
		ChoiceData = New ValueList;
		ChoiceData.Add(ContentPattern);
		
	EndIf;
	
EndProcedure

// Procedure - event handler OnChange of the Count input field.
//
&AtClient
Procedure ExpensesQuantityOnChange(Item)
	
	CalculateAmountInTabularSectionLine("Expenses");
	
EndProcedure // ExpensesQuantityOnChange()

// Procedure - event handler ChoiceProcessing of the MeasurementUnit input field.
//
&AtClient
Procedure ExpensesMeasurementUnitChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	TabularSectionRow = Items.Expenses.CurrentData;
	
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
	
	If StructureData.CurrentFactor <> 0 Then
		TabularSectionRow.Price = TabularSectionRow.Price * StructureData.Factor / StructureData.CurrentFactor;
	EndIf;
	
	CalculateAmountInTabularSectionLine("Expenses");
	
EndProcedure // ExpensesUOMSelectionDataProcessor()

// Procedure - event handler OnChange of the Price input field.
//
&AtClient
Procedure ExpensesPriceOnChange(Item)
	
	CalculateAmountInTabularSectionLine("Expenses");
	
EndProcedure // ExpensesPriceOnChange()

// Procedure - event handler OnChange of the Amount input field.
//
&AtClient
Procedure AmountExpensesOnChange(Item)
	
	TabularSectionRow = Items.Expenses.CurrentData;
	
	If TabularSectionRow.Quantity <> 0 Then
		TabularSectionRow.Price = TabularSectionRow.Amount / TabularSectionRow.Quantity;
	EndIf;
	
	CalculateVATSUM(TabularSectionRow);
	TabularSectionRow.Total = TabularSectionRow.Amount + ?(Object.AmountIncludesVAT, 0, TabularSectionRow.VATAmount);
	
EndProcedure // AmountExpensesOnChange()

// Procedure - event handler OnChange of the VATRate input field.
//
&AtClient
Procedure ExpensesVATRateOnChange(Item)
	
	TabularSectionRow = Items.Expenses.CurrentData;
	
	CalculateVATSUM(TabularSectionRow);
	TabularSectionRow.Total = TabularSectionRow.Amount + ?(Object.AmountIncludesVAT, 0, TabularSectionRow.VATAmount);
	
EndProcedure // ExpensesVATRateOnChange()

// Procedure - event handler OnChange of the VATRate input field.
//
&AtClient
Procedure AmountExpensesVATOnChange(Item)
	
	TabularSectionRow = Items.Expenses.CurrentData;
	
	TabularSectionRow.Total = TabularSectionRow.Amount + ?(Object.AmountIncludesVAT, 0, TabularSectionRow.VATAmount);
	
EndProcedure // ExpensesVATAmountOnChange()

// Procedure - SelectionStart event handler of the ExpensesBusinessActivity input field.
//
&AtClient
Procedure ExpensesBusinessActivityStartChoice(Item, ChoiceData, StandardProcessing)
	
	TabularSectionRow = Items.Expenses.CurrentData;
	
	StructureData = GetDataBusinessActivityStartChoice(TabularSectionRow.ProductsAndServices);
	
	If Not StructureData.AvailabilityOfPointingBusinessActivities Then
		StandardProcessing = False;
		ShowMessageBox(, NStr("en='Business area is not required for this type of expense.';ru='Для данного расхода направление деятельности не указывается!';vi='Đối với chi phí này không chỉ ra lĩnh vực hoạt động!'"));
	EndIf;
	
EndProcedure // ExpensesBusinessActivityStartChoice()

&AtClient
// Procedure - event handler SelectionStart of the StructuralUnit input field.
//
Procedure ExpensesStructuralUnitStartChoice(Item, ChoiceData, StandardProcessing)
	
	TabularSectionRow = Items.Expenses.CurrentData;
	
	StructureData = GetDataStructuralUnitStartChoice(TabularSectionRow.ProductsAndServices);
	
	If Not StructureData.AbilityToSpecifyDepartments Then
		StandardProcessing = False;
		ShowMessageBox(, NStr("en='Department is not required for this kind of expense.';ru='Для этого расхода подразделение не указывается!';vi='Đối với chi phí này chưa chỉ ra bộ phận!'"));
	EndIf;
	
EndProcedure // ExpensesStructuralUnitStartChoice()

&AtClient
// Procedure - event handler SelectionStart of input field Order.
//
Procedure ExpensesOrderStartChoice(Item, ChoiceData, StandardProcessing)
	
	TabularSectionRow = Items.Expenses.CurrentData;
	
	StructureData = GetDataOrderStartChoice(TabularSectionRow.ProductsAndServices);
	
	If Not StructureData.AbilityToSpecifyOrder Then
		StandardProcessing = False;
		ShowMessageBox(, NStr("en='The order is not specified for this type of expense.';ru='Для этого расхода заказ не указывается!';vi='Đối với chi phí này chưa chỉ ra đơn hàng!'"));
	EndIf;
	
EndProcedure // ExpensesOrderStartChoice()

&AtServer
// Procedure-handler of the FillCheckProcessingAtServer event.
//
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertiesManagement.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure // FillCheckProcessingAtServer()

// Procedure fills advances.
//
&AtServer
Procedure FillPrepayment(CurrentObject)
	
	CurrentObject.FillPrepayment();
	
EndProcedure // FillPrepayment()

&AtClient
Procedure BasisDocumentOnChange(Item)
	
	If Object.OperationKind = PredefinedValue("Enum.OperationKindsSupplierInvoice.ReturnFromCustomer")
		AND (NOT ValueIsFilled(Object.BasisDocument)
		OR (ValueIsFilled(Object.BasisDocument)
			AND TypeOf(Object.BasisDocument) <> Type("DocumentRef.CustomerInvoice")
			AND (TypeOf(Object.BasisDocument) = Type("DocumentRef.CustomerOrder")
			AND GetBaseDocumentOperationKind() <> PredefinedValue("Enum.OperationKindsCustomerOrder.WorkOrder")))) Then
		
		Items.Inventory.ChildItems.InventoryCostPrice.Visible = True;
		
	Else
		
		Items.Inventory.ChildItems.InventoryCostPrice.Visible = False;
		If Object.Inventory.Count() > 0 Then
			For Each StringInventory IN Object.Inventory Do
				StringInventory.Cost = 0;
			EndDo;
		EndIf;
		
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

#Region InteractiveActionResultHandlers

// Procedure-handler of the result of opening the "Prices and currencies" form
//
&AtClient
Procedure ProcessChangesOnButtonPricesAndCurrenciesEnd(ClosingResult, AdditionalParameters) Export
	
	// 3. Refill the tabular section "Inventory" if changes were made to the form "Prices and Currency".
	If TypeOf(ClosingResult) = Type("Structure")
		AND ClosingResult.WereMadeChanges Then
		
		Object.DocumentCurrency = ClosingResult.DocumentCurrency;
		Object.ExchangeRate = ClosingResult.PaymentsRate;
		Object.Multiplicity = ClosingResult.SettlementsMultiplicity;
		Object.VATTaxation = ClosingResult.VATTaxation;
		Object.AmountIncludesVAT = ClosingResult.AmountIncludesVAT;
		Object.IncludeVATInPrice = ClosingResult.IncludeVATInPrice;
		Object.CounterpartyPriceKind = ClosingResult.CounterpartyPriceKind;
		Object.RegisterVendorPrices = ClosingResult.RegisterVendorPrices;
		// DiscountCards
		If ValueIsFilled(ClosingResult.DiscountCard) AND ValueIsFilled(ClosingResult.Counterparty) AND Not Object.Counterparty.IsEmpty() Then
			If ClosingResult.Counterparty = Object.Counterparty Then
				Object.DiscountCard = ClosingResult.DiscountCard;
			Else // We will show the message and we will not change discount card data.
				CommonUseClientServer.MessageToUser(
				NStr("en='Discount card is not read. Discount card owner does not match the counterparty in the document.';ru='Дисконтная карта не считана. Владелец дисконтной карты не совпадает с контрагентом в документе.';vi='Chưa đọc thẻ ưu đãi. Chủ sở hữu thẻ ưu đãi không trùng với đối tác trong chứng từ.'"),
				,
				"Counterparty",
				"Object");
			EndIf;
		Else
			Object.DiscountCard = ClosingResult.DiscountCard;
		EndIf;
		// End DiscountCards
		
		// Recalculate prices by kind of prices.
		If ClosingResult.RefillPrices Then
			SmallBusinessClient.RefillTabularSectionPricesByCounterpartyPriceKind(ThisForm, "Inventory");
		EndIf;

		// Recalculate prices by currency.
		If Not ClosingResult.RefillPrices
			AND ClosingResult.RecalculatePrices Then
			SmallBusinessClient.RecalculateTabularSectionPricesByCurrency(ThisForm, AdditionalParameters.SettlementsCurrencyBeforeChange, "Inventory");
		EndIf;
		
		If ClosingResult.RecalculatePrices Then
			SmallBusinessClient.RecalculateTabularSectionPricesByCurrency(ThisForm, AdditionalParameters.SettlementsCurrencyBeforeChange, "Expenses");
		EndIf;
		
		// Recalculate the amount if VAT taxation flag is changed.
		If ClosingResult.VATTaxation <> ClosingResult.PrevVATTaxation Then
			FillVATRateByVATTaxation();
		EndIf;
		
		// Recalculate the amount if the "Amount includes VAT" flag is changed.
		If Not ClosingResult.RefillPrices
			AND ClosingResult.AmountIncludesVAT <> ClosingResult.PrevAmountIncludesVAT Then
			SmallBusinessClient.RecalculateTabularSectionAmountByFlagAmountIncludesVAT(ThisForm, "Inventory");
		EndIf;
		
		If ClosingResult.AmountIncludesVAT <> ClosingResult.PrevAmountIncludesVAT Then
			SmallBusinessClient.RecalculateTabularSectionAmountByFlagAmountIncludesVAT(ThisForm, "Expenses");
		EndIf;
			
		For Each TabularSectionRow IN Object.Prepayment Do
			TabularSectionRow.PaymentAmount = SmallBusinessClient.RecalculateFromCurrencyToCurrency(
				TabularSectionRow.SettlementsAmount,
				TabularSectionRow.ExchangeRate,
				?(Object.DocumentCurrency = NationalCurrency, RateNationalCurrency, Object.ExchangeRate),
				TabularSectionRow.Multiplicity,
				?(Object.DocumentCurrency = NationalCurrency, RepetitionNationalCurrency, Object.Multiplicity));
		EndDo;
		
	EndIf;
	
	LabelStructure = New Structure("DocumentCurrency, SettlementsCurrency, ExchangeRate, RateNationalCurrency, AmountIncludesVAT, CurrencyTransactionsAccounting, CounterpartyPriceKind, VATTaxation", Object.DocumentCurrency, SettlementsCurrency, Object.ExchangeRate, RateNationalCurrency, Object.AmountIncludesVAT, CurrencyTransactionsAccounting, Object.CounterpartyPriceKind, Object.VATTaxation);
	PricesAndCurrency = GenerateLabelPricesAndCurrency(LabelStructure);
	
	RefreshFormFooter();
	
EndProcedure // ProcessChangesOnButtonPricesAndCurrenciesEnd()

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

#Region DataImportFromExternalSources

&AtClient
Procedure LoadFromFileServices(Command)
	
	DataLoadSettings.FillingObjectFullName = "Document.SupplierInvoice.TabularSection.Expenses";
	
	DataLoadSettings.Insert("TabularSectionFullName", "SupplierInvoice.Expenses");
	DataLoadSettings.Insert("Title", NStr("en='Import services from file';ru='Загрузка услуг из файла';vi='Kết nhập dịch vụ từ tệp'"));
	
	NotifyDescription = New NotifyDescription("ImportDataFromExternalSourceResultDataProcessor", ThisObject, DataLoadSettings);
	
	DataImportFromExternalSourcesClient.ShowDataImportFormFromExternalSource(DataLoadSettings, NotifyDescription, ThisObject);
	
EndProcedure

&AtClient
Procedure LoadFromFileInventory(Command)
	
	DataLoadSettings.FillingObjectFullName = "Document.SupplierInvoice.TabularSection.Inventory";
	
	DataLoadSettings.Insert("TabularSectionFullName",	"SupplierInvoice.Inventory");
	DataLoadSettings.Insert("Title",					NStr("en='Import inventory from file';ru='Загрузка запасов из файла';vi='Kết nhập vật tư từ tệp'"));
	DataLoadSettings.Insert("OrderPositionInDocument",	Object.PurchaseOrderPosition);
	
	NotifyDescription = New NotifyDescription("ImportDataFromExternalSourceResultDataProcessor", ThisObject, DataLoadSettings);
	
	DataImportFromExternalSourcesClient.ShowDataImportFormFromExternalSource(DataLoadSettings, NotifyDescription, ThisObject);
	
EndProcedure

&AtClient
Procedure ImportDataFromExternalSourceResultDataProcessor(ImportResult, AdditionalParameters) Export
	
	If TypeOf(ImportResult) = Type("Structure") Then
		ProcessPreparedData(ImportResult);
		RefreshFormFooter();
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessPreparedData(ImportResult)
	
	DataImportFromExternalSourcesOverridable.ImportDataFromExternalSourceResultDataProcessor(ImportResult, Object);
	
EndProcedure

#EndRegion

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

//Rise { Aghabekyan 2017-02-11
#Region CopyPasteRows

&AtClient
Procedure InventoryCopyRows(Command)
	CopyRowsTabularPart("Inventory");
EndProcedure

&AtClient
Procedure CopyRowsTabularPart(TabularPartName)
	
	If TabularPartCopyClient.CanCopyRows(Object[TabularPartName],Items[TabularPartName].CurrentData) Then
		
		CountOfCopied = 0;
		CopyRowsTabularPartAtSever(TabularPartName, CountOfCopied);
		TabularPartCopyClient.NotifyUserCopyRows(CountOfCopied);
		
	EndIf;
	
EndProcedure

&AtServer 
Procedure CopyRowsTabularPartAtSever(TabularPartName, CountOfCopied)
	
	TabularPartCopyServer.Copy(Object[TabularPartName], Items[TabularPartName].SelectedRows, CountOfCopied);
	
EndProcedure

&AtClient
Procedure InventoryPasteRows(Command)
	PasteRowsTabularPart("Inventory");   
EndProcedure

&AtClient
Procedure PasteRowsTabularPart(TabularPartName)
	
	CountOfCopied = 0;
	CountOfPasted = 0;
	PasteRowsTabularPartAtServer(TabularPartName, CountOfCopied, CountOfPasted);
	ProcessPastedRows(TabularPartName, CountOfPasted);
	TabularPartCopyClient.NotifyUserPasteRows(CountOfCopied, CountOfPasted);
	
EndProcedure

&AtServer
Procedure PasteRowsTabularPartAtServer(TabularPartName, CountOfCopied, CountOfPasted)
	
	TabularPartCopyServer.Paste(Object, TabularPartName, Items, CountOfCopied, CountOfPasted);
	ProcessPastedRowsAtServer(TabularPartName, CountOfPasted);
	
EndProcedure

&AtClient
Procedure ProcessPastedRows(TabularPartName, CountOfPasted)
	
	If TabularPartName = "Inventory" Then
		
		Count = Object[TabularPartName].Count();
		
		For iterator = 1 To CountOfPasted Do
			
			Row = Object[TabularPartName][Count - iterator];
			CalculateAmountInTabularSectionLine(TabularPartName,Row);
			
		EndDo; 
		
	EndIf;
	           	
EndProcedure

&AtServer
Procedure ProcessPastedRowsAtServer(TabularPartName, CountOfPasted)
	
	Count = Object[TabularPartName].Count();
	
	For iterator = 1 To CountOfPasted Do
		
		Row = Object[TabularPartName][Count - iterator];
		
		StructData = New Structure;
		StructData.Insert("Company",        	  Object.Company);
		StructData.Insert("ProductsAndServices",  Row.ProductsAndServices);
		StructData.Insert("VATTaxation", 		  Object.VATTaxation);
		
		StructData = GetDataProductsAndServicesOnChange(StructData); 
		
		If TabularPartName = "Inventory" Then
			
			Row.VATRate = StructData.VATRate;
			
		ElsIf TabularPartName = "Expenses" Then
			
			Row.MeasurementUnit = MainDepartment;
			
		EndIf;
		
		If Not ValueIsFilled(Row.MeasurementUnit) Then
			Row.MeasurementUnit = StructData.MeasurementUnit;
		EndIf;
		
		
	EndDo;
	//
EndProcedure

&AtClient
Procedure ExpensesCopyRows(Command)
	CopyRowsTabularPart("Expenses"); 
EndProcedure

&AtClient
Procedure ExpensesPasteRows(Command)
	PasteRowsTabularPart("Expenses"); 
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

&AtClient
Procedure InventorySerialNumbersStartChoice(Item, ChoiceData, StandardProcessing)
		
	StandardProcessing = False;
	OpenSerialNumbersSelection();
	
EndProcedure

&AtClient
Procedure OpenSerialNumbersSelection()
		
	CurrentDataIdentifier = Items.Inventory.CurrentData.GetID();
	ParametersOfSerialNumbers = SerialNumberPickParameters(CurrentDataIdentifier);
	
	OpenForm("DataProcessor.SerialNumbersSelection.Form", ParametersOfSerialNumbers, ThisObject);

EndProcedure

&AtServer
Function GetSerialNumbersFromStorage(AddressInTemporaryStorage, RowKey)
	
	Modified = True;
	Return WorkWithSerialNumbers.GetSerialNumbersFromStorage(Object, AddressInTemporaryStorage, RowKey);
	
EndFunction

&AtServer
Function SerialNumberPickParameters(CurrentDataIdentifier)
	
	Return WorkWithSerialNumbers.SerialNumberPickParameters(Object, ThisObject.UUID, CurrentDataIdentifier, False);
	
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
Procedure CCDMode(Command)
	
	CommonUseClientServer.SetFormItemProperty(Items, "CCDMode", "Check", Not Items.CCDMode.Check);
	CommonUseClientServer.SetFormItemProperty(Items, "CCDModeContext", "Check", Not Items.CCDMode.Check);
	
	ChangeCCDOperationMode(Items.CCDMode.Check);

EndProcedure

#EndRegion

&AtClient
Procedure ChangeCCDOperationMode(EnableCCDMode)
	
	If Not CashValues.Property("AttributesToProcess") Then
		
		CashValues.Insert("AttributesToProcess", New Array);
		
	EndIf;
	
	If EnableCCDMode Then
		
		EnableCCDOperationsMode();
		
	Else
		
		DisableCCDOperationsMode();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure EnableCCDOperationsMode()
	
	UnchangeableAttributes = New Array;
	UnchangeableAttributes.Add("InventoryMark");
	UnchangeableAttributes.Add("InventoryLineNumber");
	UnchangeableAttributes.Add("InventoryProductsAndServices");
	UnchangeableAttributes.Add("InventoryCharacteristic");
	UnchangeableAttributes.Add("InventoryBatch");
	UnchangeableAttributes.Add("InventoryQuantity");
	UnchangeableAttributes.Add("InventoryMeasurementUnit");
	UnchangeableAttributes.Add("InventoryCountryOfOrigin");
	UnchangeableAttributes.Add("InventoryCCDNo");
	
	For Each FormItem In Items.Inventory.ChildItems Do
		
		If UnchangeableAttributes.Find(FormItem.Name) = Undefined
			And FormItem.Visible = True Then
			
			CommonUseClientServer.SetFormItemProperty(Items, FormItem.Name, "Visible", False);
			CashValues.AttributesToProcess.Add(FormItem.Name);
			
		EndIf;
		
	EndDo;
	
	CommonUseClientServer.SetFormItemProperty(Items, "InventoryMeasurementUnit", "Enabled", False);
	
EndProcedure

&AtClient
Procedure DisableCCDOperationsMode()
	
	For Each FormItemName In CashValues.AttributesToProcess Do
		
		CommonUseClientServer.SetFormItemProperty(Items, FormItemName, "Visible", True);
		
	EndDo;
	
	CommonUseClientServer.SetFormItemProperty(Items, "InventoryMeasurementUnit", "Enabled", True);
	
	CashValues.AttributesToProcess = New Array;
	
EndProcedure

&AtClient
Procedure CCDNumbersPickup(Command)
	
	ArrayCopy = CashValues.AttributesToProcess;
	
	CCDNumbersPickAtServer(True);
	
	If Not ArrayCopy.Count() = CashValues.AttributesToProcess.Count() Then
		
		CashValues.AttributesToProcess = ArrayCopy;
		
	EndIf;

EndProcedure

&AtClient
Procedure SelectCCDNumber(Command)
	
	NotifyDescription = New NotifyDescription("AfterCCDNumberChoice", ThisObject);
	
	OpenForm("Document.SupplierInvoice.Form.CCDNumberChoiceForm", , ThisForm, , , , NotifyDescription);
EndProcedure

&AtClient
Procedure AfterCCDNumberChoice(Result, AdditionalParameters) Export
	
	If Not TypeOf(Result) = Type("Structure") Then
		
		Return;
		
	EndIf;
	
	For Each InventoryTableRow In Object.Inventory Do
		
		If Result.IsReceiptFromOneCountry Then
			
			InventoryTableRow.CountryOfOrigin = Result.CountryOfOrigin;
			
		EndIf;
		
		If Not ValueIsFilled(InventoryTableRow.CountryOfOrigin) Then
			
			Continue;
			
		EndIf;
		
		InventoryTableRow.CCDNo = Result.CCDNo;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure CCDNumbersPickAtServer(IsContextCall)
	
	SelectionParameters = New Structure;
	SelectionParameters.Insert("TableInventory", Undefined);
	SelectionParameters.Insert("Company", Object.Company);
	
	NamesOfFields = New Array;
	NamesOfFields.Add("Amount");
	NamesOfFields.Add("VATAmount");
	NamesOfFields.Add("Total");
	SelectionParameters.Insert("NamesOfFields", NamesOfFields);
	
	If ValueIsFilled(Object.Counterparty) Then
		
		SelectionParameters.Insert("Counterparty", Object.Counterparty);
		
	EndIf;
	
	If Not IsContextCall Then
		
		SelectionParameters.Insert("CheckMark", True);
		
	EndIf;
	
	CargoCustomsDeclarationsServer.PrepareInventoryTableFromFormTable(SelectionParameters, Object.Inventory);
	CargoCustomsDeclarationsServer.PickCCDNumbersByPreviousPostuplenijam(SelectionParameters);
	CargoCustomsDeclarationsServer.MoveCCDNumbersToFormTable(Object.Inventory, SelectionParameters);
	
EndProcedure

&AtClient
Procedure InventoryChangeRows(Command)
	
	ShowHideEditPanel(NameTSInventory(), True);
	
EndProcedure

&AtServer
Procedure ShowHideEditPanel(TSName, ModifiesData = Undefined)
	
	Var MigrationState;
	GroupRowsChangeServer.ShowHideEditPanel(ThisObject, GroupRowsChangeItemsServer(TSName),
		MigrationState,
		ModifiesData);
	
	TableBackupManagement(TSName, MigrationState, ModifiesData);
	
EndProcedure

&AtServer
Procedure TableBackupManagement(TSName, MigrationState, ModifiesData)
	
	If TSName = NameTSInventory() Then
		AttributeTableBackupAddress = "InventoryTableBackupAddress";
	ElsIf TSName = TSNameExpenses() Then
		AttributeTableBackupAddress = "ExpensesTableBackupAddress";
	EndIf;
	
	GroupRowsChangeServer.BackupManagement(ThisObject, Object[TSName],
		ThisObject[AttributeTableBackupAddress], MigrationState, ModifiesData);
	
EndProcedure

&AtClient
Procedure InventoryCheckAll(Command)
	SetMark(NameTSInventory(), True);

EndProcedure

&AtServer
Procedure SetMark(TSName, Check)
	
	SetElements = GroupRowsChangeItemsServer(TSName);
	SetElements.ButtonUncheckAll.Visible = Not SetElements.ButtonUncheckAll.Visible;
	SetElements.ButtonCheckAll.Visible = Not SetElements.ButtonCheckAll.Visible;
	
	For Each Row In Object[SetElements.TSName] Do
		Row.Check = Check;
	EndDo;
	
EndProcedure

&AtServer
Function GroupRowsChangeItemsServer(TSName)
	
	If TSName = NameTSInventory() Then
		
		SetElements = New Structure();
		SetElements.Insert("TSName", NameTSInventory());
		SetElements.Insert("DocumentRef",          Object.Ref);
		SetElements.Insert("EditPanel",    Items.GroupInventoryRowsChange);
		SetElements.Insert("ChangeRowsButton",    Items.InventoryChangeRows);
		SetElements.Insert("ButtonCheckAll",  Items.InventoryCheckAll);
		SetElements.Insert("ButtonUncheckAll",       Items.InventoryUncheckAll);
		SetElements.Insert("ButtonExecuteAction", Items.InventoryExecuteAction);
		SetElements.Insert("ColumnMark",          Items.InventoryMark);
		SetElements.Insert("ColumnLineNumber",      Items.InventoryLineNumber);
		SetElements.Insert("Action",                ThisObject.InventoryRowsChangeAction);
		SetElements.Insert("ActionItem",         Items.InventoryRowsChangeAction);
		SetElements.Insert("Value",                ThisObject.InventoryRowsChangeValue);
		SetElements.Insert("ValueItem",         Items.InventoryRowsChangeValue);
		SetElements.Insert("ChangingObject",         InventoryRowsChangeChangingObjectItem);
		SetElements.Insert("ColumnChangingObject",  ?(ValueIsFilled(InventoryRowsChangeChangingObjectItem), 
		                                                     Items[InventoryRowsChangeChangingObjectItem], Undefined));
	ElsIf TSName = TSNameExpenses() Then
		
		SetElements = New Structure();
		SetElements.Insert("TSName", TSNameExpenses());
		SetElements.Insert("DocumentRef",          Object.Ref);
		SetElements.Insert("EditPanel",    Items.ExpensesGroupRowsChange);
		SetElements.Insert("ChangeRowsButton",    Items.ExpensesChangeRows);
		SetElements.Insert("ButtonCheckAll",  Items.ExpensesCheckAll);
		SetElements.Insert("ButtonUncheckAll",       Items.ExpensesUncheckAll);
		SetElements.Insert("ButtonExecuteAction", Items.ExpensesExecuteAction);
		SetElements.Insert("ColumnMark",          Items.ExpensesCheck);
		SetElements.Insert("ColumnLineNumber",      Items.ExpensesLineNumber);
		SetElements.Insert("Action",                ThisObject.ExpensesRowsChangeAction);
		SetElements.Insert("ActionItem",         Items.ExpensesRowsChangeAction);
		SetElements.Insert("Value",                ThisObject.ExpensesRowsChangeValue);
		SetElements.Insert("ValueItem",         Items.ExpensesRowsChangeValue);
		SetElements.Insert("ChangingObject",         ExpensesRowsChangeChangingObjectItem);
		SetElements.Insert("ColumnChangingObject",  ?(ValueIsFilled(ExpensesRowsChangeChangingObjectItem), 
		                                                     Items[ExpensesRowsChangeChangingObjectItem], Undefined));
	EndIf;
	
	Return SetElements;
	
EndFunction

&AtClient
Procedure InventoryRowsChangeActionOnChange(Item)
	
	DefineChangeObject(NameTSInventory());
	CustomiseEditPanelAppearance(NameTSInventory(), 2);

EndProcedure

&AtClient
Procedure DefineChangeObject(TSName)
	
	If TSName = NameTSInventory() Then
		
		If InventoryRowsChangeAction = PredefinedValue("Enum.BulkRowChangeActions.ChangePercentPrices") Then
			
			InventoryRowsChangeChangingObjectAttribute = "Price";
			InventoryRowsChangeChangingObjectItem = "InventoryPrice";
			
		ElsIf InventoryRowsChangeAction = PredefinedValue("Enum.BulkRowChangeActions.RoundPrices") Then
			
			InventoryRowsChangeChangingObjectAttribute = "Price";
			InventoryRowsChangeChangingObjectItem = "InventoryPrice";
			
		ElsIf InventoryRowsChangeAction = PredefinedValue("Enum.BulkRowChangeActions.RoundSums") Then
			
			InventoryRowsChangeChangingObjectAttribute = "Amount";
			InventoryRowsChangeChangingObjectItem = "InventoryAmount";
			
		ElsIf InventoryRowsChangeAction = PredefinedValue("Enum.BulkRowChangeActions.SetPrices") Then
			
			InventoryRowsChangeChangingObjectAttribute = "Price";
			InventoryRowsChangeChangingObjectItem = "InventoryPrice";
			
		ElsIf InventoryRowsChangeAction = PredefinedValue("Enum.BulkRowChangeActions.SetPricesByKind") Then
			
			InventoryRowsChangeChangingObjectAttribute = "Price";
			InventoryRowsChangeChangingObjectItem = "InventoryPrice";
			
		ElsIf InventoryRowsChangeAction = PredefinedValue("Enum.BulkRowChangeActions.DistributeAmountByQuantity") Then
			
			InventoryRowsChangeChangingObjectAttribute = "Amount";
			InventoryRowsChangeChangingObjectItem = "InventoryAmount";
			
		ElsIf InventoryRowsChangeAction = PredefinedValue("Enum.BulkRowChangeActions.DistributeAmountByAmounts") Then
			
			InventoryRowsChangeChangingObjectAttribute = "Amount";
			InventoryRowsChangeChangingObjectItem = "InventoryAmount";
			
		ElsIf InventoryRowsChangeAction = PredefinedValue("Enum.BulkRowChangeActions.SetVATRate") Then
			
			InventoryRowsChangeChangingObjectAttribute = "VATRate";
			InventoryRowsChangeChangingObjectItem = "InventoryVATRate";
			
		ElsIf InventoryRowsChangeAction = PredefinedValue("Enum.BulkRowChangeActions.SetPurchaseOrderCustomerOrder") Then
			
			InventoryRowsChangeChangingObjectAttribute = "DocOrder";
			InventoryRowsChangeChangingObjectItem = "InventoryOrder";
			
		ElsIf InventoryRowsChangeAction = PredefinedValue("Enum.BulkRowChangeActions.DistributeByQuantityInOrder") Then
			
			InventoryRowsChangeChangingObjectAttribute = "";
			InventoryRowsChangeChangingObjectItem = "";

		ElsIf InventoryRowsChangeAction = PredefinedValue("Enum.BulkRowChangeActions.SetWarehouse") Then
			
			InventoryRowsChangeChangingObjectAttribute = "StructuralUnit";
			InventoryRowsChangeChangingObjectItem = "InventoryStructuralUnit";
			
		ElsIf InventoryRowsChangeAction = PredefinedValue("Enum.BulkRowChangeActions.SetCell") Then
			
			InventoryRowsChangeChangingObjectAttribute = "Cell";
			InventoryRowsChangeChangingObjectItem = "InventoryCell";
			
		ElsIf InventoryRowsChangeAction = PredefinedValue("Enum.BulkRowChangeActions.DeleteRows")
			Or InventoryRowsChangeAction = PredefinedValue("Enum.BulkRowChangeActions.AddFromDocument") Then
			
			InventoryRowsChangeChangingObjectAttribute = "";
			InventoryRowsChangeChangingObjectItem = "";
		ElsIf InventoryRowsChangeAction = PredefinedValue("Enum.BulkRowChangeActions.CreateProductsAndServicesBatches") Then
			
			InventoryRowsChangeChangingObjectAttribute = "Batch";
			InventoryRowsChangeChangingObjectItem = "InventoryBatch";
			
		EndIf;
	
	ElsIf TSName = TSNameExpenses() Then
		
		If ExpensesRowsChangeAction = PredefinedValue("Enum.BulkRowChangeActions.ChangePercentPrices") Then
			
			ExpensesRowsChangeChangingObjectAttribute = "Price";
			ExpensesRowsChangeChangingObjectItem = "ExpencesPrice";
			
		ElsIf ExpensesRowsChangeAction = PredefinedValue("Enum.BulkRowChangeActions.RoundPrices") Then
			
			ExpensesRowsChangeChangingObjectAttribute = "Price";
			ExpensesRowsChangeChangingObjectItem = "ExpencesPrice";
			
		ElsIf ExpensesRowsChangeAction = PredefinedValue("Enum.BulkRowChangeActions.DistributeAmountByQuantity") Then
			
			ExpensesRowsChangeChangingObjectAttribute = "Amount";
			ExpensesRowsChangeChangingObjectItem = "AmountExpenses";
			
		ElsIf ExpensesRowsChangeAction = PredefinedValue("Enum.BulkRowChangeActions.DistributeAmountByAmounts") Then
			
			ExpensesRowsChangeChangingObjectAttribute = "Amount";
			ExpensesRowsChangeChangingObjectItem = "AmountExpenses";
			
		ElsIf ExpensesRowsChangeAction = PredefinedValue("Enum.BulkRowChangeActions.SetVATRate") Then
			
			ExpensesRowsChangeChangingObjectAttribute = "VATRate";
			ExpensesRowsChangeChangingObjectItem = "ExpencesVATRate";
			
		ElsIf ExpensesRowsChangeAction = PredefinedValue("Enum.BulkRowChangeActions.DeleteRows")
			Or ExpensesRowsChangeAction = PredefinedValue("Enum.BulkRowChangeActions.AddFromDocument") Then
			
			ExpensesRowsChangeChangingObjectAttribute = "";
			ExpensesRowsChangeChangingObjectItem = "";
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CustomiseEditPanelAppearance(TSName, State, SaveChanges = Undefined)
	
	If TSName = NameTSInventory() Then
		AttributeValue = "InventoryRowsChangeValue";
	ElsIf TSName = TSNameExpenses() Then
		AttributeValue = "ExpensesRowsChangeValue";
	EndIf;
	
	Result = GroupRowsChangeClient.CustomizeEditPanelAppearance(
		ThisObject,
		GroupRowsChangeItemsClient(TSName),
		State,
		ThisObject[AttributeValue]
	);
	
	If Result.Property("SetChoiceParameterLinks") And Result.SetChoiceParameterLinks Then
		SetChoiceParameterAssociationsForValue(TSName);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetChoiceParameterAssociationsForValue(TSName)
	
	GroupRowsChangeServer.SetChoiceParameterLinks(
		GroupRowsChangeItemsServer(TSName)
	);
	
EndProcedure

&AtClient
Procedure InventoryRowsChangeValueOnChange(Item)
	
	CustomiseEditPanelAppearance(NameTSInventory(), 3);
	
EndProcedure




#Region Constants

&AtClientAtServerNoContext
Function NameTSInventory()
	
	Return "Inventory"; // Не локализуется
	
EndFunction

&AtClientAtServerNoContext
Function TSNameExpenses()
	
	Return "Expenses"; // Не локализуется
	
EndFunction

&AtClientAtServerNoContext
Function FieldPresentationSeveralPricesInOrder()
	
	Return NStr("en='<some>';ru='<несколько>';vi='<nhiều>'");
	
EndFunction

&AtClient
Procedure ExpensesCancelChanges(Command)
	
	ShowHideEditPanel(TSNameExpenses());
	// Insert handler content.
EndProcedure

&AtClient
Procedure ExpensesChangeRows(Command)
	
	ShowHideEditPanel(TSNameExpenses(), True);
	
EndProcedure

&AtClient
Procedure ExpensesCheckAll(Command)
	
	SetMark(TSNameExpenses(), True);
	
EndProcedure

&AtClient
Procedure ExpensesExecuteAction(Command)
	
	ProcessTable(TSNameExpenses());
	CustomiseEditPanelAppearance(TSNameExpenses(), 4);

EndProcedure

#EndRegion

&AtClient
Procedure ProcessTable(TSName)
	
	If TSName = NameTSInventory() Then
		ExecutedAction = InventoryRowsChangeAction;
	ElsIf TSName = TSNameExpenses() Then
		ExecutedAction = ExpensesRowsChangeAction;
	EndIf;
	
	// Наборы
	If IsReturnFromCustomer(Object.OperationKind) And TSName = NameTSInventory()
			And ExecutedAction = PredefinedValue("Enum.BulkRowChangeActions.DeleteRows") Then
		
		RowsToChange = Object[TSName].FindRows(New Structure("Check", True));
		If RowsToChange.Count() = Object[TSName].Count() Then
		// Если выделены все строки - проверки удаления наборов не выполняются
			Object.AddedSets.Clear();
		Else
			For Each Row In RowsToChange Do
				If ValueIsFilled(Row.ProductsAndServicesOfSet) Then
					Message = New UserMessage;
					Message.Text = NStr("en='Действие недоступно для наборов.';ru='Действие недоступно для наборов.';vi='Thao tác không khả dụng đối với bộ sản phẩm.'");
					Message.Field = "Object." + TSName;
					Message.Message();
					Return;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	// Конец Наборы
	
	//Партии
	If ExecutedAction = PredefinedValue("Enum.BulkRowChangeActions.CreateProductsAndServicesBatches")
		Then
		
		RowsToChange = Object[TSName].FindRows(New Structure("Check", True));
		
		If Not RowsToChange.Count()
			Then
			Return
		EndIf;
		
		NotifyDescriptionQuestion = New NotifyDescription("CreateProductsAndServicesBatchesAtClient",
		                                                   ThisObject, Undefined);
		QuestionText = NStr("en='Установить владельцем партии: %Supplier%? ';ru='Установить владельцем партии: %Supplier%? ';vi='Đặt bởi chủ sở hữu lô hàng: %Supplier%?'");
		QuestionText = StrReplace(QuestionText, "%Supplier%", String(Object.Counterparty));
		
		ShowQueryBox(NotifyDescriptionQuestion, QuestionText, QuestionDialogMode.YesNo);
		
		Return;
		
	EndIf;
	//Конец Партии
	
	If ExecutedAction = PredefinedValue(
		"Enum.BulkRowChangeActions.SelectCCDNumber") Then
			
		NotifyDescription = New NotifyDescription("AfterSelectCCDNumberForSpecifiedRows", ThisObject);
		
		OpenForm("Document.SupplierInvoice.Form.CCDNumberChoiceForm", , ThisForm, , , , NotifyDescription);
		Return;
		
	EndIf;
	
	If ExecutedAction = PredefinedValue(
		"Enum.BulkRowChangeActions.DistributeByQuantityInOrder") Then
			
		RowsCountBeforeDistribution = Object.Inventory.Count();
		BeforeDistributionByQuantityInOrder();
		
	EndIf;
	
	ProcessTableAtServer(TSName);
	
	RowsToChange = Object[TSName].FindRows(New Structure("Check", True));
	For Each Row In RowsToChange Do
		
		If ExecutedAction = PredefinedValue("Enum.BulkRowChangeActions.ChangePercentPrices")
			Or ExecutedAction = PredefinedValue("Enum.BulkRowChangeActions.RoundPrices")
			Or InventoryRowsChangeAction = PredefinedValue("Enum.BulkRowChangeActions.SetDiscountMarkupPercent")
			Or ExecutedAction = PredefinedValue("Enum.BulkRowChangeActions.SetPricesByKind")
			Or ExecutedAction = PredefinedValue("Enum.BulkRowChangeActions.SetPrices")
			Or ExecutedAction = PredefinedValue("Enum.BulkRowChangeActions.DistributeByQuantityInOrder") Then
			
			CalculateAmountInTabularSectionLine(TSName, Row);
			
		ElsIf ExecutedAction = PredefinedValue("Enum.BulkRowChangeActions.AddFromDocument")
			And TSName = NameTSInventory() Then
			
			CalculateAmountInTabularSectionLine(TSName, Row);
			
		ElsIf ExecutedAction = PredefinedValue("Enum.BulkRowChangeActions.SetDiscountAmount") Then
			
			SmallBusinessClient.CalculateVATAmountAndTotal(Row, New Structure("AmountIncludesVAT",Object.AmountIncludesVAT));	
			
			//Ручные скидки
			CalculateAmountAndDiscountPercentExpensesInventory(Object, DiscountAmount, DiscountPercent);
			//Конец Ручные скидки
			
		ElsIf ExecutedAction = PredefinedValue("Enum.BulkRowChangeActions.RoundSums") Then
			
			If Row.Quantity <> 0 Then
				Row.Price = Row.Amount / Row.Quantity;
			EndIf;
			
			CalculateAmountInTabularSectionLine(TSName, Row);
			
			//Ручная скидка - заполнение полей ввода на форме
			CalculateAmountAndDiscountPercentExpensesInventory(Object, DiscountAmount, DiscountPercent);
			//Конец Ручная скидка
			
		ElsIf ExecutedAction = PredefinedValue("Enum.BulkRowChangeActions.SetVATRate") Then
			
			SmallBusinessClient.CalculateVATAmountAndTotal(Row, New Structure("AmountIncludesVAT",Object.AmountIncludesVAT));	
			RefreshFormFooter();
			
		ElsIf ExecutedAction = PredefinedValue("Enum.BulkRowChangeActions.DistributeAmountByQuantity")
			Or ExecutedAction = PredefinedValue("Enum.BulkRowChangeActions.DistributeAmountByAmounts") Then
			
			If Row.Quantity <> 0 Then
				Row.Price = Row.Amount / Row.Quantity;
			EndIf;
			
			SmallBusinessClient.CalculateVATAmountAndTotal(Row, New Structure("AmountIncludesVAT",Object.AmountIncludesVAT));	
			RefreshFormFooter();
			
		EndIf;
		
	EndDo;
	
	If ExecutedAction = PredefinedValue(
			"Enum.BulkRowChangeActions.DistributeByQuantityInOrder") Then
		AfterDistributionByQuantityInOrder(RowsCountBeforeDistribution);
	EndIf;
	
EndProcedure



&AtClient
Procedure InventoryExecuteAction(Command)
	
	ProcessTable(NameTSInventory());
	CustomiseEditPanelAppearance(NameTSInventory(), 4);

EndProcedure

&AtClientAtServerNoContext
Procedure CalculateAmountAndDiscountPercentExpensesInventory(Object, DiscountAmount, DiscountPercent)
	
	TotalAmountWithoutDiscounts = 0;
	For Each Str In Object.Expenses Do
		TotalAmountWithoutDiscounts = TotalAmountWithoutDiscounts + Str.Price * Str.Quantity;
	EndDo;
	For Each Str In Object.Inventory Do
		TotalAmountWithoutDiscounts = TotalAmountWithoutDiscounts + Str.Price * Str.Quantity;
	EndDo;
	
	DiscountAmount = Object.Expenses.Total("AmountDiscountsMarkups") + Object.Inventory.Total("AmountDiscountsMarkups");
	DiscountPercent = ?(TotalAmountWithoutDiscounts=0, 0, DiscountAmount / TotalAmountWithoutDiscounts * 100);
	
EndProcedure

&AtClientAtServerNoContext
Function IsReturnFromCustomer(OperationKind)
	
	Return OperationKind = PredefinedValue("Enum.OperationKindsSupplierInvoice.ReturnFromCustomer");
	
EndFunction

&AtClient
Procedure BeforeDistributionByQuantityInOrder()
	
	SetPurchaseOrderPosition(
		PredefinedValue("Enum.AttributePositionOnForm.InTabularSection"));
	
	//If Not Object.CheckDifferencesWithOrder Then
	//	Object.CheckDifferencesWithOrder = True;
	//	CheckVarianceWithOrderOnChangeAtServer();
	//EndIf;
	
	SetVisibleFromUserSettings();
	
EndProcedure

&AtClient
Procedure AfterDistributionByQuantityInOrder(Val RowsCountBeforeDistribution)
	If RowsCountBeforeDistribution <> Object.Inventory.Count() Then
		ShowUserNotification(NStr(
			"ru = 'Заказ перемещен в табличную часть. Количество распределено по заказам.;
			|en = 'The order has been moved to the tabular section. The quantity is distributed according to orders.'"));
	Else
		ShowUserNotification(NStr("en='The order has been moved to the tabular section. No allocation required.';ru='Заказ перемещен в табличную часть. Распределение по заказам не требуется.';vi='Đơn hàng đã được chuyển sang phần bảng. Không cần phân bổ theo đơn hàng.'"));
	EndIf;
EndProcedure

//&AtServer
//Procedure CheckVarianceWithOrderOnChangeAtServer()
//	
//	//CheckDifferencesWithOrder = Object.CheckDifferencesWithOrder;
//	UpdateDifferences();
//	FillActionsList(NameTSInventory());
//	
//EndProcedure

&AtClient
Procedure SetPurchaseOrderPosition(PurchaseOrderPosition)
	
	If Object.PurchaseOrderPosition = PurchaseOrderPosition Then
		Return;
	EndIf;
	
	Object.PurchaseOrderPosition = PurchaseOrderPosition;
	If Object.PurchaseOrderPosition <> PredefinedValue(
		"Enum.AttributePositionOnForm.InTabularSection") Then
		If Object.Inventory.Count() > 0 Then
			Object.Order = ObjectsFillingCMClient.ValueForHeader(Object.Inventory, "Order");
		ElsIf Object.Expenses.Count() > 0 Then
			Object.Order = ObjectsFillingCMClient.ValueForHeader(Object.Expenses, "Order");
		Else
			Object.Order = Undefined;
		EndIf;
	EndIf;
	For Each TabularSectionRow In Object.Inventory Do
		TabularSectionRow.Order = Object.Order;
	EndDo;
	For Each TabularSectionRow In Object.Expenses Do
		TabularSectionRow.Order = Object.Order;
	EndDo;
	Order = Object.Order;
	
EndProcedure

&AtServer
Procedure ProcessTableAtServer(TSName)
	
	If TSName = NameTSInventory() Then
		
		GroupRowsChangeServer.ProcessTable(
			ThisObject,
			Object.Inventory,
			InventoryRowsChangeAction,
			InventoryRowsChangeChangingObjectAttribute,
			InventoryRowsChangeValue,
			"InventoryProductsAndServices"
		);
		
		If InventoryRowsChangeAction = PredefinedValue("Enum.BulkRowChangeActions.AddFromDocument") Then
			
			RowsToChange = Object.Inventory.FindRows(New Structure("Check", True));
			For Each Row In RowsToChange Do
				
				StructureData = New Structure;
				StructureData.Insert("OperationKind", Object.OperationKind);
				StructureData.Insert("Company", Object.Company);
				StructureData.Insert("ProductsAndServices", Row.ProductsAndServices);
				StructureData.Insert("CHARACTERISTIC", Row.CHARACTERISTIC);
				StructureData.Insert("VATTaxation", Object.VATTaxation);
				StructureData.Insert("Counterparty", Object.Counterparty);
				StructureData.Insert("ProcessingDate", Object.Date);
				
				If ValueIsFilled(Object.CounterpartyPriceKind) Then
					
					StructureData.Insert("ProcessingDate", Object.Date);
					StructureData.Insert("DocumentCurrency", Object.DocumentCurrency);
					StructureData.Insert("AmountIncludesVAT", Object.AmountIncludesVAT);
					StructureData.Insert("CHARACTERISTIC", Row.CHARACTERISTIC);
					StructureData.Insert("CounterpartyPriceKind", Object.CounterpartyPriceKind);
					StructureData.Insert("Factor", 1);
					
				EndIf;
				
				StructureData = GetDataProductsAndServicesOnChange(StructureData);
				
				Row.MeasurementUnit = StructureData.MeasurementUnit;
				If Not ValueIsFilled(Row.Quantity) Then
					Row.Quantity = 1;
				EndIf;
				Row.Price = StructureData.Price;
				Row.VATRate = StructureData.VATRate;
				Row.Content = "";
				
			EndDo;
			
		EndIf;
		
		If InventoryRowsChangeAction =Enums.BulkRowChangeActions.AddFromDocument
			Or InventoryRowsChangeAction = Enums.BulkRowChangeActions.SetWarehouse Then
			
			UpdateCellAvailability();
			FillCellsAvailableAttributes(ThisObject);
			
		EndIf; 
		
		If InventoryRowsChangeAction = Enums.BulkRowChangeActions.PickCCDNumbers Then
			
			CCDNumbersPickAtServer(False);
			
		EndIf;
		
		If InventoryRowsChangeAction = Enums.BulkRowChangeActions.ClearCCDAndCountryOfOriginNumbers Then
			
			CargoCustomsDeclarationsServer.ClearCCDAndCountryOfOriginNumbers(Object.Inventory);
			
		EndIf;
		
		//If InventoryRowsChangeAction = Enums.BulkRowChangeActions.DistributeByQuantityInOrder Then
		//	UpdateDifferences();
		//EndIf;
		
	ElsIf TSName = TSNameExpenses() Then
		
		GroupRowsChangeServer.ProcessTable(
			ThisObject,
			Object.Expenses,
			ExpensesRowsChangeAction,
			InventoryRowsChangeChangingObjectAttribute,
			ExpensesRowsChangeValue,
			"ExpensesProductsAndServices"
		);
		
		If InventoryRowsChangeAction = PredefinedValue("Enum.BulkRowChangeActions.AddFromDocument") Then
		
			RowsToChange = Object.Expenses.FindRows(New Structure("Check", True));
			For Each Row In RowsToChange Do
				
				StructureData = New Structure();
				StructureData.Insert("Company", Object.Company);
				StructureData.Insert("ProductsAndServices", Row.ProductsAndServices);
				StructureData.Insert("CHARACTERISTIC", "");
				StructureData.Insert("VATTaxation", Object.VATTaxation);
				StructureData.Insert("Counterparty", Object.Counterparty);
				StructureData.Insert("ProcessingDate", Object.Date);
				
				StructureData = GetDataProductsAndServicesOnChange(StructureData);
				
				Row.MeasurementUnit = StructureData.MeasurementUnit;
				If Not ValueIsFilled(Row.Quantity) Then
					Row.Quantity = 1;
				EndIf;
				Row.Price = 0;
				Row.Amount = 0;
				Row.VATRate = StructureData.VATRate;
				Row.VATAmount = 0;
				Row.Total = 0;
				Row.Content = "";
				
				If StructureData.ClearOrderAndDivision Then
					Row.StructuralUnit = Undefined;
					Row.DocOrder = Undefined;
				ElsIf Not ValueIsFilled(Row.StructuralUnit) Then
					Row.StructuralUnit = MainDepartment;
				EndIf;
				
				If StructureData.ClearBusinessActivity Then
					Row.BusinessActivity = Undefined;
				Else
					Row.BusinessActivity = StructureData.BusinessActivity;
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	ProductsAndServicesInDocumentsServer.FillCharacteristicsUsageFlags(Object);
	
EndProcedure

&AtClient
Function GroupRowsChangeItemsClient(TSName)
	
	If TSName = NameTSInventory() Then
		
		SetElements = New Structure();
		SetElements.Insert("TSName", NameTSInventory());
		SetElements.Insert("DocumentRef",          Object.Ref);
		SetElements.Insert("EditPanel",    Items.GroupInventoryRowsChange);
		SetElements.Insert("ButtonCheckAll",  Items.InventoryCheckAll);
		SetElements.Insert("ButtonUncheckAll",       Items.InventoryUncheckAll);
		SetElements.Insert("ButtonExecuteAction", Items.InventoryExecuteAction);
		SetElements.Insert("ColumnMark",          Items.InventoryMark);
		SetElements.Insert("ColumnLineNumber",      Items.InventoryLineNumber);
		SetElements.Insert("Action",                ThisObject.InventoryRowsChangeAction);
		SetElements.Insert("ActionItem",         Items.InventoryRowsChangeAction);
		SetElements.Insert("Value",                ThisObject.InventoryRowsChangeValue);
		SetElements.Insert("ValueItem",         Items.InventoryRowsChangeValue);
		SetElements.Insert("ChangingObject",         InventoryRowsChangeChangingObjectItem);
		SetElements.Insert("ColumnChangingObject",  ?(ValueIsFilled(InventoryRowsChangeChangingObjectItem), 
		                                                     Items[InventoryRowsChangeChangingObjectItem], Undefined));
	ElsIf TSName = TSNameExpenses() Then
		
		SetElements = New Structure();
		SetElements.Insert("TSName", TSNameExpenses());
		SetElements.Insert("DocumentRef",          Object.Ref);
		SetElements.Insert("EditPanel",    Items.ExpensesGroupRowsChange);
		SetElements.Insert("ButtonCheckAll",  Items.ExpensesCheckAll);
		SetElements.Insert("ButtonUncheckAll",       Items.ExpensesUncheckAll);
		SetElements.Insert("ButtonExecuteAction", Items.ExpensesExecuteAction);
		SetElements.Insert("ColumnMark",          Items.ExpensesCheck);
		SetElements.Insert("ColumnLineNumber",      Items.ExpensesLineNumber);
		SetElements.Insert("Action",                ThisObject.ExpensesRowsChangeAction);
		SetElements.Insert("ActionItem",         Items.ExpensesRowsChangeAction);
		SetElements.Insert("Value",                ThisObject.ExpensesRowsChangeValue);
		SetElements.Insert("ValueItem",         Items.ExpensesRowsChangeValue);
		SetElements.Insert("ChangingObject",         ExpensesRowsChangeChangingObjectItem);
		SetElements.Insert("ColumnChangingObject",  ?(ValueIsFilled(ExpensesRowsChangeChangingObjectItem), 
		                                                     Items[ExpensesRowsChangeChangingObjectItem], Undefined));
	EndIf;
	
	Return SetElements;
	
EndFunction

&AtClientAtServerNoContext
Procedure FillCellsAvailableAttributes(Form)

	Object = Form.Object;
	CashValues = Form.CashValues;
	If Not CashValues.AccountingByCells Then
		Return;
	EndIf;
	If Object.WarehousePosition<>PredefinedValue("Enum.AttributePositionOnForm.InTabularSection") Then
		Return;
	EndIf; 
	 
	For Each TabularSectionRow In Object.Inventory Do
		Result = CashValues.CellAvailability.Get(TabularSectionRow.StructuralUnit);
		If Result=Undefined Then
			Result = False;
		EndIf; 
		TabularSectionRow.CellAvailable = Result And ValueIsFilled(TabularSectionRow.StructuralUnit);
	EndDo; 
	
EndProcedure 

&AtServer
Procedure UpdateCellAvailability()
	
	If Not CashValues.AccountingByCells Then
		Return;
	EndIf; 	
	
	If Not CashValues.Property("CellAvailability") Then
		CashValues.Insert("CellAvailability", New FixedMap(New Map));
	EndIf; 
	
	StructuralUnitsArray = New Array;
	If Object.WarehousePosition=Enums.AttributePositionOnForm.InTabularSection Then
		For Each TabularSectionRow In Object.Inventory Do
			StructuralUnitsArray.Add(TabularSectionRow.StructuralUnit);
		EndDo; 
	Else
		StructuralUnitsArray.Add(Object.StructuralUnit);
	EndIf;
	StructuralUnitsArray = CommonUseClientServer.CollapseArray(StructuralUnitsArray);
	SupplementCellAvailability(StructuralUnitsArray, CashValues.CellAvailability);
	
EndProcedure

&AtServerNoContext
Procedure SupplementCellAvailability(StructuralUnits, StructuralUnitsMap)
	
	Query = New Query;
	Query.SetParameter("StructuralUnits", StructuralUnits);
	Query.Text =
	"SELECT
	|	StructuralUnits.Ref AS Ref,
	|	StructuralUnits.OrderWarehouse AS OrderWarehouse,
	|	StructuralUnits.StructuralUnitType AS StructuralUnitType
	|FROM
	|	Catalog.StructuralUnits AS StructuralUnits
	|WHERE
	|	StructuralUnits.Ref IN(&StructuralUnits)";
	SELECTION = Query.Execute().Select();
	Map = New Map(StructuralUnitsMap);
	While SELECTION.Next() Do
		Map.Insert(SELECTION.Ref, Not SELECTION.OrderWarehouse And SELECTION.StructuralUnitType=Enums.StructuralUnitsTypes.Warehouse);	
	EndDo; 
	StructuralUnitsMap = New FixedMap(Map);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// GroupRowsChange
	If Items.GroupInventoryRowsChange.Visible Then
		SetMark(NameTSInventory(), True);
	EndIf;
	If Items.ExpensesGroupRowsChange.Visible Then
		SetMark(TSNameExpenses(), True);
	EndIf;
	//END GroupRowsChange

EndProcedure

&AtServer
Procedure FillActionsList(TSName)
	
	AllowedEditDocumentPrices = SmallBusinessAccessManagementReUse.AllowedEditDocumentPrices();
	
	If TSName = NameTSInventory() Then
		
		Actions = New Array;
		If AllowedEditDocumentPrices Then
			Actions.Add(Enums.BulkRowChangeActions.ChangePercentPrices);
		EndIf;
		Actions.Add(Enums.BulkRowChangeActions.RoundPrices);
		Actions.Add(Enums.BulkRowChangeActions.RoundSums);
		Actions.Add(Enums.BulkRowChangeActions.SetPricesByKind);
		If AllowedEditDocumentPrices Then
			Actions.Add(Enums.BulkRowChangeActions.SetPrices);
			Actions.Add(Enums.BulkRowChangeActions.DistributeAmountByQuantity);
			Actions.Add(Enums.BulkRowChangeActions.DistributeAmountByAmounts);
		EndIf;
		Actions.Add(Enums.BulkRowChangeActions.SetVATRate);
		If Not OrderInHeader Then
			Actions.Add(Enums.BulkRowChangeActions.SetPurchaseOrderCustomerOrder);
		EndIf;
		Actions.Add(Enums.BulkRowChangeActions.DistributeByQuantityInOrder);
		If Not WarehouseInHeader Then
			Actions.Add(Enums.BulkRowChangeActions.SetWarehouse);
			If GetFunctionalOption("AccountingByCells") Then
				Actions.Add(Enums.BulkRowChangeActions.SetCell);
			EndIf;
		EndIf;
		Actions.Add(Enums.BulkRowChangeActions.AddFromDocument);
		Actions.Add(Enums.BulkRowChangeActions.DeleteRows);
		
		If IsSupplierReceipt(Object.OperationKind) Then
			
			CargoCustomsDeclarationsServer.FillActionsList(Actions, False, TSName);
			
		EndIf;
		
		Actions.Add(Enums.BulkRowChangeActions.CreateProductsAndServicesBatches);
		
		If Object.OperationKind = Enums.OperationKindsSupplierInvoice.ReceiptFromVendor
			Or Object.OperationKind = Enums.OperationKindsSupplierInvoice.ReceptionForCommission Then
			
			Actions.Add(Enums.BulkRowChangeActions.SelectCCDNumber);
			
		EndIf;
		
		Items.InventoryRowsChangeAction.ChoiceList.Clear();
		For Each Action In Actions Do
			ActionDetails = GroupRowsChangeServer.ActionPresentation(Action);
			Items.InventoryRowsChangeAction.ChoiceList.Add(Action, ActionDetails);
		EndDo;
		
		If InventoryRowsChangeAction = Enums.BulkRowChangeActions.SetPurchaseOrderCustomerOrder
			And Actions.Find(InventoryRowsChangeAction) = Undefined Then
			
			InventoryRowsChangeAction = Undefined;
			GroupRowsChangeServer.SetSourceEditPanel(InventoryRowsChangeValue, GroupRowsChangeItemsServer(TSName));
		EndIf;
		
		If GetFunctionalOption("UseSerialNumbers") Then
			Actions.Add(Enums.BulkRowChangeActions.FillSerialNumbers);
		EndIf;
		
	ElsIf TSName = TSNameExpenses() Then
		
		Actions = New Array;
		If AllowedEditDocumentPrices Then
			Actions.Add(Enums.BulkRowChangeActions.ChangePercentPrices);
		EndIf;
		Actions.Add(Enums.BulkRowChangeActions.RoundPrices);
		If AllowedEditDocumentPrices Then
			Actions.Add(Enums.BulkRowChangeActions.DistributeAmountByQuantity);
			Actions.Add(Enums.BulkRowChangeActions.DistributeAmountByAmounts);
		EndIf;
		Actions.Add(Enums.BulkRowChangeActions.SetVATRate);
		Actions.Add(Enums.BulkRowChangeActions.AddFromDocument);
		Actions.Add(Enums.BulkRowChangeActions.DeleteRows);
		
		Items.ExpensesRowsChangeAction.ChoiceList.Clear();
		For Each Action In Actions Do
			ActionDetails = GroupRowsChangeServer.ActionPresentation(Action);
			Items.ExpensesRowsChangeAction.ChoiceList.Add(Action, ActionDetails);
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function IsSupplierReceipt(OperationKind)
	
	Return OperationKind = PredefinedValue("Enum.OperationKindsSupplierInvoice.ReceiptFromVendor");
	
EndFunction

&AtClient
Procedure SaveCurrentRowChangeAction()
	
	SavingSettings = "";
	
	If InventoryRowsChangeAction <> InventoryRowsChangeActionOnOpen Then
		SavingSettings = NameTSInventory();
	EndIf;
	
	If ExpensesRowsChangeAction <> ExpensesRowsChangeActionOnOpen Then
		If ValueIsFilled(SavingSettings) Then
			SavingSettings = SavingSettings + ",";
		EndIf;
		SavingSettings = SavingSettings + TSNameExpenses();
	EndIf;
	
	If Not ValueIsFilled(SavingSettings) Then
		Return;
	EndIf;
	
	SaveCurrentRowChangeActionServer(SavingSettings);
	
EndProcedure

&AtServer
Procedure SaveCurrentRowChangeActionServer(SavingSettings)
	
	TSNames = StringFunctionsClientServer.DecomposeStringIntoSubstringArray(SavingSettings);
	For Each TSName In TSNames Do
		GroupRowsChangeServer.SaveSettings(GroupRowsChangeItemsServer(TSName));
	EndDo;
	
EndProcedure

&AtClient
Procedure ExpensesRowsChangeActionOnChange(Item)
	
	DefineChangeObject(TSNameExpenses());
	CustomiseEditPanelAppearance(TSNameExpenses(), 2);
	
EndProcedure

