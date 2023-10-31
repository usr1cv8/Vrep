#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region ProgramInterface

#Region DocumentFillingProcedures

// Procedure of filling the document on the basis of supplier invoice.
//
// Parameters:
//	FillingData - Structure - данные заполнения документа
//					 - DocumentRef.SupplierInvoice - Supplier invoice
//
Procedure FillBySupplierInvoice(FillingData) Export
	
	Company = FillingData.Company;
	StructuralUnit = FillingData.StructuralUnit;
	DocumentCurrency = Constants.NationalCurrency.Get();
	BasisDocumentCurrency = FillingData.DocumentCurrency;
	ExchangeRate = 1;
	Multiplicity = 1;
	BasisDocumentRate = FillingData.ExchangeRate;
	BasisDocumentMultiplicity = FillingData.Multiplicity;
	AmountIncludesVAT = FillingData.AmountIncludesVAT;
	IncludeVATInPrice = True;
	VATTaxation = Enums.VATTaxationTypes.TaxableByVAT;
	ReceiptDocument = FillingData.Ref;
	If CommonUseClientServer.HasAttributeOrObjectProperty(FillingData, "WarehousePosition") Then
		WarehousePosition = FillingData.WarehousePosition;
	Else
		WarehousePosition = Enums.AttributePositionOnForm.InHeader;
	EndIf;
	
	If FillingData.Inventory.Count() > 0 Then
		
		CCDNo = FillingData.Inventory[0].CCDNo;
		
	EndIf;
	
	DocumentAmount = 0;
	
	Sections.Clear();
	Inventory.Clear();
	
	SourceTableInventory = FillingData.Inventory.Unload();
	SourceTableInventory.Columns.Add("StructuralUnit", New TypeDescription("CatalogRef.StructuralUnits"));
	SourceTableInventory.FillValues(FillingData.StructuralUnit, "StructuralUnit");
	
	TablesStructure = Undefined;
	If SourceTableInventory.Count() > 0 Then
		
		TablesStructure = DistributeInventoryBySections(SourceTableInventory);
		
	EndIf;
	
	If TablesStructure <> Undefined Then
		
		RowFilter = New Structure("SectionNumber", -1);
		
		For Each Section In TablesStructure.SectionsTable Do
			
			RowFilter.SectionNumber = TablesStructure.SectionsTable.IndexOf(Section) + 1;
			InventoryRowsArray = TablesStructure.TableInventory.FindRows(RowFilter);
			If InventoryRowsArray.Count() < 1 Then
				
				Continue;
				
			EndIf;
			
			NewSection = Sections.Add();
			NewSection.VATRate		= Company.DefaultVATRate;
			NewSection.RateFee	= Section.ImportDutyRate;
			NewSection.FEACNCode		= Section.FEACNCode;
			NewSection.GlAccountVAT	= ChartsOfAccounts.Managerial.Taxes;
			
			InformationRow = NStr("en='Product code: %1, rows in section: %2';ru='Код товаров: %1, строк в разделе: %2';vi='Mã hàng hóa: %1, các dòng trong phần hành: %2'");
			NewSection.CCDSectionInfo = StrTemplate(InformationRow, NewSection.FEACNCode,
				InventoryRowsArray.Count());
			
			For Each TabularSectionRow In InventoryRowsArray Do
				
				NewRow = Inventory.Add();
				FillPropertyValues(NewRow, TabularSectionRow);
				
				NewRow.SectionNumber = RowFilter.SectionNumber;
				NewRow.DutyAmount = Round(NewRow.InvoiceCost
					* NewSection.RateFee / 100, 2);
				NewRow.DocumentBatch = FillingData.Ref;
				
				If DocumentCurrency <> BasisDocumentCurrency Then

					NewRow.DutyAmount = Round(NewRow.DutyAmount
						* BasisDocumentRate / BasisDocumentMultiplicity, 2);
					NewRow.InvoiceCost = Round(NewRow.InvoiceCost
						* BasisDocumentRate / BasisDocumentMultiplicity, 2);
					NewRow.VATAmount = Round(NewRow.VATAmount * BasisDocumentRate
						/ BasisDocumentMultiplicity, 2);

				EndIf;

				NewSection.CustomsCost = NewSection.CustomsCost
					+ NewRow.InvoiceCost;
				NewSection.DutyAmount = NewSection.DutyAmount
					+ NewRow.DutyAmount;
				NewSection.VATAmount = NewSection.VATAmount + NewRow.VATAmount;
				
			EndDo;
			
		EndDo;
		
	EndIf;
	
	DocumentAmount = Sections.Total("VATAmount") + Sections.Total("DutyAmount") + CustomsFee + CustomsPenalty;
	
	//
	// Корректное распределение суммы сбора можно произвести только после заполнения ТЧ Запасы
	//
	If CustomsFee > 0
		And Inventory.Count() > 1 Then
		
		OldAmountsMap = New Map;
		For Each InventoryRow In Inventory Do
			
			OldAmountsMap.Insert(Inventory.IndexOf(InventoryRow), InventoryRow.InvoiceCost);
			
		EndDo;
		
		NewAmountsMap = DistributeAmountsProportionally(CustomsFee, OldAmountsMap);
		
		If TypeOf(NewAmountsMap) = Type("Map") Then
			
			For Each MapItem In NewAmountsMap Do
				
				TableRow = Inventory.Get(MapItem.Key);
				TableRow.FeeAmount = MapItem.Value;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
EndProcedure // ЗаполнитьПоПриходнойНакладной()

#EndRegion

#EndRegion

#Region EventsHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	FillingStrategy = New Map;
	FillingStrategy[Type("DocumentRef.SupplierInvoice")] = "FillBySupplierInvoice";
	
	ObjectFillingSB.FillDocument(ThisObject, FillingData, FillingStrategy);
	
EndProcedure

Procedure FillCheckProcessing(cancel, CheckedAttributes)
	
	If Not Counterparty.DoOperationsByContracts Then
		
		SmallBusinessServer.DeleteAttributeBeingChecked(CheckedAttributes, "Contract");
		
	EndIf;
		
	ProductsAndServicesInDocumentsServer.CheckCharacteristicsFilling(ThisObject, cancel, True);
	
EndProcedure

Procedure BeforeWrite(cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If ValueIsFilled(Counterparty)
		And Not Counterparty.DoOperationsByContracts
		And Not ValueIsFilled(Contract) Then
		
		Contract = Catalogs.CounterpartyContracts.ContractByDefault(Counterparty);
		
	EndIf;
	
	For Each InventoryRow In Inventory Do
		
		If ValueIsFilled(InventoryRow.StructuralUnit) Then
			
			Continue;
			
		EndIf;
		
		InventoryRow.StructuralUnit = Catalogs.StructuralUnits.MainWarehouse;
		
	EndDo;
	
EndProcedure

Procedure Posting(cancel, PostingMode)
	
	// Инициализация дополнительных свойств для проведения документа.
	SmallBusinessServer.InitializeAdditionalPropertiesForPosting(Ref, AdditionalProperties);
	
	// Инициализация данных документа.
	Documents.ExpensesOnImport.DocumentDataInitialization(Ref, AdditionalProperties);
	
	// Подготовка наборов записей.
	SmallBusinessServer.PrepareRecordSetsForRecording(ThisObject);
	
	// Отражение в разделах учета.
	SmallBusinessServer.ReflectInventory(AdditionalProperties, RegisterRecords, cancel);
	SmallBusinessServer.ReflectSettlementsWithOtherCounterparties(AdditionalProperties, RegisterRecords, cancel);
	SmallBusinessServer.ReflectIncomeAndExpenses(AdditionalProperties, RegisterRecords, cancel);
	
	SmallBusinessServer.ReflectManagerial(AdditionalProperties, RegisterRecords, cancel);
	
	// Запись наборов записей.
	SmallBusinessServer.WriteRecordSets(ThisObject);
	
	AdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager.Close();
	
EndProcedure

Procedure UndoPosting(cancel)
	
	// Инициализация дополнительных свойств для проведения документа
	SmallBusinessServer.InitializeAdditionalPropertiesForPosting(Ref, AdditionalProperties);
	
	// Подготовка наборов записей
	SmallBusinessServer.PrepareRecordSetsForRecording(ThisObject);
	
	// Запись наборов записей
	SmallBusinessServer.WriteRecordSets(ThisObject);
	
	// Контроль возникновения отрицательного остатка.
	Documents.ExpensesOnImport.RunControl(Ref, AdditionalProperties, cancel, True);
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

Function DistributeInventoryBySections(SourceTableInventory)
	
	TablesStructure = New Structure;
	TablesStructure.Insert("SectionsTable", Documents.ExpensesOnImport.EmptyRef().Sections.Unload());
	TablesStructure.Insert("TableInventory", Documents.ExpensesOnImport.EmptyRef().Inventory.Unload());
	
	NumberQualifiers = New NumberQualifiers(2);
	TablesStructure.SectionsTable.Columns.Add("ImportDutyRate", New TypeDescription(NumberQualifiers));
	
	Query = New Query;
	Query.SetParameter("SourceTableInventory", SourceTableInventory);
	
	Query.Text = 
	"SELECT
	|	-1 AS SectionNumber,
	|	CAST(SourceTableInventory.ProductsAndServices AS Catalog.ProductsAndServices) AS ProductsAndServices,
	|	SourceTableInventory.Characteristic AS Characteristic,
	|	SourceTableInventory.Batch AS Batch,
	|	SourceTableInventory.Quantity AS Quantity,
	|	SourceTableInventory.Amount AS Amount,
	|	SourceTableInventory.Amount AS InvoiceCost,
	|	SourceTableInventory.VATRate AS VATRate,
	|	SourceTableInventory.VATAmount AS VATAmount,
	|	0 AS FeeAmount,
	|	SourceTableInventory.CountryOfOrigin AS CountryOfOrigin,
	|	SourceTableInventory.StructuralUnit AS StructuralUnit,
	|	CAST(SourceTableInventory.Order AS Document.PurchaseOrder) AS PurchaseOrder
	|INTO tmpSourceTableInventory
	|FROM
	|	&SourceTableInventory AS SourceTableInventory
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SourceTableInventory.SectionNumber AS SectionNumber,
	|	SourceTableInventory.ProductsAndServices AS ProductsAndServices,
	|	SourceTableInventory.ProductsAndServices.CommodityFEAProductsAndServices.Code AS FEACNCode,
	|	SourceTableInventory.ProductsAndServices.CommodityFEAProductsAndServices.ImportDuty AS ImportDuty,
	|	SourceTableInventory.Characteristic AS Characteristic,
	|	SourceTableInventory.Batch AS Batch,
	|	SourceTableInventory.Quantity AS Quantity,
	|	SourceTableInventory.Amount AS Amount,
	|	SourceTableInventory.Amount AS InvoiceCost,
	|	SourceTableInventory.VATRate AS VATRate,
	|	SourceTableInventory.VATAmount AS VATAmount,
	|	0 AS FeeAmount,
	|	SourceTableInventory.CountryOfOrigin AS CountryOfOrigin,
	|	SourceTableInventory.PurchaseOrder.CustomerOrder AS CustomerOrder,
	|	SourceTableInventory.StructuralUnit AS StructuralUnit,
	|	UNDEFINED AS DocumentBatch
	|FROM
	|	tmpSourceTableInventory AS SourceTableInventory";
	
	ProductsAndServicesAndCodesOfTNFEA = Query.Execute().Unload();
	For Each TableRow In ProductsAndServicesAndCodesOfTNFEA Do
		
		If IsBlankString(TrimAll(TableRow.FEACNCode)) Then
			
			TableRow.FEACNCode = "0000000000";
			
		EndIf;
		
		SectionsTableRow = TablesStructure.SectionsTable.Find(TableRow.FEACNCode, "FEACNCode");
		If SectionsTableRow = Undefined Then
			
			SectionsTableRow = TablesStructure.SectionsTable.Add();
			SectionsTableRow.FEACNCode = TrimAll(TableRow.FEACNCode);
			SectionsTableRow.ImportDutyRate = TableRow.ImportDuty;
			
		EndIf;
		
		InventoryTableRow = TablesStructure.TableInventory.Add();
		FillPropertyValues(InventoryTableRow, TableRow);
		
		InventoryTableRow.SectionNumber =  TablesStructure.SectionsTable.IndexOf(SectionsTableRow) + 1;
		
	EndDo;
	
	Return TablesStructure;
	
EndFunction

Function DistributeAmountsProportionally(Val SourceAmount, RatiosMap, Accuracy = 2)
	
	If RatiosMap.Count() = 0 
		Or SourceAmount = 0 
		Or SourceAmount = Null Then
		
		Return Undefined;
		
	EndIf;
	
	MaxIndex = 0;
	MaxVal   = 0;
	DistribAmount = 0;
	CoeffAmount  = 0;
	
	For Each MapItem In RatiosMap Do
		
		AbsNumber = ?(MapItem.Value > 0, MapItem.Value, - MapItem.Value);
		
		If MaxVal < AbsNumber Then
			
			MaxVal = AbsNumber;
			MaxIndex = MapItem.Key;
			
		EndIf;
		
		CoeffAmount = CoeffAmount + MapItem.Value;
		
	EndDo;
	
	If CoeffAmount = 0 Then
		
		Return Undefined;
		
	EndIf;
	
	NewAmountsMap = New Map;
	For Each MapItem In RatiosMap Do
		
		NewAmount = Round(SourceAmount * MapItem.Value / CoeffAmount, Accuracy, 1);
		NewAmountsMap.Insert(MapItem.Key, NewAmount);
		DistribAmount = DistribAmount + NewAmount;
		
	EndDo;
	
	// Погрешности округления отнесем на коэффициент с максимальным весом
	If Not DistribAmount = SourceAmount Then
		
		ItemValue = NewAmountsMap.Get(MaxIndex);
		ItemValue = ItemValue + (SourceAmount - DistribAmount);
		
		NewAmountsMap.Insert(MaxIndex, ItemValue);
		
	EndIf;
	
	Return NewAmountsMap;
	
EndFunction

#EndRegion

#EndIf