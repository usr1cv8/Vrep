////////////////////////////////////////////////////////////////////////////////
// Work methods with the DLS from the report form (server).
//
////////////////////////////////////////////////////////////////////////////////

#Region ServiceProceduresAndFunctions

////////////////////////////////////////////////////////////////////////////////
// Analysis

Function ExtendedInformationAboutSettings(DCSettingsComposer, Form, OutputConditions = Undefined) Export
	If Form = Undefined Then
		ReportSettings = ReportsClientServer.GetReportSettingsByDefault();
	Else
		ReportSettings = Form.ReportSettings;
	EndIf;
	
	DCSettings = DCSettingsComposer.Settings;
	DCUserSettings = DCSettingsComposer.UserSettings;
	
	AdditionalItemsSettings = CommonUseClientServer.StructureProperty(DCUserSettings.AdditionalProperties, "FormItems");
	If AdditionalItemsSettings = Undefined Then
		AdditionalItemsSettings = New Map;
	EndIf;
	
	Information = New Structure;
	Information.Insert("OnlyCustom", False);
	Information.Insert("OnlyQuick", False);
	Information.Insert("CurrentCDHostIdentifier", Undefined);
	If OutputConditions <> Undefined Then
		FillPropertyValues(Information, OutputConditions);
	EndIf;
	
	Information.Insert("DCSettings", DCSettings);
	
	Information.Insert("ReportSettings",           ReportSettings);
	Information.Insert("VariantTree",            VariantTree());
	Information.Insert("VariantSettings",         VariantSettingsTable());
	Information.Insert("UserSettings", UserSettingsTable());
	
	Information.Insert("DisabledLinks", New Array);
	Information.Insert("Links", New Structure);
	Information.Links.Insert("ByType",             TypeRelationsTable());
	Information.Links.Insert("ParametersSelect",   LinksTableOfSelectionParameters());
	Information.Links.Insert("MetadataObjects", LinkTableMetadataObjects(ReportSettings));
	
	Information.Insert("AdditionalItemsSettings",   AdditionalItemsSettings);
	Information.Insert("MapMetadataObjectName", New Map);
	Information.Insert("Search", New Structure);
	Information.Search.Insert("VariantSettingsByKDField", New Map);
	Information.Search.Insert("UserSettings", New Map);
	Information.Insert("ThereAreQuickSettings", False);
	Information.Insert("ThereAreCommonSettings", False);
	
	For Each DCUsersSetting IN DCUserSettings.Items Do
		SettingProperty = Information.UserSettings.Add();
		SettingProperty.DCUsersSetting = DCUsersSetting;
		SettingProperty.ID               = DCUsersSetting.UserSettingID;
		SettingProperty.IndexInCollection = DCUserSettings.Items.IndexOf(DCUsersSetting);
		SettingProperty.DCIdentifier  = DCUserSettings.GetIDByObject(DCUsersSetting);
		SettingProperty.Type              = ReportsClientServer.RowSettingType(TypeOf(DCUsersSetting));
		Information.Search.UserSettings.Insert(SettingProperty.ID, SettingProperty);
	EndDo;
	
	TreeRow = TreeVariantRegisterNode(Information, DCSettings, DCSettings, Information.VariantTree.Rows);
	TreeRow.Global = True;
	Information.Insert("VariantTreeRootRow", TreeRow);
	If Information.CurrentCDHostIdentifier = Undefined Then
		Information.CurrentCDHostIdentifier = TreeRow.DCIdentifier;
		If Not Information.OnlyCustom Then
			TreeRow.OutputAllowed = True;
		EndIf;
	EndIf;
	
	RegisterVariantSettings(DCSettings, Information);
	
	RegisterLinksFromLeading(Information);
	
	Return Information;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Variant tree

Function VariantTree()
	Result = New ValueTree;
	
	// DLS nodes.
	Result.Columns.Add("KDNode");
	Result.Columns.Add("DCUsersSetting");
	
	// Applied structure.
	Result.Columns.Add("UserSetting");
	
	// Search this setting in node.
	Result.Columns.Add("DCIdentifier");
	
	// Link to DLS nodes.
	Result.Columns.Add("ID", New TypeDescription("String"));
	
	// Setting description.
	Result.Columns.Add("Type", New TypeDescription("String"));
	Result.Columns.Add("Subtype", New TypeDescription("String"));
	
	Result.Columns.Add("HasStructure", New TypeDescription("Boolean"));
	Result.Columns.Add("HasFieldsAndDesign", New TypeDescription("Boolean"));
	Result.Columns.Add("Global", New TypeDescription("Boolean"));
	
	// Output.
	Result.Columns.Add("Presentation", New TypeDescription("String"));
	Result.Columns.Add("Title", New TypeDescription("String"));
	Result.Columns.Add("OutputAllowed", New TypeDescription("Boolean"));
	Result.Columns.Add("DisplayOnlyCheckBox", New TypeDescription("Boolean"));
	
	Return Result;
EndFunction

Function TreeVariantRegisterNode(Information, DCSettings, KDNode, TreeRowSet, Subtype = "")
	TreeRow = TreeRowSet.Add();
	TreeRow.KDNode = KDNode;
	TreeRow.Type = ReportsClientServer.RowSettingType(TypeOf(KDNode));
	TreeRow.Subtype = Subtype;
	If TreeRow.Type <> "Settings" Then
		TreeRow.ID = KDNode.UserSettingID;
	EndIf;
	
	TreeRow.DCIdentifier = DCSettings.GetIDByObject(KDNode);
	
	If TreeRow.Type = "Settings" Then
		TreeRow.HasStructure = True;
		TreeRow.HasFieldsAndDesign = True;
	ElsIf TreeRow.Type = "Group"
		Or TreeRow.Type = "ChartGrouping"
		Or TreeRow.Type = "TableGrouping" Then
		TreeRow.HasStructure = True;
		TreeRow.HasFieldsAndDesign = True;
	ElsIf TreeRow.Type = "Table" Then
		TreeRow.HasFieldsAndDesign = True;
	ElsIf TreeRow.Type = "Chart" Then
		TreeRow.HasFieldsAndDesign = True;
	ElsIf TreeRow.Type = "StructureTableItemsCollection"
		Or TreeRow.Type = "ChartStructureItemsCollection"
		Or TreeRow.Type = "NestedObjectSettings" Then
		// see next.
	Else
		Return TreeRow;
	EndIf;
	
	FillSettingPresentation(TreeRow, False);
	
	If TreeRow.HasFieldsAndDesign Then
		TreeRow.Title = TitlesFromOutputParameters(KDNode.OutputParameters);
	EndIf;
	
	If Not Information.OnlyCustom Then
		TreeRow.OutputAllowed = (TreeRow.DCIdentifier = Information.CurrentCDHostIdentifier);
	EndIf;
	
	If TypeOf(TreeRow.ID) = Type("String") AND Not IsBlankString(TreeRow.ID) Then
		SettingProperty = Information.Search.UserSettings.Get(TreeRow.ID);
		If SettingProperty <> Undefined Then
			TreeRow.UserSetting   = SettingProperty;
			TreeRow.DCUsersSetting = SettingProperty.DCUsersSetting;
			RegisterCustomSetting(Information, SettingProperty, TreeRow, Undefined);
			If Information.OnlyCustom Then
				TreeRow.OutputAllowed = SettingProperty.OutputAllowed;
			EndIf;
		EndIf;
	EndIf;
	
	If TreeRow.HasStructure Then
		For Each NestedItem IN KDNode.Structure Do
			TreeVariantRegisterNode(Information, DCSettings, NestedItem, TreeRow.Rows);
		EndDo;
	EndIf;
	
	If TreeRow.Type = "Table" Then
		TreeVariantRegisterNode(Information, DCSettings, KDNode.Rows, TreeRow.Rows, "RowTable");
		TreeVariantRegisterNode(Information, DCSettings, KDNode.Columns, TreeRow.Rows, "ColumnTable");
	ElsIf TreeRow.Type = "Chart" Then
		TreeVariantRegisterNode(Information, DCSettings, KDNode.Points, TreeRow.Rows, "PointChart");
		TreeVariantRegisterNode(Information, DCSettings, KDNode.Series, TreeRow.Rows, "SeriesChart");
	ElsIf TreeRow.Type = "StructureTableItemsCollection"
		Or TreeRow.Type = "ChartStructureItemsCollection" Then
		For Each NestedItem IN KDNode Do
			TreeVariantRegisterNode(Information, DCSettings, NestedItem, TreeRow.Rows);
		EndDo;
	ElsIf TreeRow.Type = "NestedObjectSettings" Then
		TreeVariantRegisterNode(Information, DCSettings, KDNode.Settings, TreeRow.Rows);
	EndIf;
	
	Return TreeRow;
EndFunction

Function TitlesFromOutputParameters(OutputParameters)
	OutputKDTitle = OutputParameters.FindParameterValue(New DataCompositionParameter("TitleOutput"));
	If OutputKDTitle = Undefined Then
		Return "";
	EndIf;
	If OutputKDTitle.Use = True
		AND OutputKDTitle.Value = DataCompositionTextOutputType.DontOutput Then
		Return "";
	EndIf;
	// IN the Auto value it is considered that the title is displayed.
	// When the OutputTitle parameter is disabled, it is an equivalent to the Auto value.
	DCTitle = OutputParameters.FindParameterValue(New DataCompositionParameter("Title"));
	If DCTitle = Undefined Then
		Return "";
	EndIf;
	Return DCTitle.Value;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Variant settings

Function VariantSettingsTable()
	Result = New ValueTree;
	
	// DLS nodes.
	Result.Columns.Add("KDItem");
	Result.Columns.Add("AvailableKDSetting");
	Result.Columns.Add("DCUsersSetting");
	
	// Applied structure.
	Result.Columns.Add("TreeRow");
	Result.Columns.Add("UserSetting");
	Result.Columns.Add("Owner");
	Result.Columns.Add("Global", New TypeDescription("Boolean"));
	
	// Search this setting in node.
	Result.Columns.Add("CollectionName", New TypeDescription("String"));
	Result.Columns.Add("DCIdentifier");
	
	// Link to DLS nodes.
	Result.Columns.Add("ID", New TypeDescription("String"));
	Result.Columns.Add("ItemIdentificator", New TypeDescription("String"));
	
	// Setting description.
	Result.Columns.Add("Type", New TypeDescription("String"));
	Result.Columns.Add("Subtype", New TypeDescription("String"));
	
	Result.Columns.Add("DCField");
	Result.Columns.Add("Value");
	Result.Columns.Add("ComparisonType");
	Result.Columns.Add("EnterByList", New TypeDescription("Boolean"));
	Result.Columns.Add("TypeInformation");
	
	Result.Columns.Add("MarkedValues");
	Result.Columns.Add("ChoiceParameters");
	
	Result.Columns.Add("TypeLink");
	Result.Columns.Add("ChoiceParameterLinks");
	Result.Columns.Add("LinksByMetadata");
	Result.Columns.Add("TypeRestriction");
	
	// API
	Result.Columns.Add("TypeDescription");
	Result.Columns.Add("ValuesForSelection");
	Result.Columns.Add("SelectionValueQuery");
	Result.Columns.Add("LimitChoiceWithSpecifiedValues", New TypeDescription("Boolean"));
	
	// Output.
	Result.Columns.Add("Presentation", New TypeDescription("String"));
	Result.Columns.Add("OutputAllowed", New TypeDescription("Boolean"));
	Result.Columns.Add("DisplayCheckbox", New TypeDescription("Boolean"));
	Result.Columns.Add("ChoiceFoldersAndItems");
	
	Return Result;
EndFunction

Function UserSettingsTable()
	Result = New ValueTable;
	
	// DLS nodes.
	Result.Columns.Add("KDNode");
	Result.Columns.Add("KDVariantSetting");
	Result.Columns.Add("DCUsersSetting");
	Result.Columns.Add("AvailableKDSetting");
	
	// Applied structure.
	Result.Columns.Add("TreeRow");
	Result.Columns.Add("VariantSetting");
	
	// Search this setting in node.
	Result.Columns.Add("DCIdentifier");
	Result.Columns.Add("IndexInCollection", New TypeDescription("Number"));
	
	// Link to DLS nodes.
	Result.Columns.Add("ID", New TypeDescription("String"));
	Result.Columns.Add("ItemIdentificator", New TypeDescription("String"));
	
	// Setting description.
	Result.Columns.Add("Type", New TypeDescription("String"));
	Result.Columns.Add("Subtype", New TypeDescription("String"));
	
	Result.Columns.Add("DCField");
	Result.Columns.Add("Value");
	Result.Columns.Add("ComparisonType");
	Result.Columns.Add("EnterByList", New TypeDescription("Boolean"));
	Result.Columns.Add("TypeInformation");
	
	Result.Columns.Add("MarkedValues");
	Result.Columns.Add("ChoiceParameters");
	
	// API
	Result.Columns.Add("TypeDescription");
	Result.Columns.Add("ValuesForSelection");
	Result.Columns.Add("SelectionValueQuery");
	Result.Columns.Add("LimitChoiceWithSpecifiedValues", New TypeDescription("Boolean"));
	
	// Output.
	Result.Columns.Add("Presentation", New TypeDescription("String"));
	Result.Columns.Add("Quick", New TypeDescription("Boolean"));
	Result.Columns.Add("Ordinary", New TypeDescription("Boolean"));
	Result.Columns.Add("OutputAllowed", New TypeDescription("Boolean"));
	Result.Columns.Add("DisplayCheckbox", New TypeDescription("Boolean"));
	Result.Columns.Add("DisplayOnlyCheckBox", New TypeDescription("Boolean"));
	
	Result.Columns.Add("ItemsType", New TypeDescription("String"));
	Result.Columns.Add("ChoiceFoldersAndItems");
	
	// Additional properties.
	Result.Columns.Add("Additionally", New TypeDescription("Structure"));
	
	Return Result;
EndFunction

Function TypeRelationsTable()
	// Link from DLS.
	TypeRelationsTable = New ValueTable;
	TypeRelationsTable.Columns.Add("Leading");
	TypeRelationsTable.Columns.Add("LeadingFieldDC");
	TypeRelationsTable.Columns.Add("subordinated");
	TypeRelationsTable.Columns.Add("SubordinateNameParameter");
	
	Return TypeRelationsTable;
EndFunction

Function LinksTableOfSelectionParameters()
	LinksTableOfSelectionParameters = New ValueTable;
	LinksTableOfSelectionParameters.Columns.Add("Leading");
	LinksTableOfSelectionParameters.Columns.Add("LeadingFieldDC");
	LinksTableOfSelectionParameters.Columns.Add("subordinated");
	LinksTableOfSelectionParameters.Columns.Add("SubordinateNameParameter");
	LinksTableOfSelectionParameters.Columns.Add("Action");
	
	Return LinksTableOfSelectionParameters;
EndFunction

Function LinkTableMetadataObjects(ReportSettings)
	// Link from metadata.
	Result = New ValueTable;
	Result.Columns.Add("LeadingType",          New TypeDescription("Type"));
	Result.Columns.Add("SubordinatedType",      New TypeDescription("Type"));
	Result.Columns.Add("SubordinatedAttribute", New TypeDescription("String"));
	
	// Extension mechanisms.
	ReportsOverridable.SupplementMetadataObjectsLinks(Result); // Global links...
	If ReportSettings.Events.SupplementMetadataObjectsLinks Then // ... can override locally for report.
		ReportObject = ReportObject(ReportSettings);
		ReportObject.SupplementMetadataObjectsLinks(Result);
	EndIf;
	
	Result.Columns.Add("IsLeading",     New TypeDescription("Boolean"));
	Result.Columns.Add("AreSubordinates", New TypeDescription("Boolean"));
	Result.Columns.Add("Leading",     New TypeDescription("Array"));
	Result.Columns.Add("Subordinate", New TypeDescription("Array"));
	Result.Columns.Add("LeadingFullName",     New TypeDescription("String"));
	Result.Columns.Add("SubordinateFullName", New TypeDescription("String"));
	
	Return Result;
EndFunction

Procedure RegisterVariantSettings(DCSettings, Information)
	VariantTree = Information.VariantTree;
	VariantSettings = Information.VariantSettings;
	
	Found = VariantTree.Rows.FindRows(New Structure("HasStructure", True), True);
	For Each TreeRow IN Found Do
		
		// Settings,
		// property Filter Grouping,
		// property Filter TableGrouping Filter.
		// ChartGrouping, the Filter property.
		
		// Settings, Filter property.Items.
		// Grouping, Filter property.Items
		// TableGrouping, the Selection property.Items
		// ChartGrouping, the Selection property.Items.
		
		RegisterSettingsNode(DCSettings, Information, TreeRow, "Filter");
		
		// Settings, Order property.
		// Grouping,
		// the Order TableGrouping property, the Order property.
		// ChartGrouping, the Order property.
		
		RegisterSettingsNode(DCSettings, Information, TreeRow, "Order");
		
		// Settings, the Structure property.
		// Grouping, the Structure property.
		// TableGrouping, the Structure property.
		// ChartGrouping, the Structure property.
		
		RegisterSettingsNode(DCSettings, Information, TreeRow, "Structure");
		
	EndDo;
	
	Found = VariantTree.Rows.FindRows(New Structure("HasFieldsAndDesign", True), True);
	For Each TreeRow IN Found Do
		
		// Settings, the
		// Selection Table property,
		// the Selection Chart
		// property, the Selection
		// Chart property, the Selection Grouping property, the Selection ChartGrouping property, the Selection propert.
		// TableGrouping, the Selection property.
		
		RegisterSettingsNode(DCSettings, Information, TreeRow, "Selection");
		
		// Settings, the ConditionalDesign property.
		// Table, the ConditionalDesign property.
		// Chart, the ConditionalDesign property.
		// Grouping, the ConditionalDesign property.
		// ChartGrouping, the ConditionalDesign property.
		// TableGrouping, the ConditionalDesign property.
		
		// Settings, the ConditionalDesign property.Items.
		// Table, the ConditionalDesign property.Items.
		// Chart, the ConditionalDesign property.Items.
		// Grouping, the ConditionalDesign property.Items
		// ChartGrouping, the ConditionalDesign property.Items
		// TableGrouping, the ConditionalDesign property.Items.
		
		RegisterSettingsNode(DCSettings, Information, TreeRow, "ConditionalAppearance");
		
	EndDo;
	
	Found = VariantTree.Rows.FindRows(New Structure("Global", True), True);
	For Each TreeRow IN Found Do
		
		// Settings, the DataParameters property, the FindParameterValue() method.
		
		RegisterSettingsNode(DCSettings, Information, TreeRow, "DataParameters");
		
	EndDo;
	
EndProcedure

Procedure RegisterSettingsNode(DCSettings, Information, TreeRow, CollectionName, SetElements = Undefined, Parent = Undefined, Owner = Undefined)
	KDNode = TreeRow.KDNode[CollectionName];
	
	Owner = Information.VariantSettings.Rows.Add();
	Owner.TreeRow = TreeRow;
	If CollectionName <> "DataParameters" Then
		Owner.ID = KDNode.UserSettingID;
	EndIf;
	Owner.Type           = ReportsClientServer.RowSettingType(TypeOf(KDNode));
	Owner.CollectionName  = CollectionName;
	Owner.Global    = TreeRow.Global;
	Owner.KDItem     = KDNode;
	Owner.OutputAllowed = Not Information.OnlyCustom AND TreeRow.OutputAllowed;
	
	If TypeOf(Owner.ID) = Type("String") AND Not IsBlankString(Owner.ID) Then
		SettingProperty = Information.Search.UserSettings.Get(Owner.ID);
		If SettingProperty <> Undefined Then
			Owner.UserSetting = SettingProperty;
			RegisterCustomSetting(Information, SettingProperty, Undefined, Owner);
			If Information.OnlyCustom Then
				Owner.OutputAllowed = SettingProperty.OutputAllowed;
			EndIf;
		EndIf;
	EndIf;
	
	If CollectionName = "Filter"
		Or CollectionName = "DataParameters"
		Or CollectionName = "ConditionalAppearance" Then
		RegisterSubordinatedSettingsItems(Information, KDNode, KDNode.Items, Owner, Owner);
	EndIf;
EndProcedure

Procedure RegisterSubordinatedSettingsItems(Information, KDNode, SetElements, Owner, Parent)
	For Each KDItem IN SetElements Do
		VariantSetting = Parent.Rows.Add();
		FillPropertyValues(VariantSetting, Owner, "TreeRow, CollectionName, Global");
		VariantSetting.ID = KDItem.UserSettingID;
		VariantSetting.Type = ReportsClientServer.RowSettingType(TypeOf(KDItem));
		VariantSetting.DCIdentifier = KDNode.GetIDByObject(KDItem);
		VariantSetting.Owner = Owner;
		VariantSetting.KDItem = KDItem;
		VariantSetting.OutputAllowed = Not Information.OnlyCustom AND Owner.OutputAllowed;
		
		If VariantSetting.Type = "FilterItem"
			Or VariantSetting.Type = "SettingsParameterValue" Then
			RegisterField(Information, KDNode, KDItem, VariantSetting);
			If VariantSetting.AvailableKDSetting = Undefined Then
				VariantSetting.OutputAllowed = False;
				Continue;
			EndIf;
		EndIf;
		
		SettingProperty = Undefined;
		If TypeOf(VariantSetting.ID) = Type("String") AND Not IsBlankString(VariantSetting.ID) Then
			SettingProperty = Information.Search.UserSettings.Get(VariantSetting.ID);
		EndIf;
		If SettingProperty <> Undefined Then
			VariantSetting.UserSetting = SettingProperty;
			RegisterCustomSetting(Information, SettingProperty, Undefined, VariantSetting);
			If Information.OnlyCustom Then
				VariantSetting.OutputAllowed = SettingProperty.OutputAllowed;
				VariantSetting.Value      = SettingProperty.Value;
				VariantSetting.ComparisonType  = SettingProperty.ComparisonType;
			EndIf;
		EndIf;
		
		If VariantSetting.Type = "FilterItem" Then
			RegisterTypesAndLinks(Information, KDNode, KDItem, VariantSetting);
		ElsIf VariantSetting.Type = "FilterItemGroup" Then
			VariantSetting.Value = KDItem.GroupType;
			RegisterSubordinatedSettingsItems(Information, KDNode, KDItem.Items, Owner, VariantSetting);
		ElsIf VariantSetting.Type = "SettingsParameterValue" Then
			RegisterTypesAndLinks(Information, KDNode, KDItem, VariantSetting);
			RegisterSubordinatedSettingsItems(Information, KDNode, KDItem.NestedParameterValues, Owner, VariantSetting);
		EndIf;
		
		If SettingProperty <> Undefined Then
			SettingProperty.TypeDescription      = VariantSetting.TypeDescription;
			SettingProperty.TypeInformation   = VariantSetting.TypeInformation;
			SettingProperty.ValuesForSelection  = VariantSetting.ValuesForSelection;
			SettingProperty.ChoiceParameters    = VariantSetting.ChoiceParameters;
			SettingProperty.LimitChoiceWithSpecifiedValues = VariantSetting.LimitChoiceWithSpecifiedValues;
		EndIf;
	EndDo;
EndProcedure

Procedure RegisterField(Information, KDNode, KDItem, VariantSetting)
	If IsBlankString(VariantSetting.ID) Then
		ID = String(VariantSetting.TreeRow.DCIdentifier);
		If Not IsBlankString(ID) Then
			ID = ID + "_";
		EndIf;
		VariantSetting.ID = ID + VariantSetting.CollectionName + "_" + String(VariantSetting.DCIdentifier);
	EndIf;
	VariantSetting.ItemIdentificator = ReportsClientServer.AdjustIDToName(VariantSetting.ID);
	
	If VariantSetting.Type = "SettingsParameterValue" Then
		AvailableParameters = KDNode.AvailableParameters;
		If AvailableParameters = Undefined Then
			Return;
		EndIf;
		AvailableKDSetting = AvailableParameters.FindParameter(KDItem.Parameter);
		If AvailableKDSetting = Undefined Then
			Return;
		EndIf;
		// QuickSelection, SelectGroupsAndItems, ValuesListAvailables,
		// AvailableValues, BlockUnfilledValues, Usage, Mask, ConnectionByType, ChoiceForm EditFormat.
		If Not AvailableKDSetting.Visible Then
			VariantSetting.OutputAllowed = False;
		EndIf;
		VariantSetting.AvailableKDSetting = AvailableKDSetting;
		VariantSetting.DCField = New DataCompositionField("DataParameters." + String(KDItem.Parameter));
		VariantSetting.Value = KDItem.Value;
		If AvailableKDSetting.ValueListAllowed Then
			VariantSetting.ComparisonType = DataCompositionComparisonType.InList;
		Else
			VariantSetting.ComparisonType = DataCompositionComparisonType.Equal;
		EndIf;
	Else
		FilterAvailableFields = KDNode.FilterAvailableFields;
		If FilterAvailableFields = Undefined Then
			Return;
		EndIf;
		AvailableKDSetting = FilterAvailableFields.FindField(KDItem.LeftValue);
		If AvailableKDSetting = Undefined Then
			Return;
		EndIf;
		VariantSetting.AvailableKDSetting = AvailableKDSetting;
		VariantSetting.DCField       = KDItem.LeftValue;
		VariantSetting.Value     = KDItem.RightValue;
		VariantSetting.ComparisonType = KDItem.ComparisonType;
	EndIf;
	
	If VariantSetting.ComparisonType = DataCompositionComparisonType.InList
		Or VariantSetting.ComparisonType = DataCompositionComparisonType.InListByHierarchy
		Or VariantSetting.ComparisonType = DataCompositionComparisonType.NotInList
		Or VariantSetting.ComparisonType = DataCompositionComparisonType.NotInListByHierarchy Then
		VariantSetting.EnterByList = True;
		VariantSetting.ChoiceFoldersAndItems = FoldersAndItems.FoldersAndItems;
	ElsIf VariantSetting.ComparisonType = DataCompositionComparisonType.InHierarchy
		Or VariantSetting.ComparisonType = DataCompositionComparisonType.NotInHierarchy Then
		VariantSetting.ChoiceFoldersAndItems = FoldersAndItems.Folders;
	Else
		VariantSetting.ChoiceFoldersAndItems = ReportsClientServer.AdjustValueToGroupsAndItemsType(AvailableKDSetting.ChoiceFoldersAndItems);
	EndIf;
	
	VariantSetting.TypeDescription = AvailableKDSetting.ValueType;
	
	Information.Search.VariantSettingsByKDField.Insert(VariantSetting.DCField, VariantSetting);
	
	VariantSetting.DisplayCheckbox = True;
	If (VariantSetting.Type = "SettingsParameterValue"
			AND AvailableKDSetting.Use = DataCompositionParameterUse.Always)
		Or VariantSetting.Type = "SelectedFields"
		Or VariantSetting.Type = "Order"
		Or VariantSetting.Type = "StructureTableItemsCollection"
		Or VariantSetting.Type = "ChartStructureItemsCollection"
		Or VariantSetting.Type = "Filter"
		Or VariantSetting.Type = "ConditionalAppearance"
		Or VariantSetting.Type = "SettingsStructure" Then
		VariantSetting.DisplayCheckbox = False;
	EndIf;
	
EndProcedure

Procedure RegisterTypesAndLinks(Information, KDNode, KDItem, VariantSetting)
	
	///////////////////////////////////////////////////////////////////
	// Information about types.
	
	VariantSetting.LinksByMetadata     = New Array;
	VariantSetting.ChoiceParameterLinks = New Array;
	VariantSetting.ChoiceParameters       = New Array;
	
	If VariantSetting.EnterByList Then
		VariantSetting.MarkedValues = ReportsClientServer.ValueList(VariantSetting.Value);
	EndIf;
	VariantSetting.ValuesForSelection = New ValueList;
	VariantSetting.SelectionValueQuery = New Query;
	
	EnumerationQueryTemplate = "SELECT Refs IN &EnumerationName";
	ValuesQueryText = "";
	
	TypeInformation = ReportsClientServer.TypesAnalysis(VariantSetting.TypeDescription, True);
	TypeInformation.Insert("ContainsReferenceTypes", False);
	TypeInformation.Insert("EnumsQuantity",         0);
	TypeInformation.Insert("OtherReferenceTypesQuantity", 0);
	TypeInformation.Insert("Enums",        New Array);
	TypeInformation.Insert("OtherReferentialTypes", New Array);
	For Each Type IN TypeInformation.ObjectiveTypes Do
		DescriptionFull = Information.MapMetadataObjectName.Get(Type);
		If DescriptionFull = Undefined Then // Name of the metadata object registration.
			MetadataObject = Metadata.FindByType(Type);
			If MetadataObject = Undefined Then
				DescriptionFull = -1;
			Else
				DescriptionFull = MetadataObject.FullName();
			EndIf;
			Information.MapMetadataObjectName.Insert(Type, DescriptionFull);
		EndIf;
		If DescriptionFull = -1 Then
			Continue;
		EndIf;
		
		TypeInformation.ContainsReferenceTypes = True;
		
		If Upper(Left(DescriptionFull, 13)) = "ENUM." Then
			TypeInformation.Enums.Add(DescriptionFull);
			TypeInformation.EnumsQuantity = TypeInformation.EnumsQuantity + 1;
			If ValuesQueryText <> "" Then
				ValuesQueryText = ValuesQueryText + Chars.LF + Chars.LF + "UNION ALL" + Chars.LF + Chars.LF;
			EndIf;
			ValuesQueryText = ValuesQueryText + StrReplace(EnumerationQueryTemplate, "&EnumerationName", DescriptionFull);
		Else
			TypeInformation.OtherReferentialTypes.Add(DescriptionFull);
			TypeInformation.OtherReferenceTypesQuantity = TypeInformation.OtherReferenceTypesQuantity + 1;
		EndIf;
		
		// Search for the type in the global links among subordinates.
		Found = Information.Links.MetadataObjects.FindRows(New Structure("SubordinatedType", Type));
		For Each LinkByMetadata IN Found Do // Register setting as subordinate.
			LinkByMetadata.AreSubordinates = True;
			LinkByMetadata.Subordinate.Add(VariantSetting);
		EndDo;
		
		// Search for a type in the global links among the leading.
		If VariantSetting.ComparisonType = DataCompositionComparisonType.Equal Then
			// Field can be leading if it has the Equals comparison kind.
			Found = Information.Links.MetadataObjects.FindRows(New Structure("LeadingType", Type));
			For Each LinkByMetadata IN Found Do // Registration of setting as a leading one.
				LinkByMetadata.IsLeading = True;
				LinkByMetadata.Leading.Add(VariantSetting);
			EndDo;
		EndIf;
		
	EndDo;
	
	VariantSetting.TypeInformation = TypeInformation;
	
	///////////////////////////////////////////////////////////////////
	// Information about links and selection parameters.
	
	AvailableKDSetting = VariantSetting.AvailableKDSetting;
	
	If ValueIsFilled(AvailableKDSetting.TypeLink) Then
		LinkString = Information.Links.ByType.Add();
		LinkString.subordinated   = VariantSetting;
		LinkString.LeadingFieldDC = AvailableKDSetting.TypeLink.Field;
		LinkString.SubordinateNameParameter = AvailableKDSetting.TypeLink.LinkItem;
	EndIf;
	
	For Each LinkString IN AvailableKDSetting.GetChoiceParameterLinks() Do
		If IsBlankString(String(LinkString.Field)) Then
			Continue;
		EndIf;
		ParametersLinkString = Information.Links.ParametersSelect.Add();
		ParametersLinkString.subordinated             = VariantSetting;
		ParametersLinkString.SubordinateNameParameter = LinkString.Name;
		ParametersLinkString.LeadingFieldDC           = LinkString.Field;
		ParametersLinkString.Action                = LinkString.ValueChange;
	EndDo;
	
	For Each DCChoiceParameter IN AvailableKDSetting.GetChoiceParameters() Do
		VariantSetting.ChoiceParameters.Add(New ChoiceParameter(DCChoiceParameter.Name, DCChoiceParameter.Value));
	EndDo;
	
	///////////////////////////////////////////////////////////////////
	// Values list.
	
	If TypeOf(AvailableKDSetting.AvailableValues) = Type("ValueList")
		AND AvailableKDSetting.AvailableValues.Count() > 0 Then
		// Developer restricted the selection with available values list.
		VariantSetting.LimitChoiceWithSpecifiedValues = True;
		For Each ItemOfList IN AvailableKDSetting.AvailableValues Do
			ValueInDAS = ItemOfList.Value;
			If Not ValueIsFilled(ItemOfList.Presentation)
				AND (ValueInDAS = Undefined
					Or ValueInDAS = Type("Undefined")
					Or ValueInDAS = New TypeDescription("Undefined")
					Or Not ValueIsFilled(ValueInDAS)) Then
				Continue; // Prevent null values.
			EndIf;
			If TypeOf(ValueInDAS) = Type("Type") Then
				TypeArray = New Array;
				TypeArray.Add(ValueInDAS);
				ValueInForm = New TypeDescription(TypeArray);
			Else
				ValueInForm = ValueInDAS;
			EndIf;
			ReportsClientServer.AddUniqueValueInList(VariantSetting.ValuesForSelection, ValueInForm, ItemOfList.Presentation, False);
		EndDo;
	Else
		PreviouslySavedSettings = Information.AdditionalItemsSettings[VariantSetting.ItemIdentificator];
		If PreviouslySavedSettings <> Undefined
			AND CommonUseClientServer.StructureProperty(PreviouslySavedSettings, "LimitChoiceWithSpecifiedValues") = False Then
			OldValuesForSelection  = CommonUseClientServer.StructureProperty(PreviouslySavedSettings, "ValuesForSelection");
			OldTypeDescription      = CommonUseClientServer.StructureProperty(PreviouslySavedSettings, "TypeDescription");
			If TypeOf(OldValuesForSelection) = Type("ValueList") AND TypeOf(OldTypeDescription) = Type("TypeDescription") Then
				ControlType = Not TypeDescriptionsMatch(VariantSetting.TypeDescription, OldTypeDescription);
				VariantSetting.ValuesForSelection.ValueType = VariantSetting.TypeDescription;
				ReportsClientServer.ExpandList(VariantSetting.ValuesForSelection, OldValuesForSelection, ControlType);
			EndIf;
		EndIf;
		
		VariantSetting.SelectionValueQuery.Text = ValuesQueryText;
		If TypeInformation.EnumsQuantity = TypeInformation.TypeCount Then
			VariantSetting.LimitChoiceWithSpecifiedValues = True; // Only enumerations.
		EndIf;
	EndIf;
	
	// Extension mechanisms.
	// Global settings of types output.
	ReportsOverridable.OnDefineSelectionParameters(Undefined, VariantSetting);
	// Local override for report.
	If Information.ReportSettings.Events.OnDefineSelectionParameters Then
		ReportObject = ReportObject(Information.ReportSettings);
		ReportObject.OnDefineSelectionParameters(Undefined, VariantSetting);
	EndIf;
	
	// Automatic filling.
	If VariantSetting.SelectionValueQuery.Text <> "" Then
		AddedValues = VariantSetting.SelectionValueQuery.Execute().Unload().UnloadColumn(0);
		For Each ValueInForm IN AddedValues Do
			ReportsClientServer.AddUniqueValueInList(VariantSetting.ValuesForSelection, ValueInForm, Undefined, False);
		EndDo;
		VariantSetting.ValuesForSelection.SortByPresentation(SortDirection.Asc);
	EndIf;
	
EndProcedure

Procedure RegisterLinksFromLeading(Information)
	Links = Information.Links;
	
	// Registration of the selection parameters registration (dynamic connection disabled with the Use check box).
	Found = Links.MetadataObjects.FindRows(New Structure("AreSubordinates, IsLeading", True, True));
	For Each LinkByMetadata IN Found Do
		For Each Leading IN LinkByMetadata.Leading Do
			For Each subordinated IN LinkByMetadata.Subordinate Do
				If Leading.OutputAllowed Then // Disabled link.
					LinkDescription = New Structure;
					LinkDescription.Insert("LinkType",                "ByMetadata");
					LinkDescription.Insert("Leading",                 Leading);
					LinkDescription.Insert("subordinated",             subordinated);
					LinkDescription.Insert("LeadingType",              LinkByMetadata.LeadingType);
					LinkDescription.Insert("SubordinatedType",          LinkByMetadata.SubordinatedType);
					LinkDescription.Insert("SubordinateNameParameter", LinkByMetadata.SubordinatedAttribute);
					Information.DisabledLinks.Add(LinkDescription);
					subordinated.LinksByMetadata.Add(LinkDescription);
				Else // Fixed selection parameter.
					subordinated.ChoiceParameters.Add(New ChoiceParameter(LinkByMetadata.SubordinatedAttribute, Leading.Value));
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
	// Links by type.
	For Each TypeLink IN Links.ByType Do
		Leading = Information.Search.VariantSettingsByKDField.Get(TypeLink.LeadingFieldDC);
		If Leading = Undefined Then
			Continue;
		EndIf;
		subordinated = TypeLink.subordinated;
		If Leading.OutputAllowed Then // Disabled link.
			LinkDescription = New Structure;
			LinkDescription.Insert("LinkType",                "ByType");
			LinkDescription.Insert("Leading",                 Leading);
			LinkDescription.Insert("subordinated",             subordinated);
			LinkDescription.Insert("SubordinateNameParameter", TypeLink.SubordinateNameParameter);
			Information.DisabledLinks.Add(LinkDescription);
			subordinated.TypeLink = LinkDescription;
		Else // Fixed type restriction.
			TypeArray = New Array;
			TypeArray.Add(TypeOf(Leading.Value));
			subordinated.TypeRestriction = New TypeDescription(TypeArray);
		EndIf;
	EndDo;
	
	// Selection parameters links.
	For Each LinkSelectParameters IN Links.ParametersSelect Do
		Leading     = LinkSelectParameters.Leading;
		subordinated = LinkSelectParameters.subordinated;
		If Leading = Undefined Then
			BestVariant = 99;
			Found = Information.VariantSettings.Rows.FindRows(New Structure("DCField", LinkSelectParameters.LeadingFieldDC), True);
			For Each ProspectiveParent IN Found Do
				If ProspectiveParent.Parent = subordinated.Parent Then // Items in one group.
					If Not IsBlankString(ProspectiveParent.ItemIdentificator) Then // Leading is put out into custom.
						Leading = ProspectiveParent;
						BestVariant = 0;
						Break; // Best variant.
					Else
						Leading = ProspectiveParent;
						BestVariant = 1;
					EndIf;
				ElsIf BestVariant > 2 AND ProspectiveParent.Owner = subordinated.Owner Then // Items in one collection.
					If Not IsBlankString(ProspectiveParent.ItemIdentificator) Then // Leading is put out into custom.
						If BestVariant > 2 Then
							Leading = ProspectiveParent;
							BestVariant = 2;
						EndIf;
					Else
						If BestVariant > 3 Then
							Leading = ProspectiveParent;
							BestVariant = 3;
						EndIf;
					EndIf;
				ElsIf BestVariant > 4 AND ProspectiveParent.TreeRow = subordinated.TreeRow Then // Items in one node.
					If Not IsBlankString(ProspectiveParent.ItemIdentificator) Then // Leading is put out into custom.
						If BestVariant > 4 Then
							Leading = ProspectiveParent;
							BestVariant = 4;
						EndIf;
					Else
						If BestVariant > 5 Then
							Leading = ProspectiveParent;
							BestVariant = 5;
						EndIf;
					EndIf;
				ElsIf BestVariant > 6 Then
					Leading = ProspectiveParent;
					BestVariant = 6;
				EndIf;
			EndDo;
			If Leading = Undefined Then
				Continue;
			EndIf;
		EndIf;
		If Leading.OutputAllowed Then // Disabled link.
			LinkDescription = New Structure;
			LinkDescription.Insert("LinkType",      "ParametersSelect");
			LinkDescription.Insert("Leading",       Leading);
			LinkDescription.Insert("subordinated",   subordinated);
			LinkDescription.Insert("SubordinateNameParameter", LinkSelectParameters.SubordinateNameParameter);
			LinkDescription.Insert("SubordinatedAction",     LinkSelectParameters.Action);
			Information.DisabledLinks.Add(LinkDescription);
			subordinated.ChoiceParameterLinks.Add(LinkDescription);
		Else // Fixed selection parameter.
			If TypeOf(Leading.Value) = Type("DataCompositionField") Then
				Continue; // Extended work with the selections by the data layout field is not supported.
			EndIf;
			subordinated.ChoiceParameters.Add(New ChoiceParameter(LinkSelectParameters.SubordinateNameParameter, Leading.Value));
		EndIf;
	EndDo;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// User settings

Function RegisterCustomSetting(Information, SettingProperty, TreeRow, VariantSetting)
	DCUsersSetting = SettingProperty.DCUsersSetting;
	
	ViewMode = DCUsersSetting.ViewMode;
	If ViewMode = DataCompositionSettingsItemViewMode.Inaccessible Then
		Return SettingProperty;
	EndIf;
	
	If Not ValueIsFilled(SettingProperty.ID) Then
		Return SettingProperty;
	EndIf;
	SettingProperty.ItemIdentificator = ReportsClientServer.AdjustIDToName(SettingProperty.ID);
	
	If VariantSetting <> Undefined Then
		If VariantSetting.Owner <> Undefined Then
			SettingProperty.KDNode = VariantSetting.Owner.KDItem;
		EndIf;
		SettingProperty.TreeRow         = VariantSetting.TreeRow;
		SettingProperty.KDVariantSetting  = VariantSetting.KDItem;
		SettingProperty.VariantSetting    = VariantSetting;
		SettingProperty.Subtype               = VariantSetting.Subtype;
		SettingProperty.DCField               = VariantSetting.DCField;
		SettingProperty.AvailableKDSetting = VariantSetting.AvailableKDSetting;
		If ViewMode = DataCompositionSettingsItemViewMode.Auto Then
			ViewMode = SettingProperty.KDVariantSetting.ViewMode;
		EndIf;
	Else
		SettingProperty.KDNode              = TreeRow.KDNode;
		SettingProperty.TreeRow        = TreeRow;
		SettingProperty.Type                 = TreeRow.Type;
		SettingProperty.Subtype              = TreeRow.Subtype;
		SettingProperty.KDVariantSetting = SettingProperty.KDNode;
		If ViewMode = DataCompositionSettingsItemViewMode.Auto Then
			ViewMode = SettingProperty.KDNode.ViewMode;
		EndIf;
	EndIf;
	
	If ViewMode = DataCompositionSettingsItemViewMode.QuickAccess Then
		SettingProperty.Quick = True;
		Information.ThereAreQuickSettings = True;
	ElsIf ViewMode = DataCompositionSettingsItemViewMode.Normal Then
		SettingProperty.Ordinary = True;
		Information.ThereAreCommonSettings = True;
	ElsIf Information.OnlyCustom Then
		Return SettingProperty;
	EndIf;
	
	// Available setting definition.
	If SettingProperty.Type = "NestedObjectSettings" Then
		SettingProperty.AvailableKDSetting = Information.DCSettings.AvailableObjects.Items.Find(SettingProperty.TreeRow.KDNode.ObjectID);
	ElsIf SettingProperty.Type = "SettingsParameterValue"
		Or SettingProperty.Type = "FilterItem" Then
		If SettingProperty.AvailableKDSetting = Undefined Then
			Return SettingProperty; // Field name was changed or field wad deleted.
		EndIf;
	EndIf;
	
	If Information.OnlyCustom Then
		If Information.OnlyQuick Then
			SettingProperty.OutputAllowed = SettingProperty.Quick;
		Else
			SettingProperty.OutputAllowed = True;
		EndIf;
	EndIf;
	
	SettingProperty.DisplayCheckbox = True;
	SettingProperty.DisplayOnlyCheckBox = False;
	
	FillSettingPresentation(SettingProperty, True);
	
	If SettingProperty.Type = "FilterItemGroup"
		Or SettingProperty.Type = "NestedObjectSettings"
		Or SettingProperty.Type = "Group"
		Or SettingProperty.Type = "Table"
		Or SettingProperty.Type = "TableGrouping"
		Or SettingProperty.Type = "Chart"
		Or SettingProperty.Type = "ChartGrouping"
		Or SettingProperty.Type = "ConditionalAppearanceItem" Then
		
		SettingProperty.DisplayOnlyCheckBox = True;
		
	ElsIf SettingProperty.Type = "SettingsParameterValue"
		Or SettingProperty.Type = "FilterItem" Then
		
		If SettingProperty.Type = "SettingsParameterValue" Then
			SettingProperty.Value = DCUsersSetting.Value;
		Else
			SettingProperty.Value = DCUsersSetting.RightValue;
		EndIf;
		
		// Definition of a setting value type.
		TypeInformation = ReportsClientServer.TypesAnalysis(SettingProperty.AvailableKDSetting.ValueType, True);
		SettingProperty.TypeInformation = TypeInformation;
		SettingProperty.TypeDescription    = TypeInformation.TypeDescriptionForForm;
		
		If SettingProperty.Type = "SettingsParameterValue" Then
			If SettingProperty.AvailableKDSetting.Use = DataCompositionParameterUse.Always Then
				SettingProperty.DisplayCheckbox = False;
				DCUsersSetting.Use = True;
			EndIf;
			If SettingProperty.AvailableKDSetting.ValueListAllowed Then
				SettingProperty.ComparisonType = DataCompositionComparisonType.InList;
			Else
				SettingProperty.ComparisonType = DataCompositionComparisonType.Equal;
			EndIf;
		ElsIf SettingProperty.Type = "FilterItem" Then
			SettingProperty.ComparisonType = DCUsersSetting.ComparisonType;
		EndIf;
		
		If SettingProperty.TypeInformation.ContainsTypePeriod
			AND SettingProperty.TypeInformation.TypeCount = 1 Then
			
			SettingProperty.ItemsType = "StandardPeriod";
			
		ElsIf Not SettingProperty.DisplayCheckbox
			AND SettingProperty.TypeInformation.ContainsTypeBoolean
			AND SettingProperty.TypeInformation.TypeCount = 1 Then
			
			SettingProperty.ItemsType = "OnlyCheckBoxValues";
			
		ElsIf SettingProperty.ComparisonType = DataCompositionComparisonType.Filled
			Or SettingProperty.ComparisonType = DataCompositionComparisonType.NotFilled Then
			
			SettingProperty.DisplayOnlyCheckBox = True;
			SettingProperty.Presentation = SettingProperty.Presentation + ": " + Lower(String(SettingProperty.ComparisonType));
			
		ElsIf SettingProperty.ComparisonType = DataCompositionComparisonType.InList
			Or SettingProperty.ComparisonType = DataCompositionComparisonType.InListByHierarchy
			Or SettingProperty.ComparisonType = DataCompositionComparisonType.NotInList
			Or SettingProperty.ComparisonType = DataCompositionComparisonType.NotInListByHierarchy Then
			
			SettingProperty.EnterByList = True;
			SettingProperty.ItemsType = "ListWithSelection";
			SettingProperty.ChoiceFoldersAndItems = FoldersAndItems.FoldersAndItems;
			
		Else
			
			SettingProperty.ItemsType = "LinkWithLinker";
			If SettingProperty.ComparisonType <> DataCompositionComparisonType.Equal
				AND SettingProperty.ComparisonType <> DataCompositionComparisonType.Contains
				AND Not SettingProperty.DisplayOnlyCheckBox Then
				SettingProperty.Presentation = SettingProperty.Presentation + " (" + Lower(String(SettingProperty.ComparisonType)) + ")";
			EndIf;
			If SettingProperty.ComparisonType = DataCompositionComparisonType.InHierarchy
				Or SettingProperty.ComparisonType = DataCompositionComparisonType.NotInHierarchy Then
				SettingProperty.ChoiceFoldersAndItems = FoldersAndItems.Folders;
			EndIf;
			
		EndIf;
		
		If SettingProperty.ChoiceFoldersAndItems = Undefined Then
			SettingProperty.ChoiceFoldersAndItems = VariantSetting.ChoiceFoldersAndItems;
		EndIf;
		
	ElsIf SettingProperty.Type = "SelectedFields"
		Or SettingProperty.Type = "Order"
		Or SettingProperty.Type = "StructureTableItemsCollection"
		Or SettingProperty.Type = "ChartStructureItemsCollection"
		Or SettingProperty.Type = "Filter"
		Or SettingProperty.Type = "ConditionalAppearance"
		Or SettingProperty.Type = "SettingsStructure" Then
		
		SettingProperty.ItemsType = "LinkWithLinker";
		SettingProperty.DisplayCheckbox = False;
		
	Else
		
		SettingProperty.ItemsType = "LinkWithLinker";
		
	EndIf;
	
	If SettingProperty.DisplayOnlyCheckBox Then
		SettingProperty.ItemsType = "";
	ElsIf SettingProperty.Quick AND SettingProperty.ItemsType = "ListWithSelection" Then
		SettingProperty.ItemsType = "LinkWithLinker";
	EndIf;
	
	Return SettingProperty;
EndFunction

Procedure FillSettingPresentation(SettingProperty, IsCustomSetting)
	ItemHeader = "";
	If IsCustomSetting Then
		KDVariantSetting = SettingProperty.KDVariantSetting;
		DCUsersSetting = SettingProperty.DCUsersSetting;
		AvailableKDSetting = SettingProperty.AvailableKDSetting;
	Else
		KDVariantSetting = SettingProperty.KDNode;
		DCUsersSetting = KDVariantSetting;
		AvailableKDSetting = Undefined;
	EndIf;
	
	PresentationsStructure = New Structure("Presentation, UserSettingPresentation", "", "");
	FillPropertyValues(PresentationsStructure, KDVariantSetting);
	
	SettingProperty.DisplayOnlyCheckBox = ValueIsFilled(PresentationsStructure.Presentation);
	
	If ValueIsFilled(PresentationsStructure.UserSettingPresentation) Then
		
		ItemHeader = PresentationsStructure.UserSettingPresentation;
		
	ElsIf ValueIsFilled(PresentationsStructure.Presentation) AND PresentationsStructure.Presentation <> "1" Then
		
		ItemHeader = PresentationsStructure.Presentation;
		
	ElsIf AvailableKDSetting <> Undefined AND ValueIsFilled(AvailableKDSetting.Title) Then
		
		ItemHeader = AvailableKDSetting.Title;
		
	EndIf;
	
	// By default presentation.
	If Not ValueIsFilled(ItemHeader) Then
		
		If ValueIsFilled(SettingProperty.Subtype) Then
			
			If SettingProperty.Subtype = "SeriesChart" Then
				
				ItemHeader = NStr("en='Series';ru='Серия';vi='Ký hiệu'");
				
			ElsIf SettingProperty.Subtype = "PointChart" Then
				
				ItemHeader = NStr("en='Points';ru='Точки';vi='Điểm'");
				
			ElsIf SettingProperty.Subtype = "RowTable" Then
				
				ItemHeader = NStr("en='Lines';ru='Строки';vi='Dòng'");
				
			ElsIf SettingProperty.Subtype = "ColumnTable" Then
				
				ItemHeader = NStr("en='Columns';ru='Колонки';vi='Cột'");
				
			Else
				
				ItemHeader = String(SettingProperty.Subtype);
				
			EndIf;
			
		ElsIf SettingProperty.Type = "Filter" Then
			
			ItemHeader = NStr("en='Filter';ru='Фильтр';vi='Phễu lọc'");
			
		ElsIf SettingProperty.Type = "FilterItemGroup" Then
			
			ItemHeader = String(DCUsersSetting.GroupType);
			
		ElsIf SettingProperty.Type = "FilterItem" Then
			
			ItemHeader = String(KDVariantSetting.LeftValue);
			
		ElsIf SettingProperty.Type = "Order" Then
			
			ItemHeader = NStr("en='Sorting';ru='Сортировка';vi='Sắp xếp'");
			
		ElsIf SettingProperty.Type = "SelectedFields" Then
			
			ItemHeader = NStr("en='Fields';ru='Поля';vi='Trường'");
			
		ElsIf SettingProperty.Type = "ConditionalAppearance" Then
			
			ItemHeader = NStr("en='Appearance';ru='Оформление';vi='Trang trí'");
			
		ElsIf SettingProperty.Type = "ConditionalAppearanceItem" Then
			
			DesignPresentation = String(DCUsersSetting.Appearance);
			If DesignPresentation = "" Then
				ItemHeader = NStr("en='Do not create';ru='Не оформлять';vi='Chưa lập báo cáo'");
			Else
				ItemHeader = DesignPresentation;
			EndIf;
			
			FieldsPresentation = String(DCUsersSetting.Fields);
			If FieldsPresentation = "" Then
				ItemHeader = ItemHeader + " / " + NStr("en='All fields';ru='Все поля';vi='Tất cả trường'");
			Else
				ItemHeader = ItemHeader + " / " + NStr("en='Fields:';ru='Поля:';vi='Trường:'") + " " + FieldsPresentation;
			EndIf;
			
			FilterPresentation = FilterPresentation(DCUsersSetting.Filter);
			If FilterPresentation <> "" Then
				ItemHeader = ItemHeader + " / " + NStr("en='State:';ru='Состояние:';vi='Trạng thái:'") + " " + FilterPresentation;
			EndIf;
			
		ElsIf SettingProperty.Type = "SettingsParameterValue" Then
			
			ItemHeader = String(KDVariantSetting.Parameter);
			
		ElsIf SettingProperty.Type = "Group"
			Or SettingProperty.Type = "TableGrouping"
			Or SettingProperty.Type = "ChartGrouping" Then
			
			GroupFields = KDVariantSetting.GroupFields;
			If GroupFields.Items.Count() = 0 Then
				ItemHeader = NStr("en='<Detailed records>';ru='<Детальные записи>';vi='<Bản ghi chi tiết>'");
			Else
				ItemHeader = TrimAll(String(GroupFields));
			EndIf;
			If IsBlankString(ItemHeader) Then
				ItemHeader = NStr("en='Grouping';ru='Группировка';vi='Gom nhóm'");
			EndIf;
			
		ElsIf SettingProperty.Type = "Table" Then
			
			ItemHeader = NStr("en='Table';ru='Таблица';vi='Bảng'");
			
		ElsIf SettingProperty.Type = "Chart" Then
			
			ItemHeader = NStr("en='Chart';ru='Диаграмма';vi='Biểu đồ'");
			
		ElsIf SettingProperty.Type = "NestedObjectSettings" Then
			
			ItemHeader = String(DCUsersSetting);
			If IsBlankString(ItemHeader) Then
				ItemHeader = NStr("en='Attach grouping';ru='Вложенная группировка';vi='Gom nhóm lồng trong'");
			EndIf;
			
		ElsIf SettingProperty.Type = "SettingsStructure" Then
			
			ItemHeader = NStr("en='Structure';ru='Состав';vi='Thành phần'");
			
		Else
			
			ItemHeader = String(SettingProperty.Type);
			
		EndIf;
		
	EndIf;
	
	SettingProperty.Presentation = TrimAll(ItemHeader);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Auxiliary

Function FilterPresentation(KDNode, KDRowsSet = Undefined)
	If KDRowsSet = Undefined Then
		KDRowsSet = KDNode.Items;
	EndIf;
	
	Presentation = "";
	
	For Each KDItem IN KDRowsSet Do
		
		If TypeOf(KDItem) = Type("DataCompositionFilterItemGroup") Then
			
			AuthorPresentationFolders = String(KDItem.GroupType);
			NestedPresentation = FilterPresentation(KDNode, KDItem.Items);
			If NestedPresentation = "" Then
				Continue;
			EndIf;
			ItemPresentation = AuthorPresentationFolders + "(" + NestedPresentation + ")";
			
		ElsIf TypeOf(KDItem) = Type("DataCompositionFilterItem") Then
			
			AvailableKDSelectionField = KDNode.FilterAvailableFields.FindField(KDItem.LeftValue);
			If AvailableKDSelectionField = Undefined Then
				Continue;
			EndIf;
			
			If ValueIsFilled(AvailableKDSelectionField.Title) Then
				FieldPresentation = AvailableKDSelectionField.Title;
			Else
				FieldPresentation = String(KDItem.LeftValue);
			EndIf;
			
			ValuePresentation = String(KDItem.RightValue);
			
			If KDItem.ComparisonType = DataCompositionComparisonType.Equal Then
				PresentationConditions = "=";
			ElsIf KDItem.ComparisonType = DataCompositionComparisonType.NotEqual Then
				PresentationConditions = "<>";
			ElsIf KDItem.ComparisonType = DataCompositionComparisonType.Greater Then
				PresentationConditions = ">";
			ElsIf KDItem.ComparisonType = DataCompositionComparisonType.GreaterOrEqual Then
				PresentationConditions = ">=";
			ElsIf KDItem.ComparisonType = DataCompositionComparisonType.Less Then
				PresentationConditions = "<";
			ElsIf KDItem.ComparisonType = DataCompositionComparisonType.LessOrEqual Then
				PresentationConditions = "<=";
			
			ElsIf KDItem.ComparisonType = DataCompositionComparisonType.InHierarchy Then
				PresentationConditions = NStr("en='In group';ru='В группе';vi='Trong nhóm'");
			ElsIf KDItem.ComparisonType = DataCompositionComparisonType.NotInHierarchy Then
				PresentationConditions = NStr("en='Not in group';ru='Не в группе';vi='Không trong nhóm'");
			ElsIf KDItem.ComparisonType = DataCompositionComparisonType.InList Then
				PresentationConditions = NStr("en='In the list';ru='В списке';vi='Trong danh sách'");
			ElsIf KDItem.ComparisonType = DataCompositionComparisonType.NotInList Then
				PresentationConditions = NStr("en='Not in the list';ru='Не в списке';vi='Không trong danh sách'");
			ElsIf KDItem.ComparisonType = DataCompositionComparisonType.InListByHierarchy Then
				PresentationConditions = NStr("en='In list including subordinate';ru='В списке включая подчиненные';vi='Trong danh sách bao gồm trực thuộc'");
			ElsIf KDItem.ComparisonType = DataCompositionComparisonType.NotInListByHierarchy Then
				PresentationConditions = NStr("en='Not in the list, including subordinate';ru='Не в списке включая подчиненные';vi='Không bao gồm trực thuộc trong danh sách'");
			
			ElsIf KDItem.ComparisonType = DataCompositionComparisonType.Contains Then
				PresentationConditions = NStr("en='Contains';ru='Содержит';vi='Có chứa'");
			ElsIf KDItem.ComparisonType = DataCompositionComparisonType.NotContains Then
				PresentationConditions = NStr("en='Does not contain';ru='Не содержит';vi='Không chứa'");
			ElsIf KDItem.ComparisonType = DataCompositionComparisonType.Like Then
				PresentationConditions = NStr("en='Like';ru='Подобно';vi='Chi tiết'");
			ElsIf KDItem.ComparisonType = DataCompositionComparisonType.NotLike Then
				PresentationConditions = NStr("en='Not like';ru='Не подобно';vi='Không chi tiết'");
			ElsIf KDItem.ComparisonType = DataCompositionComparisonType.BeginsWith Then
				PresentationConditions = NStr("en='Begins with';ru='Начинается с';vi='Bắt đầu từ'");
			ElsIf KDItem.ComparisonType = DataCompositionComparisonType.NotBeginsWith Then
				PresentationConditions = NStr("en='Does not begin with';ru='Не начинается с';vi='Không bắt đầu từ'");
			ElsIf KDItem.ComparisonType = DataCompositionComparisonType.Filled Then
				PresentationConditions = NStr("en='filled in';ru='заполненный';vi='đã điền'");
				ValuePresentation = "";
			ElsIf KDItem.ComparisonType = DataCompositionComparisonType.NotFilled Then
				PresentationConditions = NStr("en='Not filled in';ru='Не заполнено';vi='Chưa điền'");
				ValuePresentation = "";
			EndIf;
			
			ItemPresentation = TrimAll(FieldPresentation + " " + PresentationConditions + " " + ValuePresentation);
			
		Else
			Continue;
		EndIf;
		
		Presentation = Presentation + ?(Presentation = "", "", ", ") + ItemPresentation;
		
	EndDo;
	
	Return Presentation;
EndFunction

Function TypeDescriptionsMatch(TypeDescription1, TypeDescription2) Export
	If TypeDescription1 = Undefined Or TypeDescription2 = Undefined Then
		Return False;
	EndIf;
	
	Return TypeDescription1 = TypeDescription2
		Or CommonUse.ValueToXMLString(TypeDescription1) = CommonUse.ValueToXMLString(TypeDescription2);
EndFunction

Function ReportObject(ID) Export
	FullName = ID;
	
	If TypeOf(ID) = Type("CatalogRef.MetadataObjectIDs") Then
		FullName = CommonUse.ObjectAttributeValue(ID, "FullName");
	EndIf;
	
	ObjectDescription = StrSplit(FullName, ".");
	
	If ObjectDescription.Count() >= 2 Then
		Kind = Upper(ObjectDescription[0]);
		NAME = ObjectDescription[1];
	Else
		Raise StrReplace(NStr("en='Некорректное полное имя отчета ""%1"".';ru='Некорректное полное имя отчета ""%1"".';vi='Tên báo cáo đủ điều kiện ""%1""'' không hợp lệ.'"), "%1", FullName);
	EndIf;
	
	If Kind = Upper("Report") Then
		Return Reports[NAME].Create();
	ElsIf Kind = Upper("ExternalReport") Then
		Return ExternalReports.Create(NAME); // АПК:553 Для внешних отчетов, не подключенных к подсистеме "Дополнительные отчеты и обработки". Вызов безопасен, так как проверки безопасности для внешнего отчета выполнены ранее при подключении.
	Else
		Raise StrReplace(NStr("en='""%1"" не является отчетом.';ru='""%1"" не является отчетом.';vi='""%1"" không phải là một báo cáo.'"), "%1", FullName);
	EndIf;
EndFunction


////////////////////////////////////////////////////////////////////////////////
// Output

Procedure OutputSettingItems(Form, Items, SettingProperty, OutputGroup, Other) Export
	OutputItem = New Structure("Size, ItemName1, ItemName2");
	OutputItem.Size = 1;
	
	ItemNameTemplate = SettingProperty.Type + "_%1_" + SettingProperty.ItemIdentificator;
	
	// Group is required to output some types of the fields.
	If SettingProperty.ItemsType = "StandardPeriod"
		Or SettingProperty.ItemsType = "ListWithSelection" Then
		GroupName = StrReplace(ItemNameTemplate, "%1", "Group");
		
		Group = Items.Add(GroupName, Type("FormGroup"), Items.NotSorted);
		Group.Type                 = FormGroupType.UsualGroup;
		Group.Representation         = UsualGroupRepresentation.None;
		Group.Title           = SettingProperty.Presentation;
		Group.ShowTitle = False;
	EndIf;
	
	// Usage check box.
	If SettingProperty.DisplayCheckbox Then
		FlagName = StrReplace(ItemNameTemplate, "%1", "Use");
		
		If SettingProperty.ItemsType = "ListWithSelection" Then
			CheckBoxForGroup = Group;
			OutputItem.ItemName1 = GroupName;
		Else
			CheckBoxForGroup = Items.NotSorted;
			OutputItem.ItemName1 = FlagName;
		EndIf;
		
		CheckBox = Items.Add(FlagName, Type("FormField"), CheckBoxForGroup);
		CheckBox.Type         = FormFieldType.CheckBoxField;
		CheckBox.Title   = SettingProperty.Presentation + ?(SettingProperty.DisplayOnlyCheckBox, "", ":");
		CheckBox.DataPath = Other.PathToLinker + ".UserSettings[" + SettingProperty.IndexInCollection + "].Use";
		CheckBox.TitleLocation = FormItemTitleLocation.Right;
		CheckBox.SetAction("OnChange", "Attachable_CheckBoxUse__OnChange");
	EndIf;
	
	// Fields for values.
	If SettingProperty.ItemsType <> "" Then
		
		TypeInformation = SettingProperty.TypeInformation;
		
		If SettingProperty.Type = "SettingsParameterValue"
			Or SettingProperty.Type = "FilterItem" Then
			
			If SettingProperty.EnterByList Then
				SettingProperty.MarkedValues = ReportsClientServer.ValueList(SettingProperty.Value);
			EndIf;
			
			// Save setting selection parameters in the additional properties of the custom settings.
			ItemSettings = New Structure;
			ItemSettings.Insert("Presentation",     SettingProperty.Presentation);
			ItemSettings.Insert("DisplayCheckbox",    SettingProperty.DisplayCheckbox);
			ItemSettings.Insert("TypeDescription",     SettingProperty.TypeDescription);
			ItemSettings.Insert("ChoiceParameters",   SettingProperty.ChoiceParameters);
			ItemSettings.Insert("ValuesForSelection", SettingProperty.ValuesForSelection);
			ItemSettings.Insert("LimitChoiceWithSpecifiedValues", SettingProperty.LimitChoiceWithSpecifiedValues);
			Other.AdditionalItemsSettings.Insert(SettingProperty.ItemIdentificator, ItemSettings);
		EndIf;
		
		////////////////////////////////////////////////////////////////////////////////
		// OUTPUT.
		
		ValueName = StrReplace(ItemNameTemplate, "%1", "Value");
		
		If SettingProperty.ItemsType = "OnlyCheckBoxValues" Then
			
			QuickSettingsAddAttribute(Other.FillingParameters, ValueName, SettingProperty.TypeDescription);
			
			OutputItem.ItemName1 = ValueName;
			
			InputField = Items.Add(ValueName, Type("FormField"), Group);
			InputField.Type                = FormFieldType.CheckBoxField;
			InputField.Title          = SettingProperty.Presentation;
			InputField.TitleLocation = FormItemTitleLocation.Right;
			InputField.SetAction("OnChange", "Attachable_ValueCheckBox_OnChange");
			
			Other.AddedInputFields.Insert(ValueName, SettingProperty.Value);
			
		ElsIf SettingProperty.ItemsType = "LinkWithLinker" Then
			
			Other.MainFormAttributesNames.Insert(SettingProperty.ItemIdentificator, ValueName);
			Other.NamesOfElementsForLinksSetup.Insert(SettingProperty.ItemIdentificator, ValueName);
			
			OutputItem.ItemName2 = ValueName;
			
			InputField = Items.Add(ValueName, Type("FormField"), Group);
			InputField.Type         = FormFieldType.InputField;
			InputField.Title   = SettingProperty.Presentation;
			InputField.DataPath = Other.PathToLinker + ".UserSettings[" + SettingProperty.IndexInCollection + "].Value";
			InputField.TitleLocation = FormItemTitleLocation.None;
			InputField.SetAction("OnChange", "Attachable_TextBox_OnChange");
			
			If SettingProperty.EnterByList Then
				InputField.SetAction("StartChoice", "Attachable_LinkerList_Value_StartChoice");
			EndIf;
			
			If SettingProperty.Type = "SettingsParameterValue" Then
				InputField.AutoMarkIncomplete = SettingProperty.AvailableKDSetting.DenyIncompleteValues;
			EndIf;
			
		ElsIf SettingProperty.ItemsType = "InputField" Then
			
			OutputItem.ItemName2 = ValueName;
			
			Other.MainFormAttributesNames.Insert(SettingProperty.ItemIdentificator, ValueName);
			Other.NamesOfElementsForLinksSetup.Insert(SettingProperty.ItemIdentificator, ValueName);
			
			// Attribute
			QuickSettingsAddAttribute(Other.FillingParameters, ValueName, SettingProperty.TypeDescription);
			
			InputField = Items.Add(ValueName, Type("FormField"), Group);
			InputField.Type                 = FormFieldType.InputField;
			InputField.Title           = SettingProperty.Presentation;
			InputField.OpenButton      = False;
			InputField.SpinButton = False;
			InputField.TitleLocation  = FormItemTitleLocation.None;
			InputField.SetAction("OnChange", "Attachable_TextBox_OnChange");
			
			FillPropertyValues(InputField, SettingProperty.AvailableKDSetting, "QuickSelection, Mask, ChoiceForm, EditFormat");
			
			InputField.ChoiceFoldersAndItems = SettingProperty.ChoiceFoldersAndItems;
			
			If SettingProperty.Type = "SettingsParameterValue" Then
				InputField.AutoMarkIncomplete = SettingProperty.AvailableKDSetting.DenyIncompleteValues;
			EndIf;
			
			// Entered fields of the following types are not dragged horizontally and do not have the clear button.:
			//     Date, Boolean, Number, Type.
			InputField.ClearButton            = TypeInformation.ContainsObjectTypes;
			InputField.HorizontalStretch = TypeInformation.ContainsObjectTypes;
			For Each ListItemInForm IN SettingProperty.ValuesForSelection Do
				FillPropertyValues(InputField.ChoiceList.Add(), ListItemInForm);
			EndDo;
			If SettingProperty.LimitChoiceWithSpecifiedValues Then
				InputField.ListChoiceMode = True;
				InputField.CreateButton = False;
				InputField.HorizontalStretch = True;
			EndIf;
			
			// Fixed selection parameters.
			If SettingProperty.ChoiceParameters.Count() > 0 Then
				InputField.ChoiceParameters = New FixedArray(SettingProperty.ChoiceParameters);
			EndIf;
			
			// Attribute value.
			Value = SettingProperty.Value;
			If TypeOf(Value) = Type("StandardBeginningDate") Then
				Value = Date(Value);
			ElsIf TypeOf(Value) = Type("Type") Then
				TypeArray = New Array;
				TypeArray.Add(Value);
				Value = New TypeDescription(TypeArray);
			EndIf;
			Other.AddedInputFields.Insert(ValueName, Value);
			
		ElsIf SettingProperty.ItemsType = "StandardPeriod" Then
			
			Group.Group = ChildFormItemsGroup.AlwaysHorizontal;
			
			OutputItem.Size = 1;
			OutputItem.ItemName2 = GroupName;
			
			PeriodKindName           = StrReplace(ItemNameTemplate, "%1", "Kind");
			AuthorPresentationActualName        = StrReplace(ItemNameTemplate, "%1", "Presentation");
			BeginOfPeriodName         = StrReplace(ItemNameTemplate, "%1", "Begin");
			EndOfPeriodName      = StrReplace(ItemNameTemplate, "%1", "End");
			DecorationName            = StrReplace(ItemNameTemplate, "%1", "Decoration");
			PagesName             = StrReplace(ItemNameTemplate, "%1", "Pages");
			StandardNamePage  = StrReplace(ItemNameTemplate, "%1", "PageStandard");
			RandomNamePage = StrReplace(ItemNameTemplate, "%1", "PageCustom");
			
			// Attributes.
			QuickSettingsAddAttribute(Other.FillingParameters, ValueName,      "StandardPeriod");
			QuickSettingsAddAttribute(Other.FillingParameters, PeriodKindName,    "EnumRef.AvailableReportPeriods");
			QuickSettingsAddAttribute(Other.FillingParameters, AuthorPresentationActualName, "String");
			
			// Period kind - Item.
			ItemPeriodType = Items.Add(PeriodKindName, Type("FormField"), Group);
			ItemPeriodType.Type                      = FormFieldType.InputField;
			ItemPeriodType.Title                = SettingProperty.Presentation;
			ItemPeriodType.ListChoiceMode      = True;
			ItemPeriodType.HorizontalStretch = False;
			ItemPeriodType.Width                   = 11;
			ItemPeriodType.TitleLocation       = FormItemTitleLocation.None;
			ItemPeriodType.SetAction("OnChange", "Attachable_StandardPeriod_Kind_OnChange");
			
			// Period kind - Selection list.
			MinimalPeriodicity = Form.ReportSettings.AccordanceFrequencySettings[SettingProperty.DCField];
			If MinimalPeriodicity = Undefined Then
				MinimalPeriodicity = Enums.AvailableReportPeriods.Day;
			EndIf;
			
			AvailablePeriods = ReportsClientServer.GetAvailablePeriodsList();
			For IndexOf = AvailablePeriods.Find(MinimalPeriodicity) To AvailablePeriods.UBound() Do
				ItemPeriodType.ChoiceList.Add(AvailablePeriods[IndexOf]);
			EndDo;
			
			// Pages.
			PagesGroup = Items.Add(PagesName, Type("FormGroup"), Group);
			PagesGroup.Type                = FormGroupType.Pages;
			PagesGroup.PagesRepresentation = FormPagesRepresentation.None;
			PagesGroup.Width = 24;
			PagesGroup.HorizontalStretch = False;
			
			
			// Page StandardPeriod.
			PageStandardPeriod = Items.Add(StandardNamePage, Type("FormGroup"), PagesGroup);
			PageStandardPeriod.Type                 = FormGroupType.Page;
			PageStandardPeriod.Group         = ChildFormItemsGroup.AlwaysHorizontal;
			PageStandardPeriod.ShowTitle = False;
			
			// Page Custom.
			PageCustomPeriod = Items.Add(RandomNamePage, Type("FormGroup"), PagesGroup);
			PageCustomPeriod.Type                 = FormGroupType.Page;
			PageCustomPeriod.Group         = ChildFormItemsGroup.AlwaysHorizontal;
			PageCustomPeriod.ShowTitle = False;
			
			// Standard period.
			Period = Items.Add(AuthorPresentationActualName, Type("FormField"), PageStandardPeriod);
			Period.Type       = FormFieldType.InputField;
			Period.Title = NStr("en='Accounting period';ru='отчетный период';vi='Kỳ báo cáo'");
			Period.HorizontalStretch = True;
			Period.ChoiceButton   = True;
			Period.OpenButton = False;
			Period.ClearButton  = False;
			Period.SpinButton  = False;
			Period.TextEdit = False;
			Period.TitleLocation   = FormItemTitleLocation.None;
			Period.SetAction("Clearing",      "Attachable_StandardPeriod_Value_Clearing");
			Period.SetAction("StartChoice", "Attachable_StandardPeriod_Value_StartChoice");
			
			// Begin custom period.
			BeginOfPeriod = Items.Add(BeginOfPeriodName, Type("FormField"), PageCustomPeriod);
			BeginOfPeriod.Type    = FormFieldType.InputField;
			BeginOfPeriod.HorizontalStretch = True;
			BeginOfPeriod.ChoiceButton   = True;
			BeginOfPeriod.OpenButton = False;
			BeginOfPeriod.ClearButton  = False;
			BeginOfPeriod.SpinButton  = False;
			BeginOfPeriod.TextEdit = True;
			BeginOfPeriod.TitleLocation   = FormItemTitleLocation.None;
			BeginOfPeriod.SetAction("OnChange", "Attachable_StandardPeriod_BeginOfPeriod_OnChange");
			
			If SettingProperty.Type = "SettingsParameterValue" Then
				BeginOfPeriod.AutoMarkIncomplete = SettingProperty.AvailableKDSetting.DenyIncompleteValues;
			EndIf;
			
			Dash = Items.Add(DecorationName, Type("FormDecoration"), PageCustomPeriod);
			Dash.Type       = FormDecorationType.Label;
			Dash.Title = Char(8211); // Medium dash (en dash).
			
			// End custom period.
			EndOfPerioding = Items.Add(EndOfPeriodName, Type("FormField"), PageCustomPeriod);
			EndOfPerioding.Type = FormFieldType.InputField;
			FillPropertyValues(EndOfPerioding, BeginOfPeriod, "HorizontalStretch, Width, TitleLocation, TextEdit, ChoiceButton, OpenButton, ClearButton, SpinButton, AutoMarkIncomplete");
			EndOfPerioding.SetAction("OnChange", "Attachable_StandardPeriod_EndOfPeriod_OnChange");
			
			// Values.
			BeginOfPeriod = SettingProperty.Value.StartDate;
			EndOfPeriod  = SettingProperty.Value.EndDate;
			PeriodKind    = ReportsClientServer.GetKindOfStandardPeriod(SettingProperty.Value, ItemPeriodType.ChoiceList);
			Presentation = ReportsClientServer.PresentationStandardPeriod(SettingProperty.Value, PeriodKind);
			
			Additionally = New Structure;
			Additionally.Insert("ValueName",        ValueName);
			Additionally.Insert("PeriodKindName",      PeriodKindName);
			Additionally.Insert("BeginOfPeriodName",    BeginOfPeriodName);
			Additionally.Insert("EndOfPeriodName", EndOfPeriodName);
			Additionally.Insert("AuthorPresentationActualName",   AuthorPresentationActualName);
			Additionally.Insert("PeriodKind",         PeriodKind);
			Additionally.Insert("Presentation",      Presentation);
			SettingProperty.Additionally = Additionally;
			Other.AddedStandardPeriods.Add(SettingProperty);
			
			// Activation page.
			If PeriodKind = Enums.AvailableReportPeriods.Custom Then
				PagesGroup.CurrentPage = PageCustomPeriod;
			Else
				PagesGroup.CurrentPage = PageStandardPeriod;
			EndIf;
			
		ElsIf SettingProperty.ItemsType = "ListWithSelection" Then
			
			Group.Group = ChildFormItemsGroup.Vertical;
			
			OutputItem.Size = 5;
			OutputItem.ItemName1 = GroupName;
			
			HeaderNameGroup = StrReplace(ItemNameTemplate, "%1", "GroupHeader");
			DecorationName       = StrReplace(ItemNameTemplate, "%1", "Decoration");
			TableName              = StrReplace(ItemNameTemplate, "%1", "ValueList");
			ColumnsGroupName        = StrReplace(ItemNameTemplate, "%1", "ColumnGroup");
			ColumnUsageName = StrReplace(ItemNameTemplate, "%1", "Column_Use");
			ValueNameColumn      = StrReplace(ItemNameTemplate, "%1", "Column_Value");
			CommandPanelName = StrReplace(ItemNameTemplate, "%1", "CommandBar");
			CompleteNameButton    = StrReplace(ItemNameTemplate, "%1", "Pick");
			InsertNameButton  = StrReplace(ItemNameTemplate, "%1", "InsertFromBuffer");
			
			Other.MainFormAttributesNames.Insert(SettingProperty.ItemIdentificator, TableName);
			Other.NamesOfElementsForLinksSetup.Insert(SettingProperty.ItemIdentificator, ValueNameColumn);
			
			If Not SettingProperty.DisplayCheckbox Or Not SettingProperty.LimitChoiceWithSpecifiedValues Then
				
				// Group row for the title and command panel table.
				TableHeaderGroup = Items.Add(HeaderNameGroup, Type("FormGroup"), Group);
				TableHeaderGroup.Type                 = FormGroupType.UsualGroup;
				TableHeaderGroup.Group         = ChildFormItemsGroup.HorizontalIfPossible;
				TableHeaderGroup.Representation         = UsualGroupRepresentation.None;
				TableHeaderGroup.ShowTitle = False;
				
				// Check box is already created.
				If SettingProperty.DisplayCheckbox Then
					Items.Move(CheckBox, TableHeaderGroup);
				EndIf;
				
				// Title / Empty decoration.
				EmptyDecoration = Items.Add(DecorationName, Type("FormDecoration"), TableHeaderGroup);
				EmptyDecoration.Type                      = FormDecorationType.Label;
				EmptyDecoration.Title                = ?(SettingProperty.DisplayCheckbox, " ", SettingProperty.Presentation + ":");
				EmptyDecoration.HorizontalStretch = True;
				
				// Buttons.
				If Not SettingProperty.LimitChoiceWithSpecifiedValues Then
					If TypeInformation.ContainsReferenceTypes Then
						CommandPickUp = Form.Commands.Add(CompleteNameButton);
						CommandPickUp.Action    = "Attachable_ListWithPickup_Pickup";
						CommandPickUp.Title   = NStr("en='Select';ru='Подобрать';vi='Chọn'");
						CommandPickUp.Representation = ButtonRepresentation.Text;
					Else
						CommandPickUp = Form.Commands.Add(CompleteNameButton);
						CommandPickUp.Action    = "Attachable_ListWithSelection_Add";
						CommandPickUp.Title   = NStr("en='Add';ru='Добавить';vi='Thêm'");
						CommandPickUp.Representation = ButtonRepresentation.Text;
						CommandPickUp.Picture    = PictureLib.CreateListItem;
					EndIf;
					
					ButtonPickUp = Items.Add(CompleteNameButton, Type("FormButton"), TableHeaderGroup);
					ButtonPickUp.CommandName = CompleteNameButton;
					ButtonPickUp.Type = FormButtonType.Hyperlink;
					
					If Other.HasDataLoadFromFile Then
						InsertCommand = Form.Commands.Add(InsertNameButton);
						InsertCommand.Action    = "Attachable_ListWithSelection_InsertFromBuffer";
						InsertCommand.Title   = NStr("en='Insert from clipboard...';ru='Вставить из буфера обмена...';vi='Chèn từ bộ đệm trao đổi...'");
						InsertCommand.Picture    = PictureLib.FillForm;
						InsertCommand.Representation = ButtonRepresentation.Picture;
						
						InsertButton = Items.Add(InsertNameButton, Type("FormButton"), TableHeaderGroup);
						InsertButton.CommandName = InsertNameButton;
						InsertButton.Type = FormButtonType.Hyperlink;
					EndIf;
				EndIf;
				
			EndIf;
			
			// Attribute.
			QuickSettingsAddAttribute(Other.FillingParameters, TableName, "ValueList");
			
			// Group with indent and table.
			GroupWithIndent = Items.Add(GroupName + "Indent", Type("FormGroup"), Group);
			GroupWithIndent.Type                 = FormGroupType.UsualGroup;
			GroupWithIndent.Group         = ChildFormItemsGroup.HorizontalIfPossible;
			GroupWithIndent.Representation         = UsualGroupRepresentation.None;
			GroupWithIndent.Title           = SettingProperty.Presentation;
			GroupWithIndent.ShowTitle = False;
			
			// Indent decoration.
			EmptyDecoration = Items.Add(DecorationName + "Indent", Type("FormDecoration"), GroupWithIndent);
			EmptyDecoration.Type                      = FormDecorationType.Label;
			EmptyDecoration.Title                = "     ";
			EmptyDecoration.HorizontalStretch = False;
			
			// Table.
			FormTable = Items.Add(TableName, Type("FormTable"), GroupWithIndent);
			FormTable.Representation               = TableRepresentation.List;
			FormTable.Title                 = SettingProperty.Presentation;
			FormTable.TitleLocation        = FormItemTitleLocation.None;
			FormTable.CommandBarLocation  = FormItemCommandBarLabelLocation.None;
			FormTable.VerticalLines         = False;
			FormTable.HorizontalLines       = False;
			FormTable.Header                     = False;
			FormTable.Footer                    = False;
			FormTable.ChangeRowOrder      = True;
			FormTable.HorizontalStretch  = True;
			FormTable.VerticalStretch    = True;
			FormTable.Height                    = 3;
			
			If SettingProperty.DisplayCheckbox Then
				// For platform 8.3.5 and less.
				Instruction = ReportsVariants.ConditionalDesignInstruction();
				Instruction.Fields = TableName + "," + ColumnUsageName + "," + ValueNameColumn;
				Instruction.Filters.Insert(CheckBox.DataPath, False);
				Instruction.Appearance.Insert("TextColor", StyleColors.InaccessibleDataColor);
				ReportsVariants.AddConditionalAppearanceElement(Form, Instruction);
				
				If Not SettingProperty.DCUsersSetting.Use Then
					FormTable.TextColor = Form.InactiveTableValuesColor;
				EndIf;
			EndIf;
			
			// Group of the in cell columns.
			ColumnGroup = Items.Add(ColumnsGroupName, Type("FormGroup"), FormTable);
			ColumnGroup.Type         = FormGroupType.ColumnGroup;
			ColumnGroup.Group = ColumnsGroup.InCell;
			
			// Use column.
			ColumnUseItem = Items.Add(ColumnUsageName, Type("FormField"), ColumnGroup);
			ColumnUseItem.Type = FormFieldType.CheckBoxField;
			
			// Value column.
			ElementValueColumn = Items.Add(ValueNameColumn, Type("FormField"), ColumnGroup);
			ElementValueColumn.Type = FormFieldType.InputField;
			
			FillPropertyValues(ElementValueColumn, SettingProperty.AvailableKDSetting, "QuickSelection, Mask, ChoiceForm, EditFormat");
			
			ElementValueColumn.ChoiceFoldersAndItems = SettingProperty.ChoiceFoldersAndItems;
			
			If SettingProperty.LimitChoiceWithSpecifiedValues Then
				ElementValueColumn.ReadOnly = True;
			EndIf;
			
			// Fill names of the metadata objects in the profiles of items types and identifiers (for the preset).
			// Used after clicking the Selection button to receive selection form name.
			If ValueIsFilled(ElementValueColumn.ChoiceForm) Then
				Other.MapMetadataObjectName.Insert(SettingProperty.ItemIdentificator, ElementValueColumn.ChoiceForm);
			EndIf;
			
			// Fixed selection parameters.
			If SettingProperty.ChoiceParameters.Count() > 0 Then
				ElementValueColumn.ChoiceParameters = New FixedArray(SettingProperty.ChoiceParameters);
			EndIf;
			
			Additionally = New Structure;
			Additionally.Insert("TableName",              TableName);
			Additionally.Insert("ColumnNameValue",      ValueNameColumn);
			Additionally.Insert("ColumnNameUse", ColumnUsageName);
			SettingProperty.Additionally = Additionally;
			Other.AddedValueLists.Add(SettingProperty);
			
		EndIf;
	EndIf;
	
	If OutputItem.ItemName1 = Undefined Then
		TitleActualName = StrReplace(ItemNameTemplate, "%1", "Title");
		LabelField = Items.Add(TitleActualName, Type("FormDecoration"), Items.NotSorted);
		LabelField.Type       = FormDecorationType.Label;
		LabelField.Title = SettingProperty.Presentation + ":";
		OutputItem.ItemName1 = TitleActualName;
	EndIf;
	
	If SettingProperty.ItemsType = "StandardPeriod" Then
		OutputGroup.Order.Insert(0, OutputItem);
	Else
		OutputGroup.Order.Add(OutputItem);
	EndIf;
	OutputGroup.Size = OutputGroup.Size + OutputItem.Size;
	
EndProcedure

Procedure QuickSettingsAddAttribute(FillingParameters, AttributeFullName, AttributeType)
	If TypeOf(AttributeType) = Type("TypeDescription") Then
		AddedTypes = AttributeType;
	ElsIf TypeOf(AttributeType) = Type("String") Then
		AddedTypes = New TypeDescription(AttributeType);
	ElsIf TypeOf(AttributeType) = Type("Array") Then
		AddedTypes = New TypeDescription(AttributeType);
	ElsIf TypeOf(AttributeType) = Type("Type") Then
		TypeArray = New Array;
		TypeArray.Add(AttributeType);
		AddedTypes = New TypeDescription(TypeArray);
	Else
		Return;
	EndIf;
	
	ExistingTypes = FillingParameters.Attributes.Existing.Get(AttributeFullName);
	If TypeDescriptionsMatch(ExistingTypes, AddedTypes) Then
		FillingParameters.Attributes.Existing.Delete(AttributeFullName);
	Else
		DotPosition = Find(AttributeFullName, ".");
		If DotPosition = 0 Then
			PathToAttribute = "";
			ShortAttributeName = AttributeFullName;
		Else
			PathToAttribute = Left(AttributeFullName, DotPosition - 1);
			ShortAttributeName = Mid(AttributeFullName, DotPosition + 1);
		EndIf;
		
		FillingParameters.Attributes.Adding.Add(New FormAttribute(ShortAttributeName, AddedTypes, PathToAttribute));
		If ExistingTypes <> Undefined Then
			FillingParameters.Attributes.ToDelete.Add(AttributeFullName);
			FillingParameters.Attributes.Existing.Delete(AttributeFullName);
		EndIf;
	EndIf;
EndProcedure

Procedure PutInOrder(Form, OutputGroup, Parent, ColumnsCount, FlexibleBalancing = True) Export
	Items = Form.Items;
	If FlexibleBalancing Then
		If OutputGroup.Size <= 7 Then
			ColumnsCount = 1;
		EndIf;
	EndIf;
	
	ParentName = Parent.Name;
	
	ColumnNumber = 0;
	ButtonsLeft = ColumnsCount + 1;
	TotalLeftPlace = OutputGroup.Size;
	PlaceLeftInColumn = 0;
	
	For Each OutputItem IN OutputGroup.Order Do
		If ButtonsLeft > 0
			AND OutputItem.Size > PlaceLeftInColumn*4 Then // The current step is bigger than the left place.
			ColumnNumber = ColumnNumber + 1;
			ButtonsLeft = ButtonsLeft - 1;
			PlaceLeftInColumn = TotalLeftPlace/ButtonsLeft;
			
			UpperLevelColumn = Items.Add(ParentName + ColumnNumber, Type("FormGroup"), Items[ParentName]);
			UpperLevelColumn.Type                 = FormGroupType.UsualGroup;
			UpperLevelColumn.Group         = ChildFormItemsGroup.Vertical;
			UpperLevelColumn.Representation         = UsualGroupRepresentation.None;
			UpperLevelColumn.ShowTitle = False;
			
			SubgroupNumber = 0;
			CurrentGroup1 = Undefined;
			CurrentGroup2 = Undefined;
		EndIf;
		
		If OutputItem.ItemName2 = Undefined Then // Output in one column.
			If CurrentGroup2 <> Undefined Then
				CurrentGroup2 = Undefined;
			EndIf;
			Items.Move(Items[OutputItem.ItemName1], UpperLevelColumn);
		Else
			If CurrentGroup2 = Undefined Then
				SubgroupNumber = SubgroupNumber + 1;
				
				Columns = Items.Add(ParentName + ColumnNumber + "_" + SubgroupNumber, Type("FormGroup"), UpperLevelColumn);
				Columns.Type                 = FormGroupType.UsualGroup;
				Columns.Group         = ChildFormItemsGroup.AlwaysHorizontal;
				Columns.Representation         = UsualGroupRepresentation.None;
				Columns.ShowTitle = False;
				
				CurrentGroup1 = Items.Add(ParentName + ColumnNumber + "_" + SubgroupNumber + "_1", Type("FormGroup"), Columns);
				CurrentGroup1.Type                 = FormGroupType.UsualGroup;
				CurrentGroup1.Group         = ChildFormItemsGroup.Vertical;
				CurrentGroup1.Representation         = UsualGroupRepresentation.None;
				CurrentGroup1.ShowTitle = False;
				CurrentGroup1.United = False;
				
				CurrentGroup2 = Items.Add(ParentName + ColumnNumber + "_" + SubgroupNumber + "_2", Type("FormGroup"), Columns);
				CurrentGroup2.Type                 = FormGroupType.UsualGroup;
				CurrentGroup2.Group         = ChildFormItemsGroup.Vertical;
				CurrentGroup2.Representation         = UsualGroupRepresentation.None;
				CurrentGroup2.ShowTitle = False;
				CurrentGroup2.United = False;
				
			EndIf;
			Items.Move(Items[OutputItem.ItemName1], CurrentGroup1);
			Items.Move(Items[OutputItem.ItemName2], CurrentGroup2);
		EndIf;
		
		TotalLeftPlace = TotalLeftPlace - OutputItem.Size;
		PlaceLeftInColumn = PlaceLeftInColumn - OutputItem.Size;
	EndDo;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Save form state

Function RememberSelectedRows(Form, TableName, KeyColumns) Export
	TableAttribute = Form[TableName];
	ItemTable = Form.Items[TableName];
	
	Result = New Structure;
	Result.Insert("Selected", New Array);
	Result.Insert("Current", Undefined);
	
	CurrentIdentifier = ItemTable.CurrentRow;
	If CurrentIdentifier <> Undefined Then
		TableRow = TableAttribute.FindByID(CurrentIdentifier);
		If TableRow <> Undefined Then
			RowData = New Structure(KeyColumns);
			FillPropertyValues(RowData, TableRow);
			Result.Current = RowData;
		EndIf;
	EndIf;
	
	SelectedRows = ItemTable.SelectedRows;
	If SelectedRows <> Undefined Then
		For Each SelectedIdentifier IN SelectedRows Do
			If SelectedIdentifier = CurrentIdentifier Then
				Continue;
			EndIf;
			TableRow = TableAttribute.FindByID(SelectedIdentifier);
			If TableRow <> Undefined Then
				RowData = New Structure(KeyColumns);
				FillPropertyValues(RowData, TableRow);
				Result.Selected.Add(RowData);
			EndIf;
		EndDo;
	EndIf;
	
	Return Result;
EndFunction

Procedure RecallSelectedRows(Form, TableName, TableRows) Export
	TableAttribute = Form[TableName];
	ItemTable = Form.Items[TableName];
	
	ItemTable.SelectedRows.Clear();
	
	If TableRows.Current <> Undefined Then
		Found = FindTableRows(TableAttribute, TableRows.Current);
		If Found <> Undefined AND Found.Count() > 0 Then
			For Each TableRow IN Found Do
				If TableRow <> Undefined Then
					ID = TableRow.GetID();
					ItemTable.CurrentRow = ID;
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	For Each RowData IN TableRows.Selected Do
		Found = FindTableRows(TableAttribute, RowData);
		If Found <> Undefined AND Found.Count() > 0 Then
			For Each TableRow IN Found Do
				If TableRow <> Undefined Then
					ItemTable.SelectedRows.Add(TableRow.GetID());
				EndIf;
			EndDo;
		EndIf;
	EndDo;
EndProcedure

Function FindTableRows(TableAttribute, RowData)
	If TypeOf(TableAttribute) = Type("FormDataCollection") Then // Values table.
		Return TableAttribute.FindRows(RowData);
	ElsIf TypeOf(TableAttribute) = Type("FormDataTree") Then // Values tree.
		Return FindRecursively(TableAttribute.GetItems(), RowData);
	Else
		Return Undefined;
	EndIf;
EndFunction

Function FindRecursively(RowsSet, RowData, Found = Undefined)
	If Found = Undefined Then
		Found = New Array;
	EndIf;
	For Each TableRow IN RowsSet Do
		ValuesMatch = True;
		For Each KeyAndValue IN RowData Do
			If TableRow[KeyAndValue.Key] <> KeyAndValue.Value Then
				ValuesMatch = False;
				Break;
			EndIf;
		EndDo;
		If ValuesMatch Then
			Found.Add(TableRow);
		EndIf;
		FindRecursively(TableRow.GetItems(), RowData, Found);
	EndDo;
	Return Found;
EndFunction

#EndRegion

#Region UniversalReport

Procedure SetFixedFilters(StructureOfSelections, DCSettings, ReportSettings) Export
	If TypeOf(DCSettings) <> Type("DataCompositionSettings")
		Or StructureOfSelections = Undefined
		Or StructureOfSelections.Count() = 0 Then
		Return;
	EndIf;
	DCParameters = DCSettings.DataParameters;
	DCFilters = DCSettings.Filter;
	Inaccessible = DataCompositionSettingsItemViewMode.Inaccessible;
	For Each KeyAndValue In StructureOfSelections Do
		NAME = KeyAndValue.Key;
		Value = KeyAndValue.Value;
		If TypeOf(Value) = Type("FixedArray") Then
			Value = New Array(Value);
		EndIf;
		If TypeOf(Value) = Type("Array") Then
			List = New ValueList;
			List.LoadValues(Value);
			Value = List;
		EndIf;
		DCParameter = DCParameters.FindParameterValue(New DataCompositionParameter(NAME));
		If TypeOf(DCParameter) = Type("DataCompositionSettingsParameterValue") Then
			DCParameter.UserSettingID = "";
			DCParameter.Use    = True;
			DCParameter.ViewMode = Inaccessible;
			DCParameter.Value         = Value;
			Continue;
		EndIf;
		If TypeOf(Value) = Type("Structure") Then
			ComparisonTypeCD = CommonUseClientServer.StructureProperty(
				Value, "ComparisonType", DataCompositionComparisonType.Equal);
			Value = CommonUseClientServer.StructureProperty(Value, "RightValue");
		ElsIf TypeOf(Value) = Type("ValueList") Then
			ComparisonTypeCD = DataCompositionComparisonType.InList;
		Else
			ComparisonTypeCD = DataCompositionComparisonType.Equal;
		EndIf;
		CommonUseClientServer.SetFilterItem(DCFilters, NAME, Value, ComparisonTypeCD, , True, Inaccessible, "");
	EndDo;
EndProcedure

Function CountOfAvailableSettings(SettingsComposer) Export 
	AvailableSettings = New Structure;
	AvailableSettings.Insert("QuickAccess", 0);
	AvailableSettings.Insert("Typical", 0);
	AvailableSettings.Insert("Total", 0);
	
	UserSettings = SettingsComposer.UserSettings;
	For Each UserSettingsItem In UserSettings.Items Do 
		SettingItem = ReportsClientServer.GetObjectByUserIdentifier(
			SettingsComposer.Settings,
			UserSettingsItem.UserSettingID,,
			UserSettings);
		
		ViewMode = ?(SettingItem = Undefined,
			UserSettingsItem.ViewMode, SettingItem.ViewMode);
		
		If ViewMode = DataCompositionSettingsItemViewMode.Auto
			Or ViewMode = DataCompositionSettingsItemViewMode.QuickAccess Then 
			AvailableSettings.QuickAccess = AvailableSettings.QuickAccess + 1;
		ElsIf ViewMode = DataCompositionSettingsItemViewMode.Normal Then 
			AvailableSettings.Typical = AvailableSettings.Typical + 1;
		EndIf;
	EndDo;
	
	AvailableSettings.Total = AvailableSettings.QuickAccess + AvailableSettings.Typical;
	
	Return AvailableSettings;
EndFunction

Procedure UpdateSettingsFormItems(Form, ItemsHierarchyNode, UpdateParameters = Undefined) Export 
	If CommonUse.IsMobileClient() Then 
		Form.CreateUserSettingsFormElements(ItemsHierarchyNode);
		Return;
	EndIf;
	
	Items = Form.Items;
	ReportSettings = Form.ReportSettings;
	
	StyylizedItemsKinds = StrSplit("Period, List, CheckBox", ", ", False);
	AttributeNames = SettingsItemsAttributesNames(Form, StyylizedItemsKinds);
	
	PrepareFormToRegroupItems(Form, ItemsHierarchyNode, AttributeNames, StyylizedItemsKinds);
	
	TemporaryGroup = Items.Add("Temporary", Type("FormGroup"));
	TemporaryGroup.Type = FormGroupType.UsualGroup;
	
	Mode = DataCompositionSettingsViewMode.QuickAccess;
	If Form.ReportFormType = ReportFormType.Settings Then 
		Mode = DataCompositionSettingsViewMode.All;
	EndIf;
	
	Form.CreateUserSettingsFormItems(TemporaryGroup, Mode, 1);
	
	ItemsProperties = SettingsFormItemsProperties(
		Form.ReportFormType, Form.Report.SettingsComposer, ReportSettings);
	
	RegroupSettingsFormItems(
		Form, ItemsHierarchyNode, ItemsProperties, AttributeNames, StyylizedItemsKinds);
	
	Items.Delete(TemporaryGroup);
	
	// Вызов переопределяемого модуля.
	If ReportSettings.Events.AfterFillingQuickSettingsPanel Then
		ReportObject = ReportObject(ReportSettings.FullName);
		ReportObject.AfterFillingQuickSettingsPanel(Form, UpdateParameters);
	EndIf;
EndProcedure

Procedure RegroupSettingsFormItems(Form, Val ItemsHierarchyNode, ItemsProperties, AttributeNames, StyylizedItemsKinds)
	SettingsDescription = ItemsProperties.Fields.Copy(,
		"SettingIndex, SettingID, Settings, SettingItem, SettingDetails");
	
	SettingsItems = SettingsFormItems(Form, SettingsDescription, AttributeNames);
	SetSettingsFormItemsProperties(Form, SettingsItems, ItemsProperties);
	
	If Form.ReportFormType <> ReportFormType.Settings Then 
		SettingsItems.FillValues(False, "IsList");
	EndIf;
	
	TakeListToSeparateGroup(SettingsItems, ItemsProperties);
	
	GroupsIDs = ItemsProperties.Fields.Copy();
	GroupsIDs.GroupBy("GroupID");
	GroupsIDs = GroupsIDs.UnloadColumn("GroupID");
	
	Items = Form.Items;
	
	If GroupsIDs.Count() = 1 Then 
		ItemsHierarchyNode.Group = ChildFormItemsGroup.AlwaysHorizontal;
	Else
		ItemsHierarchyNode.Group = ChildFormItemsGroup.Vertical;
	EndIf;
	
	GroupNumber = 0;
	For Each GroupID In GroupsIDs Do 
		GroupNumber = GroupNumber + 1;
		
		GroupProperties = Undefined;
		If Not ValueIsFilled(GroupID)
			Or Not ItemsProperties.Groups.Property(GroupID, GroupProperties) Then 
			GroupProperties = FormItemsGroupProperties();
		EndIf;
		
		FoundHierarchyNode = Items.Find(GroupID);
		If FoundHierarchyNode <> Undefined Then 
			ItemsHierarchyNode = FoundHierarchyNode;
			GroupNumber = 1;
		EndIf;
		
		GroupName = ItemsHierarchyNode.Name + "Row" + GroupNumber;
		Group = ?(GroupsIDs.Count() = 1, ItemsHierarchyNode, Items.Find(GroupName));
		
		If Group = Undefined Then 
			Group = SettingsFormItemsGroup(Items, ItemsHierarchyNode, GroupName);
			Group.Title = "Row " + GroupNumber;
			FillPropertyValues(Group, GroupProperties,, "Group");
			Group.Group = ChildFormItemsGroup.AlwaysHorizontal;
		EndIf;
		
		SearchGroupFields = New Structure("GroupID", GroupID);
		GroupFieldsProperties = ItemsProperties.Fields.FindRows(SearchGroupFields);
		GroupSettingsItems = GroupSettingsItems(SettingsItems, GroupFieldsProperties);
		
		PrepareSettingsFormItemsToDistribution(GroupSettingsItems, GroupProperties.Group);
		DistributeSettingsFormItems(Form.Items, Group, GroupSettingsItems);
	EndDo;
	
	OutputStylizedSettingsFormItems(Form, SettingsItems, SettingsDescription, AttributeNames, StyylizedItemsKinds);
EndProcedure

Function GroupSettingsItems(SettingsItems, GroupFieldsProperties)
	GroupSettingsItems = SettingsItems.CopyColumns();
	
	SimplifiedForm = New Structure("SettingIndex");
	For Each Properties In GroupFieldsProperties Do 
		SimplifiedForm.SettingIndex = Properties.SettingIndex;
		FoundItems = SettingsItems.FindRows(SimplifiedForm);
		For Each Item In FoundItems Do 
			FillPropertyValues(GroupSettingsItems.Add(), Item);
		EndDo;
	EndDo;
	
	Return GroupSettingsItems;
EndFunction

Function SettingsFormItems(Form, SettingsDescription, AttributeNames)
	Items = Form.Items;
	
	SettingsItems = SettingsItemsCollectionPalette();
	FindSettingsFormItems(Form, Items.Temporary, SettingsItems, SettingsDescription);
	
	SummaryInfo = SettingsItems.Copy();
	SummaryInfo.GroupBy("SettingIndex", "CheckSum");
	IncompleteItems = SummaryInfo.FindRows(New Structure("CheckSum", 1));
	
	SimplifiedForm = New Structure("SettingIndex, SettingProperty");
	CommonProperties = "IsPeriod, IsFlag, IsList, ValueType, ChoiceForm, AvailableValues";
	
	For Each Record In IncompleteItems Do 
		Item = SettingsItems.Find(Record.SettingIndex, "SettingIndex");
		Item.Field.TitleLocation = FormItemTitleLocation.None;
		
		SourceProperty = "Value";
		LinkedProperty = "Use";
		If StrEndsWith(Item.Field.Name, LinkedProperty) Then 
			SourceProperty = "Use";
			LinkedProperty = "Value";
		EndIf;
		
		AdditionalItemName = StrReplace(Item.Field.Name, Item.SettingProperty, LinkedProperty);
		
		ItemGroup = Item.Field.Parent;
		If Items.Find(AdditionalItemName) <> Undefined
			Or ItemGroup.ChildItems.Find(AdditionalItemName) <> Undefined Then 
			Continue;
		EndIf;
		
		AdditionalItem = Items.Add(AdditionalItemName, Type("FormDecoration"), ItemGroup);
		AdditionalItem.Title = Item.Field.Title;
		AdditionalItem.AutoMaxHeight = False;
		
		AdditionalRecord = SettingsItems.Add();
		AdditionalRecord.Field = AdditionalItem;
		AdditionalRecord.SettingIndex = Record.SettingIndex;
		AdditionalRecord.SettingProperty = LinkedProperty;
		AdditionalRecord.CheckSum = 1;
		
		SimplifiedForm.SettingIndex = Record.SettingIndex;
		SimplifiedForm.SettingProperty = SourceProperty;
		LinkedItems = SettingsItems.FindRows(SimplifiedForm);
		FillPropertyValues(AdditionalRecord, LinkedItems[0], CommonProperties);
	EndDo;
	
	FindValuesAsCheckBoxes(Form, SettingsItems, AttributeNames);
	
	SettingsItems.Sort("SettingIndex");
	
	Return SettingsItems;
	
EndFunction

Function SettingsItemsCollectionPalette()
	NumberDetails = New TypeDescription("Number");
	RowDescription = New TypeDescription("String");
	FlagDetails = New TypeDescription("Boolean");
	
	SettingsItems = New ValueTable;
	SettingsItems.Columns.Add("Priority", NumberDetails);
	SettingsItems.Columns.Add("SettingIndex", NumberDetails);
	SettingsItems.Columns.Add("SettingProperty", RowDescription);
	SettingsItems.Columns.Add("Field");
	SettingsItems.Columns.Add("IsPeriod", FlagDetails);
	SettingsItems.Columns.Add("IsList", FlagDetails);
	SettingsItems.Columns.Add("IsFlag", FlagDetails);
	SettingsItems.Columns.Add("IsValueAsCheckBox", FlagDetails);
	SettingsItems.Columns.Add("ValueType");
	SettingsItems.Columns.Add("ChoiceForm", RowDescription);
	SettingsItems.Columns.Add("AvailableValues");
	SettingsItems.Columns.Add("CheckSum", NumberDetails);
	SettingsItems.Columns.Add("ColumnNumber", NumberDetails);
	SettingsItems.Columns.Add("GroupNumber", NumberDetails);
	
	Return SettingsItems;
EndFunction

// Выполняет поиск элементов формы, связанных с пользовательскими настройками отчета,
// созданных методом СоздатьЭлементыФормыПользовательскихНастроек.
// 
// Parameters:
// 	Form - ClientApplicationForm, ManagedFormExtensionForReports - where:
// 	  * Items - FormAllItems -
// 	  * Report - ReportObject - 
// 	GroupOfItems - FormGroup - 
// 	SettingsItems - See SettingsItemsCollectionPalette
// 	SettingsDescription - ValueTable - 
//
Procedure FindSettingsFormItems(Form, GroupOfItems, SettingsItems, SettingsDescription)
	UserSettings = Form.Report.SettingsComposer.UserSettings.Items;
	
	MainProperties = New Structure("Use, Value");
	For Each Item In GroupOfItems.ChildItems Do 
		If TypeOf(Item) = Type("FormGroup") Then 
			FindSettingsFormItems(Form, Item, SettingsItems, SettingsDescription);
		ElsIf TypeOf(Item) = Type("FormField") Then 
			SettingProperty = Undefined;
			SettingIndex = ReportsClientServer.SettingItemIndexByPath(Item.Name, SettingProperty);
			
			ItemSettingDetails = SettingsDescription.Find(SettingIndex, "SettingIndex");
			If ItemSettingDetails = Undefined Then 
				Continue;
			EndIf;
			
			Record = SettingsItems.Add();
			Record.SettingIndex = SettingIndex;
			Record.SettingProperty = SettingProperty;
			Record.Field = Item;
			
			SettingItem = ItemSettingDetails.SettingItem;
			SettingDetails = ItemSettingDetails.SettingDetails;
			
			If SettingDetails <> Undefined Then 
				FillPropertyValues(Record, SettingDetails, "ValueType, ChoiceForm, AvailableValues");
			EndIf;
			
			If TypeOf(SettingItem) = Type("DataCompositionSettingsParameterValue") Then 
				Record.IsPeriod = TypeOf(SettingItem.Value) = Type("StandardPeriod");
				Record.IsList = SettingDetails <> Undefined And SettingDetails.ValueListAllowed;
			ElsIf TypeOf(SettingItem) = Type("DataCompositionFilterItem") Then 
				Record.IsPeriod = TypeOf(SettingItem.RightValue) = Type("StandardPeriod");
				Record.IsFlag = ValueIsFilled(SettingItem.Presentation);
				
				UserSettingsItem = UserSettings.Find(
					ItemSettingDetails.SettingID);
				
				Record.IsList = Not Record.IsFlag
					And ReportsClientServer.IsListComparisonKind(UserSettingsItem.ComparisonType);
			ElsIf TypeOf(SettingItem) = Type("DataCompositionConditionalAppearanceItem") Then 
				Record.IsFlag = ValueIsFilled(SettingItem.Presentation)
					Or ValueIsFilled(SettingItem.UserSettingPresentation);
			EndIf;
			
			If MainProperties.Property(Record.SettingProperty) Then 
				Record.CheckSum = 1;
			EndIf;
		EndIf;
	EndDo;
EndProcedure

Procedure FindValuesAsCheckBoxes(Form, SettingsItems, AttributeNames)
	SimplifiedForm = New Structure;
	SimplifiedForm.Insert("ValueType", New TypeDescription("Boolean"));
	FoundItems = SettingsItems.Copy(SimplifiedForm);
	FoundItems.GroupBy("SettingIndex, ValueType", "CheckSum");
	
	FoundItems = FoundItems.FindRows(New Structure("CheckSum", 2));
	If FoundItems.Count() = 0 Then 
		Return;
	EndIf;
	
	SimplifiedForm = New Structure("SettingProperty, SettingIndex");
	For Each Item In FoundItems Do 
		SimplifiedForm.SettingProperty = "Use";
		SimplifiedForm.SettingIndex = Item.SettingIndex;
		
		CheckBoxItem = SettingsItems.FindRows(SimplifiedForm);
		If CheckBoxItem.Count() = 0 Then 
			Continue;
		EndIf;
		
		CheckBoxItem = CheckBoxItem[0];
		If TypeOf(CheckBoxItem.Field) <> Type("FormDecoration") Then 
			Continue;
		EndIf;
		
		SimplifiedForm.SettingProperty = "Value";
		
		ValueItem = SettingsItems.FindRows(SimplifiedForm);
		If ValueItem.Count() = 0 Then 
			Continue;
		EndIf;
		
		CheckBoxItem.SettingProperty = "Value";
		CheckBoxItem.IsFlag = True;
		CheckBoxItem.IsValueAsCheckBox = True;
		
		ValueItem = ValueItem[0];
		ValueItem.SettingProperty = "Use";
		ValueItem.IsFlag = True;
		ValueItem.IsValueAsCheckBox = True;
		ValueItem.Field.Visible = False;
	EndDo;
EndProcedure

// Переопределяет при необходимости свойства элементов формы, связанных с настройками:
// видимость, Ширина, РастягиватьПоГоризонтали и др.
// 
// Parameters:
// 	Form - ClientApplicationForm, ManagedFormExtensionForReports - 
// 	SettingsItems - See SettingsItemsCollectionPalette
// 	ItemsProperties - Structure - Contains:
//    * Groups - Structure -
//    * Fields - ValueTable -
//
Procedure SetSettingsFormItemsProperties(Form, SettingsItems, ItemsProperties)
	SettingsComposer = Form.Report.SettingsComposer;
	
	#Region SetItemsPropertiesUsage
	
	Exceptions = New Array;
	Exceptions.Add(DataCompositionComparisonType.Equal);
	Exceptions.Add(DataCompositionComparisonType.Contains);
	Exceptions.Add(DataCompositionComparisonType.Filled);
	Exceptions.Add(DataCompositionComparisonType.Like);
	Exceptions.Add(DataCompositionComparisonType.InList);
	Exceptions.Add(DataCompositionComparisonType.InListByHierarchy);
	
	FoundItems = SettingsItems.FindRows(New Structure("SettingProperty", "Use"));
	For Each Item In FoundItems Do 
		Field = Item.Field; // ПолеФормы
		FieldProperties = ItemsProperties.Fields.Find(Item.SettingIndex, "SettingIndex");
		
		If ValueIsFilled(FieldProperties.Presentation) Then 
			Field.Title = FieldProperties.Presentation;
		EndIf;
		
		If TypeOf(Field) = Type("FormField") Then 
			Field.TitleLocation = FormItemTitleLocation.Right;
			Field.SetAction("OnChange", "Attachable_SettingItem_OnChange");
		ElsIf TypeOf(Field) = Type("FormDecoration") Then 
			Field.Visible = (FieldProperties.TitleLocation <> FormItemTitleLocation.None);
		EndIf;
		
		If StrLen(Field.Title) > 40 Then
			Field.TitleHeight = 2;
		EndIf;
		
		SettingItem = FieldProperties.SettingItem;
		If TypeOf(SettingItem) = Type("DataCompositionSettingsParameterValue") Then 
			Field.Title = Field.Title + ":";
		ElsIf TypeOf(SettingItem) = Type("DataCompositionFilterItem") Then 
			If Exceptions.Find(SettingItem.ComparisonType) <> Undefined Then 
				Field.Title = Field.Title + ":";
			ElsIf Not ValueIsFilled(SettingItem.Presentation) Then 
				Field.Title = Field.Title + " (" + Lower(SettingItem.ComparisonType) + "):";
			EndIf;
		EndIf;
	EndDo;
	
	#EndRegion
	
	#Region SetItemsPropertiesSettingsItems
	
	FoundItems = SettingsItems.FindRows(New Structure("SettingProperty", "ComparisonType"));
	For Each Item In FoundItems Do
		Field = Item.Field; // ПолеФормы 
		Field.Visible = False;
	EndDo;
	
	#EndRegion
	
	#Region SetItemsPropertiesValue
	
	SelectionParameters = New Map;
	ExtendedTypesDetails = New Map;
	
	FoundItems = SettingsItems.FindRows(New Structure("SettingProperty", "Value"));
	For Each Item In FoundItems Do 
		Field = Item.Field; // ПолеФормы
		
		If TypeOf(Field) = Type("FormDecoration") Then 
			Field.Title = "     ";
			
			SimplifiedForm = New Structure("SettingIndex, SettingProperty", Item.SettingIndex, "Use");
			FoundLinkedItems = SettingsItems.FindRows(SimplifiedForm);
			
			LinkedField = FoundLinkedItems.Get(0).Field; // ПолеФормы
			If StrEndsWith(LinkedField.Title, ":") Then 
				LinkedField.Title = Left(LinkedField.Title, StrLen(LinkedField.Title) - 1);
			EndIf;
		Else // Поле ввода.
			FieldProperties = ItemsProperties.Fields.Find(Item.SettingIndex, "SettingIndex");
			FillPropertyValues(Field, FieldProperties,, "TitleLocation");
			
			If Item.IsFlag Then 
				Item.Field.Visible = False;
				Continue;
			EndIf;
			
			Field.SetAction("OnChange", "Attachable_SettingItem_OnChange");
			If Item.IsList Then
				Field.SetAction("StartChoice", "Attachable_SettingItem_StartChoice");
			EndIf;
			
			Field.ChoiceForm = Item.ChoiceForm;
			If ValueIsFilled(Field.ChoiceForm) Then 
				SelectionParameters.Insert(Item.SettingIndex, Field.ChoiceForm);
			EndIf;
			
			Result = ReportsClientServer.ExpandList(
				Field.ChoiceList, Item.AvailableValues, False, True);
			Field.ListChoiceMode = Not Item.IsList And Result <> Undefined And Result.Total > 0;
			
			If Item.ValueType = Undefined Then 
				Continue;
			EndIf;
			
			ExtendedTypeDetails = ExtendedTypesDetails(Item.ValueType, True, SelectionParameters);
			ExtendedTypesDetails.Insert(Item.SettingIndex, ExtendedTypeDetails);
			
			Field.AvailableTypes = ExtendedTypeDetails.TypeDescriptionForForm;
			Field.TypeRestriction = ExtendedTypeDetails.TypeDescriptionForForm;
			
			If StrLen(Field.Title) > 40 Then
				Field.TitleHeight = 2;
			EndIf;
			
			If Field.HorizontalStretch = Undefined Then
				Field.HorizontalStretch = True;
				Field.AutoMaxWidth = False;
				Field.MaxWidth = 40;
			EndIf;
			
			If ExtendedTypeDetails.TypeCount = 1 Then 
				If ExtendedTypeDetails.ContainsTypeNumber Then 
					Field.ChoiceButton = True;
					If Field.HorizontalStretch = True Then
						Field.HorizontalStretch = False;
					EndIf;
				ElsIf ExtendedTypeDetails.ContainsTypeDate Then 
					Field.MaxWidth = 25;
				ElsIf ExtendedTypeDetails.ContainsTypeBoolean Then 
					Field.MaxWidth = 5;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
	AdditionalProperties = SettingsComposer.Settings.AdditionalProperties;
	AdditionalProperties.Insert("SelectionParameters", SelectionParameters);
	AdditionalProperties.Insert("ExtendedTypesDetails", ExtendedTypesDetails);
	
	#EndRegion
EndProcedure

// Выделяет группу для списка, ссылающегося на настройку с видом сравнения:
// ВСписке, НеВСписке и т.д.
// 
// Parameters:
// 	SettingsItems - See SettingsItemsCollectionPalette
// 	ItemsProperties - Structure - Description:
//   * Groups - Structure - 
//   * Fields - ValueTable - 
//
Procedure TakeListToSeparateGroup(SettingsItems, ItemsProperties)
	SimplifiedForm = New Structure("IsList", True);
	Statistics = SettingsItems.Copy(SimplifiedForm);
	Statistics.GroupBy("SettingIndex");
	
	If Statistics.Count() <> 1 Then 
		Return;
	EndIf;
	
	SettingIndex = SettingsItems.FindRows(SimplifiedForm)[0].SettingIndex;
	FieldProperties = ItemsProperties.Fields.Find(SettingIndex, "SettingIndex");
	If ValueIsFilled(FieldProperties.GroupID) Then 
		Return;
	EndIf;
	
	GroupID = "_" + StrReplace(New UUID, "-", "");
	FieldProperties.GroupID = GroupID;
	ItemsProperties.Groups.Insert(GroupID, FormItemsGroupProperties());
EndProcedure

// Формирует коллекции имен реквизитов, сгруппированных по стилям: Период, Флажок, Список.
// 
// Parameters:
//   Form - ClientApplicationForm, ManagedFormExtensionForReports - 
//   ItemsKinds - Array of String - 
//
// Returns:
//   Structure - Contains:
//     * GeneratedItems - Structure -
//     * predefined - Structure -
//
Function SettingsItemsAttributesNames(Form, ItemsKinds)
	PredefinedItemsattributesNames = New Structure;
	GeneratedItemsAttributesNames = New Structure;
	
	For Each ItemKind In ItemsKinds Do 
		PredefinedItemsattributesNames.Insert(ItemKind, New Array);
		GeneratedItemsAttributesNames.Insert(ItemKind, New Array);
	EndDo;
	
	Attributes = Form.GetAttributes();
	For Each Attribute In Attributes Do 
		For Each ItemKind In ItemsKinds Do 
			If StrStartsWith(Attribute.Name, ItemKind)
				And StringFunctionsClientServer.OnlyNumbersInString(StrReplace(Attribute.Name, ItemKind, "")) Then 
				PredefinedItemsattributesNames[ItemKind].Add(Attribute.Name);
			EndIf;
			
			If StrStartsWith(Attribute.Name, "SettingsComposerUserSettingsItem")
				And StrEndsWith(Attribute.Name, ItemKind) Then 
				GeneratedItemsAttributesNames[ItemKind].Add(Attribute.Name);
			EndIf;
		EndDo;
	EndDo;
	
	AttributeNames = New Structure;
	AttributeNames.Insert("predefined", PredefinedItemsattributesNames);
	AttributeNames.Insert("GeneratedItems", GeneratedItemsAttributesNames);
	
	Return AttributeNames;
EndFunction

Procedure PrepareFormToRegroupItems(Form, ItemsHierarchyNode, AttributeNames, StyylizedItemsKinds)
	Items = Form.Items;
	
	// Перегруппировка предопределенных элементов формы.
	PredefinedItemsProperties = StrSplit("Indent, Pick, InsertFromBuffer", ", ", False);
	PredefinedItemsProperties.Add("");
	
	For Each ItemKind In StyylizedItemsKinds Do 
		PredefinedAttributesNames = AttributeNames.predefined[ItemKind];
		For Each AttributeName In PredefinedAttributesNames Do 
			For Each Property In PredefinedItemsProperties Do 
				FoundItem = Items.Find(AttributeName + Property);
				If FoundItem <> Undefined Then 
					Items.Move(FoundItem, Items.PredefinedSettingsItems);
					FoundItem.Visible = False;
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
	// Удаление динамических элементов формы.
	ItemsHierarchyNodes = New Array;
	ItemsHierarchyNodes.Add(ItemsHierarchyNode);
	
	FoundNode = Items.Find("Additionally");
	If FoundNode <> Undefined Then 
		ItemsHierarchyNodes.Add(FoundNode);
	EndIf;
	
	Exceptions = New Array;
	
	FoundNode = Items.Find("PredefinedSettings");
	If FoundNode <> Undefined Then 
		Exceptions.Add(FoundNode);
	EndIf;
	
	For Each CurrentNode In ItemsHierarchyNodes Do 
		HierarchyOfItems = CurrentNode.ChildItems;
		ItemIndex = HierarchyOfItems.Count() - 1;
		While ItemIndex >= 0 Do 
			HierarchyItem = HierarchyOfItems[ItemIndex];
			If Exceptions.Find(HierarchyItem) = Undefined Then 
				Items.Delete(HierarchyItem);
			EndIf;
			ItemIndex = ItemIndex - 1;
		EndDo;
	EndDo;
EndProcedure

Procedure DistributeSettingsFormItems(Items, Val Group, SettingsItems)
	ColumnsCount = 0;
	If SettingsItems.Count() > 0 Then 
		ColumnsCount = SettingsItems[SettingsItems.Count() - 1].ColumnNumber;
	EndIf;
	
	For ColumnNumber = 1 To ColumnsCount Do 
		ItemsFlags = SettingsItems.Copy(New Structure("ColumnNumber", ColumnNumber));
		ItemsFlags.GroupBy("IsFlag, IsList, GroupNumber");
		
		InputFieldsOnly = ItemsFlags.Find(True, "IsFlag") = Undefined
			And ItemsFlags.Find(True, "IsList") = Undefined;
		
		ColumnName = Group.Name + "Column" + ColumnNumber;
		Column = ?(ColumnsCount = 1, Group, Items.Find(ColumnName));
		If Column = Undefined Then 
			Column = SettingsFormItemsGroup(Items, Group, ColumnName);
			Column.Title = "Column " + ColumnNumber;
			
			If InputFieldsOnly Then 
				Column.Group = ChildFormItemsGroup.AlwaysHorizontal;
			EndIf;
		EndIf;
		
		If InputFieldsOnly Then 
			DistributeSettingsFormItemsByProperties(Items, Column, SettingsItems, ColumnNumber);
			Continue;
		EndIf;
		
		LineNumber = 0;
		For Each Flags In ItemsFlags Do 
			LineNumber = LineNumber + 1;
			Parent = SettingsFormItemsHierarchy(Items, Column, Flags, LineNumber, ColumnNumber);
			
			DistributeSettingsFormItemsByProperties(Items, Parent, SettingsItems, ColumnNumber, Flags.GroupNumber);
		EndDo;
	EndDo;
EndProcedure

Function SettingsFormItemsHierarchy(Items, Parent, Flags, LineNumber, ColumnNumber)
	RowName = Parent.Name + "Row" + LineNumber;
	Row = SettingsFormItemsGroup(Items, Parent, RowName);
	Row.Title = "Row " + ColumnNumber + "." + LineNumber;
	
	If Not Flags.IsList Then 
		Row.Group = ChildFormItemsGroup.AlwaysHorizontal;
	EndIf;
	
	If Flags.IsFlag Or Flags.IsList Then 
		Return Row;
	EndIf;
	
	ColumnName = Row.Name + "Column1";
	Column = SettingsFormItemsGroup(Items, Row, ColumnName);
	Column.Title = "Column " + ColumnNumber + "." + LineNumber + ".1";
	Column.Group = ChildFormItemsGroup.AlwaysHorizontal;
	
	Return Column;
EndFunction

Procedure DistributeSettingsFormItemsByProperties(Items, Parent, SettingsItems, ColumnNumber, GroupNumber = Undefined)
	SettingsProperties = StrSplit("Use, ComparisonType, Value", ", ", False);
	For Each SettingProperty In SettingsProperties Do 
		GroupName = Parent.Name + SettingProperty;
		Group = SettingsFormItemsGroup(Items, Parent, GroupName);
		Group.Title = SettingProperty;
		Group.Visible = (SettingProperty <> "ComparisonType");
		
		SimplifiedForm = New Structure("SettingProperty, ColumnNumber", SettingProperty, ColumnNumber);
		If GroupNumber <> Undefined Then 
			SimplifiedForm.Insert("GroupNumber", GroupNumber);
		EndIf;
		
		FoundItems = SettingsItems.FindRows(SimplifiedForm);
		For Each Item In FoundItems Do 
			Group.United = SettingProperty = "Use" And Item.IsList;
			Items.Move(Item.Field, Group);
		EndDo;
	EndDo;
EndProcedure

Function SettingsFormItemsProperties(FormType, SettingsComposer, AdditionalParameters) 
	#Region StructurePreparing
	
	ItemsProperties = New Structure("Groups, Fields");
	ItemsProperties.Groups = New Structure;
	
	RowDescription = New TypeDescription("String");
	NumberDetails = New TypeDescription("Number");
	
	Fields = New ValueTable;
	Fields.Columns.Add("SettingIndex", NumberDetails);
	Fields.Columns.Add("SettingID", RowDescription);
	Fields.Columns.Add("Settings");
	Fields.Columns.Add("SettingItem");
	Fields.Columns.Add("SettingDetails");
	Fields.Columns.Add("Presentation", RowDescription);
	Fields.Columns.Add("GroupID", RowDescription);
	Fields.Columns.Add("TitleLocation", New TypeDescription("FormItemTitleLocation"));
	Fields.Columns.Add("HorizontalStretch");
	Fields.Columns.Add("Width", NumberDetails);
	
	AvailableModes = New Array;
	AvailableModes.Add(DataCompositionSettingsItemViewMode.QuickAccess);
	If FormType = ReportFormType.Settings Then 
		AvailableModes.Add(DataCompositionSettingsItemViewMode.Normal);
	EndIf;
	
	UnavailableStructureItems = New Map;
	UnavailableStructureItems.Insert(Type("DataCompositionGroup"), ReportFormType.Settings);
	UnavailableStructureItems.Insert(Type("DataCompositionTableGroup"), ReportFormType.Settings);
	UnavailableStructureItems.Insert(Type("DataCompositionChartGroup"), ReportFormType.Settings);
	UnavailableStructureItems.Insert(Type("DataCompositionTable"), ReportFormType.Settings);
	UnavailableStructureItems.Insert(Type("DataCompositionChart"), ReportFormType.Settings);
	
	#EndRegion
	
	#Region StructureFilling
	
	Information = UserSettingsInfo(SettingsComposer.Settings);
	UserSettings = SettingsComposer.UserSettings;
	For Each UserSettingsItem In UserSettings.Items Do 
		FoundInfo = Information[UserSettingsItem.UserSettingID];
		SettingItem = FoundInfo.SettingItem; // ГруппировкаКомпоновкиДанных, ГруппировкаТаблицыКомпоновкиДанных, ГруппировкаДиаграммыКомпоновкиДанных 
		
		If SettingItem = Undefined
			Or UnavailableStructureItems.Get(TypeOf(SettingItem)) = FormType
			Or AvailableModes.Find(SettingItem.ViewMode) = Undefined Then 
			Continue;
		EndIf;
		
		ItemType = TypeOf(SettingItem);
		If ItemType = Type("DataCompositionConditionalAppearanceItem") Then 
			Presentation = ReportsClientServer.ConditionalAppearanceItemPresentation(
				SettingItem, Undefined, "");
			
			If Not ValueIsFilled(SettingItem.Presentation) Then 
				SettingItem.Presentation = Presentation;
			ElsIf Not ValueIsFilled(SettingItem.UserSettingPresentation)
				And SettingItem.Presentation <> Presentation Then 
				
				SettingItem.UserSettingPresentation = SettingItem.Presentation;
				SettingItem.Presentation = Presentation;
			EndIf;
		EndIf;
		
		Field = Fields.Add();
		Field.SettingID = UserSettingsItem.UserSettingID;
		Field.SettingIndex = UserSettings.Items.IndexOf(UserSettingsItem);
		Field.Settings = FoundInfo.Settings;
		Field.SettingItem = SettingItem;
		Field.SettingDetails = FoundInfo.SettingDetails;
		Field.TitleLocation = FormItemTitleLocation.Auto;
		
		If UnavailableStructureItems.Get(TypeOf(SettingItem)) <> Undefined Then 
			Presentation = SettingItem.OutputParameters.Items.Find("TITLE");
			If Presentation <> Undefined
				And ValueIsFilled(Presentation.Value) Then 
				Field.Presentation = Presentation.Value;
			EndIf;
		EndIf;
		
		If FormType = ReportFormType.Settings
			And TypeOf(SettingItem) = Type("DataCompositionConditionalAppearanceItem") Then 
			Field.GroupID = "Additionally";
		EndIf;
	EndDo;
	
	If Fields.Find("Additionally", "GroupID") <> Undefined Then 
		ItemsProperties.Groups.Insert("Additionally", FormItemsGroupProperties());
	EndIf;
	
	Fields.Sort("SettingIndex");
	ItemsProperties.Fields = Fields;
	
	If AdditionalParameters.Events.OnDefineSettingsFormItemsProperties Then 
		ReportObject(AdditionalParameters.FullName).OnDefineSettingsFormItemsProperties(
			FormType, ItemsProperties, UserSettings.Items);
	EndIf;
	
	#EndRegion
	
	Return ItemsProperties;
EndFunction


Function FormItemsGroupProperties() Export 
	GroupProperties = New Structure;
	GroupProperties.Insert("Representation", UsualGroupRepresentation.None);
	GroupProperties.Insert("Group", ChildFormItemsGroup.HorizontalIfPossible);
	
	Return GroupProperties;
EndFunction

Function SettingsFormItemsGroup(Items, Parent, GroupName)
	Group = Items.Find(GroupName);
	If Group <> Undefined Then 
		Return Group;
	EndIf;
	
	Group = Items.Add(GroupName, Type("FormGroup"), Parent);
	Group.Type = FormGroupType.UsualGroup;
	Group.ShowTitle = False;
	Group.Representation = UsualGroupRepresentation.None;
	Group.Group = ChildFormItemsGroup.Vertical;
	
	Return Group;
EndFunction

Procedure PrepareSettingsFormItemsToDistribution(SettingsItems, Grouping)
	#Region BeforePreparation
	
	Statistics = SettingsItems.Copy();
	Statistics.GroupBy("SettingIndex");
	
	ColumnsCount = 1;
	If Grouping = ChildFormItemsGroup.HorizontalIfPossible Then 
		ColumnsCount = Min(2, Statistics.Count());
	ElsIf Grouping = ChildFormItemsGroup.AlwaysHorizontal Then 
		ColumnsCount = Statistics.Count();
	EndIf;
	ColumnsCount = Max(1, ColumnsCount);
	
	#EndRegion
	
	#Region SetPriority
	
	FoundItems = SettingsItems.FindRows(New Structure("IsPeriod", True));
	For Each Item In FoundItems Do 
		Item.Priority = -1;
	EndDo;
	
	SettingsItems.Sort("Priority, SettingIndex");
	
	#EndRegion
	
	#Region SetColumnsNumbers
	
	Statistics = SettingsItems.Copy();
	Statistics.GroupBy("Priority, SettingIndex");
	
	ItemCount = Statistics.Count();
	IndexOf = 0;
	PropertiesBorder = ItemCount - 1;
	
	Step = ItemCount / ColumnsCount;
	BreakBoundary = ?(ItemCount % ColumnsCount = 0, Step - 1, Int(Step));
	Step = ?(BreakBoundary = 0, 1, Int(Step));
	
	SimplifiedForm = New Structure("SettingIndex");
	For ColumnNumber = 1 To ColumnsCount Do 
		While IndexOf <= BreakBoundary Do 
			SimplifiedForm.SettingIndex = Statistics[IndexOf].SettingIndex;
			FoundItems = SettingsItems.FindRows(SimplifiedForm);
			For Each Item In FoundItems Do 
				Item.ColumnNumber = ColumnNumber;
			EndDo;
			IndexOf = IndexOf + 1;
		EndDo;
		
		BreakBoundary = BreakBoundary + Step;
		If BreakBoundary > PropertiesBorder Then 
			BreakBoundary = PropertiesBorder;
		EndIf;
	EndDo;
	
	DistributeListsByColumnsProportionally(SettingsItems, ColumnsCount);
	
	#EndRegion
	
	#Region SetGroupsNumbers
	
	SearchVariants = New Array;
	SearchVariants.Add(New Structure("GroupNumber, IsFlag, IsList", 0, False, False));
	SearchVariants.Add(New Structure("GroupNumber, IsFlag, IsList", 0, True, False));
	SearchVariants.Add(New Structure("GroupNumber, IsFlag, IsList", 0, False, True));
	
	GroupNumber = 1;
	For Each SimplifiedForm In SearchVariants Do 
		FoundItems = SettingsItems.FindRows(SimplifiedForm);
		
		PreviousIndex = Undefined;
		For Each Item In FoundItems Do 
			If Item.IsFlag Or Item.IsList Then 
				IndexOf = Item.SettingIndex;
			Else
				IndexOf = SettingsItems.IndexOf(Item);
			EndIf;
			
			If PreviousIndex = Undefined Then 
				PreviousIndex = IndexOf;
			EndIf;
			
			If ((Item.IsFlag Or Item.IsList) And IndexOf <> PreviousIndex)
				Or (Not Item.IsFlag And Not Item.IsList And IndexOf > PreviousIndex + 1) Then 
				GroupNumber = GroupNumber + 1;
			EndIf;
			
			Item.GroupNumber = GroupNumber;
			PreviousIndex = IndexOf;
		EndDo;
		
		GroupNumber = GroupNumber + 1;
	EndDo;
	
	#EndRegion
EndProcedure

Procedure OutputStylizedSettingsFormItems(Form, SettingsItems, SettingsDescription, AttributeNames, ItemsKinds)
	// Изменение реквизитов.
	PathToItemsData = New Structure("ByName, ByIndex", New Map, New Map);
	
	AttributesToAdd = SettingsItemsAttributesToAdd(SettingsItems, ItemsKinds, AttributeNames, PathToItemsData);
	AttributesToDelete = SettingsItemsAttributesToDelete(ItemsKinds, AttributeNames, PathToItemsData);
	
	Form.ChangeAttributes(AttributesToAdd, AttributesToDelete);
	DeleteSettingsItemsCommands(Form, AttributesToDelete);
	
	Form.PathToItemsData = PathToItemsData;
	
	// Изменение элементов.
	OutputSettingsPeriods(Form, SettingsItems, AttributeNames);
	OutputSettingsLists(Form, SettingsItems, SettingsDescription, AttributeNames);
	OutputValuesAsCheckBoxesFields(Form, SettingsItems, AttributeNames);
EndProcedure

Function SettingsItemsAttributesToAdd(SettingsItems, ItemsKinds, AttributeNames, PathToItemsData)
	AttributesToAdd = New Array;
	
	ItemsTypes = New Structure;
	ItemsTypes.Insert("Period", New TypeDescription("StandardPeriod"));
	ItemsTypes.Insert("List", New TypeDescription("ValueList"));
	ItemsTypes.Insert("CheckBox", New TypeDescription("Boolean"));
	
	ItemsKindsIndicators = New Structure("Period, List, CheckBox", "IsPeriod", "IsList", "IsValueAsCheckBox");
	ItemsKindsProperties = New Structure("Period, List, CheckBox", "Value", "Value", "Use");
	
	For Each ItemKind In ItemsKinds Do 
		SignOf = ItemsKindsIndicators[ItemKind];
		
		Generated = AttributeNames.GeneratedItems[ItemKind];
		Predefined = AttributeNames.predefined[ItemKind];
		
		PredefinedItemsIndex = -1;
		PredefinedItemsBorder = Predefined.UBound();
		
		SimplifiedForm = New Structure;
		SimplifiedForm.Insert(SignOf, True);
		SimplifiedForm.Insert("SettingProperty", "Value");
		
		FoundItems = SettingsItems.Copy(SimplifiedForm);
		For Each Item In FoundItems Do 
			If PredefinedItemsBorder >= FoundItems.IndexOf(Item) Then 
				PredefinedItemsIndex = PredefinedItemsIndex + 1;
				PathToItemsData.ByName.Insert(Predefined[PredefinedItemsIndex], Item.SettingIndex);
				PathToItemsData.ByIndex.Insert(Item.SettingIndex, Predefined[PredefinedItemsIndex]);
				Continue;
			EndIf;
			
			Field = Item.Field; // ПолеФормы
			ItemTitle = Field.Title;
			ItemNameTemplate = StrReplace(Field.Name, ItemsKindsProperties[ItemKind], "%1");
			
			AttributeName = StringFunctionsClientServer.SubstituteParametersInString(ItemNameTemplate, ItemKind);
			If Generated.Find(AttributeName) = Undefined Then 
				ItemType = Item.ValueType;
				ItemsTypes.Property(ItemKind, ItemType);
				
				AttributesToAdd.Add(New FormAttribute(AttributeName, ItemType,, ItemTitle));
			EndIf;
			
			PathToItemsData.ByName.Insert(AttributeName, Item.SettingIndex);
			PathToItemsData.ByIndex.Insert(Item.SettingIndex, AttributeName);
		EndDo;
	EndDo;
	
	Return AttributesToAdd;
EndFunction

Function SettingsItemsAttributesToDelete(ItemsKinds, AttributeNames, PathToItemsData)
	AttributesToDelete = New Array;
	
	For Each ItemKind In ItemsKinds Do 
		Generated = AttributeNames.GeneratedItems[ItemKind];
		For Each AttributeName In Generated Do 
			If PathToItemsData.ByName[AttributeName] = Undefined Then 
				AttributesToDelete.Add(AttributeName);
			EndIf;
		EndDo;
	EndDo;
	
	Return AttributesToDelete;
EndFunction

Procedure DeleteSettingsItemsCommands(Form, AttributesToDelete)
	CommandsSuffixes = StrSplit("SelectPeriod, Pick, InsertFromBuffer", ", ", False);
	
	For Each AttributeName In AttributesToDelete Do 
		For Each Suffix In CommandsSuffixes Do 
			Command = Form.Commands.Find(AttributeName + Suffix);
			If Command <> Undefined Then 
				Form.Commands.Delete(Command);
			EndIf;
		EndDo;
	EndDo;
EndProcedure


Procedure OutputSettingsPeriods(Form, SettingsItems, AttributeNames)
	FoundItems = SettingsItems.FindRows(New Structure("IsPeriod, SettingProperty", True, "Value"));
	If FoundItems.Count() = 0 Then 
		Return;
	EndIf;
	
	Items = Form.Items;
	PredefinedItemsattributesNames = AttributeNames.predefined.Period;
	
	For Each Item In FoundItems Do 
		LinkedItems = SettingsItems.FindRows(New Structure("SettingIndex", Item.SettingIndex));
		For Each LinkedItem In LinkedItems Do 
			LinkedItem.Field.Visible = (LinkedItem.SettingProperty = "Use");
		EndDo;
		
		InitializePeriod(Form, Item.SettingIndex);
		
		Field = Item.Field;
		Parent = Field.Parent; // ГруппаФормы
		
		NextItem = Undefined;
		ItemIndex = Parent.ChildItems.IndexOf(Field);
		If Parent.ChildItems.Count() > ItemIndex + 1 Then 
			NextItem = Parent.ChildItems.Get(ItemIndex + 1);
		EndIf;
		
		AttributeName = Form.PathToItemsData.ByIndex[Item.SettingIndex];
		If PredefinedItemsattributesNames.Find(AttributeName) <> Undefined Then 
			FoundItem = Items.Find(AttributeName);
			Items.Move(FoundItem, Parent, NextItem);
			FoundItem.Visible = True;
			Continue;
		EndIf;
		
		ItemNameTemplate = StrReplace(Field.Name, "Value", "%1%2");
		
		Group = PeriodItemsGroup(Items, Parent, NextItem, ItemNameTemplate, Field.Title);
		AddPeriodItem(Items, Group, ItemNameTemplate, "BeginDate", Field.Title);
		
		ItemName = StringFunctionsClientServer.SubstituteParametersInString(ItemNameTemplate, "Separator");
		Separator = Items.Find(ItemName);
		If Separator = Undefined Then 
			Separator = Items.Add(ItemName, Type("FormDecoration"), Group);
		EndIf;
		Separator.Type = FormDecorationType.Label;
		Separator.Title = Char(8211); // Среднее тире (en dash).
		
		AddPeriodItem(Items, Group, ItemNameTemplate, "EndDate", Field.Title);
		AddPeriodChoiceCommand(Form, Group, ItemNameTemplate);
	EndDo;
EndProcedure

Function PeriodItemsGroup(Items, Parent, NextItem, NamePattern, Title)
	ItemName = StringFunctionsClientServer.SubstituteParametersInString(NamePattern, "", "Period");
	
	Group = Items.Find(ItemName);
	If Group = Undefined Then 
		Group = Items.Add(ItemName, Type("FormGroup"), Parent);
	EndIf;
	Group.Type = FormGroupType.UsualGroup;
	Group.Representation = UsualGroupRepresentation.None;
	Group.Group = ChildFormItemsGroup.AlwaysHorizontal;
	Group.Title = Title;
	Group.ShowTitle = False;
	Group.EnableContentChange = False;
	
	If NextItem <> Undefined Then 
		Items.Move(Group, Parent, NextItem);
	EndIf;
	
	Return Group;
EndFunction

Procedure AddPeriodItem(Items, Group, NamePattern, Property, SettingItemTitle)
	ItemName = StringFunctionsClientServer.SubstituteParametersInString(NamePattern, "", Property);
	
	CaptionPattern = "%1 (date %2)";
	Title = StringFunctionsClientServer.SubstituteParametersInString(
		CaptionPattern, SettingItemTitle, ?(StrEndsWith(Property, "beginning"), "beginning", "end"));
	
	Item = Items.Find(ItemName);
	If Item = Undefined Then 
		Item = Items.Add(ItemName, Type("FormField"), Group);
	EndIf;
	Item.Type = FormFieldType.InputField;
	Item.DataPath = StringFunctionsClientServer.SubstituteParametersInString(NamePattern, "Period.", Property);
	Item.Width = 9;
	Item.HorizontalStretch = False;
	Item.ChoiceButton = True;
	Item.OpenButton = False;
	Item.ClearButton = False;
	Item.SpinButton = False;
	Item.TextEdit = True;
	Item.Title = Title;
	Item.TitleLocation = FormItemTitleLocation.None;
	Item.SetAction("OnChange", "Attachable_Period_OnChange");
EndProcedure

Procedure AddPeriodChoiceCommand(Form, Group, NamePattern)
	ItemName = StringFunctionsClientServer.SubstituteParametersInString(NamePattern, "", "SelectPeriod");
	
	Command = Form.Commands.Find(ItemName);
	If Command = Undefined Then 
		Command = Form.Commands.Add(ItemName);
	EndIf;
	Command.Action = "Attachable_SelectPeriod";
	Command.Title = NStr("en='Выбрать период...';ru='Выбрать период...';vi='Chọn khoảng thời gian ...'");
	Command.ToolTip = Command.Title;
	Command.Representation = ButtonRepresentation.Picture;
	Command.Picture = PictureLib.Select;
	
	Button = Form.Items.Find(ItemName);
	If Button = Undefined Then 
		Button = Form.Items.Add(ItemName, Type("FormButton"), Group);
	EndIf;
	Button.CommandName = ItemName;
EndProcedure

Procedure OutputSettingsLists(Form, SettingsItems, SettingsDescription, AttributeNames)
	SimplifiedForm = New Structure("IsList, SettingProperty", True, "Value");
	FoundItems = SettingsItems.FindRows(SimplifiedForm);
	If FoundItems.Count() = 0 Then 
		Return;
	EndIf;
	
	For Each Item In FoundItems Do 
		Item.Field.Visible = False;
		LongDesc = SettingsDescription.Find(Item.SettingIndex, "SettingIndex");
		
		ListName = Form.PathToItemsData.ByIndex[Item.SettingIndex];
		
		AddListItems(Form, Item, LongDesc, ListName, AttributeNames);
		AddListCommands(Form, Item, SettingsItems, ListName);
	EndDo;
EndProcedure

Procedure OutputValuesAsCheckBoxesFields(Form, SettingsItems, AttributeNames)
	SimplifiedForm = New Structure("IsValueAsCheckBox, SettingProperty", True, "Use");
	FoundItems = SettingsItems.FindRows(SimplifiedForm);
	If FoundItems.Count() = 0 Then 
		Return;
	EndIf;
	
	Items = Form.Items;
	PredefinedItemsattributesNames = AttributeNames.predefined.CheckBox;
	
	For Each Item In FoundItems Do 
		Field = Item.Field;
		
		AttributeName = Form.PathToItemsData.ByIndex[Item.SettingIndex];
		If PredefinedItemsattributesNames.Find(AttributeName) = Undefined Then 
			CheckBoxField = Items.Add(AttributeName, Type("FormField"), Field.Parent);
			CheckBoxField.Type = FormFieldType.CheckBoxField;
			CheckBoxField.DataPath = AttributeName;
			CheckBoxField.SetAction("OnChange", "Attachable_SettingItem_OnChange");
		Else
			CheckBoxField = Items.Find(AttributeName);
			Items.Move(CheckBoxField, Field.Parent);
			CheckBoxField.Visible = True;
		EndIf;
		
		CheckBoxField.Title = Field.Title;
		CheckBoxField.TitleLocation = FormItemTitleLocation.Right;
		Item.Field = CheckBoxField;
		
		InitializeCheckBox(Form, Item.SettingIndex);
	EndDo;
EndProcedure

Procedure InitializeCheckBox(Form, IndexOf)
	UserSettings = Form.Report.SettingsComposer.UserSettings;
	SettingItem = UserSettings.Items[IndexOf];
	
	Path = Form.PathToItemsData.ByIndex[IndexOf];
	If TypeOf(SettingItem) = Type("DataCompositionSettingsParameterValue") Then 
		Form[Path] = SettingItem.Value;
	Else // Элемент отбора.
		Form[Path] = SettingItem.RightValue;
	EndIf;
EndProcedure

// Создает элементы формы типа ТаблицаФормы, ссылающиеся на реквизит типа СписокЗначений
// 
// Parameters:
// 	Form - ClientApplicationForm, ManagedFormExtensionForReports - where:
// 	  * Report - ReportObject - 
// 	SettingItem - ValueTableRow - 
// 	SettingItemDetails - ValueTableRow, Undefined - 
// 	ListName - String - 
// 	AttributeNames - Structure - Contains:
//   * GeneratedItems - Structure -
//   * predefined - Structure -
//
Procedure AddListItems(Form, SettingItem, SettingItemDetails, ListName, AttributeNames)
	Items = Form.Items; 
	Field = SettingItem.Field; // ПолеФормы
	
	PredefinedItemsattributesNames = AttributeNames.predefined.List;
	
	If PredefinedItemsattributesNames.Find(ListName) = Undefined Then 
		List = Items.Add(ListName, Type("FormTable"), Field.Parent);
		List.DataPath = ListName;
		List.CommandBarLocation = FormItemCommandBarLabelLocation.None;
		List.Height = 3;
		List.SetAction("OnChange", "Attachable_List_OnChange");
		List.SetAction("ChoiceProcessing", "Attachable_List_ChoiceProcessing");
		
		ListFields = Items.Add(List.Name + "Columns", Type("FormGroup"), List);
		ListFields.Type = FormGroupType.ColumnGroup;
		ListFields.Group = ColumnsGroup.InCell;
		ListFields.Title = "Fields";
		ListFields.ShowTitle = False;
		
		CheckBoxField = Items.Add(ListName + "Check", Type("FormField"), ListFields);
		CheckBoxField.Type = FormFieldType.CheckBoxField;
		CheckBoxField.DataPath = ListName + ".Check";
		
		ValueField = Items.Add(ListName + "Value", Type("FormField"), ListFields);
		ValueField.Type = FormFieldType.InputField;
		ValueField.DataPath = ListName + ".Value";
		ValueField.SetAction("OnChange", "Attachable_ListItem_OnChange");
		ValueField.SetAction("StartChoice", "Attachable_ListItem_StartChoice");
	Else
		List = Items.Find(ListName);
		List.Visible = True;
		
		ListFields = Items.Find(List.Name + "Columns");
		ValueField = Items.Find(List.Name + "Value");
		
		Items.Move(List, Field.Parent);
	EndIf;
	
	List.Title = Field.Title;
	
	Properties = "AvailableTypes, TypeRestriction, AutoMarkIncomplete, ChoiceParameterLinks, TypeLink";
	FillPropertyValues(ValueField, Field, Properties);
	
	ReportsClientServer.ExpandList(ValueField.ChoiceList, Field.ChoiceList, False, True);
	
	EditParameters = New Structure("QuickChoice, ChoiceFoldersAndItems");
	If SettingItemDetails.SettingDetails <> Undefined Then 
		FillPropertyValues(EditParameters, SettingItemDetails.SettingDetails);
	EndIf;
	
	ValueField.QuickChoice = EditParameters.QuickChoice;
	
	Condition = ReportsClientServer.SettingItemCondition(
		SettingItemDetails.SettingItem, SettingItemDetails.SettingDetails);
	ValueField.ChoiceFoldersAndItems = ReportsClientServer.GroupsAndItemsTypeValue(
		EditParameters.ChoiceFoldersAndItems, Condition);
	
	ValueField.ChoiceParameters = ReportsClientServer.ChoiceParameters(
		SettingItemDetails.Settings,
		Form.Report.SettingsComposer.UserSettings.Items,
		SettingItemDetails.SettingItem);
	
	InitializeList(Form, SettingItem.SettingIndex, ValueField, SettingItemDetails.SettingItem);
	
	If Field.ChoiceList.Count() > 0 Then 
		List.ChangeRowSet = False;
		ValueField.ReadOnly = True;
	EndIf;
EndProcedure

Procedure AddListCommands(Form, SettingItem, SettingsItems, ListName)
	Items = Form.Items; 
	
	SimplifiedForm = New Structure("SettingProperty, SettingIndex", "Use");
	SimplifiedForm.SettingIndex = SettingItem.SettingIndex;
	
	TitleField = SettingsItems.FindRows(SimplifiedForm)[0].Field;
	GroupHeader = TitleField.Parent;
	GroupHeader.Group = ChildFormItemsGroup.AlwaysHorizontal;
	
	ListGroup = GroupHeader.Parent;
	ListGroup.Representation = UsualGroupRepresentation.NormalSeparation;
	
	If Not Items[ListName].ChangeRowSet Then 
		Return;
	EndIf;
	
	ItemName = ListName + "Indent";
	Indent = Items.Find(ItemName);
	If Indent = Undefined Then 
		Indent = Items.Add(ItemName, Type("FormDecoration"), GroupHeader);
	ElsIf Indent.Parent <> GroupHeader Then 
		Items.Move(Indent, GroupHeader);
	EndIf;
	Indent.Type = FormDecorationType.Label;
	Indent.Title = "     ";
	Indent.HorizontalStretch = True;
	Indent.AutoMaxWidth = False;
	Indent.Visible = True;
	
	CommandName = ListName + "Pick";
	CommandTitle = NStr("en='Подбор';ru='Подбор';vi='Lọc'");
	AddListCommand(Form, GroupHeader, CommandName, CommandTitle, "Attachable_List_Pick");
	
	If Not CommonUse.SubsystemExists("StandardSubsystems.DataLoadFromFile") Then 
		Return;
	EndIf;
	
	CommandName = ListName + "InsertFromBuffer";
	CommandTitle = NStr("en = 'Вставить из буфера обмена...'; ru = 'Вставить из буфера обмена...'; vi = 'Dán từ bộ nhớ tạm ...'");
	AddListCommand(Form, GroupHeader, CommandName, CommandTitle,
		"Attachable_List_PasteFromClipboard", PictureLib.InsertFromClipboard);
EndProcedure

Procedure AddListCommand(Form, Parent, CommandName, Title, Action, Picture = Undefined)
	Command = Form.Commands.Find(CommandName);
	If Command = Undefined Then 
		Command = Form.Commands.Add(CommandName);
	EndIf;
	Command.Action = Action;
	Command.Title = Title;
	Command.ToolTip = Title;
	
	If Picture = Undefined Then 
		Command.Representation = ButtonRepresentation.Text;
	Else
		Command.Representation = ButtonRepresentation.Picture;
		Command.Picture = PictureLib.InsertFromClipboard;
	EndIf;
	
	Button = Form.Items.Find(CommandName);
	If Button = Undefined Then 
		Button = Form.Items.Add(CommandName, Type("FormButton"), Parent);
	ElsIf Button.Parent <> Parent Then 
		Form.Items.Move(Button, Parent);
	EndIf;
	Button.CommandName = CommandName;
	Button.Type = FormButtonType.Hyperlink;
	Button.Visible = True;
EndProcedure

Procedure InitializeList(Form, IndexOf, Field, SettingItem)
	UserSettings = Form.Report.SettingsComposer.UserSettings;
	SettingItem = UserSettings.Items[IndexOf];
	
	Path = Form.PathToItemsData.ByIndex[IndexOf];
	List = Form[Path];
	List.ValueType = Field.AvailableTypes;
	List.Clear();
	
	ValueFieldName = "RightValue";
	If TypeOf(SettingItem) = Type("DataCompositionSettingsParameterValue") Then 
		ValueFieldName = "Value";
	EndIf;
	
	SelectedValues = ReportsClientServer.ValueList(SettingItem[ValueFieldName]);
	If SelectedValues.Count() > 0 Then 
		SettingItem[ValueFieldName] = SelectedValues;
	Else
		SelectedValues = ReportsClientServer.ValueList(SettingItem[ValueFieldName]);
		If SelectedValues.Count() > 0 Then 
			// При выполнении метода СоздатьЭлементыФормыПользовательскихНастроек()
			// сбрасывается значение пользовательской настройки.
			SettingItem[ValueFieldName] = SelectedValues;
		EndIf;
	EndIf;
	
	AvailableValues = New ValueList;
	If Field.QuickChoice = True Then 
		ListParameters = New Structure("ChoiceParameters, TypeDescription, ChoiceFoldersAndItems, Filter");
		FillPropertyValues(ListParameters, Field);
		ListParameters.TypeDescription = Field.AvailableTypes;
		ListParameters.Filter = New Structure;
		
		AvailableValues = ValuesForSelection(ListParameters);
	EndIf;
	
	If AvailableValues.Count() = 0 Then 
		AvailableValues = Field.ChoiceList;
	EndIf;
	
	ReportsClientServer.ExpandList(List, AvailableValues, False, True);
	ReportsClientServer.ExpandList(List, SelectedValues, False, True);
	
	For Each ListElement In List Do 
		If Not ValueIsFilled(ListElement.Value) Then 
			Continue;
		EndIf;
		
		FoundItem = AvailableValues.FindByValue(ListElement.Value);
		If FoundItem <> Undefined Then 
			ListElement.Presentation = FoundItem.Presentation;
		EndIf;
		
		FoundItem = SelectedValues.FindByValue(ListElement.Value);
		ListElement.Check = (FoundItem <> Undefined);
	EndDo;
	
	ListBox = Form.Items[Path]; // ТаблицаФормы
	If SettingItem.Use Then 
		ListBox.TextColor = New Color;
	Else
		ListBox.TextColor = Metadata.StyleItems.UnavailableCellTextColor.Value;
	EndIf;
EndProcedure

Function ExtendedTypesDetails(InitialTypeDescription, ResultInForm, SelectionParameters = Undefined) Export
	Result = New Structure;
	Result.Insert("ContainsTypeType",        False);
	Result.Insert("ContainsTypeDate",       False);
	Result.Insert("ContainsTypeBoolean",     False);
	Result.Insert("ContainsTypeOfRow",     False);
	Result.Insert("ContainsTypeNumber",      False);
	Result.Insert("ContainsTypePeriod",     False);
	Result.Insert("ContainsUUIDType",        False);
	Result.Insert("ContainsStorageType",  False);
	Result.Insert("ContainsObjectTypes", False);
	Result.Insert("LimitedLength",     True);
	
	Result.Insert("TypeCount",            0);
	Result.Insert("PrimitiveTypesQuantity", 0);
	Result.Insert("ObjectiveTypes", New Array);
	
	If ResultInForm Then
		AddTypes = New Array;
		DeductionTypes = New Array;
		Result.Insert("TypeDescriptionSource", InitialTypeDescription);
		Result.Insert("TypeDescriptionForForm", InitialTypeDescription);
	EndIf;
	
	If InitialTypeDescription = Undefined Then
		Return Result;
	EndIf;
	
	TypeArray = InitialTypeDescription.Types();
	For Each Type In TypeArray Do
		If Type = Type("Null") Then 
			DeductionTypes.Add(Type);
			Continue;
		EndIf;
		
		If Type = Type("DataCompositionField") Then
			If ResultInForm Then
				DeductionTypes.Add(Type);
			EndIf;
			Continue;
		EndIf;
		
		SettingMetadata = Metadata.FindByType(Type);
		If SettingMetadata <> Undefined Then 
			If CommonUse.MetadataObjectAvailableByFunctionalOptions(SettingMetadata) Then
				If TypeOf(SelectionParameters) = Type("Map") Then 
					SelectionParameters.Insert(Type, SettingMetadata.FullName() + ".ChoiceForm");
				EndIf;
			Else // Объект недоступен.
				If ResultInForm Then
					DeductionTypes.Add(Type);
				EndIf;
				Continue;
			EndIf;
		EndIf;
		
		Result.TypeCount = Result.TypeCount + 1;
		
		If Type = Type("Type") Then
			Result.ContainsTypeType = True;
		ElsIf Type = Type("Date") Then
			Result.ContainsTypeDate = True;
			Result.PrimitiveTypesQuantity = Result.PrimitiveTypesQuantity + 1;
		ElsIf Type = Type("Boolean") Then
			Result.ContainsTypeBoolean = True;
			Result.PrimitiveTypesQuantity = Result.PrimitiveTypesQuantity + 1;
		ElsIf Type = Type("Number") Then
			Result.ContainsTypeNumber = True;
			Result.PrimitiveTypesQuantity = Result.PrimitiveTypesQuantity + 1;
		ElsIf Type = Type("StandardPeriod") Then
			Result.ContainsTypePeriod = True;
		ElsIf Type = Type("String") Then
			Result.ContainsTypeOfRow = True;
			Result.PrimitiveTypesQuantity = Result.PrimitiveTypesQuantity + 1;
			If InitialTypeDescription.StringQualifiers.Length = 0
				And InitialTypeDescription.StringQualifiers.AllowedLength = AllowedLength.Variable Then
				Result.LimitedLength = False;
			EndIf;
		ElsIf Type = Type("UUID") Then
			Result.ContainsUUIDType = True;
		ElsIf Type = Type("ValueStorage") Then
			Result.ContainsStorageType = True;
		Else
			Result.ContainsObjectTypes = True;
			Result.ObjectiveTypes.Add(Type);
		EndIf;
		
	EndDo;
	
	If ResultInForm
		And (AddTypes.Count() > 0 Or DeductionTypes.Count() > 0) Then
		Result.TypeDescriptionForForm = New TypeDescription(InitialTypeDescription, AddTypes, DeductionTypes);
	EndIf;
	
	Return Result;
EndFunction

Function ValuesForSelection(SettingsParameters, TypeOrTypes = Undefined) Export
	GettingChoiceDataParameters = New Structure("Filter, ChoiceFoldersAndItems");
	FillPropertyValues(GettingChoiceDataParameters, SettingsParameters);
	AddItemsFromChoiceParametersToStructure(GettingChoiceDataParameters, SettingsParameters.ChoiceParameters);
	
	ValuesForSelection = New ValueList;
	If TypeOf(TypeOrTypes) = Type("Type") Then
		Types = New Array;
		Types.Add(TypeOrTypes);
	ElsIf TypeOf(TypeOrTypes) = Type("Array") Then
		Types = TypeOrTypes;
	Else
		Types = SettingsParameters.TypeDescription.Types();
	EndIf;
	
	For Each Type In Types Do
		MetadataObject = Metadata.FindByType(Type);
		If MetadataObject = Undefined Then
			Continue;
		EndIf;
		Manager = CommonUse.ObjectManagerByFullName(MetadataObject.FullName());
		
		ChoiceList = Manager.GetChoiceData(GettingChoiceDataParameters);
		For Each ListElement In ChoiceList Do
			ValueForSelection = ValuesForSelection.Add();
			FillPropertyValues(ValueForSelection, ListElement);
			
			// Для перечислений значения возвращаются в виде структуры со свойством Значение.
			EnumValue = Undefined;
			If TypeOf(ValueForSelection.Value) = Type("Structure") 
				And ValueForSelection.Value.Property("Value", EnumValue) Then
				ValueForSelection.Value = EnumValue;
			EndIf;	
				
		EndDo;
	EndDo;
	Return ValuesForSelection;
EndFunction

Procedure AddItemsFromChoiceParametersToStructure(Structure, SelectionParametersArray)
	For Each ChoiceParameter In SelectionParametersArray Do
		CurrentStructure = Structure;
		RowArray = StrSplit(ChoiceParameter.Name, ".");
		Quantity = RowArray.Count();
		If Quantity > 1 Then
			For IndexOf = 0 To Quantity-2 Do
				Var_Key = RowArray[IndexOf];
				If CurrentStructure.Property(Var_Key) And TypeOf(CurrentStructure[Var_Key]) = Type("Structure") Then
					CurrentStructure = CurrentStructure[Var_Key];
				Else
					CurrentStructure.Insert(Var_Key, New Structure);
					CurrentStructure = CurrentStructure[Var_Key];
				EndIf;
			EndDo;
		EndIf;
		Var_Key = RowArray[Quantity-1];
		CurrentStructure.Insert(Var_Key, ChoiceParameter.Value);
	EndDo;
EndProcedure

Procedure InitializePeriod(Form, IndexOf)
	UserSettings = Form.Report.SettingsComposer.UserSettings;
	SettingItem = UserSettings.Items[IndexOf];
	
	Path = Form.PathToItemsData.ByIndex[IndexOf];
	If TypeOf(SettingItem) = Type("DataCompositionSettingsParameterValue") Then 
		Form[Path] = SettingItem.Value;
	Else // Элемент отбора.
		Form[Path] = SettingItem.RightValue;
	EndIf;
EndProcedure

Procedure DistributeListsByColumnsProportionally(SettingsItems, ColumnsCount)
	If ColumnsCount <> 2
		Or SettingsItems.Find(True, "IsList") = Undefined Then 
		Return;
	EndIf;
	
	NumberDetails = New TypeDescription("Number");
	
	Statistics = SettingsItems.Copy();
	Statistics.GroupBy("SettingIndex, IsList, ColumnNumber");
	Statistics.Columns.Add("lists", NumberDetails);
	
	For Each Item In Statistics Do 
		Item.lists = Number(Item.IsList);
	EndDo;
	
	Statistics.GroupBy("ColumnNumber", "lists");
	
	lists = Statistics.Total("lists");
	If lists = 1 Then 
		Return;
	EndIf;
	
	Statistics.Sort("lists");
	
	AVG = Round(lists / Statistics.Count(), 0, RoundMode.Round15as10);
	Receiver = Statistics[0];
	Source = Statistics[Statistics.Count() - 1];
	
	Deviation = AVG - Receiver.lists;
	If Deviation = 0 Then 
		Return;
	EndIf;
	
	SimplifiedForm = New Structure("IsList, ColumnNumber", True, Source.ColumnNumber);
	SourceItems = SettingsItems.Copy(SimplifiedForm);
	SourceItems.GroupBy("SettingIndex");
	If Receiver.ColumnNumber > Source.ColumnNumber Then 
		SourceItems.Sort("SettingIndex Desc");
	EndIf;
	
	Deviation = Min(Deviation, SourceItems.Count());
	SimplifiedForm = New Structure("SettingIndex");
	
	IndexOf = 0;
	While Deviation > 0 Do 
		SimplifiedForm.SettingIndex = SourceItems[IndexOf].SettingIndex;
		LinkedItems = SettingsItems.FindRows(SimplifiedForm);
		For Each Item In LinkedItems Do 
			Item.ColumnNumber = Receiver.ColumnNumber;
		EndDo;
		
		IndexOf = IndexOf + 1;
		Deviation = Deviation - 1;
	EndDo;
EndProcedure

Function UserSettingsInfo(Settings)
	Information = New Map;
	GetGroupingInfo(Settings, Information, Settings.AdditionalProperties);
	
	Return Information;
EndFunction

Procedure GetGroupingInfo(Grouping, Information, AdditionalProperties)
	GroupType = TypeOf(Grouping);
	If GroupType <> Type("DataCompositionSettings")
		And GroupType <> Type("DataCompositionGroup")
		And GroupType <> Type("DataCompositionTableGroup")
		And GroupType <> Type("DataCompositionChartGroup") Then 
		Return;
	EndIf;
	
	If GroupType <> Type("DataCompositionSettings")
		And ValueIsFilled(Grouping.UserSettingID) Then 
		
		InformationKinds = InformationKinds();
		InformationKinds.Settings = Grouping;
		InformationKinds.SettingItem = Grouping;
		
		Information.Insert(Grouping.UserSettingID, InformationKinds);
	EndIf;
	
	GetSettingsItemInfo(Grouping, Information, AdditionalProperties);
EndProcedure

Procedure GetTableInfo(Table, Information, AdditionalProperties)
	If TypeOf(Table) <> Type("DataCompositionTable") Then
		Return;
	EndIf;
	
	If ValueIsFilled(Table.UserSettingID) Then 
		InformationKinds = InformationKinds();
		InformationKinds.Settings = Table;
		InformationKinds.SettingItem = Table;
		
		Information.Insert(Table.UserSettingID, InformationKinds);
	EndIf;
	
	GetSettingsItemInfo(Table, Information, AdditionalProperties);
	GetCollectionInfo(Table, Table.Rows, Information, AdditionalProperties);
	GetCollectionInfo(Table, Table.Columns, Information, AdditionalProperties);
EndProcedure

Procedure GetChartInfo(Chart, Information, AdditionalProperties)
	If TypeOf(Chart) <> Type("DataCompositionChart") Then
		Return;
	EndIf;
	
	If ValueIsFilled(Chart.UserSettingID) Then 
		InformationKinds = InformationKinds();
		InformationKinds.Settings = Chart;
		InformationKinds.SettingItem = Chart;
		
		Information.Insert(Chart.UserSettingID, InformationKinds);
	EndIf;
	
	GetSettingsItemInfo(Chart, Information, AdditionalProperties);
	GetCollectionInfo(Chart, Chart.Series, Information, AdditionalProperties);
	GetCollectionInfo(Chart, Chart.Points, Information, AdditionalProperties);
EndProcedure

Procedure GetCollectionInfo(SettingsItem, Collection, Information, AdditionalProperties)
	CollectionType = TypeOf(Collection);
	If CollectionType <> Type("DataCompositionTableStructureItemCollection")
		And CollectionType <> Type("DataCompositionChartStructureItemCollection")
		And CollectionType <> Type("DataCompositionSettingStructureItemCollection") Then
		Return;
	EndIf;
	
	If ValueIsFilled(Collection.UserSettingID) Then 
		InformationKinds = InformationKinds();
		InformationKinds.Settings = SettingsItem;
		InformationKinds.SettingItem = Collection;
		
		Information.Insert(Collection.UserSettingID, InformationKinds);
	EndIf;
	
	For Each Item In Collection Do 
		Settings = Item;
		If TypeOf(Item) = Type("DataCompositionNestedObjectSettings") Then
			If ValueIsFilled(Item.UserSettingID) Then 
				InformationKinds = InformationKinds();
				InformationKinds.Settings = Item;
				InformationKinds.SettingItem = Item;
				
				Information.Insert(Item.UserSettingID, InformationKinds);
			EndIf;
			
			Settings = Item.Settings;
		EndIf;

		GetGroupingInfo(Settings, Information, AdditionalProperties);
		GetTableInfo(Settings, Information, AdditionalProperties);
		GetChartInfo(Settings, Information, AdditionalProperties);
	EndDo;
EndProcedure

Procedure GetSettingsItemInfo(SettingsItem, Information, AdditionalProperties)
	PropertiesIDs = SettingsPropertiesIDs(AdditionalProperties);
	AdditionalIDs = New Array;
	
	AvailableProperties = New Structure("Choice, Filter, Order, ConditionalAppearance, Structure");
	
	SettingsItemType = TypeOf(SettingsItem);
	If SettingsItemType <> Type("DataCompositionTable")
		And SettingsItemType <> Type("DataCompositionChart") Then 
		
		AdditionalIDs.Add("Filter");
		AdditionalIDs.Add("Order");
		AdditionalIDs.Add("Structure");
		
		If SettingsItemType = Type("DataCompositionSettings") Then 
			AdditionalIDs.Add("DataParameters");
		EndIf;
	EndIf;
	
	CommonUseClientServer.SupplementArray(PropertiesIDs, AdditionalIDs, True);
	
	For Each ID In PropertiesIDs Do 
		Property = SettingsItem[ID];
		
		If AvailableProperties.Property(ID)
			And ValueIsFilled(Property.UserSettingID) Then 
			
			InformationKinds = InformationKinds();
			InformationKinds.Settings = SettingsItem;
			InformationKinds.SettingItem = Property;
			
			Information.Insert(Property.UserSettingID, InformationKinds);
		EndIf;
		
		GetSettingsPropertyItemsInfo(SettingsItem, Property, ID, Information, AdditionalProperties);
		GetCollectionInfo(SettingsItem, Property, Information, AdditionalProperties);
	EndDo;
EndProcedure

// Добавляет сведения о элементах отборов, значениях параметров и т.д.
// 
// Parameters:
// 	Settings - DataCompositionSettings - 
// 	Property - DataCompositionFilter -
// 	         - DataCompositionDataParameterValues - 
// 	         - DataCompositionOutputParameterValues - 
// 	         - DataCompositionConditionalAppearance - 
// 	PropertyID - String - 
// 	Information - See InformationKinds
// 	AdditionalProperties - Structure - 
//
Procedure GetSettingsPropertyItemsInfo(Settings, Property, PropertyID, Information, AdditionalProperties)
	PropertiesWithItems = New Structure("Filter, DataParameters, OutputParameters, ConditionalAppearance");
	If Not PropertiesWithItems.Property(PropertyID) Then 
		Return;
	EndIf;
	
	For Each Item In Property.Items Do 
		ItemType = TypeOf(Item);
		
		If ValueIsFilled(Item.UserSettingID) Then 
			LongDesc = Undefined;
			If ItemType = Type("DataCompositionFilterItem") Then 
				
				AvailableFields = Settings[PropertyID].FilterAvailableFields;
				If AvailableFields <> Undefined Then 
					LongDesc = AvailableFields.FindField(Item.LeftValue);
				EndIf;
				
			ElsIf ItemType = Type("DataCompositionParameterValue")
				Or ItemType = Type("DataCompositionSettingsParameterValue") Then 
				
				AvailableParameters = Settings[PropertyID].AvailableParameters;
				If AvailableParameters <> Undefined Then 
					LongDesc = AvailableParameters.FindParameter(Item.Parameter);
				EndIf;
			EndIf;
			
			InformationKinds = InformationKinds();
			InformationKinds.Settings = Settings;
			InformationKinds.SettingItem = Item;
			InformationKinds.SettingDetails = LongDesc;
			
			Information.Insert(Item.UserSettingID, InformationKinds);
		EndIf;
		
		If ItemType = Type("DataCompositionFilterItemGroup") Then 
			GetSettingsPropertyItemsInfo(
				Settings, Item, PropertyID, Information, AdditionalProperties);
		ElsIf ItemType = Type("DataCompositionParameterValue")
			Or ItemType = Type("DataCompositionSettingsParameterValue") Then 
			GetNestedParametersValuesInfo(
				Settings, Item.NestedParameterValues, PropertyID, Information, AdditionalProperties);
		EndIf;
	EndDo;
EndProcedure

Procedure GetNestedParametersValuesInfo(Settings, ParameterValues, PropertyID, Information, AdditionalProperties)
	For Each ParameterValue In ParameterValues Do 
		If ValueIsFilled(ParameterValue.UserSettingID) Then 
			InformationKinds = InformationKinds();
			InformationKinds.Settings = Settings;
			InformationKinds.SettingItem = ParameterValue;
			InformationKinds.SettingDetails =
				Settings[PropertyID].AvailableParameters.FindParameter(ParameterValue.Parameter);
			
			Information.Insert(ParameterValue.UserSettingID, InformationKinds);
		EndIf;
		
		GetNestedParametersValuesInfo(
			Settings, ParameterValue.NestedParameterValues, PropertyID, Information, AdditionalProperties);
	EndDo;
EndProcedure

Function SettingsPropertiesIDs(AdditionalProperties)
	
	DefaultPropertiesIDs = StrSplit("Selection, OutputParameters, ConditionalAppearance", ", ", False);
	
	PropertiesIDs = CommonUseClientServer.StructureProperty(
		AdditionalProperties,
		"SettingsPropertiesIDs",
		DefaultPropertiesIDs);
	
	Return CommonUse.CopyRecursive(PropertiesIDs);
EndFunction

Function InformationKinds()
	Return New Structure("Settings, SettingItem, SettingDetails");
EndFunction

Function AvailableSettings(ImportParameters, ReportSettings) Export 
	Settings = Undefined;
	UserSettings = Undefined;
	FixedSettings = Undefined;
	
	If ImportParameters.Property("DCSettingsComposer") Then
		Settings = ImportParameters.DCSettingsComposer.Settings;
		UserSettings = ImportParameters.DCSettingsComposer.UserSettings;
		FixedSettings = ImportParameters.DCSettingsComposer.FixedSettings;
	Else
		If ImportParameters.Property("DCSettings") Then
			Settings = ImportParameters.DCSettings;
		EndIf;
		If ImportParameters.Property("DCUserSettings") Then
			UserSettings = ImportParameters.DCUserSettings;
		EndIf;
	EndIf;
	
	If ReportSettings.Events.BeforeImportSettingsToComposer Then
		XMLSettings = CommonUseClientServer.StructureProperty(ReportSettings, "NewXMLSettings");
		If TypeOf(XMLSettings) = Type("String") Then
			Try
				Settings = CommonUse.ValueFromXMLString(XMLSettings);
			Except
				Settings = Undefined;
			EndTry;
			ReportSettings.NewXMLSettings = Undefined;
		EndIf;
		
		UserXMLSettings = CommonUseClientServer.StructureProperty(ReportSettings, "NewUserXMLSettings");
		If TypeOf(UserXMLSettings) = Type("String") Then
			Try
				UserSettings = CommonUse.ValueFromXMLString(UserXMLSettings);
			Except
				UserSettings = Undefined;
			EndTry;
			ReportSettings.NewUserXMLSettings = Undefined;
		EndIf;
	EndIf;
	
	Return New Structure("Settings, UserSettings, FixedSettings",
		Settings, UserSettings, FixedSettings);
EndFunction

Procedure ResetUserSettings(AvailableSettings, ImportParameters) Export 
	ResetUserSettings = CommonUseClientServer.StructureProperty(
		ImportParameters, "ResetUserSettings", False);
	
	If Not ResetUserSettings Then 
		Return;
	EndIf;
	
	If AvailableSettings.UserSettings = Undefined Then 
		AdditionalProperties = Undefined;
	Else
		AdditionalProperties = AvailableSettings.UserSettings.AdditionalProperties;
	EndIf;
	
	AvailableSettings.UserSettings = New DataCompositionUserSettings;
	
	If AdditionalProperties = Undefined Then 
		Return;
	EndIf;
	
	For Each Property In AdditionalProperties Do 
		AvailableSettings.UserSettings.AdditionalProperties.Insert(Property.Key, Property.Value);
	EndDo;
EndProcedure

Procedure RestoreFiltersValues(Form) Export 
	UserSettings = Form.Report.SettingsComposer.UserSettings;
	PathToItemsData = Form.PathToItemsData;
	
	FiltersValuesCache = CommonUseClientServer.StructureProperty(
		UserSettings.AdditionalProperties, "FiltersValuesCache");
	
	If FiltersValuesCache = Undefined Then 
		Return;
	EndIf;
	
	For Each CacheItem In FiltersValuesCache Do 
		FilterValue = CacheItem.Value;
		If FilterValue.Count() = 0 Then 
			Continue;
		EndIf;
		
		SettingItem = UserSettings.Items.Find(CacheItem.Key);
		If SettingItem = Undefined Then 
			Continue;
		EndIf;
		
		IndexOf = UserSettings.Items.IndexOf(SettingItem);
		ListName = PathToItemsData.ByIndex[IndexOf];
		If ListName = Undefined Then 
			Continue;
		EndIf;
		
		List = Form[ListName];
		If List = Undefined Then 
			Continue;
		EndIf;
		
		For Each Item In FilterValue Do 
			If List.FindByValue(Item.Value) = Undefined Then 
				List.Add(Item.Value);
			EndIf;
		EndDo;
	EndDo;
EndProcedure

Procedure SetAvailableValues(Report, Form) Export 
	SettingsComposer = Form.Report.SettingsComposer;
	
	SettingsCollections = New Array; // массив из ПользовательскиеНастройкиКомпоновкиДанных, ЗначенияПараметровДанныхКомпоновкиДанных, ОтборКомпоновкиДанных
	SettingsCollections.Add(SettingsComposer.UserSettings);
	SettingsCollections.Add(SettingsComposer.Settings.DataParameters);
	SettingsCollections.Add(SettingsComposer.Settings.Filter);
	
	For Each SettingsCollection In SettingsCollections Do 
		IsUserSettings = (TypeOf(SettingsCollection) = Type("DataCompositionUserSettings"));
		
		For Each SettingItem In SettingsCollection.Items Do 
			If TypeOf(SettingItem) <> Type("DataCompositionSettingsParameterValue")
				And TypeOf(SettingItem) <> Type("DataCompositionFilterItem") Then 
				Continue;
			EndIf;
			
			If Not IsUserSettings
				And ValueIsFilled(SettingItem.UserSettingID) Then 
				Continue;
			EndIf;
			
			If IsUserSettings Then 
				UserSettingsItem = SettingItem;
				
				MainSettingItem = ReportsClientServer.GetObjectByUserIdentifier(
					SettingsComposer.Settings,
					UserSettingsItem.UserSettingID,,
					SettingsCollection);
			Else
				UserSettingsItem = SettingItem;
				MainSettingItem = SettingItem;
			EndIf;
			
			SettingDetails = ReportsClientServer.FindAvailableSetting(
				SettingsComposer.Settings, MainSettingItem);
			
			SettingProperty = UserSettingsItemProperties(
				SettingsComposer, UserSettingsItem, MainSettingItem, SettingDetails);
			
			// Механизмы расширения.
			//SSLSubsystemsIntegration.OnDefineSelectionParametersReportsOptions(Undefined, SettingProperty);
			
			// Глобальные настройки вывода типов.
			ReportsOverridable.OnDefineSelectionParameters(Undefined, SettingProperty);
			
			// Локальное переопределение для отчета.
			If Form.ReportSettings.Events.OnDefineSelectionParameters Then 
				Report.OnDefineSelectionParameters(Form, SettingProperty);
			EndIf;
			
			// Автоматическое заполнение.
			If SettingProperty.SelectionValueQuery.Text <> "" Then
				AddedValues = SettingProperty.SelectionValueQuery.Execute().Unload().UnloadColumn(0);
				For Each Item In AddedValues Do
					ReportsClientServer.AddUniqueValueInList(
						SettingProperty.ValuesForSelection, Item, Undefined, False);
				EndDo;
				SettingProperty.ValuesForSelection.SortByPresentation(SortDirection.Asc);
			EndIf;
			
			If TypeOf(SettingProperty.ValuesForSelection) = Type("ValueList")
				And SettingProperty.ValuesForSelection.Count() > 0 Then 
				SettingDetails.AvailableValues = SettingProperty.ValuesForSelection;
			EndIf;
		EndDo;
	EndDo;
EndProcedure

Function IsTechnicalObject(Val FullObjectName) Export
	
	Return FullObjectName = Upper("Catalog.PredefinedExtensionsReportsOptions")
		Or FullObjectName = Upper("Catalog.PredefinedReportsVariants");
	
EndFunction

Function UserSettingsItemProperties(SettingsComposer, UserSettingsItem, SettingItem, SettingDetails)
	Properties = UserSettingsItemPropertiesPalette();
	
	Properties.DCUsersSetting = UserSettingsItem;
	Properties.KDItem = SettingItem;
	Properties.AvailableKDSetting = SettingDetails;
	
	Properties.ID = UserSettingsItem.UserSettingID;
	Properties.DCIdentifier = SettingsComposer.UserSettings.GetIDByObject(
		UserSettingsItem);
	Properties.ItemIdentificator = StrReplace(
		UserSettingsItem.UserSettingID, "-", "");
	
	SettingItemType = TypeOf(SettingItem);
	If SettingItemType = Type("DataCompositionSettingsParameterValue") Then 
		Properties.DCField = New DataCompositionField("DataParameters." + String(SettingItem.Parameter));
		Properties.Value = SettingItem.Value;
	ElsIf TypeOf(SettingItem) = Type("DataCompositionFilterItem") Then 
		Properties.DCField = SettingItem.LeftValue;
		Properties.Value = SettingItem.RightValue;
	EndIf;
	
	Properties.Type = RowSettingType(SettingItemType);
	
	If SettingDetails = Undefined Then 
		Return Properties;
	EndIf;
	
	Properties.TypeDescription = SettingDetails.ValueType;
	
	If SettingDetails.AvailableValues <> Undefined Then 
		Properties.ValuesForSelection = SettingDetails.AvailableValues;
	EndIf;
	
	Return Properties;
EndFunction

Function UserSettingsItemPropertiesPalette()
	Properties = New Structure;
	Properties.Insert("QuickChoice", False);
	Properties.Insert("EnterByList", False);
	Properties.Insert("ComparisonType", DataCompositionComparisonType.Equal);
	Properties.Insert("Owner", Undefined);
	Properties.Insert("ChoiceFoldersAndItems", FoldersAndItems.Auto);
	Properties.Insert("OutputAllowed", True);
	Properties.Insert("OutputInMainSettingsGroup", False);
	Properties.Insert("DisplayOnlyCheckBox", False);
	Properties.Insert("DisplayCheckbox", True);
	Properties.Insert("Global", True);
	Properties.Insert("AvailableKDSetting", Undefined);
	Properties.Insert("SelectionValueQuery", New Query);
	Properties.Insert("Value", Undefined);
	Properties.Insert("ValuesForSelection", New ValueList);
	Properties.Insert("ID", "");
	Properties.Insert("DCIdentifier", Undefined);
	Properties.Insert("ItemIdentificator", "");
	Properties.Insert("CollectionName", "");
	Properties.Insert("TypeInformation", New Structure);
	Properties.Insert("TypeRestriction", Undefined);
	Properties.Insert("LimitChoiceWithSpecifiedValues", False);
	Properties.Insert("TypeDescription", New TypeDescription("Undefined"));
	Properties.Insert("MarkedValues", Undefined);
	Properties.Insert("ChoiceParameters", New Array);
	Properties.Insert("Subtype", "");
	Properties.Insert("DCField", Undefined);
	Properties.Insert("UserSetting", Undefined);
	Properties.Insert("DCUsersSetting", Undefined);
	Properties.Insert("Presentation", "");
	Properties.Insert("DefaultPresentation", "");
	Properties.Insert("Parent", Undefined);
	Properties.Insert("ChoiceParameterLinks", New Array);
	Properties.Insert("LinksByMetadata", New Array);
	Properties.Insert("TypeLink", Undefined);
	Properties.Insert("EventOnChange", False);
	Properties.Insert("State", "");
	Properties.Insert("ValueListRedefined", False);
	Properties.Insert("TreeRow", Undefined);
	Properties.Insert("Rows", Undefined);
	Properties.Insert("Type", "");
	Properties.Insert("ChoiceForm", "");
	Properties.Insert("Width", 0);
	Properties.Insert("KDItem", Undefined);
	
	Return Properties;
EndFunction

Function RowSettingType(Type)
	If Type = Type("DataCompositionSettings") Then
		Return "Settings";
	ElsIf Type = Type("DataCompositionNestedObjectSettings") Then
		Return "NestedObjectSettings";
	
	ElsIf Type = Type("DataCompositionFilter") Then
		Return "Filter";
	ElsIf Type = Type("DataCompositionFilterItem") Then
		Return "FilterItem";
	ElsIf Type = Type("DataCompositionFilterItemGroup") Then
		Return "FilterItemGroup";
	
	ElsIf Type = Type("DataCompositionSettingsParameterValue") Then
		Return "SettingsParameterValue";
	
	ElsIf Type = Type("DataCompositionGroup") Then
		Return "Grouping";
	ElsIf Type = Type("DataCompositionGroupFields") Then
		Return "GroupFields";
	ElsIf Type = Type("DataCompositionGroupFieldCollection") Then
		Return "CollectionGroupFields";
	ElsIf Type = Type("DataCompositionGroupField") Then
		Return "GroupingField";
	ElsIf Type = Type("DataCompositionAutoGroupField") Then
		Return "AutoGroupField";
	
	ElsIf Type = Type("DataCompositionSelectedFields") Then
		Return "SelectedFields";
	ElsIf Type = Type("DataCompositionSelectedField") Then
		Return "SelectedField";
	ElsIf Type = Type("DataCompositionSelectedFieldGroup") Then
		Return "SelectedFieldsGroup";
	ElsIf Type = Type("DataCompositionAutoSelectedField") Then
		Return "AutoSelectedField";
	
	ElsIf Type = Type("DataCompositionOrder") Then
		Return "Order";
	ElsIf Type = Type("DataCompositionOrderItem") Then
		Return "OrderingItem";
	ElsIf Type = Type("DataCompositionAutoOrderItem") Then
		Return "AutoOrderItem";
	
	ElsIf Type = Type("DataCompositionConditionalAppearance") Then
		Return "ConditionalAppearance";
	ElsIf Type = Type("DataCompositionConditionalAppearanceItem") Then
		Return "ConditionalAppearanceItem";
	
	ElsIf Type = Type("DataCompositionSettingStructure") Then
		Return "SettingsStructure";
	ElsIf Type = Type("DataCompositionSettingStructureItemCollection") Then
		Return "SettingsStructureItemCollection";
	
	ElsIf Type = Type("DataCompositionTable") Then
		Return "Table";
	ElsIf Type = Type("DataCompositionTableGroup") Then
		Return "TableGrouping";
	ElsIf Type = Type("DataCompositionTableStructureItemCollection") Then
		Return "StructureTableItemsCollection";
	
	ElsIf Type = Type("DataCompositionChart") Then
		Return "Chart";
	ElsIf Type = Type("DataCompositionChartGroup") Then
		Return "ChartGrouping";
	ElsIf Type = Type("DataCompositionChartStructureItemCollection") Then
		Return "ChartStructureItemsCollection";
	
	ElsIf Type = Type("DataCompositionDataParameterValues") Then
		Return "DataParametersValues";
	
	Else
		Return "";
	EndIf;
EndFunction

Procedure AttachSchema(Report, Context, Scheme, SchemaKey) Export
	FormEvent = (TypeOf(Context) = Type("ClientApplicationForm"));
	
	Report.DataCompositionSchema = Scheme;
	If FormEvent Then
		ReportSettings = Context.ReportSettings;
		SchemaURL = ReportSettings.SchemaURL;
		ReportSettings.Insert("SchemaModified", True);
	Else
		SchemaURLFilled = (TypeOf(Context.SchemaURL) = Type("String") And IsTempStorageURL(Context.SchemaURL));
		If Not SchemaURLFilled Then
			FormID = CommonUseClientServer.StructureProperty(Context, "FormID");
			If TypeOf(FormID) = Type("UUID") Then
				SchemaURLFilled = True;
				Context.SchemaURL = PutToTempStorage(Scheme, FormID);
			EndIf;
		EndIf;
		If SchemaURLFilled Then
			SchemaURL = Context.SchemaURL;
		Else
			SchemaURL = PutToTempStorage(Scheme);
		EndIf;
		Context.SchemaModified = True;
	EndIf;
	PutToTempStorage(Scheme, SchemaURL);
	
	ReportVariant = ?(FormEvent, ReportSettings.VariantRef, Undefined);
	InitializeSettingsComposer(Report.SettingsComposer, SchemaURL, Report, ReportVariant);
	
	If FormEvent Then
		ValueToFormData(Report, Context.Report);
	EndIf;
EndProcedure

// Инициализирует компоновщик настроек компоновки данных, с обработкой исключения.
//
// Parameters:
//  SettingsComposer - DataCompositionSettingsComposer - компоновщик настроек, который необходимо инициализировать.
//  Scheme - DataCompositionSchema, URL - See синтакс-помощник: DataCompositionAvailableSettingsSource.
//  Report - ReportObject, Undefined - отчет, чей компоновщик инициализируется.
//  ReportVariant - СправочникСсылка.ВариантыОтчета, Undefined - хранилище варианта отчета.
//
Procedure InitializeSettingsComposer(SettingsComposer, Scheme, Report = Undefined, ReportVariant = Undefined) Export 
	Try
		SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(Scheme));
	Except
		EventName = NStr("en='Ошибка инициализации компоновщика настроек компоновки данных.';ru='Ошибка инициализации компоновщика настроек компоновки данных.';vi='Lỗi khi khởi chạy trình liên kết cài đặt thành phần dữ liệu.'",
			CommonUse.MainLanguageCode());
		
		MetadataObject = Undefined;
		If Report <> Undefined Then 
			MetadataObject = Report.Metadata();
		ElsIf ReportVariant <> Undefined Then 
			MetadataObject = ReportVariant.Metadata();
		EndIf;
		
		Comment = DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(
			EventName, EventLogLevel.Error, MetadataObject, ReportVariant, Comment);
		
		Raise;
	EndTry;
EndProcedure

Function AddSelectedField(Where, NameOrDCField, Title = "") Export
	
	If TypeOf(Where) = Type("DataCompositionSettingsComposer") Then
		FieldsSelectedCD = Where.Settings.Selection;
	ElsIf TypeOf(Where) = Type("DataCompositionSettings") Then
		FieldsSelectedCD = Where.Selection;
	Else
		FieldsSelectedCD = Where;
	EndIf;
	
	If TypeOf(NameOrDCField) = Type("String") Then
		DCField = New DataCompositionField(NameOrDCField);
	Else
		DCField = NameOrDCField;
	EndIf;
	
	SelectedFieldKD = FieldsSelectedCD.Items.Add(Type("DataCompositionSelectedField"));
	SelectedFieldKD.Field = DCField;
	If Title <> "" Then
		SelectedFieldKD.Title = Title;
	EndIf;
	
	Return SelectedFieldKD;
	
EndFunction

Procedure InitializePredefinedOutputParameters(Context, Settings) Export 
	If Settings = Undefined Then 
		Return;
	EndIf;
	
	OutputParameters = Settings.OutputParameters.Items;
	
	// Параметр Заголовок всегда доступен и только в форме настроек отчета.
	Object = OutputParameters.Find("TITLE");
	Object.ViewMode = DataCompositionSettingsItemViewMode.Normal;
	Object.UserSettingID = "";
	
	SetReportTitleByDefault(Object, Context);
	
	// Параметр ВыводитьЗаголовок всегда недоступный. Свойства зависят от параметра Заголовок.
	LinkedObject = OutputParameters.Find("TITLEOUTPUT");
	LinkedObject.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	LinkedObject.UserSettingID = "";
	LinkedObject.Use = True;
	
	If Object.Use Then 
		LinkedObject.Value = DataCompositionTextOutputType.Auto;
	Else
		LinkedObject.Value = DataCompositionTextOutputType.DontOutput;
	EndIf;
	
	// Параметр ВыводитьПараметры всегда доступен и только в форме настроек отчета.
	Object = OutputParameters.Find("DATAPARAMETERSOUTPUT");
	Object.ViewMode = DataCompositionSettingsItemViewMode.Normal;
	Object.UserSettingID = "";
	Object.Use = True;
	
	If Object.Value <> DataCompositionTextOutputType.DontOutput Then 
		Object.Value = DataCompositionTextOutputType.Auto;
	EndIf;
	
	// Параметр ВыводитьОтбор всегда недоступный. Значения свойств те же, что и у параметра ВыводитьПараметрыДанных.
	LinkedObject = OutputParameters.Find("FILTEROUTPUT");
	LinkedObject.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	LinkedObject.UserSettingID = "";
	LinkedObject.Use = True;
	
	If LinkedObject.Value <> DataCompositionTextOutputType.DontOutput Then 
		LinkedObject.Value = DataCompositionTextOutputType.Auto;
	EndIf;
EndProcedure

Procedure SetReportTitleByDefault(Title, Context)
	If ValueIsFilled(Title.Value) Then 
		Return;
	EndIf;
	
	ReportId = CommonUseClientServer.StructureProperty(Context, "ReportRef");
	If ReportId = Undefined Then 
		Return;
	EndIf;
	
	IsAdditionalReportOrDataProcessorType = False;
	
	If TypeOf(ReportId) = Type("String")
		Or IsAdditionalReportOrDataProcessorType Then 
		Title.Value = CommonUseClientServer.StructureProperty(Context, "Description", "");
		Return;
	EndIf;
	
	Variant = CommonUseClientServer.StructureProperty(Context, "VariantRef");
	If ValueIsFilled(Variant) Then 
		Title.Value = CommonUse.ObjectAttributeValue(Variant, "Description");
	EndIf;
	
	If ValueIsFilled(Title.Value)
		And Title.Value <> "Main" Then 
		Return;
	EndIf;
	
	MetadataOfReport = CommonUse.MetadataObjectByID(ReportId);
	If TypeOf(MetadataOfReport) = Type("MetadataObject") Then 
		Title.Value = MetadataOfReport.Presentation();
	EndIf;
EndProcedure

Function ValueInArray(Value) Export
	If TypeOf(Value) = Type("Array") Then
		Return Value;
	Else
		Array = New Array;
		Array.Add(Value);
		Return Array;
	EndIf;
EndFunction

Function SettingsItemByFullPath(Val Settings, Val FullPathToItem) Export
	Indexes = StrSplit(FullPathToItem, "/", False);
	SettingsItem = Settings;
	
	For Each IndexOf In Indexes Do
		If IndexOf = "Rows" Then
			SettingsItem = SettingsItem.Rows;
		ElsIf IndexOf = "Columns" Then
			SettingsItem = SettingsItem.Columns;
		ElsIf IndexOf = "Series" Then
			SettingsItem = SettingsItem.Series;
		ElsIf IndexOf = "Points" Then
			SettingsItem = SettingsItem.Points;
		ElsIf IndexOf = "Structure" Then
			SettingsItem = SettingsItem.Structure;
		ElsIf IndexOf = "Settings" Then
			SettingsItem = SettingsItem.Settings;
		Else
			SettingsItem = SettingsItem[Number(IndexOf)];
		EndIf;
	EndDo;
	
	Return SettingsItem;
EndFunction

#EndRegion
