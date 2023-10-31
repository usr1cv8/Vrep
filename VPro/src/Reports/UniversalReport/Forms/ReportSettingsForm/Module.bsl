///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2020, ООО 1С-Софт
// Все права защищены. Эта программа и сопроводительные материалы предоставляются 
// в соответствии с условиями лицензии Attribution 4.0 International (CC BY 4.0)
// Текст лицензии доступен по ссылке:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var DragSourceAtClient;
&AtClient
Var DragDestinationAtClient;

#EndRegion

#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(cancel, StandardProcessing)
	SetConditionalAppearance();
	
	DefineBehaviorInMobileClient();
	
	ParametersForm = New Structure(
		"PurposeUseKey, UserSettingsKey,
		|Details, GenerateOnOpen, ReadOnly,
		|FixedSettings, Section, Subsystem, SubsystemPresentation");
	FillPropertyValues(ParametersForm, Parameters);
	ParametersForm.Insert("Filter", New Structure);
	If TypeOf(Parameters.Filter) = Type("Structure") Then
		CommonUseClientServer.ExpandStructure(ParametersForm.Filter, Parameters.Filter, True);
		Parameters.Filter.Clear();
	EndIf;
	
	If Not Parameters.Property("ReportSettings", ReportSettings) Then
		Raise NStr("en='Service parameter not passed ""ReportSettings"".';ru='Не передан служебный параметр ""НастройкиОтчета"".';vi='Chưa chuyển tham số dịch vụ ""НастройкиОтчета"".'");
	EndIf;
	
	If Not Parameters.Property("OptionName", OptionName) Then
		Raise NStr("en='Service parameter not passed ""OptionName"".';ru='Не передан служебный параметр ""ВариантНаименование"".';vi='Chưa chuyển tham số dịch vụ ""ВариантНаименование"".'");
	EndIf;
	
	WindowOptionsKey = ReportSettings.FullName;
	If ValueIsFilled(CurrentVariantKey) Then
		WindowOptionsKey = WindowOptionsKey + "." + CurrentVariantKey;
	EndIf;
	
	DCSettings = CommonUseClientServer.StructureProperty(Parameters, "Variant");
	If DCSettings = Undefined Then
		DCSettings = Report.SettingsComposer.Settings;
	EndIf;
	
	Parameters.Property("SettingsStructureItemID", SettingsStructureItemID);
	If TypeOf(SettingsStructureItemID) = Type("DataCompositionID") Then
		SettingsStructureItemChangeMode = True;
		Height = 0;
		WindowOptionsKey = WindowOptionsKey + ".Node";
		
		PathToSettingsStructureItem = CommonUseClientServer.StructureProperty(
			Parameters, "PathToSettingsStructureItem", "");
		
		StructureItem = ReportsServer.SettingsItemByFullPath(DCSettings, PathToSettingsStructureItem);
		If StructureItem <> Undefined Then
			SettingsStructureItemID = DCSettings.GetIDByObject(StructureItem);
		EndIf;
		
		If Not Parameters.Property("Title", Title) Then
			Raise NStr("en='Не передан служебный параметр ""Заголовок"".';ru='Не передан служебный параметр ""Заголовок"".';vi='Chưa chuyển tham số dịch vụ ""Tiêu đề"".'");
		EndIf;
		
		If Not Parameters.Property("SettingsStructureItemType", SettingsStructureItemType) Then
			Raise NStr("en='Service parameter not passed ""SettingsStructureItemType"".';ru='Не передан служебный параметр ""ТипЭлементаСтруктурыНастроек"".';vi='Chưa chuyển tham số dịch vụ ""ТипЭлементаСтруктурыНастроек"".'");
		EndIf;
	Else
		If Not ValueIsFilled(OptionName) Then
			OptionName = ReportSettings.Description;
		EndIf;
		
		Title = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("ru = 'Настройки отчета ""%1""';
				|en = 'Report's setting ""%1""';"), OptionName);
	EndIf;
	
	GlobalSettings = ReportsVariants.GlobalSettings();
	Items.AppearanceCustomizeHeadersFooters.Visible = Not SettingsStructureItemChangeMode;
	
	If SettingsStructureItemChangeMode Then
		PageName = CommonUseClientServer.StructureProperty(Parameters, "PageName", "PageGroupingContent");
		ExtendedMode = 1;
	Else
		ExtendedMode = CommonUseClientServer.StructureProperty(ReportSettings, "SettingsFormExtendedMode", 0);
		PageName = CommonUseClientServer.StructureProperty(ReportSettings, "SettingsFormPageName", "PageFilters");
	EndIf;
	
	Page = Items.Find(PageName);
	If Page <> Undefined Then
		Items.SettingPages.CurrentPage = Page;
	EndIf;
	
	If ReportSettings.SchemaModified Then
		Report.SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(ReportSettings.SchemaURL));
	EndIf;
	
	ImportantInscriptionFont = Metadata.StyleItems.ImportantLabelFont;
	Items.VariantStructureTitle.Font = ImportantInscriptionFont.Value;
	
	// Регистрация команд и реквизитов формы, которые не удаляются при перезаполнении быстрых настроек.
	AttributesSet = GetAttributes();
	For Each Attribute In AttributesSet Do
		ConstantAttributes.Add(AttributeFullName(Attribute));
	EndDo;
	
	For Each Command In Commands Do
		ConstantCommands.Add(Command.Name);
	EndDo;
	
	SettingsUpdateRequired = True;
EndProcedure

&AtServer
Procedure BeforeLoadVariantAtServer(NewSettingsDC)
	
	If TypeOf(ParametersForm.Filter) = Type("Structure") Then
		ReportsServer.SetFixedFilters(ParametersForm.Filter, NewSettingsDC, ReportSettings);
	EndIf;
	
	SettingsUpdateRequired = True;
	
	// Подготовка к вызову события переинициализации.
	If ReportSettings.Events.BeforeImportSettingsToComposer Then
		Try
			NewXMLSettings = CommonUse.ValueToXMLString(NewSettingsDC);
		Except
			NewXMLSettings = Undefined;
		EndTry;
		ReportSettings.Insert("NewXMLSettings", NewXMLSettings);
	EndIf;
EndProcedure

&AtServer
Procedure BeforeLoadUserSettingsAtServer(NewDCUserSettings)
	
	SettingsUpdateRequired = True;
	
	// Подготовка к вызову события переинициализации.
	If ReportSettings.Events.BeforeImportSettingsToComposer Then
		Try
			NewUserXMLSettings = CommonUse.ValueToXMLString(NewDCUserSettings);
		Except
			NewUserXMLSettings = Undefined;
		EndTry;
		ReportSettings.Insert("NewUserXMLSettings", NewUserXMLSettings);
	EndIf;
EndProcedure

&AtServer
Procedure OnUpdateUserSettingSetAtServer(StandardProcessing)
	
	StandardProcessing = False;
	VariantModified = False;
	
	If SettingsUpdateRequired Then
		SettingsUpdateRequired = False;
		
		FillingParameters = New Structure;
		FillingParameters.Insert("EventName", "OnCreateAtServer");
		FillingParameters.Insert("UpdateVariantSettings", Not SettingsStructureItemChangeMode And ExtendedMode = 1);
		
		RefreshForm(FillingParameters);
	EndIf;
EndProcedure

&AtClient
Procedure BeforeClose(cancel, Exit, WarningText, StandardProcessing)
	VariantModified = False;
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Exit Then
		Return;
	EndIf;
	
	If SelectionResultGenerated Then
		Return;
	EndIf;
	
	If OnCloseNotifyDescription <> Undefined Then
		ExecuteNotifyProcessing(OnCloseNotifyDescription, ChoiceResult(False));
	EndIf;
EndProcedure

#EndRegion

#Region HeaderFormItemsEventsHandlers

&AtClient
Procedure ExtendedModeOnChange(Item)
	UpdateParameters = New Structure;
	UpdateParameters.Insert("EventName", "ExtendedModeOnChange");
	UpdateParameters.Insert("DCSettingsComposer", Report.SettingsComposer);
	UpdateParameters.Insert("UpdateVariantSettings", ExtendedMode = 1);
	UpdateParameters.Insert("ResetUserSettings", ExtendedMode <> 1);
	
	RefreshForm(UpdateParameters);
EndProcedure

&AtClient
Procedure NoUserSettingsWarningsURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	ExtendedMode = 1;
	ExtendedModeOnChange(Undefined);
EndProcedure

&AtClient
Procedure CurrentChartTypeOnChange(Item)
	StructureItem = Report.SettingsComposer.Settings.GetObjectByID(SettingsStructureItemID);
	If TypeOf(StructureItem) = Type("DataCompositionNestedObjectSettings") Then
		StructureItem = StructureItem.Settings;
	EndIf;
	
	SetOutputParameter(StructureItem, "ChartType", CurrentChartType);
	SetModified();
EndProcedure

&AtClient
Procedure TooltipThereAreNestedReportsDataProcessorNavigationRefs(Item, Address, StandardProcessing)
	StandardProcessing = False;
	Row = Items.VariantStructure.CurrentData;
	ChangeStructureItem(Row,, True);
EndProcedure

&AtClient
Procedure TitleOutputOnChange(Item)
	PredefinedParameters = Report.SettingsComposer.Settings.OutputParameters.Items;
	
	SettingItem = PredefinedParameters.Find("TITLE");
	SettingItem.Use = TitleOutput;
	
	SynchronizePredefinedOutputParameters(TitleOutput, SettingItem);
	SetModified();
EndProcedure

&AtClient
Procedure DisplayParametersAndFiltersOnChange(Item)
	PredefinedParameters = Report.SettingsComposer.Settings.OutputParameters.Items;
	
	SettingItem = PredefinedParameters.Find("DATAPARAMETERSOUTPUT");
	SettingItem.Use = True;
	
	If DisplayParametersAndFilters Then 
		SettingItem.Value = DataCompositionTextOutputType.Auto;
	Else
		SettingItem.Value = DataCompositionTextOutputType.DontOutput;
	EndIf;
	
	SynchronizePredefinedOutputParameters(DisplayParametersAndFilters, SettingItem);
	SetModified();
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Подключаемые

&AtClient
Procedure Attachable_Period_OnChange(Item)
	ReportsClient.SetPeriod(ThisObject, Item.Name);
EndProcedure

&AtClient
Procedure Attachable_SettingItem_OnChange(Item)
	SettingsComposer = Report.SettingsComposer;
	
	IndexOf = PathToItemsData.ByName[Item.Name];
	If IndexOf = Undefined Then 
		IndexOf = ReportsClientServer.SettingItemIndexByPath(Item.Name);
	EndIf;
	
	SettingItem = SettingsComposer.UserSettings.Items[IndexOf];
	
	IsFlag = StrStartsWith(Item.Name, "CheckBox") Or StrEndsWith(Item.Name, "CheckBox");
	If IsFlag Then 
		SettingItem.Value = ThisObject[Item.Name];
	EndIf;
	
	If TypeOf(SettingItem) = Type("DataCompositionSettingsParameterValue")
		And ReportSettings.ImportSettingsOnChangeParameters.Find(SettingItem.Parameter) <> Undefined Then 
		
		UpdateParameters = New Structure;
		UpdateParameters.Insert("DCSettingsComposer", SettingsComposer);
		
		RefreshForm(UpdateParameters);
	Else
		RegisterList(Item, SettingItem);
	EndIf;
EndProcedure

&AtClient
Procedure Attachable_ListItem_OnChange(Item)
	ListPath = StrReplace(Item.Name, "Value", "");
	
	Row = Items[ListPath].CurrentData;
	
	ListElement = ThisObject[ListPath].FindByValue(Row.Value);
	ListElement.Check = True;
EndProcedure

&AtClient
Procedure Attachable_List_OnChange(Item)
	SettingsComposer = Report.SettingsComposer;
	
	IndexOf = PathToItemsData.ByName[Item.Name];
	SettingItem = SettingsComposer.UserSettings.Items[IndexOf];
	
	List = ThisObject[Item.Name];
	SelectedValues = New ValueList;
	For Each ListElement In List Do 
		If ListElement.Check Then 
			FillPropertyValues(SelectedValues.Add(), ListElement);
		EndIf;
	EndDo;
	
	If TypeOf(SettingItem) = Type("DataCompositionSettingsParameterValue") Then 
		SettingItem.Value = SelectedValues;
	ElsIf TypeOf(SettingItem) = Type("DataCompositionFilterItem") Then 
		SettingItem.RightValue = SelectedValues;
	EndIf;
	SettingItem.Use = True;
	
	ReportsClient.CacheFilterValue(
		List, SettingItem.UserSettingID, SettingsComposer);
	
	RegisterList(Item, SettingItem);
EndProcedure

&AtClient
Procedure Attachable_ListItem_StartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	
	ListPath = StrReplace(Item.Name, "Value", "");
	
	FillingParameters = ListFillingParameters(True, False, False);
	FillingParameters.ListPath = ListPath;
	FillingParameters.IndexOf = PathToItemsData.ByName[ListPath];
	FillingParameters.Owner = Item;
	
	StartListFilling(Item, FillingParameters);
EndProcedure

&AtClient
Procedure Attachable_List_ChoiceProcessing(Item, ChoiceResult, StandardProcessing)
	StandardProcessing = False;
	
	List = ThisObject[Item.Name];
	
	Chosen = ReportsClientServer.ValueList(ChoiceResult);
	Chosen.FillChecks(True);
	
	AddOn = ReportsClientServer.ExpandList(List, Chosen, False, True);
	
	IndexOf = PathToItemsData.ByName[Item.Name];
	SettingsComposer = Report.SettingsComposer;
	SettingItem = SettingsComposer.UserSettings.Items[IndexOf];
	
	If TypeOf(SettingItem) = Type("DataCompositionSettingsParameterValue") Then
		SettingItem.Value = List;
	Else
		SettingItem.RightValue = List;
	EndIf;
	SettingItem.Use = True;
	
	RegisterList(Item, SettingItem);
	
	If AddOn.Total > 0 Then
		If AddOn.Total = 1 Then
			NotificationTitle = NStr("en='Элемент добавлен в список';ru='Элемент добавлен в список';vi='Phần tử được thêm vào danh sách'");
		Else
			NotificationTitle = NStr("en='Элементы добавлены в список';ru='Элементы добавлены в список';vi='Các phần tử được thêm vào danh sách'");
		EndIf;
		
		ShowUserNotification(
			NotificationTitle,,
			String(Chosen),
			PictureLib.ExecuteTask);
	EndIf;
	
	ReportsClient.CacheFilterValue(
		List, SettingItem.UserSettingID, SettingsComposer);
	
	SetModified();
EndProcedure

#EndRegion

#Region FormTableItemsEventsHandlersSorting

&AtClient
Procedure SortSelection(Item, RowID, Field, StandardProcessing)
	StandardProcessing = False;
	
	Row = Items.Sort.CurrentData;
	If Row = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(Row.Field) = Type("DataCompositionField") Then
		If Field = Items.SortField Then // Изменение поля
			SortingSelectField(RowID, Row);
		ElsIf Field = Items.SortOrderType Then // Изменение порядка.
			ChangeOrderType(Row);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure SortBeforeAddRow(Item, cancel, Copy, Parent, Var_Group, Parameter)
	cancel = True;
	SelectField("Sort", New NotifyDescription("SortingAfterFieldSelection", ThisObject));
EndProcedure

&AtClient
Procedure SortBeforeDeleteRow(Item, cancel)
	DeleteRows(Item, cancel);
EndProcedure

&AtClient
Procedure SortUseOnChange(Item)
	ChangeSettingItemUsage("Sort");
EndProcedure

&AtClient
Procedure Sort_Descending(Command)
	ChangeRowsOrderType(DataCompositionSortDirection.Desc);
EndProcedure

&AtClient
Procedure Sort_Ascending(Command)
	ChangeRowsOrderType(DataCompositionSortDirection.Asc);
EndProcedure

&AtClient
Procedure Sort_MoveUp(Command)
	ShiftSorting();
EndProcedure

&AtClient
Procedure Sort_MoveDown(Command)
	ShiftSorting(False);
EndProcedure

&AtClient
Procedure Sorting_SelectCheckBoxes(Command)
	ChangeUsage("Sort");
EndProcedure

&AtClient
Procedure Sorting_ClearCheckBoxes(Command)
	ChangeUsage("Sort", False);
EndProcedure

&AtClient
Procedure SortDragStart(Item, DragParameters, EnableDrag)
	DragSourceAtClient = Item.Name;
EndProcedure

&AtClient
Procedure SortDragCheck(Item, DragParameters, StandardProcessing, CurrentRow, Field)
	DragDestinationAtClient = Item.Name;
	
	If DragParameters.Value.Count() > 0 Then 
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure SortDrag(Item, DragParameters, StandardProcessing, CurrentRow, Field)
	StandardProcessing = False;
	If DragSourceAtClient = Item.Name Then 
		DragSortingWithinCollection(DragParameters, CurrentRow);
	ElsIf DragSourceAtClient = Items.SelectedFields.Name Then 
		DragSelectedFieldsToSorting(DragParameters.Value);
	EndIf;
EndProcedure

&AtClient
Procedure SortDragEnd(Item, DragParameters, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure SelectedFields_Sorting_Right(Command)
	RowsIDs = Items.SelectedFields.SelectedRows;
	If RowsIDs = Undefined Then 
		Return;
	EndIf;
	
	Rows = New Array;
	For Each RowID In RowsIDs Do 
		Row = SelectedFields.FindByID(RowID);
		If TypeOf(Row.ID) = Type("DataCompositionID") Then 
			Rows.Add(Row);
		EndIf;
	EndDo;
	
	DragSelectedFieldsToSorting(Rows);
EndProcedure

&AtClient
Procedure SelectedFields_Sorting_Left(Command)
	RowsIDs = Items.Sort.SelectedRows;
	If RowsIDs = Undefined Then 
		Return;
	EndIf;
	
	Rows = New Array;
	For Each RowID In RowsIDs Do 
		Row = Sort.FindByID(RowID);
		If TypeOf(Row.ID) = Type("DataCompositionID") Then 
			Rows.Add(Row);
		EndIf;
	EndDo;
	
	DragSortingFieldsToSelectedFields(Rows);
EndProcedure

&AtClient
Procedure SelectedFields_Sorting_LeftAll(Command)
	DragSortingFieldsToSelectedFields(Sort.GetItems()[0].GetItems());
EndProcedure

#EndRegion

#Region FormTableItemsEventsHandlersSelectedFields

&AtClient
Procedure SelectedFieldsSelection(Item, RowID, Field, StandardProcessing)
	StandardProcessing = False;
	
	Row = Items.SelectedFields.CurrentData;
	If Row = Undefined Then
		Return;
	EndIf;
	
	If Field = Items.SelectedFieldsField Then // Изменение порядка.
		If TypeOf(Row.Field) = Type("DataCompositionField") Then
			SelectedFieldsSelectField(RowID, Row);
		ElsIf Row.IsFolder Then
			SelectedFieldsSelectGroup(RowID, Row);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure SelectedFieldsBeforeAddRow(Item, cancel, Copy, Parent, Var_Group, Parameter)
	cancel = True;
	
	Handler = New NotifyDescription("SelectedFieldsAfterFieldSelection", ThisObject);
	SelectField("SelectedFields", Handler);
EndProcedure

&AtClient
Procedure SelectedFieldsBeforeDeleteRow(Item, cancel)
	If ExtendedMode = 0 Then
		cancel = True;
		Return;
	EndIf;
	DeleteRows(Item, cancel);
EndProcedure

&AtClient
Procedure SelectedFieldsUseOnChange(Item)
	ChangeSettingItemUsage("SelectedFields");
EndProcedure

&AtClient
Procedure SelectedFields_MoveUp(Command)
	ShiftSelectedFields();
EndProcedure

&AtClient
Procedure SelectedFields_MoveDown(Command)
	ShiftSelectedFields(False);
EndProcedure

&AtClient
Procedure SelectedFields_Group(Command)
	GroupingParameters = GroupingParametersOfSelectedFields();
	If GroupingParameters = Undefined Then 
		Return;
	EndIf;
	
	FormParameters = New Structure("Placement", DataCompositionFieldPlacement.Auto);
	Handler = New NotifyDescription("SelectedFieldsBeforeGroupFields", ThisObject, GroupingParameters);
	OpenForm("SettingsStorage.ReportsVariantsStorage.Form.SelectedFieldsGroup", FormParameters, 
		ThisObject, UUID,,, Handler, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure SelectedFields_Ungroup(Command)
	RowsIDs = Items.SelectedFields.SelectedRows;
	If RowsIDs.Count() <> 1 Then 
		ShowMessageBox(, NStr("en='Выберите одну группу.';ru='Выберите одну группу.';vi='Hãy chọn một nhóm.'"));
		Return;
	EndIf;
	
	SourceRowParent = SelectedFields.FindByID(RowsIDs[0]);
	If TypeOf(SourceRowParent.ID) <> Type("DataCompositionID") Then 
		ShowMessageBox(, NStr("en='Выберите группу.';ru='Выберите группу.';vi='Hãy chọn nhóm.'"));
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Selection", SettingsStructureItemID, ExtendedMode);
	
	SourceSettingItemParent = StructureItemProperty.GetObjectByID(SourceRowParent.ID);
	If TypeOf(SourceSettingItemParent) <> Type("DataCompositionSelectedFieldGroup") Then 
		ShowMessageBox(, NStr("en='Выберите группу.';ru='Выберите группу.';vi='Hãy chọn nhóm.'"));
		Return;
	EndIf;
	
	DestinationSettingItemParent = SourceSettingItemParent.Parent;
	If SourceSettingItemParent.Parent = Undefined Then 
		DestinationSettingItemParent = StructureItemProperty;
	EndIf;
	
	SettingsItemsInheritors = New Map;
	SettingsItemsInheritors.Insert(SourceSettingItemParent, DestinationSettingItemParent);
	
	DestinationRowParent = SourceRowParent.GetParent();
	RowsInheritors = New Map;
	RowsInheritors.Insert(SourceRowParent, DestinationRowParent);
	
	ChangeGroupingOfSelectedFields(StructureItemProperty, SourceRowParent.GetItems(), SettingsItemsInheritors, RowsInheritors);
	
	// Удаление базовых элементов группировки.
	DestinationRowParent.GetItems().Delete(SourceRowParent);
	DestinationSettingItemParent.Items.Delete(SourceSettingItemParent);
	
	Section = SelectedFields.GetItems()[0];
	Items.SelectedFields.Expand(Section.GetID(), True);
	Items.SelectedFields.CurrentRow = DestinationRowParent.GetID();
	
	SetModified();
EndProcedure

&AtClient
Procedure SelectedFields_SelectCheckBoxes(Command)
	ChangeUsage("SelectedFields");
EndProcedure

&AtClient
Procedure SelectedFields_ClearCheckBoxes(Command)
	ChangeUsage("SelectedFields", False);
EndProcedure

&AtClient
Procedure SelectedFieldsDragStart(Item, DragParameters, EnableDrag)
	DragSourceAtClient = Item.Name;
	
	CheckRowsToDragFromSelectedFields(DragParameters.Value);
	If DragParameters.Value.Count() = 0 Then 
		EnableDrag = False;
	EndIf;
EndProcedure

&AtClient
Procedure SelectedFieldsDragCheck(Item, DragParameters, StandardProcessing, CurrentRow, Field)
	DragDestinationAtClient = Item.Name;
	
	If DragParameters.Value.Count() > 0 Then 
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure SelectedFieldsDrag(Item, DragParameters, StandardProcessing, CurrentRow, Field)
	StandardProcessing = False;
	
	If DragSourceAtClient = Item.Name Then 
		DragSelectedFieldsWithinCollection(DragParameters, CurrentRow);
	EndIf;
EndProcedure

&AtClient
Procedure SelectedFieldsDragEnd(Item, DragParameters, StandardProcessing)
	If DragDestinationAtClient <> Item.Name Then 
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Selection", SettingsStructureItemID, ExtendedMode);
	
	Rows = DragParameters.Value;
	Parent = Rows[0].GetParent();
	
	IndexOf = Rows.UBound();
	While IndexOf >= 0 Do 
		Row = Rows[IndexOf];
		
		SettingItem = SettingItem(StructureItemProperty, Row);
		SettingItemParent = StructureItemProperty;
		If SettingItem.Parent <> Undefined Then 
			SettingItemParent = SettingItem.Parent;
		EndIf;
		
		SettingItemParent.Items.Delete(SettingItem);
		Parent.GetItems().Delete(Row);
		
		IndexOf = IndexOf - 1;
	EndDo;
EndProcedure

#EndRegion

#Region FormTableItemsEventsHandlersFilters

&AtClient
Procedure Filters_Group(Command)
	GroupingParameters = FiltersGroupingParameters();
	If GroupingParameters = Undefined Then 
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Filter", SettingsStructureItemID);
	
	// Обработка элементов настроек.
	SettingItemSource = StructureItemProperty;
	If TypeOf(GroupingParameters.Parent.ID) = Type("DataCompositionID") Then 
		SettingItemSource = StructureItemProperty.GetObjectByID(GroupingParameters.Parent.ID);
	EndIf;
	
	SettingItemDestination = SettingItemSource.Items.Insert(GroupingParameters.IndexOf, Type("DataCompositionFilterItemGroup"));
	SettingItemDestination.UserSettingID = New UUID;
	SettingItemDestination.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	SettingsItemsInheritors = New Map;
	SettingsItemsInheritors.Insert(SettingItemSource, SettingItemDestination);
	
	// Обработка строк.
	RowSource = GroupingParameters.Parent;
	RowReceiver = RowSource.GetItems().Insert(GroupingParameters.IndexOf);
	SetFiltersRowData(RowReceiver, StructureItemProperty, SettingItemDestination);
	RowReceiver.ID = StructureItemProperty.GetIDByObject(SettingItemDestination);
	
	RowsInheritors = New Map;
	RowsInheritors.Insert(RowSource, RowReceiver);
	
	ChangeFiltersGrouping(StructureItemProperty, GroupingParameters.Rows, SettingsItemsInheritors, RowsInheritors);
	DeleteBasicFiltersGroupingItems(StructureItemProperty, GroupingParameters);
	
	Section = DefaultRootRow("Filters");
	Items.Filters.Expand(Section.GetID(), True);
	Items.Filters.CurrentRow = RowReceiver.GetID();
	
	SetModified();
EndProcedure

&AtClient
Procedure Filters_Ungroup(Command)
	RowsIDs = Items.Filters.SelectedRows;
	If RowsIDs.Count() <> 1 Then 
		ShowMessageBox(, NStr("en='Выберите одну группу.';ru='Выберите одну группу.';vi='Hãy chọn một nhóm.'"));
		Return;
	EndIf;
	
	SourceRowParent = Filters.FindByID(RowsIDs[0]);
	If TypeOf(SourceRowParent.ID) <> Type("DataCompositionID") Then 
		ShowMessageBox(, NStr("en='Выберите группу.';ru='Выберите группу.';vi='Hãy chọn nhóm.'"));
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Filter", SettingsStructureItemID);
	
	SourceSettingItemParent = StructureItemProperty.GetObjectByID(SourceRowParent.ID);
	If TypeOf(SourceSettingItemParent) <> Type("DataCompositionFilterItemGroup") Then 
		ShowMessageBox(, NStr("en='Выберите группу.';ru='Выберите группу.';vi='Hãy chọn nhóm.'"));
		Return;
	EndIf;
	
	DestinationSettingItemParent = SourceSettingItemParent.Parent;
	If SourceSettingItemParent.Parent = Undefined Then 
		DestinationSettingItemParent = StructureItemProperty;
	EndIf;
	
	SettingsItemsInheritors = New Map;
	SettingsItemsInheritors.Insert(SourceSettingItemParent, DestinationSettingItemParent);
	
	DestinationRowParent = SourceRowParent.GetParent();
	RowsInheritors = New Map;
	RowsInheritors.Insert(SourceRowParent, DestinationRowParent);
	
	ChangeFiltersGrouping(StructureItemProperty, SourceRowParent.GetItems(), SettingsItemsInheritors, RowsInheritors);
	
	// Удаление базовых элементов группировки.
	DestinationRowParent.GetItems().Delete(SourceRowParent);
	DestinationSettingItemParent.Items.Delete(SourceSettingItemParent);
	
	Section = DefaultRootRow("Filters");
	Items.Filters.Expand(Section.GetID(), True);
	Items.Filters.CurrentRow = DestinationRowParent.GetID();
	
	SetModified();
EndProcedure

&AtClient
Procedure Filters_MoveUp(Command)
	ShiftFilters();
EndProcedure

&AtClient
Procedure Filters_MoveDown(Command)
	ShiftFilters(False);
EndProcedure

&AtClient
Procedure Filters_SelectCheckBoxes(Command)
	ChangeUsage("Parameters");
	ChangeUsage("Filters");
EndProcedure

&AtClient
Procedure Filters_ClearCheckBoxes(Command)
	ChangeUsage("Parameters", False);
	ChangeUsage("Filters", False);
EndProcedure

&AtClient
Procedure Filters_ShowInReportHeader(Command)
	FiltersSetDisplayMode("ShowInReportHeader");
EndProcedure

&AtClient
Procedure Filters_ShowInReportSettings(Command)
	FiltersSetDisplayMode("ShowInReportSettings");
EndProcedure

&AtClient
Procedure Filters_ShowOnlyCheckBoxInReportHeader(Command)
	FiltersSetDisplayMode("ShowOnlyCheckBoxInReportHeader");
EndProcedure

&AtClient
Procedure Filters_ShowOnlyCheckBoxInReportSettings(Command)
	FiltersSetDisplayMode("ShowOnlyCheckBoxInReportSettings");
EndProcedure

&AtClient
Procedure Filters_DontShow(Command)
	FiltersSetDisplayMode("DontShow");
EndProcedure

&AtClient
Procedure filtersSelection(Item, RowID, Field, StandardProcessing)
	Row = Items.Filters.CurrentData;
	If Row = Undefined Or Row.ThisIsSection Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	Fields = StrSplit("FiltersParameter, FiltersGroupType, FiltersLeftValue", ", ", False);
	If Fields.Find(Field.Name) <> Undefined Then 
		If Row.IsParameter Then 
			Return;
		EndIf;
		
		If Row.IsFolder Then 
			FiltersSelectGroup(RowID);
		Else
			FiltersSelectField(RowID, Row);
		EndIf;
	ElsIf Field = Items.filtersDisplayModePicture Then // Изменение быстрого доступа к отбору.
		If Row.IsParameter Then 
			StructureItemProperty = SettingsStructureItemProperty(Report.SettingsComposer, "DataParameters");
		Else
			StructureItemProperty = SettingsStructureItemProperty(Report.SettingsComposer, "Filter", SettingsStructureItemID);
		EndIf;
		SelectDisplayMode(StructureItemProperty, "Filters", RowID, True, Not Row.IsParameter);
	Else
		StandardProcessing = True;
	EndIf;
EndProcedure

&AtClient
Procedure filtersOnActivateRow(Item)
	AttachIdleHandler("FiltersOnChangeCurrentRow", 0.1, True);
EndProcedure

&AtClient
Procedure filtersOnActivateCell(Item)
	Row = Item.CurrentData;
	If Row = Undefined Then 
		Return;
	EndIf;
	
	IsListField = Row.ValueListAllowed Or ReportsClientServer.IsListComparisonKind(Row.ComparisonType);
	
	ValueField = ?(Row.IsParameter, Items.filtersValue, Items.filtersRightValue);
	ValueField.TypeRestriction = ?(IsListField, New TypeDescription("ValueList"), Row.ValueType);
	ValueField.ListChoiceMode = Not IsListField And (Row.AvailableValues <> Undefined);
	
	CastValueToComparisonKind(Row);
	SetValuePresentation(Row);
EndProcedure

&AtClient
Procedure filtersBeforeAddRow(Item, cancel, Copy, Parent, Var_Group, Parameter)
	cancel = True;
	
	If Not SettingsStructureItemChangeMode Then
		Row = Items.Filters.CurrentData;
		If (Row = Undefined)
			Or (Row.IsParameter)
			Or (Row.ThisIsSection And Row.ID = "DataParameters") Then
			Row = Filters.GetItems()[1];
			Items.Filters.CurrentRow = Row.GetID();
		EndIf;
	EndIf;
	
	SelectField("Filters", New NotifyDescription("FiltersAfterFieldSelection", ThisObject));
EndProcedure

&AtClient
Procedure filtersBeforeDeleteRow(Item, cancel)
	DeleteRows(Item, cancel);
EndProcedure

&AtClient
Procedure filtersUseOnChange(Item)
	ChangeSettingItemUsage("Filters");
EndProcedure

&AtClient
Procedure filtersComparisonTypeOnChange(Item)
	Row = Items.Filters.CurrentData;
	If Row = Undefined Then 
		Return;
	EndIf;
	
	PropertyKey = SettingsStructureItemPropertyKey("Filters", Row);
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, PropertyKey, SettingsStructureItemID, ExtendedMode);
	
	SettingItem = SettingItem(StructureItemProperty, Row);
	SettingItem.ComparisonType = Row.ComparisonType;
	
	If Row.IsParameter Then 
		Condition = DataCompositionComparisonType.Equal;
		If Row.ValueListAllowed Then 
			Condition = DataCompositionComparisonType.InList;
		EndIf;
	Else
		Condition = Row.ComparisonType;
	EndIf;
	
	ValueField = ?(Row.IsParameter, Items.filtersValue, Items.filtersRightValue);
	ValueField.ChoiceFoldersAndItems = ReportsClientServer.GroupsAndItemsTypeValue(Row.ChoiceFoldersAndItems, Condition);
	
	CastValueToComparisonKind(Row, SettingItem);
	SetModified();
EndProcedure

&AtClient
Procedure filtersValueOnChange(Item)
	Row = Items.Filters.CurrentData;
	If Row = Undefined Then 
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(Report.SettingsComposer, "DataParameters");
	SettingItem = SettingItem(StructureItemProperty, Row);
	SettingItem.Value = Row.Value;
	
	SetModified();
	SetValuePresentation(Row);
	
	If ReportSettings.ImportSettingsOnChangeParameters.Find(SettingItem.Parameter) <> Undefined Then 
		Report.SettingsComposer.Settings.AdditionalProperties.Insert("ReportInitialized", False);
		
		UpdateParameters = New Structure;
		UpdateParameters.Insert("DCSettingsComposer", Report.SettingsComposer);
		UpdateParameters.Insert("VariantModified", VariantModified);
		UpdateParameters.Insert("UserSettingsModified", UserSettingsModified);
		UpdateParameters.Insert("ResetUserSettings", True);
		
		RefreshForm(UpdateParameters);
	EndIf;
EndProcedure

&AtClient
Procedure filtersValueStartChoice(Item, ChoiceData, StandardProcessing)
	Row = Items.Filters.CurrentData;
	
	If Row.ValueListAllowed Then 
		ShowChoiceList(Row, StandardProcessing);
	Else
		SetEditParameters(Row);
	EndIf;
EndProcedure

&AtClient
Procedure filtersRightValueOnChange(Item)
	Row = Items.Filters.CurrentData;
	If Row = Undefined Then 
		Return;
	EndIf;
	
	Row.Use = True;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Filter", SettingsStructureItemID);
	
	SettingItem = SettingItem(StructureItemProperty, Row);
	FillPropertyValues(SettingItem, Row, "Use, RightValue");
	
	SetModified();
	SetValuePresentation(Row);
EndProcedure

&AtClient
Procedure filtersRightValueStartChoice(Item, ChoiceData, StandardProcessing)
	Row = Items.Filters.CurrentData;
	
	If ReportsClientServer.IsListComparisonKind(Row.ComparisonType) Then 
		ShowChoiceList(Row, StandardProcessing);
	Else
		SetEditParameters(Row);
	EndIf;
EndProcedure

&AtClient
Procedure filtersUserSettingPresentationOnChange(Item)
	Row = Items.Filters.CurrentData;
	If Row = Undefined Then
		Return;
	EndIf;
	
	If IsBlankString(Row.UserSettingPresentation) Then
		Row.UserSettingPresentation = Row.Title;
	EndIf;
	Row.IsPredefinedTitle = (Row.Title = Row.UserSettingPresentation);
	
	If Row.IsParameter Then 
		StructureItemProperty = SettingsStructureItemProperty(Report.SettingsComposer, "DataParameters");
	Else
		StructureItemProperty = SettingsStructureItemProperty(
			Report.SettingsComposer, "Filter", SettingsStructureItemID);
	EndIf;
	
	SettingItem = SettingItem(StructureItemProperty, Row);
	If Row.IsPredefinedTitle Then
		SettingItem.UserSettingPresentation = "";
	Else
		SettingItem.UserSettingPresentation = Row.UserSettingPresentation;
	EndIf;
	
	If Not Row.IsParameter Then
		If Row.DisplayModePicture = 1 Or Row.DisplayModePicture = 3 Then
			// Когда ПредставлениеПользовательскойНастройки заполнено,
			// то Представление работает как переключатель,
			// но также может использоваться для вывода в табличный документ.
			SettingItem.Presentation = Row.UserSettingPresentation;
		Else
			SettingItem.Presentation = "";
		EndIf;
	EndIf;
	
	SetModified();
EndProcedure

#EndRegion

#Region FormTableItemsEventsHandlersVariantStructure

&AtClient
Procedure VariantStructureOnActivateRow(Item)
	AttachIdleHandler("OptionStructureOnChangeCurrentRow", 0.1, True);
EndProcedure

&AtClient
Procedure VariantStructureSelection(Item, RowIdentifier, Field, StandardProcessing)
	StandardProcessing = False;
	If ExtendedMode = 0 Then
		Return;
	EndIf;
	
	Row = Item.CurrentData;
	If Row = Undefined Then
		Return;
	EndIf;
	
	If Row.Type = "DataCompositionSettings"
		Or Row.Type = "DataCompositionTableStructureItemCollection"
		Or Row.Type = "DataCompositionChartStructureItemCollection" Then
		Return;
	EndIf;
	
	If Field = Items.VariantStructurePresentation
		Or Field = Items.VariantStructureContainsFilters
		Or Field = Items.VariantStructureContainsFieldsOrOrders
		Or Field = Items.VariantStructureContainsConditionalAppearance Then
		
		PageName = Undefined;
		If Field = Items.VariantStructureContainsFilters Then
			PageName = "PageFilters";
		ElsIf Field = Items.VariantStructureContainsFieldsOrOrders Then
			PageName = "SelectedFieldsAndSortingsPage";
		ElsIf Field = Items.VariantStructureContainsConditionalAppearance Then
			PageName = "PageAppearance";
		EndIf;
		ChangeStructureItem(Row, PageName);
	Else
		StandardProcessing = True;
	EndIf;
EndProcedure

&AtClient
Procedure VariantStructureBeforeAddRow(Item, cancel, Copy, Parent, Var_Group, Parameter)
	cancel = True;
	
	If Copy
		Or Not Items.VariantStructure_Add.Enabled Then
		Return;
	EndIf;
	
	AddOptionStructureGrouping();
EndProcedure

&AtClient
Procedure VariantStructure_Group(Command)
	If Items.VariantStructure_Group.Enabled Then
		AddOptionStructureGrouping(False);
	EndIf;
EndProcedure

&AtClient
Procedure VariantStructure_AddTable(Command)
	If Items.VariantStructure_AddTable.Enabled Then
		AddSettingsStructureItem(Type("DataCompositionTable"));
	EndIf;
EndProcedure

&AtClient
Procedure VariantStructure_AddChart(Command)
	If Items.VariantStructure_AddChart.Enabled Then
		AddSettingsStructureItem(Type("DataCompositionChart"));
	EndIf;
EndProcedure

&AtClient
Procedure VariantStructure_CheckAll(Command)
	ChangeUsage("VariantStructure");
EndProcedure

&AtClient
Procedure VariantStructure_UncheckAll(Command)
	ChangeUsage("VariantStructure", False);
EndProcedure

&AtClient
Procedure VariantStructureDragStart(Item, DragParameters, StandardProcessing)
	// Проверка общих условий.
	If ExtendedMode = 0 Then
		StandardProcessing = False;
		Return;
	EndIf;
	// Проверка источника.
	Row = VariantStructure.FindByID(DragParameters.Value);
	If Row = Undefined Then
		StandardProcessing = False;
		Return;
	EndIf;
	If Row.Type = "DataCompositionChartStructureItemCollection"
		Or Row.Type = "DataCompositionTableStructureItemCollection"
		Or Row.Type = "DataCompositionSettings" Then
		StandardProcessing = False;
		Return;
	EndIf;
EndProcedure

&AtClient
Procedure VariantStructureDragCheck(Item, DragParameters, StandardProcessing, DestinationID, Field)
	// Проверка общих условий.
	If DestinationID = Undefined Then
		DragParameters.Action = DragAction.Cancel;
		Return;
	EndIf;
	// Проверка источника.
	Row = VariantStructure.FindByID(DragParameters.Value);
	If Row = Undefined Then
		DragParameters.Action = DragAction.Cancel;
		Return;
	EndIf;
	// Проверка приемника.
	NewParent = VariantStructure.FindByID(DestinationID);
	If NewParent = Undefined Then
		DragParameters.Action = DragAction.Cancel;
		Return;
	EndIf;
	If NewParent.Type = "Table"
		Or NewParent.Type = "Chart" Then
		DragParameters.Action = DragAction.Cancel;
		Return;
	EndIf;
	
	// Проверка совместимости источника с приемником.
	AllowedOnlyGroupsPresence = False;
	If NewParent.Type = "StructureTableItemsCollection"
		Or NewParent.Type = "ChartStructureItemsCollection"
		Or NewParent.Type = "TableGrouping"
		Or NewParent.Type = "ChartGrouping" Then
		AllowedOnlyGroupsPresence = True;
	EndIf;
	
	If AllowedOnlyGroupsPresence
		And Row.Type <> "Grouping"
		And Row.Type <> "TableGrouping"
		And Row.Type <> "ChartGrouping" Then
		DragParameters.Action = DragAction.Cancel;
		Return;
	EndIf;
	
	CollectionsCollections = New Array;
	CollectionsCollections.Add(Row.GetItems());
	Quantity = 1;
	While Quantity > 0 Do
		Collection = CollectionsCollections[0];
		Quantity = Quantity - 1;
		CollectionsCollections.Delete(0);
		For Each Substring In Collection Do
			If Substring = NewParent Then
				DragParameters.Action = DragAction.Cancel;
				Return;
			EndIf;
			If AllowedOnlyGroupsPresence
				And Substring.Type <> "Grouping"
				And Substring.Type <> "TableGrouping"
				And Substring.Type <> "ChartGrouping" Then
				DragParameters.Action = DragAction.Cancel;
				Return;
			EndIf;
			CollectionsCollections.Add(Substring.GetItems());
			Quantity = Quantity + 1;
		EndDo;
	EndDo;
EndProcedure

&AtClient
Procedure VariantStructureDrag(Item, DragParameters, StandardProcessing, DestinationID, Field)
	// Все проверки пройдены.
	StandardProcessing = False;
	
	Row = VariantStructure.FindByID(DragParameters.Value);
	NewParent = VariantStructure.FindByID(DestinationID);
	
	Result = MoveOptionStructureItems(Row, NewParent);
	
	Items.VariantStructure.Expand(NewParent.GetID(), True);
	Items.VariantStructure.CurrentRow = Result.Row.GetID();
	
	SetModified();
EndProcedure

&AtClient
Procedure VariantStructureUseOnChange(Item)
	ChangeSettingItemUsage("VariantStructure");
EndProcedure

&AtClient
Procedure VariantStructureTitleOnChange(Item)
	Row = Items.VariantStructure.CurrentData;
	If Row = Undefined Then
		Return;
	EndIf;
	
	UpdateOptionStructureItemTitle(Row);
	SetModified();
EndProcedure

&AtClient
Procedure VariantStructure_MoveUp(Command)
	Context = NewContext("VariantStructure", "Move");
	Context.Insert("Direction", -1);
	DefineSelectedRows(Context);
	If ValueIsFilled(Context.CancelReason) Then
		ShowMessageBox(, Context.CancelReason);
		Return;
	EndIf;
	
	ShiftRows(Context);
EndProcedure

&AtClient
Procedure VariantStructure_MoveDown(Command)
	Context = NewContext("VariantStructure", "Move");
	Context.Insert("Direction", 1);
	DefineSelectedRows(Context);
	If ValueIsFilled(Context.CancelReason) Then
		ShowMessageBox(, Context.CancelReason);
		Return;
	EndIf;
	
	ShiftRows(Context);
EndProcedure

&AtClient
Procedure VariantStructure_Change(Command)
	ItemTable = Items.VariantStructure;
	Field = ItemTable.CurrentItem;
	StandardProcessing = True;
	RowIdentifier = ItemTable.CurrentRow;
	VariantStructureSelection(ItemTable, RowIdentifier, Field, StandardProcessing);
EndProcedure

&AtClient
Procedure VariantStructureBeforeDeleteRow(Item, cancel)
	DeleteRows(Item, cancel);
EndProcedure

&AtClient
Procedure VariantStructure_MoveUpAndLeft(Command)
	If Not Items.VariantStructure_MoveUpAndLeft.Enabled Then
		Return;
	EndIf;
	TableRowUp = Items.VariantStructure.CurrentData;
	If TableRowUp = Undefined Then
		Return;
	EndIf;
	TableRowDown = TableRowUp.GetParent();
	If TableRowDown = Undefined Then
		Return;
	EndIf;
	
	ExecuteParameters = New Structure;
	ExecuteParameters.Insert("Mode",              "UpAndLeft");
	ExecuteParameters.Insert("TableRowUp", TableRowUp);
	ExecuteParameters.Insert("TableRowDown",  TableRowDown);
	VariantStructure_Move(-1, ExecuteParameters);
EndProcedure

&AtClient
Procedure VariantStructure_MoveDownAndRight(Command)
	If Not Items.VariantStructure_MoveDownAndRight.Enabled Then
		Return;
	EndIf;
	TableRowDown = Items.VariantStructure.CurrentData;
	If TableRowDown = Undefined Then
		Return;
	EndIf;
	ExecuteParameters = New Structure;
	ExecuteParameters.Insert("Mode",              "DownAndRight");
	ExecuteParameters.Insert("TableRowUp", Undefined);
	ExecuteParameters.Insert("TableRowDown",  TableRowDown);
	
	SubordinateRows = TableRowDown.GetItems();
	Quantity = SubordinateRows.Count();
	If Quantity = 0 Then
		Return;
	ElsIf Quantity = 1 Then
		ExecuteParameters.TableRowUp = SubordinateRows[0];
		VariantStructure_Move(-1, ExecuteParameters);
	Else
		List = New ValueList;
		For LineNumber = 1 To Quantity Do
			SubordinatedRow = SubordinateRows[LineNumber-1];
			List.Add(SubordinatedRow.GetID(), SubordinatedRow.Presentation);
		EndDo;
		Handler = New NotifyDescription("VariantStructure_Move", ThisObject, ExecuteParameters);
		ShowChooseFromMenu(Handler, List);
	EndIf;
	
EndProcedure

&AtClient
Procedure VariantStructure_Move(Result, ExecuteParameters) Export
	If Result <> -1 Then
		If TypeOf(Result) <> Type("ValueListItem") Then
			Return;
		EndIf;
		TableRowUp = VariantStructure.FindByID(Result.Value);
	Else
		TableRowUp = ExecuteParameters.TableRowUp;
	EndIf;
	TableRowDown = ExecuteParameters.TableRowDown;
	
	// 0. Запомнить перед каким элементом вставлять верхнюю строку.
	RowsDown = TableRowDown.GetItems();
	IndexOf = RowsDown.IndexOf(TableRowUp);
	RowsIDsArrayDown = New Array;
	For Each TableRow In RowsDown Do
		If TableRow = TableRowUp Then
			Continue;
		EndIf;
		RowsIDsArrayDown.Add(TableRow.GetID());
	EndDo;
	
	// 1. Переместить нижнюю строку на уровень с верхней.
	Result = MoveOptionStructureItems(TableRowUp, TableRowDown.GetParent(), TableRowDown);
	TableRowUp = Result.Row;
	
	// 2. Запомнить какие строки нужно переместить.
	RowsUp = TableRowUp.GetItems();
	
	// 3. Обмен строками.
	For Each TableRow In RowsUp Do
		MoveOptionStructureItems(TableRow, TableRowDown);
	EndDo;
	For Each TableRowID In RowsIDsArrayDown Do
		TableRow = VariantStructure.FindByID(TableRowID);
		MoveOptionStructureItems(TableRow, TableRowUp);
	EndDo;
	
	// 4. Переместить верхнюю строку в нижнюю.
	RowsUp = TableRowUp.GetItems();
	If RowsUp.Count() - 1 < IndexOf Then
		InsertBeforeWhat = Undefined;
	Else
		InsertBeforeWhat = RowsUp[IndexOf];
	EndIf;
	Result = MoveOptionStructureItems(TableRowDown, TableRowUp, InsertBeforeWhat);
	TableRowDown = Result.Row;
	
	// Бантики.
	If ExecuteParameters.Mode = "DownAndRight" Then
		CurrentRow = TableRowDown;
	Else
		CurrentRow = TableRowUp;
	EndIf;
	CurrentStringIdentifier = CurrentRow.GetID();
	Items.VariantStructure.Expand(CurrentStringIdentifier, True);
	Items.VariantStructure.CurrentRow = CurrentStringIdentifier;
	
	UserSettingsModified = True;
	If ExtendedMode = 1 Then
		OptionChanged = True;
	EndIf;
EndProcedure

&AtServer
Function SettingsAddressInXMLString()
	Return PutToTempStorage(
		CommonUse.ValueToXMLString(Report.SettingsComposer.Settings),
		UUID);
EndFunction

#EndRegion

#Region FormTableItemsEventsHandlersGroupingContent

&AtClient
Procedure GroupingContentUseOnChange(Item)
	ChangeSettingItemUsage("GroupingContent");
EndProcedure

&AtClient
Procedure GroupingContentSelection(Item, RowID, Field, StandardProcessing)
	StandardProcessing = False;
	
	Row = Items.GroupingContent.CurrentData;
	If Row = Undefined Then
		Return;
	EndIf;
	
	If Field = Items.GroupingContentField Then
		If TypeOf(Row.Field) = Type("DataCompositionField") Then 
			GroupContentSelectField(RowID, Row);
		EndIf;
	ElsIf Field = Items.GroupingContentGroupType
		Or Field = Items.GroupingContentAdditionType Then
		StandardProcessing = True;
	EndIf;
EndProcedure

&AtClient
Procedure GroupingContentBeforeAddRow(Item, cancel, Copy, Parent, Var_Group, Parameter)
	cancel = True;
	SelectField("GroupingContent", New NotifyDescription("GroupingContentAfterFieldSelection", ThisObject));
EndProcedure

&AtClient
Procedure GroupingContentBeforeDeleteRow(Item, cancel)
	DeleteRows(Item, cancel);
EndProcedure

&AtClient
Procedure GroupingContentGroupTypeOnChange(Item)
	Row = Items.GroupingContent.CurrentData;
	If Row = Undefined Then
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "GroupFields", SettingsStructureItemID);
	
	SettingItem = SettingItem(StructureItemProperty, Row);
	SettingItem.GroupType = Row.GroupType;
	
	SetModified();
EndProcedure

&AtClient
Procedure GroupingContentAdditionTypeOnChange(Item)
	Row = Items.GroupingContent.CurrentData;
	If Row = Undefined Then
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "GroupFields", SettingsStructureItemID);
	
	SettingItem = SettingItem(StructureItemProperty, Row);
	SettingItem.AdditionType = Row.AdditionType;
	
	SetModified();
EndProcedure

&AtClient
Procedure GroupingContent_MoveUp(Command)
	ShiftGroupField();
EndProcedure

&AtClient
Procedure GroupingContent_MoveDown(Command)
	ShiftGroupField(False);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAppearance

&AtClient
Procedure AppearanceBeforeAddRow(Item, cancel, Copy, Parent, Var_Group, Parameter)
	cancel = True;
	
	Row = DefaultRootRow("Appearance");
	If Row <> Undefined Then 
		Items.Appearance.CurrentRow = Row.GetID();
	EndIf;
	
	AppearanceChangeItem();
EndProcedure

&AtClient
Procedure AppearanceSelection(Item, RowID, Field, StandardProcessing)
	StandardProcessing = False;
	
	Row = Items.Appearance.CurrentData;
	If Row = Undefined Or Row.ThisIsSection Then 
		Return;
	EndIf;
	
	If Row.IsOutputParameter Then 
		If String(Row.ID) = "TITLE"
			And Field = Items.AppearanceTitle Then 
			
			Handler = New NotifyDescription("AppearanceTitleInputCompletion", ThisObject, RowID);
			ShowInputString(Handler, Row.Value, "Title",, True);
		EndIf;
	ElsIf Field = Items.AppearanceTitle Then // Изменение порядка.
		AppearanceChangeItem(RowID, Row);
	ElsIf Field = Items.AppearanceAccessPictureIndex Then // Изменение быстрого доступа к отбору.
		StructureItemProperty = SettingsStructureItemProperty(
			Report.SettingsComposer, "ConditionalAppearance", SettingsStructureItemID);
		SelectDisplayMode(StructureItemProperty, "Appearance", RowID, True, False);
	EndIf;
EndProcedure

&AtClient
Procedure AppearanceBeforeDeleteRow(Item, cancel)
	DeleteRows(Item, cancel);
EndProcedure

&AtClient
Procedure AppearanceUsageOnChange(Item)
	ChangeSettingItemUsage("Appearance");
EndProcedure

&AtClient
Procedure Appearance_MoveUp(Command)
	ShiftAppearance();
EndProcedure

&AtClient
Procedure Appearance_MoveDown(Command)
	ShiftAppearance(False);
EndProcedure

&AtClient
Procedure Appearance_SelectCheckBoxes(Command)
	ChangePredefinedOutputParametersUsage();
	ChangeUsage("Appearance");
EndProcedure

&AtClient
Procedure Appearance_ClearCheckBoxes(Command)
	ChangePredefinedOutputParametersUsage(False);
	ChangeUsage("Appearance", False);
EndProcedure

&AtClient
Procedure CustomizeHeadersFooters(Command)
	Var Settings;
	
	Report.SettingsComposer.Settings.AdditionalProperties.Property("HeaderOrFooterSettings", Settings);
	
	OpenForm("CommonForm.HeaderAndFooterSettings",
		New Structure("Settings", Settings),
		ThisObject,
		UUID,,,
		New NotifyDescription("RememberHeaderFooterSettings", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure CloseAndGenerate(Command)
	WriteAndClose(True);
EndProcedure

&AtClient
Procedure CloseWithoutGenerating(Command)
	WriteAndClose(False);
EndProcedure

&AtClient
Procedure EditFiltersConditions(Command)
	FormParameters = New Structure;
	FormParameters.Insert("OwnerFormType", ReportFormType);
	FormParameters.Insert("ReportSettings", ReportSettings);
	FormParameters.Insert("SettingsComposer", Report.SettingsComposer);
	Handler = New NotifyDescription("EditFilterCriteriaCompletion", ThisObject);
	OpenForm("SettingsStorage.ReportsVariantsStorage.Form.ReportFiltersConditions", FormParameters, ThisObject, True,,, Handler);
EndProcedure

&AtClient
Procedure EditFilterCriteriaCompletion(FiltersConditions, Context) Export
	If FiltersConditions = Undefined
		Or FiltersConditions = DialogReturnCode.Cancel
		Or FiltersConditions.Count() = 0 Then
		Return;
	EndIf;
	
	UpdateParameters = New Structure;
	UpdateParameters.Insert("EventName", "EditFiltersConditions");
	UpdateParameters.Insert("DCSettingsComposer", Report.SettingsComposer);
	UpdateParameters.Insert("UserSettingsModified", True);
	UpdateParameters.Insert("FiltersConditions", FiltersConditions);
	
	RefreshForm(UpdateParameters);
EndProcedure

&AtClient
Procedure RemoveNonexistentFieldsFromSettings(Command)
	DeleteFiedsMarkedForDeletion();
	
	UpdateParameters = New Structure;
	UpdateParameters.Insert("DCSettingsComposer", Report.SettingsComposer);
	
	RefreshForm(UpdateParameters);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Подключаемые команды

&AtClient
Procedure Attachable_SelectPeriod(Command)
	ReportsClient.SelectPeriod(ThisObject, Command.Name);
EndProcedure

&AtClient
Procedure Attachable_List_Pick(Command)
	ListPath = StrReplace(Command.Name, "Pick", "");
	
	FillingParameters = ListFillingParameters();
	FillingParameters.ListPath = ListPath;
	FillingParameters.IndexOf = PathToItemsData.ByName[ListPath];
	FillingParameters.Owner = Items[ListPath];
	
	StartListFilling(Items[Command.Name], FillingParameters);
EndProcedure

&AtClient
Procedure Attachable_List_PasteFromClipboard(Command)
	ListPath = StrReplace(Command.Name, "InsertFromBuffer", "");
	
	List = ThisObject[ListPath];
	ListBox = Items[ListPath];
	
	IndexOf = PathToItemsData.ByName[ListPath];
	Information = ReportsClient.SettingItemInfo(Report.SettingsComposer, IndexOf);
	UserSettings = Report.SettingsComposer.UserSettings.Items;
	
	ChoiceParameters = ReportsClientServer.ChoiceParameters(Information.Settings, UserSettings, Information.Item);
	List.ValueType = ReportsClient.ValueTypeRestrictedByLinkByType(
		Information.Settings, UserSettings, Information.Item, Information.LongDesc);
	
	SearchParameters = New Structure;
	SearchParameters.Insert("TypeDescription", TypesDetailsWithoutPrimitiveOnes(List.ValueType));
	SearchParameters.Insert("FieldPresentation", ListBox.Title);
	SearchParameters.Insert("Script", "InsertionFromClipboard");
	SearchParameters.Insert("ChoiceParameters", ChoiceParameters);
	
	Handler = New NotifyDescription("PasteFromClipboardCompletion", ThisObject, ListPath);
	
	ModuleDataLoadFromFileClient = CommonUseClient.CommonModule("DataLoadFromFileClient");
	ModuleDataLoadFromFileClient.ShowRefsFillingForm(SearchParameters, Handler);
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

#Region GroupFields

// Чтение настроек.

&AtServer
Procedure UpdateGroupFields()
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "GroupFields", SettingsStructureItemID);
	
	If StructureItemProperty = Undefined Then 
		Return;
	EndIf;
	
	For Each SettingItem In StructureItemProperty.Items Do 
		Row = GroupingContent.GetItems().Add();
		FillPropertyValues(Row, SettingItem);
		Row.ID = StructureItemProperty.GetIDByObject(SettingItem);
		
		If TypeOf(SettingItem) = Type("DataCompositionAutoGroupField") Then 
			Row.Title  = NStr("en='Auto (all fields)';ru='Авто (по всем полям)';vi='Tự động (theo tất cả các trường)'");
			Row.Picture = ReportsClientServer.PictureIndex("Item", "Predefined");
			Continue;
		EndIf;
		
		SettingDetails = StructureItemProperty.GroupFieldsAvailableFields.FindField(SettingItem.Field);
		If SettingDetails = Undefined Then 
			SetDeletionMark("GroupingContent", Row);
			Continue;
		EndIf;
		
		FillPropertyValues(Row, SettingDetails);
		Row.ShowAdditionType = SettingDetails.ValueType.ContainsType(Type("Date"));
		
		If SettingDetails.Resource Then
			Row.Picture = ReportsClientServer.PictureIndex("Resource");
		ElsIf SettingDetails.Table Then
			Row.Picture = ReportsClientServer.PictureIndex("Table");
		ElsIf SettingDetails.Folder Then
			Row.Picture = ReportsClientServer.PictureIndex("Group");
		Else
			Row.Picture = ReportsClientServer.PictureIndex("Item");
		EndIf;
	EndDo;
EndProcedure

// Добавление, изменение элементов.

&AtClient
Procedure GroupContentSelectField(RowID, Row)
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "GroupFields", SettingsStructureItemID);
	SettingItem = SettingItem(StructureItemProperty, Row);
	
	Handler = New NotifyDescription("GroupingContentAfterFieldSelection", ThisObject, RowID);
	SelectField("GroupingContent", Handler, SettingItem.Field);
EndProcedure

&AtClient
Procedure GroupingContentAfterFieldSelection(SettingDetails, RowID) Export
	If SettingDetails = Undefined Then
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "GroupFields", SettingsStructureItemID);
	
	If RowID = Undefined Then 
		Row = GroupingContent.GetItems().Add();
		SettingItem = StructureItemProperty.Items.Add(Type("DataCompositionGroupField"));
	Else
		Row = GroupingContent.FindByID(RowID);
		SettingItem = SettingItem(StructureItemProperty, Row);
	EndIf;
	
	SettingItem.Use = True;
	SettingItem.Field = SettingDetails.Field;
	
	FillPropertyValues(Row, SettingItem);
	Row.ID = StructureItemProperty.GetIDByObject(SettingItem);
	
	FillPropertyValues(Row, SettingDetails);
	
	Row.ShowAdditionType = SettingDetails.ValueType.ContainsType(Type("Date"));
	
	If SettingDetails.Resource Then
		Row.Picture = ReportsClientServer.PictureIndex("Resource");
	ElsIf SettingDetails.Table Then
		Row.Picture = ReportsClientServer.PictureIndex("Table");
	ElsIf SettingDetails.Folder Then
		Row.Picture = ReportsClientServer.PictureIndex("Group");
	Else
		Row.Picture = ReportsClientServer.PictureIndex("Item");
	EndIf;
	
	ChangeUsageOfLinkedSettingsItems("GroupingContent", Row, SettingItem);
	
	Items.GroupingContent.CurrentRow = Row.GetID();
	
	SetModified();
EndProcedure

// Сдвиг элементов.

&AtClient
Procedure ShiftGroupField(ToBeginning = True)
	RowsIDs = Items.GroupingContent.SelectedRows;
	If RowsIDs.Count() = 0 Then 
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "GroupFields", SettingsStructureItemID);
	
	For Each RowID In RowsIDs Do 
		Row = GroupingContent.FindByID(RowID);
		SettingItem = SettingItem(StructureItemProperty, Row);
		
		SettingsItems = StructureItemProperty.Items;
		Rows = GroupingContent.GetItems();
		
		IndexOf = SettingsItems.IndexOf(SettingItem);
		Border = SettingsItems.Count() - 1;
		
		If ToBeginning Then // Сдвиг в начало коллекции.
			If IndexOf = 0 Then 
				SettingsItems.Move(SettingItem, Border);
				Rows.Move(IndexOf, Border);
			Else
				SettingsItems.Move(SettingItem, -1);
				Rows.Move(IndexOf, -1);
			EndIf;
		Else // Сдвиг в конец коллекции.
			If IndexOf = Border Then 
				SettingsItems.Move(SettingItem, -Border);
				Rows.Move(IndexOf, -Border);
			Else
				SettingsItems.Move(SettingItem, 1);
				Rows.Move(IndexOf, 1);
			EndIf;
		EndIf;
	EndDo;
	
	SetModified();
EndProcedure

#EndRegion

#Region DataParametersAndFilters

// Чтение настроек.

&AtServer
Procedure UpdateDataParameters()
	If ExtendedMode = 0
		Or SettingsStructureItemChangeMode Then 
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "DataParameters", SettingsStructureItemID);
	
	Section = Filters.GetItems().Add();
	Section.ThisIsSection = True;
	Section.Title = NStr("en='Parameters';ru='Параметры';vi='Tham số'");
	Section.Picture = ReportsClientServer.PictureIndex("DataParameters");
	Section.ID = "DataParameters";
	SectionItems = Section.GetItems();
	
	If StructureItemProperty = Undefined
		Or StructureItemProperty.Items.Count() = 0 Then 
		Return;
	EndIf;
	
	Scheme = GetFromTempStorage(ReportSettings.SchemaURL);
	
	For Each SettingItem In StructureItemProperty.Items Do 
		FoundParameter = Scheme.Parameters.Find(SettingItem.Parameter);
		If FoundParameter <> Undefined And FoundParameter.UseRestriction Then 
			Continue;
		EndIf;
		
		Row = SectionItems.Add();
		FillPropertyValues(Row, SettingItem);
		Row.ID = StructureItemProperty.GetIDByObject(SettingItem);
		Row.DisplayModePicture = SettingItemDisplayModePicture(SettingItem);
		Row.Picture = -1;
		Row.IsParameter = True;
		Row.IsPeriod = (TypeOf(Row.Value) = Type("StandardPeriod"));
		
		SettingDetails = StructureItemProperty.AvailableParameters.FindParameter(SettingItem.Parameter);
		If SettingDetails <> Undefined Then 
			FillPropertyValues(Row, SettingDetails,, "Use");
			Row.DisplayUsage = (SettingDetails.Use <> DataCompositionParameterUse.Always);
			
			If SettingDetails.AvailableValues <> Undefined Then 
				ListElement = SettingDetails.AvailableValues.FindByValue(SettingItem.Value);
				If ListElement <> Undefined Then 
					Row.ValueDescription = ListElement.Presentation;
				EndIf;
			EndIf;
		EndIf;
		
		If Not ValueIsFilled(Row.UserSettingPresentation) Then 
			Row.UserSettingPresentation = Row.Title;
		EndIf;
		Row.IsPredefinedTitle = (Row.Title = Row.UserSettingPresentation);
	EndDo;
EndProcedure

&AtServer
Procedure UpdateFilters(Rows = Undefined, SettingsItems = Undefined)
	If ExtendedMode = 0 Then 
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Filter", SettingsStructureItemID);
	
	If StructureItemProperty = Undefined Then 
		Return;
	EndIf;
	
	If Rows = Undefined Then 
		Section = Filters.GetItems().Add();
		Section.ThisIsSection = True;
		Section.Title = NStr("en='Filters';ru='Отборы';vi='Bộ lọc'");
		Section.Picture = ReportsClientServer.PictureIndex("Filters");
		Section.ID = "Filters";
		Rows = Section.GetItems();
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Filter", SettingsStructureItemID);
	
	If SettingsItems = Undefined Then 
		SettingsItems = StructureItemProperty.Items;
	EndIf;
	
	For Each SettingItem In SettingsItems Do 
		Row = Rows.Add();
		
		If Not SetFiltersRowData(Row, StructureItemProperty, SettingItem) Then 
			SetDeletionMark("Filters", Row);
		EndIf;
		
		If TypeOf(SettingItem) = Type("DataCompositionFilterItemGroup") Then 
			UpdateFilters(Row.GetItems(), SettingItem.Items);
		EndIf;
	EndDo;
EndProcedure

&AtClientAtServerNoContext
Function SetFiltersRowData(Row, StructureItemProperty, SettingItem, SettingDetails = Undefined)
	InstalledSuccessfully = True;
	
	IsFolder = (TypeOf(SettingItem) = Type("DataCompositionFilterItemGroup"));
	
	If SettingDetails = Undefined Then 
		If Not IsFolder Then 
			SettingDetails = StructureItemProperty.FilterAvailableFields.FindField(SettingItem.LeftValue);
			InstalledSuccessfully = (SettingDetails <> Undefined);
		EndIf;
		
		If SettingDetails = Undefined Then 
			SettingDetails = New Structure("AvailableValues, AvailableCompareTypes");
			SettingDetails.Insert("ValueType", New TypeDescription("Undefined"));
		EndIf;
	EndIf;
	
	AvailableCompareTypes = SettingDetails.AvailableCompareTypes;
	If AvailableCompareTypes <> Undefined
		And AvailableCompareTypes.Count() > 0
		And AvailableCompareTypes.FindByValue(SettingItem.ComparisonType) = Undefined Then 
		SettingItem.ComparisonType = AvailableCompareTypes[0].Value;
	EndIf;
	
	FillPropertyValues(Row, SettingDetails);
	FillPropertyValues(Row, SettingItem);
	
	Row.ID = StructureItemProperty.GetIDByObject(SettingItem);
	Row.DisplayUsage = True;
	Row.IsPeriod = (TypeOf(Row.RightValue) = Type("StandardPeriod"));
	Row.ThisIsUUID = (TypeOf(Row.RightValue) = Type("UUID"));
	
	Row.IsFolder = IsFolder;
	Row.DisplayModePicture = SettingItemDisplayModePicture(SettingItem);
	Row.Picture = -1;
	
	If IsFolder Then 
		Row.Title = Row.GroupType;
	Else
		ReportsClientServer.CastValueToType(SettingItem.RightValue, SettingDetails.ValueType);
	EndIf;
	
	If Not ValueIsFilled(Row.UserSettingPresentation) Then 
		If ValueIsFilled(SettingItem.Presentation) Then 
			Row.UserSettingPresentation = SettingItem.Presentation;
		Else
			Row.UserSettingPresentation = Row.Title;
		EndIf;
	EndIf;
	Row.IsPredefinedTitle = (Row.Title = Row.UserSettingPresentation);
	
	CastValueToComparisonKind(Row, SettingItem);
	SetValuePresentation(Row);
	
	Return InstalledSuccessfully;
EndFunction

// Добавление, изменение элементов.

&AtClient
Procedure FiltersSelectGroup(RowID)
	Handler = New NotifyDescription("FiltersAfterGroupChoice", ThisObject, RowID);
	
	List = New ValueList;
	List.Add(DataCompositionFilterItemsGroupType.AndGroup);
	List.Add(DataCompositionFilterItemsGroupType.OrGroup);
	List.Add(DataCompositionFilterItemsGroupType.NotGroup);
	
	ShowChooseFromMenu(Handler, List);
EndProcedure

&AtClient
Procedure FiltersAfterGroupChoice(GroupType, RowID) Export
	If GroupType = Undefined Then
		Return;
	EndIf;
	
	Row = Filters.FindByID(RowID);
	Row.GroupType = GroupType.Value;
	Row.Title = Row.GroupType;
	Row.UserSettingPresentation = Row.GroupType;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Filter", SettingsStructureItemID);
	
	SettingItem = SettingItem(StructureItemProperty, Row);
	SettingItem.GroupType = GroupType.Value;
	
	SetModified();
EndProcedure

&AtClient
Procedure FiltersSelectField(RowID, Row)
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Filter", SettingsStructureItemID);
	
	SettingItem = SettingItem(StructureItemProperty, Row);
	
	Handler = New NotifyDescription("FiltersAfterFieldSelection", ThisObject, RowID);
	SelectField("Filters", Handler, SettingItem.LeftValue);
EndProcedure

&AtClient
Procedure FiltersAfterFieldSelection(SettingDetails, RowID) Export
	If SettingDetails = Undefined Then
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Filter", SettingsStructureItemID);
	
	If RowID = Undefined Then 
		Parent = Items.Filters.CurrentData;
		If Not Parent.ThisIsSection And Not Parent.IsFolder Then 
			Parent = Parent.GetParent();
		EndIf;
		Row = Parent.GetItems().Add();
		
		SettingItemParent = StructureItemProperty;
		If TypeOf(Parent.ID) = Type("DataCompositionID") Then 
			SettingItemParent = StructureItemProperty.GetObjectByID(Parent.ID);
		EndIf;
		SettingItem = SettingItemParent.Items.Add(Type("DataCompositionFilterItem"));
	Else
		Row = Filters.FindByID(RowID);
		SettingItem = SettingItem(StructureItemProperty, Row);
	EndIf;
	
	SettingItem.Use = True;
	SettingItem.LeftValue = SettingDetails.Field;
	SettingItem.RightValue = SettingDetails.Type.AdjustValue();
	SettingItem.ViewMode = DataCompositionSettingsItemViewMode.Normal;
	SettingItem.UserSettingID = New UUID;
	SettingItem.UserSettingPresentation = "";
	
	AvailableCompareTypes = SettingDetails.AvailableCompareTypes;
	If AvailableCompareTypes <> Undefined
		And AvailableCompareTypes.Count() > 0
		And AvailableCompareTypes.FindByValue(SettingItem.ComparisonType) = Undefined Then 
		SettingItem.ComparisonType = AvailableCompareTypes[0].Value;
	EndIf;
	
	SetFiltersRowData(Row, StructureItemProperty, SettingItem, SettingDetails);
	
	Section = DefaultRootRow("Filters");
	Items.Filters.Expand(Section.GetID(), True);
	
	SetModified();
EndProcedure

&AtClient
Procedure FiltersOnChangeCurrentRow()
	
	Row = Items.Filters.CurrentData;
	If Row = Undefined Then
		FiltersOnChangeCurrentRowAtServer();
		Return;
	EndIf;
	
	FiltersOnChangeCurrentRowAtServer(Not Row.IsParameter And Not Row.ThisIsSection, Row.ThisIsSection);
	
	If Row.ThisIsSection Or Row.IsFolder Then
		Return;
	EndIf;
	
	Items.filtersComparisonType.ListChoiceMode = (Row.AvailableCompareTypes <> Undefined);
	If Row.AvailableCompareTypes <> Undefined Then 
		List = Items.filtersComparisonType.ChoiceList;
		List.Clear();
		
		For Each KindsCompare In Row.AvailableCompareTypes Do 
			FillPropertyValues(List.Add(), KindsCompare);
		EndDo;
	EndIf;
	
	If Row.IsParameter Then 
		Condition = DataCompositionComparisonType.Equal;
		If Row.ValueListAllowed Then 
			Condition = DataCompositionComparisonType.InList;
		EndIf;
	Else
		Condition = Row.ComparisonType;
	EndIf;
	
	ValueField = ?(Row.IsParameter, Items.filtersValue, Items.filtersRightValue);
	ValueField.AvailableTypes = Row.ValueType;
	ValueField.ChoiceFoldersAndItems = ReportsClientServer.GroupsAndItemsTypeValue(Row.ChoiceFoldersAndItems, Condition);
	
	List = ValueField.ChoiceList;
	List.Clear();
	If Row.AvailableValues <> Undefined Then 
		For Each AvailableValue In Row.AvailableValues Do 
			FillPropertyValues(List.Add(), AvailableValue);
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure FiltersOnChangeCurrentRowAtServer(ItIsSelection = False, ThisIsSection = False)
	Items.Filters_delete.Enabled = ItIsSelection;
	Items.Filters_delete1.Enabled = ItIsSelection;
	Items.Filters_Group.Enabled = ItIsSelection;
	Items.Filters_Group1.Enabled = ItIsSelection;
	Items.Filters_Ungroup.Enabled = ItIsSelection;
	Items.Filters_Ungroup1.Enabled = ItIsSelection;
	Items.Filters_MoveUp.Enabled = ItIsSelection;
	Items.Filters_MoveUp1.Enabled = ItIsSelection;
	Items.Filters_MoveDown.Enabled = ItIsSelection;
	Items.Filters_MoveDown1.Enabled = ItIsSelection;
	
	Items.FiltersCommands_Show.Enabled = Not ThisIsSection;
	Items.FiltersCommands_Show1.Enabled = Not ThisIsSection;
	Items.Filters_ShowOnlyCheckBoxInReportHeader.Enabled = ItIsSelection;
	Items.Filters_ShowOnlyCheckBoxInReportHeader1.Enabled = ItIsSelection;
	Items.Filters_ShowOnlyCheckBoxInReportSettings.Enabled = ItIsSelection;
	Items.Filters_ShowOnlyCheckBoxInReportSettings1.Enabled = ItIsSelection;
EndProcedure

&AtClient
Procedure FiltersSetDisplayMode(ViewMode)
	Row = Items.Filters.CurrentData;
	If Row = Undefined Then
		Return;
	EndIf;
	
	If Row.IsParameter Then 
		StructureItemProperty = SettingsStructureItemProperty(Report.SettingsComposer, "DataParameters");
	Else
		StructureItemProperty = SettingsStructureItemProperty(
			Report.SettingsComposer, "Filter", SettingsStructureItemID);
	EndIf;
	
	SelectDisplayMode(StructureItemProperty, "Filters", Row.GetID(), True, Row.IsParameter, ViewMode);
EndProcedure

// Изменение группировки элементов.

&AtClient
Function FiltersGroupingParameters()
	Rows = New Array;
	Parents = New Array;
	
	RowsIDs = Items.Filters.SelectedRows;
	For Each RowID In RowsIDs Do 
		Row = Filters.FindByID(RowID);
		Parent = Row.GetParent();
		
		If Parent.GetItems().IndexOf(Row) < 0
			Or TypeOf(Row.ID) <> Type("DataCompositionID") Then 
			Continue;
		EndIf;
		
		Rows.Add(Row);
		Parents.Add(Parent);
	EndDo;
	
	If Rows.Count() = 0 Then 
		ShowMessageBox(, NStr("en='Выберите элементы.';ru='Выберите элементы.';vi='Hãy chọn phần tử.'"));
		Return Undefined;
	EndIf;
	
	Parents = CommonUseClientServer.CollapseArray(Parents);
	If Parents.Count() > 1 Then 
		ShowMessageBox(, NStr("en='Выбранные элементы не могут быть сгруппированы, поскольку они принадлежат разным родителям.';ru='Выбранные элементы не могут быть сгруппированы, поскольку они принадлежат разным родителям.';vi='Không thể gom nhóm các phần tử đã chọn vì chúng thuộc về các lớp trên khác nhau.'"));
		Return Undefined;
	EndIf;
	
	Rows = SortArray(Rows);
	Parent = Parents[0];
	IndexOf = Parent.GetItems().IndexOf(Rows[0]);
	
	Return New Structure("Rows, Parent, IndexOf", Rows, Parent, IndexOf);
EndFunction

&AtClient
Procedure ChangeFiltersGrouping(SettingsNodeFilters, Rows, SettingsItemsInheritors, RowsInheritors)
	For Each RowSource In Rows Do 
		SettingItemSource = SettingsNodeFilters.GetObjectByID(RowSource.ID);
		
		If SettingItemSource.Parent = Undefined Then 
			SourceSettingItemParent = SettingsNodeFilters;
		Else
			SourceSettingItemParent = SettingItemSource.Parent;
		EndIf;
		DestinationSettingItemParent = SettingsItemsInheritors.Get(SourceSettingItemParent);
		
		SourceRowParent = RowSource.GetParent();
		DestinationRowParent = RowsInheritors.Get(SourceRowParent);
		
		IndexOf = DestinationSettingItemParent.Items.IndexOf(SourceSettingItemParent);
		If IndexOf < 0 Then 
			SettingItemDestination = DestinationSettingItemParent.Items.Add(TypeOf(SettingItemSource));
			RowReceiver = DestinationRowParent.GetItems().Add();
		Else // Это удаление группировки.
			SettingItemDestination = DestinationSettingItemParent.Items.Insert(IndexOf, TypeOf(SettingItemSource));
			RowReceiver = DestinationRowParent.GetItems().Insert(IndexOf);
		EndIf;
		
		FillPropertyValues(SettingItemDestination, SettingItemSource);
		FillPropertyValues(RowReceiver, RowSource);
		RowReceiver.ID = SettingsNodeFilters.GetIDByObject(SettingItemDestination);
		
		SettingsItemsInheritors.Insert(SettingItemSource, SettingItemDestination);
		RowsInheritors.Insert(RowSource, RowReceiver);
		
		ChangeFiltersGrouping(SettingsNodeFilters, RowSource.GetItems(), SettingsItemsInheritors, RowsInheritors);
	EndDo;
EndProcedure

&AtClient
Procedure DeleteBasicFiltersGroupingItems(SettingsNodeFilters, GroupingParameters)
	Rows = GroupingParameters.Parent.GetItems();
	
	SettingsItems = SettingsNodeFilters.Items;
	If TypeOf(GroupingParameters.Parent.ID) = Type("DataCompositionID") Then 
		SettingsItems = SettingsNodeFilters.GetObjectByID(GroupingParameters.Parent.ID).Items;
	EndIf;
	
	IndexOf = GroupingParameters.Rows.UBound();
	While IndexOf >= 0 Do 
		Row = GroupingParameters.Rows[IndexOf];
		SettingItem = SettingsNodeFilters.GetObjectByID(Row.ID);
		
		Rows.Delete(Row);
		SettingsItems.Delete(SettingItem);
		
		IndexOf = IndexOf - 1;
	EndDo;
EndProcedure

// Сдвиг элементов.

&AtClient
Procedure ShiftFilters(ToBeginning = True)
	ShiftParameters = FiltersShiftParameters();
	If ShiftParameters = Undefined Then 
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Filter", SettingsStructureItemID);
	
	For Each Row In ShiftParameters.Rows Do 
		SettingItem = SettingItem(StructureItemProperty, Row);
		
		SettingsItems = StructureItemProperty.Items;
		If SettingItem.Parent <> Undefined Then 
			SettingsItems = SettingItem.Parent.Items;
		EndIf;
		Rows = ShiftParameters.Parent.GetItems();
		
		IndexOf = SettingsItems.IndexOf(SettingItem);
		Border = SettingsItems.Count() - 1;
		
		If ToBeginning Then // Сдвиг в начало коллекции.
			If IndexOf = 0 Then 
				SettingsItems.Move(SettingItem, Border);
				Rows.Move(IndexOf, Border);
			Else
				SettingsItems.Move(SettingItem, -1);
				Rows.Move(IndexOf, -1);
			EndIf;
		Else // Сдвиг в конец коллекции.
			If IndexOf = Border Then 
				SettingsItems.Move(SettingItem, -Border);
				Rows.Move(IndexOf, -Border);
			Else
				SettingsItems.Move(SettingItem, 1);
				Rows.Move(IndexOf, 1);
			EndIf;
		EndIf;
	EndDo;
	
	SetModified();
EndProcedure

&AtClient
Function FiltersShiftParameters()
	Rows = New Array;
	Parents = New Array;
	
	RowsIDs = Items.Filters.SelectedRows;
	For Each RowID In RowsIDs Do 
		Row = Filters.FindByID(RowID);
		Parent = Row.GetParent();
		
		If Parent.GetItems().IndexOf(Row) < 0
			Or TypeOf(Row.ID) <> Type("DataCompositionID") Then 
			Continue;
		EndIf;
		
		Rows.Add(Row);
		Parents.Add(Parent);
	EndDo;
	
	If Rows.Count() = 0 Then 
		ShowMessageBox(, NStr("en='Выберите элементы.';ru='Выберите элементы.';vi='Hãy chọn phần tử.'"));
		Return Undefined;
	EndIf;
	
	Parents = CommonUseClientServer.CollapseArray(Parents);
	If Parents.Count() > 1 Then 
		ShowMessageBox(, NStr("en='Выбранные элементы не могут быть перемещены, поскольку они принадлежат разным родителям.';ru='Выбранные элементы не могут быть перемещены, поскольку они принадлежат разным родителям.';vi='Không thể di chuyển các phần tử đã chọn vì chúng thuộc về các lớp trên khác nhau.'"));
		Return Undefined;
	EndIf;
	
	Return New Structure("Rows, Parent", SortArray(Rows), Parents[0]);
EndFunction

#EndRegion

#Region SelectedFields

// Чтение настроек.

&AtServer
Procedure UpdateSelectedFields(Rows = Undefined, SettingsItems = Undefined)
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Selection", SettingsStructureItemID, ExtendedMode);
	
	If StructureItemProperty = Undefined Then 
		Return;
	EndIf;
	
	If Rows = Undefined Then 
		Section = SelectedFields.GetItems().Add();
		Section.ThisIsSection = True;
		Section.Title = NStr("en='Fields';ru='Поля';vi='Trường'");
		Section.Picture = ReportsClientServer.PictureIndex("SelectedFields");
		Section.ID = "SelectedFields";
		Rows = Section.GetItems();
	EndIf;
	
	GroupPicture = ReportsClientServer.PictureIndex("Group");
	ItemPicture = ReportsClientServer.PictureIndex("Item");
	
	If SettingsItems = Undefined Then 
		SettingsItems = StructureItemProperty.Items;
	EndIf;
	
	For Each SettingItem In SettingsItems Do 
		Row = Rows.Add();
		FillPropertyValues(Row, SettingItem);
		Row.ID = StructureItemProperty.GetIDByObject(SettingItem);
		
		If TypeOf(SettingItem) = Type("DataCompositionAutoSelectedField") Then 
			Row.Title = NStr("en='Auto (parents fields)';ru='Авто (поля родителя)';vi='Tự động (các trường lớp trên)'");
			Row.Picture = 6;
			Continue;
		EndIf;
		
		If TypeOf(SettingItem) = Type("DataCompositionSelectedFieldGroup") Then 
			Row.IsFolder = True;
			Row.Picture = GroupPicture;
			Row.Title = SelectedFieldsGroupTitle(SettingItem);
			
			UpdateSelectedFields(Row.GetItems(), SettingItem.Items);
		Else
			SettingDetails = StructureItemProperty.SelectionAvailableFields.FindField(SettingItem.Field);
			If SettingDetails = Undefined Then 
				SetDeletionMark("SelectedFields", Row);
			Else
				FillPropertyValues(Row, SettingDetails);
				Row.Picture = ItemPicture;
			EndIf;
		EndIf;
	EndDo;
EndProcedure

// Добавление, изменение элементов.

&AtClient
Procedure SelectedFieldsSelectGroup(RowID, Row)
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Selection", SettingsStructureItemID, ExtendedMode);
	
	SettingItem = SettingItem(StructureItemProperty, Row);
	
	FormParameters = New Structure;
	FormParameters.Insert("TitleGroups", SettingItem.Title);
	FormParameters.Insert("Placement", SettingItem.Placement);
	
	Handler = New NotifyDescription("SelectedFieldsAfterGroupChoice", ThisObject, RowID);
	
	OpenForm("SettingsStorage.ReportsVariantsStorage.Form.SelectedFieldsGroup",
		FormParameters, ThisObject, UUID,,, Handler, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure SelectedFieldsAfterGroupChoice(GroupProperties, RowID) Export
	If TypeOf(GroupProperties) <> Type("Structure") Then
		Return;
	EndIf;
	
	Row = SelectedFields.FindByID(RowID);
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Selection", SettingsStructureItemID, ExtendedMode);
	
	SettingItem = SettingItem(StructureItemProperty, Row);
	SettingItem.Title = GroupProperties.TitleGroups;
	SettingItem.Placement = GroupProperties.Placement;
	
	FillPropertyValues(Row, SettingItem);
	
	If SettingItem.Placement <> DataCompositionFieldPlacement.Auto Then 
		Row.Title = Row.Title + " (" + String(SettingItem.Placement) + ")";
	EndIf;

	SetModified();
EndProcedure

&AtClient
Procedure SelectedFieldsSelectField(RowID, Row)
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Selection", SettingsStructureItemID, ExtendedMode);
	
	SettingItem = SettingItem(StructureItemProperty, Row);
	
	Handler = New NotifyDescription("SelectedFieldsAfterFieldSelection", ThisObject, RowID);
	SelectField("SelectedFields", Handler, SettingItem.Field);
EndProcedure

&AtClient
Procedure SelectedFieldsAfterFieldSelection(SettingDetails, RowID = Undefined) Export
	If SettingDetails = Undefined Then
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Selection", SettingsStructureItemID, ExtendedMode);
	
	If RowID = Undefined Then 
		Parent = Items.SelectedFields.CurrentData;
		If Parent = Undefined Then 
			Parent = DefaultRootRow("SelectedFields");
		EndIf;
		
		If Not Parent.ThisIsSection And Not Parent.IsFolder Then 
			Parent = Parent.GetParent();
		EndIf;
		Row = Parent.GetItems().Add();
		
		SettingItemParent = StructureItemProperty;
		If TypeOf(Parent.ID) = Type("DataCompositionID") Then 
			SettingItemParent = StructureItemProperty.GetObjectByID(Parent.ID);
		EndIf;
		SettingItem = SettingItemParent.Items.Add(Type("DataCompositionSelectedField"));
	Else
		Row = SelectedFields.FindByID(RowID);
		SettingItem = SettingItem(StructureItemProperty, Row);
	EndIf;
	
	SettingItem.Use = True;
	SettingItem.Field = SettingDetails.Field;
	
	FillPropertyValues(Row, SettingItem);
	FillPropertyValues(Row, SettingDetails);
	
	Row.ID = StructureItemProperty.GetIDByObject(SettingItem);
	Row.Picture = ReportsClientServer.PictureIndex("Item");
	
	SetModified();
EndProcedure

// Изменение группировки элементов.

&AtClient
Function GroupingParametersOfSelectedFields()
	Rows = New Array;
	Parents = New Array;
	
	RowsIDs = Items.SelectedFields.SelectedRows;
	For Each RowID In RowsIDs Do 
		Row = SelectedFields.FindByID(RowID);
		Parent = Row.GetParent();
		
		If Parent.GetItems().IndexOf(Row) < 0
			Or TypeOf(Row.ID) <> Type("DataCompositionID") Then 
			Continue;
		EndIf;
		
		Rows.Add(Row);
		Parents.Add(Parent);
	EndDo;
	
	If Rows.Count() = 0 Then 
		ShowMessageBox(, NStr("en='Выберите элементы.';ru='Выберите элементы.';vi='Hãy chọn phần tử.'"));
		Return Undefined;
	EndIf;
	
	Parents = CommonUseClientServer.CollapseArray(Parents);
	If Parents.Count() > 1 Then 
		ShowMessageBox(, NStr("en='Выбранные элементы не могут быть сгруппированы, поскольку они принадлежат разным родителям.';ru='Выбранные элементы не могут быть сгруппированы, поскольку они принадлежат разным родителям.';vi='Không thể gom nhóm các phần tử đã chọn vì chúng thuộc về các lớp trên khác nhau.'"));
		Return Undefined;
	EndIf;
	
	Rows = SortArray(Rows);
	Parent = Parents[0];
	IndexOf = Parent.GetItems().IndexOf(Rows[0]);
	
	Return New Structure("Rows, Parent, IndexOf", Rows, Parent, IndexOf);
EndFunction

&AtClient
Procedure SelectedFieldsBeforeGroupFields(GroupProperties, GroupingParameters) Export
	If TypeOf(GroupProperties) <> Type("Structure") Then
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Selection", SettingsStructureItemID, ExtendedMode);
	
	// Обработка элементов настроек.
	SettingItemSource = StructureItemProperty;
	If TypeOf(GroupingParameters.Parent.ID) = Type("DataCompositionID") Then 
		SettingItemSource = StructureItemProperty.GetObjectByID(GroupingParameters.Parent.ID);
	EndIf;
	
	SettingItemDestination = SettingItemSource.Items.Insert(GroupingParameters.Index, Type("DataCompositionSelectedFieldGroup"));
	SettingItemDestination.Title = GroupProperties.TitleGroups;
	SettingItemDestination.Placement = GroupProperties.Placement;
	
	SettingsItemsInheritors = New Map;
	SettingsItemsInheritors.Insert(SettingItemSource, SettingItemDestination);
	
	// Обработка строк.
	RowSource = GroupingParameters.Parent;
	RowReceiver = RowSource.GetItems().Insert(GroupingParameters.Index);
	FillPropertyValues(RowReceiver, SettingItemDestination);
	RowReceiver.ID = StructureItemProperty.GetIDByObject(SettingItemDestination);
	RowReceiver.IsFolder = True;
	RowReceiver.Picture = ReportsClientServer.PictureIndex("Group");
	RowReceiver.Title = SelectedFieldsGroupTitle(SettingItemDestination);
	
	RowsInheritors = New Map;
	RowsInheritors.Insert(RowSource, RowReceiver);
	
	ChangeGroupingOfSelectedFields(StructureItemProperty, GroupingParameters.Rows, SettingsItemsInheritors, RowsInheritors);
	DeleteBasicGroupingItemsOfSelectedFields(StructureItemProperty, GroupingParameters);
	
	Section = SelectedFields.GetItems()[0];
	Items.SelectedFields.Expand(Section.GetID(), True);
	Items.SelectedFields.CurrentRow = RowReceiver.GetID();
	
	SetModified();
EndProcedure

&AtClient
Procedure ChangeGroupingOfSelectedFields(SelectedSettingsNodeFields, Rows, SettingsItemsInheritors, RowsInheritors)
	For Each RowSource In Rows Do 
		SettingItemSource = SelectedSettingsNodeFields.GetObjectByID(RowSource.ID);
		
		If SettingItemSource.Parent = Undefined Then 
			SourceSettingItemParent = SelectedSettingsNodeFields;
		Else
			SourceSettingItemParent = SettingItemSource.Parent;
		EndIf;
		DestinationSettingItemParent = SettingsItemsInheritors.Get(SourceSettingItemParent);
		
		SourceRowParent = RowSource.GetParent();
		DestinationRowParent = RowsInheritors.Get(SourceRowParent);
		
		IndexOf = DestinationSettingItemParent.Items.IndexOf(SourceSettingItemParent);
		If IndexOf < 0 Then 
			SettingItemDestination = DestinationSettingItemParent.Items.Add(TypeOf(SettingItemSource));
			RowReceiver = DestinationRowParent.GetItems().Add();
		Else // Это удаление группировки.
			SettingItemDestination = DestinationSettingItemParent.Items.Insert(IndexOf, TypeOf(SettingItemSource));
			RowReceiver = DestinationRowParent.GetItems().Insert(IndexOf);
		EndIf;
		
		FillPropertyValues(SettingItemDestination, SettingItemSource);
		FillPropertyValues(RowReceiver, RowSource);
		RowReceiver.ID = SelectedSettingsNodeFields.GetIDByObject(SettingItemDestination);
		RowReceiver.IsFolder = (TypeOf(SettingItemDestination) = Type("DataCompositionSelectedFieldGroup"));
		
		SettingsItemsInheritors.Insert(SettingItemSource, SettingItemDestination);
		RowsInheritors.Insert(RowSource, RowReceiver);
		
		ChangeGroupingOfSelectedFields(SelectedSettingsNodeFields, RowSource.GetItems(), SettingsItemsInheritors, RowsInheritors);
	EndDo;
EndProcedure

&AtClient
Procedure DeleteBasicGroupingItemsOfSelectedFields(SelectedSettingsNodeFields, GroupingParameters)
	Rows = GroupingParameters.Parent.GetItems();
	
	SettingsItems = SelectedSettingsNodeFields.Items;
	If TypeOf(GroupingParameters.Parent.ID) = Type("DataCompositionID") Then 
		SettingsItems = SelectedSettingsNodeFields.GetObjectByID(GroupingParameters.Parent.ID).Items;
	EndIf;
	
	IndexOf = GroupingParameters.Rows.UBound();
	While IndexOf >= 0 Do 
		Row = GroupingParameters.Rows[IndexOf];
		SettingItem = SelectedSettingsNodeFields.GetObjectByID(Row.ID);
		
		Rows.Delete(Row);
		SettingsItems.Delete(SettingItem);
		
		IndexOf = IndexOf - 1;
	EndDo;
EndProcedure

&AtClientAtServerNoContext
Function SelectedFieldsGroupTitle(SettingItem)
	TitleGroups = SettingItem.Title;
	
	If Not ValueIsFilled(TitleGroups) Then 
		TitleGroups = "(" + SettingItem.Placement + ")";
	ElsIf SettingItem.Placement <> DataCompositionFieldPlacement.Auto Then 
		TitleGroups = TitleGroups + " (" + SettingItem.Placement + ")";
	EndIf;
	
	Return TitleGroups;
EndFunction

// Перетаскивание элементов.

&AtClient
Procedure CheckRowsToDragFromSelectedFields(RowsIDs)
	Parents = New Array;
	
	IndexOf = RowsIDs.UBound();
	While IndexOf >= 0 Do 
		RowID = RowsIDs[IndexOf];
		
		Row = SelectedFields.FindByID(RowID);
		Parent = Row.GetParent();
		
		If Parent = Undefined
			Or Parent.GetItems().IndexOf(Row) < 0
			Or TypeOf(Row.ID) <> Type("DataCompositionID") Then 
			RowsIDs.Delete(IndexOf);
		Else
			Parents.Add(Parent);
		EndIf;
		
		IndexOf = IndexOf - 1;
	EndDo;
	
	Parents = CommonUseClientServer.CollapseArray(Parents);
	If Parents.Count() > 1 Then 
		RowsIDs.Clear();
	EndIf;
EndProcedure

&AtClient
Procedure DragSelectedFieldsWithinCollection(DragParameters, CurrentRow)
	CurrentData = SelectedFields.FindByID(CurrentRow);
	
	Rows = New Array;
	For Each RowID In DragParameters.Value Do 
		Rows.Add(SelectedFields.FindByID(RowID));
	EndDo;
	
	RowSource = Rows[0].GetParent();
	If CurrentData.ThisIsSection Or CurrentData.IsFolder Then 
		RowReceiver = CurrentData;
	Else
		RowReceiver = CurrentData.GetParent();
	EndIf;
	
	IndexOf = RowReceiver.GetItems().IndexOf(CurrentData);
	If IndexOf < 0 Then 
		IndexOf = 0;
	EndIf;
	
	RowsInheritors = New Map;
	RowsInheritors.Insert(RowSource, RowReceiver);
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Selection", SettingsStructureItemID, ExtendedMode);
	
	SettingItemSource = StructureItemProperty;
	If TypeOf(RowSource.ID) = Type("DataCompositionID") Then 
		SettingItemSource = StructureItemProperty.GetObjectByID(RowSource.ID);
	EndIf;
	
	SettingItemDestination = StructureItemProperty;
	If TypeOf(RowReceiver.ID) = Type("DataCompositionID") Then 
		SettingItemDestination = StructureItemProperty.GetObjectByID(RowReceiver.ID);
	EndIf;
	
	SettingsItemsInheritors = New Map;
	SettingsItemsInheritors.Insert(SettingItemSource, SettingItemDestination);
	
	DragSelectedFields(StructureItemProperty, IndexOf, Rows, SettingsItemsInheritors, RowsInheritors);
	
	Items.SelectedFields.Expand(SelectedFields.GetItems()[0].GetID(), True);
	
	SetModified();
EndProcedure

&AtClient
Procedure DragSelectedFields(SelectedSettingsNodeFields, IndexOf, Rows, SettingsItemsInheritors, RowsInheritors)
	For Each RowSource In Rows Do
		SettingItemSource = SelectedSettingsNodeFields.GetObjectByID(RowSource.ID);
		
		SettingItemParentSource = SelectedSettingsNodeFields;
		If SettingItemSource.Parent <> Undefined Then 
			SettingItemParentSource = SettingItemSource.Parent;
		EndIf;
		
		SettingItemParentDestination = SettingsItemsInheritors.Get(SettingItemParentSource);
		DestinationRowParent = RowsInheritors.Get(RowSource.GetParent());
		
		If IndexOf > SettingItemParentDestination.Items.Count() - 1 Then 
			SettingItemDestination = SettingItemParentDestination.Items.Add(TypeOf(SettingItemSource));
			RowReceiver = DestinationRowParent.GetItems().Add();
		Else
			SettingItemDestination = SettingItemParentDestination.Items.Insert(IndexOf, TypeOf(SettingItemSource));
			RowReceiver = DestinationRowParent.GetItems().Insert(IndexOf);
		EndIf;
		
		FillPropertyValues(SettingItemDestination, SettingItemSource);
		FillPropertyValues(RowReceiver, RowSource);
		RowReceiver.ID = SelectedSettingsNodeFields.GetIDByObject(SettingItemDestination);
		RowReceiver.Picture = ReportsClientServer.PictureIndex("Item");
		RowReceiver.IsFolder = (TypeOf(SettingItemDestination) = Type("DataCompositionSelectedFieldGroup"));
		
		SettingsItemsInheritors.Insert(SettingItemSource, SettingItemDestination);
		RowsInheritors.Insert(RowSource, RowReceiver);
		
		If TypeOf(SettingItemDestination) = Type("DataCompositionSelectedFieldGroup") Then 
			RowReceiver.Picture = ReportsClientServer.PictureIndex("Group");
			DragSelectedFields(SelectedSettingsNodeFields, IndexOf, RowSource.GetItems(), SettingsItemsInheritors, RowsInheritors)
		EndIf;
	EndDo;
EndProcedure

// Сдвиг элементов.

&AtClient
Procedure ShiftSelectedFields(ToBeginning = True)
	ShiftParameters = ShiftParametersOfSelectedFields();
	If ShiftParameters = Undefined Then 
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Selection", SettingsStructureItemID, ExtendedMode);
	
	For Each Row In ShiftParameters.Rows Do 
		SettingItem = SettingItem(StructureItemProperty, Row);
		
		SettingsItems = StructureItemProperty.Items;
		If SettingItem.Parent <> Undefined Then 
			SettingsItems = SettingItem.Parent.Items;
		EndIf;
		Rows = ShiftParameters.Parent.GetItems();
		
		IndexOf = SettingsItems.IndexOf(SettingItem);
		Border = SettingsItems.Count() - 1;
		
		If ToBeginning Then // Сдвиг в начало коллекции.
			If IndexOf = 0 Then 
				SettingsItems.Move(SettingItem, Border);
				Rows.Move(IndexOf, Border);
			Else
				SettingsItems.Move(SettingItem, -1);
				Rows.Move(IndexOf, -1);
			EndIf;
		Else // Сдвиг в конец коллекции.
			If IndexOf = Border Then 
				SettingsItems.Move(SettingItem, -Border);
				Rows.Move(IndexOf, -Border);
			Else
				SettingsItems.Move(SettingItem, 1);
				Rows.Move(IndexOf, 1);
			EndIf;
		EndIf;
	EndDo;
	
	SetModified();
EndProcedure

&AtClient
Function ShiftParametersOfSelectedFields()
	Rows = New Array;
	Parents = New Array;
	
	RowsIDs = Items.SelectedFields.SelectedRows;
	For Each RowID In RowsIDs Do 
		Row = SelectedFields.FindByID(RowID);
		Parent = Row.GetParent();
		
		If Parent.GetItems().IndexOf(Row) < 0
			Or TypeOf(Row.ID) <> Type("DataCompositionID") Then 
			Continue;
		EndIf;
		
		Rows.Add(Row);
		Parents.Add(Parent);
	EndDo;
	
	If Rows.Count() = 0 Then 
		ShowMessageBox(, NStr("en='Выберите элементы.';ru='Выберите элементы.';vi='Hãy chọn phần tử.'"));
		Return Undefined;
	EndIf;
	
	Parents = CommonUseClientServer.CollapseArray(Parents);
	If Parents.Count() > 1 Then 
		ShowMessageBox(, NStr("en='Выбранные элементы не могут быть перемещены, поскольку они принадлежат разным родителям.';ru='Выбранные элементы не могут быть перемещены, поскольку они принадлежат разным родителям.';vi='Không thể di chuyển các phần tử đã chọn vì chúng thuộc về các lớp trên khác nhau.'"));
		Return Undefined;
	EndIf;
	
	Return New Structure("Rows, Parent", SortArray(Rows), Parents[0]);
EndFunction

// Общее

&AtClientAtServerNoContext
Procedure CastValueToComparisonKind(Row, SettingItem = Undefined)
	ValueFieldName = ?(Row.IsParameter, "Value", "RightValue");
	CurrentValue = Row[ValueFieldName];
	
	If Row.ValueListAllowed
		Or ReportsClientServer.IsListComparisonKind(Row.ComparisonType) Then 
		
		Value = ReportsClientServer.ValueList(CurrentValue);
		Value.FillChecks(True);
		
		If Row.AvailableValues <> Undefined Then 
			For Each ListElement In Value Do 
				FoundItem = Row.AvailableValues.FindByValue(ListElement.Value);
				If FoundItem <> Undefined Then 
					FillPropertyValues(ListElement, FoundItem,, "Check");
				EndIf;
			EndDo;
		EndIf;
	Else
		Value = Undefined;
		If TypeOf(CurrentValue) <> Type("ValueList") Then 
			Value = CurrentValue;
		ElsIf CurrentValue.Count() > 0 Then 
			Value = CurrentValue[0].Value;
		EndIf;
	EndIf;
	
	Row[ValueFieldName] = Value;
	
	If TypeOf(SettingItem) = Type("DataCompositionSettingsParameterValue")
		Or TypeOf(SettingItem) = Type("DataCompositionFilterItem") Then 
		SettingItem[ValueFieldName] = Value;
	EndIf;
EndProcedure

&AtClientAtServerNoContext
Procedure SetValuePresentation(Row)
	Row.ValueDescription = "";
	
	AvailableValues = Row.AvailableValues;
	If AvailableValues = Undefined Then 
		Return;
	EndIf;
	
	Value = ?(Row.IsParameter, Row.Value, Row.RightValue);
	FoundItem = AvailableValues.FindByValue(Value);
	If FoundItem <> Undefined Then 
		Row.ValueDescription = FoundItem.Presentation;
	EndIf;
EndProcedure

&AtClient
Procedure SetEditParameters(Row)
	SettingsComposer = Report.SettingsComposer;
	
	If Row.IsParameter Then 
		ValueField = Items.filtersValue;
		StructureItemProperty = SettingsStructureItemProperty(SettingsComposer, "DataParameters");
	Else
		ValueField = Items.filtersRightValue;
		StructureItemProperty = SettingsStructureItemProperty(
			SettingsComposer, "Filter", SettingsStructureItemID);
	EndIf;
	
	UserSettings = SettingsComposer.UserSettings.Items;
	
	CurrentSettings = SettingsStructureItem(SettingsComposer.Settings, SettingsStructureItemID);
	SettingItem = SettingItem(StructureItemProperty, Row);
	SettingItemDetails = ReportsClientServer.FindAvailableSetting(CurrentSettings, SettingItem);
	
	ValueField.ChoiceParameters = ReportsClientServer.ChoiceParameters(CurrentSettings, UserSettings, SettingItem, ExtendedMode = 1);
	
	Row.ValueType = ReportsClient.ValueTypeRestrictedByLinkByType(
		CurrentSettings, UserSettings, SettingItem, SettingItemDetails);
	
	ValueField.AvailableTypes = Row.ValueType;
EndProcedure

&AtClient
Procedure ShowChoiceList(Row, StandardProcessing)
	StandardProcessing = False;
	
	SetEditParameters(Row);
	
	If Row.IsParameter Then 
		ValueField = Items.filtersValue;
		CurrentValue = Row.Value;
	Else
		ValueField = Items.filtersRightValue;
		CurrentValue = Row.RightValue;
	EndIf;
	
	ValuesForSelection = ValuesForSelection(Row);
	
	OpenParameters = New Structure;
	OpenParameters.Insert("marked", ReportsClientServer.ValueList(CurrentValue));
	OpenParameters.Insert("TypeDescription", Row.ValueType);
	OpenParameters.Insert("ValuesForSelection", ValuesForSelection);
	OpenParameters.Insert("ValuesForSelectionFilled", ValuesForSelection.Count() > 0);
	OpenParameters.Insert("LimitChoiceWithSpecifiedValues", Row.AvailableValues <> Undefined);
	OpenParameters.Insert("Presentation", Row.UserSettingPresentation);
	OpenParameters.Insert("ChoiceParameters", New Array(ValueField.ChoiceParameters));
	OpenParameters.Insert("ChoiceFoldersAndItems", ValueField.ChoiceFoldersAndItems);
	
	Handler = New NotifyDescription("CompleteChoiceFromList", ThisObject, Row.GetID());
	Mode = FormWindowOpeningMode.LockOwnerWindow;
	
	OpenForm("CommonForm.EnterValuesListWithCheckBoxes", OpenParameters, ThisObject,,,, Handler, Mode);
EndProcedure

&AtClient
Function ValuesForSelection(Row)
	ValuesForSelection = Row.AvailableValues;
	If ValuesForSelection = Undefined Then 
		ValuesForSelection = New ValueList;
	EndIf;
	
	ValuesForSelection.ValueType = Row.ValueType;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, ?(Row.IsParameter, "DataParameters", "Filter"));
	
	SettingItem = SettingItem(StructureItemProperty, Row);
	If Not ValueIsFilled(SettingItem.UserSettingID) Then 
		Return ValuesForSelection;
	EndIf;
	
	FiltersValuesCache = CommonUseClientServer.StructureProperty(
		Report.SettingsComposer.UserSettings.AdditionalProperties, "FiltersValuesCache");
	If FiltersValuesCache = Undefined Then 
		Return ValuesForSelection;
	EndIf;
	
	FilterValue = FiltersValuesCache.Get(SettingItem.UserSettingID);
	If FilterValue <> Undefined Then 
		ReportsClientServer.ExpandList(ValuesForSelection, FilterValue);
	EndIf;
	
	Return ValuesForSelection;
EndFunction

&AtClient
Procedure CompleteChoiceFromList(List, RowID) Export
	If TypeOf(List) <> Type("ValueList") Then
		Return;
	EndIf;
	
	Row = Filters.FindByID(RowID);
	If Row = Undefined Then
		Return;
	EndIf;
	
	SelectedValues = New ValueList;
	For Each ListElement In List Do 
		If ListElement.Check Then 
			FillPropertyValues(SelectedValues.Add(), ListElement);
		EndIf;
	EndDo;
	
	ValueFieldName = ?(Row.IsParameter, "Value", "RightValue");
	PropertyKey = SettingsStructureItemPropertyKey("Filters", Row);
	
	Row[ValueFieldName] = SelectedValues;
	Row.Use = True;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, PropertyKey, SettingsStructureItemID);
	
	SettingItem = SettingItem(StructureItemProperty, Row);
	FillPropertyValues(SettingItem, Row, "Use, " + ValueFieldName);
	
	ReportsClient.CacheFilterValue(
		List, SettingItem.UserSettingID, SettingsComposer);
	
	SetModified();
EndProcedure

#EndRegion

#Region Order

// Чтение настроек.

&AtServer
Procedure UpdateSorting()
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Order", SettingsStructureItemID, ExtendedMode);
	
	If StructureItemProperty = Undefined Then 
		Return;
	EndIf;
	
	Section = Sort.GetItems().Add();
	Section.ThisIsSection = True;
	Section.Title = NStr("en='Sortings';ru='Сортировки';vi='Sắp xếp'");
	Section.Picture = ReportsClientServer.PictureIndex("order");
	Rows = Section.GetItems();
	
	SettingsItems = StructureItemProperty.Items;
	
	For Each SettingItem In SettingsItems Do 
		Row = Rows.Add();
		FillPropertyValues(Row, SettingItem);
		Row.ID = StructureItemProperty.GetIDByObject(SettingItem);
		
		If TypeOf(SettingItem) = Type("DataCompositionAutoOrderItem") Then 
			Row.Title = NStr("en='Auto (sorting parent)';ru='Авто (сортировки родителя)';vi='Tự động (sắp xếp lớp trên)'");
			Row.IsAutoField = True;
			Row.Picture = 6;
			Continue;
		EndIf;
		
		SettingDetails = StructureItemProperty.OrderAvailableFields.FindField(SettingItem.Field);
		If SettingDetails = Undefined Then 
			SetDeletionMark("Sort", Row);
		Else
			FillPropertyValues(Row, SettingDetails);
			Row.Picture = ReportsClientServer.PictureIndex("Item");
		EndIf;
	EndDo;
EndProcedure

// Добавление, изменение элементов.

&AtClient
Procedure SortingSelectField(RowID, Row)
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Order", SettingsStructureItemID, ExtendedMode);
	
	SettingItem = SettingItem(StructureItemProperty, Row);
	
	Handler = New NotifyDescription("SortingAfterFieldSelection", ThisObject, RowID);
	SelectField("Sort", Handler, SettingItem.Field);
EndProcedure

&AtClient
Procedure SortingAfterFieldSelection(SettingDetails, RowID = Undefined) Export
	If SettingDetails = Undefined Then
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Order", SettingsStructureItemID, ExtendedMode);
	
	If RowID = Undefined Then 
		Parent = Items.Sort.CurrentData;
		If Not Parent.ThisIsSection Then 
			Parent = Parent.GetParent();
		EndIf;
		Row = Parent.GetItems().Add();
		
		SettingItemParent = StructureItemProperty;
		If TypeOf(Parent.ID) = Type("DataCompositionID") Then 
			SettingItemParent = StructureItemProperty.GetObjectByID(Parent.ID);
		EndIf;
		SettingItem = SettingItemParent.Items.Add(Type("DataCompositionOrderItem"));
	Else
		Row = Sort.FindByID(RowID);
		SettingItem = SettingItem(StructureItemProperty, Row);
	EndIf;
	
	SettingItem.Use = True;
	SettingItem.Field = SettingDetails.Field;
	
	FillPropertyValues(Row, SettingItem);
	FillPropertyValues(Row, SettingDetails);
	
	Row.ID = StructureItemProperty.GetIDByObject(SettingItem);
	Row.Picture = ReportsClientServer.PictureIndex("Item");
	
	Items.Sort.Expand(Sort.GetItems()[0].GetID());
	
	SetModified();
EndProcedure

&AtClient
Procedure ChangeRowsOrderType(OrderType)
	Rows = Sort.GetItems()[0].GetItems();
	If Rows.Count() = 0 Then 
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Order", SettingsStructureItemID, ExtendedMode);
	
	For Each Row In Rows Do 
		SettingItem = SettingItem(StructureItemProperty, Row);
		SettingItem.OrderType = OrderType;
		Row.OrderType = SettingItem.OrderType;
	EndDo;
	
	SetModified();
EndProcedure

&AtClient
Procedure ChangeOrderType(Row)
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Order", SettingsStructureItemID, ExtendedMode);
	
	SettingItem = SettingItem(StructureItemProperty, Row);
	
	If SettingItem.OrderType = DataCompositionSortDirection.Asc Then 
		SettingItem.OrderType = DataCompositionSortDirection.Desc;
	Else
		SettingItem.OrderType = DataCompositionSortDirection.Asc;
	EndIf;
	Row.OrderType = SettingItem.OrderType;
	
	SetModified();
EndProcedure

// Перетаскивание элементов.

&AtClient
Procedure DragSelectedFieldsToSorting(Rows)
	SelectedStructureItemFields = SettingsStructureItemProperty(
		Report.SettingsComposer, "Selection", SettingsStructureItemID, ExtendedMode);
	
	StructureItemSorting = SettingsStructureItemProperty(
		Report.SettingsComposer, "Order", SettingsStructureItemID, ExtendedMode);
	
	Section = Sort.GetItems()[0];
	
	For Each RowSource In Rows Do 
		SettingItemSource = SelectedStructureItemFields.GetObjectByID(RowSource.ID);
		If TypeOf(SettingItemSource) = Type("DataCompositionSelectedFieldGroup") Then 
			DragSelectedFieldsToSorting(RowSource.GetItems());
		Else
			If FindOrderField(StructureItemSorting, SettingItemSource.Field) <> Undefined Then 
				Continue;
			EndIf;
			
			SettingItemDestination = StructureItemSorting.Items.Add(Type("DataCompositionOrderItem"));
			FillPropertyValues(SettingItemDestination, SettingItemSource);
			SettingItemDestination.Use = True;
			
			SettingDetails = StructureItemSorting.OrderAvailableFields.FindField(SettingItemSource.Field);
			
			RowReceiver = Section.GetItems().Add();
			FillPropertyValues(RowReceiver, SettingItemDestination);
			FillPropertyValues(RowReceiver, SettingDetails);
			RowReceiver.ID = StructureItemSorting.GetIDByObject(SettingItemDestination);
			RowReceiver.Picture = ReportsClientServer.PictureIndex("Item");
		EndIf;
	EndDo;
	
	Items.Sort.Expand(Section.GetID());
	SetModified();
EndProcedure

&AtClient
Procedure DragSortingWithinCollection(DragParameters, CurrentRow)
	
EndProcedure

&AtClient
Function FindOrderField(SettingsNodeSorting, Field)
	For Each SettingItem In SettingsNodeSorting.Items Do 
		If TypeOf(SettingItem) <> Type("DataCompositionAutoOrderItem")
			And SettingItem.Field = Field Then 
			
			Return Field;
		EndIf;
	EndDo;
	
	Return Undefined;
EndFunction

&AtClient
Procedure DragSortingFieldsToSelectedFields(Rows)
	SelectedStructureItemFields = SettingsStructureItemProperty(
		Report.SettingsComposer, "Selection", SettingsStructureItemID, ExtendedMode);
	
	StructureItemSorting = SettingsStructureItemProperty(
		Report.SettingsComposer, "Order", SettingsStructureItemID, ExtendedMode);
	
	SelectedFieldsSection = SelectedFields.GetItems()[0];
	SortingFieldsSection = Sort.GetItems()[0];
	
	IndexOf = Rows.Count() - 1;
	While IndexOf >= 0 Do 
		RowSource = Rows[IndexOf];
		SettingItemSource = StructureItemSorting.GetObjectByID(RowSource.ID);
		
		If FindSelectedField(SelectedStructureItemFields, SettingItemSource.Field) = Undefined Then 
			SettingItemDestination = SelectedStructureItemFields.Items.Add(Type("DataCompositionSelectedField"));
			FillPropertyValues(SettingItemDestination, SettingItemSource);
			
			SettingDetails = SelectedStructureItemFields.SelectionAvailableFields.FindField(SettingItemSource.Field);
			
			RowReceiver = SelectedFieldsSection.GetItems().Add();
			FillPropertyValues(RowReceiver, SettingItemDestination);
			FillPropertyValues(RowReceiver, SettingDetails);
			RowReceiver.ID = SelectedStructureItemFields.GetIDByObject(SettingItemDestination);
			RowReceiver.Picture = ReportsClientServer.PictureIndex("Item");
		EndIf;
		
		StructureItemSorting.Items.Delete(SettingItemSource);
		SortingFieldsSection.GetItems().Delete(RowSource);
		
		IndexOf = IndexOf - 1;
	EndDo;
	
	Items.SelectedFields.Expand(SelectedFieldsSection.GetID(), True);
	SetModified();
EndProcedure

&AtClient
Function FindSelectedField(SelectedSettingsNodeFields, Field)
	FoundField = Undefined;
	
	For Each SettingItem In SelectedSettingsNodeFields.Items Do 
		If TypeOf(SettingItem) = Type("DataCompositionSelectedFieldGroup") Then 
			FoundField = FindSelectedField(SettingItem, Field);
		ElsIf SettingItem.Field = Field Then 
			FoundField = Field;
		EndIf;
	EndDo;
	
	Return FoundField;
EndFunction

// Сдвиг элементов.

&AtClient
Procedure ShiftSorting(ToBeginning = True)
	RowsIDs = Items.Sort.SelectedRows;
	SectionID = Sort.GetItems()[0].GetID();
	
	SectionIndex = RowsIDs.Find(SectionID);
	If SectionIndex <> Undefined Then 
		RowsIDs.Delete(SectionIndex);
	EndIf;
	
	If RowsIDs.Count() = 0 Then 
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "Order", SettingsStructureItemID, ExtendedMode);
	
	For Each RowID In RowsIDs Do 
		Row = Sort.FindByID(RowID);
		SettingItem = SettingItem(StructureItemProperty, Row);
		
		SettingsItems = StructureItemProperty.Items;
		Rows = Row.GetParent().GetItems();
		
		IndexOf = SettingsItems.IndexOf(SettingItem);
		Border = SettingsItems.Count() - 1;
		
		If ToBeginning Then // Сдвиг в начало коллекции.
			If IndexOf = 0 Then 
				SettingsItems.Move(SettingItem, Border);
				Rows.Move(IndexOf, Border);
			Else
				SettingsItems.Move(SettingItem, -1);
				Rows.Move(IndexOf, -1);
			EndIf;
		Else // Сдвиг в конец коллекции.
			If IndexOf = Border Then 
				SettingsItems.Move(SettingItem, -Border);
				Rows.Move(IndexOf, -Border);
			Else
				SettingsItems.Move(SettingItem, 1);
				Rows.Move(IndexOf, 1);
			EndIf;
		EndIf;
	EndDo;
	
	SetModified();
EndProcedure

#EndRegion

#Region Appearance

// Чтение настроек.

&AtServer
Procedure UpdateAppearance()
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "ConditionalAppearance", SettingsStructureItemID);
	
	If StructureItemProperty = Undefined Then 
		Return;
	EndIf;
	
	ReadPredefinedAppearanceParameters();
	
	If SettingsStructureItemChangeMode Then 
		Rows = Appearance.GetItems();
	Else
		Section = Appearance.GetItems().Add();
		Section.Title = NStr("en='Conditional appearance';ru='Условное оформление';vi='Trang trí quy ước'");
		Section.Presentation = NStr("en='Conditional appearance';ru='Условное оформление';vi='Trang trí quy ước'");
		Section.Picture = ReportsClientServer.PictureIndex("ConditionalAppearance");
		Section.ThisIsSection = True;
		Rows = Section.GetItems();
	EndIf;
	
	For Each SettingItem In StructureItemProperty.Items Do 
		Row = Rows.Add();
		FillPropertyValues(Row, SettingItem);
		Row.ID = StructureItemProperty.GetIDByObject(SettingItem);
		Row.Picture = -1;
		
		If AppearanceItemIsMarkedForDeletion(SettingItem.Fields) Then 
			SetDeletionMark("Appearance", Row);
		EndIf;
		
		Row.Presentation = ReportsClientServer.ConditionalAppearanceItemPresentation(
			SettingItem, SettingItem, ?(Row.DeletionMark, "DeletionMark", ""));
		
		If ValueIsFilled(Row.UserSettingPresentation) Then 
			Row.Title = Row.UserSettingPresentation;
		Else
			Row.Title = Row.Presentation;
		EndIf;
		
		Row.IsPredefinedTitle = (Row.Title = Row.UserSettingPresentation);
		Row.DisplayModePicture = SettingItemDisplayModePicture(SettingItem);
	EndDo;
EndProcedure

&AtServer
Function AppearanceItemIsMarkedForDeletion(Fields)
	AvailableFields = Fields.AppearanceFieldsAvailableFields;
	
	For Each Item In Fields.Items Do 
		If AvailableFields.FindField(Item.Field) = Undefined Then 
			Return True;
		EndIf;
	EndDo;
	
	Return False;
EndFunction

// Определяет свойства параметров вывода, влияющих на отображение заголовка, параметров данных и отборов.
//  See также ОтчетыСервер.ИнициализироватьПредопределенныеПараметрыВывода().
//
&AtServer
Procedure ReadPredefinedAppearanceParameters()
	If SettingsStructureItemChangeMode Then 
		Return;
	EndIf;
	
	PredefinedParameters = PredefinedOutputParameters(Report.SettingsComposer.Settings);
	
	// Параметр вывода Заголовок.
	Object = PredefinedParameters.TITLE.Object;
	
	Row = Appearance.GetItems().Add();
	FillPropertyValues(Row, Object, "Use, Value");
	Row.Title = StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en='Title: %1';ru='Заголовок: %1';vi='Tiêu đề: %1'"),
		?(ValueIsFilled(Object.Value), Object.Value, "<NotAvailable>"));
	Row.Presentation = NStr("en='Title';ru='Заголовок';vi='Tiêu đề'");
	Row.ID = PredefinedParameters.TITLE.ID;
	Row.Picture = -1;
	Row.DisplayModePicture = 4;
	Row.IsOutputParameter = True;
	
	// Параметр вывода ВыводитьПараметры.
	Object = PredefinedParameters.DATAPARAMETERSOUTPUT.Object;
	LinkedObject = PredefinedParameters.FILTEROUTPUT.Object;
	
	Row = Appearance.GetItems().Add();
	Row.Use = (Object.Value <> DataCompositionTextOutputType.DontOutput
		Or LinkedObject.Value <> DataCompositionTextOutputType.DontOutput);
	Row.Title = NStr("en='Display parameters and filters';ru='Выводить параметры и отборы';vi='Hiển thị các tham số và bộ lọc'");
	Row.Presentation = NStr("en='Display parameters and filters';ru='Выводить параметры и отборы';vi='Hiển thị các tham số và bộ lọc'");
	Row.ID = PredefinedParameters.DATAPARAMETERSOUTPUT.ID;
	Row.Picture = -1;
	Row.DisplayModePicture = 4;
	Row.IsOutputParameter = True;
EndProcedure

// Добавление, изменение элементов.

&AtClient
Procedure AppearanceChangeItem(RowID = Undefined, Row = Undefined)
	Handler = New NotifyDescription("AppearanceChangeItemCompletion", ThisObject, RowID);
	
	FormParameters = New Structure;
	FormParameters.Insert("ReportSettings", ReportSettings);
	FormParameters.Insert("SettingsComposer", Report.SettingsComposer);
	FormParameters.Insert("SettingsStructureItemID", SettingsStructureItemID);
	If Row = Undefined Then
		FormParameters.Insert("DCIdentifier", Undefined);
		FormParameters.Insert("Description", "");
	Else
		FormParameters.Insert("DCIdentifier", Row.ID);
		FormParameters.Insert("Description", Row.Title);
	EndIf;
	FormParameters.Insert("Title", StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en='Reports conditional appearance element ""%1""';ru='Элемент условного оформления отчета ""%1""';vi='Phần tử trang trí quy ước báo cáo ""%1""'"), OptionName));
	
	OpenForm("SettingsStorage.ReportsVariantsStorage.Form.ConditionalReportPreparationItem",
		FormParameters, ThisObject, UUID,,, Handler);
	
EndProcedure

&AtClient
Procedure AppearanceChangeItemCompletion(Result, RowID) Export
	If Result = Undefined Or Result = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "ConditionalAppearance", SettingsStructureItemID);
	
	Section = DefaultRootRow("Appearance");
	
	If RowID = Undefined Then
		If Section = Undefined Then 
			Row = Appearance.GetItems().Add();
		Else
			Row = Section.GetItems().Add();
		EndIf;
		SettingItem = StructureItemProperty.Items.Add();
	Else
		Row = Appearance.FindByID(RowID);
		SettingItem = SettingItem(StructureItemProperty, Row);
		SettingItem.Filter.Items.Clear();
		SettingItem.Fields.Items.Clear();
	EndIf;
	
	ReportsClientServer.FillPropertiesRecursively(StructureItemProperty, SettingItem, Result.KDItem);
	SettingItem.UserSettingID = New UUID;
	
	If Not ValueIsFilled(SettingItem.UserSettingPresentation) Then 
		SettingItem.Presentation = Result.Title;
	EndIf;
	
	Row.ID = StructureItemProperty.GetIDByObject(SettingItem);
	Row.Use = SettingItem.Use;
	Row.Title = Result.Title;
	
	If Not ValueIsFilled(SettingItem.UserSettingPresentation) Then 
		Row.Presentation = Result.Title;
	EndIf;
	
	Row.IsPredefinedTitle = (Row.Title = Row.Presentation);
	
	If Row.IsPredefinedTitle Then
		SettingItem.UserSettingPresentation = "";
	Else
		SettingItem.UserSettingPresentation = Row.Title;
	EndIf;
	
	Row.Picture = -1;
	Row.DisplayModePicture = SettingItemDisplayModePicture(SettingItem);
	
	If Section <> Undefined Then 
		Items.Appearance.Expand(Section.GetID());
	EndIf;
	
	SetModified();
	
EndProcedure

&AtClient
Procedure SynchronizePredefinedOutputParameters(Use, SettingItem)
	OutputParameters = Report.SettingsComposer.Settings.OutputParameters.Items;
	
	Value = ?(Use, DataCompositionTextOutputType.Auto, DataCompositionTextOutputType.DontOutput);
	
	If SettingItem.Parameter = New DataCompositionParameter("Title") Then 
		LinkedSettingItem = OutputParameters.Find("TITLEOUTPUT");
		LinkedSettingItem.Use = True;
		LinkedSettingItem.Value = Value;
	ElsIf SettingItem.Parameter = New DataCompositionParameter("DataParametersOutput") Then 
		LinkedSettingItem = OutputParameters.Find("FILTEROUTPUT");
		FillPropertyValues(LinkedSettingItem, SettingItem, "Use, Value");
	EndIf;
EndProcedure

&AtClient
Procedure AppearanceTitleInputCompletion(Value, ID) Export 
	If Value = Undefined Then 
		Return;
	EndIf;
	
	Row = Appearance.FindByID(ID);
	Row.Use = True;
	Row.Value = Value;
	Row.Title = StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en='Title: %1';ru='Заголовок: %1';vi='Tiêu đề: %1'"),
		?(ValueIsFilled(Value), Value, "<NotAvailable>"));
	
	OutputParameters = Report.SettingsComposer.Settings.OutputParameters;
	SettingItem = OutputParameters.GetObjectByID(Row.ID);
	SettingItem.Value = Value;
	SettingItem.Use = True;
	
	SetModified();
EndProcedure

// Сдвиг элементов.

&AtClient
Procedure ShiftAppearance(ToBeginning = True)
	RowsIDs = Items.Appearance.SelectedRows;
	
	Section = DefaultRootRow("Appearance");
	If Section <> Undefined Then 
		SectionID = Section.GetID();
		SectionIndex = RowsIDs.Find(SectionID);
		If SectionIndex <> Undefined Then 
			RowsIDs.Delete(SectionIndex);
		EndIf;
	EndIf;
	
	If RowsIDs.Count() = 0 Then 
		Return;
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(
		Report.SettingsComposer, "ConditionalAppearance", SettingsStructureItemID);
	
	For Each RowID In RowsIDs Do 
		Row = Appearance.FindByID(RowID);
		SettingItem = SettingItem(StructureItemProperty, Row);
		
		SettingsItems = StructureItemProperty.Items;
		RowParent = Row.GetParent();
		If Not RowParent = Undefined Then
			Rows = RowParent.GetItems();
			
			IndexOf = SettingsItems.IndexOf(SettingItem);
			Border = SettingsItems.Count() - 1;
			
			If ToBeginning Then // Сдвиг в начало коллекции.
				If IndexOf = 0 Then 
					SettingsItems.Move(SettingItem, Border);
					Rows.Move(IndexOf, Border);
				Else
					SettingsItems.Move(SettingItem, -1);
					Rows.Move(IndexOf, -1);
				EndIf;
			EndIf;
		Else // Сдвиг в конец коллекции.
			If IndexOf = Border Then 
				SettingsItems.Move(SettingItem, -Border);
				Rows.Move(IndexOf, -Border);
			Else
				SettingsItems.Move(SettingItem, 1);
				Rows.Move(IndexOf, 1);
			EndIf;
		EndIf;
	EndDo;
	
	SetModified();
EndProcedure

// Использование элементов.

&AtClient
Procedure ChangePredefinedOutputParametersUsage(Use = True)
	If SettingsStructureItemChangeMode Then 
		Return;
	EndIf;
	
	Rows = Appearance.GetItems();
	StructureItemProperty = Report.SettingsComposer.Settings.OutputParameters;
	
	For Each Row In Rows Do 
		If TypeOf(Row.ID) <> Type("DataCompositionID") Then 
			Continue;
		EndIf;
		
		Row.Use = Use;
		SettingItem = SettingItem(StructureItemProperty, Row);
		SettingItem.Use = Use;
	EndDo;
EndProcedure

// Обработчик закрытия общей формы НастройкаКолонтитулов.
//  See Синтакс-помощник: ОткрытьФорму - ОписаниеОповещенияОЗакрытии.
//
&AtClient
Procedure RememberHeaderFooterSettings(Settings, AdditionalParameters) Export 
	PreviousSettings = Undefined;
	Report.SettingsComposer.Settings.AdditionalProperties.Property("HeaderOrFooterSettings", PreviousSettings);
	
	If Settings <> PreviousSettings Then 
		SetModified();
	EndIf;
	
	Report.SettingsComposer.Settings.AdditionalProperties.Insert("HeaderOrFooterSettings", Settings);
EndProcedure

#EndRegion

#Region Structure

// Чтение настроек.

&AtServer
Procedure UpdateStructure()
	StructureItemProperty = SettingsStructureItemProperty(Report.SettingsComposer, "Structure");
	If StructureItemProperty = Undefined Then 
		Return;
	EndIf;
	
	Section = VariantStructure.GetItems().Add();
	Section.Presentation = NStr("en='Report';ru='Отчет';vi='Báo cáo'");
	Section.ThisIsSection = True;
	Section.Picture = -1;
	Section.Type = StructureItemProperty;
	Rows = Section.GetItems();
	
	UpdateStructureCollection(StructureItemProperty, "Structure", Rows);
EndProcedure

&AtServer
Procedure UpdateStructureCollection(Val Node, Val CollectionName, Rows)
	StructureItemProperty = SettingsStructureItemProperty(Report.SettingsComposer, "Structure");
	UserSettings = Report.SettingsComposer.UserSettings.Items;
	
	Collection = Node[CollectionName];
	CollectionType = TypeOf(Collection);
	NamesOfCollections = StructureItemCollectionsNames(Collection);
	
	If CollectionType = Type("DataCompositionSettingStructureItemCollection") Then 
		
		If ValueIsFilled(Collection.UserSettingID) Then 
			ContainsUserStructureItems = True;
		EndIf;
		
	ElsIf NamesOfCollections.Find(CollectionName) <> Undefined
		And (CollectionType = Type("DataCompositionTableStructureItemCollection")
			Or CollectionType = Type("DataCompositionChartStructureItemCollection")) Then 
		
		Row = Rows.Add();
		Row.ID = StructureItemProperty.GetIDByObject(Collection);
		
		Row.Presentation = CollectionName;
		If ValueIsFilled(Collection.UserSettingPresentation) Then 
			Row.Presentation = Collection.UserSettingPresentation;
		EndIf;
		
		Row.Picture = -1;
		Row.Type = Collection;
		Rows = Row.GetItems();
	EndIf;
	
	For Each Item In Collection Do 
		If ValueIsFilled(Item.UserSettingID) Then 
			ContainsUserStructureItems = True;
		EndIf;
		
		UserSettingsItem = UserSettings.Find(Item.UserSettingID);
		
		Row = Rows.Add();
		
		If UserSettingsItem = Undefined Then 
			Row.Use = Item.Use;
		Else
			Row.Use = UserSettingsItem.Use;
		EndIf;
		
		If TypeOf(Item) = Type("DataCompositionNestedObjectSettings") Then 
			Node = Item.Settings;
			ContainsNestedReports = True;
		Else
			Node = Item;
			FillPropertyValues(Row, Item);
			
			If ExtendedMode = 0 And UserSettingsItem <> Undefined Then 
				Row.Use = UserSettingsItem.Use;
			EndIf;
		EndIf;
		
		Row.ID = StructureItemProperty.GetIDByObject(Node);
		Row.CheckBoxAvailable = (ExtendedMode = 1 Or UserSettingsItem <> Undefined);
		
		ItemProperties = StructureCollectionItemProperties(Item);
		FillPropertyValues(Row, ItemProperties);
		
		If ItemProperties.DeletionMark Then 
			SetDeletionMark("VariantStructure", Row);
		EndIf;
		
		For Each CollectionName In ItemProperties.NamesOfCollections Do 
			UpdateStructureCollection(Node, CollectionName, Row.GetItems());
		EndDo;
	EndDo;
EndProcedure

&AtServer
Function StructureCollectionItemProperties(Item)
	ItemProperties = StructureCollectionItemPropertiesPalette();
	
	ItemType = TypeOf(Item);
	If ItemType = Type("DataCompositionGroup")
		Or ItemType = Type("DataCompositionTableGroup")
		Or ItemType = Type("DataCompositionChartGroup") Then 
		
		ItemProperties.Presentation = GroupFieldsPresentation(Item, ItemProperties.DeletionMark);
		
	ElsIf ItemType = Type("DataCompositionNestedObjectSettings") Then 
		
		Objects = AvailableSettingsObjects(Item);
		ObjectDescription = Objects.Find(Item.ObjectID);
		
		ItemProperties.Presentation = ObjectDescription.Title;
		If ValueIsFilled(Item.UserSettingPresentation) Then 
			ItemProperties.Presentation = Item.UserSettingPresentation;
		EndIf;
		
		If Not ValueIsFilled(ItemProperties.Presentation) Then
			ItemProperties.Presentation = NStr("en='Nested grouping';ru='Вложенная группировка';vi='Gom nhóm lồng trong'");
		EndIf;
		
	ElsIf ItemType = Type("DataCompositionTable") Then 
		
		ItemProperties.Presentation = NStr("en='Table';ru='Таблица';vi='Bảng'");
		If ValueIsFilled(Item.UserSettingPresentation) Then 
			ItemProperties.Presentation = Item.UserSettingPresentation;
		EndIf;
		
	ElsIf ItemType = Type("DataCompositionChart") Then 
		
		ItemProperties.Presentation = NStr("en='Chart';ru='Диаграмма';vi='Biểu đồ'");
		If ValueIsFilled(Item.UserSettingPresentation) Then 
			ItemProperties.Presentation = Item.UserSettingPresentation;
		EndIf;
		
	Else
		ItemProperties.Presentation = String(ItemType);
	EndIf;
	
	If ItemType <> Type("DataCompositionNestedObjectSettings") Then 
		
		ItemTitle = Item.OutputParameters.Items.Find("Title");
		If ItemTitle <> Undefined Then 
			ItemProperties.Title = ItemTitle.Value;
		EndIf;
		
	EndIf;
	
	ItemProperties.NamesOfCollections = StructureItemCollectionsNames(Item);
	
	ItemTypePresentation = ReportsClientServer.RowSettingType(ItemType);
	ItemState = ?(ItemProperties.DeletionMark, "DeletionMark", Undefined);
	ItemProperties.Picture = ReportsClientServer.PictureIndex(ItemTypePresentation, ItemState);
	
	ItemProperties.Type = Item;
	
	SetFlagsOfNestedSettingsItems(Item, ItemProperties);
	
	Return ItemProperties;
EndFunction

&AtServer
Function StructureCollectionItemPropertiesPalette()
	ItemProperties = New Structure;
	ItemProperties.Insert("Presentation", "");
	ItemProperties.Insert("Title", "");
	ItemProperties.Insert("NamesOfCollections", New Array);
	ItemProperties.Insert("DeletionMark", False);
	ItemProperties.Insert("Picture", -1);
	ItemProperties.Insert("Type", "");
	ItemProperties.Insert("ContainsFilters", False);
	ItemProperties.Insert("ContainsFieldsOrOrders", False);
	ItemProperties.Insert("ContainsConditionalAppearance", False);
	
	Return ItemProperties;
EndFunction

&AtServer
Function GroupFieldsPresentation(SettingItem, DeletionMark)
	If ValueIsFilled(SettingItem.UserSettingPresentation) Then 
		Return SettingItem.UserSettingPresentation;
	EndIf;
	
	Fields = SettingItem.GroupFields;
	If Fields.Items.Count() = 0 Then 
		Return NStr("en='<Details records>';ru='<Детальные записи>';vi='<Bản ghi chi tiết>'");
	EndIf;
	
	FieldsPresentation = New Array;
	
	For Each Item In Fields.Items Do 
		If Not Item.Use
			Or TypeOf(Item) = Type("DataCompositionAutoGroupField") Then
			Continue;
		EndIf;
		
		FieldDetails = Fields.GroupFieldsAvailableFields.FindField(Item.Field);
		If FieldDetails = Undefined Then
			DeletionMark = True;
			FieldPresentation = String(Item.Field);
		Else
			FieldPresentation = FieldDetails.Title;
		EndIf;
		
		If Item.GroupType <> DataCompositionGroupType.Items Then 
			FieldPresentation = FieldPresentation + " (" + Item.GroupType + ")";
		EndIf;
		
		FieldsPresentation.Add(FieldPresentation);
	EndDo;
	
	If FieldsPresentation.Count() = 0 Then 
		Return NStr("en='<Details records>';ru='<Детальные записи>';vi='<Bản ghi chi tiết>'");
	EndIf;
	
	Return StrConcat(FieldsPresentation, ", ");
EndFunction

&AtServer
Function AvailableSettingsObjects(NestedObjectSettings)
	If TypeOf(NestedObjectSettings.Parent) = Type("DataCompositionSettings") Then 
		Return NestedObjectSettings.Parent.AvailableObjects.Items;
	Else
		Return AvailableSettingsObjects(NestedObjectSettings.Parent);
	EndIf;
EndFunction

&AtServer
Procedure SetFlagsOfNestedSettingsItems(StructureItem, StructureItemProperties)
	ItemType = TypeOf(StructureItem);
	If ItemType = Type("DataCompositionTable")
		Or ItemType = Type("DataCompositionChart") Then 
		Return;
	EndIf;
	
	Item = StructureItem;
	If ItemType = Type("DataCompositionNestedObjectSettings") Then 
		Item = StructureItem.Settings;
	EndIf;
	
	StructureItemProperties.ContainsFilters = Item.Filter.Items.Count();
	StructureItemProperties.ContainsConditionalAppearance = Item.ConditionalAppearance.Items.Count();
	
	NestedItems = Item.Selection.Items;
	ContainsFields = NestedItems.Count() > 0
		And Not (NestedItems.Count() = 1
		And TypeOf(NestedItems[0]) = Type("DataCompositionAutoSelectedField"));
	
	NestedItems = Item.Order.Items;
	ContainsSorting = NestedItems.Count() > 0
		And Not (NestedItems.Count() = 1
		And TypeOf(NestedItems[0]) = Type("DataCompositionAutoOrderItem"));
	
	StructureItemProperties.ContainsFieldsOrOrders = ContainsFields Or ContainsSorting;
	
	// Установка служебных признаков.
	If StructureItemProperties.ContainsFilters Then 
		ContainsNestedFilters = True;
	EndIf;
	
	If StructureItemProperties.ContainsFieldsOrOrders Then 
		ContainsNestedFieldsOrSorting = True;
	EndIf;
	
	If StructureItemProperties.ContainsConditionalAppearance Then 
		ContainsNestedConditionalAppearance = True;
	EndIf;
EndProcedure

// Добавление, изменение элементов.

&AtClient
Procedure AddOptionStructureGrouping(NextLevel = True)
	ExecuteParameters = New Structure;
	ExecuteParameters.Insert("NextLevel", NextLevel);
	ExecuteParameters.Insert("Wrap", True);
	
	StructureItemID = Undefined;
	Row = Items.VariantStructure.CurrentData;
	If Row <> Undefined Then
		If Not NextLevel Then
			Row = Row.GetParent();
		EndIf;
		
		If NextLevel Then
			If Row.Type = "DataCompositionSettings" And Not Row.CheckBoxAvailable Then
				ExecuteParameters.Wrap = False;
			ElsIf Row.GetItems().Count() > 1 Then
				ExecuteParameters.Wrap = False;
			EndIf;
		EndIf;
		
		While Row <> Undefined Do
			If Row.Type = "DataCompositionSettings"
				Or Row.Type = "DataCompositionNestedObjectSettings"
				Or Row.Type = "DataCompositionGroup"
				Or Row.Type = "DataCompositionTableGroup"
				Or Row.Type = "DataCompositionChartGroup" Then
				StructureItemID = Row.ID;
				Break;
			EndIf;
			Row = Row.GetParent();
		EndDo;
	EndIf;
	
	Handler = New NotifyDescription("OptionStructureAfterSelectField", ThisObject, ExecuteParameters);
	SelectField("VariantStructure", Handler, Undefined, StructureItemID);
EndProcedure

&AtClient
Procedure AddSettingsStructureItem(ItemType)
	CurrentRow = Items.VariantStructure.CurrentData;
	
	Result = InsertSettingsStructureItem(ItemType, CurrentRow, True);
	SettingItem = Result.SettingItem;
	
	Row = Result.Row;
	Row.Type = SettingItem;
	Row.Title = Row.Presentation;
	Row.CheckBoxAvailable = True;
	Row.Use = SettingItem.Use;
	
	ItemTypePresentation = ReportsClientServer.RowSettingType(TypeOf(SettingItem));
	Row.Picture = ReportsClientServer.PictureIndex(ItemTypePresentation);
	
	StructureItemProperty = SettingsStructureItemProperty(Report.SettingsComposer, "Structure");
	SubordinateRows = Row.GetItems();
	
	If Row.Type = "DataCompositionChart" Then
		SettingItem.Selection.Items.Add(Type("DataCompositionAutoSelectedField"));
		SetOutputParameter(SettingItem, "ChartType.ValuesBySeriesConnection", ChartValuesBySeriesConnectionType.EdgesConnection);
		SetOutputParameter(SettingItem, "ChartType.ValuesBySeriesConnectionLines");
		SetOutputParameter(SettingItem, "ChartType.ValuesBySeriesConnectionColor", WebColors.Gainsboro);
		SetOutputParameter(SettingItem, "ChartType.SplineMode", ChartSplineMode.SmoothCurve);
		SetOutputParameter(SettingItem, "ChartType.SemitransparencyMode", ChartSemitransparencyMode.Use);
		
		Row.Presentation = NStr("en='Диаграмма';ru='Диаграмма';vi='Biểu đồ'");
		
		SubordinateSettingItem = SettingItem.Points;
		SubordinatedRow = SubordinateRows.Add();
		SubordinatedRow.Type = SubordinateSettingItem;
		SubordinatedRow.Subtype = "PointChart";
		SubordinatedRow.ID = StructureItemProperty.GetIDByObject(SubordinateSettingItem);
		SubordinatedRow.Picture = -1;
		SubordinatedRow.Presentation = NStr("en='Точки';ru='Точки';vi='Điểm'");
		
		SubordinateSettingItem = SettingItem.Series;
		SubordinatedRow = SubordinateRows.Add();
		SubordinatedRow.Type = SubordinateSettingItem;
		SubordinatedRow.Subtype = "SeriesChart";
		SubordinatedRow.ID = StructureItemProperty.GetIDByObject(SubordinateSettingItem);
		SubordinatedRow.Picture = -1;
		SubordinatedRow.Presentation = NStr("en='Серии';ru='Серии';vi='Sê-ri'");
	ElsIf Row.Type = "DataCompositionTable" Then
		Row.Presentation = NStr("en='Таблица';ru='Таблица';vi='Bảng'");
		
		SubordinateSettingItem = SettingItem.Rows;
		SubordinatedRow = SubordinateRows.Add();
		SubordinatedRow.Type = SubordinateSettingItem;
		SubordinatedRow.Subtype = "RowTable";
		SubordinatedRow.ID = StructureItemProperty.GetIDByObject(SubordinateSettingItem);
		SubordinatedRow.Picture = -1;
		SubordinatedRow.Presentation = NStr("en='Строки';ru='Строки';vi='Xâu ký tự'");
		
		SubordinateSettingItem = SettingItem.Columns;
		SubordinatedRow = SubordinateRows.Add();
		SubordinatedRow.Type = SubordinateSettingItem;
		SubordinatedRow.Subtype = "ColumnTable";
		SubordinatedRow.ID = StructureItemProperty.GetIDByObject(SubordinateSettingItem);
		SubordinatedRow.Picture = -1;
		SubordinatedRow.Presentation = NStr("en='Колонки';ru='Колонки';vi='Cột'");
	EndIf;
	
	Items.VariantStructure.Expand(Row.GetID(), True);
	SetModified();
EndProcedure

&AtClient
Procedure OptionStructureAfterSelectField(SettingDetails, ExecuteParameters) Export
	If SettingDetails = Undefined Then
		Return;
	EndIf;
	
	CurrentRow = Items.VariantStructure.CurrentData;
	
	RowsToMoveToNewGroup = New Array;
	If ExecuteParameters.Wrap Then
		If ExecuteParameters.NextLevel Then
			Found = CurrentRow.GetItems();
			For Each TransferredRow In Found Do
				RowsToMoveToNewGroup.Add(TransferredRow);
			EndDo;
		Else
			RowsToMoveToNewGroup.Add(CurrentRow);
		EndIf;
	EndIf;
	
	// Добавление новой группировки.
	Result = InsertSettingsStructureItem(Type("DataCompositionGroup"), CurrentRow, ExecuteParameters.NextLevel);
	
	SettingItem = Result.SettingItem;
	SettingItem.Use = True;
	SettingItem.Selection.Items.Add(Type("DataCompositionAutoSelectedField"));
	SettingItem.Order.Items.Add(Type("DataCompositionAutoOrderItem"));
	
	If SettingDetails = "<>" Then
		// Детальные записи - добавлять поле не требуется.
		Presentation = NStr("en='<Detail records>';ru='<Детальные записи>';vi='<Bản ghi chi tiết>'");
	Else
		GroupingField = SettingItem.GroupFields.Items.Add(Type("DataCompositionGroupField"));
		GroupingField.Use = True;
		GroupingField.Field = SettingDetails.Field;
		Presentation = SettingDetails.Title;
	EndIf;
	
	Row = Result.Row;
	Row.Use = SettingItem.Use;
	Row.Presentation = Presentation;
	Row.CheckBoxAvailable = True;
	Row.Type = SettingItem;
	
	ItemType = Type(Row.Type);
	ItemTypePresentation = ReportsClientServer.RowSettingType(ItemType);
	ItemState = ?(Row.DeletionMark, "DeletionMark", Undefined);
	Row.Picture = ReportsClientServer.PictureIndex(ItemTypePresentation, ItemState);
	
	If Not ExecuteParameters.NextLevel Then
		Row.Title = CurrentRow.Title;
		UpdateOptionStructureItemTitle(Row);
		CurrentRow.Title = "";
		UpdateOptionStructureItemTitle(CurrentRow);
	EndIf;
	
	// Перемещение текущей группировки в новую.
	For Each TransferredRow In RowsToMoveToNewGroup Do
		Result = MoveOptionStructureItems(TransferredRow, Row);
	EndDo;
	
	Items.VariantStructure.Expand(Row.GetID(), True);
	Items.VariantStructure.CurrentRow = Row.GetID();
	
	SetModified();
EndProcedure

&AtClient
Function InsertSettingsStructureItem(ItemType, Row, NextLevel)
	StructureItemProperty = SettingsStructureItemProperty(Report.SettingsComposer, "Structure");
	
	If Row = Undefined Then
		Row = VariantStructure;
		IndexOf = Undefined;
		SettingItemIndex = Undefined;
	EndIf;
	
	SettingItem = SettingItem(StructureItemProperty, Row);
	
	If NextLevel Then
		Rows = Row.GetItems();
		IndexOf = Undefined;
		
		SettingsItems = SettingsItems(StructureItemProperty, SettingItem);
		SettingItemIndex = Undefined
	Else // Вставка на один уровень со строкой.
		Parent = GetParent("VariantStructure", Row);
		Rows = Parent.GetItems();
		IndexOf = Rows.IndexOf(Row) + 1;
		
		SettingItemParent = GetSettingItemParent(StructureItemProperty, SettingItem);
		SettingsItems = SettingsItems(StructureItemProperty, SettingItemParent);
		SettingItemIndex = SettingsItems.IndexOf(SettingItem) + 1;
	EndIf;
	
	If IndexOf = Undefined Then
		NewRow = Rows.Add();
	Else
		NewRow = Rows.Insert(IndexOf);
	EndIf;
	
	If ReportsClient.OnAddToCollectionNeedToSpecifyPointType(TypeOf(SettingsItems)) Then
		If SettingItemIndex = Undefined Then
			NewSettingItem = SettingsItems.Add(ItemType);
		Else
			NewSettingItem = SettingsItems.Insert(SettingItemIndex, ItemType);
		EndIf;
	Else
		If SettingItemIndex = Undefined Then
			NewSettingItem = SettingsItems.Add();
		Else
			NewSettingItem = SettingsItems.Insert(SettingItemIndex);
		EndIf;
	EndIf;
	Items.VariantStructure.CurrentRow = NewRow.GetID();
	NewRow.ID = StructureItemProperty.GetIDByObject(NewSettingItem);
	
	Result = New Structure("Row, StructureItemProperty, SettingItem");
	Result.Row = NewRow;
	Result.StructureItemProperty = StructureItemProperty;
	Result.SettingItem = NewSettingItem;
	
	Return Result;
EndFunction

&AtClient
Function MoveOptionStructureItems(Val Row, Val NewParent,
	Val InsertBeforeWhat = Undefined, Val IndexOf = Undefined, Val SettingItemIndex = Undefined)
	
	Result = New Structure("Row, SettingItem, IndexOf, SettingItemIndex");
	
	AddToEnd = (NewParent = Undefined);
	WhereInsert = GetItems(VariantStructure, NewParent);
	
	KDNode = SettingsStructureItemProperty(Report.SettingsComposer, "Structure");
	
	KDItem = SettingItem(KDNode, Row);
	NewDCParent = SettingItem(KDNode, NewParent);
	WhereToInsertDC = SettingsItems(KDNode, NewDCParent);
	BeforeWhatInsertDC = SettingItem(KDNode, InsertBeforeWhat);
	
	OldParent = GetParent("VariantStructure", Row);
	FromWhereToMove = GetItems(VariantStructure, OldParent);
	
	OldDCParent = SettingItem(KDNode, OldParent);
	FromWhereToMoveDC = SettingsItems(KDNode, OldDCParent);
	
	If KDItem = BeforeWhatInsertDC Then
		Result.SettingItem = KDItem;
		Result.Row = Row;
	Else
		If IndexOf = Undefined Or SettingItemIndex = Undefined Then
			If BeforeWhatInsertDC = Undefined Then
				If AddToEnd Then
					IndexOf = WhereInsert.Count();
					SettingItemIndex = WhereToInsertDC.Count();
				Else
					IndexOf = 0;
					SettingItemIndex = 0;
				EndIf;
			Else
				IndexOf = WhereInsert.IndexOf(InsertBeforeWhat);
				SettingItemIndex = WhereToInsertDC.IndexOf(BeforeWhatInsertDC);
				If OldParent = NewParent Then
					PreviousIndex = FromWhereToMove.IndexOf(Row);
					If PreviousIndex <= IndexOf Then
						IndexOf = IndexOf + 1;
						SettingItemIndex = SettingItemIndex + 1;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		
		DCItemsSearch = New Map;
		Result.SettingItem = ReportsClientServer.CopyRecursive(KDNode, KDItem, WhereToInsertDC, SettingItemIndex, DCItemsSearch);
		
		TablesRowsSearch = New Map;
		Result.Row = ReportsClientServer.CopyRecursive(Undefined, Row, WhereInsert, IndexOf, TablesRowsSearch);
		
		For Each KeyAndValue In TablesRowsSearch Do
			OldRow = KeyAndValue.Key;
			NewRow = KeyAndValue.Value;
			NewRow.ID = DCItemsSearch.Get(OldRow.ID);
		EndDo;
		
		FromWhereToMove.Delete(Row);
		FromWhereToMoveDC.Delete(KDItem);
	EndIf;
	
	Result.IndexOf = WhereInsert.IndexOf(Result.Row);
	Result.SettingItemIndex = WhereToInsertDC.IndexOf(Result.SettingItem);
	
	Return Result;
EndFunction

&AtClient
Procedure OptionStructureOnChangeCurrentRow()
	Row = Items.VariantStructure.CurrentData;
	If Row <> Undefined Then
		SETOptionStructureItemProperties(Row.GetID());
	EndIf;
EndProcedure

&AtServer
Procedure SETOptionStructureItemProperties(RowID)
	Row = VariantStructure.FindByID(RowID);
	Parent = Row.GetParent();
	AreSubordinates = (Row.GetItems().Count() > 0);
	HasAdjacent = GetItems(VariantStructure, Parent).Count() > 1;
	
	CanAddInserted = (Row.Type <> "DataCompositionTable"
		And Row.Type <> "DataCompositionChart");
	
	CanGroup = (Row.Type <> "DataCompositionSettings"
		And Row.Type <> "DataCompositionNestedObjectSettings"
		And Row.Type <> "DataCompositionTableStructureItemCollection"
		And Row.Type <> "DataCompositionChartStructureItemCollection");
	
	CanOpen = (Row.Type <> "DataCompositionSettings"
		And Row.Type <> "DataCompositionNestedObjectSettings"
		And Row.Type <> "DataCompositionTable"
		And Row.Type <> "DataCompositionChart"
		And Row.Type <> "DataCompositionTableStructureItemCollection"
		And Row.Type <> "DataCompositionChartStructureItemCollection");
	
	CanDeleteAndMove = (Row.Type <> "DataCompositionSettings"
		And Row.Type <> "DataCompositionNestedObjectSettings"
		And Row.Type <> "DataCompositionTableStructureItemCollection"
		And Row.Type <> "DataCompositionChartStructureItemCollection");
	
	CanAddTablesAndCharts = (Row.Type = "DataCompositionSettings"
		Or Row.Type = "DataCompositionNestedObjectSettings"
		Or Row.Type = "DataCompositionGroup");
	
	CanMoveParent = (Parent <> Undefined
		And Parent.Type <> "DataCompositionSettings"
		And Parent.Type <> "DataCompositionTableStructureItemCollection"
		And Parent.Type <> "DataCompositionChartStructureItemCollection");
	
	Items.VariantStructure_Add.Enabled  = CanAddInserted;
	Items.VariantStructure_Add1.Enabled = CanAddInserted;
	Items.VariantStructure_Change.Enabled  = CanOpen;
	Items.VariantStructure_Change1.Enabled = CanOpen;
	Items.VariantStructure_AddTable.Enabled  = CanAddTablesAndCharts;
	Items.VariantStructure_AddTable1.Enabled = CanAddTablesAndCharts;
	Items.VariantStructure_AddChart.Enabled  = CanAddTablesAndCharts;
	Items.VariantStructure_AddChart1.Enabled = CanAddTablesAndCharts;
	Items.VariantStructure_Delete.Enabled  = CanDeleteAndMove;
	Items.VariantStructure_Delete1.Enabled = CanDeleteAndMove;
	Items.VariantStructure_Group.Enabled  = CanGroup;
	Items.VariantStructure_Group1.Enabled = CanGroup;
	Items.VariantStructure_MoveUpAndLeft.Enabled  = CanDeleteAndMove And CanMoveParent And CanAddInserted And CanGroup;
	Items.VariantStructure_MoveUpAndLeft1.Enabled = CanDeleteAndMove And CanMoveParent And CanAddInserted And CanGroup;
	Items.VariantStructure_MoveDownAndRight.Enabled  = CanDeleteAndMove And AreSubordinates And CanAddInserted And CanGroup;
	Items.VariantStructure_MoveDownAndRight1.Enabled = CanDeleteAndMove And AreSubordinates And CanAddInserted And CanGroup;
	Items.VariantStructure_MoveUp.Enabled  = CanDeleteAndMove And HasAdjacent;
	Items.VariantStructure_MoveUp1.Enabled = CanDeleteAndMove And HasAdjacent;
	Items.VariantStructure_MoveDown.Enabled  = CanDeleteAndMove And HasAdjacent;
	Items.VariantStructure_MoveDown1.Enabled = CanDeleteAndMove And HasAdjacent;
EndProcedure

&AtClient
Procedure ChangeStructureItem(Row, PageName = Undefined, UseOptionForm = Undefined)
	If Row = Undefined Then
		Rows = VariantStructure.GetItems();
		If Rows.Count() = 0 Then
			Return;
		EndIf;
		Row = Rows[0];
	EndIf;
	
	If UseOptionForm = Undefined Then
		UseOptionForm = (Row.Type = "DataCompositionTable"
			Or Row.Type = "DataCompositionNestedObjectSettings");
	EndIf;
	
	Handler = New NotifyDescription("StructureItemIDCompletion", ThisObject);
	
	CaptionPattern = NStr("en='Report %2 setting %1';ru='Настройка %1 отчета %2';vi='Tùy chỉnh %1 báo cáo %2'");
	If Row.Type = "DataCompositionChart" Then
		ItemPresentation = NStr("en='charts';ru='диаграммы';vi='biểu đồ'");
	Else
		ItemPresentation = NStr("en='groupings';ru='группировки';vi='gom nhóm'");
	EndIf;
	
	If ValueIsFilled(Row.Title) Then
		ItemPresentation = ItemPresentation + " """ + Row.Title + """";
	ElsIf ValueIsFilled(Row.Presentation) Then
		ItemPresentation = ItemPresentation + " """ + Row.Presentation + """";
	EndIf;
	
	StructureItemProperty = SettingsStructureItemProperty(Report.SettingsComposer, "Structure");
	SettingItem = SettingItem(StructureItemProperty, Row);
	
	PathToSettingsStructureItem = ReportsClient.FullPathToSettingsItem(
		Report.SettingsComposer.Settings, SettingItem);
	
	FormParameters = New Structure;
	FormParameters.Insert("VariantKey", String(CurrentVariantKey));
	FormParameters.Insert("Variant", Report.SettingsComposer.Settings);
	FormParameters.Insert("UserSettings", Report.SettingsComposer.UserSettings);
	FormParameters.Insert("ReportSettings", ReportSettings);
	FormParameters.Insert("OptionName", OptionName);
	FormParameters.Insert("SettingsStructureItemID", Row.ID);
	FormParameters.Insert("PathToSettingsStructureItem", PathToSettingsStructureItem);
	FormParameters.Insert("SettingsStructureItemType", Row.Type);
	FormParameters.Insert("Title", StringFunctionsClientServer.SubstituteParametersInString(
		CaptionPattern, ItemPresentation, OptionName));
	If PageName <> Undefined Then
		FormParameters.Insert("PageName", PageName);
	EndIf;
	
	OpenableFormName = ReportSettings.FullName + ?(UseOptionForm, ".VariantForm", ".SettingsForm");
	OpenForm(OpenableFormName, FormParameters, ThisObject,,,, Handler, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure StructureItemIDCompletion(Result, Context) Export
	If TypeOf(Result) <> Type("Structure")
		Or Result = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	If Result.VariantModified Then 
		RefreshForm(Result);
	EndIf;
EndProcedure

#EndRegion

#Region Common

#Region NotificationsHandlers

&AtClient
Function ListFillingParameters(Var_CloseOnChoice = False, MultipleChoice = True, AddRow = True)
	FillingParameters = New Structure("ListPath, IndexOf, Owner, SelectedType, ChoiceFoldersAndItems");
	FillingParameters.Insert("AddRow", AddRow);
	// Стандартные параметры формы.
	FillingParameters.Insert("CloseOnChoice", Var_CloseOnChoice);
	FillingParameters.Insert("CloseOnOwnerClose", True);
	FillingParameters.Insert("Filter", New Structure);
	// Стандартные параметры формы выбора (см. Расширение управляемой формы для динамического списка).
	FillingParameters.Insert("MultipleChoice", MultipleChoice);
	FillingParameters.Insert("ChoiceMode", True);
	// Предполагаемые реквизиты.
	FillingParameters.Insert("WindowOpeningMode", FormWindowOpeningMode.LockOwnerWindow);
	FillingParameters.Insert("EnableStartDrag", False);
	
	Return FillingParameters;
EndFunction

&AtClient
Procedure StartListFilling(Item, FillingParameters)
	List = ThisObject[FillingParameters.ListPath];
	ListBox = Items[FillingParameters.ListPath];
	ValueField = Items[FillingParameters.ListPath + "Value"];
	
	Information = ReportsClient.SettingItemInfo(Report.SettingsComposer, FillingParameters.IndexOf);
	
	ChoiceFoldersAndItems = Undefined;
	If Information.LongDesc <> Undefined Then 
		ChoiceFoldersAndItems = Information.LongDesc.ChoiceFoldersAndItems;
	EndIf;
	
	Condition = ReportsClientServer.SettingItemCondition(Information.UserSettingsItem, Information.LongDesc);
	ValueField.ChoiceFoldersAndItems = ReportsClientServer.GroupsAndItemsTypeValue(
		ChoiceFoldersAndItems, Condition);
	FillingParameters.ChoiceFoldersAndItems = ReportsClient.ValueOfFoldersAndItemsUseType(
		ChoiceFoldersAndItems, Condition);
	
	ExtendedTypesDetails = CommonUseClientServer.StructureProperty(
		Report.SettingsComposer.Settings.AdditionalProperties, "ExtendedTypesDetails", New Map);
	
	ExtendedTypeDetails = ExtendedTypesDetails[FillingParameters.IndexOf];
	If ExtendedTypeDetails <> Undefined Then 
		List.ValueType = ExtendedTypeDetails.TypeDescriptionForForm;
	EndIf;
	List.ValueType = TypesDetailsWithoutPrimitiveOnes(List.ValueType);
	
	UserSettings = Report.SettingsComposer.UserSettings.Items;
	
	ChoiceParameters = ReportsClientServer.ChoiceParameters(Information.Settings, UserSettings, Information.Item);
	FillingParameters.Insert("ChoiceParameters", ChoiceParameters);
	
	List.ValueType = ReportsClient.ValueTypeRestrictedByLinkByType(
		Information.Settings, UserSettings, Information.Item, Information.LongDesc, List.ValueType);
	
	Types = List.ValueType.Types();
	If Types.Count() = 0 Then
		If FillingParameters.AddRow Then 
			ListBox.AddRow();
		EndIf;
		Return;
	EndIf;
	
	If Types.Count() = 1 Then
		FillingParameters.SelectedType = Types[0];
		CompleteListFilling(-1, FillingParameters);
		Return;
	EndIf;
	
	AvailableTypes = New ValueList;
	AvailableTypes.LoadValues(Types);
	
	Handler = New NotifyDescription("CompleteListFilling", ThisObject, FillingParameters);
	ShowChooseFromMenu(Handler, AvailableTypes, Item);
EndProcedure

&AtClient
Procedure CompleteListFilling(SelectedItem, FillingParameters) Export
	If SelectedItem = Undefined Then
		Return;
	EndIf;
	
	If SelectedItem <> -1 Then
		FillingParameters.SelectedType = SelectedItem.Value;
	EndIf;
	
	SelectionParameters = CommonUseClientServer.StructureProperty(
		Report.SettingsComposer.Settings.AdditionalProperties, "SelectionParameters", New Map);
	
	PathToForm = SelectionParameters[FillingParameters.IndexOf];
	If Not ValueIsFilled(PathToForm) Then 
		PathToForm = SelectionParameters[FillingParameters.SelectedType];
	EndIf;
	
	For Each Parameter In FillingParameters.ChoiceParameters Do 
		If Not ValueIsFilled(Parameter.Name) Then
			Continue;
		EndIf;
		
		If StrStartsWith(Upper(Parameter.Name), "FILTER.") Then 
			FillingParameters.Filter.Insert(Mid(Parameter.Name, 7), Parameter.Value);
		Else
			FillingParameters.Insert(Parameter.Name, Parameter.Value);
		EndIf;
	EndDo;
	
	Owner = FillingParameters.Owner;
	FillingParameters.Delete("Owner");
	
	OpenForm(PathToForm, FillingParameters, Owner);
EndProcedure

&AtClient
Procedure PasteFromClipboardCompletion(FoundObjects, ListPath) Export
	If FoundObjects = Undefined Then
		Return;
	EndIf;
	
	List = ThisObject[ListPath];
	
	SettingsComposer = Report.SettingsComposer;
	
	IndexOf = PathToItemsData.ByName[ListPath];
	SettingItem = SettingsComposer.UserSettings.Items[IndexOf];
	
	If TypeOf(SettingItem) = Type("DataCompositionFilterItem") Then
		If SettingItem.RightValue = Undefined Then
			SettingItem.RightValue = New ValueList;
		EndIf;
		marked = SettingItem.RightValue;
	Else
		marked = SettingItem.Value;
	EndIf;
	
	For Each Value In FoundObjects Do
		ReportsClientServer.AddUniqueValueInList(List, Value, Undefined, True);
		ReportsClientServer.AddUniqueValueInList(marked, Value, Undefined, True);
	EndDo;
	
	SettingItem.Use = True;
	
	RegisterList(Items[ListPath], SettingItem);
EndProcedure

#EndRegion

&AtClientAtServerNoContext
Function SettingsStructureItemProperty(SettingsComposer, Var_Key, ItemIdentificator = Undefined, Mode = Undefined)
	Settings = SettingsComposer.Settings;
	
	If Var_Key = "Structure" Then 
		Return Settings;
	EndIf;
	
	StructureItem = SettingsStructureItem(Settings, ItemIdentificator);
	
	StructureItemType = TypeOf(StructureItem);
	If StructureItem = Undefined
		Or (StructureItemType = Type("DataCompositionTable") And Var_Key <> "Selection" And Var_Key <> "ConditionalAppearance")
		Or (StructureItemType = Type("DataCompositionChart") And Var_Key <> "Selection" And Var_Key <> "ConditionalAppearance")
		Or (StructureItemType = Type("DataCompositionSettings") And Var_Key = "GroupFields")
		Or (StructureItemType = Type("DataCompositionGroup") And Var_Key = "DataParameters")
		Or (StructureItemType = Type("DataCompositionTableGroup") And Var_Key = "DataParameters")
		Or (StructureItemType = Type("DataCompositionChartGroup") And Var_Key = "DataParameters") Then 
		Return Undefined;
	EndIf;
	
	StructureItemProperty = StructureItem[Var_Key];
	
	If Mode = 0
		And (TypeOf(StructureItemProperty) = Type("DataCompositionSelectedFields")
			Or TypeOf(StructureItemProperty) = Type("DataCompositionOrder"))
		And ValueIsFilled(StructureItemProperty.UserSettingID) Then 
		
		StructureItemProperty = SettingsComposer.UserSettings.Items.Find(
			StructureItemProperty.UserSettingID);
	EndIf;
	
	Return StructureItemProperty;
EndFunction

&AtClientAtServerNoContext
Function SettingsStructureItem(Settings, ItemIdentificator)
	If TypeOf(ItemIdentificator) = Type("DataCompositionID") Then 
		StructureItem = Settings.GetObjectByID(ItemIdentificator);
	Else
		StructureItem = Settings;
	EndIf;
	
	Return StructureItem;
EndFunction

&AtClientAtServerNoContext
Function SettingsStructureItemPropertyKey(CollectionName, Row)
	Var_Key = Undefined;
	
	If CollectionName = "GroupingContent" Then 
		Var_Key = "GroupFields";
	ElsIf CollectionName = "Parameters" Or CollectionName = "Filters" Then 
		If Row.Property("IsParameter") And Row.IsParameter Then 
			Var_Key = "DataParameters";
		Else
			Var_Key = "Filter";
		EndIf;
	ElsIf CollectionName = "SelectedFields" Then 
		Var_Key = "Selection";
	ElsIf CollectionName = "Sort" Then 
		Var_Key = "Order";
	ElsIf CollectionName = "Appearance" Then 
		If Row.Property("IsOutputParameter") And Row.IsOutputParameter Then 
			Var_Key = "OutputParameters";
		Else
			Var_Key = "ConditionalAppearance";
		EndIf;
	ElsIf CollectionName = "VariantStructure" Then 
		Var_Key = "Structure";
	EndIf;
	
	Return Var_Key;
EndFunction

&AtClient
Procedure DeleteRows(Item, cancel)
	cancel = True;
	
	RowsIDs = Item.SelectedRows;
	
	IndexOf = RowsIDs.UBound();
	While IndexOf >= 0 Do 
		Row = ThisObject[Item.Name].FindByID(RowsIDs[IndexOf]);
		IndexOf = IndexOf - 1;
		
		If TypeOf(Row.ID) <> Type("DataCompositionID")
			Or (Row.Property("ThisIsSection") And Row.ThisIsSection)
			Or (Row.Property("IsParameter") And Row.IsParameter)
			Or (Row.Property("IsOutputParameter") And Row.IsOutputParameter) Then 
			Continue;
		EndIf;
		
		Rows = GetParent(Item.Name, Row).GetItems();
		If Rows.IndexOf(Row) < 0 Then 
			Continue;
		EndIf;
			
		PropertyKey = SettingsStructureItemPropertyKey(Item.Name, Row);
		StructureItemProperty = SettingsStructureItemProperty(
			Report.SettingsComposer, PropertyKey, SettingsStructureItemID, ExtendedMode);
		
		SettingItem = SettingItem(StructureItemProperty, Row);
		If TypeOf(SettingItem) = Type("DataCompositionTableStructureItemCollection")
			Or TypeOf(SettingItem) = Type("DataCompositionChartStructureItemCollection") Then 
			Continue;
		EndIf;
		
		SettingItemParent = GetSettingItemParent(StructureItemProperty, SettingItem);
		CollectionName = SettingsCollectionNameByID(Row.ID);
		SettingsItems = SettingsItems(StructureItemProperty, SettingItemParent, CollectionName);
		
		Row.Use = False;
		ChangeUsageOfLinkedSettingsItems(Item.Name, Row, SettingItem);
		
		SettingsItems.Delete(SettingItem);
		Rows.Delete(Row);
	EndDo;
	
	SetModified();
EndProcedure

&AtClient
Procedure ChangeUsage(CollectionName, Use = True, Rows = Undefined)
	If Rows = Undefined Then 
		RootRow = DefaultRootRow(CollectionName);
		If RootRow = Undefined Then 
			Return;
		EndIf;
		
		Rows = RootRow.GetItems();
	EndIf;
	
	For Each Row In Rows Do 
		Row.Use = Use;
		
		PropertyKey = SettingsStructureItemPropertyKey(CollectionName, Row);
		StructureItemProperty = SettingsStructureItemProperty(
			Report.SettingsComposer, PropertyKey, SettingsStructureItemID, ExtendedMode);
		
		SettingItem = SettingItem(StructureItemProperty, Row);
		If TypeOf(SettingItem) <> Type("DataCompositionSettings")
			And TypeOf(SettingItem) <> Type("DataCompositionTableStructureItemCollection")
			And TypeOf(SettingItem) <> Type("DataCompositionChartStructureItemCollection") Then 
			SettingItem.Use = Use;
		EndIf;
		
		ChangeUsage(CollectionName, Use, Row.GetItems());
	EndDo;
	
	SetModified();
EndProcedure

&AtClient
Procedure ChangeSettingItemUsage(CollectionName)
	Row = Items[CollectionName].CurrentData;
	
	SettingsComposer = Report.SettingsComposer;
	
	PropertyKey = SettingsStructureItemPropertyKey(CollectionName, Row);
	StructureItemProperty = SettingsStructureItemProperty(
		SettingsComposer, PropertyKey, SettingsStructureItemID, ExtendedMode);
	
	SettingItem = SettingItem(StructureItemProperty, Row);
	SettingItemParent = GetSettingItemParent(StructureItemProperty, SettingItem);
	
	If TypeOf(SettingItemParent) = Type("DataCompositionNestedObjectSettings") Then
		SettingItem = SettingItemParent;
	EndIf;
	
	SettingItem.Use = Row.Use;
	
	If Row.Property("IsOutputParameter")
		And Row.IsOutputParameter
		And String(Row.ID) = "DATAPARAMETERSOUTPUT" Then 
		
		SettingItem.Use = True;
		SettingItem.Value = ?(Row.Use,
			DataCompositionTextOutputType.Auto, DataCompositionTextOutputType.DontOutput);
	EndIf;
	
	If ExtendedMode = 0 And CollectionName = "VariantStructure" Then 
		UserSettingsItem = SettingsComposer.UserSettings.Items.Find(
			SettingItem.UserSettingID);
		If UserSettingsItem <> Undefined Then 
			UserSettingsItem.Use = SettingItem.Use;
		EndIf;
	EndIf;
	
	ChangeUsageOfLinkedSettingsItems(CollectionName, Row, SettingItem);
	
	SetModified();
EndProcedure

&AtClient
Procedure ChangeUsageOfLinkedSettingsItems(CollectionName, Row, SettingItem)
	If CollectionName = "GroupingContent" Then
		LinkedCollections = StrSplit("SelectedFields, Sort", ", ", False);
	ElsIf CollectionName = "SelectedFields" Then
		LinkedCollections = StrSplit("GroupingContent, Sort", ", ", False);
	Else
		LinkedCollections = New Array(1);
	EndIf;
	
	For Each LinkedCollection In LinkedCollections Do 
		If LinkedCollection <> Undefined And ValueIsFilled(Row.Field) Then
			Condition = New Structure("Field", Row.Field);
			ChangeUsageByCondition(LinkedCollection, Condition, Row.Use);
		ElsIf Row.Property("IsOutputParameter") And Row.IsOutputParameter Then 
			SynchronizePredefinedOutputParameters(Row.Use, SettingItem);
		EndIf;
	EndDo;
EndProcedure

&AtClient
Procedure ChangeUsageByCondition(CollectionName, Condition, Use)
	Collection = ThisObject[CollectionName];
	Found = ReportsClientServer.FindTableRows(Collection, Condition);
	
	StructureItemProperty = Undefined;
	For Each Row In Found Do
		If Row.Use = Use Then
			Continue;
		EndIf;
		
		If StructureItemProperty = Undefined Then
			PropertyKey = SettingsStructureItemPropertyKey(CollectionName, Row);
			StructureItemProperty = SettingsStructureItemProperty(
				Report.SettingsComposer, PropertyKey, SettingsStructureItemID, ExtendedMode);
		EndIf;
		
		SettingItem = SettingItem(StructureItemProperty, Row);
		If SettingItem <> Undefined Then
			Row.Use = Use;
			SettingItem.Use = Use;
		EndIf;
	EndDo;
EndProcedure

&AtServer
Procedure SetDeletionMark(CollectionName, Row)
	Row.DeletionMark = True;
	
	If CollectionName = "Appearance" Then 
		Row.Picture = ReportsClientServer.PictureIndex("Error");
	Else
		Row.Picture = ReportsClientServer.PictureIndex("Item", "DeletionMark");
	EndIf;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Клиент

&AtClient
Procedure WriteAndClose(Regenerate)
	NotifyChoice(ChoiceResult(Regenerate));
EndProcedure

&AtClient
Function ChoiceResult(Regenerate)
	SelectionResultGenerated = True;
	
	If SettingsStructureItemChangeMode And Not Regenerate Then
		Return Undefined;
	EndIf;
	
	ChoiceResult = New Structure;
	ChoiceResult.Insert("EventName", "SettingsForm");
	ChoiceResult.Insert("Regenerate", Regenerate);
	ChoiceResult.Insert("VariantModified", OptionChanged);
	ChoiceResult.Insert("UserSettingsModified", OptionChanged Or UserSettingsModified);
	ChoiceResult.Insert("ResetUserSettings", ExtendedMode = 1);
	ChoiceResult.Insert("SettingsFormExtendedMode", ExtendedMode);
	ChoiceResult.Insert("SettingsFormPageName", Items.SettingPages.CurrentPage.Name);
	ChoiceResult.Insert("DCSettingsComposer", Report.SettingsComposer);
	
	Return ChoiceResult;
EndFunction

&AtClientAtServerNoContext
Function PredefinedOutputParameters(Settings)
	PredefinedParameters = New Structure("TITLE, TITLEOUTPUT, DATAPARAMETERSOUTPUT, FILTEROUTPUT");
	
	OutputParameters = Settings.OutputParameters;
	For Each Parameter In PredefinedParameters Do 
		ParameterProperties = New Structure("Object, ID");
		ParameterProperties.Object = OutputParameters.Items.Find(Parameter.Key);
		ParameterProperties.ID = OutputParameters.GetIDByObject(ParameterProperties.Object);
		
		PredefinedParameters[Parameter.Key] = ParameterProperties;
	EndDo;
	
	Return PredefinedParameters;
EndFunction

&AtClient
Procedure SetOutputParameter(StructureItem, ParameterName, Value = Undefined, Use = True)
	ParameterValue = StructureItem.OutputParameters.FindParameterValue(New DataCompositionParameter(ParameterName));
	If ParameterValue = Undefined Then
		Return;
	EndIf;
	
	If Value <> Undefined Then
		ParameterValue.Value = Value;
	EndIf;
	
	If Use <> Undefined Then
		ParameterValue.Use = Use;
	EndIf;
EndProcedure

&AtClient
Function NewContext(Val TableName, Val Action)
	Result = New Structure;
	Result.Insert("CancelReason", "");
	Result.Insert("TableName", TableName);
	Result.Insert("Action", Action);
	Return Result;
EndFunction

&AtClient
Procedure DefineSelectedRows(Context)
	Context.Insert("TreeRows", New Array); // Выделенные строки (не идентификаторы).
	Context.Insert("CurrentRow", Undefined); // Активная строка (не идентификатор).
	ItemTable = Items[Context.TableName];
	TableAttribute = ThisObject[Context.TableName];
	CurrentStringIdentifier = ItemTable.CurrentRow;
	
	Specifics = New Structure("CanBeSections, CanBeParameters,
		|CanBeOutputParameters, CanBeGroups, RequireOneParent");
	Specifics.CanBeSections = (Context.TableName = "Filters"
		Or Context.TableName = "SelectedFields"
		Or Context.TableName = "Sort"
		Or Context.TableName = "Appearance");
	Specifics.CanBeParameters = (Context.TableName = "Filters");
	Specifics.CanBeOutputParameters = (Context.TableName = "Appearance");
	Specifics.RequireOneParent = (Context.Action = "Move" Or Context.Action = "Group");
	Specifics.CanBeGroups = (Context.TableName = "Filters" Or Context.TableName = "SelectedFields");
	If Specifics.RequireOneParent Then
		Context.Insert("CurrentParent", -1);
	EndIf;
	If Specifics.CanBeGroups Then
		HadGroups = False;
	EndIf;
	
	SelectedRows = SortArray(ItemTable.SelectedRows, SortDirection.Asc);
	For Each RowIdentifier In SelectedRows Do
		TreeRow = TableAttribute.FindByID(RowIdentifier);
		If Not RowAdded(Context, TreeRow, Specifics) Then
			Return;
		EndIf;
		If Specifics.CanBeGroups And TreeRow.IsFolder Then
			HadGroups = True;
		EndIf;
		If RowIdentifier = CurrentStringIdentifier Then
			Context.CurrentRow = TreeRow;
		EndIf;
	EndDo;
	If Context.TreeRows.Count() = 0 Then
		Context.CancelReason = NStr("en='Choose elements.';ru='Выберите элементы.';vi='Hãy chọn các phần tử.'");
		Return;
	EndIf;
	If Context.CurrentRow = Undefined Then
		If Context.Action = "ChangeGroup" Then
			Context.CancelReason = NStr("en='Choose group.';ru='Выберите группу.';vi='Hãy chọn nhóm.'");
			Return;
		EndIf;
	EndIf;
	
	// Исключение из списка удаляемых строк всех подчиненных строк, для которых включены родители.
	If Context.Action = "Delete" And Specifics.CanBeGroups And HadGroups Then
		Quantity = Context.TreeRows.Count();
		For Number = 1 To Quantity Do
			ReverseIndex = Quantity - Number;
			Parent = Context.TreeRows[ReverseIndex];
			While Parent <> Undefined Do
				Parent = Parent.GetParent();
				If Context.TreeRows.Find(Parent) <> Undefined Then
					Context.TreeRows.Delete(ReverseIndex);
					Break;
				EndIf;
			EndDo;
		EndDo;
	EndIf;
EndProcedure

&AtClient
Function RowAdded(Rows, TreeRow, Specifics)
	If Rows.TreeRows.Find(TreeRow) <> Undefined Then
		Return True; // Пропустить строку.
	EndIf;
	If Specifics.CanBeSections And TreeRow.ThisIsSection Then
		Return True; // Пропустить строку.
	EndIf;
	If (Specifics.CanBeParameters And TreeRow.IsParameter)
		Or (Specifics.CanBeOutputParameters And TreeRow.IsOutputParameter) Then
		If Rows.Action = "Move" Then
			Rows.CancelReason = NStr("en='Параметры не могут быть перемещены.';ru='Параметры не могут быть перемещены.';vi='Không thể di chuyển các tham số.'");
		ElsIf Rows.Action = "Group" Then
			Rows.CancelReason = NStr("en='Параметры не могут быть участниками групп.';ru='Параметры не могут быть участниками групп.';vi='Tham số không thể tham gia nhóm.'");
		ElsIf Rows.Action = "Delete" Then
			Rows.CancelReason = NStr("en='Параметры не могут быть удалены.';ru='Параметры не могут быть удалены.';vi='Không thể xóa các tham số.'");
		EndIf;
		Return False;
	EndIf;
	If Specifics.RequireOneParent Then
		Parent = TreeRow.GetParent();
		If Rows.CurrentParent = -1 Then
			Rows.CurrentParent = Parent;
		ElsIf Rows.CurrentParent <> Parent Then
			If Rows.Action = "Move" Then
				Rows.CancelReason = NStr("en='Выбранные элементы не могут быть перемещены, поскольку они принадлежат разным родителям.';ru='Выбранные элементы не могут быть перемещены, поскольку они принадлежат разным родителям.';vi='Không thể di chuyển các phần tử đã chọn vì chúng thuộc về các lớp trên khác nhau.'");
			ElsIf Rows.Action = "Group" Then
				Rows.CancelReason = NStr("en='Выбранные элементы не могут быть сгруппированы, поскольку они принадлежат разным родителям.';ru='Выбранные элементы не могут быть сгруппированы, поскольку они принадлежат разным родителям.';vi='Không thể gom nhóm các phần tử đã chọn vì chúng thuộc về các lớp trên khác nhau.'");
			EndIf;
			Return False; 
		EndIf;
	EndIf;
	Rows.TreeRows.Add(TreeRow);
	Return True; // Следующая строка.
EndFunction

&AtClient
Procedure ShiftRows(Context)
	CurrentParent = Context.CurrentParent;
	KDNode = SettingsStructureItemProperty(Report.SettingsComposer, "Structure");
	
	If Context.CurrentParent = Undefined Then
		TableAttribute = ThisObject[Context.TableName];
		If Context.TableName = "Filters" And Not SettingsStructureItemChangeMode Then
			CurrentParent = TableAttribute.GetItems()[1];
		Else
			CurrentParent = TableAttribute;
		EndIf;
		CurrentDCParent = KDNode;
	ElsIf TypeOf(CurrentParent.ID) <> Type("DataCompositionID") Then
		CurrentDCParent = KDNode;
	Else
		CurrentDCParent = KDNode.GetObjectByID(CurrentParent.ID);
	EndIf;
	ParentRows = CurrentParent.GetItems();
	DCParentRows = SettingsItems(KDNode, CurrentDCParent);
	
	RowsUpperBorder = ParentRows.Count() - 1;
	RowsHighlighted = Context.TreeRows.Count();
	
	// Массив выделенных строк на встречу движению:
	// Если двигаем строки в "+", то обходим "от большего к меньшему";
	// Если в "-", то обходим "от меньшего к большему".
	MoveAscending = (Context.Direction < 0);
	
	For Number = 1 To RowsHighlighted Do
		If MoveAscending Then 
			IndexInArray = Number - 1;
		Else
			IndexInArray = RowsHighlighted - Number;
		EndIf;
		
		TreeRow = Context.TreeRows[IndexInArray];
		KDItem = KDNode.GetObjectByID(TreeRow.ID);
		
		IndexInTree = ParentRows.IndexOf(TreeRow);
		WhereRowWillBe = IndexInTree + Context.Direction;
		If WhereRowWillBe < 0 Then // Перемещаем "в конец".
			ParentRows.Move(IndexInTree, RowsUpperBorder - IndexInTree);
			DCParentRows.Move(KDItem, RowsUpperBorder - IndexInTree);
		ElsIf WhereRowWillBe > RowsUpperBorder Then // Перемещаем "в начало".
			ParentRows.Move(IndexInTree, -IndexInTree);
			DCParentRows.Move(KDItem, -IndexInTree);
		Else
			ParentRows.Move(IndexInTree, Context.Direction);
			DCParentRows.Move(KDItem, Context.Direction);
		EndIf;
	EndDo;
	
	SetModified();
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Клиент - Таблицы полей (универсальные точки входа).

&AtClient
Procedure SelectDisplayMode(SettingsNodeFilters, CollectionName, RowID, ShowInputModes, ShowCheckBoxesModes, CurrentDisplayMode = Undefined)
	Context = New Structure("SettingsNodeFilters, CollectionName, RowID", SettingsNodeFilters, CollectionName, RowID);
	Handler = New NotifyDescription("DisplayModeAfterChoice", ThisObject, Context);
	
	List = New ValueList;
	If ShowInputModes Then
		List.Add("ShowInReportHeader", NStr("en='In the header of the report';ru='В шапке отчета';vi='Trong phần đầu báo cáo'"), , PictureLib.QuickAccess);
	EndIf;
	If ShowCheckBoxesModes Then
		List.Add("ShowOnlyCheckBoxInReportHeader", NStr("ru = 'Только флажок в шапке отчета';
																	|en = 'Only checkbox in the report header;"), , PictureLib.RapidAccessWithCheckBox);
	EndIf;
	If ShowInputModes Then
		List.Add("ShowInReportSettings", NStr("en='In the report settings';ru='В настройках отчета';vi='Trong tùy chỉnh báo cáo'"), , PictureLib.Attribute);
	EndIf;
	If ShowCheckBoxesModes Then
		List.Add("ShowOnlyCheckBoxInReportSettings", NStr("en='Only checkbox in the report settings';ru='Только флажок в настройках отчета';vi='Chỉ hộp kiểm trong tùy chỉnh báo cáo'"), , PictureLib.UsualAccessWithCheckBox);
	EndIf;
	List.Add("DontShow", NStr("en='Do not show';ru='Не показывать';vi='Không hiển thị'"), , PictureLib.ReportHiddenSetting);
	
	If CurrentDisplayMode = Undefined Then
		ShowChooseFromMenu(Handler, List);
	Else
		ViewMode = List.FindByValue(CurrentDisplayMode);
		ExecuteNotifyProcessing(Handler, ViewMode);
	EndIf;
EndProcedure

&AtClient
Procedure DisplayModeAfterChoice(ViewMode, Context) Export
	If ViewMode = Undefined Then
		Return;
	EndIf;
	
	If ViewMode.Value = "ShowInReportHeader" Then
		DisplayModePicture = 2;
	ElsIf ViewMode.Value = "ShowOnlyCheckBoxInReportHeader" Then
		DisplayModePicture = 1;
	ElsIf ViewMode.Value = "ShowInReportSettings" Then
		DisplayModePicture = 4;
	ElsIf ViewMode.Value = "ShowOnlyCheckBoxInReportSettings" Then
		DisplayModePicture = 3;
	Else
		DisplayModePicture = 5;
	EndIf;
	
	Row = ThisObject[Context.CollectionName].FindByID(Context.RowID);
	If Row = Undefined Then
		Return;
	EndIf;
	
	SettingItem = Context.SettingsNodeFilters.GetObjectByID(Row.ID);
	If SettingItem = Undefined Then
		Return;
	EndIf;
	
	SetDisplayMode(Context.CollectionName, Row, SettingItem, DisplayModePicture);
	
	SetModified();
EndProcedure

&AtClient
Procedure SetDisplayMode(CollectionName, Row, SettingItem, DisplayModePicture = Undefined)
	If DisplayModePicture = Undefined Then
		DisplayModePicture = Row.DisplayModePicture;
	Else
		Row.DisplayModePicture = DisplayModePicture;
	EndIf;
	
	If DisplayModePicture = 1 Or DisplayModePicture = 2 Then
		SettingItem.ViewMode = DataCompositionSettingsItemViewMode.QuickAccess;
	ElsIf DisplayModePicture = 3 Or DisplayModePicture = 4 Then
		SettingItem.ViewMode = DataCompositionSettingsItemViewMode.Normal;
	Else
		SettingItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	EndIf;
	
	If CollectionName = "Filters" And Not Row.IsParameter Then
		If DisplayModePicture = 1 Or DisplayModePicture = 3 Then
			// Когда ПредставлениеПользовательскойНастройки заполнено,
			// то Представление работает как переключатель,
			// но также может использоваться для вывода в табличный документ.
			SettingItem.Presentation = Row.Title;
		Else
			SettingItem.Presentation = "";
		EndIf;
		
		If Not Row.IsPredefinedTitle Then
			SettingItem.UserSettingPresentation = Row.Title;
		EndIf;
	ElsIf CollectionName = "Appearance" Then
		// Особенность УО - ПредставлениеПользовательскойНастройки может очищаться после ПолучитьНастройки().
		If Row.IsPredefinedTitle Then
			If DisplayModePicture = 1 Or DisplayModePicture = 3 Then
				// Когда ПредставлениеПользовательскойНастройки заполнено,
				// то Представление работает как переключатель,
				// но также может использоваться для вывода в табличный документ.
				SettingItem.Presentation = Row.Title;
			Else
				SettingItem.Presentation = "";
			EndIf;
		Else
			// Когда ПредставлениеПользовательскойНастройки заполнено,
			// то Представление работает как переключатель,
			// но также может использоваться для вывода в табличный документ.
			SettingItem.Presentation = Row.Title;
		EndIf;
	EndIf;
	
	If SettingItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible Then
		SettingItem.UserSettingID = "";
	ElsIf Not ValueIsFilled(SettingItem.UserSettingID) Then
		SettingItem.UserSettingID = New UUID;
	EndIf;
EndProcedure

&AtClientAtServerNoContext
Function SettingItemDisplayModePicture(SettingItem)
	DisplayModePicture = 5;
	
	If ValueIsFilled(SettingItem.UserSettingID) Then
		If SettingItem.ViewMode = DataCompositionSettingsItemViewMode.QuickAccess Then
			If TypeOf(SettingItem) = Type("DataCompositionSettingsParameterValue")
				Or TypeOf(SettingItem) = Type("DataCompositionConditionalAppearanceItem") Then 
				DisplayModePicture = 2;
			Else
				DisplayModePicture = ?(ValueIsFilled(SettingItem.Presentation), 1, 2);
			EndIf;
		ElsIf SettingItem.ViewMode = DataCompositionSettingsItemViewMode.Normal Then
			If TypeOf(SettingItem) = Type("DataCompositionSettingsParameterValue")
				Or TypeOf(SettingItem) = Type("DataCompositionConditionalAppearanceItem") Then 
				DisplayModePicture = 4;
			Else
				DisplayModePicture = ?(ValueIsFilled(SettingItem.Presentation), 3, 4);
			EndIf;
		EndIf;
	EndIf;
	
	Return DisplayModePicture;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Клиент - Таблицы полей (функциональная часть).

&AtClientAtServerNoContext
Function SettingItem(Val SettingsNode, Val Row)
	SettingItem = Undefined;
	
	If Row <> Undefined
		And TypeOf(Row.ID) = Type("DataCompositionID") Then
		
		SettingItem = SettingsNode.GetObjectByID(Row.ID);
	EndIf;
	
	If TypeOf(SettingItem) = Type("DataCompositionNestedObjectSettings") Then
		SettingItem = SettingItem.Settings;
	EndIf;
	
	Return SettingItem;
EndFunction

&AtClientAtServerNoContext
Function SettingsItems(Val StructureItemProperty, Val SettingItem = Undefined, CollectionName = Undefined)
	If SettingItem = Undefined Then
		SettingItem = StructureItemProperty;
	EndIf;
	
	ObjectType = TypeOf(SettingItem);
	
	If CollectionName <> Undefined
		And (ObjectType = Type("DataCompositionTable")
			And StrSplit("Rows, Columns", ", ", False).Find(CollectionName) <> Undefined
		Or ObjectType = Type("DataCompositionChart")
			And StrSplit("Series, Points", ", ", False).Find(CollectionName) <> Undefined) Then 
		Return SettingItem[CollectionName];
	EndIf;
	
	If ObjectType = Type("DataCompositionSettings")
		Or ObjectType = Type("DataCompositionGroup")
		Or ObjectType = Type("DataCompositionTableGroup")
		Or ObjectType = Type("DataCompositionChartGroup") Then
		
		Return SettingItem.Structure;
	ElsIf ObjectType = Type("DataCompositionSettingStructureItemCollection")
		Or ObjectType = Type("DataCompositionTableStructureItemCollection")
		Or ObjectType = Type("DataCompositionChartStructureItemCollection") Then
		
		Return SettingItem;
	ElsIf ObjectType = Type("DataCompositionNestedObjectSettings") Then 
		
		Return SettingItem.Settings.Structure;
	EndIf;
	
	Return SettingItem.Items;
EndFunction

&AtClient
Function SettingsCollectionNameByID(ID)
	CollectionName = Undefined;
	
	Path = Upper(ID);
	If StrFind(Path, "SERIES") > 0 Then 
		CollectionName = "Series";
	ElsIf StrFind(Path, "POINT") > 0 Then 
		CollectionName = "Points";
	ElsIf StrFind(Path, "ROW") > 0 Then 
		CollectionName = "Rows";
	ElsIf StrFind(Path, "COLUMN") > 0 Then 
		CollectionName = "Columns";
	EndIf;
	
	Return CollectionName;
EndFunction

&AtClient
Function GetSettingItemParent(Val StructureItemProperty, Val SettingItem)
	Parent = Undefined;
	
	ItemType = TypeOf(SettingItem);
	If SettingItem <> Undefined
		And ItemType <> Type("DataCompositionGroupField")
		And ItemType <> Type("DataCompositionAutoOrderItem")
		And ItemType <> Type("DataCompositionOrderItem")
		And ItemType <> Type("DataCompositionConditionalAppearanceItem")
		And ItemType <> Type("DataCompositionTableStructureItemCollection") Then 
		Parent = SettingItem.Parent;
	EndIf;
	
	If Parent = Undefined Then 
		Parent = StructureItemProperty;
	EndIf;
	
	Return Parent;
EndFunction

&AtClientAtServerNoContext
Function GetItems(Val Tree, Val Row)
	If Row = Undefined Then
		Row = Tree;
	EndIf;
	Return Row.GetItems();
EndFunction

&AtClient
Function GetParent(Val CollectionName, Val Row = Undefined)
	Parent = Undefined;
	
	If Row <> Undefined Then
		Parent = Row.GetParent();
	EndIf;
	
	If Parent = Undefined Then
		Parent = DefaultRootRow(CollectionName);
	EndIf;
	
	If Parent = Undefined Then
		Parent = ThisObject[CollectionName];
	EndIf;
	
	Return Parent;
EndFunction

&AtClient
Function DefaultRootRow(Val CollectionName)
	RootRow = Undefined;
	
	If CollectionName = "SelectedFields" Then
		RootRow = SelectedFields.GetItems()[0];
	ElsIf CollectionName = "Sort" Then
		RootRow = Sort.GetItems()[0];
	ElsIf CollectionName = "VariantStructure" Then
		RootRow = VariantStructure.GetItems()[0];
	ElsIf CollectionName = "Parameters" Then
		If Not SettingsStructureItemChangeMode Then
			RootRow = Filters.GetItems()[0];
		EndIf;
	ElsIf CollectionName = "Filters" Then
		If SettingsStructureItemChangeMode Then
			RootRow = Filters.GetItems()[0];
		Else
			RootRow = Filters.GetItems()[1];
		EndIf;
	ElsIf CollectionName = "Appearance" Then
		If Not SettingsStructureItemChangeMode Then 
			RootRow = Appearance.GetItems()[2];
		EndIf;
	EndIf;
	
	Return RootRow;
EndFunction

&AtClient
Procedure SelectField(CollectionName, Handler, Field = Undefined, SettingsNodeID = Undefined)
	ChoiceParameters = New Structure;
	ChoiceParameters.Insert("ReportSettings", ReportSettings);
	ChoiceParameters.Insert("SettingsComposer", Report.SettingsComposer);
	ChoiceParameters.Insert("Mode", CollectionName);
	ChoiceParameters.Insert("DCField", Field);
	ChoiceParameters.Insert("SettingsStructureItemID", 
		?(SettingsNodeID = Undefined, SettingsStructureItemID, SettingsNodeID));
	
	OpenForm(
		"SettingsStorage.ReportsVariantsStorage.Form.ReportFieldSelection",
		ChoiceParameters, ThisObject, UUID,,, Handler, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure UpdateOptionStructureItemTitle(Row)
	StructureItemProperty = SettingsStructureItemProperty(Report.SettingsComposer, "Structure");
	
	SettingItem = SettingItem(StructureItemProperty, Row);
	If SettingItem = Undefined Then
		Return;
	EndIf;
	
	ParameterValue = SettingItem.OutputParameters.FindParameterValue(New DataCompositionParameter("TitleOutput"));
	If ParameterValue <> Undefined Then
		ParameterValue.Use = True;
		If ValueIsFilled(Row.Title) Then
			ParameterValue.Value = DataCompositionTextOutputType.Output;
		Else
			ParameterValue.Value = DataCompositionTextOutputType.DontOutput;
		EndIf;
	EndIf;
	
	ParameterValue = SettingItem.OutputParameters.FindParameterValue(New DataCompositionParameter("Title"));
	If ParameterValue <> Undefined Then
		ParameterValue.Use = True;
		ParameterValue.Value = Row.Title;
	EndIf;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Клиент или сервер

&AtClientAtServerNoContext
Function SortArray(SourceArray, Direction = Undefined)
	If Direction = Undefined Then 
		Direction = SortDirection.Asc;
	EndIf;
	
	List = New ValueList;
	List.LoadValues(SourceArray);
	List.SortByValue(Direction);
	
	Return List.UnloadValues();
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Вызов сервера

&AtServer
Procedure RefreshForm(UpdateParameters = Undefined)
	ContainsNestedReports = False;
	ContainsNestedFilters = False;
	ContainsNestedFieldsOrSorting = False;
	ContainsNestedConditionalAppearance = False;
	ContainsUserStructureItems = False;
	
	ImportSettingsToComposer(UpdateParameters);
	
	If ExtendedMode = 0 Then 
		ReportsServer.UpdateSettingsFormItems(ThisObject, Items.IsMain, UpdateParameters);
		ReportsServer.RestoreFiltersValues(ThisObject);
	EndIf;
	
	UpdateSettingsFormCollections();
	
	SetChartType();
	UpdateFormItemsProperties();
EndProcedure

&AtServer
Procedure UpdateSettingsFormCollections()
	// Очистка настроек.
	GroupingContent.GetItems().Clear();
	Filters.GetItems().Clear();
	SelectedFields.GetItems().Clear();
	Sort.GetItems().Clear();
	Appearance.GetItems().Clear();
	VariantStructure.GetItems().Clear();
	
	SetChartType();
	
	// Обновление настроек.
	UpdateGroupFields();
	UpdateDataParameters();
	UpdateFilters();
	UpdateSelectedFields();
	UpdateSorting();
	UpdateAppearance();
	UpdateStructure();
	
	// Поиск помеченных на удаление.
	MarkedForDeletion.Clear();
	FindFieldsMarkedForDeletion();
EndProcedure

&AtServer
Procedure SetChartType()
	Items.CurrentChartType.Visible = False;
	
	If SettingsStructureItemType <> "DataCompositionChart" Then
		Return;
	EndIf;
	
	Items.CurrentChartType.TypeRestriction = New TypeDescription("ChartType");
	
	StructureItem = Report.SettingsComposer.Settings.GetObjectByID(SettingsStructureItemID);
	If TypeOf(StructureItem) = Type("DataCompositionNestedObjectSettings") Then
		StructureItem = StructureItem.Settings;
	EndIf;
	
	SettingItem = StructureItem.OutputParameters.FindParameterValue(New DataCompositionParameter("ChartType"));
	If SettingItem <> Undefined Then
		CurrentChartType = SettingItem.Value;
	EndIf;
	
	Items.CurrentChartType.Visible = (SettingItem <> Undefined);
EndProcedure

&AtServer
Procedure UpdateFormItemsProperties()
	SettingsComposer = Report.SettingsComposer;
	
	#Region CommonItemsPropertiesFlags
	
	IsExtendedMode = Boolean(ExtendedMode);
	DisplayInformation = IsExtendedMode And Not SettingsStructureItemChangeMode;
	
	#EndRegion
	
	#Region SimpleEditModeItemsProperties
	
	Items.IsMain.Visible = Not IsExtendedMode;
	Items.Additionally.Visible = Not IsExtendedMode;
	
	Items.TitleOutput.Visible = Not IsExtendedMode;
	Items.DisplayParametersAndFilters.Visible = Not IsExtendedMode;
	
	#EndRegion
	
	#Region GroupContentPageItemsProperties
	
	DisplayGroupContent = (IsExtendedMode
		And SettingsStructureItemChangeMode
		And SettingsStructureItemType <> "DataCompositionChart");
	
	Items.PageGroupingContent.Visible = DisplayGroupContent;
	Items.CommandsGroupingContent.Visible = DisplayGroupContent;
	Items.GroupingContent.Visible = DisplayGroupContent;
	
	#EndRegion
	
	#Region FiltersPageItemsProperties
	
	DisplayFilters = (IsExtendedMode
		And SettingsStructureItemType <> "DataCompositionChart");
	
	If IsExtendedMode Then
		Items.PageFilters.Title = NStr("en='Filters';ru='Отборы';vi='Bộ lọc'");
	Else
		Items.PageFilters.Title = NStr("en='Main';ru='Основное';vi='Chính'");
	EndIf;
	
	Items.Filters.Visible = DisplayFilters;
	Items.GroupThereAreNestedFilters.Visible = DisplayFilters;
	Items.GroupThereAreNestedFilters.Visible = DisplayFilters
		And ContainsNestedFilters
		And DisplayInformation;
	
	#EndRegion
	
	#Region FieldsAndSortingPageItemsProperties
	
	StructureItemProperty = SettingsStructureItemProperty(
		SettingsComposer, "Selection", SettingsStructureItemID, ExtendedMode);
	DisplaySelectedFields =
		StructureItemProperty <> Undefined
		And (ValueIsFilled(StructureItemProperty.UserSettingID) Or IsExtendedMode);
	
	StructureItemProperty = SettingsStructureItemProperty(
		SettingsComposer, "Order", SettingsStructureItemID, ExtendedMode);
	DisplaySorting =
		SettingsStructureItemType <> "DataCompositionChart"
		And StructureItemProperty <> Undefined
		And (ValueIsFilled(StructureItemProperty.UserSettingID) Or IsExtendedMode);
	
	If DisplaySelectedFields And DisplaySorting Then
		Items.SelectedFieldsAndSortingsPage.Title = NStr("en='Fields and sortings';ru='Поля и сортировки';vi='Trường và sắp xếp'");
	ElsIf DisplaySelectedFields Then
		Items.SelectedFieldsAndSortingsPage.Title = NStr("en='Fileds';ru='Поля';vi='Trường'");
	ElsIf DisplaySorting Then
		Items.SelectedFieldsAndSortingsPage.Title = NStr("en='Sortings';ru='Сортировки';vi='Sắp xếp'");
	EndIf;
	
	Items.SelectedFields.Visible = DisplaySelectedFields;
	Items.SelectedFieldsCommands_AddDelete.Visible = DisplaySelectedFields And IsExtendedMode;
	Items.SelectedFieldsCommands_AddDelete1.Visible = DisplaySelectedFields And IsExtendedMode;
	Items.SelectedFieldsCommands_Groups.Visible = DisplaySelectedFields And IsExtendedMode;
	Items.SelectedFieldsCommands_Group1.Visible = DisplaySelectedFields And IsExtendedMode;
	
	Items.FieldsAndSortingCommands.Visible = DisplaySelectedFields And DisplaySorting;
	
	Items.Sort.Visible = DisplaySorting;
	Items.SortCommands_AddDelete.Visible = DisplaySorting And IsExtendedMode;
	Items.SortingCommands_AddDelete1.Visible = DisplaySorting And IsExtendedMode;
	
	Items.HasNestedFieldsOrSortingGroup.Visible = ContainsNestedFieldsOrSorting And DisplayInformation;
	
	#EndRegion
	
	#Region AppearancePageItemsProperties
	
	DisplayAppearance = IsExtendedMode;
	Items.Appearance.Visible = DisplayAppearance;
	Items.HasNestedAppearanceGroup.Visible = DisplayAppearance
		And ContainsNestedConditionalAppearance
		And DisplayInformation;
	
	#EndRegion
	
	#Region OptionStructurePageItemsProperties
	
	DisplayOptionStructure =
		ReportSettings.EditStructureAllowed
		And Not SettingsStructureItemChangeMode
		And (ContainsUserStructureItems Or IsExtendedMode);
	
	Items.PageVariantStructure.Visible = DisplayOptionStructure;
	
	Items.VariantStructureCommands_Add.Visible = IsExtendedMode;
	Items.VariantStructureCommands_Add1.Visible = IsExtendedMode;
	Items.VariantStructureCommands_Change.Visible = IsExtendedMode;
	Items.VariantStructureCommands_Change1.Visible = IsExtendedMode;
	Items.VariantStructureCommands_MovementByHierarchy.Visible = IsExtendedMode;
	Items.VariantStructureCommands_MovementByHierarchy1.Visible = IsExtendedMode;
	Items.VariantStructureCommands_MovementInsideParent.Visible = IsExtendedMode;
	Items.VariantStructureCommands_MovementInsideParent1.Visible = IsExtendedMode;
	
	Items.VariantStructure.ChangeRowSet = IsExtendedMode;
	Items.VariantStructure.ChangeRowOrder = IsExtendedMode;
	Items.VariantStructure.EnableStartDrag = IsExtendedMode;
	Items.VariantStructure.EnableDrag = IsExtendedMode;
	Items.VariantStructure.Header = IsExtendedMode;
	
	Items.VariantStructureTitle.Visible = IsExtendedMode;
	
	Items.VariantStructureContainsFilters.Visible = IsExtendedMode;
	Items.VariantStructureContainsFieldsOrOrders.Visible = IsExtendedMode;
	Items.VariantStructureContainsConditionalAppearance.Visible = IsExtendedMode;
	
	#EndRegion
	
	#Region CommonItemsProperties
	
	If Not IsExtendedMode
		And IsMobileClient Then 
		DisplayPages = False;
	Else
		DisplayPages =
			DisplayGroupContent
			Or DisplayFilters
			Or DisplaySelectedFields
			Or DisplaySorting
			Or DisplayAppearance
			Or DisplayOptionStructure;
	EndIf;
	
	If DisplayPages Then 
		Items.SettingPages.PagesRepresentation = FormPagesRepresentation.TabsOnTop;
	Else
		Items.SettingPages.CurrentPage = Items.PageFilters;
		Items.SettingPages.PagesRepresentation = FormPagesRepresentation.None;
	EndIf;
	
	Items.GroupThereAreNestedReports.Visible = ContainsNestedReports And DisplayInformation;
	Items.HasNonexistentFieldsGroup.Visible =  MarkedForDeletion.Count() > 0 And DisplayInformation;
	
	Items.ExtendedMode.Visible = ReportSettings.EditOptionsAllowed And Not SettingsStructureItemChangeMode;
	Items.EditFiltersConditions.Visible = AllowEditingFiltersConditions();
	
	If SettingsStructureItemChangeMode Then
		Items.CloseAndGenerate.Title = NStr("en='Finish editing';ru='Завершить редактирование';vi='Hoàn tất chỉnh sửa'");
		
		Items.Close.Title = NStr("en='Cancel';ru='Отмена';vi='Huỷ bỏ'");
	Else
		Items.CloseAndGenerate.Title = NStr("en='Close and generate';ru='Закрыть и сформировать';vi='Đóng và lập báo cáo'");
		
		Items.Close.Title = NStr("en='Close';ru='Закрыть';vi='Đóng'");
	EndIf;
	
	CountOfAvailableSettings = ReportsServer.CountOfAvailableSettings(Report.SettingsComposer);
	Items.CloseAndGenerate.Visible = CountOfAvailableSettings.Total > 0 Or DisplayPages;
	
	#EndRegion
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Сервер

&AtServer
Procedure DefineBehaviorInMobileClient()
	IsMobileClient = CommonUse.IsMobileClient();
	If Not IsMobileClient Then 
		Return;
	EndIf;
	
	CommandBarLocation = FormCommandBarLabelLocation.Auto;
	Items.CloseAndGenerate.Representation = ButtonRepresentation.Picture;
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	ConditionalAppearance.Items.Clear();
	
	#Region ConditionalTableAppearanceOfGroupContentForm
	
	// ПоказыватьТипДополнения = Истина.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GroupingContent.ShowAdditionType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	Item.Appearance.SetParameterValue("Show", False);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GroupingContentGroupType.Name);
	
	// ПоказыватьТипДополнения = Ложь.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GroupingContent.ShowAdditionType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	Item.Appearance.SetParameterValue("Show", False);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GroupingContentAdditionType.Name);
	
	// Поле = Неопределено.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GroupingContent.Field");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Undefined;
	
	Item.Appearance.SetParameterValue("Visible", False);
	Item.Appearance.SetParameterValue("Show", False);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GroupingContentGroupType.Name);
	
	// Заголовок - Заполнено.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GroupingContent.Title");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("GroupingContent.Title"));
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GroupingContentField.Name);
	
	#EndRegion
	
	#Region ConditionalTableAppearanceOfFiltersForm
	
	// ЭтоРаздел = Истина.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.ThisIsSection");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersParameter.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.filtersComparisonType.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.filtersValue.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.filtersDisplayModePicture.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.filtersUserSettingPresentation.Name);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.ThisIsSection");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersGroupType.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersLeftValue.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.filtersRightValue.Name);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.ThisIsSection");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.filtersUse.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersGroupType.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersLeftValue.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.filtersComparisonType.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.filtersValue.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.filtersDisplayModePicture.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.filtersUserSettingPresentation.Name);
	
	// ЭтоПараметр = Истина.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsParameter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersParameter.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.filtersComparisonType.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.filtersDisplayModePicture.Name);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsParameter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersGroupType.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersLeftValue.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.filtersRightValue.Name);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsParameter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersGroupType.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.filtersComparisonType.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersLeftValue.Name);
	
	// ЭтоПериод = Истина.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsPeriod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Show", False);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.filtersComparisonType.Name);
	
	// ОтображатьИспользование = Ложь.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.DisplayUsage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Show", False);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.filtersUse.Name);
	
	// ЭтоРаздел = Ложь; ЭтоПараметр = Ложь; ЭтоГруппа = Ложь - это элемент отбора.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.ThisIsSection");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsParameter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsFolder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersLeftValue.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.filtersDisplayModePicture.Name);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.ThisIsSection");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsParameter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsFolder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersParameter.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersGroupType.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.filtersValue.Name);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.ThisIsSection");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsParameter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsFolder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersParameter.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersGroupType.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.filtersValue.Name);
	
	// ЭтоГруппа = Истина.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsFolder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersGroupType.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.filtersDisplayModePicture.Name);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsFolder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersParameter.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersLeftValue.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.filtersValue.Name);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsFolder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersParameter.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersLeftValue.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.filtersComparisonType.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.filtersValue.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.filtersRightValue.Name);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsFolder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.Title");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("Filters.GroupType"));
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.filtersUserSettingPresentation.Name);
	
	// ЭтоУникальныйИдентификатор = Истина.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.ThisIsUUID");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.filtersRightValue.Name);
	
	// Заголовок - Заполнено.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.Title");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("Filters.Title"));
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersParameter.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersGroupType.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FiltersLeftValue.Name);
	
	// ПредставлениеЗначения - Заполнено.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.ValueDescription");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("Filters.ValueDescription"));
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.filtersValue.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.filtersRightValue.Name);
	
	// ЭтоПредопределенныйЗаголовок = Истина.
	//
	ProhibitedCellTextColor = Metadata.StyleItems.UnavailableCellTextColor;
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Filters.IsPredefinedTitle");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", ProhibitedCellTextColor.Value);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.filtersUserSettingPresentation.Name);
	
	#EndRegion
	
	#Region ConditionalTableAppearanceOfSelectedFieldsForm
	
	// ЭтоРаздел = Истина.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SelectedFields.ThisIsSection");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	Item.Appearance.SetParameterValue("Show", False);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedFieldsUse.Name);
	
	// Заголовок - Заполнено.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SelectedFields.Title");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("SelectedFields.Title"));
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedFieldsField.Name);
	
	#EndRegion
	
	#Region ConditionalTableAppearanceOfSortingForm
	
	// ЭтоРаздел = Истина.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Sort.ThisIsSection");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	Item.Appearance.SetParameterValue("Show", False);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SortUse.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SortOrderType.Name);
	
	// ЭтоАвтоПоле = Истина.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Sort.IsAutoField");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	Item.Appearance.SetParameterValue("Show", False);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SortOrderType.Name);
	
	// Заголовок - Заполнено.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Sort.Title");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("Sort.Title"));
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SortField.Name);
	
	#EndRegion
	
	#Region ConditionalTableAppearanceOfAppearanceForm
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AppearanceTitle.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AppearanceAccessPictureIndex.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Appearance.IsOutputParameter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AppearanceUsage.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AppearanceTitle.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AppearanceAccessPictureIndex.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Appearance.ThisIsSection");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	#EndRegion
	
	#Region ConditionalTableAppearanceOfOptionStructureForm
	
	ImportantInscriptionFont = Metadata.StyleItems.ImportantLabelFont.Value;
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("VariantStructure.IsFolder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Font", ImportantInscriptionFont);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.VariantStructurePresentation.Name);

	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("VariantStructure.Title");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ExtendedMode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("VariantStructure.Title"));
	Item.Appearance.SetParameterValue("Font", ImportantInscriptionFont);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.VariantStructurePresentation.Name);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("VariantStructure.CheckBoxAvailable");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	Item.Appearance.SetParameterValue("Show", False);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.VariantStructureUse.Name);
	
	#EndRegion
EndProcedure

&AtServer
Procedure ImportSettingsToComposer(ImportParameters)
	CheckImportParameters(ImportParameters);
	
	ReportObject = ReportsServer.ReportObject(ImportParameters.ReportObjectOrFullName);
	If ReportSettings.Events.BeforeFillingQuickSettingsPanel Then
		ReportObject.BeforeFillingQuickSettingsPanel(ThisObject, ImportParameters);
	EndIf;
	
	AvailableSettings = ReportsServer.AvailableSettings(ImportParameters, ReportSettings);
	
	UpdateVariantSettings = CommonUseClientServer.StructureProperty(ImportParameters, "UpdateVariantSettings", False);
	If UpdateVariantSettings Then
		AvailableSettings.Settings = Report.SettingsComposer.GetSettings();
		Report.SettingsComposer.LoadFixedSettings(New DataCompositionSettings);
		AvailableSettings.FixedSettings = Report.SettingsComposer.FixedSettings;
	EndIf;
	
	ReportsServer.ResetUserSettings(AvailableSettings, ImportParameters);
	
	If ReportSettings.Events.BeforeImportSettingsToComposer Then
		ReportObject.BeforeImportSettingsToComposer(
			ThisObject,
			ReportSettings.SchemaKey,
			CurrentVariantKey,
			AvailableSettings.Settings,
			AvailableSettings.UserSettings);
	EndIf;
	
	SettingsImported = ReportsClientServer.LoadSettings(
		Report.SettingsComposer,
		AvailableSettings.Settings,
		AvailableSettings.UserSettings,
		AvailableSettings.FixedSettings);
	
	// Установка фиксированных отборов выполняется через компоновщик, т.к. в нем наиболее полная коллекция настроек.
	// В ПередЗагрузкой в параметрах могут отсутствовать те параметры, настройки которые не переопределялись.
	If SettingsImported And TypeOf(ParametersForm.Filter) = Type("Structure") Then
		ReportsServer.SetFixedFilters(ParametersForm.Filter, AvailableSettings.Settings, ReportSettings);
	EndIf;
	
	If ParametersForm.Property("FixedSettings") Then 
		ParametersForm.FixedSettings = Report.SettingsComposer.FixedSettings;
	EndIf;
	
	ReportsServer.SetAvailableValues(ReportObject, ThisObject);
	ReportsServer.InitializePredefinedOutputParameters(ReportSettings, AvailableSettings.Settings);
	
	FiltersConditions = CommonUseClientServer.StructureProperty(ImportParameters, "FiltersConditions");
	If FiltersConditions <> Undefined Then
		UserSettings = Report.SettingsComposer.UserSettings;
		For Each Condition In FiltersConditions Do
			UserSettingsItem = UserSettings.GetObjectByID(Condition.Key);
			If UserSettingsItem <> Undefined Then 
				UserSettingsItem.ComparisonType = Condition.Value;
			EndIf;
		EndDo;
	EndIf;
	
	InitializePredefinedOutputParametersAttributes();
	SettingsComposer = Report.SettingsComposer;
	
	If ImportParameters.VariantModified Then
		OptionChanged = True;
	EndIf;
	
	If ImportParameters.UserSettingsModified Then
		UserSettingsModified = True;
	EndIf;
EndProcedure

&AtServer
Procedure CheckImportParameters(ImportParameters)
	If TypeOf(ImportParameters) <> Type("Structure") Then 
		ImportParameters = New Structure;
	EndIf;
	
	If Not ImportParameters.Property("EventName") Then
		ImportParameters.Insert("EventName", "");
	EndIf;
	
	If Not ImportParameters.Property("VariantModified") Then
		ImportParameters.Insert("VariantModified", VariantModified);
	EndIf;
	
	If Not ImportParameters.Property("UserSettingsModified") Then
		ImportParameters.Insert("UserSettingsModified", UserSettingsModified);
	EndIf;
	
	If Not ImportParameters.Property("Result") Then
		ImportParameters.Insert("Result", New Structure);
	EndIf;
	
	If Not ImportParameters.Property("Result") Then
		ImportParameters.Insert("Result", New Structure);
		ImportParameters.Result.Insert("ExpandTreesNodes", New Array);
	EndIf;
	
	ImportParameters.Insert("Abort", False);
	ImportParameters.Insert("ReportObjectOrFullName", ReportSettings.FullName);
EndProcedure

&AtServer
Procedure InitializePredefinedOutputParametersAttributes()
	PredefinedParameters = Report.SettingsComposer.Settings.OutputParameters.Items;
	
	Object = PredefinedParameters.Find("TITLE");
	TitleOutput = Object.Use;
	
	Object = PredefinedParameters.Find("DATAPARAMETERSOUTPUT");
	LinkedObject = PredefinedParameters.Find("FILTEROUTPUT");
	
	DisplayParametersAndFilters = (Object.Value <> DataCompositionTextOutputType.DontOutput
		Or LinkedObject.Value <> DataCompositionTextOutputType.DontOutput);
EndProcedure

&AtServer
Function AttributeFullName(Attribute)
	Return ?(IsBlankString(Attribute.Path), "", Attribute.Path + ".") + Attribute.Name;
EndFunction

&AtClientAtServerNoContext
Function TypesDetailsWithoutPrimitiveOnes(InitialTypeDescription)
	DeductionTypes = New Array;
	If InitialTypeDescription.ContainsType(Type("String")) Then
		DeductionTypes.Add(Type("String"));
	EndIf;
	If InitialTypeDescription.ContainsType(Type("Date")) Then
		DeductionTypes.Add(Type("Date"));
	EndIf;
	If InitialTypeDescription.ContainsType(Type("Number")) Then
		DeductionTypes.Add(Type("Number"));
	EndIf;
	If DeductionTypes.Count() = 0 Then
		Return InitialTypeDescription;
	EndIf;
	Return New TypeDescription(InitialTypeDescription, , DeductionTypes);
EndFunction

&AtClient
Procedure RegisterList(Item, SettingItem)
	Value = Undefined;
	If TypeOf(SettingItem) = Type("DataCompositionSettingsParameterValue") Then 
		Value = SettingItem.Value;
	ElsIf TypeOf(SettingItem) = Type("DataCompositionFilterItem") Then 
		Value = SettingItem.RightValue;
	EndIf;

	If TypeOf(Value) <> Type("ValueList") Then 
		Return;
	EndIf;
	
	IndexOf = SettingsComposer.UserSettings.Items.IndexOf(SettingItem);
	ListPath = PathToItemsData.ByIndex[IndexOf];
	
	List = Items.Find(ListPath);
	If SettingItem.Use Then 
		List.TextColor = New Color;
	Else
		ClientParameter = StandardSubsystemsClient.ClientWorkParameters();
		List.TextColor = ClientParameter.StyleItems.UnavailableCellTextColor;
	EndIf;
EndProcedure

&AtServer
Function AllowEditingFiltersConditions()
	If Boolean(ExtendedMode) Then 
		Return False;
	EndIf;
	
	SettingsComposer = Report.SettingsComposer;
	
	UserSettings = SettingsComposer.UserSettings;
	For Each UserSettingsItem In UserSettings.Items Do 
		SettingItem = ReportsClientServer.GetObjectByUserIdentifier(
			SettingsComposer.Settings,
			UserSettingsItem.UserSettingID,,
			UserSettings);
		
		If TypeOf(SettingItem) <> Type("DataCompositionFilterItem")
			Or TypeOf(SettingItem.RightValue) = Type("StandardPeriod")
			Or SettingItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible Then 
			Continue;
		EndIf;
		
		Return True;
	EndDo;
	
	Return False;
EndFunction

&AtClient
Procedure SetModified()
	UserSettingsModified = True;
	If ExtendedMode = 1 Then
		OptionChanged = True;
	EndIf;
EndProcedure

#EndRegion

#Region ProcessFieldsMarkedForDeletion

// Поиск полей, помеченных на удаление.

&AtServer
Procedure FindFieldsMarkedForDeletion(Val StructureItems = Undefined)
	If SettingsStructureItemChangeMode Then 
		Return;
	EndIf;
	
	Settings = Report.SettingsComposer.Settings;
	
	If StructureItems = Undefined Then 
		StructureItems = Settings.Structure;
		
		FindSelectedFieldsMarkedForDeletion(Settings);
		FindFilterFieldsMarkedForDeletion(Settings);
		FindOrderFieldsMarkedForDeletion(Settings);
		FindConditionalAppearanceItemsMarkedForDeletion(Settings);
	EndIf;
	
	For Each StructureItem In StructureItems Do 
		ItemType = TypeOf(StructureItem);
		If ItemType = Type("DataCompositionGroup")
			Or ItemType = Type("DataCompositionTableGroup")
			Or ItemType = Type("DataCompositionChartGroup") Then 
			
			FindSelectedFieldsMarkedForDeletion(Settings, StructureItem);
			FindFilterFieldsMarkedForDeletion(Settings, StructureItem);
			FindOrderFieldsMarkedForDeletion(Settings, StructureItem);
			FindConditionalAppearanceItemsMarkedForDeletion(Settings, StructureItem);
			FindGroupingFieldsMarkedForDeletion(Settings, StructureItem);
		EndIf;
		
		NamesOfCollections = StructureItemCollectionsNames(StructureItem);
		For Each CollectionName In NamesOfCollections Do 
			StructureItemCollection = SettingsItems(StructureItem,, CollectionName);
			FindFieldsMarkedForDeletion(StructureItemCollection);
		EndDo;
	EndDo;
	
	Processed = MarkedForDeletion.Unload();
	Processed.GroupBy("StructureItemID, ItemIdentificator, KeyStructureItemProperties");
	Processed.Sort("StructureItemID Desc, KeyStructureItemProperties, ItemIdentificator");
	
	MarkedForDeletion.Load(Processed);
EndProcedure

&AtServer
Procedure FindSelectedFieldsMarkedForDeletion(Settings, Val StructureItem = Undefined, Var_Group = Undefined)
	If StructureItem = Undefined Then 
		StructureItem = Settings;
	EndIf;
	
	StructureItemProperty = StructureItem.Selection;
	AvailableFields = StructureItemProperty.SelectionAvailableFields;
	AutoFieldType = Type("DataCompositionAutoSelectedField");
	GroupType = Type("DataCompositionSelectedFieldGroup");
	
	SettingsItems = ?(Var_Group = Undefined, StructureItemProperty.Items, Var_Group.Items);
	For Each SettingItem In SettingsItems Do 
		If TypeOf(SettingItem) = GroupType Then 
			FindSelectedFieldsMarkedForDeletion(Settings,  StructureItem, SettingItem);
			Continue;
		EndIf;
		
		If TypeOf(SettingItem) = AutoFieldType
			Or AvailableFields.FindField(SettingItem.Field) <> Undefined Then 
			Continue;
		EndIf;
		
		Record = MarkedForDeletion.Add();
		Record.StructureItemID = Settings.GetIDByObject(StructureItem);
		Record.ItemIdentificator = StructureItemProperty.GetIDByObject(SettingItem);
		Record.KeyStructureItemProperties = "Selection";
	EndDo;
EndProcedure

&AtServer
Procedure FindFilterFieldsMarkedForDeletion(Settings, Val StructureItem = Undefined, Var_Group = Undefined)
	If StructureItem = Undefined Then 
		StructureItem = Settings;
	EndIf;
	
	StructureItemProperty = StructureItem.Filter;
	AvailableFields = StructureItemProperty.FilterAvailableFields;
	GroupType = Type("DataCompositionFilterItemGroup");
	
	SettingsItems = ?(Var_Group = Undefined, StructureItemProperty.Items, Var_Group.Items);
	For Each SettingItem In SettingsItems Do 
		If TypeOf(SettingItem) = GroupType Then 
			FindFilterFieldsMarkedForDeletion(Settings,  StructureItem, SettingItem);
			Continue;
		EndIf;
		
		If TypeOf(SettingItem.LeftValue) <> Type("DataCompositionField")
			Or AvailableFields.FindField(SettingItem.LeftValue) <> Undefined Then 
			Continue;
		EndIf;
		
		Record = MarkedForDeletion.Add();
		Record.StructureItemID = Settings.GetIDByObject(StructureItem);
		Record.ItemIdentificator = StructureItemProperty.GetIDByObject(SettingItem);
		Record.KeyStructureItemProperties = "Filter";
	EndDo;
EndProcedure

&AtServer
Procedure FindOrderFieldsMarkedForDeletion(Settings, Val StructureItem = Undefined)
	If StructureItem = Undefined Then 
		StructureItem = Settings;
	EndIf;
	
	StructureItemProperty = StructureItem.Order;
	AvailableFields = StructureItemProperty.OrderAvailableFields;
	AutoFieldType = Type("DataCompositionAutoOrderItem");
	
	For Each SettingItem In StructureItemProperty.Items Do 
		If TypeOf(SettingItem) = AutoFieldType
			Or AvailableFields.FindField(SettingItem.Field) <> Undefined Then 
			Continue;
		EndIf;
		
		Record = MarkedForDeletion.Add();
		Record.StructureItemID = Settings.GetIDByObject(StructureItem);
		Record.ItemIdentificator = StructureItemProperty.GetIDByObject(SettingItem);
		Record.KeyStructureItemProperties = "Order";
	EndDo;
EndProcedure

&AtServer
Procedure FindConditionalAppearanceItemsMarkedForDeletion(Settings, Val StructureItem = Undefined)
	If StructureItem = Undefined Then 
		StructureItem = Settings;
	EndIf;
	
	StructureItemProperty = StructureItem.ConditionalAppearance;
	
	For Each SettingItem In StructureItemProperty.Items Do 
		AvailableFields = SettingItem.Fields.AppearanceFieldsAvailableFields;
		For Each Item In SettingItem.Fields.Items Do 
			If AvailableFields.FindField(Item.Field) <> Undefined Then 
				Continue;
			EndIf;
			
			Record = MarkedForDeletion.Add();
			Record.StructureItemID = Settings.GetIDByObject(StructureItem);
			Record.ItemIdentificator = StructureItemProperty.GetIDByObject(SettingItem);
			Record.KeyStructureItemProperties = "ConditionalAppearance";
		EndDo;
		
		FindConditionalAppearanceFilterItemsMarkedForDeletion(Settings, StructureItem, SettingItem);
	EndDo;
EndProcedure

&AtServer
Procedure FindConditionalAppearanceFilterItemsMarkedForDeletion(Settings, StructureItem, DesignElement, Var_Group = Undefined)
	StructureItemProperty = StructureItem.ConditionalAppearance;
	
	AvailableFields = DesignElement.Filter.FilterAvailableFields;
	GroupType = Type("DataCompositionFilterItemGroup");
	
	SettingsItems = ?(Var_Group = Undefined, DesignElement.Filter.Items, Var_Group.Items);
	For Each SettingItem In SettingsItems Do 
		If TypeOf(SettingItem) = GroupType Then 
			FindConditionalAppearanceFilterItemsMarkedForDeletion(
				Settings,  StructureItem, DesignElement, SettingItem);
			Continue;
		EndIf;
		
		If AvailableFields.FindField(SettingItem.LeftValue) <> Undefined Then 
			Continue;
		EndIf;
		
		Record = MarkedForDeletion.Add();
		Record.StructureItemID = Settings.GetIDByObject(StructureItem);
		Record.ItemIdentificator = StructureItemProperty.GetIDByObject(DesignElement);
		Record.KeyStructureItemProperties = "ConditionalAppearance";
	EndDo;
EndProcedure

&AtServer
Procedure FindGroupingFieldsMarkedForDeletion(Settings, StructureItem)
	StructureItemProperty = StructureItem.GroupFields;
	AvailableFields = StructureItemProperty.GroupFieldsAvailableFields;
	AutoFieldType = Type("DataCompositionAutoGroupField");
	
	For Each SettingItem In StructureItemProperty.Items Do 
		If TypeOf(SettingItem) = AutoFieldType
			Or AvailableFields.FindField(SettingItem.Field) <> Undefined Then 
			Continue;
		EndIf;
		
		Record = MarkedForDeletion.Add();
		Record.StructureItemID = Settings.GetIDByObject(StructureItem);
		Record.ItemIdentificator = StructureItemProperty.GetIDByObject(SettingItem);
		Record.KeyStructureItemProperties = "GroupFields";
	EndDo;
EndProcedure

&AtServer
Function StructureItemCollectionsNames(Item)
	NamesOfCollections = "";
	
	ItemType = TypeOf(Item);
	If ItemType = Type("DataCompositionGroup")
		Or ItemType = Type("DataCompositionTableGroup")
		Or ItemType = Type("DataCompositionChartGroup")
		Or ItemType = Type("DataCompositionNestedObjectSettings")
		Or ItemType = Type("DataCompositionSettingStructureItemCollection") Then 
		
		NamesOfCollections = "Structure";
		
	ElsIf ItemType = Type("DataCompositionTable")
		Or ItemType = Type("DataCompositionTableStructureItemCollection") Then 
	
		NamesOfCollections = "Rows, Columns";
		
	ElsIf ItemType = Type("DataCompositionChart")
		Or ItemType = Type("DataCompositionChartStructureItemCollection") Then 
		
		NamesOfCollections = "Points, Series";
		
	EndIf;
	
	Return StrSplit(NamesOfCollections, ", ", False);
EndFunction

// Удаление полей, помеченных на удаление.

&AtClient
Procedure DeleteFiedsMarkedForDeletion()
	SettingsComposer = Report.SettingsComposer;
	
	For Each Record In MarkedForDeletion Do 
		StructureItemProperty = SettingsStructureItemProperty(
			SettingsComposer, Record.KeyStructureItemProperties, Record.StructureItemID, ExtendedMode);
		
		SettingItem = StructureItemProperty.GetObjectByID(Record.ItemIdentificator);
		If SettingItem = Undefined Then 
			Continue;
		EndIf;
		
		SettingItemParent = GetSettingItemParent(StructureItemProperty, SettingItem);
		SettingsItems = SettingsItems(StructureItemProperty, SettingItemParent);
		SettingsItems.Delete(SettingItem);
		
		If SettingsItems.Count() = 0
			And TypeOf(SettingItemParent) = Type("DataCompositionGroupFields") Then 
			
			StructureItem = SettingsComposer.Settings.GetObjectByID(Record.StructureItemID);
			If TypeOf(StructureItem) = Type("DataCompositionGroup") Then 
				StructureItems = StructureItem.Structure;
				If StructureItems.Count() = 0 Then 
					Continue;
				EndIf;
				
				IndexOf = StructureItems.Count() - 1;
				While IndexOf >= 0 Do 
					StructureItems.Delete(StructureItems[IndexOf]);
					IndexOf = IndexOf - 1;
				EndDo;
			Else // ГруппировкаТаблицыКомпоновкиДанных или ГруппировкаДиаграммыКомпоновкиДанных.
				StructureItemParent = GetSettingItemParent(StructureItemProperty, StructureItem);
				CollectionName = SettingsCollectionNameByID(Record.StructureItemID);
				StructureItems = SettingsItems(StructureItemProperty, StructureItemParent, CollectionName);
				StructureItems.Delete(StructureItem);
			EndIf;
		EndIf;
	EndDo;
	
	SetModified();
EndProcedure

#EndRegion

#EndRegion