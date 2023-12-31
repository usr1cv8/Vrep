////////////////////////////////////////////////////////////////////////////////
// Subsystem "Logging off users".
//
////////////////////////////////////////////////////////////////////////////////

#Region ServiceProceduresAndFunctions

// End the current session if connections to the infobase lock is set.
// 
Procedure ControlOfUserSessionTerminationMode() Export

	// Receive current value of lock parameters.
	CurrentMode = InfobaseConnectionsServerCall.SessionLockParameters();
	Locked = CurrentMode.Use;
	WorkParameters = StandardSubsystemsClientReUse.ClientWorkParameters();
	
	If Not Locked Then
		Return;
	EndIf;
		
	BeginTimeLock = CurrentMode.Begin;
	LockEndTime = CurrentMode.End;
	
	// IntervalCloseWithQuery and IntervalAbort
	// have negative value, that is why when these parameter are compared with difference (LockStartTime - CurrentMoment),
	// then used "<=" as this difference is gradually decreasing.
	WarningInterval    = CurrentMode.SessionTerminationTimeout;
	IntervalCloseWithQuery = WarningInterval / 3;
	StopIntervalSaaS = 60; // One minute before the lock start.
	StopInterval        = 0; // When lock is set.
	CurrentMoment             = CurrentMode.CurrentSessionDate;
	
	If LockEndTime <> '00010101' AND CurrentMoment > LockEndTime Then
		Return;
	EndIf;
	
	DateTimeBeginningLock  = Format(BeginTimeLock, "DLF=DD");
	TimeTimeBeginningLock = Format(BeginTimeLock, "DLF=T");
	
	MessageText = InfobaseConnectionsClientServer.ExtractLockMessage(CurrentMode.Message);
	MessageText = StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en='It is recommended to end current work and save all data. The application will be closed down %1 in %2. "
"%3';ru='Рекомендуется завершить текущую работу и сохранить все свои данные. Работа программы будет завершена %1 в %2. "
"%3';vi='Cần kết thúc công việc hiện tại và lưu lại tất cả dữ liệu. Sẽ kết thúc làm việc với chương trình %1 sang %2."
"%3'"),
		DateTimeBeginningLock, TimeTimeBeginningLock, MessageText);
	
	If Not WorkParameters.DataSeparationEnabled
		AND (NOT ValueIsFilled(BeginTimeLock) Or BeginTimeLock - CurrentMoment < StopInterval) Then
		
		StandardSubsystemsClient.SkipExitConfirmation();
		Exit(False, True);
		
	ElsIf WorkParameters.DataSeparationEnabled
		AND (NOT ValueIsFilled(BeginTimeLock) Or BeginTimeLock - CurrentMoment < StopIntervalSaaS) Then
		
		StandardSubsystemsClient.SkipExitConfirmation();
		Exit(False, False);
		
	ElsIf BeginTimeLock - CurrentMoment <= IntervalCloseWithQuery Then
		
		InfobaseConnectionsClient.AskQuestionOnWorkEnd(MessageText);
		
	ElsIf BeginTimeLock - CurrentMoment <= WarningInterval Then
		
		ShowMessageBox(, MessageText, 30);
		
	EndIf;
	
EndProcedure

// End active sessions if timeout exceeded and
// end the current session.
//
Procedure TerminateUserSessions() Export

	// Receive current value of lock parameters.
	CurrentMode = InfobaseConnectionsServerCall.SessionLockParameters(True);
	
	BeginTimeLock = CurrentMode.Begin;
	LockEndTime = CurrentMode.End;
	CurrentMoment = CurrentMode.CurrentSessionDate;
	
	If CurrentMoment < BeginTimeLock Then
		MessageText = NStr("en='Lock of the user operation is planned on %1.';ru='Блокировка работы пользователей запланирована на %1.';vi='Dự tính phong tỏa công việc của người sử dụng được vào lúc %1.'");
		MessageText = StringFunctionsClientServer.SubstituteParametersInString(
			MessageText, BeginTimeLock);
		ShowUserNotification(NStr("en='User work completion';ru='Завершение работы пользователей';vi='Kết thúc công việc của người sử dụng'"), 
			"e1cib/app/DataProcessor.UserWorkBlocking", 
			MessageText, PictureLib.Information32);
		Return;
	EndIf;
		
	NumberOfSessions = CurrentMode.NumberOfSessions;
	If NumberOfSessions <= 1 Then
		// All users are disabled, except of the current session.
		// The last thing is to end session started with the "EndUsersWork" parameter.
		// This disconnects order is required for configuration update using the pack file.
		InfobaseConnectionsClient.SetUserTerminationInProgressFlag(False);
		Notify("UserSessions", New Structure("Status, SessionsQuantity", "Done", NumberOfSessions));
		InfobaseConnectionsClient.TerminateThisSession();
		Return;
	EndIf; 
	
	Locked = CurrentMode.Use;
	If Not Locked Then
		Return;
	EndIf;
	
	TerminationInterval = - CurrentMode.SessionTerminationTimeout;
	ForceTermination = Not ValueIsFilled(BeginTimeLock)
		OR BeginTimeLock - CurrentMoment <= TerminationInterval;
		
	If Not ForceTermination Then
		
		MessageText = NStr("en='Active sessions: %1"
"Next sessions check will be executed in a minute.';ru='Активных сеансов: %1."
"Следующая проверка сеансов будет выполнена через минуту.';vi='Phiên làm việc đang làm việc: %1."
"Việc kiểm tra tiếp theo các phiên làm việc sẽ được thực hiện sau một phút.'");
		MessageText = StringFunctionsClientServer.SubstituteParametersInString(
			MessageText, NumberOfSessions);
		ShowUserNotification(NStr("en='User work completion';ru='Завершение работы пользователей';vi='Kết thúc công việc của người sử dụng'"), 
			"e1cib/app/DataProcessor.UserWorkBlocking", 
			MessageText, PictureLib.Information32);
		Notify("UserSessions", New Structure("Status,NumberOfSessions", "Running", NumberOfSessions));
		Return;
	EndIf;
	
	// After lock is started, sessions of all users
	// should be disabled if it did not happen, try to abort connection forcibly.
	DetachIdleHandler("TerminateUserSessions");
	
	Result = True;
	Try
		
		AdministrationParameters = InfobaseConnectionsClient.SavedAdministrationParameters();
		InfobaseConnectionsClientServer.DeleteAllSessionsExceptCurrent(AdministrationParameters);
		InfobaseConnectionsClient.SaveAdministrationParameters(Undefined);
		
	Except
		Result = False;
	EndTry;
	
	If Result Then
		InfobaseConnectionsClient.SetUserTerminationInProgressFlag(False);
		ShowUserNotification(NStr("en='User work completion';ru='Завершение работы пользователей';vi='Kết thúc công việc của người sử dụng'"), 
			"e1cib/app/DataProcessor.UserWorkBlocking", 
			NStr("en='Sessions are successfully closed';ru='Завершение сеансов выполнено успешно';vi='Kết thúc phiên làm việc đã thực hiện thành công'"), PictureLib.Information32);
		Notify("UserSessions", New Structure("Status,NumberOfSessions", "Done", NumberOfSessions));
		InfobaseConnectionsClient.TerminateThisSession();
	Else
		InfobaseConnectionsClient.SetUserTerminationInProgressFlag(False);
		ShowUserNotification(NStr("en='User work completion';ru='Завершение работы пользователей';vi='Kết thúc công việc của người sử dụng'"), 
			"e1cib/app/DataProcessor.UserWorkBlocking", 
			NStr("en='Sessions are not completed. For more information, see event log.';ru='Завершение сеансов не выполнено! Подробности см. в журнале регистрации.';vi='Không thể kết thúc phiên làm việc! Chi tiết xem trong Nhật ký sự kiện.'"), PictureLib.Warning32);
		Notify("UserSessions", New Structure("Status,NumberOfSessions", "Error", NumberOfSessions));
	EndIf;
	
EndProcedure

#EndRegion
