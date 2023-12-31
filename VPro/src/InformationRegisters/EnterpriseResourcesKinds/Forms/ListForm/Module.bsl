
&AtClient
Procedure ListChange(Command)
	
	StandardProcessing = False;
	OpenParameters = New Structure;
	OpenParameters.Insert("Key", Items.List.CurrentRow);
	OpenParameters.Insert("AvailabilityAllResources", False);
	OpenForm("InformationRegister.EnterpriseResourcesKinds.RecordForm", OpenParameters);
	
EndProcedure

&AtClient
Procedure ListSelection(Item, SelectedRow, Field, StandardProcessing)
	
	StandardProcessing = False;
	OpenParameters = New Structure;
	OpenParameters.Insert("Key", Items.List.CurrentRow);
	OpenParameters.Insert("AvailabilityAllResources", False);
	OpenForm("InformationRegister.EnterpriseResourcesKinds.RecordForm", OpenParameters);
	
EndProcedure

&AtClient
Procedure ListBeforeDelete(Item, Cancel)
	
	CurrentListRow = Items.List.CurrentData;
	If CurrentListRow <> Undefined Then
		If CurrentListRow.EnterpriseResourceKind = PredefinedValue("Catalog.EnterpriseResourcesKinds.AllResources") Then
			MessageText = NStr("en='Object is not deleted as the company resource should be included in the ""All resources"" kind.';ru='Объект не удален, т. к. ресурс предприятия должен входить в вид ""Все ресурсы"".';vi='Đối tượng không xóa bỏ được bởi vì nguồn lực trong doanh nghiệp phải nằm trong dạng ""Tất cả nguồn lực"".'");
			SmallBusinessClient.ShowMessageAboutError(ThisForm, MessageText, , , , Cancel);
		EndIf;
	EndIf;
	
EndProcedure
