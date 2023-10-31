
#Region Variables

&AtClient
Var CurrentColorItem;

#EndRegion

#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then // Возврат при получении формы для анализа.
		Return;
	EndIf;
	
	Items.FormAllCalendars.Visible			= Users.InfobaseUserWithFullAccess();
	Items.FormListCalendarRecords.Visible	= Items.FormAllCalendars.Visible;
	
	RestoreSettings();
	ReadAvailableCalendars();
	UpdatePlaningDataServer();
	
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	
	If ChoiceSource.FormName = "Catalog.EmployeesCalendarsRecords.Form.CalendarsSettings" Then
		
		If SelectedValue <> Undefined Then
			FillPropertyValues(DisplaySettings, SelectedValue);
			SaveSettingsAndUpdateDataPlannerServer();
		EndIf;
		
	ElsIf ChoiceSource.FormName = "CommonForm.ВыборЦвета" Then
		
		If CurrentColorItem <> Undefined Then
			
			CurrentColorItem.Picture = WorkWithColorClientServer.КартинкаЦветаПоНомеруКартинки(SelectedValue);
			IndexOf = Number(Mid(CurrentColorItem.Name, StrLen("CalendarColor_")+1));
			CurCalendar = AvailableCalendars[IndexOf];
			CurCalendar.ColorVariant = SelectedValue;
			
			If CurCalendar.Selected Then
				SaveSettingsAndUpdateDataPlannerServer();
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Record_SourceRecordsEmployeeCalendar"
		Or EventName = "Record_RecordsCalendarsPreparingReports" Then
		
		UpdatePlaningDataServer();
		
	ElsIf EventName = "Record_EmployeeCalendar" Then
		
		ProcessCalendarRecordServer();
		
	ElsIf EventName = "CleanSessionData" Then
		
		SessionData = New Structure;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormItemEventsHandlers

&AtClient
Procedure PeriodVariantOnChange(Item)
	
	SelectRepresentationDays(ThisObject);
	SetPeriodPresentation(ThisObject);
	Items.RepresentationDate.Refresh();
	
	SaveSettingsAndUpdateDataPlannerServer();
	
EndProcedure

&AtClient
Procedure RepresentationDateOnChange(Item)
	
	AttachIdleHandler("UpdatePlannerDataClient", 0.2, True);
	
EndProcedure

&AtClient
Procedure RepresentationDateOnActivateDate(Item)
	
	SelectRepresentationDays(ThisObject);
	SetPeriodPresentation(ThisObject);
	Items.RepresentationDate.Refresh();
	
EndProcedure

&AtClient
Procedure SchedulerBeforeCreate(Item, Begin, End, Values, Text, StandardProcessing)
	
	StandardProcessing = False;
	
	SelectedCalendars = AvailableCalendars.FindRows(New Structure("Selected", True));
	
	FillingValues = New Structure;
	FillingValues.Insert("Begin", Begin);
	FillingValues.Insert("End", End);
	If SelectedCalendars.Count() = 1 Then
		FillingValues.Insert("Calendar", SelectedCalendars[0].Calendar);
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("FillingValues", FillingValues);
	OpenForm("Catalog.EmployeesCalendarsRecords.Form.ItemForm", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure SchedulerOnEditEnd(Item, NewItem, CancelEdit)
	
	ProcessedItems = New Array;
	
	For Each SelectedItem In Item.SelectedItems Do
		
		If SelectedItem.Value.EditProhibited Then
			CancelEdit = True;
			Return;
		EndIf;
		
		ProcessedItem = New Structure;
		ProcessedItem.Insert("CalendarRecord",		SelectedItem.Value.CalendarRecord);
		ProcessedItem.Insert("Source",				SelectedItem.Value.Src);
		ProcessedItem.Insert("SourceRowNumber",	SelectedItem.Value.SourceRowNumber);
		ProcessedItem.Insert("Begin",				SelectedItem.Begin);
		ProcessedItem.Insert("End",					SelectedItem.End);
		
		ProcessedItems.Add(ProcessedItem);
		
	EndDo;
	
	CancelEdit = Not SaveChangeInBase(ProcessedItems);
	
EndProcedure

&AtClient
Procedure SchedulerBeforeStartEdit(Item, NewItem, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenFormCurrentPlannerItem();
	
EndProcedure

&AtClient
Procedure SchedulerBeforeDelete(Item, Cancel)
	
	ProcessedItems = New Array;
	
	For Each SelectedItem In Item.SelectedItems Do
		
		If SelectedItem.Value.EditProhibited Then
			Cancel = True;
			Return;
		EndIf;
		
		ProcessedItem = New Structure;
		ProcessedItem.Insert("CalendarRecord",		SelectedItem.Value.CalendarRecord);
		ProcessedItem.Insert("Source",				SelectedItem.Value.Src);
		ProcessedItem.Insert("SourceRowNumber",	SelectedItem.Value.SourceRowNumber);
		ProcessedItem.Insert("DeletionMark",		True);
		
		ProcessedItems.Add(ProcessedItem);
		
	EndDo;
	
	Cancel = Not SaveChangeInBase(ProcessedItems);
	
EndProcedure

&AtClient
Procedure SchedulerOnCurrentRepresentationPeriodChange(Item, CurrentRepresentationPeriods, StandardProcessing)
	
	If PeriodVariant = "Month" Then
		
		StandardProcessing = False;
		CurrentSessionDate = CommonUseClient.SessionDate();
		
		If CurrentRepresentationPeriods[0].Begin = BegOfDay(CurrentSessionDate) Then
			RepresentationDate = CurrentSessionDate;
		ElsIf CurrentRepresentationPeriods[0].Begin < Scheduler.CurrentRepresentationPeriods[0].Begin Then
			RepresentationDate = AddMonth(RepresentationDate, -1);
		ElsIf CurrentRepresentationPeriods[0].Begin > Scheduler.CurrentRepresentationPeriods[0].Begin Then
			RepresentationDate = AddMonth(RepresentationDate, 1);
		EndIf;
		
		PeriodOfData = GetDataPeriod(PeriodVariant, RepresentationDate);
		Scheduler.CurrentRepresentationPeriods.Clear();
		Scheduler.CurrentRepresentationPeriods.Add(PeriodOfData.StartDate, PeriodOfData.EndDate);
		
		Scheduler.BackgroundIntervals.Clear();
		Interval = Scheduler.BackgroundIntervals.Add(BegOfMonth(RepresentationDate), EndOfMonth(RepresentationDate));
		Interval.Color = New Color(250, 250, 250);
		If DisplaySettings.ShowCurrentDate Then
			Interval = Scheduler.BackgroundIntervals.Add(BegOfDay(CurrentSessionDate), EndOfDay(CurrentSessionDate));
			Interval.Color = New Color(223, 255, 223);
		EndIf;
		
	Else
		
		RepresentationDate = CurrentRepresentationPeriods[0].Begin;
		
	EndIf;
	
	SelectRepresentationDays(ThisObject);
	SetPeriodPresentation(ThisObject);
	Items.RepresentationDate.Refresh();
	AttachIdleHandler("UpdatePlannerDataClient", 0.2, True);
	
EndProcedure

&AtClient
Procedure SchedulerBeforeStartQuickEdit(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenFormCurrentPlannerItem();
	
EndProcedure

&AtClient
Procedure Attachable_ChoicedCalendarOnChange(Item)
	
	SaveSettingsAndUpdateDataPlannerServer();
	
EndProcedure

&AtClient
Procedure Attachable_ColorCalendarClick(Item)
	
	CurrentColorItem = Item;
	OpenForm("CommonForm.ВыборЦвета", , ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure Refresh(Command)
	
	UpdatePlaningDataServer();
	
EndProcedure

&AtClient
Procedure Configure(Command)
	
	OpenForm("Catalog.EmployeesCalendarsRecords.Form.CalendarsSettings", New Structure("DisplaySettings", DisplaySettings), ThisObject);
	
EndProcedure

&AtClient
Procedure AddCalendar(Command)
	
	OpenForm("Catalog.EmployeesCalendars.ObjectForm", , ThisObject);
	
EndProcedure

&AtClient
Procedure Synchronize(Command)
	
//	SynchronizeAtClient();
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtClient
Procedure OpenFormCurrentPlannerItem()
	
	ItemValue = Items.Scheduler.SelectedItems[0].Value;
	
	If ValueIsFilled(ItemValue.Source) Then
		
		ShowValue(,ItemValue.Source);
		
	ElsIf Not ValueIsFilled(ItemValue.Source) Then
		
		FormParameters = New Structure;
		FormParameters.Insert("Key", ItemValue.CalendarRecord);
		OpenForm("Catalog.EmployeesCalendarsRecords.Form.ItemForm", FormParameters, ThisObject);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function GetFormDataTasks(RecordCalendarPreparingReports)
	
	Result = New Structure("FormName, FormParameters", "", New Structure);
	
	AttributeValues = CommonUse.ObjectAttributesValues(RecordCalendarPreparingReports, "State,Company,CalendarEvents");
	
	If Not ValueIsFilled(AttributeValues.CalendarEvents) Then
		Return Result;
	EndIf;
	
	Result.FormParameters.Insert("State", AttributeValues.State);
	Result.FormParameters.Insert("Company", AttributeValues.Company);
	Result.FormParameters.Insert("CalendarEvents", AttributeValues.CalendarEvents);
	
	Task = CommonUse.ObjectAttributeValue(AttributeValues.CalendarEvents, "Task");
	If Not ValueIsFilled(Task) Then
		Return Result;
	EndIf;
	
	Result.FormName = Catalogs.ЗаписиКалендаряПодготовкиОтчетности.ПолучитьИмяФормыПоЗадачеИСостоянию(Task, AttributeValues.State);
	
	Return Result;
	
EndFunction

&AtServer
Procedure RestoreSettings()
	
	PeriodVariant = CommonUse.CommonSettingsStorageImport("EmployeeCalendarSettings",
		"PeriodVariant",
		Items.PeriodVariant.ChoiceList[0].Value
	);
	
	DisplaySettings = CommonUse.CommonSettingsStorageImport("EmployeeCalendarSettings",
		"Representation",
		Undefined
	);
	
	If DisplaySettings = Undefined Then
		
		DisplaySettings = New Structure;
		DisplaySettings.Insert("WorkingDayBeginning",		0);
		DisplaySettings.Insert("WorkingDayEnd",	23);
		DisplaySettings.Insert("ShowCurrentDate",	True);
		
	EndIf;
	
	Scheduler.TimeScale.Items[0].DayFormat = TimeScaleDayFormat.MonthDayWeekDay;
	
	RepresentationDate = CurrentSessionDate();
	SelectRepresentationDays(ThisObject);
	SetPeriodPresentation(ThisObject);
	
EndProcedure

&AtServer
Procedure SaveSettingsAndUpdateDataPlannerServer()
	
	SaveSettings();
	UpdatePlaningDataServer();
	
EndProcedure

&AtServer
Procedure SaveSettings()
	
	CommonUse.CommonSettingsStorageSave("EmployeeCalendarSettings",
		"PeriodVariant",
		PeriodVariant
	);
	
	CommonUse.CommonSettingsStorageSave("EmployeeCalendarSettings",
		"Representation",
		DisplaySettings
	);
	
	SaveSettingsAvailableCalendars();
	
EndProcedure

&AtServer
Procedure SaveSettingsAvailableCalendars()
	
	SettingsAvailableCalendars = FormAttributeToValue("AvailableCalendars");
	SettingsAvailableCalendars.Columns.Delete("Description");
	CommonUse.CommonSettingsStorageSave("EmployeeCalendarSettings",
		"AvailableCalendars",
		SettingsAvailableCalendars
	);
	
EndProcedure

&AtServer
Procedure UpdatePlaningDataServer()
	
	Scheduler.Items.Clear();
	Scheduler.BackgroundIntervals.Clear();
	
	SetupPlannerRepresentation();
	
	PeriodOfData = GetDataPeriod(PeriodVariant, RepresentationDate);
	
	Scheduler.CurrentRepresentationPeriods.Clear();
	Scheduler.CurrentRepresentationPeriods.Add(PeriodOfData.StartDate, PeriodOfData.EndDate);
	
	SelectedCalendars = New Array;
	For Each CalendarRow In AvailableCalendars Do
		If CalendarRow.Selected Then
			SelectedCalendars.Add(CalendarRow.Calendar);
		EndIf;
	EndDo;
	
	TextByProductionOrder = "";
	If AccessRight("Read", Metadata.Documents.ProductionOrder, Users.AuthorizedUser()) Then
		TextByProductionOrder = 
		"SELECT
		|	ProductionOrder.Ref
		|FROM
		|	Document.ProductionOrder AS ProductionOrder
		|WHERE
		|	ProductionOrder.Ref IN
		|			(SELECT
		|				ttSources.Source
		|			FROM
		|				ttSources)
		|
		|UNION ALL";
	EndIf;
	
	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED DISTINCT
		|	CalendarsRecords.Source AS Source
		|INTO ttSources
		|FROM
		|	Catalog.EmployeesCalendarsRecords AS CalendarsRecords
		|WHERE
		|	CalendarsRecords.DeletionMark = FALSE
		|	AND CalendarsRecords.Begin < &EndDate
		|	AND CalendarsRecords.End > &StartDate
		|	AND CalendarsRecords.Calendar IN(&SelectedCalendars)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	Event.Ref AS Ref
		|INTO ttAvailableSources
		|FROM
		|	Document.Event AS Event
		|WHERE
		|	Event.Ref IN
		|			(SELECT
		|				ttSources.Source
		|			FROM
		|				ttSources)
		|
		|UNION ALL
		|
		|SELECT
		|	JobOrder.Ref
		|FROM
		|	Document.WorkOrder AS JobOrder
		|WHERE
		|	JobOrder.Ref IN
		|			(SELECT
		|				ttSources.Source
		|			FROM
		|				ttSources)
		|
		|
		|UNION ALL
		|
		|SELECT
		|	UNDEFINED
		|
		|UNION ALL
		|
		|"+ TextByProductionOrder+"
		|
		|SELECT
		|	CustomerOrder.Ref
		|FROM
		|	Document.CustomerOrder AS CustomerOrder
		|WHERE
		|	CustomerOrder.Ref IN
		|			(SELECT
		|				ttSources.Source
		|			FROM
		|				ttSources)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	RecordsEmployeeCalendar.Ref AS CalendarRecord,
		|	RecordsEmployeeCalendar.Description AS Description,
		|	RecordsEmployeeCalendar.Begin AS Begin,
		|	RecordsEmployeeCalendar.End AS End,
		|	RecordsEmployeeCalendar.DescriptionFull AS DescriptionFull,
		|	RecordsEmployeeCalendar.Source AS Source,
		|	RecordsEmployeeCalendar.SourceRowNumber AS SourceRowNumber,
		|	RecordsEmployeeCalendar.Calendar AS Calendar,
		|	RecordsEmployeeCalendar.EditProhibited AS EditProhibited
		|FROM
		|	Catalog.EmployeesCalendarsRecords AS RecordsEmployeeCalendar
		|WHERE
		|	RecordsEmployeeCalendar.Source IN
		|			(SELECT
		|				ttAvailableSources.Ref
		|			FROM
		|				ttAvailableSources)
		|	AND RecordsEmployeeCalendar.DeletionMark = FALSE
		|	AND RecordsEmployeeCalendar.Begin < &EndDate
		|	AND RecordsEmployeeCalendar.End > &StartDate
		|	AND RecordsEmployeeCalendar.Calendar IN(&SelectedCalendars)
		|
		|ORDER BY
		|	Begin";
	
	Query.SetParameter("StartDate", PeriodOfData.StartDate);
	Query.SetParameter("EndDate", PeriodOfData.EndDate);
	Query.SetParameter("SelectedCalendars", SelectedCalendars);
	
	Selection = Query.Execute().Select();
	Filter = New Structure("Calendar");
	
	While Selection.Next() Do
		
		PlannerItem = Scheduler.Items.Add(Selection.Begin, Selection.End);
		PlannerItem.Value = New Structure;
		PlannerItem.Value.Insert("Calendar", Selection.Calendar);
		PlannerItem.Value.Insert("CalendarRecord", Selection.CalendarRecord);
		PlannerItem.Value.Insert("Source", Selection.Source);
		PlannerItem.Value.Insert("EditProhibited", Selection.EditProhibited);
		PlannerItem.Value.Insert("SourceRowNumber", Selection.SourceRowNumber);
		PlannerItem.Text		= Selection.Description;
		PlannerItem.ToolTip	= Selection.DescriptionFull;
		
		If ValueIsFilled(Selection.Source) Then
			SourceManager = CommonUse.ObjectManagerByRef(Selection.Source);
			PlannerItem.Picture = SourceManager.CalendarRecordPicture(Selection.Source);
			PlannerItem.TextColor = SourceManager.CalendarRecorTextColor(Selection.Source);
		EndIf;
		
		Filter.Calendar = Selection.Calendar;
		FoundStrings = AvailableCalendars.FindRows(Filter);
		If FoundStrings.Count() > 0 Then
			PlannerItem.BackColor = WorkWithColorClientServer.ColorByPictureNumber(FoundStrings[0].ColorVariant);
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SetupPlannerRepresentation()
	
	If PeriodVariant = "Day" Then
		
		Scheduler.ShowCurrentDate = DisplaySettings.ShowCurrentDate;
		Scheduler.PeriodicVariantUnit = TimeScaleUnitType.Hour;
		Scheduler.PeriodicVariantRepetition = 24;
		Scheduler.TimeScaleWrapBeginIndent = DisplaySettings.WorkingDayBeginning;
		Scheduler.TimeScaleWrapEndIndent = ?(DisplaySettings.WorkingDayEnd = 0, 0, 24 - DisplaySettings.WorkingDayEnd);
		Scheduler.ShowWrappedHeaders = True;
		Scheduler.ShowWrappedTimeScaleHeaders = False;
		Scheduler.ItemsTimeRepresentation = PlannerItemsTimeRepresentation.BeginAndEndTime;
		Scheduler.WrappedTimeScaleHeaderFormat = "DF='dddd, d MMMM yyyy'";
		Scheduler.TimeScale.Location = TimeScalePosition.Left;
		Scheduler.TimeScale.Items[0].Format = "DF=HH:mm";
		Scheduler.TimeScale.Items[0].Repetition = 1;
		Scheduler.TimeScale.Items[0].Unit = TimeScaleUnitType.Hour;
		
	ElsIf PeriodVariant = "Week" Then
		
		Scheduler.ShowCurrentDate = DisplaySettings.ShowCurrentDate;
		Scheduler.PeriodicVariantUnit = TimeScaleUnitType.Hour;
		Scheduler.PeriodicVariantRepetition = 24;
		Scheduler.TimeScaleWrapBeginIndent = DisplaySettings.WorkingDayBeginning;
		Scheduler.TimeScaleWrapEndIndent = ?(DisplaySettings.WorkingDayEnd = 0, 0, 24 - DisplaySettings.WorkingDayEnd);
		Scheduler.ShowWrappedHeaders = True;
		Scheduler.ShowWrappedTimeScaleHeaders = False;
		Scheduler.ItemsTimeRepresentation = PlannerItemsTimeRepresentation.DontDisplay;
		Scheduler.WrappedTimeScaleHeaderFormat = "DF='ddd, d MMMM'";
		Scheduler.TimeScale.Location = TimeScalePosition.Left;
		Scheduler.TimeScale.Items[0].Format = "DF=HH:mm";
		Scheduler.TimeScale.Items[0].Repetition = 1;
		Scheduler.TimeScale.Items[0].Unit = TimeScaleUnitType.Hour;
		
	ElsIf PeriodVariant = "Month" Then
		
		Scheduler.ShowCurrentDate = False;
		Scheduler.PeriodicVariantUnit = TimeScaleUnitType.Day;
		Scheduler.PeriodicVariantRepetition = 7;
		Scheduler.TimeScaleWrapBeginIndent = 0;
		Scheduler.TimeScaleWrapEndIndent = 0;
		Scheduler.ShowWrappedHeaders = False;
		Scheduler.ShowWrappedTimeScaleHeaders = True;
		Scheduler.ItemsTimeRepresentation = PlannerItemsTimeRepresentation.DontDisplay;
		Scheduler.WrappedTimeScaleHeaderFormat = "DF='ddd, d MMM yyyy'";
		Scheduler.TimeScale.Location = TimeScalePosition.Top;
		Scheduler.TimeScale.Items[0].Format = "DF='ddd, d MMM yyyy'";
		Scheduler.TimeScale.Items[0].Repetition = 1;
		Scheduler.TimeScale.Items[0].Unit = TimeScaleUnitType.Day;
		
		Interval = Scheduler.BackgroundIntervals.Add(BegOfMonth(RepresentationDate), EndOfMonth(RepresentationDate));
		Interval.Color = New Color(250, 250, 250);
		If DisplaySettings.ShowCurrentDate Then
			CurrentSessionDate = CurrentSessionDate();
			Interval = Scheduler.BackgroundIntervals.Add(BegOfDay(CurrentSessionDate), EndOfDay(CurrentSessionDate));
			Interval.Color = New Color(223, 255, 223);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function GetDataPeriod(PeriodVariant, RepresentationDate)
	
	Result = New Structure("StartDate, EndDate");
	
	If PeriodVariant = "Day" Then
		Result.StartDate	= BegOfDay(RepresentationDate);
		Result.EndDate	= EndOfDay(RepresentationDate);
	ElsIf PeriodVariant = "Week" Then
		Result.StartDate	= BegOfWeek(RepresentationDate);
		Result.EndDate	= EndOfWeek(RepresentationDate);
	ElsIf PeriodVariant = "Month" Then
		Result.StartDate	= BegOfWeek(BegOfMonth(RepresentationDate));
		Result.EndDate	= EndOfWeek(EndOfMonth(RepresentationDate));
	EndIf;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function SaveChangeInBase(ProcessedItems)
	
	Return Catalogs.EmployeesCalendarsRecords.SaveChangesCalendarRecords(ProcessedItems);
	
EndFunction

&AtClientAtServerNoContext
Procedure SelectRepresentationDays(Form)
	
	CalendarField = Form.Items.RepresentationDate;
	
	CalendarField.SelectedDates.Clear();
	
	If Form.PeriodVariant = "Month" Then
		// Для варианта "Месяц" выделенные даты календаря отличаются от фактического периода.
		// Фактический период должен быть кратен 7 дням (недели).
		// Но в поле календаря выделяются даты только в пределах месяца.
		PeriodOfData = New Structure("StartDate, EndDate");
		PeriodOfData.StartDate		= BegOfMonth(Form.RepresentationDate);
		PeriodOfData.EndDate	= EndOfMonth(Form.RepresentationDate);
	Else
		PeriodOfData = GetDataPeriod(Form.PeriodVariant, Form.RepresentationDate);
	EndIf;
	
	CurDate = PeriodOfData.StartDate;
	
	While CurDate < PeriodOfData.EndDate Do
		CalendarField.SelectedDates.Add(CurDate);
		CurDate = CurDate + 86400;
	EndDo;
	
EndProcedure

&AtClient
Procedure UpdatePlannerDataClient()
	
	UpdatePlaningDataServer();
	
EndProcedure

&AtServer
Procedure UpdateItemsAvailableCalendars()
	
	DeletedItems = New Array;
	
	For Each GroupOfItems In Items.AvailableCalendars.ChildItems Do
		DeletedItems.Add(GroupOfItems);
	EndDo;
	
	For Each ElementToDelete In DeletedItems Do
		Items.Delete(ElementToDelete);
	EndDo;
	
	For Each CalendarRow In AvailableCalendars Do
		
		IndexOf = AvailableCalendars.IndexOf(CalendarRow);
		
		GroupCalendar = Items.Add("GroupCalendar_" + IndexOf, Type("FormGroup"), Items.AvailableCalendars);
		GroupCalendar.Type = FormGroupType.UsualGroup;
		GroupCalendar.Representation = UsualGroupRepresentation.None;
		GroupCalendar.Group = ChildFormItemsGroup.Horizontal;
		GroupCalendar.ShowTitle = False;
		
		FlagChosen = Items.Add("SelectedCalendar_" + IndexOf, Type("FormField"), GroupCalendar);
		FlagChosen.Type = FormFieldType.CheckBoxField;
		FlagChosen.DataPath = "AvailableCalendars[" + IndexOf + "].Selected";
		FlagChosen.Title = CalendarRow.Description;
		FlagChosen.TitleLocation = FormItemTitleLocation.Right;
		FlagChosen.SetAction("OnChange", "Attachable_ChoicedCalendarOnChange");
		
		IndentDecoration = Items.Add("IndentCalendar_" + IndexOf, Type("FormDecoration"), GroupCalendar);
		IndentDecoration.HorizontalStretch = True;
		
		PictureColors = Items.Add("CalendarColor_" + IndexOf, Type("FormDecoration"), GroupCalendar);
		PictureColors.Type = FormDecorationType.Picture;
		PictureColors.Picture = WorkWithColorClientServer.ColorPictureByPictureNumber(CalendarRow.ColorVariant);
		PictureColors.Hyperlink = True;
		PictureColors.Width = 2;
		PictureColors.Height = 1;
		PictureColors.SetAction("Click", "Attachable_ColorCalendarClick");
		
	EndDo;
	
EndProcedure

&AtServer
Procedure ProcessCalendarRecordServer()
	
	ReadAvailableCalendars();
	UpdatePlaningDataServer();
	
EndProcedure

&AtServer
Procedure ReadAvailableCalendars()
	
	AvailableCalendars.Clear();
	
	SettingsAvailableCalendars = CommonUse.CommonSettingsStorageImport("EmployeeCalendarSettings",
		"AvailableCalendars",
		New ValueTable
	);
	
	BusyColors = ?(SettingsAvailableCalendars.Count() = 0, New Array, SettingsAvailableCalendars.UnloadColumn("ColorVariant"));
	IsNotSpecifiedColors = False;
	
	TableCalendars = Catalogs.EmployeesCalendars.AvailableEmployeeCalendars();
	
	For Each TableRow In TableCalendars Do
		
		NewRow = AvailableCalendars.Add();
		FillPropertyValues(NewRow, TableRow, "Calendar,Description");
		
		FoundString = SettingsAvailableCalendars.Find(TableRow.Calendar);
		If FoundString <> Undefined Then
			FillPropertyValues(NewRow, FoundString, "ColorVariant,Selected");
		EndIf;
		
		If NewRow.ColorVariant = 0 Then
			ChekingColor = 14;
			While True Do
				If BusyColors.Find(ChekingColor) = Undefined Then
					NewRow.ColorVariant = ChekingColor;
					IsNotSpecifiedColors = True;
					Break;
				EndIf;
				ChekingColor = ?(ChekingColor = 24, 1, ChekingColor+1);
			EndDo;
		EndIf;
		
		BusyColors.Add(NewRow.ColorVariant);
		If BusyColors.Count() = 24 Then
			BusyColors.Clear();
		EndIf;
		
	EndDo;
	
	Filter = New Structure("Selected", True);
	If AvailableCalendars.FindRows(Filter).Count() = 0 Then
		
		Filter.Delete("Selected");
		Filter.Insert("Calendar");
		For Each CalendarRow In AvailableCalendars Do
			Filter.Calendar = CalendarRow.Calendar;
			CalendarRow.Selected = TableCalendars.FindRows(Filter)[0].IsOwner;
		EndDo;
		
	EndIf;
	
	If IsNotSpecifiedColors Then
		SaveSettingsAvailableCalendars();
	EndIf;
	
	UpdateItemsAvailableCalendars();
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetPeriodPresentation(Form)
	
	If Form.PeriodVariant = "Day" Then
		
		Form.PeriodPresentation = Format(Form.RepresentationDate, "DF='дддд, д МММ'");
		
	ElsIf Form.PeriodVariant = "Week" Then
		
		PeriodOfData = GetDataPeriod(Form.PeriodVariant, Form.RepresentationDate);
		Form.PeriodPresentation = StrTemplate(
			"%1 - %2",
			Format(PeriodOfData.StartDate, "DF='д МММ'"),
			Format(PeriodOfData.EndDate, "DF='д МММ гггг'")
		);
		
	ElsIf Form.PeriodVariant = "Month" Then
		
		Form.PeriodPresentation = PeriodPresentation(BegOfMonth(Form.RepresentationDate), EndOfMonth(Form.RepresentationDate));
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ExchangeWithGoogle


#EndRegion
