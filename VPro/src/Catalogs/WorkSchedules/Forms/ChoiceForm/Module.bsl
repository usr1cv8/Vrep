
&AtClient
Procedure ListOnActivateRow(Item)
	
	CurrentData = Items.List.CurrentData;
	
	If CurrentData = Undefined Then Return EndIf;
	
	
	CommonUseClientServer.SetFilterDynamicListItem(СущностиПоГрафику, 
	"WorkSchedule",
	CurrentData.Ref,
	DataCompositionComparisonType.Equal);
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FilterField = New DataCompositionField("NotValid");
	
	НовыйОтбор = List.Filter.Items.Add(Type("DataCompositionFilterItem"));
	НовыйОтбор.Use = True;
	НовыйОтбор.LeftValue = FilterField;
	НовыйОтбор.RightValue = False;
	НовыйОтбор.ComparisonType = DataCompositionComparisonType.Equal;
	
	If Parameters.Property("Subsystem") Then
		ТипПодсистемы = Parameters.Subsystem;
	Else
		ТипПодсистемы = 0;
		Items.ГруппаСущностиПоГрафику.Visible = False;
		Items.ОтборПографику.Visible = False;
	EndIf;
	
	If ТипПодсистемы = 2 Then
		СущностиПоГрафику.QueryText =
		"SELECT DISTINCT
		|	StaffSliceLast.WorkSchedule AS WorkSchedule,
		|	StaffSliceLast.Employee AS EnterpriseResource
		|FROM
		|	InformationRegister.Employees.SliceLast(
		|			,
		|			NOT Employee.NotValid
		|				AND NOT WorkSchedule = VALUE(Catalog.WorkSchedules.EmptyRef)) AS StaffSliceLast
		|
		|ORDER BY
		|	StaffSliceLast.Employee.Description";
		
		Items.СписокСотрудникиПоГрафикуРесурсПредприятия.Title = NStr("en='Employees on graphics';vi='Nhân viên trên lịch';");
		Items.ОтборПографику.Visible = False;
		
	EndIf;
	
	SetConditionalAppearance();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "List.NotValid", True, DataCompositionComparisonType.Equal);
	WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, "Description");
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.TabularSectionUnavailableTextColor);

EndProcedure

&AtClient
Procedure СписокСотрудникиПоГрафикуВыбор(Item, SelectedRow, Field, StandardProcessing)
	
	CurrentData = Items.СущностиПоГрафику.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	If TypeOf(CurrentData.EnterpriseResource) = Type("CatalogRef.KeyResources") Then
		FormParameters = New Structure("Key", CurrentData.EnterpriseResource);
		OpenForm("Catalog.KeyResources.ObjectForm",FormParameters);
	ElsIf TypeOf(CurrentData.EnterpriseResource) = Type("CatalogRef.Employees") Then
		FormParameters = New Structure("Key", CurrentData.EnterpriseResource);
		OpenForm("Catalog.Employees.ObjectForm",FormParameters);
	Else
		FormParameters = New Structure("Key", CurrentData.EnterpriseResource);
		OpenForm("Catalog.Teams.ObjectForm",FormParameters);
	EndIf;

EndProcedure

&AtClient
Procedure ShowInvalid(Command)
	
	FilterField = New DataCompositionField("NotValid");
	FoundItem = Undefined;
	
	For Each FilterItem In List.Filter.Items Do
		
		If TypeOf(FilterItem) = Type("DataCompositionFilterItemGroup")
			Then
			Continue;
		EndIf;
		
		If FilterItem.LeftValue = FilterField
			Then
			FoundItem = FilterItem;
			Break
		EndIf;
	EndDo;
	
	If FoundItem = Undefined
		Then
		Return;
	EndIf;
	
	НовыйОтбор = FoundItem;
	НовыйОтбор.Use = Not НовыйОтбор.Use;
	
EndProcedure

&AtClient
Procedure ОтборПографикуOnChange(Item)
	
	УстановитьОтборПоГрафику();
	
EndProcedure

&AtServer
Procedure УстановитьОтборПоГрафику()
	
	If ОтборПографику = "Employees" Then
		Items.СущностиПоГрафикуРесурсПредприятия.Title = NStr("en='Employees on graphics';vi='Nhân viên trên lịch'");
		SmallBusinessClientServer.SetListFilterItem(СущностиПоГрафику, "ТипРесурса", 1, True, DataCompositionComparisonType.Equal);
	ElsIf ОтборПографику = "Teams" Then
		Items.СущностиПоГрафикуРесурсПредприятия.Title = NStr("en='Teams on graphics';vi='Đội lao động trên lịch'");
		SmallBusinessClientServer.SetListFilterItem(СущностиПоГрафику, "ТипРесурса", 2, True, DataCompositionComparisonType.Equal);
	ElsIf ОтборПографику = "Resources" Then
		Items.СущностиПоГрафикуРесурсПредприятия.Title = NStr("en='Resources on graphics';vi='Tài nguyên trên lịch'");
		SmallBusinessClientServer.SetListFilterItem(СущностиПоГрафику, "ТипРесурса", 3, True, DataCompositionComparisonType.Equal);
	Else
		SmallBusinessClientServer.SetListFilterItem(СущностиПоГрафику, "ТипРесурса", 0, False, DataCompositionComparisonType.Equal);
		Items.СущностиПоГрафикуРесурсПредприятия.Title = NStr("en='All items on graphics';vi='Tất cả các mục trên lịch'");
	EndIf;
		
EndProcedure

