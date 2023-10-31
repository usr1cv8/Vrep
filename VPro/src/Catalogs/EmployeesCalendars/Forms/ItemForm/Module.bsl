
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then
		Return;
	EndIf;
	
	UserEmployees.LoadValues(SmallBusinessServer.GetUserEmployees());
	
	If ValueIsFilled(Parameters.Key) Then
		
		If Not Users.InfobaseUserWithFullAccess() Then
		
			// Ограничение доступа:
			// Редактирование разрешено владельцу календаря 
			// Просмотр разрешен сотруднику, указанному в ТЧ "Доступ"
			
			EditingRight = UserEmployees.FindByValue(Object.CalendarOwner) <> Undefined;
			ViewRight = EditingRight;
			Filter = New Structure("Employee");
			For Each KeyAndValue In UserEmployees Do
				Filter.Employee = KeyAndValue.Value;
				FoundStrings = Object.Access.FindRows(Filter);
				If FoundStrings.Count() > 0 Then
					ViewRight = True;
					Break;
				EndIf;
			EndDo;
			
			If Not ViewRight Then
				Raise NStr("en='Недостаточно прав для просмотра календаря.';ru='Недостаточно прав для просмотра календаря.';vi='Không đủ quyền để xem lịch.'");
			EndIf;
			
			ReadOnly = Not EditingRight;
			
		EndIf;
		
	EndIf;

	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	NotificationParameter = New Structure;
	NotificationParameter.Insert("Calendar", Object.Ref);
	NotificationParameter.Insert("Description", Object.Description);
	NotificationParameter.Insert("CalendarOwner", Object.CalendarOwner);
	
	Notify("Record_EmployeeCalendar", NotificationParameter, ThisObject);
	
EndProcedure


#EndRegion

#Region FormItemEventsHandlers

&AtClient
Procedure CalendarOwnerOnChange(Item)
	
	If UserEmployees.FindByValue(Object.CalendarOwner) = Undefined Then
		
		HasAccess = False;
		Filter = New Structure("Employee");
		
		For Each KeyAndValue In UserEmployees Do
			Filter.Employee = KeyAndValue.Value;
			If Object.Access.FindRows(Filter).Count() > 0 Then
				HasAccess = True;
				Break;
			EndIf;
		EndDo;
		
		If Not HasAccess Then
			
			NotifyDescription = New NotifyDescription("EmployeeAddingOffered", ThisObject);
			
			QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
			QuestionParameters.DefaultButton = DialogReturnCode.Yes;
			QuestionParameters.Title = NStr("en='Изменение доступа';ru='Изменение доступа';vi='Thay đổi quyền truy cập'");
			QuestionParameters.OfferDontAskAgain = False;
			
			QuestionText = StrTemplate(NStr("en='Текущий сотрудник %1 не имеет доступа к календарю."
"Разрешить доступ?';ru='Текущий сотрудник %1 не имеет доступа к календарю."
"Разрешить доступ?';vi='Nhân viên hiện tại %1 không có quyền truy cập vào lịch."
"Cho phép truy cập? '"), String(UserEmployees));
			
			StandardSubsystemsClient.ShowQuestionToUser(NotifyDescription, QuestionText, QuestionDialogMode.YesNo, QuestionParameters);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtClient
Procedure EmployeeAddingOffered(QuestionResult, AdditionalParameters) Export
	
	If TypeOf(QuestionResult) = Type("Structure")
		And QuestionResult.Property("Value")
		And QuestionResult.Value = DialogReturnCode.Yes Then
		
		For Each KeyAndValue In UserEmployees Do
			NewRow = Object.Access.Add();
			NewRow.Employee = KeyAndValue.Value;
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion
