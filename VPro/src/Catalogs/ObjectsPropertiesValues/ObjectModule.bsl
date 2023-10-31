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
				NStr("en='Additional values for property"
"""%1"" created on the model of property ""% 2"" shall be created for sample property.';ru='Дополнительные"
"значения для свойства ""%1"", созданного по образцу свойства ""%2"" нужно создавать для свойства-образца.';vi='Cần tạo giá trị"
"bổ sung đối với thuộc tính ""%1"" được tạo theo mẫu thuộc tính ""%2"" đối với thuộc tính mẫu.'"),
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