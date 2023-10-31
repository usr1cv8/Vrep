#If Server OR ThickClientOrdinaryApplication OR ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	AccrualPeriod = New StandardPeriod;
	AccrualPeriod.Variant	= StandardPeriodVariant.LastMonth;
	StartDate				= AccrualPeriod.StartDate;
	EndDate					= AccrualPeriod.EndDate;
	
	ObjectFillingSB.FillDocument(ThisObject, FillingData);
	
EndProcedure

// Procedure - handler of the PostingProcessing event of the object.
//
Procedure Posting(Cancel, PostingMode)
	
	// Initialization of additional properties to post the document
	SmallBusinessServer.InitializeAdditionalPropertiesForPosting(Ref, AdditionalProperties);
	
	// Document data initialization
	Documents.LoanInterestCommissionAccruals.InitializeDocumentData(Ref, AdditionalProperties);
	
	// Prepare record sets
	SmallBusinessServer.PrepareRecordSetsForRecording(ThisObject);
	
	// Record in accounting sections
	SmallBusinessServer.ReflectIncomeAndExpenses(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectManagerial(AdditionalProperties, RegisterRecords, Cancel);
	SmallBusinessServer.ReflectLoanSettlements(AdditionalProperties, RegisterRecords, Cancel);
	
	// Record of record sets
	SmallBusinessServer.WriteRecordSets(ThisObject);

	AdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager.Close();
	
EndProcedure

// Procedure - handler of the PopulationCheckProcessing event of the object.
//
Procedure FillCheckProcessing(Cancel, AttributesToCheck)
	
	If OperationType = Enums.LoanAccrualTypes.AccrualsForLoansBorrowed Then		
		SmallBusinessServer.DeleteAttributeBeingChecked(AttributesToCheck, "Accruals.Employee");		
	Else		
		SmallBusinessServer.DeleteAttributeBeingChecked(AttributesToCheck, "Accruals.Lender");		
	EndIf;
	
	If ValueIsFilled(StartDate) AND ValueIsFilled(EndDate)
		AND StartDate > EndDate Then
		
		MessageText = NStr("en='Incorrect period is specified. Start date > End date.';ru='Указан неверный период. Дата начала > Даты окончания!.';vi='Đã chỉ ra sai kỳ. Ngày bắt đầu > Ngày kết thúc!'");
		
		SmallBusinessServer.ShowMessageAboutError(
			ThisObject,
			MessageText,,,
			"StartDate",
			Cancel);
		
	EndIf;
	
EndProcedure

// Procedure - handler of the PostingDeletionProcessing of the object event.
//
Procedure UndoPosting(Cancel)
	
	// Initialization of additional properties to post the document
	SmallBusinessServer.InitializeAdditionalPropertiesForPosting(Ref, AdditionalProperties);
	
	// Prepare record sets
	SmallBusinessServer.PrepareRecordSetsForRecording(ThisObject);
	
	// Record of record sets
	SmallBusinessServer.WriteRecordSets(ThisObject);

EndProcedure

// Procedure - handler of the BeforeWriting event of the object.
//
Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure // BeforeWriting()

#EndRegion

#EndIf
