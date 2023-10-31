
&AtClient
Procedure ListOnActivateRow(Item)
	
	CurrentData = Items.List.CurrentData;
	
	If CurrentData = Undefined Then Return EndIf;
	
	CurrentList = ?(FilterByGraph = "Employees", EmployeesByGraph, EntitiesByGraph);
	
	CommonUseClientServer.SetFilterDynamicListItem(CurrentList, 
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
		SubsystemType = Parameters.Subsystem;
		
		ЕстьВыводПоПодсистемам = False;
		
		If GetFunctionalOption("UseSubsystemPayroll") Then
			Items.ОтборПографику.ChoiceList.Add("Employees", NStr("en='Employees';vi='Nhân viên'"));
			
			If SubsystemType = 2 Then
				
				Items.ОтборПографику.ChoiceList.Add("Employees", NStr("en='Employees';vi='Nhân viên'"));
				
				Items.СущностиПоГрафикуEnterpriseResource.Title = NStr("en='Employees on graphics';vi='Nhân viên trên lịch'");
				Items.ОтборПографику.Visible = False;
				
				Items.СотрудникиПоГрафику.Visible = True;
				Items.СущностиПоГрафику.Visible = False;
				
				ThisForm.Title = NStr("en='Graphics works сотрудников';vi='Lịch làm việc nhân viên'");
				
				FilterByGraph = "Employees";
				
				ЕстьВыводПоПодсистемам = True;
				
			EndIf;
		EndIf;
		
		If SubsystemType = 1 Then
			
			ThisForm.Title = "Graphics works resource";
			
			If (GetFunctionalOption("PlanCompanyResourcesLoadingWorks")
				Or GetFunctionalOption("PlanCompanyResourcesLoading") 
				Or GetFunctionalOption("PlanCompanyResourcesLoadingEventLog")) Then
				
				Items.ОтборПографику.ChoiceList.Add("Resources", "Resources");
				
				Items.СущностиПоГрафикуEnterpriseResource.Title = NStr("en='Resources on graphics';vi='Tài nguyên trên lịch'");
				
				ThisForm.Title = NStr("en='Graphics works resource';vi='Lịch làm việc tài nguyên'");
				
				FilterByGraph = "Resources";
				
				Items.СотрудникиПоГрафику.Visible = False;
				Items.СущностиПоГрафику.Visible = True;
				
				ЕстьВыводПоПодсистемам = True;
				
			EndIf;
			
		EndIf;
		
		If Not ЕстьВыводПоПодсистемам Then
			SubsystemType = 0;
			Items.ГруппаСущностиПоГрафику.Visible = False;
			Items.ОтборПографику.Visible = False;
		EndIf;
		
	Else
		SubsystemType = 0;
		Items.ГруппаСущностиПоГрафику.Visible = False;
		Items.ОтборПографику.Visible = False;
	EndIf;
	
	SetConditionalAppearance();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

		NewConditionalAppearance = ConditionalAppearance.Items.Add();
		WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "List.NotValid", True, DataCompositionComparisonType.Equal);
		WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "Description");
		WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.TabularSectionUnavailableTextColor);

EndProcedure

&AtClient
Procedure СущностиПоГрафикуSelection(Item, SelectedRow, Field, StandardProcessing)
	
	CurrentData = Items.СущностиПоГрафику.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	If TypeOf(CurrentData.EnterpriseResource) = Type("CatalogRef.KeyResources") Then
		FormParameters = New Structure("Key", CurrentData.EnterpriseResource);
		OpenForm("Catalog.KeyResources.ObjectForm",FormParameters);
	Else
		FormParameters = New Structure("Key", CurrentData.EnterpriseResource);
		OpenForm("Catalog.Teams.ObjectForm",FormParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure СотрудникиПоГрафикуSelection(Item, SelectedRow, Field, StandardProcessing)

	CurrentData = Items.СотрудникиПоГрафику.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	FormParameters = New Structure("Key", CurrentData.EnterpriseResource);
	OpenForm("Catalog.Employees.ObjectForm",FormParameters);

EndProcedure

&AtClient
Procedure ОтборПографикуOnChange(Item)
	
	УстановитьОтборПоГрафику();
	
EndProcedure

&AtServer
Procedure УстановитьОтборПоГрафику()
	
	If FilterByGraph = "Employees" Then
		
		Items.СотрудникиПоГрафику.Visible = True;
		Items.СущностиПоГрафику.Visible = False;
		
		ThisForm.Title = NStr("en='Graphics works сотрудников';vi='Lịch làm việc nhân viên'");
		
	ElsIf FilterByGraph = "Resources" Then
		
		Items.СотрудникиПоГрафику.Visible = False;
		Items.СущностиПоГрафику.Visible = True;
		
		ThisForm.Title = NStr("en='Graphics works resource';vi='Lịch làm việc tài nguyên'");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowInvalid(Command)
	
	Items.СписокПоказыватьНедействительную.Check = Not Items.СписокПоказыватьНедействительную.Check;
	SetFilterInvalid(ThisObject)

EndProcedure

&AtClientAtServerNoContext
Procedure SetFilterInvalid(Form)
	
	CommonUseClientServer.SetFilterDynamicListItem(
		Form.List,
		"NotValid",
		False,
		,
		,
		Not Form.Items.СписокПоказыватьНедействительную.Check);
	
EndProcedure



