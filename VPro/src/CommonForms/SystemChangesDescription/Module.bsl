#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then // Return if the form for analysis is received.
		Return;
	EndIf;
	
	If Not Parameters.ShowOnlyChanges Then
		Items.AddressFormsInApplication.Visible = False;
	EndIf;
	                                  
	Title = NStr("en = 'What's new in configuration %1';vi='Những điểm mới trong chương trình %1';");
	Title = StringFunctionsClientServer.SubstituteParametersInString(Title, Metadata.Synonym);
	
	If ValueIsFilled(Parameters.UpdateBeginTime) Then
		UpdateBeginTime = Parameters.UpdateBeginTime;
		UpdateEndTime = Parameters.UpdateEndTime;
	EndIf;
	
	Sections = InfobaseUpdateService.NonShownSectionsOfChangesDescribing();
	LastVersion = InfobaseUpdateService.LastDisplayedVersionSystemChanges();
	
	If Sections.Count() = 0 Then
		DocumentSystemChangesDescription = Metadata.CommonTemplates.Find("SystemChangesDescription");
		If DocumentSystemChangesDescription <> Undefined
			AND (LastVersion = Undefined
				Or Not Parameters.ShowOnlyChanges) Then
			DocumentSystemChangesDescription = GetCommonTemplate(DocumentSystemChangesDescription);
		Else
			DocumentSystemChangesDescription = New SpreadsheetDocument();
		EndIf;
	Else
		DocumentSystemChangesDescription = InfobaseUpdateService.DocumentSystemChangesDescription(Sections);
	EndIf;

	If DocumentSystemChangesDescription.TableHeight = 0 Then
		Text = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='The configuration was successfully updated to version %1';ru='Конфигурация успешно обновлена на версию %1';vi='Cấu hình đã cập nhật thành công lên phiên bản %1'"), Metadata.Version);
		DocumentSystemChangesDescription.Area("R1C1:R1C1").Text = Text;
	EndIf;
	
	SubsystemDescriptions  = StandardSubsystemsReUse.SubsystemDescriptions();
	For Each SubsystemName IN SubsystemDescriptions.Order Do
		SubsystemDescription = SubsystemDescriptions.ByNames.Get(SubsystemName);
		If Not ValueIsFilled(SubsystemDescription.MainServerModule) Then
			Continue;
		EndIf;
		Module = CommonUse.CommonModule(SubsystemDescription.MainServerModule);
		Module.OnPreparationOfUpdatesDescriptionTemplate(DocumentSystemChangesDescription);
	EndDo;
	InfobaseUpdateOverridable.OnPreparationOfUpdatesDescriptionTemplate(DocumentSystemChangesDescription);
	
	SystemChangesDescription.Clear();
	SystemChangesDescription.Put(DocumentSystemChangesDescription);
	
	DataAboutUpdate = InfobaseUpdateService.DataOnUpdatingInformationBase();
	UpdateBeginTime = DataAboutUpdate.UpdateBeginTime;
	UpdateEndTime = DataAboutUpdate.UpdateEndTime;
	
	If Not CommonUseReUse.CanUseSeparatedData()
		Or DataAboutUpdate.DeferredUpdateIsCompletedSuccessfully <> Undefined
		Or DataAboutUpdate.HandlerTree <> Undefined
			AND DataAboutUpdate.HandlerTree.Rows.Count() = 0 Then
		Items.PostponedUpdate.Visible = False;
	EndIf;
	
	If CommonUse.FileInfobase() Then
		MessageTitle = NStr("en='Execute additional data processing procedures';ru='Необходимо выполнить дополнительные процедуры обработки данных';vi='Cần thực hiện các thủ tục bổ sung để xử lý dữ liệu'");
		Items.PostponedUpdateData.Title = MessageTitle;
	EndIf;
	
	If Not Users.InfobaseUserWithFullAccess(, True) Then
		Items.PostponedUpdateData.Title =
			NStr("en='Additional data processing procedures not executed';ru='Не выполнены дополнительные процедуры обработки данных';vi='Chưa thực hiện thủ tục bổ sung để xử lý dữ liệu'");
		Items.PostponedUpdateDataExplanation.Title = 
			NStr("en='Application operations are temporarily limited as the new version migration is not completed yet.';ru='Работа в программе временно ограничена, так как еще не завершен переход на новую версию.';vi='Hạn chế làm việc đồng thời trong chương trình, vì vẫn chưa kết thúc chuyển sang phiên bản mới.'");
	EndIf;
	
	If Not ValueIsFilled(UpdateBeginTime) AND Not ValueIsFilled(UpdateEndTime) Then
		Items.TechnicalInformationOnResultsOfUpdate.Visible = False;
	ElsIf Users.InfobaseUserWithFullAccess() AND Not CommonUseReUse.DataSeparationEnabled() Then
		Items.AddressFormsInApplication.TitleHeight = 2;
		Items.TechnicalInformationOnResultsOfUpdate.Visible = True;
	Else
		Items.TechnicalInformationOnResultsOfUpdate.Visible = False;
	EndIf;
	
	ClientServerBase = Not CommonUse.FileInfobase();
	
	// Show information on the scheduled jobs locking.
	If Not ClientServerBase
		AND Users.InfobaseUserWithFullAccess(, True) Then
		LaunchParameterClient = SessionParameters.ClientParametersOnServer.Get("LaunchParameter");
		ScheduledJobDisconnectionIsCompleted = Find(LaunchParameterClient, "ScheduledJobsDisabled") <> 0;
		If Not ScheduledJobDisconnectionIsCompleted Then
			Items.GroupDisabledScheduledJobs.Visible = False;
		EndIf;
	Else
		Items.GroupDisabledScheduledJobs.Visible = False;
	EndIf;
	
	InfobaseUpdateService.SetFlagDisplayDescriptionsForCurrentVersion();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	If ClientServerBase Then
		AttachIdleHandler("UpdateQueuedUpdatingStatus", 60);
	EndIf;
EndProcedure

#EndRegion

#Region HeaderFormItemsEventsHandlers

&AtClient
Procedure UpdatesDescriptionFullSelection(Item, Area, StandardProcessing)
	
	If Find(Area.Text, "http://") = 1 Or Find(Area.Text, "https://") = 1 Then
		GotoURL(Area.Text);
	EndIf;
	
	InfobaseUpdateClientOverridable.OnHyperlinkClickInUpdatesDescriptionDocument(Area);
	
EndProcedure

&AtClient
Procedure ShowAdditionalInformationOnResultsOfUpdateClick(Item)
	
	FormParameters = New Structure;
	FormParameters.Insert("ShowErrorsAndWarnings", True);
	FormParameters.Insert("StartDate", UpdateBeginTime);
	FormParameters.Insert("EndDate", UpdateEndTime);
	
	OpenForm("DataProcessor.EventLogMonitor.Form.EventLogMonitor", FormParameters);
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure PostponedUpdateData(Command)
	OpenForm("DataProcessor.InfobaseUpdate.Form.InfobaseDelayedUpdateProgressIndication");
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

&AtClient
Procedure UpdateQueuedUpdatingStatus()
	
	UpdateQueuedUpdatingStatusAtServer();
	
EndProcedure

&AtServer
Procedure UpdateQueuedUpdatingStatusAtServer()
	
	DataAboutUpdate = InfobaseUpdateService.DataOnUpdatingInformationBase();
	If DataAboutUpdate.EndTimeDeferredUpdate <> Undefined Then
		Items.PostponedUpdate.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure DisabledScheduledJobsNavigationRefsDataProcessor(Item, URL, StandardProcessing)
	StandardProcessing = False;
	
	Notification = New NotifyDescription("ScheduledJobsAreDisconnectionNavigationRefDataProcessorEnd", ThisObject);
	QuestionText = NStr("en='Restart the application?';ru='Перезапустить программу?';vi='Khởi động lại chương trình?'");
	ShowQueryBox(Notification, QuestionText, QuestionDialogMode.YesNo,, DialogReturnCode.No);
EndProcedure

&AtClient
Procedure ScheduledJobsAreDisconnectionNavigationRefDataProcessorEnd(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		NewLaunchParameter = StrReplace(LaunchParameter, "ScheduledJobsDisabled", "");
		NewLaunchParameter = StrReplace(NewLaunchParameter, "RunInfobaseUpdate", "");
		NewLaunchParameter = "/C """ + NewLaunchParameter + """";
		Terminate(True, NewLaunchParameter);
	EndIf;
	
EndProcedure

#EndRegion
