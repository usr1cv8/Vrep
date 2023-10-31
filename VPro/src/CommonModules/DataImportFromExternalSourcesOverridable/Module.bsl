
Function MaximumOfUsefulColumnsTableDocument() Export
	
	// Most attributes contains catalog Counterparties (30 useful) + 10 CI + Additional attributes.
	// The remaining cells are checked in DataImportFromExternalSources.OptimizeSpreadsheetDocument();
	
	Return 30 + 10 + MaximumOfAdditionalAttributesTableDocument();
	
EndFunction

Function MaximumOfAdditionalAttributesTableDocument() Export
	
	Return 10;
	
EndFunction

Procedure AddConditionalMatchTablesDesign(ThisObject, AttributePath, DataLoadSettings) Export
	
	If DataLoadSettings.IsTabularSectionImport Then
		
		Return;
		
	ElsIf DataLoadSettings.IsCatalogImport Then
		
		If DataLoadSettings.FillingObjectFullName = "Catalog.Products" Then
			
			FieldName = "Products";
			
		ElsIf DataLoadSettings.FillingObjectFullName = "Catalog.Counterparties" Then
			
			FieldName = "Counterparty";
			
		EndIf;
		
		TextNewItem	= NStr("en='<New item will be created>';ru='<Будет создан новый элемент>';vi='<Sẽ tạo phần tử mới>'");
		TextSkipped	= NStr("en='<Data will be skipped>';ru='<Данные будут пропущены>';vi='<Sẽ bỏ qua dữ liệu>'");
		ConditionalAppearanceText = ?(DataLoadSettings.CreateIfNotMatched, TextNewItem, TextSkipped);
		
	ElsIf DataLoadSettings.IsInformationRegisterImport Then
		
		If DataLoadSettings.FillingObjectFullName = "InformationRegister.Prices" Then
			
			FieldName = "Products";
			
		EndIf;
		
		ConditionalAppearanceText = NStr("en='<Row will be skipped...>';ru='<Строка будет пропущена...>';vi='<Sẽ bỏ qua dòng...>'");
		
	EndIf;
	
	DCConditionalAppearanceItem = ThisObject.ConditionalAppearance.Items.Add();
	DCConditionalAppearanceItem.Use = True;
	
	DCFilterItem = DCConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DCFilterItem.LeftValue = New DataCompositionField(AttributePath + "." + FieldName);
	DCFilterItem.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	DCConditionalAppearanceItem.Appearance.SetParameterValue(New DataCompositionParameter("Text"), ConditionalAppearanceText);
	DCConditionalAppearanceItem.Appearance.SetParameterValue(New DataCompositionParameter("TextColor"), New Color(175, 175, 175));
	
	FormedFieldKD = DCConditionalAppearanceItem.Fields.Items.Add();
	FormedFieldKD.Field = New DataCompositionField(FieldName);
	
EndProcedure

Procedure ChangeConditionalDesignText(ConditionalAppearance, DataLoadSettings) Export
	
	If DataLoadSettings.IsTabularSectionImport Then
		
		Return;
		
	ElsIf DataLoadSettings.IsInformationRegisterImport Then
		
		Return;
		
	ElsIf DataLoadSettings.IsCatalogImport Then
		
		If DataLoadSettings.FillingObjectFullName = "Catalog.Products" Then
			
			FieldName = "Products";
			
		ElsIf DataLoadSettings.FillingObjectFullName = "Catalog.Counterparties" Then
			
			FieldName = "Counterparty";
			
		EndIf;
		
		TextNewItem	= NStr("en='<New item will be created>';ru='<Будет создан новый элемент>';vi='<Sẽ tạo phần tử mới>'");
		TextSkipped	= NStr("en='<New item will be created>';ru='<Будет создан новый элемент>';vi='<Sẽ tạo phần tử mới>'");
		ConditionalAppearanceText = ?(DataLoadSettings.CreateIfNotMatched, TextNewItem, TextSkipped);
		
	EndIf;
	
	SearchItem = New DataCompositionField(FieldName);
	For Each ConditionalAppearanceItem In ConditionalAppearance.Items Do
		
		ThisIsTargetFormat = False;
		For Each MadeOutField In ConditionalAppearanceItem.Fields.Items Do
			
			If MadeOutField.Field = SearchItem Then
				
				ThisIsTargetFormat = True;
				Break;
				
			EndIf;
			
		EndDo;
		
		If ThisIsTargetFormat Then
			
			ConditionalAppearanceItem.Appearance.SetParameterValue(New DataCompositionParameter("Text"), ConditionalAppearanceText);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure WhenDeterminingDataImportForm(DataImportFormNameFromExternalSources, FillingObjectFullName, FilledObject) Export
	
	
	
EndProcedure

Procedure OverrideDataImportFieldsFilling(ImportFieldsTable, DataLoadSettings) Export
	
	
	
EndProcedure

Procedure WhenAddingServiceFields(ServiceFieldsGroup, FillingObjectFullName) Export
	
	
	
EndProcedure

Procedure AfterAddingItemsToMatchesTables(ThisObject, DataLoadSettings) Export
	
	If DataLoadSettings.FillingObjectFullName = "Catalog.Products" Then
		
		ThisObject.Items["Parent"].ChoiceForm = "Catalog.Products.Form.GroupChoiceForm";
		
	ElsIf DataLoadSettings.FillingObjectFullName = "Catalog.Counterparties"  Then
		
		ThisObject.Items["Parent"].ChoiceForm = "Catalog.Counterparties.Form.GroupChoiceForm.";
		
	ElsIf DataLoadSettings.FillingObjectFullName = "Document.SupplierInvoice.TabularSection.Inventory" Then
		
		ArrayProductsTypes = New Array;
		ArrayProductsTypes.Add(Enums.ProductsAndServicesTypes.InventoryItem);
		
		NewParameter = New ChoiceParameter("Filter.ProductsAndServicesTypes", ArrayProductsTypes);
		
		ParameterArray = New Array;
		ParameterArray.Add(NewParameter);
		
		ThisObject.Items["ProductsAndServices"].ChoiceParameters = New FixedArray(ParameterArray);
		
	ElsIf DataLoadSettings.FillingObjectFullName = "Document.SupplierInvoice.TabularSection.Expenses" Then
		
		ArrayProductsTypes = New Array;
		ArrayProductsTypes.Add(Enums.ProductsAndServicesTypes.Service);
		
		NewParameter = New ChoiceParameter("Filter.ProductsAndServicesTypes", ArrayProductsTypes);
		
		ParameterArray = New Array;
		ParameterArray.Add(NewParameter);
		
		ThisObject.Items["ProductsAndServices"].ChoiceParameters = New FixedArray(ParameterArray);
		
	EndIf;
	
EndProcedure

Procedure WhenDeterminingUsageMode(UseTogether) Export
	
	UseTogether = True;
	
EndProcedure

Procedure DataImportFieldsFromExternalSource(ImportFieldsTable, DataLoadSettings) Export
	
	FillingObjectFullName = DataLoadSettings.FillingObjectFullName;
	FilledObject = Metadata.FindByFullName(FillingObjectFullName);
	
	TypeDescriptionString10		= New TypeDescription("String", , , , New StringQualifiers(10));
	TypeDescriptionString11		= New TypeDescription("String", , , , New StringQualifiers(1));
	TypeDescriptionString25 	= New TypeDescription("String", , , , New StringQualifiers(25));
	TypeDescriptionString50 	= New TypeDescription("String", , , , New StringQualifiers(50));
	TypeDescriptionString100	= New TypeDescription("String", , , , New StringQualifiers(100));
	TypeDescriptionString150 	= New TypeDescription("String", , , , New StringQualifiers(150));
	TypeDescriptionString200 	= New TypeDescription("String", , , , New StringQualifiers(200));
	TypeDescriptionString1000 	= New TypeDescription("String", , , , New StringQualifiers(100));
	TypeDescriptionNumber10_0	= New TypeDescription("Number", , , , New NumberQualifiers(10, 0, AllowedSign.Nonnegative));
	TypeDescriptionNumber10_3	= New TypeDescription("Number", , , , New NumberQualifiers(10, 3, AllowedSign.Nonnegative));
	TypeDescriptionNumber15_2	= New TypeDescription("Number", , , , New NumberQualifiers(15, 2, AllowedSign.Nonnegative));
	TypeDescriptionNumber15_3 	= New TypeDescription("Number", , , , New NumberQualifiers(15, 3, AllowedSign.Nonnegative));
	TypeDescriptionDate 		= New TypeDescription("Date", , , , New DateQualifiers(DateFractions.Date));
	
	If DataLoadSettings.FillingObjectFullName = "Catalog.Counterparties" Then 
		TypeDescriptionColumn = New TypeDescription("CatalogRef.Counterparties");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Parent", NStr("en='Group';ru='Группа';vi='Nhóm'"),
																	TypeDescriptionString100, TypeDescriptionColumn);
		
		TypeDescriptionColumn = New TypeDescription("Boolean");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "ThisIsInd",
																	NStr("en='Is this an individual?';ru='Это физическое лицо?';vi='Đây là cá nhân?'"),
																	TypeDescriptionString10, TypeDescriptionColumn);
		
		TypeDescriptionColumn = New TypeDescription("CatalogRef.Counterparties");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "TIN", NStr("en='TIN';ru='ИНН';vi='MST'"),
																	TypeDescriptionString25, TypeDescriptionColumn, "Counterparty", 1, , True);
																	
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "CounterpartyDescription",
																	NStr("en='Counterparty (name)';ru='Контрагент (наименование)';vi='Đối tác (tên gọi)'"),
																	TypeDescriptionString100, TypeDescriptionColumn, "Counterparty", 3, True, True);
																	
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "BankAccount",
																	NStr("en='Counterparty (operating account)';ru='Контрагент (расчетный счет)';vi='Đối tác (tài khoản thanh toán)'"),
																	TypeDescriptionString50, TypeDescriptionColumn, "Counterparty", 4, , True);
																			
		TypeDescriptionColumn = New TypeDescription("CatalogRef.Individuals");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Individual",
																	NStr("en='Individual';ru='Физическое лицо';vi='Cá nhân'"),
																	TypeDescriptionString200, TypeDescriptionColumn);
		
		If GetFunctionalOption("UseCounterpartiesAccessGroups") Then
			
			TypeDescriptionColumn = New TypeDescription("CatalogRef.CounterpartiesAccessGroups");
			DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "AccessGroup",
																		NStr("en='Counterparty access group';ru='Группа доступа контрагента';vi='Nhóm truy cập đối tác'"),
																		TypeDescriptionString200, TypeDescriptionColumn, , , True);
		EndIf;
		
		TypeDescriptionColumn = New TypeDescription("ChartOfAccountsRef.Managerial"); 
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "GLAccountCustomerSettlements",
																	NStr("en='GL account (accounts receivable)';ru='Счет учета (расчеты с покупателем)';vi='Tài khoản kế toán (hạch toán với khách hàng)'"),
																	TypeDescriptionString10, TypeDescriptionColumn);
																	
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "CustomerAdvancesGLAccount",
																	NStr("en='GL account (customer advances)';ru='Счет учета (авансы покупателя)';vi='Tài khoản kế toán (tạm ứng của khách hàng)'"),
																	TypeDescriptionString10, TypeDescriptionColumn);
																	
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "GLAccountVendorSettlements", 	
																	NStr("en='GL account (accounts payable)';ru='Счет учета (расчеты с поставщиком)';vi='Tài khoản kế toán (hạch toán với nhà cung cấp)'"),
																	TypeDescriptionString10, TypeDescriptionColumn);
																	
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "VendorAdvancesGLAccount",
																	NStr("en='GL account (vendor advances)';ru='Счет учета (авансы поставщика)';vi='Tài khoản kế toán (tạm ứng của nhà cung cấp)'"),
																	TypeDescriptionString10, TypeDescriptionColumn);
		
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Comment", NStr("en='Comment';ru='Комментарий';vi='Ghi chú'"),
																	TypeDescriptionString200, TypeDescriptionString200);
		
		TypeDescriptionColumn = New TypeDescription("Boolean");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "DoOperationsByContracts",
																	NStr("en='Accounting by contracts';ru='Вести расчеты по договорам';vi='Hạch toán theo hợp đồng'"),
																	TypeDescriptionString10, TypeDescriptionColumn);
																	
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "DoOperationsByDocuments",
																	NStr("en='Accounting by documents';ru='Вести расчеты по документам';vi='Hạch toán theo chứng từ'"),
																	TypeDescriptionString10, TypeDescriptionColumn);
																	
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "DoOperationsByOrders",
																	NStr("en='Accounting by orders';ru='Вести расчеты по заказам';vi='Hạch toán theo đơn hàng'"),
																	TypeDescriptionString10, TypeDescriptionColumn);
																	
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "TrackPaymentsByBills",
																	NStr("en='Accounting by accounts';ru='Вести расчеты по счетам';vi='Hạch toán theo tài khoản'"),
																	TypeDescriptionString10, TypeDescriptionColumn);
		
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Phone", NStr("en='Phone';ru='Телефон';vi='Điện thoại'"),
																	TypeDescriptionString100, TypeDescriptionString100);
																	
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "EMail_Address", NStr("en='Email';ru='E-mail';vi='E-mail'"),
																	TypeDescriptionString100, TypeDescriptionString100);
		
		TypeDescriptionColumn = New TypeDescription("Boolean");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Customer",
																	NStr("en='Customer';ru='Покупатель';vi='Khách hàng'"),
																	TypeDescriptionString10, TypeDescriptionColumn);
																	
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Supplier",
																	NStr("en='Supplier';ru='Поставщик';vi='Nhà cung cấp'"),
																	TypeDescriptionString10, TypeDescriptionColumn);
																	
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "OtherRelationship",
																	NStr("en='Other relationship';ru='Прочие отношения';vi='Mối quan hệ khác'"),
																	TypeDescriptionString10, TypeDescriptionColumn);
		
		// AdditionalAttributes
		DataImportFromExternalSources.PrepareMapForAdditionalAttributes(DataLoadSettings, Catalogs.AdditionalAttributesAndInformationSets.Catalog_Counterparties);
		If DataLoadSettings.AdditionalAttributeDescription.Count() > 0 Then
			
			FieldName = DataImportFromExternalSources.AdditionalAttributesForAddingFieldsName();
			DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, FieldName,
																		NStr("en='Additional attributes';ru='Дополнительные атрибуты';vi='Thuộc tính bổ sung'"),
																		TypeDescriptionString150, TypeDescriptionString11, , , , , , True,
																		Catalogs.AdditionalAttributesAndInformationSets.Catalog_Counterparties);
		EndIf;
		
	ElsIf FillingObjectFullName = "Catalog.ProductsAndServices" Then
		
		TypeDescriptionColumn = New TypeDescription("CatalogRef.ProductsAndServices");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Parent", NStr("en='Group';ru='Группа';vi='Nhóm'"),
																	TypeDescriptionString100, TypeDescriptionColumn, , , , );
		
		TypeDescriptionColumn = New TypeDescription("CatalogRef.ProductsAndServices");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Code", NStr("en='Code';ru='Код';vi='Mã'"),
																	TypeDescriptionString11, TypeDescriptionColumn, "Products", 1, , True);
																	
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Barcode", 	NStr("en='Barcode';ru='Штрихкод';vi='Mã vạch'"),
																	TypeDescriptionString200, TypeDescriptionColumn, "Products", 2, , True);
																	
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "SKU", 	NStr("en='Product ID';ru='Артикул';vi='Thuộc tính'"),
																	TypeDescriptionString25, TypeDescriptionColumn, "Products", 3, , True);
																	
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "ProductsDescription",
																	NStr("en='Product (name)';ru='Номенклатура (наименование)';vi='Mặt hàng (tên gọi)'"),
																	TypeDescriptionString100, TypeDescriptionColumn, "Products", 4, , True);
																	
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "ProductsDescriptionFull",
																	NStr("en='Product (full name)';ru='Номенклатура (полное наименование)';vi='Mặt hàng (tên gọi đầy đủ)'"),
																	TypeDescriptionString1000, TypeDescriptionColumn, "Products", 5, , True);
																	
		TypeDescriptionColumn = New TypeDescription("EnumRef.ProductsAndServicesTypes");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "ProductsAndServicesType",
																	NStr("en='Product type';ru='Тип номенклатуры';vi='Kiểu mặt hàng'"),
																	TypeDescriptionString11, TypeDescriptionColumn);
		
		TypeDescriptionColumn = New TypeDescription("CatalogRef.UOMClassifier");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "MeasurementUnit", 
																	NStr("en='Unit of measure';ru='Ед. изм.';vi='Đơn vị tính'"), 
																	TypeDescriptionString25, TypeDescriptionColumn);
		
		TypeDescriptionColumn = New TypeDescription("EnumRef.InventoryValuationMethods");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "EstimationMethod", 
																	NStr("en='Write-off method';ru='Способ списания';vi='Phương thức ghi giảm'"), 
																	TypeDescriptionString25, TypeDescriptionColumn);
		
		TypeDescriptionColumn = New TypeDescription("CatalogRef.BusinessActivities");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "BusinessActivity", 
																	NStr("en='Line of business';ru='Направление бизнеса';vi='Mảng kinh doanh'"), 
																	TypeDescriptionString50, TypeDescriptionColumn, , , , ,
																	GetFunctionalOption("AccountingBySeveralBusinessActivities"));
		
		TypeDescriptionColumn = New TypeDescription("CatalogRef.ProductsAndServicesCategories");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "ProductsAndServicesCategory", 
																	NStr("en='Product category';ru='Номенклатурная группа';vi='Nhóm hàng'"), 
																	TypeDescriptionString100, TypeDescriptionColumn);
		
		TypeDescriptionColumn = New TypeDescription("CatalogRef.Counterparties");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Vendor", 
																	NStr("en='Supplier (TIN or name)';ru='Поставщик (ИНН или наименование)';vi='Nhà cung cấp (MST hoặc tên gọi)'"), 
																	TypeDescriptionString100, TypeDescriptionColumn);
		
		If GetFunctionalOption("UseSerialNumbers") Then
			
			TypeDescriptionColumn = New TypeDescription("Boolean");
			DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "UseSerialNumbers", 
																		NStr("en='Use serial numbers';ru='Использовать серийные номера';vi='Sử dụng số sê-ri'"),
																		TypeDescriptionString25, TypeDescriptionColumn);
			
			TypeDescriptionColumn = New TypeDescription("CatalogRef.SerialNumbers");
			DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "SerialNumber", 
																		NStr("en='Serial number';ru='Серийный номер';vi='Số sê-ri'"),
																		TypeDescriptionString150, TypeDescriptionColumn);
			
		EndIf;
		
		TypeDescriptionColumn = New TypeDescription("CatalogRef.StructuralUnits");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Warehouse", 
																	NStr("en='Warehouse (name)';ru='Склад (наименование)';vi='Kho bãi (tên gọi)'"), 
																	TypeDescriptionString50, TypeDescriptionColumn);
		
		TypeDescriptionColumn = New TypeDescription("EnumRef.InventoryReplenishmentMethods");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "ReplenishmentMethod", 
																	NStr("en='Replenishment method';ru='Способ пополнения';vi='Phương thức bổ sung'"), 
																	TypeDescriptionString50, TypeDescriptionColumn);
		
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "ReplenishmentDeadline", 
																	NStr("en='Replenishment deadline';ru='Срок пополнения';vi='Thời hạn bổ sung'"), 
																	TypeDescriptionString25, TypeDescriptionNumber10_0);
		
		TypeDescriptionColumn = New TypeDescription("CatalogRef.VATRates");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "VATRate", 
																	NStr("en='VAT rate';ru='Ставка НДС';vi='Thuế suất thuế GTGT'"), 
																	TypeDescriptionString11, TypeDescriptionColumn);
		
		TypeDescriptionColumn = New TypeDescription("ChartOfAccountsRef.Managerial");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "InventoryGLAccount", 
																	NStr("en='Inventory GL Account';ru='Счет учета запасов';vi='Tài khoản hàng tồn kho'"),
																	TypeDescriptionString11, TypeDescriptionColumn);
		
		TypeDescriptionColumn = New TypeDescription("ChartOfAccountsRef.Managerial");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "ExpensesGLAccount", 
																	NStr("en='Expense GL Account';ru='Счет учета затрат';vi='Tài khoản kế toán chi phí'"),
																	TypeDescriptionString11, TypeDescriptionColumn);
		
		If GetFunctionalOption("AccountingByCells") Then
			TypeDescriptionColumn = New TypeDescription("CatalogRef.Cells");
			DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Cell", 
																		NStr("en='Bin (name)';ru='Ячейка (наименование)';vi='Ô hàng (tên gọi)'"),
																		TypeDescriptionString50, TypeDescriptionColumn);
		EndIf;
		
		TypeDescriptionColumn = New TypeDescription("CatalogRef.PriceGroups");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "PriceGroup", 
																	NStr("en='Price group (name)';ru='Ценовая группа (наименование)';vi='Nhóm giá (tên gọi)'"),
																	TypeDescriptionString50, TypeDescriptionColumn);
		
		TypeDescriptionColumn = New TypeDescription("Boolean");
		If GetFunctionalOption("UseCharacteristics") Then
			DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "UseCharacteristics", 
																		NStr("en='Use characteristics';ru='Использовать характеристики';vi='Sử dụng đặc tính'"), 
																		TypeDescriptionString25, TypeDescriptionColumn);
		EndIf;
		
		If GetFunctionalOption("UseBatches") Then
			DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "UseBatches", 
																		NStr("en='Use batches';ru='Использовать партии';vi='Sử dụng lô hàng'"), 
																		TypeDescriptionString25, TypeDescriptionColumn);
		EndIf;
		
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Comment", 
																	NStr("en='Comment';ru='Комментарий';vi='Ghi chú'"), 
																	TypeDescriptionString200, TypeDescriptionString200);
		
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "OrderCompletionDeadline",
																	NStr("en='Order fulfillment deadline';ru='Срок исполнения заказа';vi='Thời hạn thực hiện đơn hàng'"), 
																	TypeDescriptionString11, TypeDescriptionNumber10_0);
		
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "TimeNorm", 
																	NStr("en='Standard hours';ru='Норма времени';vi='Định mức thời giian'"),
																	TypeDescriptionString25, TypeDescriptionNumber10_3);
		
		TypeDescriptionColumn = New TypeDescription("Boolean");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "FixedCost", 
																	NStr("en='Fixed cost (for works)';ru='Фикс. стоимость (для работ)';vi='Chi phí cố định (đối với công việc)'"),
																	TypeDescriptionString25, TypeDescriptionColumn);
		
		TypeDescriptionColumn = New TypeDescription("CatalogRef.WorldCountries");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "CountryOfOrigin", 
																	NStr("en='Country of origin (code or name)';ru='Страна происхождения (код или наименование)';vi='Nước xuất xứ (mã hoặc tên gọi)'"),
																	TypeDescriptionString25, TypeDescriptionColumn);
		
		// AdditionalAttributes
		DataImportFromExternalSources.PrepareMapForAdditionalAttributes(DataLoadSettings, Catalogs.AdditionalAttributesAndInformationSets.Catalog_ProductsAndServices);
		If DataLoadSettings.AdditionalAttributeDescription.Count() > 0 Then
			
			FieldName = DataImportFromExternalSources.AdditionalAttributesForAddingFieldsName();
			DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, FieldName, 
																		NStr("en='Additional attributes';ru='Дополнительные атрибуты';vi='Thuộc tính bổ sung'"),
																		TypeDescriptionString150, TypeDescriptionString11, , , , , , True,
																		Catalogs.AdditionalAttributesAndInformationSets.Catalog_ProductsAndServices_Common);
			
		EndIf;
		
	ElsIf FillingObjectFullName = "Catalog.Specifications.TabularSection.Content" Then
		
		TypeDescriptionColumn = New TypeDescription("EnumRef.SpecificationContentRowTypes");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "ContentRowType",
																	NStr("en='Row type';ru='Тип строки';vi='Kiểu dòng'"),
																	TypeDescriptionString25, TypeDescriptionColumn,,, True);
		
		TypeDescriptionColumn = New TypeDescription("CatalogRef.ProductsAndServices");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Barcode",
																	NStr("en='Barcode';ru='Штрихкод';vi='Mã vạch'"),
																	TypeDescriptionString200, TypeDescriptionColumn, "ProductsAndServices", 1, , True);
																	
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "SKU",
																	NStr("en='Product ID';ru='Артикул';vi='Thuộc tính'"),
																	TypeDescriptionString25, TypeDescriptionColumn, "ProductsAndServices", 2, , True);
																	
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "ProductsDescription",
																	NStr("en='Product (description)';ru='Номенклатура (наименование)';vi='Mặt hàng (tên gọi)'"),
																	TypeDescriptionString100, TypeDescriptionColumn, "ProductsAndServices", 3, , True);
																	
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "ProductsDescriptionFull",
																	NStr("en='Product (detailed description)';ru='Номенклатура (полное наименование)';vi='Mặt hàng (tên gọi đầy đủ)'"),
																	TypeDescriptionString1000, TypeDescriptionColumn, "ProductsAndServices", 5, , True);
		
		If GetFunctionalOption("UseCharacteristics") Then
			TypeDescriptionColumn = New TypeDescription("CatalogRef.ProductsAndServicesCharacteristics");
			DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Characteristic",
																		NStr("en='Characteristic (name)';ru='Характеристика (наименование)';vi='Đặc tính (tên gọi)'"),
																		TypeDescriptionString150, TypeDescriptionColumn);
		EndIf;
		
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Quantity",
																	NStr("en='Quantity';ru='Количество';vi='Số lượng'"),
																	TypeDescriptionString25, TypeDescriptionNumber15_3, , , True);
		
		TypeDescriptionColumn = New TypeDescription("CatalogRef.UOMClassifier"
									+ ?(GetFunctionalOption("AccountingInVariousUOM"), ", CatalogRef.UOM", ""));
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "MeasurementUnit",
																	NStr("en='Unit of measure';ru='Ед. изм.';vi='Đơn vị tính'"),
																	TypeDescriptionString25, TypeDescriptionColumn);
		
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "CostPercentage",
																	NStr("en='Cost share';ru='Доля стоимости';vi='Tỷ lệ giá trị'"),
																	TypeDescriptionString25, TypeDescriptionNumber15_2);
		
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "ProductsQuantity",
																	NStr("en='Product quantity';ru='Количество продукции';vi='Số lượng sản phẩm'"),
																	TypeDescriptionString25, TypeDescriptionNumber15_3);
		
		TypeDescriptionColumn = New TypeDescription("CatalogRef.Specifications");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Specification",
																	NStr("en='Bill of materials (name)';ru='Спецификация (наименование)';vi='Bảng kê chi tiết (tên gọi)'"),
																	TypeDescriptionString100, TypeDescriptionColumn);
		
	ElsIf FillingObjectFullName = "InformationRegister.ProductsAndServicesPrices" Then
		
		TypeDescriptionColumn = New TypeDescription("CatalogRef.ProductsAndServices");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Barcode",
																	NStr("en='Barcode';ru='Штрихкод';vi='Mã vạch'"),
																	TypeDescriptionString200, TypeDescriptionColumn, "ProductsAndServices", 1, , True);
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "SKU",
																	NStr("en='Product ID';ru='Артикул';vi='Thuộc tính'"),
																	TypeDescriptionString25, TypeDescriptionColumn, "ProductsAndServices", 2, , True);
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "ProductsDescription",
																	NStr("en='Product (name)';ru='Номенклатура (наименование)';vi='Mặt hàng (tên gọi)'"),
																	TypeDescriptionString100, TypeDescriptionColumn, "ProductsAndServices", 3, , True);
																	
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "ProductsDescriptionFull",
																	NStr("en='Product (full name)';ru='Номенклатура (полное наименование)';vi='Mặt hàng (tên gọi đầy đủ)'"),
																	TypeDescriptionString1000, TypeDescriptionColumn, "ProductsAndServices", 5, , True);
																	
		If GetFunctionalOption("UseCharacteristics") Then
			TypeDescriptionColumn = New TypeDescription("CatalogRef.ProductsAndServicesCharacteristics");
			DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Characteristic",
																		NStr("en='Characteristic (name)';ru='Характеристика (наименование)';vi='Đặc tính (tên gọi)'"),
																		TypeDescriptionString25, TypeDescriptionColumn);
		EndIf;
		
		TypeDescriptionColumn = New TypeDescription("CatalogRef.UOMClassifier"
									+ ?(GetFunctionalOption("AccountingInVariousUOM"), ", CatalogRef.UOM", ""));
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "MeasurementUnit",
																	NStr("en='Unit of measure';ru='Ед. изм.';vi='Đơn vị tính'"),
																	TypeDescriptionString25, TypeDescriptionColumn,,, True);
		
		TypeDescriptionColumn = New TypeDescription("CatalogRef.PriceKinds");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "PriceKind",
																	NStr("en='Price type (name)';ru='Вид цен (наименование)';vi='Dạng giá (tên gọi)'"),
																	TypeDescriptionString100, TypeDescriptionColumn);
		
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Price",
																	NStr("en='Price';ru='Цена';vi='Đơn giá'"),
																	TypeDescriptionString25, TypeDescriptionNumber15_2, , , True);
		
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Date",
																	NStr("en='Date (start of use)';ru='Дата (начало использования)';vi='Ngày (bắt đầu sử dụng)'"),
																	TypeDescriptionString25, TypeDescriptionDate);
		
	ElsIf FillingObjectFullName = "Document.EnterOpeningBalance.TabularSection.AccountsReceivable" Then
		
		TypeDescriptionColumn = New TypeDescription("CatalogRef.Counterparties");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Counterparty",
																	NStr("en='Counterparty (TIN or name)';ru='Контрагент (ИНН или наименование)';vi='Đối tác (MST hoặc tên gọi)'"),
																	TypeDescriptionString100, TypeDescriptionColumn, , , True);
		
		TypeDescriptionColumn = New TypeDescription("CatalogRef.CounterpartyContracts");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Contract",
																	NStr("en='Counterparty contract (name or number)';ru='Договор контрагента (наименование либо номер)';vi='Hợp đồng của đối tác (tên gọi hoặc số thứ tự)'"),
																	TypeDescriptionString100, TypeDescriptionColumn);
		
		TypeDescriptionColumn = New TypeDescription("Boolean");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "AdvanceFlag",
																	NStr("en='Is advance?';ru='Это аванс?';vi='Đây là khoản ứng trước?'"),
																	TypeDescriptionString25, TypeDescriptionColumn);
		
		TypeDescriptionColumn = New TypeDescription("DocumentRef.CustomerOrder");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "CustomerOrderNumber",
																	NStr("en='Sales order number';ru='Номер заказа покупателя';vi='Số đơn hàng của khách'"),
																	TypeDescriptionString25, TypeDescriptionColumn, "Order");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "CustomerOrderDate",
																	NStr("en='Sales order date';ru='Дата заказа покупателя';vi='Ngày đơn hàng của khách'"),
																	TypeDescriptionString25, TypeDescriptionColumn, "Order");
		
		TypeArray = New Array;
		TypeArray.Add(Type("DocumentRef.CustomerOrder"));
		TypeArray.Add(Type("DocumentRef.AcceptanceCertificate"));
		TypeArray.Add(Type("DocumentRef.Netting"));
		TypeArray.Add(Type("DocumentRef.AgentReport"));
		TypeArray.Add(Type("DocumentRef.ProcessingReport"));
		TypeArray.Add(Type("DocumentRef.CashReceipt"));
		TypeArray.Add(Type("DocumentRef.PaymentReceipt"));
		TypeArray.Add(Type("DocumentRef.FixedAssetsTransfer"));
		TypeArray.Add(Type("DocumentRef.CustomerInvoice"));
		
		TypeDescriptionColumn = New TypeDescription(TypeArray);
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "PaymentDocumentKind",
																	NStr("en='Payment document type';ru='Вид расчетного документа';vi='Dạng chứng từ hạch toán'"),
																	TypeDescriptionString50, TypeDescriptionColumn, "Document");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "NumberOfAccountsDocument",
																	NStr("en='Payment document number';ru='Номер расчетного документа';vi='Số chứng từ hạch toán'"),
																	TypeDescriptionString25, TypeDescriptionColumn, "Document");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "DateAccountingDocument",
																	NStr("en='Payment document date';ru='Дата расчетного документа';vi='Ngày chứng từ hạch toán'"),
																	TypeDescriptionString25, TypeDescriptionColumn, "Document");
		
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "AmountCur",
																	NStr("en='Amount (cur.)';ru='Сумма (вал.)';vi='Thành tiền (tiền tệ)'"),
																	TypeDescriptionString25, TypeDescriptionNumber15_2, , , True);
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Amount",
																	NStr("en='Amount';ru='Сумма';vi='Thành tiền'"),
																	TypeDescriptionString25, TypeDescriptionNumber15_2);
		
		TypeDescriptionColumn = New TypeDescription("DocumentRef.InvoiceForPayment");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "CustomerAccountNo",
																	NStr("en='Number of account for payment';ru='Номер счета к оплате';vi='Số hóa đơn cần thanh toán'"),
																	TypeDescriptionString25, TypeDescriptionColumn, "Account", , , );
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "CustomerAccountDate",
																	NStr("en='Date of account for payment';ru='Дата счета к оплате';vi='Ngày hóa đơn cần thanh toán'"),
																	TypeDescriptionString25, TypeDescriptionColumn, "Account", , , );
		
	ElsIf FillingObjectFullName = "Document.EnterOpeningBalance.TabularSection.AccountsPayable" Then
		
		TypeDescriptionColumn = New TypeDescription("CatalogRef.Counterparties");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Counterparty",
																	NStr("en='Counterparty (TIN or name)';ru='Контрагент (ИНН или наименование)';vi='Đối tác (MST hoặc tên gọi)'"),
																	TypeDescriptionString100, TypeDescriptionColumn, , , True);
		
		TypeDescriptionColumn = New TypeDescription("CatalogRef.CounterpartyContracts");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Contract",
																	NStr("en='Counterparty contract (name or number)';ru='Договор контрагента (наименование либо номер)';vi='Hợp đồng đối tác (tên gọi hoặc số thứ tự)'"),
																	TypeDescriptionString100, TypeDescriptionColumn);
		
		TypeDescriptionColumn = New TypeDescription("Boolean");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "AdvanceFlag",
																	NStr("en='Is advance?';ru='Это аванс?';vi='Đây là khoản ứng trước?'"),
																	TypeDescriptionString25, TypeDescriptionColumn, , , , False);
		
		TypeDescriptionColumn = New TypeDescription("DocumentRef.PurchaseOrder");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "PurchaseOrderNumber",
																	NStr("en='Purchase order number';ru='Номер заказа поставщику';vi='Số đơn hàng đặt nhà cung cấp'"),
																	TypeDescriptionString25, TypeDescriptionColumn, "Order");
																	
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "PurchaseOrderDate",
																	NStr("en='Purchase order date';ru='Дата заказа поставщику';vi='Ngày đơn hàng đặt nhà cung cấp'"),
																	TypeDescriptionString25, TypeDescriptionColumn, "Order");
		TypeArray = New Array;
		TypeArray.Add(Type("DocumentRef.ExpenseReport"));
		TypeArray.Add(Type("DocumentRef.AdditionalCosts"));
		TypeArray.Add(Type("DocumentRef.Netting"));
		TypeArray.Add(Type("DocumentRef.ReportToPrincipal"));
		TypeArray.Add(Type("DocumentRef.ProcessingReport"));
		TypeArray.Add(Type("DocumentRef.SupplierInvoice"));
		TypeArray.Add(Type("DocumentRef.CashPayment"));
		TypeArray.Add(Type("DocumentRef.PaymentExpense"));
		
		TypeDescriptionColumn = New TypeDescription(TypeArray);
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "PaymentDocumentKind",
																	NStr("en='Payment document type';ru='Вид расчетного документа';vi='Dạng chứng từ hạch toán'"),
																	TypeDescriptionString50, TypeDescriptionColumn, "Document");
																	
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "NumberOfAccountsDocument",
																	NStr("en='Payment document number';ru='Номер расчетного документа';vi='Số chứng từ hạch toán'"),
																	TypeDescriptionString25, TypeDescriptionColumn, "Document");
																	
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "DateAccountingDocument",
																	NStr("en='Payment document date';ru='Дата расчетного документа';vi='Ngày chứng từ hạch toán'"),
																	TypeDescriptionString25, TypeDescriptionColumn, "Document");
		
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "AmountCur",
																	NStr("en='Amount (cur.)';ru='Сумма (вал.)';vi='Thành tiền (tiền tệ)'"),
																	TypeDescriptionString25, TypeDescriptionNumber15_2, , , True);
		
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Amount",
																	NStr("en='Amount';ru='Сумма';vi='Thành tiền'"),
																	TypeDescriptionString25, TypeDescriptionNumber15_2);
		
		TypeDescriptionColumn = New TypeDescription("DocumentRef.SupplierInvoiceForPayment");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "CustomerAccountNo",
																	NStr("en='Number of account for payment';ru='Номер счета к оплате';vi='Số hóa đơn cần thanh toán'"),
																	TypeDescriptionString25, TypeDescriptionColumn, "Account");
		
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "CustomerAccountDate",
																	NStr("en='Date of account for payment';ru='Дата счета к оплате';vi='Ngày hóa đơn cần thanh toán'"),
																	TypeDescriptionString25, TypeDescriptionColumn, "Account");
	// Inventory	
	Else  
		If CommonUse.IsObjectAttribute("ProductsAndServices", FilledObject) Then
			TypeDescriptionColumn = New TypeDescription("CatalogRef.ProductsAndServices");
			DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Barcode",
																		NStr("en='Barcode';ru='Штрихкод';vi='Mã vạch'"),
																		TypeDescriptionString200, TypeDescriptionColumn, "ProductsAndServices", 1, , True);
			
			DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "SKU",
																		NStr("en='Product ID';ru='Артикул';vi='Thuộc tính'"),
																		TypeDescriptionString25, TypeDescriptionColumn, "ProductsAndServices", 2, , True);
			
			DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "ProductsDescription",
																		NStr("en='Product (description)';ru='Номенклатура (наименование)';vi='Mặt hàng (tên gọi)'"),
																		TypeDescriptionString100, TypeDescriptionColumn, "ProductsAndServices", 3, , True);
			
			DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "ProductsDescriptionFull",
																		NStr("en='Product(detailed description)';ru='Номенклатура (полное наименование)';vi='Mặt hàng (tên gọi đầy đủ)'"),
																		TypeDescriptionString1000, TypeDescriptionColumn, "ProductsAndServices", 5, , True);
		EndIf;
		
		If CommonUse.IsObjectAttribute("Characteristic", FilledObject) Then
			If GetFunctionalOption("UseCharacteristics") Then
				TypeDescriptionColumn = New TypeDescription("CatalogRef.ProductsAndServicesCharacteristics");
				DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Characteristic",
																			NStr("en='Characteristic (name)';ru='Характеристика (наименование)';vi='Đặc tính (tên gọi)'"),
																			TypeDescriptionString150, TypeDescriptionColumn);
			EndIf;
		EndIf;
		
		If CommonUse.IsObjectAttribute("Batch", FilledObject) Then
			If GetFunctionalOption("UseBatches") Then
				TypeDescriptionColumn = New TypeDescription("CatalogRef.ProductsAndServicesBatches");
				DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Batch",
																			NStr("en='Batch (name)';ru='Партия (наименование)';vi='Lô hàng (tên gọi)'"),
																			TypeDescriptionString100, TypeDescriptionColumn);
			EndIf;
		EndIf;
		
		If CommonUse.IsObjectAttribute("StructuralUnit", FilledObject) Then
			TypeDescriptionColumn = New TypeDescription("CatalogRef.StructuralUnits");
			DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "StructuralUnit",
																		NStr("en='Warehouse';ru='Склад';vi='Kho bãi'"),
																		TypeDescriptionString100, TypeDescriptionColumn);
		EndIf;
		
		If CommonUse.IsObjectAttribute("Cell", FilledObject) Then
			If GetFunctionalOption("AccountingByCells") Then
				DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Cell",
																			NStr("en='Bin (name)';ru='Ячейка (наименование)';vi='Ô hàng (tên gọi)'"),
																			TypeDescriptionString50, TypeDescriptionColumn);
			EndIf;
		EndIf;
		
		If CommonUse.IsObjectAttribute("Quantity", FilledObject) Then
			DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Quantity",
																		NStr("en='Quantity';ru='Количество';vi='Số lượng'"),
																		TypeDescriptionString25, TypeDescriptionNumber15_3, , , True);
		EndIf;
		
		If CommonUse.IsObjectAttribute("Reserve", FilledObject) Then
				DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Reserve",
																			NStr("en='Reserve';ru='Резерв';vi='Dự phòng'"),
																			TypeDescriptionString25, TypeDescriptionNumber15_3,,,,,
																			GetFunctionalOption("InventoryReservation"));
		EndIf;
		
		If CommonUse.IsObjectAttribute("MeasurementUnit", FilledObject) Then
			TypeDescriptionColumn = New TypeDescription("CatalogRef.UOMClassifier"
										+ ?(GetFunctionalOption("AccountingInVariousUOM"), ", CatalogRef.UOM", ""));
			DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "MeasurementUnit",
																		NStr("en='Unit of measure';ru='Ед. изм.';vi='Đơn vị tính'"),
																		TypeDescriptionString25, TypeDescriptionColumn, , , , , GetFunctionalOption("AccountingInVariousUOM"));
		EndIf;
		
		If CommonUse.IsObjectAttribute("Price", FilledObject) Then
			DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Price",
																		NStr("en='Price';ru='Цена';vi='Đơn giá'"),
																		TypeDescriptionString25, TypeDescriptionNumber15_2, , , True);
		EndIf;
		
		If CommonUse.IsObjectAttribute("Amount", FilledObject) Then
			DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Amount",
																		NStr("en='Amount';ru='Сумма';vi='Thành tiền'"),
																		TypeDescriptionString25, TypeDescriptionNumber15_2);
		EndIf;
		
		If CommonUse.IsObjectAttribute("VATRate", FilledObject) Then
			TypeDescriptionColumn = New TypeDescription("CatalogRef.VATRates");
			DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "VATRate",
																		NStr("en='VAT rate';ru='Ставка НДС';vi='Thuế suất thuế GTGT'"),
																		TypeDescriptionString50, TypeDescriptionColumn);
		EndIf;
		
		If CommonUse.IsObjectAttribute("VATAmount", FilledObject) Then
			DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "VATAmount",
																		NStr("en='VAT amount';ru='Сумма НДС';vi='Số tiền thuế GTGT'"),
																		TypeDescriptionString25, TypeDescriptionNumber15_2);
		EndIf;
		
		If CommonUse.IsObjectAttribute("ReceiptDate", FilledObject) Then
			DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "ReceiptDate",
																		NStr("en='Receipt date';ru='Дата поступления';vi='Ngày tiếp nhận'"),
																		TypeDescriptionString25, TypeDescriptionDate);
		EndIf;
		
		If CommonUse.IsObjectAttribute("ShipmentDate", FilledObject) Then
			FieldVisible = (DataLoadSettings.DatePositionInOrder = Enums.AttributePositionOnForm.InTabularSection);
			DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "ShipmentDate",
																		NStr("en='Shipment date';ru='Дата отгрузки';vi='Ngày giao hàng'"),
																		TypeDescriptionString25, TypeDescriptionDate, , , , , FieldVisible);
		EndIf;
		
		If CommonUse.IsObjectAttribute("Order", FilledObject) Then
			
			TypeArray = New Array;
			TypeArray.Add(Type("DocumentRef.CustomerOrder"));
			TypeArray.Add(Type("DocumentRef.PurchaseOrder"));
			
			If DataLoadSettings.Property("OrderPositionInDocument") Then
				VisibilityOfSalesOrder = (DataLoadSettings.OrderPositionInDocument = Enums.AttributePositionOnForm.InTabularSection);
			Else
				VisibilityOfSalesOrder = False;
			EndIf;
			
			TypeDescriptionColumn = New TypeDescription(TypeArray);
			DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Order",
																		NStr("en='Order (customer/supplier)';ru='Заказ (покупатель/поставщик)';vi='Đơn hàng (khách hàng/nhà cung cấp)'"),
																		TypeDescriptionString50, TypeDescriptionColumn, , , , , VisibilityOfSalesOrder);
			
		EndIf;
		
		If CommonUse.IsObjectAttribute("Specification", FilledObject) Then
			If GetFunctionalOption("UseWorkSubsystem")
				Or GetFunctionalOption("UseSubsystemProduction") Then
				
				TypeDescriptionColumn = New TypeDescription("CatalogRef.Specifications");
				DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Specification",
																			NStr("en='Specification (name)';ru='Спецификация (наименование)';vi='Bảng kê chi tiết (tên gọi)'"),
																			TypeDescriptionString150, TypeDescriptionColumn);
			EndIf;
		EndIf;
		
	EndIf;

EndProcedure

Procedure MatchImportedDataFromExternalSource(DataMatchingTable, DataLoadSettings) Export
	Var Manager;
	
	FillingObjectFullName 	= DataLoadSettings.FillingObjectFullName;
	FilledObject 			= Metadata.FindByFullName(FillingObjectFullName);
	UpdateData 				= DataLoadSettings.UpdateExisting;
	
	// DataMatchingTable - Type FormDataCollection
	For Each FormTableRow In DataMatchingTable Do
		
		If FillingObjectFullName = "Catalog.Counterparties" Then
			
			// Counterparty by TIN, Name, Current account
			MapCounterparty(FormTableRow.Counterparty, FormTableRow.TIN, FormTableRow.CounterpartyDescription, FormTableRow.BankAccount);
			ThisStringIsMapped = ValueIsFilled(FormTableRow.Counterparty);
			
			// Parent by name
			DefaultValue = Catalogs.Counterparties.EmptyRef();
			WhenDefiningDefaultValue(FormTableRow.Counterparty, "Parent", FormTableRow.Parent_IncomingData, ThisStringIsMapped, UpdateData, DefaultValue);
			MapParent("Counterparties", FormTableRow.Parent, FormTableRow.Parent_IncomingData, DefaultValue);
			
			ConvertStringToBoolean(FormTableRow.ThisIsInd, FormTableRow.ThisIsInd_IncomingData);
			If FormTableRow.ThisIsInd Then
				MapIndividualPerson(FormTableRow.Individual, FormTableRow.Individual_IncomingData);
			EndIf;
			
			If GetFunctionalOption("UseCounterpartiesAccessGroups") Then
				MapAccessGroup(FormTableRow.AccessGroup, FormTableRow.AccessGroup_IncomingData);
			EndIf;
			
			GLAccountCustomerSettlements = PredefinedValue("ChartOfAccounts.Managerial.AccountsReceivable");
			CustomerAdvancesGLAccount = PredefinedValue("ChartOfAccounts.Managerial.AccountsByAdvancesReceived");
			GLAccountVendorSettlements = PredefinedValue("ChartOfAccounts.Managerial.AccountsPayable");
			VendorAdvancesGLAccount = PredefinedValue("ChartOfAccounts.Managerial.SettlementsByAdvancesIssued");

			// GLAccountCustomerSettlements by code, name
			WhenDefiningDefaultValue(FormTableRow.Counterparty, "GLAccountCustomerSettlements", FormTableRow.GLAccountCustomerSettlements_IncomingData, ThisStringIsMapped, UpdateData, GLAccountCustomerSettlements);
			MapGLAccountCustomerSettlements(FormTableRow.GLAccountCustomerSettlements, FormTableRow.GLAccountCustomerSettlements_IncomingData, GLAccountCustomerSettlements);
			
			// CustomerAdvancesGLAccount by code, name
			WhenDefiningDefaultValue(FormTableRow.Counterparty, "CustomerAdvancesGLAccount", FormTableRow.CustomerAdvancesGLAccount_IncomingData, ThisStringIsMapped, UpdateData, CustomerAdvancesGLAccount);
			MapCustomerAdvancesGLAccount(FormTableRow.CustomerAdvancesGLAccount, FormTableRow.CustomerAdvancesGLAccount_IncomingData, CustomerAdvancesGLAccount);
			
			// GLAccountCustomerSettlements by code, name
			WhenDefiningDefaultValue(FormTableRow.Counterparty, "GLAccountVendorSettlements", FormTableRow.GLAccountVendorSettlements_IncomingData, ThisStringIsMapped, UpdateData, GLAccountVendorSettlements);
			MapGLAccountVendorSettlements(FormTableRow.GLAccountVendorSettlements, FormTableRow.GLAccountVendorSettlements_IncomingData, GLAccountVendorSettlements);
			
			// VendorAdvancesGLAccount by code, name
			WhenDefiningDefaultValue(FormTableRow.Counterparty, "VendorAdvancesGLAccount", FormTableRow.VendorAdvancesGLAccount_IncomingData, ThisStringIsMapped, UpdateData, VendorAdvancesGLAccount);
			MapVendorAdvancesGLAccount(FormTableRow.VendorAdvancesGLAccount, FormTableRow.VendorAdvancesGLAccount_IncomingData, VendorAdvancesGLAccount);
			
			// Comment
			CopyRowToStringTypeValue(FormTableRow.Comment, FormTableRow.Comment_IncomingData);
			
			// DoOperationsByContracts
			StringForMatch = ?(IsBlankString(FormTableRow.DoOperationsByContracts_IncomingData), "TRUE", FormTableRow.DoOperationsByContracts_IncomingData);
			ConvertStringToBoolean(FormTableRow.DoOperationsByContracts, StringForMatch);
			
			// DoOperationsByDocuments
			StringForMatch = ?(IsBlankString(FormTableRow.DoOperationsByDocuments_IncomingData), "TRUE", FormTableRow.DoOperationsByDocuments_IncomingData);
			ConvertStringToBoolean(FormTableRow.DoOperationsByDocuments, StringForMatch);
			
			// DoOperationsByOrders
			StringForMatch = ?(IsBlankString(FormTableRow.DoOperationsByOrders_IncomingData), "TRUE", FormTableRow.DoOperationsByOrders_IncomingData);
			ConvertStringToBoolean(FormTableRow.DoOperationsByOrders, StringForMatch);
			
			// TrackPaymentsByBills
			StringForMatch = ?(IsBlankString(FormTableRow.TrackPaymentsByBills_IncomingData), "TRUE", FormTableRow.TrackPaymentsByBills_IncomingData);
			ConvertStringToBoolean(FormTableRow.TrackPaymentsByBills, StringForMatch);
			
			// Phone
			CopyRowToStringTypeValue(FormTableRow.Phone, FormTableRow.Phone_IncomingData);
			
			// EMail_Address
			CopyRowToStringTypeValue(FormTableRow.EMail_Address, FormTableRow.EMail_Address_IncomingData);
			
			// Customer, Supplier, OtherRelationship
			ConvertStringToBoolean(FormTableRow.Customer,			FormTableRow.Customer_IncomingData);
			ConvertStringToBoolean(FormTableRow.Supplier,			FormTableRow.Supplier_IncomingData);
			ConvertStringToBoolean(FormTableRow.OtherRelationship,	FormTableRow.OtherRelationship_IncomingData);
						
			If Not FormTableRow.Customer
				AND Not FormTableRow.Supplier
				AND Not FormTableRow.OtherRelationship Then
				
				FormTableRow.Customer			= True;
				FormTableRow.Supplier			= True;
				FormTableRow.OtherRelationship	= True;
				
			EndIf;
			
		ElsIf FillingObjectFullName = "Catalog.ProductsAndServices" Then
			
			// Product by Barcode, SKU, Description
			CompareProducts(FormTableRow.Products, FormTableRow.Barcode, FormTableRow.SKU, FormTableRow.ProductsDescription, FormTableRow.ProductsDescriptionFull, FormTableRow.Code);
			ThisStringIsMapped = ValueIsFilled(FormTableRow.Products);
			
			// Parent by name
			DefaultValue = Catalogs.ProductsAndServices.EmptyRef();
			WhenDefiningDefaultValue(FormTableRow.Products, "Parent", FormTableRow.Parent_IncomingData, ThisStringIsMapped, UpdateData, DefaultValue);
			MapParent("ProductsAndServices", FormTableRow.Parent, FormTableRow.Parent_IncomingData, DefaultValue);
			
			// Product type (we can not correct attributes closed for editing)
			If ThisStringIsMapped Then
				FormTableRow.ProductsAndServicesType = FormTableRow.Products.ProductsAndServicesType;
			Else
				MapProductsType(FormTableRow.ProductsAndServicesType, FormTableRow.ProductsAndServicesType_IncomingData, Enums.ProductsAndServicesTypes.InventoryItem);
			EndIf;
			
			// MeasurementUnits by Description (also consider the option to bind user MU)
			MapUOM(FormTableRow.Products, FormTableRow.MeasurementUnit, FormTableRow.MeasurementUnit_IncomingData);
			
			// AccountingMethod
			DefaultValue = Enums.InventoryValuationMethods.ByAverage;
			WhenDefiningDefaultValue(FormTableRow.Products, "EstimationMethod", FormTableRow.EstimationMethod_IncomingData, ThisStringIsMapped, UpdateData, DefaultValue);
			MapAccountingMethod(FormTableRow.EstimationMethod, FormTableRow.EstimationMethod_IncomingData, DefaultValue);
			
			// BusinessLine by name
			DefaultValue = Catalogs.BusinessActivities.MainActivity;
			WhenDefiningDefaultValue(FormTableRow.Products, "BusinessActivity", FormTableRow.BusinessActivity_IncomingData, ThisStringIsMapped, UpdateData, DefaultValue);
			MapBusinessLine(FormTableRow.BusinessActivity, FormTableRow.BusinessActivity_IncomingData, DefaultValue);
			
			// ProductsCategory by description
			DefaultValue = Catalogs.ProductsAndServicesCategories.WithoutCategory;
			WhenDefiningDefaultValue(FormTableRow.Products, "ProductsAndServicesCategory", FormTableRow.ProductsAndServicesCategory_IncomingData, ThisStringIsMapped, UpdateData, DefaultValue);
			MapProductsCategory(FormTableRow.ProductsAndServicesCategory, FormTableRow.ProductsAndServicesCategory_IncomingData, DefaultValue);
			
			// Supplier by TIN, Description
			MapSupplier(FormTableRow.Vendor, FormTableRow.Vendor_IncomingData);
			
			// Serial numbers
			If GetFunctionalOption("UseSerialNumbers") Then
				
				ConvertStringToBoolean(FormTableRow.UseSerialNumbers, FormTableRow.UseSerialNumbers_IncomingData);
				FormTableRow.UseSerialNumbers = Not IsBlankString(FormTableRow.SerialNumber_IncomingData);
				
				If ThisStringIsMapped
					AND FormTableRow.UseSerialNumbers Then
					
					MapSerialNumber(FormTableRow.Products,
					FormTableRow.SerialNumber, FormTableRow.SerialNumber_IncomingData);
					
				EndIf;
				
			EndIf;
			
			// Warehouse by description
			DefaultValue = Catalogs.StructuralUnits.MainWarehouse;
			WhenDefiningDefaultValue(FormTableRow.Products, "Warehouse", FormTableRow.Warehouse_IncomingData, ThisStringIsMapped, UpdateData, DefaultValue);
			MapStructuralUnit(FormTableRow.Warehouse, FormTableRow.Warehouse_IncomingData, DefaultValue);
			
			// ReplenishmentMethod by description
			DefaultValue = Enums.InventoryReplenishmentMethods.Purchase;
			WhenDefiningDefaultValue(FormTableRow.Products, "ReplenishmentMethod", FormTableRow.ReplenishmentMethod_IncomingData, ThisStringIsMapped, UpdateData, DefaultValue);
			MapReplenishmentMethod(FormTableRow.ReplenishmentMethod, FormTableRow.ReplenishmentMethod_IncomingData, DefaultValue);
			
			// ReplenishmentDeadline
			DefaultValue = 1;
			WhenDefiningDefaultValue(FormTableRow.Products, "ReplenishmentDeadline", FormTableRow.ReplenishmentDeadline_IncomingData, ThisStringIsMapped, UpdateData, DefaultValue);
			ConvertRowToNumber(FormTableRow.ReplenishmentDeadline, FormTableRow.ReplenishmentDeadline_IncomingData, DefaultValue);
			
			// VATRate by description
			DefaultValue = Catalogs.Companies.MainCompany.DefaultVATRate;
			WhenDefiningDefaultValue(FormTableRow.Products, "VATRate", FormTableRow.VATRate_IncomingData, ThisStringIsMapped, UpdateData, DefaultValue);
			MapVATRate(FormTableRow.VATRate, FormTableRow.VATRate_IncomingData, DefaultValue);
			
			InventoryGLAccount = PredefinedValue("ChartOfAccounts.Managerial.RawMaterialsAndMaterials");
			If GetFunctionalOption("UseSubsystemProduction") Then
				ExpensesGLAccount = PredefinedValue("ChartOfAccounts.Managerial.UnfinishedProduction");
			Else
				ExpensesGLAccount = PredefinedValue("ChartOfAccounts.Managerial.CommercialExpenses");
			EndIf;

			// InventoryGLAccount by the code, description
			WhenDefiningDefaultValue(FormTableRow.Products, "InventoryGLAccount", FormTableRow.InventoryGLAccount_IncomingData, ThisStringIsMapped, UpdateData, InventoryGLAccount);
			MapInventoryGLAccount(FormTableRow.InventoryGLAccount, FormTableRow.InventoryGLAccount_IncomingData, InventoryGLAccount);
			
			// CostGLAccount by the code, description
			WhenDefiningDefaultValue(FormTableRow.Products, "ExpensesGLAccount", FormTableRow.ExpensesGLAccount_IncomingData, ThisStringIsMapped, UpdateData, ExpensesGLAccount);
			MapExpensesGLAccount(FormTableRow.ExpensesGLAccount, FormTableRow.ExpensesGLAccount_IncomingData, ExpensesGLAccount);
			
			If GetFunctionalOption("AccountingByCells") Then
				
				// Cell by description
				DefaultValue = Catalogs.Cells.EmptyRef();
				WhenDefiningDefaultValue(FormTableRow.Products, "Cell", FormTableRow.Cell_IncomingData, ThisStringIsMapped, UpdateData, DefaultValue);
				MapCell(FormTableRow.Cell, FormTableRow.Cell_IncomingData, DefaultValue);
				
			EndIf;
			
			// PriceGroup by description
			DefaultValue = Catalogs.PriceGroups.EmptyRef();
			WhenDefiningDefaultValue(FormTableRow.Products, "PriceGroup", FormTableRow.PriceGroup_IncomingData, ThisStringIsMapped, UpdateData, DefaultValue);
			MapPriceGroup(FormTableRow.PriceGroup, FormTableRow.PriceGroup_IncomingData, DefaultValue);
			
			// UseCharacteristics
			If GetFunctionalOption("UseCharacteristics") Then
				 ConvertStringToBoolean(FormTableRow.UseCharacteristics, FormTableRow.UseCharacteristics_IncomingData);
			EndIf;
			
			// UseBatches
			If GetFunctionalOption("UseBatches") Then
				ConvertStringToBoolean(FormTableRow.UseBatches, FormTableRow.UseBatches_IncomingData);
			EndIf;
			
			// Comment as string
			CopyRowToStringTypeValue(FormTableRow.Comment, FormTableRow.Comment_IncomingData);
			
			// OrderCompletionDeadline
			DefaultValue = 1;
			WhenDefiningDefaultValue(FormTableRow.Products, "OrderCompletionDeadline", FormTableRow.OrderCompletionDeadline_IncomingData, ThisStringIsMapped, UpdateData, DefaultValue);
			ConvertRowToNumber(FormTableRow.OrderCompletionDeadline, FormTableRow.OrderCompletionDeadline_IncomingData, DefaultValue);
			
			// TimeNorm
			DefaultValue = 0;
			WhenDefiningDefaultValue(FormTableRow.Products, "TimeNorm", FormTableRow.TimeNorm_IncomingData, ThisStringIsMapped, UpdateData, DefaultValue);
			ConvertRowToNumber(FormTableRow.TimeNorm, FormTableRow.TimeNorm_IncomingData, DefaultValue);
			
			// FixedCost
			ConvertStringToBoolean(FormTableRow.FixedCost, FormTableRow.FixedCost_IncomingData);
			
			// OriginCountry by the code
			DefaultValue = Catalogs.WorldCountries.EmptyRef();
			WhenDefiningDefaultValue(FormTableRow.Products, "CountryOfOrigin", FormTableRow.CountryOfOrigin_IncomingData, ThisStringIsMapped, UpdateData, DefaultValue);
			MapOriginCountry(FormTableRow.CountryOfOrigin, FormTableRow.CountryOfOrigin_IncomingData, DefaultValue);
			
		ElsIf FillingObjectFullName = "Catalog.Specifications.TabularSection.Content" Then
			
			// Product by Barcode, SKU, Description
			CompareProducts(FormTableRow.ProductsAndServices, FormTableRow.Barcode, FormTableRow.SKU, FormTableRow.ProductsDescription, FormTableRow.ProductsDescriptionFull);
			
			// StringType by StringType.Description
			MapRowType(FormTableRow.ContentRowType, FormTableRow.ContentRowType_IncomingData, Enums.SpecificationContentRowTypes.Material);
			
			If GetFunctionalOption("UseCharacteristics") Then
				If ValueIsFilled(FormTableRow.Products) Then
					// Characteristic by Owner and Name
					MapCharacteristic(FormTableRow.Characteristic, FormTableRow.ProductsAndServices, FormTableRow.Barcode, FormTableRow.Characteristic_IncomingData);
				EndIf;
			EndIf;
			
			// Quantity
			ConvertRowToNumber(FormTableRow.Quantity, FormTableRow.Quantity_IncomingData);
			
			// UOM by Description 
			MapUOM(FormTableRow.ProductsAndServices, FormTableRow.MeasurementUnit, FormTableRow.MeasurementUnit_IncomingData);
			
			// Cost share
			ConvertRowToNumber(FormTableRow.CostPercentage, FormTableRow.CostPercentage_IncomingData);
			
			// Product quantity
			ConvertRowToNumber(FormTableRow.ProductsQuantity, FormTableRow.ProductsQuantity_IncomingData);
			
			// Specifications by owner, description
			MapSpecification(FormTableRow.Specification, FormTableRow.Specification_IncomingData, FormTableRow.ProductsAndServices);
			
		ElsIf FillingObjectFullName = "InformationRegister.ProductsAndServicesPrices" Then
			
			// Product by Barcode, SKU, Description
			CompareProducts(FormTableRow.ProductsAndServices, FormTableRow.Barcode, FormTableRow.SKU, FormTableRow.ProductsDescription, FormTableRow.ProductsDescriptionFull);
			ThisStringIsMapped = ValueIsFilled(FormTableRow.ProductsAndServices);
			
			If GetFunctionalOption("UseCharacteristics") Then
				If ThisStringIsMapped Then
					// Characteristic by Owner and Name
					MapCharacteristic(FormTableRow.Characteristic, FormTableRow.ProductsAndServices, FormTableRow.Barcode, FormTableRow.Characteristic_IncomingData);
				EndIf;
			EndIf;
			
			// MeasurementUnits by Description (also consider the option to bind user MU)
			MapUOM(FormTableRow.ProductsAndServices, FormTableRow.MeasurementUnit, FormTableRow.MeasurementUnit_IncomingData);
			
			// PriceTypes by description
			DefaultValue = Catalogs.Counterparties.GetMainKindOfSalePrices();
			MapPriceKind(FormTableRow.PriceKind, FormTableRow.PriceKind_IncomingData, DefaultValue);
			
			// Price
			ConvertRowToNumber(FormTableRow.Price, FormTableRow.Price_IncomingData);
			
			// Date
			ConvertStringToDate(FormTableRow.Date, FormTableRow.Date_IncomingData);
			If Not ValueIsFilled(FormTableRow.Date) Then
				FormTableRow.Date = BegOfDay(CurrentDate());
			EndIf;
			
		ElsIf FillingObjectFullName = "Document.EnterOpeningBalance.TabularSection.AccountsReceivable" Then
			
			// Counterparty by TIN, Name
			MapSupplier(FormTableRow.Counterparty, FormTableRow.Counterparty_IncomingData);
			ThisStringIsMapped = ValueIsFilled(FormTableRow.Counterparty);
			
			If ThisStringIsMapped Then
				
				MapContract(FormTableRow.Counterparty, FormTableRow.Contract, FormTableRow.Contract_IncomingData);
				MapOrderByNumberDate(FormTableRow.Order, "CustomerOrder", FormTableRow.Counterparty, FormTableRow.CustomerOrderNumber, FormTableRow.CustomerOrderDate);
				MapAccountingDocumentByNumberDate(FormTableRow.Document, FormTableRow.PaymentDocumentKind, FormTableRow.Counterparty, FormTableRow.NumberOfAccountsDocument, FormTableRow.DateAccountingDocument);
				MapAccountByNumberDate(FormTableRow.Account, FormTableRow.Counterparty, FormTableRow.CustomerAccountNo, FormTableRow.CustomerAccountDate, "InvoiceForPayment");
				
			EndIf;
			
			ConvertStringToBoolean(FormTableRow.AdvanceFlag, FormTableRow.AdvanceFlag_IncomingData);
			
			ConvertRowToNumber(FormTableRow.AmountCur, FormTableRow.AmountCur_IncomingData);
			ConvertRowToNumber(FormTableRow.Amount, FormTableRow.Amount_IncomingData);
			
		ElsIf FillingObjectFullName = "Document.EnterOpeningBalance.TabularSection.AccountsPayable" Then
			
			// Counterparty by TIN, Name
			MapSupplier(FormTableRow.Counterparty, FormTableRow.Counterparty_IncomingData);
			ThisStringIsMapped = ValueIsFilled(FormTableRow.Counterparty);
			
			If ThisStringIsMapped Then
				
				MapContract(FormTableRow.Counterparty, FormTableRow.Contract, FormTableRow.Contract_IncomingData);
				MapOrderByNumberDate(FormTableRow.Order, "PurchaseOrder", FormTableRow.Counterparty, FormTableRow.PurchaseOrderNumber, FormTableRow.PurchaseOrderDate);
				MapAccountingDocumentByNumberDate(FormTableRow.Document, FormTableRow.PaymentDocumentKind, FormTableRow.Counterparty, FormTableRow.NumberOfAccountsDocument, FormTableRow.DateAccountingDocument);
				MapAccountByNumberDate(FormTableRow.Account, FormTableRow.Counterparty, FormTableRow.CustomerAccountNo, FormTableRow.CustomerAccountDate, "SupplierInvoiceForPayment");
				
			EndIf;
			
			ConvertStringToBoolean(FormTableRow.AdvanceFlag, FormTableRow.AdvanceFlag_IncomingData);
			
			ConvertRowToNumber(FormTableRow.AmountCur, FormTableRow.AmountCur_IncomingData);
			ConvertRowToNumber(FormTableRow.Amount, FormTableRow.Amount_IncomingData);
			
		// Inventory	
		Else
			// Product by Barcode, SKU, Description
			If CommonUse.IsObjectAttribute("ProductsAndServices", FilledObject) Then
				CompareProducts(FormTableRow.ProductsAndServices, FormTableRow.Barcode, FormTableRow.SKU, FormTableRow.ProductsDescription, FormTableRow.ProductsDescriptionFull);
			EndIf;
			
			// Characteristic by Owner and Name
			If CommonUse.IsObjectAttribute("Characteristic", FilledObject) Then
				If GetFunctionalOption("UseCharacteristics") Then
					If ValueIsFilled(FormTableRow.ProductsAndServices) Then
						MapCharacteristic(FormTableRow.Characteristic, FormTableRow.ProductsAndServices, FormTableRow.Barcode, FormTableRow.Characteristic_IncomingData);
					EndIf;
				EndIf;
			EndIf;
			
			// Batch by Owner and Name
			If CommonUse.IsObjectAttribute("Batch", FilledObject) Then
				If GetFunctionalOption("UseBatches") Then
					If ValueIsFilled(FormTableRow.ProductsAndServices) Then
						MapBatch(FormTableRow.Batch, FormTableRow.ProductsAndServices, FormTableRow.Barcode, FormTableRow.Batch_IncomingData);
					EndIf;
				EndIf;
			EndIf;
			
			// Structural unit
			If CommonUse.IsObjectAttribute("StructuralUnit", FilledObject) Then
				If ValueIsFilled(FormTableRow.ProductsAndServices) Then
					MapStructuralUnit(FormTableRow.StructuralUnit, FormTableRow.StructuralUnit_IncomingData, Catalogs.StructuralUnits.EmptyRef());
				EndIf;
			EndIf;
			
			// Cell by description
			If CommonUse.IsObjectAttribute("StructuralUnit", FilledObject) Then
				If GetFunctionalOption("AccountingByCells") Then
					MapCell(FormTableRow.Cell, FormTableRow.Cell_IncomingData, DefaultValue);
				EndIf;
			EndIf;
			
			// Quantity
			If CommonUse.IsObjectAttribute("Quantity", FilledObject) Then
				ConvertRowToNumber(FormTableRow.Quantity, FormTableRow.Quantity_IncomingData);
			EndIf;
			
			// Reserve
			If CommonUse.IsObjectAttribute("Reserve", FilledObject) Then
				If GetFunctionalOption("InventoryReservation") Then
					ConvertRowToNumber(FormTableRow.Reserve, FormTableRow.Reserve_IncomingData, 0);
				EndIf;
			EndIf;
			
			// MeasurementUnits by Description (also consider the option to bind user MU)
			If CommonUse.IsObjectAttribute("MeasurementUnit", FilledObject) Then
				MapUOM(FormTableRow.ProductsAndServices, FormTableRow.MeasurementUnit, FormTableRow.MeasurementUnit_IncomingData);
			EndIf;
			
			// Price
			If CommonUse.IsObjectAttribute("Price", FilledObject) Then
				ConvertRowToNumber(FormTableRow.Price, FormTableRow.Price_IncomingData);
			EndIf;
			
			// Amount
			If CommonUse.IsObjectAttribute("Amount", FilledObject) Then
				ConvertRowToNumber(FormTableRow.Amount, FormTableRow.Amount_IncomingData);
			EndIf;
			
			// VATRate
			If CommonUse.IsObjectAttribute("VATRate", FilledObject) Then
				MapVATRate(FormTableRow.VATRate, FormTableRow.VATRate_IncomingData, Undefined);
			EndIf;
			
			// VATAmount
			If CommonUse.IsObjectAttribute("VATAmount", FilledObject) Then
				ConvertRowToNumber(FormTableRow.VATAmount, FormTableRow.VATAmount_IncomingData, 0);
			EndIf;
			
			// ReceiptDate
			If CommonUse.IsObjectAttribute("ReceiptDate", FilledObject) Then
				ConvertStringToDate(FormTableRow.ReceiptDate, FormTableRow.ReceiptDate_IncomingData);
			EndIf;
			
			// Order
			If CommonUse.IsObjectAttribute("Order", FilledObject) Then
				MatchOrder(FormTableRow.Order, FormTableRow.Order_IncomingData);
			EndIf;
			
			// Specification
			If CommonUse.IsObjectAttribute("Specification", FilledObject) Then
				If GetFunctionalOption("UseWorkSubsystem")
					Or GetFunctionalOption("UseSubsystemProduction") Then
					
					If ValueIsFilled(FormTableRow.ProductsAndServices) Then
						MapSpecification(FormTableRow.Specification, FormTableRow.Specification_IncomingData, FormTableRow.ProductsAndServices);
					EndIf;
					
				EndIf;
			EndIf;
		EndIf;
		
		// Additional attributes		
		If DataLoadSettings.Property("SelectedAdditionalAttributes") AND DataLoadSettings.SelectedAdditionalAttributes.Count() > 0 Then
			MapAdditionalAttributes(FormTableRow, DataLoadSettings.SelectedAdditionalAttributes);
		EndIf;
		
		CheckDataCorrectnessInTableRow(FormTableRow, FillingObjectFullName);
		
	EndDo;
	
EndProcedure

Procedure WhenDefiningDefaultValue(CatalogRef, AttributeName, IncomingData, RowMatched, UpdateData, DefaultValue)
	
	If RowMatched 
		AND Not ValueIsFilled(IncomingData) Then
		
		DefaultValue = CatalogRef[AttributeName];
		
	EndIf;
	
EndProcedure

Procedure CheckDataCorrectnessInTableRow(FormTableRow, FillingObjectFullName = "") Export
	
	FilledObject 		= Metadata.FindByFullName(FillingObjectFullName);
	ServiceFieldName	= DataImportFromExternalSources.ServiceFieldNameImportToApplicationPossible();
	
	If FillingObjectFullName = "Catalog.Counterparties" Then 
		
		FormTableRow._RowMatched = ValueIsFilled(FormTableRow.Counterparty);
		FormTableRow[ServiceFieldName] = FormTableRow._RowMatched
		OR (NOT FormTableRow._RowMatched AND Not IsBlankString(FormTableRow.CounterpartyDescription));
		
	ElsIf FillingObjectFullName = "Catalog.ProductsAndServices" Then
		
		FormTableRow._RowMatched = ValueIsFilled(FormTableRow.Products);
		FormTableRow[ServiceFieldName] = FormTableRow._RowMatched
		OR (NOT FormTableRow._RowMatched AND Not IsBlankString(FormTableRow.ProductsDescription));
		
	ElsIf FillingObjectFullName = "Catalog.Specifications.TabularSection.Content" Then
		
		FormTableRow[ServiceFieldName] = ValueIsFilled(FormTableRow.ProductsAndServices) 
		AND  ValueIsFilled(FormTableRow.ContentRowType) 
		AND FormTableRow.Quantity <> 0;
		
	ElsIf FillingObjectFullName = "InformationRegister.Prices" Then
		
		FormTableRow[ServiceFieldName] = ValueIsFilled(FormTableRow.PriceKind)
		AND Not FormTableRow.PriceKind.CalculatesDynamically
		AND ValueIsFilled(FormTableRow.Products)
		AND FormTableRow.Price > 0
		AND ValueIsFilled(FormTableRow.MeasurementUnit)
		AND ValueIsFilled(FormTableRow.Date);
		
		If FormTableRow[ServiceFieldName] Then
			
			RecordSet = InformationRegisters.Prices.CreateRecordSet();
			RecordSet.Filter.Period.Set(BegOfDay(FormTableRow.Date));
			RecordSet.Filter.PriceKind.Set(FormTableRow.PriceKind);
			RecordSet.Filter.Products.Set(FormTableRow.Products);
			
			If GetFunctionalOption("UseCharacteristics") Then
				
				RecordSet.Filter.Characteristic.Set(FormTableRow.Characteristic);
				
			EndIf;
			
			RecordSet.Read();
			
			FormTableRow._RowMatched = (RecordSet.Count() > 0);
			
		EndIf;
		
	ElsIf FillingObjectFullName = "Document.EnterOpeningBalance.TabularSection.AccountsReceivable" 
		OR FillingObjectFullName = "Document.EnterOpeningBalance.TabularSection.AccountsPayable" Then
		
		FormTableRow[ServiceFieldName] = ValueIsFilled(FormTableRow.Counterparty)
		AND FormTableRow.AmountCur <> 0;
		
	ElsIf FillingObjectFullName = "Document.SupplierInvoice.TabularSection.Expenses" Then
		FormTableRow[ServiceFieldName] = ValueIsFilled(FormTableRow.ProductsAndServices)
			AND FormTableRow.ProductsAndServices.ProductsAndServicesType = Enums.ProductsAndServicesTypes.Service
			AND FormTableRow.Quantity <> 0
			AND FormTableRow.Price <> 0;
		
	// Inventory	
	Else 
		
		ThisIsExpenses		= (FillingObjectFullName = "Document.SupplierInvoice.TabularSection.Expenses");
		ServicesAvailable	= (FillingObjectFullName = "Document.CustomerOrder.TabularSection.Inventory") 
								OR (FillingObjectFullName = "Document.CustomerInvoice.TabularSection.Inventory")
								OR (FillingObjectFullName = "Document.PurchaseOrder.TabularSection.Inventory");
		
		FormTableRow[ServiceFieldName] = ValueIsFilled(FormTableRow.ProductsAndServices)
		AND (?(NOT ThisIsExpenses, FormTableRow.ProductsAndServices.ProductsAndServicesType = Enums.ProductsAndServicesTypes.InventoryItem, False)
		OR ?(ServicesAvailable, FormTableRow.ProductsAndServices.ProductsAndServicesType = Enums.ProductsAndServicesTypes.Service, False))
		AND ?(FormTableRow.Property("Quantity"), FormTableRow.Quantity <> 0, True)
		AND ?(FormTableRow.Property("Price"), FormTableRow.Price <> 0, True);
		
	EndIf;
	
EndProcedure

Procedure ImportDataFromExternalSourceResultDataProcessor(ImportResult, Object = Undefined, CurrentForm = Undefined) Export
	
	Try
		
		BeginTransaction();
		
		DataMatchingTable 		= ImportResult.DataMatchingTable;
		UpdateExisting 			= ImportResult.DataLoadSettings.UpdateExisting;
		CreateIfNotMatched 		= ImportResult.DataLoadSettings.CreateIfNotMatched;
		FillingObjectFullName	= ImportResult.DataLoadSettings.FillingObjectFullName;
		
		For Each TableRow In DataMatchingTable Do
			
			ImportToApplicationIsPossible = TableRow[DataImportFromExternalSources.ServiceFieldNameImportToApplicationPossible()];
			
			If FillingObjectFullName = "Catalog.Counterparties" Then 
				
				CoordinatedStringStatus = (TableRow._RowMatched AND UpdateExisting) 
				OR (NOT TableRow._RowMatched AND CreateIfNotMatched);
				
				If ImportToApplicationIsPossible AND CoordinatedStringStatus Then
					
					If TableRow._RowMatched Then
						CatalogItem			= TableRow.Counterparty.GetObject();
					Else
						CatalogItem 		= Catalogs.Counterparties.CreateItem();
						CatalogItem.Parent	= TableRow.Parent;
					EndIf;
					
					CatalogItem.Description 	= TableRow.CounterpartyDescription;
					CatalogItem.DescriptionFull	= TableRow.CounterpartyDescription;
					FillPropertyValues(CatalogItem, TableRow, , "Parent");
					
					CatalogItem.LegalEntityIndividual = ?(TableRow.ThisIsInd, Enums.CounterpartyKinds.Individual, Enums.CounterpartyKinds.LegalEntity);
					
					If Not IsBlankString(TableRow.TIN) Then
						
						Separators = New Array;
						Separators.Add("/");
						Separators.Add("\");
						Separators.Add("-");
						Separators.Add("|");
						
						TIN = "";
						
						For Each SeparatorValue In Separators Do
							
							SeparatorPosition = Find(TableRow.TIN, SeparatorValue);
							If SeparatorPosition = 0 Then 
								Continue;
							EndIf;
							
							TIN = Left(TableRow.TIN, SeparatorPosition - 1);
							
						EndDo;
						
						If IsBlankString(TIN) Then
							TIN = TableRow.TIN;
						EndIf;
						
						CatalogItem.TIN = TIN;
						
					EndIf;
					
					If Not IsBlankString(TableRow.Phone) Then
						PhoneStructure = New Structure("Presentation, Comment", TableRow.Phone,
							NStr("en='Imported from external source';ru='Загружено из внешнего источника';vi='Đã kết nhập từ nguồn ngoài'"));
						ContactInformationManagement.FillObjectContactInformation(CatalogItem, Catalogs.ContactInformationKinds.CounterpartyPhone, PhoneStructure);
					EndIf;
					
					If Not IsBlankString(TableRow.EMail_Address) Then
						StructureEmail = New Structure("Presentation", TableRow.EMail_Address);
						ContactInformationManagement.FillObjectContactInformation(CatalogItem, Catalogs.ContactInformationKinds.CounterpartyEmail, StructureEmail);
					EndIf;
					
					If ImportResult.DataLoadSettings.SelectedAdditionalAttributes.Count() > 0 Then
						DataImportFromExternalSources.ProcessSelectedAdditionalAttributes(CatalogItem, TableRow._RowMatched, TableRow, ImportResult.DataLoadSettings.SelectedAdditionalAttributes);
					EndIf;
					
					CatalogItem.Write();
				EndIf;
				
			ElsIf FillingObjectFullName = "Catalog.ProductsAndServices" Then
				
				CoordinatedStringStatus = (TableRow._RowMatched AND UpdateExisting) 
				OR (NOT TableRow._RowMatched AND CreateIfNotMatched);
				
				If ImportToApplicationIsPossible AND CoordinatedStringStatus Then
					
					If TableRow._RowMatched Then
						CatalogItem 			= TableRow.Products.GetObject();
					Else
						CatalogItem 			= Catalogs.ProductsAndServices.CreateItem();
						CatalogItem.Parent 		= TableRow.Parent;
					EndIf;
					
					CatalogItem.Description 	= TableRow.ProductsDescription;
					CatalogItem.DescriptionFull = ?(ValueIsFilled(TableRow.ProductsDescriptionFull),
					TableRow.ProductsDescriptionFull,
					TableRow.ProductsDescription);
					FillPropertyValues(CatalogItem, TableRow, , "Code, Parent");
					
					If ImportResult.DataLoadSettings.SelectedAdditionalAttributes.Count() > 0 Then
						DataImportFromExternalSources.ProcessSelectedAdditionalAttributes(CatalogItem, TableRow._RowMatched, TableRow, ImportResult.DataLoadSettings.SelectedAdditionalAttributes);
					EndIf;
					
					CatalogItem.Write();
				EndIf;
				
			ElsIf FillingObjectFullName = "InformationRegister.ProductsAndServicesPrices" Then
				
				CoordinatedStringStatus = (TableRow._RowMatched AND UpdateExisting) 
				OR (NOT TableRow._RowMatched AND CreateIfNotMatched);
				
				If ImportToApplicationIsPossible AND CoordinatedStringStatus Then
					
					RecordManager 						= InformationRegisters.ProductsAndServicesPrices.CreateRecordManager();
					RecordManager.Actuality				= True;
					RecordManager.PriceKind				= TableRow.PriceKind;
					RecordManager.MeasurementUnit 		= TableRow.MeasurementUnit;
					RecordManager.ProductsAndServices	= TableRow.ProductsAndServices;
					RecordManager.Period				= TableRow.Date;
					
					If GetFunctionalOption("UseCharacteristics") Then
						RecordManager.Characteristic	= TableRow.Characteristic;
					EndIf;
					
					RecordManager.Price					= TableRow.Price;
					RecordManager.Author				= Users.AuthorizedUser();
					RecordManager.Write(True);
					
				EndIf;
				
			ElsIf FillingObjectFullName = "Document.EnterOpeningBalance.TabularSection.AccountsReceivable" 
				OR FillingObjectFullName = "Document.EnterOpeningBalance.TabularSection.AccountsPayable" Then
				
				If ImportToApplicationIsPossible Then
					
					If FillingObjectFullName = "Document.EnterOpeningBalance.TabularSection.AccountsReceivable" Then
						TabularSectionName = "AccountsReceivable";
					Else 
						TabularSectionName = "AccountsPayable";
					EndIf;
					
					NewRow = Object[TabularSectionName].Add();
					FillPropertyValues(NewRow, TableRow, "Counterparty, Contract, AdvanceFlag, AmountCur, Amount", );
			
					
					StructureData = GetDataCounterparty(Object, NewRow.Counterparty, TabularSectionName, CurrentForm);
					If Not ValueIsFilled(NewRow.Contract) Then
						NewRow.Contract = StructureData.Contract;
					EndIf;
					
					NewRow.DoOperationsByContracts = StructureData.DoOperationsByContracts;
					NewRow.DoOperationsByDocuments = StructureData.DoOperationsByDocuments;
					NewRow.DoOperationsByOrders = StructureData.DoOperationsByOrders;
					NewRow.TrackPaymentsByBills = StructureData.TrackPaymentsByBills;
					
					NewRow.Amount = SmallBusinessServer.RecalculateFromCurrencyToAccountingCurrency(NewRow.AmountCur,
																									StructureData.SettlementsCurrency,
																									Object.Date);
					If NewRow.DoOperationsByOrders Then
						If TabularSectionName = "AccountsReceivable" Then
							NewRow.CustomerOrder = TableRow.Order;
						Else
							NewRow.PurchaseOrder = TableRow.Order;
						EndIf;
					EndIf;
					
					If NewRow.DoOperationsByDocuments Then
						NewRow.Document = TableRow.Document;
					EndIf;
					
					If NewRow.TrackPaymentsByBills Then
						NewRow.InvoiceForPayment = TableRow.Account;
					EndIf;
					
				EndIf;
				
			Else 
				
				If ImportToApplicationIsPossible Then
					
					TabularSectionName = Metadata.FindByFullName(FillingObjectFullName).Name;
					NewRow = Object[TabularSectionName].Add();
					
					PropertyNames = "";
					
					If NewRow.Property("ProductsAndServices") Then
						PropertyNames = PropertyNames + ?(PropertyNames = "", "ProductsAndServices", ", ProductsAndServices");
					EndIf;
					
					If NewRow.Property("Quantity") Then
						PropertyNames = PropertyNames + ", Quantity";
					EndIf;
					
					If NewRow.Property("Reserve") Then
						PropertyNames = PropertyNames + ", Reserve";
					EndIf;
					
					If NewRow.Property("MeasurementUnit") Then
						PropertyNames = PropertyNames + ", MeasurementUnit";
					EndIf;
					
					If NewRow.Property("VATRate") Then
						PropertyNames = PropertyNames + ", VATRate";
					EndIf;
					
					If NewRow.Property("Order") Then
						PropertyNames = PropertyNames + ", Order";
					EndIf;
					
					If NewRow.Property("UseCharacteristics") Then
						If NewRow.Property("Characteristic") Then
							PropertyNames = PropertyNames + ", Characteristic";
						EndIf;
					EndIf;
					
					If NewRow.Property("Batch")  And TableRow.Property("Batch") Then
						PropertyNames = PropertyNames + ", Batch";
					EndIf;
					
					If NewRow.Property("StructuralUnit") Then
						PropertyNames = PropertyNames + ", StructuralUnit";
					EndIf;
					
					If NewRow.Property("Specification") Then
						If GetFunctionalOption("UseWorkSubsystem")
							Or GetFunctionalOption("UseSubsystemProduction") Then
							
							PropertyNames = PropertyNames + ", Specification";
							
						EndIf;
					EndIf;
					
					If NewRow.Property("Order") Then
						PropertyNames = PropertyNames + ", Order";
					EndIf;
					
					If NewRow.Property("ReceiptDate") Then
						PropertyNames = PropertyNames + ", ReceiptDate";
					EndIf;
					
					If NewRow.Property("ShipmentDate") Then
						PropertyNames = PropertyNames + ", ShipmentDate";
					EndIf;
					
					If NewRow.Property("ContentRowType") Then
						PropertyNames = PropertyNames + ", ContentRowType";
					EndIf;
					
					If NewRow.Property("ProductsQuantity") Then
						PropertyNames = PropertyNames + ", ProductsQuantity";
					EndIf;
					
					If NewRow.Property("CostPercentage") Then
						PropertyNames = PropertyNames + ", CostPercentage";
					EndIf;
					
					FillPropertyValues(NewRow, TableRow, PropertyNames);
					
					If NewRow.Property("ProductsTypeInventory") Then
						NewRow.ProductsTypeInventory = (NewRow.Products.ProductsType = Enums.ProductsTypes.InventoryItem);
					EndIf;
					
					If NewRow.Property("Price") Then
						NewRow.Price = TableRow.Price;
					EndIf;
					
					If NewRow.Property("Amount")
						AND NewRow.Property("Price")
						AND NewRow.Property("Quantity") Then
						
						NewRow.Amount = TableRow.Price * TableRow.Quantity;
					EndIf;
					
					If Object.Property("VATTaxation")
						AND NewRow.Property("VATRate")
						AND NewRow.Property("VATAmount") Then
						
						If Object.VATTaxation = Enums.VATTaxationTypes.TaxableByVAT Then
							
							DefaultVATRate = Catalogs.Companies.MainCompany.DefaultVATRate;
							
							If Not ValueIsFilled(NewRow.VATRate) Then
								NewRow.VATRate = ?(ValueIsFilled(NewRow.ProductsAndServices.VATRate), NewRow.ProductsAndServices.VATRate, DefaultVATRate);
							EndIf;
							
							If ValueIsFilled(TableRow.VATAmount) Then
								NewRow.VATAmount = TableRow.VATAmount;
							Else
								VATRate = SmallBusinessReUse.GetVATRateValue(NewRow.VATRate);
								
								NewRow.VATAmount = ?(Object.AmountIncludesVAT, 
								NewRow.Amount - (NewRow.Amount) / ((VATRate + 100) / 100),
								NewRow.Amount * VATRate / 100);
							EndIf;
							
						Else
							NewRow.VATRate = ?(Object.VATTaxation = Enums.VATTaxationTypes.NotTaxableByVAT,
							SmallBusinessReUse.GetVATRateWithoutVAT(),
							SmallBusinessReUse.GetVATRateZero());
							
							NewRow.VATAmount = 0;
						EndIf;
					EndIf;
					
					If NewRow.Property("Total")
						AND NewRow.Property("Amount")
						AND NewRow.Property("VATAmount")
						AND Object.Property("AmountIncludesVAT") Then
						
						NewRow.Total = NewRow.Amount + ?(Object.AmountIncludesVAT, 0, NewRow.VATAmount);
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		
		CommitTransaction();
		
	Except
		WriteLogEvent(NStr("en='Data Import';ru='Загрузка данных';vi='Kết nhập dữ liệu'"), EventLogLevel.Error, Metadata.Catalogs.Counterparties, , ErrorDescription());
		RollbackTransaction();
	EndTry;
	
EndProcedure

// Procedure sets visible of calculation attributes depending on the parameters specified to the counterparty.
//
Procedure SetAccountsAttributesVisible(Object, CurrentForm = Undefined, Val DoOperationsByContracts = False, Val DoOperationsByDocuments = False, Val DoOperationsByOrders = False, Val TrackPaymentsByBills = False, TabularSectionName)
	
	If CurrentForm.FormName = "Document.EnterOpeningBalance.Form.DocumentForm" Then
		ThisIsWizard = False;
	Else
		ThisIsWizard = True;
	EndIf;
	
	FillServiceAttributesByCounterpartyInCollection(Object[TabularSectionName]);
	
	For Each CurRow In Object[TabularSectionName] Do
		If CurRow.DoOperationsByContracts Then
			DoOperationsByContracts = True;
		EndIf;
		If CurRow.DoOperationsByDocuments Then
			DoOperationsByDocuments = True;
		EndIf;
		If CurRow.DoOperationsByOrders Then
			DoOperationsByOrders = True;
		EndIf;
		If CurRow.TrackPaymentsByBills Then
			TrackPaymentsByBills = True;
		EndIf;
	EndDo;
	
	If TabularSectionName = "AccountsPayable" Then
		CurrentForm.Items[?(ThisIsWizard, "OpeningBalanceEntryCounterpartiesSettlements", "")+ "AccountsPayableContract"].Visible = DoOperationsByContracts;
		CurrentForm.Items[?(ThisIsWizard, "OpeningBalanceEntryCounterpartiesSettlements", "")+ "AccountsPayableDocument"].Visible = DoOperationsByDocuments;
		CurrentForm.Items[?(ThisIsWizard, "OpeningBalanceEntryCounterpartiesSettlements", "")+ "AccountsPayablePurchaseOrder"].Visible = DoOperationsByOrders;
		CurrentForm.Items[?(ThisIsWizard, "OpeningBalanceEntryCounterpartiesSettlements", "")+ "AccountsPayableInvoiceForPayment"].Visible = TrackPaymentsByBills;
	ElsIf TabularSectionName = "AccountsReceivable" Then
		CurrentForm.Items[?(ThisIsWizard, "OpeningBalanceEntryCounterpartiesSettlementsAccountsReceivableContract", "AccountsReceivableAgreement")].Visible = DoOperationsByContracts;
		CurrentForm.Items[?(ThisIsWizard, "OpeningBalanceEntryCounterpartiesSettlements", "")+ "AccountsReceivableDocument"].Visible = DoOperationsByDocuments;
		CurrentForm.Items[?(ThisIsWizard, "OpeningBalanceEntryCounterpartiesSettlements", "")+ "AccountsReceivableCustomersOrder"].Visible = DoOperationsByOrders;
		CurrentForm.Items[?(ThisIsWizard, "OpeningBalanceEntryCounterpartiesSettlements", "")+ "AccountsReceivableInvoiceForPayment"].Visible = TrackPaymentsByBills;
	ElsIf TabularSectionName = "StockTransferredToThirdParties" Then
		CurrentForm.Items.StockTransferredToThirdPartiesContract.Visible = DoOperationsByContracts;
	ElsIf TabularSectionName = "StockReceivedFromThirdParties" Then
		CurrentForm.Items.StockReceivedFromThirdPartiesContract.Visible = DoOperationsByContracts;
	EndIf;
	
EndProcedure

Procedure FillServiceAttributesByCounterpartyInCollection(DataCollection)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	CAST(Table.LineNumber AS NUMBER) AS LineNumber,
	|	Table.Counterparty AS Counterparty
	|INTO TableOfCounterparty
	|FROM
	|	&DataCollection AS Table
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfCounterparty.Counterparty.DoOperationsByContracts AS DoOperationsByContracts,
	|	TableOfCounterparty.Counterparty.DoOperationsByDocuments AS DoOperationsByDocuments,
	|	TableOfCounterparty.Counterparty.DoOperationsByOrders AS DoOperationsByOrders,
	|	TableOfCounterparty.Counterparty.TrackPaymentsByBills AS TrackPaymentsByBills
	|FROM
	|	TableOfCounterparty AS TableOfCounterparty";
	
	Query.SetParameter("DataCollection", DataCollection.Unload( ,"LineNumber, Counterparty"));
	
	Selection = Query.Execute().Select();
	For Ct = 0 To DataCollection.Count() - 1 Do
		Selection.Next(); // Number of rows in the query selection always equals to the number of rows in the collection
		FillPropertyValues(DataCollection[Ct], Selection, "DoOperationsByContracts, DoOperationsByDocuments, DoOperationsByOrders, TrackPaymentsByBills");
	EndDo;
	
EndProcedure

Function GetContractByDefault(Document, Counterparty, Company, TabularSectionName, OperationKind = Undefined)
	
	If Not Counterparty.DoOperationsByContracts Then
		Return Counterparty.ContractByDefault;
	EndIf;
	
	If (TabularSectionName = "StockTransferredToThirdParties"
		OR TabularSectionName = "StockReceivedFromThirdParties")
		AND Not ValueIsFilled(OperationKind) Then
		
		Return Catalogs.CounterpartyContracts.EmptyRef();
	EndIf;
	
	ManagerOfCatalog = Catalogs.CounterpartyContracts;
	
	ContractTypesList = ManagerOfCatalog.GetContractKindsListForDocument(Document, OperationKind, TabularSectionName);
	ContractByDefault = ManagerOfCatalog.GetDefaultContractByCompanyContractKind(Counterparty, Company, ContractTypesList);
	
	Return ContractByDefault;
	
EndFunction

// It receives data set from the server for the CounterpartyOnChange procedure.
//
Function GetDataCounterparty(Object, Counterparty, TabularSectionName, CurrentForm = Undefined, OperationKind = Undefined)
	
	ContractByDefault = GetContractByDefault(Object, Counterparty, TabularSectionName, OperationKind);
	
	StructureData = New Structure();
	
	StructureData.Insert(
		"Contract",
		ContractByDefault);
	
	StructureData.Insert(
		"SettlementsCurrency",
		ContractByDefault.SettlementsCurrency);
	
	StructureData.Insert("DoOperationsByContracts", Counterparty.DoOperationsByContracts);
	StructureData.Insert("DoOperationsByDocuments", Counterparty.DoOperationsByDocuments);
	StructureData.Insert("DoOperationsByOrders", Counterparty.DoOperationsByOrders);
	StructureData.Insert("TrackPaymentsByBills", Counterparty.TrackPaymentsByBills);
	
	SetAccountsAttributesVisible(
		Object,
		CurrentForm,
		Counterparty.DoOperationsByContracts,
		Counterparty.DoOperationsByDocuments,
		Counterparty.DoOperationsByOrders,
		Counterparty.TrackPaymentsByBills,
		TabularSectionName
	);
	
	Return StructureData;
	
EndFunction

Function DefaultPriceKind() Export
	
	Return Catalogs.Counterparties.GetMainKindOfSalePrices();
	
EndFunction

Function NotUpdatableStandardFieldNames() Export
	
	Return
	"TIN
	|CounterpartyDescription
	|ProductsDescription
	|ProductsFullDescription
	|BankAccount
	|Parent
	|PhoneNumber
	|SerialNumber
	|Barcode"
	
EndFunction

#Region ComparisonMethods

// :::Common

Procedure CatalogByName(CatalogName, CatalogValue, CatalogDescription, DefaultValue = Undefined)
	
	If Not IsBlankString(CatalogDescription) Then
		
		CatalogRef = Catalogs[CatalogName].FindByDescription(CatalogDescription, False);
		If ValueIsFilled(CatalogRef) Then
			
			CatalogValue = CatalogRef;
			
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(CatalogValue) Then
		
		CatalogValue = DefaultValue;
		
	EndIf;
	
EndProcedure

Procedure MapEnumeration(EnumerationName, EnumValue, IncomingData, DefaultValue)
	
	If ValueIsFilled(IncomingData) Then
		
		For Each EnumerationItem In Metadata.Enums[EnumerationName].EnumValues Do
			
			Synonym = EnumerationItem.Synonym;
			If Find(Upper(Synonym), Upper(IncomingData)) > 0 Then
				
				EnumValue = Enums[EnumerationName][EnumerationItem.Name];
				Break;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If Not ValueIsFilled(EnumValue) Then
		
		EnumValue = DefaultValue;
		
	EndIf;
	
EndProcedure

Procedure MapGLAccount(GLAccount, GLAccount_IncomingData, DefaultValue)
	
	If Not IsBlankString(GLAccount_IncomingData) Then
		
		FoundGLAccount = ChartsOfAccounts.Managerial.FindByCode(GLAccount_IncomingData);
		If FoundGLAccount = Undefined Then
			
			FoundGLAccount = ChartsOfAccounts.Managerial.FindByDescription(GLAccount_IncomingData);
			
		EndIf;
		
		If ValueIsFilled(FoundGLAccount) Then
			
			GLAccount = FoundGLAccount
			
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(GLAccount) Then
		
		GLAccount = DefaultValue;
		
	EndIf;
	
EndProcedure

Procedure ConvertStringToBoolean(ValueBoolean, IncomingData) Export
	
	IncomingData = UPPER(TrimAll(IncomingData));
	
	Array = New Array;
	Array.Add("+");
	Array.Add("1");
	Array.Add("TRUE");
	Array.Add("Yes");
	Array.Add("TRUE");
	Array.Add("YES");
	
	ValueBoolean = (Array.Find(IncomingData) <> Undefined);
	
EndProcedure

Procedure ConvertRowToNumber(NumberResult, NumberByString, DefaultValue = 0) Export
	
	If IsBlankString(NumberByString) Then
		
		NumberResult = DefaultValue;
		Return;
		
	EndIf;
	
	NumberStringCopy = StrReplace(NumberByString, ".", "");
	NumberStringCopy = StrReplace(NumberStringCopy, ",", "");
	NumberStringCopy = StrReplace(NumberStringCopy, Char(32), "");
	NumberStringCopy = StrReplace(NumberStringCopy, Char(160), "");
	If StringFunctionsClientServer.OnlyNumbersInString(NumberStringCopy) Then
		
		NumberStringCopy = StrReplace(NumberByString, " ", "");
		Try // through try, for example, in case of several points in the expression
			
			NumberResult = Number(NumberStringCopy);
			
		Except
			
			NumberResult = 0; // If trash was sent, then zero
			
		EndTry;
		
	Else
		
		NumberResult = 0; // If trash was sent, then zero
		
	EndIf;
	
EndProcedure

Procedure ConvertStringToDate(DateResult, DateString) Export
	
	If IsBlankString(DateString) Then
		
		DateResult = Date(0001, 01, 01);
		
	Else
		
		CopyDateString = DateString;
		
		DelimitersArray = New Array;
		DelimitersArray.Add(".");
		DelimitersArray.Add("/");
		
		For Each Delimiter In DelimitersArray Do
			
			NumberByString = "";
			MonthString = "";
			YearString = "";
			
			SeparatorPosition = Find(CopyDateString, Delimiter);
			If SeparatorPosition > 0 Then
				
				NumberByString = Left(CopyDateString, SeparatorPosition - 1);
				CopyDateString = Mid(CopyDateString, SeparatorPosition + 1);
				
			EndIf;
			
			SeparatorPosition = Find(CopyDateString, Delimiter);
			If SeparatorPosition > 0 Then
				
				MonthString = Left(CopyDateString, SeparatorPosition - 1);
				CopyDateString = Mid(CopyDateString, SeparatorPosition + 1);
				
			EndIf;
			
			YearString = CopyDateString;
			
			If Not IsBlankString(NumberByString) 
				AND Not IsBlankString(MonthString) 
				AND Not IsBlankString(YearString) Then
				
				Try
					
					DateResult = Date(Number(YearString), Number(MonthString), Number(NumberByString));
					
				Except
					
					DateResult = Date(0001, 01, 01);
					
				EndTry;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure CopyRowToStringTypeValue(StringTypeValue, String) Export
	
	StringTypeValue = TrimAll(String);
	
EndProcedure

Procedure CompareProducts(Products, Barcode, SKU, ProductsDescription, ProductsDescriptionFull = Undefined, Code = Undefined) Export
	
	ValueWasMapped = False;
	If ValueIsFilled(Code) Then
		
		CatalogRef = Catalogs.ProductsAndServices.FindByCode(Code, False);
		If Not CatalogRef.IsEmpty() Then
			
			ValueWasMapped = True;
			Products = CatalogRef;
			
		EndIf;
		
	EndIf;
	
	If Not ValueWasMapped 
		AND ValueIsFilled(Barcode) Then
		
		Query = New Query("SELECT BC.ProductsAndServices FROM InformationRegister.ProductsAndServicesBarcodes AS BC WHERE BC.Barcode = &Barcode");
		Query.SetParameter("Barcode", Barcode);
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			
			ValueWasMapped = True;
			Products = Selection.ProductsAndServices;
			
		EndIf;
		
	EndIf;
	
	If Not ValueWasMapped 
		AND ValueIsFilled(SKU) Then
		
		CatalogRef = Catalogs.ProductsAndServices.FindByAttribute("SKU", SKU);
		If Not CatalogRef.IsEmpty() Then
			
			ValueWasMapped = True;
			Products = CatalogRef;
			
		EndIf;
		
	EndIf;
	
	If Not ValueWasMapped 
		AND ValueIsFilled(ProductsDescription) Then
		
		CatalogRef = Catalogs.ProductsAndServices.FindByDescription(ProductsDescription, True);
		If ValueIsFilled(CatalogRef)
			AND Not CatalogRef.IsFolder Then
			
			ValueWasMapped = True;
			Products = CatalogRef;
			
		EndIf;
		
	EndIf;
	
	// Categories for catalog of products are not used at the moment.
	If ValueIsFilled(Products)
		AND Products.IsFolder Then
		
		Products = Catalogs.ProductsAndServices.EmptyRef();
		
	EndIf;
	
EndProcedure

Procedure CreateAdditionalProperty(AdditionalAttributeValue, Property, UseHierarchy, StringValue) Export
	
	If Not ValueIsFilled(AdditionalAttributeValue) Then
		
		CatalogName = ?(UseHierarchy, "AdditionalValuesHierarchy", "AdditionalValues");
		
		CatalogObject = Catalogs[CatalogName].CreateItem();
		CatalogObject.Owner = Property;
		CatalogObject.Description = StringValue;
		
		SmallBusinessServer.WriteObject(CatalogObject, True, True);
		
		AdditionalAttributeValue = CatalogObject.Ref;
		
	EndIf;
	
EndProcedure

Procedure MapAdditionalAttribute(AdditionalAttributeValue, Property, UseHierarchy, StringValue) Export
	
	QueryText = 
	"SELECT
	|	AdditionalValues.Ref AS PropertyValue
	|FROM
	|	Catalog.AdditionalValues AS AdditionalValues
	|WHERE
	|	AdditionalValues.Description LIKE &Description
	|	AND AdditionalValues.Ref IN(&ValueArray)";
	
	Query = New Query(QueryText);
	
	If UseHierarchy Then         
		
		Query.Text = StrReplace(Query.Text, "Catalog.AdditionalValues", "Catalog.AdditionalValuesHierarchy");
		
	EndIf;
	
	ValueArray = PropertiesManagement.GetListOfValuesOfProperties(Property);
	
	Query.SetParameter("Description", TrimAll(AdditionalAttributeValue));
	Query.SetParameter("ValueArray", ValueArray);
	QueryResult = Query.Execute();
	
	If NOT QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		If Selection.Next() Then
			AdditionalAttributeValue = Selection.PropertyValue;
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure CreateFillTableOfPossibleValueTypesForAdditionalAttribute(Property, TypesTable) Export
	
	TypesTable = New ValueTable;
	TypesTable.Columns.Add("Type");
	TypesTable.Columns.Add("Priority");
	
	ValueTypeArray = Property.ТипЗначения.Types();
	For Each ArrayItem In ValueTypeArray Do
		
		NewRow = TypesTable.Add();
		NewRow.Type = ArrayItem;
		If ArrayItem = Type("CatalogRef.AdditionalValues") 
			OR ArrayItem = Type("CatalogRef.AdditionalValuesHierarchy") Then
			
			NewRow.Priority = 1;
			
		ElsIf ArrayItem = Type("Boolean")
			OR ArrayItem = Type("Date")
			OR ArrayItem = Type("Number") Then
			
			NewRow.Priority = 3;
			
		ElsIf ArrayItem = Type("String") Then
			NewRow.Priority = 4;
		Else
			NewRow.Priority = 2;
		EndIf;
		
	EndDo;
	
	TypesTable.Sort("Priority");
	
EndProcedure

Procedure MapCharacteristic(Characteristic, Products, Barcode, Characteristic_IncomingData) Export
	
	If ValueIsFilled(Products) Then
		
		ValueWasMapped = False;
		If ValueIsFilled(Barcode) Then
			
			Query = New Query("SELECT BC.Characteristic FROM InformationRegister.ProductsAndServicesBarcodes AS BC WHERE BC.Barcode = &Barcode AND BC.ProductsAndServices = &Products");
			Query.SetParameter("Barcode", Barcode);
			Query.SetParameter("Products", Products);
			
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				
				ValueWasMapped = True;
				Characteristic = Selection.Characteristic;
				
			EndIf;
			
		EndIf;
		
		If Not ValueWasMapped
			AND ValueIsFilled(Characteristic_IncomingData) Then
			
			// Product or product category can be owners of a characteristic.
			//
			
			CatalogRef = Undefined;
			CatalogRef = Catalogs.ProductsAndServicesCharacteristics.FindByDescription(Characteristic_IncomingData, False, , Products);
			If Not ValueIsFilled(CatalogRef)
				AND ValueIsFilled(Products.ProductsCategory) Then
				
				CatalogRef = Catalogs.ProductsAndServicesCharacteristics.FindByDescription(Characteristic_IncomingData, False, , Products.ProductsCategory);
				
			EndIf;
			
			If ValueIsFilled(CatalogRef) Then
				
				Characteristic = CatalogRef;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure MapBatch(Batch, Products, Barcode, Batch_IncomingData) Export
	
	If ValueIsFilled(Products) Then
		
		ValueWasMapped = False;
		If ValueIsFilled(Barcode) Then
			
			Query = New Query("SELECT BC.Batch FROM InformationRegister.ProductsAndServicesBarcodes AS BC WHERE BC.Barcode = &Barcode AND BC.ProductsAndServices = &Products");
			Query.SetParameter("Barcode", Barcode);
			Query.SetParameter("Products", Products);
			
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				
				ValueWasMapped = True;
				Batch = Selection.Batch;
				
			EndIf;
			
		EndIf;
		
		If Not ValueWasMapped
			AND ValueIsFilled(Batch_IncomingData) Then
			
			CatalogRef = Catalogs.ProductsAndServicesBatches.FindByDescription(Batch_IncomingData, False, , Products);
			If ValueIsFilled(CatalogRef) Then
				
				Batch = CatalogRef;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure MapUOM(ProductsAndServices, MeasurementUnit, MeasurementUnit_IncomingData, DefaultValue = Undefined) Export
	
	If Not IsBlankString(MeasurementUnit_IncomingData) Then
		
		If ValueIsFilled(ProductsAndServices) Then
			
			CurrentUOMDescription = CommonUse.ObjectAttributeValue(ProductsAndServices, "MeasurementUnit.Description");
			If Upper(TrimAll(CurrentUOMDescription)) = Upper(TrimAll(MeasurementUnit_IncomingData)) Then
				
				MeasurementUnit = ProductsAndServices.MeasurementUnit;
				
			EndIf;
			
		EndIf;
		
		If Not ValueIsFilled(MeasurementUnit) Then
			
			CatalogRef = Catalogs.UOMClassifier.FindByDescription(MeasurementUnit_IncomingData, False);
			If ValueIsFilled(CatalogRef) Then
				
				MeasurementUnit = CatalogRef;
				
			EndIf;
			
		EndIf;
		
		If ValueIsFilled(ProductsAndServices) Then
			
			If Not ValueIsFilled(MeasurementUnit) Then
				
				CatalogRef = Catalogs.UOM.FindByDescription(MeasurementUnit_IncomingData, False, , ProductsAndServices);
				If ValueIsFilled(CatalogRef) Then
					
					MeasurementUnit = CatalogRef;
					
				EndIf;
				
			EndIf;
			
			If Not ValueIsFilled(MeasurementUnit)  Then
				
				ProductsAndServicesCategory = CommonUse.ObjectAttributeValue(ProductsAndServices, "ProductsAndServicesCategory");
				If ValueIsFilled(ProductsAndServicesCategory) Then
					
					CatalogRef = Catalogs.UOM.FindByDescription(MeasurementUnit_IncomingData, False, , ProductsAndServicesCategory);
					If ValueIsFilled(CatalogRef) Then
						
						MeasurementUnit = CatalogRef;
						
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(MeasurementUnit) And ValueIsFilled(DefaultValue) Then
		
		MeasurementUnit = DefaultValue;
		
	EndIf;
	
EndProcedure

Procedure MapParent(CatalogName, Parent, Parent_IncomingData, DefaultValue) Export
	
	If Not IsBlankString(Parent_IncomingData) Then
		
		Query = New Query("SELECT Catalog." + CatalogName + ".Ref WHERE Catalog." + CatalogName + ".IsFolder AND Catalog." + CatalogName + ".Description LIKE &Description");
		Query.SetParameter("Description", Parent_IncomingData + "%");
		Selection = Query.Execute().Select();
		
		If Selection.Next() Then
			
			Parent = Selection.Ref;
			
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(Parent) Then
		
		Parent = DefaultValue;
		
	EndIf;
	
EndProcedure

Procedure MapAdditionalAttributes(FormTableRow, SelectedAdditionalAttributes) Export
	Var TypesTable;
	
	Postfix = "_IncomingData";
	For Each MapItem In SelectedAdditionalAttributes Do
		
		StringValue = FormTableRow[MapItem.Value + Postfix];
		If IsBlankString(StringValue) Then
			Continue;
		EndIf;
		
		Property = MapItem.Key;
		
		CreateFillTableOfPossibleValueTypesForAdditionalAttribute(Property, TypesTable);
		
		AdditionalAttributeValue = Undefined;
		For Each TableRow In TypesTable Do
			
			If TableRow.Type = Type("CatalogRef.ObjectsPropertiesValues") Then
				
				MapAdditionalAttribute(AdditionalAttributeValue, Property, False, StringValue);
				
			ElsIf TableRow.Type = Type("CatalogRef.ObjectsPropertiesValuesHierarchy") Then
				
				MapAdditionalAttribute(AdditionalAttributeValue, Property, True, StringValue);
				
			ElsIf TableRow.Type = Type("CatalogRef.Counterparties") Then
				
				MapCounterparty(AdditionalAttributeValue, StringValue, StringValue, StringValue);
				
			ElsIf TableRow.Type = Type("CatalogRef.Individuals") Then
				
				MapIndividualPerson(AdditionalAttributeValue, StringValue);
				
			ElsIf TableRow.Type = Type("Boolean") Then
				
				ConvertStringToBoolean(AdditionalAttributeValue, StringValue);
				
			ElsIf TableRow.Type = Type("String") Then
				
				CopyRowToStringTypeValue(AdditionalAttributeValue, StringValue);
				
			ElsIf TableRow.Type = Type("Date") Then
				
				ConvertStringToDate(AdditionalAttributeValue, StringValue);
				
			ElsIf TableRow.Type = Type("Number") Then
				
				ConvertRowToNumber(AdditionalAttributeValue, StringValue);
				If AdditionalAttributeValue = 0 Then // 0 ignore
					AdditionalAttributeValue = Undefined;
				EndIf;
				
			EndIf;
			
			If AdditionalAttributeValue <> Undefined Then
				FormTableRow[MapItem.Value] = AdditionalAttributeValue;
				Break;
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

// :::Specification

Procedure MapRowType(RowType, RowType_IncomingData, DefaultValue) Export
	
	MapEnumeration("SpecificationContentRowTypes", RowType, RowType_IncomingData, DefaultValue);
	
EndProcedure

Procedure MapSpecification(Specification, Specification_IncomingData, Products) Export
	
	If ValueIsFilled(Products) 
		AND Not IsBlankString(Specification_IncomingData) Then
		
		CatalogRef = Catalogs.Specifications.FindByDescription(Specification_IncomingData, False, , Products);
		If ValueIsFilled(CatalogRef) Then
			
			Specification = CatalogRef;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// :::Products

Procedure MapProductsType(ProductsType, ProductsType_IncomingData, DefaultValue) Export
	
	MapEnumeration("ProductsTypes", ProductsType, ProductsType_IncomingData, DefaultValue);
	
EndProcedure

Procedure MapAccountingMethod(AccountingMethod, AccountingMethod_IncomingData, DefaultValue) Export
	
	MapEnumeration("InventoryValuationMethods", AccountingMethod, AccountingMethod_IncomingData, DefaultValue);
	
EndProcedure

Procedure MapBusinessLine(BusinessLine, BusinessLine_IncomingData, DefaultValue) Export
	
	UseEnabled = GetFunctionalOption("AccountingBySeveralBusinessActivities");
	If Not UseEnabled Then
		
		// You can not fill in the default value as it can, for instance, come from custom settings.
		//
		BusinessLine = Catalogs.BusinessActivities.MainActivity;
		
	Else
		
		CatalogByName("BusinessActivities", BusinessLine, BusinessLine_IncomingData, DefaultValue);
		
	EndIf;
	
EndProcedure

Procedure MapProductsCategory(ProductsCategory, ProductsCategory_IncomingData, DefaultValue) Export
	
	CatalogByName("ProductsCategories", ProductsCategory, ProductsCategory_IncomingData, DefaultValue)
	
EndProcedure

Procedure MapSupplier(Vendor, Vendor_IncomingData) Export
	
	If IsBlankString(Vendor_IncomingData) Then
		
		Return;
		
	EndIf;
	
	//:::TIN Search
	Separators = New Array;
	Separators.Add("/");
	Separators.Add("\");
	Separators.Add("-");
	Separators.Add("|");
	
	TIN = "";
	
	For Each SeparatorValue In Separators Do
		
		SeparatorPosition = Find(Vendor_IncomingData, SeparatorValue);
		If SeparatorPosition = 0 Then 
			
			Continue;
			
		EndIf;
		
		TIN = Left(Vendor_IncomingData, SeparatorPosition - 1);
		
		Query = New Query("SELECT Catalog.Counterparties.Ref WHERE NOT IsFolder AND TIN = &TIN");
		Query.SetParameter("TIN", TIN);
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			
			Vendor = Selection.Ref;
			Return;
			
		EndIf;
		
	EndDo;
	
	// :::Search TIN
	Query = New Query("SELECT Catalog.Counterparties.Ref WHERE NOT IsFolder AND TIN = &TIN");
	Query.SetParameter("TIN", Vendor_IncomingData);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		
		Vendor = Selection.Ref;
		Return;
		
	EndIf;
	
	//:::Search Name
	CatalogRef = Catalogs.Counterparties.FindByDescription(Vendor_IncomingData, False);
	If ValueIsFilled(CatalogRef) Then
		
		Vendor = CatalogRef;
		
	EndIf;
	
EndProcedure

Procedure MapStructuralUnit(Warehouse, Warehouse_IncomingData, DefaultValue) Export
	
	CatalogByName("StructuralUnits", Warehouse, Warehouse_IncomingData, DefaultValue);
	
EndProcedure

Procedure MapReplenishmentMethod(ReplenishmentMethod, ReplenishmentMethod_IncomingData, DefaultValue) Export
	
	MapEnumeration("InventoryReplenishmentMethods", ReplenishmentMethod, ReplenishmentMethod_IncomingData, DefaultValue);
	
EndProcedure

Procedure MapVATRate(VATRate, VATRate_IncomingData, DefaultValue) Export
	
	CatalogByName("VATRates", VATRate, VATRate_IncomingData, DefaultValue);
	
EndProcedure

Procedure MapInventoryGLAccount(InventoryGLAccount, InventoryGLAccount_IncomingData, DefaultValue) Export
	
	MapGLAccount(InventoryGLAccount, InventoryGLAccount_IncomingData, DefaultValue);
	
EndProcedure

Procedure MapExpensesGLAccount(ExpensesGLAccount, ExpensesGLAccount_IncomingData, DefaultValue) Export
	
	MapGLAccount(ExpensesGLAccount, ExpensesGLAccount_IncomingData, DefaultValue);
	
EndProcedure

Procedure MapCell(Cell, Cell_IncomingData, DefaultValue) Export
	
	CatalogByName("Cells", Cell, Cell_IncomingData, DefaultValue);
	
EndProcedure

Procedure MapPriceGroup(PriceGroup, PriceGroup_IncomingData, DefaultValue) Export
	
	CatalogByName("PriceGroups", PriceGroup, PriceGroup_IncomingData, DefaultValue);
	
EndProcedure

Procedure MapOriginCountry(CountryOfOrigin, CountryOfOrigin_IncomingData, DefaultValue) Export
	
	If Not IsBlankString(CountryOfOrigin_IncomingData) Then
		
		CatalogRef = Catalogs.WorldCountries.FindByDescription(CountryOfOrigin_IncomingData, False);
		If Not ValueIsFilled(CatalogRef) Then
			
			CatalogRef = Catalogs.WorldCountries.FindByAttribute("AlphaCode3", CountryOfOrigin_IncomingData);
			If Not ValueIsFilled(CatalogRef) Then
				
				CatalogRef = Catalogs.WorldCountries.FindByCode(CountryOfOrigin_IncomingData, True);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(CatalogRef) Then
		
		CountryOfOrigin = CatalogRef;
		
	Else
		
		CountryOfOrigin = DefaultValue;
		
	EndIf;
	
EndProcedure

Procedure MapSerialNumber(ProductsRef, SerialNumber, SerialNumber_IncomingData) Export
	
	SerialNumber = Catalogs.SerialNumbers.FindByDescription(SerialNumber_IncomingData, True, , ProductsRef);
	
EndProcedure

// :::Purchase order
Procedure MatchOrder(Order, Order_IncomingData) Export
	
	If IsBlankString(Order_IncomingData) Then
		
		Return;
		
	EndIf;
	
	SuppliersTagsArray = New Array;
	SuppliersTagsArray.Add("Purchase order");
	SuppliersTagsArray.Add("PurchaseOrder");
	SuppliersTagsArray.Add("Vendor");
	SuppliersTagsArray.Add("Vendor");
	SuppliersTagsArray.Add("Post");
	
	NumberForSearch	= Order_IncomingData;
	DocumentKind	= "CustomerOrder";
	For Each TagFromArray In SuppliersTagsArray Do
		
		If Find(Order_IncomingData, TagFromArray) > 0 Then
			
			DocumentKind = "PurchaseOrder";
			NumberForSearch = TrimAll(StrReplace(NumberForSearch, "", TagFromArray));
			
		EndIf;
		
	EndDo;
	
	Query = New Query("Select Document.CustomerOrder.Ref Where Number LIKE &Number ORDER BY Date Desc");
	Query.SetParameter("Number", "%" + NumberForSearch + "%");
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		
		Order = Selection.Ref;
		
	EndIf;
	
EndProcedure

// :::Counterparty
Procedure MapCounterparty(Counterparty, TIN, CounterpartyDescription, BankAccount) Export
	
	// TIN Search
	If Not IsBlankString(TIN) Then
		
		Query = New Query("SELECT Catalog.Counterparties.Ref WHERE NOT IsFolder AND TIN = &TIN");
		Query.SetParameter("TIN", TIN);
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			
			Counterparty = Selection.Ref;
			Return;
			
		EndIf;
		
	EndIf;
	
	//Search Name
	If Not IsBlankString(CounterpartyDescription) Then
		
		CatalogRef = Catalogs.Counterparties.FindByDescription(CounterpartyDescription, False);
		If ValueIsFilled(CatalogRef) Then
			
			Counterparty = CatalogRef;
			Return;
			
		EndIf;
		
	EndIf;
	
	// Current account number
	If Not IsBlankString(BankAccount) Then
		
		CatalogRef = Catalogs.BankAccounts.FindByAttribute("AccountNo", BankAccount);
		If ValueIsFilled(CatalogRef) Then
			Counterparty = CatalogRef.Owner;
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure MapIndividualPerson(Individual, Individual_IncomingData) Export
	
	CatalogByName("Individuals", Individual, Individual_IncomingData, Undefined);
	
EndProcedure

Procedure MapAccessGroup(AccessGroup, AccessGroup_IncomingData) Export
	
	CatalogByName("CounterpartiesAccessGroups", AccessGroup, AccessGroup_IncomingData);
	
EndProcedure

Procedure MapGLAccountCustomerSettlements(GLAccountCustomerSettlements, GLAccountCustomerSettlements_IncomingData, DefaultValue) Export
	
	MapGLAccount(GLAccountCustomerSettlements, GLAccountCustomerSettlements_IncomingData, DefaultValue);
	
EndProcedure

Procedure MapCustomerAdvancesGLAccount(CustomerAdvancesGLAccount, CustomerAdvancesGLAccount_IncomingData, DefaultValue) Export
	
	MapGLAccount(CustomerAdvancesGLAccount, CustomerAdvancesGLAccount_IncomingData, DefaultValue);
	
EndProcedure

Procedure MapGLAccountVendorSettlements(GLAccountVendorSettlements, GLAccountVendorSettlements_IncomingData, DefaultValue) Export
	
	MapGLAccount(GLAccountVendorSettlements, GLAccountVendorSettlements_IncomingData, DefaultValue);
	
EndProcedure

Procedure MapVendorAdvancesGLAccount(VendorAdvancesGLAccount, VendorAdvancesGLAccount_IncomingData, DefaultValue) Export
	
	MapGLAccount(VendorAdvancesGLAccount, VendorAdvancesGLAccount_IncomingData, DefaultValue);
	
EndProcedure

// :::Prices

Procedure MapPriceKind(PriceKind, PriceKind_IncomingData, DefaultValue) Export
	
	CatalogByName("PriceKinds", PriceKind, PriceKind_IncomingData, DefaultValue);
	
EndProcedure

// :::Enter opening balance

Procedure MapContract(Counterparty, Contract, Contract_IncomingData) Export
	
	If ValueIsFilled(Counterparty) 
		AND ValueIsFilled(Contract_IncomingData) Then
		
		CatalogRef = Undefined;
		CatalogRef = Catalogs.CounterpartyContracts.FindByDescription(Contract_IncomingData, False, , Counterparty);
		If Not ValueIsFilled(CatalogRef) Then
			
			CatalogRef = Catalogs.CounterpartyContracts.FindByAttribute("ContractNo", Contract_IncomingData, , Counterparty);
			
		EndIf;
		
		If ValueIsFilled(CatalogRef) Then
			
			Contract = CatalogRef;
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure MapOrderByNumberDate(Order, DocumentTypeName, Counterparty, Number_IncomingData, Date_IncomingData) Export
	
	If IsBlankString(Number_IncomingData) Then
		
		Return;
		
	EndIf;
	
	If DocumentTypeName <> "PurchaseOrder" Then
		
		DocumentTypeName = "CustomerOrder"
		
	EndIf;
	
	TableName = "Document." + DocumentTypeName;
	
	Query = New Query("Select Order.Ref FROM &TableName AS Order Where Order.Counterparty = &Counterparty And Order.Number LIKE &Number");
	Query.Text = StrReplace(Query.Text, "&TableName", TableName);
	Query.SetParameter("Counterparty", Counterparty);
	Query.SetParameter("Number", "%" + Number_IncomingData + "%");
	
	If Not IsBlankString(Date_IncomingData) Then
		
		DateFromString = Date('00010101');
		ConvertStringToDate(DateFromString, Date_IncomingData);
		
		If ValueIsFilled(DateFromString) Then
			
			Query.Text = Query.Text + " And Order.Date Between &StartDate And &EndDate";
			Query.SetParameter("StartDate", BegOfDay(DateFromString));
			Query.SetParameter("EndDate", EndOfDay(DateFromString));
			
		EndIf;
		
	EndIf;
	
	Query.Text = Query.Text + " ORDER BY Order.Date DESC";
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		
		Order = Selection.Ref;
		
	EndIf;
	
EndProcedure

Procedure MapAccountingDocumentByNumberDate(Document, DocumentTypeName, Counterparty, Number_IncomingData, Date_IncomingData) Export
	
	If IsBlankString(DocumentTypeName) 
		OR IsBlankString(Number_IncomingData) Then
		
		Return;
		
	EndIf;
	
	MapDocumentNames = New Map;
	
	MapDocumentNames.Insert(NStr("en='CustomerOrder';ru='ЗаказПокупателя';vi='CustomerOrder'"),       "CustomerOrder");
	MapDocumentNames.Insert(NStr("en='Customer orders';ru='Заказы покупателей';vi='Đơn hàng của khách'"),	"CustomerOrder");
	MapDocumentNames.Insert(NStr("en='Customer order';ru='Заказ покупателя';vi='Đơn hàng của khách'"),		"CustomerOrder");
	
	MapDocumentNames.Insert(NStr("en='Customer orders';ru='Заказы покупателей';vi='Đơn hàng của khách'"),       "AcceptanceCertificate");
	MapDocumentNames.Insert(NStr("en='Customer order';ru='Заказ покупателя';vi='Đơn hàng của khách'"),	"AcceptanceCertificate");
	MapDocumentNames.Insert(NStr("en='AcceptanceCertificate';ru='АктВыполненныхРабот';vi='АктВыполненныхРабот'"),	"AcceptanceCertificate");
	
	MapDocumentNames.Insert(NStr("en='Acceptance certificates';ru='Акты выполненных работ';vi='Biên bản bàn giao'"),	"Netting");
	
	MapDocumentNames.Insert(NStr("en='AgentReport';ru='ОтчетКомиссионера';vi='AgentReport'"),   	"AgentReport");
	MapDocumentNames.Insert(NStr("en='Agent report';ru='Отчет комиссионера';vi='Bảng kê hàng hóa của người nhận bán hộ'"),		"AgentReport");
	MapDocumentNames.Insert(NStr("en='Agent report';ru='Отчет комиссионера';vi='Bảng kê hàng hóa của người nhận bán hộ'"),  "AgentReport");
	
	MapDocumentNames.Insert(NStr("en='Agent reports';ru='Отчеты комиссионеров';vi='Bảng kê hàng hóa của người nhận bán hộ'"),		"ProcessingReport");
	MapDocumentNames.Insert(NStr("en='Processing report';ru='Отчет о переработке';vi='Báo cáo nhận gia công'"),	"ProcessingReport");
	MapDocumentNames.Insert(NStr("en='Processing reports';ru='Отчеты о переработке';vi='Báo cáo nhận gia công'"),	"ProcessingReport");
	
	MapDocumentNames.Insert(NStr("en='CashReceipt';ru='ПоступлениеВКассу';vi='CashReceipt'"),			"CashReceipt");
	MapDocumentNames.Insert(NStr("en='Petty cash receipt';ru='Поступление в кассу';vi='Thu tiền vào quỹ'"),	"CashReceipt");
	MapDocumentNames.Insert(NStr("en = 'OCR'; ru = 'ПКО'; vi = 'Phiếu thu'"),								  	"CashReceipt");
	
	MapDocumentNames.Insert(NStr("en='PaymentReceipt';ru='ПоступлениеНаСчет';vi='PaymentReceipt'"),		"PaymentReceipt");
	MapDocumentNames.Insert(NStr("en='Payment receipt';ru='Поступление на счет';vi='Thu tiền vào tài khoản'"),		"PaymentReceipt");
	
	MapDocumentNames.Insert(NStr("en='FixedAssetsTransfer';ru='ПродажаИмущества';vi='FixedAssetsTransfer'"),	"FixedAssetsTransfer");
	MapDocumentNames.Insert(NStr("en='Property sale';ru='Продажа имущества';vi='Bán tài sản'"),	"FixedAssetsTransfer");
	
	MapDocumentNames.Insert(NStr("en='CustomerInvoice';ru='РасходнаяНакладная';vi='CustomerInvoice'"),			"CustomerInvoice");
	MapDocumentNames.Insert(NStr("en='Invoice';ru='РасходнаяНакладная';vi='Invoice'"),					"CustomerInvoice");
	MapDocumentNames.Insert(NStr("en='Invoice';ru='Расходная накладная';vi='Hóa đơn xuất hàng'"),		"CustomerInvoice");
	
	MapDocumentNames.Insert(NStr("en='ExpenseReport';ru='АвансовыйОтчет';vi='АвансовыйОтчет'"), 		"ExpenseReport");
	MapDocumentNames.Insert(NStr("en='Expense report';ru='Авансовый отчет';vi='Giấy thanh toán tạm ứng'"), 		"ExpenseReport");
	MapDocumentNames.Insert(NStr("en='Expense reports';ru='Авансовые отчеты';vi='Giấy thanh toán tạm ứng'"),	"ExpenseReport");
	
	MapDocumentNames.Insert(NStr("en='AdditionalExpenses';ru='ДополнительныеРасходы';vi='AdditionalExpenses'"), 	"AdditionalCosts");
	MapDocumentNames.Insert(NStr("en='AdditionalExpenses';ru='ДополнительныеРасходы';vi='AdditionalExpenses'"), 	"AdditionalCosts");
	
	MapDocumentNames.Insert(NStr("en='Additional expenses';ru='Дополнительные расходы';vi='Chi phí bổ sung'"), 	"ReportToPrincipal");
	MapDocumentNames.Insert(NStr("en='Additional expenses';ru='Дополнительные расходы';vi='Chi phí bổ sung'"), "ReportToPrincipal");
	MapDocumentNames.Insert(NStr("en='Reports to principals';ru='Отчеты комитентам';vi='Báo cáo dành cho người đặt ký gửi'"), "ReportToPrincipal");
	
	MapDocumentNames.Insert(NStr("en='SubcontractorReport';ru='ОтчетПереработчика';vi='SubcontractorReport'"),	"SubcontractorReport");
	MapDocumentNames.Insert(NStr("en='Subcontractor report';ru='Отчет переработчика';vi='Báo cáo của người nhận gia công'"), "SubcontractorReport");
	MapDocumentNames.Insert(NStr("en='Processor reports';ru='Отчеты переработчика';vi='Báo cáo của người nhận gia công'"), 	"SubcontractorReport");
	
	MapDocumentNames.Insert(NStr("en='SupplierInvoice';ru='ПриходнаяНакладная';vi='SupplierInvoice'"), 		"SupplierInvoice");
	MapDocumentNames.Insert(NStr("en='Supplier invoice';ru='Приходная накладная';vi='Hóa đơn nhập hàng'"), 	"SupplierInvoice");
	MapDocumentNames.Insert(NStr("en='Supplier invoices';ru='Приходные накладные';vi='Hóa đơn nhập hàng'"),	"SupplierInvoice");
	
	MapDocumentNames.Insert(NStr("en='CashVoucher';ru='РасходИзКассы';vi='CashVoucher'"), 	 "CashPayment");
	MapDocumentNames.Insert(NStr("en = 'Cash payment'; ru = 'Расход из кассы'; vi = 'Chi từ quỹ tiền mặt'"), "CashPayment");
	MapDocumentNames.Insert(NStr("en = 'CPV'; ru = 'РКО'; vi = 'Phiếu chi'"), 					 "CashPayment");
	
	MapDocumentNames.Insert(NStr("en='PaymentExpense';ru='РасходСоСчета';vi='PaymentExpense'"), 	"PaymentExpense");
	MapDocumentNames.Insert(NStr("en = 'CPV'; ru = 'РКО'; vi = 'Phiếu chi'"), "PaymentExpense");
	
	DocumentType = MapDocumentNames.Get(DocumentTypeName);
	If DocumentType = Undefined Then
		
		Return;
		
	EndIf;
	
	TableName = "Document." + DocumentType;
	
	Query = New Query("Select AccountingDocument.Ref FROM &TableName AS AccountingDocument Where AccountingDocument.Counterparty = &Counterparty And AccountingDocument.Number LIKE &Number");
	Query.Text = StrReplace(Query.Text, "&TableName", TableName);
	Query.SetParameter("Counterparty", Counterparty);
	Query.SetParameter("Number", "%" + Number_IncomingData + "%");
	
	If Not IsBlankString(Date_IncomingData) Then
		
		DateFromString = Date('00010101');
		ConvertStringToDate(DateFromString, Date_IncomingData);
		
		If ValueIsFilled(DateFromString) Then
			
			Query.Text = Query.Text + " And AccountingDocument.Date Between &StartDate And &EndDate";
			Query.SetParameter("StartDate", BegOfDay(DateFromString));
			Query.SetParameter("EndDate", EndOfDay(DateFromString));
			
		EndIf;
		
	EndIf;
	
	Query.Text = Query.Text + " ORDER BY AccountingDocument.Date Desc";
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		
		Document = Selection.Ref;
		
	EndIf;
	
EndProcedure

Procedure MapAccountByNumberDate(Account, Counterparty, Number_IncomingData, Date_IncomingData, DocumentName) Export
	
	If IsBlankString(Number_IncomingData) Then
		
		Return;
		
	EndIf;
	
	Query = New Query("Select Account.Ref FROM &Table AS Account Where Account.Counterparty = &Counterparty And Account.Number LIKE &Number");
	Query.Text = StrReplace(Query.Text, "&Table", "Document."+DocumentName);
	Query.SetParameter("Counterparty", Counterparty);
	Query.SetParameter("Number", "%" + Number_IncomingData + "%");
	
	If Not IsBlankString(Date_IncomingData) Then
		
		DateFromString = Date('00010101');
		ConvertStringToDate(DateFromString, Date_IncomingData);
		
		If ValueIsFilled(DateFromString) Then
			
			Query.Text = Query.Text + " And Account.Date Between &StartDate And &EndDate";
			Query.SetParameter("StartDate", BegOfDay(DateFromString));
			Query.SetParameter("EndDate", EndOfDay(DateFromString));
			
		EndIf;
		
	EndIf;
	
	Query.Text = Query.Text + " ORDER BY Account.Date DESC";
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		
		Account = Selection.Ref;
		
	EndIf;
	
EndProcedure

#EndRegion
 

