#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

////////////////////////////////////////////////////////////////////////////////
// PROCEDURES OF FILLING THE DOCUMENT

// Procedure fills tabular section according to specification.
//
Procedure FillTabularSectionBySpecification(NodesSpecificationStack, NodesTable = Undefined) Export
	
	TempTablesManager = New TempTablesManager;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	TableProduction.LineNumber AS LineNumber,
	|	TableProduction.Quantity AS Quantity,
	|	TableProduction.Factor AS Factor,
	|	TableProduction.Stage КАК Stage,
	|	TableProduction.CustomerOrder КАК CustomerOrder,
	|	TableProduction.Specification AS Specification
	|INTO TemporaryTableProduction
	|FROM
	|	&TableProduction AS TableProduction
	|WHERE
	|	TableProduction.Specification <> VALUE(Catalog.Specifications.EmptyRef)";
	
	If NodesTable = Undefined Then
		Inventory.Clear();
		TableProduction = Products.Unload();
		Array = New Array();
		Array.Add(Type("Number"));
		TypeDescriptionC = New TypeDescription(Array, , ,New NumberQualifiers(10,3));
		TableProduction.Columns.Add("Factor", TypeDescriptionC);
		TableProduction.Columns.Add("Stage", New TypeDescription("CatalogRef.ProductionStages"));
		For Each StringProducts IN TableProduction Do
			If ValueIsFilled(StringProducts.MeasurementUnit)
				AND TypeOf(StringProducts.MeasurementUnit) = Type("CatalogRef.UOM") Then
				StringProducts.Factor = StringProducts.MeasurementUnit.Factor;
			Else
				StringProducts.Factor = 1;
			EndIf;
		EndDo;
		NodesTable = TableProduction.CopyColumns("LineNumber,Quantity,Factor,Specification,CustomerOrder,Stage");
		Query.SetParameter("TableProduction", TableProduction);
	Else
		Query.SetParameter("TableProduction", NodesTable);
	EndIf;
	
	Query.Execute();
	
	Query.SetParameter("OperationKind", OperationKind);
	Query.Text =
	"SELECT
	|	MIN(TableProduction.LineNumber) AS ProductionLineNumber,
	|	TableProduction.Specification AS ProductionSpecification,
	|	MIN(TableMaterials.LineNumber) AS StructureLineNumber,
	|	TableMaterials.ContentRowType AS ContentRowType,
	|	TableMaterials.ProductsAndServices AS ProductsAndServices,
	|	CASE
	|		WHEN NOT FunctionalOptionUseProductionStages.Value
	|				OR &OperationKind = VALUE(Enum.OperationKindsProductionOrder.Disassembly)
	|			THEN VALUE(Catalog.ProductionStages.ПустаяСсылка)
	|		WHEN TableProduction.Stage <> VALUE(Catalog.ProductionStages.ПустаяСсылка)
	|			THEN TableProduction.Stage
	|		ELSE TableMaterials.Stage
	|	END AS Stage,
	|	CASE
	|		WHEN UseCharacteristics.Value
	|			THEN TableMaterials.Characteristic
	|		ELSE VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	|	END AS Characteristic,
	|	SUM(TableMaterials.Quantity / TableMaterials.ProductsQuantity * TableProduction.Factor * TableProduction.Quantity) AS Quantity,
	|	TableMaterials.MeasurementUnit AS MeasurementUnit,
	|	CASE
	|		WHEN TableMaterials.ContentRowType = VALUE(Enum.SpecificationContentRowTypes.Node)
	|				AND VALUETYPE(TableMaterials.MeasurementUnit) = TYPE(Catalog.UOM)
	|				AND TableMaterials.MeasurementUnit <> VALUE(Catalog.UOM.EmptyRef)
	|			THEN TableMaterials.MeasurementUnit.Factor
	|		ELSE 1
	|	END AS Factor,
	|	TableMaterials.Specification AS Specification,
	|	TableProduction.CustomerOrder AS CustomerOrder
	|FROM
	|	TemporaryTableProduction AS TableProduction
	|		LEFT JOIN Catalog.Specifications.Content AS TableMaterials
	|		ON TableProduction.Specification = TableMaterials.Ref,
	|	Constant.FunctionalOptionUseCharacteristics AS UseCharacteristics,
	|	Constant.FunctionalOptionUseProductionStages AS FunctionalOptionUseProductionStages
	|WHERE
	|	TableMaterials.ProductsAndServices.ProductsAndServicesType = VALUE(Enum.ProductsAndServicesTypes.InventoryItem)
	|
	|GROUP BY
	|	TableProduction.Specification,
	|	TableMaterials.ContentRowType,
	|	TableMaterials.ProductsAndServices,
	|	TableMaterials.MeasurementUnit,
	|	CASE
	|		WHEN TableMaterials.ContentRowType = VALUE(Enum.SpecificationContentRowTypes.Node)
	|				AND VALUETYPE(TableMaterials.MeasurementUnit) = TYPE(Catalog.UOM)
	|				AND TableMaterials.MeasurementUnit <> VALUE(Catalog.UOM.EmptyRef)
	|			THEN TableMaterials.MeasurementUnit.Factor
	|		ELSE 1
	|	END,
	|	CASE
	|		WHEN NOT FunctionalOptionUseProductionStages.Value
	|				OR &OperationKind = VALUE(Enum.OperationKindsProductionOrder.Disassembly)
	|			THEN VALUE(Catalog.ProductionStages.ПустаяСсылка)
	|		WHEN TableProduction.Stage <> VALUE(Catalog.ProductionStages.ПустаяСсылка)
	|			THEN TableProduction.Stage
	|		ELSE TableMaterials.Stage
	|	END,
	|	TableMaterials.Specification,
	|	TableProduction.CustomerOrder,
	|	CASE
	|		WHEN UseCharacteristics.Value
	|			THEN TableMaterials.Characteristic
	|		ELSE VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	|	END
	|
	|ORDER BY
	|	ProductionLineNumber,
	|	StructureLineNumber";
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		If Selection.ContentRowType = Enums.SpecificationContentRowTypes.Node Then
			NodesTable.Clear();
			If Not NodesSpecificationStack.Find(Selection.Specification) = Undefined Then
				MessageText = NStr("ru = 'При попытке заполнить табличную""""часть Материалы по спецификации, обнаружено рекурсивное вхождение элемента';
|vi = 'Khi thử điền phần bảng""""Nguyên vật liệu theo bảng kê chi tiết, đã tìm thấy sự xuất hiện đệ quy của phần tử';
|en = 'During filling in of the Specification materials""""tabular section a recursive item occurrence was found'")+" "+Selection.ProductsAndServices+" "+NStr("ru = 'в спецификации';
																																	|vi = 'trong bảng kê chi tiết';
																																	|en = 'in BOM'")+" "+Selection.ProductionSpecification+NStr("en='"
"The operation failed.';vi='"
"Giao dịch bị hủy.'");
				Raise MessageText;
			EndIf;
			NodesSpecificationStack.Add(Selection.Specification);
			NewRow = NodesTable.Add();
			FillPropertyValues(NewRow, Selection);
			FillTabularSectionBySpecification(NodesSpecificationStack, NodesTable);
		Else
			NewRow = Inventory.Add();
			FillPropertyValues(NewRow, Selection);
		EndIf;
	EndDo;
	
	NodesSpecificationStack.Clear();
	Inventory.GroupBy("Stage, ProductsAndServices, Characteristic, MeasurementUnit, Specification, CustomerOrder", "Quantity, Reserve");
	
	For Each TabSecRow In Inventory Do
		
		If ValueIsFilled(TabSecRow.StructuralUnit)  Then
			Continue;
		EndIf;
		
		TabSecRow.StructuralUnit = StructuralUnitReserve;
		
	EndDo; ; 
	
EndProcedure // FillTabularSectionBySpecification()

// Procedure fills the Quantity column by free balances at warehouse.
//
Procedure FillColumnReserveByBalances() Export
	
	Inventory.LoadColumn(New Array(Inventory.Count()), "Reserve");
	
	TempTablesManager = New TempTablesManager;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	TableInventory.ProductsAndServices AS ProductsAndServices,
	|	TableInventory.Characteristic AS Characteristic,
	|	VALUE(Catalog.ProductsAndServicesBatches.EmptyRef) AS Batch
	|INTO TemporaryTableInventory
	|FROM
	|	&TableInventory AS TableInventory";
	
	Query.SetParameter("TableInventory", Inventory.Unload());
	Query.Execute();
	
	Query.Text =
	"SELECT
	|	InventoryBalances.Company AS Company,
	|	InventoryBalances.StructuralUnit AS StructuralUnit,
	|	InventoryBalances.GLAccount AS GLAccount,
	|	InventoryBalances.ProductsAndServices AS ProductsAndServices,
	|	InventoryBalances.Characteristic AS Characteristic,
	|	InventoryBalances.Batch AS Batch,
	|	SUM(InventoryBalances.QuantityBalance) AS QuantityBalance
	|FROM
	|	(SELECT
	|		InventoryBalances.Company AS Company,
	|		InventoryBalances.StructuralUnit AS StructuralUnit,
	|		InventoryBalances.GLAccount AS GLAccount,
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
	|						VALUE(Document.CustomerOrder.EmptyRef) AS CustomerOrder
	|					FROM
	|						TemporaryTableInventory AS TableInventory)) AS InventoryBalances
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentRegisterRecordsInventory.Company,
	|		DocumentRegisterRecordsInventory.StructuralUnit,
	|		DocumentRegisterRecordsInventory.GLAccount,
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
	|		AND DocumentRegisterRecordsInventory.RecordType = VALUE(AccumulationRecordType.Expense)) AS InventoryBalances
	|
	|GROUP BY
	|	InventoryBalances.Company,
	|	InventoryBalances.StructuralUnit,
	|	InventoryBalances.GLAccount,
	|	InventoryBalances.ProductsAndServices,
	|	InventoryBalances.Characteristic,
	|	InventoryBalances.Batch";
	
	Query.SetParameter("Period", Date);
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Company", SmallBusinessServer.GetCompany(Company));
	Query.SetParameter("StructuralUnit", StructuralUnitReserve);
	Query.SetParameter("StructuralUnitType", StructuralUnitReserve.StructuralUnitType);
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	While Selection.Next() Do
		
		StructureForSearch = New Structure;
		StructureForSearch.Insert("ProductsAndServices", Selection.ProductsAndServices);
		StructureForSearch.Insert("Characteristic", Selection.Characteristic);
		
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
	
EndProcedure // FillColumnReserveByBalances()

// Procedure for filling the document basing on Production order.
//
Procedure FillByProductionOrder(FillingData) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ProductionOrder.Start AS Start,
	|	ProductionOrder.Start AS Finish,
	|	ProductionOrder.OperationKind AS OperationKind,
	|	ProductionOrder.Ref AS BasisDocument,
	|	CASE
	|		WHEN FunctionalOptionInventoryReservation.Value
	|			THEN ProductionOrder.CustomerOrder
	|		ELSE VALUE(Document.CustomerOrder.EmptyRef)
	|	END AS CustomerOrder,
	|	ProductionOrder.Company AS Company,
	|	ProductionOrder.StructuralUnit AS StructuralUnit,
	|	CASE
	|		WHEN ProductionOrder.StructuralUnitReserve = VALUE(Catalog.StructuralUnits.EmptyRef)
	|				AND (ProductionOrder.StructuralUnit.TransferSource.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Warehouse)
	|					OR ProductionOrder.StructuralUnit.TransferSource.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Department))
	|			THEN ProductionOrder.StructuralUnit.TransferSource
	|		ELSE ProductionOrder.StructuralUnitReserve
	|	END AS StructuralUnitReserve,
	|	ProductionOrder.Inventory.(
	|		ProductsAndServices AS ProductsAndServices,
	|		Characteristic AS Characteristic,
	|		MeasurementUnit AS MeasurementUnit,
	|		Quantity AS Quantity,
	|		Specification AS Specification,
	|		ProductsAndServices.ProductsAndServicesType AS ProductsAndServicesType,
	|		ProductsAndServices.ReplenishmentMethod AS ReplenishmentMethod
	|	)
	|FROM
	|	Document.ProductionOrder AS ProductionOrder,
	|	Constant.FunctionalOptionInventoryReservation AS FunctionalOptionInventoryReservation
	|WHERE
	|	ProductionOrder.Ref = &BasisDocument";
	
	Query.SetParameter("BasisDocument", FillingData);
	
	Products.Clear();
	Inventory.Clear();
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		
		QueryResultSelection = QueryResult.Select();
		QueryResultSelection.Next();
		FillPropertyValues(ThisObject, QueryResultSelection);
		
		For Each StringInventory In QueryResultSelection.Inventory.Unload() Do
			If Not ValueIsFilled(StringInventory.ProductsAndServices) Then
				Continue;
			EndIf;
			If StringInventory.Quantity <=0 Then
				Continue;
			EndIf;
			If Not ValueIsFilled(StringInventory.Specification) 
				And StringInventory.ReplenishmentMethod = Enums.InventoryReplenishmentMethods.Purchase Then
				Continue;
			EndIf; 
			NewRow = Products.Add();
			FillPropertyValues(NewRow, StringInventory);
		EndDo;
		
		If Products.Count() > 0 Then
			NodesSpecificationStack = New Array;
			FillTabularSectionBySpecification(NodesSpecificationStack);
		EndIf;
		
	EndIf;
	
EndProcedure // FillByProductionOrder()

// Procedure for filling the document basing on Customer order.
//
Procedure FillUsingCustomerOrder(FillingData) Export
	
	If OperationKind = Enums.OperationKindsProductionOrder.Disassembly Then
		TabularSectionName = "Inventory";
	Else
		TabularSectionName = "Products";
	EndIf;
	
	// Header filling.
	Query = New Query;
	Query.Text =
	"SELECT
	|	CustomerOrder.Ref AS BasisRef,
	|	CustomerOrder.Posted AS BasisPosted,
	|	CustomerOrder.Closed AS BasisClosed,
	|	CustomerOrder.OrderState AS BasisState,
	|	CustomerOrder.OperationKind AS BasisOperationKind,
	|	CASE
	|		WHEN FunctionalOptionInventoryReservation.Value
	|			THEN CustomerOrder.Ref
	|		ELSE VALUE(Document.CustomerOrder.EmptyRef)
	|	END AS CustomerOrder,
	|	CustomerOrder.Company AS Company,
	|	CASE
	|		WHEN CustomerOrder.SalesStructuralUnit.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Department)
	|			THEN CustomerOrder.SalesStructuralUnit
	|		ELSE VALUE(Catalog.StructuralUnits.EmptyRef)
	|	END AS StructuralUnit,
	|	CASE
	|		WHEN CustomerOrder.SalesStructuralUnit.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Department)
	|				AND CustomerOrder.StructuralUnitReserve = VALUE(Catalog.StructuralUnits.EmptyRef)
	|				AND (CustomerOrder.SalesStructuralUnit.TransferSource.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Warehouse)
	|					OR CustomerOrder.SalesStructuralUnit.TransferSource.StructuralUnitType = VALUE(Enum.StructuralUnitsTypes.Department))
	|			THEN CustomerOrder.SalesStructuralUnit.TransferSource
	|		ELSE CustomerOrder.StructuralUnitReserve
	|	END AS StructuralUnitReserve,
	|	CASE
	|		WHEN CustomerOrder.OperationKind = VALUE(Enum.OperationKindsCustomerOrder.WorkOrder)
	|			THEN CustomerOrder.Start
	|		ELSE BEGINOFPERIOD(CustomerOrder.ShipmentDate, Day)
	|	END AS Start,
	|	CASE
	|		WHEN CustomerOrder.OperationKind = VALUE(Enum.OperationKindsCustomerOrder.WorkOrder)
	|			THEN CustomerOrder.Finish
	|		ELSE ENDOFPERIOD(CustomerOrder.ShipmentDate, Day)
	|	END AS Finish
	|FROM
	|	Document.CustomerOrder AS CustomerOrder,
	|	Constant.FunctionalOptionInventoryReservation AS FunctionalOptionInventoryReservation
	|WHERE
	|	CustomerOrder.Ref = &BasisDocument";
	
	Query.SetParameter("BasisDocument", FillingData);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		VerifiedAttributesValues = New Structure("OperationKind, OrderStatus, Closed, Posted", Selection.BasisOperationKind, Selection.BasisState, Selection.BasisClosed, Selection.BasisPosted);
		Documents.CustomerOrder.CheckAbilityOfEnteringByCustomerOrder(Selection.BasisRef, VerifiedAttributesValues);
	EndIf;
	
	FillPropertyValues(ThisObject, Selection);
	
	If Not ValueIsFilled(StructuralUnit) Then
		SettingValue = SmallBusinessReUse.GetValueOfSetting("MainDepartment");
		If Not ValueIsFilled(SettingValue) Then
			StructuralUnit = Catalogs.StructuralUnits.MainDepartment;
		EndIf;
	EndIf;
	
	BasisOperationKind = Selection.BasisOperationKind;
	
	// Filling out tabular section.
	Query = New Query;
	Query.Text =
	"SELECT
	|	OrdersBalance.ProductsAndServices AS ProductsAndServices,
	|	OrdersBalance.Characteristic AS Characteristic,
	|	SUM(OrdersBalance.QuantityBalance) AS QuantityBalance
	|FROM
	|	(SELECT
	|		OrdersBalance.ProductsAndServices AS ProductsAndServices,
	|		OrdersBalance.Characteristic AS Characteristic,
	|		OrdersBalance.QuantityBalance AS QuantityBalance
	|	FROM
	|		AccumulationRegister.CustomerOrders.Balance(, CustomerOrder = &BasisDocument) AS OrdersBalance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		InventoryBalances.ProductsAndServices,
	|		InventoryBalances.Characteristic,
	|		-InventoryBalances.QuantityBalance
	|	FROM
	|		AccumulationRegister.Inventory.Balance(, CustomerOrder = &BasisDocument) AS InventoryBalances
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		PlacementBalances.ProductsAndServices,
	|		PlacementBalances.Characteristic,
	|		-PlacementBalances.QuantityBalance
	|	FROM
	|		AccumulationRegister.OrdersPlacement.Balance(, CustomerOrder = &BasisDocument) AS PlacementBalances
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentRegisterRecordsOrdersPlacement.ProductsAndServices,
	|		DocumentRegisterRecordsOrdersPlacement.Characteristic,
	|		CASE
	|			WHEN DocumentRegisterRecordsOrdersPlacement.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -ISNULL(DocumentRegisterRecordsOrdersPlacement.Quantity, 0)
	|			ELSE ISNULL(DocumentRegisterRecordsOrdersPlacement.Quantity, 0)
	|		END
	|	FROM
	|		AccumulationRegister.OrdersPlacement AS DocumentRegisterRecordsOrdersPlacement
	|	WHERE
	|		DocumentRegisterRecordsOrdersPlacement.Recorder = &Ref
	|		AND DocumentRegisterRecordsOrdersPlacement.CustomerOrder = &BasisDocument) AS OrdersBalance
	|
	|GROUP BY
	|	OrdersBalance.ProductsAndServices,
	|	OrdersBalance.Characteristic
	|
	|HAVING
	|	SUM(OrdersBalance.QuantityBalance) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(CustomerOrderInventory.LineNumber) AS LineNumber,
	|	CustomerOrderInventory.ProductsAndServices AS ProductsAndServices,
	|	CustomerOrderInventory.Characteristic AS Characteristic,
	|	CASE
	|		WHEN VALUETYPE(CustomerOrderInventory.MeasurementUnit) = TYPE(Catalog.UOMClassifier)
	|			THEN 1
	|		ELSE CustomerOrderInventory.MeasurementUnit.Factor
	|	END AS Factor,
	|	CustomerOrderInventory.MeasurementUnit AS MeasurementUnit,
	|	CustomerOrderInventory.Specification AS Specification,
	|	CustomerOrderInventory.ProductsAndServices.ProductsAndServicesType AS ProductsAndServicesType,
	|	SUM(CustomerOrderInventory.Quantity) AS Quantity
	|FROM
	|	Document.CustomerOrder.Inventory AS CustomerOrderInventory
	|WHERE
	|	CustomerOrderInventory.Ref = &BasisDocument
	|	AND (CustomerOrderInventory.Specification <> VALUE(Catalog.Specifications.EmptyRef)
	|			OR CustomerOrderInventory.ProductsAndServices.ReplenishmentMethod = VALUE(Enum.InventoryReplenishmentMethods.Production)
	|			OR &OperationKind = VALUE(Enum.OperationKindsProductionOrder.Disassembly))
	|
	|GROUP BY
	|	CustomerOrderInventory.ProductsAndServices,
	|	CustomerOrderInventory.Characteristic,
	|	CustomerOrderInventory.MeasurementUnit,
	|	CustomerOrderInventory.ProductsAndServices.ProductsAndServicesType,
	|	CASE
	|		WHEN VALUETYPE(CustomerOrderInventory.MeasurementUnit) = TYPE(Catalog.UOMClassifier)
	|			THEN 1
	|		ELSE CustomerOrderInventory.MeasurementUnit.Factor
	|	END,
	|	CustomerOrderInventory.Specification
	|
	|ORDER BY
	|	LineNumber";
	
	If BasisOperationKind = Enums.OperationKindsCustomerOrder.WorkOrder Then
		
		Query.Text = Query.Text + "; " +
		"SELECT
		|	OrdersBalance.ProductsAndServices AS ProductsAndServices,
		|	OrdersBalance.Characteristic AS Characteristic,
		|	SUM(OrdersBalance.QuantityBalance) AS QuantityBalance
		|FROM
		|	(SELECT
		|		InventoryBalances.ProductsAndServices AS ProductsAndServices,
		|		InventoryBalances.Characteristic AS Characteristic,
		|		InventoryBalances.QuantityBalance AS QuantityBalance
		|	FROM
		|		AccumulationRegister.Inventory.Balance(
		|				,
		|				CustomerOrder = &BasisDocument
		|					AND ProductsAndServices.ProductsAndServicesType = VALUE(Enum.ProductsAndServicesTypes.InventoryItem)) AS InventoryBalances
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		PlacementBalances.ProductsAndServices,
		|		PlacementBalances.Characteristic,
		|		PlacementBalances.QuantityBalance
		|	FROM
		|		AccumulationRegister.OrdersPlacement.Balance(
		|				,
		|				CustomerOrder = &BasisDocument
		|					AND ProductsAndServices.ProductsAndServicesType = VALUE(Enum.ProductsAndServicesTypes.InventoryItem)) AS PlacementBalances
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentRegisterRecordsOrdersPlacement.ProductsAndServices,
		|		DocumentRegisterRecordsOrdersPlacement.Characteristic,
		|		CASE
		|			WHEN DocumentRegisterRecordsOrdersPlacement.RecordType = VALUE(AccumulationRecordType.Expense)
		|				THEN ISNULL(DocumentRegisterRecordsOrdersPlacement.Quantity, 0)
		|			ELSE -ISNULL(DocumentRegisterRecordsOrdersPlacement.Quantity, 0)
		|		END
		|	FROM
		|		AccumulationRegister.OrdersPlacement AS DocumentRegisterRecordsOrdersPlacement
		|	WHERE
		|		DocumentRegisterRecordsOrdersPlacement.Recorder = &Ref
		|		AND DocumentRegisterRecordsOrdersPlacement.CustomerOrder = &BasisDocument) AS OrdersBalance
		|
		|GROUP BY
		|	OrdersBalance.ProductsAndServices,
		|	OrdersBalance.Characteristic
		|
		|HAVING
		|	SUM(OrdersBalance.QuantityBalance) > 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MIN(CustomerOrderMaterials.LineNumber) AS LineNumber,
		|	CustomerOrderMaterials.ProductsAndServices AS ProductsAndServices,
		|	CustomerOrderMaterials.Characteristic AS Characteristic,
		|	CustomerOrderMaterials.Batch AS Batch,
		|	CASE
		|		WHEN VALUETYPE(CustomerOrderMaterials.MeasurementUnit) = TYPE(Catalog.UOMClassifier)
		|			THEN 1
		|		ELSE CustomerOrderMaterials.MeasurementUnit.Factor
		|	END AS Factor,
		|	CustomerOrderMaterials.MeasurementUnit AS MeasurementUnit,
		|	CustomerOrderMaterials.ProductsAndServices.ProductsAndServicesType AS ProductsAndServicesType,
		|	SUM(CustomerOrderMaterials.Quantity) AS Quantity
		|FROM
		|	Document.CustomerOrder.Materials AS CustomerOrderMaterials
		|WHERE
		|	CustomerOrderMaterials.Ref = &BasisDocument
		|	AND (CustomerOrderMaterials.ProductsAndServices.ReplenishmentMethod = VALUE(Enum.InventoryReplenishmentMethods.Production)
		|			OR &OperationKind = VALUE(Enum.OperationKindsProductionOrder.Disassembly))
		|
		|GROUP BY
		|	CustomerOrderMaterials.ProductsAndServices,
		|	CustomerOrderMaterials.Characteristic,
		|	CustomerOrderMaterials.Batch,
		|	CustomerOrderMaterials.MeasurementUnit,
		|	CustomerOrderMaterials.ProductsAndServices.ProductsAndServicesType,
		|	CASE
		|		WHEN VALUETYPE(CustomerOrderMaterials.MeasurementUnit) = TYPE(Catalog.UOMClassifier)
		|			THEN 1
		|		ELSE CustomerOrderMaterials.MeasurementUnit.Factor
		|	END
		|
		|ORDER BY
		|	LineNumber";
		
	EndIf;
	
	Query.SetParameter("BasisDocument", FillingData);
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("OperationKind", OperationKind);
	
	ResultsArray = Query.ExecuteBatch();
	BalanceTable = ResultsArray[0].Unload();
	BalanceTable.Indexes.Add("ProductsAndServices,Characteristic");
	
	Products.Clear();
	Inventory.Clear();
	If BalanceTable.Count() > 0 Then
		
		Selection = ResultsArray[1].Select();
		While Selection.Next() Do
			
			If TabularSectionName = "Inventory"
				AND Selection.ProductsAndServicesType <> Enums.ProductsAndServicesTypes.InventoryItem Then
				Continue;
			EndIf;
			
			StructureForSearch = New Structure;
			StructureForSearch.Insert("ProductsAndServices", Selection.ProductsAndServices);
			StructureForSearch.Insert("Characteristic", Selection.Characteristic);
			
			BalanceRowsArray = BalanceTable.FindRows(StructureForSearch);
			If BalanceRowsArray.Count() = 0 Then
				Continue;
			EndIf;
			
			NewRow = ThisObject[TabularSectionName].Add();
			FillPropertyValues(NewRow, Selection);
			
			If Not ValueIsFilled(NewRow.Specification) Then
				NewRow.Specification = SmallBusinessServer.GetDefaultSpecification(NewRow.ProductsAndServices, NewRow.Characteristic);
			EndIf;
			
			QuantityToWriteOff = Selection.Quantity * Selection.Factor;
			BalanceRowsArray[0].QuantityBalance = BalanceRowsArray[0].QuantityBalance - QuantityToWriteOff;
			If BalanceRowsArray[0].QuantityBalance < 0 Then
				
				NewRow.Quantity = (QuantityToWriteOff + BalanceRowsArray[0].QuantityBalance) / Selection.Factor;
				
			EndIf;
			
			If BalanceRowsArray[0].QuantityBalance <= 0 Then
				BalanceTable.Delete(BalanceRowsArray[0]);
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If BasisOperationKind = Enums.OperationKindsCustomerOrder.WorkOrder Then
		
		ResultsArray = Query.ExecuteBatch();
		BalanceTable = ResultsArray[2].Unload();
		BalanceTable.Indexes.Add("ProductsAndServices,Characteristic");
		
		Selection = ResultsArray[3].Select();
		While Selection.Next() Do
			
			If TabularSectionName = "Inventory"
				AND Selection.ProductsAndServicesType <> Enums.ProductsAndServicesTypes.InventoryItem Then
				Continue;
			EndIf;
			
			StructureForSearch = New Structure;
			StructureForSearch.Insert("ProductsAndServices", Selection.ProductsAndServices);
			StructureForSearch.Insert("Characteristic", Selection.Characteristic);
			
			BalanceRowsArray = BalanceTable.FindRows(StructureForSearch);
			If BalanceRowsArray.Count() = 0 Then
				
				NewRow = ThisObject[TabularSectionName].Add();
				FillPropertyValues(NewRow, Selection);
				
				NewRow.Specification = SmallBusinessServer.GetDefaultSpecification(NewRow.ProductsAndServices, NewRow.Characteristic);
				
			ElsIf (BalanceRowsArray[0].QuantityBalance / Selection.Factor) = Selection.Quantity Then
				
				Continue;
				
			ElsIf (BalanceRowsArray[0].QuantityBalance / Selection.Factor) > Selection.Quantity Then
				
				BalanceRowsArray[0].QuantityBalance = BalanceRowsArray[0].QuantityBalance - Selection.Quantity * Selection.Factor;
				Continue;
				
			ElsIf (BalanceRowsArray[0].QuantityBalance / Selection.Factor) < Selection.Quantity Then
				
				QuantityToWriteOff = -1 * (BalanceRowsArray[0].QuantityBalance / Selection.Factor - Selection.Quantity);
				BalanceRowsArray[0].QuantityBalance = 0;
				
				NewRow = ThisObject[TabularSectionName].Add();
				FillPropertyValues(NewRow, Selection);
				
				NewRow.Quantity = (QuantityToWriteOff + BalanceRowsArray[0].QuantityBalance) / Selection.Factor;
				
				NewRow.Specification = SmallBusinessServer.GetDefaultSpecification(NewRow.ProductsAndServices, NewRow.Characteristic);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If Products.Count() > 0 Then
		NodesSpecificationStack = New Array;
		FillTabularSectionBySpecification(NodesSpecificationStack);
	EndIf;
	
EndProcedure // FillByCustomerOrder()

// Procedure fills document when copying.
//
Procedure FillOnCopy()
	
	If Constants.UseProductionOrderStates.Get() Then
		User = Users.CurrentUser();
		SettingValue = SmallBusinessReUse.GetValueByDefaultUser(User, "StatusOfNewProductionOrder");
		If ValueIsFilled(SettingValue) Then
			If OrderState <> SettingValue Then
				OrderState = SettingValue;
			EndIf;
		Else
			OrderState = Catalogs.ProductionOrderStates.Open;
		EndIf;
	Else
		OrderState = Constants.ProductionOrdersInProgressStatus.Get();
	EndIf;
	
	Closed = False;
	
EndProcedure // FillOnCopy()

////////////////////////////////////////////////////////////////////////////////
// EVENT HANDLERS

// Procedure - event handler of the OnCopy object.
//
Procedure OnCopy(CopiedObject)
	
	FillOnCopy();
	
EndProcedure // OnCopy()

// Procedure - event handler FillingProcessor object.
//
Procedure Filling(FillingData, StandardProcessing) Export
	
	If Not ValueIsFilled(FillingData) Then
		Return;
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("DemandPlanning") Then
		NodesSpecificationStack = New Array;
		FillTabularSectionBySpecification(NodesSpecificationStack);
		If GetFunctionalOption("UseTechOperations") And Constants.AutomaticallyPlanOperationsByProductionOrder.Get() Then
			FillOperationsBySpecification();
		EndIf; 
		If ManualDistribution Then
			ProductionServer.DistribInventory(Products, Inventory, InventoryDistribution);
		EndIf; 
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.CustomerOrder") Then
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
	
	ProductionServer.FillConnectionKeys(Inventory);
	ProductionServer.FillConnectionKeys(Products);
	
	ResourcesList = "";
	For Each RowResource IN EnterpriseResources Do
		ResourcesList = ResourcesList + ?(ResourcesList = "","","; " + Chars.LF) + TrimAll(RowResource.EnterpriseResource);
	EndDo;
	
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
	
	FillStructuralUnitsTypes();
	
	If CustomerOrderPosition=Enums.AttributePositionOnForm.InTabularSection Then
		CustomerOrder = HeaderCustomerOrder(?(OperationKind=Enums.OperationKindsProductionOrder.Disassembly, Inventory, Products));
	Else
		For Each TabSecRow In Inventory Do
			TabSecRow.CustomerOrder = CustomerOrder;
		EndDo; 
		For Each TabSecRow In Products Do
			TabSecRow.CustomerOrder = CustomerOrder;
		EndDo; 
		For Each TabSecRow In Operations Do
			TabSecRow.CustomerOrder = CustomerOrder;
		EndDo; 
	EndIf;
	
	If WarehousePosition=Enums.AttributePositionOnForm.InTabularSection Then
		StructuralUnitReserve = HeaderStructuralUnit(?(OperationKind=Enums.OperationKindsProductionOrder.Disassembly, Products, Inventory));
		
	ElsIf OperationKind=Enums.OperationKindsProductionOrder.Disassembly Then
		
		For Each TabSecRow In Inventory Do
			TabSecRow.StructuralUnit = Catalogs.StructuralUnits.EmptyRef();
		EndDo; 
		For Each TabSecRow In Products Do
			If ValueIsFilled(TabSecRow.CustomerOrder) Then
				TabSecRow.StructuralUnit = StructuralUnitReserve;
			Else
				TabSecRow.StructuralUnit = Catalogs.StructuralUnits.EmptyRef();
			EndIf; 
		EndDo; 
		
	ElsIf OperationKind= Enums.OperationKindsProductionOrder.Assembly Then
		
		For Each TabSecRow In Inventory Do
			If ValueIsFilled(TabSecRow.CustomerOrder) Then
				TabSecRow.StructuralUnit = StructuralUnitReserve;
			Else
				TabSecRow.StructuralUnit = Catalogs.StructuralUnits.EmptyRef();
			EndIf; 
		EndDo; 
		For Each TabSecRow In Products Do
			TabSecRow.StructuralUnit = Catalogs.StructuralUnits.EmptyRef();
		EndDo; 
	EndIf;
	
	If OperationKind=Enums.OperationKindsProductionOrder.Disassembly Then
		For Each TabSecRow In InventoryDistribution Do
			TabSecRow.StructuralUnit = Catalogs.StructuralUnits.EmptyRef();
		EndDo; 
	EndIf; 
	
	If StructuralUnitOperationPosition=Enums.AttributePositionOnForm.InTabularSection Then
		StructuralUnitOperation = HeaderOperationStructuralUnit();
	Else
		For Each TabSecRow In Operations Do
			TabSecRow.StructuralUnit = StructuralUnitOperation;
		EndDo; 
		For Each TabSecRow In Brigade Do
			TabSecRow.StructuralUnit = StructuralUnitOperation;
		EndDo; 
	EndIf; 
	
	If PerformerPosition=Enums.AttributePositionOnForm.InTabularSection Then
		Performer = HeaderPerfomer();
	Else
		For Each TabSecRow In Operations Do
			TabSecRow.Performer = Performer;
		EndDo; 
	EndIf;
	
	If Not ManualDistribution
		And WriteMode = DocumentWriteMode.Posting
		And GetFunctionalOption("UseProductionStages") Then
		ProductionServer.DistribInventory(Products, Inventory, InventoryDistribution);
	ElsIf Not ManualDistribution Then 
		InventoryDistribution.Clear();
	EndIf;
	
	OperationPlanned = (Operations.Count() > 0);
	
	// ParametricSpecifications
	If WriteMode=DocumentWriteMode.Posting Then
		ProductionFormulasServer.CalculateParametricSpecifications(ThisObject, "Products", Cancel);
	EndIf; 
	// End ParametricSpecifications
	
EndProcedure // BeforeWrite()

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
		
	ProductionServer.UpdateRelatedSpecifications(Ref, DeletionMark);

EndProcedure

// Procedure - event handler FillCheckProcessing object.
//
Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If (Inventory.Total("Reserve") > 0 OR Products.Total("Reserve") > 0)
		AND Not ValueIsFilled(StructuralUnitReserve) Then
		
		MessageText = NStr("ru = 'Не указан склад резерва!';
							|vi = 'Chưa chỉ ra kho dự phòng!';
							|en = 'Reserve warehouse is not specified.'");
		SmallBusinessServer.ShowMessageAboutError(ThisObject, MessageText,,, "StructuralUnitReserve", Cancel);
		
	EndIf;
	
	If Constants.FunctionalOptionInventoryReservation.Get() Then
		
		If OperationKind = Enums.OperationKindsProductionOrder.Assembly Then
			
			For Each StringInventory IN Inventory Do
				
				If StringInventory.Reserve > StringInventory.Quantity Then
					
					MessageText = NStr("en='In string No.%Number% of tablular section ""Materials"" quantity of reserved positions exceeds the total materials.';ru='В строке №%Номер% табл. части ""Материалы"" количество резервируемых позиций превышает общее количество материалов.';vi='Tại dòng số %Number% của phần bảng ""Nguyên vật liệu"" số lượng dự phòng lớn hơn tổng số lượng nguyên vật liệu.'");
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
					
					MessageText = NStr("en='In string No.%Number% of tabular section ""Goods"" quantity of the reserved positions exceeds the total goods.';ru='В строке №%Номер% табл. части ""Товары"" количество резервируемых позиций превышает общее количество товаров.';vi='Tại dòng số %Number% của phần bảng ""Hàng hóa"", số lượng mặt hàng dự phòng vượt quá tổng số lượng hàng hóa.'");
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
	
	If Inventory.Count() > 0 Then
		
		FilterStructure = New Structure("ProductsAndServicesType", Enums.ProductsAndServicesTypes.Service);
		ArrayOfStringsServices = Products.FindRows(FilterStructure);
		If Products.Count() = ArrayOfStringsServices.Count() Then
			
			MessageText = NStr("ru = 'Планирование потребностей в материалах не выполняется для услуг!""""В табличной части ""Продукция"" указаны только услуги. Необходимо очистить табличную часть ""Материалы"".';
|vi = 'Lập kế hoạch nhu cầu nguyên vật liệu chưa được thực hiện đối với dịch vụ!""""Trong phần bảng ""Sản phẩm"" chỉ chỉ ra dịch vụ. Cần xóa bỏ phần bảng ""Nguyên vật liệu"".';
|en = 'Demand for materials is not planned for services!""""Services only are indicated in the tabular section ""Products"". It is necessary to clear the tabular section ""Materials"".'");
			SmallBusinessServer.ShowMessageAboutError(ThisObject, MessageText,,,, Cancel);
			
		EndIf;
		
	EndIf;
	
	If Not Constants.UseProductionOrderStates.Get() Then
		
		If Not ValueIsFilled(OrderState) Then
			MessageText = NStr("ru = 'Поле ""Состояние заказа"" не заполнено. В настройках параметров учета необходимо установить значения состояний.';
								|vi = 'Chưa điền trường ""Trạng thái đơn hàng"". Trong thiết lập tham số kế toán cần thiết lập giá trị trạng thái.';
								|en = 'The ""Order state"" field is not filled. Specify state values in the accounting parameter settings.'");
			SmallBusinessServer.ShowMessageAboutError(ThisObject, MessageText, , , "OrderState", Cancel);
		EndIf;
		
	EndIf;
	
	
		// Сравнение таблицы материалов и распределения
	If ManualDistribution Then
		ProductionServer.CompareInventoryAndDictribution(ThisObject, Cancel);
	Else
		SmallBusinessServer.DeleteAttributeBeingChecked(CheckedAttributes, "InventoryDistribution.Quantity");
	EndIf;
	
	If CustomerOrderPosition = Enums.AttributePositionOnForm.InTabularSection Then
		CheckTSOrders(Cancel);
	EndIf; 

	
	If Operations.Count()>0 Then
		If PerformerPosition = Enums.AttributePositionOnForm.InTabularSection Then
			CheckedAttributes.Add("Operations.Performer");
		Else 
			CheckedAttributes.Add("Performer");
		EndIf;
			
		If StructuralUnitOperationPosition = Enums.AttributePositionOnForm.InTabularSection Then
			CheckedAttributes.Add("Brigade.StructuralUnit");
		Else
			CheckedAttributes.Add("StructuralUnitOperation");
		EndIf;
	EndIf; 
	
		// Этапы производства
	If GetFunctionalOption("UseProductionStages") 
		And OperationKind<>Enums.OperationKindsProductionOrder.Disassembly Then
		SpecsArray = New Array;
		For Each TabSecRow In Products Do
			If SpecsArray.Find(TabSecRow.Specification)=Undefined Then
				SpecsArray.Add(TabSecRow.Specification);
			EndIf; 
			If Not ValueIsFilled(TabSecRow.Specification) Then
				Break;
			EndIf; 
		EndDo; 
		If SpecsArray.Find(Catalogs.Specifications.EmptyRef())=Undefined Then
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
	
	 // Production stages
	CheckProductionStagesFilling(Cancel, PostingMode = DocumentWriteMode.UndoPosting);
	If Cancel Then
		Return;
	EndIf; 

	// Initialization of additional properties for document posting
	SmallBusinessServer.InitializeAdditionalPropertiesForPosting(Ref, AdditionalProperties);
	
	// Initialization of document data
	Documents.ProductionOrder.InitializeDocumentData(Ref, AdditionalProperties);
	
	// Preparation of record sets
	SmallBusinessServer.PrepareRecordSetsForRecording(ThisObject);
	
	// Registering in accounting sections
	SmallBusinessServer.ReflectInventoryTransferSchedule(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectProductionOrders(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectInventoryDemand(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectOrdersPlacement(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectInventory(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectProductRelease(AdditionalProperties, RegisterRecords, Cancel);
	
	// Этапы производства
	If OperationKind= Enums.OperationKindsProductionOrder.Assembly Then
		SmallBusinessServer.ReflectProductionStages(AdditionalProperties, RegisterRecords, Cancel);
	EndIf;
	
	// Ресурсы предприятия
	If GetFunctionalOption("PlanCompanyResourcesLoading") Then
		SmallBusinessServer.ReflectEnterpriseResources(AdditionalProperties, RegisterRecords, Cancel);
		TableCompanyResources = AdditionalProperties.TableForRegisterRecords.TableCompanyResources;
		ResourcePlanningCM.CreateRecordsEmployeeCalendarByResources(Ref,TableCompanyResources,Cancel);
	EndIf;

	
	// Writing of record sets
	SmallBusinessServer.WriteRecordSets(ThisObject);
	
	// Control
	Documents.ProductionOrder.RunControl(Ref, AdditionalProperties, Cancel);
	
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
	Documents.ProductionOrder.RunControl(Ref, AdditionalProperties, Cancel, True);
	
EndProcedure // UndoPosting()

Procedure FillStructuralUnitsTypes() Export
		
	StructuralUnitType = CommonUse.ObjectAttributeValue(StructuralUnit, "StructuralUnitType");
	StructuralUnitReserveType = CommonUse.ObjectAttributeValue(StructuralUnitReserve, "StructuralUnitType");
	
EndProcedure

Procedure FillInventoryBySpecification(NodesSpecificationStack, NodesTable = Undefined) Export
	
	TempTablesManager = New TempTablesManager;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT ALLOWED
	|	TableProduction.LineNumber AS LineNumber,
	|	TableProduction.Quantity AS Quantity,
	|	TableProduction.Factor AS Factor,
	|	TableProduction.Specification AS Specification,
	|	TableProduction.Stage AS Stage,
	|	TableProduction.CustomerOrder AS CustomerOrder
	|INTO TemporaryTableProduction
	|FROM
	|	&TableProduction AS TableProduction
	|WHERE
	|	TableProduction.Specification <> VALUE(Catalog.Specifications.EmptyRef)";
	
	If NodesTable = Undefined Then
		Inventory.Clear();
		TableProduction = Products.Unload();
		TypeDescriptionNumber = New TypeDescription("Number", , ,New NumberQualifiers(10,3));
		TableProduction.Columns.Add("Factor", TypeDescriptionNumber);
		TableProduction.Columns.Add("Stage", New TypeDescription("CatalogRef.ProductionStages"));
		For Each ProductsRow In TableProduction Do
			If ValueIsFilled(ProductsRow.MeasurementUnit)
				And TypeOf(ProductsRow.MeasurementUnit) = Type("CatalogRef.Uom") Then
				ProductsRow.Factor = ProductsRow.MeasurementUnit.Factor;
			Else
				ProductsRow.Factor = 1;
			EndIf;
		EndDo;
		NodesTable = TableProduction.CopyColumns("LineNumber, Quantity, Factor, Specification, CustomerOrder, Stage");
		Query.SetParameter("TableProduction", TableProduction);
	Else
		Query.SetParameter("TableProduction", NodesTable);
	EndIf;
	
	Query.Execute();
	
	Query.SetParameter("OperationKind", OperationKind);
	Query.SetParameter("StructuralUnitType", CommonUse.ObjectAttributeValue(StructuralUnit, "StructuralUnitType"));
	Query.Text =
	"SELECT ALLOWED
	|	MIN(TableProduction.LineNumber) AS ProductionLineNumber,
	|	TableProduction.Specification AS ProductionSpecification,
	|	MIN(TableMaterials.LineNumber) AS StructureLineNumber,
	|	TableMaterials.ContentRowType AS ContentRowType,
	|	CASE
	|		WHEN NOT FunctionalOptionUseProductionStages.Value
	|				OR &OperationKind = VALUE(Enum.OperationKindsProductionOrder.Disassembly)
	|				OR &StructuralUnitType <> VALUE(Enum.StructuralUnitsTypes.Department)
	|			THEN VALUE(Catalog.ProductionStages.EmptyRef)
	|		WHEN TableProduction.Stage <> VALUE(Catalog.ProductionStages.EmptyRef)
	|			THEN TableProduction.Stage
	|		ELSE TableMaterials.Stage
	|	END AS Stage,
	|	TableMaterials.ProductsAndServices AS ProductsAndServices,
	|	TableMaterials.ProductsAndServices.Warehouse AS StructuralUnit,
	|	CASE
	|		WHEN UseCharacteristics.Value
	|			THEN TableMaterials.Characteristic
	|		ELSE VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	|	END AS Characteristic,
	|	SUM(TableMaterials.Quantity / TableMaterials.ProductsQuantity * TableProduction.Factor * TableProduction.Quantity) AS Quantity,
	|	TableMaterials.MeasurementUnit AS MeasurementUnit,
	|	CASE
	|		WHEN TableMaterials.ContentRowType = VALUE(Enum.SpecificationContentRowTypes.Node)
	|				AND VALUETYPE(TableMaterials.MeasurementUnit) = TYPE(Catalog.Uom)
	|				AND TableMaterials.MeasurementUnit <> VALUE(Catalog.Uom.EmptyRef)
	|			THEN TableMaterials.MeasurementUnit.Factor
	|		ELSE 1
	|	END AS Factor,
	|	TableMaterials.CostPercentage AS CostPercentage,
	|	CASE
	|		WHEN TableMaterials.Specification = VALUE(Catalog.Specifications.EmptyRef)
	|			THEN ISNULL(DefaultSpecifications.Specification, VALUE(Catalog.Specifications.EmptyRef))
	|		ELSE TableMaterials.Specification
	|	END AS Specification,
	|	TableProduction.CustomerOrder AS CustomerOrder
	|FROM
	|	TemporaryTableProduction AS TableProduction
	|		LEFT JOIN Catalog.Specifications.Content AS TableMaterials
	|			LEFT JOIN InformationRegister.DefaultSpecifications AS DefaultSpecifications
	|			ON TableMaterials.ProductsAndServices = DefaultSpecifications.ProductsAndServices
	|				AND TableMaterials.Characteristic = DefaultSpecifications.Characteristic
	|		ON TableProduction.Specification = TableMaterials.Ref,
	|	Constant.FunctionalOptionUseCharacteristics AS UseCharacteristics,
	|	Constant.FunctionalOptionUseProductionStages AS FunctionalOptionUseProductionStages
	|WHERE
	|	TableMaterials.ProductsAndServices.ProductsAndServicesType = VALUE(Enum.ProductsAndServicesTypes.InventoryItem)
	|
	|GROUP BY
	|	TableProduction.Specification,
	|	TableMaterials.ContentRowType,
	|	CASE
	|		WHEN NOT FunctionalOptionUseProductionStages.Value
	|				OR &OperationKind = VALUE(Enum.OperationKindsProductionOrder.Disassembly)
	|				OR &StructuralUnitType <> VALUE(Enum.StructuralUnitsTypes.Department)
	|			THEN VALUE(Catalog.ProductionStages.EmptyRef)
	|		WHEN TableProduction.Stage <> VALUE(Catalog.ProductionStages.EmptyRef)
	|			THEN TableProduction.Stage
	|		ELSE TableMaterials.Stage
	|	END,
	|	TableMaterials.ProductsAndServices,
	|	TableMaterials.MeasurementUnit,
	|	CASE
	|		WHEN TableMaterials.ContentRowType = VALUE(Enum.SpecificationContentRowTypes.Node)
	|				AND VALUETYPE(TableMaterials.MeasurementUnit) = TYPE(Catalog.Uom)
	|				AND TableMaterials.MeasurementUnit <> VALUE(Catalog.Uom.EmptyRef)
	|			THEN TableMaterials.MeasurementUnit.Factor
	|		ELSE 1
	|	END,
	|	TableMaterials.CostPercentage,
	|	CASE
	|		WHEN TableMaterials.Specification = VALUE(Catalog.Specifications.EmptyRef)
	|			THEN ISNULL(DefaultSpecifications.Specification, VALUE(Catalog.Specifications.EmptyRef))
	|		ELSE TableMaterials.Specification
	|	END,
	|	CASE
	|		WHEN UseCharacteristics.Value
	|			THEN TableMaterials.Characteristic
	|		ELSE VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	|	END,
	|	TableProduction.CustomerOrder,
	|	TableMaterials.ProductsAndServices.Warehouse
	|
	|ORDER BY
	|	ProductionLineNumber,
	|	StructureLineNumber";
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		If Selection.ContentRowType = Enums.SpecificationContentRowTypes.Node Then
			NodesTable.Clear();
			If Not NodesSpecificationStack.Find(Selection.Specification) = Undefined Then
				TextOfMessage = NStr("en='При попытке заполнить табличную часть Материалы по спецификации,"
"обнаружено рекурсивное вхождение элемента';ru='При попытке заполнить табличную часть Материалы по спецификации,"
"обнаружено рекурсивное вхождение элемента';vi='Khi cố gắng điền vào phần bảng Nguyên vật liệu theo Bảng chi tiết nguyên vật liệu, đã tìm thấy sự xuất hiện đệ quy của một phần tử'")+" "+Selection.ProductsAndServices+" "+NStr("en='в спецификации';ru='в спецификации';vi='trong bảng kê chi tiết'")+" "+Selection.ProductionSpecification+"
									|Operation not executed!";
				Raise TextOfMessage;
			EndIf;
			NodesSpecificationStack.Add(Selection.Specification);
			NewRow = NodesTable.Add();
			FillPropertyValues(NewRow, Selection);
			FillInventoryBySpecification(NodesSpecificationStack, NodesTable);
		Else
			NewRow = Inventory.Add();
			FillPropertyValues(NewRow, Selection);
		EndIf;
	EndDo;
	
	NodesSpecificationStack.Clear();
	Inventory.GroupBy("Stage, ProductsAndServices, Characteristic, Batch, MeasurementUnit, Specification, CustomerOrder", "Quantity, Reserve, CostPercentage");
	
	BatchStatus = New ValueList;
	BatchStatus.Add(PredefinedValue("Enum.BatchStatuses.OwnInventory"));
	BatchStatus.Add(PredefinedValue("Enum.BatchStatuses.CommissionMaterials"));
	
	For Each TabularSectionRow In Inventory Do
		
		TabularSectionRow.Batch = Undefined;
		
		If ValueIsFilled(TabularSectionRow.StructuralUnit) And WarehousePosition=Enums.AttributePositionOnForm.InTabularSection Then
			Continue;
		EndIf; 
		TabularSectionRow.StructuralUnit = StructuralUnitReserve;
	EndDo;
	
	ObjectFillingSB.FillTableByHeader(ThisObject, "Inventory", "CustomerOrder", "CustomerOrderPosition");
	
EndProcedure

Procedure FillOperationsBySpecification() Export  
	
	Operations.Clear();
	If Not GetFunctionalOption("UseTechOperations") Then
		Return;
	EndIf; 
	
	ProductionServer.FillConnectionKeys(Products);
	
	Operations.Clear();
	If PerformerPosition = Enums.AttributePositionOnForm.InTabularSection Then
		Brigade.Clear();
	EndIf; 
	
	ProductsTable = Products.Unload();
	UseReservation = Constants.FunctionalOptionInventoryReservation.Get();
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Inventory", ProductsTable.Copy(, "LineNumber, ProductsAndServices, Specification"));
	Query.Text =
	"SELECT
	|	TabularSection.LineNumber AS LineNumber,
	|	TabularSection.Specification AS Specification,
	|	TabularSection.Specification AS NestedSpecification,
	|	TRUE AS ThisNode,
	|	TabularSection.ProductsAndServices AS Operation,
	|	1 AS TimeRate
	|INTO TempTable
	|FROM
	|	&Inventory AS TabularSection
	|WHERE
	|	TabularSection.Specification <> VALUE(Catalog.Specifications.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	0 AS Level,
	|	MIN(TempTable.LineNumber) AS Order,
	|	0 AS LineNumber,
	|	VALUE(Catalog.ProductionStages.EmptyRef) AS Stage,
	|	TempTable.Specification AS Specification,
	|	TempTable.NestedSpecification AS NestedSpecification,
	|	TempTable.ThisNode AS ThisNode,
	|	TempTable.Operation AS Operation,
	|	TempTable.TimeRate AS TimeRate
	|INTO OperationTable
	|FROM
	|	TempTable AS TempTable
	|
	|GROUP BY
	|	TempTable.Specification,
	|	TempTable.Operation,
	|	TempTable.NestedSpecification,
	|	TempTable.ThisNode,
	|	TempTable.TimeRate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TempTable";
	Query.Execute();
	ProductionServer.DisassemblOperations(Query, Undefined, "Products");
	
	Query.SetParameter("Products", ProductsTable);
	Query.SetParameter("OperationKind", OperationKind);
	Query.Text =
	"SELECT
	|	Products.LineNumber AS LineNumber,
	|	Products.ConnectionKey AS ConnectionKeyProduct,
	|	Products.CustomerOrder AS CustomerOrder,
	|	CAST(Products.ProductsAndServices AS Catalog.ProductsAndServices) AS ProductsAndServices,
	|	Products.Specification AS Specification,
	|	Products.Quantity AS Quantity,
	|	Products.MeasurementUnit AS MeasurementUnit
	|INTO Products
	|FROM
	|	&Products AS Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Products.CustomerOrder AS CustomerOrder,
	|	Products.LineNumber AS LineNumber,
	|	Products.ConnectionKeyProduct AS ConnectionKeyProduct,
	|	Products.Quantity AS Quantity,
	|	CASE
	|		WHEN FunctionalOptionUseProductionStages.Value
	|				AND &OperationKind <> VALUE(Enum.OperationKindsProductionOrder.Disassembly)
	|			THEN OperationTable.Stage
	|		ELSE VALUE(Catalog.ProductionStages.EmptyRef)
	|	END AS Stage,
	|	OperationTable.Operation AS Operation,
	|	CASE
	|		WHEN OperationTable.Operation REFS Catalog.ProductsAndServices
	|			THEN OperationTable.Operation.MeasurementUnit
	|		ELSE VALUE(Catalog.UOMClassifier.EmptyRef)
	|	END AS MeasurementUnit,
	|	CASE
	|		WHEN OperationTable.Operation REFS Catalog.ProductsAndServices
	|			THEN OperationTable.Operation.FixedCost
	|		ELSE TRUE
	|	END AS FixedCost,
	|	CASE
	|		WHEN VALUETYPE(Products.MeasurementUnit) = TYPE(Catalog.UOMClassifier)
	|			THEN 1
	|		ELSE CAST(Products.MeasurementUnit AS Catalog.UOM).Factor
	|	END AS Factor,
	|	ISNULL(OperationTable.TimeRate, 0) * CASE
	|		WHEN VALUETYPE(Products.MeasurementUnit) = TYPE(Catalog.UOM)
	|				AND Products.MeasurementUnit <> VALUE(Catalog.UOM.EmptyRef)
	|			THEN CAST(Products.MeasurementUnit AS Catalog.UOM).Factor
	|		ELSE 1
	|	END AS TimeRate,
	|	OperationTable.Level AS Level,
	|	OperationTable.Order AS Order,
	|	OperationTable.LineNumber AS OperationLineNumber
	|INTO Operations
	|FROM
	|	Products AS Products
	|		LEFT JOIN OperationTable AS OperationTable
	|		ON Products.Specification = OperationTable.Specification,
	|	Constant.FunctionalOptionUseProductionStages AS FunctionalOptionUseProductionStages
	|WHERE
	|	Products.ProductsAndServices.ProductsAndServicesType IN (VALUE(Enum.ProductsAndServicesTypes.InventoryItem), VALUE(Enum.ProductsAndServicesTypes.Work))
	|	AND NOT OperationTable.Operation IS NULL
	|	AND OperationTable.Operation <> VALUE(Catalog.ProductsAndServices.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Operations.CustomerOrder AS CustomerOrder,
	|	Operations.LineNumber AS LineNumber,
	|	Operations.ConnectionKeyProduct AS ConnectionKeyProduct,
	|	Operations.Quantity AS QuantityPlan,
	|	Operations.Stage AS Stage,
	|	Operations.Operation AS Operation,
	|	Operations.FixedCost AS FixedCost,
	|	Operations.Factor AS Factor,
	|	Operations.MeasurementUnit AS MeasurementUnit,
	|	Operations.TimeRate AS TimeRate
	|FROM
	|	Operations AS Operations
	|
	|ORDER BY
	|	Operations.LineNumber,
	|	Operations.Level,
	|	Operations.Order,
	|	Operations.OperationLineNumber";
	
	Selection = Query.Execute().Select();
	
	ConnectionKey = 0;
	While Selection.Next() Do
		NewRow = Operations.Add();
		FillPropertyValues(NewRow, Selection);
		If Not UseReservation Then
			NewRow.CustomerOrder = Documents.CustomerOrder.EmptyRef();
		EndIf;
		If Not PerformerPosition = Enums.AttributePositionOnForm.InTabularSection Then
			NewRow.Performer = Performer;
		EndIf; 
		If StructuralUnitOperationPosition = Enums.AttributePositionOnForm.InTabularSection Then
			NewRow.StructuralUnit = Catalogs.StructuralUnits.MainDepartment;
		Else
			NewRow.StructuralUnit = StructuralUnitOperation;
		EndIf;
		NewRow.NormRate = NewRow.TimeRate * NewRow.QuantityPlan;
		ConnectionKey = ConnectionKey + 1;
		NewRow.ConnectionKey = ConnectionKey;
	EndDo; 
	
EndProcedure

Procedure CheckTSOrders(Cancel)
	
	Orders = New Array;
	For Each TabSecRow In Products Do
		If Orders.Find(TabSecRow.CustomerOrder)=Undefined Then
			Orders.Add(TabSecRow.CustomerOrder);
		EndIf; 
	EndDo;
	
	For Each TabSecRow In Inventory Do
		If Orders.Find(TabSecRow.CustomerOrder)=Undefined Then
			SmallBusinessServer.ShowMessageAboutError(
			ThisObject,
			StrTemplate(NStr("en='In line №%1 of the table parts of the ""Materials"" uses a customer order that is not in the table parts of the ""Products"".';ru='В строке №%1 табл. части ""Материалы"" используется заказ покупателя, отсутствующий в табл. части ""Продукция"".';vi='Trong dòng số %1 của phần bảng ""Nguyên vật liệu"", đơn đặt hàng của người mua được sử dụng, không có trong  phần bảng ""Sản phẩm"".'"), TabSecRow.LineNumber),
			"Inventory",
			TabSecRow.LineNumber,
			"CustomerOrder",
			Cancel);
		EndIf; 
	EndDo; 
	
	For Each TabSecRow In Operations Do
		If Orders.Find(TabSecRow.CustomerOrder)=Undefined Then
			SmallBusinessServer.ShowMessageAboutError(
			ThisObject,
			StrTemplate(NStr("en='In line №%1 of the tabular section of the ""Operations"" uses a customer order that is not in the tabular section ""Products"".';ru='В строке №%1 табл. части ""Операции"" используется заказ покупателя, отсутствующий в табл. части ""Продукция"".';vi='Trong dòng số %1 của bảng. một phần của ""Giao dịch"" sử dụng đơn đặt hàng của khách hàng không có trong bảng ""Sản phẩm"".'"), TabSecRow.LineNumber),
			"Operations",
			TabSecRow.LineNumber,
			"CustomerOrder",
			Cancel);
		EndIf; 
	EndDo; 
	
EndProcedure

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

Function HeaderStructuralUnit(TabularSection)
	
	CurStructuralUnit = StructuralUnitReserve;
	
	If TabularSection.Count()=0 Then
		Return CurStructuralUnit;
	EndIf; 
	
	CurStructuralUnit = TabularSection[0].StructuralUnit;
	
	If TabularSection.Count()=1 Then
		Return CurStructuralUnit;
	EndIf; 
	
	TableStructuralUnit = TabularSection.UnloadColumns("StructuralUnit");
	For Each TabSecRow In TabularSection Do
		If Not ValueIsFilled(TabSecRow.CustomerOrder) Then
			Continue;
		EndIf; 
		FillPropertyValues(TableStructuralUnit.Add(), TabSecRow);
	EndDo; 
	TableStructuralUnit.Columns.Add("Quantity", New TypeDescription("Number"));
	For Each TabSecRow In TableStructuralUnit Do
		TabSecRow.Quantity = 1;
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

Function HeaderOperationStructuralUnit()
	
	CurStructuralUnit = StructuralUnitOperation;
	
	If Operations.Count()=0 Then
		Return CurStructuralUnit;
	EndIf; 
	
	CurStructuralUnit = Operations[0].StructuralUnit;
	
	If Operations.Count()=1 Then
		Return CurStructuralUnit;
	EndIf; 
	
	TableStructuralUnit = Operations.Unload(, "StructuralUnit");
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

Function HeaderPerfomer()
	
	CurPerfomer = Performer;
	
	If Operations.Count()=0 Then
		Return CurPerfomer;
	EndIf; 
	
	CurPerfomer = Operations[0].Performer;
	
	If Operations.Count()=1 Then
		Return CurPerfomer;
	EndIf; 
	
	TablePerfomer = Operations.Unload(, "Performer");
	TablePerfomer.Columns.Add("Quantity", New TypeDescription("Number"));
	For Each CurRow In TablePerfomer Do
		CurRow.Quantity = 1;
	EndDo;
	TablePerfomer.GroupBy("Performer", "Quantity");
	
	If TablePerfomer.Count() < 2 Then
		Return CurPerfomer;
	EndIf;
	
	TablePerfomer.Sort("Quantity Desc");
	
	If TablePerfomer[0].Quantity = TablePerfomer[1].Quantity Then
		Return CurPerfomer;
	EndIf;
	
	CurPerfomer = TablePerfomer[0].Performer;
	
	Return CurPerfomer;
	
EndFunction

Procedure CheckProductionStagesFilling(Cancel, PostingCancel = False)

	If Not GetFunctionalOption("UseProductionStages") Then
		Return;
	EndIf;
	
	// Формирование таблицы продукции, использующей этапы производства
	If PostingCancel Then
		ProductsTable = Products.UnloadColumns();
	Else
		ProductsTable = Products.Unload();
	EndIf; 
	ProductsTable.Columns.Add("TabName", New TypeDescription("String", New StringQualifiers(100)));
	ProductsTable.FillValues("Products", "TabName");
	If OperationKind <> Enums.OperationKindsProductionOrder.Disassembly Then
		ProductionServer.AddDeletedProducts(Ref, ProductsTable, "Products");
	EndIf; 
	ProductsTable.Columns.Add("ProductionOrder", New TypeDescription("DocumentRef.ProductionOrder"));
	ProductsTable.FillValues(Ref, "ProductionOrder");
	If CustomerOrderPosition <> Enums.AttributePositionOnForm.InTabularSection Then
		ProductsTable.FillValues(CustomerOrder, "CustomerOrder");
	EndIf;
	
	SpecsArray = New Array;
	For Each TabSecRow In ProductsTable Do
		If OperationKind=Enums.OperationKindsProductionOrder.Disassembly Then
			Break;
		EndIf; 
		If Not ValueIsFilled(TabSecRow.Specification) Then
			Continue;
		EndIf; 
		If SpecsArray.Find(TabSecRow.Specification)=Undefined Then
			SpecsArray.Add(TabSecRow.Specification);
		EndIf; 
	EndDo; 
	
	SpecsArray = ProductionServer.SpecificationsWithProductionStages(SpecsArray);
	CheckingProducts = ProductsTable.CopyColumns();
	For Each ProductsRow In ProductsTable Do
		If Not ValueIsFilled(ProductsRow.Specification) Or SpecsArray.Find(ProductsRow.Specification)=Undefined Then
			Continue;
		EndIf; 
		FillPropertyValues(CheckingProducts.Add(), ProductsRow);
	EndDo;
	
	// Поэтапное производство выполняется только на подразделениях
	If CheckingProducts.Count()>0 
		And CommonUse.ObjectAttributeValue(StructuralUnit, "StructuralUnitType")<>Enums.StructuralUnitsTypes.Department Then
		SmallBusinessServer.ShowMessageAboutError(
		ThisObject,
		NStr("en='Only a department can be a manufacturer in stage production';vi='Chỉ có một bộ phận có thể là một nhà sản xuất trong giai đoạn sản xuất'"),
		,
		,
		"StructuralUnit",
		Cancel);
	EndIf; 
	
	// Запрет дублирования продукции
	DuplicatesControlTable = CheckingProducts.Copy();
	DuplicatesControlTable.Columns.Add("RowQuantity", New TypeDescription("Number", New NumberQualifiers(5, 0)));
	DuplicatesControlTable.FillValues(1, "RowQuantity");
	DuplicatesControlTable.GroupBy("CustomerOrder, ProductionOrder, ProductsAndServices, Characteristic, Batch", "RowQuantity");
	For Each ProductsRow In DuplicatesControlTable Do
		If ProductsRow.RowQuantity >1 Then
			FilterStructure = New Structure("CustomerOrder, ProductionOrder, ProductsAndServices, Characteristic, Batch");
			FillPropertyValues(FilterStructure, ProductsRow);
			TSRows = ProductsTable.FindRows(FilterStructure);
			For Each FindingRow In TSRows Do
				SmallBusinessServer.ShowMessageAboutError(
				ThisObject,
				StrTemplate(NStr("en='Duplicate products using production steps in line %1';vi='Sao chép sản phẩm bằng các bước sản xuất trong dòng %1'"), FindingRow.LineNumber),
				"Products",
				FindingRow.LineNumber,
				"ProductsAndServices",
				Cancel);
			EndDo; 
		EndIf; 
	EndDo; 
	
	If GetFunctionalOption("PerformStagesByDifferentDepartments") And Not PostingCancel Then
		For Each ProductsRow In CheckingProducts Do
			If Not ValueIsFilled(ProductsRow.CompletiveStageDepartment) Then
				SmallBusinessServer.ShowMessageAboutError(
				ThisObject,
				StrTemplate(NStr("en='Not filed column ""Completive stage department"" in row %1 of ""Products""';vi='Không nộp cột ""Bộ phận giai đoạn hoàn thành"" trong hàng %1 của ""Sản phẩm""'"), ProductsRow.LineNumber),
				"Products",
				ProductsRow.LineNumber,
				"CompletiveStageDepartment",
				Cancel);
			EndIf; 
		EndDo; 
	EndIf;
	
	// Проверка уникальности завершающего подразделения и количества продукции
	ProductionServer.StageProductionCheck(ThisObject, CheckingProducts, Cancel);
	
EndProcedure


#EndIf

