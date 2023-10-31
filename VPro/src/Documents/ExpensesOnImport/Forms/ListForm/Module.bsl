
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(cancel, StandardProcessing)
	
	// Установим формат для текущей даты: ДФ=Ч:мм
	SmallBusinessServer.SetDesignDateColumn(List);
	
	//УНФ.ОтборыСписка
	WorkWithFilters.RestoreFilterSettings(ThisObject, List);
	//Конец УНФ.ОтборыСписка
	
	//// СтандартныеПодсистемы.ПодключаемыеКоманды
	//ArrangementParameters = AttachableCommands.ArrangementParameters();
	//ArrangementParameters.CommandBar = Items.ImportantCommandsGroup;
	//AttachableCommands.OnCreateAtServer(ThisObject, ArrangementParameters);
	//// Конец СтандартныеПодсистемы.ПодключаемыеКоманды
	
	// УНФ.ПанельКонтактнойИнформации
	//ContactInformationPanelCM.OnCreateAtServer(ThisObject, "ContactInformation", "ListContextMenu");
	// Конец УНФ.ПанельКонтактнойИнформации
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// УНФ.ПанельКонтактнойИнформации
	//If ContactsInformationPanelCMClient.ProcessAlerts(ThisObject, EventName, Parameter) Then
	//	UpdateContactInformationPanelServer();
	//EndIf;
	// Конец УНФ.ПанельКонтактнойИнформации
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit Then
		//УНФ.ОтборыСписка
		SaveFilterSettings();
		//Конец УНФ.ОтборыСписка
	EndIf; 

EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure CreateByTemplate(Command)
	
	ObjectsFillingCMClient.ShowTemplateChoiceForDocumentAddingFromList(
	"Document.ExpensesOnImport",
	List.SettingsComposer.Settings.Filter.Items,
	Items.List.CurrentRow);
	
EndProcedure

#EndRegion

#Region FormItemEventsHandlers

&AtClient
Procedure ListOnActivateRow(Item)
	
	If TypeOf(Item.CurrentRow) <> Type("DynamicListGroupRow") Then
		
		ActiveRowCounterparty = ?(Item.CurrentData = Undefined, Undefined, Item.CurrentData.Counterparty);
		If ActiveRowCounterparty <> CurrentCounterparty Then
		
			CurrentCounterparty = ActiveRowCounterparty;
			AttachIdleHandler("HandleListStringActivation", 0.2, True);
		EndIf;
		
	EndIf;
	
	// СтандартныеПодсистемы.ПодключаемыеКоманды
	//AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// Конец СтандартныеПодсистемы.ПодключаемыеКоманды
	
EndProcedure

&AtClient
Procedure FilterCounterpartyChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	If Not ValueIsFilled(SelectedValue) Then
		Return;
	EndIf;
	
	SetListLabelAndFilter("Counterparty", Item.Parent.Name, SelectedValue);
	SelectedValue = Undefined;
	
EndProcedure

&AtClient
Procedure FilterCompanyChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	If Not ValueIsFilled(SelectedValue) Then
		Return;
	EndIf;
	
	SetListLabelAndFilter("Company", Item.Parent.Name, SelectedValue);
	SelectedValue = Undefined;
	
EndProcedure

&AtClient
Procedure FilterResponsibleChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	If Not ValueIsFilled(SelectedValue) Then
		Return;
	EndIf;
	
	SetListLabelAndFilter("Responsible", Item.Parent.Name, SelectedValue);
	SelectedValue = Undefined;
	
EndProcedure

&AtClient
Procedure FilterWarehouseChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	If Not ValueIsFilled(SelectedValue) Then
		Return;
	EndIf;
	
	SetListLabelAndFilter("StructuralUnit", Item.Parent.Name, SelectedValue);
	SelectedValue = Undefined;
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

// Processes a row activation event of the document list.
//
&AtClient
Procedure HandleListStringActivation()
	
	UpdateContactInformationPanelServer();
	
EndProcedure

#EndRegion

#Region ContactInformationPanel

// CM.ContactInformationPanel
&AtServer
Procedure UpdateContactInformationPanelServer()
	
//	ContactInformationPanelCM.RefreshPanelData(ThisObject, CurrentCounterparty);
	
EndProcedure

&AtClient
Procedure Attachable_ContactInformationPanelDataChoice(Item, SelectedRow, Field, StandardProcessing)
	
//	ContactsInformationPanelCMClient.ContactInformationPanelDataChoice(ThisObject, Item, SelectedRow, Field, StandardProcessing);
	
EndProcedure
// Конец УНФ.ПанельКонтактнойИнформации

#EndRegion

#Region FiltersLabels

&AtServer
Procedure SetListLabelAndFilter(ListFilterFieldName, GroupLabelParent, SelectedValue, ValueDescription="")
	
	If ValueDescription="" Then
		ValueDescription=String(SelectedValue);
	EndIf; 
	
	WorkWithFilters.AttachFilterLabel(ThisObject, ListFilterFieldName, GroupLabelParent, SelectedValue, ValueDescription);
	WorkWithFilters.SetListFilter(ThisObject, List, ListFilterFieldName);
	
EndProcedure

&AtClient
Procedure Attachable_LabelURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	LabelID = Mid(Item.Name, StrLen("Label_")+1);
	DeleteFilterLabel(LabelID);
	
EndProcedure

&AtServer
Procedure DeleteFilterLabel(LabelID)
	
	WorkWithFilters.DeleteFilterLabelServer(ThisObject, List, LabelID);

EndProcedure

&AtClient
Procedure PeriodPresentationClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	WorkWithFiltersClient.PeriodPresentationChoosePeriod(ThisObject, "List", "Date");
	
EndProcedure

&AtServer
Procedure SaveFilterSettings()
	
	WorkWithFilters.SaveFilterSettings(ThisObject);
	
EndProcedure

&AtClient
Procedure CollapseExpandFiltersPanel(Item)
	
	NewValueVisibility = Not Items.FiltersSettingsAndExtraInfo.Visible;
	WorkWithFiltersClient.CollapseExpandFiltersPanel(ThisObject, NewValueVisibility);
		
EndProcedure

#EndRegion

#Region PerformanceMeasurements

&AtClient
Procedure ListBeforeAddRow(Item, cancel, Copy, Parent, Var_Group)
	
	//PerformanceEstimationClient.TimeMeasurement("FormCreation" + WorkWithDocumentFormClientServer.StringFormName(ThisObject.FormName));
	
EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, cancel)
	
//	PerformanceEstimationClient.TimeMeasurement("FormOpening" + WorkWithDocumentFormClientServer.StringFormName(ThisObject.FormName));
	
EndProcedure

#EndRegion

#Region LibrariesHandlers

// StandardSubsystems.AttachableCommands
//&AtClient
//Procedure Attachable_ExecuteCommand(Command)
//	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
//EndProcedure

//&AtServer
//Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
//	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
//EndProcedure

//&AtClient
//Procedure Attachable_UpdateCommands()
//	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
//EndProcedure
// Конец СтандартныеПодсистемы.ПодключаемыеКоманды

#EndRegion
