#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region ServiceProceduresAndFunctions

// The procedure of filling in the document on the basis of cash payment voucher.
//
// Parameters:
// BasisDocument - DocumentRef.ApplicationForCashExpense - Application
// for payment FillingData - Structure - Document filling data
//	
Procedure FillByReceiptCR(Val BasisDocument, FillingData)
	
	// Fill document header data.
	QueryText = 
	"SELECT
	|	ReceiptCR.DocumentCurrency AS DocumentCurrency,
	|	ReceiptCR.Ref AS ReceiptCR,
	|	ReceiptCR.PriceKind AS PriceKind,
	|	ReceiptCR.DiscountMarkupKind AS DiscountMarkupKind,
	|	ReceiptCR.Company AS Company,
	|	ReceiptCR.VATTaxation AS VATTaxation,
	|	ReceiptCR.CashCR AS CashCR,
	|	ReceiptCR.CashCRSession AS CashCRSession,
	|	ReceiptCR.StructuralUnit AS StructuralUnit,
	|	ReceiptCR.Department AS Department,
	|	ReceiptCR.Responsible AS Responsible,
	|	ReceiptCR.DocumentAmount AS DocumentAmount,
	|	ReceiptCR.AmountIncludesVAT AS AmountIncludesVAT,
	|	ReceiptCR.IncludeVATInPrice AS IncludeVATInPrice,
	|	ReceiptCR.POSTerminal AS POSTerminal,
	|	ReceiptCR.DiscountCard AS DiscountCard,
	|	ReceiptCR.DiscountPercentByDiscountCard AS DiscountPercentByDiscountCard,
	|	ReceiptCR.Inventory.(
	|		ProductsAndServices,
	|		Characteristic,
	|		Batch,
	|		Quantity,
	|		MeasurementUnit,
	|		Price,
	|		DiscountMarkupPercent,
	|		Amount,
	|		VATRate,
	|		VATAmount,
	|		Total,
	|		AutomaticDiscountsPercent,
	|		AutomaticDiscountAmount,
	|		ConnectionKey,
	|		SerialNumbers
	|	) AS Inventory,
	|	ReceiptCR.PaymentWithPaymentCards.(
	|		ChargeCardKind,
	|		ChargeCardNo,
	|		Amount,
	|		RefNo,
	|		ETReceiptNo
	|	) AS PaymentWithPaymentCards,
	|	ReceiptCR.ReceiptCRNumber,
	|	ReceiptCR.Posted,
	|	ReceiptCR.DiscountsMarkups.(
	|		Ref,
	|		LineNumber,
	|		ConnectionKey,
	|		DiscountMarkup,
	|		Amount
	|	),
	|	ReceiptCR.DiscountsAreCalculated
	|FROM
	|	Document.ReceiptCR AS ReceiptCR
	|WHERE
	|	ReceiptCR.Ref = &Ref";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", BasisDocument);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	FillPropertyValues(ThisObject, Selection, ,"ReceiptCRNumber, Posted");
	
	ErrorText = "";
	
	If Not Documents.RetailReport.SessionIsOpen(Selection.CashCRSession, CurrentDate(), ErrorText) Then
		
		ErrorText = ErrorText + NStr("en='. Input on the basis is unavailable';ru='. Ввод на основании невозможен';vi='. Không thể nhập trên cơ sở'");
		
		Raise ErrorText;
		
	EndIf;
	
	If Not Selection.Posted Then
		
		ErrorText = NStr("en='Cash receipt is not posted. Input on the basis is not possible';ru='Чек ККМ не проведен. Ввод на основании невозможен';vi='Chưa kết chuyển phiếu tính tiền. Không thể nhập trên cơ sở'");
		
		Raise ErrorText;
		
	EndIf;
	
	If Not ValueIsFilled(Selection.ReceiptCRNumber) Then
		
		ErrorText = NStr("en='Cash receipt is not issued. Input on the basis is not possible';ru='Чек ККМ не пробит. Ввод на основании невозможен';vi='Chưa đánh phiếu tính tiền. Không thể nhập trên cơ sở'");
	
		Raise ErrorText;
		
	EndIf;
	
	ThisObject.Inventory.Load(Selection.Inventory.Unload());
	ThisObject.PaymentWithPaymentCards.Load(Selection.PaymentWithPaymentCards.Unload());
	
	WorkWithSerialNumbers.FillTSSerialNumbersByConnectionKey(ThisObject, FillingData);
	
	// AutomaticDiscounts
	If GetFunctionalOption("UseAutomaticDiscountsMarkups") Then
		ThisObject.DiscountsMarkups.Load(Selection.DiscountsMarkups.Unload());
	EndIf;
	// End AutomaticDiscounts
	
EndProcedure // FillInByCashPaymentVoucher()

// Adds additional attributes necessary for document
// posting to passed structure.
//
// Parameters:
//  StructureAdditionalProperties - Structure of additional document properties.
//
Procedure AddAttributesToAdditionalPropertiesForPosting(StructureAdditionalProperties)
	
	StructureAdditionalProperties.ForPosting.Insert("CheckIssued", ValueIsFilled(ReceiptCRNumber));
	StructureAdditionalProperties.ForPosting.Insert("Archival", Archival);
	
EndProcedure // AddAttributesToAdditionalPropertiesForPosting()

#EndRegion

#Region EventsHandlers

// Procedure - event handler "On copy".
//
Procedure OnCopy(CopiedObject)
	
	Raise NStr("en='Refund receipt can be entered only on basis';ru='Чек на возврат вводится только на основании';vi='Phiếu trả lại hàng chỉ được nhập trên cơ sở'");
	
EndProcedure // OnCopy()

// Procedure - event handler "FillingProcessor".
//
Procedure Filling(FillingData, StandardProcessing)
	
	DataTypeFill = TypeOf(FillingData);
	
	If TypeOf(FillingData) = Type("DocumentRef.ReceiptCR") Then
		
		FillByReceiptCR(FillingData, FillingData);
		
	Else
		
		Raise NStr("en='Refund receipts must be entered only on basis of cash receipts.';ru='Чеки ККМ на возврат должны вводится на основании чеков ККМ';vi='Phiếu tính tiền trả lại hàng cần được nhập trên cơ sở phiếu tính tiền'");
		
	EndIf;
	
EndProcedure // FillingProcessor()

// Procedure - event handler "Filling check processor".
//
Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	ReceiptCRReturn.Ref
	|FROM
	|	Document.ReceiptCRReturn AS ReceiptCRReturn
	|WHERE
	|	ReceiptCRReturn.Ref <> &Ref
	|	AND ReceiptCRReturn.Posted
	|	AND ReceiptCRReturn.ReceiptCR = &ReceiptCR
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReceiptCR.CashCRSession AS CashCRSession,
	|	ReceiptCR.Date AS Date,
	|	ReceiptCR.Posted AS Posted,
	|	ReceiptCR.ReceiptCRNumber AS ReceiptCRNumber
	|FROM
	|	Document.ReceiptCR AS ReceiptCR
	|WHERE
	|	ReceiptCR.Ref = &ReceiptCR";
	
	Query.SetParameter("ReceiptCR", ReceiptCR);
	Query.SetParameter("Ref", Ref);
	
	Result = Query.ExecuteBatch();
	Selection = Result[0].Select();
	
	While Selection.Next() Do
		
		ErrorText = NStr("en='Refund receipt has already been entered for this receipt';ru='Для данного чека уже введен чек на возврат';vi='Đối với phiếu này đã nhập phiếu trả lại'");
		
		SmallBusinessServer.ShowMessageAboutError(
			ThisObject,
			ErrorText,
			Undefined,
			Undefined,
			"ReceiptCR",
			Cancel
		); 
		
	EndDo;
	
	Selection = Result[1].Select();
	
	While Selection.Next() Do
		
		If BegOfDay(Selection.Date) <> BegOfDay(Date) Then
			
			ErrorText = NStr("en='Refund receipt date should correspond to sales receipt date';ru='Дата чека на возврат должна соответствовать дате чека продажи';vi='Ngày trên phiếu trả lại cần tương ứng với ngày trên phiếu bán hàng'");
			
			SmallBusinessServer.ShowMessageAboutError(
				ThisObject,
				ErrorText,
				Undefined,
				Undefined,
				"Date",
				Cancel
			); 

		EndIf;
		
		If CashCRSession <> Selection.CashCRSession Then
			
			ErrorText = NStr("en='Refund receipt register shift should correspond to sale receipt register shift';ru='Кассовая смена Чека на возврат должна соответствовать кассовой смене чека продажи';vi='Phiên thu ngân của Phiếu trả lại cần tương ứng với phiên thu ngân của phiếu bán hàng'");
			
			SmallBusinessServer.ShowMessageAboutError(
				ThisObject,
				ErrorText,
				Undefined,
				Undefined,
				"CashCRSession",
				Cancel
			); 

		EndIf;
		
		If Not Selection.Posted Then
			
			ErrorText = NStr("en='Cash receipt is not posted';ru='Чек ККМ не проведен';vi='Chưa kết chuyển phiếu tính tiền'");
			
			SmallBusinessServer.ShowMessageAboutError(
				ThisObject,
				ErrorText,
				Undefined,
				Undefined,
				"ReceiptCR",
				Cancel
			); 

		EndIf;
		
		If Not ValueIsFilled(Selection.ReceiptCRNumber) Then
			
			ErrorText = NStr("en='Cash receipt of a sale is not issued';ru='Чек ККМ продажи не пробит';vi='Chưa đánh phiếu tính tiền bán hàng'");
			
			SmallBusinessServer.ShowMessageAboutError(
				ThisObject,
				ErrorText,
				Undefined,
				Undefined,
				"ReceiptCR",
				Cancel
			);
			
		EndIf;
		
		ErrorText = NStr("en='Register shift is not opened';ru='Кассовая смена не открыта';vi='Chưa mở phiên thu ngân'");
		If Not Documents.RetailReport.SessionIsOpen(CashCRSession, Date, ErrorText) Then
			
			
			SmallBusinessServer.ShowMessageAboutError(
				ThisObject,
				ErrorText,
				Undefined,
				Undefined,
				"CashCRSession",
				Cancel
			);

		EndIf;
		
	EndDo;
	
	If PaymentWithPaymentCards.Count() > 0 AND Not ValueIsFilled(POSTerminal) Then
		
		ErrorText = NStr("en='The ""POS terminal"" field is not filled in';ru='Поле ""Эквайринговый терминал"" не заполнено';vi='Chưa điền trường ""Thiết bị thẻ thanh toán""'");
		
		SmallBusinessServer.ShowMessageAboutError(
			ThisObject,
			ErrorText,
			Undefined,
			Undefined,
			"POSTerminal",
			Cancel
		);
		
	EndIf;
	
	// Serial numbers
	WorkWithSerialNumbers.FillCheckingSerialNumbers(Cancel, Inventory, SerialNumbers, StructuralUnit, ThisObject);
	
EndProcedure // FillCheckProcessing()

// Procedure - event handler "BeforeWrite".
//
Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If ValueIsFilled(ReceiptCRNumber)
	   AND WriteMode = DocumentWriteMode.UndoPosting
	   AND Not CashCR.UseWithoutEquipmentConnection Then
		
		Cancel = True;
		
		ErrorText = NStr("en='Cash receipt for return is issued on the fiscal data recorder. Cannot cancel posting';ru='Чек ККМ на возврат пробит на фискальном регистраторе. Отмена проведения невозможна';vi='Đánh phiếu tính tiền cho hàng trả lại trên máy ghi nhận tiền mặt. Không thể hủy bỏ kết chuyển'");
		
		CommonUseClientServer.MessageToUser(
			ErrorText,
			ThisObject);
			
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
	
	AdditionalProperties.Insert("IsNew",    IsNew());
	AdditionalProperties.Insert("WriteMode", WriteMode);
	
EndProcedure // BeforeWrite()

// Procedure - event handler "Posting".
//
Procedure Posting(Cancel, PostingMode)
	
	// Initialization of additional properties for document posting.
	SmallBusinessServer.InitializeAdditionalPropertiesForPosting(Ref, AdditionalProperties);
	AddAttributesToAdditionalPropertiesForPosting(AdditionalProperties);
	
	// Document data initialization.
	Documents.ReceiptCRReturn.InitializeDocumentData(Ref, AdditionalProperties);
	
	// Preparation of records sets.
	SmallBusinessServer.PrepareRecordSetsForRecording(ThisObject);

	SmallBusinessServer.ReflectInventoryInWarehouses(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectCashAssetsInCashRegisters(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectIncomeAndExpenses(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectSales(AdditionalProperties, RegisterRecords, Cancel);
	
	// DiscountCards
	SmallBusinessServer.ReflectSalesByDiscountCard(AdditionalProperties, RegisterRecords, Cancel);
	
	// AutomaticDiscounts
	SmallBusinessServer.FlipAutomaticDiscountsApplied(AdditionalProperties, RegisterRecords, Cancel);
	
	SmallBusinessServer.ReflectManagerial(AdditionalProperties, RegisterRecords, Cancel);
	
	// SerialNumbers
	SmallBusinessServer.ReflectTheSerialNumbersOfTheGuarantee(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectTheSerialNumbersBalance(AdditionalProperties, RegisterRecords, Cancel);
	
	// Record of the records sets.
	SmallBusinessServer.WriteRecordSets(ThisObject);
	
	// Control of occurrence of a negative balance.
	Documents.ReceiptCRReturn.RunControl(Ref, AdditionalProperties, Cancel);

	AdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager.Close();
	
EndProcedure // Posting()

// Procedure - event handler "UndoPosting".
//
Procedure UndoPosting(Cancel)
	
	// Initialization of additional properties for document posting
	SmallBusinessServer.InitializeAdditionalPropertiesForPosting(Ref, AdditionalProperties);
	
	// Preparation of record sets
	SmallBusinessServer.PrepareRecordSetsForRecording(ThisObject);
	
	// Writing of record sets
	SmallBusinessServer.WriteRecordSets(ThisObject);
	
	// Control of occurrence of a negative balance.
	Documents.ReceiptCRReturn.RunControl(Ref, AdditionalProperties, Cancel, True);
	
EndProcedure // UndoPosting()

#EndRegion

#EndIf