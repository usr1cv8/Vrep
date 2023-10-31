#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

// Function returns the list of the "key" attributes names.
//
Function GetObjectAttributesBeingLocked() Export
	
	Result = New Array;
	Result.Add("Owner");
	Result.Add("SettlementsCurrency");
	
	Return Result;
	
EndFunction // GetLockedObjectAttributes()

// Receives the counterparty contract by default according to the filter conditions. Default or the only contract returns or an empty reference.
//
// Parameters
//  Counterparty	-	<CatalogRef.Counterparty> 
// 						counterparty, contract of which
//  is	needed	to 
// 						get Company - <CatalogRef.Companies> Company,
//  contract	of	which is needed to get ContractKindsList - <Array> 
// 						or <ValuesList> consisting values of the type <EnumRef.ContractKinds> Desired contract kinds
//
// Returns:
//   <CatalogRef.CounterpartyContracts> - found contract or empty ref
//
Function GetDefaultContractByCompanyContractKind(Counterparty, Company, ContractKindsList = Undefined) Export
	
	CounterpartyMainContract = CommonUse.ObjectAttributeValue(Counterparty, "ContractByDefault");
	
	If Not SmallBusinessReUse.CounterpartyContractsControlNeeded() Then
		
		Return CounterpartyMainContract;
	EndIf;
		
	Query = New Query;
	QueryText = 
	"SELECT ALLOWED
	|	CounterpartyContracts.Ref
	|FROM
	|	Catalog.CounterpartyContracts AS CounterpartyContracts
	|WHERE
	|	CounterpartyContracts.Owner = &Counterparty
	|	AND CounterpartyContracts.Company = &Company
	|	AND CounterpartyContracts.DeletionMark = False"
	+?(ContractKindsList <> Undefined,"
	|	And CounterpartyContracts.ContractKind IN (&ContractKindsList)","");
	
	Query.SetParameter("Counterparty", Counterparty);
	Query.SetParameter("Company", Company);
	Query.SetParameter("ContractKindsList", ContractKindsList);
	
	Query.Text = QueryText;
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		Return Catalogs.CounterpartyContracts.EmptyRef();
	EndIf;
	
	Selection = Result.Select();
	
	Selection.Next();
	Return Selection.Ref;

EndFunction // GetContractOfCounterparty()

// Checks the counterparty contract on the map to passed parameters.
//
// Parameters
// MessageText - <String> - error message
// about	errors	Contract - <CatalogRef.CounterpartyContracts> - checked
// contract	Company	- <CatalogRef.Company> - company
// document	Counterparty	- <CatalogRef.Counterparty> - document
// counterparty	ContractKindsList	- <ValuesList> consisting values of the type <EnumRef.ContractKinds>. 
// 						Desired contract kinds.
//
// Returns:
// <Boolean> -True if checking is completed successfully.
//
Function ContractMeetsDocumentTerms(MessageText, Contract, Company, Counterparty, ContractKindsList) Export
	
	MessageText = "";
	
	If Not Counterparty.DoOperationsByContracts Then
		Return True;
	EndIf;
	
	DoesNotMatchCompany = False;
	DoesNotMatchContractKind = False;
	
	If Contract.Company <> Company Then
		DoesNotMatchCompany = True;
	EndIf;
	
	If Not TypeOf(Contract) = Type("CatalogRef.CounterpartyContracts") Then
		Return True;
	EndIf;
	
	If ContractKindsList.FindByValue(Contract.ContractKind) = Undefined Then
		DoesNotMatchContractKind = True;
	EndIf;
	
	If (DoesNotMatchCompany OR DoesNotMatchContractKind) = False Then
		Return True;
	EndIf;
	
	MessageText = NStr("en='Contract attributes do not comply with the document conditions:';ru='Реквизиты договора не соответствуют условиям документа:';vi='Mục tin hợp đồng không tương ứng với điều kiện chứng từ:'");
	
	If DoesNotMatchCompany Then
		MessageText = MessageText + NStr("en='"
" - The company does not match';ru='"
" - Не совпадает организация';vi='"
" - Không trùng doanh nghiệp'");
	EndIf;
	
	If DoesNotMatchContractKind Then
		MessageText = MessageText + NStr("en='"
" - Contract kind does not match';ru='"
" - Не совпадает вид договора';vi='"
" - Không trùng với dạng hợp đồng'");
	EndIf;
	
	Return False;
	
EndFunction // ContractMeetsDocumentTerms()

// Returns a list of available contract kinds for the document.
//
// Parameters
// Document  - any document providing counterparty
// contract OperationKind  - document operation kind.
//
// Returns:
// <ValuesList>   - list of contract kinds which are available for the document.
//
Function GetContractKindsListForDocument(Document, OperationKind = Undefined, TabularSectionName = "") Export
	
	ContractKindsList = New ValueList;
	
	If TypeOf(Document) = Type("DocumentRef.AcceptanceCertificate") Then
		
		ContractKindsList.Add(Enums.ContractKinds.WithCustomer);
		
	ElsIf TypeOf(Document) = Type("DocumentRef.EnterOpeningBalance") Then
		
		If TabularSectionName = "InventoryTransferred" Then
			
			If OperationKind = Enums.OperationKindsCustomerInvoice.TransferForCommission Then
				ContractKindsList.Add(Enums.ContractKinds.WithAgent);
			Else
				ContractKindsList.Add(Enums.ContractKinds.WithVendor);
			EndIf;
			
		ElsIf TabularSectionName = "InventoryReceived" Then
			
			If OperationKind = Enums.OperationKindsSupplierInvoice.ReceptionForCommission Then
				ContractKindsList.Add(Enums.ContractKinds.FromPrincipal);
			Else
				ContractKindsList.Add(Enums.ContractKinds.WithCustomer);
			EndIf;
			
		ElsIf TabularSectionName = "AccountsPayable" Then
			
			ContractKindsList.Add(Enums.ContractKinds.WithVendor);
			ContractKindsList.Add(Enums.ContractKinds.FromPrincipal);
			
		ElsIf TabularSectionName = "AccountsReceivable" Then
			
			ContractKindsList.Add(Enums.ContractKinds.WithCustomer);
			ContractKindsList.Add(Enums.ContractKinds.WithAgent);
			
		EndIf;
		
	ElsIf TypeOf(Document) = Type("DocumentRef.Netting") Then
		
		If TabularSectionName = "Debitor" Then
			ContractKindsList.Add(Enums.ContractKinds.WithCustomer);
			ContractKindsList.Add(Enums.ContractKinds.WithAgent);
		ElsIf TabularSectionName = "Creditor" Then
			ContractKindsList.Add(Enums.ContractKinds.WithVendor);
			ContractKindsList.Add(Enums.ContractKinds.FromPrincipal);
		Else
			If OperationKind = Enums.OperationKindsNetting.CustomerDebtAssignment Then
				ContractKindsList.Add(Enums.ContractKinds.WithCustomer);
				ContractKindsList.Add(Enums.ContractKinds.WithAgent);
			Else
				ContractKindsList.Add(Enums.ContractKinds.WithVendor);
				ContractKindsList.Add(Enums.ContractKinds.FromPrincipal);
			EndIf;
		EndIf;
		
	ElsIf TypeOf(Document) = Type("DocumentRef.PowerOfAttorney") Then
		
		ContractKindsList.Add(Enums.ContractKinds.WithVendor);
		ContractKindsList.Add(Enums.ContractKinds.FromPrincipal);
		
	ElsIf TypeOf(Document) = Type("DocumentRef.AdditionalCosts") Then
		
		ContractKindsList.Add(Enums.ContractKinds.WithVendor);
		ContractKindsList.Add(Enums.ContractKinds.FromPrincipal);
		
	ElsIf TypeOf(Document) = Type("DocumentRef.CustomerOrder") Then
		
		If OperationKind = Enums.OperationKindsCustomerOrder.OrderForSale Then
			ContractKindsList.Add(Enums.ContractKinds.WithCustomer);
			ContractKindsList.Add(Enums.ContractKinds.WithAgent);
		Else
			ContractKindsList.Add(Enums.ContractKinds.WithCustomer);
		EndIf;
		
	ElsIf TypeOf(Document) = Type("DocumentRef.PurchaseOrder") Then
		
		If OperationKind = Enums.OperationKindsPurchaseOrder.OrderForPurchase Then
			ContractKindsList.Add(Enums.ContractKinds.WithVendor);
			ContractKindsList.Add(Enums.ContractKinds.FromPrincipal);
		Else
			ContractKindsList.Add(Enums.ContractKinds.WithVendor);
		EndIf;
		
	ElsIf TypeOf(Document) = Type("DocumentRef.AgentReport") Then
		
		ContractKindsList.Add(Enums.ContractKinds.WithAgent);
		
	ElsIf TypeOf(Document) = Type("DocumentRef.ReportToPrincipal") Then
		
		ContractKindsList.Add(Enums.ContractKinds.FromPrincipal);
		
	ElsIf TypeOf(Document) = Type("DocumentRef.ProcessingReport") Then
		
		ContractKindsList.Add(Enums.ContractKinds.WithCustomer);
		
	ElsIf TypeOf(Document) = Type("DocumentRef.SubcontractorReport") Then
		
		ContractKindsList.Add(Enums.ContractKinds.WithVendor);
		
	ElsIf TypeOf(Document) = Type("DocumentRef.CashReceipt") 
		OR TypeOf(Document) = Type("DocumentRef.PaymentReceipt") Then
		
		If OperationKind = Enums.OperationKindsCashReceipt.FromVendor
			OR OperationKind = Enums.OperationKindsPaymentReceipt.FromVendor Then
			ContractKindsList.Add(Enums.ContractKinds.WithVendor);
			ContractKindsList.Add(Enums.ContractKinds.WithAgent);
			ContractKindsList.Add(Enums.ContractKinds.FromPrincipal);
		Else
			ContractKindsList.Add(Enums.ContractKinds.WithCustomer);
			ContractKindsList.Add(Enums.ContractKinds.WithAgent);
			ContractKindsList.Add(Enums.ContractKinds.FromPrincipal);
		EndIf;
		
	ElsIf TypeOf(Document) = Type("DocumentRef.SupplierInvoice") Then
		
		If OperationKind = Enums.OperationKindsSupplierInvoice.ReceptionForCommission Then
			ContractKindsList.Add(Enums.ContractKinds.FromPrincipal);
		ElsIf OperationKind = Enums.OperationKindsSupplierInvoice.ReturnFromAgent Then
			ContractKindsList.Add(Enums.ContractKinds.WithAgent);
		ElsIf OperationKind = Enums.OperationKindsSupplierInvoice.ReceptionIntoProcessing
			OR OperationKind = Enums.OperationKindsSupplierInvoice.ReceptionForSafeCustody
			OR OperationKind = Enums.OperationKindsSupplierInvoice.ReturnFromCustomer Then
			ContractKindsList.Add(Enums.ContractKinds.WithCustomer);
		Else 
			ContractKindsList.Add(Enums.ContractKinds.WithVendor);
		EndIf;
		
	ElsIf TypeOf(Document) = Type("DocumentRef.CashPayment") 
		OR TypeOf(Document) = Type("DocumentRef.PaymentExpense") Then
		
		If OperationKind = Enums.OperationKindsCashPayment.Vendor 
			OR OperationKind = Enums.OperationKindsPaymentExpense.Vendor Then
			ContractKindsList.Add(Enums.ContractKinds.WithVendor);
			ContractKindsList.Add(Enums.ContractKinds.WithAgent);
			ContractKindsList.Add(Enums.ContractKinds.FromPrincipal);
		Else
			ContractKindsList.Add(Enums.ContractKinds.WithCustomer);
			ContractKindsList.Add(Enums.ContractKinds.WithAgent);
			ContractKindsList.Add(Enums.ContractKinds.FromPrincipal);
		EndIf;
		
	ElsIf TypeOf(Document) = Type("DocumentRef.CustomerInvoice") Then
		
		If OperationKind = Enums.OperationKindsCustomerInvoice.TransferForCommission Then
			ContractKindsList.Add(Enums.ContractKinds.WithAgent);
		ElsIf OperationKind = Enums.OperationKindsCustomerInvoice.ReturnToPrincipal Then
			ContractKindsList.Add(Enums.ContractKinds.FromPrincipal);
		ElsIf OperationKind = Enums.OperationKindsCustomerInvoice.TransferToProcessing
			OR OperationKind = Enums.OperationKindsCustomerInvoice.TransferForSafeCustody
			OR OperationKind = Enums.OperationKindsCustomerInvoice.ReturnToVendor Then
			ContractKindsList.Add(Enums.ContractKinds.WithVendor);
		Else 
			ContractKindsList.Add(Enums.ContractKinds.WithCustomer);
		EndIf;
		
	ElsIf TypeOf(Document) = Type("DocumentRef.ExpensesOnImport") Then
		
		ContractKindsList.Add(Enums.ContractKinds.Other);
		
	ElsIf TypeOf(Document) = Type("DocumentRef.InvoiceForPayment") Then
		
		ContractKindsList.Add(Enums.ContractKinds.WithCustomer);
		ContractKindsList.Add(Enums.ContractKinds.WithAgent);
		ContractKindsList.Add(Enums.ContractKinds.FromPrincipal);
		
	ElsIf TypeOf(Document) = Type("DocumentRef.SupplierInvoiceForPayment") Then
		
		ContractKindsList.Add(Enums.ContractKinds.WithVendor);
		ContractKindsList.Add(Enums.ContractKinds.WithAgent);
		ContractKindsList.Add(Enums.ContractKinds.FromPrincipal);
		
	EndIf;
	
	Return ContractKindsList;
	
EndFunction // GetContractKindsListForDocument()

Function ContractByDefault(Counterparty) Export
	
	If ТипЗнч(Counterparty) = Тип("CatalogObject.Counterparties") Then
		CounterpartyRef = Counterparty.Ref;
	Else
		CounterpartyRef = Counterparty;
	EndIf;
	
	Contract = CommonUse.GetAttributeValue(CounterpartyRef, "ContractByDefault");
	
	Return Contract;
	
EndFunction

// Проверяет, имеются ли в базе договоры обслуживания.
// 
// Returns:
//   - Boolean
//
Function HasServiceContracts() Export
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED TOP 1
	|	CounterpartyContracts.Ref AS Ref
	|FROM
	|	Catalog.CounterpartyContracts AS CounterpartyContracts
	|WHERE
	|	CounterpartyContracts.IsServiceContract";
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// Проверяет, имеются ли в базе договоры обслуживания с заполненным направлением деятельности.
// 
// Returns:
//   - Boolean
//
Function HasServiceContractsWithUniqueBusinessActivities() Export
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED TOP 1
	|	CounterpartyContracts.Ref AS Ref
	|FROM
	|	Catalog.CounterpartyContracts AS CounterpartyContracts
	|WHERE
	|	CounterpartyContracts.IsServiceContract
	|	AND CounterpartyContracts.ServiceContractBusinessActivity <> VALUE(Catalog.BusinessActivities.EmptyRef)";
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// Создает связанное с договором обслуживания направление деятельности.
//
// Parameters:
//  Counterparty - CatalogRef.Counterparties - Владелец договора.
//  Contract    - String, CatalogRef.CounterpartyContracts - Договор контрагента.
// 
// Returns:
//   - CatalogRef.BusinessActivities
//
Function CreateBusinessActivityForServiceContract(Counterparty, Contract) Export
	
	Description = "" + Counterparty + ": " + Contract;
	BusinessActivity = Catalogs.BusinessActivities.CreateItem();
	BusinessActivity.Fill(Undefined);
	BusinessActivity.Description = Description;
	BusinessActivity.Parent = Constants.BillingHeadBusinessActivity.Get();
	BusinessActivity.Write();
	
	Return BusinessActivity.Ref;
	
EndFunction

// Переименовывает направление деятельности, созданное для договора обслуживания (вызывается при переименовании договора контрагента).
//
Function RenameBusinessActivityForServiceContract(BusinessActivity, Counterparty, ContractDescription, ContractOldDescription) Export
	
	OldDescription = "" + Counterparty + ": " + ContractOldDescription;
	NewDescription = "" + Counterparty + ": " + ContractDescription;
	
	If OldDescription = NewDescription Then
		// Название не изменилось.
		Return False;
	EndIf;
	
	If Left(BusinessActivity.Description, 50) <> Left(OldDescription, 50) Then
		// Название изменено пользователем.
		Return False;
	EndIf;
	
	BusinessActivityObject = BusinessActivity.GetObject();
	BusinessActivityObject.Description = NewDescription;
	BusinessActivityObject.Write();
	
	Return True;
	
EndFunction

// Checks the match of the "Company" and "ContractKind" contract attributes to the terms of the document.
//
Procedure CheckContractToDocumentConditionAccordance(
	MessageText,
	Contract = Undefined,
	DocumentCatalog,
	Company,
	Counterparty,
	cancel,
	OperationKind = Undefined,
	Val TSPaymentDetails = Undefined,
	CreditLoanContract = Undefined) Export
	
	//ContractsControl = GetFunctionalOption("ContractsControl");
	If Not Counterparty.DoOperationsByContracts
		Or OperationKind = Enums.OperationKindsPaymentReceipt.Other
		Or OperationKind = Enums.OperationKindsCashReceipt.Other
		Or OperationKind = Enums.OperationKindsCashPayment.Other
		Or OperationKind = Enums.OperationKindsPaymentExpense.Other Then
		
		Return;
	EndIf;
	
	ManagerOfCatalog = Catalogs.CounterpartyContracts;
	If TypeOf(DocumentCatalog) = Type("CatalogRef.POSTerminals") Then
		ContractKindsList = New ValueList;
		ContractKindsList.Add(Enums.ContractKinds.Other);
	Else
		ContractKindsList = ManagerOfCatalog.GetContractKindsListForDocument(DocumentCatalog, OperationKind);
	EndIf;
	
	//DontPostWithIncorrectContracts = (ContractsControl = Enums.ContractsControlKindsOnPosting.DontConduct);
	
	If TSPaymentDetails = Undefined Then
		If Not ManagerOfCatalog.ContractMeetsDocumentTerms(MessageText, Contract, Company, Counterparty, ContractKindsList)
			 Then
			
			cancel = True;
		EndIf;
	Else
		//// Прочие расчеты
		//If OperationKind = Enums.OperationKindsCashReceipt.SettlementsByCredits
		//	Or OperationKind = Enums.OperationKindsPaymentReceipt.SettlementsByCredits
		//	Or OperationKind = Enums.OperationKindsCashPayment.SettlementsByCredits
		//	Or OperationKind = Enums.OperationKindsPaymentExpense.SettlementsByCredits Then
		//	
		//	ContractKindsList = New ValueList;
		//	ContractKindsList.Add(Enums.CreditAndLoanAgreementsTypes.CreditReceived);
		//	
		//	If Not ManagerOfCatalog.ContractMeetsDocumentTerms(MessageText, CreditLoanContract, Company, Counterparty, ContractKindsList)
		//		 Then
		//		
		//		cancel = True;
		//		
		//	EndIf;
		//	
		//Else
		// Конец Прочие расчеты
			For Each TabularSectionRow In TSPaymentDetails Do
				
				If Not ManagerOfCatalog.ContractMeetsDocumentTerms(MessageText, TabularSectionRow.Contract, Company, Counterparty, ContractKindsList)
					 Then
					
					cancel = True;
					Break;
					
				EndIf;
				
			EndDo;
		//EndIf;
	EndIf;
	
EndProcedure

#Region PrintInterface

// Fills in Customer order printing commands list
// 
// Parameters:
//   PrintCommands - ValueTable - see fields' content in the PrintManagement.CreatePrintCommandsCollection function.
//
Procedure AddPrintCommands(PrintCommands) Export
	
	// Contract
	PrintCommand = PrintCommands.Add();
	PrintCommand.Handler = "SmallBusinessClient.PrintCounterpartyContract";
	PrintCommand.ID = "ContractForm";
	PrintCommand.Presentation = NStr("en='Contract form';ru='Бланк договора';vi='Mẫu hợp đồng'");
	PrintCommand.FormsList = "ItemForm,ListForm,ChoiceForm,ChoiceFormWithCounterparty";
	PrintCommand.Order = 1;
		
	If IsInRole("FullRights") Or IsInRole("AddChangeBillingSubsystem") Then
		PrintCommand = PrintCommands.Add();
		PrintCommand.ID = "ServiceContractTariffPlan";
		PrintCommand.Presentation = NStr("en='Tariff plan';ru='Тарифный план';vi='Dịch vụ định kỳ'");
		PrintCommand.FormsList = "ItemForm,ListForm,ChoiceForm,ChoiceFormWithCounterparty";
		PrintCommand.FunctionalOptions = "UseBilling";
		PrintCommand.Order = 2;
	EndIf;

EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.NeedToPrintTemplate(PrintFormsCollection, "ServiceContractTariffPlan") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"ServiceContractTariffPlan",
			"Tariff plan",
			PrintServiceContractTariffPlan(ObjectsArray, PrintObjects, "ServiceContractTariffPlan"));
	EndIf;
	
EndProcedure

Function PrintServiceContractTariffPlan(ObjectsArray, PrintObjects, TemplateName) Export
	
	Var Errors;
	
	SpreadsheetDocument = New SpreadsheetDocument;
	
	QueryText = "";
	QueryUnion = "
	|
	|UNION
	|";
	
	For Each Item In ObjectsArray Do
		
		If Item.IsServiceContract Then
			Continue;
		EndIf;
		
		MessageText = StrTemplate(
			NStr("en='Contract %1 is not the service contract!';ru='Договор %1 не является договором обслуживания!';vi='Hợp đồng %1 không phải là hợp đồng dịch vụ!'"),
			Item.Ref
		);
		CommonUseClientServer.AddUserError(Errors, , MessageText, Undefined);
		
	EndDo;
	
	For Iterator = 0 To ObjectsArray.Count() - 1 Do
		
		If ValueIsFilled(QueryText) Then
			QueryText = QueryText + QueryUnion;
		EndIf;
		
		QueryText = QueryText + "
		|SELECT
		|	CounterpartyContracts.Ref AS Contract,
		|	CounterpartyContracts.ContractDate AS ContractDate,
		|	CounterpartyContracts.ContractNo AS ContractNo,
		|	CounterpartyContracts.ServiceContractTariffPlan AS TariffPlan,
		|	ServiceContractsTariffPlansProductsAndServicesAccounting.LineNumber AS LineNumber,
		|	ServiceContractsTariffPlansProductsAndServicesAccounting.ProductsAndServices AS ProductsAndServices,
		|	ServiceContractsTariffPlansProductsAndServicesAccounting.CHARACTERISTIC AS CHARACTERISTIC,
		|	ServiceContractsTariffPlansProductsAndServicesAccounting.MeasurementUnit AS MeasurementUnit,
		|	ServiceContractsTariffPlansProductsAndServicesAccounting.Quantity AS Quantity,
		|	ServiceContractsTariffPlansProductsAndServicesAccounting.Price AS Price
		|FROM
		|	Catalog.ServiceContractsTariffPlans.ProductsAndServicesAccounting AS ServiceContractsTariffPlansProductsAndServicesAccounting,
		|	Catalog.CounterpartyContracts AS CounterpartyContracts
		|WHERE
		|	ServiceContractsTariffPlansProductsAndServicesAccounting.Ref = &TariffPlan%1
		|	AND ServiceContractsTariffPlansProductsAndServicesAccounting.PricingMethod = VALUE(Enum.BillingProductsAndServicesPricingMethod.FixedValue)
		|	AND CounterpartyContracts.Ref = &CounterpartyContract%1
		|
		|UNION
		|
		|SELECT
		|	CounterpartyContracts.Ref AS Contract,
		|	CounterpartyContracts.ContractDate AS ContractDate,
		|	CounterpartyContracts.ContractNo AS ContractNo,
		|	CounterpartyContracts.ServiceContractTariffPlan,
		|	ServiceContractsTariffPlansProductsAndServicesAccounting.LineNumber,
		|	ServiceContractsTariffPlansProductsAndServicesAccounting.ProductsAndServices,
		|	ServiceContractsTariffPlansProductsAndServicesAccounting.CHARACTERISTIC,
		|	ServiceContractsTariffPlansProductsAndServicesAccounting.MeasurementUnit,
		|	ServiceContractsTariffPlansProductsAndServicesAccounting.Quantity,
		|	ЕСТЬNULL(ProductsAndServicesPricesSliceLast.Price, 0) AS Price
		|FROM
		|	Catalog.ServiceContractsTariffPlans.ProductsAndServicesAccounting AS ServiceContractsTariffPlansProductsAndServicesAccounting
		|		LEFT JOIN InformationRegister.ProductsAndServicesPrices.SliceLast(&ContractConclusionDate%1, PriceKind = &PriceKind%1) AS ProductsAndServicesPricesSliceLast
		|		ON ServiceContractsTariffPlansProductsAndServicesAccounting.ProductsAndServices = ProductsAndServicesPricesSliceLast.ProductsAndServices
		|			AND ServiceContractsTariffPlansProductsAndServicesAccounting.CHARACTERISTIC = ProductsAndServicesPricesSliceLast.CHARACTERISTIC,
		|	Catalog.CounterpartyContracts AS CounterpartyContracts
		|WHERE
		|	ServiceContractsTariffPlansProductsAndServicesAccounting.Ref = &TariffPlan%1
		|	AND ServiceContractsTariffPlansProductsAndServicesAccounting.PricingMethod = VALUE(Enum.BillingProductsAndServicesPricingMethod.ByContractPriceKind)
		|	AND CounterpartyContracts.Ref = &CounterpartyContract%1";
		
		QueryText = StrTemplate(QueryText, Iterator);
		
	EndDo;
	
	QueryText = QueryText + "
	|ORDER BY
	|	CounterpartyContracts.ServiceContractTariffPlan,
	|	LineNumber
	|TOTALS BY
	|	Contract";
	
	Query = New Query();
	Query.Text = QueryText;
	
	For Iterator = 0 To ObjectsArray.Count() - 1 Do
		
		Parameter = "TariffPlan" + Iterator;
		Query.SetParameter(Parameter, ObjectsArray[Iterator].ServiceContractTariffPlan);
		
		Parameter = "ContractConclusionDate" + Iterator;
		Query.SetParameter(Parameter, ObjectsArray[Iterator].ServiceContractStartDate);
		
		Parameter = "PriceKind" + Iterator;
		Query.SetParameter(Parameter, ObjectsArray[Iterator].PriceKind);
		
		Parameter = "CounterpartyContract" + Iterator;
		Query.SetParameter(Parameter, ObjectsArray[Iterator].Ref);
		
	EndDo;
	
	SpreadsheetDocument = New SpreadsheetDocument;
	FirstDocument = True;
	
	SELECTION = Query.Execute().Select(QueryResultIteration.ByGroupsWithHierarchy);
	While SELECTION.Next() Do
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		FirstDocument = False;
		
		FirstLineNumber = SpreadsheetDocument.TableHeight + 1;
		
		SpreadsheetDocument.PrintParametersName = "PRINT_PARAMETERS_" + TemplateName + "_" + TemplateName;
		
		Template = PrintManagement.PrintedFormsTemplate("Catalog.CounterpartyContracts.PF_MXL_" + TemplateName);
		
		TemplateArea = Template.GetArea("Title");
		TemplateArea.Parameters.TitleText = NStr("en='k contract № ';vi='cho hợp đồng số ';")
												+ SELECTION.ContractNo
												+ NStr("en=' FROM ';vi=' NGÀY ';")
												+ Format(SELECTION.ContractDate, "DLF=DD");
												
		SpreadsheetDocument.Put(TemplateArea);
		
		If Template.Areas.Find("TariffPlan") <> Undefined Then
			
			TemplateArea = Template.GetArea("TariffPlan");
			
		EndIf;
		TemplateArea.Parameters.Fill(SELECTION);
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("TableHeader");
		SpreadsheetDocument.Put(TemplateArea);
		
		SelectionOfTariffPlanLines = SELECTION.Select();
		
		TemplateArea = Template.GetArea("TableRow");
		
		Amount = 0;
		Quantity = 0;
		
		While SelectionOfTariffPlanLines.Next() Do
			
			Quantity = Quantity + 1;
			TemplateArea.Parameters.Fill(SelectionOfTariffPlanLines);
			TemplateArea.Parameters.ProductsAndServices = SmallBusinessServer.GetProductsAndServicesPresentationForPrinting(
				SelectionOfTariffPlanLines.ProductsAndServices,
				SelectionOfTariffPlanLines.CHARACTERISTIC
			);
			TemplateArea.Parameters.LineNumber = Quantity;
			
			SpreadsheetDocument.Put(TemplateArea);
			
			Amount = Amount + SelectionOfTariffPlanLines.Quantity * SelectionOfTariffPlanLines.Price;
			
		EndDo;
		
		TemplateArea = Template.GetArea("TotalSum");
		TemplateArea.Parameters.Amount = SmallBusinessServer.AmountsFormat(Amount);
		SpreadsheetDocument.Put(TemplateArea);
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, FirstLineNumber, PrintObjects, SELECTION.TariffPlan);
		
	EndDo;
	
	CommonUseClientServer.ShowErrorsToUser(Errors);
	
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;
	
EndFunction // ПечатьTariffPlanДоговораОбслуживания()

#EndRegion


#EndIf