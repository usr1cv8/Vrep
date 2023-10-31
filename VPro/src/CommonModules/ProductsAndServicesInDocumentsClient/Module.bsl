
#Region ProgramInterface
// Обновляет заголовки групп реквизитов справочников Номенклатура и Категории номенклатуры
//
Procedure UpdateGroupsTitles(ObjectForm, GroupDescription = Undefined) Export
	
	If GroupDescription = Undefined Then
		
		UpdateHeaderAccountingInformation(ObjectForm);
		UpdateTitleAlcoholicProducts(ObjectForm);
		UpdateTitlePurchaseAndProduction(ObjectForm);
		UpdateTitleStorage(ObjectForm);
		UpdatePriceListTitle(ObjectForm);
		UpdateTitleVetys(ObjectForm);
		UpdateTitleTobacco(ObjectForm);
		UpdateHeaderShoes(ObjectForm);
		UpdateGISMTitle(ObjectForm);
		
		If TypeOf(ObjectForm.Object) = Type("CatalogRef.ProductsAndServices") Then
			UpdateHeaderSetKit(ObjectForm);
		EndIf;
	
	ElsIf GroupDescription = "AccountingInformation" Then
		UpdateHeaderAccountingInformation(ObjectForm);
	ElsIf GroupDescription = "SetKit" Then
		UpdateHeaderSetKit(ObjectForm);
	ElsIf GroupDescription = "AlcoholicProducts" Then
		UpdateTitleAlcoholicProducts(ObjectForm);
	ElsIf GroupDescription = "PurchaseAndProduction" Then
		UpdateTitlePurchaseAndProduction(ObjectForm);
	ElsIf GroupDescription = "Location" Then
		UpdateTitleStorage(ObjectForm);
	ElsIf GroupDescription = "PriceList" Then
		UpdatePriceListTitle(ObjectForm);
	ElsIf GroupDescription = "Vetis" Then
		UpdateTitleVetys(ObjectForm);
	ElsIf GroupDescription = "Tobacco" Then
		UpdateTitleTobacco(ObjectForm);
	ElsIf GroupDescription = "Shoes" Then
		UpdateHeaderShoes(ObjectForm);
	ElsIf GroupDescription = "GISM" Then
		UpdateGISMTitle(ObjectForm);
	EndIf;
	
EndProcedure

// Контролирует резерв в указанной строке табличной части
//
// Parameters:
//  TabularSectionRow - FormDataStructure - данные строки табличной части
//  RowAction - String - возможные действия:
//    * "OnChangeQuantityCheckReserve"
//    * "OnChangeReserveCheckCount"
//  Object - FormDataStructure - данные документа, в котором выполняется контроль
//  TSName - String - имя табличной части
//
Procedure ReserveValueControlInCurrentRow(TabularSectionRow, RowAction = "OnChangeQuantityCheckReserve", Object = Undefined, TSName = "Inventory") Export
	
	If TabularSectionRow = Undefined Then
		Return
	EndIf;
	
	If RowAction = "OnChangeQuantityCheckReserve" Then
		
		If Not TabularSectionRow.Property("Reserve") Then
			Return
		EndIf;
		
		TabularSectionRow.Reserve = ?(TabularSectionRow.Count < TabularSectionRow.Reserve, TabularSectionRow.Count, TabularSectionRow.Reserve);
	
	ElsIf RowAction = "CheckQuantityOnReserveChange" Then
		
		If Not TabularSectionRow.Property("Reserve") Or Object = Undefined Then
			Return
		EndIf;
		
		If TabularSectionRow.Reserve > TabularSectionRow.Count Then
			
			ClearMessages();
			
			MessageText = NStr("en='В строке №%1 табл. части значение в колонке ""В резерв"" не может превышать значения в колонке ""Количество"".';ru='В строке №%1 табл. части значение в колонке ""В резерв"" не может превышать значения в колонке ""Количество"".';vi='Tại dòng số %1 của phần bảng, giá trị tại cột ""Đang dự phòng"" không thể vượt quá giá trị tại cột ""Số lượng"".'");
			MessageText = StrTemplate(MessageText, TabularSectionRow.LineNumber);
			
			CommonUseClient.MessageToUser(
			MessageText,,
			StrTemplate("Object.%1[%2].Quantity", TSName, Format(TabularSectionRow.LineNumber - 1, "NG=")));
			
			TabularSectionRow.Reserve = TabularSectionRow.Count;
			
		EndIf;
		
	Else
		
		ExeptionText = StrTemplate(NStr("en='Передан недопустимый параметр ""ДействиеСтроки"" = ""%1"".';ru='Передан недопустимый параметр ""ДействиеСтроки"" = ""%1"".';vi='Đã truyền tham số không hợp lệ ""ДействиеСтроки"" = ""%1"".'"), RowAction);
		Raise ExeptionText;
		
	EndIf;
	
	
EndProcedure

// Создает новый документ и заполняет его товарами из корзины
//
// Parameters:
//  Form - ClientApplicationForm - форма, из которой оформляется документ
//  DocumentKind - String - вид заполняемого документа
//  ListData - Array - данные списка, заполненные в ПодготовитьДанныеСписка()
//
Procedure CheckoutDocumentWithGoodsFromCart(Form, DocumentKind, ListData = Undefined, Owner = Undefined, UID = Undefined, FromCart = False) Export
	
	FillingParameters = New Structure;
	If ListData = Undefined Then
		ProductsAndServicesLines = Form.Basket;
	Else
		ProductsAndServicesLines = ListData;
	EndIf;
	
	FillingParameters.Insert("PriceKind",  Form.FilterPriceKind);
	If ValueIsFilled(Form.FilterWarehouse) And Form.FilterBalances = 1 Then
		If DocumentKind = "CustomerOrder" Or DocumentKind = "JobOrder" Then
			FillingParameters.Insert("StructuralUnitReserve",  Form.FilterWarehouse);
		Else
			FillingParameters.Insert("StructuralUnit",  Form.FilterWarehouse);
		EndIf;
	EndIf;
	If ValueIsFilled(Form.VATTaxation) Then
		FillingParameters.Insert("VATTaxation",  Form.VATTaxation);
		FillingParameters.Insert("UsingVAT",  Form.UsingVAT);
	EndIf;
	If ValueIsFilled(Form.PickCurrency) Then
		FillingParameters.Insert("Currency",  Form.PickCurrency);
	EndIf;
	
	FillInDocument(FillingParameters, DocumentKind, ProductsAndServicesLines, Owner, UID, FromCart);
	
	If Form.FormName = "Catalog.ProductsAndServices.Form.FormCart" Then
		Form.TransferToDocument = True;
		Form.Close();
	ElsIf ListData = Undefined Then
		Form.Basket.Clear();
	EndIf;
	
EndProcedure

// Дополняет существующий документ товарами из корзины
//
// Parameters:
//  Form - ClientApplicationForm - форма, из которой оформляется документ
//  DocumentKind - String - вид заполняемого документа
//  ListData - Array - данные списка, заполненные в ПодготовитьДанныеСписка()
//
Function GetFillingStructure(Form, DocumentKind, ListData = Undefined) Export
	
	FillingParameters = New Structure;
	If ListData = Undefined Then
		ProductsAndServicesLines = Form.Basket;
	Else
		ProductsAndServicesLines = ListData;
	EndIf;
	
	FillingParameters.Insert("PriceKind",  Form.FilterPriceKind);
	If ValueIsFilled(Form.FilterWarehouse) Then
		FillingParameters.Insert("StructuralUnit",  Form.FilterWarehouse);
	EndIf;
	If ValueIsFilled(Form.VATTaxation) Then
		FillingParameters.Insert("VATTaxation",  Form.VATTaxation);
		FillingParameters.Insert("UsingVAT",  Form.UsingVAT);
	EndIf;
	If ValueIsFilled(Form.PickCurrency) Then
		FillingParameters.Insert("Currency",  Form.PickCurrency);
	EndIf;
	
	Return DocumentFillingStructure(FillingParameters, DocumentKind, ProductsAndServicesLines);
	
EndFunction

// Обработчик команд "СоздатьИзНоменклатуры" для обобщения вызовов быстрых кнопок Продать/Купить
//
// Parameters:
//  Form - ClientApplicationForm - форма, из которой вызывается команда
//  DocumentKind - String - вид документа, который создается из карточки номенклатуры.
//
Procedure CreateFromProductsAndServices(Form, DocumentKind) Export
	
	If Form = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(Form) <> Type("ClientApplicationForm") Then
		Return;
	EndIf;
	
	If Form.Modified Then
		Form.Write();
	EndIf; 
	
	If Form.FormName = "Catalog.ProductsAndServices.Form.ItemForm" Then
		PrepareItemData(
		Form.Object.Ref,
		DocumentKind);
	ElsIf Form.FormName = "Catalog.ProductsAndServices.Form.ListForm" Then
		TableName = Form.CurrentProductsAndServicesPage;
		PrepareListData(
		Form,
		Form.Items[TableName],
		DocumentKind);
	ElsIf Form.FormName = "DataProcessor.DocumentsByFilterCriterion.Form.DocumentList" Then
		PrepareItemData(
		Form.ProductsAndServices,
		DocumentKind);
	Else
		Raise StrTemplate(
		NStr("en='Не определено поведение при вызове из формы ""%1"".';ru='Не определено поведение при вызове из формы ""%1"".';vi='Chưa xác định thao tác khi gọi từ biểu mẫu ""%1"".'"),
		Form.FormName);
	EndIf;
	
EndProcedure

// Находит открытую форму по уникальному идентификатору
//
Function GetOpenFormByEid(UID) Export
	OpenWindows = GetWindows();
	For Each OpenedForm In OpenWindows Do
		If OpenedForm.Content.Count() And OpenedForm.Content[0].UUID = UID Then
			Return OpenedForm.Content[0]
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region InternalProceduresAndFunctions

Procedure UpdateHeaderAccountingInformation(ObjectForm)
	
	If Not ObjectForm.Items.AccountInformationGroup.Visible Then Return EndIf;
	
	TitleText = "Accounting information";
	TitleAddition = "";
	
	If TypeOf(ObjectForm.Object.Ref) = Type("CatalogRef.ProductsAndServicesCategories") Then
		ProductsAndServicesType = ObjectForm.Object.DefaultProductsAndServicesType;
	Else
		ProductsAndServicesType = ObjectForm.Object.ProductsAndServicesType;
	EndIf;
	
	ShowEvaluationMethod = True;
	
	If Not ProductsAndServicesType = PredefinedValue("Enum.ProductsAndServicesTypes.InventoryItem")
		And Not ProductsAndServicesType = PredefinedValue("Enum.ProductsAndServicesTypes.GiftCertificate")
		Then
		ShowEvaluationMethod = False;
	EndIf;
	
	If ValueIsFilled(ObjectForm.Object.BusinessActivity) Then
		TitleAddition = TitleAddition + String(ObjectForm.Object.BusinessActivity);
	EndIf;
	
	If ShowEvaluationMethod And ValueIsFilled(ObjectForm.Object.EstimationMethod) Then
		TitleAddition = TitleAddition + ?(ValueIsFilled(TitleAddition), ", ", "") +String(ObjectForm.Object.EstimationMethod);
	EndIf;
	
	If ValueIsFilled(ObjectForm.Object.VATRateKind) Then
		
		VATRate = ObjectForm.Items.VATRateKind.ChoiceList.FindByValue(ObjectForm.Object.VATRateKind);
		
		TitleAddition = TitleAddition + ?(ValueIsFilled(TitleAddition), ", ", "") + String(VATRate);
	EndIf;
	
	If ValueIsFilled(TitleAddition) Then
		TitleText = TitleText +" ("+TitleAddition+")";
	EndIf;
	
	ObjectForm.Items.AccountInformationGroup.Title = TitleText;
	
EndProcedure

Procedure UpdateHeaderSetKit(ObjectForm)
	
	If Not ObjectForm.Items.GroupSets.Visible Then Return EndIf;
	
	TitleText = "Set / kit";
	TitleAddition = "";
	
	If ObjectForm.Object.ThisIsSet Then
		TitleAddition = " (this set)";
	EndIf;
	
	TitleText = TitleText + TitleAddition;
	
	ObjectForm.Items.GroupSets.Title = TitleText;
	
EndProcedure

Procedure UpdateTitleAlcoholicProducts(ObjectForm)
	
	If Not ObjectForm.Items.GroupAlcoholicBeverages.Visible Then Return EndIf;
	
	TitleText = "Alcohol products";
	TitleAddition = "";
	
	If ValueIsFilled(ObjectForm.Object.AlcoholicProductsKind) Then
		TitleAddition = TitleAddition + String(ObjectForm.Object.AlcoholicProductsKind);
	EndIf;
	
	If TypeOf(ObjectForm.Object) = Type("CatalogRef.ProductsAndServices") And ValueIsFilled(ObjectForm.Object.Manufacturer) Then
		TitleAddition = TitleAddition + ?(ValueIsFilled(TitleAddition), ", ", "") +String(ObjectForm.Object.Manufacturer);
	EndIf;
	
	If ValueIsFilled(TitleAddition) Then
		TitleText = TitleText +" ("+TitleAddition+")";
	EndIf;
	
	ObjectForm.Items.GroupAlcoholicBeverages.Title = TitleText;
	
EndProcedure

Procedure UpdateTitlePurchaseAndProduction(ObjectForm)
	
	If Not ObjectForm.Items.GroupPurchaseProduction.Visible Then Return EndIf;
	
	TitleText = "Purchase AND production";
	TitleAddition = "";
	
	If ValueIsFilled(ObjectForm.Object.ReplenishmentMethod) Then
		TitleAddition = TitleAddition + String(ObjectForm.Object.ReplenishmentMethod);
	EndIf;
	
	If ValueIsFilled(TitleAddition) Then
		TitleText = TitleText +" ("+TitleAddition+")";
	EndIf;
	
	ObjectForm.Items.GroupPurchaseProduction.Title = TitleText;
	
EndProcedure

Procedure UpdateTitleStorage(ObjectForm)
	
	If Not ObjectForm.Items.GroupLocation.Visible Then Return EndIf;
	
	TitleText = "Location";
	TitleAddition = "";
	
	If ValueIsFilled(ObjectForm.Object.Warehouse) Then
		TitleAddition = TitleAddition + String(ObjectForm.Object.Warehouse);
	EndIf;
	
	If ValueIsFilled(ObjectForm.Object.Cell) Then
		TitleAddition = TitleAddition + ?(ValueIsFilled(TitleAddition), ", ", "") +String(ObjectForm.Object.Cell);
	EndIf;
	
	If ValueIsFilled(TitleAddition) Then
		TitleText = TitleText +" ("+TitleAddition+")";
	EndIf;
	
	ObjectForm.Items.GroupLocation.Title = TitleText;
	
EndProcedure

Procedure UpdatePriceListTitle(ObjectForm)
	
	If Not ObjectForm.Items.GroupPriceList.Visible Then Return EndIf;
	
	TitleText = "PRICE-sheet";
	TitleAddition = "";
	
	If ValueIsFilled(ObjectForm.Object.PriceGroup) Then
		TitleAddition = TitleAddition + String(ObjectForm.Object.PriceGroup);
	EndIf;
	
	If ValueIsFilled(TitleAddition) Then
		TitleText = TitleText +" ("+TitleAddition+")";
	EndIf;
	
	ObjectForm.Items.GroupPriceList.Title = TitleText;
	
EndProcedure

Procedure UpdateTitleVetys(ObjectForm)
	
	If Not ObjectForm.Items.GroupVETYS.Visible Then Return EndIf;
	
	TitleText = "Controlled products (VETIS)";
	TitleAddition = "";
	
	If ObjectForm.Object.ControlledVETISProducts Then
		TitleAddition = " (this products VETIS)";
	EndIf;
	
	TitleText = TitleText + TitleAddition;
	
	ObjectForm.Items.GroupVETYS.Title = TitleText;
	
EndProcedure

Procedure UpdateGISMTitle(ObjectForm)
	
	If Not ObjectForm.Items.GroupMarking.Visible Then Return EndIf;
	
	TitleText = "Marking (GISM)";
	TitleAddition = "";
	
	If ObjectForm.Object.MarkingKind = PredefinedValue("Enum.MarkingKinds.NotMarked") Then
		TitleAddition = " (NOT marked)";
	ElsIf ObjectForm.Object.MarkingKind = PredefinedValue("Enum.MarkingKinds.ControlIdentificationMark") Then
		TitleAddition = " (Control (identification) sign)";
	ElsIf ObjectForm.Object.MarkingKind = PredefinedValue("Enum.MarkingKinds.ProductsToMark") Then
		TitleAddition = " (To products)";
	EndIf;
	
	TitleText = TitleText + TitleAddition;
	
	ObjectForm.Items.GroupMarking.Title = TitleText;
	
EndProcedure

Procedure UpdateTitleTobacco(ObjectForm)
	
	If Not ObjectForm.Items.GroupTobaccoProducts.Visible Then Return EndIf;
	
	TitleText = "Tobacco products";
	TitleAddition = "";
	
	If ObjectForm.Object.TobaccoProducts Then
		TitleAddition = " (this tobacco products)";
	EndIf;
	
	TitleText = TitleText + TitleAddition;
	
	ObjectForm.Items.GroupTobaccoProducts.Title = TitleText;
	
EndProcedure

Procedure UpdateHeaderShoes(ObjectForm)
	
	If Not ObjectForm.Items.ISMPGroup.Visible Then Return EndIf;
	
	TitleText = "Shoe products";
	TitleAddition = "";
	
	If ObjectForm.Object.ShoeProducts Then
		TitleAddition = " (this shoe products)";
	EndIf;
	
	TitleText = TitleText + TitleAddition;
	
	ObjectForm.Items.ISMPGroup.Title = TitleText;
	
EndProcedure

Procedure FillInDocument(FillStructure, DocumentKind, FillingData, Owner = Undefined, UID = Undefined, FromCart = False)

	AllowedProductsAndServicesTypesArray = New Array;
	SetsAllowed = False;
	If DocumentKind = "CustomerOrder" Then
		FillStructure.Insert("OperationKind",  PredefinedValue("Enum.OperationKindsCustomerOrder.OrderForSale"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.InventoryItem"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.Service"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.Work"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.GiftCertificate"));
		TabularSectionName = "Inventory";
		SetsAllowed = True;
	ElsIf DocumentKind = "InvoiceForPayment" Then
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.InventoryItem"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.Service"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.Work"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.GiftCertificate"));
		TabularSectionName = "Inventory";
		SetsAllowed = True;
	ElsIf DocumentKind = "JobOrder" Then
		FillStructure.Insert("OperationKind",  PredefinedValue("Enum.OperationKindsCustomerOrder.JobOrder"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.InventoryItem"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.Service"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.Work"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.WorkKind"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.GiftCertificate"));
		TabularSectionName = "Inventory";
		SetsAllowed = True;
	ElsIf DocumentKind = "AcceptanceCertificate" Then
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.Service"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.Work"));
		TabularSectionName = "WorksAndServices";
		SetsAllowed = True;
	ElsIf DocumentKind = "CustomerInvoice" Then
		FillStructure.Insert("OperationKind",  PredefinedValue("Enum.OperationKindsCustomerInvoice.SaleToCustomer"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.InventoryItem"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.Service"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.GiftCertificate"));
		TabularSectionName = "Inventory";
		SetsAllowed = True;
	ElsIf DocumentKind = "ReceiptCR" Then
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.InventoryItem"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.Service"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.GiftCertificate"));
		TabularSectionName = "Inventory";
		SetsAllowed = True;
	ElsIf DocumentKind = "PurchaseOrder" Then
		FillStructure.Insert("OperationKind",  PredefinedValue("Enum.OperationKindsPurchaseOrder.OrderForPurchase"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.InventoryItem"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.Service"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.GiftCertificate"));
		TabularSectionName = "Inventory";
		SetsAllowed = False;
	ElsIf DocumentKind = "SupplierInvoice" Then
		FillStructure.Insert("OperationKind",  PredefinedValue("Enum.OperationKindsSupplierInvoice.ReceiptFromVendor"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.InventoryItem"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.Service"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.GiftCertificate"));
		TabularSectionName = "Inventory";
		SetsAllowed = False;
	EndIf;
	
	EventsAboutErrorsArray = GetFillParameters(FillStructure, FillingData, AllowedProductsAndServicesTypesArray, SetsAllowed, TabularSectionName, DocumentKind, FromCart);
	
	FormParameters = New Structure;
	FormParameters.Insert("FillingValues", FillStructure);
	
	If DocumentKind = "JobOrder" Then
		OpenForm("Document.CustomerOrder.Form.JobOrderForm", FormParameters, Owner, UID);
	Else
		OpenForm(StrTemplate("Document.%1.ObjectForm", DocumentKind), FormParameters, Owner, UID);
	EndIf;
	
	For Each ErrorSTR In EventsAboutErrorsArray Do
		CommonUseClient.MessageToUser(ErrorSTR);
	EndDo;
	
EndProcedure

Function DocumentFillingStructure(FillStructure, DocumentKind, FillingData)

	AllowedProductsAndServicesTypesArray = New Array;
	SetsAllowed = False;
	If DocumentKind = "CustomerOrder" Then
		FillStructure.Insert("OperationKind",  PredefinedValue("Enum.OperationKindsCustomerOrder.OrderForSale"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.InventoryItem"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.Service"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.Work"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.GiftCertificate"));
		TabularSectionName = "Inventory";
		SetsAllowed = True;
	ElsIf DocumentKind = "InvoiceForPayment" Then
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.InventoryItem"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.Service"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.Work"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.GiftCertificate"));
		TabularSectionName = "Inventory";
		SetsAllowed = True;
	ElsIf DocumentKind = "JobOrder" Then
		FillStructure.Insert("OperationKind",  PredefinedValue("Enum.OperationKindsCustomerOrder.JobOrder"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.InventoryItem"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.Service"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.Work"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.WorkKind"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.GiftCertificate"));
		TabularSectionName = "Inventory";
		SetsAllowed = True;
	ElsIf DocumentKind = "AcceptanceCertificate" Then
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.Service"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.Work"));
		TabularSectionName = "WorksAndServices";
		SetsAllowed = True;
	ElsIf DocumentKind = "CustomerInvoice" Then
		FillStructure.Insert("OperationKind",  PredefinedValue("Enum.OperationKindsCustomerInvoice.SaleToCustomer"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.InventoryItem"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.Service"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.GiftCertificate"));
		TabularSectionName = "Inventory";
		SetsAllowed = True;
	ElsIf DocumentKind = "ReceiptCR" Then
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.InventoryItem"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.Service"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.GiftCertificate"));
		TabularSectionName = "Inventory";
		SetsAllowed = True;
	ElsIf DocumentKind = "PurchaseOrder" Then
		FillStructure.Insert("OperationKind",  PredefinedValue("Enum.OperationKindsPurchaseOrder.OrderForPurchase"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.InventoryItem"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.Service"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.GiftCertificate"));
		TabularSectionName = "Inventory";
		SetsAllowed = False;
	ElsIf DocumentKind = "SupplierInvoice" Then
		FillStructure.Insert("OperationKind",  PredefinedValue("Enum.OperationKindsSupplierInvoice.ReceiptFromVendor"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.InventoryItem"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.Service"));
		AllowedProductsAndServicesTypesArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.GiftCertificate"));
		TabularSectionName = "Inventory";
		SetsAllowed = False;
	EndIf;
	
	EventsAboutErrorsArray = GetFillParameters(FillStructure, FillingData, AllowedProductsAndServicesTypesArray, SetsAllowed, TabularSectionName, DocumentKind, True);
	
	FillingAndErrorStructure = New Structure("FillStructure, EventsAboutErrorsArray",FillStructure,EventsAboutErrorsArray);
	
	Return FillingAndErrorStructure;
	
EndFunction

Function GetFillParameters(FillStructure, FillingData, AllowedProductsAndServicesTypesArray, SetsAllowed, TabularSectionName, DocumentKind, FromCart = False)
	
	EventsAboutErrorsArray = New Array;
	
	If Not ValueIsFilled(TabularSectionName) Then
		Return EventsAboutErrorsArray;
	EndIf;
	
	ProductsArray 	= New Array;
	ServicesArray		= New Array;
	ArrayOfWorks		= New Array;
	WorkKind		= Undefined;
	
	For Each PPBaskets In FillingData Do
		
		If AllowedProductsAndServicesTypesArray.Find(PPBaskets.ProductsAndServicesType) = Undefined Then
			
			MessageText = NStr("en='%1: тип номенклатуры <%2> нельзя использовать в документе';ru='%1: тип номенклатуры <%2> нельзя использовать в документе';vi='%1: kiểu mặt hàng <%2> không nên sử dụng trong chứng từ'");
			EventsAboutErrorsArray.Add(StringFunctionsClientServer.SubstituteParametersInString(
				MessageText,
				PPBaskets.ProductsAndServices,
				PPBaskets.ProductsAndServicesType
				));
			Continue;
			
		EndIf;
		
		// Наборы
		If PPBaskets.Property("ThisIsSet") And PPBaskets.ThisIsSet And Not SetsAllowed  Then
			
			MessageText = NStr("en='%1: наборы нельзя использовать в документе';ru='%1: наборы нельзя использовать в документе';vi='%1: không sử dụng bộ sản phẩm trong chứng từ'");
			EventsAboutErrorsArray.Add(StringFunctionsClientServer.SubstituteParametersInString(
				MessageText,
				PPBaskets.ProductsAndServices
				));
			Continue;
			
		EndIf;
		// Конец Наборы
		
		StructureGoods = New Structure("ProductsAndServices", PPBaskets.ProductsAndServices);
		If PPBaskets.Property("CHARACTERISTIC") Then
			StructureGoods.Insert("CHARACTERISTIC", PPBaskets.CHARACTERISTIC);
		EndIf;
		
		If PPBaskets.Property("Batch") Then
			StructureGoods.Insert("Batch", PPBaskets.Batch);
		EndIf;
		
		StructureGoods.Insert("Quantity", PPBaskets.Count);
		StructureGoods.Insert("MeasurementUnit", PPBaskets.MeasurementUnit);
		
		If FromCart Then
			StructureGoods.Insert("Price", PPBaskets.Price);
			StructureGoods.Insert("Amount", PPBaskets.Amount);
		EndIf;
		
		If PPBaskets.ProductsAndServicesType = PredefinedValue("Enum.ProductsAndServicesTypes.InventoryItem") Then
			StructureGoods.Insert("ProductsAndServicesTypeInventory", True);
		ElsIf PPBaskets.ProductsAndServicesType = PredefinedValue("Enum.ProductsAndServicesTypes.GiftCertificate") Then
			StructureGoods.Insert("ProductsAndServicesTypeInventory", True);
		ElsIf PPBaskets.ProductsAndServicesType = PredefinedValue("Enum.ProductsAndServicesTypes.Service") Then
			StructureGoods.Insert("ProductsAndServicesTypeService", True);
			StructureGoods.Insert("ConnectionKey", 0);
		ElsIf PPBaskets.ProductsAndServicesType = PredefinedValue("Enum.ProductsAndServicesTypes.Work") Then
			StructureGoods.Insert("ConnectionKey", 0);
		EndIf;
		
		// Наборы
		If PPBaskets.Property("ThisIsSet") Then
			StructureGoods.Insert("ThisIsSet", PPBaskets.ThisIsSet);
		EndIf;
		// Конец Наборы
		
		If PPBaskets.Property("CountryOfOrigin") Then
			StructureGoods.Insert("CountryOfOrigin", PPBaskets.CountryOfOrigin);
		EndIf;
		
		If PPBaskets.Property("StructuralUnit") Then
			
			If DocumentKind = "CustomerOrder" Or DocumentKind = "JobOrder" Then
				StructureGoods.Insert("StructuralUnitReserve", PPBaskets.StructuralUnit);
			Else
				StructureGoods.Insert("StructuralUnit", PPBaskets.StructuralUnit);
			EndIf
		
		EndIf;
		
		If PPBaskets.Property("Cell") Then
			StructureGoods.Insert("Cell", PPBaskets.Cell);
		EndIf;
		
		If DocumentKind="JobOrder" Then
			If PPBaskets.ProductsAndServicesType = PredefinedValue("Enum.ProductsAndServicesTypes.WorkKind") Then
				WorkKind = PPBaskets.ProductsAndServices;
			ElsIf PPBaskets.ProductsAndServicesType = PredefinedValue("Enum.ProductsAndServicesTypes.Service")
				Or PPBaskets.ProductsAndServicesType = PredefinedValue("Enum.ProductsAndServicesTypes.Work")
				Then
				StructureGoods.ConnectionKey = ArrayOfWorks.Count() + 1;
				ArrayOfWorks.Add(StructureGoods);
			Else
				ProductsArray.Add(StructureGoods);
			EndIf;
		ElsIf DocumentKind="SupplierInvoice" Then
			If PPBaskets.ProductsAndServicesType = PredefinedValue("Enum.ProductsAndServicesTypes.Service") Then
				ServicesArray.Add(StructureGoods);
			Else
				ProductsArray.Add(StructureGoods);
			EndIf;
		Else
			ProductsArray.Add(StructureGoods);
		EndIf; 
		
	EndDo;
	
	FillStructure.Insert(TabularSectionName, ProductsArray);
	
	If FromCart Then
		FillStructure.Insert("FromCart", FromCart);
	EndIf;
	
	//Для Заказ-Наряда
	FillStructure.Insert("WorkKind", WorkKind);
	FillStructure.Insert("Works", ArrayOfWorks);
	
	//Для Приходной накладной
	FillStructure.Insert("Expenses", ServicesArray);
	
	Return EventsAboutErrorsArray;
	
EndFunction

// Подготавливает данные номенклатуры и вызывает ЗаполнитьДокумент()
//
// Parameters:
//  ProductsAndServices - CatalogRef.ProductsAndServices - ссылка на элемент справочника "Номенклатура"
//  DocumentKind - String - вид документа, для которого подготавливаются данные
//
Procedure PrepareItemData(ProductsAndServices, DocumentKind)
	
	ProductsAndServicesData = ProductsAndServicesInDocumentsServerCall.ProductsAndServicesData(ProductsAndServices);
	
	RowArray = New Array;
	RowArray.Add(ProductsAndServicesData);
	
	FillingParameters = New Structure;
	AddSupplierField(FillingParameters, ProductsAndServicesData, DocumentKind);
	
	FillInDocument(FillingParameters, DocumentKind, RowArray);
	
EndProcedure

Procedure AddSupplierField(FillingParameters, ProductsAndServicesData, DocumentKind)
	
	If Not ValueIsFilled(ProductsAndServicesData.Supplier) Then
		Return;
	EndIf;
	
	If DocumentKind = "PurchaseOrder"
		Or DocumentKind = "SupplierInvoice" Then
		FillingParameters.Insert("Counterparty", ProductsAndServicesData.Supplier);
	EndIf;
	
EndProcedure

// Подготавливает данные списка номенклатуры и вызывает ОформитьДокументСТоварамиИзКорзины()
//
// Parameters:
//  FormTable - FormTable - таблица формы, из которой извлекаются данные для заполнения документа
//  DocumentKind - String - вид документа, для заполнения которого подготавливаются данные
//
Procedure PrepareListData(Form, FormTable, DocumentKind)
	
	ListData = New Array;
	For Each CurRow In FormTable.SelectedRows Do
		RowData = FormTable.RowData(CurRow);
		If RowData = Undefined Then
			Continue;
		EndIf;
		
		ListFields = New Structure;
		ListFields.Insert("ProductsAndServices", RowData.ProductsAndServices);
		ListFields.Insert("Quantity", 1);
		ListFields.Insert("Price", RowData.Price);
		ListFields.Insert("MeasurementUnit", RowData.MeasurementUnit);
		ListFields.Insert("ProductsAndServicesType", RowData.ProductsAndServicesType);
		If RowData.Property("VATRate") Then
			ListFields.Insert("VATRate", RowData.VATRate);
		Else
			ListFields.Insert("VATRate", ProductsAndServicesInDocumentsServer.ProductsAndServicesRate(RowData.ProductsAndServices));
		EndIf;
		ListFields.Insert("CountryOfOrigin", RowData.CountryOfOrigin);
		ListFields.Insert("ThisIsSet", RowData.ThisIsSet);
		ListFields.Insert("Warehouse", RowData.Warehouse);
		ListFields.Insert("Cell", RowData.Cell);
		If RowData.Property("CHARACTERISTIC") Then
			ListFields.Insert("CHARACTERISTIC", RowData.CHARACTERISTIC);
		Else
			ListFields.Insert("CHARACTERISTIC", ProductsAndServicesInDocumentsServer.DefaultProductsAndServicesValues(RowData.ProductsAndServices));
		EndIf;
		
		ListData.Add(ListFields);
	EndDo; 
	
	CheckoutDocumentWithGoodsFromCart(Form, DocumentKind, ListData);
	
EndProcedure

#EndRegion
