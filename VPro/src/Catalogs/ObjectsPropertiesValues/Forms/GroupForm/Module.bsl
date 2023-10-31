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
	
	SetCaption();
		
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.УправлениеДоступом
	If CommonUse.SubsystemExists("StandardSubsystems.AccessManagement") Then
		AccessControlModule = CommonUse.CommonModule("AccessManagement");
		AccessControlModule.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.УправлениеДоступом

	SetCaption();

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	// StandardSubsystems.УправлениеДоступом
	If CommonUse.SubsystemExists("StandardSubsystems.AccessManagement") Then
		AccessControlModule = CommonUse.CommonModule("AccessManagement");
		AccessControlModule.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.УправлениеДоступом
	

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
	
	AttributeValues = CommonUse.ObjectAttributesValues(
		Object.Owner, "Title, ValueFormHeader");
	
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
			Title = StringFunctionsClientServer.SubstituteParametersInString(NStr("en='%1 (Группа значений свойства %2)';ru='%1 (Группа значений свойства %2)';vi='%1 (Nhóm giá trị tính chất %2)'"),
				Object.Description,
				PropertyName);
		Else
			Title = StringFunctionsClientServer.SubstituteParametersInString(NStr("en='Группа значений свойства %1 (Создание)';ru='Группа значений свойства %1 (Создание)';vi='Nhóm giá trị thuộc tính %1 (Tạo)'"), PropertyName);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion