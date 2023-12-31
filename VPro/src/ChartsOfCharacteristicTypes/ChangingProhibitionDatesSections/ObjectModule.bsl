#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventsHandlers

// Prevents from changing the change prohibition dates sections
// which should be changed in the designer mode only.
//
Procedure BeforeWrite(Cancel)
	
	If Predefined AND DataExchange.Load Then
		FillPropertyValues(ThisObject, CommonUse.ObjectAttributesValues(Ref, "ValueType, Description"));
	EndIf;
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	Raise(NStr("en='You can change the"
"sections of the change prohibition dates in the Designer only."
""
"Deleting is allowed.';ru='Изменение разделов дат запрета изменения"
"выполняется только через конфигуратор."
""
"Удаление допустимо.';vi='Thay đổi phần hành ngày cấm thay đổi"
"chỉ được thực hiện thông qua bộ thiết kế."
""
"Xóa bỏ cho phép.'"));
	
EndProcedure

#EndRegion

#EndIf