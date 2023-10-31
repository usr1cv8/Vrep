#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not ValueIsFilled(Object.Ref)
	   And Parameters.FillingValues.Property("Description") Then
		
		Object.Description = Parameters.FillingValues.Description;
	EndIf;
	
	If Not Parameters.HideOwner Then
		Items.Owner.Visible = True;
	EndIf;
	
	If TypeOf(Parameters.ShowWeight) = Type("Boolean") Then
		ShowWeight = Parameters.ShowWeight;
	Else
		ShowWeight = CommonUse.ObjectAttributeValue(Object.Owner, "AdditionalValuesWithWeight");
	EndIf;
	
	If ShowWeight = True Then
		Items.Weight.Visible = True;
		StandardSubsystemsServer.SetFormPurposeKey(ThisObject, "ValuesWithWeight");
	Else
		Items.Weight.Visible = False;
		Object.Weight = 0;
		StandardSubsystemsServer.SetFormPurposeKey(ThisObject, "ValueWithoutWeight");
	EndIf;
	
	SetCaption();
		
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Src)
	
	If EventName = "Update_ValueIsCharacterizedByWeighting"
	   And Src = Object.Owner Then
		
		If Parameter = True Then
			Items.Weight.Visible = True;
		Else
			Items.Weight.Visible = False;
			Object.Weight = 0;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	SetCaption();
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Record_ValuesOfObjectPropertiesHierarchy",
		New Structure("Ref", Object.Ref), Object.Ref);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
EndProcedure

#EndRegion

#Region HeaderFormItemsEventsHandlers

&AtClient
Procedure Attachable_Open(Item, StandardProcessing)
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Procedure SetCaption()
	
	If CurrentLanguage() = Metadata.DefaultLanguage Then
		AttributeValues = CommonUse.ObjectAttributesValues(
			Object.Owner, "Title, ValueFormHeader");
	Else
		Attributes = New Array;
		Attributes.Add("Title");
		Attributes.Add("ValueFormHeader");
		AttributeValues = PropertiesManagementService.LocalizedAttributeValues(Object.Owner, Attributes);
	EndIf;
	
	PropertyName = TrimAll(AttributeValues.ValueFormHeader);
	
	If Not IsBlankString(PropertyName) Then
		If ValueIsFilled(Object.Ref) Then
			Title = StringFunctionsClientServer.SubstituteParametersInString(NStr("en='%1 (%2)';ru='%1 (%2)';vi='%1 (%2)'"),
				Object.Description,
				PropertyName);
		Else
			Title = StringFunctionsClientServer.SubstituteParametersInString(NStr("en='%1 (Создание)';ru='%1 (Создание)';vi='%1 (Tạo)'"), PropertyName);
		EndIf;
	Else
		PropertyName = String(AttributeValues.Title);
		
		If ValueIsFilled(Object.Ref) Then
			Title = StringFunctionsClientServer.SubstituteParametersInString(NStr("en='%1 (Значение свойства %2)';ru='%1 (Значение свойства %2)';vi='%1 (Giá trị tính chất %2)'"),
				Object.Description,
				PropertyName);
		Else
			Title = StringFunctionsClientServer.SubstituteParametersInString(NStr("en='Значение свойства %1 (Создание)';ru='Значение свойства %1 (Создание)';vi='Giá trị thuộc tính %1 (Tạo)'"), PropertyName);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion
