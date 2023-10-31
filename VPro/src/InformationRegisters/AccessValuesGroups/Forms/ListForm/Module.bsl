
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest") Then // Return if the form for analysis is received.
		Return;
	EndIf;
	
	ReadOnly = True;
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure EnableEditingAbility(Command)
	
	ReadOnly = False;
	
EndProcedure

&AtClient
Procedure RefreshDataRegister(Command)
	
	HasChanges = False;
	
	RegisterDataUpdateOnServer(HasChanges);
	
	If HasChanges Then
		Text = NStr("en='Update was successful.';ru='Обновление выполнено успешно.';vi='Cập nhật thực hiện thành công.'");
	Else
		Text = NStr("en='Update is not required.';ru='Обновление не требуется.';vi='Cập nhật không cần.'");
	EndIf;
	
	ShowMessageBox(, Text);
	
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	IssueDataGroup(0, NStr("en='Default access values';ru='Стандартные значения доступа';vi='Giá trị truy cập chuẩn'"));
	IssueDataGroup(1, NStr("en='Standard/external users';ru='Обычные/внешние пользователи';vi='Người sử dụng thông thường/ngoài'"));
	IssueDataGroup(2, NStr("en='Standard/external user groups';ru='Обычные/внешние группы пользователей';vi='Nhóm người sử dụng thông thường/ngoài'"));
	IssueDataGroup(3, NStr("en='Performer groups';ru='Группы исполнителей';vi='Nhóm người thực hiện'"));
	IssueDataGroup(4, NStr("en='Authorization objects';ru='Объекты авторизации';vi='Đối tượng đăng nhập'"));
	
EndProcedure

&AtServer
Procedure IssueDataGroup(DataGroup, Text)
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DataGroupList.Name);
	
	FilterElement = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("List.DataGroup");
	FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
	FilterElement.RightValue = DataGroup;
	
	Item.Appearance.SetParameterValue("Text", Text);
	
EndProcedure

&AtServer
Procedure RegisterDataUpdateOnServer(HasChanges)
	
	SetPrivilegedMode(True);
	
	InformationRegisters.AccessValuesGroups.RefreshDataRegister(HasChanges);
	
	Items.List.Refresh();
	
EndProcedure

#EndRegion
