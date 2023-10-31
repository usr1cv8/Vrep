////////////////////////////////////////////////////////////////////////////////
// The subsystem "Basic functionality".
// Long server operations work support in web client.
//  
////////////////////////////////////////////////////////////////////////////////

#Region ProgramInterface

// Runs the procedure in the background job.
// 
// Parameters:
//  FormID     - UUID - identifier
// of the form that runs launch lengthy operation. 
//  ExportProcedureName - String - name of export
// procedure which is required to be run in background.
//  Parameters              - Structure - all necessary parameters
// for procedure ExportProcedureName.
//  BackgroundJobDescription    - String - background job name. 
//                           If not set, then it will still be ExportProcedureName. 
//  UseAdditionalTemporaryStorage - Boolean - sign
//                           of using additional temporary repository for
//                           data transfer to the parent session from background job. By default - False.
//
// Returns:
//  Structure              - job execution parameters: 
//   * StorageAddress  - String     - address of the temporary storage
//                                    to which the job result will be put;
//   * StorageAddressAdditional - String - address of the
//                                    additional temporary storage to which the job result will be put
//                                    (available only if you set the UseAdditionalTemporaryStorage parameter);
//   * JobID - UUID - unique identifier of the launched background job;
//   * JobCompleted - Boolean - True if the job is successfully complete during the function call.
// 
Function ExecuteInBackground(Val FormID, Val ExportProcedureName, 
	Val Parameters, Val BackgroundJobDescription = "", UseAdditionalTemporaryStorage = False) Export
	
	StorageAddress = PutToTempStorage(Undefined, FormID);
	
	Result = New Structure;
	Result.Insert("Status",    "Running");
	Result.Insert("StorageAddress",       StorageAddress);
	Result.Insert("JobCompleted",     False);
	Result.Insert("JobID", Undefined);
	Result.Insert("ResultAddress", Undefined);
	Result.Insert("AdditionalResultAddress", "");
	Result.Insert("ShortErrorDescription", "");
	Result.Insert("DetailedErrorDescription", "");
	Result.Insert("Messages", New FixedArray(New Array));

	
	If Not ValueIsFilled(BackgroundJobDescription) Then
		BackgroundJobDescription = ExportProcedureName;
	EndIf;
	
	ExportProcedureParameters = New Array;
	ExportProcedureParameters.Add(Parameters);
	ExportProcedureParameters.Add(StorageAddress);
	
	If UseAdditionalTemporaryStorage Then
		StorageAddressAdditional = PutToTempStorage(Undefined, FormID);
		ExportProcedureParameters.Add(StorageAddressAdditional);
	EndIf;
	
	JobsLaunched = 0;
	If CommonUse.FileInfobase() Then
		Filter = New Structure;
		Filter.Insert("State", BackgroundJobState.Active);
		JobsLaunched = BackgroundJobs.GetBackgroundJobs(Filter).Count();
	EndIf;
	
	If CommonUseClientServer.DebugMode()
		Or JobsLaunched > 0 Then
		WorkInSafeMode.ExecuteConfigurationMethod(ExportProcedureName, ExportProcedureParameters);
		Result.JobCompleted = True;
		Result.Status = "Completed";
		
	Else
		JobParameters = New Array;
		JobParameters.Add(ExportProcedureName);
		JobParameters.Add(ExportProcedureParameters);
		Timeout = ?(GetClientConnectionSpeed() = ClientConnectionSpeed.Low, 4, 2);
		
		Task = StandardSubsystemsServer.RunBackgroundJobWithClientContext(ExportProcedureName,
			ExportProcedureParameters,, BackgroundJobDescription);
		
		Try
			Task.WaitForExecutionCompletion(Timeout);
		Except
			// Special processor is not required, exception may be caused by timeout.
		EndTry;
		
		Result.JobCompleted = JobCompleted(Task.UUID);
		Result.JobID = Task.UUID;
		
		If Result.JobCompleted = True Then
			Result.Status = "Completed";
		EndIf;
		
	EndIf;
	
	If UseAdditionalTemporaryStorage Then
		Result.Insert("StorageAddressAdditional", StorageAddressAdditional);
	EndIf;
	
	Return Result;
	
EndFunction

// Возвращает новую структуру для параметра ПараметрыВыполнения функции ВыполнитьВФоне.
//
// Parameters:
//   FormID - UUID - уникальный идентификатор формы, 
//                               во временное хранилище которой надо поместить результат выполнения процедуры.
//
// Returns:
//   Structure - со свойствами:
//     * FormID      - UUID - уникальный идентификатор формы, 
//                               во временное хранилище которой надо поместить результат выполнения процедуры.
//     * AdditionalResult - Boolean     - признак использования дополнительного временного хранилища для передачи 
//                                 результата из фонового задания в родительский сеанс. По умолчанию - Ложь.
//     * WaitForCompletion       - Number, Undefined - таймаут в секундах ожидания завершения фонового задания. 
//                               Если задано Неопределено, то ждать до момента завершения задания. 
//                               Если задано 0, то ждать завершения задания не требуется. 
//                               По умолчанию - 2 секунды; а для низкой скорости соединения - 4. 
//     * BackgroundJobDescription - String - описание фонового задания. По умолчанию - имя процедуры.
//     * BackgroundJobKey      - String    - уникальный ключ для активных фоновых заданий, имеющих такое же имя процедуры.
//                                              По умолчанию не задан.
//     * ResultAddress          - String - адрес временного хранилища, в которое должен быть помещен результат
//                                           работы процедуры. Если не задан, адрес формируется автоматически.
//     * RunBackground           - Boolean - если True, то задание будет всегда выполняться в фоне,
//                               за исключением режима отладки.
//                               В файловом варианте при наличии ранее запущенных заданий,
//                               новое задание становится в очередь и начинает выполняться после завершения предыдущих.
//     * RunNotInBackground         - Boolean - если True, задание всегда будет запускаться непосредственно,
//                               без использования фонового задания.
//     * WithoutExtensions            - Boolean - если True, то фоновое задание будет запущено без подключения
//                               расширений конфигурации.
//
Function BackgroundExecutionParameters(Val FormID) Export
	
	Result = GeneralBacgroundExecutionParameters();
	AddExecutionParametersForResultReturning(Result, FormID);
	Result.Insert("AdditionalResult", False);
	
	Return Result;
	
EndFunction

// Cancels background job execution by the passed identifier.
// 
// Parameters:
//  JobID - UUID - background job identifier. 
// 
Procedure CancelJobExecution(Val JobID) Export 
	
	If Not ValueIsFilled(JobID) Then
		Return;
	EndIf;
	
	Task = FindJobByID(JobID);
	If Task = Undefined
		OR Task.State <> BackgroundJobState.Active Then
		
		Return;
	EndIf;
	
	Try
		Task.Cancel();
	Except
		// The job might end at the moment and there is no error.
		WriteLogEvent(NStr("ru = 'Длительные операции.Отмена выполнения фонового задания';
							|vi = ' Giao dịch chạy lâu. Hủy bỏ thực hiện nhiệm vụ nền';
							|en = 'Long actions. Background job execution cancellation'", CommonUseClientServer.MainLanguageCode()),
			EventLogLevel.Error, , , DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

// Checks background job state by the passed identifier.
// Throws an exception if there is premature job ending.
//
// Parameters:
//  JobID - UUID - background job identifier. 
//
// Returns:
//  Boolean - job execution state.
// 
Function JobCompleted(Val JobID) Export
	
	Task = FindJobByID(JobID);
	
	If Task <> Undefined
		AND Task.State = BackgroundJobState.Active Then
		Return False;
	EndIf;
	
	ActionNotExecuted = True;
	ShowFullErrorText = False;
	If Task = Undefined Then
		WriteLogEvent(NStr("ru = 'Длительные операции.Фоновое задание не найдено';
							|vi = ' Giao dịch chạy lâu. Không tìm thấy nhiệm vụ nền';
							|en = 'Long actions. Background job is not found'", CommonUseClientServer.MainLanguageCode()),
			EventLogLevel.Error, , , String(JobID));
	Else
		If Task.State = BackgroundJobState.Failed Then
			JobError = Task.ErrorInfo;
			If JobError <> Undefined Then
				ShowFullErrorText = True;
			EndIf;
		ElsIf Task.State = BackgroundJobState.Canceled Then
			WriteLogEvent(
				NStr("ru = 'Длительные операции.Фоновое задание отменено администратором';
					|vi = ' Giao dịch chạy lâu. Nhiệm vụ nền bị hủy bỏ bởi người quản trị';
					|en = 'Long actions. Background job is canceled by administrator'", CommonUseClientServer.MainLanguageCode()),
				EventLogLevel.Error,
				,
				,
				NStr("ru = 'Задание завершилось с неизвестной ошибкой.';
					|vi = 'Nhiệm vụ kết thúc có lỗi không xác định.';
					|en = 'Job was completed with an unknown error.'"));
		Else
			Return True;
		EndIf;
	EndIf;
	
	If ShowFullErrorText Then
		ErrorText = BriefErrorDescription(GetErrorInfo(Task.ErrorInfo));
		Raise(ErrorText);
	ElsIf ActionNotExecuted Then
		Raise(NStr("ru = 'Не удалось выполнить данную операцию. """"Подробности см. в журнале регистрации.';
|vi = 'Không thể thực hiện giao dịch này.""""Chi tiết xem trong Nhật ký sự kiện.';
|en = 'Unable to execute this operation. """"Look for details in event log.'"));
	EndIf;
	
EndFunction

// Registers information about the background job execution in messages.
//   This information can be read from the client using the ReadProgress function.
//
// Parameters:
//  Percent - Number  - Optional. Execution percent.
//  Text   - String - Optional. Information about current operation.
//  AdditionalParameters - Arbitrary - Optional. Any additional
//      information that should be passed to client Value should be simple (serialized to XML string).
//
Procedure TellProgress(Val Percent = Undefined, Val Text = Undefined, Val AdditionalParameters = Undefined) Export
	
	PassedValue = New Structure;
	If Percent <> Undefined Then
		PassedValue.Insert("Percent", Percent);
	EndIf;
	If Text <> Undefined Then
		PassedValue.Insert("Text", Text);
	EndIf;
	If AdditionalParameters <> Undefined Then
		PassedValue.Insert("AdditionalParameters", AdditionalParameters);
	EndIf;
	
	PassedText = CommonUse.ValueToXMLString(PassedValue);
	
	Text = "{" + SubsystemName() + "}" + PassedText;
	CommonUseClientServer.MessageToUser(Text);
	
	GetUserMessages(True); // Deleting previous messages.
	
EndProcedure

// Finds background job and reads from its messages information about execution process.
//
// Returns:
//   Structure - Information about background job execution process.
//       Structure keys and values match names and parameters values of the ReportProgress() procedure.
//
Function ReadProgress(Val JobID) Export
	Var Result;
	
	Task = BackgroundJobs.FindByUUID(JobID);
	If Task = Undefined Then
		Return Result;
	EndIf;
	
	MessagesArray = Task.GetUserMessages(True);
	If MessagesArray = Undefined Then
		Return Result;
	EndIf;
	
	Count = MessagesArray.Count();
	
	For Number = 1 To Count Do
		ReverseIndex = Count - Number;
		Message = MessagesArray[ReverseIndex];
		
		If Left(Message.Text, 1) = "{" Then
			Position = Find(Message.Text, "}");
			If Position > 2 Then
				MechanismIdentifier = Mid(Message.Text, 2, Position - 2);
				If MechanismIdentifier = SubsystemName() Then
					ReceivedText = Mid(Message.Text, Position + 1);
					Result = CommonUse.ValueFromXMLString(ReceivedText);
					Break;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
	Return Result;
EndFunction

// Возвращает новую структуру для параметра ПараметрыВыполнения функции ВыполнитьВФоне.
//
// Параметры:
//   ИдентификаторФормы - УникальныйИдентификатор - уникальный идентификатор формы, 
//                               во временное хранилище которой надо поместить результат выполнения процедуры.
//
// Returns:
//   Structure - со свойствами:
//     * FormID      - UUID - уникальный идентификатор формы, 
//                               во временное хранилище которой надо поместить результат выполнения процедуры.
//     * AdditionalResult - Boolean     - признак использования дополнительного временного хранилища для передачи 
//                                 результата из фонового задания в родительский сеанс. По умолчанию - Ложь.
//     * WaitForCompletion       - Number, Undefined - таймаут в секундах ожидания завершения фонового задания. 
//                               Если задано Неопределено, то ждать до момента завершения задания. 
//                               Если задано 0, то ждать завершения задания не требуется. 
//                               По умолчанию - 2 секунды; а для низкой скорости соединения - 4. 
//     * BackgroundJobDescription - String - описание фонового задания. По умолчанию - имя процедуры.
//     * BackgroundJobKey      - String    - уникальный ключ для активных фоновых заданий, имеющих такое же имя процедуры.
//                                              По умолчанию, не задан.
//     * ResultAddress          - String - адрес временного хранилища, в которое должен быть помещен результат
//                                           работы процедуры. Если не задан, адрес формируется автоматически.
//     * RunBackground           - Boolean - если True, то задание будет всегда выполняться в фоне,
//                               за исключением режима отладки.
//                               В файловом варианте, при наличии ранее запущенных заданий,
//                               новое задание становится в очередь и начинает выполняться после завершения предыдущих.
//     * RunNotInBackground         - Boolean - если True, задание всегда будет запускаться непосредственно,
//                               без использования фонового задания.
//     * WithoutExtensions            - Boolean - если True, то фоновое задание будет запущено без подключения
//                               расширений конфигурации.
//
Function AttributesExecuteInBackground(Val FormID) Export
	
	Result = New Structure;
	Result.Insert("FormID", FormID); 
	Result.Insert("AdditionalResult", False);
	Result.Insert("WaitForCompletion", ?(GetClientConnectionSpeed() = ClientConnectionSpeed.Low, 4, 0.8));
	Result.Insert("BackgroundJobDescription", "");
	Result.Insert("BackgroundJobKey", "");
	Result.Insert("ResultAddress", Undefined);
	Result.Insert("RunNotInBackground", False);
	Result.Insert("RunBackground", False);
	Result.Insert("WithoutExtensions", False);
	Return Result;
	
EndFunction

#EndRegion

#Region ServiceProceduresAndFunctions

Function FindJobByID(Val JobID)
	
	If TypeOf(JobID) = Type("String") Then
		JobID = New UUID(JobID);
	EndIf;
	
	Task = BackgroundJobs.FindByUUID(JobID);
	
	Return Task;
	
EndFunction

Function GetErrorInfo(ErrorInfo)
	
	Result = ErrorInfo;
	If ErrorInfo <> Undefined Then
		If ErrorInfo.Cause <> Undefined Then
			Result = GetErrorInfo(ErrorInfo.Cause);
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

Procedure ExecuteProcedureDataProcessorsObjectModule(Parameters, StorageAddress) Export 
	
	MethodName = Parameters.MethodName;
	TempStructure = New Structure;
	Try
		TempStructure.Insert(MethodName);
	Except
		WriteLogEvent(NStr("ru = 'Безопасное выполнение метода обработки';
							|vi = 'Thực hiện phương pháp xử lý an toàn';
							|en = 'Safe execution of the data processor method'", CommonUseClientServer.MainLanguageCode()),
			EventLogLevel.Error, , , DetailErrorDescription(ErrorInfo()));
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("ru = 'Имя метода ""%1"" не соответствует требованиям образования имен переменных.';
				|vi = 'Tên phương thức ""%1"" không tương ứng với yêu cầu đặt tên biến.';
				|en = 'Method name ""%1"" does not meet variable naming conventions.'"),
			MethodName);
	EndTry;
	
	ExecuteParameters = Parameters.ExecuteParameters;
	If Parameters.IsExternalDataProcessor Then
		If ValueIsFilled(Parameters.AdditionalInformationProcessorRef) AND CommonUse.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
			ModuleAdditionalReportsAndDataProcessors = CommonUse.CommonModule("AdditionalReportsAndDataProcessors");
			DataProcessor = ModuleAdditionalReportsAndDataProcessors.GetObjectOfExternalDataProcessor(Parameters.AdditionalInformationProcessorRef);
		Else
			DataProcessor = ExternalDataProcessors.Create(Parameters.DataProcessorName);
		EndIf;
	Else
		DataProcessor = DataProcessors[Parameters.DataProcessorName].Create();
	EndIf;
	
	Execute("DataProcessor." + MethodName + "(ExecuteParameters, StorageAddress)");
	
EndProcedure

Function SubsystemName()
	Return "StandardSubsystems.LongActions";
EndFunction

Procedure ExecuteReportOrDataProcessorCommand(CommandParameters, ResultAddress) Export
	
	If CommandParameters.Property("AdditionalInformationProcessorRef")
		AND ValueIsFilled(CommandParameters.AdditionalInformationProcessorRef)
		AND CommonUse.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
		
		ModuleAdditionalReportsAndDataProcessors = CommonUse.CommonModule("AdditionalReportsAndDataProcessors");
		ModuleAdditionalReportsAndDataProcessors.RunCommand(CommandParameters, ResultAddress);
		
	Else
		
		Object = CommonUse.ObjectByDescriptionFull(CommandParameters.FullObjectName);
		Object.RunCommand(CommandParameters, ResultAddress);
		
	EndIf;
	
EndProcedure

#EndRegion

#Область InternalProceduresAndFunctions

// Запустить выполнение процедуры в фоновом задании, если это возможно.
// При выполнении любого из следующих условий запуск выполняется не в фоне, а сразу в основном потоке:
//  * если вызов выполняется в файловой базе во внешнем соединении (в этом режиме фоновые задания не поддерживаются);
//  * если приложение запущено в режиме отладки (параметр /C РежимОтладки) - для упрощения отладки конфигурации;
//  * если в файловой ИБ имеются активные фоновые задания - для снижения времени ожидания пользователя;
//  * если выполняется процедура модуля внешней обработки или внешнего отчета.
//
// Не следует использовать эту функцию, если необходимо безусловно запускать фоновое задание.
// Может применяться совместно с функцией ДлительныеОперацииКлиент.ОжидатьЗавершение.
// 
// Параметры:
//  ИмяПроцедуры           - Строка    - имя экспортной процедуры общего модуля, модуля менеджера объекта 
//                                       или модуля обработки, которую необходимо выполнить в фоне.
//                                       Например, "МойОбщийМодуль.МояПроцедура", "Отчеты.ЗагруженныеДанные.Сформировать"
//                                       или "Обработки.ЗагрузкаДанных.МодульОбъекта.Загрузить". 
//                                       У процедуры должно быть два или три формальных параметра:
//                                        * Параметры       - Структура - произвольные параметры ПараметрыПроцедуры;
//                                        * АдресРезультата - Строка    - адрес временного хранилища, в которое нужно
//                                          поместить результат работы процедуры. Обязательно;
//                                        * АдресДополнительногоРезультата - Строка - если в ПараметрыВыполнения установлен 
//                                          параметр ДополнительныйРезультат, то содержит адрес дополнительного временного
//                                          хранилища, в которое нужно поместить результат работы процедуры. Опционально.
//                                       При необходимости выполнить в фоне функцию ее следует обернуть в процедуру,
//                                       а ее результат возвращать через второй параметр АдресРезультата.
//  ПараметрыПроцедуры     - Структура - произвольные параметры вызова процедуры ИмяПроцедуры.
//  ПараметрыВыполнения    - Структура - см. функцию ДлительныеОперации.ПараметрыВыполненияВФоне.
//
// Returns:
//  Structure              - параметры выполнения задания: 
//   * Status               - String - "Выполняется", если задание еще не завершилось;
//                                     "Выполнено", если задание было успешно выполнено;
//                                     "Ошибка", если задание завершено с ошибкой;
//                                     "Отменено", если задание отменено пользователем или администратором.
//   * JobID - UUID - если Статус = "Выполняется", то содержит 
//                                     идентификатор запущенного фонового задания.
//   * ResultAddress       - String - адрес временного хранилища, в которое будет
//                                     помещен (или уже помещен) результат работы процедуры.
//   * AdditionalResultAddress - String - если установлен параметр ДополнительныйРезультат, 
//                                     содержит адрес дополнительного временного хранилища,
//                                     в которое будет помещен (или уже помещен) результат работы процедуры.
//   * ShortErrorDescription   - String - краткая информация об исключении, если Статус = "Ошибка".
//   * DetailErrorDescription - String - подробная информация об исключении, если Статус = "Ошибка".
// 
// Пример:
//  В общем виде процесс запуска и обработки результата длительной операции выглядит следующим образом:
//
//   1) Процедура, которая будет исполняться в фоне, располагается в модуле менеджера объекта или в серверном общем модуле:
//    Процедура ВыполнитьДействие(Параметры, АдресРезультата) Экспорт
//     ...
//     ПоместитьВоВременноеХранилище(Результат, АдресРезультата);
//    КонецПроцедуры
//
//   2) Запуск операции на сервере и подключение обработчика ожидания:
//    &НаКлиенте
//    Процедура ВыполнитьДействие()
//     ДлительнаяОперация = НачатьВыполнениеНаСервере();
//     ПараметрыОжидания = ДлительныеОперацииКлиент.ПараметрыОжидания(ЭтотОбъект);
//     ...
//     ОповещениеОЗавершении = Новый ОписаниеОповещения("ВыполнитьДействиеЗавершение", ЭтотОбъект);
//     ДлительныеОперацииКлиент.ОжидатьЗавершение(ДлительнаяОперация, ОповещениеОЗавершении, ПараметрыОжидания);
//    КонецПроцедуры
//
//    &НаСервере
//    Функция НачатьВыполнениеНаСервере()
//     ПараметрыПроцедуры = Новый Структура;
//     ...
//     ПараметрыВыполнения = ДлительныеОперации.ПараметрыВыполненияВФоне(УникальныйИдентификатор);
//     ...
//     Возврат ДлительныеОперации.ВыполнитьВФоне("Обработки.МояОбработка.ВыполнитьДействие", 
//     ПараметрыПроцедуры, ПараметрыВыполнения);
//    КонецФункции
//    
//   3) Обработка результата выполнения операции:
//    &НаКлиенте
//    Процедура ВыполнитьДействиеЗавершение(Результат, ДополнительныеПараметры) Экспорт
//     Если Результат = Неопределено Then
//      Возврат;
//     КонецЕсли;
//     ВывестиРезультат(Результат);
//    КонецПроцедуры 
//  
Function ExecuteBackground(Val ProcedureName, Val ProcedureParameters, Val CompletingParameters)  Export
	
	CommonUseClientServer.CheckParameter("LongOperations.ExecuteBackground", 
		"CompletingParameters", 
		CompletingParameters, Type("Structure")); 
		
	If CompletingParameters.RunNotInBackground And CompletingParameters.RunBackground Then
		Raise NStr("ru = 'Параметры ""ВсегдаНеВФоне"" и ""ВсегдаВФоне"" не могут одновременно принимать значение True в ДлительныеОперации.ВыполнитьВФоне.;
			| en = 'Parameters ""AlwaysNotBackground"" and ""AlwaysBackground"" cannot simultaneously accept the value True in LongOperations.ExecuteBackground' ");
EndIf;

#If ExternalConnection Then
	FileDB = CommonUse.FileInfobase();
	If CompletingParameters.WithoutExtensions And FileDB Then
		Raise NStr("en='The background task cannot be started with the parameter ""Without Extensions"" in the file infobase in LongOperations.ExecuteBackground.';ru='Фоновое задание не может быть запущено с параметром ""WithoutExtensions"" в файловой информационной базе в ДлительныеОперации.ВыполнитьВФоне.';vi='Không thể khởi động nhiệm vụ nền với tham số ""WithoutExtensions"" tại cơ sở thông tin File-server trong в ДлительныеОперации.ВыполнитьВФоне.'");
	EndIf;
#EndIf
	
	ResultAddress = ?(CompletingParameters.ResultAddress <> Undefined, 
	    CompletingParameters.ResultAddress,
		PutToTempStorage(Undefined, CompletingParameters.FormID));
	
	Result = New Structure;
	Result.Insert("Status",    "Perfoming");
	Result.Insert("JobID", Undefined);
	Result.Insert("ResultAddress", ResultAddress);
	Result.Insert("AdditionalResultAddress", "");
	Result.Insert("ShortErrorDescription", "");
	Result.Insert("DetailedErrorDescription", "");
	Result.Insert("Messages", New FixedArray(New Array));
	
	If CompletingParameters.WithoutExtensions Then
		CompletingParameters.WithoutExtensions = ValueIsFilled(SessionParameters.ПодключенныеРасширения);
	EndIf;
	
	ExportProcedureParameters = New Array;
	ExportProcedureParameters.Add(ProcedureParameters);
	ExportProcedureParameters.Add(ResultAddress);
	
	If CompletingParameters.AdditionalResult Then
		Result.AdditionalResultAddress = PutToTempStorage(Undefined, CompletingParameters.FormID);
		ExportProcedureParameters.Add(Result.AdditionalResultAddress);
	EndIf;
	
#If ExternalConnection Then
	ExecuteWithoutBackgroundJob = FileDB
		Or CompletingParameters.RunNotInBackground
		Or (BackgroundJobsExistInFileDB() And Not CompletingParameters.RunBackground) 
		Or Not BackgroundExecuteAvailable(ProcedureName);
#Else
	ExecuteWithoutBackgroundJob = Not CompletingParameters.WithoutExtensions
		And (CompletingParameters.RunNotInBackground
			Or (BackgroundJobsExistInFileDB() And Not CompletingParameters.RunBackground) 
			Or Not BackgroundExecuteAvailable(ProcedureName));
#EndIf

	// Выполнить в основном потоке.
	If ExecuteWithoutBackgroundJob Then
		Try
			ExecuteProcedure(ProcedureName, ExportProcedureParameters);
			Result.Status = "Completed";
		Except
			Result.Status = "Error";
			Result.ShortErrorDescription = BriefErrorDescription(ErrorInfo());
			Result.DetailedErrorDescription = DetailErrorDescription(ErrorInfo());
			WriteLogEvent(NStr("en='Runtime error';ru='Ошибка выполнения';vi='Lỗi thực hiện'", CommonUse.DefaultLanguageCode()),
				EventLogLevel.Error, , , Result.DetailedErrorDescription);
		EndTry;
		Return Result;
	EndIf;
	
	// Выполнить в фоне.
	Try
		Job = RunBackgroundJobWithClientContext(ProcedureName, CompletingParameters, ExportProcedureParameters);
	Except
		Result.Status = "Error";
		If Job <> Undefined And Job.ErrorInfo <> Undefined Then
			Result.ShortErrorDescription = BriefErrorDescription(Job.ErrorInfo);
			Result.DetailedErrorDescription = DetailErrorDescription(Job.ErrorInfo);
		Else
			Result.ShortErrorDescription = BriefErrorDescription(ErrorInfo());
			Result.DetailedErrorDescription = DetailErrorDescription(ErrorInfo());
		EndIf;
		Return Result;
	EndTry;
	
	If Job <> Undefined And Job.ErrorInfo <> Undefined Then
		Result.Status = "Error";
		Result.ShortErrorDescription = BriefErrorDescription(Job.ErrorInfo);
		Result.DetailedErrorDescription = DetailErrorDescription(Job.ErrorInfo);
		Return Result;
	EndIf;
	
	Result.JobID = Job.UUID;
	JobCompleted = False;
	
	If CompletingParameters.WaitForCompletion <> 0 Then
		Try
			Job.WaitForCompletion(CompletingParameters.WaitForCompletion);
			JobCompleted = True;
		Except
			// Специальная обработка не требуется, возможно исключение вызвано истечением времени ожидания.
		EndTry;
	EndIf;
	
	If JobCompleted Then
		ProgressAndMessage = ReadProgressAndMessages(Job.UUID, "ProgressAndMessage");
		Result.Messages = ProgressAndMessage.Messages;
	EndIf;
	
	FillPropertyValues(Result, OperationPerfomed(Job.UUID), , "Messages");
	Return Result;
	
EndFunction

Function OperationComplete(Val Jobs) Export
	
	Result = New Map;
	For Each Job In Jobs Do
		Result.Insert(Job.JobID, 
			OperationPerfomed(Job.JobID, False, Job.ShowProgress, Job.ShowMessages));
	EndDo;
	Return Result;
	
EndFunction

Function RunBackgroundJobWithClientContext(ProcedureName,
	CompletingParameters, ProcedureParameters = Undefined) Export
	
	BackgroundJobKey = CompletingParameters.BackgroundJobKey;
	BackgroundJobDescription = ?(IsBlankString(CompletingParameters.BackgroundJobDescription),
		ProcedureName, CompletingParameters.BackgroundJobDescription);
		
	AllParameters = New Structure;
	AllParameters.Insert("ProcedureName",       ProcedureName);
	AllParameters.Insert("ProcedureParameters", ProcedureParameters);
	AllParameters.Insert("ClientParametersAtServer", StandardSubsystemsServer.ClientParametersOnServer());
	
	BackgroundJobProcedureParameters = New Array;
	BackgroundJobProcedureParameters.Add(AllParameters);
	
	Return RunBackgroundJob(CompletingParameters,
		"LongActions.ExecuteWithClientContext", BackgroundJobProcedureParameters,
		BackgroundJobKey, BackgroundJobDescription);
	
EndFunction

// Продолжение процедуры ЗапуститьФоновоеЗаданиеСКонтекстомКлиента.
Procedure ExecuteWithClientContext(AllParameters) Export
	
	SetPrivilegedMode(True);
	If AccessRight("Set", Metadata.SessionParameters.ClientParametersOnServer) Then
		SessionParameters.ClientParametersOnServer = AllParameters.ClientParametersAtServer;
	EndIf;
	
	SetPrivilegedMode(False);
	
	ExecuteProcedure(AllParameters.ProcedureName, AllParameters.ProcedureParameters);
	
EndProcedure

Procedure ExecuteProcedure(ProcedureName, ProcedureParameters)
	
	NamePart = StrSplit(ProcedureName, ".");
	ItProcedureProcessorModule = (NamePart.Count() = 4) And Upper(NamePart[2]) = "ObjectModule";
	If Not ItProcedureProcessorModule Then
		CommonUse.ExecuteConfigurationMethod(ProcedureName, ProcedureParameters);
		Return;
	EndIf;
	
	ItProcessor = Upper(NamePart[0]) = "Processor";
	ItReport = Upper(NamePart[0]) = "Report";
	If ItProcessor Or ItReport Then
		ObjectManager = ?(ItReport, Reports, DataProcessors);
		DataProcessorReportObject = ObjectManager[NamePart[1]].Create();
		CommonUse.ExecuteObjectMethod(DataProcessorReportObject, NamePart[3], ProcedureParameters);
		Return;
	EndIf;
	
	ItExternalProcessor = Upper(NamePart[0]) = "ExternalProcessor";
	ItExternalReport = Upper(NamePart[0]) = "ExternalReport";
	If ItExternalProcessor Or ItExternalReport Then
		VerifyAccessRights("InteractiveOpenExternalReportsAndDataProcessors", Metadata);
		ObjectManager = ?(ItExternalReport, ExternalReports, ExternalDataProcessors);
		DataProcessorReportObject = ObjectManager.Create(NamePart[1], SafeMode());
		CommonUse.ExecuteObjectMethod(DataProcessorReportObject, NamePart[3], ProcedureParameters);
		Return;
	EndIf;
	
	Raise StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en='Invalid format for the parameter ProcedureName (passed value: %1)';ru='Неверный формат параметра ProcedureName (переданное значение: %1)';vi='Sai định dạng tham số ProcedureName (giá trị đã truyền: %1)'"), ProcedureName);
	
EndProcedure

// Считывает информацию о ходе выполнения фонового задания и сообщения, которые в нем были сформированы.
//
// Параметры:
//   ИдентификаторЗадания - УникальныйИдентификатор - идентификатор фонового задания.
//   Режим                - Строка - "ПрогрессИСообщения", "Прогресс" или "Сообщения".
//
// Returns:
//   Structure - со свойствами:
//    * Progress  - Undefined, Structure - Информация о ходе выполнения фонового задания, записанная процедурой СообщитьПрогресс:
//     ** Percent                 - Number  - Необязательный. Процент выполнения.
//     ** Text                   - String - Необязательный. Информация о текущей операции.
//     ** AdditionalParameters - Arbitrary - Необязательный. Любая дополнительная информация.
//    * Messages - FixedArray - Массив объектов СообщениеПользователю, которые были сформированы в фоновом задании.
//
Function ReadProgressAndMessages(Val JobID, Val Mode = "ProgressAndMessage")
	
	Messages = New FixedArray(New Array);
	Result = New Structure("Messages, Progress", Messages, Undefined);
	
	Job = BackgroundJobs.FindByUUID(JobID);
	If Job = Undefined Then
		Return Result;
	EndIf;
	
	MessageArray = Job.GetUserMessages(True);
	If MessageArray = Undefined Then
		Return Result;
	EndIf;
	
	Count = MessageArray.Count();
	Messages = New Array;
	ReadMessage = (Mode = "ProgressAndMessage" Or Mode = "Messages"); 
	ReadProgress  = (Mode = "ProgressAndMessage" Or Mode = "Progress"); 
	
	If ReadMessage And Not ReadProgress Then
		Result.Messages = New FixedArray(MessageArray);
		Return Result;
	EndIf;
	
	For Number = 0 To Count - 1 Do
		Message = MessageArray[Number];
		
		If ReadProgress And StrStartsWith(Message.Text, "{") Then
			Position = StrFind(Message.Text, "}");
			If Position > 2 Then
				MechanismID = Mid(Message.Text, 2, Position - 2);
				If MechanismID = ProgressMessage() Then
					ReceivedText = Mid(Message.Text, Position + 1);
					Result.Progress = CommonUse.ValueFromXMLString(ReceivedText);
					Continue;
				EndIf;
			EndIf;
		EndIf;
		If ReadMessage Then
			Messages.Add(Message);
		EndIf;
	EndDo;
	
	Result.Messages = New FixedArray(Messages);
	Return Result;
	
EndFunction

Function BackgroundJobsExistInFileDB()
	
	BackgroundJobLaunched = 0;
	If CommonUse.FileInfobase() And Not InfobaseUpdate.InfobaseUpdateRequired() Then
		Filter = New Structure;
		Filter.Insert("State", BackgroundJobState.Active);
		BackgroundJobLaunched = BackgroundJobs.GetBackgroundJobs(Filter).Count();
	EndIf;
	Return BackgroundJobLaunched > 0;

EndFunction

Function BackgroundExecuteAvailable(ProcedureName)
	
	NamePart = StrSplit(ProcedureName, ".");
	If NamePart.Count() = 0 Then
		Return False;
	EndIf;
	
	ItExternalProcessor = (Upper(NamePart[0]) = "ExternalProcessor");
	ItExternalReport = (Upper(NamePart[0]) = "ExternalReport");
	Return Not (ItExternalProcessor Or ItExternalReport);

EndFunction

Function RunBackgroundJob(CompletingParameters, MethodName, Parameters, Key, Description)
	
	If CurrentRunMode() = Undefined
		And CommonUse.FileInfobase() Then
		
		Session = GetCurrentInfoBaseSession();
		If CompletingParameters.WaitForCompletion = Undefined And Session.ApplicationName = "BackgroundJob" Then
			Raise NStr("en='In a file infobase, it is impossible to simultaneously execute more than one background job';ru='В файловой информационной базе невозможно одновременно выполнять более одного фонового задания';vi='Trong cơ sở thông tin File-server không thể thực hiện đồng thời hơn một nhiệm vụ nền'");
		ElsIf Session.ApplicationName = "COMConnection" Then
			Raise NStr("en='In the file database, you can run only the background application.';ru='В файловой информационной базе можно запустить фоновое задание только из клиентского приложения';vi='Trong cơ sở dữ liệu tệp, bạn chỉ có thể chạy ứng dụng nền.'");
		EndIf;
		
	EndIf;
	
	If CompletingParameters.WithoutExtensions Then
		Return ConfigurationExtensions.ExecuteBackgroundJobWithoutExtensions(MethodName, Parameters, Key, Description);
	Else
		Return BackgroundJobs.Execute(MethodName, Parameters, Key, Description);
	EndIf;
	
EndFunction

Function OperationPerfomed(Val JobID, Val ErrorException = False, Val ShowExecutingProgress = False, 
	Val ShowMessages = False) Export
	
	Result = New Structure;
	Result.Insert("Status", "Perfoming");
	Result.Insert("ShortErrorDescription", Undefined);
	Result.Insert("DetailedErrorDescription", Undefined);
	Result.Insert("Progress", Undefined);
	Result.Insert("Messages", Undefined);
	
	Job = FindJobByID(JobID);
	If Job = Undefined Then
		Explanation = NStr("en='Operation failed due to abnormal completion of background job. Background job not found';ru='Операция не выполнена из-за аварийного завершения фонового задания.Фоновое задание не найдено';vi='Hoạt động không thành công do hoàn thành bất thường của công việc nền. Không tìm thấy công việc nền'") + ": " + String(JobID);
		WriteLogEvent(NStr("en='Operation failed due to abnormal completion of background job. Background job not found';ru='Операция не выполнена из-за аварийного завершения фонового задания.Фоновое задание не найдено';vi='Chưa thực hiện giao dịch do hoạt động bất thường của nhiệm vụ nền. Không tìm thấy nhiệm vụ nền'", CommonUse.DefaultLanguageCode()),
			EventLogLevel.Error, , , Explanation);
		If ErrorException Then
			Raise(NStr("en='Failed to perform this operation.';ru='Не удалось выполнить данную операцию.';vi='Không thể thực hiện thao tác này.'"));
		EndIf;
		Result.Status = "Error";
		Result.ShortErrorDescription = NStr("en='Operation failed due to abnormal completion of background job';ru='Операция не выполнена из-за аварийного завершения фонового задания.';vi='Hoạt động thất bại do hoàn thành bất thường của công việc nền.'");
		Return Result;
	EndIf;
	
	If ShowExecutingProgress Then
		ProgressAndMessage = ReadProgressAndMessages(JobID, ?(ShowMessages, "ProgressAndMessage", "Progress"));
		Result.Progress = ProgressAndMessage.Progress;
		If ShowMessages Then
			Result.Messages = ProgressAndMessage.Messages;
		EndIf;
	ElsIf ShowMessages Then
		Result.Messages = Job.GetUserMessages(True);
	EndIf;
	
	If Job.State = BackgroundJobState.Active Then
		Return Result;
	EndIf;
	
	If Job.State = BackgroundJobState.Canceled Then
		SetPrivilegedMode(True);
		If SessionParameters.CanceledLongOperations.Find(JobID) = Undefined Then
			Result.Status = "Error";
			If Job.ErrorInfo <> Undefined Then
				Result.ShortErrorDescription   = NStr("en='Operation canceled by administrator';ru='Операция отменена администратором.';vi='Các hoạt động đã bị hủy bởi các quản trị viên.'");
				Result.DetailedErrorDescription = Result.ShortErrorDescription;
			EndIf;
			If ErrorException Then
				If Not IsBlankString(Result.ShortErrorDescription) Then
					MessageText = Result.ShortErrorDescription;
				Else
					MessageText = NStr("en='Failed to perform this operation.';ru='Не удалось выполнить данную операцию.';vi='Không thể hoàn thành thao tác này.'");
				EndIf;
				Raise MessageText;
			EndIf;
		Else
			Result.Status = "Canceled";
		EndIf;
		SetPrivilegedMode(False);
		Return Result;
	EndIf;
	
	If Job.State = BackgroundJobState.Failed 
		Or Job.State = BackgroundJobState.Canceled Then
		
		Result.Status = "Error";
		If Job.ErrorInfo <> Undefined Then
			Result.ShortErrorDescription   = BriefErrorDescription(Job.ErrorInfo);
			Result.DetailedErrorDescription = DetailErrorDescription(Job.ErrorInfo);
		EndIf;
		If ErrorException Then
			If Not IsBlankString(Result.ShortErrorDescription) Then
				MessageText = Result.ShortErrorDescription;
			Else
				MessageText = NStr("en='Failed to perform this operation.';ru='Не удалось выполнить данную операцию.';vi='Không thể thực hiện thao tác này.'");
			EndIf;
			Raise MessageText;
		EndIf;
		Return Result;
	EndIf;
	
	Result.Status = "Completed";
	Return Result;
	
EndFunction

Function ProgressMessage() Export
	Return "StandartSubsystems.LongOperations";
EndFunction

// Отменяет выполнение фонового задания по переданному идентификатору.
// При этом если в длительной операции открывались транзакции, то будет произведен откат последней открытой транзакции.
//
// Таким образом, если длительная операция выполняет обработку (запись) данных, то для полной отмены всей операции
// следует выполнять запись в одной транзакции (в таком случае, будет отменена вся транзакция целиком).
// Если же достаточно, чтобы длительная операция была не отменена целиком, а прервана на достигнутом этапе,
// то, напротив, открывать одну длинную транзакцию не требуется.
// 
// Параметры:
//  ИдентификаторЗадания - УникальныйИдентификатор - идентификатор фонового задания, полученный при запуске 
//                                                   длительной операции. См. ДлительныеОперации.ВыполнитьВФоне.
// 
Procedure CancelJobExecuting(Val JobID) Export 
	
	If Not ValueIsFilled(JobID) Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	If SessionParameters.CanceledLongOperations.Find(JobID) = Undefined Then
		CanceledLongOperations = New Array(SessionParameters.CanceledLongOperations);
		CanceledLongOperations.Add(JobID);
		SessionParameters.CanceledLongOperations = New FixedArray(CanceledLongOperations);
	EndIf;
	SetPrivilegedMode(False);
	
	Job = FindJobByID(JobID);
	If Job = Undefined	Or Job.State <> BackgroundJobState.Active Then
		Return;
	EndIf;
	
	Try
		Job.Cancel();
	Except
		// Возможно задание как раз в этот момент закончилось и ошибки нет.
		WriteLogEvent(NStr("en='Long operations: Cancel a background job';ru='Длительные операции.Отмена выполнения фонового задания';vi='Hoạt động lâu: Hủy công việc nền'", CommonUse.DefaultLanguageCode()),
			EventLogLevel.Information, , , BriefErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

Function GeneralBacgroundExecutionParameters()
	
	Result = New Structure;
	Result.Insert("WaitForCompletion", ?(GetClientConnectionSpeed() = ClientConnectionSpeed.Low, 4, 0.8));
	Result.Insert("BackgroundJobDescription", "");
	Result.Insert("BackgroundJobKey", "");
	Result.Insert("RunNotInBackground", False);
	Result.Insert("RunBackground", False);
	Result.Insert("WithoutExtensions", False);
	
	Return Result;
	
EndFunction

Procedure AddExecutionParametersForResultReturning(Parameters, FormID)
	
	Parameters.Insert("FormID", FormID); 
	Parameters.Insert("ResultAddress", Undefined);
	
EndProcedure

#КонецОбласти

