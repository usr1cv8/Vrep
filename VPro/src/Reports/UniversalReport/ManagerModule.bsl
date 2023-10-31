///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2020, ООО 1С-Софт
// Все права защищены. Эта программа и сопроводительные материалы предоставляются 
// в соответствии с условиями лицензии Attribution 4.0 International (CC BY 4.0)
// Текст лицензии доступен по ссылке:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region ProgramInterface

#Region ForCallsFromOtherSubsystems

// СтандартныеПодсистемы.ВариантыОтчетов

// See ReportsVariantsOverridable.ConfigureReportsVariants.
//
Procedure ConfigureReportsVariants(Settings, ReportSettings) Export
	
	ReportSettings.DefineFormSettings = True;

	ModuleReportsVariants = CommonUse.CommonModule("ReportsVariants");
	ModuleReportsVariants.SetOutputModeInReportPanels(Settings, ReportSettings, False);
	
	VariantSettings = ModuleReportsVariants.VariantDesc(Settings, ReportSettings, "Main");
	VariantSettings.Description = NStr("en='Universal report on catalogs, documents, registers.';ru='Универсальный отчет по справочникам, документам, регистрам.';vi='Báo cáo đa năng theo danh mục, chứng từ, biểu ghi.'");
	
EndProcedure

// Конец СтандартныеПодсистемы.ВариантыОтчетов

#EndRegion

#EndRegion

#Region InternalProceduresAndFunctions

Function ImportSettingsOnChangeParameters() Export 
	Parameters = New Array;
	Parameters.Add(New DataCompositionParameter("MetadataObjectType"));
	Parameters.Add(New DataCompositionParameter("MetadataObjectName"));
	Parameters.Add(New DataCompositionParameter("TableName"));
	
	Return Parameters;
EndFunction

// Возвращает значения специализированных параметров универсального отчета.
//
// Parameters:
//  Settings - DataCompositionSettings - 
//  UserSettings - DataCompositionUserSettings - 
//  AvailableValues - Structure - 
//
// Returns:
//  Structure - WHERE:
//    * Period - StandardPeriod - 
//    * MetadataObjectType - String - 
//    * MetadataObjectName - String - 
//    * TableName - String - 
//    * DataSource - CatalogRef.MetadataObjectIDs - 
// 
Function FixedParameters(Settings, UserSettings, AvailableValues) Export 
	FixedParameters = New Structure("Period, DataSource, MetadataObjectType, MetadataObjectName, TableName");
	AvailableValues = New Structure("MetadataObjectType, MetadataObjectName, TableName");
	
	SetFixedParameter("Period", FixedParameters, Settings, UserSettings);
	SetFixedParameter("DataSource", FixedParameters, Settings, UserSettings);
	
	AvailableValues.MetadataObjectType = AvailableMetadataObjectsTypes();
	SetFixedParameter(
		"MetadataObjectType",
		FixedParameters,
		Settings, UserSettings,
		AvailableValues.MetadataObjectType);
	
	AvailableValues.MetadataObjectName = AvailableMetadataObjects(
		FixedParameters.MetadataObjectType);
	SetFixedParameter(
		"MetadataObjectName",
		FixedParameters,
		Settings,
		UserSettings,
		AvailableValues.MetadataObjectName);
	
	AvailableValues.TableName = AvailableTables(
		FixedParameters.MetadataObjectType, FixedParameters.MetadataObjectName);
	SetFixedParameter(
		"TableName", FixedParameters, Settings, UserSettings, AvailableValues.TableName);
	
	FixedParameters.DataSource = DataSource(
		FixedParameters.MetadataObjectType, FixedParameters.MetadataObjectName);
	
	IDs = StrSplit("MetadataObjectType, MetadataObjectName, TableName", ", ", False);
	DataParameters = Settings.DataParameters.Items;
	For Each ID In IDs Do 
		SettingItem = DataParameters.Find(ID);
		If SettingItem = Undefined
			Or SettingItem.Value = FixedParameters[ID] Then 
			Continue;
		EndIf;
		
		Settings.AdditionalProperties.Insert("ReportInitialized", False);
		Break;
	EndDo;
	
	Return FixedParameters;
EndFunction

Procedure SetFixedParameter(ID, Parameters, Settings, UserSettings, AvailableValues = Undefined)
	FixedParameter = Parameters[ID];
	
	If AvailableValues = Undefined Then 
		AvailableValues = New ValueList;
	EndIf;
	
	SettingItem = Settings.DataParameters.Items.Find(ID);
	If SettingItem = Undefined Then 
		If AvailableValues.Count() > 0 Then 
			Parameters[ID] = AvailableValues[0].Value;
		EndIf;
		Return;
	EndIf;
	
	UserSettingsItem = Undefined;
	If TypeOf(UserSettings) = Type("DataCompositionUserSettings")
		And (Settings.AdditionalProperties.Property("ReportInitialized")
		Or UserSettings.AdditionalProperties.Property("ReportInitialized")) Then 
		
		UserSettingsItem = UserSettings.Items.Find(
			SettingItem.UserSettingID);
	EndIf;
	
	If UserSettingsItem <> Undefined
		And AvailableValues.FindByValue(UserSettingsItem.Value) <> Undefined Then 
		FixedParameter = UserSettingsItem.Value;
	ElsIf AvailableValues.FindByValue(SettingItem.Value) <> Undefined Then 
		FixedParameter = SettingItem.Value;
	ElsIf ID = "MetadataObjectName"
		And ValueIsFilled(Parameters.DataSource) Then 
		FixedParameter = CommonUse.MetadataObjectByID(Parameters.DataSource).Name;
	ElsIf AvailableValues.Count() > 0 Then 
		FixedParameter = AvailableValues[0].Value;
	ElsIf UserSettingsItem <> Undefined
		And ValueIsFilled(UserSettingsItem.Value) Then 
		FixedParameter = UserSettingsItem.Value;
	ElsIf ValueIsFilled(SettingItem.Value) Then 
		FixedParameter = SettingItem.Value;
	EndIf;
	
	If ID = "MetadataObjectType"
		And ValueIsFilled(Parameters.DataSource)
		And Parameters.DataSource.GetObject() <> Undefined Then 
		
		MetadataObject = CommonUse.MetadataObjectByID(Parameters.DataSource);
		MetadataObjectType = CommonUse.BaseTypeNameByMetadataObject(MetadataObject);
		If MetadataObjectType <> FixedParameter Then 
			Parameters.DataSource = Undefined;
		EndIf;
	EndIf;
	
	Parameters[ID] = FixedParameter;
EndProcedure

// Устанавливает значения специализированных параметров универсального отчета.
//
// Parameters:
//  Report - 
//  FixedParameters - See FixedParameters
//  Settings - DataCompositionSettings - 
//  UserSettings - DataCompositionUserSettings - 
//
Procedure SetFixedParameters(Report, FixedParameters, Settings, UserSettings) Export 
	DataParameters = Settings.DataParameters;
	
	AvailableParameters = DataParameters.AvailableParameters;
	If AvailableParameters = Undefined Then 
		Return;
	EndIf;
	
	For Each Parameter In FixedParameters Do 
		If AvailableParameters.Items.Find(Parameter.Key) = Undefined Then 
			Continue;
		EndIf;
		
		SettingItem = DataParameters.Items.Find(Parameter.Key);
		If SettingItem = Undefined Then 
			SettingItem = DataParameters.Items.Add();
			SettingItem.Parameter = New DataCompositionParameter(Parameter.Key);
			SettingItem.Value = Parameter.Value;
			SettingItem.Use = True;
		Else
			DataParameters.SetParameterValue(Parameter.Key, Parameter.Value);
		EndIf;
		
		UserSettingsItem = Undefined;
		If UserSettings <> Undefined Then 
			UserSettingsItem = UserSettings.Items.Find(
				SettingItem.UserSettingID);
		EndIf;
		
		If UserSettingsItem <> Undefined Then 
			FillPropertyValues(UserSettingsItem, SettingItem, "Use, Value");
		EndIf;
	EndDo;
	
	If UserSettings <> Undefined Then 
		UserSettings.AdditionalProperties.Insert("ReportInitialized", True);
	EndIf;
EndProcedure

Function TextOfQueryByMetadata(ReportParameters)
	SourceMetadata = Metadata[ReportParameters.MetadataObjectType][ReportParameters.MetadataObjectName];
	
	SourceName = SourceMetadata.FullName();
	If ValueIsFilled(ReportParameters.TableName) Then 
		SourceName = SourceName + "." + ReportParameters.TableName;
	EndIf;
	
	// УНФ
	SourceFilter = SmallBusinessReports.FilterUniversalReportSource(SourceMetadata, ReportParameters);
	// Конец УНФ
	
	QueryText = "
	|SELECT ALLOWED
	|	*
	|FROM
	|	[SourceName] [SourceFilter]
	|";
	QueryTextExpressions = New Structure;
	QueryTextExpressions.Insert("SourceName", SourceName);
	QueryTextExpressions.Insert("SourceFilter", SourceFilter);
	
	Return StringFunctionsClientServer.SubstituteParametersInStringByName(QueryText, QueryTextExpressions);
EndFunction

Function AvailableMetadataObjectsTypes()
	AvailableValues = New ValueList;
	
	If HasMetadataTypeObjects(Metadata.Catalogs) Then
		AvailableValues.Add("Catalogs", NStr("en='Catalog';ru='Справочник';vi='Danh mục'"), , PictureLib.Catalog);
	EndIf;
	
	If HasMetadataTypeObjects(Metadata.Documents) Then
		AvailableValues.Add("Documents", NStr("en='Document';ru='Документ';vi='Chứng từ'"), , PictureLib.Document);
	EndIf;
	
	If HasMetadataTypeObjects(Metadata.InformationRegisters) Then
		AvailableValues.Add("InformationRegisters", NStr("en='Information register';ru='Регистр сведений';vi='Biểu ghi thông tin'"), , PictureLib.InformationRegister);
	EndIf;
	
	If HasMetadataTypeObjects(Metadata.AccumulationRegisters) Then
		AvailableValues.Add("AccumulationRegisters", NStr("ru = 'Регистр накопления';
																|en = 'Accumulation registers;"), , PictureLib.AccumulationRegister);
	EndIf;
	
	If HasMetadataTypeObjects(Metadata.AccountingRegisters) Then
		AvailableValues.Add("AccountingRegisters", NStr("en='Accounting registers';ru='Регистр бухгалтерии';vi='Biểu ghi kế toán'"), , PictureLib.AccountingRegister);
	EndIf;
	
	If HasMetadataTypeObjects(Metadata.CalculationRegisters) Then
		AvailableValues.Add("CalculationRegisters", NStr("en='Calculation registers';ru='Регистр расчета';vi='Biểu ghi tính toán'"), , PictureLib.CalculationRegister);
	EndIf;
	
	If HasMetadataTypeObjects(Metadata.ChartsOfCalculationTypes) Then
		AvailableValues.Add("ChartsOfCalculationTypes", NStr("en='Charts of calculation types';ru='Планы видов расчета';vi='Hệ thống dạng tính toán'"), , PictureLib.ChartOfCalculationTypes);
	EndIf;
	
	If HasMetadataTypeObjects(Metadata.Tasks) Then
		AvailableValues.Add("Tasks", NStr("en='Tasks';ru='Задачи';vi='Nhiệm vụ'"), , PictureLib.Task);
	EndIf;
	
	If HasMetadataTypeObjects(Metadata.BusinessProcesses) Then
		AvailableValues.Add("BusinessProcesses", NStr("en='Business processes';ru='Бизнес-процессы';vi='Quy trình nghiệp vụ'"), , PictureLib.BusinessProcess);
	EndIf;
	
	Return AvailableValues;
EndFunction

Function AvailableMetadataObjects(MetadataObjectType)
	AvailableValues = New ValueList;
	
	If Not ValueIsFilled(MetadataObjectType) Then
		Return AvailableValues;
	EndIf;
	
	ValuesToDelete = New ValueList;
	For Each Object In Metadata[MetadataObjectType] Do
		If Not CommonUse.MetadataObjectAvailableByFunctionalOptions(Object)
			Or Not AccessRight("Read", Object) Then
			Continue;
		EndIf;
		
		If StrStartsWith(Upper(Object.Name), "Delete") Then 
			ValuesToDelete.Add(Object.Name, Object.Synonym);
		Else
			AvailableValues.Add(Object.Name, Object.Synonym);
		EndIf;
	EndDo;
	AvailableValues.SortByPresentation(SortDirection.Asc);
	ValuesToDelete.SortByPresentation(SortDirection.Asc);
	
	For Each ObjectToDelete In ValuesToDelete Do
		AvailableValues.Add(ObjectToDelete.Value, ObjectToDelete.Presentation);
	EndDo;
	
	Return AvailableValues;
EndFunction

Function AvailableTables(MetadataObjectType, MetadataObjectName)
	AvailableValues = New ValueList;
	
	If Not ValueIsFilled(MetadataObjectType)
		Or Not ValueIsFilled(MetadataObjectName) Then 
		Return AvailableValues;
	EndIf;
	
	MetadataObject = Metadata[MetadataObjectType][MetadataObjectName];
	
	AvailableValues.Add("", NStr("en='Main data';ru='Основные данные';vi='Dữ liệu cơ bản'"));
	
	If MetadataObjectType = "Catalogs" 
		Or MetadataObjectType = "Documents" 
		Or MetadataObjectType = "BusinessProcesses"
		Or MetadataObjectType = "Tasks" Then
		
		For Each TabularSection In MetadataObject.TabularSections Do
			AvailableValues.Add(TabularSection.Name, TabularSection.Synonym);
		EndDo;
	ElsIf MetadataObjectType = "InformationRegisters" Then 
		If MetadataObject.InformationRegisterPeriodicity
			<> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then
			
			AvailableValues.Add("SliceLast", NStr("en='Slice last';ru='Срез последних';vi='Mặt cắt cuối cùng'"));
			AvailableValues.Add("SliceFirst", NStr("en='Slice first';ru='Срез первых';vi='Mặt cắt đầu tiên'"));
		EndIf;
	ElsIf MetadataObjectType = "AccumulationRegisters" Then
		If MetadataObject.RegisterType = Metadata.ObjectProperties.AccumulationRegisterType.Balance Then
			AvailableValues.Add("BalanceAndTurnovers", NStr("en='Balance and turnovers';ru='Остатки и обороты';vi='Số dư và phát sinh'"));
			AvailableValues.Add("Balances", NStr("en='Balances';ru='Остатки';vi='Số dư'"));
			AvailableValues.Add("Turnovers", NStr("en='Turnovers';ru='Обороты';vi='Phát sinh'"));
		Else
			AvailableValues.Add("Turnovers", NStr("en='Turnovers';ru='Обороты';vi='Phát sinh'"));
		EndIf;
	ElsIf MetadataObjectType = "AccountingRegisters" Then
		AvailableValues.Add("BalanceAndTurnovers", NStr("en='Balance and turnovers';ru='Остатки и обороты';vi='Số dư và phát sinh'"));
		AvailableValues.Add("Balances", NStr("en='Balances';ru='Остатки';vi='Số dư'"));
		AvailableValues.Add("Turnovers", NStr("en='Turnovers';ru='Обороты';vi='Phát sinh'"));
		AvailableValues.Add("DrCrTurnovers", NStr("en='Dr/Cr turnovers';ru='Обороты Дт/Кт';vi='Phát sinh Nợ/Có'"));
		AvailableValues.Add("RecordsWithExtDimensions", NStr("en='Records with extdimensions';ru='Движения с субконто';vi='Bản ghi kết chuyển với khoản mục'"));
	ElsIf MetadataObjectType = "CalculationRegisters" Then 
		If MetadataObject.ActionPeriod Then
			AvailableValues.Add("ScheduleData", NStr("en='Schedule data';ru='Данные графика';vi='Dữ liệu đồ thị'"));
			AvailableValues.Add("ActualActionPeriod", NStr("en='Actual action period';ru='Фактический период действия';vi='Kỳ hiệu lực thực tế'"));
		EndIf;
	ElsIf MetadataObjectType = "ChartsOfCalculationTypes" Then
		If MetadataObject.DependenceOnCalculationTypes
			<> Metadata.ObjectProperties.ChartOfCalculationTypesBaseUse.DontUse Then 
			
			AvailableValues.Add("BaseCalculationTypes", NStr("en='Base calculation types';ru='Базовые виды расчета';vi='Các dạng tính toán cơ bản'"));
		EndIf;
		
		AvailableValues.Add("LeadingCalculationTypes", NStr("en='Leading calculation types';ru='Ведущие виды расчета';vi='Các dạng tính toán đang thực hiện'"));
		
		If MetadataObject.ActionPeriodUse Then 
			AvailableValues.Add("DisplacingCalculationTypes", NStr("en='Displacing calculation types';ru='Вытесняющие виды расчета';vi='Các dạng tính toán chuyển vị'"));
		EndIf;
	EndIf;
	
	Return AvailableValues;
EndFunction

Function HasMetadataTypeObjects(MetadataType)
	
	For Each Object In MetadataType Do
		If CommonUse.MetadataObjectAvailableByFunctionalOptions(Object)
			And AccessRight("Read", Object) Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

Procedure AddTotals(ReportParameters, DataCompositionSchema)
	
	If ReportParameters.MetadataObjectType = "AccumulationRegisters" 
		Or ReportParameters.MetadataObjectType = "InformationRegisters" 
		Or ReportParameters.MetadataObjectType = "AccountingRegisters" 
		Or ReportParameters.MetadataObjectType = "CalculationRegisters" Then
		
		AddRegisterTotals(ReportParameters, DataCompositionSchema);
		
	ElsIf ReportParameters.MetadataObjectType = "Documents" 
		Or ReportParameters.MetadataObjectType = "Catalogs" 
		Or ReportParameters.MetadataObjectType = "BusinessProcesses"
		Or ReportParameters.MetadataObjectType = "Tasks" Then
		
		AddObjectTotals(ReportParameters, DataCompositionSchema);
	EndIf;
	
EndProcedure

Procedure AddObjectTotals(Val ReportParameters, Val DataCompositionSchema)
	
	MetadataObject = Metadata[ReportParameters.MetadataObjectType][ReportParameters.MetadataObjectName];
	ObjectPresentation = MetadataObject.Presentation();
	
	ReferenceDetails = MetadataObject.StandardAttributes["Ref"];
	If ValueIsFilled(ReferenceDetails.Synonym) Then 
		ObjectPresentation = ReferenceDetails.Synonym;
	ElsIf ValueIsFilled(MetadataObject.ObjectPresentation) Then 
		ObjectPresentation = MetadataObject.ObjectPresentation;
	EndIf;
	
	AddDataSetField(DataCompositionSchema.DataSets[0], ReferenceDetails.Name, ObjectPresentation);
	
	If ReportParameters.TableName <> "" Then
		TabularSection = MetadataObject.TabularSections.Find(ReportParameters.TableName);
		If TabularSection <> Undefined Then 
			MetadataObject = TabularSection;
		EndIf;
	EndIf;
	
	// Добавляем итоги по числовым реквизитам
	For Each Attribute In MetadataObject.Attributes Do
		If Not CommonUse.MetadataObjectAvailableByFunctionalOptions(Attribute) Then 
			Continue;
		EndIf;
		
		AddDataSetField(DataCompositionSchema.DataSets[0], Attribute.Name, Attribute.Synonym);
		If Attribute.Type.ContainsType(Type("Number")) Then
			AddTotalField(DataCompositionSchema, Attribute.Name);
		EndIf;
	EndDo;

EndProcedure

Procedure AddRegisterTotals(Val ReportParameters, Val DataCompositionSchema)
	
	MetadataObject = Metadata[ReportParameters.MetadataObjectType][ReportParameters.MetadataObjectName]; 
	
	// Добавляем измерения
	For Each Dimension In MetadataObject.Dimensions Do
		If CommonUse.MetadataObjectAvailableByFunctionalOptions(Dimension) Then 
			AddDataSetField(DataCompositionSchema.DataSets[0], Dimension.Name, Dimension.Synonym);
		EndIf;
	EndDo;
	
	// Добавляем реквизиты
	If IsBlankString(ReportParameters.TableName) Then
		For Each Attribute In MetadataObject.Attributes Do
			If CommonUse.MetadataObjectAvailableByFunctionalOptions(Attribute) Then 
				AddDataSetField(DataCompositionSchema.DataSets[0], Attribute.Name, Attribute.Synonym);
			EndIf;
		EndDo;
	EndIf;
	
	// Добавляем поля периода
	If ReportParameters.TableName = "BalanceAndTurnovers" 
		Or ReportParameters.TableName = "Turnovers" 
		Or ReportParameters.MetadataObjectType = "AccountingRegisters" And ReportParameters.TableName = "" Then
		AddPeriodFieldsInDataSet(DataCompositionSchema.DataSets[0]);
	EndIf;
	
	// Для регистров бухгалтерии важна настройка ролей.
	If ReportParameters.MetadataObjectType = "AccountingRegisters" Then
		
		AccountField = AddDataSetField(DataCompositionSchema.DataSets[0], "Account", NStr("en='Счет';ru='Счет';vi='Tài khoản'"));
		AccountField.Role.AccountTypeExpression = "Account.Kind";
		AccountField.Role.Account = True;
		
		CountExtDimension = 0;
		If MetadataObject.ChartOfAccounts <> Undefined Then 
			CountExtDimension = MetadataObject.ChartOfAccounts.MaxExtDimensionCount;
		EndIf;
		
		For SubkontoNumber = 1 To CountExtDimension Do
			ExtDimensionField = AddDataSetField(DataCompositionSchema.DataSets[0], "ExtDimensions" + SubkontoNumber, NStr("en='Субконто';ru='Субконто';vi='Khoản mục'") + " " + SubkontoNumber);
			ExtDimensionField.Role.Dimension = True;
			ExtDimensionField.Role.IgnoreNULLValues = True;
		EndDo;
		
	EndIf;
	
	// Добавляем ресурсы
	For Each Resource In MetadataObject.Resources Do
		If Not CommonUse.MetadataObjectAvailableByFunctionalOptions(Resource) Then 
			Continue;
		EndIf;
		
		If ReportParameters.TableName = "Turnovers" Then
			
			AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "Turnover", Resource.Synonym);
			AddTotalField(DataCompositionSchema, Resource.Name + "Turnover");
			
			If ReportParameters.MetadataObjectType = "AccountingRegisters" Then
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "TurnoverDr", Resource.Synonym + " " + NStr("en='оборот Дт';ru='оборот Дт';vi='phát sinh Nợ'"), Resource.Name + "TurnoverDr");
				AddTotalField(DataCompositionSchema, Resource.Name + "TurnoverDr");
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "TurnoverCr", Resource.Synonym + " " + NStr("en='оборот Кт';ru='оборот Кт';vi='phát sinh Có'"), Resource.Name + "TurnoverCr");
				AddTotalField(DataCompositionSchema, Resource.Name + "TurnoverCr");
				
				If Not Resource.Balance Then
					AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "BalancedTurnover", Resource.Synonym + " " + NStr("en='кор. оборот';ru='кор. оборот';vi='Phát sinh đối ứng'"), Resource.Name + "BalancedTurnover");
					AddTotalField(DataCompositionSchema, Resource.Name + "BalancedTurnover");
					AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "BalancedTurnoverDr", Resource.Synonym + " " + NStr("en='кор. оборот Дт';ru='кор. оборот Дт';vi='Phát sinh đối ứng Nợ'"), Resource.Name + "BalancedTurnoverDr");
					AddTotalField(DataCompositionSchema, Resource.Name + "BalancedTurnoverDr");
					AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "BalancedTurnoverCr", Resource.Synonym + " " + NStr("en='кор. оборот Кт';ru='кор. оборот Кт';vi='Phát sinh đối ứng Có'"), Resource.Name + "BalancedTurnoverCr");
					AddTotalField(DataCompositionSchema, Resource.Name + "BalancedTurnoverCr");
				EndIf;
			EndIf;
			
		ElsIf ReportParameters.TableName = "DrCrTurnovers" Then
			
			If Resource.Balance Then
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "Turnover", Resource.Synonym);
				AddTotalField(DataCompositionSchema, Resource.Name + "Turnover");
			Else
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "TurnoverDr", Resource.Synonym + " " + NStr("en='оборот Дт';ru='оборот Дт';vi='phát sinh Nợ'"), Resource.Name + "TurnoverDr");
				AddTotalField(DataCompositionSchema, Resource.Name + "TurnoverDr");
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "TurnoverCr", Resource.Synonym + " " + NStr("en='оборот Кт';ru='оборот Кт';vi='phát sinh Có'"), Resource.Name + "TurnoverCr");
				AddTotalField(DataCompositionSchema, Resource.Name + "TurnoverCr");
			EndIf;
			
		ElsIf ReportParameters.TableName = "RecordsWithExtDimensions" Then
			
			If Resource.Balance Then
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name, Resource.Synonym);
				AddTotalField(DataCompositionSchema, Resource.Name);
			Else
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "Dr", Resource.Synonym + " " + NStr("en='Дт';ru='Дт';vi='Ngày'"), Resource.Name + "Dr");
				AddTotalField(DataCompositionSchema, Resource.Name + "Dr");
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "Cr", Resource.Synonym + " " + NStr("en='Кт';ru='Кт';vi='Có'"), Resource.Name + "Cr");
				AddTotalField(DataCompositionSchema, Resource.Name + "Cr");
			EndIf;
			
		ElsIf ReportParameters.TableName = "BalanceAndTurnovers" Then
			
			SetField = AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "OpeningBalance", Resource.Synonym + " " + NStr("en='нач. остаток';ru='нач. остаток';vi='dư đầu'"), Resource.Name + "OpeningBalance");
			AddTotalField(DataCompositionSchema, Resource.Name + "OpeningBalance");
			
			If ReportParameters.MetadataObjectType = "AccountingRegisters" Then
				
				SetField.Role.Balance = True;
				SetField.Role.BalanceType = DataCompositionBalanceType.OpeningBalance;
				SetField.Role.BalanceGroup = "bal" + Resource.Name;
				SetField.Role.AccountField = "Account";
				
				SetField = AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "OpeningBalanceDr", Resource.Synonym + " " + NStr("en='нач. остаток Дт';ru='нач. остаток Дт';vi='Dư đầu Nợ'"), Resource.Name + "OpeningBalanceDr");
				SetField.Role.Balance = True;
				SetField.Role.BalanceType = DataCompositionBalanceType.OpeningBalance;
				SetField.Role.AccountingBalanceType = DataCompositionAccountingBalanceType.Debit;
				SetField.Role.AccountField = "Account";
				SetField.Role.BalanceGroup = "bal" + Resource.Name;
				AddTotalField(DataCompositionSchema, Resource.Name + "OpeningBalanceDr");
				
				SetField = AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "OpeningBalanceCr", Resource.Synonym + " " + NStr("en='нач. остаток Кт';ru='нач. остаток Кт';vi='Dư đầu Có'"), Resource.Name + "OpeningBalanceCr");
				SetField.Role.Balance = True;
				SetField.Role.BalanceType = DataCompositionBalanceType.OpeningBalance;
				SetField.Role.AccountingBalanceType = DataCompositionAccountingBalanceType.Credit;
				SetField.Role.AccountField = "Account";
				SetField.Role.BalanceGroup = "bal" + Resource.Name;
				AddTotalField(DataCompositionSchema, Resource.Name + "OpeningBalanceCr");
				
				SetField = AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "OpeningSplittedBalanceDr", Resource.Synonym + " " + NStr("en='нач. развернутый остаток Дт';ru='нач. развернутый остаток Дт';vi='Dư đầu chi tiết Nợ'"), Resource.Name + "OpeningSplittedBalanceDr");
				SetField.Role.Balance = True;
				SetField.Role.BalanceType = DataCompositionBalanceType.OpeningBalance;
				SetField.Role.AccountingBalanceType = DataCompositionAccountingBalanceType.None;
				SetField.Role.AccountField = "Account";
				SetField.Role.BalanceGroup = "DetailedBalance" + Resource.Name;
				AddTotalField(DataCompositionSchema, Resource.Name + "OpeningSplittedBalanceDr");
				
				SetField =AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "OpeningSplittedBalanceCr", Resource.Synonym + " " + NStr("en='нач. развернутый остаток Кт';ru='нач. развернутый остаток Кт';vi='Dư đầu chi tiết Có'"), Resource.Name + "OpeningSplittedBalanceCr");
				SetField.Role.Balance = True;
				SetField.Role.BalanceType = DataCompositionBalanceType.OpeningBalance;
				SetField.Role.AccountingBalanceType = DataCompositionAccountingBalanceType.None;
				SetField.Role.AccountField = "Account";
				SetField.Role.BalanceGroup = "DetailedBalance" + Resource.Name;
				AddTotalField(DataCompositionSchema, Resource.Name + "OpeningSplittedBalanceCr");
			EndIf;
			
			AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "Turnover", Resource.Synonym + " " + NStr("en='оборот';ru='оборот';vi='phát sinh'"), Resource.Name + "Turnover");
			AddTotalField(DataCompositionSchema, Resource.Name + "Turnover");
			
			If ReportParameters.MetadataObjectType = "AccumulationRegisters" Then
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "Receipt", Resource.Synonym + " " + NStr("en='приход';ru='приход';vi='nhập'"), Resource.Name + "Receipt");
				AddTotalField(DataCompositionSchema, Resource.Name + "Receipt");
				
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "Expense", Resource.Synonym + " " + NStr("en='расход';ru='расход';vi='xuất'"), Resource.Name + "Expense");
				AddTotalField(DataCompositionSchema, Resource.Name + "Expense");
			ElsIf ReportParameters.MetadataObjectType = "AccountingRegisters" Then
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "TurnoverDr", Resource.Synonym + " " + NStr("en='оборот Дт';ru='оборот Дт';vi='phát sinh Nợ'"), Resource.Name + "TurnoverDr");
				AddTotalField(DataCompositionSchema, Resource.Name + "TurnoverDr");
				
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "TurnoverCr", Resource.Synonym + " " + NStr("en='оборот Кт';ru='оборот Кт';vi='phát sinh Có'"), Resource.Name + "TurnoverCr");
				AddTotalField(DataCompositionSchema, Resource.Name + "TurnoverCr");
			EndIf;
			
			SetField = AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "ClosingBalance", Resource.Synonym + " " + NStr("en='кон. остаток';ru='кон. остаток';vi='Dư cuối'"), Resource.Name + "ClosingBalance");
			AddTotalField(DataCompositionSchema, Resource.Name + "ClosingBalance");
			
			If ReportParameters.MetadataObjectType = "AccountingRegisters" Then
				
				SetField.Role.Balance = True;
				SetField.Role.BalanceType = DataCompositionBalanceType.ClosingBalance;
				SetField.Role.AccountField = "Account";
				SetField.Role.BalanceGroup = "bal" + Resource.Name;
				
				SetField = AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "ClosingBalanceDr", Resource.Synonym + " " + NStr("en='кон. остаток Дт';ru='кон. остаток Дт';vi='Dư cuối Nợ'"), Resource.Name + "ClosingBalanceDr");
				SetField.Role.Balance = True;
				SetField.Role.BalanceType = DataCompositionBalanceType.ClosingBalance;
				SetField.Role.AccountingBalanceType = DataCompositionAccountingBalanceType.Debit;
				SetField.Role.AccountField = "Account";
				SetField.Role.BalanceGroup = "bal" + Resource.Name;
				AddTotalField(DataCompositionSchema, Resource.Name + "ClosingBalanceDr");
				
				SetField = AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "ClosingBalanceCr", Resource.Synonym + " " + NStr("en='кон. остаток Кт';ru='кон. остаток Кт';vi='Dư cuối Có'"), Resource.Name + "ClosingBalanceCr");
				SetField.Role.Balance = True;
				SetField.Role.BalanceType = DataCompositionBalanceType.ClosingBalance;
				SetField.Role.AccountingBalanceType = DataCompositionAccountingBalanceType.Credit;
				SetField.Role.AccountField = "Account";
				SetField.Role.BalanceGroup = "bal" + Resource.Name;
				AddTotalField(DataCompositionSchema, Resource.Name + "ClosingBalanceCr");
				
				SetField = AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "ClosingSplittedBalanceDr", Resource.Synonym + " " + NStr("en='кон. развернутый остаток Дт';ru='кон. развернутый остаток Дт';vi='Dư cuối chi tiết Nợ'"), Resource.Name + "ClosingSplittedBalanceDr");
				SetField.Role.Balance = True;
				SetField.Role.BalanceType = DataCompositionBalanceType.ClosingBalance;
				SetField.Role.AccountingBalanceType = DataCompositionAccountingBalanceType.None;
				SetField.Role.AccountField = "Account";
				SetField.Role.BalanceGroup = "DetailedBalance" + Resource.Name;
				AddTotalField(DataCompositionSchema, Resource.Name + "ClosingSplittedBalanceDr");
				
				SetField = AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "ClosingSplittedBalanceCr", Resource.Synonym + " " + NStr("en='кон. развернутый остаток Кт';ru='кон. развернутый остаток Кт';vi='Dư cuối chi tiết Có'"), Resource.Name + "ClosingSplittedBalanceCr");
				SetField.Role.Balance = True;
				SetField.Role.BalanceType = DataCompositionBalanceType.ClosingBalance;
				SetField.Role.AccountingBalanceType = DataCompositionAccountingBalanceType.None;
				SetField.Role.AccountField = "Account";
				SetField.Role.BalanceGroup = "DetailedBalance" + Resource.Name;
				AddTotalField(DataCompositionSchema, Resource.Name + "ClosingSplittedBalanceCr");
			EndIf;
			
		ElsIf ReportParameters.TableName = "Balances" Then
			AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "Balance", Resource.Synonym + " " + NStr("en='остаток';ru='остаток';vi='số dư'"), Resource.Name + "Balance");
			AddTotalField(DataCompositionSchema, Resource.Name + "Balance");
			
			If ReportParameters.MetadataObjectType = "AccountingRegisters" Then
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "BalanceDr", Resource.Synonym + " " + NStr("en='остаток Дт';ru='остаток Дт';vi='số dư Nợ'"), Resource.Name + "BalanceDr");
				AddTotalField(DataCompositionSchema, Resource.Name + "BalanceDr");
				
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "BalanceCr", Resource.Synonym + " " + NStr("en='остаток Кт';ru='остаток Кт';vi='số dư Có'"), Resource.Name + "BalanceCr");
				AddTotalField(DataCompositionSchema, Resource.Name + "BalanceCr");
				
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "SplittedBalanceDr", Resource.Synonym + " " + NStr("en='развернутый остаток Дт';ru='развернутый остаток Дт';vi='số dư chi tiết Nợ'"), Resource.Name + "SplittedBalanceDr");
				AddTotalField(DataCompositionSchema, Resource.Name + "SplittedBalanceDr");
				
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "SplittedBalanceCr", Resource.Synonym + " " + NStr("en='развернутый остаток Кт';ru='развернутый остаток Кт';vi='số dư chi tiết Có'"), Resource.Name + "SplittedBalanceCr");
				AddTotalField(DataCompositionSchema, Resource.Name + "SplittedBalanceCr");
			EndIf;
		ElsIf ReportParameters.MetadataObjectType = "InformationRegisters" Then
			AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name, Resource.Synonym);
			If Resource.Type.ContainsType(Type("Number")) Then
				AddTotalField(DataCompositionSchema, Resource.Name);
			EndIf;
		ElsIf ReportParameters.TableName = "" Then
			If ReportParameters.MetadataObjectType = "AccountingRegisters" Then
				If Resource.Balance Then
					AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name, Resource.Synonym);
					AddTotalField(DataCompositionSchema, Resource.Name);
				Else
					AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "Dr", Resource.Synonym + " " + NStr("en='Дт';ru='Дт';vi='Ngày'"), Resource.Name + "Dr");
					AddTotalField(DataCompositionSchema, Resource.Name + "Dr");
					AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "Cr", Resource.Synonym + " " + NStr("en='Кт';ru='Кт';vi='Có'"), Resource.Name + "Cr");
					AddTotalField(DataCompositionSchema, Resource.Name + "Cr");
				EndIf;
			Else
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name, Resource.Synonym);
				AddTotalField(DataCompositionSchema, Resource.Name);
			EndIf;
		EndIf;
	EndDo;

EndProcedure

// Добавляет период в поля набора данных.
// 
// Parameters:
//  DataSet - DataCompositionSchemaDataSetQuery - 
//
// Returns:
//  ValueList - Description
//
Function AddPeriodFieldsInDataSet(DataSet)
	
	PeriodsList = New ValueList;
	PeriodsList.Add("SecondPeriod",   NStr("en='Период секунда';ru='Период секунда';vi='Kỳ giây'"));
	PeriodsList.Add("MinutePeriod",    NStr("en='Период минута';ru='Период минута';vi='Kỳ phút'"));
	PeriodsList.Add("HourPeriod",       NStr("en='Период час';ru='Период час';vi='Kỳ giờ'"));
	PeriodsList.Add("DayPeriod",      NStr("en='Период день';ru='Период день';vi='Kỳ ngày'"));
	PeriodsList.Add("WeekPeriod",    NStr("en='Период неделя';ru='Период неделя';vi='Kỳ tuần'"));
	PeriodsList.Add("TenDaysPeriod",    NStr("en='Период декада';ru='Период декада';vi='Kỳ 10 ngày'"));
	PeriodsList.Add("MonthPeriod",     NStr("en='Период месяц';ru='Период месяц';vi='Kỳ tháng'"));
	PeriodsList.Add("QuarterPeriod",   NStr("en='Период квартал';ru='Период квартал';vi='Kỳ quý'"));
	PeriodsList.Add("HalfYearPeriod", NStr("en='Период полугодие';ru='Период полугодие';vi='Kỳ nửa năm'"));
	PeriodsList.Add("YearPeriod",       NStr("en='Период год';ru='Период год';vi='Kỳ năm'"));
	
	FolderName = "Periods";
	DataSetFieldsList = New ValueList;
	DataSetFieldsFolder = DataSet.Fields.Add(Type("DataCompositionSchemaDataSetFieldFolder"));
	DataSetFieldsFolder.Title   = FolderName;
	DataSetFieldsFolder.DataPath = FolderName;
	
	PeriodType = DataCompositionPeriodType.Main;
	
	For Each Period In PeriodsList Do
		DataSetField = DataSet.Fields.Add(Type("DataCompositionSchemaDataSetField"));
		DataSetField.Field        = Period.Value;
		DataSetField.Title   = Period.Presentation;
		DataSetField.DataPath = FolderName + "." + Period.Value;
		DataSetField.Role.PeriodType = PeriodType;
		DataSetField.Role.PeriodNumber = PeriodsList.IndexOf(Period);
		DataSetFieldsList.Add(DataSetField);
		PeriodType = DataCompositionPeriodType.Additional;
	EndDo;
	
	Return DataSetFieldsList;
	
EndFunction

// Добавить поле в набор данных.
// 
// Parameters:
//  DataSet - DataCompositionSchemaDataSetQuery - 
//  Field - String - 
//  Title - String - 
//  DataPath - Undefined - 
//              - String - 
//
// Returns:
//  DataCompositionSchemaDataSetField - 
//
Function AddDataSetField(DataSet, Field, Title, DataPath = Undefined)
	
	If DataPath = Undefined Then
		DataPath = Field;
	EndIf;
	
	DataSetField = DataSet.Fields.Add(Type("DataCompositionSchemaDataSetField"));
	DataSetField.Field        = Field;
	DataSetField.Title   = Title;
	DataSetField.DataPath = DataPath;
	Return DataSetField;
	
EndFunction

// Добавить поле итога в схему компоновки данных. Если параметр Выражение не указан, используется Сумма(ПутьКДанным).
Function AddTotalField(DataCompositionSchema, DataPath, Expression = Undefined)
	
	If Expression = Undefined Then
		Expression = "Sum(" + DataPath + ")";
	EndIf;
	
	TotalField = DataCompositionSchema.TotalFields.Add();
	TotalField.DataPath = DataPath;
	TotalField.Expression = Expression;
	Return TotalField;
	
EndFunction

// Добавляет поля итогов.
// 
// Parameters:
//  ReportParameters - See FixedParameters
//  DCSettings - DataCompositionSettings - 
//
Procedure AddIndicators(ReportParameters, DCSettings)
	
	If ReportParameters.TableName = "BalanceAndTurnovers" Then
		SelectedFieldsOpeningBalance = DCSettings.Selection.Items.Add(Type("DataCompositionSelectedFieldGroup"));
		SelectedFieldsOpeningBalance.Title = NStr("en='Нач. остаток';ru='Нач. остаток';vi='Dư đầu'");
		SelectedFieldsOpeningBalance.Placement = DataCompositionFieldPlacement.Horizontally;
		If ReportParameters.MetadataObjectType = "AccumulationRegisters" Then
			SelectedFieldsReceipt = DCSettings.Selection.Items.Add(Type("DataCompositionSelectedFieldGroup"));
			SelectedFieldsReceipt.Title = NStr("en='Приход';ru='Приход';vi='Nhập'");
			SelectedFieldsReceipt.Placement = DataCompositionFieldPlacement.Horizontally;
			SelectedFieldsExpense = DCSettings.Selection.Items.Add(Type("DataCompositionSelectedFieldGroup"));
			SelectedFieldsExpense.Title = NStr("en='Расход';ru='Расход';vi='Xuất'");
			SelectedFieldsExpense.Placement = DataCompositionFieldPlacement.Horizontally;
		ElsIf ReportParameters.MetadataObjectType = "AccountingRegisters" Then
			SelectedFieldsTurnovers = DCSettings.Selection.Items.Add(Type("DataCompositionSelectedFieldGroup"));
			SelectedFieldsTurnovers.Title = NStr("en='Обороты';ru='Обороты';vi='Phát sinh'");
			SelectedFieldsTurnovers.Placement = DataCompositionFieldPlacement.Horizontally;
		EndIf;
		SelectedFieldsClosingBalance = DCSettings.Selection.Items.Add(Type("DataCompositionSelectedFieldGroup"));
		SelectedFieldsClosingBalance.Title = NStr("en='Кон. остаток';ru='Кон. остаток';vi='Dư cuối'");
		SelectedFieldsClosingBalance.Placement = DataCompositionFieldPlacement.Horizontally;
	EndIf;
	
	MetadataObject = Metadata[ReportParameters.MetadataObjectType][ReportParameters.MetadataObjectName]; // ОбъектМетаданныхРегистрСведений, ОбъектМетаданныхРегистрНакопления
	If ReportParameters.MetadataObjectType = "AccumulationRegisters" Then
		For Each Dimension In MetadataObject.Dimensions Do
			If Not CommonUse.MetadataObjectAvailableByFunctionalOptions(Dimension) Then 
				Continue;
			EndIf;
			
			SelectedFields = DCSettings.Selection;
			ReportsServer.AddSelectedField(SelectedFields, Dimension.Name);
		EndDo;
		For Each Resource In MetadataObject.Resources Do
			If Not CommonUse.MetadataObjectAvailableByFunctionalOptions(Resource) Then 
				Continue;
			EndIf;
			
			SelectedFields = DCSettings.Selection;
			If ReportParameters.TableName = "Turnovers" Then
				ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "Turnover", Resource.Synonym);
			ElsIf ReportParameters.TableName = "Balances" Then
				ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "Balance", Resource.Synonym);
			ElsIf ReportParameters.TableName = "BalanceAndTurnovers" Then
				ReportsServer.AddSelectedField(SelectedFieldsOpeningBalance, Resource.Name + "OpeningBalance", Resource.Synonym);
				ReportsServer.AddSelectedField(SelectedFieldsReceipt, Resource.Name + "Receipt", Resource.Synonym);
				ReportsServer.AddSelectedField(SelectedFieldsExpense, Resource.Name + "Expense", Resource.Synonym);
				ReportsServer.AddSelectedField(SelectedFieldsClosingBalance, Resource.Name + "ClosingBalance", Resource.Synonym);
			ElsIf ReportParameters.TableName = "" Then
				ReportsServer.AddSelectedField(SelectedFields, Resource.Name);
			EndIf;
		EndDo;
	ElsIf ReportParameters.MetadataObjectType = "CalculationRegisters" Then
		For Each Dimension In MetadataObject.Dimensions Do
			If Not CommonUse.MetadataObjectAvailableByFunctionalOptions(Dimension) Then 
				Continue;
			EndIf;
			
			SelectedFields = DCSettings.Selection;
			ReportsServer.AddSelectedField(SelectedFields, Dimension.Name);
		EndDo;
		For Each Resource In MetadataObject.Resources Do
			If Not CommonUse.MetadataObjectAvailableByFunctionalOptions(Resource) Then 
				Continue;
			EndIf;
			
			SelectedFields = DCSettings.Selection;
			ReportsServer.AddSelectedField(SelectedFields, Resource.Name);
		EndDo;
	ElsIf ReportParameters.MetadataObjectType = "InformationRegisters" Then
		For Each Dimension In MetadataObject.Dimensions Do
			If Not CommonUse.MetadataObjectAvailableByFunctionalOptions(Dimension) Then 
				Continue;
			EndIf;
			
			SelectedFields = DCSettings.Selection;
			ReportsServer.AddSelectedField(SelectedFields, Dimension.Name);
		EndDo;
		For Each Resource In MetadataObject.Resources Do
			If Not CommonUse.MetadataObjectAvailableByFunctionalOptions(Resource) Then 
				Continue;
			EndIf;
			
			SelectedFields = DCSettings.Selection;
			ReportsServer.AddSelectedField(SelectedFields, Resource.Name);
		EndDo;
	ElsIf ReportParameters.MetadataObjectType = "AccountingRegisters" Then
		For Each Resource In MetadataObject.Resources Do
			If Not CommonUse.MetadataObjectAvailableByFunctionalOptions(Resource) Then 
				Continue;
			EndIf;
			
			SelectedFields = DCSettings.Selection;
			If ReportParameters.TableName = "Turnovers" Then
				ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "TurnoverDr", Resource.Synonym + " " + NStr("en='оборот Дт';ru='оборот Дт';vi='phát sinh Nợ'"));
				ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "TurnoverCr", Resource.Synonym + " " + NStr("en='оборот Кт';ru='оборот Кт';vi='phát sinh Có'"));
			ElsIf ReportParameters.TableName = "DrCrTurnovers" Then
				If Resource.Balance Then
					ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "Turnover", Resource.Synonym + " " + NStr("en='оборот';ru='оборот';vi='phát sinh'"));
				Else
					ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "TurnoverDr", Resource.Synonym + " " + NStr("en='оборот Дт';ru='оборот Дт';vi='phát sinh Nợ'"));
					ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "TurnoverCr", Resource.Synonym + " " + NStr("en='оборот Кт';ru='оборот Кт';vi='phát sinh Có'"));
				EndIf;
			ElsIf ReportParameters.TableName = "Balances" Then
				ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "BalanceDr", Resource.Synonym + " " + NStr("en='ост. Дт';ru='ост. Дт';vi='số dư Nợ'"));
				ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "BalanceCr", Resource.Synonym + " " + NStr("en='ост. Кт';ru='ост. Кт';vi='số dư Có'"));
			ElsIf ReportParameters.TableName = "BalanceAndTurnovers" Then
				ReportsServer.AddSelectedField(SelectedFieldsOpeningBalance, Resource.Name + "OpeningBalanceDr", Resource.Synonym + " " + NStr("en='нач. ост. Дт';ru='нач. ост. Дт';vi='Dư đầu Nợ'"));
				ReportsServer.AddSelectedField(SelectedFieldsOpeningBalance, Resource.Name + "OpeningBalanceCr", Resource.Synonym + " " + NStr("en='нач. ост. Кт';ru='нач. ост. Кт';vi='Dư đầu Có'"));
				ReportsServer.AddSelectedField(SelectedFieldsTurnovers, Resource.Name + "TurnoverDr", Resource.Synonym + " " + NStr("en='оборот Дт';ru='оборот Дт';vi='phát sinh Nợ'"));
				ReportsServer.AddSelectedField(SelectedFieldsTurnovers, Resource.Name + "TurnoverCr", Resource.Synonym + " " + NStr("en='оборот Кт';ru='оборот Кт';vi='phát sinh Có'"));
				ReportsServer.AddSelectedField(SelectedFieldsClosingBalance, Resource.Name + "ClosingBalanceDr", " " + Resource.Synonym + NStr("en='кон. ост. Дт';ru='кон. ост. Дт';vi='Dư cuối Nợ'"));
				ReportsServer.AddSelectedField(SelectedFieldsClosingBalance, Resource.Name + "ClosingBalanceCr", " " + Resource.Synonym + NStr("en='кон. ост. Кт';ru='кон. ост. Кт';vi='Dư cuối Có'"));
			ElsIf ReportParameters.TableName = "RecordsWithExtDimensions" Then
				If Resource.Balance Then
					ReportsServer.AddSelectedField(SelectedFields, Resource.Name, Resource.Synonym);
				Else
					ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "Dr", Resource.Synonym + " " + NStr("en='Дт';ru='Дт';vi='Ngày'"));
					ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "Cr", Resource.Synonym + " " + NStr("en='Кт';ru='Кт';vi='Có'"));
				EndIf;
			ElsIf ReportParameters.TableName = "" Then
				If Resource.Balance Then
					ReportsServer.AddSelectedField(SelectedFields, Resource.Name, Resource.Synonym);
				Else
					ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "Dr", Resource.Synonym + " " + NStr("en='Дт';ru='Дт';vi='Ngày'"));
					ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "Cr", Resource.Synonym + " " + NStr("en='Кт';ru='Кт';vi='Có'"));
				EndIf;
			EndIf;
		EndDo;
	ElsIf ReportParameters.MetadataObjectType = "Documents" 
		Or ReportParameters.MetadataObjectType = "Tasks"
		Or ReportParameters.MetadataObjectType = "BusinessProcesses"
		Or ReportParameters.MetadataObjectType = "Catalogs" Then
		If ReportParameters.TableName <> "" Then
			MetadataObject = MetadataObject.TabularSections[ReportParameters.TableName];
		EndIf;
		SelectedFields = DCSettings.Selection;
		ReportsServer.AddSelectedField(SelectedFields, "Ref");
		For Each Attribute In MetadataObject.Attributes Do
			If CommonUse.MetadataObjectAvailableByFunctionalOptions(Attribute) Then 
				ReportsServer.AddSelectedField(SelectedFields, Attribute.Name);
			EndIf;
		EndDo;
	ElsIf ReportParameters.MetadataObjectType = "ChartsOfCalculationTypes" Then
		If ReportParameters.TableName = "" Then
			For Each Attribute In MetadataObject.Attributes Do
				If Not CommonUse.MetadataObjectAvailableByFunctionalOptions(Attribute) Then 
					Continue;
				EndIf;
				
				SelectedFields = DCSettings.Selection;
				ReportsServer.AddSelectedField(SelectedFields, Attribute.Name);
			EndDo;
		Else
			For Each Attribute In MetadataObject.StandardAttributes Do
				SelectedFields = DCSettings.Selection;
				ReportsServer.AddSelectedField(SelectedFields, Attribute.Name);
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

// Формирует структуру настроек компоновки данных
//
// Parameters:
//  ReportParameters - Structure - описание объекта метаданных - источника данных
//  Scheme - DataCompositionSchema - основная схема компоновки данных отчета
//  Settings - DataCompositionSettings - настройки, чья структура формируется.
//
Procedure GenerateStructure(ReportParameters, Scheme, Settings)
	Settings.Structure.Clear();
	
	Structure = Settings.Structure.Add(Type("DataCompositionGroup"));
	
	FieldsTypes = StrSplit("Dimensions@Resources", "@", False);
	
	SourcesFieldsTypes = New Map();
	SourcesFieldsTypes.Insert("InformationRegisters", FieldsTypes);
	SourcesFieldsTypes.Insert("AccumulationRegisters", FieldsTypes);
	SourcesFieldsTypes.Insert("AccountingRegisters", FieldsTypes);
	SourcesFieldsTypes.Insert("CalculationRegisters", FieldsTypes);
	
	SourceFieldsTypes = SourcesFieldsTypes[ReportParameters.MetadataObjectType];
	If SourceFieldsTypes <> Undefined Then 
		SpecifyFieldsSuffixes = ReportParameters.MetadataObjectType = "AccountingRegisters"
			And (ReportParameters.TableName = ""
				Or ReportParameters.TableName = "DrCrTurnovers"
				Or ReportParameters.TableName = "RecordsWithExtDimensions");
		
		For Each SourceFieldsType In SourceFieldsTypes Do 
			GroupFields = Structure.GroupFields.Items;
			
			SourceMetadata = Metadata[ReportParameters.MetadataObjectType][ReportParameters.MetadataObjectName];
			For Each FieldMetadata In SourceMetadata[SourceFieldsType] Do
				If Not CommonUse.MetadataObjectAvailableByFunctionalOptions(FieldMetadata) Then 
					Continue;
				EndIf;
				
				If ReportParameters.MetadataObjectType = "AccountingRegisters"
					And FieldMetadata.AccountingFlag <> Undefined Then 
					Continue;
				EndIf;
				
				If SourceFieldsType = "Resources"
					And FieldMetadata.Type.ContainsType(Type("Number")) Then 
					Continue;
				EndIf;
				
				If SpecifyFieldsSuffixes
					And Not FieldMetadata.Balance Then 
					FieldsSuffixes = StrSplit("Dr@Cr", "@", False);
				Else
					FieldsSuffixes = StrSplit("", "@");
				EndIf;
				
				For Each Suffix In FieldsSuffixes Do 
					GroupingField = GroupFields.Add(Type("DataCompositionGroupField"));
					GroupingField.Field = New DataCompositionField(FieldMetadata.Name + Suffix);
					GroupingField.Use = True;
				EndDo;
			EndDo;
		EndDo;
	EndIf;
	
	Structure.Selection.Items.Add(Type("DataCompositionAutoSelectedField"));
	Structure.Order.Items.Add(Type("DataCompositionAutoOrderItem"));
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Работа с типовой схемой, настраиваемой в пользовательских настройках.

Function DataCompositionSchema(FixedParameters) Export 
	DataCompositionSchema = GetTemplate("MainDataCompositionSchema");
	DataCompositionSchema.TotalFields.Clear();
	
	DataSource = DataCompositionSchema.DataSources.Add();
	DataSource.Name = "DataSource1";
	DataSource.DataSourceType = "Local";
	
	DataSet = DataCompositionSchema.DataSets.Add(Type("DataCompositionSchemaDataSetQuery"));
	DataSet.Name = "DataSet1";
	DataSet.DataSource = DataSource.Name;
	DataSet.Query = TextOfQueryByMetadata(FixedParameters);
	DataSet.AutoFillAvailableFields = True;
	
	AddTotals(FixedParameters, DataCompositionSchema);
	
	If FixedParameters.MetadataObjectType = "Catalogs"
		Or FixedParameters.MetadataObjectType = "ChartsOfCalculationTypes" 
		Or (FixedParameters.MetadataObjectType = "InformationRegisters"
			And Metadata[FixedParameters.MetadataObjectType][FixedParameters.MetadataObjectName].InformationRegisterPeriodicity 
			= Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical) Then
		DataCompositionSchema.Parameters.Period.UseRestriction = True;
	EndIf;
	
	AvailableTables = AvailableTables(FixedParameters.MetadataObjectType, FixedParameters.MetadataObjectName);
	If AvailableTables.Count() < 2 Then
		DataCompositionSchema.Parameters.TableName.UseRestriction = True;
	EndIf;
	
	Return DataCompositionSchema;
EndFunction

// Устанавливает настройки по умолчанию.
//
// Parameters:
//  Report - ReportObject - 
//  FixedParameters - See FixedParameters
//  Settings - DataCompositionSettings - 
//  UserSettings - DataCompositionUserSettings - 
//
Procedure SetStandardSettings(Report, FixedParameters, Settings, UserSettings) Export 
	ReportInitialized = CommonUseClientServer.StructureProperty(
		Settings.AdditionalProperties, "ReportInitialized", False);
	
	If ReportInitialized Then 
		Return;
	EndIf;
	
	Report.SettingsComposer.LoadSettings(Report.DataCompositionSchema.DefaultSettings);
	
	Settings = Report.SettingsComposer.Settings;
	Settings.Selection.Items.Clear();
	Settings.Structure.Clear();
	
	AddIndicators(FixedParameters, Settings);
	GenerateStructure(FixedParameters, Report.DataCompositionSchema, Settings);
	
	SetFixedParameters(Report, FixedParameters, Settings, UserSettings);
	
	Settings.AdditionalProperties.Insert("ReportInitialized", True);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Работа с произвольной схемой из файла.

// Возвращает загружаемую схему компоновки данных.
//
// Parameters:
//  ImportedSchema - BinaryData - 
//
// Returns:
//  DataCompositionSchema - 
//
Function ExtractSchemaFromBinaryData(ImportedSchema) Export
	
	FullFileName = GetTempFileName();
	ImportedSchema.Write(FullFileName);
	
	XMLReader = New XMLReader;
	XMLReader.OpenFile(FullFileName);
	
	DCSchema = XDTOSerializer.ReadXML(XMLReader, Type("DataCompositionSchema"));
	
	XMLReader.Close();
	XMLReader = Undefined;
	
	DeleteFiles(FullFileName);
	
	If DCSchema.DefaultSettings.AdditionalProperties.Property("DataCompositionSchema") Then
		DCSchema.DefaultSettings.AdditionalProperties.DataCompositionSchema = Undefined;
	EndIf;
	
	Return DCSchema;
	
EndFunction

Procedure SetStandardImportedSchemaSettings(Report, SchemaBinaryData, Settings, UserSettings) Export 
	If CommonUseClientServer.StructureProperty(Settings.AdditionalProperties, "ReportInitialized", False) Then 
		Return;
	EndIf;
	
	Settings = Report.DataCompositionSchema.DefaultSettings;
	Settings.AdditionalProperties.Insert("DataCompositionSchema", SchemaBinaryData);
	Settings.AdditionalProperties.Insert("ReportInitialized",  True);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Работа с источником данных варианта отчета.

// Устанавливает параметр "ИсточникДанных" настроек варианта отчета
//
// Parameters:
//  Variant - CatalogRef.ReportsVariants - хранилище настроек варианта отчета.
//
Procedure DetermineOptionDataSource(Variant) Export
	UniversalReport = CommonUse.MetadataObjectID(Metadata.Reports.UniversalReport);
	
	BeginTransaction();
	Try
		Block = New DataLock;
		LockItem = Block.Add(Variant.Metadata().FullName());
		LockItem.SetValue("Ref", Variant);
		Block.Lock();
		
		VariantObject = Variant.GetObject();
		
		VariantSettings = Undefined;
		If VariantObject <> Undefined
			And VariantObject.Report = UniversalReport Then 
			VariantSettings = VariantSettings(VariantObject);
		EndIf;
		
		If VariantSettings = Undefined Then 
			RollbackTransaction();
			InfobaseUpdate.MarkProcessingCompletion(Variant);
			Return;
		EndIf;
		
		VariantObject.Settings = New ValueStorage(VariantSettings);
		InfobaseUpdate.WriteData(VariantObject);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
EndProcedure

// Возвращает настройки варианта отчета с установленным параметром ИсточникДанных.
//
// Parameters:
//  Variant - CatalogObject.ReportsVariants - хранилище настроек варианта отчета.
//
// Returns:
//   DataCompositionSettings, Undefined - обновленные настройки или Неопределено,
//                                            если обновить не удалось.
//
Function VariantSettings(Variant)
	Try
		VariantSettings = Variant.Settings.Get(); // НастройкиКомпоновкиДанных
	Except
		// Не удалось десериализовать хранилище значения:
		//  возможно обнаружена ссылка на несуществующий тип.
		Return Undefined;
	EndTry;
	
	If VariantSettings = Undefined Then 
		Return Undefined;
	EndIf;
	
	DataParameters = VariantSettings.DataParameters.Items;
	
	ParametersRequired = New Structure(
		"MetadataObjectType, FullMetadataObjectName, MetadataObjectName, DataSource");
	For Each Parameter In ParametersRequired Do 
		FoundParameter = DataParameters.Find(Parameter.Key);
		If FoundParameter <> Undefined Then 
			ParametersRequired[Parameter.Key] = FoundParameter.Value;
		EndIf;
	EndDo;
	
	// Если в настройках варианта хранится параметр с неактуальным именем - выполнится его актуализация.
	If ValueIsFilled(ParametersRequired.FullMetadataObjectName) Then 
		ParametersRequired.MetadataObjectName = ParametersRequired.FullMetadataObjectName;
	EndIf;
	ParametersRequired.Delete("FullMetadataObjectName");
	
	If Not ValueIsFilled(ParametersRequired.DataSource) Then 
		ParametersRequired.DataSource = DataSource(
			ParametersRequired.MetadataObjectType, ParametersRequired.MetadataObjectName);
		If ParametersRequired.DataSource = Undefined Then 
			Return Undefined;
		EndIf;
	EndIf;
	
	ParametersToSet = New Structure("DataSource, MetadataObjectName");
	FillPropertyValues(ParametersToSet, ParametersRequired);
	
	ObjectName = CommonUse.ObjectAttributeValue(ParametersRequired.DataSource, "NAME");
	If ObjectName <> ParametersToSet.MetadataObjectName Then 
		ParametersToSet.MetadataObjectName = ObjectName;
	EndIf;
	
	For Each Parameter In ParametersToSet Do 
		FoundParameter = DataParameters.Find(Parameter.Key);
		If FoundParameter = Undefined Then 
			DataParameter = DataParameters.Add();
			DataParameter.Parameter = New DataCompositionParameter(Parameter.Key);
			DataParameter.Value = Parameter.Value;
			DataParameter.Use = True;
		Else
			VariantSettings.DataParameters.SetParameterValue(Parameter.Key, Parameter.Value);
		EndIf;
	EndDo;
	
	Return VariantSettings;
EndFunction

// Возвращает источник данных отчета
//
// Parameters:
//  ManagerType - String - представление менеджера объекта метаданных,
//                 например, "Справочники" или "РегистрыСведений" и т.д.
//  ObjectName  - String - краткое имя объекта метаданных,
//                например, "Валюты" или "КурсыВалют" и т.д.
//
// Returns:
//   CatalogRef.MetadataObjectIDs, Undefined -
//   ссылка на найденный элемент справочника, иначе - Неопределено.
//
Function DataSource(ManagerType, ObjectName)
	ObjectType = ObjectTypeByManagerType(ManagerType);
	FullObjectName = ObjectType + "." + ObjectName;
	If Metadata.FindByFullName(FullObjectName) = Undefined Then 
		WriteLogEvent(NStr("en='Варианты отчетов.Установка источника данных универсального отчета';ru='Варианты отчетов.Установка источника данных универсального отчета';vi='Phương án báo cáo. Thiết lập nguồn dữ liệu của báo cáo đa năng'", 
			CommonUse.MainLanguageCode()),
			EventLogLevel.Error,
			Metadata.Catalogs.ReportsVariants,,
			StringFunctionsClientServer.SubstituteParametersInString(NStr("en='Источник данных %1 отсутствует';ru='Источник данных %1 отсутствует';vi='Thiếu nguồn dữ liệu %1'"), 
				FullObjectName));
		Return Undefined;
	EndIf;
	
	Return CommonUse.MetadataObjectID(FullObjectName);
EndFunction

// Возвращает тип объекта метаданных по соответствующему типу менеджера
//
// Parameters:
//  ManagerType - String - представление менеджера объекта метаданных,
//                 например, "Справочники" или "РегистрыСведений" и т.д.
//
// Returns:
//   String - тип объекта метаданных, например, "Справочник" или "РегистрСведений" и т.д.
//
Function ObjectTypeByManagerType(ManagerType)
	Types = New Map;
	Types.Insert("Catalogs", "Catalog");
	Types.Insert("Documents", "Document");
	Types.Insert("DATAPROCESSORS", "DataProcessor");
	Types.Insert("ChartsOfCharacteristicTypes", "CHARTOFCHARACTERISTICTYPES");
	Types.Insert("AccountingRegisters", "AccountingRegister");
	Types.Insert("AccumulationRegisters", "AccumulationRegister");
	Types.Insert("CalculationRegisters", "CalculationRegister");
	Types.Insert("InformationRegisters", "InformationRegister");
	Types.Insert("BusinessProcesses", "BusinessProcess");
	Types.Insert("DocumentJournals", "DocumentJournal");
	Types.Insert("Tasks", "TASK");
	Types.Insert("Reports", "Report");
	Types.Insert("Constants", "Constant");
	Types.Insert("Enums", "Enum");
	Types.Insert("ChartsOfCalculationTypes", "CHARTOFCALCULATIONTYPES");
	Types.Insert("ExchangePlans", "ExchangePlan");
	Types.Insert("ChartsOfAccounts", "CHARTOFACCOUNTS");
	
	Return ?(Types[ManagerType] = Undefined, "", Types[ManagerType]);
EndFunction

#EndRegion

#EndIf