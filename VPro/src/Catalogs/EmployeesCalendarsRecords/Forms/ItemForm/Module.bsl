
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not ValueIsFilled(Parameters.Key) Then
		CreateItemsExtendedInput();
		WindowOptionsKey = "ExtendedInput";
	EndIf;
	
	EventsCMClientServer.ЗаполнитьСписокВыбораВремени(Items.BeginTime);
	EventsCMClientServer.ЗаполнитьСписокВыбораВремени(Items.EndTime);
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If ValueIsFilled(MarkOnDeleteOnWrite) Then
		MarkOnDeleteOnWrite.GetObject().SetDeletionMark(True);
		MarkOnDeleteOnWrite = Catalogs.EmployeesCalendarsRecords.EmptyRef();
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// УНФ.КалендарьСотрудника
	Notify("Record_SourceRecordsEmployeeCalendar");
	// Конец УНФ.КалендарьСотрудника
	
EndProcedure

#EndRegion

#Region FormItemEventsHandlers

&AtClient
Procedure CalendarChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	If Not ValueIsFilled(Object.ID)
		And Not ValueIsFilled(MarkOnDeleteOnWrite) Then
		Return;
	EndIf;
	
	If Object.Calendar = SelectedValue Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	ReplaceObjectAtServer(SelectedValue);
	
EndProcedure

&AtClient
Procedure BeginChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	SelectedValue = BegOfDay(Object.Begin) + (SelectedValue - BegOfDay(SelectedValue));
	
EndProcedure

&AtClient
Procedure ChoiceProcessingEnd(Item, SelectedValue, StandardProcessing)
	
	SelectedValue = BegOfDay(Object.End) + (SelectedValue - BegOfDay(SelectedValue));
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Procedure CreateItemsExtendedInput()
	
	ValueToFormAttribute(Catalogs.EmployeesCalendarsRecords.ExtandedRecordsInputDescription(), "ExtandedInputDescription");
	
	For IndexOf = 0 To ExtandedInputDescription.Count()-1 Do
		
		DescriptionString = ExtandedInputDescription[IndexOf];
		
		ParentGroup = ?(IndexOf <= ExtandedInputDescription.Count() / 2, Items.Column_1, Items.Column_2);
		
		ItemName = "TypeInput_" + IndexOf;
		LabelDecoration = Items.Add(ItemName, Type("FormDecoration"), ParentGroup);
		LabelDecoration.Type = FormDecorationType.Label;
		LabelDecoration.Title = DescriptionString.Presentation;
		LabelDecoration.Hyperlink = True;
		LabelDecoration.SetAction("Click", "Attachable_TypeInputClick");
		
	EndDo;
	
EndProcedure

&AtClient
Procedure Attachable_TypeInputClick(Item)
	
	DataCalendarRecords = New Structure;
	DataCalendarRecords.Insert("Description",	Object.Description);
	DataCalendarRecords.Insert("Calendar",		Object.Calendar);
	DataCalendarRecords.Insert("Begin",		Object.Begin);
	DataCalendarRecords.Insert("End",		Object.End);
	DataCalendarRecords.Insert("DescriptionFull",		Object.DescriptionFull);
	
	IndexOf = Number(Mid(Item.Name, StrLen("TypeInput_")+1));
	DescriptionString = ExtandedInputDescription[IndexOf];
	
	If Not DescriptionString.FormParameters.Property("FillingValues") Then
		DescriptionString.FormParameters.Insert("FillingValues", New Structure);
	EndIf;
	
	DescriptionString.FormParameters.FillingValues.Insert("DataCalendarRecords", DataCalendarRecords);
	
	OpenForm(DescriptionString.FormName, DescriptionString.FormParameters);
	
	Modified = False;
	Close();
	
EndProcedure

// Процедура обеспечивает подмену объекта при изменении календаря.
// Такое поведение нужно для корректной выгрузки в Google записей,
// которые были перемещены между календарями.
&AtServer
Procedure ReplaceObjectAtServer(NewCalendar)
	
	SavingAttributes = New Structure("Description,Begin,End,Source,SourceRowNumber,Definition");
	FillPropertyValues(SavingAttributes, Object);
	
	Modified = True;
	
	If ValueIsFilled(MarkOnDeleteOnWrite)
		And CommonUse.ObjectAttributeValue(MarkOnDeleteOnWrite, "Calendar") = NewCalendar Then
		
		// Вернули календарь к первоначальному значению
		PreviousCalendarRecords = MarkOnDeleteOnWrite.GetObject();
		ValueToFormAttribute(PreviousCalendarRecords, "Object");
		FillPropertyValues(Object, SavingAttributes);
		MarkOnDeleteOnWrite = Catalogs.EmployeesCalendarsRecords.EmptyRef();
		Return;
		
	EndIf;
	
	NewCalendarRecord = Catalogs.EmployeesCalendarsRecords.CreateItem();
	MarkOnDeleteOnWrite = Object.Ref;
	ValueToFormAttribute(NewCalendarRecord, "Object");
	FillPropertyValues(Object, SavingAttributes);
	Object.Calendar = NewCalendar;
	
EndProcedure

#EndRegion
