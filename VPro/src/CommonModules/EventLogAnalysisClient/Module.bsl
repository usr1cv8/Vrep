///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2020, ООО 1С-Софт
// Все права защищены. Эта программа и сопроводительные материалы предоставляются 
// в соответствии с условиями лицензии Attribution 4.0 International (CC BY 4.0)
// Текст лицензии доступен по ссылке:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region ServiceProgramInterface

////////////////////////////////////////////////////////////////////////////////
// Клиентские события формы отчета.

// Decryption handler of the tabular document of the report form.
//
// Parameters:
//   ReportForm - ClientApplicationForm, ManagedFormExtensionForReports - Форма отчета.
//   Item - FormField, FormFieldExtensionForASpreadsheetDocumentField - Табличный документ.
//   Details - DataCompositionDetailsID - Передается из параметров обработчика "как есть".
//   StandardProcessing - Boolean - Передается из параметров обработчика "как есть".
//
Procedure ReportFormDetailProcessing(ReportForm, Item, Details, StandardProcessing) Export
	If Details = Undefined Then
		Return;
	EndIf;
	
	If ReportForm.ReportSettings.FullName <> "Report.EventsLogAnalysis" Then
		Return;
	EndIf;
	
	If TypeOf(Item.CurrentArea) = Type("SpreadsheetDocumentDrawing") Then
		If TypeOf(Item.CurrentArea.Object) = Type("Chart") Then
			StandardProcessing = False;
			Return;
		EndIf;
	EndIf;
	
	ReportOptionParameter = ReportsClientServer.FindParameter(
		ReportForm.Report.SettingsComposer.Settings,
		ReportForm.Report.SettingsComposer.UserSettings,
		"ReportVariant");
	If ReportOptionParameter = Undefined Or ReportOptionParameter.Value <> "GanttChart" Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	TypeDetails = Details.Get(0);
	If TypeDetails = "DecryptionScheduledJobs" Then
		
		VariantDetails = New ValueList;
		VariantDetails.Add("InfoAboutScheduledJob", NStr("en='Сведения о регламентном задании';ru='Сведения о регламентном задании';vi='Thông tin công việc đã lên lịch'"));
		VariantDetails.Add("OpenEventLogMonitor", NStr("en='Перейти к журналу регистрации';ru='Перейти к журналу регистрации';vi='Đi tới nhật ký'"));
		
		HandlerParameters = New Structure;
		HandlerParameters.Insert("Details", Details);
		HandlerParameters.Insert("ReportForm", ReportForm);
		Handler = New NotifyDescription("ResultDetailDataProcessorEnd", ThisObject, HandlerParameters);
		ReportForm.ShowChooseFromMenu(Handler, VariantDetails);
		
	ElsIf TypeDetails <> Undefined Then
		ShowScheduledJobInfo(Details);
	EndIf;
	
EndProcedure

// Handler of the additional decryption (menu of the tabular document of report form).
//
// Parameters:
//   ReportForm - ClientApplicationForm, ManagedFormExtensionForReports - Форма отчета.
//   Item - FormField, FormFieldExtensionForASpreadsheetDocumentField - Табличный документ.
//   Details - DataCompositionDetailsID - Передается из параметров обработчика "как есть".
//   StandardProcessing - Boolean - Передается из параметров обработчика "как есть".
//
Procedure AdditionalDetailProcessingReportForm(ReportForm, Item, Details, StandardProcessing) Export
	If ReportForm.ReportSettings.FullName <> "Report.EventsLogAnalysis" Then
		Return;
	EndIf;
	If TypeOf(Item.CurrentArea) = Type("SpreadsheetDocumentDrawing") Then
		If TypeOf(Item.CurrentArea.Object) = Type("Chart") Then
			StandardProcessing = False;
			Return;
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

// Parameters:
//  SelectedVariant - ValueList - where:
//    * Value - String - 
//  HandlerParameters - Structure - where:
//    * Details - DataCompositionDetailsID - 
//    * ReportForm - ClientApplicationForm, ManagedFormExtensionForReports - where:
//        ** ReportSpreadsheetDocument - SpreadsheetDocument - 
//
Procedure ResultDetailDataProcessorEnd(SelectedVariant, HandlerParameters) Export
	If SelectedVariant = Undefined Then
		Return;
	EndIf;
	
	Action = SelectedVariant.Value;
	If Action = "InfoAboutScheduledJob" Then
		
		Chart = HandlerParameters.ReportForm.ReportSpreadsheetDocument.Areas.GanttChart; // РисунокТабличногоДокумента
		ChartObject = Chart.Object; // ДиаграммаГанта
		ListPoints = ChartObject.Points;
		
		ListPoints = ChartObject.Points;
		For Each GanttChartPoint In ListPoints Do
			
			DetailsDots = GanttChartPoint.Details;
			If GanttChartPoint.Value = NStr("en='Фоновые задания';ru='Фоновые задания';vi='Công việc nền'") Then
				Continue;
			EndIf;
			
			If DetailsDots.Find(HandlerParameters.Details.Get(2)) <> Undefined Then
				ShowScheduledJobInfo(DetailsDots);
				Break;
			EndIf;
			
		EndDo;
		
	ElsIf Action = "OpenEventLogMonitor" Then
		
		SessionScheduledJobs = New ValueList;
		SessionScheduledJobs.Add(HandlerParameters.Details.Get(1));
		BeginDate = HandlerParameters.Details.Get(3);
		EndDate = HandlerParameters.Details.Get(4);
		EventLogMonitorFilter = New Structure("Session, BeginDate, EndDate", 
			SessionScheduledJobs, BeginDate, EndDate);
		OpenForm("DataProcessor.EventLog.Form.EventLog", EventLogMonitorFilter);
		
	EndIf;
	
EndProcedure

Procedure ShowScheduledJobInfo(Details)
	FormParameters = New Structure("DetailsFromReport", Details);
	OpenForm("Report.EventsLogAnalysis.Form.InfoAboutScheduledJob", FormParameters);
EndProcedure

#EndRegion