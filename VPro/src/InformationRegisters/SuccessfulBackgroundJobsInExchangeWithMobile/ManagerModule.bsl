Procedure WriteJobID(Node, Val JobID) Export

	If TypeOf(JobID) <> Type("String") Then
		JobID = String(JobID);	
	EndIf; 
	
	If IsBlankString(JobID) Then
		Return;	
	EndIf; 
	
	Record = InformationRegisters.SuccessfulBackgroundJobsInExchangeWithMobile.CreateRecordManager();
	Record.Node = Node;
	Record.JobID = JobID;
	Record.Write();
	
EndProcedure

Function IsSuccessfulJob(Node, Val JobID) Export
	
	If TypeOf(JobID) <> Type("String") Then
		JobID = String(JobID);	
	EndIf; 
		
	Query = New Query;
	Query.Text = 
		"SELECT
		|	SuccessfulBackgroundJobsInExchangeWithMobile.JobID AS JobID
		|FROM
		|	InformationRegister.SuccessfulBackgroundJobsInExchangeWithMobile AS SuccessfulBackgroundJobsInExchangeWithMobile
		|WHERE
		|	SuccessfulBackgroundJobsInExchangeWithMobile.Node = &Node
		|	AND SuccessfulBackgroundJobsInExchangeWithMobile.JobID = &JobID";
	
	Query.SetParameter("JobID", JobID);
	Query.SetParameter("Node", Node);
	
	QueryResult = Query.Execute();
	Return Not QueryResult.IsEmpty();
	
EndFunction // IsSuccessfulJob()

Procedure DeleteSuccessfulJob(Node) Export

	Selection = InformationRegisters.SuccessfulBackgroundJobsInExchangeWithMobile.Select(New Structure("Node", Node));
	While Selection.Next() Do
		Selection.GetRecordManager().Delete();
	EndDo; 

EndProcedure
 

 
 