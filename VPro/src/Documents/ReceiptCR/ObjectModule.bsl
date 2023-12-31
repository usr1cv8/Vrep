#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

////////////////////////////////////////////////////////////////////////////////
// INITIALIZATION PROCEDURES AND FUNCTIONS

// Initializes the document receipt CR.
//
Procedure InitializeDocument()
	
	POSTerminal = Catalogs.POSTerminals.GetPOSTerminalByDefault(CashCR);
	
EndProcedure // InitializeDocument()

// Fills document Receipt CR by cash register.
//
// Parameters
//  FillingData - Structure with the filter values
//
Procedure FillDocumentByCachRegister(CashCR)
	
	StatusCashCRSession = Documents.RetailReport.GetCashCRSessionStatus(CashCR);
	FillPropertyValues(ThisObject, StatusCashCRSession);
	
EndProcedure // FillDocumentByFilter()

// Fills document CR receipt in compliance with filter.
//
// Parameters
//  FillingData - Structure with the filter values
//
Procedure FillDocumentByFilter(FillingData)
	
	If FillingData.Property("CashCR") Then
		
		FillDocumentByCachRegister(FillingData.CashCR);
		
	EndIf;
	
EndProcedure // FillDocumentByFilter()

// Adds additional attributes necessary for document
// posting to passed structure.
//
// Parameters:
//  StructureAdditionalProperties - Structure of additional document properties.
//
Procedure AddAttributesToAdditionalPropertiesForPosting(StructureAdditionalProperties)
	
	StructureAdditionalProperties.ForPosting.Insert("CheckIssued", Status = Enums.ReceiptCRStatuses.Issued);
	StructureAdditionalProperties.ForPosting.Insert("ProductReserved", Status = Enums.ReceiptCRStatuses.ProductReserved);
	StructureAdditionalProperties.ForPosting.Insert("Archival", Archival);
	
EndProcedure // AddAttributesToAdditionalPropertiesForPosting()

////////////////////////////////////////////////////////////////////////////////
// EVENT HANDLERS

// Procedure - handler of the OnCopy event.
//
Procedure OnCopy(CopiedObject)
	
	ReceiptCRNumber = "";
	Archival = False;
	Status = Enums.ReceiptCRStatuses.ReceiptIsNotIssued;
	
	CashReceived = 0;
	PaymentWithPaymentCards.Clear();
		
	StatusCashCRSession = Documents.RetailReport.GetCashCRSessionStatus(CashCR);
	FillPropertyValues(ThisObject, StatusCashCRSession);
	
	InitializeDocument();
	
EndProcedure // OnCopy()

// Procedure - FillCheckProcessing event handler.
//
Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If PaymentWithPaymentCards.Count() > 0 AND Not ValueIsFilled(POSTerminal) Then
		
		MessageText = NStr("en='The ""POS terminal"" field is not filled in';ru='Поле ""Эквайринговый терминал"" не заполнено';vi='Chưa điền trường ""Thiết bị thẻ thanh toán""'");

		SmallBusinessServer.ShowMessageAboutError(
			ThisObject,
			MessageText,
			,
			,
			"POSTerminal",
			Cancel
		);
		
	EndIf;
	
	If PaymentWithPaymentCards.Total("Amount") > DocumentAmount Then
		
		MessageText = NStr("en='Card payment amount is greater than the document amount';ru='Сумма оплаты платежными картами превышает сумму документа';vi='Số tiền trả bằng thẻ thanh toán vượt quá số tiền trên chứng từ'");
		
		SmallBusinessServer.ShowMessageAboutError(
			ThisObject,
			MessageText,
			,
			,
			"PaymentWithPaymentCards",
			Cancel
		);

	EndIf;
	
	MessageText = NStr("en='Register shift is not opened';ru='Кассовая смена не открыта';vi='Chưa mở phiên thu ngân'");
	
	If Not Documents.RetailReport.SessionIsOpen(CashCRSession, Date, MessageText) Then
		
		SmallBusinessServer.ShowMessageAboutError(
			ThisObject,
			MessageText,
			,
			,
			"CashCRSession",
			Cancel
		);

	EndIf;
	
	// Serial numbers
	WorkWithSerialNumbers.FillCheckingSerialNumbers(Cancel, Inventory, SerialNumbers, StructuralUnit, ThisObject);
	
EndProcedure // FillCheckProcessing()

// Procedure - handler of the FillingProcessor event.
//
Procedure Filling(FillingData, StandardProcessing)
	
	DataTypeFill = TypeOf(FillingData);
	
	If DataTypeFill = Type("Structure") Then
		
		FillDocumentByFilter(FillingData);
		
	Else
		
		CashCR = Catalogs.CashRegisters.GetCashCRByDefault();
		If CashCR <> Undefined Then
			FillDocumentByCachRegister(CashCR);
		EndIf;
		
	EndIf;
	
	InitializeDocument();
	
EndProcedure // FillingProcessor()

// Procedure - BeforeWrite event handler.
//
Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Status = Enums.ReceiptCRStatuses.Issued
	   AND WriteMode = DocumentWriteMode.UndoPosting
	   AND Not CashCR.UseWithoutEquipmentConnection Then
		
		MessageText = NStr("en='Cash receipt was issued on the fiscal data recorder. Cannot cancel posting';ru='Чек ККМ пробит на фискальном регистраторе. Отмена проведения невозможна';vi='Đánh phiếu tính tiền cho hàng trả lại trên máy ghi nhận tiền mặt. Không thể hủy bỏ kết chuyển'");
		
		SmallBusinessServer.ShowMessageAboutError(
				ThisObject,
				MessageText,
				,
				,
				,
				Cancel
			);
		
		Return;
		
	EndIf;
	
	If WriteMode = DocumentWriteMode.UndoPosting
	   AND CashCR.UseWithoutEquipmentConnection
	   AND CashCRSession.Posted
	   AND CashCRSession.CashCRSessionStatus = Enums.CashCRSessionStatuses.Closed Then
		
		MessageText = NStr("en='Register shift is closed. Cannot cancel posting';ru='Кассовая смена закрыта. Отмена проведения невозможна';vi='Phiên thu ngân đóng. Không thể hủy kết chuyển chứng từ'");
		
		SmallBusinessServer.ShowMessageAboutError(
				ThisObject,
				MessageText,
				,
				,
				,
				Cancel
			);
		
		Return;
		
	EndIf;
	
	If WriteMode = DocumentWriteMode.UndoPosting Then
		ReceiptCRNumber = 0;
		Status = Undefined;
	EndIf;
	
	AdditionalProperties.Insert("IsNew", IsNew());
	AdditionalProperties.Insert("WriteMode", WriteMode);
	
EndProcedure // BeforeWrite()

// Procedure - event handler Posting().
//
Procedure Posting(Cancel, PostingMode)
	
	// Initialization of additional properties for document posting.
	SmallBusinessServer.InitializeAdditionalPropertiesForPosting(Ref, AdditionalProperties);
	AddAttributesToAdditionalPropertiesForPosting(AdditionalProperties);
	
	// Document data initialization.
	Documents.ReceiptCR.InitializeDocumentData(Ref, AdditionalProperties);
	
	// Preparation of records sets.
	SmallBusinessServer.PrepareRecordSetsForRecording(ThisObject);

	SmallBusinessServer.ReflectInventoryInWarehouses(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectCashAssetsInCashRegisters(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectIncomeAndExpenses(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectSales(AdditionalProperties, RegisterRecords, Cancel);
	
	SmallBusinessServer.ReflectManagerial(AdditionalProperties, RegisterRecords, Cancel);
	
	// DiscountCards
	SmallBusinessServer.ReflectSalesByDiscountCard(AdditionalProperties, RegisterRecords, Cancel);
	// AutomaticDiscounts
	SmallBusinessServer.FlipAutomaticDiscountsApplied(AdditionalProperties, RegisterRecords, Cancel);
	
	// SerialNumbers
	SmallBusinessServer.ReflectTheSerialNumbersOfTheGuarantee(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectTheSerialNumbersBalance(AdditionalProperties, RegisterRecords, Cancel);
	
	// Record of the records sets.
	SmallBusinessServer.WriteRecordSets(ThisObject);
	
	// Control of occurrence of a negative balance.
	Documents.ReceiptCR.RunControl(Ref, AdditionalProperties, Cancel);
	
	AdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager.Close();
	
EndProcedure // Posting()

// Procedure - event handler UndoPosting object.
//
Procedure UndoPosting(Cancel)
	
	// Initialization of additional properties for document posting
	SmallBusinessServer.InitializeAdditionalPropertiesForPosting(Ref, AdditionalProperties);
	
	// Preparation of record sets
	SmallBusinessServer.PrepareRecordSetsForRecording(ThisObject);
	
	// Writing of record sets
	SmallBusinessServer.WriteRecordSets(ThisObject);
	
	// Control of occurrence of a negative balance.
	Documents.ReceiptCR.RunControl(Ref, AdditionalProperties, Cancel, True);
	
EndProcedure // UndoPosting()

#EndIf