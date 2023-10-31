///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2020, ООО 1С-Софт
// Все права защищены. Эта программа и сопроводительные материалы предоставляются 
// в соответствии с условиями лицензии Attribution 4.0 International (CC BY 4.0)
// Текст лицензии доступен по ссылке:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region ServiceProgramInterface

// Проверяет, является ли переданная строка внутренней навигационной ссылкой.
//  
// Parameters:
//  Row - String - навигационная ссылка.
//
// Returns:
//  Boolean - Checking result.
//
Function ThisIsURL(Row) Export
	
	Return StrStartsWith(Row, "e1c:")
		Or StrStartsWith(Row, "e1cib/")
		Or StrStartsWith(Row, "e1ccs/");
	
EndFunction

// Конвертирует параметры запуска текущего сеанса в передаваемые параметры в скрипт
// Например, на вход программа может быть запущена с ключом:
// /C "ПараметрыЗапускаИзВнешнейОперации=/TestClient -TPort 48050 /C РежимОтладки;РежимОтладки"
// Пробросит в скрипт следует "/TestClient -TPort 48050 /C РежимОтладки"
//
// Returns:
//  String - Parameter value.
//
Function EnterpriseStartupParametersFromScript() Export
	
	Var ParameterValue;
	
	LaunchParameters = StringFunctionsClientServer.ParametersFromString(LaunchParameter);
	If Not LaunchParameters.Property("ExternalOperationStartupParameters", ParameterValue) Then 
		ParameterValue = "";
	EndIf;
	
	Return ParameterValue;
	
EndFunction

#Region ExternalComponents

// Parameters:
//  Context - Structure - контекст процедуры:
//      * Notification           - NotifyDescription - .
//      * ID        - String             - .
//      * Location       - String             - .
//      * Cached           - Boolean             - .
//      * SuggestInstall - Boolean             - .
//      * ExplanationText       - String             - .
//      * ObjectsCreationIDs - - .
//
Procedure AttachAddInSSL(Context) Export
	
	If IsBlankString(Context.ID) Then 
		AddInContainsOneObjectClass = (Context.ObjectsCreationIDs.Count() = 0);
		
		If AddInContainsOneObjectClass Then 
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en='Не удалось подключить внешнюю компоненту на клиенте"
"%1"
"по причине:"
"Не допустимо одновременно не указывать Идентификатор и ИдентификаторыСозданияОбъектов';ru='Не удалось подключить внешнюю компоненту на клиенте"
"%1"
"по причине:"
"Не допустимо одновременно не указывать Идентификатор и ИдентификаторыСозданияОбъектов';vi='Không thể kết nối thành phần bên ngoài trên máy khách"
"%1"
"do:"
"Không được phép không chỉ định ID và ID của ObjectCreation cùng một lúc"
"'"), 
				Context.Location);
		Else
			// В случае, когда в компоненте есть несколько классов объектов
			// Идентификатор используется только для отображения компоненты в текстах ошибок.
			// Следует собрать идентификатор для отображения.
			Context.ID = StrConcat(Context.ObjectsCreationIDs, ", ");
		EndIf;
	EndIf;
	
	If Not ValidAddInLocation(Context.Location) Then 
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='Не удалось подключить внешнюю компоненту ""%1"" на клиенте"
"%2"
"по причине:"
"Не допустимо подключить компоненты из указанного местоположения.';ru='Не удалось подключить внешнюю компоненту ""%1"" на клиенте"
"%2"
"по причине:"
"Не допустимо подключить компоненты из указанного местоположения.';vi='Không thể kết nối thành phần bên ngoài ""%1"" trên máy khách"
"%2"
"do:"
"Không thể kết nối các thành phần từ vị trí đã chỉ định.'"), 
			Context.ID,
			Context.Location);
	EndIf;
	
	If Context.Cached Then 
		
		AttachableModule = GetAddInObjectFromCache(Context.Location);
		If AttachableModule <> Undefined Then 
			AttachAddInSSLNotifyOnAttachment(AttachableModule, Context);
			Return;
		EndIf;
		
	EndIf;
	
	// Проверка факта подключения внешней компоненты в этом сеансе ранее.
	SymbolicName = GetAddInSymbolicNameFromCache(Context.Location);
	
	If SymbolicName = Undefined Then 
		
		// Генерация уникального имени.
		SymbolicName = "С" + StrReplace(String(New UUID), "-", "");
		
		Context.Insert("SymbolicName", SymbolicName);
		
		Notification = New NotifyDescription(
			"AttachAddInSSLAfterAttachmentAttempt", ThisObject, Context,
			"AttachAddInSSLOnProcessError", ThisObject);
		
		BeginAttachingAddIn(Notification, Context.Location, SymbolicName);
		
	Else 
		
		// Если в кэше уже есть символическое имя - значит к этому сеансу ранее компонента уже подключалась.
		Attached = True;
		Context.Insert("SymbolicName", SymbolicName);
		AttachAddInSSLAfterAttachmentAttempt(Attached, Context);
		
	EndIf;
	
EndProcedure

// Продолжение процедуры ПодключитьКомпоненту.
Procedure AttachAddInSSLNotifyOnAttachment(AttachableModule, Context) Export
	
	Result = AddInAttachmentResult();
	Result.Attached = True;
	Result.AttachableModule = AttachableModule;
	ExecuteNotifyProcessing(Context.Notification, Result);
	
EndProcedure

// Продолжение процедуры ПодключитьКомпоненту.
Procedure AttachAddInSSLNotifyOnError(ErrorDescription, Context) Export
	
	Notification = Context.Notification;
	
	Result = AddInAttachmentResult();
	Result.ErrorDescription = ErrorDescription;
	ExecuteNotifyProcessing(Notification, Result);
	
EndProcedure

// Parameters:
//  Context - Structure - контекст процедуры:
//      * Notification     - NotifyDescription - .
//      * Location - String             - .
//      * ExplanationText - String             - .
//
Procedure SetComponent(Context) Export
	
	If Not ValidAddInLocation(Context.Location) Then 
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='Не удалось установить внешнюю компоненту ""%1"" на клиенте"
"%2"
"по причине:"
"Не допустимо устанавливать компоненты из указанного местоположения.';ru='Не удалось установить внешнюю компоненту ""%1"" на клиенте"
"%2"
"по причине:"
"Не допустимо устанавливать компоненты из указанного местоположения.';vi='Không thể cài đặt plugin ""%1"" trên máy khách"
"%2"
"do:"
"Không thể cài đặt các thành phần từ vị trí đã chỉ định.'"), 
			Context.ID,
			Context.Location);
	EndIf;
	
	// Проверка факта подключения внешней компоненты в этом сеансе ранее.
	SymbolicName = GetAddInSymbolicNameFromCache(Context.Location);
	
	If SymbolicName = Undefined Then
		
		Notification = New NotifyDescription(
			"InstallAddInSSLAfterAnswerToInstallationQuestion", ThisObject, Context);
		
		FormParameters = New Structure;
		FormParameters.Insert("ExplanationText", Context.ExplanationText);
		
		OpenForm("CommonForm.AddInInstallationQuestion", 
			FormParameters,,,,, Notification);
		
	Else 
		
		// Если в кэше уже есть символическое имя - значит к этому сеансу ранее компонента уже подключалась,
		// значит внешняя компонента уже установлена.
		Result = AddInInstallationResult();
		Result.Insert("IsSet", True);
		ExecuteNotifyProcessing(Context.Notification, Result);
		
	EndIf;
	
EndProcedure

// Продолжение процедуры УстановитьКомпоненту.
Procedure InstallAddInSSLNotifyOnError(ErrorDescription, Context) Export
	
	Notification = Context.Notification;
	
	Result = AddInInstallationResult();
	Result.ErrorDescription = ErrorDescription;
	ExecuteNotifyProcessing(Notification, Result);
	
EndProcedure

#EndRegion

#Region SpreadsheetDocument

////////////////////////////////////////////////////////////////////////////////
// Функции для работы с табличными документами.

// Выполняет расчет и вывод показателей выделенных областей ячеек табличного документа.
//
// Parameters:
//  Form - ClientApplicationForm - форма, в которой выводятся значения расчетных показателей.
//  SpreadsheetDocumentName - String - имя реквизита формы типа ТабличныйДокумент, показатели которого рассчитываются.
//  CurrentCommand - String - имя команды расчета показателя, например, "РассчитатьСумму".
//                      Определяет, какой показатель является основным.
//
Procedure CalculateIndicators(Form, SpreadsheetDocumentName, CurrentCommand = "") Export 
	
	Items = Form.Items;
	SpreadsheetDocument = Form[SpreadsheetDocumentName];
	
	If Not ValueIsFilled(CurrentCommand) Then 
		CurrentCommand = CurrentIndicatorsCalculationCommand(Items);
	EndIf;
	
	// Расчет показателей.
	CalculationParameters = CellsIndicatorsCalculationParameters(Items[SpreadsheetDocumentName]);
	
	If CalculationParameters.CalculateAtServer Then 
		CalculationIndicators = StandardSubsystemsServerCall.CalculationCellsIndicators(
			SpreadsheetDocument, CalculationParameters.SelectedAreas);
	Else
		CalculationIndicators = CommonInternalClientServer.CalculationCellsIndicators(
			SpreadsheetDocument, CalculationParameters.SelectedAreas);
	EndIf;
	
	// Установка значений показателей.
	FillPropertyValues(Form, CalculationIndicators);
	
	// Переключение и форматирование показателей.
	IndicatorsCommands = IndicatorsCommands();
	
	For Each Command In IndicatorsCommands Do 
		EditIindicatorsCalculationItemProperty(Items, Command.Key, "Check", False);
		
		IndicatorValue = CalculationIndicators[Command.Value];
		Items[Command.Value].EditFormat = IndicatorEditFormat(IndicatorValue);
	EndDo;
	
	EditIindicatorsCalculationItemProperty(Items, CurrentCommand, "Check", True);
	
	// Вывод основного показателя.
	CurrentIndicator = IndicatorsCommands[CurrentCommand];
	
	Form.Indicator = Form[CurrentIndicator];
	Items.Indicator.EditFormat = Items[CurrentIndicator].EditFormat;
	
	EditIindicatorsCalculationItemProperty(
		Items, "IndicatorsKindsCommands", "Picture", PictureLib[CurrentIndicator]);
	
	// Кэширование состояния выбора показателей.
	Form.MainIndicator = CurrentCommand;
	Form.ExpandIndicatorsArea = Items.CalculateAllIndicators.Check;
	
EndProcedure

// Управляет признаком видимости панели расчетных показателей.
//
// Parameters:
//  Visible - Boolean - Признак включения / выключения видимости панели показателей.
//              See также Синтакс-помощник: ГруппаФормы.Видимость.
//
Procedure SetIndicatorsPanelVisibiility(Controls, Visible = False) Export 
	
	Controls.IndicatorsArea.Visible = Visible;
	EditIindicatorsCalculationItemProperty(Controls, "CalculateAllIndicators", "Check", Visible);
	
EndProcedure

#EndRegion

#EndRegion

#Region InternalProceduresAndFunctions

#Region Data

#Region CopyRecursive

Function CopyStructure(SourceStructure, FixData) Export 
	
	ResultStructure = New Structure;
	
	For Each KeyAndValue In SourceStructure Do
		ResultStructure.Insert(KeyAndValue.Key, 
			CommonUseClient.CopyRecursive(KeyAndValue.Value, FixData));
	EndDo;
	
	If FixData = True 
		Or FixData = Undefined
		And TypeOf(SourceStructure) = Type("FixedStructure") Then 
		Return New FixedStructure(ResultStructure);
	EndIf;
	
	Return ResultStructure;
	
EndFunction

Function CopyMap(SourceMap, FixData) Export 
	
	ResultMap = New Map;
	
	For Each KeyAndValue In SourceMap Do
		ResultMap.Insert(KeyAndValue.Key, 
			CommonUseClient.CopyRecursive(KeyAndValue.Value, FixData));
	EndDo;
	
	If FixData = True 
		Or FixData = Undefined
		And TypeOf(SourceMap) = Type("FixedMap") Then 
		Return New FixedMap(ResultMap);
	EndIf;
	
	Return ResultMap;
	
EndFunction

Function CopyArray(ArraySource, FixData) Export 
	
	ResultArray = New Array;
	
	For Each Item In ArraySource Do
		ResultArray.Add(CommonUseClient.CopyRecursive(Item, FixData));
	EndDo;
	
	If FixData = True 
		Or FixData = Undefined
		And TypeOf(ArraySource) = Type("FixedArray") Then 
		Return New FixedArray(ResultArray);
	EndIf;
	
	Return ResultArray;
	
EndFunction

Function CopyValueList(SourceList, FixData) Export
	
	ResultList = New ValueList;
	
	For Each ListElement In SourceList Do
		ResultList.Add(
			CommonUseClient.CopyRecursive(ListElement.Value, FixData), 
			ListElement.Presentation, 
			ListElement.Check, 
			ListElement.Picture);
	EndDo;
	
	Return ResultList;
	
EndFunction

#EndRegion

#EndRegion

#Region Forms

Function MetadataObjectName(Type) Export
	
	ParameterName = "StandardSubsystems.MetadataObjectNames";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, New Map);
	EndIf;
	MetadataObjectNames = ApplicationParameters[ParameterName];
	
	Result = MetadataObjectNames[Type];
	If Result = Undefined Then
		Result = StandardSubsystemsServerCall.MetadataObjectName(Type);
		MetadataObjectNames.Insert(Type, Result);
	EndIf;
	
	Return Result;
	
EndFunction

Procedure ConfirmFormClosing() Export
	
	ParameterName = "StandardSubsystems.CloseFormValidationSettings";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, Undefined);
	EndIf;
	
	Parameters = ApplicationParameters["StandardSubsystems.CloseFormValidationSettings"];
	If Parameters = Undefined Then
		Return;
	EndIf;
	
	Notification = New NotifyDescription("ConfirmFormClosingEnd", ThisObject, Parameters);
	If IsBlankString(Parameters.WarningText) Then
		QuestionText = NStr("en = 'Данные были изменены. Сохранить изменения?'; ru = 'Данные были изменены. Сохранить изменения?'; vi = 'Dữ liệu đã được thay đổi. Lưu thay đổi?'");
	Else
		QuestionText = Parameters.WarningText;
	EndIf;
	
	ShowQueryBox(Notification, QuestionText, QuestionDialogMode.YesNoCancel, ,
		DialogReturnCode.No);
	
EndProcedure

Procedure ConfirmFormClosingEnd(Response, Parameters) Export
	
	ApplicationParameters["StandardSubsystems.CloseFormValidationSettings"] = Undefined;
	
	If Response = DialogReturnCode.Yes Then
		ExecuteNotifyProcessing(Parameters.NotificationSaveAndClose);
		
	ElsIf Response = DialogReturnCode.No Then
		Form = Parameters.NotificationSaveAndClose.Module;
		Form.Modified = False;
		Form.Close();
	Else
		Form = Parameters.NotificationSaveAndClose.Module;
		Form.Modified = True;
	EndIf;
	
EndProcedure

Procedure ConfirmArbitraryFormClosing() Export
	
	ParameterName = "StandardSubsystems.CloseFormValidationSettings";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, Undefined);
	EndIf;
	
	Parameters = ApplicationParameters["StandardSubsystems.CloseFormValidationSettings"];
	If Parameters = Undefined Then
		Return;
	EndIf;
	ApplicationParameters["StandardSubsystems.CloseFormValidationSettings"] = Undefined;
	QuestionMode = QuestionDialogMode.YesNo;
	
	Notification = New NotifyDescription("ConfirmCustomFormClosingEnd", ThisObject, Parameters);
	
	ShowQueryBox(Notification, Parameters.WarningText, QuestionMode);
	
EndProcedure

Procedure ConfirmCustomFormClosingEnd(Response, Parameters) Export
	
	Form = Parameters.Form;
	If Response = DialogReturnCode.Yes
		Or Response = DialogReturnCode.OK Then
		Form[Parameters.AttributeNameCloseFormWithoutConfirmation] = True;
		If Parameters.AlertDescriptionClose <> Undefined Then
			ExecuteNotifyProcessing(Parameters.AlertDescriptionClose);
		EndIf;
		Form.Close();
	Else
		Form[Parameters.AttributeNameCloseFormWithoutConfirmation] = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region EditingForms

Procedure CommentEndInput(Val EnteredText, Val AdditionalParameters) Export
	
	If EnteredText = Undefined Then
		Return;
	EndIf;	
	
	FormAttribute = AdditionalParameters.OwnerForm;
	
	PathToAttributeForms = StrSplit(AdditionalParameters.AttributeName, ".");
	// Если реквизит вида "Объект.Комментарий" и т.п.
	If PathToAttributeForms.Count() > 1 Then
		For IndexOf = 0 To PathToAttributeForms.Count() - 2 Do 
			FormAttribute = FormAttribute[PathToAttributeForms[IndexOf]];
		EndDo;
	EndIf;	
	
	FormAttribute[PathToAttributeForms[PathToAttributeForms.Count() - 1]] = EnteredText;
	AdditionalParameters.OwnerForm.Modified = True;
	
EndProcedure

#EndRegion

#Region ExternalComponents

#Region AttachAddIn

// Продолжение процедуры ПодключитьКомпоненту.
Procedure AttachAddInSSLAfterAttachmentAttempt(Attached, Context) Export 
	
	If Attached Then 
		
		// Сохранение факта подключения внешней компоненты к этому сеансу.
		WriteAddInSymbolicNameToCache(Context.Location, Context.SymbolicName);
		
		AttachableModule = Undefined;
		
		Try
			AttachableModule = NewAddInObject(Context);
		Except
			// Текст ошибки уже скомпонован в НовыйОбъектКомпоненты, требуется только оповестить.
			ErrorText = BriefErrorDescription(ErrorInfo());
			AttachAddInSSLNotifyOnError(ErrorText, Context);
			Return;
		EndTry;
		
		If Context.Cached Then 
			WriteAddInObjectToCache(Context.Location, AttachableModule)
		EndIf;
		
		AttachAddInSSLNotifyOnAttachment(AttachableModule, Context);
		
	Else 
		
		If Context.SuggestInstall Then 
			AttachAddInSSLStartInstallation(Context);
		Else 
			ErrorText =  StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en='Не удалось подключить внешнюю компоненту ""%1"" на клиенте"
"%2"
"по причине:"
"Метод НачатьПодключениеВнешнейКомпоненты вернул Ложь.';ru='Не удалось подключить внешнюю компоненту ""%1"" на клиенте"
"%2"
"по причине:"
"Метод НачатьПодключениеВнешнейКомпоненты вернул Ложь.';vi='Không thể kết nối thành phần bên ngoài ""%1"" trên ứng dụng khách"
"%2"
"do"
"Phương pháp НачатьПодключениеВнешнейКомпоненты вернул Ложь.'"),
				Context.ID,
				Context.Location);
			
			AttachAddInSSLNotifyOnError(ErrorText, Context);
		EndIf;
		
	EndIf;
	
EndProcedure

// Продолжение процедуры ПодключитьКомпоненту.
Procedure AttachAddInSSLStartInstallation(Context)
	
	Notification = New NotifyDescription(
		"AttachAddInSSLAfterInstallation", ThisObject, Context);
	
	InstallationContext = New Structure;
	InstallationContext.Insert("Notification", Notification);
	InstallationContext.Insert("Location", Context.Location);
	InstallationContext.Insert("ExplanationText", Context.ExplanationText);
	
	SetComponent(InstallationContext);
	
EndProcedure

// Продолжение процедуры ПодключитьКомпоненту.
Procedure AttachAddInSSLAfterInstallation(Result, Context) Export 
	
	If Result.IsConnected Then 
		// Одна попытка установки уже прошла, если компонента не подключится в этот раз,
		// то и предлагать ее установить еще раз не следует.
		Context.SuggestInstall = False;
		AttachAddInSSL(Context);
	Else 
		// Расшифровка ОписаниеОшибки не нужна, текст уже сформирован при установке.
		// При отказе от установки пользователем ОписаниеОшибки - пустая строка.
		AttachAddInSSLNotifyOnError(Result.ErrorDescription, Context);
	EndIf;
	
EndProcedure

// Продолжение процедуры ПодключитьКомпоненту.
Procedure AttachAddInSSLOnProcessError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en='Не удалось подключить внешнюю компоненту ""%1"" на клиенте"
"%2"
"по причине:"
"%3';ru='Не удалось подключить внешнюю компоненту ""%1"" на клиенте"
"%2"
"по причине:"
"%3';vi='Không thể kết nối thành phần bên ngoài  ""%1"" trên máy khách"
"%2"
"do:"
"%3'"),
		Context.ID,
		Context.Location,
		BriefErrorDescription(ErrorInfo));
		
	AttachAddInSSLNotifyOnError(ErrorText, Context);
	
EndProcedure

// Создает экземпляр внешней компоненты (или несколько)
Function NewAddInObject(Context)
	
	AddInContainsOneObjectClass = (Context.ObjectsCreationIDs.Count() = 0);
	
	If AddInContainsOneObjectClass Then 
		
		Try
			AttachableModule = New("AddIn." + Context.SymbolicName + "." + Context.ID);
			If AttachableModule = Undefined Then 
				Raise NStr("en='Оператор Новый вернул Неопределено';ru='Оператор Новый вернул Неопределено';vi='Nhà điều hành Mới trả lại Chưa xác định'");
			EndIf;
		Except
			AttachableModule = Undefined;
			ErrorText = BriefErrorDescription(ErrorInfo());
		EndTry;
		
		If AttachableModule = Undefined Then 
			
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en='Не удалось создать объект внешней компоненты ""%1"", подключенной на клиенте"
"%2,"
"по причине:"
"%3';ru='Не удалось создать объект внешней компоненты ""%1"", подключенной на клиенте"
"%2,"
"по причине:"
"%3';vi='Không thể tạo đối tượng thành phần bên ngoài ""%1"" được kết nối trên ứng dụng khách"
"%2,"
"do:"
"%3'"),
				Context.ID,
				Context.Location,
				ErrorText);
			
		EndIf;
		
	Else 
		
		AttachableModules = New Map;
		For Each ObjectID In Context.ObjectsCreationIDs Do 
			
			Try
				AttachableModule = New("AddIn." + Context.SymbolicName + "." + ObjectID);
				If AttachableModule = Undefined Then 
					Raise NStr("en='Оператор Новый вернул Неопределено';ru='Оператор Новый вернул Неопределено';vi='Nhà điều hành Mới trả lại Chưa xác định'");
				EndIf;
			Except
				AttachableModule = Undefined;
				ErrorText = BriefErrorDescription(ErrorInfo());
			EndTry;
			
			If AttachableModule = Undefined Then 
				
				Raise StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en='Не удалось создать объект ""%1"" внешней компоненты ""%2"", подключенной на клиенте"
"%3,"
"по причине:"
"%4';ru='Не удалось создать объект ""%1"" внешней компоненты ""%2"", подключенной на клиенте"
"%3,"
"по причине:"
"%4';vi='Không thể tạo đối tượng ""%1"" của thành phần bên ngoài ""%2"" được kết nối trên ứng dụng khách"
"%3"
"do:"
"%4'"),
					ObjectID,
					Context.ID,
					Context.Location,
					ErrorText);
				
			EndIf;
			
			AttachableModules.Insert(ObjectID, AttachableModule);
			
		EndDo;
		
		AttachableModule = New FixedMap(AttachableModules);
		
	EndIf;
	
	Return AttachableModule;
	
EndFunction

// Продолжение процедуры ПодключитьКомпоненту.
Function AddInAttachmentResult()
	
	Result = New Structure;
	Result.Insert("Attached", False);
	Result.Insert("ErrorDescription", "");
	Result.Insert("AttachableModule", Undefined);
	
	Return Result;
	
EndFunction

#EndRegion

#Region InstallAddIn

// Продолжение процедуры УстановитьКомпоненту.
Procedure InstallAddInSSLAfterAnswerToInstallationQuestion(Response, Context) Export
	
	// Результат: 
	// - КодВозвратаДиалога.Да - Установить.
	// - КодВозвратаДиалога.Отмена - Отклонить.
	// - Неопределено - Закрыто окно.
	If Response = DialogReturnCode.Yes Then
		InstallAddInSSLStartInstallation(Context);
	Else
		Result = AddInInstallationResult();
		ExecuteNotifyProcessing(Context.Notification, Result);
	EndIf;
	
EndProcedure

// Продолжение процедуры УстановитьКомпоненту.
Procedure InstallAddInSSLStartInstallation(Context)
	
	Notification = New NotifyDescription(
		"InstallAddInSSLAfterInstallationAttempt", ThisObject, Context,
		"InstallAddInSSLOnProcessError", ThisObject);
	
	BeginInstallAddIn(Notification, Context.Location);
	
EndProcedure

// Продолжение процедуры УстановитьКомпоненту.
Procedure InstallAddInSSLAfterInstallationAttempt(Context) Export 
	
	Result = AddInInstallationResult();
	Result.Insert("IsSet", True);
	
	ExecuteNotifyProcessing(Context.Notification, Result);
	
EndProcedure

// Продолжение процедуры УстановитьКомпоненту.
Procedure InstallAddInSSLOnProcessError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en='Не удалось установить внешнюю компоненту ""%1"" на клиенте "
"%2"
"по причине:"
"%3';ru='Не удалось установить внешнюю компоненту ""%1"" на клиенте "
"%2"
"по причине:"
"%3';vi='Không cài đặt được thành phần bên ngoài ""%1"" trên máy khách"
"%2"
"do:"
"%3'"),
		Context.ID,
		Context.Location,
		BriefErrorDescription(ErrorInfo));
	
	Result = AddInInstallationResult();
	Result.ErrorDescription = ErrorText;
	
	ExecuteNotifyProcessing(Context.Notification, Result);
	
EndProcedure

// Продолжение процедуры УстановитьКомпоненту.
Function AddInInstallationResult()
	
	Result = New Structure;
	Result.Insert("IsSet", False);
	Result.Insert("ErrorDescription", "");
	
	Return Result;
	
EndFunction

#EndRegion

Function ValidAddInLocation(Location)
	
	If CommonUseClient.SubsystemExists("StandardSubsystems.ExternalComponents") Then
		ModuleAddInsInternalClient = CommonUseClient.CommonModule("AddInsInternalClient");
		If ModuleAddInsInternalClient.IsComponentFromStorage(Location) Then
			Return True;
		EndIf;
	EndIf;
	
	Return IsTemplate(Location);
	
EndFunction

Function IsTemplate(Location)
	
	PathSteps = StrSplit(Location, ".");
	If PathSteps.Count() < 2 Then 
		Return False;
	EndIf;
	
	Path = New Structure;
	Try
		For Each PathStep In PathSteps Do 
			Path.Insert(PathStep);
		EndDo;
	Except
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

// Получает из кэша символическое имя внешней компоненты, если она была ранее подключена.
Function GetAddInSymbolicNameFromCache(ObjectKey)
	
	SymbolicName = Undefined;
	CachedSymbolicNames = ApplicationParameters["StandardSubsystems.ExternalComponents.SymbolicNames"];
	
	If TypeOf(CachedSymbolicNames) = Type("FixedMap") Then
		SymbolicName = CachedSymbolicNames.Get(ObjectKey);
	EndIf;
	
	Return SymbolicName;
	
EndFunction

// Записывает в кэш символическое имя внешней компоненты.
Procedure WriteAddInSymbolicNameToCache(ObjectKey, SymbolicName)
	
	Map = New Map;
	CachedSymbolicNames = ApplicationParameters["StandardSubsystems.ExternalComponents.SymbolicNames"];
	
	If TypeOf(CachedSymbolicNames) = Type("FixedMap") Then
		
		If CachedSymbolicNames.Get(ObjectKey) <> Undefined Then // Уже есть в кэше.
			Return;
		EndIf;
		
		For Each Item In CachedSymbolicNames Do
			Map.Insert(Item.Key, Item.Value);
		EndDo;
		
	EndIf;
	
	Map.Insert(ObjectKey, SymbolicName);
	
	ApplicationParameters.Insert("StandardSubsystems.ExternalComponents.SymbolicNames",
		New FixedMap(Map));
	
EndProcedure

// Получает из кэша объект - экземпляр внешней компоненты
Function GetAddInObjectFromCache(ObjectKey)
	
	AttachableModule = Undefined;
	CachedObjects = ApplicationParameters["StandardSubsystems.ExternalComponents.Objects"];
	
	If TypeOf(CachedObjects) = Type("FixedMap") Then
		AttachableModule = CachedObjects.Get(ObjectKey);
	EndIf;
	
	Return AttachableModule;
	
EndFunction

// Записывает в кэш экземпляр внешней компоненты
Procedure WriteAddInObjectToCache(ObjectKey, AttachableModule)
	
	Map = New Map;
	CachedObjects = ApplicationParameters["StandardSubsystems.ExternalComponents.Objects"];
	
	If TypeOf(CachedObjects) = Type("FixedMap") Then
		For Each Item In CachedObjects Do
			Map.Insert(Item.Key, Item.Value);
		EndDo;
	EndIf;
	
	Map.Insert(ObjectKey, AttachableModule);
	
	ApplicationParameters.Insert("StandardSubsystems.ExternalComponents.Objects",
		New FixedMap(Map));
	
EndProcedure

#EndRegion

#Region ExternalConnection

// Продолжение процедуры ОбщегоНазначенияКлиент.ЗарегистрироватьCOMСоединитель.
Procedure RegisterCOMConnectorOnCheckRegistration(Result, Context) Export
	
	ApplicationStarted = Result.ApplicationStarted;
	ErrorDescription = Result.ErrorDescription;
	ReturnCode = Result.ReturnCode;
	ExecuteSessionReboot = Context.ExecuteSessionReboot;
	
	If ApplicationStarted Then
		
		If ExecuteSessionReboot Then
			
			Notification = New NotifyDescription("RegisterCOMConnectorOnCheckAnswerAboutRestart", 
				CommonInternalClient, Context);
			
			QuestionText = 
				NStr("en='Для завершения перерегистрации компоненты comcntr необходимо перезапустить программу."
"Перезапустить сейчас?';ru='Для завершения перерегистрации компоненты comcntr необходимо перезапустить программу."
"Перезапустить сейчас?';vi='Để hoàn tất việc đăng ký lại thành phần comcntr, bạn phải khởi động lại chương trình."
"Khởi động lại ngay bây giờ?'");
			
			ShowQueryBox(Notification, QuestionText, QuestionDialogMode.YesNo);
			
		Else 
			
			Notification = Context.Notification;
			
			Registered = True;
			ExecuteNotifyProcessing(Notification, Registered);
			
		EndIf;
		
	Else 
		
		MessageText = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='Ошибка при регистрации компоненты comcntr."
"Код ошибки regsvr32: %1';ru='Ошибка при регистрации компоненты comcntr."
"Код ошибки regsvr32: %1';vi='Lỗi khi đăng ký thành phần comcntr."
"Mã lỗi Regsvr32: %1'"),
			ReturnCode);
			
		If ReturnCode = 5 Then
			MessageText = MessageText + " " + NStr("en='Недостаточно прав доступа.';ru='Недостаточно прав доступа.';vi='Không đủ quyền truy cập.'");
		Else 
			MessageText = MessageText + Chars.LF + ErrorDescription;
		EndIf;
		
		EventLogMonitorClient.AddMessageForEventLogMonitor(
			NStr("en='Регистрация компоненты comcntr';ru='Регистрация компоненты comcntr';vi='Biểu ghi thành phần comcntr'", CommonUseClient.MainLanguageCode()),
			"Error",
			MessageText,,
			True);
		
		Notification = New NotifyDescription("RegisterCOMConnectorNotifyOnError", 
			CommonInternalClient, Context);
		
		ShowMessageBox(Notification, MessageText);
		
	EndIf;
	
EndProcedure

// Продолжение процедуры ОбщегоНазначенияКлиент.ЗарегистрироватьCOMСоединитель.
Procedure RegisterCOMConnectorOnCheckAnswerAboutRestart(Response, Context) Export
	
	If Response = DialogReturnCode.Yes Then
		ApplicationParameters.Insert("StandardSubsystems.SkipExitConfirmation", True);
		Exit(True, True);
	Else 
		RegisterCOMConnectorNotifyOnError(Context);
	EndIf;

EndProcedure

// Продолжение процедуры ОбщегоНазначенияКлиент.ЗарегистрироватьCOMСоединитель.
Procedure RegisterCOMConnectorNotifyOnError(Context) Export
	
	Notification = Context.Notification;
	
	If Notification <> Undefined Then
		Registered = False;
		ExecuteNotifyProcessing(Notification, Registered);
	EndIf;
	
EndProcedure

// Продолжение процедуры ОбщегоНазначенияКлиент.ЗарегистрироватьCOMСоединитель.
Function RegisterCOMConnectorRegistrationIsAvailable() Export
	
#If WebClient Or MobileClient Then
	Return False;
#Else
	ClientWorkParametersOnStart = StandardSubsystemsClient.ClientWorkParametersOnStart();
	Return Not CommonUseClient.ClientConnectedViaWebServer()
		And Not ClientWorkParametersOnStart.ThisIsBasicConfigurationVersion
		And Not ClientWorkParametersOnStart.IsEducationalPlatform;
#EndIf
	
EndFunction

#EndRegion

#Region SpreadsheetDocument

Function CurrentIndicatorsCalculationCommand(Controls)
	
	Var CurrentCommand;
	
	IndicatorsCommands = IndicatorsCommands();
	For Each Command In IndicatorsCommands Do 
		
		If Controls[Command.Key].Check Then 
			
			CurrentCommand = Command.Key;
			Break;
			
		EndIf;
		
	EndDo;
	
	If CurrentCommand = Undefined Then 
		CurrentCommand = "CalculateAmount";
	EndIf;
	
	Return CurrentCommand;
	
EndFunction

// Определяет соответствие между командами расчета показателей и показателями.
//
// Returns:
//   Map - Ключ - имя команды, Значение - имя показателя.
//
Function IndicatorsCommands()
	
	IndicatorsCommands = New Map();
	IndicatorsCommands.Insert("CalculateAmount", "Amount");
	IndicatorsCommands.Insert("CalculateCount", "Quantity");
	IndicatorsCommands.Insert("CalculateAverage", "AVG");
	IndicatorsCommands.Insert("CalculateMin", "Minimum");
	IndicatorsCommands.Insert("CalculateMax", "Maximum");
	
	Return IndicatorsCommands;
	
EndFunction

// Формирует описание выделенных областей табличного документа.
//
// Parameters:
//  DocumentField - FormField, SpreadsheetDocumentField - документ, значения ячеек которого участвуют в расчете.
//
// Returns: 
//   Structure - Contains:
//       * SelectedAreas - Array - содержит структуры со свойствами:
//           * Top  - Number - Номер строки верхней границы области.
//           * Bottom   - Number - Номер строки нижней границы области.
//           * Left  - Number - Номер колонки верхней границы области.
//           * Right - Number - Номер колонки нижней границы области.
//           * AreaType - SpreadsheetDocumentCellAreaType - Колонки, Прямоугольник, Строки, Таблица.
//       * CalculateAtServer - Boolean - признак того, что расчет должен выполняться на сервере.
//
Function CellsIndicatorsCalculationParameters(DocumentField) 
	
	IndicatorsCalculationParameters = New Structure;
	IndicatorsCalculationParameters.Insert("SelectedAreas", New Array);
	IndicatorsCalculationParameters.Insert("CalculateAtServer", False);
	
	SelectedAreas = IndicatorsCalculationParameters.SelectedAreas;
	SelectedDocumentAreas = DocumentField.GetSelectedAreas();
	
	For Each SelectedArea In SelectedDocumentAreas Do
		
		If TypeOf(SelectedArea) <> Type("SpreadsheetDocumentRange") Then
			Continue;
		EndIf;
		
		AreaBoundaries = New Structure("Top, Bottom, Left, Right, AreaType");
		FillPropertyValues(AreaBoundaries, SelectedArea);
		SelectedAreas.Add(AreaBoundaries);
		
	EndDo;
	
	SelectedAll = False;
	
	If SelectedAreas.Count() = 1 Then 
		
		SelectedArea = SelectedAreas[0];
		SelectedAll = Not Boolean(
			SelectedArea.Top
			+ SelectedArea.Bottom
			+ SelectedArea.Left
			+ SelectedArea.Right);
		
	EndIf;
	
	IndicatorsCalculationParameters.CalculateAtServer = (SelectedAll Or SelectedAreas.Count() >= 100);
	
	Return IndicatorsCalculationParameters;
	
EndFunction

Function IndicatorEditFormat(IndicatorValue)
	
	EditFormatTemplate = "NFD=%1; NGS=' '; NZ=0";
	
	FractionalPartValue = Max(IndicatorValue, -IndicatorValue) % 1;
	FractionDigits = Min(?(FractionalPartValue = 0, 0, StrLen(FractionalPartValue) - 2), 5);
	
	EditFormat = StringFunctionsClientServer.SubstituteParametersInString(
		EditFormatTemplate, FractionDigits);
	
	IndicatorPresentation = Format(IndicatorValue, EditFormat);
	
	While FractionDigits > 0
		And StrEndsWith(IndicatorPresentation, "0") Do 
		
		IndicatorPresentation = Mid(IndicatorPresentation, 1, StrLen(IndicatorPresentation) - 1);
		FractionDigits = FractionDigits - 1;
		
	EndDo;
	
	Return StringFunctionsClientServer.SubstituteParametersInString(
		EditFormatTemplate, FractionDigits);
	
EndFunction

Procedure EditIindicatorsCalculationItemProperty(Controls, ItemName, PropertyName, PropertyValue)
	
	ItemsNamesList = StringFunctionsClientServer.SubstituteParametersInString("%1, %1%2", ItemName, "Yet");
	NamesOfElements = StrSplit(ItemsNamesList, ", ", False);
	
	For Each NAME In NamesOfElements Do 
		
		FoundItem = Controls.Find(NAME);
		
		If FoundItem <> Undefined Then 
			FoundItem[PropertyName] = PropertyValue;
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region ObsoleteProceduresAndFunctions

#Region FileOperationsExtension

// Устарела. Используется в ОбщегоНазначенияКлиент.ПроверитьРасширениеРаботыСФайламиПодключено.
Procedure CheckFileOperationsExtensionConnectedEnd(ExtensionAttached, AdditionalParameters) Export
	
	If ExtensionAttached Then
		ExecuteNotifyProcessing(AdditionalParameters.OnCloseNotifyDescription);
		Return;
	EndIf;
	
	MessageText = AdditionalParameters.WarningText;
	If IsBlankString(MessageText) Then
		MessageText = NStr("en='Действие недоступно, так как не установлено расширение для работы с 1С:Предприятием.';ru='Действие недоступно, так как не установлено расширение для работы с 1С:Предприятием.';vi='Tác vụ không khả dụng vì tiện ích mở rộng để làm việc với 1C: Enterprise chưa được cài đặt.'")
	EndIf;
	ShowMessageBox(, MessageText);
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion