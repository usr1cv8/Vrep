#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

////////////////////////////////////////////////////////////////////////////////
// SERVICE VARIABLES

Var OldParent; // Group parent value before
                      // change to use in event handler OnWrite.

Var OldCompositionOfExternalUsersGroup; // Content of external
                                              // users of the external user
                                              // group before change for the use in OnWrite event handler.

Var FormerExternalUserGroupRolesSet; // Content of the
                                                   // roles of external user group before
                                                   // change for the use in OnWrite event handler.

Var FormerValueAllAuhorizationObjects; // Value of
                                           // attribute AllAuthorizationObjects before change for
                                           // the use in OnWrite event handler.

Var IsNew; // Shows that a new object was written.
                // It is used in event handler OnWrite.

#Region EventsHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If AdditionalProperties.Property("CheckedObjectAttributes") Then
		CheckedObjectAttributes = AdditionalProperties.CheckedObjectAttributes;
	Else
		CheckedObjectAttributes = New Array;
	EndIf;
	
	Errors = Undefined;
	
	// Parent use checking.
	If Parent = Catalogs.ExternalUsersGroups.AllExternalUsers Then
		CommonUseClientServer.AddUserError(Errors,
			"Object.Parent",
			NStr("en='Predefined group ""All external users"" cannot be a parent group.';ru='Предопределенная группа ""Все внешние пользователи"" не может быть родителем.';vi='Nhóm định trước ""Tất cả người sử dụng ngoài"" không thể là lớp trên.'"),
			"");
	EndIf;
	
	// Check of the unfilled and repetitive external users.
	CheckedObjectAttributes.Add("Content.ExternalUser");
	
	For Each CurrentRow IN Content Do
		LineNumber = Content.IndexOf(CurrentRow);
		
		// Value fill checking.
		If Not ValueIsFilled(CurrentRow.ExternalUser) Then
			CommonUseClientServer.AddUserError(Errors,
				"Object.Content[%1].ExternalUser",
				NStr("en='External user is not selected.';ru='Внешний пользователь не выбран.';vi='Người sử dụng ngoài chưa chọn.'"),
				"Object.Content",
				LineNumber,
				NStr("en='External user in line %1 was not selected.';ru='Внешний пользователь в строке %1 не выбран.';vi='Người sử dụng ngoài trong dòng %1 chưa chọn.'"));
			Continue;
		EndIf;
		
		// Checking existence of duplicate values.
		FoundValues = Content.FindRows(New Structure("ExternalUser", CurrentRow.ExternalUser));
		If FoundValues.Count() > 1 Then
			CommonUseClientServer.AddUserError(Errors,
				"Object.Content[%1].ExternalUser",
				NStr("en='External user is repeated.';ru='Внешний пользователь повторяется.';vi='Người sử dụng ngoài lặp lại.'"),
				"Object.Content",
				LineNumber,
				NStr("en='External user in line %1 is repeated.';ru='Внешний пользователь в строке %1 повторяется.';vi='Người sử dụng ngoài trong dòng %1 lặp lại.'"));
		EndIf;
	EndDo;
	
	CommonUseClientServer.ShowErrorsToUser(Errors, Cancel);
	
	CommonUse.DeleteUnverifiableAttributesFromArray(CheckedAttributes, CheckedObjectAttributes);
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not UsersService.BanEditOfRoles() Then
		QueryResult = CommonUse.ObjectAttributeValue(Ref, "Roles");
		If TypeOf(QueryResult) = Type("QueryResult") Then
			FormerExternalUserGroupRolesSet = QueryResult.Unload();
		Else
			FormerExternalUserGroupRolesSet = Roles.Unload(New Array);
		EndIf;
	EndIf;
	
	IsNew = IsNew();
	
	If Ref = Catalogs.ExternalUsersGroups.AllExternalUsers Then
		
		TypeOfAuthorizationObjects = Undefined;
		AllAuthorizationObjects  = False;
		
		If Not Parent.IsEmpty() Then
			Raise
				NStr("en='Predefined group ""All external users"" cannot be moved.';ru='Предопределенная группа ""Все внешние пользователи"" не может быть перемещена.';vi='Nhóm định trước ""Tất cả người sử dụng ngoài"" không điều chuyển được.'");
		EndIf;
		If Content.Count() > 0 Then
			Raise
				NStr("en='Adding participants to predefined group ""All external users"" is forbidden.';ru='Добавление участников в предопределенную группу ""Все внешние пользователи"" запрещено.';vi='Cấm thêm người tham gia vào nhóm định trước ""Tất cả người sử dụng ngoài"".'");
		EndIf;
	Else
		If Parent = Catalogs.ExternalUsersGroups.AllExternalUsers Then
			Raise
				NStr("en='Cannot add subgroup to the predefined group ""All external users"".';ru='Невозможно добавить подгруппу к предопределенной группе ""Все внешние пользователи"".';vi='Không thể thêm nhóm con vào nhóm định trước ""Tất cả người sử dụng ngoài"".'");
		ElsIf Parent.AllAuthorizationObjects Then
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en='Cannot add a subgroup to the ""%1"" group because it includes all users.';ru='Невозможно добавить подгруппу к группе ""%1"", так как в число ее участников входят все пользователи.';vi='Không thể thêm nhóm con vào nhóm ""%1"" bởi vì trong số những người tham gia của nhóm bao gồm tất cả người sử dụng.'"), Parent);
		EndIf;
		
		If TypeOfAuthorizationObjects = Undefined Then
			AllAuthorizationObjects = False;
			
		ElsIf AllAuthorizationObjects
		        AND ValueIsFilled(Parent) Then
			
			Raise
				NStr("en='Cannot move the group that includes all users.';ru='Невозможно переместить группу, в число участников которой входят все пользователи.';vi='Không thể điều chuyển nhóm mà có tất cả người sử dụng.'");
		EndIf;
		
		// Check for uniqueness of a group of all authorization objects of the specified type.
		If AllAuthorizationObjects Then
			
			Query = New Query;
			Query.SetParameter("Ref", Ref);
			Query.SetParameter("TypeOfAuthorizationObjects", TypeOfAuthorizationObjects);
			Query.Text =
			"SELECT
			|	PRESENTATION(ExternalUsersGroups.Ref) AS RefPresentation
			|FROM
			|	Catalog.ExternalUsersGroups AS ExternalUsersGroups
			|WHERE
			|	ExternalUsersGroups.Ref <> &Ref
			|	AND ExternalUsersGroups.TypeOfAuthorizationObjects = &TypeOfAuthorizationObjects
			|	AND ExternalUsersGroups.AllAuthorizationObjects";
			
			QueryResult = Query.Execute();
			If Not QueryResult.IsEmpty() Then
			
				Selection = QueryResult.Select();
				Selection.Next();
				Raise StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en='The ""%1"" group already exists and includes all users of the ""%2"" kind.';ru='Уже существует группа ""%1"", в число участников которой входят все пользователи вида ""%2"".';vi='Đã có nhóm ""%1"", trong đó người tham gia nhóm này là tất cả người sử dụng của nhóm ""%2""'"),
					Selection.RefPresentation,
					TypeOfAuthorizationObjects.Metadata().Synonym);
			EndIf;
		EndIf;
		
		// Checking the matches of authorization object
		// types with the parent (valid if the type of parent is not specified).
		If ValueIsFilled(Parent) Then
			
			ParentAuthorizationObjectType = CommonUse.ObjectAttributeValue(
				Parent, "TypeOfAuthorizationObjects");
			
			If ParentAuthorizationObjectType <> Undefined
			   AND ParentAuthorizationObjectType <> TypeOfAuthorizationObjects Then
				
				Raise StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en='Kind of participants shall be"
"""%1"" as in the upstream group of external users ""%2"".';ru='Вид участников группы должен"
"быть ""%1"", как у вышестоящей группы внешних пользователей ""%2"".';vi='Dạng người tham gia nhóm phải là"
"""%1"" như trong nhóm người sử dụng ngoài phía trên ""%2"".'"),
					ParentAuthorizationObjectType.Metadata().Synonym,
					Parent);
			EndIf;
		EndIf;
		
		// If in the external user group the type of participants
		// is set to "All users of specified type", check the existence of subordinate groups.
		If AllAuthorizationObjects
			AND ValueIsFilled(Ref) Then
			Query = New Query;
			Query.SetParameter("Ref", Ref);
			Query.Text =
			"SELECT
			|	PRESENTATION(ExternalUsersGroups.Ref) AS RefPresentation
			|FROM
			|	Catalog.ExternalUsersGroups AS ExternalUsersGroups
			|WHERE
			|	ExternalUsersGroups.Parent = &Ref";
			
			QueryResult = Query.Execute();
			If Not QueryResult.IsEmpty() Then
				Raise StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en='Cannot change a kind"
"of participants of group ""%1"" as it has subgroups.';ru='Невозможно изменить"
"вид участников группы ""%1"", так как у нее имеются подгруппы.';vi='Không thể thay đổi"
"dạng người tham gia nhóm ""%1"", bởi vì nhóm này có những nhóm con.'"),
					Description);
			EndIf;
			
		EndIf;
		
		// Check that during the change
		// of types of authorization objects there are no subordinate items of other type (type clearing is possible).
		If TypeOfAuthorizationObjects <> Undefined
		   AND ValueIsFilled(Ref) Then
			
			Query = New Query;
			Query.SetParameter("Ref", Ref);
			Query.SetParameter("TypeOfAuthorizationObjects", TypeOfAuthorizationObjects);
			Query.Text =
			"SELECT
			|	PRESENTATION(ExternalUsersGroups.Ref) AS RefPresentation,
			|	ExternalUsersGroups.TypeOfAuthorizationObjects
			|FROM
			|	Catalog.ExternalUsersGroups AS ExternalUsersGroups
			|WHERE
			|	ExternalUsersGroups.Parent = &Ref
			|	AND ExternalUsersGroups.TypeOfAuthorizationObjects <> &TypeOfAuthorizationObjects";
			
			QueryResult = Query.Execute();
			If Not QueryResult.IsEmpty() Then
				
				Selection = QueryResult.Select();
				Selection.Next();
				
				If Selection.TypeOfAuthorizationObjects = Undefined Then
					OtherAuthorizationObjectTypePresentation = NStr("en='Any user';ru='Любой пользователь';vi='Người sử dụng bất kỳ'");
				Else
					OtherAuthorizationObjectTypePresentation =
						Selection.TypeOfAuthorizationObjects.Metadata().Synonym;
				EndIf;
				Raise StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en='Cannot change a kind"
"of participants of group ""%1"" as it has subgroup ""%2"" with another kind of participants ""%3"".';ru='Невозможно"
"изменить вид участников группы ""%1"", так как у нее имеется подгруппа ""%2"" с другим видом участников ""%3"".';vi='Không thể"
"thay đổi dạng người tham gia nhóm ""%1"", bởi vì trong nhóm có nhóm con ""%2"" với dạng người tham gia khác ""%3"".'"),
					Description,
					Selection.RefPresentation,
					OtherAuthorizationObjectTypePresentation);
			EndIf;
		EndIf;
		
		OldValues = CommonUse.ObjectAttributesValues(
			Ref, "AllAuthorizationObjects, Parent");
		
		OldParent                      = OldValues.Parent;
		FormerValueAllAuhorizationObjects = OldValues.AllAuthorizationObjects;
		
		If ValueIsFilled(Ref)
		   AND Ref <> Catalogs.ExternalUsersGroups.AllExternalUsers Then
			
			QueryResult = CommonUse.ObjectAttributeValue(Ref, "Content");
			If TypeOf(QueryResult) = Type("QueryResult") Then
				OldCompositionOfExternalUsersGroup = QueryResult.Unload();
			Else
				OldCompositionOfExternalUsersGroup = Content.Unload(New Array);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If UsersService.BanEditOfRoles() Then
		IsExternalUserGroupRoleContentChanged = False;
		
	Else
		IsExternalUserGroupRoleContentChanged =
			UsersService.ColumnValuesDifferences(
				"Role",
				Roles.Unload(),
				FormerExternalUserGroupRolesSet).Count() <> 0;
	EndIf;
	
	ParticipantsOfChange = New Map;
	ChangedGroups   = New Map;
	
	If Ref <> Catalogs.ExternalUsersGroups.AllExternalUsers Then
		
		If AllAuthorizationObjects
		 OR FormerValueAllAuhorizationObjects = True Then
			
			UsersService.UpdateExternalUsersGroupsStaves(
				Ref, , ParticipantsOfChange, ChangedGroups);
		Else
			StaffChange = UsersService.ColumnValuesDifferences(
				"ExternalUser",
				Content.Unload(),
				OldCompositionOfExternalUsersGroup);
			
			UsersService.UpdateExternalUsersGroupsStaves(
				Ref, StaffChange, ParticipantsOfChange, ChangedGroups);
			
			If OldParent <> Parent Then
				
				If ValueIsFilled(Parent) Then
					UsersService.UpdateExternalUsersGroupsStaves(
						Parent, , ParticipantsOfChange, ChangedGroups);
				EndIf;
				
				If ValueIsFilled(OldParent) Then
					UsersService.UpdateExternalUsersGroupsStaves(
						OldParent, , ParticipantsOfChange, ChangedGroups);
				EndIf;
			EndIf;
		EndIf;
		
		UsersService.RefreshUsabilityRateOfUsersGroups(
			Ref, ParticipantsOfChange, ChangedGroups);
	EndIf;
	
	If IsExternalUserGroupRoleContentChanged Then
		UsersService.RefreshRolesOfExternalUsers(Ref);
	EndIf;
	
	UsersService.AfterExternalUsersGroupsStavesUpdating(
		ParticipantsOfChange, ChangedGroups);
	
	UsersService.AfterUserOrGroupChangeAdding(Ref, IsNew);
	
EndProcedure

#EndRegion

#EndIf