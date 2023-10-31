
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Parameters.PrintObjectFormName) Then
		Raise NStr("en='Непосредственное открытие этой формы не предусмотрено.';ru='Непосредственное открытие этой формы не предусмотрено.';vi='Không thể mở trực tiếp biểu mẫu này.'");
	EndIf;
	
	If TypeOf(Parameters.SendingObjects) <> Type("Array")
		And Not ValueIsFilled(Parameters.ObjectManagerName) Then
		Raise NStr("en='Непосредственное открытие этой формы не предусмотрено.';ru='Непосредственное открытие этой формы не предусмотрено.';vi='Không thể mở trực tiếp biểu mẫu này.'");
	EndIf;
	
	If TypeOf(Parameters.SendingObjects) = Type("Array") And Parameters.SendingObjects.Count() = 0
		And Not ValueIsFilled(Parameters.ObjectManagerName) Then
		Raise NStr("en='Непосредственное открытие этой формы не предусмотрено.';ru='Непосредственное открытие этой формы не предусмотрено.';vi='Không thể mở trực tiếp biểu mẫu này.'");
	EndIf;
	
	If ValueIsFilled(Parameters.FormCaption) Then
		AutoTitle = False;
		Title = Parameters.FormCaption;
	EndIf;
	PrintFormsChoiceMode = Parameters.PrintFormsChoiceMode;
	
	If TypeOf(Parameters.SendingObjects) = Type("Array") Then
		SendingObjects = New FixedArray(Parameters.SendingObjects);
	Else
		SendingObjects = New FixedArray(New Array);
	EndIf;
	
	If ValueIsFilled(Parameters.ObjectManagerName) Then
		ObjectManagerName = Parameters.ObjectManagerName;
	Else
		ObjectManagerName = SendingObjects[0].Metadata().FullName();
	EndIf;
	
	If Parameters.Property("AdditionalPrintParameters") Then
		AdditionalPrintParameters = Parameters.AdditionalPrintParameters;
	Else
		AdditionalPrintParameters = Undefined;
	EndIf;
	
	ReadPrintCommands();
	ReadFormSettings();
	
	If IsSendingContractPrintForms() Then
		Items.AttachmentFormatPresentation.Visible = False;
	Else
		AttachmentFormatPresentation = GetAttachmentsFormatPresentation(SelectedSavingFormats, PackIntoArchive);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	If Not PrintFormsChoiceMode Then
		SaveFormSettings(SettingsKey, CommonUseClientServer.MarkedItems(PrintForms));
	Else
		// Сохранение печатных форм происходит по команде Выбрать.
	EndIf;
	
	Notify("SelectionPrintFormsForSending");
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	
	If Upper(ChoiceSource.FormName) = Upper("CommonForm.AttachmentFormatSelection") Then
		
		If SelectedValue <> Undefined And SelectedValue <> DialogReturnCode.Cancel Then
			
			PackIntoArchive = SelectedValue.PackIntoArchive;
			TransliterateFilesNames = SelectedValue.TransliterateFilesNames;
			SelectedSavingFormats.FillChecks(False);
			
			For Each SelectedFormat In SelectedValue.SavingFormats Do
				FormatOnForm = SelectedSavingFormats.FindByValue(SelectedFormat);
				If FormatOnForm <> Undefined Then
					FormatOnForm.Check = True;
				EndIf;
			EndDo;
			
			AttachmentFormatPresentation = GetAttachmentsFormatPresentation(SelectedSavingFormats, PackIntoArchive);
			
		EndIf;
		
	ElsIf Upper(ChoiceSource.FormName) = Upper("CommonForm.NewEmailPreparation") Then
		
		If SelectedValue <> Undefined And SelectedValue <> DialogReturnCode.Cancel Then
			
			SendingParameters.Recipient.Clear();
			CommonUseClientServer.SupplementArray(SendingParameters.Recipient, SelectedValue.Recipients);
			CreateNewEmail();
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormItemEventsHandlers

&AtClient
Procedure AttachmentFormatPresentationClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	SelectedFormatsInRows = New Array;
	For Each Format In CommonUseClientServer.MarkedItems(SelectedSavingFormats) Do
		SelectedFormatsInRows.Add(String(Format));
	EndDo;
	
	FormatSettings = New Structure;
	FormatSettings.Insert("PackIntoArchive", PackIntoArchive);
	FormatSettings.Insert("SavingFormats", SelectedFormatsInRows);
	FormatSettings.Insert("TransliterateFilesNames", TransliterateFilesNames);
	
	OpenParameters = New Structure;
	OpenParameters.Insert("FormatSettings", FormatSettings);
	OpenForm("CommonForm.AttachmentFormatSelection", OpenParameters, ThisObject);
	
EndProcedure

#EndRegion

#Region CommandHandlers

&AtClient
Procedure SELECT(Command)
	
	If PrintFormsChoiceMode Then
		SaveFormSettings(SettingsKey, CommonUseClientServer.MarkedItems(PrintForms));
		Close();
		Return;
	EndIf;
	
	GenerateAttachmentsAndSelectRecipients();
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Procedure ReadPrintCommands()
	
	ShowPrintCommandsByPrintTemplates = True;
	If Parameters.Property("ShowPrintCommandsByOfficeDocumentPrintTemplates") Then
		ShowPrintCommandsByPrintTemplates = Parameters.ShowPrintCommandsByOfficeDocumentPrintTemplates;
	EndIf;
	
	PrintCommands = PrintManagement.PrintCommandsForms(Parameters.PrintObjectFormName);
	For Each PrintCommand In PrintCommands Do
		
		If PrintCommand.HiddenByFunctionalOptions Then
			Continue;
		EndIf;
		
		If Not SmallBusinessServer.CommandPrintsInServerContext(PrintCommand) Then
			Continue;
		EndIf;
		
		If PrintCommand.AdditionalParameters.Property("StartVariant") Then
			If PrintCommand.AdditionalParameters.StartVariant <> Enums.AdditionalDataProcessorsCallMethods.CallOfServerMethod
				Or Not ValueIsFilled(PrintCommand.AdditionalParameters.Ref) Then
				Continue;
			EndIf;
		EndIf;
		
		If Not ShowPrintCommandsByPrintTemplates
			And TypeOf(PrintCommand.AdditionalParameters) = Type("Structure")
			And PrintCommand.AdditionalParameters.Property("TemplateAssignment") Then
			Continue;
		EndIf;
		
		PrintForms.Add(PrintCommand.ID, PrintCommand.Presentation);
		
	EndDo;
	PrintCommandsAddress = PutToTempStorage(PrintCommands, UUID);
	
EndProcedure

&AtServer
Procedure ReadFormSettings()
	
	SettingsKey = ?(ValueIsFilled(Parameters.SettingsKey), Parameters.SettingsKey, ObjectManagerName);
	
	PrintFormsSettings = CommonUse.CommonSettingsStorageImport("PrintFormsSending", SettingsKey);
	If PrintFormsSettings <> Undefined Then
		For Each SelectedPrintForm In PrintFormsSettings Do 
			Command = PrintForms.FindByValue(SelectedPrintForm);
			If Command <> Undefined Then
				Command.Check = True;
			EndIf;
		EndDo;
	EndIf;
	
	SavingSettings = UserPrintFormsSavingSettings();
	PackIntoArchive = SavingSettings.PackIntoArchive;
	TransliterateFilesNames = SavingSettings.TransliterateFilesNames;
	
	AvailableFormats = PrintManagement.SpreadsheetDocumentSavingFormatsSettings();
	For Each SavingFormat In AvailableFormats Do
		
		// Для возможности использования в мобильном клиенте.
		SaveFormatPresentation = String(SavingFormat.Ref);
		SaveFormatString = String(SavingFormat.SpreadsheetDocumentFileType);
		
		ThisFormatIsSavedInSettings = SavingSettings.SavingFormats.Find(SaveFormatString) <> Undefined;
		SelectedSavingFormats.Add(
			SaveFormatString,
			SaveFormatPresentation,
			ThisFormatIsSavedInSettings,
			SavingFormat.Picture);
	EndDo;
	
	NoPrintFormSelected = PrintForms.Count() > 0
		And CommonUseClientServer.MarkedItems(PrintForms).Count() = 0;
	If NoPrintFormSelected Then
		PrintForms[0].Check = True;
	EndIf;
	
	NoFormatSelected = SelectedSavingFormats.Count() > 0
		And CommonUseClientServer.MarkedItems(SelectedSavingFormats).Count() = 0;
	If NoFormatSelected Then
		SelectedSavingFormats[0].Check = True;
	EndIf;
	
EndProcedure

&AtServer
Function UserPrintFormsSavingSettings()
	
	PrintFormsSavingSettings = PrintManagement.SavingSettings();
	
	SavedFormatSettings = CommonUse.SystemSettingsStorageImport(
		"CommonForm.AttachmentFormatSelection/CurrentData", "");
	
	If SavedFormatSettings = Undefined Then
		Return PrintFormsSavingSettings;
	EndIf;
	
	SavedFormats         = SavedFormatSettings.Get("SelectedSavingFormats");
	SavedPackageToArchive = SavedFormatSettings.Get("PackIntoArchive");
	SavedTranslatingFilesNamesToTransliteration = SavedFormatSettings.Get("TransliterateFilesNames");
	
	If SavedFormats <> Undefined Then
		PrintFormsSavingSettings.SavingFormats = CommonUseClientServer.MarkedItems(SavedFormats);
	EndIf;
	
	If SavedPackageToArchive <> Undefined Then
		PrintFormsSavingSettings.PackIntoArchive = SavedPackageToArchive;
	EndIf;
	
	If SavedTranslatingFilesNamesToTransliteration <> Undefined Then
		PrintFormsSavingSettings.TransliterateFilesNames = SavedTranslatingFilesNamesToTransliteration;
	EndIf;
	
	Return PrintFormsSavingSettings;
	
EndFunction

&AtServerNoContext
Procedure SaveFormSettings(SettingsKey, SelectedCommans)
	
	CommonUse.CommonSettingsStorageSave("PrintFormsSending", SettingsKey, SelectedCommans);
	
EndProcedure

&AtClient
Procedure GenerateAttachmentsAndSelectRecipients()
	
	SelectedCommans = CommonUseClientServer.MarkedItems(PrintForms);
	
	GenerateAttachmentsAndSelectRecipientsServer(SelectedCommans);
	
	If SendingParameters.Recipient.Count() > 1 Then
		FormParameters = New Structure;
		FormParameters.Insert("Recipients", SendingParameters.Recipient);
		FormParameters.Insert("DontSelectAttachmentsFormat", True);
		OpenForm("CommonForm.NewEmailPreparation", FormParameters, ThisObject);
	Else
		CreateNewEmail();
	EndIf;
	
EndProcedure

&AtServer
Procedure GenerateAttachmentsAndSelectRecipientsServer(SelectedCommans)
	
	ObjectsArray = CommonUseClientServer.CopyRecursive(SendingObjects);
	
	FillEmailAttachments(ObjectsArray, SelectedCommans);
	FillEmailRecipients(ObjectsArray, SelectedCommans);
	
EndProcedure

&AtServer
Procedure FillEmailAttachments(ObjectsArray, SelectedCommans)
	
	If SelectedCommans.Count() = 0 Then
		Return;
	EndIf;
	
	SavingSettings = PrintManagement.SavingSettings();
	CommonUseClientServer.SupplementArray(SavingSettings.SavingFormats, CommonUseClientServer.MarkedItems(SelectedSavingFormats));
	SavingSettings.TransliterateFilesNames = TransliterateFilesNames;
	SavingSettings.PackIntoArchive = PackIntoArchive;
	
	GeneratedFiles = PrintManagement.PrintToFile(SelectedPrintCommands(SelectedCommans), ObjectsArray, SavingSettings);
	UserMessages = GetUserMessages(True);
	
	Attachments.Clear();
	For Each GeneratedFile In GeneratedFiles Do
		Attachments.Add(PutToTempStorage(GeneratedFile.BinaryData, UUID), GeneratedFile.FileName);
	EndDo;
	
EndProcedure

&AtServer
Procedure FillEmailRecipients(ObjectsArray, SelectedCommans)
	
	SendingParametersPF = New Structure("Recipient,Subject,Text", Undefined, "", "");
	
	If SelectedCommans.Count() <> 0 Then
		SmallBusinessServer.FillSendingParameters(SendingParametersPF, ObjectsArray);
	Else
		SendingParametersPF.Recipient = SmallBusinessServer.GetPreparedRecipientsEmailAddresses(ObjectsArray);
	EndIf;
	
	FillSendingParameters(SendingParametersPF);
	
EndProcedure

&AtServer
Procedure FillSendingParameters(SendingParametersPF)
	
	If SendingParameters = Undefined Then
		SendParametersTemp = New Structure;
		SendParametersTemp.Insert("Sender");
		SendParametersTemp.Insert("Text");
		SendParametersTemp.Insert("Subject");
		SendParametersTemp.Insert("Recipient", New Array);
	Else
		SendParametersTemp = CommonUse.CopyRecursive(SendingParameters, False);
	EndIf;
	
	If SendingParametersPF.Property("Recipient") Then
		SupplementArray(SendParametersTemp.Recipient, SendingParametersPF.Recipient);
	EndIf;
	
	SendParametersTemp.Subject = ?(ValueIsFilled(SendParametersTemp.Subject), NStr("en='Документы';ru='Документы';vi='Chứng từ'"), SendingParametersPF.Subject);
	
	If SendingParametersPF.Property("Sender") Then
		SendParametersTemp.Sender = SendingParametersPF.From;
	EndIf;
	
	SendingParameters = New FixedStructure(SendParametersTemp);
	
EndProcedure

&AtClientAtServerNoContext
Function GetAttachmentsFormatPresentation(SelectedSavingFormats, PackIntoArchive)
	
	AttachmentsFormat = "";
	
	For Each SelectedFormat In SelectedSavingFormats Do
		If SelectedFormat.Check Then
			If Not IsBlankString(AttachmentsFormat) Then
				AttachmentsFormat = AttachmentsFormat + ", ";
			EndIf;
			AttachmentsFormat = AttachmentsFormat + SelectedFormat.Presentation;
		EndIf;
	EndDo;
	
	If IsBlankString(AttachmentsFormat) Then
		AttachmentsFormat = NStr("en='<Не выбран формат вложений>';ru='<Не выбран формат вложений>';vi='<Chưa chọn định dạng đính kèm>'");
	EndIf;
	
	If PackIntoArchive Then
		AttachmentsFormat = NStr("en='Архив .zip:';ru='Архив .zip:';vi='Tệp nén .zip:'") + " " + AttachmentsFormat;
	EndIf;
	
	Return AttachmentsFormat;
	
EndFunction

&AtClient
Procedure CreateNewEmail()
	
	ResultHandler = New NotifyDescription("CreateNewEmailContinue", ThisObject);
	EmailOperationsClient.VerifyAccountForEmailSending(ResultHandler);
	
EndProcedure

&AtClient
Procedure CreateNewEmailContinue(Result, AdditionalParameters) Export
	
	If Result <> True Then
		Return;
	EndIf;
	
	NewLettersParameters = New Structure;
	NewLettersParameters.Insert("Recipient", SendingParameters.Recipient);
	NewLettersParameters.Insert("Subject", SendingParameters.Subject);
	NewLettersParameters.Insert("Text", SendingParameters.Text);
	NewLettersParameters.Insert("Attachments", AttachmentsDetailsArray());
	NewLettersParameters.Insert("BasisDocuments", CommonUseClientServer.CopyRecursive(SendingObjects));
	
	EmailOperationsClient.CreateNewEmail(NewLettersParameters);
	Close();
	
	If UserMessages <> Undefined And UserMessages.Count() > 0 Then
		For Each UserMessage In UserMessages Do
			CommonUseClientServer.MessageToUser(UserMessage.Text,
				UserMessage.DataKey, UserMessage.Field, UserMessage.DataPath);
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Function AttachmentsDetailsArray()
	
	Result = New Array;
	
	For Each Attachment In Attachments Do
		
		AttachmentDescription = New Structure;
		AttachmentDescription.Insert("Presentation", Attachment.Presentation);
		AttachmentDescription.Insert("AddressInTemporaryStorage", Attachment.Value);
		
		Result.Add(AttachmentDescription);
		
	EndDo;
	
	Return Result;
	
EndFunction

// Процедура дополняет массив приемник неуникальными значениями из массива источника.
// Для элементов-структур проверка осуществляется по совпадению ключей и значений структуры
//
&AtServerNoContext
Procedure SupplementArray(ArrayReceiver, ArraySource)
	
	If TypeOf(ArraySource) <> Type("Array") Then
		Return;
	EndIf;
	
	For Each SOURCEValue In ArraySource Do
		If TypeOf(SOURCEValue) = Type("Structure") Then
			Found = False;
			For Each DestinationValue In ArrayReceiver Do
				If TypeOf(DestinationValue) = Type("Structure") Then
					AllKeysMatch = True;
					For Each KeyAndValue In SOURCEValue Do
						If Not (DestinationValue.Property(KeyAndValue.Key) And DestinationValue[KeyAndValue.Key] = KeyAndValue.Value) Then
							AllKeysMatch = False;
							Break;
						EndIf;
					EndDo;
					If AllKeysMatch Then
						Found = True;
						Break;
					EndIf;
				EndIf;
			EndDo;
			If Not Found Then
				ArrayReceiver.Add(SOURCEValue);
			EndIf;
		ElsIf ArrayReceiver.Find(SOURCEValue) = Undefined Then
			ArrayReceiver.Add(SOURCEValue);
		EndIf;
	EndDo;
	
EndProcedure

// Отправка печатных форм договора будет осуществляться только из формы элемента/списка договора,
// значит других печатных форм нет.
//
&AtServer
Function IsSendingContractPrintForms()
	
	For Each Item In PrintForms Do
		
		If StrStartsWith(Item.Value, "CounterpartyContract") Then
			Return True;
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

&AtServer
Function SelectedPrintCommands(CommandIDs)
	
	SelectedPrintCommands = New Array;
	PrintCommands = GetFromTempStorage(PrintCommandsAddress);
	For Each CommandID In CommandIDs Do
		PrintCommand = PrintCommands.Find(CommandID, "ID");
		If PrintCommand <> Undefined Then
			SelectedPrintCommands.Add(PrintCommand);
		EndIf;
	EndDo;
	Return SelectedPrintCommands;
	
EndFunction

#EndRegion
