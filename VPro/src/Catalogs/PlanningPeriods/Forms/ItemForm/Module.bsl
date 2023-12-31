
////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - FORM EVENT HANDLERS

&AtServer
// Procedure - event handler OnCreateAtServer of the form.
//
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Structure = New Structure;
	Structure.Insert("Day", Enums.Periodicity.Day);
	Structure.Insert("Week", Enums.Periodicity.Week);
	Structure.Insert("Month", Enums.Periodicity.Month);
	Structure.Insert("Quarter", Enums.Periodicity.Quarter);
	Structure.Insert("HalfYear", Enums.Periodicity.HalfYear);
	Structure.Insert("Year", Enums.Periodicity.Year);
	
	StructurePeriodicity = Structure;		
	
	If Object.Predefined Then
		
		Items.Periodicity.Enabled = False;
		Items.StartDate.Enabled = False;
		Items.StartDate.AutoMarkIncomplete = False;
		Items.EndDate.Enabled = False;
		Items.EndDate.AutoMarkIncomplete = False;
		
	EndIf;
	
	// StandardSubsystems.AdditionalReportsAndDataProcessors
	AdditionalReportsAndDataProcessors.OnCreateAtServer(ThisForm);
	// End StandardSubsystems.AdditionalReportsAndDataProcessors
	
	// StandardSubsystems.Printing
	PrintManagement.OnCreateAtServer(ThisForm);
	// End StandardSubsystems.Printing
	
EndProcedure // OnCreateAtServer()

////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - EVENT HANDLERS OF FORM ATTRIBUTES

&AtClient
// Procedure - event handler OnChange of field StartDate.
//
Procedure BeginDateOnChange(Item)
			
	If ValueIsFilled(Object.Periodicity)
		AND ValueIsFilled(Object.StartDate) Then
		
		If Object.Periodicity = StructurePeriodicity.Week Then	
			
			Object.StartDate = BegOfWeek(Object.StartDate);
						
		ElsIf Object.Periodicity = StructurePeriodicity.Month Then	
			
			Object.StartDate = BegOfMonth(Object.StartDate);
						
		ElsIf Object.Periodicity = StructurePeriodicity.Quarter Then	
			
			Object.StartDate = BegOfQuarter(Object.StartDate);
						
		ElsIf Object.Periodicity = StructurePeriodicity.HalfYear Then	
			
			MonthOfStartDate = Month(Object.StartDate);
			
			Object.StartDate = BegOfYear(Object.StartDate);

			If MonthOfStartDate > 6 Then
				
				Object.StartDate = AddMonth(Object.StartDate, 6);
				
			EndIf;	
						 
		ElsIf Object.Periodicity = StructurePeriodicity.Year Then
			
			Object.StartDate = BegOfYear(Object.StartDate);
						
		EndIf;	
			
	EndIf;	
	
	If Object.StartDate > Object.EndDate 
		AND ValueIsFilled(Object.EndDate) Then
				
		Message = New UserMessage;
		Message.Text = NStr("en='The Start date field value is greater than the End date field value.';ru='Значение поля ""Дата начала"" больше значения поля ""Дата окончания""';vi='Giá trị trường ""Ngày bắt đầu"" lớn hơn giá trị trường ""Ngày kết thúc""'");
		Message.Field = "Object.StartDate";
		Message.Message();
				
	EndIf;	
	
EndProcedure // BeginDateOnChange()

&AtClient
// Procedure - event handler OnChange of field EndDate.
//
Procedure EndingDateOnChange(Item)
			
	If ValueIsFilled(Object.Periodicity)
		AND ValueIsFilled(Object.EndDate) Then
		
		If Object.Periodicity = StructurePeriodicity.Week Then	
			
			Object.EndDate = EndOfWeek(Object.EndDate);
			
		ElsIf Object.Periodicity = StructurePeriodicity.Month Then	
			
			Object.EndDate = EndOfMonth(Object.EndDate);
			
		ElsIf Object.Periodicity = StructurePeriodicity.Quarter Then	
			
			Object.EndDate = EndOfQuarter(Object.EndDate);
			
		ElsIf Object.Periodicity = StructurePeriodicity.HalfYear Then	
			
			MonthEndDates = Month(Object.EndDate);
			
			Object.EndDate = EndOfYear(Object.EndDate);

			If MonthEndDates < 7 Then
				
				Object.EndDate = AddMonth(Object.EndDate, - 6);
				
			EndIf;	
			 
		ElsIf Object.Periodicity = StructurePeriodicity.Year Then
			
			Object.EndDate = EndOfYear(Object.EndDate);
			
		EndIf;	
			
	EndIf;
	
	If Object.StartDate > Object.EndDate 
		AND ValueIsFilled(Object.StartDate) Then
				
		Message = New UserMessage;
		Message.Text = NStr("en='The End date field value is less than the Start date field value.';ru='Значение поля ""Дата окончания"" меньше значения поля ""Дата начала""';vi='Giá trị trường ""Ngày kết thúc"" nhỏ hơn giá trị trường ""Ngày bắt đầu""'");
		Message.Field = "Object.EndDate";
		Message.Message();
						
	EndIf;
	
EndProcedure // EndingDateOnChange()

&AtClient
// Procedure - event handler OnChange of field Periodicity.
//
Procedure PeriodicityOnChange(Item)
			
	If ValueIsFilled(Object.StartDate)
		AND ValueIsFilled(Object.EndDate) Then
		
		If Object.Periodicity = StructurePeriodicity.Week Then	
			
			Object.StartDate = BegOfWeek(Object.StartDate);
			Object.EndDate = EndOfWeek(Object.EndDate);
			
		ElsIf Object.Periodicity = StructurePeriodicity.Month Then	
			
			Object.StartDate = BegOfMonth(Object.StartDate);
			Object.EndDate = EndOfMonth(Object.EndDate);
			
		ElsIf Object.Periodicity = StructurePeriodicity.Quarter Then	
			
			Object.StartDate = BegOfQuarter(Object.StartDate);
			Object.EndDate = EndOfQuarter(Object.EndDate);
			
		ElsIf Object.Periodicity = StructurePeriodicity.HalfYear Then	
			
			MonthOfStartDate = Month(Object.StartDate);
			
			Object.StartDate = BegOfYear(Object.StartDate);

			If MonthOfStartDate > 6 Then
				
				Object.StartDate = AddMonth(Object.StartDate, 6);
				
			EndIf;	
				
			MonthEndDates = Month(Object.EndDate);
			
			Object.EndDate = EndOfYear(Object.EndDate);

			If MonthEndDates < 7 Then
				
				Object.EndDate = AddMonth(Object.EndDate, - 6);
				
			EndIf;	
			 
		ElsIf Object.Periodicity = StructurePeriodicity.Year Then
			
			Object.StartDate = BegOfYear(Object.StartDate);
			Object.EndDate = EndOfYear(Object.EndDate);
			
		EndIf;	
			
	EndIf;	
	
EndProcedure // PeriodicityOnChange()

#Region LibrariesHandlers

// StandardSubsystems.AdditionalReportsAndDataProcessors
&AtClient
Procedure Attachable_ExecuteAssignedCommand(Command)
	If Not AdditionalReportsAndDataProcessorsClient.ExecuteAllocatedCommandAtClient(ThisForm, Command.Name) Then
		ExecutionResult = Undefined;
		AdditionalReportsAndProcessingsExecuteAllocatedCommandAtServer(Command.Name, ExecutionResult);
		AdditionalReportsAndDataProcessorsClient.ShowCommandExecutionResult(ThisForm, ExecutionResult);
	EndIf;
EndProcedure

&AtServer
Procedure AdditionalReportsAndProcessingsExecuteAllocatedCommandAtServer(ItemName, ExecutionResult)
	AdditionalReportsAndDataProcessors.ExecuteAllocatedCommandAtServer(ThisForm, ItemName, ExecutionResult);
EndProcedure
// End StandardSubsystems.AdditionalReportsAndDataProcessors

// StandardSubsystems.Printing
&AtClient
Procedure Attachable_ExecutePrintCommand(Command)
	PrintManagementClient.ExecuteConnectedPrintCommand(Command, ThisObject, Object);
EndProcedure
// End StandardSubsystems.Printing

#EndRegion
