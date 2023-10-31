
#Region ProgramInterface

// Проверяет наличие реквизита у объекта по строковому имени реквизита
//
// Parameters:
//  AttributeName - String - имя реквизита
//  Object - DocumentObject - документ, для которого проверяется наличие реквизита
//         - ДокументТабличнаяЧастьСтрока - строка, для которой проверяется наличие реквизита
//
// Returns:
//  Boolean - возвращает Истина когда у объекта есть реквизит с указанным именем
//
Function IsObjectAttribute(Val AttributeName, Val Object) Export
	
	CheckAttribute = New Structure(AttributeName, Undefined);
	FillPropertyValues(CheckAttribute, Object);
	If CheckAttribute[AttributeName] <> Undefined Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Установить флаг у дочерних строк в дереве
//
// Parameters:
//  ItemList - FormDataTreeItemCollection - строки, в которых устанавливается флаг
//  NameOfFlag - String - имя устанавливаемого флага
//  ValueOfFlag - Boolean - значение устанавливаемого флага
//
Procedure SetFlagInSubordinate(ItemList, NameOfFlag, ValueOfFlag) Export
	
	For Each TreeRow In ItemList Do
		
		TreeRow[NameOfFlag] = ValueOfFlag;
		
		ChildRows = TreeRow.GetItems();
		If ChildRows.Count() > 0 Then
			SetFlagInSubordinate(ChildRows, NameOfFlag, ValueOfFlag);
		EndIf;
		
	EndDo;
	
EndProcedure

// Установить флаг у родителей
//
// Parameters:
//  CurrentData - FormDataTreeItem - подчиненная строка
//  NameOfFlag - String - имя устанавливаемого флага
//  ValueOfFlag - Boolean - значение устанавливаемого флага
//
Procedure SetFlagAtParents(CurrentData, NameOfFlag, ValueOfFlag) Export
	
	Parent = CurrentData.GetParent();
	If Parent <> Undefined Then
		Parent[NameOfFlag] = ValueOfFlag;
		SetFlagAtParents(Parent, NameOfFlag, ValueOfFlag);
	EndIf;
	
EndProcedure

// Процедура рассчитывает сумму НДС в строке табличной части.
Procedure CalculateVATAmount(Object, TabularSectionRow) Export
	
	VATRate = SmallBusinessReUse.GetVATRateValue(TabularSectionRow.VATRate);
	
	If IsObjectAttribute("AmountIncludesVAT", Object) Then
		AmountIncludesVAT = Object.AmountIncludesVAT;
	Else
		AmountIncludesVAT = True;
	EndIf;
	
	TabularSectionRow.VATAmount = ?(AmountIncludesVAT,
		TabularSectionRow.Amount - (TabularSectionRow.Amount) / ((VATRate + 100) / 100),
		TabularSectionRow.Amount * VATRate / 100);
	
EndProcedure

// Procedure calculates the amount in the row of tabular section.
Procedure CalculateAmountInTabularSectionLine(Object, TabularSectionRow, TabularSectionName = "Inventory") Export
	
	// Сумма.
	If TabularSectionName = "Works" Then
		TabularSectionRow.Amount = TabularSectionRow.Count * TabularSectionRow.Multiplicity * TabularSectionRow.Factor * TabularSectionRow.Price;
	Else
		TabularSectionRow.Amount = TabularSectionRow.Count * TabularSectionRow.Price;
	EndIf;
	
	// Скидки.
	If IsObjectAttribute("UseDiscounts", TabularSectionRow) And TabularSectionRow.UseDiscounts Then
		If TabularSectionRow.DiscountMarkupPercent = 100 Then
			TabularSectionRow.Amount = 0;
		ElsIf TabularSectionRow.DiscountMarkupPercent <> 0 And TabularSectionRow.Count <> 0 Then
			TabularSectionRow.Amount = TabularSectionRow.Amount * (1 - TabularSectionRow.DiscountMarkupPercent / 100);
		EndIf;
		
		TabularSectionRow.AutomaticDiscountsPercent = 0;
		TabularSectionRow.AutomaticDiscountAmount = 0;
	EndIf; 
	
	// Сумма НДС.
	If IsObjectAttribute("VATAmount", TabularSectionRow) Then
		CalculateVATAmount(Object, TabularSectionRow);
	EndIf;
	
	// Всего.
	If IsObjectAttribute("Total", TabularSectionRow) Then
		TabularSectionRow.Total = TabularSectionRow.Amount + ?(Object.AmountIncludesVAT, 0, TabularSectionRow.VATAmount);
	EndIf;
	
EndProcedure

//Обновляет итоги подобранных товаров в форме Корзина справочника Номенклатура
Procedure UpdateSelectedProductsTotals(Form) Export
	
	If Form.HasAccessToPrices Then
		Form.GoodsSelectedLabel = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='Ваша корзина: "
"%1 на сумму %2 %3';ru='Ваша корзина: "
"%1 на сумму %2 %3';vi='Giỏ hàng của bạn:"
" %1 cho số tiền %2% 3'"),
			Form.Basket.Total("Quantity"),
			Format(Form.Basket.Total("Amount"),"NFD=2; NZ=0"),
			?(ValueIsFilled(Form.CurrencyPresentation),Form.CurrencyPresentation,"")
			);
	Else		
		Form.GoodsSelectedLabel = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("ru = Ваша корзина:
			|'%1'"),
			Form.Basket.Total("Quantity")
			);
	EndIf;
	
EndProcedure

// Для использования в колонке Содержание. Добавляет период оказания услуг по договору к сформированному наименованию.
//
// Parameters:
//  ProductsAndServicesPresentation  - String
//  Date                       - Date
//  Periodicity              - EnumRef.BillingServiceContractPeriodicity
// 
// Returns:
//   - String
//
Function ProductsAndServicesContentWithPeriod(ProductsAndServicesPresentation, Date, Periodicity) Export
	
	ProductsAndServicesContent = "";
	
	If Not ValueIsFilled(ProductsAndServicesPresentation) Then
		Return ProductsAndServicesContent;
	EndIf;
	
	PeriodPresentation = "";
	DateFormat = "";
	
	If Periodicity = PredefinedValue("Enum.BillingServiceContractPeriodicity.Week") Then
		DateFormat = NStr("en='дд ММММ гггг ""г.""';ru='дд ММММ гггг ""г.""';vi='dd MMMM yyyy "".""'");
		DateFormat = StrTemplate("DF='%1'", DateFormat);
		PeriodPresentation = StrTemplate(
			"%1 — %2",
			Format(BegOfWeek(Date), DateFormat),
			Format(EndOfWeek(Date), DateFormat)
		);
		//ПредставлениеПериода();
	ElsIf Periodicity = PredefinedValue("Enum.BillingServiceContractPeriodicity.Month") Then
		DateFormat = NStr("en='MMMM yyyy ""г.""';ru='MMMM yyyy ""г.""';vi='MMMM yyyy "".""'");
	ElsIf Periodicity = PredefinedValue("Enum.BillingServiceContractPeriodicity.Quarter") Then
		DateFormat = NStr("en='к ""квартал"" yyyy ""г.""';ru='к ""квартал"" yyyy ""г.""';vi='thành ""quý"" yyyy "".""'");
	ElsIf Periodicity = PredefinedValue("Enum.BillingServiceContractPeriodicity.HalfYear") Then
		HalfYearNumber = ?(Month(Date) <= 6, 1, 2);
		DateFormat = StrTemplate(
			NStr("en='""%1 полугодие"" yyyy ""г.""';ru='""%1 полугодие"" yyyy ""г.""';vi='""%1 học kỳ"" yyyy ""y.""'"),
			HalfYearNumber);
	ElsIf Periodicity = PredefinedValue("Enum.BillingServiceContractPeriodicity.Year") Then
		DateFormat = NStr("en='yyyy ""г.""';ru='yyyy ""г.""';vi='yyyy "".""'");
	EndIf;
	
	If ValueIsFilled(DateFormat) And Not ValueIsFilled(PeriodPresentation) Then
		DateFormat = StrTemplate("DF='%1'", DateFormat);
		PeriodPresentation = Format(Date, DateFormat);
	EndIf;
	
	If Not ValueIsFilled(PeriodPresentation) Then
		Return ProductsAndServicesContent;
	EndIf;
	
	Return StrTemplate(
		NStr("en='%1 за %2';ru='%1 за %2';vi='%1 cho %2'"),
		ProductsAndServicesPresentation,
		PeriodPresentation
	);
	
EndFunction

Procedure FillProductsAndServicesChoiceFormSettingsTable(Form, DocumentKind, ProductsAndServicesChoiceFormSettings, Current = True, TabularSectionName = "Inventory", SettingsStructure = Undefined) Export
	
	SettingsToSaveType = SettingsToSaveType(DocumentKind);
	FilterParameters = New Structure("TabularSectionName", TabularSectionName);
	SettingExists = ProductsAndServicesChoiceFormSettings.FindRows(FilterParameters);
	SettingExists = SettingExists.Count();
	
	#If Server Then
	If Not ProductsAndServicesChoiceFormSettings.Count() 
		Or Not SettingExists Then 
		ProductsAndServicesInDocumentsServer.FillProductsAndServicesChoiceFormSettingsTableServer(Form, DocumentKind, ProductsAndServicesChoiceFormSettings
																							, SettingsToSaveType, Current, TabularSectionName, SettingsStructure);
		Return;
	EndIf;
	#EndIf
	
	If SettingsStructure = Undefined Then Return EndIf;
	
	FilterParameters = New Structure("TabularSectionName, SettingName", TabularSectionName,);
	
	For Each SettingsStructureString In SettingsStructure Do;
		FilterParameters.SettingName = SettingsStructureString.Key;
		FormSettingsRows = ProductsAndServicesChoiceFormSettings.FindRows(FilterParameters);
		If Not FormSettingsRows.Count() Then Continue EndIf;
		FormSettingsRows[0].SettingValue = SettingsStructureString.Value;
	EndDo;
	
EndProcedure

Function SettingsToSaveType(DocumentKind) Export
	
	If DocumentKind = "CustomerInvoice"
		Or DocumentKind = "ReceiptCR"
		Or DocumentKind = "InventoryWriteOff"
		Or DocumentKind = "JobOrder"
		Or DocumentKind = "InventoryAssemblyWriteOff"
		Or DocumentKind = "AdditionalExpensesWriteOff"
		Or DocumentKind = "InventoryReconciliation"
		Or DocumentKind = "ReportToPrincipal"
		Or DocumentKind = "ProcessingReport"
		Or DocumentKind = "RetailReport"
		Or DocumentKind = "ReportProcessorWriteOff"
		Or DocumentKind = "InventoryTransfer"
		Or DocumentKind = "TransferBetweenCells"
		Or DocumentKind = "InventoryRegrading"
		Or DocumentKind = "GoodsExpense"
		Or DocumentKind = "InventoryReservation"
		Or DocumentKind = "AgentReport" Then
		Return 1;
	ElsIf DocumentKind = "CustomerOrder"
		Or DocumentKind = "PurchaseOrder"
		Or DocumentKind = "RetailRevaluation"
		Or DocumentKind = "CostAllocation"
		Or DocumentKind = "InvoiceForPayment"
		Or DocumentKind = "SupplierInvoiceForPayment"
		Or DocumentKind = "ProductionOrder" Then
		Return 2;
	ElsIf DocumentKind = "SupplierInvoice"
		Or DocumentKind = "InventoryReceipt"
		Or DocumentKind = "InventoryAssemblyReceivedPosting"
		Or DocumentKind = "ExpenseReport"
		Or DocumentKind = "AcceptanceCertificate"
		Or DocumentKind = "EnterOpeningBalance"
		Or DocumentKind = "AdditionalExpensesReceivedPosting"
		Or DocumentKind = "WorkOrder"
		Or DocumentKind = "PurchaseAdjustment"
		Or DocumentKind = "SalesAdjustment"
		Or DocumentKind = "GoodsReceipt"
		Or DocumentKind = "ReceiptCRReturn"
		Or DocumentKind = "RecyclerReportReceivedPosting" Then
		Return 3;
	Else
		Return 1;
	EndIf;
	
EndFunction

Procedure UpdateChoiceFormOpenParameters(Form, TabularSectionName = "Inventory", ProductsAndServicesDescriptionAddition = "") Export
	
	ProductsAndServicesChoiceFormSettings = TabularSectionSettings(Form.ProductsAndServicesChoiceFormSettings, TabularSectionName);
	
	ParameterArray = New Array;
	
	If Form.Items.Find(TabularSectionName + "ProductsAndServices" + ProductsAndServicesDescriptionAddition) = Undefined Then Return EndIf;
	
	For Each ArrayElement In Form.Items[TabularSectionName + "ProductsAndServices" + ProductsAndServicesDescriptionAddition].ChoiceParameters Do
		If ArrayElement.Name="Additionally.FormSettings" Then 
			Continue;
		EndIf;
		ParameterArray.Add(ArrayElement);
	EndDo;
	ParameterArray.Add(New ChoiceParameter("Additionally.FormSettings", ProductsAndServicesChoiceFormSettings));
	Form.Items[TabularSectionName + "ProductsAndServices"+ ProductsAndServicesDescriptionAddition].ChoiceParameters = New FixedArray(ParameterArray);
	
EndProcedure

Function TabularSectionSettings(SettingsTable, TabularSectionName)
	
	FilterParameters = New Structure("TabularSectionName", TabularSectionName);
	ReturnStructure = New Structure;
	
	FoundStrings = SettingsTable.FindRows(FilterParameters);
	
	For Each FoundString In FoundStrings Do
		ReturnStructure.Insert(FoundString.SettingName, FoundString.SettingValue);
	EndDo;
	
	Return ReturnStructure;
	
EndFunction

#EndRegion
