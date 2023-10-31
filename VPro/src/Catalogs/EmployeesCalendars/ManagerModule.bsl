#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventsHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	AvailableCalendars = AvailableEmployeeCalendars().UnloadColumn("Calendar");
	Parameters.Filter.Insert("Ref", AvailableCalendars);
	
EndProcedure

#EndRegion

#Region ProgramInterface

Function AvailableEmployeeCalendars(Employee = Undefined) Export
	
	If Employee = Undefined Then
		UserEmployees = SmallBusinessServer.GetUserEmployees();
	Else
		UserEmployees = CommonUseClientServer.ValueInArray(Employee);
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	EmployeesCalendars.Ref AS Calendar
	|INTO TTCalendars
	|FROM
	|	Catalog.EmployeesCalendars AS EmployeesCalendars
	|WHERE
	|	NOT EmployeesCalendars.Predefined
	|	AND EmployeesCalendars.DeletionMark = FALSE
	|	AND EmployeesCalendars.CalendarOwner IN(&UserEmployees)
	|
	|UNION
	|
	|SELECT DISTINCT
	|	EmployeesCalendarsAccess.Ref
	|FROM
	|	Catalog.EmployeesCalendars.Access AS EmployeesCalendarsAccess
	|WHERE
	|	NOT EmployeesCalendarsAccess.Ref.Predefined
	|	AND EmployeesCalendarsAccess.Ref.DeletionMark = FALSE
	|	AND EmployeesCalendarsAccess.Employee IN(&UserEmployees)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TTCalendars.Calendar AS Calendar,
	|	TTCalendars.Calendar.Description AS Description,
	|	CASE
	|		WHEN TTCalendars.Calendar.CalendarOwner IN (&UserEmployees)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS IsOwner
	|FROM
	|	TTCalendars AS TTCalendars
	|
	|ORDER BY
	|	IsOwner DESC,
	|	Description";
	
	Query.SetParameter("UserEmployees", UserEmployees);
	Table = Query.Execute().Unload();
	
	//If Users.InfobaseUserWithFullAccess() Then
	//	
	//	NewRow = Table.Add();
	//	NewRow.Calendar = TaxCalendars;
	//	NewRow.Description = CommonUse.ObjectAttributeValue(TaxCalendars, "Description");
	//	NewRow.IsOwner = False;
	//	
	//EndIf;
	
	Return Table;
	
EndFunction

Procedure CheckCreateEmployeeCalendar(Employee, User = Undefined) Export
	
	If User = Undefined Then
		User = Users.AuthorizedUser();
	EndIf;
	
	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED TOP 1
		|	EmployeesCalendars.Ref
		|FROM
		|	Catalog.EmployeesCalendars AS EmployeesCalendars
		|WHERE
		|	EmployeesCalendars.CalendarOwner = &CalendarOwner
		|	AND EmployeesCalendars.User = &User";
	
	Query.SetParameter("CalendarOwner", Employee);
	Query.SetParameter("User", User);
	
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	FillingData = New Structure;
	FillingData.Insert("CalendarOwner", Employee);
	FillingData.Insert("User", User);
	FillingData.Insert("Description", String(Employee));
	
	NewCalendar = Catalogs.EmployeesCalendars.CreateItem();
	NewCalendar.SetNewCode();
	NewCalendar.Fill(FillingData);
	NewCalendar.Write();
	
	SmallBusinessServer.SetUserSetting(NewCalendar.Ref, "DefaultCalendar", User);
	
EndProcedure

#Region ForCallsFromOtherSubsystems

// СтандартныеПодсистемы.УправлениеДоступом

// See AccessManagementOverridable.OnFillListWithAccessRestriction.
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadChange
	|WHERE
	|	ЭтоАвторизованныйПользователь(User)";

EndProcedure

// Конец СтандартныеПодсистемы.УправлениеДоступом

#EndRegion

#EndRegion

#EndIf