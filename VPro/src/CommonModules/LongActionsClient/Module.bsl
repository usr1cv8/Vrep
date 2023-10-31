////////////////////////////////////////////////////////////////////////////////
// The subsystem "Basic functionality".
// Long server operations work support in web client.
//  
////////////////////////////////////////////////////////////////////////////////

#Region ProgramInterface

// Fills the structure of parameters with default values.
// 
// Parameters:
//  IdleHandlerParameters - Structure - filled with default values. 
//
// 
Procedure InitIdleHandlerParameters(IdleHandlerParameters) Export
	
	IdleHandlerParameters = New Structure(
		"MinInterval,MaxInterval,CurrentInterval,IntervalIncreaseCoefficient", 1, 15, 1, 1.4);
	
EndProcedure

// Fills the structure of parameters with new calculated values.
// 
// Parameters:
//  IdleHandlerParameters - Structure - filled with calculated values. 
//
// 
Procedure UpdateIdleHandlerParameters(IdleHandlerParameters) Export
	
	IdleHandlerParameters.CurrentInterval = IdleHandlerParameters.CurrentInterval * IdleHandlerParameters.IntervalIncreaseCoefficient;
	If IdleHandlerParameters.CurrentInterval > IdleHandlerParameters.MaxInterval Then
		IdleHandlerParameters.CurrentInterval = IdleHandlerParameters.MaxInterval;
	EndIf;
		
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for working with long operation form.
//

// Opens the form indicating a long operation.
// 
// Parameters:
//  FormOwner  - ManagedForm - the form from which the opening is executed. 
//  JobID      - UUID        - The ID of the background job.
//
// Returns:
//  ManagedForm     - ref to the open form.
// 
Function OpenLongOperationForm(Val FormOwner, Val JobID) Export
	
	LongOperationForm = LongActionsClientReUse.LongOperationForm();
	If LongOperationForm.IsOpen() Then
		LongOperationForm = OpenForm(
			"CommonForm.LongOperation",
			New Structure("JobID", JobID), 
			FormOwner);
	Else
		LongOperationForm.FormOwner        = FormOwner;
		LongOperationForm.JobID = JobID;
		LongOperationForm.Open();
	EndIf;
	
	Return LongOperationForm;
	
EndFunction

// Closes the form indicating a long operation.
// 
// Parameters:
//  RefToForm - ManagedForm - ref to the form indicating a long operation. 
//
Procedure CloseLongOperationForm(LongOperationForm) Export
	
	If TypeOf(LongOperationForm) = Type("ManagedForm") Then
		If LongOperationForm.IsOpen() Then
			LongOperationForm.Close();
		EndIf;
	EndIf;
	LongOperationForm = Undefined;
	
EndProcedure

// Возвращает пустую структуру для параметра ПараметрыОжидания процедуры ДлительныеОперацииКлиент.ОжидатьЗавершение.
//
// Параметры:
//  ФормаВладелец - УправляемаяФорма, Неопределено - форма, из которой вызывается длительная операция.
//
// Возвращаемое значение:
//  Структура              - параметры выполнения задания: 
//   * ФормаВладелец          - УправляемаяФорма, Неопределено - форма, из которой вызывается длительная операция.
//   * ТекстСообщения         - Строка - текст сообщения, выводимый на форме ожидания.
//                                       Если не задан, то выводится "Пожалуйста, подождите...".
//   * ВыводитьОкноОжидания   - Булево - если True, то открыть окно ожидания с визуальной индикацией длительной операции. 
//                                       Если используется собственный механизм индикации, то следует указать Ложь.
//   * ВыводитьПрогрессВыполнения - Булево - выводить прогресс выполнения в процентах на форме ожидания.
//   * ОповещениеОПрогрессеВыполнения - ОписаниеОповещения - оповещение, которое периодически вызывается при 
//                                      проверке готовности фонового задания. Параметры процедуры-обработчика оповещения:
//     ** Прогресс - Структура, Неопределено - структура со свойствами или Неопределено, если задание было отменено. Свойства: 
//	     *** Статус               - Строка - "Выполняется", если задание еще не завершилось;
//                                           "Выполнено", если задание было успешно выполнено;
//	                                         "Ошибка", если задание завершено с ошибкой;
//                                           "Отменено", если задание отменено пользователем или администратором.
//	     *** ИдентификаторЗадания - УникальныйИдентификатор - идентификатор запущенного фонового задания.
//	     *** Прогресс             - Структура, Неопределено - результат функции ДлительныеОперации.ПрочитатьПрогресс, 
//                                                            если ВыводитьПрогрессВыполнения = True.
//	     *** Сообщения            - ФиксированныйМассив, Неопределено - если ВыводитьСообщения = True, массив объектов СообщениеПользователю, 
//                                  очередная порция сообщений, сформированных в процедуре-обработчике длительной операции.
//     ** ДополнительныеПараметры - Произвольный - произвольные данные, переданные в описании оповещения. 
//
//   * ВыводитьСообщения      - Булево - выводить в оповещения о завершении и прогресс сообщения, 
//                                       сформированные в процедуре-обработчике длительной операции.
//   * Интервал               - Число  - интервал в секундах между проверками готовности длительной операции.
//                                       По умолчанию 0 - после каждой проверки интервал увеличивается с 1 до 15 секунд
//                                       с коэффициентом 1.4.
//   * ОповещениеПользователя - Структура - содержит свойства:
//     ** Показать            - Булево - если True, то по завершении длительной операции вывести оповещение пользователя.
//     ** Текст               - Строка - текст оповещения пользователя.
//     ** НавигационнаяСсылка - Строка - навигационная ссылка оповещения пользователя.
//     ** Пояснение           - Строка - пояснение оповещения пользователя.
//   
//   * ПолучатьРезультат - Булево - Служебный параметр. Не предназначен для использования.
//

Function WaitingParameters(OwnerForm) Export
	
	Result = New Structure;
	Result.Insert("OwnerForm", OwnerForm);
	Result.Insert("MessageText", "");
	Result.Insert("ShowWaitingWindow", True);
	Result.Insert("ShowProgress", False);
	Result.Insert("ProgressNotification", Неопределено);
	Result.Insert("ShowMessages", False);
	Result.Insert("Interval", 0);
	Result.Insert("GetResult", False);
	
	UserNotification = New Structure;
	UserNotification.Insert("Show", False);
	UserNotification.Insert("Text", Undefined);
	UserNotification.Insert("NavigationRef", Неопределено);
	UserNotification.Insert("Explanation", Неопределено);
	Result.Insert("UserNotification", UserNotification);
	
	Return Result;
	
EndFunction

Procedure WaitForCompletion(Val LongOperation, Val CompletionNotification = Undefined, 
	Val WaitingParameters = Undefined) Export
	
	CheckParametersWaitCompletion(LongOperation, CompletionNotification, WaitingParameters);
	
	If LongOperation.Status <> "Running" Then
		If CompletionNotification <> Undefined Then
			If LongOperation.Status <> "Canceled" Then
				Result = New Structure;
				Result.Insert("Status", LongOperation.Status);
				Result.Insert("ResultAddress", LongOperation.ResultAddress);
				Result.Insert("AdditionalResultAddress", LongOperation.AdditionalResultAddress);
				Result.Insert("ShortErrorDescription", LongOperation.ShortErrorDescription);
				Result.Insert("DetailedErrorDescription", LongOperation.DetailedErrorDescription);
				Result.Insert("Messages", ?(WaitingParameters <> Undefined And WaitingParameters.ShowMessages, 
					LongOperation.Messages, Undefined));
			Else
				Result = Undefined;
			EndIf;
			
			If LongOperation.Status = "Completed" И WaitingParameters <> Undefined Then
				ShowNotification(WaitingParameters.UserNotification);
			EndIf;
			ExecuteNotifyProcessing(CompletionNotification, Result);
		EndIf;
		Return;
	EndIf;
	
	FormParameters = WaitingParameters(Undefined);
	If WaitingParameters <> Undefined Then
		FillPropertyValues(FormParameters, WaitingParameters);
	EndIf;
	FormParameters.Insert("ResultAddress", LongOperation.ResultAddress);
	FormParameters.Insert("AdditionalResultAddress", LongOperation.AdditionalResultAddress);
	FormParameters.Insert("JobID", LongOperation.JobID);
	
	If FormParameters.ShowWaitingWindow Then
		FormParameters.Delete("OwnerForm");
		
		ОткрытьФорму("CommonForm.LongOperation", FormParameters, 
			?(WaitingParameters <> Undefined, WaitingParameters.ФормаВладелец, Undefined),
			,,,CompletionNotification);
	Else
		FormParameters.Insert("ClosingNotification", CompletionNotification);
		FormParameters.Insert("CurrentInterval", ?(FormParameters.Interval <> 0, FormParameters.Interval, 1));
		FormParameters.Insert("Control", CurrentDate() + FormParameters.CurrentInterval); // дата сеанса не используется
		
		Operations = ActiveLongOperations();
		Operations.List.Insert(FormParameters.JobID, FormParameters);
		
		AttachIdleHandler("LongOperationsControl", FormParameters.CurrentInterval, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region ServiceMethods

Function ActiveLongOperations() Export
	
	ParameterName = "StandardSubsystems.ActiveLongOperations";
	If ApplicationParameters[ParameterName] = Undefined Then
		Operations = New Structure("Processing,List", False, New Map);
		ApplicationParameters.Insert(ParameterName, Operations);
	EndIf;
	Return ApplicationParameters[ParameterName];

EndFunction

Procedure  CheckParametersWaitCompletion(Val LongOperation, Val CompletionNotification, Val WatingParameters)
	
	CommonUseClientServer.CheckParameter("LongActionsClient.WaitForCompletion",
		"LongOperation", LongOperation, Type("Structure"));
	
	If CompletionNotification <> Undefined Then
		CommonUseClientServer.CheckParameter("LongActionsClient.WaitForCompletion",
			"ClosingNotification", CompletionNotification, Type("NotifyDescription"));
	EndIf;
	
	If WatingParameters <> Undefined Then
		
		AttributesTypes = New Structure;
		Если WatingParameters.OwnerForm <> Undefined Then
			AttributesTypes.Insert("OwnerForm", Type("ManagedForm"));
		EndIf;
		AttributesTypes.Insert("MessageText", Type("String"));
		AttributesTypes.Insert("ShowWaitingWindow", Type("Boolean"));
		AttributesTypes.Insert("ShowProgress", Type("Boolean"));
		AttributesTypes.Insert("ShowMessages", Type("Boolean"));
		AttributesTypes.Insert("Interval", Type("Number"));
		AttributesTypes.Insert("UserNotification", Type("Structure"));
		AttributesTypes.Insert("GetResult", Type("Boolean"));
		
		CommonUseClientServer.CheckParameter("LongActionsClient.WaitForCompletion",
			"WatingParameters", WatingParameters, Type("Structure"), AttributesTypes);
		
		CommonUseClientServer.Validate(WatingParameters.Interval = 0 Или WatingParameters.Interval >= 1, 
			НСтр("en = 'Parameter WaitingParameters. The interval must be greater than or equal to 1'; ru = 'Параметр ПараметрыОжидания.Интервал должен быть больше или равен 1'; vi = 'Tham số WaitingParameters. Khoảng phải lớn hơn hoặc bằng 1'"),
			"LongActionsClient.WaitForCompletion");
			
		CommonUseClientServer.Validate(Не (WatingParameters.ProgressNotification <> Undefined И WatingParameters.ShowWaitingWindow), 
			НСтр("en='If the WaitingParameters.ShowWaitingWindow parameter is set to True, then the WaitingParameters.ProgressNotification is not supported';ru='Если параметр ПараметрыОжидания.ВыводитьОкноОжидания установлен в True, то параметр ПараметрыОжидания.ОповещениеОПрогрессеВыполнения не поддерживается';vi='Nếu tham số WaitingParameters.ShowWaitingWindow được đặt thành True, thì tham số WaitingParameters.ProgressNotification không được hỗ trợ'"),
			"LongActionsClient.WaitForCompletion");
	EndIf;

EndProcedure

Procedure ShowNotification(UserNotification) Export
	
	Notification = UserNotification;
	Если Не Notification.Show Then
		Return;
	EndIf;
	
	ShowUserNotification(?(Notification.Text <> Undefined, Notification.Текст, НСтр("en='Action completed';ru='Действие выполнено';vi='Đã thực hiện thao tác'")), 
		Notification.НавигационнаяСсылка, Notification.Explanation);

EndProcedure

#EndRegion

