
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Filter.Property("Owner") And TypeOf(Parameters.Filter.Owner) = Type("CatalogRef.ProductsAndServices") Then
		
		ProductsAndServices = Parameters.Filter.Owner;
		ProductsAndServicesCategory = ProductsAndServices.ProductsAndServicesCategory;
		
		TextOfMessage = "";
		If Not ValueIsFilled(ProductsAndServices) Then
			TextOfMessage = NStr("ru='Не заполнена номенклатура!';en='Products and services are not filled in.';vi='Chưa điền mặt hàng!'");
		ElsIf Parameters.Property("ThisIsReceiptDocument") And ProductsAndServices.ProductsAndServicesType = Enums.ProductsAndServicesTypes.Service Then
			TextOfMessage = NStr("ru='Для услуг сторонних контрагентов не ведется учет по характеристикам!';en='Accounting by characteristics is not kept for services of external counterparties.';vi='Đối với dịch vụ của đối tác bên ngoài, không tiến hành kế toán theo đặc tính!'");
		ElsIf Not ProductsAndServices.UseCharacteristics Then
			TextOfMessage = NStr("ru='Для номенклатуры не ведется учет по характеристикам!';en='Accounting by characteristics is not kept for the products and services.';vi='Mặt hàng không tiến hành kế toán theo đặc tính!'");
		EndIf;
		
		If Not IsBlankString(TextOfMessage) Then
			CommonUseClientServer.MessageToUser(TextOfMessage,,,,Cancel);
			Return;
		EndIf;
		
		If Parameters.Property("CurrentRow") And ValueIsFilled(Parameters.CurrentRow) Then
			Items.List.CurrentRow = Parameters.CurrentRow;
		EndIf;
		
		// Очистим переданный отбор и установим свой
		Parameters.Filter.Delete("Owner");
		SetFilterByOwnerAtServer();
		
		// УНФ StandardSubsystems.Properties
		EmptyCharacteristic = Catalogs.ProductsAndServicesCharacteristics.EmptyRef();
		PropertiesManagementOverridable.PropertiesTableOnCreateAtServer(ThisObject, EmptyCharacteristic, ProductsAndServicesCategory, False);
		
	Else
		
		If Items.Find("ListCreate") <> Undefined Then
			Items.ListCreate.Enabled = False;
		EndIf;
		Items.ListContextMenuCreate.Enabled = False;
		
	EndIf;
	
	If Not GetFunctionalOption("UseAdditionalAttributesAndInformation") Then
		Items.Characteristics.Representation = UsualGroupRepresentation.None;
		Items.Characteristics.ShowTitle = False;
	EndIf;
	
	If ValueIsFilled(ProductsAndServicesCategory)
		Then   		
		//If ProductsAndServicesCategory.SortingOrder.Count()
		//	Then
		//	List.Order.Items.Clear();		
		//	For Each RowSortingOrder In ProductsAndServicesCategory.SortingOrder Do
		//		OrderingItem = List.Order.Items.Add(Type("DataCompositionOrderItem"));
		//		OrderingItem.Use = True;
		//		OrderingItem.ViewMode = DataCompositionSettingsItemViewMode.Normal;
		//		OrderingItem.Field = New DataCompositionField("Ref." + RowSortingOrder.Property.Description);
		//		OrderingItem.OrderType = DataCompositionSortDirection.Asc;
		//	EndDo;	
		//Else
			OrderingItem = List.Order.Items.Add(Type("DataCompositionOrderItem"));
			OrderingItem.Use = True;
			OrderingItem.ViewMode = DataCompositionSettingsItemViewMode.Normal;
			OrderingItem.Field = New DataCompositionField("Description");
			OrderingItem.OrderType = DataCompositionSortDirection.Asc; 				
		//EndIf;  
	EndIf;
	
EndProcedure // ПриСозданииНаСервере()

&AtClient
Procedure OnClose(Exit)
	
	
EndProcedure

#EndRegion

#Region FormItemEventsHandlers

// Обновляем отбор списка Характеристик по значениям доп. реквизитов.
//
&AtClient
Procedure Properties_TablePropertiesAndValuesValueOnChange(Item)
	
	List.SettingsComposer.Settings.Filter.Items.Clear();
	
	SetFilterByOwnerAtClient();
	SetFilterByPropertiesAndValues();
	
EndProcedure

// При клике на Характеристику из списка выводим в подвале формы ее наименование для печати.
//
&AtClient
Procedure ListOnActivateRow(Item)
	
	If Item.CurrentData <> Undefined Then
		
		If Not CurrentCharacteristic = Items.List.CurrentData.Ref Then
			
			CurrentCharacteristic = Items.List.CurrentData.Ref;
		EndIf;
		
		Return;
	EndIf;
	
EndProcedure

// Открываем карточку создания новой Характеристики и передаем значения отборов по доп. реквизитам.
//
&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Group)
	
	If Copy = True Then
		Return;
	EndIf;
	
	Cancel = True;
	
	FillingValues = New Structure;
	FillingValues.Insert("Owner", ProductsAndServices);
	FillingValues.Insert("ValuesOfAdditionalAttributes", FilterValues());
	
	FormParameters = New Structure;
	FormParameters.Insert("FillingValues", FillingValues);
	
	OpenForm("Catalog.ProductsAndServicesCharacteristics.ObjectForm", FormParameters);
	
EndProcedure // СписокПередНачаломДобавления()

#EndRegion

#Region HandlersCommandFormEvents

&AtClient
Procedure ClearAllFilters(Command)
	
	For Each Str In Properties_TablePropertiesAndValues Do
		
		Str.Value = Undefined;
		
	EndDo;
	
	List.SettingsComposer.Settings.Filter.Items.Clear();
	SetFilterByOwnerAtClient();
	
EndProcedure

&AtClient
Procedure FindSimilarCharacteristics(Command)
	
	If Items.List.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	CurrentRow = Items.List.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	SetFilterByCharacteristicValues(CurrentRow.Ref);
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions


#EndRegion

#Region InternalProceduresAndFunctions

// Устанавливает отбор для формы выбора характеристик номенклатуры.
//
&AtServer
Procedure SetFilterByOwnerAtServer()
	
	FilterList = New ValueList;
	FilterList.Add(ProductsAndServices);
	FilterList.Add(ProductsAndServicesCategory);
	
	SmallBusinessClientServer.SetListFilterItem(List,"Owner",FilterList,True,DataCompositionComparisonType.InList);
	
EndProcedure // УстановитьОтборПоВладельцуНаСервере()

// Устанавливает отбор для формы выбора характеристик номенклатуры.
//
&AtClient
Procedure SetFilterByOwnerAtClient()
	
	FilterList = New ValueList();
	FilterList.Add(ProductsAndServices);
	FilterList.Add(ProductsAndServicesCategory);
	
	SmallBusinessClientServer.SetListFilterItem(List,"Owner",FilterList,True,DataCompositionComparisonType.InList);
	
EndProcedure // УстановитьОтборПоВладельцуНаКлиенте()

// Обходит таблицу свойств и устанавливает отбор списка по введенным значениям.
//
&AtClient
Procedure SetFilterByPropertiesAndValues()
	
	For Each Row In Properties_TablePropertiesAndValues Do
		
		If ValueIsFilled(Row.Value) Then
			
			SmallBusinessClientServer.SetListFilterItem(List,"Ref.[" + String(Row.Property) + "]", Row.Value);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Заполняет таблицу отборов значениями выбранной характеристики.
//
&AtServer
Procedure SetFilterByCharacteristicValues(Characteristic)
	
	List.SettingsComposer.Settings.Filter.Items.Clear();
	
	SetFilterByOwnerAtServer();
	
	For Each Item In Properties_TablePropertiesAndValues Do
		
		CharacteristicValue = Characteristic.AdditionalAttributes.Find(Item.Property, "Property");
		If CharacteristicValue = Undefined Then
			Item.Value = CharacteristicValue;
		Else
			Item.Value = CharacteristicValue.Value;
		EndIf;
		
		If Not ValueIsFilled(Item.Value) Then
			Continue;
		EndIf;
		
		SmallBusinessClientServer.SetListFilterItem(List, "Ref.[" + String(Item.Property) + "]", Item.Value);
		
	EndDo;
	
EndProcedure

// Подготавливает значения отборов по доп. реквизитам для создания нового объекта.
//
&AtClient
Function FilterValues()
	
	FilterValues = New Map;
	For Each Item In Properties_TablePropertiesAndValues Do
		
		FilterValues.Insert(Item.Property, Item.Value);
		
	EndDo;
	
	Return FilterValues;
	
EndFunction // ЗначенияОтбора()

#EndRegion

#Region LibrariesHandlers

// StandardSubsystems.Properties УНФ
&AtClient
Procedure Properties_TablePropertiesAndValuesBeforeAddRow(Item, Cancel, Copy, Parent, Group, Parameter)
	PropertiesManagementClientOverridableCM.PropertiesTable(Cancel);
EndProcedure

&AtClient
Procedure Properties_TablePropertiesAndValuesBeforeDeleteRow(Item, Cancel)
	
	List.SettingsComposer.Settings.Filter.Items.Clear();
	PropertiesManagementClientOverridableCM.PropertiesTableBeforeDelete(Item, Cancel, Modified);
	SetFilterByOwnerAtClient();
	SetFilterByPropertiesAndValues();
	
EndProcedure
// Конец УНФ StandardSubsystems.Properties

#EndRegion