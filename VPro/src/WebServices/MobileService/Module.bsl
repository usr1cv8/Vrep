
#Region MethodHandlers

Function GetPackageExchange(MobileDeviceCode, ExchangeMessageNumber, JobID)
		
	SetPrivilegedMode(True);
	
	ExchangeNode = ExchangePlans.MobileApplications.FindByCode(MobileDeviceCode); 
	
	If ExchangeNode.IsEmpty() Then
		Raise(NStr("en='Unknown Device -';ru='Неизвестное устройство -';vi='Thiết bị không xác định -'") + MobileDeviceCode);
	EndIf;
	
	Return ExchangeMobileApplicationCommon.ExchangeMessage(ExchangeNode, ExchangeMessageNumber, JobID);
	
EndFunction

Procedure SetProfileByDefault(NewNode, User)
		
	UserProfile = InformationRegisters.MobileUserProfiles.UserProfile(User);
	If ValueIsFilled(UserProfile) Then
		NewNode.SetRolesByProfile(UserProfile);
		If UserProfile = Enums.MobileApplicationProfiles.Owner Then
			NewNode.ForAllCashRegisters = True;
		EndIf;
	Else
		If IsInRole(Metadata.Roles.FullRights) Then
			NewNode.SetRolesByProfile(Enums.MobileApplicationProfiles.Owner);
			NewNode.ForAllCashRegisters = True;
		Else
			NewNode.SetRolesByProfile(Enums.MobileApplicationProfiles.DetailedSetting);
			If IsInRole(Metadata.Roles.AddChangeCounterparties) Then
				NewNode.AppendRoleInTable(Enums.RolesOfMobileApplication.CounterpartiesViewAndEdit);
			EndIf;
			If IsInRole(Metadata.Roles.AddChangeProductsAndServices) Then
				NewNode.AppendRoleInTable(Enums.RolesOfMobileApplication.NomenclatureViewAndEdit);
			EndIf;
			If IsInRole(Metadata.Roles.AddChangeSalesSubsystem) Then
				NewNode.AppendRoleInTable(Enums.RolesOfMobileApplication.OrdersViewAndEdit);
				NewNode.AppendRoleInTable(Enums.RolesOfMobileApplication.GoodsMovementsViewAndEdit);
				NewNode.AppendRoleInTable(Enums.RolesOfMobileApplication.ReportStockBalancesView);
				NewNode.AppendRoleInTable(Enums.RolesOfMobileApplication.ReportSalesView);
				NewNode.AppendRoleInTable(Enums.RolesOfMobileApplication.ReportDebtsView);
				If NOT IsInRole(Metadata.Roles.AddChangeProductsAndServices) Then
					NewNode.AppendRoleInTable(Enums.RolesOfMobileApplication.NomenclatureOnlyView);
				EndIf;
			EndIf;
			If IsInRole(Metadata.Roles.AddChangePurchasesSubsystem) Then
				NewNode.AppendRoleInTable(Enums.RolesOfMobileApplication.GoodsMovementsViewAndEdit);
				NewNode.AppendRoleInTable(Enums.RolesOfMobileApplication.ReportStockBalancesView);
				NewNode.AppendRoleInTable(Enums.RolesOfMobileApplication.ReportDebtsView);
				If NOT IsInRole(Metadata.Roles.AddChangeProductsAndServices) Then
					NewNode.AppendRoleInTable(Enums.RolesOfMobileApplication.NomenclatureOnlyView);
				EndIf;
			EndIf;
			If IsInRole(Metadata.Roles.AddChangePettyCashSubsystem)
				OR IsInRole(Metadata.Roles.AddChangeBankSubsystem) Then
				NewNode.AppendRoleInTable(Enums.RolesOfMobileApplication.MovementMoneyViewAndEdit);
				NewNode.AppendRoleInTable(Enums.RolesOfMobileApplication.MoneyMovementReportView);
				NewNode.AppendRoleInTable(Enums.RolesOfMobileApplication.ReportDebtsView);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

Function SendPackageExchangeServiceWithID(
	MobileApplicationData, 
	MobileDeviceCode, 
	MobileDeviceName, 
	SentNumber, 
	ReceivedNumber, 
	ExportPeriod, 
	MobileAppVersion, 
	SubscriberID)
		
	ResponseStructure = New Structure("JobID, NewExchange", Undefined, False);
	
	User = Users.AuthorizedUser();
	ValidateAccessDevices(MobileDeviceCode);

	SetPrivilegedMode(True);
	
	ExportPeriodsInMobileApplication = Enums.ExportPeriodsInMobileApplication.ForAllTime;
	ExportPeriodsInMobileApplicationSet = SmallBusinessReUse.GetValueByDefaultUser(
		User,
		"MobileApplicationExportingsPeriod"
	);

	If ExportPeriodsInMobileApplicationSet <> ExportPeriodsInMobileApplication Then
		SmallBusinessServer.SetUserSetting(ExportPeriodsInMobileApplication, "MobileApplicationExportingsPeriod")
	EndIf;
	
	Filter = New Structure("Description", MobileDeviceCode);
	JobArray = BackgroundJobs.GetBackgroundJobs(Filter);
	ActiveJobFound = False;
	For Each BackgroundJob In JobArray Do
		If BackgroundJob.State = BackgroundJobState.Active Then
			BackgroundJob.Cancel();
		EndIf;
	EndDo;
	
	ExchangeNode = ExchangePlans.MobileApplications.ThisNode().GetObject();
	If NOT ValueIsFilled(ExchangeNode.Code) Then
		ExchangeNode.DataExchange.Load = True;
		ExchangeNode.Code = "001";
		ExchangeNode.Description = NStr("en='Central';ru='Центральный';vi='Trung tâm'");
		ExchangeNode.Write();
	EndIf;
	
	NeedNodeInitialization = False;
	
	ExchangeNode = ExchangePlans.MobileApplications.FindByCode(MobileDeviceCode); 
	If ExchangeNode.IsEmpty() Then
				
		NewNode = ExchangePlans.MobileApplications.CreateNode();
		NewNode.Code = MobileDeviceCode;
		NewNode.Description = NameForNewNode(MobileDeviceName);
		NewNode.MobileAppVersion = MobileAppVersion;
		NewNode.SentNo = SentNumber;
		NewNode.ReceivedNo = ReceivedNumber;
		NewNode.DateLastSync = CurrentSessionDate();
		NewNode.CashRegister = CreateCashCR(NewNode.Description);
		
		SetProfileByDefault(NewNode, User);
		
		If ExchangeMobileApplicationCommon.IsVersionForOldExchange(NewNode) Then
			NewNode.ByResponsible = True;
		EndIf;
		
		If SubscriberID <> Undefined Then
			NewNode.SubscriberID = New ValueStorage(SubscriberID);
		EndIf;
		
		NewNode.Write();
		ExchangeNode = NewNode.Ref;
		NeedNodeInitialization = True;
		
	Else
		
		Node = ExchangeNode.GetObject();
		
		If ExchangeNode.DeletionMark OR
			ExchangeNode.Description <> MobileDeviceName OR
			ExchangeNode.MobileAppVersion <> MobileAppVersion OR
			(SubscriberID <> Undefined AND ExchangeNode.SubscriberID.Get() = Undefined) Then
			Node.DeletionMark = False;
			Node.MobileAppVersion = MobileAppVersion;
			If SubscriberID <> Undefined Then
				Node.SubscriberID = New ValueStorage(SubscriberID);
			EndIf;
		EndIf;
		
		If ExchangeNode.Roles.Count() = 0 Then // If the roles are blank, then this is the old node that corresponds to the sales representative.
			Node.SetRolesByProfile(Enums.MobileApplicationProfiles.SalesRepresentative);
		EndIf;
		
		If ExchangeNode.SentNo = 0
			OR ExchangeNode.ReceivedNo = 0
			OR ExchangeNode.SentNo < ReceivedNumber
			OR ExchangeNode.ReceivedNo <> SentNumber Then
			Node.SentNo = ReceivedNumber;
			Node.ReceivedNo = SentNumber;
			NeedNodeInitialization = True;
		EndIf;
		
		If NOT ValueIsFilled(Node.CashRegister) Then
			Node.CashRegister = CreateCashCR(Node.Description);
		EndIf;
		
		If ExchangeNode.Profile = Enums.MobileApplicationProfiles.MobileTelephony Then // If the existing site has a telephony profile, then it is necessary to register all changes and unload.
			SetProfileByDefault(ExchangeNode, User);
			NeedNodeInitialization = True;
		EndIf;
		
		Node.DateLastSync = CurrentSessionDate();
		Node.Write();
		
	EndIf;
	
	ExchangeMobileApplicationCommon.ProcessAcceptedImportedPackage(ExchangeNode, MobileApplicationData, False, True);
	ExchangeMobileApplicationCommon.StartFormingMessageExchangeQueue(ExchangeNode, MobileDeviceCode, ReceivedNumber, NeedNodeInitialization, ResponseStructure.JobId, True);
	ResponseStructure.NewExchange = NeedNodeInitialization;
	
	Return New ValueStorage(ResponseStructure, New Deflation(9));
	
EndFunction

Function GetProductPhoto(Nomenclature)
		
	SetPrivilegedMode(True);
	
	ID = New UUID(Nomenclature);
	Ref = Catalogs.ProductsAndServices.GetRef(ID);
	
	Return ExchangeMobileApplicationCommon.GetPicture(Ref);
	
EndFunction

Function IsMobileTarifPlan()
	
	Return False;
	
EndFunction

Function GetNumberOfDevices()
	
	SetPrivilegedMode(True);
	Query = New Query();
	Query.Text =
		"SELECT
		|	COUNT(MobileApplications.Ref) AS NodesCount
		|FROM
		|	ExchangePlan.MobileApplications AS MobileApplications
		|WHERE
		|	NOT MobileApplications.DeletionMark
		|	AND NOT MobileApplications.AccessIsDenied
		|	AND NOT MobileApplications.ThisNode";
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return String(Selection.NodesCount);
	Else
		Return "0";
	EndIf;
	
EndFunction

Function GetApplicationVersion()
	
	SetPrivilegedMode(True);
	Return String(Metadata.Version);
	
EndFunction

Function DeleteSuccessfulBackgroundJobId(MobileDeviceCode)
	
	SetPrivilegedMode(True);
	
	ExchangeNode = ExchangePlans.MobileApplications.FindByCode(MobileDeviceCode);
	InformationRegisters.SuccessfulBackgroundJobsInExchangeWithMobile.DeleteSuccessfulJob(ExchangeNode);	
	
EndFunction

#EndRegion

#Region ServiceProceduresAndFunctions

Procedure ValidateUserRights(User = Undefined)
	
	If User = Undefined Then
		User = Users.AuthorizedUser();
	EndIf;
	
	If NOT IsInRole(Metadata.Roles.FullRights)
	   AND NOT(IsInRole(Metadata.Roles.AddChangeSalesSubsystem) // Profile Basic Rights.
		  AND IsInRole(Metadata.Roles.AddChangePettyCashSubsystem)
		  AND IsInRole(Metadata.Roles.AddChangeBankSubsystem)) Then // Profile Money.
		
		Raise(
			NStr("en='For user ""';ru='У пользователя ""';vi='Ở người sử dụng ""'")
		  + User
		  + NStr("en='""insufficient rights. Access rights profiles must be included. Basic rights and Money.';ru='"" недостаточно прав. Необходимо включить профили прав доступа Базовые права и Деньги.';vi='""không đủ quyền. Cần bật hồ sơ quyền truy cập Quyền cơ bản và Tiền mặt.'")
		);
		
	EndIf;
	
EndProcedure

Procedure ValidateAccessDevices(MobileDeviceCode)
	
	ExchangeNode = ExchangePlans.MobileApplications.FindByCode(MobileDeviceCode); 
	If ExchangeNode.AccessIsDenied Then
		Raise(
			NStr("en='The device is not allowed to synchronize with the central base.';ru='Устройству запрещена синхронизация с центральной базой.';vi='Cấm đồng bộ hóa thiết bị với cơ sở trung tâm.'")
		);
	EndIf;
	
EndProcedure

Function NameForNewNode(ProposedName)
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	MobileApplications.Description AS Description
		|FROM
		|	ExchangePlan.MobileApplications AS MobileApplications
		|WHERE
		|	MobileApplications.Description LIKE &ProposedName
		|
		|ORDER BY
		|	Description DESC";
	Query.SetParameter("ProposedName", ProposedName + " #%");
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Query.Text =
		"SELECT
		|	MobileApplications.Description AS Description
		|FROM
		|	ExchangePlan.MobileApplications AS MobileApplications
		|WHERE
		|	MobileApplications.Description = &ProposedName
		|
		|ORDER BY
		|	Description DESC";
		Query.SetParameter("ProposedName", ProposedName);
		QueryResult = Query.Execute();
	EndIf;
	
	Selection = QueryResult.Select();
	
	If Selection.Next() Then
		NodeDescription = StrReplace(Lower(Selection.Description), Lower(ProposedName), "");
		Number = StrReplace(NodeDescription, " #", "");
		If IsBlankString(Number) Then
			NextNumber = 1;
		Else
			Try
				NextNumber = Number(TrimAll(Number)) + 1;
			Except
				NextNumber = 1;
			EndTry;
		EndIf;
		Return ProposedName + " #" + String(NextNumber); 
	Else	
		Return ProposedName; 
	EndIf;
	
EndFunction

Procedure UpdateEMailAddress(Val UserObject, Val Address, Val AddressStructure)
	
	ContactInformationKinds = Catalogs.ContactInformationKinds.UserEmail;
	
	Row = UserObject.ContactInformation.Find(ContactInformationKinds, "Kind");
	If AddressStructure = Undefined Then
		If Row <> Undefined Then
			UserObject.ContactInformation.Delete(Row);
		EndIf;
	Else
		If Row = Undefined Then
			Row = UserObject.ContactInformation.Add();
			Row.Kind = ContactInformationKinds;
		EndIf;
		Row.Type = Enums.ContactInformationTypes.EmailAddress;
		Row.Presentation = Address;
		
		If AddressStructure.Count() > 0 Then
			Row.EmailAddress = AddressStructure[0].Address;
			
			Position = StrFind(Row.EmailAddress, "@");
			If Position <> 0 Then
				Row.ServerDomainName = Mid(Row.EmailAddress, Position + 1);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

Function StructureOfEMail(Val EMailAddress)
	
	If ValueIsFilled(EMailAddress) Then
		
		Try
			AddressStructure = CommonUseClientServer.EmailsFromString(EMailAddress);
		Except
			Template = NStr("en='Invalid email address specified:"
"%1 error: %2';ru='Указан некорректный адрес электронной почты:"
"%1 Ошибка: %2';vi='Đã chỉ ra sai địa chỉ email:"
"%1 Lỗi: %2.'");
			MessageText = StrTemplate(Template, EMailAddress, ErrorInfo().Description);
			Raise(MessageText);
		EndTry;
		
		Return AddressStructure;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

Function CreateCashCR(MobileDeviceName)
	
	CatalogCashCR = Catalogs.CashRegisters.CreateItem();
	CatalogCashCR.Description = NStr("en='CashCR';ru='Касса ККМ';vi='Quầy thu ngân'") + " (" + MobileDeviceName + ")";
	CatalogCashCR.UseWithoutEquipmentConnection = True;
	CatalogCashCR.CashCRType = Enums.CashCRTypes.FiscalRegister;
	CatalogCashCR.Department = Catalogs.StructuralUnits.MainDepartment;
	CatalogCashCR.StructuralUnit = Catalogs.StructuralUnits.MainWarehouse;
	CatalogCashCR.CashCurrency = Constants.NationalCurrency.Get();
	CatalogCashCR.GLAccount = ChartsOfAccounts.Managerial.PettyCash;
	SettingValue = SmallBusinessReUse.GetValueByDefaultUser(Users.CurrentUser(), "MainCompany");
	If ValueIsFilled(SettingValue) Then
		CatalogCashCR.Owner = SettingValue;
	Else
		CatalogCashCR.Owner = Catalogs.Companies.CompanyByDefault();
	EndIf;
	CatalogCashCR.Write();
	Return CatalogCashCR.Ref;
	
EndFunction

#EndRegion