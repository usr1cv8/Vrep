
#Region ProgramInterface

// Возвращает представление расчетов по контрагенту в формате "Должен нам/Мы должны"
//
// Parameters:
//  Counterparty - СправочникСсылка.Контрагент
//  DebtAmount - Number
// 
// Returns:
//  String
//
Function TitleOfSettlementsLabel(Counterparty, DebtAmount = 0) Export
	
	LargeFont = New Font(,11,,,);
	SmallFont  = New Font(,8, ,,);
	
	Query = New Query;
	Query.SetParameter("Counterparty", Counterparty);
	Query.Text = 
	"SELECT ALLOWED
	|	SettlementsBalances.Amount AS Amount
	|FROM
	|	InformationRegister.SettlementsBalances AS SettlementsBalances
	|WHERE
	|	SettlementsBalances.Counterparty = &Counterparty";
	
	SELECTION = Query.Execute().Select();
	If SELECTION.Next() Then
		Amount = SELECTION.Amount;
	Else
		Amount = 0;
	EndIf;
	
	DebtAmount = Amount;
	
	FSComponents = New Array;
	If Amount < 0 Then
		FSComponents.Add(New FormattedString(NStr("en='We owned';ru='Мы должны';vi='Chúng ta nên'") + " ", LargeFont));
		Amount = -Amount;
	Else
		FSComponents.Add(New FormattedString(NStr("en='Owes us';ru='Должен нам';vi='Chúng tôi cần'") + " ", LargeFont));
	EndIf;
	
	AmountString = Format(Amount, "NFD=2; NDS=,; NGS=' '; NZ=0,00");
	SeparatorPosition = StrFind(AmountString, ",");
	ComponentsNumbers = New Array;
	ComponentsNumbers.Add(New FormattedString(Left(AmountString, SeparatorPosition), LargeFont));
	ComponentsNumbers.Add(New FormattedString(Mid(AmountString, SeparatorPosition+1), SmallFont));
	FSComponents.Add(New FormattedString(ComponentsNumbers, , , , "MutualSettlements"));
	
	FSComponents.Add(" " + Constants.AccountingCurrency.Get().Description);
	
	Return New FormattedString(FSComponents, , StyleColors.MinorInscriptionText);
	
EndFunction

// Получает договор по умолчанию в зависимости от способа ведения расчетов
//
// Parameters:
//  Document - DocumentRef
//  Counterparty - CatalogRef.Counterparties
//  Company - СправочникСсылка.Организация
//
// Returns:
//  СправочникСсылка.Договор
//
Function GetContractByDefault(Document, Counterparty, Company) Export
	
	If Not Counterparty.DoOperationsByContracts Then
		Return Catalogs.CounterpartyContracts.ContractByDefault(Counterparty);
	EndIf;
	
	ManagerOfCatalog = Catalogs.CounterpartyContracts;
	
	ContractTypesList = ManagerOfCatalog.GetContractKindsListForDocument(Document);
	ContractByDefault = ManagerOfCatalog.GetDefaultContractByCompanyContractKind(Counterparty, Company, ContractTypesList);
	
	Return ContractByDefault;
	
EndFunction

#EndRegion