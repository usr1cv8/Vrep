// Copies items from one collection to another
//
// Parameters:
//	ReceiverValues	- коллекция элементов КД, куда копируются параметры
//	ValueSource	- коллекция элементов КД, откуда копируются параметры
//	ClearReceiver		- признак необходимости очистки приемника (Булево, по умолчанию: истина)
//
Procedure CopyItems(ReceiverValues, ValueSource, ClearReceiver = True) Export
	
	If TypeOf(ValueSource) = Type("DataCompositionConditionalAppearance")
		Or TypeOf(ValueSource) = Type("DataCompositionUserFieldsCaseVariants")
		Or TypeOf(ValueSource) = Type("DataCompositionAppearanceFields")
		Or TypeOf(ValueSource) = Type("DataCompositionDataParameterValues") Then
		CreateByType = False;
	Else
		CreateByType = True;
	EndIf;
	ReceiverElements = ReceiverValues.Items;
	SourceElements = ValueSource.Items;
	If ClearReceiver Then
		ReceiverElements.Clear();
	EndIf;
	
	For Each ItemSource In SourceElements Do
		
		If TypeOf(ItemSource) = Type("DataCompositionOrderItem") Then
			// Элементы порядка добавляем в начало
			IndexOf = SourceElements.IndexOf(ItemSource);
			ItemReceiver = ReceiverElements.Insert(IndexOf, TypeOf(ItemSource));
		Else
			If CreateByType Then
				ItemReceiver = ReceiverElements.Add(TypeOf(ItemSource));
			Else
				ItemReceiver = ReceiverElements.Add();
			EndIf;
		EndIf;
		
		FillPropertyValues(ItemReceiver, ItemSource);
		// В некоторых коллекциях необходимо заполнить другие коллекции
		If TypeOf(SourceElements) = Type("DataCompositionConditionalAppearanceItemCollection") Then
			CopyItems(ItemReceiver.Fields, ItemSource.Fields);
			CopyItems(ItemReceiver.Filter, ItemSource.Filter);
			FillItems(ItemReceiver.Appearance, ItemSource.Appearance); 
		ElsIf TypeOf(SourceElements)	= Type("DataCompositionUserFieldCaseVariantCollection") Then
			CopyItems(ItemReceiver.Filter, ItemSource.Filter);
		EndIf;
		
		// В некоторых элементах коллекции необходимо заполнить другие коллекции
		If TypeOf(ItemSource) = Type("DataCompositionFilterItemGroup") Then
			CopyItems(ItemReceiver, ItemSource);
		ElsIf TypeOf(ItemSource) = Type("DataCompositionSelectedFieldGroup") Then
			CopyItems(ItemReceiver, ItemSource);
		ElsIf TypeOf(ItemSource) = Type("DataCompositionUserFieldCase") Then
			CopyItems(ItemReceiver.Variants, ItemSource.Variants);
		ElsIf TypeOf(ItemSource) = Type("DataCompositionUserFieldExpression") Then
			ItemReceiver.SetDetailRecordExpression (ItemSource.GetDetailRecordExpression());
			ItemReceiver.SetTotalRecordExpression(ItemSource.GetTotalRecordExpression());
			ItemReceiver.SetDetailRecordExpressionPresentation(ItemSource.GetDetailRecordExpressionPresentation ());
			ItemReceiver.SetTotalRecordExpressionPresentation(ItemSource.GetTotalRecordExpressionPresentation ());
		EndIf;
		
	EndDo;
	
EndProcedure

// Заполняет одну коллекцию элементов на основании другой
//
// Parameters:
//	ReceiverValues	- коллекция элементов КД, куда копируются параметры
//	ValueSource	- коллекция элементов КД, откуда копируются параметры
//	FirstLevel		- уровень структуры коллекции элементов КД для копирования параметров
//
Procedure FillItems(ReceiverValues, ValueSource, FirstLevel = Undefined) Export
	
	If TypeOf(ReceiverValues) = Type("DataCompositionParameterValueCollection") Then
		CollectionValues = ValueSource;
	Else
		CollectionValues = ValueSource.Items;
	EndIf;
	
	For Each ItemSource In CollectionValues Do
		If FirstLevel = Undefined Then
			ItemReceiver = ReceiverValues.FindParameterValue(ItemSource.Parameter);
		Else
			ItemReceiver = FirstLevel.FindParameterValue(ItemSource.Parameter);
		EndIf;
		If ItemReceiver = Undefined Then
			Continue;
		EndIf;
		FillPropertyValues(ItemReceiver, ItemSource);
		If TypeOf(ItemSource) = Type("DataCompositionParameterValue") Then
			If ItemSource.NestedParameterValues.Count() <> 0 Then
				FillItems(ItemReceiver.NestedParameterValues, ItemSource.NestedParameterValues, ReceiverValues);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Добавляет в коллекцию оформляемых полей компоновки данных новое поле
//
// Parameters:
//	FormattedFieldsCollection 	- коллекция оформляемых полей КД
//	FieldName						- String - имя поля
//
// Returns:
//	DataCompositionAppearanceField - созданное поле
//
// Example:
// 	Form.ConditionalAppearance.Items[0].Fields
//
Function AddAppearanceField(FormattedFieldsCollection, FieldName) Export
	
	ItemField 		= FormattedFieldsCollection.Items.Add();
	ItemField.Field 	= New DataCompositionField(FieldName);

	Return ItemField;
	
EndFunction

// Добавляет в коллекцию отбора новую группу указанного типа.
//
// Parameters:
//	FilterItemsCollection - DataCompositionFilterItemCollection 
//	GroupType - DataCompositionFilterItemGroup - ГруппаИ или ГруппаИли
//
// Returns:
//	DataCompositionFilterItemGroup - добавленная группа
//
Function AddFilterGroup(FilterItemsCollection, GroupType) Export

	FilterItemGroup			 = FilterItemsCollection.Add(Type("DataCompositionFilterItemGroup"));
	FilterItemGroup.GroupType  = GroupType;
	
	Return FilterItemGroup;

EndFunction
