#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region PrintInterface

// Procedure forms and displays a printable document form by the specified layout.
//
Function PrintForm(ObjectsArray, PrintObjects, TemplateName)
	
	Var Errors;
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersKey = "PrintParameters_PaymentOrder";
	FirstDocument = True;
	
	For Each CurrentDocument IN ObjectsArray Do
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument = False;
		
		FirstLineNumber = SpreadsheetDocument.TableHeight + 1;
				
		// 1C - CHIENTN - 18/02/2019
		If TemplateName = "PaymentOrder" Then
			
			GeneratePaymentOrder(SpreadsheetDocument, CurrentDocument, TemplateName);			   			
								
		EndIf; 
		// 1C	

		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, FirstLineNumber, PrintObjects, CurrentDocument);
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;

EndFunction // PrintForm()

// Generate printed forms of objects
//
// Incoming:
//   TemplateNames    - String    - Names of layouts separated by commas 
//   ObjectsArray     - Array     - Array of refs to objects that need to be printed
//   PrintParameters  - Structure - Structure of additional printing parameters
//
// Outgoing:
//   PrintFormsCollection - Values table - Generated table documents
//   OutputParameters     - Structure    - Parameters of generated table documents
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	// 1C - CHIENTN - 18/02/2019
	If PrintManagement.NeedToPrintTemplate(PrintFormsCollection, "PaymentOrder") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "PaymentOrder", "Ủy nhiệm chi", PrintForm(ObjectsArray, PrintObjects, "PaymentOrder"));		
	    	
	EndIf;
	// 1C   
	
	// parameters of sending printing forms by email
	SmallBusinessServer.FillSendingParameters(OutputParameters.SendingParameters, ObjectsArray, PrintFormsCollection);


EndProcedure

// Fills in the list of printing commands.
// 
// Parameters:
//   PrintCommands - ValueTable - see fields' content in the PrintManagement.CreatePrintCommandsCollection function.
//
Procedure AddPrintCommands(PrintCommands) Export

	// 1C - CHIENTN - 18/02/2019
	PrintCommand = PrintCommands.Add();
	PrintCommand.ID = "PaymentOrder";
	PrintCommand.Presentation = NStr("en = 'Payment procedure'; ru = 'Платежное Поручение'; vi = 'Ủy nhiệm chi'");
	PrintCommand.FormsList = "DocumentForm,ListForm,DocumentsListForm";
	PrintCommand.CheckPostingBeforePrint = False;
	PrintCommand.Order = 1;	
	// 1C

EndProcedure

// Procedure of generating printed form
// 1C - CHIENTN - 18/02/2019
Procedure GeneratePaymentOrder(SpreadsheetDocument, CurrentDocument, TemplateName)
			
	Query = New Query();
	Query.SetParameter("CurrentDocument", CurrentDocument);
	Query.Text = 
	"SELECT
	|	PaymentOrder.Date AS DocumentDate,
	|	PaymentOrder.Number AS Number,
	|	PaymentOrder.Company AS Company,
	|	PaymentOrder.Company.Prefix AS Prefix,
	|	PaymentOrder.BankAccount AS CompanyBankAccount,
	|	PaymentOrder.BankAccount.AccountNo AS CompanyBankAccountNumber,
	|	PaymentOrder.BankAccount.Bank AS CompanyBank,
	|	REFPRESENTATION(PaymentOrder.BankAccount.Bank) AS CompanyBankPresentation,
	|	PaymentOrder.BankAccount.Bank.PrintFormName AS PrintFormName,
	|	PaymentOrder.BankAccount.Bank.BranchName AS BranchName1,
	|	PaymentOrder.BankAccount.Bank.City AS City1,
	|	PaymentOrder.BankAccount.Bank.Address AS Address1,
	|	PaymentOrder.Counterparty AS Counterparty,
	|	PaymentOrder.CounterpartyAccount AS CounterpartyBankAccount,
	|	PaymentOrder.CounterpartyAccount.AccountNo AS CounterpartyBankAccountNumber,
	|	PaymentOrder.CounterpartyAccount.Bank AS CounterpartyBank,
	|	PaymentOrder.CounterpartyAccount.Bank.BranchName AS BranchName2,
	|	PaymentOrder.CounterpartyAccount.Bank.City AS City2,
	|	PaymentOrder.CounterpartyAccount.Bank.Address AS Address2,
	|	PaymentOrder.DocumentAmount AS Amount,
	|	PaymentOrder.DocumentCurrency AS CashCurrency,
	|	PaymentOrder.Author AS Author,
	|	PaymentOrder.PaymentDestination AS PaymentDestination
	|FROM
	|	Document.PaymentOrder AS PaymentOrder
	|WHERE
	|	PaymentOrder.Ref = &CurrentDocument";  
	
	Results = Query.Execute();
	Selection = Results.Select();
	SpreadsheetDocument.Clear();
	InsertPageBreak = False;
	
	CatalogsBanksMetadata = Metadata.Catalogs.Banks;
		
	While Selection.Next() Do		     
				
		If Not ValueIsFilled(Selection.CompanyBank) Then
			Continue;
		ElsIf Selection.PrintFormName = ""
			Or CatalogsBanksMetadata.Templates.Find(Selection.PrintFormName) = Undefined Then
			
			MessageText = StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en='Document %1 is not printed because the Bank Payment print form for bank %2 is not set. You can set it in ""Bank"" card.';vi='Chưa chọn chứng từ %1 để in, bởi vì chưa thiết lập mẫu in cho ngân hàng %2. Bạn có thể xác định mẫu in trong thẻ Ngân hàng.';ru='Документ %1 не выведен на печать, т.к. печатная форма для банка %2 не установлена. Вы можете задать ее в карточке Банка.'"),
				Selection.Number,
				Selection.CompanyBankPresentation);
			CommonUseClientServer.MessageToUser(MessageText);
			Continue;
		EndIf;

		If InsertPageBreak Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;

		TemplateName = Selection.PrintFormName; 
		Template = Catalogs.Banks.GetTemplate(TemplateName); 
		TemplateArea = Template.GetArea("PaymentOrder");

	
		InfoAboutCompany 		= SmallBusinessServer.InfoAboutLegalEntityIndividual(Selection.Company, Selection.DocumentDate, ,);
		InfoAboutCounterparty 	= SmallBusinessServer.InfoAboutLegalEntityIndividual(Selection.Counterparty, Selection.DocumentDate, ,);
		////ResponsiblePersons 		= SmallBusinessServer.OrganizationalUnitsResponsiblePersons(Selection.Company, Selection.DocumentDate);
				
		FillStructureSection = New Structure();
		FillStructureSection.Insert("Date", 				Format(Selection.DocumentDate, "DF=dd-MM-yyyy"));  
		FillStructureSection.Insert("Company", 				InfoAboutCompany.FullDescr);
		FillStructureSection.Insert("CompanyTelephone", 	InfoAboutCompany.PhoneNumbers);
	 	
		FillStructureSection.Insert("CounterpartyTelephone",InfoAboutCounterparty.PhoneNumbers);
		FillStructureSection.Insert("AmountInWords", 	    WorkWithCurrencyRates.GenerateAmountInWords(Selection.Amount, Selection.CashCurrency));
		
		FillStructureSection.Insert("Address1", 	        Selection.Address1); //Bank Address
		FillStructureSection.Insert("Address2", 	        Selection.Address2); //Counterparty Bank Address
		FillStructureSection.Insert("City1", 	            Selection.City1);
		FillStructureSection.Insert("City2", 	            Selection.City2);
		FillStructureSection.Insert("PaymentDestination",   Selection.PaymentDestination);
		FillStructureSection.Insert("Number",  				Selection.Number);
		
		//DTN 22/11/2019
		FillStructureSection.Insert("CompanyAddress", 		InfoAboutCompany.LegalAddress);
		FillStructureSection.Insert("CounterpartyAddress",	InfoAboutCounterparty.LegalAddress);
		//
			
		TemplateArea.Parameters.Fill(Selection); 
		TemplateArea.Parameters.Fill(FillStructureSection); 
		////TemplateArea.Parameters.Fill(ResponsiblePersons);
		SpreadsheetDocument.Put(TemplateArea);			
		
		If TemplateName = "PaymentOrder_Agribank" Or TemplateName = "PaymentOrder_BIDV" Or TemplateName = "PaymentOrder_PGBank" Or TemplateName = "PaymentOrder_Sacombank" 
			Or TemplateName = "PaymentOrder_Vietinbank" Or TemplateName = "PaymentOrder_TPBank" Then
			SpreadsheetDocument.TopMargin 		= 0;
			SpreadsheetDocument.BottomMargin 	= 0;	
		Else
			SpreadsheetDocument.TopMargin 		= 10;
			SpreadsheetDocument.BottomMargin 	= 10;	
		EndIf;		
		InsertPageBreak = True;

	EndDo;	
		
EndProcedure // GeneratePaymentOrder()
#EndRegion

#EndIf