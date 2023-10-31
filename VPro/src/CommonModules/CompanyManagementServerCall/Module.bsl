
#Region ProgramInterface

Function ServerDate() Export
	
	Return CurrentDate();
	
EndFunction

Function SessionDate() Export
	
	Return CurrentSessionDate();
	
EndFunction

// Функция формирует структуру с данными для печати на принтере этикеток.
Function PrepareLabelPrinterPriceTagsAndLabelDataStructure(Val Parameters, Val PrintManager, Size) Export
	
	PrintManager = CommonUse.ObjectManagerByFullName(PrintManager);
	
	Data = PrintManager.GetDataForLabelPrinter(Parameters);
	
	Result = New Array;
	
	For Each CurTemplate In Data Do
		
		If CurTemplate.Template.TemplateSize = Size Then
			
			Package = New Structure;
			Package.Insert("XML", CurTemplate.SpreadsheetDocument.XML);
			Package.Insert("Labels", New Array);
			
			For Each CurLabel In CurTemplate.SpreadsheetDocument.Labels Do
				
				NewLabel = New Structure;
				NewLabel.Insert("Quantity", CurLabel.Count);
				NewLabel.Insert("Fields", CurLabel.FieldValues);
				
				Package.Labels.Add(NewLabel);
				
			EndDo;
			
			Result.Add(Package);
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Возвращает значение функциональной опции по имени. Для использования на клиенте.
Function GetFunctionalOptionServer(NAME) Export
	
	Return GetFunctionalOption(NAME);
	
EndFunction

// Возвращает значение функциональной опции по имени. Для использования на клиенте.
Function GetConstantServer(NAME) Export
	
	Return Constants[NAME].Get();
	
EndFunction

// Возвращает структуру, содержащую значения реквизитов, прочитанные из информационной базы по ссылке на объект.
// Рекомендуется использовать вместо обращения к реквизитам объекта через точку от ссылки на объект
// для быстрого чтения отдельных реквизитов объекта из базы данных.
//
// Если необходимо зачитать реквизит независимо от прав текущего пользователя,
// то следует использовать предварительный переход в привилегированный режим.
//
// Parameters:
//  Ref    - AnyRef - объект, значения реквизитов которого необходимо получить.
//            - String      - полное имя предопределенного элемента, значения реквизитов которого необходимо получить.
//  Attributes - String - имена реквизитов, перечисленные через запятую, в формате
//                       требований к свойствам структуры.
//                       Например, "Код, Наименование, Родитель".
//            - Structure, FixedStructure - в качестве ключа передается
//                       псевдоним поля для возвращаемой структуры с результатом, а в качестве
//                       значения (опционально) фактическое имя поля в таблице.
//                       Если ключ задан, а значение не определено, то имя поля берется из ключа.
//            - Array, FixedArray - имена реквизитов в формате требований
//                       к свойствам структуры.
//  SelectAllowedItems - Boolean - если Истина, то запрос к объекту выполняется с учетом прав пользователя;
//                                если есть ограничение на уровне записей, то все реквизиты вернутся со 
//                                значением Неопределено; если нет прав для работы с таблицей, то возникнет исключение;
//                                если Ложь, то возникнет исключение при отсутствии прав на таблицу 
//                                или любой из реквизитов.
//
// Returns:
//  Structure - includes names (keys) and values of the requested attribute.
//            - если в параметр Реквизиты передана пустая строка, то возвращается пустая структура.
//            - если в параметр Ссылка передана пустая ссылка, то возвращается структура, 
//              соответствующая именам реквизитов со значениями Неопределено.
//            - если в параметр Ссылка передана ссылка несуществующего объекта (битая ссылка), 
//              то все реквизиты вернутся со значением Неопределено.
//
Function ObjectAttributesValues(Ref, Val Attributes, SelectAllowedItems = False) Export
	
	Return CommonUse.ObjectAttributesValues(Ref, Attributes, SelectAllowedItems);
	
EndFunction

// Returns attribute value read from the infobase using the object link.
// 
//  If there is no access to the attribute, access rights exception occurs.
//  Если необходимо зачитать реквизит независимо от прав текущего пользователя,
//  то следует использовать предварительный переход в привилегированный режим.
// 
// Parameters:
//  Ref       - ссылка на объект, - элемент справочника, документ, ...
//  AttributeName - String, for example, "Code".
// 
// Returns:
//  Arbitrary    - depends on the value type of read attribute.
// 
Function ObjectAttributeValue(Ref, AttributeName) Export
	
	Return CommonUse.ObjectAttributeValue(Ref, AttributeName);
	
EndFunction

// Возвращает значение счетчика открытия формы оценки мобильного клиента текущего устройства.
//
Function GetCounterToOpenMobileClientEvaluationForm() Export
	
	Return InformationRegisters.CounterForOpeningMobileClientAssessmentForm.GetValue();
	
EndFunction

// Устанавливает значение счетчика открытия формы оценки мобильного клиента.
//
Procedure SetCounterForOpeningMobileClientAssessmentForm(CounterValue) Export
	
	InformationRegisters.CounterForOpeningMobileClientAssessmentForm.SetValue(CounterValue);
	
EndProcedure

// Увеличивает значение счетчика запусков клиента.
//
Procedure IncreaseClientLaunchCounter(IsMobileClient) Export
	
	InformationRegisters.ClientLaunchCounter.IncrementCounter(IsMobileClient);
	
EndProcedure

// Получает значения счетчика запусков клиента.
//
Function GetClientStartsCounterValues() Export
	
	Return InformationRegisters.ClientLaunchCounter.GetCounterValues();
	
EndFunction

// SetsProhibitionOfOpenSurveyForm.
//
Procedure SetPollFormOpenRestriction(OpenPollProhibition) Export
	
	InformationRegisters.ClientLaunchCounter.SetPollFormOpenRestriction(OpenPollProhibition);
	
EndProcedure

Function GetKKTRegistrationParameters(CR) Export
	
	Return SmallBusinessServer.GetKKTRegistrationParameters(CR);
	
EndFunction

// Возвращает служебную информацию для письма о новых возможностях
//
Function ServiceInformationForEmail(Tag) Export
	
	Return DataProcessors.ApplicationSettings.ServiceInformationForEmail(Tag);
	
EndFunction

#EndRegion
