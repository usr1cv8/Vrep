////////////////////////////////////////////////////////////////////////////////
//                          FORM USAGE //
//
// Additional parameters for opening a selection form:
//
// AdvancedSelection - Boolean - if True - extended user
//  selection form opens. Used with parameter
//  ExtendedSelectionFormParameters.
// AnExtendedFormOfSelectionOptions - String - reference
//  to the structure with parameters of
//  the extended selection form in the temporary storage.
//  Structure parameters:
//    FormHeaderSelection - String - selection form header.
//    SelectedUsers - Array - array of selected user names.
//

#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then // Return if the form for analysis is received.
		Return;
	EndIf;
	
	// Initial setting value before loading setting data.
	SelectHierarchy = True;
	
	FillSettingsStored();
	FillParametersDynamicLists();
	
	If Parameters.ChoiceMode Then
		StandardSubsystemsServer.SetFormPurposeKey(ThisObject, "PickupSelection");
		WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
	EndIf;
	
	// Hide user names with empty identifier if the parameter value is True.
	If Parameters.HideUsersWithoutIBUser Then
		CommonUseClientServer.SetFilterDynamicListItem(
			ExternalUsersList,
			"InfobaseUserID",
			New UUID("00000000-0000-0000-0000-000000000000"),
			DataCompositionComparisonType.NotEqual);
	EndIf;
	
	// Hide the passed user name in the user selection form.
	If TypeOf(Parameters.HiddenUsers) = Type("ValueList") Then
		
		ComparisonTypeCD = DataCompositionComparisonType.NotInList;
		CommonUseClientServer.SetFilterDynamicListItem(
			ExternalUsersList,
			"Ref",
			Parameters.HiddenUsers,
			ComparisonTypeCD);
	EndIf;
	
	CustomizeOrderGroupsAllExternalUsers(ExternalUsersGroups);
	ApplyAppearanceAndHideInvalidExternalUsers();
	
	SettingsStored.Insert("AdvancedSelection", Parameters.AdvancedSelection);
	Items.SelectedUsersAndGroups.Visible = SettingsStored.AdvancedSelection;
	SettingsStored.Insert(
		"UseGroups", GetFunctionalOption("UseUsersGroups"));
	
	If Not AccessRight("Insert", Metadata.Catalogs.ExternalUsers) Then
		Items.CreateExternalUser.Visible = False;
	EndIf;
	
	If Not Users.InfobaseUserWithFullAccess(, CommonUseReUse.ApplicationRunningMode().Local) Then
		If Items.Find("IBUsers") <> Undefined Then
			Items.IBUsers.Visible = False;
		EndIf;
		Items.ExternalUserData.Visible = False;
	EndIf;
	
	If Parameters.ChoiceMode Then
		
		If Items.Find("IBUsers") <> Undefined Then
			Items.IBUsers.Visible = False;
		EndIf;
		Items.ExternalUserData.Visible = False;
		
		// Filter of items not marked for deletion.
		CommonUseClientServer.SetFilterDynamicListItem(
			ExternalUsersList, "DeletionMark", False, , , True,
			DataCompositionSettingsItemViewMode.Normal);
		
		Items.ExternalUsersList.ChoiceMode = True;
		Items.ExternalUsersGroups.ChoiceMode =
			SettingsStored.ExternalUserGroupChoice;
		
		// Disable drag-and-drop in user selection and choice forms.
		Items.ExternalUsersList.EnableStartDrag = False;
		
		If Parameters.Property("NonExistentInfobaseUserIDs") Then
			CommonUseClientServer.SetFilterDynamicListItem(
				ExternalUsersList, "InfobaseUserID",
				Parameters.NonExistentInfobaseUserIDs,
				DataCompositionComparisonType.InList, , True,
				DataCompositionSettingsItemViewMode.Inaccessible);
		EndIf;
		
		If Parameters.CloseOnChoice = False Then
			// Choice mode.
			Items.ExternalUsersList.MultipleChoice = True;
			
			If SettingsStored.AdvancedSelection Then
				StandardSubsystemsServer.SetFormPurposeKey(ThisObject, "AdvancedSelection");
				ChangeParametersExtensionPickForm();
			EndIf;
			
			If SettingsStored.ExternalUserGroupChoice Then
				Items.ExternalUsersGroups.MultipleChoice = True;
			EndIf;
		EndIf;
	Else
		Items.Comments.Visible = False;
		Items.ChooseExternalUser.Visible = False;
		Items.ChooseExternalUserGroup.Visible = False;
	EndIf;
	
	SettingsStored.Insert("GroupAllUsers", Catalogs.ExternalUsersGroups.AllExternalUsers);
	SettingsStored.Insert("CurrentRow", Parameters.CurrentRow);
	SetupFormByUsingUsersGroups();
	SettingsStored.Delete("CurrentRow");
	
	If Not CommonUse.SubsystemExists("StandardSubsystems.GroupObjectsChange") Then
		Items.FormChangeSelected.Visible = False;
		Items.UsersListContextMenuChangeSelected.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Parameters.ChoiceMode Then
		CheckCurrentFormItemChange();
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Upper(EventName) = Upper("Write_ExternalUsersGroups")
	   AND Source = Items.ExternalUsersGroups.CurrentRow Then
		
		Items.ExternalUsersGroups.Refresh();
		Items.ExternalUsersList.Refresh();
		RefreshFormContentOnGroupChange(ThisObject);
		
	ElsIf Upper(EventName) = Upper("Record_ConstantsSet") Then
		
		If Upper(Source) = Upper("UseUsersGroups") Then
			AttachIdleHandler("OnChangeUseOfUsersGroups", 0.1, True);
		EndIf;
		
	ElsIf Upper(EventName) = Upper("PlacingUsersInGroups") Then
		
		Items.ExternalUsersList.Refresh();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeImportingDataFromSettingsAtServer(Settings)
	
	If TypeOf(Settings["SelectHierarchy"]) = Type("Boolean") Then
		SelectHierarchy = Settings["SelectHierarchy"];
	EndIf;
	
	If Not SelectHierarchy Then
		RefreshFormContentOnGroupChange(ThisObject);
	EndIf;
	
EndProcedure

#EndRegion

#Region HeaderFormItemsEventsHandlers

&AtClient
Procedure SelectHierarchicallyOnChange(Item)
	
	RefreshFormContentOnGroupChange(ThisObject);
	
EndProcedure

&AtClient
Procedure ShowInvalidUsersOnChange(Item)
	ToggleDisabledUsersView(ShowNotValidUsers);
EndProcedure

#EndRegion

#Region FormTableItemEventHandlersExternalUsersGroups

&AtClient
Procedure ExternalUsersGroupsOnActivateRow(Item)
	
	RefreshFormContentOnGroupChange(ThisObject);
	
EndProcedure

&AtClient
Procedure ExternalUsersGroupsValueChoice(Item, Value, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not SettingsStored.AdvancedSelection Then
		NotifyChoice(Value);
	Else
		
		GetImagesAndFillSelectedList(Value);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExternalUsersGroupsBeforeAddRow(Item, Cancel, Copy, Parent, Group)
	
	If Not Copy Then
		Cancel = True;
		FormParameters = New Structure;
		
		If ValueIsFilled(Items.ExternalUsersGroups.CurrentRow) Then
			
			FormParameters.Insert(
				"FillingValues",
				New Structure("Parent", Items.ExternalUsersGroups.CurrentRow));
		EndIf;
		
		OpenForm(
			"Catalog.ExternalUsersGroups.ObjectForm",
			FormParameters,
			Items.ExternalUsersGroups);
	EndIf;
	
EndProcedure

&AtClient
Procedure GroupsExternalUsersDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure GroupsExternalUsersDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	
	If SelectHierarchy Then
		ShowMessageBox(,NStr("en='To drag user names to groups,"
"clear the ""Show child group users"" check box.';ru='Для перетаскивания пользователя"
"в группы необходимо отключить флажок ""Показывать пользователей дочерних групп"".';vi='Để kéo thả người sử dụng"
"vào nhóm, cần bỏ dấu hộp kiểm ""Hiển thị người sử dụng nhóm con"".'"));
		Return;
	EndIf;
	
	If Items.ExternalUsersGroups.CurrentRow = String
		Or String = Undefined Then
		Return;
	EndIf;
	
	If DragParameters.Action = DragAction.Move Then
		Move = True;
	Else
		Move = False;
	EndIf;
	
	CurrentRowFolders = Items.ExternalUsersGroups.CurrentRow;
	FolderTypeAllAuthorizationObjects = 
		Items.ExternalUsersGroups.RowData(CurrentRowFolders).AllAuthorizationObjects;
	
	If String = SettingsStored.GroupAllUsers
		AND FolderTypeAllAuthorizationObjects Then
		UserMessage = New Structure("Message, HasErrors, Users",
			NStr("en='You cannot exclude users from groups with type of participants ""All users of the specified type"".';ru='Из групп с типом участников ""Все пользователи заданного типа"" исключение пользователей невозможно.';vi='Trong nhóm có kiểu người tham gia ""Tất cả người sử dụng kiểu đã chọn"" không thể loại bỏ người sử dụng.'"),
			True,
			Undefined);
	Else
		FolderIsMarkedForDelete = Items.ExternalUsersGroups.RowData(String).DeletionMark;
		
		UserCount = DragParameters.Value.Count();
		
		ActionToDeleteUser = (SettingsStored.GroupAllUsers = String);
		
		ActionWithUser = 
			?((SettingsStored.GroupAllUsers = CurrentRowFolders) OR FolderTypeAllAuthorizationObjects,
			NStr("en='Enable';ru='Включить';vi='Bật'"),
			?(Move, NStr("en='Movement';ru='Перемещение';vi='Điều chuyển'"), NStr("en='Copy';ru='Скопировать';vi='Sao chép'")));
		
		If FolderIsMarkedForDelete Then
			ActionsTemplate = ?(Move, NStr("en='The ""%1"" group is marked for deletion. %2';ru='Группа ""%1"" помечена на удаление. %2';vi='Nhóm ""%1"" đã đặt dấu xóa. %2'"), 
				NStr("en='The ""%1"" group is marked for deletion. %2';ru='Группа ""%1"" помечена на удаление. %2';vi='Nhóm ""%1"" đã đặt dấu xóa. %2'"));
			ActionWithUser = StringFunctionsClientServer.SubstituteParametersInString(
				ActionsTemplate, String(String), ActionWithUser);
		EndIf;
		
		If UserCount = 1 Then
			
			If ActionToDeleteUser Then
				QuestionTemplate = NStr("en='Exclude the ""%2"" user from the ""%4"" group?';ru='Исключить пользователя ""%2"" из группы ""%4""?';vi='Loại bỏ người sử dụng ""%2"" khỏi nhóm ""%4""?'");
			ElsIf Not FolderIsMarkedForDelete Then
				QuestionTemplate = NStr("en='%1 user ""%2"" to group ""%3""?';ru='%1 пользователя ""%2"" в группу ""%3""?';vi='%1 người sử dụng ""%2"" trong nhóm ""%3""?'");
			Else
				QuestionTemplate = NStr("en='%1 user ""%2"" to this group?';ru='%1 пользователя ""%2"" в эту группу?';vi='%1 người sử dụng ""%2"" trong nhóm này?'");
			EndIf;
			QuestionText = StringFunctionsClientServer.SubstituteParametersInString(
				QuestionTemplate, ActionWithUser, String(DragParameters.Value[0]),
				String(String), String(Items.ExternalUsersGroups.CurrentRow));
			
		Else
			
			If ActionToDeleteUser Then
				QuestionTemplate = NStr("en='Exclude users (%2) from the ""%4"" group?';ru='Исключить пользователей (%2) из группы ""%4""?';vi='Loại bỏ người sử dụng (%2) khỏi nhóm ""%4""?'");
			ElsIf Not FolderIsMarkedForDelete Then
				QuestionTemplate = NStr("en='%1 users (%2) to group ""%3""?';ru='%1 пользователей (%2) в группу ""%3""?';vi='%1 người sử dụng (%2) trong nhóm ""%3""?'");
			Else
				QuestionTemplate = NStr("en='%1 users (%2) to this group?';ru='%1 пользователей (%2) в эту группу?';vi='%1 người sử dụng (%2) trong nhóm này?'");
			EndIf;
			QuestionText = StringFunctionsClientServer.SubstituteParametersInString(
				QuestionTemplate, ActionWithUser, UserCount,
				String(String), String(Items.ExternalUsersGroups.CurrentRow));
			
		EndIf;
		
		AdditionalParameters = New Structure("DragParameters, String, Move",
			DragParameters.Value, String, Move);
		Notification = New NotifyDescription("ExternalUsersGroupsDragQuestionProcessor", ThisObject, AdditionalParameters);
		ShowQueryBox(Notification, QuestionText, QuestionDialogMode.YesNo, 60, DialogReturnCode.Yes);
		Return;
		
	EndIf;
	
	ExternalUsersGroupsDragEnd(UserMessage);
	
EndProcedure

#EndRegion

#Region FormTableItemEventHandlersExternalUsers

&AtClient
Procedure ExternalUsersListValueChoice(Item, Value, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not SettingsStored.AdvancedSelection Then
		NotifyChoice(Value);
	Else
		GetImagesAndFillSelectedList(Value);
	EndIf;
	
EndProcedure

&AtClient
Procedure ExternalUsersListBeforeAddRow(Item, Cancel, Copy, Parent, Group)
	
	Cancel = True;
	
	FormParameters = New Structure(
		"NewExternalUserGroup", Items.ExternalUsersGroups.CurrentRow);
	
	If ValueIsFilled(SettingsStored.AuthorizationObjectFilter) Then
		
		FormParameters.Insert(
			"NewExternalUserAuthorizationObject",
			SettingsStored.AuthorizationObjectFilter);
	EndIf;
	
	If Copy AND Item.CurrentData <> Undefined Then
		FormParameters.Insert("CopyingValue", Item.CurrentRow);
	EndIf;
	
	OpenForm(
		"Catalog.ExternalUsers.ObjectForm",
		FormParameters,
		Items.ExternalUsersList);
	
EndProcedure

&AtClient
Procedure ExternalUsersListDropCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	
EndProcedure

#EndRegion

#Region FormTableItemEventHandlersSelectedUsersAndGroupsList

&AtClient
Procedure ListOfSelectedUsersAndGroupChoice(Item, SelectedRow, Field, StandardProcessing)
	
	DeleteFromListSelected();
	ThisObject.Modified = True;
	
EndProcedure

&AtClient
Procedure SelectedUsersAndGroupsListBeforeAddRow(Item, Cancel, Copy, Parent, Group, Parameter)
	Cancel = True;
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure CreateGroupOfExternalUsers(Command)
	
	CurrentData = Items.ExternalUsersGroups.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.AllAuthorizationObjects Then
		ShowMessageBox(, StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='Cannot add a subgroup to the ""%1"" group because it includes all users.';ru='Невозможно добавить подгруппу к группе ""%1"", так как в число ее участников входят все пользователи.';vi='Không thể thêm nhóm con vào nhóm ""%1"" bởi vì trong số những người tham gia của nhóm bao gồm tất cả người sử dụng.'"), CurrentData.Description));
		Return;
	EndIf;
		
	Items.ExternalUsersGroups.AddRow();
	
EndProcedure

&AtClient
Procedure AssignGroups(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("Users", Items.ExternalUsersList.SelectedRows);
	FormParameters.Insert("ExternalUsers", True);
	
	OpenForm("CommonForm.UsersGroups", FormParameters);
	
EndProcedure

&AtClient
Procedure FinishAndClose(Command)
	
	If SettingsStored.AdvancedSelection Then
		UserArray = ChoiceResult();
		NotifyChoice(UserArray);
		ThisObject.Modified = False;
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceUserCommand(Command)
	
	UserArray = Items.ExternalUsersList.SelectedRows;
	GetImagesAndFillSelectedList(UserArray);
	
EndProcedure

&AtClient
Procedure CancelSelectionUserOrGroup(Command)
	
		DeleteFromListSelected();
	
EndProcedure

&AtClient
Procedure ClearListSelectedUsersAndGroups(Command)
	
	DeleteFromListSelected(True);
	
EndProcedure

&AtClient
Procedure ChooseGroup(Command)
	
	GroupArray = Items.ExternalUsersGroups.SelectedRows;
	GetImagesAndFillSelectedList(GroupArray);
	
EndProcedure

&AtClient
Procedure ExternalUserData(Command)
	
	OpenForm(
		"Report.InformationAboutUsers.ObjectForm",
		New Structure("VariantKey", "ExternalUserData"),
		ThisObject,
		"ExternalUserData");
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Support bulk object editing.

&AtClient
Procedure ChangeSelected(Command)
	
	If CommonUseClient.SubsystemExists("StandardSubsystems.GroupObjectsChange") Then
		ModuleBatchObjectChangingClient = CommonUseClient.CommonModule("GroupObjectsChangeClient");
		ModuleBatchObjectChangingClient.ChangeSelected(Items.ExternalUsersList);
	EndIf;
	
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

&AtServer
Procedure FillSettingsStored()
	
	SettingsStored = New Structure;
	SettingsStored.Insert("ExternalUserGroupChoice", Parameters.ExternalUserGroupChoice);
	
	If Parameters.Filter.Property("AuthorizationObject") Then
		SettingsStored.Insert("AuthorizationObjectFilter", Parameters.Filter.AuthorizationObject);
	Else
		SettingsStored.Insert("AuthorizationObjectFilter", Undefined);
	EndIf;
	
	// Prepare authorization object type views.
	SettingsStored.Insert("AuthorizationObjectsTypesPresentation", New ValueList);
	AuthorizationObjectTypes = Metadata.Catalogs.ExternalUsers.Attributes.AuthorizationObject.Type.Types();
	
	For Each CurrentAuthorizationObjectType IN AuthorizationObjectTypes Do
		If Not CommonUse.IsReference(CurrentAuthorizationObjectType) Then
			Continue;
		EndIf;
		TypeArray = New Array;
		TypeArray.Add(CurrentAuthorizationObjectType);
		DescriptionOfType = New TypeDescription(TypeArray);
		
		SettingsStored.AuthorizationObjectsTypesPresentation.Add(
			DescriptionOfType.AdjustValue(Undefined),
			Metadata.FindByType(CurrentAuthorizationObjectType).Synonym);
	EndDo;
	
EndProcedure

&AtServer
Procedure FillParametersDynamicLists()
	
	TypeOfAuthorizationObjects = Undefined;
	Parameters.Property("TypeOfAuthorizationObjects", TypeOfAuthorizationObjects);
	
	RefreshDataCompositionParameterValue(
		ExternalUsersGroups,
		"AnyAuthorizationObjectType",
		TypeOfAuthorizationObjects = Undefined);
	
	RefreshDataCompositionParameterValue(
		ExternalUsersGroups,
		"TypeOfAuthorizationObjects",
		TypeOf(TypeOfAuthorizationObjects));
	
	RefreshDataCompositionParameterValue(
		ExternalUsersList,
		"AnyAuthorizationObjectType",
		TypeOfAuthorizationObjects = Undefined);
	
	RefreshDataCompositionParameterValue(
		ExternalUsersList,
		"TypeOfAuthorizationObjects",
		TypeOf(TypeOfAuthorizationObjects));
	
EndProcedure

&AtServer
Procedure CustomizeOrderGroupsAllExternalUsers(List)
	
	Var Order;
	
	// Order.
	Order = List.SettingsComposer.Settings.Order;
	Order.UserSettingID = "DefaultOrder";
	
	Order.Items.Clear();
	
	OrderingItem = Order.Items.Add(Type("DataCompositionOrderItem"));
	OrderingItem.Field = New DataCompositionField("Predefined");
	OrderingItem.OrderType = DataCompositionSortDirection.Desc;
	OrderingItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	OrderingItem.Use = True;
	
	OrderingItem = Order.Items.Add(Type("DataCompositionOrderItem"));
	OrderingItem.Field = New DataCompositionField("Description");
	OrderingItem.OrderType = DataCompositionSortDirection.Asc;
	OrderingItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	OrderingItem.Use = True;
	
EndProcedure

&AtServer
Procedure ApplyAppearanceAndHideInvalidExternalUsers()
	
	// Design.
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemColorsDesign = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	ItemColorsDesign.Value = Metadata.StyleItems.InaccessibleDataColor.Value;
	ItemColorsDesign.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("ExternalUsersList.Invalid");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = True;
	DataFilterItem.Use  = True;
	
	ItemProcessedFields = ConditionalAppearanceItem.Fields.Items.Add();
	ItemProcessedFields.Field = New DataCompositionField("ExternalUsersList");
	ItemProcessedFields.Use = True;
	
	// Hide.
	CommonUseClientServer.SetFilterDynamicListItem(
		ExternalUsersList, "NotValid", False, , , True);
	
EndProcedure

&AtClient
Procedure CheckCurrentFormItemChange()
	
	If CurrentItem.Name <> CurrentItemName Then
		OnChangeCurrentFormItem();
		CurrentItemName = CurrentItem.Name;
	EndIf;
	
#If WebClient Or MobileClient Then
	AttachIdleHandler("CheckCurrentFormItemChange", 0.7, True);
#Else
	AttachIdleHandler("CheckCurrentFormItemChange", 0.1, True);
#EndIf
	
EndProcedure

&AtClient
Procedure OnChangeCurrentFormItem()
	
	If CurrentItem.Name = "ExternalUsersGroups" Then
		Items.Comments.CurrentPage = Items.GroupComment;
		
	ElsIf CurrentItem.Name = "ExternalUsersList" Then
		Items.Comments.CurrentPage = Items.UserComment;
		
	EndIf
	
EndProcedure

&AtServer
Procedure DeleteFromListSelected(DeleteAll = False)
	
	If DeleteAll Then
		SelectedUsersAndGroups.Clear();
		UpdateTitleFromListUsersAndGroupSelected();
		Return;
	EndIf;
	
	ListArrayOfItems = Items.ListOfSelectedUsersAndGroups.SelectedRows;
	For Each ItemOfList IN ListArrayOfItems Do
		SelectedUsersAndGroups.Delete(SelectedUsersAndGroups.FindByID(ItemOfList));
	EndDo;
	
	UpdateTitleFromListUsersAndGroupSelected();
	
EndProcedure

&AtClient
Procedure GetImagesAndFillSelectedList(ArrayChoiceItem)
	
	SelectedItemsAndPictures = New Array;
	For Each SelectedItem IN ArrayChoiceItem Do
		
		If TypeOf(SelectedItem) = Type("CatalogRef.ExternalUsers") Then
			PictureNumber = Items.ExternalUsersList.RowData(SelectedItem).PictureNumber;
		Else
			PictureNumber = Items.ExternalUsersGroups.RowData(SelectedItem).PictureNumber;
		EndIf;
		
		SelectedItemsAndPictures.Add(
			New Structure("SelectedItem, PictureNumber", SelectedItem, PictureNumber));
	EndDo;
	
	FillListSelectedUsersAndGroups(SelectedItemsAndPictures);
	
EndProcedure

&AtServer
Function ChoiceResult()
	
	SelectedUsersValuesTable = SelectedUsersAndGroups.Unload( , "User");
	UserArray = SelectedUsersValuesTable.UnloadColumn("User");
	Return UserArray;
	
EndFunction

&AtServer
Procedure ChangeParametersExtensionPickForm()
	
	// Import the list of selected user names.
	AnExtendedFormOfSelectionOptions = GetFromTempStorage(Parameters.AnExtendedFormOfSelectionOptions);
	SelectedUsersAndGroups.Load(AnExtendedFormOfSelectionOptions.SelectedUsers);
	SettingsStored.Insert("FormHeaderSelection", AnExtendedFormOfSelectionOptions.FormHeaderSelection);
	Users.FillUserPictureNumbers(SelectedUsersAndGroups, "User", "PictureNumber");
	// Set parameters of the extended selection form.
	Items.FinishAndClose.Visible                      = True;
	Items.GroupChooseUser.Visible              = True;
	// Make a list of selected user names visible.
	Items.SelectedUsersAndGroups.Visible           = True;
	If GetFunctionalOption("UseUsersGroups") Then
		Items.GroupsAndUsers.Group                 = ChildFormItemsGroup.Vertical;
		Items.GroupsAndUsers.ChildItemsWidth  = ChildFormItemsWidth.Equal;
		Items.ExternalUsersList.Height                = 5;
		Items.ExternalUsersGroups.Height               = 3;
		ThisObject.Height                                        = 17;
		Items.GroupChooseGroup.Visible                   = True;
		// Show headers of the UsersList and UsersGroups lists.
		Items.ExternalUsersGroups.TitleLocation   = FormItemTitleLocation.Top;
		Items.ExternalUsersList.TitleLocation    = FormItemTitleLocation.Top;
		Items.ExternalUsersList.Title             = NStr("en='Users in group';ru='Пользователи в группе';vi='Người sử dụng trong nhóm'");
		If AnExtendedFormOfSelectionOptions.Property("PickupGroupsIsNotPossible") Then
			Items.ChooseGroup.Visible                     = False;
		EndIf;
	Else
		Items.CancelUserSelection.Visible             = True;
		Items.ClearListSelected.Visible               = True;
	EndIf;
	
	// Add the number of selected users to the header of selected users and groups list.
	UpdateTitleFromListUsersAndGroupSelected();
	
EndProcedure

&AtServer
Procedure UpdateTitleFromListUsersAndGroupSelected()
	
	If SettingsStored.UseGroups Then
		TitleSelectedUsersAndGroups = NStr("en='Selected users and groups (%1)';ru='Выбранные пользователи и группы (%1)';vi='Người sử dụng và nhóm đã chọn (%1)'");
	Else
		TitleSelectedUsersAndGroups = NStr("en='Selected users (%1)';ru='Выбранные пользователи (%1)';vi='Người sử dụng đã chọn (%1)'");
	EndIf;
	
	UserCount = SelectedUsersAndGroups.Count();
	If UserCount <> 0 Then
		Items.ListOfSelectedUsersAndGroups.Title = StringFunctionsClientServer.SubstituteParametersInString(
			TitleSelectedUsersAndGroups, UserCount);
	Else
		
		If SettingsStored.UseGroups Then
			Items.ListOfSelectedUsersAndGroups.Title = NStr("en='Selected users and groups';ru='Выбранные пользователи и группы';vi='Người sử dụng và nhóm đã chọn'");
		Else
			Items.ListOfSelectedUsersAndGroups.Title = NStr("en='Selected users';ru='Выбранные пользователи';vi='Người sử dụng đã chọn'");
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillListSelectedUsersAndGroups(SelectedItemsAndPictures)
	
	For Each ArrayRow IN SelectedItemsAndPictures Do
		
		SelectedUserOrGroup = ArrayRow.SelectedItem;
		PictureNumber = ArrayRow.PictureNumber;
		
		FilterParameters = New Structure("User", SelectedUserOrGroup);
		Found = SelectedUsersAndGroups.FindRows(FilterParameters);
		If Found.Count() = 0 Then
			
			RowSelectedUsers = SelectedUsersAndGroups.Add();
			RowSelectedUsers.User = SelectedUserOrGroup;
			RowSelectedUsers.PictureNumber = PictureNumber;
			ThisObject.Modified = True;
			
		EndIf;
		
	EndDo;
	
	SelectedUsersAndGroups.Sort("User Asc");
	UpdateTitleFromListUsersAndGroupSelected();
	
EndProcedure

&AtClient
Procedure OnChangeUseOfUsersGroups()
	
	SetupFormByUsingUsersGroups();
	
EndProcedure

&AtServer
Procedure SetupFormByUsingUsersGroups()
	
	If SettingsStored.Property("CurrentRow") Then
		
		If TypeOf(Parameters.CurrentRow) = Type("CatalogRef.ExternalUsersGroups") Then
			
			If SettingsStored.UseGroups Then
				Items.ExternalUsersGroups.CurrentRow = SettingsStored.CurrentRow;
			Else
				Parameters.CurrentRow = Undefined;
			EndIf;
		Else
			CurrentItem = Items.ExternalUsersList;
			
			Items.ExternalUsersGroups.CurrentRow =
				Catalogs.ExternalUsersGroups.AllExternalUsers;
		EndIf;
	Else
		If Not SettingsStored.UseGroups
		   AND Items.ExternalUsersGroups.CurrentRow
		     <> Catalogs.UsersGroups.AllUsers Then
			
			Items.ExternalUsersGroups.CurrentRow =
				Catalogs.UsersGroups.AllUsers;
		EndIf;
	EndIf;
	
	Items.SelectHierarchy.Visible =
		SettingsStored.UseGroups;
	
	If SettingsStored.AdvancedSelection Then
		Items.AssignGroups.Visible = False;
	Else
		Items.AssignGroups.Visible = SettingsStored.UseGroups;
	EndIf;
	
	Items.CreateGroupOfExternalUsers.Visible =
		AccessRight("Insert", Metadata.Catalogs.ExternalUsersGroups)
		AND SettingsStored.UseGroups;
	
	ExternalUserGroupChoice = SettingsStored.ExternalUserGroupChoice
	                               AND SettingsStored.UseGroups
	                               AND Parameters.ChoiceMode;
	
	If Parameters.ChoiceMode Then
		
		Items.ChooseExternalUserGroup.Visible   = 
			?(SettingsStored.AdvancedSelection, False, ExternalUserGroupChoice);
		Items.ChooseExternalUser.DefaultButton =
			?(SettingsStored.AdvancedSelection, False, Not ExternalUserGroupChoice);
		Items.ChooseExternalUser.Visible         = Not SettingsStored.AdvancedSelection;
		
		AutoTitle = False;
		
		If Parameters.CloseOnChoice = False Then
			// Choice mode.
			
			If ExternalUserGroupChoice Then
				
				If SettingsStored.AdvancedSelection Then
					Title = SettingsStored.FormHeaderSelection;
				Else
					Title = NStr("en='Select external users and groups';ru='Подбор внешних пользователей и групп';vi='Chọn người sử dụng ngoài và nhóm'");
				EndIf;
				
				Items.ChooseExternalUser.Title =
					NStr("en='Selected external users';ru='Выбрать внешних пользователей';vi='Chọn người sử dụng ngoài'");
				
				Items.ChooseExternalUserGroup.Title =
					NStr("en='Selected groups';ru='Выбрать группы';vi='Chọn nhóm'");
				
			Else
				If SettingsStored.AdvancedSelection Then
					Title = SettingsStored.FormHeaderSelection;
				Else
					Title = NStr("en='Select external users';ru='Подбор внешних пользователей';vi='Chọn người sử dụng ngoài'");
				EndIf;
			EndIf;
		Else
			// Selection mode.
			If ExternalUserGroupChoice Then
				Title = NStr("en='Select external user or group';ru='Выбор внешнего пользователя или группы';vi='Chọn người sử dụng ngoài hoặc nhóm'");
				
				Items.ChooseExternalUser.Title = NStr("en='Selected external user';ru='Выбрать внешнего пользователя';vi='Chọn người sử dụng ngoài'");
			Else
				Title = NStr("en='Select internal user';ru='Выбор внешнего пользователя';vi='Chọn người sử dụng ngoài'");
			EndIf;
		EndIf;
	EndIf;
	
	RefreshFormContentOnGroupChange(ThisObject);
	
EndProcedure

&AtServer
Function UserTransferToNewGroup(UserArray, NewGroupOwner, Move)
	
	If NewGroupOwner = Undefined Then
		Return Undefined;
	EndIf;
	
	CurrentGroupOwner = Items.ExternalUsersGroups.CurrentRow;
	UserMessage = UsersService.UserTransferToNewGroup(
		UserArray, CurrentGroupOwner, NewGroupOwner, Move);
	
	Items.ExternalUsersList.Refresh();
	Items.ExternalUsersGroups.Refresh();
	
	Return UserMessage;
	
EndFunction

&AtClient
Procedure ToggleDisabledUsersView(ShowInvalid)
	
	CommonUseClientServer.SetFilterDynamicListItem(
		ExternalUsersList, "NotValid", False, , ,
		Not ShowInvalid);
	
EndProcedure

&AtClientAtServerNoContext
Procedure RefreshFormContentOnGroupChange(Form)
	
	Items = Form.Items;
	
	If Not Form.SettingsStored.UseGroups
	 OR Items.ExternalUsersGroups.CurrentRow = PredefinedValue(
	         "Catalog.ExternalUsersGroups.AllExternalUsers") Then
		
		RefreshDataCompositionParameterValue(
			Form.ExternalUsersList, "SelectHierarchy", True);
		
		RefreshDataCompositionParameterValue(
			Form.ExternalUsersList,
			"ExternalUserGroup",
			PredefinedValue("Catalog.ExternalUsersGroups.AllExternalUsers"));
	Else
	#If Server Then
		If ValueIsFilled(Items.ExternalUsersGroups.CurrentRow) Then
			CurrentData = CommonUse.ObjectAttributesValues(
				Items.ExternalUsersGroups.CurrentRow, "AllAuthorizationObjects");
		Else
			CurrentData = Undefined;
		EndIf;
	#Else
		CurrentData = Items.ExternalUsersGroups.CurrentData;
	#EndIf
		
		If CurrentData <> Undefined
		   AND CurrentData.AllAuthorizationObjects Then
			
			AuthorizationObjectTypePresentationItem =
				Form.SettingsStored.AuthorizationObjectsTypesPresentation.FindByValue(
					CurrentData.TypeOfAuthorizationObjects);
				
			RefreshDataCompositionParameterValue(
				Form.ExternalUsersList, "SelectHierarchy", True);
		Else
			RefreshDataCompositionParameterValue(
				Form.ExternalUsersList, "SelectHierarchy", Form.SelectHierarchy);
		EndIf;
		
		RefreshDataCompositionParameterValue(
			Form.ExternalUsersList,
			"ExternalUserGroup",
			Items.ExternalUsersGroups.CurrentRow);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure RefreshDataCompositionParameterValue(Val OwnerOfParameters,
                                                    Val ParameterName,
                                                    Val ParameterValue)
	
	For Each Parameter IN OwnerOfParameters.Parameters.Items Do
		If String(Parameter.Parameter) = ParameterName Then
			
			If Parameter.Use
			   AND Parameter.Value = ParameterValue Then
				
				Return;
			EndIf;
			Break;
			
		EndIf;
	EndDo;
	
	OwnerOfParameters.Parameters.SetParameterValue(ParameterName, ParameterValue);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Drag user names.

&AtClient
Procedure ExternalUsersGroupsDragQuestionProcessor(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	UserMessage = UserTransferToNewGroup(
		AdditionalParameters.DragParameters, AdditionalParameters.String, AdditionalParameters.Move);
	ExternalUsersGroupsDragEnd(UserMessage);
	
EndProcedure

&AtClient
Procedure ExternalUsersGroupsDragEnd(UserMessage)
	
	If UserMessage.Message = Undefined Then
		Return;
	EndIf;
	
	Notify("Write_ExternalUsersGroups");
	
	If UserMessage.HasErrors = False Then
		ShowUserNotification(
			NStr("en='Move users';ru='Перемещение пользователей';vi='Điều chuyển người sử dụng'"), , UserMessage.Message, PictureLib.Information32);
	Else
		
		If UserMessage.Users <> Undefined Then
			Report = NStr("en='The following users were not included in the selected group:';ru='Следующие пользователи не были включены в выбранную группу:';vi='Những người sử dụng sau không được đưa vào nhóm đã chọn:'");
			Report = Report + Chars.LF + UserMessage.Users;
			
			QuestionText = UserMessage.Message;
			
			Result = StandardSubsystemsClientServer.NewExecutionResult();
			OutputWarning = Result.OutputWarning;
			OutputWarning.Use = True;
			OutputWarning.Text = QuestionText;
			OutputWarning.ErrorsText = Report;
			StandardSubsystemsClient.ShowExecutionResult(ThisObject, Result);
		Else
			ShowMessageBox(,UserMessage.Message);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion
