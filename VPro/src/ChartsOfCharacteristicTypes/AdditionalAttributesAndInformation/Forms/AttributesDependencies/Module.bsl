
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	PropertyToConfigure = Parameters.PropertyToConfigure;
	
	PropertiesOfObject = CommonUse.ObjectAttributesValues(Parameters.AdditionalAttribute, "Title");
	
	Title = NStr("en='%1 of additional attribute ""%2""';ru='%1 дополнительного реквизита ""%2""';vi='%1 mục tin bổ sung ""%2""'");
	If PropertyToConfigure = "Available" Then
		PresentationProperties = NStr("en='Availability';ru='Доступность';vi='Tính khả dụng'");
	ElsIf PropertyToConfigure = "FillObligatory" Then
		PresentationProperties = NStr("en='Requred filling';ru='Обязательность заполнения';vi='Bắt buộc điền'");
	Else
		PresentationProperties = NStr("en='Visibility';ru='Видимость';vi='Phần hiện hình'");
	EndIf;
	Title = StrReplace(Title, "%1", PresentationProperties);
	Title = StrReplace(Title, "%2", PropertiesOfObject.Title);
	
	If Not ValueIsFilled(PropertiesOfObject.Title)  Then
		Title = StrReplace(Title, """", "");
	EndIf;
	
	PropertySet = Parameters.Set;
	
	If Not ValueIsFilled(PropertySet) Then
		ExeptionText = NStr("en='Visibility, accessibility and mandatory filling settings"
"is available only when you open an additional attribute"
"from the ""Additional Details"" list.';ru='Настройка видимости, доступности и обязательности заполнения"
"доступна только при открытии дополнительного реквизита"
"из списка ""Дополнительные реквизиты"".';vi='Chỉ được phép tùy chỉnh khả năng hiển thị, khả năng truy cập"
"và bắt buộc điền khi mở mục tin bổ sung"
"từ danh sách ""Mục tin bổ sung"".'");
		ExeptionText = StrReplace(ExeptionText, Chars.LF, " ");
		Raise ExeptionText;
	EndIf;
	
	Parent = CommonUse.ObjectAttributeValue(PropertySet, "Parent");
	If Not ValueIsFilled(Parent) Then
		Parent = PropertySet;
	EndIf;
	
	SetOfAdditionalAttributes = Parent.AdditionalAttributes;
	
	PredefinedPropertySets = PropertiesManagementReUse.PredefinedPropertySets();
	DescriptionOfSet = PredefinedPropertySets.Get(Parent);
	If DescriptionOfSet = Undefined Then
		PredefinedDataName = CommonUse.ObjectAttributeValue(Parent, "PredefinedDataName");
	Else
		PredefinedDataName = DescriptionOfSet.Name;
	EndIf;
	
	ReplacedCharacterPosition = StrFind(PredefinedDataName, "_");
	FullMetadataObjectName = Left(PredefinedDataName, ReplacedCharacterPosition - 1)
		                       + "."
		                       + Mid(PredefinedDataName, ReplacedCharacterPosition + 1);
	
	ObjectAttributes = AttributeListForFilter(FullMetadataObjectName, SetOfAdditionalAttributes);
	
	FilterRow = Undefined;
	AdditionalAttributeDependencies = Parameters.AttributeDependencies;
	For Each TabularSectionRow In AdditionalAttributeDependencies Do
		If TabularSectionRow.PropertySet <> PropertySet Then
			Continue;
		EndIf;
		If TabularSectionRow.DependentProperty = PropertyToConfigure Then
			ConditionParts = StrSplit(TabularSectionRow.Where, " ");
			NewCondition = "";
			If ConditionParts.Count() > 0 Then
				For Each ConditionPart In ConditionParts Do
					NewCondition = NewCondition + Upper(Left(ConditionPart, 1)) + Mid(ConditionPart, 2);
				EndDo;
			EndIf;
			
			If ValueIsFilled(NewCondition) Then
				TabularSectionRow.Where = NewCondition;
			EndIf;
			
			AttributeWithMultipleValue = (TabularSectionRow.Where = "InList")
				Or (TabularSectionRow.Where = "NotInList");
			
			If AttributeWithMultipleValue Then
				FilterParameters = New Structure;
				FilterParameters.Insert("Attribute", TabularSectionRow.Attribute);
				FilterParameters.Insert("Condition",  TabularSectionRow.Where);
				
				SearchResult = AttributeDependencies.FindRows(FilterParameters);
				If SearchResult.Count() = 0 Then
					FilterRow = AttributeDependencies.Add();
					FillPropertyValues(FilterRow, TabularSectionRow,, "Value");
					
					Values = New ValueList;
					Values.Add(TabularSectionRow.Value);
					FilterRow.Value = Values;
				Else
					FilterRow = SearchResult[0];
					FilterRow.Value.Add(TabularSectionRow.Value);
				EndIf;
			Else
				FilterRow = AttributeDependencies.Add();
				FillPropertyValues(FilterRow, TabularSectionRow);
			EndIf;
			
			AttributeFullName = ObjectAttributes.Find(FilterRow.Attribute, "Attribute");
			If AttributeFullName = Undefined Then
				Continue; // Object attribute is not found.
			EndIf;
			FilterRow.ChoiceMode   = AttributeFullName.ChoiceMode;
			FilterRow.Presentation = AttributeFullName.Presentation;
			FilterRow.ValueType   = AttributeFullName.ValueType;
			If AttributeWithMultipleValue Then
				FilterRow.Value.ValueType = AttributeFullName.ValueType;
			EndIf;
		EndIf;
	EndDo;
	
	If CommonUse.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Top;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Src)
	If EventName = "Properties_ObjectAttributeSelect" Then
		CurrentRow = AttributeDependencies.FindByID(Items.AttributeDependencies.CurrentRow);
		FilterParameters = New Structure;
		FilterParameters.Insert("Attribute", Parameter.Attribute);
		FoundStrings = AttributeDependencies.FindRows(FilterParameters);
		If FoundStrings.Count() > 0 Then
			Items.AttributeDependencies.CurrentRow = FoundStrings[0].GetID();
			AttributeDependencies.Delete(CurrentRow);
			Return;
		EndIf;
		FillPropertyValues(CurrentRow, Parameter);
		CurrentRow.PropertySet = PropertySet;
		AttributeDependenciesSetValueTypeRestriction();
		CurrentRow.DependentProperty = PropertyToConfigure;
		CurrentRow.Condition  = "Equal";
		CurrentRow.Value = CurrentRow.ValueType.AdjustValue(Undefined);
	EndIf;
EndProcedure

#EndRegion

#Region HeaderFormItemsEventsHandlers

&AtClient
Procedure AttributesDependenciesAttributeStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	OpenAttributeChoiceForm();
EndProcedure

&AtClient
Procedure AttributeDependenciesBeforeRowChange(Item, Cancel)
	AttributeDependenciesSetValueTypeRestriction();
EndProcedure

&AtClient
Procedure AttributesDependenciesComparisonKindOnChange(Item)
	AttributeDependenciesSetValueTypeRestriction();
	
	FormTable = Items.AttributeDependencies;
	CurrentRow = AttributeDependencies.FindByID(FormTable.CurrentRow);
	CurrentRow.Value = Undefined;
	
	If FormTable.CurrentData.Condition = "InList"
		Or FormTable.CurrentData.Condition = "NotInList" Then
		CurrentRow.Value = New ValueList;
		CurrentRow.Value.ValueType = FormTable.CurrentData.ValueType;
	Else
		CurrentRow.Value = Undefined;
	EndIf;
EndProcedure

&AtClient
Procedure AttributeDependenciesBeforeAddRow(Item, Cancel, Copy, Parent, Group, Parameter)
	If Not RowAdding Then
		Cancel = True;
	Else
		OpenAttributeChoiceForm();
		RowAdding = False;
	EndIf;
EndProcedure

&AtClient
Procedure OpenAttributeChoiceForm()
	FormParameters = New Structure;
	FormParameters.Insert("ObjectAttributes", ObjectAttributesInStorage);
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInformation.Form.AttributeChoice", FormParameters);
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure AddCondition(Command)
	RowAdding = True;
	Items.AttributeDependencies.AddRow();
EndProcedure

&AtClient
Procedure CommandOK(Command)
	Result = New Structure;
	Result.Insert(PropertyToConfigure, FilterSettingsInValueStorage());
	Notify("Properties_AttributeDependencySet", Result);
	Close();
EndProcedure

&AtClient
Procedure CommandCancel(Command)
	Close();
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Function FilterSettingsInValueStorage()
	
	If AttributeDependencies.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	DependenciesTable = FormAttributeToValue("AttributeDependencies");
	TableCopy = DependenciesTable.Copy();
	TableCopy.Columns.Delete("Presentation");
	TableCopy.Columns.Delete("ValueType");
	
	FilterParameter = New Structure;
	FilterParameter.Insert("Condition", "InList");
	ConvertDependenciesInList(TableCopy, FilterParameter);
	FilterParameter.Condition = "NotInList";
	ConvertDependenciesInList(TableCopy, FilterParameter);
	
	Return New ValueStorage(TableCopy);
	
EndFunction

&AtServer
Procedure ConvertDependenciesInList(Table, Filter)
	FoundStrings = Table.FindRows(Filter);
	For Each Row In FoundStrings Do
		For Each Item In Row.Value Do
			NewRow = Table.Add();
			FillPropertyValues(NewRow, Row);
			NewRow.Value = Item.Value;
		EndDo;
		Table.Delete(Row);
	EndDo;
EndProcedure

&AtServer
Function AttributeListForFilter(FullMetadataObjectName, SetOfAdditionalAttributes)
	
	ObjectAttributes = New ValueTable;
	ObjectAttributes.Columns.Add("Attribute");
	ObjectAttributes.Columns.Add("Presentation", New TypeDescription("String"));
	ObjectAttributes.Columns.Add("ValueType", New TypeDescription);
	ObjectAttributes.Columns.Add("PictureNumber", New TypeDescription("Number"));
	ObjectAttributes.Columns.Add("ChoiceMode", New TypeDescription("FoldersAndItemsUse"));
	
	MetadataObject = Metadata.FindByFullName(FullMetadataObjectName);
	
	For Each AdditionalAttribute In SetOfAdditionalAttributes Do
		PropertiesOfObject = CommonUse.ObjectAttributesValues(AdditionalAttribute.Property, "Description, ValueType");
		RowAttribute = ObjectAttributes.Add();
		RowAttribute.Attribute = AdditionalAttribute.Property;
		RowAttribute.Presentation = PropertiesOfObject.Description;
		RowAttribute.PictureNumber  = 2;
		RowAttribute.ValueType = PropertiesOfObject.ValueType;
	EndDo;
	
	For Each Attribute In MetadataObject.StandardAttributes Do
		AddAttributeToTable(ObjectAttributes, Attribute, True);
	EndDo;
	
	For Each Attribute In MetadataObject.Attributes Do
		AddAttributeToTable(ObjectAttributes, Attribute, False);
	EndDo;
	
	ObjectAttributes.Sort("Presentation Asc");
	
	ObjectAttributesInStorage = PutToTempStorage(ObjectAttributes, UUID);
	
	Return ObjectAttributes;
	
EndFunction

&AtServer
Procedure AddAttributeToTable(ObjectAttributes, Attribute, Standard)
	RowAttribute = ObjectAttributes.Add();
	RowAttribute.Attribute = Attribute.Name;
	RowAttribute.Presentation = Attribute.Presentation();
	RowAttribute.PictureNumber  = 1;
	RowAttribute.ValueType = Attribute.Type;
	If Standard Then
		RowAttribute.ChoiceMode = ?(Attribute.Name = "Parent", FoldersAndItemsUse.Folders, Undefined);
	Else
		RowAttribute.ChoiceMode = Attribute.ChoiceFoldersAndItems;
	EndIf;
EndProcedure

&AtClient
Procedure AttributeDependenciesSetValueTypeRestriction()
	
	FormTable = Items.AttributeDependencies;
	InputField    = Items.AttributeDependenciesRightValue;
	
	ChoiceParametersArray = New Array;
	If TypeOf(FormTable.CurrentData.Attribute) <> Type("String") Then
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.Owner", FormTable.CurrentData.Attribute));
	EndIf;
	
	ChoiceMode = FormTable.CurrentData.ChoiceMode;
	If ChoiceMode = FoldersAndItemsUse.Folders Then
		InputField.ChoiceFoldersAndItems = FoldersAndItems.Folders;
	ElsIf ChoiceMode = FoldersAndItemsUse.Items Then
		InputField.ChoiceFoldersAndItems = FoldersAndItems.Items;
	ElsIf ChoiceMode = FoldersAndItemsUse.FoldersAndItems Then
		InputField.ChoiceFoldersAndItems = FoldersAndItems.FoldersAndItems;
	EndIf;
	
	InputField.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	If FormTable.CurrentData.Condition = "InList"
		Or FormTable.CurrentData.Condition = "NotInList" Then
		InputField.TypeRestriction = New TypeDescription("ValueList");
	Else
		InputField.TypeRestriction = FormTable.CurrentData.ValueType;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemEnabled = ConditionalAppearanceItem.Appearance.Items.Find("Enabled");
	ItemEnabled.Value = False;
	ItemEnabled.Use = True;
	
	ComparisionValues = New ValueList;
	ComparisionValues.Add("Filled");
	ComparisionValues.Add("NotFilled"); // exclusion, it is identifier.
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("AttributeDependencies.Condition");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.InList;
	DataFilterItem.RightValue = ComparisionValues;
	DataFilterItem.Use  = True;
	
	ItemProcessedFields = ConditionalAppearanceItem.Fields.Items.Add();
	ItemProcessedFields.Field = New DataCompositionField("AttributeDependenciesRightValue");
	ItemProcessedFields.Use = True;
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AttributesDependenciesComparisonKind.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("AttributeDependencies.Condition");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "NotEqual";
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("en='Not equal';ru='Не равно';vi='Không bằng'"));
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AttributesDependenciesComparisonKind.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("AttributeDependencies.Condition");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "Equal";
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("en='Equal';ru='Равно';vi='Bằng'"));
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AttributesDependenciesComparisonKind.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("AttributeDependencies.Condition");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "NotFilled";
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("en='Not filled';ru='Не заполнено';vi='Chưa điền'"));
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AttributesDependenciesComparisonKind.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("AttributeDependencies.Condition");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "Filled";
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("en='Filled';ru='Заполнено';vi='Đã điền'"));
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AttributesDependenciesComparisonKind.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("AttributeDependencies.Condition");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "InList";
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("en='In list';ru='В списке';vi='Trong danh sách'"));
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AttributesDependenciesComparisonKind.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("AttributeDependencies.Condition");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "NotInList";
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("en='Not in list';ru='Не в списке';vi='Không trong danh sách'"));
	
EndProcedure

#EndRegion
