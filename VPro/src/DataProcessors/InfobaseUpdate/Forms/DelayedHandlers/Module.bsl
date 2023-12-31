
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then // Return if the form for analysis is received.
		Return;
	EndIf;

	DataAboutUpdate = InfobaseUpdateService.DataOnUpdatingInformationBase();
	BeginTimeOfPendingUpdate = DataAboutUpdate.BeginTimeOfPendingUpdate;
	EndTimeDeferredUpdate = DataAboutUpdate.EndTimeDeferredUpdate;
	CurrentSessionNumber = DataAboutUpdate.SessionNumber;
	FileInfobase = CommonUse.FileInfobase();
	
	If Not Users.InfobaseUserWithFullAccess(, True) Then
		Items.GroupRestart.Visible = False;
	EndIf;
	
	If Not FileInfobase Then
		RefreshInProgress = (DataAboutUpdate.DeferredUpdateIsCompletedSuccessfully = Undefined);
	EndIf;
	
	If Not Users.RolesAvailable("ViewEventLogMonitor") Then
		Items.HyperlinkPostponedUpdate.Visible = False;
	EndIf;
	
	Status = "AllProcedures";
	
	GenerateDeferredHandlerTable(, True);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If RefreshInProgress Then
		AttachIdleHandler("UpdateHandlersTable", 15);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure CloseForm(Command)
	Close();
EndProcedure

&AtClient
Procedure RunRepeatedly(Command)
	Notify("PostponedUpdate");
	Close();
EndProcedure

&AtClient
Procedure HyperlinkPostponedUpdateClick(Item)
	
	GetUpdateData();
	If ValueIsFilled(BeginTimeOfPendingUpdate) AND ValueIsFilled(EndTimeDeferredUpdate) Then
		FormParameters = New Structure;
		FormParameters.Insert("StartDate", BeginTimeOfPendingUpdate);
		FormParameters.Insert("EndDate", EndTimeDeferredUpdate);
		FormParameters.Insert("Session", CurrentSessionNumber);
		
		OpenForm("DataProcessor.EventLogMonitor.Form.EventLogMonitor", FormParameters);
	Else
		
		If ValueIsFilled(BeginTimeOfPendingUpdate) Then
			WarningText = NStr("en='Data is not processed yet.';ru='Обработка данных еще не завершилась.';vi='Vẫn chưa thực hiện xử lý dữ liệu.'");
		Else
			WarningText = NStr("en='Data has not been processed yet.';ru='Обработка данных еще не выполнялась.';vi='Vẫn chưa thực hiện xử lý dữ liệu.'");
		EndIf;
		
		ShowMessageBox(,WarningText);
	EndIf;
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	If Status = "AllProcedures" Then
		Items.DelayedHandlers.RowFilter = New FixedStructure;
	Else
		TableStringFilter = New Structure;
		TableStringFilter.Insert("HandlerStatus", Status);
		Items.DelayedHandlers.RowFilter = New FixedStructure(TableStringFilter);
	EndIf;
EndProcedure

&AtClient
Procedure SearchStringOnChange(Item)
	DelayedHandlers.Clear();
	GenerateDeferredHandlerTable(, True);
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

&AtClient
Procedure UpdateHandlersTable()
	
	PerformedAllProcessors = True;
	GenerateDeferredHandlerTable(PerformedAllProcessors);
	If PerformedAllProcessors Then
		DetachIdleHandler("UpdateHandlersTable");
	EndIf;
	
EndProcedure

&AtServer
Procedure GetUpdateData()
	DataAboutUpdate = InfobaseUpdateService.DataOnUpdatingInformationBase();
	BeginTimeOfPendingUpdate = DataAboutUpdate.BeginTimeOfPendingUpdate;
	EndTimeDeferredUpdate = DataAboutUpdate.EndTimeDeferredUpdate;
EndProcedure

&AtServer
Procedure GenerateDeferredHandlerTable(PerformedAllProcessors = True, InitialFilling = False)
	
	HandlersAreNotExecuted = True;
	DataAboutUpdate = InfobaseUpdateService.DataOnUpdatingInformationBase();
	
	For Each TreeRowLibrary IN DataAboutUpdate.HandlerTree.Rows Do
		For Each TreeRowVersion IN TreeRowLibrary.Rows Do
			For Each HandlerLine IN TreeRowVersion.Rows Do
				
				If Not IsBlankString(SearchString) Then
					If Not IsBlankString(HandlerLine.Comment) Then
						If Find(Upper(HandlerLine.Comment), Upper(SearchString)) = 0 Then
							Continue;
						EndIf;
					Else
						If Find(Upper(HandlerLine.HandlerName), Upper(SearchString)) = 0 Then
							Continue;
						EndIf;
					EndIf;
				EndIf;
				AddDeferredHandler(HandlerLine, HandlersAreNotExecuted, PerformedAllProcessors, InitialFilling);
				
			EndDo;
		EndDo;
	EndDo;
	
	If Status <> "AllProcedures" Then
		TableStringFilter = New Structure;
		TableStringFilter.Insert("HandlerStatus", Status);
		Items.DelayedHandlers.RowFilter = New FixedStructure(TableStringFilter);
	EndIf;
	
	If PerformedAllProcessors Or RefreshInProgress Then
		Items.GroupRestart.Visible = False;
	EndIf;
	
	If HandlersAreNotExecuted Then
		Items.ExplanationText.Title = NStr("en='Consider starting outstanding data processing procedures.';ru='Рекомендуется запустить невыполненные процедуры обработки данных.';vi='Nên khởi động thủ tục xử lý dữ liệu chưa thực hiện.'");
	Else
		Items.ExplanationText.Title = NStr("en='It is recommended to restart update procedures that have not been executed';ru='Невыполненные процедуры рекомендуется запустить повторно.';vi='Nên khởi động lại thủ tục chưa thực hiện.'");
	EndIf;
	
	DelayedHandlers.Sort("Weight Desc");
	
	ItemNumber = 1;
	For Each TableRow IN DelayedHandlers Do
		TableRow.Number = ItemNumber;
		ItemNumber = ItemNumber + 1;
	EndDo;
	
	Items.RefreshInProgress.Visible = Not PerformedAllProcessors;
	
EndProcedure

&AtServer
Procedure AddDeferredHandler(HandlerLine, HandlersAreNotExecuted, PerformedAllProcessors, InitialFilling)
	
	If InitialFilling Then
		ListRow = DelayedHandlers.Add();
	Else
		FilterParameters = New Structure;
		FilterParameters.Insert("ID", HandlerLine.HandlerName);
		ListRow = DelayedHandlers.FindRows(FilterParameters)[0];
	EndIf;
	
	ListRow.ID = HandlerLine.HandlerName;
	If Not IsBlankString(HandlerLine.Comment) Then
		ListRow.Handler = HandlerLine.Comment;
	Else
		ListRow.Handler = HandlerLine.HandlerName;
	EndIf;
	
	If HandlerLine.Status = "Completed" Then
		HandlersAreNotExecuted = False;
		ListRow.InformationAboutUpdateProcedure = 
			NStr("en='Data processing procedure ""%1"" is completed successfully.';ru='Процедура ""%1"" обработки данных завершилась успешно.';vi='Thủ tục ""%1"" xử lý dữ liệu đã hoàn tất thành công.'");
		ListRow.HandlerStatus = NStr("en='Completed';ru='Completed';vi='Đã thực hiện'");
		ListRow.Weight = 1;
		ListRow.StatusPicture = PictureLib.Successfully;
	ElsIf HandlerLine.Status = "Running" Then
		HandlersAreNotExecuted = False;
		ListRow.InformationAboutUpdateProcedure = 
			NStr("en='Data processing procedure ""%1"" is in progress now.';ru='Процедура ""%1"" обработки данных в данный момент выполняется.';vi='Đang thực hiện thủ tục ""%1"" xử lý dữ liệu vào thời điểm hiện tại.'");
		ListRow.HandlerStatus = NStr("en='Active';ru='Выполняется';vi='Đang thực hiện'");
		ListRow.Weight = 3;
	ElsIf HandlerLine.Status = "Error" Then
		HandlersAreNotExecuted = False;
		PerformedAllProcessors = False;
		ListRow.InformationAboutUpdateProcedure = HandlerLine.ErrorInfo;
		ListRow.HandlerStatus = NStr("en='Error';ru='Ошибка';vi='Lỗi'");
		ListRow.Weight = 4;
		ListRow.StatusPicture = PictureLib.Stop;
	Else
		PerformedAllProcessors = False;
		ListRow.HandlerStatus = NStr("en='Not executed';ru='Не выполнялась';vi='Chưa thực hiện'");
		ListRow.Weight = 2;
		ListRow.InformationAboutUpdateProcedure = NStr("en='Data processing procedure ""%1"" is not executed yet.';ru='Процедура ""%1"" обработки данных еще не выполнялась.';vi='Thủ tục ""%!"" xử lý dữ liệu còn chưa được thực hiện.'");
	EndIf;
	
	ListRow.InformationAboutUpdateProcedure = StringFunctionsClientServer.SubstituteParametersInString(
		ListRow.InformationAboutUpdateProcedure, HandlerLine.HandlerName);
	
EndProcedure

#EndRegion