#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region ProgramInterface

Function SaveChangesCalendarRecords(ProcessedItems) Export
	
	UnvisibleRecords = New Array;
	SubordinateToSource = New Map;
	
	For Each ProcessedItem In ProcessedItems Do
		If ValueIsFilled(ProcessedItem.Src) Then
			RecordsBySource = SubordinateToSource.Get(ProcessedItem.Src);
			If RecordsBySource = Undefined Then
				RecordsBySource = New Array;
				RecordsBySource.Add(ProcessedItem);
				SubordinateToSource.Insert(ProcessedItem.Src, RecordsBySource);
			Else
				RecordsBySource.Add(ProcessedItem);
			EndIf;
		Else
			UnvisibleRecords.Add(ProcessedItem);
		EndIf;
	EndDo;
	
	BeginTransaction();
	
	Try
	
		For Each KeyAndValue In SubordinateToSource Do
			
			SourceObject = KeyAndValue.Key.GetObject();
			
			If ProcessedItem.Property("DeletionMark") Then
				SourceObject.SetDeletionMark(ProcessedItem.DeletionMark);
				Continue;
			EndIf;
			
			SourceObject.ОбновитьИсточникПриИзмененииЗаписиКалендаря(KeyAndValue.Value);
			SourceObject.Write();
			
		EndDo;
		
		For Each ProcessedItem In UnvisibleRecords Do
			
			RecordObject = ProcessedItem.CalendarRecord.GetObject();
			
			If ProcessedItem.Property("DeletionMark") Then
				RecordObject.SetDeletionMark(ProcessedItem.DeletionMark);
				Continue;
			EndIf;
			
			RecordObject.Begin		= ProcessedItem.Begin;
			RecordObject.End	= ProcessedItem.End;
			RecordObject.Write();
			
		EndDo;
		
		CommitTransaction();
		Successfully = True;
		
	Except
		
		RollbackTransaction();
		Successfully = False;
		Raise StrTemplate(NStr("en='Не удалось сохранить изменения в календаре по причине: %1';ru='Не удалось сохранить изменения в календаре по причине: %1';vi='Không thể lưu các thay đổi vào lịch do: %1'"), DetailErrorDescription(ErrorInfo()));
		
	EndTry;
	
	Return Successfully;
	
EndFunction

// Функция возвращает таблицу описаний возможных расширенных вводов записи календаря
// 
// Returns:
//  ValueTable - таблица с колонками
//		ИмяФормы		- Строка - полный путь к форме для использования в ОтрытьФорму()
//		ПараметрыФормы	- Структура - параметры открываемой формы
//		Представление	- Строка - пользовательское представление расширенного ввода
//
Function ExtandedRecordsInputDescription() Export
	
	DescriptionTable = New ValueTable;
	DescriptionTable.Columns.Add("FormName",		New TypeDescription("String"));
	DescriptionTable.Columns.Add("FormParameters",	New TypeDescription("Structure"));
	DescriptionTable.Columns.Add("Presentation",	New TypeDescription("String"));
	
	RecordsType = Metadata.DefinedTypes.ИсточникЗаписейКалендаря.Type.Types();
	
	For Each TypeCalendarRecords In RecordsType Do
		
		If TypeCalendarRecords = Type("DocumentRef.CustomerOrder")
			Or TypeCalendarRecords = Type("DocumentRef.ProductionOrder")
			Then
			Continue
		EndIf;
		
		TypeMetadata = Metadata.FindByType(TypeCalendarRecords);
		TypeManager = CommonUse.ObjectManagerByFullName(TypeMetadata.FullName());
		
		TypeManager.OnFillingExtendedInputCalendarRecorder(DescriptionTable);
		
	EndDo;
	
	DescriptionTable.Sort("Presentation DESC");
	
	Return DescriptionTable;
	
EndFunction

#EndRegion

#Region WorkProcessInterval

Procedure ContentFieldFillingForWorkProcess(FieldDescriptionTable, Val ActionType) Export
	
	CalendarsRecordsMD = Metadata.Catalogs.EmployeesCalendarsRecords;
	
	NewDetails = FieldDescriptionTable.Add();
	NewDetails.AttributeName				= CalendarsRecordsMD.Attributes.Calendar.Name;
	NewDetails.Title					= CalendarsRecordsMD.Attributes.Calendar.Synonym;
	NewDetails.FillVariant			= "Specified";
	NewDetails.ValueType				= CalendarsRecordsMD.Attributes.Calendar.Type;
	NewDetails.Mandatory	= True;
	
	NewDetails = FieldDescriptionTable.Add();
	NewDetails.AttributeName				= CalendarsRecordsMD.Attributes.Begin.Name;
	NewDetails.Title					= CalendarsRecordsMD.Attributes.Begin.Synonym;
	NewDetails.FillVariant			= "Shift";
	NewDetails.ValueType				= CalendarsRecordsMD.Attributes.Begin.Type;
	NewDetails.Mandatory	= True;
	
	NewDetails = FieldDescriptionTable.Add();
	NewDetails.AttributeName				= CalendarsRecordsMD.Attributes.End.Name;
	NewDetails.Title					= CalendarsRecordsMD.Attributes.End.Synonym;
	NewDetails.FillVariant			= "Shift";
	NewDetails.ValueType				= CalendarsRecordsMD.Attributes.End.Type;
	NewDetails.Mandatory	= True;
	
	NewDetails = FieldDescriptionTable.Add();
	NewDetails.AttributeName				= "Description";
	NewDetails.Title					= NStr("en='Представление';ru='Представление';vi='Trình bày'");
	NewDetails.FillVariant			= "Specified";
	NewDetails.ValueType				= CommonUse.TypeDescriptionRow(CalendarsRecordsMD.DescriptionLength);
	NewDetails.Mandatory	= True;
	
	NewDetails = FieldDescriptionTable.Add();
	NewDetails.AttributeName				= CalendarsRecordsMD.Attributes.Description.Name;
	NewDetails.Title					= CalendarsRecordsMD.Attributes.Description.Synonym;
	NewDetails.FillVariant			= "Specified";
	NewDetails.ValueType				= CalendarsRecordsMD.Attributes.Description.Type;
	
EndProcedure

#EndRegion

#Region ИнтерфейсКалендаряСотрудника

// Функция определяет пиктограмму для элемента записи календаря
//
// Параметры:
//  ЗаписьКалендаряПодготовкиОтчетности	 - СправочникСсылка.ЗаписьКалендаряПодготовкиОтчетности
// 
// Возвращаемое значение:
//  Картинка - пиктограмма записи календаря
//
Функция CalendarRecordPicture(ЗаписьКалендаряПодготовкиОтчетности) Экспорт
	
	Возврат Новый Картинка;
	
КонецФункции

// Функция определяет цвет текста для элемента записи календаря
//
// Параметры:
//  ЗаписьКалендаряПодготовкиОтчетности	 - СправочникСсылка.ЗаписьКалендаряПодготовкиОтчетности
// 
// Возвращаемое значение:
//  Цвет - цвет текста записи календаря
//
Функция CalendarRecorTextColor(ЗаписьКалендаряПодготовкиОтчетности) Экспорт
	
	Возврат Новый Цвет;
	
КонецФункции

// Процедура заполняет таблицу описаний расширенного ввода записи календаря
//
// Параметры:
//  ТаблицаОписаний	 - ТаблицаЗначений	 - описание колонок см. Справочник.ЗаписиКалендаряСотрудника.ПриЗаполненииРасширенногоВводаЗаписиКалендаря()
//
Процедура OnFillingExtendedInputCalendarRecorder(ТаблицаОписаний) Экспорт
	
	// Запись календаря подготовки отчетности не редактируется пользователем
	
КонецПроцедуры

#EndRegion

#EndIf