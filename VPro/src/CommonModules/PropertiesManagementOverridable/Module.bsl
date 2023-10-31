////////////////////////////////////////////////////////////////////////////////
// Properties subsystem
// 
////////////////////////////////////////////////////////////////////////////////

#Region ProgramInterface

// Получает описание предопределенных наборов свойств.
//
// Parameters:
//  Sets - ValueTree - с колонками:
//     * Name           - String - Имя набора свойств. Формируется из полного имени объекта
//                       метаданных заменой символа "." на "_".
//                       Например, "Документ_ЗаказПокупателя".
//     * ID - UUID - Идентификатор ссылки предопределенного элемента.
//     * Used  - Undefined, Boolean - Признак того, что набор свойств используется.
//                       Например, можно использовать для скрытия набора по функциональным опциям.
//                       Значение по умолчанию - Неопределено, соответствует значению True.
//     * IsFolder     - Boolean - True, если набор свойств является группой.
//
Procedure OnGetPredefinedPropertySets(Sets) Export
	
	
	
EndProcedure

// Получает наименования наборов свойств второго уровня на разных языках.
//
// Parameters:
//  Descriptions - Map - представление набора на переданном языке:
//     * Key     - String - Имя набора свойств. Например, "Справочник_Партнеры_Общие".
//     * Value - String - Наименование набора для переданного кода языка.
//  LanguageCode - String - Код языка. Например, "en".
//
// Example:
//  Наименования["Справочник_Партнеры_Общие"] = НСтр("en='General';ru='Общие';vi='Chung'", КодЯзыка);
//
Procedure OnGetPropertySetDescription(Descriptions, LanguageCode) Export
	
	
	
EndProcedure

// Fills object property sets. Usually required if there is more than one set.
//
// Parameters:
//  Object       - AnyRef      - ссылка на объект со свойствами.
//               - ClientApplicationForm - форма объекта, к которому подключены свойства.
//               - FormDataStructure - описание объекта, к которому подключены свойства.
//
//  ReferenceType    - Type - тип ссылки владельца свойств.
//
//  PropertiesSets - ValueTable - с колонками:
//                    Набор - СправочникСсылка.НаборыДополнительныхРеквизитовИСведений.
//                    ОбщийНабор - Булево - True, если набор свойств содержит свойства,
//                     общие для всех объектов.
//                    // Далее свойства элемента формы типа ГруппаФормы вида обычная группа
//                    // или страница, которая создается, если наборов больше одного без учета
//                    // пустого набора, который описывает свойства группы удаленных реквизитов.
//                    
//                    // Если значение Неопределено, значит, использовать значение по умолчанию.
//                    
//                    // Для любой группы управляемой формы.
//                    Высота                   - Число.
//                    Заголовок                - Строка.
//                    Подсказка                - Строка.
//                    РастягиватьПоВертикали   - Булево.
//                    РастягиватьПоГоризонтали - Булево.
//                    ТолькоПросмотр           - Булево.
//                    ЦветТекстаЗаголовка      - Цвет.
//                    Ширина                   - Число.
//                    ШрифтЗаголовка           - Шрифт.
//                    
//                    // Для обычной группы и страницы.
//                    Группировка              - ГруппировкаПодчиненныхЭлементовФормы.
//                    
//                    // Для обычной группы.
//                    Отображение              - ОтображениеОбычнойГруппы.
//                    
//                    // Для страницы.
//                    Картинка                 - Картинка.
//                    ОтображатьЗаголовок      - Булево.
//
//  StandardProcessing - Boolean - начальное значение True. Указывает, получать ли
//                         основной набор, когда НаборыСвойств.Количество() равно нулю.
//
//  PurposeKey   - Undefined - (начальное значение) - указывает вычислить
//                      ключ назначения автоматически и добавить к значениям свойств
//                      формы КлючНазначенияИспользования и КлючСохраненияПоложенияОкна,
//                      чтобы изменения формы (настройки, положение и размер) сохранялись
//                      отдельно для разного состава наборов.
//                      Например, для каждого вида номенклатуры - свой состав наборов.
//
//                    - String - (не более 32 символа) - использовать указанный ключ
//                      назначения для добавления к значениям свойств формы.
//                      Пустая строка - не изменять свойства ключей формы, т.к. они
//                      устанавливается в форме и уже учитывают различия состава наборов.
//
//                    Добавка имеет формат "КлючНаборовСвойств<КлючНазначения>",
//                    чтобы <КлючНазначения> можно было обновлять без повторной добавки.
//                    При автоматическом вычислении <КлючНазначения> содержит хеш
//                    идентификаторов ссылок упорядоченных наборов свойств.
//
Procedure FillObjectPropertiesSets(Val Object, ReferenceType, PropertiesSets, StandardProcessing, PurposeKey) Export
	
	If ReferenceType = Type("CatalogRef.ProductsAndServices") Then
		
		FillProductsAndServicesPropertySetByCategory(Object, ReferenceType, PropertiesSets);
		
	ElsIf ReferenceType = Type("CatalogRef.ProductsAndServicesCharacteristics") Then
		
		FillCharacteristicPropertySetByCategory(Object, ReferenceType, PropertiesSets);
		
	ElsIf ReferenceType = Type("CatalogRef.Specifications") Then
		
		FillSpecificationPropertySetByCategory(Object, ReferenceType, PropertiesSets);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ServiceInterfaceSB

Function FillAdditionalParameters(Object = Undefined, ItemNameForPlacement = Undefined, ArbitraryObject = Undefined, CommandBarItemName = Undefined, HideDeleted = Undefined) Export
	
	AdditionalParameters = New Structure;
	
	If Object <> Undefined Then
		
		AdditionalParameters.Insert("Object", Object);
		
	EndIf;
	
	If ItemNameForPlacement <> Undefined Then
		
		AdditionalParameters.Insert("ItemNameForPlacement", ItemNameForPlacement);
		
	EndIf;
	
	If ArbitraryObject <> Undefined Then
		
		AdditionalParameters.Insert("ArbitraryObject", ArbitraryObject);
		
	EndIf;
	
	If CommandBarItemName <> Undefined Then
		
		AdditionalParameters.Insert("CommandBarItemName", CommandBarItemName);
		
	EndIf;
	
	If HideDeleted <> Undefined Then
		
		AdditionalParameters.Insert("HideDeleted", HideDeleted);
		
	EndIf;
	
	Return AdditionalParameters;
	
EndFunction

Procedure PropertiesTableOnCreateAtServer(Form, Object = Undefined, PropertiesOwner = Undefined, FillDependenciesDescription = True) Export
	
	Attributes = New Array;
	
	// Проверка значения функциональной опции "Использование свойств".
	OptionUseProperties = Form.GetFormFunctionalOption("UseAdditionalAttributesAndInformation");
	AttributeUseProperties = New FormAttribute("Properties_UseProperties", New TypeDescription("Boolean"));
	Attributes.Add(AttributeUseProperties);
	
	If OptionUseProperties Then
		
		// Добавление реквизита содержащего используемые наборы дополнительных реквизитов.
		Attributes.Add(New FormAttribute(
			"Properties_AdditionalObjectAttributesSets", New TypeDescription("ValueList")));
		
		// Добавление реквизита описания зависимых реквизитов.
		DependentAttributeTable = "Properties_DependentAdditionalAttributesDescription";
		
		Attributes.Add(New FormAttribute(
			DependentAttributeTable, New TypeDescription("ValueTable")));
			
		Attributes.Add(New FormAttribute(
			"AttributeNameValue", New TypeDescription("String"), DependentAttributeTable));
		
		Attributes.Add(New FormAttribute(
			"Property", New TypeDescription("ChartOfCharacteristicTypesRef.AdditionalAttributesAndInformation"), DependentAttributeTable));
		
		Attributes.Add(New FormAttribute(
			"Available", New TypeDescription("Boolean"), DependentAttributeTable));
		
		Attributes.Add(New FormAttribute(
			"AccessibilityCondition", New TypeDescription(), DependentAttributeTable));
		
		Attributes.Add(New FormAttribute(
			"Visible", New TypeDescription("Boolean"), DependentAttributeTable));
			
		Attributes.Add(New FormAttribute(
			"VisibilityCondition", New TypeDescription(), DependentAttributeTable));
		
		Attributes.Add(New FormAttribute(
			"FillObligatory", New TypeDescription("Boolean"), DependentAttributeTable));
		
		Attributes.Add(New FormAttribute(
			"RequiredFillingCondition", New TypeDescription(), DependentAttributeTable));
		
		// Добавление команды формы, если установлена роль "ДобавлениеИзменениеДополнительныхРеквизитовИСведений" или это полноправный пользователь.
		If Users.RolesAvailable("AddChangeAdditionalAttributesAndInformation") Then
			// Добавление команды.
			Command = Form.Commands.Add("EditAdditionalAttributesContent");
			Command.Title = NStr("en='Change the composition of additional attribute';ru='Изменить состав дополнительных реквизитов';vi='Thay đổi thành phần mục tin bổ sung'");
			Command.Action = "Attachable_EditPropertyContent";
			Command.ToolTip = NStr("en='Change the composition of additional attribute';ru='Изменить состав дополнительных реквизитов';vi='Thay đổi thành phần mục tin bổ sung'");
			Command.Picture = PictureLib.ListSettings;
			
			Button = Form.Items.Add(
				"EditAdditionalAttributesContent",
				Type("FormButton"),
				Form.CommandBar
			);
			
			Button.OnlyInAllActions = True;
			Button.CommandName = "EditAdditionalAttributesContent";
		EndIf;
		
	EndIf;
	
	Form.ChangeAttributes(Attributes);
	
	Form.Properties_UseProperties = OptionUseProperties;
	
	AdditionalAttributesInFormFill(Form, Object, PropertiesOwner, FillDependenciesDescription);
	
EndProcedure

Procedure PropertiesTableFillCheckProcessingAtServer(Form, Object = Undefined, Cancel) Export
	
	SessionParameters.InteractivePropertyFillCheck = True;
	
	Errors = Undefined;
	
	Iterator = 0;
	For Each Row In Form.Properties_TablePropertiesAndValues Do
		
		If Row.FillObligatory Then
			
			Result = True;
			
			If Object = Undefined Then
				ObjectDescription = Form.Object;
			Else
				ObjectDescription = Object;
			EndIf;
			
			For Each DependentAttribute In Form.Properties_DependentAdditionalAttributesDescription Do
				
				If DependentAttribute.Property = Row.Property
					And DependentAttribute.RequiredFillingCondition <> Undefined Then
					
					ParameterValues = DependentAttribute.RequiredFillingCondition.ParameterValues;
					ConditionCode         = DependentAttribute.RequiredFillingCondition.ConditionCode;
					Execute("Result = (" + ConditionCode + ")");
					Break;
				EndIf;
				
			EndDo;
			
			If Not Result Then
				Continue;
			EndIf;
			
			If Not ValueIsFilled(Row.Value) Then
				
				CommonUseClientServer.AddUserError(Errors,
					Form.Properties_TablePropertiesAndValues[Iterator].Value,
					StrTemplate(NStr("en='The ""%1"" field is not full.';ru='Поле ""%1"" не заполнено.';vi='Chưa điền trường  ""%1"".'"), Row.Title),
					"");
				EndIf;
				
		EndIf;
		
	EndDo;
	
	CommonUseClientServer.ShowErrorsToUser(Errors, Cancel);
	
EndProcedure

Procedure PropertiesTableBeforeWriteAtServer(Form, Object) Export
	
	Object.AdditionalAttributes.Clear();
	
	For Each Str In Form.Properties_TablePropertiesAndValues Do
		
		If Not ValueIsFilled(Str.Value) Then
			Continue;
		EndIf;
		
		NewRow = Object.AdditionalAttributes.Add();
		NewRow.Property = Str.Property;
		NewRow.Value = Str.Value;
		
	EndDo;
	
EndProcedure

Procedure AdditionalAttributesInFormFill(Form, Object = Undefined, PropertiesOwner = Undefined, FillDependenciesDescription = True) Export
	
	If Not Form.Properties_UseProperties Then
		Return;
	EndIf;
	
	If Object = Undefined Then
		ObjectDescription = Form.Object;
	Else
		ObjectDescription = Object;
	EndIf;
	
	Form.Properties_AdditionalObjectAttributesSets = New ValueList;
	
	If ObjectDescription = Catalogs.ProductsAndServicesCharacteristics.EmptyRef() Then
		
		EmptyRefObjectDescription = Catalogs.ProductsAndServicesCharacteristics.EmptyRef();
		ReferenceType = TypeOf(ObjectDescription);
		
		ObjectPropertiesSets = New ValueTable;
		ObjectPropertiesSets.Columns.Add("Set");
		ObjectPropertiesSets.Columns.Add("Title");
		
		GetMainSet = True;
		
		FillCharacteristicPropertySetByCategory(EmptyRefObjectDescription, ReferenceType, ObjectPropertiesSets, PropertiesOwner);
		
	Else
		
		ObjectPropertiesSets = PropertiesManagementService.GetObjectPropertiesSets(ObjectDescription);
		
	EndIf;
	
	For Each Row In ObjectPropertiesSets Do
		If PropertiesManagementService.SetPropertyTypes(Row.Set).AdditionalAttributes Then
			
			Form.Properties_AdditionalObjectAttributesSets.Add(
				Row.Set, Row.Title);
		EndIf;
	EndDo;
	
	PropertiesDescription = PropertiesManagementService.PropertiesValues(
		ObjectDescription.AdditionalAttributes.Unload(),
		Form.Properties_AdditionalObjectAttributesSets,
		False
	);
	
	Form.Properties_TablePropertiesAndValues.Load(PropertiesDescription);
	For Each Item In Form.Properties_TablePropertiesAndValues Do
		Item.FormatProperties = CommonUse.ObjectAttributeValue(Item.Property, "FormatProperties");
	EndDo;
	
	Iterator = 0;
	For Each PropertyDetails In PropertiesDescription Do
		
		If Not FillDependenciesDescription Then
			Continue;
		EndIf;
		
		// Заполнение таблицы зависимых дополнительных реквизитов.
		If PropertyDetails.AdditionalAttributeDependencies.Count() > 0 Then
			DependentAttributeDescription = Form.Properties_DependentAdditionalAttributesDescription.Add();
			FillPropertyValues(DependentAttributeDescription, PropertyDetails);
		EndIf;
		
		For Each TableRow In PropertyDetails.AdditionalAttributeDependencies Do
			
			If Not ValueIsFilled(TableRow.DependentProperty)
				And Not ValueIsFilled(TableRow.Condition)
				And TableRow.Attribute = Undefined Then
				
				Continue;
			EndIf;
			
			If TypeOf(TableRow.Attribute) = Type("String") Then
				PathToAttribute = "ObjectDescription." + TableRow.Attribute;
			Else
				Rows = Form.Properties_TablePropertiesAndValues.FindRows(New Structure("Property", TableRow.Attribute));
				If Rows.Count() = 0 Then
					Continue;
				EndIf;
				For Each Str In Rows Do
					PathToAttribute = "Form.Properties_TablePropertiesAndValues" + "[" + Str.GetID() + "]" + ".Value";
				EndDo;
			EndIf;
			
			ConditionPattern = "";
			If TableRow.Condition = "Equal" Then
				ConditionPattern = "%1 = %2";
			ElsIf TableRow.Condition = "NotEqual" Then
				ConditionPattern = "%1 <> %2";
			EndIf;
			
			If TableRow.Condition = "InList" Then
				ConditionPattern = "%2.FindByValue(%1) <> Undefined"
			ElsIf TableRow.Condition = "NotInList" Then
				ConditionPattern = "%2.FindByValue(%1) = Undefined"
			EndIf;
			
			RightValue = "";
			If ValueIsFilled(ConditionPattern) Then
				RightValue = "ParameterValues[""" + PathToAttribute + """]";
			EndIf;
			
			If TableRow.Condition = "Filled" Then
				ConditionPattern = "ValueIsFilled(%1)";
			ElsIf TableRow.Condition = "NotFilled" Then
				ConditionPattern = "NOT ValueIsFilled(%1)";
			EndIf;
			
			If ValueIsFilled(RightValue) Then
				ConditionCode = StrTemplate(ConditionPattern, PathToAttribute, RightValue);
			Else
				ConditionCode = StrTemplate(ConditionPattern, PathToAttribute);
			EndIf;
			
			If TableRow.DependentProperty = "Available" Then
				SetDependencyCondition(DependentAttributeDescription.AccessibilityCondition, PathToAttribute, TableRow, ConditionCode, TableRow.Condition);
			ElsIf TableRow.DependentProperty = "Visible" Then
				SetDependencyCondition(DependentAttributeDescription.VisibilityCondition, PathToAttribute, TableRow, ConditionCode, TableRow.Condition);
			Else
				SetDependencyCondition(DependentAttributeDescription.RequiredFillingCondition, PathToAttribute, TableRow, ConditionCode, TableRow.Condition);
			EndIf;
		EndDo;
		
		Iterator = Iterator + 1;
		
	EndDo;
	
EndProcedure

Procedure SetDependencyCondition(DependencyStructure, PathToAttribute, TableRow, ConditionCode, Condition)
	If DependencyStructure = Undefined Then
		ParameterValues = New Map;
		If Condition = "InList"
			Or Condition = "NotInList" Then
			Value = New ValueList;
			Value.Add(TableRow.Value);
		Else
			Value = TableRow.Value;
		EndIf;
		ParameterValues.Insert(PathToAttribute, Value);
		DependencyStructure = New Structure;
		DependencyStructure.Insert("ConditionCode", ConditionCode);
		DependencyStructure.Insert("ParameterValues", ParameterValues);
	ElsIf (Condition = "InList" Or Condition = "NotInList")
		And TypeOf(DependencyStructure.ParameterValues[PathToAttribute]) = Type("ValueList") Then
		DependencyStructure.ParameterValues[PathToAttribute].Add(TableRow.Value);
	Else
		DependencyStructure.ConditionCode = DependencyStructure.ConditionCode + " AND " + ConditionCode;
		If Condition = "InList" Or Condition = "NotInList" Then
			Value = New ValueList;
			Value.Add(TableRow.Value);
		Else
			Value = TableRow.Value;
		EndIf;
		DependencyStructure.ParameterValues.Insert(PathToAttribute, Value);
	EndIf;
EndProcedure

Procedure FillProductsAndServicesPropertySetByCategory(Object, ReferenceType, PropertiesSets)
	
	Row = PropertiesSets.Add();
	Row.Set = Catalogs.AdditionalAttributesAndInformationSets.Catalog_ProductsAndServices_Common;
	
	If TypeOf(Object) = ReferenceType Then
		
		ProductsAndServices = CommonUse.ObjectAttributesValues(Object, "IsFolder, ProductsAndServicesCategory");
		
	Else
		
		ProductsAndServices = Object;
		
	EndIf;
	
	If ProductsAndServices.IsFolder = False Then
		
		Row = PropertiesSets.Add();
		Row.Set = CommonUse.ObjectAttributeValue(ProductsAndServices.ProductsAndServicesCategory, "PropertySet");
		
	EndIf;
	
EndProcedure

Procedure FillCharacteristicPropertySetByCategory(Characteristic, ReferenceType, PropertiesSets, Category = Undefined)
	
	If Category = Undefined Then
		If TypeOf(Characteristic) = ReferenceType Then
			Characteristic = CommonUse.ObjectAttributesValues(
				Characteristic, "Owner"
			);
		EndIf;
		
		Category = Catalogs.ProductsAndServicesCategories.EmptyRef();
		If TypeOf(Characteristic.Owner) = Type("CatalogRef.ProductsAndServicesCategories") Then
			Category = Characteristic.Owner;
		ElsIf TypeOf(Characteristic.Owner) = Type("CatalogRef.ProductsAndServices") Then
			Category = CommonUse.ObjectAttributeValue(Characteristic.Owner, "ProductsAndServicesCategory");
		EndIf;
	EndIf;
	
	If ValueIsFilled(Category) Then
		Row = PropertiesSets.Add();
		Row.Set = CommonUse.ObjectAttributeValue(Category, "CharacteristicPropertySet");
	EndIf;
	
EndProcedure

Procedure FillSpecificationPropertySetByCategory(Object, ReferenceType, PropertiesSets, Category = Undefined)
	
	Row = PropertiesSets.Add();
	Row.Set = Catalogs.AdditionalAttributesAndInformationSets.Catalog_Specifications_Common;
	
	If Category = Undefined Then
		If TypeOf(Object) = ReferenceType Then
			Object = CommonUse.ObjectAttributesValues(
				Object, "Owner"
			);
		EndIf;
		Category = CommonUse.ObjectAttributeValue(Object.Owner, "ProductsAndServicesCategory");
	EndIf;
	
	If ValueIsFilled(Category) Then
		Row = PropertiesSets.Add();
		Row.Set = CommonUse.ObjectAttributeValue(Category, "SpecificationAttributesArray");
	EndIf;
	
EndProcedure

#EndRegion
