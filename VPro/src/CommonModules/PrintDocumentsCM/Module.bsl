
#Region InternalProceduresAndFunctions

Procedure BeforeStartDocumentGeneration(SpreadsheetDocument, FirstDocument, FirstLineNumber, PrintInfo = Undefined) Export
	
	If FirstDocument = True
		Or FirstDocument = Undefined Then
		
		FirstDocument = False;
		
	Else
		
		SpreadsheetDocument.PutHorizontalPageBreak();
		
	EndIf;
	
	FirstLineNumber = SpreadsheetDocument.TableHeight + 1;
	
	If TypeOf(PrintInfo) = Type("Structure") Then
		
		PrintInfo.Clear();
		
	EndIf;
	
EndProcedure

Function ProductsAndServicesPresentationRow(ProductsAndServicesParameters) Export
	
	ProductsAndServicesPresentation = "";
	If ProductsAndServicesParameters.Property("ProductsAndServicesPresentation") Then
		
		If TypeOf(ProductsAndServicesParameters.ProductsAndServicesPresentation) = Type("CatalogRef.ProductsAndServices") Then
			
			ProductsAndServicesPresentation = CommonUse.ObjectAttributeValue(ProductsAndServicesParameters.ProductsAndServicesPresentation, "DescriptionFull");
			If IsBlankString(ProductsAndServicesPresentation) Then
				
				ProductsAndServicesPresentation = CommonUse.ObjectAttributeValue(ProductsAndServicesParameters.ProductsAndServicesPresentation, "Description");
				
			EndIf;
			
		Else
			
			ProductsAndServicesPresentation = TrimAll(ProductsAndServicesParameters.ProductsAndServicesPresentation);
			
		EndIf;
		
	EndIf;
	
	
	Return ProductsAndServicesPresentation;
	
EndFunction

Function CharacteristicPresentationString(ProductsAndServicesParameters) Export
	
	CharacteristicPresentation = "";
	If GetFunctionalOption("UseCharacteristics") Then
		
		If ProductsAndServicesParameters.Property("CharacteristicPresentation") Then
			
			If TypeOf(ProductsAndServicesParameters.CharacteristicPresentation) = Type("CatalogRef.ProductsAndServicesCharacteristics") Then
				
				CharacteristicPresentation = CommonUse.ObjectAttributeValue(ProductsAndServicesParameters.CharacteristicPresentation, "Description");
				If IsBlankString(CharacteristicPresentation) Then
					
					CharacteristicPresentation = CommonUse.ObjectAttributeValue(ProductsAndServicesParameters.CharacteristicPresentation, "Description");
					
				EndIf;
				
			Else
				
				CharacteristicPresentation = TrimAll(ProductsAndServicesParameters.CharacteristicPresentation);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return CharacteristicPresentation;
	
EndFunction

Function BatchPresentationString(ProductsAndServicesParameters) Export
	
	BatchPresentation = "";
	If GetFunctionalOption("UseBatches") Then
		
		If ProductsAndServicesParameters.Property("BatchPresentation") Then
			
			If TypeOf(ProductsAndServicesParameters.BatchPresentation) = Type("CatalogRef.ProductsAndServicesBatches") Then
				
				BatchPresentation = CommonUse.ObjectAttributeValue(ProductsAndServicesParameters.BatchPresentation, "Description");
				
			Else
				
				BatchPresentation = TrimAll(ProductsAndServicesParameters.BatchPresentation);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return BatchPresentation;
	
EndFunction

Function TNFEACodePresentationString(ProductsAndServicesParameters) Export
	
	PresentationOfTNFEACode = "";
	If ProductsAndServicesParameters.Property("FEACNCode") Then
		
		If TypeOf(ProductsAndServicesParameters.FEACNCode) = Type("CatalogRef.TNFEAClassifier") Then
			
			PresentationOfTNFEACode = CommonUse.ObjectAttributeValue(ProductsAndServicesParameters.FEACNCode, "Code");
			
		Else
			
			PresentationOfTNFEACode = TrimAll(ProductsAndServicesParameters.FEACNCode);
			
		EndIf;
		
	EndIf;
	
	Return PresentationOfTNFEACode;
	
EndFunction

Function SerialNumberPresentationString(ProductsAndServicesParameters) Export
	
	SerialNumberPresentation = "";
	If GetFunctionalOption("UseSerialNumbers") Then
		
		If ProductsAndServicesParameters.Property("SerialNumberPresentation") Then
			
			If TypeOf(ProductsAndServicesParameters.SerialNumberPresentation) = Type("CatalogRef.SerialNumbers") Then
				
				SerialNumberPresentation = CommonUse.ObjectAttributeValue(ProductsAndServicesParameters.SerialNumberPresentation, "Description");
				
			Else
				
				SerialNumberPresentation = TrimAll(ProductsAndServicesParameters.SerialNumberPresentation);
				
			EndIf;
			
			
		EndIf;
		
	EndIf;
	
	Return SerialNumberPresentation;
	
EndFunction

Function MustBeSelectedAsSetComponent(ProductsAndServicesParameters) Export
	Var ToAllocateAsSetContent;
	
	ProductsAndServicesParameters.Property("ToAllocateAsSetContent", ToAllocateAsSetContent);
	Return ToAllocateAsSetContent = True;
	
EndFunction

// Функция формирует представление номенклатуры в печатной форме
// Parameters:
//  ProductsAndServicesParameters - Structure - Структура с параметрами, по которым формируется представление.
//
//  Номенклатура - Ссылка или строка - Формируется строка представления номенклатуры.
//  Характеристика - Ссылка или строка - Формируется строка представления характеристики.
//                                        Если получено значение, добавляется в общую строку представления номенклатуры.
//  СерийныйНомер - Ссылка или строка - Формируется строка представления серийного номера.
//                                        Если получено значение, добавляется в общую строку представления номенклатуры.
//  Партия - Ссылка или строка - Формируется строка представления партии номенклатуры.
//                                        Если получено значение, добавляется в общую строку представления номенклатуры.
//
// Returns:
//  String - представление номенклатуры в печатной форме.
//
//
Function ProductsAndServicesPresentation(ProductsAndServicesParameters) Export
	
	ProductsAndServicesPresentation = "";
	CharacteristicPresentation = "";
	SerialNumberPresentation = "";
	BatchPresentation = "";
	PresentationOfTNFEACode = "";
	// "ПредставлениеАртикула" начиная с версии 1.6.11 не используется в представлении номенклатуры.
	
	ToAllocateAsSetContent = MustBeSelectedAsSetComponent(ProductsAndServicesParameters);
	
	If ProductsAndServicesParameters.Property("Content") 
		And Not IsBlankString(ProductsAndServicesParameters.Content) Then
		
		ProductsAndServicesPresentation = ProductsAndServicesParameters.Content;
		
	Else
		
		ProductsAndServicesPresentation = ProductsAndServicesPresentationRow(ProductsAndServicesParameters);
		CharacteristicPresentation = CharacteristicPresentationString(ProductsAndServicesParameters);
		SerialNumberPresentation = SerialNumberPresentationString(ProductsAndServicesParameters);
		BatchPresentation = BatchPresentationString(ProductsAndServicesParameters);
		PresentationOfTNFEACode = TNFEACodePresentationString(ProductsAndServicesParameters);
		
	EndIf;
	
	Return GetProductsAndServicesPresentationForPrinting(ProductsAndServicesPresentation, CharacteristicPresentation, SerialNumberPresentation, BatchPresentation, PresentationOfTNFEACode, ToAllocateAsSetContent);
	
EndFunction // ПредставлениеНоменклатуры()

Function DatePresentationInDocuments(ValueDates) Export
	
	Return Format(ValueDates, "DLF=DD");
	
EndFunction

Function VATHeaderPresentation(VATAmount, AmountIncludesVAT, PartialPayment, HasZeroPercentRate = False) Export
	Var VATTotalsHeader;
	
	TextVAT = NStr("en='НДС';ru='НДС';vi='Thuế GTGT'");
	If PartialPayment Then
		
		TextVAT = TextVAT + NStr("en=' оплаты';ru=' оплаты';vi='thanh toán'");
		
	EndIf;
	
	If VATAmount = 0 
		And Not HasZeroPercentRate Then
		
		VATTotalsHeader = NStr("en='Без налога (НДС)';ru='Без налога (НДС)';vi='Không thuế (GTGT)'");
		
	ElsIf AmountIncludesVAT Then
		
		VATTotalsHeader = StrTemplate(NStr("en='В том числе %1:';ru='В том числе %1:';vi='Bao gồm %1:'"), TextVAT);
		
	Else
		
		VATTotalsHeader = StrTemplate(NStr("en='Сумма %1:';ru='Сумма %1:';vi='Số tiền %1:'"), TextVAT);
		
	EndIf;
	
	Return VATTotalsHeader;
	
EndFunction

Function PrintBasisPresentation(PrintBasisRef) Export
	
	If Not ValueIsFilled(PrintBasisRef) Then
		
		If TypeOf(PrintBasisRef) = Type("DocumentRef.CustomerOrder") Then
			
			Return ParameterThisDocumentCustomerOrder();
			
		ElsIf TypeOf(PrintBasisRef) = Type("DocumentRef.InvoiceForPayment") Then
			
			Return ParameterThisDocumentInvoiceForPayment();
			
		Else
			
			Return "";
			
		EndIf;
		
	ElsIf TypeOf(PrintBasisRef) = Type("CatalogRef.CounterpartyContracts") Then
		
		PresentationTitle = "";
		If Constants.AddWordContractInPrintBasisContractPresentation.Get() Then
			
			PresentationTitle = NStr("en='Договор: ';ru='Договор: ';vi='Hợp đồng:'");
			
		EndIf;
		
		Return PresentationTitle + String(PrintBasisRef.Description);
		
	ElsIf TypeOf(PrintBasisRef) = Type("DocumentRef.InvoiceForPayment")
		Or TypeOf(PrintBasisRef) = Type("DocumentRef.CustomerOrder")
		Or TypeOf(PrintBasisRef) = Type("DocumentRef.PurchaseOrder")
		Or TypeOf(PrintBasisRef) = Type("DocumentRef.CustomerInvoice")
		Or TypeOf(PrintBasisRef) = Type("DocumentRef.AcceptanceCertificate")
		Or TypeOf(PrintBasisRef) = Type("DocumentRef.ReceptionAndTransferToRepair")
		Then
		
		Return String(PrintBasisRef);
		
	EndIf;
	
EndFunction

Function PrintBasisDateNumberPresentation(PrintBasisRef) Export
	
	PrintBasisData = New Structure("Number, Date");
	
	If ValueIsFilled(PrintBasisRef) Then
		
		If TypeOf(PrintBasisRef) = Type("CatalogRef.CounterpartyContracts") Then
			
			PrintBasisData.Number = CommonUse.ObjectAttributeValue(PrintBasisRef, "ContractNo");
			PrintBasisData.Date = CommonUse.ObjectAttributeValue(PrintBasisRef, "ContractDate");
			
		ElsIf TypeOf(PrintBasisRef) = Type("DocumentRef.InvoiceForPayment")
			Or TypeOf(PrintBasisRef) = Type("DocumentRef.CustomerOrder")
			Or TypeOf(PrintBasisRef) = Type("DocumentRef.PurchaseOrder")
			Then
			
			FillPropertyValues(PrintBasisData, PrintBasisRef, "Number, Date");
			
		EndIf;
		
	EndIf;
	
	Return PrintBasisData;
	
EndFunction

Function ProductsAndServicesCodePresentation(ProductsAndServicesParameters) Export
	
	ProductsAndServicesCodePresentation = "";
	FieldName = "";
	
	PresentationKind = Constants.CodesPresentationInPrintForms.Get();
	If PresentationKind = Enums.ProductsAndServicesCodesInDocuments.Code Then
		
		FieldName = "Code";
		
	ElsIf PresentationKind = Enums.ProductsAndServicesCodesInDocuments.SKU Then
		
		FieldName = "SKU";
		
	EndIf;
	
	If IsBlankString(FieldName) Then
		
		// обработка не требуется
		
	ElsIf TypeOf(ProductsAndServicesParameters) = Type("ValueTableRow")
		Or TypeOf(ProductsAndServicesParameters) = Type("ValueTreeRow")
		Or TypeOf(ProductsAndServicesParameters) = Type("QueryResultSelection") Then
		
		Try
			ProductsAndServicesCodePresentation = ProductsAndServicesParameters[FieldName];
		Except
		EndTry;
		
	ElsIf TypeOf(ProductsAndServicesParameters) = Type("Structure") Then
		
		ProductsAndServicesParameters.Property(FieldName, ProductsAndServicesCodePresentation);
		
	EndIf;
	
	Return ProductsAndServicesCodePresentation;
	
EndFunction

Function SerialNumberPresentationByKey(SerialNumbersTable, ConnectionKey) Export
	
	SerialNumberPresentation = "";
	
	If TypeOf(SerialNumbersTable) = Type("ValueTable")
		And SerialNumbersTable.Count() > 0 Then
		
		FoundStringArray = SerialNumbersTable.FindRows(New Structure("ConnectionKey", ConnectionKey));
		For Each ArrayRow In FoundStringArray Do
			
			SerialNumberPresentation = SerialNumberPresentation + ?(IsBlankString(SerialNumberPresentation), "", ", ") + TrimAll(ArrayRow.SerialNumber);
			
		EndDo;
		
	EndIf;
	
	Return SerialNumberPresentation;
	
EndFunction

Function DiscountPresentation(TabularSectionRow, TotalStructure) Export
	
	DiscountAmount = 0;
	DiscountPercent = 0;
	
	DiscountRoundingAccuracy = 2; // Знаков после запятой
	
	If TabularSectionRow.DiscountMarkupPercent = 100 Then
		
		DiscountAmount = TabularSectionRow.Price * TabularSectionRow.Count;
		DiscountPercent = NStr("en='100%';ru='100%';vi='100%'");
		
	ElsIf TabularSectionRow.DiscountMarkupPercent = 0 
		And TabularSectionRow.AutomaticDiscountAmount = 0 Then
		
		DiscountAmount = 0;
		DiscountPercent = NStr("en='-';ru='-';vi='-'");
		
	Else
		
		DiscountAmount = (TabularSectionRow.Count * TabularSectionRow.Price) - TabularSectionRow.Amount;
		
		If DiscountAmount > 0 Then
			
			Denominator = (TabularSectionRow.Count * TabularSectionRow.Price);
			If Denominator = 0 Then
				
				DiscountPercent = 0;
				
			Else
				
				DiscountPercent = (TabularSectionRow.Amount * 100) / Denominator;
				DiscountPercent = String(100 - Round(DiscountPercent, DiscountRoundingAccuracy)) + "%";
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If TotalStructure.Property("DiscountByString") Then
		
		TotalStructure.DiscountByString = DiscountAmount;
		
	EndIf;
	
	Return ?(TotalStructure.DiscountPresentation = Enums.DiscountDisplayMethod.Percent, DiscountPercent, Format(DiscountAmount, "NFD=2; NG="));
	
EndFunction

Function DocumentsSetPresentation() Export
	
	Return NStr("en='Настраиваемый комплект документов';ru='Настраиваемый комплект документов';vi='Bộ chứng từ được tùy chỉnh'");
	
EndFunction


Function ParameterThisDocumentCustomerOrder() Export
	
	Return NStr("en='Этот документ (Заказ покупателя)';ru='Этот документ (Заказ покупателя)';vi='Chứng từ này (Đơn đặt hàng của người mua)'");
	
EndFunction

Function ParameterThisDocumentInvoiceForPayment() Export
	
	Return NStr("en='Этот документ (Счет на оплату)';ru='Этот документ (Счет на оплату)';vi='Chứng từ này (Hóa đơn thanh toán)'");
	
EndFunction

Function GetProductsAndServicesPresentationForPrinting(ProductsAndServicesPresentation, CharacteristicPresentation = "", SerialNumberPresentation = "", BatchPresentation = "", PresentationOfTNFEACode = "", ToAllocateAsSetContent = False) Export
	
	RowParameters = New Structure;
	RowParameters.Insert("ProductsAndServicesPresentation", ProductsAndServicesPresentation);
	RowParameters.Insert("CharacteristicPresentation", CharacteristicPresentation);
	RowParameters.Insert("SerialNumberPresentation", SerialNumberPresentation);
	RowParameters.Insert("BatchPresentation", BatchPresentation);
	RowParameters.Insert("PresentationOfTNFEACode", PresentationOfTNFEACode);
	
	// Шаблон представления:
	//[ПредставлениеНоменклатуры] ([ПредставлениеХарактеристики], [ПредставлениеСерийногоНомера]), [ПредставлениеПартии], {код ТН ВЭД [ПредставлениеКодаТНВЭД]};
	
	If IsBlankString(CharacteristicPresentation)
		And IsBlankString(SerialNumberPresentation) Then
		
		PresentationPattern = "[ProductsAndServicesPresentation]";
		
	ElsIf Not IsBlankString(CharacteristicPresentation)
		And Not IsBlankString(SerialNumberPresentation) Then
		
		PresentationPattern = "[ProductsAndServicesPresentation] ([CharacteristicPresentation], [SerialNumberPresentation])";
		
	ElsIf IsBlankString(SerialNumberPresentation) Then 
		
		PresentationPattern = "[ProductsAndServicesPresentation] ([CharacteristicPresentation])";
		
	Else
		
		PresentationPattern = "[ProductsAndServicesPresentation] ([SerialNumberPresentation])";
		
	EndIf;
	
	If Not IsBlankString(BatchPresentation) Then
		
		PresentationPattern = PresentationPattern + ", [BatchPresentation]";
		
	EndIf;
	
	If Not IsBlankString(PresentationOfTNFEACode) Then
		
		PresentationPattern = PresentationPattern + NStr("en=', код ТН ВЭД ';ru=', код ТН ВЭД ';vi=', Mã TN VED'") + " [PresentationOfTNFEACode]";
		
	EndIf;
	
	If ToAllocateAsSetContent Then
		
		PresentationPattern = NStr("en='    • ';ru='    • ';vi='•'") + PresentationPattern;
		
	EndIf;
	
	Return StringFunctionsClientServer.SubstituteParametersInStringByName(PresentationPattern, RowParameters);
	
EndFunction // ПолучитьПредставлениеНоменклатурыДляПечати()

Function GetSourceAdjustmentDocument(DocumentRef) Export
	
	If Not ValueIsFilled(DocumentRef) Then
		
		Return Undefined;
		
	ElsIf TypeOf(DocumentRef) = Type("DocumentRef.SalesAdjustment") Then
		
		Return GetSourceAdjustmentDocument(CommonUse.ObjectAttributeValue(DocumentRef, "BasisDocument"));
		
	Else
		
		Return DocumentRef;
		
	EndIf;
	
EndFunction

Function GetAreaSafely(Template, AreaName, AreaPresentation, Errors) Export
	Var TemplateArea;
	
	If Template.Areas.Find(AreaName) = Undefined Then
		
		MessageText = NStr("en='ВНИМАНИЕ! Не обнаружена область макета %1. Возможно используется пользовательский макет.';ru='ВНИМАНИЕ! Не обнаружена область макета %1. Возможно используется пользовательский макет.';vi='CHÚ Ý! Không tìm thấy khu vực bố trí %1. Có thể một bố cục tùy chỉnh được sử dụng.'");
		MessageText = StrTemplate(MessageText, ?(IsBlankString(AreaPresentation), AreaName, AreaPresentation));
		
		CommonUseClientServer.AddUserError(Errors, , MessageText, Undefined);
		
	Else
		
		TemplateArea = Template.GetArea(AreaName);
		
	EndIf;
	
	Return TemplateArea;
	
EndFunction

Procedure SetParameterSafe(Area, ParameterName, Value) Export
	
	ParameterValues = New Structure;
	ParameterValues.Insert(ParameterName, Value);
	Area.Parameters.Fill(ParameterValues);
	
EndProcedure

Function GetSignatureSafetyDie(TemplateArea, DieName, SignaturePresentation, Errors) Export
	
	SignatureDie = TemplateArea.Areas.Find(DieName);
	If SignatureDie = Undefined Then
		
		MessageText = NStr("en='ВНИМАНИЕ! Нет места для подписи %1. Возможно используется пользовательский макет.';ru='ВНИМАНИЕ! Нет места для подписи %1. Возможно используется пользовательский макет.';vi='CHÚ Ý! Không có khoảng trống cho chữ ký %1. Có thể một bố cục tùy chỉnh được sử dụng.'");
		MessageText = StrTemplate(MessageText, ?(IsBlankString(SignaturePresentation), DieName, SignaturePresentation));
		
		CommonUseClientServer.AddUserError(Errors, , MessageText, Undefined);
		
	Else
		
		SignatureDie.Line = New Line(SpreadsheetDocumentDrawingLineType.None);
		
	EndIf;
	
	Return SignatureDie;
	
EndFunction

Function GetNumberForPrintingConsideringDocumentDate(DocumentDate, DocumentNumber, Prefix) Export
	
	If DocumentDate < Date('20110101') Then
		
		Return SmallBusinessServer.GetNumberForPrinting(DocumentNumber, Prefix);
		
	Else
		
		WithoutIBPrefix = Constants.DocumentNumberPresentationWithoutInfobasePrefix.Get();
		WithoutUserPrefix = Constants.DocumentNumberPresentationWithoutUserPrefix.Get();
		
		Return ObjectPrefixationClientServer.NumberForPrinting(DocumentNumber, WithoutIBPrefix, WithoutUserPrefix);
		
	EndIf;
	
EndFunction

Procedure AdjustPlacementOfSubordinatePrintCommandsGroup(Form, FormItem_PrintSubmenu, FormItem_CMCommandsGroup) Export
	
	DefaultFormGroupName = "SubmenuPrintNormal";
	
	FormGroupWithPrintCommands = Form.Items.Find(DefaultFormGroupName);
	If FormGroupWithPrintCommands = Undefined Then
		
		FormGroupWithPrintCommands = FormItem_PrintSubmenu;
		
	EndIf;
	
	Form.Items.Move(FormItem_CMCommandsGroup, FormGroupWithPrintCommands);
	
EndProcedure

Function TemplateEditWarningTextPattern() Export
	
	Return NStr("en='ВНИМАНИЕ! Возможно используется пользовательский макет. Штатный механизм печати счетов может работать некоректно.';ru='ВНИМАНИЕ! Возможно используется пользовательский макет. Штатный механизм печати счетов может работать некоректно.';vi='CHÚ Ý! Có thể sử dụng khuôn mẫu tự tạo. Cơ chế thông thường khi in hóa đơn có thể hoạt động không chính xác.'");
	
EndFunction

Function TotalRow(PositionsQuantity, DocumentAmount, DocumentCurrency) Export
	
	Return StrTemplate(
		NStr("en='Всего наименований %1, на сумму %2';ru='Всего наименований %1, на сумму %2';vi='Tổng số mục %1, số tiền %2'"),
		PositionsQuantity,
		SmallBusinessServer.AmountsFormat(DocumentAmount, DocumentCurrency)
	);
	
EndFunction

Function DocumentFormedAccordingToFZ56(Date) Export
	
	// Используется при формирование
	// - СФ
	// - УПД
	// - Корректировочный СФ
	
	ApplicationStartFZ56 = '20170701';
	Regulation981Applies = (Date >= Constants.StartUsingSF981.Get());
	
	Return (Date >= ApplicationStartFZ56) And Not Regulation981Applies;
	
EndFunction

// Возвращает версию постановления Правительства РФ от 26.12.2011 г. № 1137
//
// PARAMETERS
//  Период  -  тип дата, в данном параметре передается
//             дата на которую необходимо определить версию постановления
// Returns:
//  Number   -  версия постановления,
//              "1137" (БП = 1) - исходная версия постановления Правительства РФ от 26.12.2011 г. № 1137
//              "952"  (БП = 2) - постановление Правительства РФ от 26.12.2011 г. № 1137 в редакции постановления № 952
//              "735"  (БП = 3) - постановление Правительства РФ от 26.12.2011 г. № 1137 в редакции постановления № 735
//              "981"  (БП = 4) - постановление Правительства РФ от 26.12.2011 г. № 1137 в редакции постановления № 981
//
Function Version1137VATOrdinance(Period) Export
	
	If Period >= '20171001' Then			// Постановление № 981 вступает в силу с 1 октября 2017 года.
		Return "981"; 						//  в БП = 4
	ElsIf Period >= '20141001' Then	// Постановление № 735 вступает в силу с 1 октября 2014 года.
		Return "735";						//  в БП = 3
	ElsIf Period >= '20131106' Then	// Постановление № 952 вступает в силу с 6 ноября 2013 года.
		Return "952";						//  в БП = 2
	Else									// Исходная версия Постановления Правительства РФ от 26.12.2011 г. № 1137.
		Return "1137";						//  в БП = 1
	EndIf;
	
EndFunction // ВерсияПостановленияНДС1137()

Function SpreadsheetDocumentFitsPage(SpreadsheetDocument, AreasToPut, Errors) Export
	
	Try
		
		Return SpreadsheetDocument.CheckPut(AreasToPut);
		
	Except
		
		ErrorDescription = ErrorInfo();
		ErrorText = NStr("en='Невозможно получить информацию о текущем принтере (возможно, в системе не установлено ни одного принтера)';ru='Невозможно получить информацию о текущем принтере (возможно, в системе не установлено ни одного принтера)';vi='Không thể nhận thông tin về máy in hiện tại (có thể, trong hệ thống chưa thiết lập máy in nào)'");
		
		WriteLogEvent(ErrorText, EventLogLevel.Error , , , ErrorDescription.Description);
		
	EndTry;

EndFunction

Procedure PrintBasisFillingProcessing(Var_ThisObject) Export
	
	ConstantTypesMap = New Map;
	ConstantTypesMap.Insert(Type("DocumentRef.CustomerOrder"), "PrintBasisCustomerOrder");
	ConstantTypesMap.Insert(Type("DocumentRef.InvoiceForPayment"), "PrintBasisInvoiceForPayment");
	
	ConstantName = ConstantTypesMap.Get(TypeOf(Var_ThisObject.Ref));
	
	ConstantValue = Constants[ConstantName].Get();
	If ConstantValue = Enums.PrintBasisInitialFillingMethod.CurrentDocument Then
		
		If ConstantName = "PrintBasisCustomerOrder" Then
			
			Var_ThisObject.PrintBasisRef = Documents.CustomerOrder.EmptyRef();
			Var_ThisObject.StampBase = ParameterThisDocumentCustomerOrder();
			
		ElsIf ConstantName = "PrintBasisInvoiceForPayment" Then
			
			Var_ThisObject.PrintBasisRef = Documents.InvoiceForPayment.EmptyRef();
			Var_ThisObject.StampBase = ParameterThisDocumentInvoiceForPayment();
			
		EndIf;
		
	ElsIf ConstantValue = Enums.PrintBasisInitialFillingMethod.CounterpartyContract Then
		
		If ValueIsFilled(Var_ThisObject.Contract) Then
			
			Var_ThisObject.PrintBasisRef = Var_ThisObject.Contract;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#Region CurrencyAmounts

Function AddAmountFields(QueryOptions, DocumentTabularSection, EnumValueDocumentsTabularSections)
	
	Query = New Query;
	Query.SetParameter("Ref", QueryOptions.Ref);
	Query.SetParameter("ExchangeRateDocument", QueryOptions.ExchangeRateDocument);
	Query.SetParameter("MultiplicityOfDocument", QueryOptions.MultiplicityOfDocument);
	Query.SetParameter("DocumentTabularSection", DocumentTabularSection);
	Query.SetParameter("EnumValueDocumentsTabularSections", EnumValueDocumentsTabularSections);
	
	Query.Text =
	"SELECT
	|	DocumentTabularSection.LineNumber AS LineNumber
	|	,DocumentTabularSection.ProductsAndServicesPresentation
	|	,DocumentTabularSection.Code
	|	,DocumentTabularSection.SKU
	|	,DocumentTabularSection.ProductsAndServicesType
	|	,DocumentTabularSection.Warehouse
	|	,DocumentTabularSection.Cell
	|	,DocumentTabularSection.CHARACTERISTIC
	|	,DocumentTabularSection.Batch
	|	,DocumentTabularSection.MeasurementUnit
	|	,DocumentTabularSection.MeasurementUnitByOKEI_Description
	|	,DocumentTabularSection.MeasurementUnitByOKEI_Code
	|	,DocumentTabularSection.Price
	|	,DocumentTabularSection.Amount
	|	,DocumentTabularSection.VATRate
	|	,DocumentTabularSection.VATAmount
	|	,DocumentTabularSection.Total
	|	,DocumentTabularSection.Quantity
	|	,DocumentTabularSection.QuantityByCoefficient
	|	,DocumentTabularSection.Content
	|	,DocumentTabularSection.DiscountMarkupPercent
	|	,DocumentTabularSection.IsDiscount
	|	,DocumentTabularSection.AutomaticDiscountAmount
	|	,DocumentTabularSection.ConnectionKey
	|	,DocumentTabularSection.DocOrder
	|	,DocumentTabularSection.IsSplitter
	|INTO DocumentTabularSection
	|FROM &DocumentTabularSection AS DocumentTabularSection
	|INDEX BY LineNumber
	|
	|;SELECT
	|	DocumentRows.LineNumber AS LineNumber
	|	,DocumentRows.ProductsAndServicesPresentation
	|	,DocumentRows.Code
	|	,DocumentRows.SKU
	|	,DocumentRows.ProductsAndServicesType
	|	,DocumentRows.Warehouse
	|	,DocumentRows.Cell
	|	,DocumentRows.CHARACTERISTIC
	|	,DocumentRows.Batch
	|	,DocumentRows.MeasurementUnit
	|	,DocumentRows.MeasurementUnitByOKEI_Description
	|	,DocumentRows.MeasurementUnitByOKEI_Code
	|	,DocumentRows.Price
	|	,DocumentRows.Amount
	|	,DocumentRows.VATRate
	|	,DocumentRows.VATAmount
	|	,ISNULL(DocumentsAmountsRegulatedAccounting.VAT, DocumentRows.VATAmount * &ExchangeRateDocument / &MultiplicityOfDocument) AS VATAmountInNationalCurrency
	|	,DocumentRows.Total
	|	,ISNULL(DocumentsAmountsRegulatedAccounting.Total, DocumentRows.Total * &ExchangeRateDocument / &MultiplicityOfDocument) AS TotalInNationalCurrency
	|	,DocumentRows.Quantity
	|	,DocumentRows.QuantityByCoefficient
	|	,DocumentRows.Content
	|	,DocumentRows.DiscountMarkupPercent
	|	,DocumentRows.IsDiscount
	|	,DocumentRows.AutomaticDiscountAmount
	|	,DocumentRows.ConnectionKey
	|	,DocumentRows.DocOrder
	|	,DocumentRows.IsSplitter
	|FROM DocumentTabularSection AS DocumentRows
	|	LEFT JOIN InformationRegister.DocumentsAmountsRegulatedAccounting AS DocumentsAmountsRegulatedAccounting
	|	ON DocumentsAmountsRegulatedAccounting.Recorder = &Ref
	|		AND DocumentsAmountsRegulatedAccounting.DocumentTabularSection = &EnumValueDocumentsTabularSections
	|		AND DocumentRows.LineNumber = DocumentsAmountsRegulatedAccounting.DocumentLineNumber
	|ORDER BY LineNumber";
	
	// Наборы
	If DocumentTabularSection.Columns.Find("ProductsAndServicesOfSet")<>Undefined Then
		Query.Text = StrReplace(
		Query.Text,
		"INTO DocumentTabularSection", 
		"	,DocumentTabularSection.ProductsAndServicesOfSet
		|	,DocumentTabularSection.SetCharacteristic
		|	,DocumentTabularSection.ThisIsSet
		|	,DocumentTabularSection.ToAllocateAsSetContent
		|INTO DocumentTabularSection");
		Query.Text = StrReplace(
		Query.Text,
		"FROM DocumentTabularSection AS DocumentRows", 
		" ,DocumentRows.ProductsAndServicesOfSet AS ProductsAndServicesOfSet
		|	,DocumentRows.SetCharacteristic AS SetCharacteristic
		|	,DocumentRows.ThisIsSet AS ThisIsSet
		|	,DocumentRows.ToAllocateAsSetContent AS ToAllocateAsSetContent
		|FROM DocumentTabularSection AS DocumentRows");
	EndIf; 
	// Конец Наборы
	
	Return Query.Execute().Unload();
	
EndFunction

Procedure AddAmountFieldsEquivalentInNationalCurrency(DocumentsData, UsedTS) Export
	
	RecalculationRequired = GetFunctionalOption("CurrencyTransactionsAccounting");
	NationalCurrency = Constants.NationalCurrency.Get();
	
	For Each ObjectData In DocumentsData Do
		
		RecalculationRequired = RecalculationRequired And (NationalCurrency <> ObjectData.DocumentCurrency);
		
		For Each TSDetails In UsedTS Do
			
			QueryOptions = New Structure;
			QueryOptions.Insert("Ref", ObjectData.Ref);
			QueryOptions.Insert("ExchangeRateDocument", ?(RecalculationRequired, ObjectData.ExchangeRate, 1));
			QueryOptions.Insert("MultiplicityOfDocument", ?(RecalculationRequired, ObjectData.Multiplicity, 1));
			
			ObjectData[TSDetails.Key] = AddAmountFields(QueryOptions, ObjectData[TSDetails.Key], TSDetails.Value);
			
		EndDo;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion