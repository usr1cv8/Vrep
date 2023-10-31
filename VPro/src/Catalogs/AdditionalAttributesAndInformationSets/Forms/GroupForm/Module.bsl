#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ReadOnly = True;
	
	SetPropertyTypes = PropertiesManagementService.SetPropertyTypes(Object.Ref);
	UseAdditAttributes = SetPropertyTypes.AdditionalAttributes;
	UseAdditInfo  = SetPropertyTypes.AdditionalInformation;
	
	If UseAdditAttributes And UseAdditInfo Then
		Title = Object.Description + " " + NStr("en='(Group of additional attribute and information sets)';ru='(Группа наборов дополнительных реквизитов и сведений)';vi='(Nhóm tập hợp mục tin và thông tin bổ sung)'")
		
	ElsIf UseAdditAttributes Then
		Title = Object.Description + " " + NStr("en='(Group of additional attribute sets)';ru='(Группа наборов дополнительных реквизитов)';vi='(Nhóm tập hợp mục tin bổ sung)'")
		
	ElsIf UseAdditInfo Then
		Title = Object.Description + " " + NStr("en='(Group of additional information sets)';ru='(Группа наборов дополнительных сведений)';vi='(Nhóm tập hợp thông tin bổ sung)'")
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

EndProcedure

#EndRegion
