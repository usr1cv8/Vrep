
////////////////////////////////////////////////////////////////////////////////
// FORM EVENT HANDLERS

// Procedure - OnCreateAtServer event handler.
//
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	HTMLData = FormAttributeToValue("Object").GetTemplate("DetailedDescriptionHTML");
	DetailedDescriptionText = HTMLData.GetText();
	
	TransitionLink = NStr("en='link_';vi='link_'") + Parameters.TransitionLink;
	
EndProcedure


////////////////////////////////////////////////////////////////////////////////
// FORM ITEMS EVENTS HANDLERS

//Procedure-handler of the event of HTML-document generating end of the TextDetailedDescription field
//
&AtClient
Procedure DetailedDescriptionTextDocumentCreated(Item)
	
	If TransitionLink = "" Then
		Return;	
	EndIf;
	
	For Each LinkItem IN Items.DetailedDescriptionText.Document.Links Do
		If LinkItem.name = TransitionLink Then
			LinkItem.Click();
		EndIf;
	EndDo; 	
	
EndProcedure
