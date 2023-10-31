#Region ServiceApplicationInterface

Function GetXDTODataObject(Data, ObjectCount) Export
	
	TransferedObject = Undefined;
	
	If TypeOf(Data) = Type("CatalogObject.Counterparties")
		OR TypeOf(Data) = Type("CatalogRef.Counterparties") Then
		TransferedObject = SerializationCounterparty(Data, ObjectCount);
	ElsIf TypeOf(Data) = Type("CatalogObject.ProductsAndServices")
		OR TypeOf(Data) = Type("CatalogRef.ProductsAndServices") Then
		TransferedObject = SerializationGoods(Data, ObjectCount);
	ElsIf TypeOf(Data) = Type("CatalogObject.StructuralUnits")
		OR TypeOf(Data) = Type("CatalogRef.StructuralUnits") Then
		TransferedObject = SerializationStructuralUnits(Data, ObjectCount);
	ElsIf TypeOf(Data) = Type("CatalogObject.CashRegisters")
		OR TypeOf(Data) = Type("CatalogRef.CashRegisters") Then
		TransferedObject = SerializationCashCR(Data, ObjectCount);
	ElsIf TypeOf(Data) = Type("CatalogRef.Specifications") Or
		TypeOf(Data) = Type("CatalogObject.Specifications") Then
		TransferedObject = SerializationSpecification(Data, ObjectCount);
	ElsIf TypeOf(Data) = Type("CatalogObject.CashFlowItems")
		OR TypeOf(Data) = Type("CatalogRef.CashFlowItems") Then
		TransferedObject = SerializationCashFlowItems(Data, ObjectCount);
	ElsIf TypeOf(Data) = Type("DocumentObject.CustomerOrder")
		OR TypeOf(Data) = Type("DocumentRef.CustomerOrder") Then
		TransferedObject = SerializationCustomerOrder(Data, ObjectCount);
	ElsIf TypeOf(Data) = Type("DocumentObject.CustomerInvoice")
		OR TypeOf(Data) = Type("DocumentRef.CustomerInvoice") Then
		TransferedObject = SerializationCustomerInvoice(Data, ObjectCount);
	ElsIf TypeOf(Data) = Type("DocumentObject.SupplierInvoice")
		OR TypeOf(Data) = Type("DocumentRef.SupplierInvoice") Then
		TransferedObject = SerializationSupplierInvoice(Data, ObjectCount);
	ElsIf TypeOf(Data) = Type("DocumentObject.InventoryAssembly")
		OR TypeOf(Data) = Type("DocumentRef.InventoryAssembly") Then
		TransferedObject = SerializationInventoryAssembly(Data, ObjectCount);
	ElsIf TypeOf(Data) = Type("DocumentObject.CashReceipt")
		OR TypeOf(Data) = Type("DocumentRef.CashReceipt") Then
		TransferedObject = SerializationCashReceipt(Data, ObjectCount);
	ElsIf TypeOf(Data) = Type("DocumentObject.CashPayment")
		OR TypeOf(Data) = Type("DocumentRef.CashPayment") Then
		TransferedObject = SerializationCashPayment(Data, ObjectCount);
	ElsIf TypeOf(Data) = Type("DocumentObject.ReceiptCR")
		OR TypeOf(Data) = Type("DocumentRef.ReceiptCR") Then
		TransferedObject = SerializationReceiptCR(Data, ObjectCount);
	ElsIf TypeOf(Data) = Type("DocumentObject.ReceiptCRReturn")
		OR TypeOf(Data) = Type("DocumentRef.ReceiptCRReturn") Then
		TransferedObject = SerializationReceiptCRReturn(Data, ObjectCount);
	ElsIf TypeOf(Data) = Type("DocumentObject.RetailReport")
		OR TypeOf(Data) = Type("DocumentRef.RetailReport") Then
		TransferedObject = SerializationRetailReport(Data, ObjectCount);
	ElsIf TypeOf(Data) = Type("EnumRef.ProductsAndServicesTypes") Then
		TransferedObject = SerializationGoodsTypes(Data, ObjectCount);
	ElsIf TypeOf(Data) = Type("InformationRegisterRecordSet.ProductsAndServicesPrices") Then
		TransferedObject = SerializationGoodsPrices(Data, ObjectCount);
	ElsIf TypeOf(Data) = Type("ObjectDeletion") Then
		TransferedObject = SerializationObjectDeletion(Data, ObjectCount);
	EndIf;
	
	ObjectCount = ObjectCount + 1;
	Return TransferedObject;
	
EndFunction // GetXDTODataObject()

#EndRegion

#Region Catalogs

Function SerializationCounterparty(Data, ObjectCount)
	
	TransferedObject = CreateXDTOObject("CatContractors");
	TransferedObject.Id = String(Data.Ref.UUID());
	TransferedObject.Name = Data.Description;
	TransferedObject.DeletionMark = Data.DeletionMark;
	If ValueIsFilled(Data.Parent) Then
		TransferedObject.Group = GetXDTODataObject(Data.Parent, ObjectCount);
	EndIf;
	If Data.IsFolder Then
		TransferedObject.ThisIsGroup = True;
		Return TransferedObject;
	Else
		TransferedObject.ThisIsGroup = False;
	EndIf;
	
	CounterpartyPostalAddress = "";
	CounterpartyLegalAddress = "";
	CounterpartyActualAddress = "";
	TransferedObject.Tel = "";
	TransferedObject.Fax = "";
	TransferedObject.Email = "";
	TransferedObject.Web = "";
	TransferedObject.Adress = "";
	
	For Each CurRow In Data.ContactInformation Do
		If CurRow.Type = Enums.ContactInformationTypes.Phone Then
			TransferedObject.Tel = CurRow.Presentation;
		ElsIf CurRow.Type = Enums.ContactInformationTypes.Fax Then
			TransferedObject.Fax = CurRow.Presentation;
		ElsIf CurRow.Type = Enums.ContactInformationTypes.Address
			AND CurRow.Kind = Catalogs.ContactInformationKinds.CounterpartyPostalAddress Then
			CounterpartyPostalAddress = CurRow.Presentation;
		ElsIf CurRow.Type = Enums.ContactInformationTypes.Address
			AND CurRow.Kind = Catalogs.ContactInformationKinds.CounterpartyLegalAddress Then
			CounterpartyLegalAddress = CurRow.Presentation;
		ElsIf CurRow.Type = Enums.ContactInformationTypes.Address
			AND CurRow.Kind = Catalogs.ContactInformationKinds.CounterpartyActualAddress Then
			CounterpartyActualAddress = CurRow.Presentation;
		ElsIf CurRow.Type = Enums.ContactInformationTypes.EmailAddress Then
			TransferedObject.Email = CurRow.Presentation;
		ElsIf CurRow.Type = Enums.ContactInformationTypes.WebPage Then
			TransferedObject.Web = CurRow.Presentation;
		EndIf;
	EndDo;
	
	If NOT IsBlankString(CounterpartyActualAddress) Then
		TransferedObject.Adress = CounterpartyActualAddress;
	ElsIf NOT IsBlankString(CounterpartyPostalAddress) Then
		TransferedObject.Adress = CounterpartyPostalAddress;
	ElsIf NOT IsBlankString(CounterpartyLegalAddress) Then
		TransferedObject.Adress = CounterpartyLegalAddress;
	EndIf;
	
	TransferedObject.AdditionalInfo = Data.Comment;
	TransferedObject.ContactName = CommonUse.GetAttributeValue(Data.ContactPerson, "Description");
	
	Return TransferedObject;
	
EndFunction

Function SerializationGoods(Data, ObjectCount)
	
	TransferedObject = CreateXDTOObject("CatItems");
	TransferedObject.Id = String(Data.Ref.UUID());
	TransferedObject.Name = Data.Description;
	TransferedObject.DeletionMark = Data.DeletionMark;
	If ValueIsFilled(Data.Parent) Then
		TransferedObject.Group = GetXDTODataObject(Data.Parent, ObjectCount);
	EndIf;
	If Data.IsFolder Then
		TransferedObject.ThisIsGroup = True;
		Return TransferedObject;
	Else
		TransferedObject.ThisIsGroup = False;
	EndIf;
	TransferedObject.Article = Data.SKU;
	If ValueIsFilled(Data.Vendor) Then
		TransferedObject.Supplier = GetXDTODataObject(Data.Vendor, ObjectCount);
	EndIf;
	TransferedObject.TypeItem = GetXDTODataObject(Data.ProductsAndServicesType, ObjectCount);
	TransferedObject.ImageAviable = ValueIsFilled(Data.Ref.PictureFile);
	
	If ValueIsFilled(Data.DeleteSpecification) Then
		TransferedObject.Specification = GetXDTODataObject(Data.DeleteSpecification, ObjectCount);
	EndIf; 
	
	TransferedObject.BarCode = InformationRegisters.ProductsAndServicesBarcodes.GetBarcodeByProduct(Data.Ref);
	
	Return TransferedObject;
	
EndFunction

Function SerializationStructuralUnits(Data, ObjectCount)
	
	TransferedObject = CreateXDTOObject("CatStructuralUnit");
	TransferedObject.Id = String(Data.Ref.UUID());
	TransferedObject.Name = Data.Description;
	TransferedObject.DeletionMark = Data.DeletionMark;
	TransferedObject.Predefined = Data.Predefined;
	If ValueIsFilled(Data.Parent) Then
		TransferedObject.Group = GetXDTODataObject(Data.Parent, ObjectCount);
	EndIf;
	
	If Data.Predefined Then
		If Data.Ref = Catalogs.StructuralUnits.MainDepartment Then
			TransferedObject.PredefinedCode = "000000001";
		ElsIf Data.Ref = Catalogs.StructuralUnits.MainWarehouse Then
			TransferedObject.PredefinedCode = "000000002";
		EndIf;
	EndIf;
	
	Return TransferedObject;
	
EndFunction

Function SerializationCashCR(Data, ObjectCount)
	
	TransferedObject = CreateXDTOObject("CatCashDesk");
	TransferedObject.Id = String(Data.Ref.UUID());
	TransferedObject.Name = Data.Description;
	TransferedObject.DeletionMark = Data.DeletionMark;
	TransferedObject.RetailStructuralUnit = GetXDTODataObject(Data.StructuralUnit, ObjectCount);;
	
	Return TransferedObject;
	
EndFunction

Function SerializationSpecification(Data, ObjectCount)
	
	TransferedObject = CreateXDTOObject("CatSpecifications");
	TransferedObject.Id = String(Data.Ref.UUID());
	TransferedObject.Name = Data.Description;
	TransferedObject.DeletionMark = Data.DeletionMark;
	TransferedObject.Owner = String(Data.Owner.Ref.UUID()); 
	
	TypeOfAddStrings = TransferedObject.Properties().Get("Content").Type;
	AddStrings = XDTOFactory.Create(TypeOfAddStrings);
	
	For Each Row In Data.Content Do
		
		TypeOfAddString = AddStrings.Properties().Get("Item").Type;
		AddString = XDTOFactory.Create(TypeOfAddString);
		
		If ValueIsFilled(Row.ProductsAndServices) Then
			AddString.Nomenclature = String(Row.ProductsAndServices.UUID()); 
		EndIf;
		
		AddString.Quantity = Row.Quantity;
		
		AddStrings.Item.Add(AddString);
		
	EndDo;
	
	TransferedObject.Content = AddStrings;
	
	
	Return TransferedObject;
	
EndFunction

Function SerializationCashFlowItems(Data, ObjectCount)
	
	TransferedObject = CreateXDTOObject("CashFlowItems");
	TransferedObject.Id = String(Data.Ref.UUID());
	TransferedObject.Name = Data.Description;
	TransferedObject.DeletionMark = Data.DeletionMark;
	TransferedObject.Predefined = Data.Predefined;
	
	If ValueIsFilled(Data.Parent) Then
		TransferedObject.Group = GetXDTODataObject(Data.Parent, ObjectCount);
	EndIf;
	If Data.IsFolder Then
		TransferedObject.ThisIsGroup = True;
		Return TransferedObject;
	Else
		TransferedObject.ThisIsGroup = False;
	EndIf;
	
	If Data.Predefined Then
		If Data.Ref = Catalogs.CashFlowItems.PaymentFromCustomers Then
			TransferedObject.PredefinedCode = "000000001";
		ElsIf Data.Ref = Catalogs.CashFlowItems.PaymentToVendor Then
			TransferedObject.PredefinedCode = "000000002";
		ElsIf Data.Ref = Catalogs.CashFlowItems.Other Then
			TransferedObject.PredefinedCode = "000000003";
		EndIf;
	EndIf;
	
	Return TransferedObject;
	
EndFunction

#EndRegion

#Region Documents

Function SerializationCustomerOrder(Data, ObjectCount)
	
	TransferedObject = CreateXDTOObject("DocOrders");
	
	ReadOnly = ExchangeMobileApplicationCommon.ChangesToTabularSectionAreAvailable(Data, "Inventory");
	TransferedObject.ReadOnly = ReadOnly;
	TransferedObject.Id = String(Data.Ref.UUID());
	TransferedObject.DeletionMark = Data.DeletionMark;
	TransferedObject.Posted = Data.Posted;
	TransferedObject.Name = Data.Number;
	TransferedObject.Date = Data.Date;
	TransferedObject.Comment = Data.Comment;
	If ValueIsFilled(Data.Counterparty) Then
		TransferedObject.Buyer = GetXDTODataObject(Data.Counterparty, ObjectCount);
	EndIf;
	TypeOfAddStrings = TransferedObject.Properties().Get("Items").Type;
	AddStrings = XDTOFactory.Create(TypeOfAddStrings);
	
	NeedToRecalculateSum = Data.DocumentCurrency <> Constants.NationalCurrency.Get();
	TotalDiscount = 0;
	
	For Each Row In Data.Inventory Do
		TypeOfAddString = AddStrings.Properties().Get("Item").Type;
		AddString = XDTOFactory.Create(TypeOfAddString);
		If ValueIsFilled(Row.ProductsAndServices) Then
			AddString.Nomenclature = GetXDTODataObject(Row.ProductsAndServices, ObjectCount);
		EndIf;
		CurrentDiscount = (Row.Price * (Row.DiscountMarkupPercent/100)) * Row.Quantity;
		If NeedToRecalculateSum Then
			AddString.Price = SmallBusinessServer.RecalculateFromCurrencyToCurrency(
				Row.Price,
				Data.ExchangeRate,
				1,
				Data.Multiplicity,
				1
				);
			AddString.Total = SmallBusinessServer.RecalculateFromCurrencyToCurrency(
				Row.Amount,
				Data.ExchangeRate,
				1,
				Data.Multiplicity,
				1
				);
			AddString.Discount = SmallBusinessServer.RecalculateFromCurrencyToCurrency(
				CurrentDiscount,
				Data.ExchangeRate,
				1,
				Data.Multiplicity,
				1
				);
		Else
			AddString.Price = Row.Price;
			AddString.Total = Row.Amount;
			AddString.Discount = CurrentDiscount;  
		EndIf;
		AddString.Quantity = Row.Quantity;
		AddStrings.Item.Add(AddString);
		
		TotalDiscount = TotalDiscount + CurrentDiscount;
	EndDo;
	
	TransferedObject.Items = AddStrings;
	
	Query = New Query(
		"SELECT
		|	CASE
		|		WHEN ISNULL(CustoumerOrdersBalanceAndTurnovers.QuantityReceipt, 0) <> 0
		|				AND ISNULL(CustoumerOrdersBalanceAndTurnovers.QuantityExpense, 0) <> 0
		|				AND ISNULL(CustoumerOrdersBalanceAndTurnovers.QuantityClosingBalance, 0) = 0
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS Shipped,
		|	CASE
		|		WHEN ISNULL(OrdersPaymentTurnovers.AmountTurnover, 0) <= ISNULL(OrdersPaymentTurnovers.PaymentAmountTurnover, 0) + ISNULL(OrdersPaymentTurnovers.AdvanceAmountTurnover, 0)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS Paid,
		|	InvoiceOrder.Ref
		|FROM
		|	Document.CustomerOrder AS InvoiceOrder
		|		LEFT JOIN AccumulationRegister.CustomerOrders.BalanceAndTurnovers(, , Авто, , ) AS CustoumerOrdersBalanceAndTurnovers
		|		ON InvoiceOrder.Ref = CustoumerOrdersBalanceAndTurnovers.CustomerOrder
		|		LEFT JOIN AccumulationRegister.InvoicesAndOrdersPayment.Turnovers AS OrdersPaymentTurnovers
		|		ON InvoiceOrder.Ref = OrdersPaymentTurnovers.InvoiceForPayment
		|WHERE
		|	InvoiceOrder.Ref = &Ref"
	);
	Query.SetParameter("Ref", Data.Ref);
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		TransferedObject.Shipped = Selection.Shipped;
		TransferedObject.Paid = Selection.Paid;
	EndIf;
	
	If NeedToRecalculateSum Then
		TransferedObject.Total = SmallBusinessServer.RecalculateFromCurrencyToCurrency(
			Data.DocumentAmount,
			Data.ExchangeRate,
			1,
			Data.Multiplicity,
			1
			);
		TransferedObject.Discount = SmallBusinessServer.RecalculateFromCurrencyToCurrency(
			TotalDiscount,
			Data.ExchangeRate,
			1,
			Data.Multiplicity,
			1
			);
	Else
		TransferedObject.Total = Data.DocumentAmount;
		TransferedObject.Discount = TotalDiscount;
	EndIf;
	
	Return TransferedObject;
	
EndFunction

Function SerializationCustomerInvoice(Data, ObjectCount)
	
	TransferedObject = CreateXDTOObject("DocInvoice");
	ReadOnly = ExchangeMobileApplicationCommon.ChangesToTabularSectionAreAvailable(Data, "Inventory");
	TransferedObject.ReadOnly = ReadOnly;
	TransferedObject.Id = String(Data.Ref.UUID());
	TransferedObject.DeletionMark = Data.DeletionMark;
	TransferedObject.Posted = Data.Posted;
	TransferedObject.Name = Data.Number;
	TransferedObject.Date = Data.Date;
	TransferedObject.Comment = Data.Comment;
	Try
		If ValueIsFilled(Data.Order) Then
			If TypeOf(Data.Order) = Type("DocumentRef.CustomerOrder") Then
				TransferedObject.Order = GetXDTODataObject(Data.Order.GetObject(), ObjectCount);
			EndIf;
		ElsIf Data.Inventory.Count() > 0 
			AND TypeOf(Data.Order) = Type("DocumentRef.CustomerOrder") 
			AND ValueIsFilled(Data.Inventory[0].Order)
			AND ValueIsFilled(Data.Inventory[0].Total) = Data.DocumentAmount Then
			TransferedObject.Order = GetXDTODataObject(Data.Inventory[0].Order.GetObject(), ObjectCount);
		EndIf;
	Except
	EndTry;
	If ValueIsFilled(Data.Counterparty) Then
		TransferedObject.Buyer = GetXDTODataObject(Data.Counterparty, ObjectCount);
	EndIf;
	TypeOfAddStrings = TransferedObject.Properties().Get("Items").Type;
	AddStrings = XDTOFactory.Create(TypeOfAddStrings);
	
	NeedToRecalculateSum = Data.DocumentCurrency <> Constants.NationalCurrency.Get();
	TotalDiscount = 0;
	
	For Each Row In Data.Inventory Do
		TypeOfAddString = AddStrings.Properties().Get("Item").Type;
		AddString = XDTOFactory.Create(TypeOfAddString);
		If ValueIsFilled(Row.ProductsAndServices) Then
			AddString.Nomenclature = GetXDTODataObject(Row.ProductsAndServices, ObjectCount);
		EndIf;
		
		CurrentDiscount = (Row.Price * (Row.DiscountMarkupPercent/100)) * Row.Quantity;
		
		If NeedToRecalculateSum Then
			AddString.Price = SmallBusinessServer.RecalculateFromCurrencyToCurrency(
				Row.Price,
				Data.ExchangeRate,
				1,
				Data.Multiplicity,
				1
				);
			AddString.Total = SmallBusinessServer.RecalculateFromCurrencyToCurrency(
				Row.Amount,
				Data.ExchangeRate,
				1,
				Data.Multiplicity,
				1
				);
			AddString.Discount = SmallBusinessServer.RecalculateFromCurrencyToCurrency(
				CurrentDiscount,
				Data.ExchangeRate,
				1,
				Data.Multiplicity,
				1
				);
		Else
			AddString.Price = Row.Price;
			AddString.Total = Row.Amount;
			AddString.Discount = CurrentDiscount;
			
			TotalDiscount = TotalDiscount + CurrentDiscount;
		EndIf;
		AddString.Quantity = Row.Quantity;
		AddStrings.Item.Add(AddString);
	EndDo;
	
	TransferedObject.Items = AddStrings;
	
	If NeedToRecalculateSum Then
		TransferedObject.Total = SmallBusinessServer.RecalculateFromCurrencyToCurrency(
			Data.DocumentAmount,
			Data.ExchangeRate,
			1,
			Data.Multiplicity,
			1
			);
		TransferedObject.Discount = SmallBusinessServer.RecalculateFromCurrencyToCurrency(
			TotalDiscount,
			Data.ExchangeRate,
			1,
			Data.Multiplicity,
			1
			);
	Else
		TransferedObject.Total = Data.DocumentAmount;
		TransferedObject.Discount = TotalDiscount;
	EndIf;
	
	Return TransferedObject;
	
EndFunction

Function SerializationSupplierInvoice(Data, ObjectCount)
	
	TransferedObject = CreateXDTOObject("DocPurshareInvoice");
	ReadOnly = ExchangeMobileApplicationCommon.ChangesToTabularSectionAreAvailable(Data, "Inventory");
	TransferedObject.ReadOnly = ReadOnly;
	TransferedObject.Id = String(Data.Ref.UUID());
	TransferedObject.DeletionMark = Data.DeletionMark;
	TransferedObject.Posted = Data.Posted;
	TransferedObject.Name = Data.Number;
	TransferedObject.Date = Data.Date;
	TransferedObject.Comment = Data.Comment;
	If ValueIsFilled(Data.Counterparty) Then
		TransferedObject.Supplier = GetXDTODataObject(Data.Counterparty, ObjectCount);
	EndIf;
	TypeOfAddStrings = TransferedObject.Properties().Get("Items").Type;
	AddStrings = XDTOFactory.Create(TypeOfAddStrings);
	
	NeedToRecalculateSum = Data.DocumentCurrency <> Constants.NationalCurrency.Get();
	
	For Each Row In Data.Inventory Do
		TypeOfAddString = AddStrings.Properties().Get("Item").Type;
		AddString = XDTOFactory.Create(TypeOfAddString);
		If ValueIsFilled(Row.ProductsAndServices) Then
			AddString.Nomenclature = GetXDTODataObject(Row.ProductsAndServices, ObjectCount);
		EndIf;
		If NeedToRecalculateSum Then
			AddString.Price = SmallBusinessServer.RecalculateFromCurrencyToCurrency(
				Row.Price,
				Data.ExchangeRate,
				1,
				Data.Multiplicity,
				1
				);
			AddString.Total = SmallBusinessServer.RecalculateFromCurrencyToCurrency(
				Row.Amount,
				Data.ExchangeRate,
				1,
				Data.Multiplicity,
				1
				);
		Else
			AddString.Price = Row.Price;
			AddString.Total = Row.Amount;
		EndIf;
		AddString.Quantity = Row.Quantity;
		AddStrings.Item.Add(AddString);
	EndDo;
	
	For Each Row In Data.Expenses Do
		TypeOfAddString = AddStrings.Properties().Get("Item").Type;
		AddString = XDTOFactory.Create(TypeOfAddString);
		If ValueIsFilled(Row.ProductsAndServices) Then
			AddString.Nomenclature = GetXDTODataObject(Row.ProductsAndServices, ObjectCount);
		EndIf;
		If NeedToRecalculateSum Then
			AddString.Price = SmallBusinessServer.RecalculateFromCurrencyToCurrency(
				Row.Price,
				Data.ExchangeRate,
				1,
				Data.Multiplicity,
				1
				);
			AddString.Total = SmallBusinessServer.RecalculateFromCurrencyToCurrency(
				Row.Amount,
				Data.ExchangeRate,
				1,
				Data.Multiplicity,
				1
				);
		Else
			AddString.Price = Row.Price;
			AddString.Total = Row.Amount;
		EndIf;
		AddString.Quantity = Row.Quantity;
		AddStrings.Item.Add(AddString);
	EndDo;
	
	TransferedObject.Items = AddStrings;
	
	If NeedToRecalculateSum Then
		TransferedObject.Total = SmallBusinessServer.RecalculateFromCurrencyToCurrency(
		Data.DocumentAmount,
		Data.ExchangeRate,
		1,
		Data.Multiplicity,
		1
		);
	Else
		TransferedObject.Total = Data.DocumentAmount;
	EndIf;
	
	Return TransferedObject;
	
EndFunction

Function SerializationInventoryAssembly(Data, ObjectCount)
	
	TransferedObject = CreateXDTOObject("DocProduction");
	ReadOnlyProduction = ExchangeMobileApplicationCommon.ChangesToTabularSectionAreAvailable(Data, "Products");
	ReadOnlyInventory = ExchangeMobileApplicationCommon.ChangesToTabularSectionAreAvailable(Data, "Inventory");
	TransferedObject.ReadOnly = ReadOnlyProduction OR ReadOnlyInventory;
	TransferedObject.Id = String(Data.Ref.UUID());
	TransferedObject.DeletionMark = Data.DeletionMark;
	TransferedObject.Posted = Data.Posted;
	TransferedObject.Name = Data.Number;
	TransferedObject.Date = Data.Date;
	TransferedObject.Comment = Data.Comment;
	
	TypeOfAddStrings = TransferedObject.Properties().Get("Products").Type;
	AddStrings = XDTOFactory.Create(TypeOfAddStrings);
	For Each Row In Data.Products Do
		TypeOfAddString = AddStrings.Properties().Get("Item").Type;
		AddString = XDTOFactory.Create(TypeOfAddString);
		If ValueIsFilled(Row.ProductsAndServices) Then
			AddString.Nomenclature = GetXDTODataObject(Row.ProductsAndServices, ObjectCount);
		EndIf;
		AddString.Quantity = Row.Quantity;
		AddStrings.Item.Add(AddString);
	EndDo;
	TransferedObject.Products = AddStrings;
	
	TypeOfAddStrings = TransferedObject.Properties().Get("Materials").Type;
	AddStrings = XDTOFactory.Create(TypeOfAddStrings);
	For Each Row In Data.Inventory Do
		TypeOfAddString = AddStrings.Properties().Get("Item").Type;
		AddString = XDTOFactory.Create(TypeOfAddString);
		If ValueIsFilled(Row.ProductsAndServices) Then
			AddString.Nomenclature = GetXDTODataObject(Row.ProductsAndServices, ObjectCount);
		EndIf;
		AddString.Quantity = Row.Quantity;
		AddStrings.Item.Add(AddString);
	EndDo;
	TransferedObject.Materials = AddStrings;
	
	Return TransferedObject;
	
EndFunction

Function SerializationCashReceipt(Data, ObjectCount)
	
	TransferedObject = CreateXDTOObject("DocIncomingPayment");
	TransferedObject.Id = String(Data.Ref.UUID());
	TransferedObject.DeletionMark = Data.DeletionMark;
	TransferedObject.Posted = Data.Posted;
	TransferedObject.Name = Data.Number;
	TransferedObject.Date = Data.Date;
	Try
		If ValueIsFilled(Data.BasisDocument) Then
			If TypeOf(Data.BasisDocument) = Type("DocumentRef.CustomerInvoice") Then
				TransferedObject.Invoice = GetXDTODataObject(Data.BasisDocument.GetObject(), ObjectCount);
			ElsIf TypeOf(Data.BasisDocument) = Type("DocumentRef.CustomerOrder") And 
				Data.BasisDocument.OperationKind = Enums.OperationKindsCustomerOrder.OrderForSale Then
				TransferedObject.Order = GetXDTODataObject(Data.BasisDocument.GetObject(), ObjectCount);
			Else
				TransferedObject.ReadOnly = True;
			EndIf;
		EndIf;
		If Data.PaymentDetails.Count() > 0 Then
			If ValueIsFilled(Data.PaymentDetails[0].Order)
				AND Data.PaymentDetails[0].Order = Type("DocumentRef.CustomerOrder")
				AND Data.PaymentDetails[0].PaymentAmount = Data.DocumentAmount Then
				TransferedObject.Order = GetXDTODataObject(Data.PaymentDetails[0].Order.GetObject(), ObjectCount);
			EndIf;
			If ValueIsFilled(Data.PaymentDetails[0].Document)
				AND Data.PaymentDetails[0].Document = Type("DocumentRef.CustomerInvoice")
				AND Data.PaymentDetails[0].PaymentAmount = Data.DocumentAmount Then
				TransferedObject.Invoice = GetXDTODataObject(Data.PaymentDetails[0].Document.GetObject(), ObjectCount);
			EndIf;
		EndIf;
	Except
	EndTry;
	If ValueIsFilled(Data.Counterparty) Then
		TransferedObject.Contractor = GetXDTODataObject(Data.Counterparty.GetObject(), ObjectCount);
	EndIf;
	If ValueIsFilled(Data.Item) Then
		TransferedObject.CashFlowItem = GetXDTODataObject(Data.Item.GetObject(), ObjectCount);
	EndIf;
	TransferedObject.Comment = Data.Comment;
	TransferedObject.Total = Data.DocumentAmount;
	
	Return TransferedObject;
	
EndFunction

Function SerializationCashPayment(Data, ObjectCount)
	
	TransferedObject = CreateXDTOObject("DocOutgoingPayment");
	TransferedObject.Id = String(Data.Ref.UUID());
	TransferedObject.DeletionMark = Data.DeletionMark;
	TransferedObject.Posted = Data.Posted;
	TransferedObject.Name = Data.Number;
	TransferedObject.Date = Data.Date;
	Try
		If ValueIsFilled(Data.BasisDocument) Then
			If TypeOf(Data.BasisDocument) = Type("DocumentRef.SupplierInvoice") Then
				TransferedObject.PurshareInvoice = GetXDTODataObject(Data.BasisDocument.GetObject(), ObjectCount);
			Else
				TransferedObject.ReadOnly = True;
			EndIf;
		EndIf;
		If Data.PaymentDetails.Count() > 0 Then
			If ValueIsFilled(Data.PaymentDetails[0].Document)
				AND Data.PaymentDetails[0].Document = Type("DocumentRef.SupplierInvoice")
				AND Data.PaymentDetails[0].PaymentAmount = Data.DocumentAmount Then
				TransferedObject.PurshareInvoice = GetXDTODataObject(Data.PaymentDetails[0].Document.GetObject(), ObjectCount);
			EndIf;
		EndIf;
	Except
	EndTry;
	If ValueIsFilled(Data.Counterparty) Then
		TransferedObject.Contractor = GetXDTODataObject(Data.Counterparty.GetObject(), ObjectCount);
	EndIf;
	If ValueIsFilled(Data.Item) Then
		TransferedObject.CashFlowItem = GetXDTODataObject(Data.Item.GetObject(), ObjectCount);
	EndIf;
	TransferedObject.Comment = Data.Comment;
	TransferedObject.Total = Data.DocumentAmount;
	
	Return TransferedObject;
	
EndFunction

Function SerializationReceiptCR(Data, ObjectCount)
	
	TransferedObject = CreateXDTOObject("DocCashReceipt");
	ReadOnly = ExchangeMobileApplicationCommon.ChangesToTabularSectionAreAvailable(Data, "Inventory");
	TransferedObject.ReadOnly = ReadOnly;
	TransferedObject.Id = String(Data.Ref.UUID());
	TransferedObject.DeletionMark = Data.DeletionMark;
	TransferedObject.Posted = Data.Posted;
	TransferedObject.Name = Data.Number;
	TransferedObject.Date = Data.Date;
	TransferedObject.Comment = Data.Comment;
	TransferedObject.CheckNumber = Data.ReceiptCRNumber;
	TransferedObject.Printed = Data.ReceiptCRNumber <> 0;
	
	If ValueIsFilled(Data.CashCR) Then
		TransferedObject.CashDesk = GetXDTODataObject(Data.CashCR, ObjectCount);
	EndIf;
	
	If ValueIsFilled(Data.StructuralUnit) Then
		TransferedObject.StructuralUnit = GetXDTODataObject(Data.StructuralUnit, ObjectCount);
	EndIf;
	
	If ValueIsFilled(Data.CashCRSession) Then
		TransferedObject.RetailSalesReport = GetXDTODataObject(Data.CashCRSession, ObjectCount);
	EndIf;
	
	TypeOfAddStrings = TransferedObject.Properties().Get("Items").Type;
	AddStrings = XDTOFactory.Create(TypeOfAddStrings);
	
	For Each Row In Data.Inventory Do
		TypeOfAddString = AddStrings.Properties().Get("Item").Type;
		AddString = XDTOFactory.Create(TypeOfAddString);
		If ValueIsFilled(Row.ProductsAndServices) Then
			AddString.Nomenclature = GetXDTODataObject(Row.ProductsAndServices, ObjectCount);
		EndIf;
		AddString.Price = Row.Price;
		AddString.Total = Row.Amount;
		AddString.Quantity = Row.Quantity;
		AddStrings.Item.Add(AddString);
	EndDo;
	
	TransferedObject.Items = AddStrings;
	TransferedObject.Total = Data.DocumentAmount;
	TransferedObject.InCashTotal = Data.CashReceived;
	
	Return TransferedObject;
	
EndFunction

Function SerializationReceiptCRReturn(Data, ObjectCount)
	
	TransferedObject = CreateXDTOObject("DocCashReceiptReturn");
	ReadOnly = ExchangeMobileApplicationCommon.ChangesToTabularSectionAreAvailable(Data, "Inventory");
	TransferedObject.ReadOnly = ReadOnly;
	TransferedObject.Id = String(Data.Ref.UUID());
	TransferedObject.DeletionMark = Data.DeletionMark;
	TransferedObject.Posted = Data.Posted;
	TransferedObject.Name = Data.Number;
	TransferedObject.Date = Data.Date;
	TransferedObject.Comment = Data.Comment;
	TransferedObject.CheckNumber = Data.ReceiptCRNumber;
	TransferedObject.Printed = Data.ReceiptCRNumber <> 0;
	
	If ValueIsFilled(Data.CashCR) Then
		TransferedObject.CashDesk = GetXDTODataObject(Data.CashCR, ObjectCount);
	EndIf;
	
	If ValueIsFilled(Data.StructuralUnit) Then
		TransferedObject.StructuralUnit = GetXDTODataObject(Data.StructuralUnit, ObjectCount);
	EndIf;
	
	If ValueIsFilled(Data.ReceiptCR) Then
		TransferedObject.CashReceipt = GetXDTODataObject(Data.ReceiptCR, ObjectCount);
	EndIf;
	
	If ValueIsFilled(Data.CashCRSession) Then
		TransferedObject.RetailSalesReport = GetXDTODataObject(Data.CashCRSession, ObjectCount);
	EndIf;
	
	TypeOfAddStrings = TransferedObject.Properties().Get("Items").Type;
	AddStrings = XDTOFactory.Create(TypeOfAddStrings);
	
	For Each Row In Data.Inventory Do
		TypeOfAddString = AddStrings.Properties().Get("Item").Type;
		AddString = XDTOFactory.Create(TypeOfAddString);
		If ValueIsFilled(Row.ProductsAndServices) Then
			AddString.Nomenclature = GetXDTODataObject(Row.ProductsAndServices, ObjectCount);
		EndIf;
		AddString.Price = Row.Price;
		AddString.Total = Row.Amount;
		AddString.Quantity = Row.Quantity;
		AddStrings.Item.Add(AddString);
	EndDo;
	
	TransferedObject.Items = AddStrings;
	TransferedObject.Total = Data.DocumentAmount;
	
	Return TransferedObject;
	
EndFunction

Function SerializationRetailReport(Data, ObjectCount)
	
	TransferedObject = CreateXDTOObject("DocRetailSalesReport");
	ReadOnly = ExchangeMobileApplicationCommon.ChangesToTabularSectionAreAvailable(Data, "Inventory");
	TransferedObject.ReadOnly = ReadOnly;
	TransferedObject.Id = String(Data.Ref.UUID());
	TransferedObject.DeletionMark = Data.DeletionMark;
	TransferedObject.Posted = Data.Posted;
	TransferedObject.Name = Data.Number;
	TransferedObject.Date = Data.Date;
	TransferedObject.Comment = Data.Comment;
	TransferedObject.DateBegin = Data.CashCRSessionStart;
	TransferedObject.DateEnd = Data.CashCRSessionEnd;
	
	If Data.CashCRSessionStatus = Enums.CashCRSessionStatuses.IsOpen Then
		TransferedObject.Status = "Open";
	Else
		TransferedObject.Status = "Closed";
	EndIf;
	
	If ValueIsFilled(Data.CashCR) Then
		TransferedObject.CashDesk = GetXDTODataObject(Data.CashCR, ObjectCount);
	EndIf;
	
	If ValueIsFilled(Data.StructuralUnit) Then
		TransferedObject.StructuralUnit = GetXDTODataObject(Data.StructuralUnit, ObjectCount);
	EndIf;
	
	TypeOfAddStrings = TransferedObject.Properties().Get("Items").Type;
	AddStrings = XDTOFactory.Create(TypeOfAddStrings);
	
	For Each Row In Data.Inventory Do
		TypeOfAddString = AddStrings.Properties().Get("Item").Type;
		AddString = XDTOFactory.Create(TypeOfAddString);
		If ValueIsFilled(Row.ProductsAndServices) Then
			AddString.Nomenclature = GetXDTODataObject(Row.ProductsAndServices, ObjectCount);
		EndIf;
		AddString.Price = Row.Price;
		AddString.Total = Row.Amount;
		AddString.Quantity = Row.Quantity;
		AddStrings.Item.Add(AddString);
	EndDo;
	
	TransferedObject.Items = AddStrings;
	TransferedObject.Total = Data.DocumentAmount;
	
	Return TransferedObject;
	
EndFunction

#EndRegion

#Region InformationRegisters

Function SerializationGoodsTypes(Data, ObjectCount)
	
	If Data = Enums.ProductsAndServicesTypes.InventoryItem Then
		TransferedObject = "Product";
	Else
		TransferedObject = "Service";
	EndIf;
	
	Return TransferedObject;
	
EndFunction

Function SerializationGoodsPrices(Data, ObjectCount)
	
	If Data.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	TransferedObject = CreateXDTOObject("Prices");
	UnloadingRegister = Data.Unload();
	
	If ValueIsFilled(UnloadingRegister[0].ProductsAndServices) Then
		TransferedObject.Nomenclature = GetXDTODataObject(UnloadingRegister[0].ProductsAndServices, ObjectCount);
	Else
		Return Undefined;
	EndIf;
	TransferedObject.Date = UnloadingRegister[0].Period;
	TransferedObject.Price = UnloadingRegister[0].Price;
	
	Return TransferedObject;
	
EndFunction

#EndRegion

#Region OtherObjects

Function SerializationObjectDeletion(Data, ObjectCount)
	
	TransferedObject = CreateXDTOObject("ObjectDeletion");
	TransferedObject.Id = String(Data.Ref.UUID());
	
	If TypeOf(Data.Ref) = Type("CatalogRef.Counterparties") Then
		TransferedObject.Type = "CatContractors";
	ElsIf TypeOf(Data.Ref) = Type("CatalogRef.ProductsAndServices") Then
		TransferedObject.Type = "CatItems";
	ElsIf TypeOf(Data.Ref) = Type("CatalogRef.StructuralUnits") Then
		TransferedObject.Type = "CatStructuralUnit";
	ElsIf TypeOf(Data.Ref) = Type("CatalogRef.CashFlowItems") Then
		TransferedObject.Type = "CashFlowItems";
	ElsIf TypeOf(Data.Ref) = Type("DocumentRef.CustomerOrder") Then
		TransferedObject.Type = "DocOrders";
	ElsIf TypeOf(Data.Ref) = Type("DocumentRef.SupplierInvoice") Then
		TransferedObject.Type = "DocPurshareInvoice";
	ElsIf TypeOf(Data.Ref) = Type("DocumentRef.CustomerInvoice") Then
		TransferedObject.Type = "DocInvoice";
	ElsIf TypeOf(Data.Ref) = Type("DocumentRef.CashPayment") Then
		TransferedObject.Type = "DocOutgoingPayment";
	ElsIf TypeOf(Data.Ref) = Type("DocumentRef.CashReceipt") Then
		TransferedObject.Type = "DocIncomingPayment";
	ElsIf TypeOf(Data.Ref) = Type("DocumentRef.InventoryAssembly") Then
		TransferedObject.Type = "DocProduction";
	ElsIf TypeOf(Data.Ref) = Type("DocumentRef.ReceiptCR") Then
		TransferedObject.Type = "DocCashReceipt";
	ElsIf TypeOf(Data.Ref) = Type("DocumentRef.ReceiptCRReturn") Then
		TransferedObject.Type = "DocCashReceiptReturn";
	ElsIf TypeOf(Data.Ref) = Type("DocumentRef.RetailReport") Then
		TransferedObject.Type = "DocRetailSalesReport";
	EndIf;
	
	Return TransferedObject;
	
EndFunction

Function SerializationCompanyInfo(ObjectCount)
	
	TransferedObject = CreateXDTOObject("Company");
	
	User = Users.CurrentUser();
	
	MainCompany = SmallBusinessReUse.GetValueByDefaultUser(
	User,
	"MainCompany"
	);
	Company = ?(ValueIsFilled(MainCompany), MainCompany, Catalogs.Companies.CompanyByDefault());
	
	TransferedObject.name = Company.Description;
	
	ObjectCount = ObjectCount + 1;
	
	Return TransferedObject;
	
EndFunction

Function SerializationTaxSettings(ObjectCount)
	
	TransferedObject = CreateXDTOObject("TaxSettings");
	
	User = Users.CurrentUser();
	
	MainCompany = SmallBusinessReUse.GetValueByDefaultUser(
	User,
	"MainCompany"
	);
	Company = ?(ValueIsFilled(MainCompany), MainCompany, Catalogs.Companies.CompanyByDefault());
	
	TransferedObject.IsLLC = IsLLC(Company);
	
	TransferedObject.IsEmployer = False;
	TransferedObject.IsFilingTaxReporting = False;
	TransferedObject.IsPayerUSN = False;
	TransferedObject.IsPayerENVD = False;
	TransferedObject.IsPayerShoppingTax = False;
	TransferedObject.IsRetailSaleOfAlcohol = False;
	
	ObjectCount = ObjectCount + 1;
	
	Return TransferedObject;	
	
EndFunction

Procedure SerializationInventoryRemainsAndAddInXDTOObject(MessageWriter, XMLWriter, ReturnableList, ExchangeNode, QueueMessageNumber, ObjectCount) Export
	
	Query = New Query(
		"SELECT
		|	InventoryRemains.ProductsAndServices,
		|	InventoryRemains.QuantityBalance,
		|	InventoryRemains.AmountBalance
		|FROM
		|	AccumulationRegister.Inventory.Balance
		|AS
		|	InventoryRemains WHERE InventoryRemains.CustomerOrder
		|	= VALUE(Документ.CustomerOrder.EmptyRef) AND InventoryRemains.QuantityBalance > 0"
	);
	
	Result = Query.Execute();
	
	SelectionRemains = Result.Select();
	
	TransferedObject = CreateXDTOObject("Remains");
	
	While SelectionRemains.Next() Do
		
		ObjectCount = ObjectCount + 1;
		If ObjectCount >= NumberOfObjectsInPackage() Then
			
			ReturnableList.objects.Add(TransferedObject);
			
			XDTOFactory.WriteXML(XMLWriter, ReturnableList);
			MessageWriter.EndWrite();
			
			ExchangeMessage = New ValueStorage(XMLWriter.Close());
			QueueMessageNumber = QueueMessageNumber + 1;
			ExchangeMobileApplicationCommon.AddMessageToMessageExchangeQueue(ExchangeNode, QueueMessageNumber, ExchangeMessage);
			
			XMLWriter = ExchangeMobileApplicationCommon.XMLWriteForExchangeMessage(ExchangeNode, MessageWriter);
			ReturnableList = CreateXDTOObject("Objects");
			TransferedObject = CreateXDTOObject("Remains");
			
			ObjectCount = 0;
			
		EndIf;
		
		TypeOfAddString = TransferedObject.Properties().Get("Item").Type;
		AddString = XDTOFactory.Create(TypeOfAddString);
		If ValueIsFilled(SelectionRemains.ProductsAndServices) Then
			ObjectCount = 0;
			AddString.Nomenclature = GetXDTODataObject(SelectionRemains.ProductsAndServices.GetObject(), ObjectCount);
		EndIf;
		AddString.Quantity = SelectionRemains.QuantityBalance;
		AddString.Total = SelectionRemains.AmountBalance;
		TransferedObject.Item.Add(AddString);
		
	EndDo;
	
	If TransferedObject <> Undefined Then
		ReturnableList.objects.Add(TransferedObject);
	EndIf;
	
EndProcedure // SerializationInventoryRemainsAndAddInXDTOObject()

Procedure SerializeAddRemainingStocksToUnifiedExportPackage(ReturnableList, Data) Export
	
	Query = New Query(
		"SELECT
		|	InventoryRemains.ProductsAndServices,
		|	InventoryRemains.QuantityBalance,
		|	InventoryRemains.AmountBalance
		|FROM
		|	AccumulationRegister.Inventory.Balance AS InventoryRemains
		|WHERE
		|	InventoryRemains.CustomerOrder = VALUE(Document.CustomerOrder.EmptyRef)
		|	AND InventoryRemains.QuantityBalance > 0"
	);
	Selection = Query.Execute().Select();
	
	TransferedObject = ExchangeMobileApplicationExportRules.CreateXDTOObject("Remains");
	
	While Selection.Next() Do
		TypeOfAddString = TransferedObject.Properties().Get("Item").Type;
		AddString = XDTOFactory.Create(TypeOfAddString);
		If ValueIsFilled(Selection.ProductsAndServices) Then
			ObjectCount = 0;
			AddString.Nomenclature = ExchangeMobileApplicationExportRules.GetXDTODataObject(Selection.ProductsAndServices.GetObject(), ObjectCount);
		EndIf;
		AddString.Quantity = Selection.QuantityBalance;
		AddString.Total = Selection.AmountBalance;
		TransferedObject.Item.Add(AddString);
	EndDo;
	
	If TransferedObject <> Undefined Then
		ReturnableList.objects.Add(TransferedObject);
	EndIf;
	
EndProcedure 

Procedure SerializeRolesAndAddInXDTOObject(MessageWriter, XMLWriter, ReturnableList, ExchangeNode, QueueMessageNumber, ObjectCount) Export
	
	TransferedObject = CreateXDTOObject("Roles");
	
	IsVersionForProduction = ExchangeMobileApplicationCommon.IsVersionForProduction(ExchangeNode);
	IsVersionOfRetail = ExchangeMobileApplicationCommon.IsVersionForRetail(ExchangeNode);
	
	For Each CurrentRole In ExchangeNode.Roles Do
		
		If (CurrentRole.Role = Enums.RolesOfMobileApplication.ProductionViewAndEdit
			OR CurrentRole.Role = Enums.RolesOfMobileApplication.ProductionOnlyView)
			AND NOT IsVersionForProduction Then
			Continue;
		EndIf;
		
		If (CurrentRole.Role = Enums.RolesOfMobileApplication.RetailViewAndEdit
			OR CurrentRole.Role = Enums.RolesOfMobileApplication.RetailOnlyView
			OR CurrentRole.Role = Enums.RolesOfMobileApplication.CompanyInfoViewAndEdit
			OR CurrentRole.Role = Enums.RolesOfMobileApplication.CompanyInfoOnlyView)
			AND NOT IsVersionOfRetail Then
			Continue;
		EndIf;
		
		
		ObjectCount = ObjectCount + 1;
		If ObjectCount >= NumberOfObjectsInPackage() Then
			
			ReturnableList.objects.Add(TransferedObject);
			
			XDTOFactory.WriteXML(XMLWriter, ReturnableList);
			MessageWriter.EndWrite();
			
			ExchangeMessage = New ValueStorage(XMLWriter.Close());
			QueueMessageNumber = QueueMessageNumber + 1;
			ExchangeMobileApplicationCommon.AddMessageToMessageExchangeQueue(ExchangeNode, QueueMessageNumber, ExchangeMessage);
			
			XMLWriter = ExchangeMobileApplicationCommon.XMLWriteForExchangeMessage(ExchangeNode, MessageWriter);
			ReturnableList = CreateXDTOObject("Objects");
			TransferedObject = CreateXDTOObject("Roles");
			
			ObjectCount = 0;
			
		EndIf;
		
		TypeOfAddString = TransferedObject.Properties().Get("role").Type;
		AddString = XDTOFactory.Create(TypeOfAddString);
		Index = Enums.RolesOfMobileApplication.IndexOf(CurrentRole.Role);
		AddString.Name = Metadata.Enums.RolesOfMobileApplication.EnumValues.Get(Index).Name;
		TransferedObject.Role.Add(AddString);
		
	EndDo;
	
	If TransferedObject <> Undefined Then
		ReturnableList.objects.Add(TransferedObject);
	EndIf;
	
EndProcedure // SerializeRolesAndAddInXDTOObject()

Procedure SerializeCompanyInfoAndAddInXFDTOObject(ReturnableList, ObjectCount) Export
	
	TransferedObject = SerializationCompanyInfo(ObjectCount);
	If TransferedObject <> Undefined Then
		ReturnableList.objects.Add(TransferedObject);
	EndIf;
	
EndProcedure // SerializeCompanyInfoAndAddInXFDTOObject()

Procedure SerializeTaxSettingsAndAddInXDTOObject(MessageWriter, XMLWriter, ReturnableList, ExchangeNode, QueueMessageNumber, ObjectCount) Export
	
	TransferedObject = SerializationTaxSettings(ObjectCount);
	If TransferedObject <> Undefined Then
		ReturnableList.objects.Add(TransferedObject);
	EndIf;
	
EndProcedure // SerializeTaxSettingsAndAddInXDTOObject()

Procedure SerializeCatalogsAndDocumentsAndAddInXDTOObject(MessageWriter, XMLWriter, ReturnableList, ExchangeNode, QueueMessageNumber, ObjectCount) Export
	
	Selection = ExchangePlans.SelectChanges(ExchangeNode, MessageWriter.MessageNo);
	
	While Selection.Next() Do
		
		ObjectCount = ObjectCount + 1;
		If ObjectCount >= NumberOfObjectsInPackage() Then
			
			XDTOFactory.WriteXML(XMLWriter, ReturnableList);
			MessageWriter.EndWrite();
			ExchangeMessage = New ValueStorage(XMLWriter.Close());
			QueueMessageNumber = QueueMessageNumber + 1;
			ExchangeMobileApplicationCommon.AddMessageToMessageExchangeQueue(ExchangeNode, QueueMessageNumber, ExchangeMessage);
			
			XMLWriter = ExchangeMobileApplicationCommon.XMLWriteForExchangeMessage(ExchangeNode, MessageWriter);
			ReturnableList = ExchangeMobileApplicationExportRules.CreateXDTOObject("Objects");
			
			ObjectCount = 0;
			
		EndIf;
		
		Data = Selection.Get();
		
		// If no data transfer is needed, then it may be necessary to record the deletion of the data.
		If NOT ExchangeMobileApplicationCommon.NeedToTransferData(Data, ExchangeNode) Then
			
			// Receive value with possible removal of data.
			DeletingData(Data);
			
		EndIf;
		
		XDTOObject = GetXDTODataObject(Data, ObjectCount);
		If XDTOObject <> Undefined Then
			ReturnableList.objects.Add(XDTOObject);
		EndIf;
		
	EndDo;
	
EndProcedure // SerializeCatalogsAndDocumentsAndAddInXDTOObject()

#EndRegion

#Region ServiceProceduresAndFunctions

Function CreateXDTOObject(ObjectType) Export
	
	SetPrivilegedMode(True);
	Return XDTOFactory.Create(XDTOFactory.Type("http://www.1c.com.vn/CM/MobileExchange", ObjectType));
	
EndFunction // CreateXDTOObject()

Function NumberOfObjectsInPackage()
	
	Return 1000;
	
EndFunction

Procedure DeletingData(Data)
	
	// Get the object description of the metadata corresponding to the data.
	MetadataObject = ?(TypeOf(Data) = Type("ObjectDeletion"), Data.Ref.Metadata(), Data.Metadata());
	
	// Check the type, only those types that are implemented on the mobile platform are interested.
	If Metadata.Catalogs.Contains(MetadataObject)
		OR Metadata.Documents.Contains(MetadataObject) Then
		
		// Transfer object deletion for object.
		Data = New ObjectDeletion(Data.Ref);
		
	ElsIf Metadata.InformationRegisters.Contains(MetadataObject)
		OR Metadata.AccumulationRegisters.Contains(MetadataObject)
		OR Metadata.Sequences.Contains(MetadataObject) Then
		
		// Clearing the data.
		Data.Clear();
		
	EndIf;
	
EndProcedure // DeletingData()

Function IsLLC(Company)
	Return CommonUse.GetAttributeValue(Company, "LegalEntityIndividual") = Enums.CounterpartyKinds.LegalEntity;
EndFunction

#EndRegion