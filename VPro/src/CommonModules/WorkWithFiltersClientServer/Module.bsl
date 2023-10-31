
Procedure SetFilterByPeriod(FilterList, StartDate, EndDate, FieldFilterName = "Date") Export
	
	// Filter by period
	GroupFilterByPeriod = CommonUseClientServer.CreateGroupOfFilterItems(
		FilterList.Items,
		"Period",
		DataCompositionFilterItemsGroupType.AndGroup);
	
	CommonUseClientServer.AddCompositionItem(
		GroupFilterByPeriod,
		FieldFilterName,
		DataCompositionComparisonType.GreaterOrEqual,
		StartDate,
		"StartDate",
		ValueIsFilled(StartDate));
	
	CommonUseClientServer.AddCompositionItem(
		GroupFilterByPeriod,
		FieldFilterName,
		DataCompositionComparisonType.LessOrEqual,
		EndDate,
		"EndDate",
		ValueIsFilled(EndDate));
		
EndProcedure
	
Function RefreshPeriodPresentation(Period) Export
	
	If Not ValueIsFilled(Period) Or (Not ValueIsFilled(Period.StartDate) And Not ValueIsFilled(Period.EndDate)) Then
		PeriodPresentation = NStr("en='Period: during all this time';ru='Период: за все время';vi='Kỳ: toàn thời gian'");
	Else
		EndDate = ?(ValueIsFilled(Period.EndDate), EndOfDay(Period.EndDate), Period.EndDate);
		If EndDate < Period.StartDate Then
			#If Client Then
			SmallBusinessClient.ShowMessageAboutError(Undefined, NStr("en='Selected date end of the period, which is less than the start date!';ru='Выбрана дата окончания периода, которая меньше даты начала!';vi='Đã chọn ngày cuối kỳ nhỏ hơn ngày đầu kỳ!'"));
			#EndIf
			PeriodPresentation = NStr("en='from ';ru='с ';vi='từ '")+Format(Period.StartDate,"DF=dd.MM.yyyy");
		Else
			PeriodPresentation = NStr("en='for ';ru='за ';vi='cho '")+Lower(PeriodPresentation(Period.StartDate, EndDate));
		EndIf; 
	EndIf;
	
	Return PeriodPresentation;
	
EndFunction

