////////////////////////////////////////////////////////////////////////////////
// Подсистема "Базовая функциональность".
//
////////////////////////////////////////////////////////////////////////////////

#Region ProgramInterface

#EndRegion

#Region ServiceProgramInterface

Function SelectDateFromCCDNumber(CCDCode) Export
	
	ReceivedDate = Date(1, 1, 1);
	
	FirstDelimiterPosition	= StrFind(CCDCode, "/");
	DateCCD						= Right(CCDCode, StrLen(CCDCode) - FirstDelimiterPosition);
	SecondDelimiterPosition	= StrFind(DateCCD, "/");
	DateCCD						= Left(DateCCD, SecondDelimiterPosition - 1);
	
	If StrLen(DateCCD) = 6 Then
		
		DateDay	= Left(DateCCD, 2);
		DateMonth	= Mid(DateCCD, 3, 2);
		DateYear		= Mid(DateCCD, 5, 2);
		
		Try
			
			DateYear			= ?(Number(DateYear) >= 30, "19" + DateYear, "20" + DateYear);
			ReceivedDate	= Date(DateYear, DateMonth, DateDay);
			
		Except
		EndTry;
		
	EndIf;
	
	Return ReceivedDate;
	
EndFunction

Procedure PrepareInventoryTableFromFormTable(SelectionParameters, FormTable) Export
	
	TableInventory = New ValueTable;
	
	TableInventory.Columns.Add("RowID",	New TypeDescription("Number"));
	TableInventory.Columns.Add("ProductsAndServices", 			New TypeDescription("CatalogRef.ProductsAndServices"));
	TableInventory.Columns.Add("Characteristic",		New TypeDescription("CatalogRef.ProductsAndServicesCharacteristics"));
	TableInventory.Columns.Add("Batch",				New TypeDescription("CatalogRef.ProductsAndServicesBatches"));
	
	For Each FormTableRow In FormTable Do
		
		If SelectionParameters.Property("CheckMark")
			And Not FormTableRow.Check Then
			
			Continue;
			
		EndIf;
		
		If FormTableRow.CountryOfOrigin = Catalogs.WorldCountries.RUSSIA Then
			
			Continue;
			
		EndIf;
		
		If SelectionParameters.Property("ConnectionKey")
			And FormTableRow.ConnectionKey <> SelectionParameters.ConnectionKey Then
			
			Continue;
			
		EndIf;
		
		NewRow = TableInventory.Add();
		FillPropertyValues(NewRow, FormTableRow);
		
		NewRow.RowID = FormTableRow.GetID();
		
	EndDo;
	
	SelectionParameters.TableInventory = TableInventory;
	
EndProcedure

Procedure PickCCDNumbersByPreviousPostuplenijam(SelectionParameters) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.SetParameter("TemporaryTableInventory",	SelectionParameters.TableInventory);
	Query.SetParameter("Company", 			SmallBusinessServer.GetCompany(SelectionParameters.Company));
	
	Query.Text = 
	"SELECT DISTINCT
	|	TableInventory.RowID AS RowID,
	|	TableInventory.ProductsAndServices AS ProductsAndServices,
	|	TableInventory.Characteristic AS Characteristic,
	|	TableInventory.Batch AS Batch
	|INTO TableInventory
	|FROM
	|	&TemporaryTableInventory AS TableInventory
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryByCCDTurnovers.Recorder.Counterparty AS Counterparty,
	|	TableInventory.RowID AS RowID,
	|	TableInventory.ProductsAndServices AS ProductsAndServices,
	|	TableInventory.Characteristic AS Characteristic,
	|	TableInventory.Batch AS Batch,
	|	InventoryByCCDTurnovers.CountryOfOrigin AS CountryOfOrigin,
	|	InventoryByCCDTurnovers.CCDNo AS CCDNo,
	|	InventoryByCCDTurnovers.CCDNo.Code AS CCDCode,
	|	DATETIME(1, 1, 1) AS DateCCD
	|FROM
	|	TableInventory AS TableInventory
	|		LEFT JOIN AccumulationRegister.InventoryByCCD.Turnovers(, , Record, Company = &Company) AS InventoryByCCDTurnovers
	|		ON TableInventory.ProductsAndServices = InventoryByCCDTurnovers.ProductsAndServices
	|			AND TableInventory.Characteristic = InventoryByCCDTurnovers.Characteristic
	|			AND TableInventory.Batch = InventoryByCCDTurnovers.Batch
	|			AND (&CounterpartyConditionInventoryOwn)";
	
	If SelectionParameters.Property("Counterparty") Then 
		
		Query.Text = StrReplace(Query.Text, "&CounterpartyConditionInventoryOwn", "(InventoryByCCDTurnovers.Recorder.Counterparty = &Counterparty)");
		Query.Text = StrReplace(Query.Text, "&CounterpartyConditionInventoryAccepted", "(InventoryAdoptedByCCDTurnovers.Recorder.Counterparty = &Counterparty)");
		Query.SetParameter("Counterparty", SelectionParameters.Counterparty);
		
	Else
		
		Query.Text = StrReplace(Query.Text, "&CounterpartyConditionInventoryOwn", "True");
		Query.Text = StrReplace(Query.Text, "&CounterpartyConditionInventoryAccepted", "True");
		
	EndIf;
	
	InventoryTurnoversByCCD = Query.Execute().Unload();
	For Each TableRow In InventoryTurnoversByCCD Do
		
		TableRow.DateCCD = SelectDateFromCCDNumber(TableRow.CCDCode);
		
	EndDo;
	
	Query.Text = 
	"SELECT
	|	TableInventory.Counterparty AS Counterparty
	|	,TableInventory.RowID
	|	,TableInventory.ProductsAndServices
	|	,TableInventory.Characteristic
	|	,TableInventory.Batch
	|	,TableInventory.CountryOfOrigin
	|	,TableInventory.CCDNo
	|	,TableInventory.DateCCD AS DateCCD
	|INTO TableInventoryWithFilledDates
	|FROM
	|	&InventoryTurnoversByCCD AS TableInventory;
	|
	|//:::::::::::::::::::::::::::::::::::::::::::::::::::::::
	|//::::::: Выделим ГТД с максимально свежей датой ::::::::
	|//:::::::::::::::::::::::::::::::::::::::::::::::::::::::
	|SELECT 
	|	TableInventoryWithFilledDates.Counterparty
	|	,TableInventoryWithFilledDates.RowID
	|	,TableInventoryWithFilledDates.ProductsAndServices
	|	,TableInventoryWithFilledDates.Characteristic
	|	,TableInventoryWithFilledDates.Batch
	|	,TableInventoryWithFilledDates.CountryOfOrigin
	|	,MAX(TableInventoryWithFilledDates.CCDNo)
	|	,MAX(TableInventoryWithFilledDates.DateCCD)
	|FROM TableInventoryWithFilledDates AS TableInventoryWithFilledDates
	|
	|GROUP BY
	|	TableInventoryWithFilledDates.Counterparty
	|	,TableInventoryWithFilledDates.RowID
	|	,TableInventoryWithFilledDates.ProductsAndServices
	|	,TableInventoryWithFilledDates.Characteristic
	|	,TableInventoryWithFilledDates.Batch
	|	,TableInventoryWithFilledDates.CountryOfOrigin";
	
	Query.SetParameter("InventoryTurnoversByCCD", InventoryTurnoversByCCD);
	SelectionParameters.TableInventory = Query.Execute().Unload();
	
	SetPrivilegedMode(False);
	
EndProcedure

Procedure GenerateCCDNumberBalances(SelectionParameters) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT DISTINCT
	|	TableInventory.ProductsAndServices AS ProductsAndServices,
	|	TableInventory.Characteristic AS Characteristic,
	|	TableInventory.Batch AS Batch
	|INTO TableInventory
	|FROM
	|	&TableInventory AS TableInventory
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryByCCDBalance.CountryOfOrigin AS CountryOfOrigin,
	|	InventoryByCCDBalance.QuantityBalance AS QuantityBalance,
	|	TableInventory.ProductsAndServices AS ProductsAndServices,
	|	TableInventory.Characteristic AS Characteristic,
	|	TableInventory.Batch AS Batch,
	|	InventoryByCCDBalance.CCDNo AS CCDNo,
	|	InventoryByCCDBalance.CCDNo.Code AS CCDCode,
	|	DATETIME(1, 1, 1) AS DateCCD
	|INTO BalancesBasedOnCurrentDocument
	|FROM
	|	TableInventory AS TableInventory
	|		LEFT JOIN AccumulationRegister.InventoryByCCD.Balance(, Company = &Company) AS InventoryByCCDBalance
	|		ON TableInventory.ProductsAndServices = InventoryByCCDBalance.ProductsAndServices
	|			AND TableInventory.Characteristic = InventoryByCCDBalance.Characteristic
	|			AND TableInventory.Batch = InventoryByCCDBalance.Batch
	|WHERE
	|	InventoryByCCDBalance.QuantityBalance > 0
	|
	|UNION ALL
	|
	|SELECT
	|	InventoryTakenByCCDBalance.CountryOfOrigin,
	|	InventoryTakenByCCDBalance.QuantityBalance,
	|	TableInventory.ProductsAndServices,
	|	TableInventory.Characteristic,
	|	TableInventory.Batch,
	|	InventoryTakenByCCDBalance.CCDNo,
	|	InventoryTakenByCCDBalance.CCDNo.Code,
	|	DATETIME(1, 1, 1)
	|FROM
	|	TableInventory AS TableInventory
	|		LEFT JOIN AccumulationRegister.InventoryByCCD.Balance(, Company = &Company) AS InventoryTakenByCCDBalance
	|		ON TableInventory.ProductsAndServices = InventoryTakenByCCDBalance.ProductsAndServices
	|			AND TableInventory.Characteristic = InventoryTakenByCCDBalance.Characteristic
	|			AND TableInventory.Batch = InventoryTakenByCCDBalance.Batch
	|WHERE
	|	InventoryTakenByCCDBalance.QuantityBalance > 0
	|
	|UNION ALL
	|
	|SELECT
	|	CurrentDocument.CountryOfOrigin,
	|	CASE
	|		WHEN CurrentDocument.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN ISNULL(CurrentDocument.Quantity, 0)
	|		ELSE -ISNULL(CurrentDocument.Quantity, 0)
	|	END,
	|	CurrentDocument.ProductsAndServices,
	|	CurrentDocument.Characteristic,
	|	CurrentDocument.Batch,
	|	CurrentDocument.CCDNo,
	|	CurrentDocument.CCDNo.Code,
	|	DATETIME(1, 1, 1)
	|FROM
	|	AccumulationRegister.InventoryByCCD AS CurrentDocument
	|WHERE
	|	CurrentDocument.Recorder = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryBalanceOnRegisterCCD.CountryOfOrigin AS CountryOfOrigin,
	|	SUM(InventoryBalanceOnRegisterCCD.QuantityBalance) AS QuantityBalance,
	|	InventoryBalanceOnRegisterCCD.ProductsAndServices AS ProductsAndServices,
	|	InventoryBalanceOnRegisterCCD.Characteristic AS Characteristic,
	|	InventoryBalanceOnRegisterCCD.Batch AS Batch,
	|	InventoryBalanceOnRegisterCCD.CCDNo AS CCDNo,
	|	InventoryBalanceOnRegisterCCD.CCDNo.Code AS CCDCode,
	|	InventoryBalanceOnRegisterCCD.DateCCD AS DateCCD
	|FROM
	|	BalancesBasedOnCurrentDocument AS InventoryBalanceOnRegisterCCD
	|
	|GROUP BY
	|	InventoryBalanceOnRegisterCCD.CountryOfOrigin,
	|	InventoryBalanceOnRegisterCCD.ProductsAndServices,
	|	InventoryBalanceOnRegisterCCD.Characteristic,
	|	InventoryBalanceOnRegisterCCD.Batch,
	|	InventoryBalanceOnRegisterCCD.CCDNo,
	|	InventoryBalanceOnRegisterCCD.CCDNo.Code,
	|	InventoryBalanceOnRegisterCCD.DateCCD");
	
	Query.SetParameter("Period", SelectionParameters.Date);
	Query.SetParameter("Ref", SelectionParameters.Ref);
	Query.SetParameter("TableInventory", SelectionParameters.TableInventory);
	Query.SetParameter("Company", SmallBusinessServer.GetCompany(SelectionParameters.Company));
	BalancesByCCD = Query.Execute().Unload();
	
	For Each TableRow In BalancesByCCD Do
		
		TableRow.DateCCD = SelectDateFromCCDNumber(TableRow.CCDCode);
		
	EndDo; 
	
	BalancesByCCD.Sort("ProductsAndServices, Characteristic, Batch, DateCCD");
	
	SelectionParameters.BalancesByCCD = BalancesByCCD;
	
	SetPrivilegedMode(False);
	
EndProcedure

Procedure GenerateBalancesPassedCCDNumbers(SelectionParameters) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT DISTINCT
	|	TableInventory.ProductsAndServices AS ProductsAndServices,
	|	TableInventory.Characteristic AS Characteristic,
	|	TableInventory.Batch AS Batch
	|INTO TableInventory
	|FROM
	|	&TableInventory AS TableInventory
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryTransferredByCCDBalance.CountryOfOrigin AS CountryOfOrigin,
	|	InventoryTransferredByCCDBalance.QuantityBalance AS QuantityBalance,
	|	TableInventory.ProductsAndServices AS ProductsAndServices,
	|	TableInventory.Characteristic AS Characteristic,
	|	TableInventory.Batch AS Batch,
	|	InventoryTransferredByCCDBalance.CCDNo AS CCDNo,
	|	InventoryTransferredByCCDBalance.CCDNo.Code AS CCDCode,
	|	DATETIME(1, 1, 1) AS DateCCD
	|INTO BalancesWithoutCurrentDocumentAccounting
	|FROM
	|	TableInventory AS TableInventory
	|		LEFT JOIN AccumulationRegister.InventoryTransferredByCCD.Balance(, Company = &Company) AS InventoryTransferredByCCDBalance
	|		ON TableInventory.ProductsAndServices = InventoryTransferredByCCDBalance.ProductsAndServices
	|			AND TableInventory.Characteristic = InventoryTransferredByCCDBalance.Characteristic
	|			AND TableInventory.Batch = InventoryTransferredByCCDBalance.Batch
	|WHERE
	|	InventoryTransferredByCCDBalance.QuantityBalance > 0
	|
	|UNION ALL
	|
	|SELECT
	|	CurrentDocument.CountryOfOrigin,
	|	CASE
	|		WHEN CurrentDocument.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN ISNULL(CurrentDocument.Quantity, 0)
	|		ELSE -ISNULL(CurrentDocument.Quantity, 0)
	|	END,
	|	CurrentDocument.ProductsAndServices,
	|	CurrentDocument.Characteristic,
	|	CurrentDocument.Batch,
	|	CurrentDocument.CCDNo,
	|	CurrentDocument.CCDNo.Code,
	|	DATETIME(1, 1, 1)
	|FROM
	|	AccumulationRegister.InventoryTransferredByCCD AS CurrentDocument
	|WHERE
	|	CurrentDocument.Recorder = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryBalancesTransferredByCCDRegister.CountryOfOrigin AS CountryOfOrigin,
	|	SUM(InventoryBalancesTransferredByCCDRegister.QuantityBalance) AS QuantityBalance,
	|	InventoryBalancesTransferredByCCDRegister.ProductsAndServices AS ProductsAndServices,
	|	InventoryBalancesTransferredByCCDRegister.Characteristic AS Characteristic,
	|	InventoryBalancesTransferredByCCDRegister.Batch AS Batch,
	|	InventoryBalancesTransferredByCCDRegister.CCDNo AS CCDNo,
	|	InventoryBalancesTransferredByCCDRegister.CCDNo.Code AS CCDCode,
	|	InventoryBalancesTransferredByCCDRegister.DateCCD AS DateCCD
	|FROM
	|	BalancesWithoutCurrentDocumentAccounting AS InventoryBalancesTransferredByCCDRegister
	|
	|GROUP BY
	|	InventoryBalancesTransferredByCCDRegister.CountryOfOrigin,
	|	InventoryBalancesTransferredByCCDRegister.ProductsAndServices,
	|	InventoryBalancesTransferredByCCDRegister.Characteristic,
	|	InventoryBalancesTransferredByCCDRegister.Batch,
	|	InventoryBalancesTransferredByCCDRegister.CCDNo,
	|	InventoryBalancesTransferredByCCDRegister.CCDNo.Code,
	|	InventoryBalancesTransferredByCCDRegister.DateCCD");
	
	Query.SetParameter("Period", SelectionParameters.Date);
	Query.SetParameter("Ref", SelectionParameters.Ref);
	Query.SetParameter("TableInventory", SelectionParameters.TableInventory);
	Query.SetParameter("Company", SmallBusinessServer.GetCompany(SelectionParameters.Company));
	BalancesByCCD = Query.Execute().Unload();
	
	For Each TableRow In BalancesByCCD Do
		
		TableRow.DateCCD = SelectDateFromCCDNumber(TableRow.CCDCode);
		
	EndDo; 
	
	BalancesByCCD.Sort("ProductsAndServices, Characteristic, Batch, DateCCD");
	
	SelectionParameters.BalancesByCCD = BalancesByCCD;
	
	SetPrivilegedMode(False);
	
EndProcedure

Procedure GenerateBalancesAcceptedCCDNumbers(SelectionParameters) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT DISTINCT
	|	TableInventory.ProductsAndServices AS ProductsAndServices,
	|	TableInventory.Characteristic AS Characteristic,
	|	TableInventory.Batch AS Batch
	|INTO TableInventory
	|FROM
	|	&TableInventory AS TableInventory
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryTakenByCCDBalance.CountryOfOrigin AS CountryOfOrigin,
	|	InventoryTakenByCCDBalance.QuantityBalance AS QuantityBalance,
	|	TableInventory.ProductsAndServices AS ProductsAndServices,
	|	TableInventory.Characteristic AS Characteristic,
	|	TableInventory.Batch AS Batch,
	|	InventoryTakenByCCDBalance.CCDNo AS CCDNo,
	|	InventoryTakenByCCDBalance.CCDNo.Code AS CCDCode,
	|	DATETIME(1, 1, 1) AS DateCCD
	|INTO BalancesWithoutCurrentDocumentAccounting
	|FROM
	|	TableInventory AS TableInventory
	|		LEFT JOIN AccumulationRegister.InventoryTakenByCCD.Balance(, Company = &Company) AS InventoryTakenByCCDBalance
	|		ON TableInventory.ProductsAndServices = InventoryTakenByCCDBalance.ProductsAndServices
	|			AND TableInventory.Characteristic = InventoryTakenByCCDBalance.Characteristic
	|			AND TableInventory.Batch = InventoryTakenByCCDBalance.Batch
	|WHERE
	|	InventoryTakenByCCDBalance.QuantityBalance > 0
	|
	|UNION ALL
	|
	|SELECT
	|	CurrentDocument.CountryOfOrigin,
	|	CASE
	|		WHEN CurrentDocument.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN ISNULL(CurrentDocument.Quantity, 0)
	|		ELSE -ISNULL(CurrentDocument.Quantity, 0)
	|	END,
	|	CurrentDocument.ProductsAndServices,
	|	CurrentDocument.Characteristic,
	|	CurrentDocument.Batch,
	|	CurrentDocument.CCDNo,
	|	CurrentDocument.CCDNo.Code,
	|	DATETIME(1, 1, 1)
	|FROM
	|	AccumulationRegister.InventoryTakenByCCD AS CurrentDocument
	|WHERE
	|	CurrentDocument.Recorder = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryBalanceOnRegisterCCD.CountryOfOrigin,
	|	SUM(InventoryBalanceOnRegisterCCD.QuantityBalance) AS QuantityBalance,
	|	InventoryBalanceOnRegisterCCD.ProductsAndServices,
	|	InventoryBalanceOnRegisterCCD.Characteristic,
	|	InventoryBalanceOnRegisterCCD.Batch,
	|	InventoryBalanceOnRegisterCCD.CCDNo,
	|	InventoryBalanceOnRegisterCCD.CCDNo.Code AS CCDCode,
	|	InventoryBalanceOnRegisterCCD.DateCCD AS DateCCD
	|FROM
	|	BalancesWithoutCurrentDocumentAccounting AS InventoryBalanceOnRegisterCCD
	|
	|GROUP BY
	|	InventoryBalanceOnRegisterCCD.CountryOfOrigin,
	|	InventoryBalanceOnRegisterCCD.ProductsAndServices,
	|	InventoryBalanceOnRegisterCCD.Characteristic,
	|	InventoryBalanceOnRegisterCCD.Batch,
	|	InventoryBalanceOnRegisterCCD.CCDNo,
	|	InventoryBalanceOnRegisterCCD.CCDNo.Code,
	|	InventoryBalanceOnRegisterCCD.DateCCD");
	
	Query.SetParameter("Period", SelectionParameters.Date);
	Query.SetParameter("Ref", SelectionParameters.Ref);
	Query.SetParameter("TableInventory", SelectionParameters.TableInventory);
	Query.SetParameter("Company", SmallBusinessServer.GetCompany(SelectionParameters.Company));
	BalancesByCCD = Query.Execute().Unload();
	
	For Each TableRow In BalancesByCCD Do
		
		TableRow.DateCCD = SelectDateFromCCDNumber(TableRow.CCDCode);
		
	EndDo; 
	
	BalancesByCCD.Sort("ProductsAndServices, Characteristic, Batch, DateCCD");
	
	SelectionParameters.BalancesByCCD = BalancesByCCD;
	
	SetPrivilegedMode(False);
	
EndProcedure

Procedure MoveCCDNumbersToFormTable(FormTable, SelectionParameters) Export
	
	For Each InventoryRow In SelectionParameters.TableInventory Do
		
		FormTableRow = FormTable.FindByID(InventoryRow.RowID);
		
		FormTableRow.CountryOfOrigin = InventoryRow.CountryOfOrigin;
		FormTableRow.CCDNo = InventoryRow.CCDNo;
		
	EndDo;
	
EndProcedure

Procedure TransferCCDNumberBalancesToFormTable(FormTable, SelectionParameters) Export
	
	If FormTable.Count() < 1 Then
		
		SelectionParameters.IndexOfCurrentRow = -1;
		Return;
		
	EndIf;
	
	TableInventory = FormTable.Unload();
	TableInventory.Clear();
	
	QuantitativeFields = New Array;
	QuantitativeFields.Add("Reserve");
	
	FilterStructure = New Structure("ProductsAndServices, Characteristic, Batch");
	
	HasMeasurementUnitColumn = (TableInventory.Columns.Find("MeasurementUnit") = Undefined);
	
	AutomaticDiscountsLinkKey	= Undefined;
	NewCurrentRowIndex		= -1;
	For Each TSRow In FormTable Do
		
		If SelectionParameters.Property("SkipRefunds")
			And TSRow.Count < 0 Then
			
			FillPropertyValues(TableInventory.Add(), TSRow);
			Continue;
			
		EndIf;
		
		If SelectionParameters.Property("CheckMark")
			And Not TSRow.Check Then
			
			FillPropertyValues(TableInventory.Add(), TSRow);
			Continue;
			
		EndIf;
		
		If SelectionParameters.Property("ConnectionKey")
			And Not TSRow.ConnectionKey = SelectionParameters.ConnectionKey Then
			
			FillPropertyValues(TableInventory.Add(), TSRow);
			Continue;
			
		EndIf;
		
		If SelectionParameters.Property("HasAutomaticDiscountsConnectionKey") Then
			
			AutomaticDiscountsLinkKey = TSRow.ConnectionKey;
			
		EndIf;
		
		IsCurrentRow = (FormTable.IndexOf(TSRow) = SelectionParameters.IndexOfCurrentRow);
		
		TotalStructure = New Structure;
		For Each FieldName In SelectionParameters.NamesOfFields Do
			
			TotalStructure.Insert(FieldName, TSRow[FieldName]);
			
		EndDo;
		
		FilterStructure.ProductsAndServices	= TSRow.ProductsAndServices;
		FilterStructure.Characteristic	= TSRow.Characteristic;
		FilterStructure.Batch			= TSRow.Batch;
		
		RowsArrayCCD		= SelectionParameters.BalancesByCCD.FindRows(FilterStructure);
		QuantityBalance	= TSRow.Quantity;
		
		UserUnitFactor = 1;
		If HasMeasurementUnitColumn
			And TypeOf(TSRow.MeasurementUnit) = Type("CatalogRef.UOM") Then
			
			UserUnitFactor = TSRow.MeasurementUnit.Factor;
			
		EndIf;
		
		For Each ArrayRow In RowsArrayCCD Do
			
			NewRow = TableInventory.Add();
			FillPropertyValues(NewRow, TSRow);
			
			If SelectionParameters.Property("HasAutomaticDiscountsConnectionKey") Then
				
				NewRow.ConnectionKey = AutomaticDiscountsLinkKey;
				If AutomaticDiscountsLinkKey <> Undefined Then
					
					AutomaticDiscountsLinkKey = Undefined;
					
				EndIf;
				
			EndIf;
			
			NewRow.CCDNo			= ArrayRow.CCDNo;
			NewRow.CountryOfOrigin	= ArrayRow.CountryOfOrigin;
			
			If (QuantityBalance * UserUnitFactor) <= ArrayRow.QuantityBalance Then
				
				NewRow.Quantity			= QuantityBalance;
				ArrayRow.QuantityBalance	= ArrayRow.QuantityBalance - (QuantityBalance * UserUnitFactor);
				QuantityBalance				= 0;
				
				If ArrayRow.QuantityBalance = 0 Then
					
					SelectionParameters.BalancesByCCD.Delete(ArrayRow);
					
				EndIf;
				
				For Each FieldName In SelectionParameters.NamesOfFields Do
					
					NewRow[FieldName] = TotalStructure[FieldName]
					
				EndDo;
				
				Break;
				
			Else
				
				QuantityWithFactorAccounting = Round(ArrayRow.QuantityBalance / UserUnitFactor, 3);
				
				NewRow.Quantity	= QuantityWithFactorAccounting;
				
				If SelectionParameters.NamesOfFields.Count() > 0 Then
					
					MultiplierByCoefficient = ?(TSRow.Quantity = 0, 1, (QuantityWithFactorAccounting/TSRow.Quantity));
					For Each FieldName In SelectionParameters.NamesOfFields Do
						
						If QuantitativeFields.Find(FieldName) = Undefined Then
							
							NewRow[FieldName] = Round(NewRow[FieldName] * MultiplierByCoefficient, 3);
							
						Else
							
							NewRow[FieldName] = Min(NewRow.Quantity, NewRow[FieldName]);
							
						EndIf;
						
						TotalStructure[FieldName] = TotalStructure[FieldName] - NewRow[FieldName];
						
					EndDo;
					
				EndIf;
				
				QuantityBalance		= QuantityBalance - QuantityWithFactorAccounting;
				SelectionParameters.BalancesByCCD.Delete(ArrayRow);
				
			EndIf;
			
		EndDo;
		
		If QuantityBalance > 0 Then
		
			NewRow				= TableInventory.Add();
			FillPropertyValues(NewRow, TSRow);
			
			NewRow.Quantity			= QuantityBalance;
			NewRow.CCDNo			= Catalogs.CCDNumbers.EmptyRef();
			NewRow.CountryOfOrigin = TSRow.CountryOfOrigin;
			
			For Each FieldName In SelectionParameters.NamesOfFields Do
				
				NewRow[FieldName] = TotalStructure[FieldName];
				
			EndDo;
			
		EndIf;
		
		If IsCurrentRow Then
			
			NewCurrentRowIndex = TableInventory.IndexOf(NewRow);
			IsCurrentRow = False;
			
		EndIf;
		
	EndDo;
	
	FormTable.Load(TableInventory);
	
	If NewCurrentRowIndex <> -1 Then
		
		SelectionParameters.IndexOfCurrentRow = NewCurrentRowIndex;
		
	EndIf;
	
EndProcedure

Procedure ClearCCDAndCountryOfOriginNumbers(FormTable, ConnectionKey = +1, CheckMark = True) Export
	
	For Each TableRow In FormTable Do
		
		If CheckMark
			And Not TableRow.Check Then
			
			Continue;
			
		EndIf;
		
		If ConnectionKey >= 0
			And TableRow.ConnectionKey <> ConnectionKey Then
			
			Continue;
			
		EndIf;
		
		If TableRow.Property("CountryOfOrigin") Then
			
			TableRow.CountryOfOrigin = Undefined;
			
		EndIf;
		
		If TableRow.Property("CCDNo") Then
			
			TableRow.CCDNo = Undefined;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure FillActionsList(Actions, IsExpenseDocument = True, TSName = "") Export
	
	If GetFunctionalOption("AccountingCCD") Then
		
		If IsExpenseDocument Then
			
			Actions.Add(Enums.BulkRowChangeActions.FillByActualBalancesCCDNumbers);
			
		EndIf;
		
		Actions.Add(Enums.BulkRowChangeActions.PickCCDNumbers);
		Actions.Add(Enums.BulkRowChangeActions.ClearCCDAndCountryOfOriginNumbers);
		
	EndIf;
	
EndProcedure

Function MustReflectInvoiceByInvoiceInventoryByCCD(InvoiceRef) Export
	
	Query = New Query("SELECT TOP 1 InventoryCCD.Recorder FROM AccumulationRegister.InventoryByCCD AS InventoryCCD WHERE InventoryCCD.Recorder IN(&RefArray)");
	Query.SetParameter("RefArray", InvoiceRef.BasisDocuments.Unload(,"BasisDocument"));
	QueryResult = Query.Execute();
	
	MustReflect = Constants.FunctionalOptionAccountingCCD.Get() And (BegOfDay(Constants.UpdateDateForRelease_1_6_6.Get()) < InvoiceRef.Date);
	
	Return MustReflect And QueryResult.IsEmpty();
	
EndFunction

Function CanEnableControlBalancesByCCDNumbers() Export
	
	Query			= New Query;
	Query.Text	= "SELECT TOP 1 CatCCDNumbers.CCDNo FROM AccumulationRegister.InventoryByCCD.Balance AS CatCCDNumbers WHERE CatCCDNumbers.QuantityBalance < 0";
	SELECTION			= Query.Execute().Select();
	
	Return Not SELECTION.Next();
	
EndFunction

Procedure OnCreateAtServer(ThisForm, TSNames, CashValues) Export
	
	If TypeOf(CashValues) <> Type("Structure") Then
		
		CashValues = New Structure;
		
	EndIf;
	
	CashValues.Insert("AccountingCCD", GetFunctionalOption("AccountingCCD"));
	CashValues.Insert("RUSSIA", Catalogs.WorldCountries.RUSSIA);
	
	For Each ParametersStructure In TSNames Do
		
		CheckFieldName = ParametersStructure.CheckFieldName;
		AppearanceFieldName = ParametersStructure.AppearanceFieldName;
		
		//(1)
		CCDNumberAvailable = ThisForm.ConditionalAppearance.Items.Add();
		CCDNumberAvailable.Appearance.SetParameterValue("ReadOnly", False);
		
		GroupOfFilter = CCDNumberAvailable.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		GroupOfFilter.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
		CommonUseClientServer.AddCompositionItem(GroupOfFilter, CheckFieldName, DataCompositionComparisonType.Filled);
		CommonUseClientServer.AddCompositionItem(GroupOfFilter, CheckFieldName, DataCompositionComparisonType.NotEqual, Catalogs.WorldCountries.RUSSIA);
		
		If ParametersStructure.Property("AdditionalCheckField") Then
			
			CommonUseClientServer.AddCompositionItem(GroupOfFilter, ParametersStructure.AdditionalCheckField, DataCompositionComparisonType.Equal, False);
			
		EndIf;
		
		DataCompositionClientServer.AddAppearanceField(CCDNumberAvailable.Fields, AppearanceFieldName);
		
		//(2)
		CCDNumberUnavailable = ThisForm.ConditionalAppearance.Items.Add();
		CCDNumberUnavailable.Appearance.SetParameterValue("ReadOnly", True);
		
		GroupOfFilter = CCDNumberUnavailable.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		GroupOfFilter.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
		
		CommonUseClientServer.AddCompositionItem(GroupOfFilter, CheckFieldName, DataCompositionComparisonType.NotFilled);
		CommonUseClientServer.AddCompositionItem(GroupOfFilter, CheckFieldName, DataCompositionComparisonType.Equal, Catalogs.WorldCountries.RUSSIA);
		
		If ParametersStructure.Property("AdditionalCheckField") Then
			
			CommonUseClientServer.AddCompositionItem(GroupOfFilter, ParametersStructure.AdditionalCheckField, DataCompositionComparisonType.Equal, True);
			
		EndIf;
		
		DataCompositionClientServer.AddAppearanceField(CCDNumberUnavailable.Fields, AppearanceFieldName);
		
	EndDo;
	
EndProcedure

Procedure OnProcessingFillingCheck(cancel, CheckObject, TabularSectionNames = Undefined) Export
	Var Errors;
	
	If Not GetFunctionalOption("AccountingCCD") Then
		
		Return;
		
	EndIf;
	
	If TabularSectionNames = Undefined Then
		
		TabularSectionNames = New Array;
		TabularSectionNames.Add("Inventory");
		
	EndIf;
	
	//EEUCountries = TableOfCountriesOfCustomsUnion().UnloadColumn("Ref");
	//
	//IndexRussia = EEUCountries.Find(Catalogs.WorldCountries.RUSSIA);
	//If IndexRussia <> Undefined Then
	//	
	//	EEUCountries.Delete(IndexRussia);
	//	
	//EndIf;
	
	RequireImportGoodsCCDFilling = Constants.RequireImportGoodsCCDFilling.Get();
	For Each TSName In TabularSectionNames Do
		
		For Each DocumentTableString In CheckObject[TSName] Do
			
			//If EEUCountries.Find(DocumentTableString.CountryOfOrigin) <> Undefined Then
			//	
			//	// Страны ЕАЭС могут содержать номер ГТД, но это не обязательная мера.
			//	Continue;
			//	
			//EndIf;
			
			CountryOfOriginRequiresCCDNumber = ValueIsFilled(DocumentTableString.CountryOfOrigin)
				And DocumentTableString.CountryOfOrigin <> Catalogs.WorldCountries.RUSSIA;
			
			If ValueIsFilled(DocumentTableString.CCDNo)
				And Not CountryOfOriginRequiresCCDNumber
				Then
				
				ErrorText = StrTemplate(NStr("en='In row [%1] tabular section %2 not correct Origin country';ru='В строке [%1] табличной части %2 не верно указана страна происхождения';vi='Tại dòng [%1] của phần bảng %2 đã chỉ ra sai nước xuất xứ'"), TrimAll(DocumentTableString.LineNumber), TSName);
				ErrorField = "Object." + TSName + "[%1].CountryOfOrigin";
				
				CommonUseClientServer.AddUserError(Errors, ErrorField, ErrorText, "", CheckObject[TSName].IndexOf(DocumentTableString));
				
			EndIf;
			
			If RequireImportGoodsCCDFilling = True
				And Not ValueIsFilled(DocumentTableString.CCDNo)
				And CountryOfOriginRequiresCCDNumber
				Then
				
				ErrorText = StrTemplate(NStr("en='In Row [%1] tabular section %2 not filled CCD number';ru='В строке [%1] табличной части %2 не указан номер ГТД';vi='Trong dòng [%1] của phần bảng %2 chưa chỉ ra số tờ khai hải quan'"), TrimAll(DocumentTableString.LineNumber), TSName);
				ErrorField = "Object." + TSName + "[%1].CCDNo";
				
				CommonUseClientServer.AddUserError(Errors, ErrorField, ErrorText, "", CheckObject[TSName].IndexOf(DocumentTableString));
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	If Not Errors = Undefined Then
		
		CommonUseClientServer.ShowErrorsToUser(Errors, cancel);
		
	EndIf;
	
EndProcedure

#EndRegion