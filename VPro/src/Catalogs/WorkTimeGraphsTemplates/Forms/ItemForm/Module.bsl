&AtClient
Var ВремяНачалаДоИзменения, ВремяОкончанияДоИзменения, КоличествоРабочихЧасовДоИзменения;

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Not ValueIsFilled(Object.ScheduleType) Then
		Object.ScheduleType = Enums.WorkScheduleTypes.CalendarDays;
		ВидГрафикаПриИзмененииНаСервере();
		Items.WorkSchedule.ChangeRowSet = False;
	Else
		ВидГрафикаПриИзмененииНаСервере(True);
		ScheduleChanged = True;
	EndIf;
	
	Object.AccountHolidays = ?(Parameters.Key.IsEmpty(), True, Object.AccountHolidays);
	
	Object.Breaks.Sort("DayNumber Asc");
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	УстановитьНастройкиТаблиц(True);
	СформироватьПредставлениеРасписанияДополнительныхНастроекЗаполнения();
	ЗаполнитьСписокВыбораДопНастроек();
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	//Расписание работы
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.WorkSchedule.ОшибкаПериода", True, DataCompositionComparisonType.Equal);
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "РасписаниеРаботыНачалоРабочегоДня");
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "РасписаниеРаботыОкончаниеРабочегоДня");
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.ExplanationTextError);
	
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.WorkSchedule.ОшибкаПериода", True, DataCompositionComparisonType.Equal);
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "РасписаниеРаботыЧасовПерерывовПредставление");
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "ReadOnly", True);
	
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.WorkSchedule.ОшибкаПериода", True, DataCompositionComparisonType.Equal);
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "РасписаниеРаботыКоличествоРабочихЧасов");
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "MarkIncomplete", True);
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "ReadOnly", True);
	
	//--------------------
	
	//Дополнительные настройки
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.AdditionalFillingSettings.ОшибкаПериода", True, DataCompositionComparisonType.Equal);
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "ДополнительныеНастройкиЗаполненияВремяНачала");
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "ДополнительныеНастройкиЗаполненияВремяОкончания");
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.ExplanationTextError);
	
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.AdditionalFillingSettings.ОшибкаПериода", True, DataCompositionComparisonType.Equal);
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "ДополнительныеНастройкиЗаполненияРасписание");
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "ReadOnly", True);
	
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.AdditionalFillingSettings.ОшибкаПериода", True, DataCompositionComparisonType.Equal);
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "ДополнительныеНастройкиЗаполненияКоличествоРабочихЧасов");
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "MarkIncomplete", True);
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "ReadOnly", True);
	//---------------------
	
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.WorkSchedule.Active", False, DataCompositionComparisonType.Equal);
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.ScheduleType", Enums.WorkScheduleTypes.ShiftWork, DataCompositionComparisonType.Equal);
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "РасписаниеРаботыНомерДняПредставление");
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "РасписаниеРаботыНачалоРабочегоДня");
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "РасписаниеРаботыОкончаниеРабочегоДня");
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "РасписаниеРаботыКоличествоРабочихЧасов");
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "РасписаниеРаботыВремяПерерывов");
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "РасписаниеРаботыЧасовПерерывовПредставление");
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "ReadOnly", True);
	
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.WorkSchedule.Active", False, DataCompositionComparisonType.Equal);
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.ScheduleType", Enums.WorkScheduleTypes.ShiftWork, DataCompositionComparisonType.Equal);
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "РасписаниеРаботыКоличествоРабочихЧасов");
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.InaccessibleDataColor);
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Text", "<nonworking>");
	
EndProcedure

&AtClient
Procedure УстановитьНастройкиТаблиц(ОткрытияФормы = False)
	
	ПоДнямНедели = ?(Object.ScheduleType = PredefinedValue("Enum.WorkScheduleTypes.CalendarDays"), True, False);
	
	If ThisForm.ReadOnly Then
		
		Items.РасписаниеРаботыКонтекстноеМенюЗаполнитьТекущим.Enabled = False;
		Items.РасписаниеРаботыКонтекстноеМенюДобавитьРабочийДень.Enabled = False;
		Items.РасписаниеРаботыКонтекстноеМенюДобавитьНерабочийДень.Enabled = False;
		Items.РасписаниеРаботыКонтекстноеМенюОчиститьРасипасние.Enabled = False;
		
		Items.РасписаниеКнопкаДобавитьРабочийДень.Enabled = False;
		Items.РасписаниеКнопкаДобавитьНеРабочийДень.Enabled = False;
		
	EndIf;
	
	If ПоДнямНедели Then
		Items.WorkScheduleDayNumberDescription.Title = NStr("en='Day weeks';vi='Ngày trong tuần'");
		Items.РасписаниеРаботыКонтекстноеМенюДобавитьРабочийДень.Visible = False;
		Items.РасписаниеРаботыКонтекстноеМенюДобавитьНерабочийДень.Visible = False;
		Items.РасписаниеРаботыКонтекстноеМенюУдалить.Visible = False;
		Items.РасписаниеРаботыКонтекстноеМенюПереместитьВверх.Visible = False;
		Items.РасписаниеРаботыКонтекстноеМенюПереместитьВниз.Visible = False;
		Items.РасписаниеРаботыКонтекстноеМенюСкопировать.Visible = False;
		Items.РасписаниеРаботыКонтекстноеМенюЗаполнитьТекущим.Visible = True;
	Else
		Items.WorkScheduleDayNumberDescription.Title = NStr("en='Number day';vi='Số ngày'");
		Items.РасписаниеРаботыКонтекстноеМенюДобавитьРабочийДень.Visible = True;
		Items.РасписаниеРаботыКонтекстноеМенюДобавитьНерабочийДень.Visible = True;
		Items.РасписаниеРаботыКонтекстноеМенюУдалить.Visible = True;
		Items.РасписаниеРаботыКонтекстноеМенюПереместитьВверх.Visible = True;
		Items.РасписаниеРаботыКонтекстноеМенюПереместитьВниз.Visible = True;
		Items.РасписаниеРаботыКонтекстноеМенюСкопировать.Visible = True;
		Items.РасписаниеРаботыКонтекстноеМенюЗаполнитьТекущим.Visible = False;
	EndIf;

	Items.РасписаниеРаботыКонтекстноеМенюСкопировать.Enabled = ?(ThisForm.ReadOnly, False,Object.WorkSchedule.Count());
	
	DayNumber = 0;
	
	For Each TimetableString In Object.WorkSchedule Do
		
		DayNumber = DayNumber + 1;
		
		If Not ОткрытияФормы Then
			ПереназначитьНомерДняПерерывам(TimetableString.CycleDayNumber, DayNumber);
			TimetableString.CycleDayNumber = DayNumber;
		EndIf;
		
		TimetableString.НомерДняПредставление = ПредставленияДняЦикла(TimetableString.CycleDayNumber,ПоДнямНедели);
		
		If ValueIsFilled(TimetableString.BeginTime) And ValueIsFilled(TimetableString.EndTime) Then
			TimetableString.ЗаполненПериодРабочегоДня = True;
		Else
			TimetableString.ЗаполненПериодРабочегоДня = False;
		EndIf;
		
		FilterParameters = New Structure("DayNumber", TimetableString.CycleDayNumber);
		СтрокиПерерывов = Object.Breaks.FindRows(FilterParameters);
		
		TimetableString.ЗаполненПериодПерерывов =?(СтрокиПерерывов.Count()>0, True, False);
		
		КоличествоПерерывов = СтрокиПерерывов.Count();
		
		PresentationRow = "";
		
		If КоличествоПерерывов Then
			
			ИндексКоличества = 1;
			
			ДлительностьПерерывов = 0;
			
			For Each СтрокаПерерывов In СтрокиПерерывов Do
				
				ПредставлениеВремениНачала = ?(ValueIsFilled(СтрокаПерерывов.BeginTime), Format(СтрокаПерерывов.BeginTime,"DF=HH:mm"), "00:00");
				ПредставлениеВремениОкончания = ?(ValueIsFilled(СтрокаПерерывов.EndTime), Format(СтрокаПерерывов.EndTime,"DF=HH:mm"), "24:00");
				
				PresentationRow = PresentationRow + "("+ ПредставлениеВремениНачала + "-" 
				+ ПредставлениеВремениОкончания + ")" + ?(ИндексКоличества<КоличествоПерерывов, ", ", "");
				
				ИндексКоличества = ИндексКоличества + 1;
				ДлительностьПерерывов = ДлительностьПерерывов + СтрокаПерерывов.Duration;
				
			EndDo;
			
			PresentationRow = ?(ValueIsFilled(PresentationRow), String(ДлительностьПерерывов) + "h. " + PresentationRow, "");
			
		Else
			PresentationRow = ?(ValueIsFilled(TimetableString.TimeBreak), String(TimetableString.TimeBreak)+ "h. ", "");
		EndIf;
		
		TimetableString.ЧасовПерерывовПредставление = PresentationRow;
		
	EndDo;
	
	СформироватьПредставлениеРасписанияДополнительныхНастроекЗаполнения();
	
EndProcedure

&AtClient
Procedure WorkScheduleOnChange(Item)
	
	УстановитьНастройкиТаблиц();
	
	ScheduleChanged = True;
	ThisForm.Modified = True;
	
EndProcedure

&AtClient
Procedure ПереназначитьНомерДняПерерывам(CycleDayNumber, DayNumber)
	
	FilterParameters = New Structure("DayNumber", CycleDayNumber);
	
	ПереназначаемыеСтроки = Object.Breaks.FindRows(FilterParameters);
	
	For Each СтрокаПерерыва In ПереназначаемыеСтроки Do
		СтрокаПерерыва.DayNumber = DayNumber;
	EndDo
	
EndProcedure

&AtClient
Procedure WorkScheduleOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		CurrentData = Items.WorkSchedule.CurrentData;
		CurrentData.CycleDayNumber = Object.WorkSchedule.Count();
		CurrentData.НомерДняПредставление = ПредставленияДняЦикла(CurrentData.CycleDayNumber,Object.GraphKindWeekDays)
	EndIf;
	
	ОткрытьФормуРедактированияПерерывов(Item);
	
EndProcedure

&AtClient
Procedure WorkScheduleBeforeRowChange(Item, Cancel)
	
	CurrentData = Items.WorkSchedule.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	ВремяНачалаДоИзменения = CurrentData.BeginTime;
	ВремяОкончанияДоИзменения = CurrentData.EndTime;
	КоличествоРабочихЧасовДоИзменения = CurrentData.WorkHoursQuantity;
	
EndProcedure

&AtClient
Procedure ОткрытьФормуРедактированияПерерывов(Item, СобытиеВыбор = False, ЭтоДопНастройка = False)
	
	If Not ЭтоДопНастройка And (СобытиеВыбор Or Item.CurrentItem.Name = "РасписаниеРаботыЧасовПерерывовПредставление") Then
		
		CurrentData = Items.WorkSchedule.CurrentData;
		
		If CurrentData = Undefined Or Not CurrentData.Active Then 
			Return 
		EndIf;
		
		If CurrentData.WorkHoursQuantity = 0 Then
			ShowMessageBox(,NStr("en='Не заданы часы работы';ru='Не заданы часы работы';vi='Giờ không được đặt'"),0,"Warning");
			Return;
		EndIf;
		
		OpenParameters = New Structure;
		OpenParameters.Insert("BeginTime", CurrentData.BeginTime);
		OpenParameters.Insert("EndTime", CurrentData.EndTime);
		OpenParameters.Insert("TimeBreak", CurrentData.TimeBreak);
		OpenParameters.Insert("DayNumber", CurrentData.CycleDayNumber);
		OpenParameters.Insert("WorkingHours", CurrentData.WorkHoursQuantity);
		OpenParameters.Insert("ЭтоДопНастройка", False);
		
		СформироватьПерерывыПоДню(CurrentData.CycleDayNumber);
		OpenParameters.Insert("Breaks", DayBreaks);
		
		AdditNotificationParameters = New Structure;
		
		NotifyDescription = New NotifyDescription(
		"СкорректироватьРасписаниеИПерерывы", 
		ThisObject,
		AdditNotificationParameters);
		
		OpenForm("Catalog.WorkTimeGraphsTemplates.Form.FormChangeSchedule"
		, OpenParameters, Item,,,, NotifyDescription,FormWindowOpeningMode.LockOwnerWindow);
		
		Return;
		
	EndIf;
	
	If ЭтоДопНастройка And (СобытиеВыбор Or Item.CurrentItem.Name = "ДополнительныеНастройкиЗаполненияРасписание") Then
		
		CurrentData = Items.AdditionalFillingSettings.CurrentData;
		
		If CurrentData = Undefined Then
			Return 
		EndIf;
		
		OpenParameters = New Structure;
		OpenParameters.Insert("BeginTime", CurrentData.BeginTime);
		OpenParameters.Insert("EndTime", CurrentData.EndTime);
		OpenParameters.Insert("TimeBreak", CurrentData.TimeBreak);
		OpenParameters.Insert("SettingValue", CurrentData.SettingValue);
		OpenParameters.Insert("WorkingHours", CurrentData.WorkHoursQuantity);
		OpenParameters.Insert("ЭтоДопНастройка", True);
		
		СформироватьПерерывыПоДню(CurrentData.SettingValue, True);
		OpenParameters.Insert("Breaks", DayBreaksAddSettings);
		
		AdditNotificationParameters = New Structure;
		
		NotifyDescription = New NotifyDescription(
		"СкорректироватьРасписаниеИПерерывыДопНастройки",
		ThisObject,
		AdditNotificationParameters);
		
		OpenForm("Catalog.WorkTimeGraphsTemplates.Form.FormChangeSchedule"
		, OpenParameters, Item,,,, NotifyDescription,FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure СкорректироватьРасписаниеИПерерывы(Result, ВходящийКонтекст) Export
	
	If Not Result = Undefined Then
		
		CurrentData = Items.WorkSchedule.CurrentData;
		If CurrentData = Undefined Then Return EndIf;
		
		CurrentData.BeginTime = Result.BeginTime;
		CurrentData.EndTime = Result.EndTime;
		CurrentData.TimeBreak = Result.TimeBreak;
		
		КоличествоПерерывов = Result.Breaks.Count();
		
		PresentationRow = "";
		
		//Перерывы
		FilterParameters = New Structure("DayNumber", CurrentData.CycleDayNumber);
		СтарыеПерерывы = Object.Breaks.FindRows(FilterParameters);
		
		For Each СтарыйПерерыв In СтарыеПерерывы Do
			Object.Breaks.Delete(СтарыйПерерыв);
		EndDo;
		
		For Each НовыйПерерыв In Result.Breaks Do 
			NewRow = Object.Breaks.Add();
			NewRow.DayNumber = CurrentData.CycleDayNumber;
			FillPropertyValues(NewRow, НовыйПерерыв);
		EndDo;
		
		//Периоды между перерывами
		FilterParameters = New Structure("CycleDayNumber", CurrentData.CycleDayNumber);
		СтарыеПериоды = Object.Periods.FindRows(FilterParameters);
		
		For Each СтарыйПериод In СтарыеПериоды Do
			Object.Periods.Delete(СтарыйПериод);
		EndDo;
		
		For Each NewPeriod In Result.Periods Do
			NewRow = Object.Periods.Add();
			NewRow.CycleDayNumber = CurrentData.CycleDayNumber;
			FillPropertyValues(NewRow, NewPeriod);
		EndDo;
		
		If Not Result.Periods.Count() Then
			
			If ValueIsFilled(CurrentData.BeginTime)
				Or ValueIsFilled(CurrentData.EndTime) Then
				NewRow = Object.Periods.Add();
				NewRow.BeginTime = CurrentData.BeginTime;
				NewRow.EndTime = CurrentData.EndTime;
			EndIf;
			
		EndIf;
		
		ОбработатьИзменениеРабочегоПериода(False, Result.WorkHours);
		УстановитьНастройкиТаблиц();
		
		ScheduleChanged = True;
		ThisForm.Modified = True;
		
	EndIf;
	
	Object.Breaks.Sort("DayNumber Asc");
	
EndProcedure

&AtClient
Procedure СкорректироватьРасписаниеИПерерывыДопНастройки(Result, ВходящийКонтекст) Export
	
	If Not Result = Undefined Then
		
		CurrentData = Items.AdditionalFillingSettings.CurrentData;
		If CurrentData = Undefined Then Return EndIf;
		
		CurrentData.BeginTime = Result.BeginTime;
		CurrentData.EndTime = Result.EndTime;
		CurrentData.TimeBreak = Result.TimeBreak;
		CurrentData.WorkHoursQuantity = Result.WorkHours;
		
		КоличествоПерерывов = Result.Breaks.Count();
		
		PresentationRow = "";
		
		//Перерывы
		FilterParameters = New Structure("SettingValue", CurrentData.SettingValue);
		СтарыеПерерывы = Object.BreaksAdditionalFillingSettings.FindRows(FilterParameters);
		
		For Each СтарыйПерерыв In СтарыеПерерывы Do
			Object.BreaksAdditionalFillingSettings.Delete(СтарыйПерерыв);
		EndDo;
		
		ПредставлениеПерерывов = "";
		
		For Each НовыйПерерыв In Result.Breaks Do 
			NewRow = Object.BreaksAdditionalFillingSettings.Add();
			NewRow.SettingValue = CurrentData.SettingValue;
			FillPropertyValues(NewRow, НовыйПерерыв);
			
			ПредставлениеПерерывов = ПредставлениеПерерывов + "(" + Format(НовыйПерерыв.BeginTime,"DF=HH:mm") + "-"
			+ ?(ValueIsFilled(НовыйПерерыв.EndTime),Format(НовыйПерерыв.EndTime,"DF=HH:mm"), "24:00")+")" + ";";
			
		EndDo;
		
		//Периоды между перерывами
		FilterParameters = New Structure("SettingValue", CurrentData.SettingValue);
		СтарыеПериоды = Object.AdditionalFillingSettingsPeriods.FindRows(FilterParameters);
		
		For Each СтарыйПериод In СтарыеПериоды Do
			Object.AdditionalFillingSettingsPeriods.Delete(СтарыйПериод);
		EndDo;
		
		For Each NewPeriod In Result.Periods Do
			NewRow = Object.AdditionalFillingSettingsPeriods.Add();
			NewRow.SettingValue = CurrentData.SettingValue;
			FillPropertyValues(NewRow, NewPeriod);
		EndDo;
		
		If Not Result.Periods.Count() Then
			
			If ValueIsFilled(CurrentData.BeginTime)
				Or ValueIsFilled(CurrentData.EndTime) Then
				NewRow = Object.AdditionalFillingSettingsPeriods.Add();
				NewRow.BeginTime = CurrentData.BeginTime;
				NewRow.EndTime = CurrentData.EndTime;
			EndIf;
			
		EndIf;
		
		If CurrentData.WorkHoursQuantity = 0 Then
			ОчиститьРасписаниеИПерерывы(CurrentData.SettingValue);
			CurrentData.SchedulePresentation = "";
			Return
		EndIf;
		
		If Not CurrentData.TimeBreak = 0 Then
			
			PresentationRow = ?(Not CurrentData.TimeBreak = 0, String(CurrentData.TimeBreak)+"h. " + ПредставлениеПерерывов, "");
			
		EndIf;
		
		ОбработатьИзменениеРабочегоПериодаДополнительныхНастроек(False, Result.WorkHours);
		CurrentData.ЧасовПерерывовПредставление = PresentationRow;
		
		ScheduleChanged = True;
		ThisForm.Modified = True;
		
	EndIf;
	
	Object.Breaks.Sort("DayNumber Asc");
	
EndProcedure

&AtClient
Procedure СформироватьПредставлениеРасписанияДополнительныхНастроекЗаполнения()
	
	For Each СтрокаДопНастроек In Object.AdditionalFillingSettings Do
		
		FilterParameters = New Structure("SettingValue", СтрокаДопНастроек.SettingValue);
		СтрокиПерерывы = Object.BreaksAdditionalFillingSettings.FindRows(FilterParameters);
		
		If СтрокаДопНастроек.WorkHoursQuantity = 0 Then Continue EndIf;
		
		PresentationRow = "";
		ПредставлениеПерерывов = "";
		
		For Each СтрокаПерерыва In СтрокиПерерывы Do
			ПредставлениеПерерывов = "(" + ?(ValueIsFilled(СтрокаПерерыва.BeginTime), Format(СтрокаПерерыва.BeginTime,"DF=HH:mm"), "00:00")
			+ "-" + ?(ValueIsFilled(СтрокаПерерыва.EndTime), Format(СтрокаПерерыва.EndTime,"DF=HH:mm"), "24:00") + ")" + ";";
		EndDo;
		
		If Not СтрокаДопНастроек.TimeBreak = 0 Then
			
			PresentationRow = ?(СтрокаДопНастроек.TimeBreak > 0, String(СтрокаДопНастроек.TimeBreak) + "h. " + ПредставлениеПерерывов, "");
			
		EndIf;
		
		СтрокаДопНастроек.ЧасовПерерывовПредставление = PresentationRow;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure СформироватьПерерывыПоДню(SearchParameter, ЭтоДопНастройка = False)
	
	If Not ЭтоДопНастройка Then
		
		DayBreaks.Clear();
		
		ОтборПерерывы = New Structure("DayNumber", SearchParameter);
		СтрокиПерерывов = Object.Breaks.FindRows(ОтборПерерывы);
		
		LineNumber = 1;
		
		For Each СтрокаПерерыва In СтрокиПерерывов Do
			NewRow = DayBreaks.Add();
			FillPropertyValues(NewRow,СтрокаПерерыва);
			NewRow.LineNumber = LineNumber;
			LineNumber = LineNumber + 1;
		EndDo;
		
	Else
		
		DayBreaksAddSettings.Clear();
		
		ОтборПерерывы = New Structure("SettingValue", SearchParameter);
		СтрокиПерерывов = Object.BreaksAdditionalFillingSettings.FindRows(ОтборПерерывы);
		
		LineNumber = 1;
		
		For Each СтрокаПерерыва In СтрокиПерерывов Do
			NewRow = DayBreaksAddSettings.Add();
			FillPropertyValues(NewRow,СтрокаПерерыва);
			NewRow.LineNumber = LineNumber;
			LineNumber = LineNumber + 1;
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function ПредставленияДняЦикла(DayNumber, ВидГрафикаПоДнямНедели = False)
	If ВидГрафикаПоДнямНедели Then
		Return Format(BegOfWeek('20100101') + (DayNumber - 1) * 86400, "DF=ддд");
	Else
		Return Format(DayNumber, "NG=");
	EndIf;
EndFunction

&AtClient
Procedure WorkScheduleBeforeDeleteRow(Item, Cancel)
	CurrentData = Items.WorkSchedule.CurrentData;
	
	If Not CurrentData = Undefined Then
		ОчиститьРасписаниеИПерерывы(CurrentData.CycleDayNumber);
	EndIf;
EndProcedure

&AtServer
Procedure ОчиститьРасписаниеИПерерывы(CycleDayNumber)
	
	FilterParameters = New Structure("DayNumber", CycleDayNumber);
	
	СтрокиДляУдаления = Object.Breaks.FindRows(FilterParameters);
	
	For Each RemovedRow In СтрокиДляУдаления Do
		Object.Breaks.Delete(RemovedRow);
	EndDo;
	
	FilterParameters = New Structure("CycleDayNumber", CycleDayNumber);
	СтрокиПериодов = Object.Periods.FindRows(FilterParameters);
	
	For Each RowPeriod In СтрокиПериодов Do
		Object.Periods.Delete(RowPeriod);
	EndDo;
	
EndProcedure

&AtClient
Procedure ПереназначитьРасписаниеИПерерывыДополнительныхНастроек(ЗначениеСтаройНастройки, ЗначениеНовойНастройки)
	
	FilterParameters = New Structure("SettingValue", ЗначениеСтаройНастройки);
	
	СтрокиПерерывов = Object.BreaksAdditionalFillingSettings.FindRows(FilterParameters);
	
	For Each СтрокаПерерыва In СтрокиПерерывов Do
		СтрокаПерерыва.SettingValue = ЗначениеНовойНастройки;
	EndDo;
	
	FilterParameters = New Structure("SettingValue", ЗначениеСтаройНастройки);
	СтрокиПериодов = Object.AdditionalFillingSettingsPeriods.FindRows(FilterParameters);
	
	For Each RowPeriod In СтрокиПериодов Do
		RowPeriod.SettingValue = ЗначениеНовойНастройки;
	EndDo;
	
EndProcedure

&AtServer
Procedure ВидГрафикаПриИзмененииНаСервере(FormOpening = False)
	
	ЭтоГрафикПоСменам = ?(Object.ScheduleType = Enums.WorkScheduleTypes.ShiftWork, True, False);
	
	If Not ЭтоГрафикПоСменам Then
		Items.WorkSchedule.ChangeRowSet = False;
	EndIf;
	
	Items.ГруппаКоманднаяПанельРасписание.Visible = ЭтоГрафикПоСменам;
	
	If Not FormOpening And Not ЭтоГрафикПоСменам Then
		ЗаполнитьСтрокиРасписанияКалендаряПоУмолчанию();
	EndIf;
	
EndProcedure

&AtServer
Procedure ЗаполнитьСтрокиРасписанияКалендаряПоУмолчанию()
	WorkingDaysCount = 5;
	
	Object.WorkSchedule.Clear();
	Object.Breaks.Clear();
	Object.Periods.Clear();
	
	For DayNumber = 1 To 7 Do
		TimetableString = Object.WorkSchedule.Add();
		TimetableString.CycleDayNumber = DayNumber;
		TimetableString.НомерДняПредставление = ПредставленияДняЦикла(DayNumber, Object.GraphKindWeekDays);
		TimetableString.Active = True;
		
		If DayNumber <= WorkingDaysCount Then
			TimetableString.WorkHoursQuantity = 8;
			TimetableString.BeginTime = Date(1,1,1,08,00,0);
			TimetableString.EndTime = Date(1,1,1,17,00,0);
			
			СтрокаПерерыв = Object.Breaks.Add();
			СтрокаПерерыв.BeginTime = Date(1,1,1,12,00,0);
			СтрокаПерерыв.EndTime = Date(1,1,1,13,00,0);
			СтрокаПерерыв.Duration = 1;
			СтрокаПерерыв.DayNumber = DayNumber;
			
			НоваяСтрокаПериода = Object.Periods.Add();
			НоваяСтрокаПериода.BeginTime = Date(1,1,1,8,0,0);
			НоваяСтрокаПериода.EndTime = Date(1,1,1,12,0,0);
			НоваяСтрокаПериода.CycleDayNumber = DayNumber;
			НоваяСтрокаПериода.Duration = 4;
			
			НоваяСтрокаПериода = Object.Periods.Add();
			НоваяСтрокаПериода.BeginTime = Date(1,1,1,13,0,0);
			НоваяСтрокаПериода.EndTime = Date(1,1,1,17,0,0);
			НоваяСтрокаПериода.CycleDayNumber = DayNumber;
			НоваяСтрокаПериода.Duration = 4;
			
			TimetableString.TimeBreak = 1;
			
		EndIf;
	EndDo;
EndProcedure

&AtClient
Procedure РасписаниеРаботыНачалоРабочегоДняПриИзменении(Item)
	ОбработатьИзменениеРабочегоПериода();
EndProcedure

&AtClient
Procedure РасписаниеРаботыОкончаниеРабочегоДняПриИзменении(Item)
	ОбработатьИзменениеРабочегоПериода();
EndProcedure

&AtClient
Procedure ОбработатьИзменениеРабочегоПериода(ИзменениеВТабличнойЧасти = True, WorkHours = 0)
	
	CurrentData = Items.WorkSchedule.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	ИмяТЧПерерывы = "Breaks";
	ИмяТЧПериоды = "Periods";
	КолонкаОтбораПерерывы = "DayNumber";
	КолонкаОтбораПериоды = "CycleDayNumber";
	
	FilterParameters = New Structure(КолонкаОтбораПерерывы, CurrentData.CycleDayNumber);
	СтрокиПерерывов = Object[ИмяТЧПерерывы].FindRows(FilterParameters);
	
	If СтрокиПерерывов.Count() And ИзменениеВТабличнойЧасти Then
		
		QuestionText = NStr("en='Границы перерывов выходят за период рабочего дня. Интервалы перерывов будут очищены. Продолжить?';ru='Границы перерывов выходят за период рабочего дня. Интервалы перерывов будут очищены. Продолжить?';vi='Ranh giới của thời gian nghỉ vượt quá thời gian của ngày làm việc. Khoảng nghỉ sẽ được xóa. Tiếp tục?'");
		
		NotificationParameters = New Structure("CurrentData", CurrentData);
		
		If ValueIsFilled(CurrentData.BeginTime)
			And CurrentData.BeginTime > СтрокиПерерывов[0].BeginTime Then
			
			Mode = QuestionDialogMode.YesNo;
			ПараметрыОповещени = New Structure("CurrentData",CurrentData);
			Notification = New NotifyDescription("AfterQuestionClosing", ThisForm, NotificationParameters);
			ShowQueryBox(Notification, QuestionText, Mode, 0);
			
			Return;
		EndIf;
		
		ВремяОкончанияПерерывов = СтрокиПерерывов[СтрокиПерерывов.Count()-1].EndTime;
		ВремяОкончанияПерерывов = ?(Not ValueIsFilled(ВремяОкончанияПерерывов), Date(1,1,1,23,59,0), ВремяОкончанияПерерывов);
		
		ВремяОкончанияПериода = CurrentData.EndTime;
		ВремяОкончанияПериода = ?(Not ValueIsFilled(ВремяОкончанияПериода), Date(1,1,1,23,59,0), ВремяОкончанияПериода);
		
		If ValueIsFilled(ВремяОкончанияПерерывов)
			And ВремяОкончанияПериода < ВремяОкончанияПерерывов Then
			
			Mode = QuestionDialogMode.YesNo;
			NotificationParameters = New Structure("CurrentData", CurrentData);
			Notification = New NotifyDescription("AfterQuestionClosing", ThisForm, NotificationParameters);
			ShowQueryBox(Notification, QuestionText, Mode, 0);
			
			Return;
		EndIf;
		
	EndIf;
	
	CurrentData.ОшибкаПериода = False;
	
	If ValueIsFilled(CurrentData.BeginTime) And ValueIsFilled(CurrentData.EndTime)
		And CurrentData.EndTime<= CurrentData.BeginTime Then
		CurrentData.ОшибкаПериода = True;
		CurrentData.WorkHoursQuantity = 0;
	EndIf;
	
	If ValueIsFilled(CurrentData.EndTime) And CurrentData.BeginTime>= CurrentData.EndTime Then
		CurrentData.ОшибкаПериода = True;
		CurrentData.WorkHoursQuantity = 0;
	EndIf;
	
	BeginOfPeriod = CurrentData.BeginTime;
	EndOfPeriod = CurrentData.EndTime;
	
	If Not CurrentData.ОшибкаПериода Then
		
		WorkHoursQuantity = Round((EndOfPeriod-BeginOfPeriod)/60/60, 2, RoundMode.Round15as20);
		
		If ValueIsFilled(BeginOfPeriod) Or ValueIsFilled(EndOfPeriod) Then
			CurrentData.WorkHoursQuantity = ?(WorkHoursQuantity > 0, WorkHoursQuantity - CurrentData.TimeBreak
			, 24 + WorkHoursQuantity - CurrentData.TimeBreak);
		EndIf;
		
		If Not ValueIsFilled(BeginOfPeriod) And Not ValueIsFilled(EndOfPeriod)
			Then
			CurrentData.WorkHoursQuantity = ?(Not WorkHours = 0, WorkHours, 24-CurrentData.TimeBreak);
		EndIf;
		
		If ValueIsFilled(CurrentData.WorkHoursQuantity) Then
			
			FilterParameters = New Structure(КолонкаОтбораПериоды, CurrentData.CycleDayNumber);
			СтрокиПериодов = Object[ИмяТЧПериоды].FindRows(FilterParameters);
			
			For Each RowPeriod In СтрокиПериодов Do
				Object[ИмяТЧПериоды].Delete(RowPeriod);
			EndDo;
			
			NewRow = Object[ИмяТЧПериоды].Add();
			NewRow.CycleDayNumber = CurrentData.CycleDayNumber;
			
			NewRow.BeginTime = CurrentData.BeginTime;
			NewRow.EndTime = CurrentData.EndTime;
			NewRow.Duration = CurrentData.WorkHoursQuantity;
			NewRow.BreakHours = CurrentData.TimeBreak;
			
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(CurrentData.TimeBreak) And CurrentData.WorkHoursQuantity = 0
		And (ValueIsFilled(CurrentData.EndTime) Or ValueIsFilled(CurrentData.BeginTime)) Then
		CurrentData.ОшибкаПериода = True;
	EndIf;
	
	CurrentData.ЗаполненПериодРабочегоДня = True;
	
EndProcedure

&AtClient
Procedure AfterQuestionClosing(Result, Parameters) Export
	
	CurrentData = Parameters.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	If Result = DialogReturnCode.No Then
		
		CurrentData.BeginTime = ВремяНачалаДоИзменения;
		CurrentData.EndTime = ВремяОкончанияДоИзменения;
		CurrentData.WorkHoursQuantity = КоличествоРабочихЧасовДоИзменения;
		
		Return;
	EndIf;
	
	If ValueIsFilled(CurrentData.BeginTime) And ValueIsFilled(CurrentData.EndTime)
		And CurrentData.EndTime<= CurrentData.BeginTime Then
		CurrentData.ОшибкаПериода = True;
		CurrentData.WorkHoursQuantity = 0;
	Else
		CurrentData.ОшибкаПериода = False;
		
	EndIf;
	
	If ValueIsFilled(CurrentData.EndTime) And CurrentData.BeginTime>= CurrentData.EndTime Then
		CurrentData.ОшибкаПериода = True;
		CurrentData.WorkHoursQuantity = 0;
	Else
		CurrentData.ОшибкаПериода = False;
	EndIf;
	
	BeginOfPeriod = CurrentData.BeginTime;
	EndOfPeriod = CurrentData.EndTime;
	
	FilterParameters = New Structure("DayNumber", CurrentData.CycleDayNumber);
	СтрокиПерерывов = Object.Breaks.FindRows(FilterParameters);
	
	For Each СтрокаПерерывов In СтрокиПерерывов Do
		Object.Breaks.Delete(СтрокаПерерывов);
	EndDo;
	
	FilterParameters = New Structure("CycleDayNumber", CurrentData.CycleDayNumber);
	СтрокиПериодов = Object.Periods.FindRows(FilterParameters);
	
	For Each RowPeriod In СтрокиПериодов Do
		Object.Periods.Delete(RowPeriod);
	EndDo;
	
	If CurrentData.WorkHoursQuantity = 0 Then
		
		CurrentData.TimeBreak = 0;
		EndOfPeriod = Date(1,1,1);
		BeginOfPeriod = Date(1,1,1);
		
	EndIf;
	
	If Not CurrentData.ОшибкаПериода Then
		WorkHoursQuantity = Round((EndOfPeriod-BeginOfPeriod)/60/60, 2, RoundMode.Round15as20);
		
		CurrentData.WorkHoursQuantity = ?(WorkHoursQuantity > 0, WorkHoursQuantity - CurrentData.TimeBreak
		, 24 + WorkHoursQuantity - CurrentData.TimeBreak);
		
		If ValueIsFilled(CurrentData.WorkHoursQuantity) Then
			
			NewRow = Object.Periods.Add();
			NewRow.CycleDayNumber = CurrentData.CycleDayNumber;
			
			NewRow.BeginTime = CurrentData.BeginTime;
			NewRow.EndTime = CurrentData.EndTime;
			NewRow.Duration = CurrentData.WorkHoursQuantity;
			NewRow.BreakHours = CurrentData.TimeBreak;
			
		EndIf;
		
	EndIf;
	
	//Если Не ЗначениеЗаполнено(ТекущиеДанные.ВремяОкончания) Тогда
	//	ТекущиеДанные.ВремяОкончания = КонецРабочегоДня1С;
	//КонецЕсли;
	
	УстановитьНастройкиТаблиц();
	
EndProcedure

&AtClient
Procedure ПослеЗакрытияВопросаИзменениеТипаГрафика(Result, Parameters) Export
	
	If Result = DialogReturnCode.No Then
		
		If Object.ScheduleType = PredefinedValue("Enum.WorkScheduleTypes.CalendarDays") Then
			Object.ScheduleType = PredefinedValue("Enum.WorkScheduleTypes.ShiftWork")
		Else
			Object.ScheduleType = PredefinedValue("Enum.WorkScheduleTypes.CalendarDays")
		EndIf;
		
		Return;
	EndIf;
	
	Object.WorkSchedule.Clear();
	Object.Breaks.Clear();
	Object.Periods.Clear();
	Object.AdditionalFillingSettings.Clear();
	Object.AdditionalFillingSettingsPeriods.Clear();
	Object.BreaksAdditionalFillingSettings.Clear();
	DayBreaks.Clear();
	DayBreaksAddSettings.Clear();
	
	If Object.ScheduleType = PredefinedValue("Enum.WorkScheduleTypes.CalendarDays") Then
		ВидГрафикаПриИзмененииНаСервере();
		Items.ГруппаКоманднаяПанельРасписание.Visible = False;
		Items.WorkSchedule.ChangeRowSet = False;
		Object.AccountHolidays = True;
		
		Items.AdditionalFillingSettingsChange.ChoiceList.Clear();
		Items.AdditionalFillingSettingsChange.ChoiceList.Add(NStr("en='By even numbers';ru='По четным числам';vi='Theo số chẵn'"));
		Items.AdditionalFillingSettingsChange.ChoiceList.Add(NStr("en='By odd numbers';ru='По нечетным числам';vi='Theo số lẻ'"));
		Items.AdditionalFillingSettingsChange.ChoiceList.Add(NStr("en='On preholidays';ru='В предпраздничных днях';vi='Vào ngày lễ'"));
		Items.AdditionalFillingSettingsChange.ChoiceList.Add(NStr("en='On holidays';ru='В праздники';vi='Vào ngày lễ'"));
		Items.AdditionalFillingSettingsChange.ChoiceList.Add(NStr("en='On weekends';ru='В выходные';vi='Vào ngày nghỉ'"),NStr("en='On Weekends(sa, su, holidays)';ru='В выходные (сб, вс, праздники)';vi='Vào cuối tuần (Thứ bảy, Chủ nhật, ngày lễ)'"));
	Else
		Items.ГруппаКоманднаяПанельРасписание.Visible = True;
		Items.WorkSchedule.ChangeRowSet = True;
		Object.AccountHolidays = False;
		
		Items.AdditionalFillingSettingsChange.ChoiceList.Clear();
		Items.AdditionalFillingSettingsChange.ChoiceList.Add(NStr("en='By even numbers';ru='По четным числам';vi='Theo số chẵn'"));
		Items.AdditionalFillingSettingsChange.ChoiceList.Add(NStr("en='By odd numbers';ru='По нечетным числам';vi='Theo số lẻ'"));
		Items.AdditionalFillingSettingsChange.ChoiceList.Add(NStr("en='On Saturdays';ru='По субботам';vi='Vào các ngày thứ bảy'"));
		Items.AdditionalFillingSettingsChange.ChoiceList.Add(NStr("en='On Sundays';ru='По воскресеньям';vi='Vào những ngày chủ nhật'"));
		Items.AdditionalFillingSettingsChange.ChoiceList.Add(NStr("en='On preholidays';ru='В предпраздничных днях';vi='Vào ngày lễ'"));
		Items.AdditionalFillingSettingsChange.ChoiceList.Add(NStr("en='On holidays';ru='В праздники';vi='Vào ngày lễ'"));
		Items.AdditionalFillingSettingsChange.ChoiceList.Add(NStr("en='On weekends';ru='В выходные';vi='Vào ngày nghỉ'"),NStr("en='On Weekends(sa, su, holidays)';ru='В выходные (сб, вс, праздники)';vi='Vào cuối tuần (Thứ bảy, Chủ nhật, ngày lễ)'"));
	EndIf;
	
	УстановитьНастройкиТаблиц();
	
	ScheduleChanged = False;
	ThisForm.Modified = True;
	
EndProcedure

&AtClient
Procedure ScheduleTypeOnChange(Item)
	
	If ScheduleChanged Then
		Mode = QuestionDialogMode.YesNo;
		Notification = New NotifyDescription("ПослеЗакрытияВопросаИзменениеТипаГрафика", ThisForm, Parameters);
		ShowQueryBox(Notification, NStr("en='Schedule changes will be deleted. Continue?';ru='Изменения расписания будут удалены. Продолжить?';vi='Thay đổi lịch trình sẽ bị xóa. Tiếp tục?'"), Mode, 0);
		
		Return;
	EndIf;
	
		Object.WorkSchedule.Clear();
	Object.Breaks.Clear();
	Object.Periods.Clear();
	Object.AdditionalFillingSettings.Clear();
	Object.AdditionalFillingSettingsPeriods.Clear();
	Object.BreaksAdditionalFillingSettings.Clear();
	DayBreaks.Clear();
	DayBreaksAddSettings.Clear();
	
	If Object.ScheduleType = PredefinedValue("Enum.WorkScheduleTypes.CalendarDays") Then
		ВидГрафикаПриИзмененииНаСервере();
		Items.ГруппаКоманднаяПанельРасписание.Visible = False;
		Items.WorkSchedule.ChangeRowSet = False;
		Object.AccountHolidays = True;
		
		Items.AdditionalFillingSettingsChange.ChoiceList.Clear();
		Items.AdditionalFillingSettingsChange.ChoiceList.Add(NStr("en='By even numbers';ru='По четным числам';vi='Theo số chẵn'"));
		Items.AdditionalFillingSettingsChange.ChoiceList.Add(NStr("en='By odd numbers';ru='По нечетным числам';vi='Theo số lẻ'"));
		Items.AdditionalFillingSettingsChange.ChoiceList.Add(NStr("en='On preholidays';ru='В предпраздничных днях';vi='Vào ngày lễ'"));
		Items.AdditionalFillingSettingsChange.ChoiceList.Add(NStr("en='On holidays';ru='В праздники';vi='Vào ngày lễ'"));
		Items.AdditionalFillingSettingsChange.ChoiceList.Add(NStr("en='On weekends';ru='В выходные';vi='Vào ngày nghỉ'"),NStr("en='On Weekends(sa, su, holidays)';ru='В выходные (сб, вс, праздники)';vi='Vào cuối tuần (Thứ bảy, Chủ nhật, ngày lễ)'"));
	Else
		Items.ГруппаКоманднаяПанельРасписание.Visible = True;
		Items.WorkSchedule.ChangeRowSet = True;
		Object.AccountHolidays = False;
		
		Items.AdditionalFillingSettingsChange.ChoiceList.Clear();
		Items.AdditionalFillingSettingsChange.ChoiceList.Add(NStr("en='By even numbers';ru='По четным числам';vi='Theo số chẵn'"));
		Items.AdditionalFillingSettingsChange.ChoiceList.Add(NStr("en='By odd numbers';ru='По нечетным числам';vi='Theo số lẻ'"));
		Items.AdditionalFillingSettingsChange.ChoiceList.Add(NStr("en='On Saturdays';ru='По субботам';vi='Vào các ngày thứ bảy'"));
		Items.AdditionalFillingSettingsChange.ChoiceList.Add(NStr("en='On Sundays';ru='По воскресеньям';vi='Vào những ngày chủ nhật'"));
		Items.AdditionalFillingSettingsChange.ChoiceList.Add(NStr("en='On preholidays';ru='В предпраздничных днях';vi='Vào ngày lễ'"));
		Items.AdditionalFillingSettingsChange.ChoiceList.Add(NStr("en='On holidays';ru='В праздники';vi='Vào ngày lễ'"));
		Items.AdditionalFillingSettingsChange.ChoiceList.Add(NStr("en='On weekends';ru='В выходные';vi='Vào ngày nghỉ'"),NStr("en='On Weekends(sa, su, holidays)';ru='В выходные (сб, вс, праздники)';vi='Vào cuối tuần (Thứ bảy, Chủ nhật, ngày lễ)'"));
	EndIf;
	
	УстановитьНастройкиТаблиц();
	
	ScheduleChanged = False;
	ThisForm.Modified = True;
	
EndProcedure

&AtClient
Procedure ЗаполнитьСписокВыбораДопНастроек()
	
	If Object.ScheduleType = PredefinedValue("Enum.WorkScheduleTypes.CalendarDays") Then
		
		Items.AdditionalFillingSettingsChange.ChoiceList.Clear();
		Items.AdditionalFillingSettingsChange.ChoiceList.Add(NStr("en='By even numbers';ru='По четным числам';vi='Theo số chẵn'"));
		Items.AdditionalFillingSettingsChange.ChoiceList.Add(NStr("en='By odd numbers';ru='По нечетным числам';vi='Theo số lẻ'"));
		Items.AdditionalFillingSettingsChange.ChoiceList.Add(NStr("en='On preholidays';ru='В предпраздничных днях';vi='Vào ngày lễ'"));
		Items.AdditionalFillingSettingsChange.ChoiceList.Add(NStr("en='On holidays';ru='В праздники';vi='Vào ngày lễ'"));
		Items.AdditionalFillingSettingsChange.ChoiceList.Add(NStr("en='On weekends';ru='В выходные';vi='Vào ngày nghỉ'"),NStr("en='On Weekends(sa, su, holidays)';ru='В выходные (сб, вс, праздники)';vi='Vào cuối tuần (Thứ bảy, Chủ nhật, ngày lễ)'"));
	Else
		Items.AdditionalFillingSettingsChange.ChoiceList.Clear();
		Items.AdditionalFillingSettingsChange.ChoiceList.Add(NStr("en='By even numbers';ru='По четным числам';vi='Theo số chẵn'"));
		Items.AdditionalFillingSettingsChange.ChoiceList.Add(NStr("en='By odd numbers';ru='По нечетным числам';vi='Theo số lẻ'"));
		Items.AdditionalFillingSettingsChange.ChoiceList.Add(NStr("en='On Saturdays';ru='По субботам';vi='Vào các ngày thứ bảy'"));
		Items.AdditionalFillingSettingsChange.ChoiceList.Add(NStr("en='On Sundays';ru='По воскресеньям';vi='Vào những ngày chủ nhật'"));
		Items.AdditionalFillingSettingsChange.ChoiceList.Add(NStr("en='On preholidays';ru='В предпраздничных днях';vi='Vào ngày lễ'"));
		Items.AdditionalFillingSettingsChange.ChoiceList.Add(NStr("en='On holidays';ru='В праздники';vi='Vào ngày lễ'"));
		Items.AdditionalFillingSettingsChange.ChoiceList.Add(NStr("en='On weekends';ru='В выходные';vi='Vào ngày nghỉ'"),NStr("en='On Weekends(sa, su, holidays)';ru='В выходные (сб, вс, праздники)';vi='Vào cuối tuần (Thứ bảy, Chủ nhật, ngày lễ)'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If Not Object.WorkSchedule.Count() Then
		Object.Periods.Clear();
		Object.Breaks.Clear();
		Return;
	EndIf;
	
	For Each TimetableString In Object.WorkSchedule Do
		
		If TimetableString.ОшибкаПериода Then
			
			Message = New UserMessage();
			Message.Text = NStr("en='Период задан неверно!';ru='Период задан неверно!';vi='Thời gian được đặt không chính xác!'");
			Message.Field = "Object.WorkSchedule[" + String(TimetableString.LineNumber-1) +"]" + ".BeginTime";
			Message.SetData(ThisForm);
			Message.Message();
			
			Cancel = True;
			Break;
			
		EndIf;
		
		If TimetableString.WorkHoursQuantity = 0 And Not TimetableString.TimeBreak = 0
			Then
			
			Message = New UserMessage();
			Message.Text = NStr("en='Удалите перерывы или введите часы работы!';ru='Удалите перерывы или введите часы работы!';vi='Hủy bỏ nghỉ hoặc nhập giờ làm việc!'");
			Message.Field = "Object.WorkSchedule[" + String(TimetableString.LineNumber-1) +"]" + ".WorkHoursQuantity";
			Message.SetData(ThisForm);
			Message.Message();
			
			Cancel = True;
			Break;
			
		EndIf;
		
	EndDo;
	
	For Each СтрокаДопНастроек In Object.AdditionalFillingSettings Do
		
		If СтрокаДопНастроек.ОшибкаПериода Then
			
			Message = New UserMessage();
			Message.Text = NStr("en='Период задан неверно!';ru='Период задан неверно!';vi='Thời gian được đặt không chính xác!'");
			Message.Field = "Object.AdditionalFillingSettings[" + String(СтрокаДопНастроек.LineNumber-1) +"]" + ".BeginTime";
			Message.SetData(ThisForm);
			Message.Message();
			
			Cancel = True;
			Break;
			
		EndIf;
		
		If СтрокаДопНастроек.WorkHoursQuantity = 0 And Not СтрокаДопНастроек.TimeBreak = 0
			Then
			
			Message = New UserMessage();
			Message.Text = NStr("en='Удалите перерывы или введите часы работы!';ru='Удалите перерывы или введите часы работы!';vi='Hủy bỏ nghỉ hoặc nhập giờ làm việc!'");
			Message.Field = "Object.AdditionalFillingSettings[" + String(СтрокаДопНастроек.LineNumber-1) +"]" + ".WorkHoursQuantity";
			Message.SetData(ThisForm);
			Message.Message();
			
			Cancel = True;
			Break;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure РасписаниеДобавитьНеРабочийДень(Command)
	
	NewRow = Object.WorkSchedule.Add();
	NewRow.Active = False;
	
	ScheduleChanged = True;
	ThisForm.Modified = True;
	
	УстановитьНастройкиТаблиц();
	
EndProcedure

&AtClient
Procedure РасписаниеДобавитьРабочийДень(Command)
	
	NewRow = Object.WorkSchedule.Add();
	NewRow.Active = True;
	
	ScheduleChanged = True;
	ThisForm.Modified = True;
	
	УстановитьНастройкиТаблиц();
	
EndProcedure

&AtClient
Procedure WorkScheduleЧасовПерерывовПредставлениеStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.WorkSchedule.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	If CurrentData.WorkHoursQuantity = 0 Then
		ShowMessageBox(,NStr("en='Не заданы часы работы';ru='Не заданы часы работы';vi='Giờ không được đặt'"),0,"Warning");
		Return;
	EndIf;
	
	ОткрытьФормуРедактированияПерерывов(Item, True);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	УстановитьНастройкиТаблиц();
EndProcedure

&AtClient
Procedure СкопироватьСтрокиРасписания(Command)
	
	КопированиеСтрок();
	
EndProcedure

&AtClient
Procedure КопированиеСтрок()
	
	CurrentData = Items.WorkSchedule.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	НомерКопируемогоДня = CurrentData.CycleDayNumber;
	
	NewRow = Object.WorkSchedule.Add();
	
	FillPropertyValues(NewRow, CurrentData);
	
	NewRow.CycleDayNumber = Object.WorkSchedule.Count();
	
	СкопироватьПерерывыИПериодыСтроке(НомерКопируемогоДня, NewRow.CycleDayNumber);
	
	УстановитьНастройкиТаблиц();
	
	ScheduleChanged = True;
	ThisForm.Modified = True;
	
EndProcedure

&AtClient
Procedure СкопироватьПерерывыИПериодыСтроке(НомерКопируемогоДня, НовыйНомерДня = 0)
	
	//Перерывы
	FilterParameters = New Structure("DayNumber", НомерКопируемогоДня);
	НовыеСтрокиПерерывов = Object.Breaks.FindRows(FilterParameters);
	
	FilterParameters = New Structure("DayNumber", НовыйНомерДня);
	СтарыеСтрокиПерерывов = Object.Breaks.FindRows(FilterParameters);
	
	If СтарыеСтрокиПерерывов.Count() Then
		For Each СтараяСтрокаПерерывов In СтарыеСтрокиПерерывов Do
			Object.Breaks.Delete(СтараяСтрокаПерерывов);
		EndDo;
	EndIf;
	
	For Each СтрокаПерерывов In НовыеСтрокиПерерывов Do
		NewRow = Object.Breaks.Add();
		FillPropertyValues(NewRow, СтрокаПерерывов);
		NewRow.DayNumber = НовыйНомерДня;
	EndDo;
	
	//Периоды
	FilterParameters = New Structure("CycleDayNumber", НомерКопируемогоДня);
	НовыеСтрокиПериода = Object.Periods.FindRows(FilterParameters);
	
	FilterParameters = New Structure("CycleDayNumber", НовыйНомерДня);
	СтарыеСтрокиПериода = Object.Periods.FindRows(FilterParameters);
	
	If СтарыеСтрокиПериода.Count() Then
		For Each СтараяСтрокаПерериода In СтарыеСтрокиПериода Do
			Object.Periods.Delete(СтараяСтрокаПерериода);
		EndDo;
	EndIf;
	
	For Each СтрокаПерерода In НовыеСтрокиПериода Do
		NewRow = Object.Periods.Add();
		FillPropertyValues(NewRow, СтрокаПерерода);
		NewRow.CycleDayNumber = НовыйНомерДня;
	EndDo;
	
EndProcedure

&AtClient
Procedure WorkScheduleBeforeAddRow(Item, Cancel, Copy, Parent, Group, Parameter)
	If Copy Then
		КопированиеСтрок();
		Cancel = True 
	EndIf;
EndProcedure

&AtClient
Procedure WorkScheduleWorkHoursQuantityOnChange(Item)
	
	CurrentData = Items.WorkSchedule.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	FilterParameters = New Structure("DayNumber", CurrentData.CycleDayNumber);
	СтрокиПерерывов = Object.Breaks.FindRows(FilterParameters);
	
	КоличествоПерерывов = СтрокиПерерывов.Count();
	
	If КоличествоПерерывов Then
		
		If Not ValueIsFilled(CurrentData.WorkHoursQuantity) Then
			Mode = QuestionDialogMode.YesNo;
			ПараметрыОповещени = New Structure("CurrentData",CurrentData);
			Notification = New NotifyDescription("AfterQuestionClosing", ThisForm, ПараметрыОповещени);
			ShowQueryBox(Notification, NStr("en='Перерывы будут очищены. Продолжить?';ru='Перерывы будут очищены. Продолжить?';vi='Giờ nghỉ sẽ được xóa. Tiếp tục?'"), Mode, 0);
			Return;
		EndIf;
		
	EndIf;
	
	If CurrentData.WorkHoursQuantity = 0 Then
		CurrentData.BeginTime = Date(1,1,1);
		CurrentData.EndTime = Date(1,1,1);
		CurrentData.TimeBreak = 0;
	EndIf;
	
	If CurrentData.WorkHoursQuantity + CurrentData.TimeBreak > 24 Then
		CurrentData.WorkHoursQuantity = 24 - CurrentData.TimeBreak;
	EndIf;
	
	If ValueIsFilled(CurrentData.BeginTime) Then
		ДоступныхЧасов =86400+(Date(1,1,1) - CurrentData.BeginTime) + CurrentData.TimeBreak*3600;
	Else
		ДоступныхЧасов = 86400 + CurrentData.TimeBreak*3600;
	EndIf;
	
	If CurrentData.WorkHoursQuantity*3600 > ДоступныхЧасов Then
		CurrentData.WorkHoursQuantity = ДоступныхЧасов/3600;
		If ValueIsFilled(CurrentData.BeginTime) Then
			CurrentData.EndTime = CurrentData.BeginTime + (CurrentData.WorkHoursQuantity*3600) + CurrentData.TimeBreak*3600;
		EndIf;
	ElsIf ValueIsFilled(CurrentData.BeginTime) Then
		CurrentData.EndTime = CurrentData.BeginTime + (CurrentData.WorkHoursQuantity*3600) + CurrentData.TimeBreak*3600;
	Else
		CurrentData.EndTime = CurrentData.BeginTime + (CurrentData.WorkHoursQuantity*3600) + CurrentData.TimeBreak*3600;
	EndIf;
	
	If КоличествоПерерывов Then
		
		If Not CurrentData.WorkHoursQuantity = 24
			And ValueIsFilled(CurrentData.EndTime)
			And CurrentData.EndTime < СтрокиПерерывов[КоличествоПерерывов-1].EndTime Then
			
			Mode = QuestionDialogMode.YesNo;
			ПараметрыОповещени = New Structure("CurrentData",CurrentData);
			Notification = New NotifyDescription("AfterQuestionClosing", ThisForm, ПараметрыОповещени);
			ShowQueryBox(Notification, NStr("en='Границы перерывов выходят за период рабочего дня. Интервалы перерывов будут очищены. Продолжить?';ru='Границы перерывов выходят за период рабочего дня. Интервалы перерывов будут очищены. Продолжить?';vi='Ranh giới của thời gian nghỉ vượt quá thời gian của ngày làm việc. Khoảng nghỉ sẽ được xóa. Tiến hành?'"), Mode, 0);
			
			Return;
		EndIf;
		
	EndIf;
	
	FilterParameters = New Structure("CycleDayNumber", CurrentData.CycleDayNumber);
	СтрокиПериодов = Object.Periods.FindRows(FilterParameters);
	
	For Each RowPeriod In СтрокиПериодов Do
		Object.Periods.Delete(RowPeriod);
	EndDo;
	
	If ValueIsFilled(CurrentData.WorkHoursQuantity) Then
		
		NewRow = Object.Periods.Add();
		NewRow.CycleDayNumber = CurrentData.CycleDayNumber;
		
		NewRow.BeginTime = CurrentData.BeginTime;
		NewRow.EndTime = CurrentData.EndTime;
		NewRow.Duration = CurrentData.WorkHoursQuantity;
		NewRow.BreakHours = CurrentData.TimeBreak;
		
	EndIf;
	
	ThisForm.Modified = True;
	
EndProcedure

&AtClient
Procedure ЗаполнитьТекущим(Command)
	
	CurrentData = Items.WorkSchedule.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	НомерКопируемогоДня = CurrentData.CycleDayNumber;
	
	For Each TimetableString In Object.WorkSchedule Do
		
		If TimetableString.CycleDayNumber = НомерКопируемогоДня Then
			Continue;
		EndIf;
		TimetableString.BeginTime = CurrentData.BeginTime;
		TimetableString.EndTime = CurrentData.EndTime;
		TimetableString.TimeBreak = CurrentData.TimeBreak;
		TimetableString.ЗаполненПериодПерерывов = CurrentData.ЗаполненПериодПерерывов;
		TimetableString.ЗаполненПериодРабочегоДня = CurrentData.ЗаполненПериодРабочегоДня;
		TimetableString.ОшибкаПериода = CurrentData.ОшибкаПериода;
		TimetableString.WorkHoursQuantity = CurrentData.WorkHoursQuantity;
		
		СкопироватьПерерывыИПериодыСтроке(НомерКопируемогоДня, TimetableString.CycleDayNumber);
		
	EndDo;
	
	УстановитьНастройкиТаблиц();
	
EndProcedure

&AtClient
Procedure WorkScheduleOnActivateRow(Item)
	
	CurrentData = Items.WorkSchedule.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	Items.РасписаниеРаботыКонтекстноеМенюИзменить.Enabled = CurrentData.Active;
	
EndProcedure

&AtClient
Procedure ОчиститьРасипасние(Command)
	
	CurrentData = Items.WorkSchedule.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	//Периоды
	FilterParameters = New Structure("CycleDayNumber", CurrentData.CycleDayNumber);
	СтрокиПериодов = Object.Periods.FindRows(FilterParameters);
	
	For Each RowPeriod In СтрокиПериодов Do
		
		If Not CurrentData.BeginTime = RowPeriod.BeginTime
			And Not CurrentData.EndTime = RowPeriod.EndTime Then
			
			Object.Periods.Delete(RowPeriod);
			
		EndIf;
		
	EndDo;
	
	//Перерывы
	FilterParameters = New Structure("DayNumber", CurrentData.CycleDayNumber);
	СтрокиПерерывов = Object.Breaks.FindRows(FilterParameters);
	
	For Each СтрокаПерерывов In СтрокиПерерывов Do
		Object.Breaks.Delete(СтрокаПерерывов);
	EndDo;
	
	CurrentData.TimeBreak = 0;
	
	ОбработатьИзменениеРабочегоПериода();
	УстановитьНастройкиТаблиц();
	
EndProcedure

&AtClient
Procedure WorkScheduleAfterDeleteRow(Item)
	If Not Object.WorkSchedule.Count() Then
		Object.Periods.Clear();
		Object.Breaks.Clear();
		Return;
	EndIf;
	
	ScheduleChanged = True;
	ThisForm.Modified = True;
	
EndProcedure

&AtClient
Procedure AdditionalFillingSettingsOnStartEdit(Item, NewRow, Copy)
	
	ОткрытьФормуРедактированияПерерывов(Item,, True);
	
EndProcedure

&AtClient
Procedure AdditionalFillingSettingsAfterDeleteRow(Item)
	
	If Not Object.AdditionalFillingSettings.Count() Then
		Object.AdditionalFillingSettingsPeriods.Clear();
		Object.BreaksAdditionalFillingSettings.Clear();
		Return;
	EndIf;
	
	ScheduleChanged = True;
	ThisForm.Modified = True;
	
EndProcedure

&AtClient
Procedure AdditionalFillingSettingsBeforeDeleteRow(Item, Cancel)
	
	CurrentData = Items.AdditionalFillingSettings.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	ОчиститьРасписаниеИПерерывы(CurrentData.SettingValue);
	
EndProcedure

&AtClient
Procedure ДополнительныеНастройкиЗаполненияРасписаниеНачалоВыбора(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.AdditionalFillingSettings.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	If CurrentData.WorkHoursQuantity = 0 Then
		ShowMessageBox(,NStr("en='Не заданы часы работы';ru='Не заданы часы работы';vi='Giờ không được đặt'"),0,"Warning");
		Return;
	EndIf;
	
	ОткрытьФормуРедактированияПерерывов(Item, True, True)
	
EndProcedure

&AtClient
Procedure ДополнительныеНастройкиЗаполненияИзменитьОбработкаВыбора(Item, SelectedValue, StandardProcessing)
	CurrentData = Items.AdditionalFillingSettings.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	FilterParameters = New Structure("SettingValue", SelectedValue);
	FoundStrings = Object.AdditionalFillingSettings.FindRows(FilterParameters);
	
	If FoundStrings.Count() = 1 And Not FoundStrings[0].LineNumber = CurrentData.LineNumber Then
		Message = New UserMessage();
		Message.Text = NStr("en='Данная доп. настройка заполнения уже присутствует в списке!';ru='Данная доп. настройка заполнения уже присутствует в списке!';vi='Cài đặt điền bổ sung này đã có trong danh sách!'");
		
		Message.Field = "Object.AdditionalFillingSettings[" + String(FoundStrings[0].LineNumber-1) + "]" + ".SettingValue";
		
		Message.SetData(ThisForm);
		Message.Message();
		
		StandardProcessing = False;
		
		Return;
		
	EndIf;
	
	If ValueIsFilled(CurrentData.SettingValue) And Not SelectedValue = CurrentData.SettingValue Then
		ПереназначитьРасписаниеИПерерывыДополнительныхНастроек(CurrentData.SettingValue, SelectedValue);
	EndIf;
	
EndProcedure

&AtClient
Procedure AdditionalFillingSettingsBeginTimeOnChange(Item)
	ОбработатьИзменениеРабочегоПериодаДополнительныхНастроек();
EndProcedure

&AtClient
Procedure AdditionalFillingSettingsEndTimeOnChange(Item)
	ОбработатьИзменениеРабочегоПериодаДополнительныхНастроек();
EndProcedure

&AtClient
Procedure ОбработатьИзменениеРабочегоПериодаДополнительныхНастроек(ИзменениеВТабличнойЧасти = True, WorkHours = 0)
	
	CurrentData = Items.AdditionalFillingSettings.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	FilterParameters = New Structure("SettingValue", CurrentData.SettingValue);
	СтрокиПерерывов = Object.BreaksAdditionalFillingSettings.FindRows(FilterParameters);
	
	If СтрокиПерерывов.Count() And ИзменениеВТабличнойЧасти Then
		QuestionText = NStr("en='Границы перерывов выходят за период рабочего дня. Интервалы перерывов будут очищены. Продолжить?';ru='Границы перерывов выходят за период рабочего дня. Интервалы перерывов будут очищены. Продолжить?';vi='Ranh giới của thời gian nghỉ vượt quá thời gian của ngày làm việc. Khoảng nghỉ sẽ được xóa. Tiến hành?'");
		
		If ValueIsFilled(CurrentData.BeginTime)
			And CurrentData.BeginTime > СтрокиПерерывов[0].BeginTime Then
			
			Mode = QuestionDialogMode.YesNo;
			ПараметрыОповещени = New Structure("CurrentData",CurrentData);
			Notification = New NotifyDescription("ПослеЗакрытияВопросаДополнительныеНастройки", ThisForm, ПараметрыОповещени);
			ShowQueryBox(Notification, QuestionText, Mode, 0);
			
			Return;
		EndIf;
		
		ВремяОкончанияПерерывов = СтрокиПерерывов[СтрокиПерерывов.Count()-1].EndTime;
		ВремяОкончанияПерерывов = ?(Not ValueIsFilled(ВремяОкончанияПерерывов), Date(1,1,1,23,59,0), ВремяОкончанияПерерывов);
		
		ВремяОкончанияПериода = CurrentData.EndTime;
		ВремяОкончанияПериода = ?(Not ValueIsFilled(ВремяОкончанияПериода), Date(1,1,1,23,59,0), ВремяОкончанияПериода);
		
		If ValueIsFilled(ВремяОкончанияПерерывов)
			And ВремяОкончанияПериода< ВремяОкончанияПерерывов Then
			
			Mode = QuestionDialogMode.YesNo;
			ПараметрыОповещени = New Structure("CurrentData",CurrentData);
			Notification = New NotifyDescription("ПослеЗакрытияВопросаДополнительныеНастройки", ThisForm, ПараметрыОповещени);
			ShowQueryBox(Notification, QuestionText, Mode, 0);
			
			Return;
		EndIf;
		
	EndIf;
	
	CurrentData.ОшибкаПериода = False;
	
	If ValueIsFilled(CurrentData.BeginTime) And ValueIsFilled(CurrentData.EndTime)
		And CurrentData.EndTime<= CurrentData.BeginTime Then
		CurrentData.ОшибкаПериода = True;
		CurrentData.WorkHoursQuantity = 0;
	EndIf;
	
	If ValueIsFilled(CurrentData.EndTime) And CurrentData.BeginTime>= CurrentData.EndTime Then
		CurrentData.ОшибкаПериода = True;
		CurrentData.WorkHoursQuantity = 0;
	EndIf;
	
	BeginOfPeriod = CurrentData.BeginTime;
	EndOfPeriod = CurrentData.EndTime;
	
	If Not CurrentData.ОшибкаПериода Then
		
		WorkHoursQuantity = Round((EndOfPeriod-BeginOfPeriod)/60/60, 2, RoundMode.Round15as20);
		
		If ValueIsFilled(BeginOfPeriod) Or ValueIsFilled(EndOfPeriod) Then
			CurrentData.WorkHoursQuantity = ?(WorkHoursQuantity > 0, WorkHoursQuantity - CurrentData.TimeBreak
			, 24 + WorkHoursQuantity - CurrentData.TimeBreak);
		EndIf;
		
		
		If ValueIsFilled(CurrentData.WorkHoursQuantity) And Not СтрокиПерерывов.Count() Then
			
			FilterParameters = New Structure("SettingValue", CurrentData.SettingValue);
			СтрокиПериодов = Object.AdditionalFillingSettingsPeriods.FindRows(FilterParameters);
			
			For Each RowPeriod In СтрокиПериодов Do
				Object.AdditionalFillingSettingsPeriods.Delete(RowPeriod);
			EndDo;
			
			NewRow = Object.AdditionalFillingSettingsPeriods.Add();
			NewRow.SettingValue = CurrentData.SettingValue;
			
			NewRow.BeginTime = CurrentData.BeginTime;
			NewRow.EndTime = CurrentData.EndTime;
			NewRow.Duration = CurrentData.WorkHoursQuantity;
			NewRow.BreakHours = CurrentData.TimeBreak;
			
		EndIf;
		
		If Not ValueIsFilled(BeginOfPeriod) And Not ValueIsFilled(EndOfPeriod)
			Then
			CurrentData.WorkHoursQuantity = ?(Not WorkHours = 0, WorkHours, 24-CurrentData.TimeBreak);
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(CurrentData.TimeBreak) And CurrentData.WorkHoursQuantity = 0
		And (ValueIsFilled(CurrentData.EndTime) Or ValueIsFilled(CurrentData.BeginTime)) Then
		CurrentData.ОшибкаПериода = True;
	EndIf;
	
	CurrentData.ЗаполненПериодРабочегоДня = True;
	
	СформироватьПредставлениеРасписанияДополнительныхНастроекЗаполнения();
	
EndProcedure

&AtClient
Procedure ПослеЗакрытияВопросаДополнительныеНастройки(Result, Parameters) Export
	
	CurrentData = Items.AdditionalFillingSettings.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	If Result = DialogReturnCode.No Then
		
		CurrentData.BeginTime = ВремяНачалаДоИзменения;
		CurrentData.EndTime = ВремяОкончанияДоИзменения;
		CurrentData.WorkHoursQuantity = КоличествоРабочихЧасовДоИзменения;
		
		Return;
	EndIf;
	
	If ValueIsFilled(CurrentData.BeginTime) And ValueIsFilled(CurrentData.EndTime)
		And CurrentData.EndTime<= CurrentData.BeginTime Then
		CurrentData.ОшибкаПериода = True;
		CurrentData.WorkHoursQuantity = 0;
	Else
		CurrentData.ОшибкаПериода = False;
		
	EndIf;
	
	If ValueIsFilled(CurrentData.EndTime) And CurrentData.BeginTime>= CurrentData.EndTime Then
		CurrentData.ОшибкаПериода = True;
		CurrentData.WorkHoursQuantity = 0;
	Else
		CurrentData.ОшибкаПериода = False;
	EndIf;
	
	BeginOfPeriod = CurrentData.BeginTime;
	EndOfPeriod = CurrentData.EndTime;
	
	FilterParameters = New Structure("SettingValue", CurrentData.SettingValue);
	СтрокиПерерывов = Object.BreaksAdditionalFillingSettings.FindRows(FilterParameters);
	
	For Each СтрокаПерерывов In СтрокиПерерывов Do
		Object.BreaksAdditionalFillingSettings.Delete(СтрокаПерерывов);
	EndDo;
	
	FilterParameters = New Structure("SettingValue", CurrentData.SettingValue);
	СтрокиПериодов = Object.AdditionalFillingSettingsPeriods.FindRows(FilterParameters);
	
	For Each RowPeriod In СтрокиПериодов Do
		Object.AdditionalFillingSettingsPeriods.Delete(RowPeriod);
	EndDo;
	
	If CurrentData.WorkHoursQuantity = 0 Then
		
		CurrentData.TimeBreak = 0;
		EndOfPeriod = Date(1,1,1);
		BeginOfPeriod = Date(1,1,1);
		CurrentData.BeginTime = Date(1,1,1);
		CurrentData.EndTime = Date(1,1,1);
		
	EndIf;
	
	If Not CurrentData.ОшибкаПериода Then
		WorkHoursQuantity = Round((EndOfPeriod-BeginOfPeriod)/60/60, 2, RoundMode.Round15as20);
		
		CurrentData.WorkHoursQuantity = ?(WorkHoursQuantity > 0, WorkHoursQuantity - CurrentData.TimeBreak
		, 24 + WorkHoursQuantity - CurrentData.TimeBreak);
		
		If ValueIsFilled(CurrentData.WorkHoursQuantity) Then
			
			NewRow = Object.AdditionalFillingSettingsPeriods.Add();
			NewRow.SettingValue = CurrentData.SettingValue;
			
			NewRow.BeginTime = CurrentData.BeginTime;
			NewRow.EndTime = CurrentData.EndTime;
			NewRow.Duration = CurrentData.WorkHoursQuantity;
			NewRow.BreakHours = CurrentData.TimeBreak;
			
		EndIf;
		
	EndIf;
	
	УстановитьНастройкиТаблиц();
	
EndProcedure

&AtClient
Procedure AdditionalFillingSettingsWorkHoursQuantityOnChange(Item)
	
	CurrentData = Items.AdditionalFillingSettings.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	FilterParameters = New Structure("SettingValue", CurrentData.SettingValue);
	СтрокиПерерывов = Object.BreaksAdditionalFillingSettings.FindRows(FilterParameters);
	
	КоличествоПерерывов = СтрокиПерерывов.Count();
	
	If КоличествоПерерывов Then
		
		If Not ValueIsFilled(CurrentData.WorkHoursQuantity) Then
			Mode = QuestionDialogMode.YesNo;
			ПараметрыОповещени = New Structure("CurrentData",CurrentData);
			Notification = New NotifyDescription("ПослеЗакрытияВопросаДополнительныеНастройки", ThisForm, ПараметрыОповещени);
			ShowQueryBox(Notification, NStr("en='Перерывы будут очищены. Продолжить?';ru='Перерывы будут очищены. Продолжить?';vi='Giờ nghỉ sẽ được xóa. Tiếp tục?'"), Mode, 0);
			Return;
		EndIf;
		
	EndIf;
	
	If CurrentData.WorkHoursQuantity = 0 Then
		CurrentData.BeginTime = Date(1,1,1);
		CurrentData.EndTime = Date(1,1,1);
		CurrentData.TimeBreak = 0;
	EndIf;
	
	If CurrentData.WorkHoursQuantity + CurrentData.TimeBreak > 24 Then
		CurrentData.WorkHoursQuantity = 24 - CurrentData.TimeBreak;
	EndIf;
	
	If ValueIsFilled(CurrentData.BeginTime) Then
		ДоступныхЧасов =86400+(Date(1,1,1) - CurrentData.BeginTime) + CurrentData.TimeBreak*3600;
	Else
		ДоступныхЧасов = 86400 + CurrentData.TimeBreak*3600;
	EndIf;
	
	If CurrentData.WorkHoursQuantity*3600 > ДоступныхЧасов Then
		CurrentData.WorkHoursQuantity = ДоступныхЧасов/3600;
		If ValueIsFilled(CurrentData.BeginTime) Then
			CurrentData.EndTime = CurrentData.BeginTime + (CurrentData.WorkHoursQuantity*3600) + CurrentData.TimeBreak*3600;
		EndIf;
	ElsIf ValueIsFilled(CurrentData.BeginTime) Then
		CurrentData.EndTime = CurrentData.BeginTime + (CurrentData.WorkHoursQuantity*3600) + CurrentData.TimeBreak*3600;
	Else
		CurrentData.EndTime = CurrentData.BeginTime + (CurrentData.WorkHoursQuantity*3600) + CurrentData.TimeBreak*3600;
	EndIf;
	
	If КоличествоПерерывов Then
		
		If Not CurrentData.WorkHoursQuantity = 24
			And ValueIsFilled(CurrentData.EndTime)
			And CurrentData.EndTime < СтрокиПерерывов[КоличествоПерерывов-1].EndTime Then
			
			Mode = QuestionDialogMode.YesNo;
			ПараметрыОповещени = New Structure("CurrentData",CurrentData);
			Notification = New NotifyDescription("ПослеЗакрытияВопросаДополнительныеНастройки", ThisForm, ПараметрыОповещени);
			ShowQueryBox(Notification, NStr("en='Границы перерывов выходят за период рабочего дня. Интервалы перерывов будут очищены. Продолжить?';ru='Границы перерывов выходят за период рабочего дня. Интервалы перерывов будут очищены. Продолжить?';vi='Ranh giới của thời gian nghỉ vượt quá thời gian của ngày làm việc. Khoảng nghỉ sẽ được xóa. Tiến hành?'"), Mode, 0);
			
			Return;
		EndIf;
		
	EndIf;
	
	FilterParameters = New Structure("SettingValue", CurrentData.SettingValue);
	СтрокиПериодов = Object.AdditionalFillingSettingsPeriods.FindRows(FilterParameters);
	
	For Each RowPeriod In СтрокиПериодов Do
		Object.AdditionalFillingSettingsPeriods.Delete(RowPeriod);
	EndDo;
	
	If ValueIsFilled(CurrentData.WorkHoursQuantity) Then
		
		NewRow = Object.AdditionalFillingSettingsPeriods.Add();
		NewRow.SettingValue = CurrentData.SettingValue;
		
		NewRow.BeginTime = CurrentData.BeginTime;
		NewRow.EndTime = CurrentData.EndTime;
		NewRow.Duration = CurrentData.WorkHoursQuantity;
		NewRow.BreakHours = CurrentData.TimeBreak;
		
	EndIf;
	
	ThisForm.Modified = True;
	
EndProcedure

&AtClient
Procedure AdditionalFillingSettingsBeforeRowChange(Item, Cancel)
	
	CurrentData = Items.AdditionalFillingSettings.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	ВремяНачалаДоИзменения = CurrentData.BeginTime;
	ВремяОкончанияДоИзменения = CurrentData.EndTime;
	КоличествоРабочихЧасовДоИзменения = CurrentData.WorkHoursQuantity;
	
EndProcedure

&AtClient
Procedure AdditionalFillingSettingsOnChange(Item)
	ScheduleChanged = True;
	ThisForm.Modified = True;
EndProcedure













