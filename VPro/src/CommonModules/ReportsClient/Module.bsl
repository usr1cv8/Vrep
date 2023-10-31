////////////////////////////////////////////////////////////////////////////////
// Work methods with the DAS from the report form (client).
//
////////////////////////////////////////////////////////////////////////////////

#Region ServiceProceduresAndFunctions

Procedure LinkerListSelectionBegin(Form, Item, ChoiceData, StandardProcessing) Export
	StandardProcessing = False;
	
	ItemIdentificator = Right(Item.Name, 32);
	DCUsersSetting = FindElementsUsersSetup(Form, ItemIdentificator);
	AdditionalSettings = FindAdditionalItemSettings(Form, ItemIdentificator);
	If AdditionalSettings = Undefined Then
		Return;
	EndIf;
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("Form", Form);
	HandlerParameters.Insert("ItemIdentificator", ItemIdentificator);
	Handler = New NotifyDescription("LinkerListEndSelection", ThisObject, HandlerParameters);
	
	If TypeOf(DCUsersSetting) = Type("DataCompositionFilterItem") Then
		Value = DCUsersSetting.RightValue;
	Else
		Value = DCUsersSetting.Value;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("UniqueKey", ItemIdentificator);
	FormParameters.Insert("marked", ReportsClientServer.ValueList(Value));
	CommonUseClientServer.ExpandStructure(FormParameters, AdditionalSettings, True);
	
	FormParameters.Insert("ChoiceParameters", New Array);
	
	// Add the fixed selection parameters.
	For Each ChoiceParameter IN Item.ChoiceParameters Do
		If IsBlankString(ChoiceParameter.Name) Then
			Continue;
		EndIf;
		If ValueIsFilled(ChoiceParameter.Name) Then
			FormParameters.ChoiceParameters.Add(ChoiceParameter);
		EndIf;
	EndDo;
	
	// Insert dynamic selection parameters (from leading). For the backward compatibility.
	For Each ChoiceParameterLink IN Item.ChoiceParameterLinks Do
		If IsBlankString(ChoiceParameterLink.Name) Then
			Continue;
		EndIf;
		LeaderValue = Form[ChoiceParameterLink.DataPath];
		FormParameters.ChoiceParameters.Add(New ChoiceParameter(ChoiceParameterLink.Name, LeaderValue));
	EndDo;
	
	// Insert dynamic selection parameters (from leading).
	Found = Form.DisabledLinks.FindRows(New Structure("SubordinateIdentifierInForm", ItemIdentificator));
	For Each Link IN Found Do
		If Not ValueIsFilled(Link.LeadingIdentifierInForm)
			Or Not ValueIsFilled(Link.SubordinateNameParameter) Then
			Continue;
		EndIf;
		LeaderDASetting = FindElementsUsersSetup(Form, Link.LeadingIdentifierInForm);
		If Not LeaderDASetting.Use Then
			Continue;
		EndIf;
		If TypeOf(LeaderDASetting) = Type("DataCompositionFilterItem") Then
			LeaderValue = LeaderDASetting.RightValue;
		Else
			LeaderValue = LeaderDASetting.Value;
		EndIf;
		If Link.LinkType = "ParametersSelect" Then
			FormParameters.ChoiceParameters.Add(New ChoiceParameter(Link.SubordinateNameParameter, LeaderValue));
		ElsIf Link.LinkType = "ByType" Then
			LeadingType = TypeOf(LeaderValue);
			If FormParameters.TypeDescription.ContainsType(LeadingType) AND FormParameters.TypeDescription.Types().Count() > 1 Then
				TypeArray = New Array;
				TypeArray.Add(LeadingType);
				FormParameters.TypeDescription = New TypeDescription(TypeArray);
			EndIf;
		EndIf;
	EndDo;
	
	Block = FormWindowOpeningMode.LockOwnerWindow;
	
	OpenForm("CommonForm.EnterValuesListWithCheckBoxes", FormParameters, ThisObject, , , , Handler, Block);
EndProcedure

Procedure LinkerListEndSelection(ChoiceResult, HandlerParameters) Export
	If TypeOf(ChoiceResult) <> Type("ValueList") Then
		Return;
	EndIf;
	Form = HandlerParameters.Form;
	
	ItemIdentificator = HandlerParameters.ItemIdentificator;
	
	DCUsersSetting = FindElementsUsersSetup(Form, ItemIdentificator);
	AdditionalSettings = FindAdditionalItemSettings(Form, ItemIdentificator);
	
	// Import selected values in 2 lists.
	ValueListInDAS = New ValueList;
	If Not AdditionalSettings.LimitChoiceWithSpecifiedValues Then
		AdditionalSettings.ValuesForSelection = New ValueList;
	EndIf;
	For Each ListItemInForm IN ChoiceResult Do
		ValueInForm = ListItemInForm.Value;
		If Not AdditionalSettings.LimitChoiceWithSpecifiedValues Then
			If AdditionalSettings.ValuesForSelection.FindByValue(ValueInForm) <> Undefined Then
				Continue;
			EndIf;
			FillPropertyValues(AdditionalSettings.ValuesForSelection.Add(), ListItemInForm, "Value,Presentation");
		EndIf;
		If ListItemInForm.Check Then
			If TypeOf(ValueInForm) = Type("TypeDescription") Then
				ValueInDAS = ValueInForm.Types()[0];
			Else
				ValueInDAS = ValueInForm;
			EndIf;
			ReportsClientServer.AddUniqueValueInList(ValueListInDAS, ValueInDAS, ListItemInForm.Presentation, True);
		EndIf;
	EndDo;
	If TypeOf(DCUsersSetting) = Type("DataCompositionFilterItem") Then
		DCUsersSetting.RightValue = ValueListInDAS;
	Else
		DCUsersSetting.Value = ValueListInDAS;
	EndIf;
	
	// Select the Use check box.
	DCUsersSetting.Use = True;
	
	Form.UserSettingsModified = True;
	#If WebClient Or MobileClient Then
		Form.RefreshDataRepresentation();
	#EndIf
EndProcedure

Function FindElementsUsersSetup(Form, ItemIdentificator) Export
	// For custom settings, data composition IDs are stored as they can not be stored as a reference (value copy is in progress).
	SettingsComposer = ReportsClientServer.SettingsComposer(Form);
	DCIdentifier = Form.FastSearchOfUserSettings.Get(ItemIdentificator);
	If DCIdentifier = Undefined Then
		Return Undefined;
	Else
		Return SettingsComposer.UserSettings.GetObjectByID(DCIdentifier);
	EndIf;
EndFunction

Function FindAdditionalItemSettings(Form, ItemIdentificator) Export
	// For custom settings, data composition IDs are stored as they can not be stored as a reference (value copy is in progress).
	SettingsComposer = ReportsClientServer.SettingsComposer(Form);
	AllAdditionalSettings = CommonUseClientServer.StructureProperty(SettingsComposer.UserSettings.AdditionalProperties, "FormItems");
	If AllAdditionalSettings = Undefined Then
		Return Undefined;
	Else
		Return AllAdditionalSettings[ItemIdentificator];
	EndIf;
EndFunction

#EndRegion

#Region UniversalReport

Function ValueTypeRestrictedByLinkByType(Settings, UserSettings, SettingItem, SettingItemDetails, ValueType = Undefined) Export 
	If SettingItemDetails = Undefined Then 
		Return ?(ValueType = Undefined, New TypeDescription("Undefined"), ValueType);
	EndIf;
	
	If ValueType = Undefined Then 
		ValueType = SettingItemDetails.ValueType;
	EndIf;
	
	TypeLink = SettingItemDetails.TypeLink;
	
	LinkedSettingItem = SettingItemByField(Settings, UserSettings, TypeLink.Field);
	If LinkedSettingItem = Undefined Then 
		Return ValueType;
	EndIf;
	
	AllowedComparisonKinds = New Array;
	AllowedComparisonKinds.Add(DataCompositionComparisonType.Equal);
	AllowedComparisonKinds.Add(DataCompositionComparisonType.InHierarchy);
	
	If TypeOf(LinkedSettingItem) = Type("DataCompositionFilterItem")
		And (Not LinkedSettingItem.Use
		Or AllowedComparisonKinds.Find(LinkedSettingItem.ComparisonType) = Undefined) Then 
		Return ValueType;
	EndIf;
	
	LinkedSettingItemDetails = ReportsClientServer.FindAvailableSetting(Settings, LinkedSettingItem);
	If LinkedSettingItemDetails = Undefined Then 
		Return ValueType;
	EndIf;
	
	If TypeOf(LinkedSettingItem) = Type("DataCompositionSettingsParameterValue")
		And (LinkedSettingItemDetails.Use <> DataCompositionParameterUse.Always
		Or Not LinkedSettingItem.Use) Then 
		Return ValueType;
	EndIf;
	
	If TypeOf(LinkedSettingItem) = Type("DataCompositionSettingsParameterValue") Then 
		LinkedSettingItemValue = LinkedSettingItem.Value;
	ElsIf TypeOf(LinkedSettingItem) = Type("DataCompositionFilterItem") Then 
		LinkedSettingItemValue = LinkedSettingItem.RightValue;
	EndIf;
	
	ExtDimensionType = ReportsOptionsServerCall.ExtDimensionType(LinkedSettingItemValue, TypeLink.LinkItem);
	If TypeOf(ExtDimensionType) = Type("TypeDescription") Then
		LinkedTypes = ExtDimensionType.Types();
	Else
		LinkedTypes = LinkedSettingItemDetails.ValueType.Types();
	EndIf;
	
	DeductionTypes = ValueType.Types();
	IndexOf = DeductionTypes.UBound();
	While IndexOf >= 0 Do 
		If LinkedTypes.Find(DeductionTypes[IndexOf]) <> Undefined Then 
			DeductionTypes.Delete(IndexOf);
		EndIf;
		IndexOf = IndexOf - 1;
	EndDo;
	
	Return New TypeDescription(ValueType,, DeductionTypes);
EndFunction

Function SettingItemByField(Settings, UserSettings, Field)
	SettingItem = DataParametersItemByField(Settings, UserSettings, Field);
	
	If SettingItem = Undefined Then 
		FindFilterItemByField(Field, Settings.Filter.Items, UserSettings, SettingItem);
	EndIf;
	
	Return SettingItem;
EndFunction

Procedure FindFilterItemByField(Field, FilterItems, UserSettings, SettingItem)
	For Each Item In FilterItems Do 
		If TypeOf(Item) = Type("DataCompositionFilterItemGroup") Then 
			FindFilterItemByField(Field, Item.Items, UserSettings, SettingItem)
		Else
			UserItem = UserSettings.Find(Item.UserSettingID);
			ItemToAnalyse = ?(UserItem = Undefined, Item, UserItem);
			
			If ItemToAnalyse.Use And Item.LeftValue = Field Then 
				SettingItem = ItemToAnalyse;
				Break;
			EndIf;
		EndIf;
	EndDo;
EndProcedure

Function DataParametersItemByField(Settings, UserSettings, Field)
	If TypeOf(Settings) <> Type("DataCompositionSettings") Then 
		Return Undefined;
	EndIf;
	
	SettingsItems = Settings.DataParameters.Items;
	For Each Item In SettingsItems Do 
		UserItem = UserSettings.Find(Item.UserSettingID);
		ItemToAnalyse = ?(UserItem = Undefined, Item, UserItem);
		
		Fields = New Array;
		Fields.Add(New DataCompositionField(String(Item.Parameter)));
		Fields.Add(New DataCompositionField("DataParameters." + String(Item.Parameter)));
		
		If ItemToAnalyse.Use
			And (Fields[0] = Field Or Fields[1] = Field) Then 
			
			Return ItemToAnalyse;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

Function FullPathToSettingsItem(Val Settings, Val SettingsItem) Export
	Result = New Array;
	SettingsItemParent = SettingsItem;
	
	While SettingsItemParent <> Undefined
		And SettingsItemParent <> Settings Do
		
		SettingsItem = SettingsItemParent;
		SettingsItemParent = SettingsItemParent.Parent;
		ParentType = TypeOf(SettingsItemParent);
		
		If ParentType = Type("DataCompositionTable") Then
			IndexOf = SettingsItemParent.Rows.IndexOf(SettingsItem);
			If IndexOf = -1 Then
				IndexOf = SettingsItemParent.Columns.IndexOf(SettingsItem);
				CollectionName = "Columns";
			Else
				CollectionName = "Rows";
			EndIf;
		ElsIf ParentType = Type("DataCompositionChart") Then
			IndexOf = SettingsItemParent.Series.IndexOf(SettingsItem);
			If IndexOf = -1 Then
				IndexOf = SettingsItemParent.Points.IndexOf(SettingsItem);
				CollectionName = "Points";
			Else
				CollectionName = "Series";
			EndIf;
		ElsIf ParentType = Type("DataCompositionNestedObjectSettings") Then
			CollectionName = "Settings";
			IndexOf = Undefined;
		Else
			CollectionName = "Structure";
			IndexOf = SettingsItemParent.Structure.IndexOf(SettingsItem);
		EndIf;
		
		If IndexOf = -1 Then
			Return Undefined;
		EndIf;
		
		If IndexOf <> Undefined Then
			Result.Insert(0, IndexOf);
		EndIf;
		
		Result.Insert(0, CollectionName);
	EndDo;
	
	Return StrConcat(Result, "/");
	
EndFunction

Function OnAddToCollectionNeedToSpecifyPointType(CollectionType) Export
	Return CollectionType <> Type("DataCompositionTableStructureItemCollection")
		And CollectionType <> Type("DataCompositionChartStructureItemCollection")
		And CollectionType <> Type("DataCompositionConditionalAppearanceItemCollection");
EndFunction

Procedure SelectPeriod(Form, CommandName) Export
	Path = StrReplace(CommandName, "SelectPeriod", "Period");
	Context = New Structure("Form, Path", Form, Path);
	
	Dialog = New StandardPeriodEditDialog;
	Dialog.Period = Form[Path];
	Dialog.Show(New NotifyDescription("SelectPeriodCompletion", ThisObject, Context));
	
EndProcedure

Procedure SelectPeriodCompletion(SelectedPeriod, Context) Export 
	If SelectedPeriod = Undefined Then 
		Return;
	EndIf;
	
	Context.Form[Context.Path] = SelectedPeriod;
	SetPeriod(Context.Form, Context.Path);
	
EndProcedure

Procedure SetPeriod(Form, Val Path) Export
	
	SettingsComposer = Form.Report.SettingsComposer;
	
	Properties = StrSplit("BeginDate, EndDate", ", ", False);
	For Each Property In Properties Do 
		Path = StrReplace(Path, Property, "");
	EndDo;
	
	IndexOf = Form.PathToItemsData.ByName[Path];
	If IndexOf = Undefined Then 
		Path = Path + "Period";
		IndexOf = Form.PathToItemsData.ByName[Path];
	EndIf;
	
	UserSettingsItem = SettingsComposer.UserSettings.Items[IndexOf];
	UserSettingsItem.Use = True;
	
	If TypeOf(UserSettingsItem) = Type("DataCompositionSettingsParameterValue") Then 
		UserSettingsItem.Value = Form[Path];
	Else // Элемент отбора.
		UserSettingsItem.RightValue = Form[Path];
	EndIf;
	
EndProcedure

Procedure GenerateReport(ReportForm, EndProcessor = Undefined) Export
	
	If TypeOf(EndProcessor) = Type("NotifyDescription") Then
		ReportForm.HandlerAfterGenerateAtClient = EndProcessor;
	EndIf;
	ReportForm.AttachIdleHandler("Generate", 0.1, True);
	
EndProcedure

#EndRegion