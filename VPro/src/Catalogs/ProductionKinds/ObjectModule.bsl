
Procedure ПередЗаписью(Отказ)
	
	If ОбменДанными.Загрузка Then
		Return;
	EndIf;
	
	TSRow = Stages.Find(Catalogs.ProductionStages.ProductionComplete, "Stage");
	If TSRow = Undefined Then
		TSRow = Stages.Add();
		TSRow.Stage = Catalogs.ProductionStages.ProductionComplete;
	Else
		Stages.Move(TSRow, Stages.Count() - TSRow.LineNumber);
	EndIf;
	
EndProcedure

Procedure ОбработкаПроверкиЗаполнения(Отказ, ПроверяемыеРеквизиты)
	
	If Отказ ИЛИ ОбменДанными.Загрузка Then
		Return;
	EndIf; 
	
	If Stages.Количество()=0 Then
		CommonUseClientServer.MessageToUser(
		НСтр("ru='Не выбрано ни одного этапа';vi='Chưa chọn công đoạn nào'"),
		ЭтотОбъект,
		"Этапы",
		,
		Отказ);
	EndIf; 
	
	// Проверка удаления выполняемых ранее этапов
	If ValueIsFilled(Ref) Then
		Query = Новый Запрос;
		Query.SetParameter("Ref", Ref);
		Query.SetParameter("Этапы", Stages.UnloadColumn("Stage"));
		Query.Text =
		"SELECT
		|	ЭтапыПроизводстваОбороты.Stage AS Stage
		|FROM
		|	AccumulationRegister.ProductionStages.Turnovers(
		|			,
		|			,
		|			,
		|			Specification.ProductionKind = &Ref
		|				AND Stage <> VALUE(Catalog.ProductionStages.ProductionComplete)
		|				AND NOT Stage IN (&Этапы)) AS ЭтапыПроизводстваОбороты
		|
		|GROUP BY
		|	ЭтапыПроизводстваОбороты.Stage";
		Result = Query.Execute();
		If NOT Result.IsEmpty() Then
			Выборка = Result.Select();
			ПредставлениеЭтапов = "";
			Пока Выборка.Следующий() Цикл
				ПредставлениеЭтапов = ПредставлениеЭтапов + ?(ПустаяСтрока(ПредставлениеЭтапов), "", ", ") + Строка(Выборка.Stage);	
			КонецЦикла;
			ТекстОшибки = СтрШаблон(НСтр("ru='По виду производства ранее %1 %2. Удаление %3 невозможно.';vi='Theo dạng sản xuất trước %1 %2. Không thể xóa %3.'"),
			?(Выборка.Количество()=1, НСтр("ru='выполнялся этап';vi='đã thực hiện công đoạn'"), НСтр("ru='выполнялись этапы:';vi='đã thực hiện các công đoạn:'")),
			ПредставлениеЭтапов,
			?(Выборка.Количество()=1, НСтр("ru='этого этапа';vi='của công đoạn này'"), НСтр("ru='этих этапов';vi='của các công đoạn này'")));
			CommonUseClientServer.MessageToUser(
			ТекстОшибки,
			ЭтотОбъект,
			"Этапы",
			,
			Отказ);
		EndIf; 
	EndIf; 
	
	// Дублирование этапов
	Query = Новый Запрос;
	Query.SetParameter("Этапы", Stages.Unload());
	Query.Text = 
	"SELECT
	|	Этапы.LineNumber AS LineNumber,
	|	Этапы.Stage AS Stage,
	|	1 AS Количество
	|INTO Этапы
	|FROM
	|	&Этапы AS Этапы
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Этапы.Stage AS Stage,
	|	MAX(Этапы.LineNumber) AS LineNumber,
	|	SUM(Этапы.Количество) AS Количество
	|FROM
	|	Этапы AS Этапы
	|
	|GROUP BY
	|	Этапы.Stage
	|
	|HAVING
	|	SUM(Этапы.Количество) > 1";
	
	Выборка = Query.Execute().Select();
	Пока Выборка.Next() Цикл
		CommonUseClientServer.MessageToUser(
		СтрШаблон(НСтр("ru='Дублирование этапов производства: %1';vi='Trùng lặp các công đoạn sản xuất: %1'"), Выборка.Stage),
		ЭтотОбъект,
		CommonUseClientServer.PathToTabularSection("Этапы", Выборка.НомерСтроки, "Stage"),
		,
		Отказ);
	КонецЦикла;
	
EndProcedure

