
#Region Variables

&AtClient
Var ContinuationProcessorOnWriteError, CancelOnWrite;

#EndRegion

#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	//InfobaseUpdate.ПроверитьОбъектОбработан(Object, ThisObject);
	
	CreatePassedParametersStructure();
	
	If PassedFormParameters.SelectionOfCommonProperty
		Or PassedFormParameters.OwnersSelectionOfAdditionalValues
		Or PassedFormParameters.CopyWithQuestion Then
		ThisObject.WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
		WizardMode               = True;
		If PassedFormParameters.CopyWithQuestion Then
			Items.WIzardCardPages.CurrentPage = Items.ActionChoice;
			FillActionListOnAttributeAppend();
		Else
			FillSelectionPage();
		EndIf;
		RefreshContentOfFormItems();
		
		If CommonUse.ThisIsWebClient() Then
			Items.AttributeCard.Visible = False;
		EndIf;
	Else
		FillAttributeOrInformationCard();
		// Обработчик подсистемы запрета редактирования реквизитов объектов.
		ObjectsAttributesEditProhibition.LockAttributes(ThisObject);
	EndIf;
	
	If Not CommonUse.SubsystemExists("StandardSubsystems.SearchAndDeleteDuplicates") Then
		Items.FormDuplicateObjectsDetection.Visible = False;
	EndIf;
	
	Items.MultilineGroup.Representation          = UsualGroupRepresentation.NormalSeparation;
	If Not PropertiesManagementService.ValueTypeContainsPropertiesValues(Object.ValueType) Then
		Items.PropertiesAndDependenciesGroup.Representation = UsualGroupRepresentation.NormalSeparation;
		Items.OtherAttributes.Representation         = UsualGroupRepresentation.NormalSeparation;
	EndIf;
	
	If CommonUse.IsMobileClient() Then
		Items.PropertiesSets.InitialTreeView = InitialTreeView.ExpandAllLevels;
		Items.GroupAdditionalInformation.Representation = UsualGroupRepresentation.NormalSeparation;
		Items.Close.Visible = False;
		Items.GroupAttributeDescription.ItemsAndTitlesAlign = ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
		Items.AttributeValueType.ItemsAndTitlesAlign        = ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
	EndIf;
	
	CurrentTitle = Object.Title;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	
	If TypeOf(SelectedValue) = Type("ChartOfCharacteristicTypesRef.AdditionalAttributesAndInformation") Then
		Close();
		
		// Открытие формы свойства.
		FormParameters = New Structure;
		FormParameters.Insert("Key", SelectedValue);
		FormParameters.Insert("CurrentSetOfProperties", CurrentSetOfProperties);
		
		OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInformation.ObjectForm",
			FormParameters, FormOwner);
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If Not WriteParameters.Property("DescriptionChangeConfirmed") Then
		If ValueIsFilled(CurrentTitle) And CurrentTitle <> Object.Title Then
			QuestionText = NStr("en=""The name has been changed. You'll need to re-set up your display"
"additional details in lists and reports, as well as the use of"
"in the selections."";ru='Наименование было изменено. Потребуется заново настроить отображение"
"дополнительного реквизита в списках и отчетах, а также использование"
"в отборах.';vi='Đã thay đổi tên gọi. Cần tùy chỉnh lại việc hiển thị "
"mục tin bổ sung trong danh sách và báo cáo,"
"cũng như sử dụng"
"trong bộ lọc.'");
			QuestionText = StrReplace(QuestionText, Chars.LF, " ");
			
			Buttons = New ValueList;
			Buttons.Add("ContinueWrite",            NStr("en='Rename';ru='Переименовать';vi='Đổi tên'"));
			Buttons.Add("ReturnDescription", NStr("en='Cancel';ru='Отмена';vi='Hủy bỏ'"));
			
			ShowQueryBox(
				New NotifyDescription("AfterAnswerToQuestionAboutDescriptionChange", ThisObject, WriteParameters),
				QuestionText, Buttons, , "ReturnDescription");
			
			CancelOnWrite = True;
			Cancel = True;
			Return;
		EndIf;
	EndIf;
	
	If Not WriteParameters.Property("WhenNameIsAlreadyUsed") Then
	
		// Filling the name according
		// to set of properties, and check if there is a property with the same name.
		QuestionText = NameIsAlreadyUsed(
			Object.Title, Object.Ref, CurrentSetOfProperties, Object.Description, Object.Presentations);
		
		If ValueIsFilled(QuestionText) Then
			Buttons = New ValueList;
			Buttons.Add("ContinueWrite",            NStr("en='Continue writing';ru='Продолжить запись';vi='Tiếp tục ghi'"));
			Buttons.Add("BackToEnteringNames", NStr("en='Return to name input';ru='Вернуться к вводу наименования';vi='Quay lại để nhập tên gọi'"));
			
			ShowQueryBox(
				New NotifyDescription("AfterAnswerToAQuestionWhenNameIsAlreadyUsed", ThisObject, WriteParameters),
				QuestionText, Buttons, , "BackToEnteringNames");
			
			CancelOnWrite = True;
			Cancel = True;
			Return;
		EndIf;
	EndIf;
	
	If Not WriteParameters.Property("WhenNameAlreadyUsed")
		And ValueIsFilled(Object.Name) Then
		// Заполнение наименования по набору свойств
		// и проверка есть ли свойство с тем же наименованием.
		QuestionText = NameAlreadyUsed(
			Object.Name, Object.Ref, Object.Description);
		
		If ValueIsFilled(QuestionText) Then
			Buttons = New ValueList;
			Buttons.Add("ContinueWrite",            NStr("en='Continue';ru='Продолжить';vi='Tiếp tục'"));
			Buttons.Add("BackToNameInput", NStr("en='Cancel';ru='Отмена';vi='Hủy bỏ'"));
			
			ShowQueryBox(
				New NotifyDescription("AfterAnswerToQuestionWhenNameAlreadyUsed", ThisObject, WriteParameters),
				QuestionText, Buttons, , "ContinueWrite");
			
			CancelOnWrite = True;
			Cancel = True;
			Return;
		EndIf;
	EndIf;
	
	If WriteParameters.Property("ContinuationProcessor") Then
		ContinuationProcessorOnWriteError = WriteParameters.ContinuationProcessor;
		AttachIdleHandler("AfterErrorRecord", 0.1, True);
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If PropertiesManagementService.ValueTypeContainsPropertiesValues(Object.ValueType) Then
		CurrentObject.AdditionalValuesAreUsed = True;
	Else
		CurrentObject.AdditionalValuesAreUsed = False;
		CurrentObject.ValueFormHeader = "";
		CurrentObject.ValueChoiceFormHeader = "";
	EndIf;
	
	If Object.ThisIsAdditionalInformation
	 OR Not (    Object.ValueType.ContainsType(Type("Number" ))
	         OR Object.ValueType.ContainsType(Type("Date"  ))
	         OR Object.ValueType.ContainsType(Type("Boolean")) )Then
		
		CurrentObject.FormatProperties = "";
	EndIf;
	
	CurrentObject.MultilineTextBox = 0;
	
	If Not Object.ThisIsAdditionalInformation
	   AND Object.ValueType.Types().Count() = 1
	   AND Object.ValueType.ContainsType(Type("String")) Then
		
		If AttributePresentation = "MultilineTextBox" Then
			CurrentObject.MultilineTextBox   = MultilineTextBoxNumber;
			CurrentObject.DisplayAsHyperlink = False;
		EndIf;
	EndIf;
	
	// Формирование имени дополнительного реквизита (сведения).
	If Not ValueIsFilled(CurrentObject.Name)
		Or WriteParameters.Property("WhenNameAlreadyUsed") Then
		CurrentObject.Name = "";
		ObjectHeader = CurrentObject.Title;
		PropertiesManagementService.DeleteInvalidCharacters(ObjectHeader);
		ObjectHeaderParts = StrSplit(ObjectHeader, " ", False);
		For Each HeaderPart In ObjectHeaderParts Do
			CurrentObject.Name = CurrentObject.Name + Upper(Left(HeaderPart, 1)) + Mid(HeaderPart, 2);
		EndDo;
		
		UID = New UUID();
		StringAtID = StrReplace(String(UID), "-", "");
		CurrentObject.Name = CurrentObject.Name + "_" + StringAtID;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If ValueIsFilled(CurrentSetOfProperties) Then
		
		Block = New DataLock;
		LockItem = Block.Add("Catalog.AdditionalAttributesAndInformationSets");
		LockItem.SetValue("Ref", CurrentSetOfProperties);
		Block.Lock();
		LockDataForEdit(CurrentSetOfProperties);
		
		PropertiesSetObject = CurrentSetOfProperties.GetObject();
		If CurrentObject.ThisIsAdditionalInformation Then
			TabularSection = PropertiesSetObject.AdditionalInformation;
		Else
			TabularSection = PropertiesSetObject.AdditionalAttributes;
		EndIf;
		FoundString = TabularSection.Find(CurrentObject.Ref, "Property");
		If FoundString = Undefined Then
			NewRow = TabularSection.Add();
			NewRow.Property = CurrentObject.Ref;
			PropertiesSetObject.Write();
			CurrentObject.AdditionalProperties.Insert("SetChange", CurrentSetOfProperties);
		EndIf;
		
	EndIf;
	
	If WriteParameters.Property("ClearInputWeightsCoefficients") Then
		ClearInputWeightsCoefficients();
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	If AttributeAddMode = "CreateByCopying" Then
		SaveAdditionalAttributeValuesOnCopy(CurrentObject);
	EndIf;
	
	// Subsystem handler of the objects attributes editing prohibition.
	ObjectsAttributesEditProhibition.LockAttributes(ThisObject);
	
	RefreshContentOfFormItems();
	
	If CurrentObject.AdditionalProperties.Property("SetChange") Then
		WriteParameters.Insert("SetChange", CurrentObject.AdditionalProperties.SetChange);
	EndIf;
	
	CurrentTitle = Object.Title;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Writing_AdditionalAttributesAndInformation",
		New Structure("Ref", Object.Ref), Object.Ref);
	
	If WriteParameters.Property("SetChange") Then
		
		Notify("Writing_AdditionalAttributesAndInformationSets",
			New Structure("Ref", WriteParameters.SetChange), WriteParameters.SetChange);
	EndIf;
	
	If WriteParameters.Property("ContinuationProcessor") Then
		ContinuationProcessorOnWriteError = Undefined;
		DetachIdleHandler("AfterErrorRecord");
		ExecuteNotifyProcessing(
			New NotifyDescription(WriteParameters.ContinuationProcessor.ProcedureName,
				ThisObject, WriteParameters.ContinuationProcessor.Parameters),
			False);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	If WizardMode Then
		SetWizardSettings();
	EndIf;
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Src)
	If EventName = "Properties_AttributeDependencySet" Then
		Modified = True;
		ValueAdded = False;
		For Each DependencyCondition In AttributeDependencyConditions Do
			Value = Undefined;
			If Parameter.Property(DependencyCondition.Presentation, Value) Then
				ValueToStorage = PutToTempStorage(Value, UUID);
				DependencyCondition.Value = ValueToStorage;
				ValueAdded = True;
			EndIf;
		EndDo;
		If Not ValueAdded Then
			For Each PassedParameter In Parameter Do
				ValueToStorage = PutToTempStorage(PassedParameter.Value, UUID);
				AttributeDependencyConditions.Add(ValueToStorage, PassedParameter.Key);
			EndDo;
		EndIf;
		
		AdditionalAttributesDependencyCondition();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
EndProcedure

#EndRegion

#Region HeaderFormItemsEventsHandlers

&AtClient
Procedure ThisIsAdditionalInformationOnChange(Item)
	
	Object.ThisIsAdditionalInformation = ThisIsAdditionalInformation;
	
	RefreshContentOfFormItems();
	
EndProcedure

&AtClient
Procedure ClarificationOfValuesListCommentClick(Item)
	
	ContinuationHandler = New NotifyDescription("ValuesListSpecificationCommentClickEnd", ThisObject);
	WriteObject("TransitionToListOfValues", ContinuationHandler);
	
EndProcedure

&AtClient
Procedure SetsSpecificationsCommentClick(Item)
	
	ContinuationHandler = New NotifyDescription("SetsSpecificationCommentClickContinue", ThisObject);
	WriteObject("TransitionToListOfValues", ContinuationHandler);
	
EndProcedure

&AtClient
Procedure ValueTypeOnChange(Item)
	
	WarningText = "";
	RefreshContentOfFormItems(WarningText);
	
	If ValueIsFilled(WarningText) Then
		ShowMessageBox(, WarningText);
	EndIf;
	
EndProcedure

&AtClient
Procedure AdditionalValuesWithWeightOnChange(Item)
	
	If ValueIsFilled(Object.Ref)
	   AND Not Object.AdditionalValuesWithWeight Then
		
		QuestionText =
			NStr("en='Clear the entered weight coefficients? Data will be written.';ru='Очистить введенные весовые коэффициенты? Данные будут записаны.';vi='Xóa  bỏ hệ số cân đã nhập? Dữ liệu sẽ được ghi lại.'");
		
		Buttons = New ValueList;
		Buttons.Add("ClearAndWrite", NStr("en='Clear and write';ru='Очистить и записать';vi='Xóa bỏ và ghi lại'"));
		Buttons.Add("Cancel", NStr("en='Cancel';ru='Отменить';vi='Hủy bỏ'"));
		
		ShowQueryBox(
			New NotifyDescription("AfterWeightCoefficientsClearingConfirmation", ThisObject),
			QuestionText, Buttons, , "ClearAndWrite");
	Else
		QuestionText = NStr("en='The data will be recorded.';ru='Данные будут записаны.';vi='Dữ liệu sẽ được ghi lại.'");
		
		Buttons = New ValueList;
		Buttons.Add("Write", NStr("en='Write';ru='Записать';vi='Ghi lại'"));
		Buttons.Add("Cancel", NStr("en='Cancel';ru='Отмена';vi='Hủy bỏ'"));
		
		ShowQueryBox(
			New NotifyDescription("AfterWeightingFactorEnablingConfirmation", ThisObject),
			QuestionText, Buttons, , "Write");
	EndIf;
	
EndProcedure

&AtClient
Procedure MultilineTextBoxNumberOnChange(Item)
	
	AttributePresentation = "MultilineTextBox";
	
EndProcedure

&AtClient
Procedure CommentOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	CommonUseClient.ShowCommentEditingForm(Item.EditText, ThisObject);
	
EndProcedure

&AtClient
Procedure FillObligatoryOnChange(Item)
	Items.ChooseItemRequiredOption.Enabled = Object.FillObligatory;
EndProcedure

&AtClient
Procedure ChooseAvailabilityOptionClick(Item)
	OpenDependencySettingsForm("Available");
EndProcedure

&AtClient
Procedure SetConditionClick(Item)
	OpenDependencySettingsForm("FillObligatory");
EndProcedure

&AtClient
Procedure ChooseVisibilityOptionClick(Item)
	OpenDependencySettingsForm("Visible");
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	CommonUseClient.ShowCommentEditingForm(Item.EditText, ThisObject);
EndProcedure

&AtClient
Procedure AttributeKindOnChange(Item)
	Items.DisplayAsHyperlink.Enabled    = (AttributePresentation = "SingleLineInputField");
	Items.MultilineTextBoxNumber.Enabled = (AttributePresentation = "MultilineTextBox");
EndProcedure

&AtClient
Procedure Attachable_Open(Item, StandardProcessing)
EndProcedure

#EndRegion

#Region FormTableItemsEventsHandlersPropertiesSets

&AtClient
Procedure PropertiesSetsOnActivateRow(Item)
	AttachIdleHandler("OnChangeOfCurrentSet", 0.1, True)
EndProcedure

&AtClient
Procedure PropertiesSetsBeforeRowChange(Item, Cancel)
	Cancel = True;
EndProcedure

#EndRegion

#Region FormTableItemEventHandlersPropertiesSelection

&AtClient
Procedure PropertiesSelection(Item, SelectedRow, Field, StandardProcessing)
	StandardProcessing = False;
	
	CommandNext(Undefined);
EndProcedure

#EndRegion

#Region ValueFormTableItemsEventsHandlers

&AtClient
Procedure ValuesOnChange(Item)
	
	If Item.CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Object.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues")) Then
		EventName = "Record_ValuesOfObjectProperties";
	Else
		EventName = "Record_ValuesOfObjectPropertiesHierarchy";
	EndIf;
	
	Notify(EventName,
		New Structure("Ref", Item.CurrentData.Ref),
		Item.CurrentData.Ref);
	
EndProcedure

&AtClient
Procedure ValuesBeforeAddRow(Item, Cancel, Copy, Parent, Group)
	
	Cancel = True;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Copy", Copy);
	AdditionalParameters.Insert("Parent", Parent);
	AdditionalParameters.Insert("Group", Group);
	
	ContinuationHandler = New NotifyDescription("ValuesBeforeAddingStartEnd", ThisObject);
	WriteObject("TransitionToListOfValues", ContinuationHandler, AdditionalParameters);
	
EndProcedure

&AtClient
Procedure ValuesBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	If Items.AdditionalValues.ReadOnly Then
		Return;
	EndIf;
	
	ContinuationHandler = New NotifyDescription("ValuesBeforeChangeStartEnd", ThisObject);
	WriteObject("TransitionToListOfValues", ContinuationHandler);
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure CommandNext(Command)
	
#If WebClient Then
	If Not Items.AttributeCard.Visible Then
		Items.AttributeCard.Visible = True;
	EndIf;
#EndIf
	
	If AttributeAddMode = "AddCommonAttributeToSet" Then
		Result = New Structure;
		Result.Insert("CommonProperty", PassedFormParameters.AdditionalValuesOwner);
		If PassedFormParameters.Drag Then
			Result.Insert("Drag", True);
		EndIf;
		ConvertAdditionalAttributeToCommon();
		NotifyChoice(Result);
		Return;
	EndIf;
	
	MainPage = Items.WIzardCardPages;
	PageIndex = MainPage.ChildItems.IndexOf(MainPage.CurrentPage);
	If PageIndex = 0
		And Items.Properties.CurrentData = Undefined Then
		WarningText = NStr("en='The item has not been selected.';ru='Элемент не выбран.';vi='Chưa chọn phần tử nào.'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	If PageIndex = 2 Then
		If Not CheckFilling() Then
			Return;
		EndIf;
		
		If AttributeAddMode = "CreateByCopying" Then
			Items.AttributeValuePages.CurrentPage = Items.AdditionalValues;
		EndIf;
		
		Write();
		If CancelOnWrite <> True Then
			Close();
		EndIf;
		Return;
	EndIf;
	CurrentPage = MainPage.ChildItems.Get(PageIndex + 1);
	SetWizardSettings(CurrentPage);
	
	OnCurrentPageChange("GoForward", MainPage, CurrentPage);
	
EndProcedure

&AtClient
Procedure CommandBack(Command)
	
	MainPage = Items.WIzardCardPages;
	PageIndex = MainPage.ChildItems.IndexOf(MainPage.CurrentPage);
	If PageIndex = 1 Then
		AttributeAddMode = "";
	EndIf;
	CurrentPage = MainPage.ChildItems.Get(PageIndex - 1);
	SetWizardSettings(CurrentPage);
	
	OnCurrentPageChange("Back", MainPage, CurrentPage);
	
EndProcedure

&AtClient
Procedure CloseForm(Command)
	Close();
EndProcedure

&AtClient
Procedure EditValueFormat(Command)
	
	Assistant = New FormatStringWizard(Object.FormatProperties);
	
	Assistant.AvailableTypes = Object.ValueType;
	
	Assistant.Show(
		New NotifyDescription("EditValueFormatEnd", ThisObject));
	
EndProcedure

&AtClient
Procedure SpecificationOfValuesListChange(Command)
	
	ContinuationHandler = New NotifyDescription("ValuesListSpecificationChangeEnd", ThisObject);
	WriteObject("AttributeTypeChange", ContinuationHandler);
	
EndProcedure

&AtClient
Procedure SpecificationsSetsChange(Command)
	
	ContinuationHandler = New NotifyDescription("SetsSpecificationChangeEnd", ThisObject);
	WriteObject("AttributeTypeChange", ContinuationHandler);
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEditing(Command)
	
	BlockedAttributes = ObjectsAttributesEditProhibitionClient.Attributes(ThisObject);
	
	If BlockedAttributes.Count() > 0 Then
		
		FormParameters = New Structure;
		FormParameters.Insert("Ref", Object.Ref);
		FormParameters.Insert("ThisIsAdditionalAttribute", Not Object.ThisIsAdditionalInformation);
		
		Notification = New NotifyDescription("AfterSelectAttributesForUnlock", ThisObject);
		OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInformation.Form.AttributeUnlocking",
			FormParameters, ThisObject,,,, Notification);
	Else
		ObjectsAttributesEditProhibitionClient.ShowMessageBoxAllVisibleAttributesUnlocked();
	EndIf;
	
EndProcedure

&AtClient
Procedure SearchAndDeleteDuplicates(Command)
	SearchAndDeleteDuplicatesModuleClient = CommonUseClient.CommonModule("SearchAndDeleteDuplicatesClient");
	SearchAndDeleteDuplicatesFormName = SearchAndDeleteDuplicatesModuleClient.ИмяФормыОбработкиПоискИУдалениеДублей();
	OpenForm(SearchAndDeleteDuplicatesFormName);
EndProcedure

&AtClient
Procedure Change(Command)
	
	If Items.Properties.CurrentData <> Undefined Then
		// Открытие формы свойства.
		FormParameters = New Structure;
		FormParameters.Insert("Key", Items.Properties.CurrentData.Property);
		FormParameters.Insert("CurrentSetOfProperties", SelectedPropertiesSet);
		
		OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInformation.ObjectForm",
			FormParameters, Items.Properties,,,,, FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowUnusedAttributes(Command)
	NewValue = Not Items.UsedAttributes.Check;
	Items.UsedAttributes.Check = NewValue;
	If NewValue Then
		Items.PropertiesSetsPages.CurrentPage = Items.SharedSetsPage;
	Else
		Items.PropertiesSetsPages.CurrentPage = Items.AllSetsPage;
	EndIf;
	
	RefreshListOfPropertiesOfCurrentSetOf();
	
EndProcedure

&AtClient
Procedure EnableDisableMarkDeletion(Command)
	ContinuationHandler = New NotifyDescription("SetRemoveDeletionMarkContinue", ThisObject);
	WriteObject("MarkForDeletionChange", ContinuationHandler);
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Procedure AdditionalAttributesDependencyCondition()
	
	If AttributeDependencyConditions.Count() = 0 Then
		Return;
	EndIf;
	
	CurrentObject = FormAttributeToValue("Object");
	
	AdditionalAttributeDependencies = CurrentObject.AdditionalAttributeDependencies;
	
	For Each DependencyCondition In AttributeDependencyConditions Do
		RowFilter = New Structure;
		RowFilter.Insert("DependentProperty", DependencyCondition.Presentation);
		RowFilter.Insert("PropertySet", CurrentSetOfProperties);
		RowArray = AdditionalAttributeDependencies.FindRows(RowFilter);
		For Each TabularSectionRow In RowArray Do
			AdditionalAttributeDependencies.Delete(TabularSectionRow);
		EndDo;
		
		ValueFromStorage = GetFromTempStorage(DependencyCondition.Value);
		If ValueFromStorage = Undefined Then
			Continue;
		EndIf;
		For Each NewDependency In ValueFromStorage.Get() Do
			FillPropertyValues(CurrentObject.AdditionalAttributeDependencies.Add(), NewDependency);
		EndDo;
	EndDo;
	
	ValueToFormAttribute(CurrentObject, "Object");
	
	SetHyperlinkTitles();
	
EndProcedure

&AtServer
Procedure FillSelectionPage()
	
	If PassedFormParameters.ThisIsAdditionalInformation <> Undefined Then
		ThisIsAdditionalInformation = PassedFormParameters.ThisIsAdditionalInformation;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TheSets.Ref AS Ref
	|FROM
	|	Catalog.AdditionalAttributesAndInformationSets AS TheSets
	|WHERE
	|	TheSets.Parent = VALUE(Catalog.AdditionalAttributesAndInformationSets.EmptyRef)";
	
	TheSets = Query.Execute().Unload().UnloadColumn("Ref");
	
	AvailableSets = New Array;
	For Each Ref In TheSets Do
		SetPropertyTypes = PropertiesManagementService.SetPropertyTypes(Ref, False);
		
		If ThisIsAdditionalInformation = 1
		   And SetPropertyTypes.AdditionalInformation
		 Or ThisIsAdditionalInformation = 0
		   And SetPropertyTypes.AdditionalAttributes Then
			
			AvailableSets.Add(Ref);
		EndIf;
	EndDo;
	
	CurrentSetParent = CommonUse.ObjectAttributeValue(
		PassedFormParameters.CurrentSetOfProperties, "Parent");
	ExcludedSets = New Array;
	ExcludedSets.Add(PassedFormParameters.CurrentSetOfProperties);
	If ValueIsFilled(CurrentSetParent) Then
		PredefinedSets = PropertiesManagementReUse.PredefinedPropertySets();
		PropertiesSet = PredefinedSets.Get(CurrentSetParent);
		If PropertiesSet = Undefined Then
			PredefinedDataName = CommonUse.ObjectAttributeValue(CurrentSetParent, "PredefinedDataName");
		Else
			PredefinedDataName = PropertiesSet.Name;
		EndIf;
		ReplacedCharacterPosition = StrFind(PredefinedDataName, "_");
		FullObjectName = Left(PredefinedDataName, ReplacedCharacterPosition - 1)
			             + "."
			             + Mid(PredefinedDataName, ReplacedCharacterPosition + 1);
		Manager         = CommonUse.ObjectManagerByFullName(FullObjectName);
		
		If StrStartsWith(FullObjectName, "Document") Then
			NewObject = Manager.CreateDocument();
		Else
			NewObject = Manager.CreateItem();
		EndIf;
		ObjectSets = PropertiesManagementService.GetObjectPropertiesSets(NewObject);
		
		FilterParameters = New Structure;
		FilterParameters.Insert("CommonSet", True);
		FoundStrings = ObjectSets.FindRows(FilterParameters);
		For Each FoundString In FoundStrings Do
			If PassedFormParameters.CurrentSetOfProperties = FoundString.Set Then
				Continue;
			EndIf;
			ExcludedSets.Add(FoundString.Set);
		EndDo;
	EndIf;
	
	If ThisIsAdditionalInformation = 1 Then
		Items.UsedAttributes.Title = NStr("en='Unused additional information';ru='Неиспользуемые дополнительные сведения';vi='Thông tin bổ sung không sử dụng'");
	Else
		Items.UsedAttributes.Title = NStr("en='Unused additional details';ru='Неиспользуемые дополнительные реквизиты';vi='Mục tin bổ sung không sử dụng'");
	EndIf;
	
	CommonUseClientServer.SetDynamicListParameter(
		PropertiesSets, "TheSets", AvailableSets, True);
	
	CommonUseClientServer.SetDynamicListParameter(
		PropertiesSets, "ExcludedSets", ExcludedSets, True);
	
	CommonUseClientServer.SetDynamicListParameter(
		PropertiesSets, "ThisIsAdditionalInformation", (ThisIsAdditionalInformation = 1), True);
	
	CommonUseClientServer.SetDynamicListParameter(
		PropertiesSets, "IsMainLanguage", CurrentLanguage() = Metadata.DefaultLanguage, True);
	
	CommonUseClientServer.SetDynamicListParameter(
		PropertiesSets, "LanguageCode", CurrentLanguage().LanguageCode, True);
	
	CommonUseClientServer.SetDynamicListParameter(
		CommonPropertySets, "ThisIsAdditionalInformation", (ThisIsAdditionalInformation = 1), True);
	
	CommonUseClientServer.SetDynamicListParameter(
		CommonPropertySets, "CommonAdditionalInformation", NStr("en='Unused additional information';ru='Неиспользуемые дополнительные сведения';vi='Thông tin bổ sung không sử dụng'"), True);
	
	CommonUseClientServer.SetDynamicListParameter(
		CommonPropertySets, "CommonAdditionalAttributes", NStr("en='Unused additional details';ru='Неиспользуемые дополнительные реквизиты';vi='Mục tin bổ sung không sử dụng'"), True);
	
	SetListConditionalAppearance(AvailableSets);
	
EndProcedure

&AtServer
Procedure SetListConditionalAppearance(AvailableSetsList)
	
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
	
EndProcedure

&AtServer
Procedure FillAdditionalAttributeValues(ValueOwner)
	
	ValueTree = FormAttributeToValue("ValuesOfAdditionalAttributes");
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	ObjectsPropertiesValues.Ref AS Ref,
		|	ObjectsPropertiesValues.Owner AS Owner,
		|	0 AS PictureCode,
		|	ObjectsPropertiesValues.Weight,
		|	PRESENTATION(ObjectsPropertiesValues.Ref) AS Description
		|FROM
		|	Catalog.ObjectsPropertiesValues AS ObjectsPropertiesValues
		|WHERE
		|	ObjectsPropertiesValues.DeletionMark = FALSE
		|	AND ObjectsPropertiesValues.Owner = &Owner
		|
		|UNION ALL
		|
		|SELECT
		|	ObjectsPropertiesValuesHierarchy.Ref,
		|	ObjectsPropertiesValuesHierarchy.Owner,
		|	0,
		|	ObjectsPropertiesValuesHierarchy.Weight,
		|	PRESENTATION(ObjectsPropertiesValuesHierarchy.Description) AS Description
		|FROM
		|	Catalog.ObjectsPropertiesValuesHierarchy AS ObjectsPropertiesValuesHierarchy
		|WHERE
		|	ObjectsPropertiesValuesHierarchy.DeletionMark = FALSE
		|	AND ObjectsPropertiesValuesHierarchy.Owner = &Owner
		|
		|ORDER BY
		|	Ref HIERARCHY";
	Query.SetParameter("Owner", ValueOwner);
	Result = Query.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy);
	
	ValueTree = Result.Copy();
	ValueToFormAttribute(ValueTree, "ValuesOfAdditionalAttributes");
	
EndProcedure

&AtServer
Procedure ConvertAdditionalAttributeToCommon()
	Return;
	
	SelectedAttribute = PassedFormParameters.AdditionalValuesOwner;
	PropertySet = CommonUse.ObjectAttributeValue(SelectedAttribute, "PropertySet");
	If Not ValueIsFilled(PropertySet) Then
		Return;
	EndIf;
	
	BeginTransaction();
	Try
		Block = New DataLock;
		LockItem = Block.Add("ChartOfCharacteristicTypes.AdditionalAttributesAndInformation");
		LockItem.SetValue("Ref", SelectedAttribute);
		Block.Lock();
		
		SelectedAttributeObject = SelectedAttribute.GetObject();
		SelectedAttributeObject.PropertySet = Catalogs.AdditionalAttributesAndInformationSets.EmptyRef();
		SelectedAttributeObject.Description = SelectedAttributeObject.Title;
		SelectedAttributeObject.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
EndProcedure

&AtServer
Procedure FillAttributeOrInformationCard()
	
	If ValueIsFilled(PassedFormParameters.CopyingValue) Then
		AttributeAddMode = "CreateByCopying";
	EndIf;
	
	CreatingAttributeByCopying = (AttributeAddMode = "CreateByCopying");
	
	CurrentSetOfProperties = PassedFormParameters.CurrentSetOfProperties;
	
	If ValueIsFilled(Object.Ref) Then
		Items.ThisIsAdditionalInformation.Enabled = False;
		ShowUpdateSet = PassedFormParameters.ShowUpdateSet;
	Else
		Object.Available = True;
		Object.Visible  = True;
		
		Object.AdditionalAttributeDependencies.Clear();
		If ValueIsFilled(CurrentSetOfProperties) Then
			Object.PropertySet = CurrentSetOfProperties;
		EndIf;
		
		If CreatingAttributeByCopying Then
			Object.AdditionalValuesOwner = ChartsOfCharacteristicTypes.AdditionalAttributesAndInformation.EmptyRef();
		ElsIf ValueIsFilled(PassedFormParameters.AdditionalValuesOwner) Then
			Object.AdditionalValuesOwner = PassedFormParameters.AdditionalValuesOwner;
		EndIf;
		
		If PassedFormParameters.ThisIsAdditionalInformation <> Undefined Then
			Object.ThisIsAdditionalInformation = PassedFormParameters.ThisIsAdditionalInformation;
			
		ElsIf Not ValueIsFilled(PassedFormParameters.CopyingValue) Then
			Items.ThisIsAdditionalInformation.Visible = True;
		EndIf;
	EndIf;
	
	If Object.Predefined And Not ValueIsFilled(Object.Title) Then
		Object.Title = Object.Description;
	EndIf;
	
	ThisIsAdditionalInformation = ?(Object.ThisIsAdditionalInformation, 1, 0);
	
	If CreatingAttributeByCopying Then
		// Для случаев, когда копирование выполняется из карточки реквизита по команде "Скопировать".
		If Not ValueIsFilled(PassedFormParameters.AdditionalValuesOwner) Then
			PassedFormParameters.AdditionalValuesOwner = PassedFormParameters.CopyingValue;
		EndIf;
		
		PropertiesOfOwner = CommonUse.ObjectAttributesValues(
			PassedFormParameters.AdditionalValuesOwner, "ValueType, AdditionalValuesWithWeight, FormatProperties");
		
		Object.ValueType    = PropertiesOfOwner.ValueType;
		Object.FormatProperties = PropertiesOfOwner.FormatProperties;
		
		OwnerValuesWithWeight                                = PropertiesOfOwner.AdditionalValuesWithWeight;
		Object.AdditionalValuesWithWeight                    = OwnerValuesWithWeight;
		Items.AdditionalAttributeValues.Header        = OwnerValuesWithWeight;
		Items.AdditionalAttributeValuesWeight.Visible = OwnerValuesWithWeight;
		Items.AttributeValuePages.CurrentPage     = Items.ValueTreePage;
		
		FillAdditionalAttributeValues(PassedFormParameters.AdditionalValuesOwner);
	EndIf;
	
	RefreshContentOfFormItems();
	
	If Object.MultilineTextBox > 0 Then
		AttributePresentation = "MultilineTextBox";
		MultilineTextBoxNumber = Object.MultilineTextBox;
	Else
		AttributePresentation = "SingleLineInputField";
	EndIf;
	
	Items.DisplayAsHyperlink.Enabled    = (AttributePresentation = "SingleLineInputField");
	Items.MultilineTextBoxNumber.Enabled = (AttributePresentation = "MultilineTextBox");
	
EndProcedure

&AtClient
Procedure AfterSelectAttributesForUnlock(UnlockableAttributes, Context) Export
	
	If TypeOf(UnlockableAttributes) <> Type("Array") Then
		Return;
	EndIf;
	
	ObjectsAttributesEditProhibitionClient.SetEnabledOfFormItems(ThisObject,
		UnlockableAttributes);
	
	#If WebClient Then
		RefreshDataRepresentation();
	#EndIf
	
EndProcedure

&AtClient
Procedure AfterAnswerToAQuestionWhenNameIsAlreadyUsed(Response, WriteParameters) Export
	
	If Response <> "ContinueWrite" Then
		CurrentItem = Items.Title;
		If WriteParameters.Property("ContinuationProcessor") Then
			ExecuteNotifyProcessing(
				New NotifyDescription(WriteParameters.ContinuationProcessor.ProcedureName,
					ThisObject, WriteParameters.ContinuationProcessor.Parameters),
				True);
		EndIf;
	Else
		WriteParameters.Insert("WhenNameIsAlreadyUsed");
		Write(WriteParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterAnswerToQuestionAboutDescriptionChange(Response, WriteParameters) Export
	
	If Response <> "ContinueWrite" Then
		Object.Title = CurrentTitle;
		If WriteParameters.Property("ContinuationProcessor") Then
			ExecuteNotifyProcessing(
				New NotifyDescription(WriteParameters.ContinuationProcessor.ProcedureName,
					ThisObject, WriteParameters.ContinuationProcessor.Parameters),
				True);
		EndIf;
	Else
		WriteParameters.Insert("DescriptionChangeConfirmed");
		Write(WriteParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterAnswerToQuestionWhenNameAlreadyUsed(Response, WriteParameters) Export
	
	If Response <> "ContinueWrite" Then
		CurrentItem = Items.Title;
		If WriteParameters.Property("ContinuationProcessor") Then
			ExecuteNotifyProcessing(
				New NotifyDescription(WriteParameters.ContinuationProcessor.ProcedureName,
					ThisObject, WriteParameters.ContinuationProcessor.Parameters),
				True);
		EndIf;
	Else
		WriteParameters.Insert("WhenNameAlreadyUsed");
		Write(WriteParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWeightCoefficientsClearingConfirmation(Response, Context) Export
	
	If Response <> "ClearAndWrite" Then
		Object.AdditionalValuesWithWeight = Not Object.AdditionalValuesWithWeight;
		Return;
	EndIf;
	
	WriteParameters = New Structure;
	WriteParameters.Insert("ClearInputWeightsCoefficients");
	
	ContinuationHandler = New NotifyDescription("AdditionalValuesWithWeightOnChangeEnd", ThisObject);
	WriteObject("UseWeightChange", ContinuationHandler,, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWeightingFactorEnablingConfirmation(Response, Context) Export
	
	If Response <> "Write" Then
		Object.AdditionalValuesWithWeight = Not Object.AdditionalValuesWithWeight;
		Return;
	EndIf;
	
	ContinuationHandler = New NotifyDescription("AdditionalValuesWithWeightOnChangeEnd", ThisObject);
	WriteObject("UseWeightChange", ContinuationHandler);
	
EndProcedure

&AtClient
Procedure AdditionalValuesWithWeightOnChangeEnd(Cancel, Context) Export
	
	If Cancel Then
		Object.AdditionalValuesWithWeight = Not Object.AdditionalValuesWithWeight;
		Return;
	EndIf;
	
	If ValueIsFilled(Object.Ref) Then
		Notify(
			"Update_ValueIsCharacterizedByWeighting",
			Object.AdditionalValuesWithWeight,
			Object.Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure ValuesListSpecificationCommentClickEnd(Cancel, Context) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	Close();
	
	FormParameters = New Structure;
	FormParameters.Insert("ShowUpdateSet", True);
	FormParameters.Insert("Key", Object.AdditionalValuesOwner);
	FormParameters.Insert("CurrentSetOfProperties", CurrentSetOfProperties);
	
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInformation.ObjectForm",
		FormParameters, FormOwner);
	
EndProcedure

&AtClient
Procedure SetsSpecificationCommentClickContinue(Cancel, Context) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	If ListOfSets.Count() > 1 Then
		ShowChooseFromList(
			New NotifyDescription("SetsSpecificationCommentClickEnd", ThisObject),
			ListOfSets, Items.SetsSpecificationsComment);
	Else
		SetsSpecificationCommentClickEnd(Undefined, ListOfSets[0].Value);
	EndIf;
	
EndProcedure

&AtClient
Procedure SetsSpecificationCommentClickEnd(SelectedItem, SelectedSet) Export
	
	If SelectedItem <> Undefined Then
		SelectedSet = SelectedItem.Value;
	EndIf;
	
	If Not ValueIsFilled(CurrentSetOfProperties) Then
		Return;
	EndIf;
	
	If SelectedSet <> Undefined Then
		ChoiceValue = New Structure;
		ChoiceValue.Insert("Set", SelectedSet);
		ChoiceValue.Insert("Property", Object.Ref);
		ChoiceValue.Insert("ThisIsAdditionalInformation", Object.ThisIsAdditionalInformation);
		NotifyChoice(ChoiceValue);
	EndIf;
	
EndProcedure

&AtClient
Procedure ValuesBeforeAddingStartEnd(Cancel, ProcessingParameters) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	If AttributeAddMode = "CreateByCopying" Then
		Items.AttributeValuePages.CurrentPage = Items.AdditionalValues;
	EndIf;
	
	If Object.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues")) Then
		TableValuesName = "Catalog.ObjectsPropertiesValues";
	Else
		TableValuesName = "Catalog.ObjectsPropertiesValuesHierarchy";
	EndIf;
	
	FillingValues = New Structure;
	FillingValues.Insert("Parent", ProcessingParameters.Parent);
	FillingValues.Insert("Owner", Object.Ref);
	
	FormParameters = New Structure;
	FormParameters.Insert("HideOwner", True);
	FormParameters.Insert("FillingValues", FillingValues);
	
	If ProcessingParameters.Group Then
		FormParameters.Insert("IsFolder", True);
		
		OpenForm(TableValuesName + ".GroupForm", FormParameters, Items.Values);
	Else
		FormParameters.Insert("ShowWeight", Object.AdditionalValuesWithWeight);
		
		If ProcessingParameters.Copy Then
			FormParameters.Insert("CopyingValue", Items.Values.CurrentRow);
		EndIf;
		
		OpenForm(TableValuesName + ".ObjectForm", FormParameters, Items.Values);
	EndIf;
	
EndProcedure

&AtClient
Procedure ValuesBeforeChangeStartEnd(Cancel, Context) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	If Object.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues")) Then
		TableValuesName = "Catalog.ObjectsPropertiesValues";
	Else
		TableValuesName = "Catalog.ObjectsPropertiesValuesHierarchy";
	EndIf;
	
	If Items.Values.CurrentRow <> Undefined Then
		// Открытие формы значения или группы значений.
		FormParameters = New Structure;
		FormParameters.Insert("HideOwner", True);
		FormParameters.Insert("ShowWeight", Object.AdditionalValuesWithWeight);
		FormParameters.Insert("Key", Items.Values.CurrentRow);
		
		OpenForm(TableValuesName + ".ObjectForm", FormParameters, Items.Values);
	EndIf;
	
EndProcedure

&AtClient
Procedure ValuesListSpecificationChangeEnd(Cancel, Context) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("CurrentSetOfProperties", CurrentSetOfProperties);
	FormParameters.Insert("Property", Object.Ref);
	FormParameters.Insert("AdditionalValuesOwner", Object.AdditionalValuesOwner);
	FormParameters.Insert("ThisIsAdditionalInformation", Object.ThisIsAdditionalInformation);
	
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInformation.Form.PropertySettingChange",
		FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure SetsSpecificationChangeEnd(Cancel, Context) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("CurrentSetOfProperties", CurrentSetOfProperties);
	FormParameters.Insert("Property", Object.Ref);
	FormParameters.Insert("AdditionalValuesOwner", Object.AdditionalValuesOwner);
	FormParameters.Insert("ThisIsAdditionalInformation", Object.ThisIsAdditionalInformation);
	
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInformation.Form.PropertySettingChange",
		FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure WriteObject(VariantOfTextOfQuestion, ContinuationHandler, AdditionalParameters = Undefined, WriteParameters = Undefined)
	
	If WriteParameters = Undefined Then
		WriteParameters = New Structure;
	EndIf;
	
	If VariantOfTextOfQuestion = "MarkForDeletionChange" Then
		If Modified Then
			If Object.DeletionMark Then
				QuestionText = NStr("en=""To remove the removal mark, you need to write down the changes you've made. Write down the data?"";ru='Для снятия пометки удаления необходимо записать внесенные изменения. Записать данные?';vi='Để bỏ dấu xóa, cần ghi lại những thay đổi đã thực hiện. Ghi lại dữ liệu?'");
			Else
				QuestionText = NStr("en=""To set the removal notes, you need to write down the changes you've made. Write down the data?"";ru='Для установки пометки удаления необходимо записать внесенные изменения. Записать данные?';vi='Để đặt dấu xóa, cần ghi lại những thay đổi đã thực hiện. Ghi lại dữ liệu?'");
			EndIf;
		Else
			QuestionText = NStr("en='Mark ""%1"" to delete?';ru='Пометить ""%1"" на удаление?';vi='Đặt dấu xóa ""%1""?'");
			QuestionText = StringFunctionsClientServer.SubstituteParametersInString(QuestionText, Object.Description);
		EndIf;
		
		ShowQueryBox(
			New NotifyDescription(
				ContinuationHandler.ProcedureName, ContinuationHandler.Module, WriteParameters),
			QuestionText, QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
		Return;
	EndIf;
	
	If ValueIsFilled(Object.Ref) And Not Modified Then
		ExecuteNotifyProcessing(New NotifyDescription(
			ContinuationHandler.ProcedureName, ContinuationHandler.Module, AdditionalParameters), False);
		Return;
	EndIf;
	
	ContinuationProcessor = New Structure;
	ContinuationProcessor.Insert("ProcedureName", ContinuationHandler.ProcedureName);
	ContinuationProcessor.Insert("Parameters", AdditionalParameters);
	WriteParameters.Insert("ContinuationProcessor", ContinuationProcessor);
	
	If ValueIsFilled(Object.Ref) Then
		WriteObjectContinuation("Write", WriteParameters);
		Return;
	EndIf;
	
	If VariantOfTextOfQuestion = "TransitionToListOfValues" Then
		QuestionText = NStr("en='The data will be recorded before moving to the list of values.';ru='Перед переходом к списку значений данные будут записаны.';vi='Trước khi chuyển đến danh sách giá trị, dữ liệu sẽ được ghi lại.'");
	Else
		QuestionText = NStr("en='The data will be recorded.';ru='Данные будут записаны.';vi='Dữ liệu sẽ được ghi lại.'")
	EndIf;
	
	Buttons = New ValueList;
	Buttons.Add("Write", NStr("en='Write';ru='Записать';vi='Ghi lại'"));
	Buttons.Add("Cancel", NStr("en='Cancel';ru='Отмена';vi='Hủy bỏ'"));
	
	ShowQueryBox(
		New NotifyDescription(
			"WriteObjectContinuation", ThisObject, WriteParameters),
		QuestionText, Buttons, , "Write");
	
EndProcedure

&AtClient
Procedure SetRemoveDeletionMarkContinue(Response, WriteParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		Object.DeletionMark = Not Object.DeletionMark;
	EndIf;
	WriteObjectContinuation(Response, WriteParameters);
	
EndProcedure


&AtClient
Procedure WriteObjectContinuation(Response, WriteParameters) Export
	
	If Response = "Write"
		Or Response = DialogReturnCode.Yes Then
		Write(WriteParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterErrorRecord()
	
	If ContinuationProcessorOnWriteError <> Undefined Then
		ExecuteNotifyProcessing(
			New NotifyDescription(ContinuationProcessorOnWriteError.ProcedureName,
				ThisObject, ContinuationProcessorOnWriteError.Parameters),
			True);
	EndIf;
	
EndProcedure

&AtClient
Procedure EditValueFormatEnd(Text, Context) Export
	
	If Text <> Undefined Then
		Object.FormatProperties = Text;
		SetTitleOfFormatButton(ThisObject);
		
		WarningText = NStr("en='The following format settings do not automatically apply in most places:';ru='Следующие настройки формата автоматически не применяются в большинстве мест:';vi='Các tùy chỉnh định dạng sau không được tự động áp dụng ở hầu hết các nơi:'");
		Array = StrSplit(Text, ";", False);
		
		For Each SubString In Array Do
			If StrFind(SubString, "DP=") > 0 Or StrFind(SubString, "DE=") > 0 Then
				WarningText = WarningText + Chars.LF
					+ " - " + NStr("en='View of an empty date';ru='представление пустой даты';vi='trình bày ngày trống'");
				Continue;
			EndIf;
			If StrFind(SubString, "NZ=") > 0 Or StrFind(SubString, "NZ=") > 0 Then
				WarningText = WarningText + Chars.LF
					+ " - " + NStr("en='View of an empty number';ru='представление пустого числа';vi='trình bày số trống'");
				Continue;
			EndIf;
			If StrFind(SubString, "DF=") > 0 Or StrFind(SubString, "DF=") > 0 Then
				If StrFind(SubString, "ddd") > 0 Or StrFind(SubString, "ddd") > 0 Then
					WarningText = WarningText + Chars.LF
						+ " - " + NStr("en='multiple name of the day of the week';ru='кратное название дня недели';vi='tên gọi ngắn gọn của ngày'");
				EndIf;
				If StrFind(SubString, "dddd") > 0 Or StrFind(SubString, "dddd") > 0 Then
					WarningText = WarningText + Chars.LF
						+ " - " + NStr("en='full name of the day of the week';ru='полное название дня недели';vi='tên gọi đầy đủ của ngày trong tuần'");
				EndIf;
				If StrFind(SubString, "MMM") > 0 Or StrFind(SubString, "MMM") > 0 Then
					WarningText = WarningText + Chars.LF
						+ " - " + NStr("en=""multiple of the month's name"";ru='кратное название месяца';vi='tên gọi ngắn gọn của tháng'");
				EndIf;
				If StrFind(SubString, "MMMM") > 0 Or StrFind(SubString, "MMMM") > 0 Then
					WarningText = WarningText + Chars.LF
						+ " - " + NStr("en='Full name of the month';ru='полное название месяца';vi='tên gọi đầy đủ của tháng'");
				EndIf;
			EndIf;
			If StrFind(SubString, "DLF=") > 0 Or StrFind(SubString, "DLF=") > 0 Then
				If StrFind(SubString, "dd") > 0 Or StrFind(SubString, "DD") > 0 Then
					WarningText = WarningText + Chars.LF
						+ " - " + NStr("en='long date (month of writing)';ru='длинная дата (месяц прописью)';vi='ngày dài (bằng chữ bằng lời)'");
				EndIf;
			EndIf;
		EndDo;
		
		If StrLineCount(WarningText) > 1 Then
			ShowMessageBox(, WarningText);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SetWizardSettings(CurrentPage = Undefined)
	
	If CurrentPage = Undefined Then
		CurrentPage = Items.WIzardCardPages.CurrentPage;
	EndIf;
	
	ListHeaderPattern        = NStr("en='Select %1 to be included in the ""%2"" set';ru='Выберите %1 для включения в набор ""%2""';vi='Hãy chọn %1 để đưa vào tập hợp ""%2""'");
	SwitchHeaderPattern = NStr("en='Choose to add an additional %1 ""%2"" to the ""%3"" set';ru='Выберите вариант добавления дополнительного %1 ""%2"" в набор ""%3""';vi='Hãy chọn phương án thêm %1 ""%2"" trong tập hợp ""%3""'");
	
	If CurrentPage = Items.AttributeChoice Then
		
		If PassedFormParameters.ThisIsAdditionalInformation Then
			Title = NStr("en='Add more information';ru='Добавление дополнительного сведения';vi='Thêm thông tin bổ sung'");
		Else
			Title = NStr("en='Add additional attribute';ru='Добавление дополнительного реквизита';vi='Thêm mục tin bổ sung'");
		EndIf;
		
		Items.CommandBarLeft.Enabled = False;
		Items.CommandNext.Title = NStr("en='Next >';ru='Далее >';vi='Tiếp theo>'");
		
		Items.DecorationHeader.Title = StringFunctionsClientServer.SubstituteParametersInString(
			ListHeaderPattern,
			?(PassedFormParameters.ThisIsAdditionalInformation, NStr("en='additional mix-up';ru='дополнительное сведение';vi='thông tin bổ sung'"), NStr("en='additional attribute';ru='дополнительный реквизит';vi='mục tin bổ sung'")),
			String(PassedFormParameters.CurrentSetOfProperties));
		
	ElsIf CurrentPage = Items.ActionChoice Then
		
		If PassedFormParameters.CopyWithQuestion Then
			Items.CommandBarLeft.Enabled = False;
			AdditionalValuesOwner = PassedFormParameters.AdditionalValuesOwner;
		Else
			Items.CommandBarLeft.Enabled = True;
			SelectedItem = Items.Properties.CurrentData;
			If SelectedItem = Undefined Then
				AdditionalValuesOwner = PassedFormParameters.AdditionalValuesOwner;
			Else
				AdditionalValuesOwner = Items.Properties.CurrentData.Property;
			EndIf;
		EndIf;
		Items.CommandNext.Title = NStr("en='Next >';ru='Далее >';vi='Tiếp theo>'");
		
		Items.AttributeAddMode.Title = StringFunctionsClientServer.SubstituteParametersInString(
			SwitchHeaderPattern,
			?(PassedFormParameters.ThisIsAdditionalInformation, NStr("en='information';ru='сведения';vi='thông tin'"), NStr("en='attribute';ru='реквизита';vi='mục tin'")),
			String(AdditionalValuesOwner),
			String(PassedFormParameters.CurrentSetOfProperties));
		
		If PassedFormParameters.ThisIsAdditionalInformation Then
			Title = NStr("en='Add more information';ru='Добавление дополнительного сведения';vi='Thêm thông tin bổ sung'");
		Else
			Title = NStr("en='Add additional attribute';ru='Добавление дополнительного реквизита';vi='Thêm mục tin bổ sung'");
		EndIf;
		
	Else
		Items.CommandNext.Title = NStr("en='Ready';ru='Готово';vi='Đồng ý'");
		Items.CommandBarLeft.Enabled = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure RefreshContentOfFormItems(WarningText = "")
	
	If WizardMode Then
		CommandBarLocation = FormCommandBarLabelLocation.None;
		Items.CommandNext.DefaultButton    = True;
	Else
		Items.WizardCommandBar.Visible = False;
		Items.WIzardCardPages.CurrentPage = Items.AttributeCard;
	EndIf;
	
	SetFormTitle();
	
	If Not Object.ValueType.ContainsType(Type("Number"))
	   And Not Object.ValueType.ContainsType(Type("Date"))
	   And Not Object.ValueType.ContainsType(Type("Boolean")) Then
		
		Object.FormatProperties = "";
	EndIf;
	
	SetTitleOfFormatButton(ThisObject);
	
	If Object.ThisIsAdditionalInformation
	 Or Not (    Object.ValueType.ContainsType(Type("Number" ))
	         Or Object.ValueType.ContainsType(Type("Date"  ))
	         Or Object.ValueType.ContainsType(Type("Boolean")) )Then
		Items.EditValueFormat.Visible = False;
	Else
		Items.EditValueFormat.Visible = True;
	EndIf;
	
	If Object.ThisIsAdditionalInformation
		And Object.ValueType.ContainsType(Type("String"))
		And Object.ValueType.StringQualifiers.Length = 0 Then
		Items.GroupValueTypeExplanation.Visible = True;
	Else
		Items.GroupValueTypeExplanation.Visible = False;
	EndIf;
	
	If Not Object.ThisIsAdditionalInformation Then
		Items.MultilineGroup.Visible = True;
		SwitchAttributeInputSettings(Object.ValueType);
	Else
		Items.MultilineGroup.Visible = False;
	EndIf;
	
	If ValueIsFilled(Object.Ref) Then
		OldValueType = CommonUse.ObjectAttributeValue(Object.Ref, "ValueType");
	Else
		OldValueType = New TypeDescription;
	EndIf;
	
	If Object.ThisIsAdditionalInformation Then
		Object.FillObligatory = False;
		Items.PropertiesAndDependenciesGroup.Visible = False;
	Else
		AttributeBoolean = (Object.ValueType = New TypeDescription("Boolean"));
		Items.FillObligatory.Visible    = Not AttributeBoolean;
		Items.ChooseItemRequiredOption.Visible = Not AttributeBoolean;
		Items.PropertiesAndDependenciesGroup.Visible = True;
		
		Items.ChooseItemRequiredOption.Enabled  = Object.FillObligatory;
		Items.ChooseAvailabilityOption.Enabled = True;
		Items.ChooseVisibilityOption.Enabled   = True;
		
		SetHyperlinkTitles();
	EndIf;
	
	If ValueIsFilled(Object.AdditionalValuesOwner) Then
		
		PropertiesOfOwner = CommonUse.ObjectAttributesValues(
			Object.AdditionalValuesOwner, "ValueType, AdditionalValuesWithWeight");
		
		If PropertiesOfOwner.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValuesHierarchy")) Then
			Object.ValueType = New TypeDescription(
				Object.ValueType,
				"CatalogRef.ObjectsPropertiesValuesHierarchy",
				"CatalogRef.ObjectsPropertiesValues");
		Else
			Object.ValueType = New TypeDescription(
				Object.ValueType,
				"CatalogRef.ObjectsPropertiesValues",
				"CatalogRef.ObjectsPropertiesValuesHierarchy");
		EndIf;
		
		ValueOwner = Object.AdditionalValuesOwner;
		ValuesWithWeight   = PropertiesOfOwner.AdditionalValuesWithWeight;
	Else
		// Проверка возможности удаления типа дополнительных значений.
		If PropertiesManagementService.ValueTypeContainsPropertiesValues(OldValueType) Then
			Query = New Query;
			Query.SetParameter("Owner", Object.Ref);
			
			If OldValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValuesHierarchy")) Then
				Query.Text =
				"SELECT TOP 1
				|	TRUE AS TrueValue
				|FROM
				|	Catalog.ObjectsPropertiesValuesHierarchy AS ObjectsPropertiesValuesHierarchy
				|WHERE
				|	ObjectsPropertiesValuesHierarchy.Owner = &Owner";
			Else
				Query.Text =
				"SELECT TOP 1
				|	TRUE AS TrueValue
				|FROM
				|	Catalog.ObjectsPropertiesValues AS ObjectsPropertiesValues
				|WHERE
				|	ObjectsPropertiesValues.Owner = &Owner";
			EndIf;
			
			If Not Query.Execute().IsEmpty() Then
				
				If OldValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValuesHierarchy"))
				   And Not Object.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValuesHierarchy")) Then
					
					WarningText = StringFunctionsClientServer.SubstituteParametersInString(
						NStr("en='It is not acceptable to remove the ""%1"" type"
"because additional values have already been introduced."
"You first need to remove the additional values you''ve entered."
""
"Removal cancelled.';ru='Недопустимо удалять тип ""%1"","
"так как дополнительные значения уже введены."
"Сначала нужно удалить введенные дополнительные значения."
""
"Удаление отменено.';vi='Không được phép xóa kiểu ""%1"","
"vì đã nhập các giá trị bổ sung."
"Ban đầu cần xóa các giá trị bổ sung đã nhập."
""
"Đã hủy xóa.'"),
						String(Type("CatalogRef.ObjectsPropertiesValuesHierarchy")) );
					
					Object.ValueType = New TypeDescription(
						Object.ValueType,
						"CatalogRef.ObjectsPropertiesValuesHierarchy",
						"CatalogRef.ObjectsPropertiesValues");
				
				ElsIf OldValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues"))
				        And Not Object.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues")) Then
					
					WarningText = StringFunctionsClientServer.SubstituteParametersInString(
						NStr("en='It is not acceptable to remove the ""%1"" type"
"because additional values have already been introduced."
"You first need to remove the additional values you''ve entered."
""
"Removal cancelled.';ru='Недопустимо удалять тип ""%1"","
"так как дополнительные значения уже введены."
"Сначала нужно удалить введенные дополнительные значения."
""
"Удаление отменено.';vi='Không được phép xóa kiểu ""%1"","
"vì đã nhập các giá trị bổ sung."
"Ban đầu cần xóa các giá trị bổ sung đã nhập."
""
"Đã hủy xóa.'"),
						String(Type("CatalogRef.ObjectsPropertiesValues")) );
					
					Object.ValueType = New TypeDescription(
						Object.ValueType,
						"CatalogRef.ObjectsPropertiesValues",
						"CatalogRef.ObjectsPropertiesValuesHierarchy");
				EndIf;
			EndIf;
		EndIf;
		
		// Check that no more than one additional values type is set up.
		If Object.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValuesHierarchy"))
		   AND Object.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues")) Then
			
			If Not OldValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValuesHierarchy")) Then
				
				WarningText = StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en='You don''t want to use value types at the same time"
"""%1"" and"
"""%2""."
""
"The second type has been removed.';ru='Недопустимо одновременно использовать типы значения"
"""%1"" и"
"""%2""."
""
"Второй тип удален.';vi='Không được phép sử dụng đồng thời các kiểu giá trị"
"""%1"" và"
"""%2""."
""
"Kiểu thứ hai đã bị xóa.'"),
					String(Type("CatalogRef.ObjectsPropertiesValues")),
					String(Type("CatalogRef.ObjectsPropertiesValuesHierarchy")) );
				
				// Удаление второго типа.
				Object.ValueType = New TypeDescription(
					Object.ValueType,
					,
					"CatalogRef.ObjectsPropertiesValuesHierarchy");
			Else
				WarningText = StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en='You don''t want to use value types at the same time"
"""%1"" and"
"""%2""."
""
"The first type has been removed.';ru='Недопустимо одновременно использовать типы значения"
"""%1"" и"
"""%2""."
""
"Первый тип удален.';vi='Không được phép sử dụng đồng thời các kiểu giá trị"
"""%1"" và"
"""%2""."
""
"Kiểu đầu tiên đã bị xóa.'"),
					String(Type("CatalogRef.ObjectsPropertiesValues")),
					String(Type("CatalogRef.ObjectsPropertiesValuesHierarchy")) );
				
				// Deletion of the first type.
				Object.ValueType = New TypeDescription(
					Object.ValueType,
					,
					"CatalogRef.ObjectsPropertiesValues");
			EndIf;
		EndIf;
		
		ValueOwner = Object.Ref;
		ValuesWithWeight   = Object.AdditionalValuesWithWeight;
	EndIf;
	
	If PropertiesManagementService.ValueTypeContainsPropertiesValues(Object.ValueType) Then
		Items.GroupFormsValuesHeaders.Visible = True;
		Items.AdditionalValuesWithWeight.Visible = True;
		Items.ValuePage.Visible = True;
		Items.Pages.PagesRepresentation = FormPagesRepresentation.TabsOnTop;
	Else
		Items.GroupFormsValuesHeaders.Visible = False;
		Items.AdditionalValuesWithWeight.Visible = False;
		Items.ValuePage.Visible = False;
		Items.Pages.PagesRepresentation = FormPagesRepresentation.None;
	EndIf;
	
	Items.Values.Header        = ValuesWithWeight;
	Items.ValuesWeight.Visible = ValuesWithWeight;
	
	CommonUseClientServer.SetFilterDynamicListItem(
		Values, "Owner", ValueOwner, , , True);
	
	If Object.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues")) Then
		ListProperties = CommonUse.DynamicListPropertyStructure();
		ListProperties.QueryText =
			"SELECT
			|	Values.Ref,
			|	Values.DataVersion,
			|	Values.DeletionMark,
			|	Values.Predefined,
			|	Values.Owner,
			|	Values.Parent,
			|	CASE
			|		WHEN &IsMainLanguage
			|		THEN Values.Description
			|		ELSE CAST(ISNULL(PresentationValues.Description, Values.Description) AS STRING(150))
			|	END AS Description,
			|	Values.Weight
			|FROM
			|	Catalog.ObjectsPropertiesValues AS Values
			|	LEFT JOIN Catalog.ObjectsPropertiesValues.Presentations AS PresentationValues
			|		ON (PresentationValues.Ref = Values.Ref)
			|		AND PresentationValues.LanguageCode = &LanguageCode";
		ListProperties.MainTable = "Catalog.ObjectsPropertiesValues";
		CommonUse.SetDynamicListProperties(Items.Values,
			ListProperties);
	Else
		ListProperties = CommonUse.DynamicListPropertyStructure();
		ListProperties.QueryText =
			"SELECT
			|	Values.Ref,
			|	Values.DataVersion,
			|	Values.DeletionMark,
			|	Values.Predefined,
			|	Values.Owner,
			|	Values.Parent,
			|	CASE
			|		WHEN &IsMainLanguage
			|		THEN Values.Description
			|		ELSE CAST(ISNULL(PresentationValues.Description, Values.Description) AS STRING(150))
			|	END AS Description,
			|	Values.Weight
			|FROM
			|	Catalog.ObjectsPropertiesValuesHierarchy AS Values
			|	LEFT JOIN Catalog.ObjectsPropertiesValuesHierarchy.Presentations AS PresentationValues
			|		ON (PresentationValues.Ref = Values.Ref)
			|		AND PresentationValues.LanguageCode = &LanguageCode";
		ListProperties.MainTable = "Catalog.ObjectsPropertiesValuesHierarchy";
		CommonUse.SetDynamicListProperties(Items.Values,
			ListProperties);
	EndIf;
	
	CommonUseClientServer.SetDynamicListParameter(
		Values, "IsMainLanguage", CurrentLanguage() = Metadata.DefaultLanguage, True);
	CommonUseClientServer.SetDynamicListParameter(
		Values, "LanguageCode", CurrentLanguage().LanguageCode, True);
	
	// Отображение уточнений.
	
	If Not ValueIsFilled(Object.AdditionalValuesOwner) Then
		Items.ClarificationOfValuesList.Visible = False;
		Items.AdditionalValues.ReadOnly = False;
		Items.ValuesCommandBarEditing.Visible = True;
		Items.ValuesContextMenuEditing.Visible = True;
		Items.AdditionalValuesWithWeight.Visible = True;
	Else
		Items.ClarificationOfValuesList.Visible = True;
		Items.AdditionalValues.ReadOnly = True;
		Items.ValuesCommandBarEditing.Visible = False;
		Items.ValuesContextMenuEditing.Visible = False;
		Items.AdditionalValuesWithWeight.Visible = False;
		
		Items.ClarificationOfValuesListComment.Hyperlink = ValueIsFilled(Object.Ref);
		Items.SpecificationOfValuesListChange.Enabled    = ValueIsFilled(Object.Ref);
		
		PropertiesOfOwner = CommonUse.ObjectAttributesValues(
			Object.AdditionalValuesOwner, "Title, ThisIsAdditionalInformation");
		
		If PropertiesOfOwner.ThisIsAdditionalInformation <> True Then
			SpecificationTemplate = NStr("en='List of values shared with ""%1"" attribute';ru='Список значений общий с реквизитом ""%1""';vi='Danh sách các giá trị chung với mục tin ""%1""'");
		Else
			SpecificationTemplate = NStr("en='List of values totaled with ""%1""';ru='Список значений общий со сведением ""%1""';vi='Danh sách các giá trị chung với thông tin ""%1""'");
		EndIf;
		
		Items.ClarificationOfValuesListComment.Title =
			StringFunctionsClientServer.SubstituteParametersInString(SpecificationTemplate, PropertiesOfOwner.Title);
	EndIf;
	
	RefreshListSets();
	
	If Not ShowUpdateSet And ListOfSets.Count() < 2 Then
		
		Items.SetsSpecifications.Visible = False;
	Else
		Items.SetsSpecifications.Visible = True;
		Items.SetsSpecificationsComment.Hyperlink = True;
		
		Items.SpecificationsSetsChange.Enabled = ValueIsFilled(Object.Ref);
		
		If ListOfSets.Count() < 2 Then
			
			Items.SpecificationsSetsChange.Visible = False;
		
		ElsIf ValueIsFilled(CurrentSetOfProperties) Then
			Items.SpecificationsSetsChange.Visible = True;
		Else
			Items.SpecificationsSetsChange.Visible = False;
		EndIf;
		
		If ListOfSets.Count() = 0 Then
			Items.SetsSpecificationsComment.Hyperlink = False;
			Items.SpecificationsSetsChange.Visible = False;
			
			If Object.ThisIsAdditionalInformation Then
				TextOfComment = NStr("en='Information is not included in the sets';ru='Сведение не входит в наборы';vi='Thông tin không nằm trong tập hợp'");
			Else
				TextOfComment = NStr("en='Attribute are not included in the sets';ru='Реквизит не входит в наборы';vi='Mục tin không thuộc tập hợp'");
			EndIf;
		ElsIf ListOfSets.Count() < 2 Then
			If Object.ThisIsAdditionalInformation Then
				SpecificationTemplate = NStr("en='Information is included in the set: %1';ru='Сведение входит в набор: %1';vi='Thông tin nằm trong tập hợp: %1'");
			Else
				SpecificationTemplate = NStr("en='Attribute included in the set: %1';ru='Реквизит входит в набор: %1';vi='Mục tin nằm trong tập hợp: %1'");
			EndIf;
			TextOfComment = StringFunctionsClientServer.SubstituteParametersInString(SpecificationTemplate, TrimAll(ListOfSets[0].Presentation));
		Else
			If Object.ThisIsAdditionalInformation Then
				SpecificationTemplate = NStr("en='Information is included in %1%2';ru='Сведение входит в %1 %2';vi='Thông tin nằm trong %1 %2'");
			Else
				SpecificationTemplate = NStr("en='Attribute are included in %1 %2';ru='Реквизит входит в %1 %2';vi='Mục tin thuộc %1 %2'");
			EndIf;
			
			StringSets = UsersServiceClientServer.IntegerSubject(ListOfSets.Count(),
				"", NStr("en='set,sets,sets,,,,,,0';ru='набор,набора,наборов,,,,,,0';vi='tập hợp, các tập hợp,,,,,, 0'"));
			
			TextOfComment = StringFunctionsClientServer.SubstituteParametersInString(SpecificationTemplate, Format(ListOfSets.Count(), "NG="), StringSets);
		EndIf;
		
		Items.SetsSpecificationsComment.Title = TextOfComment + " ";
		
		If Items.SetsSpecificationsComment.Hyperlink Then
			Items.SetsSpecificationsComment.ToolTip = NStr("en='Going to the set';ru='Переход к набору';vi='Chuyển đến tập hợp'");
		Else
			Items.SetsSpecificationsComment.ToolTip = "";
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure SwitchAttributeInputSettings(ValueType)
	
	AllowMultilineFieldSelect = (Object.ValueType.Types().Count() = 1)
		And (Object.ValueType.ContainsType(Type("String")));
	AllowDisplayAsHyperlink   = AllowMultilineFieldSelect
		Or (Not Object.ValueType.ContainsType(Type("String"))
			And Not Object.ValueType.ContainsType(Type("Date"))
			And Not Object.ValueType.ContainsType(Type("Boolean"))
			And Not Object.ValueType.ContainsType(Type("Number")));
	
	Items.SingleLineKind.Visible                       = AllowMultilineFieldSelect;
	Items.FolderMultilineTextBoxSettings.Visible = AllowMultilineFieldSelect;
	Items.DisplayAsHyperlink.Visible              = AllowDisplayAsHyperlink;
	
EndProcedure

&AtServer
Procedure ClearInputWeightsCoefficients()
	
	If Object.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues")) Then
		TableValuesName = "Catalog.ObjectsPropertiesValues";
	Else
		TableValuesName = "Catalog.ObjectsPropertiesValuesHierarchy";
	EndIf;
	
	Block = New DataLock;
	Block.Add(TableValuesName);
	
	BeginTransaction();
	Try
		Block.Lock();
		Query = New Query;
		Query.Text =
		"SELECT
		|	CurrentTable.Ref AS Ref
		|FROM
		|	Catalog.ObjectsPropertiesValues AS CurrentTable
		|WHERE
		|	CurrentTable.Weight <> 0";
		Query.Text = StrReplace(Query.Text , "Catalog.ObjectsPropertiesValues", TableValuesName);
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			ValueObject = Selection.Ref.GetObject();
			ValueObject.Weight = 0;
			ValueObject.Write();
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

&AtServer
Procedure RefreshListSets()
	
	ListOfSets.Clear();
	
	If ValueIsFilled(Object.Ref) Then
		
		Query = New Query(
		"SELECT
		|	AdditionalAttributes.Ref AS Set,
		|	AdditionalAttributes.Ref.Description
		|FROM
		|	Catalog.AdditionalAttributesAndInformationSets.AdditionalAttributes AS AdditionalAttributes
		|WHERE
		|	AdditionalAttributes.Property = &Property
		|	AND NOT AdditionalAttributes.Ref.IsFolder
		|
		|UNION ALL
		|
		|SELECT
		|	AdditionalInformation.Ref,
		|	AdditionalInformation.Ref.Description
		|FROM
		|	Catalog.AdditionalAttributesAndInformationSets.AdditionalInformation AS AdditionalInformation
		|WHERE
		|	AdditionalInformation.Property = &Property
		|	AND NOT AdditionalInformation.Ref.IsFolder");
		
		Query.SetParameter("Property", Object.Ref);
		
		BeginTransaction();
		Try
			Selection = Query.Execute().Select();
			While Selection.Next() Do
				ListOfSets.Add(Selection.Set, Selection.Description + "         ");
			EndDo;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnCurrentPageChange(Direction, MainPage, CurrentPage)
	
	MainPage.CurrentPage = CurrentPage;
	If CurrentPage = Items.ActionChoice Then
		If Direction = "GoForward" Then
			SelectedItem = Items.Properties.CurrentData;
			PassedFormParameters.AdditionalValuesOwner = SelectedItem.Property;
			FillActionListOnAttributeAppend();
		EndIf;
	ElsIf CurrentPage = Items.AttributeCard Then
		FillAttributeOrInformationCard();
	EndIf;
	
EndProcedure

&AtServer
Function AttributeWithAdditionalValueList()
	
	AttributeWithAdditionalValueList = True;
	PropertiesOfOwner = CommonUse.ObjectAttributesValues(
		PassedFormParameters.AdditionalValuesOwner, "ValueType");
	If Not PropertiesOfOwner.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues"))
		And Not PropertiesOfOwner.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValuesHierarchy")) Then
		AttributeWithAdditionalValueList = False;
	EndIf;
	
	Return AttributeWithAdditionalValueList;
EndFunction

&AtServer
Procedure FillActionListOnAttributeAppend()
	
	AttributeWithAdditionalValueList = AttributeWithAdditionalValueList();
	
	If PassedFormParameters.ThisIsAdditionalInformation Then
		AddCommon = NStr("en='Add as is (recommended)"
""
"In this case, it will be possible to select data of different types in lists and reports.';ru='Добавить сведение как есть (рекомендуется)"
""
"В этом случае будет возможно отбирать по нему данные разных типов в списках и отчетах.';vi='Thêm thông tin như có sẵn (nên dùng)"
""
"Trong trường hợp này, có thể chọn dữ liệu có các kiểu khác nhau từ danh sách và báo cáo.'");
		MakeOnPattern = NStr("en=""Make a copy of the information by model (with a common list of values)"
""
"The list of values of this information will be shared with the original mix-up."
"With this option, it's convenient to centrally set the list of values for several similar information at once."
"You can edit the name and a number of other information properties."";ru='Сделать копию сведения по образцу (с общим списком значений)"
""
"Список значений этого сведения будет общим с исходным сведением."
"С помощью этого варианта удобно выполнять централизованную настройку списка значений сразу для нескольких однотипных сведений."
"При этом можно отредактировать наименование и ряд других свойств сведения.';vi='Tạo bản sao thông tin theo mẫu (với danh sách giá trị chung)"
""
"Danh sách giá trị của thông tin này sẽ là chung với thông tin gốc."
"Thông qua phương án này, có thể thực hiện tùy chỉnh tập trung danh sách giá trị ngay đối với nhiều thông tin cùng kiểu. Khi đó có thể soạn tên gọi và nhiều thuộc tính khác của thông tin.'");
		CreateByCopying = NStr("en='Make a copy of the information"
""
"A copy of the information will be created%1';ru='Сделать копию сведения"
""
"Будет создана копия сведения%1';vi='Tạo bản sao thông tin"
""
"Sẽ tạo bản sao thông tin%1'");
	Else
		AddCommon = NStr("en='Add attribute as is (recommended)"
""
"In this case, it will be possible to select data of different types in lists and reports.';ru='Добавить реквизит как есть (рекомендуется)"
""
"В этом случае будет возможно отбирать по нему данные разных типов в списках и отчетах.';vi='Thêm thông tin như có sẵn (nên dùng)"
""
"Trong trường hợp này, có thể chọn dữ liệu có các kiểu khác nhau từ danh sách và báo cáo.'");
		MakeOnPattern = NStr("en=""Make a copy of the attribute by model (with a common list of values)"
""
"The list of meanings of this attribute will be shared with the original attribute."
"With this option, it's convenient to centrally set up a list of values for multiple similar details at once."
"You can edit the name and a number of other attribute properties."";ru='Сделать копию реквизита по образцу (с общим списком значений)"
""
"Список значений этого реквизита будет общим с исходным реквизитом."
"С помощью этого варианта удобно выполнять централизованную настройку списка значений сразу для нескольких однотипных реквизитов."
"При этом можно отредактировать наименование и ряд других свойств реквизита.';vi='Tạo bản sao mục tin theo mẫu (với danh sách giá trị chung)"
""
"Danh sách giá trị của mục tin này sẽ là chung với mục tin gốc."
"Thông qua phương án này, có thể thực hiện tùy chỉnh tập trung danh sách giá trị ngay đối với nhiều mục tin cùng kiểu. Khi đó có thể soạn tên gọi và nhiều thuộc tính khác của mục tin.'");
		CreateByCopying = NStr("en='Make a copy of the attribute"
""
"A copy of the attribute will be created%1';ru='Сделать копию реквизита"
""
"Будет создана копия реквизита%1';vi='Tạo bản sao mục tin"
""
"Sẽ tạo bản sao mục tin%1'");
	EndIf;
	
	ChoiceList = Items.AttributeAddMode.ChoiceList;
	ChoiceList.Clear();
	
	If AttributeWithAdditionalValueList Then
		InsertionPattern = " " + NStr("en='and all its values.';ru='и всех его значений.';vi='và tất cả giá trị của nó.'");
	Else
		InsertionPattern = ".";
	EndIf;
	CreateByCopying = StringFunctionsClientServer.SubstituteParametersInString(CreateByCopying, InsertionPattern);
	
	ChoiceList.Add("AddCommonAttributeToSet", AddCommon);
	If AttributeWithAdditionalValueList Then
		ChoiceList.Add("CreateSample", MakeOnPattern);
	EndIf;
	ChoiceList.Add("CreateByCopying", CreateByCopying);
	
	AttributeAddMode = "AddCommonAttributeToSet";
	
EndProcedure

&AtServer
Procedure SaveAdditionalAttributeValuesOnCopy(CurrentObject)
	
	If CurrentObject.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValuesHierarchy")) Then
		Parent = Catalogs.ObjectsPropertiesValuesHierarchy.EmptyRef();
	Else
		Parent = Catalogs.ObjectsPropertiesValues.EmptyRef();
	EndIf;
	
	Owner = CurrentObject.Ref;
	TreeRow = ValuesOfAdditionalAttributes.GetItems();
	SaveAdditionalAttributeValuesOnCopyRecursive(Owner, TreeRow, Parent);
	TreeRow.Clear();
	Items.AttributeValuePages.CurrentPage = Items.AdditionalValues;
	
EndProcedure

&AtServer
Procedure SaveAdditionalAttributeValuesOnCopyRecursive(Owner, TreeRow, Parent)
	
	For Each TreeItem In TreeRow Do
		ObjectCopy = TreeItem.Ref.GetObject().Copy();
		ObjectCopy.Owner = Owner;
		ObjectCopy.Parent = Parent;
		ObjectCopy.Write();
		
		Var_ChildItems = TreeItem.GetItems();
		SaveAdditionalAttributeValuesOnCopyRecursive(Owner, Var_ChildItems, ObjectCopy.Ref)
	EndDo;
	
EndProcedure

&AtServer
Procedure SetHyperlinkTitles()
	
	EnabledDependencySet              = False;
	RequiredFillingDependencySet = False;
	VisibleDependencySet                = False;
	PropertyDependencies = Object.AdditionalAttributeDependencies;
	
	FilterBySet = New Structure;
	FilterBySet.Insert("PropertySet", CurrentSetOfProperties);
	DependenciesFound = Object.AdditionalAttributeDependencies.FindRows(FilterBySet);
	
	For Each PropertyDependency In DependenciesFound Do
		If PropertyDependency.DependentProperty = "Available" Then
			EnabledDependencySet = True;
		ElsIf PropertyDependency.DependentProperty = "FillObligatory" Then
			RequiredFillingDependencySet = True;
		ElsIf PropertyDependency.DependentProperty = "Visible" Then
			VisibleDependencySet = True;
		EndIf;
	EndDo;
	
	PatternDependencySet = NStr("en='with the condition';ru='с условием';vi='với điều kiện'");
	PatternDependencyNotSet = NStr("en='always';ru='всегда';vi='luôn luôn'");
	
	Items.ChooseAvailabilityOption.Title = ?(EnabledDependencySet,
		PatternDependencySet,
		PatternDependencyNotSet);
	
	Items.ChooseItemRequiredOption.Title = ?(RequiredFillingDependencySet,
		PatternDependencySet,
		PatternDependencyNotSet);
	
	Items.ChooseVisibilityOption.Title = ?(VisibleDependencySet,
		PatternDependencySet,
		PatternDependencyNotSet);
	
EndProcedure

&AtClient
Procedure OpenDependencySettingsForm(PropertyToConfigure)
	
	FormParameters = New Structure;
	FormParameters.Insert("AdditionalAttribute", Object.Ref);
	FormParameters.Insert("AttributeDependencies", Object.AdditionalAttributeDependencies);
	FormParameters.Insert("Set", CurrentSetOfProperties);
	FormParameters.Insert("PropertyToConfigure", PropertyToConfigure);
	
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInformation.Form.AttributesDependencies", FormParameters);
	
EndProcedure

&AtServer
Procedure SetFormTitle()
	
	If ValueIsFilled(Object.Ref) Then
		If Object.ThisIsAdditionalInformation Then
			Title = String(Object.Title) + " " + NStr("en='(Additional information)';ru='(Дополнительное сведение)';vi='(Thông tin bổ sung)'");
		Else
			Title = String(Object.Title) + " " + NStr("en='(Additional attribute)';ru='(Дополнительный реквизит)';vi='(Mục tin bổ sung)'");
		EndIf;
	Else
		If Object.ThisIsAdditionalInformation Then
			Title = NStr("en='Additional mixing (creation)';ru='Дополнительное сведение (создание)';vi='Thông tin bổ sung (tạo)'");
		Else
			Title = NStr("en='Additional attribute (creation)';ru='Дополнительный реквизит (создание)';vi='Mục tin bổ sung (tạo)'");
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnChangeOfCurrentSet()
	
	If Items.PropertiesSets.CurrentData = Undefined Then
		If ValueIsFilled(SelectedPropertiesSet) Then
			SelectedPropertiesSet = Undefined;
			OnChangeOfCurrentSetAtServer();
		EndIf;
		
	ElsIf Items.PropertiesSets.CurrentData.Ref <> SelectedPropertiesSet Then
		SelectedPropertiesSet = Items.PropertiesSets.CurrentData.Ref;
		CurrentSetIsFolder = Items.PropertiesSets.CurrentData.IsFolder;
		OnChangeOfCurrentSetAtServer(CurrentSetIsFolder);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnChangeOfCurrentSetAtServer(CurrentSetIsFolder = Undefined)
	
	If ValueIsFilled(SelectedPropertiesSet)
		And Not CurrentSetIsFolder Then
		RefreshListOfPropertiesOfCurrentSetOf();
	Else
		Properties.Clear();
	EndIf;
	
EndProcedure

&AtServer
Procedure RefreshListOfPropertiesOfCurrentSetOf()
	
	Query = New Query;
	
	If Not Items.UsedAttributes.Check Then
		Query.SetParameter("Set", SelectedPropertiesSet);
		Query.Text =
			"SELECT
			|	SetsProperties.LineNumber,
			|	SetsProperties.Property,
			|	SetsProperties.DeletionMark,
			|	CASE
			|		WHEN &IsMainLanguage
			|		THEN Properties.Title
			|		ELSE CAST(ISNULL(PresentationProperties.Title, Properties.Title) AS STRING(150))
			|	END AS Title,
			|	Properties.AdditionalValuesOwner,
			|	Properties.ValueType AS ValueType,
			|	TRUE AS Common,
			|	CASE
			|		WHEN SetsProperties.DeletionMark = TRUE
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
			|	Catalog.AdditionalAttributesAndInformationSets.AdditionalAttributes AS SetsProperties
			|		LEFT JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInformation AS Properties
			|		ON SetsProperties.Property = Properties.Ref
			|		LEFT JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInformation.Presentations AS PresentationProperties
			|		ON SetsProperties.Property = PresentationProperties.Ref
			|			AND PresentationProperties.LanguageCode = &LanguageCode
			|
			|WHERE
			|	SetsProperties.Ref = &Set
			|
			|ORDER BY
			|	SetsProperties.LineNumber
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	TheSets.DataVersion AS DataVersion
			|FROM
			|	Catalog.AdditionalAttributesAndInformationSets AS TheSets
			|WHERE
			|	TheSets.Ref = &Set";
		
		If ThisIsAdditionalInformation Then
			Query.Text = StrReplace(
				Query.Text,
				"Catalog.AdditionalAttributesAndInformationSets.AdditionalAttributes",
				"Catalog.AdditionalAttributesAndInformationSets.AdditionalInformation");
		EndIf;
		
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
			?(ThisIsAdditionalInformation, "AdditionalInformation", "AdditionalAttributes"));
		Query.SetParameter("ThisIsAdditionalInformation", (ThisIsAdditionalInformation = 1));
	EndIf;
	Query.SetParameter("IsMainLanguage", CurrentLanguage() = Metadata.DefaultLanguage);
	Query.SetParameter("LanguageCode", CurrentLanguage().LanguageCode);
	
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
			|UNION ALL
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
Procedure CreatePassedParametersStructure()
	PassedFormParameters = New Structure;
	PassedFormParameters.Insert("AdditionalValuesOwner");
	PassedFormParameters.Insert("ShowUpdateSet");
	PassedFormParameters.Insert("CurrentSetOfProperties");
	PassedFormParameters.Insert("ThisIsAdditionalInformation");
	PassedFormParameters.Insert("SelectionOfCommonProperty");
	PassedFormParameters.Insert("SelectedValues");
	PassedFormParameters.Insert("OwnersSelectionOfAdditionalValues");
	PassedFormParameters.Insert("CopyingValue");
	PassedFormParameters.Insert("CopyWithQuestion");
	PassedFormParameters.Insert("Drag", False);
	
	FillPropertyValues(PassedFormParameters, Parameters);
	
	ValueOwner = PassedFormParameters.AdditionalValuesOwner;
	If ValueIsFilled(ValueOwner) Then
		ValueOwner = CommonUse.ObjectAttributeValue(ValueOwner, "AdditionalValuesOwner");
		If ValueIsFilled(ValueOwner) Then
			PassedFormParameters.AdditionalValuesOwner = ValueOwner;
		EndIf;
	EndIf;
EndProcedure

&AtServerNoContext
Function NameIsAlreadyUsed(Val Title, Val CurrentProperty, Val PropertySet, NewDescription, Val Presentations)
	
	If CurrentLanguage() <> CommonUseClientServer.MainLanguageCode() Then
		Filter = New Structure();
		Filter.Insert("LanguageCode", CommonUseClientServer.MainLanguageCode());
		FoundStrings = Presentations.FindRows(Filter);
		If FoundStrings.Count() > 0 Then
			Title = FoundStrings[0].Title;
		EndIf;
	EndIf;
	
	NewDescription = Title;
	
	Query = New Query;
	Query.Text =
		"SELECT TOP 1
		|	PropertiesSet.Property AS Property,
		|	AttributesAndInformation.ThisIsAdditionalInformation AS ThisIsAdditionalInformation
		|FROM
		|	Catalog.AdditionalAttributesAndInformationSets.AdditionalAttributes AS PropertiesSet
		|		LEFT JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInformation AS AttributesAndInformation
		|		ON (AttributesAndInformation.Ref = PropertiesSet.Property)
		|WHERE
		|	AttributesAndInformation.Title = &Description
		|	AND PropertiesSet.Ref = &PropertySet
		|	AND PropertiesSet.Property <> &Ref
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	PropertiesSet.Property AS Property,
		|	AttributesAndInformation.ThisIsAdditionalInformation AS ThisIsAdditionalInformation
		|FROM
		|	Catalog.AdditionalAttributesAndInformationSets.AdditionalInformation AS PropertiesSet
		|		LEFT JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInformation AS AttributesAndInformation
		|		ON (AttributesAndInformation.Ref = PropertiesSet.Property)
		|WHERE
		|	AttributesAndInformation.Title = &Description
		|	AND PropertiesSet.Ref = &PropertySet
		|	AND PropertiesSet.Property <> &Ref";
	
	Query.SetParameter("Ref",       CurrentProperty);
	Query.SetParameter("PropertySet", PropertySet);
	Query.SetParameter("Description", NewDescription);
	
	BeginTransaction();
	Try
		Selection = Query.Execute().Select();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If Not Selection.Next() Then
		Return "";
	EndIf;
	
	If Selection.ThisIsAdditionalInformation Then
		QuestionText = NStr("en='There is an additional link with the name"
"""%1"".';ru='Существует дополнительное сведение с наименованием"
"""%1"".';vi='Có thông tin bổ sung với tên gọi"
"""%1"".'");
	Else
		QuestionText = NStr("en='There is an additional attribute with the name"
"""%1"".';ru='Существует дополнительный реквизит с наименованием"
"""%1"".';vi='Có mục tin bổ sung với tên gọi"
"""%1"".'");
	EndIf;
	
	QuestionText = StringFunctionsClientServer.SubstituteParametersInString(
		QuestionText + Chars.LF + Chars.LF
		                         + NStr("en=""It's a good idea to use a different name"
"otherwise the program may not work properly."";ru='Рекомендуется использовать другое наименование,"
"иначе программа может работать некорректно.';vi='Nên sử dụng tên gọi khác,"
"nếu không chương trình có thể làm việc không chính xác.'"),
		NewDescription);
	
	Return QuestionText;
	
EndFunction

&AtServerNoContext
Function NameAlreadyUsed(Val Name, Val CurrentProperty, NewDescription)
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	Properties.ThisIsAdditionalInformation
	|FROM
	|	ChartOfCharacteristicTypes.AdditionalAttributesAndInformation AS Properties
	|WHERE
	|	Properties.Name = &Name
	|	AND Properties.Ref <> &Ref";
	
	Query.SetParameter("Ref", CurrentProperty);
	Query.SetParameter("Name",    Name);
	
	BeginTransaction();
	Try
		Selection = Query.Execute().Select();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If Not Selection.Next() Then
		Return "";
	EndIf;
	
	If Selection.ThisIsAdditionalInformation Then
		QuestionText = NStr("en='There is additional information with the name"
"""%1"".';ru='Существует дополнительное сведение с именем"
"""%1"".';vi='Có thông tin bổ sung với tên gọi"
"""%1"".'");
	Else
		QuestionText = NStr("en='There is an additional attribute with a name"
"""%1"".';ru='Существует дополнительный реквизит с именем"
"""%1"".';vi='Có mục tin bổ sung với tên gọi"
"""%1"".'");
	EndIf;
	
	QuestionText = StringFunctionsClientServer.SubstituteParametersInString(
		QuestionText + Chars.LF + Chars.LF
		                         + NStr("en=""It's a good idea to use a different name"
"otherwise the program may not work properly."
""
"Create a new name and continue recording?"";ru='Рекомендуется использовать другое имя,"
"иначе программа может работать некорректно."
""
"Создать новое имя и продолжить запись?';vi='Nên sử dụng một tên khác,"
"nếu không chương trình có thể làm việc không chính xác."
""
"Tạo tên mới và tiếp tục ghi lại?'"),
		Name);
	
	Return QuestionText;
	
EndFunction

&AtClientAtServerNoContext
Procedure SetTitleOfFormatButton(Form)
	
	If IsBlankString(Form.Object.FormatProperties) Then
		HeaderText = NStr("en='Default format';ru='Формат по умолчанию';vi='Định dạng theo mặc định'");
	Else
		HeaderText = NStr("en='Format is set';ru='Формат установлен';vi='Đã thiết lập định dạng'");
	EndIf;
	
	Form.Items.EditValueFormat.Title = HeaderText;
	
EndProcedure

#EndRegion
