#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

///////////////////////////////////////////////////////////////////////////////
// PROCEDURES OF FILLING THE DOCUMENT

// Procedure fills tabular section according to specification.
//
Procedure FillTabularSectionBySpecification(NodesSpecificationStack, NodesTable = Undefined) Export
	
	ItsDisassembly = (OperationKind = Enums.OperationKindsInventoryAssembly.Disassembly);
	
	Query = Новый Запрос;
	Query.TempTablesManager = New TempTablesManager;
	
	AddTempTables(Query);
	AddDistributionBySpecification(Query);
	FillInventoryByStages(Query);

	
EndProcedure // FillTabularSectionBySpecification()

// Procedure fills out the Quantity column according to reserves to be ordered.
//
Procedure FillColumnReserveByReserves() Export
	
	If Inventory.Count() = 0 Then
		Return;
	EndIf;
	
	Inventory.LoadColumn(New Array(Inventory.Count()), "Reserve");
	
	TempTablesManager = New TempTablesManager;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	TableInventory.ProductsAndServices AS ProductsAndServices,
	|	TableInventory.Characteristic AS Characteristic,
	|	TableInventory.Batch AS Batch,
	|	&Order AS CustomerOrder
	|INTO TemporaryTableInventory
	|FROM
	|	&TableInventory AS TableInventory";
	
	Query.SetParameter("TableInventory", Inventory.Unload());
	Query.SetParameter("Order", ?(ValueIsFilled(CustomerOrder), CustomerOrder, Documents.CustomerOrder.EmptyRef()));
	Query.Execute();
	
	Query.Text =
	"SELECT
	|	InventoryBalances.Company AS Company,
	|	InventoryBalances.StructuralUnit AS StructuralUnit,
	|	InventoryBalances.GLAccount AS GLAccount,
	|	InventoryBalances.CustomerOrder AS CustomerOrder,
	|	InventoryBalances.ProductsAndServices AS ProductsAndServices,
	|	InventoryBalances.Characteristic AS Characteristic,
	|	InventoryBalances.Batch AS Batch,
	|	SUM(InventoryBalances.QuantityBalance) AS QuantityBalance
	|FROM
	|	(SELECT
	|		InventoryBalances.Company AS Company,
	|		InventoryBalances.StructuralUnit AS StructuralUnit,
	|		InventoryBalances.GLAccount AS GLAccount,
	|		InventoryBalances.CustomerOrder AS CustomerOrder,
	|		InventoryBalances.ProductsAndServices AS ProductsAndServices,
	|		InventoryBalances.Characteristic AS Characteristic,
	|		InventoryBalances.Batch AS Batch,
	|		InventoryBalances.QuantityBalance AS QuantityBalance
	|	FROM
	|		AccumulationRegister.Inventory.Balance(
	|				,
	|				(Company, StructuralUnit, GLAccount, ProductsAndServices, Characteristic, Batch, CustomerOrder) In
	|					(SELECT
	|						&Company,
	|						&StructuralUnit,
	|						CASE
	|							WHEN &StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Department)
	|								THEN TableInventory.ProductsAndServices.ExpensesGLAccount
	|							ELSE TableInventory.ProductsAndServices.InventoryGLAccount
	|						END,
	|						TableInventory.ProductsAndServices,
	|						TableInventory.Characteristic,
	|						TableInventory.Batch,
	|						TableInventory.CustomerOrder
	|					FROM
	|						TemporaryTableInventory AS TableInventory
	|					WHERE
	|						TableInventory.CustomerOrder <> VALUE(Document.CustomerOrder.EmptyRef))) AS InventoryBalances
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentRegisterRecordsInventory.Company,
	|		DocumentRegisterRecordsInventory.StructuralUnit,
	|		DocumentRegisterRecordsInventory.GLAccount,
	|		DocumentRegisterRecordsInventory.CustomerOrder,
	|		DocumentRegisterRecordsInventory.ProductsAndServices,
	|		DocumentRegisterRecordsInventory.Characteristic,
	|		DocumentRegisterRecordsInventory.Batch,
	|		CASE
	|			WHEN DocumentRegisterRecordsInventory.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN ISNULL(DocumentRegisterRecordsInventory.Quantity, 0)
	|			ELSE -ISNULL(DocumentRegisterRecordsInventory.Quantity, 0)
	|		END
	|	FROM
	|		AccumulationRegister.Inventory AS DocumentRegisterRecordsInventory
	|	WHERE
	|		DocumentRegisterRecordsInventory.Recorder = &Ref
	|		AND DocumentRegisterRecordsInventory.Period <= &Period
	|		AND DocumentRegisterRecordsInventory.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND DocumentRegisterRecordsInventory.CustomerOrder <> VALUE(Document.CustomerOrder.EmptyRef)) AS InventoryBalances
	|
	|GROUP BY
	|	InventoryBalances.Company,
	|	InventoryBalances.StructuralUnit,
	|	InventoryBalances.GLAccount,
	|	InventoryBalances.CustomerOrder,
	|	InventoryBalances.ProductsAndServices,
	|	InventoryBalances.Characteristic,
	|	InventoryBalances.Batch";
	
	Query.SetParameter("Period", Date);
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Company", SmallBusinessServer.GetCompany(Company));
	Query.SetParameter("StructuralUnit", InventoryStructuralUnit);
	Query.SetParameter("StructuralUnitType", InventoryStructuralUnit.StructuralUnitType);
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	While Selection.Next() Do
		
		StructureForSearch = New Structure;
		StructureForSearch.Insert("ProductsAndServices", Selection.ProductsAndServices);
		StructureForSearch.Insert("Characteristic", Selection.Characteristic);
		StructureForSearch.Insert("Batch", Selection.Batch);
		
		TotalBalance = Selection.QuantityBalance;
		ArrayOfRowsInventory = Inventory.FindRows(StructureForSearch);
		For Each StringInventory IN ArrayOfRowsInventory Do
			
			TotalBalance = ?(TypeOf(StringInventory.MeasurementUnit) = Type("CatalogRef.UOMClassifier"), TotalBalance, TotalBalance / StringInventory.MeasurementUnit.Factor);
			If StringInventory.Quantity >= TotalBalance Then
				StringInventory.Reserve = TotalBalance;
				TotalBalance = 0;
			Else
				StringInventory.Reserve = StringInventory.Quantity;
				TotalBalance = TotalBalance - StringInventory.Quantity;
				TotalBalance = ?(TypeOf(StringInventory.MeasurementUnit) = Type("CatalogRef.UOMClassifier"), TotalBalance, TotalBalance * StringInventory.MeasurementUnit.Factor);
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure // FillColumnReserveByReserves()

// Procedure for filling the document basing on Production order.
//
Procedure FillByProductionOrder(FillingData) Export
	
	// Header filling.
	Query = New Query;
	Query.Text =
	"SELECT
	|	ProductionOrder.Ref AS BasisRef,
	|	ProductionOrder.Posted AS BasisPosted,
	|	ProductionOrder.Closed AS Closed,
	|	ProductionOrder.OrderState AS OrderState,
	|	CASE
	|		WHEN ProductionOrder.OperationKind = VALUE(Enum.OperationKindsProductionOrder.Assembly)
	|			THEN VALUE(Enum.OperationKindsInventoryAssembly.Assembly)
	|		ELSE VALUE(Enum.OperationKindsInventoryAssembly.Disassembly)
	|	END AS OperationKind,
	|	ProductionOrder.Start AS Start,
	|	ProductionOrder.Finish AS Finish,
	|	ProductionOrder.Ref AS ProductionOrder,
	|	ProductionOrder.CustomerOrder AS CustomerOrder,
	|	ProductionOrder.Company AS Company,
	|	ProductionOrder.StructuralUnit AS StructuralUnit,
	|	CASE
	|		WHEN ProductionOrder.StructuralUnit.TransferRecipient.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Warehouse)
	|				OR ProductionOrder.StructuralUnit.TransferRecipient.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Department)
	|			THEN ProductionOrder.StructuralUnit.TransferRecipient
	|		ELSE VALUE(Catalog.StructuralUnits.EmptyRef)
	|	END AS ProductsStructuralUnit,
	|	CASE
	|		WHEN ProductionOrder.StructuralUnit.TransferRecipient.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Warehouse)
	|				OR ProductionOrder.StructuralUnit.TransferRecipient.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Department)
	|			THEN ProductionOrder.StructuralUnit.TransferRecipientCell
	|		ELSE VALUE(Catalog.Cells.EmptyRef)
	|	END AS ProductsCell,
	|	CASE
	|		WHEN ProductionOrder.StructuralUnit.TransferSource.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Warehouse)
	|				OR ProductionOrder.StructuralUnit.TransferSource.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Department)
	|			THEN ProductionOrder.StructuralUnit.TransferSource
	|		ELSE VALUE(Catalog.StructuralUnits.EmptyRef)
	|	END AS InventoryStructuralUnit,
	|	CASE
	|		WHEN ProductionOrder.StructuralUnit.TransferSource.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Warehouse)
	|				OR ProductionOrder.StructuralUnit.TransferSource.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Department)
	|			THEN ProductionOrder.StructuralUnit.TransferSourceCell
	|		ELSE VALUE(Catalog.Cells.EmptyRef)
	|	END AS CellInventory,
	|	ProductionOrder.StructuralUnit.DisposalsRecipient AS DisposalsStructuralUnit,
	|	ProductionOrder.StructuralUnit.DisposalsRecipientCell AS DisposalsCell
	|FROM
	|	Document.ProductionOrder AS ProductionOrder
	|WHERE
	|	ProductionOrder.Ref = &BasisDocument";
	
	Query.SetParameter("BasisDocument", FillingData);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		VerifiedAttributesValues = New Structure("OrderState, Closed, Posted", Selection.OrderState, Selection.Closed, Selection.BasisPosted);
		Documents.ProductionOrder.VerifyEnteringAbilityByProductionOrder(Selection.BasisRef, VerifiedAttributesValues);
	EndDo;
	
	IntermediateStructuralUnit = StructuralUnit;
	FillPropertyValues(ThisObject, Selection);
	
	If ValueIsFilled(StructuralUnit) Then
			
		If Not ValueIsFilled(ProductsStructuralUnit) Then
			ProductsStructuralUnit = StructuralUnit;
		EndIf;
		
		If Not ValueIsFilled(InventoryStructuralUnit) Then
			InventoryStructuralUnit = StructuralUnit;
		EndIf;
		
		If Not ValueIsFilled(DisposalsStructuralUnit) Then
			DisposalsStructuralUnit = StructuralUnit;
		EndIf;
		
	EndIf;
	
	If IntermediateStructuralUnit <> StructuralUnit Then
		Cell = Undefined;
	EndIf;
	
	// Filling out tabular section.
	Query = New Query;
	Query.Text =
	"SELECT
	|	OrdersBalance.ProductionOrder AS ProductionOrder,
	|	OrdersBalance.ProductsAndServices AS ProductsAndServices,
	|	OrdersBalance.Characteristic AS Characteristic,
	|	SUM(OrdersBalance.QuantityBalance) AS QuantityBalance
	|FROM
	|	(SELECT
	|		OrdersBalance.ProductionOrder AS ProductionOrder,
	|		OrdersBalance.ProductsAndServices AS ProductsAndServices,
	|		OrdersBalance.Characteristic AS Characteristic,
	|		OrdersBalance.QuantityBalance AS QuantityBalance
	|	FROM
	|		AccumulationRegister.ProductionOrders.Balance(
	|				,
	|				ProductionOrder = &BasisDocument
	|					AND ProductsAndServices.ProductsAndServicesType = VALUE(Enum.ProductsAndServicesTypes.InventoryItem)) AS OrdersBalance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentRegisterRecordsProductionOrders.ProductionOrder,
	|		DocumentRegisterRecordsProductionOrders.ProductsAndServices,
	|		DocumentRegisterRecordsProductionOrders.Characteristic,
	|		CASE
	|			WHEN DocumentRegisterRecordsProductionOrders.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN ISNULL(DocumentRegisterRecordsProductionOrders.Quantity, 0)
	|			ELSE -ISNULL(DocumentRegisterRecordsProductionOrders.Quantity, 0)
	|		END
	|	FROM
	|		AccumulationRegister.ProductionOrders AS DocumentRegisterRecordsProductionOrders
	|	WHERE
	|		DocumentRegisterRecordsProductionOrders.Recorder = &Ref) AS OrdersBalance
	|
	|GROUP BY
	|	OrdersBalance.ProductionOrder,
	|	OrdersBalance.ProductsAndServices,
	|	OrdersBalance.Characteristic
	|
	|HAVING
	|	SUM(OrdersBalance.QuantityBalance) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductionOrder.Products.(
	|		ProductsAndServices AS ProductsAndServices,
	|		ProductsAndServices.ProductsAndServicesType AS ProductsAndServicesType,
	|		Characteristic AS Characteristic,
	|		Quantity AS Quantity,
	|		CASE
	|			WHEN VALUETYPE(ProductionOrder.Products.MeasurementUnit) = TYPE(Catalog.UOMClassifier)
	|				THEN 1
	|			ELSE ProductionOrder.Products.MeasurementUnit.Factor
	|		END AS Factor,
	|		MeasurementUnit AS MeasurementUnit,
	|		Specification AS Specification,
	|		CASE
	|			WHEN ProductionOrder.Products.Ref.OperationKind = VALUE(Enum.OperationKindsInventoryAssembly.Disassembly)
	|					AND ProductionOrder.Products.CustomerOrder <> VALUE(Document.CustomerOrder.EmptyRef)
	|					AND ProductionOrder.Products.StructuralUnit <> VALUE(Catalog.StructuralUnits.EmptyRef)
	|				THEN ProductionOrder.Products.StructuralUnit
	|			ELSE VALUE(Catalog.StructuralUnits.EmptyRef)
	|		END AS StructuralUnit,
	|		CompletiveStageDepartment AS CompletiveStageDepartment,
	|		CustomerOrder AS CustomerOrder,
	|		ConnectionKey AS ConnectionKey
	|	) AS Products,
	|	ProductionOrder.Inventory.(
	|		CASE
	|			WHEN FunctionalOptionUseProductionStages.Value
	|					AND ProductionOrder.Inventory.Ref.OperationKind = VALUE(Enum.OperationKindsInventoryAssembly.Assembly)
	|				THEN ProductionOrder.Inventory.Stage
	|			ELSE VALUE(Catalog.ProductionStages.EmptyRef)
	|		END AS Stage,
	|		ProductsAndServices AS ProductsAndServices,
	|		ProductsAndServices.ProductsAndServicesType AS ProductsAndServicesType,
	|		Characteristic AS Characteristic,
	|		Quantity AS Quantity,
	|		CASE
	|			WHEN VALUETYPE(ProductionOrder.Inventory.MeasurementUnit) = TYPE(Catalog.UOMClassifier)
	|				THEN 1
	|			ELSE ProductionOrder.Inventory.MeasurementUnit.Factor
	|		END AS Factor,
	|		MeasurementUnit AS MeasurementUnit,
	|		Specification AS Specification,
	|		CASE
	|			WHEN ProductionOrder.Inventory.Ref.OperationKind = VALUE(Enum.OperationKindsInventoryAssembly.Assembly)
	|					AND ProductionOrder.Inventory.CustomerOrder <> VALUE(Document.CustomerOrder.EmptyRef)
	|					AND ProductionOrder.Inventory.StructuralUnit <> VALUE(Catalog.StructuralUnits.EmptyRef)
	|				THEN ProductionOrder.Inventory.StructuralUnit
	|			ELSE VALUE(Catalog.StructuralUnits.EmptyRef)
	|		END AS StructuralUnit,
	|		CustomerOrder As CustomerOrder,
	|		1 AS CostPercentage
	|	) AS Inventory
	|FROM
	|	Document.ProductionOrder AS ProductionOrder,
	|	Constant.FunctionalOptionUseProductionStages AS FunctionalOptionUseProductionStages
	|WHERE
	|	ProductionOrder.Ref = &BasisDocument";
	
	Query.Text = Query.Text + ";";
	
	If FillingData.OperationKind = Enums.OperationKindsProductionOrder.Disassembly Then
		
		TabularSectionName = "Inventory";
		Query.Text = Query.Text +
		"SELECT
		|	OrdersBalance.ProductsAndServices AS ProductsAndServices,
		|	OrdersBalance.Characteristic AS Characteristic,
		|	OrdersBalance.MeasurementUnit AS MeasurementUnit,
		|	OrdersBalance.Specification AS Specification,
		|	SUM(OrdersBalance.Reserve) AS Reserve,
		|	SUM(OrdersBalance.Quantity) AS Quantity
		|FROM
		|	(SELECT
		|		OrderForProductsProduction.ProductsAndServices AS ProductsAndServices,
		|		OrderForProductsProduction.Characteristic AS Characteristic,
		|		OrderForProductsProduction.MeasurementUnit AS MeasurementUnit,
		|		OrderForProductsProduction.Specification AS Specification,
		|		OrderForProductsProduction.Reserve AS Reserve,
		|		OrderForProductsProduction.Quantity AS Quantity
		|	FROM
		|		Document.ProductionOrder.Products AS OrderForProductsProduction
		|	WHERE
		|		OrderForProductsProduction.Ref = &BasisDocument
		|		AND OrderForProductsProduction.ProductsAndServices.ProductsAndServicesType = VALUE(Enum.ProductsAndServicesTypes.InventoryItem)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		InventoryAssemblyProducts.ProductsAndServices,
		|		InventoryAssemblyProducts.Characteristic,
		|		InventoryAssemblyProducts.MeasurementUnit,
		|		InventoryAssemblyProducts.Specification,
		|		-InventoryAssemblyProducts.Reserve,
		|		-InventoryAssemblyProducts.Quantity
		|	FROM
		|		Document.InventoryAssembly.Products AS InventoryAssemblyProducts
		|	WHERE
		|		InventoryAssemblyProducts.Ref.Posted
		|		AND InventoryAssemblyProducts.Ref.BasisDocument = &BasisDocument
		|		AND Not InventoryAssemblyProducts.Ref = &Ref) AS OrdersBalance
		|
		|GROUP BY
		|	OrdersBalance.ProductsAndServices,
		|	OrdersBalance.Characteristic,
		|	OrdersBalance.MeasurementUnit,
		|	OrdersBalance.Specification
		|
		|HAVING
		|	SUM(OrdersBalance.Quantity) > 0";
		
	Else
		
		TabularSectionName = "Products";
		Query.Text = Query.Text +
		"SELECT
		|	OrdersBalance.ProductsAndServices AS ProductsAndServices,
		|	OrdersBalance.Characteristic AS Characteristic,
		|	OrdersBalance.MeasurementUnit AS MeasurementUnit,
		|	OrdersBalance.Specification AS Specification,
		|	SUM(OrdersBalance.Quantity) AS Quantity
		|FROM
		|	(SELECT
		|		ProductionOrderInventory.ProductsAndServices AS ProductsAndServices,
		|		ProductionOrderInventory.Characteristic AS Characteristic,
		|		ProductionOrderInventory.MeasurementUnit AS MeasurementUnit,
		|		ProductionOrderInventory.Specification AS Specification,
		|		ProductionOrderInventory.Quantity AS Quantity
		|	FROM
		|		Document.ProductionOrder.Inventory AS ProductionOrderInventory
		|	WHERE
		|		ProductionOrderInventory.Ref = &BasisDocument
		|		AND ProductionOrderInventory.ProductsAndServices.ProductsAndServicesType = VALUE(Enum.ProductsAndServicesTypes.InventoryItem)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		InventoryAssemblyInventory.ProductsAndServices,
		|		InventoryAssemblyInventory.Characteristic,
		|		InventoryAssemblyInventory.MeasurementUnit,
		|		InventoryAssemblyInventory.Specification,
		|		-InventoryAssemblyInventory.Quantity
		|	FROM
		|		Document.InventoryAssembly.Inventory AS InventoryAssemblyInventory
		|	WHERE
		|		InventoryAssemblyInventory.Ref.Posted
		|		AND InventoryAssemblyInventory.Ref.BasisDocument = &BasisDocument
		|		AND Not InventoryAssemblyInventory.Ref = &Ref) AS OrdersBalance
		|
		|GROUP BY
		|	OrdersBalance.ProductsAndServices,
		|	OrdersBalance.Characteristic,
		|	OrdersBalance.MeasurementUnit,
		|	OrdersBalance.Specification
		|
		|HAVING
		|	SUM(OrdersBalance.Quantity) > 0";
		
	EndIf;
	
	Query.SetParameter("BasisDocument", FillingData);
	Query.SetParameter("Ref", Ref);
	
	ResultsArray = Query.ExecuteBatch();
	BalanceTable = ResultsArray[0].Unload();
	BalanceTable.Indexes.Add("ProductionOrder,ProductsAndServices,Characteristic");
	
	Products.Clear();
	Inventory.Clear();
	Disposals.Clear();
	If BalanceTable.Count() > 0 Then
		
		Selection = ResultsArray[1].Select();
		Selection.Next();
		For Each SelectionProducts IN Selection[TabularSectionName].Unload() Do
			
			If SelectionProducts.ProductsAndServicesType <> Enums.ProductsAndServicesTypes.InventoryItem Then
				Continue;
			EndIf;
			
			StructureForSearch = New Structure;
			StructureForSearch.Insert("ProductionOrder", FillingData);
			StructureForSearch.Insert("ProductsAndServices", SelectionProducts.ProductsAndServices);
			StructureForSearch.Insert("Characteristic", SelectionProducts.Characteristic);
			
			BalanceRowsArray = BalanceTable.FindRows(StructureForSearch);
			If BalanceRowsArray.Count() = 0 Then
				Continue;
			EndIf;
			
			NewRow = ThisObject[TabularSectionName].Add();
			FillPropertyValues(NewRow, SelectionProducts);
			
			QuantityToWriteOff = SelectionProducts.Quantity * SelectionProducts.Factor;
			BalanceRowsArray[0].QuantityBalance = BalanceRowsArray[0].QuantityBalance - QuantityToWriteOff;
			If BalanceRowsArray[0].QuantityBalance < 0 Then
				
				NewRow.Quantity = (QuantityToWriteOff + BalanceRowsArray[0].QuantityBalance) / SelectionProducts.Factor;
				
			EndIf;
			
			If BalanceRowsArray[0].QuantityBalance <= 0 Then
				BalanceTable.Delete(BalanceRowsArray[0]);
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If Products.Count() > 0 Then
		Selection = ResultsArray[2].Select();
		While Selection.Next() Do
			NewRow = Inventory.Add();
			FillPropertyValues(NewRow, Selection);
		EndDo;
	ElsIf Inventory.Count() > 0 Then
		Selection = ResultsArray[2].Select();
		While Selection.Next() Do
			NewRow = Products.Add();
			FillPropertyValues(NewRow, Selection);
		EndDo;
	EndIf;
	
	// Fill out according to specification.
	If Products.Count() > 0 AND FillingData.Inventory.Count() = 0 Then
		NodesSpecificationStack = New Array;
		FillTabularSectionBySpecification(NodesSpecificationStack);
	EndIf;
	
	If ManualDistribution Then
		ProductionServer.DistribInventory(Products, Inventory, InventoryDistribution, CompletedStages, ProductionOrder);
	EndIf; 

	
	// Filling out reserves.
	If TabularSectionName = "Products" AND Inventory.Count() > 0
		AND Constants.FunctionalOptionInventoryReservation.Get()
		AND ValueIsFilled(InventoryStructuralUnit) Then
		FillColumnReserveByReserves();
	EndIf;
	
EndProcedure // FillByProductionOrder()

// Procedure for filling the document basing on Customer order.
//
Procedure FillUsingCustomerOrder(FillingData) Export
	
	If OperationKind = Enums.OperationKindsInventoryAssembly.Disassembly Then
		TabularSectionName = "Inventory";
	Else
		TabularSectionName = "Products";
	EndIf;
	
	Query = New Query( 
	"SELECT
	|	CustomerOrderInventory.Ref AS CustomerOrder,
	|	DATEADD(CustomerOrderInventory.ShipmentDate, DAY, -CustomerOrderInventory.ProductsAndServices.ReplenishmentDeadline) AS Start,
	|	CustomerOrderInventory.ShipmentDate AS Finish,
	|	CustomerOrderInventory.Ref.Company AS Company,
	|	CustomerOrderInventory.Ref.SalesStructuralUnit AS StructuralUnit,
	|	CASE
	|		WHEN CustomerOrderInventory.Ref.SalesStructuralUnit.TransferRecipient.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Warehouse)
	|				OR CustomerOrderInventory.Ref.SalesStructuralUnit.TransferRecipient.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Department)
	|			THEN CustomerOrderInventory.Ref.SalesStructuralUnit.TransferRecipient
	|		ELSE VALUE(Catalog.StructuralUnits.EmptyRef)
	|	END AS ProductsStructuralUnit,
	|	CASE
	|		WHEN CustomerOrderInventory.Ref.SalesStructuralUnit.TransferRecipient.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Warehouse)
	|				OR CustomerOrderInventory.Ref.SalesStructuralUnit.TransferRecipient.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Department)
	|			THEN CustomerOrderInventory.Ref.SalesStructuralUnit.TransferRecipientCell
	|		ELSE VALUE(Catalog.Cells.EmptyRef)
	|	END AS ProductsCell,
	|	CASE
	|		WHEN CustomerOrderInventory.Ref.SalesStructuralUnit.TransferSource.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Warehouse)
	|				OR CustomerOrderInventory.Ref.SalesStructuralUnit.TransferSource.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Department)
	|			THEN CustomerOrderInventory.Ref.SalesStructuralUnit.TransferSource
	|		ELSE VALUE(Catalog.StructuralUnits.EmptyRef)
	|	END AS InventoryStructuralUnit,
	|	CASE
	|		WHEN CustomerOrderInventory.Ref.SalesStructuralUnit.TransferSource.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Warehouse)
	|				OR CustomerOrderInventory.Ref.SalesStructuralUnit.TransferSource.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Department)
	|			THEN CustomerOrderInventory.Ref.SalesStructuralUnit.TransferSourceCell
	|		ELSE VALUE(Catalog.Cells.EmptyRef)
	|	END AS CellInventory,
	|	CustomerOrderInventory.Ref.SalesStructuralUnit.DisposalsRecipient AS DisposalsStructuralUnit,
	|	CustomerOrderInventory.Ref.SalesStructuralUnit.DisposalsRecipientCell AS DisposalsCell,
	|	CustomerOrderInventory.ProductsAndServices AS ProductsAndServices,
	|	CustomerOrderInventory.ProductsAndServices.ProductsAndServicesType AS ProductsAndServicesType,
	|	CustomerOrderInventory.Characteristic AS Characteristic,
	|	CustomerOrderInventory.MeasurementUnit AS MeasurementUnit,
	|	CustomerOrderInventory.Quantity AS Quantity,
	|	CustomerOrderInventory.Reserve AS Reserve,
	|	CustomerOrderInventory.Specification AS Specification
	|FROM
	|	Document.CustomerOrder.Inventory AS CustomerOrderInventory
	|WHERE
	|	CustomerOrderInventory.Ref = &BasisDocument
	|	AND (CustomerOrderInventory.Specification <> VALUE(Catalog.Specifications.EmptyRef)
	|			OR CustomerOrderInventory.ProductsAndServices.ReplenishmentMethod = VALUE(Enum.InventoryReplenishmentMethods.Production)
	|			OR &OperationKind = VALUE(Enum.OperationKindsProductionOrder.Disassembly))");
	
	Query.SetParameter("BasisDocument", FillingData);
	Query.SetParameter("OperationKind", OperationKind);
	
	Products.Clear();
	Inventory.Clear();
	
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		
		QueryResultSelection = QueryResult.Select();
		QueryResultSelection.Next();
		FillPropertyValues(ThisObject, QueryResultSelection);
		
		If ValueIsFilled(StructuralUnit) Then
			
			If Not ValueIsFilled(ProductsStructuralUnit) Then
				ProductsStructuralUnit = StructuralUnit;
			EndIf;
			
			If Not ValueIsFilled(InventoryStructuralUnit) Then
				InventoryStructuralUnit = StructuralUnit;
			EndIf;
			
			If Not ValueIsFilled(DisposalsStructuralUnit) Then
				DisposalsStructuralUnit = StructuralUnit;
			EndIf;
			
		EndIf;
		
		QueryResultSelection.Reset();
		While QueryResultSelection.Next() Do
		
			If ValueIsFilled(QueryResultSelection.ProductsAndServices) Then
			
				If QueryResultSelection.ProductsAndServicesType <> Enums.ProductsAndServicesTypes.InventoryItem Then
					Continue;
				EndIf;
				
				NewRow = ThisObject[TabularSectionName].Add();
				FillPropertyValues(NewRow, QueryResultSelection);
				
				If Not ValueIsFilled(NewRow.Specification) Then
					NewRow.Specification = SmallBusinessServer.GetDefaultSpecification(NewRow.ProductsAndServices, NewRow.Characteristic);
				EndIf;
				
			EndIf;
		
		EndDo;
		
		If Products.Count() > 0 Then
			NodesSpecificationStack = New Array;
			FillTabularSectionBySpecification(NodesSpecificationStack);
		EndIf;
		
	EndIf;
	
EndProcedure // FillByCustomerOrder()

Procedure FillTabularSectionByBalance() Export
	
Inventory.Clear();
	SerialNumbers.Clear();
	
	OrderArray = New Array;
	If CustomerOrderPosition = Enums.AttributePositionOnForm.InTabularSection Then
		ValueTable = Products.Unload(, "CustomerOrder");
		ValueTable.GroupBy("CustomerOrder");
		For Each OrderRow In ValueTable Do
			If Not ValueIsFilled(OrderRow.CustomerOrder) Then
				Continue;
			EndIf; 
			OrderArray.Add(OrderRow.CustomerOrder);
		EndDo;
		
	ElsIf ЗначениеЗаполнено(CustomerOrder) Then
		OrderArray.Add(CustomerOrder);
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Orders", OrderArray);
	Query.SetParameter("StrUnit", InventoryStructuralUnit);
	Query.SetParameter("Cell", CellInventory);
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Company", SmallBusinessServer.GetCompany(Company));
	If CustomerOrderPosition = Enums.AttributePositionOnForm.InTabularSection Then

		Query.SetParameter("HeaderCustomerOrder", Documents.CustomerOrder.EmptyRef());
	Else
		Query.SetParameter("HeaderCustomerOrder", CustomerOrder);
	EndIf; 
	Query.Text =
	"SELECT
	|	NestedQuery.StructuralUnit AS StructuralUnit,
	|	NestedQuery.ProductsAndServices AS ProductsAndServices,
	|	NestedQuery.Characteristic AS Characteristic,
	|	NestedQuery.Batch AS Batch,
	|	CASE
	|		WHEN &HeaderCustomerOrder = VALUE(Document.CustomerOrder.EmptyRef)
	|			THEN NestedQuery.CustomerOrder
	|		ELSE &HeaderCustomerOrder
	|	END AS CustomerOrder,
	|	SUM(NestedQuery.Quantity) AS Quantity,
	|	SUM(CASE
	|			WHEN NestedQuery.CustomerOrder = VALUE(Document.CustomerOrder.EmptyRef)
	|				THEN 0
	|			ELSE NestedQuery.Quantity
	|		END) AS Reserve,
	|	NestedQuery.ProductsAndServices.MeasurementUnit AS MeasurementUnit,
	|	NestedQuery.ProductsAndServices.CountryOfOrigin AS CountryOfOrigin
	|FROM
	|	(SELECT
	|		InventoryBalance.StructuralUnit AS StructuralUnit,
	|		InventoryBalance.ProductsAndServices AS ProductsAndServices,
	|		InventoryBalance.Characteristic AS Characteristic,
	|		InventoryBalance.Batch AS Batch,
	|		InventoryBalance.CustomerOrder AS CustomerOrder,
	|		InventoryBalance.QuantityBalance AS Quantity
	|	FROM
	|		AccumulationRegister.Inventory.Balance(
	|				,
	|				Company = &Company
	|					AND StructuralUnit = &StrUnit
	|					AND (CustomerOrder IN (&Orders)
	|						OR CustomerOrder = VALUE(Document.CustomerOrder.EmptyRef))) AS InventoryBalance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Inventory.StructuralUnit,
	|		Inventory.ProductsAndServices,
	|		Inventory.Characteristic,
	|		Inventory.Batch,
	|		Inventory.CustomerOrder,
	|		CASE
	|			WHEN Inventory.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN Inventory.Quantity
	|			ELSE -Inventory.Quantity
	|		END
	|	FROM
	|		AccumulationRegister.Inventory AS Inventory
	|	WHERE
	|		Inventory.Recorder = &Ref
	|		AND Inventory.Company = &Company
	|		AND Inventory.StructuralUnit = &StrUnit
	|		AND (Inventory.CustomerOrder IN (&Orders)
	|				OR Inventory.CustomerOrder = VALUE(Document.CustomerOrder.EmptyRef))) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Characteristic,
	|	NestedQuery.ProductsAndServices,
	|	CASE
	|		WHEN &HeaderCustomerOrder = VALUE(Document.CustomerOrder.EmptyRef)
	|			THEN NestedQuery.CustomerOrder
	|		ELSE &HeaderCustomerOrder
	|	END,
	|	NestedQuery.Batch,
	|	NestedQuery.StructuralUnit,
	|	NestedQuery.ProductsAndServices.MeasurementUnit,
	|	NestedQuery.ProductsAndServices.CountryOfOrigin
	|
	|HAVING
	|	SUM(NestedQuery.Quantity) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.ProductsAndServices AS ProductsAndServices,
	|	NestedQuery.Characteristic AS Characteristic,
	|	NestedQuery.Batch AS Batch,
	|	NestedQuery.StructuralUnit AS StructuralUnit,
	|	NestedQuery.Cell AS Cell,
	|	SUM(NestedQuery.Quantity) AS Quantity
	|FROM
	|	(SELECT
	|		WarehouseInventoryBalance.ProductsAndServices AS ProductsAndServices,
	|		WarehouseInventoryBalance.Characteristic AS Characteristic,
	|		WarehouseInventoryBalance.Batch AS Batch,
	|		WarehouseInventoryBalance.StructuralUnit AS StructuralUnit,
	|		WarehouseInventoryBalance.Cell AS Cell,
	|		WarehouseInventoryBalance.QuantityBalance AS Quantity
	|	FROM
	|		AccumulationRegister.InventoryInWarehouses.Balance(
	|				,
	|				Company = &Company
	|					AND StructuralUnit = &StrUnit
	|					AND Cell = &Cell) AS WarehouseInventoryBalance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		WarehouseInventory.ProductsAndServices,
	|		WarehouseInventory.Characteristic,
	|		WarehouseInventory.Batch,
	|		WarehouseInventory.StructuralUnit,
	|		WarehouseInventory.Cell,
	|		CASE
	|			WHEN WarehouseInventory.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN WarehouseInventory.Quantity
	|			ELSE -WarehouseInventory.Quantity
	|		END
	|	FROM
	|		AccumulationRegister.InventoryInWarehouses AS WarehouseInventory
	|	WHERE
	|		WarehouseInventory.Recorder = &Ref
	|		AND WarehouseInventory.Company = &Company
	|		AND WarehouseInventory.StructuralUnit = &StrUnit
	|		AND WarehouseInventory.Cell = &Cell) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Characteristic,
	|	NestedQuery.Cell,
	|	NestedQuery.ProductsAndServices,
	|	NestedQuery.Batch,
	|	NestedQuery.StructuralUnit
	|
	|HAVING
	|	SUM(NestedQuery.Quantity) > 0";
	Result = Query.ExecuteBatch();
	BalanceTable = Result.Get(1).Unload();
	BalanceTable.Indexes.Add("ProductsAndServices, Characteristic, StructuralUnit, Batch");
	
	Selection = Result.Get(0).Select();
	While Selection.Next() Do
		FilterStructure = New Structure("ProductsAndServices, Characteristic, StructuralUnit, Batch");
		FillPropertyValues(FilterStructure, Selection);
		BalanceRows = BalanceTable.FindRows(FilterStructure);
		ToWriteOff = Selection.Quantity;
		Rsrv = Selection.Reserve;
		For Each BalanceRow In BalanceRows Do
			WriteOff = Min(BalanceRow.Quantity, ToWriteOff);
			If WriteOff=0 Then
				Continue;
			EndIf; 
			BalanceRow.Quantity = BalanceRow.Quantity - WriteOff;
			ToWriteOff = ToWriteOff - WriteOff;
			NewRow = Inventory.Add();
			FillPropertyValues(NewRow, Selection);
			NewRow.Cell = BalanceRow.Cell;
			NewRow.Reserve = Min(NewRow.Quantity, Rsrv);
			Rsrv = Rsrv - NewRow.Reserve;
			If ToWriteOff<=0 Then
				Break;
			EndIf;
		EndDo;
	EndDo;

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// EVENT HANDLERS

// Procedure - event handler FillingProcessor object.
//
Procedure Filling(FillingData, StandardProcessing) Export
	
	If TypeOf(FillingData) = Type("DocumentRef.CustomerOrder") Then
		FillUsingCustomerOrder(FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.ProductionOrder") Then
		FillByProductionOrder(FillingData);
	EndIf;
	
EndProcedure // FillingProcessor()

// Procedure - BeforeWrite event handler.
//
Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	ProductsAndServicesList = "";
	FOUseCharacteristics = Constants.FunctionalOptionUseCharacteristics.Get();
	For Each StringProducts IN Products Do
		
		If Not ValueIsFilled(StringProducts.ProductsAndServices) Then
			Continue;
		EndIf;
		
		CharacteristicPresentation = "";
		If FOUseCharacteristics And ValueIsFilled(StringProducts.Characteristic) Then
			CharacteristicPresentation = " (" + TrimAll(StringProducts.Characteristic) + ")";
		EndIf;
		
		If ValueIsFilled(ProductsAndServicesList) Then
			ProductsAndServicesList = ProductsAndServicesList + Chars.LF;
		EndIf;
		ProductsAndServicesList = ProductsAndServicesList + TrimAll(StringProducts.ProductsAndServices) + CharacteristicPresentation + ", " + StringProducts.Quantity + " " + TrimAll(StringProducts.MeasurementUnit);
		
	EndDo;
	
	If WarehousePosition = Enums.AttributePositionOnForm.InTabularSection Then
		
		TabSec = ?(OperationKind= Enums.OperationKindsInventoryAssembly.Disassembly, Products, Inventory);
		InventoryStructuralUnit = HeaderStructuralUnit(TabSec, InventoryStructuralUnit);
		CellInventory = HeaderCell(TabSec, InventoryStructuralUnit, CellInventory);
		TabSec = ?(OperationKind=Enums.OperationKindsInventoryAssembly.Disassembly, Inventory, Products);
		For Each TabSecRow In TabSec Do
			TabSecRow.StructuralUnit = ProductsStructuralUnit;
			TabSecRow.Cell = ProductsCell;
		EndDo;
		
	ElsIf OperationKind = Enums.OperationKindsInventoryAssembly.Disassembly Then
		
		For Each TabSecRow In Inventory Do
			TabSecRow.StructuralUnit = ProductsStructuralUnit;
			TabSecRow.Cell = ProductsCell;
		EndDo; 
		For Each TabSecRow In Products Do
			TabSecRow.StructuralUnit = InventoryStructuralUnit;
			TabSecRow.Cell = CellInventory;
		EndDo; 
		
	ElsIf OperationKind = Enums.OperationKindsInventoryAssembly.Assembly Then
		For Each TabSecRow In Inventory Do
			TabSecRow.StructuralUnit = InventoryStructuralUnit;
			TabSecRow.Cell = CellInventory;
		EndDo; 
		For Each TabSecRow In Products Do
			TabSecRow.StructuralUnit = ProductsStructuralUnit;
			TabSecRow.Cell = ProductsCell;
		EndDo; 
	EndIf;
	
	If OperationKind = Enums.OperationKindsInventoryAssembly.Disassembly Then
		For Each TabSecRow In InventoryDistribution Do
			TabSecRow.StructuralUnit = ProductsStructuralUnit;
			TabSecRow.Cell = ProductsCell;
		EndDo; 
	EndIf; 
	
	If CustomerOrderPosition = Enums.AttributePositionOnForm.InTabularSection Then
		CustomerOrder = HeaderCustomerOrder(?(OperationKind=Enums.OperationKindsInventoryAssembly.Disassembly, Inventory, Products));
	Else
		For Each TabSecRow In Inventory Do
			TabSecRow.CustomerOrder = CustomerOrder;
		EndDo; 
		For Each TabSecRow In Products Do
			TabSecRow.CustomerOrder = CustomerOrder;
		EndDo; 
	EndIf; 
	
	If Not ManualDistribution
		And WriteMode=DocumentWriteMode.Posting Then
		ProductionServer.DistribInventory(Products, Inventory, InventoryDistribution, CompletedStages, ProductionOrder);
	EndIf;
	
	FillStructuralUnitsTypes();
	
EndProcedure // BeforeWrite()

// Procedure - event handler FillCheckProcessing object.
//
Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Inventory.Total("Reserve") > 0 Then
		
		If Not ValueIsFilled(CustomerOrder) Then
			
			MessageText = NStr("vi = 'Chưa chỉ ra đơn hàng của khách-nguồn dự phòng!';
								|ru = 'Не указан заказ покупателя- источник резерва!';
								|en = 'Customer order which is a reserve source is not specified.';
								|En = 'Customer order which is a reserve source is not specified.'");
			SmallBusinessServer.ShowMessageAboutError(ThisObject, MessageText,,,"CustomerOrder",Cancel);
			
		EndIf;
		
	EndIf;
	
	If Constants.FunctionalOptionInventoryReservation.Get() Then
		
		If OperationKind = Enums.OperationKindsInventoryAssembly.Assembly Then
			
			For Each StringInventory IN Inventory Do
				
				If StringInventory.Reserve > StringInventory.Quantity Then
					
					MessageText = NStr("en='In row No. %Number% of the ""Inventory"" tabular section, the number of items for write-off from reserve exceeds the total inventory quantity.';ru='В строке №%Номер% табл. части ""Запасы"" количество позиций к списанию из резерва превышает общее количество запасов.';vi='Tại dòng số %Number% của phần bảng ""Vật tư"" số lượng mặt hàng chờ ghi giảm từ dự phòng vượt quá tổng số lượng vật tư.'");
					MessageText = StrReplace(MessageText, "%Number%", StringInventory.LineNumber);
					SmallBusinessServer.ShowMessageAboutError(
						ThisObject,
						MessageText,
						"Inventory",
						StringInventory.LineNumber,
						"Reserve",
						Cancel
					);
					
				EndIf;
				
			EndDo;
			
		Else
			
			For Each StringProducts IN Products Do
				
				If StringProducts.Reserve > StringProducts.Quantity Then
					
					MessageText = NStr("en='In row No. %Number% of the ""Products"" tabular section, the number of items for write-off from reserve exceeds the total inventory quantity.';ru='В строке №%Номер% табл. части ""Продукция"" количество позиций к списанию из резерва превышает общее количество продукции.';vi='Trong dòng số %Number% phần bảng ""Sản phẩm"" số lượng nhóm sản phẩm cần ghi giảm từ dự phòng vượt quá tổng số lượng sản phẩm.'");
					MessageText = StrReplace(MessageText, "%Number%", StringProducts.LineNumber);
					SmallBusinessServer.ShowMessageAboutError(
						ThisObject,
						MessageText,
						"Products",
						StringProducts.LineNumber,
						"Reserve",
						Cancel
					);
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	// Serial numbers
	WorkWithSerialNumbers.FillCheckingSerialNumbers(Cancel, Products, SerialNumbersProducts, StructuralUnit, ThisObject);
	WorkWithSerialNumbers.FillCheckingSerialNumbers(Cancel, Inventory, SerialNumbers, StructuralUnit, ThisObject);
	
	If WarehousePosition <> Enums.AttributePositionOnForm.InTabularSection Then
		CheckedAttributes.Add("InventoryStructuralUnit");
	Else
		If OperationKind = Enums.OperationKindsInventoryAssembly.Disassembly Then
			TabularSection = Products;
			TSName = "Products";
		Else
			TabularSection = Inventory;
			TSName = "Inventory";
		EndIf;
		For Each CurrTabSecRow In TabularSection Do
			If ValueIsFilled(CurrTabSecRow.StructuralUnit) Then
				Continue;
			EndIf;
			SmallBusinessServer.ShowMessageAboutError(
				ThisObject,
				StrTemplate(NStr("en='The column ""Warehouse"" in row %1 of list ""%2"" is not filled';ru='Не заполнена колонка ""Склад""  в строке %1 списка ""%2"" ';vi='Cột ""Kho"" trong hàng %1 của danh sách ""%2"" không được điền'"), CurrTabSecRow.LineNumber, TSName),
				TSName,
				CurrTabSecRow.LineNumber,
				"StructuralUnit",
				Cancel);
		EndDo;
	EndIf;
	// Сравнение таблицы материалов и распределения
	If ManualDistribution Then
		ProductionServer.CompareInventoryAndDictribution(ThisObject, Cancel);
	Else
		SmallBusinessServer.DeleteAttributeBeingChecked(CheckedAttributes, "InventoryDistribution.Quantity");
	EndIf;
	
	TabSecNames = New Array(1);
	TabSecNames[0] = "Products";
	If OperationKind = Enums.OperationKindsInventoryAssembly.Assembly Then
		
		TabSecNames[0] = "Inventory";
		
	EndIf;
	
	// CCD numbers
	CargoCustomsDeclarationsServer.OnProcessingFillingCheck(cancel, ThisObject, TabSecNames);
	
	// Этапы производства
	EmptyStecification = Catalogs.Specifications.EmptyRef();
	If GetFunctionalOption("UseProductionStages") 
		And OperationKind<>Enums.OperationKindsInventoryAssembly.Disassembly Then
		SpecsArray = New Array;
		For Each TabSecRow In Products Do
			If SpecsArray.Find(TabSecRow.Specification)=Undefined Then
				SpecsArray.Add(TabSecRow.Specification);
			EndIf;
			If Not ValueIsFilled(TabSecRow.Specification) Then
				Break;
			EndIf;
			If (CustomerOrderPosition = Enums.AttributePositionOnForm.InHeader And Not ValueIsFilled(CustomerOrder)) OR
				(CustomerOrderPosition = Enums.AttributePositionOnForm.InTabularSection And Not ValueIsFilled(TabSecRow.CustomerOrder)) Then
				SpecsArray.Add(EmptyStecification);
			EndIf; 
		EndDo; 
		
		If SpecsArray.Find(EmptyStecification)=Undefined Then
			StagesArray = ProductionServer.ProductionStagesOfSpecifications(SpecsArray);
			If StagesArray.Find(Catalogs.ProductionStages.EmptyRef())=Undefined Then
				CheckedAttributes.Add("Inventory.Stage");
				If ManualDistribution Then
					CheckedAttributes.Add("InventoryDistribution.Stage");
				EndIf; 
			EndIf; 
		EndIf;
	EndIf; 
	
EndProcedure // FillCheckProcessing()

// Procedure - event handler FillingProcessor object.
//
Procedure Posting(Cancel, PostingMode)
	
	// Initialization of additional properties for document posting
	SmallBusinessServer.InitializeAdditionalPropertiesForPosting(Ref, AdditionalProperties);
	
	// Initialization of document data
	Documents.InventoryAssembly.InitializeDocumentData(Ref, AdditionalProperties);
	
	// Preparation of record sets
	SmallBusinessServer.PrepareRecordSetsForRecording(ThisObject);
	
	// Registering in accounting sections
	SmallBusinessServer.ReflectInventory(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectInventoryInWarehouses(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectInventoryForWarehouses(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectInventoryForExpenseFromWarehouses(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectProductRelease(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectInventoryAccepted(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectInventoryDemand(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectProductionOrders(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectOrdersPlacement(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectManagerial(AdditionalProperties, RegisterRecords, Cancel);
	
	// SerialNumbers
	SmallBusinessServer.ReflectTheSerialNumbersOfTheGuarantee(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectTheSerialNumbersBalance(AdditionalProperties, RegisterRecords, Cancel);
	
	// Production stages
	If OperationKind = Enums.OperationKindsInventoryAssembly.Assembly Then
		SmallBusinessServer.ReflectProductionStages(AdditionalProperties, RegisterRecords, Cancel);
	EndIf;
	
	// Inventory by CCD
	SmallBusinessServer.ReflectInventoryByCCD(AdditionalProperties, RegisterRecords, Cancel);
	
	// Writing of record sets
	SmallBusinessServer.WriteRecordSets(ThisObject);
	
	// Control
	Documents.InventoryAssembly.RunControl(Ref, AdditionalProperties, Cancel);
	
	AdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager.Close();
	
EndProcedure // Posting()

// Procedure - event handler UndoPosting object.
//
Procedure UndoPosting(Cancel)
	
	// Initialization of additional properties for document posting
	SmallBusinessServer.InitializeAdditionalPropertiesForPosting(Ref, AdditionalProperties);
	
	// Preparation of record sets
	SmallBusinessServer.PrepareRecordSetsForRecording(ThisObject);
	
	// Writing of record sets
	SmallBusinessServer.WriteRecordSets(ThisObject);
	
	// Control
	Documents.InventoryAssembly.RunControl(Ref, AdditionalProperties, Cancel, True);
	
EndProcedure // UndoPosting()

Procedure FillStructuralUnitsTypes() Export
		
	StructuralUnitType = CommonUse.ObjectAttributeValue(StructuralUnit, "StructuralUnitType");
	ProductsStructuralUnitType = CommonUse.ObjectAttributeValue(ProductsStructuralUnit, "StructuralUnitType");
	DisposalsStructuralUnitType = CommonUse.ObjectAttributeValue(DisposalsStructuralUnit, "StructuralUnitType");
	InventoryStructuralUnitType = CommonUse.ObjectAttributeValue(InventoryStructuralUnit, "StructuralUnitType");
	
EndProcedure

Function HeaderStructuralUnit(TabularSection, Val CurStructuralUnit)
	
	If TabularSection.Count()=0 Then
		Return CurStructuralUnit;
	EndIf; 
	
	CurStructuralUnit = TabularSection[0].StructuralUnit;
	
	If TabularSection.Count()=1 Then
		Return CurStructuralUnit;
	EndIf; 
	
	TableStructuralUnit = TabularSection.Unload(, "StructuralUnit");
	TableStructuralUnit.Columns.Add("Quantity", New TypeDescription("Number"));
	For Each CurRow In TableStructuralUnit Do
		CurRow.Quantity = 1;
	EndDo;
	TableStructuralUnit.GroupBy("StructuralUnit", "Quantity");
	
	If TableStructuralUnit.Count() < 2 Then
		Return CurStructuralUnit;
	EndIf;
	
	TableStructuralUnit.Sort("Quantity Desc");
	
	If TableStructuralUnit[0].Quantity = TableStructuralUnit[1].Quantity Then
		Return CurStructuralUnit;
	EndIf;
	
	CurStructuralUnit = TableStructuralUnit[0].StructuralUnit;
	
	Return CurStructuralUnit;
	
EndFunction

Function HeaderCell(TabularSection, Val CurStructuralUnit, Val CurCell)
	
	If TabularSection.Count()=0 Then
		Return CurCell;
	EndIf; 
	
	CurCell = TabularSection[0].Cell;
	
	If TabularSection.Count()=1 Then
		Return CurCell;
	EndIf; 
	
	TableCell = TabularSection.Unload(New Structure ("StructuralUnit", CurStructuralUnit), "Cell");
	TableCell.Columns.Add("Quantity", New TypeDescription("Number"));
	For Each CurRow In TableCell Do
		CurRow.Quantity = 1;
	EndDo;
	TableCell.GroupBy("Cell", "Quantity");
	
	If TableCell.Count() < 2 Then
		Return CurCell;
	EndIf;
	
	TableCell.Sort("Quantity Desc");
	
	If TableCell[0].Quantity = TableCell[1].Quantity Then
		Return CurCell;
	EndIf;
	
	CurCell = TableCell[0].Cell;
	
	Return CurCell;
	
EndFunction

Function HeaderCustomerOrder(TabularSection)
	
	CurCustomerOrder = CustomerOrder;
	
	If TabularSection.Count()=0 Then
		Return CurCustomerOrder;
	EndIf; 
	
	CurCustomerOrder = TabularSection[0].CustomerOrder;
	
	If TabularSection.Count()=1 Then
		Return CurCustomerOrder;
	EndIf; 
	
	TableOrders = TabularSection.Unload(, "CustomerOrder");
	TableOrders.Columns.Add("Quantity", New TypeDescription("Number"));
	For Each CurRow In TableOrders Do
		CurRow.Quantity = 1;
	EndDo;
	TableOrders.GroupBy("CustomerOrder", "Quantity");
	
	If TableOrders.Count() < 2 Then
		Return CurCustomerOrder;
	EndIf;
	
	TableOrders.Sort("Quantity Desc");
	
	If TableOrders[0].Quantity = TableOrders[1].Quantity Then
		Return CurCustomerOrder;
	EndIf;
	
	CurCustomerOrder = TableOrders[0].CustomerOrder;
	
	Return CurCustomerOrder;
	
EndFunction

Procedure AddTempTables(Query)
	
	Query.SetParameter("Products", Products.Unload());
	Query.SetParameter("CompletedStages", CompletedStages.Unload());
	Query.SetParameter("ProductionOrder", ProductionOrder);
	Query.SetParameter("CustomerOrder", CustomerOrder);
	Query.SetParameter("CustomerOrderPosition", CustomerOrderPosition);
	Query.SetParameter("OperationKind", OperationKind);
	
	Query.Text = 
	"SELECT
	|	Products.LineNumber AS LineNumber,
	|	Products.ProductsAndServices AS ProductsAndServices,
	|	Products.Characteristic AS Characteristic,
	|	Products.Batch AS Batch,
	|	CAST(Products.Specification AS Catalog.Specifications) AS Specification,
	|	CASE
	|		WHEN &CustomerOrderPosition = VALUE(Enum.AttributePositionOnForm.InTabularSection)
	|			THEN Products.CustomerOrder
	|		ELSE &CustomerOrder
	|	END AS CustomerOrder,
	|	Products.ConnectionKey AS ConnectionKey
	|INTO Products
	|FROM
	|	&Products AS Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CompletedStages.ConnectionKey AS ConnectionKey,
	|	CompletedStages.Stage AS Stage
	|INTO CompletedStages
	|FROM
	|	&CompletedStages AS CompletedStages
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Products.LineNumber AS LineNumber,
	|	Products.ProductsAndServices AS ProductsAndServices,
	|	Products.Characteristic AS Characteristic,
	|	Products.Batch AS Batch,
	|	Products.Specification AS Specification,
	|	Products.ConnectionKey AS ConnectionKey,
	|	Products.CustomerOrder AS CustomerOrder,
	|	CASE
	|		WHEN Specifications.ProductionKind <> VALUE(Catalog.ProductionKinds.EmptyRef)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS UseProductionStages,
	|	ISNULL(CompletedStages.Stage, VALUE(Catalog.ProductionStages.EmptyRef)) AS Stage
	|INTO ProductsAndStages
	|FROM
	|	Products AS Products
	|		LEFT JOIN Catalog.Specifications AS Specifications
	|		ON Products.Specification = Specifications.Ref
	|		LEFT JOIN CompletedStages AS CompletedStages
	|		ON Products.ConnectionKey = CompletedStages.ConnectionKey";
	Query.Execute();
	
EndProcedure

Procedure AddDistributionBySpecification(Query)
	
	ContentTable = ProductionServer.SpecificationContent(Products.Unload(), True, , , False);
	
	Query.SetParameter("ContentTable", ContentTable);
	Query.Text =
	"SELECT
	|	ContentTable.ConnectionKey AS ConnectionKey,
	|	ContentTable.LineNumber AS LineNumberProduct,
	|	ContentTable.ProductsAndServices AS ProductsAndServicesProduct,
	|	ContentTable.Characteristic AS CharacteristicProduct,
	|	ContentTable.Specification AS SpecificationProduct,
	|	ContentTable.Quantity AS QuantityProduct,
	|	ContentTable.CustomerOrder AS CustomerOrder,
	|	ContentTable.Stage AS Stage,
	|	ContentTable.LineNumberContent AS LineNumber,
	|	ContentTable.ProductsAndServicesContent AS ProductsAndServices,
	|	ContentTable.CharacteristicContent AS Characteristic,
	|	ContentTable.SpecificationCont AS Specification,
	|	ContentTable.QuantityContent AS Quantity,
	|	ContentTable.CostPercentage AS CostPercentage,
	|	ContentTable.MeasurementUnitContent AS MeasurementUnit
	|INTO ContentTable
	|FROM
	|	&ContentTable AS ContentTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ContentTable.ConnectionKey AS ConnectionKeyProduct,
	|	ContentTable.CustomerOrder AS CustomerOrder,
	|	ContentTable.Stage AS Stage,
	|	ContentTable.LineNumber AS LineNumber,
	|	ContentTable.ProductsAndServices AS ProductsAndServices,
	|	ContentTable.Characteristic AS Characteristic,
	|	ContentTable.Specification AS Specification,
	|	VALUE(Catalog.ProductsAndServicesBatches.EmptyRef) AS Batch,
	|	VALUE(Catalog.StructuralUnits.EmptyRef) AS StructuralUnit,
	|	ContentTable.Quantity AS Quantity,
	|	ContentTable.CostPercentage AS CostPercentage,
	|	ContentTable.MeasurementUnit AS MeasurementUnit
	|INTO InventoryDistribution
	|FROM
	|	ContentTable AS ContentTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP ContentTable";
	Query.Execute();
	
EndProcedure

Procedure FillInventoryByStages(Query)
	
	Query.Text =
	"SELECT
	|	InventoryDistribution.CustomerOrder AS CustomerOrder,
	|	CASE
	|		WHEN NOT ProductsAndStages.UseProductionStages
	|				OR &OperationKind = VALUE(Enum.OperationKindsInventoryAssembly.Disassembly)
	|				OR &ProductionOrder = VALUE(Document.ProductionOrder.EmptyRef)
	|					AND CASE
	|						WHEN &CustomerOrderPosition = VALUE(Enum.AttributePositionOnForm.InTabularSection)
	|							THEN ProductsAndStages.CustomerOrder
	|						ELSE &CustomerOrder
	|					END = VALUE(Document.CustomerOrder.EmptyRef)
	|			THEN VALUE(Catalog.ProductionStages.EmptyRef)
	|		ELSE InventoryDistribution.Stage
	|	END AS Stage,
	|	InventoryDistribution.ProductsAndServices AS ProductsAndServices,
	|	InventoryDistribution.Characteristic AS Characteristic,
	|	InventoryDistribution.Specification AS Specification,
	|	InventoryDistribution.Batch AS Batch,
	|	InventoryDistribution.StructuralUnit AS StructuralUnit,
	|	SUM(InventoryDistribution.Quantity) AS Quantity,
	|	SUM(InventoryDistribution.CostPercentage) AS CostPercentage,
	|	InventoryDistribution.MeasurementUnit AS MeasurementUnit,
	|	CAST(InventoryDistribution.ProductsAndServices AS Catalog.ProductsAndServices).CountryOfOrigin AS CountryOfOrigin
	|FROM
	|	ProductsAndStages AS ProductsAndStages
	|		LEFT JOIN InventoryDistribution AS InventoryDistribution
	|		ON ProductsAndStages.ConnectionKey = InventoryDistribution.ConnectionKeyProduct
	|			AND (ProductsAndStages.Stage = InventoryDistribution.Stage
	|				OR NOT ProductsAndStages.UseProductionStages
	|				OR &OperationKind = VALUE(Enum.OperationKindsInventoryAssembly.Disassembly)
	|				OR &ProductionOrder = VALUE(Document.ProductionOrder.EmptyRef)
	|					AND CASE
	|						WHEN &CustomerOrderPosition = VALUE(Enum.AttributePositionOnForm.InTabularSection)
	|							THEN ProductsAndStages.CustomerOrder
	|						ELSE &CustomerOrder
	|					END = VALUE(Document.CustomerOrder.EmptyRef))
	|WHERE
	|	NOT InventoryDistribution.ProductsAndServices IS NULL
	|
	|GROUP BY
	|	InventoryDistribution.CustomerOrder,
	|	CASE
	|		WHEN NOT ProductsAndStages.UseProductionStages
	|				OR &OperationKind = VALUE(Enum.OperationKindsInventoryAssembly.Disassembly)
	|				OR &ProductionOrder = VALUE(Document.ProductionOrder.EmptyRef)
	|					AND CASE
	|						WHEN &CustomerOrderPosition = VALUE(Enum.AttributePositionOnForm.InTabularSection)
	|							THEN ProductsAndStages.CustomerOrder
	|						ELSE &CustomerOrder
	|					END = VALUE(Document.CustomerOrder.EmptyRef)
	|			THEN VALUE(Catalog.ProductionStages.EmptyRef)
	|		ELSE InventoryDistribution.Stage
	|	END,
	|	InventoryDistribution.ProductsAndServices,
	|	InventoryDistribution.Characteristic,
	|	InventoryDistribution.Specification,
	|	InventoryDistribution.Batch,
	|	InventoryDistribution.StructuralUnit,
	|	InventoryDistribution.MeasurementUnit,
	|	CAST(InventoryDistribution.ProductsAndServices AS Catalog.ProductsAndServices).CountryOfOrigin
	|
	|ORDER BY
	|	MIN(ProductsAndStages.LineNumber),
	|	MIN(InventoryDistribution.LineNumber)";
	Inventory.Load(Query.Execute().Unload());
	For Each InventoryRow In Inventory Do
		If Not ValueIsFilled(InventoryRow.StructuralUnit) Then
			InventoryRow.StructuralUnit = ProductsStructuralUnit;
			InventoryRow.Cell = ProductsCell;
		EndIf; 
	EndDo; 
	
EndProcedure

#EndIf