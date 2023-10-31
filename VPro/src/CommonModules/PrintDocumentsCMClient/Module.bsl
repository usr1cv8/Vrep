
#Region InternalProceduresAndFunctions

Procedure UpdatePrintAttributesValues(CurrentObject, ChangedAttributes) Export
	
	If CurrentObject.ReadOnly Then
		
		Return;
		
	EndIf;
	
	For Each StructureItem In ChangedAttributes Do
		
		CurrentObject.Object[StructureItem.Key] = StructureItem.Value;
		
		If Not CurrentObject.Modified Then
			
			CurrentObject.Modified = True;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function SuggestFillCompanyAttributes(PrintParameters) Export
	
	OpenAttributesFillingFormForPrint(PrintParameters, "ManagerSignature,ChiefAccountantSignature,TIN,KPP,BankAccountByDefault,LogoFile,LegAddress");
	
EndFunction

Function OfferFillCompanyAttributesWithFacsimileSignature(PrintParameters) Export
	
	OpenAttributesFillingFormForPrint(PrintParameters, "ManagerSignature,ChiefAccountantSignature,TIN,KPP,BankAccountByDefault,LogoFile,LegAddress,FileFacsimilePrinting");
	
EndFunction

Procedure OpenAttributesFillingFormForPrint(PrintParameters, AttributesNamesToFill)
	
	FormParameters = New Structure;
	FormParameters.Insert("PrintManagerName", PrintParameters.PrintManager);
	FormParameters.Insert("TemplateNames", PrintParameters.ID);
	FormParameters.Insert("CommandParameter", PrintParameters.PrintObjects);
	FormParameters.Insert("AttributesNamesToFill", AttributesNamesToFill);
	FormParameters.Insert("PrintParameters", New Structure);
	For Each KeyAndValue In PrintParameters Do
		If TypeOf(KeyAndValue.Value) = Type("ClientApplicationForm") Then
			Continue;
		EndIf;
		FormParameters.PrintParameters.Insert(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	FormParameters.Insert(
	"Key",
	SmallBusinessServer.CompanyFromCommandParameter(FormParameters.CommandParameter));
	
	If ValueIsFilled(FormParameters.Key) Then
		
		AttributesFillingFormForPrinting = OpenForm(
		"Catalog.Companies.Form.AttributesFillingFormForPrinting",
		FormParameters,
		String(New UUID));
		
		If AttributesFillingFormForPrinting <> Undefined Then
			Return;
		EndIf;
		
	EndIf;
	
	PrintManagementClient.ExecutePrintCommand(
	FormParameters.PrintManagerName,
	FormParameters.TemplateNames,
	FormParameters.CommandParameter,
	PrintParameters.Form,
	FormParameters);
	
EndProcedure

Procedure PrintPriceTagsAndLabelsPrintingCommandOnLabelPrinter(PrintParameters) Export
	
	DataProcessor = PrintParameters.PrintObjects[0];
	
	If DataProcessor.Goods.FindRows(New Structure("Selected", True)).Count() = 0 Then
		ShowMessageBox(, NStr("en='Не выбрано ни одного товара';ru='Не выбрано ни одного товара';vi='Chưa chọn hàng hóa nào'"));
		Return;
	EndIf;
	
	If PrintParameters.Property("FormID") Then
		FormID = PrintParameters.FormID;
	Else
		FormID = PrintParameters.Form.UUID;
	EndIf;
	
	DataForLabelsPrinter = CompanyManagementServerCall.PrepareLabelPrinterPriceTagsAndLabelDataStructure(DataProcessor, PrintParameters.PrintManager, PrintParameters.CurrentSize);
	
	If DataForLabelsPrinter.Count() > 0 Then
		
		For Each CurTemplate In DataForLabelsPrinter Do
			
			PrintCompletion = New NotifyDescription("ProcessPrintPriceTagsAndLabelsOnPrinterLabelsCompletion", PrintDocumentsCMClient, CurTemplate);
			
			EquipmentManagerClient.StartLabelsPrinting(PrintCompletion, FormID, CurTemplate.XML, CurTemplate.Labels);
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure ProcessPrintPriceTagsAndLabelsOnPrinterLabelsCompletion(ExecutionResult, Parameters) Export
	
	If ExecutionResult.Result Then
		
		Return;
		
	Else
		
		MessageText = NStr("en='При печати произошла ошибка."
"Дополнительное описание:"
"%AdditionalDetails%';ru='При печати произошла ошибка."
"Дополнительное описание:"
"%AdditionalDetails%';vi='Đã xảy ra lỗi khi in."
"Mô tả bổ sung:"
"%AdditionalDetails%'"
		);
		MessageText = StrReplace(
			MessageText,
			"%AdditionalDetails%",
			ExecutionResult.ErrorDescription
		);
		
		CommonUseClientServer.MessageToUser(MessageText);
		
	EndIf;
	
EndProcedure

#Region ClientPrintMethods

Function ContactInformationPrinting(PrintParameters) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("CounterpartiesInitialValue", PrintParameters.PrintObjects);
	
	If PrintParameters.PrintObjects.Count() > 0 Then
		UniqueKey = PrintParameters.PrintObjects[0];
	Else
		UniqueKey = False;
	EndIf;
	
	OpenForm("Catalog.Counterparties.Form.ContactInformationForm", FormParameters, , UniqueKey);
	
EndFunction

Function EnvelopePrint(CommandDetails) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("PrintObjects", CommandDetails.PrintObjects);
	
	OpenForm("DataProcessor.EnvelopesPrint.Form", FormParameters);
	
EndFunction

#EndRegion

#Region OnChangeFormAttributes

Procedure OnChangeCounterpartyContract(ContractAfterChange, PrintBasisRef, StampBase, AdditionalParameters = Undefined) Export
	
	FillPrintBasisByContract = True;
	AddWordContractInPrintBasisContractPresentation = True;
	If TypeOf(AdditionalParameters) = Type("Structure") Then
		
		ConstantValue = Undefined;
		If AdditionalParameters.Property("PrintBasisInvoiceForPayment", ConstantValue) Then
			
			FillPrintBasisByContract = (ConstantValue = PredefinedValue("Enum.PrintBasisInitialFillingMethod.CounterpartyContract"));
			
		EndIf;
		
		If AdditionalParameters.Property("PrintBasisCustomerOrder", ConstantValue) Then
			
			FillPrintBasisByContract = (ConstantValue = PredefinedValue("Enum.PrintBasisInitialFillingMethod.CounterpartyContract"));
			
		EndIf;
		
		AdditionalParameters.Property("AddWordContractInPrintBasisContractPresentation", AddWordContractInPrintBasisContractPresentation);
		AddWordContractInPrintBasisContractPresentation = (AddWordContractInPrintBasisContractPresentation = Undefined Or AddWordContractInPrintBasisContractPresentation = True);
		
	EndIf;
	
	If FillPrintBasisByContract Then
		
		If Not ValueIsFilled(ContractAfterChange) Then
			
			If Not ValueIsFilled(PrintBasisRef)
				Or TypeOf(PrintBasisRef) = Type("CatalogRef.CounterpartyContracts") Then
				
				PrintBasisRef = Undefined;
				StampBase = "";
				
			EndIf;
			
		ElsIf ValueIsFilled(ContractAfterChange) Then
			
			If Not ValueIsFilled(PrintBasisRef)
				Or TypeOf(PrintBasisRef) = Type("CatalogRef.CounterpartyContracts") Then
			
				PrintBasisRef = ContractAfterChange;
				
				PresentationTitle = "";
				If AddWordContractInPrintBasisContractPresentation Then
					
					PresentationTitle = NStr("en='Договор: ';ru='Договор: ';vi='Hợp đồng:'");
					
				EndIf;
				
				StampBase = PresentationTitle + String(ContractAfterChange);
			
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion