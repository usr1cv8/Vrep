Function VATRate(RateKind, Period = Undefined) Export
	If Period = Undefined Then
		Period = CurrentSessionDate();
	EndIf;
	
	If RateKind = Enums.VATRateKinds.Common Then
		Return CommonVATRate(Period);
	ElsIf RateKind = Enums.VATRateKinds.TotalCalculated Then
		Return CommonVATRate(Period, True);
	Else
		Return VATRateByBetKind(RateKind);
	EndIf
	
EndFunction

Function VATRateByBetKind(Val RateKind)
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	VATRates.Ref AS Ref
	|FROM
	|	Catalog.VATRates AS VATRates
	|WHERE
	|	VATRates.VATRateKind = &VATRateKind";
	Query.SetParameter("VATRateKind", RateKind);
	SELECTION = Query.Execute().Select();
	If SELECTION.Next() Then
		Return SELECTION.Ref;
	Else
		Return Catalogs.VATRates.EmptyRef();
	EndIf;

EndFunction

Function CommonVATRate(Val Period, Calculated = False)
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	VATRates.Ref AS Ref,
	|	1 AS Priority
	|FROM
	|	Catalog.VATRates AS VATRates
	|WHERE
	|	VATRates.VATRateKind = VALUE(Enum.VATRateKinds.Common)
	|	AND VATRates.Rate = &RateValue
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	VATRates.Ref,
	|	2
	|FROM
	|	Catalog.VATRates AS VATRates
	|WHERE
	|	VATRates.VATRateKind = VALUE(Enum.VATRateKinds.Common)
	|	AND VATRates.Rate <> &RateValue
	|
	|ORDER BY
	|	Priority";
	If Period >= Date('20190101') Then
		Query.SetParameter("RateValue", 20);
	Else
		Query.SetParameter("RateValue", 18);
	EndIf;
	If Calculated Then
		Query.Text = StrReplace(Query.Text, ".Common", ".TotalCalculated");
	EndIf;
	SELECTION = Query.Execute().Select();
	If SELECTION.Next() Then
		Return SELECTION.Ref;
	Else
		Return Catalogs.VATRates.EmptyRef();
	EndIf;
EndFunction
