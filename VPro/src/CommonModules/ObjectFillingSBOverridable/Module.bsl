
#Region Interface

Procedure OnDefiningRulesStructuralUnitsSettings(Rules) Export
	
	Rules[Type("DocumentObject.WorkOrder")]				= Catalogs.StructuralUnits.MainDepartment;
	Rules[Type("DocumentObject.PurchaseOrder")]			= Catalogs.StructuralUnits.MainDepartment;
	Rules[Type("DocumentObject.Payroll")]						= Catalogs.StructuralUnits.MainDepartment;
	Rules[Type("DocumentObject.SalesTarget")]				= Catalogs.StructuralUnits.MainDepartment;
	Rules[Type("DocumentObject.PayrollSheet")]				= Catalogs.StructuralUnits.MainDepartment;
	Rules[Type("DocumentObject.OtherExpenses")]			= Catalogs.StructuralUnits.MainDepartment;
	Rules[Type("DocumentObject.CostAllocation")]			= Catalogs.StructuralUnits.MainDepartment;
	Rules[Type("DocumentObject.JobSheet")]					= Catalogs.StructuralUnits.MainDepartment;
	Rules[Type("DocumentObject.Timesheet")]				= Catalogs.StructuralUnits.MainDepartment;
	Rules[Type("DocumentObject.TimeTracking")]			= Catalogs.StructuralUnits.MainDepartment;
	Rules[Type("DocumentObject.InventoryAssembly")]	= Catalogs.StructuralUnits.MainDepartment;
	Rules[Type("DocumentObject.ProductionOrder")]		= Catalogs.StructuralUnits.MainDepartment;
	
	Rules[Type("DocumentObject.AdditionalCosts")]				= CommonUseClientServer.PredefinedItem("Catalog.StructuralUnits.MainWarehouse");
	Rules[Type("DocumentObject.InventoryReconciliation")]	= CommonUseClientServer.PredefinedItem("Catalog.StructuralUnits.MainWarehouse");
	Rules[Type("DocumentObject.InventoryReceipt")]			= CommonUseClientServer.PredefinedItem("Catalog.StructuralUnits.MainWarehouse");
	Rules[Type("DocumentObject.ProcessingReport")]			= CommonUseClientServer.PredefinedItem("Catalog.StructuralUnits.MainWarehouse");
	Rules[Type("DocumentObject.SubcontractorReport")]		= CommonUseClientServer.PredefinedItem("Catalog.StructuralUnits.MainWarehouse");
	Rules[Type("DocumentObject.TransferBetweenCells")]		= CommonUseClientServer.PredefinedItem("Catalog.StructuralUnits.MainWarehouse");
	Rules[Type("DocumentObject.FixedAssetsEnter")]			= CommonUseClientServer.PredefinedItem("Catalog.StructuralUnits.MainWarehouse");
	Rules[Type("DocumentObject.SupplierInvoice")]				= CommonUseClientServer.PredefinedItem("Catalog.StructuralUnits.MainWarehouse");
	Rules[Type("DocumentObject.GoodsReceipt")]				= CommonUseClientServer.PredefinedItem("Catalog.StructuralUnits.MainWarehouse");
	Rules[Type("DocumentObject.GoodsExpense")]				= CommonUseClientServer.PredefinedItem("Catalog.StructuralUnits.MainWarehouse");
	Rules[Type("DocumentObject.CustomerInvoice")]			= CommonUseClientServer.PredefinedItem("Catalog.StructuralUnits.MainWarehouse");
	Rules[Type("DocumentObject.InventoryWriteOff")]			= CommonUseClientServer.PredefinedItem("Catalog.StructuralUnits.MainWarehouse");
	Rules[Type("DocumentObject.InventoryTransfer")]			= CommonUseClientServer.PredefinedItem("Catalog.StructuralUnits.MainWarehouse");
	
EndProcedure

#EndRegion
