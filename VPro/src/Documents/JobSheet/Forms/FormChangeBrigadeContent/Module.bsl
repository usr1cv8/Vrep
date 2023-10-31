
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not Parameters.Property("ID", ID)
		Or Not Parameters.Property("ConnectionKey", ConnectionKey)
		Or Not Parameters.Property("StructuralUnitPosition", StructuralUnitPosition)
		Or Not Parameters.Property("Brigade", Brigade) Then
		Cancel = True;
		Return;
	EndIf;
	
	Parameters.Property("Company", Company);
	Parameters.Property("StructuralUnit", StructuralUnit);
	Parameters.Property("Date", Date);
	
	BrigadeContent.Clear();
	If Parameters.Property("BrigadeContent") Then
		For Each ContentDescription In Parameters.BrigadeContent Do
			FillPropertyValues(BrigadeContent.Add(), ContentDescription);
		EndDo; 
	EndIf;
	
	If StructuralUnitPosition= Enums.AttributePositionOnForm.InHeader Then
		CommonUseClientServer.SetFormItemProperty(Items, "BrigadeContentStructuralUnit", "Visible", False);
	EndIf;
	
	If Parameters.Property("HideTabelNumber") And Parameters.HideTabelNumber=True Then
		CommonUseClientServer.SetFormItemProperty(Items, "BrigadeContentEmployeeTN", "Visible", False);
	EndIf; 
	
EndProcedure

#EndRegion

#Region FormItemsEventsHandlers

&AtClient
Procedure BrigadeContentOnStartEdit(Item, NewRow, Clone)
	
	If NewRow Then
		Items.BrigadeContent.CurrentData.LPR = 1;
	EndIf; 	
	
EndProcedure

&AtClient
Procedure BrigadeContentOnChange(Item)
	
	CurrentRow = Items.BrigadeContent.CurrentData;
	If Items.BrigadeContent.Visible Then
		CurrentRow.StructuralUnit = EmployeeDepartment(Company, CurrentRow.Employee, Date);
	EndIf;
	
EndProcedure

#EndRegion

#Region CommandFormHandlers

&AtClient
Procedure FillBrigadeContent(Command)
	
	FillBrigadeOnServer();
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	
	ClosingParameters = New Structure;
	ClosingParameters.Insert("Event", "ChangingBrigadeContent");
	ClosingParameters.Insert("ConnectionKey", ConnectionKey);
	ClosingParameters.Insert("ID", ID);
	ClosingParameters.Insert("BrigadeContent", New Array);
	
	For Each TabSecRow In BrigadeContent Do
		RowDescription = New Structure("Employee, LPR, StructuralUnit");
		FillPropertyValues(RowDescription, TabSecRow);
		ClosingParameters.BrigadeContent.Add(RowDescription);
	EndDo;
	
	NotifyChoice(ClosingParameters);
	
EndProcedure

#EndRegion

#Region ServiceMethod

&AtServer
Procedure FillBrigadeOnServer() Export

	BrigadeContent.Clear();
	ContentTable = Catalogs.Teams.BrigadeContent(Brigade, Company, Date);
	
	For Each TabSecRow In ContentTable Do
		NewRow = BrigadeContent.Add();
		FillPropertyValues(NewRow, TabSecRow);
		NewRow.LPR = 1;
		If StructuralUnitPosition = Enums.AttributePositionOnForm.InHeader Then
			NewRow.StructuralUnit = StructuralUnit;
		EndIf;
	EndDo 

EndProcedure

&AtServerNoContext
Function EmployeeDepartment(Company, Employee, Date)
	
	Query = New Query;
	Query.SetParameter("Company", Company);
	Query.SetParameter("Employee", Employee);
	Query.SetParameter("SlicePeriod", ?(ValueIsFilled(Date), Date, EndOfDay(CurrentSessionDate())));
	Query.Text =
	"SELECT
	|	Staff.Ref AS Employee,
	|	ISNULL(StaffSliceLast.StructuralUnit, VALUE(Catalog.StructuralUnits.EmptyRef)) AS StructuralUnit
	|FROM
	|	Catalog.Employees AS Staff
	|		LEFT JOIN InformationRegister.Employees.SliceLast(&SlicePeriod, Company = &Company) AS StaffSliceLast
	|		ON (StaffSliceLast.Employee = Staff.Ref)
	|WHERE
	|	Staff.Ref = &Employee";
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.StructuralUnit;
	Else
		Return Catalogs.StructuralUnits.EmptyRef();
	EndIf; 
	
EndFunction

#EndRegion
 