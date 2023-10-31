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

// Задать настройки формы отчета.
//
// Parameters:
//   Form - ClientApplicationForm, Undefined - 
//   VariantKey - String, Undefined - 
//   Settings - See ReportsClientServer.DefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.BeforeLoadVariantAtServer = True;
	Settings.Events.BeforeImportSettingsToComposer = True;
	Settings.Events.OnDefineSelectionParameters = True;
	Settings.Events.OnDefineSettingsFormItemsProperties = True;
	
	Settings.ImportSchemaAllowed = True;
	Settings.EditSchemaAllowed = True;
	Settings.RestoreStandardSchemaAllowed = True;
	
	Settings.ImportSettingsOnChangeParameters = Reports.UniversalReport.ImportSettingsOnChangeParameters();
EndProcedure

// See ReportsOverridable.OnCreateAtServer.
//
// Parameters:
//  Form - ClientApplicationForm - 
//  cancel - Boolean - 
//  StandardProcessing - Boolean - 
//
Procedure OnCreateAtServer(Form, cancel, StandardProcessing) Export
	EditOptionsAllowed = CommonUseClientServer.StructureProperty(
		Form.ReportSettings, "EditOptionsAllowed", False);
	
	If EditOptionsAllowed Then
		Form.ReportSettings.Insert("SettingsFormExtendedMode", 1);
	EndIf;
	
	CommonUseClientServer.SetFormItemProperty(Form.Items, "ChooseSettings", "Visible", False);
	CommonUseClientServer.SetFormItemProperty(Form.Items, "SaveSettings", "Visible", False);
	CommonUseClientServer.SetFormItemProperty(Form.Items, "ShareSettings", "Visible", False);
EndProcedure

// See ReportsOverridable.OnDefineSelectionParameters.
Procedure OnDefineSelectionParameters(Form, SettingProperty) Export
	AvailableValues = CommonUseClientServer.StructureProperty(
		SettingsComposer.Settings.AdditionalProperties, "AvailableValues", New Structure);
	
	Try
		ValuesForSelection = CommonUseClientServer.StructureProperty(
			AvailableValues, StrReplace(SettingProperty.DCField, "DataParameters.", ""));
	Except
		ValuesForSelection = Undefined;
	EndTry;
	
	If ValuesForSelection <> Undefined Then 
		SettingProperty.LimitChoiceWithSpecifiedValues = True;
		SettingProperty.ValuesForSelection = ValuesForSelection;
	EndIf;
EndProcedure

// Called in the handler of the report form eponymous event after execution of the form code.
// See "Расширение управляемой формы для отчета.ПередЗагрузкойВариантаНаСервере" в синтакс-помощнике.
//
// Parameters:
//   Form - ClientApplicationForm - Форма отчета.
//   Settings - DataCompositionSettings - Настройки для загрузки в компоновщик настроек.
//
Procedure BeforeLoadVariantAtServer(Form, Settings) Export
	CurrentSchemaKey = Undefined;
	Scheme = Undefined;
	
	IsImportedSchema = False;
	
	If TypeOf(Settings) = Type("DataCompositionSettings") Or Settings = Undefined Then
		If Settings = Undefined Then
			AdditionalSettingsProperties = SettingsComposer.Settings.AdditionalProperties;
		Else
			AdditionalSettingsProperties = Settings.AdditionalProperties;
		EndIf;
		
		If Form.ReportFormType = ReportFormType.Main
			And (Form.EncryptingMode
			Or (Form.CurrentVariantKey <> "Main"
			And Form.CurrentVariantKey <> "Main")) Then 
			
			AdditionalSettingsProperties.Insert("ReportInitialized", True);
		EndIf;
		
		SchemaBinaryData = CommonUseClientServer.StructureProperty(
			AdditionalSettingsProperties, "DataCompositionSchema");
		
		If TypeOf(SchemaBinaryData) = Type("BinaryData") Then
			IsImportedSchema = True;
			CurrentSchemaKey = BinaryDataHash(SchemaBinaryData);
			Scheme = Reports.UniversalReport.ExtractSchemaFromBinaryData(SchemaBinaryData);
		EndIf;
	EndIf;
	
	If IsImportedSchema Then
		SchemaKey = CurrentSchemaKey;
		ReportsServer.AttachSchema(ThisObject, Form, Scheme, SchemaKey);
	EndIf;
EndProcedure

// Вызывается перед загрузкой новых настроек. Используется для изменения схемы компоновки.
//   Например, если схема отчета зависит от ключа варианта или параметров отчета.
//   Чтобы изменения схемы вступили в силу следует вызывать метод ОтчетыСервер.ПодключитьСхему().
//
// Parameters:
//   Context - Arbitrary - 
//       Параметры контекста, в котором используется отчет.
//       Используется для передачи в параметрах метода ОтчетыСервер.ПодключитьСхему().
//   SchemaKey - String -
//       Идентификатор текущей схемы компоновщика настроек.
//       По умолчанию не заполнен (это означает что компоновщик инициализирован на основании основной схемы).
//       Используется для оптимизации, чтобы переинициализировать компоновщик как можно реже).
//       Может не использоваться если переинициализация выполняется безусловно.
//   VariantKey - String, Undefined -
//       Name of the predefined one or unique identifier of user report variant.
//       Неопределено когда вызов для варианта расшифровки или без контекста.
//   Settings - DataCompositionSettings, Undefined -
//       Настройки варианта отчета, которые будут загружены в компоновщик настроек после его инициализации.
//       Неопределено когда настройки варианта не надо загружать (уже загружены ранее).
//   UserSettings - DataCompositionUserSettings, Undefined -
//       Пользовательские настройки, которые будут загружены в компоновщик настроек после его инициализации.
//       Неопределено когда пользовательские настройки не надо загружать (уже загружены ранее).
//
// Example:
//  // Компоновщик отчета инициализируется на основании схемы из общих макетов:
//	Если КлючСхемы <> "1" Тогда
//		КлючСхемы = "1";
//		СхемаКД = ПолучитьОбщийМакет("МояОбщаяСхемаКомпоновки");
//		ОтчетыСервер.ПодключитьСхему(ЭтотОбъект, Контекст, СхемаКД, КлючСхемы);
//	EndIf;
//
//  // Схема зависит от значения параметра, выведенного в пользовательские настройки отчета:
//	Если ТипЗнч(НовыеПользовательскиеНастройкиКД) = Тип("ПользовательскиеНастройкиКомпоновкиДанных") Тогда
//		ИмяОбъектаМетаданных = "";
//		Для Каждого ЭлементКД Из НовыеПользовательскиеНастройкиКД.Элементы Цикл
//			Если ТипЗнч(ЭлементКД) = Тип("ЗначениеПараметраНастроекКомпоновкиДанных") Тогда
//				ИмяПараметра = Строка(ЭлементКД.Параметр);
//				Если ИмяПараметра = "ОбъектМетаданных" Тогда
//					ИмяОбъектаМетаданных = ЭлементКД.Значение;
//				EndIf;
//			EndIf;
//		EndDo;
//		Если КлючСхемы <> ИмяОбъектаМетаданных Тогда
//			КлючСхемы = ИмяОбъектаМетаданных;
//			СхемаКД = Новый СхемаКомпоновкиДанных;
//			// Наполнение схемы...
//			ОтчетыСервер.ПодключитьСхему(ЭтотОбъект, Контекст, СхемаКД, КлючСхемы);
//		EndIf;
//	EndIf;
//
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, Settings, UserSettings) Export
	CurrentSchemaKey = Undefined;
	
	If Settings = Undefined Then 
		Settings = SettingsComposer.Settings;
	EndIf;
	
	IsImportedSchema = False;
	SchemaBinaryData = CommonUseClientServer.StructureProperty(
		Settings.AdditionalProperties, "DataCompositionSchema");
	
	If TypeOf(SchemaBinaryData) = Type("BinaryData") Then
		CurrentSchemaKey = BinaryDataHash(SchemaBinaryData);
		If CurrentSchemaKey <> SchemaKey Then
			Scheme = Reports.UniversalReport.ExtractSchemaFromBinaryData(SchemaBinaryData);
			IsImportedSchema = True;
		EndIf;
	EndIf;
	
	AvailableValues = Undefined;
	FixedParameters = Reports.UniversalReport.FixedParameters(
		Settings, UserSettings, AvailableValues);
	
	If CurrentSchemaKey = Undefined Then 
		CurrentSchemaKey = FixedParameters.MetadataObjectType
			+ "/" + FixedParameters.MetadataObjectName
			+ "/" + FixedParameters.TableName;
		CurrentSchemaKey = CommonUse.TrimStringUsingChecksum(CurrentSchemaKey, 100);
		
		If CurrentSchemaKey <> SchemaKey Then
			SchemaKey = "";
			Scheme = Reports.UniversalReport.DataCompositionSchema(FixedParameters);
		EndIf;
	EndIf;
	
	If CurrentSchemaKey <> Undefined And CurrentSchemaKey <> SchemaKey Then
		SchemaKey = CurrentSchemaKey;
		ReportsServer.AttachSchema(ThisObject, Context, Scheme, SchemaKey);
		
		If IsImportedSchema Then
			Reports.UniversalReport.SetStandardImportedSchemaSettings(
				ThisObject, SchemaBinaryData, Settings, UserSettings);
		Else
			Reports.UniversalReport.SetStandardSettings(
				ThisObject, FixedParameters, Settings, UserSettings);
		EndIf;
		
		If TypeOf(Context) = Type("ClientApplicationForm") Then
			// Переопределение.
			// SSLSubsystemsIntegration.BeforeLoadVariantAtServer(Context, Settings);
			ReportsOverridable.BeforeLoadVariantAtServer(Context, Settings);
			BeforeLoadVariantAtServer(Context, Settings);
		EndIf;
	Else
		Reports.UniversalReport.SetFixedParameters(
			ThisObject, FixedParameters, Settings, UserSettings);
	EndIf;
	
	SettingsComposer.Settings.AdditionalProperties.Insert("AvailableValues", AvailableValues);
EndProcedure

// Вызывается после определения свойств элементов формы, связанных с пользовательскими настройками.
// See ReportsServer.СвойстваЭлементовФормыНастроек()
// Позволяет переопределить свойства, для целей персонализации отчета.
//
// Parameters:
//  FormType - ReportFormType - See Синтакс-помощник
//  ItemsProperties - See ReportsServer.СвойстваЭлементовФормыНастроек()
//  UserSettings - DataCompositionUserSettingsItemCollection - элементы актуальных
//                              пользовательских настроек, влияющих на создание связанных элементов формы.
//
Procedure OnDefineSettingsFormItemsProperties(FormType, ItemsProperties, UserSettings) Export 
	If FormType <> ReportFormType.Main Then 
		Return;
	EndIf;
	
	GroupProperties = ReportsServer.FormItemsGroupProperties();
	GroupProperties.Group= ChildFormItemsGroup.AlwaysHorizontal;
	ItemsProperties.Groups.Insert("FixedParameters", GroupProperties);
	
	FixedParameters = New Structure("Period, MetadataObjectType, MetadataObjectName, TableName");
	MarginWidth = New Structure("MetadataObjectType, MetadataObjectName, TableName", 20, 35, 20);
	
	For Each SettingItem In UserSettings Do 
		If TypeOf(SettingItem) <> Type("DataCompositionSettingsParameterValue")
			Or Not FixedParameters.Property(SettingItem.Parameter) Then 
			Continue;
		EndIf;
		
		FieldProperties = ItemsProperties.Fields.Find(
			SettingItem.UserSettingID, "SettingID");
		
		If FieldProperties = Undefined Then 
			Continue;
		EndIf;
		
		FieldProperties.GroupID = "FixedParameters";
		
		ParameterName = String(SettingItem.Parameter);
		If ParameterName <> "Period" Then 
			FieldProperties.TitleLocation = FormItemTitleLocation.None;
			FieldProperties.Width = MarginWidth[ParameterName];
			FieldProperties.HorizontalStretch = False;
		EndIf;
	EndDo;
EndProcedure

// Конец СтандартныеПодсистемы.ВариантыОтчетов

#EndRegion

#EndRegion

#Region InternalProceduresAndFunctions

// Возвращает хеш-сумму двоичных данных.
//
// Parameters:
//   BinaryData - BinaryData - Данные, от которых считается хеш-сумма.
//
Function BinaryDataHash(BinaryData)
	DataHashing = New DataHashing(HashFunction.MD5);
	DataHashing.Append(BinaryData);
	Return StrReplace(DataHashing.HashSum, " ", "") + "_" + Format(BinaryData.Size(), "NG=");
EndFunction

#EndRegion

#Else
Raise NStr("en='Недопустимый вызов объекта на клиенте.';ru='Недопустимый вызов объекта на клиенте.';vi='Không thể gọi ra đối tượng trên Client.'");
#EndIf