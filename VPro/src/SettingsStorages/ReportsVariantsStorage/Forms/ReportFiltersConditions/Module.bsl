///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2020, ООО 1С-Софт
// Все права защищены. Эта программа и сопроводительные материалы предоставляются 
// в соответствии с условиями лицензии Attribution 4.0 International (CC BY 4.0)
// Текст лицензии доступен по ссылке:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	CloseOnChoice = False;
	
	FillPropertyValues(ThisObject, Parameters, "ReportSettings, SettingsComposer");
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(ReportSettings.SchemaURL));
	
	OwnerFormType = CommonUseClientServer.StructureProperty(
		Parameters, "OwnerFormType", ReportFormType.Main);
	
	UpdateFilters(OwnerFormType);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventsHandlersFiltersTable

&AtClient
Procedure FiltersOnActivateRow(Item)
	List = Items.filtersComparisonType.ChoiceList;
	List.Clear();
	
	Row = Item.CurrentData;
	If Row = Undefined
		Or Row.AvailableCompareTypes = Undefined Then 
		Return;
	EndIf;
	
	For Each KindsCompare In Row.AvailableCompareTypes Do 
		FillPropertyValues(List.Add(), KindsCompare);
	EndDo;
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure Select(Command)
	ChooseAndClose();
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Procedure SetConditionalAppearance()
	ConditionalAppearance.Items.Clear();
	
	// ПредставлениеПользовательскойНастройки - НеЗаполнено.
	// Представление - Заполнено.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("filters.UserSettingPresentation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("filters.Presentation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("filters.Presentation"));
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.filtersUserSettingPresentation.Name);
	
	// ПредставлениеПользовательскойНастройки - НеЗаполнено.
	// Представление - НеЗаполнено.
	// Заголовок - Заполнено.
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("filters.UserSettingPresentation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("filters.Presentation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("filters.Title");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("filters.Title"));
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.filtersUserSettingPresentation.Name);
EndProcedure

&AtServer
Procedure UpdateFilters(OwnerFormType)
	Rows = Filters.GetItems();
	
	AllowedDisplayModes = New Array;
	AllowedDisplayModes.Add(DataCompositionSettingsItemViewMode.Auto);
	AllowedDisplayModes.Add(DataCompositionSettingsItemViewMode.QuickAccess);
	If OwnerFormType = ReportFormType.Settings Then 
		AllowedDisplayModes.Add(DataCompositionSettingsItemViewMode.Normal);
	EndIf;
	
	UserSettings = SettingsComposer.UserSettings;
	For Each UserSettingsItem In UserSettings.Items Do 
		If TypeOf(UserSettingsItem) <> Type("DataCompositionFilterItem")
			Or TypeOf(UserSettingsItem.RightValue) = Type("StandardPeriod") Then 
			Continue;
		EndIf;
		
		SettingItem = ReportsClientServer.GetObjectByUserIdentifier(
			SettingsComposer.Settings,
			UserSettingsItem.UserSettingID,,
			UserSettings);
		
		If AllowedDisplayModes.Find(SettingItem.ViewMode) = Undefined Then 
			Continue;
		EndIf;
		
		SettingDetails = ReportsClientServer.FindAvailableSetting(SettingsComposer.Settings, SettingItem);
		If SettingDetails = Undefined Then 
			Continue;
		EndIf;
		
		Row = Rows.Add();
		FillPropertyValues(Row, SettingDetails);
		FillPropertyValues(Row, SettingItem, "Presentation, UserSettingPresentation");
		
		Row.ComparisonType = UserSettingsItem.ComparisonType;
		
		AvailableCompareTypes = SettingDetails.AvailableCompareTypes;
		If AvailableCompareTypes <> Undefined
			And AvailableCompareTypes.Count() > 0
			And AvailableCompareTypes.FindByValue(Row.ComparisonType) = Undefined Then 
			Row.ComparisonType = AvailableCompareTypes[0].Value;
		EndIf;
		
		Row.ID = UserSettings.GetIDByObject(UserSettingsItem);
		Row.InitialComparisonType = Row.ComparisonType;
	EndDo;
EndProcedure

&AtClient
Procedure ChooseAndClose()
	FiltersConditions = New Map;
	
	Rows = Filters.GetItems();
	For Each Row In Rows Do
		If Row.InitialComparisonType <> Row.ComparisonType Then
			FiltersConditions.Insert(Row.ID, Row.ComparisonType);
		EndIf;
	EndDo;
	
	Close(FiltersConditions);
EndProcedure

#EndRegion
