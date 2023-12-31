
////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - FORM EVENT HANDLERS

// Procedure - event handler OnCreateAtServer of the form.
//
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ResourcesList.Parameters.SetParameterValue("EnterpriseResourceKind", Object.Ref);
	
	// Delete prohibition from the All resources kind content.
	If Object.Ref = Catalogs.EnterpriseResourcesKinds.AllResources Then
		Items.ResourcesList.CommandBar.ChildItems.ResourcesListDelete.Enabled = False;
		Items.ResourcesList.ContextMenu.ChildItems.ResourcesListContextMenuDelete.Enabled = False;
	EndIf;
	
EndProcedure // OnCreateAtServer()

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Record_EnterpriseResourcesKinds" Then
		
		ResourcesList.Parameters.SetParameterValue("EnterpriseResourceKind", Object.Ref);
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - EVENTS HANDLER OF LIST FORM

// Procedure - Change event handler of the ResourcesList form list.
//
&AtClient
Procedure ListChange(Command)
	
	If Not ValueIsFilled(Object.Ref) Then
		Message = New UserMessage();
		Message.Text = NStr("en='The data is not written yet.';ru='Данные еще не записаны.';vi='Dữ liệu vẫn chưa được ghi lại.'");
		Message.Message();
	Else
		OpenParameters = New Structure;
		OpenParameters.Insert("Key", Items.ResourcesList.CurrentRow);
		OpenParameters.Insert("AvailabilityOfKind", False);
		If Items.ResourcesList.CurrentRow = Undefined Then
			OpenParameters.Insert("ValueEnterpriseResourceKind", Object.Ref);
		EndIf;
		OpenForm("InformationRegister.EnterpriseResourcesKinds.RecordForm", OpenParameters);
		
	EndIf;
	
EndProcedure // ListChange()

// Procedure - BeforeAddingBegin event handler of the ResourcesList form list.
//
&AtClient
Procedure ResourcesListBeforeAddRow(Item, Cancel, Copy, Parent, Group)
	
	Cancel = True;
	If Not ValueIsFilled(Object.Ref) Then
		Message = New UserMessage();
		Message.Text = NStr("en='The data is not written yet.';ru='Данные еще не записаны.';vi='Dữ liệu vẫn chưa được ghi lại.'");
		Message.Message();
	Else
		OpenParameters = New Structure;
		OpenParameters.Insert("AvailabilityOfKind", False);
		OpenParameters.Insert("ValueEnterpriseResourceKind", Object.Ref);
		OpenForm("InformationRegister.EnterpriseResourcesKinds.RecordForm", OpenParameters, Item);
	EndIf;
	
EndProcedure // ResourcesListBeforeAddRow()

// Procedure - Selection event handler of the ResourcesList form list.
//
&AtClient
Procedure ResourcesListSelection(Item, SelectedRow, Field, StandardProcessing)
	
	StandardProcessing = False;
	OpenParameters = New Structure;
	OpenParameters.Insert("Key", Items.ResourcesList.CurrentRow);
	OpenParameters.Insert("AvailabilityOfKind", False);
	OpenForm("InformationRegister.EnterpriseResourcesKinds.RecordForm", OpenParameters);
	
EndProcedure // ResourcesListSelection()

// Procedure - BeforeDelete event handler of the ResourcesList form list.
//
&AtClient
Procedure ResourcesListBeforeDeleteRow(Item, Cancel)
	
	If Object.Ref = PredefinedValue("Catalog.EnterpriseResourcesKinds.AllResources") Then
		MessageText = NStr("en='Object is not deleted as the company resource should be included in the ""All resources"" kind.';ru='Объект не удален, т. к. ресурс предприятия должен входить в вид ""Все ресурсы"".';vi='Đối tượng không xóa bỏ được bởi vì nguồn lực trong doanh nghiệp phải nằm trong dạng ""Tất cả nguồn lực"".'");
		SmallBusinessClient.ShowMessageAboutError(Object, MessageText, , , , Cancel);
	EndIf;
	
EndProcedure // ResourcesListBeforeDeleteRow()

// Procedure - AfterDeletion event handler of the ResourcesList form list.
//
&AtClient
Procedure ResourcesListAfterDeleteRow(Item)
	
	Notify("Record_EnterpriseResourcesKinds");
	
EndProcedure // ResourcesListAfterDeleteRow()
