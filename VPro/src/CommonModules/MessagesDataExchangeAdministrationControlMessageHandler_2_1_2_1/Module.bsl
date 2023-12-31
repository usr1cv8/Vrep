////////////////////////////////////////////////////////////////////////////////
// MESSAGE CHANNEL HANDLER FOR VERSION 2.1.2.1
//  DATA EXCHANGE ADMINISTRATION CONTROL MESSAGE INTERFACE
//
////////////////////////////////////////////////////////////////////////////////

#Region ProgramInterface

// Returns namespace for message interface version
Function Package() Export
	
	Return "http://www.1c.ru/SaaS/ExchangeAdministration/Control";
	
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
//  MessageProcessed - Boolean, a flag showing that the message is successfully processed. The value of this parameter shall be set as equal to True,
//     if the message was successfully read in this handler
//
Procedure ProcessSaaSMessage(Val Message, Val Sender, MessageHandled) Export
	
	MessageHandled = True;
	
	Dictionary = MessagesDataExchangeAdministrationControlInterface;
	MessageType = Message.Body.Type();
	
	If MessageType = Dictionary.MessageDataSynchronizationSettingsReceived(Package()) Then
		DataExchangeSaaS.SaveSessionData(Message, SettingsGettingOperationRepresentation());
	ElsIf MessageType = Dictionary.MessageDataSynchronizationSettingsGettingError(Package()) Then
		DataExchangeSaaS.FixUnsuccessfullSessionCompletion(Message, SettingsGettingOperationRepresentation());
	ElsIf MessageType = Dictionary.MessageSynchronizationEnablingCompletedSuccessfully(Package()) Then
		DataExchangeSaaS.FixSuccessfullSessionCompletion(Message, SynchronizationEnablingRepresentation());
	ElsIf MessageType = Dictionary.MessageSynchronizationDisabledSuccessfully(Package()) Then
		DataExchangeSaaS.FixSuccessfullSessionCompletion(Message, SynchronizationDisablingRepresentation());
	ElsIf MessageType = Dictionary.MessageSynchronizationEnablingError(Package()) Then
		DataExchangeSaaS.FixUnsuccessfullSessionCompletion(Message, SynchronizationEnablingRepresentation());
	ElsIf MessageType = Dictionary.MessageSynchronizationDisablingError(Package()) Then
		DataExchangeSaaS.FixUnsuccessfullSessionCompletion(Message, SynchronizationDisablingRepresentation());
	ElsIf MessageType = Dictionary.MessageSynchronizationCompleted(Package()) Then
		DataExchangeSaaS.FixSuccessfullSessionCompletion(Message, SynchronizationPerformingRepresentation());
	Else
		MessageHandled = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

Function SettingsGettingOperationRepresentation()
	
	Return NStr("en='Receiving settings of data synchronization from the service manager.';ru='Получение настроек синхронизации данных из Менеджера сервиса.';vi='Nhận tùy chỉnh đồng bộ hóa dữ liệu từ Bộ quản lý dịch vụ.'");
	
EndFunction

Function SynchronizationEnablingRepresentation()
	
	Return NStr("en='Enable data synchronization in the service manager.';ru='Включение синхронизации данных в Менеджере сервиса.';vi='Bật đồng bộ hóa dữ liệu trong Quản lý dịch vụ.'");
	
EndFunction

Function SynchronizationDisablingRepresentation()
	
	Return NStr("en='Disable data synchronization in the service manager.';ru='Отключение синхронизации данных в Менеджере сервиса.';vi='Ngắt bỏ đồng bộ hóa dữ liệu trong Bộ quản lý dịch vụ.'");
	
EndFunction

Function SynchronizationPerformingRepresentation()
	
	Return NStr("en='Synchronize data on user request.';ru='Выполнение синхронизации данных по запросу пользователя.';vi='Thực hiện đồng bộ hóa dữ liệu theo truy vấn của người sử dụng.'");
	
EndFunction

#EndRegion
