
#Region FormEventsHandlers
//

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then 
		// Return if the form for analysis is received.
		Return;
	EndIf;
	
	FillPropertyValues(Object, Parameters.Object , , "ComposerAllDocumentsFilter, AdditionalRegistration, AdditionalRegistrationScriptSite");
	For Each String IN Parameters.Object.AdditionalRegistration Do
		FillPropertyValues(Object.AdditionalRegistration.Add(), String);
	EndDo;
	For Each String IN Parameters.Object.AdditionalRegistrationScriptSite Do
		FillPropertyValues(Object.AdditionalRegistrationScriptSite.Add(), String);
	EndDo;
	
	// Initialize composer manually.
	ObjectDataProcessor = FormAttributeToValue("Object");
	
	Data = GetFromTempStorage(Parameters.Object.AddressLinkerAllDocuments);
	ObjectDataProcessor.ComposerAllDocumentsFilter = New DataCompositionSettingsComposer;
	ObjectDataProcessor.ComposerAllDocumentsFilter.Initialize(
		New DataCompositionAvailableSettingsSource(Data.CompositionSchema));
	ObjectDataProcessor.ComposerAllDocumentsFilter.LoadSettings(Data.Settings);
	
	ValueToFormAttribute(ObjectDataProcessor, "Object");
	
	ViewCurrentSettings = Parameters.ViewCurrentSettings;
	ReadSavedSettings();
EndProcedure

#EndRegion

#Region FormTableItemEventHandlersSettingVariants
//

&AtClient
Procedure SettingVariantsCase(Item, SelectedRow, Field, StandardProcessing)
	CurrentData = SettingVariants.FindByID(SelectedRow);
	If CurrentData<>Undefined Then
		ViewCurrentSettings = CurrentData.Presentation;
	EndIf;
EndProcedure

&AtClient
Procedure SettingsOptionsBeforeBeginAdding(Item, Cancel, Copy, Parent, Group)
	Cancel = True;
EndProcedure

&AtClient
Procedure SettingsOptionsBeforeDeleting(Item, Cancel)
	Cancel = True;
	
	SettingRepresentation = Item.CurrentData.Presentation;
	
	HeaderText = NStr("en='Confirmation';ru='Подтверждение';vi='Xác nhận'");
	QuestionText   = NStr("en='Remove setting ""%1""?';ru='Удалить настройку ""%1""?';vi='Xóa tùy chỉnh ""%1""?'");
	
	QuestionText = StrReplace(QuestionText, "%1", SettingRepresentation);
	
	AdditionalParameters = New Structure("SettingRepresentation", SettingRepresentation);
	NotifyDescription = New NotifyDescription("NotificationSettingOptionDeletionQuery", ThisObject, 
		AdditionalParameters);
	
	ShowQueryBox(NOTifyDescription, QuestionText, QuestionDialogMode.YesNo,,,HeaderText);
EndProcedure

#EndRegion

#Region FormCommandsHandlers
//

&AtClient
Procedure SaveSetting(Command)
	
	If IsBlankString(ViewCurrentSettings) Then
		CommonUseClientServer.MessageToUser(
			NStr("en='Name for the current setting is not entered.';ru='Не заполнено имя для текущей настройки.';vi='Chưa điền tên đối với tùy chỉnh hiện tại.'"), , "ViewCurrentSettings");
		Return;
	EndIf;
		
	If SettingVariants.FindByValue(ViewCurrentSettings)<>Undefined Then
		HeaderText = NStr("en='Confirmation';ru='Подтверждение';vi='Xác nhận'");
		QuestionText   = NStr("en='Rewrite existing setting ""%1""?';ru='Перезаписать существующую настройку ""%1""?';vi='Ghi lại tùy chỉnh hiện tại ""%1""?'");
		QuestionText = StrReplace(QuestionText, "%1", ViewCurrentSettings);
		
		AdditionalParameters = New Structure("SettingRepresentation", ViewCurrentSettings);
		NotifyDescription = New NotifyDescription("NotificationSettingOptionSaveQuery", ThisObject, 
			AdditionalParameters);
			
		ShowQueryBox(NOTifyDescription, QuestionText, QuestionDialogMode.YesNo,,,HeaderText);
		Return;
	EndIf;
	
	// Save without prompts
	SaveAndExecuteCurrentSettingChoice();
EndProcedure
	
&AtClient
Procedure MakeSelection(Command)
	ExecuteCase(ViewCurrentSettings);
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions
//

&AtServer
Function ThisObject(NewObject=Undefined)
	If NewObject=Undefined Then
		Return FormAttributeToValue("Object");
	EndIf;
	ValueToFormAttribute(NewObject, "Object");
	Return Undefined;
EndFunction

&AtServer
Procedure RemoveSettingServer(SettingRepresentation)
	ThisObject().RemoveSettingsOption(SettingRepresentation);
EndProcedure

&AtServer
Procedure ReadSavedSettings()
	ThisDataProcessor = ThisObject();
	
	VariantsFilter = DataExchangeServer.InteractiveExchangeFilterOptionsExportings(Object);
	SettingVariants = ThisDataProcessor.ReadSettingsListPresentations(Object.InfobaseNode, VariantsFilter);
	
	ItemOfList = SettingVariants.FindByValue(ViewCurrentSettings);
	Items.SettingVariants.CurrentRow = ?(ItemOfList=Undefined, Undefined, ItemOfList.GetID())
EndProcedure

&AtServer
Procedure SaveCurrentSettings()
	ThisObject().SaveCurrentToSettings(ViewCurrentSettings);
EndProcedure

&AtClient
Procedure ExecuteCase(Presentation)
	If SettingVariants.FindByValue(Presentation)<>Undefined AND CloseOnChoice Then 
		NotifyChoice( New Structure("ChoiceAction, SettingRepresentation", 3, Presentation) );
	EndIf;
EndProcedure

&AtClient
Procedure NotificationSettingOptionDeletionQuery(Result, AdditionalParameters) Export
	If Result<>DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	RemoveSettingServer(AdditionalParameters.SettingRepresentation);
	ReadSavedSettings();
EndProcedure

&AtClient
Procedure NotificationSettingOptionSaveQuery(Result, AdditionalParameters) Export
	If Result<>DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ViewCurrentSettings = AdditionalParameters.SettingRepresentation;
	SaveAndExecuteCurrentSettingChoice();
EndProcedure

&AtClient
Procedure SaveAndExecuteCurrentSettingChoice()
	
	SaveCurrentSettings();
	ReadSavedSettings();
	
	CloseOnChoice = True;
	ExecuteCase(ViewCurrentSettings);
EndProcedure;

#EndRegion
