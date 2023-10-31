
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(cancel, StandardProcessing)
	
	//// СтандартныеПодсистемы.ПодключаемыеКоманды
	//ArrangementParameters = AttachableCommands.ArrangementParameters();
	//ArrangementParameters.CommandBar = Items.ImportantCommandsGroup;
	//AttachableCommands.OnCreateAtServer(ThisObject, ArrangementParameters);
	//// Конец СтандартныеПодсистемы.ПодключаемыеКоманды
	
	DocumentDate = Object.Date;
	If Not ValueIsFilled(DocumentDate) Then
		DocumentDate = CurrentDate();
	EndIf;
	
	SubsidiaryCompany = SmallBusinessServer.GetCompany(Object.Company);
	Counterparty = Object.Counterparty;
	Contract = Object.Contract;
	DocOrder = Object.PurchaseOrder;
	SettlementsCurrency = Object.Contract.SettlementsCurrency;
	NationalCurrency = Constants.NationalCurrency.Get();
	FilterNationalCurrency = New Structure("Currency", NationalCurrency);
	StructureByCurrency = InformationRegisters.CurrencyRates.GetLast(Object.Date, FilterNationalCurrency);
	RateNationalCurrency = StructureByCurrency.ExchangeRate;
	RepetitionNationalCurrency = StructureByCurrency.Multiplicity;
	DefaultVATAccountingAccount = ChartsOfAccounts.Managerial.Taxes;
	DefaultWarehouse = Catalogs.StructuralUnits.MainWarehouse;
	
	// Сформируем надпись цены и валюты.
	CurrencyTransactionsAccounting = Constants.FunctionalCurrencyTransactionsAccounting.Get();
	LabelStructure = New Structure;
	LabelStructure.Insert("DocumentCurrency", Object.DocumentCurrency);
	LabelStructure.Insert("SettlementsCurrency", SettlementsCurrency);
	LabelStructure.Insert("ExchangeRate", Object.ExchangeRate);
	LabelStructure.Insert("RateNationalCurrency", RateNationalCurrency);
	LabelStructure.Insert("AmountIncludesVAT", Object.AmountIncludesVAT);
	LabelStructure.Insert("CurrencyTransactionsAccounting", CurrencyTransactionsAccounting);
	LabelStructure.Insert("VATTaxation", Object.VATTaxation);
	PricesAndCurrency = GenerateLabelPricesAndCurrency(LabelStructure);
	
	CommonUseClientServer.SetFormItemProperty(Items, "BusinessActivity", "Visible",
		Object.CustomsPenalty <> 0);
	CommonUseClientServer.SetFormItemProperty(Items, "ExpensesGLAccount", "Visible",
		Object.CustomsPenalty <> 0);
	
	//ExchangeWithBookkeepingConfigured = SmallBusinessReUse.ExchangeWithBookkeepingConfigured();
	//CommonUseClientServer.SetFormItemProperty(Items, "InventoryBatchDocument", "Visible", ExchangeWithBookkeepingConfigured);
	
	// Установка видимости договора.
	SetContractVisible();
	
	// КопированиеСтрокТабличныхЧастей
	CopyTabularSectionServer.OnCreateAtServer(Items, "Inventory");
	
	// ГрупповоеИзменениеСтрок
	InitializeGroupRowsChange();
	// Конец ГрупповоеИзменениеСтрок
	
	TabularSectionsConditionalAppearance();
	
	// Характеристики
	ProductsAndServicesInDocumentsServer.UpdateTabularSectionConditionalAppearanceForCharacteristics(ThisForm);
	If Parameters.Key.IsEmpty() Then
		ProductsAndServicesInDocumentsServer.FillCharacteristicsUsageFlags(Object, True)
	EndIf;
	
	ProductsAndServicesChoiceStructure = New Structure("Characteristic, Batch");
	
EndProcedure // ПриСозданииНаСервере()

&AtClient
Procedure OnOpen(cancel)
	
	// СтандартныеПодсистемы.ПодключаемыеКоманды
	//AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// Конец СтандартныеПодсистемы.ПодключаемыеКоманды
	
	CheckTNFEAFilling();
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit Then
		// ГрупповоеИзменениеСтрок
		SaveCurrentRowChangeAction();
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_Counterparty" 
		And ValueIsFilled(Parameter)
		And Object.Counterparty = Parameter Then
		
		SetContractVisible();
		
	EndIf;
	
	// КопированиеСтрокТабличныхЧастей
	//If EventName = "ClipboardTabularSectionRowsCopying" Then
	//	CopyTabularSectionClient.NotificationProcessing(Items, "Inventory");
	//EndIf;
	
	// Обсуждения
	//ConversationsClient.NotificationProcessing(EventName, Parameter, Source, ThisForm, Object.Ref);
	// Конец Обсуждения
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// СтандартныеПодсистемы.УправлениеДоступом
	//If CommonUse.SubsystemExists("StandardSubsystems.AccessManagement") Then
	//	AccessControlModule = CommonUse.CommonModule("AccessManagement");
	//	AccessControlModule.OnReadAtServer(ThisObject, CurrentObject);
	//EndIf;
	// Конец СтандартныеПодсистемы.УправлениеДоступом
	
	ChangeProhibitionDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	// СтандартныеПодсистемы.ПодключаемыеКоманды
	//AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// Конец СтандартныеПодсистемы.ПодключаемыеКоманды
	
	ProductsAndServicesInDocumentsServer.FillCharacteristicsUsageFlags(Object);
	
	ProductsAndServicesChoiceStructure = New Structure("Characteristic, Batch");
	
EndProcedure

&AtClient
Procedure BeforeWrite(cancel, WriteParameters)
	
	If Object.CustomsPenalty <> 0
		And Not (ValueIsFilled(Object.BusinessActivity)
				And ValueIsFilled(Object.ExpensesGLAccount)) Then
				
		Items.Pages.CurrentPage = Items.PageMainInfo;
		ErrorText = NStr("en='Check the filling of the line of business Activity and cost account';ru='Проверьте заполнение направления деятельности и счета затрат';vi='Hãy kiểm tra việc điền mảng hoạt động và tài khoản chi phí'");
		CommonUseClientServer.MessageToUser(ErrorText, , , , cancel);
		
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(cancel, CurrentObject, WriteParameters)
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		
		MessageText = "";
		Catalogs.CounterpartyContracts.CheckContractToDocumentConditionAccordance(MessageText, Object.Contract, Object.Ref, Object.Company, Object.Counterparty, cancel);
		
		If MessageText <> "" Then
			
			Message = New UserMessage;
			Message.Text = ?(cancel, NStr("en='Document not posted! ';ru='Документ не проведен! ';vi='Chứng từ chưa được kết chuyển!'") + MessageText, MessageText);
			
			If cancel Then
				Message.DataPath = "Object";
				Message.Field = "Contract";
				Message.Message();
				Return;
			Else
				Message.Message();
			EndIf;
			
		EndIf;
		
	EndIf;
	
	CurrentObject.AdditionalProperties.Insert("Modified",Modified);
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(cancel, CurrentObject, WriteParameters)
	
	//ExchangeWithGoogle.IncreaseHintCounterValue(ThisForm);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	
	ProductsAndServicesInDocumentsServer.FillCharacteristicsUsageFlags(Object);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("NotificationAboutChangingDebt");
	
EndProcedure

#EndRegion

#Region HeaderFormItemsEventsHandlers

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonUseClient.ShowCommentEditingForm(Item.EditText, ThisObject,
		"Object.Comment");
		
EndProcedure

&AtClient
Procedure InventoryOnStartEdit(Item, NewRow, Copy)
	
	Item.CurrentData.Check = True;
	
	CurrentData = Items.Sections.CurrentData;
	
	If CurrentData = Undefined Then 
		SectionNumber = 1;
	Else
		SectionNumber = Items.Sections.CurrentData.LineNumber;
	EndIf;
		
	Item.CurrentData.SectionNumber = SectionNumber;
	
EndProcedure

&AtClient
Procedure InventoryProductsAndServicesOnChange(Item)
	
	SectionRow = Items.Sections.CurrentData;
	RowInventory = Items.Inventory.CurrentData;
	
	StructureData = New Structure;
	StructureData.Insert("Company", Object.Company);
	StructureData.Insert("ProductsAndServices", RowInventory.ProductsAndServices);
	StructureData.Insert("Characteristic", RowInventory.Characteristic);
	StructureData.Insert("Batch", RowInventory.Batch);

	StructureData.Insert("VATTaxation", Object.VATTaxation);
	StructureData.Insert("ProcessingDate", Object.Date);
	
	BatchStatus = New ValueList;
	BatchStatus.Add(PredefinedValue("Enum.BatchStatuses.OwnInventory"));
	
	StructureData.Insert("BatchStatus", BatchStatus);
	
	StructureData = GetDataProductsAndServicesOnChange(StructureData);
	
	RowInventory.Quantity			= 1;
	RowInventory.SectionNumber		= SectionRow.LineNumber;
	RowInventory.DutyAmount		= 0;
	RowInventory.VATAmount			= 0;
	RowInventory.CountryOfOrigin= StructureData.CountryOfOrigin;
	
	RowInventory.UseCharacteristics = StructureData.UseCharacteristics;
	RowInventory.CheckCharacteristicFilling = StructureData.CheckCharacteristicFilling;
	RowInventory.FillingCharacteristicChecked = True;
	
	If StructureData.UseCharacteristics Then
		If PickProductsAndServicesFromList And TypeOf(ProductsAndServicesChoiceStructure) = Type("Structure") Then
			RowInventory.Characteristic = ProductsAndServicesChoiceStructure.Characteristic;
			ProductsAndServicesChoiceStructure.Characteristic = Undefined;
		Else
			RowInventory.Characteristic = StructureData.Characteristic;
		EndIf;
	EndIf;
	
	//Партии
	RowInventory.UseBatches = StructureData.UseBatches;
	RowInventory.CheckBatchFilling = StructureData.CheckBatchFilling;
	
	If StructureData.UseBatches Then
		If PickProductsAndServicesFromList And TypeOf(ProductsAndServicesChoiceStructure) = Type("Structure") Then
			RowInventory.Batch = ProductsAndServicesChoiceStructure.Batch;
			ProductsAndServicesChoiceStructure.Batch = Undefined;
		Else
			RowInventory.Batch = StructureData.Batch;
		EndIf;
	EndIf;
	// Конец Партии
	
	PickProductsAndServicesFromList = False;
	
EndProcedure

&AtClient
Procedure InventoryProductsAndServicesChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	If TypeOf(SelectedValue) = Type("Structure") Then
		
		TabularSectionRow = Items.Inventory.CurrentData;
		
		FillPropertyValues(TabularSectionRow, SelectedValue);
		
		PickProductsAndServicesFromList = SelectedValue.Property("Cell");
		
		If Not TypeOf(ProductsAndServicesChoiceStructure) = Type("Structure") Then
			ProductsAndServicesChoiceStructure = New Structure("Characteristic, Batch");
		EndIf;
		
		ProductsAndServicesChoiceStructure.Characteristic = SelectedValue.Characteristic;
		ProductsAndServicesChoiceStructure.Batch = SelectedValue.Batch;
		
		SelectedValue = SelectedValue.ProductsAndServices;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	
	DateBeforeChange = DocumentDate;
	DocumentDate = Object.Date;
	If Object.Date <> DateBeforeChange Then
		
		StructureData = GetDataDateOnChange(Object.Ref, Object.Date, DateBeforeChange,
			SettlementsCurrency);
			
		If StructureData.DATEDIFF <> 0 Then
			Object.Number = "";
		EndIf;
		
		If ValueIsFilled(SettlementsCurrency) Then
			RecalculateExchangeRateMultiplicitySettlementCurrency(StructureData);
		EndIf;	
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CompanyOnChange(Item)
	
	Object.Number = "";
	StructureData = GetCompanyDataOnChange(Object.Company);
	SubsidiaryCompany = StructureData.SubsidiaryCompany;
	
	Object.Contract = GetContractByDefault(Object.Ref, Object.Counterparty, Object.Company);
	ProcessContractChange();
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyBeforeChange = Counterparty;
	CounterpartyDoSettlementsByOrdersBeforeChange = CounterpartyDoSettlementsByOrders;
	Counterparty = Object.Counterparty;
	
	If CounterpartyBeforeChange <> Object.Counterparty Then
		
		DataStructure = GetDataCounterpartyOnChange(Object.Date, Object.DocumentCurrency, Object.Counterparty,
			Object.Company);
		Object.Contract = DataStructure.Contract;
		
		DataStructure.Insert("CounterpartyBeforeChange", CounterpartyBeforeChange);
		DataStructure.Insert("CounterpartyDoSettlementsByOrdersBeforeChange", CounterpartyDoSettlementsByOrdersBeforeChange);
		
		ProcessContractChange(DataStructure);
		
	Else
		
		Object.Contract = Contract; // Восстанавливаем автоматически очищеный договор.
		Object.PurchaseOrder = DocOrder;
		
	EndIf;
	
	DocOrder = Object.PurchaseOrder;
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	ProcessContractChange();
	
EndProcedure

&AtClient
Procedure ContractStartChoice(Item, ChoiceData, StandardProcessing)
	
	FormParameters = GetChoiceFormParameters(Object.Ref, Object.Company, Object.Counterparty, Object.Contract);
	If FormParameters.ControlContractChoice Then
		
		StandardProcessing = False;
		OpenForm("Catalog.CounterpartyContracts.ChoiceForm", FormParameters, Item);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PurchaseOrderOnChange(Item)
	
	If Object.Prepayment.Count() > 0 And Object.PurchaseOrder <> DocOrder
			And CounterpartyDoSettlementsByOrders Then
		Mode = QuestionDialogMode.YesNo;
		NotifyDescription = New NotifyDescription("PurchaseOrderOnChangeCompletion", ThisObject);
		ShowQueryBox(NotifyDescription, NStr("en='Зачет предоплаты будет очищен, продолжить?';ru='Зачет предоплаты будет очищен, продолжить?';vi='Khoản khấu trừ trả trước sẽ bị xóa, tiếp tục?'"), Mode, 0);
		Return;
	EndIf;
	
	PurchaseOrderOnChangeFragment();
	
EndProcedure

&AtClient
Procedure PurchaseOrderOnChangeCompletion(Result, AdditionalParameters) Export
	
	Response = Result;
	If Response = DialogReturnCode.Yes Then
		Object.Prepayment.Clear();
	Else
		Object.PurchaseOrder = DocOrder;
		Return;
	EndIf;
	
	PurchaseOrderOnChangeFragment();

EndProcedure

&AtClient
Procedure PurchaseOrderOnChangeFragment()
	
	DocOrder = Object.PurchaseOrder;

EndProcedure

&AtClient
Procedure BalanceOfSettlementsURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	WorkWithDocumentFormClient.OpenReportSettlementsWithCounterparties(Object.Counterparty);
	
EndProcedure

&AtClient
Procedure ExpensesCustomsCostOnChange(Item)
	
	SectionNumber = Object.Sections.IndexOf(Items.Sections.CurrentData) + 1;
	OnChangeDutyRateCost(SectionNumber);
	
EndProcedure

&AtClient
Procedure SectionsDutyPercentOnChange(Item)
	
	DataCurrentRows = Items.Sections.CurrentData;
	If DataCurrentRows <> Undefined Then
		
		SectionNumber = Object.Sections.IndexOf(DataCurrentRows) + 1;
		OnChangeDutyRateCost(SectionNumber);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SectionsDutyAmountOnChange(Item)
	
	OnChangeVATRateDutyAmount(Items.Sections.CurrentData);
	
EndProcedure

&AtClient
Procedure SectionsVATRateOnChange(Item)
	
	OnChangeVATRateDutyAmount(Items.Sections.CurrentData);
	
EndProcedure

&AtClient
Procedure SectionsVATAmountOnChange(Item)
	
	CalculateDocumentAmount();
	DistributeVATAndDutyBySectionServer(Object.Sections.IndexOf(Items.Sections.CurrentData) + 1);
	
EndProcedure

&AtClient
Procedure SectionsOnEditEnd(Item, NewRow, CancelEdit)
	
	DataCurrentRows = Items.Sections.CurrentData;
	If Not DataCurrentRows = Undefined Then
		
		RowID = DataCurrentRows.GetID();
		FillSectionInfo(RowID);
		
		If Object.Sections.Count() > 1 Then
			
			ItemSelectionList = Items.InventoryRowsChangeAction.ChoiceList;
			If ItemSelectionList.FindByValue(PredefinedValue("Enum.BulkRowChangeActions.SetSourceLocation")) = Undefined Then
				
				ItemSelectionList.Add(PredefinedValue("Enum.BulkRowChangeActions.SetSourceLocation"), NStr("en='Перенести строки в другой раздел';ru='Перенести строки в другой раздел';vi='Chuyển các dòng sang phân hệ khác'"));
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SectionsOnStartEdit(Item, NewRow, Copy)
	
	If NewRow
		Or Not ValueIsFilled(Item.CurrentData.GlAccountVAT) Then
		
		Item.CurrentData.GlAccountVAT = DefaultVATAccountingAccount;
		
	EndIf;
	
	If Copy Then
		
		Item.CurrentData.CustomsCost = 0;
		Item.CurrentData.DutyAmount = 0;
		Item.CurrentData.VATAmount= 0;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SectionsBeforeDeleteRow(Item, cancel)
	
	SectionNumber = Object.Sections.IndexOf(Items.Sections.CurrentData) + 1;
	DeleteSectionProducts(SectionNumber);
	
EndProcedure

&AtClient
Procedure SectionsAfterDeleteRow(Item)
	
	If Object.Sections.Count() < 2 Then
		
		ItemSelectionList = Items.InventoryRowsChangeAction.ChoiceList;
		
		ListElement = ItemSelectionList.FindByValue(PredefinedValue("Enum.BulkRowChangeActions.SetSourceLocation"));
		If ListElement <> Undefined Then
			
			ItemSelectionList.Delete(ListElement);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure InventoryInvoiceCostOnChange(Item)
	
	RecalculateSectionTotals(Object.Sections.IndexOf(Items.Sections.CurrentData) + 1, "CustomsCost");
	
EndProcedure

&AtClient
Procedure InventoryDutyAmountOnChange(Item)
	
	RecalculateSectionTotals(Object.Sections.IndexOf(Items.Sections.CurrentData) + 1, "DutyAmount");
	
EndProcedure

&AtClient
Procedure InventoryVATAmountOnChange(Item)
	
	RecalculateSectionTotals(Object.Sections.IndexOf(Items.Sections.CurrentData) + 1, "VATAmount");
	
EndProcedure

&AtClient
Procedure InventoryBeforeAddRow(Item, cancel, Copy, Parent, Var_Group, Parameter)
	
	If Items.Sections.CurrentData = Undefined Then
		
		ErrorText = NStr("en='Необходимо выделить раздел, для которого добавляются запасы';ru='Необходимо выделить раздел, для которого добавляются запасы';vi='Cần chọn phân hệ thêm vật tư vào đó'");
		CommonUseClientServer.MessageToUser(ErrorText, , "Object.Sections", , cancel);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure InventoryAfterDeleteRow(Item)
	
	RecalculateSectionTotals(Object.Sections.IndexOf(Items.Sections.CurrentData) + 1);
	
EndProcedure

&AtClient
Procedure CustomsFeeOnChange(Item)
	
	CalculateDocumentAmount();
	
	DistributeFeeAmountByInventory();
	
EndProcedure

&AtClient
Procedure CustomsPenaltyOnChange(Item)
	
	AmountFilled = Object.CustomsPenalty <> 0;
	
	CommonUseClientServer.SetFormItemProperty(Items, "BusinessActivity", "Visible", AmountFilled);
	CommonUseClientServer.SetFormItemProperty(Items, "ExpensesGLAccount", "Visible", AmountFilled);
	
	If AmountFilled Then
		
		Object.BusinessActivity = Undefined;
		Object.ExpensesGLAccount = Undefined;
		
	EndIf;
	
	CalculateDocumentAmount();
	
EndProcedure

&AtClient
Procedure InventoryOnChange(Item)
	
	DistributeFeeAmountByInventory();
	
	SectionRow = Items.Sections.CurrentData;
	If SectionRow <> Undefined Then
		
		FillSectionInfo(SectionRow.GetID());
		
	EndIf;
	
	CheckTNFEAFilling();
	
	DataCurrentRows = Items.Inventory.CurrentData;
	If DataCurrentRows <> Undefined Then
		
		If Not ValueIsFilled(DataCurrentRows.StructuralUnit) Then
			
			DataCurrentRows.StructuralUnit = DefaultWarehouse;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#Region AttributesExchangeWithGoogle

&AtClient
Procedure Attachable_ChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	//ExchangeWithGoogleClient.Attachable_ChoiceProcessing(
	//ThisObject,
	//Item,
	//SelectedValue,
	//StandardProcessing);
	
EndProcedure

&AtClient
Procedure Attachable_AutoPick(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	
	//ExchangeWithGoogleClient.Attachable_AutoPick(
	//ThisObject,
	//Item,
	//Text,
	//ChoiceData,
	//Var_Parameters,
	//Waiting,
	//StandardProcessing);
	
EndProcedure

#EndRegion

#Region AttributesRowsCopying

&AtClient
Procedure InventoryRowsChangeValueOnChange(Item)
	
	CustomizeEditPanelAppearance(3);
	
EndProcedure

#EndRegion

#Region AttributesGroupChange

&AtClient
Procedure InventoryMarkOnChange(Item)
	
	//GroupRowsChangeClient.RowMarkOnChange(Object.Inventory, Items.InventoryCheckAll, Items.InventoryUncheckAll);
	
EndProcedure

&AtClient
Procedure InventoryRowsChangeActionOnChange(Item)
	
	CustomizeEditPanelAppearance(2);
	
EndProcedure

#EndRegion

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure InventoryInsertRows(Command)
	
	SectionRow = Items.Sections.CurrentData;
	If SectionRow = Undefined Then
		
		ErrorText = NStr("en='Необходимо выделить раздел, для которого добавляются запасы';ru='Необходимо выделить раздел, для которого добавляются запасы';vi='Cần chọn phân hệ thêm vật tư vào đó'");
		CommonUseClientServer.MessageToUser(ErrorText, , "Object.Sections");
		Return;
		
	EndIf;
	
	InsertRows(SectionRow, "Inventory");
	
EndProcedure

&AtClient
Procedure InventoryExecuteAction(Command)
	
	ProcessTable();
	CustomizeEditPanelAppearance(4);
	
EndProcedure

&AtClient
Procedure InventoryChangeRows(Command)
	
	ShowHideEditPanel(True);
	
	InventoryRowsChangeAction = Undefined;
	
EndProcedure

&AtClient
Procedure InventoryCopyRows(Command)
	
	CopyRows("Inventory");
	
EndProcedure

&AtClient
Procedure InventoryUndoChanges(Command)
	
	ShowHideEditPanel();
	
EndProcedure

&AtClient
Procedure InventoryUncheckAll(Command)
	
	SetMark(False);
	
EndProcedure

&AtClient
Procedure InventoryCheckAll(Command)
	
	SetMark(True);
	
EndProcedure

&AtClient
Procedure FillByInvoice(Command)
	
	If (Object.Sections.Count() + Object.Inventory.Count()) > 0 Then
		
		QuestionText = NStr("en='Current data tabular sections and stocks will be cleared."
"Continue?';ru='Текущие данные табличных частей разделы и запасы будут очищены."
"Продолжить?';vi='Dữ liệu hiện tại của phần bảng của phân hệ và vật tư sẽ bị xóa."
"Tiếp tục?'");
		
		NotifyDescription = New NotifyDescription("FillByInvoiceContinuation", ThisObject);
		ShowQueryBox(NotifyDescription, QuestionText, QuestionDialogMode.YesNo);
		Return;
		
	EndIf;
	
	SelectSupplierInvoice();
	
EndProcedure

&AtClient
Procedure FillByInvoiceContinuation(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		SelectSupplierInvoice();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SaveDocumentAsTemplate(Command) Export
	
	ObjectsFillingCMClient.SaveDocumentAsTemplate(Object, ShowedAttributes(), Command);
	
EndProcedure

&AtClient
Procedure EditPricesAndCurrency(Item, StandardProcessing)
	
	StandardProcessing = False;
	ProcessChangesOnButtonPricesAndCurrencies(Object.DocumentCurrency);
	Modified = True;
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtClient
Function DistributeProportionally(Val SrcAmount, CoeffMap, Val Accuracy = 2)
	
	Result = New Map;
	
	If CoeffMap.Count() = 0
		Or SrcAmount = 0
		Or SrcAmount = Null Then
		
		Return Result;
		
	EndIf;
	
	MaxIndex = 0;
	MaxVal = 0;
	DistribAmount = 0;
	CoeffAmount = 0;
	
	For Each MapItem In CoeffMap Do
		
		AbsNumber = ?(MapItem.Value > 0, MapItem.Value, - MapItem.Value);
		
		If MaxVal < AbsNumber Then
			
			MaxVal = AbsNumber;
			MaxIndex = MapItem.Key;
			
		EndIf;
		
		CoeffAmount = CoeffAmount + MapItem.Value;
		
	EndDo;
	
	If CoeffAmount = 0 Then
		
		Return Result;
		
	EndIf;
	
	For Each MapItem In CoeffMap Do
		
		NewAmount = Round(SrcAmount * MapItem.Value / CoeffAmount, Accuracy, 1);
		Result.Insert(MapItem.Key, NewAmount);
		DistribAmount = DistribAmount + NewAmount;
		
	EndDo;
	
	// Погрешности округления отнесем на коэффициент с максимальным весом
	If Not DistribAmount = SrcAmount Then
		
		ItemValue = Result.Get(MaxIndex);
		ItemValue = ItemValue + (SrcAmount - DistribAmount);
		
		Result.Insert(MaxIndex, ItemValue);
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Procedure DistributeCustomsFeeAmountByColumnsOfTableInventory(DistributingAmount, InventoryTable, ColumnName, BaseColumnName)
	
	If DistributingAmount <> 0 Then
		
		OldAmountsMap = New Map;
		For Each InventoryRow In InventoryTable Do
			
			OldAmountsMap.Insert(InventoryRow.GetID(), InventoryRow[?(IsBlankString(BaseColumnName), ColumnName, BaseColumnName)]);
			
		EndDo;
		
		NewAmountsMap = DistributeProportionally(DistributingAmount, OldAmountsMap);
		
		For Each MapItem In NewAmountsMap Do
			
			TableRow = InventoryTable.FindByID(MapItem.Key);
			TableRow[ColumnName] = MapItem.Value;
			
		EndDo;
		
	Else
		
		For Each InventoryRow In InventoryTable Do
			
			InventoryRow[ColumnName] = 0;
			
		EndDo;
		
	EndIf;

EndProcedure

&AtClient
Procedure ProcessContractChange(ContractData = Undefined)
	
	ContractBeforeChange = Contract;
	Contract = Object.Contract;
	
	If ContractBeforeChange <> Object.Contract Then
		
		DocumentParameters = New Structure;
		If ContractData = Undefined Then
			
			ContractData = GetDataContractOnChange(Object.Date, Object.DocumentCurrency, Object.Contract);
			
		Else
			
			DocumentParameters.Insert("CounterpartyBeforeChange", ContractData.CounterpartyBeforeChange);
			DocumentParameters.Insert("CounterpartyDoSettlementsByOrdersBeforeChange", ContractData.CounterpartyDoSettlementsByOrdersBeforeChange);
			DocumentParameters.Insert("ContractVisibleBeforeChange", Items.Contract.Visible);
			
		EndIf;
		
		SettlementsCurrencyBeforeChange = SettlementsCurrency;
		SettlementsCurrency = ContractData.SettlementsCurrency;
		
		NewContractAndCalculationCurrency = ValueIsFilled(Object.Contract) And ValueIsFilled(SettlementsCurrency) 
			And Object.Contract <> ContractBeforeChange And SettlementsCurrencyBeforeChange <> ContractData.SettlementsCurrency;
		
		OpenFormPricesAndCurrencies = NewContractAndCalculationCurrency And Object.DocumentCurrency <> ContractData.SettlementsCurrency
			And (Object.Inventory.Count() > 0 Or Object.Sections.Count() > 0);
		
		DocumentParameters.Insert("ContractBeforeChange", ContractBeforeChange);
		DocumentParameters.Insert("SettlementsCurrencyBeforeChange", SettlementsCurrencyBeforeChange);
		DocumentParameters.Insert("ContractData", ContractData);
		DocumentParameters.Insert("OpenFormPricesAndCurrencies", OpenFormPricesAndCurrencies);
		
		HandleContractAndCurrenciesSettlementsChangeProcess(DocumentParameters);
		
	Else
		
		Object.PurchaseOrder = DocOrder;
		
	EndIf;
	
	DocOrder = Object.PurchaseOrder;
	
EndProcedure

&AtClient
Procedure CalculateVATAmount(TabularSectionRow)
	
	CurrentRateParameters = New Structure;
	CurrentRateParameters.Insert("Currency",	Object.DocumentCurrency);
	CurrentRateParameters.Insert("ExchangeRate",		Object.ExchangeRate);
	CurrentRateParameters.Insert("Multiplicity",Object.Multiplicity);
	CurrentRateParameters.Insert("Ref",	Object.Ref);
	
	If Object.DocumentCurrency = NationalCurrency Then
		
		DutyAmount = TabularSectionRow.DutyAmount;
		
	Else
		
		NewRateParameters = New Structure;
		NewRateParameters.Insert("Currency",		NationalCurrency);
		NewRateParameters.Insert("ExchangeRate",		1);
		NewRateParameters.Insert("Multiplicity",	1);
		
		DutyAmount = WorkWithCurrencyRatesClientServer.RecalculateByRate(TabularSectionRow.DutyAmount, CurrentRateParameters, NewRateParameters);
		
	EndIf;
	
	VatAmount = SmallBusinessClientServer.CalculateVATAmountCCD(TabularSectionRow, CurrentRateParameters, NationalCurrency);
	
	TabularSectionRow.VatAmount = VatAmount;
	
	CalculateDocumentAmount();
	
EndProcedure

&AtClient
Procedure RecalculateExchangeRateMultiplicitySettlementCurrency(StructureData)
	
	NewExchangeRate = ?(StructureData.CurrencyRateRepetition.ExchangeRate = 0, 1, StructureData.CurrencyRateRepetition.ExchangeRate);
	NewRatio = ?(StructureData.CurrencyRateRepetition.Multiplicity = 0, 1, StructureData.CurrencyRateRepetition.Multiplicity);
	
	If Object.ExchangeRate <> NewExchangeRate
		Or Object.Multiplicity <> NewRatio Then
		
		CurrencyRateInLetters = String(Object.Multiplicity) + " " + TrimAll(SettlementsCurrency) + " = " + String(Object.ExchangeRate) + " " + TrimAll(NationalCurrency);
		RateNewCurrenciesInLetters = String(NewRatio) + " " + TrimAll(SettlementsCurrency) + " = " + String(NewExchangeRate) + " " + TrimAll(NationalCurrency);
		
		MessageText = NStr("ru = 'on date document у currencies settlements (" + CurrencyRateInLetters + ") was set exchangerate.
									|Set exchangerate settlements (" + RateNewCurrenciesInLetters + ") IN mapping с course currencies?'");
		
		Mode = QuestionDialogMode.YesNo;
		
		ShowQueryBox(New NotifyDescription("RecalculatePaymentCurrencyRateConversionFactorCompletion", ThisObject, New Structure("NewRatio, NewExchangeRate", NewRatio, NewExchangeRate)), MessageText, Mode, 0);
		Return;
		
	EndIf;
	
	// Сформируем надпись цены и валюты.
	RecalculatePaymentCurrencyRateConversionFactorFragment();
	
EndProcedure

&AtClient
Procedure RecalculatePaymentCurrencyRateConversionFactorCompletion(Result, AdditionalParameters) Export
	
	NewRatio = AdditionalParameters.NewRatio;
	NewExchangeRate = AdditionalParameters.NewExchangeRate;
	
	
	Response = Result;
	
	If Response = DialogReturnCode.Yes Then
		
		Object.ExchangeRate = NewExchangeRate;
		Object.Multiplicity = NewRatio;
		
		For Each TabularSectionRow In Object.Prepayment Do
			TabularSectionRow.PayAmount = SmallBusinessClient.RecalculateFromCurrencyToCurrency(
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
	
	LabelStructure = New Structure("DocumentCurrency, SettlementsCurrency, ExchangeRate, RateNationalCurrency, AmountIncludesVAT, CurrencyTransactionsAccounting, VATTaxation", Object.DocumentCurrency, SettlementsCurrency, Object.ExchangeRate, RateNationalCurrency, Object.AmountIncludesVAT, CurrencyTransactionsAccounting, Object.VATTaxation);
	PricesAndCurrency = GenerateLabelPricesAndCurrency(LabelStructure);

EndProcedure

&AtClient
Procedure ProcessChangesOnButtonPricesAndCurrencies(Val SettlementsCurrencyBeforeChange, RecalculatePrices = False, WarningText = "")
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("ReadOnly", 		ThisObject.ReadOnly);
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
	ParametersStructure.Insert("RefillPrices",	False);
	ParametersStructure.Insert("RecalculatePrices",		RecalculatePrices);
	ParametersStructure.Insert("WereMadeChanges",False);
	ParametersStructure.Insert("WarningText",	WarningText);
	
	NotifyDescription = New NotifyDescription("OpenPricesAndCurrencyFormCompletion", ThisObject, New Structure("SettlementsCurrencyBeforeChange", SettlementsCurrencyBeforeChange));
	OpenForm("CommonForm.PricesAndCurrencyForm", ParametersStructure, ThisForm, , , , NotifyDescription, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure HandleContractAndCurrenciesSettlementsChangeProcess(DocumentParameters)
	
	SettlementsCurrencyBeforeChange = DocumentParameters.SettlementsCurrencyBeforeChange;
	ContractData = DocumentParameters.ContractData;
	OpenFormPricesAndCurrencies = DocumentParameters.OpenFormPricesAndCurrencies;
	
	If Not ContractData.AmountIncludesVAT = Undefined Then
		
		Object.AmountIncludesVAT = ContractData.AmountIncludesVAT;
		
	EndIf;
	
	If ValueIsFilled(Object.Contract) Then 
		
		Object.ExchangeRate	  = ?(ContractData.SettlementsCurrencyRateRepetition.ExchangeRate = 0, 1, ContractData.SettlementsCurrencyRateRepetition.ExchangeRate);
		Object.Multiplicity = ?(ContractData.SettlementsCurrencyRateRepetition.Multiplicity = 0, 1, ContractData.SettlementsCurrencyRateRepetition.Multiplicity);
		
	EndIf;
	
	Object.DocumentCurrency = ContractData.SettlementsCurrency;
	DocOrder = Object.PurchaseOrder;
	
	If OpenFormPricesAndCurrencies Then
		
		WarningText = NStr("en='Изменилась валюта расчетов по договору с контрагентом!"
"Необходимо проверить валюту документа!';ru='Изменилась валюта расчетов по договору с контрагентом!"
"Необходимо проверить валюту документа!';vi='Tiền tệ thanh toán theo hợp đồng với đối tác đã thay đổi!"
"Cần kiểm tra tiền tệ chứng từ!'");
										
		ProcessChangesOnButtonPricesAndCurrencies(SettlementsCurrencyBeforeChange, True, WarningText);
		
	Else
		
		LabelStructure = New Structure("DocumentCurrency, SettlementsCurrency, ExchangeRate, RateNationalCurrency, AmountIncludesVAT, CurrencyTransactionsAccounting, VATTaxation", 
			Object.DocumentCurrency, 
			SettlementsCurrency, 
			Object.ExchangeRate, 
			RateNationalCurrency, 
			Object.AmountIncludesVAT, 
			CurrencyTransactionsAccounting, 
			Object.VATTaxation);
			
		PricesAndCurrency = GenerateLabelPricesAndCurrency(LabelStructure);
		
	EndIf;
	
	If DocumentParameters.Property("ChangeVariableSettlementsCurrency") Then
		
		SettlementsCurrency = ContractData.SettlementsCurrency;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenPricesAndCurrencyFormCompletion(ClosingResult, AdditionalParameters) Export
	
	If TypeOf(ClosingResult) = Type("Structure") 
		And ClosingResult.WereMadeChanges Then
		
		Object.DocumentCurrency = ClosingResult.DocumentCurrency;
		Object.ExchangeRate = ClosingResult.PaymentsRate;
		Object.Multiplicity = ClosingResult.SettlementsMultiplicity;
		Object.VATTaxation = ClosingResult.VATTaxation;
		Object.AmountIncludesVAT = ClosingResult.AmountIncludesVAT;
		Object.IncludeVATInPrice = ClosingResult.IncludeVATInPrice;
		SettlementsCurrencyBeforeChange = AdditionalParameters.SettlementsCurrencyBeforeChange;
		
		// Пересчитываем цены по валюте.
		If ClosingResult.RecalculatePrices Then
			
			SmallBusinessClient.RecalculateTabularSectionPricesByCurrency(ThisForm, SettlementsCurrencyBeforeChange, "Inventory");
			SmallBusinessClient.RecalculateTabularSectionPricesByCurrency(ThisForm, SettlementsCurrencyBeforeChange, "Sections");
			
		EndIf;
		
		// Пересчитываем сумму если изменился признак "Сумма включает НДС".
		If ClosingResult.AmountIncludesVAT <> ClosingResult.PrevAmountIncludesVAT Then
			
			SmallBusinessClient.RecalculateTabularSectionAmountByFlagAmountIncludesVAT(ThisForm, "Sections");
			
		EndIf;
		
	EndIf;
	
	LabelStructure = New Structure("DocumentCurrency, SettlementsCurrency, ExchangeRate, RateNationalCurrency, AmountIncludesVAT, CurrencyTransactionsAccounting, VATTaxation",
		Object.DocumentCurrency,
		SettlementsCurrency,
		Object.ExchangeRate,
		RateNationalCurrency,
		Object.AmountIncludesVAT,
		CurrencyTransactionsAccounting,
		Object.VATTaxation);
		
	PricesAndCurrency = GenerateLabelPricesAndCurrency(LabelStructure);
	
EndProcedure

&AtClient
Procedure DefineAdvancePaymentOffsetsRefreshNeed(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult = DialogReturnCode.Yes Then
		
		Object.Prepayment.Clear();
		HandleContractAndCurrenciesSettlementsChangeProcess(AdditionalParameters);
		
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
	
EndProcedure

&AtClient
Function CalculateCCDDutyAmount(Val RowData, Val ObjectData, Val CurrencyRegAccounting)

	If Not ValueIsFilled(ObjectData.DocumentCurrency) Then
		
		CustomsCostCur = RowData.CustomsCost;
		
	Else
		
		CurrentRateParameters = New Structure;
		CurrentRateParameters.Insert("Currency",	ObjectData.DocumentCurrency);
		CurrentRateParameters.Insert("ExchangeRate",		ObjectData.ExchangeRateDocument);
		CurrentRateParameters.Insert("Multiplicity",ObjectData.MultiplicityOfDocument);
		
		NewRateParameters = New Structure;
		NewRateParameters.Insert("Currency",		ObjectData.CurrencyOfRegulatedAccounting);
		NewRateParameters.Insert("ExchangeRate",		1);
		NewRateParameters.Insert("Multiplicity",	1);
		
		CustomsCostCur = WorkWithCurrencyRatesClientServer.RecalculateByRate(RowData.CustomsCost, CurrentRateParameters, NewRateParameters);
		
	EndIf;

	//++ БПВ
	CumulativeTotalFee = RowData.CumulativeTotalFee;
	Return (CustomsCostCur + CumulativeTotalFee) * RowData.RateFee / 100;
	//-- БПВ
	
EndFunction

&AtClient
Procedure OnChangeDutyRateCost(SectionNumber)
	
	SectionRow = Object.Sections.Get(SectionNumber - 1);
	
	ObjectData = New Structure("DocumentCurrency,MutualSettlementsExchangeRate,MutualSettlementsCurrencyRate");
	FillPropertyValues(ObjectData, Object);
	
	ObjectData.Insert("Ref", Object.Ref);
	ObjectData.Insert("SettlementsCurrency", SettlementsCurrency);
	ObjectData.Insert("CurrencyOfRegulatedAccounting", NationalCurrency);
	ObjectData.Insert("ExchangeRateDocument", Object.ExchangeRate);
	ObjectData.Insert("MultiplicityOfDocument", Object.Multiplicity);
	
	RowData = New Structure("CustomsCost, CumulativeTotalFee, RateFee, DutyAmount, VATRate, VATAmount, LineNumber");
	FillPropertyValues(RowData, SectionRow);
	
	#Region CumulativeTotal
	
	RowData.CumulativeTotalFee = 0;
	
	If RowData.LineNumber > 1 Then
		 
		Для PreviousSectionNumber = 1 По SectionNumber - 1 Цикл
			
			PreviousSectionRow = Object.Sections.Get(PreviousSectionNumber - 1);
			
			FeeCostCur = PreviousSectionRow.DutyAmount;
			RowData.CumulativeTotalFee = RowData.CumulativeTotalFee + FeeCostCur;
			
		EndDo;
		
	EndIf;
	
	#EndRegion
	
	SectionRow.DutyAmount = CalculateCCDDutyAmount(RowData, ObjectData, NationalCurrency);
	RowData.DutyAmount  = SectionRow.DutyAmount;
	CalculateVATAmount(SectionRow);
	
	CalculateDocumentAmount();
	
	DistributeVATAndDutyBySectionServer(SectionNumber);
	
	// Fill next sections
	SectionCount = Object.Sections.Count();
	Если SectionCount > SectionNumber Тогда
		OnChangeDutyRateCost(SectionNumber+1)
	КонецЕсли;

EndProcedure

&AtClient
Procedure OnChangeVATRateDutyAmount(SectionRow)
	
	CalculateVATAmount(SectionRow);
	DistributeVATAndDutyBySectionServer(Object.Sections.IndexOf(SectionRow) + 1);
	
EndProcedure

&AtClient
Procedure FillSectionInfo(RowID)
	
	If RowID <> Undefined Then
		
		SectionRowData = Object.Sections.FindByID(RowID);
		
		SectionCode = ?(IsBlankString(TrimAll(SectionRowData.FEACNCode)), "0000000000", TrimAll(SectionRowData.FEACNCode));
		
		SectionNumber = SectionRowData.LineNumber;
		ProductsInSection = Object.Inventory.FindRows(New Structure("SectionNumber", SectionNumber));
		ProductsQuantityInSection = ?(TypeOf(ProductsInSection) = Type("Array"), ProductsInSection.Count(), 0);
		
		InformationRow = NStr("en='Product code: %1, rows in section: %2';ru='Код товаров: %1, строк в разделе: %2';vi='Mã hàng hóa: %1, các dòng trong phân hệ: %2'");
		SectionRowData.CCDSectionInfo = StrTemplate(InformationRow, SectionCode, ProductsQuantityInSection);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RecalculateSectionTotals(SectionNumber, ColumnName = "")
	
	If SectionNumber = 0 Then
		
		Return;
		
	EndIf;
	
	SectionData = Object.Sections.Get(SectionNumber - 1);
	OldCustomsCost = SectionData.CustomsCost;
	
	TOTALS = New Structure("DutyAmount,VATAmount,CustomsCost", 0, 0, 0);
	
	SectionProducts = Object.Inventory.FindRows(New Structure("SectionNumber", SectionNumber));
	For Each TableRow In SectionProducts Do
		
		TOTALS.DutyAmount			= TOTALS.DutyAmount + TableRow.DutyAmount;
		TOTALS.VATAmount				= TOTALS.VATAmount + TableRow.VATAmount;
		TOTALS.CustomsCost	= TOTALS.CustomsCost + TableRow.InvoiceCost;
		
	EndDo;
	
	If ColumnName = "" Then
		
		FillPropertyValues(SectionData, TOTALS);
		
	Else
		
		SectionData[ColumnName] = TOTALS[ColumnName];
		
	EndIf; 
	
	If OldCustomsCost <> SectionData.CustomsCost Then
		
		OnChangeDutyRateCost(SectionNumber);
		
	EndIf;
	
	CalculateDocumentAmount();
	
EndProcedure

&AtClient
Procedure CalculateDocumentAmount()
	
	Object.DocumentAmount = Object.Sections.Total("VATAmount") + Object.Sections.Total("DutyAmount") + Object.CustomsFee + Object.CustomsPenalty;
	
EndProcedure

&AtClient
Procedure SelectSupplierInvoice()
	
	OpenParameters = New Structure;
	OpenParameters.Insert("MultipleChoice", False);
	
	NotifyDescription = New NotifyDescription("AfterSelectSupplierInvoice", ThisObject);
	
	OpenForm("Document.SupplierInvoice.ChoiceForm", OpenParameters, ThisForm, , , , NotifyDescription);
	
EndProcedure

&AtClient
Procedure AfterSelectSupplierInvoice(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result)
		And TypeOf(Result) = Type("DocumentRef.SupplierInvoice") Then
		
		FillByInvoiceAtServer(Result);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DistributeFeeAmountByInventory()
	
	If Object.Inventory.Count() < 1 Then
		
		Return;
		
	EndIf;
	
	If Items.InventoryFeeAmount.Enabled Then // Если включено уточнение
		
		Return;
		
	EndIf;
	
	DistributeCustomsFeeAmountByColumnsOfTableInventory(Object.CustomsFee, Object.Inventory, "FeeAmount", "InvoiceCost");
	
EndProcedure

&AtClientAtServerNoContext
Function GenerateLabelPricesAndCurrency(LabelStructure)
	
	LabelText = "";
	
	// Валюта.
	If LabelStructure.CurrencyTransactionsAccounting Then
		If ValueIsFilled(LabelStructure.DocumentCurrency) Then
			LabelText = NStr("en='%Currency%';ru='%Currency%';vi='%Currency%'");
			If LabelStructure.DocumentCurrency <> SmallBusinessReUse.GetNationalCurrency() Then
				LabelText = LabelText + NStr("en=' %ExchangeRate%';ru=' %ExchangeRate%';vi=' %ExchangeRate%'");
				LabelText = StrReplace(LabelText, "%Currency%", TrimAll(SmallBusinessReUse.GetCharCurrencyPresentation(LabelStructure.DocumentCurrency)));
				LabelText = StrReplace(LabelText, "%ExchangeRate%", TrimAll(String(LabelStructure.ExchangeRate)));
			Else
				LabelText = StrReplace(LabelText, "%Currency%", TrimAll(String(LabelStructure.DocumentCurrency)));
			EndIf;
		EndIf;
	EndIf;
	
	// Налогообложение НДС.
	If ValueIsFilled(LabelStructure.VATTaxation) Then
		
		If IsBlankString(LabelText) Then
			
			LabelText = LabelText + NStr("en='%VATTaxation%';ru='%VATTaxation%';vi='%VATTaxation%'");
			
		Else
			
			LabelText = LabelText + NStr("en=' • %VATTaxation%';ru=' • %VATTaxation%';vi='• %VATTaxation%'");
			
		EndIf;
		
		LabelText = StrReplace(LabelText, "%VATTaxation%", WorkWithDocumentFormClientServer.ShortPresentationOfVATTaxationType(LabelStructure.VATTaxation));
		
	EndIf;
	
	// Флаг сумма включает НДС.
	LabelText = LabelText 
		+ ?(IsBlankString(LabelText), "", " • ")
		+ ?(LabelStructure.AmountIncludesVAT, NStr("en='Amount include VAT НДС';ru='Сумма включает НДС';vi='Số tiền gồm thuế GTGT'"), NStr("en='Amount not include VAT';ru='Сумма не включает НДС';vi='Số tiền không gồm thuế GTGT'"));
	
	Return LabelText;
	
EndFunction

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
	
EndFunction

&AtServerNoContext
Function GetCompanyDataOnChange(Company)
	
	StructureData = New Structure;
	
	StructureData.Insert("SubsidiaryCompany", SmallBusinessServer.GetCompany(Company));
	
	Return StructureData;
	
EndFunction

&AtServerNoContext
Function GetDataProductsAndServicesOnChange(StructureData)
	
	StructureData.Insert("CountryOfOrigin", StructureData.ProductsAndServices.CountryOfOrigin);
	//StructureData.Insert("VATRate", Catalogs.VATRates.VATRate(StructureData.ProductsAndServices.VATRateKind, ?(ValueIsFilled(StructureData.ProcessingDate), StructureData.ProcessingDate, CurrentSessionDate())));
	
	StructureData.Insert("VATRate", StructureData.ProductsAndServices.VATRate);
	
	
	// Характеристики
	StructureData.Insert("UseCharacteristics",False);
	StructureData.Insert("CheckCharacteristicFilling",False);
	
	If ValueIsFilled(StructureData.ProductsAndServices) And StructureData.ProductsAndServices.UseCharacteristics
		Then
		DefaultValues = ProductsAndServicesInDocumentsServer.DefaultProductsAndServicesValues(StructureData.ProductsAndServices);
		
		If Not DefaultValues = Undefined
			Then
			DefaultCharacteristic = DefaultValues;
		EndIf;
		
		If Not StructureData.Property("Characteristic") Then
			StructureData.Insert("Characteristic",DefaultCharacteristic);
		Else
			StructureData.Characteristic = ?(ValueIsFilled(StructureData.Characteristic), StructureData.Characteristic, DefaultCharacteristic);
		EndIf;
		
		StructureData.Insert("UseCharacteristics",True);
		StructureData.Insert("CheckCharacteristicFilling",StructureData.ProductsAndServices.CheckCharacteristicFilling);
	EndIf; 
	// Конец Характеристики
	
	//Партии
	StructureData.Insert("UseBatches",False);
	StructureData.Insert("CheckBatchFilling",False);
	
	If Not StructureData.Property("Batch") Then
		StructureData.Insert("Batch", Undefined);
	EndIf;
	
	If ValueIsFilled(StructureData.ProductsAndServices) And StructureData.ProductsAndServices.UseBatches
		Then
		
		If StructureData.Property("BatchStatus")
			Then
			DefaultBatchValues = ProductsAndServicesInDocumentsServer.DefaultProductsAndServicesBatchesValues(StructureData.ProductsAndServices,StructureData.BatchStatus);
		Else
			If Not StructureData.Property("OperationKind")
				Then
				OperationKind = Undefined
			Else
				OperationKind = StructureData.OperationKind
			EndIf;
			
			BatchStatus = ProductsAndServicesInDocumentsServer.TypeOfTransactionOrHozOperationBatchStatus(, OperationKind);
			DefaultBatchValues = ProductsAndServicesInDocumentsServer.DefaultProductsAndServicesBatchesValues(StructureData.ProductsAndServices,BatchStatus);
		EndIf;
		
		BatchByDefolt = Catalogs.ProductsAndServicesBatches.EmptyRef();
		
		If Not DefaultBatchValues = Undefined
			Then
			BatchByDefolt = DefaultBatchValues;
		EndIf;
		
		StructureData.Batch = ?(ValueIsFilled(StructureData.Batch), StructureData.Batch, BatchByDefolt);
		
		StructureData.CheckBatchFilling = StructureData.ProductsAndServices.CheckBatchFilling;
		StructureData.UseBatches = True;
		
	EndIf;
	// Конец Партии
	
	Return StructureData;
	
EndFunction

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
		"AmountIncludesVAT",
		?(ValueIsFilled(Contract.PriceKind), Contract.PriceKind.PriceIncludesVAT, Undefined)
	);
	
	Return StructureData;
	
EndFunction

&AtServerNoContext
Function GetChoiceFormParameters(Document, Company, Counterparty, Contract)
	
	ContractTypesList = Catalogs.CounterpartyContracts.GetContractKindsListForDocument(Document);
	
	FormParameters = New Structure;
	FormParameters.Insert("ControlContractChoice", Counterparty.DoOperationsByContracts);
	FormParameters.Insert("Counterparty", Counterparty);
	FormParameters.Insert("Company", Company);
	FormParameters.Insert("ContractKinds", ContractTypesList);
	FormParameters.Insert("CurrentRow", Contract);
	FormParameters.Insert("ChoiceMode", True);
	
	Return FormParameters;
	
EndFunction

&AtServerNoContext
Function GetContractByDefault(Document, Counterparty, Company)
	
	If Not Counterparty.DoOperationsByContracts Then
		Return Catalogs.CounterpartyContracts.ContractByDefault(Counterparty);
	EndIf;
	
	ManagerOfCatalog = Catalogs.CounterpartyContracts;
	
	ContractTypesList = ManagerOfCatalog.GetContractKindsListForDocument(Document);
	ContractByDefault = ManagerOfCatalog.GetDefaultContractByCompanyContractKind(Counterparty, Company, ContractTypesList);
	
	Return ContractByDefault;
	
EndFunction

&AtServer
Procedure TabularSectionsConditionalAppearance()
	
	TNFEACheckError = ConditionalAppearance.Items.Add();
	TNFEACheckError.Appearance.SetParameterValue("BackColor", New Color(255,200,200));
	
	FilterItem = TNFEACheckError.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue = New DataCompositionField("Object.Inventory.TNFEAFillingError");
	FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem.RightValue = True;
	
	DataCompositionClientServer.AddAppearanceField(TNFEACheckError.Fields, "InventoryProductsAndServicesCommodityProductsAndServicesFEA");
	
EndProcedure

&AtServer
Procedure CheckTNFEAFilling()
	
	FilterParameters = New Structure("SectionNumber");
	
	For Each TableRowSections In Object.Sections Do
		
		TNFEA = Undefined;
		
		FilterParameters.SectionNumber = TableRowSections.LineNumber;
		FoundStrings = Object.Inventory.FindRows(FilterParameters);
		
		For Each InventoryTableRow In FoundStrings Do
			
			If ValueIsFilled(InventoryTableRow.ProductsAndServices.CommodityFEAProductsAndServices) Then
				
				If TNFEA = Undefined Then
					
					TNFEA = InventoryTableRow.ProductsAndServices.CommodityFEAProductsAndServices;
					Continue;
					
				EndIf;
				
				InventoryTableRow.TNFEAFillingError = (TNFEA <> InventoryTableRow.ProductsAndServices.CommodityFEAProductsAndServices);
				
			Else
				
				InventoryTableRow.TNFEAFillingError = True;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

&AtServer
Function ShowedAttributes()
	
	Return ObjectFillingSB.ShowedAttributes(ThisForm);
	
EndFunction

&AtServer
Function GetDataCounterpartyOnChange(Date, DocumentCurrency, Counterparty, Company)
	
	ContractByDefault = GetContractByDefault(Object.Ref, Counterparty, Company);
	
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
		"SettlementsInStandardUnits",
		ContractByDefault.SettlementsInStandardUnits
	);
	
	StructureData.Insert(
		"AmountIncludesVAT",
		?(ValueIsFilled(ContractByDefault.PriceKind), Contract.PriceKind.PriceIncludesVAT, Undefined)
	);
	
	SetContractVisible();
	
	Return StructureData;
	
EndFunction

&AtServer
Procedure SetContractVisible()
	
	CounterpartyDoSettlementsByOrders = Object.Counterparty.DoOperationsByOrders;
	Items.Contract.Visible = Object.Counterparty.DoOperationsByContracts;
	
EndProcedure

&AtServer
Procedure DistributeVATAndDutyBySectionServer(SectionNumber)
	
	SectionRow 		= Object.Sections.Get(SectionNumber - 1);
	DutyAmount		= SectionRow.DutyAmount;
	VATAmount			= SectionRow.VATAmount;
	
	RowArray  = Object.Inventory.FindRows(New Structure("SectionNumber", SectionNumber));
	DistributionBasis = New Array;
	
	TotalCost = 0;
	For Each ArrayElement In RowArray Do
		
		TotalCost = TotalCost + ArrayElement.InvoiceCost;
		DistributionBasis.Add(ArrayElement.InvoiceCost);
		
	EndDo;
	
	If TotalCost = 0 Then
		
		If RowArray.Count() > 0 Then
			
			MessageText = NStr("en='The total amount of the invoice of the section %1 is zero!"
"Distribution is not possible.';ru='Общая сумма фактурной стоимости раздела %1 нулевая!"
"Распределение невозможно.';vi='Tổng giá trị hóa đơn của phân hệ %1 bằng 0!"
"Không thể phân bổ.'");
			
			MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText, SectionNumber);
			CommonUseClientServer.MessageToUser(MessageText,, "Goods", "Object");
			
		EndIf;
		
		Return;
		
	EndIf;
	
	If Not DutyAmount = 0 Then
		
		DistributionResultArray_Duty = CommonUse.DistributeAmountProportionallyToFactors(DutyAmount,
			DistributionBasis);
		
	EndIf;
	
	If Not VATAmount = 0 Then
		
		DistributionResultArray_VAT = CommonUse.DistributeAmountProportionallyToFactors(VATAmount,
			DistributionBasis);
		
	EndIf;
	
	For RowIndex = 0 To RowArray.Count() - 1 Do
		
		ArrayRow				= RowArray[RowIndex];
		ArrayRow.DutyAmount	= ?(DutyAmount = 0,	0, DistributionResultArray_Duty[RowIndex]);
		ArrayRow.VATAmount		= ?(VATAmount = 0,		0, DistributionResultArray_VAT[RowIndex]);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure DeleteSectionProducts(SectionNumber)
	
	RowArray = Object.Inventory.FindRows(New Structure("SectionNumber", SectionNumber));
	For Each SectionRow In RowArray Do
		
		Object.Inventory.Delete(SectionRow);
		
	EndDo;
	
	If Object.Sections.Count() > SectionNumber Then
		
		RecalculateSectionsNumbers(SectionNumber);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure RecalculateSectionsNumbers(DeletedSectionNumber)
	
	For Each ProductsRow In Object.Inventory Do
		
		If ProductsRow.SectionNumber > DeletedSectionNumber Then
			
			ProductsRow.SectionNumber = ProductsRow.SectionNumber - 1;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillByInvoiceAtServer(DocumentRef)
	
	CurrentDocumentObject = FormAttributeToValue("Object");
	CurrentDocumentObject.Fill(DocumentRef);
	ValueToFormAttribute(CurrentDocumentObject, "Object");
	
	Modified = True;
	
	ProductsAndServicesInDocumentsServer.FillCharacteristicsUsageFlags(Object);
	
EndProcedure

#Region InternalRowsCopying

&AtClient
Procedure InsertRows(SectionRow, TSName)
	
	NumberOfCopied = 0;
	NumberOfInserted = 0;
	InsertRowsAtServer(SectionRow.LineNumber, TSName, NumberOfCopied, NumberOfInserted);
	
	FillSectionInfo(SectionRow.GetID());
	
EndProcedure

&AtClient
Procedure CopyRows(TSName)
	
	//If CopyTabularSectionClient.CopyRowsAvailable(Object[TSName], Items[TSName].CurrentData) Then
	//	NumberOfCopied = 0;
	//	CopyRowsAtServer(TSName, NumberOfCopied);
	//	CopyTabularSectionClient.NotifyUserAboutCopyingRows(NumberOfCopied);
	//EndIf;
	
EndProcedure

&AtServer
Procedure TableBackupManagement(MigrationState, ModifiesData)
	
	GroupRowsChangeServer.BackupManagement(
		ThisObject,
		Object.Inventory,
		InventoryTableBackupAddress,
		MigrationState,
		ModifiesData
	);
	
EndProcedure

&AtServer
Procedure SetMark(Check)
	
	Items.InventoryUncheckAll.Visible = Not Items.InventoryUncheckAll.Visible;
	Items.InventoryCheckAll.Visible = Not Items.InventoryCheckAll.Visible;
	
	For Each Row In Object.Inventory Do
		Row.Check = Check;
	EndDo;
	
EndProcedure

&AtClient
Procedure SaveCurrentRowChangeAction()
	
	If InventoryRowsChangeAction = InventoryRowsChangeActionOnOpen Then
		Return;
	EndIf;
	
	SaveCurrentRowChangeActionServer();
	
EndProcedure

&AtServer
Procedure SaveCurrentRowChangeActionServer()
	
	GroupRowsChangeServer.SaveSettings(GroupRowsChangeItemsServer());
	
EndProcedure

&AtServer
Procedure CopyRowsAtServer(TSName, NumberOfCopied)
	
	CopyTabularSectionServer.Copy(Object[TSName], Items[TSName].SelectedRows, NumberOfCopied);
	
EndProcedure

&AtServer
Procedure InsertRowsAtServer(SectionRowNumber, TSName, NumberOfCopied, NumberOfInserted)
	
	CopyTabularSectionServer.Insert(Object, TSName, Items, NumberOfCopied, NumberOfInserted);
	ProcessInsertedRowsAtServer(SectionRowNumber, TSName, NumberOfInserted);
	
	ProductsAndServicesInDocumentsServer.FillCharacteristicsUsageFlags(Object);
	
EndProcedure

&AtServer
Procedure ProcessInsertedRowsAtServer(SectionRowNumber, TSName, NumberOfInserted)
	
	Quantity = Object[TSName].Count();
	
	For Iterator = 1 To NumberOfInserted Do
		
		Row = Object[TSName][Quantity - Iterator];
		
		StructureData = New Structure;
		StructureData.Insert("Company", Object.Company);
		StructureData.Insert("ProductsAndServices", Row.ProductsAndServices);
		StructureData.Insert("VATTaxation", Object.VATTaxation);
		StructureData.Insert("ProcessingDate", Object.Date);
		
		StructureData = GetDataProductsAndServicesOnChange(StructureData);
		
		Row.SectionNumber = SectionRowNumber;
		Row.VATAmount = 0;
		
		If Not ValueIsFilled(Row.CountryOfOrigin) Then
			
			Row.CountryOfOrigin = StructureData.CountryOfOrigin;
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region InternalGroupChange

&AtClient
Procedure ProcessTable()
	Var Errors, ChangedSections;
	
	SectionRow = Items.Sections.CurrentData;
	If SectionRow = Undefined Then
		
		ErrorText = NStr("en='Укажите раздел ГТД, в который необходимо добавить товары';ru='Укажите раздел ГТД, в который необходимо добавить товары';vi='Hãy chỉ ra phân hệ tờ khai hải quan cần thêm hàng hóa vào đó'");
		CommonUseClientServer.AddUserError(Errors, "Sections", ErrorText, "");
		
	Else
		
		ProcessTableAtServer(SectionRow.GetID(), ChangedSections, Errors);
		
	EndIf;
	
	If Not Errors = Undefined Then
		
		CommonUseClientServer.ShowErrorsToUser(Errors);
		Return;
		
	EndIf;
	
	If InventoryRowsChangeAction = PredefinedValue("Enum.BulkRowChangeActions.AddFromDocument")
		Or InventoryRowsChangeAction = PredefinedValue("Enum.BulkRowChangeActions.AddImportedProductsFromDocument")
		Or InventoryRowsChangeAction = PredefinedValue("Enum.BulkRowChangeActions.PickCCDNumbers")
		Or InventoryRowsChangeAction = PredefinedValue("Enum.BulkRowChangeActions.DeleteRows")
		Then
		
		RecalculateSectionTotals(SectionRow.LineNumber);
		FillSectionInfo(SectionRow.GetID());
		
		DistributeFeeAmountByInventory();
		
	ElsIf InventoryRowsChangeAction = PredefinedValue("Enum.BulkRowChangeActions.DistributeAmountByAmounts") 
		And Not Items.InventoryFeeAmount.Enabled Then
		
		DistributeFeeAmountByInventory();
		
	ElsIf InventoryRowsChangeAction = PredefinedValue("Enum.BulkRowChangeActions.SetSourceLocation") Then
		
		If ChangedSections <> Undefined Then
			
			For Each SectionRow In Object.Sections Do
				
				If ChangedSections.Find(SectionRow.LineNumber) = Undefined Then
					
					Continue;
					
				EndIf;
				
				RecalculateSectionTotals(SectionRow.LineNumber, "CustomsCost");
				FillSectionInfo(SectionRow.GetID());
				
			EndDo;
			
			DistributeFeeAmountByInventory();
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CustomizeEditPanelAppearance(State, SaveChanges = Undefined)
	
	GroupRowsChangeClient.CustomizeEditPanelAppearance(
		ThisObject,
		GroupRowsChangeItemsClient(),
		State,
		InventoryRowsChangeValue
	);
	
	OnChangeCurrentAction();
	
EndProcedure

&AtClient
Function GroupRowsChangeItemsClient()
	
	SetElements = New Structure();
	SetElements.Insert("TSName", "Inventory");
	SetElements.Insert("DocumentRef", Object.Ref);
	SetElements.Insert("EditPanel", Items.GroupInventoryRowsChange);
	SetElements.Insert("ActionGroup", Items.GroupInventoryChoiceAction);
	SetElements.Insert("ValueGroup", Items.GroupInventoryChoiceValue);
	SetElements.Insert("ExecuteGroup", Items.GroupInventoryExecuteAction);
	SetElements.Insert("ButtonExecuteAction", Items.InventoryExecuteAction);
	SetElements.Insert("ColumnMark", Items.InventoryMark);
	SetElements.Insert("ColumnLineNumber", Items.InventoryLineNumber);
	SetElements.Insert("Action", ThisForm.InventoryRowsChangeAction);
	SetElements.Insert("ActionItem", Items.InventoryRowsChangeAction);
	SetElements.Insert("Value", ThisForm.InventoryRowsChangeValue);
	SetElements.Insert("ValueItem", Items.InventoryRowsChangeValue);
	SetElements.Insert("ChangingObject", ""); 				// Неактуально
	SetElements.Insert("ColumnChangingObject", Undefined);// Неактуально
	Return SetElements;
	
EndFunction

&AtServer
Procedure InitializeGroupRowsChange()
	
	FillActionsList();
	GroupRowsChangeServer.OnCreateAtServer(GroupRowsChangeItemsServer(), ThisForm.InventoryRowsChangeAction);
	InventoryRowsChangeActionOnOpen = InventoryRowsChangeAction;
	SetMark(True);
	
EndProcedure

&AtServer
Procedure ProcessTableAtServer(SectionID, ChangedSections, Errors)
	
	If InventoryRowsChangeAction = Enums.BulkRowChangeActions.PickBatchDocuments Then
		
		PickBatchDocuments(SectionID, Errors);
		
	ElsIf InventoryRowsChangeAction = Enums.BulkRowChangeActions.AddFromDocument Then
		
		AddRowsToSectionFromDocument(SectionID, False, Errors);
		
	ElsIf InventoryRowsChangeAction = Enums.BulkRowChangeActions.AddImportedProductsFromDocument Then
		
		AddRowsToSectionFromDocument(SectionID, True, Errors);
		
	ElsIf InventoryRowsChangeAction = Enums.BulkRowChangeActions.PickCCDNumbers Then
		
		AddRowsToSectionFromDocumentsSupplierInvoice(SectionID, Errors);
		
	ElsIf InventoryRowsChangeAction = Enums.BulkRowChangeActions.DistributeAmountByAmounts Then
		
		CommonUseClientServer.SetFormItemProperty(Items, "InventoryFeeAmount", "Enabled", Not Items.InventoryFeeAmount.Enabled);
		
	ElsIf InventoryRowsChangeAction = Enums.BulkRowChangeActions.DeleteRows Then
		
		MarkedRows = Object.Inventory.FindRows(New Structure("Check", True));
		For Each TableRow In MarkedRows Do
			
			Object.Inventory.Delete(TableRow);
			
		EndDo;
		
	ElsIf InventoryRowsChangeAction = Enums.BulkRowChangeActions.SetSourceLocation Then
		
		ChangedSections = New Array;
		ChangedSections.Add(InventoryRowsChangeValue);
		
		MarkedRows = Object.Inventory.FindRows(New Structure("Check", True));
		For Each TableRow In MarkedRows Do
			
			If ChangedSections.Find(TableRow.SectionNumber) = Undefined Then
				
				ChangedSections.Add(TableRow.SectionNumber);
				
			EndIf;
			
			TableRow.SectionNumber = InventoryRowsChangeValue;
			
		EndDo;
		
		If ChangedSections.Count() = 1 Then
			
			ChangedSections = Undefined;
			
		EndIf;
		
	EndIf;
	
	ProductsAndServicesInDocumentsServer.FillCharacteristicsUsageFlags(Object);
	
EndProcedure

&AtClient
Procedure OnChangeCurrentAction()
	
	TypeArray = New Array;
	
	If InventoryRowsChangeAction = PredefinedValue("Enum.BulkRowChangeActions.SetSourceLocation") Then
		
		TypeArray.Add(Type("Number"));
		
		CurrentSectionData = Items.Sections.CurrentData;
		
		Items.InventoryRowsChangeValue.ChoiceList.Clear();
		For SectionsCounter = 1 To Object.Sections.Count() Do
			
			If Not CurrentSectionData.LineNumber = SectionsCounter Then
				
				Items.InventoryRowsChangeValue.ChoiceList.Add(SectionsCounter, "Section " + SectionsCounter);
				
			EndIf;
			
		EndDo;
		
		If Items.InventoryRowsChangeValue.ChoiceList.Count() = 1 Then
			
			InventoryRowsChangeValue = Items.InventoryRowsChangeValue.ChoiceList[0].Value;
			
		EndIf;
		
	ElsIf InventoryRowsChangeAction = PredefinedValue("Enum.BulkRowChangeActions.AddFromDocument")
			Or InventoryRowsChangeAction = PredefinedValue("Enum.BulkRowChangeActions.AddImportedProductsFromDocument") Then
		
		TypeArray.Add(Type("DocumentRef.PurchaseOrder"));
		TypeArray.Add(Type("DocumentRef.SupplierInvoice"));
		TypeArray.Add(Type("DocumentRef.SupplierInvoiceForPayment"));
		
	ElsIf InventoryRowsChangeAction = PredefinedValue("Enum.BulkRowChangeActions.DistributeAmountByAmounts") Then
		
		CommonUseClientServer.SetFormItemProperty(Items, "InventoryRowsChangeValue", "Visible", False);
		
	EndIf;
	
	Items.InventoryRowsChangeValue.TypeRestriction = New TypeDescription(TypeArray);
	
EndProcedure

&AtServer
Procedure ShowHideEditPanel(ModifiesData = Undefined)
	Var MigrationState;
	
	GroupRowsChangeServer.ShowHideEditPanel(
		ThisObject,
		GroupRowsChangeItemsServer(),
		MigrationState,
		ModifiesData
	);
	
	CommonUseClientServer.SetFormItemProperty(Items, "SectionsGroup", "Enabled", Not Items.GroupInventoryRowsChange.Visible);
	
	TableBackupManagement(MigrationState, ModifiesData);
	
EndProcedure

&AtServer
Function GroupRowsChangeItemsServer()
	
	SetElements = New Structure;
	SetElements.Insert("TSName", "Inventory");
	SetElements.Insert("DocumentRef", Object.Ref);
	SetElements.Insert("EditPanel", Items.GroupInventoryRowsChange);
	SetElements.Insert("ActionGroup", Items.GroupInventoryChoiceAction);
	SetElements.Insert("ValueGroup", Items.GroupInventoryChoiceValue);
	SetElements.Insert("ExecuteGroup", Items.GroupInventoryExecuteAction);
	SetElements.Insert("ButtonExecuteAction", Items.InventoryExecuteAction);
	SetElements.Insert("ChangeRowsButton", Items.InventoryChangeRows);
	SetElements.Insert("ColumnMark", Items.InventoryMark);
	SetElements.Insert("ColumnLineNumber", Items.InventoryLineNumber);
	SetElements.Insert("Action", ThisForm.InventoryRowsChangeAction);
	SetElements.Insert("ActionItem", Items.InventoryRowsChangeAction);
	SetElements.Insert("Value", ThisForm.InventoryRowsChangeValue);
	SetElements.Insert("ValueItem", Items.InventoryRowsChangeValue);
	SetElements.Insert("ChangingObject", "");
	SetElements.Insert("ColumnChangingObject", Undefined);
	Return SetElements;
	
EndFunction

&AtServer
Procedure FillActionsList()
	
	ActionChoiceList = Items.InventoryRowsChangeAction.ChoiceList;
	
	ActionChoiceList.Clear();
	
	ExchangeWithBookkeepingConfigured = SmallBusinessReUse.ExchangeWithBookkeepingConfigured();
	If ExchangeWithBookkeepingConfigured Then
		
		ActionChoiceList.Add(Enums.BulkRowChangeActions.PickBatchDocuments,		NStr("en='Select batch documents';ru='Подобрать документы партий';vi='Chọn chứng từ lô hàng'"));
		
	EndIf;
	
	ActionChoiceList.Add(Enums.BulkRowChangeActions.AddFromDocument,				NStr("en='Add from document';ru='Добавить из документа';vi='Thêm từ chứng từ'"));
	ActionChoiceList.Add(Enums.BulkRowChangeActions.AddImportedProductsFromDocument, NStr("en='Add from document (import product and services)';ru='Добавить из документа (импортные товары)';vi='Thêm từ chứng từ (hàng nhập khẩu)'"));
	ActionChoiceList.Add(Enums.BulkRowChangeActions.PickCCDNumbers,					NStr("en='Add rows by CCD from supplier invoices';ru='Добавить строки по номеру ГТД из приходных накладных';vi='Thêm dòng theo số tờ khai hải quan từ hóa đơn đầu vào'"));
	ActionChoiceList.Add(Enums.BulkRowChangeActions.DistributeAmountByAmounts,			NStr("en='Clarify amount customs fee distibution';ru='Уточнить суммы распределения таможенного сбора';vi='Chỉ ra số tiền phân bổ chi phí hải quan'"));
	ActionChoiceList.Add(Enums.BulkRowChangeActions.DeleteRows, 						NStr("en='Delete rows';ru='Удалить строки';vi='Xóa dòng'"));
	
	If Object.Sections.Count() > 1 Then
		
		ActionChoiceList.Add(Enums.BulkRowChangeActions.SetSourceLocation,	NStr("en='Move rows in other section';ru='Перенести строки в другой раздел';vi='Chuyển các dòng sang phân hệ khác'"));
		
	EndIf;
	
EndProcedure

&AtServer
Procedure PickBatchDocuments(SectionID, Errors)
	
	SectionRow = Object.Sections.FindByID(SectionID);
	If SectionRow = Undefined Then
		
		ErrorText = NStr("en='Select CCD section to add products and services';ru='Укажите раздел ГТД, в который необходимо добавить товары';vi='Hãy chỉ ra phân hệ tờ khai hải quan cần thêm hàng hóa vào đó'");
		CommonUseClientServer.AddUserError(Errors, "Sections", ErrorText, "");
		
	EndIf;
	
	If Not Errors = Undefined Then
		
		Return;
		
	EndIf;
	
	RowArray = Object.Inventory.FindRows(New Structure("SectionNumber", SectionRow.LineNumber));
	InventoryTable = Object.Inventory.Unload(RowArray);
	
	If InventoryTable.Count() < 1 Then
		
		Return;
		
	EndIf;
	
	QueryText = 
	"SELECT
	|	InventoryTable.LineNumber AS LineNumber
	|	,InventoryTable.ProductsAndServices AS ProductsAndServices
	|	,InventoryTable.Characteristic AS Characteristic
	|	,InventoryTable.Batch AS Batch
	|	,InventoryTable.CountryOfOrigin AS CountryOfOrigin
	|INTO DataByDocuments
	|FROM &InventoryTable AS InventoryTable
	|;
	|
	|SELECT
	|	DataByDocuments.LineNumber AS LineNumber
	|	,DataByDocuments.ProductsAndServices AS ProductsAndServices
	|	,DataByDocuments.Characteristic AS Characteristic
	|	,DataByDocuments.Batch AS Batch
	|	,DataByDocuments.CountryOfOrigin AS CountryOfOrigin
	|	,MAX(DocumentTabularSection.Ref.Date) AS Period
	|INTO DataByPeriods
	|FROM DataByDocuments AS DataByDocuments
	|	JOIN Document.SupplierInvoice.Inventory AS DocumentTabularSection
	|	ON DataByDocuments.ProductsAndServices = DocumentTabularSection.ProductsAndServices
	|		AND DataByDocuments.Characteristic = DocumentTabularSection.Characteristic
	|		AND DataByDocuments.Batch = DocumentTabularSection.Batch
	|		AND DataByDocuments.CountryOfOrigin = DocumentTabularSection.CountryOfOrigin
	|		AND DocumentTabularSection.CCDNo = &CCDNo
	|GROUP BY
	|	DataByDocuments.LineNumber
	|	,DataByDocuments.ProductsAndServices
	|	,DataByDocuments.Characteristic
	|	,DataByDocuments.Batch
	|	,DataByDocuments.CountryOfOrigin
	|;
	|
	|SELECT
	|	DataByPeriods.LineNumber AS LineNumber
	|	,DataByPeriods.ProductsAndServices AS ProductsAndServices
	|	,DataByPeriods.Characteristic AS Characteristic
	|	,DataByPeriods.Batch AS Batch
	|	,DataByPeriods.CountryOfOrigin AS CountryOfOrigin
	|	,DocumentTabularSection.Ref AS DocumentBatch
	|FROM DataByPeriods AS DataByPeriods
	|	JOIN Document.SupplierInvoice.Inventory AS DocumentTabularSection
	|	ON DataByPeriods.ProductsAndServices = DocumentTabularSection.ProductsAndServices
	|		AND DataByPeriods.Characteristic = DocumentTabularSection.Characteristic
	|		AND DataByPeriods.Batch = DocumentTabularSection.Batch
	|		AND DataByPeriods.CountryOfOrigin = DocumentTabularSection.CountryOfOrigin
	|		AND DataByPeriods.Period = DocumentTabularSection.Ref.Date
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("InventoryTable", InventoryTable);
	Query.SetParameter("CCDNo", Object.CCDNo);
	BatchDocumentsTable = Query.Execute().Unload();
	
	For Each InventoryRow In RowArray Do
		
		FoundStrings = BatchDocumentsTable.FindRows(New Structure("LineNumber", InventoryRow.LineNumber));
		If FoundStrings.Count() > 0 Then
			
			FillPropertyValues(InventoryRow, FoundStrings[0], "DocumentBatch");
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure AddRowsToSectionFromDocument(SectionID, OnlyImported, Errors)
	
	If Not ValueIsFilled(InventoryRowsChangeValue) Then
		
		ErrorText = NStr("en='For filling need to choose document';ru='Для заполнения необходимо выбрать документ';vi='Cần chọn chứng từ để điền'");
		CommonUseClientServer.AddUserError(Errors, "InventoryRowsChangeValue", ErrorText, "");
		
	EndIf;
	
	SectionRow = Object.Sections.FindByID(SectionID);
	If SectionRow = Undefined Then
		
		ErrorText = NStr("en='Choose CCD section to add product and services';ru='Укажите раздел ГТД, в который необходимо добавить товары';vi='Hãy chỉ ra phân hệ tờ khai hải quan cần thêm hàng hóa vào đó'");
		CommonUseClientServer.AddUserError(Errors, "Sections", ErrorText, "");
		
	EndIf;
	
	If Not Errors = Undefined Then
		
		Return;
		
	EndIf;
	
	QueryTextPattern = 
	"SELECT
	|	DocumentTabularSection.ProductsAndServices AS ProductsAndServices
	|	,DocumentTabularSection.Characteristic AS Characteristic
	|	,&FieldNameBatch AS Batch
	|	,&FieldNameCountryOfOrigin AS CountryOfOrigin
	|	,DocumentTabularSection.Quantity AS Quantity
	|	,DocumentTabularSection.Amount AS Amount
	|	,DocumentTabularSection.VATAmount AS VATAmount
	|	,DocumentTabularSection.Ref.AmountIncludesVAT AS AmountIncludesVAT
	|	,DocumentTabularSection.Ref.DocumentCurrency AS DocumentCurrency
	|FROM
	|	&NameDocumentTable AS DocumentTabularSection
	|WHERE
	|	DocumentTabularSection.Ref = &Ref AND &OnlyImported";
	
	If TypeOf(InventoryRowsChangeValue) = Type("DocumentRef.PurchaseOrder") Then
		
		QueryTextPattern = StrReplace(QueryTextPattern, "&FieldNameBatch", "NULL");
		QueryTextPattern = StrReplace(QueryTextPattern, "&FieldNameCountryOfOrigin", "DocumentTabularSection.ProductsAndServices.CountryOfOrigin");
		QueryTextPattern = StrReplace(QueryTextPattern, "&NameDocumentTable", "Document.PurchaseOrder.Inventory");
		
		ConditionsDetails = ?(OnlyImported,
		"
		|	AND DocumentTabularSection.ProductsAndServices.CountryOfOrigin <> Value(Catalog.WorldCountries.EmptyRef)
		|	AND DocumentTabularSection.ProductsAndServices.CountryOfOrigin <> Value(Catalog.WorldCountries.RUSSIA)",
		"");
		QueryTextPattern = StrReplace(QueryTextPattern, " AND &OnlyImported", ConditionsDetails);
		
	ElsIf TypeOf(InventoryRowsChangeValue) = Type("DocumentRef.SupplierInvoice") Then
		
		QueryTextPattern = StrReplace(QueryTextPattern, "&FieldNameBatch", "DocumentTabularSection.Batch");
		QueryTextPattern = StrReplace(QueryTextPattern, "&FieldNameCountryOfOrigin", "DocumentTabularSection.CountryOfOrigin");
		QueryTextPattern = StrReplace(QueryTextPattern, "&NameDocumentTable", "Document.SupplierInvoice.Inventory");
		
		ConditionsDetails = ?(OnlyImported,
		"
		|	AND DocumentTabularSection.CountryOfOrigin <> Value(Catalog.WorldCountries.EmptyRef)
		|	AND DocumentTabularSection.CountryOfOrigin <> Value(Catalog.WorldCountries.RUSSIA)",
		"");
		QueryTextPattern = StrReplace(QueryTextPattern, " AND &OnlyImported", ConditionsDetails);
		
	ElsIf TypeOf(InventoryRowsChangeValue) = Type("DocumentRef.SupplierInvoiceForPayment") Then
		
		QueryTextPattern = StrReplace(QueryTextPattern, "&FieldNameBatch", "DocumentTabularSection.Batch");
		QueryTextPattern = StrReplace(QueryTextPattern, "&FieldNameCountryOfOrigin", "DocumentTabularSection.ProductsAndServices.CountryOfOrigin");
		QueryTextPattern = StrReplace(QueryTextPattern, "&NameDocumentTable", "Document.SupplierInvoiceForPayment.Inventory");
		
		ConditionsDetails = ?(OnlyImported,
		"
		|	AND DocumentTabularSection.ProductsAndServices.CountryOfOrigin <> Value(Catalog.WorldCountries.EmptyRef)
		|	AND DocumentTabularSection.ProductsAndServices.CountryOfOrigin <> Value(Catalog.WorldCountries.RUSSIA)",
		"");
		QueryTextPattern = StrReplace(QueryTextPattern, " AND &OnlyImported", ConditionsDetails);
		
	EndIf;
	
	Query = New Query(QueryTextPattern);
	Query.SetParameter("Ref", InventoryRowsChangeValue);
	Query.SetParameter("CCDNo", Object.CCDNo);
	Selection = Query.Execute().Select();
	
	TaxableByVAT = ?(InventoryRowsChangeValue.VATTaxation = Enums.VATTaxationTypes.TaxableByVAT, True, False);
	
	While Selection.Next() Do
		
		NewRow = Object.Inventory.Add();
		FillPropertyValues(NewRow, Selection, "ProductsAndServices, Characteristic, Batch, CountryOfOrigin, Quantity");
		
		NewRow.Check = True;
		NewRow.SectionNumber = SectionRow.LineNumber;
		
		InvoiceCost = ?(Selection.AmountIncludesVAT And TaxableByVAT, Selection.Amount - Selection.VATAmount, Selection.Amount);
		If Not (Selection.DocumentCurrency = Object.DocumentCurrency) Then
			
			InvoiceCost = WorkWithCurrencyRates.RecalculateToCurrency(InvoiceCost, Selection.DocumentCurrency, Object.DocumentCurrency, Object.Date);
		EndIf;
		
		NewRow.InvoiceCost = InvoiceCost;
		
		If TypeOf(InventoryRowsChangeValue) = Type("DocumentRef.SupplierInvoice") Then
			
			NewRow.DocumentBatch = InventoryRowsChangeValue;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure AddRowsToSectionFromDocumentsSupplierInvoice(SectionID, Errors)
	
	SectionRow = Object.Sections.FindByID(SectionID);
	If SectionRow = Undefined Then
		
		ErrorText = NStr("en='Choose CCD section to add product and services';ru='Укажите раздел ГТД, в который необходимо добавить товары';vi='Hãy chỉ ra phân hệ tờ khai hải quan cần thêm hàng hóa vào đó'");
		CommonUseClientServer.AddUserError(Errors, "Sections", ErrorText, "");
		
	EndIf;
	
	If Not ValueIsFilled(Object.CCDNo) Then
		
		ErrorText = NStr("en='Choose CCD number';ru='Укажите номер ГТД';vi='Hãy chỉ ra số tờ khai hải quan'");
		CommonUseClientServer.AddUserError(Errors, "Sections", ErrorText, "");
		
	EndIf;
	
	If Not Errors = Undefined Then
		
		Return;
		
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentTableInventory.Ref AS DocumentBatch,
	|	DocumentTableInventory.ProductsAndServices AS ProductsAndServices,
	|	DocumentTableInventory.Characteristic AS Characteristic,
	|	DocumentTableInventory.Batch AS Batch,
	|	DocumentTableInventory.CountryOfOrigin AS CountryOfOrigin,
	|	CASE
	|		WHEN DocumentTableInventory.MeasurementUnit REFS Catalog.UOMClassifier
	|			THEN DocumentTableInventory.Quantity
	|		ELSE DocumentTableInventory.Quantity * DocumentTableInventory.MeasurementUnit.Factor
	|	END AS Quantity,
	|	CASE
	|		WHEN DocumentTableInventory.Ref.AmountIncludesVAT
	|			THEN DocumentTableInventory.Amount - DocumentTableInventory.VATAmount
	|		ELSE DocumentTableInventory.Amount
	|	END AS AmountWithoutVAT,
	|	DocumentTableInventory.Ref.DocumentCurrency AS DocumentCurrency
	|INTO RowsInCurrentDocumentCurrency
	|FROM
	|	Document.SupplierInvoice.Inventory AS DocumentTableInventory
	|WHERE
	|	DocumentTableInventory.CCDNo = &CCDNo
	|	AND DocumentTableInventory.Ref.Posted = TRUE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SupplierInvoiceRows.ProductsAndServices AS ProductsAndServices,
	|	SupplierInvoiceRows.Characteristic AS Characteristic,
	|	SupplierInvoiceRows.Batch AS Batch,
	|	SupplierInvoiceRows.CountryOfOrigin AS CountryOfOrigin,
	|	SupplierInvoiceRows.DocumentBatch AS DocumentBatch,
	|	SUM(SupplierInvoiceRows.Quantity) AS Quantity,
	|	SUM(SupplierInvoiceRows.AmountWithoutVAT) AS InvoiceCost
	|FROM
	|	RowsInCurrentDocumentCurrency AS SupplierInvoiceRows
	|
	|GROUP BY
	|	SupplierInvoiceRows.ProductsAndServices,
	|	SupplierInvoiceRows.Characteristic,
	|	SupplierInvoiceRows.Batch,
	|	SupplierInvoiceRows.CountryOfOrigin,
	|	SupplierInvoiceRows.DocumentBatch";
	
	Query = New Query(QueryText);
	Query.SetParameter("CCDNo", 			Object.CCDNo);
	Query.SetParameter("DocumentDate", 		Object.Date);
	Query.SetParameter("DocumentCurrency", 	Object.DocumentCurrency);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		NewRow = Object.Inventory.Add();
		FillPropertyValues(NewRow, Selection, "ProductsAndServices, Characteristic, Batch, CountryOfOrigin, DocumentBatch, Quantity, InvoiceCost");
		
		If Not Object.DocumentCurrency = Selection.DocumentCurrency Then
			NewRow.InvoiceCost = WorkWithCurrencyRates.RecalculateToCurrency(Selection.InvoiceCost, Selection.DocumentCurrency, Object.DocumentCurrency, Object.Date);
		EndIf;
		
		NewRow.SectionNumber = SectionRow.LineNumber;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure SectionsOnActivateRow(Item)
	
	TabularSectionRow = Items.Sections.CurrentData;
	If TabularSectionRow = Undefined Then
		
		Return;
		
	EndIf;
	
	SectionNumber = Object.Sections.IndexOf(TabularSectionRow) + 1;
	
	Items.Inventory.RowFilter = New FixedStructure("SectionNumber", SectionNumber);
	
EndProcedure

#EndRegion

#Region LibrariesHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	//AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	//AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	//AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#EndRegion
