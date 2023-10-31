////////////////////////////////////////////////////////////////////////////////
// Процедуры и функции, предназначенные для группового изменения строк в табличной
//  части и управления оформлением панели редактирования.
////////////////////////////////////////////////////////////////////////////////

#Region ProgramInterface

// Вызывается при создании формы на сервере; заполняет список выбора поля ввода Действие панели редактирования таблицы.
//
// Parameters:
//  SetElements - Structure - набор необходимых реквизитов и элементов формы, входящих в панель редактирования.
//    * ДокументСсылка  - ДокументСсылка - Ссылка на документ, в котором происходит редактирование ТЧ.
//    * ИмяТЧ  - Строка - Имя ТЧ, которая будет редактироваться.
//    * ДействиеЭлемент - ПолеФормы - Элемент формы, содержащий выбранное действие для группового изменения строк.
//  Action       - EnumRef - Выбранное действие для группового изменения строк.
//
Procedure OnCreateAtServer(SetElements, Action) Export
	
	SetElements.EditPanel.Visible = False;
	SetElements.ColumnMark.Visible = False;
	SetElements.ColumnMark.FixingInTable = FixingInTable.None;
	If SetElements.Property("ColumnLineNumber") Then
		SetElements.ColumnLineNumber.Visible = True;
	EndIf; 
	
	ObjectKey = TypeOf(SetElements.DocumentRef);
	SettingsKey = "GroupRowsChange_" + SetElements.TSName;
	Action = CommonSettingsStorage.Load(ObjectKey, SettingsKey);
	
EndProcedure

// Управляет видимостью командной панели
Procedure ShowHideEditPanel(Form, SetElements, MigrationState, ModifiesData = Undefined) Export
	
	PanelVisibility = Not SetElements.EditPanel.Visible;
	SetElements.EditPanel.Visible = PanelVisibility;
	SetElements.ChangeRowsButton.Check = PanelVisibility;
	
	MigrationState = ?(PanelVisibility, 1, 0);
	CustomizeEditPanelAppearance(Form, SetElements, MigrationState, Undefined, ModifiesData);
	
	//BulkRowChangeClientServer.SetActionPresentation(SetElements, False);
	
EndProcedure

// Записывает в пользовательские настройки последнее выбранное действие для изменения таблицы.
// called when closing the form.
//
// Parameters:
//  SetElements - Structure - набор необходимых реквизитов и элементов формы, входящих в панель редактирования.
//    * ДокументСсылка  - ДокументСсылка - Ссылка на документ, в котором происходит редактирование ТЧ.
//    * ИмяТЧ - Строка - Имя ТЧ, которая будет редактироваться.
//    * ДействиеЭлемент - ПолеФормы - Элемент формы, содержащий выбранное действие для группового изменения строк.
//  Действие       - ПеречислениеСсылка - Выбранное действие для группового изменения строк.
//
Procedure SaveSettings(SetElements) Export
	
	ObjectKey = TypeOf(SetElements.DocumentRef);
	SettingsKey = "GroupRowsChange_" + SetElements.TSName;
	CommonSettingsStorage.Save(ObjectKey, SettingsKey, SetElements.Action);
	
EndProcedure

// Получает строковое представление действия.
//
// Parameters:
//  ActionEnum - EnumRef.BulkRowChangeActions - Действие, описание которого необходимо получить.
// Returns:
//  String - Представление действия.
Function ActionPresentation(ActionEnum) Export
	
	ActionPresentation = String(ActionEnum);
	Return Left(ActionPresentation, StrFind(ActionPresentation, "@") - 1);
	
EndFunction

Procedure SetSourceEditPanel(Value, SetElements) Export
	
	Value = "";
	SetElements.ValueItem.Title = "Value";
	TypeString = New Array;
	TypeString.Add(Type("String"));
	SetElements.ValueItem.TypeRestriction = New TypeDescription(TypeString);
	
EndProcedure

// Управляет оформлением панели редактирования таблицы.
//
// Parameters:
//  ThisForm         - ClientApplicationForm - Форма, в которой происходит групповое изменение строк ТЧ.
//  SetElements   - Structure - набор необходимых реквизитов и элементов формы, входящих в панель редактирования.
//    * ПанельРедактирования - ГруппаФормы - Группа формы, непосредственно являющаяся панелью редактирования ТЧ.
//    * ГруппаДействие - ГруппаФормы - Группа формы, содержащая поле выбора действия для группового изменения строк.
//    * ГруппаЗначение - ГруппаФормы - Группа формы, содержащая поле ввода значения для группового изменения строк.
//    * ГруппаВыполнить - ГруппаФормы - Группа формы, содержащая кнопку формы, запускающую обработку ТЧ.
//    * КнопкаВыполнитьДействие - КнопкаФормы - Кнопка формы, запускающая обработку ТЧ.
//    * КолонкаПометка - ПолеФормы - Пометка строки.
//    * КолонкаНомерСтроки - ПолеФормы - Номер строки.
//    * Действие - ПеречислениеСсылка.ДействияГрупповогоИзмененияСтрок - Выбранное действие для группового изменения строк.
//    * ЗначениеЭлемент - ПолеФормы - Поле ввода значения для группового изменения строк.
//    * ОбъектИзменений - Строка - Название элемента формы, входящего в состав ТЧ, над которым будут производиться изменения.
//    * КолонкаОбъектИзменений - ПолеФормы - Элемент формы, входящего в состав ТЧ, над которым будут производиться изменения.
//  State        - Number - Состояние формы, к которому происходит переход.
//    * 0 - Панель скрыта.
//    * 1 - Выбор действия.
//    * 2 - Выбор значения.
//    * 3 - Применение изменений.
//    * 4 - Представление изменений.
//  Value         - ПроизвольноеЗначение - Значение, которое используется для изменения значений колонки ТЧ при групповом изменении строк.
//  ChangesValue - Boolean - Определяет, нужно ли загрузить исходное состояние редактируемой ТЧ
//                              при скрытии панели редактирования.
//
Procedure CustomizeEditPanelAppearance(ThisForm, SetElements, State, Value, ChangesValue = Undefined) Export
	
	If State = 2 And SetElements.Action = Enums.BulkRowChangeActions.DeleteRows Then
		State = 3;
	EndIf;
	
	If State = 0 Then
		
		// 0. Панель скрыта
		If ValueIsFilled(ChangesValue) And ChangesValue Then
			ThisForm.Modified = True;
		EndIf;
		
		SetElements.EditPanel.Visible = False;
		SetElements.ColumnMark.Visible = False;
		SetElements.ColumnMark.FixingInTable = FixingInTable.None;
		If SetElements.Property("ColumnLineNumber") Then
			SetElements.ColumnLineNumber.Visible = True;
			SetElements.ColumnLineNumber.FixingInTable = FixingInTable.Left;
		EndIf; 
		
	ElsIf State = 1 Then
		// 1. Выбор действия
		
		SetElements.ColumnMark.Visible = True;
		SetElements.ColumnMark.FixingInTable = FixingInTable.Left;
		If SetElements.Property("ColumnLineNumber") Then
			SetElements.ColumnLineNumber.Visible = False;
			SetElements.ColumnLineNumber.FixingInTable = FixingInTable.None;
		EndIf; 
		SetElements.EditPanel.Visible = True;
		
		Value = SetElements.ValueItem.TypeRestriction.AdjustValue("");
		
	ElsIf State = 2 Then
		// 2. Выбор значения
		
		If SetElements.Action <> Enums.BulkRowChangeActions.DeleteRows Then
			SetElements.ValueItem.Visible = True;
		EndIf;
		
		Value = SetElements.ValueItem.TypeRestriction.AdjustValue("");
		
		If SetElements.ValueItem.Visible Then
			ThisForm.CurrentItem = SetElements.ValueItem;
		Else
			ThisForm.CurrentItem = SetElements.ButtonExecuteAction;
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure BackupManagement(Form, Table, TableBackupAddress, MigrationState, ModifiesData) Export
	
	ModifiesData = ?(ModifiesData = Undefined, False, ModifiesData);
	If MigrationState = 1 Then
		MakeTableBackup(Form, Table, TableBackupAddress);
	ElsIf MigrationState = 0 And Not ModifiesData Then
		RestoreTableFromBackup(Table, TableBackupAddress);
	EndIf;
	
	If MigrationState = 1 Then
		If Table.Count()>0 And Table[0].Property("Check") Then
			//При открытии устанавливаем пометки
			For Each Str In Table Do
				Str.Check = True;
			EndDo;
		EndIf;
	EndIf;
		
EndProcedure

// Помещает таблицу во временное хранилище.
//
// Parameters:
//  ThisForm - ClientApplicationForm - Форма, в которой происходит групповое изменение строк ТЧ.
//  Table  - FormDataCollection - ТЧ, которую требуется поместить во временное хранилище.
//  TableBackupAddress - String - Вернет адрес таблицы во временном хранилище.
//
Procedure MakeTableBackup(ThisForm, Table, TableBackupAddress) Export
	
	TableBackupAddress = PutToTempStorage(Table.Unload(), ThisForm.UUID);
	
EndProcedure

// Полностью заменяет текущую таблицу таблицей из временного хранилища.
//
// Parameters:
//  Table  - FormDataCollection - ТЧ, которую требуется заменить таблицей во временном хранилище.
//  TableBackupAddress - String - Адрес таблицы во временном хранилище.
//
Procedure RestoreTableFromBackup(Table, TableBackupAddress) Export
	
	Table.Load(GetFromTempStorage(TableBackupAddress));
	
EndProcedure

// Производит групповое изменение строк ТЧ.
//
// Parameters:
//  ThisForm       - ClientApplicationForm - Форма, в которой происходит групповое изменение строк ТЧ.
//  Table        - FormDataCollection - ТЧ, над которой производится групповое изменение строк.
//  Action       - EnumRef.BulkRowChangeActions - Выбранное действие для группового изменения строк.
//  ActionObject - String - Имя реквизита ТЧ объекта, над которым производятся изменения.
//  Value       - ПроизвольноеЗначение - Значение, которое используется для изменения значений колонки ТЧ при групповом изменении строк.
//
Procedure ProcessTable(ThisForm, Table, Action, ActionObject, Value, ItemNameProductsAndServices, FilterParameters = Undefined) Export
	
	If Action <> Enums.BulkRowChangeActions.AddFromDocument
		And Action <> Enums.BulkRowChangeActions.SetDiscountMarkupPercent
		And Action <> Enums.BulkRowChangeActions.SetDiscountAmount
		And Action <> Enums.BulkRowChangeActions.DistributeByQuantityInOrder
		And Table.FindRows(New Structure("Check", True)).Count() = 0 Then
		
		MessageText = NStr("en='Не выбрана ни одна строка.';ru='Не выбрана ни одна строка.';vi='Chưa chọn dòng nào.'");
		CommonUse.MessageToUser(MessageText);
		Return;
	EndIf;
	
	If Action = PredefinedValue("Enum.BulkRowChangeActions.ChangePercentPrices") Then
		
		For Each Row In Table Do
			
			If Not Row.Check Then
				Continue;
			EndIf;
			
			If Row.Property("Price") Then
				Row.Price = Row.Price * (100 + Value) / 100;
			EndIf;
			
		EndDo;
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.SetPrices") Then
		
		For Each Row In Table Do
			
			If Not Row.Check Then
				Continue;
			EndIf;
			
			If Row.Property("Price") Then
				Row.Price = Value;
			EndIf;
			
		EndDo;
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.SetPricesByKind") Then
		
		For Each Row In Table Do
			
			If Not Row.Check Then
				Continue;
			EndIf;
			
			StructureData = New Structure();
			
			StructureData.Insert("ProcessingDate",	ThisForm.Object.Date);
			StructureData.Insert("ProductsAndServices",	Row.ProductsAndServices);
			StructureData.Insert("CHARACTERISTIC",	Row.CHARACTERISTIC);
			StructureData.Insert("DocumentCurrency", ThisForm.Object.DocumentCurrency);
			StructureData.Insert("PriceKind", 			Value);
			If Row.Property("MeasurementUnit")
				And TypeOf(Row.MeasurementUnit) = Type("CatalogRef.UOM") Then
				StructureData.Insert("Factor", Row.MeasurementUnit.Factor);
			Else
				StructureData.Insert("Factor", 1);
			EndIf;
			
			If Row.Property("Price") Then
				Row.Price = SmallBusinessServer.GetProductsAndServicesPriceByPriceKind(StructureData);
			EndIf;
			
		EndDo;
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.RoundPrices") Then
		
		For Each Row In Table Do
			
			If Not Row.Check Then
				Continue;
			EndIf;
			
			If Row.Property("Price") Then
				Row.Price = SmallBusinessServer.RoundPrice(Row.Price, Value, False);
			EndIf;
			
		EndDo;
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.RoundSums") Then
		
		For Each Row In Table Do
			
			If Not Row.Check Then
				Continue;
			EndIf;
			
			If Row.Property("Amount") Then
				Row.Amount = SmallBusinessServer.RoundPrice(Row.Amount, Value, False);
			EndIf;
			
		EndDo;
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.SetDiscountMarkupPercent") Then
		
		For Each Row In Table Do
			
			If FilterParameters <> Undefined Then
				IsSuitableString = SmallBusinessClientServer.ObjectMatchesFilterParameters(Row, FilterParameters);
				If Not IsSuitableString Then
					Continue;
				EndIf;
			EndIf;
			
			If Row.Property("DiscountMarkupPercent") Then
				Row.DiscountMarkupPercent = Value;
			EndIf;
			If Row.Property("Check") Then
				Row.Check = True;
			EndIf;

		EndDo;
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.SetDiscountAmount") Then
		
		DistributeAmountByDiscounts(Table, "Amount", Value, FilterParameters);
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.DistributeByQuantityInOrder") Then
		
		DistributeByQuantityInOrder(Table);
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.DistributeAmountByQuantity") Then
		
		If Value <> Undefined Then
			DistributeAmountByColumn(Table, "Quantity", Value);
		EndIf;
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.DistributeAmountByAmounts") Then
		
		If Value <> Undefined Then
			DistributeAmountByColumn(Table, "Amount", Value);
		EndIf;
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.SetVATRate") Then
		
		For Each Row In Table Do
			
			If Not Row.Check Then
				Continue;
			EndIf;
			
			If Row.Property("VATRate") Then
				Row.VATRate = Value;
			EndIf;
			
		EndDo;
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.AddFromDocument") Then
		
		// Оставим пометки только у добавленных из документа.
		For Each Row In Table Do
			Row.Check = False;
		EndDo;
		
		If TypeOf(Value) = Type("DocumentRef.AcceptanceCertificate") Then
			TSNameSource = "WorksAndServices";
		ElsIf TypeOf(Value) = Type("DocumentRef.ProductionOrder") Then
			TSNameSource = "Products";
		ElsIf TypeOf(Value) = Type("DocumentRef.CustomerOrder") Then
			TSNameSource = "Inventory";
		ElsIf TypeOf(Value) = Type("DocumentRef.PurchaseOrder") Then
			TSNameSource = "Inventory";
		ElsIf TypeOf(Value) = Type("DocumentRef.InventoryReconciliation") Then
			TSNameSource = "Inventory";
		ElsIf TypeOf(Value) = Type("DocumentRef.InventoryReceipt") Then
			TSNameSource = "Inventory";
		ElsIf TypeOf(Value) = Type("DocumentRef.InventoryTransfer") Then
			TSNameSource = "Inventory";
		ElsIf TypeOf(Value) = Type("DocumentRef.SupplierInvoice") Then
			TSNameSource = "Inventory";
		ElsIf TypeOf(Value) = Type("DocumentRef.CustomerInvoice") Then
			TSNameSource = "Inventory";
		ElsIf TypeOf(Value) = Type("DocumentRef.InventoryAssembly") Then
			TSNameSource = "Products";
		ElsIf TypeOf(Value) = Type("DocumentRef.InventoryWriteOff") Then
			TSNameSource = "Inventory";
		ElsIf TypeOf(Value) = Type("DocumentRef.InvoiceForPayment") Then
			TSNameSource = "Inventory";
		ElsIf TypeOf(Value) = Type("DocumentRef.SupplierInvoiceForPayment") Then
			TSNameSource = "Inventory";
		EndIf;
		
		AllowedProductsAndServicesTypes = New Array;
		
		ItemProductsAndServices = ThisForm.Items[ItemNameProductsAndServices];
		ProductsAndServicesChoiceParameters = ItemProductsAndServices.ChoiceParameters;
		For Each ChoiceParameter In ProductsAndServicesChoiceParameters Do
			
			If ChoiceParameter.Name <> "Filter.ProductsAndServicesType" Then
				Continue;
			EndIf;
			
			If TypeOf(ChoiceParameter.Value) = Type("FixedArray")
				Or TypeOf(ChoiceParameter.Value) = Type("FixedArray") Then
				
				For Each FilterValue In ChoiceParameter.Value Do
					AllowedProductsAndServicesTypes.Add(FilterValue);
				EndDo;
			Else
				AllowedProductsAndServicesTypes.Add(ChoiceParameter.Value);
			EndIf;
			
		EndDo;
		
		NewRowValues = New Structure("ProductsAndServices,Quantity");
		
		For Each Row In Value[TSNameSource] Do
			
			If TypeOf(Row.ProductsAndServices) <> Type("CatalogRef.ProductsAndServices") Then
				Continue;
			EndIf;
			
			If AllowedProductsAndServicesTypes.Find(Row.ProductsAndServices.ProductsAndServicesType) = Undefined Then
				Continue;
			EndIf;
			
			NewRowValues.ProductsAndServices = Undefined;
			NewRowValues.Quantity = Undefined;
			
			FillPropertyValues(NewRowValues, Row);
			NewRow = Table.Add();
			NewRow.Check = True;
			FillPropertyValues(NewRow, NewRowValues);
			
		EndDo;
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.DeleteRows") Then
		
		MarkedRows = Table.FindRows(New Structure("Check", True));
		
		For Each Row In MarkedRows Do
			
			Table.Delete(Row);
			
		EndDo;
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.SetCustomerOrder")
		Or Action = PredefinedValue("Enum.BulkRowChangeActions.SetShipmentDate")
		Or Action = PredefinedValue("Enum.BulkRowChangeActions.SetReceiptDate")
		Or Action = PredefinedValue("Enum.BulkRowChangeActions.SetCustomer")
		Or Action = PredefinedValue("Enum.BulkRowChangeActions.InstallSupplier")
		Or Action = PredefinedValue("Enum.BulkRowChangeActions.InstallManufacturer")
		Or Action = PredefinedValue("Enum.BulkRowChangeActions.SetImplementationDate")
		Or Action = PredefinedValue("Enum.BulkRowChangeActions.SetPlanningDate")
		Or Action = PredefinedValue("Enum.BulkRowChangeActions.SetPurchaseOrderCustomerOrder")
		Or Action = PredefinedValue("Enum.BulkRowChangeActions.SetSourceLocation")
		Or Action = PredefinedValue("Enum.BulkRowChangeActions.SetNewLocation") Then
		
		For Each Row In Table Do
			
			If Not Row.Check Then
				Continue;
			EndIf;
			
			Row[ActionObject] = Value;
			
		EndDo;
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.SetWarehouse") Then
		
		For Each Row In Table Do
			
			If Not Row.Check Then
				Continue;
			EndIf;
			
			Row[ActionObject] = Value;
			
			If Not Row.Property("Cell") Or Not ValueIsFilled(Row.Cell) Then
				Continue;
			EndIf;
			
			If CommonUse.ObjectAttributeValue(Row.Cell, "Owner") <> Value Then
				Row.Cell = Catalogs.Cells.EmptyRef();
			EndIf;
			
		EndDo;
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.SetCell") Then
		
		For Each Row In Table Do
			
			If Not Row.Check Then
				Continue;
			EndIf;
			
			If Row.StructuralUnit <> Value.Owner Then
				Continue;
			EndIf;
			
			Row.Cell = Value;
			
		EndDo;
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.FillSerialNumbers") Then
		
		If ItemNameProductsAndServices = "ProductsProductsAndServices" Then
			WorkWithSerialNumbers.FillSerialNumbersAvailable(ThisForm.Object, "Products");
		Else
			WorkWithSerialNumbers.FillSerialNumbersAvailable(ThisForm.Object);
		EndIf; 
		
	ElsIf Action = PredefinedValue("Enum.BulkRowChangeActions.SetStage") Then
		
		For Each Row In Table Do
			
			If Not Row.Check Then
				Continue;
			EndIf;
			
			If Row.Property("stage") Then
				Row.stage = Value;
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

Procedure DistributeByQuantityInOrder(Table)
	
	For Each CurRow In Table Do
		If CurRow.VarianceWithOrder <= 0 Then
			Continue;
		EndIf;
		NewRow = Table.Insert(Table.IndexOf(CurRow) + 1);
		FillPropertyValues(NewRow, CurRow);
		NewRow.DocOrder = Undefined;
		NewRow.Count = CurRow.VarianceWithOrder;
		NewRow.ReferenceQuantity = NewRow.Count;
		NewRow.QuantityInOrder = 0;
		NewRow.VarianceWithOrder = 0;
		NewRow.VarianceWithOrderPresentation = "";
		NewRow.PriceInOrder = 0;
		NewRow.PriceInOrderPresentation = "";
		CurRow.Count = CurRow.Count - CurRow.VarianceWithOrder;
		CurRow.VarianceWithOrder = 0;
		CurRow.VarianceWithOrderPresentation = "0";
	EndDo;
	
EndProcedure

// Распределяет сумму по колонке таблицы.
Procedure DistributeAmountByColumn(Table, ColumnName, DistributionAmount)
	
	If DistributionAmount = 0 Then
		Return;
	EndIf;
	
	// Посчитаем общую помеченных позиций
	Total = 0;
	For Each TabularSectionRow In Table Do
		If Not TabularSectionRow.Check Then
			Continue;
		EndIf;
		
		Total = Total + TabularSectionRow[ColumnName];
	EndDo;
	
	If Total = 0 Then
		Return;
	EndIf;
	
	// Теперь распределяем
	MaxAmountString = Undefined; // На эту строку будем относить остаток после распределения (ошибки округления)
	MaxAmount       = 0; // Значение максимальной суммы.
	UnpaidAmount       = DistributionAmount;
	
	For Each TabularSectionRow In Table Do
		If Not TabularSectionRow.Check Then
			Continue;
		EndIf;
			
		CurrentAmount = TabularSectionRow.Amount;
		Delta       = DistributionAmount * TabularSectionRow[ColumnName] / Total;
		
		// Если Дельта по модулю оказалась больше, чем осталось погасить
		If Delta < 0 Then
			Delta = Max(UnpaidAmount, Delta)
		Else
			Delta = Min(UnpaidAmount, Delta)
		EndIf;
		
		// Проверим текущую сумму на максимум.
		If CurrentAmount > MaxAmount Then
			MaxAmount       = CurrentAmount;
			MaxAmountString = TabularSectionRow;
		EndIf;
		
		// Учеличиваем значение
		TabularSectionRow.Amount = CurrentAmount + Delta;
		
		// Остаток нераспределенной суммы надо уменьшать на дельту реального изменения
		UnpaidAmount = UnpaidAmount - (TabularSectionRow.Amount - CurrentAmount);
		
	EndDo;
	
	// Если что-то осталось, кидаем на строку с максимальной суммой.
	If UnpaidAmount > 0 And MaxAmountString <> Undefined Then
		MaxAmountString.Amount = MaxAmountString.Amount + UnpaidAmount;
	EndIf;
	
EndProcedure

// Распределяет сумму по колонке таблицы.
Procedure DistributeAmountByDiscounts(Table, ColumnName, DistributionAmount, FilterParameters = Undefined)
	
	// Посчитаем общую сумму помеченных позиций
	Total = 0;
	For Each TabularSectionRow In Table Do
		
		If FilterParameters <> Undefined Then
			If Not SmallBusinessClientServer.ObjectMatchesFilterParameters(TabularSectionRow, FilterParameters) Then
				Continue;
			EndIf;
		EndIf;
		
		If TypeOf(Table) = Type("DocumentTabularSection.ЗаказПокупателя.Inventory")
			Or TypeOf(Table) = Type("DocumentTabularSection.РасходнаяНакладная.Inventory") Then
			Total = Total + TabularSectionRow.Price * TabularSectionRow.Count;
		Else
			Total = Total + TabularSectionRow.Price * TabularSectionRow.Count 
				* ?(TabularSectionRow.Property("Multiplicity"), TabularSectionRow.Multiplicity, 1) 
				* ?(TabularSectionRow.Property("Factor"), TabularSectionRow.Factor, 1);
		EndIf;
		
	EndDo;
	
	If Total = 0 Then
		Return;
	EndIf;
	
	DiscountPercent = DistributionAmount / Total * 100;
	
	TotalDiscountAmount = 0;
	TotalAmountWithoutDiscounts = 0;
	LastRow = Undefined;
	For Each TabularSectionRow In Table Do
		
		If FilterParameters <> Undefined Then
			If Not SmallBusinessClientServer.ObjectMatchesFilterParameters(TabularSectionRow, FilterParameters) Then
				Continue;
			EndIf;
		EndIf;
		
		TabularSectionRow.DiscountMarkupPercent = DiscountPercent;
		If TypeOf(Table) = Type("DocumentTabularSection.ЗаказПокупателя.Inventory")
			Or TypeOf(Table) = Type("DocumentTabularSection.РасходнаяНакладная.Inventory") Then
			RowAmountWithoutDiscounts = TabularSectionRow.Price * TabularSectionRow.Quantity;
			AmountDiscountsMarkups = RowAmountWithoutDiscounts * DiscountPercent / 100;
			TabularSectionRow.AmountDiscountsMarkups = AmountDiscountsMarkups;
		Else
			RowAmountWithoutDiscounts = TabularSectionRow.Price * TabularSectionRow.Quantity 
				* ?(TabularSectionRow.Property("Multiplicity"), TabularSectionRow.Multiplicity, 1) 
				* ?(TabularSectionRow.Property("Factor"), TabularSectionRow.Factor, 1);
			AmountDiscountsMarkups = RowAmountWithoutDiscounts * DiscountPercent / 100;
			If TabularSectionRow.Property("AmountDiscountsMarkups") Then
				TabularSectionRow.AmountDiscountsMarkups = AmountDiscountsMarkups;
			EndIf;
			TabularSectionRow.Check = True;
		EndIf;
		TabularSectionRow.Amount = RowAmountWithoutDiscounts - AmountDiscountsMarkups;
		
		TotalDiscountAmount = TotalDiscountAmount + AmountDiscountsMarkups;
		LastRow = TabularSectionRow;
		
	EndDo;
	
	TotalDiscountMarkupsAmount = 0;
	For Each TabularSectionRow In Table Do
		If FilterParameters <> Undefined Then
			If Not SmallBusinessClientServer.ObjectMatchesFilterParameters(TabularSectionRow, FilterParameters) Then
				Continue;
			EndIf;
		EndIf;
		TotalDiscountMarkupsAmount = TotalDiscountMarkupsAmount + TabularSectionRow.AmountDiscountsMarkups;
	EndDo;
	
	UnpaidAmount = DistributionAmount - TotalDiscountMarkupsAmount;
	If LastRow <> Undefined And UnpaidAmount <> 0 Then
		If TypeOf(Table) = Type("DocumentTabularSection.ЗаказПокупателя.Inventory")
			Or TypeOf(Table) = Type("DocumentTabularSection.РасходнаяНакладная.Inventory") Then
			RowAmountWithoutDiscount = TabularSectionRow.Price * TabularSectionRow.Quantity;
			LastRow.DiscountMarkupPercent = (TabularSectionRow.Price * TabularSectionRow.Quantity 
				* TabularSectionRow.DiscountMarkupPercent/100 
				+ UnpaidAmount) / RowAmountWithoutDiscount * 100;
		Else
			RowAmountWithoutDiscount = TabularSectionRow.Price * TabularSectionRow.Quantity 
				* ?(TabularSectionRow.Property("Multiplicity"), TabularSectionRow.Multiplicity, 1) 
				* ?(TabularSectionRow.Property("Factor"), TabularSectionRow.Factor, 1);
			LastRow.DiscountMarkupPercent = (TabularSectionRow.Price * TabularSectionRow.Quantity 
				* ?(TabularSectionRow.Property("Multiplicity"), TabularSectionRow.Multiplicity, 1) 
				* ?(TabularSectionRow.Property("Factor"), TabularSectionRow.Factor, 1) 
				* TabularSectionRow.DiscountMarkupPercent/100 
				+ UnpaidAmount) / RowAmountWithoutDiscount * 100;
		EndIf;
		
		LastRow.AmountDiscountsMarkups = LastRow.AmountDiscountsMarkups + UnpaidAmount;
		TabularSectionRow.Amount = RowAmountWithoutDiscounts - LastRow.AmountDiscountsMarkups;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetChoiceParameterLinks(SetElements) Export
	
	If SetElements.ColumnChangingObject <> Undefined Then
		SetElements.ValueItem.ChoiceParameterLinks = SetElements.ColumnChangingObject.ChoiceParameterLinks;
	Else
		SetElements.ValueItem.ChoiceParameterLinks = New FixedArray(New Array);
	EndIf;
	
EndProcedure

#EndRegion
