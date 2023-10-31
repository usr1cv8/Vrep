
#Region ProgramInterface

Procedure FillConnectionKeys(Table, AttributeName = "ConnectionKey") Export
	
	MaxVal = 0;
	For Each TabSecRow In Table Do
		If TabSecRow[AttributeName]>MaxVal Then
			MaxVal = TabSecRow[AttributeName];
		EndIf; 
	EndDo;
	
	For Each TabSecRow In Table Do
		If TabSecRow[AttributeName]<>0 Then
			Continue;
		EndIf; 
		MaxVal = MaxVal+1;
		TabSecRow[AttributeName] = MaxVal;
	EndDo; 
	
EndProcedure

Procedure DistribInventory(Products, Inventory, InventoryDistribution, CompletedStages = Undefined, ProductionOrder = Undefined) Export
	
	FillConnectionKeys(Products); 
	FillConnectionKeys(Inventory); 
	
	If TypeOf(Products)<>Type("ValueTable") Then
		ProductsTable = Products.Unload();
	Else
		ProductsTable = Products;
	EndIf; 
	If TypeOf(Inventory)<>Type("ValueTable") Then
		InventoryTab = Inventory.Unload();
	Else
		InventoryTab = Inventory;
	EndIf;
	
	ItsDisassembly = (ValueIsFilled(ProductionOrder) 
	And TypeOf(ProductionOrder)=Type("ДокументСсылка.ProductionOrder") 
	And CommonUse.ObjectAttributeValue(ProductionOrder, "OperationKind")=Enums.OperationKindsProductionOrder.Disassembly);
	
	SpecificationContent = SpecificationContent(ProductsTable, True);
	If ProductionOrder = Documents.ProductionOrder.EmptyRef() Then
		For Each ContentRow In SpecificationContent Do
			If (Not ValueIsFilled(ContentRow.CustomerOrder) Or ItsDisassembly) And ValueIsFilled(ContentRow.Stage) Then
				// Поэтапное производство вожножно только под заказ
				ContentRow.Stage = Catalogs.ProductionStages.EmptyRef();
			EndIf; 
		EndDo; 
	EndIf; 
	SpecificationContent.GroupBy("ConnectionKey, Stage, ProductsAndServicesContent, CharacteristicContent", "QuantityContent");
	If InventoryTab.Columns.Find("Cell")=Undefined Then
		InventoryTab.Columns.Add("Cell", New TypeDescription("СправочникСсылка.Cells"))
	EndIf;
	
	If GetFunctionalOption("UseProductionStages") And CompletedStages<>Undefined Then
		If TypeOf(CompletedStages)<>Type("ValueTable") Then
			StageTable = CompletedStages.Unload();
		Else
			StageTable = CompletedStages;
		EndIf;
	Else
		StageTable = SpecificationContent.Copy(, "ConnectionKey, Stage");
	EndIf; 
	StageTable.GroupBy("ConnectionKey, Stage");
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Products", ProductsTable);
	Query.SetParameter("Inventory", InventoryTab);
	Query.SetParameter("SpecificationContent", SpecificationContent);
	Query.SetParameter("Stages", StageTable);
	Query.Text = 
	"SELECT
	|	Products.ProductsAndServices AS ProductsAndServices,
	|	Products.Characteristic AS Characteristic,
	|	Products.Specification AS Specification,
	|	Products.CustomerOrder AS CustomerOrder,
	|	Products.Quantity AS Quantity,
	|	Products.ConnectionKey AS ConnectionKey
	|INTO Products
	|FROM
	|	&Products AS Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Inventory.Stage AS Stage,
	|	Inventory.LineNumber AS LineNumber,
	|	CAST(Inventory.ProductsAndServices AS Catalog.ProductsAndServices) AS ProductsAndServices,
	|	Inventory.Characteristic AS Characteristic,
	|	Inventory.Specification AS Specification,
	|	Inventory.Batch AS Batch,
	|	Inventory.CustomerOrder AS CustomerOrder,
	|	Inventory.Quantity AS Quantity,
	|	Inventory.MeasurementUnit AS MeasurementUnit,
	|	Inventory.StructuralUnit AS StructuralUnit,
	|	Inventory.Cell AS Cell,
	|	Inventory.ConnectionKey AS ConnectionKey
	|INTO Inventory
	|FROM
	|	&Inventory AS Inventory
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SpecificationContent.Stage AS Stage,
	|	SpecificationContent.ProductsAndServicesContent AS ProductsAndServicesContent,
	|	SpecificationContent.CharacteristicContent AS CharacteristicContent,
	|	SpecificationContent.QuantityContent AS QuantityContent,
	|	SpecificationContent.ConnectionKey AS ConnectionKey
	|INTO SpecificationContent
	|FROM
	|	&SpecificationContent AS SpecificationContent
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Stages.Stage AS Stage,
	|	Stages.ConnectionKey AS ConnectionKey
	|INTO Stages
	|FROM
	|	&Stages AS Stages
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Products.ProductsAndServices AS ProductsAndServices,
	|	Products.Characteristic AS Characteristic,
	|	Products.Specification AS Specification,
	|	Products.CustomerOrder AS CustomerOrder,
	|	Products.Quantity AS Quantity,
	|	Products.ConnectionKey AS ConnectionKey,
	|	ISNULL(Stages.Stage, VALUE(Catalog.ProductionStages.EmptyRef)) AS Stage
	|INTO ProductsStages
	|FROM
	|	Products AS Products
	|		LEFT JOIN Stages AS Stages
	|		ON Products.ConnectionKey = Stages.ConnectionKey
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Products.CustomerOrder AS CustomerOrder,
	|	Products.ConnectionKey AS ConnectionKey,
	|	SpecificationContent.Stage AS Stage,
	|	SpecificationContent.ProductsAndServicesContent AS ProductsAndServicesContent,
	|	SpecificationContent.CharacteristicContent AS CharacteristicContent,
	|	SpecificationContent.QuantityContent AS QuantityContent
	|INTO ProductsAndContent
	|FROM
	|	Products AS Products
	|		LEFT JOIN SpecificationContent AS SpecificationContent
	|		ON Products.ConnectionKey = SpecificationContent.ConnectionKey
	|WHERE
	|	NOT SpecificationContent.ConnectionKey IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SpecificationContent.ProductsAndServicesContent AS ProductsAndServicesContent,
	|	SpecificationContent.CharacteristicContent AS CharacteristicContent,
	|	ProductsStages.CustomerOrder AS CustomerOrder,
	|	ProductsStages.Stage AS Stage,
	|	SUM(SpecificationContent.QuantityContent) AS QuantityContent
	|INTO BaseByContent
	|FROM
	|	SpecificationContent AS SpecificationContent
	|		LEFT JOIN ProductsStages AS ProductsStages
	|		ON SpecificationContent.ConnectionKey = ProductsStages.ConnectionKey
	|			AND SpecificationContent.Stage = ProductsStages.Stage
	|
	|GROUP BY
	|	SpecificationContent.ProductsAndServicesContent,
	|	SpecificationContent.CharacteristicContent,
	|	ProductsStages.CustomerOrder,
	|	ProductsStages.Stage
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Products.CustomerOrder AS CustomerOrder,
	|	SUM(Products.Quantity) AS Quantity
	|INTO BaseByProductsQuantity
	|FROM
	|	Products AS Products
	|
	|GROUP BY
	|	Products.CustomerOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductsAndContent.ConnectionKey AS ConnectionKeyProduction,
	|	ProductsAndContent.Stage AS Stage,
	|	TQInventory.ProductsAndServices AS ProductsAndServices,
	|	TQInventory.Characteristic AS Characteristic,
	|	TQInventory.MeasurementUnit AS MeasurementUnit,
	|	TQInventory.CustomerOrder AS CustomerOrder,
	|	SUM(CAST(CASE
	|				WHEN ISNULL(BaseByContent.QuantityContent, 0) = 0
	|					THEN 0
	|				ELSE TQInventory.Quantity / ISNULL(BaseByContent.QuantityContent, 0) * ProductsAndContent.QuantityContent
	|			END AS NUMBER(15, 3))) AS Quantity,
	|	TQInventory.LineNumber AS LineNumber
	|INTO InventoryDistributed
	|FROM
	|	ProductsAndContent AS ProductsAndContent
	|		LEFT JOIN (SELECT
	|			Inventory.Stage AS Stage,
	|			Inventory.ProductsAndServices AS ProductsAndServices,
	|			Inventory.Characteristic AS Characteristic,
	|			Inventory.MeasurementUnit AS MeasurementUnit,
	|			Inventory.CustomerOrder AS CustomerOrder,
	|			SUM(Inventory.Quantity) AS Quantity,
	|			MIN(Inventory.LineNumber) AS LineNumber
	|		FROM
	|			Inventory AS Inventory
	|		WHERE
	|			(Inventory.ProductsAndServices, Inventory.Characteristic, Inventory.CustomerOrder) IN
	|					(SELECT
	|						BaseByContent.ProductsAndServicesContent,
	|						BaseByContent.CharacteristicContent,
	|						BaseByContent.CustomerOrder
	|					FROM
	|						BaseByContent)
	|		
	|		GROUP BY
	|			Inventory.Characteristic,
	|			Inventory.ProductsAndServices,
	|			Inventory.MeasurementUnit,
	|			Inventory.Stage,
	|			Inventory.CustomerOrder) AS TQInventory
	|		ON ProductsAndContent.ProductsAndServicesContent = TQInventory.ProductsAndServices
	|			AND ProductsAndContent.CharacteristicContent = TQInventory.Characteristic
	|			AND ProductsAndContent.CustomerOrder = TQInventory.CustomerOrder
	|			AND ProductsAndContent.Stage = TQInventory.Stage
	|		LEFT JOIN BaseByContent AS BaseByContent
	|		ON ProductsAndContent.ProductsAndServicesContent = BaseByContent.ProductsAndServicesContent
	|			AND ProductsAndContent.CharacteristicContent = BaseByContent.CharacteristicContent
	|			AND ProductsAndContent.CustomerOrder = BaseByContent.CustomerOrder
	|			AND ProductsAndContent.Stage = BaseByContent.Stage
	|WHERE
	|	NOT TQInventory.ProductsAndServices IS NULL
	|
	|GROUP BY
	|	ProductsAndContent.ConnectionKey,
	|	ProductsAndContent.Stage,
	|	TQInventory.ProductsAndServices,
	|	TQInventory.Characteristic,
	|	TQInventory.MeasurementUnit,
	|	TQInventory.CustomerOrder,
	|	TQInventory.LineNumber
	|
	|UNION ALL
	|
	|SELECT
	|	Products.ConnectionKey,
	|	TQInventory.Stage,
	|	TQInventory.ProductsAndServices,
	|	TQInventory.InventoryAssembly,
	|	TQInventory.MeasurementUnit,
	|	TQInventory.CustomerOrder,
	|	SUM(CAST(CASE
	|				WHEN ISNULL(BaseByProductsQuantity.Quantity, 0) = 0
	|					THEN 0
	|				ELSE TQInventory.Quantity / ISNULL(BaseByProductsQuantity.Quantity, 0) * Products.Quantity
	|			END AS NUMBER(15, 3))),
	|	TQInventory.LineNumber
	|FROM
	|	Products AS Products
	|		LEFT JOIN (SELECT
	|			Inventory.Stage AS Stage,
	|			Inventory.ProductsAndServices AS ProductsAndServices,
	|			Inventory.Characteristic AS InventoryAssembly,
	|			Inventory.MeasurementUnit AS MeasurementUnit,
	|			Inventory.CustomerOrder AS CustomerOrder,
	|			SUM(Inventory.Quantity) AS Quantity,
	|			MIN(Inventory.LineNumber) AS LineNumber
	|		FROM
	|			Inventory AS Inventory
	|		WHERE
	|			NOT (Inventory.ProductsAndServices, Inventory.Characteristic, Inventory.CustomerOrder) IN
	|						(SELECT
	|							BaseByContent.ProductsAndServicesContent,
	|							BaseByContent.CharacteristicContent,
	|							BaseByContent.CustomerOrder
	|						FROM
	|							BaseByContent)
	|		
	|		GROUP BY
	|			Inventory.CustomerOrder,
	|			Inventory.MeasurementUnit,
	|			Inventory.Characteristic,
	|			Inventory.ProductsAndServices,
	|			Inventory.Stage) AS TQInventory
	|		ON Products.CustomerOrder = TQInventory.CustomerOrder
	|		LEFT JOIN BaseByProductsQuantity AS BaseByProductsQuantity
	|		ON Products.CustomerOrder = BaseByProductsQuantity.CustomerOrder
	|WHERE
	|	NOT TQInventory.ProductsAndServices IS NULL
	|
	|GROUP BY
	|	Products.ConnectionKey,
	|	TQInventory.Stage,
	|	TQInventory.ProductsAndServices,
	|	TQInventory.CustomerOrder,
	|	TQInventory.InventoryAssembly,
	|	TQInventory.MeasurementUnit,
	|	TQInventory.LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryDistributed.ConnectionKeyProduction AS ConnectionKeyProduct,
	|	0 AS ConnectionKeyInventory,
	|	InventoryDistributed.Stage AS Stage,
	|	InventoryDistributed.ProductsAndServices AS ProductsAndServices,
	|	InventoryDistributed.Characteristic AS Characteristic,
	|	InventoryDistributed.MeasurementUnit AS MeasurementUnit,
	|	VALUE(Catalog.ProductsAndServicesBatches.EmptyRef) AS Batch,
	|	VALUE(Catalog.Specifications.EmptyRef) AS Specification,
	|	InventoryDistributed.CustomerOrder AS CustomerOrder,
	|	VALUE(Catalog.StructuralUnits.EmptyRef) AS StructuralUnit,
	|	VALUE(Catalog.Cells.EmptyRef) AS Cell,
	|	InventoryDistributed.Quantity AS Quantity,
	|	InventoryDistributed.ProductsAndServices.UseCharacteristics AS UseCharacteristics
	|FROM
	|	InventoryDistributed AS InventoryDistributed
	|
	|ORDER BY
	|	InventoryDistributed.LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TQRounding.CustomerOrder AS CustomerOrder,
	|	TQRounding.Stage AS Stage,
	|	TQRounding.ProductsAndServices AS ProductsAndServices,
	|	TQRounding.Characteristic AS Characteristic,
	|	TQRounding.MeasurementUnit AS MeasurementUnit,
	|	SUM(TQRounding.Quantity) AS Quantity
	|FROM
	|	(SELECT
	|		InventoryDistributed.CustomerOrder AS CustomerOrder,
	|		InventoryDistributed.Stage AS Stage,
	|		InventoryDistributed.ProductsAndServices AS ProductsAndServices,
	|		InventoryDistributed.Characteristic AS Characteristic,
	|		InventoryDistributed.MeasurementUnit AS MeasurementUnit,
	|		-InventoryDistributed.Quantity AS Quantity
	|	FROM
	|		InventoryDistributed AS InventoryDistributed
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Inventory.CustomerOrder,
	|		Inventory.Stage,
	|		Inventory.ProductsAndServices,
	|		Inventory.Characteristic,
	|		Inventory.MeasurementUnit,
	|		Inventory.Quantity
	|	FROM
	|		Inventory AS Inventory) AS TQRounding
	|
	|GROUP BY
	|	TQRounding.CustomerOrder,
	|	TQRounding.Stage,
	|	TQRounding.ProductsAndServices,
	|	TQRounding.Characteristic,
	|	TQRounding.MeasurementUnit
	|
	|HAVING
	|	SUM(TQRounding.Quantity) <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Inventory.Stage AS Stage,
	|	Inventory.ProductsAndServices AS ProductsAndServices,
	|	Inventory.Characteristic AS Characteristic,
	|	Inventory.Specification AS Specification,
	|	Inventory.Batch AS Batch,
	|	Inventory.CustomerOrder AS CustomerOrder,
	|	Inventory.Quantity AS Quantity,
	|	Inventory.MeasurementUnit AS MeasurementUnit,
	|	Inventory.StructuralUnit AS StructuralUnit,
	|	Inventory.Cell AS Cell,
	|	Inventory.ConnectionKey AS ConnectionKeyInventory
	|FROM
	|	Inventory AS Inventory";
	Result = Query.ExecuteBatch();
	
	DistributionTable = Result.Get(9).Unload();
	InventoryTab = Result.Get(11).Unload();
	
	// Проверка ошибок округления. Расхождение добавляется к строке с максимальным значением 
	RoundingSelection = Result.Get(10).Select();
	While RoundingSelection.Next() Do
		FilterStructure = New Structure;
		FilterStructure.Insert("CustomerOrder", RoundingSelection.CustomerOrder);
		FilterStructure.Insert("Stage", RoundingSelection.Stage);
		FilterStructure.Insert("ProductsAndServices", RoundingSelection.ProductsAndServices);
		FilterStructure.Insert("Characteristic", RoundingSelection.Characteristic);
		FilterStructure.Insert("MeasurementUnit", RoundingSelection.MeasurementUnit);
		Rows = DistributionTable.FindRows(FilterStructure);
		If RoundingSelection.Quantity<>0 Then
			TakeRounding(Rows, RoundingSelection.Quantity, "Quantity");
		EndIf; 
	EndDo;
	
	Result = DistributionTable.CopyColumns();
	For Each DistributionRow In DistributionTable Do
		Disrtribute = DistributionRow.Quantity;
		FilterStructure = New Structure;
		FilterStructure.Insert("CustomerOrder", DistributionRow.CustomerOrder);
		FilterStructure.Insert("Stage", DistributionRow.Stage);
		FilterStructure.Insert("ProductsAndServices", DistributionRow.ProductsAndServices);
		FilterStructure.Insert("Characteristic", DistributionRow.Characteristic);
		FilterStructure.Insert("MeasurementUnit", DistributionRow.MeasurementUnit);
		Rows = InventoryTab.FindRows(FilterStructure);
		For Each InventoryRow In Rows Do
			If InventoryRow.Quantity<=0 Then
				Continue;
			EndIf; 
			Quantity = Min(Disrtribute, InventoryRow.Quantity);
			InventoryRow.Quantity = InventoryRow.Quantity - Quantity;
			Disrtribute = Disrtribute - Quantity;
			NewRow = Result.Add();
			FillPropertyValues(NewRow, DistributionRow);
			FillPropertyValues(NewRow, InventoryRow);
			NewRow.Quantity = Quantity;
			If Disrtribute<=0 Then
				Break;
			EndIf; 
		EndDo; 
	EndDo;
	
	If TypeOf(InventoryDistribution)<>Type("ValueTable") Then
		InventoryDistribution.Load(Result);
	Else
		InventoryDistribution = Result;
	EndIf; 
	
EndProcedure

Procedure FillByDistribution(Inventory, InventoryDistribution) Export
	
	DistributionTable = InventoryDistribution.Unload();
	NoCells = (DistributionTable.Columns.Find("Cell")=Undefined);
	If NoCells Then
		DistributionTable.Columns.Add("Cell", New TypeDescription("СправочникСсылка.Cells"));
	EndIf; 
	
	Query = New Query;
	Query.SetParameter("DistributionTable", DistributionTable);
	Query.Text =
	"SELECT
	|	DistributionTable.Stage AS Stage,
	|	CAST(DistributionTable.ProductsAndServices AS Catalog.ProductsAndServices) AS ProductsAndServices,
	|	DistributionTable.Characteristic AS Characteristic,
	|	DistributionTable.Batch AS Batch,
	|	DistributionTable.MeasurementUnit AS MeasurementUnit,
	|	DistributionTable.Specification AS Specification,
	|	DistributionTable.StructuralUnit AS StructuralUnit,
	|	DistributionTable.Cell AS Cell,
	|	DistributionTable.CustomerOrder AS CustomerOrder,
	|	DistributionTable.Quantity AS Quantity
	|INTO DistributionTable
	|FROM
	|	&DistributionTable AS DistributionTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DistributionTable.Stage AS Stage,
	|	DistributionTable.ProductsAndServices AS ProductsAndServices,
	|	DistributionTable.Characteristic AS Characteristic,
	|	DistributionTable.Batch AS Batch,
	|	DistributionTable.MeasurementUnit AS MeasurementUnit,
	|	DistributionTable.Specification AS Specification,
	|	DistributionTable.StructuralUnit AS StructuralUnit,
	|	DistributionTable.Cell AS Cell,
	|	DistributionTable.CustomerOrder AS CustomerOrder,
	|	SUM(DistributionTable.Quantity) AS Quantity,
	|	1 AS CostPercentag,
	|	DistributionTable.ProductsAndServices.CountryOfOrigin AS CountryOfOrigin
	|FROM
	|	DistributionTable AS DistributionTable
	|
	|GROUP BY
	|	DistributionTable.Stage,
	|	DistributionTable.ProductsAndServices,
	|	DistributionTable.Characteristic,
	|	DistributionTable.Batch,
	|	DistributionTable.MeasurementUnit,
	|	DistributionTable.Specification,
	|	DistributionTable.StructuralUnit,
	|	DistributionTable.Cell,
	|	DistributionTable.CustomerOrder,
	|	DistributionTable.ProductsAndServices.CountryOfOrigin";
	
	Inventory.Load(Query.Execute().Unload());
	
EndProcedure

Function JoinInventoryAndDistribution(DocumentRef) Export
	
	Query = New Query;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	InventoryAssemblyInventory.Stage AS Stage,
	|	InventoryAssemblyInventory.ProductsAndServices AS ProductsAndServices,
	|	InventoryAssemblyInventory.Characteristic AS Characteristic,
	|	InventoryAssemblyInventory.Batch AS Batch,
	|	InventoryAssemblyInventory.MeasurementUnit AS MeasurementUnit,
	|	InventoryAssemblyInventory.Specification AS Specification,
	|	InventoryAssemblyInventory.StructuralUnit AS StructuralUnit,
	|	InventoryAssemblyInventory.Cell AS Cell,
	|	InventoryAssemblyInventory.CustomerOrder AS CustomerOrder,
	|	InventoryAssemblyInventory.CountryOfOrigin AS CountryOfOrigin,
	|	InventoryAssemblyInventory.CCDNo AS CCDNo,
	|	SUM(InventoryAssemblyInventory.Reserve) AS Reserve,
	|	SUM(InventoryAssemblyInventory.CostPercentage) AS CostPercentage,
	|	SUM(InventoryAssemblyInventory.Quantity) AS Quantity
	|FROM
	|	Document.InventoryAssembly.Inventory AS InventoryAssemblyInventory
	|WHERE
	|	InventoryAssemblyInventory.Ref = &Ref
	|
	|GROUP BY
	|	InventoryAssemblyInventory.Stage,
	|	InventoryAssemblyInventory.Batch,
	|	InventoryAssemblyInventory.MeasurementUnit,
	|	InventoryAssemblyInventory.ProductsAndServices,
	|	InventoryAssemblyInventory.Specification,
	|	InventoryAssemblyInventory.Cell,
	|	InventoryAssemblyInventory.Characteristic,
	|	InventoryAssemblyInventory.StructuralUnit,
	|	InventoryAssemblyInventory.CustomerOrder,
	|	InventoryAssemblyInventory.CountryOfOrigin,
	|	InventoryAssemblyInventory.CCDNo
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryAssemblyInventoryDistribution.Ref AS Ref,
	|	InventoryAssemblyInventoryDistribution.Stage AS Stage,
	|	InventoryAssemblyInventoryDistribution.LineNumber AS LineNumber,
	|	InventoryAssemblyInventoryDistribution.ConnectionKeyProduct AS ConnectionKeyProduct,
	|	InventoryAssemblyInventoryDistribution.ProductsAndServices AS ProductsAndServices,
	|	InventoryAssemblyInventoryDistribution.Characteristic AS Characteristic,
	|	InventoryAssemblyInventoryDistribution.Batch AS Batch,
	|	InventoryAssemblyInventoryDistribution.MeasurementUnit AS MeasurementUnit,
	|	InventoryAssemblyInventoryDistribution.Specification AS Specification,
	|	InventoryAssemblyInventoryDistribution.StructuralUnit AS StructuralUnit,
	|	InventoryAssemblyInventoryDistribution.Cell AS Cell,
	|	InventoryAssemblyInventoryDistribution.CustomerOrder AS CustomerOrder,
	|	Value(Catalog.WorldCountries.EmptyRef) КАК CountryOfOrigin,
	|	Value(Catalog.CCDNumbers.EmptyRef) КАК CCDNo,
	|	InventoryAssemblyInventoryDistribution.Quantity AS Quantity,
	|	0 AS Reserve,
	|	0 AS CostPercentage,
	|	FALSE AS Distributed
	|FROM
	|	Document.InventoryAssembly.InventoryDistribution AS InventoryAssemblyInventoryDistribution
	|WHERE
	|	InventoryAssemblyInventoryDistribution.Ref = &Ref";
	
	Result = Query.ExecuteBatch();
	InventorySelection = Result.Get(0).Select();
	DistribTable = Result.Get(1).Unload();
	
	While InventorySelection.Next() Do
		FilterStructure = New Structure("Stage, ProductsAndServices, Characteristic, Batch, Specification, MeasurementUnit, StructuralUnit, Cell, CustomerOrder");
		FillPropertyValues(FilterStructure, InventorySelection);
		FilterStructure.Insert("Distributed", False);
		DistributionRows = DistribTable.FindRows(FilterStructure);
		QuantityDistribute = InventorySelection.Quantity;
		ReserveDistribute = InventorySelection.Reserve;
		DistributionCostPercentage = InventorySelection.CostPercentage;
		For Each DistribRow In DistributionRows Do
			If QuantityDistribute=DistribRow.Quantity Then
				DistribRow.Reserve = ReserveDistribute;
				DistribRow.CostPercentage = DistributionCostPercentage;
				FillPropertyValues(DistribRow, InventorySelection, "CountryOfOrigin, CCDNo");
				DistribRow.Distributed = True;
				Break;
			ElsIf QuantityDistribute>DistribRow.Quantity Then
				DistribRow.Reserve = Min(ReserveDistribute, DistribRow.Quantity);
				If QuantityDistribute<>0 Then
					DistribRow.CostPercentage = DistributionCostPercentage * DistribRow.Quantity / QuantityDistribute;
				EndIf; 
				FillPropertyValues(DistribRow, InventorySelection, "CountryOfOrigin, CCDNo");
				DistribRow.Distributed = True;
				QuantityDistribute = QuantityDistribute-DistribRow.Quantity;
				ReserveDistribute = ReserveDistribute-DistribRow.Reserve;
				DistributionCostPercentage = DistributionCostPercentage-DistribRow.CostPercentage;
			ElsIf QuantityDistribute<DistribRow.Quantity Then
				NewRow = DistribTable.Add();
				FillPropertyValues(NewRow, DistribRow);
				NewRow.Quantity = QuantityDistribute;
				NewRow.Reserve = ReserveDistribute;
				NewRow.CostPercentage = DistributionCostPercentage;
				FillPropertyValues(DistribRow, InventorySelection, "CountryOfOrigin, CCDNo");
				NewRow.Distributed = True;
				DistribRow.Quantity = DistribRow.Quantity-NewRow.Quantity;
				Break;
			EndIf; 
		EndDo; 
	EndDo; 
	
	DistribTable.Sort("LineNumber");
	Return DistribTable;
	
EndFunction

Function ProductionStagesOfSpecifications(Specifications) Export
	
	If TypeOf(Specifications)<>Type("Array") Then
		SpecificationArray = CommonUseClientServer.ValueInArray(Specifications); 
	Else
		SpecificationArray = Specifications;
	EndIf; 
	
	Query = New Query;
	Query.SetParameter("Specs", SpecificationArray);
	Query.Text = 
	"SELECT
	|	ProductionKindsStages.Stage AS Stage,
	|	MIN(ProductionKindsStages.LineNumber) AS LineNumber
	|FROM
	|	Catalog.Specifications AS Specifications
	|		LEFT JOIN Catalog.ProductionKinds.Stages AS ProductionKindsStages
	|		ON Specifications.ProductionKind = ProductionKindsStages.Ref
	|WHERE
	|	Specifications.Ref IN(&Specs)
	|
	|GROUP BY
	|	ProductionKindsStages.Stage
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	VALUE(Catalog.ProductionStages.EmptyRef),
	|	0
	|FROM
	|	Catalog.Specifications AS Specifications
	|WHERE
	|	Specifications.ProductionKind = VALUE(Catalog.ProductionKinds.EmptyRef)
	|	AND (Specifications.Ref IN (&Specs)
	|			OR VALUE(Catalog.Specifications.EmptyRef) IN (&Specs))
	|
	|HAVING
	|	COUNT(DISTINCT Specifications.Ref) > 0
	|
	|ORDER BY
	|	LineNumber";
	StagesArray = Query.Execute().Unload().UnloadColumn("Stage");
	If StagesArray.Count()=0 Then
		StagesArray.Add(Catalogs.ProductionStages.EmptyRef());
	EndIf; 
	Return StagesArray;
	
EndFunction

// Возвращает массив этапов производства спецификаций.
//
// Parameters:
//  Specifications - CatalogRef.Specifications, Array - Спецификация / массив спецификаций, для которых нужно определить используемые этапы производства
// Returns:
//  Array - Массив ссылок на этапы производства (СправочникСсылка.ЭтапыПроизводства), которые будут пройдены при производстве по заданным спецификациям.
//
Function SpecificationProductionStages(Specifications) Export
	
	If TypeOf(Specifications)<>Type("Array") Then
		ArraySpecification = CommonUseClientServer.ValueInArray(Specifications); 
	Else
		ArraySpecification = Specifications;
	EndIf; 
	
	Query = New Query;
	Query.SetParameter("Specifications", ArraySpecification);
	Query.Text = 
	"SELECT
	|	ProductionKindsStages.Stage AS Stage,
	|	MIN(ProductionKindsStages.LineNumber) AS LineNumber
	|FROM
	|	Catalog.Specifications AS Specifications
	|		LEFT JOIN Catalog.ProductionKinds.Stages AS ProductionKindsStages
	|		ON Specifications.ProductionKind = ProductionKindsStages.Ref
	|WHERE
	|	Specifications.Ref IN(&Specifications)
	|
	|GROUP BY
	|	ProductionKindsStages.Stage
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	VALUE(Catalog.ProductionStages.EmptyRef),
	|	0
	|FROM
	|	Catalog.Specifications AS Specifications
	|WHERE
	|	Specifications.ProductionKind = VALUE(Catalog.ProductionKinds.EmptyRef)
	|	AND (Specifications.Ref IN (&Specifications)
	|			OR VALUE(Catalog.Specifications.EmptyRef) IN (&Specifications))
	|
	|HAVING
	|	COUNT(DISTINCT Specifications.Ref) > 0
	|
	|ORDER BY
	|	LineNumber";
	StagesArray = Query.Execute().Unload().UnloadColumn("Stage");
	If StagesArray.Count()=0 Then
		StagesArray.Add(Catalogs.ProductionStages.EmptyRef());
	EndIf; 
	Return StagesArray;
	
EndFunction


Function SpecificationsWithProductionStages(Specifications) Export
	
	Query = New Query;
	Query.SetParameter("Specifications", Specifications);
	Query.Text =
	"SELECT
	|	Specifications.Ref AS Ref
	|FROM
	|	Catalog.Specifications AS Specifications
	|WHERE
	|	Specifications.Ref IN(&Specifications)
	|	AND Specifications.ProductionKind <> VALUE(Catalog.ProductionKinds.EmptyRef)";
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

Procedure AddStagesOrderTable(Query, TemplTableName = "Products") Export
	
	Query.Text = StrTemplate(
	"SELECT
	|	Products.Ref AS Order,
	|	Products.ProductsAndServices AS ProductsAndServices,
	|	Products.Typefield AS InventoryAssembly,
	|	Products.Specification AS Specification,
	|	Products.Batch AS Batch,
	|	ProductionKindsStages.LineNumber AS Ord,
	|	ProductionKindsStages.Stage AS Stage
	|INTO ProductsStagesPlan
	|FROM
	|	%1 КАК Products
	|		LEFT JOIN Catalog.Specifications AS Specifications
	|			LEFT JOIN Catalog.ProductionKinds.Stages AS ProductionKindsStages
	|			ON Specifications.ProductionKind = ProductionKindsStages.REFS
	|		ON Products.Specification = Specifications.REFS
	|WHERE
	|	Products.Specification <> VALUE(Catalog.Specifications.EmptyRef)
	|	AND Specifications.ProductionKind <> VALUE(Catalog.ProductionKinds.EmptyRef)",
	TemplTableName);
	Query.Execute();
	
EndProcedure

Function CostAccumulationStructuralUnit(ProductonStructuralUnit) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ProductionStagesStricturalUnit.StructuralUnit AS StructuralUnit
	|FROM
	|	Catalog.ProductionStages.StructuralUnits AS ProductionStagesStricturalUnit
	|WHERE
	|	ProductionStagesStricturalUnit.Ref = VALUE(Catalog.ProductionStages.ProductionComplete)
	|	AND ProductionStagesStricturalUnit.Default";
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.StructuralUnit;
	Else
		Return ProductonStructuralUnit;
	EndIf; 
	
EndFunction

Procedure FillUnventoryStages(Products, Inventory) Export
	
	ContentTable = SpecificationContent(Products, True);
	ContentTable.GroupBy("ContentProductsServices, ContentChar, ContentMeasirimentUnit, Stg", "ContentQtt");
	InventoryTab = Inventory.UnloadColumns();
	
	For Each InventoryRow In Inventory Do
		Filter = New Structure;
		Filter.Insert("ContentProductsServices", InventoryRow.Номенклатура);
		Filter.Insert("ContentChar", InventoryRow.Характеристика);
		Filter.Insert("ContentMeasirimentUnit", InventoryRow.ЕдиницаИзмерения);
		ContentRows = ContentTable.FindRows(Filter);
		If ContentRows.Count()=0 Then
			NewRow = InventoryTab.Add();
			FillPropertyValues(NewRow, InventoryRow);
			If ContentTable.Count()>0 And ContentTable.Find(Catalogs.ProductionStages.EmptyRef(), "Stg")=Undefined Then
				NewRow.Stg = Catalogs.ProductionStages.ProductionComplete;
			EndIf; 
		ElsIf ContentRows.Count()=1 Then
			NewRow = InventoryTab.Add();
			FillPropertyValues(NewRow, InventoryRow);
			NewRow.Stg = ContentRows[0].Stg;
		Else
			TotalQuantity = 0;
			For Each ContentRow In ContentRows Do
				TotalQuantity = TotalQuantity + ContentRow.ContentQtt;
			EndDo;
			If TotalQuantity=0 Then
				// Распределение по количеству строк
				Distribted = 0;
				NewRows = New Array;
				For Each ContentRow In ContentRows Do
					NewRow = InventoryTab.Add();
					FillPropertyValues(NewRow, InventoryRow);
					NewRow.Stg = ContentRows[0].Stg;
					NewRow.Qtt = InventoryRow.Qtt * 1 / ContentRows.Count();
					Distribted = Distribted + NewRow.Qtt;
					NewRows.Add(NewRow);
				EndDo;
				If Distribted<>InventoryRow.Qtt Then
					TakeRounding(NewRows, (InventoryRow.Qtt-Distribted), "Qtt");
				EndIf; 
			Else
				// Распределение по количеству
				Distribted = 0;
				NewRows = New Array;
				For Each ContentRow In ContentRows Do
					NewRow = InventoryTab.Add();
					FillPropertyValues(NewRow, InventoryRow);
					NewRow.Stg = ContentRows[0].Stg;
					NewRow.Qtt = InventoryRow.Qtt * ContentRow.ContentQtt / TotalQuantity;
					Distribted = Distribted + NewRow.Qtt;
					NewRows.Add(NewRow);
				EndDo;
				If Distribted<>InventoryRow.Qtt Then
					TakeRounding(NewRows, (InventoryRow.Qtt-Distribted), "Qtt");
				EndIf; 
			EndIf; 
		EndIf; 
	EndDo;
	
	InventoryTab.FillValues(0, "ConKey");
	CollapseAllColumns(InventoryTab, "Qtt, Rsrv, CostPercentag");
	FillConnectionKeys(InventoryTab);
	Inventory.Load(InventoryTab);
	
EndProcedure

// Возвращает признак использования спецификацией дополнительных реквизитов
//
// Parameters:
//  Specification - CatalogRef.Specifications - Проверяемая спецификация.
// Returns:
//  Boolean - Признак наличия у спецификации общих или привязанных к категории дополнительных реквизитов.
//
Function HasSpecificationAdditionalAttributes(Specification) Export
	
	Query = New Query;
	Query.SetParameter("Specification", Specification);
	Query.Text =
	"SELECT ALLOWED TOP 1
	|	Specifications.Ref AS Ref,
	|	CASE
	|		WHEN AdditionalAttributesAndInformation.Ref IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS AreAdditAttributes
	|FROM
	|	Catalog.Specifications AS Specifications
	|		LEFT JOIN Catalog.ProductsAndServices AS ProductsAndServices
	|			LEFT JOIN Catalog.ProductsAndServicesCategories AS ProductsAndServicesCategories
	|				LEFT JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInformation AS AdditionalAttributesAndInformation
	|				ON (ProductsAndServicesCategories.SpecificationAttributesArray = AdditionalAttributesAndInformation.PropertySet
	|						OR AdditionalAttributesAndInformation.PropertySet = VALUE(Catalog.AdditionalAttributesAndInformationSets.Catalog_Specifications_Common))
	|					AND (NOT AdditionalAttributesAndInformation.DeletionMark)
	|			ON ProductsAndServices.ProductsAndServicesCategory = ProductsAndServicesCategories.Ref
	|		ON Specifications.Owner = ProductsAndServices.Ref
	|WHERE
	|	Specifications.Ref = &Specification";
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.AreAdditAttributes;
	Else
		Return False;
	EndIf; 
	
EndFunction

// Обновляет признак пометки удаления у привязанных к заказу спецификаций.
//
// Parameters:
//  DocOrder - DocumentRef.CustomerOrder, DocumentRef.ProductionOrder - Заказ для отбора спецификаций.
//  DeletionMark - Boolean - Новое значение признака пометки удаления спецификаций.
Procedure UpdateRelatedSpecifications(DocOrder, DeletionMark) Export
	
	If Not ValueIsFilled(DocOrder) Then
		Return;
	EndIf;
	If Not AccessRight("Update", Metadata.Catalogs.Specifications) Then
		Return;
	EndIf; 
	
	Query = New Query;
	Query.SetParameter("DocOrder", DocOrder);
	Query.SetParameter("DeletionMark", DeletionMark);
	Query.Text =
	"SELECT
	|	DocumentOrder.Ref AS DocOrder,
	|	Specifications.Ref AS Specification
	|FROM
	|	Document.CustomerOrder AS DocumentOrder
	|		LEFT JOIN Catalog.Specifications AS Specifications
	|		ON (Specifications.DocOrder = DocumentOrder.Ref)
	|WHERE
	|	DocumentOrder.Ref = &DocOrder
	|	AND Specifications.DeletionMark <> &DeletionMark
	|	AND DocumentOrder.DeletionMark <> &DeletionMark";
	If TypeOf(DocOrder)=Type("DocumentRef.ProductionOrder") Then
		Query.Text = StrReplace(Query.Text, "Document.CustomerOrder", "Document.ProductionOrder");
	EndIf;
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Specification = Selection.Specification.GetObject();
		Specification.SetDeletionMark(DeletionMark);
	EndDo; 
	
EndProcedure
 
#EndRegion

#Region ServiceProgramInterface

Procedure CompareInventoryAndDictribution(Object, Cancel) Export
	
	If TypeOf(Object)<>Type("ДокументОбъект.ProductionOrder") And TypeOf(Object)<>Type("ДокументОбъект.InventoryAssembly") Then
		Return;
	EndIf; 
	
	If Object.Inventory.Count()=0 And Object.InventoryDistribution.Count()=0 Then
		Return;
	EndIf;
	
	InventoryTab = Object.Inventory.Unload();
	NoCells = (InventoryTab.Columns.Find("Cell")=Undefined);
	If NoCells Then
		InventoryTab.Columns.Add("Cell", New TypeDescription("СправочникСсылка.Cells"));
	EndIf; 
	
	DistributionTable = Object.InventoryDistribution.Unload();
	
	If NoCells Then
		DistributionTable.Columns.Add("Cell", New TypeDescription("СправочникСсылка.Cells"));
	EndIf; 
	
	ItsDisassemble = (Object.OperationKind=Enums.OperationKindsProductionOrder.Disassembly
		Or Object.OperationKind=Enums.OperationKindsInventoryAssembly.Disassembly);
	
	Query = New Query;
	Query.SetParameter("InventoryDistribution", DistributionTable);
	Query.SetParameter("Inventory", InventoryTab);
	Query.SetParameter("ItsDisassemble", ItsDisassemble);
	Query.SetParameter("WarehousePosition", Object.WarehousePosition);
	Query.SetParameter("CellsAccount", GetFunctionalOption("AccountingByCells"));
	Query.Text =
	"SELECT
	|	Inventory.Stage AS Stage,
	|	Inventory.ProductsAndServices AS ProductsAndServices,
	|	Inventory.Characteristic AS Characteristic,
	|	Inventory.MeasurementUnit AS MeasurementUnit,
	|	Inventory.Specification AS Specification,
	|	Inventory.Batch AS Batch,
	|	Inventory.CustomerOrder AS CustomerOrder,
	|	CASE
	|		WHEN &ItsDisassemble
	|				OR &WarehousePosition <> VALUE(Enum.AttributePositionOnForm.InTabularSection)
	|			THEN VALUE(Catalog.StructuralUnits.EmptyRef)
	|		ELSE Inventory.StructuralUnit
	|	END AS StructuralUnit,
	|	CASE
	|		WHEN NOT &CellsAccount
	|				OR &ItsDisassemble
	|				OR &WarehousePosition <> VALUE(Enum.AttributePositionOnForm.InTabularSection)
	|			THEN VALUE(Catalog.Cells.EmptyRef)
	|		ELSE Inventory.Cell
	|	END AS Cell,
	|	Inventory.Quantity AS Quantity
	|INTO Inventory
	|FROM
	|	&Inventory AS Inventory
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryDistribution.Stage AS Stage,
	|	InventoryDistribution.ProductsAndServices AS ProductsAndServices,
	|	InventoryDistribution.Characteristic AS Characteristic,
	|	InventoryDistribution.MeasurementUnit AS MeasurementUnit,
	|	InventoryDistribution.Specification AS Specification,
	|	InventoryDistribution.Batch AS Batch,
	|	InventoryDistribution.CustomerOrder AS CustomerOrder,
	|	CASE
	|		WHEN &ItsDisassemble
	|				OR &WarehousePosition <> VALUE(Enum.AttributePositionOnForm.InTabularSection)
	|			THEN VALUE(Catalog.StructuralUnits.EmptyRef)
	|		ELSE InventoryDistribution.StructuralUnit
	|	END AS StructuralUnit,
	|	CASE
	|		WHEN NOT &CellsAccount
	|				OR &ItsDisassemble
	|				OR &WarehousePosition <> VALUE(Enum.AttributePositionOnForm.InTabularSection)
	|			THEN VALUE(Catalog.Cells.EmptyRef)
	|		ELSE InventoryDistribution.Cell
	|	END AS Cell,
	|	InventoryDistribution.Quantity AS Quantity
	|INTO InventoryDistribution
	|FROM
	|	&InventoryDistribution AS InventoryDistribution
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.Stage AS Stage,
	|	NestedQuery.ProductsAndServices AS ProductsAndServices,
	|	NestedQuery.Characteristic AS Characteristic,
	|	NestedQuery.MeasurementUnit AS MeasurementUnit,
	|	NestedQuery.Specification AS Specification,
	|	NestedQuery.Batch AS Batch,
	|	NestedQuery.CustomerOrder AS CustomerOrder,
	|	NestedQuery.StructuralUnit AS StructuralUnit,
	|	NestedQuery.Cell AS Cell,
	|	SUM(NestedQuery.Quantity) AS Quantity,
	|	SUM(NestedQuery.QuantityInventory) AS QuantityInventory,
	|	SUM(NestedQuery.QuantityDistributed) AS QuantityDistributed
	|FROM
	|	(SELECT
	|		Inventory.Stage AS Stage,
	|		Inventory.ProductsAndServices AS ProductsAndServices,
	|		Inventory.Characteristic AS Characteristic,
	|		Inventory.MeasurementUnit AS MeasurementUnit,
	|		Inventory.Specification AS Specification,
	|		Inventory.Batch AS Batch,
	|		Inventory.CustomerOrder AS CustomerOrder,
	|		Inventory.StructuralUnit AS StructuralUnit,
	|		Inventory.Cell AS Cell,
	|		Inventory.Quantity AS Quantity,
	|		Inventory.Quantity AS QuantityInventory,
	|		0 AS QuantityDistributed
	|	FROM
	|		Inventory AS Inventory
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		InventoryDistribution.Stage,
	|		InventoryDistribution.ProductsAndServices,
	|		InventoryDistribution.Characteristic,
	|		InventoryDistribution.MeasurementUnit,
	|		InventoryDistribution.Specification,
	|		InventoryDistribution.Batch,
	|		InventoryDistribution.CustomerOrder,
	|		InventoryDistribution.StructuralUnit,
	|		InventoryDistribution.Cell,
	|		-InventoryDistribution.Quantity,
	|		0,
	|		InventoryDistribution.Quantity
	|	FROM
	|		InventoryDistribution AS InventoryDistribution) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Stage,
	|	NestedQuery.ProductsAndServices,
	|	NestedQuery.Characteristic,
	|	NestedQuery.MeasurementUnit,
	|	NestedQuery.Specification,
	|	NestedQuery.Batch,
	|	NestedQuery.CustomerOrder,
	|	NestedQuery.StructuralUnit,
	|	NestedQuery.Cell
	|
	|HAVING
	|	SUM(NestedQuery.Quantity) <> 0";
	
	ColumnsName = "Stage, ProductsAndServices, Characteristic, MeasurementUnit, Specification, Batch, CustomerOrder, StructuralUnit";
	If Not NoCells Then
		ColumnsName = ColumnsName + ", Cell";
	EndIf; 
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		FilterStructure = New Structure(ColumnsName);
		FillPropertyValues(FilterStructure, Selection);
		InventoryRows = Object.Inventory.FindRows(FilterStructure);
		If InventoryRows.Count()=0 Then
			DistribRows = Object.InventoryDistribution.FindRows(FilterStructure);
			If DistribRows.Count()=0 Then
				SmallBusinessServer.ShowMessageAboutError(
					Object,
					NStr("'ru = 'Обнаружно распределение, не отраженное в таблице материалов. Выполните перераспределение.';
						|En = 'A distribution was found that is not reflected in the material table. Redistribute.'"), , , ,
					Cancel);
			Else
				SmallBusinessServer.ShowMessageAboutError(
					Object,
					NStr("en='Detected distribution not reflected in material table';ru='Обнаружно распределение, не отраженное в таблице материалов.';vi='Đã phát hiện có phân bổ chưa được phản ánh vào bảng nguyên vật liệu.'"),
					"InventoryDistribution",
					DistribRows[0].LineNumber,
					"ProductsAndServices",
					Cancel);
			EndIf; 
		Else
			InventoryRow = InventoryRows[0];
			MessageText = StrTemplate(NStr("en='An incorrect distribution of materials was detected on line %1';ru='Обнаружно неверное распределение материалов в строке %1';vi='Đã phân bổ sai nguyên vật liệu tại dòng %1'"), InventoryRow.LineNumber);
			InformText = "";
			If Selection.Quantity<>0 Then
				InformText = InformText + StrTemplate(NStr("en='number %1, distributed %2';ru='количество %1, распределено %2';vi='số lượng %1, đã phân bổ %2'"), Selection.QuantityInventory, Selection.QuantityDistributed);
			EndIf; 
			If Not IsBlankString(InformText) Then
				MessageText = MessageText + StrTemplate(NStr("En=' (%1)';ru=' (%1)';vi=' (%1)'"), InformText);
			EndIf; 
			SmallBusinessServer.ShowMessageAboutError(
				Object,
				MessageText,
				"Inventory",
				InventoryRow.LineNumber,
				"ProductsAndServices",
				Cancel);
		EndIf; 
	EndDo; 
	
EndProcedure

Procedure FillDistributionControlCash(Object, DistributionControlCash) Export
	
	InventoryTab = Object.Inventory.Unload();
	If InventoryTab.Columns.Find("Cell")=Undefined Then
		InventoryTab.Columns.Add("Cell", New TypeDescription("CatalogRef.Cells"));
	EndIf; 
	
	DistributionTable = Object.InventoryDistribution.Unload();
	If DistributionTable.Columns.Find("Cell")=Undefined Then
		DistributionTable.Columns.Add("Cell", New TypeDescription("CatalogRef.Cells"));
	EndIf; 
	
	If Object.OperationKind = Enums.OperationKindsProductionOrder.Disassembly
		Or Object.OperationKind = Enums.OperationKindsInventoryAssembly.Assembly
		Or Object.CustomerOrderPosition = Enums.AttributePositionOnForm.InHeader Then
		
		InventoryTab.FillValues(Catalogs.StructuralUnits.EmptyRef(), "StructuralUnit");
		DistributionTable.FillValues(Catalogs.StructuralUnits.EmptyRef(), "StructuralUnit");
		InventoryTab.FillValues(Catalogs.Cells.EmptyRef(), "Cell");
		DistributionTable.FillValues(Catalogs.Cells.EmptyRef(), "Cell");
	EndIf;
	
	If Object.CustomerOrderPosition = Enums.AttributePositionOnForm.InHeader Then
		InventoryTab.FillValues(Documents.CustomerOrder.EmptyRef(), "CustomerOrder");
		DistributionTable.FillValues(Documents.CustomerOrder.EmptyRef(), "CustomerOrder");
	EndIf; 
	
	Query = New Query;
	Query.SetParameter("InventoryDistribution", DistributionTable);
	Query.SetParameter("Inventory", InventoryTab);
	Query.Text =
	"SELECT
	|	Inventory.Stage AS Stage,
	|	Inventory.ProductsAndServices AS ProductsAndServices,
	|	Inventory.Characteristic AS Characteristic,
	|	Inventory.MeasurementUnit AS MeasurementUnit,
	|	Inventory.Specification AS Specification,
	|	Inventory.Batch AS Batch,
	|	Inventory.CustomerOrder AS CustomerOrder,
	|	Inventory.StructuralUnit AS StructuralUnit,
	|	Inventory.Cell AS Cell,
	|	Inventory.Quantity AS Quantity
	|INTO Inventory
	|FROM
	|	&Inventory AS Inventory
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryDistribution.Stage AS Stage,
	|	InventoryDistribution.ProductsAndServices AS ProductsAndServices,
	|	InventoryDistribution.Characteristic AS Characteristic,
	|	InventoryDistribution.MeasurementUnit AS MeasurementUnit,
	|	InventoryDistribution.Specification AS Specification,
	|	InventoryDistribution.Batch AS Batch,
	|	InventoryDistribution.CustomerOrder AS CustomerOrder,
	|	InventoryDistribution.StructuralUnit AS StructuralUnit,
	|	InventoryDistribution.Cell AS Cell,
	|	InventoryDistribution.Quantity AS Quantity
	|INTO InventoryDistribution
	|FROM
	|	&InventoryDistribution AS InventoryDistribution
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.Stage AS Stage,
	|	NestedQuery.ProductsAndServices AS ProductsAndServices,
	|	NestedQuery.Characteristic AS Characteristic,
	|	NestedQuery.MeasurementUnit AS MeasurementUnit,
	|	NestedQuery.Specification AS Specification,
	|	NestedQuery.Batch AS Batch,
	|	NestedQuery.CustomerOrder AS CustomerOrder,
	|	NestedQuery.StructuralUnit AS StructuralUnit,
	|	NestedQuery.Cell AS Cell,
	|	SUM(NestedQuery.QuantityInventory) AS QuantityInventory,
	|	SUM(NestedQuery.QuantityDistribution) AS QuantityDistribution
	|FROM
	|	(SELECT
	|		Inventory.Stage AS Stage,
	|		Inventory.ProductsAndServices AS ProductsAndServices,
	|		Inventory.Characteristic AS Characteristic,
	|		Inventory.MeasurementUnit AS MeasurementUnit,
	|		Inventory.Specification AS Specification,
	|		Inventory.Batch AS Batch,
	|		Inventory.CustomerOrder AS CustomerOrder,
	|		Inventory.StructuralUnit AS StructuralUnit,
	|		Inventory.Cell AS Cell,
	|		Inventory.Quantity AS QuantityInventory,
	|		0 AS QuantityDistribution
	|	FROM
	|		Inventory AS Inventory
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		InventoryDistribution.Stage,
	|		InventoryDistribution.ProductsAndServices,
	|		InventoryDistribution.Characteristic,
	|		InventoryDistribution.MeasurementUnit,
	|		InventoryDistribution.Specification,
	|		InventoryDistribution.Batch,
	|		InventoryDistribution.CustomerOrder,
	|		InventoryDistribution.StructuralUnit,
	|		InventoryDistribution.Cell,
	|		0,
	|		InventoryDistribution.Quantity
	|	FROM
	|		InventoryDistribution AS InventoryDistribution) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Stage,
	|	NestedQuery.ProductsAndServices,
	|	NestedQuery.Characteristic,
	|	NestedQuery.MeasurementUnit,
	|	NestedQuery.Specification,
	|	NestedQuery.Batch,
	|	NestedQuery.CustomerOrder,
	|	NestedQuery.StructuralUnit,
	|	NestedQuery.Cell";
	
	DistributionControlCash.Load(Query.Execute().Unload());
	
EndProcedure

Procedure DisassemblOperations(Query, DisassemblDoc = Undefined, TSName = "", NestedLevel = 0) Export
	
	If Query.TempTablesManager=Undefined Then
		Query.TempTablesManager = New TempTablesManager;
	EndIf;
	
	If TypeOf(DisassemblDoc)=Type("Array") Then
		DocsArray = DisassemblDoc;
	Else
		DocsArray = New Array;
		If ValueIsFilled(DisassemblDoc) Then
			DocsArray.Add(DisassemblDoc);
		EndIf; 
	EndIf; 
	
	// Выборка спецификаций из ТЧ документа
	If Query.TempTablesManager.Tables.Find("OperationTable")=Undefined Then
		If DocsArray.Count()=0 Or IsBlankString(TSName) Then
			Return;
		EndIf;
		FirstDoc = DocsArray[0];
		Query.SetParameter("DocsArray", DocsArray);
		If FirstDoc.Metadata()=Metadata.Documents.CustomerOrder And TSName="Inventory" And Query.TempTablesManager.Tables.Find("TTCustomerOrderInventory")<>Undefined Then
			Query.Text =
			"SELECT
			|	0 AS Level,
			|	MIN(TabularSection.LineNumber) AS Order,
			|	0 AS LineNumber,
			|	VALUE(Catalog.ProductionStages.EmptyRef) AS Stage,
			|	TabularSection.Specification AS Specification,
			|	TabularSection.Specification AS NestedSpecification,
			|	TRUE AS ThisNode,
			|	TabularSection.ProductsAndServices AS Operation,
			|	1 AS TimeRate
			|INTO OperationTable
			|FROM
			|	TTCostomerOrderInvtry AS TabularSection
			|WHERE
			|	TabularSection.Specification <> VALUE(Catalog.Specifications.EmptyRef)
			|
			|GROUP BY
			|	TabularSection.ProductsAndServices,
			|	TabularSection.Specification";
		Else
			Query.Text =
			"SELECT
			|	0 AS Level,
			|	MIN(TabularSection.LineNumber) AS Order,
			|	0 AS LineNumber,
			|	VALUE(Catalog.ProductionStages.EmptyRef) AS Stage,
			|	TabularSection.Specification AS Specification,
			|	TabularSection.Specification AS NestedSpecification,
			|	TRUE AS ThisNode,
			|	TabularSection.ProductsAndServices AS Operation,
			|	1 AS TimeRate
			|INTO OperationTable
			|FROM
			|	Document.CustomerOrder.Inventory AS TabularSection
			|WHERE
			|	TabularSection.Ref IN(&DocsArray)
			|	AND TabularSection.Specification <> VALUE(Catalog.Specifications.EmptyRef)
			|
			|GROUP BY
			|	TabularSection.Specification,
			|	TabularSection.ProductsAndServices";
			Query.Text = StrReplace(Query.Text, "CustomerOrder.Inventory", FirstDoc.Metadata().Name+"."+TSName);
		EndIf; 
		Query.Execute();
	EndIf; 
	
	Query.SetParameter("NestedLevel", NestedLevel);
	Query.SetParameter("UseProductionStage", GetFunctionalOption("UseProductionStages"));
	Query.Text =
	"SELECT
	|	OperationTable.Level AS Level,
	|	OperationTable.Order AS Order,
	|	OperationTable.LineNumber AS LineNumber,
	|	OperationTable.Stage AS Stage,
	|	OperationTable.Specification AS Specification,
	|	OperationTable.NestedSpecification AS NestedSpecification,
	|	OperationTable.ThisNode AS ThisNode,
	|	OperationTable.Operation AS Operation,
	|	OperationTable.TimeRate AS TimeRate
	|INTO TempOperationTable
	|FROM
	|	OperationTable AS OperationTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP OperationTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OperationTable.Level AS Level,
	|	OperationTable.Order AS Order,
	|	OperationTable.LineNumber AS LineNumber,
	|	OperationTable.Stage AS Stage,
	|	OperationTable.Specification AS Specification,
	|	OperationTable.NestedSpecification AS NestedSpecification,
	|	OperationTable.ThisNode AS ThisNode,
	|	OperationTable.Operation AS Operation,
	|	SUM(OperationTable.TimeRate) AS TimeRate,
	|	UNDEFINED AS Performer
	|INTO OperationTable
	|FROM
	|	(SELECT
	|		OperationTable.Level AS Level,
	|		OperationTable.Order AS Order,
	|		0 AS LineNumber,
	|		OperationTable.Stage AS Stage,
	|		OperationTable.Specification AS Specification,
	|		UNDEFINED AS NestedSpecification,
	|		FALSE AS ThisNode,
	|		OperationTable.Operation AS Operation,
	|		OperationTable.TimeRate AS TimeRate
	|	FROM
	|		TempOperationTable AS OperationTable
	|	WHERE
	|		NOT OperationTable.ThisNode
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		OperationTable.Level,
	|		OperationTable.Order,
	|		CASE
	|			WHEN OperationTable.LineNumber = 0
	|				THEN SpecificationsOperations.LineNumber
	|			ELSE OperationTable.LineNumber
	|		END,
	|		CASE
	|			WHEN NOT &UseProductionStage
	|				THEN VALUE(Catalog.ProductionStages.EmptyRef)
	|			WHEN OperationTable.Stage = VALUE(Catalog.ProductionStages.EmptyRef)
	|				THEN SpecificationsOperations.Stage
	|			ELSE OperationTable.Stage
	|		END,
	|		OperationTable.Specification,
	|		UNDEFINED,
	|		FALSE,
	|		ISNULL(SpecificationsOperations.Operation, VALUE(Catalog.ProductsAndServices.EmptyRef)),
	|		OperationTable.TimeRate * CASE
	|			WHEN SpecificationsOperations.TimeNorm IS NULL
	|				THEN 1
	|			ELSE CASE
	|					WHEN SpecificationsOperations.ProductsQuantity = 0
	|						THEN 0
	|					ELSE SpecificationsOperations.TimeNorm / SpecificationsOperations.ProductsQuantity
	|				END
	|		END
	|	FROM
	|		TempOperationTable AS OperationTable
	|			LEFT JOIN Catalog.Specifications.Operations AS SpecificationsOperations
	|			ON OperationTable.NestedSpecification = SpecificationsOperations.Ref
	|	WHERE
	|		OperationTable.ThisNode
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		OperationTable.Level + 1,
	|		SpecificationsContent.LineNumber,
	|		0,
	|		CASE
	|			WHEN NOT &UseProductionStage
	|				THEN VALUE(Catalog.ProductionStages.EmptyRef)
	|			WHEN OperationTable.Stage = VALUE(Catalog.ProductionStages.EmptyRef)
	|				THEN SpecificationsContent.Stage
	|			ELSE OperationTable.Stage
	|		END,
	|		OperationTable.Specification,
	|		SpecificationsContent.Specification,
	|		TRUE,
	|		SpecificationsContent.ProductsAndServices,
	|		OperationTable.TimeRate * CASE
	|			WHEN SpecificationsContent.ProductsQuantity = 0
	|				THEN 0
	|			ELSE SpecificationsContent.Quantity / SpecificationsContent.ProductsQuantity
	|		END
	|	FROM
	|		TempOperationTable AS OperationTable
	|			LEFT JOIN Catalog.Specifications.Content AS SpecificationsContent
	|			ON OperationTable.NestedSpecification = SpecificationsContent.Ref
	|	WHERE
	|		OperationTable.ThisNode
	|		AND SpecificationsContent.ContentRowType = VALUE(Enum.SpecificationContentRowTypes.Node)
	|		AND SpecificationsContent.Specification <> VALUE(Catalog.Specifications.EmptyRef)
	|		AND &NestedLevel < 50) AS OperationTable
	|
	|GROUP BY
	|	OperationTable.Level,
	|	OperationTable.Order,
	|	OperationTable.LineNumber,
	|	OperationTable.Stage,
	|	OperationTable.Specification,
	|	OperationTable.NestedSpecification,
	|	OperationTable.ThisNode,
	|	OperationTable.Operation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TempOperationTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	OperationTable.Specification AS Specification
	|FROM
	|	OperationTable AS OperationTable
	|WHERE
	|	OperationTable.ThisNode";
	
	Result = Query.Execute();
	If Not Result.IsEmpty() Then
		DisassemblOperations(Query, DocsArray, TSName, NestedLevel+1);
	EndIf;
	
EndProcedure

Function SpecificationContent(Products, AddInventory = False, AddOperations = False, ExpendNodes = False, InBaseUnits = True) Export
	
	If ExpendNodes And Products.Columns.Find("ThisNode")=Undefined Then
		Return Products;
	EndIf;
	
	If Products.Columns.Find("LoopCheck")=Undefined Then
		Products.Columns.Add("LoopCheck", New TypeDescription("Array"));
	EndIf;
	If Products.Columns.Find("LineNumberContent")=Undefined Then
		Products.Columns.Add("LineNumberContent", New TypeDescription("Number", New NumberQualifiers(5, 0, AllowedSign.Nonnegative)));
	EndIf;
	
	UseProductionStages = GetFunctionalOption("UseProductionStages");
	
	Query = New Query;
	Query.SetParameter("UseProductionStages", UseProductionStages);
	Query.SetParameter("InBaseUnits", InBaseUnits);
	Query.TempTablesManager = New TempTablesManager;
	
	If ExpendNodes Then
		For Each TabSecRow In Products Do
			If Not ValueIsFilled(TabSecRow.SpecificationCont) Or Not TabSecRow.ThisNode Then
				Continue;
			EndIf; 
			If TabSecRow.LoopCheck.Find(TabSecRow.SpecificationCont)<>Undefined Then
				If ValueIsFilled(TabSecRow.CharacteristicContent) Then
					MessageText = StrTemplate(NStr("en='Looping specifications specification nodes %1 (%2, %3)';vi='Các thông số kỹ thuật của vòng lặp %1 (%2, %3)'"), TabSecRow.SpecificationCont, TabSecRow.ProductsAndServicesContent, TabSecRow.CharacteristicContent);
				Else
					MessageText = StrTemplate(NStr("en='Looping specifications specification nodes %1 (%2)';vi='Các thông số kỹ thuật của vòng lặp %1 (%2)'"), TabSecRow.SpecificationCont, TabSecRow.ProductsAndServicesContent);
				EndIf; 
				Raise MessageText;
			EndIf; 
			TabSecRow.LoopCheck.Add(TabSecRow.SpecificationCont);
		EndDo; 
		Query.Text = 
		"SELECT
		|	Products.LineNumber AS LineNumber,
		|	Products.LineNumberContent AS LineNumberContent,
		|	CASE
		|		WHEN &UseStages
		|			THEN Products.Stage
		|		ELSE VALUE(Catalog.ProductionStages.EmptyRef)
		|	END AS Stage,
		|	Products.ProductsAndServicesContent AS ProductsAndServices,
		|	Products.CharacteristicContent AS Characteristic,
		|	Products.SpecificationCont AS Specification,
		|	Products.CustomerOrder AS CustomerOrder,
		|	Products.QuantityContent * CASE
		|		WHEN Products.MeasurementUnitContent REFS Catalog.UOM
		|			THEN CAST(Products.MeasurementUnitContent AS Catalog.UOM).Factor
		|		ELSE 1
		|	END AS Quantity,
		|	Products.CostPercentage AS CostPercentage,
		|	Products.ConnectionKey AS ConnectionKey
		|INTO Products
		|FROM
		|	&Products AS Products
		|WHERE
		|	Products.SpecificationCont <> VALUE(Catalog.Specifications.EmptyRef)
		|	AND Products.ThisNode";
	Else
		For Each TabSecRow In Products Do
			If Not ValueIsFilled(TabSecRow.Specification) Then
				Continue;
			EndIf; 
			TabSecRow.LoopCheck.Add(TabSecRow.Specification);
		EndDo; 
		Query.Text = 
		"SELECT
		|	Products.LineNumber AS LineNumber,
		|	Products.LineNumberContent AS LineNumberContent,
		|	VALUE(Catalog.ProductionStages.EmptyRef) AS Stage,
		|	Products.ProductsAndServices AS ProductsAndServices,
		|	Products.Characteristic AS Characteristic,
		|	Products.Specification AS Specification,
		|	Products.CustomerOrder AS CustomerOrder,
		|	Products.Quantity AS Quantity,
		|	Products.MeasurementUnit AS MeasurementUnit,
		|	0 AS CostPercentage,
		|	Products.ConnectionKey AS ConnectionKey
		|INTO TT_Products
		|FROM
		|	&Products AS Products
		|WHERE
		|	Products.Specification <> VALUE(Catalog.Specifications.EmptyRef)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Products.LineNumber AS LineNumber,
		|	Products.LineNumberContent AS LineNumberContent,
		|	Products.Stage AS Stage,
		|	Products.ProductsAndServices AS ProductsAndServices,
		|	Products.Characteristic AS Characteristic,
		|	Products.Specification AS Specification,
		|	Products.CustomerOrder AS CustomerOrder,
		|	Products.Quantity * CASE
		|		WHEN Products.MeasurementUnit REFS Catalog.UOM
		|			THEN CAST(Products.MeasurementUnit AS Catalog.UOM).Factor
		|		ELSE 1
		|	END AS Quantity,
		|	Products.CostPercentage AS CostPercentage,
		|	Products.ConnectionKey AS ConnectionKey
		|INTO Products
		|FROM
		|	TT_Products AS Products
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TT_Products";
	EndIf;
	
	Query.SetParameter("Products", Products);
	Query.SetParameter("AddInventory", AddInventory);
	Query.SetParameter("AddOperations", AddOperations);
	Query.SetParameter("ExpendNodes", ExpendNodes);
	Query.SetParameter("UseStages", UseProductionStages);
	Query.Execute();
	
	Query.Text = 
	"SELECT
	|	Products.LineNumber AS LineNumber,
	|	CASE
	|		WHEN &UseStages
	|				AND Products.Stage = VALUE(Catalog.ProductionStages.EmptyRef)
	|			THEN SpecificationsContent.Stage
	|		WHEN &UseStages
	|			THEN Products.Stage
	|		ELSE VALUE(Catalog.ProductionStages.EmptyRef)
	|	END AS Stage,
	|	Products.ProductsAndServices AS ProductsAndServices,
	|	Products.Characteristic AS Characteristic,
	|	Products.Specification AS Specification,
	|	Products.CustomerOrder AS CustomerOrder,
	|	Products.Quantity AS Quantity,
	|	Products.ConnectionKey AS ConnectionKey,
	|	CASE
	|		WHEN Products.LineNumberContent = 0
	|			THEN SpecificationsContent.LineNumber
	|		ELSE Products.LineNumberContent
	|	END AS LineNumberContent,
	|	SpecificationsContent.ProductsAndServices AS ProductsAndServicesContent,
	|	SpecificationsContent.Characteristic AS CharacteristicContent,
	|	SpecificationsContent.Specification AS SpecificationCont,
	|	SpecificationsContent.Quantity / CASE
	|		WHEN SpecificationsContent.ProductsQuantity = 0
	|			THEN 1
	|		ELSE SpecificationsContent.ProductsQuantity
	|	END * CASE
	|		WHEN &InBaseUnits
	|				AND SpecificationsContent.MeasurementUnit REFS Catalog.UOM
	|			THEN SpecificationsContent.MeasurementUnit.Factor
	|		ELSE 1
	|	END * Products.Quantity AS QuantityContent,
	|	CASE
	|		WHEN Products.CostPercentage = 0
	|			THEN SpecificationsContent.CostPercentage
	|		WHEN ISNULL(TotalCostPercentage.CostPercentage, 0) = 0
	|			THEN 1
	|		ELSE Products.CostPercentage / ISNULL(TotalCostPercentage.CostPercentage, 0) * SpecificationsContent.CostPercentage
	|	END AS CostPercentage,
	|	CASE
	|		WHEN &InBaseUnits
	|			THEN SpecificationsContent.ProductsAndServices.MeasurementUnit
	|		ELSE SpecificationsContent.MeasurementUnit
	|	END AS MeasurementUnitContent,
	|	CASE
	|		WHEN SpecificationsContent.ContentRowType = VALUE(Enum.SpecificationContentRowTypes.Node)
	|				AND SpecificationsContent.Specification <> VALUE(Catalog.Specifications.EmptyRef)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisNode
	|FROM
	|	Products AS Products
	|		LEFT JOIN Catalog.Specifications.Content AS SpecificationsContent
	|		ON Products.Specification = SpecificationsContent.Ref
	|		LEFT JOIN (SELECT
	|			Products.Specification AS Specification,
	|			SUM(SpecificationsContent.CostPercentage) AS CostPercentage
	|		FROM
	|			Products AS Products
	|				LEFT JOIN Catalog.Specifications.Content AS SpecificationsContent
	|				ON Products.Specification = SpecificationsContent.Ref
	|		
	|		GROUP BY
	|			Products.Specification) AS TotalCostPercentage
	|		ON Products.Specification = TotalCostPercentage.Specification
	|WHERE
	|	(&AddInventory
	|				AND SpecificationsContent.ProductsAndServices.ProductsAndServicesType = VALUE(Enum.ProductsAndServicesTypes.InventoryItem)
	|				AND SpecificationsContent.ContentRowType <> VALUE(Enum.SpecificationContentRowTypes.Expense)
	|				AND NOT(SpecificationsContent.ContentRowType = VALUE(Enum.SpecificationContentRowTypes.Node)
	|						AND SpecificationsContent.Specification = VALUE(Catalog.Specifications.EmptyRef))
	|			OR &AddOperations
	|				AND SpecificationsContent.Specification <> VALUE(Catalog.Specifications.EmptyRef)
	|				AND SpecificationsContent.ContentRowType = VALUE(Enum.SpecificationContentRowTypes.Node))
	|
	|UNION ALL
	|
	|SELECT
	|	Products.LineNumber,
	|	CASE
	|		WHEN &UseStages
	|				AND Products.Stage = VALUE(Catalog.ProductionStages.EmptyRef)
	|			THEN SpecificationsOperations.Stage
	|		WHEN &UseStages
	|			THEN Products.Stage
	|		ELSE VALUE(Catalog.ProductionStages.EmptyRef)
	|	END,
	|	Products.ProductsAndServices,
	|	Products.Characteristic,
	|	Products.Specification,
	|	Products.CustomerOrder,
	|	Products.Quantity,
	|	Products.ConnectionKey,
	|	CASE
	|		WHEN Products.LineNumberContent = 0
	|			THEN SpecificationsOperations.LineNumber
	|		ELSE Products.LineNumberContent
	|	END,
	|	SpecificationsOperations.Operation,
	|	VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef),
	|	VALUE(Catalog.Specifications.EmptyRef),
	|	SpecificationsOperations.TimeNorm / CASE
	|		WHEN SpecificationsOperations.ProductsQuantity = 0
	|			THEN 1
	|		ELSE SpecificationsOperations.ProductsQuantity
	|	END * Products.Quantity,
	|	0,
	|	SpecificationsOperations.Operation.MeasurementUnit,
	|	FALSE
	|FROM
	|	Products AS Products
	|		LEFT JOIN Catalog.Specifications.Operations AS SpecificationsOperations
	|		ON Products.Specification = SpecificationsOperations.Ref
	|WHERE
	|	&AddOperations";
	
	Content = Query.Execute().Unload();
	
	If ExpendNodes Then
		For Each ProductRow In Products Do
			If ProductRow.ThisNode Then
				Continue;
			EndIf;
			FillPropertyValues(Content.Add(), ProductRow);
		EndDo; 
	EndIf;
	
	If Content.Find(True, "ThisNode")<>Undefined Then
		Content = SpecificationContent(Content, AddInventory, AddOperations, True);
	EndIf;
	
	If Not ExpendNodes Then
		Content.Sort("LineNumber, LineNumberContent");
	EndIf; 
	
	Return Content;
	
EndFunction

Procedure AddDeletedProducts(Document, ProductsTable, TSName) Export
	
	CustomerOrderExist = (ProductsTable.Columns.Find("CustomerOrder")<>Undefined);
	ProductionOrderExist = (ProductsTable.Columns.Find("ProductionOrde")<>Undefined);
	EmptyFieldsStructure = New Structure("Qtt, QttPlan, QttFact, TSName", 0, 0, 0, TSName);
	
	QueryText = 
	"SELECT
	|	ProductsTable.ProductsAndServices AS ProductsAndServices,
	|	ProductsTable.Characteristic AS Characteristic,
	|	ProductsTable.Batch AS Batch
	|INTO ProductsTable
	|FROM
	|	&ProductsTable AS ProductsTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT * FROM
	|	Document.CustomerOrder.Inventory AS DocumentTS
	|WHERE
	|	NOT (DocumentTS.ProductsAndServices, DocumentTS.Characteristic, DocumentTS.Batch) IN
	|			(SELECT
	|				SelectionFields.ProductsAndServices,
	|				SelectionFields.Characteristic,
	|				SelectionFields.Batch
	|			FROM
	|				ProductsTable AS SelectionFields)
	|	AND DocumentTS.Ref = &Document";
	QueryText = StrReplace(QueryText, "Document.CustomerOrder.Inventory", "Document." + Document.Metadata().Name + "." + TSName);
	If CustomerOrderExist Then
		QueryText = StrReplace(
		QueryText, 
		"ProductsTable.Batch AS Batch", 
		"ProductsTable.Batch AS Batch,
		|	ProductsTable.CustomerOrder AS CustomerOrder");
		QueryText = StrReplace(
		QueryText, 
		", DocumentTS.Batch", 
		", DocumentTS.Batch, DocumentTS.CustomerOrder");
		QueryText = StrReplace(
		QueryText, 
		"SelectionFields.Batch", 
		"SelectionFields.Batch,
		|	SelectionFields.CustomerOrder");
	EndIf; 	
	If ProductionOrderExist Then
		QueryText = StrReplace(
		QueryText, 
		"ProductsTable.Batch AS Batch", 
		"ProductsTable.Batch AS Batch,
		|	ProductsTable.ProductionOrder КАК ProductionOrder");
		QueryText = StrReplace(
		QueryText, 
		", DocumentTS.Batch", 
		", DocumentTS.Batch, DocumentTS.ProductionOrder");
		QueryText = StrReplace(
		QueryText, 
		"SelectionFields.Batch", 
		"SelectionFields.Batch,
		|	SelectionFields.ProductionOrder");
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Document", Document);
	Query.SetParameter("ProductsTable", ProductsTable);
	Query.Text = QueryText;
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		NewRow = ProductsTable.Add();
		FillPropertyValues(NewRow, Selection);
		FillPropertyValues(NewRow, EmptyFieldsStructure);
	EndDo; 
	
EndProcedure

Procedure StageProductionCheck(Document, ProductsTable, Cancel) Export
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Document", Document.Ref);
	Query.SetParameter("ProductsTable", ProductsTable);
	Query.Text =
	"SELECT
	|	ProductsTable.TabName AS TabName,
	|	ProductsTable.LineNumber AS LineNumber,
	|	ProductsTable.ProductsAndServices AS ProductsAndServices,
	|	ProductsTable.Characteristic AS Characteristic,
	|	ProductsTable.Batch AS Batch,
	|	ProductsTable.Specification AS Specification,
	|	ProductsTable.Quantity AS Quantity,
	|	CASE
	|		WHEN ProductsTable.CustomerOrder = VALUE(Document.CustomerOrder.EmptyRef)
	|			THEN ProductsTable.ProductionOrder
	|		ELSE ProductsTable.CustomerOrder
	|	END AS Order,
	|	ProductsTable.CompletiveStageDepartment AS CompletiveStageDepartment
	|INTO ProductsTable
	|FROM
	|	&ProductsTable AS ProductsTable
	|WHERE
	|	(ProductsTable.CustomerOrder <> VALUE(Document.CustomerOrder.EmptyRef)
	|			OR ProductsTable.ProductionOrder <> VALUE(Document.ProductionOrder.EmptyRef))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductionStages.Order AS Order,
	|	ProductionStages.ProductsAndServices AS ProductsAndServices,
	|	ProductionStages.Characteristic AS Characteristic,
	|	ProductionStages.Specification AS Specification,
	|	ProductionStages.Batch AS Batch,
	|	ProductionStages.StructuralUnit AS StructuralUnit,
	|	CASE
	|		WHEN ProductionStages.QuantityPlan = 0
	|			THEN ProductionStages.QuantityFact
	|		ELSE ProductionStages.QuantityPlan
	|	END AS Quantity,
	|	ProductionStages.QuantityFact AS QuantityFact,
	|	ProductionStages.QuantityPlan AS QuantityPlan
	|INTO ExistingRecord
	|FROM
	|	AccumulationRegister.ProductionStages AS ProductionStages
	|WHERE
	|	ProductionStages.Recorder <> &Document
	|	AND ProductionStages.StructuralUnit <> VALUE(Catalog.StructuralUnits.EmptyRef)
	|	AND (ProductionStages.Order, ProductionStages.ProductsAndServices, ProductionStages.Characteristic, ProductionStages.Specification, ProductionStages.Batch) IN
	|			(SELECT
	|				ProductsTable.Order,
	|				ProductsTable.ProductsAndServices,
	|				ProductionStages.Characteristic,
	|				ProductsTable.Specification,
	|				ProductsTable.Batch
	|			FROM
	|				ProductsTable)
	|
	|GROUP BY
	|	ProductionStages.Order,
	|	ProductionStages.ProductsAndServices,
	|	ProductionStages.StructuralUnit,
	|	ProductionStages.Characteristic,
	|	ProductionStages.Specification,
	|	ProductionStages.Batch,
	|	ProductionStages.QuantityFact,
	|	ProductionStages.QuantityPlan";
	Query.Execute();
	
	If GetFunctionalOption("PerformStagesByDifferentDepartments")
		And TypeOf(Document.Ref)<>Type("ДокументСсылка.CustomerOrder") Then
		Query.Text = 
		"SELECT
		|	ProductsTable.LineNumber AS LineNumber,
		|	ProductsTable.TabName AS TabName,
		|	ExistingRecord.StructuralUnit AS StructuralUnit
		|FROM
		|	ProductsTable AS ProductsTable
		|		LEFT JOIN ExistingRecord AS ExistingRecord
		|		ON ProductsTable.Order = ExistingRecord.Order
		|			AND ProductsTable.ProductsAndServices = ExistingRecord.ProductsAndServices
		|			AND ProductsTable.Characteristic = ExistingRecord.Characteristic
		|			AND ProductsTable.Batch = ExistingRecord.Batch
		|			AND ProductsTable.Specification = ExistingRecord.Specification
		|			AND ProductsTable.CompletiveStageDepartment <> ExistingRecord.StructuralUnit
		|WHERE
		|	NOT ExistingRecord.StructuralUnit IS NULL
		|
		|ORDER BY
		|	LineNumber";
		PreviousNumber = 0;
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			If PreviousNumber=Selection.LineNumber Then
				Continue;
			EndIf; 
			PreviousNumber = Selection.LineNumber;
			SmallBusinessServer.ShowMessageAboutError(
				Document,
				StrTemplate(NStr("en='Existing product documents of product and services in line %1 use the completive stage department ""%2 "" different from the selected';vi='Các chứng từ sản xuất hiện có của hàng hóa và dịch vụ tại dòng %1 sử dụng bộ phận thực hiện công đoạn ""%2 "" khác với mục đã chọn'"), Selection.LineNumber, Selection.StructuralUnit),
				Selection.TabName,
				Selection.LineNumber,
				"CompletiveStageDepartment",
				Cancel);
		EndDo;
	EndIf;
	
	If TypeOf(Document.Ref)<>Type("DocumentRef.InventoryAssembly") Then
		Query.Text = 
		"SELECT
		|	ProductsTable.LineNumber AS LineNumber,
		|	ProductsTable.TabName AS TabName,
		|	ProductsTable.Quantity AS Quantity,
		|	ExistingRecord.Quantity AS CurrentQuantity
		|FROM
		|	ProductsTable AS ProductsTable
		|		LEFT JOIN ExistingRecord AS ExistingRecord
		|		ON ProductsTable.Order = ExistingRecord.Order
		|			AND ProductsTable.ProductsAndServices = ExistingRecord.ProductsAndServices
		|			AND ProductsTable.Characteristic = ExistingRecord.Characteristic
		|			AND ProductsTable.Batch = ExistingRecord.Batch
		|			AND ProductsTable.Specification = ExistingRecord.Specification
		|WHERE
		|	NOT ExistingRecord.Quantity IS NULL
		|	AND ExistingRecord.Quantity <> 0
		|	AND ProductsTable.Quantity <> 0
		|	AND ExistingRecord.Quantity <> ProductsTable.Quantity
		|
		|GROUP BY
		|	ExistingRecord.Quantity,
		|	ProductsTable.Quantity,
		|	ProductsTable.LineNumber,
		|	ProductsTable.TabName
		|
		|ORDER BY
		|	LineNumber";
		Selection = Query.Execute().Select();
		PreviousNumber = 0;
		While Selection.Next() Do
			If PreviousNumber=Selection.LineNumber Then
				Continue;
			EndIf;
			PreviousNumber = Selection.LineNumber;
			SmallBusinessServer.ShowMessageAboutError(
				Document,
				StrTemplate(NStr("en='In stage production, the planned and fact manufactured quantity of products cannot differ. The line %1 have the quantity %2, in other documents %3';vi='Trong công đoạn sản xuất, số lượng thành phẩm sản xuất dự tính và thực tế không thể khác nhau. Dòng %1 có số lượng %2, trong chứng từ khác là %3'"), Selection.LineNumber, Selection.Quantity, Selection.CurrentQuantity),
				Selection.TabName,
				Selection.LineNumber,
				"Quantity",
				Cancel);
		EndDo;
	EndIf;
	
	If TypeOf(Document.Ref)=Type("ДокументСсылка.CustomerOrder")
		Or TypeOf(Document.Ref)=Type("ДокументСсылка.ProductionOrder") Then
		Query.Text = 
		"SELECT
		|	ProductsTable.ProductsAndServices AS ProductsAndServices,
		|	ProductsTable.Characteristic AS Characteristic,
		|	ProductsTable.Batch AS Batch,
		|	ProductsTable.Specification AS Specification,
		|	ProductsTable.TabName AS TabName,
		|	ProductsTable.Quantity AS Quantity,
		|	ExistingRecord.Quantity AS QuantityCurrent,
		|	ExistingRecord.QuantityPlan AS QuantityPlan,
		|	ExistingRecord.QuantityFact AS QuantityFact
		|FROM
		|	ProductsTable AS ProductsTable
		|		LEFT JOIN ExistingRecord AS ExistingRecord
		|		ON ProductsTable.Order = ExistingRecord.Order
		|			AND ProductsTable.ProductsAndServices = ExistingRecord.ProductsAndServices
		|			AND ProductsTable.Characteristic = ExistingRecord.Characteristic
		|			AND ProductsTable.Batch = ExistingRecord.Batch
		|			AND ProductsTable.Specification = ExistingRecord.Specification
		|WHERE
		|	NOT ExistingRecord.Quantity IS NULL
		|	AND ExistingRecord.Quantity <> 0
		|	AND ProductsTable.Quantity = 0
		|
		|GROUP BY
		|	ExistingRecord.Quantity,
		|	ExistingRecord.QuantityPlan,
		|	ExistingRecord.QuantityFact,
		|	ProductsTable.Quantity,
		|	ProductsTable.ProductsAndServices,
		|	ProductsTable.Characteristic,
		|	ProductsTable.Batch,
		|	ProductsTable.Specification,
		|	ProductsTable.TabName
		|
		|ORDER BY
		|	Specification";
		Selection = Query.Execute().Select();
		PreviousSpecification = Undefined;
		While Selection.Next() Do
			If PreviousSpecification=Selection.Specification Then
				Continue;
			EndIf;
			If Selection.QttFact<>0 Then
				ErrorText = NStr("en='The product participates in the production:% 1. Change prohibited';vi='Sản phẩm đang tham gia vào sản xuất:% 1. Cấm thay đổi'");
			ElsIf Selection.QttPlan<>0 And TypeOf(Document.Ref)=Type("ДокументСсылка.CustomerOrder") Then
				ErrorText = NStr("en='Product planned for production:% 1. Change prohibited';vi='Sản phẩm dự tính để sản xuất: %1. Cấm thay đổi'");
			Else
				Continue;
			EndIf;
			PreviousSpecification = Selection.Specification;
			//СтруктураПолей = Новый Структура;
			//СтруктураПолей.Вставить("ПредставлениеНоменклатуры", Выборка.ProductsAndServices);
			//СтруктураПолей.Вставить("ПредставлениеХарактеристики", Выборка.Characteristic);
			//СтруктураПолей.Вставить("ПредставлениеПартии", Выборка.Batch);
			//ЗаполнитьЗначенияСвойств(СтруктураПолей, Выборка);
			ProductAndServicesDescription = SmallBusinessServer.GetProductsAndServicesPresentationForPrinting(Selection.ProductsAndServices, Selection.InventoryAssembly, Selection.Batch);
			
			SmallBusinessServer.ShowMessageAboutError(
				Document,
				StrTemplate(ErrorText, ProductAndServicesDescription),
				,
				,
				Selection.TabName,
				Cancel);
		EndDo;
	EndIf; 
	
EndProcedure

Procedure FillRegisterRecordsInventoryMirror(NewRecord, Record) Export
	
	FillPropertyValues(NewRecord, Record);
		
	NewRecord.RecordType = ?(Record.RecordType=AccumulationRecordType.Receipt, AccumulationRecordType.Expense, AccumulationRecordType.Receipt);
		
	NewRecord.StructuralUnit = Record.StructuralUnitCorr;
	NewRecord.GLAccount = Record.CorrGLAccount;
	NewRecord.ProductsAndServices = Record.ProductsAndServicesCorr;
	NewRecord.Characteristic = Record.CharacteristicCorr;
	NewRecord.Batch = Record.BatchCorr;
	NewRecord.CustomerOrder = Record.CustomerCorrOrder;
	NewRecord.ProductionOrder = Record.ProductionCorrOrder;
	NewRecord.Specification = Record.SpecificationCorr;
	
	NewRecord.StructuralUnitCorr = Record.StructuralUnit;
	NewRecord.CorrGLAccount = Record.GLAccount;
	NewRecord.ProductsAndServicesCorr = Record.ProductsAndServices;
	NewRecord.CharacteristicCorr = Record.Characteristic;
	NewRecord.BatchCorr = Record.Batch;
	NewRecord.CustomerCorrOrder = Record.CustomerOrder;
	NewRecord.ProductionCorrOrder = Record.ProductionOrder;
	NewRecord.SpecificationCorr = Record.Specification;
	
	If NewRecord.Owner().Columns.Find("AccountDr") <> Undefined
		And NewRecord.Owner().Columns.Find("AccountCr") <> Undefined Then
		If NewRecord.RecordType=AccumulationRecordType.Receipt Then
			NewRecord.AccountDr = Record.CorrGLAccount;
			NewRecord.AccountCr = Record.GLAccount;
		Else
			NewRecord.AccountDr = Record.GLAccount;
			NewRecord.AccountCr = Record.CorrGLAccount;
		EndIf; 
	EndIf; 
	
EndProcedure

Procedure AddSpecificationFilters(Parameters, Cancel) Export
		
	If Parameters.Property("Filter") And Parameters.Filter.Property("Owner") Then
		
		If ValueIsFilled(Parameters.Filter.Owner) Then
			
			OwnerType = Parameters.Filter.Owner.ProductsAndServicesType;
			
			If (OwnerType = Enums.ProductsAndServicesTypes.Operation
				Or OwnerType = Enums.ProductsAndServicesTypes.WorkKind
				Or OwnerType = Enums.ProductsAndServicesTypes.Service
				Or (Not Constants.FunctionalOptionUseSubsystemProduction.Get() And OwnerType = Enums.ProductsAndServicesTypes.InventoryItem)
				Or (Not Constants.FunctionalOptionUseWorkSubsystem.Get() And OwnerType = Enums.ProductsAndServicesTypes.Work)) Then
			
				Message = New UserMessage();
				LabelText = NStr("en='Для номенклатуры типа %1 спецификация не указывается.';ru='Для номенклатуры типа %1 спецификация не указывается.';vi='Đối với loại mặt hàng %1, Bảng chi tiết nguyên vật liệu không được chỉ định.'");
				LabelText = StrTemplate(LabelText, OwnerType);
				Message.Text = LabelText;
				Message.Message();
				Cancel = True;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	ValueArray = New Array;
	ValueArray.Add(Undefined);
	ValueArray.Add(Documents.CustomerOrder.EmptyRef());
	ValueArray.Add(Documents.ProductionOrder.EmptyRef());
	If Parameters.Property("CustomerOrder") Then
		DocOrder = Parameters.CustomerOrder;
		If Parameters.Property("OperationKind") Then
			AvailableOperationKinds = New Array;
			AvailableOperationKinds.Add(Enums.OperationKindsCustomerOrder.OrderForSale);
			ProperOperationKind = (AvailableOperationKinds.Find(Parameters.OperationKind)<>Undefined);
		Else
			ProperOperationKind = True; 
		EndIf; 
		If ValueIsFilled(DocOrder) And TypeOf(DocOrder)=Type("DocumentRef.CustomerOrder") And ProperOperationKind Then
			ValueArray.Add(DocOrder);
		EndIf;
	EndIf; 
	If Parameters.Property("ProductionOrder") Then
		DocOrder = Parameters.ProductionOrder;
		If ValueIsFilled(DocOrder) And TypeOf(DocOrder)=Type("DocumentRef.ProductionOrder") Then
			ValueArray.Add(DocOrder);
		EndIf;
	EndIf; 
	Parameters.Filter.Insert("DocOrder", New FixedArray(ValueArray));
	
	If Not Parameters.Property("IsTemplate") Then
		Parameters.Filter.Insert("IsTemplate", False);
	EndIf; 
	
	If Parameters.Property("Filter") And Parameters.Filter.Property("ProductCharacteristic") Then
		
		ProductCharacteristic = Parameters.Filter.ProductCharacteristic;
		
		If ValueIsFilled(ProductCharacteristic) Then
			
			ValueArray = New Array;
			ValueArray.Add(ProductCharacteristic);
			ValueArray.Add(Catalogs.ProductsAndServicesCharacteristics.EmptyRef());
			Parameters.Filter.ProductCharacteristic = New FixedArray(ValueArray);
			
		EndIf; 
		
	EndIf;
	
	If Not Parameters.Filter.Property("NotValid") Then
		Parameters.Filter.Insert("NotValid", False);
	EndIf;
	
EndProcedure

#EndRegion 

#Region InternalProceduresAndFunctions

Procedure TakeRounding(Table, Value, ColumnName)
	
	MaxVal = 0;
	FindingRow = Undefined;
	For Each Row In Table Do
		If FindingRow=Undefined Or Row[ColumnName]>MaxVal Then
			MaxVal = Row[ColumnName];
			FindingRow = Row;
		EndIf; 
	EndDo;
	If FindingRow<>Undefined Then
		FindingRow[ColumnName] = FindingRow[ColumnName] + Value;
	EndIf; 
	
EndProcedure

Procedure CollapseAllColumns(Table, TotalColumns)
	
	SkipColumns = StringFunctionsClientServer.GetStringFromSubstringArray(TotalColumns);
	CollapsingColumns = "";
	For Each Column In Table.Columns Do
		If SkipColumns.Find(Column.Name)<>Undefined Then
			Continue;
		EndIf; 
		CollapsingColumns = CollapsingColumns + ?(IsBlankString(CollapsingColumns), "", ", ") + Column.Name;
	EndDo;
	
	Table.GroupBy(CollapsingColumns, TotalColumns); 
	
EndProcedure

#EndRegion