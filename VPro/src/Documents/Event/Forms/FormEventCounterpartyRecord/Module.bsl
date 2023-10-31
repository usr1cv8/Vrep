
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetFormConditionalAppearance();
	
	Items.ContactsContact.TypeRestriction = New TypeDescription("String",, New StringQualifiers(100));
	
	If ValueIsFilled(Object.Ref) Then
		DocumentDate = Object.Date;
	Else
		OnCreateReadAtServer(Object);
		AutoTitle = False;
		Title = NStr("en='Event: Record (create)';ru='Событие: Запись (создание)';vi='Sự kiện: Bản ghi (tạo)'");
		
		Object.EventType = Enums.EventTypes.Record;
		
		Object.EnterpriseResources.Clear();
		
		DocumentDate = CurrentSessionDate();
	EndIf;
	
	ObjectVersioning.OnCreateAtServer(ThisObject);
	PropertiesManagement.OnCreateAtServer(ThisObject,);
	
	ConfigureMobileClientForm();
	
	OpenFormPlanner = Parameters.Property("SelectedResources");
	
	If OpenFormPlanner And Not ThisForm.ReadOnly Then
		FillResourcesFromPlanner(Parameters.SelectedResources);
		
		If Parameters.Property("Counterparty") And ValueIsFilled(Parameters.Counterparty) Then
			Counterparty = Parameters.Counterparty;
			CounterpartyOnChangeServer();
		EndIf;
		
	EndIf;
	
	Items.GroupLinks.Visible = False;
	
	If GetFunctionalOption("PlanCompanyResourcesLoadingWorks") Then
		Items.GroupLinks.Visible = True;
		FillSubordinateWorkOrders();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	FormManagement();
	
	// СтандартныеПодсистемы.ПодключаемыеКоманды
	//AttachableCommandsClient.НачатьОбновлениеКоманд(ThisObject);
	// Конец СтандартныеПодсистемы.ПодключаемыеКоманды
	
	SetupRepeatAvailable(True);
	FillDataResourceTableOnForm();
	
	UpdateListSubordinateWorkOrders();
	
	//Ресурсы
	If OpenFormPlanner And ValueIsFilled(Object.Ref) Then
		If Not Items.Find("PegeResources") = Undefined Then
			ThisForm.CurrentItem = Items.PegeResources;
		EndIf;
	EndIf;
	
	If Not CommonUseClientServer.FormItemPropertyValue(Items, "Pages", "CurrentPage") = Undefined Then
		If Items.Pages.CurrentPage.Name = "PegeResources" Then
			SetupRepeatAvailable(True);
			FillDataResourceTableOnForm();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateListSubordinateWorkOrders()
	
	Items.ExistingWorkOrders.Visible = False;
	
	If Not ValueIsFilled(Object.Ref) Then Return EndIf;
	
	Items.NavigateRefWorkOrder.Visible = True;
	
	If Not WorkOrdersList.Count() Then Return EndIf;
	
	WorkOrderValue = WorkOrdersList[0].Value;
	DeletionMark = WorkOrdersList[0].Check;
	
	If DeletionMark Then
		ValueDescription = StrReplace(String(WorkOrderValue), "DocOrder-outfit", "") +NStr("ru = '(mark on deletion)';
			|en='(mark on deletion)';vi='(đánh dấu xóa)';");
	Else
		ValueDescription = StrReplace(String(WorkOrderValue), "DocOrder-outfit", "");
	EndIf;
	
	ValueDescription = TrimAll(ValueDescription);
	
	If WorkOrdersList.Count() > 1 Then
		ValueDescription = ValueDescription + "...";
	EndIf;
	
	Items.ExistingWorkOrders.Title = ValueDescription;
	Items.ExistingWorkOrders.Visible = True;
	Items.NavigateRefWorkOrder.Visible = False;
	
EndProcedure

&AtServer
Procedure FillSubordinateWorkOrders()
	
	WorkOrdersList.Clear();
	
	Query = New Query;
	
	Query.SetParameter("Event", Object.Ref);
	
	Query.Text = 
	"SELECT ALLOWED
	|	CustomerOrder.Ref AS Ref,
	|	CustomerOrder.DeletionMark AS DeletionMark
	|FROM
	|	Document.CustomerOrder AS CustomerOrder
	|WHERE
	|	CustomerOrder.OperationKind = VALUE(Enum.OperationKindsCustomerOrder.WorkOrder)
	|	AND CustomerOrder.Event = &Event
	|	AND CustomerOrder.Posted";
	
	Result = Query.Execute().Select();
	
	OrdersList = New ValueList;
	
	While Result.Next() Do
		WorkOrdersList.Add(Result.Ref,,Result.DeletionMark);
	EndDo;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// СтандартныеПодсистемы.Свойства
	If PropertiesManagementClient.ProcessAlerts(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertiesManagementClient.AfterLoadAdditionalAttributes(ThisObject);
	EndIf;
	// Конец СтандартныеПодсистемы.Свойства
	
	If EventName = "ПроведениеЗаказНаряда" Then
		If ValueIsFilled(Parameter.СсылкаНаСобытие) And Parameter.СсылкаНаСобытие = Object.Ref Then
			FoundValue = WorkOrdersList.FindByValue(Parameter.СсылкаНаЗаказНаряд);
			If FoundValue = Undefined Then
				WorkOrdersList.Add(Parameter.СсылкаНаЗаказНаряд)
			EndIf;
			UpdateListSubordinateWorkOrders();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	
	If EventConnectedToCall 
		And ChoiceSource.FormName = "Catalog.Counterparties.Form.ItemForm" 
		And Not ValueIsFilled(Counterparty) And ValueIsFilled(SelectedValue) Then
		
		Counterparty = SelectedValue;
		CounterpartyOnChangeServer();
		Write();
	EndIf;
	
EndProcedure

&AtClient
Procedure NewWriteProcessing(NewObject, Source, StandardProcessing)
	
	If ValueIsFilled(СопоставитьКонтактКакСвязаться) Then
		StandardProcessing = False;
		СопоставитьКонтактКонтактнуюИнформацию(NewObject, СопоставитьКонтактКакСвязаться);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnCreateReadAtServer(CurrentObject);
	
	// СтандартныеПодсистемы.Свойства
	PropertiesManagement.OnReadAtServer(ThisObject, CurrentObject);
	// Конец СтандартныеПодсистемы.Свойства
		
	ResourcePlanningCM.RefillServiceAttributesResourceTable(Object.EnterpriseResources);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	// СтандартныеПодсистемы.ОценкаПроизводительности
	//PerformanceEstimationClient.StartTimeMeasurement(True, "Record"+ WorkWithDocumentFormClientServer.StringFormName(ThisObject.FormName));
	// СтандартныеПодсистемы.ОценкаПроизводительности
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Modified Then
		NotifyWorkCalendar = True;
	EndIf;
	
	WriteAttributes(CurrentObject);
	
	If TypeOf(CurrentObject.Subject) = Type("String") Then
	// Сохрание тем в истории для автоподбора
		
		HistoryItem = SubjectRowHistory.FindByValue(TrimAll(CurrentObject.Subject));
		If HistoryItem <> Undefined Then
			SubjectRowHistory.Delete(HistoryItem);
		EndIf;
		SubjectRowHistory.Insert(0, TrimAll(CurrentObject.Subject));
		
		CommonUse.CommonSettingsStorageSave("ThemeEventsChoiceList", "", SubjectRowHistory.UnloadValues());
		
	EndIf;
	
	// СтандартныеПодсистемы.Свойства
	PropertiesManagement.BeforeWriteAtServer(ThisObject, CurrentObject);
	// Конец СтандартныеПодсистемы.Свойства
	
	// Обсуждения
	CurrentObject.AdditionalProperties.Insert("Modified",Modified);
	// Конец Обсуждения
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	//ExchangeWithGoogle.УвеличитьЗначениеСчетчикаПодсказок(ThisForm);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Title = "";
	AutoTitle = True;
	
	// УНФ.КалендарьСотрудника
	Notify("Record_SourceRecordsEmployeeCalendar");
	// Конец УНФ.КалендарьСотрудника
	
	If OpenFormPlanner Then Notify("UpdatePlanner") EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	OnCreateReadAtServer(CurrentObject);
	
	// Обсуждения
	//ОбсужденияСервер.AfterWriteAtServer(CurrentObject);
	// Конец Обсуждения
	
	ResourcePlanningCM.RefillServiceAttributesResourceTable(Object.EnterpriseResources);
	
	//АссистентУправления.ВыполнитьТекущиеЗадачиСейчас(CurrentObject.Ref);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	For Each RowContacts In Contacts Do
		If Not ValueIsFilled(RowContacts.Contact) And Not ValueIsFilled(RowContacts.HowToContact) Then
			CommonUse.MessageToUser(
				CommonUseClientServer.TextFillingErrors("Column", "FillType", "Contact", Contacts.IndexOf(RowContacts) + 1, "Attendees"),
				,
				StringFunctionsClientServer.SubstituteParametersInString("Contacts[%1].Contact", Contacts.IndexOf(RowContacts)),
				,
				Cancel
			);
		EndIf;
	EndDo;
	
	// СтандартныеПодсистемы.Свойства
	PropertiesManagement.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// Конец СтандартныеПодсистемы.Свойства
	
EndProcedure

&AtClient
Procedure OnClose()
	
	If NotifyWorkCalendar Then
		Notify("EventChanged", Object.Responsible);
	EndIf;
	
EndProcedure

#EndRegion

#Region HeaderFormItemsEventsHandlers

&AtClient
Procedure СуществующиеЗаказНарядыНажатие(Item)
	
	If WorkOrdersList.Count() = 1 Then 
		OpenForm("Document.CustomerOrder.Form.FormWorkOrder", New Structure("Key", WorkOrdersList[0].Value),ThisForm);
		Return;
	EndIf;
		
	Notification = New NotifyDescription("ПослеВыбораЭлемента", ThisForm);
	
	WorkOrdersList.ShowChooseItem(Notification, NStr("en='Subordinate docorder-jobs';vi='Công việc chứng từ cấp dưới';"));
	
EndProcedure

&AtClient
Procedure ПослеВыбораЭлемента(ListElement, Parameters) Export
	
	If Not ListElement = Undefined And TypeOf(ListElement.Value) = Type("DocumentRef.CustomerOrder") Then
		OpenForm("Document.CustomerOrder.Form.FormWorkOrder", New Structure("Key", ListElement.Value),ThisForm)
	EndIf;
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	
	// Обработка события изменения даты.
	DateBeforeChange = DocumentDate;
	DocumentDate = Object.Date;
	If DocumentDate <> DateBeforeChange Then
		StructureData = GetDataDateOnChange(Object.Ref, Object.Date, DateBeforeChange);
		If StructureData.Datediff <> 0 Then
			Object.Number = "";
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	
EndProcedure

&AtClient
Procedure CounterpartyChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	If TypeOf(SelectedValue) = Type("Type") Then
		ОпределитьТипПоляКонтргент(SelectedValue);
	EndIf;
	
EndProcedure

&AtClient
Procedure CounterpartyCreating(Item, StandardProcessing)
	
	If Not EventConnectedToCall Then
		Return;
	EndIf;
	
	If ValueIsFilled(Counterparty) Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	Write();
	
	OpenParameters = New Structure;
	
	If Object.Participants.Count() > 0 Then
		OpenParameters.Insert(
			"КонтактКакСвязаться",
			New Structure(
				"ВидКонтакта,Contact,HowToContact,CIType",
				"ContactPerson", "", Object.Participants[0].HowToContact, PredefinedValue("Enum.ContactInformationTypes.Phone")));
	EndIf;
	
	OpenParameters.Insert("ChoiceMode", True);
	
	FillingValues = New Structure("Buyer", True);
	OpenParameters.Insert("FillingValues", FillingValues);
	
	OpenForm(
		"Catalog.Counterparties.ObjectForm",
		OpenParameters, ThisObject,,,,,
		FormWindowOpeningMode.LockOwnerWindow
	);
	
EndProcedure

&AtClient
Procedure CounterpartyClearing(Item, StandardProcessing)
	
	ОпределитьТипПоляКонтргент(Undefined);
	
EndProcedure

#EndRegion

#Region ОбработчикиСобытийЭлементовТаблицыФормыКонтакты
&AtClient
Procedure ContactsSelection(Item, SelectedRow, Field, StandardProcessing)
		
	If Field <> Items.ContactsIconIndex Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	RowOfContact = Contacts.FindByID(SelectedRow);
	If RowOfContact = Undefined Then
		Return;
	EndIf;
	
	If Not Write() Then
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure ContactsContactStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	If ValueIsFilled(Counterparty) Then
		FormParameters.Insert("Filter", New Structure("Owner", Counterparty));
	EndIf;
	FormParameters.Insert("CurrentRow", Items.Contacts.CurrentData.Contact);
	FormParameters.Insert("ChoiceMode", True);
	
	OpenForm("Catalog.ContactPersons.ChoiceForm", FormParameters, Item);
	
EndProcedure

&AtClient
Procedure ContactsContactOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	If ValueIsFilled(Items.Contacts.CurrentData.Contact) Then
		Contact = Contacts.FindByID(Items.Contacts.CurrentRow).Contact;
		
		//If TypeOf(Contact) = Type("String") And TypeOf(Counterparty) = Type("CatalogRef.Leads") And ValueIsFilled(Counterparty) Then
		//	ShowValue(, Counterparty);
		//Else
			ShowValue(,Contact);
		//EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ContactsContactChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	StandardProcessing = False;
	Modified = True;
	
	If ValueIsFilled(SelectedValue) Then
		HowToContact = GetHowToContact(SelectedValue, Object.EventType);
	EndIf;
	
	RowContacts = Contacts.FindByID(Items.Contacts.CurrentRow);
	RowContacts.Contact = SelectedValue;
	RowContacts.HowToContact = HowToContact;

EndProcedure

&AtClient
Procedure ContactsContactAutoComplete(Item, Text, ChoiceData, GetingDataParameters, Waiting, StandardProcessing)
	If Waiting <> 0 And Not IsBlankString(Text) And ValueIsFilled(Counterparty) Then
		StandardProcessing = False;
		ChoiceData = GetContactChoiceList(Text, Counterparty);
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure FillByBasis(Command)
	
	If Not ValueIsFilled(Object.BasisDocument) Then
		ShowMessageBox(Undefined, NStr("en='Не указано основание для заполнения.';ru='Не указано основание для заполнения.';vi='Chưa chỉ ra cơ sở để điền.'"));
		Return;
	EndIf;
	
	ShowQueryBox(New NotifyDescription("FillByBasisEnd", ThisObject),
		NStr("en='Документ будет полностью перезаполнен по ""Основанию""! Продолжить выполнение операции?';ru='Документ будет полностью перезаполнен по ""Основанию""! Продолжить выполнение операции?';vi='Chứng từ sẽ được điền lại toán bộ trên cơ sở ""Chính""! Tiếp tục thực hiện giao dịch?'"), QuestionDialogMode.YesNo, 0);
		
EndProcedure

&AtClient
Procedure FillByCounterparty(Command)
	
	If Not ValueIsFilled(Counterparty) Then
		//If TypeOf(Counterparty) = Type("CatalogRef.Leads") Then
		//	QuestionText = NStr("ru = 'Не указан лид для заполнения.';
		//						|en = 'Не указан лид для заполнения.';");
		//Else
			QuestionText = NStr("en='Не указан контрагент для заполнения.';ru='Не указан контрагент для заполнения.';vi='Chưa chỉ ra đối tác để điền.'");
		//EndIf;
		ShowMessageBox(Undefined, QuestionText);
		Return;
	EndIf;
	
	If Contacts.Count() > 0 Then
		//If TypeOf(Counterparty) = Type("CatalogRef.Leads") Then
		//	QuestionText = NStr("ru = 'Контакты будут полностью перезаполнены по лиду! Продолжить выполнение операции?';
		//						|en = 'Контакты будут полностью перезаполнены по лиду! Продолжить выполнение операции?';");
		//Else
			QuestionText = NStr("en='Контакты будут полностью перезаполнены по контрагенту! Продолжить выполнение операции?';ru='Контакты будут полностью перезаполнены по контрагенту! Продолжить выполнение операции?';vi='Liên hệ sẽ được điền lại toàn bộ theo đối tác. Tiếp tục thực hiện giao dịch?'");
		//EndIf;
		ShowQueryBox(New NotifyDescription("FillByCounterpartyEnd", ThisObject), QuestionText, QuestionDialogMode.YesNo, 0);
	Else
		FillByCounterpartyFragment(DialogReturnCode.Yes);
	EndIf;
	
EndProcedure

&AtClient
Procedure СоздатьКонтрагент(Command)
	
	If TypeOf(Counterparty) = Type("CatalogRef.Counterparties") And ValueIsFilled(Counterparty) Then
		CommonUseClientServer.MessageToUser(NStr("en='Контрагент уже выбран (можно создать только при несопоставленном контакте).';ru='Контрагент уже выбран (можно создать только при несопоставленном контакте).';vi='Đối tác đã được chọn (chỉ có thể được tạo với một liên hệ chưa từng có).'"),, "Counterparty");
		Return;
	EndIf;
	
	//If TypeOf(Counterparty) = Type("CatalogRef.Leads") And ValueIsFilled(Counterparty) Then
	//	CommonUseClientServer.MessageToUser(NStr("ru = 'Лид уже выбран (можно создать только при несопоставленном контакте).';
	//													|en = 'Лид уже выбран (можно создать только при несопоставленном контакте).';"),, "Counterparty");
	//	Return;
	//EndIf;
	
	If Items.Contacts.CurrentData <> Undefined Then
		СтрокаКонтакт = Items.Contacts.CurrentData;
	ElsIf Contacts.Count() <> 0 Then
		СтрокаКонтакт = Contacts[0];
	Else
		CommonUseClientServer.MessageToUser(NStr("en='Список контактов не заполнен.';ru='Список контактов не заполнен.';vi='Danh sách liên hệ chưa điền.'"),, "Contacts");
		Return;
	EndIf;
	
	If Not ЗначениеЗаполненоКакСвязаться(СтрокаКонтакт) Then
		Return;
	EndIf;
	
	СопоставитьКонтактКакСвязаться = СтрокаКонтакт.HowToContact;
	
	FormParameters = New Structure;
	FormParameters.Insert("КонтактКакСвязаться", New Structure);
	FormParameters.КонтактКакСвязаться.Insert("ВидКонтакта", "ContactPerson");
	FormParameters.КонтактКакСвязаться.Insert("Contact", СтрокаКонтакт.Contact);
	FormParameters.КонтактКакСвязаться.Insert("HowToContact", СтрокаКонтакт.HowToContact);
	FormParameters.КонтактКакСвязаться.Insert("CIType", PredefinedValue("Enum.ContactInformationTypes.Phone"));
	
	FillingValues = New Structure;
	FillingValues.Insert("ИсточникПривлеченияПокупателя", Object.ИсточникПривлечения);
	
	FormParameters.Insert("FillingValues", FillingValues);
	OpenForm("Catalog.Counterparties.ObjectForm", FormParameters, ThisObject,,,,, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CreateContact(Command)
	
	//If TypeOf(Counterparty) = Type("CatalogRef.Leads") And ValueIsFilled(Counterparty) Then
	//	CommonUseClientServer.MessageToUser(NStr("ru = 'Лид уже выбран (можно создать только при несопоставленном контакте).';
	//													|en = 'Лид уже выбран (можно создать только при несопоставленном контакте).';"),, "Counterparty");
	//	Return;
	//EndIf;
	
	If Items.Contacts.CurrentData <> Undefined Then
		СтрокаКонтакт = Items.Contacts.CurrentData;
	ElsIf Contacts.Count() <> 0 Then
		СтрокаКонтакт = Contacts[0];
	Else
		CommonUseClientServer.MessageToUser(NStr("en='Список контактов не заполнен.';ru='Список контактов не заполнен.';vi='Danh sách liên hệ chưa điền.'"),, "Contacts");
		Return;
	EndIf;
	
	If Not ЗначениеЗаполненоКакСвязаться(СтрокаКонтакт) Then
		Return;
	EndIf;
	
	СопоставитьКонтактКакСвязаться = СтрокаКонтакт.HowToContact;
	
	FormParameters = New Structure;
	FormParameters.Insert("КонтактКакСвязаться", New Structure);
	FormParameters.КонтактКакСвязаться.Insert("Counterparty", Counterparty);
	FormParameters.КонтактКакСвязаться.Insert("Contact", СтрокаКонтакт.Contact);
	FormParameters.КонтактКакСвязаться.Insert("HowToContact", СтрокаКонтакт.HowToContact);
	FormParameters.КонтактКакСвязаться.Insert("CIType", PredefinedValue("Enum.ContactInformationTypes.Phone"));
	
	FillingValues = New Structure;
	FillingValues.Insert("ИсточникПривлечения", Object.ИсточникПривлечения);
	
	FormParameters.Insert("FillingValues", FillingValues);
	OpenForm("Catalog.ContactPersons.ObjectForm", FormParameters, ThisObject,,,,, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ConnectToExistingCounterparty(Command)
	
	СтрокаКонтакт = Items.Contacts.CurrentData;
	
	If Items.Contacts.CurrentData <> Undefined Then
		СтрокаКонтакт = Items.Contacts.CurrentData;
	ElsIf Contacts.Count() <> 0 Then
		СтрокаКонтакт = Contacts[0];
	Else
		CommonUseClientServer.MessageToUser(NStr("en='Contacts list not filled.';ru='Список контактов не заполнен.';vi='Danh sách liên hệ chưa điền.'"),, "Contacts");
		Return;
	EndIf;
	
	If TypeOf(СтрокаКонтакт.Contact) <> Type("CatalogRef.ContactPersons") Then
		RowIndex = Contacts.IndexOf(СтрокаКонтакт);
		CommonUseClientServer.MessageToUser(
			NStr("en='Contact not selected.';ru='Не выбран контакт.';vi='Chưa chọn liện hệ.'"),,
			StrTemplate("Contacts[%1].Contact", Format(RowIndex, "NG=")));
		Return;
	EndIf;
	
	OpenForm(
		"Catalog.Counterparties.ChoiceForm",
		New Structure("ChoiceMode", True),
		ThisObject,,,,
		New NotifyDescription("ПривязатьКСуществующемуКонтрагентуЗавершение", ThisObject, New Structure("Contact", СтрокаКонтакт.Contact)),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ConnectToExistingContactFinish(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	
	ПривявязатьСобытиеКонтактаККонтрагенту(Result, AdditionalParameters.Contact);
	
EndProcedure

&AtClient
Procedure NavigateRefWorkOrderClick(Item)
	
	If Not ValueIsFilled(Object.Ref) Then
		Message = New UserMessage;
		Message.Text = NStr("en='Перед созданием заказ-наряда необходимо записать документ.';ru='Перед созданием заказ-наряда необходимо записать документ.';vi='Trước khi tạo đơn đặt hàng, cần ghi lại chứng từ.'");
		Message.Message();
		Return;
	EndIf;
	
	FillStructure = New Structure();
	GetFillParameters(FillStructure);
	
	Notification = New NotifyDescription("AfterOrderCreating", ThisForm);
	
	OpenForm("Document.CustomerOrder.Form.FormWorkOrder", New Structure("FillingValues", FillStructure),ThisForm,,,,Notification);

EndProcedure

&AtClient
Procedure AfterOrderCreating(ListElement, Parameters) Export
	
	FillSubordinateWorkOrders();
	UpdateListSubordinateWorkOrders();
	
EndProcedure 

&AtClient
Procedure AddAdditionalAttribute(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("CurrentSetOfProperties", PredefinedValue("Catalog.AdditionalAttributesAndInformationSets.Document_Event"));
	FormParameters.Insert("ThisIsAdditionalInformation", False);
	
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInformation.ObjectForm", FormParameters,,,,,,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Procedure GetFillParameters(FillStructure)
	
	If Object.Participants.Count() > 0 And TypeOf(Object.Participants[0].Contact) = Type("CatalogRef.Counterparties") Then
		FillStructure.Insert("Counterparty", Object.Participants[0].Contact);
		FillStructure.Insert("Contract", Catalogs.CounterpartyContracts.ContractByDefault(FillStructure.Counterparty));
	EndIf;
	FillStructure.Insert("OperationKind", Enums.OperationKindsCustomerOrder.WorkOrder);
	FillStructure.Insert("EnterpriseResources", Object.EnterpriseResources);
	FillStructure.Insert("Event", Object.Ref);
	
EndProcedure

&AtServer
Procedure OnCreateReadAtServer(CurrentObject)
	
	ReadAttributes(CurrentObject);
	
EndProcedure

&AtServer
Procedure SetFormConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, Items.ContactsContact.DataPath, Undefined, DataCompositionComparisonType.NotFilled);
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, Items.ContactsHowToContact.DataPath, Undefined, DataCompositionComparisonType.Filled);
	WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, Items.ContactsContact.Name);
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "MarkIncomplete", False);
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Text", NStr("en='<Unknow contact>';ru='<Неизвестный контакт>';vi='<Liên hệ không xác định>'"));
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.UnfilledTableField);
	
	//Ресурсы
	ResourcePlanningCM.SetupConditionalAppearanceResources("EnterpriseResources", ThisObject, True);
	
EndProcedure

&AtServer
Procedure ReadAttributes(Object)
	
	Contacts.Clear();
	FirstRow = True;
	
	For Each RowParticipants In Object.Participants Do
		
		If FirstRow And TypeOf(RowParticipants.Contact) <> Type("String") Then
			Counterparty = RowParticipants.Contact;
			CounterpartyHowToContact = RowParticipants.HowToContact;
			FirstRow = False;
			Continue;
		EndIf;
		
		RowContacts = Contacts.Add();
		FillPropertyValues(RowContacts, RowParticipants);
		
	EndDo;
	
	If Not ValueIsFilled(Counterparty) Then
		Counterparty = Catalogs.Counterparties.EmptyRef();
	EndIf;
	ОпределитьТипПоляКонтргент(TypeOf(Counterparty));
	
	If Not ValueIsFilled(Responsible) Then
		Responsible = Object.Responsible;
	EndIf;
	
	DocumentAuthor = Object.Author;
	
EndProcedure

&AtServer
Procedure WriteAttributes(Object)
	
	Object.Participants.Clear();
	
	RowParticipants = Object.Participants.Add();
	RowParticipants.Contact = Counterparty;
	RowParticipants.HowToContact = CounterpartyHowToContact;
	
	For Each RowContacts In Contacts Do
		FillPropertyValues(Object.Participants.Add(), RowContacts);
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateConnectingWay()
	
	If Not ValueIsFilled(Counterparty) Then
		CounterpartyHowToContact = "";
		Return;
	EndIf;
	
	CounterpartyHowToContact = GetHowToContact(Counterparty, Object.EventType);
		
EndProcedure

&AtServerNoContext
Function GetHowToContact(Contact, EventType)
	
	If TypeOf(Contact) = Type("String") Then
		Return "";
	EndIf;
	
	If Not ValueIsFilled(Contact) Then
		Return "";
	EndIf;
	
	CIType = Undefined;
	If EventType = Enums.EventTypes.PhoneCall Then
		CIType = Enums.ContactInformationTypes.Phone;
	EndIf;
	
	If TypeOf(Contact) = Type("CatalogRef.Counterparties")
		Or TypeOf(Contact) = Type("CatalogRef.ContactPersons") Then
		
		ItsEmail = (CIType = Enums.ContactInformationTypes.Phone);
		Return Documents.Event.GetHowToContact(Contact, ItsEmail);
	EndIf;
	
EndFunction

&AtServerNoContext
Function GetDataDateOnChange(DocumentRef, DateNew, DateBeforeChange)
	
	StructureData = New Structure();
	StructureData.Insert("Datediff", SmallBusinessServer.CheckDocumentNumber(DocumentRef, DateNew, DateBeforeChange));
	
	Return StructureData;
	
EndFunction // ПолучитьДанныеДатаПриИзменении()

&AtServer
Procedure CounterpartyOnChangeServer()
	
	UpdateConnectingWay();
	
EndProcedure

&AtServerNoContext
Function GetContactChoiceList(Val SearchString, Counterparty)
	
	ChoiceParameters = New Structure;
	ChoiceParameters.Insert("Filter", New Structure("Owner, DeletionMark", Counterparty, False));
	ChoiceParameters.Insert("SearchString", SearchString);
	
	ContactPersonSelectionData = Catalogs.ContactPersons.GetChoiceData(ChoiceParameters);
	
	Return ContactPersonSelectionData;
	
EndFunction

&AtClient
Procedure FormManagement()
	
	ИспользуетсяТелефония = ИспользоватьОблачнуюТелефонию Or ИспользоватьМобильнуюТелефонию And ValueIsFilled(ПерсональноеМобильноеУстройство);
	
	If Not ValueIsFilled(Counterparty) And Object.Participants.Count() <> 0 Then
		Items.Counterparty.InputHint = NStr("en='Unknow counterparty: create new';ru='Неизвестный контрагент: создайте нового';vi='Đối tác không xác định: tạo mới'");
	EndIf;
	
	Items.ResponsibleForCall.Visible = EventConnectedToCall;
	Items.Responsible.Visible = Not EventConnectedToCall;
	
	If ОбязательноЗаполнятьИсточникВЗаписях Then
		Items.ИсточникПривлечения.AutoMarkIncomplete = True;
	EndIf;

EndProcedure

&AtServer
Function ПолучитьСтрокуВремени(Val Seconds) Export
	
	Hours = Int(Seconds / 3600);
	Minutes = Int((Seconds - Hours * 3600) / 60);
	Seconds = Number((Seconds - Hours * 3600 - Minutes * 60));
	Return Format(Hours, "ND=2; NZ=00; NLZ=") + ":" + Format(Minutes,"ND=2; NZ=00; NLZ=") + ":" + Format(Seconds,"ND=2; NZ=00; NLZ=");
	
EndFunction

&AtServer
Procedure ОпределитьТипПоляКонтргент(Type)
	
	Items.Counterparty.ChooseType = False;
	Items.Counterparty.Title = NStr("en='Counterparty';ru='Контрагент';vi='Đối tác'");
	Items.ContactsContact.ChoiceButton = True;
	
EndProcedure

&AtClient
Function ЗначениеЗаполненоКакСвязаться(СтрокаКонтакт)
	
	If ValueIsFilled(СтрокаКонтакт.HowToContact) Then
		Return True;
	EndIf;
	
	RowIndex = Contacts.IndexOf(СтрокаКонтакт);
	CommonUseClientServer.MessageToUser(
		NStr("en='Не заполнена колонка ""Как связаться"".';ru='Не заполнена колонка ""Как связаться"".';vi='Cột ""Liên hệ"" không được điền.'"),,
		StrTemplate("Contacts[%1].HowToContact", Format(RowIndex, "NG=")));
		
	Return False;
	
EndFunction

&AtServer
Procedure СопоставитьКонтактКонтактнуюИнформацию(НовыйКонтакт, HowToContact)
	
	If TypeOf(НовыйКонтакт) = Type("CatalogRef.Counterparties") Then
		
		If ValueIsFilled(Counterparty) Then
			Return;
		EndIf;
		
		Counterparty = НовыйКонтакт;
		UpdateConnectingWay();
		
		СопоставитьКонтактыСобытияСКонтактнымиЛицами(Catalogs.Counterparties.RelaitedContacts(НовыйКонтакт), HowToContact);
		
	ElsIf TypeOf(НовыйКонтакт) = Type("CatalogRef.ContactPersons") Then
		
		If ValueIsFilled(Counterparty) And Not Catalogs.Counterparties.КонтрагентСвязанСКонтактом(Counterparty, НовыйКонтакт) Then
			Return;
		EndIf;
		
		СопоставитьКонтактыСобытияСКонтактнымиЛицами(НовыйКонтакт, HowToContact);
		
	//ElsIf TypeOf(НовыйКонтакт) = Type("CatalogRef.Leads") Then
	//	
	//	If ValueIsFilled(Counterparty) Then
	//		Return;
	//	EndIf;
	//	
	//	Counterparty = НовыйКонтакт;
	//	Contacts.Clear();
	//	ОбновитьКакСвязаться();
		
	EndIf;
	
	Write();
	
EndProcedure

&AtServer
Procedure СопоставитьКонтактыСобытияСКонтактнымиЛицами(Val ContactPersons, HowToContact)
	
	//If TypeOf(ContactPersons) <> Type("Array") Then
	//	ContactPersons = CommonUseClientServer.ValueInArray(ContactPersons);
	//EndIf;
	//
	//If ContactPersons.Count() = 0 Then
	//	Return;
	//EndIf;
	//
	//ТелефонКонтактаСопоставляемый = КонтактнаяИнформацияУНФ.ПреобразоватьНомерДляКонтактнойИнформации(HowToContact);
	//СопоставляемыеКонтактыСобытия = Contacts.FindRows(New Structure("HowToContact", HowToContact));
	//
	//КонтактнаяИнформацияКонтактныхЛиц = ContactInformationManagement.ContactInformationOfObjects(ContactPersons, Enums.ContactInformationTypes.Phone);
	//
	//For Each КонтактСобытия In СопоставляемыеКонтактыСобытия Do
	//	
	//	КонтактНайден = False;
	//	
	//	For Each СопоставляемыйКонтакт In КонтактнаяИнформацияКонтактныхЛиц Do
	//		
	//		If ТелефонКонтактаСопоставляемый = КонтактнаяИнформацияУНФ.ПреобразоватьТелефонДляПоиска(СопоставляемыйКонтакт.Presentation) Then
	//			КонтактНайден = True;
	//			Break;
	//		EndIf;
	//		
	//	EndDo;
	//	
	//	If Not КонтактНайден Then
	//		Continue;
	//	EndIf;
	//	
	//	КонтактСобытия.Contact = СопоставляемыйКонтакт.Object;
	//	КонтактСобытия.HowToContact = СопоставляемыйКонтакт.Presentation;
	//	
	//EndDo;
	
EndProcedure

&AtServer
Procedure ПривявязатьСобытиеКонтактаККонтрагенту(NewCounterparty, Contact)
	
	BeginTransaction();
	
	Try
		Counterparty = NewCounterparty;
		UpdateConnectingWay();
		Catalogs.Counterparties.ДобавитьСвязьСКонтактом(NewCounterparty, Contact);
		Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		ErrorText = DetailErrorDescription(ErrorInfo());
		Raise ErrorText;
	EndTry;
	
EndProcedure

#EndRegion

#Region SecondaryDataFilling

&AtClient
Procedure FillByCounterpartyEnd(Result, AdditionalParameters) Export
	
	FillByCounterpartyFragment(Result);
	
EndProcedure

&AtClient
Procedure FillByCounterpartyFragment(Val Response)
	
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Counterparty) Then
		Return;
	EndIf;
	
	FillByCounterpartyServer(Counterparty);
	
EndProcedure // ЗаполнитьПоКонтрагенту()

&AtServer
Procedure FillByCounterpartyServer(Counterparty)
	
	Document = FormAttributeToValue("Object");
	Document.Fill(New Structure("FillBasis, EventType, Responsible", Counterparty, Object.EventType, Object.Responsible));
	ValueToFormAttribute(Document, "Object");
	
	ReadAttributes(Object);
	
	ResourcePlanningCM.RefillServiceAttributesResourceTable(Object.EnterpriseResources);
	
EndProcedure // ЗаполнитьУчастниковПоКонтрагенту()

&AtClient
Procedure FillByBasisEnd(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		FillByBasisServer(Object.BasisDocument);
	EndIf;
	
EndProcedure // ЗаполнитьПоОснованию()

&AtServer
Procedure FillByBasisServer(BasisDocument)
	
	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.Fill(New Structure("FillBasis, EventType, Responsible", BasisDocument, Object.EventType, Object.Responsible));
	ValueToFormAttribute(DocumentObject, "Object");
	
	ReadAttributes(DocumentObject);
	
	ResourcePlanningCM.RefillServiceAttributesResourceTable(Object.EnterpriseResources);
	
EndProcedure // ЗаполнитьПоДокументу()

#EndRegion

#Region LibrariesHandlers

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesRunCommand(ItemOrCommand, URL = Undefined, StandardProcessing = Undefined)
	PropertiesManagementClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertiesManagement.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure // ОбновитьЭлементыДополнительныхРеквизитов()

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertiesManagementClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_AdditionalAttributeOnChange(Item)
	PropertiesManagementClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure
// Конец СтандартныеПодсистемы.Свойства

#EndRegion

#Region НастройкаВидимостьЭлементовФормы

// Процедура выполняет настройку элементов формы для корректного отображения в мобильном клиенте
//
&AtServer
Procedure ConfigureMobileClientForm()
	
	If Not CommonUse.IsMobileClient() Then
		Return;
	EndIf;
	
	CommonUseClientServer.SetFormItemProperty(Items, "GroupParties", "ShowTitle", True);
	
EndProcedure

#EndRegion

#Region WorkWithResources

&AtClient
Procedure EnterpriseResourcesEnterpriseResourceOnChange(Item)
	CurrentData = Items.EnterpriseResources.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	StructureData = New Structure();
	StructureData.Insert("Resource", CurrentData.EnterpriseResource);
	
	CurrentData.Capacity = 1;
	
	ResourcePlanningCMClient.CleanRowData(CurrentData);
	FillDataResourceTableOnForm();
EndProcedure

&AtClient
Procedure FillDataResourceTableOnForm()
	
	ResourceData = MapResourcesData();
	
	Items.EnterpriseResourcesPickupResources.Enabled = Not ThisForm.ReadOnly;
	Items.CompanyResourcesGroupCheck.Enabled = Not ThisForm.ReadOnly;
	
	For Each RowResources In Object.EnterpriseResources Do
		
		IsCounterDetails = ?(TypeOf(RowResources.CompleteAfter) = Type("Number"), True, False);
		
		ResourcesData = ResourceData.Get(RowResources.EnterpriseResource);
		
		If Not ResourcesData = Undefined Then
			FillPropertyValues(RowResources, ResourcesData)
		EndIf;
		
		SelectedWeekDays = ResourcePlanningCMClient.DescriptionWeekDays(RowResources);
		
		AddingByMonthYear = "";
		
		Start = RowResources.Start;
		WeekDayMonth = RowResources.WeekDayMonth;
		RepeatabilityDate = RowResources.RepeatabilityDate;
		
		If RowResources.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.Monthly")
										Or RowResources.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.Ежегодно") Then
			
			If ValueIsFilled(RepeatabilityDate) Then
				
				AddingByMonthYear = ?(ValueIsFilled(RepeatabilityDate), NStr("en=', every ';vi=', mỗi ';") 
										+ String(RepeatabilityDate) + "-ok "+ResourcePlanningCMClient.GetMonthByNumber(RowResources.MonthNumber)+".","");
			ElsIf ValueIsFilled(WeekDayMonth) Then
				
				If ResourcePlanningCMClient.ItLastMonthWeek(Start) Then
					AddingByMonthYear = NStr("en=', In last. ';vi=', Vào cuối.';") + ResourcePlanningCMClient.MapNumberWeekDay(WeekDayMonth)+ NStr("en=' month.';vi=' tháng.';");
				Else
				WeekMonthNumber = WeekOfYear(Start)-WeekOfYear(BegOfMonth(Start))+1;
				AddingByMonthYear = " "+ResourcePlanningCMClient.MapNumberWeekDay(WeekDayMonth) + NStr("en=' every. ';vi=' mỗi. ';") +String(WeekMonthNumber)+ "-Iy" + NStr("en=' Weeks';vi=' Tuần';");
				EndIf;
				
			ElsIf RowResources.LastMonthDay = True Then
				AddingByMonthYear = NStr("en=', last day month.';vi=', vào ngày cuối tháng'");
			EndIf;
			
		EndIf;
		
		Interjection = ?(RowResources.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.Weekly"),NStr("ru = 'Каждую';en='Every';vi='Mỗi';"), NStr("ru = 'Каждый';en='Each';vi='Mỗi';"));
		
		End = "";
		
		If RowResources.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.Weekly") Then
			End = NStr("en='Week';vi='Tuần';")
		ElsIf RowResources.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.Daily") Then
			End = NStr("en='Day';vi='Ngày';")
		ElsIf RowResources.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.Monthly") Then
			End = NStr("en='Month';vi='Tháng';")
		ElsIf RowResources.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.Ежегодно") Then
			End = NStr("en='Year';vi='Năm';")
		EndIf;
		
		If ValueIsFilled(RowResources.RepeatKind) 
			And Not RowResources.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.НеПовторять") Then
			
			SchedulePresentation = String(RowResources.RepeatKind)+", "+Interjection+" "+String(RowResources.RepeatInterval)+
			" "+ End+", "+SelectedWeekDays+AddingByMonthYear;
		Else
			SchedulePresentation = Nstr("en='Not repeat';ru='Не повторять';vi='Không lặp lại'")
		EndIf;
		
		RowResources.SchedulePresentation = SchedulePresentation;
		
		If RowResources.CompleteKind = PredefinedValue("Enum.ScheduleRepeatCompletingKind.ByCounter")
			And ValueIsFilled(RowResources.CompleteAfter) Then 
			
			FormatString = "L = ru_RU";
			
			DetailsCounter = ResourcePlanningCMClient.CountingItem(
			RowResources.CompleteAfter,
			NStr("en='time';ru='раза';vi='lần'"),
			NStr("en='time';ru='раз';vi='lần'"),
			NStr("en='time';ru='раз';vi='lần'"),
			"M");
			
			RowResources.DetailsCounter = DetailsCounter;
		Else
			RowResources.DetailsCounter = "";
		EndIf;
		
	EndDo;
	
	ResourcePlanningCMClient.FillDurationInSelectedResourcesTable(Object.EnterpriseResources);
	
EndProcedure

&AtServer
Function MapResourcesData()
	
	CollapsedResourceTable = Object.EnterpriseResources.Unload(,"EnterpriseResource");
	CollapsedResourceTable.GroupBy("EnterpriseResource");
	
	ConformityOfReturn = New Map();
	
	DataTable = New ValueTable;
	
	DataTable.Columns.Add("EnterpriseResource");
	DataTable.Columns.Add("ControlStep");
	DataTable.Columns.Add("MultiplicityPlanning");
	
	For Each TableRow In CollapsedResourceTable Do
		
		EnterpriseResource = TableRow.EnterpriseResource;
		
		DataStructure = New Structure("ControlStep,MultiplicityPlanning"
											,EnterpriseResource.ControlIntervalsStepInDocuments, EnterpriseResource.MultiplicityPlanning);
		
		ConformityOfReturn.Insert(EnterpriseResource, DataStructure);
		
	EndDo;
	
	Return ConformityOfReturn;
	
EndFunction

&AtClient
Procedure EnterpriseResourcesStartOnChange(Item)
	OnChangePeriod(True)
EndProcedure

&AtClient
Procedure РесурсыПредприятияСтартВремяПриИзменении(Item)
		OnChangePeriod(True)
EndProcedure

&AtClient
Procedure EnterpriseResourcesFinishOnChange(Item)
	OnChangePeriod()
EndProcedure

&AtClient
Procedure РесурсыПредприятияФинишВремяПриИзменении(Item)
		OnChangePeriod()
EndProcedure

&AtClient
Procedure OnChangePeriod(ItBeginDate = False)
	
	CurrentData = Items.EnterpriseResources.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	BalanceSecondToEndDay = EndOfDay(CurrentData.Finish) - CurrentData.Finish;
	
	If BalanceSecondToEndDay = 59 Then CurrentData.Finish = EndOfDay(CurrentData.Finish) EndIf;
	If CurrentData.Finish = BegOfDay(CurrentData.Finish) Then CurrentData.Finish = CurrentData.Finish-1 EndIf; 
	
	CurrentData.Start = ?(Minute(CurrentData.Start)%5 = 0, CurrentData.Start, CurrentData.Start - (Minute(CurrentData.Start)%5*60));
	
	RemainderOfDivision = Minute(CurrentData.Finish)%5;
	
	If Not (RemainderOfDivision = 0 Or CurrentData.Finish = EndOfDay(CurrentData.Finish)) Then
		
		If RemainderOfDivision < 3 Then
			CurrentData.Finish = CurrentData.Finish - (RemainderOfDivision*60);
		ElsIf (EndOfDay(CurrentData.Finish) - CurrentData.Finish)<300 Then
			CurrentData.Finish = EndOfDay(CurrentData.Finish);
		Else
			CurrentData.Finish = CurrentData.Finish + (300 - (RemainderOfDivision*60));
		EndIf;
		
	EndIf;
	
	If CurrentData.Start > CurrentData.Finish Then 
		If ItBeginDate Then 
			CurrentData.Finish = CurrentData.Start+CurrentData.MultiplicityPlanning*60;
		Else
			CurrentData.Finish = CurrentData.Start;
		EndIf;
		
	EndIf;
	
	CurrentData.Start = ?(Second(CurrentData.Start) = 0, CurrentData.Start, CurrentData.Start - Second(CurrentData.Start));
	
	If Not (Second(CurrentData.Finish) = 0 Or CurrentData.Finish = EndOfDay(CurrentData.Finish)) Then  
		CurrentData.Finish = CurrentData.Finish - Second(CurrentData.Finish)
	EndIf;
	
	ResourcePlanningCMClient.CheckPlanningStep(CurrentData,ItBeginDate,True);
	
	SetupRepeatAvailable();
	
	If CurrentData.RepeatsAvailable Then
		
		If ValueIsFilled(CurrentData.RepeatabilityDate) Then
			CurrentData.RepeatabilityDate = Day(CurrentData.Start);
		EndIf;
		
		If CurrentData.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.Monthly") Then
			
			If ValueIsFilled(CurrentData.WeekDayMonth) Then
				
				If EndOfDay(CurrentData.Start) = EndOfMonth(CurrentData.Start) Then
					
					CurrentData.WeekDayMonth = 0;
					CurrentData.WeekMonthNumber = 0;
					CurrentData.LastMonthDay = True
					
				Else
					
					CurrentData.WeekDayMonth = WeekDay(CurrentData.Start);
					
					CurWeekNumber = WeekOfYear(CurrentData.Start)-WeekOfYear(BegOfMonth(CurrentData.Start))+1;
					
					If ValueIsFilled(CurrentData.WeekMonthNumber) And Not CurrentData.WeekMonthNumber = CurWeekNumber  Then
						CurrentData.WeekMonthNumber = CurWeekNumber;
					EndIf;
					
				EndIf;
				
			EndIf;
			
			If CurrentData.LastMonthDay And Not EndOfDay(CurrentData.Start) = EndOfMonth(CurrentData.Start) Then
				
				CurrentData.LastMonthDay = False;
				CurrentData.WeekDayMonth = WeekDay(CurrentData.Start);
			EndIf;
			
		EndIf;
		
		If CurrentData.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.Ежегодно")
										And ValueIsFilled(CurrentData.MonthNumber) Then
			
			CurrentData.MonthNumber = Month(CurrentData.Start);
			
		EndIf;
		
	Else
		
		CurrentData.WeekMonthNumber = 0;
		CurrentData.MonthNumber = 0;
		CurrentData.RepeatabilityDate = 0;
		CurrentData.WeekDayMonth = 0;
		CurrentData.LastMonthDay = False;
		
		CurrentData.CompleteKind = Undefined;
		CurrentData.CompleteAfter = Undefined;
		
		CurrentData.RepeatInterval = 0;
		CurrentData.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.НеПовторять");
		CurrentData.DetailsCounter = "";
		
		CurrentData.Mon = False;
		CurrentData.Tu = False;
		CurrentData.We = False;
		CurrentData.Th = False;
		CurrentData.Fr = False;
		CurrentData.Sa = False;
		CurrentData.Su = False;
		
	EndIf;
	
	CurrentData.Duration = Date(1,1,1)+(CurrentData.Finish - CurrentData.Start);
	
	FillDataResourceTableOnForm();
	
	If ItBeginDate Then
		If TypeOf(CurrentData.CompleteAfter) = Type("Date")
			And ValueIsFilled(CurrentData.CompleteAfter)
			And ValueIsFilled(CurrentData.Start)
			And CurrentData.CompleteAfter<BegOfDay(CurrentData.Start)
			Then
			CurrentData.CompleteAfter=BegOfDay(CurrentData.Start)
		EndIf;
	EndIf
	
EndProcedure

&AtClient
Procedure SetupRepeatAvailable(FormOpening = False, WasPickup = False)
	
	If FormOpening Or WasPickup Then
		
		For Each RowCompanyResources In Object.EnterpriseResources Do
			
			RowCompanyResources.SchedulePresentation = ?(RowCompanyResources.SchedulePresentation = "", Nstr("en='Not repeat';ru='Не повторять';vi='Không lặp lại'"), RowCompanyResources.SchedulePresentation);
			
			If ValueIsFilled(RowCompanyResources.Start) And ValueIsFilled(RowCompanyResources.Finish) Then
				
				RowCompanyResources.PeriodDifferent = ?(Not BegOfDay(RowCompanyResources.Start) = BegOfDay(RowCompanyResources.Finish), True, False);
				
				If BegOfDay(RowCompanyResources.Start) = BegOfDay(RowCompanyResources.Finish) Then
					RowCompanyResources.RepeatsAvailable = True;
				EndIf;
				
			EndIf;
		EndDo;
		
		Return;
	EndIf;
	
	CurrentData = Items.EnterpriseResources.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	CurrentData.RepeatsAvailable = False;
	CurrentData.PeriodDifferent = False;
	
	If ValueIsFilled(CurrentData.Start) And ValueIsFilled(CurrentData.Finish) Then
		
		CurrentData.PeriodDifferent = ?(Not BegOfDay(CurrentData.Start) = BegOfDay(CurrentData.Finish), True, False);
		
		If BegOfDay(CurrentData.Start) = BegOfDay(CurrentData.Finish) Then
			CurrentData.RepeatsAvailable = True;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure EnterpriseResourcesDaysOnChange(Item)
	SpecifiedEndOfPeriod();
	SetupRepeatAvailable();
EndProcedure

&AtClient
Procedure EnterpriseResourcesTimeOnChange(Item)
	SpecifiedEndOfPeriod();
	SetupRepeatAvailable();
EndProcedure

&AtClient
Procedure SpecifiedEndOfPeriod()
	
	CurrentData = Items.EnterpriseResources.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	SecondsOnTime = CurrentData.Time - Date(1,1,1);
	SeconrdOnDays = ?(ValueIsFilled(CurrentData.Days), CurrentData.Days*1440*60, 0);
	
	CurrentData.Finish = CurrentData.Start + SeconrdOnDays + SecondsOnTime;
	CurrentData.Finish = ?(Not SeconrdOnDays = 0 And CurrentData.Finish = BegOfDay(CurrentData.Finish)
										, CurrentData.Finish - 1, CurrentData.Finish);
	
	ResourcePlanningCMClient.CheckPlanningStep(CurrentData);
	
EndProcedure

&AtClient
Procedure EnterpriseResourcesSchedulePresentationAutoComplete(Item, Text, ChoiceData, GetingDataParameters, Waiting, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.EnterpriseResources.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	StringDate = Day(CurrentData.Start);
	
	NotificationParameters = New Structure;
	
	Notification = New NotifyDescription("AfterEndScheduleEdit", ThisObject, NotificationParameters);
	
	StructureRepeat = New Structure("RepeatInterval, Mon, Tu, We, Th, Fr, Sa, Su, LastMonthDay, RepeatabilityDate, WeekDayMonth, StringDate, CurWeekday, WeekMonthNumber, PeriodRows, MonthNumber"
										,CurrentData.RepeatInterval, CurrentData.Mon, CurrentData.Tu, CurrentData.We
										,CurrentData.Th,CurrentData.Fr, CurrentData.Sa, CurrentData.Su, CurrentData.LastMonthDay
										,CurrentData.RepeatabilityDate, CurrentData.WeekDayMonth, StringDate, WeekDay(CurrentData.Start), CurrentData.WeekMonthNumber, CurrentData.Start, CurrentData.MonthNumber);
	
	OpenParameters = New Structure("Repeatability, StructureRepeat", CurrentData.RepeatKind, StructureRepeat);
	
	OpenForm("DataProcessor.ResourcePlanner.Form.FormScheduleEdit",OpenParameters, ThisForm,,,,Notification, FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure AfterEndScheduleEdit(ExecutionResult, Parameters) Export
	
	If ExecutionResult = Undefined Then Return EndIf;
	
	CurrentData = Items.EnterpriseResources.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	RepeatKind = ExecutionResult.RepeatKind;
	
	CurrentData.RepeatKind = RepeatKind;
	
	If RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.NoRepeat") Then
		 ResourcePlanningCMClient.CleanRowData(CurrentData, False);
		 FillDataResourceTableOnForm();
		 Return;
	 EndIf;
	
	CurrentData.RepeatInterval = ExecutionResult.RepeatInterval;
	CurrentData.Mon = ExecutionResult.Mon;
	CurrentData.Tu = ExecutionResult.Tu;
	CurrentData.We = ExecutionResult.We;
	CurrentData.Th = ExecutionResult.Th;
	CurrentData.Fr = ExecutionResult.Fr;
	CurrentData.Sa = ExecutionResult.Sa;
	CurrentData.Su = ExecutionResult.Su;
	CurrentData.LastMonthDay = ExecutionResult.LastMonthDay;
	CurrentData.RepeatabilityDate = ExecutionResult.RepeatabilityDate;
	CurrentData.WeekDayMonth = ExecutionResult.WeekDayMonth;
	CurrentData.WeekMonthNumber = ExecutionResult.WeekMonthNumber;
	CurrentData.MonthNumber = ExecutionResult.MonthNumber;
	
	FillDataResourceTableOnForm();
	
EndProcedure

&AtClient
Procedure EnterpriseResourcesCompleteKindOnChange(Item)
	CurrentData = Items.EnterpriseResources.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	If CurrentData.CompleteKind = PredefinedValue("Enum.ScheduleRepeatCompletingKind.AtDate") Then
		CurrentData.CompleteAfter = BegOfDay(CurrentData.Finish+86400);
		CurrentData.DetailsCounter = "";
	ElsIf CurrentData.CompleteKind = PredefinedValue("Enum.ScheduleRepeatCompletingKind.ByCounter") Then
		CurrentData.CompleteAfter = 1;
		CurrentData.DetailsCounter = "Time";
	Else
		CurrentData.DetailsCounter = "";
		CurrentData.CompleteAfter = Undefined;
	EndIf;
EndProcedure

&AtClient
Procedure EnterpriseResourcesCompleteAfterOnChange(Item)
	CurrentData = Items.EnterpriseResources.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	If CurrentData.CompleteKind = PredefinedValue("Enum.ScheduleRepeatCompletingKind.ByCounter")
										And ValueIsFilled(CurrentData.CompleteAfter) Then 
		
		FormatString = "L = ru_RU";
		
		DetailsCounter = ResourcePlanningCMClient.CountingItem(
		CurrentData.CompleteAfter,
		NStr("en='раза';ru='раза';vi='lần'"),
		NStr("en='раза';ru='раза';vi='lần'"),
		NStr("en='раза';ru='раза';vi='lần'"),
		"M");
		
		CurrentData.DetailsCounter = DetailsCounter;
	Else
		CurrentData.DetailsCounter = "";
	EndIf;
	
	If TypeOf(CurrentData.CompleteAfter) = Type("Date")
			And ValueIsFilled(CurrentData.CompleteAfter)
			And ValueIsFilled(CurrentData.Start)
			And CurrentData.CompleteAfter<BegOfDay(CurrentData.Start)
			Then
			CurrentData.CompleteAfter=BegOfDay(CurrentData.Start)
	EndIf;
	
EndProcedure

&AtClient
Procedure ControlExcess(Command)
	ControlAtServer();
EndProcedure

&AtServer
Procedure ControlAtServer()
	ResourcePlanningCM.ControlParametersResourcesLoading(True,, Object.EnterpriseResources, ThisObject);
EndProcedure

&AtClient
Procedure BoarderControl(Command)
	BoarderControlAtServer();
EndProcedure

&AtServer
Procedure BoarderControlAtServer()
	ResourcePlanningCM.ControlParametersResourcesLoading(,True, Object.EnterpriseResources, ThisObject);
EndProcedure

&AtClient
Procedure ControlAll(Command)
	ControlAllAtServer();
EndProcedure

Procedure ControlAllAtServer()
	ResourcePlanningCM.ControlParametersResourcesLoading(True, True, Object.EnterpriseResources, ThisObject);
EndProcedure

&AtClient
Procedure PickupResources(Command)
	OpenParameters = New Structure("ThisSelection, EnterpriseResources, PlanningBoarders, SubsystemNumber", True, Object.EnterpriseResources,,3);
	Notification = New NotifyDescription("AfterPickupFormPlannerEnd", ThisObject, OpenParameters);
	OpenForm("DataProcessor.ResourcePlanner.Form.PlannerForm", OpenParameters,,,,,Notification);
EndProcedure

&AtClient
Procedure AfterPickupFormPlannerEnd(Result, AdditionalParameters) Export
	
	If Not Result = Undefined Then
		
		Object.EnterpriseResources.Clear();
		
		SelectedResources = Result;
		
		For Each ResourcesRow In SelectedResources Do
			
			NewRow = Object.EnterpriseResources.Add();
			
			FillPropertyValues(NewRow, ResourcesRow);
			
			NewRow.EnterpriseResource = ResourcesRow.Resource;
			NewRow.Start = ResourcesRow.BeginOfPeriod;
			NewRow.Finish = ResourcesRow.EndOfPeriod;
			NewRow.Capacity = ResourcesRow.Load;
			NewRow.Duration = Date(1,1,1)+(NewRow.Finish - NewRow.Start); 
			
		EndDo;
		
		FillDataResourceTableOnForm();
		
		SetupRepeatAvailable(, True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	If CurrentPage.Name = "PegeResources" Then
		SetupRepeatAvailable(True);
		FillDataResourceTableOnForm();
	EndIf;
EndProcedure

&AtServer
Procedure FillResourcesFromPlanner(SelectedResources)
	
	For Each ResourcesRow In SelectedResources Do
		
		
		NewRow = Object.EnterpriseResources.Add();
		
		FillPropertyValues(NewRow, ResourcesRow);
		
		NewRow.EnterpriseResource = ResourcesRow.Resource;
		NewRow.Start = ResourcesRow.BeginOfPeriod;
		NewRow.Finish = ResourcesRow.EndOfPeriod;
		NewRow.Capacity = ResourcesRow.Loading;
		NewRow.Duration = Date(1,1,1)+(NewRow.Finish - NewRow.Start); 
		
	EndDo;
	
EndProcedure

#EndRegion