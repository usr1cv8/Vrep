////////////////////////////////////////////////////////////////////////////////
// MessageExchangeClient: the mechanism of the exchange messages.
//
////////////////////////////////////////////////////////////////////////////////

#Region ServiceProceduresAndFunctions

// Executes sending and receiving of system messages.
// 
Procedure SendAndReceiveMessages() Export
	
	Status(NStr("en='Sending and receiving messages.';ru='Выполняется отправка и получение сообщений.';vi='Đang thực hiện gửi và nhận thông báo.'"),,
			NStr("en='Please wait...';ru='Пожалуйста, подождите...';vi='Xin vui lòng đợi...'"), PictureLib.Information32);
	
	Cancel = False;
	
	MessageExchangeServerCall.SendAndReceiveMessages(Cancel);
	
	If Cancel Then
		
		Status(NStr("en='Errors occurred when sending and receiving messages.';ru='Возникли ошибки при отправке и получении сообщений!';vi='Phát sinh lỗi khi gửi và nhận thông báo!'"),,
				NStr("en='Use the event log to diagnose errors.';ru='Используйте журнал регистрации для диагностики ошибок.';vi='Hãy sử dụng nhật ký sự kiện để chẩn đoán lỗi.'"), PictureLib.Error32);
		
	Else
		
		Status(NStr("en='Sending and receiving messages successfully completed.';ru='Отправка и получение сообщений успешно завершены.';vi='Gửi và nhận thông báo đã hoàn tất thành công.'"),,, PictureLib.Information32);
		
	EndIf;
	
	Notify(EventNameMessagesSendingAndReceivingPerformed());
	
EndProcedure

// Only for internal use.
//
// Returns:
// Row. 
//
Function EndPointAddedEventName() Export
	
	Return "MessageExchange.EndPointAdded";
	
EndFunction

// Only for internal use.
//
// Returns:
// Row. 
//
Function EventNameMessagesSendingAndReceivingPerformed() Export
	
	Return "MessageExchange.SendAndReceiveExecuted";
	
EndFunction

// Only for internal use.
//
// Returns:
// Row. 
//
Function EndPointFormClosedEventName() Export
	
	Return "MessageExchange.EndPointFormClosed";
	
EndFunction

// Only for internal use.
//
// Returns:
// Row. 
//
Function EventNameLeadingEndPointSet() Export
	
	Return "MessageExchange.LeadingEndPointSet";
	
EndFunction

#EndRegion
