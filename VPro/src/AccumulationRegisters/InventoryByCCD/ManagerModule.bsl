#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region ProgramInterface

Function InventoryBalancesCCDExist() Export
	
	Query = New Query;
	Query.Text = 
		"SELECT TOP 1
		|	InventoryByCCDBalances.CCDNo AS CCDNo
		|FROM
		|	AccumulationRegister.InventoryByCCD.Balance AS InventoryByCCDBalances";
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	Return Не QueryResult.IsEmpty();
	
EndFunction


// Procedure creates an empty temporary table of records change.
//
Procedure CreateEmptyTemporaryTableChange(AdditionalProperties) Export
	
	If Not AdditionalProperties.Property("ForPosting")
	 OR Not AdditionalProperties.ForPosting.Property("StructureTemporaryTables") Then
		Return;
	EndIf;
	
	StructureTemporaryTables = AdditionalProperties.ForPosting.StructureTemporaryTables;
	
	Query = New Query(
	"SELECT TOP 0
	|	InventoryByCCD.LineNumber AS LineNumber,
	|	InventoryByCCD.Company AS Company,
	|	InventoryByCCD.ProductsAndServices AS ProductsAndServices,
	|	InventoryByCCD.CCDNo AS CCDNo,
	|	InventoryByCCD.Batch AS Batch,
	|	InventoryByCCD.Characteristic AS Characteristic,
	|	InventoryByCCD.CountryOfOrigin AS CountryOfOrigin,
	|	InventoryByCCD.Quantity AS QuantityBeforeWrite,
	|	InventoryByCCD.Quantity AS QuantityChange,
	|	InventoryByCCD.Quantity AS QuantityOnWrite
	|INTO RegisterRecordsInventoryByCCDChange
	|FROM
	|	AccumulationRegister.InventoryByCCD AS InventoryByCCD");
	
	Query.TempTablesManager = StructureTemporaryTables.TempTablesManager;
	QueryResult = Query.Execute();
	
	StructureTemporaryTables.Insert("RegisterRecordsInventoryByCCDChange", False);
	
EndProcedure // CreateEmptyTemporaryTableChange()

Procedure AddTextInventoryByCCD(QueryText) Export
	
	QueryText = QueryText + 
	"SELECT
	|	RegisterRecordsInventoryByCCDChange.LineNumber AS LineNumber,
	|	REFPRESENTATION(RegisterRecordsInventoryByCCDChange.Company) AS CompanyPresentation,
	|	REFPRESENTATION(RegisterRecordsInventoryByCCDChange.CCDNo) AS CCDNoPresentation,
	|	REFPRESENTATION(RegisterRecordsInventoryByCCDChange.ProductsAndServices) AS ProductsAndServicesPresentation,
	|	REFPRESENTATION(RegisterRecordsInventoryByCCDChange.Characteristic) AS CharacteristicPresentation,
	|	REFPRESENTATION(RegisterRecordsInventoryByCCDChange.Batch) AS BatchPresentation,
	|	REFPRESENTATION(RegisterRecordsInventoryByCCDChange.CountryOfOrigin) AS CountryOfOriginPresentation,
	|	REFPRESENTATION(InventoryByCCDBalance.ProductsAndServices.MeasurementUnit) AS MeasurementUnitPresentation,
	|	ISNULL(RegisterRecordsInventoryByCCDChange.QuantityChange, 0) + ISNULL(InventoryByCCDBalance.QuantityBalance, 0) AS BalanceInventoryByCCD,
	|	ISNULL(InventoryByCCDBalance.QuantityBalance, 0) AS QuantityBalanceInventoryByCCD
	|FROM
	|	RegisterRecordsInventoryByCCDChange AS RegisterRecordsInventoryByCCDChange
	|		LEFT JOIN AccumulationRegister.InventoryByCCD.Balance(
	|				&ControlTime,
	|				(Company, CCDNo, ProductsAndServices, Characteristic, Batch, CountryOfOrigin) IN
	|					(SELECT
	|						RegisterRecordsInventoryByCCDChange.Company AS Company,
	|						RegisterRecordsInventoryByCCDChange.CCDNo AS CCDNo,
	|						RegisterRecordsInventoryByCCDChange.ProductsAndServices AS ProductsAndServices,
	|						RegisterRecordsInventoryByCCDChange.Characteristic AS Characteristic,
	|						RegisterRecordsInventoryByCCDChange.Batch AS Batch,
	|						RegisterRecordsInventoryByCCDChange.CountryOfOrigin AS CountryOfOrigin
	|					FROM
	|						RegisterRecordsInventoryByCCDChange AS RegisterRecordsInventoryByCCDChange)) AS InventoryByCCDBalance
	|		ON RegisterRecordsInventoryByCCDChange.Company = InventoryByCCDBalance.Company
	|			AND RegisterRecordsInventoryByCCDChange.CCDNo = InventoryByCCDBalance.CCDNo
	|			AND RegisterRecordsInventoryByCCDChange.ProductsAndServices = InventoryByCCDBalance.ProductsAndServices
	|			AND RegisterRecordsInventoryByCCDChange.Characteristic = InventoryByCCDBalance.Characteristic
	|			AND RegisterRecordsInventoryByCCDChange.Batch = InventoryByCCDBalance.Batch
	|			AND RegisterRecordsInventoryByCCDChange.CountryOfOrigin = InventoryByCCDBalance.CountryOfOrigin
	|WHERE
	|	ISNULL(InventoryByCCDBalance.QuantityBalance, 0) < 0
	|
	|ORDER BY
	|	LineNumber";
	
	

EndProcedure

#EndRegion

#EndIf