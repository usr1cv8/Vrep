
&AtServer
// Procedure - OnCreateAtServer event handler.
//
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	InformationCenterServer.OutputContextReferences(ThisForm, Items.InformationReferences);
	
	// StandardSubsystems.GroupObjectsChange
	If Items.Find("ListBatchObjectChanging") <> Undefined Then
		
		YouCanEdit = AccessRight("Edit", Metadata.Catalogs.ProductsAndServices);
		CommonUseClientServer.SetFormItemProperty(Items, "ListBatchObjectChanging", "Visible", YouCanEdit);
		
	EndIf;
	// End StandardSubsystems.GroupObjectChange
	
	// StandardSubsystems.AdditionalReportsAndDataProcessors
	AdditionalReportsAndDataProcessors.OnCreateAtServer(ThisForm);
	// End StandardSubsystems.AdditionalReportsAndDataProcessors
	
	// StandardSubsystems.DataImportFromExternalSources
	DataImportFromExternalSources.OnCreateAtServer(Metadata.Catalogs.ProductsAndServices, DataLoadSettings, ThisObject);
	// End StandardSubsystems.DataImportFromExternalSource
	
EndProcedure // OnCreateAtServer()

&AtClient
Procedure ChangeSelected(Command)
	
	GroupObjectsChangeClient.ChangeSelected(Items.List);
	
EndProcedure

&AtClient
Procedure Attachable_ClickOnInformationLink(Item)
	
	InformationCenterClient.ClickOnInformationLink(ThisForm, Item);
	
EndProcedure

&AtClient
Procedure Attachable_ReferenceClickAllInformationLinks(Item)
	
	InformationCenterClient.ReferenceClickAllInformationLinks(ThisForm.FormName);
	
EndProcedure

#Region LibrariesHandlers

// StandardSubsystems.DataImportFromExternalSources
&AtClient
Procedure DataImportFromExternalSources(Command)
	
	NotifyDescription = New NotifyDescription("ImportDataFromExternalSourceResultDataProcessor", ThisObject, DataLoadSettings);
	
	DataLoadSettings.Insert("TemplateNameWithTemplate",	"LoadFromFile");
	DataLoadSettings.Insert("SelectionRowDescription",	New Structure("FullMetadataObjectName, Type", "Products", "AppliedImport"));
	
	DataImportFromExternalSourcesClient.ShowDataImportFormFromExternalSource(DataLoadSettings, NotifyDescription, ThisObject);
	
EndProcedure

&AtClient
Procedure ImportDataFromExternalSourceResultDataProcessor(ImportResult, AdditionalParameters) Export
	
	If TypeOf(ImportResult) = Type("Structure") Then
		
		ProcessPreparedData(ImportResult);
		Items.List.Refresh();
		ShowMessageBox(,NStr("en='Data import is complete.';ru='Загрузка данных завершена.';vi='Hoàn thành kết nhập dữ liệu'"));
		
	ElsIf ImportResult = Undefined Then
		
		Items.List.Refresh();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessPreparedData(ImportResult)
	
	DataImportFromExternalSourcesOverridable.ImportDataFromExternalSourceResultDataProcessor(ImportResult);
	
EndProcedure
// End StandardSubsystems.DataImportFromExternalSource

// StandardSubsystems.PerformanceEstimation
&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Group)
	
	If Not Group Then
		KeyOperation = "FormCreatingProductsAndServices";
		PerformanceEstimationClientServer.StartTimeMeasurement(KeyOperation);
	EndIf;

EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	If Not Item.CurrentData.IsFolder Then
		KeyOperation = "FormOpeningProductsAndServices";
		PerformanceEstimationClientServer.StartTimeMeasurement(KeyOperation);
	EndIf;
	
EndProcedure
// End StandardSubsystems.PerformanceEstimation

#EndRegion
