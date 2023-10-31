#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region ProgramInterface

Procedure CreatePredifinedSchedulesTemplates() Export

	BeginTransaction();
	
	ГруппаШаблоновПоДнямНедели = Catalogs.ШаблоныЗаполненияГрафиковРабочегоВремени.CreateFolder();
	ГруппаШаблоновПоДнямНедели.Description = "Patterns on дням weeks";
	
	ГруппаШаблоновСменные = Catalogs.ШаблоныЗаполненияГрафиковРабочегоВремени.CreateFolder();
	ГруппаШаблоновСменные.Description = "Patterns сменные";
	
	Try
		ГруппаШаблоновПоДнямНедели.Write();
		ГруппаШаблоновСменные.Write();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	// По дням Неделеи
	НовыйШаблонПятидневка = Catalogs.ШаблоныЗаполненияГрафиковРабочегоВремени.CreateItem();
	НовыйШаблонПятидневка.DataExchange.Load = True;
	НовыйШаблонПятидневка.AccountHolidays = True;
	НовыйШаблонПятидневка.Parent = ГруппаШаблоновПоДнямНедели.Ref;
	НовыйШаблонПятидневка.Description = "Pattern fivedays";
	
	НовыйШаблонШестидневка = Catalogs.ШаблоныЗаполненияГрафиковРабочегоВремени.CreateItem();
	НовыйШаблонШестидневка.DataExchange.Load = True;
	НовыйШаблонШестидневка.Parent = ГруппаШаблоновПоДнямНедели.Ref;
	НовыйШаблонШестидневка.AccountHolidays = True;
	НовыйШаблонШестидневка.Description = "Pattern sixdays";
	
	НовыйШаблонШестидневка.GraphKindWeekDays = True;
	НовыйШаблонШестидневка.ScheduleType = Enums.WorkScheduleTypes.CalendarDays;
	НовыйШаблонПятидневка.GraphKindWeekDays = True;
	НовыйШаблонПятидневка.ScheduleType = Enums.WorkScheduleTypes.CalendarDays;
		
	For DayIndex = 1 To 7 Do
		
		If DayIndex <= 5 Then
			НоваяСтрокаРасписания = НовыйШаблонПятидневка.WorkSchedule.Add();
			
			НоваяСтрокаРасписания.CycleDayNumber = DayIndex;
			НоваяСтрокаРасписания.BeginTime = Date(1,1,1,8,0,0);
			НоваяСтрокаРасписания.EndTime = Date(1,1,1,17,0,0);
			НоваяСтрокаРасписания.WorkHoursQuantity = 8;
			НоваяСтрокаРасписания.TimeBreak = 1;
			НоваяСтрокаРасписания.Active = True;
			
			НоваяСтрокаПерерыв = НовыйШаблонПятидневка.Breaks.Add();
			НоваяСтрокаПерерыв.BeginTime = Date(1,1,1,12,00,0);
			НоваяСтрокаПерерыв.EndTime = Date(1,1,1,13,00,0);
			НоваяСтрокаПерерыв.Duration = 1;
			НоваяСтрокаПерерыв.DayNumber = DayIndex;
			
			НоваяСтрокаПериода = НовыйШаблонПятидневка.Periods.Add();
			НоваяСтрокаПериода.BeginTime = Date(1,1,1,8,0,0);
			НоваяСтрокаПериода.EndTime = Date(1,1,1,12,0,0);
			НоваяСтрокаПериода.Duration = 4;
			НоваяСтрокаПериода.CycleDayNumber = DayIndex;
			
			НоваяСтрокаПериода = НовыйШаблонПятидневка.Periods.Add();
			НоваяСтрокаПериода.BeginTime = Date(1,1,1,13,0,0);
			НоваяСтрокаПериода.EndTime = Date(1,1,1,17,0,0);
			НоваяСтрокаПериода.Duration = 4;
			НоваяСтрокаПериода.CycleDayNumber = DayIndex;
		
		Else
			НоваяСтрокаРасписания = НовыйШаблонПятидневка.WorkSchedule.Add();
			НоваяСтрокаРасписания.CycleDayNumber = DayIndex;
			НоваяСтрокаРасписания.Active = True
		EndIf;
		
		If DayIndex <= 6 Then
			НоваяСтрокаРасписания = НовыйШаблонШестидневка.WorkSchedule.Add();
			
			НоваяСтрокаРасписания.CycleDayNumber = DayIndex;
			НоваяСтрокаРасписания.BeginTime = Date(1,1,1,8,0,0);
			НоваяСтрокаРасписания.EndTime = Date(1,1,1,17,0,0);
			НоваяСтрокаРасписания.WorkHoursQuantity = 8;
			НоваяСтрокаРасписания.TimeBreak = 1;
			НоваяСтрокаРасписания.Active = True;
			
			НоваяСтрокаПерерыв = НовыйШаблонШестидневка.Breaks.Add();
			НоваяСтрокаПерерыв.BeginTime = Date(1,1,1,12,00,0);
			НоваяСтрокаПерерыв.EndTime = Date(1,1,1,13,00,0);
			НоваяСтрокаПерерыв.Duration = 1;
			НоваяСтрокаПерерыв.DayNumber = DayIndex;
			
			НоваяСтрокаПериода = НовыйШаблонШестидневка.Periods.Add();
			НоваяСтрокаПериода.BeginTime = Date(1,1,1,8,0,0);
			НоваяСтрокаПериода.EndTime = Date(1,1,1,12,0,0);
			НоваяСтрокаПериода.Duration = 4;
			НоваяСтрокаПериода.CycleDayNumber = DayIndex;
			
			НоваяСтрокаПериода = НовыйШаблонШестидневка.Periods.Add();
			НоваяСтрокаПериода.BeginTime = Date(1,1,1,13,0,0);
			НоваяСтрокаПериода.EndTime = Date(1,1,1,17,0,0);
			НоваяСтрокаПериода.Duration = 4;
			НоваяСтрокаПериода.CycleDayNumber = DayIndex;
		Else
			НоваяСтрокаРасписания = НовыйШаблонШестидневка.WorkSchedule.Add();
			НоваяСтрокаРасписания.CycleDayNumber = DayIndex;
			НоваяСтрокаРасписания.Active = True
		EndIf;
		
	EndDo;
	
	//Сменные
	НовыйШаблонСменный2через2_12 = Catalogs.ШаблоныЗаполненияГрафиковРабочегоВремени.CreateItem();
	НовыйШаблонСменный2через2_12.DataExchange.Load = True;
	НовыйШаблонСменный2через2_12.Parent = ГруппаШаблоновСменные.Ref;
	НовыйШаблонСменный2через2_12.Description = NStr("en='Pattern shiftwork 12 hours 2 through 2 ';vi='Làm việc theo mô hình 12 giờ từ 2 đến 2'");
	
	НовыйШаблонЖД = Catalogs.ШаблоныЗаполненияГрафиковРабочегоВремени.CreateItem();
	НовыйШаблонЖД.DataExchange.Load = True;
	НовыйШаблонЖД.Parent = ГруппаШаблоновСменные.Ref;
	НовыйШаблонЖД.Description = NStr("en='Pattern shiftwork 3 through 1 (железнодорожный)';vi='Làm việc theo mô hình 3 đến 1 (đường sắt)'");
	
	НовыйШаблонСменныйСуткиТрое = Catalogs.ШаблоныЗаполненияГрафиковРабочегоВремени.CreateItem();
	НовыйШаблонСменныйСуткиТрое.DataExchange.Load = True;
	НовыйШаблонСменныйСуткиТрое.Parent = ГруппаШаблоновСменные.Ref;
	НовыйШаблонСменныйСуткиТрое.Description = NStr("en='Pattern shiftwork twentyfourhours through трое ';vi='Làm việc theo mô hình hai mươi bốn giờ thông qua ba'");
	
	НовыйШаблонЖД.GrpaphKindByCyrcleArbitraryLenghts = True;
	НовыйШаблонСменный2через2_12.GrpaphKindByCyrcleArbitraryLenghts = True;
	НовыйШаблонСменныйСуткиТрое.GrpaphKindByCyrcleArbitraryLenghts = True;
	
	НовыйШаблонСменный2через2_12.ScheduleType = Enums.WorkScheduleTypes.ShiftWork;
	НовыйШаблонЖД.ScheduleType = Enums.WorkScheduleTypes.ShiftWork;
	НовыйШаблонСменныйСуткиТрое.ScheduleType = Enums.WorkScheduleTypes.ShiftWork;
	
	
	For DayIndex = 1 To 4 Do
		
		If DayIndex <= 2 Then
			НоваяСтрокаРасписания = НовыйШаблонСменный2через2_12.WorkSchedule.Add();
			
			НоваяСтрокаРасписания.CycleDayNumber = DayIndex;
			НоваяСтрокаРасписания.WorkHoursQuantity = 12;
			НоваяСтрокаРасписания.Active = True;
			
			НоваяСтрокаПериода = НовыйШаблонСменный2через2_12.Periods.Add();
			НоваяСтрокаПериода.BeginTime = Date(1,1,1);
			НоваяСтрокаПериода.EndTime = Date(1,1,1);
			НоваяСтрокаПериода.Duration = 12;
			НоваяСтрокаПериода.CycleDayNumber = DayIndex;
		
		Else
			НоваяСтрокаРасписания = НовыйШаблонСменный2через2_12.WorkSchedule.Add();
			НоваяСтрокаРасписания.CycleDayNumber = DayIndex;
			НоваяСтрокаРасписания.Active = False;
		EndIf;
		
		If DayIndex <= 3 Then
			НоваяСтрокаРасписания = НовыйШаблонЖД.WorkSchedule.Add();
			
			НоваяСтрокаРасписания.CycleDayNumber = DayIndex;
			
			If DayIndex = 1 Then
				НоваяСтрокаРасписания.WorkHoursQuantity = 12;
				
				НоваяСтрокаПериода = НовыйШаблонЖД.Periods.Add();
				НоваяСтрокаПериода.BeginTime = Date(1,1,1);
				НоваяСтрокаПериода.EndTime = Date(1,1,1);
				НоваяСтрокаПериода.Duration = 12;
				НоваяСтрокаПериода.CycleDayNumber = DayIndex;
				
			ElsIf DayIndex = 2 Then
				НоваяСтрокаРасписания.WorkHoursQuantity = 4;
				НоваяСтрокаПериода = НовыйШаблонЖД.Periods.Add();
				
				НоваяСтрокаПериода.BeginTime = Date(1,1,1);
				НоваяСтрокаПериода.EndTime = Date(1,1,1);
				НоваяСтрокаПериода.Duration = 4;
				НоваяСтрокаПериода.CycleDayNumber = DayIndex;
			ElsIf DayIndex = 3 Then
				НоваяСтрокаРасписания.WorkHoursQuantity = 8;
				
				НоваяСтрокаПериода = НовыйШаблонЖД.Periods.Add();
				НоваяСтрокаПериода.BeginTime = Date(1,1,1);
				НоваяСтрокаПериода.EndTime = Date(1,1,1);
				НоваяСтрокаПериода.Duration = 8;
				НоваяСтрокаПериода.CycleDayNumber = DayIndex;
			EndIf;
			
			НоваяСтрокаРасписания.Active = True;
		Else
			НоваяСтрокаРасписания = НовыйШаблонЖД.WorkSchedule.Add();
			НоваяСтрокаРасписания.CycleDayNumber = DayIndex;
			НоваяСтрокаРасписания.Active = False
		EndIf;
		
		If DayIndex = 1 Then
			НоваяСтрокаРасписания = НовыйШаблонСменныйСуткиТрое.WorkSchedule.Add();
			
			НоваяСтрокаРасписания.CycleDayNumber = DayIndex;
			НоваяСтрокаРасписания.WorkHoursQuantity = 24;
			
			НоваяСтрокаПериода = НовыйШаблонСменныйСуткиТрое.Periods.Add();
			НоваяСтрокаПериода.BeginTime = Date(1,1,1);
			НоваяСтрокаПериода.EndTime = Date(1,1,1);
			НоваяСтрокаПериода.Duration = 24;
			НоваяСтрокаПериода.CycleDayNumber = DayIndex;
			
			НоваяСтрокаРасписания.Active = True;
		Else
			НоваяСтрокаРасписания = НовыйШаблонСменныйСуткиТрое.WorkSchedule.Add();
			НоваяСтрокаРасписания.CycleDayNumber = DayIndex;
			НоваяСтрокаРасписания.Active = False
		EndIf;
		
	EndDo;
	
	Try
		НовыйШаблонПятидневка.Write();
		НовыйШаблонШестидневка.Write();
		НовыйШаблонСменный2через2_12.Write();
		НовыйШаблонЖД.Write();
		НовыйШаблонСменныйСуткиТрое.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;

EndProcedure

Procedure UpdateWorkSchedules() Export
	
	Query = New Query;
	
	Query.Text =
	"SELECT
	|	WorkSchedules.Ref AS Ref
	|INTO ВТГрафики
	|FROM
	|	Catalog.WorkSchedules AS WorkSchedules
	|
	|GROUP BY
	|	WorkSchedules.Ref
	|
	|HAVING
	|	COUNT(WorkSchedules.DeletePeriods.BeginTime) > 1
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	WorkSchedules.Ref
	|FROM
	|	Catalog.WorkSchedules AS WorkSchedules
	|WHERE
	|	NOT WorkSchedules.DeleteCalendar = VALUE(Catalog.Calendars.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ВТГрафики.Ref AS Ref
	|FROM
	|	ВТГрафики AS ВТГрафики
	|WHERE
	|	NOT ВТГрафики.Ref.DeleteScheduleType = VALUE(Enum.WorkScheduleTypes.EmptyRef)
	|
	|GROUP BY
	|	ВТГрафики.Ref
	|
	|HAVING
	|	COUNT(ВТГрафики.Ref.TemplateByYear.Ref) = 0";
	
	
	ВыборкаГрафиков = Query.Execute().Select();
	
	While ВыборкаГрафиков.Next() Do
		
		If Not ValueIsFilled(ВыборкаГрафиков.Ref.DeleteScheduleType) Then Continue EndIf;
		
		PeriodsQuantity = ВыборкаГрафиков.Ref.DeletePeriods.Count();
		
		ПериодыПустые = True;
		
		For Each RowPeriod In ВыборкаГрафиков.Ref.DeletePeriods Do
			
			If ValueIsFilled(RowPeriod.BeginTime) Or ValueIsFilled(RowPeriod.EndTime) Then
				ПериодыПустые = False;
				Break;
			EndIf;
			
		EndDo;
		
		BeginTransaction();
		
		SelectionObject = ВыборкаГрафиков.Ref.GetObject();
		SelectionObject.DataExchange.Load = True;
		
		If ValueIsFilled(SelectionObject.DeleteCalendar) And ValueIsFilled(SelectionObject.DeleteCalendar.BusinessCalendar)
			Then
			SelectionObject.BusinessCalendar = SelectionObject.DeleteCalendar.BusinessCalendar;
		EndIf;
		
		If PeriodsQuantity And Not ПериодыПустые Then
		
		NewPattern = Catalogs.ШаблоныЗаполненияГрафиковРабочегоВремени.CreateItem();
		NewPattern.Description = "Pattern "+SelectionObject.Description;
		
		ЭтоНедельныйГрафик = False;
		
		If SelectionObject.DeleteScheduleType = Enums.WorkScheduleTypes.FiveDays
			Or SelectionObject.DeleteScheduleType = Enums.WorkScheduleTypes.SixDays
			Or SelectionObject.DeleteScheduleType = Enums.WorkScheduleTypes.CalendarDays
			Then
			NewPattern.ScheduleType = Enums.WorkScheduleTypes.CalendarDays;
			ЭтоНедельныйГрафик = True;
		Else
			NewPattern.ScheduleType = Enums.WorkScheduleTypes.ShiftWork;
		EndIf;
		
		SelectionObject.DeletePeriods.Sort("DayNumber Asc, BeginTime Asc");
		
		If ЭтоНедельныйГрафик Then
			ПоследнийДеньПериодов = 7;
		Else
			ПоследнийДеньПериодов = SelectionObject.DeletePeriods[PeriodsQuantity-1].DayNumber;
		EndIf;
		
		For DayNumber = 1 To ПоследнийДеньПериодов Do
			
			FilterParameters = New Structure("DayNumber", DayNumber);
			СтрокиПоДню = SelectionObject.DeletePeriods.FindRows(FilterParameters);
			
			If Not СтрокиПоДню.Count() Then
				
				If ЭтоНедельныйГрафик Then
					RowTemplate = NewPattern.WorkSchedule.Add();
					RowTemplate.CycleDayNumber = DayNumber;
					Continue;
				Else
					Break
				EndIf;
				
			EndIf;
			
			RowTemplate = NewPattern.WorkSchedule.Add();
			RowTemplate.BeginTime = СтрокиПоДню[0].BeginTime;
			RowTemplate.CycleDayNumber = DayNumber;
			
			ДлительностьПериодов = 0;
			
			//Периоды Шаблона
			For Each PeriodString In СтрокиПоДню Do
				
				СтрокаПериодШаблона = NewPattern.Periods.Add();
				СтрокаПериодШаблона.BeginTime = PeriodString.BeginTime;
				СтрокаПериодШаблона.EndTime = ?(PeriodString.EndTime = EndOfDay(PeriodString.EndTime)
				, BegOfDay(PeriodString.EndTime), PeriodString.EndTime);
				
				СтрокаПериодШаблона.CycleDayNumber = DayNumber;
				
				Duration = Round((СтрокаПериодШаблона.EndTime - СтрокаПериодШаблона.BeginTime)/3600, 2, RoundMode.Round15as20);
				СтрокаПериодШаблона.Duration = ?(Duration < 0, 24 + Duration, Duration);
				
				ДлительностьПериодов = ДлительностьПериодов + СтрокаПериодШаблона.Duration;
				
			EndDo;
			//Конец Перерывы Шаблона
			
			RowTemplate.EndTime = СтрокаПериодШаблона.EndTime;
			
			RowTemplate.Active = ?(ValueIsFilled(RowTemplate.BeginTime) Or ValueIsFilled(СтрокаПериодШаблона.EndTime), True, False);
			
			//Перерывы Шаблона
			ПоследнееВремяОкончанияПерерыва = Date(1,1,1);
			
			FilterParameters = New Structure("CycleDayNumber", DayNumber);
			Periods = NewPattern.Periods.FindRows(FilterParameters);
			
			PeriodsQuantity = NewPattern.Periods.Count();
			RowIndex = 1;
			
			ДлительностьПерерывов = 0;
			ВремяНачалаПерерыва = Date(1,1,1);
			
			For Each RowPeriod In Periods Do
				
				If PeriodsQuantity = 1 Then Break EndIf;
				
				If RowIndex = 1 Then
					
					ВремяНачалаПерерыва = RowPeriod.EndTime;
				Else
					
					NewRow = NewPattern.Breaks.Add();
					NewRow.DayNumber = DayNumber;
					
					NewRow.BeginTime = ВремяНачалаПерерыва;
					NewRow.EndTime = RowPeriod.BeginTime;
					
					ВремяНачалаПерерыва = RowPeriod.EndTime;
					
					NewRow.Duration = Round((NewRow.EndTime - NewRow.BeginTime)/3600, 2, RoundMode.Round15as20);
					
					ДлительностьПерерывов = ДлительностьПерерывов + NewRow.Duration;
					
				EndIf;
				
				RowIndex = RowIndex + 1;
				
			EndDo;
			//Конец Перерывы Шаблона
			
			RowTemplate.WorkHoursQuantity = ДлительностьПериодов;
			RowTemplate.TimeBreak = ДлительностьПерерывов;
			
		EndDo;
		
		SelectionObject.GraphPeriods.Clear();
		SelectionObject.Breaks.Clear();
		SelectionObject.WorkSchedule.Clear();
		SelectionObject.DeletePeriods.Clear();
		
		SelectionObject.GraphPeriods.Load(NewPattern.Periods.Unload());
		SelectionObject.Breaks.Load(NewPattern.Breaks.Unload());
		SelectionObject.WorkSchedule.Load(NewPattern.WorkSchedule.Unload());
		
		ЭтоГрафикПоДнямНедели = ?(NewPattern.ScheduleType = Enums.WorkScheduleTypes.CalendarDays, True, False);
		
		Try
			NewPattern.Write();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
		
		EndIf;
		
		Query = New Query;
		Query.SetParameter("WorkSchedule", ВыборкаГрафиков.Ref);
		
		Query.Text = 
		"SELECT DISTINCT
		|	WorkSchedules.Year AS Year
		|FROM
		|	InformationRegister.WorkSchedules AS WorkSchedules
		|WHERE
		|	WorkSchedules.WorkSchedule = &WorkSchedule
		|
		|ORDER BY
		|	Year";
		
		ВыборкаГода = Query.Execute().Select();
		
		While ВыборкаГода.Next() Do
			
			NewRow = SelectionObject.TemplateByYear.Add();
			NewRow.Year = ВыборкаГода.Year;
			NewRow.TemplateGraphFill = ?(Not NewPattern = Undefined, NewPattern.Ref, Undefined);
			NewRow.ScheduleType =  ?(Not NewPattern = Undefined, NewPattern.ScheduleType, Undefined);
			NewRow.BeginnigDate = ?(Year(ВыборкаГрафиков.Ref.DeleteBeginnigDate) = NewRow.Year, ВыборкаГрафиков.Ref.DeleteBeginnigDate, Date(1,1,1));
			
			//Обработка регистра сведений
			RecordSet = InformationRegisters.WorkSchedules.CreateRecordSet();
			RecordSet.Filter.WorkTimetable.Set(ВыборкаГрафиков.Ref);
			RecordSet.Filter.Year.Set(ВыборкаГода.Year);
			RecordSet.Read();
			
				For Each WriteSet In RecordSet Do
					
					TimeDifference = WriteSet.EndTime - WriteSet.BeginTime;
					TimeDifference = ?(TimeDifference = 86399, 86400, TimeDifference);
					
					Duration = Round((TimeDifference)/3600, 2, RoundMode.Round15as20);
					WriteSet.WorkHours = ?(Duration < 0, 24 + Duration, Duration);
					
				EndDo;
			
			Try
				RecordSet.Write();
			Except
				RollbackTransaction();
				Raise;
			EndTry;
			
		EndDo;
		
		Try
			SelectionObject.Write();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
		
		CommitTransaction();
		
	EndDo;
	
	//Обработка регистра сведений "Отклонения от графиков работы"
	RecordSet = InformationRegisters.DeviationFromResourcesWorkSchedules.CreateRecordSet();
	RecordSet.Read();
	
	For Each WriteSet In RecordSet Do
		
		TimeDifference = WriteSet.EndTime - WriteSet.BeginTime;
		TimeDifference = ?(TimeDifference = 86399, 86400, TimeDifference);
		
		Duration = Round((TimeDifference)/3600, 2, RoundMode.Round15as20);
		WriteSet.WorkHours = ?(Duration < 0, 24 + Duration, Duration);
		
	EndDo;
	
	Try
		RecordSet.Write();
	Except
		Raise;
	EndTry;
	
EndProcedure

Procedure FillByProductionCalendarData(ScheduleData, CurrentYearNumber, UpdateCalendar = False,
	БезКалендаря = False, OnFormOpening = False, BeginnigDate, ScheduleType, ChangedDays = Undefined, FilledObject) Export
	
	If Not ValueIsFilled(FilledObject.BusinessCalendar) And Not БезКалендаря Then Return EndIf;
	
	ConsiderHolidays = FilledObject.AccountHolidays;
	
	ЭтоГрафикПоДнямНедели = ?(ScheduleType = Enums.WorkScheduleTypes.CalendarDays, True, False);
	
	If Not БезКалендаря Then
		CalendarData = BusinessCalendarData(FilledObject.BusinessCalendar, CurrentYearNumber);
		If Not CalendarData.Count() Then Return EndIf;
	EndIf;
	
	ГрафикПустой = Not ScheduleData.Count();
	
	If ЭтоГрафикПоДнямНедели Or UpdateCalendar
		Or OnFormOpening Or БезКалендаря Then
		
		For CounterMonth = 1 To 12 Do
			
			If UpdateCalendar And Not ГрафикПустой Then
				CalendarRow = ScheduleData[CounterMonth-1];
			Else
				CalendarRow = ScheduleData.Add();
			EndIf;
			
			CalendarRow.MonthNumber = CounterMonth;
			
			CalendarRow.NumberOfDaysInMonth = Day(EndOfMonth(Date(CurrentYearNumber,CounterMonth, 1)));
			
			WorkHoursPerMonth = 0;
			
			For DayNumber = 1 To CalendarRow.NumberOfDaysInMonth Do
				
				StringDayNumber = String(DayNumber); 
				
				NameFieldDay = NStr("en='Day';vi='Ngày'") + StringDayNumber;
				NameFieldDayKind = "DayKind"+StringDayNumber;
				NameFieldCycleDay = "CycleDayNumber"+StringDayNumber;
				
				If БезКалендаря Then
					CalendarRow[NameFieldDayKind] = Enums.BusinessCalendarDayKinds.Working;
					Continue
				EndIf;
				
				DateOfDay = Date(CurrentYearNumber, CounterMonth, DayNumber);
				
				FilterParameters = New Structure("Date", DateOfDay);
				
				RowsProductionCalendar = CalendarData.FindRows(FilterParameters);
				
				RowProductionCalendar = RowsProductionCalendar[0];
				
				If UpdateCalendar Then
					CalendarRow[NameFieldDayKind] = RowProductionCalendar.DayKind;
					Continue;
				EndIf;
				
				CycleDayNumber = WeekDay(RowProductionCalendar.Date);
				
				FilterParameters = New Structure("CycleDayNumber", CycleDayNumber);
				
				ЧасыРаботыПоДню = FilledObject.WorkSchedule.FindRows(FilterParameters);
				
				WorkHoursQuantity = DateTimeByAddSettings(DateOfDay, RowProductionCalendar.DayKind, ChangedDays, FilledObject, RowProductionCalendar.DestinationDate);
				
				If (Not ЧасыРаботыПоДню.Count() And WorkHoursQuantity = 0)
					Or (FilledObject.AccountHolidays And (RowProductionCalendar.DayKind = Enums.BusinessCalendarDayKinds.Holiday 
					Or (Not RowProductionCalendar.DayKind = Enums.BusinessCalendarDayKinds.Preholiday And ValueIsFilled(RowProductionCalendar.DestinationDate))))Then
					CalendarRow[NameFieldDayKind] = RowProductionCalendar.DayKind;
					Continue;
				EndIf;
					
				CalendarRow["Changed"+StringDayNumber] = ?(Not WorkHoursQuantity = 0, True, False);
				
				If WorkHoursQuantity = 0 Then
					WorkHoursQuantity = ЧасыРаботыПоДню[0].WorkHoursQuantity;
				EndIf;
				
				CalendarRow[NameFieldDayKind] = RowProductionCalendar.DayKind;
				CalendarRow[NameFieldDay] = WorkHoursQuantity;
				CalendarRow[NameFieldCycleDay] = CycleDayNumber;
				
				WorkHoursPerMonth = WorkHoursPerMonth + WorkHoursQuantity;
				
				If RowProductionCalendar.DayKind = Enums.BusinessCalendarDayKinds.Preholiday
					Or RowProductionCalendar.DayKind = Enums.BusinessCalendarDayKinds.Working Then
					
					CalendarRow[NameFieldDayKind] = Enums.BusinessCalendarDayKinds.Working;
					
				EndIf;
				
			EndDo;
			
			WorkHoursPerMonth = Round(WorkHoursPerMonth, 2, RoundMode.Round15as20);
			
			If OnFormOpening Then
				CalendarRow.DayHoursRepresentation = String(CalendarRow.NumberOfDaysInMonth) + " / " + String(WorkHoursPerMonth);
				CalendarRow.TotalsDays = CalendarRow.NumberOfDaysInMonth;
				CalendarRow.MonthRepresentstion = GetMonthByNumber(CounterMonth);
				Continue
			EndIf;
				
			If UpdateCalendar Then Continue;
			EndIf;
				
			CalendarRow.MonthRepresentstion = GetMonthByNumber(CounterMonth);
			
			CalendarRow.DayHoursRepresentation = String(CalendarRow.NumberOfDaysInMonth) + " / " + String(WorkHoursPerMonth);
			CalendarRow.TotalsDays = CalendarRow.NumberOfDaysInMonth;
			CalendarRow.TotalHours = WorkHoursPerMonth;
			
		EndDo;
		
	Else
		
		КоличествоПосменныхДней = FilledObject.WorkSchedule.Count();
		
		If КоличествоПосменныхДней = 0 Then Return EndIf;
		
		ИндексДняПосменныхДней = 1;
		
		For CounterMonth = 1 To 12 Do
			
			CalendarRow = ScheduleData.Add();
			
			CalendarRow.MonthNumber = CounterMonth;
			
			CalendarRow.NumberOfDaysInMonth = Day(EndOfMonth(Date(CurrentYearNumber,CounterMonth, 1)));
			
			WorkHoursPerMonth = 0;
			
			For DayNumber = 1 To CalendarRow.NumberOfDaysInMonth Do
				
				StringDayNumber = String(DayNumber);
				
				NameFieldDay = NStr("en='Day';vi='Ngày'") + StringDayNumber;
				NameFieldDayKind = "DayKind"+StringDayNumber;
				NameFieldCycleDay = "CycleDayNumber"+StringDayNumber;
				
				DateOfDay = Date(CurrentYearNumber, CounterMonth, DayNumber);
				
				FilterParameters = New Structure("Date", DateOfDay);
				
				RowsProductionCalendar = CalendarData.FindRows(FilterParameters);
				
				RowProductionCalendar = RowsProductionCalendar[0];
				
				CalendarRow[NameFieldDayKind] = RowProductionCalendar.DayKind;
				
				If DateOfDay < BeginnigDate Then Continue EndIf;
				
				CalendarRow[NameFieldCycleDay] = ИндексДняПосменныхДней;
				
				FilterParameters = New Structure("CycleDayNumber, Active", ИндексДняПосменныхДней, True);
				
				ИндексДняПосменныхДней = ?(ИндексДняПосменныхДней = КоличествоПосменныхДней, 1, ИндексДняПосменныхДней + 1);
				
				ЧасыРаботыПоДню = FilledObject.WorkSchedule.FindRows(FilterParameters);
				
				WorkHoursQuantity = DateTimeByAddSettings(DateOfDay, RowProductionCalendar.DayKind, ChangedDays, FilledObject, RowProductionCalendar.DestinationDate);
				
				If (Not ЧасыРаботыПоДню.Count() And WorkHoursQuantity = 0)
					Or (FilledObject.AccountHolidays And (RowProductionCalendar.DayKind = Enums.BusinessCalendarDayKinds.Holiday 
					Or (Not RowProductionCalendar.DayKind = Enums.BusinessCalendarDayKinds.Preholiday And ValueIsFilled(RowProductionCalendar.DestinationDate))))Then
					CalendarRow[NameFieldDayKind] = RowProductionCalendar.DayKind;
					Continue;
				EndIf;
					
				CalendarRow["Changed"+StringDayNumber] = ?(Not WorkHoursQuantity = 0, True, False);
				
				If WorkHoursQuantity = 0 Then
					WorkHoursQuantity = ЧасыРаботыПоДню[0].WorkHoursQuantity;
				EndIf;
					
				CalendarRow[NameFieldDay] = WorkHoursQuantity;
				
				WorkHoursPerMonth = WorkHoursPerMonth + WorkHoursQuantity;
				
			EndDo;
			
			WorkHoursPerMonth = Round(WorkHoursPerMonth, 2, RoundMode.Round15as20);
			
			CalendarRow.MonthRepresentstion = GetMonthByNumber(CounterMonth);
			CalendarRow.DayHoursRepresentation = String(CalendarRow.NumberOfDaysInMonth) + " / " + String(WorkHoursPerMonth);
			CalendarRow.TotalsDays = CalendarRow.NumberOfDaysInMonth;
			CalendarRow.TotalHours = WorkHoursPerMonth;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Function DateTimeByAddSettings(DateOfDay, DayKind, ChangedDays, FilledObject, DestinationDate = Undefined)
	
	For Each ДопНастройка In FilledObject.AdditionalFillingSettings Do
		
		If ValueIsFilled(ДопНастройка.SettingValue) Then
			
			If ДопНастройка.SettingValue = "On четным числам" And Day(DateOfDay)%2 = 0 Then
				If Not ДопНастройка.WorkHoursQuantity = 0 Then
					FillPeriodsByAddSettings(ChangedDays,DateOfDay, ДопНастройка.SettingValue, FilledObject);
				EndIf;
				Return ДопНастройка.WorkHoursQuantity;
			EndIf;
			
			If ДопНастройка.SettingValue = "On нечетным числам" And Not Day(DateOfDay)%2 = 0 Then
				If Not ДопНастройка.WorkHoursQuantity = 0 Then
					FillPeriodsByAddSettings(ChangedDays,DateOfDay, ДопНастройка.SettingValue, FilledObject);
				EndIf;
				Return ДопНастройка.WorkHoursQuantity;
			EndIf;
			
			If ДопНастройка.SettingValue = "On субботам" And WeekDay(DateOfDay) = 6 Then
				If Not ДопНастройка.WorkHoursQuantity = 0 Then
					FillPeriodsByAddSettings(ChangedDays,DateOfDay, ДопНастройка.SettingValue, FilledObject);
				EndIf;
				Return ДопНастройка.WorkHoursQuantity;
			EndIf;
			
			If ДопНастройка.SettingValue = "On воскресеньям" And WeekDay(DateOfDay) = 7 Then
				If Not ДопНастройка.WorkHoursQuantity = 0 Then
					FillPeriodsByAddSettings(ChangedDays,DateOfDay, ДопНастройка.SettingValue, FilledObject);
				EndIf;
				Return ДопНастройка.WorkHoursQuantity;
			EndIf;
			
			If ДопНастройка.SettingValue = "In holidays" And (DayKind = Enums.BusinessCalendarDayKinds.Holiday
				Or (Not DayKind = Enums.BusinessCalendarDayKinds.Preholiday And ValueIsFilled(DestinationDate))) Then
				If Not ДопНастройка.WorkHoursQuantity = 0 Then
					FillPeriodsByAddSettings(ChangedDays,DateOfDay, ДопНастройка.SettingValue, FilledObject);
				EndIf;
				Return ДопНастройка.WorkHoursQuantity;
			EndIf;
			
			If ДопНастройка.SettingValue = "In предпраздничных днях" And DayKind = Enums.BusinessCalendarDayKinds.Preholiday Then
				If Not ДопНастройка.WorkHoursQuantity = 0 Then
					FillPeriodsByAddSettings(ChangedDays,DateOfDay, ДопНастройка.SettingValue, FilledObject);
				EndIf;
				Return ДопНастройка.WorkHoursQuantity;
			EndIf;
			
			If ДопНастройка.SettingValue = "In output"
				And (DayKind = Enums.BusinessCalendarDayKinds.Holiday
				Or WeekDay(DateOfDay) = 6
				Or WeekDay(DateOfDay) = 7) Then
				If Not ДопНастройка.WorkHoursQuantity = 0 Then
					FillPeriodsByAddSettings(ChangedDays,DateOfDay, ДопНастройка.SettingValue, FilledObject);
				EndIf;
				
				Return ДопНастройка.WorkHoursQuantity;
				
			EndIf;
			
		EndIf;
	EndDo;
	
	Return 0;
	
EndFunction

Procedure FillPeriodsByAddSettings(ChangedDays, DateOfDay, SettingValue, FilledObject)
	
	FilterParameters = New Structure("SettingValue", SettingValue);
	
	СтрокиДопНастроек = FilledObject.AdditionalFillingSettingsPeriods.FindRows(FilterParameters);
	
	For Each СтрокаДопНастройки In СтрокиДопНастроек Do
		
		NewRow = ChangedDays.Add();
		
		FillPropertyValues(NewRow, СтрокаДопНастройки);
		
		NewRow.DateOfDay = DateOfDay;
		
	EndDo;
	
	
EndProcedure

// Функция читает данные производственного календаря из регистра.
//
// Parameters:
//	BusinessCalendar			- Ссылка на текущий элемент справочника.
//	YearNumber							- Номер года, за который необходимо прочитать производственный календарь.
//
// Возвращаемое значение
//	ДанныеПроизводственногоКалендаря	- таблица значений, в которой хранятся сведения о виде дня на каждую дату календаря.
//
Function BusinessCalendarData(BusinessCalendar, YearNumber) Export
	
	Query = New Query;
	
	Query.SetParameter("BusinessCalendar",	BusinessCalendar);
	Query.SetParameter("CurrentYear",	YearNumber);
	Query.Text =
	"SELECT
	|	BusinessCalendarData.Date,
	|	BusinessCalendarData.DayKind,
	|	BusinessCalendarData.DestinationDate
	|FROM
	|	InformationRegister.BusinessCalendarData AS BusinessCalendarData
	|WHERE
	|	BusinessCalendarData.Year = &CurrentYear
	|	AND BusinessCalendarData.BusinessCalendar = &BusinessCalendar";
	
	Return Query.Execute().Unload();
	
EndFunction

Function GetMonthByNumber(MonthNumber)
	
	MapMonth = New Map();
	MapMonth.Insert(1, NStr("en='January';vi='Tháng 1';"));
	MapMonth.Insert(2, NStr("en='February';vi='Tháng 2';"));
	MapMonth.Insert(3, NStr("en='March';vi='Tháng 3';"));
	MapMonth.Insert(4, NStr("en='April';vi='Tháng 4';"));
	MapMonth.Insert(5, NStr("en='May';vi='Tháng 5';"));
	MapMonth.Insert(6, NStr("en='June';vi='Tháng 6';"));
	MapMonth.Insert(7, NStr("en='July';vi='Tháng 7';"));
	MapMonth.Insert(8, NStr("en='August';vi='Tháng 8';"));
	MapMonth.Insert(9, NStr("en='September';vi='Tháng 9';"));
	MapMonth.Insert(10, NStr("en='October';vi='Tháng 10';"));
	MapMonth.Insert(11, NStr("en='November';vi='Tháng 11';"));
	MapMonth.Insert(12, NStr("en='December';vi='Tháng 12';"));
	
	Return MapMonth.Get(MonthNumber); 
	
EndFunction

#EndRegion

#EndIf