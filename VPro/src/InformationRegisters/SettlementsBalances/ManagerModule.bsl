#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region ProgramInterface

// Процедура обновляет данные регистра для переданных контагентов по текущим остаткам взаиморасчетов.
//
// Parameters:
//  Counterparties	 - Array, ValueTable	 - контрагенты, для которых необходимо обновить данные регистра.
//		Если параметр не указан, обновляются остатки по всем контрагентам.
//
Procedure UpdateSettlementsBalances(Val Counterparties = Undefined) Export
	
	If TypeOf(Counterparties) = Type("Array") Then
		CounterpartyTable = New ValueTable;
		CounterpartyTable.Columns.Add("Counterparty", New TypeDescription("CatalogRef.Counterparties"));
		For Each Counterparty In Counterparties Do
			NewRow = CounterpartyTable.Add();
			NewRow.Counterparty = Counterparty;
		EndDo;
		Counterparties = CounterpartyTable;
	EndIf;
	
	Query = New Query;
	
	If Counterparties = Undefined Then
		
		Query.Text = 
			"SELECT
			|	NestedQuery.Counterparty,
			|	SUM(NestedQuery.AmountBalance) AS AmountBalance
			|INTO TTSettlements
			|FROM
			|	(SELECT
			|		AccountsReceivableBalances.Counterparty AS Counterparty,
			|		AccountsReceivableBalances.AmountBalance AS AmountBalance
			|	FROM
			|		AccumulationRegister.AccountsReceivable.Balance AS AccountsReceivableBalances
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		AccountsPayableBalances.Counterparty,
			|		-AccountsPayableBalances.AmountBalance
			|	FROM
			|		AccumulationRegister.AccountsPayable.Balance AS AccountsPayableBalances
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		SettlementsWithOtherCounterpartiesBalances.Counterparty,
			|		SettlementsWithOtherCounterpartiesBalances.AmountBalance
			|	FROM
			|		AccumulationRegister.SettlementsWithOtherCounterparties.Balance AS SettlementsWithOtherCounterpartiesBalances) AS NestedQuery
			|
			|GROUP BY
			|	NestedQuery.Counterparty
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	ISNULL(SettlementsBalances.Counterparty, TTSettlements.Counterparty) AS Counterparty,
			|	ISNULL(TTSettlements.AmountBalance, 0) AS AmountBalance
			|FROM
			|	InformationRegister.SettlementsBalances AS SettlementsBalances
			|		FULL JOIN TTSettlements AS TTSettlements
			|		ON SettlementsBalances.Counterparty = TTSettlements.Counterparty";
		
	Else
		
		Query.Text = 
			"SELECT
			|	Counterparties.Counterparty
			|INTO vtCounterparties
			|FROM
			|	&Counterparties AS Counterparties
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	NestedQuery.Counterparty,
			|	SUM(NestedQuery.AmountBalance) AS AmountBalance
			|INTO TTSettlements
			|FROM
			|	(SELECT
			|		AccountsReceivableBalances.Counterparty AS Counterparty,
			|		AccountsReceivableBalances.AmountBalance AS AmountBalance
			|	FROM
			|		AccumulationRegister.AccountsReceivable.Balance(, Counterparty IN (&Counterparties)) AS AccountsReceivableBalances
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		AccountsPayableBalances.Counterparty,
			|		-AccountsPayableBalances.AmountBalance
			|	FROM
			|		AccumulationRegister.AccountsPayable.Balance(, Counterparty IN (&Counterparties)) AS AccountsPayableBalances
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		SettlementsWithOtherCounterpartiesBalances.Counterparty,
			|		SettlementsWithOtherCounterpartiesBalances.AmountBalance
			|	FROM
			|		AccumulationRegister.SettlementsWithOtherCounterparties.Balance(, Counterparty IN (&Counterparties)) AS SettlementsWithOtherCounterpartiesBalances) AS NestedQuery
			|
			|GROUP BY
			|	NestedQuery.Counterparty
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	vtCounterparties.Counterparty AS Counterparty,
			|	ISNULL(TTSettlements.AmountBalance, 0) AS AmountBalance
			|FROM
			|	vtCounterparties AS vtCounterparties
			|		LEFT JOIN TTSettlements AS TTSettlements
			|		ON vtCounterparties.Counterparty = TTSettlements.Counterparty";
		
		Query.SetParameter("Counterparties", Counterparties);
	
	EndIf;
	
	RecordSet = InformationRegisters.SettlementsBalances.CreateRecordSet();
	SELECTION = Query.Execute().Select();
	
	While SELECTION.Next() Do
		
		RecordSet.Filter.Counterparty.Set(SELECTION.Counterparty);
		
		If SELECTION.AmountBalance = 0 Then
			RecordSet.Write(True);
			Continue;
		EndIf;
		
		RecordSet.Read();
		
		If RecordSet.Count() > 0 Then
			WriteSet = RecordSet[0];
		Else
			WriteSet = RecordSet.Add();
		EndIf;
		WriteSet.Counterparty = SELECTION.Counterparty;
		WriteSet.Amount = SELECTION.AmountBalance;
		
		RecordSet.Write(True);
		RecordSet.Clear();
		
	EndDo;
	
EndProcedure

#Region ForCallsFromOtherSubsystems

// СтандартныеПодсистемы.УправлениеДоступом

// See AccessManagementOverridable.OnFillListWithAccessRestriction.
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Counterparty)";

EndProcedure

// Конец СтандартныеПодсистемы.УправлениеДоступом

#EndRegion

#EndRegion

#EndIf