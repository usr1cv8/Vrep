#If Server OR ThickClientOrdinaryApplication OR ExternalConnection Then

// Function returns the list of key attribute names.
//
Function GetObjectAttributesBeingLocked() Export
	
	Result = New Array;
	Result.Add("SettlementsCurrency");
	
	Return Result;
	
EndFunction // ReceiveLockedObjectAttributes()

// Initializes value tables containing data of the document tabular sections.
// Saves value tables to properties of the "AdditionalProperties" structure.
Procedure InitializeDocumentData(DocumentRefCashReceipt, StructureAdditionalProperties) Export
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.Text =
	"SELECT
	|	LoanContractPaymentAndAccrualSchedule.Ref AS LoanContract,
	|	LoanContractPaymentAndAccrualSchedule.PaymentDate AS Period,
	|	LoanContractPaymentAndAccrualSchedule.Principal,
	|	LoanContractPaymentAndAccrualSchedule.Interest,
	|	LoanContractPaymentAndAccrualSchedule.Commission
	|FROM
	|	Document.LoanContract.PaymentAndAccrualSchedule AS LoanContractPaymentAndAccrualSchedule
	|WHERE
	|	LoanContractPaymentAndAccrualSchedule.Ref = &Ref";
	
	Query.SetParameter("Ref", DocumentRefCashReceipt);
	
	RequestResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableLoanRepaymentSchedule", RequestResult.Unload());
	
EndProcedure // InitializeDocumentData()

// Receives the counterparty contract by default considering filter conditions. Main contract, a single contract, or an empty reference is returned.
//
// The
//  Counterparty	parameters	- 
//							<CatalogRef.Counterparties> Counterparty whose
//  contract	to	be 
//							received Company - <CatalogRef.Companies> Company
//  whose	contract	to be received LoanKindList - <Array> or <ValueList> 
//							consisting of values of the <EnumRef.LoanKinds> type Necessary contract kinds
//
// Returns:
//   <CatalogRef.CounterpartyContracts> - found contract or null reference
//
Function ReceiveLoanContractByDefaultByCompanyLoanKind(Counterparty, Company, LoanKindList = Undefined) Export
	
	If Not ValueIsFilled(Counterparty) Then
		Return Undefined;
	EndIf;
	
	Query = New Query;
	QueryText = 
	"SELECT ALLOWED
	|	LoanContract.Ref
	|FROM
	|	Document.LoanContract AS LoanContract
	|WHERE
	|	LoanContract.Counterparty = &Counterparty
	|	AND LoanContract.Company = &Company
	|	AND LoanContract.Posted"
	+ ?(LoanKindList <> Undefined,"
	|	AND LoanContract.LoanKind IN (&LoanKindList)","");
	
	Query.SetParameter("Counterparty", Counterparty);
	Query.SetParameter("Company", Company);
	Query.SetParameter("LoanKindList", LoanKindList);
	
	If TypeOf(Counterparty) = Type("CatalogRef.Employees") Then
		QueryText = StrReplace(QueryText, 
			"LoanContract.Counterparty = &Counterparty", 
			"LoanContract.Employee = &Counterparty");
	EndIf;
	
	Query.Text = QueryText;
	Result = Query.Execute();
	
	Selection = Result.Select();
	If Selection.Count() = 1 
		AND Selection.Next() Then
			LoanContract = Selection.Ref;
	Else
		LoanContract = Undefined;
	EndIf;
	
	Return LoanContract;
	
EndFunction // ReceiveLoanContractByDefaultByCompanyLoanKind()

#Region ObjectVersioning

// StandardSubsystems.ObjectVersioning

// Defines object settings for the ObjectVersioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure WhenDefiningObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectVersioning

#EndRegion

#Region PrintInterface

// Fills the list of printing commands.
// 
// Parameters:
//   PrintCommands - ValueTable - see field content in the PrintManagement.CreatePrintCommandCollection function.
//
Procedure AddPrintCommands(PrintCommands) Export
		
EndProcedure

#EndRegion

#EndIf
