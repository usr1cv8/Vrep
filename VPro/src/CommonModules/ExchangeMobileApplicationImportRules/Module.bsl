
#Region ServiceApplicationInterface

Procedure ImportObjects(ExchangeNode, Objects, IsNewExchange) Export
	
	DocumentsForLatePosting = New ValueTable;
	DocumentsForLatePosting.Columns.Add("DocumentRef");
	DocumentsForLatePosting.Columns.Add("DocumentType");
	DocumentsForLatePosting.Columns.Add("Order");
	
	BeginTransaction();
	
	If Objects <> Undefined Then
		For Each XDTOObject In Objects.objects Do
			If XDTOObject.Type().Name = "CatContractors" Then
				FindCreateCounterParties(ExchangeNode, XDTOObject, IsNewExchange);
			ElsIf XDTOObject.Type().Name = "CatItems" Then
				FindCreateProduct(ExchangeNode, XDTOObject, IsNewExchange);
			ElsIf XDTOObject.Type().Name = "CatStructuralUnit" Then
				FindCreateStructuralUnit(ExchangeNode, XDTOObject, IsNewExchange);
			ElsIf XDTOObject.Type().Name = "CatCashDesk" Then
				FindCreateCashCR(ExchangeNode, XDTOObject, IsNewExchange);
			ElsIf XDTOObject.Type().Name = "CashFlowItems" Then
				FindCreateCashFlow(ExchangeNode, XDTOObject, IsNewExchange);
			ElsIf XDTOObject.Type().Name = "DocOrders" Then
				FindCreateCustomerOrder(ExchangeNode, XDTOObject, DocumentsForLatePosting, IsNewExchange);
			ElsIf XDTOObject.Type().Name = "DocInvoice" Then
				FindCreateCustomerInvoice(ExchangeNode, XDTOObject, DocumentsForLatePosting, IsNewExchange);
			ElsIf XDTOObject.Type().Name = "DocPurshareInvoice" Then
				FindCreateSupplierInvoice(ExchangeNode, XDTOObject, DocumentsForLatePosting, IsNewExchange);
			ElsIf XDTOObject.Type().Name = "DocIncomingPayment" Then
				FindCreateCashReceipt(ExchangeNode, XDTOObject, DocumentsForLatePosting, IsNewExchange);
			ElsIf XDTOObject.Type().Name = "DocOutgoingPayment" Then
				FindCreateCashPayment(ExchangeNode, XDTOObject, DocumentsForLatePosting, IsNewExchange);
			ElsIf XDTOObject.Type().Name = "DocProduction" Then
				FindCreateInventoryAssembly(ExchangeNode, XDTOObject, DocumentsForLatePosting, IsNewExchange);
			ElsIf XDTOObject.Type().Name = "DocCashReceipt" Then
				FindCreateReceiptCR(ExchangeNode, XDTOObject, DocumentsForLatePosting, IsNewExchange);
			ElsIf XDTOObject.Type().Name = "DocCashReceiptReturn" Then
				FindCreateReceiptCRReturn(ExchangeNode, XDTOObject, DocumentsForLatePosting, IsNewExchange);
			ElsIf XDTOObject.Type().Name = "DocRetailSalesReport" Then
				FindCreateRetailReport(ExchangeNode, XDTOObject, DocumentsForLatePosting, IsNewExchange);
			ElsIf XDTOObject.Type().Name = "Prices" Then
				ImportPrices(ExchangeNode, XDTOObject, IsNewExchange);
			ElsIf XDTOObject.Type().Name = "ObjectDeletion" Then
				SetDeletionMark(ExchangeNode, XDTOObject);
			EndIf;
		EndDo;
	EndIf;
	
	CommitTransaction();
	
	RunLatePosting(ExchangeNode, DocumentsForLatePosting);
	
EndProcedure // ImportObjects()

#EndRegion

#Region Catalogs

Function FindCreateCounterParties(ExchangeNode, XDTOObject, IsNewExchange)
	
	If XDTOObject = Undefined Then
		Return Catalogs.Counterparties.EmptyRef();
	EndIf;
	
	ID = New UUID(XDTOObject.Id);
	Ref = Catalogs.Counterparties.GetRef(ID);
	Object = Ref.GetObject();
	IsNew = False;
	If Object = Undefined Then
		If XDTOObject.ThisIsGroup Then
			Object = Catalogs.Counterparties.CreateFolder();
		Else
			Object = Catalogs.Counterparties.CreateItem();
			Object.Customer = True;
			Object.Supplier = True;
			Object.OtherRelationship = True;
		EndIf;
		Object.SetNewObjectRef(Ref);
		Object.SetNewCode();
		Object.Write();
		IsNew = True;
	EndIf;
	
	If NOT IsNewExchange AND NOT IsNew Then
		Return Object.Ref;
	EndIf;
	
	NeedToWriteObject = False;
	If Object.Description <> XDTOObject.Name Then
		Object.Description = XDTOObject.Name;
		NeedToWriteObject = True;
	EndIf;
	
	Parent = FindCreateCounterParties(ExchangeNode, XDTOObject.Group, IsNewExchange);
	If Object.Parent <> Parent Then
		Object.Parent = Parent;
		NeedToWriteObject = True;
	EndIf;
	If Object.Comment <> XDTOObject.AdditionalInfo
		AND NOT Object.IsFolder Then
		Object.Comment = XDTOObject.AdditionalInfo;
		NeedToWriteObject = True;
	EndIf;
	If NOT Object.IsFolder Then
		If NOT ValueIsFilled(Object.DescriptionFull) Then
			Object.DescriptionFull = Object.Description;
			NeedToWriteObject = True;
		EndIf;
		If NOT ValueIsFilled(Object.LegalEntityIndividual) Then
			Object.LegalEntityIndividual = Enums.CounterpartyKinds.LegalEntity;
			NeedToWriteObject = True;
		EndIf;
		If NOT ValueIsFilled(Object.Responsible) Then
			MainResponsible = SmallBusinessReUse.GetValueByDefaultUser(
				Users.CurrentUser(),
				"MainResponsible"
			);
			Object.Responsible = MainResponsible;
			NeedToWriteObject = True;
		EndIf;
		If NOT ValueIsFilled(Object.GLAccountCustomerSettlements) Then
			Object.GLAccountCustomerSettlements = ChartsOfAccounts.Managerial.AccountsReceivable;
			NeedToWriteObject = True;
		EndIf;
		If NOT ValueIsFilled(Object.CustomerAdvancesGLAccount) Then
			Object.CustomerAdvancesGLAccount = ChartsOfAccounts.Managerial.AccountsByAdvancesReceived;
			NeedToWriteObject = True;
		EndIf;
		If NOT ValueIsFilled(Object.GLAccountVendorSettlements) Then
			Object.GLAccountVendorSettlements = ChartsOfAccounts.Managerial.AccountsPayable;
			NeedToWriteObject = True;
		EndIf;
		If NOT ValueIsFilled(Object.VendorAdvancesGLAccount) Then
			Object.VendorAdvancesGLAccount = ChartsOfAccounts.Managerial.SettlementsByAdvancesIssued;
			NeedToWriteObject = True;
		EndIf;
		If IsNew Then
			If ExchangeMobileApplicationCommon.IsVersionForOldExchange(ExchangeNode) Then // this is the old version
				Object.DoOperationsByContracts = False;
				Object.DoOperationsByDocuments = False;
				Object.DoOperationsByOrders = True;
				Object.TrackPaymentsByBills = True;
			Else
				Object.DoOperationsByContracts = True;
				Object.DoOperationsByDocuments = True;
				Object.DoOperationsByOrders = True;
				Object.TrackPaymentsByBills = True;
			EndIf;
			NeedToWriteObject = True;
		EndIf;
		If ValueIsFilled(XDTOObject.Adress) Then
			FoundStringAddress = False;
			For Each CurRow In Object.ContactInformation Do
				If CurRow.Type = Enums.ContactInformationTypes.Address
				   AND CurRow.Kind = Catalogs.ContactInformationKinds.CounterpartyActualAddress Then
					FoundStringAddress = True;
					If CurRow.Presentation <> XDTOObject.Adress Then
						CurRow.Presentation = XDTOObject.Adress;
						NeedToWriteObject = True;
					EndIf;
				EndIf;
			EndDo;
			If NOT FoundStringAddress Then
				NewRow = Object.ContactInformation.Add();
				NewRow.Type = Enums.ContactInformationTypes.Address;
				NewRow.Kind = Catalogs.ContactInformationKinds.CounterpartyActualAddress; 
				NewRow.Presentation = XDTOObject.Adress;
				NeedToWriteObject = True;
			EndIf;
		EndIf;
		If ValueIsFilled(XDTOObject.Tel) Then
			FoundString = False;
			For Each CurRow In Object.ContactInformation Do
				If CurRow.Type = Enums.ContactInformationTypes.Phone
				   AND CurRow.Kind = Catalogs.ContactInformationKinds.CounterpartyPhone Then
					FoundString = True;
					If CurRow.Presentation <> XDTOObject.Tel Then
						CurRow.Presentation = XDTOObject.Tel;
						NeedToWriteObject = True;
					EndIf;
				EndIf;
			EndDo;
			If NOT FoundString Then
				NewRow = Object.ContactInformation.Add();
				NewRow.Type = Enums.ContactInformationTypes.Phone;
				NewRow.Kind = Catalogs.ContactInformationKinds.CounterpartyPhone;
				NewRow.Presentation = XDTOObject.Tel;
				NeedToWriteObject = True;
			EndIf;
		EndIf;
		If ValueIsFilled(XDTOObject.Email) Then
			FoundString = False;
			For Each CurRow In Object.ContactInformation Do
				If CurRow.Type = Enums.ContactInformationTypes.EmailAddress
				   AND CurRow.Kind = Catalogs.ContactInformationKinds.CounterpartyEmail Then
					FoundString = True;
					If CurRow.Presentation <> XDTOObject.Email Then
						CurRow.Presentation = XDTOObject.Email;
						NeedToWriteObject = True;
					EndIf;
				EndIf;
			EndDo;
			If NOT FoundString Then
				NewRow = Object.ContactInformation.Add();
				NewRow.Type = Enums.ContactInformationTypes.EmailAddress;
				NewRow.Kind = Catalogs.ContactInformationKinds.CounterpartyEmail;
				NewRow.Presentation = XDTOObject.Email;
				NeedToWriteObject = True;
			EndIf;
		EndIf;
	EndIf;
	
	If NeedToWriteObject Then
		Object.Write();
	EndIf;
	
	If Object.DeletionMark <> XDTOObject.DeletionMark Then
		Object.SetDeletionMark(XDTOObject.DeletionMark, False);
	EndIf;
	
	ExchangePlans.DeleteChangeRecords(ExchangeNode, Object);
	
	Return Object.Ref;
	
EndFunction // FindCreateCounterParties()

Function FindCreateProduct(ExchangeNode, XDTOObject, IsNewExchange)
	
	If XDTOObject = Undefined Then
		Return Catalogs.ProductsAndServices.EmptyRef();
	EndIf;
	
	ID = New UUID(XDTOObject.Id);
	Ref = Catalogs.ProductsAndServices.GetRef(ID);
	Object = Ref.GetObject();
	IsNew = False;
	If Object = Undefined Then
		If XDTOObject.ThisIsGroup Then
			Object = Catalogs.ProductsAndServices.CreateFolder();
		Else
			Object = Catalogs.ProductsAndServices.CreateItem();
		EndIf;
		Object.SetNewObjectRef(Ref);
		Object.SetNewCode();
		Object.Write();
		IsNew = True;
	EndIf;
	
	If NOT IsNewExchange AND NOT IsNew Then
		Return Object.Ref;
	EndIf;
	
	NeedToWriteObject = False;
	If Object.Description <> XDTOObject.Name Then
		Object.Description = XDTOObject.Name;
		NeedToWriteObject = True;
	EndIf;
	If Object.SKU <> XDTOObject.Article
		AND NOT Object.IsFolder Then
		Object.SKU = XDTOObject.Article;
		NeedToWriteObject = True;
	EndIf;
	Parent = FindCreateProduct(ExchangeNode, XDTOObject.Group, IsNewExchange);
	If Object.Parent <> Parent Then
		Object.Parent = Parent;
		NeedToWriteObject = True;
	EndIf;
	Vendor = FindCreateCounterParties(ExchangeNode, XDTOObject.Supplier, IsNewExchange);
	If Object.Vendor <> Vendor
		AND NOT Object.IsFolder Then
		Object.Vendor = Vendor;
		NeedToWriteObject = True;
	EndIf;
	If Object.ProductsAndServicesType <> FindProductType(XDTOObject.TypeItem)
		AND NOT Object.IsFolder Then
		Object.ProductsAndServicesType = FindProductType(XDTOObject.TypeItem);
		NeedToWriteObject = True;
	EndIf;
	If XDTOObject.Properties().Get("Image") <> Undefined
		AND ValueIsFilled(XDTOObject.Image) Then
		If ValueIsFilled(Object.PictureFile) Then
			FileInfo = New Structure;
			FileInfo.Insert("FileAddressInTemporaryStorage", PutToTempStorage(XDTOObject.Image));
			FileInfo.Insert("TextTemporaryStorageAddress", "");
			AttachedFiles.UpdateAttachedFile(Object.PictureFile, FileInfo);
		Else
			Address = PutToTempStorage(XDTOObject.Image);
			AttachedFile = AttachedFiles.AddFile(Object.Ref, "cover",,,,Address);
			Object.PictureFile = AttachedFile;
		EndIf;
		NeedToWriteObject = True;
	EndIf;
	If XDTOObject.Properties().Get("BarCode") <> Undefined Then
		FindCreateProductBarcode(Object.Ref, XDTOObject.BarCode);
		NeedToWriteObject = True;
	EndIf;
	If NOT Object.IsFolder Then
		If NOT ValueIsFilled(Object.ReplenishmentDeadline) Then
			Object.ReplenishmentDeadline = 1;
		EndIf;
		If NOT ValueIsFilled(Object.Warehouse) Then
			Object.Warehouse = Catalogs.StructuralUnits.MainWarehouse;
		EndIf;
		If NOT ValueIsFilled(Object.InventoryGLAccount) Then
			Object.InventoryGLAccount = ChartsOfAccounts.Managerial.RawMaterialsAndMaterials;
		EndIf;
		If NOT ValueIsFilled(Object.ExpensesGLAccount) Then
			Object.ExpensesGLAccount = ChartsOfAccounts.Managerial.CommercialExpenses;
		EndIf;
		If NOT ValueIsFilled(Object.DescriptionFull) Then
			Object.DescriptionFull = Object.Description;
		EndIf;
		If NOT ValueIsFilled(Object.MeasurementUnit) Then
			Object.MeasurementUnit = Catalogs.UOMClassifier.pcs;
		EndIf;
		If NOT ValueIsFilled(Object.ProductsAndServicesCategory) Then
			Object.ProductsAndServicesCategory = Catalogs.ProductsAndServicesCategories.WithoutCategory;
		EndIf;
		If NOT ValueIsFilled(Object.EstimationMethod) Then
			Object.EstimationMethod = Enums.InventoryValuationMethods.ByAverage;
		EndIf;
		If NOT ValueIsFilled(Object.BusinessActivity) Then
			Object.BusinessActivity = Catalogs.BusinessActivities.MainActivity;
		EndIf;
		If NOT ValueIsFilled(Object.ReplenishmentMethod) Then
			Object.ReplenishmentMethod = Enums.InventoryReplenishmentMethods.Purchase;
		EndIf;
		If NOT ValueIsFilled(Object.VATRate) Then
			Query = New Query(
				"SELECT
				|	VATRates.Ref
				|FROM
				|	Catalog.VATRates AS VATRates
				|WHERE
				|	VATRates.Rate = 10
				|	AND NOT VATRates.Calculated"
			);
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				Object.VATRate = Selection.Ref;
			EndIf;
		EndIf;
		NeedToWriteObject = True;
	EndIf;
	
	If NeedToWriteObject Then
		Object.Write();
	EndIf;
	
	If Object.DeletionMark <> XDTOObject.DeletionMark Then
		Object.SetDeletionMark(XDTOObject.DeletionMark, False);
	EndIf;
	
	ExchangePlans.DeleteChangeRecords(ExchangeNode, Object);
	
	Return Object.Ref;
	
EndFunction // FindCreateProduct()

Function FindCreateCashFlow(ExchangeNode, XDTOObject, IsNewExchange)
	
	If XDTOObject = Undefined Then
		Return Catalogs.CashFlowItems.EmptyRef();
	EndIf;
	
	If XDTOObject.Predefined <> Undefined AND XDTOObject.Predefined Then
		If XDTOObject.PredefinedCode = "000000001" Then
			Return Catalogs.CashFlowItems.PaymentFromCustomers;
		ElsIf XDTOObject.PredefinedCode = "000000002" Then
			Return Catalogs.CashFlowItems.PaymentToVendor;
		ElsIf XDTOObject.PredefinedCode = "000000003" Then
			Return Catalogs.CashFlowItems.Other;
		EndIf;
	EndIf;
	
	ID = New UUID(XDTOObject.Id);
	Ref = Catalogs.CashFlowItems.GetRef(ID);
	Object = Ref.GetObject();
	IsNew = False;
	If Object = Undefined Then
		If XDTOObject.ThisIsGroup Then
			Object = Catalogs.CashFlowItems.CreateFolder();
		Else
			Object = Catalogs.CashFlowItems.CreateItem();
		EndIf;
		Object.SetNewObjectRef(Ref);
		Object.SetNewCode();
		Object.Write();
		IsNew = True;
	EndIf;
	
	If Object.Predefined Then
		Return Object.Ref;
	EndIf;
	
	NeedToWriteObject = False;
	If Object.Description <> XDTOObject.Name Then
		Object.Description = XDTOObject.Name;
		NeedToWriteObject = True;
	EndIf;
	
	Parent = FindCreateCashFlow(ExchangeNode, XDTOObject.Group, IsNewExchange);
	If Object.Parent <> Parent Then
		Object.Parent = Parent;
		NeedToWriteObject = True;
	EndIf;
		
	If NeedToWriteObject Then
		Object.Write();
	EndIf;
	
	If Object.DeletionMark <> XDTOObject.DeletionMark Then
		Object.SetDeletionMark(XDTOObject.DeletionMark, False);
	EndIf;
	
	ExchangePlans.DeleteChangeRecords(ExchangeNode, Object);
	
	Return Object.Ref;
	
EndFunction // FindCreateCashFlow()

Function FindCreateStructuralUnit(ExchangeNode, XDTOObject, IsNewExchange)
	
	If XDTOObject = Undefined Then
		Return Catalogs.StructuralUnits.EmptyRef();
	EndIf;
	
	If XDTOObject.Predefined <> Undefined AND XDTOObject.Predefined Then
		If XDTOObject.PredefinedCode = "000000001" Then
			Return Catalogs.StructuralUnits.MainDepartment;
		ElsIf XDTOObject.PredefinedCode = "000000002" Then
			Return Catalogs.StructuralUnits.MainWarehouse;
		EndIf;
	EndIf;
	
	ID = New UUID(XDTOObject.Id);
	Ref = Catalogs.StructuralUnits.GetRef(ID);
	Object = Ref.GetObject();
	IsNew = False;
	If Object = Undefined Then
		Object = Catalogs.StructuralUnits.CreateItem();
		Object.SetNewObjectRef(Ref);
		Object.SetNewCode();
		Object.Write();
		IsNew = True;
	EndIf;
	
	If Object.Predefined Then
		Return Object.Ref;
	EndIf;
	
	NeedToWriteObject = False;
	If Object.Description <> XDTOObject.Name Then
		Object.Description = XDTOObject.Name;
		NeedToWriteObject = True;
	EndIf;
	
	Parent = FindCreateStructuralUnit(ExchangeNode, XDTOObject.Group, IsNewExchange);
	If Object.Parent <> Parent Then
		Object.Parent = Parent;
		NeedToWriteObject = True;
	EndIf;
	
	If NOT ValueIsFilled(Object.StructuralUnitType) Then
		Object.StructuralUnitType = Enums.StructuralUnitsTypes.Retail;
		NeedToWriteObject = True;
	EndIf;
	
	If NOT ValueIsFilled(Object.RetailPriceKind) Then
		Object.RetailPriceKind = Catalogs.PriceKinds.GetMainKindOfSalePrices();
		NeedToWriteObject = True;
	EndIf;
	
	If NeedToWriteObject Then
		Object.Write();
	EndIf;
	
	If Object.DeletionMark <> XDTOObject.DeletionMark Then
		Object.SetDeletionMark(XDTOObject.DeletionMark, False);
	EndIf;
	
	ExchangePlans.DeleteChangeRecords(ExchangeNode, Object);
	
	Return Object.Ref;
	
EndFunction // FindCreateCounterParties()

Function FindCreateCashCR(ExchangeNode, XDTOObject, IsNewExchange)
	
	If XDTOObject = Undefined Then
		Return Catalogs.CashRegisters.EmptyRef();
	EndIf;
	
	ID = New UUID(XDTOObject.Id);
	Ref = Catalogs.CashRegisters.GetRef(ID);
	Object = Ref.GetObject();
	IsNew = False;
	If Object = Undefined Then
		Object = Catalogs.CashRegisters.CreateItem();
		Object.SetNewObjectRef(Ref);
		Object.SetNewCode();
		Object.UseWithoutEquipmentConnection = True;
		Object.GLAccount = ChartsOfAccounts.Managerial.PettyCash;
		
		SettingValue = SmallBusinessReUse.GetValueByDefaultUser(Users.CurrentUser(), "MainCompany");
		If ValueIsFilled(SettingValue) Then
			Object.Owner = SettingValue;
		Else
			Object.Owner = Catalogs.Companies.CompanyByDefault();
		EndIf;
		Object.Write();
		IsNew = True;
	EndIf;
	
	NeedToWriteObject = False;
	If Object.Description <> XDTOObject.Name Then
		Object.Description = XDTOObject.Name;
		NeedToWriteObject = True;
	EndIf;
	
	StructuralUnit = FindCreateStructuralUnit(ExchangeNode, XDTOObject.RetailStructuralUnit, IsNewExchange);
	If Object.StructuralUnit <> StructuralUnit Then
		Object.StructuralUnit = StructuralUnit;
		NeedToWriteObject = True;
	EndIf;
	
	If NOT ValueIsFilled(Object.CashCRType) Then
		Object.CashCRType = Enums.CashCRTypes.FiscalRegister;
		NeedToWriteObject = True;
	EndIf;
	
	If NOT ValueIsFilled(Object.Department) Then
		Object.Department = SmallBusinessReUse.GetValueByDefaultUser(
			Users.CurrentUser(),
			"MainDepartment"
		);
		Object.Department = ?(ValueIsFilled(Object.Department), Object.Department, Catalogs.StructuralUnits.MainDepartment);
		NeedToWriteObject = True;
	EndIf;
	
	If NOT ValueIsFilled(Object.CashCurrency) Then
		Object.CashCurrency = Constants.NationalCurrency.Get();
		NeedToWriteObject = True;
	EndIf;
	
	If NeedToWriteObject Then
		Object.Write();
	EndIf;
	
	If Object.DeletionMark <> XDTOObject.DeletionMark Then
		Object.SetDeletionMark(XDTOObject.DeletionMark, False);
	EndIf;
	
	ExchangePlans.DeleteChangeRecords(ExchangeNode, Object);
	
	Return Object.Ref;
	
EndFunction // FindCreateCounterParties()

#EndRegion

#Region Documents

Function FindCreateCustomerOrder(ExchangeNode, XDTOObject, DocumentsForLatePosting, IsNewExchange)
	
	If XDTOObject = Undefined Then
		Return Documents.CustomerOrder.EmptyRef();
	EndIf;
	
	Object = CreateDocument("CustomerOrder", XDTOObject);
	
	If NOT Object.IsNew() Then // In order not to spoil the data do not refill the document.
		BreakFilling = ExchangeMobileApplicationCommon.ChangesToTabularSectionAreAvailable(Object, "Inventory");
		If BreakFilling Then
			Return Object.Ref;
		EndIf;
	EndIf;
	
	NeedToWriteObject = False;
	FillMainDocumentAttributes(Object, XDTOObject, NeedToWriteObject);
	
	If NOT ValueIsFilled(Object.OperationKind) Then
		Object.OperationKind = Enums.OperationKindsCustomerOrder.OrderForSale;
		NeedToWriteObject = True;
	EndIf;
	
	If NOT ValueIsFilled(Object.Author) Then
		Object.Author = SmallBusinessReUse.GetValueByDefaultUser(
			Object.Author,
			"MainResponsible"
		);
		NeedToWriteObject = True;
	EndIf;
	
	If NOT ValueIsFilled(Object.DocumentCurrency) Then
		Object.DocumentCurrency = Constants.NationalCurrency.Get();
		NeedToWriteObject = True;
	EndIf;
	
	Counterparty = FindCreateCounterParties(ExchangeNode, XDTOObject.Buyer, IsNewExchange);
	If Object.Counterparty <> Counterparty Then
		Object.Counterparty = Counterparty;
		NeedToWriteObject = True;
	EndIf;
	If NOT ValueIsFilled(Object.Contract) Then
		ContractByDefault = FindCreateContractByDefault(
			Object.Ref,
			Object.Counterparty,
			Object.Company,
			Object.OperationKind,
			Enums.ContractKinds.WithCustomer);
		Object.Contract = ContractByDefault;
		Query = New Query(
			"SELECT
			|	CurrencyRatesSliceLast.ExchangeRate,
			|	CurrencyRatesSliceLast.Multiplicity
			|FROM
			|	InformationRegister.CurrencyRates.SliceLast(&Period, Currency = &Currency) AS CurrencyRatesSliceLast"
		);
		Query.SetParameter("Period", Object.Date);
		Query.SetParameter("Currency", Object.Contract.SettlementsCurrency);
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			Object.ExchangeRate = Selection.ExchangeRate;
			Object.Multiplicity = Selection.Multiplicity;
		Else
			Object.ExchangeRate = 1;
			Object.Multiplicity = 1;
		EndIf;
		NeedToWriteObject = True;
	EndIf;
	
	If NOT ValueIsFilled(Object.ShipmentDate) Then
		Object.ShipmentDate = Object.Date;
		NeedToWriteObject = True;
	EndIf;
	
	OrderStatusDownloadable = FindCustomerOrderStates(XDTOObject.OrderStatus); 
	If NOT ValueIsFilled(Object.OrderState) OR
		Object.OrderState <> OrderStatusDownloadable Then
		Object.OrderState = OrderStatusDownloadable;
		NeedToWriteObject = True;
	EndIf;
	
	If NOT ValueIsFilled(Object.SalesStructuralUnit) Then
		Object.SalesStructuralUnit = SmallBusinessReUse.GetValueByDefaultUser(
			Object.Author,
			"MainDepartment"
		);
		Object.SalesStructuralUnit = ?(ValueIsFilled(Object.SalesStructuralUnit), Object.SalesStructuralUnit, Catalogs.StructuralUnits.MainDepartment);
		NeedToWriteObject = True;
	EndIf;
	
	If Object.IsNew() Then
		Object.PriceKind = SmallBusinessReUse.GetValueByDefaultUser(
			Object.Author,
			"MainPriceKindSales"
		);
		Object.PriceKind = ?(ValueIsFilled(Object.PriceKind), Object.PriceKind, Object.Contract.PriceKind);
		Object.PriceKind = ?(ValueIsFilled(Object.PriceKind), Object.PriceKind, Catalogs.PriceKinds.Wholesale);
		Object.AmountIncludesVAT = ?(ValueIsFilled(Object.PriceKind), Object.PriceKind.PriceIncludesVAT, True);
		
		SettingValue = SmallBusinessReUse.GetValueByDefaultUser(Users.CurrentUser(), "ShipmentDatePositionInCustomerOrder");
		If ValueIsFilled(SettingValue) Then
			If Object.ShipmentDatePosition <> SettingValue Then
				Object.ShipmentDatePosition = SettingValue;
			EndIf;
		Else
			Object.ShipmentDatePosition = Enums.AttributePositionOnForm.InHeader;
		EndIf;
		
		NeedToWriteObject = True;
	EndIf;
	
	If Object.Inventory.Count() > 0 Then
		Object.Inventory.Clear();
		NeedToWriteObject = True;
	EndIf;
	
	If XDTOObject.Items <> Undefined Then
		For Each CurRow In XDTOObject.Items.Item Do
			NewRow = Object.Inventory.Add();
			NewRow.ProductsAndServices = FindCreateProduct(ExchangeNode, CurRow.Nomenclature, IsNewExchange);
			NewRow.ProductsAndServicesTypeInventory = NewRow.ProductsAndServices.ProductsAndServicesType = Enums.ProductsAndServicesTypes.InventoryItem;
			NewRow.MeasurementUnit = NewRow.ProductsAndServices.MeasurementUnit;
			NewRow.Price = CurRow.Price;
			NewRow.Quantity = CurRow.Quantity;
			NewRow.Amount = CurRow.Total;
			NewRow.ShipmentDate = Object.Date;
			NeedToWriteObject = True;
		EndDo;
	EndIf;
	
	If XDTOObject.Properties().Get("Comment") <> Undefined
		AND Object.Comment <> XDTOObject.Comment Then
		Object.Comment = XDTOObject.Comment;
		NeedToWriteObject = True;
	EndIf;
	
	DistributeAmountToDiscounts(Object.Inventory, XDTOObject.Discount);
	
	For Each CurRow In Object.Inventory Do
		CalculateAmoutsForRow(Object, CurRow);
	EndDo;
	
	WriteDocument(ExchangeNode, Object, XDTOObject, NeedToWriteObject, DocumentsForLatePosting);
	
	// If the number in the mobile application does not match the
	// order number in the central database, send back to synchronize the numbers.
	If XDTOObject.name = Object.Number Then
		ExchangePlans.DeleteChangeRecords(ExchangeNode, Object);
	EndIf;
	
	Return Object.Ref;
	
EndFunction // FindCreateCustomerOrder()

Function FindCreateCashPayment(ExchangeNode, XDTOObject, DocumentsForLatePosting, IsNewExchange)
	
	If XDTOObject = Undefined Then
		Return Documents.CashPayment.EmptyRef();
	EndIf;
	
	Object = CreateDocument("CashPayment", XDTOObject);
	
	NeedToWriteObject = False;
	
	FillMainDocumentAttributes(Object, XDTOObject, NeedToWriteObject);
	
	If NOT ValueIsFilled(Object.CashCurrency) Then
		Object.CashCurrency = Constants.NationalCurrency.Get();
		NeedToWriteObject = True;
	EndIf;
	
	If NOT ValueIsFilled(Object.PettyCash) Then
		Object.PettyCash = Object.Company.PettyCashByDefault;
		NeedToWriteObject = True;
	EndIf;
		
	Counterparty = FindCreateCounterParties(ExchangeNode, XDTOObject.Contractor, IsNewExchange);
	
	If Object.Counterparty <> Counterparty
	 OR NOT ValueIsFilled(Object.OperationKind) Then
		If ValueIsFilled(Counterparty) Then
			Object.OperationKind = Enums.OperationKindsCashPayment.Vendor;
		Else                                                      
			Object.OperationKind = Enums.OperationKindsCashPayment.Other;
			Object.Correspondence = ChartsOfAccounts.Managerial.OtherExpenses;
		EndIf;
		NeedToWriteObject = True;
	EndIf;
		
	If Object.Counterparty <> Counterparty Then
		Object.Counterparty = Counterparty;
		NeedToWriteObject = True;
	EndIf;
	
	SupplierInvoice = FindCreateSupplierInvoice(ExchangeNode, XDTOObject.PurshareInvoice, DocumentsForLatePosting, IsNewExchange);
	If Object.BasisDocument <> SupplierInvoice Then
		Object.BasisDocument = SupplierInvoice;
		NeedToWriteObject = True;
	EndIf;
	
	Object.PaymentDetails.Clear();
	NeedToWriteObject = True;
	NewRow = Object.PaymentDetails.Add();
	ContractByDefault = FindCreateContractByDefault(
		Object.Ref,
		Object.Counterparty,
		Object.Company,
		Object.OperationKind,
		Enums.ContractKinds.WithVendor
	);
	NewRow.Contract = ContractByDefault;
	Query = New Query(
		"SELECT CurrencyRatesSliceLast.Currency, CurrencyRatesSliceLast.ExchangeRate, CurrencyRatesSliceLast.Multiplicity FROM InformationRegister.CurrencyRates.SliceLast(&Period, Currency IN (&Currencies)) AS CurrencyRatesSliceLast"
	);
	Currencies = New Array();
	Currencies.Add(ContractByDefault.SettlementsCurrency);
	Currencies.Add(Object.CashCurrency);
	Query.SetParameter("Period", Object.Date);
	Query.SetParameter("Currencies", Currencies);
	CurrencyTable = Query.Execute().Unload();
	SettlementsCurrency = CurrencyTable.Find(ContractByDefault.SettlementsCurrency, "Currency");
	CashCurrency = CurrencyTable.Find(Object.CashCurrency, "Currency");
	
	If ValueIsFilled(SettlementsCurrency) Then
		NewRow.ExchangeRate = SettlementsCurrency.ExchangeRate;
		NewRow.Multiplicity = SettlementsCurrency.Multiplicity;
	Else
		NewRow.ExchangeRate = 1;
		NewRow.Multiplicity = 1;
	EndIf;
	
	NewRow.PaymentAmount = Object.DocumentAmount;
	If ValueIsFilled(SupplierInvoice) Then
		NewRow.Document = SupplierInvoice;
	Else
		NewRow.AdvanceFlag = True;
	EndIf;
	
	If ValueIsFilled(CashCurrency) Then
		NewRow.SettlementsAmount = SmallBusinessServer.RecalculateFromCurrencyToCurrency(
			NewRow.PaymentAmount,
			CashCurrency.ExchangeRate,
			NewRow.ExchangeRate,
			CashCurrency.Multiplicity,
			NewRow.Multiplicity
		);
	Else
		NewRow.SettlementsAmount = SmallBusinessServer.RecalculateFromCurrencyToCurrency(
			NewRow.PaymentAmount,
			1,
			NewRow.ExchangeRate,
			1,
			NewRow.Multiplicity
		);
	EndIf;
	
	If Object.VATTaxation = Enums.VATTaxationTypes.TaxableByVAT Then
		DefaultVATRate = Object.Company.DefaultVATRate; 
	ElsIf Object.VATTaxation = Enums.VATTaxationTypes.NotTaxableByVAT Then
		DefaultVATRate = SmallBusinessReUse.GetVATRateWithoutVAT();
	Else
		DefaultVATRate = SmallBusinessReUse.GetVATRateZero();
	EndIf;
	
	NewRow.VATRate = DefaultVATRate;
	NewRow.VATAmount = NewRow.PaymentAmount - (NewRow.PaymentAmount) / ((NewRow.VATRate.Rate + 100) / 100);
	
	If XDTOObject.Properties().Get("Comment") <> Undefined
		AND Object.Comment <> XDTOObject.Comment Then
		Object.Comment = XDTOObject.Comment;
		NeedToWriteObject = True;
	EndIf;
	
	If XDTOObject.Properties().Get("CashFlowItem") <> Undefined Then
		CashFlow = FindCreateCashFlow(ExchangeNode, XDTOObject.CashFlowItem, IsNewExchange);
		If Object.Item <> CashFlow Then
			Object.Item = CashFlow;
			NeedToWriteObject = True;
		EndIf;
	EndIf;
	
	If NOT ValueIsFilled(Object.Item) Then
		Object.Item = Catalogs.CashFlowItems.PaymentToVendor;
		NeedToWriteObject = True;
	EndIf;
	
	WriteDocument(ExchangeNode, Object, XDTOObject, NeedToWriteObject, DocumentsForLatePosting);
	
	// If the order number in the mobile application does not match the
	// order number in the central database, send back to synchronize the numbers.
	If XDTOObject.name = Object.Number Then
		ExchangePlans.DeleteChangeRecords(ExchangeNode, Object);
	EndIf;
	
	Return Object.Ref;
	
EndFunction // FindCreateCashPayment()

Function FindCreateCashReceipt(ExchangeNode, XDTOObject, DocumentsForLatePosting, IsNewExchange)
	
	If XDTOObject = Undefined Then
		Return Documents.CashReceipt.EmptyRef();
	EndIf;
	
	Object = CreateDocument("CashReceipt", XDTOObject);
	
	NeedToWriteObject = False;
	
	FillMainDocumentAttributes(Object, XDTOObject, NeedToWriteObject);
	
	If NOT ValueIsFilled(Object.OperationKind) Then
		Object.OperationKind = Enums.OperationKindsCashReceipt.FromCustomer;
	EndIf;
	
	If NOT ValueIsFilled(Object.CashCurrency) Then
		Object.CashCurrency = Constants.NationalCurrency.Get();
		NeedToWriteObject = True;
	EndIf;
	
	If NOT ValueIsFilled(Object.PettyCash) Then
		Object.PettyCash = Object.Company.PettyCashByDefault;
		NeedToWriteObject = True;
	EndIf;
	
	Counterparty = FindCreateCounterParties(ExchangeNode, XDTOObject.Contractor, IsNewExchange);
	
	If Object.Counterparty <> Counterparty
	 OR NOT ValueIsFilled(Object.OperationKind) Then
		If ValueIsFilled(Counterparty) Then
			Object.OperationKind = Enums.OperationKindsCashReceipt.FromCustomer;
		Else
			Object.OperationKind = Enums.OperationKindsCashReceipt.Other;
			Object.Correspondence = ChartsOfAccounts.Managerial.OtherIncome;
		EndIf;
		NeedToWriteObject = True;
	EndIf;
	
	If Object.Counterparty <> Counterparty Then
		Object.Counterparty = Counterparty;
		NeedToWriteObject = True;
	EndIf;
	
	If NOT ValueIsFilled(Object.AcceptedFrom) Then
		Object.AcceptedFrom = Object.Counterparty.DescriptionFull;
		NeedToWriteObject = True;
	EndIf;
	
	CustomerInvoice = FindCreateCustomerInvoice(ExchangeNode, XDTOObject.Invoice, DocumentsForLatePosting, IsNewExchange);
	CustomerOrder = FindCreateCustomerOrder(ExchangeNode, XDTOObject.Order, DocumentsForLatePosting, IsNewExchange);
	
	BasisDocument = Undefined;
	If ValueIsFilled(CustomerOrder) Then
		BasisDocument = CustomerOrder;
	ElsIf ValueIsFilled(CustomerInvoice) Then
		BasisDocument = CustomerInvoice;
	EndIf;
	
	If ValueIsFilled(BasisDocument) Then
		// In the mobile client, it is impossible to delete or change an order; therefore, only a clean document of the foundation is filled in.
		Object.BasisDocument = BasisDocument;
		NeedToWriteObject = True;
	EndIf;
	
	Object.PaymentDetails.Clear();
	NeedToWriteObject = True;
	NewRow = Object.PaymentDetails.Add();
	ContractByDefault = FindCreateContractByDefault(
		Object.Ref,
		Object.Counterparty,
		Object.Company,
		Object.OperationKind,
		Enums.ContractKinds.WithCustomer
	);
	NewRow.Contract = ContractByDefault;
	Query = New Query(
		"SELECT CurrencyRatesSliceLast.Currency, CurrencyRatesSliceLast.ExchangeRate, CurrencyRatesSliceLast.Multiplicity FROM InformationRegister.CurrencyRates.SliceLast(&Period, Currency IN (&Currencies)) AS CurrencyRatesSliceLast"
	);
	
	Currencies = New Array();
	Currencies.Add(ContractByDefault.SettlementsCurrency);
	Currencies.Add(Object.CashCurrency);
	Query.SetParameter("Period", Object.Date);
	Query.SetParameter("Currencies", Currencies);
	CurrencyTable = Query.Execute().Unload();
	SettlementsCurrency = CurrencyTable.Find(ContractByDefault.SettlementsCurrency, "Currency");
	CashCurrency = CurrencyTable.Find(Object.CashCurrency, "Currency");
	
	If ValueIsFilled(SettlementsCurrency) Then
		NewRow.ExchangeRate = SettlementsCurrency.ExchangeRate;
		NewRow.Multiplicity = SettlementsCurrency.Multiplicity;
	Else
		NewRow.ExchangeRate = 1;
		NewRow.Multiplicity = 1;
	EndIf;
	
	NewRow.PaymentAmount = Object.DocumentAmount;
	If ValueIsFilled(CustomerInvoice) Then
		NewRow.Document = CustomerInvoice;
	Else
		NewRow.AdvanceFlag = True;
	EndIf;
	If ValueIsFilled(CustomerOrder) Then
		NewRow.Order = CustomerOrder;
	Else
		NewRow.Order = Object.BasisDocument;
	EndIf;
	
	If ValueIsFilled(CashCurrency) Then
		NewRow.SettlementsAmount = SmallBusinessServer.RecalculateFromCurrencyToCurrency(
			NewRow.PaymentAmount,
			CashCurrency.ExchangeRate,
			NewRow.ExchangeRate,
			CashCurrency.Multiplicity,
			NewRow.Multiplicity
		);
	Else
		NewRow.SettlementsAmount = SmallBusinessServer.RecalculateFromCurrencyToCurrency(
			NewRow.PaymentAmount,
			1,
			NewRow.ExchangeRate,
			1,
			NewRow.Multiplicity
		);
	EndIf;
	
	If Object.VATTaxation = Enums.VATTaxationTypes.TaxableByVAT Then
		DefaultVATRate = Object.Company.DefaultVATRate; 
	ElsIf Object.VATTaxation = Enums.VATTaxationTypes.NotTaxableByVAT Then
		DefaultVATRate = SmallBusinessReUse.GetVATRateWithoutVAT();
	Else
		DefaultVATRate = SmallBusinessReUse.GetVATRateZero();
	EndIf;
	
	NewRow.VATRate = DefaultVATRate;
	NewRow.VATAmount = NewRow.PaymentAmount - (NewRow.PaymentAmount) / ((NewRow.VATRate.Rate + 100) / 100);
	
	If XDTOObject.Properties().Get("Comment") <> Undefined
		AND Object.Comment <> XDTOObject.Comment Then
		Object.Comment = XDTOObject.Comment;
		NeedToWriteObject = True;
	EndIf;
	
	If XDTOObject.Properties().Get("CashFlowItem") <> Undefined Then
		CashFlow = FindCreateCashFlow(ExchangeNode, XDTOObject.CashFlowItem, IsNewExchange);
		If Object.Item <> CashFlow Then
			Object.Item = CashFlow;
			NeedToWriteObject = True;
		EndIf;
	EndIf;
	
	If NOT ValueIsFilled(Object.Item) Then
		Object.Item = Catalogs.CashFlowItems.PaymentFromCustomers;
		NeedToWriteObject = True;
	EndIf;
	
	WriteDocument(ExchangeNode, Object, XDTOObject, NeedToWriteObject, DocumentsForLatePosting);
	
	// If the number in the mobile application does not match the
	// order number in the central database, send back to synchronize the numbers.
	If XDTOObject.name = Object.Number Then
		ExchangePlans.DeleteChangeRecords(ExchangeNode, Object);
	EndIf;
	
	Return Object.Ref;
	
EndFunction // FindCreateCashReceipt()

Function FindCreateCustomerInvoice(ExchangeNode, XDTOObject, DocumentsForLatePosting, IsNewExchange)
	
	If XDTOObject = Undefined Then
		Return Documents.CustomerInvoice.EmptyRef();
	EndIf;
	
	Object = CreateDocument("CustomerInvoice", XDTOObject);
	
	If NOT Object.IsNew() Then // In order not to spoil the data do not refill the document.
		BreakFilling = ExchangeMobileApplicationCommon.ChangesToTabularSectionAreAvailable(Object, "Inventory");
		If BreakFilling Then
			Return Object.Ref;
		EndIf;
	EndIf;
	
	NeedToWriteObject = False;
	
	FillMainDocumentAttributes(Object, XDTOObject, NeedToWriteObject);
	
	If NOT ValueIsFilled(Object.OperationKind) Then
		Object.OperationKind = Enums.OperationKindsCustomerInvoice.SaleToCustomer;
		NeedToWriteObject = True;
	EndIf;
	
	If NOT ValueIsFilled(Object.Author) Then
		Object.Author = SmallBusinessReUse.GetValueByDefaultUser(
			Object.Author,
			"MainResponsible"
		);
		NeedToWriteObject = True;
	EndIf;
	
	If NOT ValueIsFilled(Object.DocumentCurrency) Then
		Object.DocumentCurrency = Constants.NationalCurrency.Get();
		NeedToWriteObject = True;
	EndIf;
	
	Counterparty = FindCreateCounterParties(ExchangeNode, XDTOObject.Buyer, IsNewExchange);
	If Object.Counterparty <> Counterparty Then
		Object.Counterparty = Counterparty;
		NeedToWriteObject = True;
	EndIf;
	If NOT ValueIsFilled(Object.Contract) Then
		ContractByDefault = FindCreateContractByDefault(
			Object.Ref,
			Object.Counterparty,
			Object.Company,
			Object.OperationKind,
			Enums.ContractKinds.WithCustomer
		);
		Object.Contract = ContractByDefault;
		Query = New Query(
			"SELECT
			|	CurrencyRatesSliceLast.ExchangeRate,
			|	CurrencyRatesSliceLast.Multiplicity
			|FROM
			|	InformationRegister.CurrencyRates.SliceLast(&Period, Currency = &Currency) AS CurrencyRatesSliceLast"
		);
		Query.SetParameter("Period", Object.Date);
		Query.SetParameter("Currency", Object.Contract.SettlementsCurrency);
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			Object.ExchangeRate = Selection.ExchangeRate;
			Object.Multiplicity = Selection.Multiplicity;
		Else
			Object.ExchangeRate = 1;
			Object.Multiplicity = 1;
		EndIf;
		NeedToWriteObject = True;
	EndIf;
	
	If NOT ValueIsFilled(Object.Department) Then
		Object.Department = SmallBusinessReUse.GetValueByDefaultUser(
			Object.Author,
			"MainDepartment"
		);
		Object.Department = ?(ValueIsFilled(Object.Department), Object.Department, Catalogs.StructuralUnits.MainDepartment);
		NeedToWriteObject = True;
	EndIf;
	
	If NOT ValueIsFilled(Object.StructuralUnit) Then
		Object.StructuralUnit = SmallBusinessReUse.GetValueByDefaultUser(
			Object.Author,
			"MainWarehouse"
		);
		Object.StructuralUnit = ?(ValueIsFilled(Object.StructuralUnit), Object.StructuralUnit, Catalogs.StructuralUnits.MainWarehouse);
		NeedToWriteObject = True;
	EndIf;
	
	If Object.IsNew() Then
		Object.PriceKind = SmallBusinessReUse.GetValueByDefaultUser(
			Object.Author,
			"MainPriceKindSales"
		);
		Object.PriceKind = ?(ValueIsFilled(Object.PriceKind), Object.PriceKind, Object.Contract.PriceKind);
		Object.PriceKind = ?(ValueIsFilled(Object.PriceKind), Object.PriceKind, Catalogs.PriceKinds.Wholesale);
		Object.AmountIncludesVAT = ?(ValueIsFilled(Object.PriceKind), Object.PriceKind.PriceIncludesVAT, True);
		
		SettingValue = SmallBusinessReUse.GetValueByDefaultUser(Users.CurrentUser(), "CustomerOrderPositionInShipmentDocuments");
		If ValueIsFilled(SettingValue) Then
			If Object.CustomerOrderPosition <> SettingValue Then
				Object.CustomerOrderPosition = SettingValue;
			EndIf;
		Else
			Object.CustomerOrderPosition = Enums.AttributePositionOnForm.InHeader;
		EndIf;
		
		NeedToWriteObject = True;
	EndIf;
	
	CustomerOrder = FindCreateCustomerOrder(ExchangeNode, XDTOObject.Order, DocumentsForLatePosting, IsNewExchange);
	If Object.BasisDocument <> CustomerOrder Then
		Object.BasisDocument = CustomerOrder;
		NeedToWriteObject = True;
	EndIf;
	If Object.Order <> CustomerOrder Then
		Object.Order = CustomerOrder;
		NeedToWriteObject = True;
	EndIf;
	
	If Object.Inventory.Count() > 0 Then
		Object.Inventory.Clear();
		NeedToWriteObject = True;
	EndIf;

	If XDTOObject.Items <> Undefined Then
		For Each CurRow In XDTOObject.Items.Item Do
			NewRow = Object.Inventory.Add();
			NewRow.ProductsAndServices = FindCreateProduct(ExchangeNode, CurRow.Nomenclature, IsNewExchange);
			NewRow.ProductsAndServicesTypeInventory = NewRow.ProductsAndServices.ProductsAndServicesType = Enums.ProductsAndServicesTypes.InventoryItem;
			NewRow.MeasurementUnit = NewRow.ProductsAndServices.MeasurementUnit;
			NewRow.Price = CurRow.Price;
			NewRow.Order = CustomerOrder;
			NewRow.Quantity = CurRow.Quantity;
			NewRow.Amount = CurRow.Total;
			NeedToWriteObject = True;
		EndDo;
	EndIf;
	
	If XDTOObject.Properties().Get("Comment") <> Undefined
		AND Object.Comment <> XDTOObject.Comment Then
		Object.Comment = XDTOObject.Comment;
		NeedToWriteObject = True;
	EndIf;
	
	DistributeAmountToDiscounts(Object.Inventory, XDTOObject.Discount);
	
	For Each CurRow In Object.Inventory Do
		CalculateAmoutsForRow(Object, CurRow);
	EndDo;
	
	WriteDocument(ExchangeNode, Object, XDTOObject, NeedToWriteObject, DocumentsForLatePosting);
	
	// If the number in the mobile application does not match the
	// order number in the central database, send back to synchronize the numbers.
	If XDTOObject.name = Object.Number Then
		ExchangePlans.DeleteChangeRecords(ExchangeNode, Object);
	EndIf;
	
	Return Object.Ref;
	
EndFunction // FindCreateCustomerInvoice()

Function FindCreateSupplierInvoice(ExchangeNode, XDTOObject, DocumentsForLatePosting, IsNewExchange)
	
	If XDTOObject = Undefined Then
		Return Documents.SupplierInvoice.EmptyRef();
	EndIf;
	
	Object = CreateDocument("SupplierInvoice", XDTOObject);
	If NOT Object.IsNew() Then // In order not to spoil the data do not refill the document.
		BreakFilling = ExchangeMobileApplicationCommon.ChangesToTabularSectionAreAvailable(Object, "Inventory")
			OR ExchangeMobileApplicationCommon.ChangesToTabularSectionAreAvailable(Object, "Expenses");
		If BreakFilling Then
			Return Object.Ref;
		EndIf;
	EndIf;
	
	NeedToWriteObject = False;
	
	FillMainDocumentAttributes(Object, XDTOObject, NeedToWriteObject);
	
	If NOT ValueIsFilled(Object.OperationKind) Then
		Object.OperationKind = Enums.OperationKindsSupplierInvoice.ReceiptFromVendor;
	EndIf;
	
	If NOT ValueIsFilled(Object.Author) Then
		Object.Author = SmallBusinessReUse.GetValueByDefaultUser(
			Object.Author,
			"MainResponsible"
		);
	EndIf;
	
	If NOT ValueIsFilled(Object.DocumentCurrency) Then
		Object.DocumentCurrency = Constants.NationalCurrency.Get();
		NeedToWriteObject = True;
	EndIf;
	
	Counterparty = FindCreateCounterParties(ExchangeNode, XDTOObject.Supplier, IsNewExchange);
	If Object.Counterparty <> Counterparty Then
		Object.Counterparty = Counterparty;
		NeedToWriteObject = True;
	EndIf;
	If NOT ValueIsFilled(Object.Contract) Then
		ContractByDefault = FindCreateContractByDefault(
			Object.Ref,
			Object.Counterparty,
			Object.Company,
			Object.OperationKind,
			Enums.ContractKinds.WithVendor
		);
		Object.Contract = ContractByDefault;
		Query = New Query(
			"SELECT
			|	CurrencyRatesSliceLast.ExchangeRate,
			|	CurrencyRatesSliceLast.Multiplicity
			|FROM
			|	InformationRegister.CurrencyRates.SliceLast(&Period, Currency = &Currency) AS CurrencyRatesSliceLast"
		);
		Query.SetParameter("Period", Object.Date);
		Query.SetParameter("Currency", Object.Contract.SettlementsCurrency);
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			Object.ExchangeRate = Selection.ExchangeRate;
			Object.Multiplicity = Selection.Multiplicity;
		Else
			Object.ExchangeRate = 1;
			Object.Multiplicity = 1;
		EndIf;
		NeedToWriteObject = True;
	EndIf;
	
	If NOT ValueIsFilled(Object.StructuralUnit) Then
		Object.StructuralUnit = SmallBusinessReUse.GetValueByDefaultUser(
			Object.Author,
			"MainWarehouse"
		);
		Object.StructuralUnit = ?(ValueIsFilled(Object.StructuralUnit), Object.StructuralUnit, Catalogs.StructuralUnits.MainWarehouse);
		NeedToWriteObject = True;
	EndIf;
	
	If Object.IsNew() Then
		Object.CounterpartyPriceKind = Object.Contract.CounterpartyPriceKind;
		Object.CounterpartyPriceKind = ?(ValueIsFilled(Object.CounterpartyPriceKind), Object.CounterpartyPriceKind, Catalogs.CounterpartyPriceKind.CounterpartyDefaultPriceKind(Object.Counterparty));
		Object.AmountIncludesVAT = ?(ValueIsFilled(Object.CounterpartyPriceKind), Object.CounterpartyPriceKind.PriceIncludesVAT, True);
		
		SettingValue = SmallBusinessReUse.GetValueByDefaultUser(Users.CurrentUser(), "PurchaseOrderPositionInReceiptDocuments");
		If ValueIsFilled(SettingValue) Then
			If Object.PurchaseOrderPosition <> SettingValue Then
				Object.PurchaseOrderPosition = SettingValue;
			EndIf;
		Else
			Object.PurchaseOrderPosition = Enums.AttributePositionOnForm.InHeader;
		EndIf;
		
		NeedToWriteObject = True;
	EndIf;
	
	If Object.Inventory.Count() > 0 Then
		Object.Inventory.Clear();
		NeedToWriteObject = True;
	EndIf;
	
	If Object.Expenses.Count() > 0 Then
		Object.Expenses.Clear();
		NeedToWriteObject = True;
	EndIf;
	
	If XDTOObject.Items <> Undefined Then
		For Each CurRow In XDTOObject.Items.Item Do
			Product = FindCreateProduct(ExchangeNode, CurRow.Nomenclature, IsNewExchange);
			If Product.ProductsAndServicesType = Enums.ProductsAndServicesTypes.Service Then
				NewRow = Object.Expenses.Add();
			Else
				NewRow = Object.Inventory.Add();
			EndIf;
			NewRow.ProductsAndServices = FindCreateProduct(ExchangeNode, CurRow.Nomenclature, IsNewExchange);
			NewRow.MeasurementUnit = NewRow.ProductsAndServices.MeasurementUnit;
			NewRow.Price = CurRow.Price;
			NewRow.Quantity = CurRow.Quantity;
			NewRow.Amount = CurRow.Total;
			CalculateAmoutsForRow(Object, NewRow);
			NeedToWriteObject = True;
		EndDo;
	EndIf;
	
	If XDTOObject.Properties().Get("Comment") <> Undefined
		AND Object.Comment <> XDTOObject.Comment Then
		Object.Comment = XDTOObject.Comment;
		NeedToWriteObject = True;
	EndIf;
	
	WriteDocument(ExchangeNode, Object, XDTOObject, NeedToWriteObject, DocumentsForLatePosting);
	
	// If the number in the mobile application does not match the
	// order number in the central database, send back to synchronize the numbers.
	If XDTOObject.name = Object.Number Then
		ExchangePlans.DeleteChangeRecords(ExchangeNode, Object);
	EndIf;
	
	Return Object.Ref;
	
EndFunction // FindCreateSupplierInvoice()

Function FindCreateInventoryAssembly(ExchangeNode, XDTOObject, DocumentsForLatePosting, IsNewExchange)
	
	If XDTOObject = Undefined Then
		Return Documents.InventoryAssembly.EmptyRef();
	EndIf;

	Object = CreateDocument("InventoryAssembly", XDTOObject);
	If NOT Object.IsNew() Then // In order not to spoil the data do not refill the document.
		BreakFilling = ExchangeMobileApplicationCommon.ChangesToTabularSectionAreAvailable(Object, "Products")
			OR ExchangeMobileApplicationCommon.ChangesToTabularSectionAreAvailable(Object, "Inventory");
		If BreakFilling Then
			Return Object.Ref;
		EndIf;
	EndIf;
	
	NeedToWriteObject = False;
	
	FillMainDocumentAttributes(Object, XDTOObject, NeedToWriteObject);
	
	If NOT ValueIsFilled(Object.OperationKind) Then
		Object.OperationKind = Enums.OperationKindsInventoryAssembly.Assembly;
		NeedToWriteObject = True;
	EndIf;
	
	StructuralUnitByDefault = SmallBusinessReUse.GetValueByDefaultUser(
		Object.Author,
		"MainWarehouse"
	);
	StructuralUnitByDefault = ?(ValueIsFilled(StructuralUnitByDefault), StructuralUnitByDefault, Catalogs.StructuralUnits.MainWarehouse);
	
	If NOT ValueIsFilled(Object.StructuralUnit) Then
		Object.StructuralUnit = StructuralUnitByDefault;
		NeedToWriteObject = True;
	EndIf;
	
	If NOT ValueIsFilled(Object.ProductsStructuralUnit) Then
		Object.ProductsStructuralUnit = StructuralUnitByDefault;
		NeedToWriteObject = True;
	EndIf;
	
	If NOT ValueIsFilled(Object.InventoryStructuralUnit) Then
		Object.InventoryStructuralUnit = StructuralUnitByDefault;
		NeedToWriteObject = True;
	EndIf;
	
	If NOT ValueIsFilled(Object.DisposalsStructuralUnit) Then
		Object.DisposalsStructuralUnit = StructuralUnitByDefault;
		NeedToWriteObject = True;
	EndIf;
	
	If Object.Products.Count() > 0 Then
		Object.Products.Clear();
		NeedToWriteObject = True;
	EndIf;
		
	If Object.Inventory.Count() > 0 Then
		Object.Inventory.Clear();
		NeedToWriteObject = True;
	EndIf;
	
	If XDTOObject.Products <> Undefined Then
		For Each CurRow In XDTOObject.Products.Item Do
			Product = FindCreateProduct(ExchangeNode, CurRow.Nomenclature, IsNewExchange);
			NewRow = Object.Products.Add();
			NewRow.ProductsAndServices = FindCreateProduct(ExchangeNode, CurRow.Nomenclature, IsNewExchange);
			NewRow.MeasurementUnit = NewRow.ProductsAndServices.MeasurementUnit;
			NewRow.Quantity = CurRow.Quantity;
			NeedToWriteObject = True;
		EndDo;
	EndIf;
	
	If XDTOObject.Materials <> Undefined Then
		For Each CurRow In XDTOObject.Materials.Item Do
			Product = FindCreateProduct(ExchangeNode, CurRow.Nomenclature, IsNewExchange);
			NewRow = Object.Inventory.Add();
			NewRow.ProductsAndServices = FindCreateProduct(ExchangeNode, CurRow.Nomenclature, IsNewExchange);
			NewRow.MeasurementUnit = NewRow.ProductsAndServices.MeasurementUnit;
			NewRow.Quantity = CurRow.Quantity;
			NeedToWriteObject = True;
		EndDo;
	EndIf;
	
	If XDTOObject.Properties().Get("Comment") <> Undefined
		AND Object.Comment <> XDTOObject.Comment Then
		Object.Comment = XDTOObject.Comment;
		NeedToWriteObject = True;
	EndIf;
	
	WriteDocument(ExchangeNode, Object, XDTOObject, NeedToWriteObject, DocumentsForLatePosting);
	
	// If the number in the mobile application does not match the
	// order number in the central database, send back to synchronize the numbers.
	If XDTOObject.name = Object.Number Then
		ExchangePlans.DeleteChangeRecords(ExchangeNode, Object);
	EndIf;
	
	Return Object.Ref;
	
EndFunction // FindCreateSupplierInvoice()

Function FindCreateReceiptCR(ExchangeNode, XDTOObject, DocumentsForLatePosting, IsNewExchange)
	
	If XDTOObject = Undefined Then
		Return Documents.ReceiptCR.EmptyRef();
	EndIf;
	
	Object = CreateDocument("ReceiptCR", XDTOObject);
	
	If NOT Object.IsNew() Then // In order not to spoil the data do not refill the document.
		BreakFilling = ExchangeMobileApplicationCommon.ChangesToTabularSectionAreAvailable(Object, "Inventory");
		If BreakFilling Then
			Return Object.Ref;
		EndIf;
	EndIf;
	
	NeedToWriteObject = False;
	
	FillMainDocumentAttributes(Object, XDTOObject, NeedToWriteObject);
	
	If NOT ValueIsFilled(Object.Author) Then
		Object.Author = SmallBusinessReUse.GetValueByDefaultUser(
			Object.Author,
			"MainResponsible"
		);
		NeedToWriteObject = True;
	EndIf;
	
	CashCRSession = FindCreateRetailReport(ExchangeNode, XDTOObject.RetailSalesReport, DocumentsForLatePosting, IsNewExchange);
	If Object.CashCRSession <> CashCRSession Then
		Object.CashCRSession = CashCRSession;
		NeedToWriteObject = True;
	EndIf;
	
	If ValueIsFilled(XDTOObject.CheckNumber) Then
		CheckNumber = Number(XDTOObject.CheckNumber);
	Else
		CheckNumber = 0;
	EndIf;
	
	If Object.ReceiptCRNumber <> CheckNumber Then
		Object.ReceiptCRNumber = CheckNumber;
		NeedToWriteObject = True;
	EndIf;
	
	Status = ?(Object.ReceiptCRNumber = 0, Enums.ReceiptCRStatuses.ReceiptIsNotIssued, Enums.ReceiptCRStatuses.Issued);
	If Object.Status <> Status Then
		Object.Status = Status;
		NeedToWriteObject = True;
	EndIf;
	
	If ValueIsFilled(XDTOObject.ShiftNumber) Then
		ShiftNumber = Number(XDTOObject.ShiftNumber);
	Else
		ShiftNumber = 0;
	EndIf;
		
	If Object.CashReceived <> XDTOObject.InCashTotal Then
		Object.CashReceived = XDTOObject.InCashTotal;
		NeedToWriteObject = True;
	EndIf;
	
	CashCR = FindCreateCashCR(ExchangeNode, XDTOObject.CashDesk, IsNewExchange);
	If Object.CashCR <> CashCR Then
		Object.CashCR = CashCR;
		NeedToWriteObject = True;
	EndIf;

	If NOT ValueIsFilled(Object.CashCR) Then
		CashCR = ExchangeMobileApplicationCommon.CashCRNode(ExchangeNode);
		Object.CashCR = CashCR;
		NeedToWriteObject = True;
	EndIf;
	
	If ValueIsFilled(Object.CashCR)
		AND NeedToWriteObject Then
		Object.Department = Object.CashCR.Department;
		Object.StructuralUnit = Object.CashCR.StructuralUnit;
	EndIf;
	
	If Object.IsNew() Then
		If ValueIsFilled(Object.StructuralUnit) Then
			Object.PriceKind = Object.StructuralUnit.RetailPriceKind;
		EndIf;
		
		If NOT ValueIsFilled(Object.PriceKind) Then
			Object.PriceKind = SmallBusinessReUse.GetValueByDefaultUser(
				Object.Author,
				"MainPriceKindSales"
			);
		EndIf;
		Object.PriceKind = ?(ValueIsFilled(Object.PriceKind), Object.PriceKind, Catalogs.PriceKinds.Wholesale);
		Object.AmountIncludesVAT = ?(ValueIsFilled(Object.PriceKind), Object.PriceKind.PriceIncludesVAT, True);
		
		NeedToWriteObject = True;
	EndIf;
	
	If Object.Inventory.Count() > 0 Then
		Object.Inventory.Clear();
		NeedToWriteObject = True;
	EndIf;

	If XDTOObject.Items <> Undefined Then
		For Each CurRow In XDTOObject.Items.Item Do
			NewRow = Object.Inventory.Add();
			NewRow.ProductsAndServices = FindCreateProduct(ExchangeNode, CurRow.Nomenclature, IsNewExchange);
			NewRow.MeasurementUnit = NewRow.ProductsAndServices.MeasurementUnit;
			NewRow.Price = CurRow.Price;
			NewRow.Quantity = CurRow.Quantity;
			NewRow.Amount = CurRow.Total;
			CalculateAmoutsForRow(Object, NewRow);
			NeedToWriteObject = True;
		EndDo;
	EndIf;
	
	If XDTOObject.Properties().Get("Comment") <> Undefined
		AND Object.Comment <> XDTOObject.Comment Then
		Object.Comment = XDTOObject.Comment;
		NeedToWriteObject = True;
	EndIf;
	
	WriteDocument(ExchangeNode, Object, XDTOObject, NeedToWriteObject, DocumentsForLatePosting);
	
	// If the number in the mobile application does not match the
	// order number in the central database, send back to synchronize the numbers.
	If XDTOObject.name = Object.Number Then
		ExchangePlans.DeleteChangeRecords(ExchangeNode, Object);
	EndIf;
	
	Return Object.Ref;
	
EndFunction // FindCreateReceiptCR()

Function FindCreateReceiptCRReturn(ExchangeNode, XDTOObject, DocumentsForLatePosting, IsNewExchange)
	
	If XDTOObject = Undefined Then
		Return Documents.ReceiptCRReturn.EmptyRef();
	EndIf;
	
	Object = CreateDocument("ReceiptCRReturn", XDTOObject);
	
	If NOT Object.IsNew() Then // In order not to spoil the data do not refill the document.
		BreakFilling = ExchangeMobileApplicationCommon.ChangesToTabularSectionAreAvailable(Object, "Inventory");
		If BreakFilling Then
			Return Object.Ref;
		EndIf;
	EndIf;
	
	NeedToWriteObject = False;
	
	FillMainDocumentAttributes(Object, XDTOObject, NeedToWriteObject);
	
	If NOT ValueIsFilled(Object.Author) Then
		Object.Author = SmallBusinessReUse.GetValueByDefaultUser(
			Object.Author,
			"MainResponsible"
		);
		NeedToWriteObject = True;
	EndIf;
	
	CashCRSession = FindCreateRetailReport(ExchangeNode, XDTOObject.RetailSalesReport, DocumentsForLatePosting, IsNewExchange);
	If Object.CashCRSession <> CashCRSession Then
		Object.CashCRSession = CashCRSession;
		NeedToWriteObject = True;
	EndIf;
	
	If ValueIsFilled(XDTOObject.CheckNumber) Then
		CheckNumber = Number(XDTOObject.CheckNumber);
	Else
		CheckNumber = 0;
	EndIf;
	
	If Object.ReceiptCRNumber <> CheckNumber Then
		Object.ReceiptCRNumber = CheckNumber;
		NeedToWriteObject = True;
	EndIf;
	
	If ValueIsFilled(XDTOObject.ShiftNumber) Then
		ShiftNumber = Number(XDTOObject.ShiftNumber);
	Else
		ShiftNumber = 0;
	EndIf;
	
	CashCR = FindCreateCashCR(ExchangeNode, XDTOObject.CashDesk, IsNewExchange);
	If Object.CashCR <> CashCR Then
		Object.CashCR = CashCR;
		NeedToWriteObject = True;
	EndIf;

	If NOT ValueIsFilled(Object.CashCR) Then
		CashCR = ExchangeMobileApplicationCommon.CashCRNode(ExchangeNode);
		Object.CashCR = CashCR;
		NeedToWriteObject = True;
	EndIf;
	
	If ValueIsFilled(Object.CashCR)
		AND NeedToWriteObject Then
		Object.Department = Object.CashCR.Department;
		Object.StructuralUnit = Object.CashCR.StructuralUnit;
	EndIf;
	
	CashReceipt = FindCreateCashReceipt(ExchangeNode, XDTOObject.CashReceipt, DocumentsForLatePosting, IsNewExchange);
	
	If Object.ReceiptCR <> CashReceipt Then
		Object.ReceiptCR = CashReceipt;
		NeedToWriteObject = True;
	EndIf;
	
	If Object.IsNew() Then
		If ValueIsFilled(Object.StructuralUnit) Then
			Object.PriceKind = Object.StructuralUnit.RetailPriceKind;
		EndIf;
		
		If NOT ValueIsFilled(Object.PriceKind) Then
			Object.PriceKind = SmallBusinessReUse.GetValueByDefaultUser(
				Object.Author,
				"MainPriceKindSales"
			);
		EndIf;
		Object.PriceKind = ?(ValueIsFilled(Object.PriceKind), Object.PriceKind, Catalogs.PriceKinds.Wholesale);
		Object.AmountIncludesVAT = ?(ValueIsFilled(Object.PriceKind), Object.PriceKind.PriceIncludesVAT, True);
		
		NeedToWriteObject = True;
	EndIf;
	
	If Object.Inventory.Count() > 0 Then
		Object.Inventory.Clear();
		NeedToWriteObject = True;
	EndIf;

	If XDTOObject.Items <> Undefined Then
		For Each CurRow In XDTOObject.Items.Item Do
			NewRow = Object.Inventory.Add();
			NewRow.ProductsAndServices = FindCreateProduct(ExchangeNode, CurRow.Nomenclature, IsNewExchange);
			NewRow.MeasurementUnit = NewRow.ProductsAndServices.MeasurementUnit;
			NewRow.Price = CurRow.Price;
			NewRow.Quantity = CurRow.Quantity;
			NewRow.Amount = CurRow.Total;
			CalculateAmoutsForRow(Object, NewRow);
			NeedToWriteObject = True;
		EndDo;
	EndIf;
	
	If XDTOObject.Properties().Get("Comment") <> Undefined
		AND Object.Comment <> XDTOObject.Comment Then
		Object.Comment = XDTOObject.Comment;
		NeedToWriteObject = True;
	EndIf;
	
	WriteDocument(ExchangeNode, Object, XDTOObject, NeedToWriteObject, DocumentsForLatePosting);
	
	// If the number in the mobile application does not match the
	// order number in the central database, send back to synchronize the numbers.
	If XDTOObject.name = Object.Number Then
		ExchangePlans.DeleteChangeRecords(ExchangeNode, Object);
	EndIf;
	
	Return Object.Ref;
	
EndFunction // FindCreateReceiptCRReturn()

Function FindCreateRetailReport(ExchangeNode, XDTOObject, DocumentsForLatePosting, IsNewExchange)
	
	If XDTOObject = Undefined Then
		Return Documents.RetailReport.EmptyRef();
	EndIf;
	
	Object = CreateDocument("RetailReport", XDTOObject);
	
	If NOT Object.IsNew() Then // In order not to spoil the data do not refill the document.
		BreakFilling = ExchangeMobileApplicationCommon.ChangesToTabularSectionAreAvailable(Object, "Inventory");
		If BreakFilling Then
			Return Object.Ref;
		EndIf;
	EndIf;
	
	NeedToWriteObject = False;
	NeedToWriteCashCRSession = False;
	
	FillMainDocumentAttributes(Object, XDTOObject, NeedToWriteObject);
	
	CashCR = FindCreateCashCR(ExchangeNode, XDTOObject.CashDesk, IsNewExchange);
	If Object.CashCR <> CashCR Then
		Object.CashCR = CashCR;
		NeedToWriteObject = True;
	EndIf;

	If NOT ValueIsFilled(Object.CashCR) Then
		CashCR = ExchangeMobileApplicationCommon.CashCRNode(ExchangeNode);
		Object.CashCR = CashCR;
		NeedToWriteObject = True;
	EndIf;
	
	If ValueIsFilled(Object.CashCR)
		AND NeedToWriteObject Then
		Object.Department = Object.CashCR.Department;
		Object.StructuralUnit = Object.CashCR.StructuralUnit;
	EndIf;

	If XDTOObject.Status = "Open" Then
		CashCRSessionStatus = Enums.CashCRSessionStatuses.IsOpen;
	Else
		CashCRSessionStatus = Enums.CashCRSessionStatuses.Closed;
	EndIf;
	
	If Object.CashCRSessionStatus <> CashCRSessionStatus
		AND Object.CashCRSessionStatus <> Enums.CashCRSessionStatuses.ClosedReceiptsArchived Then
		Object.CashCRSessionStatus = CashCRSessionStatus;
		NeedToWriteObject = True;
	EndIf;
	
	If Object.CashCRSessionStart <> XDTOObject.DateBegin Then
		Object.CashCRSessionStart = XDTOObject.DateBegin;
		NeedToWriteObject = True;
	EndIf;
	
	If Object.CashCRSessionEnd <> XDTOObject.DateEnd Then
		Object.CashCRSessionEnd = XDTOObject.DateEnd;
		NeedToWriteObject = True;
	EndIf;
	
	If NOT ValueIsFilled(Object.Item) Then
		Object.Item = Catalogs.CashFlowItems.PaymentFromCustomers;
	EndIf;
	
	If NOT ValueIsFilled(Object.Author) Then
		Object.Author = SmallBusinessReUse.GetValueByDefaultUser(
			Object.Author,
			"MainResponsible"
		);
		NeedToWriteObject = True;
	EndIf;
	
	If Object.IsNew() Then
		If ValueIsFilled(Object.StructuralUnit) Then
			Object.PriceKind = Object.StructuralUnit.RetailPriceKind;
		EndIf;
		
		If NOT ValueIsFilled(Object.PriceKind) Then
			Object.PriceKind = SmallBusinessReUse.GetValueByDefaultUser(
				Object.Author,
				"MainPriceKindSales"
			);
		EndIf;
		Object.PriceKind = ?(ValueIsFilled(Object.PriceKind), Object.PriceKind, Catalogs.PriceKinds.Wholesale);
		Object.AmountIncludesVAT = ?(ValueIsFilled(Object.PriceKind), Object.PriceKind.PriceIncludesVAT, True);
		
		NeedToWriteObject = True;
	EndIf;
	
	If Object.Inventory.Count() > 0 Then
		Object.Inventory.Clear();
		NeedToWriteObject = True;
	EndIf;

	If XDTOObject.Items <> Undefined Then
		For Each CurRow In XDTOObject.Items.Item Do
			NewRow = Object.Inventory.Add();
			NewRow.ProductsAndServices = FindCreateProduct(ExchangeNode, CurRow.Nomenclature, IsNewExchange);
			NewRow.MeasurementUnit = NewRow.ProductsAndServices.MeasurementUnit;
			NewRow.Price = CurRow.Price;
			NewRow.Quantity = CurRow.Quantity;
			NewRow.Amount = CurRow.Total;
			CalculateAmoutsForRow(Object, NewRow);
			NeedToWriteObject = True;
		EndDo;
	EndIf;
	
	If XDTOObject.Properties().Get("Comment") <> Undefined
		AND Object.Comment <> XDTOObject.Comment Then
		Object.Comment = XDTOObject.Comment;
		NeedToWriteObject = True;
	EndIf;
	
	WriteDocument(ExchangeNode, Object, XDTOObject, NeedToWriteObject, DocumentsForLatePosting);
	
	// If the number in the mobile application does not match the
	// order number in the central database, send back to synchronize the numbers.
	If XDTOObject.name = Object.Number Then
		ExchangePlans.DeleteChangeRecords(ExchangeNode, Object);
	EndIf;
	
	Return Object.Ref;
	
EndFunction // FindCreateRetailReport()

#EndRegion

#Region InformationRegisters

Procedure FindCreateProductBarcode(Product, Barcode)
	
	ProductBarcode = InformationRegisters.ProductsAndServicesBarcodes.GetBarcodeByProduct(Product);
	
	If Barcode = ProductBarcode Then
		Return;
	EndIf;
	
	If ValueIsFilled(ProductBarcode) Then
		RecordSet = InformationRegisters.ProductsAndServicesBarcodes.CreateRecordSet();
		RecordSet.Filter.Barcode.Set(ProductBarcode);
		RecordSet.Write(True);
	EndIf;
	
	If ValueIsFilled(Barcode) Then
		RecordSet = InformationRegisters.ProductsAndServicesBarcodes.CreateRecordSet();
		RecordSet.Filter.Barcode.Set(Barcode);
		NewRecord = RecordSet.Add();
		NewRecord.Barcode = Barcode;
		NewRecord.ProductsAndServices = Product;
		RecordSet.Write(True);
	EndIf;
	
EndProcedure // FindCreateProductBarcode()

Function ImportPrices(ExchangeNode, XDTOObject, IsNewExchange)
	
	If XDTOObject = Undefined Then
		Return Undefined;
	EndIf;
	
	User = Users.CurrentUser();
	PriceKind = SmallBusinessReUse.GetValueByDefaultUser(
		User,
		"MainPriceKindSales"
	);
		
	If Not ValueIsFilled(PriceKind) Then
		PriceKind = Catalogs.PriceKinds.Wholesale;
	EndIf;
		
	Product = FindCreateProduct(ExchangeNode, XDTOObject.Nomenclature, IsNewExchange);
	
	RecordSet = InformationRegisters.ProductsAndServicesPrices.CreateRecordSet();
	RecordSet.Filter.Period.Set(XDTOObject.Date);
	RecordSet.Filter.PriceKind.Set(PriceKind);
	RecordSet.Filter.ProductsAndServices.Set(Product);
	RecordSet.Filter.Characteristic.Set(Catalogs.ProductsAndServicesCharacteristics.EmptyRef());
	
	NewRecord = RecordSet.Add();
	NewRecord.Period = XDTOObject.Date;
	NewRecord.PriceKind = PriceKind;
	NewRecord.ProductsAndServices = Product;
	NewRecord.Price = XDTOObject.Price;
	NewRecord.Active = True;
	NewRecord.MeasurementUnit = CommonUse.GetAttributeValue(Product, "MeasurementUnit");
	NewRecord.Author = User;
	
	RecordSet.Write();
	
	ExchangePlans.DeleteChangeRecords(ExchangeNode, RecordSet);
	
EndFunction // ImportPrices()

#EndRegion

#Region Enums

Function FindProductType(XDTOObject)
	
	If XDTOObject = Undefined Then
		Return Enums.ProductsAndServicesTypes.EmptyRef();
	EndIf;
	
	If XDTOObject = "Product" Then
		Object = Enums.ProductsAndServicesTypes.InventoryItem;
	Else
		Object = Enums.ProductsAndServicesTypes.Service;
	EndIf;
	
	Return Object;
	
EndFunction // FindProductType()

Function FindCustomerOrderStates(ObjectXDTO)
	
	If ObjectXDTO = Undefined Then
		Return Catalogs.CustomerOrderStates.EmptyRef();
	EndIf;
	
	If ObjectXDTO = "Open" Then
		OrderStatus = Enums.OrderStatuses.Open;
	ElsIf ObjectXDTO = "InProcess" Then
		OrderStatus = Enums.OrderStatuses.InProcess;	
	ElsIf ObjectXDTO = "Complete" Then
		OrderStatus = Enums.OrderStatuses.Completed;		
	ElsIf ObjectXDTO = "Closed" Then
		OrderStatus = Enums.OrderStatuses.Closed;
	Else	
		OrderStatus = Enums.OrderStatuses.EmptyRef();
	EndIf; 
	
	OrderState = Undefined;
	
	Query = New Query;
	Query.Text = 
		"SELECT TOP 1
		|	CustomerOrderStates.Ref
		|FROM
		|	Catalog.CustomerOrderStates AS CustomerOrderStates
		|WHERE
		|	CustomerOrderStates.OrderStatus = &OrderStatus";
	
	Query.SetParameter("OrderStatus", OrderStatus);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		OrderState = Selection.Ref;	
	EndIf; 	
	
	Return OrderState;
	
EndFunction // FindCustomerOrderStates()

#EndRegion

#Region ServiceProceduresAndFunctions

Function CreateDocument(DocumentName, XDTOObject)
	
	ID = New UUID(XDTOObject.Id);
	Ref = Documents[DocumentName].GetRef(ID);
	Object = Ref.GetObject();
	If Object = Undefined Then
		Object = Documents[DocumentName].CreateDocument();
		Object.SetNewObjectRef(Ref);
	EndIf;
	
	Return Object;
	
EndFunction // CreateDocument()

Procedure WriteDocument(ExchangeNode, Object, XDTOObject, NeedToWriteObject, DocumentsForLatePosting)
	
	If NeedToWriteObject Then
		
		Object.DeletionMark = XDTOObject.DeletionMark;
		
		WriteMode = DocumentWriteMode.Posting;
		If Not XDTOObject.Posted Then
			WriteMode = DocumentWriteMode.UndoPosting;
		EndIf;
		
		If Object.DeletionMark
			AND (WriteMode = DocumentWriteMode.Posting) Then
			
			Object.DeletionMark = False;
			
		EndIf;
		
		If NOT ValueIsFilled(Object.Number) Then
			
			Object.SetNewNumber();
			
		EndIf;
		
		Object.DataExchange.Load = True;
		Try
			
			If Not Object.Posted Then
				Object.Write();
			Else
				// cancel the document
				Object.Posted = False;
				Object.Write();
				DeleteRegisterRecords(Object);
			EndIf;
			
		Except
			
			Raise DetailErrorDescription(ErrorInfo());
			
		EndTry;
		
		If WriteMode = DocumentWriteMode.Posting Then
			
			If DocumentsForLatePosting.Find(Object.Ref, "DocumentRef") = Undefined Then
				Row = DocumentsForLatePosting.Add();
				Row.DocumentRef = Object.Ref;
				Row.DocumentType = Object.Metadata().Name;
				Row.Order = Number(TypeOf(Object) = Type("DocumentObject.CustomerOrder"));
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure // WriteDocument()

Procedure FillMainDocumentAttributes(Object, XDTOObject, NeedToWriteObject)
	
	If Object.Date <> XDTOObject.Date Then
		Object.Date = XDTOObject.Date;
		NeedToWriteObject = True;
	EndIf;
	If TypeOf(Object.Ref) <> Type("DocumentRef.InventoryAssembly")
		AND Object.DocumentAmount <> XDTOObject.Total Then
		Object.DocumentAmount = XDTOObject.Total;
		NeedToWriteObject = True;
	EndIf;
	If NOT ValueIsFilled(Object.Author) Then
		Object.Author = Users.CurrentUser();
		NeedToWriteObject = True;
	EndIf;
	If NOT ValueIsFilled(Object.Company) Then
		MainCompany = SmallBusinessReUse.GetValueByDefaultUser(
			Object.Author,
			"MainCompany"
		);
		Object.Company = ?(ValueIsFilled(MainCompany), MainCompany, Catalogs.Companies.CompanyByDefault());
		NeedToWriteObject = True;
	EndIf;
	If TypeOf(Object.Ref) <> Type("DocumentRef.InventoryAssembly")
		AND NOT ValueIsFilled(Object.VATTaxation) Then
		Object.VATTaxation = SmallBusinessServer.VATTaxation(Object.Company, , Object.Date);
		NeedToWriteObject = True;
	EndIf;
	
EndProcedure // FillMainDocumentAttributes()

Procedure DeleteRegisterRecords(DocumentObject)
	
	ArrayOfTableRowsOfRegisterRecords = New Array();
	
	// getting the list of registers for which there are movements
	TableRecords = FindRegisterRecordsByDocument(DocumentObject.Ref);
	TableRecords.Columns.Add("RegisterSet");
		
	For Each Row In TableRecords Do
		// the register name is passed as a
		// value obtained using the FullName () function of the register metadata
		PointPosition = StrFind(Row.Name, ".");
		RegisterKind = Left(Row.Name, PointPosition - 1);
		RegisterName = TrimR(Mid(Row.Name, PointPosition + 1));

		ArrayOfTableRowsOfRegisterRecords.Add(Row);
		
		If RegisterKind = "AccumulationRegister" Then
			SetMetadata = Metadata.AccumulationRegisters[RegisterName];
			Set = AccumulationRegisters[RegisterName].CreateRecordSet();
			
		ElsIf RegisterKind = "AccountingRegister" Then
			SetMetadata = Metadata.AccountingRegisters[RegisterName];
			Set = AccountingRegisters[RegisterName].CreateRecordSet();
			
		ElsIf RegisterKind = "InformationRegister" Then
			SetMetadata = Metadata.InformationRegisters[RegisterName];
			Set = InformationRegisters[RegisterName].CreateRecordSet();
			
		ElsIf RegisterKind = "CalculationRegister" Then
			SetMetadata = Metadata.CalculationRegisters[RegisterName];
			Set = CalculationRegisters[RegisterName].CreateRecordSet();
			
		EndIf;
		
		If NOT AccessRight("Update", Set.Metadata()) Then
			// no rights to the entire register table
			Raise NStr("en='Access violation: ';ru='Нарушение прав доступа: ';vi='Vi phạm quyền truy cập:'") + Row.Name;
			Return;
		EndIf;

		Set.Filter.Recorder.Set(DocumentObject.Ref);

		// the set is not recorded immediately so as not
		// to roll back the transaction, if it later turns out that one of the registers does not have enough rights.
		Row.RegisterSet = Set;
		
	EndDo;	
	
	For Each Row In ArrayOfTableRowsOfRegisterRecords Do		
		Try
			Row.RegisterSet.Write();
		Except
			// possibly “triggered” RLS or change prohibit date subsystem
			Raise NStr("en='Operation failed: ';ru='Операция не выполнена: ';vi='Chưa thực hiện giao dịch:'") + Row.Name + Chars.LF + BriefErrorDescription(ErrorInfo());
		EndTry;
	EndDo;
	
	ClearingRegisterRecords(DocumentObject);
	
EndProcedure // DeleteRegisterRecords()

Procedure ClearingRegisterRecords(DocumentObject)
		
	For Each Record In DocumentObject.RegisterRecords Do
		If Record.Count() > 0 Then
			Record.Clear();
		EndIf;
	EndDo;
	
EndProcedure // ClearingRegisterRecords()

Function FindRegisterRecordsByDocument(DocumentRef)
	
	SetPrivilegedMode(True);
	
	QueryText = "";
	// to exclude crashes for documents held on more than 256 tables
	Counter_table = 0;
	
	DocumentMetadata = DocumentRef.Metadata();
	
	If DocumentMetadata.RegisterRecords.Count() = 0 Then
		Return New ValueTable;
	EndIf;
	
	For Each Record In DocumentMetadata.RegisterRecords Do
		// in the request, we get the names of the registers for
		// which
		// there is at least
		// one movement,
		// for example, SELECT First 1 “AccumulationRegister.ProductsInStores” FROM Accumulation Register = &Register
		
		// register name cast to String (200), see below.
		QueryText = QueryText + "
		|" + ?(QueryText = "", "", "UNION ALL ") + "
		|SELECT TOP 1 CAST(""" + Record.FullName() 
		+  """ AS String(200)) AS Name FROM " + Record.FullName() 
		+ " WHERE Recorder = &Recorder";
		
		// if more than 256 tables are included
		// in the query, we divide it into two parts
		Counter_table = Counter_table + 1;
		If Counter_table = 256 Then
			Break;
		EndIf;
		
	EndDo;
	
	Query = New Query(QueryText);
	Query.SetParameter("Recorder", DocumentRef);
	// when unloading for the “Name” column, the type is set according to
	// the longest row from the query during the second pass through the table, the new
	// name may not “climb”; therefore, the query (200) is immediately listed in the query
	Table = Query.Execute().Unload();
	
	// if the number of tables does not exceed 256 - we return the table
	If Counter_table = DocumentMetadata.RegisterRecords.Count() Then
		Return Table;			
	EndIf;
	
	// tables more than 256, we do add. query and complement table rows.
	
	QueryText = "";
	For Each Record In DocumentMetadata.RegisterRecords Do
		
		If Counter_table > 0 Then
			Counter_table = Counter_table - 1;
			Continue;
		EndIf;
		
		QueryText = QueryText + "
		|" + ?(QueryText = "", "", "UNION ALL ") + "
		|SELECT TOP 1 """ + Record.FullName() +  """ AS Name FROM " 
		+ Record.FullName() + " WHERE Recorder = &Recorder";	
		
		
	EndDo;
	Query.Text = QueryText;
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Row = Table.Add();
		FillPropertyValues(Row, Selection);
	EndDo;
	
	Return Table;
	
EndFunction // FindRegisterRecordsByDocument()

Function SetDeletionMark(ExchangeNode, XDTOObject)
	
	If XDTOObject = Undefined Then
		Return Undefined;
	EndIf;
	
	ID = New UUID(XDTOObject.Id);
	
	If XDTOObject.Type = "CatContractors" Then
		Return Undefined;
	ElsIf XDTOObject.Type = "CatItems" Then
		Return Undefined;
	ElsIf XDTOObject.Type = "CatStructuralUnit" Then
		Return Undefined;
	ElsIf XDTOObject.Type = "DocOrders" Then
		Ref = Documents.CustomerOrder.GetRef(ID);
	ElsIf XDTOObject.Type = "DocInvoice" Then
		Ref = Documents.CustomerInvoice.GetRef(ID);
	ElsIf XDTOObject.Type = "DocPurshareInvoice" Then
		Ref = Documents.SupplierInvoice.GetRef(ID);
	ElsIf XDTOObject.Type = "DocIncomingPayment" Then
		Ref = Documents.CashReceipt.GetRef(ID);
	ElsIf XDTOObject.Type = "DocOutgoingPayment" Then
		Ref = Documents.CashPayment.GetRef(ID);
	ElsIf XDTOObject.Type = "DocProduction" Then
		Ref = Documents.InventoryAssembly.GetRef(ID);
	ElsIf XDTOObject.Type = "DocCashReceipt" Then
		Ref = Documents.ReceiptCR.GetRef(ID);
	ElsIf XDTOObject.Type = "DocCashReceiptReturn" Then
		Ref = Documents.ReceiptCRReturn.GetRef(ID);
	ElsIf XDTOObject.Type = "DocRetailSalesReport" Then
		Ref = Documents.RetailReport.GetRef(ID);
	EndIf;
	
	Try
		Object = Ref.GetObject();
		Object.SetDeletionMark(True);
		ExchangePlans.DeleteChangeRecords(ExchangeNode, Object);
	Except
	EndTry;
	
EndFunction // SetDeletionMark()

Procedure RunLatePosting(ExchangeNode, DocumentsForLatePosting)

	DocumentsForLatePosting.Sort("Order Desc, DocumentType");
	
	For Each Row In DocumentsForLatePosting Do
		
		If Row.DocumentRef.IsEmpty() Then
			Continue;
		EndIf;
		
		Object = Row.DocumentRef.GetObject();
		
		If Object = Undefined Then
			Continue;
		EndIf;
		
		RemoveRegistrationChanges = Not ExchangePlans.IsChangeRecorded(ExchangeNode, Object);
		Object.DataExchange.Load = False;
		
		Try
			
			Object.CheckFilling();
			Object.Write(DocumentWriteMode.Posting);
			
			If RemoveRegistrationChanges Then
				ExchangePlans.DeleteChangeRecords(ExchangeNode, Object);
			EndIf;
			
		Except
		EndTry;
		
	EndDo;

EndProcedure // RunLatePosting()

Function FindCreateContractByDefault(Document, Counterparty, Company, OperationKind, ContractKind)
	
	If NOT Counterparty.DoOperationsByContracts Then
		Return Catalogs.CounterpartyContracts.ContractByDefault(Counterparty);
	EndIf;
	
	CatalogManager = Catalogs.CounterpartyContracts;
	
	ContractKindsList = CatalogManager.GetContractKindsListForDocument(Document, OperationKind);
	ContractByDefault = CatalogManager.GetDefaultContractByCompanyContractKind(Counterparty, Company, ContractKindsList);
	
	If NOT ValueIsFilled(ContractByDefault) Then
		ContractByDefault = CreateContractByDefault(Counterparty, Company, ContractKind);
	EndIf;
	
	Return ContractByDefault;
	
EndFunction // ContractByDefault()

Function CreateContractByDefault(Counterparty, Company, ContractKind)
	
	If NOT ValueIsFilled(Counterparty) Then
		Return Catalogs.CounterpartyContracts.EmptyRef();
	EndIf;
	
	SetPrivilegedMode(True);
	
	NewContract = Catalogs.CounterpartyContracts.CreateItem();
	
	Description = NStr("en='Main contract';ru='MainContract';vi='Hợp đồng chính'");
	Description = Description + " (" + String(ContractKind) + ")";
	NewContract.Description = Description;
	NewContract.SettlementsCurrency = Constants.NationalCurrency.Get();
	NewContract.Company = Company;
	NewContract.ContractKind = ContractKind;
	NewContract.PriceKind = Catalogs.PriceKinds.Wholesale;
	NewContract.Owner = Counterparty;
	NewContract.VendorPaymentDueDate = Constants.VendorPaymentDueDate.Get();
	NewContract.CustomerPaymentDueDate = Constants.CustomerPaymentDueDate.Get();
	
	// Fill the price kind of the counterparty
	NewCounterpartyPriceKind = Catalogs.CounterpartyPriceKind.CounterpartyDefaultPriceKind(Counterparty);
	
	If NOT ValueIsFilled(NewCounterpartyPriceKind) Then 
		
		NewCounterpartyPriceKind = Catalogs.CounterpartyPriceKind.FindAnyFirstKindOfCounterpartyPrice(Counterparty);
		
		If NOT ValueIsFilled(NewCounterpartyPriceKind) Then
			
			NewCounterpartyPriceKind = Catalogs.CounterpartyPriceKind.CreateCounterpartyPriceKind(
				Counterparty,
				NewContract.SettlementsCurrency
			);
			
		EndIf;
		
	EndIf;
	
	NewContract.CounterpartyPriceKind = NewCounterpartyPriceKind;
	
	NewContract.Write();
	
	SetPrivilegedMode(False);
	
	Return NewContract.Ref;
	
EndFunction // CreateContractByDefault()

Procedure CalculateAmoutsForRow(Object, NewRow)
	
	If Object.VATTaxation <> Enums.VATTaxationTypes.TaxableByVAT Then
		If Object.VATTaxation = Enums.VATTaxationTypes.NotTaxableByVAT Then
			NewRow.VATRate = SmallBusinessReUse.GetVATRateWithoutVAT();
		Else
			NewRow.VATRate = SmallBusinessReUse.GetVATRateZero();
		EndIf;
	ElsIf ValueIsFilled(NewRow.ProductsAndServices.VATRate) Then
		NewRow.VATRate = NewRow.ProductsAndServices.VATRate;
	Else
		NewRow.VATRate = Object.Company.DefaultVATRate;
	EndIf;
	
	VATRate = SmallBusinessReUse.GetVATRateValue(NewRow.VATRate);
	NewRow.VATAmount = ?(
		Object.AmountIncludesVAT,
		NewRow.Amount - (NewRow.Amount) / ((VATRate + 100) / 100),
		NewRow.Amount * VATRate / 100
	);
	NewRow.Total = NewRow.Amount + ?(Object.AmountIncludesVAT, 0, NewRow.VATAmount);
	
EndProcedure // РассчитатьСуммуВСтрокеТабличнойЧасти()

// Distributes the amount of the column table.
Procedure DistributeAmountToDiscounts(Table, AmountOfDistribution)
	
	// Calculate the total amount of marked positions.
	TotalSum = 0;
	For Each Row In Table Do
		TotalSum = TotalSum + Row.Price * Row.Quantity;
	EndDo;
	
	If TotalSum = 0 Then
		Return;
	EndIf;
	
	DiscountPercent = AmountOfDistribution / TotalSum * 100;
	
	TotalDiscountSum = 0;
	TotalSumWithoutDiscount = 0;
	LastString = Undefined;
	For Each Row In Table Do
		
		Row.DiscountMarkupPercent = DiscountPercent;
		RowSumWithoutDiscount = Row.Price * Row.Quantity;
		DiscountSum = RowSumWithoutDiscount * DiscountPercent / 100;

		Row.Amount = RowSumWithoutDiscount - DiscountSum;
		TotalDiscountSum = TotalDiscountSum + DiscountSum;
		
		LastString = Row;
	EndDo;
	
	RemainingSum = AmountOfDistribution - TotalDiscountSum; 
	If LastString <> Undefined AND RemainingSum <> 0 Then

		RowSumWithoutDiscount = Row.Price * Row.Quantity;
		LastString.DiscountMarkupPercent = (Row.Price * Row.Quantity 
			* Row.DiscountMarkupPercent/100 
			+ RemainingSum) / RowSumWithoutDiscount * 100;
			
		Row.Amount = RowSumWithoutDiscount - DiscountSum;
	EndIf;
	
EndProcedure

#EndRegion