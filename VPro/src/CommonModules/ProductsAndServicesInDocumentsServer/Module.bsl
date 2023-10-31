
#Region ProgramInterface

#Region WorkWithTabularSectionOfProductsAndServices

//Заполняет поля табличной части Запасы признаками использования характеристик
//
//Parameters:
//FormOpening - Булево. Устанавливается в значение - Истина, если заполнение происходит при открытии формы. 
Procedure FillCharacteristicsUsageFlags(Object, FormOpening = False) Export
	
	UseCharacteristics = GetFunctionalOption("UseCharacteristics");
	UseBatches = GetFunctionalOption("UseBatches");
	
	If Not UseBatches And Not UseCharacteristics Then Return EndIf;
	
	ObjectMetadata = Object.Ref.Metadata();
	
	TabularSectionsNamesArray = New Array;
	
	For Each TabularSection In ObjectMetadata.TabularSections	Do
		
		If Not TabularSection.Attributes.Find("Characteristic") = Undefined
			Then
			TabularSectionsNamesArray.Add(TabularSection.Name);
		EndIf;
		
	EndDo;
	
	//IsDocumentReceiptAdjustment = ?(TypeOf(Object.Ref) = Type("DocumentRef.PurchaseAdjustment"),True, False);
	//IsDocumentImplementationAdjustment = ?(TypeOf(Object.Ref) = Type("DocumentRef.SalesAdjustment"),True, False);
	IsDocumentPurchaseOrder = ?(TypeOf(Object.Ref) = Type("DocumentRef.PurchaseOrder"),True, False);
	IsDocumentInvoiceForPaymentReceived = ?(TypeOf(Object.Ref) = Type("DocumentRef.SupplierInvoiceForPayment"),True, False);
	
	DontCheckServices = ?(IsDocumentPurchaseOrder Or IsDocumentInvoiceForPaymentReceived, True, False);
	
	Query = New Query;
	
	//If IsDocumentReceiptAdjustment Then
	//	
	//	QueryText =
	//	"SELECT
	//	|	CAST(DocumentProductsAndServicesTable.ProductsAndServices AS Catalog.ProductsAndServices) AS Ref,
	//	|	DocumentProductsAndServicesTable.LineNumber AS ProductsAndServicesLineNumber,
	//	|	DocumentProductsAndServicesTable.Characteristic AS Characteristic,
	//	|	DocumentProductsAndServicesTable.HasInReceiptDocument AS HasInReceiptDocument
	//	|INTO SelectionFromTabularSectionInventory
	//	|FROM
	//	|	&TSName AS DocumentProductsAndServicesTable
	//	|;
	//	|
	//	|////////////////////////////////////////////////////////////////////////////////
	//	|SELECT
	//	|	SelectionFromTabularSectionInventory.ProductsAndServicesLineNumber AS ProductsAndServicesLineNumber,
	//	|	CASE
	//	|		WHEN NOT SelectionFromTabularSectionInventory.Ref.UseCharacteristics
	//	|				AND NOT SelectionFromTabularSectionInventory.Characteristic = VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	//	|			THEN TRUE
	//	|		ELSE SelectionFromTabularSectionInventory.Ref.UseCharacteristics
	//	|	END AS UseCharacteristics,
	//	|	SelectionFromTabularSectionInventory.Ref.CheckCharacteristicFilling AS CheckCharacteristicFilling,
	//	|	SelectionFromTabularSectionInventory.HasInReceiptDocument AS HasInReceiptDocument,
	//	|	TRUE AS FillingCharacteristicChecked,
	//	|	SelectionFromTabularSectionInventory.Ref.UseBatches AS UseBatches,
	//	|	SelectionFromTabularSectionInventory.Ref.CheckBatchFilling AS CheckBatchFilling
	//	|FROM
	//	|	SelectionFromTabularSectionInventory AS SelectionFromTabularSectionInventory
	//	|		LEFT JOIN InformationRegister.DefaultProductsAndServicesValues AS DefaultProductsAndServicesValues
	//	|		ON SelectionFromTabularSectionInventory.Ref = DefaultProductsAndServicesValues.ProductsAndServices
	//	|
	//	|ORDER BY
	//	|	ProductsAndServicesLineNumber";
		
	//ElsIf IsDocumentImplementationAdjustment Then
	//	QueryText =
	//	"SELECT
	//	|	CAST(DocumentProductsAndServicesTable.ProductsAndServices AS Catalog.ProductsAndServices) AS Ref,
	//	|	DocumentProductsAndServicesTable.LineNumber AS ProductsAndServicesLineNumber,
	//	|	DocumentProductsAndServicesTable.Characteristic AS Characteristic,
	//	|	DocumentProductsAndServicesTable.HasInSalesDocument AS HasInSalesDocument
	//	|INTO SelectionFromTabularSectionInventory
	//	|FROM
	//	|	&TSName AS DocumentProductsAndServicesTable
	//	|;
	//	|
	//	|////////////////////////////////////////////////////////////////////////////////
	//	|SELECT
	//	|	SelectionFromTabularSectionInventory.ProductsAndServicesLineNumber AS ProductsAndServicesLineNumber,
	//	|	CASE
	//	|		WHEN NOT SelectionFromTabularSectionInventory.Ref.UseCharacteristics
	//	|				AND NOT SelectionFromTabularSectionInventory.Characteristic = VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	//	|			THEN TRUE
	//	|		ELSE SelectionFromTabularSectionInventory.Ref.UseCharacteristics
	//	|	END AS UseCharacteristics,
	//	|	SelectionFromTabularSectionInventory.Ref.CheckCharacteristicFilling AS CheckCharacteristicFilling,
	//	|	SelectionFromTabularSectionInventory.HasInSalesDocument AS HasInSalesDocument,
	//	|	TRUE AS FillingCharacteristicChecked,
	//	|	SelectionFromTabularSectionInventory.Ref.UseBatches AS UseBatches,
	//	|	SelectionFromTabularSectionInventory.Ref.CheckBatchFilling AS CheckBatchFilling
	//	|FROM
	//	|	SelectionFromTabularSectionInventory AS SelectionFromTabularSectionInventory
	//	|		LEFT JOIN InformationRegister.DefaultProductsAndServicesValues AS DefaultProductsAndServicesValues
	//	|		ON SelectionFromTabularSectionInventory.Ref = DefaultProductsAndServicesValues.ProductsAndServices
	//	|
	//	|ORDER BY
	//	|	ProductsAndServicesLineNumber";
	//Else
		
		QueryText =
		"SELECT DISTINCT
		|	ProductsAndServices.Ref AS ProductsAndServices,
		|	ProductsAndServices.UseBatches AS UseBatches,
		|	ProductsAndServices.UseCharacteristics AS UseCharacteristics,
		//|	ProductsAndServices.CheckCharacteristicFilling AS CheckCharacteristicFilling,
		//|	ProductsAndServices.CheckBatchFilling AS CheckBatchFilling,
		|	CASE
		|		WHEN ProductsAndServices.ProductsAndServicesType = VALUE(Enum.ProductsAndServicesTypes.Service)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS IsService,
		|	TRUE AS FillingCharacteristicChecked
		|FROM
		|	Catalog.ProductsAndServices AS ProductsAndServices
		|WHERE
		|	ProductsAndServices.Ref IN(&ProductsAndServicesToCheckArray)
		|	AND NOT ProductsAndServices.ProductsAndServicesType = VALUE(Enum.ProductsAndServicesTypes.Service)";
		
	//EndIf;
	
	ProductsAndServicesToCheckArray = New Array;
	
	//Если Не ОткрытиеФормы Тогда
	
	QueryBatchesCount = 1;
	
	TabularSectionsMapToPackageIndices = New Map();
	
	For Each TabularSectionName In TabularSectionsNamesArray Do
		
		NotCheckedRowsFilter = New Structure("FillingCharacteristicChecked", False);
		NotValidatedStringsArray = Object[TabularSectionName].FindRows(NotCheckedRowsFilter);
		
		DocumentProductsAndServicesTable = Object[TabularSectionName].Unload(NotValidatedStringsArray,"ProductsAndServices, LineNumber, Characteristic"); 
		//If IsDocumentReceiptAdjustment Then
		//	
		//	If Not Object[TabularSectionName].Count() Then Continue EndIf;
		//	
		//	DocumentProductsAndServicesTable = Object[TabularSectionName].Unload(NotValidatedStringsArray,"ProductsAndServices, LineNumber, Characteristic, HasInReceiptDocument");
		//ElsIf IsDocumentImplementationAdjustment Then
		//	
		//	If Not Object[TabularSectionName].Count() Then Continue EndIf;
		//	
		//	DocumentProductsAndServicesTable = Object[TabularSectionName].Unload(NotValidatedStringsArray,"ProductsAndServices, LineNumber, Characteristic, HasInSalesDocument");
		//Else
		
		If Not Object[TabularSectionName].Count() Then Continue EndIf;
		
		For Each TableRow In Object[TabularSectionName] Do
			
			If TableRow.FillingCharacteristicChecked Then Continue EndIf;
			
			ProductsAndServicesToCheckArray.Add(TableRow.ProductsAndServices);
			
		EndDo;
		
		Continue;
			
		//EndIf;
		
		TextPacket = QueryText;
		
		TextPacket = StrReplace(TextPacket, "&TSName", "&"+TabularSectionName);
		TextPacket = StrReplace(TextPacket, "SelectionFromTabularSectionInventory", "SelectionFromTabularSectionInventory"+TabularSectionName);
		
		Query.Text = Query.Text + TextPacket + "
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
		Query.SetParameter(TabularSectionName, DocumentProductsAndServicesTable);
		
		TabularSectionsMapToPackageIndices.Insert(QueryBatchesCount, TabularSectionName);
		QueryBatchesCount = QueryBatchesCount + 2;
		
	EndDo;
	
	If Not ValueIsFilled(Query.Text) And Not ProductsAndServicesToCheckArray.Count() Then Return EndIf;
	
	PackageIndex = 1;
	
	//If IsDocumentReceiptAdjustment Then
		
		//QueryBatch = Query.ExecuteBatch();
		//
		//While PackageIndex <= QueryBatch.Count()-1 Do
		//	
		//	SelectionByCharacteristics = QueryBatch[PackageIndex].Select();
		//	
		//	TabularSectionName = TabularSectionsMapToPackageIndices.Get(PackageIndex);
		//	
		//	While SelectionByCharacteristics.Next() Do
		//		
		//		If SelectionByCharacteristics.HasInReceiptDocument Then
		//			Continue;
		//		EndIf;
		//		
		//		TabSectionRow = Object[TabularSectionName][SelectionByCharacteristics.ProductsAndServicesLineNumber-1];
		//		FillPropertyValues(TabSectionRow,SelectionByCharacteristics);
		//		
		//		If TabSectionRow.Property("Batch") And ValueIsFilled(TabSectionRow.Batch) Then
		//			TabSectionRow.UseBatches = True
		//		EndIf;
		//		
		//	EndDo;
		//	
		//	PackageIndex = PackageIndex + 2;
		//	
		//EndDo;
		
	//ElsIf IsDocumentImplementationAdjustment Then
	//	
	//	QueryBatch = Query.ExecuteBatch();
	//	
	//	While PackageIndex <= QueryBatch.Count()-1 Do
	//		
	//		SelectionByCharacteristics = QueryBatch[PackageIndex].Select();
	//		
	//		TabularSectionName = TabularSectionsMapToPackageIndices.Get(PackageIndex);
	//		
	//		While SelectionByCharacteristics.Next() Do
	//			
	//			If SelectionByCharacteristics.HasInSalesDocument Then
	//				Continue;
	//			EndIf;
	//			
	//			TabSectionRow = Object[TabularSectionName][SelectionByCharacteristics.ProductsAndServicesLineNumber-1];
	//			FillPropertyValues(TabSectionRow,SelectionByCharacteristics);
	//			
	//			If TabSectionRow.Property("Batch") And ValueIsFilled(TabSectionRow.Batch) Then
	//				TabSectionRow.UseBatches = True
	//			EndIf;
	//			
	//		EndDo;
	//		
	//		PackageIndex = PackageIndex + 2;
	//		
	//	EndDo;
		
	//Else
		
		If DontCheckServices = False Then
			QueryText = StrReplace(QueryText,"AND NOT ProductsAndServices.ProductsAndServicesType = VALUE(Enum.ProductsAndServicesTypes.Service)","");
		EndIf;
		
		Query.Text = QueryText;
		
		Query.SetParameter("ProductsAndServicesToCheckArray", ProductsAndServicesToCheckArray);
		SelectionByCharacteristics = Query.Execute().Select();
		
		For Each TabularSectionName In TabularSectionsNamesArray Do
			
			For Each TabSectionRow In Object[TabularSectionName] Do
				
				FilterParameters = New Structure("ProductsAndServices", TabSectionRow.ProductsAndServices);
				
				FoundString = SelectionByCharacteristics.FindNext(FilterParameters);
				
				If FoundString Then
					FillPropertyValues(TabSectionRow, SelectionByCharacteristics);
					
					If TabSectionRow.Property("Batch") And ValueIsFilled(TabSectionRow.Batch) Then
						TabSectionRow.UseBatches = True
					EndIf;
					
					If TabSectionRow.Property("Characteristic") And ValueIsFilled(TabSectionRow.Characteristic) Then
						TabSectionRow.UseCharacteristics = True
					EndIf;
				EndIf;
				
				SelectionByCharacteristics.Reset();
				
			EndDo;
		EndDo
		
	//EndIf;
	
EndProcedure

//Получает значение характеристики номенклатуры по умолчанию
//
Function DefaultProductsAndServicesValues(ProductsAndServices) Export
	
	If ProductsAndServices.ThisIsSet Then
		Return Undefined
	EndIf;
	
	Query = New Query;
	
	Query.SetParameter("ProductsAndServices", ProductsAndServices);
	Query.SetParameter("Category", ProductsAndServices.ProductsAndServicesCategory);
	
	Query.Text = "SELECT ALLOWED
	|	CASE
	|		WHEN DefaultProductsAndServicesValuesProductsAndServices.Characteristic = VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	|			THEN DefaultProductsAndServicesValuesProductsAndServices.Characteristic
	|		ELSE CASE
	|				WHEN DefaultProductsAndServicesValuesProductsAndServices.Characteristic.Owner = DefaultProductsAndServicesValuesProductsAndServices.ProductsAndServices
	|					THEN DefaultProductsAndServicesValuesProductsAndServices.Characteristic
	|				ELSE CASE
	|						WHEN DefaultProductsAndServicesValuesProductsAndServices.ProductsAndServices.ProductsAndServicesCategory = DefaultProductsAndServicesValuesProductsAndServices.Characteristic.Owner
	|							THEN DefaultProductsAndServicesValuesProductsAndServices.Characteristic
	|						ELSE UNDEFINED
	|					END
	|			END
	|	END AS Characteristic
	|FROM
	|	InformationRegister.DefaultProductsAndServicesValues AS DefaultProductsAndServicesValuesProductsAndServices
	|WHERE
	|	(CAST(DefaultProductsAndServicesValuesProductsAndServices.ProductsAndServices AS Catalog.ProductsAndServices)) = &ProductsAndServices
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	DefaultProductsAndServicesValuesCategories.Characteristic AS CategoryCharacteristic
	|FROM
	|	InformationRegister.DefaultProductsAndServicesValues AS DefaultProductsAndServicesValuesCategories
	|WHERE
	|	(CAST(DefaultProductsAndServicesValuesCategories.ProductsAndServices AS Catalog.ProductsAndServicesCategories)) = &Category";
	
	QueryResult = Query.ExecuteBatch();
	ResultByProductsAndServices = QueryResult[0].Select();
	
	If ResultByProductsAndServices.Next() Then
		Return ResultByProductsAndServices.Characteristic
	EndIf;
	
	ResultByCategory = QueryResult[1].Select();
	
	If ResultByCategory.Next() And ValueIsFilled(ResultByCategory.CategoryCharacteristic) Then
		Return ResultByCategory.CategoryCharacteristic
	EndIf;
	
	Return Undefined;
	
EndFunction

//Проверяет,в зависимости от использования, заполнение характеристик номенклатуры
//
Procedure CheckCharacteristicsFilling(Object, cancel, CheckBatchFilling = False, TSNamesToExcludeBatchChecks = Undefined) Export
	
	ListOfTSNamesToExcludeBatchChecks = New ValueList;
	
	If Not TSNamesToExcludeBatchChecks = Undefined Then
		ListOfTSNamesToExcludeBatchChecks = TSNamesToExcludeBatchChecks;
	EndIf;
	
	If cancel Then Return EndIf;
	
	If CheckBatchFilling And Not Object.Metadata().Attributes.Find("OperationKind") = Undefined
		And (Object.OperationKind = Enums.OperationKindsSupplierInvoice.ReceptionIntoProcessing 
		Or Object.OperationKind = Enums.OperationKindsSupplierInvoice.ReceptionForCommission 
		Or Object.OperationKind = Enums.OperationKindsSupplierInvoice.ReceptionForSafeCustody) Then
		
		CheckBatchFilling = False;
	EndIf;
	
//	IsDocumentReceiptAdjustment = ?(TypeOf(Object.Ref) = Type("DocumentRef.PurchaseAdjustment"),True, False);
//	IsDocumentImplementationAdjustment = ?(TypeOf(Object.Ref) = Type("DocumentRef.SalesAdjustment"),True, False);
//	IsInventoryRecalculationDocument = ?(TypeOf(Object.Ref) = Type("DocumentRef.InventoryRegrading"),True, False);
	IsDocumentPurchaseOrder = ?(TypeOf(Object.Ref) = Type("DocumentRef.PurchaseOrder"),True, False);
	IsDocumentInvoiceForPaymentReceived = ?(TypeOf(Object.Ref) = Type("DocumentRef.SupplierInvoiceForPayment"),True, False);
	
	ObjectMetadata = Object.Ref.Metadata();
	
	TabularSectionsNamesArray = New Array;
	
	For Each TabularSection In ObjectMetadata.TabularSections Do
		If Not TabularSection.Attributes.Find("Characteristic") = Undefined Then
			
			If TabularSection.Name = "Calculation" Then Continue EndIf;
			
			If TabularSection.Name = "InventoryDistribution" 
				And Object.Metadata().Attributes.Find("ManualDistribution") <> Undefined 
				And Not Object.ManualDistribution Then
				// При автоматическом распределении контроль табличной части не выполняется, она имеет служебный характер
				Continue;
			EndIf; 
			
			TabularSectionsNamesArray.Add(TabularSection.Name);
			
		EndIf;
	EndDo;
	
	DontCheckServices = ?(IsDocumentPurchaseOrder Or IsDocumentInvoiceForPaymentReceived, True, False);
	
	UseCharacteristics = GetFunctionalOption("UseCharacteristics");
	UseBatches = GetFunctionalOption("UseBatches");
	
	For Each TabularSectionName In TabularSectionsNamesArray Do
		
		CheckBatches = False;
		
		If CheckBatchFilling 
			And Not ObjectMetadata.TabularSections[TabularSectionName].Attributes.Find("Batch") = Undefined Then
			
			CheckBatches = ?(Not ListOfTSNamesToExcludeBatchChecks.FindByValue(TabularSectionName) = Undefined, False, True);
			
		EndIf;
		
		AttributesTable = ValueTableOfTabularSectionProductsAndServicesAttributesValues(Object[TabularSectionName]);
		
		For Each RowInventory In Object[TabularSectionName] Do
			
			ProductsAndServices = RowInventory.ProductsAndServices;
			
			If Not ValueIsFilled(ProductsAndServices) Then Continue EndIf;
			
			LineNumber = RowInventory.LineNumber;
			
			IsProductsAndServices = ?(TypeOf(ProductsAndServices) = Type("CatalogRef.ProductsAndServices"), True, False);
			
			If Not IsProductsAndServices Then Continue EndIf;
			
			IsFolder = AttributesTable[LineNumber-1].IsFolder;
			If IsFolder Then Continue EndIf;
			
			//CheckCharacteristicFilling = AttributesTable[LineNumber-1].CheckCharacteristicFilling;
			//CheckBatchFilling = AttributesTable[LineNumber-1].CheckBatchFilling;
			
			//CheckCharacteristicsFillingInPartTab = CheckCharacteristicFilling And UseCharacteristics;
			//CheckBatchFillingInPartTab = CheckBatchFilling And UseBatches;
			
			//If (IsDocumentReceiptAdjustment And RowInventory.HasInReceiptDocument) 
			//	Or (IsDocumentImplementationAdjustment And RowInventory.HasInSalesDocument) Then
			//	Continue;
			//EndIf;
			
			ProductsAndServicesType = AttributesTable[LineNumber-1].ProductsAndServicesType;
			
			If DontCheckServices And ProductsAndServicesType = Enums.ProductsAndServicesTypes.Service Then
				Continue;
			EndIf;
			
			//If CheckCharacteristicsFillingInPartTab
			//	And Not ValueIsFilled(RowInventory.Characteristic) Then
			//	MessageText = NStr("ru = 'В таблице %Table%, для номенклатуры %1% в строке %Number%, заполнение поля ""характеристика"" является обязательным. ';
			//							|en = 'В таблице %Table%, для номенклатуры %1% в строке %Number%, заполнение поля ""характеристика"" является обязательным. ';");
			//	MessageText = StrReplace(MessageText, "%1%", String(ProductsAndServices));
			//	MessageText = StrReplace(MessageText, "%Number%", LineNumber);
			//	MessageText = StrReplace(MessageText, "%Table%", TabularSectionName);
			//	
			//	SmallBusinessServer.ShowMessageAboutError(
			//	Object,
			//	MessageText,
			//	TabularSectionName,
			//	LineNumber,
			//	"Characteristic",
			//	cancel
			//	);
			//EndIf;
			
			//If CheckBatches
			//	And CheckBatchFillingInPartTab
			//	And Not ValueIsFilled(RowInventory.Batch) Then
			//	
			//	MessageText = NStr("ru = 'В таблице %Table%, для номенклатуры %1% в строке %Number%, заполнение поля ""партия"" является обязательным. ';
			//							|en = 'В таблице %Table%, для номенклатуры %1% в строке %Number%, заполнение поля ""партия"" является обязательным. ';");
			//	MessageText = StrReplace(MessageText, "%1%", String(ProductsAndServices));
			//	MessageText = StrReplace(MessageText, "%Number%", LineNumber);
			//	MessageText = StrReplace(MessageText, "%Table%", TabularSectionName);
			//	
			//	SmallBusinessServer.ShowMessageAboutError(
			//	Object,
			//	MessageText,
			//	TabularSectionName,
			//	LineNumber,
			//	"Batch",
			//	cancel
			//	);
			//EndIf;
			
			//If IsInventoryRecalculationDocument
			//	And CheckCharacteristicsFillingInPartTab
			//	And Not ValueIsFilled(RowInventory.CharacteristicReceivedPosting) Then
			//	
			//	MessageText = NStr("ru = 'В таблице %Table%, для номенклатуры %1% в строке %Number%, заполнение поля ""характеристика"" является обязательным. ';
			//							|en = 'В таблице %Table%, для номенклатуры %1% в строке %Number%, заполнение поля ""характеристика"" является обязательным. ';");
			//	MessageText = StrReplace(MessageText, "%1%", String(RowInventory.ProductsAndServicesReceivedPosting));
			//	MessageText = StrReplace(MessageText, "%Number%", LineNumber);
			//	MessageText = StrReplace(MessageText, "%Table%", TabularSectionName);
			//	
			//	SmallBusinessServer.ShowMessageAboutError(
			//	Object,
			//	MessageText,
			//	TabularSectionName,
			//	LineNumber,
			//	"CharacteristicReceivedPosting",
			//	cancel
			//	);
			//EndIf;
			
			//If IsInventoryRecalculationDocument And CheckBatches
			//	And CheckBatchFillingInPartTab
			//	And Not ValueIsFilled(RowInventory.BatchReceivedPosting) Then
			//	
			//	MessageText = NStr("ru = 'В таблице %Table%, для номенклатуры %1% в строке %Number%, заполнение поля ""партия"" является обязательным. ';
			//							|en = 'В таблице %Table%, для номенклатуры %1% в строке %Number%, заполнение поля ""партия"" является обязательным. ';");
			//	MessageText = StrReplace(MessageText, "%1%", String(RowInventory.ProductsAndServicesReceivedPosting));
			//	MessageText = StrReplace(MessageText, "%Number%", LineNumber);
			//	MessageText = StrReplace(MessageText, "%Table%", TabularSectionName);
			//	
			//	SmallBusinessServer.ShowMessageAboutError(
			//	Object,
			//	MessageText,
			//	TabularSectionName,
			//	LineNumber,
			//	"BatchReceivedPosting",
			//	cancel
			//	);
			//EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

//Обновляет условное оформление колонки "Характеристика" для формы документа
//Форма - Форма объекта для условного оформления
//СоответствиеИменТабличныхЧастей - Соответствие Имя Табличной части -> Имя колонки табличной части
Procedure UpdateTabularSectionConditionalAppearanceForCharacteristics(Form, TabularSectionsNamesMap = Undefined) Export  
	
	UseCharacteristics = GetFunctionalOption("UseCharacteristics");
	UseBatches = GetFunctionalOption("UseBatches");
	
	If Not UseBatches And Not UseCharacteristics Then Return EndIf;
	
	If Form.FormName = "Document.ProductionOrder.Form.DocumentForm" 
		Or Form.FormName = "Document.InventoryAssembly.Form.DocumentForm" Then
		
		FieldDescriptionCharacteristic = "InventoryDistributionCharacteristic";
		FieldDescriptionBatch = "InventoryDistributionBatch";
		
		SearchValue = Form.Items.Find(FieldDescriptionCharacteristic);
		
		SearchValueBatch = Form.Items.Find(FieldDescriptionBatch);
		
		If UseCharacteristics And Not SearchValue = Undefined Then
			
			FieldNameCheckCharacteristicFilling = "InventoryDistribution.CheckCharacteristicFilling";
			FieldNameUseCharacteristics = "InventoryDistribution.UseCharacteristics";
			CharacteristicFieldName = FieldDescriptionCharacteristic;
			
			NewConditionalAppearance = Form.ConditionalAppearance.Items.Add();
			WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, FieldNameUseCharacteristics, False, DataCompositionComparisonType.Equal);
			
			WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, CharacteristicFieldName);
			WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Text", NStr("en='<Not used>';ru='<Не используется>';vi='<Không sử dụng>'"));
			WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "ReadOnly", True);
			WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.TabularSectionUnavailableTextColor);
			
			NewConditionalAppearance = Form.ConditionalAppearance.Items.Add();
			WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, FieldNameCheckCharacteristicFilling, True, DataCompositionComparisonType.Equal);
			
			WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, CharacteristicFieldName);
			WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "MarkIncomplete", True);
			
			NewConditionalAppearance = Form.ConditionalAppearance.Items.Add();
			WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "InventoryDistribution.Characteristic", Catalogs.ProductsAndServicesCharacteristics.EmptyRef(), DataCompositionComparisonType.NotEqual);
			WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, CharacteristicFieldName);
			
			WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "MarkIncomplete", False);
		EndIf;
		
		If UseBatches And Not SearchValueBatch = Undefined Then
			FieldNameCheckBatchFilling = "InventoryDistribution.CheckBatchFilling";
			UseBatchesFieldName = "InventoryDistribution.UseBatches";
			BatchFieldName = FieldDescriptionBatch;
			
			NewConditionalAppearance = Form.ConditionalAppearance.Items.Add();
			WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, UseBatchesFieldName, False, DataCompositionComparisonType.Equal);
			
			WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, BatchFieldName);
			WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Text", NStr("en='<Not used>';ru='<Не используется>';vi='<Không sử dụng>'"));
			WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "ReadOnly", True);
			WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.TabularSectionUnavailableTextColor);
			
			NewConditionalAppearance = Form.ConditionalAppearance.Items.Add();
			WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, FieldNameCheckBatchFilling, True, DataCompositionComparisonType.Equal);
			
			WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, BatchFieldName);
			WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "MarkIncomplete", True);
			
			NewConditionalAppearance = Form.ConditionalAppearance.Items.Add();
			
			WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "InventoryDistribution.Batch", Catalogs.ProductsAndServicesBatches.EmptyRef(), DataCompositionComparisonType.NotEqual);
			WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, BatchFieldName);
			WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "MarkIncomplete", False);
		EndIf;
	EndIf;
	
	If TabularSectionsNamesMap = Undefined Then
		
		ObjectMetadata = Form.Object.Ref.Metadata();
		
		For Each TabularSection In ObjectMetadata.TabularSections Do
			If UseCharacteristics And Not TabularSection.Attributes.Find("Characteristic") = Undefined Then
				FieldDescription = TabularSection.Name + "Characteristic";
				SearchValue = Form.Items.Find(FieldDescription);
				
				If Not SearchValue = Undefined And TypeOf(SearchValue.Parent) = Type("FormTable") Then
					FieldNameCheckCharacteristicFilling = SearchValue.Parent.DataPath + ".CheckCharacteristicFilling";
					FieldNameUseCharacteristics = SearchValue.Parent.DataPath+".UseCharacteristics";
					CharacteristicFieldName = FieldDescription; 
					
					NewConditionalAppearance = Form.ConditionalAppearance.Items.Add();
					WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, FieldNameUseCharacteristics, False, DataCompositionComparisonType.Equal);
					
					If Form.FormName = "Document.PurchaseAdjustment.Form.DocumentForm" Then
						WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, SearchValue.Parent.DataPath + ".HasInReceiptDocument", False, DataCompositionComparisonType.Equal);
					EndIf; 
					
					If Form.FormName = "Document.SalesAdjustment.Form.DocumentForm" Then
						WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, SearchValue.Parent.DataPath + ".HasInSalesDocument", False, DataCompositionComparisonType.Equal);
					EndIf;
					
					WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, CharacteristicFieldName);
					WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Text", NStr("en='<Not used>';ru='<Не используется>';vi='<Không sử dụng>'"));
					WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "ReadOnly", True);
					WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.TabularSectionUnavailableTextColor);
					
					NewConditionalAppearance = Form.ConditionalAppearance.Items.Add();
					WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, FieldNameCheckCharacteristicFilling, True, DataCompositionComparisonType.Equal);
					
					If Form.FormName = "Document.PurchaseAdjustment.Form.DocumentForm" Then
						WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, SearchValue.Parent.DataPath + ".HasInReceiptDocument", False, DataCompositionComparisonType.Equal);
					EndIf;
					
					If Form.FormName = "Document.SalesAdjustment.Form.DocumentForm" Then
						WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, SearchValue.Parent.DataPath + ".HasInSalesDocument", False, DataCompositionComparisonType.Equal);
					EndIf;
					
					WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, CharacteristicFieldName);
					WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "MarkIncomplete", True);
					
					NewConditionalAppearance = Form.ConditionalAppearance.Items.Add();
					WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, SearchValue.Parent.DataPath+".Characteristic", Catalogs.ProductsAndServicesCharacteristics.EmptyRef(), DataCompositionComparisonType.NotEqual);
					WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, CharacteristicFieldName);
					WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "MarkIncomplete", False);
				EndIf;
			EndIf;
			
			If UseBatches And Not TabularSection.Attributes.Find("Batch") = Undefined Then
				FieldDescription = TabularSection.Name + "Batch";
				SearchValue = Form.Items.Find(FieldDescription);
				
				If Not SearchValue = Undefined And TypeOf(SearchValue.Parent) = Type("FormTable") Then
					UseBatchesFieldName = SearchValue.Parent.DataPath+".UseBatches";
					CharacteristicFieldName = FieldDescription; 
					FieldNameCheckBatchFilling = SearchValue.Parent.DataPath + ".CheckBatchFilling";
					
					FieldNameOperationKind = "Object.OperationKind";
					OperationKindsExceptionsList = New ValueList;
					
					OperationKindsExceptionsList.Add(Enums.OperationKindsSupplierInvoice.ReceptionIntoProcessing);
					OperationKindsExceptionsList.Add(Enums.OperationKindsSupplierInvoice.ReceptionForCommission);
					OperationKindsExceptionsList.Add(Enums.OperationKindsSupplierInvoice.ReceptionForSafeCustody);
					
					NewConditionalAppearance = Form.ConditionalAppearance.Items.Add();
					WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, UseBatchesFieldName, False, DataCompositionComparisonType.Equal);
					WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, FieldNameOperationKind, OperationKindsExceptionsList, DataCompositionComparisonType.NotInList);
					
					
					If Form.FormName = "Document.PurchaseAdjustment.Form.DocumentForm" Then
						WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, SearchValue.Parent.DataPath + ".HasInReceiptDocument", False, DataCompositionComparisonType.Equal);
					EndIf;
					
					If Form.FormName = "Document.SalesAdjustment.Form.DocumentForm" Then
						WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, SearchValue.Parent.DataPath + ".HasInSalesDocument", False, DataCompositionComparisonType.Equal);
					EndIf;
					
					WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, CharacteristicFieldName);
					WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Text", NStr("en='<Not used>';ru='<Не используется>';vi='<Không sử dụng>'"));
					WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "ReadOnly", True);
					WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.TabularSectionUnavailableTextColor);
					
					NewConditionalAppearance = Form.ConditionalAppearance.Items.Add();
					WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, FieldNameCheckBatchFilling, True, DataCompositionComparisonType.Equal);
					
					If Form.FormName = "Document.PurchaseAdjustment.Form.DocumentForm" Then
						WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, SearchValue.Parent.DataPath + ".HasInReceiptDocument", False, DataCompositionComparisonType.Equal);
					EndIf;
					
					If Form.FormName = "Document.SalesAdjustment.Form.DocumentForm" Then
						WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, SearchValue.Parent.DataPath + ".HasInSalesDocument", False, DataCompositionComparisonType.Equal);
					EndIf;
					
					WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, CharacteristicFieldName);
					WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "MarkIncomplete", True);
					
					NewConditionalAppearance = Form.ConditionalAppearance.Items.Add();
					WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, SearchValue.Parent.DataPath+".Batch", Catalogs.ProductsAndServicesBatches.EmptyRef(), DataCompositionComparisonType.NotEqual);
					WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, CharacteristicFieldName);
					WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "MarkIncomplete", False);
					
				EndIf;
			EndIf;
		EndDo;
		
	Else
		
		For Each TabularSection In TabularSectionsNamesMap Do
			
			FieldDescription =?(ValueIsFilled(TabularSection.Value),TabularSection.Value, TabularSection.Key + "Characteristic");
			SearchValue = Form.Items.Find(FieldDescription);
			
			If UseCharacteristics And Not SearchValue = Undefined And TypeOf(SearchValue.Parent) = Type("FormTable") Then
				FieldNameCheckCharacteristicFilling = SearchValue.Parent.DataPath + ".CheckCharacteristicFilling";
				FieldNameUseCharacteristics = SearchValue.Parent.DataPath+".UseCharacteristics";
				CharacteristicFieldName = FieldDescription; 
				
				NewConditionalAppearance = Form.ConditionalAppearance.Items.Add();
				WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, FieldNameUseCharacteristics, False, DataCompositionComparisonType.Equal);
				
				If  Form.FormName = "Document.PurchaseAdjustment.Form.DocumentForm" Then
					WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, SearchValue.Parent.DataPath + ".HasInReceiptDocument", False, DataCompositionComparisonType.Equal);
				EndIf;
				
				If Form.FormName = "Document.SalesAdjustment.Form.DocumentForm" Then
					WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, SearchValue.Parent.DataPath + ".HasInSalesDocument", False, DataCompositionComparisonType.Equal);
				EndIf;
				
				WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, CharacteristicFieldName);
				WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Text", NStr("en='<Not used>';ru='<Не используется>';vi='<Không sử dụng>'"));
				WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "ReadOnly", True);
				WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.TabularSectionUnavailableTextColor);
				
				NewConditionalAppearance = Form.ConditionalAppearance.Items.Add();
				WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, FieldNameCheckCharacteristicFilling, True, DataCompositionComparisonType.Equal);
				
				If Form.FormName = "Document.PurchaseAdjustment.Form.DocumentForm" Then
					WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, SearchValue.Parent.DataPath + ".HasInReceiptDocument", False, DataCompositionComparisonType.Equal);
				EndIf;
				
				If Form.FormName = "Document.SalesAdjustment.Form.DocumentForm" Then
					WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, SearchValue.Parent.DataPath + ".HasInSalesDocument", False, DataCompositionComparisonType.Equal);
				EndIf;
				
				WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, CharacteristicFieldName);
				WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "MarkIncomplete", True);
				
				NewConditionalAppearance = Form.ConditionalAppearance.Items.Add();
				WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, SearchValue.Parent.DataPath+".Characteristic", Catalogs.ProductsAndServicesCharacteristics.EmptyRef(), DataCompositionComparisonType.NotEqual);
				WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, CharacteristicFieldName);
				WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "MarkIncomplete", False);
			EndIf;
			
			FieldDescription = TabularSection.Key + "Batch";
			SearchValue = Form.Items.Find(FieldDescription);
			
			If UseBatches And Not SearchValue = Undefined And TypeOf(SearchValue.Parent) = Type("FormTable") Then
				UseBatchesFieldName = SearchValue.Parent.DataPath+".UseBatches";
				PartyGenderName = FieldDescription; 
				FieldNameCheckBatchFilling = SearchValue.Parent.DataPath + ".CheckBatchFilling";
				
				FieldNameOperationKind = "Object.OperationKind";
				OperationKindsExceptionsList = New ValueList;
				
				OperationKindsExceptionsList.Add(Enums.OperationKindsSupplierInvoice.ReceptionIntoProcessing);
				OperationKindsExceptionsList.Add(Enums.OperationKindsSupplierInvoice.ReceptionForCommission);
				OperationKindsExceptionsList.Add(Enums.OperationKindsSupplierInvoice.ReceptionForSafeCustody);
				
				NewConditionalAppearance = Form.ConditionalAppearance.Items.Add();
				WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, UseBatchesFieldName, False, DataCompositionComparisonType.Equal);
				WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, FieldNameOperationKind, OperationKindsExceptionsList, DataCompositionComparisonType.NotInList);
				
				If Form.FormName = "Document.PurchaseAdjustment.Form.DocumentForm" Then
					WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, SearchValue.Parent.DataPath + ".HasInReceiptDocument", False, DataCompositionComparisonType.Equal);
				EndIf;
				
				If Form.FormName = "Document.SalesAdjustment.Form.DocumentForm" Then
					WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, SearchValue.Parent.DataPath + ".HasInSalesDocument", False, DataCompositionComparisonType.Equal);
				EndIf;
				
				WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, PartyGenderName);
				WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Text", NStr("en='<Not used>';ru='<Не используется>';vi='<Không sử dụng>'"));
				WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "ReadOnly", True);
				WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.TabularSectionUnavailableTextColor);
				
				NewConditionalAppearance = Form.ConditionalAppearance.Items.Add();
				WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, FieldNameCheckBatchFilling, True, DataCompositionComparisonType.Equal);
				
				If Form.FormName = "Document.PurchaseAdjustment.Form.DocumentForm" Then
					WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, SearchValue.Parent.DataPath + ".HasInReceiptDocument", False, DataCompositionComparisonType.Equal);
				EndIf;
				
				If Form.FormName = "Document.SalesAdjustment.Form.DocumentForm" Then
					WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, SearchValue.Parent.DataPath + ".HasInSalesDocument", False, DataCompositionComparisonType.Equal);
				EndIf;
				
				WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, PartyGenderName);
				WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "MarkIncomplete", True);
				
				NewConditionalAppearance = Form.ConditionalAppearance.Items.Add();
				WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, SearchValue.Parent.DataPath+".Batch", Catalogs.ProductsAndServicesBatches.EmptyRef(), DataCompositionComparisonType.NotEqual);
				WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, PartyGenderName);
				WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "MarkIncomplete", False);
				
			EndIf;
			
		EndDo;
	EndIf;
	
EndProcedure

//Получает значение партии номенклатуры по умолчанию
//
Function DefaultProductsAndServicesBatchesValues(ProductsAndServices, BatchStatus = Undefined, Counterparty = Undefined) Export 
	
	//StatusList = New ValueList;
	//
	//If Not BatchStatus = Undefined Then
	//	If Not TypeOf(BatchStatus) = Type("ValueList")
	//		Then
	//		StatusList.Add(BatchStatus);
	//	Else
	//		StatusList = BatchStatus;
	//	EndIf;
	//EndIf;
	//
	//Query = New Query;
	//
	//Query.SetParameter("ProductsAndServices", ProductsAndServices);
	//
	//Query.Text = "SELECT ALLOWED
	//|	CounterpartiesParties.Batch AS Batch
	//|FROM
	//|	InformationRegister.CounterpartiesParties AS CounterpartiesParties
	//|WHERE
	//|	CounterpartiesParties.ProductsAndServices = &ProductsAndServices
	//|	AND CounterpartiesParties.Status IN (&StatusList)
	//|	AND CounterpartiesParties.Counterparty = &Counterparty";
	//
	//If StatusList.Count() Then
	//	Query.SetParameter("StatusList", StatusList);
	//Else
	//	Query.Text = StrReplace(Query.Text,"AND CounterpartiesParties.Status IN (&StatusList)","");
	//EndIf;
	//
	//If ValueIsFilled(Counterparty) Then
	//	Query.SetParameter("Counterparty", Counterparty);
	//	QuerySelection = Query.Execute();
	//	If QuerySelection.IsEmpty() Then
	//		Query.SetParameter("Counterparty", Catalogs.Counterparties.EmptyRef());
	//		QueryResult = Query.Execute().Select();
	//	Else
	//		QueryResult = QuerySelection.Select();
	//	EndIf;
	//Else
	//	Query.Text = StrReplace(Query.Text, "AND CounterpartiesParties.Counterparty = &Counterparty","");
	//	QueryResult = Query.Execute().Select();
	//EndIf;
	//
	//If QueryResult.Count()>1 Then
	//	Return Undefined
	//Else	
	//	If QueryResult.Next() Then
	//		Return QueryResult.Batch;
	//	EndIf;
	//EndIf;
	
	Return Undefined;
	
EndFunction

//Возвращает статус партии, соответствующий операции документа
//
Function TypeOfTransactionOrHozOperationBatchStatus(Object, OperationKind = Undefined, BusinessTransaction = Undefined) Export
	
	DocumentOperation = ?(Not OperationKind = Undefined, OperationKind, BusinessTransaction);
	
	FilterStatus = New ValueList;
	
	If DocumentOperation = Undefined Then
		FilterStatus.Add(Enums.BatchStatuses.OwnInventory);
		FilterStatus.Add(Enums.BatchStatuses.CommissionMaterials);
		FilterStatus.Add(Enums.BatchStatuses.SafeCustody);
		FilterStatus.Add(Enums.BatchStatuses.ProductsOnCommission);
		Return FilterStatus;
	EndIf;
	
	If Not DocumentOperation = Undefined 
		And TypeOf(DocumentOperation) = Type("CatalogRef.EconomicOperations") Then
		
		If DocumentOperation = Catalogs.EconomicOperations.ReturnToPrincipal
			Or DocumentOperation = Catalogs.EconomicOperations.ReceptionForCommission Then
			FilterStatus.Add(Enums.BatchStatuses.ProductsOnCommission);
		ElsIf DocumentOperation = Catalogs.EconomicOperations.ReceptionForSafeCustody
			Or DocumentOperation = Catalogs.EconomicOperations.ReturnFromSafeCustody Then
			FilterStatus.Add(Enums.BatchStatuses.SafeCustody);
		ElsIf DocumentOperation = Catalogs.EconomicOperations.ReceptionIntoProcessing
			Or DocumentOperation = Catalogs.EconomicOperations.ReturnFromProcessing Then
			FilterStatus.Add(Enums.BatchStatuses.CommissionMaterials);
		Else
			FilterStatus.Add(Enums.BatchStatuses.OwnInventory);
			
			If DocumentOperation = Catalogs.EconomicOperations.SaleToCustomer Then
				FilterStatus.Add(Enums.BatchStatuses.ProductsOnCommission);
			EndIf;
			
		EndIf;
		
		If Not FilterStatus.Count()Then
			MessageText = NStr("en='Для операции документа - %1%, не найден статус партии. Выбор партии не возможен!';ru='Для операции документа - %1%, не найден статус партии. Выбор партии не возможен!';vi='Đối với giao dịch của chứng từ - %1%, không tìm thấy trạng thái lô hàng. Không thể chọn lô hàng!'");
			MessageText = StrReplace(MessageText, "%1%", String(DocumentOperation));
			
			SmallBusinessServer.ShowMessageAboutError(Object, MessageText);
			
			Return Undefined;
		EndIf;
		
	ElsIf Not DocumentOperation = Undefined 
		And (TypeOf(DocumentOperation) = Type("EnumRef.OperationKindsCustomerInvoice") 
		Or TypeOf(DocumentOperation) = Type("EnumRef.OperationKindsSupplierInvoice"))Then
		
		If DocumentOperation = Enums.OperationKindsCustomerInvoice.ReturnToPrincipal
			Or DocumentOperation = Enums.OperationKindsSupplierInvoice.ReceptionForCommission Then
			FilterStatus.Add(Enums.BatchStatuses.ProductsOnCommission);
		ElsIf DocumentOperation = Enums.OperationKindsSupplierInvoice.ReceptionForSafeCustody
			Or DocumentOperation = Enums.OperationKindsCustomerInvoice.ReturnFromSafeCustody Then
			FilterStatus.Add(Enums.BatchStatuses.SafeCustody);
		ElsIf DocumentOperation = Enums.OperationKindsSupplierInvoice.ReceptionIntoProcessing
			Or DocumentOperation = Enums.OperationKindsCustomerInvoice.ReturnFromProcessing Then
			FilterStatus.Add(Enums.BatchStatuses.CommissionMaterials);
		ElsIf DocumentOperation = Enums.OperationKindsSupplierInvoice.ReturnFromCustomer Then
			FilterStatus.Add(Enums.BatchStatuses.OwnInventory);
			FilterStatus.Add(Enums.BatchStatuses.ProductsOnCommission);
		Else
			FilterStatus.Add(Enums.BatchStatuses.OwnInventory);
			
			If DocumentOperation = Enums.OperationKindsCustomerInvoice.SaleToCustomer Then
				FilterStatus.Add(Enums.BatchStatuses.ProductsOnCommission);
			EndIf;
			
		EndIf;
		
		If Not FilterStatus.Count() Then
			MessageText = NStr("en='Для операции документа - %1%, не найден статус партии. Выбор партии не возможен!';ru='Для операции документа - %1%, не найден статус партии. Выбор партии не возможен!';vi='Đối với giao dịch của chứng từ - %1%, không tìm thấy trạng thái lô hàng. Không thể chọn lô hàng!'");
			MessageText = StrReplace(MessageText, "%1%", String(DocumentOperation));
			
			SmallBusinessServer.ShowMessageAboutError(Object, MessageText);
			
			Return Undefined;
		EndIf;
		
	Else
		
		If DocumentOperation = Enums.OperationKindsSupplierInvoice.ReceptionForCommission Then
			FilterStatus.Add(Enums.BatchStatuses.ProductsOnCommission);
		ElsIf DocumentOperation = Enums.OperationKindsSupplierInvoice.ReceptionForSafeCustody Then
			FilterStatus.Add(Enums.BatchStatuses.SafeCustody);
		ElsIf DocumentOperation = Enums.OperationKindsSupplierInvoice.ReceptionIntoProcessing Then
			FilterStatus.Add(Enums.BatchStatuses.CommissionMaterials);
		Else
			FilterStatus.Add(Enums.BatchStatuses.OwnInventory);
			
			If DocumentOperation = Enums.OperationKindsCustomerInvoice.SaleToCustomer Then
				FilterStatus.Add(Enums.BatchStatuses.ProductsOnCommission);
			EndIf;
			
		EndIf;
		
		If Not FilterStatus.Count() Then
			MessageText = NStr("en='Для операции документа - %1%, не найден статус партии. Выбор партии не возможен!';ru='Для операции документа - %1%, не найден статус партии. Выбор партии не возможен!';vi='Đối với giao dịch của chứng từ - %1%, không tìm thấy trạng thái lô hàng. Không thể chọn lô hàng!'");
			MessageText = StrReplace(MessageText, "%1%", String(DocumentOperation));
			
			SmallBusinessServer.ShowMessageAboutError(Object, MessageText);
			
			Return Undefined;
		EndIf;
	EndIf;
	
	Return FilterStatus;
	
EndFunction

Procedure FillProductsAndServicesChoiceFormSettingsTableServer(Form, DocumentKind, ProductsAndServicesChoiceFormSettings
	, SettingsToSaveType, Current = True, TabularSectionName = "Inventory", SettingsStructure = Undefined) Export
	
	StructuralUnitNameInForm = Undefined;
	If DocumentKind = "ReceiptCR" Then
		StructuralUnitNameInForm = "StructuralUnitCR";
	ElsIf Form.Object.Property("StructuralUnit") Then
		StructuralUnitNameInForm = "StructuralUnit";
	ElsIf Form.Object.Property("StructuralUnitReserve") Then
		StructuralUnitNameInForm = "StructuralUnitReserve";
	EndIf;
	
	If SettingsToSaveType = 1 Then
		NewRow = ProductsAndServicesChoiceFormSettings.Add();
		NewRow.TabularSectionName = TabularSectionName;
		NewRow.CurrentTabularSection = Current;
		NewRow.SettingName = "FilterCompany";
		NewRow.SettingValue = Form.Object.Company;
		
		NewRow = ProductsAndServicesChoiceFormSettings.Add();
		NewRow.TabularSectionName = TabularSectionName;
		NewRow.CurrentTabularSection = Current;
		NewRow.SettingName = "FilterWarehouse";
		
		If ValueIsFilled(StructuralUnitNameInForm) And DocumentKind = "ReceiptCR" Then
			NewRow.SettingValue = Form.StructuralUnitCR;
		ElsIf ValueIsFilled(StructuralUnitNameInForm) Then
			If Form.Object.Property("WarehousePosition") Then
				NewRow.SettingValue = ?(Form.Object.WarehousePosition = PredefinedValue("Enum.AttributePositionOnForm.InHeader")
				, Form.Object[StructuralUnitNameInForm], PredefinedValue("Catalog.StructuralUnits.EmptyRef"));
			Else 
				NewRow.SettingValue = Form.Object[StructuralUnitNameInForm];
			EndIf;
		Else
			NewRow.SettingValue = PredefinedValue("Catalog.StructuralUnits.EmptyRef");
		EndIf;
		
		NewRow = ProductsAndServicesChoiceFormSettings.Add();
		NewRow.TabularSectionName = TabularSectionName;
		NewRow.CurrentTabularSection = Current;
		NewRow.SettingName = "FilterPriceKind";
		
		If Form.Object.Property("PriceKind") Then
			NewRow.SettingValue = Form.Object.PriceKind;
		Else
			NewRow.SettingValue = PredefinedValue("Catalog.PriceKinds.Accounting");
		EndIf;
		
	EndIf;
	
	If SettingsToSaveType = 2 Then
		
		NewRow = ProductsAndServicesChoiceFormSettings.Add();
		NewRow.TabularSectionName = TabularSectionName;
		NewRow.CurrentTabularSection = Current;
		NewRow.SettingName = "FilterPriceKind";
		
		If Form.Object.Property("PriceKind") Then
			NewRow.SettingValue = Form.Object.PriceKind;
		Else
			NewRow.SettingValue = PredefinedValue("Catalog.PriceKinds.Accounting");
		EndIf;
		
	EndIf;
	
	If SettingsToSaveType = 3 Then
		NewRow = ProductsAndServicesChoiceFormSettings.Add();
		NewRow.TabularSectionName = TabularSectionName;
		NewRow.CurrentTabularSection = Current;
		NewRow.SettingName = "FilterCompany";
		NewRow.SettingValue = Form.Object.Company;
		
		NewRow = ProductsAndServicesChoiceFormSettings.Add();
		NewRow.TabularSectionName = TabularSectionName;
		NewRow.CurrentTabularSection = Current;
		NewRow.SettingName = "FilterWarehouse";
		NewRow.SettingValue = PredefinedValue("Catalog.StructuralUnits.EmptyRef");
		
		NewRow = ProductsAndServicesChoiceFormSettings.Add();
		NewRow.TabularSectionName = TabularSectionName;
		NewRow.CurrentTabularSection = Current;
		NewRow.SettingName = "FilterBalances";
		NewRow.SettingValue = 0;
	EndIf;
	
	NewRow = ProductsAndServicesChoiceFormSettings.Add();
	NewRow.TabularSectionName = TabularSectionName;
	NewRow.CurrentTabularSection = Current;
	NewRow.SettingName = "DocumentDestinationKey";
	NewRow.SettingValue = SettingsToSaveType;
	
	If RestrictWarehouseType(DocumentKind) Then
		
		If DocumentKind = "ReceiptCR" Then
			NewRow = ProductsAndServicesChoiceFormSettings.Add();
			NewRow.TabularSectionName = TabularSectionName;
			NewRow.CurrentTabularSection = Current;
			NewRow.SettingName = "StructuralUnitType";
			NewRow.SettingValue = Enums.StructuralUnitsTypes.Warehouse;
		Else
			NameMetadataObject = Metadata.FindByType(TypeOf(Form.Object.Ref));
			NameMetadataObject = ?(Not NameMetadataObject = Undefined, NameMetadataObject.Name, "");
			
			If ValueIsFilled(StructuralUnitNameInForm) And ValueIsFilled(NameMetadataObject) Then
				
				ChoiceParametersWarehouse = Metadata.Documents[NameMetadataObject].Attributes[StructuralUnitNameInForm].ChoiceParameters;
				
				For Each ChoiceParametersString In ChoiceParametersWarehouse Do
					If ChoiceParametersString.Name = "Filter.StructuralUnitType" Then
						NewRow = ProductsAndServicesChoiceFormSettings.Add();
						NewRow.TabularSectionName = TabularSectionName;
						NewRow.CurrentTabularSection = Current;
						NewRow.SettingName = "StructuralUnitType";
						NewRow.SettingValue = ChoiceParametersString.Value;
						Break;
					EndIf;
				EndDo;
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region InternalProceduresAndFunctions

Function ValueTableOfTabularSectionProductsAndServicesAttributesValues(TabularSection)
	
	
	Query = New Query;
	
	Query.SetParameter("TabularSection", TabularSection.Unload(,"LineNumber, ProductsAndServices"));
	
	Query.Text =
	"SELECT
	|	TabularSection.ProductsAndServices AS TabSectionProductsAndServices,
	|	TabularSection.LineNumber AS LineNumber
	|INTO Total
	|FROM
	|	&TabularSection AS TabularSection
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Total.LineNumber AS LineNumber,
	|	Total.TabSectionProductsAndServices AS ProductsAndServices,
	|	ProductsAndServices.IsFolder AS IsFolder,
	//|	ProductsAndServices.CheckCharacteristicFilling AS CheckCharacteristicFilling,
	//|	ProductsAndServices.CheckBatchFilling AS CheckBatchFilling,
	|	ProductsAndServices.ProductsAndServicesType AS ProductsAndServicesType
	|FROM
	|	Total AS Total
	|		LEFT JOIN Catalog.ProductsAndServices AS ProductsAndServices
	|		ON Total.TabSectionProductsAndServices = ProductsAndServices.Ref
	|
	|ORDER BY
	|	LineNumber";
	
	Return Query.Execute().Unload();
	
EndFunction

Function RestrictWarehouseType(DocumentKind)
	If DocumentKind = "PurchaseOrder" Then
		Return False
	Else
		Return True;
	EndIf;
EndFunction

Function QueryTextFillQuantityByBalancesAndReservesCustomerInvoice()
	
	QueryText =
	"SELECT ALLOWED
	|	TableInventory.ProductsAndServices AS ProductsAndServices,
	|	TableInventory.Characteristic AS Characteristic,
	|	TableInventory.Batch AS Batch,
	|	CASE
	|		WHEN &OrderInHeader
	|			THEN &DocOrder
	|		ELSE CASE
	|				WHEN TableInventory.DocOrder REFS Document.CustomerOrder
	|						AND TableInventory.DocOrder <> VALUE(Document.CustomerOrder.EmptyRef)
	|					THEN TableInventory.DocOrder
	|				ELSE VALUE(Document.CustomerOrder.EmptyRef)
	|			END
	|	END AS CustomerOrder
	|INTO TTProductsAndServicesChoice
	|FROM
	|	&TableInventory AS TableInventory
	|WHERE
	|	TableInventory.ProductsAndServicesTypeInventory
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	TTProductsAndServicesChoice.ProductsAndServices AS ProductsAndServices,
	|	TTProductsAndServicesChoice.Characteristic AS Characteristic,
	|	TTProductsAndServicesChoice.Batch AS Batch,
	|	TTProductsAndServicesChoice.CustomerOrder AS CustomerOrder,
	|	StructuralUnits.Ref AS StructuralUnit
	|INTO TTCartesianProductsAndServicesAndWarehouse
	|FROM
	|	TTProductsAndServicesChoice AS TTProductsAndServicesChoice,
	|	Catalog.StructuralUnits AS StructuralUnits
	|WHERE
	|	CASE
	|			WHEN NOT VALUETYPE(&Ref) = TYPE(Document.InventoryAssembly)
	|					AND NOT VALUETYPE(&Ref) = TYPE(Document.ProductionOrder)
	|				THEN StructuralUnits.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Warehouse)
	|			ELSE TRUE
	|		END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	InventoryBalance.QuantityBalance AS QuantityBalance,
	|	TTCartesianProductsAndServicesAndWarehouse.ProductsAndServices AS ProductsAndServices,
	|	TTCartesianProductsAndServicesAndWarehouse.Characteristic AS Characteristic,
	|	TTCartesianProductsAndServicesAndWarehouse.Batch AS Batch,
	|	TTCartesianProductsAndServicesAndWarehouse.StructuralUnit AS StructuralUnit
	|INTO WarehouseBalances
	|FROM
	|	TTCartesianProductsAndServicesAndWarehouse AS TTCartesianProductsAndServicesAndWarehouse
	|		LEFT JOIN AccumulationRegister.Inventory.Balance(
	|				,
	|				Company = &Company
	|					AND CustomerOrder = VALUE(Document.CustomerOrder.EmptyRef)
	|					AND ProductsAndServices IN (&ProductsAndServicesArray)) AS InventoryBalance
	|		ON TTCartesianProductsAndServicesAndWarehouse.ProductsAndServices = InventoryBalance.ProductsAndServices
	|			AND TTCartesianProductsAndServicesAndWarehouse.Characteristic = InventoryBalance.Characteristic
	|			AND TTCartesianProductsAndServicesAndWarehouse.Batch = InventoryBalance.Batch
	|			AND TTCartesianProductsAndServicesAndWarehouse.StructuralUnit = InventoryBalance.StructuralUnit
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	InventoryBalance.QuantityBalance AS QuantityBalance,
	|	TTCartesianProductsAndServicesAndWarehouse.ProductsAndServices AS ProductsAndServices,
	|	TTCartesianProductsAndServicesAndWarehouse.Characteristic AS Characteristic,
	|	TTCartesianProductsAndServicesAndWarehouse.Batch AS Batch,
	|	TTCartesianProductsAndServicesAndWarehouse.CustomerOrder AS CustomerOrder,
	|	TTCartesianProductsAndServicesAndWarehouse.StructuralUnit AS StructuralUnit
	|INTO ReserveBalances
	|FROM
	|	TTCartesianProductsAndServicesAndWarehouse AS TTCartesianProductsAndServicesAndWarehouse
	|		LEFT JOIN AccumulationRegister.Inventory.Balance(
	|				,
	|				Company = &Company
	|					AND NOT CustomerOrder = VALUE(Document.CustomerOrder.EmptyRef)
	|					AND ProductsAndServices IN (&ProductsAndServicesArray)) AS InventoryBalance
	|		ON TTCartesianProductsAndServicesAndWarehouse.ProductsAndServices = InventoryBalance.ProductsAndServices
	|			AND TTCartesianProductsAndServicesAndWarehouse.Characteristic = InventoryBalance.Characteristic
	|			AND TTCartesianProductsAndServicesAndWarehouse.Batch = InventoryBalance.Batch
	|			AND TTCartesianProductsAndServicesAndWarehouse.CustomerOrder = InventoryBalance.CustomerOrder
	|			AND TTCartesianProductsAndServicesAndWarehouse.StructuralUnit = InventoryBalance.StructuralUnit
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	SUM(CASE
	|			WHEN DocumentRegisterRecordsInventory.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN ISNULL(DocumentRegisterRecordsInventory.Quantity, 0)
	|			ELSE -ISNULL(DocumentRegisterRecordsInventory.Quantity, 0)
	|		END) AS ShippedWithoutReserve,
	|	TTCartesianProductsAndServicesAndWarehouse.ProductsAndServices AS ProductsAndServices,
	|	TTCartesianProductsAndServicesAndWarehouse.Characteristic AS Characteristic,
	|	TTCartesianProductsAndServicesAndWarehouse.Batch AS Batch,
	|	TTCartesianProductsAndServicesAndWarehouse.StructuralUnit AS StructuralUnit,
	|	TTCartesianProductsAndServicesAndWarehouse.CustomerOrder AS CustomerOrder1
	|INTO DocumentMovementWithoutReserve
	|FROM
	|	TTCartesianProductsAndServicesAndWarehouse AS TTCartesianProductsAndServicesAndWarehouse
	|		LEFT JOIN AccumulationRegister.Inventory AS DocumentRegisterRecordsInventory
	|		ON TTCartesianProductsAndServicesAndWarehouse.ProductsAndServices = DocumentRegisterRecordsInventory.ProductsAndServices
	|			AND TTCartesianProductsAndServicesAndWarehouse.Characteristic = DocumentRegisterRecordsInventory.Characteristic
	|			AND TTCartesianProductsAndServicesAndWarehouse.Batch = DocumentRegisterRecordsInventory.Batch
	|			AND TTCartesianProductsAndServicesAndWarehouse.StructuralUnit = DocumentRegisterRecordsInventory.StructuralUnit
	|			AND TTCartesianProductsAndServicesAndWarehouse.CustomerOrder = DocumentRegisterRecordsInventory.CustomerOrder
	|WHERE
	|	DocumentRegisterRecordsInventory.Recorder = &Ref
	|	AND DocumentRegisterRecordsInventory.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND DocumentRegisterRecordsInventory.CustomerOrder = VALUE(Document.CustomerOrder.EmptyRef)
	|
	|GROUP BY
	|	TTCartesianProductsAndServicesAndWarehouse.ProductsAndServices,
	|	TTCartesianProductsAndServicesAndWarehouse.Characteristic,
	|	TTCartesianProductsAndServicesAndWarehouse.Batch,
	|	TTCartesianProductsAndServicesAndWarehouse.StructuralUnit,
	|	TTCartesianProductsAndServicesAndWarehouse.CustomerOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	SUM(CASE
	|			WHEN DocumentRegisterRecordsInventory.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN ISNULL(DocumentRegisterRecordsInventory.Quantity, 0)
	|			ELSE -ISNULL(DocumentRegisterRecordsInventory.Quantity, 0)
	|		END) AS ReserveShipped,
	|	TTCartesianProductsAndServicesAndWarehouse.ProductsAndServices AS ProductsAndServices,
	|	TTCartesianProductsAndServicesAndWarehouse.Characteristic AS Characteristic,
	|	TTCartesianProductsAndServicesAndWarehouse.Batch AS Batch,
	|	TTCartesianProductsAndServicesAndWarehouse.StructuralUnit AS StructuralUnit,
	|	TTCartesianProductsAndServicesAndWarehouse.CustomerOrder AS CustomerOrder1
	|INTO DocumentMovementByBackup
	|FROM
	|	TTCartesianProductsAndServicesAndWarehouse AS TTCartesianProductsAndServicesAndWarehouse
	|		LEFT JOIN AccumulationRegister.Inventory AS DocumentRegisterRecordsInventory
	|		ON TTCartesianProductsAndServicesAndWarehouse.ProductsAndServices = DocumentRegisterRecordsInventory.ProductsAndServices
	|			AND TTCartesianProductsAndServicesAndWarehouse.Characteristic = DocumentRegisterRecordsInventory.Characteristic
	|			AND TTCartesianProductsAndServicesAndWarehouse.Batch = DocumentRegisterRecordsInventory.Batch
	|			AND TTCartesianProductsAndServicesAndWarehouse.StructuralUnit = DocumentRegisterRecordsInventory.StructuralUnit
	|			AND TTCartesianProductsAndServicesAndWarehouse.CustomerOrder = DocumentRegisterRecordsInventory.CustomerOrder
	|WHERE
	|	DocumentRegisterRecordsInventory.Recorder = &Ref
	|	AND DocumentRegisterRecordsInventory.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND NOT DocumentRegisterRecordsInventory.CustomerOrder = VALUE(Document.CustomerOrder.EmptyRef)
	|
	|GROUP BY
	|	TTCartesianProductsAndServicesAndWarehouse.ProductsAndServices,
	|	TTCartesianProductsAndServicesAndWarehouse.CustomerOrder,
	|	TTCartesianProductsAndServicesAndWarehouse.Characteristic,
	|	TTCartesianProductsAndServicesAndWarehouse.Batch,
	|	TTCartesianProductsAndServicesAndWarehouse.StructuralUnit
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	ISNULL(ReserveBalances.QuantityBalance, 0) AS Reserved,
	|	TTCartesianProductsAndServicesAndWarehouse.ProductsAndServices AS ProductsAndServices,
	|	TTCartesianProductsAndServicesAndWarehouse.Characteristic AS Characteristic,
	|	TTCartesianProductsAndServicesAndWarehouse.Batch AS Batch,
	|	TTCartesianProductsAndServicesAndWarehouse.CustomerOrder AS DocOrder,
	|	TTCartesianProductsAndServicesAndWarehouse.StructuralUnit AS StructuralUnit,
	|	CASE
	|		WHEN TTCartesianProductsAndServicesAndWarehouse.StructuralUnit = &PriorityWarehouse
	|			THEN 1
	|		ELSE 2
	|	END AS Priority,
	|	ISNULL(DocumentMovementByBackup.ReserveShipped, 0) AS ReserveShipped,
	|	ISNULL(DocumentRegisterRecord.ShippedWithoutReserve, 0) AS ShippedWithoutReserve,
	|	ISNULL(WarehouseBalances.QuantityBalance, 0) + ISNULL(ReserveBalances.QuantityBalance, 0) + ISNULL(DocumentMovementByBackup.ReserveShipped, 0) AS QuantityBalance,
	|	ISNULL(DocumentMovementByBackup.ReserveShipped, 0) + ISNULL(ReserveBalances.QuantityBalance, 0) AS TotalReserve,
	|	ISNULL(WarehouseBalances.QuantityBalance, 0) AS AvailableBalance,
	|	ISNULL(WarehouseBalances.QuantityBalance, 0) + ISNULL(ReserveBalances.QuantityBalance, 0) + ISNULL(DocumentMovementByBackup.ReserveShipped, 0) AS BalanceWithAllowance,
	|	VALUE(Catalog.Cells.EmptyRef) AS Cell
	|FROM
	|	TTCartesianProductsAndServicesAndWarehouse AS TTCartesianProductsAndServicesAndWarehouse
	|		LEFT JOIN WarehouseBalances AS WarehouseBalances
	|		ON TTCartesianProductsAndServicesAndWarehouse.ProductsAndServices = WarehouseBalances.ProductsAndServices
	|			AND TTCartesianProductsAndServicesAndWarehouse.Characteristic = WarehouseBalances.Characteristic
	|			AND TTCartesianProductsAndServicesAndWarehouse.Batch = WarehouseBalances.Batch
	|			AND TTCartesianProductsAndServicesAndWarehouse.StructuralUnit = WarehouseBalances.StructuralUnit
	|		LEFT JOIN DocumentMovementWithoutReserve AS DocumentRegisterRecord
	|		ON TTCartesianProductsAndServicesAndWarehouse.ProductsAndServices = DocumentRegisterRecord.ProductsAndServices
	|			AND TTCartesianProductsAndServicesAndWarehouse.Characteristic = DocumentRegisterRecord.Characteristic
	|			AND TTCartesianProductsAndServicesAndWarehouse.Batch = DocumentRegisterRecord.Batch
	|			AND TTCartesianProductsAndServicesAndWarehouse.CustomerOrder = DocumentRegisterRecord.CustomerOrder1
	|			AND TTCartesianProductsAndServicesAndWarehouse.StructuralUnit = DocumentRegisterRecord.StructuralUnit
	|		LEFT JOIN ReserveBalances AS ReserveBalances
	|		ON TTCartesianProductsAndServicesAndWarehouse.ProductsAndServices = ReserveBalances.ProductsAndServices
	|			AND TTCartesianProductsAndServicesAndWarehouse.CustomerOrder = ReserveBalances.CustomerOrder
	|			AND TTCartesianProductsAndServicesAndWarehouse.Characteristic = ReserveBalances.Characteristic
	|			AND TTCartesianProductsAndServicesAndWarehouse.Batch = ReserveBalances.Batch
	|			AND TTCartesianProductsAndServicesAndWarehouse.StructuralUnit = ReserveBalances.StructuralUnit
	|		LEFT JOIN DocumentMovementByBackup AS DocumentMovementByBackup
	|		ON TTCartesianProductsAndServicesAndWarehouse.ProductsAndServices = DocumentMovementByBackup.ProductsAndServices
	|			AND TTCartesianProductsAndServicesAndWarehouse.Characteristic = DocumentMovementByBackup.Characteristic
	|			AND TTCartesianProductsAndServicesAndWarehouse.Batch = DocumentMovementByBackup.Batch
	|			AND TTCartesianProductsAndServicesAndWarehouse.CustomerOrder = DocumentMovementByBackup.CustomerOrder1
	|			AND TTCartesianProductsAndServicesAndWarehouse.StructuralUnit = DocumentMovementByBackup.StructuralUnit
	|WHERE
	|	(NOT ISNULL(ReserveBalances.QuantityBalance, 0) = 0
	|			OR NOT ISNULL(WarehouseBalances.QuantityBalance, 0) = 0)
	|
	|ORDER BY
	|	DocOrder,
	|	Priority,
	|	Reserved";
	
	Return QueryText;
EndFunction

Function QueryTextInventoryInReserveByWarehouses()
	
	QueryText = 
	"SELECT ALLOWED
	|	SUM(InventoryBalance.QuantityBalance) AS Quantity,
	|	InventoryBalance.StructuralUnit AS Warehouse
	|FROM
	|	AccumulationRegister.Inventory.Balance(
	|			,
	|			ProductsAndServices = &ProductsAndServices
	|				AND CustomerOrder = &CustomerOrder
	|				AND Company = &Company
	|				AND Characteristic = &Characteristic
	|				AND Batch = &Batch) AS InventoryBalance
	|
	|GROUP BY
	|	InventoryBalance.StructuralUnit
	|
	|ORDER BY
	|	Quantity DESC";
	
	Return QueryText;
	
EndFunction

#EndRegion