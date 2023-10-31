
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ThisObject.ReadOnly = Parameters.ReadOnly;
	
	Items.Ref.TypeRestriction  = Parameters.ValueType;
	ReferenceTypeRow             = Parameters.ReferenceTypeRow;
	Items.Presentation.Visible = ReferenceTypeRow;
	Items.Ref.Title        = Parameters.DescriptionAttribute;
	
	UsageKey = ?(ReferenceTypeRow, "RowEdit", "ReferenceObjectEdit");
	StandardSubsystemsServer.SetFormPurposeKey(ThisObject, UsageKey);
	
	If Not Parameters.ReferenceTypeRow
		And PropertiesManagementService.ValueTypeContainsPropertiesValues(Parameters.ValueType) Then
		ChoiceParameter = ?(ValueIsFilled(Parameters.AdditionalValuesOwner),
			Parameters.AdditionalValuesOwner, Parameters.Property);
	EndIf;
	
	ReturnValue = New Structure;
	ReturnValue.Insert("AttributeName", Parameters.AttributeName);
	ReturnValue.Insert("ReferenceTypeRow", ReferenceTypeRow);
	If Parameters.ReferenceTypeRow Then
		ReturnValue.Insert("RefAttributeName", Parameters.RefAttributeName);
		
		RefAndPresentation = PropertiesManagementService.AddressAndPresentation(Parameters.ValueOfAttribute);
		Ref        = RefAndPresentation.Ref;
		Presentation = RefAndPresentation.Presentation;
	Else
		Ref = Parameters.ValueOfAttribute;
	EndIf;
	
	If CommonUse.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Top;
		Items.FormOKButton.Representation = ButtonRepresentation.Picture;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If ChoiceParameter = Undefined Then
		Return;
	EndIf;
	
	ChoiceParametersArray = New Array;
	ChoiceParametersArray.Add(New ChoiceParameter("Filter.Owner", ChoiceParameter));
	
	Items.Ref.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure OKButton(Command)
	If ReferenceTypeRow Then
		Pattern = "<a href = ""%1"">%2</a>";
		If Not ValueIsFilled(Presentation) Then
			Presentation = Ref;
		EndIf;
		If Not ValueIsFilled(Ref) Then
			Value = "";
			ReturnValue.Insert("FormattedString", BlankFormattedString());
		Else
			Value = StringFunctionsClientServer.SubstituteParametersInString(Pattern, Ref, Presentation);
			ReturnValue.Insert("FormattedString", StringFunctionsClientServer.FormattedString(Value));
		EndIf;
	Else
		Value = Ref;
	EndIf;
	
	ReturnValue.Insert("Value", Value);
	Close(ReturnValue);
EndProcedure

&AtClient
Procedure ButtonCancel(Command)
	Close();
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Function BlankFormattedString()
	ValueDescription= NStr("en='not set';ru='не задано';vi='chưa đặt'");
	EditLink = "NotDefined";
	Result            = New FormattedString(ValueDescription,, StyleColors.EmptyHyperlinkColor,, EditLink);
	
	Return Result;
EndFunction

#EndRegion