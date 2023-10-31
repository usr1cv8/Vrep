
#Region ExportToMobileApplication

Function NeedToTransferData(Data, ExchangeNode) Export
	
	UseFilter = UseFilter(ExchangeNode);
	
	Transfer = True;
	
	If TypeOf(Data) = Type("DocumentObject.CustomerOrder")
		OR TypeOf(Data) = Type("DocumentRef.CustomerOrder") Then
		
		User = Users.CurrentUser();
		
		FiltersForExportDocuments = FiltersForExportDocuments();
		
		If UseFilter Then
			// Check that the organization corresponds to the unloaded.
			If Data.Company <> FiltersForExportDocuments.MainCompany
			 OR Data.Date < FiltersForExportDocuments.StartDateExport Then
				Transfer = False;
			EndIf;
			
			// If the responsible person is filled, then we unload it.
			If ValueIsFilled(FiltersForExportDocuments.MainResponsible)
			   AND ValueIsFilled(Data.Author) Then
				If Data.Author <> FiltersForExportDocuments.MainResponsible Then
					Transfer = False;
				EndIf;
			Else
				// Check that the author of the document - this is the current user
				If Data.Author <> User Then
					Transfer = False;
				EndIf;
			EndIf;
		EndIf;
		
		If Data.OperationKind <> Enums.OperationKindsCustomerOrder.OrderForSale Then
			Transfer = False;
		EndIf;
		
		If NOT Data.Posted Then
			Transfer = False;
		EndIf;
		
		For Each CurRow In Data.Inventory Do
			If TypeOf(CurRow.ProductsAndServices) = Type("CatalogRef.ProductsAndServices")
				AND CurRow.ProductsAndServices.ProductsAndServicesType = Enums.ProductsAndServicesTypes.Work Then
				Transfer = False;
				Break;
			EndIf;
		EndDo;
		
	ElsIf TypeOf(Data) = Type("DocumentObject.CustomerInvoice")
		OR TypeOf(Data) = Type("DocumentRef.CustomerInvoice") Then
		
		If IsVersionForOldExchange(ExchangeNode) Then
			Transfer = False;
		EndIf;
		
	ElsIf TypeOf(Data) = Type("DocumentObject.SupplierInvoice")
		OR TypeOf(Data) = Type("DocumentRef.SupplierInvoice") Then
		
		If IsVersionForOldExchange(ExchangeNode) Then
			Transfer = False;
		EndIf;
		
	ElsIf TypeOf(Data) = Type("DocumentObject.CashReceipt")
		OR TypeOf(Data) = Type("DocumentRef.CashReceipt") Then
		
		If IsVersionForOldExchange(ExchangeNode) Then
			Transfer = False;
		EndIf;
		
	ElsIf TypeOf(Data) = Type("DocumentObject.CashPayment")
		OR TypeOf(Data) = Type("DocumentRef.CashPayment") Then
		
		If IsVersionForOldExchange(ExchangeNode) Then
			Transfer = False;
		EndIf;
		
	ElsIf TypeOf(Data) = Type("CatalogObject.ProductsAndServices")
		OR TypeOf(Data) = Type("CatalogRef.ProductsAndServices") Then
		
		If NOT Data.IsFolder
		   AND Data.ProductsAndServicesType <> Enums.ProductsAndServicesTypes.InventoryItem
		   AND Data.ProductsAndServicesType <> Enums.ProductsAndServicesTypes.Service Then
			Transfer = False;
		EndIf;
		
	ElsIf TypeOf(Data) = Type("InformationRegisterRecordSet.ProductsAndServicesPrices") Then
		
		If Data.Filter.ProductsAndServices.Value.ProductsAndServicesType <> Enums.ProductsAndServicesTypes.InventoryItem
		   AND Data.Filter.ProductsAndServices.Value.ProductsAndServicesType <> Enums.ProductsAndServicesTypes.Service Then
			Transfer = False;
		EndIf;
		
		If ValueIsFilled(Data.Filter.Characteristic.Value) Then
			Transfer = False;
		EndIf;
		
	ElsIf TypeOf(Data) = Type("DocumentObject.InventoryAssembly")
		OR TypeOf(Data) = Type("DocumentRef.InventoryAssembly") Then
		
		If IsVersionForOldExchange(ExchangeNode) Then
			Transfer = False;
		EndIf;
		
		If NOT IsVersionForProduction(ExchangeNode) Then
			Transfer = False;
		EndIf;
		
	ElsIf TypeOf(Data) = Type("DocumentObject.ReceiptCR")
		OR TypeOf(Data) = Type("DocumentRef.ReceiptCR")
		OR TypeOf(Data) = Type("DocumentObject.ReceiptCRReturn") 
		OR TypeOf(Data) = Type("DocumentRef.ReceiptCRReturn")
		OR TypeOf(Data) = Type("DocumentObject.RetailReport")
		OR TypeOf(Data) = Type("DocumentRef.RetailReport") Then
		
		If IsVersionForOldExchange(ExchangeNode) Then
			Transfer = False;
		EndIf;
		
		If NOT IsVersionForRetail(ExchangeNode) Then
			Transfer = False;
		EndIf;
		
		CashCR = CashCRNode(ExchangeNode);
		
		If NOT ExchangeNode.ForAllCashRegisters
			AND ValueIsFilled(CashCR)
			AND Data.CashRegister <> CashCR Then
			Transfer = False;
		EndIf;
		
		If NOT Data.Posted Then
			Transfer = False;
		EndIf;
		
		For Each CurRow In Data.Inventory Do
			If CurRow.ProductsAndServices.ProductsAndServicesType = Enums.ProductsAndServicesTypes.Work Then
				Transfer = False;
				Break;
			EndIf;
		EndDo;
		
	EndIf;
	
	Return Transfer;
	
EndFunction // NeedToTransferData()

Procedure RegisterDataChanges(ExchangeNode)
	
	ExchangePlanContent = ExchangeNode.Metadata().Content;
	For Each ExchangePlanContentItem In ExchangePlanContent Do
		
		If CommonUse.IsDocument(ExchangePlanContentItem.Metadata) Then
			
			ObjectFullName = ExchangePlanContentItem.Metadata.FullName();
			If (IsVersionForOldExchange(ExchangeNode) AND ObjectFullName = "Document.CustomerOrder")
				OR (NOT IsVersionForOldExchange(ExchangeNode)) Then
				Selection = SelectionOfDocumentsForRegistration(ObjectFullName, ExchangeNode);
				
				While Selection.Next() Do
					
					Transfer = True;
					If ObjectFullName = "Document.CustomerOrder" Then
						Data = Selection.Ref.GetObject();
						For Each CurRow In Data.Inventory Do
							If TypeOf(CurRow.ProductsAndServices) = Type("CatalogRef.ProductsAndServices")
								AND CurRow.ProductsAndServices.ProductsAndServicesType = Enums.ProductsAndServicesTypes.Work Then
								Transfer = False;
								Break;
							EndIf;
						EndDo;
					EndIf;
					
					If Transfer Then
						ExchangePlans.RecordChanges(ExchangeNode, Selection.Ref);
					EndIf;
					
				EndDo;
			EndIf;
			
		Else
			
			ExchangePlans.RecordChanges(ExchangeNode, ExchangePlanContentItem.Metadata);
			
		EndIf;
		
	EndDo;
	
EndProcedure // RegisterDataChanges()

Function FiltersForExportDocuments()
	
	User = Users.CurrentUser();
	
	MainResponsible = SmallBusinessReUse.GetValueByDefaultUser(
		User,
		"MainResponsible"
	);
	
	MainCompany = SmallBusinessReUse.GetValueByDefaultUser(
		User,
		"MainCompany"
	);
	If NOT ValueIsFilled(MainCompany) Then
		MainCompany = Catalogs.Companies.CompanyByDefault();
	EndIf;
	
	ExportPeriodsInMobileApplication = SmallBusinessReUse.GetValueByDefaultUser(
		User,
		"MobileApplicationExportingsPeriod"
	);
	
	If ExportPeriodsInMobileApplication = Enums.ExportPeriodsInMobileApplication.RecentQuarter Then
		StartDate = BegOfQuarter(CurrentDate());
	ElsIf ExportPeriodsInMobileApplication = Enums.ExportPeriodsInMobileApplication.RecentMonth Then
		StartDate = BegOfMonth(CurrentDate());
	ElsIf ExportPeriodsInMobileApplication = Enums.ExportPeriodsInMobileApplication.RecentWeek Then
		StartDate = BegOfWeek(CurrentDate());
	ElsIf ExportPeriodsInMobileApplication = Enums.ExportPeriodsInMobileApplication.RecentDay Then
		StartDate = BegOfDay(CurrentDate());
	Else
		StartDate = '00010101';
	EndIf;
	
	FiltersForExportDocuments = New Structure;
	
	FiltersForExportDocuments.Insert("MainResponsible", MainResponsible);
	FiltersForExportDocuments.Insert("MainCompany", MainCompany);
	FiltersForExportDocuments.Insert("StartDateExport", StartDate);
	
	Return FiltersForExportDocuments;
	
EndFunction // FiltersForExportDocuments()

Function SelectionOfDocumentsForRegistration(ObjectFullName, ExchangeNode)
	
	UseFilter = UseFilter(ExchangeNode);
	
	FiltersForExportDocuments = FiltersForExportDocuments();

	Query = New Query;
	If ObjectFullName = "Document.CustomerOrder" Then
		If UseFilter Then
			QueryText =
			"SELECT
			|	Table.Ref As Ref 
			|FROM 
			|	[ObjectFullName] AS Table
			|WHERE 
			|	Table.Date >= &StartDateExport 
			|	AND Table.OperationKind = Value(Enum.OperationKindsCustomerOrder.OrderForSale) 
			|	AND Table.Company = &MainCompany 
			|	%FilterByResponsible% 
			|	AND Table.Posted";
			
			Query.SetParameter("StartDateExport", FiltersForExportDocuments.StartDateExport);
			Query.SetParameter("MainCompany", FiltersForExportDocuments.MainCompany);
			If ValueIsFilled(FiltersForExportDocuments.MainResponsible) Then
				QueryText = StrReplace(QueryText, "%FilterByResponsible%", "AND Table.Author = &Responsible");
				Query.SetParameter("Responsible", FiltersForExportDocuments.MainResponsible);
			Else
				QueryText = StrReplace(QueryText, "%FilterByResponsible%", "AND Table.Author = &Author");
				Query.SetParameter("Author", Users.CurrentUser());
			EndIf;
		Else
			QueryText =
			"SELECT
			|	Table.Ref AS Ref
			|FROM
			|	[ObjectFullName] AS Table
			|WHERE
			|	Table.OperationKind = VALUE(Enum.OperationKindsCustomerOrder.OrderForSale)
			|	AND Table.Posted";
		EndIf;
	ElsIf ObjectFullName = "Document.ReceiptCR"
		OR ObjectFullName = "Document.ReceiptCRReturn"
		OR ObjectFullName = "Document.RetailReport" Then

		QueryText =
		"SELECT
		|	Table.Ref AS Ref
		|FROM
		|	[ObjectFullName] AS Table
		|WHERE
		|	Table.Posted
		|	%FilterByCashCR%";
		
		CashCR = CashCRNode(ExchangeNode);
		
		If NOT ExchangeNode.ForAllCashRegisters
			AND ValueIsFilled(CashCR) Then
			QueryText = StrReplace(QueryText, "%FilterByCashCR%", "AND Table.CashCR = &CashCR");
			Query.SetParameter("CashCR", CashCR);
		Else
			QueryText = StrReplace(QueryText, "%FilterByCashCR%", "");
		EndIf;

	ElsIf IsVersionForOldExchange(ExchangeNode) Then
		Return Undefined;
	Else
		QueryText =
		"SELECT
		|	Table.Ref AS Ref
		|FROM
		|	[ObjectFullName] AS Table";
	EndIf;
	
	QueryText = StrReplace(QueryText, "[ObjectFullName]", ObjectFullName);
	Query.Text = QueryText;
	
	Return Query.Execute().Select();
	
EndFunction // SelectionOfDocumentsForRegistration()

Procedure AddMessageToMessageExchangeQueue(ExchangeNode, QueueMessageNumber, ExchangeMessage) Export
	
	RecordSet = InformationRegisters.QueuesOfMessagesExchangeWithMobileClients.CreateRecordSet();
	RecordSet.Filter.MobileClient.Set(ExchangeNode);
	RecordSet.Filter.MessageNumber.Set(QueueMessageNumber);
	RecordSet.Read();
	
	// If the message with this number is already in the queue, we will generate an exception.
	If RecordSet.Count() > 0 Then
		
		WriteLogEvent(
			NStr("en='Exchange with the mobile client. Adding a message to the message exchange queue';ru='Обмен с мобильным клиентом.Добавление сообщения в очередь сообщений обмена';vi='Trao đổi với Client di động. Thêm thông báo vào hàng đợi thông báo trao đổi'", CommonUseClientServer.MainLanguageCode()),
			EventLogLevel.Error,
			,
			ExchangeNode,
			NStr("ru = 'Очередь сообщений обмена уже содержит сообщение с номером" + QueueMessageNumber + ".'"));
			
		// Reset the counters of received and sent messages for re-registration and sending all data during the next exchange.
		ReinitializeMessageCountersOnExchangeNode(ExchangeNode);
		
		Raise(NStr("en='Failed to send data. Details see in the log of the information database.';ru='Не удалось выполнить отправку данных. Подробности см. в Журнале регистрации информационной базы.';vi='Không thể thực hiện gửi dữ liệu. Chi tiết xem trong Nhật ký sự kiện của cơ sở thông tin.'"));
		
	EndIf;
	
	NewRecord = RecordSet.Add();
	NewRecord.MobileClient = ExchangeNode;
	NewRecord.MessageNumber = QueueMessageNumber;
	NewRecord.PostExchange = ExchangeMessage;
	
	RecordSet.DataExchange.Load = True;
	RecordSet.Write(True);
	
EndProcedure // AddMessageToMessageExchangeQueue()

Function XMLWriteForExchangeMessage(ExchangeNode, MessageWriter) Export
	
	XMLWriter = New XMLWriter;
	
	XMLWriter.SetString("UTF-8");
	XMLWriter.WriteXMLDeclaration();
	
	MessageWriter = ExchangePlans.CreateMessageWriter();
	MessageWriter.BeginWrite(XMLWriter, ExchangeNode);
	
	XMLWriter.WriteNamespaceMapping("xsi", "http://www.w3.org/2001/XMLSchema-instance");
	XMLWriter.WriteNamespaceMapping("v8",  "http://v8.1c.ru/data");
	
	Return XMLWriter;
	
EndFunction

Procedure CheckQueueMessageExchange(ExchangeNode, Val ReceivedNo) 

	QueueMessageNumber = ReceivedNo + 1;
	
	Filter = New Structure("MobileClient", ExchangeNode);
	Order = "MessageNumber Asc";
	SelectionExchangeMessage = InformationRegisters.QueuesOfMessagesExchangeWithMobileClients.Select(Filter, Order);
	
	While SelectionExchangeMessage.Next() Do
		
		If SelectionExchangeMessage.MessageNumber < QueueMessageNumber Then
			
			Continue;
			
		ElsIf SelectionExchangeMessage.MessageNumber > QueueMessageNumber Then
			
			WriteLogEvent(
				NStr("en='Exchange with a mobile client. Check Message Exchange Queue';ru='Обмен с мобильным клиентом. Проверка очереди сообщений обмена';vi='Trao đổi với Client di động. Kiểm tra hàng đợi thông báo trao đổi'", CommonUseClientServer.MainLanguageCode()),
				EventLogLevel.Error,
				,
				SelectionExchangeMessage.MobileClient,
				NStr("en='Violated the order of the message exchange.';ru='Нарушен порядок следования сообщений обмена.';vi='Đã vi phạm trình tự theo dõi thông báo trao đổi.'"));
				
			// Reset the counters of received and sent messages for re-registration and sending all data during the next exchange.
			ReinitializeMessageCountersOnExchangeNode(ExchangeNode);
			
			Raise(NStr("en='Failed to send data. Details see in the log of the information database.';ru='Не удалось выполнить отправку данных. Подробности см. в Журнале регистрации информационной базы.';vi='Không thể thực hiện gửi dữ liệu. Chi tiết xem trong Nhật ký sự kiện của cơ sở thông tin.'"));
			
		EndIf;
		
		QueueMessageNumber = QueueMessageNumber + 1;
	EndDo;

EndProcedure

Function GenerateExchangeMessageQueue(ExchangeNode, ReceivedNo, NeedNodeInitialization = False, IsNewExchange = False, JobKey) Export
	
	SetPrivilegedMode(True);
	If NeedNodeInitialization Then
		ExchangePlans.DeleteChangeRecords(ExchangeNode);
		ClearQueueExchangeMessage(ExchangeNode);
		RegisterDataChanges(ExchangeNode);
	Else
		ClearQueueExchangeMessage(ExchangeNode, ReceivedNo);
	EndIf;
	
	QueueMessageNumber = ExchangeNode.SentNo;
	
	// Writing data to the queue.
	SerializeAndAddDataToExchangeMessageQueue(ExchangeNode, QueueMessageNumber, IsNewExchange);
	
	// Check the order of the message exchange.
	CheckQueueMessageExchange(ExchangeNode, ReceivedNo);
	
	// Remove registration of changes for messages exchanged in the queue.
	ExchangePlans.DeleteChangeRecords(ExchangeNode);
	
	Jobs = BackgroundJobs.GetBackgroundJobs(New Structure("Key", JobKey)); 
	If Jobs.Count() <> 0 Then
		InformationRegisters.SuccessfulBackgroundJobsInExchangeWithMobile.WriteJobID(ExchangeNode, Jobs[0].UUID);
	EndIf; 
	
EndFunction // GenerateExchangeMessageQueue()

Procedure SerializeAndAddDataToExchangeMessageQueue(ExchangeNode, QueueMessageNumber, IsNewExchange)
	
	MessageWriter = Undefined;
	XMLWriter = XMLWriteForExchangeMessage(ExchangeNode, MessageWriter);
	
	ReturnableList = ExchangeMobileApplicationExportRules.CreateXDTOObject("Objects");
	
	ObjectCount = 0; // Counter of objects
	
	// Recording directories and documents
	ExchangeMobileApplicationExportRules.SerializeCatalogsAndDocumentsAndAddInXDTOObject(MessageWriter, XMLWriter, ReturnableList, ExchangeNode, QueueMessageNumber, ObjectCount);
	
	// Write remains
	ExchangeMobileApplicationExportRules.SerializationInventoryRemainsAndAddInXDTOObject(MessageWriter, XMLWriter, ReturnableList, ExchangeNode, QueueMessageNumber, ObjectCount);
	
	If IsNewExchange Then
		// Write roles
		ExchangeMobileApplicationExportRules.SerializeRolesAndAddInXDTOObject(MessageWriter, XMLWriter, ReturnableList,ExchangeNode, QueueMessageNumber, ObjectCount);
		// Record company information.
		ExchangeMobileApplicationExportRules.SerializeCompanyInfoAndAddInXFDTOObject(ReturnableList, ObjectCount);
		// Settings of taxation
		ExchangeMobileApplicationExportRules.SerializeTaxSettingsAndAddInXDTOObject(MessageWriter, XMLWriter, ReturnableList, ExchangeNode, QueueMessageNumber, ObjectCount);
	EndIf;
	
	XDTOFactory.WriteXML(XMLWriter, ReturnableList);
	
	MessageWriter.EndWrite();
	ExchangeMessage = New ValueStorage(XMLWriter.Close());
	QueueMessageNumber = QueueMessageNumber + 1;
	AddMessageToMessageExchangeQueue(ExchangeNode, QueueMessageNumber, ExchangeMessage);

EndProcedure // SerializeAndAddDataToExchangeMessageQueue()

Procedure StartFormingMessageExchangeQueue(ExchangeNode, MobileDeviceCode, ReceivedNo, NeedNodeInitialization, JobID, IsNewExchange = False) Export
	
	JobKey = String(New UUID);
	
	Parameters = New Array;
	Parameters.Add(ExchangeNode);
	Parameters.Add(ReceivedNo);
	Parameters.Add(NeedNodeInitialization);
	Parameters.Add(IsNewExchange);
	Parameters.Add(JobKey);
	
	FunctionName = "ExchangeMobileApplicationCommon.GenerateExchangeMessageQueue";
	
	BackgroundJob = BackgroundJobs.Execute(
		FunctionName,
		Parameters,
		JobKey,
		MobileDeviceCode);
		
	JobID = BackgroundJob.UUID;
	
EndProcedure

Function ExchangeMessage(ExchangeNode, ExchangeMessageNumber, JobID) Export

	ResponseStructure = New Structure("Подождать, ПродолжитьЗагрузку, ПрерватьЗагрузку, СообщениеОбмена", False, True, False, Undefined);
	
	ExchangeMessage = MessageExchangeByNumber(ExchangeNode, ExchangeMessageNumber);
	If ExchangeMessage <> Undefined Then
		WriteLogEvent("MobileApplication", EventLogLevel.Information, , ,"Sent package " + String(ExchangeMessageNumber));
		ResponseStructure.СообщениеОбмена = ExchangeMessage;
		Return New ValueStorage(ResponseStructure, New Deflation(9));
	EndIf;
	
	// If the message is not in the queue, check the status of the background job.
	IsError = False;
	Message = "";
	MessageQueuingFormed = MessageQueuingFormed(JobID, ExchangeNode, IsError, Message);
	
	NeedToClearMessageQueue = False;
	// If there are errors, reset the message counters to re-send data during the next exchange session.
	If IsError Then
		ReinitializeMessageCountersOnExchangeNode(ExchangeNode);
		NeedToClearMessageQueue = True;
		ResponseStructure.ПрерватьЗагрузку = True;
		ResponseStructure.ПродолжитьЗагрузку = False;
		ResponseStructure.Подождать = False;
		Return New ValueStorage(ResponseStructure, New Deflation(9));
	EndIf;
	
	// If there are no messages and the queue has been formed, we consider that all the packets have been successfully received, otherwise we expect packets.
	If MessageQueuingFormed Then
		ResponseStructure.Подождать = False;
		ResponseStructure.ПродолжитьЗагрузку = False;
		NeedToClearMessageQueue = True;
	Else
		ResponseStructure.Подождать = True;
		ResponseStructure.ПродолжитьЗагрузку = NOT IsError;
	EndIf;
	
	ResponseStructure.ПрерватьЗагрузку = IsError;
	
	If NeedToClearMessageQueue Then
		
		Filter = New Structure("Key", String(JobID));
		JobArray = BackgroundJobs.GetBackgroundJobs(Filter);
		
		If JobArray.Count() = 0  Then // If cleaning did not start, then run.
			
			Parameters = New Array;
			Parameters.Add(ExchangeNode);
			Parameters.Add(Undefined);
			Parameters.Add(JobID);
			
			FunctionName = "ExchangeMobileApplicationCommon.ClearQueueExchangeMessage";
			
			BackgroundJob = BackgroundJobs.Execute(
				FunctionName,
				Parameters,
				String(JobID),
				NStr("en='Clearing the Message Queuing with the Mobile Client';ru='Очистка очереди сообщений с мобильным клиентом';vi='Xóa hàng đợi thông báo với Client di động'"));
				
			ResponseStructure.Подождать = True; // Let's wait for cleaning
			ResponseStructure.ПродолжитьЗагрузку = True;
			
		Else
			
			If JobArray[0].State = BackgroundJobState.Active Then
				ResponseStructure.Подождать = True; // Let's wait for cleaning
				ResponseStructure.ПродолжитьЗагрузку = True;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return New ValueStorage(ResponseStructure, New Deflation(9));

EndFunction

#EndRegion

#Region ImportFromMobileApplication

Function MessageQueuingFormed(JobID, ExchangeNode, IsError, Message = "")

	Try
		JobIsCompleted = LongActions.JobCompleted(JobID);
		Return JobIsCompleted;
	Except		
		If InformationRegisters.SuccessfulBackgroundJobsInExchangeWithMobile.IsSuccessfulJob(ExchangeNode, JobID) Then
			Return True;		
		EndIf; 
		Message = DetailErrorDescription(ErrorInfo());
		IsError = True;
		WriteLogEvent("Debug", EventLogLevel.Error,,, "Идентификатор задания " + String(JobID));
		Return False;
	EndTry;
	
EndFunction // MessageQueuingFormed()

Function MessageExchangeByNumber(ExchangeNode, ExchangeMessageNumber)

	Query = New Query;
	Query.Text = 
	"SELECT
	|	QueuesOfMessagesExchangeWithMobileClients.PostExchange
	|FROM
	|	InformationRegister.QueuesOfMessagesExchangeWithMobileClients AS QueuesOfMessagesExchangeWithMobileClients
	|WHERE
	|	QueuesOfMessagesExchangeWithMobileClients.MobileClient = &MobileClient
	|	AND QueuesOfMessagesExchangeWithMobileClients.MessageNumber = &MessageNumber";
	
	Query.SetParameter("MobileClient", ExchangeNode);
	Query.SetParameter("MessageNumber", ExchangeMessageNumber);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return Undefined;
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	
	Return Selection.PostExchange;

EndFunction // ExchangeMessageByNumber()

Function ChangesToTabularSectionAreAvailable(Object, TabSection) Export
	
	BreakFilling = False;
	ColumnsTabs = Object[TabSection].UnloadColumns().Columns;
	
	For Each CurRow In Object[TabSection] Do
		If ValueIsFilled(CurRow.ProductsAndServices)
			AND TypeOf(CurRow.ProductsAndServices) <> Type("CatalogRef.ProductsAndServices") Then
			BreakFilling = True;
		EndIf;
		If TypeOf(CurRow.ProductsAndServices) = Type("CatalogRef.ProductsAndServices")
			AND CurRow.ProductsAndServices.ProductsAndServicesType <> Enums.ProductsAndServicesTypes.InventoryItem
			AND CurRow.ProductsAndServices.ProductsAndServicesType <> Enums.ProductsAndServicesTypes.Service Then
			BreakFilling = True;
		EndIf;
		If (ColumnsTabs.Find("Characteristic") <> Undefined
			AND ValueIsFilled(CurRow.Characteristic)) Then
			BreakFilling = True;
		EndIf;
		If (ColumnsTabs.Find("Batch") <> Undefined
			AND ValueIsFilled(CurRow.Batch)) Then
			BreakFilling = True;
		EndIf;
		If (ColumnsTabs.Find("SerialNumbers") <> Undefined
			AND ValueIsFilled(CurRow.SerialNumbers)) Then
			BreakFilling = True;
		EndIf;
		If (ColumnsTabs.Find("Reserve") <> Undefined
			AND ValueIsFilled(CurRow.Reserve)) Then
			BreakFilling = True;
		EndIf;
		If (ColumnsTabs.Find("ReserveShipment") <> Undefined
			AND ValueIsFilled(CurRow.ReserveShipment)) Then
			BreakFilling = True;
		EndIf;
		If (ColumnsTabs.Find("Specification") <> Undefined
			AND ValueIsFilled(CurRow.Specification)) Then
			BreakFilling = True;
		EndIf;
		If (ColumnsTabs.Find("AutomaticDiscountsPercent") <> Undefined
			AND ValueIsFilled(CurRow.AutomaticDiscountsPercent)) Then
			BreakFilling = True;
		EndIf;
		If (ColumnsTabs.Find("AutomaticDiscountAmount") <> Undefined
			AND ValueIsFilled(CurRow.AutomaticDiscountAmount)) Then
			BreakFilling = True;
		EndIf;
		If (ColumnsTabs.Find("StructuralUnit") <> Undefined
			AND ValueIsFilled(CurRow.StructuralUnit)
			AND CurRow.StructuralUnit <> Object.StructuralUnit) Then
			BreakFilling = True;
		EndIf;
		If (ColumnsTabs.Find("BusinessActivity") <> Undefined
			AND ValueIsFilled(CurRow.BusinessActivity)) Then
			BreakFilling = True;
		EndIf;
	EndDo;
	Return BreakFilling;
	
EndFunction

Procedure ProcessAcceptedImportedPackage(ExchangeNode, ExchangeData, ClearChanges = False, IsNewExchange = False) Export
	
	XMLReader = New XMLReader;
	XMLReader.SetString(ExchangeData.Get());
	ExchangeMessage = ExchangePlans.CreateMessageReader();
	ExchangeMessage.BeginRead(XMLReader);
	
	If ClearChanges Then
		ExchangePlans.DeleteChangeRecords(ExchangeMessage.Sender, ExchangeMessage.ReceivedNo);
	EndIf;
	
	XDTOObjectType = XDTOFactory.Type("http://www.1c.com.vn/CM/MobileExchange", "Objects");
	
	Objects = XDTOFactory.ReadXML(XMLReader, XDTOObjectType);
	
	ExchangeMobileApplicationImportRules.ImportObjects(ExchangeNode, Objects, IsNewExchange);
	
	ExchangeMessage.EndRead();
	XMLReader.Close();
	
EndProcedure // ProcessAcceptedImportedPackage()

#EndRegion

#Region Events

Procedure ExchangeMobileApplicationOnWriteDocument(Source, Cancel, WriteMode, PostingMode) Export
	
	SetPrivilegedMode(True);
	ArrayOfNodesForRegistration = New Array;
	
	Selection = ExchangePlans.MobileApplications.Select();
	While Selection.Next() Do
		If Selection.Ref <> ExchangePlans.MobileApplications.ThisNode() Then
			NeedToExport = False;
			If TypeOf(Source) = Type("DocumentObject.CustomerOrder")
			   AND Source.OperationKind = Enums.OperationKindsCustomerOrder.OrderForSale
			   AND Source.Posted Then
				NeedToExport = True;
				For Each CurRow In Source.Inventory Do
					If TypeOf(CurRow.ProductsAndServices) = Type("CatalogRef.ProductsAndServices")
						AND CurRow.ProductsAndServices.ProductsAndServicesType = Enums.ProductsAndServicesTypes.Work Then
						NeedToExport = False;
						Break;
					EndIf;
				EndDo;
			EndIf;
			If NOT IsVersionForOldExchange(Selection.Ref) Then
				If TypeOf(Source) = Type("DocumentObject.CashReceipt")
					OR TypeOf(Source) = Type("DocumentObject.CashPayment") 
					OR TypeOf(Source) = Type("DocumentObject.SupplierInvoice")
					OR TypeOf(Source) = Type("DocumentObject.CustomerInvoice") Then
					NeedToExport = True;
				EndIf;
			EndIf;
			If IsVersionForProduction(Selection.Ref) Then
				If TypeOf(Source) = Type("DocumentObject.InventoryAssembly") Then
					NeedToExport = True;
				EndIf;
			EndIf;
			If IsVersionForRetail(Selection.Ref) Then
				If TypeOf(Source) = Type("DocumentObject.ReceiptCR")
					OR TypeOf(Source) = Type("DocumentObject.ReceiptCRReturn") 
					OR TypeOf(Source) = Type("DocumentObject.RetailReport") Then
					CashCR = CashCRNode(Selection.Ref);
					If NOT ValueIsFilled(CashCR) Then
						NeedToExport = True;
					EndIf;
					If ValueIsFilled(CashCR)
						AND Source.CashCR = CashCR Then
						NeedToExport = True;
					EndIf;
					If Selection.ForAllCashRegisters Then
						NeedToExport = True;
					EndIf;
				EndIf;
			EndIf;
			If NeedToExport Then
				ArrayOfNodesForRegistration.Add(Selection.Ref);
			EndIf;
		EndIf;
	EndDo;
	
	If ArrayOfNodesForRegistration.Count() > 0 Then
		ExchangePlans.RecordChanges(ArrayOfNodesForRegistration, Source.Ref);
	EndIf;
	SetPrivilegedMode(False);
	
EndProcedure // ExchangeMobileApplicationOnWriteDocument()

Procedure ExchangeMobileApplicationOnWriteRegister(Source, Cancel, Replacing) Export
	
	If Source.DataExchange.Load = True Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	MobileApplications.Ref
	|FROM
	|	ExchangePlan.MobileApplications AS MobileApplications
	|WHERE
	|	MobileApplications.Ref <> &ThisNode";
	
	Query.SetParameter("ThisNode", ExchangePlans.MobileApplications.ThisNode());
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	If (TypeOf(Source) = Type("AccumulationRegisterRecordSet.InvoicesAndOrdersPayment")
		OR TypeOf(Source) = Type("AccumulationRegisterRecordSet.CustomerOrders")) Then
		If TypeOf(Source) = Type("AccumulationRegisterRecordSet.InvoicesAndOrdersPayment") Then
			Query = New Query(
				"SELECT
				|	InvoicesAndOrdersPayment.InvoiceForPayment AS Order,
				|	TRUE AS Register
				|FROM
				|	AccumulationRegister.InvoicesAndOrdersPayment AS InvoicesAndOrdersPayment
				|WHERE
				|	InvoicesAndOrdersPayment.Recorder = &Recorder
				|	AND InvoicesAndOrdersPayment.InvoiceForPayment.OperationKind = &OperationKind
				|
				|GROUP BY
				|	InvoicesAndOrdersPayment.InvoiceForPayment"
			);
		ElsIf TypeOf(Source) = Type("AccumulationRegisterRecordSet.CustomerOrders") Then
			Query = New Query(
				"SELECT
				|	CustomerOrders.CustomerOrder AS Order,
				|	TRUE AS Register
				|FROM
				|	AccumulationRegister.CustomerOrders AS CustomerOrders
				|WHERE
				|	CustomerOrders.Recorder = &Recorder
				|	AND CustomerOrders.CustomerOrder.OperationKind = &OperationKind
				|
				|GROUP BY
				|	CustomerOrders.CustomerOrder"
			);
		EndIf;
		Query.SetParameter("Recorder", Source.Filter.Recorder.Value);
		Query.SetParameter("OperationKind", Enums.OperationKindsCustomerOrder.OrderForSale);
		TableOrder = Query.Execute().Unload();
		For Each CurRow In TableOrder Do
			ObjectOrder = CurRow.Order.GetObject();
			For Each Row In ObjectOrder.Inventory Do
				If TypeOf(Row.ProductsAndServices) = Type("CatalogRef.ProductsAndServices")
					AND Row.ProductsAndServices.ProductsAndServicesType = Enums.ProductsAndServicesTypes.Work Then
					CurRow.Register = False;
					Break;
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	
	ArrayOfNodesForRegistration = New Array;
	MainKindOfSalePrice = Catalogs.PriceKinds.GetMainKindOfSalePrices(); 
	
	Selection = QueryResult.Select();
	While Selection.Next() Do
		If Selection.Ref <> ExchangePlans.MobileApplications.ThisNode() Then
			If TypeOf(Source) = Type("InformationRegisterRecordSet.ProductsAndServicesPrices") Then
				If Source.Filter.PriceKind.Value = MainKindOfSalePrice
					AND NOT ValueIsFilled(Source.Filter.Characteristic.Value) Then
					ArrayOfNodesForRegistration.Add(Selection.Ref);
				EndIf;
			ElsIf TypeOf(Source) = Type("InformationRegisterRecordSet.ProductsAndServicesBarcodes") Then
				ArrayOfNodesForRegistration.Add(Selection.Ref);
			Else
				For Each CurRow In TableOrder Do
					If ValueIsFilled(CurRow.Order)
					   AND CurRow.Register Then
						ArrayOfNodesForRegistration.Add(Selection.Ref);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndDo;
	
	If ArrayOfNodesForRegistration.Count() > 0 Then
		If TypeOf(Source) = Type("InformationRegisterRecordSet.ProductsAndServicesPrices") Then
			If Source.Filter.PriceKind.Value = MainKindOfSalePrice
				AND NOT ValueIsFilled(Source.Filter.Characteristic.Value) Then
				For Each CurrentRecord In Source Do
					RecordSet = InformationRegisters.ProductsAndServicesPrices.CreateRecordSet();
					RecordSet.Filter.Period.Set(CurrentRecord.Period);
					RecordSet.Filter.ProductsAndServices.Set(CurrentRecord.ProductsAndServices);
					RecordSet.Filter.PriceKind.Set(CurrentRecord.PriceKind);
					RecordSet.Filter.Characteristic.Set(CurrentRecord.Characteristic);
					ExchangePlans.RecordChanges(ArrayOfNodesForRegistration, RecordSet);
				EndDo;
			EndIf;
		ElsIf TypeOf(Source) = Type("InformationRegisterRecordSet.ProductsAndServicesBarcodes") Then
			ProductsTable = Source.Unload();
			For Each CurRow In ProductsTable Do
				If ValueIsFilled(CurRow.ProductsAndServices)
				   AND CurRow.ProductsAndServices.ProductsAndServicesType <> Enums.ProductsAndServicesTypes.Work
				   AND NOT ValueIsFilled(CurRow.Characteristic)
				   AND NOT ValueIsFilled(CurRow.Batch) Then
					ExchangePlans.RecordChanges(ArrayOfNodesForRegistration, CurRow.ProductsAndServices);
				EndIf;
			EndDo;
		Else
			For Each CurRow In TableOrder Do
				If ValueIsFilled(CurRow.Order)
				   AND CurRow.Register Then
					ExchangePlans.RecordChanges(ArrayOfNodesForRegistration, CurRow.Order);
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure // ExchangeMobileApplicationOnWriteRegister()

Procedure ExchangeMobileApplicationOnWrite(Source, Cancel) Export
	
	SetPrivilegedMode(True);
	ArrayOfNodesForRegistration = New Array;
	
	Selection = ExchangePlans.MobileApplications.Select();
	While Selection.Next() Do
		If Selection.Ref <> ExchangePlans.MobileApplications.ThisNode() Then
			If TypeOf(Source) = Type("CatalogObject.ProductsAndServices")
			   AND (Source.ProductsAndServicesType = Enums.ProductsAndServicesTypes.InventoryItem
			   OR Source.ProductsAndServicesType = Enums.ProductsAndServicesTypes.Service) Then
				ArrayOfNodesForRegistration.Add(Selection.Ref);
			EndIf;
			If TypeOf(Source) = Type("CatalogObject.StructuralUnits")
			   AND Source.StructuralUnitType = Enums.StructuralUnitsTypes.Retail Then
				ArrayOfNodesForRegistration.Add(Selection.Ref);
			EndIf;
		EndIf;
	EndDo;
	
	If ArrayOfNodesForRegistration.Count() > 0 Then
		ExchangePlans.RecordChanges(ArrayOfNodesForRegistration, Source.Ref);
	EndIf;
	SetPrivilegedMode(False);
	
EndProcedure // ExchangeMobileApplicationOnWrite()

#EndRegion

#Region ServiceProceduresAndFunctions

Function IsVersionWithNewExchange()
	
	Return "1.2.33.1";

EndFunction

Function VersionForProduction()
	
	Return "1.2.60.1";

EndFunction

Function VersionForRetail()
	
	Return "1.2.80.1";

EndFunction

Function UseFilter(ExchangeNode)
	
	If NOT ValueIsFilled(ExchangeNode) Then
		Return False;
	EndIf;
	
	Return ExchangeNode.ByResponsible;
	
EndFunction

Function CashCRNode(ExchangeNode) Export
	
	If NOT ValueIsFilled(ExchangeNode) Then
		Return Undefined;
	EndIf;
	
	Return ExchangeNode.CashRegister;
	
EndFunction

Function IsVersionForOldExchange(ExchangeNode) Export
	
	If NOT ValueIsFilled(ExchangeNode.MobileAppVersion) Then
		Return True;
	EndIf;
	
	If ValueIsFilled(ExchangeNode.MobileAppVersion) Then
		Return CommonUseClientServer.CompareVersions(IsVersionWithNewExchange(), ExchangeNode.MobileAppVersion) > 0;
	Else
		Return True;
	EndIf;

EndFunction

Function IsVersionForProduction(ExchangeNode) Export
	
	If NOT ValueIsFilled(ExchangeNode.MobileAppVersion) Then
		Return True;
	EndIf;
	
	If ValueIsFilled(ExchangeNode.MobileAppVersion) Then
		Return CommonUseClientServer.CompareVersions(ExchangeNode.MobileAppVersion, VersionForProduction()) >= 0;
	Else
		Return True;
	EndIf;

EndFunction

Function IsVersionForRetail(ExchangeNode) Export
	
	If NOT ValueIsFilled(ExchangeNode.MobileAppVersion) Then
		Return True;
	EndIf;
	
	If ValueIsFilled(ExchangeNode.MobileAppVersion) Then
		Return CommonUseClientServer.CompareVersions(ExchangeNode.MobileAppVersion, VersionForRetail()) >= 0;
	Else
		Return True;
	EndIf;

EndFunction

Procedure ClearQueueExchangeMessage(MobileClient, MessageNumber = Undefined, JobID = "") Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	QueuesOfMessagesExchangeWithMobileClients.MessageNumber
	|FROM
	|	InformationRegister.QueuesOfMessagesExchangeWithMobileClients AS QueuesOfMessagesExchangeWithMobileClients
	|WHERE
	|	QueuesOfMessagesExchangeWithMobileClients.MobileClient = &MobileClient
	|	AND (&MessageNumber = UNDEFINED
	|			OR QueuesOfMessagesExchangeWithMobileClients.MessageNumber <= &MessageNumber)";
	
	Query.SetParameter("MobileClient", MobileClient);
	Query.SetParameter("MessageNumber", MessageNumber);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	RecordSet = InformationRegisters.QueuesOfMessagesExchangeWithMobileClients.CreateRecordSet();
	RecordSet.DataExchange.Load = True;
	
	MessageSelection = Result.Select();
	While MessageSelection.Next() Do
		
		RecordSet.Filter.MobileClient.Set(MobileClient);
		RecordSet.Filter.MessageNumber.Set(MessageSelection.MessageNumber);
		
		RecordSet.Write(True);
		
	EndDo;
	
	InformationRegisters.SuccessfulBackgroundJobsInExchangeWithMobile.WriteJobID(MobileClient, JobID); 
	
EndProcedure // ClearQueueExchangeMessage()

Procedure ReinitializeMessageCountersOnExchangeNode(ExchangeNode)
	
	SetPrivilegedMode(True);
	
	ObjectOfExchangeNode = ExchangeNode.GetObject();
	ObjectOfExchangeNode.ReceivedNo = 0;
	ObjectOfExchangeNode.SentNo = 0;
	ObjectOfExchangeNode.Write();
	
	SetPrivilegedMode(False);
	
EndProcedure // ReinitializeMessageCountersOnExchangeNode()

Function GetPicture(Ref) Export
	
	File = Ref.PictureFile;
	BinaryData = AttachedFiles.GetFileBinaryData(File);
	XDTOSerializer = New XDTOSerializer(XDTOFactory);
	
	Try
		XDTOPicture = XDTOSerializer.WriteXDTO(BinaryData);
	Except
		Raise ErrorDescription();
	EndTry;
	
	Return XDTOPicture;
	
EndFunction

Function AuthenticationData()
	
	Return "AIzaSyB75SosZcatLAMPFw17Zgs5MnxoH3AtBcI";
	
EndFunction

#EndRegion

