
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If PropertiesManagementService.AdditionalPropertyInUse(Parameters.Ref) Then
		
		Items.UserDialogs.CurrentPage = Items.ObjectIsUsed;
		
		Items.AllowEdit.DefaultButton = True;
		
		If Parameters.ThisIsAdditionalAttribute = True Then
			Items.Warnings.CurrentPage = Items.AdditionalAttributeWarning;
		Else
			Items.Warnings.CurrentPage = Items.AdditionalInformationWarning;
		EndIf;
		
		StandardSubsystemsServer.SetFormPurposeKey(ThisObject, "PropertyUsed");
		Items.DetailsButtons.Visible = False;
	Else
		Items.UserDialogs.CurrentPage = Items.ObjectIsNotUsed;
		Items.ObjectIsUsed.Visible = False; // Для компактного отображения формы.
		
		Items.OK.DefaultButton = True;
		
		If Parameters.ThisIsAdditionalAttribute = True Then
			Items.Explanations.CurrentPage = Items.AdditionalAttributesExplanation;
		Else
			Items.Explanations.CurrentPage = Items.AdditionalInformationExplanation;
		EndIf;
		
		StandardSubsystemsServer.SetFormPurposeKey(ThisObject, "PropertyNotUsed");
		Items.ButtonsToPrevent.Visible = False;
	EndIf;
	
	If CommonUse.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Top;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure AllowEdit(Command)
	
	UnlockableAttributes = New Array;
	UnlockableAttributes.Add("ValueType");
	UnlockableAttributes.Add("Name");
	
	Close(UnlockableAttributes);
	
EndProcedure

#EndRegion
