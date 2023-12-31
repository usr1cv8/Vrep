
#Region FormHandlers

&AtServer
// Procedure - OnCreateAtServer event handler.
//
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Set the format for the current date: DF=H:mm
	SmallBusinessServer.SetDesignDateColumn(List);
	
	// StandardSubsystems.AdditionalReportsAndDataProcessors
	AdditionalReportsAndDataProcessors.OnCreateAtServer(ThisForm);
	// End StandardSubsystems.AdditionalReportsAndDataProcessors
	
	// StandardSubsystems.Printing
	PrintManagement.OnCreateAtServer(ThisForm, Items.ImportantCommandsGroup);
	// End StandardSubsystems.Printing
	
EndProcedure // OnCreateAtServer()

// Procedure - form event handler "OnLoadDataFromSettingsAtServer".
//
&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	FilterEmployee			= Settings.Get("FilterEmployee");
	FilterCompany 		= Settings.Get("FilterCompany");
	FilterDepartment 		= Settings.Get("FilterDepartment");
	
	SmallBusinessClientServer.SetListFilterItem(List, "Employees.Employee", FilterEmployee, ValueIsFilled(FilterEmployee));
	SmallBusinessClientServer.SetListFilterItem(List, "Company", FilterCompany, ValueIsFilled(FilterCompany));
	SmallBusinessClientServer.SetListFilterItem(List, "Employees.StructuralUnit", FilterDepartment, ValueIsFilled(FilterDepartment));
	
EndProcedure // OnLoadDataFromSettingsAtServer()

#EndRegion

#Region AttributeHandlers

// Procedure - event handler OnChange input field FilterEmployee
//
&AtClient
Procedure FilterEmployeeOnChange(Item)
	
	SmallBusinessClientServer.SetListFilterItem(List, "Employees.Employee", FilterEmployee, ValueIsFilled(FilterEmployee));
	
EndProcedure // FilterEmployeeOnChange()

// Procedure - event handler OnChange input field FilterCompany 
// IN procedure the situation is defined, when on change its
// date document is in another document numbering period, and in
// this case appropriates for document new unique number.
// Overrides the corresponding form parameter.
//
&AtClient
Procedure FilterCompanyOnChange(Item)
	
	SmallBusinessClientServer.SetListFilterItem(List, "Company", FilterCompany, ValueIsFilled(FilterCompany));
	
EndProcedure // FilterCompanyOnChange()

// Procedure - event handler OnChange input field FilterDepartment
// IN procedure the situation is defined, when on change its
// date document is in another document numbering period, and in
// this case appropriates for document new unique number.
// Overrides the corresponding form parameter.
//
&AtClient
Procedure FilterDepartmentOnChange(Item)
	
	SmallBusinessClientServer.SetListFilterItem(List, "Employees.StructuralUnit", FilterDepartment, ValueIsFilled(FilterDepartment));
	
EndProcedure // FilterDepartmentOnChange()

#EndRegion

#Region LibrariesHandlers

// StandardSubsystems.Printing
&AtClient
Procedure Attachable_ExecutePrintCommand(Command)
	PrintManagementClient.ExecuteConnectedPrintCommand(Command, ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.Printing

#EndRegion
