&AtClient
Var ApplicationsChecked;

#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DigitalSignatureService.SetConditionalCertificatesListAppearance(Certificates, True);
	
	If Parameters.Property("AutoTest") Then // Return if the form for analysis is received.
		Return;
	EndIf;
	
	If Not AccessRight("SaveUserData", Metadata) Then
		ErrorText = NStr("en='Data saving right is not available. Contact your administrator.';ru='Отсутствует право сохранения данных. Обратитесь к администратору.';vi='Không có quyền lưu dữ liệu. Hãy liên hệ với người quản trị.'");
		// Denial is set in OnOpen.
		Return;
	EndIf;
	
	InfobaseUserWithFullAccess = Users.InfobaseUserWithFullAccess();
	
	If Parameters.Property("ShowPageCertificates") Then
		Items.Pages.CurrentPage = Items.PageCertificates;
		
	ElsIf Parameters.Property("ShowSettingPage") Then
		Items.Pages.CurrentPage = Items.SettingsPage;
		
	ElsIf Parameters.Property("ShowApplicationPage") Then
		Items.Pages.CurrentPage = Items.ApplicationPage;
	EndIf;
	
	RunMode = CommonUseReUse.ApplicationRunningMode();
	
	If CommonUseReUse.DataSeparationEnabled() Then
		SetSignatureChecksAtServer(False);
		Items.CheckSignaturesAtServer.Visible = False;
		Items.ToSignAtServer.Visible = False;
	Else
		CheckSignaturesAtServer = Constants.VerifyDigitalSignaturesAtServer.Get();
		ToSignAtServer      = Constants.CreateDigitalSignaturesAtServer.Get();
	EndIf;
	
	RunMode = CommonUseReUse.ApplicationRunningMode();
	
	If RunMode.IsApplicationAdministrator Then
		CertificatesShow = "AllCertificates";
	Else
		CertificatesShow = "MyCertificates";
		
		// Application Page
		Items.application.ChangeRowSet = False;
		Items.ApplicationsAdd.Visible = False;
		Items.ApplicationsChange.Visible = False;
		Items.ApplicationsSetDeleteMark.Visible = False;
		Items.ApplicationsContextMenuAdd.Visible = False;
		Items.ApplicationsContextMenuChange.Visible = False;
		Items.ApplicationsContextMenuApplicationsSetDeleteMark.Visible = False;
		Items.CheckSignaturesAtServer.Visible = False;
		Items.ToSignAtServer.Visible = False;
		Items.ApplicationsExplanation.Title =
			NStr("en='Applications specified by administrator that can be used on computer.';ru='Список программ, предусмотренных администратором, которые можно использовать на компьютере.';vi='Danh sách chương trình được dự kiến bởi người quản trị mà có thể sử dụng trên máy tính,'");
	EndIf;
	
	If Not DigitalSignature.CommonSettings().CertificateIssueApplicationAvailable Then
		Items.CertificatesCreate.Visible = True;
		Items.CertificatesAdd.Visible = False;
		Items.CertificatesShowApplications.Visible = False;
		Items.CertificatesRequestStatus.Visible = False;
	EndIf;
	
	CertificatesRefreshFilter(ThisObject);
	
	If CommonUse.IsSubordinateDIBNode() Then
		// Cannot edit content and settings of default applications.
		// You can change only the path to the applications at Linux servers.
		Items.application.ChangeRowSet = False;
		Items.ApplicationsSetDeleteMark.Enabled = False;
		Items.ApplicationsContextMenuApplicationsSetDeleteMark.Enabled = False;
		Items.ApplicationsChange.OnlyInAllActions = False;
	EndIf;
	
	If Not RunMode.IsLinuxClient Then
		Items.GroupLinuxApplicationsPathToApplication.Visible = False;
	EndIf;
	
	Items.GroupWebClientExtensionNotSet.Visible =
		RunMode.ThisIsWebClient AND Parameters.Property("ExtensionNotConnected");
	
	SetConditionalAppearance();
	
	FillApplicationsAndSettings();
	
	RefreshCurrentItemsVisible();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If ValueIsFilled(ErrorText) Then
		Cancel = True;
		ShowMessageBox(, ErrorText);
		Return;
	EndIf;
	
	DefineSetApplications();
	
EndProcedure

&AtClient
Procedure OnReopen()
	
	DefineSetApplications();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Upper(EventName) = Upper("Record_DigitalSignaturesAndEncryptionKeyCertificates")
	   AND Parameter.Property("IsNew") Then
		
		Items.Certificates.Refresh();
		Items.Certificates.CurrentRow = Source;
		Return;
	EndIf;
	
	// On change of content or settings of applications.
	If Upper(EventName) = Upper("Write_DigitalSignatureAndEncryptionApplications")
	 Or Upper(EventName) = Upper("Write_PathsToDigitalSignatureAndEncryptionFilesAtServersLinux")
	 Or Upper(EventName) = Upper("Write_DigitalSignatureAndEncryptionPersonalSettings") Then
		
		AttachIdleHandler("OnChangeApplicationsContentOrSettings", 0.1, True);
		Return;
	EndIf;
	
	If Upper(EventName) = Upper("Set_ExpandedWorkWithCryptography") Then
		DefineSetApplications();
		Return;
	EndIf;
	
	// On change of usage settings.
	If Upper(EventName) <> Upper("Record_ConstantsSet") Then
		Return;
	EndIf;
	
	If Upper(Source) = Upper("UseDigitalSignatures")
	 Or Upper(Source) = Upper("UseEncryption") Then
		
		AttachIdleHandler("OnChangeSigningOrEncryptionUsage", 0.1, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region HeaderFormItemsEventsHandlers

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	If ApplicationsChecked <> True Then
		DefineSetApplications();
	EndIf;
	
EndProcedure

&AtClient
Procedure CertificatesShowOnChange(Item)
	
	CertificatesRefreshFilter(ThisObject);
	
EndProcedure

&AtClient
Procedure CertificatesShowApplicationsOnChange(Item)
	
	CertificatesRefreshFilter(ThisObject);
	
EndProcedure

&AtClient
Procedure ExtensionForEncryptedFilesOnChange(Item)
	
	If IsBlankString(ExtensionForEncryptedFiles) Then
		ExtensionForEncryptedFiles = "p7m";
	EndIf;
	
	SaveSettings();
	
EndProcedure

&AtClient
Procedure ExtensionForSignatureFilesOnChange(Item)
	
	If IsBlankString(ExtensionForSignatureFiles) Then
		ExtensionForSignatureFiles = "p7s";
	EndIf;
	
	SaveSettings();
	
EndProcedure

&AtClient
Procedure ActionsOnSavingDataWithDigitalSignatureOnChange(Item)
	
	SaveSettings();
	
EndProcedure

&AtClient
Procedure CheckSignaturesAtServerOnChange(Item)
	
	SetSignatureChecksAtServer(CheckSignaturesAtServer);
	
	Notify("Record_ConstantsSet", New Structure, "VerifyDigitalSignaturesAtServer");
	
EndProcedure

&AtClient
Procedure SignAtServerOnChange(Item)
	
	SetSigningAtServer(ToSignAtServer);
	
	Notify("Record_ConstantsSet", New Structure, "CreateDigitalSignaturesAtServer");
	
EndProcedure

#EndRegion

#Region ItemEventsHandlersFormTablesCertificates

&AtClient
Procedure CertificatesBeforeAdding(Item, Cancel, Copy, Parent, Group, Parameter)
	
	Cancel = True;
	If Not Copy Then
		CreationParameters = New Structure;
		CreationParameters.Insert("HideApplication", False);
		DigitalSignatureServiceClient.AddCertificate(CreationParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region ApplicationFormTableItemEventsHandlers

&AtClient
Procedure ApplicationsOnRowActivetion(Item)
	
	Items.ApplicationsSetDeleteMark.Enabled =
		Items.Applications.CurrentData <> Undefined;
	
EndProcedure

&AtClient
Procedure ApplicationsBeforeAdding(Item, Cancel, Copy, Parent, Group, Parameter)
	
	Cancel = True;
	
	If Items.Applications.ChangeRowSet Then
		OpenForm("Catalog.DigitalSignatureAndEncryptionApplications.ObjectForm");
	EndIf;
	
EndProcedure

&AtClient
Procedure ApplicationsBeforeChanges(Item, Cancel)
	
	Cancel = True;
	
	If Items.ApplicationsChange.Visible Then
		ShowValue(, Items.Applications.CurrentData.Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure ApplicationsBeforeDelete(Item, Cancel)
	
	Cancel = True;
	
	If Items.ApplicationsChange.Visible Then
		ApplicationsSetDeleteMark(Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure ApplicationsLinuxPathToApplicationOnChange(Item)
	
	CurrentData = Items.application.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	SaveLinuxPathAtServer(CurrentData.Ref, CurrentData.LinuxPathToApplication);
	
	DefineSetApplications();
	
EndProcedure

&AtClient
Procedure InstructionClick(Item)
	
	DigitalSignatureServiceClient.OpenInstructionForWorkWithApplications();
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure Refresh(Command)
	
	FillApplicationsAndSettings(True);
	
	DefineSetApplications();
	
EndProcedure

&AtClient
Procedure AddApplicationForCertificateIssue(Command)
	
	CreationParameters = New Structure;
	CreationParameters.Insert("CreateApplication", True);
	
	DigitalSignatureServiceClient.AddCertificate(CreationParameters);
	
EndProcedure

&AtClient
Procedure AddFromInstalledOnComputer(Command)
	
	DigitalSignatureServiceClient.AddCertificate();
	
EndProcedure

&AtClient
Procedure SetExtension(Command)
	
	DigitalSignatureClient.SetExtension(True);
	
EndProcedure

&AtClient
Procedure ApplicationsSetDeleteMark(Command)
	
	CurrentData = Items.application.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.DeletionMark Then
		QuestionText = NStr("en='Clear mark for deletion for ""%1""?';ru='Снять с ""%1"" пометку на удаление?';vi='Bỏ dấu xóa ""%1""?'");
	Else
		QuestionText = NStr("en='Mark ""%1"" for deletion?';ru='Пометить ""%1"" на удаление?';vi='Đặt dấu xóa ""%1""?'");
	EndIf;
	
	QuestionContent = New Array;
	QuestionContent.Add(PictureLib.Question32);
	QuestionContent.Add(StringFunctionsClientServer.SubstituteParametersInString(
		QuestionText, CurrentData.Description));
	
	ShowQueryBox(
		New NotifyDescription("ApplicationsSetDeleteMarkContinue", ThisObject, CurrentData.Ref),
		New FormattedString(QuestionContent),
		QuestionDialogMode.YesNo);
	
	
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

&AtServer
Procedure SetConditionalAppearance()
	
	// Form message of successful application installation.
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemColorsDesign = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	ItemColorsDesign.Value = Metadata.StyleItems.ExplanationText.Value;
	ItemColorsDesign.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("Applications.Installed");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = True;
	DataFilterItem.Use  = True;
	
	ItemProcessedFields = ConditionalAppearanceItem.Fields.Items.Add();
	ItemProcessedFields.Field = New DataCompositionField("ApplicationsCheckResult");
	ItemProcessedFields.Use = True;
	
	// Form message of failed application installation.
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemColorsDesign = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	ItemColorsDesign.Value = Metadata.StyleItems.ExplanationTextError.Value;
	ItemColorsDesign.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("Applications.Installed");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	DataFilterItem.Use  = True;
	
	ItemProcessedFields = ConditionalAppearanceItem.Fields.Items.Add();
	ItemProcessedFields.Field = New DataCompositionField("ApplicationsCheckResult");
	ItemProcessedFields.Use = True;
	
EndProcedure

&AtClientAtServerNoContext
Procedure CertificatesRefreshFilter(Form)
	
	Items = Form.Items;
	
	// Certificates filter All/My.
	ShowYours = Form.CertificatesShow <> "AllCertificates";
	
	CommonUseClientServer.SetFilterDynamicListItem(
		Form.Certificates, "User", UsersClientServer.CurrentUser(),,, ShowYours);
	
	Items.CertificatesUser.Visible = Not ShowYours;
	
	If Items.CertificatesShowApplications.Visible Then
		// Filter of certificates according to application state.
		FilterByApplicationState = ValueIsFilled(Form.CertificatesShowApplications);
		CommonUseClientServer.SetFilterDynamicListItem(Form.Certificates,
			"RequestStatus", Form.CertificatesShowApplications, , , FilterByApplicationState);
	EndIf;
	
EndProcedure

&AtClient
Procedure ApplicationsSetDeleteMarkContinue(Response, CurrentApplication) Export
	
	If Response = DialogReturnCode.Yes Then
		ChangeApplicationDeletionMark(CurrentApplication);
		NotifyChanged(CurrentApplication);
		Notify("Write_DigitalSignatureAndEncryptionApplications", New Structure, CurrentApplication);
		DefineSetApplications();
	EndIf;
	
EndProcedure

&AtServer
Procedure ChangeApplicationDeletionMark(Application)
	
	LockDataForEdit(Application, , UUID);
	
	Try
		Object = Application.GetObject();
		Object.DeletionMark = Not Object.DeletionMark;
		Object.Write();
	Except
		UnlockDataForEdit(Application, UUID);
		Raise;
	EndTry;
	
	UnlockDataForEdit(Application, UUID);
	
	FillApplicationsAndSettings(True);
	
EndProcedure

&AtClient
Procedure OnChangeSigningOrEncryptionUsage()
	
	RefreshCurrentItemsVisible();
	
EndProcedure

&AtServer
Procedure RefreshCurrentItemsVisible()
	
	If Constants.UseEncryption.Get()
	 Or DigitalSignature.CommonSettings().CertificateIssueApplicationAvailable Then
		
		Items.CertificatesCreate.Title = NStr("en='Add...';ru='Добавить...';vi='Thêm...'");
		Items.CertificatesContextMenuCreate.Title = NStr("en='Add...';ru='Добавить...';vi='Thêm...'");
		Items.ExtensionForEncryptedFiles.Visible = True;
	Else
		Items.CertificatesCreate.Title = NStr("en='Add';ru='Добавить';vi='Thêm'");
		Items.CertificatesContextMenuCreate.Title = NStr("en='Add';ru='Добавить';vi='Thêm'");
		Items.ExtensionForEncryptedFiles.Visible = False;
	EndIf;
	
	If Constants.UseEncryption.Get() Then
		Items.AddFromInstalledOnComputer.Title =
			NStr("en='From the ones installed on computer...';ru='Из установленных на компьютере...';vi='Từ những thiết lập trên máy tính...'");
	Else
		Items.AddFromInstalledOnComputer.Title =
			NStr("en='From the ones installed on computer';ru='Из установленных на компьютере';vi='Từ những thiết lập trên máy tính'");
	EndIf;
	
	If Constants.UseDigitalSignatures.Get() Then
		CheckBoxTitle = NStr("en='Check signatures and certificates on the server';ru='Проверять подписи и сертификаты на сервере';vi='Kiểm tra chữ ký và chứng thư trên Server'");
		CheckBoxToolTip =
			NStr("en='It allows you not to install"
"the application to the user computer to check digital signatures and certificates."
""
"Important: at least one of"
"the applications from the list must"
"be installed on each computer with working 1C:Enterprise server or Web server which uses a file infobase.';ru='Позволяет не устанавливать"
"программу на компьютер пользователя для проверки электронных подписей и сертификатов."
""
"Важно: на каждый"
"компьютер, где работает сервер 1С:Предприятия"
"или веб-сервер, использующий файловую информационную базу, должна быть установлена хотя бы одна из программ в списке.';vi='Cho phép không cài đặt"
"chương trình trên máy tính người sử dụng để kiểm tra chữ ký điện tử và chứng thư."
""
"Chú ý: trên mỗi máy tính,"
"mà Server 1C:DOANH NGHIỆP hoặc Web-server sử dụng cơ sở thông tin File-server, cần cài đặt một trong các chương trình trong danh sách.'");
		Items.ExtensionForSignatureFiles.Visible = True;
		Items.ActionsOnSavingDataWithDigitalSignature.Visible = True;
	Else
		CheckBoxTitle = NStr("en='Verify certificates on server';ru='Проверять сертификаты на сервере';vi='Kiểm tra chứng thư trên Server'");
		CheckBoxToolTip =
			NStr("en='It is not necessary to install"
"the application and certificate to the users computer to check certificates."
""
"Important: at least one of"
"the applications from the list must"
"be installed on each computer with working 1C:Enterprise server or Web server which uses a file infobase.';ru='Позволяет не устанавливать"
"программу на компьютер пользователя для проверки сертификатов."
""
"Важно: на каждый"
"компьютер, где работает сервер 1С:Предприятия"
"или веб-сервер, использующий файловую информационную базу, должна быть установлена хотя бы одна из программ в списке.';vi='Cho phép không cài đặt"
"chương trình trên máy tính người sử dụng để kiểm tra chứng thư."
""
"Chú ý: trên mỗi máy tính,"
"mà Server 1C:DOANH NGHIỆP"
"hoặc Web-server đang làm việc có sử dụng cơ sở thông tin File-server, cần cài đặt ít nhất một trong các chương trình trong danh sách.'");
		Items.ExtensionForSignatureFiles.Visible = False;
		Items.ActionsOnSavingDataWithDigitalSignature.Visible = False;
	EndIf;
	Items.CheckSignaturesAtServer.Title = CheckBoxTitle;
	Items.CheckSignaturesAtServer.ExtendedTooltip.Title = CheckBoxToolTip;
	
	If Not Constants.UseDigitalSignatures.Get() Then
		CheckBoxTitle = NStr("en='Encrypt and decrypt on server';ru='Шифровать и расшифровывать на сервере';vi='Mã hóa và giải mã trên Server'");
		CheckBoxToolTip =
			NStr("en=""It is not necessary to"
"install the application and certificate to the user's computer for encryption and decryption."
""
"Important: the application and the"
"private key certificate must be installed"
"on each computer with working 1C:Enterprise server or Web server which uses a file infobase."";ru='Позволяет не"
"устанавливать программу и сертификат на компьютер пользователя для шифрования и расшифровки."
""
"Важно: на каждый"
"компьютер, где работает сервер 1С:Предприятия"
"или веб-сервер, использующий файловую информационную базу, должна быть установлена программа и сертификат с закрытым ключом.';vi='Cho phép không"
"cài đặt chương trình và chứng thư vào máy tính người sử dụng để mã hóa và giải mã.'");
	ElsIf Not Constants.UseEncryption.Get() Then
		CheckBoxTitle = NStr("en='Sign on server';ru='Подписывать на сервере';vi='Ký tên trên Server'");
		CheckBoxToolTip =
			NStr("en='It is not necessary to"
"install the application and certificate to the users computer for signing."
""
"Important: the application and the"
"private key certificate must be installed"
"on each computer with working 1C:Enterprise server or Web server which uses a file infobase.';ru='Позволяет не"
"устанавливать программу и сертификат на компьютер пользователя для подписания."
""
"Важно: на каждый"
"компьютер, где работает сервер 1С:Предприятия"
"или веб-сервер, использующий файловую информационную базу, должна быть установлена программа и сертификат с закрытым ключом.';vi='Cho phép không"
"cài đặt chương trình và chứng thư trên máy tính người sử dụng để ký."
""
"Chú ý: trên mỗi máy tính"
"mà Server 1C:DOANH NGHIỆP"
"hoặc Web-server đang làm việc có sử dụng cơ sở thông tin File-server, cần cài đặt chương trình và chứng thư với khóa đóng.'");
	Else
		CheckBoxTitle = NStr("en='Sign and decrypt on server';ru='Подписывать и шифровать на сервере';vi='Ký tên và mã hóa trên Server'");
		CheckBoxToolTip =
			NStr("en='It allows you not to"
"install the application and the certificate on the computer of the user for signing, encryption and decryption."
""
"Important: the application and the"
"private key certificate must be installed"
"on each computer with working 1C:Enterprise server or Web server which uses a file infobase.';ru='Позволяет не устанавливать"
"программу и сертификат на компьютер пользователя для подписания, шифрования и расшифровки."
""
"Важно: на каждый"
"компьютер, где работает сервер 1С:Предприятия"
"или веб-сервер, использующий файловую информационную базу, должна быть установлена программа и сертификат с закрытым ключом.';vi='Cho phép không cài đặt"
"chương trình và chứng thư trên máy tính người sử dụng để ký, mã hóa và giải mã."
""
"Chú ý: trên mỗi máy tính, mà Server 1C:DOANH NGHIỆP hoặc Web-server"
"đang làm việc, có sử dụng cơ sở thông tin File-server, cần cài đặt chương trình và chứng thư với khóa đóng.'");
	EndIf;
	Items.ToSignAtServer.Title = CheckBoxTitle;
	Items.ToSignAtServer.ExtendedTooltip.Title = CheckBoxToolTip;
	
EndProcedure

&AtClient
Procedure DefineSetApplications()
	
	If Items.Pages.CurrentPage = Items.ApplicationPage Then
		ApplicationsChecked = True;
		BeginAttachingCryptoExtension(New NotifyDescription(
			"DefineInstalledApplicationsAfterExpansionConnecting", ThisObject));
	Else
		ApplicationsChecked = Undefined;
	EndIf;
	
EndProcedure

// Continuation of the DefineInstalledApplications procedure.
&AtClient
Procedure DefineInstalledApplicationsAfterExpansionConnecting(Attached, NotSpecified) Export
	
	If Attached Then
		Items.ApplicationPagesAndUpdate.CurrentPage = Items.ApplicationPageUpdate;
	EndIf;
	
	#If WebClient Or MobileClient Then
		AttachIdleHandler("ExpectationHandlerDefineInstalledApplications", 0.3, True);
	#Else
		AttachIdleHandler("ExpectationHandlerDefineInstalledApplications", 0.1, True);
	#EndIf
	
EndProcedure

&AtClient
Procedure WaitingForContinuationHandler()
	
	Return;
	
EndProcedure

&AtClient
Procedure ExpectationHandlerDefineInstalledApplications()
	
	BeginAttachingCryptoExtension(New NotifyDescription(
		"ExpectationHandlerDefineInstalledApplicationsAfterExpansionConnecting", ThisObject));
	
	#If WebClient Or MobileClient Then
		AttachIdleHandler("WaitingForContinuationHandler", 0.3, True);
	#Else
		AttachIdleHandler("WaitingForContinuationHandler", 0.1, True);
	#EndIf
	
EndProcedure

// Continue the ExpectationHandlerDefineInstalledApplications procedure.
&AtClient
Procedure ExpectationHandlerDefineInstalledApplicationsAfterExpansionConnecting(Attached, NotSpecified) Export
	
	If Not Attached Then
		If Not Items.GroupWebClientExtensionNotSet.Visible Then
			SetVisibleGroupWebClientExtensionNotSet(True);
		EndIf;
		AttachIdleHandler("ExpectationHandlerDefineInstalledApplications", 3, True);
		Return;
	EndIf;
	
	If Items.GroupWebClientExtensionNotSet.Visible Then
		SetVisibleGroupWebClientExtensionNotSet(False);
	EndIf;
	
	Context = New Structure;
	Context.Insert("IndexOf", -1);
	
	ExpectationHandlerDefineInstalledApplicationsCycleBegin(Context);
	
EndProcedure

// Continue the ExpectationHandlerDefineInstalledApplications procedure.
&AtClient
Procedure ExpectationHandlerDefineInstalledApplicationsCycleBegin(Context)
	
	If Applications.Count() <= Context.IndexOf + 1 Then
		// After cycle.
		Items.ApplicationPagesAndUpdate.CurrentPage = Items.ApplicationPageList;
		CurrentItem = Items.Applications;
		Return;
	EndIf;
	Context.IndexOf = Context.IndexOf + 1;
	ApplicationDescription = Applications.Get(Context.IndexOf);
	
	Context.Insert("ApplicationDescription", ApplicationDescription);
	
	If ApplicationDescription.DeletionMark Then
		UpdateValue(ApplicationDescription.CheckResult, "");
		UpdateValue(ApplicationDescription.Use, "");
		ExpectationHandlerDefineInstalledApplicationsCycleBegin(Context);
		Return;
	EndIf;
	
	ApplicationsDescription = New Array;
	ApplicationsDescription.Add(Context.ApplicationDescription);
	
	ExecuteParameters = New Structure;
	ExecuteParameters.Insert("ApplicationsDescription",  ApplicationsDescription);
	ExecuteParameters.Insert("IndexOf",            -1);
	ExecuteParameters.Insert("ShowError",    Undefined);
	ExecuteParameters.Insert("ErrorProperties",    New Structure("Errors", New Array));
	ExecuteParameters.Insert("IsLinux",   CommonUseClientServer.IsLinuxClient());
	ExecuteParameters.Insert("Manager",   Undefined);
	ExecuteParameters.Insert("Notification", New NotifyDescription(
		"ExpectationHandlerDefineInstalledApplicationsContinueCycle", ThisObject, Context));
	
	Context.Insert("ExecuteParameters", ExecuteParameters);
	DigitalSignatureServiceClient.CreateCryptographyManagerCycleBegin(ExecuteParameters);
	
EndProcedure

// Continue the ExpectationHandlerDefineInstalledApplications procedure.
&AtClient
Procedure ExpectationHandlerDefineInstalledApplicationsContinueCycle(Manager, Context) Export
	
	ApplicationDescription = Context.ApplicationDescription;
	Errors            = Context.ExecuteParameters.ErrorProperties.Errors;
	
	If Manager <> Undefined Then
		UpdateValue(ApplicationDescription.CheckResult, NStr("en='Installed on the computer.';ru='Установлена на компьютере.';vi='Đã cài đặt trên máy tính.'"));
		UpdateValue(ApplicationDescription.Use, True);
		ExpectationHandlerDefineInstalledApplicationsCycleBegin(Context);
		Return;
	EndIf;
	
	For Each Error IN Errors Do
		Break;
	EndDo;
	
	If Error.PathNotSpecified Then
		UpdateValue(ApplicationDescription.CheckResult, NStr("en='Path to the application is not specified.';ru='Не указан путь к программе.';vi='Chưa chỉ ra đường dẫn tới chương trình.'"));
		UpdateValue(ApplicationDescription.Use, "");
	Else
		ErrorText = NStr("en='It is not installed on the computer.';ru='Не установлена на компьютере.';vi='Chưa thiết lập trên máy tính.'") + " " + Error.Description;
		If Error.ToAdmin AND Not InfobaseUserWithFullAccess Then
			ErrorText = ErrorText + " " + NStr("en='Contact administrator.';ru='Обратитесь к администратору.';vi='Hãy liên hệ với người quản trị.'");
		EndIf;
		UpdateValue(ApplicationDescription.CheckResult, ErrorText);
		UpdateValue(ApplicationDescription.Use, False);
	EndIf;
	
	ExpectationHandlerDefineInstalledApplicationsCycleBegin(Context);
	
EndProcedure

&AtServer
Procedure SetVisibleGroupWebClientExtensionNotSet(Val ItemVisible)
	
	Items.GroupWebClientExtensionNotSet.Visible = ItemVisible;
	
EndProcedure

&AtClient
Procedure OnChangeApplicationsContentOrSettings()
	
	FillApplicationsAndSettings();
	
	DefineSetApplications();
	
EndProcedure

&AtServer
Procedure FillApplicationsAndSettings(RefreshReUse = False)
	
	Items.Certificates.Refresh();
	
	If RefreshReUse Then
		RefreshReusableValues();
	EndIf;
	
	PersonalSettings = DigitalSignature.PersonalSettings();
	
	ActionsOnSavingDS         = PersonalSettings.ActionsOnSavingDS;
	ExtensionForEncryptedFiles = PersonalSettings.ExtensionForEncryptedFiles;
	ExtensionForSignatureFiles       = PersonalSettings.ExtensionForSignatureFiles;
	PathToApplications                  = PersonalSettings.PathToDigitalSignatureAndEncryptionApplications;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	application.Ref,
	|	application.Description AS Description,
	|	application.ApplicationName,
	|	application.ApplicationType,
	|	application.SignAlgorithm,
	|	application.HashAlgorithm,
	|	application.EncryptionAlgorithm,
	|	application.DeletionMark AS DeletionMark
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionApplications AS application
	|
	|ORDER BY
	|	Description";
	
	Selection = Query.Execute().Select();
	
	RunMode = CommonUseReUse.ApplicationRunningMode();
	RowsProcessed = New Map;
	IndexOf = 0;
	
	While Selection.Next() Do
		If Not RunMode.IsApplicationAdministrator AND Selection.DeletionMark Then
			Continue;
		EndIf;
		Rows = Applications.FindRows(New Structure("Ref", Selection.Ref));
		If Rows.Count() = 0 Then
			If Applications.Count()-1 < IndexOf Then
				String = Applications.Add();
			Else
				String = Applications.Insert(IndexOf);
			EndIf;
		Else
			String = Rows[0];
			RowIndex = Applications.IndexOf(String);
			If RowIndex <> IndexOf Then
				Applications.Move(RowIndex, IndexOf - RowIndex);
			EndIf;
		EndIf;
		// Update only the changed values not to update the form table once again.
		UpdateValue(String.Ref,              Selection.Ref);
		UpdateValue(String.DeletionMark,     Selection.DeletionMark);
		UpdateValue(String.Description,        Selection.Description);
		UpdateValue(String.ApplicationName,        Selection.ApplicationName);
		UpdateValue(String.ApplicationType,        Selection.ApplicationType);
		UpdateValue(String.SignAlgorithm,     Selection.SignAlgorithm);
		UpdateValue(String.HashAlgorithm, Selection.HashAlgorithm);
		UpdateValue(String.EncryptionAlgorithm,  Selection.EncryptionAlgorithm);
		UpdateValue(String.LinuxPathToApplication, PathToApplications.Get(Selection.Ref));
		UpdateValue(String.PictureNumber,       ?(Selection.DeletionMark, 4, 3));
		
		RowsProcessed.Insert(String, True);
		IndexOf = IndexOf + 1;
	EndDo;
	
	IndexOf = Applications.Count()-1;
	While IndexOf >=0 Do
		String = Applications.Get(IndexOf);
		If RowsProcessed.Get(String) = Undefined Then
			Applications.Delete(IndexOf);
		EndIf;
		IndexOf = IndexOf-1;
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateValue(OldValue, NewValue)
	
	If OldValue <> NewValue Then
		OldValue = NewValue;
	EndIf;
	
EndProcedure

&AtClient
Procedure SaveSettings()
	
	SavedSettings = New Structure;
	SavedSettings.Insert("ActionsOnSavingDS",         ActionsOnSavingDS);
	SavedSettings.Insert("ExtensionForEncryptedFiles", ExtensionForEncryptedFiles);
	SavedSettings.Insert("ExtensionForSignatureFiles",       ExtensionForSignatureFiles);
	
	SaveSettingsAtServer(SavedSettings);
	
EndProcedure

&AtServerNoContext
Procedure SaveSettingsAtServer(SavedSettings)
	
	PersonalSettings = DigitalSignature.PersonalSettings();
	FillPropertyValues(PersonalSettings, SavedSettings);
	DigitalSignatureService.SavePersonalSettings(PersonalSettings);
	
	// It is required to update personal settings on client.
	RefreshReusableValues();
	
EndProcedure

&AtServerNoContext
Procedure SaveLinuxPathAtServer(Application, PathLinux)
	
	PersonalSettings = DigitalSignature.PersonalSettings();
	PersonalSettings.PathToDigitalSignatureAndEncryptionApplications.Insert(Application, PathLinux);
	DigitalSignatureService.SavePersonalSettings(PersonalSettings);
	
	// It is required to update personal settings on client.
	RefreshReusableValues();
	
EndProcedure

&AtServerNoContext
Procedure SetSignatureChecksAtServer(CheckSignaturesAtServer)
	
	If Not AccessRight("Set", Metadata.Constants.VerifyDigitalSignaturesAtServer)
	 Or Constants.VerifyDigitalSignaturesAtServer.Get() = CheckSignaturesAtServer Then
		
		Return;
	EndIf;
	
	Constants.VerifyDigitalSignaturesAtServer.Set(CheckSignaturesAtServer);
	
	// It is required to update common settings at server and on client.
	RefreshReusableValues();
	
EndProcedure

&AtServerNoContext
Procedure SetSigningAtServer(ToSignAtServer)
	
	If Not AccessRight("Set", Metadata.Constants.CreateDigitalSignaturesAtServer)
	 Or Constants.CreateDigitalSignaturesAtServer.Get() = ToSignAtServer Then
		
		Return;
	EndIf;
	
	Constants.CreateDigitalSignaturesAtServer.Set(ToSignAtServer);
	
	// It is required to update common settings at server and on client.
	RefreshReusableValues();
	
EndProcedure

#EndRegion
