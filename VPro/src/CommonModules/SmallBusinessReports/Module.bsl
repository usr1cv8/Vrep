Function GetPeriodPresentation(ReportParameters, OnlyDates  = False)
	
	TextPeriod = "";
	
	If ReportParameters.Property("Period") Then
		
		If ValueIsFilled(ReportParameters.Period) Then
			TextPeriod = ?(OnlyDates, "", " on ") + Format(ReportParameters.Period, "DLF=D");
		EndIf;
		
	ElsIf ReportParameters.Property("BeginOfPeriod")
		AND ReportParameters.Property("EndOfPeriod") Then
		
		BeginOfPeriod = ReportParameters.BeginOfPeriod;
		EndOfPeriod  = ReportParameters.EndOfPeriod;
		
		If ValueIsFilled(EndOfPeriod) Then 
			If EndOfPeriod >= BeginOfPeriod Then
				TextPeriod = ?(OnlyDates, "", " for ") + PeriodPresentation(BegOfDay(BeginOfPeriod), EndOfDay(EndOfPeriod), "FP = True");
			Else
				TextPeriod = "";
			EndIf;
		ElsIf ValueIsFilled(BeginOfPeriod) AND Not ValueIsFilled(EndOfPeriod) Then
			TextPeriod = ?(OnlyDates, "", " for ") + PeriodPresentation(BegOfDay(BeginOfPeriod), EndOfDay(Date(3999, 11, 11)), "FP = True");
			TextPeriod = StrReplace(TextPeriod, Mid(TextPeriod, Find(TextPeriod, " - ")), " - ...");
		EndIf;
		
	EndIf;
	
	Return TextPeriod;
	
EndFunction

Function FilterUniversalReportSource(Val SourceMetadata, Val ReportParameters) Export
	
	SourceFilter = "";
	
	If ReportParameters.MetadataObjectType = "Documents" 
		Or ReportParameters.MetadataObjectType = "Tasks"
		Or ReportParameters.MetadataObjectType = "BusinessProcesses" Then
		
		If ValueIsFilled(ReportParameters.TableName)
			And CommonUseClientServer.HasAttributeOrObjectProperty(SourceMetadata, "TabularSections")
			And CommonUseClientServer.HasAttributeOrObjectProperty(SourceMetadata.TabularSections, ReportParameters.TableName) Then 
			SourceFilter = " AS VirtualTable
				|{WHERE
				|	(VirtualTable.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod)}";
		Else
			SourceFilter = " AS VirtualTable
				|{WHERE
				|	(VirtualTable.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod)}";
		EndIf;
	ElsIf ReportParameters.TableName = "BalanceAndTurnovers"
		Or ReportParameters.TableName = "Turnovers" Then
		SourceFilter = "({&BeginOfPeriod}, {&EndOfPeriod}, Auto) AS VirtualTable";
	ElsIf ReportParameters.TableName = "Balances"
		Or ReportParameters.TableName = "SliceLast" Then
		SourceFilter = "({&EndOfPeriod},) AS VirtualTable";
	ElsIf ReportParameters.TableName = "SliceFirst" Then
		SourceFilter = "({&BeginOfPeriod},) AS VirtualTable";
	ElsIf ReportParameters.MetadataObjectType = "InformationRegisters"
		And SourceMetadata.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then
		SourceFilter = " AS VirtualTable
			|{WHERE
			|	(VirtualTable.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod)}";
	ElsIf ReportParameters.MetadataObjectType = "AccumulationRegisters"
		Or ReportParameters.MetadataObjectType = "AccountingRegisters" Then
		SourceFilter = " AS VirtualTable
			|{WHERE
			|	(VirtualTable.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod)}";
	ElsIf ReportParameters.MetadataObjectType = "CalculationRegisters" Then
		SourceFilter = " AS VirtualTable
			|{WHERE
			|	VirtualTable.RegistrationPeriod BETWEEN &BeginOfPeriod AND &EndOfPeriod}";
	EndIf;
	
	Return SourceFilter;
	
EndFunction


Function GetReportTitleText(ReportParameters)
	
	HeaderText = ReportParameters.Title + GetPeriodPresentation(ReportParameters);
	Return HeaderText;
	
EndFunction

Function GetPeriodicityValue(BeginOfPeriod, EndOfPeriod) Export
	
	Result = Enums.Periodicity.Month;
	If ValueIsFilled(BeginOfPeriod)
		AND ValueIsFilled(EndOfPeriod) Then
		
		Diff = EndOfPeriod - BeginOfPeriod;
		If Diff / 86400 < 45 Then
			Result = Enums.Periodicity.Day;
		Else
			Result = Enums.Periodicity.Month; // Month
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

Procedure OutputReportTitle(ReportParameters, Result) Export
	
	OutputParameters = ReportParameters.ReportSettings.OutputParameters;
	
	OutputParameter = OutputParameters.FindParameterValue(New DataCompositionParameter("TitleOutput"));
	If OutputParameter <> Undefined
		AND (NOT OutputParameter.Use OR OutputParameter.Value <> DataCompositionTextOutputType.DontOutput) Then
		OutputParameter.Use = True;
		OutputParameter.Value = DataCompositionTextOutputType.DontOutput; // disable the standard output of a title
	EndIf;
	
	OutputParameter = OutputParameters.FindParameterValue(New DataCompositionParameter("DataParametersOutput"));
	If OutputParameter <> Undefined
		AND (NOT OutputParameter.Use OR OutputParameter.Value <> DataCompositionTextOutputType.DontOutput) Then
		OutputParameter.Use = True;
		OutputParameter.Value = DataCompositionTextOutputType.DontOutput; // disable the parameters standard output
	EndIf;
	
	OutputParameter = OutputParameters.FindParameterValue(New DataCompositionParameter("FilterOutput"));
	If OutputParameter <> Undefined
		AND (NOT OutputParameter.Use OR OutputParameter.Value <> DataCompositionTextOutputType.DontOutput) Then
		OutputParameter.Use = True;
		OutputParameter.Value = DataCompositionTextOutputType.DontOutput; // disable the standard output of a filter
	EndIf;
	
	Template = GetCommonTemplate("StandardReportCommonAreas");
	HeaderArea        = Template.GetArea("HeaderArea");
	SettingsDescriptionField = Template.GetArea("SettingsDescription");
	
	// Title
	If ReportParameters.TitleOutput 
		AND ValueIsFilled(ReportParameters.Title) Then
		HeaderArea.Parameters.ReportHeader = GetReportTitleText(ReportParameters);
		Result.Put(HeaderArea);
		
		// Filter
		TextFilter = "";
		
		If ReportParameters.Property("ParametersToBeIncludedInSelectionText")
			AND TypeOf(ReportParameters.ParametersToBeIncludedInSelectionText) = Type("Array") Then
			
			For Each Parameter IN ReportParameters.ParametersToBeIncludedInSelectionText Do
				If TypeOf(Parameter) <> Type("DataCompositionSettingsParameterValue")
					OR Not Parameter.Use Then
					Continue;
				EndIf;
				TextFilter = TextFilter + ?(IsBlankString(TextFilter), "", NStr("en=' AND ';ru=' И ';vi='VÀ'")) 
					+ TrimAll(Parameter.UserSettingPresentation) + " Equal """ + TrimAll(Parameter.Value) + """";
				
			EndDo;
		EndIf;
		
		For Each FilterItem IN ReportParameters.ReportSettings.Filter.Items Do
			If TypeOf(FilterItem) <> Type("DataCompositionFilterItem")
				OR Not FilterItem.Use
				OR Not ValueIsFilled(FilterItem.UserSettingID)
				OR FilterItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible Then
				Continue;
			EndIf;
			TextFilter = TextFilter + ?(IsBlankString(TextFilter), "", NStr("en=' AND ';ru=' И ';vi='VÀ'")) 
				+ TrimAll(FilterItem.LeftValue) + " " + TrimAll(FilterItem.ComparisonType) + " """ + TrimAll(FilterItem.RightValue) + """";
			
		EndDo;
		
		If Not IsBlankString(TextFilter) Then
			SettingsDescriptionField.Parameters.NameReportSettings      = NStr("en='Filter:';ru='Фильтр:';vi='Bộ lọc:'");
			SettingsDescriptionField.Parameters.DescriptionReportSettings = TextFilter;
			Result.Put(SettingsDescriptionField);
		EndIf;
		
		Result.Area("R1:R" + Result.TableHeight).Name = "Title";
		
	EndIf;
	
EndProcedure

// Procedure sets the calculation formula and dynamic period format.
//
// Parameters:
// 	DataCompositionSchema - DataCompositionSchema - DLS
// 	of the SettingsLinker report - DataCompositionSettings - report settings
//
Procedure CustomizeDynamicPeriod(DataCompositionSchema, ReportParameters, ExpandPeriod = False) Export
	
	ReportSettings = ReportParameters.ReportSettings;
	
	FieldParameter = New DataCompositionParameter("Periodicity");
	ParameterPeriodicity = ReportSettings.DataParameters.FindParameterValue(FieldParameter);
	
	If ParameterPeriodicity <> Undefined
		AND ParameterPeriodicity.Use Then
		
		If Not ValueIsFilled(ParameterPeriodicity.Value)
			OR ParameterPeriodicity.Value = Enums.Periodicity.Auto Then
			ParameterPeriodicity.Value = GetPeriodicityValue(ReportParameters.BeginOfPeriod, ReportParameters.EndOfPeriod);
		EndIf;
		
		SearchField = DataCompositionSchema.CalculatedFields.Find("DynamicPeriod");
		If SearchField <> Undefined Then
			StringDurationPeriod = CommonUse.NameOfEnumValue(ParameterPeriodicity.Value);
			SearchField.Expression = StringDurationPeriod + "Period";
			SearchField.Title = StringDurationPeriod;
			
			AppearanceParameterFormat = SearchField.Appearance.Items.Find("Format");
			AppearanceParameterFormat.Value = FormatStringOfDynamicPeriod(ParameterPeriodicity.Value);
			AppearanceParameterFormat.Use = True;
			
			If ExpandPeriod
				AND ReportParameters.Property("BeginOfPeriod")
				AND ReportParameters.Property("EndOfPeriod") Then
				
				PeriodAddition = DataCompositionPeriodAdditionType[StringDurationPeriod];
				FieldDynamicPeriod = New DataCompositionField("DynamicPeriod");
				Groups = GetGroups(ReportSettings);
				For Each Group IN Groups Do
					If Group.Value.GroupFields.Items.Count() = 1
						AND Group.Value.GroupFields.Items[0].Field = FieldDynamicPeriod Then
						GroupingDynamicPeriod = Group.Value.GroupFields.Items[0];
						GroupingDynamicPeriod.AdditionType = PeriodAddition;
						GroupingDynamicPeriod.BeginOfPeriod = ReportParameters.BeginOfPeriod;
						GroupingDynamicPeriod.EndOfPeriod = ReportParameters.EndOfPeriod;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

Function FormatStringOfDynamicPeriod(Periodicity) Export
	
	FormatString = "";
	
	If Periodicity = Enums.Periodicity.Day Then
		FormatString = "L=En; DF='dd.MM.yy'";
	ElsIf Periodicity = Enums.Periodicity.Week Then
		FormatString = "L=En; DF='dd.MM.yy'";
	ElsIf Periodicity = Enums.Periodicity.TenDays Then
		FormatString = "L=En; DF='dd.MM.yy'";
	ElsIf Periodicity = Enums.Periodicity.Month Then
		FormatString = "L=En; DF='MMM yy'";
	ElsIf Periodicity = Enums.Periodicity.Quarter Then
		FormatString = "L=En; DF='q ""qtr."" yy'";
	ElsIf Periodicity = Enums.Periodicity.HalfYear Then
		FormatString = "L=En; DF='MM.yy'";
	ElsIf Periodicity = Enums.Periodicity.Year Then
		FormatString = "L=En; DF='yyyy'";
	EndIf;
	
	Return FormatString;
	
EndFunction

Procedure ProcessReportCharts(ReportParameters, ResultDocument) Export
	
	For Each Draw IN ResultDocument.Drawings Do
		// Output labels vertically if the quantity of charts points is more than 6
		Try
			If TypeOf(Draw.Object) = Type("Chart") Then
				
				If ReportParameters.Property("ChartType")
					AND ReportParameters.ChartType <> Undefined
					AND Draw.Object.ChartType <> ReportParameters.ChartType Then
					Draw.Object.ChartType = ReportParameters.ChartType;
				EndIf;
				
				Draw.Object.PlotArea.VerticalLabels = (Draw.Object.Points.Count() > 6);
				Draw.Object.PlotArea.ValueScaleFormat = "NG=3,0";
				
				Draw.Object.GaugeChartValuesScaleLabelsLocation = GaugeChartValuesScaleLabelsLocation.AtScale;
				Draw.Object.GaugeChartValuesScaleLabelsArcDirection = True;
				Draw.Object.GaugeChartValuesScaleLabelsArcDirection = 3;
				Draw.Object.ValueLabelFormat = "NFD=2; NG=3,0";
				
			EndIf;
		Except
		EndTry;
	EndDo;
	
EndProcedure

// Procedure sets the size of the picture with a report chart.
//
Procedure SetReportChartSize(Draw) Export

	Draw.Object.ShowTitle = False;
	Draw.Object.LegendArea.Bottom = 0.90;
	Draw.Height = 95;
	Draw.Width = 145;

EndProcedure

Procedure SetReportAppearanceTemplate(ReportSettings) Export
	
	DesignLayoutParameter = GetInputParameter(ReportSettings, "AppearanceTemplate");
	If DesignLayoutParameter <> Undefined
		AND DesignLayoutParameter.Use
		AND ValueIsFilled(DesignLayoutParameter.Value) Then
		Return;
	EndIf;
	
	AppearanceTemplate = "ReportThemeGreen";
	
	SetOutputParameter(ReportSettings, "AppearanceTemplate", AppearanceTemplate);
	
EndProcedure

// Возвращает поле схемы компоновки данных по имени или полю компоновки данных
//
// Parameters:
//   Scheme - DataCompositionSchema - Схема компоновки данных отчета
//   Field - String, DataCompositionField - Поле компоновки для которого нужно получить соответствующее поле схемы
//
// Returns: 
//   * ПолеНабораДанныхСхемыКомпоновкиДанных,DataCompositionSchemaCalculatedField - Найденное поле схемы компоновки данных
//   * Неопределено                                                               - Если поле не найдено
//
Function SchemaField(Scheme, Field) Export
	
	FieldName = String(Field);
	If IsBlankString(FieldName) Then
		Return Undefined;
	EndIf; 
	For Each Set In Scheme.DataSets Do
		SchemaField = Set.Fields.Find(FieldName);
		If Not SchemaField=Undefined Then
			Return SchemaField;
		EndIf;  
	EndDo;
	SchemaField = Scheme.CalculatedFields.Find(FieldName);
	If Not SchemaField=Undefined Then
		Return SchemaField;
	EndIf; 
	Return Undefined;
	
EndFunction

// Отмечает в списке значений используемые выбранные поля отчета
//
// Parameters:
//   Items  - DataCompositionSelectedFieldCollection - Коллекция выбранных полй, для которой выполняется рекурсивная отметка полей
//   Result - ValueList - Список полей выбора, для которых нужно определить признак использования
//
Procedure MarkSelectedFieldsRecursively(Items, Result)
	
	For Each SelectedField In Items Do
		If TypeOf(SelectedField)=Type("DataCompositionSelectedField") Then
			Item = Result.FindByValue(String(SelectedField.Field));
			If Not Item=Undefined And SelectedField.Use Then
				Item.Check = True;
			EndIf; 
		ElsIf TypeOf(SelectedField)=Type("DataCompositionSelectedFieldGroup") Then
			MarkSelectedFieldsRecursively(SelectedField.Items, Result);
		EndIf; 
	EndDo; 
	
EndProcedure

// Устанавливает формат вывода поля отчета
//
// Parameters:
//   Grouping - ГруппировкаКомпоновкиДанных, ДиаграммаКомпоновкиДанных, ГруппировкаДиаграммыКомпоновкиДанных,
//	     ТаблицаКомпоновкиДанных или ГруппировкаТаблицыКомпоновкиДанных - Элемент структуры, для которого устанавливается
//       условное оформление с форматом поля
//   FieldName - String - Имя поля, для которого изменяется формат вывода
//   Format - String - Устанавливаемый формат вывода
//
Procedure AddUVFormat(Grouping, FieldName, Format)
	
	DesignElement = Grouping.ConditionalAppearance.Items.Add();
	DesignElement.Use = True;
	FieldUV = DesignElement.Fields.Items.Add();
	FieldUV.Field = New DataCompositionField(FieldName);
	FieldUV.Use = True;
	DesignElement.Appearance.SetParameterValue("Format",Format);
	
EndProcedure

#Region REPORTCREATION

// Возвращает структуру служебных данных для формирования отчета
//
// Parameters:
//    ReportSettings - DataCompositionSettings - Настройки компоновки данных отчета
//
// Returns: 
//   * Структура     - Структура сложебных данных для формирования. Содержит поля;
//      НастройкиОтчета - НастройкиКомпоновкиДанных - Настройки компоновки данных отчета
//      ВыводитьЗаголовок - Булево - Признак отображения заголовка отчета
//      Заголовок - Строка - Заголовок отчета
//      ПараметрыВключаемыеВТекстОтбора - Массив - Массив имен параметров, включаемых в текст отбора при выводе заголовка
//      Переносит параметры из структуры ДополнительныеСвойства настроек компоновки данных
//
Function ReportGenerationParameters(ReportSettings) Export
	
	Result = New Structure;
	Result.Insert("ReportSettings", ReportSettings);
	
	AdditionalProperties = ReportSettings.AdditionalProperties;
	For Each Property In AdditionalProperties Do
		Result.Insert(Property.Key, Property.Value);
	EndDo;
	
	Parameter = ReportSettings.DataParameters.FindParameterValue(New DataCompositionParameter("TitleOutput"));
	Result.Insert("TitleOutput", Not Parameter=Undefined And Parameter.Use And Parameter.Value);
	If Result.TitleOutput And Not Result.Property("Title") Then
		Parameter = ReportSettings.OutputParameters.FindParameterValue(New DataCompositionParameter("Title"));
		If Not Parameter=Undefined And Parameter.Use Then
			Result.Insert("Title", Parameter.Value);
		Else
			Result.Insert("Title", "");
		EndIf; 
	EndIf; 
	
	ParametersToBeIncludedInSelectionText = New Array;
	NonOUTPUTParameters = StringFunctionsClientServer.DecomposeStringIntoSubstringsArray("BeginOfPeriod,EndOfPeriod,Period,ItmPeriod,Periodicity,ChartType,TitleOutput");
	For Each Parameter In ReportSettings.DataParameters.AvailableParameters.Items Do
		If Not NonOUTPUTParameters.Find(String(Parameter.Parameter))=Undefined Then
			Continue;
		EndIf; 
		ParametersToBeIncludedInSelectionText.Add(Parameter); 
	EndDo;
	If ParametersToBeIncludedInSelectionText.Count()>0 Then
		Result.Insert("ParametersToBeIncludedInSelectionText", ParametersToBeIncludedInSelectionText);
	EndIf; 
	
	Return Result;
	
EndFunction

// Добавляет дополнительные вычисляемые поля в схему компоновки данных отчета
//    Добавляемые поля: МесяцГода, ДеньМесяцГода, НеделяГода
//
// Parameters:
//    DataCompositionSchema - DataCompositionSchema - Схема компоновки данных отчета
//
Procedure AddCalculatedFields(DataCompositionSchema) Export
	
	Field = SchemaField(DataCompositionSchema, "PeriodForCalculation");
	If Field=Undefined Then
		Field = SchemaField(DataCompositionSchema, "Period");
	EndIf; 
	If Field=Undefined Then
		Field = SchemaField(DataCompositionSchema, "SecondPeriod");
	EndIf; 
	If Not Field=Undefined Then
		FieldName = Field.DataPath;
		FieldToEval = DataCompositionSchema.CalculatedFields.Find("MonthYear");
		If FieldToEval=Undefined Then
			FieldToEval = DataCompositionSchema.CalculatedFields.Add();
			FieldToEval.DataPath = "MonthYear";
			FieldToEval.Expression = "SmallBusinessReports.MonthYear("+FieldName+")";
			FieldToEval.Title = NStr("en='Месяц года';ru='Месяц года';vi='Tháng của năm'");
			FieldToEval.ValueType = New TypeDescription("Date", New DateQualifiers(DateFractions.Date));
			FieldToEval.Appearance.SetParameterValue("Format", NStr("en='ДФ=ММММ';ru='ДФ=ММММ';vi='ДФ=ММММ'"));
			FieldToEval.UseRestriction.Condition = True;
		EndIf; 
		FieldToEval = DataCompositionSchema.CalculatedFields.Find("MonthOfYearDay");
		If FieldToEval=Undefined Then
			FieldToEval = DataCompositionSchema.CalculatedFields.Add();
			FieldToEval.DataPath = "MonthOfYearDay";
			FieldToEval.Expression = "SmallBusinessReports.MonthOfYearDay("+FieldName+")";
			FieldToEval.Title = NStr("en='День и месяц года';ru='День и месяц года';vi='Ngày và tháng trong năm'");
			FieldToEval.ValueType = New TypeDescription("Date", New DateQualifiers(DateFractions.Date));
			FieldToEval.Appearance.SetParameterValue("Format", NStr("ru = 'ДФ='д ММММ'';
																					|en = 'ДФ='д ММММ'';")); 
			FieldToEval.UseRestriction.Condition = True;
		EndIf; 
		FieldToEval = DataCompositionSchema.CalculatedFields.Find("WeekOfYear");
		If FieldToEval=Undefined Then
			FieldToEval = DataCompositionSchema.CalculatedFields.Add();
			FieldToEval.DataPath = "WeekOfYear";
			FieldToEval.Expression = "SmallBusinessReports.YearWeekNumber("+FieldName+")";
			FieldToEval.ValueType = New TypeDescription("Number", New NumberQualifiers(2, 0, AllowedSign.Nonnegative));
			FieldToEval.Title = NStr("en='Неделя года';ru='Неделя года';vi='Tuần trong năm'");
			FieldToEval.UseRestriction.Condition = True;
		EndIf; 
	EndIf;
	
	Field = SchemaField(DataCompositionSchema, "Counterparty");
	If Field=Undefined Then
		Field = SchemaField(DataCompositionSchema, "Buyer");
	EndIf;
	If Field=Undefined Then
		Field = SchemaField(DataCompositionSchema, "Supplier");
	EndIf;
	If Field<>Undefined Then
		FieldToEval = DataCompositionSchema.CalculatedFields.Find("AddedField_Tag");
		If FieldToEval=Undefined Then
			FieldToEval = DataCompositionSchema.CalculatedFields.Add();
			FieldToEval.DataPath = "AddedField_Tag";
			FieldToEval.Expression = "";
			FieldToEval.ValueType = New TypeDescription("CatalogRef.Tags");
			FieldToEval.Title = NStr("en='Тег';ru='Тег';vi='Nhãn đánh dấu'");
			FieldToEval.UseRestriction.Group = True;
			FieldToEval.UseRestriction.Field = True;
			FieldToEval.UseRestriction.Order = True;
		EndIf; 
		FieldToEval = DataCompositionSchema.CalculatedFields.Find("AddedField_Segment");
		If FieldToEval=Undefined Then
			FieldToEval = DataCompositionSchema.CalculatedFields.Add();
			FieldToEval.DataPath = "AddedField_Segment";
			FieldToEval.Expression = "";
			FieldToEval.ValueType = New TypeDescription("CatalogRef.Segments");
			FieldToEval.Title = NStr("en='Сегмент';ru='Сегмент';vi='Phân nhóm'");
			FieldToEval.UseRestriction.Group = True;
			FieldToEval.UseRestriction.Field = True;
			FieldToEval.UseRestriction.Order = True;
		EndIf; 
	EndIf; 
	
EndProcedure

// Стандартизирует схему компоновки данных отчета
//    * Устанавливает стандартные заголовки периодических полей отчета
//    * Устанавливаент стандартные форматы вывода периодических полей отчета 
//
// Parameters:
//   DataCompositionSchema - DataCompositionSchema - Схема компоновки данных отчета
//
Procedure StandardizeSchema(DataCompositionSchema) Export
	
	FieldsTab = New ValueTable;
	FieldsTab.Columns.Add("Field");
	FieldsTab.Columns.Add("Title");
	FieldsTab.Columns.Add("Format");
	
	// Форматы по умолчанию
	AddFieldsTableRow(FieldsTab, "SecondPeriod", NStr("en='Секунда';ru='Секунда';vi='Giây'"), NStr("ru = 'ДФ='дд.ММ.гггг ЧЧ:мм:сс'';
																						|en = 'ДФ='дд.ММ.гггг ЧЧ:мм:сс'';"));
	AddFieldsTableRow(FieldsTab, "MinutePeriod", NStr("en='Минута';ru='Минута';vi='Phút'"), NStr("ru = 'ДФ='дд.ММ.гггг ЧЧ:мм'';
																					|en = 'ДФ='дд.ММ.гггг ЧЧ:мм'';"));
	AddFieldsTableRow(FieldsTab, "HourPeriod", NStr("en='Час';ru='Час';vi='Giờ'"), NStr("ru = 'ДФ='дд.ММ.гггг ЧЧ:00'';
																				|en = 'ДФ='дд.ММ.гггг ЧЧ:00'';"));
	AddFieldsTableRow(FieldsTab, "DayPeriod", NStr("en='День';ru='День';vi='Ngày'"), NStr("en='ДФ=дд.ММ.гггг';ru='ДФ=дд.ММ.гггг';vi='ДФ=дд.ММ.гггг'"));
	AddFieldsTableRow(FieldsTab, "WeekPeriod", NStr("en='Начало недели';ru='Начало недели';vi='Đầu tuần'"), NStr("en='ДФ=дд.ММ.гггг';ru='ДФ=дд.ММ.гггг';vi='ДФ=дд.ММ.гггг'"));
	AddFieldsTableRow(FieldsTab, "TenDaysPeriod", NStr("en='Начало декады';ru='Начало декады';vi='Đầu mười ngày'"), NStr("en='ДФ=дд.ММ.гггг';ru='ДФ=дд.ММ.гггг';vi='ДФ=дд.ММ.гггг'"));
	AddFieldsTableRow(FieldsTab, "MonthPeriod", NStr("en='Месяц';ru='Месяц';vi='Trong tháng tới'"), NStr("ru = 'ДФ='МММ гггг'';
																					|en = 'ДФ='МММ гггг'';"));
	AddFieldsTableRow(FieldsTab, "QuarterPeriod", NStr("en='Квартал';ru='Квартал';vi='Quý'"), NStr("ru = 'ДФ='к ''кв.'' гггг'';
																						|en = 'ДФ='к ''кв.'' гггг'';"));
	AddFieldsTableRow(FieldsTab, "HalfYearPeriod", NStr("en='Начало полугодия';ru='Начало полугодия';vi='Đầu nửa năm'"), NStr("en='ДФ=дд.ММ.гггг';ru='ДФ=дд.ММ.гггг';vi='ДФ=дд.ММ.гггг'"));
	AddFieldsTableRow(FieldsTab, "YearPeriod", NStr("en='Год';ru='Год';vi='Trong năm tới'"), NStr("en='ДФ=гггг';ru='ДФ=гггг';vi='ДФ=гггг'"));
	
	For Each Str In FieldsTab Do
		Field = SchemaField(DataCompositionSchema, Str.Field);
		If Field=Undefined Then
			Continue;
		EndIf; 
		If ValueIsFilled(Str.Title) Then
			Field.Title = Str.Title;
		EndIf; 
		If ValueIsFilled(Str.Format) Then
			Field.Appearance.SetParameterValue("Format", Str.Format); 
		EndIf; 
	EndDo;
	
EndProcedure

// Стандартный обработчик компонови результата отчета
//
// Parameters:
//    SettingsComposer - DataCompositionSettingsComposer - Компоновщик настроек компоновки данных отчета
//    DataCompositionSchema - DataCompositionSchema - Схема компоновки данных отчета
//    ResultDocument - SpreadsheetDocument - Результат компоновки отчета
//    DetailsData - DataCompositionDetailsData - Данные расшифровки
//    StandardProcessing - Boolean - Признак выполнения стандартной обработки компоновки
//
Procedure OnResultComposition(SettingsComposer, DataCompositionSchema, ResultDocument, DetailsData, StandardProcessing) Export
	
	StandardProcessing = False;
	
	ReportSettings = SettingsComposer.Settings;
	AdditionalProperties = ReportSettings.AdditionalProperties;
	ReportParameters = ReportGenerationParameters(ReportSettings);
	
	If AdditionalProperties.Property("SchemaURL") And IsTempStorageURL(AdditionalProperties.SchemaURL) Then
		DataCompositionSchema = GetFromTempStorage(AdditionalProperties.SchemaURL);
	Else
		StandardizeSchema(DataCompositionSchema);
		AddCalculatedFields(DataCompositionSchema);
	EndIf; 
	
	SmallBusinessReports.SetReportAppearanceTemplate(ReportSettings);
	SmallBusinessReports.OutputReportTitle(ReportParameters, ResultDocument);
	
	ParametersForm = New Structure;
	ParametersForm.Insert("ColumnsGroup", ?(AdditionalProperties.Property("ColumnsGroup"), AdditionalProperties.ColumnsGroup, "ColumnsGroup"));
	ParametersForm.Insert("Comparison", ?(AdditionalProperties.Property("Comparison"), AdditionalProperties.Comparison, "Comparison"));
	If TypeOf(ParametersForm.Comparison)=Type("EnumRef.Periodicity") Then
		ParametersForm.Insert("Comparison", "DynamicPeriod");
	EndIf;
	ParametersForm.Insert("GroupingOrder", New Array);
	ParametersForm.Insert("GroupingOrderFilled", False);
	ParametersForm.Insert("ComparisonFieldsStructure", New Structure);
	If AdditionalProperties.Property("UseComparison") And AdditionalProperties.UseComparison Then
		SmallBusinessReports.CustomizeDynamicPeriod(DataCompositionSchema, ReportParameters);
		UpdateComparisonFields(DataCompositionSchema, ReportSettings, ParametersForm);
	EndIf; 
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	//Создадим и инициализируем процессор компоновки
	CompositionProcessor = New DataCompositionProcessor;
	
	If AdditionalProperties.Property("ExternalDataSets") And IsTempStorageURL(AdditionalProperties.ExternalDataSets) Then
		CompositionProcessor.Initialize(CompositionTemplate, GetFromTempStorage(AdditionalProperties.ExternalDataSets), DetailsData, True);
	Else
		CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);
	EndIf; 

	//Создадим и инициализируем процессор вывода результата
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);

	//Обозначим начало вывода
	OutputProcessor.BeginOutput();
	TableFixed = False;

	ResultDocument.FixedTop = 0;
	
	//Основной цикл вывода отчета
	AreasForDeletion = New Array;
	
	While True Do
		//Получим следующий элемент результата компоновки
		ResultItem = CompositionProcessor.Next();

		If ResultItem = Undefined Then
			//Следующий элемент не получен - заканчиваем цикл вывода
			Break;
		Else
			// Зафиксируем шапку
			If  Not TableFixed 
				  And ResultItem.ParameterValues.Count() > 0 
				  And TypeOf(SettingsComposer.Settings.Structure[0]) <> Type("DataCompositionChart") Then

				TableFixed = True;
				ResultDocument.FixedTop = ResultDocument.TableHeight;

			EndIf;
			//Элемент получен - выведем его при помощи процессора вывода
			OutputProcessor.OutputItem(ResultItem);
			
			If AdditionalProperties.Property("Comparison") And TypeOf(AdditionalProperties.Comparison)=Type("EnumRef.Periodicity") Then
				OutputPicturesToResultItem(ResultItem, DetailsData, ResultDocument, ParametersForm); 
			EndIf; 
			
		EndIf;
	EndDo;

	OutputProcessor.EndOutput();
	
	If (ReportParameters.Property("TitleOutput") And ReportParameters.TitleOutput) Then
		// Область заголовка использует собственную ширину колонок и нарушает фиксацию 
		ResultDocument.FixedLeft = 0;
		ResultDocument.FixedTop = 0;
	ElsIf CommonUse.IsMobileClient() Then
		// Для мобильного клиента фиксация не позволяет корректно работать с табличным документом 
		ResultDocument.FixedLeft = 0;
		ResultDocument.FixedTop = 0;
	ElsIf (AdditionalProperties.Property("ColumnsFixing") And AdditionalProperties.ColumnsFixing) Then
		ResultDocument.FixedLeft = RowsLockLeft(SettingsComposer);
	EndIf; 
	
	For Each Area In AreasForDeletion Do
		ResultDocument.DeleteArea(Area, SpreadsheetDocumentShiftType.Vertical);
	EndDo;
	
	ExecuteOperationsAfterGeneration(ResultDocument, ParametersForm);
	
EndProcedure

// Изменяет схему отчета для поддержки мультивалютности
//
// Parameters:
//    DataCompositionSchema - DataCompositionSchema - Схема компоновки данных отчета
//    Settings - DataCompositionSettings - Настройки компоновки данных отчета
//
Procedure ProcessMulticurrencyReportSchema(DataCompositionSchema, Settings) Export
	
	If Settings.Structure.Count()>1 Then
		Return;
	EndIf; 
	GroupsWithCurrencies = MulticurrencyGroupsRecursively(Settings.Structure);
	AddPeriodGroupings(GroupsWithCurrencies, DataCompositionSchema);
	If GroupsWithCurrencies.Count()=0 Then
		Return;
	EndIf; 
	ColumnsGroups = ColumnsGroupsRecursively(Settings.Structure);
	GroupsWithoutCurrencies = OtherGroups(Settings, GroupsWithCurrencies, ColumnsGroups);
	SelectedResources = New Array;
	For Each Resource In DataCompositionSchema.TotalFields Do
		Resource.Groups.Clear();
		For Each GroupName In GroupsWithoutCurrencies Do
			Resource.Groups.Add(GroupName);
		EndDo;
		Resource.Groups.Add("Overall");
	EndDo; 
	For Each ChoiceField In Settings.SelectionAvailableFields.Items Do
		If Not ChoiceField.Resource Then
			Continue;
		EndIf; 
		FieldName = String(ChoiceField.Field);
		If Find(FieldName, "Currency")>0 Then
			Continue;
		EndIf; 
		Suffixes = StringFunctionsClientServer.DecomposeStringIntoSubstringsArray("OpeningBalance,Receipt,Expense,Turnover,ClosingBalance,Balance,");
		SelectionFieldCur = Undefined;
		For Each Suffix In Suffixes Do
			If IsBlankString(Suffix) Then
				FieldNameCur = FieldName+"Currency";
			Else
				Position = Find(FieldName, Suffix);
				If Position=0 Then
					Continue;
				EndIf;
				FieldNameCur = Left(FieldName, Position-1)+"Currency"+Mid(FieldName, Position);
			EndIf; 
			SelectionFieldCur = Settings.SelectionAvailableFields.FindField(New DataCompositionField(FieldNameCur));
			If SelectionFieldCur=Undefined Then
				Continue;
			EndIf; 
			Break;
		EndDo;
		If Not SelectionFieldCur=Undefined Then
			NewResource = DataCompositionSchema.TotalFields.Add();
			NewResource.DataPath = FieldName;
			NewResource.Expression = "SUM("+FieldNameCur+")";
			For Each Grouping In GroupsWithCurrencies Do
				NewResource.Groups.Add(Grouping);
			EndDo; 
		EndIf; 
	EndDo; 
	
EndProcedure

// Обновляет состав дополнительных вычисляемых полей для поддержки режима сравнения
//
// Parameters:
//    DataCompositionSchema - DataCompositionSchema - Схема компоновки данных отчета
//    Настройки - НастройкиКомпоновкиДанных - Настройки компоновки данных отчета
//    ParametersForm - Structure - Служебные параметры формирования отчета
//
Procedure UpdateComparisonFields(DataCompositionSchema, ReportSettings, ParametersForm) Export
	
	If Not ValueIsFilled(ParametersForm.Comparison) Then
		Return;
	EndIf;
	
	If ReportSettings.Structure.Count()=0 Then
		Return;
	EndIf; 
	For Each StructureItem In ReportSettings.Structure Do
		If TypeOf(StructureItem)=Type("DataCompositionTable") Then
			Break;
		EndIf; 
	EndDo;
	If Not TypeOf(StructureItem)=Type("DataCompositionTable") Then
		Return;
	EndIf;
	
	Structure = StructureItem.Columns;
	If Structure.Count()=0 Then
		Return;
	EndIf; 
	ComparisonFieldName = ParametersForm.Comparison;
	IndicatorsList = IndicatorsList(ReportSettings);
	
	If Not ReportSettings.AdditionalProperties.Property("ShowAbsoluteChange") Then
		ReportSettings.AdditionalProperties.Insert("ShowAbsoluteChange", False);
	EndIf; 
	If Not ReportSettings.AdditionalProperties.Property("ShowRelativeChange") Then
		ReportSettings.AdditionalProperties.Insert("ShowRelativeChange", False);
	EndIf; 
	If Not ReportSettings.AdditionalProperties.Property("ShowPictographs") Then
		ReportSettings.AdditionalProperties.Insert("ShowPictographs", False);
	EndIf;
	If Not ReportSettings.AdditionalProperties.Property("Comparison") Then
		ReportSettings.AdditionalProperties.Insert("Comparison", Undefined);
	EndIf;
	
	SettingsChoice = ReportSettings.Selection.Items;
	For Each Indicator In IndicatorsList Do
		NamesOfFields = StringFunctionsClientServer.SubstituteParametersInString("%1Icon,%1Difference,%1Gain", Indicator.Value);
		DeleteComparisonFields(NamesOfFields, SettingsChoice, DataCompositionSchema);
		If Not TypeOf(ReportSettings.AdditionalProperties.Comparison)=Type("EnumRef.Periodicity") Then
			// Ресурсы сравнения добавляем только при сравнении периодов
			Continue;
		EndIf;
		For Each TotalField In DataCompositionSchema.TotalFields Do
			If Not TotalField.DataPath=Indicator.Value Then
				Continue;
			EndIf;
			Expression = TotalField.Expression;
			// Иконка
			If Not ReportSettings.AdditionalProperties.Comparison=Undefined And Indicator.Check Then
				FieldName = Indicator.Value+"Icon";
				FieldToEval = DataCompositionSchema.CalculatedFields.Add();
				FieldToEval.DataPath = FieldName;
				ParametersForm.ComparisonFieldsStructure.Insert(FieldName);
				FieldToEval.Expression = Indicator.Value;
				FieldToEval.Title = " ";
				FieldToEval.Appearance.SetParameterValue("MaximumWidth", 2);
				Resource = DataCompositionSchema.TotalFields.Add();
				Resource.DataPath = FieldToEval.DataPath;
				Resource.Groups.Clear();
				For Each GroupName In TotalField.Groups Do
					Resource.Groups.Add(GroupName); 
				EndDo; 
				Resource.Expression = StringFunctionsClientServer.SubstituteParametersInString(
				"CASE WHEN ISNULL(EvalExpression(""%1"",,, ""Current"", ""Current""),0)= 
				|ISNULL(EvalExpression(""%1"", ""DynamicPeriod"",, ""Prev"", ""Prev""),0) THEN UNDEFINED
				|WHEN ISNULL(EvalExpression(""%1"",,, ""Current"", ""Current""),0)> 
				|ISNULL(EvalExpression(""%1"", ""DynamicPeriod"",, ""Prev"", ""Prev""),0) THEN &UpArrow
				|WHEN ISNULL(EvalExpression(""%1"",,, ""Current"", ""Current""),0)< 
				|ISNULL(EvalExpression(""%1"", ""DynamicPeriod"",, ""Prev"", ""Prev""),0) THEN &DownArrow
				|END",
				StrReplace(Expression, """-""", "0"));
				If Not ChoiceFieldExists(ReportSettings, New DataCompositionField(FieldName)) Then
					NewIndicator = SettingsChoice.Add(Type("DataCompositionSelectedField"));
					NewIndicator.Use = True;
					NewIndicator.Field = New DataCompositionField(FieldToEval.DataPath);
					NewIndicator.Title = FieldToEval.Title;
				EndIf; 
				If DataCompositionSchema.Parameters.Find("UpArrow")=Undefined Then
					Parameter = DataCompositionSchema.Parameters.Add();
					Parameter.Name = "UpArrow";
					Parameter.Use = DataCompositionParameterUse.Always;
					Parameter.Value = 1;
				EndIf; 
				If DataCompositionSchema.Parameters.Find("DownArrow")=Undefined Then
					Parameter = DataCompositionSchema.Parameters.Add();
					Parameter.Name = "DownArrow";
					Parameter.Use = DataCompositionParameterUse.Always;
					Parameter.Value = 2;
				EndIf; 
			EndIf; 
			// + / -
			If ReportSettings.AdditionalProperties.ShowAbsoluteChange And Indicator.Check Then
				FieldName = Indicator.Value+"Difference";
				FieldToEval = DataCompositionSchema.CalculatedFields.Add();
				FieldToEval.DataPath = FieldName;
				ParametersForm.ComparisonFieldsStructure.Insert(FieldName);
				FieldToEval.Expression = Indicator.Value;
				FieldToEval.Title = NStr("en='Разница';ru='Разница';vi='Chênh lệch'");
				Resource = DataCompositionSchema.TotalFields.Add();
				Resource.DataPath = FieldToEval.DataPath;
				Resource.Groups.Clear();
				For Each GroupName In TotalField.Groups Do
					Resource.Groups.Add(GroupName); 
				EndDo; 
				Resource.Expression = StringFunctionsClientServer.SubstituteParametersInString(
				"ISNULL(EvalExpression(""%1"",,, ""Current"", ""Current""),0) - 
				|ISNULL(EvalExpression(""%1"", ""DynamicPeriod"",, ""Prev"", ""Prev""),0)",
				StrReplace(Expression, """-""", "0"));
				If Not ChoiceFieldExists(ReportSettings, New DataCompositionField(FieldName)) Then
					NewIndicator = SettingsChoice.Add(Type("DataCompositionSelectedField"));
					NewIndicator.Use = True;
					NewIndicator.Field = New DataCompositionField(FieldToEval.DataPath);
					NewIndicator.Title = FieldToEval.Title;
				EndIf; 
			EndIf; 
			// %
			If ReportSettings.AdditionalProperties.ShowRelativeChange And Indicator.Check Then
				FieldName = Indicator.Value+"Increase";
				FieldToEval = DataCompositionSchema.CalculatedFields.Add();
				FieldToEval.DataPath = FieldName;
				ParametersForm.ComparisonFieldsStructure.Insert(FieldName);
				FieldToEval.Expression = Indicator.Value;
				FieldToEval.Title = NStr("en='%';ru='%';vi='%'");
				AddUVFormat(StructureItem, FieldToEval.DataPath, "NFD=2");
				Resource = DataCompositionSchema.TotalFields.Add();
				Resource.DataPath = FieldToEval.DataPath;
				Resource.Groups.Clear();
				For Each GroupName In TotalField.Groups Do
					Resource.Groups.Add(GroupName); 
				EndDo; 
				Resource.Expression = StringFunctionsClientServer.SubstituteParametersInString(
				"CASE WHEN ISNULL(EvalExpression(""%1"", ""DynamicPeriod"",, ""Prev"", ""Prev""),0)=0 
				|THEN 0 ELSE (ISNULL(EvalExpression(""%1"",,, ""Current"", ""Current""),0) - 
				|ISNULL(EvalExpression(""%1"", ""DynamicPeriod"",, ""Prev"", ""Prev""),0))/
				|ISNULL(EvalExpression(""%1"", ""DynamicPeriod"",, ""Prev"", ""Prev""),0)*100 END",
				StrReplace(Expression, """-""", "0"));
				If Not ChoiceFieldExists(ReportSettings, New DataCompositionField(FieldName)) Then
					NewIndicator = SettingsChoice.Add(Type("DataCompositionSelectedField"));
					NewIndicator.Use = True;
					NewIndicator.Field = New DataCompositionField(FieldToEval.DataPath);
					NewIndicator.Title = FieldToEval.Title;
				EndIf; 
			EndIf; 
		EndDo; 
	EndDo;
	
EndProcedure

// Выводит картинки из данных расшифровки в отчет. Используется в режиме сравнения
//
// Parameters:
//    ResultItem - DataCompositionResultItem - Элемент результата выполнения компоновки данных
//    DetailsData - DataCompositionDetailsData - Данные расшифровки
//    ResultDocument - SpreadsheetDocument - Результат компоновки отчета
//    ParametersForm - Structure - Служебные параметры формирования отчета
//
Procedure OutputPicturesToResultItem(ResultItem, DetailsData, ResultDocument, ParametersForm) Export
	
	If ResultItem.ParameterValues.Count() = 0 Then 
		Return; 
	EndIf;

	For Each ParameterItem In ResultItem.ParameterValues Do
		If TypeOf(ParameterItem.Value) = Type("DataCompositionDetailsID") Then
			Fields = DetailsData.Items[ParameterItem.Value].GetFields();
			For Each Field In Fields Do
				If Not ParametersForm.GroupingOrderFilled Then
					If ParametersForm.ComparisonFieldsStructure.Count()=0 Then
						ParametersForm.GroupingOrderFilled = True;
					ElsIf Not Field.Field=ParametersForm.ColumnsGroup And Not Field.Field=ParametersForm.Comparison Then
						ParametersForm.GroupingOrderFilled = True;
					Else
						If Not ParametersForm.Property("FirstColumn") Then
							ParametersForm.Insert("FirstColumn", ResultDocument.TableWidth-ParametersForm.ComparisonFieldsStructure.Count()+1);
						EndIf; 
						ParametersForm.GroupingOrder.Add(Field.Field);
					EndIf; 
				EndIf; 
				If Right(String(Field.Field), 6)="Icon" Then
					If Field.Value=1 Then
						Picture = PictureLib.ValueIncreased;
					ElsIf Field.Value=2 Then
						Picture = PictureLib.ValueDecreased;
					Else
						Picture = New Picture;
					EndIf; 
					For ColumnNumber = 1 To ResultDocument.TableWidth Do
						CellArea = ResultDocument.Area(ResultDocument.TableHeight, ColumnNumber, ResultDocument.TableHeight, ColumnNumber);
						If ParameterItem.Value=CellArea.Details Then
							Image = ResultDocument.Drawings.Add(SpreadsheetDocumentDrawingType.Picture);
							Image.PictureSize = PictureSize.AutoSize;
							Image.Picture = Picture;
							Image.TopBorder = False;
							Image.BottomBorder = False;
							Image.RightBorder = False;
							Image.LeftBorder = False;
							Image.LeftBorder = False;
							Image.BackColor = New Color;
							Image.Place(CellArea);
							CellArea.Text = "";
						EndIf; 
					EndDo;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
			
EndProcedure

// Служебные операции после формирования отчета
//    * Удаление лишних колонок для отчетов в режиме сравнения
//    * Обработка диаграмм табличного документа
//
// Parameters:
//    ResultDocument - SpreadsheetDocument - Результат компоновки отчета
//    ParametersForm - Structure - Служебные параметры формирования отчета
//
Procedure ExecuteOperationsAfterGeneration(ResultDocument, ParametersForm) Export
	
	AreasForDeletion = New Array;
	
	OutputComparison = False;
	If ParametersForm.Property("ComparisonFieldsStructure") And ParametersForm.Property("FirstColumn") And ParametersForm.FirstColumn>0 Then
		ParametersForm.GroupingOrder.Add("Overall");
		FieldIndex = 0;
		For Each Field In ParametersForm.GroupingOrder Do
			If Field=ParametersForm.Comparison Then
				If Not OutputComparison Then
					// Для первых колонок сравненеи скрываем
					Position = ParametersForm.FirstColumn+FieldIndex*(ParametersForm.ComparisonFieldsStructure.Count()+1);
					AreasForDeletion.Insert(0, ResultDocument.Area(,Position,,Position+ParametersForm.ComparisonFieldsStructure.Count()-1));
				EndIf; 
				OutputComparison = True;
			Else
				// Для группировки колонок сравнение всегда скрывается
				Position = ParametersForm.FirstColumn+FieldIndex*(ParametersForm.ComparisonFieldsStructure.Count()+1);
				AreasForDeletion.Insert(0, ResultDocument.Area(,Position,,Position+ParametersForm.ComparisonFieldsStructure.Count()-1));
				OutputComparison = False;
			EndIf;
			FieldIndex = FieldIndex+1;
		EndDo; 
	EndIf;
	
	For Each Area In AreasForDeletion Do
		ResultDocument.DeleteArea(Area, SpreadsheetDocumentShiftType.Horizontal);
	EndDo;
	
	WorkAroundSpreadsheetDocumentCharts(ResultDocument);
	
EndProcedure
// Приведение к общему виду диаграмм табличного документа
//
// Parameters:
//    ResultDocument - SpreadsheetDocument - Результат компоновки отчета
//
Procedure WorkAroundSpreadsheetDocumentCharts(ResultDocument) Export
	
	ThinConnector = New Line(ChartLineType.Solid, 1);
	ThickLine = New Line(ChartLineType.Solid, 2);
	SeriesColors = ChartsSeriesColors32();
	// Если точек на диаграмме меньше, то серии рисуем толстой линией, если больше - то тонкой
	MaxGraphPointsWithThickLine = 10;
	RestrictionPercent = 20;
	
	For Each Draw In ResultDocument.Drawings Do
		If Not Draw.DrawingType=SpreadsheetDocumentDrawingType.Chart Then
			Continue;
		EndIf;
		Draw.Height = 95;
		Draw.Width = 180;
		Chart = Draw.Object;
		Chart.ShowTitle = False;
		For SeriesIndex = 0 To Chart.Series.Count() - 1 Do
			Series = Chart.Series[SeriesIndex];
			If Not ValueIsFilled(Series.Value) Then
				Series.Value = NStr("en='<Не указано>';ru='<Не указано>';vi='<Chưa chỉ ra>'")
			EndIf; 
			If SeriesIndex<SeriesColors.Count() Then
				Series.Color = SeriesColors[SeriesIndex];
			Else
				Series.Color = SeriesColors[SeriesIndex%SeriesColors.Count()];
			EndIf;
			If Chart.Points.Count() > MaxGraphPointsWithThickLine Then
				Series.Line = ThinConnector;
			Else
				Series.Line = ThickLine;
			EndIf;
		EndDo;
		
		IsBar = (Chart.ChartType=ChartType.Column 
		Or Chart.ChartType=ChartType.Column3D
		Or Chart.ChartType=ChartType.NormalizedColumn
		Or Chart.ChartType=ChartType.NormalizedColumn3D
		Or Chart.ChartType=ChartType.StackedColumn
		Or Chart.ChartType=ChartType.StackedColumn3D);
		IsHorizontalBar = (Chart.ChartType=ChartType.Bar 
		Or Chart.ChartType=ChartType.Bar3D
		Or Chart.ChartType=ChartType.NormalizedBar
		Or Chart.ChartType=ChartType.NormalizedBar3D
		Or Chart.ChartType=ChartType.StackedBar
		Or Chart.ChartType=ChartType.StackedBar3D);
		IsSchedule = (Chart.ChartType=ChartType.Line 
		Or Chart.ChartType=ChartType.Step
		Or Chart.ChartType=ChartType.StackedLine
		Or Chart.ChartType=ChartType.Area
		Or Chart.ChartType=ChartType.StackedArea
		Or Chart.ChartType=ChartType.NormalizedArea);
		IsPieChart = (Chart.ChartType=ChartType.Pie 
		Or Chart.ChartType=ChartType.Pie3D);
		
		If Chart.Series.Count()<=5 Then
			CollapsedSeries = 0;
		ElsIf IsBar Or IsSchedule Then
			OutputSeries = New Array;
			MaxValue = 0;
			SeriesMap = New Map;
			For PointIndex = 0 To Chart.Points.Count() - 1 Do
				Point = Chart.Points[PointIndex];
				For SeriesIndex = 0 To Chart.Series.Count() - 1 Do
					Series = Chart.Series[SeriesIndex];
					Value = Chart.GetValue(Point, Series).Value;
					Value = ?(ValueIsFilled(Value) And TypeOf(Value)=Type("Number"), Value, 0);
					MaxValue = Max(MaxValue, Value);
					CurrentValue = SeriesMap.Get(Series);
					If Not TypeOf(CurrentValue)=Type("Number") Or Value>CurrentValue Then
						SeriesMap.Insert(Series, Value);
					EndIf; 
				EndDo;
			EndDo;
			Restriction = MaxValue*RestrictionPercent/100;
			For Each Item In SeriesMap Do
				If Item.Value>=Restriction And OutputSeries.Find(Item.Key)=Undefined Then
					OutputSeries.Add(Item.Key);
				EndIf; 
			EndDo; 
			CollapsedSeries = (Chart.Series.Count()-OutputSeries.Count());
		ElsIf IsPieChart Then
			CollapsedSeries = (Chart.Series.Count()-10);
		EndIf;
		
		Chart.SummarySeries.Color = StyleColors.ChartColorMissingData;
		Chart.SummarySeries.Text = NStr("en='Прочее';ru='Прочее';vi='Quan hệ khác'");
		If ValueIsFilled(CollapsedSeries) Then
			Chart.SummarySeries.Text = Chart.SummarySeries.Text+" ("+Format(CollapsedSeries, "NG=0")+")";
		EndIf; 
		If IsSchedule Then
			Chart.PlotArea.ОриентацияМеток = ОриентацияМетокДиаграммы.Horizontal;
			If Chart.Series.Count()>5 Then
				Chart.MaxSeries = MaxSeries.Percent;
				Chart.MaxSeriesPercent = RestrictionPercent;
			EndIf; 
			Chart.PlotArea.Right = 0.75;
			Chart.PlotArea.Bottom = 0.99;
			Chart.LegendArea.Left = 0.76;
			Chart.LegendArea.Top = 0;
			Chart.LabelType = ChartLabelType.None;
		ElsIf IsBar Or IsHorizontalBar Then
			If IsBar Then
				Chart.PlotArea.ОриентацияМеток = ОриентацияМетокДиаграммы.Vertical;
			Else
				Chart.PlotArea.ОриентацияМеток = ОриентацияМетокДиаграммы.Horizontal;
			EndIf; 
			If Chart.Series.Count()>5 Then
				Chart.MaxSeries = MaxSeries.Percent;
				Chart.MaxSeriesPercent = RestrictionPercent;
			EndIf; 
			Chart.PlotArea.Right = 0.75;
			Chart.PlotArea.Bottom = 0.99;
			Chart.LegendArea.Left = 0.76;
			Chart.LegendArea.Top = 0;
			Chart.LabelType = ChartLabelType.None;
		ElsIf IsPieChart Then
			Chart.MaxSeries = MaxSeries.Limited;
			Chart.MaxSeriesCount = 10;
			Chart.PlotArea.Right = 0.65;
			Chart.PlotArea.Bottom = 0.99;
			Chart.LegendArea.Left = 0.66;
			Chart.LegendArea.Top = 0;
			Chart.LabelType = ChartLabelType.Percent;
		EndIf; 
	EndDo;
	
EndProcedure

// Возвращает массив цветов стандартной палитры диаграмм
//
// Returns: 
//   * Массив - Массив элементов типа Цвет
//
Function ChartsSeriesColors32() Export
	
	color = New Array;
	color.Add(New Color(245, 152, 150));
	color.Add(New Color(142, 201, 249));
	color.Add(New Color(255, 202, 125));
	color.Add(New Color(178, 154, 218));
	color.Add(New Color(163, 214, 166));
	color.Add(New Color(244, 140, 175));
	color.Add(New Color(125, 221, 233));
	color.Add(New Color(255, 242, 128));
	color.Add(New Color(205, 145, 215));
	color.Add(New Color(125, 202, 194));
	//10
	color.Add(New Color(229, 216, 165));
	color.Add(New Color(178, 136, 143));
	color.Add(New Color(135, 151, 106));
	color.Add(New Color(94, 163, 153));
	color.Add(New Color(163, 137, 109));
	color.Add(New Color(169, 155, 174));
	color.Add(New Color(122, 131, 135));
	color.Add(New Color(132, 122, 112));
	color.Add(New Color(240, 185, 200));
	color.Add(New Color(158, 152, 131));
	//20
	color.Add(New Color(107, 195, 102));
	color.Add(New Color(188, 255, 189));
	color.Add(New Color(150, 197, 191));
	color.Add(New Color(193, 146, 64));
	color.Add(New Color(197, 146, 250));
	color.Add(New Color(210, 110, 71));
	color.Add(New Color(158, 140, 255));
	color.Add(New Color(114, 149, 92));
	color.Add(New Color(126, 144, 230));
	color.Add(New Color(252, 119, 87));
	//30
	color.Add(New Color(127, 192, 255));
	color.Add(New Color(179, 114, 101));
	Return color;
	
EndFunction
 
#EndRegion

#Region REPORTCREATION_internal

Procedure AddFieldsTableRow(Table, Field, Title = Undefined, Format = Undefined)
	
	Str = Table.Add();
	Str.Field = Field;
	Str.Title = Title;
	Str.Format = Format;
	
EndProcedure

Function MulticurrencyGroupsRecursively(Structure, Val Add = False)
	
	Result = New Array;
	For Each Item In Structure Do
		If TypeOf(Item)=Type("DataCompositionGroup") Or TypeOf(Item)=Type("DataCompositionTableGroup") Then
			For Each Field In Item.GroupFields.Items Do
				FieldName = String(Field.Field);
				If FieldName="Currency" Then
					Add = True;
				EndIf; 
			EndDo;
			For Each Field In Item.GroupFields.Items Do
				FieldName = String(Field.Field);
				If Add And Result.Find(FieldName)=Undefined Then
					If Field.GroupType=DataCompositionGroupType.Items Then
						Result.Add(FieldName);
					ElsIf Field.GroupType=DataCompositionGroupType.HierarchyOnly Then
						Result.Add(FieldName+" Hierarchy");
					ElsIf Field.GroupType=DataCompositionGroupType.Hierarchy Then
						Result.Add(FieldName);
						Result.Add(FieldName+" Hierarchy");
					EndIf; 
				EndIf; 
			EndDo;
			NestedResult = MulticurrencyGroupsRecursively(Item.Structure, Add);
			For Each FieldName In NestedResult Do
				If Not Result.Find(FieldName)=Undefined Then
					Continue;
				EndIf; 
				Result.Add(FieldName);
			EndDo; 
		ElsIf TypeOf(Item)=Type("DataCompositionTable") Then
			NestedResult = MulticurrencyGroupsRecursively(Item.Rows, Add);
			For Each FieldName In NestedResult Do
				If Not Result.Find(FieldName)=Undefined Then
					Continue;
				EndIf; 
				Result.Add(FieldName);
			EndDo;
		EndIf; 
	EndDo;
	Return Result;
	
EndFunction

Procedure AddPeriodGroupings(Groups, DataCompositionSchema)
	
	If Groups.Count()=0 Then
		Return;
	EndIf;
	PeriodFields = New Array;
	For Each Set In DataCompositionSchema.DataSets Do
		For Each Field In Set.Fields Do
			If Not TypeOf(Field)=Type("DataCompositionSchemaDataSetField") Then
				Continue;
			EndIf; 
			If Field.Role.PeriodNumber>0 Then
				PeriodFields.Add(Field.DataPath);
			EndIf; 
		EndDo; 
	EndDo; 
	Add = False;
	For Each FieldName In PeriodFields Do
		If Not Groups.Find(FieldName)=Undefined Then
			Add = True;
			Break;
		EndIf; 
	EndDo;
	
	If Add Then
		For Each FieldName In PeriodFields Do
			If Groups.Find(FieldName)=Undefined Then
				Groups.Add(FieldName);
			EndIf; 
		EndDo; 
	EndIf; 
	
EndProcedure

Function ColumnsGroupsRecursively(Structure)
	
	Result = New Array;
	For Each Item In Structure Do
		If TypeOf(Item)=Type("DataCompositionTableGroup") Then
			For Each Field In Item.GroupFields.Items Do
				FieldName = String(Field.Field);
				If Result.Find(FieldName)=Undefined Then
					If Field.GroupType=DataCompositionGroupType.Items Then
						Result.Add(FieldName);
					ElsIf Field.GroupType=DataCompositionGroupType.HierarchyOnly Then
						Result.Add(FieldName+" Hierarchy");
					ElsIf Field.GroupType=DataCompositionGroupType.Hierarchy Then
						Result.Add(FieldName);
						Result.Add(FieldName+" Hierarchy");
					EndIf; 
				EndIf; 
			EndDo;
			NestedResult = ColumnsGroupsRecursively(Item.Structure);
			For Each FieldName In NestedResult Do
				If Not Result.Find(FieldName)=Undefined Then
					Continue;
				EndIf; 
				Result.Add(FieldName);
			EndDo; 
		ElsIf TypeOf(Item)=Type("DataCompositionTable") Then
			NestedResult = ColumnsGroupsRecursively(Item.Columns);
			For Each FieldName In NestedResult Do
				If Not Result.Find(FieldName)=Undefined Then
					Continue;
				EndIf; 
				Result.Add(FieldName);
			EndDo; 
		EndIf; 
	EndDo;
	Return Result;
	
EndFunction

Function OtherGroups(Settings, CurrencyGroupings, ColumnsGroups)
	
	CatalogTypes = Catalogs.AllRefsType();
	TypesOfPVC = ChartsOfCharacteristicTypes.AllRefsType();
	Result = New Array;
	For Each Field In Settings.GroupAvailableFields.Items Do
		FieldName = String(Field.Field);
		If CurrencyGroupings.Find(FieldName)=Undefined And ColumnsGroups.Find(FieldName)=Undefined Then
			Result.Add(FieldName);
		EndIf;
		For Each Type In Field.ValueType.Types() Do
			If CatalogTypes.ContainsType(Type) Or TypesOfPVC.ContainsType(Type) Then
				ObjectMetadata = Metadata.FindByType(Type);
				If ObjectMetadata.Hierarchical Then
					FieldName = FieldName+" Hierarchy";
					If CurrencyGroupings.Find(FieldName)=Undefined And ColumnsGroups.Find(FieldName)=Undefined Then
						Result.Add(FieldName);
					EndIf;
					Break;
				EndIf; 
			EndIf; 
		EndDo;   
	EndDo;
	Return Result;
	
EndFunction

Function RowsLockLeft(SettingsComposer) Export

    OutputParameter = SettingsComposer.Settings.OutputParameters.Items.Find("GroupFieldsLocation");
	If OutputParameter.Use 
		And OutputParameter.Value = DataCompositionGroupFieldsPlacement.Together Then
		GroupsSeparately = False; 
	Else
		GroupsSeparately = True;
	EndIf; 
    OutputParameter = SettingsComposer.Settings.OutputParameters.Items.Find("AttributePlacement");
	If OutputParameter.Use 
		And OutputParameter.Value = DataCompositionAttributesPlacement.Separately Then
		AttributesSeparately = True; 
	Else
		AttributesSeparately = False;
	EndIf; 
    RowsLockLeft = MaxFieldsNumberRecursively(SettingsComposer.Settings.Structure, GroupsSeparately, AttributesSeparately);

    OutputParameter = SettingsComposer.Settings.OutputParameters.Items.Find("HorizontalOverallPlacement");
    If (OutputParameter.Value = DataCompositionTotalPlacement.Begin
        Or OutputParameter.Value = DataCompositionTotalPlacement.BeginAndEnd)
        And OutputParameter.Use = True Then

        RowsLockLeft = RowsLockLeft + 1;

    EndIf;

    OutputParameter = SettingsComposer.Settings.OutputParameters.Items.Find("ResourcePlacement");
    If OutputParameter.Value = DataCompositionResourcesPlacement.Vertically
        And OutputParameter.Use = True Then

        RowsLockLeft = RowsLockLeft + 1;

    EndIf;

    Return RowsLockLeft;

EndFunction

Function MaxFieldsNumberRecursively(StructureItems, GroupsSeparately, AttributesSeparately)
	
	FieldsCount = 0;
	For Each Item In StructureItems Do
		If Not Item.Use Then
			Continue;
		EndIf; 
		If Not TypeOf(Item)=Type("DataCompositionGroup") And Not TypeOf(Item)=Type("DataCompositionTableGroup") Then
			Continue;
		EndIf;
		If Not GroupsSeparately Then
			Return 1;
		EndIf; 
		GroupFieldsCount = 0;
		For Each GroupingField In Item.GroupFields.Items Do
			If Not GroupingField.Use Then
				Continue;
			EndIf; 
			If Not TypeOf(GroupingField)=Type("DataCompositionGroupField") Then
				Continue;
			EndIf;
			FieldName = String(GroupingField.Field);
			IsAttribute = False;
			Position = Find(FieldName, ".");
			If Not AttributesSeparately And Position>0 Then
				ParentName = Left(FieldName, Position-1);
				For Each CheckField In Item.GroupFields.Items Do
					CheckFieldName  = String(CheckField.Field);
					If FieldName=CheckFieldName Then
						Break;
					EndIf;
					CheckPosition = Find(CheckFieldName, ".");
					CheckParentName = ?(CheckPosition=0, CheckFieldName, Left(CheckFieldName, CheckPosition-1));
					If ParentName=CheckParentName Then
						IsAttribute = True;
						Break;
					EndIf; 
				EndDo;
			EndIf; 
			GroupFieldsCount = GroupFieldsCount+?(IsAttribute, ?(GroupFieldsCount=0, 1, 0), 1);
		EndDo;
		FieldsCount = Max(FieldsCount, GroupFieldsCount);
	EndDo;
	For Each Item In StructureItems Do
		If TypeOf(Item)=Type("DataCompositionGroup") Or TypeOf(Item)=Type("DataCompositionTableGroup") Then
			FieldsCount = Max(FieldsCount, MaxFieldsNumberRecursively(Item.Structure, GroupsSeparately, AttributesSeparately));
		ElsIf TypeOf(Item)=Type("DataCompositionTable") Then
			FieldsCount = Max(FieldsCount, MaxFieldsNumberRecursively(Item.Rows, GroupsSeparately, AttributesSeparately));
		EndIf; 
	EndDo; 
	Return FieldsCount;
	
EndFunction

#EndRegion

#Region ReportSettings

// Добавляет описание контекстной привязки
//
// Parameters:
//   LinkedFields - Array - Массив описаний связанных полей
//   Field - String - Имя поля, по которому выполняется отбор при контекстном открытии
//   Object - String - Полное имя объекта метаданных, к которому выполняется привязка, например "Справочник.Номенклатура"
//   AdditionalSection - Произвольная ссылка - Дополнительная фильтрация. Поддерживается:
//      ПеречислениеСсылка.ТипыНоменклатуры - для разделения номенклатуры
//      ПеречислениеСсылка.ТипыСтруктурныхЕдиниц - для разделения структурных единиц
//      Перечисления вариантов операций документов
//   ComplexAlgorithm - Boolean - Признак использования сложного алгоритма наложения отборов при контекстном открытии
//      В модуле объекта отчета должна присутствовать экспортируемая процедура ПриКонтекстномОткрытии
//   Recommended - Boolean - Признак рекомендуемости для контекстного режима списка отчетов
//
Procedure AddBindingDetails(LinkedFields, Field, Object, AdditionalSection = Undefined, ComplexAlgorithm = False, Recommended = False) Export
	
	DescriptionStructure = New Structure;
	DescriptionStructure.Insert("Field", Field);
	DescriptionStructure.Insert("Object", Object);
	DescriptionStructure.Insert("ComplexAlgorithm", ComplexAlgorithm);
	DescriptionStructure.Insert("AdditionalSection", AdditionalSection);
	DescriptionStructure.Insert("Recommended", Recommended);
	LinkedFields.Add(DescriptionStructure);
	
EndProcedure

Procedure AddCurrencyCharToFieldsHeaders(DataCompositionSchema, Fields, Currency = Undefined) Export
	
	If Currency=Undefined Then
		CurrencyChar = SmallBusinessReUse.GetCharCurrencyPresentation(Constants.AccountingCurrency.Get());
	Else
		CurrencyChar = SmallBusinessReUse.GetCharCurrencyPresentation(Currency);
	EndIf;
	
	FieldsArray = StringFunctionsClientServer.DecomposeStringIntoSubstringsArray(Fields);
	
	For Each Set In DataCompositionSchema.DataSets Do
		For Each Field In FieldsArray Do
			SchemaField = Set.Fields.Find(Field);
			If SchemaField=Undefined Then
				Continue;
			EndIf; 
			SchemaField.Title = SchemaField.Title+", "+CurrencyChar;
	EndDo;
EndDo;
	
EndProcedure

Procedure SetReportParameterByDefault(DCSSettings, ParameterName, Value) Export
	
	DCParameterValue = DCSSettings.DataParameters.Items.Find(ParameterName);
	If DCParameterValue=Undefined Then
		Return;
	EndIf; 
	If ValueIsFilled(DCParameterValue.Value) Then
		Return;
	EndIf;
	
	DCParameterValue.Value = Value;
	
EndProcedure

// Procedure includes parent groupings in the custom settings if at least one child is enabled
//
// Parameters:
// 	SettingsComposer - DataCompositionSettingsComposer - settings
// 	of the UserSettingsModified report - Boolean - flag of advantages modifications is mandatory to be set. report settings
//
Procedure ChangeGroupsValues(SettingsComposer, UserSettingsModified) Export
	UserSettings = SettingsComposer.UserSettings;
	Settings = SettingsComposer.Settings;
	
	For Each UserSetting IN UserSettings.Items Do
		If (TypeOf(UserSetting) = Type("DataCompositionGroup") 
			Or TypeOf(UserSetting) = Type("DataCompositionTableGroup")
			Or TypeOf(UserSetting) = Type("DataCompositionTable"))
			AND UserSetting.Use Then
			CorrectParentGroupsSettings(UserSetting, UserSettings, Settings, UserSettingsModified);
		EndIf;
	EndDo;
EndProcedure

Procedure CorrectParentGroupsSettings(UserSetting, UserSettings, Settings, UserSettingsModified)
	UserSettingID = UserSetting.UserSettingID;
	
	If Not IsBlankString(UserSettingID) Then
		SettingsObject = GetObjectByUserIdentifier(Settings, UserSettingID);
	Else
		SettingsObject = UserSetting;
	EndIf;
	SettingObjectParent = SettingsObject.Parent;
	
	If TypeOf(SettingObjectParent) = Type("DataCompositionGroup") 
		Or TypeOf(SettingObjectParent) = Type("DataCompositionTableGroup")
		Or TypeOf(SettingObjectParent) = Type("DataCompositionTable") Then
		
		ParentCustomSettingID = SettingObjectParent.UserSettingID;
		
		If Not IsBlankString(ParentCustomSettingID) Then
			CustomSettingParent = FindCustomSetting(UserSettings, ParentCustomSettingID);
			CustomSettingParent.Use = True;
			UserSettingsModified = True;
			
			CorrectParentGroupsSettings(CustomSettingParent, UserSettings, Settings, UserSettingsModified);
		Else
			CorrectParentGroupsSettings(SettingObjectParent, UserSettings, Settings, UserSettingsModified);
		EndIf;
	EndIf;
EndProcedure

// Returns a list of all groupings of the settings linker
// 
// Parameters:
// 	StructureItem - item of DLS setting structure, DLS setting or settings linker ShowTablesGroups - shows that column grouping is added to list (by default, True)
//
Function GetGroups(StructureItem, ShowTableGroups = True) Export
	
	FieldList = New ValueList;
	If TypeOf(StructureItem) = Type("DataCompositionSettingsComposer") Then
		Structure = StructureItem.Settings.Structure;
		AddGroups(Structure, FieldList);
	ElsIf TypeOf(StructureItem) = Type("DataCompositionSettings") Then
		Structure = StructureItem.Structure;
		AddGroups(Structure, FieldList);
	ElsIf TypeOf(StructureItem) = Type("DataCompositionTable") Then
		AddGroups(StructureItem.Rows, FieldList);
		AddGroups(StructureItem.Columns, FieldList);
	ElsIf TypeOf(StructureItem) = Type("DataCompositionChart") Then
		AddGroups(StructureItem.Series, FieldList);
		AddGroups(StructureItem.Points, FieldList);
	Else
		AddGroups(StructureItem.Structure, FieldList, ShowTableGroups);
	EndIf;
	
	Return FieldList;
	
EndFunction

// Adds nested groups of the structure item.
//
Procedure AddGroups(Structure, ListOfGroups, ShowTableGroups = True)
	
	For Each StructureItem IN Structure Do
		If TypeOf(StructureItem) = Type("DataCompositionTable") Then
			AddGroups(StructureItem.Rows, ListOfGroups);
			AddGroups(StructureItem.Columns, ListOfGroups);
		ElsIf TypeOf(StructureItem) = Type("DataCompositionChart") Then
			AddGroups(StructureItem.Series, ListOfGroups);
			AddGroups(StructureItem.Points, ListOfGroups);
		Else
			ListOfGroups.Add(StructureItem);
			If ShowTableGroups Then
				AddGroups(StructureItem.Structure, ListOfGroups);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Finds a common setting by custom setting ID.
//
// Parameters:
//   Settings - DataCompositionSettings - Settings collection.
//   UserSettingID - String -
//
Function GetObjectByUserIdentifier(Settings, UserSettingID, Hierarchy = Undefined) Export
	If Hierarchy <> Undefined Then
		Hierarchy.Add(Settings);
	EndIf;
	
	SettingType = TypeOf(Settings);
	
	If SettingType <> Type("DataCompositionSettings") Then
		
		If Settings.UserSettingID = UserSettingID Then
			
			Return Settings;
			
		ElsIf SettingType = Type("DataCompositionNestedObjectSettings") Then
			
			Return GetObjectByUserIdentifier(Settings.Settings, UserSettingID, Hierarchy);
			
		ElsIf SettingType = Type("DataCompositionTableStructureItemCollection")
			OR SettingType = Type("DataCompositionChartStructureItemCollection")
			OR SettingType = Type("DataCompositionSettingStructureItemCollection") Then
			
			For Each NestedItem IN Settings Do
				SearchResult = GetObjectByUserIdentifier(NestedItem, UserSettingID, Hierarchy);
				If SearchResult <> Undefined Then
					Return SearchResult;
				EndIf;
			EndDo;
			
			If Hierarchy <> Undefined Then
				Hierarchy.Delete(Hierarchy.UBound());
			EndIf;
			
			Return Undefined;
			
		EndIf;
		
	EndIf;
	
	If Settings.Selection.UserSettingID = UserSettingID Then
		Return Settings.Selection;
	ElsIf Settings.ConditionalAppearance.UserSettingID = UserSettingID Then
		Return Settings.ConditionalAppearance;
	EndIf;
	
	If SettingType <> Type("DataCompositionTable") AND SettingType <> Type("DataCompositionChart") Then
		If Settings.Filter.UserSettingID = UserSettingID Then
			Return Settings.Filter;
		ElsIf Settings.Order.UserSettingID = UserSettingID Then
			Return Settings.Order;
		EndIf;
	EndIf;
	
	If SettingType = Type("DataCompositionSettings") Then
		SearchResult = FindSettingItem(Settings.DataParameters, UserSettingID);
		If SearchResult <> Undefined Then
			Return SearchResult;
		EndIf;
	EndIf;
	
	If SettingType <> Type("DataCompositionTable") AND SettingType <> Type("DataCompositionChart") Then
		SearchResult = FindSettingItem(Settings.Filter, UserSettingID);
		If SearchResult <> Undefined Then
			Return SearchResult;
		EndIf;
	EndIf;
	
	SearchResult = FindSettingItem(Settings.ConditionalAppearance, UserSettingID);
	If SearchResult <> Undefined Then
		Return SearchResult;
	EndIf;
	
	If SettingType = Type("DataCompositionTable") Then
		
		SearchResult = GetObjectByUserIdentifier(Settings.Rows, UserSettingID, Hierarchy);
		If SearchResult <> Undefined Then
			Return SearchResult;
		EndIf;
		
		SearchResult = GetObjectByUserIdentifier(Settings.Columns, UserSettingID, Hierarchy);
		If SearchResult <> Undefined Then
			Return SearchResult;
		EndIf;
		
	ElsIf SettingType = Type("DataCompositionChart") Then
		
		SearchResult = GetObjectByUserIdentifier(Settings.Points, UserSettingID, Hierarchy);
		If SearchResult <> Undefined Then
			Return SearchResult;
		EndIf;
		
		SearchResult = GetObjectByUserIdentifier(Settings.Series, UserSettingID, Hierarchy);
		If SearchResult <> Undefined Then
			Return SearchResult;
		EndIf;
		
	Else
		
		SearchResult = GetObjectByUserIdentifier(Settings.Structure, UserSettingID, Hierarchy);
		If SearchResult <> Undefined Then
			Return SearchResult;
		EndIf;
		
	EndIf;
	
	If Hierarchy <> Undefined Then
		Hierarchy.Delete(Hierarchy.UBound());
	EndIf;
	
	Return Undefined;
	
EndFunction

Function FindSettingItem(SettingItem, UserSettingID)
	// Search item with the specified UserSettingID (USI) property.
	
	GroupArray = New Array;
	GroupArray.Add(SettingItem.Items);
	
	While GroupArray.Count() > 0 Do
		
		ItemCollection = GroupArray.Get(0);
		GroupArray.Delete(0);
		
		For Each SubordinateItem IN ItemCollection Do
			If TypeOf(SubordinateItem) = Type("DataCompositionSelectedFieldGroup") Then
				// Does not contain IIT; The collection of inserted items does not contain IIT.
			ElsIf TypeOf(SubordinateItem) = Type("DataCompositionParameterValue") Then
				// Does not contain IIT; The collection of inserted items may contain IIT.
				GroupArray.Add(SubordinateItem.NestedParameterValues);
			ElsIf SubordinateItem.UserSettingID = UserSettingID Then
				// Required item is found.
				Return SubordinateItem;
			Else
				// Contains IIT; The collection of inserted items may contain IIT.
				If TypeOf(SubordinateItem) = Type("DataCompositionFilterItemGroup") Then
					GroupArray.Add(SubordinateItem.Items);
				ElsIf TypeOf(SubordinateItem) = Type("DataCompositionSettingsParameterValue") Then
					GroupArray.Add(SubordinateItem.NestedParameterValues);
				EndIf;
			EndIf;
		EndDo;
		
	EndDo;
	
	Return Undefined;
EndFunction

// Finds a custom setting by its identifier.
//
// Parameters:
//   DCUserSettings - DataCompositionUserSettings - Collection of custom settings.
//   ID - String -
//
Function FindCustomSetting(DCUserSettings, ID) Export
	For Each UserSetting IN DCUserSettings.Items Do
		If UserSetting.UserSettingID = ID Then
			Return UserSetting;
		EndIf;
	EndDo;
	
	Return Undefined;
EndFunction

// Gets the settings linker output parameter or DLS setting
//
// Parameters:
// 	SettingsComposerGroup - settings linker or
// 	setting/grouping DLS ParameterName - parameter name DLS
//
Function GetInputParameter(Setting, ParameterName) Export
	
	ParameterArray   = StringFunctionsClientServer.DecomposeStringIntoSubstringsArray(ParameterName, ".");
	NestingLevel = ParameterArray.Count();
	
	If NestingLevel > 1 Then
		ParameterName = ParameterArray[0];		
	EndIf;
	
	If TypeOf(Setting) = Type("DataCompositionSettingsComposer") Then
		ParameterValue = Setting.Settings.OutputParameters.FindParameterValue(New DataCompositionParameter(ParameterName));
	Else
		ParameterValue = Setting.OutputParameters.FindParameterValue(New DataCompositionParameter(ParameterName));
	EndIf;
	
	If NestingLevel > 1 Then
		For IndexOf = 1 To NestingLevel - 1 Do
			ParameterName = ParameterName + "." + ParameterArray[IndexOf];
			ParameterValue = ParameterValue.NestedParameterValues.Find(ParameterName); 
		EndDo;
	EndIf;
	
	Return ParameterValue;  
	
EndFunction

// Sets the settings linker output parameter or DLS setting
//
// Parameters:
// 	SettingsComposerGroup - settings linker or
// 	setting/grouping DLS ParameterName - parameter name
// 	DLS Value - value of the
// 	output parameter DLS Usage - Shows that the parameter is used. Always equals to True by default.
//
Function SetOutputParameter(Setting, ParameterName, Value, Use = True) Export
	
	ParameterValue = GetInputParameter(Setting, ParameterName);
	
	If ParameterValue <> Undefined Then
		ParameterValue.Use = Use;
		ParameterValue.Value      = Value;
	EndIf;
	
	Return ParameterValue;
	
EndFunction

Function IndicatorsList(ReportSettings)
	
	Result = New ValueList;
	For Each AvailableField In ReportSettings.SelectionAvailableFields.Items Do
		If Not AvailableField.Resource Then
			Continue;
		EndIf;
		Result.Add(String(AvailableField.Field)); 
	EndDo;
	MarkSelectedFieldsRecursively(ReportSettings.Selection.Items, Result);
	Return Result;
	
EndFunction

Procedure DeleteComparisonFields(NamesOfFields, SettingsChoice, DataCompositionSchema)
	
	FieldsNamesArray = StringFunctionsClientServer.DecomposeStringIntoSubstringArray(NamesOfFields);
	For Each FieldName In FieldsNamesArray Do
		For Each SelectedField In SettingsChoice Do
			If Not TypeOf(SelectedField)=Type("DataCompositionSelectedField") Then
				Continue;
			EndIf;
			If SelectedField.Field=New DataCompositionField(FieldName) Then
				SettingsChoice.Delete(SelectedField);
			EndIf;
		EndDo;
		Resource = DataCompositionSchema.TotalFields.Find(FieldName);
		If Not Resource=Undefined Then
			DataCompositionSchema.TotalFields.Delete(Resource);
		EndIf;
		FieldToEval = DataCompositionSchema.CalculatedFields.Find(FieldName);
		If Not FieldToEval=Undefined Then
			DataCompositionSchema.CalculatedFields.Delete(FieldToEval);
		EndIf;
	EndDo;
	
EndProcedure

Function ChoiceFieldExists(ReportSettings, Field)
		
	For Each ComboBox In ReportSettings.Selection.Items Do
		If Not TypeOf(ComboBox)=Type("DataCompositionSelectedField") Then
			Continue;
		EndIf; 
		If ComboBox.Field=Field Then
			Return True;
		EndIf; 
	EndDo; 
	Return False;
		
EndFunction

#EndRegion

// Возвращает преобразованную дату, для которой актуальными остается только месяц, остальные части даты сбрасываются 
//
// Parameters:
//    ParameterDate - Date - Дата определения месяца
//
// Returns: 
//    * Дата - Дата содержащая месяц
//
Function MonthYear(ParameterDate) Export
	
	If TypeOf(ParameterDate)<>Type("Date") Then
		Return Undefined;
	EndIf;
	
	Return Date(1900, Month(ParameterDate), 1, 0, 0, 0);		
	
EndFunction

// Возвращает преобразованную дату, для которой актуальными остается только месяц и день, остальные части даты сбрасываются 
//
// Parameters:
//    ParameterDate - Date - Дата определения месяца и дня
//
// Returns: 
//    * Дата - Дата содержащая месяц и день
//
Function MonthOfYearDay(ParameterDate) Export
	
	If TypeOf(ParameterDate)<>Type("Date") Then
		Return Undefined;
	EndIf;
	
	Return Date(1900, Month(ParameterDate), Day(ParameterDate), 0, 0, 0);		
	
EndFunction

// Возвращает номер недели года. Используется в вычисляемых полях отчетов
//
// Parameters:
//    ParameterDate - Date - Дата определения номера недели
//
// Returns: 
//    * Число - Номер недели года
//
Function YearWeekNumber(ParameterDate) Export
	
	If TypeOf(ParameterDate)<>Type("Date") Then
		Return Undefined;
	EndIf;
	
	Return WeekOfYear(ParameterDate);		
	
EndFunction
