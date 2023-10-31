////////////////////////////////////////////////////////////////////////////////
// Properties subsystem
// 
////////////////////////////////////////////////////////////////////////////////

#Region ProgramInterface

////////////////////////////////////////////////////////////////////////////////
// Процедуры и функции для стандартной обработки дополнительных реквизитов.

// Создает основные реквизиты и поля формы, необходимые для работы.
// Заполняет дополнительные реквизиты, если используются.
// Вызывается из обработчика ПриСозданииНаСервере формы объекта со свойствами.
// 
// Parameters:
//  Form - ClientApplicationForm - в которой будут отображаться дополнительные реквизиты.
//
//  AdditionalParameters - Undefined - все дополнительные параметры имеют значения по умолчанию.
//                               Ранее реквизит назывался "Объект" и имел смысл,
//                               как одноименное свойство структуры, указанной ниже.
//                          - Structure - с необязательными свойствами:
//
//    * Object - FormDataStructure - по типу объекта, если свойство не указано или Неопределено,
//               взять объект из реквизита формы "Объект".
//
//    * ItemNameForPlacement - String - имя группы формы, в которой будут размещены свойства.
//
//    * ArbitraryObject - Boolean - если True, тогда в форме создается таблица описания дополнительных
//            реквизитов, параметр Объект игнорируется, дополнительные реквизиты не создаются и не заполняются.
//
//            Это востребовано при последовательном использовании одной формы для просмотра или редактирования
//            дополнительных реквизитов разных объектов (в том числе разных типов).
//
//            После выполнения ПриСозданииНаСервере следует вызывать ЗаполнитьДополнительныеРеквизитыВФорме()
//            для добавления и заполнения дополнительных реквизитов.
//            Чтобы сохранить изменения, следует вызвать ПеренестиЗначенияИзРеквизитовФормыВОбъект(),
//            а для обновления состава реквизитов вызвать ОбновитьЭлементыДополнительныхРеквизитов().
//
//    * CommandBarItemName - String - имя группы формы, в которую будет добавлена кнопка.
//            РедактироватьСоставДополнительныхРеквизитов. Если имя элемента не указано,
//            используется стандартная группа "Форма.КоманднаяПанель".
//
//    * HideDeleted - Boolean - установить/отключить режим скрытия удаленных.
//            Если параметр не указан, а параметр Объект указан и свойство Ссылка не заполнено,
//            тогда начальное значение устанавливается True, иначе Ложь.
//            При вызове процедуры ПередЗаписьюНаСервере в режиме скрытия удаленных удаленные значения
//            очищаются (не переносятся обратно в объект), а режим СкрытьУдаленные устанавливается Ложь.
//
Procedure OnCreateAtServer(Form, AdditionalParameters = Undefined) Export
	
	If Not PropertiesUsed(Form, AdditionalParameters) Then
		Return;
	EndIf;
	
	Context = New Structure;
	Context.Insert("Object",                     Undefined);
	Context.Insert("ItemNameForPlacement",   "");
	Context.Insert("DeferredInitialization",    False);
	Context.Insert("ArbitraryObject",         False);
	Context.Insert("CommandBarItemName", "");
	Context.Insert("HideDeleted",            Undefined);
	
	If TypeOf(AdditionalParameters) = Type("Structure") Then
		FillPropertyValues(Context, AdditionalParameters);
	EndIf;
	
	If Context.ArbitraryObject Then
		CreateAdditionalAttributesDescription = True;
	Else
		If Context.Object = Undefined Then
			ObjectDescription = Form.Object;
		Else
			ObjectDescription = Context.Object;
		EndIf;
		CreateAdditionalAttributesDescription = UseAdditAttributes(ObjectDescription.Ref);
		If Not ValueIsFilled(ObjectDescription.Ref) And Context.HideDeleted = Undefined Then
			Context.HideDeleted = True;
		EndIf;
	EndIf;
	
	CreateMainFormObjects(Form, Context, CreateAdditionalAttributesDescription);
	
	If Context.DeferredInitialization Then
		
		If Not Form.Properties_UseProperties
			Or Not Form.Properties_UseAdditionalAttributes Then
			Return;
		EndIf;
		
		PurposeKey = Undefined;
		ObjectPropertiesSets = PropertiesManagementService.GetObjectPropertiesSets(
			ObjectDescription, PurposeKey);
		
		PropertiesManagementService.FillSetsWithAdditionalAttributes(
			ObjectPropertiesSets,
			Form.Properties_AdditionalObjectAttributesSets);
		
		ShowTab = PropertiesManagementService.ShowTabAdditionally(
			ObjectDescription.Ref, Form.Properties_AdditionalObjectAttributesSets);
		
		If Form.ProperyParameters.Property("EmptyDecorationIsAdded") Then
			For Each NameDecoration In Form.ProperyParameters.DecorationCollection Do
				Form.Items[NameDecoration].Visible = ShowTab;
			EndDo;
		EndIf;
		
		UpdateFormPurposeKey(Form, PurposeKey);
	EndIf;
	
	If Not Context.ArbitraryObject
		And Not Context.DeferredInitialization Then
		AdditionalAttributesInFormFill(Form, ObjectDescription, , Context.HideDeleted);
	EndIf;
	
EndProcedure

// Заполняет объект из реквизитов, созданных в форме.
// Вызывается из обработчика ПередЗаписьюНаСервере формы объекта со свойствами.
//
// Parameters:
//  Form         - ClientApplicationForm - уже настроена в процедуре ПриСозданииНаСервере.
//  CurrentObject - Объект - <MetadataObjectKind>Object.<MetadataObjectName>
//
Procedure OnReadAtServer(Form, CurrentObject) Export
	
	Structure = New Structure("Properties_UseProperties");
	FillPropertyValues(Structure, Form);
	
	If TypeOf(Structure.Properties_UseProperties) = Type("Boolean")
		And Structure.Properties_UseProperties Then
		
		If Form.ProperyParameters.Property("ExecutedDeferredInitialization")
			And Not Form.ProperyParameters.ExecutedDeferredInitialization Then
			Return;
		EndIf;
		
		AdditionalAttributesInFormFill(Form, CurrentObject);
	EndIf;
	
EndProcedure

// Заполняет объект из реквизитов, созданных в форме.
// Вызывается из обработчика ПередЗаписьюНаСервере формы объекта со свойствами.
//
// Parameters:
//  Form         - ClientApplicationForm - уже настроена в процедуре ПриСозданииНаСервере.
//  CurrentObject - Объект - <MetadataObjectKind>Object.<MetadataObjectName>
//
Procedure BeforeWriteAtServer(Form, CurrentObject) Export
	
	PropertiesManagementService.MoveValuesFromFormAttributesToObject(Form, CurrentObject, True);
	
EndProcedure

// Проверяет заполненность реквизитов, обязательных для заполнения.
// 
// Parameters:
//  Form                - ClientApplicationForm - уже настроена в процедуре ПриСозданииНаСервере.
//  Cancel                - Boolean - параметр обработчика ОбработкаПроверкиЗаполненияНаСервере.
//  CheckedAttributes - Array - параметр обработчика ОбработкаПроверкиЗаполненияНаСервере.
//  Object - Объект - по типу объекта, если свойство не указано или Неопределено,
//           объект берется из реквизита формы "Объект".
//
Procedure FillCheckProcessing(Form, Cancel, CheckedAttributes, Object = Undefined) Export
	
	SessionParameters.InteractivePropertyFillCheck = True;
	
	If Not Form.Properties_UseProperties
	 Or Not Form.Properties_UseAdditionalAttributes Then
		
		Return;
	EndIf;
	
	Receiver = New Structure;
	Receiver.Insert("ProperyParameters", Undefined);
	FillPropertyValues(Receiver, Form);
	
	If TypeOf(Receiver.ProperyParameters) = Type("Structure")
		And Receiver.ProperyParameters.Property("ExecutedDeferredInitialization")
		And Not Receiver.ProperyParameters.ExecutedDeferredInitialization Then
		AdditionalAttributesInFormFill(Form, Object);
	EndIf;
	
	For Each Row In Form.Properties_AdditionalAttributesDescription Do
		If Row.FillObligatory And Not Row.Deleted Then
			If Not AttributeAvailableByFunctionalOptions(Row) Then
				Continue;
			EndIf;
			Result = True;
			If Object = Undefined Then
				ObjectDescription = Form.Object;
			Else
				ObjectDescription = Object;
			EndIf;
			
			For Each DependentAttribute In Form.Properties_DependentAdditionalAttributesDescription Do
				If DependentAttribute.AttributeNameValue = Row.AttributeNameValue
					And DependentAttribute.RequiredFillingCondition <> Undefined Then
					
					Parameters = New Structure;
					Parameters.Insert("ParameterValues", DependentAttribute.RequiredFillingCondition.ParameterValues);
					Parameters.Insert("Form", Form);
					Parameters.Insert("ObjectDescription", ObjectDescription);
					Result = WorkInSafeMode.EvalInSafeMode(DependentAttribute.RequiredFillingCondition.ConditionCode, Parameters);
					
					Break;
				EndIf;
			EndDo;
			If Not Result Then
				Continue;
			EndIf;
			
			If Not ValueIsFilled(Form[Row.AttributeNameValue]) Then
				CommonUseClientServer.MessageToUser(
					StringFunctionsClientServer.SubstituteParametersInString(NStr("en='The ""%1"" field is not full.';ru='Поле ""%1"" не заполнено.';vi='Chưa điền trường  ""%1"".'"), Row.Description),
					,
					Row.AttributeNameValue,
					,
					Cancel);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Обновляет наборы дополнительных реквизитов и сведений для вида объектов со свойствами.
//  Используется при записи элементов справочников, которые являются видами объектов со свойствами.
//  Например, если есть справочник Номенклатура, к которому применяется подсистема Свойства, для него создан
// справочник ВидыНоменклатуры, то при записи элемента ВидНоменклатуры необходимо вызывать эту процедуру.
//
// Parameters:
//  ObjectKind                - Объект - например вид номенклатуры перед записью.
//  ObjectNameWithProperties    - String - например "Номенклатура".
//  PropertiesSetAttributeName - String - используется, когда наборов свойств несколько или
//                              используется имя реквизита основного набора, отличное от "НаборСвойств".
//
Procedure BeforeObjectKindWrite(ObjectKind,
                                  ObjectNameWithProperties,
                                  PropertiesSetAttributeName = "PropertySet") Export
	
	SetPrivilegedMode(True);
	
	PropertySet   = ObjectKind[PropertiesSetAttributeName];
	ParentOfSet = PropertySetByName(ObjectNameWithProperties);
	If ParentOfSet = Undefined Then
		ParentOfSet = Catalogs.AdditionalAttributesAndInformationSets[ObjectNameWithProperties];
	EndIf;
	
	If ValueIsFilled(PropertySet) Then
		
		OldSetProperties = CommonUse.ObjectAttributesValues(
			PropertySet, "Description, Parent, DeletionMark");
		
		If OldSetProperties.Description    = ObjectKind.Description
		   And OldSetProperties.DeletionMark = ObjectKind.DeletionMark
		   And OldSetProperties.Parent        = ParentOfSet Then
			
			Return;
		EndIf;
		
		If OldSetProperties.Parent = ParentOfSet Then
			Block = New DataLock;
			LockItem = Block.Add("Catalog.AdditionalAttributesAndInformationSets");
			LockItem.SetValue("Ref", PropertySet);
			Block.Lock();
			
			LockDataForEdit(PropertySet);
			PropertiesSetObject = PropertySet.GetObject();
		Else
			PropertiesSetObject = PropertySet.Copy();
		EndIf;
	Else
		PropertiesSetObject = Catalogs.AdditionalAttributesAndInformationSets.CreateItem();
		PropertiesSetObject.Used = True;
	EndIf;
	
	PropertiesSetObject.Description    = ObjectKind.Description;
	PropertiesSetObject.DeletionMark = ObjectKind.DeletionMark;
	PropertiesSetObject.Parent        = ParentOfSet;
	PropertiesSetObject.Write();
	
	ObjectKind[PropertiesSetAttributeName] = PropertiesSetObject.Ref;
	
EndProcedure

// Обновляет отображаемые данные на форме объекта со свойствами.
// 
// Parameters:
//  Form           - ClientApplicationForm - уже настроена в процедуре ПриСозданииНаСервере.
//
//  Object          - Undefined - взять объект из реквизита формы "Объект".
//                  - Объект - СправочникОбъект, ДокументОбъект, ... , ДанныеФормыСтруктура (по типу объекта).
//
//  HideDeleted - Undefined - не менять текущий режим скрытия удаленных, установленный ранее.
//                  - Boolean - установить/отключить режим скрытия удаленных.
//                    При вызове процедуры ПередЗаписьюНаСервере в режиме скрытия удаленных удаленные значения
//                    очищаются (не переносятся обратно в объект), а режим СкрытьУдаленные устанавливается Ложь.
//
Procedure UpdateAdditionalAttributesItems(Form, Object = Undefined, HideDeleted = Undefined) Export
	
	PropertiesManagementService.MoveValuesFromFormAttributesToObject(Form, Object);
	
	AdditionalAttributesInFormFill(Form, Object, , HideDeleted);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Процедуры и функции для нестандартной обработки дополнительных свойств.

// Возвращает ссылку на предопределенный набор свойств по имени набора.
// Предназначена для наборов, указанных в процедуре
// УправлениеСвойствамиПереопределяемый.ПриСозданииПредопределенныхНаборовСвойств.
//
// Parameters:
//  SetName - String - Имя получаемого набора свойств.
//
// Returns:
//  CatalogRef.AdditionalAttributesAndInformationSets - ссылка на набор свойств.
//  Неопределено - Если предопределенный набор не найден.
//
// Example:
//  Ссылка = УправлениеСвойствами.НаборСвойствПоИмени("Справочник_Пользователи");
//
Function PropertySetByName(SetName) Export
	PredefinedPropertySets = PropertiesManagementReUse.PredefinedPropertySets();
	Set = PredefinedPropertySets.Get(SetName);
	If Set = Undefined Then
		Return Undefined;
	Else
		Return Set.Ref;
	EndIf;
EndFunction

// Создает/пересоздает дополнительные реквизиты и элементы в форме владельца свойств.
//
// Parameters:
//  Form           - ClientApplicationForm - уже настроена в процедуре ПриСозданииНаСервере.
//
//  Object          - Undefined - взять объект из реквизита формы "Объект".
//                  - Объект - СправочникОбъект, ДокументОбъект, ..., ДанныеФормыСтруктура (по типу объекта).
//
//  InscriptionFields    - Boolean - если указать True, то вместо полей ввода на форме будут созданы поля надписей.
//
//  HideDeleted - Undefined - не менять текущий режим скрытия удаленных, установленный ранее.
//                  - Boolean - установить/отключить режим скрытия удаленных.
//                    При вызове процедуры ПередЗаписьюНаСервере в режиме скрытия удаленных, удаленные значения
//                    очищаются (не переносятся обратно в объект), а режим СкрытьУдаленные устанавливается Ложь.
//
Procedure AdditionalAttributesInFormFill(Form, Object = Undefined, InscriptionFields = False, HideDeleted = Undefined) Export
	
	If Not Form.Properties_UseProperties
	 Or Not Form.Properties_UseAdditionalAttributes Then
		Return;
	EndIf;
	
	If TypeOf(HideDeleted) = Type("Boolean") Then
		Form.Properties_HideDeleted = HideDeleted;
	EndIf;
	
	If Object = Undefined Then
		ObjectDescription = Form.Object;
	Else
		ObjectDescription = Object;
	EndIf;
	
	Form.Properties_AdditionalObjectAttributesSets = New ValueList;
	
	PurposeKey = Undefined;
	ObjectPropertiesSets = PropertiesManagementService.GetObjectPropertiesSets(
		ObjectDescription, PurposeKey);
	
	PropertiesManagementService.FillSetsWithAdditionalAttributes(
		ObjectPropertiesSets,
		Form.Properties_AdditionalObjectAttributesSets);
	
	UpdateFormPurposeKey(Form, PurposeKey);
	
	PropertiesDescription = PropertiesManagementService.PropertiesValues(
		ObjectDescription.AdditionalAttributes.Unload(),
		Form.Properties_AdditionalObjectAttributesSets,
		False);
	
	PropertiesDescription.Columns.Add("AttributeNameValue");
	PropertiesDescription.Columns.Add("ReferenceTypeRow");
	PropertiesDescription.Columns.Add("ReferenceAttributeNameValue");
	PropertiesDescription.Columns.Add("NameUniquePart");
	PropertiesDescription.Columns.Add("AdditionalValue");
	PropertiesDescription.Columns.Add("Boolean");
	
	DeleteOldAttributesAndItems(Form);
	
	// Создание реквизитов.
	AttributesToAdd = New Array();
	
	For Each PropertyDetails In PropertiesDescription Do
		
		PropertyValueType = PropertyDetails.ValueType;
		TypeList = PropertyValueType.Types();
		StringAttribute = (TypeList.Count() = 1) And (TypeList[0] = Type("String"));
		
		// Поддержка строк неограниченной длины.
		UseOpenEndedString = PropertiesManagementService.UseOpenEndedString(
			PropertyValueType, PropertyDetails.MultilineTextBox);
		
		If UseOpenEndedString Then
			PropertyValueType = New TypeDescription("String");
		ElsIf PropertyValueType.ContainsType(Type("String"))
			And PropertyValueType.StringQualifiers.Length = 0 Then
			// Если нельзя использовать неограниченную строку, а в свойствах реквизита она неограниченная,
			// то устанавливаем ограничение в 1024 символа.
			PropertyValueType = New TypeDescription(PropertyDetails.ValueType,
				,,, New StringQualifiers(1024));
		EndIf;
		
		PropertyDetails.NameUniquePart = 
			StrReplace(Upper(String(PropertyDetails.Set.UUID())), "-", "x")
			+ "_"
			+ StrReplace(Upper(String(PropertyDetails.Property.UUID())), "-", "x");
		
		PropertyDetails.AttributeNameValue =
			"AdditionalAttributeValue_" + PropertyDetails.NameUniquePart;
		
		PropertyDetails.ReferenceTypeRow = False;
		If StringAttribute
			And Not UseOpenEndedString
			And PropertyDetails.DisplayAsHyperlink Then
			FormattedString                           = New TypeDescription("FormattedString");
			PropertyDetails.ReferenceTypeRow           = True;
			PropertyDetails.ReferenceAttributeNameValue = "ReferenceAdditionalAttributeValue_" + PropertyDetails.NameUniquePart;
			
			Attribute = New FormAttribute(PropertyDetails.ReferenceAttributeNameValue, FormattedString, , PropertyDetails.Description, True);
			AttributesToAdd.Add(Attribute);
		EndIf;
		
		If PropertyDetails.Deleted Then
			PropertyValueType = New TypeDescription("String");
		EndIf;
		
		Attribute = New FormAttribute(PropertyDetails.AttributeNameValue, PropertyValueType, , PropertyDetails.Description, True);
		AttributesToAdd.Add(Attribute);
		
		PropertyDetails.AdditionalValue =
			PropertiesManagementService.ValueTypeContainsPropertiesValues(PropertyValueType);
		
		PropertyDetails.Boolean = CommonUse.TypeDescriptionFullConsistsOfType(PropertyValueType, Type("Boolean"));
	EndDo;
	Form.ChangeAttributes(AttributesToAdd);
	
	// Создание элементов формы.
	For Each PropertyDetails In PropertiesDescription Do
		
		ItemNameForPlacement = Form.Properties_ItemNameForPlacement;
		If TypeOf(ItemNameForPlacement) <> Type("ValueList") Then
			If ItemNameForPlacement = Undefined Then
				ItemNameForPlacement = "";
			EndIf;
			
			PlacingItem = ?(ItemNameForPlacement = "", Undefined, Form.Items[ItemNameForPlacement]);
		Else
			SectionsForPlacement = Form.Properties_ItemNameForPlacement;
			SetPlacement = SectionsForPlacement.FindByValue(PropertyDetails.Set);
			If SetPlacement = Undefined Then
				SetPlacement = SectionsForPlacement.FindByValue("AllOther");
			EndIf;
			PlacingItem = Form.Items[SetPlacement.Presentation];
		EndIf;
		
		FormPropertyDescription = Form.Properties_AdditionalAttributesDescription.Add();
		FillPropertyValues(FormPropertyDescription, PropertyDetails);
		
		// Заполнение таблицы зависимых дополнительных реквизитов.
		If PropertyDetails.AdditionalAttributeDependencies.Count() > 0
			And Not PropertyDetails.Deleted Then
			DependentAttributeDescription = Form.Properties_DependentAdditionalAttributesDescription.Add();
			FillPropertyValues(DependentAttributeDescription, PropertyDetails);
		EndIf;
		
		RowFilter = New Structure;
		RowFilter.Insert("PropertySet", PropertyDetails.Set);
		CurrentSetDependencies = PropertyDetails.AdditionalAttributeDependencies.FindRows(RowFilter);
		For Each TableRow In CurrentSetDependencies Do
			If TableRow.DependentProperty = "FillObligatory"
				And PropertyDetails.ValueType = New TypeDescription("Boolean") Then
				Continue;
			EndIf;
			If PropertyDetails.Deleted Then
				Continue;
			EndIf;
			
			If TypeOf(TableRow.Attribute) = Type("String") Then
				PathToAttribute = "Parameters.ObjectDescription." + TableRow.Attribute;
			Else
				AdditionalAttributeDescription = PropertiesDescription.Find(TableRow.Attribute, "Property");
				If AdditionalAttributeDescription = Undefined Then
					Continue; // Дополнительный реквизит не существует, условие игнорируется.
				EndIf;
				PathToAttribute = "Parameters.Form." + AdditionalAttributeDescription.AttributeNameValue;
			EndIf;
			
			PropertiesManagementService.BuildDependencyConditions(DependentAttributeDescription, PathToAttribute, TableRow);
		EndDo;
		
		If PropertyDetails.ReferenceTypeRow Then
			If ValueIsFilled(PropertyDetails.Value) Then
				Value = PropertyDetails.ValueType.AdjustValue(PropertyDetails.Value);
				RowValue = StringFunctionsClientServer.FormattedString(Value);
			Else
				Value = NStr("en='not set';ru='не задано';vi='chưa đặt'");
				EditLink = "NotDefined";
				RowValue = New FormattedString(Value,, StyleColors.EmptyHyperlinkColor,, EditLink);
			EndIf;
			Form[PropertyDetails.ReferenceAttributeNameValue] = RowValue;
		EndIf;
		Form[PropertyDetails.AttributeNameValue] = PropertyDetails.Value;
		
		If PropertyDetails.Deleted And Form.Properties_HideDeleted Then
			Continue;
		EndIf;
		
		If ObjectPropertiesSets.Count() > 1 Then
			
			ListElement = Form.Properties_AdditionalAttributesGroupsItems.FindByValue(
				PropertyDetails.Set);
			
			If ListElement <> Undefined Then
				Parent = Form.Items[ListElement.Presentation];
			Else
				DescriptionOfSet = ObjectPropertiesSets.Find(PropertyDetails.Set, "Set");
				
				If DescriptionOfSet = Undefined Then
					DescriptionOfSet = ObjectPropertiesSets.Add();
					DescriptionOfSet.Set     = PropertyDetails.Set;
					DescriptionOfSet.Title = NStr("en='Remote attribute';ru='Удаленные реквизиты';vi='Đã xóa chi tiết'")
				EndIf;
				
				If Not ValueIsFilled(DescriptionOfSet.Title) Then
					DescriptionOfSet.Title = String(PropertyDetails.Set);
				EndIf;
				
				ElementNameSet = "SetOfAdditionalAttributes" + PropertyDetails.NameUniquePart;
				
				Parent = Form.Items.Add(ElementNameSet, Type("FormGroup"), PlacingItem);
				
				Form.Properties_AdditionalAttributesGroupsItems.Add(
					PropertyDetails.Set, Parent.Name);
				
				If TypeOf(PlacingItem) = Type("FormGroup")
				   And PlacingItem.Type = FormGroupType.Pages Then
					
					Parent.Type = FormGroupType.Page;
				Else
					Parent.Type = FormGroupType.UsualGroup;
					Parent.Representation = UsualGroupRepresentation.None;
				EndIf;
				Parent.ShowTitle = False;
				Parent.Group = ChildFormItemsGroup.Vertical;
				
				FilledGroupProperties = New Structure;
				For Each Column In ObjectPropertiesSets.Columns Do
					If DescriptionOfSet[Column.Name] <> Undefined Then
						FilledGroupProperties.Insert(Column.Name, DescriptionOfSet[Column.Name]);
					EndIf;
				EndDo;
				FillPropertyValues(Parent, FilledGroupProperties);
			EndIf;
		Else
			Parent = PlacingItem;
		EndIf;
		
		If PropertyDetails.DisplayAsHyperlink Then
			HyperlinkGroupName = "Group_" + PropertyDetails.NameUniquePart;
			GroupHiperlinks = Form.Items.Add(HyperlinkGroupName, Type("FormGroup"), Parent);
			GroupHiperlinks.Type = FormGroupType.UsualGroup;
			GroupHiperlinks.Representation = UsualGroupRepresentation.None;
			GroupHiperlinks.ShowTitle = False;
			GroupHiperlinks.Group = ChildFormItemsGroup.AlwaysHorizontal;
			GroupHiperlinks.Title = PropertyDetails.Description;
			
			Item = Form.Items.Add(PropertyDetails.AttributeNameValue, Type("FormField"), GroupHiperlinks);
			
			AttributeAvailable = AttributeAvailableByFunctionalOptions(PropertyDetails);
			If AttributeAvailable And Not InscriptionFields Then
				ButtonName = "Button_" + PropertyDetails.NameUniquePart;
				Button = Form.Items.Add(
					ButtonName,
					Type("FormButton"),
					GroupHiperlinks);
					
				Button.OnlyInAllActions = True;
				Button.CommandName = "EditAttributeHyperlink";
				Button.ShapeRepresentation = ButtonShapeRepresentation.WhenActive;
			EndIf;
			
			If Not PropertyDetails.ReferenceTypeRow And ValueIsFilled(PropertyDetails.Value) Then
				Item.Hyperlink = True;
			EndIf;
		Else
			Item = Form.Items.Add(PropertyDetails.AttributeNameValue, Type("FormField"), Parent);
		EndIf;
		
		FormPropertyDescription.FormItemAdded = True;
		
		If PropertyDetails.Boolean And IsBlankString(PropertyDetails.FormatProperties) Then
			Item.Type = FormFieldType.CheckBoxField;
			Item.TitleLocation = FormItemTitleLocation.Right;
		Else
			If InscriptionFields Then
				Item.Type = FormFieldType.InputField;
			ElsIf PropertyDetails.DisplayAsHyperlink
				And (PropertyDetails.ReferenceTypeRow
					Or ValueIsFilled(PropertyDetails.Value))Then
				Item.Type = FormFieldType.LabelField;
			Else
				Item.Type = FormFieldType.InputField;
				Item.AutoMarkIncomplete = PropertyDetails.FillObligatory And Not PropertyDetails.Deleted;
			EndIf;
			
			Item.VerticalStretch = False;
			Item.TitleLocation     = FormItemTitleLocation.Left;
		EndIf;
		
		If PropertyDetails.ReferenceTypeRow Then
			Item.DataPath = PropertyDetails.ReferenceAttributeNameValue;
			Item.SetAction("URLProcessing", "Attachable_PropertiesRunCommand");
		Else
			Item.DataPath = PropertyDetails.AttributeNameValue;
		EndIf;
		Item.ToolTip   = PropertyDetails.ToolTip;
		Item.SetAction("OnChange", "Attachable_AdditionalAttributeOnChange");
		
		If Item.Type = FormFieldType.InputField
		   And Not UseOpenEndedString
		   And PropertyDetails.ValueType.Types().Find(Type("String")) <> Undefined Then
			
			Item.TypeLink = New TypeLink("Properties_AdditionalAttributesDescription.Property",
				PropertiesDescription.IndexOf(PropertyDetails));
		EndIf;
		
		If PropertyDetails.MultilineTextBox > 0 Then
			If Not InscriptionFields Then
				Item.MultiLine = True;
			EndIf;
			Item.Height = PropertyDetails.MultilineTextBox;
		EndIf;
		
		If Not IsBlankString(PropertyDetails.FormatProperties)
			And Not PropertyDetails.DisplayAsHyperlink Then
			If InscriptionFields Then
				Item.Format = PropertyDetails.FormatProperties;
			Else
				FormatString = "";
				Array = StrSplit(PropertyDetails.FormatProperties, ";", False);
				
				For Each SubString In Array Do
					If StrFind(SubString, "DP=") > 0 Or StrFind(SubString, "DE=") > 0 Then
						Continue;
					EndIf;
					If StrFind(SubString, "NZ=") > 0 Or StrFind(SubString, "NZ=") > 0 Then
						Continue;
					EndIf;
					If StrFind(SubString, "DF=") > 0 Or StrFind(SubString, "DF=") > 0 Then
						If StrFind(SubString, "ddd") > 0 Or StrFind(SubString, "ddd") > 0 Then
							SubString = StrReplace(SubString, "ddd", "dd");
							SubString = StrReplace(SubString, "ddd", "dd");
						EndIf;
						If StrFind(SubString, "dddd") > 0 Or StrFind(SubString, "dddd") > 0 Then
							SubString = StrReplace(SubString, "dddd", "dd");
							SubString = StrReplace(SubString, "dddd", "dd");
						EndIf;
						If StrFind(SubString, "MMM") > 0 Or StrFind(SubString, "MMM") > 0 Then
							SubString = StrReplace(SubString, "MMM", "mm");
							SubString = StrReplace(SubString, "MMM", "MM");
						EndIf;
						If StrFind(SubString, "MMMM") > 0 Or StrFind(SubString, "MMMM") > 0 Then
							SubString = StrReplace(SubString, "MMMM", "mm");
							SubString = StrReplace(SubString, "MMMM", "MM");
						EndIf;
					EndIf;
					If StrFind(SubString, "DLF=") > 0 Or StrFind(SubString, "DLF=") > 0 Then
						If StrFind(SubString, "dd") > 0 Or StrFind(SubString, "DD") > 0 Then
							SubString = StrReplace(SubString, "dd", "D");
							SubString = StrReplace(SubString, "DD", "D");
						EndIf;
					EndIf;
					FormatString = FormatString + ?(FormatString = "", "", ";") + SubString;
				EndDo;
				
				Item.Format = FormatString;
				Item.EditFormat = FormatString;
			EndIf;
		EndIf;
		
		If PropertyDetails.Deleted Then
			Item.TitleTextColor = StyleColors.UnavailableCellTextColor;
			Item.TitleFont = StyleFonts.DeletedAdditionalAttributeFont;
			If Item.Type = FormFieldType.InputField Then
				Item.ClearButton = True;
				Item.ChoiceButton = False;
				Item.OpenButton = False;
				Item.DropListButton = False;
				Item.TextEdit = False;
			EndIf;
		EndIf;
		
		If Not InscriptionFields And PropertyDetails.AdditionalValue And Item.Type = FormFieldType.InputField Then
			ChoiceParameters = New Array;
			ChoiceParameters.Add(New ChoiceParameter("Filter.Owner",
				?(ValueIsFilled(PropertyDetails.AdditionalValuesOwner),
					PropertyDetails.AdditionalValuesOwner, PropertyDetails.Property)));
			Item.ChoiceParameters = New FixedArray(ChoiceParameters);
		EndIf;
		
	EndDo;
	
	// Установка видимости, доступности и обязательности заполнения дополнительных реквизитов.
	For Each DependentAttributeDescription In Form.Properties_DependentAdditionalAttributesDescription Do
		If DependentAttributeDescription.DisplayAsHyperlink Then
			ProcessedItem = StrReplace(DependentAttributeDescription.AttributeNameValue, "AdditionalAttributeValue_", "Group_");
		Else
			ProcessedItem = DependentAttributeDescription.AttributeNameValue;
		EndIf;
		
		If DependentAttributeDescription.AccessibilityCondition <> Undefined Then
			Result = ConditionComputeResult(Form, ObjectDescription, DependentAttributeDescription.AccessibilityCondition);
			Item = Form.Items[ProcessedItem];
			If Item.Enabled <> Result Then
				Item.Enabled = Result;
			EndIf;
		EndIf;
		If DependentAttributeDescription.VisibilityCondition <> Undefined Then
			Result = ConditionComputeResult(Form, ObjectDescription, DependentAttributeDescription.VisibilityCondition);
			Item = Form.Items[ProcessedItem];
			If Item.Visible <> Result Then
				Item.Visible = Result;
			EndIf;
		EndIf;
		If DependentAttributeDescription.RequiredFillingCondition <> Undefined Then
			If Not DependentAttributeDescription.FillObligatory Then
				Continue;
			EndIf;
			
			Result = ConditionComputeResult(Form, ObjectDescription, DependentAttributeDescription.RequiredFillingCondition);
			Item = Form.Items[ProcessedItem];
			If Not DependentAttributeDescription.DisplayAsHyperlink
				And Item.AutoMarkIncomplete <> Result Then
				Item.AutoMarkIncomplete = Result;
			EndIf;
		EndIf;
	EndDo;
	
	Structure = New Structure("ProperyParameters");
	FillPropertyValues(Structure, Form);
	If TypeOf(Structure.ProperyParameters) = Type("Structure")
		And Structure.ProperyParameters.Property("ExecutedDeferredInitialization") Then
		Form.ProperyParameters.ExecutedDeferredInitialization = True;
		// Удаление временной декорации, если она была добавлена.
		If Form.ProperyParameters.Property("EmptyDecorationIsAdded") Then
			For Each NameDecoration In Form.ProperyParameters.DecorationCollection Do
				Form.Items.Delete(Form.Items[NameDecoration]);
			EndDo;
			Form.ProperyParameters.Delete("EmptyDecorationIsAdded");
		EndIf;
	EndIf;
	
EndProcedure

// Переносит значения свойств из реквизитов формы в табличную часть объекта.
// 
// Parameters:
//  Form        - ClientApplicationForm - уже настроена в процедуре ПриСозданииНаСервере.
//  Object       - Undefined - взять объект из реквизита формы "Объект".
//               - Объект - СправочникОбъект, ДокументОбъект, ..., ДанныеФормыСтруктура (по типу объекта).
//
Procedure MoveValuesFromFormAttributesToObject(Form, Object = Undefined) Export
	
	PropertiesManagementService.MoveValuesFromFormAttributesToObject(Form, Object);
	
EndProcedure

// Удаляет старые реквизиты и элементы формы.
// 
// Parameters:
//  Form        - ClientApplicationForm - уже настроена в процедуре ПриСозданииНаСервере.
//  
Procedure DeleteOldAttributesAndItems(Form) Export
	
	AttributesToBeRemoved = New Array;
	For Each PropertyDetails In Form.Properties_AdditionalAttributesDescription Do
		UniquePart = StrReplace(PropertyDetails.AttributeNameValue, "AdditionalAttributeValue_", "");
		
		AttributesToBeRemoved.Add(PropertyDetails.AttributeNameValue);
		If PropertyDetails.ReferenceTypeRow Then
			AttributesToBeRemoved.Add("ReferenceAdditionalAttributeValue_" + UniquePart);
		EndIf;
		If PropertyDetails.FormItemAdded Then
			If PropertyDetails.DisplayAsHyperlink Then
				Form.Items.Delete(Form.Items["Group_" + UniquePart]);
			Else
				Form.Items.Delete(Form.Items[PropertyDetails.AttributeNameValue]);
			EndIf;
		EndIf;
	EndDo;
	
	If AttributesToBeRemoved.Count() > 0 Then
		Form.ChangeAttributes(, AttributesToBeRemoved);
	EndIf;
	
	For Each ListElement In Form.Properties_AdditionalAttributesGroupsItems Do
		Form.Items.Delete(Form.Items[ListElement.Presentation]);
	EndDo;
	
	Form.Properties_AdditionalAttributesDescription.Clear();
	Form.Properties_AdditionalAttributesGroupsItems.Clear();
	Form.Properties_DependentAdditionalAttributesDescription.Clear();
	
EndProcedure

// Возвращает дополнительные реквизиты и сведения у указанного объекта.
//
// Parameters:
//  PropertiesOwner      - Ссылка - например: СправочникСсылка.Номенклатура, ДокументСсылка.ЗаказПокупателя, ...
//                       - Объект - например: СправочникОбъект.Номенклатура, ДокументОбъект.ЗаказПокупателя, ...
//                       - FormDataStructure - коллекция по типу объекта владельца свойств.
//  GetAdditAttributes - Boolean - в результат включать дополнительные реквизиты.
//  GetAdditInfo  - Boolean - в результат включать дополнительные сведения.
//
// Returns:
//  Array - значения
//    * ПланВидовХарактеристикСсылка.ДополнительныеРеквизитыИСведения - если есть.
//
Function PropertiesOfObject(PropertiesOwner, GetAdditAttributes = True, GetAdditInfo = True) Export
	
	If Not (GetAdditAttributes Or GetAdditInfo) Then
		Return New Array;
	EndIf;
	
	GetAdditInfo = GetAdditInfo And AccessRight("Read", Metadata.InformationRegisters.AdditionalInformation);
	
	SetPrivilegedMode(True);
	ObjectPropertiesSets = PropertiesManagementService.GetObjectPropertiesSets(
		PropertiesOwner);
	SetPrivilegedMode(False);
	
	ObjectPropertiesSetsArray = ObjectPropertiesSets.UnloadColumn("Set");
	
	QueryTextAdditAttributes = 
		"SELECT
		|	PropertyTable.Property AS Property
		|FROM
		|	Catalog.AdditionalAttributesAndInformationSets.AdditionalAttributes AS PropertyTable
		|WHERE
		|	PropertyTable.Ref IN (&ObjectPropertiesSetsArray)";
	
	QueryTextAdditInfo = 
		"SELECT ALLOWED
		|	PropertyTable.Property AS Property
		|FROM
		|	Catalog.AdditionalAttributesAndInformationSets.AdditionalInformation AS PropertyTable
		|WHERE
		|	PropertyTable.Ref IN (&ObjectPropertiesSetsArray)";
	
	Query = New Query;
	
	If GetAdditAttributes And GetAdditInfo Then
		
		Query.Text = QueryTextAdditInfo + "
		|
		| UNION ALL
		|" + QueryTextAdditAttributes;
		
	ElsIf GetAdditAttributes Then
		Query.Text = QueryTextAdditAttributes;
		
	ElsIf GetAdditInfo Then
		Query.Text = QueryTextAdditInfo;
	EndIf;
	
	Query.Parameters.Insert("ObjectPropertiesSetsArray", ObjectPropertiesSetsArray);
	
	Result = Query.Execute().Unload().UnloadColumn("Property");
	
	Return Result;
	
EndFunction

// Возвращает значения дополнительных свойств объектов.
//
// Parameters:
//  ObjectsWithProperties  - Array      - объекты, для которых нужно получить значения дополнительных свойств.
//                       - AnyRef - ссылка на объект, например, СправочникСсылка.Номенклатура,
//                                       ДокументСсылка.ЗаказПокупателя, ...
//  GetAdditAttributes - Boolean - в результат включать дополнительные реквизиты. По умолчанию True.
//  GetAdditInfo  - Boolean - в результат включать дополнительные сведения. По умолчанию True.
//  Properties             - Array - properties:
//                          * ChartOfCharacteristicTypesRef.AdditionalAttributesAndInformation - значения
//                            которых следует получить.
//                          * Row - уникальное имя дополнительного свойства.
//                       - Undefined - по умолчанию, получить значения всех свойств владельца.
//
// Returns:
//  ValueTable - колонки:
//    * Property - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInformation - свойство владельца.
//    * Value - Arbitrary - значения любого типа из описания типов свойства объекта метаданных:
//                  "Метаданные.ПланВидовХарактеристик.ДополнительныеРеквизитыИСведения.Тип".
//    * PropertiesOwner - AnyRef - ссылка на объект.
//
Function PropertiesValues(ObjectsWithProperties,
                        GetAdditAttributes = True,
                        GetAdditInfo = True,
                        Properties = Undefined) Export
	
	GetAdditInfo = GetAdditInfo And AccessRight("Read", Metadata.InformationRegisters.AdditionalInformation);
	
	If TypeOf(ObjectsWithProperties) = Type("Array") Then
		PropertiesOwner = ObjectsWithProperties[0];
	Else
		PropertiesOwner = ObjectsWithProperties;
	EndIf;
	
	If Properties = Undefined Then
		Properties = PropertiesOfObject(PropertiesOwner, GetAdditAttributes, GetAdditInfo);
	EndIf;
	
	ObjectNameWithProperties = CommonUse.TableNameByRef(PropertiesOwner);
	
	QueryTextAdditAttributes =
		"SELECT [ALLOWED]
		|	PropertyTable.Property AS Property,
		|	PropertyTable.Value AS Value,
		|	PropertyTable.TextString,
		|	PropertyTable.Ref AS PropertiesOwner
		|FROM
		|	[ObjectNameWithProperties].AdditionalAttributes AS PropertyTable
		|		LEFT JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInformation AS AdditionalAttributesAndInformation
		|		ON AdditionalAttributesAndInformation.Ref = PropertyTable.Property
		|WHERE
		|	PropertyTable.Ref IN (&ObjectsWithProperties)
		|	AND (AdditionalAttributesAndInformation.Ref IN (&Properties)
		|		OR AdditionalAttributesAndInformation.Name IN (&Properties))";
	
	QueryTextAdditInfo =
		"SELECT [ALLOWED]
		|	PropertyTable.Property AS Property,
		|	PropertyTable.Value AS Value,
		|	"""" AS TextString,
		|	PropertyTable.Object AS PropertiesOwner
		|FROM
		|	InformationRegister.AdditionalInformation AS PropertyTable
		|		LEFT JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInformation AS AdditionalAttributesAndInformation
		|		ON AdditionalAttributesAndInformation.Ref = PropertyTable.Property
		|WHERE
		|	PropertyTable.Object IN (&ObjectsWithProperties)
		|	AND (AdditionalAttributesAndInformation.Ref IN (&Properties)
		|		OR AdditionalAttributesAndInformation.Name IN (&Properties))";
	
	Query = New Query;
	
	If GetAdditAttributes And GetAdditInfo Then
		QueryText = StrReplace(QueryTextAdditAttributes, "[ALLOWED]", "ALLOWED") + "
			|
			| UNION ALL
			|" + StrReplace(QueryTextAdditInfo, "[ALLOWED]", "");
		
	ElsIf GetAdditAttributes Then
		QueryText = StrReplace(QueryTextAdditAttributes, "[ALLOWED]", "ALLOWED");
		
	ElsIf GetAdditInfo Then
		QueryText = StrReplace(QueryTextAdditInfo, "[ALLOWED]", "ALLOWED");
	EndIf;
	
	QueryText = StrReplace(QueryText, "[ObjectNameWithProperties]", ObjectNameWithProperties);
	
	Query.Parameters.Insert("ObjectsWithProperties", ObjectsWithProperties);
	Query.Parameters.Insert("Properties", Properties);
	Query.Text = QueryText;
	
	Result = Query.Execute().Unload();
	ResultWithTextStrings = Undefined;
	RowIndex = 0;
	For Each PropertyValue In Result Do
		TextString = PropertyValue.TextString;
		If Not IsBlankString(TextString) Then
			If ResultWithTextStrings = Undefined Then
				ResultWithTextStrings = Result.Copy(,"Property, PropertiesOwner");
				ResultWithTextStrings.Columns.Add("Value");
				ResultWithTextStrings.LoadColumn(Result.UnloadColumn("Value"), "Value");
			EndIf;
			ResultWithTextStrings[RowIndex].Value = TextString;
		EndIf;
		RowIndex = RowIndex + 1;
	EndDo;
	
	Return ?(ResultWithTextStrings <> Undefined, ResultWithTextStrings, Result);
EndFunction

// Возвращает значение дополнительного свойства объекта.
//
// Parameters:
//  Object   - AnyRef - ссылка на объект, например, СправочникСсылка.Номенклатура,
//                           ДокументСсылка.ЗаказПокупателя, ...
//  Property - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInformation - ссылка на
//                           дополнительный реквизит, значение которого нужно получить.
//           - String - Имя дополнительного свойства.
//
// Returns:
//  Arbitrary - любое значение, допустимое для свойства.
//
Function PropertyValue(Object, Property) Export
	GetAttributes = PropertiesManagementService.IsMetadataObjectWithAdditionalDetails(Object.Metadata());
	
	Result = PropertiesValues(Object, GetAttributes, True, Property);
	If Result.Count() = 1 Then
		Return Result[0].Value;
	EndIf;
EndFunction

// Проверяет, есть ли у объекта свойство.
//
// Parameters:
//  PropertiesOwner - Ссылка - например: СправочникСсылка.Номенклатура, ДокументСсылка.ЗаказПокупателя, ...
//  Property        - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInformation - проверяемое свойство.
//
// Returns:
//  Boolean - если True, свойство у владельца есть.
//
Function CheckObjectProperty(PropertiesOwner, Property) Export
	
	PropertyArray = PropertiesOfObject(PropertiesOwner);
	
	If PropertyArray.Find(Property) = Undefined Then
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction

// Записывает дополнительные реквизиты и сведения владельцу свойств.
// Изменения происходят в транзакции.
// 
// Parameters:
//  PropertiesOwner - Ссылка - например, СправочникСсылка.Номенклатура, ДокументСсылка.ЗаказПокупателя и т.д.
//  PropertiesAndValuesTable - ValueTable - с колонками:
//    * Property - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInformation - свойство владельца.
//    * Value - Arbitrary - любое значение, допустимое для свойства (указано в элементе свойства).
//
Procedure WriteObjectProperties(PropertiesOwner, PropertiesAndValuesTable) Export
	
	AdditAttributesTable = New ValueTable;
	AdditAttributesTable.Columns.Add("Property", New TypeDescription("ChartOfCharacteristicTypesRef.AdditionalAttributesAndInformation"));
	AdditAttributesTable.Columns.Add("Value");
	AdditAttributesTable.Columns.Add("TextString");
	
	AdditInfoTable = AdditAttributesTable.CopyColumns();
	
	For Each PropertiesTableRow In PropertiesAndValuesTable Do
		If PropertiesTableRow.Property.ThisIsAdditionalInformation Then
			NewRow = AdditInfoTable.Add();
		Else
			NewRow = AdditAttributesTable.Add();
			
			If TypeOf(PropertiesTableRow.Value) = Type("String")
				And StrLen(PropertiesTableRow.Value) > 1024 Then
				NewRow.TextString = PropertiesTableRow.Value;
			EndIf;
		EndIf;
		FillPropertyValues(NewRow, PropertiesTableRow, "Property,Value");
	EndDo;
	
	AreAdditAttributes = AdditAttributesTable.Count() > 0;
	IsAdditInfo  = AdditInfoTable.Count() > 0;
	
	PropertyArray = PropertiesOfObject(PropertiesOwner);
	
	AdditAttributesArray = New Array;
	ArrayAddInformation = New Array;
	
	For Each AdditionalProperty In PropertyArray Do
		If AdditionalProperty.ThisIsAdditionalInformation Then
			ArrayAddInformation.Add(AdditionalProperty);
		Else
			AdditAttributesArray.Add(AdditionalProperty);
		EndIf;
	EndDo;
	
	BeginTransaction();
	Try
		If AreAdditAttributes Then
			Block = New DataLock;
			LockItem = Block.Add(PropertiesOwner.Metadata().FullName());
			LockItem.SetValue("Ref", PropertiesOwner);
			Block.Lock();
			
			OwnerOfObjectProperties = PropertiesOwner.GetObject();
			LockDataForEdit(OwnerOfObjectProperties.Ref);
			
			For Each AdditionalAttribute In AdditAttributesTable Do
				If AdditAttributesArray.Find(AdditionalAttribute.Property) = Undefined Then
					Continue;
				EndIf;
				RowArray = OwnerOfObjectProperties.AdditionalAttributes.FindRows(New Structure("Property", AdditionalAttribute.Property));
				If RowArray.Count() Then
					PropertyString = RowArray[0];
				Else
					PropertyString = OwnerOfObjectProperties.AdditionalAttributes.Add();
				EndIf;
				FillPropertyValues(PropertyString, AdditionalAttribute, "Property,Value,TextString");
			EndDo;
			OwnerOfObjectProperties.Write();
		EndIf;
		
		If IsAdditInfo Then
			For Each AdditInfo In AdditInfoTable Do
				If ArrayAddInformation.Find(AdditInfo.Property) = Undefined Then
					Continue;
				EndIf;
				
				Block = New DataLock;
				LockItem = Block.Add("InformationRegister.AdditionalInformation");
				LockItem.SetValue("Object", PropertiesOwner);
				LockItem.SetValue("Property", AdditInfo.Property);
				Block.Lock();
				
				RecordManager = InformationRegisters.AdditionalInformation.CreateRecordManager();
				
				RecordManager.Object = PropertiesOwner;
				RecordManager.Property = AdditInfo.Property;
				RecordManager.Value = AdditInfo.Value;
				
				RecordManager.Write(True);
			EndDo;
			
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Проверяет, используются ли дополнительные реквизиты с объектом.
//
// Parameters:
//  PropertiesOwner - Ссылка - например, СправочникСсылка.Номенклатура, ДокументСсылка.ЗаказПокупателя, ...
//
// Returns:
//  Boolean - если True, тогда дополнительные реквизиты используются.
//
Function UseAdditAttributes(PropertiesOwner) Export
	
	OwnerMetadata = PropertiesOwner.Metadata();
	Return OwnerMetadata.TabularSections.Find("AdditionalAttributes") <> Undefined
	      And OwnerMetadata <> Metadata.Catalogs.AdditionalAttributesAndInformationSets;
	
EndFunction

// Проверяет, используются ли дополнительные сведения объектом.
//
// Parameters:
//  PropertiesOwner - Ссылка - например, СправочникСсылка.Номенклатура, ДокументСсылка.ЗаказПокупателя, ...
//
// Returns:
//  Boolean - если True, тогда дополнительные сведения используются.
//
Function UseAdditInfo(PropertiesOwner) Export
	
	Return Metadata.FindByFullName("CommonCommand.AdditionalInformationCommandBar") <> Undefined
		And Metadata.CommonCommands.AdditionalInformationCommandBar.CommandParameterType.Types().Find(TypeOf(PropertiesOwner)) <> Undefined;
	
EndFunction

// Проверяет доступность подсистемы для текущего пользователя.
//
// Returns:
//  Boolean - True, если подсистема доступна.
//
Function PropertiesAvailable() Export
	Return AccessRight("Read", Metadata.Catalogs.AdditionalAttributesAndInformationSets);
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Обновление информационной базы.

// 1. Обновляет наименования предопределенных наборов свойств,
// если они отличаются от текущих представлений соответствующих
// им объектов метаданных со свойствами.
// 2. Обновляет наименования не общих свойств, если у них
// уточнение отличается от наименования их набора.
// 3. Устанавливает пометку удаления у необщих свойств,
// если установлена пометка удаления их наборов.
//
Procedure UpdateSetsAndPropertiesNames() Export
	
	QuerySets = New Query;
	QuerySets.Text =
	"SELECT
	|	TheSets.Ref AS Ref,
	|	TheSets.Description AS Description
	|FROM
	|	Catalog.AdditionalAttributesAndInformationSets AS TheSets
	|WHERE
	|	TheSets.Predefined
	|	AND TheSets.Parent = VALUE(Catalog.AdditionalAttributesAndInformationSets.EmptyRef)";
	
	SelectionSets = QuerySets.Execute().Select();
	While SelectionSets.Next() Do
		
		Description = PropertiesManagementService.DescriptionPredefinedSet(
			SelectionSets.Ref);
		
		If SelectionSets.Description <> Description Then
			Object = SelectionSets.Ref.GetObject();
			Object.Description = Description;
			InfobaseUpdate.WriteData(Object);
		EndIf;
	EndDo;
	
	QueryProperties = New Query;
	QueryProperties.Text =
	"SELECT
	|	Properties.Ref AS Ref
	|FROM
	|	ChartOfCharacteristicTypes.AdditionalAttributesAndInformation AS Properties
	|WHERE
	|	CASE
	|			WHEN Properties.PropertySet = VALUE(Catalog.AdditionalAttributesAndInformationSets.EmptyRef)
	|				THEN FALSE
	|			ELSE CASE
	|					WHEN Properties.Description <> Properties.Title
	|						THEN TRUE
	|					ELSE FALSE
	|				END
	|		END";
	
	PropertySelection = QueryProperties.Execute().Select();
	While PropertySelection.Next() Do
		
		Object = PropertySelection.Ref.GetObject();
		Object.Description = Object.Title + " (" + String(PropertySelection.NameOfSet) + ")";
		Object.DeletionMark = PropertySelection.DeletionMarkSet;
		InfobaseUpdate.WriteData(Object);
	EndDo;
	
EndProcedure

// Устанавливает параметры набора свойств.
//
// Parameters:
//  PropertySetName - String - имя предопределенного набора свойств.
//  Parameters - Structure - See описание функции СтруктураПараметровНабораСвойств.
//
Procedure SetPropertySetParameters(PropertySetName, Parameters = Undefined) Export
	
	If Parameters = Undefined Then
		Parameters = PropertySetParametersStructure();
	EndIf;
	
	WriteObject = False;
	PropertySet = PropertySetByName(PropertySetName);
	If PropertySet = Undefined Then
		PropertySet = Catalogs.AdditionalAttributesAndInformationSets[PropertySetName];
	EndIf;
	PropertiesSetObject = PropertySet.GetObject();
	For Each Parameter In Parameters Do
		If PropertiesSetObject[Parameter.Key] = Parameter.Value Then
			Continue;
		EndIf;
		WriteObject = True;
	EndDo;
	
	If WriteObject Then
		FillPropertyValues(PropertiesSetObject, Parameters);
		InfobaseUpdate.WriteData(PropertiesSetObject);
	EndIf;
	
EndProcedure

// Получает структуру параметров для набора свойств.
//
// Returns: 
//  Structure - со свойствами:
//     * Used - Boolean - признак использования набора свойств.
//                               Устанавливается в Ложь, например, если
//                               объект отключен функциональной опцией.
//
Function PropertySetParametersStructure() Export
	
	Parameters = New Structure;
	Parameters.Insert("Used", True);
	Return Parameters;
	
EndFunction

#Region ObsoleteProceduresAndFunctions

// Устарела. Следует использовать ЗначенияСвойств или ЗначенияСвойства.
// Возвращает значения дополнительных свойств объекта.
//
// Parameters:
//  PropertiesOwner      - Ссылка - например, СправочникСсылка.Номенклатура, ДокументСсылка.ЗаказПокупателя, ...
//  GetAdditAttributes - Boolean - в результат включать дополнительные реквизиты.
//  GetAdditInfo  - Boolean - в результат включать дополнительные сведения.
//  PropertyArray        - Array - properties:
//                          * ChartOfCharacteristicTypesRef.AdditionalAttributesAndInformation - значения
//                            которых следует получить.
//                       - Undefined - получить значения всех свойств владельца.
// Returns:
//  ValueTable - колонки:
//    * Property - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInformation - свойство владельца.
//    * Value - Arbitrary - значения любого типа из описания типов свойства объекта метаданных:
//                  "Метаданные.ПланВидовХарактеристик.ДополнительныеРеквизитыИСведения.Тип".
//
Function GetValuesOfProperties(PropertiesOwner,
                                GetAdditAttributes = True,
                                GetAdditInfo = True,
                                PropertyArray = Undefined) Export
	
	Return PropertiesValues(PropertiesOwner, GetAdditAttributes, GetAdditInfo, PropertyArray);
	
EndFunction

// Устарела. Следует использовать СвойстваОбъекта.
// Возвращает свойства владельца.
//
// Parameters:
//  PropertiesOwner      - Ссылка - например, СправочникСсылка.Номенклатура, ДокументСсылка.ЗаказПокупателя, ...
//  GetAdditAttributes - Boolean - в результат включать дополнительные реквизиты.
//  GetAdditInfo  - Boolean - в результат включать дополнительные сведения.
//
// Returns:
//  Array - значения
//    * ПланВидовХарактеристикСсылка.ДополнительныеРеквизитыИСведения - если есть.
//
Function GetListOfProperties(PropertiesOwner, GetAdditAttributes = True, GetAdditInfo = True) Export
	Return PropertiesOfObject(PropertiesOwner, GetAdditAttributes, GetAdditInfo);
EndFunction

// Возвращает перечисляемые значения указанного свойства.
//
// Parameters:
//  Property - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInformation - свойство для
//             которого нужно получить перечисляемые значения.
// 
// Returns:
//  Array - значения:
//    * CatalogRef.ObjectsPropertiesValues, СправочникСсылка.ЗначенияСвойствОбъектовИерархия - значения
//      свойства, если есть.
//
Function GetListOfValuesOfProperties(Property) Export
	
	Return PropertiesManagementService.PropertyAdditionalValues(Property);
	
EndFunction

#EndRegion

#EndRegion

#Region InternalProceduresAndFunctions

////////////////////////////////////////////////////////////////////////////////
// Вспомогательные процедуры и функции.

// Создает основные реквизиты, команды, элементы в форме владельца свойств.
Procedure CreateMainFormObjects(Form, Context, CreateAdditionalAttributesDescription)
	
	ItemNameForPlacement   = Context.ItemNameForPlacement;
	CommandBarItemName = Context.CommandBarItemName;
	DeferredInitialization    = Context.DeferredInitialization;
	
	Attributes = New Array;
	
	// Проверка значения функциональной опции "Использование свойств".
	OptionUseProperties = Form.GetFormFunctionalOption("UseAdditionalAttributesAndInformation");
	AttributeUseProperties = New FormAttribute("Properties_UseProperties", New TypeDescription("Boolean"));
	Attributes.Add(AttributeUseProperties);
	AttributeHideDeleted = New FormAttribute("Properties_HideDeleted", New TypeDescription("Boolean"));
	Attributes.Add(AttributeHideDeleted);
	// Дополнительные параметры подсистемы свойства.
	AttributePropertiesParameters = New FormAttribute("ProperyParameters", New TypeDescription());
	Attributes.Add(AttributePropertiesParameters);
	
	If OptionUseProperties Then
		
		AttributeUseAdditAttributes = New FormAttribute("Properties_UseAdditionalAttributes", New TypeDescription("Boolean"));
		Attributes.Add(AttributeUseAdditAttributes);
		
		If CreateAdditionalAttributesDescription Then
			
			// Добавление реквизита содержащего используемые наборы дополнительных реквизитов.
			Attributes.Add(New FormAttribute(
				"Properties_AdditionalObjectAttributesSets", New TypeDescription("ValueList")));
			
			// Добавление реквизита описания создаваемых реквизитов и элементов формы.
			DescriptionName = "Properties_AdditionalAttributesDescription";
			
			Attributes.Add(New FormAttribute(
				DescriptionName, New TypeDescription("ValueTable")));
			
			Attributes.Add(New FormAttribute(
				"AttributeNameValue", New TypeDescription("String"), DescriptionName));
			
			Attributes.Add(New FormAttribute(
				"Property", New TypeDescription("ChartOfCharacteristicTypesRef.AdditionalAttributesAndInformation"),
					DescriptionName));
			
			Attributes.Add(New FormAttribute(
				"AdditionalValuesOwner", New TypeDescription("ChartOfCharacteristicTypesRef.AdditionalAttributesAndInformation"),
					DescriptionName));
			
			Attributes.Add(New FormAttribute(
				"ValueType", New TypeDescription("TypeDescription"), DescriptionName));
			
			Attributes.Add(New FormAttribute(
				"MultilineTextBox", New TypeDescription("Number"), DescriptionName));
			
			Attributes.Add(New FormAttribute(
				"Deleted", New TypeDescription("Boolean"), DescriptionName));
			
			Attributes.Add(New FormAttribute(
				"FillObligatory", New TypeDescription("Boolean"), DescriptionName));
			
			Attributes.Add(New FormAttribute(
				"Available", New TypeDescription("Boolean"), DescriptionName));
			
			Attributes.Add(New FormAttribute(
				"Visible", New TypeDescription("Boolean"), DescriptionName));
			
			Attributes.Add(New FormAttribute(
				"Description", New TypeDescription("String"), DescriptionName));
			
			Attributes.Add(New FormAttribute(
				"FormItemAdded", New TypeDescription("Boolean"), DescriptionName));
			
			Attributes.Add(New FormAttribute(
				"DisplayAsHyperlink", New TypeDescription("Boolean"), DescriptionName));
			
			Attributes.Add(New FormAttribute(
				"ReferenceTypeRow", New TypeDescription("Boolean"), DescriptionName));
			
			// Добавление реквизита описания зависимых реквизитов.
			DependentAttributeTable = "Properties_DependentAdditionalAttributesDescription";
			
			Attributes.Add(New FormAttribute(
				DependentAttributeTable, New TypeDescription("ValueTable")));
			
			Attributes.Add(New FormAttribute(
				"AttributeNameValue", New TypeDescription("String"), DependentAttributeTable));
			
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
			
			Attributes.Add(New FormAttribute(
				"DisplayAsHyperlink", New TypeDescription("Boolean"), DependentAttributeTable));
			
			// Добавление реквизита содержащего элементы создаваемых групп дополнительных реквизитов.
			Attributes.Add(New FormAttribute(
				"Properties_AdditionalAttributesGroupsItems", New TypeDescription("ValueList")));
			
			// Добавление реквизита с именем элемента в котором будут размещаться поля ввода.
			Attributes.Add(New FormAttribute(
				"Properties_ItemNameForPlacement", New TypeDescription()));
			
			// Добавление команды формы, если установлена роль "ДобавлениеИзменениеДополнительныхРеквизитовИСведений" или это
			// полноправный пользователь.
			If AccessRight("Update", Metadata.Catalogs.AdditionalAttributesAndInformationSets) Then
				// Добавление команды.
				Command = Form.Commands.Add("EditAdditionalAttributesContent");
				Command.Title = NStr("en='Change the composition of additional attribute';ru='Изменить состав дополнительных реквизитов';vi='Thay đổi thành phần mục tin bổ sung'");
				Command.Action = "Attachable_PropertiesRunCommand";
				Command.ToolTip = NStr("en='Change the composition of additional attribute';ru='Изменить состав дополнительных реквизитов';vi='Thay đổi thành phần mục tin bổ sung'");
				Command.Picture = PictureLib.ListSettings;
				
				Button = Form.Items.Add(
					"EditAdditionalAttributesContent",
					Type("FormButton"),
					?(CommandBarItemName = "",
						Form.CommandBar,
						Form.Items[CommandBarItemName]));
				
				Button.OnlyInAllActions = True;
				Button.CommandName = "EditAdditionalAttributesContent";
			EndIf;
			
			Command = Form.Commands.Add("EditAttributeHyperlink");
			Command.Title   = NStr("en='Start/finish editing';ru='Начать/закончить редактирование';vi='Bắt đầu / dừng chỉnh sửa'");
			Command.Action    = "Attachable_PropertiesRunCommand";
			Command.ToolTip   = NStr("en='Start/finish editing';ru='Начать/закончить редактирование';vi='Bắt đầu / dừng chỉnh sửa'");
			Command.Picture    = PictureLib.Change;
			Command.Representation = ButtonRepresentation.Picture;
		EndIf;
	EndIf;
	
	Form.ChangeAttributes(Attributes);
	
	Form.Properties_UseProperties = OptionUseProperties;
	
	Form.ProperyParameters = New Structure;
	If DeferredInitialization Then
		// Если свойства не используются, признак выполнения отложенной инициализации
		// взводится в истину.
		Value = ?(OptionUseProperties, False, True);
		Form.ProperyParameters.Insert("ExecutedDeferredInitialization", Value);
	EndIf;
	
	If OptionUseProperties Then
		Form.Properties_UseAdditionalAttributes = CreateAdditionalAttributesDescription;
	EndIf;
	
	If OptionUseProperties And CreateAdditionalAttributesDescription Then
		Form.Properties_ItemNameForPlacement = ItemNameForPlacement;
	EndIf;
	
	// Если дополнительные реквизиты расположены на отдельной странице, включена
	// отложенная инициализация и свойства включены, то в страницу размещается пустая декорация.
	// Декорация удаляется автоматически при переключении на закладку.
	// Также блокируется возможность перемещения дополнительных реквизитов из группы.
	If OptionUseProperties
		And DeferredInitialization
		And ItemNameForPlacement <> "" Then
		Form.ProperyParameters.Insert("DecorationCollection");
		Form.ProperyParameters.DecorationCollection = New Array;
		
		Form.ProperyParameters.Insert("EmptyDecorationIsAdded", True);
		If TypeOf(ItemNameForPlacement ) = Type("ValueList") Then
			IndexOf = 0;
			For Each PlacementGroup In ItemNameForPlacement Do
				PrepareFormForDeferredInitialization(Form, Context, PlacementGroup.Presentation, IndexOf);
				IndexOf = IndexOf + 1;
			EndDo;
		Else
			PrepareFormForDeferredInitialization(Form, Context, ItemNameForPlacement, "");
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure PrepareFormForDeferredInitialization(Form, Context, ItemNameForPlacement, IndexOf)
	
	FormGroup = Form.Items[ItemNameForPlacement];
	If FormGroup.Type <> FormGroupType.Page Then
		Parent = PageParent(FormGroup);
	Else
		Parent = FormGroup;
	EndIf;
	
	If Parent <> Undefined
		And Not Form.ProperyParameters.Property(Parent.Name) Then
		NameDecoration = "Properties_EmptyDecoration" + IndexOf;
		Form.ProperyParameters.DecorationCollection.Add(NameDecoration);
		Decoration = Form.Items.Add(NameDecoration, Type("FormDecoration"), FormGroup);
		
		PagesGroup = Parent.Parent;
		PageTitle = ?(ValueIsFilled(Parent.Title), Parent.Title, Parent.Name);
		PageGroupHeader = ?(ValueIsFilled(PagesGroup.Title), PagesGroup.Title, PagesGroup.Name);
		
		WarningOfPlacement = NStr("en='To display additional details, you don''t need to place the ""%1"" group in the ""%2"" group (menu More - Change form).';ru='Для отображения дополнительных реквизитов необходимо разместить группу ""%1"" не первым элементом (после любой другой группы) в группе ""%2"" (меню Еще - Изменить форму).';vi='Để hiển thị chi tiết bổ sung, phải đặt nhóm ""%1"" chứ không phải phần tử đầu tiên (sau bất kỳ nhóm nào khác) trong nhóm ""%2"" (menu Thêm - Thay đổi biểu mẫu).'");
		WarningOfPlacement = StringFunctionsClientServer.SubstituteParametersInString(WarningOfPlacement,
			PageTitle, PageGroupHeader);
		ToolTipText = NStr("en='You can also set standard form settings:"
"   • In the menu More choose the item Change shape...;"
"   • In the open form ""Form Setting"" in the menu More choose the item ""Set standard settings.""';ru='Также можно установить стандартные настройки формы:"
"   • в меню Еще выбрать пункт Изменить форму...;"
"   • в открывшейся форме ""Настройка формы"" в меню Еще выбрать пункт ""Установить стандартные настройки"".';vi='Có thể đặt cài đặt biểu mẫu tiêu chuẩn:"
"    • trong menu Thêm chọn mục Thay đổi biểu mẫu ...;"
"    • trong biểu mẫu đã mở ""Cài đặt biểu mẫu"" trong menu Thêm chọn mục ""Đặt cài đặt tiêu chuẩn"".'");
			
		Decoration.ToolTipRepresentation = ToolTipRepresentation.Button;
		Decoration.Title  = WarningOfPlacement;
		Decoration.ToolTip  = ToolTipText;
		Decoration.TextColor = StyleColors.ExplanationTextError;
		
		// Страница, на которой размещаются дополнительные реквизиты.
		Form.ProperyParameters.Insert(Parent.Name);
	EndIf;
	
	FormGroup.EnableContentChange = False;
	
EndProcedure

Function PageParent(FormGroup)
	
	Parent = FormGroup.Parent;
	If TypeOf(Parent) = Type("FormGroup") Then
		Parent.EnableContentChange = False;
		If Parent.Type = FormGroupType.Page Then
			Return Parent;
		Else
			PageParent(Parent);
		EndIf;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

Procedure UpdateFormPurposeKey(Form, PurposeKey)
	
	If PurposeKey = Undefined Then
		PurposeKey = PropertiesSetsKey(Form.Properties_AdditionalObjectAttributesSets);
	EndIf;
	
	If IsBlankString(PurposeKey) Then
		Return;
	EndIf;
	
	KeyBeginning = "PropertiesSetsKey";
	PropertiesSetsKey = KeyBeginning + Left(PurposeKey + "00000000000000000000000000000000", 32);
	
	NewKey = NewPurposeKey(Form.PurposeUseKey, KeyBeginning, PropertiesSetsKey);
	If NewKey = Undefined Then
		// Ключ уже дополнен.
		NewKey = Form.PurposeUseKey;
	EndIf;
	
	NewPositionKey = NewPurposeKey(Form.WindowOptionsKey, KeyBeginning, PropertiesSetsKey);
	If NewPositionKey = Undefined Then
		// Ключ уже дополнен.
		NewPositionKey = Form.WindowOptionsKey;
	EndIf;
	
	StandardSubsystemsServer.SetFormPurposeKey(Form, NewKey, NewPositionKey);
	
EndProcedure

Function ConditionComputeResult(Form, ObjectDescription, Parameters)
	ConditionParameters = New Structure;
	ConditionParameters.Insert("ParameterValues", Parameters.ParameterValues);
	ConditionParameters.Insert("Form", Form);
	ConditionParameters.Insert("ObjectDescription", ObjectDescription);
	
	Return WorkInSafeMode.EvalInSafeMode(Parameters.ConditionCode, ConditionParameters);
EndFunction

Function NewPurposeKey(CurrentKey, KeyBeginning, PropertiesSetsKey)
	
	Position = StrFind(CurrentKey, KeyBeginning);
	
	NewPurposeKey = Undefined;
	
	If Position = 0 Then
		NewPurposeKey = CurrentKey + PropertiesSetsKey;
	
	ElsIf StrFind(CurrentKey, PropertiesSetsKey) = 0 Then
		NewPurposeKey = Left(CurrentKey, Position - 1) + PropertiesSetsKey
			+ Mid(CurrentKey, Position + StrLen(KeyBeginning) + 32);
	EndIf;
	
	Return NewPurposeKey;
	
EndFunction

Function PropertiesSetsKey(TheSets)
	
	SetsIdentifiers = New ValueList;
	
	For Each ListElement In TheSets Do
		SetsIdentifiers.Add(String(ListElement.Value.UUID()));
	EndDo;
	
	SetsIdentifiers.SortByValue();
	IdentifiersRow = "";
	
	For Each ListElement In SetsIdentifiers Do
		IdentifiersRow = IdentifiersRow + StrReplace(ListElement.Value, "-", "");
	EndDo;
	
	Return CommonUse.StringChecksum(IdentifiersRow);
	
EndFunction

Function AttributeAvailableByFunctionalOptions(PropertyDetails)
	ObjectAvailable = True;
	For Each Type In PropertyDetails.ValueType.Types() Do
		MetadataObject = Metadata.FindByType(Type);
		If MetadataObject = Undefined Then
			Continue;
		EndIf;
		ObjectAvailable = CommonUse.MetadataObjectAvailableByFunctionalOptions(MetadataObject);
		If ObjectAvailable Then
			Break; // Если хоть один тип доступен, то реквизит не скрывается.
		EndIf;
	EndDo;
	
	Return ObjectAvailable;
EndFunction

Function PropertiesUsed(Form, AdditionalParameters)
	
	If Not AccessRight("Read", Metadata.Catalogs.AdditionalAttributesAndInformationSets) Then
		DisableAdditionalAttributesOnForm(Form, AdditionalParameters);
		Return False;
	EndIf;
	
	If AdditionalParameters <> Undefined
		And AdditionalParameters.Property("ArbitraryObject")
		And AdditionalParameters.ArbitraryObject Then
		Return True;
	EndIf;
	
	If AdditionalParameters <> Undefined
		And AdditionalParameters.Property("Object") Then
		ObjectDescription = AdditionalParameters.Object;
	Else
		ObjectDescription = Form.Object;
	EndIf;
	ObjectType = TypeOf(ObjectDescription.Ref);
	FullName = Metadata.FindByType(ObjectType).FullName();
	
	FormNameArray = StrSplit(FullName, ".");
	
	ItemName = FormNameArray[0] + "_" + FormNameArray[1];
	PropertySet = PropertySetByName(ItemName);
	If PropertySet = Undefined Then
		PropertySet = Catalogs.AdditionalAttributesAndInformationSets[ItemName];
	EndIf;
	
	PropertiesUsed = CommonUse.ObjectAttributeValue(PropertySet, "Used");
	
	If Not PropertiesUsed Then
		DisableAdditionalAttributesOnForm(Form, AdditionalParameters);
	EndIf;
	
	Return PropertiesUsed;
	
EndFunction

Procedure DisableAdditionalAttributesOnForm(Form, AdditionalParameters)
	
	AttributeArray = CommonUseClientServer.ValueInArray(
		New FormAttribute("Properties_UseProperties", New TypeDescription("Boolean")));
	PropertyParametersAdded = False;
	
	If TypeOf(AdditionalParameters) = Type("Structure") Then
		If AdditionalParameters.Property("ItemNameForPlacement") Then
			If TypeOf(AdditionalParameters.ItemNameForPlacement) = Type("ValueList") Then
				For Each ListElement In AdditionalParameters.ItemNameForPlacement Do
					Form.Items[ListElement.Presentation].Visible = False;
				EndDo;
			Else
				Form.Items[AdditionalParameters.ItemNameForPlacement].Visible = False;
			EndIf;
		EndIf;
		
		If AdditionalParameters.Property("DeferredInitialization") Then
			AttributePropertiesParameters = New FormAttribute("ProperyParameters", New TypeDescription());
			AttributeArray.Add(AttributePropertiesParameters);
			PropertyParametersAdded = True;
		EndIf;
	EndIf;
	
	Form.ChangeAttributes(AttributeArray);
	Form.Properties_UseProperties = False;
	If PropertyParametersAdded Then
		Form.ProperyParameters = New Structure;
		Form.ProperyParameters.Insert("ExecutedDeferredInitialization", True);
	EndIf;
	
EndProcedure

#EndRegion
