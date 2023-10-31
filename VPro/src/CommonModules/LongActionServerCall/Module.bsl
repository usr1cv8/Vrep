
#Region ServiceMethods

Function OperationComplete(Val JobsForCheck, JobsForCancel) Export
	
	Result = LongActions.OperationComplete(JobsForCheck);
	For Each JobID In JobsForCancel Do
		LongActions.ОтменитьВыполнениеЗадания(JobID);
		Result.Insert(JobID, New Structure("Status", "Canceled"));
	EndDo;
	Return Result;
	
EndFunction

#EndRegion
