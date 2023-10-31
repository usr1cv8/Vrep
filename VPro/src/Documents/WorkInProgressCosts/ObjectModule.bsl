#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

////////////////////////////////////////////////////////////////////////////////
// EXPORT PROCEDURES AND FUNCTIONS OF DOCUMENT

// Procedure fills tabular section according to specification.
//
Procedure FillTabularSectionBySpecification(BySpecification, RequiredQuantity, UsedMeasurementUnit, OnRequest) Export
    
	Query = New Query(
	"SELECT
	|	MAX(SpecificationsContent.LineNumber) AS SpecificationsContentLineNumber,
	|	SpecificationsContent.ProductsAndServices AS ProductsAndServices,
	|	SpecificationsContent.ContentRowType AS ContentRowType,
	|	CASE
	|		WHEN &UseCharacteristics
	|			THEN SpecificationsContent.Characteristic
	|		ELSE VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	|	END AS Characteristic,
	|	SpecificationsContent.MeasurementUnit AS MeasurementUnit,
	|	SpecificationsContent.Specification AS Specification,
	|	SUM(CASE
	|			WHEN VALUETYPE(&MeasurementUnit) = Type(Catalog.UOMClassifier)
	|				THEN SpecificationsContent.Quantity / SpecificationsContent.ProductsQuantity * &Quantity
	|			ELSE SpecificationsContent.Quantity / SpecificationsContent.ProductsQuantity * &Factor * &Quantity
	|		END) AS Quantity,
	|	&CustomerOrder AS CustomerOrder
	|FROM
	|	Catalog.Specifications.Content AS SpecificationsContent
	|WHERE
	|	SpecificationsContent.Ref = &Specification
	|	AND SpecificationsContent.ProductsAndServices.ProductsAndServicesType = &ProductsAndServicesType
	|
	|GROUP BY
	|	SpecificationsContent.ProductsAndServices,
	|	CASE
	|		WHEN &UseCharacteristics
	|			THEN SpecificationsContent.Characteristic
	|		ELSE VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	|	END,
	|	SpecificationsContent.MeasurementUnit,
	|	SpecificationsContent.Specification,
	|	SpecificationsContent.ContentRowType,
	|	SpecificationsContent.CostPercentage
	|
	|ORDER BY
	|	SpecificationsContentLineNumber");
	
	Query.SetParameter("UseCharacteristics", Constants.FunctionalOptionUseCharacteristics.Get());
	Query.SetParameter("ProcessingDate", EndOfDay(Date));
	
	Query.SetParameter("CustomerOrder", OnRequest);
	Query.SetParameter("Specification", BySpecification);
	Query.SetParameter("Quantity", RequiredQuantity);
	
	Query.SetParameter("MeasurementUnit", UsedMeasurementUnit);
	
	If TypeOf(UsedMeasurementUnit) = Type("CatalogRef.UOMClassifier") Then
    	Query.SetParameter("Factor", 1);
	Else
		Query.SetParameter("Factor", UsedMeasurementUnit.Factor);
	EndIf;
	
	Query.SetParameter("ProductsAndServicesType", Enums.ProductsAndServicesTypes.InventoryItem);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		If Selection.ContentRowType = Enums.SpecificationContentRowTypes.Node Then
			
			FillTabularSectionBySpecification(Selection.Specification, Selection.Quantity, Selection.MeasurementUnit, OnRequest);
			
		Else
			
	    	NewRow = Inventory.Add();
	    	FillPropertyValues(NewRow, Selection);
			
		EndIf;
		
   EndDo;

EndProcedure // FillTabularSectionBySpecification()

// Procedure allocates tabular section by specification.
//
Procedure DistributeTabularSectionBySpecification(OnLine, TemporaryTableDistribution, ProductionSpecification) Export
    
	Query = New Query(
	"SELECT
	|	MAX(SpecificationsContent.LineNumber) AS SpecificationsContentLineNumber,
	|	SpecificationsContent.ProductsAndServices AS ProductsAndServices,
	|	SpecificationsContent.ContentRowType AS ContentRowType,
	|	CASE
	|		WHEN &UseCharacteristics
	|			THEN SpecificationsContent.Characteristic
	|		ELSE VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	|	END AS Characteristic,
	|	SpecificationsContent.MeasurementUnit AS MeasurementUnit,
	|	SpecificationsContent.Specification AS Specification,
	|	SUM(CASE
	|			WHEN VALUETYPE(&MeasurementUnit) = Type(Catalog.UOMClassifier)
	|				THEN SpecificationsContent.Quantity / SpecificationsContent.ProductsQuantity * &Quantity
	|			ELSE SpecificationsContent.Quantity / SpecificationsContent.ProductsQuantity * &Factor * &Quantity
	|		END) AS Quantity,
	|	&Products AS Products,
	|	&ProductCharacteristic AS ProductCharacteristic,
	|	&ProductionBatch AS ProductionBatch,
	|	&CustomerOrder AS CustomerOrder
	|FROM
	|	Catalog.Specifications.Content AS SpecificationsContent
	|WHERE
	|	SpecificationsContent.Ref = &Specification
	|	AND SpecificationsContent.ProductsAndServices.ProductsAndServicesType = &ProductsAndServicesType
	|
	|GROUP BY
	|	SpecificationsContent.ProductsAndServices,
	|	CASE
	|		WHEN &UseCharacteristics
	|			THEN SpecificationsContent.Characteristic
	|		ELSE VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	|	END,
	|	SpecificationsContent.MeasurementUnit,
	|	SpecificationsContent.Specification,
	|	SpecificationsContent.ContentRowType,
	|	SpecificationsContent.CostPercentage
	|
	|ORDER BY
	|	SpecificationsContentLineNumber");
	
	Query.SetParameter("UseCharacteristics", Constants.FunctionalOptionUseCharacteristics.Get());
	Query.SetParameter("ProcessingDate", EndOfDay(Date));
	
	Query.SetParameter("Products", 					OnLine.Products);
	Query.SetParameter("ProductCharacteristic", 	OnLine.ProductCharacteristic);
	Query.SetParameter("ProductionBatch", 			OnLine.ProductionBatch);
	Query.SetParameter("CustomerOrder", 			OnLine.CustomerOrder);
	    	
	Query.SetParameter("Specification", OnLine.Specification);
	Query.SetParameter("Quantity", OnLine.Quantity);
	
	Query.SetParameter("MeasurementUnit", OnLine.MeasurementUnit);
	
	If TypeOf(OnLine.MeasurementUnit) = Type("CatalogRef.UOMClassifier") Then
    	Query.SetParameter("Factor", 1);
	Else
		Query.SetParameter("Factor", OnLine.MeasurementUnit.Factor);
	EndIf;
	
	Query.SetParameter("ProductsAndServicesType", Enums.ProductsAndServicesTypes.InventoryItem);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		If Selection.ContentRowType = Enums.SpecificationContentRowTypes.Node Then
			
			DistributeTabularSectionBySpecification(Selection, TemporaryTableDistribution, ProductionSpecification);
			
		Else
			
	    	NewRow = TemporaryTableDistribution.Add();
			FillPropertyValues(NewRow, Selection);
			NewRow.ProductionSpecification = ProductionSpecification;
			
		EndIf;
		
   EndDo;

EndProcedure // DistributeTabularSectionBySpecification()

// Procedure fills inventory according to standards.
//
Procedure RunInventoryFillingByBalance() Export
	
	Inventory.Clear();
	
	Query = New Query;
	Query.Text =
    "SELECT
    |	SUM(InventoryBalances.QuantityBalance) AS Quantity,
    |	SUM(CASE
    |			WHEN InventoryBalances.CustomerOrder <> VALUE(Document.CustomerOrder.EmptyRef)
    |				THEN InventoryBalances.QuantityBalance
    |			ELSE 0
    |		END) AS Reserve,
    |	ISNULL(InventoryBalances.ProductsAndServices, VALUE(Catalog.ProductsAndServices.EmptyRef)) AS ProductsAndServices,
    |	InventoryBalances.Characteristic AS Characteristic,
    |	InventoryBalances.Batch AS Batch,
    |	InventoryBalances.ProductsAndServices.MeasurementUnit AS MeasurementUnit,
    |	InventoryBalances.CustomerOrder AS CustomerOrder,
    |	InventoryBalances.Company AS Company,
    |	InventoryBalances.StructuralUnit AS StructuralUnit
    |FROM
    |	AccumulationRegister.Inventory.Balance(&ProcessingDate) AS InventoryBalances
    |WHERE
    |	InventoryBalances.QuantityBalance > 0
    |	AND InventoryBalances.ProductsAndServices <> VALUE(Catalog.ProductsAndServices.EmptyRef)
    |	AND InventoryBalances.Company = &Company
    |	AND InventoryBalances.StructuralUnit = &StructuralUnit
    |
    |GROUP BY
    |	InventoryBalances.Batch,
    |	InventoryBalances.ProductsAndServices,
    |	InventoryBalances.Characteristic,
    |	InventoryBalances.ProductsAndServices.MeasurementUnit,
    |	InventoryBalances.Company,
    |	InventoryBalances.StructuralUnit,
    |	InventoryBalances.CustomerOrder";
	
	Query.SetParameter("ProcessingDate", EndOfDay(Date));
	Query.SetParameter("Company", SmallBusinessServer.GetCompany(Company));
	Query.SetParameter("StructuralUnit", StructuralUnit);
	
	ConnectionKey = 0;
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		NewRow = Inventory.Add();
		FillPropertyValues(NewRow, Selection);
        NewRow.ConnectionKey = ConnectionKey;
		
		ConnectionKey = ConnectionKey + 1;
		
	EndDo;	
	
EndProcedure // RunInventoryFillingByBalance()

// Procedure fills expenses according to balances.
//
Procedure RunExpenseFillingByBalance() Export
	
	Costs.Clear();
	
	Query = New Query;
	Query.Text =
    "SELECT
    |	SUM(InventoryBalances.AmountBalance) AS Amount,
    |	InventoryBalances.GLAccount AS GLExpenseAccount,
    |	InventoryBalances.CustomerOrder AS CustomerOrder
    |FROM
    |	AccumulationRegister.Inventory.Balance(
    |			&ProcessingDate,
    |			Company = &Company
    |				AND StructuralUnit = &StructuralUnit
    |				AND ProductsAndServices = VALUE(Catalog.ProductsAndServices.EmptyRef)
    |				AND GLAccount.TypeOfAccount = VALUE(Enum.GLAccountsTypes.UnfinishedProduction)
    |				) AS InventoryBalances
    |WHERE
    |	InventoryBalances.AmountBalance > 0
    |
    |GROUP BY
    |	InventoryBalances.GLAccount,
    |	InventoryBalances.CustomerOrder";
	
	Query.SetParameter("ProcessingDate", EndOfDay(Date));
	Query.SetParameter("Company", SmallBusinessServer.GetCompany(Company));
	Query.SetParameter("StructuralUnit", StructuralUnit);
	
	ConnectionKey = 0;
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		NewRow = Costs.Add();
		FillPropertyValues(NewRow, Selection);
        NewRow.ConnectionKey = ConnectionKey;
		
		ConnectionKey = ConnectionKey + 1;
		
	EndDo;
	
EndProcedure // RunExpenseFillingByBalance()

////////////////////////////////////////////////////////////////////////////////
// EVENT HANDLERS

// Procedure - event handler FillingProcessor object.
//
Procedure Filling(FillingData, StandardProcessing) Export
	
	If Not ValueIsFilled(FillingData) Then
		Return;
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure") Then
		FillPropertyValues(ThisObject, FillingData);
	EndIf;
	
EndProcedure // FillingProcessor()

// Procedure - event handler FillCheckProcessing object.
//
Procedure FillCheckProcessing(Cancel, CheckedAttributes)

	If DataExchange.Load Then
		Return;
	EndIf;
			
EndProcedure // FillCheckProcessing()

// Procedure - event handler Posting object.
//
Procedure Posting(Cancel, PostingMode)

EndProcedure // Posting()

// Procedure - event handler UndoPosting object.
//
Procedure UndoPosting(Cancel)

EndProcedure // UndoPosting()

#EndIf