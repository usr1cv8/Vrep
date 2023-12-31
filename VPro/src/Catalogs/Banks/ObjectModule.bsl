#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventsHandlers

Procedure OnCopy(CopiedObject)
	
	Code = "";
	
EndProcedure // OnCopy()

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If DataExchange.Load Then
		Return;
	EndIf;
			
	If Not IsFolder Then
	
		If StrLen(TrimAll(Code)) <> 8 AND StrLen(TrimAll(Code)) <> 11 Then
			MessageText = NStr("en='SWIFT must have 8 or 11 characters.';ru='SWIFT банка должен иметь 8 или 11 знаков.';vi='Mã ngân hàng cần có 8 hoặc 11 ký tự.'");
			SmallBusinessServer.ShowMessageAboutError(
				ThisObject,
				MessageText,
				,
				,
				"Code",
				Cancel
			);
		EndIf;

	Else
		
		SmallBusinessServer.DeleteAttributeBeingChecked(CheckedAttributes, "Code");
		
	EndIf;
	
EndProcedure // FillCheckProcessing()

#EndRegion

#EndIf