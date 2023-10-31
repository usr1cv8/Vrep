&AtClient
Var ВремяОкончанияРегулирование;

#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	DateOfDay = Parameters.DateOfDay;
	ЭтоИзменениеИнтервалаГрафика = Parameters.SelectedInterval;
	
	TimeBreak = 0;
	
	If Not ValueIsFilled(DateOfDay) And Not ЭтоИзменениеИнтервалаГрафика Then
		Cancel = True;
		Return;
	EndIf;
	
	If Parameters.Property("Ref") Then
		LineReference = Parameters.Ref;
	ElsIf Parameters.Property("Object") Then
		LineReference = Parameters.Object;
	Else
		Return;
	EndIf;
	
	If Not ЭтоИзменениеИнтервалаГрафика Then
	
		ThisForm.Title = NStr("en='Schedule on date: ';vi='Lịch biểu: '") + Format(DateOfDay,"DLF=Д");
		
		If Parameters.Changed Then
			
			FilterParameters = New Structure();
			FilterParameters.Insert("DateOfDay",DateOfDay);
			
			ИзмененныйПериод_Строки = Parameters.ChangedDays.FindRows(FilterParameters);
			
			If ИзмененныйПериод_Строки.Count() Then
				
				TableOfPeriods = ПериодыВПерерывы(Parameters.ChangedDays.Unload(ИзмененныйПериод_Строки));
				Breaks.Load(TableOfPeriods);
				
			EndIf;
			
		Else
			
			DayNumber = Parameters.CycleDayNumber;
			
			If Not DayNumber = 0 Then
				
				FilterParameters = New Structure();
				FilterParameters.Insert("CycleDayNumber",DayNumber);
				
				СтрокиПериодов = LineReference.GraphPeriods.FindRows(FilterParameters);
				
				TableOfPeriods = ПериодыВПерерывы(LineReference.GraphPeriods.Unload(СтрокиПериодов));
				
				Breaks.Load(TableOfPeriods);
				
			EndIf;
			
		EndIf;
		
		WorkHoursWithBreak = Parameters.WorkingHours;
		Items.TimeBreak.ReadOnly = Breaks.Count();
		
		EndTime = ?(EndTime = Date(1,1,1) And WorkHoursWithBreak > 0, Date(1,1,1, 23,59,0), EndTime);
		FinishTimeForCalculation = ?(EndTime =Date(1,1,1, 23,59,0) And WorkHoursWithBreak > 0, Date(1,1,1), EndTime);
		
		If Not ValueIsFilled(BeginTime) And Not ValueIsFilled(FinishTimeForCalculation)
			Then
			
			If Not Parameters.WorkingHours = 24 Then
				ДатаНачалаРасчет = 28800+ Parameters.WorkingHours * 3600;
				BeginTime = ?(ДатаНачалаРасчет>86400, 28800 - (ДатаНачалаРасчет - 86400), ДатаНачалаРасчет);
			EndIf;
			
		EndIf;
		
		Return;
	EndIf;
		
	If Not Parameters.Property("ListDays") Then
		Return
	EndIf;
	
	MapTransferedDataGraphs = ?(Parameters.Property("MapTransferedDataGraphs")
										, Parameters.MapTransferedDataGraphs, Undefined);
	
	If Not ПараметрыДнейСовпадают(Parameters.ListDays, Parameters.ChangedDays, LineReference.GraphPeriods, MapTransferedDataGraphs)
		Or Parameters.Property("ErrorText") Then
		
		Items.ГруппаТекстОшибки.Visible = True;
		
		ErrorText = ?(Parameters.Property("ErrorText"), Parameters.ErrorText
		,NStr("en='Parameters выделенных days not match. When edit schedule will updated current.';vi='Các thông số đã chọn ngày không khớp. Khi chỉnh sửa lịch trình sẽ cập nhật hiện tại.'"));
		
	Else
		Items.TimeBreak.ReadOnly = Breaks.Count();
		WorkHoursWithBreak = Parameters.WorkingHours;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	РасчитатьВремяПерерывовИСформироватьПредставлениеРасписанияПриОткрытии();
EndProcedure

#EndRegion

#Region FormItemEventsHandlers

&AtClient
Procedure WorkingHoursTuning(Item, Direction, StandardProcessing)
	If Direction> 0 And EndTime = Date(1,1,1,23,59,0) Then
		FinishTimeForCalculation = Date(1,1,1);
	EndIf
EndProcedure

&AtClient
Procedure РасписаниеРаботыОкончаниеРабочегоДняРегулирование(Item, Direction, StandardProcessing)
	
	ВремяОкончанияРегулирование = ?(Direction>0,EndTime, Undefined);
	EndTime = ?(EndTime = Date(1,1,1,23,59,0), Date(1,1,1), EndTime);
	
EndProcedure

&AtClient
Procedure TimeBreakOnChange(Item)
	
	ОбработкаИзмененияВремениПерерывов();
	ПриИзмененииЧасовРаботы();
	
EndProcedure

&AtClient
Procedure BreaksBeforeDeleteRow(Item, Cancel)
	
	CurrentData = Items.Breaks.CurrentData;
	
	If CurrentData = Undefined Then Return EndIf;
	
	TimeBreak = TimeBreak - CurrentData.Duration;
	
	ОбработкаИзмененияВремениПерерывов(True);
	
EndProcedure

&AtClient
Procedure BreaksBeginTimeOnChange(Item)
	
	CurrentData = Items.Breaks.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	If ValueIsFilled(BeginTime) And
		CurrentData.BeginTime < BeginTime Then
		CurrentData.BeginTime = BeginTime;
	EndIf;
	
	If ValueIsFilled(CurrentData.EndTime) And CurrentData.BeginTime >= CurrentData.EndTime Then
		CurrentData.ОшибкаПериода = True;
	Else
		CurrentData.ОшибкаПериода = False;
	EndIf;
	
	CalculateBreaksTimeAndFormDescription();
	
	BreakTimeError = ?(TimeBreak+WorkHoursWithBreak>WorkTimeInterval, True, False);
	
EndProcedure

&AtClient
Procedure РасписаниеРаботыОкончаниеРабочегоДняПриИзменении(Item)
	
	If EndTime = Date(1,1,1) And WorkHoursWithBreak = 0 Then
		FinishTimeForCalculation = Date(1,1,1);
	ElsIf EndTime = Date(1,1,1) And WorkHoursWithBreak > 0 Then
		 EndTime = Date(1,1,1,23,59,0);
		 FinishTimeForCalculation = Date(1,1,1);
	 ElsIf Not(ВремяОкончанияРегулирование) = Undefined
		 And ВремяОкончанияРегулирование = Date(1,1,1,23,59,0) 
		 And FinishTimeForCalculation = Date(1,1,1) Then
		 
		EndTime = Date(1,1,1);
	 Else
		FinishTimeForCalculation = ?(EndTime =Date(1,1,1, 23,59,0), Date(1,1,1), EndTime);
	EndIf;
	
	ОбработатьИзменениеПериодаРабочегоДня(False);
	ПроверитьГраницыПерерывовПриИзмниненииПериодаРабочегоДня(False);
	
	ВремяОкончанияРегулирование = Undefined;
	
EndProcedure

&AtClient
Procedure РасписаниеРаботыНачалоРабочегоДняПриИзменении(Item)
	
	ОбработатьИзменениеПериодаРабочегоДня();
	ПроверитьГраницыПерерывовПриИзмниненииПериодаРабочегоДня();
	
EndProcedure

&AtClient
Procedure BreaksEndTimeOnChange(Item)
	
	CurrentData = Items.Breaks.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	
	If ValueIsFilled(EndTime) And CurrentData.EndTime > EndTime Then
		CurrentData.EndTime = EndTime;
	EndIf;
	
	If ValueIsFilled(CurrentData.BeginTime) And ValueIsFilled(CurrentData.EndTime) 
		And CurrentData.EndTime <= CurrentData.BeginTime Then
		CurrentData.ОшибкаПериода = True;
	Else
		CurrentData.ОшибкаПериода = False;
	EndIf;
	
	CalculateBreaksTimeAndFormDescription(False);
	
	BreakTimeError = ?(TimeBreak+WorkHoursWithBreak>WorkTimeInterval, True, False);
	
EndProcedure

&AtClient
Procedure WorkingHoursOnChange(Item)
	
	ПриИзмененииЧасовРаботы();
	
EndProcedure

&AtClient
Procedure BreaksAfterDeleteRow(Item)
	
	If Not Breaks.Count() Then
		TimeBreak = 0;
		WorkHoursWithBreak = WorkTimeInterval;
		If ValueIsFilled(BeginTime) Or ValueIsFilled(FinishTimeForCalculation) Then
			ОбработатьИзменениеПериодаРабочегоДня();
		EndIf;
	EndIf;
	
	ПриИзмененииЧасовРаботы();
	BreakTimeError = ?(WorkHoursWithBreak + TimeBreak > WorkTimeInterval, True, False);
	
EndProcedure

&AtClient
Procedure BreaksOnChange(Item)
	Items.TimeBreak.ReadOnly = Breaks.Count();
EndProcedure

&AtClient
Procedure BreaksOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		CurrentData = Items.Breaks.CurrentData;
		CurrentData.LineNumber = Breaks.Count();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure MoveToGraph(Command)
	
	If Not ПроверитьГраницыПерерывов() Then Return EndIf;
	
	Breaks.Sort("BeginTime");
	
	Periods.Clear();
	
	ПоследнееВремяОкончанияПерерыва = Date(1,1,1);
	КоличествоПерерывов = Breaks.Count();
	RowIndex = 1;
	
	For Each СтрокаПерерыва In Breaks Do
		
		If RowIndex = 1 Then
			
			NewRow = Periods.Add();
			NewRow.CycleDayNumber = DayNumber;
			
			NewRow.BeginTime = BeginTime;
			NewRow.EndTime = ?(ValueIsFilled(СтрокаПерерыва.BeginTime),СтрокаПерерыва.BeginTime, СтрокаПерерыва.EndTime);
			
			NewRow.Duration = Round((NewRow.EndTime - NewRow.BeginTime)/3600, 2, RoundMode.Round15as20);
			
			//Если всего один перерыв
			If RowIndex = КоличествоПерерывов Then
				
				NewRow = Periods.Add();
				NewRow.CycleDayNumber = DayNumber;
				
				NewRow.BeginTime = СтрокаПерерыва.EndTime;
				NewRow.EndTime = FinishTimeForCalculation;
				
				Duration = Round((NewRow.EndTime - NewRow.BeginTime)/3600, 2, RoundMode.Round15as20);
				NewRow.Duration = ?(Duration < 0, 24 + Duration, Duration);
				
			EndIf;
			
		ElsIf RowIndex = КоличествоПерерывов Then
			
			If Not СтрокаПерерыва.BeginTime = ПоследнееВремяОкончанияПерерыва Then
				
				NewRow = Periods.Add();
				NewRow.CycleDayNumber = DayNumber;
				
				NewRow.BeginTime = ПоследнееВремяОкончанияПерерыва;
				NewRow.EndTime = СтрокаПерерыва.BeginTime;
				
				NewRow.Duration = Round((NewRow.EndTime - NewRow.BeginTime)/3600, 2, RoundMode.Round15as20)
				
			EndIf;
			
			NewRow = Periods.Add();
			NewRow.CycleDayNumber = DayNumber;
			
			NewRow.BeginTime = СтрокаПерерыва.EndTime;
			NewRow.EndTime = FinishTimeForCalculation;
			
			Duration = Round((NewRow.EndTime - NewRow.BeginTime)/3600, 2, RoundMode.Round15as20);
			NewRow.Duration = ?(Duration < 0, 24 + Duration, Duration);
			
		Else
			
			If СтрокаПерерыва.BeginTime = ПоследнееВремяОкончанияПерерыва Then
				ПоследнееВремяОкончанияПерерыва = СтрокаПерерыва.EndTime;
				RowIndex = RowIndex + 1;
				Continue
			EndIf;
			
			NewRow = Periods.Add();
			NewRow.CycleDayNumber = DayNumber;
			
			NewRow.BeginTime = ПоследнееВремяОкончанияПерерыва;
			NewRow.EndTime = СтрокаПерерыва.BeginTime;
			
			NewRow.Duration = Round((NewRow.EndTime - NewRow.BeginTime)/3600, 2, RoundMode.Round15as20)
			
		EndIf;
		
		ПоследнееВремяОкончанияПерерыва = СтрокаПерерыва.EndTime;
		RowIndex = RowIndex + 1;
		
	EndDo;
	
	ClosingParameters = New Structure;
	ClosingParameters.Insert("CycleDayNumber", DayNumber);
	ClosingParameters.Insert("DateOfDay", DateOfDay);
	ClosingParameters.Insert("Periods", Periods);
	ClosingParameters.Insert("BeginTime", BeginTime);
	ClosingParameters.Insert("EndTime", FinishTimeForCalculation);
	ClosingParameters.Insert("TimeBreak", TimeBreak);
	ClosingParameters.Insert("WorkingHours", WorkHoursWithBreak);
	
	ThisForm.Close(ClosingParameters);
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtClient
Procedure ОбработкаИзмененияВремениПерерывов(ЭтоУдалениеСтроки = False, ЭтоИзменениеПериодаВперерывах = False)
	
	If ЭтоУдалениеСтроки Then
			Return;
	EndIf;
	
	If ЭтоИзменениеПериодаВперерывах And TimeBreak > WorkTimeInterval Then
		Return
	EndIf;
	
	If TimeBreak>=24 Then
		TimeBreak = WorkTimeInterval - WorkHoursWithBreak;
		Return;
	EndIf;
	
	If TimeBreak = 0 And WorkHoursWithBreak = 0 Then
		Return
	EndIf;
	
	If WorkTimeInterval - TimeBreak<0 Then
		
		WorkHoursWithBreak = WorkTimeInterval + (WorkTimeInterval - TimeBreak);
		TimeBreak = (WorkTimeInterval - TimeBreak) * -1;
		
		Return;
	ElsIf WorkTimeInterval - TimeBreak = 0 And Not ЭтоИзменениеПериодаВперерывах Then
		WorkHoursWithBreak = WorkTimeInterval;
		TimeBreak = 0;
		Return;
		
	EndIf;
	
	WorkHoursWithBreak = WorkTimeInterval - TimeBreak;
	TimeBreak = ?(WorkTimeInterval - TimeBreak<0,0, TimeBreak);
	
	BreakTimeError = ?(TimeBreak+WorkHoursWithBreak>WorkTimeInterval, True, False);
	
	
EndProcedure

&AtServer
Function ПериодыВПерерывы(TableOfPeriods)
	
	ТаблицаПерерывов = New ValueTable;
	ТаблицаПерерывов.Columns.Add("BeginTime");
	ТаблицаПерерывов.Columns.Add("EndTime");
	ТаблицаПерерывов.Columns.Add("LineNumber");
	
	PeriodsQuantity = TableOfPeriods.Count();
	
	If PeriodsQuantity = 0 Then
		
		Return ТаблицаПерерывов;
		
	ElsIf PeriodsQuantity = 1 Then
		
		BeginTime = TableOfPeriods[0].BeginTime;
		FinishTimeForCalculation = TableOfPeriods[0].EndTime;
		EndTime = ?(Not ValueIsFilled(FinishTimeForCalculation) And WorkHoursWithBreak = 24, Date(1,1,1, 23, 59, 0), FinishTimeForCalculation);
		
		TimeBreak = TableOfPeriods[0].BreakHours;
		
		Return ТаблицаПерерывов;
		
	ElsIf PeriodsQuantity > 1 Then
		
		BeginTime = TableOfPeriods[0].BeginTime;
		FinishTimeForCalculation = TableOfPeriods[PeriodsQuantity-1].EndTime;
		EndTime = ?(Not ValueIsFilled(FinishTimeForCalculation) And WorkHoursWithBreak = 24, Date(1,1,1, 23, 59, 0), FinishTimeForCalculation);
		
	EndIf;
	
	For LineNumber = 0 To PeriodsQuantity-1 Do
		
		TimeBeginPeriod = TableOfPeriods[LineNumber].EndTime;
		ВремяОкончанияПериода = TableOfPeriods[LineNumber+1].BeginTime;
		
		If TimeBeginPeriod = ВремяОкончанияПериода 
			Then
			
			If LineNumber+1 = PeriodsQuantity-1 Then 
				Break
			Else
				Continue
			EndIf;
			
		EndIf;
		
		NewRow = ТаблицаПерерывов.Add();
		NewRow.BeginTime = TimeBeginPeriod;
		NewRow.EndTime = ВремяОкончанияПериода;
		NewRow.LineNumber = LineNumber+1;
		
		If LineNumber+1 = PeriodsQuantity-1 Then Break EndIf;
		
	EndDo;
	
	Return ТаблицаПерерывов;
	
EndFunction

&AtServer
Procedure SetConditionalAppearance()
	
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Breaks.ОшибкаПериода", True, DataCompositionComparisonType.Equal);
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "BreaksBeginTime");
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "BreaksEndTime");
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.ExplanationTextError);
	
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "ОшибкаВремениПериода", True, DataCompositionComparisonType.Equal);
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "РасписаниеРаботыНачалоРабочегоДня");
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "РасписаниеРаботыОкончаниеРабочегоДня");
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.ExplanationTextError);
	
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "ОшибкаВремениПерерывов", True, DataCompositionComparisonType.Equal);
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "ЧасовРаботыСУчетомПерерывов");
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "TimeBreak");
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.ExplanationTextError);
	
EndProcedure

&AtClient
Function ПроверитьГраницыПерерывов()
	
	ClearMessages();
	
	If WorkHoursWithBreak = 0 Then
		
		Message = New UserMessage();
		Message.Text = NStr("en='Заполните часы работы.';ru='Заполните часы работы.';vi='Điền vào giờ làm việc.'");
		Message.Field = "ЧасовРаботыСУчетомПерерывов";
		Message.SetData(ThisForm);
		Message.Message();
		
		Return False;
		
	EndIf;
	
	If TimeBreak + WorkHoursWithBreak > 24 Then
		
		Message = New UserMessage();
		Message.Text = NStr("en='Сумма перерывов и часов работы больше 24 часов.';ru='Сумма перерывов и часов работы больше 24 часов.';vi='Thời gian nghỉ và giờ làm việc hơn 24 giờ.'");
		Message.Field = "ЧасовРаботыСУчетомПерерывов";
		Message.SetData(ThisForm);
		Message.Message();
		
		Return False;
		
	EndIf;
	
	If TimePeriodError Then
		
		Message = New UserMessage();
		Message.Text = NStr("en='Начало и окончание рабочего дня не могут совпадать.';ru='Начало и окончание рабочего дня не могут совпадать.';vi='Bắt đầu và kết thúc ngày làm việc không thể trùng nhau.'");
		Message.Field = "EndTime";
		Message.SetData(ThisForm);
		Message.Message();
		
		Return False;
		
	EndIf;
	
	For Each CheckedString In Breaks Do
		
		CurrentLineNumber = CheckedString.LineNumber;
		
		If CheckedString.ОшибкаПериода 
			Or (Not ValueIsFilled(CheckedString.BeginTime) And Not ValueIsFilled(CheckedString.EndTime)) Then
			
			Message = New UserMessage();
			Message.Text = NStr("en='Границы перерыва введены не верно.';ru='Границы перерыва введены не верно.';vi='Các ranh giới nghỉ không được nhập chính xác.'");
			Message.Field = "Breaks[" + String(CheckedString.LineNumber-1)+"]" + ".BeginTime";
			Message.SetData(ThisForm);
			Message.Message();
			
			Return False;
			
		EndIf;
		
		For Each СтрокаПерерывов In Breaks Do
			
			// Проверка на поглащенные перерывы
			If Not СтрокаПерерывов.LineNumber = CurrentLineNumber 
				And ValueIsFilled(CheckedString.EndTime) And ValueIsFilled(CheckedString.BeginTime) Then
				
				If ValueIsFilled(СтрокаПерерывов.EndTime) 
					And CheckedString.EndTime >= СтрокаПерерывов.EndTime
					And CheckedString.BeginTime <= СтрокаПерерывов.BeginTime Then
					
					Message = New UserMessage();
					Message.Text = NStr("en='Существует перерыв включенный в данный период.';ru='Существует перерыв включенный в данный период.';vi='Có một nghỉ bao gồm trong giai đoạn này.'");
					Message.Field = "Breaks[" + String(CheckedString.LineNumber-1)+"]" + ".EndTime";
					Message.SetData(ThisForm);
					Message.Message();
					Return False;
				EndIf;
				
				If CheckedString.EndTime <= СтрокаПерерывов.EndTime
					And CheckedString.BeginTime >= СтрокаПерерывов.BeginTime Then
					
					Message = New UserMessage();
					Message.Text = NStr("en='Данный период включен в другой перерыв.';ru='Данный период включен в другой перерыв.';vi='Khoảng thời gian này được bao gồm trong giờ nghỉ khác.'");
					Message.Field = "Breaks[" + String(CheckedString.LineNumber-1)+"]" + ".EndTime";
					Message.SetData(ThisForm);
					Message.Message();
					Return False;
				EndIf;
				
			EndIf;
			//--------------
			
			If Not СтрокаПерерывов.LineNumber = CurrentLineNumber And ValueIsFilled(CheckedString.BeginTime)
				And (CheckedString.BeginTime >= СтрокаПерерывов.BeginTime And CheckedString.BeginTime < СтрокаПерерывов.EndTime) Then
				
				Message = New UserMessage();
				Message.Text = NStr("en='Время окончания перерыва пересекается с периодом другого перерыва.';ru='Время окончания перерыва пересекается с периодом другого перерыва.';vi='Thời gian kết thúc của giờ nghỉ giao với thời gian nghỉ khác.'");
				Message.Field = "Breaks[" + String(CheckedString.LineNumber-1)+"]" + ".EndTime";
				Message.SetData(ThisForm);
				Message.Message();
				Return False;
			EndIf;
			
			If Not СтрокаПерерывов.LineNumber = CurrentLineNumber And ValueIsFilled(CheckedString.EndTime)
				And (CheckedString.EndTime <= СтрокаПерерывов.EndTime And CheckedString.EndTime > СтрокаПерерывов.BeginTime) Then
				
				Message = New UserMessage();
				Message.
				Message.Text = NStr("en='Время начала перерыва пересекается с периодом другого перерыва.';ru='Время начала перерыва пересекается с периодом другого перерыва.';vi='Thời gian bắt đầu của giờ nghỉ giao với thời gian nghỉ khác.'");
				Message.Field = "Breaks[" + String(CheckedString.LineNumber-1)+"]" + ".BeginTime";
				Message.SetData(ThisForm);
				Message.Message();
				Return False;
			EndIf;
			
			If ValueIsFilled(BeginTime) And Not ValueIsFilled(CheckedString.BeginTime)Then
				
				Message = New UserMessage();
				Message.Text = NStr("en='Задано начало раб. дня. Время начала перерыва не может быть пустым.';ru='Задано начало раб. дня. Время начала перерыва не может быть пустым.';vi='Bắt đầu ngày làm việc. Thời gian bắt đầu nghỉ không thể để trống.'");
				Message.Field = "Breaks[" + String(CheckedString.LineNumber-1)+"]" + ".BeginTime";
				Message.SetData(ThisForm);
				Message.Message();
				Return False;
			EndIf;
			
			If ValueIsFilled(FinishTimeForCalculation) And Not ValueIsFilled(CheckedString.EndTime)Then
				
				Message = New UserMessage();
				Message.Text = NStr("en='Задано окончание раб. дня. Время окончания перерыва не может быть пустым.';ru='Задано окончание раб. дня. Время окончания перерыва не может быть пустым.';vi='Bắt đầu ngày làm việc. Giờ giải lao không thể để trống.'");
				Message.Field = "Breaks[" + String(CheckedString.LineNumber-1)+"]" + ".EndTime";
				Message.SetData(ThisForm);
				Message.Message();
				Return False;
			EndIf;
			
			If ValueIsFilled(FinishTimeForCalculation) And FinishTimeForCalculation = CheckedString.EndTime Then
				
				Message = New UserMessage();
				Message.Text = NStr("en='Время окончания перерыва не может совпадать с окончанием рабочего дня.';ru='Время окончания перерыва не может совпадать с окончанием рабочего дня.';vi='Thời gian kết thúc của giờ nghỉ không thể trùng với thời điểm kết thúc ngày làm việc.'");
				Message.Field = "Breaks[" + String(CheckedString.LineNumber-1)+"]" + ".EndTime";
				Message.SetData(ThisForm);
				Message.Message();
				Return False;
			EndIf;
			
			If ValueIsFilled(BeginTime) And BeginTime = CheckedString.BeginTime Then
				
				Message = New UserMessage();
				Message.Text = NStr("en='Время начала перерыва не может совпадать с началом рабочего дня.';ru='Время начала перерыва не может совпадать с началом рабочего дня.';vi='Thời gian bắt đầu nghỉ không thể trùng với thời điểm bắt đầu ngày làm việc.'");
				Message.Field = "Breaks[" + String(CheckedString.LineNumber-1)+"]" + ".BeginTime";
				Message.SetData(ThisForm);
				Message.Message();
				Return False;
			EndIf;
			
			If ValueIsFilled(FinishTimeForCalculation) And FinishTimeForCalculation < CheckedString.EndTime Then
				
				Message = New UserMessage();
				Message.Text = NStr("en='Время окончания перерыва не может превышать окончание рабочего дня.';ru='Время окончания перерыва не может превышать окончание рабочего дня.';vi='Thời gian kết thúc nghỉ không thể vượt quá cuối ngày làm việc.'");
				Message.Field = "Breaks[" + String(CheckedString.LineNumber-1)+"]" + ".EndTime";
				Message.SetData(ThisForm);
				Message.Message();
				Return False;
			EndIf;
			
			If ValueIsFilled(BeginTime) And BeginTime > CheckedString.BeginTime Then
				
				Message = New UserMessage();
				Message.Text = NStr("en='Время начала перерыва не может быть меньше времени начала рабочего дня.';ru='Время начала перерыва не может быть меньше времени начала рабочего дня.';vi='Thời gian bắt đầu nghỉ không thể ít hơn thời gian bắt đầu của ngày làm việc.'");
				Message.Field = "Breaks[" + String(CheckedString.LineNumber-1)+"]" + ".BeginTime";
				Message.SetData(ThisForm);
				Message.Message();
				Return False;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Return True;
	
EndFunction

&AtClient
Procedure CalculateBreaksTimeAndFormDescription(ItBreakTimeStart = True)
	
	CurrentData = Items.Breaks.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	If Breaks.Count() Then
		
		ИтогДлительностиПерерывов = 0;
		ИтогДлительностиПерерывовСек = 0;
		ИтогДлительностьПерерывовСек = 0;
		
		For Each СтрокаПерерывов In Breaks Do
			
			If СтрокаПерерывов.BeginTime < СтрокаПерерывов.EndTime
				Or (ValueIsFilled(СтрокаПерерывов.BeginTime) And Not ValueIsFilled(СтрокаПерерывов.EndTime)) Then
				
				ДлительностьПерерываСек = СтрокаПерерывов.EndTime - СтрокаПерерывов.BeginTime;
				ДлительностьПерерываСек = ?(ДлительностьПерерываСек > 0, ДлительностьПерерываСек, 86400 + ДлительностьПерерываСек);
				
				ДлительностьПерерыва = Round(ДлительностьПерерываСек/3600, 2, RoundMode.Round15as20);
				СтрокаПерерывов.Duration = ?(ДлительностьПерерыва > 0, ДлительностьПерерыва, 24 + ДлительностьПерерыва);
				
				ИтогДлительностиПерерывов = ИтогДлительностиПерерывов + СтрокаПерерывов.Duration;
				ИтогДлительностьПерерывовСек = ИтогДлительностьПерерывовСек + ДлительностьПерерываСек;
				
			EndIf;
		EndDo;
		TimeBreak = ИтогДлительностиПерерывов;
		
	EndIf;
	
	ОбработкаИзмененияВремениПерерывов(,True);
	
EndProcedure

&AtClient
Procedure РасчитатьВремяПерерывовИСформироватьПредставлениеРасписанияПриОткрытии(ЭтоВремяНачалаПерерыва = True, FormOpening = False)
	
	If Breaks.Count() Then
		
		ИтогДлительностиПерерывов = 0;
		
		For Each СтрокаПерерывов In Breaks Do
			
			//Если Не ЗначениеЗаполнено(СтрокаПерерывов.ВремяНачала) или Не ЗначениеЗаполнено(СтрокаПерерывов.ВремяОкончания) Тогда
			//	Продолжить
			//КонецЕсли;
			
			If СтрокаПерерывов.BeginTime < СтрокаПерерывов.EndTime
				Or (ValueIsFilled(СтрокаПерерывов.BeginTime) And Not ValueIsFilled(СтрокаПерерывов.EndTime)) Then
				
				ДлительностьПерерыва = Round((СтрокаПерерывов.EndTime - СтрокаПерерывов.BeginTime)/3600, 2, RoundMode.Round15as20);
				СтрокаПерерывов.Duration = ?(ДлительностьПерерыва > 0, ДлительностьПерерыва, 24 + ДлительностьПерерыва);
				
				ИтогДлительностиПерерывов = ИтогДлительностиПерерывов + СтрокаПерерывов.Duration;
				
			EndIf;
		EndDo;
		
		TimeBreak = ИтогДлительностиПерерывов;
	EndIf;
	
	WorkTimeInterval = WorkHoursWithBreak + TimeBreak;
	
EndProcedure

&AtClient
Procedure ОбработатьИзменениеПериодаРабочегоДня(ЭтоВремяНачала = True)
	
	If Not ValueIsFilled(BeginTime) And Not ValueIsFilled(FinishTimeForCalculation)
		And Not EndTime = Date(1,1,1,23,59,0) Then
		WorkHoursWithBreak = 0;
		WorkTimeInterval = 24 - TimeBreak;
		Return;
	EndIf;
	
	If ValueIsFilled(BeginTime) And ValueIsFilled(FinishTimeForCalculation) Then
		If FinishTimeForCalculation < BeginTime Or BeginTime > FinishTimeForCalculation Then
			FinishTimeForCalculation = BeginTime;
			EndTime = ?(Not ValueIsFilled(FinishTimeForCalculation) And WorkHoursWithBreak = 24, Date(1,1,1, 23, 59, 0), FinishTimeForCalculation);
		EndIf
	EndIf;
		
	ЧасовРаботыСУчетомПерерывовРасчет = Round((FinishTimeForCalculation-BeginTime)/60/60, 2, RoundMode.Round15as20);
	
	ЧасовРаботыСУчетомПерерывовРасчет = ?(ЧасовРаботыСУчетомПерерывовРасчет > 0, ЧасовРаботыСУчетомПерерывовРасчет, 24 + ЧасовРаботыСУчетомПерерывовРасчет );
	
	WorkHoursWithBreak = ЧасовРаботыСУчетомПерерывовРасчет;
	
	If ValueIsFilled(BeginTime) Or ValueIsFilled(FinishTimeForCalculation) Then
		WorkHoursWithBreak = ?(WorkHoursWithBreak > 0, WorkHoursWithBreak - TimeBreak
		, 24 + WorkHoursWithBreak - TimeBreak);
		
		If WorkHoursWithBreak < 0 Then
			If ЭтоВремяНачала Then
				BeginTime = BeginTime + (WorkHoursWithBreak*3600)
			Else
				FinishTimeForCalculation = FinishTimeForCalculation - (WorkHoursWithBreak*3600);
				EndTime = ?(Not ValueIsFilled(FinishTimeForCalculation) And WorkHoursWithBreak = 24, Date(1,1,1, 23, 59, 0), FinishTimeForCalculation);
			EndIf;
			
			WorkHoursWithBreak = 0;
		EndIf;
		
	Else
		WorkHoursWithBreak = 24 - TimeBreak;
	EndIf;
	
	If (ValueIsFilled(FinishTimeForCalculation) Or ValueIsFilled(BeginTime))
		And BeginTime = EndTime Then
		WorkHoursWithBreak = 0;
	EndIf;
	
	WorkTimeInterval = WorkHoursWithBreak + TimeBreak;
	
EndProcedure

&AtClient
Procedure ПроверитьГраницыПерерывовПриИзмниненииПериодаРабочегоДня(ЭтоВремяНачала = True)
	
	ClearMessages();
	
	TimePeriodError = ?(ValueIsFilled(FinishTimeForCalculation) And ValueIsFilled(BeginTime)
	And FinishTimeForCalculation = BeginTime, True, False);
	
	If (Not ValueIsFilled(BeginTime) And Not ValueIsFilled(FinishTimeForCalculation))
		Or Not Breaks.Count() Then
		Return
	EndIf;
	
	ОшибкаПериода = False;
	
	If ЭтоВремяНачала And ValueIsFilled(BeginTime) Then
		
		LineNumber = 1;
		
		For Each СтрокаПерерывов In Breaks Do
			
			If BeginTime > СтрокаПерерывов.BeginTime Then
				
				Message = New UserMessage();
				Message.Text = NStr("en='Время начала рабочего дня больше времени начала перерыва';ru='Время начала рабочего дня больше времени начала перерыва';vi='Thời gian bắt đầu của ngày làm việc dài hơn thời gian bắt đầu nghỉ'");
				Message.Field = "Breaks[" + String(LineNumber-1)+"]" + ".BeginTime";
				Message.SetData(ThisForm);
				Message.Message();
				
				BeginTime = СтрокаПерерывов.BeginTime;
				
			EndIf;
			
			LineNumber = LineNumber + 1;
			
		EndDo;
	EndIf;
	
	If Not ЭтоВремяНачала And ValueIsFilled(FinishTimeForCalculation) Then
		
		LineNumber = 1;
		
		For Each СтрокаПерерывов In Breaks Do
			
			If FinishTimeForCalculation < СтрокаПерерывов.EndTime Then
				
				Message = New UserMessage();
				Message.Text = NStr("en='Время окончания рабочего дня меньше времени окончания перерыва';ru='Время окончания рабочего дня меньше времени окончания перерыва';vi='Thời gian kết thúc ngày làm việc ít hơn thời gian kết thúc của giờ nghỉ'");
				Message.Field = "Breaks[" + String(LineNumber-1)+"]" + ".EndTime";
				Message.SetData(ThisForm);
				Message.Message();
				
				FinishTimeForCalculation = СтрокаПерерывов.EndTime;
				EndTime = ?(Not ValueIsFilled(FinishTimeForCalculation) And WorkHoursWithBreak = 24, Date(1,1,1, 23, 59, 0), FinishTimeForCalculation);
				
			EndIf;
			
			LineNumber = LineNumber + 1;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Function ПараметрыДнейСовпадают(ListDays, Val ChangedDays, Val GraphPeriods, MapTransferedDataGraphs = Undefined)
	
	НетОшибокИнтервала = True;
	НетОшибокНачалаИнтервала = True;
	НетОшибокОкончанияИнтервала = True;
	НетОшибокВремениРабДня = True;
	НетОшибокИнтерваловПерерывов = True;
	НетОшибокДлительностиПерерывов = True;
	
	ЭтоФормаВводаОтклонений = ?(MapTransferedDataGraphs = Undefined, False, True);
	
	ChangedDays.Sort("DateOfDay Asc, BeginTime Asc");
	GraphPeriods.Sort("CycleDayNumber Asc, BeginTime Asc");
	
	СоответствиеПараметровПоДням = New Map;
	
	ДлительностьПерерывовТекДня = 25;
	КоличествоПерерывов = -1;
	
	ПоследнийДеньСписка = Undefined;
	ТаблицаПерерывов = New ValueTable;
	
	ИндексДняСписка = 1;
	
	ВремяНачалаЭталон = Date(1,1,1);
	ВремяОкончанияЭталон = Date(1,1,1);
	
	СтруктураШапки = СтруктураШапкиДня();
	
	WorkHours = 0;
	
	For Each ListElement In ListDays Do
		
		ParameterTable = New ValueTable;
		ParameterTable.Columns.Add("DateOfDay");
		ParameterTable.Columns.Add("BeginTime");
		ParameterTable.Columns.Add("EndTime");
		ParameterTable.Columns.Add("Duration");
		
		If ListElement.Check Then
			
			ДлительностьПерерывовПредДня = ДлительностьПерерывовТекДня;
			КоличествоПериодовПредДень = КоличествоПерерывов;
			
			КоличествоПерерывов = 0;
			СуммаПерерывов = 0;
			РабочихЧасовЗаДень = 0;
			
			FilterParameters = New Structure("DateOfDay",ListElement.Value);
			ИзмененныйПериод_Строки = ChangedDays.FindRows(FilterParameters);
			
			ТабИзмененныеДни = ChangedDays.Unload(ИзмененныйПериод_Строки);
			
			СтруктураШапки = СтруктураШапкиДня(ТабИзмененныеДни);
			РабочихЧасовЗаДень = СтруктураШапки.WorkingHours;
			
			If ИзмененныйПериод_Строки.Count() Then 
				
				If ИндексДняСписка = 1 Then
					ВремяНачалаЭталон = ИзмененныйПериод_Строки[0].BeginTime;
					ВремяОкончанияЭталон = ИзмененныйПериод_Строки[ИзмененныйПериод_Строки.Count()-1].EndTime;
				EndIf;
				
				ТаблицаПерерывов = ПериодыВПерерывы(ТабИзмененныеДни);
				
				For Each PeriodString In ТаблицаПерерывов Do
					NewRow = ParameterTable.Add();
					FillPropertyValues(NewRow, PeriodString);
					NewRow.DateOfDay = ListElement.Value;
					СуммаПерерывов = СуммаПерерывов + (NewRow.EndTime-NewRow.BeginTime)/3600;
				EndDo;
				
				КоличествоПерерывов = ParameterTable.Count();
				
				If СуммаПерерывов = 0
					And (ValueIsFilled(BeginTime)
					Or ValueIsFilled(FinishTimeForCalculation)) Then
					
					Duration = Round((FinishTimeForCalculation -BeginTime)/3600, 2, RoundMode.Round15as20);
					СуммаПерерывов = ?(Duration < 0, 24 + Duration, Duration);
					
				EndIf;
				
			EndIf;
			
			ДлительностьПерерывовТекДня = СуммаПерерывов;
			
		Else
			
			ДлительностьПерерывовПредДня = ДлительностьПерерывовТекДня;
			КоличествоПериодовПредДень = КоличествоПерерывов;
			
			DayNumber = Number(ListElement.Presentation);
			
			КоличествоПерерывов = 0;
			СуммаПерерывов = 0;
			
			FilterParameters = New Structure();
			FilterParameters.Insert("CycleDayNumber",DayNumber);
			
			If ЭтоФормаВводаОтклонений Then
				FilterParameters.Insert("WorkSchedule",MapTransferedDataGraphs.Get(ListElement.Value));
			EndIf;
			
			СтрокиПериодов = GraphPeriods.FindRows(FilterParameters);
			
			ТабПериодыГрафика = GraphPeriods.Unload(СтрокиПериодов);
			
			СтруктураШапки = СтруктураШапкиДня(ТабПериодыГрафика);
			РабочихЧасовЗаДень = СтруктураШапки.WorkingHours;
			
			If СтрокиПериодов.Count() Then
				
				ТаблицаПерерывов = ПериодыВПерерывы(ТабПериодыГрафика);
				
				If ИндексДняСписка = 1 Then
					ВремяНачалаЭталон = СтрокиПериодов[0].BeginTime;
					ВремяОкончанияЭталон = СтрокиПериодов[СтрокиПериодов.Count()-1].EndTime;
				EndIf;
			
				For Each PeriodString In ТаблицаПерерывов Do
					NewRow = ParameterTable.Add();
					FillPropertyValues(NewRow, PeriodString);
					NewRow.DateOfDay = ListElement.Value;
					СуммаПерерывов = СуммаПерерывов + (NewRow.EndTime-NewRow.BeginTime)/3600;
				EndDo;
				
				If СуммаПерерывов = 0
					And (ValueIsFilled(BeginTime) 
					Or ValueIsFilled(FinishTimeForCalculation)) Then
					
					Duration = Round((FinishTimeForCalculation -BeginTime)/3600, 2, RoundMode.Round15as20);
					СуммаПерерывов = ?(Duration < 0, 24 + Duration, Duration);
					
				EndIf;
				
				КоличествоПерерывов = ParameterTable.Count();
				
			EndIf;
			
			ДлительностьПерерывовТекДня = СуммаПерерывов;
			
		EndIf;
		
		If (ДлительностьПерерывовПредДня < 25 And Not ДлительностьПерерывовПредДня = ДлительностьПерерывовТекДня) 
			Or (КоличествоПериодовПредДень > 0 And Not КоличествоПериодовПредДень = КоличествоПерерывов) Then
			НетОшибокДлительностиПерерывов = False;
		EndIf;
		
		If Not СтруктураШапки.BeginTime = ВремяНачалаЭталон Or Not СтруктураШапки.EndTime = ВремяОкончанияЭталон Then
			
			НетОшибокНачалаИнтервала = ?(Not СтруктураШапки.BeginTime = ВремяНачалаЭталон, False, True);
			НетОшибокОкончанияИнтервала = ?(Not СтруктураШапки.EndTime = ВремяОкончанияЭталон, False, True);
			
			НетОшибокИнтервала = False;
			
		EndIf;
		
		ParameterTable.Sort("BeginTime Asc");
		СоответствиеПараметровПоДням.Insert(ListElement.Value,ParameterTable);
		
		ПоследнийДеньСписка = ListElement.Value;
		
		WorkHours = WorkHours + РабочихЧасовЗаДень;
		
		If Not WorkHours/ИндексДняСписка = РабочихЧасовЗаДень Then
			НетОшибокВремениРабДня = False
		EndIf;
		
		ИндексДняСписка = ИндексДняСписка + 1;
		
	EndDo;
	
	If НетОшибокДлительностиПерерывов Then
		
		FoundValue = ListDays.FindByValue(ПоследнийДеньСписка);
		
		ListDays.Delete(FoundValue);
		
		ТабЗначенийПерерывыПервыйДень = СоответствиеПараметровПоДням.Get(ПоследнийДеньСписка);
		КоличествоПерерывовПервыйДень = ТабЗначенийПерерывыПервыйДень.Count();
		
		For Each ListElement In ListDays Do
			
			ТабЗначенийПерерывыТекущийДень = СоответствиеПараметровПоДням.Get(ListElement.Value);
			
			If Not КоличествоПерерывовПервыйДень = ТабЗначенийПерерывыТекущийДень.Count() Then
				НетОшибокИнтерваловПерерывов = False;
				Break;
			EndIf;
			
			ИндексСтрокиПервойТаблицы = 0;
			
			For Each TableRow In ТабЗначенийПерерывыТекущийДень Do
				
				If Not TableRow.BeginTime = ТабЗначенийПерерывыПервыйДень[ИндексСтрокиПервойТаблицы].BeginTime
					Or Not TableRow.EndTime = ТабЗначенийПерерывыПервыйДень[ИндексСтрокиПервойТаблицы].EndTime Then
					НетОшибокИнтерваловПерерывов = False;
					Break;
				EndIf;
				
				ИндексСтрокиПервойТаблицы = ИндексСтрокиПервойТаблицы + 1;
			EndDo;
			
		EndDo;
	Else
		НетОшибокИнтерваловПерерывов = False;
	EndIf;
	
	If НетОшибокВремениРабДня And НетОшибокДлительностиПерерывов
		And НетОшибокИнтервала And НетОшибокИнтерваловПерерывов Then
		
		Breaks.Load(ТаблицаПерерывов);
		Return True;
		
	EndIf;
	
	If Not НетОшибокДлительностиПерерывов Then TimeBreak = 0 EndIf;
	If Not НетОшибокВремениРабДня Then WorkHoursWithBreak = 0 EndIf;
	
	BeginTime = ?(НетОшибокНачалаИнтервала, ВремяНачалаЭталон, Date(1,1,1));
	EndTime = ?(НетОшибокОкончанияИнтервала, ВремяОкончанияЭталон, Date(1,1,1));
	
	If НетОшибокИнтерваловПерерывов Then
		Breaks.Load(ТаблицаПерерывов);
	EndIf;
	
	Return False;
	
EndFunction

&AtServer
Function СтруктураШапкиДня(TableOfPeriods = Undefined)
	
	СтруктураДня = New Structure("BeginTime, EndTime, WorkingHours");
	
	If TableOfPeriods = Undefined Or Not TableOfPeriods.Count() Then
		
		СтруктураДня.WorkingHours = 0;
		СтруктураДня.BeginTime = Date(1,1,1);
		СтруктураДня.EndTime = Date(1,1,1);
		
		Return СтруктураДня;
		
	EndIf;
	
	WorkingHours = 0;
	
	For Each TabRow In TableOfPeriods Do
		WorkingHours = WorkingHours + TabRow.Duration;
	EndDo;
	
	СтруктураДня.WorkingHours = WorkingHours;
	СтруктураДня.BeginTime = TableOfPeriods[0].BeginTime;
	СтруктураДня.EndTime = TableOfPeriods[TableOfPeriods.Count()-1].EndTime;
	
	Return СтруктураДня;
	
EndFunction

&AtClient
Procedure ПриИзмененииЧасовРаботы()
	
	If WorkHoursWithBreak = 24 Then
		BeginTime = Date(1,1,1);
		EndTime = Date(1,1,1,23,59,0);
		FinishTimeForCalculation = Date(1,1,1);
	EndIf;
	
	If WorkHoursWithBreak>24 - TimeBreak Then
		WorkHoursWithBreak = 24 - TimeBreak;
	EndIf;
	
	If WorkHoursWithBreak = 0 Then
		BeginTime = Date(1,1,1);
		FinishTimeForCalculation = Date(1,1,1);
		EndTime = FinishTimeForCalculation;
		Return;
	EndIf;
	
	If ValueIsFilled(BeginTime) Then
		ДоступныхЧасов =86400+(Date(1,1,1) - BeginTime) - TimeBreak*3600;
	Else
		ДоступныхЧасов = 86400 - TimeBreak*3600;
	EndIf;
	
	BeginTime = ?(Not ValueIsFilled(BeginTime), Date(1,1,1,8,0,0), BeginTime);
	
	TimeBeginSec = (Date(1,1,1) - BeginTime)*-1;
	
	ВремяОкончанияДляРасчетовСек = 86400 - (TimeBeginSec + (WorkHoursWithBreak+TimeBreak)*3600);
	
	If ВремяОкончанияДляРасчетовСек < 0 Then
		EndTime = Date(1,1,1,23,59,0);
		BeginTime = Date(1,1,1) + (TimeBeginSec + ВремяОкончанияДляРасчетовСек);
		FinishTimeForCalculation = Date(1,1,1);
	Else
		EndTime = Date(1,1,1)+TimeBeginSec + (WorkHoursWithBreak+TimeBreak)*3600;
		FinishTimeForCalculation = EndTime;
		If EndTime = Date(1,1,1) Then
			EndTime = Date(1,1,1,23,59,0);
			FinishTimeForCalculation = Date(1,1,1);
		EndIf;
	EndIf;
	
	TimePeriodError = ?(ValueIsFilled(FinishTimeForCalculation) And ValueIsFilled(BeginTime)
	And FinishTimeForCalculation = BeginTime, True, False);
	
	WorkTimeInterval = WorkHoursWithBreak + TimeBreak;
	
	BreakTimeError = ?(TimeBreak+WorkHoursWithBreak>24, True, False);
	
EndProcedure;

#EndRegion





