
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then // Return if the form for analysis is received.
		Return;
	EndIf;
	
	If Object.Predefined Then
		Items.Description.ReadOnly = True;
		Items.Parent.ReadOnly      = True;
		Items.Type.ReadOnly        = True;
		Items.ToolTip.ReadOnly     = True;
		
	Else
		// Object attribute editing prohibition subsystem handler.
		If CommonUse.SubsystemExists("StandardSubsystems.ObjectsAttributesEditProhibition") Then
			ObjectAttributeEditProhibitionModule = CommonUse.CommonModule("ObjectsAttributesEditProhibition");
			ObjectAttributeEditProhibitionModule.LockAttributes(ThisObject,, NStr("en='Allow editing type and group';ru='Разрешить редактирование типа и группы';vi='Cho phép soạn kiểu và nhóm'"));
			
		Else
			Items.Parent.ReadOnly = True;
			Items.Type.ReadOnly = True;
			
		EndIf;
	EndIf;
	
	ParentRef = Object.Parent;
	CurrentLevel = ?(ParentRef.IsEmpty(), 0, ParentRef.Level() );
	
	Items.AllowMultipleValueInput.Enabled = ?(CurrentLevel = 1, False, True);
	
	If Not Object.CanChangeEditMode Then
		Items.EditInDialogOnly.Enabled					= False;
		Items.AllowMultipleValueInput.Enabled			= False;
		Items.DescriptionSettingsByTypeGroup.Enabled	= False;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ChangeRepresentationOnTypeChange();
	ChangeEditInDialogMode();

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Not CurrentObject.CheckFilling() Then
		Cancel = True;
	EndIf;
	
	//Address classified is not available
	Object.CheckValidity			= False;
	Object.ProhibitInvalidEntry		= False;
	Object.HideObsoleteAddresses	= False;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	If Not CurrentObject.Predefined Then
		// Object attribute editing prohibition subsystem handler.
		If CommonUse.SubsystemExists("StandardSubsystems.ObjectsAttributesEditProhibition") Then
			ObjectAttributeEditProhibitionModule = CommonUse.CommonModule("ObjectsAttributesEditProhibition");
			ObjectAttributeEditProhibitionModule.LockAttributes(ThisObject);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, AttributesToCheck)
	
	AttributesToCheck.Clear();
	
EndProcedure

#EndRegion

#Region FormHeaderItemEventHandlers

&AtClient
Procedure TypeOnChange(Item)
	
	ChangeAttributesOnTypeChange();
	ChangeRepresentationOnTypeChange();
	
EndProcedure

&AtClient
Procedure ClearType(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure DomesticAddressOnlyOnChange(Item)
	
	ChangeEditInDialogMode();	
	
EndProcedure

&AtClient
Procedure ProhibitInvalidEntryOnChange(Item)
	
	ChangeAttributesOnChangeCheckValidity();
	
EndProcedure

&AtClient
Procedure CheckValidityOnChange(Item)
	
	ChangeAttributesOnChangeCheckValidity();
	
EndProcedure

&AtClient
Procedure EditInDialogOnlyOnChange(Item)
	ChangeEditInDialogMode();
EndProcedure


#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Attachable_AllowObjectAttributesEditing(Command)
	
	If Not Object.Predefined Then
		If CommonUseClient.SubsystemExists("StandardSubsystems.ObjectsAttributesEditProhibition") Then
			ObjectAttributeEditProhibitionClientModule = CommonUseClient.CommonModule("ObjectsAttributesEditProhibitionClient");
			ObjectAttributeEditProhibitionClientModule.AllowObjectAttributesEditing(ThisObject);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtClient
Procedure ChangeEditInDialogMode()
	
	If Not Object.EditInDialogOnly Then
		Object.DomesticAddressOnly			= False;
		Object.IncludeCountryInPresentation = False;
	EndIf;
	
	IsEditInDialogOnlyOn = Object.EditInDialogOnly 
							Or Object.DomesticAddressOnly 
							Or Object.IncludeCountryInPresentation;
	
	Items.DomesticAddressOnly.Enabled  			= IsEditInDialogOnlyOn;
	Items.IncludeCountryInPresentation.Enabled  = IsEditInDialogOnlyOn;
	
EndProcedure

&AtClient
Procedure ChangeRepresentationOnTypeChange()
	
	If Object.Type = PredefinedValue("Enum.ContactInformationTypes.Address") Then
		Items.Checks.CurrentPage = Items.Checks.ChildItems.Address;
		ChangeEditInDialogMode();
		
	ElsIf Object.Type = PredefinedValue("Enum.ContactInformationTypes.EmailAddress") Then
		Items.Checks.CurrentPage = Items.Checks.ChildItems.EmailAddress;
		Items.EditInDialogOnly.Enabled = False;
		
	ElsIf Object.Type = PredefinedValue("Enum.ContactInformationTypes.Skype") Then
		Items.Checks.CurrentPage = Items.Checks.ChildItems.Skype;
		Items.EditInDialogOnly.Enabled = False;
		Items.AllowMultipleValueInput.Enabled = True;
		
	ElsIf Object.Type = PredefinedValue("Enum.ContactInformationTypes.Phone")
		Or Object.Type = PredefinedValue("Enum.ContactInformationTypes.Fax") Then
		Items.Checks.CurrentPage = Items.Checks.ChildItems.Another;
		Items.EditInDialogOnly.Enabled = Object.CanChangeEditMode;
		
	Else
		Items.Checks.CurrentPage = Items.Checks.ChildItems.Another;
		Items.EditInDialogOnly.Enabled = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeAttributesOnTypeChange()
	
	If Object.Type = PredefinedValue("Enum.ContactInformationTypes.Address") Then
		ChangeEditInDialogMode();
		
	ElsIf Object.Type = PredefinedValue("Enum.ContactInformationTypes.EmailAddress") Then
		Object.EditInDialogOnly = False;
		ChangeAttributesOnChangeCheckValidity();
		
	ElsIf Object.Type = PredefinedValue("Enum.ContactInformationTypes.Phone")
		Or Object.Type = PredefinedValue("Enum.ContactInformationTypes.Fax") Then
		// No changes
		
	Else
		Object.EditInDialogOnly = False;

	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeAttributesOnChangeCheckValidity()
	
	Object.ProhibitInvalidEntry = Object.CheckValidity;
	
EndProcedure

#EndRegion
