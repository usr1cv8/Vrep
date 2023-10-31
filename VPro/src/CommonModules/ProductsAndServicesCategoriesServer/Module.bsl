
#Region ProgramInterface

// Возвращает дерево используемых категорий.
// 
// Returns:
//  ValueTree - дерево используемых категорий.
//
Function CategoryTree() Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ProductsAndServicesCategories.Ref AS Value,
	|	ProductsAndServicesCategories.Description AS Presentation
	|FROM
	|	Catalog.ProductsAndServicesCategories AS ProductsAndServicesCategories
	|
	|ORDER BY
	|	ProductsAndServicesCategories.IsFolder HIERARCHY, ProductsAndServicesCategories.AdditionalOrderingAttribute, ProductsAndServicesCategories.Description";
	
	Tree = Query.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy);
	If Tree.Rows.Count() > 1 Then
		
		RowNoCategory = Tree.Rows.Insert(0);
		RowNoCategory.Value = Catalogs.ProductsAndServices.EmptyRef();
		RowNoCategory.Presentation = NStr("en='<Все категории>';ru='<Все категории>';vi='<Tất cả thể loại>'");
		
	EndIf;
	
	Return Tree;
	
EndFunction

// Создает на форме список используемых свойств выбранной категории для выполнения отборов по списку номенклатуры.
//
// Parameters:
//  Form					 - ClientApplicationForm - Форма объекта-владельца, предназначенная для вывода списка свойств.
//  SelectedCategory		 - CatalogRef.ProductsAndServicesCategories - Выбранная категория номенклатуры, являющаяся
//                             владельцем свойств.
//  ItemNameForPlacement - String - Имя группы на форме, в которой будут размещены свойства номенклатуры.
//  CharacteristicProperties	 - Boolean - Определяет, нужно ли показывать свойства характеристик выбранной номенклатуры.
//
Procedure ShowCategoryProperties(Form, List, SelectedCategory, ItemNameForPlacement, CharacteristicProperties) Export
	
	Items = Form.Items;
	
	DeleteOldAttributesAndItems(Form, List, CharacteristicProperties);
	
	If Not ValueIsFilled(SelectedCategory) Then
		Return;
	EndIf;
	
	If CharacteristicProperties Then
		PropertySet = SelectedCategory.CharacteristicPropertySet;
	Else
		PropertySet = SelectedCategory.PropertySet;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("PropertySet", PropertySet);
	Query.TempTablesManager = New TempTablesManager;
	Query.Text = 
	"SELECT ALLOWED
	|	SetsAdditionalDetails.LineNumber AS Order,
	|	FillingStateOfCategoryProperties.Property AS Property,
	|	FillingStateOfCategoryProperties.Value AS Value,
	|	ISNULL(FillingStateOfCategoryProperties.ValueType.FullName, """") AS ValueTypeFullName
	|INTO PropertiesAndValues
	|FROM
	|	InformationRegister.FillingStateOfCategoryProperties AS FillingStateOfCategoryProperties
	|		LEFT JOIN Catalog.AdditionalAttributesAndInformationSets.AdditionalAttributes AS SetsAdditionalDetails
	|		ON FillingStateOfCategoryProperties.Property = SetsAdditionalDetails.Property
	|WHERE
	|	FillingStateOfCategoryProperties.PropertySet = &PropertySet
	|	AND SetsAdditionalDetails.Ref = &PropertySet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	PropertiesAndValues.Order AS Order,
	|	PropertiesAndValues.Property AS Property,
	|	COUNT(DISTINCT PropertiesAndValues.Value) AS Quantity
	|FROM
	|	PropertiesAndValues AS PropertiesAndValues
	|
	|GROUP BY
	|	PropertiesAndValues.Order,
	|	PropertiesAndValues.Property
	|
	|ORDER BY
	|	Order";
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		If CommonUse.TypeDescriptionFullConsistsOfType(Selection.Property.ValueType, Type("Number")) Then
			
			NewPropertyDescription(
				Form.СвойстваОписаниеДополнительныхРеквизитов,
				PropertySet,
				Selection.Property,
				CharacteristicProperties,
				"From");
			
			NewPropertyDescription(
				Form.СвойстваОписаниеДополнительныхРеквизитов,
				PropertySet,
				Selection.Property,
				CharacteristicProperties,
				"До");
			
		Else
			
			NewPropertyDescription(
				Form.СвойстваОписаниеДополнительныхРеквизитов,
				PropertySet,
				Selection.Property,
				CharacteristicProperties);
			
		EndIf;
		
	EndDo;
	
	AttributesToAdd = New Array();
	
	For Each PropertyDetails In Form.СвойстваОписаниеДополнительныхРеквизитов Do
		
		If PropertyDetails.CharacteristicProperty <> CharacteristicProperties Then
			Continue;
		EndIf;
		
		ValueType = ?(CommonUse.TypeDescriptionFullConsistsOfType(PropertyDetails.ValueType, Type("Number")),
						New TypeDescription("String",,,, New StringQualifiers(1024)),
						PropertyDetails.ValueType);
		
		Attribute = New FormAttribute(
			PropertyDetails.AttributeNameValue,
			ValueType,,
			PropertyDetails.Description);
			
		AttributesToAdd.Add(Attribute);
		
	EndDo;
	Form.ChangeAttributes(AttributesToAdd);
	
	PropertiesPlacementOwnerItem = Items[ItemNameForPlacement];
	For Each PropertyDetails In Form.СвойстваОписаниеДополнительныхРеквизитов Do
		
		If PropertyDetails.CharacteristicProperty <> CharacteristicProperties Then
			Continue;
		EndIf;
		
		If IsLeftBorderOfNumericAttributeRange(PropertyDetails.AttributeNameValue) Then
			
			ItemLeftBorder = PropertyDetails;
			FilterParameters = New Structure;
			FilterParameters.Insert("AttributeNameValue", StrReplace(PropertyDetails.AttributeNameValue, "_from", "_до"));
			Rows = Form.СвойстваОписаниеДополнительныхРеквизитов.FindRows(FilterParameters);
			If Rows.Count() <> 0 Then
				ItemRightBorder = Rows[0];
			EndIf;
			
			CreatedItems = New Array;
			CreatedItems.Add(ItemLeftBorder);
			CreatedItems.Add(ItemRightBorder);
			NewFormItem(Form, CreatedItems, PropertiesPlacementOwnerItem);
			
		ElsIf IsRightBorderOfNumericAttributeRange(PropertyDetails.AttributeNameValue) Then
			
			Continue;
			
		Else
			
			ValuesOfSelection = Undefined;
			
			If CommonUse.TypeDescriptionFullConsistsOfType(PropertyDetails.ValueType, Type("CatalogRef.ObjectsPropertiesValues"))
				Or CommonUse.TypeDescriptionFullConsistsOfType(PropertyDetails.ValueType, Type("CatalogRef.ObjectsPropertiesValuesHierarchy")) Then
				FilterParameters = New Structure("Property", PropertyDetails.Property);
				
				Query.Text = 
				"SELECT ALLOWED
				|	PropertiesAndValues.Property AS Property,
				|	PropertiesAndValues.Value AS Value,
				|	PropertiesAndValues.ValueTypeFullName AS ValueTypeFullName
				|FROM
				|	PropertiesAndValues AS PropertiesAndValues
				|WHERE
				|	PropertiesAndValues.Property = &Property
				|	AND PropertiesAndValues.ValueTypeFullName <> """"";
				Query.SetParameter("Property", PropertyDetails.Property);
				ChoiceValuesSelection = Query.Execute().Select();
				
				ValuesOfSelection = New Array;
				While ChoiceValuesSelection.Next() Do
					ValuesOfSelection.Add(
						CommonUse.ObjectManagerByFullName(ChoiceValuesSelection.ValueTypeFullName)
							.GetRef(ChoiceValuesSelection.Value));
				EndDo;
			EndIf;
			
			CreatedItems = New Array;
			CreatedItems.Add(PropertyDetails);
			
			NewFormItem(Form, CreatedItems, PropertiesPlacementOwnerItem, ValuesOfSelection);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Заполняет свойства номенклатуры по выбранной категории.
// Заполняемые свойства: тип номенклатуры, единица измерения, признак использования характеристик.
//
// Parameters:
//  ProductsAndServices - FormDataStructure - Объект номенклатуры.
//
Procedure FillProductsAndServicesPropertyByCategory(ProductsAndServices) Export
	
	If ValueIsFilled(ProductsAndServices.ProductsAndServicesCategory) Then
		Category = ProductsAndServices.ProductsAndServicesCategory;
	Else
		Category = CategoryFillingValue();
		ProductsAndServices.ProductsAndServicesCategory = Category;
	EndIf;

	If Not ValueIsFilled(ProductsAndServices.Ref) And (ProductsAndServices.ProductsAndServicesType = Enums.ProductsAndServicesTypes.InventoryItem
		Or ProductsAndServices.ProductsAndServicesType = Enums.ProductsAndServicesTypes.Service
		Or ProductsAndServices.ProductsAndServicesType = Enums.ProductsAndServicesTypes.Work) Then

		If ProductsAndServices.ProductsAndServicesType = Enums.ProductsAndServicesTypes.InventoryItem Then
			FillPropertyValues(ProductsAndServices, Category, "AlcoholicProductsKind");
		EndIf;
		
	EndIf;
	
EndProcedure

// Возвращает имя поля отбора для установления отбора списка номенклатуры по значению свойства.
//
// Parameters:
//  Form					 - ClientApplicationForm - Форма объекта-владельца, в котором происходит отбор по свойству номенклатуры.
//  ElementName				 - String - Имя элемента на форме, в котором был произведен выбор значения номенклатуры для отбора.
//  ProductsAndServicesCategory	 - CatalogRef.ProductsAndServicesCategories - Выбранная категория номенклатуры.
// 
// Returns:
//  String - Имя поля отбора.
//
Function FieldOfAdditionalAttributeFilter(Form, ElementName, ProductsAndServicesCategory) Export
	
	PropertyDetails = PropertyDetails(Form, ElementName);
	FilterField = FieldOfAdditionalAttributeFilterFromPropertyDescription(PropertyDetails, ProductsAndServicesCategory);
	Return FilterField;
	
EndFunction

// Устанавливает отбор списка номенклатуры по выбранной категории.
//
// Parameters:
//  Form				 - ClientApplicationForm - Форма объекта-владельца, в котором требуется установить отбор номенклатуры по категории.
//  List				 - DynamicList - Список на форме.
//  SelectedCategory	 - CatalogRef.ProductsAndServicesCategories - Категория, по которой требуется установить отбор.
//
Procedure SetFilterByCategory(Form, List, SelectedCategory) Export
	
	DeletePreviousCategoryPropertyFilters(Form, List);
	
	If Not ValueIsFilled(SelectedCategory) Then
		
		CommonUseClientServer.DeleteItemsOfFilterGroup(
			List.SettingsComposer.Settings.Filter,,
			"FilterByCategorty");
		Return;
		
	EndIf;
	
	GroupFilterByCategory = CommonUseClientServer.CreateGroupOfFilterItems(
		List.SettingsComposer.Settings.Filter.Items,
		"FilterByCategorty",
		DataCompositionFilterItemsGroupType.OrGroup);
		
	CommonUseClientServer.AddCompositionItem(
		GroupFilterByCategory,
		"ProductsAndServicesCategory",
		DataCompositionComparisonType.Equal,
		SelectedCategory,
		"FilterByCategorty",
		ValueIsFilled(SelectedCategory));
	
	CommonUseClientServer.AddCompositionItem(
		GroupFilterByCategory,
		"ProductsAndServicesCategory",
		DataCompositionComparisonType.InHierarchy,
		SelectedCategory,
		"FilterByCategortyWithHierarchy",
		ValueIsFilled(SelectedCategory));
	
EndProcedure

// Устанавливает отбор списка номенклатуры по значению свойства номенклатуры или характеристики.
//
// Parameters:
//  Form					 - ClientApplicationForm - Форма объекта-владельца, в котором происходит отбор по свойству.
//  List					 - DynamicList - Список на форме.
//  ElementName				 - String - Имя элемента на форме, в котором был произведен выбор значения номенклатуры для отбора.
//  ProductsAndServicesCategory	 - CatalogRef.ProductsAndServicesCategories - Выбранная категория номенклатуры.
//
Procedure SetFilterByAdditionalAttribute(Form, List, ElementName, ProductsAndServicesCategory) Export
	
	PropertyDetails = PropertyDetails(Form, ElementName);
	FilterField = FieldOfAdditionalAttributeFilterFromPropertyDescription(PropertyDetails, ProductsAndServicesCategory);
	
	Value = Form[ElementName];
	ComparisonTypeValues = DataCompositionComparisonType.Equal;
	
	If CommonUse.TypeDescriptionFullConsistsOfType(PropertyDetails.ValueType, Type("Number")) Then
		
		If Not ValueIsFilled(Value) Then
			DeleteFilterInList(List, ElementName);
		EndIf;
		
		If ValueIsFilled(Value) Then
			
			Try
				Value = Number(Value);
			Except
				CommonUseClientServer.MessageToUser(
					NStr("en='Ожидается ввод числа!';ru='Ожидается ввод числа!';vi='Dự kiến sẽ ​​nhập số!'"),,,
					Form.Items[ElementName].DataPath);
			EndTry;
			
			If IsLeftBorderOfNumericAttributeRange(ElementName) Then
				ComparisonTypeValues = DataCompositionComparisonType.GreaterOrEqual;
			ElsIf IsRightBorderOfNumericAttributeRange(ElementName) Then
				ComparisonTypeValues = DataCompositionComparisonType.LessOrEqual;
			EndIf;
			
			SetFilterInList(List, FilterField, ComparisonTypeValues, Value, ElementName);
			
		EndIf;
		
	ElsIf CommonUse.TypeDescriptionFullConsistsOfType(PropertyDetails.ValueType, Type("Boolean")) Then
		
		If Value Then
			SetFilterInList(List, FilterField, ComparisonTypeValues, Value, ElementName);
		Else
			DeleteFilterInList(List, ElementName);
		EndIf;
		
	Else
		
		SetFilterInList(List, FilterField, ComparisonTypeValues, Value, ElementName);
		
	EndIf;
	
EndProcedure

Procedure PropertyFillingCheckBeforeWrite(Object, Cancel) Export
	
	// Сохраним предыдущие значения для анализа в ПриЗаписи()
	Query = New Query;
	Query.Text =
	"SELECT
	|	ObjectAdditionalAttributes.Property,
	|	ObjectAdditionalAttributes.Value
	|FROM
	|	" + Object.Ref.Metadata().FullName() + ".AdditionalAttributes AS ObjectAdditionalAttributes
	|WHERE
	|	ObjectAdditionalAttributes.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Object.DeletionMark
	|	%ObjectFields%
	|FROM
	|	" + Object.Ref.Metadata().FullName() + " AS Object
	|WHERE
	|	Object.Ref = &Ref";
	
	IsProductsAndServices = (TypeOf(Object) = Type("CatalogObject.ProductsAndServices"));
	If IsProductsAndServices Then
		Query.Text = StrReplace(Query.Text, "%ObjectFields%", ",Object.ProductsAndServicesCategory");
	Else
		Query.Text = StrReplace(Query.Text, "%ObjectFields%", "");
	EndIf;
	
	
	Query.SetParameter("Ref", Object.Ref);
	Result = Query.ExecuteBatch();
	
	PropertiesOfObject = Result[0].Unload();
	
	Selection = Result[1].Select();
	While Selection.Next() Do
		DeletionMark = Selection.DeletionMark;
		
		If IsProductsAndServices Then
			ProductsAndServicesCategory = Selection.ProductsAndServicesCategory;
		EndIf;
		
	EndDo;
	
	If DeletionMark = Undefined Then
		DeletionMark = False;
	EndIf;
	
	Object.AdditionalProperties.Insert("PropertiesOfObject", PropertiesOfObject);
	Object.AdditionalProperties.Insert("DeletionMark", DeletionMark);
	If IsProductsAndServices Then
		Object.AdditionalProperties.Insert("ProductsAndServicesCategory", ProductsAndServicesCategory);
	EndIf;
	
EndProcedure

Procedure PropertyFillingCheckOnWrite(Object, ProductsAndServicesCategory, Cancel) Export
	
	IsProductsAndServices = (TypeOf(Object) = Type("CatalogObject.ProductsAndServices"));
	
	If Object.AdditionalProperties.Property("DeletionMark") Then
		ObjectDeletionMark = Object.AdditionalProperties.DeletionMark;
	Else
		ObjectDeletionMark = False;
	EndIf;
	
	If IsProductsAndServices Then
		If Object.AdditionalProperties.Property("ProductsAndServicesCategory") Then
			ObjectProductsAndServicesCategory = Object.AdditionalProperties.ProductsAndServicesCategory;
			If ObjectProductsAndServicesCategory <> Object.ProductsAndServicesCategory Then
				WriteCategoryFillingValue(Object.ProductsAndServicesCategory);
			EndIf;
		EndIf;
	EndIf;
	
	If IsProductsAndServices Then
		PropertySet = ProductsAndServicesCategory.PropertySet;
	Else
		PropertySet = ProductsAndServicesCategory.CharacteristicPropertySet;
	EndIf;
	
	// при обмене данными НаборСвойств может оказаться пустым, поэтому прекращаем запись
	// данные регистра свой 
	If Not ValueIsFilled(PropertySet) Then
		Return;
	EndIf;
	
	PropertiesToDelete = New ValueTable;
	PropertiesToAdd = New ValueTable;
	
	PropertiesToDelete.Columns.Add("Property");
	PropertiesToDelete.Columns.Add("Value");
	
	PropertiesToAdd.Columns.Add("Property");
	PropertiesToAdd.Columns.Add("Value");
	
	If Object.DeletionMark And Object.DeletionMark <> ObjectDeletionMark Then 
		
		// Объект стал помечен на удаление
		For Each ObjectString In Object.AdditionalAttributes Do
			
			NewRow = PropertiesToDelete.Add();
			FillPropertyValues(NewRow, ObjectString);
			
		EndDo;
		
	ElsIf Not Object.DeletionMark And Object.DeletionMark <> ObjectDeletionMark Then
		
		// Объект снят с удаления
		For Each ObjectString In Object.AdditionalAttributes Do
			
			NewRow = PropertiesToAdd.Add();
			FillPropertyValues(NewRow, ObjectString);
			
		EndDo;
		
	ElsIf Not Object.DeletionMark And Object.DeletionMark = ObjectDeletionMark Then 
		
		// Обычная запись
		If Object.AdditionalProperties.Property("PropertiesOfObject") Then
			
			PropertiesOfObject = Object.AdditionalProperties.PropertiesOfObject;
			
			For Each ObjectString In Object.AdditionalAttributes Do
				
				DBRow = PropertiesOfObject.Find(ObjectString.Property, "Property");
				
				If DBRow = Undefined Then 
					
					// Добавлено свойство
					NewRow = PropertiesToAdd.Add();
					FillPropertyValues(NewRow, ObjectString);
					Continue;
					
				EndIf;
					
				If DBRow.Value = ObjectString.Value Then
					
					// Свойство не изменено
					PropertiesOfObject.Delete(DBRow);
					Continue;
					
				EndIf;
				
				If DBRow.Value <> ObjectString.Value Then
					
					// Свойство изменено
					NewRow = PropertiesToDelete.Add();
					FillPropertyValues(NewRow, DBRow);
					
					NewRow = PropertiesToAdd.Add();
					FillPropertyValues(NewRow, ObjectString);
					
					PropertiesOfObject.Delete(DBRow);
					
				EndIf;
				
			EndDo;
			
			// Остались удаленные свойства
			For Each DBRow In PropertiesOfObject Do
				
				NewRow = PropertiesToDelete.Add();
				FillPropertyValues(NewRow, DBRow);
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	For Each PropertyToDelete In PropertiesToDelete Do
		DeletePropertyFromRegister(PropertyToDelete.Property, PropertyToDelete.Value, PropertySet);
	EndDo;
	
	For Each AddedProperty In PropertiesToAdd Do
		AddPropertyToRegister(AddedProperty.Property, AddedProperty.Value, PropertySet);
	EndDo;
	
EndProcedure

Procedure SetProductsAndServicesFilterKindSetting(FilterKind = Undefined) Export
	
	If Not AccessRight("Update", Metadata.InformationRegisters.UserSettings) Then
		Return;
	EndIf;
	
	If FilterKind = Undefined Then
		FilterKind = Enums.ВидыОтборовНоменклатуры.ProductsAndServicesCategories;
	EndIf;
	
	CurrentSetting = SmallBusinessReUse.GetValueOfSetting("MainFilterKind");
	If CurrentSetting <> FilterKind Then
		SmallBusinessServer.SetUserSetting(FilterKind, "MainFilterKind");
	EndIf;
	
EndProcedure

Function GetProductsAndServicesFilterKindSettings() Export
	
	FilterKind = SmallBusinessReUse.GetValueOfSetting("MainFilterKind");
	If FilterKind = Undefined Or Not ValueIsFilled(FilterKind) Then
		
		FilterKindByDefault = SettingProductsAndServicesFilterKindByDefault();
		If FilterKindByDefault = Undefined Or Not ValueIsFilled(FilterKindByDefault) Then
			FilterKind = Enums.ВидыОтборовНоменклатуры.ProductsAndServicesGroups;
		Else
			FilterKind = FilterKindByDefault;
		EndIf;
		
		If AccessRight("Update", Metadata.InformationRegisters.UserSettings) Then
			SmallBusinessServer.SetUserSetting(FilterKind, "MainFilterKind");
		EndIf;
		
	EndIf;
	
	Return FilterKind;
	
EndFunction

#EndRegion

#Region InternalProceduresAndFunctions

Function CancelGLAccountChange(Ref)
	
	Query = New Query(
	"SELECT
	|	Inventory.Period,
	|	Inventory.Recorder,
	|	Inventory.LineNumber,
	|	Inventory.Active,
	|	Inventory.RecordType,
	|	Inventory.Company,
	|	Inventory.StructuralUnit,
	|	Inventory.GLAccount,
	|	Inventory.ProductsAndServices,
	|	Inventory.Characteristic,
	|	Inventory.Batch,
	|	Inventory.CustomerOrder,
	|	Inventory.Quantity,
	|	Inventory.Amount,
	|	Inventory.StructuralUnitCorr,
	|	Inventory.CorrGLAccount,
	|	Inventory.ProductsAndServicesCorr,
	|	Inventory.CharacteristicCorr,
	|	Inventory.BatchCorr,
	|	Inventory.CustomerCorrOrder,
	|	Inventory.Specification,
	|	Inventory.SpecificationCorr,
	|	Inventory.OrderSales,
	|	Inventory.SalesDocument,
	|	Inventory.Department,
	|	Inventory.Responsible,
	|	Inventory.VATRate,
	|	Inventory.FixedCost,
	|	Inventory.ProductionExpenses,
	|	Inventory.Return,
	|	Inventory.ContentOfAccountingRecord,
	|	Inventory.RetailTransferAccrualAccounting
	|FROM
	|	AccumulationRegister.Inventory AS Inventory
	|WHERE
	|	Inventory.ProductsAndServices = &ProductsAndServices
	|	OR Inventory.ProductsAndServicesCorr = &ProductsAndServices");
	
	Query.SetParameter("ProductsAndServices", ?(ValueIsFilled(Ref), Ref, Undefined));
	
	Result = Query.Execute();
	
	Return Not Result.IsEmpty();
	
EndFunction 

Function SettingProductsAndServicesFilterKindByDefault()
	
	Query = New Query;
	Query.SetParameter("User", Users.RefsUnspecifiedUser());
	Query.SetParameter("Setting"   , ChartsOfCharacteristicTypes.UserSettings.MainFilterKind);
	Query.Text =
	"SELECT
	|	Value
	|FROM
	|	InformationRegister.UserSettings AS RegisterRightsValue
	|
	|WHERE
	|	User = &User
	| AND Setting    = &Setting";
	
	Selection = Query.Execute().Select();
	
	EmptyValue = ChartsOfCharacteristicTypes.UserSettings.MainFilterKind.ValueType.AdjustValue();
	
	If Selection.Count() = 0 Then
		
		Return EmptyValue;
		
	ElsIf Selection.Next() Then
		
		If Not ValueIsFilled(Selection.Value) Then
			Return EmptyValue;
		Else
			Return Selection.Value;
		EndIf;
		
	Else
		Return EmptyValue;
		
	EndIf;
	
EndFunction // ПолучитьЗначениеНастройки()

Function CategoryFillingValue() Export
	
	FillingCategory = Catalogs.ProductsAndServicesCategories.EmptyRef();
	
	Category = SmallBusinessReUse.GetValueOfSetting("FillingValueProductsAndServicesCategory");
	
	If Not Category.IsFolder Then
		FillingCategory = Category;
	EndIf;
	
	If Not ValueIsFilled(FillingCategory) Then
		FillingCategory = Catalogs.ProductsAndServicesCategories.WithoutCategory;
		WriteCategoryFillingValue(FillingCategory);
	EndIf;
	
	Return FillingCategory;
	
EndFunction

Procedure WriteCategoryFillingValue(Category) Export
	
	CategoryInSettings = SmallBusinessReUse.GetValueOfSetting("FillingValueProductsAndServicesCategory");
	If CategoryInSettings = Category
		Or Not ValueIsFilled(Category) Then
		
		Return;
	EndIf;
	SmallBusinessServer.SetUserSetting(Category, "FillingValueProductsAndServicesCategory");
	
EndProcedure

Function PropertyDetails(Form, ElementName)
	
	FilterParameters = New Structure("AttributeNameValue", ElementName);
	Rows = Form.СвойстваОписаниеДополнительныхРеквизитов.FindRows(FilterParameters);
	If Rows.Count() <> 0 Then
		Return Rows[0];
	Else
		Return Undefined;
	EndIf;
	
EndFunction

Procedure SetItemProperties(Form, Item, PropertyDetails, ValuesOfSelection = Undefined)
	
	If PropertyDetails.Boolean Then
		Item.Type = FormFieldType.CheckBoxField;
		Item.TitleLocation = FormItemTitleLocation.Right;
	Else
		Item.Type = FormFieldType.InputField;
		Item.OpenButton = False;
		Item.TitleLocation = FormItemTitleLocation.None;
		
		If IsLeftBorderOfNumericAttributeRange(PropertyDetails.AttributeNameValue) Then
			InputHint = PropertyDetails.Title + " From";
			ToolTip = PropertyDetails.Title;
		ElsIf IsRightBorderOfNumericAttributeRange(PropertyDetails.AttributeNameValue) Then
			InputHint = "До";
			ToolTip = PropertyDetails.Title;
		Else
			InputHint = PropertyDetails.Title;
			ToolTip = PropertyDetails.Title;
		EndIf;
		
		Item.InputHint = InputHint;
		Item.ToolTip = ToolTip;
		Item.ToolTipRepresentation = ToolTipRepresentation.Balloon;
		
	EndIf;
	
	Item.Title = PropertyDetails.Title;
	Item.DataPath = PropertyDetails.AttributeNameValue;
	Item.SetAction("OnChange", "Attachable_AdditionalAttributeOnChange");
	
	If CommonUse.TypeDescriptionFullConsistsOfType(PropertyDetails.ValueType, Type("CatalogRef.ObjectsPropertiesValues"))
		Or CommonUse.TypeDescriptionFullConsistsOfType(PropertyDetails.ValueType, Type("CatalogRef.ObjectsPropertiesValuesHierarchy")) Then
		
		Item.SetAction("ChoiceProcessing", "Attachable_AdditionalAttributeChoiceProcessing");
		
		ChoiceParameters = New Array;
		ChoiceParameters.Add(New ChoiceParameter("Filter.Owner",
			?(ValueIsFilled(PropertyDetails.AdditionalValuesOwner),
				PropertyDetails.AdditionalValuesOwner, PropertyDetails.Property)));
		
		Item.ChoiceParameters = New FixedArray(ChoiceParameters);
		
		If ValuesOfSelection <> Undefined Then
			
			Item.SetAction("StartChoice", "Attachable_AdditionalAttributeStartChoice");
			
			If ValuesOfSelection.Count() <= 10 Then
				Item.ChoiceList.LoadValues(ValuesOfSelection);
				Item.ListChoiceMode = True;
			Else
				PropertyDetails.СписокВыбораЗначенийСсылка = PutToTempStorage(ValuesOfSelection, Form.UUID);
				
				Item.ListChoiceMode = False;
				Item.QuickChoice = False;
				Item.ChoiceHistoryOnInput = ChoiceHistoryOnInput.Auto;
			EndIf;
			
		EndIf;
		
		Item.CreateButton = False;
		
	EndIf;
	
EndProcedure

Function NewFormItem(Form, CreatedItems, Parent, ValuesOfSelection = Undefined)
	
	FirstItem = CreatedItems[0].AttributeNameValue;
	If IsLeftBorderOfNumericAttributeRange(FirstItem) Then
		FirstItem = StrReplace(FirstItem, "_from", "");
	ElsIf IsRightBorderOfNumericAttributeRange(FirstItem) Then
		FirstItem = StrReplace(FirstItem, "_до", "");
	EndIf;
	
	Group = Form.Items.Add(FirstItem + "_group", Type("FormGroup"), Parent);
	Group.Type = FormGroupType.UsualGroup;
	Group.ShowTitle = False;
	Group.Representation = UsualGroupRepresentation.None;
	Group.Group = ChildFormItemsGroup.Vertical;
	
	If CreatedItems.Count() > 1 Then
		
		Group = Form.Items.Add(FirstItem + "_group_group", Type("FormGroup"), Group);
		Group.Type = FormGroupType.UsualGroup;
		Group.ShowTitle = False;
		Group.Representation = UsualGroupRepresentation.None;
		Group.Group = ChildFormItemsGroup.AlwaysHorizontal;
		
		For Each AddingItem In CreatedItems Do
			
			Item = Form.Items.Add(AddingItem.AttributeNameValue, Type("FormField"), Group);
			
			SetItemProperties(Form, Item, AddingItem);
			
		EndDo;
		
	Else
		
		Item = Form.Items.Add(CreatedItems[0].AttributeNameValue, Type("FormField"), Group);
		
		SetItemProperties(Form, Item, CreatedItems[0], ValuesOfSelection);
		
	EndIf;
	
EndFunction

Function NewPropertyDescription(TableWriteoff, PropertySet, Property, IsCharacteristicProperty, PostFix = "")
	
	NewRow = TableWriteoff.Add();
	NewRow.PropertySet                   = PropertySet;
	NewRow.Property                       = Property;
	NewRow.AdditionalValuesOwner = Property.AdditionalValuesOwner;
	NewRow.Title                      = Property.Title;
	NewRow.Description                   = Property.Description;
	NewRow.ValueType                    = Property.ValueType;
	NewRow.FormatProperties                 = Property.FormatProperties;
	NewRow.Boolean = CommonUse.TypeDescriptionFullConsistsOfType(NewRow.ValueType, Type("Boolean"));
	NewRow.CharacteristicProperty         = IsCharacteristicProperty;
	
	NewRow.AdditionalValue = 
		PropertiesManagementService.ValueTypeContainsPropertiesValues(Property.ValueType);
	
	If ValueIsFilled(PostFix) Then
		PostFix = "_" + PostFix;
	EndIf;
	
	NameUniquePart = 
			StrReplace(Upper(String(PropertySet.UUID())), "-", "x")
			+ "_"
			+ StrReplace(Upper(String(Property.UUID())), "-", "x")
			+ PostFix;
	
	NewRow.AttributeNameValue =
			"AdditionalAttributeValue_" + NameUniquePart;
	
EndFunction

Function IsLeftBorderOfNumericAttributeRange(AttributeName)
	
	RangeStartPostfix = "_from";
	Return StrFind(AttributeName,
					RangeStartPostfix,, 
					StrLen(AttributeName) - StrLen(RangeStartPostfix) + 1) <> 0;
	
EndFunction

Function IsRightBorderOfNumericAttributeRange(AttributeName)
	
	RangeStartPostfix = "_до";
	Return StrFind(AttributeName,
					RangeStartPostfix,, 
					StrLen(AttributeName) - StrLen(RangeStartPostfix) + 1) <> 0;
	
EndFunction

Procedure DeleteOldAttributesAndItems(Form, List, CharacteristicProperties)
	
	If CharacteristicProperties Then
		
		Filter = New Structure("CharacteristicProperty", True);
		Controls = Form.СвойстваОписаниеДополнительныхРеквизитов.FindRows(Filter);
		
	Else
		
		Controls = Form.СвойстваОписаниеДополнительныхРеквизитов;
		
	EndIf;
	
	Items = Form.Items;
	
	DeletedItems = New Array;
	AttributesToBeRemoved = New Array;
	For Each FormItem In Controls Do
		
		AttributesToBeRemoved.Add(FormItem.AttributeNameValue);
		
		AttributeItem = FormItem.AttributeNameValue;
		
		DeletedItems.Clear();
		DeletedItems.Add(AttributeItem);
		
		AttributeItem = StrReplace(AttributeItem, "_from", "");
		AttributeItem = StrReplace(AttributeItem, "_до", "");
		
		AttributeItem = AttributeItem + "_group";
		DeletedItems.Add(AttributeItem);
		
		AttributeItem = AttributeItem + "_group";
		DeletedItems.Add(AttributeItem + "_group" + "_group");
		
		For Each ItemName In DeletedItems Do
			
			ElementToDelete = Items.Find(ItemName);
			If ElementToDelete <> Undefined Then
				
				Items.Delete(ElementToDelete);
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	For Each AttributeToBeDeleted In AttributesToBeRemoved Do
		
		DeleteFilterInList(List, AttributeToBeDeleted);
		
		Filter = New Structure("AttributeNameValue", AttributeToBeDeleted);
		Rows = Form.СвойстваОписаниеДополнительныхРеквизитов.FindRows(Filter);
		If Rows.Count() <> 0 Then
			Form.СвойстваОписаниеДополнительныхРеквизитов.Delete(Rows[0]);
		EndIf;
		
	EndDo;
	
	Form.ChangeAttributes(, AttributesToBeRemoved);
	
EndProcedure

Procedure DeletePreviousCategoryPropertyFilters(Form, List)
	
	CommonUseClientServer.DeleteItemsOfFilterGroup(
		List.SettingsComposer.Settings.Filter,,
		"FilterByPropertiesOfSelectedCategory");
			
	TagsData = Form.TagsData.Unload(, "FilterFieldName");
	TagsData.GroupBy("FilterFieldName");
	For Each Mark In TagsData Do
		
		CommonUseClientServer.DeleteItemsOfFilterGroup(
			List.SettingsComposer.Settings.Filter,
			Mark.FilterFieldName);
		
	EndDo;
	
	Form.TagsData.Clear();
	
EndProcedure

Procedure SetFilterInList(List, FieldName, ComparisonTypeValues, Value, Presentation)
	
	FilterGroup = CommonUseClientServer.FindFilterItemByPresentation(
		List.SettingsComposer.Settings.Filter.Items,
		"FilterByPropertiesOfSelectedCategory");
	
	If FilterGroup = Undefined Then
		
		FilterGroup = CommonUseClientServer.CreateGroupOfFilterItems(
			List.SettingsComposer.Settings.Filter.Items,
			"FilterByPropertiesOfSelectedCategory",
			DataCompositionFilterItemsGroupType.AndGroup);
		
	EndIf;
	
	FilterItem = CommonUseClientServer.FindFilterItemByPresentation(
		FilterGroup.Items,
		Presentation);
	
	If FilterItem = Undefined Then
		CommonUseClientServer.AddCompositionItem(
			FilterGroup,
			FieldName,
			ComparisonTypeValues,
			Value,
			Presentation,
			True);
	Else
		
		CommonUseClientServer.ChangeFilterItems(
			List.SettingsComposer.Settings.Filter,
			FieldName,
			Presentation,
			Value,
			ComparisonTypeValues);
		
	EndIf;
	
EndProcedure

Procedure DeleteFilterInList(List, Presentation)
	
	CommonUseClientServer.DeleteItemsOfFilterGroup(
		List.SettingsComposer.Settings.Filter,,
		Presentation);
	
EndProcedure

Procedure DeletePropertyFromRegister(Property, Value, PropertySet)
	
	ValueID = Undefined;
	If CommonUse.IsReference(TypeOf(Value)) Then
		ValueID = Value.UUID();
	EndIf;
	
	RecordSet = InformationRegisters.FillingStateOfCategoryProperties.CreateRecordSet();
	RecordSet.Filter.PropertySet.Set(PropertySet);
	RecordSet.Filter.Property.Set(Property);
	RecordSet.Filter.Value.Set(ValueID);
	RecordSet.Read();
	
	If RecordSet.Count() = 0 Then
		Return;
	EndIf;
	
	Record = RecordSet.Get(0);
	If Record.Counter > 1 Then
		Record.Counter = Record.Counter - 1;
	Else
		RecordSet.Delete(Record);
	EndIf;
	RecordSet.Write();
	
EndProcedure

Procedure AddPropertyToRegister(Property, Value, PropertySet)
	
	ValueID = Undefined;
	If CommonUse.IsReference(TypeOf(Value)) Then
		ValueID = Value.UUID();
	EndIf;
	
	RecordSet = InformationRegisters.FillingStateOfCategoryProperties.CreateRecordSet();
	RecordSet.Filter.PropertySet.Set(PropertySet);
	RecordSet.Filter.Property.Set(Property);
	RecordSet.Filter.Value.Set(ValueID);
	RecordSet.Read();
	
	If RecordSet.Count() = 0 Then
		
		NewRecord = RecordSet.Add();
		NewRecord.PropertySet = PropertySet;
		NewRecord.Property = Property;
		NewRecord.Value = ValueID;
		If ValueID <> Undefined Then
			NewRecord.ValueType = CommonUse.MetadataObjectID(TypeOf(Value));
		EndIf;
		NewRecord.Counter = 1;
		
	Else
		
		Record = RecordSet.Get(0);
		Record.Counter = Record.Counter + 1;
		
	EndIf;
	
	RecordSet.Write();
	
EndProcedure

Function FieldOfAdditionalAttributeFilterFromPropertyDescription(PropertyDetails, ProductsAndServicesCategory)
	
	If PropertyDetails.PropertySet = ProductsAndServicesCategory.PropertySet Then
		PropertyParent = "Ref.";
	ElsIf PropertyDetails.PropertySet = ProductsAndServicesCategory.CharacteristicPropertySet Then
		PropertyParent = "Characteristic.";
	EndIf;
	
	Return PropertyParent + String(PropertyDetails.Property);
	
EndFunction

#EndRegion
