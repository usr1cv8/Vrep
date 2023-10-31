#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("ShowAdditionalAttributes") Then
		StandardSubsystemsServer.SetFormPurposeKey(ThisObject,
			"SetsAdditionalDetails");
		Items.ThisIsSetOfAdditionalInformation.Visible = False;
		
	ElsIf Parameters.Property("ShowAdditionalInformation") Then
		StandardSubsystemsServer.SetFormPurposeKey(ThisObject,
			"AdditionalInformationSets");
		Items.ThisIsSetOfAdditionalInformation.Visible = False;
		ThisIsSetOfAdditionalInformation = True;
	EndIf;
	
	ColorForms = Items.Properties.BackColor;
	
	ConfigureRepresentationSets();
	ApplyAppearanceSetsAndProperties();
	
	If Not CommonUse.SubsystemExists("StandardSubsystems.SearchAndDeleteDuplicates") Then
		Items.SearchAndDeleteDuplicates.Visible = False;
	EndIf;
	
	If CommonUse.IsMobileClient() Then
		Items.PropertiesSets.InitialTreeView = InitialTreeView.ExpandAllLevels;
		Items.PropertiesSets.TitleLocation         = FormItemTitleLocation.Top;
		Items.Properties.TitleLocation              = FormItemTitleLocation.Top;
		Items.PropertiesPopupAdd.Representation      = ButtonRepresentation.Picture;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Src)
	
	If EventName = "Writing_AdditionalAttributesAndInformation"
	 Or EventName = "Record_ValuesOfObjectProperties"
	 Or EventName = "Record_ValuesOfObjectPropertiesHierarchy" Then
		
		// При записи свойства необходимо перенести свойство в соответствующую группу.
		// При записи значения необходимо обновить список первых 3-х значений.
		OnChangeOfCurrentSetAtServer();
		
	ElsIf EventName = "Transition_SetsOfAdditionalDetailsAndInformation" Then
		// При открытии формы для редактирования состава свойств конкретного объекта метаданных
		// необходимо перейти к набору или группе наборов этого объекта метаданных.
		If TypeOf(Parameter) = Type("Structure") Then
			SelectSpecifiedRows(Parameter);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region HeaderFormItemsEventsHandlers

&AtClient
Procedure ThisIsSetOfAdditionalInformationOnChange(Item)
	
	ConfigureRepresentationSets();
	ApplyAppearanceSetsAndProperties();
	
EndProcedure

&AtClient
Procedure ShowUnusedAttributesOnChange(Item)
	SwitchSetList();
	OnChangeOfCurrentSet();
EndProcedure

#EndRegion

#Region FormTableItemsEventsHandlersPropertiesSets

&AtClient
Procedure PropertiesSetsOnActivateRow(Item)
	
	AttachIdleHandler("OnChangeOfCurrentSet", 0.1, True);
	
EndProcedure

&AtClient
Procedure PropertiesSetsBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure PropertiesSetsDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	StandardProcessing = False;
	
	If Row = Undefined Then
		Return;
	EndIf;
	
	If Items.PropertiesSets.RowData(Row).IsFolder Then
		DragParameters.Action = DragAction.Cancel;
	EndIf;
	
EndProcedure

&AtClient
Procedure PropertiesSetsDrag(Item, DragParameters, StandardProcessing, Row, Field)
	StandardProcessing = False;
	
	If DragParameters.Value.GeneralValues Then
		DraggedItem = DragParameters.Value.AdditionalValuesOwner;
	Else
		DraggedItem = DragParameters.Value.Property;
	EndIf;
	
	If TypeOf(DraggedItem) <> Type("ChartOfCharacteristicTypesRef.AdditionalAttributesAndInformation") Then
		Return;
	EndIf;
	
	DestinationSet = Row;
	AddAttributeToSet(DraggedItem, Row);
EndProcedure

&AtServerNoContext
Procedure PropertiesSetsOnGetDataAtServer(ItemName, Settings, Rows)
	
	IsMainLanguage = (CurrentLanguage() = Metadata.DefaultLanguage);
	
	For Each DynamicListRow In Rows Do
		Data = DynamicListRow.Value.Data;
		If Data.IsFolder Then
			Data.Presentation = String(Data.Ref);
			Continue;
		EndIf;
		
		If Data.IsInformation Then
			If Not ValueIsFilled(Data.CountInformation) Then
				Data.Presentation = String(Data.Ref);
				Continue;
			EndIf;
			If ValueIsFilled(Data.DescriptionInOtherLanguages) Then
				Data.Presentation = Data.DescriptionInOtherLanguages + " (" + Data.CountInformation + ")";
				Continue;
			EndIf;
			Data.Presentation = String(Data.Ref) + " (" + Data.CountInformation + ")";
		Else
			If Not ValueIsFilled(Data.CountAttributes) Then
				Data.Presentation = String(Data.Ref);
				Continue;
			EndIf;
			If ValueIsFilled(Data.DescriptionInOtherLanguages) Then
				Data.Presentation = Data.DescriptionInOtherLanguages + " (" + Data.CountAttributes + ")";
				Continue;
			EndIf;
			Data.Presentation = String(Data.Ref) + " (" + Data.CountAttributes + ")";
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventsHandlersProperties

&AtClient
Procedure PropertiesOnActivateRow(Item)
	
	PropertiesSetEnabledCommands(ThisObject);
	
EndProcedure

&AtClient
Procedure PropertiesBeforeAddRow(Item, Cancel, Copy, Parent, Group)
	
	If Copy Then
		Copy();
	Else
		Create();
	EndIf;
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure PropertiesBeforeRowChange(Item, Cancel)
	
	Change();
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure PropertiesBeforeDeleteRow(Item, Cancel)
	
	ChangeDeletionMark();
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure PropertiesChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	StandardProcessing = False;
	
	If TypeOf(SelectedValue) = Type("Structure") Then
		If SelectedValue.Property("AdditionalValuesOwner") Then
			
			FormParameters = New Structure;
			FormParameters.Insert("ThisIsAdditionalInformation",      ThisIsSetOfAdditionalInformation);
			FormParameters.Insert("CurrentSetOfProperties",            CurrentSet);
			FormParameters.Insert("AdditionalValuesOwner", SelectedValue.AdditionalValuesOwner);
			
			OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInformation.ObjectForm",
				FormParameters, Items.Properties);
			
		ElsIf SelectedValue.Property("CommonProperty") Then
			
			ChangedSet = CurrentSet;
			If SelectedValue.Property("Drag") Then
				AddCommonPropertyByDragAndDrop(SelectedValue.CommonProperty);
			Else
				ExecuteCommandAtServer("AddCommonProperty", SelectedValue.CommonProperty);
				ChangedSet = DestinationSet;
			EndIf;
			
			Notify("Writing_AdditionalAttributesAndInformationSets",
				New Structure("Ref", ChangedSet), ChangedSet);
		Else
			SelectSpecifiedRows(SelectedValue);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure PropertiesDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure PropertiesDragStart(Item, DragParameters, Execution)
	// Перемещение свойств и реквизитов не поддерживается, всегда выполняется копирование.
	// Иконка курсора при этом должна быть соответствующая.
	DragParameters.AllowedActions = DragAllowedActions.Copy;
	DragParameters.Action           = DragAction.Copy;
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure Create(Command = Undefined)
	
	FormParameters = New Structure;
	FormParameters.Insert("PropertySet", CurrentSet);
	FormParameters.Insert("ThisIsAdditionalInformation", ThisIsSetOfAdditionalInformation);
	FormParameters.Insert("CurrentSetOfProperties", CurrentSet);
	
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInformation.ObjectForm",
		FormParameters, Items.Properties);
	
EndProcedure

&AtClient
Procedure AddFromSet(Command)
	
	FormParameters = New Structure;
	
	SelectedValues = New Array;
	FoundStrings = Properties.FindRows(New Structure("Common", True));
	For Each Row In FoundStrings Do
		SelectedValues.Add(Row.Property);
	EndDo;
	
	If ThisIsSetOfAdditionalInformation Then
		FormParameters.Insert("SelectionOfCommonProperty", True);
	Else
		FormParameters.Insert("OwnersSelectionOfAdditionalValues", True);
	EndIf;
	
	FormParameters.Insert("SelectedValues", SelectedValues);
	FormParameters.Insert("ThisIsAdditionalInformation", ThisIsSetOfAdditionalInformation);
	FormParameters.Insert("CurrentSetOfProperties", CurrentSet);
	
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInformation.Form.ItemForm",
		FormParameters, Items.Properties);
EndProcedure

&AtClient
Procedure Change(Command = Undefined)
	
	If Items.Properties.CurrentData <> Undefined Then
		// Открытие формы свойства.
		FormParameters = New Structure;
		FormParameters.Insert("Key", Items.Properties.CurrentData.Property);
		FormParameters.Insert("CurrentSetOfProperties", CurrentSet);
		
		OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInformation.ObjectForm",
			FormParameters, Items.Properties);
	EndIf;
	
EndProcedure

&AtClient
Procedure Copy(Command = Undefined, PasteFromClipboard = False)
	
	FormParameters = New Structure;
	CopyingValue = Items.Properties.CurrentData.Property;
	FormParameters.Insert("AdditionalValuesOwner", CopyingValue);
	FormParameters.Insert("CurrentSetOfProperties", CurrentSet);
	FormParameters.Insert("CopyingValue", CopyingValue);
	
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInformation.ObjectForm", FormParameters);
	
EndProcedure

&AtClient
Procedure AddAttributeToSet(AdditionalValuesOwner, Set = Undefined)
	
	FormParameters = New Structure;
	If Set = Undefined Then
		CurrentSetOfProperties = CurrentSet;
	Else
		CurrentSetOfProperties = Set;
		FormParameters.Insert("Drag", True);
	EndIf;
	
	FormParameters.Insert("CopyWithQuestion", True);
	FormParameters.Insert("AdditionalValuesOwner", AdditionalValuesOwner);
	FormParameters.Insert("ThisIsAdditionalInformation", ThisIsSetOfAdditionalInformation);
	FormParameters.Insert("CurrentSetOfProperties", CurrentSetOfProperties);
	
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInformation.ObjectForm", FormParameters, Items.Properties);
	
EndProcedure

&AtClient
Procedure MarkToDelete(Command)
	
	ChangeDeletionMark();
	
EndProcedure

&AtClient
Procedure MoveUp(Command)
	
	ExecuteCommandAtServer("MoveUp");
	
EndProcedure

&AtClient
Procedure MoveDown(Command)
	
	ExecuteCommandAtServer("MoveDown");
	
EndProcedure

&AtClient
Procedure SearchAndDeleteDuplicates(Command)
	SearchAndDeleteDuplicatesModuleClient = CommonUseClient.CommonModule("SearchAndDeleteDuplicatesClient");
	SearchAndDeleteDuplicatesFormName = SearchAndDeleteDuplicatesModuleClient.ИмяФормыОбработкиПоискИУдалениеДублей();
	OpenForm(SearchAndDeleteDuplicatesFormName);
EndProcedure

&AtClient
Procedure CopySelectedAttribute(Command)
	AttributeToCopy = New Structure;
	AttributeToCopy.Insert("AttributeToCopy", Items.Properties.CurrentData.Property);
	AttributeToCopy.Insert("GeneralValues", Items.Properties.CurrentData.GeneralValues);
	AttributeToCopy.Insert("AdditionalValuesOwner", Items.Properties.CurrentData.AdditionalValuesOwner);
	
	Items.PasteAttribute.Enabled = Not ShowUnusedAttributes;
EndProcedure

&AtClient
Procedure PasteAttribute(Command)
	If AttributeToCopy.GeneralValues Then
		AdditionalValuesOwner = AttributeToCopy.AdditionalValuesOwner;
	Else
		AdditionalValuesOwner = AttributeToCopy.AttributeToCopy;
	EndIf;
	
	AddAttributeToSet(AdditionalValuesOwner);
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Procedure ApplyAppearanceSetsAndProperties()
	
	// Оформление корня списка наборов.
	ConditionalAppearanceItem = PropertiesSets.ConditionalAppearance.Items.Add();
	
	ItemColorsDesign = ConditionalAppearanceItem.Appearance.Items.Find("Text");
	ItemColorsDesign.Value = NStr("en='Sets';ru='Наборы';vi='Tập hợp'");
	ItemColorsDesign.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("Ref");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.NotFilled;
	DataFilterItem.Use  = True;
	
	ItemProcessedFields = ConditionalAppearanceItem.Fields.Items.Add();
	ItemProcessedFields.Field = New DataCompositionField("Presentation");
	ItemProcessedFields.Use = True;
	
	// Оформление недоступных групп наборов, которые безусловно отображаются платформой, как часть дерева групп.
	ConditionalAppearanceItem = PropertiesSets.ConditionalAppearance.Items.Add();
	
	ItemVisible = ConditionalAppearanceItem.Appearance.Items.Find("Visible");
	ItemVisible.Value = False;
	ItemVisible.Use = True;
	
	FolderSelectionDataElements = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FolderSelectionDataElements.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	FolderSelectionDataElements.Use = True;
	
	DataFilterItem = FolderSelectionDataElements.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("Ref");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.NotInList;
	DataFilterItem.RightValue = AvailableSetsList;
	DataFilterItem.Use  = True;
	
	DataFilterItem = FolderSelectionDataElements.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("Parent");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.NotInList;
	DataFilterItem.RightValue = AvailableSetsList;
	DataFilterItem.Use  = True;
	
	DataFilterItem = FolderSelectionDataElements.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("Ref");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.Filled;
	DataFilterItem.Use  = True;
	
	ItemProcessedFields = ConditionalAppearanceItem.Fields.Items.Add();
	ItemProcessedFields.Field = New DataCompositionField("Presentation");
	ItemProcessedFields.Use = True;
	
	// Оформление свойств, обязательных для заполнения.
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemColorsDesign = ConditionalAppearanceItem.Appearance.Items.Find("Font");
	ItemColorsDesign.Value = StyleFonts.MainListItem;
	ItemColorsDesign.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("Properties.FillObligatory");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = True;
	DataFilterItem.Use  = True;
	
	ItemProcessedFields = ConditionalAppearanceItem.Fields.Items.Add();
	ItemProcessedFields.Field = New DataCompositionField("PropertiesTitle");
	ItemProcessedFields.Use = True;
	
EndProcedure

&AtClient
Procedure SelectSpecifiedRows(LongDesc)
	
	If LongDesc.Property("Set") Then
		
		If TypeOf(LongDesc.Set) = Type("String") Then
			ConvertRowsToLinks(LongDesc);
		EndIf;
		
		If LongDesc.ThisIsAdditionalInformation <> ThisIsSetOfAdditionalInformation Then
			ThisIsSetOfAdditionalInformation = LongDesc.ThisIsAdditionalInformation;
			ConfigureRepresentationSets();
		EndIf;
		
		Items.PropertiesSets.CurrentRow = LongDesc.Set;
		CurrentSet = Undefined;
		OnChangeOfCurrentSet();
		FoundStrings = Properties.FindRows(New Structure("Property", LongDesc.Property));
		If FoundStrings.Count() > 0 Then
			Items.Properties.CurrentRow = FoundStrings[0].GetID();
		Else
			Items.Properties.CurrentRow = Undefined;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SwitchSetList()
	
	If Not ShowUnusedAttributes Then
		Items.PageSets.CurrentPage = Items.Default;
		Return;
	EndIf;
	
	Items.PageSets.CurrentPage = Items.Used;
	
	CommonUseClientServer.SetDynamicListParameter(
		UsedSets, "ThisIsAdditionalInformation", (ThisIsSetOfAdditionalInformation = 1), True);
	
	CommonUseClientServer.SetDynamicListParameter(
		UsedSets, "CommonAdditionalInformation", NStr("en='Unused additional information';ru='Неиспользуемые дополнительные сведения';vi='Thông tin bổ sung không sử dụng'"), True);
	
	CommonUseClientServer.SetDynamicListParameter(
		UsedSets, "CommonAdditionalAttributes", NStr("en='Unused additional details';ru='Неиспользуемые дополнительные реквизиты';vi='Mục tin bổ sung không sử dụng'"), True);
	
EndProcedure

&AtServerNoContext
Procedure ConvertRowsToLinks(LongDesc)
	
	LongDesc.Insert("Set", Catalogs.AdditionalAttributesAndInformationSets.GetRef(
		New UUID(LongDesc.Set)));
	
	LongDesc.Insert("Property", ChartsOfCharacteristicTypes.AdditionalAttributesAndInformation.GetRef(
		New UUID(LongDesc.Property)));
	
EndProcedure

&AtServer
Procedure ConfigureRepresentationSets()
	
	CommandCreate                      = Commands.Find("Create");
	CommandCopy                  = Commands.Find("Copy");
	CommandChange                     = Commands.Find("Change");
	CommandMarkToDelete           = Commands.Find("MarkToDelete");
	CommandMoveUp             = Commands.Find("MoveUp");
	CommandMoveDown              = Commands.Find("MoveDown");
	
	If ThisIsSetOfAdditionalInformation Then
		Title = NStr("en='Find out more';ru='Дополнительные сведения';vi='Thông tin bổ sung'");
		
		CommandCreate.ToolTip          = NStr("en='Create a unique mix';ru='Создать уникальное сведение';vi='Tạo thông tin đơn trị'");
		CommandCreate.Title          = NStr("en='New';ru='Новое';vi='Mới'");
		CommandCreate.ToolTip          = NStr("en='Create a unique mix';ru='Создать уникальное сведение';vi='Tạo thông tin đơn trị'");
		
		CommandCopy.ToolTip        = NStr("en='Create a new mix by copying the current';ru='Создать новое сведение копированием текущего';vi='Tạo mới thông tin bằng cách sao chép thông tin hiện tại'");
		CommandChange.ToolTip           = NStr("en='Change (or open) the current mix';ru='Изменить (или открыть) текущее сведение';vi='Thay đổi (hoặc mở) thông tin hiện tại'");
		CommandMarkToDelete.ToolTip = NStr("en='Mark the current deletion (Del)';ru='Пометить текущее сведение на удаление (Del)';vi='Đánh dấu xóa thông tin hiện tại (Del)'");
		CommandMoveUp.ToolTip   = NStr("en='Move the current mix up';ru='Переместить текущее сведение вверх';vi='Chuyển thông tin hiện tại lên trên'");
		CommandMoveDown.ToolTip    = NStr("en='Move the current mix-up down';ru='Переместить текущее сведение вниз';vi='Chuyển thông tin hiện tại xuống dưới'");
		
		MetadataTabularSection =
			Metadata.Catalogs.AdditionalAttributesAndInformationSets.TabularSections.AdditionalInformation;
		
		Items.PropertiesTitle.ToolTip = MetadataTabularSection.Attributes.Property.Tooltip;
		
		Items.PropertiesFillObligatory.Visible = False;
		
		Items.PropertiesValueType.ToolTip =
			NStr("en='The types of value you can enter when you fill in the information.';ru='Типы значения, которое можно ввести при заполнении сведения.';vi='Kiểu giá trị mà có thể nhập khi điền thông tin.'");
		
		Items.PropertiesGeneralValues.ToolTip =
			NStr("en='The information uses a list of sample information values.';ru='Сведение использует список значений сведения-образца.';vi='Thông tin sử dụng danh sách giá trị thông tin mẫu'");
		
		Items.ShowUnusedAttributes.Title = NStr("en='Show unused information';ru='Показать неиспользуемые сведения';vi='Hiển thị các thông tin không sử dụng'");
		
		Items.PropertiesCommon.Title = NStr("en='Total';ru='Общее';vi='Chung'");
		Items.PropertiesCommon.ToolTip = NStr("en='The total additional mix that is used in the"
"a few sets of additional information.';ru='Общее дополнительное сведение, которое используется в"
"нескольких наборах дополнительных сведений.';vi='Thông tin bổ sung chung mà được sử dụng trong"
"nhiều tập hợp thông tin bổ sung.'");
	Else
		Title = NStr("en='Additional attributes';ru='Дополнительные реквизиты';vi='Mục tin bổ sung'");
		CommandCreate.Title          = NStr("en='New';ru='Новый';vi='Mới'");
		CommandCreate.ToolTip          = NStr("en='Create unique attribute';ru='Создать уникальный реквизит';vi='Tạo mục tin đơn trị'");
		
		CommandCopy.ToolTip        = NStr("en='Create new attribute by copying the current one';ru='Создать новый реквизит копированием текущего';vi='Tạo mới mục tin bằng cách sao chép mục tin hiện tại'");
		CommandChange.ToolTip           = NStr("en='Change (or open) current attribute';ru='Изменить (или открыть) текущий реквизит';vi='Thay đổi (hoặc mở) mục tin hiện tại'");
		CommandMarkToDelete.ToolTip = NStr("en='Mark the current deletion attribute (Del)';ru='Пометить текущий реквизит на удаление (Del)';vi='Đánh dấu xóa mục tin hiện tại (Del)'");
		CommandMoveUp.ToolTip   = NStr("en='Move the current attribute up';ru='Переместить текущий реквизит вверх';vi='Chuyển mục tin hiện tại lên trên'");
		CommandMoveDown.ToolTip    = NStr("en='Move the current attribute down';ru='Переместить текущий реквизит вниз';vi='Chuyển mục tin hiện tại xuống dưới'");
		
		MetadataTabularSection =
			Metadata.Catalogs.AdditionalAttributesAndInformationSets.TabularSections.AdditionalAttributes;
		
		Items.PropertiesTitle.ToolTip = MetadataTabularSection.Attributes.Property.Tooltip;
		
		Items.PropertiesFillObligatory.Visible = True;
		Items.PropertiesFillObligatory.ToolTip =
			Metadata.ChartsOfCharacteristicTypes.AdditionalAttributesAndInformation.Attributes.FillObligatory.Tooltip;
		
		Items.PropertiesValueType.ToolTip =
			NStr("en='The types of value that you can enter when filling out attribute.';ru='Типы значения, которое можно ввести при заполнении реквизита.';vi='Kiểu giá trị mà có thể nhập khi điền mục tin.'");
		
		Items.PropertiesGeneralValues.ToolTip =
			NStr("en='The attribute use a list of sample attribute.';ru='Реквизит использует список значений реквизита-образца.';vi='Mục tin sử dụng danh sách giá trị mục tin mẫu.'");
		
		Items.ShowUnusedAttributes.Title = NStr("en='Show unused attribute';ru='Показать неиспользуемые реквизиты';vi='Hiển thị các mục tin không sử dụng'");
		
		Items.PropertiesCommon.Title = NStr("en='Shared';ru='Общий';vi='Chung'");
		Items.PropertiesCommon.ToolTip = NStr("en='The total additional attribute that are used in the"
"several sets of additional attribute.';ru='Общий дополнительный реквизит, который используется в"
"нескольких наборах дополнительных реквизитов.';vi='Mục tin bổ sung chung được sử dụng trong nhiều"
"tập hợp mục tin bổ sung.'");
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	PropertySets.Ref AS Ref
	|FROM
	|	Catalog.AdditionalAttributesAndInformationSets AS PropertySets
	|WHERE
	|	PropertySets.Parent = VALUE(Catalog.AdditionalAttributesAndInformationSets.EmptyRef)";
	
	PropertySets = Query.Execute().Unload().UnloadColumn("Ref");
	AvailableSets = New Array;
	AvailableSetsList.Clear();
	
	For Each Ref In PropertySets Do
		SetPropertyTypes = PropertiesManagementService.SetPropertyTypes(Ref, False);
		
		If ThisIsSetOfAdditionalInformation
		   And SetPropertyTypes.AdditionalInformation
		 Or Not ThisIsSetOfAdditionalInformation
		   And SetPropertyTypes.AdditionalAttributes Then
			
			AvailableSets.Add(Ref);
			AvailableSetsList.Add(Ref);
		EndIf;
	EndDo;
	
	CommonUseClientServer.SetDynamicListParameter(
		PropertiesSets, "ThisIsSetOfAdditionalInformation", ThisIsSetOfAdditionalInformation, True);
	
	CommonUseClientServer.SetDynamicListParameter(
		PropertiesSets, "PropertySets", AvailableSets, True);
		
	CommonUseClientServer.SetDynamicListParameter(
		PropertiesSets, "IsMainLanguage", CurrentLanguage() = Metadata.DefaultLanguage, True);
	
	CommonUseClientServer.SetDynamicListParameter(
		PropertiesSets, "LanguageCode", CurrentLanguage().LanguageCode, True);
	
	OnChangeOfCurrentSetAtServer();
	
EndProcedure

&AtClient
Procedure OnChangeOfCurrentSet()
	
	If ShowUnusedAttributes Then
		CurrentSet = Undefined;
		OnChangeOfCurrentSetAtServer();
	ElsIf Items.PropertiesSets.CurrentData = Undefined Then
		If ValueIsFilled(CurrentSet) Then
			CurrentSet = Undefined;
			OnChangeOfCurrentSetAtServer();
		EndIf;
		
	ElsIf Items.PropertiesSets.CurrentData.Ref <> CurrentSet Then
		CurrentSet          = Items.PropertiesSets.CurrentData.Ref;
		CurrentSetIsFolder = Items.PropertiesSets.CurrentData.IsFolder;
		OnChangeOfCurrentSetAtServer();
	EndIf;
	
#If MobileClient Then
	CurrentItem = Items.Properties;
	If Not ImportanceConfigured Then
		Items.PropertiesSets.DisplayImportance = DisplayImportance.VeryLow;
		ImportanceConfigured = True;
	EndIf;
	Items.Properties.Title = String(CurrentSet);
#EndIf
	
EndProcedure

&AtClient
Procedure ChangeDeletionMark()
	
	If Items.Properties.CurrentData <> Undefined Then
		
		If ThisIsSetOfAdditionalInformation Then
			If Not ShowUnusedAttributes Then
				QuestionText = NStr("en='To exclude information from the set?';ru='Исключить сведение из набора?';vi='Loại bỏ thông tin khỏi tập hợp?'");
				
			ElsIf Items.Properties.CurrentData.DeletionMark Then
				QuestionText = NStr("en='Do you want to remove the deletion mark from your current information?';ru='Снять с текущего сведения пометку на удаление?';vi='Bỏ đánh dấu xóa thông tin hiện tại?'");
			Else
				QuestionText = NStr("en='Mark the current deletion mix?';ru='Пометить текущее сведение на удаление?';vi='Đánh dấu xóa thông tin hiện tại?'");
			EndIf;
		Else
			If Not ShowUnusedAttributes Then
				QuestionText = NStr("en='To exclude attribute from the set?';ru='Исключить реквизит из набора?';vi='Loại bỏ mục tin khỏi tập hợp?'");
				
			ElsIf Items.Properties.CurrentData.DeletionMark Then
				QuestionText = NStr("en='Remove the delete note from the current attribute?';ru='Снять с текущего реквизита пометку на удаление?';vi='Bỏ dấu xóa khỏi mục tin hiện tại?'");
			Else
				QuestionText = NStr("en='Mark the current attribute for removal?';ru='Пометить текущий реквизит на удаление?';vi='Đánh dấu xóa mục tin hiện tại?'");
			EndIf;
		EndIf;
		
		ShowQueryBox(
			New NotifyDescription("ChangeDeletionMarkEnd", ThisObject, CurrentSet),
			QuestionText, QuestionDialogMode.YesNo);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeDeletionMarkEnd(Response, CurrentSet) Export
	
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ExecuteCommandAtServer("ChangeDeletionMark");
	
	Notify("Writing_AdditionalAttributesAndInformationSets",
		New Structure("Ref", CurrentSet), CurrentSet);
	
EndProcedure

&AtServer
Procedure OnChangeOfCurrentSetAtServer()
	
	If ValueIsFilled(CurrentSet)
	   And Not CurrentSetIsFolder
	   Or ShowUnusedAttributes Then
		
		CurrentEnable = True;
		If Items.Properties.BackColor <> Items.PropertiesSets.BackColor Then
			Items.Properties.BackColor = Items.PropertiesSets.BackColor;
		EndIf;
		RefreshListOfPropertiesOfCurrentSetOf(CurrentEnable);
	Else
		CurrentEnable = False;
		If Items.Properties.BackColor <> ColorForms Then
			Items.Properties.BackColor = ColorForms;
		EndIf;
		Properties.Clear();
	EndIf;
	
	If Items.Properties.ReadOnly = CurrentEnable Then
		Items.Properties.ReadOnly = Not CurrentEnable;
	EndIf;
	
	PropertiesSetEnabledCommands(ThisObject);
	
	Items.PropertiesSets.Refresh();
	
EndProcedure

&AtClientAtServerNoContext
Procedure PropertiesSetEnabledCommands(Context)
	
	Items = Context.Items;
	ShowUnusedAttributes = Context.ShowUnusedAttributes;
	
	TotalEnabled = Not Items.Properties.ReadOnly;
	InsertEnabled = TotalEnabled And (Context.AttributeToCopy <> Undefined);
	
	EnabledForRows = TotalEnabled
		And Context.Items.Properties.CurrentRow <> Undefined;
	
	TotalEnabled = TotalEnabled And Not ShowUnusedAttributes;
	
	// Настройка команд командной панели.
	Items.AddFromSet.Enabled           = TotalEnabled;
	Items.PropertiesCreate.Enabled            = TotalEnabled;
	
	Items.PropertiesCopy.Enabled        = EnabledForRows And Not ShowUnusedAttributes;
	Items.PropertiesChange.Enabled           = EnabledForRows;
	Items.PropertiesMarkToDelete.Enabled = EnabledForRows;
	
	Items.PropertiesMoveUp.Enabled   = EnabledForRows;
	Items.PropertiesMoveDown.Enabled    = EnabledForRows;
	
	Items.CopyAttribute.Enabled         = EnabledForRows;
	Items.PasteAttribute.Enabled           = InsertEnabled And Not ShowUnusedAttributes;
	
	// Настройка команд контекстного меню.
	Items.PropertiesContextMenuCreate.Enabled            = TotalEnabled;
	Items.PropertiesContextMenuAddFromSet.Enabled   = TotalEnabled;
	
	Items.PropertiesContextMenuCopy.Enabled        = EnabledForRows And Not ShowUnusedAttributes;
	Items.PropertiesContextMenuChange.Enabled           = EnabledForRows;
	Items.PropertiesContextMenuMarkToDelete.Enabled = EnabledForRows;
	
	Items.PropertiesContextMenuCopyAttribute.Enabled = EnabledForRows;
	Items.PropertiesContextMenuPasteAttribute.Enabled   = InsertEnabled And Not ShowUnusedAttributes;
	
EndProcedure

&AtServer
Procedure RefreshListOfPropertiesOfCurrentSetOf(CurrentEnable)
	
	Query = New Query;
	Query.SetParameter("Set", CurrentSet);
	Query.SetParameter("IsMainLanguage", CurrentLanguage() = Metadata.DefaultLanguage);
	Query.SetParameter("LanguageCode", CurrentLanguage().LanguageCode);
	
	If Not ShowUnusedAttributes Then
		Query.Text =
		"SELECT
		|	SetsProperties.LineNumber,
		|	SetsProperties.Property,
		|	SetsProperties.DeletionMark,
		|	CASE
		|		WHEN &IsMainLanguage
		|			THEN Properties.Title
		|		ELSE CAST(ISNULL(PresentationProperties.Title, Properties.Title) AS STRING(150))
		|	END AS Title,
		|	Properties.AdditionalValuesOwner,
		|	Properties.FillObligatory,
		|	Properties.ValueType AS ValueType,
		|	TRUE AS Common,
		|	CASE
		|		WHEN SetsProperties.DeletionMark = TRUE
		|			THEN 4
		|		ELSE 3
		|	END AS PictureNumber
		|FROM
		|	Catalog.AdditionalAttributesAndInformationSets.AdditionalAttributes AS SetsProperties
		|		LEFT JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInformation AS Properties
		|		ON SetsProperties.Property = Properties.Ref
		|		LEFT JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInformation.Presentations AS PresentationProperties
		|		ON (PresentationProperties.Ref = Properties.Ref)
		|			AND PresentationProperties.LanguageCode = &LanguageCode
		|WHERE
		|	SetsProperties.Ref = &Set
		|
		|ORDER BY
		|	SetsProperties.LineNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	PropertySets.DataVersion AS DataVersion
		|FROM
		|	Catalog.AdditionalAttributesAndInformationSets AS PropertySets
		|WHERE
		|	PropertySets.Ref = &Set";
	Else
		Query.Text =
		"SELECT
		|	Properties.Ref AS Property,
		|	Properties.DeletionMark AS DeletionMark,
		|	CASE
		|		WHEN &IsMainLanguage
		|		THEN Properties.Title
		|		ELSE CAST(ISNULL(PresentationProperties.Title, Properties.Title) AS STRING(150))
		|	END AS Title,
		|	Properties.AdditionalValuesOwner,
		|	Properties.ValueType AS ValueType,
		|	TRUE AS Common,
		|	CASE
		|		WHEN Properties.DeletionMark = TRUE
		|			THEN 4
		|		ELSE 3
		|	END AS PictureNumber,
		|	CASE
		|		WHEN &IsMainLanguage
		|		THEN Properties.ToolTip
		|		ELSE CAST(ISNULL(PresentationProperties.ToolTip, Properties.ToolTip) AS STRING(150))
		|	END AS ToolTip,
		|	CASE
		|		WHEN &IsMainLanguage
		|		THEN Properties.ValueFormHeader
		|		ELSE CAST(ISNULL(PresentationProperties.ValueFormHeader, Properties.ValueFormHeader) AS STRING(150))
		|	END AS ValueFormHeader,
		|	CASE
		|		WHEN &IsMainLanguage
		|		THEN Properties.ValueChoiceFormHeader
		|		ELSE CAST(ISNULL(PresentationProperties.ValueChoiceFormHeader, Properties.ValueChoiceFormHeader) AS STRING(150))
		|	END AS ValueChoiceFormHeader
		|FROM
		|	ChartOfCharacteristicTypes.AdditionalAttributesAndInformation AS Properties
		|		LEFT JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInformation.Presentations AS PresentationProperties
		|		ON Properties.Ref = PresentationProperties.Ref
		|			AND PresentationProperties.LanguageCode = &LanguageCode
		|		LEFT JOIN Catalog.AdditionalAttributesAndInformationSets.[TableName] AS SetContent
		|		ON Properties.Ref = SetContent.Property
		|		
		|WHERE
		|	Properties.ThisIsAdditionalInformation = &ThisIsAdditionalInformation
		|	AND SetContent.Property IS NULL
		|
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	""DataVersion"" AS DataVersion";
		
		Query.Text = StrReplace(Query.Text, "[TableName]",
			?(ThisIsSetOfAdditionalInformation, "AdditionalInformation", "AdditionalAttributes"));
		Query.SetParameter("ThisIsAdditionalInformation", (ThisIsSetOfAdditionalInformation = 1));
	EndIf;
	
	If ThisIsSetOfAdditionalInformation Then
		Query.Text = StrReplace(
			Query.Text,
			"Catalog.AdditionalAttributesAndInformationSets.AdditionalAttributes",
			"Catalog.AdditionalAttributesAndInformationSets.AdditionalInformation");
	EndIf;
	
	BeginTransaction();
	Try
		ResultsOfQuery = Query.ExecuteBatch();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If Items.Properties.CurrentRow = Undefined Then
		Row = Undefined;
	Else
		Row = Properties.FindByID(Items.Properties.CurrentRow);
	EndIf;
	CurrentProperty = ?(Row = Undefined, Undefined, Row.Property);
	
	Properties.Clear();
	
	If ResultsOfQuery[1].IsEmpty() Then
		CurrentEnable = False;
		Return;
	EndIf;
	
	CurrentSetDataVersion = ResultsOfQuery[1].Unload()[0].DataVersion;
	
	Selection = ResultsOfQuery[0].Select();
	While Selection.Next() Do
		
		NewRow = Properties.Add();
		FillPropertyValues(NewRow, Selection);
		
		NewRow.GeneralValues = ValueIsFilled(Selection.AdditionalValuesOwner);
		
		If Selection.ValueType <> NULL
		   And PropertiesManagementService.ValueTypeContainsPropertiesValues(Selection.ValueType) Then
			
			NewRow.ValueType = String(New TypeDescription(
				Selection.ValueType,
				,
				"CatalogRef.ObjectsPropertiesValuesHierarchy,
				|CatalogRef.ObjectsPropertiesValues"));
			
			Query = New Query;
			If ValueIsFilled(Selection.AdditionalValuesOwner) Then
				Query.SetParameter("Owner", Selection.AdditionalValuesOwner);
			Else
				Query.SetParameter("Owner", Selection.Property);
			EndIf;
			Query.Text =
			"SELECT TOP 4
			|	PRESENTATION(ObjectsPropertiesValues.Ref) AS Description
			|FROM
			|	Catalog.ObjectsPropertiesValues AS ObjectsPropertiesValues
			|WHERE
			|	ObjectsPropertiesValues.Owner = &Owner
			|	AND NOT ObjectsPropertiesValues.IsFolder
			|	AND NOT ObjectsPropertiesValues.DeletionMark
			|
			|UNION
			|
			|SELECT TOP 4
			|	PRESENTATION(ObjectsPropertiesValuesHierarchy.Ref) AS Description
			|FROM
			|	Catalog.ObjectsPropertiesValuesHierarchy AS ObjectsPropertiesValuesHierarchy
			|WHERE
			|	ObjectsPropertiesValuesHierarchy.Owner = &Owner
			|	AND NOT ObjectsPropertiesValuesHierarchy.DeletionMark
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT TOP 1
			|	TRUE AS TrueValue
			|FROM
			|	Catalog.ObjectsPropertiesValues AS ObjectsPropertiesValues
			|WHERE
			|	ObjectsPropertiesValues.Owner = &Owner
			|	AND NOT ObjectsPropertiesValues.IsFolder
			|
			|UNION ALL
			|
			|SELECT TOP 1
			|	TRUE
			|FROM
			|	Catalog.ObjectsPropertiesValuesHierarchy AS ObjectsPropertiesValuesHierarchy
			|WHERE
			|	ObjectsPropertiesValuesHierarchy.Owner = &Owner";
			ResultsOfQuery = Query.ExecuteBatch();
			
			FirstValues = ResultsOfQuery[0].Unload().UnloadColumn("Description");
			
			If FirstValues.Count() = 0 Then
				If ResultsOfQuery[1].IsEmpty() Then
					ValuesPresentation = NStr("en='Values not yet entered';ru='Значения еще не введены';vi='Chưa nhập các giá trị'");
				Else
					ValuesPresentation = NStr("en='Values marked for deletion';ru='Значения помечены на удаление';vi='Giá trị đã bị đánh dấu xóa'");
				EndIf;
			Else
				ValuesPresentation = "";
				Number = 0;
				For Each Value In FirstValues Do
					Number = Number + 1;
					If Number = 4 Then
						ValuesPresentation = ValuesPresentation + ",...";
						Break;
					EndIf;
					ValuesPresentation = ValuesPresentation + ?(Number > 1, ", ", "") + Value;
				EndDo;
			EndIf;
			ValuesPresentation = "<" + ValuesPresentation + ">";
			If ValueIsFilled(NewRow.ValueType) Then
				ValuesPresentation = ValuesPresentation + ", ";
			EndIf;
			NewRow.ValueType = ValuesPresentation + NewRow.ValueType;
		EndIf;
		
		If Selection.Property = CurrentProperty Then
			Items.Properties.CurrentRow =
				Properties[Properties.Count()-1].GetID();
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure AddCommonPropertyByDragAndDrop(AddedProperty)
	
	Block = New DataLock;
	LockItem = Block.Add("Catalog.AdditionalAttributesAndInformationSets");
	LockItem.SetValue("Ref", DestinationSet);
	
	Try
		LockDataForEdit(DestinationSet);
		BeginTransaction();
		Try
			Block.Lock();
			LockDataForEdit(DestinationSet);
			
			ObjectRecipientSet = DestinationSet.GetObject();
			
			TabularSection = ObjectRecipientSet[?(ThisIsSetOfAdditionalInformation,
				"AdditionalInformation", "AdditionalAttributes")];
			
			FoundString = TabularSection.Find(AddedProperty, "Property");
			
			If FoundString = Undefined Then
				NewRow = TabularSection.Add();
				NewRow.Property = AddedProperty;
				ObjectRecipientSet.Write();
				
			ElsIf FoundString.DeletionMark Then
				FoundString.DeletionMark = False;
				ObjectRecipientSet.Write();
			EndIf;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	Except
		UnlockDataForEdit(DestinationSet);
		Raise;
	EndTry;
	
	Items.PropertiesSets.Refresh();
	DestinationSet = Undefined;
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(Command, Parameter = Undefined)
	
	Block = New DataLock;
	
	If Command = "ChangeDeletionMark" Then
		LockItem = Block.Add("Catalog.AdditionalAttributesAndInformationSets");
		LockItem = Block.Add("ChartOfCharacteristicTypes.AdditionalAttributesAndInformation");
		LockItem = Block.Add("Catalog.ObjectsPropertiesValues");
		LockItem = Block.Add("Catalog.ObjectsPropertiesValuesHierarchy");
	Else
		LockItem = Block.Add("Catalog.AdditionalAttributesAndInformationSets");
		LockItem.SetValue("Ref", CurrentSet);
	EndIf;
	
	If ShowUnusedAttributes Then
		BeginTransaction();
		Try
			Block.Lock();
			
			Row = Properties.FindByID(Items.Properties.CurrentRow);
			ChangeDeletionMarkAndValuesOwner(Row.Property, Undefined);
			OnChangeOfCurrentSetAtServer();
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
		
		Return;
	EndIf;
	
	Try
		LockDataForEdit(CurrentSet);
		BeginTransaction();
		Try
			Block.Lock();
			LockDataForEdit(CurrentSet);
			
			CurrentSetObject = CurrentSet.GetObject();
			If CurrentSetObject.DataVersion <> CurrentSetDataVersion Then
				OnChangeOfCurrentSetAtServer();
				If ThisIsSetOfAdditionalInformation Then
					Raise
						NStr("en='The action has not been completed because the composition of additional information"
"has been changed by another user."
"The new composition of additional information has been read."
""
"Repeat if required.';ru='Действие не выполнено, так как состав дополнительных сведений"
"был изменен другим пользователем."
"Новый состав дополнительных сведений прочитан."
""
"Повторите действие, если требуется.';vi='Chưa thực hiện thao tác, bởi vì thành phần của thông tin bổ sung"
"đã bị thay đổi bởi người sử dụng khác."
"Đã đọc thành phần thông tin bổ sung mới."
""
"Hãy lặp lại thao tác, nếu cần thiết.'");
				Else
					Raise
						NStr("en='The action has not been performed, as the composition of additional attribute"
"has been changed by another user."
"The new line-up of additional details has been read."
""
"Repeat if required.';ru='Действие не выполнено, так как состав дополнительных реквизитов"
"был изменен другим пользователем."
"Новый состав дополнительных реквизитов прочитан."
""
"Повторите действие, если требуется.';vi='Chưa thực hiện thao tác, bởi vì thành phần của mục tin bổ sung"
"đã bị thay đổi bởi người sử dụng khác."
"Đã đọc thành phần mục tin bổ sung mới."
""
"Hãy lặp lại thao tác, nếu cần thiết.'");
				EndIf;
			EndIf;
			
			TabularSection = CurrentSetObject[?(ThisIsSetOfAdditionalInformation,
				"AdditionalInformation", "AdditionalAttributes")];
			
			If Command = "AddCommonProperty" Then
				FoundString = TabularSection.Find(Parameter, "Property");
				
				If FoundString = Undefined Then
					NewRow = TabularSection.Add();
					NewRow.Property = Parameter;
					CurrentSetObject.Write();
					
				ElsIf FoundString.DeletionMark Then
					FoundString.DeletionMark = False;
					CurrentSetObject.Write();
				EndIf;
			Else
				Row = Properties.FindByID(Items.Properties.CurrentRow);
				
				If Row <> Undefined Then
					IndexOf = Row.LineNumber-1;
					
					If Command = "MoveUp" Then
						IndexOfTopRows = Properties.IndexOf(Row)-1;
						If IndexOfTopRows >= 0 Then
							Shift = Properties[IndexOfTopRows].LineNumber - Row.LineNumber;
							TabularSection.Move(IndexOf, Shift);
						EndIf;
						CurrentSetObject.Write();
						
					ElsIf Command = "MoveDown" Then
						IndexOfBottomRows = Properties.IndexOf(Row)+1;
						If IndexOfBottomRows < Properties.Count() Then
							Shift = Properties[IndexOfBottomRows].LineNumber - Row.LineNumber;
							TabularSection.Move(IndexOf, Shift);
						EndIf;
						CurrentSetObject.Write();
						
					ElsIf Command = "ChangeDeletionMark" Then
						Row = Properties.FindByID(Items.Properties.CurrentRow);
						
						If Row.Common Then
							TabularSection.Delete(IndexOf);
							CurrentSetObject.Write();
							Properties.Delete(Row);
							If TabularSection.Count() > IndexOf Then
								Items.Properties.CurrentRow = Properties[IndexOf].GetID();
							ElsIf TabularSection.Count() > 0 Then
								Items.Properties.CurrentRow = Properties[Properties.Count()-1].GetID();
							EndIf;
						Else
							TabularSection[IndexOf].DeletionMark = Not TabularSection[IndexOf].DeletionMark;
							CurrentSetObject.Write();
							
							ChangeDeletionMarkAndValuesOwner(
								TabularSection[IndexOf].Property,
								TabularSection[IndexOf].DeletionMark);
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	Except
		UnlockDataForEdit(CurrentSet);
		Raise;
	EndTry;
	
	OnChangeOfCurrentSetAtServer();
	
EndProcedure

&AtServer
Procedure ChangeDeletionMarkAndValuesOwner(CurrentProperty, DeletionMarkProperties)
	
	OldOwnerValues = CurrentProperty;
	
	NewCheckValues   = Undefined;
	NewOwnerValues  = Undefined;
	
	PropertyObject = CurrentProperty.GetObject();
	
	If DeletionMarkProperties = Undefined Then
		DeletionMarkProperties = Not PropertyObject.DeletionMark;
	EndIf;
	
	If DeletionMarkProperties Then
		// При пометке уникального свойства:
		// - пометить свойство,
		// - если есть созданные по образцу не помеченные на удаление
		//   тогда установить нового владельца значений,
		//   и всем свойствам указать новый образец,
		//   иначе пометить на удаление все значения.
		PropertyObject.DeletionMark = True;
		
		If Not ValueIsFilled(PropertyObject.AdditionalValuesOwner) Then
			Query = New Query;
			Query.SetParameter("Property", PropertyObject.Ref);
			Query.Text =
			"SELECT
			|	Properties.Ref,
			|	Properties.DeletionMark
			|FROM
			|	ChartOfCharacteristicTypes.AdditionalAttributesAndInformation AS Properties
			|WHERE
			|	Properties.AdditionalValuesOwner = &Property";
			Unloading = Query.Execute().Unload();
			FoundString = Unloading.Find(False, "DeletionMark");
			If FoundString <> Undefined Then
				NewOwnerValues  = FoundString.Ref;
				PropertyObject.AdditionalValuesOwner = NewOwnerValues;
				For Each Row In Unloading Do
					CurrentObject = Row.Ref.GetObject();
					If CurrentObject.Ref = NewOwnerValues Then
						CurrentObject.AdditionalValuesOwner = Undefined;
					Else
						CurrentObject.AdditionalValuesOwner = NewOwnerValues;
					EndIf;
					CurrentObject.Write();
				EndDo;
			Else
				NewCheckValues = True;
			EndIf;
		EndIf;
		PropertyObject.Write();
	Else
		If PropertyObject.DeletionMark Then
			PropertyObject.DeletionMark = False;
			PropertyObject.Write();
		EndIf;
		// При снятии пометки с уникального свойства:
		// - снять пометку со свойства,
		// - если свойство создано по образцу
		//   тогда если образец помечен на удаление
		//     тогда установить нового владельца значений (текущего)
		//     для всех свойств и снять пометку удаления со значений
		//   иначе снять пометку удаления со значений.
		If Not ValueIsFilled(PropertyObject.AdditionalValuesOwner) Then
			NewCheckValues = False;
			
		ElsIf CommonUse.ObjectAttributeValue(
		            PropertyObject.AdditionalValuesOwner, "DeletionMark") Then
			
			Query = New Query;
			Query.SetParameter("Property", PropertyObject.AdditionalValuesOwner);
			Query.Text =
			"SELECT
			|	Properties.Ref AS Ref
			|FROM
			|	ChartOfCharacteristicTypes.AdditionalAttributesAndInformation AS Properties
			|WHERE
			|	Properties.AdditionalValuesOwner = &Property";
			Array = Query.Execute().Unload().UnloadColumn("Ref");
			Array.Add(PropertyObject.AdditionalValuesOwner);
			NewOwnerValues = PropertyObject.Ref;
			For Each CurrentRef In Array Do
				If CurrentRef = NewOwnerValues Then
					Continue;
				EndIf;
				CurrentObject = CurrentRef.GetObject();
				CurrentObject.AdditionalValuesOwner = NewOwnerValues;
				CurrentObject.Write();
			EndDo;
			OldOwnerValues = PropertyObject.AdditionalValuesOwner;
			PropertyObject.AdditionalValuesOwner = Undefined;
			PropertyObject.Write();
			NewCheckValues = False;
		EndIf;
	EndIf;
	
	If NewCheckValues  = Undefined
	   And NewOwnerValues = Undefined Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Owner", OldOwnerValues);
	Query.Text =
	"SELECT
	|	ObjectsPropertiesValues.Ref AS Ref,
	|	ObjectsPropertiesValues.DeletionMark AS DeletionMark
	|FROM
	|	Catalog.ObjectsPropertiesValues AS ObjectsPropertiesValues
	|WHERE
	|	ObjectsPropertiesValues.Owner = &Owner
	|
	|UNION ALL
	|
	|SELECT
	|	ObjectsPropertiesValuesHierarchy.Ref,
	|	ObjectsPropertiesValuesHierarchy.DeletionMark
	|FROM
	|	Catalog.ObjectsPropertiesValuesHierarchy AS ObjectsPropertiesValuesHierarchy
	|WHERE
	|	ObjectsPropertiesValuesHierarchy.Owner = &Owner";
	
	Unloading = Query.Execute().Unload();
	
	If NewOwnerValues <> Undefined Then
		For Each Row In Unloading Do
			CurrentObject = Row.Ref.GetObject();
			
			If CurrentObject.Owner <> NewOwnerValues Then
				CurrentObject.Owner = NewOwnerValues;
			EndIf;
			
			If CurrentObject.Modified() Then
				CurrentObject.DataExchange.Load = True;
				CurrentObject.Write();
			EndIf;
		EndDo;
	EndIf;
	
	If NewCheckValues <> Undefined Then
		For Each Row In Unloading Do
			CurrentObject = Row.Ref.GetObject();
			
			If CurrentObject.DeletionMark <> NewCheckValues Then
				CurrentObject.DeletionMark = NewCheckValues;
			EndIf;
			
			If CurrentObject.Modified() Then
				CurrentObject.Write();
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion
