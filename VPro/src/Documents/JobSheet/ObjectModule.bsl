#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

////////////////////////////////////////////////////////////////////////////////
// EXPORT PROCEDURES AND FUNCTIONS OF DOCUMENT

// Procedure fills team members.
//
Procedure FillTeamMembers() Export

	If ValueIsFilled(Performer) AND TypeOf(Performer) = Type("CatalogRef.Teams") Then
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	WorkgroupsContent.Employee,
		|	1 AS LPF
		|FROM
		|	Catalog.Teams.Content AS WorkgroupsContent
		|WHERE
		|	WorkgroupsContent.Ref = &Ref";
		
		Query.SetParameter("Ref", Performer);	
		
		TeamMembers.Load(Query.Execute().Unload());
		
	EndIf;	

EndProcedure

// Procedure fills tabular section according to specification.
//
Procedure FillTableBySpecification(BaseSpecification, BySpecification, ByMeasurementUnit, ByQuantity, ByCostPercentage = Undefined, TableContent)
	
	Query = New Query(
	"SELECT
	|	MAX(SpecificationsContent.LineNumber) AS SpecificationsContentLineNumber,
	|	SpecificationsContent.ProductsAndServices AS ProductsAndServices,
	|	SpecificationsContent.ContentRowType AS ContentRowType,
	|	CASE
	|		WHEN &UseCharacteristics
	|			THEN SpecificationsContent.ПОЛЕВИДА
	|		ELSE VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	|	END AS Characteristic,
	|	SpecificationsContent.Specification AS Specification,
	|	SpecificationsContent.CostPercentage AS CostPercentage,
	|	SpecificationsContent.MeasurementUnit AS MeasurementUnit,
	|	SUM(SpecificationsContent.Quantity / SpecificationsContent.ProductsQuantity * &Factor * &Quantity) AS Quantity
	|FROM
	|	Catalog.Specifications.Content AS SpecificationsContent
	|WHERE
	|	SpecificationsContent.Ref = &Specification
	|	AND SpecificationsContent.ProductsAndServices.ProductsAndServicesType = VALUE(Enum.ProductsAndServicesTypes.InventoryItem)
	|
	|GROUP BY
	|	SpecificationsContent.ProductsAndServices,
	|	CASE
	|		WHEN &UseCharacteristics
	|			THEN SpecificationsContent.ПОЛЕВИДА
	|		ELSE VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	|	END,
	|	SpecificationsContent.Specification,
	|	SpecificationsContent.MeasurementUnit,
	|	SpecificationsContent.ContentRowType,
	|	SpecificationsContent.CostPercentage
	|
	|ORDER BY
	|	SpecificationsContentLineNumber");
	
	Query.SetParameter("UseCharacteristics", Constants.ФункциональнаяОпцияИспользоватьХарактеристики.Get());
	
	Query.SetParameter("Specification", BySpecification);
	Query.SetParameter("Quantity", ByQuantity);
	
	If TypeOf(ByMeasurementUnit) = Type("СправочникСсылка.ЕдиницыИзмерения")
		And ValueIsFilled(ByMeasurementUnit) Then
		ByFactor = ByMeasurementUnit.Factor;
	Else
		ByFactor = 1;
	EndIf;
	Query.SetParameter("Factor", ByFactor);
	
	ContentTable = Query.Execute().Unload();
	TotalCostPercentage = ContentTable.Total("CostPercentage");
	For Each ContentRow In ContentTable Do
		
		If ContentRow.ContentRowType = Enums.SpecificationContentRowTypes.Node Then
			
			NodePercentage = ?(ByCostPercentage<>Undefined And TotalCostPercentage<>0, ByCostPercentage*ContentRow.CostPercentage/TotalCostPercentage, ContentRow.CostPercentage);
			FillTableBySpecification(BaseSpecification, ContentRow.Specification, ContentRow.MeasurementUnit, ContentRow.Quantity, NodePercentage, TableContent);
			
		Else
			
			NewRow = TableContent.Add();
			FillPropertyValues(NewRow, ContentRow);
			NewRow.BaseSpecification = BaseSpecification;
			If ByCostPercentage<>Undefined And TotalCostPercentage<>0 Then
				NewRow.CostPercentage = ByCostPercentage*NewRow.CostPercentage/TotalCostPercentage;
			EndIf; 
			
		EndIf;
		
	EndDo;
	
EndProcedure // ЗаполнитьТаблицуПоСпецификации()

// Procedure for filling the document basing on Customer order.
//
Procedure FillUsingCustomerOrder(FillingData)
	
	AttributeValues = CommonUse.ObjectAttributesValues(FillingData,
			New Structure("Company, OperationKind, SalesStructuralUnit, Start, Finish, ShipmentDate"));
	
	Company = AttributeValues.Company;
	StructuralUnit = AttributeValues.SalesStructuralUnit;
	DocumentCurrency = Catalogs.PriceKinds.Accounting.PriceCurrency;
	
	If AttributeValues.OperationKind = Enums.OperationKindsCustomerOrder.WorkOrder Then
		
		ClosingDate = AttributeValues.Finish;
		Period = ?(ValueIsFilled(AttributeValues.Start), AttributeValues.Start, CurrentDate());
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	&Period AS Period,
		|	CustomerOrderWorks.LineNumber AS LineNumber,
		|	CustomerOrderWorks.Ref AS CustomerOrder,
		|	CustomerOrderWorks.ProductsAndServices AS ProductsAndServices,
		|	CustomerOrderWorks.Characteristic AS Characteristic,
		|	CustomerOrderWorks.Quantity AS QuantityPlan,
		|	CustomerOrderWorks.Specification AS Specification,
		|	OperationSpecification.Operation,
		|	OperationSpecification.Operation.MeasurementUnit AS MeasurementUnit,
		|	ISNULL(OperationSpecification.TimeNorm, 0) / ISNULL(OperationSpecification.ProductsQuantity, 1) AS TimeNorm,
		|	ISNULL(ProductsAndServicesPricesSliceLast.Price / ISNULL(ProductsAndServicesPricesSliceLast.MeasurementUnit.Factor, 1), 0) AS Tariff
		|FROM
		|	Document.CustomerOrder.Works AS CustomerOrderWorks
		|		LEFT JOIN Catalog.Specifications.Operations AS OperationSpecification
		|			LEFT JOIN InformationRegister.ProductsAndServicesPrices.SliceLast(&Period, PriceKind = VALUE(Catalog.PriceKinds.Accounting)) AS ProductsAndServicesPricesSliceLast
		|			ON OperationSpecification.Operation = ProductsAndServicesPricesSliceLast.ProductsAndServices
		|		ON CustomerOrderWorks.Specification = OperationSpecification.Ref
		|WHERE
		|	CustomerOrderWorks.Ref = &BasisDocument
		|	AND CustomerOrderWorks.ProductsAndServices.ProductsAndServicesType = VALUE(Enum.ProductsAndServicesTypes.Work)
		|
		|ORDER BY
		|	LineNumber";
		
	Else
		
		ClosingDate = AttributeValues.ShipmentDate;
		Period = ?(ValueIsFilled(AttributeValues.ShipmentDate), AttributeValues.ShipmentDate, CurrentDate());
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	&Period AS Period,
		|	CustomerOrderInventory.LineNumber AS LineNumber,
		|	CustomerOrderInventory.Ref AS CustomerOrder,
		|	CustomerOrderInventory.ProductsAndServices AS ProductsAndServices,
		|	CustomerOrderInventory.Characteristic AS Characteristic,
		|	CustomerOrderInventory.Batch AS Batch,
		|	CustomerOrderInventory.Quantity AS QuantityPlan,
		|	CustomerOrderInventory.Specification AS Specification,
		|	OperationSpecification.Operation,
		|	OperationSpecification.Operation.MeasurementUnit AS MeasurementUnit,
		|	ISNULL(OperationSpecification.TimeNorm, 0) / ISNULL(OperationSpecification.ProductsQuantity, 1) * CASE
		|		WHEN VALUETYPE(CustomerOrderInventory.MeasurementUnit) = TYPE(Catalog.UOM)
		|				AND CustomerOrderInventory.MeasurementUnit <> VALUE(Catalog.UOM.EmptyRef)
		|			THEN CustomerOrderInventory.MeasurementUnit.Factor
		|		ELSE 1
		|	END AS TimeNorm,
		|	ISNULL(ProductsAndServicesPricesSliceLast.Price / ISNULL(ProductsAndServicesPricesSliceLast.MeasurementUnit.Factor, 1), 0) AS Tariff
		|FROM
		|	Document.CustomerOrder.Inventory AS CustomerOrderInventory
		|		LEFT JOIN Catalog.Specifications.Operations AS OperationSpecification
		|			LEFT JOIN InformationRegister.ProductsAndServicesPrices.SliceLast(&Period, PriceKind = VALUE(Catalog.PriceKinds.Accounting)) AS ProductsAndServicesPricesSliceLast
		|			ON OperationSpecification.Operation = ProductsAndServicesPricesSliceLast.ProductsAndServices
		|		ON CustomerOrderInventory.Specification = OperationSpecification.Ref
		|WHERE
		|	CustomerOrderInventory.Ref = &BasisDocument
		|	AND (CustomerOrderInventory.ProductsAndServices.ProductsAndServicesType = VALUE(Enum.ProductsAndServicesTypes.InventoryItem)
		|			OR CustomerOrderInventory.ProductsAndServices.ProductsAndServicesType = VALUE(Enum.ProductsAndServicesTypes.Work))
		|	AND (CustomerOrderInventory.Specification <> VALUE(Catalog.Specifications.EmptyRef)
		|			OR CustomerOrderInventory.ProductsAndServices.ReplenishmentMethod = VALUE(Enum.InventoryReplenishmentMethods.Production))
		|
		|ORDER BY
		|	LineNumber";
		
	EndIf;
	
	Query.SetParameter("BasisDocument", FillingData);
	Query.SetParameter("Period", Period);
	
	Operations.Clear();
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		Selection = QueryResult.Select();
		While Selection.Next() Do
			NewRow = Operations.Add();
			FillPropertyValues(NewRow, Selection);
		EndDo;
		
	EndIf
	
EndProcedure // FillByCustomerOrder()

Procedure FillByProductionOrder(ProductionOrderRef)
	
	// Основание и настройка документа.
	If TypeOf(ProductionOrderRef) = Type("Structure") And ProductionOrderRef.Property("ProductionOrderArray") Then
		OrderArray = ProductionOrderRef.ProductionOrderArray;
		ProductionOrderPosition = Enums.AttributePositionOnForm.InTabularSection;
		PerformerPosition = Enums.AttributePositionOnForm.InTabularSection;
		StructuralUnitPosition = Enums.AttributePositionOnForm.InTabularSection;
	Else
		OrderArray = New Array;
		OrderArray.Add(ProductionOrderRef);
		ProductionOrderPosition = SmallBusinessReUse.GetValueOfSetting("CustomerOrderPositionInProductionDocuments");
		If Not ValueIsFilled(ProductionOrderPosition) Then
			ProductionOrderPosition = Enums.AttributePositionOnForm.InHeader;
		EndIf;
		If ProductionOrderPosition = Enums.AttributePositionOnForm.InHeader Then
			ProductionOrder = ProductionOrderRef;
		EndIf;
	EndIf;
	If OrderArray.Count()=0 Then
		Return;
	EndIf; 
	
	Query = New Query;
	Query.SetParameter("OrderArray", OrderArray);
	Query.Text =
	"SELECT TOP 1
	|	ProductionOrder.OperationKind AS OperationKind,
	|	ProductionOrder.StructuralUnit.StructuralUnitType AS StructuralUnitType
	|FROM
	|	Document.ProductionOrder AS ProductionOrder
	|WHERE
	|	ProductionOrder.Ref IN(&OrderArray)";
	Selection = Query.Execute().Select();
	Selection.Next();
	
	If Selection.StructuralUnitType = Enums.StructuralUnitsTypes.Warehouse Then
		Raise NStr("en='A Job sheet cannot be entered based on a warehouse production order';ru='Сдельный наряд не может быть введен на основании заказа на производство по складу!';vi='Công khoán không thể được nhập trên cơ sở của một đơn đặt hàng sản xuất theo kho!'");
	EndIf;
	
	If Selection.OperationKind = Enums.OperationKindsProductionOrder.Assembly Then
		FillByCustomerOrderAssembly(OrderArray);
	ElsIf Selection.OperationKind = Enums.OperationKindsProductionOrder.Disassembly Then
		FillByProductionOrderDisassembly(OrderArray);
	EndIf;
	
	If OrderArray.Count()=1 Then
		BasisDocument = OrderArray[0];
	EndIf; 

	
EndProcedure

Procedure FillByCustomerOrderAssembly(OrderArray)
	
	Query = New Query;
	Query.SetParameter("OrderArray", OrderArray);
	Query.Text =
	"SELECT TOP 1
	|	ProductionOrder.Company AS Company,
	|	ProductionOrder.StructuralUnitOperation AS StructuralUnit,
	|	ProductionOrder.Performer AS Performer,
	|	ProductionOrder.OperationPlanned AS OperationPlanned,
	|	MAX(ProductionOrder.Finish) AS Finish,
	|	ProductionOrder.PerformerPosition AS PerformerPosition,
	|	ProductionOrder.StructuralUnitOperationPosition AS StructuralUnitPosition
	|FROM
	|	Document.ProductionOrder AS ProductionOrder
	|WHERE
	|	ProductionOrder.Ref IN(&OrderArray)
	|
	|GROUP BY
	|	ProductionOrder.Company,
	|	ProductionOrder.StructuralUnitOperation,
	|	ProductionOrder.Performer,
	|	ProductionOrder.OperationPlanned,
	|	ProductionOrder.PerformerPosition,
	|	ProductionOrder.StructuralUnitOperationPosition";
	HeaderSelection = Query.Execute().Select();
	HeaderSelection.Next();
	Period = ?(ValueIsFilled(HeaderSelection.Finish), HeaderSelection.Finish, CurrentSessionDate());
	
	FillPropertyValues(ThisObject, HeaderSelection, "Company" + ?(OrderArray.Count()=1, ", StructuralUnit, Performer, PerformerPosition, StructuralUnitPosition", ""));
	
	DocumentCurrency = Catalogs.PriceKinds.Accounting.PriceCurrency;
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("RoundingTable", SmallBusinessServer.RoundingTable());
	Query.SetParameter("OrderArray", OrderArray);
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Period", Period);
	
	If HeaderSelection.OperationPlanned Then
		
		Closed = True;
		
		Query.Text =
		"SELECT
		|	ProductionOrderOperations.Ref AS ProductionOrder,
		|	ProductionOrderOperations.Ref.Company AS Company,
		|	ProductionOrderOperations.StructuralUnit AS StructuralUnit,
		|	ProductionOrderOperations.Ref.Finish AS ClosingDate,
		|	&Period AS Period,
		|	ProductionOrderOperations.CustomerOrder AS CustomerOrder,
		|	ProductionOrderOperations.LineNumber AS LineNumber,
		|	ProductionOrderProducts.ProductsAndServices AS ProductsAndServices,
		|	ProductionOrderProducts.Characteristic AS Characteristic,
		|	ProductionOrderOperations.QuantityPlan AS Quantity,
		|	ProductionOrderProducts.Specification AS Specification,
		|	ProductionOrderProducts.Batch AS Batch,
		|	ProductionOrderOperations.Operation AS Operation,
		|	ProductionOrderOperations.Stage AS Stage,
		|	ProductionOrderProducts.CompletiveStageDepartment AS CompletiveStageDepartment,
		|	ProductionOrderOperations.MeasurementUnit AS MeasurementUnit,
		|	CASE
		|		WHEN ProductionOrderOperations.Operation REFS Catalog.ProductsAndServices
		|				AND ProductionOrderOperations.Operation <> VALUE(Catalog.ProductsAndServices.EmptyRef)
		|			THEN ProductionOrderOperations.Operation.FixedCost
		|		ELSE TRUE
		|	END AS FixedCost,
		|	CASE
		|		WHEN ValueType(ProductionOrderOperations.MeasurementUnit) = TYPE(Catalog.UOMClassifier)
		|			THEN 1
		|		ELSE ProductionOrderOperations.MeasurementUnit.Factor
		|	END AS Factor,
		|	ProductionOrderOperations.TimeRate AS TimeNorm,
		|	ProductionOrderOperations.ConnectionKey AS ConnectionKey,
		|	ProductionOrderOperations.Performer AS Performer,
		|	0 AS Level,
		|	0 AS Order,
		|	ProductionOrderOperations.LineNumber AS OperationLineNumber
		|INTO Operations
		|FROM
		|	Document.ProductionOrder.Operations AS ProductionOrderOperations
		|		LEFT JOIN Document.ProductionOrder.Products AS ProductionOrderProducts
		|		ON ProductionOrderOperations.ConnectionKeyProduct = ProductionOrderProducts.ConnectionKey
		|			AND ProductionOrderOperations.Ref = ProductionOrderProducts.Ref
		|WHERE
		|	ProductionOrderOperations.Ref IN(&OrderArray)";
		
	Else
		
		ProductionServer.DisassemblOperations(Query, OrderArray, "Products");
		Query.Text =
		"SELECT
		|	ProductionOrderProducts.Ref AS ProductionOrder,
		|	ProductionOrderProducts.Ref.Company AS Company,
		|	ProductionOrderProducts.StructuralUnit AS StructuralUnit,
		|	ProductionOrderProducts.Ref.Finish AS ClosingDate,
		|	&Period AS Period,
		|	ProductionOrderProducts.CustomerOrder AS CustomerOrder,
		|	ProductionOrderProducts.LineNumber AS LineNumber,
		|	ProductionOrderProducts.ProductsAndServices AS ProductsAndServices,
		|	ProductionOrderProducts.Characteristic AS Characteristic,
		|	ProductionOrderProducts.Quantity AS Quantity,
		|	ProductionOrderProducts.Specification AS Specification,
		|	ProductionOrderProducts.Batch AS Batch,
		|	OperationTable.Operation AS Operation,
		|	OperationTable.Stage AS Stage,
		|	ProductionOrderProducts.CompletiveStageDepartment AS CompletiveStageDepartment,
		|	CASE
		|		WHEN OperationTable.Operation REFS Catalog.ProductsAndServices
		|			THEN OperationTable.Operation.MeasurementUnit
		|		ELSE VALUE(Catalog.UOMClassifier.EmptyRef)
		|	END AS MeasurementUnit,
		|	CASE
		|		WHEN OperationTable.Operation REFS Catalog.ProductsAndServices
		|				AND OperationTable.Operation <> VALUE(Catalog.ProductsAndServices.EmptyRef)
		|			THEN OperationTable.Operation.FixedCost
		|		ELSE TRUE
		|	END AS FixedCost,
		|	CASE
		|		WHEN VALUETYPE(ProductionOrderProducts.MeasurementUnit) = TYPE(Catalog.UOMClassifier)
		|			THEN 1
		|		ELSE ProductionOrderProducts.MeasurementUnit.Factor
		|	END AS Factor,
		|	ISNULL(OperationTable.TimeRate, 0) * CASE
		|		WHEN VALUETYPE(ProductionOrderProducts.MeasurementUnit) = TYPE(Catalog.UOM)
		|				AND ProductionOrderProducts.MeasurementUnit <> VALUE(Catalog.UOM.EmptyRef)
		|			THEN ProductionOrderProducts.MeasurementUnit.Factor
		|		ELSE 1
		|	END AS TimeNorm,
		|	0 AS ConnectionKey,
		|	VALUE(Catalog.Employees.EmptyRef) AS Performer,
		|	OperationTable.Level AS Level,
		|	OperationTable.Order AS Order,
		|	OperationTable.LineNumber AS OperationLineNumber
		|INTO Operations
		|FROM
		|	Document.ProductionOrder.Products AS ProductionOrderProducts
		|		LEFT JOIN OperationTable AS OperationTable
		|		ON ProductionOrderProducts.Specification = OperationTable.Specification
		|WHERE
		|	ProductionOrderProducts.Ref IN(&OrderArray)
		|	AND ProductionOrderProducts.ProductsAndServices.ProductsAndServicesType IN (VALUE(Enum.ProductsAndServicesTypes.InventoryItem), VALUE(Enum.ProductsAndServicesTypes.Work))";
		
	EndIf;
	
	Query.Execute();
	
	Query.Text =
	"SELECT
	|	RoundingTable.Method AS Method,
	|	RoundingTable.Value AS Value
	|INTO RoundingTable
	|FROM
	|	&RoundingTable AS RoundingTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Operations.ProductionOrder AS Basis,
	|	Operations.ProductionOrder AS ProductionOrder,
	|	Operations.Company AS Company,
	|	Operations.StructuralUnit AS StructuralUnit,
	|	Operations.Performer AS Performer,
	|	Operations.ClosingDate AS ClosingDate,
	|	Operations.Period AS Period,
	|	Operations.CustomerOrder AS CustomerOrder,
	|	Operations.LineNumber AS LineNumber,
	|	Operations.ConnectionKey AS ConnectionKey,
	|	Operations.ProductsAndServices AS ProductsAndServices,
	|	Operations.Characteristic AS Characteristic,
	|	Operations.Quantity AS QuantityPlan,
	|	Operations.Specification AS Specification,
	|	Operations.Batch AS Batch,
	|	Operations.Operation AS Operation,
	|	Operations.Stage AS Stage,
	|	Operations.CompletiveStageDepartment AS CompletiveStageDepartment,
	|	Operations.FixedCost AS FixedCost,
	|	Operations.Factor AS Factor,
	|	Operations.MeasurementUnit AS MeasurementUnit,
	|	Operations.TimeNorm AS TimeNorm,
	|	(CAST(ISNULL(ProductsAndServicesSliceLast.Price / ISNULL(ProductsAndServicesSliceLast.MeasurementUnit.Factor, 1), 0) / ISNULL(RoundingTable.Value, 0.01) AS NUMBER(15, 0))) * ISNULL(RoundingTable.Value, 0.01) AS Tariff
	|FROM
	|	Operations AS Operations
	|		LEFT JOIN InformationRegister.ProductsAndServicesPrices.SliceLast(&Period, PriceKind = VALUE(Catalog.PriceKinds.Accounting)) AS ProductsAndServicesSliceLast
	|			LEFT JOIN RoundingTable AS RoundingTable
	|			ON ProductsAndServicesSliceLast.PriceKind.RoundingOrder = RoundingTable.Method
	|		ON Operations.Operation = ProductsAndServicesSliceLast.ProductsAndServices
	|
	|ORDER BY
	|	Operations.ProductionOrder,
	|	Operations.LineNumber,
	|	Operations.Level,
	|	Operations.Order,
	|	Operations.OperationLinenumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrderBalances.ProductionOrder AS Basis,
	|	OrderBalances.ProductsAndServices AS ProductsAndServices,
	|	OrderBalances.Characteristic AS Characteristic,
	|	OrderBalances.Operation AS Operation,
	|	OrderBalances.Stage AS Stage,
	|	SUM(OrderBalances.QuantityBalance) AS Balance
	|FROM
	|	(SELECT
	|		Operations.ProductionOrder AS ProductionOrder,
	|		Operations.ProductsAndServices AS ProductsAndServices,
	|		Operations.Characteristic AS Characteristic,
	|		Operations.Operation AS Operation,
	|		Operations.Stage AS Stage,
	|		Operations.Quantity * Operations.Factor AS QuantityBalance
	|	FROM
	|		Operations AS Operations
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		JobSheets.ProductionDocument,
	|		JobSheets.ProductsAndServices,
	|		JobSheets.Characteristic,
	|		JobSheets.Operation,
	|		JobSheets.Stage,
	|		-JobSheets.QuantityFactTurnover
	|	FROM
	|		AccumulationRegister.JobSheets.Turnovers(, , Auto, ProductionDocument IN (&OrderArray)) AS JobSheets
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentJibSheetRegisters.ProductionDocument,
	|		DocumentJibSheetRegisters.ProductsAndServices,
	|		DocumentJibSheetRegisters.Characteristic,
	|		DocumentJibSheetRegisters.Operation,
	|		DocumentJibSheetRegisters.Stage,
	|		DocumentJibSheetRegisters.QuantityFact
	|	FROM
	|		AccumulationRegister.JobSheets AS DocumentJibSheetRegisters
	|	WHERE
	|		DocumentJibSheetRegisters.Recorder = &Ref
	|		AND DocumentJibSheetRegisters.ProductionDocument IN(&OrderArray)) AS OrderBalances
	|
	|GROUP BY
	|	OrderBalances.ProductionOrder,
	|	OrderBalances.ProductsAndServices,
	|	OrderBalances.Characteristic,
	|	OrderBalances.Operation,
	|	OrderBalances.Stage";
	
	ResultsArray = Query.ExecuteBatch();
	BalanceTable = ResultsArray[2].Unload();
	Selection = ResultsArray[1].Select();
	
	ConnectionKeysMap = New Map;
	FillOperations(Selection, BalanceTable, Closed, ConnectionKeysMap);
	
	FillTeamMembersByProductionOrder(OrderArray, ConnectionKeysMap);
	
	ClosingDate = '0001-01-01';
	If Closed Then
		For Each TabSecRow In Operations Do
			ClosingDate = Max(ClosingDate, TabSecRow.Period);
		EndDo; 
	EndIf; 
	
EndProcedure

Procedure FillOperations(DataSelection, BalanceTable, FillFactQuantity = False, ConnectionKeysMap = Undefined)
	
	SaveConnectionKey = (DataSelection.Owner().Columns.Find("ConnectionKey")<>Undefined);
	If SaveConnectionKey Or TypeOf(ConnectionKeysMap)<>Type("Map") Then
		ConnectionKeysMap = New Map;
	EndIf;
	
	BasisExist = (BalanceTable.Columns.Find("Basis")<>Undefined);
	ExistStage = (BalanceTable.Columns.Find("Stage")<>Undefined);
	
	Operations.Clear();
	ConnectionKey = 0;
	If BalanceTable.Count() > 0 And DataSelection.Count() > 0 Then
		
		CommonBalancesTable = BalanceTable.Copy();
		CommonBalancesTable.GroupBy("ProductsAndServices, Characteristic", "Balance");
		CommonBalancesTable.Indexes.Add("ProductsAndServices,Characteristic");
		BalanceTable.Indexes.Add("ProductsAndServices,Characteristic,Operation");
		
		While DataSelection.Next() Do
			
			SearchFilter = New Structure;
			SearchFilter.Insert("ProductsAndServices", DataSelection.ProductsAndServices);
			SearchFilter.Insert("Characteristic", DataSelection.Characteristic);
			
			CommonBalancesArray = CommonBalancesTable.FindRows(SearchFilter);
			If CommonBalancesArray.Count() = 0 Then
				Continue;
			EndIf;
			TotalBalance = CommonBalancesArray[0].Balance;
			
			SearchFilter.Insert("Operation", DataSelection.Operation);
			If ExistStage Then
				SearchFilter.Insert("Stage", DataSelection.Stage);
			EndIf; 
			If BasisExist Then
				SearchFilter.Insert("Basis", DataSelection.Basis);
			EndIf; 
			
			BalancesArray = BalanceTable.FindRows(SearchFilter);
			Balance = ?(BalancesArray.Count()=0, 0, BalancesArray[0].Balance);
			
			QuantituToWriteOf = DataSelection.QuantityPlan * DataSelection.Factor;
			AvailableWriteOf = Min(TotalBalance, Balance);
			If Not ValueIsFilled(DataSelection.Specification) Then
				// Строки с незаполненной спецификацией не контролируются
				AvailableWriteOf = QuantituToWriteOf;
			EndIf; 
			WriteOff = Min(AvailableWriteOf, QuantituToWriteOf);
			If WriteOff <= 0 Then
				Continue;
			EndIf; 
			
			ConnectionKey = ConnectionKey+1;
			NewRow = Operations.Add();
			FillPropertyValues(NewRow, DataSelection);
			If Not Constants.FunctionalOptionInventoryReservation.Get() Then
				NewRow.CustomerOrder = Documents.CustomerOrder.EmptyRef();
			EndIf; 
			NewRow.ConnectionKey = ConnectionKey;
			If SaveConnectionKey And ValueIsFilled(DataSelection.ConnectionKey) Then
				If BasisExist Then
					If ConnectionKeysMap.Get(DataSelection.Basis)=Undefined Then
						ConnectionKeysMap.Insert(DataSelection.Basis, New Map)
					EndIf; 
					ConnectionKeysMap.Get(DataSelection.Basis).Insert(ConnectionKey, DataSelection.ConnectionKey);
				Else
					ConnectionKeysMap.Insert(ConnectionKey, DataSelection.ConnectionKey);
				EndIf; 
			EndIf; 
			
			NewRow.QuantityPlan = WriteOff / DataSelection.Factor;
			If FillFactQuantity Then
				NewRow.QuantityFact = NewRow.QuantityPlan;
				NewRow.StandardHours = NewRow.TimeNorm * NewRow.QuantityFact;
				If Not DataSelection.FixedCost Then
					NewRow.Cost = NewRow.Tariff * NewRow.TimeNorm * NewRow.QuantityFact;
				Else
					NewRow.Cost = NewRow.Tariff * NewRow.QuantityFact;
				EndIf; 
			EndIf; 
			
			CommonBalancesArray[0].Balance = CommonBalancesArray[0].Balance - WriteOff;
			If CommonBalancesArray[0].Balance <= 0 Then
				CommonBalancesTable.Delete(CommonBalancesArray[0]);
			EndIf;
			If BalancesArray.Count()>0 Then
				BalancesArray[0].Balance = BalancesArray[0].Balance - WriteOff;
				If BalancesArray[0].Balance <= 0 Then
					BalanceTable.Delete(BalancesArray[0]);
				EndIf;
			EndIf; 
				
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure FillTeamMembersByProductionOrder(OrderArray, ConnectionKeysMap)
	
	TeamMembers.Clear();
	
	Teams = New Array;
	For Each TabSecRow In Operations Do
		If Not ValueIsFilled(TabSecRow.Performer) Or TypeOf(TabSecRow.Performer)<>Type("СправочникСсылка.Teams") Then
			Continue;
		EndIf;
		If Teams.Find(TabSecRow.Performer)<>Undefined Then
			Continue;
		EndIf;
		Teams.Add(TabSecRow.Performer);
	EndDo; 
	
	Query = New Query;
	Query.SetParameter("OrderArray", OrderArray);
	Query.SetParameter("PerformerPosition", PerformerPosition);
	Query.SetParameter("Teams", Teams);
	Query.SetParameter("Company", Company);
	Query.SetParameter("StructuralUnit", StructuralUnit);
	Query.Text =
	"SELECT
	|	ProductionOrderTeamMembers.Ref AS Ref,
	|	ProductionOrderTeamMembers.Employee AS Employee,
	|	ProductionOrderTeamMembers.LPR AS LPR,
	|	ProductionOrderTeamMembers.StructuralUnit AS StructuralUnit,
	|	ProductionOrderTeamMembers.ConnectionKey AS ConnectionKey
	|FROM
	|	Document.ProductionOrder.Brigade AS ProductionOrderTeamMembers
	|WHERE
	|	ProductionOrderTeamMembers.Ref IN(&OrderArray)
	|	AND ProductionOrderTeamMembers.Ref.PerformerPosition = VALUE(Enum.AttributePositionOnForm.InTabularSection)
	|	AND &PerformerPosition = VALUE(Enum.AttributePositionOnForm.InTabularSection)
	|	AND ProductionOrderTeamMembers.ConnectionKey <> 0
	|	AND ProductionOrderTeamMembers.Ref.OperationPlanned
	|
	|UNION ALL
	|
	|SELECT
	|	ProductionOrderTeamMembers.Ref,
	|	ProductionOrderTeamMembers.Employee,
	|	ProductionOrderTeamMembers.LPR,
	|	ProductionOrderTeamMembers.StructuralUnit,
	|	ProductionOrderOperations.ConnectionKey
	|FROM
	|	Document.ProductionOrder.Operations AS ProductionOrderOperations
	|		LEFT JOIN Document.ProductionOrder.Brigade AS ProductionOrderTeamMembers
	|		ON ProductionOrderOperations.Ref = ProductionOrderTeamMembers.Ref
	|WHERE
	|	ProductionOrderOperations.Ref IN(&OrderArray)
	|	AND ProductionOrderOperations.Ref.PerformerPosition <> VALUE(Enum.AttributePositionOnForm.InTabularSection)
	|	AND &PerformerPosition = VALUE(Enum.AttributePositionOnForm.InTabularSection)
	|	AND ProductionOrderOperations.Ref.Performer REFS Catalog.Teams
	|	AND ProductionOrderOperations.ConnectionKey <> 0
	|	AND ProductionOrderOperations.Ref.OperationPlanned
	|
	|UNION ALL
	|
	|SELECT
	|	ProductionOrderTeamMembers.Ref,
	|	ProductionOrderTeamMembers.Employee,
	|	ProductionOrderTeamMembers.LPR,
	|	ProductionOrderTeamMembers.StructuralUnit,
	|	0
	|FROM
	|	Document.ProductionOrder.Brigade AS ProductionOrderTeamMembers
	|WHERE
	|	ProductionOrderTeamMembers.Ref IN(&OrderArray)
	|	AND ProductionOrderTeamMembers.Ref.PerformerPosition <> VALUE(Enum.AttributePositionOnForm.InTabularSection)
	|	AND &PerformerPosition <> VALUE(Enum.AttributePositionOnForm.InTabularSection)
	|	AND ProductionOrderTeamMembers.Ref.Performer REFS Catalog.Teams
	|	AND ProductionOrderTeamMembers.ConnectionKey = 0
	|	AND ProductionOrderTeamMembers.Ref.OperationPlanned
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TeamsContent.Ref AS Ref,
	|	1 AS LPR,
	|	TeamsContent.Employee AS Employee,
	|	ISNULL(StaffSliceLast.StructuralUnit, &StructuralUnit) AS StructuralUnit
	|FROM
	|	Catalog.Teams.Content AS TeamsContent
	|		LEFT JOIN InformationRegister.Employees.SliceLast AS StaffSliceLast
	|		ON TeamsContent.Employee = StaffSliceLast.Employee
	|			AND (StaffSliceLast.Company = &Company)
	|WHERE
	|	TeamsContent.Ref IN(&Teams)
	|
	|ORDER BY
	|	Ref,
	|	TeamsContent.LineNumber";
	Result = Query.ExecuteBatch();
	
	ContentTable = Result[0].Unload();
	StandardContentTable = Result[1].Unload();
	
	// Состав шапки
	For Each TabSecRow In ContentTable Do
		If ValueIsFilled(TabSecRow.ConnectionKey) Then
			Continue;
		EndIf;
		NewRow = TeamMembers.Add();
		FillPropertyValues(NewRow, TabSecRow);
	EndDo; 
	
	// Состав ТЧ
	For Each TabSecRow In Operations Do
		If Not ValueIsFilled(TabSecRow.ConnectionKey)
			Or Not ValueIsFilled(TabSecRow.Performer)
			Or TypeOf(TabSecRow.Performer)<>Type("СправочникСсылка.Teams") Then
			Continue;
		EndIf;
		If ConnectionKeysMap.Get(TabSecRow.ProductionOrder)=Undefined Then
			ConnectionKeysMap.Insert(TabSecRow.ProductionOrder, New Map)
		EndIf; 
		OldConnectionKey = ConnectionKeysMap.Get(TabSecRow.ProductionOrder).Get(TabSecRow.ConnectionKey);
		If Not ValueIsFilled(OldConnectionKey) Then
			ContentRows = New Array;
		Else
			FilterStructure = New Structure;
			FilterStructure.Insert("ConnectionKey", OldConnectionKey);
			FilterStructure.Insert("Ref", TabSecRow.ProductionOrder);
			ContentRows = ContentTable.FindRows(FilterStructure);
		EndIf;
		If ContentRows.Count()=0 Then
			FilterStructure = New Structure;
			FilterStructure.Insert("Ref", TabSecRow.Performer);
			ContentRows = StandardContentTable.FindRows(FilterStructure);
		EndIf; 
		For Each ContentRow In ContentRows Do
			NewRow = TeamMembers.Add();
			FillPropertyValues(NewRow, ContentRow);
			NewRow.ConnectionKey = TabSecRow.ConnectionKey;
			If Not ValueIsFilled(NewRow.StructuralUnit) Then
				NewRow.StructuralUnit = TabSecRow.StructuralUnit;
			EndIf; 
		EndDo; 
	EndDo;  
	
EndProcedure

Procedure FillByProductionOrderDisassembly(OrderArray)
	
	Query = New Query;
	Query.SetParameter("OrderArray", OrderArray);
	Query.Text =
	"SELECT TOP 1
	|	ProductionOrder.Company AS Company,
	|	ProductionOrder.StructuralUnitOperation AS StructuralUnit,
	|	ProductionOrder.Performer AS Performer,
	|	ProductionOrder.OperationPlanned AS OperationPlanned,
	|	MAX(ProductionOrder.Finish) AS Finish,
	|	ProductionOrder.PerformerPosition AS PerformerPosition,
	|	ProductionOrder.StructuralUnitOperationPosition AS StructuralUnitPosition
	|FROM
	|	Document.ProductionOrder AS ProductionOrder
	|WHERE
	|	ProductionOrder.Ref IN(&OrderArray)
	|
	|GROUP BY
	|	ProductionOrder.Company,
	|	ProductionOrder.StructuralUnitOperation,
	|	ProductionOrder.Performer,
	|	ProductionOrder.OperationPlanned,
	|	ProductionOrder.PerformerPosition,
	|	ProductionOrder.StructuralUnitOperationPosition";
	HeaderSelection = Query.Execute().Select();
	HeaderSelection.Next();
	Period = ?(ValueIsFilled(HeaderSelection.Finish), HeaderSelection.Finish, CurrentSessionDate());
	
	FillPropertyValues(ThisObject, HeaderSelection, "Company" + ?(OrderArray.Count()=1, ", StructuralUnit, Performer, PerformerPosition, StructuralUnitPosition", ""));
	
	DocumentCurrency = Catalogs.PriceKinds.Accounting.PriceCurrency;
	
	TableContent = EmptyContentTable();
	
	FillContentTable("ProductionOrder", OrderArray, TableContent);
	
	CurSpecification = Undefined;
	LineNumber = 0;
	TableContent.Sort("BaseSpecification");
	For Each ContentRow In TableContent Do
		If ContentRow.BaseSpecification<>CurSpecification Then
			LineNumber = 0;
			CurSpecification = ContentRow.BaseSpecification;
		EndIf;
		LineNumber = LineNumber+1;
		ContentRow.LineNumber = LineNumber;
	EndDo; 
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("TableContent", TableContent);
	Query.SetParameter("OrderArray", OrderArray);
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Period", Period);
	
	If HeaderSelection.ЗапланированыOperations Then
		
		Closed = True;
		
		Query.Text =
		"SELECT
		|	ProductionOrderOperations.Ref AS ProductionOrder,
		|	ProductionOrderOperations.Ref.Company AS Company,
		|	ProductionOrderOperations.StructuralUnit AS StructuralUnit,
		|	ProductionOrderOperations.Ref.Finish AS ClosingDate,
		|	&Period AS Period,
		|	ProductionOrderOperations.CustomerOrder AS CustomerOrder,
		|	ProductionOrderOperations.LineNumber AS LineNumber,
		|	ProductionOrderProducts.ProductsAndServices AS ProductsAndServices,
		|	ProductionOrderProducts.Characteristic AS Characteristic,
		|	ProductionOrderOperations.QuantityPlan AS Quantity,
		|	ProductionOrderProducts.Specification AS Specification,
		|	ProductionOrderProducts.Batch AS Batch,
		|	ProductionOrderOperations.Operation AS Operation,
		|	ProductionOrderOperations.MeasurementUnt AS MeasurementUnt,
		|	CASE
		|		WHEN ProductionOrderOperations.Operation REFS Catalog.ProductsAndServices
		|				AND ProductionOrderOperations.Operation <> VALUE(Catalog.ProductsAndServices.EmptyRef)
		|			THEN ProductionOrderOperations.Operation.FixedCost
		|		ELSE TRUE
		|	END AS FixedCost,
		|	CASE
		|		WHEN VALUETYPE(ProductionOrderOperations.MeasurementUnt) = TYPE(Catalog.КлассификаторЕдиницИзмерения)
		|			THEN 1
		|		ELSE ProductionOrderOperations.MeasurementUnt.Factor
		|	END AS Factor,
		|	ProductionOrderOperations.TimeRate AS TimeRate,
		|	ProductionOrderOperations.ConectionKey AS ConectionKey,
		|	ProductionOrderOperations.Perfomer AS Perfomer,
		|	ProductionOrderOperations.LineNumber AS LineNumberOperations
		|INTO Operations
		|FROM
		|	Document.ProductionOrder.Operations AS ProductionOrderOperations
		|		LEFT JOIN Document.ProductionOrder.Products AS ProductionOrderProducts
		|		ON ProductionOrderOperations.ConnectionKeyProduct = ProductionOrderProducts.ConectionKey
		|			AND ProductionOrderOperations.Ref = ProductionOrderProducts.REFS
		|WHERE
		|	ProductionOrderOperations.Ref IN(&OrderArray)";
		
	Else
		
		Query.Text = 
		"SELECT
		|	ProductionOrderProduction.Ref AS ProductionOrder,
		|	ProductionOrderProduction.Ref.Company AS Company,
		|	ProductionOrderProduction.StructuralUnit AS StructuralUnit,
		|	ProductionOrderProduction.Ref.Finish AS ClosingDate,
		|	&Period AS Period,
		|	ProductionOrderProduction. .CustomerOrder AS CustomerOrder,
		|	ProductionOrderProduction.LineNumber AS LineNumber,
		|	ProductionOrderProduction.ProductsAndServices AS ProductsAndServices,
		|	ProductionOrderProduction.Characteristic AS Characteristic,
		|	1 AS Factor,
		|	ProductionOrderProduction.Quantity * CASE
		|		WHEN VALUETYPE(ProductionOrderProduction.MeasurementUnit) = TYPE(Catalog.UOM)
		|		AND ProductionOrderProduction.MeasurementUnit <> VALUE(Catalog.UOM.EmptyRef)
		|			THEN ProductionOrderProduction.MeasurementUnit.Factor
		|		ELSE 1
		|	END AS Quantity,
		|	ProductionOrderProduction.Specification AS Specification,
		|	ProductionOrderProduction.Batch AS Batch,
		|	SpecificationsOperations.Operation AS Operation,
		|	CASE
		|		WHEN SpecificationsOperations.Operation REFS Catalog.ProductsAndServices
		|		AND SpecificationsOperations.Operation <> VALUE(Catalog.ProductsAndServices.EmptyRef)
		|			THEN SpecificationsOperations.Operation.FixedCost
		|		ELSE TRUE
		|	END AS FixedCost,
		|	SpecificationsOperations.Operation.MeasurementUnit AS MeasurementUnit,
		|	ISNULL(SpecificationsOperations.TimeNorm, 0) / ISNULL(SpecificationsOperations.ProductsQuantity, 1) AS TimeNorm,
		|	0 AS ConnectionKey,
		|	VALUE(Catalog.Teams.EmptyRef) AS Perfomer,
		|	SpecificationsOperations.LineNumber AS LineNumberOperations
		|INTO Operations
		|FROM
		|	Document.ProductionOrder.Products AS ProductionOrderProduction
		|		LEFT JOIN Catalog.Specifications.Operations AS SpecificationsOperations
		|		ON ProductionOrderProduction.Specification = SpecificationsOperations.REFS
		|WHERE
		|	ProductionOrderProduction.Ref IN (&OrderArray)
		|	AND ProductionOrderProduction.ProductsAndServices.ProductsAndServicesType IN
		|		(VALUE(Enum.ProductsAndServicesTypes.InventoryItem), VALUE(Enum.ProductsAndServicesTypes.Work))";
		
	EndIf;
	
	Query.Execute();
	
	Selection = GetSelectionOperationDisassembly(Query);
	
	Query.Text =
	"SELECT
	|	OrderBalances.ProductionOrder AS Basis,
	|	OrderBalances.ProductsAndServices AS ProductsAndServices,
	|	OrderBalances.Characteristic AS Characteristic,
	|	OrderBalances.Operation AS Operation,
	|	SUM(OrderBalances.QuantityBalance) AS Balance
	|FROM
	|	(SELECT
	|		OperationAndContent.ProductionOrder AS ProductionOrder,
	|		OperationAndContent.ProductsAndServices AS ProductsAndServices,
	|		OperationAndContent.Characteristic AS Characteristic,
	|		OperationAndContent.Operation AS Operation,
	|		OperationAndContent.Quantity * OperationAndContent.Factor AS QuantityBalance
	|	FROM
	|		OperationAndContent AS OperationAndContent
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		JobSheets.ProductionDocument,
	|		JobSheets.ProductsAndServices,
	|		JobSheets.CHARACTERISTIC,
	|		JobSheets.Operation,
	|		-JobSheets.QuantityФактОборот
	|	FROM
	|		AccumulationRegister.JobSheets.Turnovers(, , Auto, ProductionDocument IN (&DocsArray)) AS JobSheets
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentJibSheetRegisters.ProductionDocument,
	|		DocumentJibSheetRegisters.ProductsAndServices,
	|		DocumentJibSheetRegisters.CHARACTERISTIC,
	|		DocumentJibSheetRegisters.Operation,
	|		DocumentJibSheetRegisters.QuantityFact
	|	FROM
	|		AccumulationRegister.JobSheets AS DocumentJibSheetRegisters
	|	WHERE
	|		DocumentJibSheetRegisters.Recorder = &Ref
	|		AND DocumentJibSheetRegisters.ProductionDocument IN(&DocsArray)) AS OrderBalances
	|
	|GROUP BY
	|	OrderBalances.ProductionOrder,
	|	OrderBalances.ProductsAndServices,
	|	OrderBalances.Characteristic,
	|	OrderBalances.Operation";
	BalanceTable = Query.Execute().Unload();
	
	ConnectionKeysMap = New Map;
	FillOperations(Selection, BalanceTable, Closed, ConnectionKeysMap);
	
	FillTeamMembersByProductionOrder(OrderArray, ConnectionKeysMap);
	
	ClosingDate = '0001-01-01';
	If Closed Then
		For Each TabSecRow In Operations Do
			ClosingDate = Max(ClosingDate, TabSecRow.Period);
		EndDo; 
	EndIf; 
	
EndProcedure


////////////////////////////////////////////////////////////////////////////////
// EVENT HANDLERS

// IN the event handler of the FillingProcessor document
// - document filling by inventory reconciliation in the warehouse.
//
Procedure Filling(FillingData, StandardProcessing) Export
	
	If Not ValueIsFilled(FillingData) Then
		Return;
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		FillPropertyValues(ThisObject, FillingData);
		
		If FillingData.Property("Operations") Then
			For Each StringOperations IN FillingData.Operations Do
				NewRow = Operations.Add();
				FillPropertyValues(NewRow, StringOperations);
			EndDo;
		EndIf;
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.CustomerOrder") Then
		
		FillUsingCustomerOrder(FillingData);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.ProductionOrder") Then
		
		FillByProductionOrder(FillingData);
		
		//If FillingData.StructuralUnit.StructuralUnitType = Enums.StructuralUnitsTypes.Warehouse Then
		//	
		//	Raise NStr("en='Cannot enter job sheet based on the production order by warehouse.';ru='Сдельный наряд не может быть введен на основании заказа на производство по складу!';vi='Công khoán không thể nhập trên cơ sở đơn hàng sản xuất theo kho!'");
		//	
		//ElsIf FillingData.OperationKind = Enums.OperationKindsProductionOrder.Assembly Then
		//	
		//	Query = New Query;
		//	Query.Text =
		//	"SELECT
		//	|	OrderForProductsProduction.Ref.Company AS Company,
		//	|	OrderForProductsProduction.Ref.StructuralUnit AS StructuralUnit,
		//	|	OrderForProductsProduction.Ref.Finish AS ClosingDate,
		//	|	&Period AS Period,
		//	|	OrderForProductsProduction.Ref.CustomerOrder AS CustomerOrder,
		//	|	OrderForProductsProduction.ProductsAndServices AS ProductsAndServices,
		//	|	OrderForProductsProduction.Characteristic AS Characteristic,
		//	|	OrderForProductsProduction.Quantity AS QuantityPlan,
		//	|	OrderForProductsProduction.Specification AS Specification,
		//	|	OperationSpecification.Operation,
		//	|	OperationSpecification.Operation.MeasurementUnit AS MeasurementUnit,
		//	|	ISNULL(OperationSpecification.TimeNorm, 0) / ISNULL(OperationSpecification.ProductsQuantity, 1) * CASE
		//	|		WHEN VALUETYPE(OrderForProductsProduction.MeasurementUnit) = Type(Catalog.UOM)
		//	|				AND OrderForProductsProduction.MeasurementUnit <> VALUE(Catalog.UOM.EmptyRef)
		//	|			THEN OrderForProductsProduction.MeasurementUnit.Factor
		//	|		ELSE 1
		//	|	END AS TimeNorm,
		//	|	ISNULL(ProductsAndServicesPricesSliceLast.Price / ISNULL(ProductsAndServicesPricesSliceLast.MeasurementUnit.Factor, 1), 0) AS Tariff
		//	|FROM
		//	|	Document.ProductionOrder.Products AS OrderForProductsProduction
		//	|		LEFT JOIN Catalog.Specifications.Operations AS OperationSpecification
		//	|			LEFT JOIN InformationRegister.ProductsAndServicesPrices.SliceLast(&Period, PriceKind = VALUE(Catalog.PriceKinds.Accounting)) AS ProductsAndServicesPricesSliceLast
		//	|			ON OperationSpecification.Operation = ProductsAndServicesPricesSliceLast.ProductsAndServices
		//	|		ON OrderForProductsProduction.Specification = OperationSpecification.Ref
		//	|WHERE
		//	|	OrderForProductsProduction.Ref = &BasisDocument";
		//	
		//	Query.SetParameter("BasisDocument", FillingData);
		//	Query.SetParameter("Period", ?(ValueIsFilled(FillingData.Start), FillingData.Start, CurrentDate()));
		//	
		//	QueryResult = Query.Execute();
		//	If Not QueryResult.IsEmpty() Then
		//		
		//		QueryResultSelection = QueryResult.Select();
		//		QueryResultSelection.Next();
		//		FillPropertyValues(ThisObject, QueryResultSelection);
		//		ThisObject.DocumentCurrency = Catalogs.PriceKinds.Accounting.PriceCurrency;
		//		
		//		QueryResultSelection.Reset();
		//		Operations.Clear();
		//		While QueryResultSelection.Next() Do
		//			NewRow = Operations.Add();
		//			FillPropertyValues(NewRow, QueryResultSelection);
		//		EndDo;
		//		
		//	EndIf
		//	
		//Else
		//	
		//	TableContent = New ValueTable;
		//	
		//	Array = New Array;
		//	
		//	Array.Add(Type("CatalogRef.ProductsAndServices"));
		//	TypeDescription = New TypeDescription(Array, ,);
		//	Array.Clear();
		//	TableContent.Columns.Add("ProductsAndServices", TypeDescription);
		//	
		//	Array.Add(Type("CatalogRef.ProductsAndServicesCharacteristics"));
		//	TypeDescription = New TypeDescription(Array, ,);
		//	Array.Clear();
		//	TableContent.Columns.Add("Characteristic", TypeDescription);
		//	
		//	Array.Add(Type("CatalogRef.Specifications"));
		//	TypeDescription = New TypeDescription(Array, ,);
		//	Array.Clear();
		//	TableContent.Columns.Add("Specification", TypeDescription);
		//	
		//	Array.Add(Type("Number"));
		//	TypeDescription = New TypeDescription(Array, ,);
		//	TableContent.Columns.Add("Quantity", TypeDescription);
		//	
		//	Array.Add(Type("Number"));
		//	TypeDescription = New TypeDescription(Array, ,);
		//	TableContent.Columns.Add("CostPercentage", TypeDescription);
		//	
		//	Query = New Query;
		//	Query.Text =
		//	"SELECT
		//	|	&Period AS Period,
		//	|	OrderForProductsProduction.Ref.Company AS Company,
		//	|	OrderForProductsProduction.Ref.StructuralUnit AS StructuralUnit,
		//	|	OrderForProductsProduction.Ref.Finish AS ClosingDate,
		//	|	OrderForProductsProduction.Ref.CustomerOrder AS CustomerOrder,
		//	|	OrderForProductsProduction.ProductsAndServices AS ProductsAndServices,
		//	|	OrderForProductsProduction.Characteristic AS Characteristic,
		//	|	OrderForProductsProduction.MeasurementUnit AS MeasurementUnit,
		//	|	OrderForProductsProduction.Quantity AS Quantity,
		//	|	OrderForProductsProduction.Specification AS Specification,
		//	|	OperationSpecification.Operation AS Operation,
		//	|	OperationSpecification.Operation.MeasurementUnit AS OperationMeasurementUnit,
		//	|	ISNULL(OperationSpecification.TimeNorm, 0) / ISNULL(OperationSpecification.ProductsQuantity, 1) * CASE
		//	|		WHEN VALUETYPE(OrderForProductsProduction.MeasurementUnit) = Type(Catalog.UOM)
		//	|				AND OrderForProductsProduction.MeasurementUnit <> VALUE(Catalog.UOM.EmptyRef)
		//	|			THEN OrderForProductsProduction.MeasurementUnit.Factor
		//	|		ELSE 1
		//	|	END AS TimeNorm,
		//	|	ISNULL(ProductsAndServicesPricesSliceLast.Price / ISNULL(ProductsAndServicesPricesSliceLast.MeasurementUnit.Factor, 1), 0) AS Tariff
		//	|FROM
		//	|	Document.ProductionOrder.Products AS OrderForProductsProduction
		//	|		LEFT JOIN Catalog.Specifications.Operations AS OperationSpecification
		//	|			LEFT JOIN InformationRegister.ProductsAndServicesPrices.SliceLast(&Period, PriceKind = VALUE(Catalog.PriceKinds.Accounting)) AS ProductsAndServicesPricesSliceLast
		//	|			ON OperationSpecification.Operation = ProductsAndServicesPricesSliceLast.ProductsAndServices
		//	|		ON OrderForProductsProduction.Specification = OperationSpecification.Ref
		//	|WHERE
		//	|	OrderForProductsProduction.Ref = &BasisDocument";
		//	
		//	Query.SetParameter("BasisDocument", FillingData);
		//	Query.SetParameter("Period", ?(ValueIsFilled(FillingData.Start), FillingData.Start, CurrentDate()));
		//	
		//	QueryResult = Query.Execute();
		//	If Not QueryResult.IsEmpty() Then
		//		
		//		Selection = QueryResult.Select();
		//		Selection.Next();
		//		FillPropertyValues(ThisObject, Selection);
		//		ThisObject.DocumentCurrency = Catalogs.PriceKinds.Accounting.PriceCurrency;
		//		
		//		Selection.Reset();
		//		While Selection.Next() Do
		//			
		//			TableContent.Clear();
		//			FillTableBySpecification(Selection.Specification, Selection.MeasurementUnit, Selection.Quantity, TableContent);
		//			TotalCostPercentage = TableContent.Total("CostPercentage");
		//			
		//			LeftToDistribute = Selection.TimeNorm;
		//			
		//			NewRow = Undefined;
		//			For Each TableRow IN TableContent Do
		//			
		//				NewRow = Operations.Add();
		//				NewRow.Period = Selection.Period;
		//				NewRow.CustomerOrder = Selection.CustomerOrder;
		//				NewRow.ProductsAndServices = TableRow.ProductsAndServices;
		//				NewRow.Characteristic = TableRow.Characteristic;
		//				NewRow.Operation = Selection.Operation;
		//				NewRow.MeasurementUnit = Selection.OperationMeasurementUnit;
		//				NewRow.QuantityPlan = TableRow.Quantity;
		//				NewRow.Tariff = Selection.Tariff;
		//				NewRow.Specification = Selection.Specification;
		//				
		//				TimeNorm = Round(Selection.TimeNorm * TableRow.CostPercentage / ?(TotalCostPercentage = 0, 1, TotalCostPercentage),3,0);
		//				NewRow.TimeNorm = TimeNorm;
		//				LeftToDistribute = LeftToDistribute - TimeNorm;
		//				
		//			EndDo;
		//			
		//			If NewRow <> Undefined Then
		//				NewRow.TimeNorm = NewRow.TimeNorm + LeftToDistribute;
		//			EndIf;
		//			
		//		EndDo;
		//		
		//	Else
		//		Return;
		//	EndIf;
			
		//EndIf;
		
	EndIf;
	
EndProcedure // FillingProcessor()

// Procedure - event handler FillCheckProcessing object.
//
Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	
	CheckedAttributes.Clear();
	Return;
	
	If DataExchange.Load Then
	
		Return;
		
	EndIf;
	
	If Closed Then
		
		CheckedAttributes.Add("ClosingDate");
	
	EndIf;
		
EndProcedure

// Procedure - event handler BeforeWrite object.
//
Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If ProductionOrderPosition = Enums.AttributePositionOnForm.InTabularSection Then
		ProductionOrder = HeaderProductionOrder();
	Else
		For Each TabSecRow In Operations Do
			TabSecRow.ProductionOrder = ProductionOrder;
		EndDo; 
	EndIf;
	
	If StructuralUnitPosition = Enums.AttributePositionOnForm.InTabularSection Then
		StructuralUnit = HeaderStructuralUnit();
	Else
		For Each TabSecRow In Operations Do
			TabSecRow.StructuralUnit = StructuralUnit;
		EndDo; 
		For Each TabSecRow In TeamMembers Do
			TabSecRow.StructuralUnit = StructuralUnit;
		EndDo; 
	EndIf; 
	
	DocumentAmount = Operations.Total("Cost");
	
	UpdateDescriptions();
	
EndProcedure // BeforeWrite()

// Procedure - event handler FillingProcessor object.
//
Procedure Posting(Cancel, PostingMode)

	// Initialization of additional properties for document posting
	SmallBusinessServer.InitializeAdditionalPropertiesForPosting(Ref, AdditionalProperties);
	
	// Initialization of document data
	Documents.JobSheet.InitializeDocumentData(Ref, AdditionalProperties);
	
	// Preparation of record sets
	SmallBusinessServer.PrepareRecordSetsForRecording(ThisObject);
	
	// Registering in accounting sections
	SmallBusinessServer.ReflectAccrualsAndDeductions(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectPayrollPayments(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectInventory(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectJobSheets(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectManagerial(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectProductionStages(AdditionalProperties, RegisterRecords, Cancel);

	// Writing of record sets
	SmallBusinessServer.WriteRecordSets(ThisObject);
	
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
	
EndProcedure // UndoPosting()

#Region ServiceMethods

Function EmptyContentTable()
	
	TableContent = New ValueTable;
	
	TableContent.Columns.Add("BaseSpecification", New TypeDescription("СправочникСсылка.Specifications"));
	TableContent.Columns.Add("LineNumber", New TypeDescription("Number"));
	TableContent.Columns.Add("ProductsAndServices", New TypeDescription("СправочникСсылка.ProductsAndServices"));
	TableContent.Columns.Add("Characteristic", New TypeDescription("СправочникСсылка.ProductsAndServicesCharacteristics"));
	TableContent.Columns.Add("Specification", New TypeDescription("СправочникСсылка.Specifications"));
	TableContent.Columns.Add("Quantity", New TypeDescription("Number"));
	TableContent.Columns.Add("CostPercentage", New TypeDescription("Number"));
	
	Return TableContent;
	
EndFunction

Procedure CheckProductionStagesFilling(Cancel, UndoPosting = False)
	
	If Not GetFunctionalOption("ИспользоватьЭтапыПроизводства") Then
		Return;
	EndIf;
	
	// Формирование таблицы продукции, использующей этапы производства
	ColumnsName = "LineNumber, ProductsAndServices, Characteristic, Batch, Specification, CustomerOrder, ProductionOrder, Stage, CompletiveStageDepartment, QuantityFact";
	If UndoPosting Then
		ProductsTable = Operations.UnloadColumns(ColumnsName);
	Else
		ProductsTable = Operations.Unload(, ColumnsName);
	EndIf; 
	ProductsTable.Columns.Add("TSName", New TypeDescription("Row", New StringQualifiers(100)));
	ProductsTable.FillValues("Operations", "TSName");
	ProductsTable.Columns.QuantityFact.Name = "Quantity";
	If ProductionOrderPosition <> Enums.AttributePositionOnForm.InTabularSection Then
		ProductsTable.FillValues(ProductionOrder, "ProductionOrder");
	EndIf;
	SpecsArray = New Array;
	For Each TabSecRow In ProductsTable Do
		If Not ValueIsFilled(TabSecRow.Specification) Then
			Continue;
		EndIf;
		If Not ValueIsFilled(TabSecRow.ProductionOrder) And Not ValueIsFilled(TabSecRow.CustomerOrder) Then
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
		If ValueIsFilled(TabSecRow.ProductionOrder) 
			And CommonUse.ObjectAttributeValue(TabSecRow.ProductionOrder, "OperationKind")= Enums.OperationKindsProductionOrder.Disassembly Then
			// Разборка не может выполняться поэтапно
			Continue;
		EndIf; 
		FillPropertyValues(CheckingProducts.Add(), ProductsRow);
		If Not ValueIsFilled(ProductsRow.Stage) Then
			SmallBusinessServer.ShowMessageAboutError(
			ThisObject,
			StrTemplate(NStr("En='null';vi='không'"), ProductsRow.LineNumber),
			"Operations",
			ProductsRow.LineNumber,
			"Stage",
			Cancel);
		EndIf; 
	EndDo;
	
	If GetFunctionalOption("PerformStagesByDifferentDepartments") Then
		For Each ProductsRow In CheckingProducts Do
			If Not ValueIsFilled(ProductsRow.CompletiveStageDepartment) Then
				SmallBusinessServer.ShowMessageAboutError(
				ThisObject,
				StrTemplate(NStr("en = 'The column ""Completive stage department"" is not filled in line %1 of ""Products""'; vi = 'Cột ""Bộ phận hoàn thành công đoạn"" không được điền vào dòng %1 của phần bảng ""Hàng hóa""'"), ProductsRow.LineNumber),
				"Products",
				ProductsRow.LineNumber,
				"CompletiveStageDepartment",
				Cancel);
			EndIf; 
		EndDo; 
	EndIf; 
	
	// Проверка уникальности завершающего подразделения
	ProductionServer.StageProductionCheck(ThisObject, CheckingProducts, Cancel);
	
EndProcedure

Procedure AddProductionOrderOperationTable(Query, ProductionOrder)
	
	Query.SetParameter("ProductionOrder", ProductionOrder);
	Query.Text =
	"SELECT
	|	1 AS Level,
	|	1 AS Ord,
	|	Operations.LineNumber AS LineNumber,
	|	Operations.Stage AS Stage,
	|	Products.Specification AS Specification,
	|	UNDEFINED AS NestedSpecification,
	|	FALSE AS ItNode,
	|	Operations.Operation AS Operation,
	|	Operations.TimeRate AS TimeRate,
	|	Operations.Perfomer AS Perfomer
	|INTO OperationTable
	|FROM
	|	Document.ProductionOrder.Operations AS Operations
	|		LEFT JOIN (SELECT
	|			Products.Specification AS Specification,
	|			MIN(Products.ConectionKey) AS ConectionKey
	|		FROM
	|			Document.ProductionOrder.Products AS Products
	|		WHERE
	|			Products.REFS = &ProductionOrder
	|		
	|		GROUP BY
	|			Products.Specification) AS Products
	|		ON Operations.ConnectionKeyProduct = Products.ConectionKey
	|WHERE
	|	Operations.Ref = &ProductionOrder
	|	AND NOT Products.ConectionKey IS NULL";
	Query.Execute();
	
EndProcedure
 
#EndRegion

Procedure FillContentTable(DocName, DocsArray, ContentTable)
	
	Query = New Query;
	Query.SetParameter("DocsArray", DocsArray);
	Query.Text =
	"SELECT
	|	Document.Ref AS Ref,
	|	Document.BasisDocument AS ProductionOrder,
	|	Document.ManualDistribution AS ManualDistribution,
	|	Document.Products.(
	|		LineNumber AS LineNumber,
	|		ProductsAndServices AS ProductsAndServices,
	|		Characteristic AS Characteristic,
	|		Batch AS Batch,
	|		Quantity AS Quantity,
	|		Reserve AS Reserve,
	|		MeasurementUnit AS MeasurementUnit,
	|		ProductsAndServices.MeasurementUnit AS BaseUnit,
	|		CASE
	|			WHEN Document.Products.MeasurementUnit REFS Catalog.UOM
	|				THEN Document.Products.MeasurementUnit.Factor
	|			ELSE 1
	|		END AS Factor,
	|		Specification AS Specification,
	|		ConnectionKey AS ConnectionKey,
	|		StructuralUnit AS StructuralUnit,
	|		CustomerOrder AS CustomerOrder
	|	) AS Products,
	|	Document.Inventory.(
	|		LineNumber AS LineNumber,
	|		Stage AS Stage,
	|		ProductsAndServices AS ProductsAndServices,
	|		Characteristic AS Characteristic,
	|		Batch AS Batch,
	|		Quantity AS Quantity,
	|		Reserve AS Reserve,
	|		MeasurementUnit AS MeasurementUnit,
	|		Specification AS Specification,
	|		CASE
	|			WHEN Document.Inventory.CostPercentage = 0
	|				THEN 1
	|			ELSE Document.Inventory.CostPercentage
	|		END AS CostPercentage,
	|		ConnectionKey AS ConnectionKey,
	|		StructuralUnit AS StructuralUnit,
	|		CustomerOrder AS CustomerOrder
	|	) AS Inventory,
	|	Document.InventoryDistribution.(
	|		LineNumber AS LineNumber,
	|		Quantity AS Quantity,
	|		ConnectionKeyProduct AS ConnectionKeyProduct,
	|		Stage AS Stage,
	|		ProductsAndServices AS ProductsAndServices,
	|		Characteristic AS Characteristic,
	|		Batch AS Batch,
	|		MeasurementUnit AS MeasurementUnit,
	|		Specification AS Specification,
	|		StructuralUnit AS StructuralUnit,
	|		CustomerOrder AS CustomerOrder
	|	) AS InventoryDistribution
	|FROM
	|	Document.InventoryAssembly AS Document
	|WHERE
	|	Document.Ref IN(&DocsArray)";
	
	Query.Text = StrReplace(Query.Text, "Document.InventoryAssembly", "Document." + DocName);
	If DocName="ProductionOrder" Then
		Query.Text = StrReplace(Query.Text, "Document.BasisDocument AS ProductionOrder", "Document.Ref AS ProductionOrder");
	EndIf; 
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		ProductsTable = Selection.Products.Unload();
		InventoryTab = Selection.Inventory.Unload();
		If InventoryTab.Count()=0 Then
			For Each RowProduction In ProductsTable Do
				FillTableBySpecification(RowProduction.Specification, RowProduction.Specification, RowProduction.BaseUnit, 1, , ContentTable);
			EndDo;
			Continue;
		ElsIf TypeOf(Selection.Ref)=Type("DocumentRef.InventoryAssembly") Or Selection.ManualDistribution Then
			InventoryDistributionTable = Selection.InventoryDistribution.Unload();
		Else
			InventoryDistributionTable = Selection.InventoryDistribution.Unload().CopyColumns();
			ProductionServer.DistribInventory(ProductsTable, InventoryTab, InventoryDistributionTable, , Selection.ProductionOrder);
		EndIf;
		JoinInventoryAndDistribution(InventoryTab, InventoryDistributionTable);
		For Each RowProduction In ProductsTable Do
			FilterStructure = New Structure;
			FilterStructure.Insert("ConnectionKeyProduct", RowProduction.ConnectionKey);
			DistributionRows = InventoryDistributionTable.FindRows(FilterStructure);
			For Each DistrRow In DistributionRows Do
				NewRow = ContentTable.Add();
				NewRow.BaseSpecification = RowProduction.Specification;
				NewRow.ProductsAndServices = DistrRow.ProductsAndServices;
				NewRow.Characteristic = DistrRow.Characteristic;
				NewRow.Quantity = ?(RowProduction.Quantity=0 Or RowProduction.Factor=0, 0, DistrRow.Quantity / RowProduction.Quantity / RowProduction.Factor);
				NewRow.CostPercentage = DistrRow.CostPercentage;
			EndDo; 
		EndDo;
	EndDo; 
	
EndProcedure

Procedure JoinInventoryAndDistribution(InventoryTab, InventoryDistributionTable)
	
	InventoryTab.GroupBy("ProductsAndServices, Characteristic, Batch, MeasurementUnit, Specification, StructuralUnit, CustomerOrder", "CostPercentage, Quantity");
	InventoryDistributionTable.Columns.Add("CostPercentage", New TypeDescription("Number", New NumberQualifiers(15, 2, AllowedSign.Nonnegative)));
	InventoryDistributionTable.Columns.Add("Distributed", New TypeDescription("Boolean"));
	
	For Each RowInventory In InventoryTab Do
		FilterStructure = New Structure("ProductsAndServices, Characteristic, Batch, Specification, MeasurementUnit, StructuralUnit, CustomerOrder");
		FillPropertyValues(FilterStructure, RowInventory);
		FilterStructure.Insert("Distributed", False);
		DistributionRows = InventoryDistributionTable.FindRows(FilterStructure);
		QuantityDistribute = RowInventory.Quantity;
		DistributionCostPercentage = RowInventory.CostPercentage;
		For Each DistribRow In DistributionRows Do
			If QuantityDistribute=DistribRow.Quantity Then
				DistribRow.CostPercentage = DistributionCostPercentage;
				DistribRow.Distributed = True;
				Break;
			ElsIf QuantityDistribute>DistribRow.Quantity Then
				If QuantityDistribute<>0 Then
					DistribRow.CostPercentage = DistributionCostPercentage * DistribRow.Quantity / QuantityDistribute;
				EndIf; 
				DistribRow.Distributed = True;
				QuantityDistribute = QuantityDistribute-DistribRow.Quantity;
				DistributionCostPercentage = DistributionCostPercentage-DistribRow.CostPercentag;
			ElsIf QuantityDistribute<DistribRow.Quantity Then
				NewRow = InventoryDistributionTable.Insert(InventoryDistributionTable.IndexOf(DistribRow));
				FillPropertyValues(NewRow, DistribRow);
				NewRow.Quantity = QuantityDistribute;
				NewRow.CostPercentage = DistributionCostPercentage;
				NewRow.Distributed = True;
				DistribRow.Quantity = DistribRow.Quantity-NewRow.Quantity;
				Break;
			EndIf; 
		EndDo; 
	EndDo; 
	
	If InventoryDistributionTable.Columns.Find("LineNumber")<>Undefined Then
		InventoryDistributionTable.Sort("LineNumber");
	EndIf; 
	
EndProcedure

Function GetSelectionOperationDisassembly(Query)
	
	Query.SetParameter("RoundMethodsTable", SmallBusinessServer.RoundingTable());
	Query.Text =
	"SELECT
	|	RoundMethodsTable.Method AS Method,
	|	RoundMethodsTable.Value AS Value
	|INTO RoundMethodsTable
	|FROM
	|	&RoundMethodsTable AS RoundMethodsTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableContent.BaseSpecification AS BaseSpecification,
	|	TableContent.LineNumber AS LineNumber,
	|	TableContent.ProductsAndServices AS ProductsAndServices,
	|	TableContent.Characteristic AS Characteristic,
	|	TableContent.Specification AS Specification,
	|	TableContent.Quantity AS Quantity,
	|	TableContent.CostPercentage AS CostPercentage
	|INTO TableContent
	|FROM
	|	&TableContent AS TableContent
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableContent.BaseSpecification AS Specification,
	|	SUM(TableContent.CostPercentage) AS CostPercentage
	|INTO SpecificationTotal
	|FROM
	|	TableContent AS TableContent
	|
	|GROUP BY
	|	TableContent.BaseSpecification
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Operations.ProductionOrder AS Basis,
	|	Operations.ProductionOrder AS ProductionOrder,
	|	Operations.Period AS Period,
	|	Operations.Company AS Company,
	|	Operations.StructuralUnit AS StructuralUnit,
	|	Operations.Performer AS Performer,
	|	Operations.ClosingDate AS ClosingDate,
	|	Operations.ConnectionKey AS ConnectionKey,
	|	Operations.CustomerOrder AS CustomerOrder,
	|	Operations.LineNumber AS LineNumber,
	|	Operations.LineNumberOperations AS LineNumberOperations,
	|	ISNULL(TableContent.LineNumber, 1) AS LineNumberСостава,
	|	ISNULL(TableContent.ProductsAndServices, Operations.ProductsAndServices) AS ProductsAndServices,
	|	ISNULL(TableContent.Characteristic, Operations.Characteristic) AS Characteristic,
	|	Operations.Factor AS Factor,
	|	Operations.Quantity * ISNULL(TableContent.Quantity, 1) AS Quantity,
	|	Operations.Specification AS Specification,
	|	Operations.Batch AS Batch,
	|	Operations.Operation AS Operation,
	|	Operations.FixedCost AS FixedCost,
	|	Operations.MeasurementUnit AS MeasurementUnit,
	|	CAST(CASE
	|			WHEN ISNULL(TableContent.Quantity, 1) = 0
	|				THEN 0
	|			ELSE Operations.NormRate / ISNULL(TableContent.Quantity, 1) * ISNULL(CASE
	|						WHEN SpecificationTotal.CostPercentage = 0
	|							THEN 1
	|						ELSE TableContent.CostPercentage / SpecificationTotal.CostPercentage
	|					END, 1)
	|		END AS NUMBER(15, 3)) AS NormRate
	|INTO OperationAndContent
	|FROM
	|	Operations AS Operations
	|		LEFT JOIN TableContent AS TableContent
	|			LEFT JOIN SpecificationTotal AS SpecificationTotal
	|			ON TableContent.BaseSpecification = SpecificationTotal.Specification
	|		ON Operations.Specification = TableContent.BaseSpecification
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NormTotal.Specification AS Specification,
	|	(NormTotal.NormRate - ISNULL(NestedQuery.NormRate, 0)) / ISNULL(MinQuantityRow.Quantity, 1) AS NormRate,
	|	ISNULL(MinQuantityRow.LineNumber, 1) AS LineNumber
	|INTO NormDivergence
	|FROM
	|	(SELECT
	|		Operations.Specification AS Specification,
	|		SUM(Operations.NormRate) AS NormRate
	|	FROM
	|		Operations AS Operations
	|	
	|	GROUP BY
	|		Operations.Specification) AS NormTotal
	|		LEFT JOIN (SELECT
	|			OperationAndContent.Specification AS Specification,
	|			SUM(CAST(OperationAndContent.NormRate * OperationAndContent.Quantity AS NUMBER(15, 3))) AS NormRate,
	|			MAX(OperationAndContent.LineNumberСостава) AS LineNumber
	|		FROM
	|			OperationAndContent AS OperationAndContent
	|		
	|		GROUP BY
	|			OperationAndContent.Specification) AS NestedQuery
	|		ON NormTotal.Specification = NestedQuery.Specification,
	|	(SELECT
	|		MinQuantity.Quantity AS Quantity,
	|		MAX(TableContent.LineNumber) AS LineNumber
	|	FROM
	|		(SELECT
	|			MIN(TableContent.Quantity) AS Quantity
	|		FROM
	|			TableContent AS TableContent
	|		WHERE
	|			TableContent.Quantity <> 0) AS MinQuantity
	|			LEFT JOIN TableContent AS TableContent
	|			ON MinQuantity.Quantity = TableContent.Quantity
	|	
	|	GROUP BY
	|		MinQuantity.Quantity) AS MinQuantityRow
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OperationAndContent.Basis AS Basis,
	|	OperationAndContent.ProductionOrder AS ProductionOrder,
	|	OperationAndContent.Period AS Period,
	|	OperationAndContent.Company AS Company,
	|	OperationAndContent.StructuralUnit AS StructuralUnit,
	|	OperationAndContent.Performer AS Performer,
	|	OperationAndContent.ClosingDate AS ClosingDate,
	|	OperationAndContent.CustomerOrder AS CustomerOrder,
	|	OperationAndContent.ProductsAndServices AS ProductsAndServices,
	|	OperationAndContent.Characteristic AS Characteristic,
	|	OperationAndContent.Factor AS Factor,
	|	OperationAndContent.Quantity AS QuantityPlan,
	|	OperationAndContent.Specification AS Specification,
	|	OperationAndContent.Batch AS Batch,
	|	OperationAndContent.Operation AS Operation,
	|	OperationAndContent.FixedCost AS FixedCost,
	|	OperationAndContent.MeasurementUnit AS MeasurementUnit,
	|	OperationAndContent.NormRate + ISNULL(NormDivergence.NormRate, 0) AS NormRate,
	|	(CAST(ISNULL(ProductsAndServicesSliceLast.Price / ISNULL(ProductsAndServicesSliceLast.MeasurementUnit.Factor, 1), 0) / ISNULL(RoundMethodsTable.Value, 0.01) AS NUMBER(15, 0))) * ISNULL(RoundMethodsTable.Value, 0.01) AS Rate
	|FROM
	|	OperationAndContent AS OperationAndContent
	|		LEFT JOIN InformationRegister.ProductsAndServicesPrices.SliceLast(&Period, PriceKind = VALUE(Catalog.PriceKinds.Accounting)) AS ProductsAndServicesSliceLast
	|			LEFT JOIN RoundMethodsTable AS RoundMethodsTable
	|			ON ProductsAndServicesSliceLast.PriceKind.RoundingOrder = RoundMethodsTable.Method
	|		ON OperationAndContent.Operation = ProductsAndServicesSliceLast.ProductsAndServices
	|		LEFT JOIN NormDivergence AS NormDivergence
	|		ON OperationAndContent.Specification = NormDivergence.Specification
	|			AND OperationAndContent.LineNumberСостава = NormDivergence.LineNumber
	|
	|ORDER BY
	|	OperationAndContent.ProductionOrder,
	|	OperationAndContent.LineNumber,
	|	OperationAndContent.LineNumberOperations";
	
	Return Query.Execute().Select();
	
EndFunction

Function HeaderProductionOrder()
	
	CurProductionOrder = ProductionOrder;
	
	If Operations.Count()=0 Then
		Return CurProductionOrder;
	EndIf; 
	
	CurProductionOrder = Operations[0].ProductionOrder;
	
	If Operations.Count()=1 Then
		Return CurProductionOrder;
	EndIf; 
	
	TableOrders = Operations.Unload(, "ProductionOrder");
	TableOrders.Columns.Add("Quantity", New TypeDescription("Number"));
	For Each CurRow In TableOrders Do
		CurRow.Quantity = 1;
	EndDo;
	TableOrders.GroupBy("ProductionOrder", "Quantity");
	
	If TableOrders.Count() < 2 Then
		Return CurProductionOrder;
	EndIf;
	
	TableOrders.Sort("Quantity Desc");
	
	If TableOrders[0].Quantity = TableOrders[1].Quantity Then
		Return CurProductionOrder;
	EndIf;
	
	CurProductionOrder = TableOrders[0].ProductionOrder;
	
	Return CurProductionOrder;
	
EndFunction

Function HeaderStructuralUnit()
	
	CurStructuralUnit = StructuralUnit;
	
	If Operations.Count()=0 Then
		Return CurStructuralUnit;
	EndIf; 
	
	CurStructuralUnit = Operations[0].StructuralUnit;
	
	If Operations.Count()=1 Then
		Return CurStructuralUnit;
	EndIf; 
	
	TableStructuralUnit = Operations.Unload(, "StructuralUnit");
	TableStructuralUnit.Columns.Add("Quantity", New TypeDescription("Number"));
	TableStructuralUnit.FillValues(1, "Quantity");
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

Procedure UpdateDescriptions() Export
	
	If PerformerPosition = Enums.AttributePositionOnForm.InTabularSection Then
		PerfomerDescription = "";
		For Each TabSecRow In Operations Do
			CurPerfomer = TrimAll(String(TabSecRow.Performer));
			If IsBlankString(CurPerfomer) Then
				Continue;
			EndIf;
			If Find(PerfomerDescription, CurPerfomer+Chars.LF)>0 Then
				Continue;
			EndIf; 
			PerfomerDescription = PerfomerDescription+CurPerfomer+Chars.LF;
		EndDo;
		PerfomerDescription = TrimAll(PerfomerDescription);
	Else
		PerfomerDescription = String(Performer);
	EndIf; 
	
	If StructuralUnitPosition = Enums.AttributePositionOnForm.InTabularSection Then
		StructurlUnitDescription = "";
		For Each TabSecRow In Operations Do
			If PerformerPosition= Enums.AttributePositionOnForm.InHeader And TypeOf(Performer)=Type("CatalogRef.Teams") Then
				Break;
			EndIf;
			If TypeOf(TabSecRow.Performer)=Type("CatalogRef.Teams") Then
				Continue;
			EndIf; 
			CurStructuralUnit = TrimAll(String(TabSecRow.StructuralUnit));
			If IsBlankString(CurStructuralUnit) Then
				Continue;
			EndIf;
			If Find(StructurlUnitDescription, CurStructuralUnit+Chars.LF)>0 Then
				Continue;
			EndIf; 
			StructurlUnitDescription = StructurlUnitDescription+CurStructuralUnit+Chars.LF;
		EndDo;
		
		For Each TabSecRow In TeamMembers Do
			
			CurStructuralUnit = TrimAll(String(TabSecRow.StructuralUnit));
			If IsBlankString(CurStructuralUnit) Then
				Continue;
			EndIf;
			
			If Find(StructurlUnitDescription, CurStructuralUnit+Chars.LF)>0 Then
				Continue;
			EndIf;
			
			StructurlUnitDescription = StructurlUnitDescription+CurStructuralUnit+Chars.LF;
			
		EndDo;
		StructurlUnitDescription = TrimAll(StructurlUnitDescription);
	Else
		StructurlUnitDescription = String(StructuralUnit);
	EndIf; 
	
EndProcedure

#EndIf