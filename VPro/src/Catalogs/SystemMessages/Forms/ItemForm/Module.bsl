
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then // Return if the form for analysis is received.
		Return;
	EndIf;
	
	MessageBody = CommonUse.ObjectAttributeValue(Object.Ref, "Body").Get();
	
	If TypeOf(MessageBody) = Type("String") Then
		
		MessageBodyPresentation = MessageBody;
		
	Else
		
		Try
			MessageBodyPresentation = CommonUse.ValueToXMLString(MessageBody);
		Except
			MessageBodyPresentation = NStr("en='Email body cannot be displayed as a string.';ru='Тело сообщения не может быть представлено строкой.';vi='Không thể trình bày thân thông báo theo dòng.'");
		EndTry;
		
	EndIf;
	
EndProcedure

#EndRegion
