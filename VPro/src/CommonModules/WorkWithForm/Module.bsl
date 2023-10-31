
#Region ProgramInterface

// Условное оформление

Function AddDataCompositionFilterItemGroup(FilterItemGroup, GroupType) Export
	
	FilterGroup = FilterItemGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
	If TypeOf(GroupType)=Type("String") Then
		FilterGroup.GroupType = DataCompositionFilterItemsGroupType[GroupType];
	Else
		FilterGroup.GroupType = GroupType;
	EndIf; 
	Return FilterGroup;
	
EndFunction

Procedure AddDataCompositionFilterItem(FilterItemGroup, FieldDataPath, Value, ComparisonType = Undefined) Export
	
	If ComparisonType = Undefined Then
		ComparisonType = DataCompositionComparisonType.Equal;
	ElsIf TypeOf(ComparisonType)=Type("String") Then
		ComparisonType = DataCompositionComparisonType[ComparisonType];
	EndIf;
	
	Filter = FilterItemGroup.Items.Add(Type("DataCompositionFilterItem"));
	Filter.ComparisonType   = ComparisonType;
	Filter.Use  = True;
	Filter.LeftValue  = New DataCompositionField(FieldDataPath);
	Filter.RightValue = Value;
	
EndProcedure

Procedure AddConditionalAppearanceField(ConditionalAppearance, FieldDataPath) Export
	
	MadeOutField                = ConditionalAppearance.Fields.Items.Add();
	MadeOutField.Field           = New DataCompositionField(FieldDataPath);
	MadeOutField.Use  = True;
	
EndProcedure

Procedure AddConditionalAppearanceFields(ConditionalAppearance, DataCompositionFields) Export
	
	If TypeOf(DataCompositionFields)=Type("Array") Then
		FieldsArray = DataCompositionFields;
	ElsIf TypeOf(DataCompositionFields)=Type("String") Then
		FieldsArray = StringFunctionsClientServer.DecomposeStringIntoSubstringsArray(StrReplace(DataCompositionFields, Chars.LF, ""));
	Else
		Return;
	EndIf;
	
	For Each FieldName In FieldsArray Do
		AddConditionalAppearanceField(ConditionalAppearance, FieldName)
	EndDo; 
	
EndProcedure

Procedure AddConditionalAppearanceElement(ConditionalAppearance, ID, Value) Export
	
	Appearance = ConditionalAppearance.Appearance.Items.Find(ID);
	Appearance.Value      = Value;
	Appearance.Use = True;
	
EndProcedure

#EndRegion 

#Region InternalProceduresAndFunctions

#EndRegion 

 