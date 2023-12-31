////////////////////////////////////////////////////////////////////////////////
// MESSAGE CHANNEL HANDLER FOR VERSION 2.1.2.1
//  DATA EXCHANGE CONTROL MESSAGE INTERFACE
//
////////////////////////////////////////////////////////////////////////////////

#Region ProgramInterface

// Returns namespace for message interface version
Function Package() Export
	
	Return "http://www.1c.ru/SaaS/Exchange/Control";
	
EndFunction

// Returns a message interface version served by the handler
Function Version() Export
	
	Return "2.1.2.1";
	
EndFunction

// Returns default type for version messages
Function BaseType() Export
	
	Return MessagesSaaSReUse.TypeBody();
	
EndFunction

// Processes incoming messages in service model
//
// Parameters:
//  Message - ObjectXDTO, incoming message,
//  Sender - ExchangePlanRef.Messaging, exchange plan node, corresponding to message sender 
//  MessageProcessed - Boolean, a flag showing that the message is successfully processed. The value of
//    this parameter shall be set to True if the message was successfully read in this handler
//
Procedure ProcessSaaSMessage(Val Message, Val Sender, MessageHandled) Export
	
	MessageHandled = True;
	
	Dictionary = MessageControlDataExchangeInterface;
	MessageType = Message.Body.Type();
	
	If MessageType = Dictionary.MessageExchangeSettingStep1CompletedSuccessfully(Package()) Then
		
		SettingExchangeStep1SuccessfullyCompleted(Message, Sender);
		
	ElsIf MessageType = Dictionary.MessageExchangeSettingStep2CompletedSuccessfully(Package()) Then
		
		ExchangeSettingStep2CompletedSuccessfully(Message, Sender);
		
	ElsIf MessageType = Dictionary.MessageExchangeSettingErrorStep1(Package()) Then
		
		ExchangeSettingErrorStep1(Message, Sender);
		
	ElsIf MessageType = Dictionary.MessageExchangeSettingErrorStep2(Package()) Then
		
		ExchangeSettingErrorStep2(Message, Sender);
		
	ElsIf MessageType = Dictionary.MessageExchangeMessageImportingCompletedSuccessfully(Package()) Then
		
		ImportMessageExchangeSuccessfullyCompleted(Message, Sender);
		
	ElsIf MessageType = Dictionary.MessageExchangeMessageImportingError(Package()) Then
		
		ExchangeMessageImportingError(Message, Sender);
		
	ElsIf MessageType = Dictionary.MessageCorrespondentDataGettingCompletedSuccessfully(Package()) Then
		
		CorrespondentDataGettingCompletedSuccessfully(Message, Sender);
		
	ElsIf MessageType = Dictionary.MessageCorrespondentNodesCommonDataGettingCompletedSuccessfully(Package()) Then
		
		CorrespondentNodesCommonDataGettingCompletedSuccessfully(Message, Sender);
		
	ElsIf MessageType = Dictionary.MessageCorrespondentDataGettingError(Package()) Then
		
		CorrespondentDataGettingError(Message, Sender);
		
	ElsIf MessageType = Dictionary.MessageCorrespondentNodesCommonDataGettingError(Package()) Then
		
		CorrespondentNodesCommonDataGettingError(Message, Sender);
		
	ElsIf MessageType = Dictionary.MessageCorrespondentAccountingParametersGettingCompletedSuccessfully(Package()) Then
		
		CorrespondentAccountingParametersGettingCompletedSuccessfully(Message, Sender);
		
	ElsIf MessageType = Dictionary.MessageCorrespondentAccountingParametersGettingError(Package()) Then
		
		CorrespondentAccountingParametersGettingError(Message, Sender);
		
	Else
		
		MessageHandled = False;
		Return;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

// exchange setup

Procedure SettingExchangeStep1SuccessfullyCompleted(Message, Sender)
	
	DataExchangeSaaS.FixSuccessfullSessionCompletion(Message, RepresentationSynchronizationSettingStep1());
	
EndProcedure

Procedure ExchangeSettingStep2CompletedSuccessfully(Message, Sender)
	
	DataExchangeSaaS.FixSuccessfullSessionCompletion(Message, RepresentationSynchronizationSettingStep2());
	
EndProcedure

Procedure ExchangeSettingErrorStep1(Message, Sender)
	
	DataExchangeSaaS.FixUnsuccessfullSessionCompletion(Message, RepresentationSynchronizationSettingStep1());
	
EndProcedure

Procedure ExchangeSettingErrorStep2(Message, Sender)
	
	DataExchangeSaaS.FixUnsuccessfullSessionCompletion(Message, RepresentationSynchronizationSettingStep2());
	
EndProcedure

Procedure ImportMessageExchangeSuccessfullyCompleted(Message, Sender)
	
	DataExchangeSaaS.FixSuccessfullSessionCompletion(Message, RepresentationExchangeMessageImporting());
	
EndProcedure

Procedure ExchangeMessageImportingError(Message, Sender)
	
	DataExchangeSaaS.FixSuccessfullSessionCompletion(Message, RepresentationExchangeMessageImporting());
	
EndProcedure

// Receive correspondent data

Procedure CorrespondentDataGettingCompletedSuccessfully(Message, Sender)
	
	DataExchangeSaaS.SaveSessionData(Message, RepresentationCorrespondentDataGetting());
	
EndProcedure

Procedure CorrespondentNodesCommonDataGettingCompletedSuccessfully(Message, Sender)
	
	DataExchangeSaaS.SaveSessionData(Message, RepresentationCorrespondentNodesCommonDataGetting());
	
EndProcedure

Procedure CorrespondentDataGettingError(Message, Sender)
	
	DataExchangeSaaS.FixUnsuccessfullSessionCompletion(Message, RepresentationCorrespondentDataGetting());
	
EndProcedure

Procedure CorrespondentNodesCommonDataGettingError(Message, Sender)
	
	DataExchangeSaaS.FixUnsuccessfullSessionCompletion(Message, RepresentationCorrespondentNodesCommonDataGetting());
	
EndProcedure

// Getting correspondent accounting parameters

Procedure CorrespondentAccountingParametersGettingCompletedSuccessfully(Message, Sender)
	
	DataExchangeSaaS.SaveSessionData(Message, RepresentationCorrespondentAccountingParametersGetting());
	
EndProcedure

Procedure CorrespondentAccountingParametersGettingError(Message, Sender)
	
	DataExchangeSaaS.FixUnsuccessfullSessionCompletion(Message, RepresentationCorrespondentAccountingParametersGetting());
	
EndProcedure

// Auxiliary functions

Function RepresentationSynchronizationSettingStep1()
	
	Return NStr("en='Data synchronization, step 1.';ru='Настройка синхронизации, шаг 1.';vi='Thiết lập đồng bộ hóa dữ liệu, bước 1.'");
	
EndFunction

Function RepresentationSynchronizationSettingStep2()
	
	Return NStr("en='Data synchronization, step 2.';ru='Настройка синхронизации, шаг 2.';vi='Thiết lập đồng bộ hóa dữ liệu, bước 2.'");
	
EndFunction

Function RepresentationExchangeMessageImporting()
	
	Return NStr("en='Import exchange message.';ru='Загрузка сообщения обмена.';vi='Kết nhập thông điệp trao đổi.'");
	
EndFunction

Function RepresentationCorrespondentDataGetting()
	
	Return NStr("en='Receiving correspondent data.';ru='Получение данных корреспондента.';vi='Nhận dữ liệu nơi trao đổi thông tin.'");
	
EndFunction

Function RepresentationCorrespondentNodesCommonDataGetting()
	
	Return NStr("en='Receiving common data of node of a correspondent.';ru='Получение общих данных узлов корреспондента.';vi='Nhận dữ liệu chung của nút nơi trao đổi thông tin.'");
	
EndFunction

Function RepresentationCorrespondentAccountingParametersGetting()
	
	Return NStr("en='Receiving accounting parameters of the correspondent';ru='Получение параметров учета корреспондента.';vi='Nhận tham số kế toán nơi trao đổi thông tin.'");
	
EndFunction

#EndRegion
