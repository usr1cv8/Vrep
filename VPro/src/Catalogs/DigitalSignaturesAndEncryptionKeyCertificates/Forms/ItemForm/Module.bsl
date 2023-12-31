#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then // Return if the form for analysis is received.
		Return;
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		Return;
	EndIf;
	
	AreCompanies = Not Metadata.DefinedTypes.Company.Type.ContainsType(Type("String"));
	OnCreateAtServerOnReadAtServer();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not ValueIsFilled(Object.Ref) Then
		Cancel = True;
		AttachIdleHandler("WaitHandlerAddCertificate", 0.1, True);
		Return;
		
	ElsIf ValueIsFilled(Object.RequestStatus)
	        AND Object.RequestStatus
	           <> PredefinedValue("Enum.CertificateIssueRequestState.Executed") Then
		
		Cancel = True;
		AttachIdleHandler("WaitHandlerOpenStatement", 0.1, True);
		Return;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	If CertificateAddress <> Undefined Then
		OnCreateAtServerOnReadAtServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Record_DigitalSignaturesAndEncryptionKeyCertificates", New Structure, Object.Ref);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// Check for name uniqueness.
	If Not Items.Description.ReadOnly Then
		DigitalSignatureService.CheckPresentationUniqueness(
			Object.Description, Object.Ref, "Object.Description", Cancel);
	EndIf;
	
	If TypeOf(AttributesParameters) <> Type("Structure") Then
		Return;
	EndIf;
	
	For Each KeyAndValue IN AttributesParameters Do
		AttributeName = KeyAndValue.Key;
		Properties     = KeyAndValue.Value;
		
		If Not Properties.ReadOnly.FillChecking
		 Or ValueIsFilled(Object[AttributeName]) Then
			
			Continue;
		EndIf;
		
		MessageText = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='The ""%1"" field is not filled in.';ru='Поле %1 не заполнено.';vi='Chưa điền trường %1.'"), Items[AttributeName].Title);
		
		CommonUseClientServer.MessageToUser(MessageText,, AttributeName,, Cancel);
	EndDo;
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure ShowAutofilledAttributes(Command)
	
	Show = Not Items.FormShowAutofilledAttributes.Check;
	
	Items.FormShowAutofilledAttributes.Check = Show;
	Items.AutoFieldsFromCertificateData.Visible = Show;
	
	If AreCompanies Then
		Items.Company.Visible = Show;
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowCertificateData(Command)
	
	DigitalSignatureClient.OpenCertificate(CertificateAddress, True);
	
EndProcedure

&AtClient
Procedure ShowRequestForCertificateIssue(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("CertificatRef", Object.Ref);
	OpenForm("Catalog.DigitalSignaturesAndEncryptionKeyCertificates.Form.RequestForNewQualifiedCertificateIssue",
		FormParameters);
	
EndProcedure

&AtClient
Procedure CheckCertificate(Command)
	
	If Not ValueIsFilled(Object.Ref) Then
		ShowMessageBox(, NStr("en='Certificate has not been recorded yet.';ru='Сертификат еще не записан.';vi='Chứng thư vẫn chưa được ghi lại.'"));
		Return;
	EndIf;
	
	If Modified AND Not Write() Then
		Return;
	EndIf;
	
	DigitalSignatureClient.CheckCatalogCertificate(Object.Ref,
		New Structure("WithoutConfirmation", True));
	
EndProcedure

&AtClient
Procedure SaveCertificateDataInFile(Command)
	
	DigitalSignatureServiceClient.SaveCertificate(, CertificateAddress);
	
EndProcedure

&AtClient
Procedure CertificateRevoked(Command)
	
	Object.Revoked = Not Object.Revoked;
	Items.FormCertificateRevoked.Check = Object.Revoked;
	
	If Object.Revoked Then
		ShowMessageBox(, NStr("en='After writing, callback cannot be canceled.';ru='После записи отменить отзыв будет невозможно.';vi='Sau khi ghi lại không thể hủy bỏ nhận xét.'"));
	EndIf;
	
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

&AtServer
Procedure OnCreateAtServerOnReadAtServer()
	
	If ValueIsFilled(Object.RequestStatus) Then
		If Object.RequestStatus = Enums.CertificateIssueRequestState.Executed Then
			Items.FormShowRequestForCertificateIssue.Enabled = True;
			Items.ShowRequestForCertificateIssue.Enabled = True;
		Else
			Return;
		EndIf;
	EndIf;
	
	CertificateBinaryData = CommonUse.ObjectAttributeValue(
		Object.Ref, "CertificateData").Get();
	
	If TypeOf(CertificateBinaryData) = Type("BinaryData") Then
		Certificate = New CryptoCertificate(CertificateBinaryData);
		If ValueIsFilled(CertificateAddress) Then
			PutToTempStorage(CertificateBinaryData, CertificateAddress);
		Else
			CertificateAddress = PutToTempStorage(CertificateBinaryData, UUID);
		EndIf;
		DigitalSignatureClientServer.FillCertificateDataDescription(CertificateDataDescription, Certificate);
	Else
		CertificateAddress = "";
		Items.ShowCertificateData.Enabled  = False;
		Items.FormCheckCertificate.Enabled = False;
		Items.FormSaveCertificateDataInFile.Enabled = False;
		Items.AutoFieldsFromCertificateData.Visible = True;
		Items.FormShowAutofilledAttributes.Check = True;
	EndIf;
	
	Items.FormCertificateRevoked.Check = Object.Revoked;
	If Object.Revoked Then
		Items.FormCertificateRevoked.Enabled = False;
	EndIf;
	
	If Not Users.InfobaseUserWithFullAccess() Then
		If Object.AddedBy      <> Users.CurrentUser()
		   AND Object.User <> Users.CurrentUser() Then
			// Regular users can change only their certificates.
			ReadOnly = True;
		Else
			// A regular user can not change the access rights.
			Items.AddedBy.ReadOnly = True;
			If Object.AddedBy <> Users.CurrentUser() Then
				// A regular user can not change
				// the attribute User if they didn't add a certificate.
				Items.User.ReadOnly = True;
			EndIf;
		EndIf;
	EndIf;
	
	AreCompanies = Not Metadata.DefinedTypes.Company.Type.ContainsType(Type("String"));
	Items.Company.Visible = AreCompanies;
	
	If Not ValueIsFilled(CertificateAddress) Then
		Return; // Certificate = Undefined.
	EndIf;
	
	SubjectProperties = DigitalSignatureClientServer.CertificateSubjectProperties(Certificate);
	If SubjectProperties.Surname <> Undefined Then
		Items.Surname.ReadOnly = True;
	EndIf;
	If SubjectProperties.Name <> Undefined Then
		Items.Name.ReadOnly = True;
	EndIf;
	If SubjectProperties.Patronymic <> Undefined Then
		Items.Patronymic.ReadOnly = True;
	EndIf;
	If SubjectProperties.Company <> Undefined Then
		Items.firm.ReadOnly = True;
	EndIf;
	If SubjectProperties.Position <> Undefined Then
		Items.Position.ReadOnly = True;
	EndIf;
	
	AttributesParameters = Undefined;
	DigitalSignatureService.BeforeEditKeyCertificate(
		Object.Ref, Certificate, AttributesParameters);
	
	For Each KeyAndValue IN AttributesParameters Do
		AttributeName = KeyAndValue.Key;
		Properties     = KeyAndValue.Value;
		
		If Not Properties.Visible Then
			Items[AttributeName].Visible = False;
			
		ElsIf Properties.ReadOnly Then
			Items[AttributeName].ReadOnly = True
		EndIf;
		If Properties.ReadOnly.FillChecking Then
			Items[AttributeName].AutoMarkIncomplete = True;
		EndIf;
	EndDo;
	
	Items.AutoFieldsFromCertificateData.Visible =
		    Not Items.Surname.ReadOnly   AND Not ValueIsFilled(Object.Surname)
		Or Not Items.Name.ReadOnly       AND Not ValueIsFilled(Object.Name)
		Or Not Items.Patronymic.ReadOnly  AND Not ValueIsFilled(Object.Patronymic);
	
	Items.FormShowAutofilledAttributes.Check =
		Items.AutoFieldsFromCertificateData.Visible;
	
EndProcedure

&AtClient
Procedure WaitHandlerAddCertificate()
	
	CreationParameters = New Structure;
	CreationParameters.Insert("ToPersonalList", True);
	CreationParameters.Insert("Company", Object.Company);
	CreationParameters.Insert("HideApplication", False);
	
	DigitalSignatureServiceClient.AddCertificate(CreationParameters);
	
EndProcedure

&AtClient
Procedure WaitHandlerOpenStatement()
	
	FormParameters = New Structure;
	FormParameters.Insert("CertificatRef", Object.Ref);
	OpenForm("Catalog.DigitalSignaturesAndEncryptionKeyCertificates.Form.RequestForNewQualifiedCertificateIssue",
		FormParameters);
	
EndProcedure

#EndRegion
