#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventsHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If ValueIsFilled(Owner) Then
		AdditionalValuesOwner = CommonUse.ObjectAttributeValue(Owner,
			"AdditionalValuesOwner");
		
		If ValueIsFilled(AdditionalValuesOwner) Then
			ErrorDescription = StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en='Дополнительные значения для свойства ""%1"", созданного"
"по образцу свойства ""%2"" нужно создавать для свойства-образца.';ru='Дополнительные значения для свойства ""%1"", созданного"
"по образцу свойства ""%2"" нужно создавать для свойства-образца.';vi='Các giá trị bổ sung cho thuộc tính ""%1"" được mô hình hóa trên thuộc tính ""%2"" phải được tạo cho thuộc tính tham chiếu.'"),
				Owner,
				AdditionalValuesOwner);
			
			If IsNew() Then
				Raise ErrorDescription;
			Else
				CommonUseClientServer.MessageToUser(ErrorDescription);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region ServiceProgramInterface

Procedure OnReadPresentationsAtServer() Export

EndProcedure

#EndRegion

#Else
Raise NStr("en='Invalid object call at client.';ru='Недопустимый вызов объекта на клиенте.';vi='Không thể gọi ra đối tượng trên Client.'");
#EndIf