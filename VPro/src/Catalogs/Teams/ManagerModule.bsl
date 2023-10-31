#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region ProgramInterface

Function TeamsContent(Team, Company, Date = '0001-01-01') Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	TeamsContent.Employee AS Employee,
	|	ISNULL(EmployeesSliceLast.StructuralUnit, VALUE(Catalog.StructuralUnits.EmptyRef)) AS StructuralUnit
	|FROM
	|	Catalog.Teams.Content AS TeamsContent
	|		LEFT JOIN InformationRegister.Employees.SliceLast(&SlicePeriod, Company = &Company) AS EmployeesSliceLast
	|		ON TeamsContent.Employee = EmployeesSliceLast.Employee
	|WHERE
	|	TeamsContent.Ref = &Ref";
	
	Query.SetParameter("Ref", Team);	
	Query.SetParameter("Company", Company);	
	Query.SetParameter("SlicePeriod", ?(ValueIsFilled(Date), Date, EndOfDay(CurrentDate())));
	
	Return Query.Execute().Unload();
	
EndFunction

#EndRegion 	
	
#EndIf