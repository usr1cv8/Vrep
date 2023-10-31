
////////////////////////////////////////////////////////////////////////////////
// MODULE VARIABLES

&AtClient
Var WhenChangingStart;

&AtClient
Var WhenChangingFinish;

////////////////////////////////////////////////////////////////////////////////
// GENERAL PURPOSE PROCEDURES AND FUNCTIONS

// Procedure fills inventories by specification.
//
&AtServer
Procedure FillBySpecificationsAtServer()
	
	Document = FormAttributeToValue("Object");
	NodesSpecificationStack = New Array;
	Document.FillTabularSectionBySpecification(NodesSpecificationStack);
	ValueToFormAttribute(Document, "Object");
	
EndProcedure // FillBySpecificationOnServer()

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
Function GetDataProductsAndServicesOnChange(StructureData, TabSec = "Inventory")
	
	StructureData.Insert("MeasurementUnit", StructureData.ProductsAndServices.MeasurementUnit);
	
	If StructureData.Property("Characteristic") Then
		StructureData.Insert("Specification", SmallBusinessServer.GetDefaultSpecification(StructureData.ProductsAndServices, StructureData.Characteristic));
	Else
		StructureData.Insert("Specification", SmallBusinessServer.GetDefaultSpecification(StructureData.ProductsAndServices));
	EndIf;
	
	StructureData.Insert("ProductsAndServicesType", StructureData.ProductsAndServices.ProductsAndServicesType);
	
	FillSpecificationDataOnChange(StructureData);
	
	If TabSec="Operations" Then
		
		If ValueIsFilled(StructureData.Specification) And TypeOf(StructureData.Specification)=Type("CatalogRef.Specifications") Then
			Query = New Query;
			Query.SetParameter("Ref", StructureData.Specification);
			If StructureData.Property("Operation") Then
				Query.SetParameter("Operation", StructureData.Operat);
			Else
				Query.SetParameter("Operation", Undefined);
			EndIf; 
			Query.Text =
			"SELECT
			|	SpecificationsOperations.Ref AS Ref,
			|	SpecificationsOperations.LineNumber AS LineNumber,
			|	SpecificationsOperations.Operation AS Operation,
			|	SpecificationsOperations.TimeNorm AS TimeNorm,
			|	SpecificationsOperations.ProductsQuantity AS ProductsQuantity
			|INTO Operations
			|FROM
			|	Catalog.Specifications.Operations AS SpecificationsOperations
			|WHERE
			|	SpecificationsOperations.Ref = &Ref
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	SpecificationsOperations.Operation AS Operation,
			|	SpecificationsOperations.Operation.MeasurementUnit AS MeasurementUnit,
			|	CASE
			|		WHEN SpecificationsOperations.ProductsQuantity = 0
			|			THEN 0
			|		ELSE SpecificationsOperations.TimeNorm / SpecificationsOperations.ProductsQuantity
			|	END AS TimeNorm
			|FROM
			|	Operations AS SpecificationsOperations
			|WHERE
			|	SpecificationsOperations.Operation IN
			|			(SELECT
			|				SpecificationsOperations.Operation
			|			FROM
			|				Operations AS SpecificationsOperations
			|			WHERE
			|				(SpecificationsOperations.Operation = &Operation
			|					OR &Operation = UNDEFINED)
			|			GROUP BY
			|				SpecificationsOperations.Operation
			|			HAVING
			|				COUNT(SpecificationsOperations.LineNumber) = 1)";
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				// The time rate is taken from the specification
				StructureData.Insert("Operation", Selection.Operation);
				StructureData.Insert("TimeNorm", Selection.TimeNorm);
				StructureData.Insert("MeasurementUnit", Selection.MeasurementUnit);
			EndIf;
		EndIf;
		
		If StructureData.Property("Operation") 
			And ValueIsFilled(StructureData.Operation)
			And TypeOf(StructureData.Operation)=Type("СправочникСсылка.ProductsAndServices") Then
			If Not StructureData.Property("TimeNorm") Then
				// The time rate is taken from the operation card
				AttributesValue = CommonUse.ObjectAttributeValues(StructureData.Operation, "TimeNorm, MeasurementUnit");
				StructureData.Insert("TimeNorm", AttributesValue.TimeNorm);
				StructureData.Insert("MeasurementUnit", AttributesValue.MeasurementUnit);
			EndIf; 
		Else
			// Failed to determine operation
			StructureData.Insert("Operation", Undefined);
			StructureData.Insert("TimeNorm", 0);
			StructureData.Insert("MeasurementUnit", Undefined);
		EndIf;
	
	EndIf;
	
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
Function GetDataStructuralUnitOnChange(Warehouse)
	
	If Warehouse.TransferSource.StructuralUnitType = Enums.StructuralUnitsTypes.Warehouse
		OR Warehouse.TransferSource.StructuralUnitType = Enums.StructuralUnitsTypes.Department Then
		
		Return Warehouse.TransferSource;
		
	Else
		
		Return Undefined;
		
	EndIf;	
	
EndFunction // GetDataStructuralUnitOnChange()	

// Gets the data set from the server for the StructuralUnitsOnChangeReserve procedure.
//
&AtServerNoContext
Function GetDataStructuralUnitReserveOnChange(Warehouse)
	
	If Warehouse.TransferRecipient.StructuralUnitType = Enums.StructuralUnitsTypes.Warehouse
		OR Warehouse.TransferRecipient.StructuralUnitType = Enums.StructuralUnitsTypes.Department Then
		
		Return Warehouse.TransferRecipient;
		
	Else
		
		Return Undefined;
		
	EndIf;
	
	Return Warehouse.TransferRecipient;
	
EndFunction // GetDataStructuralUnitOnChange()

// Procedure calls the data processor for document filling by basis.
//
&AtServer
Procedure FillByDocument(Attribute = "BasisDocument")
	
	Document = FormAttributeToValue("Object");
	Document.Filling(Object[Attribute], );
	ValueToFormAttribute(Document, "Object");
	Modified = True;
	
EndProcedure // FillByDocument()

// Procedure sets availability of the form items.
//
// Parameters:
//  No.
//
&НаКлиентеНаСервереБезКонтекста
Procedure SetVisibleAndEnabled(Form)
	
	Object = Form.Object;
	Items = Form.Items;
	FormParameters = Form.FormParameters;
	
	ItsDisassembly = (Object.OperationKind = PredefinedValue("Enum.OperationKindsProductionOrder.Disassembly"));
	OrderComplete = (Object.OrderState = PredefinedValue("Catalog.ProductionOrderStates.Closed"));
	
	CommonUseClientServer.SetFormItemProperty(Items, "InventoryCostPercentage", "Visible", ItsDisassembly);
	
	SetVisibleReserveColumn(Form);
	
	// Заказ покупателя
	CommonUseClientServer.SetFormItemProperty(Items, "CustomerOrder", "ReadOnly", ValueIsFilled(Object.BasisDocument));
	CommonUseClientServer.SetFormItemProperty(Items, "ProductsCustomerOrder", "ReadOnly", ValueIsFilled(Object.BasisDocument));
	CommonUseClientServer.SetFormItemProperty(Items, "InventoryCustomerOrder", "ReadOnly", ValueIsFilled(Object.BasisDocument));
	
	// Распределение
	CommonUseClientServer.SetFormItemProperty(Items, "InventoryDistribution", "ReadOnly", Form.ReadOnly);
	CommonUseClientServer.SetFormItemProperty(Items, "ManualDistribution", "ReadOnly", Form.ReadOnly);
	CommonUseClientServer.SetFormItemProperty(Items, "TSDistribution", "Visible", Object.ManualDistribution);
	CommonUseClientServer.SetFormItemProperty(Items, "InventoryFillByDistribution", "Visible", Object.ManualDistribution);
	
	If Object.OperationKind = PredefinedValue("Enum.OperationKindsProductionOrder.Disassembly") Then
		
		// Reserve.
		Items.InventoryStructuralUnitReserve.Visible = False;
		Items.InventoryReserve.Visible = False;
		Items.InventoryChangeReserve.Visible = False;
		Items.ProductionStructuralUnitReserve.Visible = ValueIsFilled(Object.CustomerOrder);
		Items.ProductsReserve.Visible = ValueIsFilled(Object.CustomerOrder);
		
		For Each StringInventory IN Object.Inventory Do
			StringInventory.Reserve = 0;
		EndDo;
		
		// Products and services type.
		NewParameter = New ChoiceParameter("Filter.ProductsAndServicesType", PredefinedValue("Enum.ProductsAndServicesTypes.InventoryItem"));
		NewArray = New Array();
		NewArray.Add(NewParameter);
		NewParameters = New FixedArray(NewArray);
		Items.ProductsProductsAndServices.ChoiceParameters = NewParameters;
		
	Else
		
		// Reserve.
		Items.InventoryStructuralUnitReserve.Visible = ValueIsFilled(Object.CustomerOrder);
		Items.InventoryReserve.Visible = ValueIsFilled(Object.CustomerOrder);
		Items.InventoryChangeReserve.Visible = ValueIsFilled(Object.CustomerOrder);
		Items.ProductionStructuralUnitReserve.Visible = False;
		Items.ProductsReserve.Visible = False;
		
		For Each StringProducts IN Object.Products Do
			StringProducts.Reserve = 0;
		EndDo;
		
		// Products and services type.
		NewArray = New Array();
		NewArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.InventoryItem"));
		NewArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.Work"));
		NewArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.Service"));
		ArrayInventoryWork = New FixedArray(NewArray);
		NewParameter = New ChoiceParameter("Filter.ProductsAndServicesType", ArrayInventoryWork);
		NewParameter2 = New ChoiceParameter("Additionally.TypeRestriction", ArrayInventoryWork);
		NewArray = New Array();
		NewArray.Add(NewParameter);
		NewArray.Add(NewParameter2);
		NewParameters = New FixedArray(NewArray);
		Items.ProductsProductsAndServices.ChoiceParameters = NewParameters;
		
	EndIf;
	
	StageVisibleControl(Form);
	
EndProcedure // SetVisibleAndEnabled()

// Procedure sets selection mode and selection list for the form units.
//
// Parameters:
//  No.
//
&AtServer
Procedure SetModeAndChoiceList()
	
	If Not Constants.FunctionalOptionAccountingByMultipleDepartments.Get()
		AND Not Constants.FunctionalOptionAccountingByMultipleWarehouses.Get() Then
		
		Items.StructuralUnit.ListChoiceMode = True;
		Items.StructuralUnit.ChoiceList.Add(Catalogs.StructuralUnits.MainDepartment);
		Items.StructuralUnit.ChoiceList.Add(Catalogs.StructuralUnits.MainWarehouse);
		
		Items.ProductionStructuralUnitReserve.ListChoiceMode = True;
		Items.ProductionStructuralUnitReserve.ChoiceList.Add(Catalogs.StructuralUnits.MainWarehouse);
		Items.ProductionStructuralUnitReserve.ChoiceList.Add(Catalogs.StructuralUnits.MainDepartment);
		
		Items.InventoryStructuralUnitReserve.ListChoiceMode = True;
		Items.InventoryStructuralUnitReserve.ChoiceList.Add(Catalogs.StructuralUnits.MainWarehouse);
		Items.InventoryStructuralUnitReserve.ChoiceList.Add(Catalogs.StructuralUnits.MainDepartment);
		
	EndIf;
	
EndProcedure // SetModeAndChoiceList()

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
			TSRowsArray = Object.Inventory.FindRows(New Structure("ProductsAndServices,Characteristic,MeasurementUnit",BarcodeData.ProductsAndServices,BarcodeData.Characteristic,BarcodeData.MeasurementUnit));
			If TSRowsArray.Count() = 0 Then
				NewRow = Object.Inventory.Add();
				NewRow.ProductsAndServices = BarcodeData.ProductsAndServices;
				NewRow.Characteristic = BarcodeData.Characteristic;
				NewRow.Quantity = CurBarcode.Quantity;
				NewRow.MeasurementUnit = ?(ValueIsFilled(BarcodeData.MeasurementUnit), BarcodeData.MeasurementUnit, BarcodeData.StructureProductsAndServicesData.MeasurementUnit);
				NewRow.Specification = BarcodeData.StructureProductsAndServicesData.Specification;
				Items.Inventory.CurrentRow = NewRow.GetID();
			Else
				FoundString = TSRowsArray[0];
				FoundString.Quantity = FoundString.Quantity + CurBarcode.Quantity;
				Items.Inventory.CurrentRow = FoundString.GetID();
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

// Procedure fills the column Reserve by free balances on stock.
//
&AtServer
Procedure FillColumnReserveByBalancesAtServer()
	
	Document = FormAttributeToValue("Object");
	Document.FillColumnReserveByBalances();
	ValueToFormAttribute(Document, "Object");
	
EndProcedure // FillColumnReserveByBalancesAtServer()

// Function checks reservation use in the document 
//
&AtServerNoContext
Function ReservationUsed(ObjectOperationKind, ObjectCustomerOrder, TabularSectionName)
	
	If Constants.FunctionalOptionInventoryReservation.Get()
		AND ValueIsFilled(ObjectCustomerOrder) Then
		
		If TabularSectionName = "Inventory" AND ObjectOperationKind = Enums.OperationKindsProductionOrder.Assembly Then
			Return True;
		ElsIf TabularSectionName = "Products" AND ObjectOperationKind = Enums.OperationKindsProductionOrder.Disassembly Then
			Return True;
		Else
			Return False;
		EndIf;
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction // ReservationUsed()

////////////////////////////////////////////////////////////////////////////////
// PROCEDURES FOR WORK WITH THE SELECTION

// Procedure - handler of the Action event of the Pick TS Inventory command.
//
&AtClient
Procedure Pick(Command)
	
	TabularSectionName 	= "Inventory";
	AreCharacteristics 	= True;
	AreBatches 			= False;
	
	SelectionParameters = New Structure;
	
	SelectionParameters.Insert("Period", 			Object.Date);
	SelectionParameters.Insert("Company", 		Counterparty);
	SelectionParameters.Insert("StructuralUnit", Object.StructuralUnitReserve);
	
	SelectionParameters.Insert("SpecificationsUsed",	True);
	SelectionParameters.Insert("BatchesUsed", 		False);
	SelectionParameters.Insert("ShowPriceColumn", 		False);
	
	If Object.OperationKind = PredefinedValue("Enum.OperationKindsProductionOrder.Assembly") Then
		SelectionParameters.Insert("ThisIsReceiptDocument", False);
		SelectionParameters.Insert("AvailableStructuralUnitEdit", True);
	Else
		SelectionParameters.Insert("ThisIsReceiptDocument", True);
		SelectionParameters.Insert("AvailableStructuralUnitEdit", False);
	EndIf;
	SelectionParameters.Insert("ReservationUsed", ReservationUsed(Object.OperationKind, Object.CustomerOrder, TabularSectionName));
	
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
	
	SelectionParameters.Insert("OwnerFormUUID", UUID);
	
	OpenForm("CommonForm.PickForm", SelectionParameters, ThisForm);
	
EndProcedure // Selection()

// Procedure - handler of the Action event of the Pick TS Products command.
//
&AtClient
Procedure ProductsPick(Command)
	
	TabularSectionName 	= "Products";
	AreCharacteristics 	= True;
	AreBatches 			= False;
	
	SelectionParameters = New Structure;
	
	SelectionParameters.Insert("Period", 			Object.Date);
	SelectionParameters.Insert("Company",		Counterparty);
	SelectionParameters.Insert("StructuralUnit", Object.StructuralUnitReserve);
	
	SelectionParameters.Insert("SpecificationsUsed",	True);
	SelectionParameters.Insert("BatchesUsed", 		False);
	SelectionParameters.Insert("ShowPriceColumn",		False);
	
	If Object.OperationKind = PredefinedValue("Enum.OperationKindsProductionOrder.Assembly") Then
		SelectionParameters.Insert("ThisIsReceiptDocument", True);
		SelectionParameters.Insert("AvailableStructuralUnitEdit", False);
	Else
		SelectionParameters.Insert("ThisIsReceiptDocument", False);
		SelectionParameters.Insert("AvailableStructuralUnitEdit", True);
	EndIf;
	SelectionParameters.Insert("ReservationUsed", ReservationUsed(Object.OperationKind, Object.CustomerOrder, TabularSectionName));
	
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
	
	SelectionParameters.Insert("OwnerFormUUID", UUID);
	
	OpenForm("CommonForm.PickForm", SelectionParameters, ThisForm);
	
EndProcedure // ProductsPick()

// Function gets a product list from the temporary storage
//
&AtServer
Procedure GetInventoryFromStorage(InventoryAddressInStorage, TabularSectionName, AreCharacteristics, AreBatches)
	
	TableForImport = GetFromTempStorage(InventoryAddressInStorage);
	
	For Each ImportRow IN TableForImport Do
		
		NewRow = Object[TabularSectionName].Add();
		FillPropertyValues(NewRow, ImportRow);
		
		If TabularSectionName = "Products" Then
			
			If ValueIsFilled(ImportRow.ProductsAndServices) Then
				
				NewRow.ProductsAndServicesType = ImportRow.ProductsAndServices.ProductsAndServicesType;
				
			EndIf;
			
		EndIf;
		
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
		BarcodesReceived(New Structure("Barcode, Quantity", CurBarcode, 1));
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

////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - FORM EVENT HANDLERS

// Procedure - OnCreateAtServer event handler.
//
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Object.Ref.IsEmpty() Then
		FillFormParamaters();
	EndIf;
	
	SetFormConditionalAppearance();
	
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
	
	SubsidiaryCompany = SmallBusinessServer.GetCompany(Object.Company);
	
	Items.CustomerOrder.ReadOnly = ValueIsFilled(Object.BasisDocument);
	
	Items.Inventory.ChildItems.InventoryReserve.Visible = ValueIsFilled(Object.CustomerOrder);
	
	If Parameters.Key.IsEmpty() Then
		StructuralUnitType = CommonUse.ObjectAttributeValue(Object.StructuralUnit, "StructuralUnitType");
		//НоменклатураВДокументахСервер.ЗаполнитьПризнакиИспользованияХарактеристик(Объект, Истина);
		FillStagesUsingAttributes();
		UpdateDataCaсheServer();
		FillServiceDataAfterReading(Object);
	EndIf;
	
	CurrentProduct = -1;
	SetPagePicture(ThisObject);
	
	ManualDistribution = Object.ManualDistribution;
	If Object.ManualDistribution Then
		ProductionServer.FillDistributionControlCash(Object, DistributionControlCash);
	EndIf;
	
	SetVisibleAndEnabled(ThisForm);
	SetModeAndChoiceList();
	
	If ValueIsFilled(Object.Ref) Then
		NotifyWorkCalendar = False;
	Else
		NotifyWorkCalendar = True;
	EndIf; 
	DocumentModified = False;
	
	If Not Constants.UseProductionOrderStates.Get() Then
		
		Items.StateGroup.Visible = False;
		
		InProcessStatus = Constants.ProductionOrdersInProgressStatus.Get();
		CompletedStatus = Constants.ProductionOrdersCompletedStatus.Get();
		
		Items.Status.ChoiceList.Add("InProcess", NStr("en='In process';ru='В работе';vi='Đang thực hiện'"));
		Items.Status.ChoiceList.Add("Completed", NStr("en='Completed';ru='Выполнен';vi='Đã hoàn thành'"));
		Items.Status.ChoiceList.Add("Canceled", NStr("ru = 'Отменен';
													|vi = 'Đã hủy';
													|en = 'Canceled'"));
		
		If Object.OrderState.OrderStatus = Enums.OrderStatuses.InProcess AND Not Object.Closed Then
			Status = "InProcess";
		ElsIf Object.OrderState.OrderStatus = Enums.OrderStatuses.Completed Then
			Status = "Completed";
		Else
			Status = "Canceled";
		EndIf;
		
	Else
		
		Items.GroupStatuses.Visible = False;
		
	EndIf;
	
	SmallBusinessClientServer.SetPictureForComment(Items.AdvancedPage, Object.Comment);
	
	ManualDistribution = Object.ManualDistribution;
	Если Object.ManualDistribution Тогда
		ProductionServer.FillDistributionControlCash(Object, DistributionControlCash);
	КонецЕсли; 
	
	// Setting the visibility of attributes from user settings
	SetVivisibleFromUserSettings(ThisObject);
	
	// StandardSubsystems.DataImportFromExternalSources
	DataImportFromExternalSources.OnCreateAtServer(Metadata.Documents.ProductionOrder.TabularSections.Products, DataLoadSettings, ThisObject);
	// End StandardSubsystems.DataImportFromExternalSource
	
	// StandardSubsystems.ObjectVersioning
	ObjectVersioning.OnCreateAtServer(ThisForm);
	// End StandardSubsystems.ObjectVersioning
	
	// StandardSubsystems.AdditionalReportsAndDataProcessors
	AdditionalReportsAndDataProcessors.OnCreateAtServer(ThisForm);
	// End StandardSubsystems.AdditionalReportsAndDataProcessors
	
	// StandardSubsystems.Printing
	PrintManagement.OnCreateAtServer(ThisForm, Items.ImportantCommandsGroup);
	// End StandardSubsystems.Printing
	
	// StandardSubsystems.Properties
	AdditionalParameters = PropertiesManagementOverridable.FillAdditionalParameters(Object, "AdditionalAttributesGroup");
	PropertiesManagement.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// Peripherals
	UsePeripherals = SmallBusinessReUse.UsePeripherals();
	ListOfElectronicScales = EquipmentManagerServerCall.GetEquipmentList("ElectronicScales", , EquipmentManagerServerCall.GetClientWorkplace());
	If ListOfElectronicScales.Count() = 0 Then
		// There are no connected scales.
		Items.InventoryGetWeight.Visible = False;
	EndIf;
	Items.InventoryImportDataFromDCT.Visible = UsePeripherals;
	// End Peripherals
	
	
	OpenFormPlanner = Parameters.Property("SelectedResources");
	
	If OpenFormPlanner And Not ThisForm.ReadOnly Then
		FillResourcesFromPlanner(Parameters.SelectedResources);
	EndIf;
	
EndProcedure // OnCreateAtServer()

// Procedure - OnReadAtServer event handler.
//
&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	FillFormParamaters();
	
	// StandardSubsystems.ChangesProhibitionDates
	ChangeProhibitionDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.ChangesProhibitionDates
	
	// StandardSubsystems.Properties
	PropertiesManagement.OnReadAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.Properties
	
	StructuralUnitType = CommonUse.ObjectAttributeValue(Object.StructuralUnit, "StructuralUnitType");
	FillStagesUsingAttributes();
	UpdateDataCaсheServer();
	FillServiceDataAfterReading(Object);

	ResourcePlanningCM.RefillServiceAttributesResourceTable(Object.EnterpriseResources);
	
EndProcedure // OnReadAtServer()

// Procedure - event handler OnOpen.
//
&AtClient
Procedure OnOpen(Cancel)
	
	WhenChangingStart = Object.Start;
	WhenChangingFinish = Object.Finish;
	
	// Peripherals
	EquipmentManagerClientOverridable.StartConnectingEquipmentOnFormOpen(ThisForm, "BarCodeScanner");
	// End Peripherals
	
	UpdateProductsChoiseList();
	UpdateStructuralUnitReserveMark();
	
EndProcedure // OnOpen()

// Procedure - event handler AfterWriting.
//
&AtClient
Procedure AfterWrite(WriteParameters)
	
	If DocumentModified Then
		NotifyWorkCalendar = True;
		DocumentModified = False;
	EndIf; 
	
	FillServiceDataAfterReading(Object);
	
	If OpenFormPlanner Then
		Notify("UpdatePlanner")
	EndIf;
	
EndProcedure // AfterWrite()

// Procedure - event handler of the form NotificationProcessing.
//
&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties 
	If PropertiesManagementClient.ProcessAlerts(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
	EndIf;
	// End StandardSubsystems.Properties
	
	// Peripherals
	If Source = "Peripherals"
		AND IsInputAvailable() Then
		If EventName = "ScanData" Then
			//Transform preliminary to the expected format
			Data = New Array();
			If Parameter[1] = Undefined Then
				Data.Add(New Structure("Barcode, Quantity", Parameter[0], 1)); // Get a barcode from the basic data
			Else
				Data.Add(New Structure("Barcode, Quantity", Parameter[1][1], 1)); // Get a barcode from the additional data
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
		CurrentPagesProducts= (Items.Pages.CurrentPage = Items.TSProducts);
		TabularSectionName		= ?(CurrentPagesProducts, "Products", "Inventory");
		
		GetInventoryFromStorage(InventoryAddressInStorage, TabularSectionName, True, False);
		
	EndIf;
	
EndProcedure // NotificationProcessing()

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertiesManagement.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
	// ParametricSpecifications
	ProductionFormulasServer.CheckSpecificationsAdditAttributesFilling(Object, "Products", Cancel);
	// End ParametricSpecifications

EndProcedure

// Procedure - event handler OnClose.
//
&AtClient
Procedure OnClose()
	
	// Peripherals
	EquipmentManagerClientOverridable.StartDisablingEquipmentOnCloseForm(ThisForm);
	// End Peripherals
	
EndProcedure // OnClose()

// Procedure-handler of the BeforeWriteAtServer event.
// Performs initial attributes forms filling.
//
&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Modified Then
		DocumentModified = True;
	EndIf;
	
	// StandardSubsystems.Properties
	PropertiesManagement.BeforeWriteAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.Properties
	
EndProcedure // BeforeWriteAtServer()

// Procedure - BeforeWrite event handler.
//
&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	// StandardSubsystems.PerformanceEstimation
	PerformanceEstimationClientServer.StartTimeMeasurement("DocumentProductionOrderPosting");
	// StandardSubsystems.PerformanceEstimation
	
EndProcedure // BeforeWrite()

// Procedure - event handler BeforeClose form.
//
&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	If NotifyWorkCalendar Then
		Notify("ChangedProductionOrder", Object.Responsible);
	EndIf;
	
EndProcedure

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
		
		FillByDocument();
		
		If Object.OperationKind = PredefinedValue("Enum.OperationKindsProductionOrder.Disassembly") Then
			
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
				
			Else
				
				If Not Items.Inventory.ChildItems.InventoryReserve.Visible Then
					Items.Inventory.ChildItems.InventoryReserve.Visible = True;
					Items.InventoryChangeReserve.Visible = True;
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;

EndProcedure  // FillExecute()

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

// Procedure - command handler FillByBalance submenu ChangeReserve.
//
&AtClient
Procedure ChangeReserveFillByBalances(Command)
	
	If Object.Inventory.Count() = 0 Then
		Message = New UserMessage;
		Message.Text = NStr("ru = 'Табличная часть ""Запасы"" не заполнена!';
							|vi = 'Phần bảng ""Vật tư"" chưa điền!';
							|en = 'The ""Inventory"" tabular section is not filled in.'");
		Message.Message();
		Return;
	EndIf;
	
	FillColumnReserveByBalancesAtServer();
	
EndProcedure // ChangeReserveFillByBalances()

// Procedure - command handler ClearReserve of the ChangeReserve submenu.
//
&AtClient
Procedure ChangeReserveClearReserve(Command)
	
	If Object.Inventory.Count() = 0 Then
		Message = New UserMessage;
		Message.Text = NStr("ru = 'Табличная часть ""Запасы"" не заполнена!';
							|vi = 'Phần bảng ""Vật tư"" chưa điền!';
							|en = 'The ""Inventory"" tabular section is not filled in.'");
		Message.Message();
		Return;
	EndIf;
	
	For Each TabularSectionRow IN Object.Inventory Do
		TabularSectionRow.Reserve = 0;
	EndDo;
	
EndProcedure // ChangeReserveFillByBalances()

////////////////////////////////////////////////////////////////////////////////
// COMMAND ACTIONS OF THE ORDER STATES PANEL

// Procedure - event handler OnChange input field Status.
//
&AtClient
Procedure StatusOnChange(Item)
	
	If Status = "InProcess" Then
		Object.OrderState = InProcessStatus;
		Object.Closed = False;
	ElsIf Status = "Completed" Then
		Object.OrderState = CompletedStatus;
		Object.Closed = True;
	ElsIf Status = "Canceled" Then
		Object.OrderState = InProcessStatus;
		Object.Closed = True;
	EndIf;
	
	Modified = True;
	
EndProcedure // StatusOnChange()

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
	
	Items.CustomerOrder.ReadOnly = ValueIsFilled(Object.BasisDocument);
	
EndProcedure // BasisDocumentOnChange()

// Procedure - handler of the OnChange event of the CustomerOrder input field.
//
&AtClient
Procedure CustomerOrderOnChange(Item)
	
	If Object.OperationKind = PredefinedValue("Enum.OperationKindsProductionOrder.Disassembly") Then
		
		Items.ProductionStructuralUnitReserve.Visible = ValueIsFilled(Object.CustomerOrder);
		Items.ProductsReserve.Visible = ValueIsFilled(Object.CustomerOrder);
		
		For Each StringProducts IN Object.Products Do
			StringProducts.Reserve = 0;
		EndDo;
		
	Else
		
		Items.InventoryStructuralUnitReserve.Visible = ValueIsFilled(Object.CustomerOrder);
		Items.InventoryReserve.Visible = ValueIsFilled(Object.CustomerOrder);
		Items.InventoryChangeReserve.Visible = ValueIsFilled(Object.CustomerOrder);
		
		For Each StringInventory IN Object.Inventory Do
			StringInventory.Reserve = 0;
		EndDo;
		
	EndIf;
	
	FillTSAtributesByHeader(Object, "CustomerOrder");
	
	SetVisibleAndEnabled(ThisObject);
	
	OrderOperationKindOnChange();
	
EndProcedure // CustomerOrderOnChange()

// Procedure - handler of the ChoiceProcessing of the OperationKind input field.
//
&AtClient
Procedure OperationKindChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If ValueSelected = PredefinedValue("Enum.OperationKindsProductionOrder.Disassembly") Then
		
		ProductsAndServicesTypeInventory = PredefinedValue("Enum.ProductsAndServicesTypes.InventoryItem");
		For Each StringProducts IN Object.Products Do
			
			If ValueIsFilled(StringProducts.ProductsAndServices)
				AND StringProducts.ProductsAndServicesType <> ProductsAndServicesTypeInventory Then
				
				MessageText = NStr("ru = 'Операция разборки не выполняется для работ и услуг!""""В строке №%Номер% табличной части ""Продукция"" номенклатура ""%НоменклатураПредставление%"" является работой (услугой)';
|vi = 'Không thực hiện giao dịch tách bộ cho công việc và dịch vụ!""""Tại dòng số %Номер% của phần bảng ""Sản phẩm"", mặt hàng ""%НоменклатураПредставление%"" là công việc (dịch vụ)';
|en = 'Disassembling operation is invalid for works and services!""""The %ProductsAndServicesPresentation% products and services could be a work(service) in the %Number% string of the tabular section ""Products""'");
				MessageText = StrReplace(MessageText, "%Number%", StringProducts.LineNumber);
				MessageText = StrReplace(MessageText, "%ProductsAndServicesPresentation%", String(StringProducts.ProductsAndServices));
				
				SmallBusinessClient.ShowMessageAboutError(Object, MessageText);
				StandardProcessing = False;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure // OperationKindChoiceProcessing()

// Procedure - event handler OnChange of the OperationKind input field.
//
&AtClient
Procedure OperationKindOnChange(Item)
	
	SetVisibleAndEnabled(ThisForm);
	
	OrderOperationKindOnChange();
	
EndProcedure // OperationKindOnChange()

// Procedure - event handler OnChange input field Start.
//
&AtClient
Procedure StartOnChange(Item)
	
	If Object.Start > Object.Finish AND ValueIsFilled(Object.Finish) Then
		Object.Start = WhenChangingStart;
		Message(NStr("ru = 'Дата старта не может быть больше даты финиша.';
					|vi = 'Ngày bắt đầu không thể lớn hơn ngày kết thúc.';
					|en = 'Start date cannot be greater than end date.'"));
	Else
		WhenChangingStart = Object.Start;
	EndIf;
	
EndProcedure

// Procedure - event handler OnChange input field Finish.
//
&AtClient
Procedure FinishOnChange(Item)
	
	If Hour(Object.Finish) = 0 AND Minute(Object.Finish) = 0 Then
		Object.Finish = EndOfDay(Object.Finish);
	EndIf;
	
	If Object.Finish < Object.Start Then
		Object.Finish = WhenChangingFinish;
		Message(NStr("ru = 'Дата финиша не может быть меньше даты старта.';
					|vi = 'Ngày kết thúc không thể nhỏ hơn ngày bắt đầu.';
					|en = 'Finish date can not be less than the start date.'"));
	Else
		WhenChangingFinish = Object.Finish;
	EndIf;
	
EndProcedure // FinishOnChange()

// Procedure - event handler OnChange of the StructuralUnit input field.
//
&AtClient
Procedure StructuralUnitOnChange(Item)
	
	If ValueIsFilled(Object.StructuralUnit)
		AND Not ValueIsFilled(Object.StructuralUnitReserve) Then
		
		DataStructuralUnitReserve = GetDataStructuralUnitOnChange(Object.StructuralUnit);
		Object.StructuralUnitReserve = DataStructuralUnitReserve;
		
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

// Procedure - handler of the OnChange event of the StructuralUnitReserve input field.
//
&AtClient
Procedure StructuralUnitReserveOnChange(Item)
	
	If ValueIsFilled(Object.StructuralUnitReserve)
		AND Not ValueIsFilled(Object.StructuralUnit) Then
		
		DataStructuralUnit = GetDataStructuralUnitReserveOnChange(Object.StructuralUnitReserve);
		Object.StructuralUnit = DataStructuralUnit;
		
	EndIf;
	
EndProcedure // StructuralUnitReserveOnChange()

// Procedure - handler of the Opening event of the StructuralUnitReserve input field.
//
&AtClient
Procedure ProductsStructuralUnitReserveOpen(Item, StandardProcessing)
	
	If Items.ProductionStructuralUnitReserve.ListChoiceMode
		AND Not ValueIsFilled(Object.StructuralUnitReserve) Then
		
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure // ProductsStructuralUnitReserveOpening()

// Procedure - handler of the Opening event of the StructuralUnitReserve input field.
//
&AtClient
Procedure InventoryStructuralUnitReserveOpen(Item, StandardProcessing)
	
	If Items.InventoryStructuralUnitReserve.ListChoiceMode
		AND Not ValueIsFilled(Object.StructuralUnitReserve) Then
		
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure // InventoryStructuralUnitReserveOpen()

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


////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - EVENT HANDLERS OF THE PRODUCTS TABULAR SECTION ATTRIBUTES

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
	TabularSectionRow.UseProductionStages = StructureData.UseProductionStages;
	
	If TabularSectionRow.UseProductionStages
		And FormParameters.UseProductionStages
		And StructuralUnitType=PredefinedValue("Enum.StructuralUnitsTypes.Department") Then
		TabularSectionRow.CompletiveStageDepartment = Object.StructuralUnit;
	EndIf; 

	TabularSectionRow.ProductsAndServicesType = StructureData.ProductsAndServicesType;
	
	
	UpdateProductsChoiseList();
	FillOperationServiceData(Object);
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
	
	If TabularSectionRow.UseProductionStages
		And FormParameters.UseProductionStages
		And StructuralUnitType=PredefinedValue("Enum.StructuralUnitsTypes.Department") Then
		TabularSectionRow.CompletiveStageDepartment = Object.StructuralUnit;
	EndIf; 
	
	If ValueIsFilled(TabularSectionRow.Specification) And Object.Inventory.Count()>0 Then
		SetPagePicture(ThisObject, False);
	EndIf; 
	
	UpdateProductsChoiseList();
	FillOperationServiceData(Object);
	StageVisibleControl(ThisObject);

	
EndProcedure // ProductsCharacteristicOnChange()

////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - EVENT HANDLERS OF THE INVENTORY TABULAR SECTION ATTRIBUTES

// Procedure - event handler OnChange of the ProductsAndServices input field.
//
&AtClient
Procedure InventoryProductsAndServicesOnChange(Item)
	
	TabularSectionRow = Items.Inventory.CurrentData;
	
	StructureData = New Structure;
	StructureData.Insert("ProductsAndServices", TabularSectionRow.ProductsAndServices);
	
	StructureData = GetDataProductsAndServicesOnChange(StructureData);
	
	TabularSectionRow.MeasurementUnit = StructureData.MeasurementUnit;
	TabularSectionRow.Quantity = 1;
	TabularSectionRow.Specification = StructureData.Specification;
	
	TabularSectionRow.StructuralUnit = Object.StructuralUnitReserve;

EndProcedure // InventoryProductsAndServicesOnChange()

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

&AtClient
Procedure InventoryCustomerOrderOnChange(Item)
	
	СтрокаТабличнойЧасти = Items.Inventory.ТекущиеДанные;
	Если НЕ ЗначениеЗаполнено(СтрокаТабличнойЧасти.CustomerOrder) Тогда
		СтрокаТабличнойЧасти.Reserve = 0;
	КонецЕсли; 
	
КонецПроцедуры

// Procedure - OnChange event handler of the Comment input field.
//
&AtClient
Procedure CommentOnChange(Item)
	
	AttachIdleHandler("Attachable_SetPictureForComment", 0.5, True);
	
EndProcedure // CommentOnChange()

&AtClient
Procedure Attachable_SetPictureForComment()
	
	SmallBusinessClientServer.SetPictureForComment(Items.AdvancedPage, Object.Comment);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - EVENTS HANDLERS OF THE ENTERPRISE RESOURCES TABULAR SECTION ATTRIBUTES

// Procedure calculates the operation duration.
//
// Parameters:
//  No.
//
&AtClient
Function CalculateDuration(CurrentRow)
	
	DurationInSeconds = CurrentRow.Finish - CurrentRow.Start;
	Hours = Int(DurationInSeconds / 3600);
	Minutes = (DurationInSeconds - Hours * 3600) / 60;
	Duration = Date(0001, 01, 01, Hours, Minutes, 0);
	
	Return Duration;
	
EndFunction // CalculateDuration()

// It receives data set from the server for the EnterpriseResourcesOnStartEdit procedure.
//
&AtClient
Function GetDataEnterpriseResourcesOnStartEdit(DataStructure)
	
	DataStructure.Start = Object.Start - Second(Object.Start);
	DataStructure.Finish = Object.Finish - Second(Object.Finish);
	
	If ValueIsFilled(DataStructure.Start) AND ValueIsFilled(DataStructure.Finish) Then
		If BegOfDay(DataStructure.Start) <> BegOfDay(DataStructure.Finish) Then
			DataStructure.Finish = EndOfDay(DataStructure.Start) - 59;
		EndIf;
		If DataStructure.Start >= DataStructure.Finish Then
			DataStructure.Finish = DataStructure.Start + 1800;
			If BegOfDay(DataStructure.Finish) <> BegOfDay(DataStructure.Start) Then
				If EndOfDay(DataStructure.Start) = DataStructure.Start Then
					DataStructure.Start = DataStructure.Start - 29 * 60;
				EndIf;
				DataStructure.Finish = EndOfDay(DataStructure.Start) - 59;
			EndIf;
		EndIf;
	ElsIf ValueIsFilled(DataStructure.Start) Then
		DataStructure.Start = DataStructure.Start;
		DataStructure.Finish = EndOfDay(DataStructure.Start) - 59;
		If DataStructure.Finish = DataStructure.Start Then
			DataStructure.Start = BegOfDay(DataStructure.Start);
		EndIf;
	ElsIf ValueIsFilled(DataStructure.Finish) Then
		DataStructure.Start = BegOfDay(DataStructure.Finish);
		DataStructure.Finish = DataStructure.Finish;
		If DataStructure.Finish = DataStructure.Start Then
			DataStructure.Finish = EndOfDay(DataStructure.Finish) - 59;
		EndIf;
	Else
		DataStructure.Start = BegOfDay(CurrentDate());
		DataStructure.Finish = EndOfDay(CurrentDate()) - 59;
	EndIf;
	
	DurationInSeconds = DataStructure.Finish - DataStructure.Start;
	Hours = Int(DurationInSeconds / 3600);
	Minutes = (DurationInSeconds - Hours * 3600) / 60;
	Duration = Date(0001, 01, 01, Hours, Minutes, 0);
	DataStructure.Duration = Duration;
	
	Return DataStructure;
	
EndFunction // GetDataEnterpriseResourcesOnStartEdit()

// Procedure - event handler OnStartEdit tabular section EnterpriseResources.
//
&AtClient
Procedure EnterpriseResourcesOnStartEdit(Item, NewRow, Copy)
	
	//If NewRow Then
	//	
	//	TabularSectionRow = Items.EnterpriseResources.CurrentData;
	//	
	//	DataStructure = New Structure;
	//	DataStructure.Insert("Start", '00010101');
	//	DataStructure.Insert("Finish", '00010101');
	//	DataStructure.Insert("Duration", '00010101');
	//	
	//	DataStructure = GetDataEnterpriseResourcesOnStartEdit(DataStructure);
	//	TabularSectionRow.Start = DataStructure.Start;
	//	TabularSectionRow.Finish = DataStructure.Finish;
	//	TabularSectionRow.Duration = DataStructure.Duration;
	//	
	//EndIf;
	
EndProcedure // EnterpriseResourcesOnStartEdit()

// Procedure - event handler OnChange input field EnterpriseResource.
//
&AtClient
Procedure EnterpriseResourcesEnterpriseResourceOnChange(Item)
	
	TabularSectionRow = Items.EnterpriseResources.CurrentData;
	
	If TabularSectionRow = Undefined Then
		Return;
	EndIf;

	TabularSectionRow.Capacity = 1;
	
	СтруктураДанные = Новый Структура();
	СтруктураДанные.Вставить("Resource", TabularSectionRow.EnterpriseResource);
	
	ResourcePlanningCMClient.CleanRowData(TabularSectionRow);
	FillDataResourceTableOnForm();
	
EndProcedure // EnterpriseResourcesEnterpriseResourceOnChange()

// Procedure - event handler OnChange input field Day.
//
&AtClient
Procedure EnterpriseResourcesDayOnChange(Item)
	
	SpecifiedEndOfPeriod();
	SetupRepeatAvailable();

	
EndProcedure // EnterpriseResourcesDayOnChange()

// Procedure - event handler OnChange input field Duration.
//
&AtClient
Procedure EnterpriseResourcesDurationOnChange(Item)
	
	CurrentRow = Items.EnterpriseResources.CurrentData;
	DurationInSeconds = Hour(CurrentRow.Duration) * 3600 + Minute(CurrentRow.Duration) * 60;
	If DurationInSeconds = 0 Then
		CurrentRow.Finish = CurrentRow.Start + 1800;
	Else
		CurrentRow.Finish = CurrentRow.Start + DurationInSeconds;
	EndIf;
	If BegOfDay(CurrentRow.Start) <> BegOfDay(CurrentRow.Finish) Then
		CurrentRow.Finish = EndOfDay(CurrentRow.Start) - 59;
	EndIf;
	If CurrentRow.Start >= CurrentRow.Finish Then
		CurrentRow.Finish = CurrentRow.Start + 1800;
		If BegOfDay(CurrentRow.Finish) <> BegOfDay(CurrentRow.Start) Then
			If EndOfDay(CurrentRow.Start) = CurrentRow.Start Then
				CurrentRow.Start = CurrentRow.Start - 29 * 60;
			EndIf;
			CurrentRow.Finish = EndOfDay(CurrentRow.Start) - 59;
		EndIf;
	EndIf;
	
	CurrentRow.Duration = CalculateDuration(CurrentRow);
	
EndProcedure // EnterpriseResourcesDurationOnChange()

// Procedure - event handler OnChange input field Start.
//
&AtClient
Procedure EnterpriseResourcesStartOnChange(Item)
	
	OnChangePeriod(True);
	
EndProcedure // EnterpriseResourcesStartOnChange()

// Procedure - event handler OnChange input field Finish.
//
&AtClient
Procedure EnterpriseResourcesFinishOnChange(Item)
	
	OnChangePeriod();
	
EndProcedure // EnterpriseResourcesFinishOnChange()

////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - TOOLTIP EVENTS HANDLERS

&AtClient
Procedure StatusExtendedTooltipNavigationLinkProcessing(Item, URL, StandardProcessing)
	
	StandardProcessing = False;
	OpenForm("DataProcessor.AdministrationPanelSB.Form.SectionProduction");
	
EndProcedure

#Region DataImportFromExternalSources

&AtClient
Procedure LoadFromFileGoods(Command)
	
	NotifyDescription = New NotifyDescription("ImportDataFromExternalSourceResultDataProcessor", ThisObject, DataLoadSettings);
	
	DataLoadSettings.Insert("TabularSectionFullName",	"ProductionOrder.Products");
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

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_EditContentOfProperties()
PropertiesManagementClient.EditContentOfProperties(ThisForm, Object.Ref);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	PropertiesManagement.UpdateAdditionalAttributesItems(ThisForm);
EndProcedure

&AtClient
Procedure ManualDistributionOnChange(Item)
	
	Object.ManualDistribution = ManualDistribution;
	Modified = True;
	
	SetVisibleAndEnabled(ThisObject);
	If Object.ManualDistribution Then
		DistribFragment();
		UpdateProductsChoiseList();
	Else
		Object.InventoryDistribution.Clear();
	EndIf; 

EndProcedure

// End StandardSubsystems.Properties

#EndRegion

&НаКлиенте
Procedure DistribFragment()
	
	DistributeServer();
	UpdateInventoryDistributionOnForm();
	
EndProcedure

&НаКлиенте
Procedure UpdateProductsChoiseList()
	
	CurrentRow = Items.ProductionList.CurrentData;
	If CurrentRow=Undefined Then
		ConnectionKey = 0;
	Else
		ConnectionKey = CurrentRow.Value;
	EndIf;
	
	TabularSectionName = "Products";
	
	ProductionList.Clear();
	Items.InventoryDistributionProductsAndServicesProduction.ChoiceList.Clear();
	Items.InventoryCustomerOrder.ChoiceList.Clear();
	Items.OperationsCustomerOrder.ChoiceList.Clear();
	Items.OperationsProductsAndServices.ChoiceList.Clear();
	ProductionList.Add(0, NStr("en='All products';vi='Tất cả sản phẩm';ru='Вся продукция'"));
	For Each TabSecRow In Object.Products Do
		If TabSecRow.ConnectionKey=0 And Not ReadOnly Then
			TabSecRow.ConnectionKey = SmallBusinessClient.CreateNewLinkKey(ThisObject);
		EndIf; 
		If Not ValueIsFilled(TabSecRow.ProductsAndServices) Then
			Continue;
		EndIf;
		ProductsDescription = Description(TabSecRow.ProductsAndServices, TabSecRow.Characteristic, TabSecRow.Specification);
		ProductionList.Add(TabSecRow.ConnectionKey, ProductsDescription);
		Items.InventoryDistributionProductsAndServicesProduction.ChoiceList.Add(TabSecRow.ConnectionKey, ProductsDescription);
		If Items.InventoryCustomerOrder.ChoiceList.FindByValue(TabSecRow.CustomerOrder)=Undefined Then
			OrderDescription = ?(ValueIsFilled(TabSecRow.CustomerOrder), String(TabSecRow.CustomerOrder), NStr("en='<Not specified>';vi='<Chưa chỉ ra>'"));
			Items.InventoryCustomerOrder.ChoiceList.Add(TabSecRow.CustomerOrder, OrderDescription);
		EndIf; 
	EndDo;
	Items.InventoryCustomerOrder.ChoiceList.SortByPresentation();
	For Each ListElement In Items.InventoryCustomerOrder.ChoiceList Do
		Items.OperationsCustomerOrder.ChoiceList.Add(ListElement.Value, ListElement.Presentation);
	EndDo;
	For Each ListElement In Items.InventoryDistributionProductsAndServicesProduction.ChoiceList Do
		Items.OperationsProductsAndServices.ChoiceList.Add(ListElement.Value, ListElement.Presentation);
	EndDo; 
	
	CurrentRow = ProductionList.FindByValue(ConnectionKey);
	If CurrentRow=Undefined Then
		CurrentRow = ProductionList[0];
	EndIf; 
	Items.ProductionList.CurrentRow = CurrentRow.GetID();
	
	If Object.ManualDistribution Then
		UpdateInventoryDistributionOnForm();
	EndIf;
	
EndProcedure

&НаСервере
Procedure DistributeServer()
	
	If Not Object.ManualDistribution Then
		Return;
	EndIf; 
	
	FillTSAtributesByHeader(Object);
	ProductionServer.DistribInventory(Object.Products, Object.Inventory, Object.InventoryDistribution);
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
	Items.InventoryDistributionProductsAndServicesProduction.Visible = NoFulter;
	
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
		If ProductsRow.ConnectionKey=0 And Not ReadOnly Then
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
	EndDo;
	
	RenumberDistribution(InventoryDistribution);
	DisplayControlMarks(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillProductDataInDistributionRow(DistributionRow, ProductRow = Undefined)
	
	If ProductRow=Undefined Then
		DistributionRow.ProductsAndServicesProduction = Undefined;
		DistributionRow.CharacteristicProduction = Undefined;
		DistributionRow.SpecificationProduction = Undefined;
		DistributionRow.MeasurementUnitProduction = Undefined;
		DistributionRow.QuantityProduction = 0;
		DistributionRow.ReserveProduction = 0;
		DistributionRow.BatchProduction = Undefined;
		DistributionRow.StructuralUnitProduction = Undefined;
		DistributionRow.ConnectionKeyProduct = 0;
		DistributionRow.CustomerOrder = Undefined; 
	Else
		DistributionRow.ProductsAndServicesProduction = ProductRow.ProductsAndServices;
		DistributionRow.CharacteristicProduction = ProductRow.Characteristic;
		DistributionRow.SpecificationProduction = ProductRow.Specification;
		DistributionRow.MeasurementUnitProduction = ProductRow.MeasurementUnit;
		DistributionRow.QuantityProduction = ProductRow.Quantity;
		DistributionRow.ReserveProduction = ProductRow.Reserve;
		DistributionRow.BatchProduction = ProductRow.Batch;
		DistributionRow.StructuralUnitProduction = ProductRow.StructuralUnit;
		DistributionRow.ConnectionKeyProduct = ProductRow.ConnectionKey;
		DistributionRow.CustomerOrder = ProductRow.CustomerOrder; 
	EndIf; 
	
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
		If ControlRow.QuantityInventory=ControlRow.QuantityDistribution Then
			Continue;
		EndIf;
		DistributionErrorExist = True;
		FilterStructure = New Structure(InventoryColumnsName(Object));
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

&AtClientAtServerNoContext
Function Description(Value1 = Undefined, Value2 = Undefined, Value3 = Undefined)
	
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

&AtClientAtServerNoContext
Function InventoryColumnsName(Object)
	
	Return "Stage, ProductsAndServices, Characteristic, Batch, Specification, MeasurementUnit"
	+?(Object.OperationKind=PredefinedValue("Enum.OperationKindsProductionOrder.Assembly"), ", StructuralUnit, CustomerOrder", "");
	
EndFunction

&AtClientAtServerNoContext
Procedure RenumberDistribution(InventoryDistribution)
	
	Num = 1;
	For Each TabSecRow In InventoryDistribution Do
		TabSecRow.LineNumber = Num;
		Num = Num+1;
	EndDo; 	
	
EndProcedure

&AtClient
Procedure FillTeam(Command)
	
	FillTeamContentOnServer(Object.Performer);
	
EndProcedure

&AtServer
Procedure FillTeamContentOnServer(Team, ConnectionKey = Undefined)

	If ConnectionKey=Undefined Then
		Object.Brigade.Clear();
	EndIf; 
	
	If ValueIsFilled(Team) And TypeOf(Team) = Type("СправочникСсылка.Teams") Then
		
		ContentTable = Catalogs.Teams.BrigadeContent(Team, Object.Company, Object.Date);
		
		For Each TabSecRow In ContentTable Do
			NewRow = Object.Brigade.Add();
			FillPropertyValues(NewRow, TabSecRow);
			NewRow.КТУ = 1;
			//Если Object.ПоложениеСтруктурнойЕдиницыОпераций=Перечисления.ПоложениеРеквизитаНаФорме.ВШапке Тогда
				NewRow.StructuralUnit = Object.StructuralUnit;
			//КонецЕсли;
			If ConnectionKey<>Undefined Then
				NewRow.ConnectionKey = ConnectionKey;
			EndIf; 
		EndDo; 
		
	EndIf;	
	
	Modified = True;

EndProcedure

&AtClient
Procedure FillBySpecification(Command)
	
	If Object.Operations.Count() <> 0 Then
		
		Answer = Undefined;
		
		
		ShowQueryBox(New NotifyDescription("FillOperationsCompliting", ThisObject), NStr("en = 'The tabular section ""Operation"" will be replenished! Continue the operation?'; ru = 'Табличная часть ""Операции"" будет перезаполнена! Продолжить выполнение операции?'; vi = 'Phần bảng ""Thao tác"" sẽ được điền lại! Tiếp tục?'"), 
			QuestionDialogMode.YesNo, 0);
			Return;
		
	EndIf;
	
	FillOperationFragment();

EndProcedure

&AtClient
Procedure FillOperationsCompliting(Result, AdditionalParameters) Export
	
	Answer = Result;
	
	If Answer = DialogReturnCode.No Then
		Return;
	EndIf;
	
	FillOperationFragment();
	
EndProcedure

&AtClient
Procedure FillOperationFragment()
	
	FillOperationsServer();
	
EndProcedure

&AtServer
Procedure FillOperationsServer()
	
	Document = FormAttributeToValue("Object");
	StackNodesSpecifications = New Array;
	Document.FillOperationsBySpecification();
	ValueToFormAttribute(Document, "Object");
	
	UpdateDataCaсheServer();
	FillServiceDataAfterReading(Object);
	FillStagesUsingAttributes();
	
	DisplayControlMarks(ThisObject);
	UpdateAutoMarksOnOperationsChange(ThisObject);
	
EndProcedure 

&AtServer
Procedure UpdateDataCaсheServer(StaffArray = Undefined)
	
	If StaffArray=Undefined Then
		StaffArray = New Array;
		If Object.PerformerPosition = PredefinedValue("Enum.AttributePositionOnForm.InTabularSection") Then
			For Each TabSecRow In Object.Operations Do
				If Not ValueIsFilled(TabSecRow.Performer) Or TypeOf(TabSecRow.Performer)<>Type("CatalogRef.Employees") Then
					Continue;
				EndIf; 
				StaffArray.Add(TabSecRow.Performer);
			EndDo;
			For Each TabSecRow In Object.Brigade Do
				If Not ValueIsFilled(TabSecRow.Employee) Then
					Continue;
				EndIf; 
				StaffArray.Add(TabSecRow.Employee);
			EndDo;
		ElsIf Object.PerformerPosition = PredefinedValue("Enum.AttributePositionOnForm.InHeader") Then
			Если ValueIsFilled(Object.Performer) И ТипЗнч(Object.Performer)=Тип("CatalogRef.Employees") Тогда
				StaffArray.Добавить(Object.Performer);
			ИначеЕсли ТипЗнч(Object.Performer)=Тип("CatalogRef.Teams") Then
				For Each TabularSectionRow In Object.Brigade Do
					If Not ValueIsFilled(TabularSectionRow.Employee) Then
						Continue;
					EndIf;
					StaffArray.Add(TabularSectionRow.Сотрудник);
				EndDo;
			EndIf; 
		EndIf;
	EndIf;
	
	ExecuteQuery = FormParameters.UseTechOperations And StaffArray.Count()>0;
	
	If ExecuteQuery Then
		
		StaffArray = CommonUseClientServer.CollapseArray(StaffArray);
		
		Query = New Query;
		Query.SetParameter("Company", Object.Company);
		Query.SetParameter("StaffArray", StaffArray);
		Query.SetParameter("SlicePeriod", ?(ValueIsFilled(Object.Date), Object.Date, EndOfDay(CurrentDate())));
		Query.Text =
		"SELECT
		|	Staff.Ref AS Employee,
		|	ISNULL(StaffSliceLast.StructuralUnit, VALUE(Catalog.StructuralUnits.EmptyRef)) AS StructuralUnit
		|FROM
		|	Catalog.Employees AS Staff
		|		LEFT JOIN InformationRegister.Employees.SliceLast(&SlicePeriod, Company = &Company) AS StaffSliceLast
		|		ON (StaffSliceLast.Employee = Staff.Ref)
		|WHERE
		|	Staff.Ref IN(&StaffArray)";
		Selection = Query.Execute().Select();
		
		If TypeOf(DepartmentCashe)=Type("FixedMap") Then
			DepartmentsMap = New Map(DepartmentCashe);
		Else
			DepartmentsMap = New Map;
		EndIf; 
		
		While Selection.Next() Do
			DepartmentsMap.Insert(Selection.Employee, Selection.StructuralUnit);
		EndDo;
		
		DepartmentCashe = New FixedMap(DepartmentsMap);
		
	Else
		
		DepartmentCashe = New FixedMap(New Map);
		
	EndIf; 
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillServiceDataAfterReading(Object)
	
	IF Object.PerformerPosition = PredefinedValue("Enum.AttributePositionOnForm.InTabularSection") Then
		For Each CurrentRow In Object.Operations Do
			CurrentRow.ItsTeam = (TypeOf(CurrentRow.Performer)=Type("СправочникСсылка.Teams"));
			If CurrentRow.ItsTeam Then
				CurrentRow.ChangeContent = NStr("en='Change content and LPR';vi='Thay đổi thành phần LPR'");
			EndIf;
		EndDo;
	Else
		For Each CurrentRow In Object.Operations Do
			CurrentRow.ItsTeam = False;
		EndDo; 
	EndIf;
	
	For Each TabSecRow In Object.Operations Do
		ProductRow = RowByKey(Object.Products, TabSecRow.ConnectionKeyProduct);
		FillProductsDataInOperationRow(Object, TabSecRow, ProductRow);
	EndDo; 	
		
EndProcedure

&AtServer
Procedure FillStagesUsingAttributes()
	
	If Not FormParameters.UseProductionStages Then
		Return;
	EndIf;
	If Object.OperationKind=Enums.OperationKindsProductionOrder.Disassembly Then
		Return;
	EndIf;
	If StructuralUnitType<>Enums.StructuralUnitsTypes.Department Then
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

&AtClientAtServerNoContext
Procedure UpdateAutoMarksOnOperationsChange(Form)
	
	Object = Form.Object;
	Items = Form.Items;
	
	OperationsFilled = (Object.Operations.Count()>0);
	CommonUseClientServer.SetFormItemProperty(Items, "Performer", "ReadOnly", Not OperationsFilled);
	CommonUseClientServer.SetFormItemProperty(Items, "StructuralUnitOperation", "ReadOnly", Not OperationsFilled);
	CommonUseClientServer.SetFormItemProperty(Items, "Performer", "AutoMarkIncomplete", OperationsFilled);
	CommonUseClientServer.SetFormItemProperty(Items, "StructuralUnitOperation", "AutoMarkIncomplete", OperationsFilled);
	If Not OperationsFilled Then
		CommonUseClientServer.SetFormItemProperty(Items, "Performer", "MarkIncomplete", False);
		CommonUseClientServer.SetFormItemProperty(Items, "StructuralUnitOperation", "MarkIncomplete", False);
	EndIf;
	
	If Not Form.ReadOnly And Object.Performer=Undefined Then
		Object.Performer = PredefinedValue("Справочник.Employees.ПустаяСсылка");
	EndIf; 
	
EndProcedure

&AtClientAtServerNoContext
Function RowByKey(Table, ConectionKey, FieldName = "ConnectionKey")
	
	FilterStructure = New Structure;
	FilterStructure.Insert(FieldName, ConectionKey);
	Rows = Table.FindRows(FilterStructure);
	If Rows.Count()=0 Then
		Return Undefined;
	Else
		Return Rows[0];
	EndIf; 
	
EndFunction

&AtClientAtServerNoContext
Procedure FillProductsDataInOperationRow(Object, OperationRow, ProductRow)
	
	If ProductRow=Undefined Then
		ChangeFieldsStructure = New Structure;
		ChangeFieldsStructure.Insert("ConnectionKeyProduct", 0);
		ChangeFieldsStructure.Insert("ProductsAndServices", PredefinedValue("Catalog.ProductsAndServices.EmptyRef"));
		ChangeFieldsStructure.Insert("Characteristic", PredefinedValue("Catalog.ProductsAndServicesCharacteristics.EmptyRef"));
		ChangeFieldsStructure.Insert("Batch", PredefinedValue("Catalog.ProductsAndServicesBatches.EmptyRef"));
		ChangeFieldsStructure.Insert("Specification", PredefinedValue("Catalog.Specifications.EmptyRef"));
	Else
		ChangeFieldsStructure = New Structure("ConnectionKeyProduct, Characteristic, Batch, Specification, ConnectionKeyProduct");
		FillPropertyValues(ChangeFieldsStructure, ProductRow);
		ChangeFieldsStructure.ConnectionKeyProduct = ProductRow.ConnectionKey;
	EndIf;
	
	If Object.CustomerOrderPosition=ПредопределенноеЗначение("Enum.AttributePositionOnForm.InTabularSection") Then
		If ProductRow=Undefined Then
			ChangeFieldsStructure.Insert("CustomerOrder", PredefinedValue("Document.CustomerOrder.EmptyRef"));
		Else
			ChangeFieldsStructure.Insert("CustomerOrder", ProductRow.CustomerOrder);
		EndIf; 
	Else
		ChangeFieldsStructure.Вставить("CustomerOrder", Object.CustomerOrder);
	КонецЕсли;
	
	For Each KeyValue In ChangeFieldsStructure Do
		If OperationRow[KeyValue.Key]=KeyValue.Value Then
			Continue;
		EndIf; 
		OperationRow[KeyValue.Key] = KeyValue.Value;
	EndDo; 
	
EndProcedure

&AtClient
Procedure GroupByFiltersClick(Item)
	
	NewVisibleValue = Not Items.FiltersSettingsAndExtraInfo.Visible;
	WorkWithFiltersClient.CollapseExpandFiltesPanel(ThisObject, NewVisibleValue);

EndProcedure

&AtClient
Procedure DecorationExpandFiltersClick(Item)
	
	NewVisibleValue = Not Items.FiltersSettingsAndExtraInfo.Visible;
	WorkWithFiltersClient.CollapseExpandFiltesPanel(ThisObject, NewVisibleValue);

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
Procedure Distrib(Command)
	
	If Object.InventoryDistribution.Count() <> 0 Then
		
		Answer = Undefined;
		
		ShowQueryBox(New NotifyDescription("DistribCompliting", ThisObject), NStr("en = 'The spreadsheet ""Distribution"" will be refilled! Continue the operation?'; ru = 'Табличная часть ""Распределение"" будет перезаполнена! Продолжить выполнение операции?'; vi = 'Phần bảng ""Phân bổ"" sẽ được điền lại! Tiếp tục?'"),
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
Procedure UpdateDistributionHelpText()
	
	DescriptionTextDistributionErrors = "";
	
	CurrentRow = Items.InventoryDistribution.CurrentData;
	If CurrentRow=Undefined Then
		DescriptionTextDistributionErrors = NStr("en='The distribution result does not match the data on materials and / or products.';ru='Результат распределения не соответствует данным о материалах и/или продукции.';vi='Kết quả phân bổ không khớp với dữ liệu trên vật liệu và / hoặc sản phẩm.'");
		Return;
	ElsIf ValueIsFilled(CurrentRow.ProductsAndServicesProduction) And Not CurrentRow.ErrorQuantity Then
		DescriptionTextDistributionErrors = NStr("en='The distribution result does not match the data on materials and / or products. For details, highlight the warning line';ru='Результат распределения не соответствует данным о материалах и/или продукции. Для подробной информации выделите строку с предупреждением.';vi='Kết quả phân bổ không khớp với dữ liệu trên vật liệu và / hoặc sản phẩm. Để biết chi tiết, chọn dòng cảnh báo.'");
		Return;
	EndIf;
	
	FilterStructure = New Structure(InventoryColumnsName(Object));
	FillPropertyValues(FilterStructure, CurrentRow);
	TotalStructure = InventoryTotal(FilterStructure);
	MeasurementUnit = String(FilterStructure.MeasurementUnit);
	
	If Not ValueIsFilled(CurrentRow.ProductsAndServicesProduction) Then
		DescriptionTextDistributionErrors = DescriptionTextDistributionErrors 
		+ NStr("En='Not specified distribution products';ru='Не указана продукция распределения.';vi='Không quy định sản phẩm phân bổ.'"); 
	EndIf; 
	
	If CurrentRow.ErrorQuantity Then
		DescriptionTextDistributionErrors = DescriptionTextDistributionErrors 
		+ StrTemplate(NStr("en='Отличается количество материалов (%1 %2) и распределения (%3 %4). ';vi='Lượng vật liệu (%1%2) và phân bổ (%3 %4) khác nhau.'"), TotalStructure.QuantityInventory, MeasurementUnit, TotalStructure.QuantityDistribution, MeasurementUnit); 
	EndIf; 
	
EndProcedure

&AtClient
Procedure InventoryDistributionOnActivateRow(Item)
	
	UpdateDistributionHelpText();
	
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
		FillHeaderData(Item.CurrentData);
	Else
		FieldsStructure = New Structure(InventoryColumnsName(Object));
		FillPropertyValues(FieldsStructure, Item.CurrentData);
		OldRowData = New FixedStructure(FieldsStructure);
	EndIf; 
	
EndProcedure

&AtClient
Procedure InventoryDistributionOnEditEnd(Item, NewRow, CancelEdit)
	
	UpdateDataTSInventoryDistribution(ThisObject);
	UpdateControlCacheOnDataChange(Item.CurrentData);
	
EndProcedure

&AtClient
Procedure InventoryDistributionAfterDeleteRow(Item)
	
	UpdateDataTSInventoryDistribution(ThisObject);
	UpdateControlCacheOnDataChange();
	

EndProcedure

&AtClient
Procedure InventoryDistributionDragStart(Item, DragParameters, Perform)
	
	DragData = New Structure;
	DragData.Insert("Event", "ПерераспределениеМатериалов");
	DragData.Insert("Row", Item.CurrentRow);
	
	DragParameters.Value = CommonUseClientServer.ValueInArray(DragData);

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
Procedure FillHeaderData(TSRow, TSName = "Inventory")
	
	ItsAssembly = (Object.OperationKind = PredefinedValue("Enum.OperationKindsProductionOrder.Assembly"));
	ItsDisassembly = (Object.OperationKind = PredefinedValue("Enum.OperationKindsProductionOrder.Disassembly"));
	
	FieldStructure = New Structure;
	If Object.CustomerOrderPosition=PredefinedValue("Enum.AttributePositionOnForm.InHeader") Then
		FieldStructure.Insert("CustomerOrder", Object.CustomerOrder);
	EndIf;
	
	If Object.PerformerPosition = PredefinedValue("Enum.AttributePositionOnForm.InHeader") 
	And  ItsAssembly Then
		If TSName="Products" Then
			FieldStructure.Insert("StructuralUnit", PredefinedValue("Справочник.StructuralUnits.ПустаяСсылка"));
		Else
			FieldStructure.Insert("StructuralUnit", Object.StructuralUnitReserve);
		EndIf; 
	EndIf; 
	
	If Object.PerformerPosition = PredefinedValue("Enum.AttributePositionOnForm.InHeader") 
	And  ItsDisassembly Then
		If TSName="Products" Then
			FieldStructure.Insert("StructuralUnit", Object.StructuralUnitReserve);
		Else
			FieldStructure.Insert("StructuralUnit", PredefinedValue("Catalog.StructuralUnits.EmptyRef"));
		EndIf; 
	EndIf;
	
	FillPropertyValues(TSRow, FieldStructure);
	
EndProcedure

&AtClient
Procedure FillBrigade(Command)
	
	FillTeamContentOnServer(Object.Performer);

EndProcedure

&AtClient
Procedure InventoryOnChange(Item)
	
	UpdateStructuralUnitReserveMark();
	
EndProcedure

&AtClient
Procedure UpdateStructuralUnitReserveMark() 
	
	ReserveExist = (Object.Products.Total("Reserve")>0);
	CommonUseClientServer.SetFormItemProperty(Items, "ProductsStructuralUnitReserve", "AutoMarkIncomplete", ReserveExist);
	If Not ReserveExist Then
		CommonUseClientServer.SetFormItemProperty(Items, "ProductsStructuralUnitReserve", "MarkIncomplete", False);
	EndIf;
	
	ReserveExist = (Object.Inventory.Total("Reserve")>0);
	CommonUseClientServer.SetFormItemProperty(Items, "InventoryStructuralUnitReserve", "AutoMarkIncomplete", ReserveExist);
	If Not ReserveExist Then
		CommonUseClientServer.SetFormItemProperty(Items, "InventoryStructuralUnitReserve", "MarkIncomplete", False);
	EndIf;
	
EndProcedure

&AtClient
Procedure InventoryBeforeDeleteRow(Item, Cancel)
	
	If Cancel Or Not Object.ManualDistribution Then
		OldRowData = Undefined;
	ElsIf Items.Inventory.SelectedRows.Count()>1 Then
		StoredData = New Array;
		For Each SelectedRow In Items.Inventory.SelectedRows Do
			CurrentRowData = Items.Inventory.RowData(SelectedRow);
			FieldStructure = New Structure(InventoryColumnsName(Object));
			FillPropertyValues(FieldStructure, CurrentRowData);
			StoredData.Add(New FixedStructure(FieldStructure));
		EndDo;
		OldRowData = New FixedArray(StoredData);
	ElsIf Items.Inventory.SelectedRows.Count()=1 Then
		FieldStructure = New Structure(InventoryColumnsName(Object));
		FillPropertyValues(FieldStructure, Item.CurrentData);
		OldRowData = New FixedStructure(FieldStructure);
	Else
		OldRowData = Undefined;
	EndIf; 

EndProcedure

&AtClient
Procedure InventoryOnStartEdit(Item, NewRow, Clone)
	
	CurrentRow = Item.CurrentData;
	
	If NewRow And Clone Then
		CurrentRow.ConectionKey = 0;
	EndIf;
		
	TabularSectionName = "Inventory";
	
	If NewRow Or CurrentRow.ConnectionKey=0 Then
		SmallBusinessClient.AddConnectionKeyToTabularSectionLine(ThisObject);
	EndIf; 
	
	If NewRow And Not Clone Then
		OldRowData = Undefined;
		FillHeaderData(CurrentRow);
	ElsIf Not NewRow Then 
		FieldsStructure = New Structure(InventoryColumnsName(Object));
		FillPropertyValues(FieldsStructure, CurrentRow);
		OldRowData = New FixedStructure(FieldsStructure);
	EndIf;

EndProcedure

&AtClient
Procedure InventoryOnEditEnd(Item, NewRow, CancelEdit)
	
	UpdateControlCacheOnDataChange(Item.CurrentData);

EndProcedure

&AtClient
Procedure InventoryAfterDeleteRow(Item)
	
	If Not Object.ManualDistribution Then
		SetPagePicture(ThisObject);
	EndIf;
	
	If TypeOf(OldRowData)=Type("FixedArray") Then
		Values = New Array(OldRowData);
		For Each Value In Values Do
			OldRowData = Value;
			UpdateControlCacheOnDataChange();
		EndDo; 
	Else
		UpdateControlCacheOnDataChange();
	EndIf; 
	
	UpdateStructuralUnitReserveMark(); 

EndProcedure

&AtClient
Procedure InventoryStageStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure InventoryStageAutoComplete(Item, Text, ChoiceData, DataGetParameters, Wait, StandardProcessing)
	
	StandardProcessing = False;
	
	SpecsArray = New Array;
	For Each TabSecRow In Object.Products Do
		SpecsArray.Add(TabSecRow.Specification);
	EndDo; 
	ChoiceData = New ValueList;
	ChoiceData.LoadValues(ProductionStage(SpecsArray));
	UpdateEmptyStageDescriptiion(ChoiceData); 
	
EndProcedure

&AtServerNoContext
Function ProductionStage(Specifications)
	
	Return ProductionServer.ProductionStagesOfSpecifications(Specifications);	
	
EndFunction

&AtClientAtServerNoContext
Procedure UpdateEmptyStageDescriptiion(List)
	
	If List.Count()>0 And Not ValueIsFilled(List[0].Value) Then
		List[0].Description = NStr("en='<Without stages>';vi='<Không có công đoạn>'");
	EndIf; 
	
EndProcedure

&AtServer
Procedure FillFormParamaters()
	
	FormParameters = New Structure;
	FormParameters.Insert("InventoryReservation", GetFunctionalOption("InventoryReservation"));
	FormParameters.Insert("AccountingBySeveralDepartments", GetFunctionalOption("AccountingBySeveralDepartments"));
	FormParameters.Insert("UseTechOperations", GetFunctionalOption("UseTechOperations"));
	FormParameters.Insert("UseProductionStages", GetFunctionalOption("UseProductionStages"));
	
EndProcedure

&AtClient
Procedure OperationsProductsAndServicesClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure OperationsProductsAndServicesChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	StandardProcessing = False;
	If TypeOf(SelectedValue)<>Type("Number") Then
		Return;
	EndIf; 	
	
	ProductsRow = RowByKey(Object.Products, SelectedValue);
	If ProductsRow=Undefined Then
		Return;
	EndIf; 
	
	CurrentRow = Items.Operations.CurrentData;
	
	FillProductsDataInOperationRow(Object, CurrentRow, ProductsRow);
	OnChangeProductsAndServicesCharctericticOperations();
	Var_SelectedValue = ProductsRow.ProductsAndServices;
	
	If Items.Find("OperationsOperation")<>Undefined Then
		Items.Operations.CurrentItem = Items.OperationsOperation;
	EndIf; 
	

EndProcedure

&AtClient
Procedure OnChangeProductsAndServicesCharctericticOperations()
	
	TabSecRow = Items.Operations.CurrentData;
	
	DataStructure = New Structure;
	DataStructure.Insert("ProductsAndServices", TabSecRow.ProductsAndServices);
	DataStructure.Insert("Characteristic", TabSecRow.Characteristic);
	DataStructure.Insert("Specification", TabSecRow.Specification);
	
	DataStructure = GetDataProductsAndServicesOnChange(DataStructure, "Operations");
	
	If ValueIsFilled(DataStructure.Operation) Then
		TabSecRow.Operation 			= DataStructure.Operation;
		TabSecRow.MeasurementUnit 	= DataStructure.MeasurementUnit;
		TabSecRow.NormRate 		= DataStructure.NormRate;
		CalculateOperationDuration();
	EndIf; 
	
EndProcedure

&AtClient
Procedure CalculateOperationDuration()

	CurrentRow = Items.Operations.CurrentData;
	CurrentRow.NormRate = CurrentRow.TimeRate * CurrentRow.QuantityPlan;
	
EndProcedure

Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Колонка "Спецификация"
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.Products.ProductsAndServicesType", Enums.ProductsAndServicesTypes.Service);
	WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, Items.ProductsSpecification.Name);
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.MinorInscriptionText);
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Text", NStr("en='<not using>';ru='<Не используются>';vi='<Không sử dụng>'"));
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Enabled", False);

	
	// Операции
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.Operations.ItsTeam", False);
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "OperationsChangeContent");
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Visible", False);
	
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.Operations.ItsTeam", True);
	//WorkWithForm.ДобавитьЭлементОтбораКомпоновкиДанных(НовоеУсловноеОформление.Отбор, "Объект.ПоложениеСтруктурнойЕдиницыОпераций", Перечисления.ПоложениеРеквизитаНаФорме.ВТабличнойЧасти);
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "OperationsStructuralUnit");
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Visible", False);
	
	// Этапы производства
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.Products.UseProductionStages", False);
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "ProductsCompletiveStageDepartment");
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Enabled", False);
	
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.Products.UseProductionStages", True);
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.Products.CompletiveStageDepartment", Catalogs.StructuralUnits.EmptyRef());
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "ProductsCompletiveStageDepartment");
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "MarkIncomplete", True);

	
EndProcedure

&AtClient
Procedure OperationsPerfomerOnChange(Item)
	
	UpdateDataCaches();
	TabSecRow = Items.Operations.CurrentData;
	FillServiceDataInOperationRow(Object, TabSecRow);
	If Object.StructuralUnitOperationPosition=PredefinedValue("Enum.AttributePositionOnForm.InHeader") And Not TabSecRow.ItsTeam Then
		TabSecRow.StructuralUnit = DepartmentCashe.Get(TabSecRow.Performer);
	ElsIf Object.StructuralUnitOperationPosition=PredefinedValue("Enum.AttributePositionOnForm.InHeader") Then
		TabSecRow.StructuralUnit = Object.StructuralUnitOperation;
	EndIf;
	If TabSecRow.ItsTeam Then
		If TabSecRow.ConnectionKey=0 Then
			SmallBusinessClient.AddConnectionKeyToTabularSectionLine(ThisObject, TabSecRow);
		EndIf;
		SmallBusinessClientServer.DeleteRowsByConnectionKey(Object.Brigade, TabSecRow);
		FillTeamContentOnServer(TabSecRow.Performer, TabSecRow.ConnectionKey);
	EndIf; 

EndProcedure

Procedure UpdateDataCaches()
	
	StaffForUpdate = New Array;
	If Object.PerformerPosition=PredefinedValue("Перечисление.AttributePositionOnForm.InTabularSection") Then
	For Each TabSecRow In Object.Operations Do
		If Not ValueIsFilled(TabSecRow.Performer) Or TypeOf(TabSecRow.Performer)<>Type("СправочникСсылка.Teams") Then
			Continue;
		EndIf; 
		If DepartmentCashe.Get(TabSecRow.Performer)=Undefined Then
			StaffForUpdate.Add(TabSecRow.Performer);
		EndIf; 
	EndDo;
	For Each TabSecRow In Object.Brigade Do
		If Not ValueIsFilled(TabSecRow.Employee) Then
			Continue;
		EndIf; 
		If DepartmentCashe.Get(TabSecRow.Employee)=Undefined Then
			StaffForUpdate.Add(TabSecRow.Employee);
		EndIf; 
	EndDo;
	ElsIf Object.PerformerPosition=PredefinedValue("Enum.AttributePositionOnForm.InHeader") Then
		If ValueIsFilled(Object.Performer) And TypeOf(Object.Performer)=Type("CatalogRef.Employees") Then
			If DepartmentCashe.Get(Object.Performer)=Undefined Then
				StaffForUpdate.Add(Object.Performer);
			EndIf;
		ElsIf TypeOf(Object.Performer)=Type("CatalogRef.Teams") Then
			For Each TabSecRow In Object.Brigade Do
				If Not ValueIsFilled(TabSecRow.Employee) Then
					Continue;
				EndIf; 
				If DepartmentCashe.Get(TabSecRow.Сотрудник)=Undefined Then
					StaffForUpdate.Add(TabSecRow.Сотрудник);
				EndIf; 
			EndDo;
		EndIf; 
	EndIf;
	
	If StaffForUpdate.Count()>0 Then
		UpdateDataCaсheServer(StaffForUpdate);
	EndIf; 
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillServiceDataInOperationRow(Object, TabSecRow)
	
	TabSecRow.ItsTeam = (TypeOf(TabSecRow.Performer)=Type("СправочникСсылка.Teams"));
	If TabSecRow.ItsTeam  Then
		TabSecRow.ChangeContent = NStr("en = 'Change content and LPС'; vi = 'Thay đổi thành phần LPC'");
	EndIf;
	
	If ValueIsFilled(TabSecRow.ConnectionKey) Then
		ProductRow = RowByKey(Object.Products, TabSecRow.ConnectionKeyProduct);
		FillProductsDataInOperationRow(Object, TabSecRow, ProductRow);
	EndIf; 
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	FillStagesUsingAttributes();
	
	ResourcePlanningCM.RefillServiceAttributesResourceTable(Object.EnterpriseResources);
	
EndProcedure

&AtClient
Procedure OperationsSelection(Item, SelectedRow, Field, StandardProcessing)
	
	If Field.Name="OperationsChangeContent" Then
		StandardProcessing = False;
		OpenChangeContentForm(SelectedRow);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenChangeContentForm(ID)
	
	TabSecRow = Object.Operations.FindByID(ID);
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("ConnectionKey", TabSecRow.ConnectionKey);
	OpeningParameters.Insert("ID", TabSecRow.GetID());
	OpeningParameters.Insert("StructuralUnitPosition", Object.StructuralUnitOperationPosition);
	OpeningParameters.Insert("StructuralUnit", Object.StructuralUnitOperation);
	OpeningParameters.Insert("BrigadeContent", New Array);
	OpeningParameters.Insert("Brigade", TabSecRow.Performer);
	OpeningParameters.Insert("Company", Object.Company);
	OpeningParameters.Insert("Date", Object.Date);
	OpeningParameters.Insert("HideTabelNumber", True);
	
	FilterStructure = New Structure;
	FilterStructure.Insert("ConnectionKey", TabSecRow.ConnectionKey);
	ContentRows = Object.Brigade.FindRows(FilterStructure);
	For Each TabSecRow In ContentRows Do
		RowDescription = New Structure("Employee, LPR, StructuralUnit");
		FillPropertyValues(RowDescription, TabSecRow);
		OpeningParameters.BrigadeContent.Add(RowDescription);
	EndDo;
	
	OpenForm("Document.JobSheet.Form.FormChangeBrigadeContent", OpeningParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	
	// Изменен состав бригады в подчиненной форме
	If TypeOf(SelectedValue)=Type("Structure") And SelectedValue.Property("Event") And SelectedValue.Event="ChangingBrigadeContent" Then
		TabSecRow = Object.Operations.FindByID(SelectedValue.ID);
		If TabSecRow.ConnectionKey=0 Then
			SmallBusinessClient.AddConnectionKeyToTabularSectionLine(ThisObject, TabSecRow);
		EndIf;
		SmallBusinessClientServer.DeleteRowsByConnectionKey(Object.Brigade, TabSecRow);
		For Each RowDescription In SelectedValue.BrigadeContent Do
			NewRow = Object.Brigade.Add();
			FillPropertyValues(NewRow, RowDescription);
			NewRow.ConnectionKey = TabSecRow.ConnectionKey;
		EndDo;
	EndIf;

EndProcedure

&AtClient
Procedure FillByDistribution(Command)
	
	If Object.Inventory.Count() <> 0 Then
		
		Answer = Undefined;
		
		
		ShowQueryBox(New NotifyDescription("FillByDistributionCompleting", ThisObject), NStr("en='The tabular section ""Materials"" will be replenished! Continue the operation?';ru='Табличная часть ""Материалы"" будет перезаполнена! Продолжить выполнение операции?';vi='Phần bảng ""Nguyên vật liệu"" sẽ được điền lại! Tiếp tục?'"), 
				QuestionDialogMode.YesNo, 0);
		Return;
		
	EndIf;
	
	FillByDistributionFragment();

EndProcedure

&AtClient
Procedure FillByDistributionCompleting(Result, AdditionalParameters) Export
	
	Answer = Result;
	
	If Answer = DialogReturnCode.No Then
		Return;
	EndIf;
	
	FillByDistributionFragment();

EndProcedure

&AtClient
Procedure FillByDistributionFragment()
	
	FillByDistributionServer();
	
	UpdateStructuralUnitReserveMark(); 
	
EndProcedure // ЗаполнитьПоРаспределению()

&AtServer
Procedure FillByDistributionServer()
	
	If Not Object.ManualDistribution Then
		Return;
	EndIf; 
	
	ProductionServer.FillByDistribution(Object.Inventory, Object.InventoryDistribution);
	ProductionServer.FillDistributionControlCash(Object, DistributionControlCash);
	
	
	InventoryNotFilled = False;
	DisplayControlMarks(ThisObject);

EndProcedure

&AtClient
Procedure OrderOperationKindOnChange()
	
	
	ItsDisassembly = (Object.OperationKind=PredefinedValue("Enum.OperationKindsProductionOrder.Disassembly"));
	
	If ItsDisassembly Then
		
		For Each ProductsRow In Object.Products Do
			ProductsRow.Reserve = 0;
		EndDo;
		
	Else
		
		For Each RowInventory In Object.Inventory Do
			RowInventory.Reserve = 0;
		EndDo;
		
	EndIf;
	
	If ItsDisassembly Then
		For Each TabSecRow In Object.Inventory Do
			TabSecRow.Stage = PredefinedValue("Catalog.ProductionStages.EmptyRef");
		EndDo;
		For Each TabSecRow In Object.InventoryDistribution Do
			TabSecRow.Stage = PredefinedValue("Catalog.ProductionStages.EmptyRef");
		EndDo;
		For Each TabSecRow In Object.Operations Do
			TabSecRow.Stage = PredefinedValue("Catalog.ProductionStages.EmptyRef");
		EndDo;
	EndIf;
	
	//УстановитьВидимостьОтПользовательскихНастроек(ЭтотОбъект);
	
	UpdateTSWarehouse();
	
EndProcedure

&AtClientAtServerNoContext
Procedure StageVisibleControl(Form)
	
	Items = Form.Items;
	
	StageExist = ProductionWithStages(Form);
	CommonUseClientServer.SetFormItemProperty(Items, "InventoryStage", "Visible", StageExist);
	CommonUseClientServer.SetFormItemProperty(Items, "InventoryDistributionStage", "Visible", StageExist);
	CommonUseClientServer.SetFormItemProperty(Items, "OperationsStage", "Visible", StageExist);
	CommonUseClientServer.SetFormItemProperty(Items, "ProductsCompletiveStageDepartment", "Visible", StageExist);
	
EndProcedure

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
Procedure UpdateTSWarehouse()
	
	If Object.OperationKind=PredefinedValue("Enum.OperationKindsProductionOrder.Disassembly") Then
		TSName = "Products";
		TSNameCleaning = "Inventory";
	Else
		TSName = "Inventory";
		TSNameCleaning = "Products";
	EndIf;
	For Each TabSecRow In Object[TSName] Do
		TabSecRow.StructuralUnit = Object.StructuralUnitReserve;
	EndDo; 
	For Each TabSecRow In Object[TSNameCleaning] Do
		TabSecRow.StructuralUnit = PredefinedValue("Catalog.StructuralUnits.EmptyRef");
	EndDo; 
	
EndProcedure

&AtClientAtServerNoContext
Function ProductionWithStages(Form)
	
	Object = Form.Object;
	FormParameters = Form.FormParameters;
	
	If Object.OperationKind=PredefinedValue("Enum.OperationKindsProductionOrder.Disassembly") Then
		Return False;
	EndIf;
	If Form.StructuralUnitType<>PredefinedValue("Enum.StructuralUnitsTypes.Department") Then
		Return False;
	EndIf;
	
	If Not FormParameters.UseProductionStages Then
		Return False;
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
Procedure FillOperationServiceData(Object)
	
	For Each TabSecRow In Object.Operations Do
		FillServiceDataInOperationRow(Object, TabSecRow);
	EndDo; 	
	
EndProcedure

&AtClient
Procedure DocumentSetting(Command)
	
	DialogParameters = New Structure;
	DialogParameters.Insert("WarehousePositionInProductionDocuments", Object.WarehousePosition);
	If FormParameters.InventoryReservation Then
		DialogParameters.Insert("CustomerOrderPositionInProductionDocuments", Object.CustomerOrderPosition);
	EndIf; 
	DialogParameters.Insert("PerformerPositionJobSheet", Object.PerformerPosition);
	If FormParameters.AccountingBySeveralDepartments Then
		DialogParameters.Insert("StructuralUnitPositionJobSheet", Object.StructuralUnitOperationPosition);
	EndIf; 
	DialogParameters.Insert("WereMadeChanges", False);
	
	OpenForm(
		"CommonForm.DocumentSetting",
		DialogParameters,,,,,
		New NotifyDescription("HeaderTabularSectionComleting", ThisObject));

EndProcedure

&AtClient
Procedure HeaderTabularSectionComleting(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Structure") And Result.WereMadeChanges Then
		HeaderTabularSectionCompleting(Result);
	EndIf;
	
EndProcedure

&AtServer
Procedure HeaderTabularSectionCompleting(Val Result)
	
	If Result.Property("WarehousePositionInProductionDocuments")
		And Object.WarehousePosition <> Result.WarehousePositionInProductionDocuments Then
		
		Object.WarehousePosition = Result.WarehousePositionInProductionDocuments;
		If Object.OperationKind= Enums.OperationKindsProductionOrder.Disassembly Then
			TSName = "Products";
		Else
			TSName = "Inventory";
		EndIf; 
		For Each TabSecRow In Object[TSName] Do
			TabSecRow.StructuralUnit = Object.StructuralUnitReserve;
		EndDo; 
	EndIf; 
	
	If Result.Property("CustomerOrderPositionInProductionDocuments") 
		And Object.CustomerOrderPosition <> Result.CustomerOrderPositionInProductionDocuments Then
		
		Object.CustomerOrderPosition = Result.CustomerOrderPositionInProductionDocuments;
		For Each TabSecRow In Object.Products Do
			TabSecRow.CustomerOrder = Object.CustomerOrder;
		EndDo; 
		For Each TabSecRow In Object.Inventory Do
			TabSecRow.CustomerOrder = Object.CustomerOrder;
		EndDo; 
	EndIf; 
	
	If Result.Property("PerformerPositionJobSheet") 
		And Object.PerformerPosition<>Result.PerformerPositionJobSheet Then
		
		For Each TabSecRow In Object.Operations Do
			TabSecRow.Performer = Object.Performer;
		EndDo;
		If Result.PerformerPositionJobSheet = Enums.AttributePositionOnForm.InTabularSection Then
			If TypeOf(Object.Performer)=Type("СправочникСсылка.Teams") Then
				FilterStructure = New Structure;
				FilterStructure.Insert("ConectionKey", 0);
				ContentRows = Object.СоставБригады.FindRows(FilterStructure);
				For Each OperationRow In Object.Operations Do
					If OperationRow.ConectionKey=0 Then
						TabularSectionName = "Operations";
						OperationRow.ConnectionKey = SmallBusinessServer.CreateNewLinkKey(ThisObject);
					EndIf; 
					For Each ContentRow In ContentRows Do
						NewRow = Object.Brigade.Add();
						FillPropertyValues(NewRow, ContentRow);
						NewRow.ConnectionKey = OperationRow.ConnectionKey;
					EndDo; 
				EndDo; 
				For Each ContentRow In ContentRows Do
					Object.Brigade.Delete(ContentRow);
				EndDo; 
			EndIf; 
			Object.Performer = Undefined;
		Else
			Object.Brigade.Clear();
		EndIf; 
		Object.PerformerPosition = Result.PerformerPositionJobSheet;
	EndIf; 
	
	If Result.Property("StructuralUnitPositionJobSheet") 
		And Object.StructuralUnitOperationPosition <> Result.StructuralUnitPositionJobSheet Then
		
		If Result.StructuralUnitPositionJobSheet = Enums.AttributePositionOnForm.InHeader Then
			Object.StructuralUnitOperation = SmallBusinessReUse.GetValueOfSetting("MainDepartment");
			For Each TabSecRow In Object.Operations Do
				TabSecRow.StructuralUnit = Object.StructuralUnitOperation;
			EndDo; 
			For Each TabSecRow In Object.Brigade Do
				TabSecRow.StructuralUnit = Object.StructuralUnitOperation;
			EndDo; 
		Else
			For Each TabSecRow In Object.Operations Do
				TabSecRow.StructuralUnit = Object.StructuralUnitOperation;
			EndDo; 
			For Each TabSecRow In Object.Brigade Do
				TabSecRow.StructuralUnit = Object.StructuralUnitOperation;
			EndDo; 
			Object.StructuralUnitOperation = Catalogs.StructuralUnits.EmptyRef();
		EndIf; 
		Object.StructuralUnitOperationPosition = Result.StructuralUnitPositionJobSheet;
	EndIf; 
	
	SetVivisibleFromUserSettings(ThisObject);
	
	FillServiceDataAfterReading(Object);
	If Object.ManualDistribution Then
		ProductionServer.FillDistributionControlCash(Object, DistributionControlCash);
		DisplayControlMarks(ThisObject);
	EndIf; 
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetVivisibleFromUserSettings(Form)
	
	Object = Form.Object;
	Items = Form.Items;
	ItDisassembly = (Object.OperationKind=PredefinedValue("Enum.OperationKindsProductionOrder.Disassembly"));
	ItAssembly = (Object.OperationKind=PredefinedValue("Enum.OperationKindsProductionOrder.Assembly"));
	
	CustomerOrderIsFill = CustomerOrderIsFilled(Object);
	
	// Склад
	If Object.WarehousePosition = PredefinedValue("Enum.AttributePositionOnForm.InTabularSection") Then
		CommonUseClientServer.SetFormItemProperty(Items, "ProductionStructuralUnitReserve", "Visible", False);
		CommonUseClientServer.SetFormItemProperty(Items, "InventoryStructuralUnitReserve", "Visible", False);
		CommonUseClientServer.SetFormItemProperty(Items, "ProductsStructuralUnitTabularSection", "Visible", ItDisassembly And CustomerOrderIsFill);
		CommonUseClientServer.SetFormItemProperty(Items, "InventoryStructuralUnitTabularSection", "Visible", ItAssembly And CustomerOrderIsFill);
		CommonUseClientServer.SetFormItemProperty(Items, "InventoryDistributionStructuralUnit", "Visible", ItAssembly And CustomerOrderIsFill);
		Form.WarehouseInHeader = False;
	Else
		CommonUseClientServer.SetFormItemProperty(Items, "ProductionStructuralUnitReserve", "Visible", ItDisassembly And CustomerOrderIsFill);
		CommonUseClientServer.SetFormItemProperty(Items, "InventoryStructuralUnitReserve", "Visible", ItAssembly And CustomerOrderIsFill);
		CommonUseClientServer.SetFormItemProperty(Items, "ProductsStructuralUnitTabularSection", "Visible", False);
		CommonUseClientServer.SetFormItemProperty(Items, "InventoryStructuralUnitTabularSection", "Visible", False);
		CommonUseClientServer.SetFormItemProperty(Items, "InventoryDistributionStructuralUnit", "Visible", False);
		Form.WarehouseInHeader = True;
	EndIf;
	
	// Заказ покупателя
	ЗаказВТабличнойЧасти = (Object.CustomerOrderPosition = PredefinedValue("Enum.AttributePositionOnForm.InTabularSection"));
	CommonUseClientServer.SetFormItemProperty(Items, "ProductsCustomerOrder", "Visible", ЗаказВТабличнойЧасти);
	CommonUseClientServer.SetFormItemProperty(Items, "InventoryCustomerOrder", "Visible", ЗаказВТабличнойЧасти);
	CommonUseClientServer.SetFormItemProperty(Items, "InventoryDistributionCustomerOrder", "Visible", ЗаказВТабличнойЧасти);
	CommonUseClientServer.SetFormItemProperty(Items, "OperationsCustomerOrder", "Visible", ЗаказВТабличнойЧасти);
	CommonUseClientServer.SetFormItemProperty(Items, "GroupCustomerOrder", "Visible", Not ЗаказВТабличнойЧасти);
//	CommonUseClientServer.SetFormItemProperty(Items, "ПродукцияДобавитьИзЗаказов", "Видимость", ЭтоСборка И ЗаказВТабличнойЧасти);
	SetVisibleReserveColumn(Form);
	
	// Исполнитель
	If Object.PerformerPosition = PredefinedValue("Enum.AttributePositionOnForm.InTabularSection") Then
		CommonUseClientServer.SetFormItemProperty(Items, "GroupPerfomer", "Visible", False);
		CommonUseClientServer.SetFormItemProperty(Items, "OperationsPerfomerContent", "Visible", True);
		CommonUseClientServer.SetFormItemProperty(Items, "TSBrigade", "Visible", ShowPageTeam(Object));
	Else
		CommonUseClientServer.SetFormItemProperty(Items, "GroupPerfomer", "Visible", True);
		CommonUseClientServer.SetFormItemProperty(Items, "OperationsPerfomerContent", "Visible", False);
		CommonUseClientServer.SetFormItemProperty(Items, "TSBrigade", "Visible", ShowPageTeam(Object));
	EndIf;
	
	// Подразделение выполнения операций
	If Object.StructuralUnitOperationPosition = PredefinedValue("Enum.AttributePositionOnForm.InTabularSection") Then
		CommonUseClientServer.SetFormItemProperty(Items, "StructuralUnitOperation", "Visible", False);
		CommonUseClientServer.SetFormItemProperty(Items, "OperationsStructuralUnit", "Visible", Not ShowPageTeam(Object));
		CommonUseClientServer.SetFormItemProperty(Items, "BrigadeStructuralUnit", "Visible", ShowPageTeam(Object));
	Else
		CommonUseClientServer.SetFormItemProperty(Items, "StructuralUnitOperation", "Visible", True);
		CommonUseClientServer.SetFormItemProperty(Items, "OperationsStructuralUnit", "Visible", False);
		CommonUseClientServer.SetFormItemProperty(Items, "BrigadeStructuralUnit", "Visible", False);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function CustomerOrderIsFilled(Object)
	
	Return ValueIsFilled(Object.CustomerOrder) 
	Or Object.CustomerOrderPosition=PredefinedValue("Enum.AttributePositionOnForm.InTabularSection");	
	
EndFunction 

&AtClientAtServerNoContext
Function ShowPageTeam(Object)
	
	Return ValueIsFilled(Object.Performer) 
		And TypeOf(Object.Performer)=Type("СправочникСсылка.Teams") 
		And Object.PerformerPosition=PredefinedValue("Enum.AttributePositionOnForm.InHeader");
	
EndFunction
	
&AtClientAtServerNoContext
Procedure SetVisibleReserveColumn(Form)
	
	Object = Form.Object;
	Items = Form.Items;
	ItsDisassembly = (Object.OperationKind=PredefinedValue("Enum.OperationKindsProductionOrder.Disassembly"));
	CustomerOrderIsFilled = CustomerOrderIsFilled(Object);
	
	// Резерв
	CommonUseClientServer.SetFormItemProperty(Items, "ProductsReserve", "Visible", CustomerOrderIsFilled And ItsDisassembly);
	CommonUseClientServer.SetFormItemProperty(Items, "InventoryReserve", "Visible", CustomerOrderIsFilled And Not ItsDisassembly);
	CommonUseClientServer.SetFormItemProperty(Items, "InventoryChangeReserve", "Visible", CustomerOrderIsFilled And Not ItsDisassembly);
	
EndProcedure

&AtClient
Procedure OperationsQuantityPlanOnChange(Item)
	
	CalculateOperationDuration();
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillTSAtributesByHeader(Object, Attribute = "")

	// Заполнение склада
	FillStructuralUnit = (IsBlankString(Attribute) Or Attribute="StructuralUnit");
	
	If FillStructuralUnit And Object.WarehousePosition<>PredefinedValue("Enum.AttributePositionOnForm.InTabularSection") Then
		
		TabSec = ?(Object.OperationKind = PredefinedValue("Enum.OperationKindsProductionOrder.Disassembly"), Object.Products, Object.Inventory);
		
		For Each TabSecRow In TabSec Do
			TabSecRow.StructuralUnit = Object.StructuralUnitReserve;
		EndDo; 
		
		TabSec = ?(Object.OperationKind = PredefinedValue("Enum.OperationKindsProductionOrder.Disassembly"), Object.Inventory, Object.Products);
		
		For Each TabSecRow In TabSec Do
			TabSecRow.StructuralUnit = PredefinedValue("Catalog.StructuralUnits.EmptyRef");
		EndDo; 
		
	EndIf;
	
	// Заполнение заказа покупателя
	Fill = ((IsBlankString(Attribute) Or Attribute="CustomerOrder"));
	
	If Fill And Object.CustomerOrderPosition<>PredefinedValue("Enum.AttributePositionOnForm.InTabularSection") Then
		For Each TabSecRow In Object.Inventory Do
			TabSecRow.CustomerOrder = Object.CustomerOrder;
		EndDo; 
		For Each TabSecRow In Object.Products Do
			TabSecRow.CustomerOrder = Object.CustomerOrder;
		EndDo; 
		For Each TabSecRow In Object.Operations Do
			TabSecRow.CustomerOrder = Object.CustomerOrder;
		EndDo;
	EndIf;
	
EndProcedure 

&AtClient
Procedure ProductsSpecificationOnChange(Item)
	
	TabSecRow = Items.Products.CurrentData;
	
	DataStructure = Новый Структура;
	DataStructure.Insert("Specification", TabSecRow.Specification);
	DataStructure = SpecificationDataOnChange(DataStructure); //ПолучитьДанныеСпецификацияПриИзменении(DataStructure);
	
	TabSecRow.UseProductionStages = DataStructure.UseProductionStages;
	If TabSecRow.UseProductionStages
		И FormParameters.UseProductionStages
		И StructuralUnitType=PredefinedValue("Enum.StructuralUnitsTypes.Department") Then
		TabSecRow.CompletiveStageDepartment = Object.StructuralUnit;
	EndIf; 
	
	If ValueIsFilled(TabSecRow.Specification) И Object.Inventory.Count()>0 Then
		SetPagePicture(ThisObject, False);
	EndIf;
	
	UpdateProductsChoiseList();
	FillOperationServiceData(Object);
	StageVisibleControl(ThisObject);

EndProcedure

&AtServerNoContext
Function SpecificationDataOnChange(DataStructure)
	
	If GetFunctionalOption("UseProductionStages")
		And ValueIsFilled(DataStructure.Specification)
		And TypeOf(DataStructure.Specification) = Type("CatalogRef.Specifications") Then
		ProductionKind = CommonUse.ObjectAttributeValue(DataStructure.Specification, "ProductionKind");
		DataStructure.Вставить("UseProductionStages", ValueIsFilled(ProductionKind));
	Else
		DataStructure.Вставить("UseProductionStages", False);
	EndIf; 
	
	Return DataStructure;
	
EndFunction

&AtClient
Procedure DecorationWarningsInventoryCloseClick(Item)
	
	SetPagePicture(ThisObject, True);
	
EndProcedure

&AtClient
Procedure FillDataResourceTableOnForm()
	
	ResourceData = MapResourcesData();
	
	Items.EnterpriseResourcesPickupResources.Enabled = Not ThisForm.ReadOnly;
	Items.CompanyResourcesGroupCheck.Enabled = Not ThisForm.ReadOnly;
	
	For Each RowResources In Object.EnterpriseResources Do
		
		IsCounterDetails = ?(TypeOf(RowResources.CompleteAfter) = Type("Number"), True, False);
		
		ResourcesData = ResourceData.Get(RowResources.EnterpriseResource);
		
		If Not ResourcesData = Undefined Then
			FillPropertyValues(RowResources, ResourcesData)
		EndIf;
		
		SelectedWeekDays = ResourcePlanningCMClient.DescriptionWeekDays(RowResources);
		
		AddingByMonthYear = "";
		
		Start = RowResources.Start;
		WeekDayMonth = RowResources.WeekDayMonth;
		RepeatabilityDate = RowResources.RepeatabilityDate;
		
		If RowResources.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.Monthly")
										Or RowResources.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.Annually") Then
			
			If ValueIsFilled(RepeatabilityDate) Then
				
				AddingByMonthYear = ?(ValueIsFilled(RepeatabilityDate), NStr("en = ', every ; ru = 'каждый' ") 
										+ String(RepeatabilityDate) + Nstr("en='-ok ';ru=' -ok ';vi=' -ok'")+ResourcePlanningCMClient.GetMonthByNumber(RowResources.MonthNumber)+".","");
			ElsIf ValueIsFilled(WeekDayMonth) Then
				
				If ResourcePlanningCMClient.ItLastMonthWeek(Start) Then
					AddingByMonthYear = NStr("en=', In last. ';ru=', в конце';vi=', vào cuối'") + ResourcePlanningCMClient.MapNumberWeekDay(WeekDayMonth)+  Nstr("en=' month.';ru=' месяц';vi=' tháng.'");
				Else
				WeekMonthNumber = WeekOfYear(Start)-WeekOfYear(BegOfMonth(Start))+1;
				AddingByMonthYear = " "+ResourcePlanningCMClient.MapNumberWeekDay(WeekDayMonth) + NStr("en = ', every. ; ru = ' каждый.' ") +String(WeekMonthNumber)+ "-Iy" + Nstr("en=' Weeks';ru=' Недели';vi=' Tuần'");
				EndIf;
				
			ElsIf RowResources.LastMonthDay = True Then
				AddingByMonthYear = Nstr("en=', last day month.';ru=', последний день месяца';vi=', ngày cuối tháng'");
			EndIf;
			
		EndIf;
		
		Interjection = ?(RowResources.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.Weekly"),NStr("en='Every';vi='Mỗi';"), NStr("en='Each';vi='Mỗi';"));
		
		End = "";
		
		If RowResources.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.Weekly") Then
			End = NStr("en='Week';ru='Неделя';vi='Tuần'");
		ElsIf RowResources.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.Daily") Then
			End = NStr("en='Day';ru='День';vi='Ngày'");
		ElsIf RowResources.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.Monthly") Then
			End = NStr("en='Month';ru='Месяц';vi='Trong tháng tới'");
		ElsIf RowResources.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.Annually") Then
			End = NStr("en='Year';ru='Год';vi='Trong năm tới'");
		EndIf;
		
		If ValueIsFilled(RowResources.RepeatKind) 
			And Not RowResources.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.NoRepeat") Then
			
			SchedulePresentation = String(RowResources.RepeatKind)+", "+Interjection+" "+String(RowResources.RepeatInterval)+
			" "+ End+SelectedWeekDays+AddingByMonthYear;
		Else
			SchedulePresentation = Nstr("en='Not repeat';ru='не повторять';vi='Không lặp lại'");
		EndIf;
		
		RowResources.SchedulePresentation = SchedulePresentation;
		
		If RowResources.CompleteKind = PredefinedValue("Enum.ScheduleRepeatCompletingKind.ПоСчетчику")
			And ValueIsFilled(RowResources.CompleteAfter) Then 
			
			FormatString = "L = ru_RU";
			
			DetailsCounter = ResourcePlanningCMClient.CountingItem(
			RowResources.CompleteAfter,
			NStr("en='time';ru='раза';vi='lần'"),
			NStr("ru = 'раз';
				|en = 'time;"),
			NStr("en='time';ru='раз';vi='lần'"),
			"M");
			
			RowResources.DetailsCounter = DetailsCounter;
		Else
			RowResources.DetailsCounter = "";
		EndIf;
		
	EndDo;
	
	ResourcePlanningCMClient.FillDurationInSelectedResourcesTable(Object.EnterpriseResources);
	
EndProcedure

&AtServer
Function MapResourcesData()
	
	CollapsedResourceTable = Object.EnterpriseResources.Unload(,"EnterpriseResource");
	CollapsedResourceTable.GroupBy("EnterpriseResource");
	
	ConformityOfReturn = New Map();
	
	DataTable = New ValueTable;
	
	DataTable.Columns.Add("EnterpriseResource");
	DataTable.Columns.Add("ControlStep");
	DataTable.Columns.Add("MultiplicityPlanning");
	
	For Each TableRow In CollapsedResourceTable Do
		
		EnterpriseResource = TableRow.EnterpriseResource;
		
		DataStructure = New Structure("ControlStep,MultiplicityPlanning"
											,EnterpriseResource.ControlIntervalsStepInDocuments, EnterpriseResource.MultiplicityPlanning);
		
		ConformityOfReturn.Insert(EnterpriseResource, DataStructure);
		
	EndDo;
	
	Return ConformityOfReturn;
	
EndFunction


&AtClient
Procedure SetupRepeatAvailable(FormOpening = False, WasPickup = False)
	
	If FormOpening Or WasPickup Then
		
		For Each RowCompanyResources In Object.EnterpriseResources Do
			
			RowCompanyResources.SchedulePresentation = ?(RowCompanyResources.SchedulePresentation = "", Nstr("en='Not repeat';ru='Не повторять';vi='Không lặp lại'"), RowCompanyResources.SchedulePresentation);
			
			If ValueIsFilled(RowCompanyResources.Start) And ValueIsFilled(RowCompanyResources.Finish) Then
				
				RowCompanyResources.PeriodDifferent = ?(Not BegOfDay(RowCompanyResources.Start) = BegOfDay(RowCompanyResources.Finish), True, False);
				
				If BegOfDay(RowCompanyResources.Start) = BegOfDay(RowCompanyResources.Finish) Then
					RowCompanyResources.RepeatsAvailable = True;
				EndIf;
				
			EndIf;
		EndDo;
		
		Return;
	EndIf;
	
	CurrentData = Items.EnterpriseResources.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	CurrentData.RepeatsAvailable = False;
	CurrentData.PeriodDifferent = False;
	
	If ValueIsFilled(CurrentData.Start) And ValueIsFilled(CurrentData.Finish) Then
		
		CurrentData.PeriodDifferent = ?(Not BegOfDay(CurrentData.Start) = BegOfDay(CurrentData.Finish), True, False);
		
		If BegOfDay(CurrentData.Start) = BegOfDay(CurrentData.Finish) Then
			CurrentData.RepeatsAvailable = True;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnChangePeriod(ItBeginDate = False)
	
	CurrentData = Items.EnterpriseResources.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	BalanceSecondToEndDay = EndOfDay(CurrentData.Finish) - CurrentData.Finish;
	
	If BalanceSecondToEndDay = 59 Then CurrentData.Finish = EndOfDay(CurrentData.Finish) EndIf;
	If CurrentData.Finish = BegOfDay(CurrentData.Finish) Then CurrentData.Finish = CurrentData.Finish-1 EndIf; 
	
	CurrentData.Start = ?(Minute(CurrentData.Start)%5 = 0, CurrentData.Start, CurrentData.Start - (Minute(CurrentData.Start)%5*60));
	
	RemainderOfDivision = Minute(CurrentData.Finish)%5;
	
	If Not (RemainderOfDivision = 0 Or CurrentData.Finish = EndOfDay(CurrentData.Finish)) Then
		
		If RemainderOfDivision < 3 Then
			CurrentData.Finish = CurrentData.Finish - (RemainderOfDivision*60);
		ElsIf (EndOfDay(CurrentData.Finish) - CurrentData.Finish)<300 Then
			CurrentData.Finish = EndOfDay(CurrentData.Finish);
		Else
			CurrentData.Finish = CurrentData.Finish + (300 - (RemainderOfDivision*60));
		EndIf;
		
	EndIf;
	
	If CurrentData.Start > CurrentData.Finish Then 
		If ItBeginDate Then 
			CurrentData.Finish = CurrentData.Start+CurrentData.MultiplicityPlanning*60;
		Else
			CurrentData.Finish = CurrentData.Start;
		EndIf;
		
	EndIf;
	
	CurrentData.Start = ?(Second(CurrentData.Start) = 0, CurrentData.Start, CurrentData.Start - Second(CurrentData.Start));
	
	If Not (Second(CurrentData.Finish) = 0 Or CurrentData.Finish = EndOfDay(CurrentData.Finish)) Then  
		CurrentData.Finish = CurrentData.Finish - Second(CurrentData.Finish)
	EndIf;
	
	ResourcePlanningCMClient.CheckPlanningStep(CurrentData,ItBeginDate,True);
	
	SetupRepeatAvailable();
	
	If CurrentData.RepeatsAvailable Then
		
		If ValueIsFilled(CurrentData.RepeatabilityDate) Then
			CurrentData.RepeatabilityDate = Day(CurrentData.Start);
		EndIf;
		
		If CurrentData.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.Monthly") Then
			
			If ValueIsFilled(CurrentData.WeekDayMonth) Then
				
				If EndOfDay(CurrentData.Start) = EndOfMonth(CurrentData.Start) Then
					
					CurrentData.WeekDayMonth = 0;
					CurrentData.WeekMonthNumber = 0;
					CurrentData.LastMonthDay = True
					
				Else
					
					CurrentData.WeekDayMonth = WeekDay(CurrentData.Start);
					
					CurWeekNumber = WeekOfYear(CurrentData.Start)-WeekOfYear(BegOfMonth(CurrentData.Start))+1;
					
					If ValueIsFilled(CurrentData.WeekMonthNumber) And Not CurrentData.WeekMonthNumber = CurWeekNumber  Then
						CurrentData.WeekMonthNumber = CurWeekNumber;
					EndIf;
					
				EndIf;
				
			EndIf;
			
			If CurrentData.LastMonthDay And Not EndOfDay(CurrentData.Start) = EndOfMonth(CurrentData.Start) Then
				
				CurrentData.LastMonthDay = False;
				CurrentData.WeekDayMonth = WeekDay(CurrentData.Start);
			EndIf;
			
		EndIf;
		
		If CurrentData.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.Annually")
										And ValueIsFilled(CurrentData.MonthNumber) Then
			
			CurrentData.MonthNumber = Month(CurrentData.Start);
			
		EndIf;
		
	Else
		
		CurrentData.WeekMonthNumber = 0;
		CurrentData.MonthNumber = 0;
		CurrentData.RepeatabilityDate = 0;
		CurrentData.WeekDayMonth = 0;
		CurrentData.LastMonthDay = False;
		
		CurrentData.CompleteKind = Undefined;
		CurrentData.CompleteAfter = Undefined;
		
		CurrentData.RepeatInterval = 0;
		CurrentData.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.NoRepeat");
		CurrentData.DetailsCounter = "";
		
		CurrentData.Mon = False;
		CurrentData.Tu = False;
		CurrentData.We = False;
		CurrentData.Th = False;
		CurrentData.Fr = False;
		CurrentData.Sa = False;
		CurrentData.Su = False;
		
	EndIf;
	
	CurrentData.Duration = Date(1,1,1)+(CurrentData.Finish - CurrentData.Start);
	
	FillDataResourceTableOnForm();
	
	If ItBeginDate Then
		If TypeOf(CurrentData.CompleteAfter) = Type("Date")
			And ValueIsFilled(CurrentData.CompleteAfter)
			And ValueIsFilled(CurrentData.Start)
			And CurrentData.CompleteAfter<BegOfDay(CurrentData.Start)
			Then
			CurrentData.CompleteAfter=BegOfDay(CurrentData.Start)
		EndIf;
	EndIf
	
EndProcedure

&AtServer
Procedure FillResourcesFromPlanner(SelectedResources)
	
	For Each ResourcesRow In SelectedResources Do
		
		
		NewRow = Object.EnterpriseResources.Add();
		
		FillPropertyValues(NewRow, ResourcesRow);
		
		NewRow.EnterpriseResource = ResourcesRow.Resource;
		NewRow.Start = ResourcesRow.BeginOfPeriod;
		NewRow.Finish = ResourcesRow.EndOfPeriod;
		NewRow.Capacity = ResourcesRow.Loading;
		NewRow.Duration = Date(1,1,1)+(NewRow.Finish - NewRow.Start); 
		
	EndDo;
	
EndProcedure

&AtClient
Procedure EnterpriseResourcesStartTimeOnChange(Item)
	
	OnChangePeriod(True);
	
EndProcedure

&AtClient
Procedure SpecifiedEndOfPeriod()
	
	CurrentData = Items.EnterpriseResources.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	SecondsOnTime = CurrentData.Time - Date(1,1,1);
	SeconrdOnDays = ?(ValueIsFilled(CurrentData.Days), CurrentData.Days*1440*60, 0);
	
	CurrentData.Finish = CurrentData.Start + SeconrdOnDays + SecondsOnTime;
	CurrentData.Finish = ?(Not SeconrdOnDays = 0 And CurrentData.Finish = BegOfDay(CurrentData.Finish)
										, CurrentData.Finish - 1, CurrentData.Finish);
	
	ResourcePlanningCMClient.CheckPlanningStep(CurrentData);
	
EndProcedure

&AtClient
Procedure EnterpriseResourcesTimeOnChange(Item)
	
	SpecifiedEndOfPeriod();
	SetupRepeatAvailable();

EndProcedure

&AtClient
Procedure EnterpriseResourcesFinishTimeOnChange(Item)
	
	OnChangePeriod();
	
EndProcedure

&AtClient
Procedure EnterpriseResourcesScheduleDescriptionAutoComplete(Item, Text, ChoiceData, DataGetParameters, Wait, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.EnterpriseResources.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	StringDate = Day(CurrentData.Start);
	
	NotificationParameters = New Structure;
	
	Notification = New NotifyDescription("AfterEndScheduleEdit", ThisObject, NotificationParameters);
	
	StructureRepeat = New Structure("RepeatInterval, Mon, Tu, We, Th, Fr, Sa, Su, LastMonthDay, RepeatabilityDate, WeekDayMonth, StringDate, CurWeekday, WeekMonthNumber, PeriodRows, MonthNumber"
										,CurrentData.RepeatInterval, CurrentData.Mon, CurrentData.Tu, CurrentData.We
										,CurrentData.Th,CurrentData.Fr, CurrentData.Sa, CurrentData.Su, CurrentData.LastMonthDay
										,CurrentData.RepeatabilityDate, CurrentData.WeekDayMonth, StringDate, WeekDay(CurrentData.Start), CurrentData.WeekMonthNumber, CurrentData.Start, CurrentData.MonthNumber);
	
	OpenParameters = New Structure("Repeatability, StructureRepeat", CurrentData.RepeatKind, StructureRepeat);
	
	OpenForm("DataProcessor.ResourcePlanner.Form.FormScheduleEdit",OpenParameters, ThisForm,,,,Notification, FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure AfterEndScheduleEdit(ExecutionResult, Parameters) Export
	
	If ExecutionResult = Undefined Then Return EndIf;
	
	CurrentData = Items.EnterpriseResources.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	RepeatKind = ExecutionResult.RepeatKind;
	
	CurrentData.RepeatKind = RepeatKind;
	
	If RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.NoRepeat") Then
		 ResourcePlanningCMClient.CleanRowData(CurrentData, False);
		 FillDataResourceTableOnForm();
		 Return;
	 EndIf;
	
	CurrentData.RepeatInterval = ExecutionResult.RepeatInterval;
	CurrentData.Mon = ExecutionResult.Mon;
	CurrentData.Tu = ExecutionResult.Tu;
	CurrentData.We = ExecutionResult.We;
	CurrentData.Th = ExecutionResult.Th;
	CurrentData.Fr = ExecutionResult.Fr;
	CurrentData.Sa = ExecutionResult.Sa;
	CurrentData.Su = ExecutionResult.Su;
	CurrentData.LastMonthDay = ExecutionResult.LastMonthDay;
	CurrentData.RepeatabilityDate = ExecutionResult.RepeatabilityDate;
	CurrentData.WeekDayMonth = ExecutionResult.WeekDayMonth;
	CurrentData.WeekMonthNumber = ExecutionResult.WeekMonthNumber;
	CurrentData.MonthNumber = ExecutionResult.MonthNumber;
	
	FillDataResourceTableOnForm();
	
EndProcedure

&AtClient
Procedure EnterpriseResourcesCompleteKindOnChange(Item)
	
	CurrentData = Items.EnterpriseResources.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	If CurrentData.CompleteKind = PredefinedValue("Enum.ScheduleRepeatCompletingKind.ПоДате") Then
		CurrentData.CompleteAfter = BegOfDay(CurrentData.Finish+86400);
		CurrentData.DetailsCounter = "";
	ElsIf CurrentData.CompleteKind = PredefinedValue("Enum.ScheduleRepeatCompletingKind.ПоСчетчику") Then
		CurrentData.CompleteAfter = 1;
		CurrentData.DetailsCounter = "Time";
	Else
		CurrentData.DetailsCounter = "";
		CurrentData.CompleteAfter = Undefined;
	EndIf;

EndProcedure

&AtClient
Procedure EnterpriseResourcesCompleteAfterOnChange(Item)
	
	CurrentData = Items.EnterpriseResources.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	If CurrentData.CompleteKind = PredefinedValue("Enum.ScheduleRepeatCompletingKind.ПоСчетчику")
										And ValueIsFilled(CurrentData.CompleteAfter) Then 
		
		FormatString = "L = ru_RU";
		
		DetailsCounter = ResourcePlanningCMClient.CountingItem(
		CurrentData.CompleteAfter,
		NStr("en='time';ru='раза';vi='lần'"),
		NStr("en='time';ru='раз';vi='lần'"),
		NStr("ru = 'раз';
			|en = 'time;"),
		"M");
		
		CurrentData.DetailsCounter = DetailsCounter;
	Else
		CurrentData.DetailsCounter = "";
	EndIf;
	
	If TypeOf(CurrentData.CompleteAfter) = Type("Date")
		And ValueIsFilled(CurrentData.CompleteAfter)
		And ValueIsFilled(CurrentData.Start)
		And CurrentData.CompleteAfter<BegOfDay(CurrentData.Start)
		Then
		CurrentData.CompleteAfter=BegOfDay(CurrentData.Start)
	EndIf;

EndProcedure

&AtClient
Procedure PickupResources(Command)
	
	OpenParameters = New Structure("ThisSelection, EnterpriseResources, PlanningBoarders, SubsystemNumber", True, Object.EnterpriseResources,,2);
	
	Notification = New NotifyDescription("AfterPickupFormPlannerEnd", ThisObject, OpenParameters);
	
	OpenForm("DataProcessor.ResourcePlanner.Form.PlannerForm", OpenParameters,,,,,Notification);

EndProcedure

&AtClient
Procedure AfterPickupFormPlannerEnd(Result, AdditionalParameters) Export
	
	If Not Result = Undefined Then
		
		Object.EnterpriseResources.Clear();
		
		SelectedResources = Result;
		
		For Each ResourcesRow In SelectedResources Do
			
			NewRow = Object.EnterpriseResources.Add();
			
			FillPropertyValues(NewRow, ResourcesRow);
			
			NewRow.EnterpriseResource = ResourcesRow.Resource;
			NewRow.Start = ResourcesRow.BeginOfPeriod;
			NewRow.Finish = ResourcesRow.EndOfPeriod;
			NewRow.Capacity = ResourcesRow.Loading;
			NewRow.Duration = Date(1,1,1)+(NewRow.Finish - NewRow.Start); 
			
		EndDo;
		
		FillDataResourceTableOnForm();
		
		SetupRepeatAvailable(, True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ControlExcess(Command)
	
	ControlAtServer();
	
EndProcedure

&AtServer
Procedure ControlAtServer()
	ResourcePlanningCM.ControlParametersResourcesLoading(True,, Object.EnterpriseResources, ThisObject);
EndProcedure

&AtClient
Procedure BoarderControl(Command)
	
	BoarderControlAtServer();
	
EndProcedure

&AtServer
Procedure BoarderControlAtServer()
	ResourcePlanningCM.ControlParametersResourcesLoading(,True, Object.EnterpriseResources, ThisObject);
EndProcedure

&AtClient
Procedure ControlAll(Command)
	ControlAllAtServer();
EndProcedure

&AtServer
Procedure ControlAllAtServer()
	ResourcePlanningCM.ControlParametersResourcesLoading(True, True, Object.EnterpriseResources, ThisObject);
EndProcedure

&AtServer
Procedure SetFormConditionalAppearance()
	
	//Ресурсы
	ResourcePlanningCM.SetupConditionalAppearanceResources("EnterpriseResources", ThisObject, True);

	
EndProcedure

&AtClient
Procedure InventoryBatchStartChoice(Item, ChoiceData, StandardProcessing)
	
	NewParameter = New ChoiceParameter("filter.ExportDocument",True);
	NewArray = New Array();
	NewArray.Add(NewParameter);
	NewParameters = New FixedArray(NewArray);
	Items.InventoryBatch.ChoiceParameters = NewParameters;

EndProcedure
