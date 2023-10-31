
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("BeginTime") Then
		BeginTime = Parameters.BeginTime;
	EndIf;
	If Parameters.Property("EndTime") Then
		EndTime= Parameters.EndTime;
	EndIf;
	If Parameters.Property("Breaks") Then
		Breaks.Load(Parameters.Breaks.Unload());
	EndIf;
	If Parameters.Property("TimeBreak") Then
		TimeBreak= Parameters.TimeBreak;
	EndIf;
	If Parameters.Property("DayNumber") Then
		DayNumber = Parameters.DayNumber;
	EndIf;
	If Parameters.Property("WorkingHours") Then
		WorkHoursWithBreaks = Parameters.WorkingHours;
	EndIf;
	
	WorkHoursInterval = WorkHoursWithBreaks + TimeBreak;
	
	If (ValueIsFilled(BeginTime) Or ValueIsFilled(EndTime)) 
		Or ValueIsFilled(Parameters.WorkingHours) Then
		
		СтрокаВремяНачала = ?(ValueIsFilled(BeginTime),Format(BeginTime,"DF=HH:mm"), "00:00");
		СтрокаВремяОкончания = ?(ValueIsFilled(EndTime),Format(EndTime,"DF=HH:mm"), "24:00");
		
		Items.LabelWorkTime.Title = "Working time: " + СтрокаВремяНачала + "-" + СтрокаВремяОкончания;
		Items.WorkHoursWithBreaks.ReadOnly = True;
	Else
		Items.LabelWorkTime.Title = NStr("en='Working time: <not specified>';vi='Thời gian làm việc: <không xác định>'");
	EndIf;
	
	Items.TimeBreak.ReadOnly = Breaks.Count();
	
EndProcedure

#EndRegion

#Region FormItemEventsHandlers

&AtClient
Procedure РасписаниеРаботыОкончаниеРабочегоДняПриИзменении(Item)
	
	ОбработатьИзменениеПериодаРабочегоДня(False);
	ПроверитьГраницыПерерывовПриИзмниненииПериодаРабочегоДня(False);
	
EndProcedure

&AtClient
Procedure РасписаниеРаботыНачалоРабочегоДняПриИзменении(Item)
	
	ОбработатьИзменениеПериодаРабочегоДня();
	ПроверитьГраницыПерерывовПриИзмниненииПериодаРабочегоДня();
	
EndProcedure

&AtClient
Procedure TimeBreakOnChange(Item)
	
	ОбработкаИзмененияВремениПерерывов();
	
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
	
	РасчитатьВремяПерерывовИСформироватьПредставлениеРасписания();
	
	ErrorBreakTime = ?(TimeBreak+WorkHoursWithBreaks>WorkHoursInterval, True, False);
	
EndProcedure

&AtClient
Procedure BreaksEndTimeOnChange(Item)
	
	CurrentData = Items.Breaks.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	
	If ValueIsFilled(EndTime) And CurrentData.EndTime > EndTime Then
		CurrentData.EndTime = EndTime;
	EndIf;
	
	If ValueIsFilled(BeginTime) And ValueIsFilled(EndTime)
		And CurrentData.EndTime < BeginTime Then
		CurrentData.EndTime = BeginTime;
	EndIf;
	
	If ValueIsFilled(CurrentData.BeginTime) And ValueIsFilled(CurrentData.EndTime) 
		And CurrentData.EndTime <= CurrentData.BeginTime Then
		CurrentData.ОшибкаПериода = True;
	Else
		CurrentData.ОшибкаПериода = False;
	EndIf;
	
	РасчитатьВремяПерерывовИСформироватьПредставлениеРасписания(False);
	
	ErrorBreakTime = ?(TimeBreak+WorkHoursWithBreaks>WorkHoursInterval, True, False);
	
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

&AtClient
Procedure BreaksAfterDeleteRow(Item)
	If Not Breaks.Count() Then
		TimeBreak = 0;
		WorkHoursWithBreaks = WorkHoursInterval;
		If ValueIsFilled(BeginTime) Or ValueIsFilled(EndTime) Then
			ОбработатьИзменениеПериодаРабочегоДня();
		EndIf;
	EndIf;
	
	ErrorBreakTime = ?(WorkHoursWithBreaks + TimeBreak > WorkHoursInterval, True, False);

EndProcedure

&AtClient
Procedure BreaksBeforeDeleteRow(Item, Cancel)
	
	CurrentData = Items.Breaks.CurrentData;
	
	If CurrentData = Undefined Then Return EndIf;
	
	TimeBreak = TimeBreak - CurrentData.Duration;
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure ПеренестиВСправочник(Command)
	
	If Not ПроверитьГраницыПерерывов() Then Return EndIf;
	
	Breaks.Sort("BeginTime");
	
	Periods.Clear();
	
	ПоследнееВремяОкончанияПерерыва = Date(1,1,1);
	КоличествоПерерывов = Breaks.Count();
	RowIndex = 1;
	
	If Not Breaks.Count()
		And (ValueIsFilled(BeginTime) Or ValueIsFilled(EndTime)) Then
		
		NewRow = Periods.Add();
		NewRow.CycleDayNumber = DayNumber;
		
		NewRow.BeginTime = BeginTime;
		NewRow.EndTime = EndTime;
		
	EndIf;
	
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
				NewRow.EndTime = EndTime;
				
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
			NewRow.EndTime = EndTime;
			
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
	ClosingParameters.Insert("BeginTime", BeginTime);
	ClosingParameters.Insert("EndTime", EndTime);
	ClosingParameters.Insert("TimeBreak", TimeBreak);
	ClosingParameters.Insert("Breaks", Breaks);
	ClosingParameters.Insert("Periods", Periods);
	ClosingParameters.Insert("WorkHours", WorkHoursWithBreaks);
	
	ThisForm.Close(ClosingParameters);
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtClient
Procedure ОбработкаИзмененияВремениПерерывов(ЭтоИзменениеПериодаВперерывах = False)
	
	If ЭтоИзменениеПериодаВперерывах And TimeBreak > WorkHoursInterval Then
		Return
	EndIf;
	
	If TimeBreak>=24 Then
		TimeBreak = WorkHoursInterval - WorkHoursWithBreaks;
		Return;
	EndIf;
	
	If TimeBreak = 0 And WorkHoursWithBreaks = 0 Then
		Return
	EndIf;
	
	If WorkHoursInterval - TimeBreak<0 Then
		
		WorkHoursWithBreaks = WorkHoursInterval + (WorkHoursInterval - TimeBreak);
		TimeBreak = (WorkHoursInterval - TimeBreak) * -1;
		
		Return;
	ElsIf WorkHoursInterval - TimeBreak = 0 Then
		WorkHoursWithBreaks = WorkHoursInterval;
		TimeBreak = 0;
		Return;
		
	EndIf;
	
	WorkHoursWithBreaks = WorkHoursInterval - TimeBreak;
	TimeBreak = ?(WorkHoursInterval - TimeBreak<0,0, TimeBreak);
	
	ErrorBreakTime = ?(TimeBreak+WorkHoursWithBreaks>WorkHoursInterval, True, False);
	
EndProcedure


&AtServer
Procedure SetConditionalAppearance()

		NewConditionalAppearance = ConditionalAppearance.Items.Add();
		WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Breaks.PeriodError", True, DataCompositionComparisonType.Equal);
		WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, "BreaksBeginTime");
		WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, "BreaksEndTime");
		WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.ExplanationTextError);
		
		NewConditionalAppearance = ConditionalAppearance.Items.Add();
		WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "ОшибкаВремениПерерывов", True, DataCompositionComparisonType.Equal);
		WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, "ЧасовРаботыСУчетомПерерывов");
		WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, "TimeBreak");
		WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.ExplanationTextError);
		
		NewConditionalAppearance = ConditionalAppearance.Items.Add();
		WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "ОшибкаВремениПериода", True, DataCompositionComparisonType.Equal);
		WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, "РасписаниеРаботыНачалоРабочегоДня");
		WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, "РасписаниеРаботыОкончаниеРабочегоДня");
		WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.ExplanationTextError);

EndProcedure

&AtClient
Function ПроверитьГраницыПерерывов()
	
	If WorkHoursWithBreaks = 0 Then
		
		Message = New UserMessage();
		Message.Text = NStr("en='Заполните часы работы.';ru='Заполните часы работы.';vi='Điền vào giờ làm việc.'");
		Message.Field = "ЧасовРаботыСУчетомПерерывов";
		Message.SetData(ThisForm);
		Message.Message();
		
		Return False;
		
	EndIf;
	
	If TimeBreak + WorkHoursWithBreaks > 24 Then
		
		Message = New UserMessage();
		Message.Text = NStr("en='Сумма перерывов и часов работы больше 24 часов.';ru='Сумма перерывов и часов работы больше 24 часов.';vi='Thời gian nghỉ và giờ làm việc hơn 24 giờ.'");
		Message.Field = "ЧасовРаботыСУчетомПерерывов";
		Message.SetData(ThisForm);
		Message.Message();
		
		Return False;
		
	EndIf;
	
	If ErrorPeriodTime Then
		
		Message = New UserMessage();
		Message.Text = NStr("en='Начало и окончание рабочего дня не могут совпадать.';ru='Начало и окончание рабочего дня не могут совпадать.';vi='Bắt đầu và kết thúc ngày làm việc không thể trùng nhau.'");
		Message.Field = "EndTime";
		Message.SetData(ThisForm);
		Message.Message();
		
		Return False;
		
	EndIf;
	
	For Each CheckedString In Breaks Do
		
		ПроверяемаяСтрокаВремяОкончания = ?(Not ValueIsFilled(CheckedString.EndTime), Date(1,1,1,23,59,0), CheckedString.EndTime);
		
		CurrentLineNumber = CheckedString.LineNumber;
		
		If CheckedString.ОшибкаПериода 
			Or (Not ValueIsFilled(CheckedString.BeginTime) And Not ValueIsFilled(ПроверяемаяСтрокаВремяОкончания)) Then
			
			Message = New UserMessage();
			Message.Text = NStr("en='Границы перерыва введены не верно.';ru='Границы перерыва введены не верно.';vi='Các ranh giới nghỉ không được nhập chính xác.'");
			Message.Field = "Breaks[" + String(CheckedString.LineNumber-1)+"]" + ".BeginTime";
			Message.SetData(ThisForm);
			Message.Message();
			
			Return False;
			
		EndIf;
		
		For Each СтрокаПерерывов In Breaks Do
			
			ПроверяемаяСтрокаВремяОкончания = ?(Not ValueIsFilled(CheckedString.EndTime), Date(1,1,1,23,59,0), CheckedString.EndTime);
			СтрокаПерерывовВремяОкончания = ?(Not ValueIsFilled(СтрокаПерерывов.EndTime), Date(1,1,1,23,59,0), СтрокаПерерывов.EndTime);
			
			// Проверка на поглащенные перерывы
			If Not СтрокаПерерывов.LineNumber = CurrentLineNumber 
				And ValueIsFilled(ПроверяемаяСтрокаВремяОкончания) And ValueIsFilled(CheckedString.BeginTime) Then
				
				If ValueIsFilled(СтрокаПерерывовВремяОкончания) 
					And ПроверяемаяСтрокаВремяОкончания >= СтрокаПерерывовВремяОкончания
					And CheckedString.BeginTime <= СтрокаПерерывов.BeginTime Then
					
					Message = New UserMessage();
					Message.Text = NStr("en='Существует перерыв включенный в данный период.';ru='Существует перерыв включенный в данный период.';vi='Có một nghỉ bao gồm trong giai đoạn này.'");
					Message.Field = "Breaks[" + String(CheckedString.LineNumber-1)+"]" + ".EndTime";
					Message.SetData(ThisForm);
					Message.Message();
					Return False;
				EndIf;
				
				If ПроверяемаяСтрокаВремяОкончания <= СтрокаПерерывовВремяОкончания
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
				And (CheckedString.BeginTime >= СтрокаПерерывов.BeginTime And CheckedString.BeginTime < СтрокаПерерывовВремяОкончания) Then
				
				Message = New UserMessage();
				Message.Text = NStr("en='Время окончания перерыва пересекается с периодом другого перерыва.';ru='Время окончания перерыва пересекается с периодом другого перерыва.';vi='Thời gian kết thúc của giờ nghỉ giao với thời gian nghỉ khác.'");
				Message.Field = "Breaks[" + String(CheckedString.LineNumber-1)+"]" + ".EndTime";
				Message.SetData(ThisForm);
				Message.Message();
				Return False;
			EndIf;
			
			If Not СтрокаПерерывов.LineNumber = CurrentLineNumber And ValueIsFilled(ПроверяемаяСтрокаВремяОкончания)
				And (ПроверяемаяСтрокаВремяОкончания <= СтрокаПерерывовВремяОкончания And ПроверяемаяСтрокаВремяОкончания > СтрокаПерерывов.BeginTime) Then
				
				Message = New UserMessage();
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
			
			If ValueIsFilled(EndTime) And Not ValueIsFilled(ПроверяемаяСтрокаВремяОкончания)Then
				
				Message = New UserMessage();
				Message.Text = NStr("en='Задано окончание раб. дня. Время окончания перерыва не может быть пустым.';ru='Задано окончание раб. дня. Время окончания перерыва не может быть пустым.';vi='Bắt đầu ngày làm việc. Giờ giải lao không thể để trống.'");
				Message.Field = "Breaks[" + String(CheckedString.LineNumber-1)+"]" + ".EndTime";
				Message.SetData(ThisForm);
				Message.Message();
				Return False;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Return True;
	
EndFunction

&AtClient
Procedure РасчитатьВремяПерерывовИСформироватьПредставлениеРасписания(ЭтоВремяНачалаПерерыва = True)
	
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
	
	ОбработкаИзмененияВремениПерерывов(True);
	
EndProcedure

&AtClient
Procedure ОбработатьИзменениеПериодаРабочегоДня(ЭтоВремяНачала = True)
	
	If ValueIsFilled(BeginTime) And ValueIsFilled(EndTime) Then
		If EndTime < BeginTime Or BeginTime > EndTime Then
			EndTime = BeginTime;
		EndIf
	EndIf;
		
	WorkingHours = Round((EndTime-BeginTime)/60/60, 2, RoundMode.Round15as20);
	
	If ValueIsFilled(BeginTime) Or ValueIsFilled(EndTime) Then
		WorkingHours = ?(WorkingHours > 0, WorkingHours - TimeBreak
		, 24 + WorkingHours - TimeBreak);
		
		If WorkingHours < 0 Then
			If ЭтоВремяНачала Then
				BeginTime = BeginTime + (WorkingHours*3600)
			Else
				EndTime = EndTime - (WorkingHours*3600);
			EndIf;
			
			WorkingHours = 0;
		EndIf;
	EndIf;
	
	WorkHoursWithBreaks = WorkingHours;
	
	If (ValueIsFilled(EndTime) Or ValueIsFilled(BeginTime))
		And BeginTime = EndTime Then
		WorkHoursWithBreaks = 0;
	EndIf;
	
EndProcedure

&AtClient
Procedure ПроверитьГраницыПерерывовПриИзмниненииПериодаРабочегоДня(ЭтоВремяНачала = True)
	
	ErrorPeriodTime = ?(ValueIsFilled(EndTime) And ValueIsFilled(BeginTime)
	And EndTime = BeginTime, True, False);
	
	If (Not ValueIsFilled(BeginTime) And Not ValueIsFilled(EndTime))
		Or Not Breaks.Count() Then
		Return
	EndIf;
	
	If ЭтоВремяНачала And ValueIsFilled(BeginTime) Then
		
		LineNumber = 1;
		
		For Each СтрокаПерерывов In Breaks Do
			
			If BeginTime > СтрокаПерерывов.BeginTime Then
				
				Message = New UserMessage();
				Message.Text = NStr("en='Время начала рабочего дня больше времени начала перерыва.';ru='Время начала рабочего дня больше времени начала перерыва.';vi='Thời gian bắt đầu của ngày làm việc dài hơn thời gian bắt đầu nghỉ.'");
				Message.Field = "Breaks[" + String(LineNumber-1)+"]" + ".BeginTime";
				Message.SetData(ThisForm);
				Message.Message();
				
				BeginTime = СтрокаПерерывов.BeginTime;
				
			EndIf;
			
			LineNumber = LineNumber + 1;
			
		EndDo;
	EndIf;
	
	If Not ЭтоВремяНачала And ValueIsFilled(EndTime) Then
		
		LineNumber = 1;
		
		For Each СтрокаПерерывов In Breaks Do
			
			If EndTime < СтрокаПерерывов.EndTime Then
				
				Message = New UserMessage();
				Message.Text = NStr("en='Время окончания рабочего дня меньше времени окончания перерыва.';ru='Время окончания рабочего дня меньше времени окончания перерыва.';vi='Thời gian kết thúc ngày làm việc ít hơn thời gian kết thúc của giờ nghỉ.'");
				Message.Field = "Breaks[" + String(LineNumber-1)+"]" + ".EndTime";
				Message.SetData(ThisForm);
				Message.Message();
				
				EndTime = СтрокаПерерывов.EndTime; 
				
			EndIf;
			
			LineNumber = LineNumber + 1;
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

