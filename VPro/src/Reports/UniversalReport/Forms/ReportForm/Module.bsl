///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2020, ООО 1С-Софт
// Все права защищены. Эта программа и сопроводительные материалы предоставляются 
// в соответствии с условиями лицензии Attribution 4.0 International (CC BY 4.0)
// Текст лицензии доступен по ссылке:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var HandlerAfterGenerateAtClient Export;
&AtClient
Var MeasurementID;
&AtClient
Var Directly;
&AtClient
Var GenerateOnOpening;
&AtClient
Var WaitngInterval;

#EndRegion

#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(cancel, StandardProcessing)
	
	DefineBehaviorInMobileClient();
	
	// Определение ключевых параметров отчета.
	EncryptingMode = (Parameters.Property("Details") And Parameters.Details <> Undefined);
	OutputRight = AccessRight("Output", Metadata);
	
	ReportObject     = FormAttributeToValue("Report");
	ReportMetadata = ReportObject.Metadata();
	ReportFullName  = ReportMetadata.FullName();
	PredefinedVariants = New ValueList;
	If ReportObject.DataCompositionSchema <> Undefined Then
		For Each Variant In ReportObject.DataCompositionSchema.SettingVariants Do
			PredefinedVariants.Add(Variant.Name, Variant.Presentation);
		EndDo;
	EndIf;
	
	SetCurrentOptionKey(ReportFullName, PredefinedVariants);
	
	// Предварительная инициализация компоновщика (если требуется).
	SchemaURL = CommonUseClientServer.StructureProperty(Parameters, "SchemaURL");
	If EncryptingMode And TypeOf(Parameters.Details) = Type("DataCompositionDetailsProcessDescription") Then
		NewSettingsDC = GetFromTempStorage(Parameters.Details.Data).Settings;
		SchemaURL = CommonUseClientServer.StructureProperty(NewSettingsDC.AdditionalProperties, "SchemaURL");
	EndIf;
	If TypeOf(SchemaURL) = Type("String") And IsTempStorageURL(SchemaURL) Then
		DataCompositionSchema = GetFromTempStorage(SchemaURL);
		If TypeOf(DataCompositionSchema) = Type("DataCompositionSchema") Then
			SchemaURL = PutToTempStorage(DataCompositionSchema, UUID);
			Report.SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(SchemaURL));
		Else
			SchemaURL = PutToTempStorage(ReportObject.DataCompositionSchema, UUID);
		EndIf;
	Else
		SchemaURL = PutToTempStorage(ReportObject.DataCompositionSchema, UUID);
	EndIf;
	
	// Сохранение параметров открытия формы.
	ParametersForm = New Structure(
		"PurposeUseKey, UserSettingsKey,
		|GenerateOnOpen, ReadOnly,
		|FixedSettings, Section, Subsystem, SubsystemPresentation");
	FillPropertyValues(ParametersForm, Parameters);
	ParametersForm.Insert("Filter", New Structure);
	If TypeOf(Parameters.Filter) = Type("Structure") Then
		CommonUseClientServer.ExpandStructure(ParametersForm.Filter, Parameters.Filter, True);
		Parameters.Filter.Clear();
	EndIf;
	
	// Определение настроек отчета.
	ReportByStringType = ReportsVariants.ReportByStringType(Parameters.Report);
	If ReportByStringType = Undefined Then
		Information      = ReportsVariants.ReportInformation(ReportFullName, True);
		Parameters.Report = Information.Report;
	EndIf;
	ReportSettings = ReportsVariants.ReportFormSettings(Parameters.Report, CurrentVariantKey, ReportObject);
	ReportSettings.Insert("OptionSelectionAllowed", True);
	ReportSettings.Insert("SchemaModified", False);
	ReportSettings.Insert("PredefinedVariants", PredefinedVariants);
	ReportSettings.Insert("SchemaURL",   SchemaURL);
	ReportSettings.Insert("SchemaKey",    "");
	ReportSettings.Insert("Contextual",  TypeOf(ParametersForm.Filter) = Type("Structure") And ParametersForm.Filter.Count() > 0);
	ReportSettings.Insert("FullName",    ReportFullName);
	ReportSettings.Insert("Description", TrimAll(ReportMetadata.Presentation()));
	ReportSettings.Insert("ReportRef",  Parameters.Report);
	ReportSettings.Insert("Subsystem",   ParametersForm.Subsystem);
	ReportSettings.Insert("External",      TypeOf(ReportSettings.ReportRef) = Type("String"));
	ReportSettings.Insert("Safe",   SafeMode() <> False);
	UpdateInfoOnReportOption();
		
	ReportSettings.Insert("ReadCheckBoxGenerateImmediatelyFromUserSettings", True);
	If Parameters.Property("GenerateOnOpen") And Parameters.GenerateOnOpen = True Then
		Parameters.GenerateOnOpen = False;
		Items.FormImmediately.Check = True;
		ReportSettings.ReadCheckBoxGenerateImmediatelyFromUserSettings = False;
	EndIf;
	
	If CommonUse.ThisIsWebClient() Then 
		Items.Preview.Visible = False;
	EndIf;
	
	// Параметры по умолчанию.
	If Not CommonUseClientServer.StructureProperty(ReportSettings, "OutputAmountSelectedCells", True) Then
		Items.IndicatorGroup.Visible = False;
		Items.IndicatorsArea.Visible = False;
		Items.MoreIndicatorsKindsCommands.Visible = False;
		Items.ReportSpreadsheetDocument.SetAction("ПриАктивизацииОбласти", "");
	EndIf;
	
	// Скрытие команд вариантов.
	ReportVariantsCommandsVisible = CommonUseClientServer.StructureProperty(Parameters, "ReportVariantsCommandsVisible");	
	
	If ReportVariantsCommandsVisible = False Then
		ReportSettings.EditOptionsAllowed = False;
		ReportSettings.OptionSelectionAllowed = False;
		If IsBlankString(PurposeUseKey) Then
			PurposeUseKey = Parameters.VariantKey;
			ParametersForm.PurposeUseKey = PurposeUseKey;
		EndIf;
	EndIf;
	If ReportSettings.EditOptionsAllowed And Not ReportsVariantsReUse.AddRight() Then
		ReportSettings.EditOptionsAllowed = False;
	EndIf;
	
	SelectAndEditOptionsWithoutSavingAllowed = CommonUseClientServer.StructureProperty(
		ReportSettings, "SelectAndEditOptionsWithoutSavingAllowed", False);
	
	If SelectAndEditOptionsWithoutSavingAllowed Then
		ReportSettings.EditOptionsAllowed = True;
		ReportSettings.OptionSelectionAllowed = True;
		VariantModified                      = False;
		If IsBlankString(PurposeUseKey) Then
			PurposeUseKey = Parameters.VariantKey;
			ParametersForm.PurposeUseKey = PurposeUseKey;
		EndIf;
	EndIf;
	
	// Регистрация команд и реквизитов формы, которые не удаляются при перезаполнении быстрых настроек.
	AttributesSet = GetAttributes();
	For Each Attribute In AttributesSet Do
		AttributeFullName = Attribute.Name + ?(IsBlankString(Attribute.Path), "", "." + Attribute.Path);
		ConstantAttributes.Add(AttributeFullName);
	EndDo;
	
	For Each Command In Commands Do
		ConstantCommands.Add(Command.Name);
	EndDo;
	
	If Not ReportVariantMode() Then 
		SetVisibleEnabled();
	EndIf;
	
	// Тесная интеграция с почтой и рассылкой.
	AvailableEmailSending = False;
	If CommonUse.SubsystemExists("StandardSubsystems.EmailOperations") Then
		ModuleEmailOperations = CommonUse.CommonModule("EmailOperations");
		AvailableEmailSending = ModuleEmailOperations.AvailableEmailSending();
	EndIf;
	If AvailableEmailSending Then
		If ReportSettings.EditOptionsAllowed
			And CommonUse.SubsystemExists("StandardSubsystems.ReportMailing")
			And Not ReportSettings.HideBulkEmailCommands Then
			ReportSendingModule = CommonUse.CommonModule("ReportMailing");
			ReportSendingModule.ReportFormAddCommands(ThisObject, cancel, StandardProcessing);
		Else // Если в подменю одна команда, то выпадающий список не отображается.
			Items.SendByEmail.Title = Items.GroupSend.Title + "...";
			Items.Move(Items.SendByEmail, Items.GroupSend.Parent, Items.GroupSend);
		EndIf;
	Else
		Items.GroupSend.Visible = False;
	EndIf;
	
	// Определение, что отчет может содержать некорректные данные.
	If Not Items.FormImmediately.Check Then
		Try
			TablesToUse = ReportsVariants.TablesToUse(ReportObject.DataCompositionSchema);
			TablesToUse.Add(ReportSettings.FullName);
			If ReportSettings.Events.OnDefineUsedTables Then
				ReportObject.OnDefineUsedTables(CurrentVariantKey, TablesToUse);
			EndIf;
		Except
			ErrorText = NStr("en='Can not determine the using tables:';ru='Не удалось определить используемые таблицы:';vi='Không thể xác định các bảng đang sử dụng:'");
			ErrorText = ErrorText + Chars.LF + DetailErrorDescription(ErrorInfo());
			ReportsVariants.WriteInJournal(EventLogLevel.Error, ErrorText, ReportSettings.VariantRef);
		EndTry;
	EndIf;
	
	DisplayReportState(NStr("en='The report is not generated. Click ""Generate"" to generate the report.';ru='Отчет не сформирован. Нажмите ""Сформировать"" для получения отчета.';vi='Báo cáo chưa được lập. Hãy nhấp vào nút ""Lập báo cáo"" để nhận báo cáo.'"));
	
	ReportsOverridable.OnCreateAtServer(ThisObject, cancel, StandardProcessing);
	If ReportSettings.Events.OnCreateAtServer Then
		ReportObject.OnCreateAtServer(ThisObject, cancel, StandardProcessing);
	EndIf;
EndProcedure

&AtClient
Procedure OnOpen(cancel)
		
	Directly = ReportSettings.External Or ReportSettings.Safe;
	GenerateOnOpening = False;
	WaitngInterval = ?(GetClientConnectionSpeed() = ClientConnectionSpeed.Low, 1, 0.2);
	
	If Items.FormImmediately.Check Then
		GenerateOnOpening = True;
		AttachIdleHandler("Generate", 0.1, True);
	EndIf;
	
	CommonInternalClient.SetIndicatorsPanelVisibiility(Items, ExpandIndicatorsArea);
	CommonInternalClient.CalculateIndicators(ThisObject, "ReportSpreadsheetDocument", MainIndicator);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(Result, SubordinateForm)
	ResultProcessed = False;
	
	// Приемка результата из стандартных форм.
	If TypeOf(SubordinateForm) = Type("ClientApplicationForm") Then
		SubordinateFormName = SubordinateForm.FormName;
		If SubordinateFormName = "SettingsStorage.ReportsVariantsStorage.Form.ReportSettings"
			Or SubordinateForm.OnCloseNotifyDescription <> Undefined Then
			ResultProcessed = True; // См. ВсеНастройкиЗавершение.
		ElsIf TypeOf(Result) = Type("Structure") Then
			DotPosition = StrLen(SubordinateFormName);
			While CharCode(SubordinateFormName, DotPosition) <> 46 Do // Не точка.
				DotPosition = DotPosition - 1;
			EndDo;
			SourseFormSuffix = Upper(Mid(SubordinateFormName, DotPosition + 1));
			If SourseFormSuffix = Upper("ReportSettingsForm")
				Or SourseFormSuffix = Upper("SettingsForm")
				Or SourseFormSuffix = Upper("ReportVariantFormMain")
				Or SourseFormSuffix = Upper("VariantForm") Then
				
				UpdateSettingsFormItems(Result);
				ResultProcessed = True;
			EndIf;
		EndIf;
	ElsIf TypeOf(SubordinateForm) = Type("DataCompositionSchemaWizard") Then
#If ThickClientOrdinaryApplication Or ThickClientManagedApplication Then
		If TypeOf(Result) = Type("DataCompositionSchema") Then
			ReportSettings.SchemaURL = PutToTempStorage(Result, UUID);
			
			Path = GetTempFileName();
			
			XMLWriter = New XMLWriter; 
			XMLWriter.OpenFile(Path, "UTF-8");
			XDTOSerializer.WriteXML(XMLWriter, Result, "dataCompositionSchema", "http://v8.1c.ru/8.1/data-composition-system/schema"); 
			XMLWriter.Close();
			
			BinaryData = New BinaryData(Path);
			BeginDeletingFiles(, Path);
			
			Report.SettingsComposer.Settings.AdditionalProperties.Insert("DataCompositionSchema", BinaryData);
			Report.SettingsComposer.Settings.AdditionalProperties.Insert("ReportInitialized",  False);
			
			FillingParameters = New Structure;
			FillingParameters.Insert("UserSettingsModified", True);
			FillingParameters.Insert("DCSettingsComposer", Report.SettingsComposer);
			FillingParameters.Insert("EventName", "DefaultSettings");
			
			UpdateSettingsFormItems(FillingParameters);
		EndIf;
#EndIf
	EndIf;
	
	// Механизмы расширения.
	If CommonUseClient.SubsystemExists("StandardSubsystems.ReportMailing") Then
		ModuleReportSendingClient = CommonUseClient.CommonModule("ReportMailingClient");
		ModuleReportSendingClient.ReportFormChoiceProcessing(ThisObject, Result, SubordinateForm, ResultProcessed);
	EndIf;
	
	ReportsClientOverridable.ChoiceProcessing(ThisObject, Result, SubordinateForm, ResultProcessed);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	NotificationProcessed = False;
	
	If EventName = "Record_SetOfConstants" Then 
		
		NotificationProcessed = True;
		PanelVariantsCurrentVariantKey = BlankOptionKey();
		
	ElsIf EventName = ReportsVariantsClient.EventNameOptionChanging() Then 
		
		NotificationProcessed = True;
		VariantKey = Undefined;
		
		If TypeOf(Parameter) = Type("Structure") Then 
			Parameter.Property("VariantKey", VariantKey);
		EndIf;
		
		If ValueIsFilled(VariantKey) Then 
			SetCurrentVariant(VariantKey);
		Else
			PanelVariantsCurrentVariantKey = BlankOptionKey();
		EndIf;
		
	ElsIf EventName = ReportsVariantsClientServer.ApplyPassedSettingsActionName() Then 
		
		NotificationProcessed = True;
		ApplyPassedSettings(Parameter);
		
	EndIf;
	
	ReportsClientOverridable.NotificationProcessing(ThisObject, EventName, Parameter, Source, NotificationProcessed);
EndProcedure

&AtServer
Procedure BeforeLoadVariantAtServer(NewSettingsDC)
	
	// Ничего не делать если отчет не на СКД и никаких настроек не загружено.
	If NewSettingsDC = Undefined Or Not ReportVariantMode() Then
		Return;
	EndIf;
	
	//SSLSubsystemsIntegration.BeforeLoadVariantAtServer(ThisObject, NewSettingsDC);
	ReportsOverridable.BeforeLoadVariantAtServer(ThisObject, NewSettingsDC);
	If ReportSettings.Events.BeforeLoadVariantAtServer Then
		ReportObject = FormAttributeToValue("Report");
		ReportObject.BeforeLoadVariantAtServer(ThisObject, NewSettingsDC);
	EndIf;
	
	// Подготовка к вызову события переинициализации.
	If ReportSettings.Events.BeforeImportSettingsToComposer Then
		Try
			NewXMLSettings = CommonUse.ValueToXMLString(NewSettingsDC);
		Except
			NewXMLSettings = Undefined;
		EndTry;
		ReportSettings.Insert("NewXMLSettings", NewXMLSettings);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadVariantAtServer(NewSettingsDC)
	
	// Ничего не делать если отчет не на СКД и никаких настроек не загружено.
	If Not ReportVariantMode() And NewSettingsDC = Undefined Then
		Return;
	EndIf;
	
	// Загрузка фиксированных настроек для режима расшифровки.
	If EncryptingMode Then
		ReportCurrentVariantName = CommonUseClientServer.StructureProperty(NewSettingsDC.AdditionalProperties, "OptionName");
		
		If Parameters <> Undefined And Parameters.Property("Details") Then
			Report.SettingsComposer.LoadFixedSettings(Parameters.Details.UsedSettings);
			Report.SettingsComposer.FixedSettings.AdditionalProperties.Insert("EncryptingMode", True);
		EndIf;
		
		If CurrentVariantKey = Undefined Then
			CurrentVariantKey = CommonUseClientServer.StructureProperty(NewSettingsDC.AdditionalProperties, "VariantKey");
		EndIf;
	EndIf;
	
	// Установка фиксированных отборов выполняется через компоновщик, т.к. в нем наиболее полная коллекция настроек.
	// В ПередЗагрузкой в параметрах могут отсутствовать те параметры, настройки которых не переопределялись.
	If TypeOf(ParametersForm.Filter) = Type("Structure") Then
		ReportsServer.SetFixedFilters(ParametersForm.Filter, Report.SettingsComposer.Settings, ReportSettings);
	EndIf;
	
	// Обновление ссылки варианта отчета.
	If PanelVariantsCurrentVariantKey <> CurrentVariantKey Then
		UpdateInfoOnReportOption();
	EndIf;
	
	If ReportSettings.Events.OnLoadVariantAtServer Then
		ReportObject = FormAttributeToValue("Report");
		ReportObject.OnLoadVariantAtServer(ThisObject, NewSettingsDC);
	EndIf;
EndProcedure

&AtServer
Procedure BeforeLoadUserSettingsAtServer(NewDCUserSettings)
	If ReportSettings.Events.BeforeImportSettingsToComposer Then
		// Подготовка к переинициализации.
		Try
			NewUserXMLSettings = CommonUse.ValueToXMLString(NewDCUserSettings);
		Except
			NewUserXMLSettings = Undefined;
		EndTry;
		ReportSettings.Insert("NewUserXMLSettings", NewUserXMLSettings);
	EndIf;
EndProcedure

&AtServer
Procedure OnLoadUserSettingsAtServer(NewDCUserSettings)
	If Not ReportVariantMode() Then
		Return;
	EndIf;
	
	If ReportSettings.Events.OnLoadUserSettingsAtServer Then
		ReportObject = FormAttributeToValue("Report");
		ReportObject.OnLoadUserSettingsAtServer(ThisObject, NewDCUserSettings);
	EndIf;
EndProcedure

&AtServer
Procedure OnUpdateUserSettingSetAtServer(StandardProcessing)
	If Not ReportVariantMode() Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	UpdateParameters = New Structure("EventName", "OnUpdateUserSettingSetAtServer");
 	UpdateSettingsFormItemsAtServer(UpdateParameters);
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(cancel, CheckedAttributes)
	If Not ReportVariantMode() Then
		Return;
	EndIf;
	
	SettingsItems = Report.SettingsComposer.UserSettings.Items;
	For Each SettingItem In SettingsItems Do
		If TypeOf(SettingItem) <> Type("DataCompositionSettingsParameterValue")
			Or TypeOf(SettingItem.Value) <> Type("StandardPeriod")
			Or Not SettingItem.Use Then
			Continue;
		EndIf;
		
		NamePattern = "SettingsComposerUserSettingsItem" + SettingsItems.IndexOf(SettingItem);
		
		BeginDate = Items.Find(NamePattern + "BeginDate");
		EndDate = Items.Find(NamePattern + "EndDate");
		If BeginDate = Undefined Or EndDate = Undefined Then 
			Continue;
		EndIf;
		
		Value = SettingItem.Value;
		If BeginDate.AutoMarkIncomplete = True
			And Not ValueIsFilled(Value.StartDate)
			And Not ValueIsFilled(Value.EndDate) Then
			ErrorText = NStr("en='Не указан период';ru='Не указан период';vi='Chưa chỉ ra kỳ'");
			DataPath = BeginDate.DataPath;
		ElsIf Value.StartDate > Value.EndDate Then
			ErrorText = NStr("en='Конец периода должен быть больше начала';ru='Конец периода должен быть больше начала';vi='Cuối kỳ phải lớn hơn đầu kỳ'");
			DataPath = EndDate.DataPath;
		Else
			Continue;
		EndIf;
		
		CommonUse.MessageToUser(ErrorText,, DataPath,, cancel);
	EndDo;
EndProcedure

&AtServer
Procedure OnSaveVariantAtServer(DCSettings)
	
	If Not ReportVariantMode() Then
		Return;
	EndIf;
	
	NewSettingsDC = Report.SettingsComposer.GetSettings();
	ReportsClientServer.LoadSettings(Report.SettingsComposer, NewSettingsDC);
	DCSettings.AdditionalProperties.Insert("Address", PutToTempStorage(NewSettingsDC));
	DCSettings = NewSettingsDC;
	PanelVariantsCurrentVariantKey = BlankOptionKey();
	UpdateInfoOnReportOption();
	SetVisibleEnabled(True);
	
EndProcedure

&AtServer
Procedure OnSaveUserSettingsAtServer(DCUserSettings)
	If Not ReportVariantMode() Then
		Return;
	EndIf;
	ReportsVariants.OnSaveUserSettingsAtServer(ThisObject, DCUserSettings);
	UpdateOptionsSelectionCommands();
EndProcedure

#EndRegion

#Region HeaderFormItemsEventsHandlers

////////////////////////////////////////////////////////////////////////////////
// Табличный документ

&AtClient
Procedure ReportSpreadsheetDocumentSelection(Item, Area, StandardProcessing)
	
	If StandardProcessing Then
		ReportsClientOverridable.SpreadsheetDocumentChoiceProcessing(ThisObject, Item, Area, StandardProcessing);
	EndIf;
	
	If StandardProcessing And TypeOf(Area) = Type("SpreadsheetDocumentRange") Then
		If NavigateToLink(Area.Text) Then
			StandardProcessing = False;
			Return;
		EndIf;
		
		Try
			ValueDetails = Area.Details;
		Except
			ValueDetails = Undefined;
			// Для некоторых типов областей табличного документа (свойство ТипОбласти)
			// чтение расшифровки недоступно, поэтому делается попытка-исключение.
		EndTry;
		
		If ValueDetails <> Undefined And NavigateToLink(ValueDetails) Then
			StandardProcessing = False;
			Return;
		EndIf;
		If NavigateToLink(Area.Mask) Then
			StandardProcessing = False;
			Return;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure ReportSpreadsheetDocumentDetailProcessing(Item, Details, StandardProcessing)
	If CommonUseClient.SubsystemExists("StandardSubsystems.EventsLogAnalysis") Then
		ModuleEventLogAnalysisClient = CommonUseClient.CommonModule("EventLogAnalysisClient");
		ModuleEventLogAnalysisClient.ReportFormDetailProcessing(ThisObject, Item, Details, StandardProcessing);
	EndIf;
	
	ReportsClientOverridable.DetailProcessing(ThisObject, Item, Details, StandardProcessing);
EndProcedure

&AtClient
Procedure ReportSpreadsheetDocumentAdditionalDetailProcessing(Item, Details, StandardProcessing)
	If CommonUseClient.SubsystemExists("StandardSubsystems.EventsLogAnalysis") Then
		ModuleEventLogAnalysisClient = CommonUseClient.CommonModule("EventLogAnalysisClient");
		ModuleEventLogAnalysisClient.AdditionalDetailProcessingReportForm(ThisObject, Item, Details, StandardProcessing);
	EndIf;
	
	ReportsClientOverridable.AdditionalDetailProcessing(ThisObject, Item, Details, StandardProcessing);
EndProcedure

&AtClient
Procedure ReportSpreadsheetDocumentOnActivate(Item)
	AttachIdleHandler("CalculateIndicatorsDynamically", 0.2, True);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Подключаемые

&AtClient
Procedure Attachable_SettingItem_OnChange(Item)
	
	SettingsComposer = Report.SettingsComposer;
	
	IndexOf = PathToItemsData.ByName[Item.Name];
	If IndexOf = Undefined Then 
		IndexOf = ReportsClientServer.SettingItemIndexByPath(Item.Name);
	EndIf;
	
	SettingItem = SettingsComposer.UserSettings.Items[IndexOf];
	
	IsFlag = StrStartsWith(Item.Name, "CheckBox") Or StrEndsWith(Item.Name, "CheckBox");
	If IsFlag Then 
		SettingItem.Value = ThisObject[Item.Name];
	EndIf;
	
	If TypeOf(SettingItem) = Type("DataCompositionSettingsParameterValue")
		And ReportSettings.ImportSettingsOnChangeParameters.Find(SettingItem.Parameter) <> Undefined Then 
		
		SettingsComposer.Settings.AdditionalProperties.Insert("ReportInitialized", False);
		
		UpdateParameters = New Structure;
		UpdateParameters.Insert("DCSettingsComposer", SettingsComposer);
		UpdateParameters.Insert("UserSettingsModified", True);
		
		UpdateSettingsFormItems(UpdateParameters);
	EndIf;
EndProcedure

&AtClient
Procedure Attachable_SettingItem_StartChoice(Item, ChoiceData, StandardProcessing)
	ShowChoiceList(Item, StandardProcessing)
EndProcedure

&AtClient
Procedure Attachable_Period_OnChange(Item)
	ReportsClient.SetPeriod(ThisObject, Item.Name);
EndProcedure

&AtClient
Procedure Attachable_SelectPeriod(Command)
	ReportsClient.SelectPeriod(ThisObject, Command.Name);
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure AllSettings(Command)
	ReportName = ReportSettings.FullName + ".SettingsForm";
	
	FormParameters = New Structure;
	CommonUseClientServer.ExpandStructure(FormParameters, ParametersForm, True);
	FormParameters.Insert("VariantKey", String(CurrentVariantKey));
	FormParameters.Insert("Variant", Report.SettingsComposer.Settings);
	FormParameters.Insert("UserSettings", Report.SettingsComposer.UserSettings);
	FormParameters.Insert("ReportSettings", ReportSettings);
	FormParameters.Insert("OptionName", String(ReportCurrentVariantName));
	
	Mode = FormWindowOpeningMode.LockOwnerWindow;
	
	Handler = New NotifyDescription("AllSettingsEnd", ThisObject);
	
	
	OpenForm(ReportName, FormParameters, ThisObject, , , , Handler, Mode);
	
EndProcedure

&AtClient
Procedure AllSettingsEnd(Result, ExecuteParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;
	
	ReportSettings.Insert("SettingsResult", Result);
	AttachIdleHandler("UpdateSettingsFormItemsDeferred", 0.1, True);
EndProcedure

&AtClient
Procedure ChangeReportVariant(Command)
	FormParameters = New Structure;
	CommonUseClientServer.ExpandStructure(FormParameters, ParametersForm, True);
	FormParameters.Insert("ReportSettings", ReportSettings);
	FormParameters.Insert("Variant", Report.SettingsComposer.Settings);
	FormParameters.Insert("VariantKey", String(CurrentVariantKey));
	FormParameters.Insert("UserSettings", Report.SettingsComposer.UserSettings);
	FormParameters.Insert("VariantPresentation", String(ReportCurrentVariantName));
	FormParameters.Insert("UserSettingsPresentation", "");
	
	OpenForm(ReportSettings.FullName + ".VariantForm", FormParameters, ThisObject);
EndProcedure

&AtClient
Procedure DefaultSettings(Command)
	FillingParameters = New Structure;
	FillingParameters.Insert("EventName", "DefaultSettings");
	
	If VariantModified Then
		FillingParameters.Insert("ClearOptionSettings", True);
		FillingParameters.Insert("VariantModified", False);
	EndIf;
	
	FillingParameters.Insert("ResetUserSettings", True);
	FillingParameters.Insert("UserSettingsModified", True);
	
	UpdateSettingsFormItems(FillingParameters);
EndProcedure

&AtClient
Procedure SendByEmail(Command)
	StatePresentation = Items.ReportSpreadsheetDocument.StatePresentation;
	If StatePresentation.Visible = True
		And StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance Then
		QuestionText = NStr("en='Report not generated. Generate ?';ru='Отчет не сформирован. Сформировать?';vi='Báo cáo vẫn chưa được lập. Lập báo cáo?'");
		Handler = New NotifyDescription("GenerateBeforeEmailing", ThisObject);
		ShowQueryBox(Handler, QuestionText, QuestionDialogMode.YesNo, 60, DialogReturnCode.Yes);
	Else
		ShowSendByEmailDialog();
	EndIf;
EndProcedure

&AtClient
Procedure ReportAssembleResult(Command)
	
	ClearMessages();
	
	Generate();
	
EndProcedure

&AtClient
Procedure FormImmediately(Command)
	FormImmediately = Not Items.FormImmediately.Check;
	Items.FormImmediately.Check = FormImmediately;
	
	StateBeforeChange = New Structure("Visible, AdditionalShowMode, Picture, Text");
	FillPropertyValues(StateBeforeChange, Items.ReportSpreadsheetDocument.StatePresentation);
	
	Report.SettingsComposer.UserSettings.AdditionalProperties.Insert("FormImmediately", FormImmediately);
	UserSettingsModified = True;
	
	FillPropertyValues(Items.ReportSpreadsheetDocument.StatePresentation, StateBeforeChange);
EndProcedure

&AtClient
Procedure OtherReports(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("VariantRef", ReportSettings.VariantRef);
	FormParameters.Insert("ReportRef", ReportSettings.ReportRef);
	FormParameters.Insert("SubsystemRef", ParametersForm.Subsystem);
	FormParameters.Insert("ReportName", ReportSettings.Title);
	
	Block = FormWindowOpeningMode.LockOwnerWindow;
	
	OpenForm("SettingsStorage.ReportsVariantsStorage.Form.OtherReportsPanel", FormParameters, ThisObject, True, , , , Block);
EndProcedure

&AtClient
Procedure EditSchema(Command)
#If ThickClientOrdinaryApplication Or ThickClientManagedApplication Then
	DataCompositionSchema = GetFromTempStorage(ReportSettings.SchemaURL);
	
	If DataCompositionSchema.DefaultSettings.AdditionalProperties.Property("DataCompositionSchema") Then
		DataCompositionSchema.DefaultSettings.AdditionalProperties.DataCompositionSchema = Undefined;
	EndIf;
	
	Assistant = New DataCompositionSchemaWizard(DataCompositionSchema);
	Assistant.Edit(ThisObject);
#Else
	ShowMessageBox(, (NStr("en='Для того чтобы редактировать схему компоновки, необходимо запустить приложение в режиме толстого клиента.';ru='Для того чтобы редактировать схему компоновки, необходимо запустить приложение в режиме толстого клиента.';vi='Để chỉnh sửa sơ đồ dàn dựng, cần chạy ứng dụng ở chế độ Client dày.'")));
#EndIf
EndProcedure

&AtClient
Procedure RestoreDefaultSchema(Command)
	Report.SettingsComposer.Settings.AdditionalProperties.Clear();
	
	DataParameters = Report.SettingsComposer.Settings.DataParameters.Items;
	ParametersNamesToClear = StrSplit("MetadataObjectType, MetadataObjectName, TableName", ", ", False);
	For Each ParameterName In ParametersNamesToClear Do 
		FoundParameter = DataParameters.Find(ParameterName);
		If FoundParameter <> Undefined Then 
			FoundParameter.Value = Undefined;
		EndIf;
	EndDo;
	
	FillingParameters = New Structure;
	FillingParameters.Insert("DCSettingsComposer", Report.SettingsComposer);
	FillingParameters.Insert("UserSettingsModified", True);
	
	UpdateSettingsFormItems(FillingParameters);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Обработчики команд обмена настройками (основными и пользовательскими).

&AtClient
Procedure SaveReportOptionToFile(Command)
	SavingParameters = New Structure(ReportsVariantsClientServer.ReportOptionSavingProperties());
	FillPropertyValues(SavingParameters, ThisObject);
	
	SavingParameters.ReportVariant = ReportSettings.VariantRef;
	SavingParameters.ReportName = ReportSettings.FullName;
	SavingParameters.ReportOptionSettings = Report.SettingsComposer.Settings;
	
	OpenForm(
		"SettingsStorage.ReportsVariantsStorage.Form.SaveReportOptionToFile",
		SavingParameters,
		ThisObject);
EndProcedure

&AtClient
Procedure ShareSettings(Command)
	SettingsDescription = New Structure();
	SettingsDescription.Insert("ReportVariant", ReportSettings.VariantRef);
	SettingsDescription.Insert("ObjectKey", ReportSettings.FullName + "/" + CurrentVariantKey);
	SettingsDescription.Insert("SettingsKey", CurrentUserSettingsKey);
	SettingsDescription.Insert("Presentation", CurrentUserSettingsPresentation);
	SettingsDescription.Insert("Settings", Report.SettingsComposer.UserSettings);
	SettingsDescription.Insert("VariantModified", VariantModified);
	
	ReportsVariantsClient.ShareUserSettings(SettingsDescription);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Обработчики команд расчета показателей.

&AtClient
Procedure CalculateAmount(Command)
	CommonInternalClient.CalculateIndicators(ThisObject, "ReportSpreadsheetDocument", Command.Name);
EndProcedure

&AtClient
Procedure CalculateCount(Command)
	CommonInternalClient.CalculateIndicators(ThisObject, "ReportSpreadsheetDocument", Command.Name);
EndProcedure

&AtClient
Procedure CalculateAverage(Command)
	CommonInternalClient.CalculateIndicators(ThisObject, "ReportSpreadsheetDocument", Command.Name);
EndProcedure

&AtClient
Procedure CalculateMin(Command)
	CommonInternalClient.CalculateIndicators(ThisObject, "ReportSpreadsheetDocument", Command.Name);
EndProcedure

&AtClient
Procedure CalculateMax(Command)
	CommonInternalClient.CalculateIndicators(ThisObject, "ReportSpreadsheetDocument", Command.Name);
EndProcedure

&AtClient
Procedure CalculateAllIndicators(Command)
	CommonInternalClient.SetIndicatorsPanelVisibiility(
		Items, Not Items.CalculateAllIndicators.Check);
EndProcedure

&AtClient
Procedure CollapseIndicators(Command)
	CommonInternalClient.SetIndicatorsPanelVisibiility(Items);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Подключаемые

&AtClient
Procedure Attachable_Command(Command)
	ConstantCommand = ConstantCommands.FindByValue(Command.Name);
	If ConstantCommand <> Undefined And ValueIsFilled(ConstantCommand.Presentation) Then
		SubstringArray = StrSplit(ConstantCommand.Presentation, ".");
		ClientModule = CommonUseClient.CommonModule(SubstringArray[0]);
		Handler = New NotifyDescription(SubstringArray[1], ClientModule, Command);
		ExecuteNotifyProcessing(Handler, ThisObject);
	Else
		
		ReportsClientOverridable.CommandHandler(ThisObject, Command, False);
	EndIf;
EndProcedure

&AtClient
Procedure Attachable_LoadReportVariant(Command)
	Found = AddedVariants.FindRows(New Structure("CommandName", Command.Name));
	If Found.Count() = 0 Then
		ShowMessageBox(, NStr("en='Вариант отчета не найден.';ru='Вариант отчета не найден.';vi='Không tìm thấy phương án báo cáo.'"));
		Return;
	EndIf;
	
	FormVariant = Found[0];
	ReportSettings.Delete("SettingsFormExtendedMode");
	
	LoadVariant(FormVariant.VariantKey);
	
	UniqueKey = ReportsClientServer.UniqueKey(ReportSettings.FullName, FormVariant.VariantKey);
	
	If Items.FormImmediately.Check Then
		AttachIdleHandler("Generate", 0.1, True);
	EndIf;
EndProcedure

&AtClient
Procedure EditFiltersConditions(Command)
	FormParameters = New Structure;
	FormParameters.Insert("OwnerFormType", ReportFormType);
	FormParameters.Insert("ReportSettings", ReportSettings);
	FormParameters.Insert("SettingsComposer", Report.SettingsComposer);
	Handler = New NotifyDescription("EditFilterCriteriaCompletion", ThisObject);
	OpenForm("SettingsStorage.ReportsVariantsStorage.Form.ReportFiltersConditions", FormParameters, ThisObject, True,,, Handler);
EndProcedure

&AtClient
Procedure EditFilterCriteriaCompletion(FiltersConditions, Context) Export
	If FiltersConditions = Undefined
		Or FiltersConditions = DialogReturnCode.Cancel
		Or FiltersConditions.Count() = 0 Then
		Return;
	EndIf;
	FillingParameters = New Structure;
	FillingParameters.Insert("EventName", "EditFiltersConditions");
	FillingParameters.Insert("DCSettingsComposer", Report.SettingsComposer);
	FillingParameters.Insert("UserSettingsModified", True);
	FillingParameters.Insert("FiltersConditions", FiltersConditions);
	
	UpdateSettingsFormItems(FillingParameters);
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

////////////////////////////////////////////////////////////////////////////////
// Клиент

&AtClient
Procedure UpdateSettingsFormItems(UpdateParameters)
	UpdateSettingsFormItemsAtServer(UpdateParameters);
	
	If CommonUseClientServer.StructureProperty(UpdateParameters, "Regenerate", False) Then
		ClearMessages();
		Generate();
	EndIf;
EndProcedure

&AtClient
Procedure UpdateSettingsFormItemsDeferred()
	
	UpdateSettingsFormItems(ReportSettings.SettingsResult);
	ReportSettings.Delete("SettingsResult");
	
EndProcedure

#Region GenerationWithSendingByEmail

&AtClient
Procedure GenerateBeforeEmailing(Response, AdditionalParameters) Export
	If Response = DialogReturnCode.Yes Then
		Handler = New NotifyDescription("SendByEmailAfterGenerate", ThisObject);
		ReportsClient.GenerateReport(ThisObject, Handler);
	EndIf;
EndProcedure

&AtClient
Procedure SendByEmailAfterGenerate(SpreadsheetDocumentGenerated, AdditionalParameters) Export
	
	If SpreadsheetDocumentGenerated Then
		ShowSendByEmailDialog();
	EndIf;
	
EndProcedure

#EndRegion

#Region Generating

&AtClient
Procedure Generate()
	
	Result = FormingResultReport(GenerateOnOpening, ReportSettings.External Or ReportSettings.Safe);
	
	If Result = Undefined Then 
		Return;
	EndIf;
	
	If Result.Status <> "Running" Then 
		AfterGenerating(Result, False);
		Return;
	EndIf;
	
	Handler = New NotifyDescription("AfterGenerating", ThisObject, True);
	WaitingParameters = LongActionsClient.WaitingParameters(ThisObject);
	WaitingParameters.ShowWaitingWindow = False;
	
	LongActionsClient.WaitForCompletion(Result, Handler, WaitingParameters);
EndProcedure

&AtClient
Procedure AfterGenerating(Result, ImportReportGenerationResult) Export 
	If Result = Undefined Then 
		FormationErrorsShow(NStr("en='Report generation was interrupted by the administrator';ru='Формирование отчета прервано администратором';vi='Người quản trị đã ngắt quá trình tạo báo cáo'"));
		ShowUserNotification(NStr("en='Report not generated';ru='Отчет не сформирован';vi='Báo cáo chưa được lập'"),, Title);
	ElsIf Result.Status = "Completed" Then 
		If ImportReportGenerationResult Then
			ImportReportGenerationResult();
		EndIf;
		ShowUserNotification(NStr("en='Report not generated';ru='Отчет сформирован';vi='Báo cáo đã được lập'"),, Title);
	ElsIf Result.Status = "Error" Then
		FormationErrorsShow(Result.ShortErrorDescription);
		ShowUserNotification(NStr("en='Report not generated';ru='Отчет не сформирован';vi='Báo cáo chưa được lập'"),, Title);
	EndIf;
	
	GenerateOnOpening = False;
	
	ReportCreated = ?(Result = Undefined, False, Result.Status = "Completed");
	
	ReportsClientOverridable.AfterGenerating(ThisObject, ReportCreated);
	
	If ReportCreated Then
		If TypeOf(HandlerAfterGenerateAtClient) = Type("NotifyDescription") Then
			
			ExecuteNotifyProcessing(HandlerAfterGenerateAtClient, True);
			
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function FormingResultReport(Val GenerateOnOpening, Directly)
	
	If ValueIsFilled(BackgroundJobID) Then
		LongActions.CancelJobExecuting(BackgroundJobID);
		BackgroundJobID = Undefined;
	EndIf;
	
	If Not CheckFilling() Then
		If GenerateOnOpening Then
			ErrorText = "";
			Messages = GetUserMessages(True);
			For Each Message In Messages Do
				ErrorText = ErrorText + ?(ErrorText = "", "", ";" + Chars.LF + Chars.LF) + Message.Text;
			EndDo;
			FormationErrorsShow(ErrorText);
		EndIf;
		Return Undefined;
	EndIf;
	
	ReportName = StrSplit(ReportSettings.FullName, ".")[1];
	FormParameters = ReportGenerationParameters(ReportName, Directly);
	ExecuteParameters = LongActions.BackgroundExecutionParameters(UUID);
	ExecuteParameters.BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en='Report generating: %1';ru='Выполнение отчета: %1';vi='Thực hiện báo cáo: %1'"),
		ReportName);
	ExecuteParameters.RunNotInBackground = Directly;
	
	Result = LongActions.ExecuteInBackground(UUID,
		"ReportsVariants.GenerateReportInBackground",
		FormParameters,
		ExecuteParameters);
		
	BackgroundJobID = Result.JobID;
	BackgroundJobStorageAddress = Result.StorageAddress;
	
	If Result.Status <> "Running" Then
		ImportReportGenerationResult();
	Else	
		DisplayReportState(NStr("en='Report generating...';ru='Отчет формируется...';vi='Đang lập báo cáo…'"), PictureLib.LongOperation48);
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Function ReportGenerationParameters(ReportName, Directly)
	ReportGenerationParameters = New Structure;
	ReportGenerationParameters.Insert("RefOfReport", ReportSettings.ReportRef);
	ReportGenerationParameters.Insert("OptionRef", ReportSettings.VariantRef);
	ReportGenerationParameters.Insert("VariantKey", CurrentVariantKey);
	ReportGenerationParameters.Insert("DCSettings", Report.SettingsComposer.Settings);
	ReportGenerationParameters.Insert("FixedDCSettings", Report.SettingsComposer.FixedSettings);
	ReportGenerationParameters.Insert("DCUserSettings", Report.SettingsComposer.UserSettings);
	ReportGenerationParameters.Insert("SchemaModified", ReportSettings.SchemaModified);
	ReportGenerationParameters.Insert("SchemaKey", ReportSettings.SchemaKey);
	ReportGenerationParameters.Insert("KeyOperationName");
	ReportGenerationParameters.Insert("KeyOperationComment");
	
	If Directly Then
		If ReportSettings.SchemaModified Then
			ReportGenerationParameters.Insert("SchemaURL", ReportSettings.SchemaURL);
		EndIf;
		ReportGenerationParameters.Insert("Object", FormAttributeToValue("Report"));
		ReportGenerationParameters.Insert("FullName", ReportSettings.FullName);
	Else
		If ReportSettings.SchemaModified Then
			ReportGenerationParameters.Insert("DCSchema", GetFromTempStorage(ReportSettings.SchemaURL));
		EndIf;
	EndIf;
	
	Return ReportGenerationParameters;
EndFunction

&AtServer
Procedure ImportReportGenerationResult()
	
	If Not IsTempStorageURL(BackgroundJobStorageAddress) Then 
		FormationErrorsShow(NStr("en='Не удалось сформировать отчет';ru='Не удалось сформировать отчет';vi='Không thể lập báo cáo'"));
		Return;
	EndIf;
	
	Result = GetFromTempStorage(BackgroundJobStorageAddress);
	
	DeleteFromTempStorage(BackgroundJobStorageAddress);
	BackgroundJobStorageAddress = Undefined;
	BackgroundJobID = Undefined;
	
	If Result = Undefined Then 
		FormationErrorsShow(NStr("en='Не удалось сформировать отчет (пустой результат)';ru='Не удалось сформировать отчет (пустой результат)';vi='Không thể lập báo cáo (kết quả trống)'"));
		Return;
	EndIf;
	
	Success = CommonUseClientServer.StructureProperty(Result, "Success");
	If Success <> True Then
		FormationErrorsShow(Result.ErrorText);
		Return;
	EndIf;
	
	DataStillUpdating = CommonUseClientServer.StructureProperty(Result, "DataStillUpdating", False);
	If DataStillUpdating Then
		CommonUse.MessageToUser(ReportsVariants.DataIsBeingUpdatedMessage());
	EndIf;
	
	DisplayReportState();
	
	FillPropertyValues(ReportSettings.Print, ReportSpreadsheetDocument); // Сохранение настроек печати.
	ReportSpreadsheetDocument = Result.SpreadsheetDocument;
	FillPropertyValues(ReportSpreadsheetDocument, ReportSettings.Print); // Восстановление.
	
	If ValueIsFilled(ReportDetailsData) And IsTempStorageURL(ReportDetailsData) Then
		DeleteFromTempStorage(ReportDetailsData);
	EndIf;
	ReportDetailsData = PutToTempStorage(Result.Details, UUID);
	
	If Not Result.VariantModified
		And Not Result.UserSettingsModified Then
		Return;
	EndIf;
	
	Result.Insert("EventName", "AfterGenerating");
	Result.Insert("Directly", False);
	UpdateSettingsFormItemsAtServer(Result);
EndProcedure

#EndRegion

&AtClient
Procedure ShowSendByEmailDialog()
	
	DocumentsTable = New ValueList;
	DocumentsTable.Add(ThisObject.ReportSpreadsheetDocument, ThisObject.ReportCurrentVariantName);
	
	FormTitle = StrReplace(NStr("en='Send report ""%1"" by email';ru='Отправка отчета ""%1"" по почте';vi='Gửi báo cáo ""%1"" theo E-mail'"), "%1", ThisObject.ReportCurrentVariantName);
	
	FormParameters = New Structure;
	FormParameters.Insert("DocumentsTable", DocumentsTable);
	FormParameters.Insert("Subject",               ThisObject.ReportCurrentVariantName);
	FormParameters.Insert("Title",          FormTitle);
	
	OpenForm("CommonForm.SendingSpreadsheetDocumentsByEmail", FormParameters, , );

EndProcedure

&AtClient
Procedure ShowChoiceList(Item, StandardProcessing)
	StandardProcessing = False;
	
	Information = ReportsClient.SettingItemInfo(Report.SettingsComposer, Item.Name);
	SettingsDescription = Information.LongDesc;
	
	UserSettings = Report.SettingsComposer.UserSettings.Items;
	
	ChoiceParameters = ReportsClientServer.ChoiceParameters(
		Information.Settings, UserSettings, Information.Item);
	
	Item.AvailableTypes = ReportsClient.ValueTypeRestrictedByLinkByType(
		Information.Settings, UserSettings, Information.Item, SettingsDescription);
	
	If TypeOf(Information.UserSettingsItem) = Type("DataCompositionSettingsParameterValue") Then 
		CurrentValue = Information.UserSettingsItem.Value;
	Else
		CurrentValue = Information.UserSettingsItem.RightValue;
	EndIf;
	
	AvailableValues = ?(SettingsDescription = Undefined, Undefined, SettingsDescription.AvailableValues);
	
	Condition = ReportsClientServer.SettingItemCondition(Information.UserSettingsItem, SettingsDescription);
	ChoiceFoldersAndItems = ReportsClient.ValueOfFoldersAndItemsUseType(
		?(SettingsDescription = Undefined, Undefined, SettingsDescription.ChoiceFoldersAndItems), Condition);
	
	ValuesForSelection = ValuesForSelection(
		Item.ChoiceList,
		Information.UserSettingsItem.UserSettingID,
		Item.AvailableTypes);
	
	LimitChoiceWithSpecifiedValues = AvailableValues <> Undefined;
	
	OpenParameters = New Structure;
	OpenParameters.Insert("marked", ReportsClientServer.ValueList(CurrentValue));
	OpenParameters.Insert("TypeDescription", Item.AvailableTypes);
	OpenParameters.Insert("ValuesForSelection", ValuesForSelection);
	OpenParameters.Insert("ValuesForSelectionFilled", Item.ChoiceList.Count() > 0);
	OpenParameters.Insert("LimitChoiceWithSpecifiedValues", LimitChoiceWithSpecifiedValues);
	OpenParameters.Insert("Presentation", Item.Title);
	OpenParameters.Insert("ChoiceParameters", New Array(ChoiceParameters));
	OpenParameters.Insert("ChoiceFoldersAndItems", ChoiceFoldersAndItems);
	OpenParameters.Insert("QuickChoice", ?(SettingsDescription = Undefined, False, SettingsDescription.QuickChoice));
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("UserSettingsItem", Information.UserSettingsItem);
	HandlerParameters.Insert("LimitChoiceWithSpecifiedValues", LimitChoiceWithSpecifiedValues);
	HandlerParameters.Insert("ItemName", Item.Name);
	
	Handler = New NotifyDescription("CompleteChoiceFromList", ThisObject, HandlerParameters);
	Mode = FormWindowOpeningMode.LockOwnerWindow;
	
	OpenForm("CommonForm.EnterValuesListWithCheckBoxes", OpenParameters, ThisObject,,,, Handler, Mode);
EndProcedure

&AtClient
Function ValuesForSelection(ChoiceList, UserSettingID, ValueType)
	ValuesForSelection = ChoiceList;
	If Not ValueIsFilled(UserSettingID) Then 
		Return ValuesForSelection;
	EndIf;
	
	ValuesForSelection.ValueType = ValueType;
	
	FiltersValuesCache = CommonUseClientServer.StructureProperty(
		Report.SettingsComposer.UserSettings.AdditionalProperties, "FiltersValuesCache");
	If FiltersValuesCache = Undefined Then 
		Return ValuesForSelection;
	EndIf;
	
	FilterValue = FiltersValuesCache.Get(UserSettingID);
	If FilterValue <> Undefined Then 
		ReportsClientServer.ExpandList(ValuesForSelection, FilterValue);
	EndIf;
	
	Return ValuesForSelection;
EndFunction

&AtClient
Procedure CompleteChoiceFromList(List, ChoiceParameters) Export
	If TypeOf(List) <> Type("ValueList") Then
		Return;
	EndIf;
	
	SelectedValues = New ValueList;
	For Each ListElement In List Do 
		If ListElement.Check Then 
			FillPropertyValues(SelectedValues.Add(), ListElement);
		EndIf;
	EndDo;
	
	UserSettingsItem = ChoiceParameters.UserSettingsItem;
	UserSettingsItem.Use = True;
	
	If TypeOf(UserSettingsItem) = Type("DataCompositionSettingsParameterValue") Then 
		UserSettingsItem.Value = SelectedValues;
	Else
		UserSettingsItem.RightValue = SelectedValues;
	EndIf;
	
	If Not ChoiceParameters.LimitChoiceWithSpecifiedValues Then 
		Item = Items.Find(ChoiceParameters.TagName);
		
		If Item <> Undefined Then 
			Item.ChoiceList.Clear();
			
			For Each ListElement In List Do 
				FillPropertyValues(Item.ChoiceList.Add(), ListElement);
			EndDo;
		EndIf;
	EndIf;
	
	ReportsClient.CacheFilterValue(
		List, UserSettingsItem.UserSettingID, Report.SettingsComposer);
EndProcedure

&AtClient
Function NavigateToLink(RefAddress)
	
	If IsBlankString(RefAddress) Then
		Return False;
	EndIf;
	
	ReferenceAddressInReg = Upper(RefAddress);
	Return False;
	
EndFunction

&AtClient
Procedure ImportSchemaAfterLocateFile(SelectedFiles, AdditionalParameters) Export
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	BinaryData = GetFromTempStorage(SelectedFiles.Location);
	
	AdditionalProperties = Report.SettingsComposer.Settings.AdditionalProperties;
	AdditionalProperties.Clear();
	AdditionalProperties.Insert("DataCompositionSchema", BinaryData);
	AdditionalProperties.Insert("ReportInitialized", False);
	
	FillingParameters = New Structure;
	FillingParameters.Insert("UserSettingsModified", True);
	FillingParameters.Insert("DCSettingsComposer", Report.SettingsComposer);
	
	UpdateSettingsFormItems(FillingParameters);
EndProcedure

&AtClient
Procedure ApplyPassedSettings(SettingsDescription)
	If VariantModified Then 
		ShowMessageBox(, NStr("en='Вариант отчета был изменен."
"Сохраните изменения перед применением настроек.';ru='Вариант отчета был изменен."
"Сохраните изменения перед применением настроек.';vi='Đã thay đổi phương án báo cáo."
"Hãy lưu lại những thay đổi trước khi áp dụng tùy chỉnh.'"));
		Return;
	EndIf;
	
	CurrentUserSettingsKey = SettingsDescription.SettingsKey;
	CurrentUserSettingsPresentation = SettingsDescription.Presentation;
	
	Report.SettingsComposer.LoadUserSettings(SettingsDescription.Settings);
	Generate();
EndProcedure

// Выполняет расчет и вывод показателей выделенной области ячеек.
// See обработчик события ОтчетТабличныйДокументПриАктивизацииОбласти.
//
&AtClient
Procedure CalculateIndicatorsDynamically()
	CommonInternalClient.CalculateIndicators(ThisObject, "ReportSpreadsheetDocument");
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Вызов сервера

&AtServer
Procedure SetVisibleEnabled(OnSaveOption = False)
	ShowOptionsSelectionCommands = ReportVariantMode() And ReportSettings.OptionSelectionAllowed;
	
	If Not OnSaveOption Then
		ShowOptionChangingCommands = ShowOptionsSelectionCommands And ReportSettings.EditOptionsAllowed;
		SelectAndEditOptionsWithoutSavingAllowed = CommonUseClientServer.StructureProperty(
			ReportSettings, "SelectAndEditOptionsWithoutSavingAllowed", False);
		CountOfAvailableSettings = ReportsServer.CountOfAvailableSettings(Report.SettingsComposer);
		
		Items.AllSettings.Visible = ShowOptionChangingCommands Or CountOfAvailableSettings.Typical > 0;
		Items.MoreCommandBarAllSettings.Visible = Items.AllSettings.Visible;
		
		SaveOptionAllowed = ShowOptionChangingCommands
			And Not SelectAndEditOptionsWithoutSavingAllowed;
		CommonUseClientServer.SetFormItemProperty(
			Items, "SaveVariant", "Visible", SaveOptionAllowed);
		CommonUseClientServer.SetFormItemProperty(
			Items, "SaveOptionMore", "Visible", SaveOptionAllowed);
		
		Items.OtherReports.Visible = ReportSettings.Subsystem <> Undefined
			And ReportSettings.OptionSelectionAllowed;
		
		UseSettingsAllowed =
			ShowOptionsSelectionCommands
			And CountOfAvailableSettings.Total > 0 ;
		
		If SelectAndEditOptionsWithoutSavingAllowed Then
			VariantModified = False;
		EndIf;
	EndIf;
	
	// Команды выбора вариантов.
	If PanelVariantsCurrentVariantKey <> CurrentVariantKey Then
		PanelVariantsCurrentVariantKey = CurrentVariantKey;
		
		If ShowOptionsSelectionCommands Then
			UpdateOptionsSelectionCommands();
		EndIf;
		
		If OutputRight Then
			WindowOptionsKey = ReportsClientServer.UniqueKey(ReportSettings.FullName, CurrentVariantKey);
			ReportSettings.Print.Insert("PrintParametersKey", WindowOptionsKey);
			FillPropertyValues(ReportSpreadsheetDocument, ReportSettings.Print);
		EndIf;
		
		URL = "";
		If ValueIsFilled(ReportSettings.VariantRef)
			And Not ReportSettings.External
			And Not ReportSettings.Contextual Then
			URL = GetURL(ReportSettings.VariantRef);
		EndIf;
	EndIf;
		
	// Заголовок.
	ReportCurrentVariantName = TrimAll(ReportCurrentVariantName);
	If ValueIsFilled(ReportCurrentVariantName) Then
		Title = ReportCurrentVariantName;
	Else
		Title = ReportSettings.Description;
	EndIf;
	
	If EncryptingMode Then
		Title = Title + " (" + NStr("en='Details';ru='Расшифровка';vi='Giải mã'") + ")";
	EndIf;
EndProcedure

&AtServer
Procedure LoadVariant(VariantKey)
	If Not EncryptingMode And Not VariantModified Then
		// Сохранение текущих пользовательских настроек.
		CommonUse.SystemSettingsStorageSave(
			ReportSettings.FullName + "/" + CurrentVariantKey + "/CurrentUserSettings",
			"",
			Report.SettingsComposer.UserSettings);
	EndIf;
	
	EncryptingMode = False;
	VariantModified = False;
	UserSettingsModified = False;
	ReportSettings.ReadCheckBoxGenerateImmediatelyFromUserSettings = True;
	
	SetCurrentVariant(VariantKey);
	DisplayReportState(NStr("en='Выбран другой вариант отчета. Нажмите ""Сформировать"" для получения отчета.';ru='Выбран другой вариант отчета. Нажмите ""Сформировать"" для получения отчета.';vi='Đã chọn phương án báo cáo khác. Hãy nhấn ""Lập báo cáo"" để nhận báo cáo.'"),
		PictureLib.Information32);
EndProcedure

&AtServer
Procedure DisplayReportState(Val StatusText = "", Val StatePicture = Undefined)
	
	ShowStatus = Not IsBlankString(StatusText);
	If StatePicture = Undefined Or Not ShowStatus Then 
		StatePicture = New Picture;
	EndIf;
	
	StatePresentation = Items.ReportSpreadsheetDocument.StatePresentation;
	StatePresentation.Visible = ShowStatus;
	StatePresentation.AdditionalShowMode = 
		?(ShowStatus, AdditionalShowMode.Irrelevance, AdditionalShowMode.DontUse);
	StatePresentation.Picture = StatePicture;
	StatePresentation.Text = StatusText;

	Items.ReportSpreadsheetDocument.ReadOnly = ShowStatus 
		Or Items.ReportSpreadsheetDocument.Output = UseOutput.Disable;
		
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Сервер

&AtServer
Procedure DefineBehaviorInMobileClient()
	If Not CommonUse.IsMobileClient() Then 
		Return;
	EndIf;
	
	Items.CommandsAndIndicators.Title = NStr("en='показатели';ru='показатели';vi='chỉ số'");
	Items.GroupReportSettings.Visible = False;
	Items.WorkInTableGroup.Visible = False;
	Items.OutputGroup.Visible = False;
	Items.Edit.Visible = False;
	
	Items.IndicatorGroup.HorizontalStretch = Undefined;
	Items.Indicator.Width = 0;
EndProcedure

&AtServer
Procedure SetCurrentOptionKey(ReportFullName, PredefinedVariants)
	PanelVariantsCurrentVariantKey = BlankOptionKey();
	
	If ValueIsFilled(Parameters.VariantKey) Then
		CurrentVariantKey = Parameters.VariantKey;
	Else
		If Parameters.Property("CommandParameter")
			And CommonUse.ReferenceTypeValue(Parameters.CommandParameter) Then 
			
			OwnerFullName = Parameters.CommandParameter.Metadata().FullName();
			ObjectKey = ReportFullName + "/" + OwnerFullName + "/CurrentVariantKey";
		Else
			ObjectKey = ReportFullName + "/CurrentVariantKey";
		EndIf;
		
		CurrentVariantKey = CommonUse.SystemSettingsStorageImport(ObjectKey, "");
	EndIf;
	
	If Not ValueIsFilled(CurrentVariantKey)
		And PredefinedVariants.Count() > 0 Then
		
		CurrentVariantKey = PredefinedVariants[0].Value;
	EndIf;
EndProcedure

&AtServer
Procedure UpdateSettingsFormItemsAtServer(UpdateParameters = Undefined)
	ImportSettingsToComposer(UpdateParameters);
	
	ReportsServer.UpdateSettingsFormItems(
		ThisObject, Items.SettingsComposerUserSettings, UpdateParameters);
	
	If UpdateParameters.EventName <> "AfterGenerating" Then
		Regenerate = CommonUseClientServer.StructureProperty(UpdateParameters, "Regenerate", False);
		
		If Regenerate
			And Not CheckFilling() Then 
			
			UpdateParameters.Regenerate = False;
			
		ElsIf Regenerate Then
			
			DisplayReportState(NStr("en='Report generating...';ru='Отчет формируется...';vi='Đang lập báo cáo…'"), PictureLib.LongOperation48);
			
		ElsIf UpdateParameters.VariantModified
			Or UpdateParameters.UserSettingsModified Then
			
			DisplayReportState(NStr("en='Settings are changed. Press ""Generate"" to generate report.';ru='Изменились настройки. Нажмите ""Сформировать"" для получения отчета.';vi='Đã thay đổi tùy chỉnh. Hãy nhấn vào nút ""Lập báo cáo"" để nhận báo cáo.'"));
		EndIf;
	EndIf;
	
	// Стандартный диалог не показывается если пользователю запрещено изменять варианты этого отчета.
	If Not ReportSettings.EditOptionsAllowed Then
		VariantModified = False;
	EndIf;
	
	ReportsServer.RestoreFiltersValues(ThisObject);
	
	SetVisibleEnabled();
EndProcedure

&AtServer
Procedure ImportSettingsToComposer(ImportParameters)
	CheckImportParameters(ImportParameters);
	
	ReportObject = FormAttributeToValue("Report");
	If ReportSettings.Events.BeforeFillingQuickSettingsPanel Then
		ReportObject.BeforeFillingQuickSettingsPanel(ThisObject, ImportParameters);
	EndIf;
	
	AvailableSettings = ReportsServer.AvailableSettings(ImportParameters, ReportSettings);
	
	ClearOptionSettings = CommonUseClientServer.StructureProperty(
		ImportParameters, "ClearOptionSettings", False);
	If ClearOptionSettings Then
		LoadVariant(CurrentVariantKey);
	EndIf;
	
	ReportsServer.ResetUserSettings(AvailableSettings, ImportParameters);
	
	If ReportSettings.Events.BeforeImportSettingsToComposer Then 
		ReportObject.BeforeImportSettingsToComposer(
			ThisObject,
			ReportSettings.SchemaKey,
			CurrentVariantKey,
			AvailableSettings.Settings,
			AvailableSettings.UserSettings);
	EndIf;
	
	SettingsImported = ReportsClientServer.LoadSettings(
		Report.SettingsComposer,
		AvailableSettings.Settings,
		AvailableSettings.UserSettings,
		AvailableSettings.FixedSettings);
	
	// Установка фиксированных отборов выполняется через компоновщик, т.к. в нем наиболее полная коллекция настроек.
	// В ПередЗагрузкой в параметрах могут отсутствовать те параметры, настройки которые не переопределялись.
	If SettingsImported And TypeOf(ParametersForm.Filter) = Type("Structure") Then
		ReportsServer.SetFixedFilters(ParametersForm.Filter, Report.SettingsComposer.Settings, ReportSettings);
	EndIf;
	
	If ParametersForm.Property("FixedSettings") Then 
		ParametersForm.FixedSettings = Report.SettingsComposer.FixedSettings;
	EndIf;
	
	ReportsServer.SetAvailableValues(ReportObject, ThisObject);
	ReportsServer.InitializePredefinedOutputParameters(ReportSettings, Report.SettingsComposer.Settings);
	
	AdditionalProperties = Report.SettingsComposer.Settings.AdditionalProperties;
	AdditionalProperties.Insert("VariantKey", CurrentVariantKey);
	AdditionalProperties.Insert("OptionName", ReportCurrentVariantName);
	
	// Подготовка к предварительной инициализации компоновщика (используется при расшифровке).
	If ReportSettings.SchemaModified Then
		AdditionalProperties.Insert("SchemaURL", ReportSettings.SchemaURL);
	EndIf;
	
	If ImportParameters.Property("SettingsFormExtendedMode") Then
		ReportSettings.Insert("SettingsFormExtendedMode", ImportParameters.SettingsFormExtendedMode);
	EndIf;
	
	If ImportParameters.Property("SettingsFormPageName") Then
		ReportSettings.Insert("SettingsFormPageName", ImportParameters.SettingsFormPageName);
	EndIf;
	
	SetFiltersConditions(ImportParameters);
	
	If ImportParameters.VariantModified Then
		VariantModified = True;
	EndIf;
	
	If ImportParameters.UserSettingsModified Then
		UserSettingsModified = True;
	EndIf;
	
	If ReportSettings.ReadCheckBoxGenerateImmediatelyFromUserSettings Then
		ReportSettings.ReadCheckBoxGenerateImmediatelyFromUserSettings = False;
		Items.FormImmediately.Check = CommonUseClientServer.StructureProperty(
			AdditionalProperties,
			"FormImmediately",
			ReportSettings.FormImmediately);
	EndIf;
EndProcedure

&AtServer
Procedure CheckImportParameters(ImportParameters)
	If TypeOf(ImportParameters) <> Type("Structure") Then 
		ImportParameters = New Structure;
	EndIf;
	
	If Not ImportParameters.Property("EventName") Then
		ImportParameters.Insert("EventName", "");
	EndIf;
	
	If Not ImportParameters.Property("VariantModified") Then
		ImportParameters.Insert("VariantModified", VariantModified);
	EndIf;
	
	If Not ImportParameters.Property("UserSettingsModified") Then
		ImportParameters.Insert("UserSettingsModified", UserSettingsModified);
	EndIf;
	
	If Not ImportParameters.Property("Result") Then
		ImportParameters.Insert("Result", New Structure);
	EndIf;
	
	ImportParameters.Insert("ReportObjectOrFullName", ReportSettings.FullName);
EndProcedure

&AtServer
Procedure SetFiltersConditions(ImportParameters)
	FiltersConditions = CommonUseClientServer.StructureProperty(ImportParameters, "FiltersConditions");
	If FiltersConditions = Undefined Then
		Return;
	EndIf;
	
	Settings = Report.SettingsComposer.Settings;
	UserSettings = Report.SettingsComposer.UserSettings;
	
	For Each Condition In FiltersConditions Do
		UserSettingsItem = UserSettings.GetObjectByID(Condition.Key);
		UserSettingsItem.ComparisonType = Condition.Value;
		
		If ReportsClientServer.IsListComparisonKind(UserSettingsItem.ComparisonType)
			And TypeOf(UserSettingsItem.RightValue) <> Type("ValueList") Then 
			
			UserSettingsItem.RightValue = ReportsClientServer.ValueList(
				UserSettingsItem.RightValue);
		EndIf;
		
		SettingItem = ReportsClientServer.GetObjectByUserIdentifier(
			Settings, UserSettingsItem.UserSettingID,, UserSettings);
		
		FillPropertyValues(SettingItem, UserSettingsItem, "ComparisonType, RightValue");
	EndDo;
EndProcedure

&AtServer
Procedure FormationErrorsShow(ErrorInfo)
	If TypeOf(ErrorInfo) = Type("ErrorInfo") Then
		ErrorDescription = BriefErrorDescription(ErrorInfo);
		DetailErrorDescription = NStr("en='Ошибка при формировании:';ru='Ошибка при формировании:';vi='Lỗi khi lập báo cáo:'") + Chars.LF + DetailErrorDescription(ErrorInfo);
		If IsBlankString(ErrorDescription) Then
			ErrorDescription = DetailErrorDescription;
		EndIf;
	Else
		ErrorDescription = ErrorInfo;
		DetailErrorDescription = "";
	EndIf;
	
	DisplayReportState(ErrorDescription);
	If Not IsBlankString(DetailErrorDescription) Then
		ReportsVariants.WriteInJournal(EventLogLevel.Warning, DetailErrorDescription, ReportSettings.VariantRef);
	EndIf;
EndProcedure

&AtServer
Procedure UpdateOptionsSelectionCommands()
	
	FormOptions = FormAttributeToValue("AddedVariants");
	FormOptions.Columns.Add("Found", New TypeDescription("Boolean"));
	
	SearchParameters = New Structure;
	SearchParameters.Insert("Reports", ReportsClientServer.ValueInArray(ReportSettings.ReportRef));
	SearchParameters.Insert("DeletionMark", False);
	SearchParameters.Insert("ReceiveSummaryTable", True);
	
	SearchResult = ReportsVariants.FindReferences(SearchParameters);
	
	VariantTable = SearchResult.ValueTable;
	If ReportSettings.External Then // Add predefined options of the external report to the options table.
		For Each ItemOfList In ReportSettings.PredefinedVariants Do
			TableRow = VariantTable.Add();
			TableRow.Description = ItemOfList.Presentation;
			TableRow.VariantKey = ItemOfList.Value;
		EndDo;
	EndIf;
	VariantTable.GroupBy("Ref, VariantKey, Description");
	VariantTable.Sort("Description Asc, VariantKey Asc");
	
	GroupVar = Items.ReportOptionsGroup;
	GroupButtons = GroupVar.ChildItems;
	
	LastIndex = FormOptions.Count() - 1;
	For Each TableRow In VariantTable Do
		Found = FormOptions.FindRows(New Structure("VariantKey, Found", TableRow.VariantKey, False));
		If Found.Count() = 1 Then
			FormVariant = Found[0];
			FormVariant.found = True;
			Button = Items.Find(FormVariant.CommandName);
			Button.Visible = True;
			Button.Title = TableRow.Description;
			Items.Move(Button, GroupVar);
		Else
			LastIndex = LastIndex + 1;
			FormVariant = FormOptions.Add();
			FillPropertyValues(FormVariant, TableRow);
			FormVariant.found = True;
			FormVariant.CommandName = "ChooseVariant_" + Format(LastIndex, "NZ=0; NG=");
			
			Command = Commands.Add(FormVariant.CommandName);
			Command.Action = "Attachable_LoadReportVariant";
			
			Button = Items.Add(FormVariant.CommandName, Type("FormButton"), GroupVar);
			Button.Type = FormButtonType.CommandBarButton;
			Button.CommandName = FormVariant.CommandName;
			Button.Title = TableRow.Description;
			
			ConstantCommands.Add(FormVariant.CommandName);
		EndIf;
		Button.Check = (ReportSettings.VariantRef = FormVariant.Ref);
	EndDo;
	
	Found = FormOptions.FindRows(New Structure("Found", False));
	For Each FormVariant In Found Do
		Button = Items.Find(FormVariant.CommandName);
		Button.Visible = False;
	EndDo;
	
	FormOptions.Columns.Delete("Found");
	ValueToFormAttribute(FormOptions, "AddedVariants");
	
EndProcedure

&AtServer
Procedure UpdateInfoOnReportOption()
	
	AdditionalProperties = Report.SettingsComposer.Settings.AdditionalProperties;
	AdditionalProperties.Insert("VariantKey", CurrentVariantKey);
	AdditionalProperties.Insert("OptionName", ReportCurrentVariantName);
	
	ReportSettings.Insert("VariantRef", Undefined);
	ReportSettings.Insert("MeasurementsKey", Undefined);
	ReportSettings.Insert("PredefinedRef", Undefined);
	ReportSettings.Insert("OriginalOptionName", Undefined);
	ReportSettings.Insert("User", False);
	ReportSettings.Insert("ReportType", Undefined);
	
	Query = New Query("
	|SELECT ALLOWED TOP 1
	|	ReportsVariants.Ref AS VariantRef,
	|	"""" AS MeasurementsKey,
	|	ReportsVariants.PredefinedVariant AS PredefinedRef,
	|	CASE
	|		WHEN ReportsVariants.User
	|			OR ReportsVariants.Parent.VariantKey IS NULL 
	|		THEN ReportsVariants.VariantKey
	|		ELSE ReportsVariants.Parent.VariantKey
	|	END AS OriginalOptionName,
	|	ReportsVariants.User AS User,
	|	ReportsVariants.ReportType
	|FROM
	|	Catalog.ReportsVariants AS ReportsVariants
	|WHERE
	|	ReportsVariants.Report = &Report
	|	AND ReportsVariants.VariantKey = &VariantKey
	|");
	Query.SetParameter("Report", ReportSettings.ReportRef);
	Query.SetParameter("VariantKey", CurrentVariantKey);
	
	Selection = Query.Execute().Select();
	If Not Selection.Next() Then
		Return;
	EndIf;
	
	MeasurementsKey = Selection.MeasurementsKey;
	If Not ValueIsFilled(MeasurementsKey) Then 
		MeasurementsKey = CommonUse.TrimStringUsingChecksum(
			ReportSettings.FullName + "." + CurrentVariantKey, 135);
	EndIf;
	
	FillPropertyValues(ReportSettings, Selection);
	
	ReportSettings.MeasurementsKey = MeasurementsKey;
	ReportSettings.OriginalOptionName = ?(Selection.User, Selection.OriginalOptionName, CurrentVariantKey);
	
EndProcedure

&AtServer
Function ReportVariantMode()
	Return TypeOf(CurrentVariantKey) = Type("String") And Not IsBlankString(CurrentVariantKey);
EndFunction

&AtClientAtServerNoContext
Function BlankOptionKey()
	Return " - ";
EndFunction

#EndRegion