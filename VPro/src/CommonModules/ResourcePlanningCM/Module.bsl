// Возвращает расписание загрузки ресурсов.
//
Function GetResourcesWorkImportSchedule(ResourcesList, BeginOfPeriod, EndOfPeriod) Export
	
	ListPeriodDates = New ValueList;
	
	CounterDays = BeginOfPeriod;
	
	While BegOfDay(CounterDays) <= BegOfDay(EndOfPeriod) Do
		ListPeriodDates.Add(BegOfDay(CounterDays));
		CounterDays = CounterDays + 86400;
	EndDo;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ResourcesWorkSchedules.Period AS Period,
	|	ResourcesWorkSchedules.WorkSchedule AS WorkSchedule,
	|	ResourcesWorkSchedules.EnterpriseResource AS EnterpriseResource
	|INTO Total
	|FROM
	|	InformationRegister.ResourcesWorkSchedules AS ResourcesWorkSchedules
	|WHERE
	|	NOT ResourcesWorkSchedules.EnterpriseResource.UseEmployeeGraph
	|	AND NOT ResourcesWorkSchedules.EnterpriseResource.NotValid
	|
	|UNION
	|
	|SELECT
	|	Employees.Period,
	|	Employees.WorkSchedule,
	|	KeyResources.Ref
	|FROM
	|	Catalog.KeyResources AS KeyResources
	|		LEFT JOIN InformationRegister.Employees AS Employees
	|		ON KeyResources.ResourceValue = Employees.Employee
	|WHERE
	|	NOT KeyResources.NotValid
	|	AND KeyResources.UseEmployeeGraph
	|
	|UNION
	|
	|SELECT
	|	Employees.Period,
	|	Employees.WorkSchedule,
	|	KeyResources.Ref
	|FROM
	|	Catalog.KeyResources AS KeyResources
	|		LEFT JOIN InformationRegister.Employees AS Employees
	|		ON KeyResources.ResourceValue = Employees.Employee
	|WHERE
	|	VALUETYPE(KeyResources.ResourceValue) = TYPE(Catalog.Employees)
	|	AND NOT KeyResources.NotValid
	|	AND NOT KeyResources.UseEmployeeGraph
	|	AND NOT KeyResources.Ref IN
	|				(SELECT
	|					ResourcesWorkSchedules.EnterpriseResource AS Ref
	|				FROM
	|					InformationRegister.ResourcesWorkSchedules AS ResourcesWorkSchedules
	|				WHERE
	|					NOT ResourcesWorkSchedules.EnterpriseResource.NotValid
	|					AND NOT ResourcesWorkSchedules.EnterpriseResource.UseEmployeeGraph)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Total.Period AS Period,
	|	Total.WorkSchedule AS WorkSchedule,
	|	Total.EnterpriseResource AS EnterpriseResource
	|FROM
	|	Total AS Total
	|
	|ORDER BY
	|	EnterpriseResource,
	|	Period DESC
	|TOTALS BY
	|	EnterpriseResource";
	
	QueryResult = Query.Execute();
	SelectionResource = QueryResult.Select(QueryResultIteration.ByGroups, "EnterpriseResource");
	
	TableOfSchedules = New ValueTable;
	
	Array = New Array;
	Array.Add(Type("Date"));
	TypeDescription = New TypeDescription(Array, ,);
	Array.Clear();
	
	TableOfSchedules.Columns.Add("Period", TypeDescription);
	
	Array = New Array;
	Array.Add(Type("CatalogRef.KeyResources"));
	TypeDescription = New TypeDescription(Array, ,);
	Array.Clear();
	
	TableOfSchedules.Columns.Add("EnterpriseResource", TypeDescription);
	
	Array = New Array;
	Array.Add(Type("CatalogRef.WorkSchedules"));
	TypeDescription = New TypeDescription(Array, ,);
	Array.Clear();
	
	TableOfSchedules.Columns.Add("WorkSchedule", TypeDescription);
	
	While SelectionResource.Next() Do
		
		ArrayOfScheduledDays = New Array();
		For Each ListIt In ListPeriodDates Do
			ArrayOfScheduledDays.Add(ListIt.Value);
		EndDo;
		
		Selection = SelectionResource.Select();
		While Selection.Next() Do
			
			If Not ValueIsFilled(Selection.Period) Then Continue EndIf;
			
			Ind = 0;
			While Ind <= ArrayOfScheduledDays.Count() - 1 Do
				
				If Selection.Period <= ArrayOfScheduledDays[Ind] Then
					
					NewRow = TableOfSchedules.Add();
					NewRow.EnterpriseResource = Selection.EnterpriseResource;
					NewRow.Period = ArrayOfScheduledDays[Ind];
					NewRow.WorkSchedule= Selection.WorkSchedule;
					ArrayOfScheduledDays.Delete(Ind);
					
				Else
					Ind = Ind + 1;
				EndIf;
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
	ResourcesWithoutGraph = New Array;
	CommonListResources = New Array;
	
	For Each ArrayElement In ResourcesList Do
		CommonListResources.Add(ArrayElement);
	EndDo;
	
	For Each ListResource In CommonListResources Do
		
		FoundValue = TableOfSchedules.Find(ListResource);
		
		If FoundValue = Undefined Then
			ResourcesWithoutGraph.Add(ListResource);
			ElementToDelete = ResourcesList.Find(ListResource);
			ResourcesList.Delete(ElementToDelete);
		EndIf;
		
	EndDo;
	
	TempTablesManager = New TempTablesManager;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT ALLOWED
	|	KeyResources.Ref AS EnterpriseResource,
	|	KeyResources.Capacity AS Capacity,
	|	KeyResources.Description AS ResourceDescription
	|INTO EnterpriseResourceTempTable
	|FROM
	|	Catalog.KeyResources AS KeyResources
	|WHERE
	|	NOT KeyResources.DeletionMark
	|	AND KeyResources.Ref IN(&FilterKeyResourcesList)
	|	AND NOT KeyResources.NotValid
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	KeyResources.Ref AS EnterpriseResource,
	|	KeyResources.Capacity AS Capacity,
	|	KeyResources.Description AS ResourceDescription
	|INTO ResourcesWithoutGraph
	|FROM
	|	Catalog.KeyResources AS KeyResources
	|WHERE
	|	KeyResources.Ref IN(&ResourcesWithoutGraph)
	|	AND NOT KeyResources.NotValid
	|	AND NOT KeyResources.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TableOfSchedules.Period AS Period,
	|	TableOfSchedules.EnterpriseResource AS EnterpriseResource,
	|	TableOfSchedules.WorkSchedule AS WorkSchedule
	|INTO SchedulesTempTable
	|FROM
	|	&TableOfSchedules AS TableOfSchedules
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	EnterpriseResourceTempTable.EnterpriseResource AS EnterpriseResource,
	|	EnterpriseResourceTempTable.Capacity AS Capacity,
	|	SchedulesTempTable.Period AS Period,
	|	SchedulesTempTable.WorkSchedule AS WorkSchedule,
	|	CASE
	|		WHEN NOT DeviationFromResourcesWorkSchedules.BeginTime = DATETIME(1, 1, 1, 0, 0, 0)
	|			THEN YEAR(DeviationFromResourcesWorkSchedules.BeginTime)
	|		ELSE YEAR(WorkSchedules.BeginTime)
	|	END AS Year,
	|	CASE
	|		WHEN NOT DeviationFromResourcesWorkSchedules.BeginTime = DATETIME(1, 1, 1, 0, 0, 0)
	|			THEN MONTH(DeviationFromResourcesWorkSchedules.BeginTime)
	|		ELSE MONTH(WorkSchedules.BeginTime)
	|	END AS Month,
	|	CASE
	|		WHEN ISNULL(DeviationFromResourcesWorkSchedules.EndTime, 0) = 0
	|			THEN CASE
	|					WHEN NOT DATEDIFF(BEGINOFPERIOD(WorkSchedules.EndTime, MINUTE), WorkSchedules.EndTime, SECOND) = 0
	|						THEN DATEADD(BEGINOFPERIOD(WorkSchedules.EndTime, MINUTE), SECOND, 60)
	|					ELSE WorkSchedules.EndTime
	|				END
	|		ELSE CASE
	|				WHEN NOT DATEDIFF(BEGINOFPERIOD(DeviationFromResourcesWorkSchedules.EndTime, MINUTE), DeviationFromResourcesWorkSchedules.EndTime, SECOND) = 0
	|					THEN DATEADD(BEGINOFPERIOD(DeviationFromResourcesWorkSchedules.EndTime, MINUTE), SECOND, 60)
	|				ELSE DeviationFromResourcesWorkSchedules.EndTime
	|			END
	|	END AS WorkPeriodPerDayEnd,
	|	CASE
	|		WHEN ISNULL(DeviationFromResourcesWorkSchedules.BeginTime, 0) = 0
	|			THEN CASE
	|					WHEN NOT DATEDIFF(BEGINOFPERIOD(WorkSchedules.BeginTime, MINUTE), WorkSchedules.BeginTime, SECOND) = 0
	|						THEN DATEADD(BEGINOFPERIOD(WorkSchedules.BeginTime, MINUTE), SECOND, 60)
	|					ELSE WorkSchedules.BeginTime
	|				END
	|		ELSE CASE
	|				WHEN NOT DATEDIFF(BEGINOFPERIOD(DeviationFromResourcesWorkSchedules.BeginTime, MINUTE), DeviationFromResourcesWorkSchedules.BeginTime, SECOND) = 0
	|					THEN DATEADD(BEGINOFPERIOD(DeviationFromResourcesWorkSchedules.BeginTime, MINUTE), SECOND, 60)
	|				ELSE DeviationFromResourcesWorkSchedules.BeginTime
	|			END
	|	END AS BeginWorkPeriodInDay
	|FROM
	|	EnterpriseResourceTempTable AS EnterpriseResourceTempTable
	|		LEFT JOIN SchedulesTempTable AS SchedulesTempTable
	|		ON EnterpriseResourceTempTable.EnterpriseResource = SchedulesTempTable.EnterpriseResource
	|		LEFT JOIN InformationRegister.WorkSchedules AS WorkSchedules
	|		ON (SchedulesTempTable.WorkSchedule = WorkSchedules.WorkSchedule)
	|			AND (WorkSchedules.BeginTime BETWEEN &StartDate AND &EndDate)
	|			AND (WorkSchedules.EndTime BETWEEN &StartDate AND &EndDate)
	|			AND (SchedulesTempTable.Period = BEGINOFPERIOD(WorkSchedules.BeginTime, Day))
	|			AND (SchedulesTempTable.Period = BEGINOFPERIOD(WorkSchedules.EndTime, Day))
	|		LEFT JOIN InformationRegister.DeviationFromResourcesWorkSchedules AS DeviationFromResourcesWorkSchedules
	|		ON EnterpriseResourceTempTable.EnterpriseResource = DeviationFromResourcesWorkSchedules.EnterpriseResource
	|			AND (SchedulesTempTable.Period = BEGINOFPERIOD(DeviationFromResourcesWorkSchedules.Day, Day))
	|			AND (DeviationFromResourcesWorkSchedules.BeginTime BETWEEN &StartDate AND &EndDate)
	|			AND (DeviationFromResourcesWorkSchedules.EndTime BETWEEN &StartDate AND &EndDate)
	|
	|UNION ALL
	|
	|SELECT
	|	ResourcesWithoutGraph.EnterpriseResource,
	|	ResourcesWithoutGraph.Capacity,
	|	DeviationFromResourcesWorkSchedules.Day,
	|	""GraphNotSpecified"",
	|	YEAR(DeviationFromResourcesWorkSchedules.BeginTime),
	|	MONTH(DeviationFromResourcesWorkSchedules.BeginTime),
	|	CASE
	|		WHEN NOT DATEDIFF(BEGINOFPERIOD(DeviationFromResourcesWorkSchedules.EndTime, MINUTE), DeviationFromResourcesWorkSchedules.EndTime, SECOND) = 0
	|			THEN DATEADD(BEGINOFPERIOD(DeviationFromResourcesWorkSchedules.EndTime, MINUTE), SECOND, 60)
	|		ELSE DeviationFromResourcesWorkSchedules.EndTime
	|	END,
	|	CASE
	|		WHEN NOT DATEDIFF(BEGINOFPERIOD(DeviationFromResourcesWorkSchedules.BeginTime, MINUTE), DeviationFromResourcesWorkSchedules.BeginTime, SECOND) = 0
	|			THEN DATEADD(BEGINOFPERIOD(DeviationFromResourcesWorkSchedules.BeginTime, MINUTE), SECOND, 60)
	|		ELSE DeviationFromResourcesWorkSchedules.BeginTime
	|	END
	|FROM
	|	ResourcesWithoutGraph AS ResourcesWithoutGraph
	|		LEFT JOIN InformationRegister.DeviationFromResourcesWorkSchedules AS DeviationFromResourcesWorkSchedules
	|		ON ResourcesWithoutGraph.EnterpriseResource = DeviationFromResourcesWorkSchedules.EnterpriseResource
	|			AND (DeviationFromResourcesWorkSchedules.BeginTime BETWEEN &StartDate AND &EndDate)
	|			AND (DeviationFromResourcesWorkSchedules.EndTime BETWEEN &StartDate AND &EndDate)
	|
	|ORDER BY
	|	BeginWorkPeriodInDay
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	EnterpriseResourceTempTable.EnterpriseResource AS EnterpriseResource,
	|	EnterpriseResourceTempTable.Capacity AS Capacity,
	|	EnterpriseResourceTempTable.ResourceDescription AS ResourceDescription
	|INTO CommonResouorceTable
	|FROM
	|	EnterpriseResourceTempTable AS EnterpriseResourceTempTable
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	ResourcesWithoutGraph.EnterpriseResource,
	|	ResourcesWithoutGraph.Capacity,
	|	ResourcesWithoutGraph.ResourceDescription
	|FROM
	|	ResourcesWithoutGraph AS ResourcesWithoutGraph
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	NestedQuery.Ref AS Ref,
	|	NestedQuery.Counterparty AS Counterparty,
	|	NestedQuery.Department AS Department,
	|	NestedQuery.Responsible AS Responsible,
	|	NestedQuery.Start AS BeginTime,
	|	NestedQuery.Finish AS EndTime,
	|	NestedQuery.Capacity AS Loading,
	|	MONTH(NestedQuery.Start) AS Month,
	|	YEAR(NestedQuery.Start) AS Year,
	|	BEGINOFPERIOD(NestedQuery.Start, DAY) AS Period,
	|	DATEDIFF(NestedQuery.Start, NestedQuery.Finish, SECOND) / 300 AS CellsQuantity,
	|	NestedQuery.NumberRowResourceTable AS LineNumber,
	|	CommonResouorceTable.EnterpriseResource AS EnterpriseResource,
	|	CommonResouorceTable.Capacity AS Capacity
	|FROM
	|	CommonResouorceTable AS CommonResouorceTable
	|		LEFT JOIN (SELECT
	|			ScheduleLoadingResources.Recorder AS Ref,
	|			ScheduleLoadingResources.EnterpriseResource AS EnterpriseResource,
	|			ScheduleLoadingResources.Capacity AS Capacity,
	|			CASE
	|				WHEN NOT DATEDIFF(BEGINOFPERIOD(ScheduleLoadingResources.Start, MINUTE), ScheduleLoadingResources.Start, SECOND) = 0
	|					THEN DATEADD(BEGINOFPERIOD(ScheduleLoadingResources.Start, MINUTE), SECOND, 60)
	|				ELSE ScheduleLoadingResources.Start
	|			END AS Start,
	|			CASE
	|				WHEN NOT DATEDIFF(BEGINOFPERIOD(ScheduleLoadingResources.Finish, MINUTE), ScheduleLoadingResources.Finish, SECOND) = 0
	|					THEN DATEADD(BEGINOFPERIOD(ScheduleLoadingResources.Finish, MINUTE), SECOND, 60)
	|				ELSE ScheduleLoadingResources.Finish
	|			END AS Finish,
	|			ScheduleLoadingResources.Counterparty AS Counterparty,
	|			ScheduleLoadingResources.Responsible AS Responsible,
	|			ScheduleLoadingResources.Department AS Department,
	|			ScheduleLoadingResources.NumberRowResourceTable AS NumberRowResourceTable
	|		FROM
	|			InformationRegister.ScheduleLoadingResources AS ScheduleLoadingResources
	|		WHERE
	|			ScheduleLoadingResources.EnterpriseResource IN(&CommonListResources)
	|			AND ScheduleLoadingResources.Start BETWEEN &StartDate AND &EndDate
	|			AND ScheduleLoadingResources.Finish BETWEEN &StartDate AND &EndDate) AS NestedQuery
	|		ON CommonResouorceTable.EnterpriseResource = NestedQuery.EnterpriseResource";
	
	Query.SetParameter("StartDate", BegOfDay(BeginOfPeriod));
	Query.SetParameter("EndDate", EndOfDay(EndOfPeriod));
	Query.SetParameter("FilterKeyResourcesList", ResourcesList);
	Query.SetParameter("TableOfSchedules", TableOfSchedules);
	Query.SetParameter("ResourcesWithoutGraph", ResourcesWithoutGraph);
	Query.SetParameter("CommonListResources", CommonListResources);
	
	ReturnStructure = New Structure;
	
	ResourcesDataPacket = Query.ExecuteBatch();
	
	WorkPeriods = ResourcesDataPacket[3].Unload();
	ResourcePlanningCM.CheckIntervalBoarders(WorkPeriods, True);
	
	ScheduleLoading = ResourcesDataPacket[5].Unload();
	ResourcePlanningCM.CheckIntervalBoarders(ScheduleLoading);
	
	ReturnStructure.Insert("WorkPeriods", WorkPeriods);
	ReturnStructure.Insert("ScheduleLoading", ScheduleLoading);
	
	Return ReturnStructure;;
	
EndFunction // ПолучитьРасписаниеЗагрузкиРесурсов()

//Возвращает структуру с минимальным значением начала и максимальным значением окончания интервала
//
Function MaxIntervalBoarders(IntervalsTable, ColumnNameBegin, ColumnNameEnd) Export
	
	If Not IntervalsTable.Count() Then Return Undefined EndIf;
	
	IntervalBegin = IntervalsTable[0][ColumnNameBegin];
	IntervalEnd = Date(1,1,1);
	
	For Each TableRow In IntervalsTable Do
		
		If ValueIsFilled(TableRow[ColumnNameBegin])
			And TableRow[ColumnNameBegin] < IntervalBegin Then
			IntervalBegin = TableRow[ColumnNameBegin];
		EndIf;
		
		If ValueIsFilled(TableRow[ColumnNameEnd])
			And TableRow[ColumnNameEnd] > IntervalEnd Then
			IntervalEnd = TableRow[ColumnNameEnd];
		EndIf;
		
	EndDo;
	
	StructureIntervals = New Structure("IntervalBegin, IntervalEnd", IntervalBegin, IntervalEnd);
	
	Return StructureIntervals;
	
EndFunction

//Возвращает документы по ресурсу за указанный период
//
Function DocumentTablePerPeriod(RowsByResource, IntervalBegin, IntervalEnding, MultiplicityPlanning, DayPeriod = False) Export
	
	If DayPeriod Then
		CheckingIntervalEnd = EndOfDay(IntervalBegin);
	ElsIf Not IntervalBegin = IntervalEnding
		Then
		CheckingIntervalEnd = IntervalEnding;
	Else
		
		CheckingIntervalEnd = IntervalBegin + MultiplicityPlanning*60;
	EndIf;
	
	DocumentsTable = New ValueTable;
	DocumentsTable.Columns.Add("Ref");
	DocumentsTable.Columns.Add("Loading");
	DocumentsTable.Columns.Add("BeginTime");
	DocumentsTable.Columns.Add("EndTime");
	DocumentsTable.Columns.Add("LineNumber");
	DocumentsTable.Columns.Add("CellsQuantity");
	
	For Each TablePeriod In RowsByResource Do
		
		If Not ValueIsFilled(TablePeriod.Ref) Then Continue EndIf;
		If TablePeriod.BeginTime > CheckingIntervalEnd Then Continue EndIf;
		
		If TablePeriod.EndTime <= CheckingIntervalEnd And TablePeriod.BeginTime>=IntervalBegin Then
			
			NewRow = DocumentsTable.Add();
			NewRow.Ref = TablePeriod.Ref;
			NewRow.Loading = TablePeriod.Loading;
			NewRow.BeginTime = TablePeriod.BeginTime;
			NewRow.EndTime = TablePeriod.EndTime;
			NewRow.LineNumber = TablePeriod.LineNumber;
			NewRow.CellsQuantity = TablePeriod.CellsQuantity;
			
			Continue;
			
		EndIf;
		
		If TablePeriod.EndTime <= CheckingIntervalEnd And TablePeriod.EndTime > IntervalBegin Then
			
			NewRow = DocumentsTable.Add();
			NewRow.Ref = TablePeriod.Ref;
			NewRow.Loading = TablePeriod.Loading;
			NewRow.BeginTime = TablePeriod.BeginTime;
			NewRow.EndTime = TablePeriod.EndTime;
			NewRow.LineNumber = TablePeriod.LineNumber;
			NewRow.CellsQuantity = TablePeriod.CellsQuantity;
			
			Continue;
			
		EndIf;
		
		If TablePeriod.BeginTime>=IntervalBegin And TablePeriod.BeginTime<CheckingIntervalEnd Then
			
			NewRow = DocumentsTable.Add();
			NewRow.Ref = TablePeriod.Ref;
			NewRow.Loading = TablePeriod.Loading;
			NewRow.BeginTime = TablePeriod.BeginTime;
			NewRow.EndTime = TablePeriod.EndTime;
			NewRow.LineNumber = TablePeriod.LineNumber;
			NewRow.CellsQuantity = TablePeriod.CellsQuantity;
			
			Continue;
			
		EndIf;
		
		If (IntervalBegin>=TablePeriod.BeginTime And IntervalBegin< TablePeriod.EndTime) Then
			
			NewRow = DocumentsTable.Add();
			NewRow.Ref = TablePeriod.Ref;
			NewRow.Loading = TablePeriod.Loading;
			NewRow.BeginTime = TablePeriod.BeginTime;
			NewRow.EndTime = TablePeriod.EndTime;
			NewRow.LineNumber = TablePeriod.LineNumber;
			NewRow.CellsQuantity = TablePeriod.CellsQuantity;
			
		EndIf;
	EndDo;
	
	Return DocumentsTable;
	
EndFunction

//Возвращает итоги по интервалу в рамках дня
Function TotalsByDay(OutputDay, Multiplicity, WorkPeriods, Resource, ScheduleLoading, DetailsDocuments, IntervalMatrix, FoundStrings = Undefined) Export
	
	ReturnStructure = New Structure();
	
	MultiplicitySec = Multiplicity*60;
	
	MultiplicitySec = ?(MultiplicitySec = 0, 300, MultiplicitySec);
	
	FilterParameters = New Structure("Period, EnterpriseResource", BegOfDay(OutputDay), Resource);
	FoundRowsPerDay = WorkPeriods.FindRows(FilterParameters);
	
	WorkPeriodsPerDay = WorkPeriods.CopyColumns();
	
	For Each FoundString In FoundRowsPerDay Do
		
		NewRow = WorkPeriodsPerDay.Add();
		FillPropertyValues(NewRow, FoundString);
		
	EndDo;
	
	WorkPeriodsPerDay.GroupBy("BeginWorkPeriodInDay, WorkPeriodPerDayEnd");
	PeriodsQuantity = WorkPeriodsPerDay.Count();
	
	DocumentPerDay = DetailsDocuments.Copy();
	DocumentPerDay.GroupBy("Ref, BeginTime, EndTime, CellsQuantity");
	
	If Not DocumentPerDay.Count() And (PeriodsQuantity = 0 
		Or (PeriodsQuantity = 1 And (Not ValueIsFilled(WorkPeriodsPerDay[0].BeginWorkPeriodInDay)
		Or Not ValueIsFilled(WorkPeriodsPerDay[0].WorkPeriodPerDayEnd)))) Then
		
		ReturnStructure.Insert("Loading", 0);
		ReturnStructure.Insert("IntervalsWithoutLoading", 0);
		ReturnStructure.Insert("IntervalsWithLoading", 0);
		ReturnStructure.Insert("IsExcess ", False);
		
		Return ReturnStructure;
		
	EndIf;
	
	WorkIntervalsTable = New ValueTable;
	WorkIntervalsTable.Columns.Add("IntervalBegin");
	WorkIntervalsTable.Columns.Add("IntervalEnd");
	WorkIntervalsTable.Columns.Add("CellsInIntervalQuantity");
	WorkIntervalsTable.Columns.Add("ByDocument");
	
	MapCellTime = New Map;
	IntervalMatrix.Clear();
	
	CellIndex = 1;
	IntervalTime = BegOfDay(OutputDay);
	IntervalEnding = EndOfDay(OutputDay)+1;
	
	While IntervalTime <= IntervalEnding Do

		MapCellTime.Insert(IntervalTime, CellIndex);
		
		IntervalTime = IntervalTime + 300;
		CellIndex = CellIndex + 1;
	EndDo;
	
	RowMatrix = IntervalMatrix.Add();
	
	For Each workPeriod In WorkPeriodsPerDay Do
		
		BeginOfPeriod = workPeriod.BeginWorkPeriodInDay;
		EndOfPeriod = workPeriod.WorkPeriodPerDayEnd;
		
		If Not ValueIsFilled(BeginOfPeriod) Or Not ValueIsFilled(EndOfPeriod) Then Continue EndIf;
		
		EndOfPeriod = ?(EndOfPeriod = EndOfDay(EndOfPeriod), EndOfPeriod+1, EndOfPeriod);
		
		ColumnMatrixBeginPeriod = MapCellTime.Get(BeginOfPeriod);
		ColumnMatrixEndPeriod = MapCellTime.Get(EndOfPeriod);
		
		While BeginOfPeriod <= EndOfPeriod Do
			
			IntervalEnd = BeginOfPeriod + MultiplicitySec;
			
			NewRow = WorkIntervalsTable.Add();
			NewRow.IntervalBegin = BeginOfPeriod;
			NewRow.IntervalEnd = ?(IntervalEnd>EndOfPeriod, EndOfPeriod, IntervalEnd);
			NewRow.CellsInIntervalQuantity = (NewRow.IntervalEnd - NewRow.IntervalBegin)/300;
			NewRow.ByDocument = False;
			
			BeginOfPeriod = IntervalEnd;
		EndDo;
		
		While ColumnMatrixBeginPeriod < ColumnMatrixEndPeriod Do
			
			ColumnName = "Column"+String(ColumnMatrixBeginPeriod);
			
			RowMatrix[ColumnName] = 5000;
			ColumnMatrixBeginPeriod = ColumnMatrixBeginPeriod+1;
			
		EndDo;
		
	EndDo;
	
	PreviousDocument = Undefined;
	
	For Each Document In DocumentPerDay Do
		
		If Not Document.Ref = PreviousDocument Then
			RowMatrix = IntervalMatrix.Add();
		EndIf;
		
		EndTime = Document.EndTime;
		BeginTime = Document.BeginTime;
		
		If EndTime = EndOfDay(EndTime) Then
			EndTime = EndTime + 1;
		EndIf;
		
		ColumnMatrixBeginPeriod = MapCellTime.Get(BeginTime);
		ColumnMatrixEndPeriod = MapCellTime.Get(EndTime);
		
		While ColumnMatrixBeginPeriod < ColumnMatrixEndPeriod Do
			
			RowMatrix["Column"+String(ColumnMatrixBeginPeriod)] = 1;
			ColumnMatrixBeginPeriod = ColumnMatrixBeginPeriod+1;
			
		EndDo;
		
		PreviousDocument = Document.Ref;
		
	EndDo;
	
	ColumnIndex = 1;
	UnitedIntervalsQuantity = 0;
	
	IntervalTime = BegOfDay(OutputDay);
	
	TimeBeginOfInterval = IntervalTime;
	
	CellsInMultiplicity = Multiplicity/5;
	
	While IntervalTime <= IntervalEnding Do
		
		ColumnName = "Column"+ ColumnIndex;
		
		TotalByInterval = IntervalMatrix.Total(ColumnName);
		
		ItCellForUnite = ValueIsFilled(TotalByInterval) And TotalByInterval<5000;
		
		If ItCellForUnite And Not UnitedIntervalsQuantity = CellsInMultiplicity Then
			
			If UnitedIntervalsQuantity = 0 Then
				NewRow = WorkIntervalsTable.Add();
				NewRow.IntervalBegin = IntervalTime;
				NewRow.ByDocument = True;
			EndIf;
			UnitedIntervalsQuantity =UnitedIntervalsQuantity + 1;
			
		ElsIf ItCellForUnite And UnitedIntervalsQuantity = CellsInMultiplicity Then
			
			NewRow.IntervalEnd = IntervalTime;
			NewRow.CellsInIntervalQuantity = (NewRow.IntervalEnd - NewRow.IntervalBegin)/300;
			
			NewRow = WorkIntervalsTable.Add();
			NewRow.IntervalBegin = IntervalTime;
			NewRow.ByDocument = True;
			
			UnitedIntervalsQuantity = 1;
			
		ElsIf ValueIsFilled(UnitedIntervalsQuantity) Then
			NewRow.IntervalEnd = IntervalTime;
			NewRow.CellsInIntervalQuantity = (NewRow.IntervalEnd - NewRow.IntervalBegin)/300;
			UnitedIntervalsQuantity = 0;
		EndIf;
		
		IntervalTime = IntervalTime + 300;
		ColumnIndex = ColumnIndex + 1;
	EndDo;
	
	WorkIntervalsTable.Sort("IntervalBegin Asc");
	
	TotalLoadings = 0;
	IntervalsWithoutLoading = 0;
	IntervalsWithLoading = 0;
	IsExcess  = False;
	Capacity = Resource.Capacity;
	
	For Each WorkInterval In WorkIntervalsTable Do;
		
		If WorkInterval.CellsInIntervalQuantity = 0 Then Continue EndIf;
		
		DocumentPerPeriod = DocumentTablePerPeriod(FoundStrings, WorkInterval.IntervalBegin, WorkInterval.IntervalEnd, Multiplicity);
		LoadingForInterval = MaxByLoading(DocumentPerPeriod, WorkInterval.IntervalBegin, WorkInterval.IntervalEnd, WorkInterval.CellsInIntervalQuantity, IntervalMatrix);
		IntervalsWithoutLoading = ?(LoadingForInterval = 0, IntervalsWithoutLoading+1, IntervalsWithoutLoading);
		IntervalsWithLoading = ?(Not LoadingForInterval = 0 And Not WorkInterval.ByDocument, IntervalsWithLoading+1, IntervalsWithLoading);
		IsExcess  = ?(LoadingForInterval>Capacity, True, IsExcess );
		
		TotalLoadings = TotalLoadings + LoadingForInterval;
		
	EndDo;
	
	ReturnStructure.Insert("Loading", TotalLoadings);
	ReturnStructure.Insert("IntervalsWithoutLoading", IntervalsWithoutLoading);
	ReturnStructure.Insert("IntervalsWithLoading", IntervalsWithLoading);
	ReturnStructure.Insert("IsExcess ", IsExcess );
	
	Return ReturnStructure;
	
	
EndFunction

//Возвращает максимальную загрузку в рамках интервала
//
Function MaxByLoading(DetailsDocuments, IntervalBegin, IntervalEnding, CellsInIntervalQuantity, IntervalTableBy5Min) Export
	
	If Not DetailsDocuments.Count() Then Return 0 EndIf;
	
	MaxLoading = 0;
	
	MapCellTime = New Map;
	
	IntervalTableBy5Min.Clear();
	
	CellIndex = 1;
	IntervalBegin = ?(Second(IntervalBegin) = 0, IntervalBegin, IntervalBegin - Second(IntervalBegin));
	IntervalTime = IntervalBegin;
	
	If IntervalEnding = EndOfDay(IntervalEnding) Then
		IntervalEnding = IntervalEnding + 1;
	EndIf;
	
	While IntervalTime <= IntervalEnding Do
		MapCellTime.Insert(IntervalTime, CellIndex);
		
		IntervalTime = IntervalTime + 300;
		CellIndex = CellIndex + 1;
	EndDo;
	
	For Each RowDetailsDocument In DetailsDocuments Do
		
		If RowDetailsDocument.BeginTime>=IntervalBegin Then
			TimeCellInterval = RowDetailsDocument.BeginTime;
			CellsQuantity = RowDetailsDocument.CellsQuantity;
		Else
			TimeCellInterval = IntervalBegin;
			CellsQuantity = (RowDetailsDocument.EndTime - IntervalBegin)/300;
		EndIf;
		
		IntervalStartCellNumber = MapCellTime.Get(TimeCellInterval);
		
		IntervalEndCellNumber = IntervalStartCellNumber + (CellsQuantity-1);
		IntervalEndCellNumber = ?(IntervalEndCellNumber > CellsInIntervalQuantity, CellsInIntervalQuantity, IntervalEndCellNumber);
		
		NewRow = IntervalTableBy5Min.Add();
		
		While IntervalStartCellNumber <= IntervalEndCellNumber Do
			
			ColumnName = "Column"+String(IntervalStartCellNumber);
			
			NewRow[ColumnName] = RowDetailsDocument.Loading;
			
			IntervalStartCellNumber = IntervalStartCellNumber + 1;
			
		EndDo;
		
	EndDo;
	
	For Each TableColumn In IntervalTableBy5Min.Columns Do
		ColumnTotal = IntervalTableBy5Min.Total(TableColumn);
		MaxLoading = ?(MaxLoading<ColumnTotal, ColumnTotal, MaxLoading);
	EndDo;
	
	Return MaxLoading;
	
EndFunction

Function CreateIntervalColumns() Export
	
	IntervalMatrix = New ValueTable;
	
	For ColumnIndex = 1 To 289 Do
		IntervalMatrix.Columns.Add("Column"+String(ColumnIndex));
	EndDo;
	
	Return IntervalMatrix;
	
EndFunction

//Осуществляет контроль параметров загрузки в зависимости от входящих условий
//
Procedure ControlParametersResourcesLoading(CheckOverLoading = False,CheckingLoadingIntervalBoarders = False,SelectedResources, Object) Export
	
	If Not SelectedResources.Count() Or AreFillingErrors(SelectedResources, Object) Then Return EndIf; 
	
	ResourcesTable = SelectedResources.Unload(,"EnterpriseResource");
	ResourcesArray = ResourcesTable.UnloadColumn("EnterpriseResource");
	ExtendedTable = DecomposeRowsBySchedule(SelectedResources);
	CheckingPeriod = ResourcePlanningCM.MaxIntervalBoarders(ExtendedTable, "BeginOfPeriod", "EndOfPeriod");
	ResourcesDataPacket = ResourcePlanningCM.GetResourcesWorkImportSchedule(ResourcesArray, CheckingPeriod.IntervalBegin, CheckingPeriod.IntervalEnd);
	
	ResourcesTable = ExtendedTable.Copy(,"Resource, Period, BeginOfPeriod, EndOfPeriod, Loading");
	ResourcesTable.GroupBy("Resource, Period, BeginOfPeriod, EndOfPeriod, Loading");
	
	If CheckOverLoading Then
		ControlLoadingOverload(ResourcesDataPacket, ResourcesTable, Object);
	EndIf;
	
	If CheckingLoadingIntervalBoarders Then
		ControlBoarderIntervalOnSchedule(ResourcesDataPacket, ResourcesTable, Object);
	EndIf;
	
EndProcedure

//Осуществляет контроль превышения загрузки по интервалам
//
Procedure ControlLoadingOverload(ResourcesDataPacket, ResourcesTable, Object)
	
	ScheduleLoading = ResourcesDataPacket.ScheduleLoading;
	
	HasErrors = False;
	
	DocumentHeld = Object.Object.Posted;
	
	DetailsLoading = ?(DocumentHeld, "Loading с acount cur. document", "Current loading");
	
	IntervalTableBy5Min = CreateIntervalColumns();
	
	For Each TableRow In ResourcesTable Do
		
		EndOfPeriod = ?(TableRow.EndOfPeriod = EndOfDay(TableRow.EndOfPeriod)
		, TableRow.EndOfPeriod + 1, TableRow.EndOfPeriod);
		
		MultiplicityPlanning = TableRow.Resource.MultiplicityPlanning;
		Capacity = TableRow.Resource.Capacity;
		
		FilterParameters = New Structure("EnterpriseResource, Period",TableRow.Resource,TableRow.Period);
		FoundStrings = ScheduleLoading.FindRows(FilterParameters);
		
		DocumentPerPeriod = DocumentTablePerPeriod(FoundStrings, TableRow.BeginOfPeriod, EndOfPeriod, MultiplicityPlanning);
		
		CellsInIntervalQuantity = (EndOfPeriod - TableRow.BeginOfPeriod)/300;
		
		LoadingForInterval = MaxByLoading(DocumentPerPeriod, TableRow.BeginOfPeriod, EndOfPeriod, CellsInIntervalQuantity, IntervalTableBy5Min);
		
		LoadingValue = ?(DocumentHeld, LoadingForInterval, LoadingForInterval+TableRow.Loading);
		
		If LoadingValue>Capacity Then
			
			Message = New UserMessage();
			Message.Text = NStr("en='Для %Resource% в период с %BeginOfPeriod% по %EndOfPeriod% есть превышение загрузки. %DetailsLoading%: %CurrentLoading%';ru='Для %Resource% в период с %BeginOfPeriod% по %EndOfPeriod% есть превышение загрузки. %DetailsLoading%: %CurrentLoading%';vi='Đối với %Resource% trong kỳ từ %BeginOfPeriod% đến %EndOfPeriod% có vượt tải. %DetailsLoading%: %CurrentLoading%'");
			Message.Text = StrReplace(Message.Text, "%Resource%", String(TableRow.Resource));
			Message.Text = StrReplace(Message.Text, "%BeginOfPeriod%", String(TableRow.BeginOfPeriod));
			Message.Text = StrReplace(Message.Text, "%EndOfPeriod%", String(TableRow.EndOfPeriod));
			Message.Text = StrReplace(Message.Text, "%CurrentLoading%", String(LoadingForInterval));
			Message.Text = StrReplace(Message.Text, "%DetailsLoading%", DetailsLoading);
			Message.Field = "SelectedResources";
			Message.SetData(Object);
			Message.Message();
			
			HasErrors = True;
			
		EndIf;
		
	EndDo;
	
	If Not HasErrors Then
		Message = New UserMessage();
		Message.Text = NStr("en='Ошибок превышения загрузки не обнаружено.';ru='Ошибок превышения загрузки не обнаружено.';vi='Lỗi quá tải không được phát hiện.'");
		Message.SetData(Object);
		Message.Message();
	EndIf;
	
EndProcedure

//Осуществляет контроль выхода интервалов загрузки за границы графика работы
//
Procedure ControlBoarderIntervalOnSchedule(ResourcesDataPacket, ResourcesTable, Object)
	
	WorkPeriods = ResourcesDataPacket.WorkPeriods;
	WorkPeriods.GroupBy("EnterpriseResource, BeginWorkPeriodInDay, WorkPeriodPerDayEnd");
	
	HasErrors = False;
	
	DocumentHeld = Object.Object.Posted;
	
	DetailsLoading = ?(DocumentHeld, "Loading с acount cur. document", "Current loading");
	
	IntervalTableBy5Min = CreateIntervalColumns();
	
	TextError = "";
	
	OutputOverBoarding = False;
	
	For Each TableRow In ResourcesTable Do
		
		If Not TableRow.Resource.ControlLoadingOnlyInWorkTime Then Continue EndIf;
		
		FilterParameters = New Structure("EnterpriseResource", TableRow.Resource);
		
		FoundStrings = WorkPeriods.FindRows(FilterParameters);
		
		For Each RowWorkCalendar In FoundStrings Do
			
			If Not ValueIsFilled(RowWorkCalendar.BeginWorkPeriodInDay) 
				Or Not ValueIsFilled(RowWorkCalendar.WorkPeriodPerDayEnd) Then 
				Continue;
			EndIf;
			
			If Not BegOfDay(TableRow.BeginOfPeriod) = BegOfDay(TableRow.EndOfPeriod) Then
				EndOfPeriod = EndOfDay(TableRow.BeginOfPeriod);
			Else
				EndOfPeriod = TableRow.EndOfPeriod;
			EndIf;
			
			If TableRow.BeginOfPeriod < RowWorkCalendar.BeginWorkPeriodInDay And EndOfPeriod >= RowWorkCalendar.WorkPeriodPerDayEnd Then
				
				TextError = TextError + NStr("en='Для %Resource% период с %BeginOfPeriod% по %EndOfPeriod% выходит за границы рабочего графика."
"';ru='Для %Resource% период с %BeginOfPeriod% по %EndOfPeriod% выходит за границы рабочего графика."
"';vi='Đối với %Resource% kỳ từ %BeginOfPeriod% đến %EndOfPeriod% vượt ra ngoài lịch làm việc."
"'");
				TextError = StrReplace(TextError, "%Resource%", String(TableRow.Resource));
				TextError = StrReplace(TextError, "%BeginOfPeriod%", String(TableRow.BeginOfPeriod));
				TextError = StrReplace(TextError, "%EndOfPeriod%", String(EndOfPeriod));
				OutputOverBoarding = True;
				Break;
				
			EndIf;
			
			If (TableRow.BeginOfPeriod >= RowWorkCalendar.BeginWorkPeriodInDay And TableRow.BeginOfPeriod < RowWorkCalendar.WorkPeriodPerDayEnd)
				And EndOfPeriod > RowWorkCalendar.WorkPeriodPerDayEnd Then
				
				TextError = TextError + NStr("en='Для %Resource% период с %BeginOfPeriod% по %EndOfPeriod% выходит за границы рабочего графика."
"';ru='Для %Resource% период с %BeginOfPeriod% по %EndOfPeriod% выходит за границы рабочего графика."
"';vi='Đối với %Resource% kỳ từ %BeginOfPeriod% đến %EndOfPeriod% vượt ra ngoài lịch làm việc."
"'");
				TextError = StrReplace(TextError, "%Resource%", String(TableRow.Resource));
				TextError = StrReplace(TextError, "%BeginOfPeriod%", String(TableRow.BeginOfPeriod));
				TextError = StrReplace(TextError, "%EndOfPeriod%", String(EndOfPeriod));
				OutputOverBoarding = True;
				Break;
				
			EndIf;
			
			If (EndOfPeriod > RowWorkCalendar.BeginWorkPeriodInDay And EndOfPeriod <= RowWorkCalendar.WorkPeriodPerDayEnd)
				And TableRow.BeginOfPeriod < RowWorkCalendar.BeginWorkPeriodInDay Then
				
				TextError = TextError + NStr("en='Для %Resource% период с %BeginOfPeriod% по %EndOfPeriod% выходит за границы рабочего графика."
"';ru='Для %Resource% период с %BeginOfPeriod% по %EndOfPeriod% выходит за границы рабочего графика."
"';vi='Đối với %Resource% kỳ từ %BeginOfPeriod% đến %EndOfPeriod% vượt ra ngoài lịch làm việc."
"'");
				TextError = StrReplace(TextError, "%Resource%", String(TableRow.Resource));
				TextError = StrReplace(TextError, "%BeginOfPeriod%", String(TableRow.BeginOfPeriod));
				TextError = StrReplace(TextError, "%EndOfPeriod%", String(EndOfPeriod));
				OutputOverBoarding = True;
				Break;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	If OutputOverBoarding Then
		
		Message = New UserMessage();
		Message.Text = TextError;
		Message.Field = "SelectedResources";
		Message.SetData(Object);
		Message.Message();
		
		HasErrors = True;
		
	EndIf;
	
	If Not HasErrors Then
		Message = New UserMessage();
		Message.Text = NStr("en='Границ загрузки вне графика работы не обнаружено.';ru='Границ загрузки вне графика работы не обнаружено.';vi='Không có ranh giới tải được tìm thấy bên ngoài lịch trình làm việc.'");
		Message.SetData(Object);
		Message.Message();
	EndIf;
	
	
	
EndProcedure

//Проверяет ошибки заполнения в ТЧ РесурсыПредприятия Документов Заказ-наряд и Заказ на производство
//
Function AreFillingErrors(SelectedResources, Object) Export
	
	IsError = False;
	LineNumber = 1;
	
	For Each RowResource In SelectedResources Do
		
		If Not ValueIsFilled(RowResource.EnterpriseResource) Then
			
			TextOfMessage = NStr("en='В строке №%Number% табл. части не указан ресурс.';ru='В строке №%Number% табл. части не указан ресурс.';vi='Trong dòng số %Number% của bảng tài nguyên không được chỉ định.'");
			TextOfMessage = StrReplace(TextOfMessage, "%Number%", LineNumber);
			SmallBusinessServer.ShowMessageAboutError(
			Object,
			TextOfMessage,
			"EnterpriseResources",
			LineNumber,
			"EnterpriseResource",
			IsError
			);
			
		EndIf;
		
		If Not ValueIsFilled(RowResource.Capacity) Then
			TextOfMessage = NStr("en='В строке №%Number% табл. части не указано значение загрузки.';ru='В строке №%Number% табл. части не указано значение загрузки.';vi='Trong dòng số %Number% của bảng giá trị tải xuống không được chỉ định.'");
			TextOfMessage = StrReplace(TextOfMessage, "%Number%", LineNumber);
			SmallBusinessServer.ShowMessageAboutError(
			Object,
			TextOfMessage,
			"EnterpriseResources",
			LineNumber,
			"Capacity",
			IsError
			);
		EndIf;
		
		If BegOfDay(RowResource.Start) = BegOfDay(RowResource.Finish) 
			And (Not RowResource.RepeatKind = Enums.ScheduleRepeatKind.NoRepeat And ValueIsFilled(RowResource.RepeatKind)) Then
			
			If Not ValueIsFilled(RowResource.CompleteKind) Then
				TextOfMessage = NStr("en='В строке №%Number% табл. части не указан вид окончания повторов.';ru='В строке №%Number% табл. части не указан вид окончания повторов.';vi='Trong dòng số %Number% của bảng loại kết thúc lặp lại không được chỉ định.'");
				TextOfMessage = StrReplace(TextOfMessage, "%Number%", LineNumber);
				SmallBusinessServer.ShowMessageAboutError(
				Object,
				TextOfMessage,
				"EnterpriseResources",
				LineNumber,
				"CompleteKind",
				IsError
				);
				Continue;
			EndIf;
			
			If Not ValueIsFilled(RowResource.CompleteAfter) Then
				TextOfMessage = NStr("en='В строке №%Number% табл. части не указано значение окончания повторов.';ru='В строке №%Number% табл. части не указано значение окончания повторов.';vi='Trong dòng số %Number% của bảng giá trị cuối cùng không được chỉ định.'");
				TextOfMessage = StrReplace(TextOfMessage, "%Number%", LineNumber);
				SmallBusinessServer.ShowMessageAboutError(
				Object,
				TextOfMessage,
				"EnterpriseResources",
				LineNumber,
				"CompleteAfter",
				IsError
				);
			EndIf;
			
		EndIf;
		
		LineNumber = LineNumber +1;
		
	EndDo;
	
	Return IsError;
	
EndFunction

//Раскладывает строки из ТЧ РесурсыПредприятия по расписанию в таблицу знаяений
//
Function DecomposeRowsBySchedule(ScheduleTable) Export
	
	ExtendedTable = New ValueTable;
	
	ExtendedTable.Columns.Add("Resource");
	ExtendedTable.Columns.Add("BeginOfPeriod");
	ExtendedTable.Columns.Add("EndOfPeriod");
	ExtendedTable.Columns.Add("Loading");
	ExtendedTable.Columns.Add("Period");
	
	For Each TimetableString In ScheduleTable Do
		
		Resource = TimetableString.EnterpriseResource;
		IntervalBegin = TimetableString.Start;
		IntervalEnd = TimetableString.Finish;
		CompleteAfter = TimetableString.CompleteAfter;
		RepeatInterval = TimetableString.RepeatInterval;
		Loading = TimetableString.Capacity;
		RepeatIndex = 0;
		
		If Not BegOfDay(IntervalBegin) = BegOfDay(IntervalEnd) Then
			
			CounterDay = IntervalBegin;
			
			While CounterDay<= BegOfDay(IntervalEnd) Do
				
				NewRow = ExtendedTable.Add();
				NewRow.BeginOfPeriod = CounterDay;
				
				NewRow.EndOfPeriod = ?(BegOfDay(CounterDay)= BegOfDay(IntervalEnd), IntervalEnd, EndOfDay(CounterDay));
				
				NewRow.Loading = Loading;
				NewRow.Resource = Resource;
				NewRow.Period = BegOfDay(CounterDay);
				
				CounterDay = BegOfDay(CounterDay+86401);
			EndDo;
			
			Continue;
		EndIf;
		
		If BegOfDay(IntervalBegin) = BegOfDay(IntervalEnd) 
			And (Not ValueIsFilled(TimetableString.RepeatKind) Or TimetableString.RepeatKind = Enums.ScheduleRepeatKind.NoRepeat) Then
			
			NewRow = ExtendedTable.Add();
			NewRow.BeginOfPeriod = IntervalBegin;
			NewRow.EndOfPeriod = IntervalEnd;
			NewRow.Loading = Loading;
			NewRow.Resource = Resource;
			NewRow.Period = BegOfDay(IntervalBegin);
			
			Continue;
		EndIf;
		
		If TimetableString.RepeatKind = Enums.ScheduleRepeatKind.Daily Then
			
			BeginOfPeriod = IntervalBegin;
			EndOfPeriod = IntervalEnd;
			
			If TimetableString.CompleteKind = Enums.ScheduleRepeatCompletingKind.AtDate Then
				
				BeginOfPeriod = IntervalBegin;
				EndOfPeriod = IntervalEnd;
				
				While BegOfDay(BeginOfPeriod) <= CompleteAfter Do
					
					If RepeatIndex = 0 Or RepeatIndex = RepeatInterval Then
						NewRow = ExtendedTable.Add();
						NewRow.BeginOfPeriod = BeginOfPeriod;
						NewRow.EndOfPeriod = EndOfPeriod;
						NewRow.Loading = Loading;
						NewRow.Resource = Resource;
						NewRow.Period = BegOfDay(BeginOfPeriod);
						
						RepeatIndex = 0;
					EndIf;
					
					RepeatIndex = RepeatIndex + 1;
					BeginOfPeriod = BeginOfPeriod + 86400;
					EndOfPeriod = EndOfPeriod + 86400;
				EndDo;
				
			ElsIf TimetableString.CompleteKind = Enums.ScheduleRepeatCompletingKind.ByCounter Then
				
				RepeatQuantity = 1;
				
				While RepeatQuantity <= CompleteAfter Do
					
					If RepeatIndex = 0 Or RepeatIndex = RepeatInterval Then
						NewRow = ExtendedTable.Add();
						NewRow.BeginOfPeriod = BeginOfPeriod;
						NewRow.EndOfPeriod = EndOfPeriod;
						NewRow.Loading = Loading;
						NewRow.Resource = Resource;
						NewRow.Period = BegOfDay(BeginOfPeriod);
						
						RepeatQuantity = RepeatQuantity + 1;
						RepeatIndex = 0;
					EndIf;
					
					RepeatIndex = RepeatIndex + 1;
					BeginOfPeriod = BeginOfPeriod + 86400;
					EndOfPeriod = EndOfPeriod + 86400;
					
				EndDo;
			EndIf;
			Continue;
		EndIf;
		
		TimeSecBeginInterval = IntervalBegin - BegOfDay(IntervalBegin);
		TimeSecFinishInterval = IntervalEnd - BegOfDay(IntervalEnd);
		YearPeriod = Year(IntervalBegin);
		
		If TimetableString.RepeatKind = Enums.ScheduleRepeatKind.Weekly Then
			
			ArrayOfWeekDays = ArrayWorkDaysForRepeat(TimetableString);
			
			ProseccedWorkDaysQuantity = ArrayOfWeekDays.Count();
			CurrentWeekDayNumber = WeekDay(IntervalBegin);
			CurrentWeekNumber = WeekOfYear(IntervalBegin);
			
			If TimetableString.CompleteKind = Enums.ScheduleRepeatCompletingKind.AtDate Then
				
				WeekEndNumber = WeekOfYear(CompleteAfter);
				YearFinish = Year(CompleteAfter);
				
				While YearPeriod <= YearFinish Do
					
					LastYearWeek = WeekOfYear(Date(YearPeriod,12,31,1,1,1));
					WeekendPeriodForYear = ?(YearPeriod <YearFinish, LastYearWeek,WeekEndNumber);
					
					While CurrentWeekNumber < WeekendPeriodForYear Do
						
						If RepeatIndex = 0 Or RepeatIndex = RepeatInterval Then
							
							BegOfWeek = DateBeginOfWeekByNumber(YearPeriod,CurrentWeekNumber);
							
							For Each WeekDay In ArrayOfWeekDays Do
								
								DateByNumber = BegOfDay(BegOfWeek-1+(86400*WeekDay));
								
								If DateByNumber < BegOfDay(IntervalBegin) Then Continue EndIf;
								If DateByNumber > BegOfDay(CompleteAfter) Then Break EndIf;
								
								NewRow = ExtendedTable.Add();
								NewRow.BeginOfPeriod = DateByNumber + TimeSecBeginInterval;
								NewRow.EndOfPeriod = DateByNumber + TimeSecFinishInterval;
								NewRow.Loading = Loading;
								NewRow.Resource = Resource;
								NewRow.Period = BegOfDay(DateByNumber);
								
							EndDo;
							
							RepeatIndex = 0;
						EndIf;
						
						RepeatIndex = RepeatIndex + 1;
						CurrentWeekNumber = CurrentWeekNumber +1;
					EndDo;
					
					CurrentWeekNumber = 1;
					YearPeriod = YearPeriod + 1;
				EndDo;
				
			ElsIf TimetableString.CompleteKind = Enums.ScheduleRepeatCompletingKind.ByCounter Then
				
				LastYearWeek = WeekOfYear(Date(YearPeriod,12,31,1,1,1));
				
				While RepeatIndex < CompleteAfter Do
					
					BegOfWeek = DateBeginOfWeekByNumber(YearPeriod,CurrentWeekNumber);
					
					For Each WeekDay In ArrayOfWeekDays Do
						
						DateByNumber = BegOfDay(BegOfWeek-1+(86400*WeekDay));
						
						If DateByNumber < BegOfDay(IntervalBegin) Then Continue EndIf;
						
						NewRow = ExtendedTable.Add();
						NewRow.BeginOfPeriod = DateByNumber + TimeSecBeginInterval;
						NewRow.EndOfPeriod = DateByNumber + TimeSecFinishInterval;
						NewRow.Loading = Loading;
						NewRow.Resource = Resource;
						NewRow.Period = BegOfDay(DateByNumber);
						
					EndDo;
					
					RepeatIndex = RepeatIndex + 1;
					CurrentWeekNumber = CurrentWeekNumber +RepeatInterval;
					
					If CurrentWeekNumber > LastYearWeek Then
						YearPeriod = YearPeriod+1;
						LastYearWeek = WeekOfYear(Date(YearPeriod,12,31,1,1,1));
						CurrentWeekNumber = 1+RepeatInterval;
					EndIf;
					
				EndDo;
				
			EndIf;
			Continue;
		EndIf;
		
		If TimetableString.RepeatKind = Enums.ScheduleRepeatKind.Monthly Then
			
			If TimetableString.CompleteKind = Enums.ScheduleRepeatCompletingKind.AtDate Then
				
				DecomposeRowsMonthByDate(TimetableString,ExtendedTable);
				
			ElsIf TimetableString.CompleteKind = Enums.ScheduleRepeatCompletingKind.ByCounter Then
				
				DecomposeRowsMonthByCounter(TimetableString,ExtendedTable)
				
			EndIf;
			Continue;
		EndIf;
		
		If TimetableString.RepeatKind = Enums.ScheduleRepeatKind.Annually Then
			
			MonthNumber = TimetableString.MonthNumber;
			RepeatabilityDate = TimetableString.RepeatabilityDate;
			
			If TimetableString.CompleteKind = Enums.ScheduleRepeatCompletingKind.AtDate Then
				
				CountingEnd = BegOfMonth(CompleteAfter);
				
				If ValueIsFilled(RepeatabilityDate) And ValueIsFilled(MonthNumber) Then
					
					YearPeriod = Year(IntervalBegin);
					YearFinish = Year(CompleteAfter);
					
					While YearPeriod<=YearFinish Do
						
						CounterPeriod = Date(YearPeriod, MonthNumber, RepeatabilityDate, 0,0,0);
						
						NewRow = ExtendedTable.Add();
						NewRow.BeginOfPeriod = CounterPeriod + TimeSecBeginInterval;
						NewRow.EndOfPeriod = CounterPeriod + TimeSecFinishInterval;
						NewRow.Loading = Loading;
						NewRow.Resource = Resource;
						NewRow.Period = BegOfDay(CounterPeriod);
						
						YearPeriod = YearPeriod + RepeatInterval;
					EndDo;
					
				EndIf;
				
			ElsIf TimetableString.CompleteKind = Enums.ScheduleRepeatCompletingKind.ByCounter Then
				
				If ValueIsFilled(RepeatabilityDate) And ValueIsFilled(MonthNumber) Then
					
					RepeatIndex = 1;
					
					While RepeatIndex<=CompleteAfter Do
						
						CounterPeriod = Date(YearPeriod, MonthNumber, RepeatabilityDate, 0,0,0);
						
						NewRow = ExtendedTable.Add();
						NewRow.BeginOfPeriod = CounterPeriod + TimeSecBeginInterval;
						NewRow.EndOfPeriod = CounterPeriod + TimeSecFinishInterval;
						NewRow.Loading = Loading;
						NewRow.Resource = Resource;
						NewRow.Period = BegOfDay(CounterPeriod);
						
						YearPeriod = YearPeriod + RepeatInterval;
						
						RepeatIndex = RepeatIndex + 1;
					EndDo;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return ExtendedTable;
	
EndFunction

//Раскладывет строки Ежемесячного распиания с учетом даты завершения
//
Procedure DecomposeRowsMonthByDate(TimetableString, ExtendedTable)
	
	Resource = TimetableString.EnterpriseResource;
	
	IntervalBegin = TimetableString.Start;
	IntervalEnd = TimetableString.Finish;
	CompleteAfter = TimetableString.CompleteAfter;
	
	RepeatInterval = TimetableString.RepeatInterval;
	Loading = TimetableString.Capacity;
	
	RepeatabilityDate = TimetableString.RepeatabilityDate;
	WeekDayMonth = TimetableString.WeekDayMonth;
	
	TimeSecBeginInterval = IntervalBegin - BegOfDay(IntervalBegin);
	TimeSecFinishInterval = IntervalEnd - BegOfDay(IntervalEnd);
	
	LastMonthDay = TimetableString.LastMonthDay;
	
	CurMonth = Month(IntervalBegin);
	CurYear = Year(IntervalBegin);
	
	CountingEnd = BegOfMonth(CompleteAfter);
	
	If ValueIsFilled(RepeatabilityDate) Then
		
		CounterPeriod = Date(CurYear, CurMonth, RepeatabilityDate, 0,0,0);
		
		While CounterPeriod <= CountingEnd Do
			
			CurMonth = CurMonth + RepeatInterval;
			
			NewRow = ExtendedTable.Add();
			NewRow.BeginOfPeriod = CounterPeriod + TimeSecBeginInterval;
			NewRow.EndOfPeriod = CounterPeriod + TimeSecFinishInterval;
			NewRow.Loading = Loading;
			NewRow.Resource = Resource;
			NewRow.Period = BegOfDay(CounterPeriod);
			
			If CurMonth>12 Then
				CurYear = CurYear+1;
				CurMonth = CurMonth - 12;
			EndIf;
			
			CounterPeriod = Date(CurYear, CurMonth, RepeatabilityDate, 0,0,0);
			
		EndDo;
		
		Return;
		
	EndIf;
	
	If ValueIsFilled(WeekDayMonth) Then
		
		CounterPeriod = Date(CurYear, CurMonth, 1, 0,0,0);
		
		WeekMonthNumber = TimetableString.WeekMonthNumber;
		
		While CounterPeriod <= CountingEnd Do
			
			WeekBeginMonthByCounter = WeekOfYear(BegOfMonth(CounterPeriod));
			SearchWeek = WeekBeginMonthByCounter + WeekMonthNumber - 1;
			
			DateBeginOfWeek = DateBeginOfWeekByNumber(CurYear,SearchWeek);
			RequiredData =  BegOfDay(DateBeginOfWeek-1+(86400*WeekDayMonth));
			
			If RequiredData > CompleteAfter Then Break EndIf;
			
			CurMonth = CurMonth + RepeatInterval;
			
			NewRow = ExtendedTable.Add();
			NewRow.BeginOfPeriod = RequiredData + TimeSecBeginInterval;
			NewRow.EndOfPeriod = RequiredData + TimeSecFinishInterval;
			NewRow.Loading = Loading;
			NewRow.Resource = Resource;
			NewRow.Period = BegOfDay(RequiredData);
			
			If CurMonth>12 Then
				CurYear = CurYear+1;
				CurMonth = CurMonth - 12;
			EndIf;
			
			CounterPeriod = Date(CurYear, CurMonth, 1, 0,0,0);
			
		EndDo;
		
		Return;
		
	EndIf;
	
	If LastMonthDay Then
		
		CounterPeriod = Date(CurYear, CurMonth, 1, 0,0,0);
		
		While CounterPeriod <= CountingEnd Do
			
			
			RequiredData = BegOfDay(EndOfMonth(CounterPeriod));
			
			If RequiredData > CompleteAfter Then Break EndIf;
			
			CurMonth = CurMonth + RepeatInterval;
			
			NewRow = ExtendedTable.Add();
			NewRow.BeginOfPeriod = RequiredData + TimeSecBeginInterval;
			NewRow.EndOfPeriod = RequiredData + TimeSecFinishInterval;
			NewRow.Loading = Loading;
			NewRow.Resource = Resource;
			NewRow.Period = BegOfDay(RequiredData);
			
			If CurMonth>12 Then
				CurYear = CurYear+1;
				CurMonth = CurMonth - 12;
			EndIf;
			
			CounterPeriod = Date(CurYear, CurMonth, 1, 0,0,0);
			
		EndDo;
		
		Return;
		
	EndIf;
	
EndProcedure

//Раскладывет строки Ежемесячного распиания с учетом количества повторений
//
Procedure DecomposeRowsMonthByCounter(TimetableString, ExtendedTable)
	
	Resource = TimetableString.EnterpriseResource;
	
	IntervalBegin = TimetableString.Start;
	IntervalEnd = TimetableString.Finish;
	CompleteAfter = TimetableString.CompleteAfter;
	
	RepeatInterval = TimetableString.RepeatInterval;
	Loading = TimetableString.Capacity;
	
	RepeatabilityDate = TimetableString.RepeatabilityDate;
	WeekDayMonth = TimetableString.WeekDayMonth;
	
	TimeSecBeginInterval = IntervalBegin - BegOfDay(IntervalBegin);
	TimeSecFinishInterval = IntervalEnd - BegOfDay(IntervalEnd);
	
	LastMonthDay = TimetableString.LastMonthDay;
	
	CurMonth = Month(IntervalBegin);
	CurYear = Year(IntervalBegin);
	
	CountingEnd = CompleteAfter;
	CounterPeriod = 1;
	
	If ValueIsFilled(RepeatabilityDate) Then
		
		OutputPeriod = Date(CurYear, CurMonth, RepeatabilityDate, 0,0,0);
		
		While CounterPeriod <= CountingEnd Do
			
			CurMonth = CurMonth + RepeatInterval;
			
			NewRow = ExtendedTable.Add();
			NewRow.BeginOfPeriod = OutputPeriod + TimeSecBeginInterval;
			NewRow.EndOfPeriod = OutputPeriod + TimeSecFinishInterval;
			NewRow.Loading = Loading;
			NewRow.Resource = Resource;
			NewRow.Period = BegOfDay(OutputPeriod);
			
			If CurMonth>12 Then
				CurYear = CurYear+1;
				CurMonth = CurMonth - 12;
			EndIf;
			
			OutputPeriod = Date(CurYear, CurMonth, RepeatabilityDate, 0,0,0);
			CounterPeriod = CounterPeriod +1;
			
		EndDo;
		
		Return;
		
	EndIf;
	
	If ValueIsFilled(WeekDayMonth) Then
		
		OutputPeriod = Date(CurYear, CurMonth, 1, 0,0,0);
		
		WeekMonthNumber = TimetableString.WeekMonthNumber;
	
		While CounterPeriod <= CountingEnd Do
			
			WeekBeginMonthByCounter = WeekOfYear(BegOfMonth(OutputPeriod));
			SearchWeek = WeekBeginMonthByCounter + WeekMonthNumber - 1;
			
			DateBeginOfWeek = DateBeginOfWeekByNumber(CurYear,SearchWeek);
			RequiredData =  BegOfDay(DateBeginOfWeek-1+(86400*WeekDayMonth));
			
			CurMonth = CurMonth + RepeatInterval;
			
			NewRow = ExtendedTable.Add();
			NewRow.BeginOfPeriod = RequiredData + TimeSecBeginInterval;
			NewRow.EndOfPeriod = RequiredData + TimeSecFinishInterval;
			NewRow.Loading = Loading;
			NewRow.Resource = Resource;
			NewRow.Period = BegOfDay(RequiredData);
			
			If CurMonth>12 Then
				CurYear = CurYear+1;
				CurMonth = CurMonth - 12;
			EndIf;
			
			OutputPeriod = Date(CurYear, CurMonth, 1, 0,0,0);
			
			CounterPeriod = CounterPeriod +1;
			
		EndDo;
		
		Return;
		
	EndIf;
	
	If LastMonthDay Then
		
		OutputPeriod = Date(CurYear, CurMonth, 1, 0,0,0);
		
		While CounterPeriod <= CountingEnd Do
		
			RequiredData = BegOfDay(EndOfMonth(OutputPeriod));
			
			CurMonth = CurMonth + RepeatInterval;
			
			NewRow = ExtendedTable.Add();
			NewRow.BeginOfPeriod = RequiredData + TimeSecBeginInterval;
			NewRow.EndOfPeriod = RequiredData + TimeSecFinishInterval;
			NewRow.Loading = Loading;
			NewRow.Resource = Resource;
			NewRow.Period = BegOfDay(RequiredData);
			
			If CurMonth>12 Then
				CurYear = CurYear+1;
				CurMonth = CurMonth - 12;
			EndIf;
			
			OutputPeriod = Date(CurYear, CurMonth, 1, 0,0,0);
			
			CounterPeriod = CounterPeriod +1;
			
		EndDo;
		
		Return;
		
	EndIf;
	
EndProcedure

//Раскладывает строки из ТЧ РесурсыПредприятия по расписанию в таблицу знаяений для формирования движений
//
Function DecomposeRowsByRecordsSchedule(DocumentRef,ScheduleTable, Counterparty = Undefined, Department = Undefined, Responsible = Undefined) Export
	
	ExtendedTable = New ValueTable;
	
	ExtendedTable.Columns.Add("Counterparty");
	ExtendedTable.Columns.Add("Department");
	ExtendedTable.Columns.Add("Responsible");
	ExtendedTable.Columns.Add("EnterpriseResource");
	ExtendedTable.Columns.Add("Start");
	ExtendedTable.Columns.Add("Finish");
	ExtendedTable.Columns.Add("Capacity");
	ExtendedTable.Columns.Add("Period");
	ExtendedTable.Columns.Add("NumberRowResourceTable");
	ExtendedTable.Columns.Add("Document");
	
	For Each TimetableString In ScheduleTable Do
		
		EnterpriseResource = TimetableString.EnterpriseResource;
		IntervalBegin = TimetableString.Start;
		IntervalEnd = TimetableString.Finish;
		CompleteAfter = TimetableString.CompleteAfter;
		RepeatInterval = TimetableString.RepeatInterval;
		Capacity = TimetableString.Capacity;
		RepeatIndex = 0;
		
		If Not BegOfDay(IntervalBegin) = BegOfDay(IntervalEnd) Then
			
			CounterDay = IntervalBegin;
			
			While CounterDay<= BegOfDay(IntervalEnd) Do
				
				NewRow = ExtendedTable.Add();
				NewRow.Start = CounterDay;
				
				NewRow.Finish = ?(BegOfDay(CounterDay)= BegOfDay(IntervalEnd), IntervalEnd, EndOfDay(CounterDay));
				
				NewRow.Capacity = Capacity;
				NewRow.EnterpriseResource = EnterpriseResource;
				NewRow.Period = BegOfDay(CounterDay);
				
				NewRow.Counterparty = Counterparty;
				NewRow.Department = Department;
				NewRow.Responsible = Responsible;
				NewRow.NumberRowResourceTable = TimetableString.LineNumber;
				NewRow.Document = DocumentRef;
				
				CounterDay = BegOfDay(CounterDay+86401);
			EndDo;
			
			Continue;
		EndIf;
		
		If BegOfDay(IntervalBegin) = BegOfDay(IntervalEnd) 
			And (Not ValueIsFilled(TimetableString.RepeatKind) Or TimetableString.RepeatKind = Enums.ScheduleRepeatKind.NoRepeat) Then
			
			NewRow = ExtendedTable.Add();
			NewRow.Start = IntervalBegin;
			NewRow.Finish = IntervalEnd;
			NewRow.Capacity = Capacity;
			NewRow.EnterpriseResource = EnterpriseResource;
			NewRow.Period = BegOfDay(IntervalBegin);
			
			NewRow.Counterparty = Counterparty;
			NewRow.Department = Department;
			NewRow.Responsible = Responsible;
			NewRow.NumberRowResourceTable = TimetableString.LineNumber;
			NewRow.Document = DocumentRef;
			
			Continue;
		EndIf;
		
		If TimetableString.RepeatKind = Enums.ScheduleRepeatKind.Daily Then
			
			Start = IntervalBegin;
			Finish = IntervalEnd;
			
			If TimetableString.CompleteKind = Enums.ScheduleRepeatCompletingKind.AtDate Then
				
				Start = IntervalBegin;
				Finish = IntervalEnd;
				
				While BegOfDay(Start) <= CompleteAfter Do
					
					If RepeatIndex = 0 Or RepeatIndex = RepeatInterval Then
						NewRow = ExtendedTable.Add();
						NewRow.Start = Start;
						NewRow.Finish = Finish;
						NewRow.Capacity = Capacity;
						NewRow.EnterpriseResource = EnterpriseResource;
						NewRow.Period = BegOfDay(Start);
						
						NewRow.Counterparty = Counterparty;
						NewRow.Department = Department;
						NewRow.Responsible = Responsible;
						NewRow.NumberRowResourceTable = TimetableString.LineNumber;
						NewRow.Document = DocumentRef;
						
						RepeatIndex = 0;
					EndIf;
					
					RepeatIndex = RepeatIndex + 1;
					Start = Start + 86400;
					Finish = Finish + 86400;
				EndDo;
				
			ElsIf TimetableString.CompleteKind = Enums.ScheduleRepeatCompletingKind.ByCounter Then
				
				RepeatQuantity = 1;
				
				While RepeatQuantity <= CompleteAfter Do
					
					If RepeatIndex = 0 Or RepeatIndex = RepeatInterval Then
						NewRow = ExtendedTable.Add();
						NewRow.Start = Start;
						NewRow.Finish = Finish;
						NewRow.Capacity = Capacity;
						NewRow.EnterpriseResource = EnterpriseResource;
						NewRow.Period = BegOfDay(Start);
						
						NewRow.Counterparty = Counterparty;
						NewRow.Department = Department;
						NewRow.Responsible = Responsible;
						NewRow.NumberRowResourceTable = TimetableString.LineNumber;
						NewRow.Document = DocumentRef;
						
						RepeatQuantity = RepeatQuantity + 1;
						RepeatIndex = 0;
					EndIf;
					
					RepeatIndex = RepeatIndex + 1;
					Start = Start + 86400;
					Finish = Finish + 86400;
					
				EndDo;
			EndIf;
			Continue;
		EndIf;
		
		TimeSecBeginInterval = IntervalBegin - BegOfDay(IntervalBegin);
		TimeSecFinishInterval = IntervalEnd - BegOfDay(IntervalEnd);
		YearPeriod = Year(IntervalBegin);
		
		If TimetableString.RepeatKind = Enums.ScheduleRepeatKind.Weekly Then
			
			ArrayOfWeekDays = ArrayWorkDaysForRepeat(TimetableString);
			
			ProseccedWorkDaysQuantity = ArrayOfWeekDays.Count();
			CurrentWeekDayNumber = WeekDay(IntervalBegin);
			CurrentWeekNumber = WeekOfYear(IntervalBegin);
			
			If TimetableString.CompleteKind = Enums.ScheduleRepeatCompletingKind.AtDate Then
				
				WeekEndNumber = WeekOfYear(CompleteAfter);
				YearFinish = Year(CompleteAfter);
				
				While YearPeriod <= YearFinish Do
					
					LastYearWeek = WeekOfYear(Date(YearPeriod,12,31,1,1,1));
					WeekendPeriodForYear = ?(YearPeriod <YearFinish, LastYearWeek,WeekEndNumber);
					
					While CurrentWeekNumber < WeekendPeriodForYear Do
						
						If RepeatIndex = 0 Or RepeatIndex = RepeatInterval Then
							
							BegOfWeek = DateBeginOfWeekByNumber(YearPeriod,CurrentWeekNumber);
							
							For Each WeekDay In ArrayOfWeekDays Do
								
								DateByNumber = BegOfDay(BegOfWeek-1+(86400*WeekDay));
								
								If DateByNumber < BegOfDay(IntervalBegin) Then Continue EndIf;
								If DateByNumber > BegOfDay(CompleteAfter) Then Break EndIf;
								
								NewRow = ExtendedTable.Add();
								NewRow.Start = DateByNumber + TimeSecBeginInterval;
								NewRow.Finish = DateByNumber + TimeSecFinishInterval;
								NewRow.Capacity = Capacity;
								NewRow.EnterpriseResource = EnterpriseResource;
								NewRow.Period = BegOfDay(DateByNumber);
								
								NewRow.Counterparty = Counterparty;
								NewRow.Department = Department;
								NewRow.Responsible = Responsible;
								NewRow.NumberRowResourceTable = TimetableString.LineNumber;
								NewRow.Document = DocumentRef;
								
							EndDo;
							
							RepeatIndex = 0;
						EndIf;
						
						RepeatIndex = RepeatIndex + 1;
						CurrentWeekNumber = CurrentWeekNumber +1;
					EndDo;
					
					CurrentWeekNumber = 1;
					YearPeriod = YearPeriod + 1;
				EndDo;
				
			ElsIf TimetableString.CompleteKind = Enums.ScheduleRepeatCompletingKind.ByCounter Then
				
				LastYearWeek = WeekOfYear(Date(YearPeriod,12,31,1,1,1));
				
				While RepeatIndex < CompleteAfter Do
					
					BegOfWeek = DateBeginOfWeekByNumber(YearPeriod,CurrentWeekNumber);
					
					For Each WeekDay In ArrayOfWeekDays Do
						
						DateByNumber = BegOfDay(BegOfWeek-1+(86400*WeekDay));
						
						If DateByNumber < BegOfDay(IntervalBegin) Then Continue EndIf;
						
						NewRow = ExtendedTable.Add();
						NewRow.Start = DateByNumber + TimeSecBeginInterval;
						NewRow.Finish = DateByNumber + TimeSecFinishInterval;
						NewRow.Capacity = Capacity;
						NewRow.EnterpriseResource = EnterpriseResource;
						NewRow.Period = BegOfDay(DateByNumber);
						
						NewRow.Counterparty = Counterparty;
						NewRow.Department = Department;
						NewRow.Responsible = Responsible;
						NewRow.NumberRowResourceTable = TimetableString.LineNumber;
						NewRow.Document = DocumentRef;
						
					EndDo;
					
					RepeatIndex = RepeatIndex + 1;
					CurrentWeekNumber = CurrentWeekNumber +RepeatInterval;
					
					If CurrentWeekNumber > LastYearWeek Then
						YearPeriod = YearPeriod+1;
						LastYearWeek = WeekOfYear(Date(YearPeriod,12,31,1,1,1));
						CurrentWeekNumber = 1+RepeatInterval;
					EndIf;
					
				EndDo;
				
			EndIf;
			Continue;
		EndIf;
		
		If TimetableString.RepeatKind = Enums.ScheduleRepeatKind.Monthly Then
			
			If TimetableString.CompleteKind = Enums.ScheduleRepeatCompletingKind.AtDate Then
				
				DecomposeRowsMonthByRecordsDate(TimetableString,ExtendedTable, Counterparty, Department, Responsible, DocumentRef);
				
			ElsIf TimetableString.CompleteKind = Enums.ScheduleRepeatCompletingKind.ByCounter Then
				
				DecomposeRowsMonthByRecordsCounter(TimetableString,ExtendedTable, Counterparty, Department, Responsible, DocumentRef)
				
			EndIf;
			Continue;
		EndIf;
		
		If TimetableString.RepeatKind = Enums.ScheduleRepeatKind.Annually Then
			
			MonthNumber = TimetableString.MonthNumber;
			RepeatabilityDate = TimetableString.RepeatabilityDate;
			
			If TimetableString.CompleteKind = Enums.ScheduleRepeatCompletingKind.AtDate Then
				
				CountingEnd = BegOfMonth(CompleteAfter);
				
				If ValueIsFilled(RepeatabilityDate) And ValueIsFilled(MonthNumber) Then
					
					YearPeriod = Year(IntervalBegin);
					YearFinish = Year(CompleteAfter);
					
					While YearPeriod<=YearFinish Do
						
						CounterPeriod = Date(YearPeriod, MonthNumber, RepeatabilityDate, 0,0,0);
						
						NewRow = ExtendedTable.Add();
						NewRow.Start = CounterPeriod + TimeSecBeginInterval;
						NewRow.Finish = CounterPeriod + TimeSecFinishInterval;
						NewRow.Capacity = Capacity;
						NewRow.EnterpriseResource = EnterpriseResource;
						NewRow.Period = BegOfDay(CounterPeriod);
						
						NewRow.Counterparty = Counterparty;
						NewRow.Department = Department;
						NewRow.Responsible = Responsible;
						NewRow.NumberRowResourceTable = TimetableString.LineNumber;
						NewRow.Document = DocumentRef;
						
						YearPeriod = YearPeriod + RepeatInterval;
					EndDo;
					
				EndIf;
				
			ElsIf TimetableString.CompleteKind = Enums.ScheduleRepeatCompletingKind.ByCounter Then
				
				If ValueIsFilled(RepeatabilityDate) And ValueIsFilled(MonthNumber) Then
					
					RepeatIndex = 1;
					
					While RepeatIndex<=CompleteAfter Do
						
						CounterPeriod = Date(YearPeriod, MonthNumber, RepeatabilityDate, 0,0,0);
						
						NewRow = ExtendedTable.Add();
						NewRow.Start = CounterPeriod + TimeSecBeginInterval;
						NewRow.Finish = CounterPeriod + TimeSecFinishInterval;
						NewRow.Capacity = Capacity;
						NewRow.EnterpriseResource = EnterpriseResource;
						NewRow.Period = BegOfDay(CounterPeriod);
						
						NewRow.Counterparty = Counterparty;
						NewRow.Department = Department;
						NewRow.Responsible = Responsible;
						NewRow.NumberRowResourceTable = TimetableString.LineNumber;
						NewRow.Document = DocumentRef;
						
						YearPeriod = YearPeriod + RepeatInterval;
						
						RepeatIndex = RepeatIndex + 1;
					EndDo;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return ExtendedTable;
	
EndFunction

//Раскладывет строки Ежемесячного распиания с учетом даты завершения для движений
//
Procedure DecomposeRowsMonthByRecordsDate(TimetableString, ExtendedTable
	,Counterparty = Undefined, Department = Undefined, Responsible = Undefined, DocumentRef = Undefined)
	
	EnterpriseResource = TimetableString.EnterpriseResource;
	
	IntervalBegin = TimetableString.Start;
	IntervalEnd = TimetableString.Finish;
	CompleteAfter = TimetableString.CompleteAfter;
	
	RepeatInterval = TimetableString.RepeatInterval;
	Capacity = TimetableString.Capacity;
	
	RepeatabilityDate = TimetableString.RepeatabilityDate;
	WeekDayMonth = TimetableString.WeekDayMonth;
	
	TimeSecBeginInterval = IntervalBegin - BegOfDay(IntervalBegin);
	TimeSecFinishInterval = IntervalEnd - BegOfDay(IntervalEnd);
	
	LastMonthDay = TimetableString.LastMonthDay;
	
	CurMonth = Month(IntervalBegin);
	CurYear = Year(IntervalBegin);
	
	CountingEnd = BegOfMonth(CompleteAfter);
	
	If ValueIsFilled(RepeatabilityDate) Then
		
		CounterPeriod = Date(CurYear, CurMonth, RepeatabilityDate, 0,0,0);
		
		While CounterPeriod <= CountingEnd Do
			
			CurMonth = CurMonth + RepeatInterval;
			
			NewRow = ExtendedTable.Add();
			NewRow.Start = CounterPeriod + TimeSecBeginInterval;
			NewRow.Finish = CounterPeriod + TimeSecFinishInterval;
			NewRow.Capacity = Capacity;
			NewRow.EnterpriseResource = EnterpriseResource;
			NewRow.Period = BegOfDay(CounterPeriod);
			
			NewRow.Counterparty = Counterparty;
			NewRow.Department = Department;
			NewRow.Responsible = Responsible;
			NewRow.NumberRowResourceTable = TimetableString.LineNumber;
			
			If ValueIsFilled(DocumentRef) Then
				NewRow.Document = DocumentRef;
			EndIf;
			
			If CurMonth>12 Then
				CurYear = CurYear+1;
				CurMonth = CurMonth - 12;
			EndIf;
			
			CounterPeriod = Date(CurYear, CurMonth, RepeatabilityDate, 0,0,0);
			
		EndDo;
		
		Return;
		
	EndIf;
	
	If ValueIsFilled(WeekDayMonth) Then
		
		CounterPeriod = Date(CurYear, CurMonth, 1, 0,0,0);
		
		WeekMonthNumber = TimetableString.WeekMonthNumber;
		
		While CounterPeriod <= CountingEnd Do
			
			WeekBeginMonthByCounter = WeekOfYear(BegOfMonth(CounterPeriod));
			SearchWeek = WeekBeginMonthByCounter + WeekMonthNumber - 1;
			
			DateBeginOfWeek = DateBeginOfWeekByNumber(CurYear,SearchWeek);
			RequiredData =  BegOfDay(DateBeginOfWeek-1+(86400*WeekDayMonth));
			
			If RequiredData > CompleteAfter Then Break EndIf;
			
			CurMonth = CurMonth + RepeatInterval;
			
			NewRow = ExtendedTable.Add();
			NewRow.Start = RequiredData + TimeSecBeginInterval;
			NewRow.Finish = RequiredData + TimeSecFinishInterval;
			NewRow.Capacity = Capacity;
			NewRow.EnterpriseResource = EnterpriseResource;
			NewRow.Period = BegOfDay(RequiredData);
			
			NewRow.Counterparty = Counterparty;
			NewRow.Department = Department;
			NewRow.Responsible = Responsible;
			NewRow.NumberRowResourceTable = TimetableString.LineNumber;
			
			If ValueIsFilled(DocumentRef) Then
				NewRow.Document = DocumentRef;
			EndIf;
			
			If CurMonth>12 Then
				CurYear = CurYear+1;
				CurMonth = CurMonth - 12;
			EndIf;
			
			CounterPeriod = Date(CurYear, CurMonth, 1, 0,0,0);
			
		EndDo;
		
		Return;
		
	EndIf;
	
	If LastMonthDay Then
		
		CounterPeriod = Date(CurYear, CurMonth, 1, 0,0,0);
		
		While CounterPeriod <= CountingEnd Do
			
			
			RequiredData = BegOfDay(EndOfMonth(CounterPeriod));
			
			If RequiredData > CompleteAfter Then Break EndIf;
			
			CurMonth = CurMonth + RepeatInterval;
			
			NewRow = ExtendedTable.Add();
			NewRow.Start = RequiredData + TimeSecBeginInterval;
			NewRow.Finish = RequiredData + TimeSecFinishInterval;
			NewRow.Capacity = Capacity;
			NewRow.EnterpriseResource = EnterpriseResource;
			NewRow.Period = BegOfDay(RequiredData);
			
			NewRow.Counterparty = Counterparty;
			NewRow.Department = Department;
			NewRow.Responsible = Responsible;
			NewRow.NumberRowResourceTable = TimetableString.LineNumber;
			
			If ValueIsFilled(DocumentRef) Then
				NewRow.Document = DocumentRef;
			EndIf;
			
			If CurMonth>12 Then
				CurYear = CurYear+1;
				CurMonth = CurMonth - 12;
			EndIf;
			
			CounterPeriod = Date(CurYear, CurMonth, 1, 0,0,0);
			
		EndDo;
		
		Return;
		
	EndIf;
	
EndProcedure

//Раскладывет строки Ежемесячного распиания с учетом количества повторений для движений
//
Procedure DecomposeRowsMonthByRecordsCounter(TimetableString, ExtendedTable,
	Counterparty = Undefined, Department = Undefined, Responsible = Undefined, DocumentRef = Undefined)
	
	EnterpriseResource = TimetableString.EnterpriseResource;
	
	IntervalBegin = TimetableString.Start;
	IntervalEnd = TimetableString.Finish;
	CompleteAfter = TimetableString.CompleteAfter;
	
	RepeatInterval = TimetableString.RepeatInterval;
	Capacity = TimetableString.Capacity;
	
	RepeatabilityDate = TimetableString.RepeatabilityDate;
	WeekDayMonth = TimetableString.WeekDayMonth;
	
	TimeSecBeginInterval = IntervalBegin - BegOfDay(IntervalBegin);
	TimeSecFinishInterval = IntervalEnd - BegOfDay(IntervalEnd);
	
	LastMonthDay = TimetableString.LastMonthDay;
	
	CurMonth = Month(IntervalBegin);
	CurYear = Year(IntervalBegin);
	
	CountingEnd = CompleteAfter;
	CounterPeriod = 1;
	
	If ValueIsFilled(RepeatabilityDate) Then
		
		OutputPeriod = Date(CurYear, CurMonth, RepeatabilityDate, 0,0,0);
		
		While CounterPeriod <= CountingEnd Do
			
			CurMonth = CurMonth + RepeatInterval;
			
			NewRow = ExtendedTable.Add();
			NewRow.Start = OutputPeriod + TimeSecBeginInterval;
			NewRow.Finish = OutputPeriod + TimeSecFinishInterval;
			NewRow.Capacity = Capacity;
			NewRow.EnterpriseResource = EnterpriseResource;
			NewRow.Period = BegOfDay(OutputPeriod);
			
			NewRow.Counterparty = Counterparty;
			NewRow.Department = Department;
			NewRow.Responsible = Responsible;
			NewRow.NumberRowResourceTable = TimetableString.LineNumber;
			
			If ValueIsFilled(DocumentRef) Then
				NewRow.Document = DocumentRef;
			EndIf;
			
			If CurMonth>12 Then
				CurYear = CurYear+1;
				CurMonth = CurMonth - 12;
			EndIf;
			
			OutputPeriod = Date(CurYear, CurMonth, RepeatabilityDate, 0,0,0);
			CounterPeriod = CounterPeriod +1;
			
		EndDo;
		
		Return;
		
	EndIf;
	
	If ValueIsFilled(WeekDayMonth) Then
		
		OutputPeriod = Date(CurYear, CurMonth, 1, 0,0,0);
		
		WeekMonthNumber = TimetableString.WeekMonthNumber;
		
		While CounterPeriod <= CountingEnd Do
			
			WeekBeginMonthByCounter = WeekOfYear(BegOfMonth(OutputPeriod));
			SearchWeek = WeekBeginMonthByCounter + WeekMonthNumber - 1;
			
			DateBeginOfWeek = DateBeginOfWeekByNumber(CurYear,SearchWeek);
			RequiredData =  BegOfDay(DateBeginOfWeek-1+(86400*WeekDayMonth));
			
			CurMonth = CurMonth + RepeatInterval;
			
			NewRow = ExtendedTable.Add();
			NewRow.Start = RequiredData + TimeSecBeginInterval;
			NewRow.Finish = RequiredData + TimeSecFinishInterval;
			NewRow.Capacity = Capacity;
			NewRow.EnterpriseResource = EnterpriseResource;
			NewRow.Period = BegOfDay(RequiredData);
			
			NewRow.Counterparty = Counterparty;
			NewRow.Department = Department;
			NewRow.Responsible = Responsible;
			NewRow.NumberRowResourceTable = TimetableString.LineNumber;
			
			If ValueIsFilled(DocumentRef) Then
				NewRow.Document = DocumentRef;
			EndIf;
			
			If CurMonth>12 Then
				CurYear = CurYear+1;
				CurMonth = CurMonth - 12;
			EndIf;
			
			OutputPeriod = Date(CurYear, CurMonth, 1, 0,0,0);
			
			CounterPeriod = CounterPeriod +1;
			
		EndDo;
		
		Return;
		
	EndIf;
	
	If LastMonthDay Then
		
		OutputPeriod = Date(CurYear, CurMonth, 1, 0,0,0);
		
		While CounterPeriod <= CountingEnd Do
			
			RequiredData = BegOfDay(EndOfMonth(OutputPeriod));
			
			CurMonth = CurMonth + RepeatInterval;
			
			NewRow = ExtendedTable.Add();
			NewRow.Start = RequiredData + TimeSecBeginInterval;
			NewRow.Finish = RequiredData + TimeSecFinishInterval;
			NewRow.Capacity = Capacity;
			NewRow.EnterpriseResource = EnterpriseResource;
			NewRow.Period = BegOfDay(RequiredData);
			
			NewRow.Counterparty = Counterparty;
			NewRow.Department = Department;
			NewRow.Responsible = Responsible;
			NewRow.NumberRowResourceTable = TimetableString.LineNumber;
			
			If ValueIsFilled(DocumentRef) Then
				NewRow.Document = DocumentRef;
			EndIf;
			
			If CurMonth>12 Then
				CurYear = CurYear+1;
				CurMonth = CurMonth - 12;
			EndIf;
			
			OutputPeriod = Date(CurYear, CurMonth, 1, 0,0,0);
			
			CounterPeriod = CounterPeriod +1;
			
		EndDo;
		
		Return;
		
	EndIf;
	
	
EndProcedure

//Возвращает Даты начала недели по номеру недели
//
Function DateBeginOfWeekByNumber(YearNumber,WeekNumber)
	Return BegOfWeek(Date(YearNumber,1,1))+604800*(WeekNumber-1); 
EndFunction

//Возвращает Массив дней недели для повторения в рамках заданного расписания
//
Function ArrayWorkDaysForRepeat(CurrentData)
	
	DaysArray = New Array;
	
	If CurrentData.Mon Then
		DaysArray.Add(1);
	EndIf;
	If CurrentData.Tu Then
		DaysArray.Add(2);
	EndIf;
	If CurrentData.We Then
		DaysArray.Add(3);
	EndIf;
	If CurrentData.Th Then
		DaysArray.Add(4);
	EndIf;
	If CurrentData.Fr Then
		DaysArray.Add(5);
	EndIf;
	If CurrentData.Sa Then
		DaysArray.Add(6);
	EndIf;
	If CurrentData.Su Then
		DaysArray.Add(7);
	EndIf;
	
	Return DaysArray;
	
EndFunction

//Устанавливает условное оформление для элемнтов ТЧ содержащих Ресурсы
//
Procedure SetupConditionalAppearanceResources(TSName="", Form, ThisIsDocument = False) Export
	
	If Form.Object.Property("Ref") Then
		If TypeOf(Form.Object.Ref) = Type("DocumentRef.CustomerOrder") 
			And Form.Object.OperationKind = Enums.OperationKindsCustomerOrder.WorkOrder 
			And Not GetFunctionalOption("PlanCompanyResourcesLoadingWorks") Then
			Return
		EndIf;
		
		If TypeOf(Form.Object.Ref) = Type("DocumentRef.ProductionOrder") 
			And Not GetFunctionalOption("PlanCompanyResourcesLoading") Then
			Return
		EndIf;
		
		If TypeOf(Form.Object.Ref) = Type("DocumentRef.Event") 
			And Form.Object.EventType = Enums.EventTypes.Record 
			And Not GetFunctionalOption("PlanCompanyResourcesLoadingEventLog") Then
			Return
		EndIf;
	EndIf;
	
	AddingFilterFields = ?(ThisIsDocument, "Object."+TSName, TSName);
	
	NewConditionalAppearance = Form.ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, AddingFilterFields+".CompleteKind", Enums.ScheduleRepeatCompletingKind.EmptyRef()
	,DataCompositionComparisonType.Equal);
	
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, TSName+"CompleteAfter");
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Text", NStr("en='<not specified>';ru='<не задано>';vi='<chưa đặt>'"));
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "ReadOnly", True);
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.TabularSectionUnavailableTextColor);
	
	NewConditionalAppearance = Form.ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, AddingFilterFields+".RepeatKind", Enums.ScheduleRepeatKind.EmptyRef()
	,DataCompositionComparisonType.Equal);
	
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, TSName+"CompleteKind");
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Text", NStr("en='<not specified>';ru='<не задано>';vi='<chưa đặt>'"));
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "ReadOnly", True);
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.TabularSectionUnavailableTextColor);
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "MarkIncomplete", False);
	
	NewConditionalAppearance = Form.ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, AddingFilterFields+".RepeatKind", Enums.ScheduleRepeatKind.NoRepeat
	, DataCompositionComparisonType.Equal);
	
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, TSName+"CompleteKind");
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Text", NStr("en='<not specified>';ru='<не задано>';vi='<chưa đặt>'"));
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "ReadOnly", True);
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.TabularSectionUnavailableTextColor);
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "MarkIncomplete", False);
	
	NewConditionalAppearance = Form.ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, AddingFilterFields+".RepeatsAvailable", False, DataCompositionComparisonType.Equal);
	
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, TSName+"CompleteKind");
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Text", NStr("en='<not specified>';ru='<не задано>';vi='<chưa đặt>'"));
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "ReadOnly", True);
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.TabularSectionUnavailableTextColor);
	
	NewConditionalAppearance = Form.ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, AddingFilterFields+".RepeatsAvailable", False, DataCompositionComparisonType.Equal);
	
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, TSName+"CompleteAfter");
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Text", NStr("en='<not specified>';ru='<не задано>';vi='<chưa đặt>'"));
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "ReadOnly", True);
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.TabularSectionUnavailableTextColor);
	
	NewConditionalAppearance = Form.ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, AddingFilterFields+".RepeatsAvailable", False, DataCompositionComparisonType.Equal);
	
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, TSName+"SchedulePresentation");
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Text", NStr("en='<not specified>';ru='<не задано>';vi='<chưa đặt>'"));
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "ReadOnly", True);
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.TabularSectionUnavailableTextColor);
	
	NewConditionalAppearance = Form.ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, AddingFilterFields+".PeriodDifferent", True, DataCompositionComparisonType.Equal);
	
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, TSName+"CompleteKind");
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Text", NStr("en='<not specified>';ru='<не задано>';vi='<chưa đặt>'"));
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "ReadOnly", True);
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.TabularSectionUnavailableTextColor);
	
	NewConditionalAppearance = Form.ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, AddingFilterFields+".PeriodDifferent", True, DataCompositionComparisonType.Equal);
	
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, TSName+"CompleteAfter");
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Text", NStr("en='<not specified>';ru='<не задано>';vi='<chưa đặt>'"));
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "ReadOnly", True);
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.TabularSectionUnavailableTextColor);
	
	NewConditionalAppearance = Form.ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, AddingFilterFields+".PeriodDifferent", True, DataCompositionComparisonType.Equal);
	
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, TSName+"SchedulePresentation");
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Text", NStr("en='<available in day>';ru='<доступно в рамках дня>';vi='<cho phép trong một ngày>'"));
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "ReadOnly", True);
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.TabularSectionUnavailableTextColor);
	
EndProcedure

//Возвращает таблицу движений для документов
//
Function DocumentsRecordsTable(DocumentRef) Export
	
	If TypeOf(DocumentRef) = Type("DocumentRef.ProductionOrder") Then
		Counterparty = ?(ValueIsFilled(DocumentRef.CustomerOrder), DocumentRef.CustomerOrder.Counterparty, Undefined);
		Department = DocumentRef.StructuralUnit;
	ElsIf TypeOf(DocumentRef) = Type("DocumentRef.CustomerOrder") Then
		Counterparty = DocumentRef.Counterparty;
		Department = DocumentRef.SalesStructuralUnit;
	ElsIf TypeOf(DocumentRef) = Type("DocumentRef.Event") 
		Or TypeOf(DocumentRef) = Type("DocumentObject.Event") Then
		
		If DocumentRef.Participants.Count() And ValueIsFilled(DocumentRef.Participants[0].Contact) Then
			Counterparty =DocumentRef.Participants[0].Contact;
		Else
			Counterparty = Undefined;
		EndIf;
				
		Department = Undefined;
	Else
		Counterparty = Undefined;
		Department = Undefined;
	EndIf;
	
	Return DecomposeRowsByRecordsSchedule(DocumentRef, DocumentRef.EnterpriseResources, Counterparty, Department, DocumentRef.Responsible);
	
EndFunction

//Перезаполняет служебные реквизиты табличной части РесурсыПредприятия
//
Procedure RefillServiceAttributesResourceTable(EnterpriseResources) Export
	
	If Not GetFunctionalOption("PlanCompanyResourcesLoading") Then Return EndIf;
	
	For Each RowResources In EnterpriseResources Do
		
		RowResources.ControlStep = RowResources.EnterpriseResource.ControlIntervalsStepInDocuments;
		RowResources.MultiplicityPlanning = RowResources.EnterpriseResource.MultiplicityPlanning;
		
		SelectedWeekDays = DescriptionWeekDays(RowResources);
		
		AddingByMonthYear = "";
		
		Start = RowResources.Start;
		Finish = RowResources.Finish;
		WeekDayMonth = RowResources.WeekDayMonth;
		RepeatabilityDate = RowResources.RepeatabilityDate;
		
		//Расписание
		If RowResources.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.Monthly")
			Or RowResources.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.Annually") Then
			
			If ValueIsFilled(RepeatabilityDate) Then
				
				AddingByMonthYear = ?(ValueIsFilled(RepeatabilityDate), NStr("en=', every ';ru=', каждый ';vi=', mỗi '") 
				+ String(RepeatabilityDate) + Nstr("ru='-ок';vi='-'")+ GetMonthByNumber(RowResources.MonthNumber)+".","");
			ElsIf ValueIsFilled(WeekDayMonth) Then
				
				If ItLastMonthWeek(Start) Then
					AddingByMonthYear = NStr("en=', In last. ';ru=', в конце';vi=', vào cuối'") + MapNumberWeekDay(WeekDayMonth)+ Nstr("en=' month.';ru=' месяц';vi=' tháng.'");
				Else
					WeekMonthNumber = WeekOfYear(Start)-WeekOfYear(BegOfMonth(Start))+1;
					AddingByMonthYear = " "+MapNumberWeekDay(WeekDayMonth) + Nstr("en=' every. ';ru=' каждый. ';vi=' mỗi.'") +String(WeekMonthNumber)+ Nstr("ru='-ли';vi='-'") + Nstr("en=' Weeks';ru=' Недели';vi='Tuần'");
				EndIf;
				
			ElsIf RowResources.LastMonthDay = True Then
				AddingByMonthYear = Nstr("en=', last day month.';ru=', последний день месяца';vi=', ngày cuối tháng'");
			EndIf;
			
		EndIf;
		
		Interjection = ?(RowResources.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.Weekly"),NStr("en='Every';vi='Mỗi';"), NStr("en='Each';vi='Mỗi';"));
		
		End = "";
		
		If RowResources.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.Weekly") Then
			End = Nstr("en='Week';ru='Неделя';vi='Tuần'");
		ElsIf RowResources.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.Daily") Then
			End = Nstr("en='Day';ru='День';vi='Ngày'");
		ElsIf RowResources.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.Monthly") Then
			End = Nstr("en='Month';ru='Месяц';vi='Trong tháng tới'");
		ElsIf RowResources.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.Annually") Then
			End = Nstr("en='Year';ru='Год';vi='Trong năm tới'");
		EndIf;
		
		If ValueIsFilled(RowResources.RepeatKind) 
			And Not RowResources.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.NoRepeat") Then
			
			SchedulePresentation = String(RowResources.RepeatKind)+", "+Interjection+" "+String(RowResources.RepeatInterval)+
			" "+ End+SelectedWeekDays+AddingByMonthYear;
		Else
			SchedulePresentation =  NStr("en='Not repeat';ru='Не повторять';vi='Không lặp lại'");
		EndIf;
		
		RowResources.SchedulePresentation = SchedulePresentation;
		
		//Повторы
		RowResources.RepeatsAvailable = False;
		RowResources.PeriodDifferent = False;
		
		If ValueIsFilled(Start) And ValueIsFilled(RowResources.Finish) Then
			
			RowResources.PeriodDifferent = ?(Not BegOfDay(Start) = BegOfDay(RowResources.Finish), True, False);
			
			If BegOfDay(Start) = BegOfDay(RowResources.Finish) Then
				RowResources.RepeatsAvailable = True;
			EndIf;
			
		EndIf;
		
		//Длительность
		
		DurationInMinutes = (Finish - Start)/60;
		
		RowResources.Days = 0;
		
		If DurationInMinutes >= 1440 Then
			RowResources.Days = Int(DurationInMinutes/1440);
		EndIf;
		
		RowResources.Time = Date(1,1,1)+((DurationInMinutes - RowResources.Days*1440)*60);
		
		//Расшифровка счетчика
		
		If RowResources.CompleteKind = Enums.ScheduleRepeatCompletingKind.ByCounter
			And ValueIsFilled(RowResources.CompleteAfter) Then 
			
			FormatString = "L = ru_RU";
			
			DetailsCounter = CountingItem(
			RowResources.CompleteAfter,
			NStr("en='time';ru='раза';vi='lần'"),
			NStr("en='time';ru='раз';vi='lần'"),
			NStr("en='time';ru='раз';vi='lần'"),
			"M");
			
			RowResources.DetailsCounter = DetailsCounter;
		Else
			RowResources.DetailsCounter = "";
		EndIf;
		
	EndDo;
	
EndProcedure

//Проверяет на кратность равную пяти окончания границ интервалов
Procedure CheckIntervalBoarders(CheckTable ,ItWorkPeriods = False) Export
	
	If ItWorkPeriods Then
		For Each CheckString In CheckTable Do
			
			EndOfPeriod = CheckString.WorkPeriodPerDayEnd;
			BeginOfPeriod= CheckString.BeginWorkPeriodInDay;
			
			If Not ValueIsFilled(BeginOfPeriod) Then Continue EndIf;
			
			ClosingBalance = Minute(EndOfPeriod)%5;
			OpeningBalance = Minute(BeginOfPeriod)%5;
			
			If Not OpeningBalance = 0 Or Not ClosingBalance = 0 Then
				CheckString.WorkPeriodPerDayEnd = ?(ClosingBalance = 0, EndOfPeriod, EndOfPeriod - (ClosingBalance*60));
				CheckString.BeginWorkPeriodInDay = ?(OpeningBalance = 0, BeginOfPeriod, BeginOfPeriod + (300 - OpeningBalance*60));
			EndIf;
			
		EndDo;
		Return
	EndIf;
	
	For Each CheckString In CheckTable Do
		
		EndOfPeriod = CheckString.EndTime;
		BeginOfPeriod= CheckString.BeginTime;
		
		If Not ValueIsFilled(BeginOfPeriod) Then Continue EndIf;
		
		ClosingBalance = Minute(EndOfPeriod)%5;
		OpeningBalance = Minute(BeginOfPeriod)%5;
		
		If Not OpeningBalance = 0 Or Not ClosingBalance = 0 Then
			CheckString.EndTime = ?(ClosingBalance = 0, EndOfPeriod, EndOfPeriod + (300 - ClosingBalance*60));
			CheckString.BeginTime = ?(OpeningBalance = 0, BeginOfPeriod, BeginOfPeriod - (OpeningBalance*60));
			CheckString.CellsQuantity = (CheckString.EndTime - CheckString.BeginTime)/300;
		EndIf;
		
	EndDo;
	
EndProcedure

//Формирует записи календаря сотрудника при проведении документа
//
Procedure CreateRecordsEmployeeCalendarByResources(DocumentRef, RegisterRecordTable, Cancel) Export
	
	If Cancel Then Return EndIf;
	
	MarkOnDeleteEmployeeCalendarRecords(DocumentRef, Cancel);
	
	If RegisterRecordTable = Undefined 
		Or Not RegisterRecordTable.Count() 
		Or Cancel Then
		Return
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Source",DocumentRef);
	
	Query.Text = 
	"SELECT
	|	RecordsEmployeeCalendar.Ref AS Ref,
	|	RecordsEmployeeCalendar.Begin AS Begin,
	|	RecordsEmployeeCalendar.End AS End,
	|	TRUE AS DeletionMark
	|FROM
	|	Catalog.EmployeesCalendarsRecords AS RecordsEmployeeCalendar
	|WHERE
	|	RecordsEmployeeCalendar.Source = &Source";
	
	RecordsTable = Query.Execute().Unload();
	
	FilterParameters = New Structure("Begin, End, DeletionMark");
	
	IsError = False;
	
	BeginTransaction();
	
	For Each TimetableString In RegisterRecordTable Do
		
		Calendar = TimetableString.EnterpriseResource.Calendar;
		
		If Not ValueIsFilled(Calendar) Then Continue EndIf;
		
		FilterParameters.Begin = TimetableString.Start;
		FilterParameters.End = TimetableString.Finish;
		FilterParameters.DeletionMark = True;
		
		FoundStrings = RecordsTable.FindRows(FilterParameters);
		
		If Not FoundStrings.Count() Then
			
			NewCalendarRecord = Catalogs.EmployeesCalendarsRecords.CreateItem();
			NewCalendarRecord.Source = DocumentRef;
			NewCalendarRecord.Begin = TimetableString.Start;
			NewCalendarRecord.End = TimetableString.Finish;
			NewCalendarRecord.SourceRowNumber = TimetableString.NumberRowResourceTable;
			NewCalendarRecord.Calendar = Calendar;
			
			If TypeOf(DocumentRef) = Type("DocumentRef.Event") Then
				NewCalendarRecord.Description = String(DocumentRef);
			Else
				OperationKind = "";
				
				If TypeOf(DocumentRef) = Type("DocumentRef.ProductionOrder") Then
					OperationKind = String(DocumentRef.OperationKind)+ " - ";
				EndIf;
				
				NewCalendarRecord.Description = NStr("en='Task: ';ru='Задание: ';vi='Nhiệm vụ:'") + OperationKind + String(DocumentRef);
			EndIf;
			
			Try
				NewCalendarRecord.Write();
			Except
				ErrorTitle = NStr("en='Error:';ru='Ошибка:';vi='Lỗi:'");
				TextOfMessage = ErrorTitle + Chars.LF + NStr("en='Error on write employee calendar';ru='Ошибка записи календаря сотрудника';vi='Lỗi khi ghi lịch nhân viên'");
				SmallBusinessServer.ShowMessageAboutError(DocumentRef, TextOfMessage);
				IsError = True;
				Break;
			EndTry;
			
		Else
			FoundStrings[0].DeletionMark = False;
			ObjectCalendarRecord = FoundStrings[0].Ref.GetObject();
			Try
				ObjectCalendarRecord.SetDeletionMark(False);
			Except
				ErrorTitle = NStr("en='Error:';ru='Ошибка:';vi='Lỗi:'");
				MessagePattern = ErrorTitle + Chars.LF + NStr("en='Error setup deletion mark for employee calendar record %CalendarRecord%';ru='Ошибка установки пометки на удаление записи календаря сотрудника %CalendarRecord%';vi='Lỗi thiết lập cờ để xóa mục nhập lịch của nhân viên %CalendarRecord%'");
				TextOfMessage = StrReplace(MessagePattern, "%CalendarRecord%", String(ObjectCalendarRecord));
				SmallBusinessServer.ShowMessageAboutError(DocumentRef, TextOfMessage);
				IsError = True;
				Break;
			EndTry;
			
			Continue;
			
		EndIf;
		
	EndDo;
	
	If IsError Then
		RollbackTransaction();
		Cancel = True;
	Else
		CommitTransaction();
	EndIf;
	
EndProcedure

//Помечает на удаление записи календаря сотрудника при удалении проведения документа
//
Procedure MarkOnDeleteEmployeeCalendarRecords(DocumentRef, Cancel)
	
	Query = New Query;
	Query.SetParameter("Source",DocumentRef);
	
	Query.Text = 
	"SELECT
	|	RecordsEmployeeCalendar.Ref AS Ref
	|FROM
	|	Catalog.EmployeesCalendarsRecords AS RecordsEmployeeCalendar
	|WHERE
	|	RecordsEmployeeCalendar.Source = &Source
	|	AND NOT RecordsEmployeeCalendar.DeletionMark";
	
	Selection = Query.Execute().Select();
	
	HasErrors = False;
	
	BeginTransaction();
	
	While Selection.Next() Do
		
		SelectionObject = Selection.Ref.GetObject();
		
		Try
			SelectionObject.SetDeletionMark(True);
		Except
			HasErrors = True;
			
			ErrorTitle = NStr("en='Ошибка:';ru='Ошибка:';vi='Lỗi:'");
			MessagePattern = ErrorTitle + Chars.LF + NStr("en='Ошибка установки пометки на удаление записи календаря сотрудника %CalendarRecord%';ru='Ошибка установки пометки на удаление записи календаря сотрудника %CalendarRecord%';vi='Lỗi thiết lập cờ để xóa mục nhập lịch của nhân viên %CalendarRecord%'");
			TextOfMessage = StrReplace(MessagePattern, "%CalendarRecord%", String(Selection.Ref));
			SmallBusinessServer.ShowMessageAboutError(DocumentRef, TextOfMessage);
			
			Break;
		EndTry;
		
	EndDo;
	
	If HasErrors Then
		Cancel = True;
		RollbackTransaction();
	Else
		CommitTransaction();
	EndIf;
	
EndProcedure

//Записывает данные в регистр сведений "Расписание загрузки ресурсов"
//
Procedure WriteScheduleResourceLoading(DocumentRef, ResourcesRecordsTable = Undefined, Cancel) Export
	
	RecordSet = InformationRegisters.ScheduleLoadingResources.CreateRecordSet();
	RecordSet.Filter.Recorder.Set(DocumentRef);
	
	If ResourcesRecordsTable = Undefined Then
		RecordSet.Write();
		Return;
	EndIf;
	
	Responsible = DocumentRef.Responsible;
	
	For Each WritingTable In ResourcesRecordsTable Do
		
		NewRecord = RecordSet.Add();
		
		FillPropertyValues(NewRecord, WritingTable);
		
		NewRecord.Responsible = Responsible;
		NewRecord.Document = DocumentRef;
		
	EndDo;
	
	RecordSet.Write();
	
EndProcedure

Function CountingItem(Number, CountingItemParameters1, CountingItemParameters2, CountingItemParameters3, Gender) Export
	
	FormatString = "L = ru_RU";
	
	MeasurementUnitInWordParameters = "%1,%2,%3,%4,,,,,0";
	MeasurementUnitInWordParameters = StrTemplate(
		MeasurementUnitInWordParameters,
		CountingItemParameters1,
		CountingItemParameters2,
		CountingItemParameters3,
		Gender);
		
	NumberStringAndCountingItem = Lower(NumberInWords(Number, FormatString, MeasurementUnitInWordParameters));
	
	NumberInWords = NumberStringAndCountingItem;
	NumberInWords = StrReplace(NumberInWords, CountingItemParameters1, "");
	NumberInWords = StrReplace(NumberInWords, CountingItemParameters2, "");
		
	CountingItem = StrReplace(NumberStringAndCountingItem, NumberInWords, "");
	
	Return CountingItem;
	
EndFunction

Function MapNumberWeekDay(DayNumber) Export
	
	ConformityOfReturn = New Map;
	
	ConformityOfReturn.Insert(1,"Monday");
	ConformityOfReturn.Insert(2,"Tuesday");
	ConformityOfReturn.Insert(3,"Wednesday");
	ConformityOfReturn.Insert(4,"Thursday");
	ConformityOfReturn.Insert(5,"Friday");
	ConformityOfReturn.Insert(6,"Saturday");
	ConformityOfReturn.Insert(7,"Sunday");
	
	Return ConformityOfReturn.Get(DayNumber);
	
EndFunction

Function GetMonthByNumber(MonthNumber, WithoutDeclension = False) Export
	
	MapMonth = New Map();
	
	If WithoutDeclension Then
		
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
		
	Else
		
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
		
	EndIf;
	
	Return MapMonth.Get(MonthNumber);
	
EndFunction

Function ItLastMonthWeek(WeekDate) Export
	
	MonthWeekDays = Month(WeekDate);
	
	If Not MonthWeekDays = Month(EndOfWeek(WeekDate)) 
		Or Not MonthWeekDays = Month(EndOfWeek(WeekDate+10)) Then
		Return True
	EndIf;
	
	Return False;
	
EndFunction

Function DescriptionWeekDays(CurrentData) Export
	
	PresentationRow = "";
	
	If CurrentData.Mon Then PresentationRow = " Mon," EndIf;
	If CurrentData.Tu Then PresentationRow = PresentationRow + " Tu," EndIf;
	If CurrentData.We Then PresentationRow = PresentationRow + " We," EndIf;
	If CurrentData.Th Then PresentationRow = PresentationRow + " Th," EndIf;
	If CurrentData.Fr Then PresentationRow = PresentationRow + " Fr," EndIf;
	If CurrentData.Sa Then PresentationRow = PresentationRow + " Sa," EndIf;
	If CurrentData.Su Then PresentationRow = PresentationRow + " Su" EndIf;
	
	If StrEndsWith(PresentationRow, " ,") Then
		StringLength = StrLen(PresentationRow);
		PresentationRow = " In "+Left(PresentationRow,StringLength - 2);
		PresentationRow = PresentationRow;
	EndIf;
	
	Return PresentationRow;
	
EndFunction
