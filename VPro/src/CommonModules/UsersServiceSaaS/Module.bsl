///////////////////////////////////////////////////////////////////////////////////
// Users in the service model subsystem.
// 
///////////////////////////////////////////////////////////////////////////////////

#Region ServiceProgramInterface

// Returns check box of users actions availability.
//
// Returns:
// Boolean - True if users change is available, otherwise, False.
//
Function CanChangeUsers() Export
	
	Return Constants.InfobaseUsageMode.Get() 
		<> Enums.InfobaseUsageModes.Demo;
	
EndFunction

// Returns actions available to the current
// user with the specified service user.
//
// Parameters:
//  User - CatalogRef.Users - user
//   available actions with which are required to be received. If not specified,
//   the application checks available actions with the current user.
//  ServiceUserPassword - String - current user password
//   for access the service.
//  
Function GetActionsWithServiceUser(Val User = Undefined) Export
	
	If User = Undefined Then
		User = Users.CurrentUser();
	EndIf;
	
	If CanChangeUsers() Then
		
		If InfobaseUsers.CurrentUser().DataSeparation.Count() = 0 Then
			
			Return ActionsWithServiceUserWhenUserSettingIsUnavailable();
			
		ElsIf ItIsCurrentDataAreaExistingUser(User) Then
			
			Return ActionsWithExistentServiceUser(User);
			
		Else
			
			If IsRightToAddUsers() Then
				Return ActionsWithNewServiceUser();
			Else
				Raise NStr("en='Insufficient access rights to add users';ru='Недостаточно прав доступа для добавления новых пользователей';vi='Không đủ quyền truy cập để thêm người sử dụng mới'");
			EndIf;
			
		EndIf;
		
	Else
		
		Return ActionsWithServiceUserWhenUserSettingIsUnavailable();
		
	EndIf;
	
EndFunction

// Generates a query on change
// email address of the service user.
//
// Parameters:
//  NewEmail - String - user’s new email address.
//  User - CatalogRef.Users - user
//   which email address should be changed.
//  ServiceUserPassword - String - current user
//   password for access to service manager.
//
Procedure CreateRequestToChangeEmail(Val NewEmail, Val User, Val ServiceUserPassword) Export
	
	SetPrivilegedMode(True);
	Proxy = SaaSOperations.GetServiceManagerProxy(ServiceUserPassword);
	SetPrivilegedMode(False);
	
	ErrorInfo = Undefined;
	Proxy.RequestEmailChange(
		CommonUse.ObjectAttributeValue(User, "ServiceUserID"), 
		NewEmail, 
		ErrorInfo);
	ProcessInformationAboutWebServiceError(ErrorInfo, "RequestEmailChange"); // The operation name is not localized.
	
EndProcedure

// Creates / updates service user details.
// 
// Parameters:
//  User - CatalogRef.Users/CatalogObject.Users
//  CreateServiceUser - Boolean - True - create
//   a new service user, False - update the existing one.
//  ServiceUserPassword - String - current user
//   password for access to service manager.
//
Procedure RecordServiceUser(Val User, Val CreateServiceUser, Val ServiceUserPassword) Export
	
	If TypeOf(User) = Type("CatalogRef.Users") Then
		UserObject = User.GetObject();
	Else
		UserObject = User;
	EndIf;
	
	SetPrivilegedMode(True);
	Proxy = SaaSOperations.GetServiceManagerProxy(ServiceUserPassword);
	SetPrivilegedMode(False);
	
	If ValueIsFilled(UserObject.InfobaseUserID) Then
		IBUser = InfobaseUsers.FindByUUID(UserObject.InfobaseUserID);
		AccessPermitted = IBUser <> Undefined;
	Else
		AccessPermitted = False;
	EndIf;
	
	ServiceUser = Proxy.XDTOFactory.Create(
		Proxy.XDTOFactory.Type("http://www.1c.ru/SaaS/ApplicationUsers", "User"));
	ServiceUser.Zone = SaaSOperations.SessionSeparatorValue();
	ServiceUser.UserServiceID = UserObject.ServiceUserID;
	ServiceUser.FullName = UserObject.Description;
	
	If AccessPermitted Then
		ServiceUser.Name = IBUser.Name;
		ServiceUser.StoredPasswordValue = IBUser.StoredPasswordValue;
		ServiceUser.Language = GetLanguageCode(IBUser.Language);
		ServiceUser.Access = True;
		ServiceUser.AdmininstrativeAccess = IBUser.Roles.Contains(Metadata.Roles.FullRights);
	Else
		ServiceUser.Name = "";
		ServiceUser.StoredPasswordValue = "";
		ServiceUser.Language = "";
		ServiceUser.Access = False;
		ServiceUser.AdmininstrativeAccess = False;
	EndIf;
	
	ContactInformation = Proxy.XDTOFactory.Create(
		Proxy.XDTOFactory.Type("http://www.1c.ru/SaaS/ApplicationUsers", "ContactsList"));
		
	TypeCIRecord = Proxy.XDTOFactory.Type("http://www.1c.ru/SaaS/ApplicationUsers", "ContactsItem");
	
	For Each CIRow IN UserObject.ContactInformation Do
		XDTOCIKind = SaaSReUse.AccordanceOfUserCITypesXDTO().Get(CIRow.Type);
		If XDTOCIKind = Undefined Then
			Continue;
		EndIf;
		
		WriteKEY = Proxy.XDTOFactory.Create(TypeCIRecord);
		WriteKEY.ContactType = XDTOCIKind;
		WriteKEY.Value = CIRow.Presentation;
		WriteKEY.Parts = CIRow.FieldsValues;
		
		ContactInformation.Item.Add(WriteKEY);
	EndDo;
	
	ServiceUser.Contacts = ContactInformation;
	
	ErrorInfo = Undefined;
	If CreateServiceUser Then
		Proxy.CreateUser(ServiceUser, ErrorInfo);
		ProcessInformationAboutWebServiceError(ErrorInfo, "CreateUser"); // The operation name is not localized.
	Else
		Proxy.UpdateUser(ServiceUser, ErrorInfo);
		ProcessInformationAboutWebServiceError(ErrorInfo, "UpdateUser"); // The operation name is not localized.
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Infobase user processing when writing the Users or ExternalUsers catalog items.

// It is called from the StartInfobaseUserProcessing procedure to support the service model.
Procedure BeforeStartIBUserProcessor(UserObject, ProcessingParameters) Export
	
	If Not CommonUseReUse.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	AdditionalProperties = UserObject.AdditionalProperties;
	OldUser     = ProcessingParameters.OldUser;
	AutoAttributes          = ProcessingParameters.AutoAttributes;
	
	If TypeOf(UserObject) = Type("CatalogObject.ExternalUsers")
	   AND CommonUseReUse.DataSeparationEnabled() Then
		
		Raise NStr("en='External users are not supported in SaaS.';ru='Внешние пользователи не поддерживаются в модели сервиса.';vi='Không hỗ trợ người sử dụng ngoài trong mô hình dịch vụ.'");
	EndIf;
	
	AutoAttributes.Insert("ServiceUserID", OldUser.ServiceUserID);
	
	If AdditionalProperties.Property("RemoteAdministrationChannelMessageProcessing") Then
		
		If Not CommonUseReUse.SessionWithoutSeparator() Then
			Raise
				NStr("en='Only undivided"
"users can be"
"updated upon messages via the remote administration channel.';ru='Обновление"
"пользователя по"
"сообщению канала удаленного администрирования доступно только неразделенным пользователям.';vi='Chỉ có người sử dụng"
"không chia tách mới có thể"
"cập nhật người sử dụng"
"theo thông báo của kênh quản trị từ xa.'");
		EndIf;
		
		ProcessingParameters.Insert("RemoteAdministrationChannelMessageProcessing");
		AutoAttributes.ServiceUserID = UserObject.ServiceUserID;
		
	ElsIf Not UserObject.Service Then
		UpdateServiceManagerWebServiceDescription();
	EndIf;
	
	If ValueIsFilled(AutoAttributes.ServiceUserID)
	   AND AutoAttributes.ServiceUserID <> OldUser.ServiceUserID Then
		
		If ValueIsFilled(OldUser.ServiceUserID) Then
			
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en='An error occurred while writing user %1."
"You can not modify"
"the service user ID already set in a catalog item.';ru='Ошибка при записи пользователя ""%1""."
"Нельзя изменять"
"уже установленный идентификатор пользователя сервиса в элементе справочника.';vi='Lỗi khi ghi lại người sử dụng ""%1""."
"Không thể thay đổi"
"tên (ID) người sử dụng Service đã thiết lập trong phần tử danh mục.'"),
				UserObject.Description);
			
		EndIf;
		
		FoundUser = Undefined;
		
		If UsersService.UserByIDExists(
				AutoAttributes.ServiceUserID,
				UserObject.Ref,
				FoundUser,
				True) Then
			
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en='An error occurred while writing user %1."
"You can not"
"set the service"
"user identifier ""%2"" to this catalog item, because it"
"is already used in the item ""%3"".';ru='Ошибка при записи пользователя ""%1""."
"Нельзя устанавливать идентификатор"
"пользователя сервиса ""%2"""
"в этот элемент справочника, т.к. он"
"уже используется в элементе ""%3"".';vi='Lỗi khi ghi người sử dụng ""%1""."
"Không nên thiết lập tên người sử dụng dịch vụ ""%2"""
"vào phần tử danh mục này, bởi vì"
"đã sử dụng nó trong phần tử ""%3"".'"),
				UserObject.Description,
				AutoAttributes.ServiceUserID,
				FoundUser);
		EndIf;
	EndIf;
	
EndProcedure

// It is called from the StartInfobaseUserProcessing procedure to support the service model.
Procedure AfterStartIBUserProcessor(UserObject, ProcessingParameters) Export
	
	If Not CommonUseReUse.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	AutoAttributes = ProcessingParameters.AutoAttributes;
	
	ProcessingParameters.Insert("CreateServiceUser", False);
	
	If ProcessingParameters.NewIBUserExist
	   AND CommonUseReUse.DataSeparationEnabled() Then
		
		If Not ValueIsFilled(AutoAttributes.ServiceUserID) Then
			
			ProcessingParameters.Insert("CreateServiceUser", True);
			UserObject.ServiceUserID = New UUID;
			
			// Update attribute value controlled during the record.
			AutoAttributes.ServiceUserID = UserObject.ServiceUserID;
		EndIf;
	EndIf;
	
EndProcedure

// It is called from the EndInfobaseUserProcessing procedure to support the service model.
Procedure BeforeEndUserIBUserProcessor(UserObject, ProcessingParameters) Export
	
	If Not CommonUseReUse.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	AutoAttributes = ProcessingParameters.AutoAttributes;
	
	If AutoAttributes.ServiceUserID <> UserObject.ServiceUserID Then
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='An error occurred while writing user %1."
"Changing the ServiceUserID attribute is not permitted."
"Attribute update is performed automatically.';ru='Ошибка при записи пользователя ""%1""."
"Реквизит ИдентификаторПользователяСервиса не допускается изменять."
"Обновление реквизита выполняется автоматически.';vi='Lỗi khi ghi người sử dụng ""%1""."
"Không cho phép thay đổi mục tin ServiceUserID."
"Cập nhật tự động mục tin.'"),
			UserObject.Ref);
	EndIf;
	
EndProcedure

// It is called from the EndInfobaseUserProcessing procedure to support the service model.
Procedure OnCompleteIBUserProcessor(UserObject, ProcessingParameters, UpdateRoles) Export
	
	If Not CommonUseReUse.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	If ProcessingParameters.Property("RemoteAdministrationChannelMessageProcessing") Then
		UpdateRoles = False;
	EndIf;
	
	IBUserDescription = UserObject.AdditionalProperties.IBUserDescription;
	
	If CommonUseReUse.DataSeparationEnabled()
	   AND TypeOf(UserObject) = Type("CatalogObject.Users")
	   AND IBUserDescription.Property("ActionResult")
	   AND Not UserObject.Service Then
		
		If IBUserDescription.ActionResult = "InfobaseUserDeleted" Then
			
			SetPrivilegedMode(True);
			CancelServiceUserAccess(UserObject);
			SetPrivilegedMode(False);
			
		Else // InfobaseUserWasAdded or InfobaseUserWasChanged.
			UpdateServiceUser(UserObject, ProcessingParameters.CreateServiceUser);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

// Only for internal use.
Procedure UpdateServiceManagerWebServiceDescription() Export
	
	If Not CommonUseReUse.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	// The cache must be filled before writing the infobase user.
	SaaSOperations.GetServiceManagerProxy();
	SetPrivilegedMode(False);
	
EndProcedure

// For the AtInfobaseUserProcessingCompletion procedure.
Procedure UpdateServiceUser(UserObject, CreateServiceUser)
	
	If Not UserObject.AdditionalProperties.Property("SynchronizeWithService")
		OR Not UserObject.AdditionalProperties.SynchronizeWithService Then
		
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	RecordServiceUser(UserObject, 
		CreateServiceUser, 
		UserObject.AdditionalProperties.ServiceUserPassword);
	
EndProcedure

// Only for internal use.
Function IsRightToAddUsers() Export
	
	SetPrivilegedMode(True);
	Proxy = SaaSOperations.GetServiceManagerProxy();
	SetPrivilegedMode(False);
	
	DataArea = Proxy.XDTOFactory.Create(
		Proxy.XDTOFactory.Type("http://www.1c.ru/SaaS/ApplicationAccess", "Zone"));
	DataArea.Zone = SaaSOperations.SessionSeparatorValue();
	
	ErrorInfo = Undefined;
	XDTOAccessRights = Proxy.GetAccessRights(DataArea, 
		CurrentUserServiceIdentifier(), ErrorInfo);
	ProcessInformationAboutWebServiceError(ErrorInfo, "GetAccessRights"); // The operation name is not localized.
	
	For Each RightsListItem IN XDTOAccessRights.Item Do
		If RightsListItem.AccessRight = "CreateUser" Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// Only for internal use.
Function ActionsWithNewServiceUser() Export
	
	ActionsWithServiceUser = NewActionsWithServiceUser();
	ActionsWithServiceUser.ChangePassword = True;
	ActionsWithServiceUser.ChangeName = True;
	ActionsWithServiceUser.ChangeDescriptionFull = True;
	ActionsWithServiceUser.ChangeAccess = True;
	ActionsWithServiceUser.ChangeAdmininstrativeAccess = True;
	
	ActionsWithCI = ActionsWithServiceUser.ContactInformation; 
	For Each KeyAndValue IN SaaSReUse.AccordanceOfUserCITypesXDTO() Do
		ActionsWithCI[KeyAndValue.Key].Update = True;
	EndDo;
	
	Return ActionsWithServiceUser;
	
EndFunction

// Only for internal use.
Function ActionsWithExistentServiceUser(Val User) Export
	
	SetPrivilegedMode(True);
	Proxy = SaaSOperations.GetServiceManagerProxy();
	SetPrivilegedMode(False);
	
	AccessObjects = PrepareUserAccessObjects(Proxy.XDTOFactory, User);
	
	ErrorInfo = Undefined;
	XDTOObjectAccessRights = Proxy.GetObjectsAccessRights(AccessObjects, 
		CurrentUserServiceIdentifier(), ErrorInfo);
	ProcessInformationAboutWebServiceError(ErrorInfo, "GetObjectsAccessRights"); // The operation name is not localized.
	
	Return XDTOObjectAccessRightsToActionsWithServiceUser(Proxy.XDTOFactory, XDTOObjectAccessRights);
	
EndFunction

// Only for internal use.
Function ActionsWithServiceUserWhenUserSettingIsUnavailable() Export
	
	ActionsWithServiceUser = NewActionsWithServiceUser();
	ActionsWithServiceUser.ChangePassword = False;
	ActionsWithServiceUser.ChangeName = False;
	ActionsWithServiceUser.ChangeDescriptionFull = False;
	ActionsWithServiceUser.ChangeAccess = False;
	ActionsWithServiceUser.ChangeAdmininstrativeAccess = False;
	
	ActionsWithCI = ActionsWithServiceUser.ContactInformation;
	For Each KeyAndValue IN SaaSReUse.AccordanceOfUserCITypesXDTO() Do
		ActionsWithCI[KeyAndValue.Key].Update = False;
	EndDo;
	
	Return ActionsWithServiceUser;
	
EndFunction

// Only for internal use.
Function GetServiceUsers(ServiceUserPassword) Export
	
	SetPrivilegedMode(True);
	Proxy = SaaSOperations.GetServiceManagerProxy(ServiceUserPassword);
	SetPrivilegedMode(False);
	
	ErrorInfo = Undefined;
	
	Try
		
		UsersList = Proxy.GetUsersList(SaaSOperations.SessionSeparatorValue(), );
		
	Except
		
		ServiceUserPassword = Undefined;
		Raise;
		
	EndTry;
	
	ProcessInformationAboutWebServiceError(ErrorInfo, "GetUsersList"); // The operation name is not localized.
	
	Result = New ValueTable;
	Result.Columns.Add("ID", New TypeDescription("UUID"));
	Result.Columns.Add("Name", New TypeDescription("String", , New StringQualifiers(0, AllowedLength.Variable)));
	Result.Columns.Add("FullName", New TypeDescription("String", , New StringQualifiers(0, AllowedLength.Variable)));
	Result.Columns.Add("Access", New TypeDescription("Boolean"));
	
	For Each UserInfo IN UsersList.Item Do
		UserRow = Result.Add();
		UserRow.ID = UserInfo.UserServiceID;
		UserRow.Name = UserInfo.Name;
		UserRow.FullName = UserInfo.FullName;
		UserRow.Access = UserInfo.Access;
	EndDo;
	
	Return Result;
	
EndFunction

// Only for internal use.
Procedure GiveAccessToServiceUser(Val ServiceUserID, Val ServiceUserPassword) Export
	
	SetPrivilegedMode(True);
	Proxy = SaaSOperations.GetServiceManagerProxy(ServiceUserPassword);
	SetPrivilegedMode(False);
	
	ErrorInfo = Undefined;
	Proxy.GrantUserAccess(
		CommonUse.SessionSeparatorValue(),
		ServiceUserID, 
		ErrorInfo);
	ProcessInformationAboutWebServiceError(ErrorInfo, "GrantUserAccess"); // The operation name is not localized.
	
EndProcedure

// For the AtInfobaseUserProcessingCompletion procedure.
Procedure CancelServiceUserAccess(UserObject)
	
	If Not ValueIsFilled(UserObject.ServiceUserID) Then
		Return;
	EndIf;
	
	BeginTransaction();
	Try
		Message = MessagesSaaS.NewMessage(
			MessagesManagementApplicationInterface.MessageRevokeUserAccess());
		
		Message.Body.Zone = CommonUse.SessionSeparatorValue();
		Message.Body.UserServiceID = UserObject.ServiceUserID;
		
		MessagesSaaS.SendMessage(
			Message,
			SaaSReUse.ServiceManagerEndPoint());
			
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Verifies that the passed user matches
// the existing infobase user in the current data area.
//
// Parameters:
//  User - CatalogRef.Users;
//
// Return value: Boolean.
//
Function ItIsCurrentDataAreaExistingUser(Val User)
	
	SetPrivilegedMode(True);
	
	If ValueIsFilled(User) Then
		
		If ValueIsFilled(User.InfobaseUserID) Then
			
			If InfobaseUsers.FindByUUID(User.InfobaseUserID) <> Undefined Then
				
				Return True;
				
			Else
				
				Return False;
				
			EndIf;
			
		Else
			
			Return False;
			
		EndIf;
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// HELPER PROCEDURE AND FUNCTIONS

Function CurrentUserServiceIdentifier()
	
	Return CommonUse.ObjectAttributeValue(Users.CurrentUser(), "ServiceUserID");
	
EndFunction

Function NewActionsWithServiceUser()
	
	ActionsWithServiceUser = New Structure;
	ActionsWithServiceUser.Insert("ChangePassword", False);
	ActionsWithServiceUser.Insert("ChangeName", False);
	ActionsWithServiceUser.Insert("ChangeDescriptionFull", False);
	ActionsWithServiceUser.Insert("ChangeAccess", False);
	ActionsWithServiceUser.Insert("ChangeAdmininstrativeAccess", False);
	
	ActionsWithCI = New Map;
	For Each KeyAndValue IN SaaSReUse.AccordanceOfUserCITypesXDTO() Do
		ActionsWithCI.Insert(KeyAndValue.Key, New Structure("Update", False));
	EndDo;
	// Key - CIKind, Value - Structure with rights.
	ActionsWithServiceUser.Insert("ContactInformation", ActionsWithCI);
	
	Return ActionsWithServiceUser;
	
EndFunction

Function PrepareUserAccessObjects(Factory, User)
	
	InformationAboutUsers = Factory.Create(
		Factory.Type("http://www.1c.ru/SaaS/ApplicationAccess", "User"));
	InformationAboutUsers.Zone = SaaSOperations.SessionSeparatorValue();
	InformationAboutUsers.UserServiceID = CommonUse.ObjectAttributeValue(User, "ServiceUserID");
	
	ObjectList = Factory.Create(
		Factory.Type("http://www.1c.ru/SaaS/ApplicationAccess", "ObjectsList"));
		
	ObjectList.Item.Add(InformationAboutUsers);
	
	UserCIType = Factory.Type("http://www.1c.ru/SaaS/ApplicationAccess", "UserContact");
	
	For Each KeyAndValue IN SaaSReUse.AccordanceOfUserCITypesXDTO() Do
		CIKind = Factory.Create(UserCIType);
		CIKind.UserServiceID = CommonUse.ObjectAttributeValue(User, "ServiceUserID");
		CIKind.ContactType = KeyAndValue.Value;
		ObjectList.Item.Add(CIKind);
	EndDo;
	
	Return ObjectList;
	
EndFunction

Function XDTOObjectAccessRightsToActionsWithServiceUser(Factory, XDTOObjectAccessRights)
	
	TypeInformationAboutUsers = Factory.Type("http://www.1c.ru/SaaS/ApplicationAccess", "User");
	UserCIType = Factory.Type("http://www.1c.ru/SaaS/ApplicationAccess", "UserContact");
	
	ActionsWithServiceUser = NewActionsWithServiceUser();
	ActionsWithCI = ActionsWithServiceUser.ContactInformation;
	
	For Each AccessRightsOfXDTOObject IN XDTOObjectAccessRights.Item Do
		
		If AccessRightsOfXDTOObject.Object.Type() = TypeInformationAboutUsers Then
			
			For Each RightsListItem IN AccessRightsOfXDTOObject.AccessRights.Item Do
				ActionWithUser = SaaSReUse.
					AccordanceRightXDTOUserActionsService().Get(RightsListItem.AccessRight);
				ActionsWithServiceUser[ActionWithUser] = True;
			EndDo;
			
		ElsIf AccessRightsOfXDTOObject.Object.Type() = UserCIType Then
			CIKind = SaaSReUse.AccordanceCIXDTOTypesToUserCI().Get(
				AccessRightsOfXDTOObject.Object.ContactType);
			If CIKind = Undefined Then
				MessagePattern = NStr("en='Unknown contact information kind was received: %1';ru='Получен неизвестный вид контактной информации: %1';vi='Nhận dạng thông tin liên hệ không xác định: %1'");
				MessageText = StringFunctionsClientServer.SubstituteParametersInString(
					MessagePattern, AccessRightsOfXDTOObject.Object.ContactType);
				Raise(MessageText);
			EndIf;
			
			ActionsWithCIKind = ActionsWithCI[CIKind];
			
			For Each RightsListItem IN AccessRightsOfXDTOObject.AccessRights.Item Do
				If RightsListItem.AccessRight = "Change" Then
					ActionsWithCIKind.Update = True;
				EndIf;
			EndDo;
		Else
			MessagePattern = NStr("en='Unknown access object type received: %1';ru='Получен неизвестный тип объектов доступа: %1';vi='Nhận kiểu đối tượng truy cập không xác định: %1'");
			MessageText = StringFunctionsClientServer.SubstituteParametersInString(
				MessagePattern, CommonUse.XDTOTypePresentation(AccessRightsOfXDTOObject.Object.Type()));
			Raise(MessageText);
		EndIf;
		
	EndDo;
	
	Return ActionsWithServiceUser;
	
EndFunction

Function GetLanguageCode(Val Language)
	
	If Language = Undefined Then
		Return "";
	Else
		Return Language.LanguageCode;
	EndIf;
	
EndFunction

// Processes the error details received from the web service.
// If not empty error info is passed, writes the
// detailed error presentation to the events log monitor
// and throws an exception with the brief error presentation text.
//
Procedure ProcessInformationAboutWebServiceError(Val ErrorInfo, Val OperationName)
	
	SaaSOperations.ProcessInformationAboutWebServiceError(
		ErrorInfo,
		UsersServiceSaaSReUse.SubsystemNameForEventLogMonitorEvents(),
		"ManagementApplication", // Not localized
		OperationName);
	
EndProcedure

#EndRegion
