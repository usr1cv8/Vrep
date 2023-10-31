
////////////////////////////////////////////////////////////////////////////////
// GENERAL PURPOSE PROCEDURES AND FUNCTIONS

// Procedure fills in Inventory by specification.
//
&AtServer
Procedure FillBySpecificationsAtServer()
	
	Document = FormAttributeToValue("Object");
	NodesSpecificationStack = New Array;
	Document.FillTabularSectionBySpecification(NodesSpecificationStack);
	ValueToFormAttribute(Document, "Object");
	
	ProductionServer.FillDistributionControlCash(Object, DistributionControlCash);
	FillStagesUsingAttributes();
	
	InventoryNotFilled = False;
	DisplayControlMarks(ThisObject);
	UpdateFormStages(ThisObject);
	UpdateCellsAvailability();
	FillCellsAvailableAttributes(ThisObject);
	FormManagement(ThisObject);
	
	
EndProcedure // FillMaterialCostsOnServerSpecification()

// It receives data set from server for the DateOnChange procedure.
//
&AtServerNoContext
Function GetDataDateOnChange(DocumentRef, DateNew, DateBeforeChange)
	
	StructureData = New Structure();
	StructureData.Insert("DATEDIFF", SmallBusinessServer.CheckDocumentNumber(DocumentRef, DateNew, DateBeforeChange));
	
	Return StructureData;
	
EndFunction // GetDataDateOnChange()

// Gets data set from server.
//
&AtServerNoContext
Function GetCompanyDataOnChange(Company)
	
	StructureData = New Structure();
	StructureData.Insert("Counterparty", SmallBusinessServer.GetCompany(Company));
	
	Return StructureData;
	
EndFunction // GetCompanyDataOnChange()

// Receives the set of data from the server for the ProductsAndServicesOnChange procedure.
//
&AtServerNoContext
Function GetDataProductsAndServicesOnChange(StructureData)
	
	ProductsAndServicesData = CommonUse.ObjectAttributesValues(StructureData.ProductsAndServices, "MeasurementUnit, CountryOfOrigin");
	StructureData.Insert("MeasurementUnit", ProductsAndServicesData.MeasurementUnit);
	StructureData.Insert("CountryOfOrigin", ProductsAndServicesData.CountryOfOrigin);
	
	If StructureData.Property("Characteristic") Then
		StructureData.Insert("Specification", SmallBusinessServer.GetDefaultSpecification(StructureData.ProductsAndServices, StructureData.Characteristic));
	Else
		StructureData.Insert("Specification", SmallBusinessServer.GetDefaultSpecification(StructureData.ProductsAndServices));
	EndIf;
	
	
	FillSpecificationDataOnChange(StructureData);
	
	Return StructureData;
	
EndFunction // ReceiveDataProductsAndServicesOnChange()

// It receives data set from server for the CharacteristicOnChange procedure.
//
&AtServerNoContext
Function GetDataCharacteristicOnChange(StructureData)
	
	StructureData.Insert("Specification", SmallBusinessServer.GetDefaultSpecification(StructureData.ProductsAndServices, StructureData.Characteristic));
	
	Return StructureData;
	
EndFunction // GetDataCharacteristicOnChange()

// It receives data set from the server for the StructuralUnitOnChange procedure.
//
&AtServerNoContext
Function GetDataStructuralUnitOnChange(StructureData)
	
	If StructureData.Department.TransferRecipient.StructuralUnitType = Enums.StructuralUnitsTypes.Warehouse
		OR StructureData.Department.TransferRecipient.StructuralUnitType = Enums.StructuralUnitsTypes.Department Then
		
		StructureData.Insert("ProductsStructuralUnit", StructureData.Department.TransferRecipient);
		StructureData.Insert("ProductsCell", StructureData.Department.TransferRecipientCell);
		
	Else
		
		StructureData.Insert("ProductsStructuralUnit", Undefined);
		StructureData.Insert("ProductsCell", Undefined);
		
	EndIf;
	
	If StructureData.Department.TransferSource.StructuralUnitType = Enums.StructuralUnitsTypes.Warehouse
		OR StructureData.Department.TransferSource.StructuralUnitType = Enums.StructuralUnitsTypes.Department Then
		
		StructureData.Insert("InventoryStructuralUnit", StructureData.Department.TransferSource);
		StructureData.Insert("CellInventory", StructureData.Department.TransferSourceCell);
		
	Else
		
		StructureData.Insert("InventoryStructuralUnit", Undefined);
		StructureData.Insert("CellInventory", Undefined);
		
	EndIf;
	
	StructureData.Insert("DisposalsStructuralUnit", StructureData.Department.DisposalsRecipient);
	StructureData.Insert("DisposalsCell", StructureData.Department.DisposalsRecipientCell);
	
	StructureData.Insert("OrderWarehouse", Not StructureData.Department.OrderWarehouse);
	StructureData.Insert("OrderWarehouseOfProducts", Not StructureData.Department.TransferRecipient.OrderWarehouse);
	StructureData.Insert("OrderWarehouseWaste", Not StructureData.Department.DisposalsRecipient.OrderWarehouse);
	StructureData.Insert("OrderWarehouseOfInventory", Not StructureData.Department.TransferSource.OrderWarehouse);
	
	Return StructureData;
	
EndFunction // GetDataStructuralUnitOnChange()

// Receives data set from the server for CellOnChange procedure.
//
&AtServerNoContext
Function GetDataCellOnChange(StructureData)
	
	If StructureData.StructuralUnit = StructureData.ProductsStructuralUnit Then
		
		If StructureData.StructuralUnit.TransferRecipient <> StructureData.ProductsStructuralUnit
			OR StructureData.StructuralUnit.TransferRecipientCell <> StructureData.ProductsCell Then
			
			StructureData.Insert("NewGoodsCell", StructureData.Cell);
			
		EndIf;
		
	EndIf;
	
	If StructureData.StructuralUnit = StructureData.InventoryStructuralUnit Then
		
		If StructureData.StructuralUnit.TransferSource <> StructureData.InventoryStructuralUnit
			OR StructureData.StructuralUnit.TransferSourceCell <> StructureData.CellInventory Then
			
			StructureData.Insert("NewCellInventory", StructureData.Cell);
			
		EndIf;
		
	EndIf;
	
	If StructureData.StructuralUnit = StructureData.DisposalsStructuralUnit Then
		
		If StructureData.StructuralUnit.DisposalsRecipient <> StructureData.DisposalsStructuralUnit
			OR StructureData.StructuralUnit.DisposalsRecipientCell <> StructureData.DisposalsCell Then
			
			StructureData.Insert("NewCellWastes", StructureData.Cell);
			
		EndIf;
		
	EndIf;
	
	Return StructureData;
	
EndFunction // GetDataCellOnChange()

// It receives data set from the server for the StructuralUnitOnChange procedure.
//
&AtServerNoContext
Function GetDataStructuralUnitProductsInventoryDisposalsOnChange(StructureData)
	
	StructureData.Insert("OrderWarehouse", Not StructureData.Warehouse.OrderWarehouse);
	
	Return StructureData;
	
EndFunction // GetDataStructuralUnitProductsInventoryDisposalsOnChange()

// Procedure calls the data processor for document filling by basis.
//
&AtServer
Procedure FillByDocument(AttributeBasis = "BasisDocument")
	
	Document = FormAttributeToValue("Object");
	Document.Filling(Object[AttributeBasis], );
	ValueToFormAttribute(Document, "Object");
	
	FormManagement(ThisObject);
	
	SetVisibleByUserSettings(ЭтотОбъект);
	
	FillStagesUsingAttributes();
	
EndProcedure // FillByDocument()

// Peripherals
// Procedure gets data by barcodes.
//
&AtServerNoContext
Procedure GetDataByBarCodes(StructureData)
	
	// Transform weight barcodes.
	For Each CurBarcode IN StructureData.BarcodesArray Do
		
		InformationRegisters.ProductsAndServicesBarcodes.ConvertWeightBarcode(CurBarcode);
		
	EndDo;
	
	DataByBarCodes = InformationRegisters.ProductsAndServicesBarcodes.GetDataByBarCodes(StructureData.BarcodesArray);
	
	For Each CurBarcode IN StructureData.BarcodesArray Do
		
		BarcodeData = DataByBarCodes[CurBarcode.Barcode];
		
		If BarcodeData <> Undefined
			AND BarcodeData.Count() <> 0 Then
			
			StructureProductsAndServicesData = New Structure();
			StructureProductsAndServicesData.Insert("ProductsAndServices", BarcodeData.ProductsAndServices);
			StructureProductsAndServicesData.Insert("Characteristic", BarcodeData.Characteristic);
			BarcodeData.Insert("StructureProductsAndServicesData", GetDataProductsAndServicesOnChange(StructureProductsAndServicesData));
			
			If Not ValueIsFilled(BarcodeData.MeasurementUnit) Then
				BarcodeData.MeasurementUnit  = BarcodeData.ProductsAndServices.MeasurementUnit;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	StructureData.Insert("DataByBarCodes", DataByBarCodes);
	
EndProcedure // GetDataByBarCodes()

&AtClient
Function FillByBarcodesData(BarcodesData)
	
	UnknownBarcodes = New Array;
	
	If TypeOf(BarcodesData) = Type("Array") Then
		BarcodesArray = BarcodesData;
	Else
		BarcodesArray = New Array;
		BarcodesArray.Add(BarcodesData);
	EndIf;
	
	StructureData = New Structure();
	StructureData.Insert("BarcodesArray", BarcodesArray);
	GetDataByBarCodes(StructureData);
	
	For Each CurBarcode IN StructureData.BarcodesArray Do
		BarcodeData = StructureData.DataByBarCodes[CurBarcode.Barcode];
		
		If BarcodeData <> Undefined
			AND BarcodeData.Count() = 0 Then
			UnknownBarcodes.Add(CurBarcode);
		Else
			TSRowsArray = Object.Inventory.FindRows(New Structure("ProductsAndServices, Characteristic, Batch, MeasurementUnit",BarcodeData.ProductsAndServices,BarcodeData.Characteristic,BarcodeData.Batch,BarcodeData.MeasurementUnit));
			If TSRowsArray.Count() = 0 Then
				NewRow = Object.Inventory.Add();
				NewRow.ProductsAndServices = BarcodeData.ProductsAndServices;
				NewRow.Characteristic = BarcodeData.Characteristic;
				NewRow.Batch = BarcodeData.Batch;
				NewRow.Quantity = CurBarcode.Quantity;
				NewRow.CostPercentage = 1;
				NewRow.MeasurementUnit = ?(ValueIsFilled(BarcodeData.MeasurementUnit), BarcodeData.MeasurementUnit, BarcodeData.StructureProductsAndServicesData.MeasurementUnit);
				NewRow.Specification = BarcodeData.StructureProductsAndServicesData.Specification;
				Items.Inventory.CurrentRow = NewRow.GetID();
			Else
				NewRow = TSRowsArray[0];
				NewRow.Quantity = NewRow.Quantity + CurBarcode.Quantity;
				Items.Inventory.CurrentRow = NewRow.GetID();
			EndIf;
			
			If BarcodeData.Property("SerialNumber") AND ValueIsFilled(BarcodeData.SerialNumber) Then
				WorkWithSerialNumbersClientServer.AddSerialNumberToString(NewRow, BarcodeData.SerialNumber, Object);
			EndIf;
		EndIf;
	EndDo;
	
	Return UnknownBarcodes;
	
EndFunction // FillByBarcodesData()

// Procedure processes the received barcodes.
//
&AtClient
Procedure BarcodesReceived(BarcodesData)
	
	Modified = True;
	
	UnknownBarcodes = FillByBarcodesData(BarcodesData);
	
	ReturnParameters = Undefined;
	
	If UnknownBarcodes.Count() > 0 Then
		
		Notification = New NotifyDescription("BarcodesAreReceivedEnd", ThisForm, UnknownBarcodes);
		
		OpenForm(
		"InformationRegister.ProductsAndServicesBarcodes.Form.ProductsAndServicesBarcodesRegistration",
		New Structure("UnknownBarcodes", UnknownBarcodes), ThisForm,,,,Notification
		);
		
		Return;
		
	EndIf;
	
	BarcodesAreReceivedFragment(UnknownBarcodes);
	
EndProcedure // BarcodesAreReceived()

&AtClient
Procedure BarcodesAreReceivedEnd(ReturnParameters, Parameters) Export
	
	UnknownBarcodes = Parameters;
	
	If ReturnParameters <> Undefined Then
		
		BarcodesArray = New Array;
		
		For Each ArrayElement IN ReturnParameters.RegisteredBarcodes Do
			BarcodesArray.Add(ArrayElement);
		EndDo;
		
		For Each ArrayElement IN ReturnParameters.ReceivedNewBarcodes Do
			BarcodesArray.Add(ArrayElement);
		EndDo;
		
		UnknownBarcodes = FillByBarcodesData(BarcodesArray);
		
	EndIf;
	
	BarcodesAreReceivedFragment(UnknownBarcodes);
	
EndProcedure

&AtClient
Procedure BarcodesAreReceivedFragment(UnknownBarcodes) Export
	
	For Each CurUndefinedBarcode IN UnknownBarcodes Do
		
		MessageString = NStr("ru = 'Данные по штрихкоду не найдены: %1%; количество: %2%';
		|vi = 'Không tìm thấy dữ liệu về mã vạch: %1%; số lượng: %2%';
		|en = 'Barcode data is not found: %1%; quantity: %2%'");
		MessageString = StrReplace(MessageString, "%1%", CurUndefinedBarcode.Barcode);
		MessageString = StrReplace(MessageString, "%2%", CurUndefinedBarcode.Quantity);
		CommonUseClientServer.MessageToUser(MessageString);
		
	EndDo;
	
EndProcedure

// End Peripherals

// The procedure fills in column Reserve by reserves for the order.
//
&AtServer
Procedure FillColumnReserveByReservesAtServer()
	
	Document = FormAttributeToValue("Object");
	Document.FillColumnReserveByReserves();
	ValueToFormAttribute(Document, "Object");
	
EndProcedure // FillColumnReserveByReservesAtServer()

////////////////////////////////////////////////////////////////////////////////
// PROCEDURES AND FUNCTIONS FOR CONTROL OF THE FORM APPEARANCE

&AtClientAtServerNoContext
Функция CustomerOrderFilled(Object)
	
	Return ЗначениеЗаполнено(Object.CustomerOrder);
	
КонецФункции 


&AtClientAtServerNoContext
Procedure FormManagement(Form)
	
	Object = Form.Object;
	Items = Form.Items;
	
	ItDisassembly = (Object.OperationKind = PredefinedValue("Enum.OperationKindsInventoryAssembly.Disassembly"));
	ItAssembly = (Object.OperationKind = PredefinedValue("Enum.OperationKindsInventoryAssembly.Assembly"));
	
	CustomerOrderFilled = CustomerOrderFilled(Object);
	
	CommonUseClientServer.SetFormItemProperty(Items, "InventoryStructuralUnitAssembling", "AutoMarkIncomplete", Object.Inventory.Count()>0);
	If Object.Inventory.Count()=0 Then
		CommonUseClientServer.SetFormItemProperty(Items, "InventoryStructuralUnitAssembling", "MarkIncomplete", False);
	EndIf; 
	
	// Reserve.
	UseReserving = CustomerOrderFilled И ItAssembly;
	Items.InventoryReserve.Видимость = CustomerOrderFilled И ItAssembly;
	Items.InventoryChangeReserve.Видимость = CustomerOrderFilled И ItAssembly;
	Items.ProductsReserve.Видимость = CustomerOrderFilled И ItAssembly;
	Items.InventoryCostPercentage.Видимость = ItDisassembly;
	
	Items.CustomerOrder.ReadOnly = ValueIsFilled(Object.BasisDocument);
	Items.ProductsCustomerOrder.ReadOnly = ValueIsFilled(Object.BasisDocument);
	Items.InventoryCustomerOrder.ReadOnly = ValueIsFilled(Object.BasisDocument);
	
	Items.InventoryDistribution.ReadOnly = Form.ReadOnly;
	Items.ManualDistribution.ReadOnly = Form.ReadOnly;
	
	If ItDisassembly Then
		
		// Reserve.
		Items.InventoryReserve.Visible = False;
		ReservationUsed = False;
		Items.InventoryChangeReserve.Visible = False;
		Items.ProductsReserve.Visible = ValueIsFilled(Object.CustomerOrder);
		Items.InventoryCostPercentage.Visible = True;
		
		// Batch status.
		NewArray = New Array();
		NewArray.Add(PredefinedValue("Enum.BatchStatuses.OwnInventory"));
		NewArray.Add(PredefinedValue("Enum.BatchStatuses.CommissionMaterials"));
		ArrayInventoryWork = New FixedArray(NewArray);
		NewParameter = New ChoiceParameter("Filter.Status", ArrayInventoryWork);
		NewParameter2 = New ChoiceParameter("Additionally.StatusRestriction", ArrayInventoryWork);
		NewArray = New Array();
		NewArray.Add(NewParameter);
		NewArray.Add(NewParameter2);
		NewParameters = New FixedArray(NewArray);
		Items.ProductsBatch.ChoiceParameters = NewParameters;
		
		Items.GroupWarehouseProductsAssembling.Visible = False;
		Items.GroupWarehouseProductsDisassembling.Visible = True;
		
		Items.GroupWarehouseInventoryAssembling.Visible = False;
		Items.GroupWarehouseInventoryDisassembling.Visible = True;
		
	Else
		
		// Reserve.
		Items.InventoryReserve.Visible = ValueIsFilled(Object.CustomerOrder);
		ReservationUsed = ValueIsFilled(Object.CustomerOrder);
		Items.InventoryChangeReserve.Visible = ValueIsFilled(Object.CustomerOrder);
		Items.ProductsReserve.Visible = False;
		Items.InventoryCostPercentage.Visible = False;
		
		// Batch status.
		NewParameter = New ChoiceParameter("Filter.Status", PredefinedValue("Enum.BatchStatuses.OwnInventory"));
		NewArray = New Array();
		NewArray.Add(NewParameter);
		NewParameters = New FixedArray(NewArray);
		Items.ProductsBatch.ChoiceParameters = NewParameters;
		
		For Each StringProducts IN Object.Products Do
			
			If ValueIsFilled(StringProducts.Batch)
				AND StringProducts.Batch.Status = PredefinedValue("Enum.BatchStatuses.CommissionMaterials") Then
				StringProducts.Batch = Undefined;
			EndIf;
			
		EndDo;
		
		Items.GroupWarehouseProductsAssembling.Visible = True;
		Items.GroupWarehouseProductsDisassembling.Visible = False;
		
		Items.GroupWarehouseInventoryAssembling.Visible = True;
		Items.GroupWarehouseInventoryDisassembling.Visible = False;
		
	EndIf;
	
	CommonUseClientServer.SetFormItemProperty(Items, "ProductsCountryOfOrigin",	    "Visible", ItDisassembly);
	CommonUseClientServer.SetFormItemProperty(Items, "ProductsCCDNo",				    "Visible", ItDisassembly);
	CommonUseClientServer.SetFormItemProperty(Items, "InventoryCountryOfOrigin",		    "Visible", ItAssembly);
	CommonUseClientServer.SetFormItemProperty(Items, "InventoryCCDNo", 				    "Visible", ItAssembly);
	
	CommonUseClientServer.SetFormItemProperty(Items, "TSDistribution", "Visible", Object.ManualDistribution);
	CommonUseClientServer.SetFormItemProperty(Items, "InventoryFillByDistribution",    "Visible", Object.ManualDistribution);
	
	StageVisibleControl(Form)
	
EndProcedure // SetVisibleAndEnabled()

// Procedure sets selection mode and selection list for the form units.
//
// Parameters:
//  No.
//
&AtServer
Procedure SetModeAndChoiceList()
	
	If Not ValueIsFilled(Object.StructuralUnit)
		OR Object.StructuralUnit.OrderWarehouse Then
		Items.Cell.Enabled = False;
	EndIf;
	
	If Not ValueIsFilled(Object.ProductsStructuralUnit)
		OR Object.ProductsStructuralUnit.OrderWarehouse Then
		Items.ProductsCellAssembling.Enabled = False;
		Items.CellInventoryDisassembling.Enabled = False;
	EndIf;
	
	If Not ValueIsFilled(Object.InventoryStructuralUnit)
		OR Object.InventoryStructuralUnit.OrderWarehouse Then
		Items.CellInventoryAssembling.Enabled = False;
		Items.ProductsCellDisassembling.Enabled = False;
	EndIf;
	
	If Not ValueIsFilled(Object.DisposalsStructuralUnit)
		OR Object.DisposalsStructuralUnit.OrderWarehouse Then
		Items.DisposalsCell.Enabled = False;
	EndIf;
	
	If Not Constants.FunctionalOptionAccountingByMultipleDepartments.Get()
		AND Not Constants.FunctionalOptionAccountingByMultipleWarehouses.Get() Then
		
		Items.StructuralUnit.ListChoiceMode = True;
		Items.StructuralUnit.ChoiceList.Add(Catalogs.StructuralUnits.MainDepartment);
		Items.StructuralUnit.ChoiceList.Add(Catalogs.StructuralUnits.MainWarehouse);
		
		Items.ProductsStructuralUnitAssembling.ListChoiceMode = True;
		Items.ProductsStructuralUnitAssembling.ChoiceList.Add(Catalogs.StructuralUnits.MainDepartment);
		Items.ProductsStructuralUnitAssembling.ChoiceList.Add(Catalogs.StructuralUnits.MainWarehouse);
		
		Items.ProductsStructuralUnitDisassembling.ListChoiceMode = True;
		Items.ProductsStructuralUnitDisassembling.ChoiceList.Add(Catalogs.StructuralUnits.MainDepartment);
		Items.ProductsStructuralUnitDisassembling.ChoiceList.Add(Catalogs.StructuralUnits.MainWarehouse);
		
		Items.InventoryStructuralUnitAssembling.ListChoiceMode = True;
		Items.InventoryStructuralUnitAssembling.ChoiceList.Add(Catalogs.StructuralUnits.MainDepartment);
		Items.InventoryStructuralUnitAssembling.ChoiceList.Add(Catalogs.StructuralUnits.MainWarehouse);
		
		Items.InventoryStructuralUnitDisassembling.ListChoiceMode = True;
		Items.InventoryStructuralUnitDisassembling.ChoiceList.Add(Catalogs.StructuralUnits.MainDepartment);
		Items.InventoryStructuralUnitDisassembling.ChoiceList.Add(Catalogs.StructuralUnits.MainWarehouse);
		
		Items.DisposalsStructuralUnit.ListChoiceMode = True;
		Items.DisposalsStructuralUnit.ChoiceList.Add(Catalogs.StructuralUnits.MainDepartment);
		Items.DisposalsStructuralUnit.ChoiceList.Add(Catalogs.StructuralUnits.MainWarehouse);
		
	EndIf;
	
EndProcedure // SetModeAndChoiceList()

////////////////////////////////////////////////////////////////////////////////
// PROCEDURES FOR WORK WITH THE SELECTION

// Procedure - event handler Action of the Pick command
//
&AtClient
Procedure Pick(Command)
	
	TabularSectionName 	= "Inventory";
	SelectionMarker = "Inventory";
	
	SelectionParameters = New Structure;
	
	SelectionParameters.Insert("Period", 		Object.Date);
	SelectionParameters.Insert("Company", 	SubsidiaryCompany);
	
	If Object.OperationKind = PredefinedValue("Enum.OperationKindsInventoryAssembly.Assembly") Then
		SelectionParameters.Insert("StructuralUnit", Object.InventoryStructuralUnit);
	Else
		SelectionParameters.Insert("StructuralUnit", Object.ProductsStructuralUnit);
	EndIf;
	
	SelectionParameters.Insert("SpecificationsUsed", True);
	SelectionParameters.Insert("ReservationUsed", ReservationUsed);
	
	If Object.OperationKind = PredefinedValue("Enum.OperationKindsInventoryAssembly.Assembly") Then
		SelectionParameters.Insert("ThisIsReceiptDocument", False);
		SelectionParameters.Insert("AvailableStructuralUnitEdit", True);
	Else
		SelectionParameters.Insert("ThisIsReceiptDocument", True);
		SelectionParameters.Insert("AvailableStructuralUnitEdit", False);
	EndIf;
	
	ProductsAndServicesType = New ValueList;
	For Each ArrayElement IN Items[TabularSectionName + "ProductsAndServices"].ChoiceParameters Do
		If ArrayElement.Name = "Filter.ProductsAndServicesType" Then
			If TypeOf(ArrayElement.Value) = Type("FixedArray") Then
				For Each FixArrayItem IN ArrayElement.Value Do
					ProductsAndServicesType.Add(FixArrayItem);
				EndDo; 
			Else
				ProductsAndServicesType.Add(ArrayElement.Value);
			EndIf;
		EndIf;
	EndDo;
	SelectionParameters.Insert("ProductsAndServicesType", ProductsAndServicesType);
	
	BatchStatus = New ValueList;
	For Each ArrayElement IN Items[TabularSectionName + "Batch"].ChoiceParameters Do
		If ArrayElement.Name = "Filter.Status" Then
			If TypeOf(ArrayElement.Value) = Type("FixedArray") Then
				For Each FixArrayItem IN ArrayElement.Value Do
					BatchStatus.Add(FixArrayItem);
				EndDo;
			Else
				BatchStatus.Add(ArrayElement.Value);
			EndIf;
		EndIf;
	EndDo;
	
	SelectionParameters.Insert("BatchStatus", BatchStatus);
	
	SelectionParameters.Insert("OwnerFormUUID", UUID);
	
	OpenForm("CommonForm.PickForm", SelectionParameters, ThisForm);
	
EndProcedure // Selection()

// Procedure - handler of the Action event of the Pick TS Products command.
//
&AtClient
Procedure ProductsPick(Command)
	
	TabularSectionName = "Products";
	SelectionMarker = "Products";
	
	SelectionParameters = New Structure;
	
	SelectionParameters.Insert("Period", 		Object.Date);
	SelectionParameters.Insert("Company",	SubsidiaryCompany);
	
	If Object.OperationKind = PredefinedValue("Enum.OperationKindsInventoryAssembly.Assembly") Then
		SelectionParameters.Insert("StructuralUnit", Object.ProductsStructuralUnit);
	Else
		SelectionParameters.Insert("StructuralUnit", Object.InventoryStructuralUnit);
	EndIf;
	
	SelectionParameters.Insert("SpecificationsUsed", True);
	SelectionParameters.Insert("ReservationUsed", ReservationUsed);
	
	If Object.OperationKind = PredefinedValue("Enum.OperationKindsInventoryAssembly.Assembly") Then
		SelectionParameters.Insert("ThisIsReceiptDocument", True);
		SelectionParameters.Insert("AvailableStructuralUnitEdit", False);
	Else
		SelectionParameters.Insert("ThisIsReceiptDocument", False);
		SelectionParameters.Insert("AvailableStructuralUnitEdit", True);
	EndIf;
	
	ProductsAndServicesType = New ValueList;
	For Each ArrayElement IN Items[TabularSectionName + "ProductsAndServices"].ChoiceParameters Do
		If ArrayElement.Name = "Filter.ProductsAndServicesType" Then
			If TypeOf(ArrayElement.Value) = Type("FixedArray") Then
				For Each FixArrayItem IN ArrayElement.Value Do
					ProductsAndServicesType.Add(FixArrayItem);
				EndDo;
			Else
				ProductsAndServicesType.Add(ArrayElement.Value);
			EndIf;
		EndIf;
	EndDo;
	SelectionParameters.Insert("ProductsAndServicesType", ProductsAndServicesType);
	
	BatchStatus = New ValueList;
	For Each ArrayElement IN Items[TabularSectionName + "Batch"].ChoiceParameters Do
		If ArrayElement.Name = "Filter.Status" Then
			If TypeOf(ArrayElement.Value) = Type("FixedArray") Then
				For Each FixArrayItem IN ArrayElement.Value Do
					BatchStatus.Add(FixArrayItem);
				EndDo;
			Else
				BatchStatus.Add(ArrayElement.Value);
			EndIf;
		EndIf;
	EndDo;
	
	SelectionParameters.Insert("BatchStatus", BatchStatus);
	
	SelectionParameters.Insert("OwnerFormUUID", UUID);
	
	OpenForm("CommonForm.PickForm", SelectionParameters, ThisForm);
	
EndProcedure // ProductsPick()

// Procedure - event handler Action of the Pick command
//
&AtClient
Procedure DisposalsPick(Command)
	
	TabularSectionName 	= "Disposals";
	SelectionMarker = "Disposals";
	
	SelectionParameters = New Structure;
	
	SelectionParameters.Insert("Period", 				Object.Date);
	SelectionParameters.Insert("Company", 			SubsidiaryCompany);
	SelectionParameters.Insert("ThisIsReceiptDocument", True);
	
	ProductsAndServicesType = New ValueList;
	For Each ArrayElement IN Items[TabularSectionName + "ProductsAndServices"].ChoiceParameters Do
		If ArrayElement.Name = "Filter.ProductsAndServicesType" Then
			If TypeOf(ArrayElement.Value) = Type("FixedArray") Then
				For Each FixArrayItem IN ArrayElement.Value Do
					ProductsAndServicesType.Add(FixArrayItem);
				EndDo; 
			Else
				ProductsAndServicesType.Add(ArrayElement.Value);
			EndIf;
		EndIf;
	EndDo;
	SelectionParameters.Insert("ProductsAndServicesType", ProductsAndServicesType);
	
	BatchStatus = New ValueList;
	For Each ArrayElement IN Items[TabularSectionName + "Batch"].ChoiceParameters Do
		If ArrayElement.Name = "Filter.Status" Then
			If TypeOf(ArrayElement.Value) = Type("FixedArray") Then
				For Each FixArrayItem IN ArrayElement.Value Do
					BatchStatus.Add(FixArrayItem);
				EndDo;
			Else
				BatchStatus.Add(ArrayElement.Value);
			EndIf;
		EndIf;
	EndDo;
	
	SelectionParameters.Insert("BatchStatus", BatchStatus);
	
	SelectionParameters.Insert("OwnerFormUUID", UUID);
	
	OpenForm("CommonForm.PickForm", SelectionParameters, ThisForm);
	
EndProcedure // ExecutePick()

// Function gets a product list from the temporary storage
//
&AtServer
Procedure GetInventoryFromStorage(InventoryAddressInStorage, TabularSectionName, AreCharacteristics, AreBatches)
	
	TableForImport = GetFromTempStorage(InventoryAddressInStorage);
	
	For Each ImportRow IN TableForImport Do
		
		NewRow = Object[TabularSectionName].Add();
		FillPropertyValues(NewRow, ImportRow);
		
	EndDo;
	
EndProcedure // GetInventoryFromStorage()

// Peripherals
// Procedure - command handler of the tabular section command panel.
//
&AtClient
Procedure SearchByBarcode(Command)
	
	CurBarcode = "";
	ShowInputValue(New NotifyDescription("SearchByBarcodeEnd", ThisObject, New Structure("CurBarcode", CurBarcode)), CurBarcode, NStr("ru = 'Введите штрихкод';
	|vi = 'Hãy nhập mã vạch';
	|en = 'Enter barcode'"));
	
EndProcedure

&AtClient
Procedure SearchByBarcodeEnd(Result, AdditionalParameters) Export
	
	CurBarcode = ?(Result = Undefined, AdditionalParameters.CurBarcode, Result);
	
	
	If Not IsBlankString(CurBarcode) Then
		BarcodesReceived(New Structure("Barcode, Quantity, CostPercentage", CurBarcode, 1, 1));
	EndIf;
	
EndProcedure // SearchByBarcode()

// Procedure - event handler Action of the GetWeight command
//
&AtClient
Procedure GetWeight(Command)
	
	TabularSectionRow = Items.Inventory.CurrentData;
	
	If TabularSectionRow = Undefined Then
		
		ShowMessageBox(Undefined, NStr("ru = 'Необходимо выбрать строку, для которой необходимо получить вес.';
		|vi = 'Cần chọn dòng mà theo đó cần nhận trọng lượng.';
		|en = 'Select a line for which the weight should be received.'"));
		
	ElsIf EquipmentManagerClient.RefreshClientWorkplace() Then // Checks if the operator's workplace is specified
		
		NotifyDescription = New NotifyDescription("GetWeightEnd", ThisObject, TabularSectionRow);
		EquipmentManagerClient.StartWeightReceivingFromElectronicScales(NOTifyDescription, UUID);
		
	EndIf;
	
EndProcedure // GetWeight()

&AtClient
Procedure GetWeightEnd(Weight, Parameters) Export
	
	TabularSectionRow = Parameters;
	
	If Not Weight = Undefined Then
		If Weight = 0 Then
			MessageText = NStr("ru = 'Электронные весы вернули нулевой вес.';
			|vi = 'Cân điện tử trả lại trọng lượng bằng 0.';
			|en = 'Electronic scales returned zero weight.'");
			CommonUseClientServer.MessageToUser(MessageText);
		Else
			// Weight is received.
			TabularSectionRow.Quantity = Weight;
		EndIf;
	EndIf;
	
EndProcedure

// Procedure - ImportDataFromDTC command handler.
//
&AtClient
Procedure ImportDataFromDCT(Command)
	
	NotificationsAtImportFromDCT = New NotifyDescription("ImportFromDCTEnd", ThisObject);
	EquipmentManagerClient.StartImportDataFromDCT(NotificationsAtImportFromDCT, UUID);
	
EndProcedure // ImportDataFromDCT()

&AtClient
Procedure ImportFromDCTEnd(Result, Parameters) Export
	
	If TypeOf(Result) = Type("Array") 
		AND Result.Count() > 0 Then
		BarcodesReceived(Result);
	EndIf;
	
EndProcedure

// End Peripherals

////////////////////////////////////////////////////////////////////////////////PROCEDURE - FORM EVENT HANDLERS

// Procedure - OnCreateAtServer event handler.
//
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SmallBusinessServer.FillDocumentHeader(
	Object,
	,
	Parameters.CopyingValue,
	Parameters.Basis,
	PostingIsAllowed,
	Parameters.FillingValues
	);
	
	
	// Form attributes setting.
	DocumentDate = Object.Date;
	If Not ValueIsFilled(DocumentDate) Then
		DocumentDate = CurrentDate();
	EndIf;
	
	If Object.Ref.IsEmpty() Then
		FillFormParamaters();
	EndIf; 
	
	If TypeOf(ValueCashe) <> Type("Structure") Then
		
		ValueCashe = New Structure;
		
	EndIf;
	
	SubsidiaryCompany = SmallBusinessServer.GetCompany(Object.Company);
	
	Items.CustomerOrder.ReadOnly = ValueIsFilled(Object.BasisDocument);
	
	FormManagement(ThisObject);
	SetModeAndChoiceList();
	
	SmallBusinessClientServer.SetPictureForComment(Items.GroupAdditional, Object.Comment);
	
	FOInventoryReservation = GetFunctionalOption("InventoryReservation");
	FORetail = GetFunctionalOption("RetailAccounting");
	FOUseCells = GetFunctionalOption("AccountingByCells");
	
	// Ячейки
	If Not ЗначениеЗаполнено(Object.Ref) Then
		ValueCashe.Вставить("AccountingByCells", ПолучитьФункциональнуюОпцию("AccountingByCells"));
		UpdateCellsAvailability();
		FillCellsAvailableAttributes(ThisObject);
	EndIf;
	// Конец Ячейки
	
	// StandardSubsystems.DataImportFromExternalSources
	DataImportFromExternalSources.OnCreateAtServer(Metadata.Documents.InventoryAssembly.TabularSections.Products, DataLoadSettings, ThisObject);
	// End StandardSubsystems.DataImportFromExternalSource
	
	// StandardSubsystems.AdditionalReportsAndDataProcessors
	AdditionalReportsAndDataProcessors.OnCreateAtServer(ThisForm);
	// End StandardSubsystems.AdditionalReportsAndDataProcessors
	
	// StandardSubsystems.Printing
	PrintManagement.OnCreateAtServer(ThisForm, Items.ImportantCommandsGroup);
	// End StandardSubsystems.Printing
	
	// Peripherals.
	UsePeripherals = SmallBusinessReUse.UsePeripherals();
	ListOfElectronicScales = EquipmentManagerServerCall.GetEquipmentList("ElectronicScales", , EquipmentManagerServerCall.GetClientWorkplace());
	If ListOfElectronicScales.Count() = 0 Then
		// There are no connected scales.
		Items.InventoryGetWeight.Visible = False;
	EndIf;
	Items.InventoryImportDataFromDCT.Visible = UsePeripherals;
	// End Peripherals
	
	// Serial numbers
	UseSerialNumbersBalance = WorkWithSerialNumbers.UseSerialNumbersBalance();
	
	If Parameters.Key.IsEmpty() Then
		//НоменклатураВДокументахСервер.ЗаполнитьПризнакиИспользованияХарактеристик(Объект, True);
		FillStagesUsingAttributes();
	EndIf;
	
	// Установка видимости реквизитов от пользовательских настроек
	SetVisibleByUserSettings(ЭтотОбъект); 
	
	UpdateFormStages(ThisObject);
	
	CurrentProduct = -1;
	SetPagePicture(ThisObject);
	
	ManualDistribution = Object.ManualDistribution;
	
	If ManualDistribution Then
		ProductionServer.FillDistributionControlCash(Object, DistributionControlCash);
	EndIf; 
	
	TSNames = New Array;
	TSNames.Add(New Structure("CheckFieldName, AppearanceFieldName", "Object.Products.CountryOfOrigin", "ProductsNumberCCD"));
	TSNames.Add(New Structure("CheckFieldName, AppearanceFieldName", "Object.Inventory.CountryOfOrigin", "InventoryCCDNo"));
	
	CargoCustomsDeclarationsServer.OnCreateAtServer(ThisForm, TSNames, CashValues);
	
	AllowWarehousesInTabularSections = True;
	
EndProcedure // OnCreateAtServer()

// Procedure - OnReadAtServer event handler.
//
&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	FillFormParamaters();
	
	ChangeProhibitionDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	// Ячейки
	If ТипЗнч(ValueCashe) <> Тип("Структура") Then
		ValueCashe = Новый Структура;
	EndIf;
	
	ValueCashe.Вставить("AccountingByCells", ПолучитьФункциональнуюОпцию("AccountingByCells"));
	
	FillStagesUsingAttributes();
	
EndProcedure // OnReadAtServer()

// Procedure - event handler OnOpen.
//
&AtClient
Procedure OnOpen(Cancel)
	
	// Peripherals
	EquipmentManagerClientOverridable.StartConnectingEquipmentOnFormOpen(ThisForm, "BarCodeScanner");
	// End Peripherals
	
	UpdateDicstributionChoiceLists();
	UpdateDistributionHelp();
	
	
EndProcedure // OnOpen()

// Procedure - BeforeWrite event handler.
//
&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	// StandardSubsystems.PerformanceEstimation
	PerformanceEstimationClientServer.StartTimeMeasurement("DocumentInventoryAssemblyPosting");
	// StandardSubsystems.PerformanceEstimation
	
EndProcedure // BeforeWrite()

// Procedure - event handler AfterWriting.
//
&AtClient
Procedure AfterWrite(WriteParameters)
	
	If ValueIsFilled(Object.BasisDocument) Then
		Notify("Record_InventoryAssembly", Object.Ref);
	EndIf;
	
EndProcedure // AfterWrite()

// Procedure - event handler of the form NotificationProcessing.
//
&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If Source = "Peripherals"
		AND IsInputAvailable() Then
		If EventName = "ScanData" Then
			//Transform preliminary to the expected format
			Data = New Array();
			If Parameter[1] = Undefined Then
				Data.Add(New Structure("Barcode, Quantity, CostPercentage", Parameter[0], 1, 1)); // Get a barcode from the basic data
			Else
				Data.Add(New Structure("Barcode, Quantity, CostPercentage", Parameter[1][1], 1, 1)); // Get a barcode from the additional data
			EndIf;
			
			BarcodesReceived(Data);
		EndIf;
	EndIf;
	// End Peripherals
	
	If EventName = "SelectionIsMade" 
		AND ValueIsFilled(Parameter) 
		//Check for the form owner
		AND Source <> New UUID("00000000-0000-0000-0000-000000000000")
		AND Source = UUID
		Then
		
		InventoryAddressInStorage	= Parameter;
		
		If SelectionMarker = "Products" Then
			
			TabularSectionName = "Products";
			
		ElsIf SelectionMarker = "Inventory" Then
			
			TabularSectionName = "Inventory";
			
		ElsIf SelectionMarker = "Disposals" Then
			
			TabularSectionName = "Disposals";
			
		EndIf;
		
		GetInventoryFromStorage(InventoryAddressInStorage, TabularSectionName, True, True);
		
	ElsIf EventName = "SerialNumbersSelection"
		AND ValueIsFilled(Parameter) 
		//Form owner checkup
		AND Source <> New UUID("00000000-0000-0000-0000-000000000000")
		AND Source = UUID
		Then
		
		If Items.Pages.CurrentPage = Items.TSProducts Then
			GetProductsSerialNumbersFromStorage(Parameter.AddressInTemporaryStorage, Parameter.RowKey);
		Else
			GetSerialNumbersInventoryFromStorage(Parameter.AddressInTemporaryStorage, Parameter.RowKey);
		EndIf;
		
	EndIf;
	
EndProcedure // NotificationProcessing()

// Procedure - event handler OnClose.
//
&AtClient
Procedure OnClose()
	
	// Peripherals
	EquipmentManagerClientOverridable.StartDisablingEquipmentOnCloseForm(ThisForm);
	// End Peripherals
	
EndProcedure // OnClose()

////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - ACTIONS OF THE FORM COMMAND PANELS

// Procedure - handler of clicking the FillByBasis button.
//
&AtClient
Procedure FillByBasis(Command)
	
	Response = Undefined;
	
	
	ShowQueryBox(New NotifyDescription("FillByBasisEnd", ThisObject), NStr("ru = 'Документ будет полностью перезаполнен по ""Основанию""! Продолжить?';
	|vi = 'Chứng từ sẽ được điền lại toàn bộ theo ""Cơ sở""! Tiếp tục?';
	|en = 'The  document will be fully filled out according to the ""Basis"". Continue?'"), QuestionDialogMode.YesNo, 0);
	
EndProcedure

&AtClient
Procedure FillByBasisEnd(Result, AdditionalParameters) Export
	
	Response = Result;
	If Response = DialogReturnCode.Yes Then
		
		FillByDocument("ProductionOrder");
		
		If Object.OperationKind = PredefinedValue("Enum.OperationKindsInventoryAssembly.Disassembly") Then
			
			If Not ValueIsFilled(Object.CustomerOrder) Then
				
				For Each StringInventory IN Object.Products Do
					StringInventory.Reserve = 0;
				EndDo;
				Items.Products.ChildItems.ProductsReserve.Visible = False;
				
			Else
				
				If Items.Products.ChildItems.ProductsReserve.Visible = False Then
					Items.Products.ChildItems.ProductsReserve.Visible = True;
				EndIf;
				
			EndIf;
			
		Else
			
			If Not ValueIsFilled(Object.CustomerOrder) Then
				
				For Each StringInventory IN Object.Inventory Do
					StringInventory.Reserve = 0;
				EndDo;
				Items.Inventory.ChildItems.InventoryReserve.Visible = False;
				Items.InventoryChangeReserve.Visible = False;
				ReservationUsed = False;
				
			Else
				
				If Items.Inventory.ChildItems.InventoryReserve.Visible = False Then
					Items.Inventory.ChildItems.InventoryReserve.Visible = True;
					Items.InventoryChangeReserve.Visible = True;
					ReservationUsed = True;
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure  // FillByBasis()

// Procedure - handler of the  FillUsingCustomerOrder click button.
//
&AtClient
Procedure FillUsingCustomerOrder(Command)
	
	Response = Undefined;
	
	
	ShowQueryBox(New NotifyDescription("FillByCustomerOrderEnd", ThisObject), NStr("ru = 'Документ будет полностью перезаполнен по ""Заказу покупателя""! Продолжить выполнение операции?';
	|vi = 'Chứng từ sẽ được điền lại toàn bộ theo ""Đơn hàng của khách""! Tiếp tục thực hiện thao tác?';
	|en = 'The document will be completely refilled according to ""Customer order""! Continue?'"), QuestionDialogMode.YesNo, 0);
	
EndProcedure

&AtClient
Procedure FillByCustomerOrderEnd(Result, AdditionalParameters) Export
	
	Response = Result;
	If Response = DialogReturnCode.Yes Then
		FillByDocument("CustomerOrder");
	EndIf;
	
EndProcedure // FillByCustomerOrder()

// Procedure - command handler FillByReserve of the ChangeReserve submenu.
//
&AtClient
Procedure ChangeReserveFillByReserves(Command)
	
	If Object.Inventory.Count() = 0 Then
		Message = New UserMessage;
		Message.Text = NStr("ru = 'Табличная часть ""Запасы и услуги"" не заполнена!';
		|vi = 'Phần bảng ""Vật tư và dịch vụ"" chưa điền!';
		|en = 'The ""Inventory and services"" tabular section is not filled in.'");
		Message.Message();
		Return;
	EndIf;
	
	FillColumnReserveByReservesAtServer();
	
EndProcedure // ChangeReserveFillByReserves()

// Procedure - command handler ClearReserve of the ChangeReserve submenu.
//
&AtClient
Procedure ChangeReserveClearReserve(Command)
	
	If Object.Inventory.Count() = 0 Then
		Message = New UserMessage;
		Message.Text = NStr("ru = 'Табличная часть ""Запасы и услуги"" не заполнена!';
		|vi = 'Phần bảng ""Vật tư và dịch vụ"" chưa điền!';
		|en = 'The ""Inventory and services"" tabular section is not filled in.'");
		Message.Message();
		Return;
	EndIf;
	
	For Each TabularSectionRow IN Object.Inventory Do
		TabularSectionRow.Reserve = 0;
	EndDo;
	
EndProcedure // ChangeReserveFillByBalances()

////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - EVENT HANDLERS OF HEADER ATTRIBUTES

// Procedure - event handler OnChange of the Date input field.
// The procedure determines the situation when after changing the date
// of a document this document is found in another period
// of documents enumeration, and in this case the procedure assigns new unique number to the document.
// Overrides the corresponding form parameter.
//
&AtClient
Procedure DateOnChange(Item)
	
	// Date change event DataProcessor.
	DateBeforeChange = DocumentDate;
	DocumentDate = Object.Date;
	If Object.Date <> DateBeforeChange Then
		StructureData = GetDataDateOnChange(Object.Ref, Object.Date, DateBeforeChange);
		If StructureData.DATEDIFF <> 0 Then
			Object.Number = "";
		EndIf;
	EndIf;
	
EndProcedure // DateOnChange()

// Procedure - event handler OnChange of the Company input field.
// IN procedure the document number
// is cleared, and also the form functional options are configured.
// Overrides the corresponding form parameter.
//
&AtClient
Procedure CompanyOnChange(Item)
	
	// Company change event data processor.
	Object.Number = "";
	StructureData = GetCompanyDataOnChange(Object.Company);
	Counterparty = StructureData.Counterparty;
	
EndProcedure // CompanyOnChange()

// Procedure - handler of the OnChange event of the BasisDocument input field.
//
&AtClient
Procedure BasisDocumentOnChange(Item)
	
	FormManagement(ThisObject);
	
	
EndProcedure // BasisDocumentOnChange()

// Procedure - handler of the OnChange event of the CustomerOrder input field.
//
&AtClient
Procedure CustomerOrderOnChange(Item)
	
	If Object.OperationKind = PredefinedValue("Enum.OperationKindsInventoryAssembly.Disassembly") Then
		
		Items.ProductsReserve.Visible = ValueIsFilled(Object.CustomerOrder);
		
		For Each StringProducts IN Object.Products Do
			StringProducts.Reserve = 0;
		EndDo;
		
	Else
		
		Items.InventoryReserve.Visible = ValueIsFilled(Object.CustomerOrder);
		Items.InventoryChangeReserve.Visible = ValueIsFilled(Object.CustomerOrder);
		
		For Each StringInventory IN Object.Inventory Do
			StringInventory.Reserve = 0;
		EndDo;
		
		ReservationUsed = ValueIsFilled(Object.CustomerOrder);
		
	EndIf;
	
	StageVisibleControl(ThisObject);
	
EndProcedure // CustomerOrderOnChange()

// Procedure - event handler OnChange of the OperationKind input field.
//
&AtClient
Procedure OperationKindOnChange(Item)
	
	FormManagement(ThisObject);
	
EndProcedure // OperationKindOnChange()

// Procedure - OnChange event handler of the Comment input field.
//
&AtClient
Procedure CommentOnChange(Item)
	
	AttachIdleHandler("Attachable_SetPictureForComment", 0.5, True);
	
EndProcedure // CommentOnChange()

&AtClient
Procedure Attachable_SetPictureForComment()
	
	SmallBusinessClientServer.SetPictureForComment(Items.GroupAdditional, Object.Comment);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Structural unit - MANUFACTURER

// Procedure - event handler OnChange of the StructuralUnit input field.
//
&AtClient
Procedure StructuralUnitOnChange(Item)
	
	If ValueIsFilled(Object.StructuralUnit) Then
		
		StructureData = New Structure();
		StructureData.Insert("Department", Object.StructuralUnit);
		
		StructureData = GetDataStructuralUnitOnChange(StructureData);
		
		Items.Cell.Enabled = StructureData.OrderWarehouse;
		
		If ValueIsFilled(StructureData.ProductsStructuralUnit) Then
			Object.ProductsStructuralUnit = StructureData.ProductsStructuralUnit;
			Object.ProductsCell = StructureData.ProductsCell;
			Items.ProductsCellAssembling.Enabled = StructureData.OrderWarehouseOfProducts;
			Items.ProductsCellDisassembling.Enabled = StructureData.OrderWarehouseOfProducts;
			
		Else
			Object.ProductsStructuralUnit = Object.StructuralUnit;
			Object.ProductsCell = Object.Cell;
			Items.ProductsCellAssembling.Enabled = StructureData.OrderWarehouse;
			Items.ProductsCellDisassembling.Enabled = StructureData.OrderWarehouse;
			
		EndIf;
		
		If ValueIsFilled(StructureData.InventoryStructuralUnit) Then
			Object.InventoryStructuralUnit = StructureData.InventoryStructuralUnit;
			Object.CellInventory = StructureData.CellInventory;
			Items.CellInventoryAssembling.Enabled = StructureData.OrderWarehouseOfInventory;
			Items.CellInventoryDisassembling.Enabled = StructureData.OrderWarehouseOfInventory;
			
		Else
			Object.InventoryStructuralUnit = Object.StructuralUnit;
			Object.CellInventory = Object.Cell;
			Items.CellInventoryAssembling.Enabled = StructureData.OrderWarehouse;
			Items.CellInventoryDisassembling.Enabled = StructureData.OrderWarehouse;
			
		EndIf;
		
		If ValueIsFilled(StructureData.DisposalsStructuralUnit) Then
			Object.DisposalsStructuralUnit = StructureData.DisposalsStructuralUnit;
			Object.DisposalsCell = StructureData.DisposalsCell;
			Items.DisposalsCell.Enabled = StructureData.OrderWarehouseWaste;
			
		Else
			Object.DisposalsStructuralUnit = Object.StructuralUnit;
			Object.DisposalsCell = Object.Cell;
			Items.DisposalsCell.Enabled = StructureData.OrderWarehouse;
			
		EndIf;
		
	Else
		
		Items.Cell.Enabled = False;
		
	EndIf;
	
EndProcedure // StructuralUnitOnChange()

// Procedure - event handler Field opening StructuralUnit.
//
&AtClient
Procedure StructuralUnitOpening(Item, StandardProcessing)
	
	If Items.StructuralUnit.ListChoiceMode
		AND Not ValueIsFilled(Object.StructuralUnit) Then
		
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure // StructuralUnitOpening()

// Procedure - OnChange event handler of the Cell input field.
//
&AtClient
Procedure CellOnChange(Item)
	
	StructureData = New Structure();
	StructureData.Insert("StructuralUnit", Object.StructuralUnit);
	StructureData.Insert("Cell", Object.Cell);
	StructureData.Insert("ProductsStructuralUnit", Object.ProductsStructuralUnit);
	StructureData.Insert("ProductsCell", Object.ProductsCell);
	StructureData.Insert("InventoryStructuralUnit", Object.InventoryStructuralUnit);
	StructureData.Insert("CellInventory", Object.CellInventory);
	StructureData.Insert("DisposalsStructuralUnit", Object.DisposalsStructuralUnit);
	StructureData.Insert("DisposalsCell", Object.DisposalsCell);
	
	StructureData = GetDataCellOnChange(StructureData);
	
	If StructureData.Property("NewGoodsCell") Then
		Object.ProductsCell = StructureData.NewGoodsCell;
	EndIf;
	
	If StructureData.Property("NewCellInventory") Then
		Object.CellInventory = StructureData.NewCellInventory;
	EndIf;
	
	If StructureData.Property("NewCellWastes") Then
		Object.DisposalsCell = StructureData.NewCellWastes;
	EndIf;
	
EndProcedure // CellOnChange()

////////////////////////////////////////////////////////////////////////////////
// Structural unit - PRODUCTION (RECIPIENT - ASSEMBLY)

// Procedure - OnChange event handler of the ProductsStructuralUnitAssembling input field.
//
&AtClient
Procedure ProductsStructuralUnitAssemblingOnChange(Item)
	
	If Not ValueIsFilled(Object.ProductsStructuralUnit) Then
		
		Items.ProductsCellAssembling.Enabled = False;
		
	Else
		
		StructureData = New Structure();
		StructureData.Insert("Warehouse", Object.ProductsStructuralUnit);
		
		StructureData = GetDataStructuralUnitProductsInventoryDisposalsOnChange(StructureData);
		
		Items.ProductsCellAssembling.Enabled = StructureData.OrderWarehouse;
		
	EndIf;
	
EndProcedure // ProductsStructuralUnitAssemblingOnChange()

// Procedure - Open event handler of ProductsStructuralUnitAssembling field.
//
&AtClient
Procedure StructuralUnitOfProductAssemblyOpening(Item, StandardProcessing)
	
	If Items.ProductsStructuralUnitAssembling.ListChoiceMode
		AND Not ValueIsFilled(Object.ProductsStructuralUnit) Then
		
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure // StructuralUnitOfProductAssemblyOpening()

////////////////////////////////////////////////////////////////////////////////
// Structural unit - PRODUCTS (WRITE OFF FROM - DISASSEMBLY)

// Procedure - OnChange event handler of the ProductsStructuralUnitDisassembling input field.
//
&AtClient
Procedure ProductsStructuralUnitDisassemblingOnChange(Item)
	
	If Not ValueIsFilled(Object.InventoryStructuralUnit) Then
		
		Items.ProductsCellDisassembling.Enabled = False;
		
	Else
		
		StructureData = New Structure();
		StructureData.Insert("Warehouse", Object.InventoryStructuralUnit);
		
		StructureData = GetDataStructuralUnitProductsInventoryDisposalsOnChange(StructureData);
		
		Items.ProductsCellDisassembling.Enabled = StructureData.OrderWarehouse;
		
	EndIf;
	
EndProcedure // ProductsStructuralUnitDisassemblingOnChange()

// Procedure - Open event handler of ProductsStructuralUnitDisassembling field.
//
&AtClient
Procedure ProductsStructuralUnitDisassemblingOpen(Item, StandardProcessing)
	
	If Items.ProductsStructuralUnitDisassembling.ListChoiceMode
		AND Not ValueIsFilled(Object.InventoryStructuralUnit) Then
		
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure // ProductsStructuralUnitDisassemblingOpen()

////////////////////////////////////////////////////////////////////////////////
// Structural unit - INVENTORY (WRITE OFF FROM - ASSEMBLY)

// Procedure - OnChange event handler of the InventoryStructuralUnitAssembling input field.
//
&AtClient
Procedure InventoryStructuralUnitAssemblingOnChange(Item)
	
	If Not ValueIsFilled(Object.InventoryStructuralUnit) Then
		
		Items.CellInventoryAssembling.Enabled = False;
		
	Else
		
		StructureData = New Structure();
		StructureData.Insert("Warehouse", Object.InventoryStructuralUnit);
		
		StructureData = GetDataStructuralUnitProductsInventoryDisposalsOnChange(StructureData);
		
		Items.CellInventoryAssembling.Enabled = StructureData.OrderWarehouse;
		
	EndIf;
	
EndProcedure // InventoryStructuralUnitAssemblingOnChange()

// Procedure - Open event handler of InventoryStructuralUnitAssembling field.
//
&AtClient
Procedure InventoryStructuralUnitInAssemblingOpen(Item, StandardProcessing)
	
	If Items.InventoryStructuralUnitAssembling.ListChoiceMode
		AND Not ValueIsFilled(Object.InventoryStructuralUnit) Then
		
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure // InventoryStructuralUnitInAssemblingOpen()

////////////////////////////////////////////////////////////////////////////////
// Structural unit - INVENTORY (RECIPIENT - DISASSEMBLY)

// Procedure - OnChange event handler of the InventoryStructuralUnitDisassembling input field.
//
&AtClient
Procedure InventoryStructuralUnitDisassemblyOnChange(Item)
	
	If Not ValueIsFilled(Object.ProductsStructuralUnit) Then
		
		Items.CellInventoryDisassembling.Enabled = False;
		
	Else
		
		StructureData = New Structure();
		StructureData.Insert("Warehouse", Object.ProductsStructuralUnit);
		
		StructureData = GetDataStructuralUnitProductsInventoryDisposalsOnChange(StructureData);
		
		Items.CellInventoryDisassembling.Enabled = StructureData.OrderWarehouse;
		
	EndIf;
	
EndProcedure // InventoryStructuralUnitDisassemblyOnChange()

// Procedure - Handler of event Opening InventoryStructuralUnitDisassembling field.
//
&AtClient
Procedure InventoryStructuralUnitDisassemblyOpening(Item, StandardProcessing)
	
	If Items.InventoryStructuralUnitDisassembling.ListChoiceMode
		AND Not ValueIsFilled(Object.ProductsStructuralUnit) Then
		
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure // InventoryStructuralUnitDisassemblyOpening()

////////////////////////////////////////////////////////////////////////////////
// Structural unit - Recipient

// Procedure - OnChange event handler of the DisposalsStructuralUnit input field.
//
&AtClient
Procedure DisposalsStructuralUnitOnChange(Item)
	
	If Not ValueIsFilled(Object.DisposalsStructuralUnit) Then
		
		Items.DisposalsCell.Enabled = False;
		
	Else
		
		StructureData = New Structure();
		StructureData.Insert("Warehouse", Object.DisposalsStructuralUnit);
		
		StructureData = GetDataStructuralUnitProductsInventoryDisposalsOnChange(StructureData);
		
		Items.DisposalsCell.Enabled = StructureData.OrderWarehouse;
		
	EndIf;
	
EndProcedure // DisposalsStructuralUnitOnChange()

// Procedure - Open event handler of DisposalsStructuralUnit field.
//
&AtClient
Procedure DisposalsStructuralUnitOpening(Item, StandardProcessing)
	
	If Items.DisposalsStructuralUnit.ListChoiceMode
		AND Not ValueIsFilled(Object.DisposalsStructuralUnit) Then
		
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure // DisposalsStructuralUnitOpening()

////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - FORM TABULAR SECTIONS COMMAND PANELS ACTIONS

// Procedure - command handler of the tabular section command panel.
//
&AtClient
Procedure CommandFillBySpecification(Command)
	
	If Object.Inventory.Count() <> 0 Then
		
		Response = Undefined;
		
		
		ShowQueryBox(New NotifyDescription("CommandToFillBySpecificationEnd", ThisObject), NStr("ru = 'Табличная часть ""Материалы"" будет перезаполнена! Продолжить?';
		|vi = 'Phần bảng ""Nguyên vật liệu"" sẽ được điền lại! Tiếp tục?';
		|en = 'Tabular section ""Materials"" will be filled in again. Continue?'"), 
		QuestionDialogMode.YesNo, 0);
		Return;
		
	EndIf;
	
	CommandToFillBySpecificationFragment();
EndProcedure

&AtClient
Procedure CommandToFillBySpecificationEnd(Result, AdditionalParameters) Export
	
	Response = Result;
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	
	CommandToFillBySpecificationFragment();
	
EndProcedure

&AtClient
Procedure CommandToFillBySpecificationFragment()
	
	FillBySpecificationsAtServer();
	
EndProcedure // CommandFillBySpecification()

////////////////////////////////////////////////////////////////////////////////PROCEDURE - EVENT HANDLERS OF THE PRODUCTS TABULAR SECTION ATTRIBUTES

// Procedure - event handler OnChange of the ProductsAndServices input field.
//
&AtClient
Procedure ProductsProductsAndServicesOnChange(Item)
	
	TabularSectionRow = Items.Products.CurrentData;
	
	StructureData = New Structure;
	StructureData.Insert("ProductsAndServices", TabularSectionRow.ProductsAndServices);
	
	StructureData = GetDataProductsAndServicesOnChange(StructureData);
	
	TabularSectionRow.MeasurementUnit = StructureData.MeasurementUnit;
	TabularSectionRow.Quantity = 1;
	TabularSectionRow.Specification = StructureData.Specification;
	TabularSectionRow.CountryOfOrigin = StructureData.CountryOfOrigin;
	
	//Serial numbers
	WorkWithSerialNumbersClientServer.DeleteSerialNumbersByConnectionKey(Object.SerialNumbersProducts, TabularSectionRow, , UseSerialNumbersBalance);
	
	If Object.OperationKind=ПредопределенноеЗначение("Enum.OperationKindsInventoryAssembly.Disassembly") Then
		If NOT WarehouseInHeader Then
			FillWarehouseInventoryTS(TabularSectionRow, Object, StructureData);
		Else
			TabularSectionRow.StructuralUnit = Object.InventoryStructuralUnit;
			TabularSectionRow.Cell = Object.CellInventory;
		EndIf;
		TabularSectionRow.CellAvailable = CellAvailable(TabularSectionRow.StructuralUnit);
	EndIf; 
	
	
	If ValueIsFilled(TabularSectionRow.Specification) И Object.Inventory.Count()>0 Then
		SetPagePicture(ThisObject, False);
	EndIf;
	
	UpdateDicstributionChoiceLists();
	
	ClearCompletedStages(TabularSectionRow);
	StageVisibleControl(ThisObject);
	
EndProcedure // ProductsProductsAndServicesOnChange()

// Procedure - event handler OnChange of the Characteristic input field.
//
&AtClient
Procedure ProductsCharacteristicOnChange(Item)
	
	TabularSectionRow = Items.Products.CurrentData;
	
	StructureData = New Structure;
	StructureData.Insert("ProductsAndServices", TabularSectionRow.ProductsAndServices);
	StructureData.Insert("Characteristic", TabularSectionRow.Characteristic);
	
	StructureData = GetDataCharacteristicOnChange(StructureData);
	
	TabularSectionRow.Specification = StructureData.Specification;
	
EndProcedure // ProductsCharacteristicOnChange()

////////////////////////////////////////////////////////////////////////////////PROCEDURE - EVENT HANDLERS OF THE INVENTORY TABULAR SECTION ATTRIBUTES

// Procedure - event handler OnChange of the ProductsAndServices input field.
//
&AtClient
Procedure InventoryProductsAndServicesOnChange(Item)
	
	TabularSectionRow = Items.Inventory.CurrentData;
	
	StructureData = New Structure();
	StructureData.Insert("ProductsAndServices", TabularSectionRow.ProductsAndServices);
	
	StructureData = GetDataProductsAndServicesOnChange(StructureData);
	
	TabularSectionRow.MeasurementUnit = StructureData.MeasurementUnit;
	TabularSectionRow.Specification = StructureData.Specification;
	TabularSectionRow.Quantity = 1;
	TabularSectionRow.CostPercentage = 1;
	TabularSectionRow.CountryOfOrigin = StructureData.CountryOfOrigin;
	
	//Serial numbers
	WorkWithSerialNumbersClientServer.DeleteSerialNumbersByConnectionKey(Object.SerialNumbers, TabularSectionRow, , UseSerialNumbersBalance);
	
EndProcedure // InventoryProductsAndServicesOnChange()

&AtClient
Procedure InventoryQuantityOnChange(Item)
	
	// Serial numbers
	If UseSerialNumbersBalance <> Undefined Then
		WorkWithSerialNumbersClientServer.UpdateSerialNumbersQuantity(Object, Items.Inventory.CurrentData);
	EndIf;
	
EndProcedure

&AtClient
Procedure InventoryBeforeDeleteRow(Item, Cancel)
	
	// Serial numbers
	CurrentData = Items.Inventory.CurrentData;
	WorkWithSerialNumbersClientServer.DeleteSerialNumbersByConnectionKey(Object.SerialNumbers, CurrentData, , UseSerialNumbersBalance);
	
EndProcedure

&AtClient
Procedure InventoryOnStartEdit(Item, NewRow, Clone)
	
	If NewRow AND Clone Then
		Item.CurrentData.ConnectionKey = 0;
		Item.CurrentData.SerialNumbers = "";
	EndIf;
	
	If Item.CurrentItem.Name = "InventorySerialNumbers" Then
		OpenSerialNumbersSelection("Inventory", "SerialNumbers");
	EndIf;
	
EndProcedure

&AtClient
Procedure InventorySerialNumbersStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSerialNumbersSelection("Inventory", "SerialNumbers");
	
EndProcedure

&AtClient
Procedure ProductsQuantityOnChange(Item)
	
	// Serial numbers
	If UseSerialNumbersBalance<>Undefined Then
		WorkWithSerialNumbersClientServer.UpdateSerialNumbersQuantity(Object, Items.Products.CurrentData, "SerialNumbersProducts");
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsBeforeDeleteRow(Item, Cancel)
	
	// Serial numbers
	CurrentData = Items.Products.CurrentData;
	WorkWithSerialNumbersClientServer.DeleteSerialNumbersByConnectionKey(Object.SerialNumbersProducts, CurrentData,  ,UseSerialNumbersBalance);
	
EndProcedure

&AtClient
Procedure ProductsOnStartEdit(Item, NewRow, Clone)
	
	If NewRow AND Clone Then
		Item.CurrentData.ConnectionKey = 0;
		Item.CurrentData.SerialNumbers = "";
	EndIf;
	
	If Item.CurrentItem.Name = "ProductsSerialNumbers" Then
		OpenSerialNumbersSelection("Products","SerialNumbersProducts");
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsSerialNumbersStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSerialNumbersSelection("Products","SerialNumbersProducts");
	
EndProcedure

// Procedure - event handler OnChange of the Characteristic input field.
//
&AtClient
Procedure InventoryCharacteristicOnChange(Item)
	
	TabularSectionRow = Items.Inventory.CurrentData;
	
	StructureData = New Structure;
	StructureData.Insert("ProductsAndServices", TabularSectionRow.ProductsAndServices);
	StructureData.Insert("Characteristic", TabularSectionRow.Characteristic);
	
	StructureData = GetDataCharacteristicOnChange(StructureData);
	
	TabularSectionRow.Specification = StructureData.Specification;
	
EndProcedure // InventoryCharacteristicOnChange()

////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - EVENT HANDLERS OF THE DISPOSALS TABULAR SECTION ATTRIBUTES

// Procedure - event handler OnChange of the ProductsAndServices input field.
//
&AtClient
Procedure DisposalsProductsAndServicesOnChange(Item)
	
	TabularSectionRow = Items.Disposals.CurrentData;
	
	StructureData = New Structure();
	StructureData.Insert("ProductsAndServices", TabularSectionRow.ProductsAndServices);
	
	StructureData = GetDataProductsAndServicesOnChange(StructureData);
	
	TabularSectionRow.MeasurementUnit = StructureData.MeasurementUnit;
	TabularSectionRow.Quantity = 1;
	
EndProcedure // DisposalsProductsAndServicesOnChange()

#Region DataImportFromExternalSources

&AtClient
Procedure LoadFromFileGoods(Command)
	
	NotifyDescription = New NotifyDescription("ImportDataFromExternalSourceResultDataProcessor", ThisObject, DataLoadSettings);
	
	DataLoadSettings.Insert("TabularSectionFullName",	"Production.Products");
	DataLoadSettings.Insert("Title",					NStr("en='Import goods from file';ru='Загрузка товаров из файла';vi='Kết nhập mặt hàng từ tệp'"));
	
	DataImportFromExternalSourcesClient.ShowDataImportFormFromExternalSource(DataLoadSettings, NotifyDescription, ThisObject);
	
EndProcedure

&AtClient
Procedure ImportDataFromExternalSourceResultDataProcessor(ImportResult, AdditionalParameters) Export
	
	If TypeOf(ImportResult) = Type("Structure") Then
		ProcessPreparedData(ImportResult);
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessPreparedData(ImportResult)
	
	DataImportFromExternalSourcesOverridable.ImportDataFromExternalSourceResultDataProcessor(ImportResult, Object);
	
EndProcedure

#EndRegion

#Region LibrariesHandlers

// StandardSubsystems.AdditionalReportsAndDataProcessors
&AtClient
Procedure Attachable_ExecuteAssignedCommand(Command)
	If Not AdditionalReportsAndDataProcessorsClient.ExecuteAllocatedCommandAtClient(ThisForm, Command.Name) Then
		ExecutionResult = Undefined;
		AdditionalReportsAndProcessingsExecuteAllocatedCommandAtServer(Command.Name, ExecutionResult);
		AdditionalReportsAndDataProcessorsClient.ShowCommandExecutionResult(ThisForm, ExecutionResult);
	EndIf;
EndProcedure

&AtServer
Procedure AdditionalReportsAndProcessingsExecuteAllocatedCommandAtServer(ItemName, ExecutionResult)
	AdditionalReportsAndDataProcessors.ExecuteAllocatedCommandAtServer(ThisForm, ItemName, ExecutionResult);
EndProcedure
// End StandardSubsystems.AdditionalReportsAndDataProcessors

// StandardSubsystems.Printing
&AtClient
Procedure Attachable_ExecutePrintCommand(Command)
	PrintManagementClient.ExecuteConnectedPrintCommand(Command, ThisObject, Object);
EndProcedure

// End StandardSubsystems.Printing

#EndRegion

#Region ServiceProceduresAndFunctions


&AtServerNoContext
Procedure FillSpecificationDataOnChange(StructureData)
	
	If GetFunctionalOption("UseProductionStages")
		And ValueIsFilled(StructureData.Specification)
		And TypeOf(StructureData.Specification) = Type("CatalogRef.Specifications") Then
		ProductionKind = CommonUse.ObjectAttributeValue(StructureData.Specification, "ProductionKind");
		StructureData.Insert("UseProductionStages", ValueIsFilled(ProductionKind));
	Else
		StructureData.Insert("UseProductionStages", False);
	EndIf;
	
EndProcedure 

&AtClient
Procedure OpenSerialNumbersSelection(NameTSInventory, TSNameSerialNumbers)
	
	CurrentDataIdentifier = Items[NameTSInventory].CurrentData.GetID();
	ParametersOfSerialNumbers = SerialNumberPickParameters(CurrentDataIdentifier, NameTSInventory, TSNameSerialNumbers);
	// Using field InventoryStructuralUnit for SN selection
	ParametersOfSerialNumbers.Insert("StructuralUnit", Object.InventoryStructuralUnit);
	OpenForm("DataProcessor.SerialNumbersSelection.Form", ParametersOfSerialNumbers, ThisObject);
	
EndProcedure

&AtServer
Function GetSerialNumbersInventoryFromStorage(AddressInTemporaryStorage, RowKey)
	
	ParametersFieldNames = New Structure;
	ParametersFieldNames.Insert("NameTSInventory", "Inventory");
	ParametersFieldNames.Insert("TSNameSerialNumbers", "SerialNumbers");
	
	Return WorkWithSerialNumbers.GetSerialNumbersFromStorage(Object, AddressInTemporaryStorage, RowKey, ParametersFieldNames);
	
EndFunction

&AtServer
Function GetProductsSerialNumbersFromStorage(AddressInTemporaryStorage, RowKey)
	
	ParametersFieldNames = New Structure;
	ParametersFieldNames.Insert("NameTSInventory", "Products");
	ParametersFieldNames.Insert("TSNameSerialNumbers", "SerialNumbersProducts");
	
	Return WorkWithSerialNumbers.GetSerialNumbersFromStorage(Object, AddressInTemporaryStorage, RowKey, ParametersFieldNames);
	
EndFunction

&AtServer
Function SerialNumberPickParameters(CurrentDataIdentifier, TSName, TSNameSerialNumbers)
	
	If TSName = "Inventory" AND Object.OperationKind = PredefinedValue("Enum.OperationKindsInventoryAssembly.Assembly") Then
		PickMode = True;
	ElsIf TSName = "Products" AND Object.OperationKind = PredefinedValue("Enum.OperationKindsInventoryAssembly.Disassembly") Then
		PickMode = True;
	Else
		PickMode = False;
	EndIf;
	
	Return WorkWithSerialNumbers.SerialNumberPickParameters(Object, ThisObject.UUID, CurrentDataIdentifier, PickMode, TSName, TSNameSerialNumbers);
	
EndFunction

&AtClient
Procedure ProductsStagesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.Products.CurrentData;
	If Not ValueIsFilled(CurrentData.Specification)
		Or (Not ValueIsFilled(Object.ProductionOrder) And Not ProductionByOrder(CurrentData)) Then
		MessageText = NStr("en = 'In manufacturing %1, no production steps are used'; vi = 'Trong sản xuất %1, không có bước sản xuất nào được sử dụng'");
		CommonUseClientServer.MessageToUser(StrTemplate(MessageText, CurrentData.ProductsAndServices));
		Return;
	EndIf;
	
	ConnectionKey = CurrentData.ConnectionKey;
	If ConnectionKey=0 Then
		TabularSectionName = "Products";
		SmallBusinessClient.AddConnectionKeyToTabularSectionLine(ThisObject);
		ConnectionKey = CurrentData.ConnectionKey;
	EndIf; 
	
	StagesArray = New Array;
	FilterStructure = New Structure;
	FilterStructure.Insert("ConnectionKey", ConnectionKey);
	Rows = Object.CompletedStages.FindRows(FilterStructure);
	For Each TabSecRow In Rows Do
		StagesArray.Add(TabSecRow.Stage);
	EndDo;
	
	OpenStructure = New Structure;
	OpenStructure.Insert("ConnectionKey", ConnectionKey);
	OpenStructure.Insert("CompletedStages", StagesArray);
	OpenStructure.Insert("Specification", CurrentData.Specification);
	OpenForm("Документ.InventoryAssembly.Form.CompletedStages", OpenStructure, Item, , , , , FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Function ProductionByOrder(TabularSectionRow)
	
	If Object.CustomerOrderPosition=PredefinedValue("Enum.AttributePositionOnForm.InTabularSection") And ValueIsFilled(TabularSectionRow.CustomerOrder) Then
		return True;
	ElsIf Object.CustomerOrderPosition<>PredefinedValue("Enum.AttributePositionOnForm.InTabularSection") And ValueIsFilled(Object.CustomerOrder) Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

&AtClient
Procedure ProductsStagesChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	If TypeOf(SelectedValue)<>Type("Structure") Then
		Return;
	EndIf;
	
	If Not SelectedValue.Property("ConnectionKey")
		Or Not SelectedValue.Property("CompletedStages ") Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	FilterStructure = New Structure;
	FilterStructure.Insert("ConnectionKey", SelectedValue.ConnectionKey);
	Rows = Object.CompletedStages.FindRows(FilterStructure);
	For Each TabSecRow In Rows Do
		Object.CompletedStages.Delete(TabSecRow);
	EndDo; 
	
	For Each Stage In SelectedValue.CompletedStages Do
		NewRow = Object.CompletedStages.Add();
		NewRow.ConnectionKey = SelectedValue.ConnectionKey;
		NewRow.Stage = Stage;
	EndDo;
	
	UpdateFormStages(ThisObject);
	SetPagePicture(ThisObject, False);
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateFormStages(Form)
	
	FormParameters = Form.FormParameters;
	If Not FormParameters.UseProductionStages Then
		Return;
	EndIf;
	
	Object = Form.Object;
	
	If Object.OperationKind<>PredefinedValue("Enum.OperationKindsInventoryAssembly.Assembly") Then
		Return;
	EndIf; 
	
	For Each TabSecRow In Object.Products Do
		FilterStructure = New Structure;
		FilterStructure.Insert("ConnectionKey", TabSecRow.ConnectionKey);
		RowsStages = Object.CompletedStages.FindRows(FilterStructure);
		TabSecRow.Stages = "";
		For Each RowStage In RowsStages Do
			TabSecRow.Stages = TabSecRow.Stages + ?(IsBlankString(TabSecRow.Stages), "", "; ") + String(RowStage.Stage);
		EndDo;
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetPagePicture(Form, Filled = Undefined, Distributed = Undefined)
	
	Object = Form.Object;
	Items = Form.Items;
	
	If Filled <> (Not Form.InventoryNotFilled) Then
		If Filled <> Undefined Then
			Form.InventoryNotFilled = Not Filled;
		EndIf;
		CommonUseClientServer.SetFormItemProperty(Items, "TSInventory", "Picture", ?(Form.InventoryNotFilled, PictureLib.AttentionInTriangle, New Picture));
	EndIf; 	
	
	If Not Object.ManualDistribution Then
		Form.InventoryNotDistributed = False;
		CommonUseClientServer.SetFormItemProperty(Items, "TSDistribution", "Picture", New Picture);
	ElsIf Distributed <> (Not Form.InventoryNotDistributed) Then
		If Distributed <> Undefined Then
			Form.InventoryNotDistributed = Not Distributed;
		EndIf;
		CommonUseClientServer.SetFormItemProperty(Items, "TSDistribution", "Picture", ?(Form.InventoryNotDistributed, PictureLib.AttentionInTriangle, New Picture));
	EndIf;
	
	CommonUseClientServer.SetFormItemProperty(Items, "GroupAttentionInventory", "Visible", Form.InventoryNotFilled);
	CommonUseClientServer.SetFormItemProperty(Items, "GroupAttentionDistribution", "Visible", Form.InventoryNotDistributed);
	
EndProcedure

&AtClient
Procedure InventoryDistributionOnActivateRow(Item)
	
	UpdateDistributionHelpText();
	
EndProcedure

&AtClient
Procedure UpdateDistributionHelpText()
	
	DescriptionTextDistributionErrors = "";
	
	CurrentRow = Items.InventoryDistribution.CurrentData;
	If CurrentRow=Undefined Then
		DescriptionTextDistributionErrors = NStr("en='The distribution result does not match the data on materials and / or products.';ru='Результат распределения не соответствует данным о материалах и/или продукции.';vi='Kết quả phân bổ không khớp với dữ liệu trên vật liệu và / hoặc sản phẩm.'");
		Return;
	ElsIf ValueIsFilled(CurrentRow.ProductsAndServicesProduction) And Not CurrentRow.ErrorQuantity Then
		DescriptionTextDistributionErrors = NStr("en='The distribution result does not match the data on materials and / or products. For details, highlight the warning line.';ru='Результат распределения не соответствует данным о материалах и/или продукции. Для подробной информации выделите строку с предупреждением.';vi='Kết quả phân bổ không tương ứng với dữ liệu về nguyên vật liệu và/hoặc sản phẩm. Để xem thêm chi tiết, hãy chọn dòng cảnh báo.'");
		Return;
	EndIf;
	
	FilterStructure = New Structure(InventoryColumnsName(Object));
	FillPropertyValues(FilterStructure, CurrentRow);
	TotalStructure = InventoryTotal(FilterStructure);
	MeasurementUnt = String(FilterStructure.MeasurementUnit);
	
	If Not ValueIsFilled(CurrentRow.ProductsAndServices) Then
		DescriptionTextDistributionErrors = DescriptionTextDistributionErrors 
		+ NStr("ru = 'Не указана продукция распределения.;
		|en = 'Not specified distribution products.' ");
	EndIf; 
	
	If CurrentRow.ErrorQuantity Then
		DescriptionTextDistributionErrors = DescriptionTextDistributionErrors 
		+ StrTemplate(NStr ("en = 'The amount of materials (%1 %2) and distribution (%3 %4) differs.'; ru = 'Отличается количество материалов (%1 %2) и распределения (%3 %4).'; vi = 'Lượng vật liệu (%1 %2) và phân bổ (%3 %4) khác nhau.'"), TotalStructure.QuantityInventory, MeasurementUnt, TotalStructure.QuantityDistribution, MeasurementUnt); 
	EndIf; 
	
EndProcedure

&AtClientAtServerNoContext
Function InventoryColumnsName(Object)
	
	Return "Stage, ProductsAndServices, Characteristic, Batch, Specification, MeasurementUnit, Cell"
	+?(Object.OperationKind=PredefinedValue("Enum.OperationKindsInventoryAssembly.Assembly"), ", StructuralUnit, CustomerOrder", "");
	
EndFunction

&AtClient
Function InventoryTotal(FilterStructure)
	
	TotalStructure = New Structure("QuantityInventory, QuantityDistribution", 0, 0, 0, 0);
	
	RowsInventory = Object.Inventory.FindRows(FilterStructure);
	For Each RowInventory In RowsInventory Do
		TotalStructure.QuantityInventory = TotalStructure.QuantityInventory + RowInventory.Quantity;
	EndDo;
	
	DistribRows = Object.InventoryDistribution.FindRows(FilterStructure);
	For Each DistributionRow In DistribRows Do
		TotalStructure.QuantityDistribution = TotalStructure.QuantityDistribution + DistributionRow.Quantity;
	EndDo;
	
	Return TotalStructure;
	
EndFunction

&AtClient
Procedure Distrib(Command)
	
	If Object.InventoryDistribution.Count() <> 0 Then
		
		Answer = Undefined;
		
		ShowQueryBox(New NotifyDescription("DistribCompliting", ThisObject), NStr("en='The spreadsheet ""Distribution"" will be refilled! Continue the operation?';ru='Табличная часть ""Распределение"" будет перезаполнена! Продолжить выполнение операции?';vi='Phần bảng ""Phân bổ"" sẽ được điền lại! Tiếp tục?'"),
		QuestionDialogMode.YesNo, 0);
		Return;
		
	EndIf;
	
	DistribFragment();
	
EndProcedure

&AtClient
Procedure DistribCompliting(Result, AdditionalParameters) Export
	
	Answer = Result;
	
	If Answer = DialogReturnCode.No Then
		Return;
	EndIf;
	
	
	DistribFragment();
	
EndProcedure

&AtClient
Procedure DistribFragment()
	
	DistributeServer();
	
	UpdateInventoryDistributionOnForm();
	
EndProcedure

&AtServer
Procedure DistributeServer()
	
	If Not Object.ManualDistribution Then
		Return;
	EndIf; 
	
	FillTSAtributesByHeader(Object);
	ProductionServer.DistribInventory(Object.Products, Object.Inventory, Object.InventoryDistribution, Object.CompletedStages, Object.BasisDocument);
	ProductionServer.FillDistributionControlCash(Object, DistributionControlCash);
	
	SetPagePicture(ThisObject);
	
EndProcedure

&AtClient
Procedure UpdateInventoryDistributionOnForm()
	
	If Not Object.ManualDistribution Then
		Return;
	EndIf; 
	
	CurrentRow = Items.ProductionList.CurrentData;
	NoFulter = (CurrentRow=Undefined Or CurrentRow.Value=0);
	Items.InventoryDistributionGroupProduction.Visible = NoFulter;
	
	If NoFulter Then
		Rows = Object.InventoryDistribution;
		CurrentProduct = 0;
	Else
		FilterStructure = New Structure;
		FilterStructure.Insert("ConnectionKeyProduct", CurrentRow.Value);
		Rows = Object.InventoryDistribution.FindRows(FilterStructure);
		CurrentProduct = CurrentRow.Value;
	EndIf; 
	
	ProductsMap = New Map;
	TabularSectionName = "Products";
	For Each ProductsRow In Object.Products Do
		If ProductsRow.ConnectionKey=0 Then
			ProductsRow.ConnectionKey = SmallBusinessClient.CreateNewLinkKey(ThisObject);
		EndIf; 
		ProductsMap.Insert(ProductsRow.ConnectionKey, ProductsRow);
	EndDo; 
	
	InventoryDistribution.Clear();
	For Each TabSecRow In Rows Do
		If Not NoFulter And CurrentRow.Value<>TabSecRow.ConnectionKeyProduct Then
			Continue;
		EndIf; 
		ProductsRow = ProductsMap.Get(TabSecRow.ConnectionKeyProduct);
		NewRow = InventoryDistribution.Add();
		FillPropertyValues(NewRow, TabSecRow);
		FillProductDataInDistributionRow(NewRow, ProductsRow);
		NewRow.CellAvailable = CellAvailable(NewRow.StructuralUnit);
	EndDo; 
	
	RenumberDistribution(InventoryDistribution);
	DisplayControlMarks(ThisObject);
	
EndProcedure

&AtClient
Function CellAvailable(StructuralUnit)
	
	If Not ValueCashe.AccountingByCells Then
		Return False;
	EndIf;
	
	If Not ValueIsFilled(StructuralUnit) Or TypeOf(StructuralUnit)<>Type("СправочникСсылка.StructuralUnits") Then
		Return False;
	EndIf;
	
	If Not ValueCashe.Property("CellAvailability") Then
		Return False;
	EndIf; 
	
	Result = ValueCashe.CellAvailability.Get(StructuralUnit);
	If Result = Undefined Then
		StructuralUnitsArray = New Array;
		StructuralUnitsArray.Add(StructuralUnit);
		CompleteCellAvailable(StructuralUnitsArray, ValueCashe.CellAvailability);
		Result = ValueCashe.CellAvailability.Get(StructuralUnit);
		If Result=Undefined Then
			Return False;
		EndIf; 
	EndIf; 
	
	Return Result;
	
EndFunction

&AtServerNoContext
Procedure CompleteCellAvailable(StructuralUnits, StructuralUnitMap)
	
	Query = New Query;
	Query.SetParameter("StructuralUnits", StructuralUnits);
	Query.Text =
	"SELECT
	|	StructuralUnits.Ref AS Ref,
	|	StructuralUnits.OrderWarehouse AS OrderWarehouse,
	|	StructuralUnits.StructuralUnitType AS StructuralUnitType
	|FROM
	|	Catalog.StructuralUnits AS StructuralUnits
	|WHERE
	|	StructuralUnits.Ref IN(&StructuralUnits)";
	Selection = Query.Execute().Select();
	Map = New Map(StructuralUnitMap);
	While Selection.Next() Do
		Map.Insert(Selection.Ref, Not Selection.OrderWarehouse And Selection.StructuralUnitType=Enums.StructuralUnitsTypes.Warehouse);
	EndDo; 
	StructuralUnitMap = New FixedMap(Map);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillProductDataInDistributionRow(DistributionRow, ProductRow)
	
	If ProductRow=Undefined Then
		DistributionRow.ProductsAndServicesProduction = Undefined;
		DistributionRow.CharacteristicProduction = Undefined;
		DistributionRow.SpecificationProduction = Undefined;
		DistributionRow.MeasurementUnitProduction = Undefined;
		DistributionRow.ProductionQuantity = 0;
		DistributionRow.ReserveProduction = 0;
		DistributionRow.BatchProduction = Undefined;
		DistributionRow.StructuralUnitProduction = Undefined;
		DistributionRow.CellProduction = Undefined;
		DistributionRow.ConnectionKeyProduct = 0;
		DistributionRow.CustomerOrder = Undefined; 
	Else
		DistributionRow.ProductsAndServicesProduction = ProductRow.ProductsAndServices;
		DistributionRow.CharacteristicProduction = ProductRow.Characteristic;
		DistributionRow.SpecificationProduction = ProductRow.Specification;
		DistributionRow.MeasurementUnitProduction = ProductRow.MeasurementUnit;
		DistributionRow.ProductionQuantity = ProductRow.Quantity ;
		DistributionRow.ReserveProduction = ProductRow.Reserve;
		DistributionRow.BatchProduction = ProductRow.Batch;
		DistributionRow.StructuralUnitProduction = ProductRow.StructuralUnit;
		DistributionRow.CellProduction = ProductRow.Cell;
		DistributionRow.ConnectionKeyProduct = ProductRow.ConnectionKey;
		DistributionRow.CustomerOrder = ProductRow.CustomerOrder; 
	EndIf; 
	
EndProcedure

&AtClientAtServerNoContext
Procedure RenumberDistribution(InventoryDistribution)
	
	Num = 1;
	For Each TabSecRow In InventoryDistribution Do
		TabSecRow.LineNumber = Num;
		Num = Num+1;
	EndDo; 	
	
EndProcedure

&AtClientAtServerNoContext
Procedure DisplayControlMarks(Form)
	
	Object = Form.Object;
	If Not Object.ManualDistribution Then
		SetPagePicture(Form);
		Return;
	EndIf;
	
	For Each DistributionRow In Form.InventoryDistribution Do
		DistributionRow.ErrorQuantity = False;
	EndDo;
	
	DistributionErrorExist = False;
	For Each ControlRow In Form.DistributionControlCash Do
		If ControlRow.QuantityInventory =ControlRow.QuantityDistribution Then
			Continue;
		EndIf;
		DistributionErrorExist = True;
		FilterStructure = New Structure(InventoryColumnsName(Form.Object));
		FillPropertyValues(FilterStructure, ControlRow);
		DistribRows = Form.InventoryDistribution.FindRows(FilterStructure);
		For Each DistributionRow In DistribRows Do
			If (ControlRow.QuantityInventory<>ControlRow.QuantityDistribution) Then
				DistributionRow.ErrorQuantity = True;
			EndIf; 
		EndDo;  
	EndDo;
	
	SetPagePicture(Form, , Not DistributionErrorExist);
	
EndProcedure

&AtClient
Procedure InventoryDistributionBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	
	If Clone Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure InventoryDistributionBeforeDeleteRow(Item, Cancel)
	
	If Cancel Then
		OldRowData = Undefined;
	Else
		FieldsStructure = New Structure(InventoryColumnsName(Object));
		FillPropertyValues(FieldsStructure, Item.CurrentData);
		OldRowData = New FixedStructure(FieldsStructure);
	EndIf;
	
EndProcedure

&AtClient
Procedure InventoryDistributionOnStartEdit(Item, NewRow, Clone)
	
	If NewRow Then
		CurrentRow = Item.CurrentData;
		CurrentRow.LineNumber = InventoryDistribution.Count();
		OldRowData = Undefined;
		If ValueIsFilled(CurrentProduct) Then
			CurrentRow.ConnectionKeyProduct = CurrentProduct;
			ProductRow = RowByKey(Object.Products, CurrentProduct);
			FillProductDataInDistributionRow(CurrentRow, ProductRow);
		EndIf; 
	Else
		FieldStructure = New Structure(InventoryColumnsName(Object));
		FillPropertyValues(FieldStructure, Item.CurrentData);
		OldRowData = New FixedStructure(FieldStructure);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Функция RowByKey(Table, ConnectionKey, FieldName = "ConnectionKey")
	
	FilterStructure = New Structure;
	FilterStructure.Insert(FieldName, ConnectionKey);
	Rows = Table.НайтиСтроки(FilterStructure);
	If Rows.Count()=0 Then
		Return Undefined;
	Else
		Return Rows[0];
	EndIf;
	
КонецФункции

&AtClient
Procedure InventoryDistributionOnEditEnd(Item, NewRow, CancelEdit)
	
	UpdateDataTSInventoryDistribution(ThisObject);
	UpdateControlCacheOnDataChange(Item.CurrentData);
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateDataTSInventoryDistribution(Form)
	
	If Not Form.Object.ManualDistribution Then
		Return;
	EndIf; 
	
	DistributionOnForm = Form.InventoryDistribution;
	DistributionTS = Form.Object.InventoryDistribution;
	CurrentProduct = Form.CurrentProduct;
	
	If CurrentProduct>0 Then
		FilterStructure = New Structure;
		FilterStructure.Insert("ConnectionKeyProduct", CurrentProduct);
		Rows = DistributionTS.FindRows(FilterStructure);
		If Rows.Count()=0 Then
			InsertIndex = DistributionTS.Count();
		Else
			InsertIndex = DistributionTS.IndexOf(Rows[0]);
		EndIf; 
	Else
		Rows = New Array;
		DistributionTS.Clear();
		InsertIndex = 0;
	EndIf; 
	For Each FormRow In DistributionOnForm Do
		If FormRow.Quantity=0 Then
			Continue;
		EndIf; 
		If InsertIndex>=DistributionTS.Count() Then
			NewRow = DistributionTS.Add();
		Else
			NewRow = DistributionTS.Insert(InsertIndex);
		EndIf;
		FillPropertyValues(NewRow, FormRow);
		InsertIndex = InsertIndex + 1;
	EndDo; 
	For Each TabSecRow In Rows Do
		DistributionTS.Delete(TabSecRow);
	EndDo; 
	
	Form.Modified = True;
	
EndProcedure

&AtClient
Procedure UpdateControlCacheOnDataChange(NewRowData = Undefined)
	
	If Not Object.ManualDistribution Then
		Return;
	EndIf; 
	
	For ii = 1 To 2 Do
		If ii=1 Then
			If TypeOf(OldRowData)<>Type("FixedStructure") Then
				Continue;
			EndIf; 
			FilterStructure = New Structure(OldRowData);
			OldRowData = Undefined;
		Else
			If NewRowData=Undefined Then
				Continue;
			EndIf; 
			FilterStructure = New Structure(InventoryColumnsName(Object));
			FillPropertyValues(FilterStructure, NewRowData);
		EndIf;
		TotalStructure = InventoryTotal(FilterStructure);
		ControlRows = DistributionControlCash.FindRows(FilterStructure);
		If ControlRows.Count()=0 Then
			ControlRow = DistributionControlCash.Add();
			FillPropertyValues(ControlRow, FilterStructure);
		Else
			ControlRow = ControlRows[0];
		EndIf;
		FillPropertyValues(ControlRow, TotalStructure);
		ErrorsExist = (ControlRow.QuantityInventory<>ControlRow.QuantityDistribution);
		RowsOnForm = InventoryDistribution.FindRows(FilterStructure);
		For Each RowOnForm In RowsOnForm Do
			RowOnForm.ErrorQuantity = ErrorsExist;
		EndDo; 
	EndDo;
	
	DistributionErrorExist = False;
	For Each ControlRow In DistributionControlCash Do
		If ControlRow.QuantityInventory<>ControlRow.QuantityDistribution Then
			DistributionErrorExist = True;
			Break;
		EndIf; 
	EndDo;
	SetPagePicture(ThisObject, , Not DistributionErrorExist);
	UpdateDistributionHelpText();
	
EndProcedure

&AtClient
Procedure InventoryDistributionAfterDeleteRow(Item)
	
	UpdateDataTSInventoryDistribution(ThisObject);
	UpdateControlCacheOnDataChange();
	
EndProcedure

&AtClient
Procedure InventoryDistributionDragStart(Item, DragParameters, Perform)
	
	DrugData = New Structure;
	DrugData.Insert("Event", "MaterialsRedistribution");
	DrugData.Insert("Row", Item.CurrentRow);
	
	DragParameters.Value = CommonUseClientServer.ValueInArray(DrugData)
	
EndProcedure

&AtClient
Procedure ManualDisributionOnChange(Item)
	
	Object.ManualDistribution = ManualDistribution;
	Modified = True;
	
	FormManagement(ThisObject);
	If Object.ManualDistribution Then
		DistribFragment();
		UpdateDicstributionChoiceLists();
	Else
		Object.InventoryDistribution.Clear();
	EndIf; 
	
EndProcedure

&AtClient
Procedure UpdateDicstributionChoiceLists()
	
	CurrentRow = Items.ProductionList.CurrentData;
	If CurrentRow=Undefined Then
		ConectionKey = 0;
	Else
		ConectionKey = CurrentRow.Value;
	EndIf;
	
	TabularSectionName = "Products";
	
	ProductionList.Clear();
	Items.InventoryDistributionProductsAndServicesProduction.ChoiceList.Clear();
	Items.InventoryCustomerOrder.ChoiceList.Clear();
	
	ProductionList.Add(0, NStr("en='All products';ru='Вся продукция';vi='Tất cả sản phẩm'"));
	For Each TabSecRow In Object.Products Do
		If Object.ManualDistribution Then
			If TabSecRow.ConnectionKey=0 And Not ReadOnly Then
				TabSecRow.ConnectionKey = SmallBusinessClient.CreateNewLinkKey(ThisObject);
			EndIf; 
			If Not ValueIsFilled(TabSecRow.ProductsAndServices) Then
				Continue;
			EndIf;
			ProductsPresentation = Presentation(TabSecRow.ProductsAndServices, TabSecRow.Characteristic, TabSecRow.Specification);
			ProductionList.Add(TabSecRow.ConnectionKey, ProductsPresentation);
			Items.InventoryDistributionProductsAndServicesProduction.ChoiceList.Add(TabSecRow.ConnectionKey, ProductsPresentation);
		EndIf;
		If Items.InventoryCustomerOrder.ChoiceList.FindByValue(TabSecRow.CustomerOrder)=Undefined Then
			OrderPresentation = ?(ValueIsFilled(TabSecRow.CustomerOrder), String(TabSecRow.CustomerOrder), NStr("En='<Not specified>';ru='<Не указано>';vi='<Chưa chỉ ra>'"));
			Items.InventoryCustomerOrder.ChoiceList.Add(TabSecRow.CustomerOrder, OrderPresentation);
		EndIf; 
	EndDo;
	
	Items.InventoryCustomerOrder.ChoiceList.SortByPresentation();
	
	CurrentRow = ProductionList.FindByValue(ConectionKey);
	If CurrentRow=Undefined Then
		CurrentRow = ProductionList[0];
	EndIf; 
	Items.ProductionList.CurrentRow = CurrentRow.GetID();
	
	If Object.ManualDistribution Then
		UpdateInventoryDistributionOnForm();
	EndIf; 
	
EndProcedure

&AtClientAtServerNoContext
Function Presentation(Value1 = Undefined, Value2 = Undefined, Value3 = Undefined)
	
	Result = "";
	ValueArray = New Array;
	ValueArray.Add(Value1);
	ValueArray.Add(Value2);
	ValueArray.Add(Value3);
	
	For Each Value In ValueArray Do
		If Not ValueIsFilled(Value) Then
			Continue;
		EndIf;
		Result = Result + ?(IsBlankString(Result), "", ", ")+String(Value);
	EndDo; 
	
	Return Result; 
	
EndFunction

&AtClient
Procedure InventoryDistributionProductsAndServicesProductionChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	StandardProcessing = False;
	
	If TypeOf(SelectedValue)<>Type("Number") Then
		Return;
	EndIf;
	
	ProductsRow = RowByKey(Object.Products, SelectedValue);
	If ProductsRow=Undefined Then
		Return;
	EndIf; 
	
	CurrentRow = Items.InventoryDistribution.CurrentData;
	
	FillProductDataInDistributionRow(CurrentRow, ProductsRow);
	
	If Items.Find("InventoryDistributionProductsAndServices")<>Undefined Then
		Items.InventoryDistribution.CurrentItem = Items.InventoryDistributionProductsAndServices;
	EndIf; 
	
EndProcedure

&AtClient
Procedure ProductionListOnActivateRow(Item)
	
	ListElement = Items.ProductionList.CurrentData;
	If ListElement=Undefined Or ListElement.Value=CurrentProduct Then
		Return;
	EndIf; 
	
	UpdateInventoryDistributionOnForm(); 
	
EndProcedure

&AtClient
Procedure ProductionListDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	
	If ReadOnly Then
		Return;
	EndIf; 
	
	If Row=Undefined Then
		Return;
	EndIf; 
	
	If TypeOf(DragParameters.Value)<>Type("Array") Or DragParameters.Value.Count()<>1 Then
		Return;
	EndIf;
	
	DetailsEvents = DragParameters.Value[0];
	
	If TypeOf(DetailsEvents)<>Type("Structure") Or Not DetailsEvents.Property("Event") Or DetailsEvents.Event<>"MaterialsRedistribution" Then
		Return;
	EndIf; 
	
	ListElement = ProductionList.FindByID(Row);
	DistributionRow = InventoryDistribution.FindByID(DetailsEvents.Row);
	If ListElement=Undefined Or ListElement.Value=0 Or DistributionRow.ConnectionKeyProduct = ListElement.Value Then
		Return;
	EndIf; 
	
	Var_StandardProcessing = False;
	
EndProcedure

&AtServer
Procedure UpdateCellsAvailability()
	
	If Not ValueCashe.AccountingByCells Then
		Return;
	EndIf; 	
	
	If Not ValueCashe.Property("CellAvailability") Then
		ValueCashe.Insert("CellAvailability", New FixedMap(New Map));
	EndIf; 
	
	StructuralUnitAray = New Array;
	StructuralUnitAray.Add(Object.StructuralUnit);
	StructuralUnitAray.Add(Object.ProductsStructuralUnit);
	If Object.WarehousePosition=Enums.AttributePositionOnForm.InTabularSection Then
		If Object.OperationKind= Enums.OperationKindsInventoryAssembly.Assembly Then
			TSName = "Products";
		Else
			TSName = "Inventory";
		EndIf; 
		For Each TabSecRow In Object[TSName] Do
			StructuralUnitAray.Add(TabSecRow.StructuralUnit);
		EndDo; 
	Else
		StructuralUnitAray.Add(Object.InventoryStructuralUnit);
	EndIf;
	StructuralUnitAray = CommonUseClientServer.CollapseArray(StructuralUnitAray);
	CompleteCellAvailable(StructuralUnitAray, ValueCashe.CellAvailability);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillCellsAvailableAttributes(Form)
	
	Object = Form.Object;
	ValueCashe = Form.ValueCashe;
	If Not ValueCashe.AccountingByCells Then
		Return;
	EndIf;
	If Object.WarehousePosition<>PredefinedValue("Enum.AttributePositionOnForm.InTabularSection") Then
		Return;
	EndIf; 
	
	If Object.OperationKind=PredefinedValue("Enum.OperationKindsInventoryAssembly.Disassembly") Then
		TSName = "Products";
	Else
		TSName = "Inventory";
	EndIf;
	
	For Each TabSecRow In Object[TSName] Do
		Result = ValueCashe.CellAvailability.Get(TabSecRow.StructuralUnit);
		If Result=Undefined Then
			Result = False;
		EndIf; 
		TabSecRow.CellAvailable = Result And ValueIsFilled(TabSecRow.StructuralUnit);
	EndDo;
	
	For Each TabSecRow In Form.InventoryDistribution Do
		Result = ValueCashe.CellAvailability.Get(TabSecRow.StructuralUnit);
		If Result=Undefined Then
			Result = False;
		EndIf;
		TabSecRow.CellAvailable = Result And ValueIsFilled(TabSecRow.StructuralUnit);
	EndDo;
	
EndProcedure  

&AtClient
Procedure CollapseFiltersClick(Item)
	
	NewVisible = NOT items.FiltersSettingsAndExtraInfo.Visible;
	WorkWithFiltersClient.CollapseExpandFiltesPanel(ThisObject, NewVisible);
	
EndProcedure

&AtClient
Procedure DecorationExpandFiltersClick(Item)
	
	NewVisible = NOT items.FiltersSettingsAndExtraInfo.Visible;
	WorkWithFiltersClient.CollapseExpandFiltesPanel(ThisObject, NewVisible);
	
EndProcedure

&AtServer
Procedure FillStagesUsingAttributes()
	
	If Not FormParameters.UseProductionStages Then
		Return;
	EndIf;
	If Object.OperationKind=Enums.OperationKindsInventoryAssembly.Disassembly Then
		Return;
	EndIf;
	
	SpecsArray = New Array;
	For Each TabSecRow In Object.Products Do
		TabSecRow.UseProductionStages = False;
		If ValueIsFilled(TabSecRow.Specification) And SpecsArray.Find(TabSecRow.Specification)=Undefined Then
			SpecsArray.Add(TabSecRow.Specification);
		EndIf; 
	EndDo;
	
	If SpecsArray.Count()=0 Then
		Return;
	EndIf;
	
	SpecificationsWithStageProduction = ProductionServer.SpecificationsWithProductionStages(SpecsArray);
	For Each TabSecRow In Object.Products Do
		If Not ValueIsFilled(TabSecRow.Specification) Then
			Continue;
		EndIf;
		TabSecRow.UseProductionStages = (SpecificationsWithStageProduction.Find(TabSecRow.Specification)<>Undefined);
	EndDo;
	
EndProcedure

&AtClient
Procedure InventoryDistributionProductsAndServicesOnChange(Item)
	
	CurStr = Items.InventoryDistribution.CurrentData;
	
	DataStructure = New Structure;
	DataStructure.Insert("ProductsAndServices", CurStr.ProductsAndServices);
	
	DataStructure = GetProductsAndServicesDataOnChange(DataStructure);
	
	CurStr.MeasurementUnit = DataStructure.MeasurementUnit;
	CurStr.Count = 1;
	CurStr.Specification = DataStructure.Specification;
	
	//Характеристики
	CurStr.UseCharacteristics = DataStructure.UseCharacteristics;
	//CurStr.ПроверятьЗаполнениеХарактеристики = DataStructure.ПроверятьЗаполнениеХарактеристики;
	//CurStr.ЗаполнениеХарактеристикиПроверено = True;
	
	If DataStructure.UseCharacteristics Then
		CurStr.Characteristic = DataStructure.Characteristic;
	EndIf;
	//Конец Характеристики
	
	//Партии
	CurStr.UseBatches = DataStructure.UseBatches;
	CurStr.CheckBatchFilling = DataStructure.CheckBatchFilling;
	
	If DataStructure.UseBatches
		Then
		CurStr.Batch = DataStructure.Batch;
	EndIf;
	// Конец Партии
	
	If Object.OperationKind=PredefinedValue("Enum.ВидыОперацийСборкаЗапасов.Сборка") Then
		If Not WarehouseInHeader Then
			FillWarehouseInventoryTS(CurStr, Object, DataStructure);
		Else
			CurStr.StructuralUnit = Object.ProductsStructuralUnit;
			CurStr.Cell = Object.CellInventory;
			CurStr.CellAvailable = CellAvailable(CurStr.StructuralUnit);
		EndIf; 
	EndIf;
	
EndProcedure

&AtClient
Procedure FillWarehouseInventoryTS(Val TSInventoryRow, Val DocumentObject, Val ProductsAndServicesData) Export
	
	If Not ValueIsFilled(TSInventoryRow.StrUnit) Then
		TSInventoryRow.StrUnit = DocumentObject.StrUnit;
		If TSInventoryRow.Property("Cell") Then
			TSInventoryRow.Cell = DocumentObject.Cell;
		EndIf; 
	EndIf;
	
	If TypeOf(ProductsAndServicesData) <> Type("Structure") Then
		Return;
	EndIf;
	
	If ProductsAndServicesData.Property("Warehouse") And ValueIsFilled(ProductsAndServicesData.Warehouse) Then
		TSInventoryRow.StrUnit = ProductsAndServicesData.Warehouse;
	EndIf;
	
	If ProductsAndServicesData.Property("Cell") And ValueIsFilled(ProductsAndServicesData.Cell) And TSInventoryRow.Property("Cell") Then
		TSInventoryRow.Cell = ProductsAndServicesData.Cell;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function GetProductsAndServicesDataOnChange(DataStructure)
	
	DataStructure.Insert("MeasurementUnit", DataStructure.ProductsAndServices.MeasurementUnit);
	DataStructure.Insert("CountryOfOrigin", DataStructure.ProductsAndServices.CountryOfOrigin);
	
	DataStructure.Insert("Warehouse", DataStructure.ProductsAndServices.Warehouse);
	DataStructure.Insert("Cell", DataStructure.ProductsAndServices.Cell);
	
	// Характеристики
	DataStructure.Insert("UseCharacteristics",DataStructure.ProductsAndServices.UseCharacteristics);
	
	If Not DataStructure.Property("Batch") Then
		DataStructure.Insert("Batch", Undefined);
	EndIf;
	
	If ValueIsFilled(DataStructure.ProductsAndServices) 
		And DataStructure.ProductsAndServices.UseBatches Then
		
		BatchByDefault = Catalogs.ПартииНоменклатуры.EmptyRef();
		
		DataStructure.Batch = ?(ValueIsFilled(DataStructure.Batch), DataStructure.Batch, BatchByDefault);
		DataStructure.UseBatches = True;
		
	EndIf;
	// Конец Партии
	
	DataStructure.Insert("Specification", Catalogs.Specifications.EmptyRef());
	DataStructure = GetSpecificationDataOnChange(DataStructure);
	
	Return DataStructure;
	
EndFunction

&AtServerNoContext
Function GetSpecificationDataOnChange(DataStructure)
	
	If GetFunctionalOption("UseProductionStages")
		And ValueIsFilled(DataStructure.Specification)
		And TypeOf(DataStructure.Specification)=Type("СправочникСсылка.Specifications") Then
		ProductionKind = CommonUse.ObjectAttributeValue(DataStructure.Specification, "ProductionKind");
		DataStructure.Insert("UseProductionStage", ValueIsFilled(ProductionKind));
	Else
		DataStructure.Insert("UseProductionStage", False);
	EndIf; 
	
	Return DataStructure;
	
EndFunction 

&AtServer
Procedure FillFormParamaters()
	
	FormParameters = Новый Структура;
	FormParameters.Insert("UseProductionStages", ПолучитьФункциональнуюОпцию("UseProductionStages"));
	
EndProcedure

&AtClient
Procedure UpdateDistributionHelp(ReadValue = False)
	
	If ReadValue Then
		UpdateDistributionByDefault();
	EndIf; 
	
	HeaderItem = New Array;
	HeaderItem.Add(
	StrTemplate(NStr("ru = 'Правила автоматического распределения материалов: по спецификациям и (или) 
	|пропорционально количеству выпускаемой продукции. Для ручного режима первичное 
	|распределение выполняется по тем же правилам, но есть возможность откорректировать
	|результат. Режим по умолчанию: %1 ';
	|en = 'Rules for the automatic distribution of materials: according to specifications and (or)
	|in proportion to the number of products. Default mode: %1';
	| vi = 'Quy tắc phân phối vật liệu tự động: theo thông số kỹ thuật và (hoặc) tỷ lệ với số lượng sản phẩm. Chế độ mặc định: %1';"),
	?(ManualInventoryDistributionByDefault, NStr("ru = 'ручное распределение';
	|en = 'manual distribution'; vi = 'phân phối thủ công';"), NStr("ru = 'автоматическое распределение';
	|en = 'automatic distribution'; vi = 'phân phối tự động';"))));
	HeaderItem.Add(New FormattedString(NStr("ru = 'изменить'; en = 'change'; vi = 'thay đổi';"), , , , "ChangeDefaultMode"));
	Items.ManualDistributionExtendedTooltip.Title = New FormattedString(HeaderItem);
	
EndProcedure

&AtServer
Procedure UpdateDistributionByDefault()
	
	ManualInventoryDistributionByDefault = (Constants.ManualInventoryDistributionByDefault.Get()=Enums.YesNo.Yes);
	
EndProcedure

&AtClient
Procedure ManualDistributionExtendedTooltipURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillTSAtributesByHeader(Object, Attribute = "")
	
	// Заполнение склада
	FillStructuralUnit = (IsBlankString(Attribute) Or Attribute="StructuralUnit");
	If FillStructuralUnit  Then
		TabSec = ?(Object.OperationKind = PredefinedValue("Enum.OperationKindsInventoryAssembly.Disassembly"), Object.Products, Object.Inventory);
		For Each TabSecRow In TabSec Do
			TabSecRow.StructuralUnit = Object.InventoryStructuralUnit;
			TabSecRow.Cell = Object.CellInventory;
		EndDo;
		
		TabSec = ?(Object.OperationKind = PredefinedValue("Enum.OperationKindsInventoryAssembly.Disassembly"), Object.Inventory, Object.Products);
		For Each TabSecRow In TabSec Do
			TabSecRow.StructuralUnit = Object.ProductsStructuralUnit;
			TabSecRow.Cell = Object.ProductsCell;
		EndDo;
		
	EndIf;
	
	// Заполнение заказа покупателя
	For Each TabSecRow In Object.Inventory Do
		TabSecRow.CustomerOrder = Object.CustomerOrder;
	EndDo; 
	For Each TabSecRow In Object.Products Do
		TabSecRow.CustomerOrder = Object.CustomerOrder;
	EndDo;
	
EndProcedure


&AtClientAtServerNoContext
Function ProductionWithStages(Form)
	
	Object = Form.Object;
	FormParameters = Form.FormParameters;
	
	If Not FormParameters.UseProductionStages Then
		Return False;
	EndIf; 
	
	If Object.OperationKind=PredefinedValue("Enum.OperationKindsInventoryAssembly.Disassembly") Then
		Return False;
	EndIf; 
	
	If Object.CustomerOrderPosition=PredefinedValue("Enum.AttributePositionOnForm.InTabularSection") Then
		ByOrder = False;
		For Each TabSecRow In Object.Products Do
			If ValueIsFilled(TabSecRow.CustomerOrder) Then
				ByOrder = True;
				Break;
			EndIf; 
		EndDo;
	Else
		ByOrder = ValueIsFilled(Object.CustomerOrder);
	EndIf;
	
	If Not ByOrder And Not ValueIsFilled(Object.ProductionOrder) Then
		Return False;
	EndIf; 
	
	If Object.CompletedStages.Count()>0 Then
		Return True;
	EndIf; 
	
	StageExist = False;
	
	For Each TabSecRow In Object.Products Do
		If TabSecRow.UseProductionStages Then
			StageExist = True;
			Break;
		EndIf; 
	EndDo; 
	
	Return StageExist;
	
EndFunction  

&AtClientAtServerNoContext
Procedure StageVisibleControl(Form)
	
	Object = Form.Object;
	Items = Form.Items;
	
	ShowStage = ProductionWithStages(Form);
	CommonUseClientServer.SetFormItemProperty(Items, "ProductsStages", 				    		"Visible", ShowStage);
	CommonUseClientServer.SetFormItemProperty(Items, "InventoryStage", 		    					"Visible", ShowStage);
	CommonUseClientServer.SetFormItemProperty(Items, "InventoryDistributionStage", 		    		"Visible", ShowStage);
	CommonUseClientServer.SetFormItemProperty(Items, "ProductsCompletiveStageDepartment",	"Visible", ShowStage);
	
	If Not ShowStage And Not Form.ReadOnly Then
		Object.CompletedStages.Clear();
		For Each TabSecRow In Object.Inventory Do
			TabSecRow.Stage = PredefinedValue("Catalog.ProductionStages.EmptyRef");
		EndDo; 
	EndIf; 
	
EndProcedure

&AtClient
Procedure ClearCompletedStages(TabSecRow)
	
	If Not FormParameters.UseProductionStages Then
		Return;
	EndIf;
	
	If TabSecRow.ConnectionKey=0 Then
		Return;
	EndIf;
	
	FilterStructure = New Structure;
	FilterStructure.Insert("ConnectionKey", TabSecRow.ConnectionKey);
	CompletedStagesRow = Object.CompletedStages.FindRows(FilterStructure);
	
	StageExist = CompletedStagesRow.Count()>0;
	
	For Each RowStage In CompletedStagesRow Do
		Object.CompletedStages.Delete(RowStage);
	EndDo; 
	
	If StageExist Then
		SetPagePicture(ThisObject, False);
		UpdateFormStages(ThisObject);
	EndIf; 
	
	If Not TabSecRow.UseProductionStages
		And ValueIsFilled(TabSecRow.CompletiveStageDepartment) Then
		TabSecRow.CompletiveStageDepartment = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsCustomerOrderOnChange(Item)
	
	TabSecRow = Items.Products.CurrentData;
	If Not ValueIsFilled(TabSecRow.CustomerOrder) Then
		TabSecRow.Reserve = 0;
	EndIf; 
	
	If ValueIsFilled(TabSecRow.Specification) And Object.Inventory.Count()>0 Then
		SetPagePicture(ThisObject, False);
	EndIf; 
	UpdateDicstributionChoiceLists();
	
	If FormParameters.UseProductionStages 
		And Not ValueIsFilled(TabSecRow.CustomerOrder)
		And Not ValueIsFilled(Object.BasisDocument) Then
		FilterStructure = New Structure;
		FilterStructure.Insert("ConnectionKey", TabSecRow.ConnectionKey);
		CompletedStagesRow = Object.CompletedStages.FindRows(FilterStructure);
		If CompletedStagesRow.Count()>0 Then
			For Each RowCompletedStage In CompletedStagesRow Do
				Object.CompletedStages.Delete(RowCompletedStage);
			EndDo; 
			SetPagePicture(ThisObject, False);
			UpdateFormStages(ThisObject);
		EndIf; 
	EndIf; 
	
	StageVisibleControl(ThisObject);
	UpdateCommandFillByBalanceTitle(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateCommandFillByBalanceTitle(Form)
	
	Object = Form.Object;
	Items = Form.Items;
	TSOrder = (Object.CustomerOrderPosition=PredefinedValue("Enum.AttributePositionOnForm.InTabularSection"));
	If TSOrder Then
		OrderFilled = False;
		For Each TabSecRow In Object.Products Do
			If ValueIsFilled(TabSecRow.CustomerOrder) Then
				OrderFilled = True;
				Break;
			EndIf;; 
		EndDo; 
	Else
		OrderFilled = ValueIsFilled(Object.CustomerOrder);
	EndIf; 
	CommandTitle = ?(OrderFilled И Form.ReservationUsed, NStr("ru = 'По остаткам и резервам';
	|vi = 'Theo số dư và dự phòng';
	|en = 'By balances and reserves';"), NStr("ru = 'По остаткам';
	|vi = 'Theo số dư';
	|en = 'By balances';"));
	CommonUseClientServer.SetFormItemProperty(Items, "InventoryFillByBalance", "Title", CommandTitle);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	FillStagesUsingAttributes();
	UpdateFormStages(ThisObject);
	UpdateCellsAvailability();
	FillCellsAvailableAttributes(ThisObject);
EndProcedure

&AtClient
Procedure FillByBalance(Command)
	
	If Object.Inventory.Count() <> 0 Then
		
		ShowQueryBox(Новый NotifyDescription("FillByBalanceCompleting", ThisObject), NStr("en = 'The tabular section ""Materials"" will be replenished! Continue the operation?'; ru = 'Табличная часть ""Материалы"" будет перезаполнена! Продолжить выполнение операции?'; vi = 'Phần bảng ""Nguyên vật liệu"" sẽ được điền lại! Tiếp tục thao tác?'"), 
		QuestionDialogMode.YesNo, 0);
		Return;
		
	EndIf;
	
	FillByBalanceFragment();
	
EndProcedure

&AtClient
Procedure  FillByBalanceCompleting(Result, AdditionalParameters) Export
	
	Answer = Result;
	
	If Answer = DialogReturnCode.No Then
		Return;
	EndIf;
	
	FillByBalanceFragment();
	
EndProcedure

&AtClient
Procedure FillByBalanceFragment()
	
	FillByBalanceSercver();
	
EndProcedure // ЗаполнитьПоРаспределению()

&AtServer
Procedure FillByBalanceSercver()
	
	Document = FormAttributeToValue("Object");
	Document.FillTabularSectionByBalance();
	ValueToFormAttribute(Document, "Object");
	
	ProductionServer.FillDistributionControlCash(Object, DistributionControlCash);
	//НоменклатураВДокументахСервер.ЗаполнитьПризнакиИспользованияХарактеристик(Объект);
	FillStagesUsingAttributes();
	
	InventoryNotFilled = False;
	DisplayControlMarks(ThisObject);
	UpdateFormStages(ThisObject);
	UpdateCellsAvailability();
	FillCellsAvailableAttributes(ThisObject);
	FormManagement(ThisObject);
	
EndProcedure

&AtClient
Procedure DocumentSetting(Command)
	
	// 1. Form parameter structure to fill "Document setting" form.
	ParametersStructure = New Structure;
	ParametersStructure.Insert("CustomerOrderPositionInProductionDocuments", Object.CustomerOrderPosition);
	ParametersStructure.Insert("WarehousePositionInProductionDocuments", Object.WarehousePosition);
	
	ParametersStructure.Insert("WereMadeChanges", 								False);
	
	StructureDocumentSetting = Undefined;
	
	
	OpenForm("CommonForm.DocumentSetting", ParametersStructure,,,,, New NotifyDescription("DocumentSettingEnd", ThisObject));
	
EndProcedure

&AtClient
Procedure DocumentSettingEnd(Result, AdditionalParameters) Export
	
	// 2. Open the form "Prices and Currency".
	StructureDocumentSetting = Result;
	
	// 3. Apply changes made in "Document setting" form.
	If TypeOf(StructureDocumentSetting) = Type("Structure") AND StructureDocumentSetting.WereMadeChanges Then
		
		DocumentSettingEndServer(Result);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DocumentSettingEndServer(Val Result)
	
	If Object.WarehousePosition <> Result.WarehousePositionInProductionDocuments Then
		Object.WarehousePosition = Result.WarehousePositionInProductionDocuments;
		If Object.OperationKind= Enums.OperationKindsInventoryAssembly.Disassembly Then
			TSName = "Products";
		Else
			TSName = "Inventory";
		EndIf;
		OrderWarehouse = Object.InventoryStructuralUnit.OrderWarehouse;
		Для каждого TabSecRow Из Object[TSName] Цикл
			TabSecRow.StructuralUnit = Object.InventoryStructuralUnit;
			TabSecRow.Cell = Object.CellInventory;
			TabSecRow.CellAvailable = NOT OrderWarehouse И ЗначениеЗаполнено(TabSecRow.StructuralUnit);
		КонецЦикла;
	EndIf; 
	
	If Object.CustomerOrderPosition <> Result.CustomerOrderPositionInProductionDocuments Then
		Object.CustomerOrderPosition = Result.CustomerOrderPositionInProductionDocuments;
		Для каждого TabSecRow Из Object.Products Цикл
			TabSecRow.CustomerOrder = Object.CustomerOrder;
		КонецЦикла; 
		Для каждого TabSecRow Из Object.Inventory Цикл
			TabSecRow.CustomerOrder = Object.CustomerOrder;
		КонецЦикла; 
	EndIf; 
	
	SetVisibleByUserSettings(ThisObject);
	
	If Object.ManualDistribution Then
		ProductionServer.FillDistributionControlCash(Object, DistributionControlCash);
		DisplayControlMarks(ThisObject);
	EndIf;
	
EndProcedure // SetVisibleFromUserSettings()

&AtClient
Procedure InventoryStageStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure InventoryStageAutoComplete(Item, Text, ChoiceData, DataGetParameters, Wait, StandardProcessing)
	
	StandardProcessing = False;
	
	StageArray = New Array;
	For Each TabularSectionRow Из Object.Products Do
		If Not TabularSectionRow.UseProductionStages Then
			StageArray.Add(PredefinedValue("Catalog.ProductionStages.EmptyRef"));
			Break;
		EndIf;
	EndDo; 
	For Each TabularSectionRow In Object.CompletedStages Do
		If StageArray.Найти(TabularSectionRow.Stage)= Undefined Then
			StageArray.Add(TabularSectionRow.Stage);
		EndIf; 
	EndDo;
	ChoiceData = New ValueList;
	ChoiceData.LoadValues(StageArray);
	UpdateEmptyStagePresentation(ChoiceData);
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateEmptyStagePresentation(List)
	
	If List.Count()>0 And Not ЗначениеЗаполнено(List[0].Value) Then
		List[0].Presentation = НСтр("en='<No stages>';ru='<Без этапов>';vi='<Không có công đoạn>'");
	EndIf 
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetVisibleByUserSettings(Form)
	
	Object = Form.Object;
	Items = Form.Items;
	ItDisassembly	= (Object.OperationKind = PredefinedValue("Enum.OperationKindsInventoryAssembly.Disassembly"));
	WarehouseInTS = (Object.WarehousePosition=PredefinedValue("Enum.AttributePositionOnForm.InTabularSection"));
	OrderInTS = (Object.CustomerOrderPosition=PredefinedValue("Enum.AttributePositionOnForm.InTabularSection"));
	
	// Склад
	If WarehouseInTS Then
		CommonUseClientServer.SetFormItemProperty(Items, "GroupWarehouseProductsAssembling", "Visible", Not ItDisassembly);
		CommonUseClientServer.SetFormItemProperty(Items, "GroupWarehouseProductsDisassembling", "Visible", False);
		CommonUseClientServer.SetFormItemProperty(Items, "GroupWarehouseInventoryAssembling", "Visible", False);
		CommonUseClientServer.SetFormItemProperty(Items, "GroupWarehouseInventoryDisassembling", "Visible", ItDisassembly);
		CommonUseClientServer.SetFormItemProperty(Items, "ProductsStructuralUnit", "Visible", ItDisassembly);
		CommonUseClientServer.SetFormItemProperty(Items, "ProductsCell", "Visible", ItDisassembly);
		CommonUseClientServer.SetFormItemProperty(Items, "InventoryStructuralUnit", "Visible", Not ItDisassembly);
		CommonUseClientServer.SetFormItemProperty(Items, "InventoryCell", "Visible", Not ItDisassembly);
		CommonUseClientServer.SetFormItemProperty(Items, "InventoryDistributionStructuralUnit", "Visible", Not ItDisassembly);
		CommonUseClientServer.SetFormItemProperty(Items, "InventoryDistributionCell", "Visible", Not ItDisassembly);
		Form.WarehouseInHeader = False;
	Else
		CommonUseClientServer.SetFormItemProperty(Items, "GroupWarehouseProductsAssembling", "Visible", Not ItDisassembly);
		CommonUseClientServer.SetFormItemProperty(Items, "GroupWarehouseProductsDisassembling", "Visible", ItDisassembly);
		CommonUseClientServer.SetFormItemProperty(Items, "GroupWarehouseInventoryAssembling", "Visible", Not ItDisassembly);
		CommonUseClientServer.SetFormItemProperty(Items, "GroupWarehouseInventoryDisassembling", "Visible", ItDisassembly);
		CommonUseClientServer.SetFormItemProperty(Items, "ProductsStructuralUnit", "Visible", False);
		CommonUseClientServer.SetFormItemProperty(Items, "ProductsCell", "Visible", False);
		CommonUseClientServer.SetFormItemProperty(Items, "InventoryStructuralUnit", "Visible", False);
		CommonUseClientServer.SetFormItemProperty(Items, "InventoryCell", "Visible", False);
		CommonUseClientServer.SetFormItemProperty(Items, "InventoryDistributionStructuralUnit", "Visible", False);
		CommonUseClientServer.SetFormItemProperty(Items, "InventoryDistributionCell", "Visible", False);
		Form.WarehouseInHeader = True;
	EndIf;
	
	// Заполнение по остаткам
	WarehouseFilled = (NOT WarehouseInTS И ЗначениеЗаполнено(Object.InventoryStructuralUnit));
	CommonUseClientServer.SetFormItemProperty(Items, "InventoryFillByBalance", "Enabled", WarehouseFilled);
	UpdateCommandFillByBalanceTitle(Form);
	
	// Заказ покупателя
	CommonUseClientServer.SetFormItemProperty(Items, "ProductsCustomerOrder", "Visible", OrderInTS);
	CommonUseClientServer.SetFormItemProperty(Items, "InventoryCustomerOrder", "Visible", OrderInTS);
	CommonUseClientServer.SetFormItemProperty(Items, "InventoryDistributionCustomerOrder", "Visible", OrderInTS);
	CommonUseClientServer.SetFormItemProperty(Items, "GroupCustomerOrder", "Visible", NOT OrderInTS);
	
EndProcedure // УстановитьВидимостьОтПользовательскихНастроек()

&AtClient
Procedure ProductsCountryOfOriginOnChange(Item)
	
	If CashValues.AccountingCCD Then
		
		TabularSectionRow = Items.Products.CurrentData;
		If Not ValueIsFilled(TabularSectionRow.CountryOfOrigin)
			Or TabularSectionRow.CountryOfOrigin = CashValues.RUSSIA Then
			
			TabularSectionRow.CCDNo = Undefined;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure InventoryCountryOfOriginOnChange(Item)
	
	If CashValues.AccountingCCD Then
		
		TabularSectionRow = Items.Inventory.CurrentData;
		If Not ValueIsFilled(TabularSectionRow.CountryOfOrigin)
			Or TabularSectionRow.CountryOfOrigin = CashValues.RUSSIA Then
			
			TabularSectionRow.CCDNo = Undefined;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure InventoryCCDNoOnChange(Item)
	
	TabularSectionRow = Items.Inventory.CurrentData;
	If TabularSectionRow <> Undefined
		And ValueIsFilled(TabularSectionRow.CCDNo) Then
		
		DateCCD = CargoCustomsDeclarationsClient.SelectDateFromCCDNumber(String(TabularSectionRow.CCDNo));
		If DateCCD > EndOfDay(Object.Date) Then
			
			MessageText = NStr("en='Attention! The selected CCD is dated at a later date than the current document';ru='Внимание! Выбранная ГТД датирована более поздней датой, чем текущий документ';vi='Chú ý! Tờ khải hải quan đã chọn có ngày muộn hơn so với chứng từ hiện tại'");
			Stick = StrTemplate("Object.Inventory[%1].CCDNo", TabularSectionRow.GetID());
			
			CommonUseClientServer.MessageToUser(MessageText, , Stick);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsCCDNoOnChange(Item)
	
	TabularSectionRow = Items.Products.CurrentData;
	If TabularSectionRow <> Undefined
		And ValueIsFilled(TabularSectionRow.CCDNo) Then
		
		DateCCD = CargoCustomsDeclarationsClient.SelectDateFromCCDNumber(String(TabularSectionRow.CCDNo));
		If DateCCD > EndOfDay(Object.Date) Then
			
			MessageText = NStr("en='Attention! The selected CCD is dated at a later date than the current document';ru='Внимание! Выбранная ГТД датирована более поздней датой, чем текущий документ';vi='Chú ý! Tờ khai hải quan đã chọn có ngày muộn hơn so với chứng từ hiện tại'");
			Stick = StrTemplate("Object.Products[%1].CCDNo", TabularSectionRow.GetID());
			
			CommonUseClientServer.MessageToUser(MessageText, , Stick);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CCDProductsMode(Command)
	
	If BalancesAndReservesMode Then
		
		Items.BalanceAndReserves.Check = False;
		BalancesAndReservesMode = False;
		UpdateColumnDisplayByInventory();
		
	EndIf;
	
	IsTSMaterials = (Command.Name = "CCDModeMaterials");
	If IsTSMaterials Then
		
		CommonUseClientServer.SetFormItemProperty(Items, "CCDModeMaterials", "Check", Not Items.CCDModeMaterials.Check);
		
	EndIf;
	
	IsTSProducts = (Command.Name = "CCDModeProducts");
	If IsTSProducts Then
		
		CommonUseClientServer.SetFormItemProperty(Items, "CCDModeProducts", "Check", Not Items.CCDModeProducts.Check);
		
	EndIf;
	
	EnableCCDMode = ?(IsTSMaterials, Items.CCDModeMaterials.Check, Items.CCDModeProducts.Check);
	ChangeCCDOperationMode(EnableCCDMode, IsTSMaterials, IsTSProducts);
	
EndProcedure

&AtClient
Procedure CCDNumbersFillByActualBalancesProducts(Command)
	
	IsTSProducts	= (Command.Name = "CCDNumbersFillByActualBalancesProducts");
	IsTSMaterials	= (Command.Name = "CCDNumbersFillByActualBalancesMaterials");
	
	CCDNumbersFillByActualBalancesAtServer(IsTSProducts, IsTSMaterials);
	
EndProcedure

&AtServer
Procedure CCDNumbersFillByActualBalancesAtServer(IsTSProducts, IsTSMaterials)
	
	TSName = ?(IsTSMaterials = True, "Inventory", "Products");
	
	SelectionParameters = New Structure;
	SelectionParameters.Insert("TableInventory", Undefined);
	SelectionParameters.Insert("BalancesByCCD", Undefined);
	SelectionParameters.Insert("Date", Object.Date);
	SelectionParameters.Insert("Ref", Object.Ref);
	SelectionParameters.Insert("Company", Object.Company);
	SelectionParameters.Insert("IndexOfCurrentRow", ?(ValueIsFilled(Items[TSName].CurrentRow), Object[TSName].IndexOf(Object[TSName].FindByID(Items[TSName].CurrentRow)), 0));
	SelectionParameters.Insert("HasAutomaticDiscountsConnectionKey", Undefined);
	
	FieldsNamesArray = New Array;
	FieldsNamesArray.Add("Reserve");
	SelectionParameters.Insert("NamesOfFields", FieldsNamesArray);
	
	CargoCustomsDeclarationsServer.PrepareInventoryTableFromFormTable(SelectionParameters, Object[TSName]);
	CargoCustomsDeclarationsServer.GenerateCCDNumberBalances(SelectionParameters);
	CargoCustomsDeclarationsServer.TransferCCDNumberBalancesToFormTable(Object[TSName], SelectionParameters);
	
	If SelectionParameters.IndexOfCurrentRow <> -1 Then
		
		CollectionRow = Object[TSName].Get(SelectionParameters.IndexOfCurrentRow);
		Items[TSName].CurrentRow = CollectionRow.GetID();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CCDNumbersPickupTabularSection(Command)
	
	ItsMaterial = (Command.Name = "CCDNumbersPickMaterials");
	ItsProducts = (Command.Name = "CCDNumbersPickProducts");
	
	CCDNumbersPickAtServer(ItsProducts, ItsMaterial);
	
EndProcedure

&AtServer
Procedure CCDNumbersPickAtServer(IsTSProducts, IsTSMaterials);
	
	TSName = ?(IsTSMaterials = True, "Inventory", "Products");
	
	SelectionParameters = New Structure;
	SelectionParameters.Insert("TableInventory", Undefined);
	SelectionParameters.Insert("Company", Object.Company);
	
	CargoCustomsDeclarationsServer.PrepareInventoryTableFromFormTable(SelectionParameters, Object[TSName]);
	CargoCustomsDeclarationsServer.PickCCDNumbersByPreviousPostuplenijam(SelectionParameters);
	CargoCustomsDeclarationsServer.MoveCCDNumbersToFormTable(Object[TSName], SelectionParameters);
	
EndProcedure

&AtClient 
Procedure ChangeCCDOperationMode(EnableCCDMode, IsTSMaterials, IsTSProducts)
	
	PropertyName = ?(IsTSMaterials, "ProcessedAttributesMaterials", "ProcessedAttributesProducts");
	If Not CashValues.Property(PropertyName) Then
		
		CashValues.Insert(PropertyName, New Array);
		
	EndIf;
	
	If EnableCCDMode Then
		
		
		EnableCCDOperationsMode(PropertyName, IsTSMaterials, IsTSProducts);
		
	Else
		
		DisableCCDOperationsMode(PropertyName, IsTSMaterials, IsTSProducts);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure EnableCCDOperationsMode(PropertyName, IsTSMaterials, IsTSProducts)
	
	TSName = ?(IsTSMaterials = True, "Inventory", "Products");
	
	UnchangeableAttributes = New Array;
	UnchangeableAttributes.Add(TSName + "Check");
	UnchangeableAttributes.Add(TSName + "LineNumber");
	UnchangeableAttributes.Add(TSName + "ProductsAndServices");
	UnchangeableAttributes.Add(TSName + "CHARACTERISTIC");
	UnchangeableAttributes.Add(TSName + "Batch");
	UnchangeableAttributes.Add(TSName + "Quantity");
	UnchangeableAttributes.Add(TSName + "MeasurementUnit");
	UnchangeableAttributes.Add(TSName + "CountryOfOrigin");
	UnchangeableAttributes.Add(TSName + "CCDNo");
	
	For Each FormItem In Items[TSName].ChildItems Do
		
		If UnchangeableAttributes.Find(FormItem.Name) = Undefined
			And FormItem.Visible = True Then
			
			CommonUseClientServer.SetFormItemProperty(Items, FormItem.Name, "Visible", False);
			CashValues[PropertyName].Add(FormItem.Name);
			
		EndIf;
		
	EndDo;
	
	CommonUseClientServer.SetFormItemProperty(Items, TSName + "MeasurementUnit", "Enabled", False);
	
EndProcedure

&AtClient
Procedure DisableCCDOperationsMode(PropertyName, IsTSMaterials, IsTSProducts)
	
	TSName = ?(IsTSMaterials = True, "Inventory", "Products");
	
	For Each FormItemName In CashValues[PropertyName] Do
		
		CommonUseClientServer.SetFormItemProperty(Items, FormItemName, "Visible", True);
		
	EndDo;
	
	CommonUseClientServer.SetFormItemProperty(Items, TSName + "MeasurementUnit", "Enabled", True);
	
	CashValues[PropertyName] = New Array;
	
EndProcedure

&AtClient
Procedure UpdateColumnDisplayByInventory()
	
	Items.InventoryReserve.Visible = Not BalancesAndReservesMode And CustomerOrderIsFilled(Object) And Object.OperationKind=PredefinedValue("Enum.OperationKindsInventoryAssembly.Assembly");
	Items.InventoryContextMenuGroupOperationsWithRowsUpdate.Visible = BalancesAndReservesMode;
	
	If BalancesAndReservesMode Then
		Items.InventoryBalance.Visible = True;
		Items.InventoryStructuralUnit.Visible = False;
		
		Items.InventoryReserveForBalancesMode.Visible = Object.Posted;
		Items.InventoryInReserveTotal.Visible = Object.Posted;
		
		Items.InventoryReserveForBalancesMode.Visible = FOInventoryReservation;
		Items.InventoryInReserveTotal.Visible = FOInventoryReservation;
		Items.InventoryReserved.Visible = FOInventoryReservation;
		Items.InventoryChangeReserveFillByReserves.Visible = FOInventoryReservation;
		
		Items.InventoryStructuralUnitReserve.Visible = AllowWarehousesInTabularSections;
		
		If FOUseCells And Items.InventoryCell.Visible Then
			Items.InventoryCell.Visible = False;
			Items.InventoryCellForModeBalances.Visible = AllowWarehousesInTabularSections;
		Else
			Items.InventoryCellForModeBalances.Visible = False;
		EndIf;
		
		If Items.CCDModeMaterials.Check Then
			ItsDisassembly	= (Object.OperationKind = CashValues.INDisassembly);
			ItsAssembly	= (Object.OperationKind = CashValues.ToAssembly);
			
			CommonUseClientServer.SetFormItemProperty(Items, "CCDProductsMode", "Check", Not Items.CCDModeProducts.Check And ItsDisassembly);
			CommonUseClientServer.SetFormItemProperty(Items, "CCDModeMaterials", "Check", Not Items.CCDModeMaterials.Check And ItsAssembly);
			
			EnableCCDMode = ?(ItsDisassembly, Items.CCDModeProducts.Check, Items.CCDModeMaterials.Check);
			ChangeCCDOperationMode(EnableCCDMode, ItsDisassembly, ItsAssembly);
		EndIf;
		
	Else
		Items.InventoryStructuralUnit.Visible = ?(WarehouseInHeader, False, True);
		Items.InventoryBalance.Visible = False;
		Items.InventoryChangeReserveFillByReserves.Visible = False;
		
		If FOUseCells And Items.InventoryCellForModeBalances.Visible Then
			Items.InventoryCell.Visible = AllowWarehousesInTabularSections;
			Items.InventoryCellForModeBalances.Visible = False;
		EndIf;
		
	EndIf;
	
	Items.InventoryFillByBalancesAndReservesAllWarehouses.Visible = Not WarehouseInHeader Or BalancesAndReservesMode;
	Items.InventoryBalanceInCell.Visible = Items.InventoryCellForModeBalances.Visible;
	
EndProcedure

&AtClientAtServerNoContext
Function CustomerOrderIsFilled(Object)
	
	Return ValueIsFilled(Object.CustomerOrder) 
	Or Object.CustomerOrderPosition=PredefinedValue("Enum.AttributePositionOnForm.InTabularSection");	
	
EndFunction 

&AtClient
Procedure ClearCCDAndCountryOfOriginNumbers(Command)
	
	IsTSProducts	= (Command.Name = "ClearCCDNumbersAndCountryOfOriginProducts");
	IsTSMaterials	= (Command.Name = "ClearCCDNumbersAndCountryOfOriginMaterials");
	
	TSName = ?(IsTSMaterials = True, "Inventory", "Products");
	
	NumbersCCDClearNumbersAndCountryOfOriginAtServer(TSName);
	
EndProcedure

&AtServer
Procedure NumbersCCDClearNumbersAndCountryOfOriginAtServer(TSName)
	
	CargoCustomsDeclarationsServer.ClearCCDAndCountryOfOriginNumbers(Object[TSName], -1, False);
	
EndProcedure


&AtClient
Procedure ProductsBatchStartChoice(Item, ChoiceData, StandardProcessing)
	
	ItDisassembly = (Object.OperationKind = PredefinedValue("Enum.OperationKindsInventoryAssembly.Disassembly"));
	If ItDisassembly = True Then 
		
		NewParameter = New ChoiceParameter("Filter.ExportDocument",True);
		NewArray = New Array();
		NewArray.Add(NewParameter);
		NewParameters = New FixedArray(NewArray);
		Items.ProductsBatch.ChoiceParameters = NewParameters;
	Else
		NewParameter = New ChoiceParameter("Filter.ExportDocument",False);
		NewArray = New Array();
		NewArray.Add(NewParameter);
		NewParameters = New FixedArray(NewArray);
		Items.ProductsBatch.ChoiceParameters = NewParameters;
		
		
	EndIf;
	
EndProcedure

&AtClient
Procedure InventoryBatchStartChoice(Item, ChoiceData, StandardProcessing)
	
	ItDisassembly = (Object.OperationKind = PredefinedValue("Enum.OperationKindsInventoryAssembly.Disassembly"));
	If ItDisassembly = True Then 
		
		NewParameter = New ChoiceParameter("Filter.ExportDocument",False);
		NewArray = New Array();
		NewArray.Add(NewParameter);
		NewParameters = New FixedArray(NewArray);
		Items.InventoryBatch.ChoiceParameters = NewParameters;
	Else
		NewParameter = New ChoiceParameter("Filter.ExportDocument",True);
		NewArray = New Array();
		NewArray.Add(NewParameter);
		NewParameters = New FixedArray(NewArray);
		Items.InventoryBatch.ChoiceParameters = NewParameters;
	EndIf;
	
	
	
EndProcedure


#EndRegion