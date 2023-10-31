
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region BackgroundJob

Procedure FormDocuments(Parameters, ResultTempStorage) Export
	
	Result = New Structure;
	Errors = New ValueList;
	
	If Not Parameters.Property("Orders") Or TypeOf(Parameters.Orders)<>Type("ValueTree") Then
		Error = NStr("en='Not specified production orders';vi='Không quy định đơn đặt hàng sản xuất'");
		Errors.Add(, Error);
		Result.Insert("Errors", Errors);
	EndIf;
	
	If Errors.Count()>0 Then
		PutToTempStorage(Result, ResultTempStorage);
		Return;
	EndIf; 
	
	Orders = Parameters.Orders;
	StagesQuantity = Parameters.StagesQuantity;
	ProductionDate = Parameters.ProductionDate;
	Author = Parameters.Author;
	
	ChangesTable = Undefined;
	NewInventoryAssembly = Undefined;
	NewJobSheets = Undefined;
	CreateEmptyTables(ChangesTable, NewInventoryAssembly, NewJobSheets);
	ChangedDocument = New Map;
	
	RowQuantity = Orders.Rows.Count();
	RowNumber = 0;
	StageText = NStr("en = 'Production documents creating'; vi = 'Tạo chứng từ sản xuất'");
	
	If ProductionDate<BegOfDay(CurrentSessionDate()) Then
		Query = New Query;
		Query.SetParameter("ProductionDate", ProductionDate);
		Query.Text =
		"SELECT
		|	MAX(InventoryAssembly.Date) AS Date
		|FROM
		|	Document.InventoryAssembly AS InventoryAssembly
		|WHERE
		|	InventoryAssembly.Date BETWEEN BEGINOFPERIOD(&ProductionDate, МИНУТА) AND ENDOFPERIOD(&ProductionDate, МИНУТА)
		|	AND InventoryAssembly.Posted
		|
		|UNION ALL
		|
		|SELECT
		|	MAX(JobSheet.Date)
		|FROM
		|	Document.JobSheet AS JobSheet
		|WHERE
		|	JobSheet.Date BETWEEN BEGINOFPERIOD(&ProductionDate, МИНУТА) AND ENDOFPERIOD(&ProductionDate, МИНУТА)
		|	AND JobSheet.Posted
		|
		|ORDER BY
		|	Date DESC";
		Selection = Query.Execute().Select();
		If Selection.Count()=0 Then
			FormationTime = 0;
		Else
			Selection.Next();
			FormationTime = ?(ValueIsFilled(Selection.Date), (Selection.Date - ProductionDate), 0);
		EndIf;
	Else
		FormationTime = Undefined;
	EndIf; 
	
	For Each RowOrder In Orders.Rows Do
		For Each ProductsRow In RowOrder.Rows Do
			For ii = 1 To StagesQuantity Do
				Stage = ProductsRow["Stage" + ii];
				If Not ValueIsFilled(ProductsRow.ProductionKind) Then
					Stage = Catalogs.ProductionStages.EmptyRef();
				EndIf; 
				FieldsValue = New Structure;
				FieldsValue.Insert("ProductionDate", ProductionDate);
				FieldsValue.Insert("Company", RowOrder.Company);
				FieldsValue.Insert("Author", Author);
				FieldsValue.Insert("CompletiveStageDepartment", ProductsRow.StructuralUnit);
				FieldsValue.Insert("StructuralUnit", ?(Not ValueIsFilled(Stage) Or Stage=Catalogs.ProductionStages.ProductionComplete, ProductsRow.StructuralUnit, ProductsRow["StructuralUnit" + ii]));
				FieldsValue.Insert("Performer", ProductsRow["Performer" + ii]);
				FieldsValue.Insert("CustomerOrder", RowOrder.CustomerOrder);
				FieldsValue.Insert("ProductionOrder", RowOrder.ProductionOrder);
				FieldsValue.Insert("Counterparty", RowOrder.Counterparty);
				FieldsValue.Insert("ProductsAndServices", ProductsRow.ProductsAndServices);
				FieldsValue.Insert("Characteristic", ProductsRow.Characteristic);
				FieldsValue.Insert("Batch", ProductsRow.Batch);
				FieldsValue.Insert("Specification", ProductsRow.Specification);
				FieldsValue.Insert("Stage", Stage);
				FieldsValue.Insert("ProductionQuantity", ProductsRow.ProductionQuantity);
				FieldsValue.Insert("StageQuantity", ProductsRow.StageQuantity);
				FieldsValue.Insert("ProductionKind", ProductsRow.ProductionKind);
				FieldsValue.Insert("PerformerHide", ProductsRow["PerformerHide" + ii]);
				FieldsValue.Insert("ChoosePerformer", ProductsRow["ChoosePerformer" + ii]);
				If FormationTime<>Undefined Then
					FieldsValue.Insert("FormationTime", FormationTime);
				EndIf; 
				If ProductsRow["StageLabel" + ii] And Not ProductsRow["StageLabelOld" + ii] Then
					PerfomStage(FieldsValue,
						ChangesTable,
						ChangedDocument,
						NewInventoryAssembly,
						NewJobSheets,
						Errors);
				ElsIf Not ProductsRow["StageLabel" + ii] And ProductsRow["StageLabelOld" + ii] Then
					UndoStage(FieldsValue,
						ChangesTable,
						ChangedDocument,
						Errors);
				EndIf; 
			EndDo; 
		EndDo; 
		RowNumber = RowNumber+1;
		LongActions.TellProgress(Round(RowNumber/RowQuantity*100), StageText, RowOrder.Description);
	EndDo; 	
	
	// Сохранение изменений
	CommonFieldsValues = New Structure;
	CommonFieldsValues.Insert("ProductionDate", ProductionDate);
	CommonFieldsValues.Insert("StagesQuantity", StagesQuantity);
	CommonFieldsValues.Insert("CreatedDocuments", 0);
	CommonFieldsValues.Insert("ИзмененоДокументов", 0);
	CheckDocumentsFilling(ChangesTable, ChangedDocument, CommonFieldsValues, Errors);
	CommonFieldsValues.Insert("RowNumber", 0);
	WriteInventoryAssembly(Orders, ChangesTable, ChangedDocument, CommonFieldsValues, Errors);
	WriteJobSheets(Orders, ChangesTable, ChangedDocument, CommonFieldsValues, Errors);
	
	Result.Insert("Orders", Orders);
	Result.Insert("CreatedDocuments", CommonFieldsValues.CreatedDocuments);
	Result.Insert("ChangedDocuments", CommonFieldsValues.ИзмененоДокументов);
	If Errors.Count()>0 Then
		Result.Insert("Errors", Errors);
	EndIf;
	
	PutToTempStorage(Result, ResultTempStorage);
	
EndProcedure

Procedure CheckDocumentsFilling(ChangesTable, ChangedDocument, CommonFieldsValues, Errors)
	
	CanceledDocuments = New Array;
	For Each Item In ChangedDocument Do
		
		DocumentObject = Item.Value;
		FilterStructure = New Structure;
		If TypeOf(Item.Value)=Type("DocumentObject.InventoryAssembly") Then
			FilterStructure.Insert("InventoryAssembly", Item.Key);
			If DocumentObject.Products.Count()=0 Then
				//  The document will be marked for deletion, no need to check
				Continue;
			EndIf; 
		ElsIf TypeOf(Item.Value)=Type("DocumentObject.JobSheet") Then
			FilterStructure.Insert("JobSheet", Item.Key);
			If DocumentObject.Operations.Count()=0 Then
				// The document will be marked for deletion, no need to check
				Continue;
			EndIf; 
		Else
			Continue;
		EndIf;
		
		If DocumentObject.CheckFilling() Then
			Continue;
		EndIf;
		
		TableRows = ChangesTable.FindRows(FilterStructure);
		
		ErrorInfo = ErrorInfo();
		UserMessage = GetUserMessages();    
		Error = StrTemplate(NStr("en = 'Error filling document %1. Failed to complete the stages;'; ru = 'Ошибка заполнения документа %1. Не удалось выполнить этапы:'; vi = 'Lỗi điền chứng từ %1. Không thể hoàn thành các giai đoạn:'"), DocumentObject.Ref);
		For Each TableRow In TableRows Do
			Error = Error + Chars.LF + StrTemplate(NStr("En='> %1, %2, %3';ru='> %1, %2, %3';vi='> %1, %2, %3'"), OrdersPresentation(TableRow), ProductAndServicesPresentation(TableRow), TableRow.Stage);
		EndDo;
		Errors.Add(, Error);
		Error = RecursiveErrorDescription(ErrorInfo, UserMessage);
		Errors.Add(, Error);
		
		For Each ChangesRow In ChangesTable Do
			UndoStageChanges(ChangesRow, CommonFieldsValues, ChangedDocument, CanceledDocuments, Errors);
		EndDo;
		CanceledDocuments.Add(Item.Key);
		
	EndDo;
	
	For Each Document In CanceledDocuments Do
		ChangedDocument.Delete(Document);
	EndDo;  
	
EndProcedure

Procedure UndoStageChanges(ChangesTableRow, CommonFieldsValues, ChangedDocument, CanceledDocuments, Errors)
	
	FieldsValue = FieldsValue(
	ChangesTableRow.CustomerOrder,
	ChangesTableRow.ProductionOrder,
	ChangesTableRow.ProductsAndServices,
	ChangesTableRow.Characteristic,
	ChangesTableRow.Batch,
	ChangesTableRow.Specification,
	ChangesTableRow.ProductionKind,
	ChangesTableRow.Stage,
	ChangesTableRow.ProductionQuantity,
	ChangesTableRow.CompletiveStageDepartment);
	FieldsValue.Insert("ProductionDate", CommonFieldsValues.ProductionDate);
	
	If ValueIsFilled(ChangesTableRow.InventoryAssembly) Then
		DocumentObject = ChangedDocument.Get(ChangesTableRow.InventoryAssembly);
		If ChangesTableRow.Cancel Then
			PerfomStageinventoryAssembly(DocumentObject, FieldsValue, Errors);
		Else
			UndoStageInventoryAssembly(DocumentObject, FieldsValue, Errors);
		EndIf; 
		ChangesTableRow.InventoryAssembly = Undefined;
	EndIf; 	
	
	If ValueIsFilled(ChangesTableRow.JobSheet) Then
		DocumentObject = ChangedDocument.Get(ChangesTableRow.JobSheet);
		If ChangesTableRow.Cancel Then
			PerfomStageJobSheet(DocumentObject, FieldsValue, Errors);
		Else
			UndoStageJobSheet(DocumentObject, FieldsValue, Errors);
		EndIf; 
		ChangesTableRow.JobSheet = Undefined;
	EndIf;
	
EndProcedure

Procedure WriteInventoryAssembly(Orders, ChangesTable, ChangedDocument, CommonFieldsValues, Errors)
	
	RowQuantity = ChangedDocument.Count();
	StageText = NStr("En='Saving changes';ru='Сохранение изменений';vi='Lưu thay đổi'");
	
	For Each Item In ChangedDocument Do
		
		If TypeOf(Item.Value)<>Type("DocumentObject.InventoryAssembly") Then
			Continue;
		EndIf;
		
		DocumentObject = Item.Value;
		CommonFieldsValues.RowNumber = CommonFieldsValues.RowNumber+1;
		LongActions.TellProgress(Round(CommonFieldsValues.RowNumber/RowQuantity*100), StageText, String(DocumentObject));
		
		FilterStructure = New Structure;
		FilterStructure.Insert("InventoryAssembly", Item.Key);
		TableRows = ChangesTable.FindRows(FilterStructure);
		
		If TableRows.Count()=0 Then
			// Все изменения по документу отменены
			Continue;
		EndIf; 
		
		If DocumentObject.Products.Count()=0 And DocumentObject.IsNew() Then
			Continue;
		ElsIf DocumentObject.Products.Count()=0 Then
			
			Try
				DocumentObject.Write(DocumentWriteMode.UndoPosting);
				DocumentObject.SetDeletionMark(True);
				CommonFieldsValues.ИзмененоДокументов = CommonFieldsValues.ИзмененоДокументов + 1;
			Except
				ErrorInfo = ErrorInfo();
				UserMessage = GetUserMessages();
				WriteLogEvent(NStr("En='Production per stage: stage canceling';ru='Производство за смену: отмена этапов';vi='Sản xuất ca: loại bỏ công đoạn'"),
					EventLogLevel.Error, Metadata.Documents.InventoryAssembly, DocumentObject.Ref, DetailErrorDescription(ErrorInfo));
				Error = NStr("En='Errors in production stage canceling';ru='Не удалось отменить этапы производства:';vi='Không thể hủy giai đoạn sản xuất:'");
				For Each TableRow In TableRows Do
					Error = Error + Chars.LF + StrTemplate(NStr("En='> %1, %2, %3';ru='> %1, %2, %3';vi='> %1, %2, %3'"), OrdersPresentation(TableRow), ProductAndServicesPresentation(TableRow), TableRow.Stage);
				EndDo;
				Errors.Add(, Error);
				Error = RecursiveErrorDescription(ErrorInfo, UserMessage);
				Errors.Add(, Error);
			EndTry;
			
		Else
			
			Try
				
				IsNew = DocumentObject.IsNew();
				DocumentObject.FillColumnReserveByReserves();
				
				DocumentObject.Write(DocumentWriteMode.Posting);
				
				For Each TableRow In TableRows Do
					For Each OrderRow In Orders.Rows Do
						If OrderRow.CustomerOrder<>TableRow.CustomerOrder 
							Or OrderRow.ProductionOrder<>TableRow.ProductionOrder Then
							Continue;
						EndIf; 
						For Each ProductRow In OrderRow.Rows Do
							If ProductRow.ProductsAndServices<>TableRow.ProductsAndServices 
								Or ProductRow.Characteristic<>TableRow.Characteristic 
								Or ProductRow.Batch<>TableRow.Batch 
								Or ProductRow.Specification<>TableRow.Specification Then
								Continue;
							EndIf; 
							For ii = 1 To CommonFieldsValues.StagesQuantity Do
								If ProductRow["Stage" + ii]<>TableRow.Stage Then
									Continue;
								EndIf;
								ProductRow["StageLabelOld" + ii] = ProductRow["StageLabel" + ii];
								OrderRow["StageLabelOld" + ii] = EqualValue(OrderRow, "StageLabelOld" + ii);
								ProductRow["InventoryAssembly" + ii] = DocumentObject.Ref;
								ProductRow["InventoryAssemblyDescription" + ii] = DocumentPresentation(DocumentObject.Number, DocumentObject.Date);
								OrderRow["InventoryAssembly" + ii] = EqualValue(OrderRow, "InventoryAssembly" + ii);
								If ValueIsFilled(OrderRow["InventoryAssembly" + ii]) Then
									OrderRow["InventoryAssemblyDescription" + ii] = ProductRow["InventoryAssemblyDescription" + ii]; 
								EndIf; 
							EndDo; 
							ProductRow.IsSavedDocuments = True;
							OrderRow.IsSavedDocuments = EqualValue(OrderRow, "IsSavedDocuments");
						EndDo; 
					EndDo; 
				EndDo;
				If IsNew Then
					CommonFieldsValues.CreatedDocuments = CommonFieldsValues.CreatedDocuments + 1;
				Else
					CommonFieldsValues.ИзмененоДокументов = CommonFieldsValues.ИзмененоДокументов + 1;
				EndIf; 
				
			Except
				
				ErrorInfo = ErrorInfo();
				UserMessage = GetUserMessages();
				WriteLogEvent(NStr("en='Production per shift: stages completing';ru='Производство за смену: выполнение этапов';vi='Sản xuất ca: thực hiện giai đoạn'"),
					EventLogLevel.Error, Metadata.Documents.InventoryAssembly, ?(DocumentObject.IsNew(), Undefined, DocumentObject.Ref), DetailErrorDescription(ErrorInfo));
				Error = NStr("en='Failed to complete production stages:';ru='Не удалось выполнить этапы производства:';vi='Không thể thực hiện giai đoạn sản xuất:'");
				For Each TableRow In TableRows Do
					Error = Error + Chars.LF + StrTemplate(NStr("en='> %1, %2, %3';ru='> %1, %2, %3';vi='> %1, %2, %3'"), OrdersPresentation(TableRow), ProductAndServicesPresentation(TableRow), TableRow.Stage);
				EndDo;
				Errors.Add(, Error);
				Error = RecursiveErrorDescription(ErrorInfo, UserMessage);
				Errors.Add(, Error);
				
				// Discard changes of Job sheets
				For Each TableRow In TableRows Do
					If Not ValueIsFilled(TableRow.JobSheet) Then
						Continue;
					EndIf;
					
					FieldsValue = FieldsValue(
						TableRow.CustomerOrder,
						TableRow.ProductionOrder,
						TableRow.ProductsAndServices,
						TableRow.Characteristic,
						TableRow.Batch,
						TableRow.Specification,
						TableRow.ProductionKind,
						TableRow.Stage,
						TableRow.ProductionQuantity,
						TableRow.CompletiveStageDepartment);
						FieldsValue.Insert("ProductionDate", CommonFieldsValues.ProductionDate);
					
					DocumentObject = ChangedDocument.Get(TableRow.JobSheet);
					If TableRow.Cancel Then
						PerfomStageJobSheet(DocumentObject, FieldsValue, Errors);
					Else
						UndoStageJobSheet(DocumentObject, FieldsValue, Errors);
					EndIf; 
					TableRow.JobSheet = Undefined;
					
				EndDo; 
				
			EndTry;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure WriteJobSheets(Orders, ChangesTable, ChangedDocument, CommonFieldsValues, Errors)
	
	RowQuantity = ChangedDocument.Count();
	StageText = NStr("En='Saving changes';ru='Сохранение изменений';vi='Lưu thay đổi'");
	
	For Each Item In ChangedDocument Do
		
		If TypeOf(Item.Value)<>Type("DocumentObject.JobSheet") Then
			Continue;
		EndIf;
		
		DocumentObject = Item.Value;
		CommonFieldsValues.RowNumber = CommonFieldsValues.RowNumber+1;
		LongActions.TellProgress(Round(CommonFieldsValues.RowNumber/RowQuantity*100), StageText, String(DocumentObject));
		
		FilterStructure = New Structure;
		FilterStructure.Insert("JobSheet", Item.Key);
		TableRows = ChangesTable.FindRows(FilterStructure);
		
		If TableRows.Count()=0 Then
			// Все изменения по документу отменены
			Continue;
		EndIf; 
		
		If DocumentObject.Operations.Count()=0 And DocumentObject.IsNew() Then
			Continue;
		ElsIf DocumentObject.Operations.Count()=0 Then
			
			Try
				DocumentObject.Write(DocumentWriteMode.UndoPosting);
				DocumentObject.SetDeletionMark(True);
				CommonFieldsValues.ИзмененоДокументов = CommonFieldsValues.ИзмененоДокументов + 1;
			Except
				ErrorInfo = ErrorInfo();
				UserMessage = GetUserMessages();
				WriteLogEvent(NStr("en='Job sheet: stages canceling';ru='Сдельный наряд: отмена этапов';vi='Công khoán: hủy giai đoạn'"),
					EventLogLevel.Error, Metadata.Documents.JobSheet, DocumentObject.Ref, DetailErrorDescription(ErrorInfo));
				Error = NStr("en='Error in production stage canceling:';ru='Не удалось отменить этапы производства:';vi='Không thể hủy giai đoạn sản xuất:'");
				For Each TableRow In TableRows Do
					Error = Error + Chars.LF + StrTemplate(NStr("en='> %1, %2, %3';vi='> %1, %2, %3'"), OrdersPresentation(TableRow), ProductAndServicesPresentation(TableRow), TableRow.Stage);
				EndDo;
				Errors.Add(, Error);
				Error = RecursiveErrorDescription(ErrorInfo, UserMessage);
				Errors.Add(, Error);
			EndTry;
			
		Else
			
			Try
				
				IsNew = DocumentObject.IsNew();
				DocumentObject.Write(DocumentWriteMode.Posting);
				For Each TableRow In TableRows Do
					For Each OrderRow In Orders.Rows Do
						If OrderRow.CustomerOrder<>TableRow.CustomerOrder 
							Or OrderRow.ProductionOrder<>TableRow.ProductionOrder Then
							Continue;
						EndIf; 
						For Each ProductRow In OrderRow.Rows Do
							If ProductRow.ProductsAndServices<>TableRow.ProductsAndServices 
								Or ProductRow.Characteristic<>TableRow.Characteristic 
								Or ProductRow.Batch<>TableRow.Batch 
								Or ProductRow.Specification<>TableRow.Specification Then
								Continue;
							EndIf; 
							For ii = 1 To CommonFieldsValues.StagesQuantity Do
								If ProductRow["Stage" + ii]<>TableRow.Stage Then
									Continue;
								EndIf;
								ProductRow["JobSheet" + ii] = DocumentObject.Ref;
								ProductRow["JobSheetDescription" + ii] = DocumentPresentation(DocumentObject.Number, DocumentObject.Date);
								OrderRow["JobSheet" + ii] = EqualValue(OrderRow, "JobSheet" + ii);
								If ValueIsFilled(OrderRow["JobSheet" + ii]) Then
									OrderRow["JobSheetDescription" + ii] = ProductRow["JobSheetDescription" + ii]; 
								EndIf; 
							EndDo; 
							ProductRow.IsSavedDocuments = True;
							OrderRow.IsSavedDocuments = EqualValue(OrderRow, "IsSavedDocuments");
						EndDo; 
					EndDo; 
				EndDo;
				If IsNew Then
					CommonFieldsValues.CreatedDocuments = CommonFieldsValues.CreatedDocuments + 1;
				Else
					CommonFieldsValues.ИзмененоДокументов = CommonFieldsValues.ИзмененоДокументов + 1;
				EndIf; 
				
			Except
				ErrorInfo = ErrorInfo();
				UserMessage = GetUserMessages();
				WriteLogEvent(NStr("en='Job sheet: stage perfoming';ru='Сдельный наряд: выполнение этапов';vi='Công khoán: hoàn thành giai đoạn'"),
					EventLogLevel.Error, Metadata.Documents.JobSheet, ?(DocumentObject.IsNew(), Undefined, DocumentObject.Ref), DetailErrorDescription(ErrorInfo));
				Error = NStr("en = 'Production stage completed failed:'; ru = 'Не удалось выполнить этапы производства:'; vi = 'Không thể hoàn thành các giai đoạn sản xuất:'");
				For Each TableRow In TableRows Do
					Error = Error + Chars.LF + StrTemplate(NStr("en='> %1, %2, %3';ru='> %1, %2, %3';vi='> %1, %2, %3'"), OrdersPresentation(TableRow), ProductAndServicesPresentation(TableRow), TableRow.Stage);
				EndDo;
				Errors.Add(, Error);
				Error = RecursiveErrorDescription(ErrorInfo, UserMessage);
				Errors.Add(, Error);
			EndTry;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure CreateEmptyTables(ChangesTable, NewInventoryAssembly, NewJobSheets)
	
	ChangesTable = New ValueTable;
	ChangesTable.Columns.Add("CustomerOrder");
	ChangesTable.Columns.Add("ProductionOrder");
	ChangesTable.Columns.Add("Counterparty");
	ChangesTable.Columns.Add("ProductsAndServices");
	ChangesTable.Columns.Add("Characteristic");
	ChangesTable.Columns.Add("Batch");
	ChangesTable.Columns.Add("Specification");
	ChangesTable.Columns.Add("ProductionKind");
	ChangesTable.Columns.Add("Stage");
	ChangesTable.Columns.Add("InventoryAssembly");
	ChangesTable.Columns.Add("JobSheet");
	ChangesTable.Columns.Add("Cancel");
	ChangesTable.Columns.Add("ProductionQuantity");
	ChangesTable.Columns.Add("CompletiveStageDepartment");
	
	NewInventoryAssembly = New ValueTable;
	NewInventoryAssembly.Columns.Add("ProductionOrder");
	NewInventoryAssembly.Columns.Add("StructuralUnit");
	NewInventoryAssembly.Columns.Add("InventoryAssembly");
	
	NewJobSheets = New ValueTable;
	NewJobSheets.Columns.Add("StructuralUnit");
	NewJobSheets.Columns.Add("JobSheet");
	
EndProcedure

Function ExistingDocument(FieldsValue, ChangesTable, ChangedDocument, DocumentName = "InventoryAssembly")
	
	Query = New Query;
	Query.SetParameter("ProductionDate", FieldsValue.ProductionDate);
	Query.SetParameter("Order", ?(ValueIsFilled(FieldsValue.CustomerOrder), FieldsValue.CustomerOrder, FieldsValue.ProductionOrder));
	Query.SetParameter("ProductsAndServices", FieldsValue.ProductsAndServices);
	Query.SetParameter("Characteristic", FieldsValue.Characteristic);
	Query.SetParameter("Batch", FieldsValue.Batch);
	Query.SetParameter("Specification", FieldsValue.Specification);
	Query.SetParameter("Stage", FieldsValue.Stage);
	Query.Text =
	"SELECT TOP 1
	|	ProductionStages.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.ProductionStages AS ProductionStages
	|WHERE
	|	ProductionStages.Period BETWEEN BEGINOFPERIOD(&ProductionDate, МИНУТА) AND ENDOFPERIOD(&ProductionDate, МИНУТА)
	|	AND ProductionStages.ORDER = &Order
	|	AND ProductionStages.ProductsAndServices = &ProductsAndServices
	|	AND ProductionStages.ПОЛЕВИДА = &Characteristic
	|	AND ProductionStages.Specification = &Specification
	|	AND ProductionStages.Batch = &Batch
	|	AND ProductionStages.Stage = &Stage
	|	AND ProductionStages.Recorder REFS Document.InventoryAssembly";
	Query.Text = StrReplace(Query.Text, "Document.InventoryAssembly", "Document." + DocumentName);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		If ChangedDocument.Get(Selection.Recorder)=Undefined Then
			ChangedDocument.Insert(Selection.Recorder, Selection.Recorder.GetObject());
		EndIf;
		If DocumentName="InventoryAssembly" Then
			AddChangeRecord(ChangesTable, FieldsValue, Selection.Recorder, , True);
		Else
			AddChangeRecord(ChangesTable, FieldsValue, , Selection.Recorder, True);
		EndIf;
		Return Selection.Recorder;
	Else
		Return Undefined;
	EndIf;  
	
EndFunction

Function FindCreateInventoryAssembly(FieldsValue, ChangesTable, ChangedDocument, NewInventoryAssembly)
	
	Query = New Query;
	Query.SetParameter("ProductionDate", FieldsValue.ProductionDate);
	Query.SetParameter("StructuralUnit", FieldsValue.StructuralUnit);
	Query.SetParameter("Company", FieldsValue.Company);
	Query.SetParameter("ProductionOrder", FieldsValue.ProductionOrder);
	Query.Text =
	"SELECT TOP 1
	|	ProductionStages.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.ProductionStages AS ProductionStages
	|WHERE
	|	ProductionStages.Period BETWEEN BEGINOFPERIOD(&ProductionDate, DAY) AND ENDOFPERIOD(&ProductionDate, DAY)
	|	AND ProductionStages.QuantityFact > 0
	|	AND ProductionStages.Recorder REFS Document.InventoryAssembly
	|	AND ProductionStages.Recorder.StructuralUnit = &StructuralUnit
	|	AND ProductionStages.Recorder.Company = &Company
	|	AND ProductionStages.Recorder.ProductionOrder = &ProductionOrder";
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		
		If ChangedDocument.Get(Selection.Recorder)=Undefined Then
			ChangedDocument.Insert(Selection.Recorder, Selection.Recorder.GetObject());
		EndIf;
		AddChangeRecord(ChangesTable, FieldsValue, Selection.Recorder);
		Return ChangedDocument.Get(Selection.Recorder);
		
	Else	
		
		FilterStructure = New Structure;
		FilterStructure.Insert("ProductionOrder", FieldsValue.ProductionOrder);
		FilterStructure.Insert("StructuralUnit", FieldsValue.StructuralUnit);
		DocumentsRows = NewInventoryAssembly.FindRows(FilterStructure);
		If DocumentsRows.Count()>0 Then
			// New document has already been created for the same production order and structural unit
			AddChangeRecord(ChangesTable, FieldsValue, DocumentsRows[0].InventoryAssembly);
			Return ChangedDocument.Get(DocumentsRows[0].InventoryAssembly);
		EndIf; 
		
		Doc = Documents.InventoryAssembly.CreateDocument();
		If FieldsValue.Property("FormationTime") Then
			FieldsValue.FormationTime = FieldsValue.FormationTime + 1;
			If EndOfDay('0001-01-01')<('0001-01-01' + FieldsValue.FormationTime) Then
				FieldsValue.FormationTime = EndOfDay('0001-01-01') - '0001-01-01';
			EndIf; 
			Doc.Date = FieldsValue.ProductionDate + FieldsValue.FormationTime;
		ElsIf FieldsValue.ProductionDate>EndOfDay(CurrentSessionDate()) Then
			Doc.Date = FieldsValue.ProductionDate;
		Else
			Doc.Date = FieldsValue.ProductionDate + (CurrentSessionDate() - BegOfDay(CurrentSessionDate()));
		EndIf; 
		Doc.OperationKind = Enums.OperationKindsInventoryAssembly.Assembly;
		Doc.Company = FieldsValue.Company;
		Doc.Author = FieldsValue.Author;
		Doc.StructuralUnit = FieldsValue.StructuralUnit;
		If ValueIsFilled(FieldsValue.ProductionOrder) Then
			Doc.ProductionOrder = FieldsValue.ProductionOrder;
			AttributesValue = CommonUse.ObjectAttributesValues(FieldsValue.ProductionOrder, "WarehousePosition, CustomerOrderPosition");
			Doc.WarehousePosition = AttributesValue.WarehousePosition;
			Doc.CustomerOrderPosition = AttributesValue.CustomerOrderPosition;
		Else
			Doc.WarehousePosition = Enums.AttributePositionOnForm.InHeader;
			Doc.CustomerOrderPosition = Enums.AttributePositionOnForm.InHeader;
		EndIf; 
		DataStructure = GetDataStructuralUnit(FieldsValue.StructuralUnit);
		
		If Not GetFunctionalOption("AccountingBySeveralWarehouses") Then
			Doc.ProductsStructuralUnit = Catalogs.StructuralUnits.MainDepartment;
		ElsIf ValueIsFilled(DataStructure.ProductsStructuralUnit) Then
			Doc.ProductsStructuralUnit = DataStructure.ProductsStructuralUnit;
			Doc.ProductsCell = DataStructure.ProductsCell;
		Else
			Doc.ProductsStructuralUnit = FieldsValue.StructuralUnit;
		EndIf;
		If Not GetFunctionalOption("AccountingBySeveralWarehouses") Then
			Doc.InventoryStructuralUnit = Catalogs.StructuralUnits.MainDepartment;
		ElsIf ValueIsFilled(DataStructure.InventoryStructuralUnit) Then
			Doc.InventoryStructuralUnit = DataStructure.InventoryStructuralUnit;
			Doc.CellInventory = DataStructure.InventoryCell;
		Else
			Doc.InventoryStructuralUnit = FieldsValue.StructuralUnit;
		EndIf;
		If ValueIsFilled(DataStructure.WasteStructuralUnit) Then
			Doc.DisposalsStructuralUnit = DataStructure.DisposalsStructuralUnit;
			Doc.WasteCell = DataStructure.WasteCell;
		Else
			Doc.DisposalsStructuralUnit = Doc.StructuralUnit;
			Doc.DisposalsCell = Doc.Cell;
		EndIf;
		
		Doc.SetNewObjectRef(Documents.InventoryAssembly.GetRef(New UUID));
		ChangedDocument.Insert(Doc.GetNewObjectRef(), Doc);
		
		AddChangeRecord(ChangesTable, FieldsValue, Doc.GetNewObjectRef());
		
		NewRow = NewInventoryAssembly.Add();
		FillPropertyValues(NewRow, FieldsValue);
		NewRow.InventoryAssembly  = Doc.GetNewObjectRef();
		
		Return Doc;
		
	EndIf;  
	
EndFunction

Function FindCreateJobSheet(FieldsValue, ChangesTable, ChangedDocument, NewJobSheets)
	
	Query = New Query;
	Query.SetParameter("ProductionDate", FieldsValue.ProductionDate);
	Query.SetParameter("StructuralUnit", FieldsValue.StructuralUnit);
	Query.SetParameter("Company", FieldsValue.Company);
	Query.Text =
	"SELECT TOP 1
	|	ProductionStages.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.ProductionStages AS ProductionStages
	|WHERE
	|	ProductionStages.Period BETWEEN BEGINOFPERIOD(&ProductionDate, МИНУТА) AND ENDOFPERIOD(&ProductionDate, МИНУТА)
	|	AND ProductionStages.QuantityFact > 0
	|	AND ProductionStages.Recorder REFS Document.JobSheet
	|	AND ProductionStages.Recorder.StructuralUnit = &StructuralUnit
	|	AND ProductionStages.Recorder.Company = &Company";
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		
		If ChangedDocument.Get(Selection.Recorder)=Undefined Then
			ChangedDocument.Insert(Selection.Recorder, Selection.Recorder.GetObject());
		EndIf;
		AddChangeRecord(ChangesTable, FieldsValue, , Selection.Recorder);
		Return ChangedDocument.Get(Selection.Recorder);
		
	Else	
		
		FilterStructure = New Structure;
		FilterStructure.Insert("StructuralUnit", FieldsValue.StructuralUnit);
		DocumentsRows = NewJobSheets.FindRows(FilterStructure);
		If DocumentsRows.Count()>0 Then
			// Уже создан новый документ по такому же заказу на производство и структурной единице
			AddChangeRecord(ChangesTable, FieldsValue, , DocumentsRows[0].JobSheet);
			Return ChangedDocument.Get(DocumentsRows[0].JobSheet);
		EndIf; 
		
		Doc = Documents.JobSheet.CreateDocument();
		If FieldsValue.Property("FormationTime") Then
			FieldsValue.FormationTime = FieldsValue.FormationTime + 1;
			If EndOfDay('0001-01-01')<('0001-01-01' + FieldsValue.FormationTime) Then
				FieldsValue.FormationTime = EndOfDay('0001-01-01') - '0001-01-01';
			EndIf; 
			Doc.Date = FieldsValue.ProductionDate + FieldsValue.FormationTime;
		ElsIf FieldsValue.ProductionDate>EndOfDay(CurrentSessionDate()) Then
			Doc.Date = FieldsValue.ProductionDate;
		Else
			Doc.Date = FieldsValue.ProductionDate + (CurrentSessionDate() - BegOfDay(CurrentSessionDate()));
		EndIf; 
		Doc.ClosingDate = Doc.Date;
		Doc.Company = FieldsValue.Company;
		Doc.Author = FieldsValue.Author;
		Doc.StructuralUnit = FieldsValue.StructuralUnit;
		Doc.ProductionOrderPosition = Enums.AttributePositionOnForm.InHeader;
		Doc.PerformerPosition = Enums.AttributePositionOnForm.InTabularSection;
		Doc.StructuralUnitPosition = Enums.AttributePositionOnForm.InHeader;
		If ValueIsFilled(FieldsValue.ProductionOrder) Then
			Doc.ProductionOrder = FieldsValue.ProductionOrder;
		EndIf;
		Doc.Closed = True;
		
		Doc.DocumentCurrency = Constants.AccountingCurrency.Get();
		
		Doc.SetNewObjectRef(Documents.JobSheet.GetRef(New UUID));
		ChangedDocument.Insert(Doc.GetNewObjectRef(), Doc);
		
		AddChangeRecord(ChangesTable, FieldsValue, , Doc.GetNewObjectRef());
		
		NewRow = NewJobSheets.Add();
		FillPropertyValues(NewRow, FieldsValue);
		NewRow.JobSheet = Doc.GetNewObjectRef();
		
		Return Doc;
		
	EndIf;
	
EndFunction

Procedure AddChangeRecord(ChangesTable, FieldsValue, InventoryAssembly = Undefined, JobSheet = Undefined, Canceled = False)

	If InventoryAssembly=Undefined And JobSheet=Undefined Then
		Return;
	EndIf; 
	
	SearchFilter = New Structure("CustomerOrder, ProductionOrder, Counterparty, ProductsAndServices, Characteristic, Batch, Specification, Stage");
	FillPropertyValues(SearchFilter, FieldsValue);
	SearchFilter.Insert("Cancel", Canceled);
	Rows = ChangesTable.FindRows(SearchFilter);
	ChangesApplied = False;
	For Each TableRow In Rows Do
		If InventoryAssembly<>Undefined And Not ValueIsFilled(TableRow.InventoryAssembly) Then
			TableRow.InventoryAssembly = InventoryAssembly;
			ChangesApplied = True;
			Break;
		EndIf; 
		If JobSheet<>Undefined And Not ValueIsFilled(TableRow.JobSheet) Then
			TableRow.JobSheet = JobSheet;
			ChangesApplied = True;
			Break;
		EndIf; 
	EndDo; 
	
	If Not ChangesApplied Then
		NewRow = ChangesTable.Add();
		FillPropertyValues(NewRow, FieldsValue);
		If InventoryAssembly<>Undefined Then
			NewRow.InventoryAssembly = InventoryAssembly;
		EndIf; 
		If JobSheet<>Undefined Then
			NewRow.JobSheet = JobSheet;
		EndIf;
		NewRow.Cancel = Canceled;
	EndIf; 
	
EndProcedure 

Procedure PerfomStage(FieldsValue, ChangesTable, ChangedDocument, NewInventoryAssembly, NewJobSheets, Errors)
	
	DocumentObject = FindCreateInventoryAssembly(FieldsValue, ChangesTable, ChangedDocument, NewInventoryAssembly);
	If Not PerfomStageinventoryAssembly(DocumentObject, FieldsValue, Errors) Then
		// Failed to fill out production document, rollback changes
		RefForSearch = ?(DocumentObject.IsNew(), DocumentObject.GetNewObjectRef(), DocumentObject.Ref);
		ChangesTable.Delete(ChangesTable.Count()-1);
		SearchFilter = New Structure;
		SearchFilter.Insert("InventoryAssembly", RefForSearch);
		If ChangesTable.FindRows(SearchFilter).Count()=0 Then
			ChangedDocument.Delete(RefForSearch);
			If DocumentObject.IsNew() Then
				DeletedRows = NewInventoryAssembly.FindRows(SearchFilter);
				For Each DeletingRow In DeletedRows Do
					NewInventoryAssembly.Delete(DeletingRow);
				EndDo; 
			EndIf; 
		EndIf; 
		Return;
	EndIf;
	
	If GetFunctionalOption("UseTechOperations") And Not FieldsValue.PerformerHide Then
		
		DocumentObject = FindCreateJobSheet(FieldsValue, ChangesTable, ChangedDocument, NewJobSheets);
		PerfomStageJobSheet(DocumentObject, FieldsValue, Errors);

	EndIf; 
	
EndProcedure

Function FieldsValue(CustomerOrder, ProductionOrder, ProductsAndServices, Characteristic, Batch, Specification, ProductionKind, Stage, ProductionQuantity, CompletiveStageDepartment)
	
	FieldsValue = New Structure;
	FieldsValue.Insert("CustomerOrder", CustomerOrder);
	FieldsValue.Insert("ProductionOrder", ProductionOrder);
	FieldsValue.Insert("ProductsAndServices", ProductsAndServices);
	FieldsValue.Insert("Characteristic", Characteristic);
	FieldsValue.Insert("Batch", Batch);
	FieldsValue.Insert("Specification", Specification);
	FieldsValue.Insert("Stage", Stage);
	FieldsValue.Insert("ProductionQuantity", ProductionQuantity);
	FieldsValue.Insert("ProductionKind", ProductionKind);
	FieldsValue.Insert("CompletiveStageDepartment", CompletiveStageDepartment);
	Return FieldsValue;
	
EndFunction

Function PerfomStageinventoryAssembly(DocumentObject, FieldsValue, Errors)
	
	If ValueIsFilled(FieldsValue.CustomerOrder) 
		And DocumentObject.CustomerOrderPosition<> Enums.AttributePositionOnForm.InTabularSection
		And DocumentObject.CustomerOrder <> FieldsValue.CustomerOrder Then
		DocumentObject.CustomerOrderPosition = Enums.AttributePositionOnForm.InTabularSection;
	EndIf;
	
	ContentTable = StageContent(FieldsValue);
	If Not CheckContent(FieldsValue, ContentTable, Errors) Then
		Return False;
	EndIf; 
	
	SearchFilter = New Structure;
	If ValueIsFilled(FieldsValue.CustomerOrder) Then
		SearchFilter.Insert("CustomerOrder", FieldsValue.CustomerOrder);
	EndIf; 
	SearchFilter.Insert("ProductsAndServices", FieldsValue.ProductsAndServices);
	SearchFilter.Insert("Characteristic", FieldsValue.Characteristic);
	SearchFilter.Insert("Batch", FieldsValue.Batch);
	SearchFilter.Insert("Specification", FieldsValue.Specification);
	
	// Production
	ProductionRow = DocumentObject.Products.FindRows(SearchFilter);
	If ProductionRow.Count()=0 Then
		NewRowProduction = DocumentObject.Products.Add();
		FillPropertyValues(NewRowProduction, FieldsValue, "CustomerOrder, ProductsAndServices, Characteristic, Batch, Specification");
		If ValueIsFilled(FieldsValue.ProductionKind) Then
			NewRowProduction.CompletiveStageDepartment = FieldsValue.CompletiveStageDepartment;
		EndIf; 
		NewRowProduction.MeasurementUnit = CommonUse.ObjectAttributeValue(FieldsValue.ProductsAndServices, "MeasurementUnit");
		NewRowProduction.Quantity = FieldsValue.ProductionQuantity;
		SmallBusinessServer.FillConnectionKey(DocumentObject.Products, NewRowProduction, "ConnectionKey");
	Else
		NewRowProduction = ProductionRow[0];
	EndIf;
	
	// Completed changes
	If ValueIsFilled(FieldsValue.ProductionKind) Then
		FilterConnectionKey = New Structure;
		FilterConnectionKey.Insert("ConnectionKey", NewRowProduction.ConnectionKey);
		FilterConnectionKey.Insert("Stage", FieldsValue.Stage);
		CompletedStagesRow = DocumentObject.CompletedStages.FindRows(FilterConnectionKey);
		If CompletedStagesRow.Count()=0 Then
			NewRowPerfomedStage = DocumentObject.CompletedStages.Add();
			FillPropertyValues(NewRowPerfomedStage, FilterConnectionKey);
		EndIf; 
	EndIf; 
	
	// Inventory distribution
	For Each TableRow In ContentTable Do
		NewRow = DocumentObject.InventoryDistribution.Add();
		FillPropertyValues(NewRow, TableRow);
		NewRow.ConnectionKeyProduct = NewRowProduction.ConnectionKey;
		If Not ValueIsFilled(TableRow.StructuralUnit) Then
			NewRow.StructuralUnit = DocumentObject.InventoryStructuralUnit;
		EndIf; 
		If NewRow.StructuralUnit<>DocumentObject.InventoryStructuralUnit
			And DocumentObject.WarehousePosition <> Enums.AttributePositionOnForm.InTabularSection Then
			DocumentObject.WarehousePosition = Enums.AttributePositionOnForm.InTabularSection;
		EndIf; 
	EndDo; 
	
	ProductionServer.FillByDistribution(DocumentObject.Inventory, DocumentObject.InventoryDistribution);
	
	Return True;
	
EndFunction

Function CheckContent(FieldsValue, ContentTable, Errors)
	
	SerialNumberControl = GetFunctionalOption("SerialNumbersBalanceControl");
	ControlTBG = True; //Константы.КонтролироватьОстаткиПоНомерамГТД.Получить();
	If Not SerialNumberControl And Not ControlTBG Then
		Return True;
	EndIf; 
	
	ListSerialNumbers = New ValueList;
	ListTBGNumbers = New ValueList;
	For Each TabSecRow In ContentTable Do
		If SerialNumberControl 
			And TabSecRow.UseSerialNumbers 
			And ListSerialNumbers.FindByValue(TabSecRow.ProductsAndServices)=Undefined Then
			ListSerialNumbers.Add(TabSecRow.ProductsAndServices);
		EndIf;
		If ControlTBG 
			And ValueIsFilled(TabSecRow.CountryOfOrigin)
			And TabSecRow.CountryOfOrigin<>Catalogs.WorldCountries.Russia
			And ListTBGNumbers.FindByValue(TabSecRow.ProductsAndServices)=Undefined Then
			ListTBGNumbers.Add(TabSecRow.ProductsAndServices);
		EndIf; 
	EndDo; 
	
	If ListSerialNumbers.Count()>0 Or ListTBGNumbers.Count()>0 Then
		Error = NStr("en='Failed to complete production:';ru='Не удалось выполнить этап производства:';vi='Không thể thực hiện giai đoạn sản xuất:'");
		Error = Error + Chars.LF + StrTemplate(NStr("en='> %1, %2, %3';vi='> %1, %2, %3'"), OrdersPresentation(FieldsValue), ProductAndServicesPresentation(FieldsValue), FieldsValue.Stage);
		Errors.Add(, Error);
	EndIf; 
	If ListSerialNumbers.Count()>0 Then
		Error = StrTemplate(NStr("en='Automatic generation of production documents is not possible when using materials based on serial numbers (% 1)';ru='Автоматическое формирование документов производства невозможно при использовании материалов с учетом по серийным номерам (%1)';vi='Không thể tạo chứng từ sản xuất tự động khi sử dụng các nguyên liệu có số sê-ri (% 1)'"),
			String(ListSerialNumbers));
		Errors.Add(, Error);
	EndIf; 
	If ListTBGNumbers.Count()>0 Then
		Error = StrTemplate(NStr("En='Automatic generation of production documents is not possible when using materials requiring the indication of TBG (%1)';ru='Автоматическое формирование документов производства невозможно при использовании материалов, требующих указания номера ГТД (%1)';vi='Không thể tạo chứng từ sản xuất tự động khi sử dụng các vật liệu yêu cầu chỉ thị số động cơ  (%1)'"),
			String(ListTBGNumbers));
		Errors.Add(, Error);
	EndIf; 
	
	Return (ListSerialNumbers.Count()=0 And ListTBGNumbers.Count()=0);
	
EndFunction
 
Function PerfomStageJobSheet(DocumentObject, FieldsValue, Errors)
	
	If ValueIsFilled(FieldsValue.ProductionOrder) 
		And DocumentObject.ProductionOrderPosition <> Enums.AttributePositionOnForm.InTabularSection
		And DocumentObject.ProductionOrder<>FieldsValue.ProductionOrder Then
		DocumentObject.ProductionOrderPosition = Enums.AttributePositionOnForm.InTabularSection;
	EndIf;
	
	OperationTable = StagesOperation(FieldsValue);
	
	SearchFilter = New Structure;
	SearchFilter.Insert("CustomerOrder", FieldsValue.CustomerOrder);
	SearchFilter.Insert("ProductionOrder", FieldsValue.ProductionOrder);
	SearchFilter.Insert("ProductsAndServices", FieldsValue.ProductsAndServices);
	SearchFilter.Insert("Characteristic", FieldsValue.Characteristic);
	SearchFilter.Insert("Batch", FieldsValue.Batch);
	SearchFilter.Insert("Specification", FieldsValue.Specification);
	SearchFilter.Insert("Stage", FieldsValue.Stage);

	OperationRows = DocumentObject.Operations.FindRows(SearchFilter);
	For Each OperationRow In OperationRows Do
		DocumentObject.Operations.Delete(OperationRow);
	EndDo;  
	
	For Each OperationRow In OperationTable Do
		
		OperationNewRow = DocumentObject.Operations.Add();
		SmallBusinessServer.FillConnectionKey(DocumentObject.Operations, OperationNewRow, "ConnectionKey");
		OperationNewRow.Period = FieldsValue.ProductionDate;
		FillPropertyValues(OperationNewRow, FieldsValue, , "CompletiveStageDepartment");
		If ValueIsFilled(FieldsValue.ProductionKind) Then
			OperationNewRow.CompletiveStageDepartment = FieldsValue.CompletiveStageDepartment;
		EndIf; 
		FillPropertyValues(OperationNewRow, OperationRow);
		OperationNewRow.QuantityPlan = FieldsValue.ProductionQuantity;
		OperationNewRow.QuantityFact = FieldsValue.ProductionQuantity;
		OperationNewRow.StandardHours = OperationNewRow.QuantityFact * OperationNewRow.TimeNorm;
		OperationNewRow.Cost = ?(OperationRow.FixedCost, OperationNewRow.QuantityFact, OperationNewRow.TimeNorm) * OperationNewRow.Tariff;
		If OperationNewRow.ProductionOrder<>DocumentObject.ProductionOrder
			And DocumentObject.ProductionOrderPosition<>Enums.AttributePositionOnForm.InTabularSection Then
			DocumentObject.ProductionOrderPosition = Enums.AttributePositionOnForm.InTabularSection;
		EndIf; 
		
		// Brigade content
		If OperationTable.Columns.Find("Brigade")<>Undefined Then
			For Each ContentRow In OperationRow.Brigade Do
				ContentNewRow = DocumentObject.TeamMembers.Add();
				FillPropertyValues(ContentNewRow, ContentRow);
				ContentNewRow.ConnectionKey = OperationNewRow.ConnectionKey;
			EndDo;
		ElsIf TypeOf(OperationNewRow.Performer)=Type("СправочникСсылка.Teams") Then 
			ContentTable = Catalogs.Teams.BrigadeContent(OperationNewRow.Performer, DocumentObject.Company, DocumentObject.Date);
			For Each ContentRow In ContentTable Do
				ContentNewRow = DocumentObject.TeamMembers.Add();
				FillPropertyValues(ContentNewRow, ContentRow);
				ContentNewRow.ConnectionKey = OperationNewRow.ConnectionKey;
			EndDo;
		EndIf; 
		
	EndDo;
	
	Return True;
	
EndFunction
 
Procedure UndoStage(FieldsValue, ChangesTable, ChangedDocument, Errors)
	
	ProductionDocument = ExistingDocument(FieldsValue, ChangesTable, ChangedDocument);
	If GetFunctionalOption("UseTechOperations") And Not FieldsValue.PerformerHide Then
		DocumentSN = ExistingDocument(FieldsValue, ChangesTable, ChangedDocument, "JobSheet");
	Else
		DocumentSN = Undefined;
	EndIf;
	
	DocumentsFound = (ProductionDocument<>Undefined Or DocumentSN<>Undefined);
	If ProductionDocument=Undefined Then
		CommonUseClientServer.MessageToUser(
			StrTemplate(NStr("En='Production document not found %1, %2, %3.';ru='Не найден документ производства %1, %2, %3.';vi='Không tìm thấy chứng từ sản xuất %1, %2, %3.'"), OrdersPresentation(FieldsValue), ProductAndServicesPresentation(FieldsValue), FieldsValue.Stage));
	EndIf;
	If DocumentSN=Undefined Then
		CommonUseClientServer.MessageToUser(
			StrTemplate(NStr("En='Job sheet document not found %1, %2, %3.';ru='Не найден сдельный наряд %1, %2, %3.';vi='Không tìm thấy công khoán %1, %2, %3.'"), OrdersPresentation(FieldsValue), ProductAndServicesPresentation(FieldsValue), FieldsValue.Stage));
	EndIf;
	If Not DocumentsFound Then
		Return;
	EndIf;
	
	If ProductionDocument<>Undefined Then
		
		DocumentObject = ChangedDocument.Get(ProductionDocument);	
		UndoStageInventoryAssembly(DocumentObject, FieldsValue, Errors);
		
	EndIf; 
	
	If DocumentSN<>Undefined Then
		
		DocumentObject = ChangedDocument.Get(DocumentSN);
		UndoStageJobSheet(DocumentObject, FieldsValue, Errors);
		
	EndIf; 
	
EndProcedure

Function UndoStageInventoryAssembly(DocumentObject, FieldsValue, Errors)
	
	SearchFilter = New Structure;
	If ValueIsFilled(FieldsValue.CustomerOrder) Then
		SearchFilter.Insert("CustomerOrder", FieldsValue.CustomerOrder);
	EndIf; 
	SearchFilter.Insert("ProductsAndServices", FieldsValue.ProductsAndServices);
	SearchFilter.Insert("Characteristic", FieldsValue.Characteristic);
	SearchFilter.Insert("Batch", FieldsValue.Batch);
	SearchFilter.Insert("Specification", FieldsValue.Specification);
	
	ProductionRow = DocumentObject.Products.FindRows(SearchFilter);
	If ProductionRow.Count()=0 Then
		Return False;
	EndIf;
	
	ProductsRow = ProductionRow[0];
	ConectionKey = ProductsRow.ConnectionKey;
	
	FilterConnectionKey = New Structure;
	FilterConnectionKey.Insert("ConnectionKey", ConectionKey);
	FilterConnectionKey.Insert("Stage", FieldsValue.Stage);
	
	CompletedStagesRow = DocumentObject.CompletedStages.FindRows(FilterConnectionKey);
	For Each PerfomedStagesRow In CompletedStagesRow Do
		DocumentObject.CompletedStages.Delete(PerfomedStagesRow);
	EndDo;
	
	FilterConnectionKey = New Structure;
	FilterConnectionKey.Insert("ConnectionKeyProduct", ConectionKey);
	FilterConnectionKey.Insert("Stage", FieldsValue.Stage);
	
	DistributionRows = DocumentObject.InventoryDistribution.FindRows(FilterConnectionKey);
	For Each DistribRow In DistributionRows Do
		DocumentObject.InventoryDistribution.Delete(DistribRow);
	EndDo;
	
	FilterConnectionKey = New Structure;
	FilterConnectionKey.Insert("ConnectionKey", ConectionKey);
	
	CompletedStagesRow = DocumentObject.CompletedStages.FindRows(FilterConnectionKey);
	If CompletedStagesRow.Count()=0 Then
		SmallBusinessServer.DeleteConnectionKeyRows(DocumentObject.SerialNumbersProducts, ProductsRow);
		DocumentObject.Products.Delete(ProductsRow);
	EndIf; 
	
	ProductionServer.FillByDistribution(DocumentObject.Inventory, DocumentObject.InventoryDistribution);
	
	Return True;
	
EndFunction

Function UndoStageJobSheet(DocumentObject, FieldsValue, Errors)
	
	If ValueIsFilled(FieldsValue.ProductionOrder) 
		И DocumentObject.ProductionOrder <> Enums.AttributePositionOnForm.InTabularSection
		И DocumentObject.ProductionOrder <> FieldsValue.ProductionOrder Then
		Return False;
	EndIf;
	
	SearchFilter = New Structure;
	SearchFilter.Insert("CustomerOrder", FieldsValue.CustomerOrder);
	SearchFilter.Insert("ProductionOrder", FieldsValue.ProductionOrder);
	SearchFilter.Insert("ProductsAndServices", FieldsValue.ProductsAndServices);
	SearchFilter.Insert("Characteristic", FieldsValue.Characteristic);
	SearchFilter.Insert("Batch", FieldsValue.Batch);
	SearchFilter.Insert("Specification", FieldsValue.Specification);
	SearchFilter.Insert("Stage", FieldsValue.Stage);

	OperationRows = DocumentObject.Operations.FindRows(SearchFilter);
	For Each OperationRow In OperationRows Do
		SmallBusinessServer.DeleteConnectionKeyRows(DocumentObject.TeamMembers, OperationRow);
		DocumentObject.Operations.Delete(OperationRow);
	EndDo;
	
	Return True;
	
EndFunction

Function GetDataStructuralUnit(Department)
	
	DataStructure = New Structure;
	
	DataStructure.Insert("ItWarehouse", Department.TransferRecipient.StructuralUnitType = Enums.StructuralUnitsTypes.Warehouse);
	DataStructure.Insert("ItDepartment", Department.TransferRecipient.StructuralUnitType = Enums.StructuralUnitsTypes.Department);
	
	If DataStructure.ItWarehouse Or DataStructure.ItDepartment Then
		
		DataStructure.Insert("ProductsStructuralUnit", Department.TransferRecipient);
		DataStructure.Insert("ProductsCell", Department.TransferRecipientCell);
		DataStructure.Insert("ProductsStructuralUnitSign", Department.TransferRecipient.FRP);
		
	Else
		
		DataStructure.Insert("ProductsStructuralUnit", Undefined);
		DataStructure.Insert("ProductsCell", Undefined);
		DataStructure.Insert("ProductsStructuralUnitSign", Department.FRP);
		
	EndIf;
	
	If Department.TransferSource.StructuralUnitType = Enums.StructuralUnitsTypes.Warehouse
		Or Department.TransferSource.StructuralUnitType = Enums.StructuralUnitsTypes.Department Then
		
		DataStructure.Insert("InventoryStructuralUnit", Department.TransferSource);
		DataStructure.Insert("InventoryCell", Department.TransferSourceCell);
		DataStructure.Insert("InventoryStructuralUnitSign", Department.TransferSource.FRP);
		
	Else
		
		DataStructure.Insert("InventoryStructuralUnit", Undefined);
		DataStructure.Insert("InventoryCell", Undefined);
		DataStructure.Insert("InventoryStructuralUnitSign", Department.FRP);
		
	EndIf;
	
	DataStructure.Insert("WasteStructuralUnit", Department.DisposalsRecipient);
	DataStructure.Insert("WasteCell", Department.DisposalsRecipientCell);
	
	DataStructure.Insert("OrderWarehouse", Department.OrderWarehouse);
	DataStructure.Insert("OrderProductionWarehouse", Department.TransferRecipient.OrderWarehouse);
	DataStructure.Insert("OrderWasteWarehouse", Department.DisposalsRecipient.OrderWarehouse);
	DataStructure.Insert("OrderInventoryWarehouse", Department.TransferSource.OrderWarehouse);
	DataStructure.Insert("ControllerSign", Department.FRP);
	
	Return DataStructure;
	
EndFunction // ПолучитьДанныеСтруктурнаяЕдиницаПриИзменении()

Function StageContent(FieldsValue)
	
	Query = New Query;
	Query.SetParameter("Specification", FieldsValue.Specification);
	Query.SetParameter("Stage", FieldsValue.Stage);
	Query.SetParameter("CustomerOrder", FieldsValue.CustomerOrder);
	Query.SetParameter("WithoutStages", Not ValueIsFilled(FieldsValue.ProductionKind));
	
	If ValueIsFilled(FieldsValue.ProductionOrder) Then
		
		Query.SetParameter("ProductionOrder", FieldsValue.ProductionOrder);
		Query.SetParameter("ProductsAndServices", FieldsValue.ProductsAndServices);
		Query.SetParameter("Characteristic", FieldsValue.Characteristic);
		Query.SetParameter("Batch", FieldsValue.Batch);
		Query.Text =
		"SELECT
		|	ProductionOrderInventoryAssembly.ProductsAndServices AS ProductsAndServices,
		|	ProductionOrderInventoryAssembly.Characteristic AS Characteristic,
		|	ProductionOrderInventoryAssembly.MeasurementUnit AS MeasurementUnit,
		|	ProductionOrderInventoryAssembly.Specification AS Specification,
		|	ProductionOrderInventoryAssembly.Batch AS Batch,
		|	CASE
		|		WHEN ProductionOrderInventoryAssembly.CustomerOrder <> VALUE(Document.CustomerOrder.EmptyRef)
		|			THEN ProductionOrderInventoryAssembly.StructuralUnit
		|		ELSE VALUE(Catalog.StructuralUnits.EmptyRef)
		|	END AS StructuralUnit,
		|	ProductionOrderInventoryAssembly.CustomerOrder AS CustomerOrder,
		|	ProductionOrderInventoryAssembly.Stage AS Stage,
		|	ProductionOrderInventoryAssembly.Quantity AS Quantity,
		|	ProductionOrderInventoryAssembly.ProductsAndServices.CountryOfOrigin AS CountryOfOrigin,
		|	ProductionOrderInventoryAssembly.ProductsAndServices.UseSerialNumbers AS UseSerialNumbers
		|FROM
		|	Document.ProductionOrder.Products AS ProductionOrderProducts
		|		LEFT JOIN Document.ProductionOrder.InventoryDistribution AS ProductionOrderInventoryAssembly
		|		ON ProductionOrderProducts.Ref = ProductionOrderInventoryAssembly.Ref
		|			AND ProductionOrderProducts.ConnectionKey = ProductionOrderInventoryAssembly.ConnectionKeyProduct
		|WHERE
		|	ProductionOrderProducts.Ref = &ProductionOrder
		|	AND ProductionOrderProducts.ProductsAndServices = &ProductsAndServices
		|	AND ProductionOrderProducts.Characteristic = &Characteristic
		|	AND ProductionOrderProducts.Specification = &Specification
		|	AND ProductionOrderProducts.Batch = &Batch
		|	AND (ProductionOrderInventoryAssembly.Stage = &Stage
		|			OR &WithoutStages)
		|	AND NOT ProductionOrderInventoryAssembly.ProductsAndServices IS NULL";
		
	Else	
	
		Query.SetParameter("ProductionQuantity", FieldsValue.ProductionQuantity);
		Query.Text =
		"SELECT
		|	SpecificationsContent.ProductsAndServices AS ProductsAndServices,
		|	SpecificationsContent.Characteristic AS Characteristic,
		|	SpecificationsContent.MeasurementUnit AS MeasurementUnit,
		|	SpecificationsContent.Specification AS Specification,
		|	VALUE(Catalog.ProductsAndServicesBatches.EmptyRef) AS Batch,
		|	VALUE(Catalog.StructuralUnits.EmptyRef) AS StructuralUnit,
		|	&CustomerOrder AS CustomerOrder,
		|	SpecificationsContent.Stage AS Stage,
		|	SpecificationsContent.Quantity / SpecificationsContent.ProductsQuantity * &ProductionQuantity AS Quantity,
		|	SpecificationsContent.ProductsAndServices.CountryOfOrigin AS CountryOfOrigin,
		|	SpecificationsContent.ProductsAndServices.UseSerialNumbers AS UseSerialNumbers
		|FROM
		|	Catalog.Specifications.Content AS SpecificationsContent
		|WHERE
		|	SpecificationsContent.Ref = &Specification
		|	AND (SpecificationsContent.Stage = &Stage
		|			OR &WithoutStages)";
		
	EndIf; 
	
	Return Query.Execute().Unload();
	
EndFunction

Function StagesOperation(FieldsValue)
	
	Query = New Query;
	Query.SetParameter("Specification", FieldsValue.Specification);
	Query.SetParameter("Stage", FieldsValue.Stage);
	Query.SetParameter("ProductionDate", FieldsValue.ProductionDate);
	Query.SetParameter("NoStages", Not ValueIsFilled(FieldsValue.ProductionKind));
	
	If ValueIsFilled(FieldsValue.ProductionOrder)
		And CommonUse.ObjectAttributeValue(FieldsValue.ProductionOrder, "OperationPlanned") Then
		
		Query.SetParameter("ProductionOrder", FieldsValue.ProductionOrder);
		Query.SetParameter("CustomerOrder", FieldsValue.CustomerOrder);
		Query.SetParameter("ProductsAndServices", FieldsValue.ProductsAndServices);
		Query.SetParameter("Characteristic", FieldsValue.Characteristic);
		Query.SetParameter("Batch", FieldsValue.Batch);
		Query.Text =
		"SELECT
		|	ProductionOrderProducts.MeasurementUnit AS MeasurementUnit,
		|	ProductionOrderOperations.Operation AS Operation,
		|	ProductionOrderOperations.Operation.FixedCost AS FixedCost,
		|	ProductionOrderOperations.TimeRate AS TimeRate,
		|	ISNULL(ProductsAndServicesSliceLast.Price * CASE
		|			WHEN ProductsAndServicesSliceLast.MeasurementUnit REFS Catalog.UOM
		|				THEN ProductsAndServicesSliceLast.MeasurementUnit.Factor
		|			ELSE 1
		|		END, 0) AS Pricing,
		|	ProductionOrderOperations.Performer AS Performer,
		|	ProductionOrderOperations.ConnectionKey AS ConnectionKey,
		|	ProductionOrderOperations.Ref.PerformerPosition КАК PerformerPosition
		|INTO Operations
		|FROM
		|	Document.ProductionOrder.Products AS ProductionOrderProducts
		|		LEFT JOIN Document.ProductionOrder.Operations AS ProductionOrderOperations
		|			LEFT JOIN InformationRegister.ProductsAndServicesPrices.SliceLast(
		|					&ProductionDate,
		|					PriceKind = VALUE(Catalog.PriceKinds.Accounting)
		|						AND Characteristic = VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)) AS ProductsAndServicesSliceLast
		|			ON ProductionOrderOperations.Operation = ProductsAndServicesSliceLast.ProductsAndServices
		|		ON ProductionOrderProducts.Ref = ProductionOrderOperations.Ref
		|			AND ProductionOrderProducts.ConnectionKey = ProductionOrderOperations.ConnectionKeyProduct
		|WHERE
		|	ProductionOrderProducts.Ref = &ProductionOrder
		|	AND ProductionOrderProducts.CustomerOrder = &CustomerOrder
		|	AND ProductionOrderProducts.ProductsAndServices = &ProductsAndServices
		|	AND ProductionOrderProducts.Characteristic = &Characteristic
		|	AND ProductionOrderProducts.Specification = &Specification
		|	AND ProductionOrderProducts.Batch = &Batch
		|	AND (ProductionOrderOperations.Stage = &Stage
		|			OR &NoStages)
		|	AND NOT ProductionOrderOperations.Operation IS NULL
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Operations.MeasurementUnit AS MeasurementUnit,
		|	Operations.Operation AS Operation,
		|	Operations.FixedCost AS FixedCost,
		|	Operations.TimeRate AS TimeRate,
		|	Operations.Pricing AS Pricing,
		|	Operations.Performer AS Performer,
		|	Operations.ConnectionKey AS ConnectionKey,
		|	Operations.PerformerPosition AS PerformerPosition
		|FROM
		|	Operations AS Operations
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ProductionOrderBrigadeContent.Employee AS Employee,
		|	ProductionOrderBrigadeContent.LPR AS LPR,
		|	ProductionOrderBrigadeContent.StructuralUnit AS StructuralUnit,
		|	ProductionOrderBrigadeContent.ConnectionKey AS ConnectionKey
		|FROM
		|	Document.ProductionOrder.Brigade AS ProductionOrderBrigadeContent
		|WHERE
		|	ProductionOrderBrigadeContent.Ref = &ProductionOrder
		|	AND (ProductionOrderBrigadeContent.ConnectionKey IN
		|				(SELECT
		|					Operations.ConnectionKey
		|				FROM
		|					Operations
		|				WHERE
		|					Operations.Performer REFS Catalog.Teams)
		|			OR ProductionOrderBrigadeContent.ConnectionKey = 0
		|				AND ProductionOrderBrigadeContent.Ref.Performer REFS Catalog.Teams)";
		Result = Query.ExecuteBatch();
		Operations = Result[1].Unload();
		BrigadeContent = Result[2].Unload();
		Operations.Columns.Add("Brigade");
		For Each OperationRow In Operations Do
			If TypeOf(OperationRow.Performer)<>Type("СправочникСсылка.Teams") Then
				OperationRow.Brigade = BrigadeContent.CopyColumns();
				Continue;
			EndIf; 
			FilterStructure = New Structure;
			If OperationRow.PerformerPosition = Enums.AttributePositionOnForm.InHeader Then
				FilterStructure.Insert("ConnectionKey", 0);
			Else
				FilterStructure.Insert("ConnectionKey", OperationRow.ConnectionKey);
			EndIf;
			OperationRow.Brigade = BrigadeContent.Copy(FilterStructure);
		EndDo;
		Operations.Columns.Delete("ConnectionKey");
		Operations.Columns.Delete("PerformerPosition");
		
	Else
		
		Query.Text =
		"SELECT
		|	SpecificationsContent.Ref.Owner.MeasurementUnit AS MeasurementUnit,
		|	SpecificationsContent.Operation AS Operation,
		|	SpecificationsContent.Operation.FixedCost AS FixedCost,
		|	SpecificationsContent.TimeNorm / SpecificationsContent.ProductsQuantity AS TimeNorm,
		|	ISNULL(ProductsAndServicesSliceLast.Price * CASE
		|			WHEN ProductsAndServicesSliceLast.MeasurementUnit REFS Catalog.UOM
		|				THEN ProductsAndServicesSliceLast.MeasurementUnit.Factor
		|			ELSE 1
		|		END, 0) AS Pricing
		|FROM
		|	Catalog.Specifications.Operations AS SpecificationsContent
		|		LEFT JOIN InformationRegister.ProductsAndServicesPrices.SliceLast(
		|				&ProductionDate,
		|				PriceKind = VALUE(Catalog.PriceKinds.Accounting)
		|					AND Characteristic = VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)) AS ProductsAndServicesSliceLast
		|		ON SpecificationsContent.Operation = ProductsAndServicesSliceLast.ProductsAndServices
		|WHERE
		|	SpecificationsContent.Ref = &Specification
		|	AND (SpecificationsContent.Stage = &Stage
		|			OR &NoStages)";
		Operations = Query.Execute().Unload();
		
	EndIf; 
	
	Return Operations;
	
EndFunction

Function ProductAndServicesPresentation(TreeRow)
	
	If Not ValueIsFilled(TreeRow.ProductsAndServices) Then
		Return NStr("En='<Products and services not specified>';ru='<Номенклатура не указана>';vi='<Chưa chỉ ra mặt hàng>'");
	EndIf;
	
	Presentation = String(TreeRow.ProductsAndServices);
	If ValueIsFilled(TreeRow.Characteristic) Then
		Presentation = Presentation + ", " + String(TreeRow.Characteristic);
	EndIf; 
	If ValueIsFilled(TreeRow.Batch) Then
		Presentation = Presentation + ", " + String(TreeRow.Batch);
	EndIf; 
	If ValueIsFilled(TreeRow.Specification) Then
		Presentation = Presentation + ", " + String(TreeRow.Specification);
	EndIf; 
	
	Return Presentation;
	
EndFunction 

Function OrdersPresentation(TreeRow)
	
	If Not ValueIsFilled(TreeRow.CustomerOrder) And Not ValueIsFilled(TreeRow.ProductionOrder) Then
		Return NStr("En='<Wihtout order>';ru='<Без заказа>';vi='<Không có đơn hàng>'");
	EndIf;
	
	FillBothOrders = (ValueIsFilled(TreeRow.CustomerOrder) And ValueIsFilled(TreeRow.ProductionOrder));
	
	Presentation = "";
	If ValueIsFilled(TreeRow.CustomerOrder) Then
		Presentation = Presentation + ?(FillBothOrders, StrReplace(String(TreeRow.CustomerOrder), "Order ", ""), String(TreeRow.CustomerOrder));
		If ValueIsFilled(TreeRow.Counterparty) Then
			Presentation = Presentation + " (" + String(TreeRow.Counterparty) + ")";
		EndIf; 
	EndIf; 
	If ValueIsFilled(TreeRow.ProductionOrder) Then
		Presentation = Presentation + ?(FillBothOrders, ", ", "") + ?(FillBothOrders, StrReplace(String(TreeRow.ProductionOrder), "Order ", ""), String(TreeRow.ProductionOrder));
	EndIf; 
	
	Presentation = ?(FillBothOrders, NStr("en = 'Orders: '; ru = 'Заказы:'; vi = 'Đơn hàng:'"), "") + Presentation;
	
	Return Presentation;
	
EndFunction  

Function DocumentPresentation(Number, Date)
	
	WithoutIBPrefix = True;
	WithoutUserPrefix = True;
	Return StrTemplate(NStr("ru = '№%1 от %2';
							|en = '№%1 form %2';
							|vi = '№%1 ngày  %2';"), 
		ObjectPrefixationClientServer.GetNumberForPrinting(Number, WithoutIBPrefix, WithoutUserPrefix),
		Format(Date, "ДЛФ=D"));	
	
EndFunction

Function RecursiveErrorDescription(Information, UserMessage = Undefined)
	
	If Information.Cause=Undefined Then
		Error = BriefErrorDescription(Information);
	Else
		Error = RecursiveErrorDescription(Information.Cause);
	EndIf; 
	If UserMessage<>Undefined Then
		For Each Message In UserMessage Do
			If Find(Message.Text, LongActions.ProgressMessage()) > 0 Then
				Continue;
			EndIf;
			Error = Error+Chars.LF+Message.Text;
		EndDo; 
	EndIf; 
	Return Error	
	
EndFunction

Function EqualValue(OrderRow, Name)
	
	FirstValue = Undefined;
	For Each SubString In OrderRow.Rows Do
		If FirstValue=Undefined Then
			FirstValue = SubString[Name];
		ElsIf FirstValue<>SubString[Name] Then 
			FirstValue = Undefined;
			Break;
		EndIf; 
	EndDo; 
	
	Return FirstValue;
	
EndFunction

#EndRegion 

#EndIf

