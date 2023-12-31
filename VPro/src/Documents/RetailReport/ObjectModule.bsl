#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

//////////////////////////////////////////////////////////////////////////////////
//// PROCEDURES AND FUNCTIONS OF INITIALIZATION AND FILLING

// Initializes document
//
Procedure InitializeDocument()
	
	CashCRSessionStart    = BegOfDay(CurrentDate());
	CashCRSessionEnd = EndOfDay(CurrentDate());
	
EndProcedure // InitializeDocument()

// Fills the retail sale report according to filter.
//
// Parameters
//  FillingData - Structure with the filter values
//
Procedure FillDocumentByFilter(FillingData)
	
	If FillingData.Property("CashCR") Then
		FillDocumentByCachRegister(FillingData.CashCR);
	EndIf;
	
EndProcedure // FillDocumentByFilter()

// Fills the document tabular section according to the goods reconciliation at warehouse.
//
Procedure FillTabularSectionInventoryByGoodsInventoryAtWarehouse(FillingData)

	ThisObject.InventoryReconciliation = FillingData.Ref;
	Company = FillingData.Company;
	StructuralUnit = FillingData.StructuralUnit;
	Cell = FillingData.Cell;
	
	VATTaxation = SmallBusinessServer.VATTaxation(Company, StructuralUnit, Date);
	
	Query = New Query(
	"SELECT
	|	MIN(InventoryReconciliation.LineNumber) AS LineNumber,
	|	InventoryReconciliation.ProductsAndServices AS ProductsAndServices,
	|	InventoryReconciliation.Characteristic AS Characteristic,
	|	InventoryReconciliation.Batch AS Batch,
	|	InventoryReconciliation.MeasurementUnit AS MeasurementUnit,
	|	MAX(InventoryReconciliation.QuantityAccounting - InventoryReconciliation.Quantity) AS QuantityInventorytakingRejection,
	|	SUM(CASE
	|			WHEN RetailReport.Quantity IS NULL
	|				THEN 0
	|			ELSE RetailReport.Quantity
	|		END) AS QuantityDebited,
	|	InventoryReconciliation.Price AS Price,
	|	InventoryReconciliation.ProductsAndServices.VATRate AS VATRate,
	|	InventoryReconciliation.ConnectionKey
	|FROM
	|	Document.InventoryReconciliation.Inventory AS InventoryReconciliation
	|		LEFT JOIN Document.RetailReport.Inventory AS RetailReport
	|		ON InventoryReconciliation.ProductsAndServices = RetailReport.ProductsAndServices
	|			AND InventoryReconciliation.Characteristic = RetailReport.Characteristic
	|			AND InventoryReconciliation.Batch = RetailReport.Batch
	|			AND InventoryReconciliation.Ref = RetailReport.Ref.InventoryReconciliation
	|			AND (RetailReport.Ref <> &DocumentRef)
	|			AND (RetailReport.Ref.Posted)
	|WHERE
	|	InventoryReconciliation.Ref = &BasisDocument
	|	AND InventoryReconciliation.QuantityAccounting - InventoryReconciliation.Quantity > 0
	|
	|GROUP BY
	|	InventoryReconciliation.ProductsAndServices,
	|	InventoryReconciliation.Characteristic,
	|	InventoryReconciliation.Batch,
	|	InventoryReconciliation.MeasurementUnit,
	|	InventoryReconciliation.Price,
	|	InventoryReconciliation.ProductsAndServices.VATRate,
	|	InventoryReconciliation.ConnectionKey
	|
	|ORDER BY
	|	LineNumber");
		
	Query.SetParameter("BasisDocument", FillingData.Ref);
	Query.SetParameter("DocumentRef", Ref);
		
	QueryResult = Query.Execute();
		
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
			
		// Filling document tabular section.
		Inventory.Clear();
		
		While Selection.Next() Do
			
			QuantityToReceive = Selection.QuantityInventorytakingRejection - Selection.QuantityDebited;
			If QuantityToReceive <= 0 Then
				Continue;
			EndIf;
			
			TabularSectionRow = Inventory.Add();
			FillPropertyValues(TabularSectionRow, Selection);
			TabularSectionRow.Quantity = QuantityToReceive;
			TabularSectionRow.Amount   = TabularSectionRow.Quantity * TabularSectionRow.Price;
			
			If VATTaxation = Enums.VATTaxationTypes.TaxableByVAT Then
				
				TabularSectionRow.VATRate = Selection.VATRate;
				VATRate = SmallBusinessReUse.GetVATRateValue(TabularSectionRow.VATRate);
				TabularSectionRow.VATAmount = ?(AmountIncludesVAT,
												TabularSectionRow.Amount
												- (TabularSectionRow.Amount) / ((VATRate + 100) / 100),
												TabularSectionRow.Amount * VATRate / 100);
			
				TabularSectionRow.Total = TabularSectionRow.Amount + ?(AmountIncludesVAT, 0, TabularSectionRow.VATAmount);
				
			Else
				If VATTaxation = Enums.VATTaxationTypes.NotTaxableByVAT Then	
				
					DefaultVATRate = SmallBusinessReUse.GetVATRateWithoutVAT();
				
				Else
				
					DefaultVATRate = SmallBusinessReUse.GetVATRateZero();
				
				EndIf;
				
				TabularSectionRow.VATRate = DefaultVATRate;
				TabularSectionRow.VATAmount = 0;
			
				TabularSectionRow.Total = TabularSectionRow.Amount;
				
			EndIf;
			
		EndDo;
		
	EndIf;
		
	If Inventory.Count() = 0 Then
		
		Message = New UserMessage();
		Message.Text = NStr("en='No data to fill in by physical inventory.';ru='Нет данных для заполнения по инвентаризации!';vi='Không có dữ liệu để điền theo kiểm kê!'");
		Message.Message();
		
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure // FillTabularSectionProductsForStockAudit()

// Fills document by CR petty cash 
//
Procedure FillDocumentByCachRegister(CashCR)
	
	CashRegisterAttributes = Catalogs.CashRegisters.GetCashRegisterAttributes(CashCR);
	FillPropertyValues(ThisObject, CashRegisterAttributes);
	VATTaxation = SmallBusinessServer.VATTaxation(Company, StructuralUnit, Date);
	
EndProcedure // FillDocumentByCRPettyCash()

// Fills document by warehouse cash register if there is only one cash register at the warehouse.
//
Procedure FillDocumentByWarehouse(StructuralUnit)
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 2
	|	CashRegisters.Ref AS CashCR
	|FROM
	|	Catalog.CashRegisters AS CashRegisters
	|WHERE
	|	CashRegisters.StructuralUnit = &StructuralUnit";
	
	Query.SetParameter("StructuralUnit", StructuralUnit);
	
	Selection = Query.Execute().Select();
	If Selection.Count() = 1
	   AND Selection.Next()
	Then
		CashCR = Selection.CashCR;
		FillDocumentByCachRegister(CashCR);
	EndIf;
	
EndProcedure // FillDocumentByWarehouse()

// Fills the retail sales report according to the goods reconciliation at warehouse.
//
// Parameters
//  FillingData - Structure with the filter values
//
Procedure FillByInventoryInventoryAtWarehouse(FillingData)
	
	StructuralUnit            = FillingData.StructuralUnit;
	ProductsAtWarehouseReconciliation = FillingData.Ref;
	
	FillDocumentByWarehouse(StructuralUnit);
	
	FillTabularSectionInventoryByGoodsInventoryAtWarehouse(FillingData);
	
EndProcedure // FillByGoodsReconciliationAtWarehouse()

// Adds additional attributes necessary for document
// posting to passed structure.
//
// Parameters:
//  StructureAdditionalProperties - Structure of additional document properties.
//
Procedure AddAttributesToAdditionalPropertiesForPosting(StructureAdditionalProperties)
	
	If CashCR.CashCRType = Enums.CashCRTypes.FiscalRegister Then
		CompletePosting = CashCRSessionStatus = Enums.CashCRSessionStatuses.ClosedReceiptsArchived;
	Else
		CompletePosting = (CashCRSessionStatus = Enums.CashCRSessionStatuses.ClosedReceiptsArchived)
					   OR (CashCRSessionStatus = Enums.CashCRSessionStatuses.Closed);
	EndIf;
	
	StructureAdditionalProperties.ForPosting.Insert("CompletePosting", CompletePosting);
	
EndProcedure // AddAttributesToAdditionalPropertiesForPosting()

////////////////////////////////////////////////////////////////////////////////
// EVENT HANDLERS

// Procedure - handler of the FillingProcessor event.
//
Procedure Filling(FillingData, StandardProcessing)
	
	DataTypeFill = TypeOf(FillingData);
	
	If DataTypeFill = Type("Structure") Then
		
		FillDocumentByFilter(FillingData);
		
	ElsIf DataTypeFill = Type("DocumentRef.InventoryReconciliation") Then
		
		If FillingData.StructuralUnit.StructuralUnitType <> Enums.StructuralUnitsTypes.Retail Then
			Raise(NStr("en='The document can be filled in based on the retail warehouse physical inventory only.';ru='Документ может быть заполнен только на основании инвентаризации по розничному складу!';vi='Chứng từ có thể được điền chỉ trên cơ sở kiểm kê theo kho bán lẻ!'"));
		Else
			FillByInventoryInventoryAtWarehouse(FillingData);
		EndIf;
		
	Else
		
		CashCR = Catalogs.CashRegisters.GetCashCRByDefault();
		If CashCR <> Undefined Then
			FillDocumentByCachRegister(CashCR);
		EndIf;
		
	EndIf;
	
	InitializeDocument();
	
EndProcedure // FillingProcessor()

// Procedure - event handler BeforeWrite object.
//
Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If PositionResponsible = Enums.AttributePositionOnForm.InHeader Then
		For Each TabularSectionRow IN Inventory Do
			TabularSectionRow.Responsible = Responsible;
		EndDo;
	EndIf;
	
	DocumentAmount = Inventory.Total("Total");
	
	FillStructuralUnitsTypes();
	
EndProcedure // BeforeWrite()

// Procedure - FillCheckProcessing event handler.
//
Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	CashCRType = Catalogs.CashRegisters.GetCashRegisterAttributes(CashCR).CashCRType;
	
	If PaymentWithPaymentCards.Total("Amount") > DocumentAmount Then
		
		ErrorText = NStr("en='Card payment amount is greater than the document amount';ru='Сумма оплаты платежными картами превышает сумму документа';vi='Số tiền trả bằng thẻ thanh toán vượt quá số tiền trên chứng từ'");
		
		SmallBusinessServer.ShowMessageAboutError(
			ThisObject,
			ErrorText,
			Undefined,
			Undefined,
			"PaymentWithPaymentCards",
			Cancel
		);
		
	EndIf;
	
	If CashCRType = Enums.CashCRTypes.FiscalRegister Then
		
		OpenedCashCRSession = Documents.RetailReport.GetOpenCashCRSession(CashCR, Ref, CashCRSessionStart, CashCRSessionEnd);
		If OpenedCashCRSession <> Undefined
		   AND OpenedCashCRSession <> Ref Then
			
			ErrorText = NStr("en='%CashShift% is already registered for this cash register on date %Date%';ru='По данной кассе на дату %Дата% уже зарегистрирован %КассоваяСмена%';vi='Theo quỹ tiền mặt này tại ngày %Date% đã ghi nhận %CashShift%'");
			ErrorText = StrReplace(ErrorText, "%Date%", Date);
			ErrorText = StrReplace(ErrorText, "%CashCRSession%", OpenedCashCRSession);
			
			SmallBusinessServer.ShowMessageAboutError(
				ThisObject,
				ErrorText,
				Undefined,
				Undefined,
				"",
				Cancel
			);
			
		EndIf;
		
		If Not ValueIsFilled(CashCRSessionEnd)
			 AND ValueIsFilled(CashCRSessionStatus)
			 AND CashCRSessionStatus <> Enums.CashCRSessionStatuses.IsOpen Then
			
			ErrorText = NStr("en='The ""Shift end"" field is not filled in';ru='Поле ""Окончание смены"" не заполнено';vi='Chưa điền trường ""Kết thúc phiên làm việc""'");
			
			SmallBusinessServer.ShowMessageAboutError(
				ThisObject,
				ErrorText,
				Undefined,
				Undefined,
				"CashCRSessionEnd",
				Cancel
			);
			
		EndIf;
		
		If ValueIsFilled(CashCRSessionEnd)
			 AND CashCRSessionEnd < CashCRSessionStart Then
			
			ErrorText = NStr("en='Start time of the register shift is later than the end time of the register shift';ru='Время начала кассовой смены больше времени окончания кассовой смены';vi='Thời gian bắt đầu phiên thu ngân lớn hơn thời gian kết thúc phiên thu ngân'");
			
			SmallBusinessServer.ShowMessageAboutError(
				ThisObject,
				ErrorText,
				Undefined,
				Undefined,
				"CashCRSessionEnd",
				Cancel
			);
			
		EndIf;
		
		
		If ValueIsFilled(CashCRSessionStatus)
			 AND CashCRSessionStatus = Enums.CashCRSessionStatuses.IsOpen
			 AND CashCRSessionStart <> Date Then
			
			ErrorText = NStr("en='Start time of the register shift is different from the document date';ru='Время начала кассовой смены отличается от даты документа';vi='Thời gian bắt đầu phiên thu ngân khác ngày của chứng từ'");
			
			SmallBusinessServer.ShowMessageAboutError(
				ThisObject,
				ErrorText,
				Undefined,
				Undefined,
				"CashCRSessionStart",
				Cancel
			); 
			
		EndIf;
		
		If ValueIsFilled(CashCRSessionStatus)
			 AND CashCRSessionStatus <> Enums.CashCRSessionStatuses.IsOpen
			 AND CashCRSessionEnd <> Date Then
			
			ErrorText = NStr("en='End time of the register shift is different from the document date';ru='Время окончания кассовой смены отличается от даты документа';vi='Thời gian kết thúc phiên thu ngân khác ngày của chứng từ'");
			
			SmallBusinessServer.ShowMessageAboutError(
				ThisObject,
				ErrorText,
				Undefined,
				Undefined,
				"CashCRSessionEnd",
				Cancel
			);
			
		EndIf;
	
	EndIf;
	
	// 100% discount.
	If Constants.FunctionalOptionUseDiscountsMarkups.Get() Then
		For Each StringInventory IN Inventory Do
			If StringInventory.DiscountMarkupPercent <> 100 
				AND Not ValueIsFilled(StringInventory.Amount) Then
				MessageText = NStr("en='The ""Amount"" column is not populated in the %Number% line of the ""Inventory"" list.';ru='Не заполнена колонка ""Сумма"" в строке %Номер% списка ""Запасы"".';vi='Chưa điền cột ""Thành tiền"" trong dòng %Number% danh sách ""Vật tư"".'");
				MessageText = StrReplace(MessageText, "%Number%", StringInventory.LineNumber);
				SmallBusinessServer.ShowMessageAboutError(
					ThisObject,
					MessageText,
					"Inventory",
					StringInventory.LineNumber,
					"Amount",
					Cancel
				);
			EndIf;
		EndDo;
	EndIf;
	
	// Serial numbers
	WorkWithSerialNumbers.FillCheckingSerialNumbers(Cancel, Inventory, SerialNumbers, StructuralUnit, ThisObject);
	
EndProcedure // FillCheckProcessing()

// Procedure - event handler Posting().
//
Procedure Posting(Cancel, PostingMode)
	
	// Initialization of additional properties for document posting.
	SmallBusinessServer.InitializeAdditionalPropertiesForPosting(Ref, AdditionalProperties);
	AddAttributesToAdditionalPropertiesForPosting(AdditionalProperties);
	
	// Document data initialization.
	Documents.RetailReport.InitializeDocumentData(Ref, AdditionalProperties);
	
	// Preparation of records sets.
	SmallBusinessServer.PrepareRecordSetsForRecording(ThisObject);
	
	// Account for in accounting sections.
	SmallBusinessServer.ReflectInventory(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectSales(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectInventoryInWarehouses(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectIncomeAndExpenses(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectIncomeAndExpensesCashMethod(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectCashAssetsInCashRegisters(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectInventoryAccepted(AdditionalProperties, RegisterRecords, Cancel);
	
	// DiscountCards
	SmallBusinessServer.ReflectSalesByDiscountCard(AdditionalProperties, RegisterRecords, Cancel);
	
	// SerialNumbers
	SmallBusinessServer.ReflectTheSerialNumbersOfTheGuarantee(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectTheSerialNumbersBalance(AdditionalProperties, RegisterRecords, Cancel);
	
	// Inventory By CCD
	SmallBusinessServer.ReflectInventoryByCCD(AdditionalProperties, RegisterRecords, Cancel);
	
	// AutomaticDiscounts
	SmallBusinessServer.FlipAutomaticDiscountsApplied(AdditionalProperties, RegisterRecords, Cancel);
	
	SmallBusinessServer.ReflectManagerial(AdditionalProperties, RegisterRecords, Cancel);
	
	// Record of the records sets.
	SmallBusinessServer.WriteRecordSets(ThisObject);
	
	// Control of occurrence of a negative balance.
	Documents.RetailReport.RunControl(Ref, AdditionalProperties, Cancel);
	
	AdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager.Close();
	
EndProcedure // Posting()

// Procedure - handler of event PostingDeletionDataProcessor.
//
Procedure UndoPosting(Cancel)
	
	// Initialization of additional properties for document posting
	SmallBusinessServer.InitializeAdditionalPropertiesForPosting(Ref, AdditionalProperties);
	
	// Preparation of record sets
	SmallBusinessServer.PrepareRecordSetsForRecording(ThisObject);
	
	// Writing of record sets
	SmallBusinessServer.WriteRecordSets(ThisObject);
	
	// Control of occurrence of a negative balance.
	Documents.RetailReport.RunControl(Ref, AdditionalProperties, Cancel, True);
	
EndProcedure // UndoPosting()

// 
Procedure FillStructuralUnitsTypes() Export
	
	StructuralUnitType = CommonUse.ObjectAttributeValue(StructuralUnit, "StructuralUnitType");
	
EndProcedure


#EndIf
