
#Region ServiceMethods

Procedure LongOperationsControl() Export
	
	ActiveLongOperations = LongActionsClient.ActiveLongOperations();
	If ActiveLongOperations.Processing Then
		Return;
	EndIf;
	
	ActiveLongOperations.Processing = True;
	Try
		CheckLongOperations(ActiveLongOperations.List);
		
		ActiveLongOperations.Processing = False;
	Except
		ActiveLongOperations.Processing = False;
		Raise;
	EndTry;
	
EndProcedure

Procedure CheckLongOperations(ActiveLongOperations)
	
	CurrentData = CurrentDate();
	
	ControledOperation = New Map;
	JobsForCheck = New Array;
	JobsForCancel = New Array;
	
	For Each LongOperation In ActiveLongOperations Do
		
		LongOperation = LongOperation.Value;
		
		OperationCanceled = False;
		If LongOperation.OwnerForm <> Undefined And Not LongOperation.OwnerForm.IsOpen() Then
			OperationCanceled = True;
		EndIf;
		If LongOperation.ClosingNotification <> Undefined And TypeOf(LongOperation.ClosingNotification.Module) = Type("ManagedForm") 
			And Not LongOperation.ClosingNotification.Module.IsOpen() Then
			OperationCanceled = True;
		EndIf;
		
		If OperationCanceled Then
			
			ControledOperation.Insert(LongOperation.JobID, LongOperation);
			JobsForCancel.Add(LongOperation.JobID);
			
		ElsIf LongOperation.Control <= CurrentData Then
			
			ControledOperation.Insert(LongOperation.JobID, LongOperation);
			
			JobForChecking = New Structure("JobID,ShowProgress,ShowMessages");
			FillPropertyValues(JobForChecking, LongOperation);
			JobsForCheck.Add(JobForChecking);
			
		EndIf;
		
	EndDo;
	
	Statuses = New Map;
	Statuses = LongActionServerCall.OperationComplete(JobsForCheck, JobsForCancel);
	For Each OperationStatus In Statuses Do
		Operat = ControledOperation[OperationStatus.Key];
		Status = OperationStatus.Value;
		Try
			If CheckLongOperation(Operat, Status) Then
				ActiveLongOperations.Delete(OperationStatus.Key);
			EndIf;
		Except
			// далее не отслеживаем
			ActiveLongOperations.Delete(OperationStatus.Key);
			Raise;
		EndTry;
	EndDo;

	If ActiveLongOperations.Count() = 0 Then
		Return;
	EndIf;
	
	CurrentData = CurrentDate(); // дата сеанса не используется
	Interval = 120; 
	For Each Operat In ActiveLongOperations Do
		Interval = Max(Min(Interval, Operat.Value.Control - CurrentData), 1);
	EndDo;
	
	AttachIdleHandler("LongOperationsControl", Interval, True);
	
EndProcedure

Function CheckLongOperation(LongOperation, Status) 
	
	If Status.Status <> "Canceled" And LongOperation.ProgressNotification <> Undefined Then
		Progress = New Structure;
		Progress.Insert("Status", Status.Status);
		Progress.Insert("JobID", LongOperation.JobID);
		Progress.Insert("Progress", Status.Progress);
		Progress.Insert("Messages", Status.Messages);
		ExecuteNotifyProcessing(LongOperation.ProgressNotification, Progress);
	EndIf;
		
	If Status.Status = "Completed" Then
		
		LongActionsClient.ShowNotification(LongOperation.UserNotification);
		ExecuteNotify(LongOperation, Status);
		Return True;
		
	ElsIf Status.Status = "Error" Then
		
		ExecuteNotify(LongOperation, Status);
		Return True;
		
	ElsIf Status.Status = "Canceled" Then
		
		ExecuteNotify(LongOperation, Status);
		Return True;
		
	EndIf;
	
	WaitngInterval = LongOperation.CurrentInterval;
	If LongOperation.Interval = 0 Then
		WaitngInterval = WaitngInterval * 1.4;
		If WaitngInterval > 15 Then
			WaitngInterval = 15;
		EndIf;
		LongOperation.CurrentInterval = WaitngInterval;
	EndIf;
	LongOperation.Control = CurrentDate() + WaitngInterval;  // дата сеанса не используется
	Return False;
		
EndFunction

Procedure ExecuteNotify(Val LongOperation, Val Status)
	
	If LongOperation.ClosingNotification = Undefined Then
		Return;
	EndIf;
	
	If Status.Status = "Canceled" Then
		Result = Undefined;
	Else
		Result = New Structure;
		Result.Insert("Status",    Status.Status);
		Result.Insert("ResultAddress", LongOperation.ResultAddress);
		Result.Insert("AdditionalResultAddress", LongOperation.AdditionalResultAddress);
		Result.Insert("ShortErrorDescription", Status.ShortErrorDescription);
		Result.Insert("DetailedErrorDescription", Status.DetailedErrorDescription);
		Result.Insert("Messages", Status.Messages);
	EndIf;
	
	ExecuteNotifyProcessing(LongOperation.ClosingNotification, Result);

EndProcedure

#EndRegion
