#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventsHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If TypeOf(FillingData) = Type("CatalogRef.Employees") Then
		
		CalendarOwner = FillingData;
		User = InformationRegisters.UserEmployees.ПолучитьПользователяПоСотруднику(CalendarOwner);
		Description = CommonUse.ObjectAttributeValue(FillingData, "Description");
		
	ElsIf TypeOf(FillingData) = Type("Structure") Then
		
		FillPropertyValues(ThisObject, FillingData);
		
	EndIf;
	
	AddByDefault();
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
//	FillKey();
	
	AdditionalProperties.Insert("ChangedMarkSynchronizeWithGoogle", False);
	
	If DataExchange.Load = True Then
		Return;
	EndIf;
	
	CollectionItemsQuantity = Access.Count();
	For ReverseIndex = 1 To CollectionItemsQuantity Do
		IndexOf = CollectionItemsQuantity - ReverseIndex;
		If Access[IndexOf].Employee = CalendarOwner Then
			Access.Delete(IndexOf);
		EndIf;
	EndDo;
	
	//If DeletionMark Then
	//	SynchronizeWithGoogle = False;
	//EndIf;
	
	//AdditionalProperties.ChangedMarkSynchronizeWithGoogle = CommonUse.ObjectAttributeValue(Ref, "SynchronizeWithGoogle") <> SynchronizeWithGoogle;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	//If Not AdditionalProperties.ChangedMarkSynchronizeWithGoogle Then
	//	Return;
	//EndIf;
	
	//If SynchronizeWithGoogle Then
	//	AddActualRecordsInQueueToSendInGoogle();
	//Else
	//	CleanQueueToSendInGoogle();
	//EndIf;
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

Procedure AddByDefault()
	
	If Not ValueIsFilled(CalendarOwner) Then
		
		UserEmployees = SmallBusinessServer.GetUserEmployees(Users.CurrentUser());
		
		If UserEmployees.Count() > 0 Then
			CalendarOwner = UserEmployees[0];
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(User) Then
		User = Users.CurrentUser();
	EndIf;
	
EndProcedure

//Procedure FillKey()
//	
//	If ValueIsFilled(id) Then
//		key = ExchangeWithGoogle.КлючИзИдентификатора(
//		id,
//		TypeOf(ThisObject));
//		Return;
//	EndIf;
//	
//	If ValueIsFilled(Ref) Then
//		ObjectReference = Ref;
//	Else
//		ObjectReference = GetNewObjectRef();
//		If Not ValueIsFilled(ObjectReference) Then
//			ObjectReference = Catalogs.EmployeesCalendars.GetRef();
//			SetNewObjectRef(ObjectReference);
//		EndIf;
//	EndIf;
//	
//	key = ExchangeWithGoogle.КлючИзИдентификатора(
//	StrReplace(ObjectReference.UUID(), "-", ""),
//	TypeOf(ThisObject));
//	
//EndProcedure

//Procedure AddActualRecordsInQueueToSendInGoogle()
//	
//	Query = New Query(
//	"SELECT
//	|	RecordsEmployeeCalendar.Ref
//	|FROM
//	|	Catalog.RecordsEmployeeCalendar AS RecordsEmployeeCalendar
//	|WHERE
//	|	RecordsEmployeeCalendar.Calendar = &Calendar
//	|	AND NOT RecordsEmployeeCalendar.DeletionMark
//	|	AND RecordsEmployeeCalendar.Begin >= &Period");
//	Query.SetParameter("Calendar", Ref);
//	Query.SetParameter("Period", BegOfDay(CurrentSessionDate()));
//	
//	QueryResult = Query.Execute();
//	If QueryResult.IsEmpty() Then
//		Return;
//	EndIf;
//	
//	NodeForCalendarGoogle = ExchangePlans.ОбменСGoogleCalendar.NodeForCalendarGoogle(Ref);
//	
//	Selection = QueryResult.Select();
//	While Selection.Next() Do
//		ExchangePlans.RecordChanges(NodeForCalendarGoogle, Selection.Ref);
//	EndDo;
//	
//EndProcedure

//Procedure CleanQueueToSendInGoogle()
//	
//	SetPrivilegedMode(True);
//	
//	Query = New Query(
//	"SELECT TOP 1
//	|	ОбменСGoogleCalendar.Ref
//	|FROM
//	|	ExchangePlan.ОбменСGoogleCalendar AS ОбменСGoogleCalendar
//	|WHERE
//	|	NOT ОбменСGoogleCalendar.ThisNode
//	|	AND ОбменСGoogleCalendar.EmployeeCalendar = &EmployeeCalendar");
//	Query.SetParameter("EmployeeCalendar", Ref);
//	
//	QueryResult = Query.Execute();
//	If QueryResult.IsEmpty() Then
//		Return;
//	EndIf;
//	
//	Selection = QueryResult.Select();
//	Selection.Next();
//	ExchangePlans.DeleteChangeRecords(Selection.Ref);
//	
//EndProcedure

#EndRegion

#EndIf