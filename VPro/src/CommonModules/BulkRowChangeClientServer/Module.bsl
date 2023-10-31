#Region ProgramInterface

// Устанавливает ограничение типа выбираемому значению в зависимости от выбранного действия
//
// Parameters:
//  SetElements   - Structure - набор необходимых реквизитов и элементов формы, входящих в панель редактирования.
//    * КнопкаВыполнитьДействие - КнопкаФормы - Кнопка формы, запускающая обработку ТЧ.
//    * Действие - ПеречислениеСсылка.ДействияГрупповогоИзмененияСтрок - Выбранное действие для группового изменения строк.
//    * ЗначениеЭлемент - ПолеФормы - Поле ввода значения для группового изменения строк.
//
Procedure SetActionPresentation(SetElements, SetChoiceParameterLinks) Export
	
	If Not ValueIsFilled(SetElements.Action) Then
		
		TypeArray = New Array;
		TypeArray.Add(Type("String"));
		SetElements.ValueItem.TypeRestriction = New TypeDescription(TypeArray);
		SetElements.ValueItem.Visible = True;
		SetElements.ValueItem.Title = "Value";
		Return;
		
	EndIf;
	
	ChoiceParameters = ?(SetElements.ColumnChangingObject = Undefined, Undefined, SetElements.ColumnChangingObject.ChoiceParameters);
	ChoiceParameterLinks = ?(SetElements.ColumnChangingObject = Undefined, Undefined, SetElements.ColumnChangingObject.ChoiceParameterLinks);
	
	ValueType = ActionObjectType(SetElements.Action, SetElements.ColumnChangingObject);
	
	If ValueIsFilled(ValueType) Then
		
		SetElements.ValueItem.TypeRestriction = ValueType;
		If ChoiceParameters <> Undefined Then
			SetElements.ValueItem.ChoiceParameters = ChoiceParameters;
		EndIf;
		If SetElements.ValueItem.ChoiceParameterLinks.Count() <> 0 Then
			SetChoiceParameterLinks = True;
		ElsIf ChoiceParameterLinks <> Undefined Then
			SetChoiceParameterLinks = ChoiceParameterLinks.Count() <> 0;
		Else
			SetChoiceParameterLinks = False;
		EndIf;
		SetElements.ValueItem.Title = ActionObjectHeaderPresentation(SetElements.Action);
		SetElements.ValueItem.РежимВыбораИзСПиска = False;
		
		If SetElements.Action = PredefinedValue("Enum.BulkRowChangeActions.AddFromDocument") Then
			SetElements.ValueItem.ChoiceButton = True;
			SetElements.ValueItem.DropListButton = False;
		ElsIf SetElements.Action = PredefinedValue("Enum.BulkRowChangeActions.ChangePercentPrices") Then
			SetElements.ValueItem.ChoiceButton = True;
			SetElements.ValueItem.DropListButton = False;
		ElsIf SetElements.Action = PredefinedValue("Enum.BulkRowChangeActions.RoundPrices")
			Or SetElements.Action = PredefinedValue("Enum.BulkRowChangeActions.RoundSums") Then
			
			SetElements.ValueItem.ChoiceButton = False;
			SetElements.ValueItem.DropListButton = True;
		ElsIf SetElements.Action = PredefinedValue("Enum.BulkRowChangeActions.DistributeAmountByQuantity") Then
			SetElements.ValueItem.ChoiceButton = True;
			SetElements.ValueItem.DropListButton = False;
		ElsIf SetElements.Action = PredefinedValue("Enum.BulkRowChangeActions.DistributeAmountByAmounts") Then
			SetElements.ValueItem.ChoiceButton = True;
			SetElements.ValueItem.DropListButton = False;
		ElsIf SetElements.Action = PredefinedValue("Enum.BulkRowChangeActions.SetVATRate") Then
			SetElements.ValueItem.ChoiceButton = False;
			SetElements.ValueItem.DropListButton = True;
		ElsIf SetElements.Action = PredefinedValue("Enum.BulkRowChangeActions.SetDiscountMarkupPercent") Then
			SetElements.ValueItem.ChoiceButton = True;
			SetElements.ValueItem.DropListButton = False;
		ElsIf SetElements.Action = PredefinedValue("Enum.BulkRowChangeActions.SetPrices") Then
			SetElements.ValueItem.ChoiceButton = True;
			SetElements.ValueItem.DropListButton = False;
		ElsIf SetElements.Action = PredefinedValue("Enum.BulkRowChangeActions.SetPricesByKind") Then
			SetElements.ValueItem.ChoiceButton = True;
			SetElements.ValueItem.DropListButton = True;
		ElsIf SetElements.Action = PredefinedValue("Enum.BulkRowChangeActions.SetCustomerOrder") Then
			SetElements.ValueItem.ChoiceButton = True;
			SetElements.ValueItem.DropListButton = True;
		ElsIf SetElements.Action = PredefinedValue("Enum.BulkRowChangeActions.SetShipmentDate")
			Or SetElements.Action = PredefinedValue("Enum.BulkRowChangeActions.SetReceiptDate")
			Or SetElements.Action = PredefinedValue("Enum.BulkRowChangeActions.SetImplementationDate")
			Or SetElements.Action = PredefinedValue("Enum.BulkRowChangeActions.SetPlanningDate") Then
			
			SetElements.ValueItem.ChoiceButton = True;
			SetElements.ValueItem.DropListButton = False;
		ElsIf SetElements.Action = PredefinedValue("Enum.BulkRowChangeActions.SetCustomer")
			Or SetElements.Action = PredefinedValue("Enum.BulkRowChangeActions.InstallSupplier")
			Or SetElements.Action = PredefinedValue("Enum.BulkRowChangeActions.InstallManufacturer") Then
			SetElements.ValueItem.ChoiceButton = True;
			SetElements.ValueItem.DropListButton = True;
		ElsIf SetElements.Action = PredefinedValue("Enum.BulkRowChangeActions.SetPurchaseOrderCustomerOrder") Then
			SetElements.ValueItem.ChoiceButton = True;
			SetElements.ValueItem.DropListButton = True;
		ElsIf SetElements.Action = PredefinedValue("Enum.BulkRowChangeActions.SetWarehouse") Then
			SetElements.ValueItem.ChoiceButton = True;
			SetElements.ValueItem.DropListButton = True;
		ElsIf SetElements.Action = PredefinedValue("Enum.BulkRowChangeActions.SetCell") Then
			SetElements.ValueItem.ChoiceButton = True;
			SetElements.ValueItem.DropListButton = True;
		ElsIf SetElements.Action = PredefinedValue("Enum.BulkRowChangeActions.SetSourceLocation") Then
			SetElements.ValueItem.ChoiceButton = True;
			SetElements.ValueItem.DropListButton = True;
		ElsIf SetElements.Action = PredefinedValue("Enum.BulkRowChangeActions.SetNewLocation") Then
			SetElements.ValueItem.ChoiceButton = True;
			SetElements.ValueItem.DropListButton = True;
		ElsIf SetElements.Action = PredefinedValue("Enum.BulkRowChangeActions.CreateProductsAndServicesBatches") Then
			SetElements.ValueItem.ClearButton = True;
			SetElements.ValueItem.ChoiceButton = False;
			SetElements.ValueItem.DropListButton = False;
			SetElements.ValueItem.Title = "Description batches";
			SetElements.Value = "Batch created automatically";
		ElsIf SetElements.Action = PredefinedValue("Enum.BulkRowChangeActions.SetStage") Then
			SetElements.ValueItem.ChoiceButton = False;
			SetElements.ValueItem.DropListButton = True;
			SetElements.ValueItem.РежимВыбораИзСПиска = True;
		EndIf;
		
	Else
		
		SetElements.ValueItem.Visible = False;
		SetElements.ButtonExecuteAction.Visible = True;
		
	EndIf;
	
	SetElements.ValueItem.OpenButton = False;
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

// Определяет тип объекта действия.
//
Function ActionObjectType(Action, ChangingObject)
	
	TypeArray = New Array;
	NumberQualifiers = Undefined;
	TypeDescription = Undefined;
	
	If Action = PredefinedValue("Enum.BulkRowChangeActions.AddFromDocument") Then
		
		TypeArray.Add(Type("DocumentRef.AcceptanceCertificate"));
		TypeArray.Add(Type("DocumentRef.ProductionOrder"));
		TypeArray.Add(Type("DocumentRef.CustomerOrder"));
		TypeArray.Add(Type("DocumentRef.PurchaseOrder"));
		TypeArray.Add(Type("DocumentRef.InventoryReconciliation"));
		TypeArray.Add(Type("DocumentRef.InventoryReceipt"));
		TypeArray.Add(Type("DocumentRef.InventoryTransfer"));
		TypeArray.Add(Type("DocumentRef.SupplierInvoice"));
		TypeArray.Add(Type("DocumentRef.CustomerInvoice"));
		TypeArray.Add(Type("DocumentRef.InventoryAssembly"));
		TypeArray.Add(Type("DocumentRef.InventoryWriteOff"));
		TypeArray.Add(Type("DocumentRef.InvoiceForPayment"));
		TypeArray.Add(Type("DocumentRef.SupplierInvoiceForPayment"));
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.AddImportedProductsFromDocument") Then
		
		TypeArray.Add(Type("DocumentRef.CustomerOrder"));
		TypeArray.Add(Type("DocumentRef.SupplierInvoice"));
		TypeArray.Add(Type("DocumentRef.InvoiceForPayment"));
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.ChangePercentPrices") Then
		
		TypeArray.Add(Type("Number"));
		NumberQualifiers = New NumberQualifiers(10, 2, AllowedSign.Any);
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.RoundPrices")
		Or Action = PredefinedValue("Enum.BulkRowChangeActions.RoundSums") Then
		
		TypeArray.Add(Type("EnumRef.RoundingMethods"));
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.DistributeAmountByQuantity") Then
		
		TypeArray.Add(Type("Number"));
		NumberQualifiers = New NumberQualifiers(15, 2, AllowedSign.Nonnegative);
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.DistributeAmountByAmounts") Then
		
		TypeArray.Add(Type("Number"));
		NumberQualifiers = New NumberQualifiers(15, 2, AllowedSign.Nonnegative);
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.SetVATRate") Then
		
		TypeArray.Add(Type("CatalogRef.VATRates"));
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.SetDiscountMarkupPercent") Then
		
		TypeArray.Add(Type("Number"));
		NumberQualifiers = New NumberQualifiers(10, 2, AllowedSign.Nonnegative);
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.SetPrices") Then
		
		TypeArray.Add(Type("Number"));
		NumberQualifiers = New NumberQualifiers(10, 2, AllowedSign.Nonnegative);
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.SetPricesByKind") Then
		
		TypeArray.Add(Type("CatalogRef.PriceKinds"));
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.DeleteRows") Then
		
		TypeArray.Clear();
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.SetCustomerOrder") Then
		
		TypeArray.Add(Type("DocumentRef.CustomerOrder"));
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.SetShipmentDate")
		Or Action = PredefinedValue("Enum.BulkRowChangeActions.SetReceiptDate")
		Or Action = PredefinedValue("Enum.BulkRowChangeActions.SetImplementationDate")
		Or Action = PredefinedValue("Enum.BulkRowChangeActions.SetPlanningDate") Then
		
		TypeArray.Add(Type("Date"));
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.SetCustomer")
		Or Action = PredefinedValue("Enum.BulkRowChangeActions.InstallSupplier") Then
		
		TypeArray.Add(Type("CatalogRef.Counterparties"));
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.InstallManufacturer") Then
		
		TypeArray.Add(Type("CatalogRef.StructuralUnits"));
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.SetPurchaseOrderCustomerOrder") Then
		
		TypeDescription = ChangingObject.TypeRestriction;
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.SetWarehouse") Then
		
		TypeArray.Add(Type("CatalogRef.StructuralUnits"));
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.SetCell") Then
		
		TypeArray.Add(Type("CatalogRef.Cells"));
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.SetSourceLocation") Then
		
		TypeArray.Add(Type("CatalogRef.StructuralUnits"));
		TypeArray.Add(Type("DocumentRef.ProductionOrder"));
		TypeArray.Add(Type("DocumentRef.CustomerOrder"));
		TypeArray.Add(Type("DocumentRef.PurchaseOrder"));
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.SetNewLocation") Then
		
		TypeArray.Add(Type("CatalogRef.StructuralUnits"));
		TypeArray.Add(Type("DocumentRef.ProductionOrder"));
		TypeArray.Add(Type("DocumentRef.CustomerOrder"));
		TypeArray.Add(Type("DocumentRef.PurchaseOrder"));
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.CreateProductsAndServicesBatches") Then
		
		TypeArray.Add(Type("String"));
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.SetStage") Then
		
		TypeArray.Add(Type("CatalogRef.ProductionStages"));
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.ImportDeliveryState") Then
		
		TypeArray.Add(Type("EnumRef.OrderDeliveryStates"));
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.SavePaymentState") Then
		
		TypeArray.Add(Type("EnumRef.OrderPaymentStates"));
		
	EndIf;
	
	If TypeDescription = Undefined Then
		ObjectType = New TypeDescription(TypeArray,,, NumberQualifiers);
	Else
		ObjectType = TypeDescription;
	EndIf;
	
	Return ObjectType;
	
EndFunction

// Определяет название объекта действия.
//
Function ActionObjectHeaderPresentation(ActionEnum)
	
	ActionPresentation = String(ActionEnum);
	Return Right(ActionPresentation, StrLen(ActionPresentation) - StrFind(ActionPresentation, "@"));
	
EndFunction

#EndRegion