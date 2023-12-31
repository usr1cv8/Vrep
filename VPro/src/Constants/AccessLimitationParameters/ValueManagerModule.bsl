#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region ServiceProgramInterface

// Updates access kind properties description
// in access limitation parameters while changing configuration.
// 
// Parameters:
//  HasChanges - Boolean (return value) - if there
//                  is a record, True is set, otherwise, it is not changed.
//
Procedure UpdateAccessKindsPropertiesDescription(HasChanges = Undefined, CheckOnly = False) Export
	
	SetPrivilegedMode(True);
	
	If CheckOnly OR ExclusiveMode() Then
		SwitchOffSoleMode = False;
	Else
		SwitchOffSoleMode = True;
		SetExclusiveMode(True);
	EndIf;
	
	AccessKindsProperties = AccessKindsProperties();
	
	Block = New DataLock;
	LockItem = Block.Add("Constant.AccessLimitationParameters");
	LockItem.Mode = DataLockMode.Exclusive;
	
	BeginTransaction();
	Try
		Block.Lock();
		
		Parameters = StandardSubsystemsServer.ApplicationWorkParameters(
			"AccessLimitationParameters");
		
		Saved = Undefined;
		
		If Parameters.Property("AccessKindsProperties") Then
			Saved = Parameters.AccessKindsProperties;
			
			If Not CommonUse.DataMatch(AccessKindsProperties, Saved) Then
				HasAndAccessValuesGroupTypesChanges =
					HasAndAccessValuesGroupTypesChanges(AccessKindsProperties, Saved);
				Saved = Undefined;
			EndIf;
		EndIf;
		
		If Saved = Undefined Then
			HasChanges = True;
			If CheckOnly Then
				CommitTransaction();
				Return;
			EndIf;
			StandardSubsystemsServer.SetApplicationPerformenceParameter(
				"AccessLimitationParameters",
				"AccessKindsProperties",
				AccessKindsProperties);
		EndIf;
		
		StandardSubsystemsServer.ConfirmUpdatingApplicationWorkParameter(
			"AccessLimitationParameters",
			"AccessKindsProperties");
		
		If Not CheckOnly Then
			StandardSubsystemsServer.AddChangesToApplicationPerformenceParameters(
				"AccessLimitationParameters",
				"GroupsAndAccessValuesTypes",
				?(HasAndAccessValuesGroupTypesChanges = True,
				  New FixedStructure("HasChanges", True),
				  New FixedStructure()) );
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		If SwitchOffSoleMode Then
			SetExclusiveMode(False);
		EndIf;
		Raise;
	EndTry;
	
	If SwitchOffSoleMode Then
		SetExclusiveMode(False);
	EndIf;
	
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

// Returns access kind properties filled in
// while implementing in the OnFillAccessKinds procedure of the general module.
// AccessManagementOverridable and corresponding procedures of a service event.
//
Function AccessKindsProperties()
	
	// 1. Fill in the data specified while embedding.
	
	AccessKinds = New ValueTable;
	AccessKinds.Columns.Add("Name",                    New TypeDescription("String"));
	AccessKinds.Columns.Add("Presentation",          New TypeDescription("String"));
	AccessKinds.Columns.Add("ValuesType",            New TypeDescription("Type"));
	AccessKinds.Columns.Add("ValueGroupType",       New TypeDescription("Type"));
	AccessKinds.Columns.Add("SeveralGroupsOfValues", New TypeDescription("Boolean"));
	AccessKinds.Columns.Add("AdditionalTypes",     New TypeDescription("ValueTable"));
	
	AccessTypeUsers = AccessKinds.Add();
	AccessKindExternalUsers = AccessKinds.Add();
	
	FillUnchangedAccessKindsPropertiesUsersAndExternalUsers(
		AccessTypeUsers, AccessKindExternalUsers);
	
	EventHandlers = CommonUse.ServiceEventProcessor(
		"StandardSubsystems.AccessManagement\OnFillAccessKinds");
	
	For Each Handler IN EventHandlers Do
		Handler.Module.OnFillAccessKinds(AccessKinds);
	EndDo;
	
	AccessManagementOverridable.OnFillAccessKinds(AccessKinds);
	
	FillUnchangedAccessKindsPropertiesUsersAndExternalUsers(
		AccessTypeUsers, AccessKindExternalUsers);
	
	// Checks:
	// - access values type is not specified for two access kinds
	// - the Users access values type, UsersGroups is used only for the Users access value.
	// the ExternalUsers access values type, ExternalUsersGroups is used only
	// for the ExternalUsers access value.
	// Object, Condition, RightSettings, ReadungRight, ChangeRight access kinds names are not specified.
	// Access groups type does not match to the values type.
	
	// 2. Prepare access kinds property collection used while application is working.
	PropertyArray         = New Array;
	ByRefs             = New Map;
	ByNames              = New Map;
	ByValuesTypes       = New Map;
	ByGroupsAndValuesTypes = New Map;
	
	AccessValuesWithGroups = New Structure;
	AccessValuesWithGroups.Insert("ByTypes",           New Map);
	AccessValuesWithGroups.Insert("ByRefsTypes",     New Map);
	AccessValuesWithGroups.Insert("TablesNames",       New Array);
	AccessValuesWithGroups.Insert("ValueGroupTypes", New Map);
	
	Parameters = New Structure;
	Parameters.Insert("DefinedAccessValuesType",
		AccessManagementServiceReUse.TypesTableFields("DefinedType.AccessValue"));
	
	ErrorTitle =
		NStr("en='An error occurred"
"in the FillAccessKindProperty procedure of the AccessManagementOverridable general module."
""
"';ru='Ошибка"
"в процедуре ЗаполнитьСвойстваВидаДоступа общего модуля УправлениеДоступомПереопределяемый."
""
"';vi='Lỗi"
"trong thủ tục ЗаполнитьСвойстваВидаДоступа của mô-đun chung"
"УправлениеДоступомПереопределяемый.'");
	
	Parameters.Insert("ErrorTitle", ErrorTitle);
	
	Parameters.Insert("SubscriptionTypesUpdateAccessValuesGroups",
		AccessManagementServiceReUse.TypesOfObjectsInSubscriptionsToEvents(
			"RefreshAccessValuesGroups"));
	
	AllAccessKindNames = New Map;
	AllAccessKindNames.Insert(Upper("Object"),         True);
	AllAccessKindNames.Insert(Upper("Condition"),        True);
	AllAccessKindNames.Insert(Upper("RightSettings"),  True);
	AllAccessKindNames.Insert(Upper("ReadRight"),    True);
	AllAccessKindNames.Insert(Upper("EditRight"), True);
	
	AllValueTypes      = New Map;
	AllValueGroupTypes = New Map;
	
	For Each AccessKind IN AccessKinds Do
		
		If AllAccessKindNames[Upper(AccessKind.Name)] <> Undefined Then
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				ErrorTitle +
				NStr("en='Name of access type ""%1"" was already defined.';ru='Имя вида доступа ""%1"" уже определено.';vi='Đã xác định tên dạng truy cập ""%1"".'"),
				AccessKind.Name);
		EndIf;
		
		// Check values and groups repetitions.
		CheckType(AccessKind, AccessKind.ValuesType,      AllValueTypes,      Parameters);
		CheckType(AccessKind, AccessKind.ValueGroupType, AllValueGroupTypes, Parameters, True);
		// Check values and groups intersection.
		CheckType(AccessKind, AccessKind.ValuesType,      AllValueGroupTypes, Parameters,       , True);
		CheckType(AccessKind, AccessKind.ValueGroupType, AllValueTypes,      Parameters, True, True);
		
		For Each String IN AccessKind.AdditionalTypes Do
			// Check values and groups repetitions.
			CheckType(AccessKind, String.ValuesType,      AllValueTypes,      Parameters);
			CheckType(AccessKind, String.ValueGroupType, AllValueGroupTypes, Parameters, True);
			// Check values and groups intersection.
			CheckType(AccessKind, String.ValuesType,      AllValueGroupTypes, Parameters,       , True);
			CheckType(AccessKind, String.ValueGroupType, AllValueTypes,      Parameters, True, True);
		EndDo;
		
		ValuesTypeEmptyRef = CommonUse.ObjectManagerByFullName(
			Metadata.FindByType(AccessKind.ValuesType).FullName()).EmptyRef();
		
		Properties = New Structure;
		Properties.Insert("Name",                      AccessKind.Name);
		Properties.Insert("Ref",                   ValuesTypeEmptyRef);
		Properties.Insert("Presentation",            AccessKind.Presentation);
		Properties.Insert("ValuesType",              AccessKind.ValuesType);
		Properties.Insert("ValueGroupType",         AccessKind.ValueGroupType);
		Properties.Insert("SeveralGroupsOfValues",   AccessKind.SeveralGroupsOfValues);
		Properties.Insert("AdditionalTypes",       New Array);
		Properties.Insert("SelectedValuesTypes",   New Array);
		
		PropertyArray.Add(Properties);
		ByNames.Insert(Properties.Name, Properties);
		ByRefs.Insert(ValuesTypeEmptyRef, Properties);
		ByValuesTypes.Insert(Properties.ValuesType, Properties);
		ByGroupsAndValuesTypes.Insert(Properties.ValuesType, Properties);
		If Properties.ValueGroupType <> Type("Undefined") Then
			ByGroupsAndValuesTypes.Insert(Properties.ValueGroupType, Properties);
		EndIf;
		FillAccessValuesWithGroups(Properties, AccessValuesWithGroups, Properties, Parameters);
		
		For Each String IN AccessKind.AdditionalTypes Do
			Item = New Structure;
			Item.Insert("ValuesType",            String.ValuesType);
			Item.Insert("ValueGroupType",       String.ValueGroupType);
			Item.Insert("SeveralGroupsOfValues", String.SeveralGroupsOfValues);
			Properties.AdditionalTypes.Add(Item);
			ByValuesTypes.Insert(String.ValuesType, Properties);
			ByGroupsAndValuesTypes.Insert(String.ValuesType, Properties);
			If String.ValueGroupType <> Type("Undefined") Then
				ByGroupsAndValuesTypes.Insert(String.ValueGroupType, Properties);
			EndIf;
			FillAccessValuesWithGroups(String, AccessValuesWithGroups, Properties, Parameters);
		EndDo;
		
	EndDo;
	
	WithoutGroupsForAccessValues      = New Array;
	WithOneGroupForAccessValue = New Array;
	AccessValueTypesWithGroups    = New Map;
	
	AccessKindsWithGroups = New Map;
	
	For Each KeyAndValue IN AccessValuesWithGroups.ByRefsTypes Do
		AccessTypeName = KeyAndValue.Value.Name;
		AccessKindsWithGroups.Insert(AccessTypeName, True);
		
		EmptyRef = AccessManagementService.MetadataObjectEmptyRef(KeyAndValue.Key);
		AccessValueTypesWithGroups.Insert(TypeOf(EmptyRef), EmptyRef);
		
		If Not KeyAndValue.Value.SeveralGroupsOfValues
		   AND WithOneGroupForAccessValue.Find(AccessTypeName) = Undefined Then
		   
			WithOneGroupForAccessValue.Add(AccessTypeName);
		EndIf;
	EndDo;
	
	AccessValueTypesWithGroups.Insert(Type("CatalogRef.Users"),
		Catalogs.Users.EmptyRef());
	
	AccessValueTypesWithGroups.Insert(Type("CatalogRef.UsersGroups"),
		Catalogs.UsersGroups.EmptyRef());
	
	AccessValueTypesWithGroups.Insert(Type("CatalogRef.ExternalUsers"),
		Catalogs.ExternalUsers.EmptyRef());
	
	AccessValueTypesWithGroups.Insert(Type("CatalogRef.ExternalUsersGroups"),
		Catalogs.ExternalUsersGroups.EmptyRef());
	
	For Each AccessTypeProperties IN PropertyArray Do
		If AccessKindsWithGroups.Get(AccessTypeProperties.Name) <> Undefined Then
			Continue;
		EndIf;
		If AccessTypeProperties.Name = "Users"
		 OR AccessTypeProperties.Name = "ExternalUsers" Then
			Continue;
		EndIf;
		WithoutGroupsForAccessValues.Add(AccessTypeProperties.Name);
	EndDo;
	
	AccessKindsProperties = New Structure;
	AccessKindsProperties.Insert("Array",                          PropertyArray);
	AccessKindsProperties.Insert("ByNames",                        ByNames);
	AccessKindsProperties.Insert("ByRefs",                       ByRefs);
	AccessKindsProperties.Insert("ByValuesTypes",                 ByValuesTypes);
	AccessKindsProperties.Insert("ByGroupsAndValuesTypes",           ByGroupsAndValuesTypes);
	AccessKindsProperties.Insert("AccessValuesWithGroups",        AccessValuesWithGroups);
	AccessKindsProperties.Insert("WithoutGroupsForAccessValues",      WithoutGroupsForAccessValues);
	AccessKindsProperties.Insert("WithOneGroupForAccessValue", WithOneGroupForAccessValue);
	AccessKindsProperties.Insert("AccessValueTypesWithGroups",    AccessValueTypesWithGroups);
	
	// Check the compatibility of transition to application new versions.
	If Parameters.DefinedAccessValuesType.Get(
		TypeOf(ChartsOfCharacteristicTypes.DeleteAccessKinds.EmptyRef())) = Undefined Then
	
		ErrorDescription =
			NStr("en='Type ChartOfCharacteristicTypesRef.DeleteAccessKinds"
"required to transfer to"
"the application new versions is not specified in the ""Access value"" determined type.';ru='Тип ПланВидовХарактеристикСсылка.УдалитьВидыДоступа, необходимый для перехода на новые версии программы не указан в определяемом типе ""Значение доступа"".';vi='Chưa chỉ ra kiểu ChartOfCharacteristicTypesRef.DeleteAccessKinds cần thiết để chuyển đổi sang phiên bản mới của chương trình trong kiểu xác định ""Giá trị truy cập"".'");
		
		Raise Parameters.ErrorTitle + ErrorDescription;
	EndIf;
	
	Return CommonUse.FixedData(AccessKindsProperties);
	
EndFunction

Procedure FillAccessValuesWithGroups(String, AccessValuesWithGroups, Properties, Parameters)
	
	If Properties.Name = "Users" Then
		AddToArray(Properties.SelectedValuesTypes, Type("CatalogRef.Users"));
		AddToArray(Properties.SelectedValuesTypes, Type("CatalogRef.UsersGroups"));
		Return;
	EndIf;
	
	If Properties.Name = "ExternalUsers" Then
		AddToArray(Properties.SelectedValuesTypes, Type("CatalogRef.ExternalUsers"));
		AddToArray(Properties.SelectedValuesTypes, Type("CatalogRef.ExternalUsersGroups"));
		Return;
	EndIf;
	
	If String.ValueGroupType = Type("Undefined") Then
		AddToArray(Properties.SelectedValuesTypes, String.ValuesType);
		Return;
	EndIf;
	
	ReferenceType = String.ValuesType;
	
	ValuesTypeMetadata = Metadata.FindByType(String.ValuesType);
	If CommonUse.IsEnum(ValuesTypeMetadata) Then
		ObjectType = ReferenceType;
	Else
		ObjectType = StandardSubsystemsServer.ObjectTypeOrSetOfMetadataObject(
			ValuesTypeMetadata);
	EndIf;
	
	If String.ValueGroupType <> Type("Undefined") Then
		AddToArray(Properties.SelectedValuesTypes, String.ValueGroupType);
	EndIf;
	
	AccessValuesWithGroups.ByTypes.Insert(ReferenceType,  Properties);
	AccessValuesWithGroups.ByTypes.Insert(ObjectType, Properties);
	AccessValuesWithGroups.ByRefsTypes.Insert(ReferenceType, Properties);
	AccessValuesWithGroups.TablesNames.Add(ValuesTypeMetadata.FullName());
	
	ValueGroupsTypeMetadata = Metadata.FindByType(String.ValueGroupType);
	ValueGroupsTypeEmptyRef =
		AccessManagementService.MetadataObjectEmptyRef(ValueGroupsTypeMetadata);
	
	AccessValuesWithGroups.ValueGroupTypes.Insert(ReferenceType, ValueGroupsTypeEmptyRef);
	AccessValuesWithGroups.ValueGroupTypes.Insert(
		AccessManagementService.MetadataObjectEmptyRef(ValuesTypeMetadata),
		ValueGroupsTypeEmptyRef);
	
	// Check whether there is a reference type in the corresponding metadata objects.
	If Parameters.SubscriptionTypesUpdateAccessValuesGroups.Get(ObjectType) = Undefined
	   AND Not CommonUse.IsEnum(ValuesTypeMetadata) Then
		
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			Parameters.ErrorTitle +
			NStr("en='Access value type ""%1"" that uses"
"value groups is not specified in the subscription to the ""Update access value groups"" event.';ru='Тип значения доступа ""%1"","
"использующий группы значений, не указан в подписке на событие ""Обновить группы значений доступа"".';vi='Chưa chỉ ra"
"kiểu giá trị truy cập ""%1"" sử dụng nhóm giá trị khi ghi nhận trong sự kiện ""Cập nhật nhóm giá trị truy cập"".'"),
			String(ObjectType));
	EndIf;
	
EndProcedure

Procedure FillUnchangedAccessKindsPropertiesUsersAndExternalUsers(
		AccessTypeUsers, AccessKindExternalUsers)
	
	AccessTypeUsers.Name                    = "Users";
	AccessTypeUsers.Presentation          = NStr("en='Users';ru='Пользователи';vi='Người sử dụng'");
	AccessTypeUsers.ValuesType            = Type("CatalogRef.Users");
	AccessTypeUsers.ValueGroupType       = Type("CatalogRef.UsersGroups");
	AccessTypeUsers.SeveralGroupsOfValues = True;
	
	AccessKindExternalUsers.Name                    = "ExternalUsers";
	AccessKindExternalUsers.Presentation          = NStr("en='External users';ru='Внешние пользователи';vi='Người sử dụng ngoài'");
	AccessKindExternalUsers.ValuesType            = Type("CatalogRef.ExternalUsers");
	AccessKindExternalUsers.ValueGroupType       = Type("CatalogRef.ExternalUsersGroups");
	AccessKindExternalUsers.SeveralGroupsOfValues = True;
	
EndProcedure

Procedure CheckType(AccessKind, Type, AllTypes, Parameters, GroupTypesCheck = False, CheckIntersection = False)
	
	If Type = Type("Undefined") Then
		If GroupTypesCheck Then
			Return;
		EndIf;
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			Parameters.ErrorTitle +
			NStr("en='Access value type is not specified for the ""%1"" access kind.';ru='Для вида доступа ""%1"" не указан тип значений доступа.';vi='Đối với dạng truy cập ""%1"" chưa chỉ ra kiểu giá trị truy cập.'"),
			AccessKind.Name);
	EndIf;
	
	// Check whether reference type is specified.
	If Not CommonUse.IsReference(Type) Then
		If GroupTypesCheck Then
			ErrorDescription =
				NStr("en='Type ""%1"" is specified as value groups type for the access kind ""%2""."
"But it is not reference type.';ru='Тип ""%1"" указан, как тип групп значений, для вида доступа ""%2""."
"Однако это не тип ссылки.';vi='Đã chỉ ra kiểu ""%1"" như là kiểu nhóm giá trị, đối với dạng truy cập ""%2""."
"Tuy nhiên đây không phải là kiểu tham chiếu.'");
		Else
			ErrorDescription =
				NStr("en='Type ""%1"" is specified as values type for the access kind ""%2""."
"But it is not reference type.';ru='Тип ""%1"" указан, как тип значений, для вида доступа ""%2""."
"Однако это не тип ссылки.';vi='Đã chỉ ra kiểu ""%1"" như là kiểu giá trị đối với dạng truy cập ""%2""."
"Tuy nhiên đây không phải là kiểu tham chiếu.'");
		EndIf;
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			Parameters.ErrorTitle + ErrorDescription, Type, AccessKind.Name);
	EndIf;
	
	// Check repetition and intersection of the value types and value groups.
	ForSameAccessTypeNoError = False;
	
	If GroupTypesCheck Then
		If CheckIntersection Then
			ErrorDescription =
				NStr("en='Type ""%1"" is specified as values type for the access kind ""%2""."
"For the access kind ""%3"" it can not be specified as values group type.';ru='Тип ""%1"" указан, как тип значений, для вида доступа ""%2""."
"Для вида доступа ""%3"" его нельзя указать, как тип групп значений.';vi='Đã chỉ ra kiểu ""%1"" như là kiểu giá trị, đối với dạng truy cập ""%2""."
"Đối với dạng truy cập ""%3"" không nên chỉ ra kiểu đó như là kiểu nhóm giá trị.'");
		Else
			ForSameAccessTypeNoError = True;
			ErrorDescription =
				NStr("en='Value groups type ""%1"" is specified for the access kind ""%2""."
"For the access kind ""%3"" it can not be specified.';ru='Тип групп значений ""%1"" уже указан для вида доступа ""%2""."
"Для вида доступа ""%3"" его нельзя указать.';vi='Đã chỉ ra kiểu giá trị ""%1"" đối với dạng truy cập ""%2""."
"Đối với dạng truy cpaj ""%3"" không cần chỉ ra kiểu này.'");
		EndIf;
	Else
		If CheckIntersection Then
			ErrorDescription =
				NStr("en='Type ""%1"" is specified as value groups type for the access kind ""%2""."
"For the access kind ""%3"" it can not be specified as values type.';ru='Тип ""%1"" указан, как тип групп значений, для вида доступа ""%2""."
"Для вида доступа ""%3"" его нельзя указать, как тип значений.';vi='Đã chỉ ra kiểu ""%1"" như là kiểu nhóm giá trị, đối với dạng truy cập ""%2""."
"Đối với dạng truy cập ""%3"" không thể chỉ ra kiểu này như là kiểu giá trị.'");
		Else
			ErrorDescription =
				NStr("en='Values type ""%1"" is specified for the access kind ""%2""."
"For the access kind ""%3"" it can not be specified.';ru='Тип значений ""%1"" уже указан для вида доступа ""%2""."
"Для вида доступа ""%3"" его нельзя указать.';vi='Đã chỉ ra kiểu giá trị ""%1"" đối với dạng truy cập ""%2""."
"Đối với dạng truy cập ""%3"" không cần chỉ ra kiểu này.'");
		EndIf;
	EndIf;
	
	If AllTypes.Get(Type) <> Undefined Then
		If Not (ForSameAccessTypeNoError AND AccessKind.Name = AllTypes.Get(Type)) Then
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				Parameters.ErrorTitle + ErrorDescription, Type, AllTypes.Get(Type), AccessKind.Name);
		EndIf;
	ElsIf Not CheckIntersection Then
		AllTypes.Insert(Type, AccessKind.Name);
	EndIf;
	
	// Check defined types content.
	ErrorDescription = "";
	If Parameters.DefinedAccessValuesType.Get(Type) = Undefined Then
		If GroupTypesCheck Then
			ErrorDescription =
				NStr("en='Access value groups type ""%1"" of the"
"access kind ""%2"" is not specified in the ""Access value"" defined type.';ru='Тип групп значений доступа"
"""%1"" вида доступа ""%2"" не указан в определяемом типе ""Значение доступа"".';vi='Kiểu nhóm giá trị truy cập"
"""%1"" dạng truy cập ""%2"" chưa được chỉ ra trong kiểu ""Giá trị truy cập"".'");
		Else
			ErrorDescription =
				NStr("en='Access value type ""%1"" of the"
"access kind ""%2"" is specified in the ""Access value"" defined type.';ru='Тип значений доступа"
"""%1"" вида доступа ""%2"" не указан в определяемом типе ""Значение доступа"".';vi='Chưa chỉ ra kiểu giá trị truy cập"
"""%1"" của dạng truy cập ""%2"" trong kiểu xác định ""Giá trị truy cập"".'");
		EndIf;
	EndIf;
	
	If ValueIsFilled(ErrorDescription) Then
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			Parameters.ErrorTitle + ErrorDescription,
			Type,
			AccessKind.Name);
	EndIf;
	
EndProcedure

Procedure AddToArray(Array, Value)
	
	If Array.Find(Value) = Undefined Then
		Array.Add(Value);
	EndIf;
	
EndProcedure

// Checks whether there are changes of the group types and access values.
Function HasAndAccessValuesGroupTypesChanges(AccessKindsProperties, Saved)
	
	If Not TypeOf(Saved) = Type("FixedStructure")
	 OR Not Saved.Property("ByValuesTypes")
	 OR Not Saved.Property("AccessValueTypesWithGroups")
	 OR Not TypeOf(Saved.ByValuesTypes)              = Type("FixedMap")
	 OR Not TypeOf(Saved.AccessValueTypesWithGroups) = Type("FixedMap")
	 OR Not AccessKindsProperties.Property("ByValuesTypes")
	 OR Not AccessKindsProperties.Property("AccessValueTypesWithGroups")
	 OR Not TypeOf(AccessKindsProperties.ByValuesTypes)              = Type("FixedMap")
	 OR Not TypeOf(AccessKindsProperties.AccessValueTypesWithGroups) = Type("FixedMap") Then
	
		Return True;
	EndIf;
	
	If MatchKeysDiffer(AccessKindsProperties.ByValuesTypes, Saved.ByValuesTypes) Then
		Return True;
	EndIf;
	
	If MatchKeysDiffer(AccessKindsProperties.AccessValueTypesWithGroups,
			Saved.AccessValueTypesWithGroups) Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

Function MatchKeysDiffer(NewItem, Old)
	
	If NewItem.Count() <> Old.Count() Then
		Return True;
	EndIf;
	
	For Each KeyAndValue IN NewItem Do
		If Old.Get(KeyAndValue.Key) = Undefined Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

#EndRegion

#EndIf
