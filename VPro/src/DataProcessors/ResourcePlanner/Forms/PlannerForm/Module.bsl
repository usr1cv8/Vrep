
&AtClient
Var LastRepresentationVariant;

&AtServer
Var SettingsImported;

#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If CommonUse.IsMobileClient() Then
		Items.DecorationExpandCalendar.Visible = False;
		Items.CollapseCalendar.Visible = False;
		Items.CollapseAdditional.Visible = False;
		Items.CollapseFilter.Visible = False;
		Items.RightBarGroup.ShowTitle = True;
		Items.HeaderGroup.Group = ChildFormItemsGroup.Vertical;
		Items.GroupDelimiter.Visible = False;
	Else
		Items.DecorationExpandCalendar.Visible = False;
		Items.GroupPages.Visible = True;
	EndIf;
	
	Items.FilterContact.TypeRestriction = New TypeDescription("String",, New StringQualifiers(100));
	
	RepresentationVariant = 1;
	SubsystemNumber = ?(Parameters.Property("SubsystemNumber"), Parameters.SubsystemNumber, 0);
	
	ThisSelection = Parameters.Property("ThisSelection");
	OnlyFormReview = ProfileAvailable("Only view");
	
	Items.DocumentsGroup.Visible = Not ThisSelection;
	Items.DocumentsGroup.Enabled = Not OnlyFormReview;
	
	SettingsImported = False;
	
	If Not OnlyFormReview Then
		ImportFormSettings();
	Else
		SetupSettingsDefaultColors();
		Items.ResourcesImportContextMenuGroup.Visible = False;
		Items.GroipTypeDocument.Visible = False;
	EndIf;
	
	If Not ValueIsFilled(CalendarDate) Then CalendarDate = CurrentSessionDate() EndIf;
	
	WorksScheduleRadioButton = ?(Not ValueIsFilled(WorksScheduleRadioButton), "Interval planning", WorksScheduleRadioButton);
	
	DatesArray = Undefined;
	
	If ThisSelection Then
		
		DatesArray = New Array;
		
		SetupSettingsFormItemsOnCreate();
		
		If Parameters.EnterpriseResources.Count() Then
			PlanningBoarders = Undefined;
			ProcessPickupEvent(Parameters.EnterpriseResources, DatesArray, PlanningBoarders);
		EndIf;
		
		PeriodLabel = UpdatePeriodRepresentation(Period);
		
	EndIf;
	
	If Not SettingsImported Then
		SetupSettingsDefaultColors();
		If Not ThisSelection Then
			Items.ShowPanningInterval.Check = True;
			SetupSettingsFormItemsOnCreate();
			PlanningBoarders = Undefined;
		EndIf;
	EndIf;
	
	ThisForm.Title = NStr("en='Scheduler resource';vi='Lịch biểu tài nguyên'");
	
	If Not SubsystemNumber = 0 Then 
		If SubsystemNumber = 1 Then OnlyBySubsystem1 = True; EndIf;
		If SubsystemNumber = 2 Then OnlyBySubsystem2 = True; EndIf;
		If SubsystemNumber = 3 Then 
			OnlyBySubsystem3 = True; 
			ThisForm.Title = NStr("en='Journal records';vi='Bản ghi nhật ký'");
		EndIf;
	EndIf;
	
	Items.OnlyBySubsystem1.Visible = Not ThisSelection;
	Items.OnlyBySubsystem2.Visible = Not ThisSelection;
	Items.OnlyBySubsystem3.Visible = Not ThisSelection;
	
	If Not GetFunctionalOption("PlanCompanyResourcesLoading") 
		Or (Not IsInRole("FullRights") And Not ProfileAvailable("Production")) Then
		
		Items.OnlyBySubsystem2.Visible = False;
		OnlyBySubsystem2 = False;
	EndIf;
	
	If Not GetFunctionalOption("PlanCompanyResourcesLoadingEventLog") Then
		Items.OnlyBySubsystem3.Visible = False;
		OnlyBySubsystem3 = False;
	EndIf;
	
	If Not GetFunctionalOption("PlanCompanyResourcesLoadingWorks") Then
		Items.OnlyBySubsystem1.Visible = False;
		OnlyBySubsystem1 = False;
	EndIf;
	
	If ColorPickedupInBin = New Color(0,0,0) Then
		ColorPickedupInBin = WebColors.RoyalBlue;
	EndIf;
	
	Items.GroupScaleBar.HorizontalStretch = Items.ShowMonth.Check;

	DisplayTableDocument(DatesArray,True);
	
	UpdatePickupedPeriods(False);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	LastRepresentationVariant = RepresentationVariant;
	SetupSettingsBySubsystemNumber();
	SetupBinRepresentation(True);
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not ThisSelection And Not OnlyFormReview And Not Exit Then
		FilterParameters =  New Structure("RepresentationVariant",RepresentationVariant);
		RowsByVariant = DataAttributesFormCache.FindRows(FilterParameters);
		DefaultVariant = (RowsByVariant.Count() And RowsByVariant[0].DefaultVariant) Or Not DataAttributesFormCache.Count();
		SaveDataVariantRepresentationClient(RepresentationVariant, DefaultVariant);
	EndIf;
	
	If SelectedResources.Count() And Not ThisSelection And Not Exit Then
		
		Mode = QuestionDialogMode.YesNo;
		
		NotificationParameters = New Structure("Exit", Exit);
		Notification = New NotifyDescription("AfterQuestionClosingOnClose", ThisForm, NotificationParameters);
		
		QuestionText = NStr("en = 'При закрытии данные о подборе будут утеряны. Продолжить?'; ru = 'При закрытии данные о подборе будут утеряны. Продолжить?'; vi = 'Khi đóng dữ liệu lựa chọn sẽ bị mất. Tiếp tục?'");
		
		ShowQueryBox(Notification, QuestionText, Mode, 0);
		
		Cancel = True;
		Return;
		
	EndIf;
	
	If Not Exit Then
		BeforeClosingAtServer();
	EndIf
	
EndProcedure

&AtServer
Procedure BeforeClosingAtServer()
	If Not ThisSelection And Not OnlyFormReview Then
		SaveFormSettings();
	EndIf;
	ListPeriodDates.Clear();
	Items.Calendar.SelectedDates.Clear();
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	
	If Not AddingFormBin Then 
		ResiurcesCollection = AddInDocumentBuffer;
	Else
		ResiurcesCollection = SelectedResources;
	EndIf;
	
	If Not SelectedValue = Undefined Then 
		If TypeOf(SelectedValue) = Type("DocumentRef.ProductionOrder") Then
			OpenParameters = New Structure("Key, SelectedResources, OpenFormPlanner",SelectedValue, ResiurcesCollection, True);
			OpenForm("Document.ProductionOrder.ObjectForm", OpenParameters, ThisForm);
		EndIf;
		
		If TypeOf(SelectedValue) = Type("DocumentRef.CustomerOrder") Then
			OpenParameters = New Structure("Key, SelectedResources, OpenFormPlanner",SelectedValue, ResiurcesCollection, True);
			OpenForm("Document.CustomerOrder.Form.FormWorkOrder", OpenParameters, ThisForm);
		EndIf;
		
		If TypeOf(SelectedValue) = Type("DocumentRef.Event") Then
			OpenParameters = New Structure("Key, SelectedResources, OpenFormPlanner",SelectedValue, ResiurcesCollection, True);
			OpenForm("Document.Event.Form.FormEventCounterpartyRecord", OpenParameters, ThisForm);
		EndIf;
		
		AddInDocumentBuffer.Clear();
		SelectedResources.Clear();
		SetupBinRepresentation();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "UpdatePlanner" Then
		DisplayTableDocument();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormItemEventsHandlers

&AtClient
Procedure DecorationSelectedClick(Item)
	OpenBin();
EndProcedure

&AtClient
Procedure ResourcesImportSelection(Item, Area, StandardProcessing)
	
	RowCoordinate = Format(Area.Top,"NG=");
	ColumnCoordinate = ?(WorksScheduleRadioButton = "Month",Format(Area.Left,"NG="),1);
	
	CellDetails = ResourcesImport.Area("R"+String(RowCoordinate)+"C"+String(ColumnCoordinate)).Details;
	
	Resource = Undefined;
	GraphControl = False;
	
	If TypeOf(CellDetails) = Type("Structure") And CellDetails.Property("Resource") And Not CellDetails.Property("DocumentReference") Then
		Resource = CellDetails.Resource;
		
		If Area.Left = 1 Then
			StandardProcessing = False;
			
			OpenParameters = New Structure("Key", Resource);
			OpenForm("Catalog.KeyResources.ObjectForm",OpenParameters,ThisForm);
			Return
			
		EndIf;
		
		GraphControl = ?(CellDetails.Property("ControlLoadingOnlyInWorkTime"), CellDetails.ControlLoadingOnlyInWorkTime, False);
		
		BeginTime = PositioningPeriod;
		EndTime = PositioningPeriod + (Area.Right - Area.Left-1)*300;
		PeriodDay = PeriodPresentation;
		
		If (WorksScheduleRadioButton = "Interval planning" And ValueIsFilled(PeriodDay))
			Or (WorksScheduleRadioButton = "Day" And ValueIsFilled(PeriodDay)) Or WorksScheduleRadioButton = "Month" Then
			StandardProcessing = False;
			ProcessEventIntervalChoice(Resource, Area, PeriodDay, GraphControl);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ResourcesImportDetailProcessing(Item, Details, StandardProcessing, AdditionalParameters)
	
	If TypeOf(Details) = Type("Structure") And Details.Property("DetailsKind") Then
		
		StandardProcessing = False;
		
		If Details.DetailsKind = "PostionigOnDocument" Then
			
			PositioningOnArea(, Details.DocumentReference, Details.Resource, Details.DocumentLineNumber);
			Return
		EndIf;
		
		If Details.DetailsKind = "CreateNewResourrce" Then
			
			CreateNewResourrce();
			Return
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ResourcesImportOnActivate(Item)
	
	OnActivateSreadSheetDocument();
	
EndProcedure

&AtClient
Procedure CollapseCalendarClick(Item)
	Items.GroupPages.Visible = Not Items.GroupPages.Visible;
	Items.DecorationExpandCalendar.Visible = Not Items.GroupPages.Visible;
EndProcedure

&AtClient
Procedure DecorationExpandCalendarClick(Item)
	
	Items.GroupPages.Visible = Not Items.GroupPages.Visible;
	Items.DecorationExpandCalendar.Visible = Not Items.DecorationExpandCalendar.Visible;
	
	Items.Calendar.SelectedDates.Clear();
	
	For Each ListDate In ListPeriodDates Do
		Items.Calendar.SelectedDates.Add(ListDate.Value);
	EndDo;
	
EndProcedure

&AtClient
Procedure PositioningPeriodOnChange(Item)
	PositioningOnArea(PeriodPresentation);
EndProcedure

&AtClient
Procedure FilterResourcesChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	If Not ValueIsFilled(SelectedValue) Then
		Return;
	EndIf;
	
	SetListTagAndFilter("Resource", Item.Parent.Name, SelectedValue);
	SelectedValue = Undefined;
	
EndProcedure

&AtClient
Procedure CalendarOnActivateDate(Item)
	
	If Not Items.Calendar.SelectedDates.Count() Then Return EndIf;
	
	WasListCleaning = False;
	
	If Items.Calendar.SelectedDates.Count() = 1 And ListPeriodDates.Count() = 1
		And Not Items.Calendar.SelectedDates[0] = ListPeriodDates[0].Value Then
		ListPeriodDates.Clear();
		WasListCleaning = True;
	EndIf;
	
	If Items.Calendar.SelectedDates.Count() = ListPeriodDates.Count() Then
		Return
	EndIf;
	
	If WorksScheduleRadioButton = "Month" Then
		AddDateForMonthEnd();
	EndIf;
	
	If Not WasListCleaning Then
		ListPeriodDates.Clear();
	EndIf;
	
	ListPeriodDates.LoadValues(Items.Calendar.SelectedDates);
	ListPeriodDates.SortByValue(SortDirection.Asc);
	
	PeriodSelection = True;
	
	AttachIdleHandler("OutputSpreadSheetClient", 1, True);
EndProcedure

&AtClient
Procedure PeriodPresentationChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	If Not TypeOf(SelectedValue) = Type("Date") Then
		PeriodDate = Date(SelectedValue +" 00:00:00");
	Else
		PeriodDate = BegOfDay(SelectedValue);
	EndIf;
	
	PositioningOnArea(PeriodDate);
	
	If SwitchCaledarFilters = "Interval planning" Then
		FillListPositioningPeriod();
	EndIf;
	
EndProcedure

&AtClient
Procedure PeriodLabelClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	Notification = New NotifyDescription("PeriodLabelOnClickEnd", ThisObject, Parameters);
	
	Dialog = New StandardPeriodEditDialog;
	Dialog.Period = Period;
	
	Dialog.Show(Notification);
	
EndProcedure

&AtClient
Procedure FilterCounterpartyChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	If Not ValueIsFilled(SelectedValue) Then
		Return;
	EndIf;
	
	FilterContacts = New Array;
	FilterContacts.Add(SelectedValue);
	
	//AddCounterpertyFilterByContacts(FilterContacts, SelectedValue);
	
	SetListTagAndFilter("Counterparty", Item.Parent.Name, FilterContacts, String(SelectedValue));
	SelectedValue = Undefined;
	
EndProcedure

&AtClient
Procedure RepresentationVariantOnChange(Item)
	
	If RepresentationVariant = 7 Then
		CreateVariant();
		Return;
	EndIf;
	
	If Not LastRepresentationVariant = Undefined Then
		
		FilterParameters =  New Structure("RepresentationVariant",LastRepresentationVariant);
		RowsByVariant = DataAttributesFormCache.FindRows(FilterParameters);
		DefaultVariant = RowsByVariant.Count() And RowsByVariant[0].DefaultVariant;
		
		SaveDataVariantRepresentationClient(LastRepresentationVariant, DefaultVariant);
		
	EndIf;
	
	RestoreFiledsRepresentationData(RepresentationVariant);
	
	LastRepresentationVariant = RepresentationVariant;
	
	UpdatePeriodRepresentation(Period);
	
	SetupSettingsBySubsystemNumber();
	
EndProcedure

&AtClient
Procedure UseVariantsOnChange(Item)
	Items.GroupRepresentationVariant.Visible = UseVariants;
	
	If Not UseVariants Then
		DataAttributesFormCache.Clear();
		DataMarksCache.Clear();
		Items.RepresentationVariant.ChoiceList.Clear();
		Items.RepresentationVariant.ChoiceList.Add(1, NStr("en='Variant 1(main)';vi='Phương án 1(chính)';"));
		Items.RepresentationVariant.ChoiceList.Add(7, "+");
	EndIf;
	
	SaveDataVariantRepresentationClient(1, True);
	RepresentationVariant = 1;
	LastRepresentationVariant = 1;
	
	VariantList = New ValueList;
	For Each VariantValue In Items.RepresentationVariant.ChoiceList Do
		VariantList.Add(VariantValue.Value, VariantValue.Presentation);
	EndDo;
	UpdateVariantsList(VariantList);
	
EndProcedure

&AtClient
Procedure BeginOfRepresentationIntervalOnChange(Item)
	
	DatesArray = Items.Calendar.SelectedDates;
	
	DisplayTableDocument(DatesArray);
	
	FillListPositioningPeriod();
EndProcedure

&AtClient
Procedure RepresentationIntervalEndOnChange(Item)
	
	DatesArray = Items.Calendar.SelectedDates;
	
	DisplayTableDocument(DatesArray);
	
	FillListPositioningPeriod();
EndProcedure

&AtClient
Procedure IntervalStepMinOnChange(Item)
	
	RemainderOfDivision = IntervalStepMin%5;
	
	If IntervalStepMin < 15 And Not IntervalStepMin = 0 Then
		IntervalStepMin = 15
	Else
		If Not RemainderOfDivision%5 = 0 Then
			IntervalStepMin = IntervalStepMin + (5-RemainderOfDivision);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure IntervalStepMinTuning(Item, Direction, StandardProcessing)
	
	StandardProcessing = False;
	
	If IntervalStepMin < 15 And Not IntervalStepMin = 0 Then 
		IntervalStepMin = 15
	Else
		IntervalStepMin = ?(Direction>0, IntervalStepMin+5, IntervalStepMin-5);
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterResourceKindChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	If Not ValueIsFilled(SelectedValue) Then
		Return;
	EndIf;
	
	SetListTagAndFilter("ResourceKind", Item.Parent.Name, SelectedValue);
	SelectedValue = Undefined;
	
EndProcedure

&AtClient
Procedure FilterDocumentStartChoice(Item, ChoiceData, StandardProcessing)
	
	List = New ValueList;
	
	If OnlyBySubsystem1 And Not OnlyBySubsystem2 And Not OnlyBySubsystem3 Then
		OpenParameters = New Structure("ChoiceMode", True);
		OpenForm("Document.CustomerOrder.Form.ListFormWorkOrder", OpenParameters, Item,,,,,FormWindowOpeningMode.LockOwnerWindow);
		Return;
	ElsIf OnlyBySubsystem2 And Not OnlyBySubsystem1 And Not OnlyBySubsystem3 Then
		OpenParameters = New Structure();
		OpenForm("Document.ProductionOrder.Form.ChoiceForm", OpenParameters, Item,,,,,FormWindowOpeningMode.LockOwnerWindow);
		Return;
	ElsIf OnlyBySubsystem3 And Not OnlyBySubsystem2 And Not OnlyBySubsystem1 Then
		OpenParameters = New Structure("ChoiceMode, EventType", True, PredefinedValue("Enum.EventTypes.Record"));
		OpenForm("Document.Event.ListForm", OpenParameters, Parameters.Item,,,,,FormWindowOpeningMode.LockOwnerWindow);
		Return;
	Else
		
		If OnlyBySubsystem2 Then
			List.Add(Nstr("en='Production order';ru='Заказ на производство';vi='Đơn hàng sản xuất'"));
		EndIf;
		
		If OnlyBySubsystem1 Then
			List.Add(Nstr("en='Work order';ru='Заказ наряд';vi='Đơn hàng trọn gói'"));
		EndIf;
		
		If OnlyBySubsystem3 Then
			List.Add(Nstr("en='Event ""Record""';ru='Событие ""Запись""';vi='Sự kiện ""Bản ghi""'"));
		EndIf;
	
	EndIf;
	
	NotificationParameters = New Structure("Item", Item);
	Notification = New NotifyDescription("AfterChoiceDocumentFormMenu", ThisForm, NotificationParameters);
	
	ShowChooseFromMenu(Notification, List, Item);
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure FilterDocumentChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	StandardProcessing = False;
	
	SetListTagAndFilter("Document", Item.Parent.Name, SelectedValue);
	FilterDocument = Undefined;
	
EndProcedure

&AtClient
Procedure FilterContactOnChange(Item)
	DisplayTableDocument();
EndProcedure

&AtClient
Procedure ColorNotworkingTimeOnChange(Item)
	OnChangeIntervalColor()
EndProcedure

&AtClient
Procedure ColorWorkTimeOnChange(Item)
	OnChangeIntervalColor()
EndProcedure

&AtClient
Procedure ColorPartialLoadingBeforeOnChange(Item)
	OnChangeIntervalColor()
EndProcedure

&AtClient
Procedure ColorPartialLoadingAfterOnChange(Item)
	OnChangeIntervalColor()
EndProcedure

&AtClient
Procedure ColorFullLoadingOnChange(Item)
	OnChangeIntervalColor()
EndProcedure

&AtClient
Procedure ColorOverloadingOnChange(Item)
	OnChangeIntervalColor()
EndProcedure

&AtClient
Procedure ColorPickedupInBinOnChange(Item)
	OnChangeIntervalColor()
EndProcedure

&AtClient
Procedure OnlyBySubsystemOnChange(Item)
	SetupSettingsBySubsystemNumber();
EndProcedure

&AtClient
Procedure OnlyBySubsystem2OnChange(Item)
	SetupSettingsBySubsystemNumber()
EndProcedure

&AtClient
Procedure OnlyBySubsystem3OnChange(Item)
	SetupSettingsBySubsystemNumber();
EndProcedure

&AtClient
Procedure OnlyWorkTimeOnChange(Item)
	
	If Not OnlyWorkTime Then
		Items.GroupRepresentationInterval.Enabled = True;
		BeginOfRepresentationInterval = Date(1,1,1);
		RepresentationIntervalEnd = Date(1,1,1);
	Else
		Items.GroupRepresentationInterval.Enabled = False;
	EndIf;
	
	DisplayTableDocument();
	
EndProcedure

#EndRegion

#Region HandlersCommandFormEvents

&AtClient
Procedure CommandDeleteVariant(Command)
	
	If RepresentationVariant = 7 Or RepresentationVariant = 0 Or Items.RepresentationVariant.ChoiceList.Count() = 2 Then Return EndIf;
	
	FilterParameters =  New Structure("RepresentationVariant",RepresentationVariant);
	RowsByVariant = DataAttributesFormCache.FindRows(FilterParameters);
	
	DeletedDefaultVariant = RowsByVariant.Count() And RowsByVariant[0].DefaultVariant;
		
	If Items.RepresentationVariant.ChoiceList.Count() = 2 Or DeletedDefaultVariant Then 
		
		DescriptionFirstVariant = Items.RepresentationVariant.ChoiceList[0].Presentation;
		
		Items.RepresentationVariant.ChoiceList[0].Presentation  = ?(StrFind(DescriptionFirstVariant, "(chính)") = 0
																		, DescriptionFirstVariant + "(chính)", DescriptionFirstVariant);
		
		DataAttributesFormCache[0].DefaultVariant = True;
		
	EndIf;
	
	DeleteRowByVariantRepresentation(RepresentationVariant);
	
	DataMarksCache.Sort("RepresentationVariant Asc");
	
	For Each TagsRow In DataMarksCache Do
		TagsRow.RepresentationVariant = ?(TagsRow.RepresentationVariant>RepresentationVariant, TagsRow.RepresentationVariant-1, TagsRow.RepresentationVariant);
	EndDo;
	
	RepresentationVariant = RepresentationVariant - 1;
	
	Items.RepresentationVariant.ChoiceList.Delete(RepresentationVariant);
	
	VariantCount = Items.RepresentationVariant.ChoiceList.Count()-1;
	
	DataAttributesFormCache.Sort("RepresentationVariant Asc");
	
	For ListIndex = 1 To VariantCount Do
		
		Items.RepresentationVariant.ChoiceList[ListIndex-1].Value = ListIndex;
		DataAttributesFormCache[ListIndex-1].RepresentationVariant = ListIndex;
		
	EndDo;
	
	RepresentationVariant = ?(RepresentationVariant = 0,1,RepresentationVariant);
	RestoreFiledsRepresentationData(RepresentationVariant);
	
	LastRepresentationVariant = RepresentationVariant;
	
	VariantList = New ValueList;
	
	For Each VariantValue In Items.RepresentationVariant.ChoiceList Do
		VariantList.Add(VariantValue.Value, VariantValue.Presentation);
	EndDo;
	UpdateVariantsList(VariantList);
	
EndProcedure

&AtServer
Procedure UpdateVariantsList(VariantList)
	
	Items.RepresentationVariant.ChoiceList.Clear();
	
	For Each Variant In VariantList Do
		Items.RepresentationVariant.ChoiceList.Add(Variant.Value, Variant.Presentation);
	EndDo;
	
EndProcedure

&AtServer
Procedure CommandColorsByDefaultAtServer()
	SetupSettingsDefaultColors();
EndProcedure

&AtClient
Procedure CommandColorsByDefault(Command)
	CommandColorsByDefaultAtServer();
EndProcedure

&AtClient
Procedure CommandCreateVariant(Command)
	
	CreateVariant();
	
EndProcedure

&AtClient
Procedure CommandCopyVariant(Command)
	
	CreateVariant(True);
	
EndProcedure

&AtClient
Procedure CommandRenameVariant(Command)
	
	If Not ValueIsFilled(RepresentationVariant) Then Return EndIf;
	
	VariantPresentation = StrReplace(Items.RepresentationVariant.ChoiceList[RepresentationVariant-1].Presentation, "(chính)", "");
	
	OpenParameters = New Structure("VariantName", VariantPresentation);
	NotificationParameters = New Structure();
	
	Notification = New NotifyDescription("SetupVariantDescription", ThisObject, Parameters);
	
	OpenForm("DataProcessor.ResourcePlanner.Form.FormRenameVariant", OpenParameters,ThisObject,,,,Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CommandMainVariant(Command)
	
	If RepresentationVariant = 7 Or RepresentationVariant = 0 Or Items.RepresentationVariant.ChoiceList.Count() = 2 Then Return EndIf;
	
	SaveDataVariantRepresentationClient(RepresentationVariant, True);
	
	VariantCount = Items.RepresentationVariant.ChoiceList.Count()-1;
	
	For ListIndex = 1 To VariantCount Do
		
		VariantPresentation = Items.RepresentationVariant.ChoiceList[ListIndex-1].Presentation;
		VariantPresentation= StrReplace(VariantPresentation, "(chính)", "");
		
		If DataAttributesFormCache[ListIndex-1].RepresentationVariant = RepresentationVariant Then
			
			VariantPresentation= ?(VariantPresentation = NStr("en='Variant ';vi='Phương án ';") + String(ListIndex)
									, NStr("en='Variant ';vi='Phương án ';") + String(ListIndex) + "(chính)", VariantPresentation+NStr("en='(main)';vi='(chính)';"));
			
			Items.RepresentationVariant.ChoiceList[ListIndex-1].Presentation = VariantPresentation;
			Continue
		EndIf;
		
		If DataAttributesFormCache[ListIndex-1].DefaultVariant Then
			DataAttributesFormCache[ListIndex-1].DefaultVariant = False;
			Items.RepresentationVariant.ChoiceList[ListIndex-1].Presentation = VariantPresentation;
		EndIf;
	EndDo;
	
	VariantList = New ValueList;
	For Each VariantValue In Items.RepresentationVariant.ChoiceList Do
		VariantList.Add(VariantValue.Value, VariantValue.Presentation);
	EndDo;
	UpdateVariantsList(VariantList);
	
EndProcedure

&AtClient
Procedure CommandCreateCustomerOrder(Command)
	AddingFormBin = True;
	CreateWorkOrder();
	
	SelectedResources.Clear();
	SetupBinRepresentation();
EndProcedure

&AtClient
Procedure CommandCreateProductionOrder(Command)
	AddingFormBin = True;
	CreateProductionOrder();
	
	SelectedResources.Clear();
	SetupBinRepresentation();
EndProcedure

&AtClient
Procedure ShowPanningInterval(Command)
	
	WorksScheduleRadioButton = "Interval planning";
	
	Items.ShowPanningInterval.Check = True;
	Items.ShowDay.Check = False;
	Items.ShowMonth.Check = False;
	Items.GroupIntervalSetting.Enabled = True;
	Items.GroupScaleBar.HorizontalStretch = False;
	Items.GroupStepIntervalMin.Visible = True;
	
	DatesArray = Items.Calendar.SelectedDates;
	
	If DatesArray.Count()>14 Then
		LastDate = DatesArray[DatesArray.Count()-1];
		DatesArray.Clear();
		DatesArray.Add(LastDate);
		CalendarDate = LastDate;
		CleanFilterPeriod();
		PeriodLabel = UpdatePeriodRepresentation(Period);
	EndIf;
	
	DisplayTableDocument(DatesArray);
	
	FillListPositioningPeriod();
	
	CurrentPosition = Items.ResourcesImport.CurrentArea;
	CurRowCoordinate = String(?(CurrentPosition.Bottom=1, 3, Format(CurrentPosition.Bottom,"NG=")));
	Items.ResourcesImport.CurrentArea = ResourcesImport.Area("R"+CurRowCoordinate+"C"+"5");
	
EndProcedure

&AtClient
Procedure ShowDay(Command)
	
	WorksScheduleRadioButton = "Day";
	
	Items.ShowPanningInterval.Check = False;
	Items.ShowDay.Check = True;
	Items.ShowMonth.Check = False;
	Items.GroupStepIntervalMin.Visible = False;
	Items.GroupIntervalSetting.Enabled = True;
	Items.GroupScaleBar.HorizontalStretch = False;
	
	DisplayTableDocument();
	
	CurrentPosition = Items.ResourcesImport.CurrentArea;
	CurRowCoordinate = String(?(CurrentPosition.Bottom=1, 3, Format(CurrentPosition.Bottom,"NG=")));
	Items.ResourcesImport.CurrentArea = ResourcesImport.Area("R"+CurRowCoordinate+"C"+"5");
	
EndProcedure

&AtClient
Procedure ShowMonth(Command)
	
	WorksScheduleRadioButton = "Month";
	
	Items.ShowPanningInterval.Check = False;
	Items.ShowDay.Check = False;
	Items.ShowMonth.Check = True;
	Items.GroupIntervalSetting.Enabled = False;
	Items.GroupScaleBar.HorizontalStretch = True;
	
	DisplayTableDocument();
	
	FillListPositioningPeriod();
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	DatesArray = Items.Calendar.SelectedDates;
	
	DisplayTableDocument(DatesArray);
	
	FillListPositioningPeriod();
EndProcedure

&AtClient
Procedure SelectedResources(Command)
	
	OpenParameters = New Structure("SelectedResources", SelectedResources);
	
	NotificationParameters = New Structure();
	
	Notification = New NotifyDescription("ProcessBinData", ThisObject, NotificationParameters);
	
	OpenForm("ExternalDataProcessor.ResourcePlanner.Form.FormSelectedResources",OpenParameters,ThisForm,,,,Notification,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CommandAddInProductionOrder(Command)
	AddingFormBin = True;
	AddInProductionOrder();
EndProcedure

&AtClient
Procedure CommandAddInWorkOrder(Command)
	AddingFormBin = True;
	AddInWorkOrder();
EndProcedure

&AtClient
Procedure CommandAddInEvent(Command)
	AddingFormBin = True;
	AddInEvent();
EndProcedure

&AtClient
Procedure CommandCreateEvent(Command)
	AddingFormBin = True;
	CreateEvent();
	
	SelectedResources.Clear();
	SetupBinRepresentation();
EndProcedure

&AtClient
Procedure CommandMoveInDocument(Command)
	TransferToDocument()
EndProcedure

&AtClient
Procedure CommandPickupInBin(Command)
	
	ListPeriodDates.SortByValue(SortDirection.Asc);
	
	SelectedAreas = Items.ResourcesImport.GetSelectedAreas();
	
	CompletePickup = False;

	If WorksScheduleRadioButton = "Interval planning" Then
		CompletePickup = CompleteOnExistNotWorkingPeriods(SelectedAreas);
	EndIf;
	
	If Not CompletePickup Then
		PickupInBinFromContexBarEnd(SelectedAreas);
	Else
		
		NotificationParameters = New Structure("SelectedAreas", SelectedAreas);
		Notification = New NotifyDescription("AfterQuestionClosingPickUpFromContexBar", ThisForm, NotificationParameters);
		
		Mode = QuestionDialogMode.YesNo;
		ShowQueryBox(Notification, NStr("en='Выделенные области содержат интервалы за границами графика рабочего времени. Продолжить?';ru='Выделенные области содержат интервалы за границами графика рабочего времени. Продолжить?';vi='Các khu vực được chọn chứa các khoảng vượt ra ngoài ranh giới của lịch làm việc. Tiếp tục?'"), Mode, 0);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MenuCreateEvent(Command)
	FillBuffer();
	AddingFormBin = False;
	CreateEvent();
	AddInDocumentBuffer.Clear();
EndProcedure

&AtClient
Procedure MenuCreateCustomerOrder(Command)
	FillBuffer();
	AddingFormBin = False;
	CreateWorkOrder();
	AddInDocumentBuffer.Clear();
EndProcedure

&AtClient
Procedure MenuCreateProductionOrder(Command)
	FillBuffer();
	AddingFormBin = False;
	CreateProductionOrder();
	AddInDocumentBuffer.Clear();
EndProcedure

&AtClient
Procedure MenuAddInWorkOrder(Command)
	FillBuffer();
	AddingFormBin = False;
	AddInWorkOrder();
EndProcedure

&AtClient
Procedure MenuAddInProductionOrder(Command)
	FillBuffer();
	AddingFormBin = False;
	AddInProductionOrder();
EndProcedure

&AtClient
Procedure MenuAddInEvent(Command)
	FillBuffer();
	AddingFormBin = False;
	AddInEvent();
EndProcedure

#EndRegion

#Region HandlersSpreadSheetCreate

&AtClient
Procedure OutputSpreadSheetClient()
	
	DatesArray = Items.Calendar.SelectedDates;
	
	If DatesArray.Count()>14 And WorksScheduleRadioButton = "Interval planning" Then
		Items.ShowPanningInterval.Check = False;
		Items.ShowDay.Check = True;
		WorksScheduleRadioButton = "Day"
	EndIf;
	
	DisplayTableDocument(DatesArray, True);
	
	CleanFilterPeriod();
	FillListPositioningPeriod();
	
	If Not WorksScheduleRadioButton = "Month" And Not ValueIsFilled(PositioningPeriod) Then
		Items.ResourcesImport.CurrentArea = ResourcesImport.Area("R7C5");
		PositioningOnArea(PeriodPresentation);
	EndIf;
	
EndProcedure

&AtServer
Procedure DisplayTableDocument(DatesArray = Undefined, FormOpening = False, OutputFromCalendar = False)
	
	DaysCoordinates.Clear();
	DocumentsCoordinate.Clear();
	ResourcesByRows.Clear();

	Items.PositioningPeriod.ChoiceList.Clear();
	Items.PeriodPresentation.ChoiceList.Clear();
	Items.RepresentationIntervalEnd.ChoiceList.Clear();
	Items.BeginOfRepresentationInterval.ChoiceList.Clear();
	
	If Not DatesArray = Undefined Then
		ListPeriodDates.Clear();
		ListPeriodDates.LoadValues(DatesArray);
		ListPeriodDates.SortByValue(SortDirection.Asc);
	EndIf;
	
	If Not ListPeriodDates.Count() Then 
		
		CalendarDate = BegOfDay(CurrentSessionDate());
		
		ListPeriodDates.Add(CalendarDate);
		Items.Calendar.SelectedDates.Add(CalendarDate);
		Period.StartDate = CalendarDate;
		Period.EndDate = CalendarDate;
		PeriodLabel = UpdatePeriodRepresentation(Period);
	EndIf;
	
	If WorksScheduleRadioButton = "Month" And Not OutputFromCalendar Then
		FillListDaysByMonth();
		If ListPeriodDates.Count() Then
			Period.StartDate = ListPeriodDates[0].Value;
			Period.EndDate = ListPeriodDates[ListPeriodDates.Count()-1].Value;
			PeriodLabel = UpdatePeriodRepresentation(Period);
		EndIf
	EndIf;
	
	ResourcesImport.Clear();
	
	StructureColors = New Structure;
	
	StructureColors.Insert("AvailableResourceCellColor", ?(Not ColorWorkTime = Undefined, ColorWorkTime,StyleColors.WorktimeCompletelyBusy));
	StructureColors.Insert("ResourceIsNotEditableCellColor",?(Not ColorNotworkingTime = Undefined, ColorNotworkingTime,StyleColors.WorktimeFreeAvailable));
	
	DataProcessor = FormAttributeToValue("Object");
	TemplateResourcesPlanning = DataProcessor.GetTemplate("CalendarWithoutLoading");
	
	TemplateArea = TemplateResourcesPlanning.GetArea("PeriodPresentation|Title");
	
	StructurePlanningStep = StructurePlanningInterval();
	
	If StructurePlanningStep.Count() Then
		MinPlanningStep = StructurePlanningStep.MinInterval;
		MinIntervalResource = StructurePlanningStep.Resource;
	Else
		MinIntervalResource = Undefined;
		MinPlanningStep = 1200
	EndIf;
	
	MinInterval = 5;
	
	Items.GroupRepresentationInterval.Visible = ?(WorksScheduleRadioButton = "Interval planning", True, False);
	Items.GroupFilterContact.Visible = ?(WorksScheduleRadioButton = "Interval planning", True, False);
	
	ResourcesAndDocuments = StructureResourceAndDocuments();
	
	ComapnyResourcesTable = ResourcesAndDocuments.ResourcesTable;
	
	If Not ComapnyResourcesTable.Count() Then
		
		TemplateArea = TemplateResourcesPlanning.GetArea("SplashWithoutResources|Text");
		
		DetailsStructure = New Structure("DetailsKind", "CreateNewResourrce");
		TemplateArea.Parameters.Details = DetailsStructure;

		If Not LabelData.Count() Then
			TextEmptySpreadSheetDocument = NStr("en='Enterprise resources are missing. Create items in Company Resources and set a calendar."
"After adding the resource, click the button ""Update""';ru='Ресурсы предприятия отсутствуют. Создайте элементы в справочнике ""Ресурсы предприятия"" и установите график работы."
"После добавления ресурса нажмите кнопку ""Обновить""';vi='Không có nguồn lực doanh nghiệp. Tạo các mục trong thư mục Tài nguyên doanh nghiệp và đặt lịch. Sau khi thêm tài nguyên, nhấp vào nút ""Cập nhật""'");
		
			TemplateArea.Parameters.TextOfMessage = TextEmptySpreadSheetDocument;
			ResourcesImport.Put(TemplateArea);
			
		Else
			TextEmptySpreadSheetDocument = NStr("en='There are no enterprise resources that meet the filter parameters. Change filter parameters.';ru='Ресурсы предприятия удовлетворяющие параметрам отбора отсутствуют. Измените параметры отбора.';vi='Tài nguyên doanh nghiệp đáp ứng các tham số lựa chọn không có. Thay đổi các tùy chọn lọc.'");
			
			TemplateArea.Parameters.TextOfMessage = TextEmptySpreadSheetDocument;
			ResourcesImport.Put(TemplateArea);
		EndIf;
		
		Return;
	EndIf;
	
	ResourcesImport.FixedLeft = 4;
	ResourcesImport.FixedTop = 4;
	
	ResourcesDataPacket = GetResourcesWorkImportSchedule(ComapnyResourcesTable.UnloadColumn("Resource"), ResourcesAndDocuments.DocumentList);
	
	WorkPeriods = ResourcesDataPacket.WorkPeriods;
	
	If FormOpening And ThisSelection And IsWorksPeriods(WorkPeriods) And ListPeriodDates.Count() <= 14 Then
		OnlyWorkTime = True;
		Items.GroupRepresentationInterval.Enabled = False;
	EndIf;
	
	ScheduleLoading = ResourcesDataPacket.ScheduleLoading;

	If WorksScheduleRadioButton = "Interval planning" And ListPeriodDates.Count() <= 14 Then
		
		Items.ShowPanningInterval.Check = True;
		
		OutputScheduleMultiplicityInterval(TemplateResourcesPlanning, TemplateArea, StructureColors
		, ComapnyResourcesTable, WorkPeriods, ScheduleLoading, MinIntervalResource);
		
	Else
		
		If WorksScheduleRadioButton = "Interval planning" Then
			
			WorksScheduleRadioButton = "Day";
			
			Items.ShowPanningInterval.Check = False;
			Items.ShowDay.Check = True;
			Items.ShowMonth.Check = False;
			Items.GroupIntervalSetting.Enabled = True;
			
			OutputScheduleByDays(TemplateResourcesPlanning, TemplateArea, StructureColors
			, ComapnyResourcesTable, WorkPeriods, ScheduleLoading);
			
		ElsIf WorksScheduleRadioButton = "Day" Then
			OutputScheduleByDays(TemplateResourcesPlanning, TemplateArea, StructureColors
			, ComapnyResourcesTable, WorkPeriods, ScheduleLoading);
		ElsIf WorksScheduleRadioButton = "Month" Then
			OutputScheduleByMonth(TemplateResourcesPlanning, TemplateArea, StructureColors
			, ComapnyResourcesTable, WorkPeriods, ScheduleLoading);
		EndIf;
		
	EndIf;
	
	Items.PeriodPresentation.Enabled = ?(ListPeriodDates.Count()=1, False, True);
	Items.PeriodPresentation.Visible = Not WorksScheduleRadioButton = "Month";
	
	If FormOpening Then
		Items.ResourcesImport.CurrentArea = ResourcesImport.Area("R7C5");
	EndIf;
	
	PeriodPresentation = ?(ListPeriodDates.Count()=1, ListPeriodDates[0].Value,PeriodPresentation);
	
EndProcedure

&AtServer
Procedure OutputScheduleByMonth(TemplateResourcesPlanning, AreaTemplateHeader, StructureColors
	, ComapnyResourcesTable, WorkPeriods, ScheduleLoading)
	
	ResourcesImport.FixedLeft = 0;
	ResourcesImport.FixedTop = 0;
	
	If Not ListPeriodDates.Count() Then ListPeriodDates.Add(CalendarDate) EndIf;
	
	IntervalMatrix = ResourcePlanningCM.CreateIntervalColumns();
	
	Items.PositioningPeriod.Visible = False;
	
	SolidLine = New Line(SpreadsheetDocumentCellLineType.Solid);
	
	ScheduleLoadingYear = ScheduleLoading.Copy();
	ScheduleLoadingYear.GroupBy("EnterpriseResource, Month, Year", "Loading");
	
	RowsInAreaQuantity = MaxQuantityUsingResourcesPerPeriodUnity(ComapnyResourcesTable.UnloadColumn("Resource"));
	
	TVYearsPeriod = PeriodTableYearMonth();
	TVMonthsPeriod = PeriodTableYearMonth(True);
	
	StructureDetailsPeriod = New Structure;
	
	StructureDetailsPeriod.Insert("BalanceOnLoading", 0);
	StructureDetailsPeriod.Insert("ItWorkPeriod", False);
	
	YearOutputed = False;
	
	For Each YearString In TVYearsPeriod Do
		
		TemplateArea = TemplateResourcesPlanning.GetArea("YearOutput|MonthTitle");
		TemplateArea.Parameters.Year = Format(YearString.Year,"NG=");
		TemplateArea.Parameters.DetailsYear = YearString.Year;
		ResourcesImport.Put(TemplateArea);
		
		FilterParameters = New Structure("Year", YearString.Year);
		
		FoundRowsMonths = TVMonthsPeriod.FindRows(FilterParameters);
		
		MonthNumber = 1;
		
		TemplateArea = TemplateResourcesPlanning.GetArea("YearOutput|MonthTitle");
		
		LengthStringColoring = ?(FoundRowsMonths.Count()>3, 2, FoundRowsMonths.Count()-1);
		
		For Each PeriodString In FoundRowsMonths Do
			
			AreaTemplateMonth = TemplateResourcesPlanning.GetArea("Month|MonthTitle");
			AreaTemplateMonth.Parameters.Month = MonthByNumber(PeriodString.Month);
			AreaTemplateMonth.Parameters.MonthYear = Date(YearString.Year,PeriodString.Month,1,0,0,0);
			
			RowIndexInArea = 0;
			RowIndex = 3;
			
			For Each EnterpriseResource In ComapnyResourcesTable Do
				
				Resource = EnterpriseResource.Resource;
				
				FilterParameters = New Structure("EnterpriseResource, Year, Month", Resource, YearString.Year, PeriodString.Month);
				FoundRowsResources = ScheduleLoadingYear.FindRows(FilterParameters);
				
				SummaryLoadingPerMonth = ResourceLoadingForMonth(WorkPeriods, Resource, PeriodString.Year, PeriodString.Month);
				
				AreaTemplateResources = AreaTemplateMonth.Area(RowIndex,1,RowIndex,1);
				
				AreaTemplateResources.Text = String(Resource)+"
				|"+NStr("en='Step plan.: ';vi='Bước lập kế hoạch.: ';") + DetailsMultiplicity(EnterpriseResource)+". "+NStr("en='Capacity:';vi='Năng suất:'")+String(EnterpriseResource.Capacity);
				AreaTemplateResources.Details = Resource;
				
				AreaTemplateResources.RightBorder = SolidLine;
				AreaTemplateResources.LeftBorder = SolidLine;
				AreaTemplateResources.BottomBorder = SolidLine;
				AreaTemplateResources.TopBorder = SolidLine;
				AreaTemplateResources.BorderColor = WebColors.White;
				AreaTemplateResources.BackColor = WebColors.Lavender;
				AreaTemplateResources.TextPlacement = SpreadsheetDocumentTextPlacementType.Wrap;
				
				DetailsStructure = New Structure("Resource, Year, Month, DetailsKind",Resource, PeriodString.Year, PeriodString.Month, "ByDays");
				
				ResourceImport = 0;
				
				MultiplicityPlanning = EnterpriseResource.MultiplicityPlanning;
				
				For PeriodDay = 1 To PeriodString.DaysNumber Do
					
					PeriodDate = Date(YearString.Year, PeriodString.Month, PeriodDay, 0, 0, 0);
					
					FilterParameters = New Structure("EnterpriseResource, Period",Resource,PeriodDate);
					FoundStrings = ScheduleLoading.FindRows(FilterParameters);
					
					DetailsDocuments = ResourcePlanningCM.DocumentTablePerPeriod(FoundStrings, PeriodDate, PeriodDate, MultiplicityPlanning, True);
					
					StructureTotalsPerDay = ResourcePlanningCM.TotalsByDay(PeriodDate, MultiplicityPlanning, WorkPeriods
					,Resource, ScheduleLoading, DetailsDocuments, IntervalMatrix, FoundStrings);
					
					ResourceImport = ResourceImport + StructureTotalsPerDay.Loading;
					
				EndDo;
				
				AreaTemplateResourcesParametersLoading = AreaTemplateMonth.Area(RowIndex,2,RowIndex,2);
				
				AreaTemplateResourcesParametersLoading.RightBorder = SolidLine;
				AreaTemplateResourcesParametersLoading.LeftBorder = SolidLine;
				AreaTemplateResourcesParametersLoading.BottomBorder = SolidLine;
				AreaTemplateResourcesParametersLoading.TopBorder = SolidLine;
				AreaTemplateResourcesParametersLoading.BorderColor = StyleColors.WorktimeFreeAvailable;
				AreaTemplateResourcesParametersLoading.Details = DetailsStructure;
				
				UpdateRepresentationAreaAccordingLoading(AreaTemplateResourcesParametersLoading, ResourceImport, SummaryLoadingPerMonth,,True);
				
				AreaTemplateResourcesParametersLoading.Text = String(ResourceImport);
				
				AreaTemplateResourceParametersPower = AreaTemplateMonth.Area(RowIndex,3,RowIndex,3);
				
				AreaTemplateResourceParametersPower.RightBorder = SolidLine;
				AreaTemplateResourceParametersPower.LeftBorder = SolidLine;
				AreaTemplateResourceParametersPower.BottomBorder = SolidLine;
				AreaTemplateResourceParametersPower.TopBorder = SolidLine;
				AreaTemplateResourceParametersPower.BorderColor = StyleColors.WorktimeFreeAvailable;
				AreaTemplateResourceParametersPower.Details = DetailsStructure;
				
				UpdateRepresentationAreaAccordingLoading(AreaTemplateResourceParametersPower, ResourceImport, SummaryLoadingPerMonth,,True);
				
				AreaTemplateResourceParametersPower.Text =  String(SummaryLoadingPerMonth);
				
				RowIndexInArea = RowIndexInArea + 1;
				RowIndex = RowIndex +1;
				
			EndDo;
			
			While RowIndexInArea < RowsInAreaQuantity Do
				
				AreaTemplateResources = AreaTemplateMonth.Area(RowIndex,1,RowIndex,1);
				
				AreaTemplateResources.RightBorder = SolidLine;
				AreaTemplateResources.LeftBorder = SolidLine;
				AreaTemplateResources.BottomBorder = SolidLine;
				AreaTemplateResources.TopBorder = SolidLine;
				AreaTemplateResources.BorderColor = WebColors.White;
				
				AreaTemplateResourceParameters = AreaTemplateMonth.Area(RowIndex,2,RowIndex,2);
				
				AreaTemplateResourceParameters.RightBorder = SolidLine;
				AreaTemplateResourceParameters.LeftBorder = SolidLine;
				AreaTemplateResourceParameters.BottomBorder = SolidLine;
				AreaTemplateResourceParameters.TopBorder = SolidLine;
				AreaTemplateResourceParameters.BorderColor = WebColors.White;
				AreaTemplateResourceParameters.BackColor = StyleColors.WorktimeFreeAvailable;
				
				AreaTemplateResources.BackColor = WebColors.Lavender;
				
				RowIndexInArea = RowIndexInArea + 1;
				RowIndex = RowIndex +1;
				
			EndDo;
			
			If MonthNumber = 1 Or MonthNumber%3 = 1 Then
				ResourcesImport.Put(AreaTemplateMonth);
			Else
				ResourcesImport.Join(AreaTemplateMonth);
			EndIf;
			
			MonthNumber = MonthNumber + 1;
			
		EndDo;
		
	EndDo;
	
	Items.ResourcesImport.CurrentArea = ResourcesImport.Area("R1C1");
	
EndProcedure

&AtServer
Procedure OutputScheduleByDays(TemplateResourcesPlanning, AreaTemplateHeader, StructureColors
	, ComapnyResourcesTable, WorkPeriods, ScheduleLoading)
	
	Items.PositioningPeriod.Visible = False;
	ListDatesForCreateGraphForDays.Clear();
	
	SolidLine = New Line(SpreadsheetDocumentCellLineType.Solid);
	WhiteColor = WebColors.White;
	
	IntervalMatrix = ResourcePlanningCM.CreateIntervalColumns();
	
	If Not ListPeriodDates.Count() Then ListPeriodDates.Add(CalendarDate) EndIf;
	
	ListDatesForCreateGraphForDays.LoadValues(ListPeriodDates.UnloadValues());
	
	If OnlyWorkTime Then
		
		For Each ListElement In ListPeriodDates Do
			
			If Not ItWorkInterval(ListElement.Value, WorkPeriods,,, True) Then
				
				FoundedListItem = ListDatesForCreateGraphForDays.FindByValue(ListElement.Value);
				ListDatesForCreateGraphForDays.Delete(FoundedListItem);
				
			EndIf;
			
		EndDo;
		
		If Not ListDatesForCreateGraphForDays.Count() Then
			
			TemplateArea = TemplateResourcesPlanning.GetArea("SplashWithoutResources|Text");
			
			DetailsStructure = New Structure("DetailsKind", "CreateNewResourrce");
			TemplateArea.Parameters.Details = DetailsStructure;
			
			TextEmptySpreadSheetDocument = NStr("en='Ресурсы предприятия с графиком работы в выбранный период отсутствуют.';ru='Ресурсы предприятия с графиком работы в выбранный период отсутствуют.';vi='Tài nguyên doanh nghiệp với một lịch trình làm việc trong khoảng thời gian đã chọn là không có sẵn.'");
			TemplateArea.Parameters.TextOfMessage = TextEmptySpreadSheetDocument;
			ResourcesImport.Put(TemplateArea);
			
			Return 
		EndIf;
		
	EndIf;
	
	PeriodsQuantity = ListDatesForCreateGraphForDays.Count();
	
	For Each ListElement In ListPeriodDates Do
		Items.PeriodPresentation.ChoiceList.Add(ListElement.Value, Format(ListElement.Value,"DF=dd.MM.yyyy"));
	EndDo;
	
	PeriodPresentation = ListDatesForCreateGraphForDays[0].Value;
	
	If PeriodsQuantity = 0 Then Return EndIf;
	
	UnitedCellsQuantity = 0;
	
	TVYearsPeriod = PeriodTableYearMonth(, ListDatesForCreateGraphForDays);
	
	For Each YearString In TVYearsPeriod Do
		
		DaysNumber = YearString.DaysNumber;
		
		UnionArea = AreaTemplateHeader.Area(1,5+?(UnitedCellsQuantity=0,0, UnitedCellsQuantity),1,UnitedCellsQuantity+DaysNumber+4);
		
		UnionArea.Text = String(YearString.Year);
		UnionArea.RightBorder = SolidLine;
		UnionArea.BottomBorder = SolidLine;
		
		UnionArea.Merge();
		
		UnitedCellsQuantity = UnitedCellsQuantity + DaysNumber;
		
	EndDo;
	
	ResourcesImport.Put(AreaTemplateHeader);
	
	TemplateArea = TemplateResourcesPlanning.GetArea("TimePresentation|Title");
	ResourcesImport.Put(TemplateArea);
	
	CoordinateIndex = 5;
	
	DesriptionWeekDayByNumber = AccordanceDaysOfWeek();
	TextColorStep = WebColors.LightSalmon;
	GreyTextColor = WebColors.Gray;
	
	For Each ListDay In ListDatesForCreateGraphForDays Do
		
		WeekDayNumber = WeekDay(ListDay.Value);
		
		TemplateArea = TemplateResourcesPlanning.GetArea("TimePresentation|PeriodUnitDay");
		TemplateArea.Parameters.Interval = Format(ListDay.Value,"DF=dd.MM")+ " " + DesriptionWeekDayByNumber.Get(WeekDayNumber);
		TemplateArea.Parameters.Date = ListDay.Value;
		
		TemplateArea.Area(3,1,3,1).LeftBorder = New Line(SpreadsheetDocumentCellLineType.Solid);
		
		If ListDay.Value = ListDatesForCreateGraphForDays[ListDatesForCreateGraphForDays.Count()-1].Value Then
			TemplateArea.Area(3,1,3,1).RightBorder = New Line(SpreadsheetDocumentCellLineType.Solid);
		EndIf;
		
		If Day(ListDay.Value) = 1 Then
			TemplateArea.Area(3,1,2,1).LeftBorder = New Line(SpreadsheetDocumentCellLineType.Solid);
			TemplateArea.Area(3,1,1,1).BorderColor = TextColorStep;
		Else
			TemplateArea.Area(3,1,1,1).BorderColor = GreyTextColor;
		EndIf;
		
		If WeekDayNumber = 6 Or WeekDayNumber = 7 Then
			TemplateArea.Area(3,1,1,1).TextColor = TextColorStep;
		EndIf;
		
		ResourcesImport.Join(TemplateArea);
		
		NewRow = DaysCoordinates.Add();
		NewRow.CoordinateBegin = CoordinateIndex;
		NewRow.CoordinateEnd = CoordinateIndex;
		NewRow.Date = ListDay.Value;
		
		CoordinateIndex = CoordinateIndex + 1;
		
	EndDo;
	
	TemplateArea = TemplateResourcesPlanning.GetArea("Separator|Title");
	ResourcesImport.Put(TemplateArea);
	
	LineNumber = 7;
	GroupNumber = 1;
	
	For Each EnterpriseResource In ComapnyResourcesTable Do
		
		MultiplicityPlanning = ?(EnterpriseResource.MultiplicityPlanning = 0, 5, EnterpriseResource.MultiplicityPlanning);
		
		AreaResource = TemplateResourcesPlanning.GetArea("Resources|Title");
		
		AreaDetailsResource = AreaResource.Area(2,1,2,1);
		AreaDetailsResource.Parameter = EnterpriseResource.Resource;
		
		StructureDetailsResource = New Structure;
		
		StructureDetailsResource.Insert("Resource", EnterpriseResource.Resource);
		StructureDetailsResource.Insert("ControlLoadingOnlyInWorkTime", EnterpriseResource.Resource.ControlLoadingOnlyInWorkTime);
		
		AreaDetailsResource.Details = StructureDetailsResource;
		
		AreaDetailsResourcePlanningStep = AreaResource.Area(3,1,3,1);
		AreaDetailsResourcePlanningStep.Parameter = NStr("en='Step plan.: ';vi='Bước lập kế hoạch.: '") +DetailsMultiplicity(EnterpriseResource)+". "+NStr("en='Capacity:';vi='Năng suất:'")+String(EnterpriseResource.Capacity);
		
		AreaDetailsByDocuments = TemplateResourcesPlanning.GetArea("DetailsByDocuments|Title");
		
		DocumentDetailsRowNumber = 1;
		IsDetails = False;
		
		MultiplicityInterval = PeriodsQuantity;
		
		Interval = 1;
		PeriodQuantityIndex = 1;
		DetailsRowNumber = 1;
		LoadingForPeriod = 0;
		AvailableLoadingValue = 0;
		
		For Each ListDay In ListDatesForCreateGraphForDays Do
			
			FilterParameters = New Structure("EnterpriseResource, Period",EnterpriseResource.Resource, BegOfDay(ListDay.Value));
			FoundStrings = ScheduleLoading.FindRows(FilterParameters);
			
			AvailableResorceDayLoading = 0;
			
			AreaOutputInterval = Interval;
			
			Resource = EnterpriseResource.Resource;
			
			UnionArea = AreaResource.Area(2,4+AreaOutputInterval,3,4+AreaOutputInterval);
			UnionArea.BackColor = StructureColors.AvailableResourceCellColor;
			
			OutputPeriodDelimiters(UnionArea,SolidLine,WhiteColor);
			
			DetailsDocuments = ResourcePlanningCM.DocumentTablePerPeriod(FoundStrings, ListDay.Value, ListDay.Value, MultiplicityInterval, True);
			
			StructureTotalsPerDay = ResourcePlanningCM.TotalsByDay(ListDay.Value, MultiplicityPlanning, WorkPeriods
			,Resource, ScheduleLoading, DetailsDocuments, IntervalMatrix, FoundStrings);
			
			ResourceImport = StructureTotalsPerDay.Loading;
			
			AvailableResorceDayLoading = RecourceLoadingOnDate(WorkPeriods, Resource, ListDay.Value);
			Interval = Interval + 1;
			
			ItWorkPeriod = ?(AvailableResorceDayLoading = 0, False, True);
			
			LoadingForPeriod = LoadingForPeriod + ResourceImport;
			
			BalanceOnLoading = AvailableResorceDayLoading - LoadingForPeriod;
			
			DetailsStructure = New Structure("Resource, Day, DetailsKind, BalanceOnLoading"
			, Resource, ListDay.Value, "MultipleInterval", BalanceOnLoading);
			UnionArea.Details = DetailsStructure;
			
			UnionArea.Merge();
			
			UpdateRepresentationAreaAccordingLoading(UnionArea, ResourceImport, AvailableResorceDayLoading,,
			,StructureTotalsPerDay.IsExcess,,StructureTotalsPerDay,ItWorkPeriod);
			
			AvailableLoadingValue = AvailableLoadingValue + AvailableResorceDayLoading;
			
		EndDo;
		
		FontTotal6 = New Font(,6,,,,);
		
		FontTotal8 = New Font(,8,,,,);
		
		AreaTotals1 = AreaResource.Area(2,2,2,2);
		AreaTotals1.Outline(SolidLine);
		AreaTotals1.BorderColor = WebColors.White;
		AreaTotals1.BackColor = ?(LoadingForPeriod = 0 And Not AvailableLoadingValue = 0,StructureColors.AvailableResourceCellColor, AreaTotals1.BackColor);
		
		UpdateRepresentationAreaAccordingLoading(AreaTotals1, LoadingForPeriod, AvailableLoadingValue,,True);
		
		AreaTotals1.Text = String(LoadingForPeriod);
		
		AreaTotals1.Font = ?(LoadingForPeriod>=1000, FontTotal6, FontTotal8);
		
		
		AreaTotals2 = AreaResource.Area(2,3,2,3);
		AreaTotals2.Outline(SolidLine);
		AreaTotals2.BorderColor = WebColors.White;
		AreaTotals2.BackColor = ?(LoadingForPeriod = 0 And Not AvailableLoadingValue = 0,StructureColors.AvailableResourceCellColor, AreaTotals2.BackColor);
		
		UpdateRepresentationAreaAccordingLoading(AreaTotals2, LoadingForPeriod, AvailableLoadingValue,,True);
		
		AreaTotals2.Text = String(AvailableLoadingValue);
		
		AreaTotals2.Font = ?(AvailableLoadingValue>=1000, FontTotal6, FontTotal8);
		
		
		If IsDetails Then
			ResourcesImport.StartRowAutoGrouping();
			
			ResourcesImport.Put(AreaResource,GroupNumber,"Details on documents"+String(Resource), False);
			ResourcesImport.Put(AreaDetailsByDocuments,GroupNumber+1,"Details"+String(Resource), False);
			
			ResourcesImport.EndRowAutoGrouping();
		Else
			ResourcesImport.Put(AreaResource,GroupNumber,"Details on documents"+String(Resource), False);
		EndIf;
		
		LineNumber = LineNumber + 2;
		GroupNumber = GroupNumber + 1;
		
	EndDo;
	
	AreaAddResources = TemplateResourcesPlanning.GetArea("AddResource|Title"); 
	DetailsStructure = New Structure("DetailsKind", "CreateNewResourrce");
	AreaAddResources.Parameters.Details = DetailsStructure;
	ResourcesImport.Put(AreaAddResources)
	
EndProcedure

&AtServer
Procedure OutputScheduleMultiplicityInterval(TemplateResourcesPlanning, AreaTemplateHeader, StructureColors
	, ComapnyResourcesTable, WorkPeriods, ScheduleLoading, MinIntervalResource)
	
	PositioningTableByDays.Clear();
	PeriodByDays.Clear();
	
	Items.PositioningPeriod.Visible = True;
	
	CreateChoiceListPeriodsTime();
	
	UnitedCellsQuantity = 0;
	DurationIntervalSec = MinInterval*60;
	
	AddMoveColumnForOutputAddInfo = 2;
	
	NotWorkingDays = New ValueList;
	
	DesriptionWeekDayByNumber = AccordanceDaysOfWeek();
	
	TextColorStep = WebColors.LightSalmon;
	GreyTextColor = WebColors.DarkSlateGray;
	WhiteColor = WebColors.White;
	
	SolidLine = New Line(SpreadsheetDocumentCellLineType.Solid);
	None = New Line(SpreadsheetDocumentCellLineType.None);
	
	IntervalMatrix = ResourcePlanningCM.CreateIntervalColumns();
	
	For Each ListDay In ListPeriodDates Do
		
		If OnlyWorkTime Then
			StructureInterval = WorkPeriodBoarders(ListDay.Value, WorkPeriods, ScheduleLoading);
			
			If Not ValueIsFilled(StructureInterval.BeginTime) Then
				NotWorkingDays.Add(ListDay.Value);
				Continue;
			EndIf;
			
			IntervalBegin = StructureInterval.BeginTime;
			IntervalEnd = ?(StructureInterval.EndTime = EndOfDay(StructureInterval.EndTime),StructureInterval.EndTime+1, StructureInterval.EndTime);
			
			If Not ValueIsFilled(IntervalBegin) Then Continue EndIf;
			
			PeriodsQuantity = (IntervalEnd - IntervalBegin)/DurationIntervalSec;
			CellsForUnitteQuantity = PeriodsQuantity;
			
		Else
			If ValueIsFilled(BeginOfRepresentationInterval) Or ValueIsFilled(RepresentationIntervalEnd) Then
				IntervalEndPeriod = ?(ValueIsFilled(RepresentationIntervalEnd), RepresentationIntervalEnd+300, EndOfDay(BeginOfRepresentationInterval));
				IntervalEndPeriod = ?(IntervalEndPeriod = EndOfDay(IntervalEndPeriod),IntervalEndPeriod+1, IntervalEndPeriod);
				PeriodsQuantity = (IntervalEndPeriod - BeginOfRepresentationInterval)/(DurationIntervalSec);
			Else
				PeriodsQuantity = 1440/MinInterval;
			EndIf;
			
			IntervalBegin = BegOfDay(ListDay.Value)+(BeginOfRepresentationInterval-Date(1,1,1));
			IntervalEnd = BegOfDay(ListDay.Value)+(RepresentationIntervalEnd-Date(1,1,1));
			
		EndIf;
		
		Items.PeriodPresentation.ChoiceList.Add(ListDay.Value,Format(ListDay.Value,"DF=dd.MM.yyyy"));
		
		NewRowPeriodsByDays = PeriodByDays.Add();
		NewRowPeriodsByDays.Date = ListDay.Value;
		NewRowPeriodsByDays.PeriodsQuantity = PeriodsQuantity;
		NewRowPeriodsByDays.BeginTime = IntervalBegin;
		NewRowPeriodsByDays.EndTime = IntervalEnd;
		
		If ListPeriodDates.Count() = 1 Then
			BeginOfRepresentationInterval = IntervalBegin;
			RepresentationIntervalEnd = IntervalEnd;
		EndIf;
		
		CreateChoiseListTimeMoveByCoordinate(PeriodsQuantity, NewRowPeriodsByDays, IntervalBegin);
		
		CellsForUnitteQuantity =PeriodsQuantity;
		
		ColumnBegin = 3+?(UnitedCellsQuantity=0,0, UnitedCellsQuantity)+AddMoveColumnForOutputAddInfo;
		ColumnEnd = UnitedCellsQuantity+CellsForUnitteQuantity+2+AddMoveColumnForOutputAddInfo;
		
		UnionArea = AreaTemplateHeader.Area(1,ColumnBegin,1,ColumnEnd);
		
		WeekDayNumber = WeekDay(ListDay.Value);
		
		UnionArea.Text = Format(ListDay.Value,"DF=dd.MM.yyyy")+" "+ DesriptionWeekDayByNumber.Get(WeekDayNumber);
		UnionArea.RightBorder = SolidLine;
		UnionArea.LeftBorder = SolidLine;
		UnionArea.BottomBorder = SolidLine;
		UnionArea.Details = ListDay.Value;
		
		If WeekDayNumber = 6 Or WeekDayNumber = 7 Then
			UnionArea.TextColor = TextColorStep;
		Else
			UnionArea.TextColor = GreyTextColor;
		EndIf;
		
		UnionArea.Merge();
		
		NewRow = DaysCoordinates.Add();
		NewRow.CoordinateBegin = UnionArea.Left;
		NewRow.CoordinateEnd = UnionArea.Right;
		NewRow.Date = ListDay.Value;
		
		UnitedCellsQuantity = UnitedCellsQuantity + CellsForUnitteQuantity;
		
	EndDo;
	
	If OnlyWorkTime Then
		ProcessedDateList = DeleteNotWorkingDaysFromList(NotWorkingDays);
		
		If Not ProcessedDateList.Count() Then
			
			TemplateArea = TemplateResourcesPlanning.GetArea("SplashWithoutResources|Text");
			
			DetailsStructure = New Structure("DetailsKind", "CreateNewResourrce");
			TemplateArea.Parameters.Details = DetailsStructure;
			
			TextEmptySpreadSheetDocument = NStr("en='Ресурсы предприятия с графиком работы в выбранный период отсутствуют.';ru='Ресурсы предприятия с графиком работы в выбранный период отсутствуют.';vi='Tài nguyên doanh nghiệp với một lịch trình làm việc trong khoảng thời gian đã chọn là không có sẵn.'");
			TemplateArea.Parameters.TextOfMessage = TextEmptySpreadSheetDocument;
			ResourcesImport.Put(TemplateArea);
			Return
		EndIf;
		
	Else
		ProcessedDateList = ListPeriodDates;
	EndIf;
	
	PeriodPresentation = ProcessedDateList[0].Value;
	
	ResourcesImport.Put(AreaTemplateHeader);
	
	TemplateArea = TemplateResourcesPlanning.GetArea("TimePresentation|Title");
	ResourcesImport.Put(TemplateArea);
	
	PeriodsQuantityTotal = 0;
	
	For Each ListDay In ProcessedDateList Do
		
		FilterParameters = New Structure("Date",ListDay.Value);
		FoundStrings = PeriodByDays.FindRows(FilterParameters);
		
		IntervalBegin = FoundStrings[0].BeginTime;
		IntervalEnd = FoundStrings[0].EndTime;
		PeriodsQuantity = FoundStrings[0].PeriodsQuantity;
		
		OutputInterval = IntervalBegin;
		
		FilterParameters = New Structure("EnterpriseResource, Period", MinIntervalResource,BegOfDay(IntervalBegin));
		RowGraphs = WorkPeriods.FindRows(FilterParameters);
		
		If RowGraphs.Count() And Not ValueIsFilled(IntervalStepMin) Then
			
			TimeBeginOutputStepInGraphScale = RowGraphs[0].BeginWorkPeriodInDay;
			
			If Not ValueIsFilled(TimeBeginOutputStepInGraphScale) Then
				MoveTimeOutputScale = 0;
				MinPlanningStep = ?(Not ValueIsFilled(IntervalStepMin), MinPlanningStep, IntervalStepMin*60);
			Else
				
				MinPlanningStepMin = MinPlanningStep/60;
				
				TimeBeginOutputStepInGraphSeconds = TimeBeginOutputStepInGraphScale-BegOfDay(TimeBeginOutputStepInGraphScale);
				PositionStartStepScaleOutput = TimeBeginOutputStepInGraphSeconds/300;
				
				RemainderOfDivision = PositionStartStepScaleOutput%(MinPlanningStepMin);
				
				MoveTimeOutputScale = ?(RemainderOfDivision = 0, 0,(MinPlanningStepMin - RemainderOfDivision)*300);
				
			EndIf;
			
		Else
			
			MoveTimeOutputScale = 0;
			MinPlanningStep = ?(Not ValueIsFilled(IntervalStepMin), MinPlanningStep, IntervalStepMin*60);
			
		EndIf;
		
		MinPlanningStep = ?(MinPlanningStep <900, 900,MinPlanningStep);
		
		AreaTemplateInterval = TemplateResourcesPlanning.GetArea("TimePresentation|PeriodUnit");
		AreaTemplateInterval.Area(3,1,2,1).LeftBorder = SolidLine;
		AreaTemplateInterval.Area(3,1,1,1).BorderColor = TextColorStep;
		AreaTemplateInterval.Area(3,1,3,1).BottomBorder = SolidLine;
		
		AreaTemplateScaleDelimiter = TemplateResourcesPlanning.GetArea("TimePresentation|DelimiterScale");
		AreaTemplateScaleDelimiter.Area(3,1,3,1).LeftBorder = SolidLine;
		AreaTemplateScaleDelimiter.Area(3,1,1,1).BorderColor = WebColors.Gray;
		AreaTemplateScaleDelimiter.Area(3,1,3,1).BottomBorder = SolidLine;
		
		For Interval = 1 To PeriodsQuantity Do
			
			If (OutputInterval - BegOfDay(OutputInterval)+MoveTimeOutputScale)% MinPlanningStep = 0 Then
				
				If Interval = PeriodsQuantity Then
					AreaTemplateInterval.Area(3,1,3,1).BottomBorder = None;
				EndIf;
				
				AreaTemplateInterval.Parameters.Interval = Format(OutputInterval,"DF=HH:mm");
				
				OutputTime = ?(Interval = 1, OutputInterval, OutputInterval-300);
				
				AreaTemplateInterval.Parameters.Time = OutputTime;
			
				ResourcesImport.Join(AreaTemplateInterval);
			Else
				
				AreaTemplateScaleDelimiter.Parameters.Time = OutputInterval-300;
				
				ResourcesImport.Join(AreaTemplateScaleDelimiter);
			EndIf;
			
			OutputInterval = OutputInterval + DurationIntervalSec
		EndDo;
		
		PeriodsQuantityTotal = PeriodsQuantityTotal + PeriodsQuantity;
		
	EndDo;
	
	AreaTemplateScaleDelimiter.Parameters.Time = OutputInterval-300;
	AreaTemplateScaleDelimiter.Area(3,1,3,1).BottomBorder = None;
	ResourcesImport.Join(AreaTemplateScaleDelimiter);
	
	TemplateArea = TemplateResourcesPlanning.GetArea("Separator|Title");
	ResourcesImport.Put(TemplateArea);
	
	TemplateArea = TemplateResourcesPlanning.GetArea("Separator|PeriodUnit");
	For Interval = 1 To PeriodsQuantityTotal Do
		ResourcesImport.Join(TemplateArea);
	EndDo;
	
	LineNumber = 7;
	GroupNumber = 1;
	
	For Each EnterpriseResource In ComapnyResourcesTable Do
		
		Resource = EnterpriseResource.Resource;
		
		NewRow = ResourcesByRows.Add();
		NewRow.Resource = Resource;
		NewRow.LineNumber = LineNumber;
		
		AddColumnMove = AddMoveColumnForOutputAddInfo;
		
		AreaResource = TemplateResourcesPlanning.GetArea("Resources|Title");
		
		AreaDetailsResource = AreaResource.Area(2,1,2,1);
		AreaDetailsResource.Parameter = Resource;
		
		StructureDetailsResource = New Structure;
		
		StructureDetailsResource.Insert("Resource", Resource);
		StructureDetailsResource.Insert("ControlLoadingOnlyInWorkTime", Resource.ControlLoadingOnlyInWorkTime);
		
		AreaDetailsResource.Details = StructureDetailsResource;
		
		AreaDetailsResource.TextPlacement = SpreadsheetDocumentTextPlacementType.Wrap;
		
		AreaDetailsResourcePlanningStep = AreaResource.Area(3,1,3,1);
		AreaDetailsResourcePlanningStep.Parameter = NStr("en='Step plan.: ';vi='Bước lập kế hoạch.: '") + DetailsMultiplicity(EnterpriseResource) + ". "+NStr("en='Capacity:';vi='Năng suất:'")+String(EnterpriseResource.Capacity);
		
		FilterParameters = New Structure("EnterpriseResource",Resource);
		FoundStrings = ScheduleLoading.FindRows(FilterParameters);
		
		AreaDetailsByDocuments = TemplateResourcesPlanning.GetArea("DetailsByDocuments|Title");
		
		MultiplicityPlanningResource = EnterpriseResource.MultiplicityPlanning*60;
		
		DocumentDetailsRowNumber = 1;
		IsDetails = False;
		LoadingForPeriod = 0;
		
		MapDetailsDocumentsRows = New ValueTable;
		
		MapDetailsDocumentsRows.Columns.Add("Ref");
		MapDetailsDocumentsRows.Columns.Add("DocumentLineNumber");
		MapDetailsDocumentsRows.Columns.Add("RowForOutputNumber");
		
		IntervalsOutputByDocuments = New ValueTable;
		IntervalsOutputByDocuments.Columns.Add("Document");
		IntervalsOutputByDocuments.Columns.Add("IntervalBegin");
		IntervalsOutputByDocuments.Columns.Add("IntervalEnd");
		IntervalsOutputByDocuments.Columns.Add("CellsQuantity");
		IntervalsOutputByDocuments.Columns.Add("UnitedCellsQuantity");
		IntervalsOutputByDocuments.Columns.Add("PreviousLoading");
		IntervalsOutputByDocuments.Columns.Add("DetailsRowNumber");
		IntervalsOutputByDocuments.Columns.Add("PreviousLoadingIntervalEnd");
		
		ArrayDocumentsWithCrossing = ArrayDocumentsWithCrossingForAllPeriod(FoundStrings, ScheduleLoading);
		
		FilterParameters = New Structure;
		
		RowFilterParameters = New Structure("DocumentLineNumber, Ref");

		
		For Each FoundString In FoundStrings Do
			
			If Not ValueIsFilled(FoundString.Ref) Then Continue EndIf;
			
			IsCrossings = ?(ArrayDocumentsWithCrossing.Find(FoundString.Ref) = Undefined, False, True);
			
			If Not IsCrossings Then
				
				FilterParameters.Insert("Ref", FoundString.Ref);
				
				FoundValueMap = MapDetailsDocumentsRows.FindRows(FilterParameters);
				
				If FoundValueMap.Count() Then
					Continue
				EndIf;
			EndIf;
			
			RowFilterParameters.DocumentLineNumber = FoundString.LineNumber;
			RowFilterParameters.Ref = FoundString.Ref;
			
			AddedStrings = MapDetailsDocumentsRows.FindRows(RowFilterParameters);
			
			If AddedStrings.Count() Then Continue EndIf;
			
			NewRow = MapDetailsDocumentsRows.Add();
			NewRow.Ref = FoundString.Ref;
			NewRow.RowForOutputNumber = DocumentDetailsRowNumber;
			NewRow.DocumentLineNumber = FoundString.LineNumber;
			
			DetailsArea = AreaDetailsByDocuments.Area(DocumentDetailsRowNumber,1,DocumentDetailsRowNumber,3);
			DetailsArea.Merge();
			DetailsArea.Parameter = FoundString.Ref;
			DetailsArea.TextPlacement = SpreadsheetDocumentTextPlacementType.Wrap;
			DocumentDetailsRowNumber = DocumentDetailsRowNumber +1;
			
			DetailsArea.BottomBorder = New Line(SpreadsheetDocumentCellLineType.ThinDashed);
			DetailsArea.BorderColor = WebColors.Gainsboro;
			
			DetailsStructure = New Structure("Resource, DocumentReference, DetailsKind, DocumentLineNumber"
			,Resource, FoundString.Ref, "PostionigOnDocument", FoundString.LineNumber);
			DetailsArea.Details = DetailsStructure;
			
			LineNumber = LineNumber + 1;
			
			CounterpartyAdding = "";
			
			If Find(String(FoundString.Ref), "<Object not found>" ) = 0 Then
				
				If TypeOf(FoundString.Ref) = Type("DocumentRef.Event")
					And FoundString.Ref.Participants.Count() Then
					
					For Each RowParticipants In FoundString.Ref.Participants Do
						If ValueIsFilled(RowParticipants.Contact) Then
							
							HowToContact = TrimAll(RowParticipants.HowToContact);
							CounterpartyAdding = String(RowParticipants.Contact) +?(ValueIsFilled(HowToContact)," (" + HowToContact+")","");
							Break;
							
						EndIf;
					EndDo;
				ElsIf TypeOf(FoundString.Ref) = Type("DocumentRef.CustomerOrder") Then
					
					CounterpartyAdding = String(FoundString.Counterparty);
					
					//If ValueIsFilled(FoundString.Counterparty.PhoneNumber) Then
					//	CounterpartyAdding = CounterpartyAdding +" (" + FoundString.Counterparty.PhoneNumber+")";
					//Else
						ContactsFilterParameters = New Structure("Type", Enums.ContactInformationTypes.Phone);
						FoundRowsContacts = FoundString.Counterparty.ContactInformation.FindRows(ContactsFilterParameters);
						
						For Each FoundedRowContacts In FoundRowsContacts Do
							If ValueIsFilled(FoundedRowContacts.Presentation) Then
								CounterpartyAdding = CounterpartyAdding +" (" + FoundedRowContacts.Presentation+")";
								Break
							EndIf;
						EndDo;
						
					//EndIf;
					
				Else
					CounterpartyAdding = String(FoundString.Counterparty);
				EndIf;
				
				If ValueIsFilled(CounterpartyAdding) Then
					DetailsArea.Text = TrimAll(CounterpartyAdding)+":
					|"+ DetailsArea.Text;
				EndIf;
				
			Else
				
				DetailsArea.Text = "<Document с restricted access>"
				
			EndIf;
			
			IsDetails = True;
			
		EndDo;
		
		MultiplicityPlanning = ?(Not ValueIsFilled(EnterpriseResource.MultiplicityPlanning), 5, EnterpriseResource.MultiplicityPlanning);
		MultiplicityInterval = MultiplicityPlanning;
		
		Interval = 1;
		
		DetailsRowNumber = 1;
		IntervalForExeption = 0;
		AvailableLoadingValue = 0;
		IsOverLoadingByMultiplicity = False;
		PeriodQuantityIndex = 0;
		
		For Each ListDay In ProcessedDateList Do
			
			FilterParameters = New Structure("Date",ListDay.Value);
			FoundRowsByDay = PeriodByDays.FindRows(FilterParameters);
			
			IntervalBegin = FoundRowsByDay[0].BeginTime;
			IntervalEnd = FoundRowsByDay[0].EndTime;
			PeriodsQuantity = FoundRowsByDay[0].PeriodsQuantity;
			
			OutputInterval = IntervalBegin;
			
			CellsForUnitteQuantity = 0;
			CellsForUniteDetailsQuantity = 0;
			CellsForUniteQuantityIntervalsEqualMultiplicity = 0;
			
			PeriodInListDayQuantity = PeriodsQuantity+PeriodQuantityIndex;
			PeriodQuantityIndex = PeriodInListDayQuantity;
			
			IntervalsOutputByDocuments.Clear();
			
			NotWorkingCellsForUniteQuantity = 0;
			
			WasNoWorkingPeriod = False;
			
			CurrentPeriodKind = "ByGraph";
			PreviousPeriodKind = CurrentPeriodKind;
			
			While Interval <= PeriodInListDayQuantity Do
				
				AreaOutputInterval = Interval - IntervalForExeption;
				
				workPeriod = ItWorkPeriod(WorkPeriods, OutputInterval, Resource,, ScheduleLoading, DurationIntervalSec, CurrentPeriodKind);
				
				OutputNotMultiplicityInterval = False;
				
				If Not CellsForUnitteQuantity = 0
					And Not PreviousPeriodKind = "Nonworking" And Not CurrentPeriodKind = "Nonworking"
					And Not PreviousPeriodKind = CurrentPeriodKind Then
					OutputNotMultiplicityInterval = True;
				EndIf;
				
				If workPeriod And OutputNotMultiplicityInterval = False Then
					If WasNoWorkingPeriod Then
						TemplateArea = AreaResource.Area(2,2+Interval+AddColumnMove-NotWorkingCellsForUniteQuantity,3,2+Interval-1+AddColumnMove);
						TemplateArea.BackColor = StructureColors.ResourceIsNotEditableCellColor;
						TemplateArea.Merge();
						OutputPeriodDelimiters(TemplateArea,SolidLine,WhiteColor);
					EndIf;
					
					WasNoWorkingPeriod = False;
					PreviousPeriodKind = CurrentPeriodKind;
					
					NotWorkingCellsForUniteQuantity = 0;
					
					MultiplicityInterval = MultiplicityInterval - MinInterval;
					CellsForUnitteQuantity = CellsForUnitteQuantity + 1;
					
					ResourceImport = 0;
					
					IntervalBegin = OutputInterval + DurationIntervalSec - CellsForUnitteQuantity*DurationIntervalSec;
					
					If CellsForUnitteQuantity > 1 
						And (MultiplicityInterval = 0 Or Interval = PeriodInListDayQuantity) Then
						
						UnionArea = AreaResource.Area(2,3+AreaOutputInterval- CellsForUnitteQuantity+AddColumnMove,3,2+AreaOutputInterval+AddColumnMove);
						UnionArea.BackColor = StructureColors.AvailableResourceCellColor;
						UnionArea.Merge();
						
						If CurrentPeriodKind = "ByGraph" Then
							AvailableLoadingValue = AvailableLoadingValue + EnterpriseResource.Capacity;
						EndIf;
						
						MultiplicityInterval = MultiplicityPlanning;
						
						OutputPeriodDelimiters(UnionArea,SolidLine,WhiteColor);
						
						IntervalEnding = OutputInterval+DurationIntervalSec;
						
						DetailsDocuments = ResourcePlanningCM.DocumentTablePerPeriod(FoundStrings, IntervalBegin, IntervalEnding, MultiplicityPlanning);
						
						OutputDetailsDocuments(DetailsDocuments,IntervalsOutputByDocuments, MapDetailsDocumentsRows
						,IntervalBegin, IntervalEnding, ArrayDocumentsWithCrossing, DetailsRowNumber, CellsForUnitteQuantity
						,AreaOutputInterval, Resource, AreaDetailsByDocuments, ResourceImport, IntervalMatrix);
						
						UpdateRepresentationAreaAccordingLoading(UnionArea, ResourceImport, EnterpriseResource.Capacity, IntervalBegin,,
						,CellsForUnitteQuantity,,True);
						
						IsOverLoadingByMultiplicity =?(ResourceImport>EnterpriseResource.Capacity, True, IsOverLoadingByMultiplicity);
						
						LoadingForPeriod = LoadingForPeriod + ResourceImport;
						
						CellsForUnitteQuantity = 0;
						
					ElsIf CellsForUnitteQuantity = 1 And (MultiplicityInterval = 0 Or Interval = PeriodInListDayQuantity) Then
						
						UnionArea = AreaResource.Area(2,2+AreaOutputInterval+AddColumnMove,3,2+AreaOutputInterval+AddColumnMove);
						UnionArea.BackColor = StructureColors.AvailableResourceCellColor;
						UnionArea.Merge();
						
						If MultiplicityPlanning = MinInterval Then
							UnionArea.ColumnWidth = 15;
						EndIf;
						
						If CurrentPeriodKind = "ByGraph" Then
							AvailableLoadingValue = AvailableLoadingValue + EnterpriseResource.Capacity;
						EndIf;
						
						OutputPeriodDelimiters(UnionArea,SolidLine,WhiteColor);
						
						DetailsDocuments = ResourcePlanningCM.DocumentTablePerPeriod(FoundStrings, OutputInterval, OutputInterval, MultiplicityPlanning);
						
						IntervalEnding = OutputInterval+DurationIntervalSec;
						
						OutputDetailsDocuments(DetailsDocuments,IntervalsOutputByDocuments,MapDetailsDocumentsRows
						,IntervalBegin, IntervalEnding, ArrayDocumentsWithCrossing, DetailsRowNumber
						,CellsForUnitteQuantity, AreaOutputInterval, Resource, AreaDetailsByDocuments, ResourceImport, IntervalMatrix);
						
						CellsForUnitteQuantity = 0;
						MultiplicityInterval = MultiplicityPlanning;
						
						UpdateRepresentationAreaAccordingLoading(UnionArea, ResourceImport, EnterpriseResource.Capacity
						, OutputInterval, CellsForUnitteQuantity,,,,True);
						
						IsOverLoadingByMultiplicity =?(ResourceImport>EnterpriseResource.Capacity, True, IsOverLoadingByMultiplicity);
						
						LoadingForPeriod = LoadingForPeriod + ResourceImport;
						
					EndIf;
					
					OutputInterval = OutputInterval + DurationIntervalSec;
					Interval = Interval + 1;
					Continue;
					
				EndIf;
				
				If CellsForUnitteQuantity >=1 Then
					
					UnionArea = AreaResource.Area(2,2+AreaOutputInterval- CellsForUnitteQuantity+AddColumnMove,3,1+AreaOutputInterval+AddColumnMove);
					UnionArea.BackColor = StructureColors.AvailableResourceCellColor;
					UnionArea.Merge();
					
					IntervalEnding = OutputInterval;
					
					PeriodLength = (IntervalEnding - IntervalBegin)/60;
					
					If PreviousPeriodKind = "ByGraph"
						Then
						AvailableLoadingValue = AvailableLoadingValue + EnterpriseResource.Capacity;
					EndIf;
					
					IsOverLoadingByMultiplicity =?(ResourceImport>EnterpriseResource.Capacity, True, IsOverLoadingByMultiplicity);
					
					OutputPeriodDelimiters(UnionArea,SolidLine,WhiteColor);
					
					IntervalBegin = OutputInterval - CellsForUnitteQuantity*DurationIntervalSec;
					
					DetailsDocuments = ResourcePlanningCM.DocumentTablePerPeriod(FoundStrings, IntervalBegin, IntervalEnding, MultiplicityPlanning);
					
					OutputDetailsDocuments(DetailsDocuments,IntervalsOutputByDocuments,MapDetailsDocumentsRows
					,IntervalBegin, IntervalEnding, ArrayDocumentsWithCrossing, DetailsRowNumber
					,CellsForUnitteQuantity, AreaOutputInterval-1, Resource, AreaDetailsByDocuments, ResourceImport, IntervalMatrix);
					
					PreviousPeriodKind = CurrentPeriodKind;
					
					UpdateRepresentationAreaAccordingLoading(UnionArea, ResourceImport, EnterpriseResource.Capacity, IntervalBegin,,
					,CellsForUnitteQuantity,,Not OutputNotMultiplicityInterval);
					
					
					IsOverLoadingByMultiplicity =?(ResourceImport>EnterpriseResource.Capacity, True, IsOverLoadingByMultiplicity);
					
					OutputInterval = OutputInterval + DurationIntervalSec;
					
					LoadingForPeriod = LoadingForPeriod + ResourceImport;
					
					If Not OutputNotMultiplicityInterval Then
						
						TemplateArea = AreaResource.Area(2,2+AreaOutputInterval+AddColumnMove-NotWorkingCellsForUniteQuantity,3,2+AreaOutputInterval+AddColumnMove);
						TemplateArea.BackColor = StructureColors.ResourceIsNotEditableCellColor;
						
						NotWorkingCellsForUniteQuantity = NotWorkingCellsForUniteQuantity + 1;
						TemplateArea.Merge();
						
						CellsForUnitteQuantity = 0;
						MultiplicityInterval = MultiplicityPlanning;
						
						OutputPeriodDelimiters(TemplateArea,SolidLine,WhiteColor);
						
					Else
						CellsForUnitteQuantity = 1;
						MultiplicityInterval = MultiplicityPlanning- MinInterval;
					EndIf;
					
					Interval = Interval + 1;
					
					PreviousPeriodKind = CurrentPeriodKind;
					
					Continue;
				EndIf;
				
				PreviousPeriodKind = CurrentPeriodKind;
				
				If Interval = PeriodInListDayQuantity Then
					TemplateArea = AreaResource.Area(2,2+Interval+AddColumnMove-NotWorkingCellsForUniteQuantity,3,2+Interval+AddColumnMove);
					TemplateArea.BackColor = StructureColors.ResourceIsNotEditableCellColor;
					
					TemplateArea.Merge();
					OutputPeriodDelimiters(TemplateArea,SolidLine,WhiteColor);
				EndIf;
				
				WasNoWorkingPeriod = True;
				
				NotWorkingCellsForUniteQuantity = NotWorkingCellsForUniteQuantity + 1;
				
				OutputInterval = OutputInterval + DurationIntervalSec;
				Interval = Interval + 1;
				
			EndDo;
			
		EndDo;
		
		AreaTotals1 = AreaResource.Area(2,2,2,2);
		AreaTotals1.Outline(SolidLine);
		AreaTotals1.BorderColor = WebColors.White;
		AreaTotals1.BackColor = ?(LoadingForPeriod = 0 And Not AvailableLoadingValue = 0,StructureColors.AvailableResourceCellColor, AreaTotals1.BackColor);
		
		UpdateRepresentationAreaAccordingLoading(AreaTotals1, LoadingForPeriod, AvailableLoadingValue,,True,IsOverLoadingByMultiplicity);
		
		AreaTotals1.Text = String(LoadingForPeriod);
		
		AreaTotals2 = AreaResource.Area(2,3,2,3);
		AreaTotals2.Outline(SolidLine);
		AreaTotals2.BorderColor = WebColors.White;
		AreaTotals2.BackColor = ?(LoadingForPeriod = 0 And Not AvailableLoadingValue = 0,StructureColors.AvailableResourceCellColor, AreaTotals2.BackColor);
		
		UpdateRepresentationAreaAccordingLoading(AreaTotals2, LoadingForPeriod, AvailableLoadingValue,,True, IsOverLoadingByMultiplicity);
		
		AreaTotals2.Text = String(AvailableLoadingValue);
		
		If IsDetails Then
			
			ResourcesImport.StartRowAutoGrouping();
			
			ResourcesImport.Put(AreaResource,GroupNumber,"Details on documents"+String(EnterpriseResource.Resource), False);
			ResourcesImport.Put(AreaDetailsByDocuments,GroupNumber+1,"Details"+String(EnterpriseResource.Resource), False);
			
			ResourcesImport.EndRowAutoGrouping();
		Else
			ResourcesImport.Put(AreaResource,GroupNumber,"Details on documents"+String(EnterpriseResource.Resource), False);
		EndIf;
		
		LineNumber = LineNumber + 3;
		GroupNumber = GroupNumber + 1;
		
	EndDo;
	
	AreaAddResources = TemplateResourcesPlanning.GetArea("AddResource|Title"); 
	DetailsStructure = New Structure("DetailsKind", "CreateNewResourrce");
	AreaAddResources.Parameters.Details = DetailsStructure;
	ResourcesImport.Put(AreaAddResources);
	
	UpdatePickupedPeriods(True);
	
EndProcedure

&AtServer
Procedure OutputDetailsDocuments(DetailsDocuments,IntervalsOutputByDocuments,MapDetailsDocumentsRows
	, IntervalBegin, IntervalEnding, ArrayDocumentsWithCrossing, DetailsRowNumber
	, CellsForUnitteQuantity, AreaOutputInterval, Resource, AreaDetailsByDocuments, ResourceImport, IntervalMatrix)
	
	SolidLine = New Line(SpreadsheetDocumentCellLineType.Solid);
	None = New Line(SpreadsheetDocumentCellLineType.None);
	
	IsCrossing = False;
	
	IntervalMatrix.Clear();
	
	RowOfDetails = DetailsRowNumber;
	
	DocumentsCount = DetailsDocuments.Count();
	AddingsRelaitedPeriod = 0;
	
	ResourceImport = ?(DocumentsCount, DetailsDocuments[0].Loading, ResourceImport); 
	
	FilterByRowsParameters = New Structure;
	
	For Each DetailDocument In DetailsDocuments Do
		
		EveryIntervalNewRow = ?(Not ArrayDocumentsWithCrossing.Find(DetailDocument.Ref) = Undefined, True, False);
		
		If EveryIntervalNewRow Then
			FilterParameters = New Structure("Document, IntervalBegin, PreviousLoadingIntervalEnd, DetailsRowNumber"
			,DetailDocument.Ref, DetailDocument.BeginTime, DetailDocument.EndTime, DetailDocument.LineNumber);
			
			FilterByRowsParameters.Insert("Ref", DetailDocument.Ref);
			FilterByRowsParameters.Insert("DocumentLineNumber", DetailDocument.LineNumber);
			
		Else
			FilterByRowsParameters.Insert("Ref", DetailDocument.Ref);
			FilterParameters = New Structure("Document", DetailDocument.Ref);
		EndIf;
		
		RowsByDocument = IntervalsOutputByDocuments.FindRows(FilterParameters);
		
		FoundValueMap = MapDetailsDocumentsRows.FindRows(FilterByRowsParameters);
		
		FilterByRowsParameters.Clear();
		
		If FoundValueMap.Count() Then
			RowOfDetails = FoundValueMap[0].RowForOutputNumber;
			
			DetailsRowNumber = ?(DetailsRowNumber = RowOfDetails, DetailsRowNumber-1, DetailsRowNumber);
		EndIf;
		
		MoveIntervalEndByDocument = 0;
		
		CellsInIntervalQuantity = (IntervalEnding - IntervalBegin)/60/5;
		TimeFinishInDocument = ?(DetailDocument.EndTime+59 = EndOfDay(DetailDocument.EndTime)
		, DetailDocument.EndTime+60, DetailDocument.EndTime);
		
		TimeFinishDocumentInInterval = ?(TimeFinishInDocument>IntervalEnding, IntervalEnding, TimeFinishInDocument);
		TimeBeginDocumentInInterval = ?(DetailDocument.BeginTime<IntervalBegin, IntervalBegin, DetailDocument.BeginTime);
		
		CellsByDocumentsInInterval = (TimeFinishDocumentInInterval - TimeBeginDocumentInInterval)/60/5;
		MoveIntervalEndByDocument = CellsForUnitteQuantity - CellsByDocumentsInInterval;
		
		If RowsByDocument.Count() Then
			RowByDocument = RowsByDocument[RowsByDocument.Count()-1];
			
			RowOfDetails = ?(EveryIntervalNewRow, RowOfDetails, RowByDocument.DetailsRowNumber);
			
			If RowByDocument.CellsQuantity = 0 Then
				
				OutputOverIntervalBoarder = True;
				
				If DetailDocument.EndTime>IntervalEnding Then
					TimeFinishDocumentInInterval = IntervalEnding;
				Else
					TimeFinishDocumentInInterval = TimeFinishInDocument;
					OutputOverIntervalBoarder = False;
				EndIf;
				
				TimeBeginDocumentInInterval = ?(DetailDocument.BeginTime<IntervalBegin, IntervalBegin, DetailDocument.BeginTime);
				
				DocumentBeginCellNumberInInterval = (TimeBeginDocumentInInterval - IntervalBegin)/60/5;
				DocumentEndCellNumberInInterval = (TimeFinishDocumentInInterval - IntervalBegin)/60/5;
				
				LoadingPeriodsByDocuments = DetailDocument.Loading;
				ColumnBeginInterval = 3+AreaOutputInterval - CellsForUnitteQuantity+DocumentBeginCellNumberInInterval+AddColumnMove;
				
				ColumnEndInterval = 2+ AreaOutputInterval - CellsForUnitteQuantity + DocumentEndCellNumberInInterval+AddColumnMove;
				
				DetailsArea = AreaDetailsByDocuments.Area(RowOfDetails,ColumnBeginInterval,RowOfDetails,ColumnEndInterval);
				DetailsArea.Merge();
				
				OutputIntervalsQuantity = IntervalsOutputByDocuments.Count();
				If OutputIntervalsQuantity Then
					LastOutputedVariant = IntervalsOutputByDocuments[OutputIntervalsQuantity-1];
					IsCrossing = ?(DetailDocument.BeginTime < LastOutputedVariant.PreviousLoadingIntervalEnd, True, False);
				EndIf;
				
				RowByDocument = IntervalsOutputByDocuments.Add();
				RowByDocument.Document = DetailDocument.Ref;
				
				RowByDocument.CellsQuantity = ?(Not OutputOverIntervalBoarder, 0, CellsByDocumentsInInterval);
				RowByDocument.UnitedCellsQuantity = ColumnEndInterval - ColumnBeginInterval;
				RowByDocument.PreviousLoading = LoadingPeriodsByDocuments;
				RowByDocument.PreviousLoadingIntervalEnd = TimeFinishInDocument;
				RowByDocument.IntervalBegin = DetailDocument.BeginTime;
				RowByDocument.DetailsRowNumber = RowOfDetails;
				
			Else
				
				AddingsRelaitedPeriod = AddingsRelaitedPeriod + 1;
				
				CellsForUniteDetailsQuantity = CellsByDocumentsInInterval+RowByDocument.CellsQuantity;
				
				If RowByDocument.PreviousLoadingIntervalEnd >= DetailDocument.BeginTime Then
					CellsForUniteDetailsQuantity = RowByDocument.UnitedCellsQuantity+CellsByDocumentsInInterval+1;
					LoadingPeriodsByDocuments = RowByDocument.PreviousLoading;
				Else
					LoadingPeriodsByDocuments = DetailDocument.Loading;
				EndIf;
				
				ColumnBeginInterval = 3+AreaOutputInterval-(CellsForUniteDetailsQuantity+MoveIntervalEndByDocument)+AddColumnMove;
				ColumnEndInterval = 2+AreaOutputInterval+AddColumnMove - MoveIntervalEndByDocument;
				
				DetailsArea = AreaDetailsByDocuments.Area(RowOfDetails, ColumnBeginInterval,RowOfDetails,ColumnEndInterval);
				
				DetailsArea.Merge();
				
				CellsByDocuments = (DetailDocument.EndTime - DetailDocument.BeginTime)/300;
				
				RowByDocument.CellsQuantity =?(CellsByDocuments=CellsForUniteDetailsQuantity,0, CellsForUniteDetailsQuantity);
				
				RowByDocument.UnitedCellsQuantity = ColumnEndInterval - ColumnBeginInterval;
				RowByDocument.PreviousLoading = LoadingPeriodsByDocuments;
				RowByDocument.PreviousLoadingIntervalEnd = RowByDocument.PreviousLoadingIntervalEnd;
				RowByDocument.IntervalBegin = DetailDocument.BeginTime;
				RowByDocument.DetailsRowNumber = RowOfDetails;
				
				OutputOverIntervalBoarder = ?(RowByDocument.CellsQuantity = 0, False, True);
				
			EndIf;
			
		Else
			
			OutputIntervalsQuantity = IntervalsOutputByDocuments.Count();
			If OutputIntervalsQuantity Then
				LastOutputedVariant = IntervalsOutputByDocuments[OutputIntervalsQuantity-1];
				IsCrossing = ?(DetailDocument.BeginTime < LastOutputedVariant.PreviousLoadingIntervalEnd, True, False);
			EndIf;
			
			RowByDocument = IntervalsOutputByDocuments.Add();
			RowByDocument.Document = DetailDocument.Ref;
			
			OutputOverIntervalBoarder = True;
			
			If DetailDocument.EndTime>IntervalEnding Then
				TimeFinishDocumentInInterval = IntervalEnding;
			Else
				TimeFinishDocumentInInterval = TimeFinishInDocument;
				OutputOverIntervalBoarder = False;
			EndIf;
			
			DocumentBeginCellNumberInInterval = (TimeBeginDocumentInInterval - IntervalBegin)/60/5;
			DocumentEndCellNumberInInterval = (TimeFinishDocumentInInterval - IntervalBegin)/60/5;
			
			LoadingPeriodsByDocuments = DetailDocument.Loading;
			ColumnBeginInterval = 3+AreaOutputInterval - CellsForUnitteQuantity+DocumentBeginCellNumberInInterval+AddColumnMove;
			
			ColumnEndInterval = 2+ AreaOutputInterval - CellsForUnitteQuantity + DocumentEndCellNumberInInterval+AddColumnMove;
			
			DetailsArea = AreaDetailsByDocuments.Area(RowOfDetails,ColumnBeginInterval,RowOfDetails,ColumnEndInterval);
			DetailsArea.Merge();
			
			RowByDocument.CellsQuantity = ?(Not OutputOverIntervalBoarder, 0, CellsByDocumentsInInterval);
			RowByDocument.UnitedCellsQuantity = ColumnEndInterval - ColumnBeginInterval;
			RowByDocument.PreviousLoading = LoadingPeriodsByDocuments;
			RowByDocument.PreviousLoadingIntervalEnd = TimeFinishInDocument;
			RowByDocument.IntervalBegin = DetailDocument.BeginTime;
			RowByDocument.DetailsRowNumber = RowOfDetails;
			
		EndIf;
		
		RowByDocument.IntervalEnd = IntervalEnding;
		
		DetailsArea.BackColor = WebColors.Turquoise;
		DetailsArea.Outline(SolidLine, SolidLine, None, SolidLine);
		DetailsArea.BorderColor = WebColors.Beige;
		DetailsArea.Text = String(LoadingPeriodsByDocuments);
		DetailsArea.HorizontalAlign = HorizontalAlign.Left;
		DetailsArea.VerticalAlign = VerticalAlign.Top;
		DetailsArea.TextColor = WebColors.White;
		DetailsArea.Details = DetailDocument.Ref;
		
		NewRow = DocumentsCoordinate.Add();
		NewRow.CoordinateBegin = DetailsArea.Left;
		NewRow.CoordinateEnd = DetailsArea.Right;
		NewRow.Ref = DetailDocument.Ref;
		NewRow.Resource = Resource;
		NewRow.DocumentLineNumber = DetailDocument.LineNumber;
		
		AreaСlarificationDottedLine = AreaDetailsByDocuments.Area(RowOfDetails,3+AddColumnMove,RowOfDetails
		,ColumnEndInterval);
		AreaСlarificationDottedLine.BottomBorder = New Line(SpreadsheetDocumentCellLineType.ThinDashed);
		AreaСlarificationDottedLine.BorderColor = WebColors.Gainsboro;
		
		RowOfDetails = ?(EveryIntervalNewRow, RowOfDetails+1, RowOfDetails);
		
	EndDo;
	
	ResourceImport = MaxByLoading(DetailsDocuments,IntervalBegin, IntervalEnding, CellsForUnitteQuantity, IntervalMatrix);
	
EndProcedure

&AtClient
Procedure OutputMultiplicityInterval(Day)
	
	ListPeriodDates.Clear();
	
	WorksScheduleRadioButton = "Interval planning";
	
	ListPeriodDates.Add(Day);
	
	Items.Calendar.SelectedDates.Clear();
	Items.Calendar.SelectedDates.Add(Day);
	
	Items.ShowDay.Check = False;
	Items.ShowPanningInterval.Check = True;
	
	Items.GroupIntervalSetting.Enabled = True;
	
	DisplayTableDocument();
	
EndProcedure

&AtClient
Procedure CreateByPeriodValueFilter()
	
	If Not ValueIsFilled(Period.StartDate) And Not ValueIsFilled(Period.EndDate) Then
		
		ListPeriodDates.Clear();
		Items.Calendar.SelectedDates.Clear();
		
		DisplayTableDocument();
		
		Return;
		
	EndIf;
	
	If Not ValueIsFilled(Period.StartDate) And ValueIsFilled(Period.EndDate) Then
		Period.StartDate = BegOfDay(Period.EndDate - 31536000)
	ElsIf Not ValueIsFilled(Period.EndDate) And ValueIsFilled(Period.StartDate) Then
		Period.EndDate = EndOfDay(Period.EndDate + 31536000)
	EndIf;
	
	FillListPeriodDates(BegOfDay(Period.StartDate), BegOfDay(Period.EndDate));
	
	Items.Calendar.SelectedDates.Clear();
	
	For Each ListElement In ListPeriodDates Do
		Items.Calendar.SelectedDates.Add(ListElement.Value);
	EndDo;
	
	If ListPeriodDates.Count()>14 And WorksScheduleRadioButton = "Interval planning" Then
		WorksScheduleRadioButton = "Day";
		Items.ShowDay.Check = True;
		Items.ShowPanningInterval.Check = False;
	EndIf;
	
	DisplayTableDocument();
	
EndProcedure

&AtServer
Function DeleteNotWorkingDaysFromList(NotWorkingDays)
	
	ReturnList = New ValueList;
	ReturnList.LoadValues(ListPeriodDates.UnloadValues());
	
	For Each ListDay In NotWorkingDays Do
		ListElement = ReturnList.FindByValue(ListDay.Value);
		ReturnList.Delete(ListElement);
	EndDo;
	
	Return ReturnList;
	
EndFunction

&AtServer
Function ArrayDocumentsWithCrossingForAllPeriod(DocumentByResource, ScheduleTable)
	
	ReturnArray = New Array;
	
	DocumentsTable = New ValueTable;
	DocumentsTable.Columns.Add("Ref");
	DocumentsTable.Columns.Add("Loading");
	DocumentsTable.Columns.Add("BeginTime");
	DocumentsTable.Columns.Add("EndTime");
	DocumentsTable.Columns.Add("IsCrossing");
	
	RefArray = New Array;
	
	For Each Document In DocumentByResource Do
		
		If RefArray.Find(Document.Ref) = Undefined And ValueIsFilled(Document.Ref) Then
			RefArray.Add(Document.Ref);
		EndIf;
		
	EndDo;
	
	For Each DocumentsRow In RefArray Do
		
		FilterParameters = New Structure("Ref", DocumentsRow);
		FoundStrings = ScheduleTable.FindRows(FilterParameters);
		
		For Each TablePeriod In FoundStrings Do
			
			If Not ValueIsFilled(TablePeriod.Ref) Then Continue EndIf;
			
			IsCrossing = False;
			
			For Each DocumentsTableRow In DocumentsTable Do
				
				If DocumentsTableRow.BeginTime<=TablePeriod.BeginTime And DocumentsTableRow.EndTime>=TablePeriod.EndTime Then
					IsCrossing = True;
				EndIf;
				
				If DocumentsTableRow.BeginTime>TablePeriod.BeginTime And DocumentsTableRow.BeginTime<=TablePeriod.EndTime Then
					DocumentsTableRow.BeginTime=TablePeriod.BeginTime;
					IsCrossing = True;
				EndIf;
				
				If DocumentsTableRow.EndTime>TablePeriod.BeginTime And DocumentsTableRow.EndTime<TablePeriod.EndTime Then
					DocumentsTableRow.EndTime=TablePeriod.EndTime;
					IsCrossing = True;
				EndIf;
				
			EndDo;
			
			If IsCrossing And Not ValueIsFilled(ReturnArray.Find(TablePeriod.Ref)) Then
				ReturnArray.Add(TablePeriod.Ref)
			EndIf;
			
			NewRow = DocumentsTable.Add();
			NewRow.Ref = TablePeriod.Ref;
			NewRow.Loading = TablePeriod.Loading; // ava1c Load --> Loading
			NewRow.BeginTime = TablePeriod.BeginTime;
			NewRow.EndTime = TablePeriod.EndTime;
			NewRow.IsCrossing = IsCrossing;
			
		EndDo;
		
		DocumentsTable.Clear();
		
	EndDo;
	
	Return ReturnArray;
	
EndFunction

&AtServer
Function ResourceLoadingForMonth(TableOfPeriods, EnterpriseResource, YearPeriod, MonthPeriod)
	
	FilterParameters = New Structure("EnterpriseResource, Year, Month",EnterpriseResource, YearPeriod,MonthPeriod);
	RowsByResource = TableOfPeriods.FindRows(FilterParameters);
	
	If Not RowsByResource.Count() Then Return 0 EndIf;
	
	MultiplicityPlanning = EnterpriseResource.MultiplicityPlanning;
	
	If MultiplicityPlanning = 0 Then Return 0 EndIf;
	
	AvailableLoadingForDay = 0;
	
	For Each ResourceRow In RowsByResource Do
		
		WorkingTime = ResourceRow.WorkPeriodPerDayEnd - ResourceRow.BeginWorkPeriodInDay;
		
		WorkingTime = (WorkingTime/60)/MultiplicityPlanning;
		WorkingTime = ?(WorkingTime - Int(WorkingTime)>0, Int(WorkingTime)+1, WorkingTime);
		
		
		LoadingForInterval = WorkingTime * EnterpriseResource.Capacity;
		
		AvailableLoadingForDay = AvailableLoadingForDay + LoadingForInterval;
		
	EndDo;
	
	Return AvailableLoadingForDay;
	
EndFunction

&AtServer
Function MaxByLoading(DetailsDocuments, IntervalBegin, IntervalEnding, CellsInIntervalQuantity, IntervalTableBy5Min)
	
	If Not DetailsDocuments.Count() Then Return 0 EndIf;
	
	MaxLoading = 0;
	IntervalTableBy5Min.Clear();
	
	MapCellTime = New Map;
	
	CellIndex = 1;
	IntervalTime = IntervalBegin;
	
	If IntervalEnding = EndOfDay(IntervalEnding) Then
		IntervalEnding = IntervalEnding + 1;
	EndIf;
	
	While IntervalTime <= IntervalEnding Do
		MapCellTime.Insert(IntervalTime, CellIndex);
		
		IntervalTime = IntervalTime + 300;
		CellIndex = CellIndex + 1;
	EndDo;
	
	For Each RowDetailsDocument In DetailsDocuments Do
		
		If RowDetailsDocument.BeginTime>=IntervalBegin Then
			TimeCellInterval = RowDetailsDocument.BeginTime;
			CellsQuantity = RowDetailsDocument.CellsQuantity;
		Else
			TimeCellInterval = IntervalBegin;
			CellsQuantity = (RowDetailsDocument.EndTime - IntervalBegin)/300;
		EndIf;
		
		IntervalStartCellNumber = MapCellTime.Get(TimeCellInterval);
		
		IntervalEndCellNumber = IntervalStartCellNumber + (CellsQuantity-1);
		IntervalEndCellNumber = ?(IntervalEndCellNumber > CellsInIntervalQuantity, CellsInIntervalQuantity, IntervalEndCellNumber);
		
		NewRow = IntervalTableBy5Min.Add();
		
		While IntervalStartCellNumber <= IntervalEndCellNumber Do
			
			ColumnName = "Column"+String(IntervalStartCellNumber);
			
			NewRow[ColumnName] = RowDetailsDocument.Loading;
			
			IntervalStartCellNumber = IntervalStartCellNumber + 1;
			
		EndDo;
		
	EndDo;
	
	For Each TableColumn In IntervalTableBy5Min.Columns Do
		ColumnTotal = IntervalTableBy5Min.Total(TableColumn);
		MaxLoading = ?(MaxLoading<ColumnTotal, ColumnTotal, MaxLoading);
	EndDo;
	
	Return MaxLoading;
	
EndFunction

&AtServer
Function RecourceLoadingOnDate(PeriodTableOnDate, EnterpriseResource, SearchPeriod)
	
	TableOfPeriods = PeriodTableOnDate.Copy();
	
	TableOfPeriods.GroupBy("EnterpriseResource,Period, BeginWorkPeriodInDay, WorkPeriodPerDayEnd");
	
	FilterParameters = New Structure("EnterpriseResource, Period",EnterpriseResource, BegOfDay(SearchPeriod));
	RowsByResource = TableOfPeriods.FindRows(FilterParameters);
	
	If Not RowsByResource.Count() Then Return 0 EndIf;
	
	MultiplicityPlanning = ?(EnterpriseResource.MultiplicityPlanning = 0, 5, EnterpriseResource.MultiplicityPlanning);
	
	AvailableLoadingForDay = 0;
	
	For Each ResourceRow In RowsByResource Do
		
		If Not ValueIsFilled(ResourceRow.WorkPeriodPerDayEnd) 
			Or Not ValueIsFilled(ResourceRow.BeginWorkPeriodInDay) Then
			Continue
		EndIf;
		
		WorkingTime = ResourceRow.WorkPeriodPerDayEnd - ResourceRow.BeginWorkPeriodInDay;
		
		WorkingTime = (WorkingTime/60)/MultiplicityPlanning;
		WorkingTime = ?(WorkingTime - Int(WorkingTime)>0, Int(WorkingTime)+1, WorkingTime);
		
		
		LoadingForInterval = WorkingTime * EnterpriseResource.Capacity;
		
		AvailableLoadingForDay = AvailableLoadingForDay + LoadingForInterval;
		
	EndDo;
	
	If MultiplicityPlanning = 0 Then Return 0 EndIf;
	
	Return AvailableLoadingForDay;
	
EndFunction

&AtServer
Procedure UpdateRepresentationAreaAccordingLoading(Area, ResourceImport, Capacity, TimeBeginOfInterval = Undefined
	,ItTotal = False, IsOverLoadingByMultiplicity = False, CellsForUnitteQuantity = 0
	, StructureTotalsPerDay = Undefined, ItWorkPeriod = False)
	
	If Not ItTotal Then
		BalanceOnLoading = ?(ItWorkPeriod And Capacity - ResourceImport > 0, Capacity - ResourceImport, 0);
		StructureDetailsPeriod = New Structure("BalanceOnLoading, ItWorkPeriod",BalanceOnLoading,ItWorkPeriod);
		Area.Details = StructureDetailsPeriod;
	EndIf;
	
	If WorksScheduleRadioButton = "Interval planning" Then
		If CellsForUnitteQuantity>2 Then
			
			If TimeBeginOfInterval = Undefined Then
				Area.Text = String(ResourceImport)+"|"+String(Capacity);
			Else
				Area.Text = String(ResourceImport)+"|"+String(Capacity)+"
				|
				|"+Format(TimeBeginOfInterval,"DF=ЧЧ:мм");
			EndIf;
		Else
			Area.Text = ?(Not ResourceImport = 0,String(ResourceImport),"");
		EndIf;
	Else
		
		If TimeBeginOfInterval = Undefined Then
			
			If WorksScheduleRadioButton = "Day" And Not StructureTotalsPerDay = Undefined And ValueIsFilled(Capacity) Then
				Area.Text = String(ResourceImport)+"|"+String(Capacity)+"
				|
				|"+String(StructureTotalsPerDay.IntervalsWithLoading)+"|"+String(StructureTotalsPerDay.IntervalsWithoutLoading);
				
			ElsIf ValueIsFilled(ResourceImport) Then
				Area.Text = String(ResourceImport)+"|"+String(Capacity);
			EndIf;
			
		Else
			Area.Text = Format(TimeBeginOfInterval,"DF=ЧЧ:мм")+"
			|
			|"+?(Not ResourceImport = 0,String(ResourceImport),"");
		EndIf;
		
	EndIf;
	
	Area.VerticalAlign = VerticalAlign.Top;
	Area.HorizontalAlign = ?(ItTotal, HorizontalAlign.Right, HorizontalAlign.Left);
	
	Area.TextColor = WebColors.White;
	Area.BorderColor = WebColors.White;
	
	If IsOverLoadingByMultiplicity Then 
		Area.BackColor = ?(Not ColorOverloading = Undefined, ColorOverloading,WebColors.Salmon);
		Return;
	EndIf;
	
	If ResourceImport > Capacity Then
		Area.BackColor = ColorOverloading;
	ElsIf ResourceImport = Capacity And Not (ResourceImport = 0 And Capacity = 0) Then
		Area.BackColor = ColorFullLoading;
	ElsIf ResourceImport >=1 And ResourceImport< Capacity Then
		
		If LoadingProcent = 0 Then
			Area.BackColor = ColorPartialLoadingBefore;
		Else
			LoadingByProcent = Capacity/100*LoadingProcent;
			
			If ResourceImport <= LoadingByProcent Then
				Area.BackColor = ColorPartialLoadingBefore;
			Else
				Area.BackColor = ColorPartialLoadingAfter;
			EndIf;
		EndIf;
		
	ElsIf ResourceImport = 0 And Not Capacity = 0 Then
		Area.BackColor = ColorWorkTime;
	Else
		Area.BackColor = StyleColors.WorktimeFreeAvailable;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillListDaysByMonth()
	
	PeriodTable = PeriodTableYearMonth(True);
	
	ListPeriodDates.Clear();
	Items.Calendar.SelectedDates.Clear();
	
	For Each TablePeriod In PeriodTable Do
		DaysInMonth = Day(EndOfMonth(Date(TablePeriod.Year, TablePeriod.Month, 1)));
		
		MonthDayIndex = 1;
		
		While MonthDayIndex <= DaysInMonth Do
			
			PeriodDate = Date(TablePeriod.Year, TablePeriod.Month, MonthDayIndex);
			
			ListPeriodDates.Add(PeriodDate);
			Items.Calendar.SelectedDates.Add(PeriodDate);
			
			MonthDayIndex = MonthDayIndex + 1;
			
		EndDo;
		
	EndDo;
	
	CalendarDate = ?(Not ValueIsFilled(PeriodDate), CurrentDate(), PeriodDate);
	
EndProcedure

&AtClient
Procedure AddDateForMonthEnd()
	
	DateCount = Items.Calendar.SelectedDates.Count();
	
	LastDate = Items.Calendar.SelectedDates[DateCount-1];
	FirstDate = Items.Calendar.SelectedDates[0];
	
	EndOfMonth = BegOfDay(EndOfMonth(LastDate));
	
	Items.Calendar.SelectedDates.Clear();
	
	FirstDate = BegOfMonth(FirstDate);
	
	While FirstDate <= EndOfMonth Do
		Items.Calendar.SelectedDates.Add(FirstDate);
		FirstDate = BegOfDay(FirstDate+86400);
	EndDo;
	
EndProcedure

&AtServer
Function MaxQuantityUsingResourcesPerPeriodUnity(ResourcesList)
	
	Query = New Query;
	
	Query.SetParameter("StartDate", BegOfDay(ListPeriodDates[0].Value));
	Query.SetParameter("EndDate", EndOfDay(ListPeriodDates[ListPeriodDates.Count()-1].Value));
	Query.SetParameter("FilterKeyResourcesList", ResourcesList);
	
	Query.Text = 
	"SELECT
	|	ScheduleLoadingResources.Recorder AS Ref,
	|	ScheduleLoadingResources.EnterpriseResource AS EnterpriseResource,
	|	ScheduleLoadingResources.Capacity AS Capacity,
	|	ScheduleLoadingResources.Start AS Start,
	|	ScheduleLoadingResources.Finish AS Finish,
	|	ScheduleLoadingResources.Counterparty AS Counterparty,
	|	ScheduleLoadingResources.Responsible AS Responsible
	|INTO TTForResourcesLoading
	|FROM
	|	InformationRegister.ScheduleLoadingResources AS ScheduleLoadingResources
	|WHERE
	|	ScheduleLoadingResources.Start BETWEEN &StartDate AND &EndDate
	|	AND ScheduleLoadingResources.Finish BETWEEN &StartDate AND &EndDate
	|	AND ScheduleLoadingResources.EnterpriseResource IN(&FilterKeyResourcesList)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	COUNT(DISTINCT TTForResourcesLoading.EnterpriseResource) AS QuantityOfResources,
	|	BEGINOFPERIOD(TTForResourcesLoading.Start, DAY) AS Day
	|INTO Total
	|FROM
	|	TTForResourcesLoading AS TTForResourcesLoading
	|
	|GROUP BY
	|	BEGINOFPERIOD(TTForResourcesLoading.Start, DAY)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	Total.QuantityOfResources AS QuantityOfResources
	|FROM
	|	Total AS Total
	|
	|ORDER BY
	|	QuantityOfResources DESC";
	
	
	Result = Query.Execute().Select();
	
	Return ?(Result.Next(), Result.QuantityOfResources, 0);
	
EndFunction

&AtServer
Function PeriodTableYearMonth(ByMonths = False, ListDatesForCreateGraphForDays = Undefined)
	
	PeriodTableYears = New ValueTable;
	PeriodTableYears.Columns.Add("Year");
	PeriodTableYears.Columns.Add("DaysNumber");
	
	If ByMonths Then
		PeriodTableYears.Columns.Add("Month");
		
		For Each ListDate In ListPeriodDates Do
			
			NewRow = PeriodTableYears.Add();
			NewRow.Year = Year(ListDate.Value);
			NewRow.Month = Month(ListDate.Value);
			NewRow.DaysNumber = 1;
			
		EndDo;
		
		PeriodTableYears.GroupBy("Year, Month","DaysNumber");
		PeriodTableYears.Sort("Year Asc, Month Asc");
		
		Return PeriodTableYears;
		
	EndIf;
	
	ListCounterPeriodDates = ?(Not ListDatesForCreateGraphForDays = Undefined
	,ListDatesForCreateGraphForDays
	,ListPeriodDates);
	
	For Each ListDate In ListCounterPeriodDates Do
		
		NewRow = PeriodTableYears.Add();
		NewRow.Year = Year(ListDate.Value);
		NewRow.DaysNumber = 1;
		
	EndDo;
	
	PeriodTableYears.GroupBy("Year","DaysNumber");
	PeriodTableYears.Sort("Year Asc");
	
	Return PeriodTableYears;
	
EndFunction

&AtServer
Function GetIntervalValue(ListREsourceMultiplicity)
	
	First = ListREsourceMultiplicity[0].Value;
	
	Second = ?(ListREsourceMultiplicity.Count() = 1,First, ListREsourceMultiplicity[1].Value);
	
	ListRecursion = New ValueList;
	
	Balance = First % Second;
	
	If Balance > 0 Then
		First = Second;
		Second = Balance;
		
		ListRecursion.Add(First);
		ListRecursion.Add(Second);
		ListRecursion.SortByValue(SortDirection.Desc);
		
		If ListREsourceMultiplicity.Count()>2 Then
			ListREsourceMultiplicity.Delete(ListREsourceMultiplicity[0]);
			ListREsourceMultiplicity.Delete(ListREsourceMultiplicity[0]);
		EndIf;
		
		Gcd = GetIntervalValue(ListRecursion);
		
		Return Gcd;
		
	Else
		
		If ListREsourceMultiplicity.Count()>2 Then
			ListREsourceMultiplicity.Delete(ListREsourceMultiplicity[0]);
			ListREsourceMultiplicity.Delete(ListREsourceMultiplicity[0]);
			
			If ListREsourceMultiplicity[0].Value%Second > 0
				Then
				ListRecursion.Clear();
				ListRecursion.Add(ListREsourceMultiplicity[0].Value);
				ListRecursion.Add(Second);
				ListRecursion.SortByValue(SortDirection.Desc);
				Gcd = GetIntervalValue(ListRecursion);
				
				Return Gcd;
			EndIf;
		Else
			Return Second;
		EndIf;
		
	EndIf;
	
EndFunction

&AtServer
Procedure OutputPeriodDelimiters(TemplateArea, Line, Color)
	
	TemplateArea.Outline(Line);
	TemplateArea.BorderColor = Color;
	
EndProcedure

&AtServer
Function WorkPeriodBoarders(SearchPeriod, Val WorkPeriods, Val ScheduleLoading, Resource = Undefined)
	
	BeginOfPeriod = BegOfDay(SearchPeriod);
	EndOfPeriod = EndOfDay(SearchPeriod);
	
	FilterParameters = New Structure("Period, Year", BeginOfPeriod, Year(BeginOfPeriod));
	
	FoundRowsByGraph = WorkPeriods.FindRows(FilterParameters);
	
	QuantityByFoundedRowsPer = FoundRowsByGraph.Count();
	
	If QuantityByFoundedRowsPer Then
		
		FirstIteration = True;
		
		For Each FoundString In FoundRowsByGraph Do
			If ValueIsFilled(FoundString.BeginWorkPeriodInDay) And ValueIsFilled(FoundString.BeginWorkPeriodInDay) Then
				
				If FirstIteration Then
					BeginOfPeriod = FoundString.BeginWorkPeriodInDay;
					EndOfPeriod = FoundString.WorkPeriodPerDayEnd;
					FirstIteration = False;
					Continue;
				EndIf;
				
				BeginOfPeriod = ?(FoundString.BeginWorkPeriodInDay<BeginOfPeriod, FoundString.BeginWorkPeriodInDay, BeginOfPeriod);
				EndOfPeriod = ?(FoundString.WorkPeriodPerDayEnd>EndOfPeriod, FoundString.WorkPeriodPerDayEnd, EndOfPeriod);
			EndIf;
		EndDo;
		
	EndIf;
	
	FoundRowsBySchedule = ScheduleLoading.FindRows(FilterParameters);
	
	QuantityByFoundedRows = FoundRowsBySchedule.Count();
	
	If QuantityByFoundedRows Then
		BeginOfPeriod = ?(FoundRowsBySchedule[0].BeginTime<BeginOfPeriod, FoundRowsBySchedule[0].BeginTime, BeginOfPeriod);
		EndTime = ?(FoundRowsBySchedule[QuantityByFoundedRows-1].EndTime>EndOfPeriod, FoundRowsBySchedule[QuantityByFoundedRows-1].EndTime,EndOfPeriod);
		EndOfPeriod = ?(EndTime+59 = EndOfDay(EndTime),EndTime+60, EndTime);
	EndIf;
	
	If Not QuantityByFoundedRowsPer Then
		ReturnStructure = New Structure("BeginTime, EndTime", Date(1,1,1), EndOfPeriod);
	Else
		ReturnStructure = New Structure("BeginTime, EndTime", BeginOfPeriod, EndOfPeriod);
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

&AtServer
Function ItWorkInterval(SearchPeriod, WorkPeriods, ScheduleLoading = Undefined
	, DurationPeriod = Undefined, PeriodDaySummary = False)
	
	If PeriodDaySummary Then 
		
		FilterParameters = New Structure("Period", BegOfDay(SearchPeriod));
		RowsByPeriod = WorkPeriods.FindRows(FilterParameters);
		
		If Not RowsByPeriod.Count() Then Return False EndIf;
		
		For Each RowByPeriod In RowsByPeriod Do
			
			If Not RowByPeriod.BeginWorkPeriodInDay = RowByPeriod.WorkPeriodPerDayEnd Then
				Return True;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If ScheduleLoading = Undefined Or DurationPeriod = Undefined Then Return False EndIf;
	
	BeginOfPeriod = SearchPeriod;
	PeriodEnding = SearchPeriod + DurationPeriod;
	
	For Each TablePeriod In ScheduleLoading Do
		
		If ValueIsFilled(TablePeriod.Ref) Then
			
			If Not ValueIsFilled(TablePeriod.BeginTime) Then Continue EndIf;
			
			If TablePeriod.BeginTime > PeriodEnding Then Continue EndIf;
			
			If TablePeriod.BeginTime >= BeginOfPeriod And TablePeriod.BeginTime< PeriodEnding
				Or TablePeriod.EndTime > BeginOfPeriod And TablePeriod.EndTime <= PeriodEnding 
				Or TablePeriod.BeginTime< PeriodEnding And PeriodEnding<= TablePeriod.EndTime Then
				Return True 
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

&AtServer
Function ItWorkPeriod(TableOfPeriods, SearchPeriod, EnterpriseResource, PeriodDaySummary = False
	, ScheduleLoading = Undefined, DurationPeriod = Undefined, WorkPeriodKind = Undefined)
	
	WorkPeriodKind = "ByGraph";
	
	FilterParameters = New Structure("EnterpriseResource, Period",EnterpriseResource, BegOfDay(SearchPeriod));
	RowsByResource = TableOfPeriods.FindRows(FilterParameters);
	
	If PeriodDaySummary Then 
		If RowsByResource.Count() Then
			
			If (ValueIsFilled(RowsByResource[0].BeginWorkPeriodInDay) Or ValueIsFilled(RowsByResource[0].WorkPeriodPerDayEnd)) Then
				Return True
			EndIf;
			
		Else
			Return False
		EndIf;
	EndIf;
	
	For Each TablePeriod In RowsByResource Do
		
		If ValueIsFilled(TablePeriod.WorkSchedule) Then
			
			If Not ValueIsFilled(TablePeriod.BeginWorkPeriodInDay) Then Continue EndIf;
			If TablePeriod.BeginWorkPeriodInDay > SearchPeriod Then Continue EndIf;
			
			If SearchPeriod < TablePeriod.WorkPeriodPerDayEnd Then Return True EndIf;
		Else
			Return True;
		EndIf;
		
	EndDo;
	
	If ScheduleLoading = Undefined Or DurationPeriod = Undefined Then Return False EndIf;
	
	BeginOfPeriod = SearchPeriod;
	PeriodEnding = SearchPeriod + DurationPeriod;
	
	RowsByResource = ScheduleLoading.FindRows(FilterParameters);
	
	For Each TablePeriod In RowsByResource Do
		
		If ValueIsFilled(TablePeriod.Ref) Then
			
			If Not ValueIsFilled(TablePeriod.BeginTime) Then Continue EndIf;
			
			If TablePeriod.BeginTime > PeriodEnding Then Continue EndIf;
			
			If TablePeriod.BeginTime >= BeginOfPeriod And TablePeriod.BeginTime< PeriodEnding
				Or TablePeriod.EndTime > BeginOfPeriod And TablePeriod.EndTime <= PeriodEnding 
				Or TablePeriod.BeginTime< PeriodEnding And PeriodEnding<= TablePeriod.EndTime Then
				WorkPeriodKind = "ByDocument";
				Return True 
			EndIf;
			
		EndIf;
		
	EndDo;
	
	WorkPeriodKind = "Nonworking";
	
	Return False;
	
EndFunction

&AtServer
Function StructurePlanningInterval()
	
	Query = New Query;
	
	Query.Text = 
	"SELECT DISTINCT TOP 1
	|	KeyResources.MultiplicityPlanning * 60 AS MultiplicityPlanning,
	|	KeyResources.Ref AS Resource
	|FROM
	|	Catalog.KeyResources AS KeyResources
	|WHERE
	|	NOT KeyResources.DeletionMark
	|	AND NOT KeyResources.MultiplicityPlanning = 0
	|
	|ORDER BY
	|	MultiplicityPlanning";
	
	SelectionResourcesMultiplicity = Query.Execute().Select();
	
	ReturnStructure = New Structure("Resource, MinInterval");
	
	While SelectionResourcesMultiplicity.Next() Do
		ReturnStructure.Resource = SelectionResourcesMultiplicity.Resource;
		ReturnStructure.MinInterval = ?(SelectionResourcesMultiplicity.MultiplicityPlanning<900, 900,SelectionResourcesMultiplicity.MultiplicityPlanning);
	EndDo;
	
	Return ReturnStructure;
	
EndFunction

&AtServer
Function GetResourcesWorkImportSchedule(ResourcesList, DocumentList)
	
	Query = New Query;
	Query.SetParameter("BeginOfPeriod", ListPeriodDates[ListPeriodDates.Count()-1].Value);
	Query.SetParameter("ResourcesList", ResourcesList);
	Query.Text =
	"SELECT
	|	ResourcesWorkSchedules.Period AS Period,
	|	ResourcesWorkSchedules.WorkSchedule AS WorkSchedule,
	|	ResourcesWorkSchedules.EnterpriseResource AS EnterpriseResource
	|INTO Total
	|FROM
	|	InformationRegister.ResourcesWorkSchedules AS ResourcesWorkSchedules
	|WHERE
	|	NOT ResourcesWorkSchedules.EnterpriseResource.UseEmployeeGraph
	|	AND NOT ResourcesWorkSchedules.EnterpriseResource.NotValid
	|	AND ResourcesWorkSchedules.EnterpriseResource IN (&ResourcesList)
	|
	|UNION
	|
	|SELECT
	|	Employees.Period,
	|	Employees.WorkSchedule,
	|	KeyResources.Ref
	|FROM
	|	Catalog.KeyResources AS KeyResources
	|		LEFT JOIN InformationRegister.Employees AS Employees
	|		ON KeyResources.ResourceValue = Employees.Employee
	|WHERE
	|	NOT KeyResources.NotValid
	|	AND KeyResources.UseEmployeeGraph
	|	AND KeyResources.Ref IN (&ResourcesList)
	|
	|UNION
	|
	|SELECT
	|	Employees.Period,
	|	Employees.WorkSchedule,
	|	KeyResources.Ref
	|FROM
	|	Catalog.KeyResources AS KeyResources
	|		LEFT JOIN InformationRegister.Employees AS Employees
	|		ON KeyResources.ResourceValue = Employees.Employee
	|WHERE
	|	VALUETYPE(KeyResources.ResourceValue) = TYPE(Catalog.Employees)
	|	AND NOT KeyResources.NotValid
	|	AND NOT KeyResources.UseEmployeeGraph
	|	AND NOT KeyResources.Ref IN
	|				(SELECT
	|					ResourcesWorkSchedules.EnterpriseResource AS Ref
	|				FROM
	|					InformationRegister.ResourcesWorkSchedules AS ResourcesWorkSchedules
	|				WHERE
	|					NOT ResourcesWorkSchedules.EnterpriseResource.NotValid
	|					AND NOT ResourcesWorkSchedules.EnterpriseResource.UseEmployeeGraph)
	|	AND KeyResources.Ref IN (&ResourcesList)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Total.Period AS Period,
	|	Total.WorkSchedule AS WorkSchedule,
	|	Total.EnterpriseResource AS EnterpriseResource
	|FROM
	|	Total AS Total
	|
	|ORDER BY
	|	EnterpriseResource,
	|	Period DESC
	|TOTALS BY
	|	EnterpriseResource";
	
	QueryResult = Query.Execute();
	SelectionResource = QueryResult.Select(QueryResultIteration.ByGroups, "EnterpriseResource");
	
	TableOfSchedules = New ValueTable;
	
	Array = New Array;
	Array.Add(Type("Date"));
	TypeDescription = New TypeDescription(Array, ,);
	Array.Clear();
	
	TableOfSchedules.Columns.Add("Period", TypeDescription);
	
	Array = New Array;
	Array.Add(Type("CatalogRef.KeyResources"));
	TypeDescription = New TypeDescription(Array, ,);
	Array.Clear();
	
	TableOfSchedules.Columns.Add("EnterpriseResource", TypeDescription);
	
	Array = New Array;
	Array.Add(Type("CatalogRef.WorkSchedules"));
	TypeDescription = New TypeDescription(Array, ,);
	Array.Clear();
	
	TableOfSchedules.Columns.Add("WorkSchedule", TypeDescription);
	
	While SelectionResource.Next() Do
		
		ArrayOfScheduledDays = New Array();
		For Each ListIt In ListPeriodDates Do
			ArrayOfScheduledDays.Add(ListIt.Value);
		EndDo;
		
		Selection = SelectionResource.Select();
		While Selection.Next() Do
			
			If Not ValueIsFilled(Selection.Period) Then Continue EndIf;
			
			Ind = 0;
			While Ind <= ArrayOfScheduledDays.Count() - 1 Do
				
				If Selection.Period <= ArrayOfScheduledDays[Ind] Then
					
					NewRow = TableOfSchedules.Add();
					NewRow.EnterpriseResource = Selection.EnterpriseResource;
					NewRow.Period = ArrayOfScheduledDays[Ind];
					NewRow.WorkSchedule = Selection.WorkSchedule;
					ArrayOfScheduledDays.Delete(Ind);
					
				Else
					Ind = Ind + 1;
				EndIf;
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
	ResourcesWithoutGraph = New Array;
	CommonListResources = New Array;
	
	For Each ArrayElement In ResourcesList Do
		CommonListResources.Add(ArrayElement);
	EndDo;
	
	For Each ListResource In CommonListResources Do
		
		FoundValue = TableOfSchedules.Find(ListResource);
		
		If FoundValue = Undefined Then
			ResourcesWithoutGraph.Add(ListResource);
			ElementToDelete = ResourcesList.Find(ListResource);
			ResourcesList.Delete(ElementToDelete);
		EndIf;
		
	EndDo;
	
	TempTablesManager = New TempTablesManager;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT ALLOWED
	|	KeyResources.Ref AS EnterpriseResource,
	|	KeyResources.Capacity AS Capacity,
	|	KeyResources.Description AS ResourceDescription
	|INTO EnterpriseResourceTempTable
	|FROM
	|	Catalog.KeyResources AS KeyResources
	|WHERE
	|	KeyResources.Ref IN(&FilterKeyResourcesList)
	|	AND NOT KeyResources.DeletionMark
	|	AND NOT KeyResources.NotValid
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	KeyResources.Ref AS EnterpriseResource,
	|	KeyResources.Capacity AS Capacity,
	|	KeyResources.Description AS ResourceDescription
	|INTO ResourcesWithoutGraph
	|FROM
	|	Catalog.KeyResources AS KeyResources
	|WHERE
	|	KeyResources.Ref IN(&ResourcesWithoutGraph)
	|	AND NOT KeyResources.NotValid
	|	AND NOT KeyResources.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TableOfSchedules.Period AS Period,
	|	TableOfSchedules.EnterpriseResource AS EnterpriseResource,
	|	TableOfSchedules.WorkSchedule AS WorkSchedule
	|INTO SchedulesTempTable
	|FROM
	|	&TableOfSchedules AS TableOfSchedules
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	EnterpriseResourceTempTable.EnterpriseResource AS EnterpriseResource,
	|	EnterpriseResourceTempTable.Capacity AS Capacity,
	|	SchedulesTempTable.Period AS Period,
	|	SchedulesTempTable.WorkSchedule AS WorkSchedule,
	|	CASE
	|		WHEN NOT DeviationFromResourcesWorkSchedules.BeginTime = DATETIME(1, 1, 1, 0, 0, 0)
	|			THEN YEAR(DeviationFromResourcesWorkSchedules.BeginTime)
	|		ELSE YEAR(WorkSchedules.BeginTime)
	|	END AS Year,
	|	CASE
	|		WHEN NOT DeviationFromResourcesWorkSchedules.BeginTime = DATETIME(1, 1, 1, 0, 0, 0)
	|			THEN MONTH(DeviationFromResourcesWorkSchedules.BeginTime)
	|		ELSE MONTH(WorkSchedules.BeginTime)
	|	END AS Month,
	|	CASE
	|		WHEN ISNULL(DeviationFromResourcesWorkSchedules.EndTime, 0) = 0
	|			THEN CASE
	|					WHEN NOT DATEDIFF(BEGINOFPERIOD(WorkSchedules.EndTime, MINUTE), WorkSchedules.EndTime, SECOND) = 0
	|						THEN DATEADD(BEGINOFPERIOD(WorkSchedules.EndTime, MINUTE), SECOND, 60)
	|					ELSE WorkSchedules.EndTime
	|				END
	|		ELSE CASE
	|				WHEN NOT DATEDIFF(BEGINOFPERIOD(DeviationFromResourcesWorkSchedules.EndTime, MINUTE), DeviationFromResourcesWorkSchedules.EndTime, SECOND) = 0
	|					THEN DATEADD(BEGINOFPERIOD(DeviationFromResourcesWorkSchedules.EndTime, MINUTE), SECOND, 60)
	|				ELSE DeviationFromResourcesWorkSchedules.EndTime
	|			END
	|	END AS WorkPeriodPerDayEnd,
	|	CASE
	|		WHEN ISNULL(DeviationFromResourcesWorkSchedules.BeginTime, 0) = 0
	|			THEN CASE
	|					WHEN NOT DATEDIFF(BEGINOFPERIOD(WorkSchedules.BeginTime, MINUTE), WorkSchedules.BeginTime, SECOND) = 0
	|						THEN DATEADD(BEGINOFPERIOD(WorkSchedules.BeginTime, MINUTE), SECOND, 60)
	|					ELSE WorkSchedules.BeginTime
	|				END
	|		ELSE CASE
	|				WHEN NOT DATEDIFF(BEGINOFPERIOD(DeviationFromResourcesWorkSchedules.BeginTime, MINUTE), DeviationFromResourcesWorkSchedules.BeginTime, SECOND) = 0
	|					THEN DATEADD(BEGINOFPERIOD(DeviationFromResourcesWorkSchedules.BeginTime, MINUTE), SECOND, 60)
	|				ELSE DeviationFromResourcesWorkSchedules.BeginTime
	|			END
	|	END AS BeginWorkPeriodInDay
	|FROM
	|	EnterpriseResourceTempTable AS EnterpriseResourceTempTable
	|		LEFT JOIN SchedulesTempTable AS SchedulesTempTable
	|		ON EnterpriseResourceTempTable.EnterpriseResource = SchedulesTempTable.EnterpriseResource
	|		LEFT JOIN InformationRegister.WorkSchedules AS WorkSchedules
	|		ON (SchedulesTempTable.WorkSchedule = WorkSchedules.WorkSchedule)
	|			AND (WorkSchedules.BeginTime BETWEEN &StartDate AND &EndDate)
	|			AND (WorkSchedules.EndTime BETWEEN &StartDate AND &EndDate)
	|			AND (SchedulesTempTable.Period = BEGINOFPERIOD(WorkSchedules.BeginTime, Day))
	|			AND (SchedulesTempTable.Period = BEGINOFPERIOD(WorkSchedules.EndTime, Day))
	|		LEFT JOIN InformationRegister.DeviationFromResourcesWorkSchedules AS DeviationFromResourcesWorkSchedules
	|		ON EnterpriseResourceTempTable.EnterpriseResource = DeviationFromResourcesWorkSchedules.EnterpriseResource
	|			AND (SchedulesTempTable.Period = BEGINOFPERIOD(DeviationFromResourcesWorkSchedules.Day, Day))
	|			AND (DeviationFromResourcesWorkSchedules.BeginTime BETWEEN &StartDate AND &EndDate)
	|			AND (DeviationFromResourcesWorkSchedules.EndTime BETWEEN &StartDate AND &EndDate)
	|
	|UNION ALL
	|
	|SELECT
	|	ResourcesWithoutGraph.EnterpriseResource,
	|	ResourcesWithoutGraph.Capacity,
	|	DeviationFromResourcesWorkSchedules.Day,
	|	""GraphNotSpecified"",
	|	YEAR(DeviationFromResourcesWorkSchedules.BeginTime),
	|	MONTH(DeviationFromResourcesWorkSchedules.BeginTime),
	|	CASE
	|		WHEN NOT DATEDIFF(BEGINOFPERIOD(DeviationFromResourcesWorkSchedules.EndTime, MINUTE), DeviationFromResourcesWorkSchedules.EndTime, SECOND) = 0
	|			THEN DATEADD(BEGINOFPERIOD(DeviationFromResourcesWorkSchedules.EndTime, MINUTE), SECOND, 60)
	|		ELSE DeviationFromResourcesWorkSchedules.EndTime
	|	END,
	|	CASE
	|		WHEN NOT DATEDIFF(BEGINOFPERIOD(DeviationFromResourcesWorkSchedules.BeginTime, MINUTE), DeviationFromResourcesWorkSchedules.BeginTime, SECOND) = 0
	|			THEN DATEADD(BEGINOFPERIOD(DeviationFromResourcesWorkSchedules.BeginTime, MINUTE), SECOND, 60)
	|		ELSE DeviationFromResourcesWorkSchedules.BeginTime
	|	END
	|FROM
	|	ResourcesWithoutGraph AS ResourcesWithoutGraph
	|		LEFT JOIN InformationRegister.DeviationFromResourcesWorkSchedules AS DeviationFromResourcesWorkSchedules
	|		ON ResourcesWithoutGraph.EnterpriseResource = DeviationFromResourcesWorkSchedules.EnterpriseResource
	|			AND (DeviationFromResourcesWorkSchedules.BeginTime BETWEEN &StartDate AND &EndDate)
	|			AND (DeviationFromResourcesWorkSchedules.EndTime BETWEEN &StartDate AND &EndDate)
	|
	|ORDER BY
	|	BeginWorkPeriodInDay
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	EnterpriseResourceTempTable.EnterpriseResource AS EnterpriseResource,
	|	EnterpriseResourceTempTable.Capacity AS Capacity,
	|	EnterpriseResourceTempTable.ResourceDescription AS ResourceDescription
	|INTO CommonResouorceTable
	|FROM
	|	EnterpriseResourceTempTable AS EnterpriseResourceTempTable
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	ResourcesWithoutGraph.EnterpriseResource,
	|	ResourcesWithoutGraph.Capacity,
	|	ResourcesWithoutGraph.ResourceDescription
	|FROM
	|	ResourcesWithoutGraph AS ResourcesWithoutGraph
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	NestedQuery.Ref AS Ref,
	|	NestedQuery.Counterparty AS Counterparty,
	|	NestedQuery.Department AS Department,
	|	NestedQuery.Responsible AS Responsible,
	|	NestedQuery.Start AS BeginTime,
	|	NestedQuery.Finish AS EndTime,
	|	NestedQuery.Capacity AS Loading,
	|	MONTH(NestedQuery.Start) AS Month,
	|	YEAR(NestedQuery.Start) AS Year,
	|	BEGINOFPERIOD(NestedQuery.Start, DAY) AS Period,
	|	DATEDIFF(NestedQuery.Start, NestedQuery.Finish, SECOND) / 300 AS CellsQuantity,
	|	NestedQuery.NumberRowResourceTable AS LineNumber,
	|	CommonResouorceTable.EnterpriseResource AS EnterpriseResource,
	|	CommonResouorceTable.Capacity AS Capacity
	|FROM
	|	CommonResouorceTable AS CommonResouorceTable
	|		LEFT JOIN (SELECT
	|			ScheduleLoadingResources.Recorder AS Ref,
	|			ScheduleLoadingResources.EnterpriseResource AS EnterpriseResource,
	|			ScheduleLoadingResources.Capacity AS Capacity,
	|			CASE
	|				WHEN NOT DATEDIFF(BEGINOFPERIOD(ScheduleLoadingResources.Start, MINUTE), ScheduleLoadingResources.Start, SECOND) = 0
	|					THEN DATEADD(BEGINOFPERIOD(ScheduleLoadingResources.Start, MINUTE), SECOND, 60)
	|				ELSE ScheduleLoadingResources.Start
	|			END AS Start,
	|			CASE
	|				WHEN NOT DATEDIFF(BEGINOFPERIOD(ScheduleLoadingResources.Finish, MINUTE), ScheduleLoadingResources.Finish, SECOND) = 0
	|					THEN DATEADD(BEGINOFPERIOD(ScheduleLoadingResources.Finish, MINUTE), SECOND, 60)
	|				ELSE ScheduleLoadingResources.Finish
	|			END AS Finish,
	|			ScheduleLoadingResources.Counterparty AS Counterparty,
	|			ScheduleLoadingResources.Responsible AS Responsible,
	|			ScheduleLoadingResources.Department AS Department,
	|			ScheduleLoadingResources.NumberRowResourceTable AS NumberRowResourceTable
	|		FROM
	|			InformationRegister.ScheduleLoadingResources AS ScheduleLoadingResources
	|		WHERE
	|			BEGINOFPERIOD(ScheduleLoadingResources.Start, DAY) IN (&DateList)
	|			AND ScheduleLoadingResources.Counterparty IN(&FilterCounterparty)
	|			AND ScheduleLoadingResources.EnterpriseResource IN(&CommonListResources)
	|			AND ScheduleLoadingResources.Recorder IN(&DocumentList)) AS NestedQuery
	|		ON CommonResouorceTable.EnterpriseResource = NestedQuery.EnterpriseResource
	|
	|ORDER BY
	|	BeginTime";
	
	Query.SetParameter("StartDate", BegOfDay(ListPeriodDates[0].Value));
	Query.SetParameter("EndDate", EndOfDay(ListPeriodDates[ListPeriodDates.Count()-1].Value));
	Query.SetParameter("DateList", ListPeriodDates);
	Query.SetParameter("FilterKeyResourcesList", ResourcesList);
	Query.SetParameter("TableOfSchedules", TableOfSchedules);
	Query.SetParameter("ResourcesWithoutGraph", ResourcesWithoutGraph);
	Query.SetParameter("CommonListResources", CommonListResources);
	
	If DocumentList.Count() Then
		Query.SetParameter("DocumentList", DocumentList);
	Else
		Query.Text = StrReplace(Query.Text, "AND ScheduleLoadingResources.Recorder IN(&DocumentList)", "");
	EndIf;
	
	FilterParameters = New Structure("FilterFieldName", "Counterparty");
	FoundsCounterparties = LabelData.FindRows(FilterParameters);
	
	CounterpartiesList = New ValueList;
	
	For Each FoundString In FoundsCounterparties Do
		CounterpartiesList.Add(FoundString.Label);
	EndDo;
	
	If Not CounterpartiesList.Count() Then
		Query.Text = StrReplace(Query.Text, "AND ScheduleLoadingResources.Counterparty IN(&FilterCounterparty)", "");
	Else
		Query.SetParameter("FilterCounterparty", CounterpartiesList);
	EndIf;
	
	ReturnStructure = New Structure;
	
	ResourcesDataPacket = Query.ExecuteBatch();
	
	WorkPeriods = ResourcesDataPacket[3].Unload();
	ResourcePlanningCM.CheckIntervalBoarders(WorkPeriods, True);
	
	ScheduleLoading = ResourcesDataPacket[5].Unload();
	ResourcePlanningCM.CheckIntervalBoarders(ScheduleLoading);
	
	ReturnStructure.Insert("WorkPeriods", WorkPeriods);
	ReturnStructure.Insert("ScheduleLoading", ScheduleLoading);
	
	Return ReturnStructure;
	
EndFunction

&AtServer
Function StructureEventDataByContacts(ResourcesList, DocumentList)
	
	Query = New Query;
	
	Query.SetParameter("DescriptionSearchByContacts","%"+FilterContact+"%");
	Query.SetParameter("DateList", ListPeriodDates);
	Query.SetParameter("DocumentList", DocumentList);
	
	Query.Text = 
	"SELECT DISTINCT
	|	EventParties.Ref AS Ref
	|FROM
	|	InformationRegister.ScheduleLoadingResources AS ScheduleLoadingResources
	|		LEFT JOIN Document.Event.Participants AS EventParties
	|		ON ScheduleLoadingResources.Recorder = EventParties.Ref
	|WHERE
	|	BEGINOFPERIOD(ScheduleLoadingResources.Start, DAY) IN (&DateList)
	|	AND VALUETYPE(ScheduleLoadingResources.Recorder) = TYPE(Document.Event)
	|	AND (CAST(EventParties.Contact AS STRING(100)) LIKE &DescriptionSearchByContacts
	|			OR EventParties.HowToContact LIKE &DescriptionSearchByContacts)
	|	AND ScheduleLoadingResources.Recorder IN(&DocumentList)";
	
	If DocumentList.Count() Then
		Query.SetParameter("DocumentList", DocumentList);
	Else
		Query.Text = StrReplace(Query.Text, "AND ScheduleLoadingResources.Recorder IN(&DocumentList)", "");
	EndIf;
	
	DocumentArray = Query.Execute().Unload().UnloadColumn("Ref");
	
	Query = New Query;
	Query.SetParameter("DocumentArray", DocumentArray);
	Query.SetParameter("ResourcesList", ResourcesList);
	
	Query.Text = 
	"SELECT DISTINCT
	|	ScheduleLoadingResources.EnterpriseResource AS EnterpriseResource
	|FROM
	|	InformationRegister.ScheduleLoadingResources AS ScheduleLoadingResources
	|WHERE
	|	ScheduleLoadingResources.Document IN(&DocumentArray)
	|	AND ScheduleLoadingResources.EnterpriseResource IN (&ResourcesList)";
	
	If ResourcesList.Count() Then
		Query.SetParameter("ResourcesList", ResourcesList);
	Else
		Query.Text = StrReplace(Query.Text, "AND ScheduleLoadingResources.EnterpriseResource IN (&ResourcesList)", "");
	EndIf;
	
	ResourcesArray = Query.Execute().Unload().UnloadColumn("EnterpriseResource");
	
	ReturnStructure = New Structure("ResourcesList, DocumentList",ResourcesArray, DocumentArray);
	
	Return ReturnStructure;
	
EndFunction

&AtServer
Function GetResourceWorkGraph(ResourcesList, ScheduleDate)
	
	Query = New Query;
	Query.SetParameter("BeginOfPeriod", ScheduleDate);
	Query.SetParameter("ResourcesList", ResourcesList);
	Query.Text =
	"SELECT
	|	ResourcesWorkSchedules.Period AS Period,
	|	ResourcesWorkSchedules.WorkSchedule AS WorkSchedule,
	|	ResourcesWorkSchedules.EnterpriseResource AS EnterpriseResource,
	|	""GraphResources"" AS GraphKind
	|INTO Total
	|FROM
	|	InformationRegister.ResourcesWorkSchedules AS ResourcesWorkSchedules
	|WHERE
	|	NOT ResourcesWorkSchedules.EnterpriseResource.UseEmployeeGraph
	|	AND NOT ResourcesWorkSchedules.EnterpriseResource.NotValid
	|	AND ResourcesWorkSchedules.EnterpriseResource IN(&ResourcesList)
	|
	|UNION
	|
	|SELECT
	|	Employees.Period,
	|	Employees.WorkSchedule,
	|	KeyResources.Ref,
	|	""EmployeeGraph""
	|FROM
	|	Catalog.KeyResources AS KeyResources
	|		LEFT JOIN InformationRegister.Employees AS Employees
	|		ON KeyResources.ResourceValue = Employees.Employee
	|WHERE
	|	NOT KeyResources.NotValid
	|	AND KeyResources.UseEmployeeGraph
	|	AND KeyResources.Ref IN(&ResourcesList)
	|
	|UNION
	|
	|SELECT
	|	Employees.Period,
	|	Employees.WorkSchedule,
	|	KeyResources.Ref,
	|	""GraphEmployeeWithoutResourcesGraphs""
	|FROM
	|	Catalog.KeyResources AS KeyResources
	|		LEFT JOIN InformationRegister.Employees AS Employees
	|		ON KeyResources.ResourceValue = Employees.Employee
	|WHERE
	|	VALUETYPE(KeyResources.ResourceValue) = TYPE(Catalog.Employees)
	|	AND NOT KeyResources.NotValid
	|	AND NOT KeyResources.UseEmployeeGraph
	|	AND NOT KeyResources.Ref IN
	|				(SELECT
	|					ResourcesWorkSchedules.EnterpriseResource AS Ref
	|				FROM
	|					InformationRegister.ResourcesWorkSchedules AS ResourcesWorkSchedules
	|				WHERE
	|					NOT ResourcesWorkSchedules.EnterpriseResource.NotValid
	|					AND NOT ResourcesWorkSchedules.EnterpriseResource.UseEmployeeGraph)
	|	AND KeyResources.Ref IN(&ResourcesList)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	Total.Period AS Period,
	|	Total.WorkSchedule AS WorkSchedule,
	|	Total.EnterpriseResource AS EnterpriseResource,
	|	Total.GraphKind AS GraphKind
	|FROM
	|	Total AS Total
	|WHERE
	|	Total.Period <= &BeginOfPeriod
	|
	|ORDER BY
	|	EnterpriseResource,
	|	Period DESC
	|TOTALS BY
	|	EnterpriseResource";
	
	QueryResult = Query.Execute();
	SelectionResource = QueryResult.Select(QueryResultIteration.ByGroups, "EnterpriseResource");
	
	TableOfSchedules = New ValueTable;
	
	Array = New Array;
	Array.Add(Type("Date"));
	TypeDescription = New TypeDescription(Array, ,);
	Array.Clear();
	
	TableOfSchedules.Columns.Add("Period", TypeDescription);
	
	Array = New Array;
	Array.Add(Type("CatalogRef.KeyResources"));
	TypeDescription = New TypeDescription(Array, ,);
	Array.Clear();
	
	TableOfSchedules.Columns.Add("EnterpriseResource", TypeDescription);
	
	Array = New Array;
	Array.Add(Type("CatalogRef.WorkSchedules"));
	TypeDescription = New TypeDescription(Array, ,);
	Array.Clear();
	
	TableOfSchedules.Columns.Add("WorkSchedule", TypeDescription);
	
	While SelectionResource.Next() Do
		
		Selection = SelectionResource.Select();
		While Selection.Next() Do
			If Selection.Period <= ScheduleDate Then
				
				NewRow = TableOfSchedules.Add();
				NewRow.EnterpriseResource = Selection.EnterpriseResource;
				NewRow.Period = ScheduleDate;
				NewRow.WorkSchedule = Selection.WorkSchedule;
			EndIf;
		EndDo;
		
	EndDo;
	
	TempTablesManager = New TempTablesManager;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT ALLOWED
	|	KeyResources.Ref AS EnterpriseResource,
	|	KeyResources.Capacity AS Capacity,
	|	KeyResources.Description AS ResourceDescription,
	|	KeyResources.ControlIntervalsStepInDocuments AS ControlStep,
	|	KeyResources.MultiplicityPlanning AS MultiplicityPlanning
	|INTO EnterpriseResourceTempTable
	|FROM
	|	Catalog.KeyResources AS KeyResources
	|WHERE
	|	(&FilterByKeyResource
	|			OR KeyResources.Ref IN (&FilterKeyResourcesList))
	|	AND NOT KeyResources.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TableOfSchedules.Period AS Period,
	|	TableOfSchedules.EnterpriseResource AS EnterpriseResource,
	|	TableOfSchedules.WorkSchedule AS WorkSchedule
	|INTO SchedulesTempTable
	|FROM
	|	&TableOfSchedules AS TableOfSchedules
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	EnterpriseResourceTempTable.EnterpriseResource AS EnterpriseResource,
	|	EnterpriseResourceTempTable.Capacity AS Capacity,
	|	SchedulesTempTable.Period AS Period,
	|	SchedulesTempTable.WorkSchedule AS WorkSchedule,
	|	WorkSchedules.BeginTime AS BeginTime,
	|	WorkSchedules.EndTime AS EndTime,
	|	DeviationFromResourcesWorkSchedules.BeginTime AS RejectionsBeginTime,
	|	DeviationFromResourcesWorkSchedules.EndTime AS RejectionsEndTime,
	|	ISNULL(DeviationFromResourcesWorkSchedules.NotABusinessDay, FALSE) AS RejectionsNotABusinessDay,
	|	CASE
	|		WHEN NOT DeviationFromResourcesWorkSchedules.BeginTime = DATETIME(1, 1, 1, 0, 0, 0)
	|			THEN YEAR(DeviationFromResourcesWorkSchedules.BeginTime)
	|		ELSE YEAR(WorkSchedules.BeginTime)
	|	END AS Year,
	|	CASE
	|		WHEN NOT DeviationFromResourcesWorkSchedules.BeginTime = DATETIME(1, 1, 1, 0, 0, 0)
	|			THEN MONTH(DeviationFromResourcesWorkSchedules.BeginTime)
	|		ELSE MONTH(WorkSchedules.BeginTime)
	|	END AS Month,
	|	CASE
	|		WHEN ISNULL(DeviationFromResourcesWorkSchedules.EndTime, 0) = 0
	|			THEN WorkSchedules.EndTime
	|		ELSE DeviationFromResourcesWorkSchedules.EndTime
	|	END AS WorkPeriodPerDayEnd,
	|	CASE
	|		WHEN ISNULL(DeviationFromResourcesWorkSchedules.BeginTime, 0) = 0
	|			THEN WorkSchedules.BeginTime
	|		ELSE DeviationFromResourcesWorkSchedules.BeginTime
	|	END AS BeginWorkPeriodInDay,
	|	EnterpriseResourceTempTable.ControlStep AS ControlStep,
	|	EnterpriseResourceTempTable.MultiplicityPlanning AS MultiplicityPlanning
	|INTO Total
	|FROM
	|	EnterpriseResourceTempTable AS EnterpriseResourceTempTable
	|		LEFT JOIN SchedulesTempTable AS SchedulesTempTable
	|		ON EnterpriseResourceTempTable.EnterpriseResource = SchedulesTempTable.EnterpriseResource
	|		LEFT JOIN InformationRegister.WorkSchedules AS WorkSchedules
	|		ON (SchedulesTempTable.WorkSchedule = WorkSchedules.WorkSchedule)
	|			AND (WorkSchedules.BeginTime BETWEEN &StartDate AND &EndDate)
	|			AND (WorkSchedules.EndTime BETWEEN &StartDate AND &EndDate)
	|			AND (SchedulesTempTable.Period = BEGINOFPERIOD(WorkSchedules.BeginTime, Day))
	|			AND (SchedulesTempTable.Period = BEGINOFPERIOD(WorkSchedules.EndTime, Day))
	|		LEFT JOIN InformationRegister.DeviationFromResourcesWorkSchedules AS DeviationFromResourcesWorkSchedules
	|		ON EnterpriseResourceTempTable.EnterpriseResource = DeviationFromResourcesWorkSchedules.EnterpriseResource
	|			AND (SchedulesTempTable.Period = BEGINOFPERIOD(DeviationFromResourcesWorkSchedules.Day, Day))
	|			AND (DeviationFromResourcesWorkSchedules.BeginTime BETWEEN &StartDate AND &EndDate)
	|			AND (DeviationFromResourcesWorkSchedules.EndTime BETWEEN &StartDate AND &EndDate)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Total.EnterpriseResource AS EnterpriseResource,
	|	Total.Capacity AS Capacity,
	|	Total.Period AS Period,
	|	Total.WorkSchedule AS WorkSchedule,
	|	Total.BeginTime AS BeginTime,
	|	Total.EndTime AS EndTime,
	|	Total.RejectionsBeginTime AS RejectionsBeginTime,
	|	Total.RejectionsEndTime AS RejectionsEndTime,
	|	Total.RejectionsNotABusinessDay AS RejectionsNotABusinessDay,
	|	Total.Year AS Year,
	|	Total.Month AS Month,
	|	Total.WorkPeriodPerDayEnd AS WorkPeriodPerDayEnd,
	|	Total.BeginWorkPeriodInDay AS BeginWorkPeriodInDay,
	|	Total.ControlStep AS ControlStep,
	|	Total.MultiplicityPlanning AS MultiplicityPlanning,
	|	DATEDIFF(Total.BeginWorkPeriodInDay, Total.WorkPeriodPerDayEnd, SECOND) / (60 * Total.MultiplicityPlanning) * Total.Capacity AS AvailableLoading
	|FROM
	|	Total AS Total";
	
	Query.SetParameter("StartDate", BegOfDay(ScheduleDate));
	Query.SetParameter("EndDate", EndOfDay(ScheduleDate));
	Query.SetParameter("FilterByKeyResource", ResourcesList = Undefined);
	Query.SetParameter("FilterKeyResourcesList", ResourcesList);
	Query.SetParameter("TableOfSchedules", TableOfSchedules);
	
	FilterParameters = New Structure("FilterFieldName", "Counterparty");
	FoundsCounterparties = LabelData.FindRows(FilterParameters);
	
	CounterpartiesList = New ValueList;
	
	For Each FoundString In FoundsCounterparties Do
		CounterpartiesList.Add(FoundString.Label);
	EndDo;
	
	Result = Query.Execute().Unload();
	
	Result.GroupBy("BeginWorkPeriodInDay, WorkPeriodPerDayEnd, MultiplicityPlanning, ControlStep, AvailableLoading");
	
	PeriodStructureArray = New Array;
	
	For Each ResultRow In Result Do
		
		If Not ValueIsFilled(ResultRow.BeginWorkPeriodInDay) Then Continue EndIf;
		
		AvailableLoading = ?(ResultRow.AvailableLoading - Int(ResultRow.AvailableLoading)>0
		,Int(ResultRow.AvailableLoading)+1, ResultRow.AvailableLoading);
		
		StructurePeriodItem = New Structure("BeginOfPeriod, EndOfPeriod, AvailableLoading, MultiplicityPlanning, ControlStep,"
		,ResultRow.BeginWorkPeriodInDay, ResultRow.WorkPeriodPerDayEnd
		,ResultRow.AvailableLoading, ResultRow.MultiplicityPlanning, ResultRow.ControlStep);
		
		PeriodStructureArray.Add(StructurePeriodItem);
		
	EndDo;
	
	Return PeriodStructureArray;
	
EndFunction 

&AtServer
Function StructureResourceAndDocuments()
	
	WasFilterByFilter = False;
	
	Query = New Query;
	
	FilterParameters = New Structure("FilterFieldName", "Resource");
	foundResources = LabelData.FindRows(FilterParameters);
	
	ResourcesList = New ValueList;
	
	For Each FoundString In foundResources Do
		ResourcesList.Add(FoundString.Label);
	EndDo;
	
	WasFilterByFilter = ?(ResourcesList.Count(), True, False);
	
	FilterParameters = New Structure();
	
	FilterParameters.Insert("FilterFieldName", "ResourceKind");
	foundResources = LabelData.FindRows(FilterParameters);
	
	ResourcesKind = New ValueList;
	
	For Each FoundString In foundResources Do
		ResourcesKind.Add(FoundString.Label);
	EndDo;
	
	If ResourcesKind.Count() Then
		ResourcesList = GetResourcesListByResourceKind(ResourcesList, ResourcesKind);
		WasFilterByFilter = True;
	EndIf;
	
	FilterParameters.Clear();
	
	FilterParameters.Insert("FilterFieldName", "Counterparty");
	FoundStrings = LabelData.FindRows(FilterParameters);
	
	CounterpartiesList = New ValueList;
	
	For Each FoundString In FoundStrings Do
		CounterpartiesList.Add(FoundString.Label);
	EndDo;
	
	FilterParameters.Clear();
	
	FilterParameters.Insert("FilterFieldName", "Document");
	FoundStrings = LabelData.FindRows(FilterParameters);
	
	DocumentList = New ValueList;
	
	For Each FoundString In FoundStrings Do
		DocumentList.Add(FoundString.Label);
	EndDo;
	
	ListDocumentsBySelectedContacts = New ValueList;
	
	If DocumentList.Count() Or CounterpartiesList.Count() Then
		ResourcesList = GetListResourcesByCounterpartiesAndDocuments(ResourcesList, CounterpartiesList, DocumentList);
		WasFilterByFilter = True;
	EndIf;
	
	If ValueIsFilled(TrimAll(FilterContact)) Then
		
		StructureByContact = StructureEventDataByContacts(ResourcesList, DocumentList);
		
		DocumentList = StructureByContact.DocumentList;
		ResourcesList = StructureByContact.ResourcesList;
		
		WasFilterByFilter = True;
		
	EndIf;
	
	Query.Text = 
	"SELECT ALLOWED
	|	KeyResources.Ref AS Resource,
	|	KeyResources.Capacity AS Capacity,
	|	KeyResources.MultiplicityPlanning AS MultiplicityPlanning
	|FROM
	|	Catalog.KeyResources AS KeyResources
	|WHERE
	|	NOT KeyResources.DeletionMark
	|	AND KeyResources.Ref IN(&ResourcesList)
	|	AND NOT KeyResources.NotValid
	|
	|ORDER BY
	|	KeyResources.Description";
	
	If WasFilterByFilter Then
		Query.SetParameter("ResourcesList", ResourcesList);
	Else
		Query.Text = StrReplace(Query.Text, "AND KeyResources.Ref IN(&ResourcesList)", "");
	EndIf;
	
	ResourcesTable = Query.Execute().Unload();
	
	ReturnStructure = New Structure("ResourcesTable, DocumentList", ResourcesTable, DocumentList);
	
	Return ReturnStructure;
	
EndFunction

&AtServer
Function GetResourcesListByResourceKind(ResourcesList, ResourcesKind)
	
	ListResourcesKinds = New ValueList;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	EnterpriseResourcesKinds.EnterpriseResource AS EnterpriseResource
	|FROM
	|	InformationRegister.EnterpriseResourcesKinds AS EnterpriseResourcesKinds
	|WHERE
	|	EnterpriseResourcesKinds.EnterpriseResourceKind IN(&EnterpriseResourceKind)
	|	AND EnterpriseResourcesKinds.EnterpriseResource IN(&ResourcesList)";
	
	Query.SetParameter("EnterpriseResourceKind", ResourcesKind);
	
	If ResourcesList.Count() Then
		Query.SetParameter("ResourcesList", ResourcesList);
	Else
		Query.Text = StrReplace(Query.Text, "AND EnterpriseResourcesKinds.EnterpriseResource IN(&ResourcesList)", "");
	EndIf;
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return ListResourcesKinds;
	EndIf;
	
	Selection = Result.Select();
	While Selection.Next() Do
		ListResourcesKinds.Add(Selection.EnterpriseResource);
	EndDo;
	
	Return ListResourcesKinds;
	
EndFunction

&AtServer
Function GetListResourcesByCounterpartiesAndDocuments(ResourcesList, CounterpartiesList, DocumentList)
	
	ReturnList = New ValueList;
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	ScheduleLoadingResources.EnterpriseResource AS EnterpriseResource
	|FROM
	|	InformationRegister.ScheduleLoadingResources AS ScheduleLoadingResources
	|WHERE
	|	ScheduleLoadingResources.Counterparty IN(&CounterpartiesList)
	|	AND ScheduleLoadingResources.Recorder IN(&DocumentList)
	|	AND ScheduleLoadingResources.EnterpriseResource IN(&ResourcesList)
	|	AND ScheduleLoadingResources.Start BETWEEN &StartDate AND &EndDate
	|	AND ScheduleLoadingResources.Finish BETWEEN &StartDate AND &EndDate";
	
	Query.SetParameter("StartDate", BegOfDay(ListPeriodDates[0].Value));
	Query.SetParameter("EndDate", EndOfDay(ListPeriodDates[ListPeriodDates.Count()-1].Value));
	
	If ResourcesList.Count() Then
		Query.SetParameter("ResourcesList", ResourcesList);
	Else
		Query.Text = StrReplace(Query.Text, "AND ScheduleLoadingResources.EnterpriseResource IN(&ResourcesList)", "");
	EndIf;
	
	If CounterpartiesList.Count() Then
		Query.SetParameter("CounterpartiesList", CounterpartiesList);
	Else
		Query.Text = StrReplace(Query.Text, "ScheduleLoadingResources.Counterparty IN(&CounterpartiesList)
		|	AND", "");
	EndIf;
	
	If DocumentList.Count() Then
		Query.SetParameter("DocumentList", DocumentList);
	Else
		Query.Text = StrReplace(Query.Text, "AND ScheduleLoadingResources.Recorder IN(&DocumentList)", "");
	EndIf;
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return ReturnList;
	EndIf;
	
	Selection = Result.Select();
	While Selection.Next() Do
		ReturnList.Add(Selection.EnterpriseResource);
	EndDo;
	
	Return ReturnList;
	
EndFunction

&AtClient
Procedure CreateNewResourrce()
	
	OpenParameters = New Structure;
	
	Notification = New NotifyDescription("UpdateSpreadSheetDocumentEnd", ThisObject, OpenParameters);
	
	OpenForm("Catalog.KeyResources.ObjectForm", OpenParameters,,,,,Notification);
	
	
EndProcedure

&AtClient
Procedure UpdateSpreadSheetDocumentEnd(InformationValue, Parameters) Export
	
	DatesArray = Items.Calendar.SelectedDates;
	DisplayTableDocument(DatesArray);
	
	FillListPositioningPeriod();
	
EndProcedure

#EndRegion

#Region HandlersFilterCreate

&AtServer
Procedure SetListTagAndFilter(ListFilterFieldName, GroupTagParent, SelectedValue, ValueDescription="")
	
	If ValueDescription="" Then
		
		If TypeOf(SelectedValue) = Type("DocumentRef.ProductionOrder") Then
			ValueDescription=StrReplace(String(SelectedValue), "Production order", "Order");
		Else
			ValueDescription = StrReplace(String(SelectedValue), "Work order", "Order");
		EndIf;
		
	EndIf;
	
	WorkWithFilters.AttachFilterLabel(ThisObject, ListFilterFieldName, GroupTagParent, SelectedValue, ValueDescription);
	
	Items.GroupPageFilter.Title = ?(ValueIsFilled(SelectedValue), "Filter*", "Filter");
	
	DisplayTableDocument();
	
EndProcedure

&AtClient
Procedure Attachable_LabelURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	TagID = Mid(Item.Name, StrLen("Label_")+1);
	DeleteFilterTag(TagID);
	
EndProcedure

&AtServer
Procedure DeleteFilterTag(TagID)
	
	TagsRow = LabelData[Number(TagID)];
	FilterFieldName = TagsRow.FilterFieldName;
	
	AddedItemsRemovalFormGroupsList = GetListGroupParentName();
	
	LabelData.Delete(TagsRow);
	
	If Not LabelData.Count() Then
		Items.GroupPageFilter.Title = NStr("en='Filter';vi='Lọc';");
	EndIf;
	
	WorkWithFilters.RefreshLabelItems(ThisObject, AddedItemsRemovalFormGroupsList, "LabelData");
	
	DisplayTableDocument();
	
EndProcedure

&AtServer
Procedure DeleteFilterMarksDataByFieldName(FieldName)
	AddedItemsRemovalFormGroupsList = GetListGroupParentName();
	CleanFilterTableByFieldsName(FieldName);
	WorkWithFilters.RefreshLabelItems(ThisObject, AddedItemsRemovalFormGroupsList, "LabelData");
EndProcedure

&AtServer
Procedure CleanFilterTableByFieldsName(FieldName)
	
	FilterParameters = New Structure("FilterFieldName", FieldName);
	FoundStrings = LabelData.FindRows(FilterParameters);
	
	For Each RowToDelete In FoundStrings Do
		LabelData.Delete(RowToDelete);
	EndDo;
	
EndProcedure

#EndRegion

#Region HandlersWorkWithDocuments

&AtClient
Procedure CreateProductionOrder()
	
	If Not AddingFormBin Then 
		ResiurcesCollection = AddInDocumentBuffer;
	Else
		ResiurcesCollection = SelectedResources;
	EndIf;
	
	OpenParameters = New Structure("SelectedResources, OpenFormPlanner",ResiurcesCollection, True);
	
	OpenForm("Document.ProductionOrder.ObjectForm", OpenParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure CreateWorkOrder()
	
	If Not AddingFormBin Then 
		ResiurcesCollection = AddInDocumentBuffer;
	Else
		ResiurcesCollection = SelectedResources;
	EndIf;
	
	FilterParameters = New Structure("FilterFieldName", "Counterparty");
	FoundStrings = LabelData.FindRows(FilterParameters);
	
	If FoundStrings.Count() Then 
		FoundedMark = FoundStrings[0].Mark;
		Counterparty = FoundedMark[0].Value;
	Else
		Counterparty = Undefined;
	EndIf;
	
	FillingValues = New Structure("OperationKind, Counterparty", PredefinedValue("Enum.OperationKindsCustomerOrder.WorkOrder"), Counterparty);
	
	OpenParameters = New Structure("SelectedResources, FillingValues",ResiurcesCollection, FillingValues);
	
	OpenForm("Document.CustomerOrder.Form.FormWorkOrder", OpenParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure AddInProductionOrder()
	OpenParameters = New Structure();
	OpenForm("Document.ProductionOrder.Form.ChoiceForm", OpenParameters,ThisForm);
EndProcedure

&AtClient
Procedure AddInWorkOrder()
	OpenParameters = New Structure("ChoiceMode", True);
	OpenForm("Document.CustomerOrder.Form.ListFormWorkOrder", OpenParameters, ThisForm);
EndProcedure

&AtClient
Procedure CreateEvent()
	
	If Not AddingFormBin Then 
		ResiurcesCollection = AddInDocumentBuffer;
	Else
		ResiurcesCollection = SelectedResources;
	EndIf;
	
	FilterParameters = New Structure("FilterFieldName", "Counterparty");
	FoundStrings = LabelData.FindRows(FilterParameters);
	
	If FoundStrings.Count() Then 
		FoundedMark = FoundStrings[0].Mark;
		Counterparty = FoundedMark[0].Value;
	Else
		Counterparty = Undefined;
	EndIf;
	
	OpenParameters = New Structure("SelectedResources, OpenFormPlanner, Counterparty",ResiurcesCollection, True, Counterparty);
	OpenForm("Document.Event.Form.FormEventCounterpartyRecord", OpenParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure AddInEvent()
	OpenParameters = New Structure("ChoiceMode, EventType", True, PredefinedValue("Enum.EventTypes.Record"));
	OpenForm("Document.Event.ListForm", OpenParameters, ThisForm);
EndProcedure

#EndRegion

#Region HandlersSavingAndRestoreSettings

&AtServer
Procedure SaveFormSettings()
	SettingsStructure = New Structure;
	SettingsStructure.Insert("DataMarksCache", DataMarksCache.Unload());
	SettingsStructure.Insert("DataAttributesFormCache", DataAttributesFormCache.Unload());
	FormDataSettingsStorage.Save("ResourcePlanner", "SettingsStructure", SettingsStructure);
EndProcedure

&AtServer
Procedure ImportFormSettings()
	
	SettingsStructure = FormDataSettingsStorage.Load("ResourcePlanner", "SettingsStructure");
	
	If TypeOf(SettingsStructure) = Type("Structure") Then
		If SettingsStructure.Property("DataMarksCache") And SettingsStructure.Property("DataAttributesFormCache") Then
			DataMarksCache.Load(SettingsStructure.DataMarksCache);
			DataAttributesFormCache.Load(SettingsStructure.DataAttributesFormCache);
		EndIf;
	EndIf;
	
	
	For Each RowVariants In DataAttributesFormCache Do
		
		VariantName = RowVariants.VariantName;
		
		DefaultVariant = RowVariants.DefaultVariant;
		
		If DefaultVariant Then
			VariantName = RowVariants.VariantName+"(chính)";
			RepresentationVariant = RowVariants.RepresentationVariant;
		EndIf;
		
		If Not RowVariants.RepresentationVariant = 1 Then
			Items.RepresentationVariant.ChoiceList.Add(RowVariants.RepresentationVariant, VariantName, DefaultVariant);
		Else
			ForstListItem = Items.RepresentationVariant.ChoiceList.FindByValue(RowVariants.RepresentationVariant);
			ForstListItem.Presentation = VariantName;
			ForstListItem.Check = DefaultVariant;
		EndIf;
		
		SettingsImported = True;
		
	EndDo;
	
	RestoreFiledsRepresentationData(RepresentationVariant, True);
	
	Items.RepresentationVariant.ChoiceList.SortByValue(SortDirection.Asc);
	Items.GroupRepresentationVariant.Visible = UseVariants;
	Items.CommandMoveInDocument.Visible = False;
	Items.DecorationSelected.Title = NStr("en='Pickuped: ';vi='Đã lấy lên: ';") + String(SelectedResources.Count());
	
	If WorksScheduleRadioButton = "Day" Then
		Items.GroupStepIntervalMin.Visible = False
	EndIf;
	
EndProcedure

#EndRegion

#Region HandlersPostioningOnArea

&AtClient
Procedure PositioningOnArea(DescriptionPeriodSearch, DocumentReference = Undefined, Resource = Undefined, DocumentLineNumber = 0)
	
	If Not ValueIsFilled(DocumentReference) Then
		
		If Not ValueIsFilled(DescriptionPeriodSearch) Then
			
			PositioningPeriod = Undefined;
			
			Return 
		EndIf;
		
		FilterParameters = New Structure("Date", DescriptionPeriodSearch);
		RowsIntervalTable = DaysCoordinates.FindRows(FilterParameters);
		
		CurrentPosition = Items.ResourcesImport.CurrentArea;
		
		CurRowCoordinate = String(?(CurrentPosition.Bottom=1, 3, Format(CurrentPosition.Bottom,"NG=")));
		
		If Not RowsIntervalTable.Count() Then Return EndIf;
		
		CurIntervalDate = RowsIntervalTable[0];
		
		If WorksScheduleRadioButton = "Day" Then
			CoordinateColumnPositioning = CurIntervalDate.CoordinateBegin;
		Else
			
			TimePositioning = 0;
			
			FilterParameters = New Structure("Date", DescriptionPeriodSearch);
			
			FoundRowsByPeriod = PeriodByDays.FindRows(FilterParameters);
			
			TimeBeginPeriod = Date(1,1,1);
			
			If FoundRowsByPeriod.Count() Then
				ListPositioningByPeriod = FoundRowsByPeriod[0].ChioceListTimeMoveByCoordinate;
				If ListPositioningByPeriod.Count() Then
					TimeBeginPeriod = ListPositioningByPeriod[0].Value;
				EndIf
			EndIf;
			
			TimePositioning = (Hour(PositioningPeriod)*60+Minute(PositioningPeriod)) - (Hour(TimeBeginPeriod)*60+Minute(TimeBeginPeriod));
			
			CoordinateColumnPositioning = Format(CurIntervalDate.CoordinateBegin + TimePositioning/MinInterval,"NG=");
			
		EndIf;
		
		ThisForm.CurrentItem = Items.ResourcesImport;
		
		Items.ResourcesImport.CurrentArea = ResourcesImport.Area("R"+CurRowCoordinate+"C"+String(CoordinateColumnPositioning));
		
	Else
		
		FilterParameters = New Structure("Ref, Resource, DocumentLineNumber", DocumentReference, Resource, DocumentLineNumber);
		
		RowsIntervalTable = DocumentsCoordinate.FindRows(FilterParameters);
		
		CurrentPosition = Items.ResourcesImport.CurrentArea;
		
		CurRowCoordinate = String(?(CurrentPosition.Bottom=1, 3, Format(CurrentPosition.Bottom,"NG=")));
		
		If Not RowsIntervalTable.Count() Then Return EndIf;
		
		CurIntervalDate = RowsIntervalTable[0];
		
		CoordinateColumnPositioning = Format(CurIntervalDate.CoordinateBegin,"NG=");
		
		ThisForm.CurrentItem = Items.ResourcesImport;
		
		Items.ResourcesImport.CurrentArea = ResourcesImport.Area("R"+CurRowCoordinate+"C"+String(CoordinateColumnPositioning));
		
	EndIf;
	
EndProcedure

&AtClient
Function CurentPositioningDate(CurrentCoordinate)
	
	For Each CoordinateRow In DaysCoordinates Do
		
		If CurrentCoordinate>CoordinateRow.CoordinateEnd Then Continue EndIf;
		
		If CurrentCoordinate>=CoordinateRow.CoordinateBegin Then
			CurrentPostionDate = CoordinateRow.Date;
			Return CoordinateRow.Date;
		EndIf;
		
	EndDo;
	
	CurrentPostionDate = Date(1,1,1);
	Return "";
	
EndFunction

&AtServer
Function CreateChoiseListTimeMoveByCoordinate(PeriodsQuantity, TSRow = Undefined, IntervalBegin)
	
	CounterDate = Date(1,1,1)+(IntervalBegin - BegOfDay(IntervalBegin));

	TSRow.ChioceListTimeMoveByCoordinate.Add(CounterDate);
	
	For  IntervalIndex = 1 To PeriodsQuantity - 1 Do
		
		CounterDate = CounterDate+MinInterval*60;
		TSRow.ChioceListTimeMoveByCoordinate.Add(CounterDate);
		
	EndDo;
	
EndFunction

&AtServer
Function CreateChoiceListPeriodsTime()
	
	CounterDate = Date(1,1,1);
	
	For  IntervalIndex =1 To 288 Do
		
		CounterDate = CounterDate+MinInterval*60;
		
		Items.BeginOfRepresentationInterval.ChoiceList.Add(CounterDate,Format(CounterDate,"DF=ЧЧ:мм"));
		Items.RepresentationIntervalEnd.ChoiceList.Add(CounterDate,Format(CounterDate,"DF=ЧЧ:мм"));
		
	EndDo;
	
EndFunction

&AtClient
Procedure FillListPeriodDates(BeginOfPeriod, PeriodEnding)
	
	ListPeriodDates.Clear();
	
	While BeginOfPeriod <= PeriodEnding Do
		
		ListPeriodDates.Add(BeginOfPeriod);
		BeginOfPeriod = BegOfDay(BeginOfPeriod + 86450);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region HandlersWorkWithVariants

&AtClient
Procedure SetupVariantDescription(NewDescription, Parameters) Export
	
	If ValueIsFilled(NewDescription) Then
		
		FilterParameters = New Structure("RepresentationVariant", RepresentationVariant);
		FoundStrings = DataAttributesFormCache.FindRows(FilterParameters);
		
		ItDefaultVariant = FoundStrings.Count() And FoundStrings[0].DefaultVariant;
		
		Items.RepresentationVariant.ChoiceList[RepresentationVariant-1].Presentation = ?(ItDefaultVariant, NewDescription+"(chính)", NewDescription);
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateVariant(Copy = False)
	
	NewVariantNumber = Items.RepresentationVariant.ChoiceList.Count();
	
	If NewVariantNumber = 7 Then 
		RepresentationVariant = 6;
		Return 
	EndIf;
	
	Items.RepresentationVariant.ChoiceList.Insert(NewVariantNumber-1, NewVariantNumber, NStr("en='Variant ';vi='Phương án ';") + String(NewVariantNumber));
	
	FilterParameters = New Structure("RepresentationVariant", LastRepresentationVariant);
	FoundStrings = DataAttributesFormCache.FindRows(FilterParameters);
	
	ItDefaultVariant = (FoundStrings.Count() And FoundStrings[0].DefaultVariant) Or Not DataAttributesFormCache.Count();
	
	SaveDataVariantRepresentationClient(LastRepresentationVariant, ItDefaultVariant);
	
	If Not Copy Then
		SetupFormAttributesValuesByDefault();
	EndIf;
	
	RepresentationVariant = NewVariantNumber;
	
	SaveDataVariantRepresentationClient(RepresentationVariant);
	
	LastRepresentationVariant = RepresentationVariant;
	
	DisplayTableDocument();
	
	VariantList = New ValueList;
	For Each VariantValue In Items.RepresentationVariant.ChoiceList Do
		VariantList.Add(VariantValue.Value, VariantValue.Presentation);
	EndDo;
	UpdateVariantsList(VariantList);
	
EndProcedure

&AtClient
Procedure SaveDataVariantRepresentationClient(VariantNumber, DefaultVariant = False)
	
	DeleteRowByVariantRepresentation(VariantNumber);
	
	NewRow = DataAttributesFormCache.Add();
	FillPropertyValues(NewRow, ThisForm);
	NewRow.RepresentationVariant = VariantNumber;
	
	VariantPresentation = Items.RepresentationVariant.ChoiceList.FindByValue(VariantNumber).Presentation;
	VariantPresentation= StrReplace(VariantPresentation, "(chính)", "");
	
	NewRow.VariantName = VariantPresentation;
	NewRow.DefaultVariant = DefaultVariant;
	
	For Each RowFilterMarks In LabelData Do
		NewRow = DataMarksCache.Add();
		FillPropertyValues(NewRow, RowFilterMarks);
		NewRow.RepresentationVariant = VariantNumber;
	EndDo;
	
	DataAttributesFormCache.Sort("RepresentationVariant Asc");
	
EndProcedure


&AtServer
Procedure RestoreFiledsRepresentationData(VariantNumber, FormOpening = False)
	
	AddedItemsRemovalFormGroupsList = GetListGroupParentName();
	
	LabelData.Clear();
	Items.Calendar.SelectedDates.Clear();
	
	FilterParameters = New Structure("RepresentationVariant", VariantNumber);
	FoundStrings = DataAttributesFormCache.FindRows(FilterParameters);
	
	If Not ThisSelection Then
		
		For Each RowCache In FoundStrings Do
			FillPropertyValues(ThisForm, RowCache);
		EndDo;
		
		FoundStrings = DataMarksCache.FindRows(FilterParameters);
		For Each RowCache In FoundStrings Do
			NewRow = LabelData.Add();
			FillPropertyValues(NewRow, RowCache);
		EndDo;
		
		If FoundStrings.Count() Then
			Items.GroupPageFilter.Title = NStr("en='Filter*';vi='Lọc*';");
			Items.GroupPages.CurrentPage = Items.GroupPageFilter; 
		Else
			Items.GroupPageFilter.Title = NStr("en='Filter';vi='Lọc';");
		EndIf;
		
		WorkWithFilters.RefreshLabelItems(ThisObject, AddedItemsRemovalFormGroupsList, "LabelData");
		
	Else
		For Each RowCache In FoundStrings Do
			ColorNotworkingTime = RowCache.ColorNotworkingTime;
			ColorFullLoading = RowCache.ColorFullLoading;
			ColorOverloading = RowCache.ColorOverloading;
			ColorWorkTime = RowCache.ColorWorkTime;
			ColorPartialLoadingBefore = RowCache.ColorPartialLoadingBefore;
			ColorPartialLoadingAfter = RowCache.ColorPartialLoadingAfter;
		EndDo;
	EndIf;

	Items.GroupIntervalSetting.Enabled = ?(Not WorksScheduleRadioButton = "Month", True, False);;
	
	Items.ShowDay.Check = ?(WorksScheduleRadioButton = "Day", True, False);
	Items.ShowMonth.Check = ?(WorksScheduleRadioButton = "Month", True, False);
	Items.ShowPanningInterval.Check = ?(WorksScheduleRadioButton = "Interval planning", True, False);
	
	Items.GroupRepresentationInterval.Enabled = Not OnlyWorkTime;
	
	PeriodLabel = UpdatePeriodRepresentation(Period);
	
	If FormOpening Then
		ListPeriodDates.Clear();
	Else
		DatesArray = ListPeriodDates.UnloadValues();
		
		For Each ArrayData In DatesArray Do
			Items.Calendar.SelectedDates.Add(ArrayData);
		EndDo;
		
		DisplayTableDocument(DatesArray);
	EndIf;
	
EndProcedure

&AtServer
Procedure DeleteRowByVariantRepresentation(VariantNumber)
	
	FilterParameters = New Structure("RepresentationVariant", VariantNumber);
	
	FoundStrings = DataAttributesFormCache.FindRows(FilterParameters);
	For Each RowCache In FoundStrings Do
		DataAttributesFormCache.Delete(RowCache);
	EndDo;
	
	FoundStrings = DataMarksCache.FindRows(FilterParameters);
	For Each RowCache In FoundStrings Do
		DataMarksCache.Delete(RowCache);
	EndDo;
	
EndProcedure

#EndRegion

#Region HandlersworkWithBin

&AtClient
Procedure PickupInBin(Resource, Area, GraphControl)
	
	RowCoordinate = Area.Top;
	
	BeginTime = PositioningPeriod;
	EndTime = PositioningPeriod + (Area.Right - Area.Left)*300 + 300;
	PeriodDay = PeriodPresentation;
	
	EndTime = ?(Not ValueIsFilled(EndTime), BeginTime, EndTime);
	
	If WorksScheduleRadioButton = "Interval planning" And (ValueIsFilled(EndTime) And ValueIsFilled(PeriodDay)) 
		Or (WorksScheduleRadioButton = "Day" And ValueIsFilled(PeriodDay))Then 
		
		TimeFinishSec = EndTime - Date(1,1,1);
		DateAndTimeFinish = PeriodDay + TimeFinishSec;
		DateAndTimeFinish = ?(DateAndTimeFinish>EndOfDay(PeriodDay), EndOfDay(PeriodDay), DateAndTimeFinish);
		
		StructureData = New Structure();
		StructureData.Insert("Resource", Resource);
		StructureData = GetREsourceData(StructureData);
		
		If WorksScheduleRadioButton = "Day" Then
			BeginOfPeriod = BegOfDay(PeriodDay);
			EndOfPeriod = EndOfDay(PeriodDay);
		Else
			BeginOfPeriod = PeriodDay+(BeginTime - Date(1,1,1));
			EndOfPeriod = DateAndTimeFinish;
			
			If EndOfPeriod >= BegOfDay(BeginOfPeriod+86400) Then
				EndOfPeriod = ?(BegOfDay(EndOfPeriod) = EndOfPeriod, EndOfPeriod - 1, EndOfPeriod - 300);
			EndIf;

		EndIf;
		
		FilterParameters = New Structure("Resource, BeginOfPeriod, EndOfPeriod", Resource, BeginOfPeriod, EndOfPeriod);
		FoundStrings = SelectedResources.FindRows(FilterParameters);
		
		If FoundStrings.Count() Then
			SelectedRow = FoundStrings[0];
			SelectedRow.Loading = SelectedRow.Loading+1;
		Else
			
			If WorksScheduleRadioButton = "Interval planning" Then
				SelectedRow = SelectedResources.Add();
				SelectedRow.Resource = Resource;
				SelectedRow.BeginOfPeriod = BeginOfPeriod;
				SelectedRow.EndOfPeriod = EndOfPeriod;
				SelectedRow.Loading =1;
				SelectedRow.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.NoRepeat");
				
				SelectedRow.ControlStep = StructureData.ControlStep;
				SelectedRow.MultiplicityPlanning = StructureData.MultiplicityPlanning;
				
			Else
				
				ResourcesList = New ValueList;
				ResourcesList.Add(Resource);
				
				WorkPeriods = GetResourceWorkGraph(ResourcesList, BegOfDay(BeginOfPeriod));
				
				If WorkPeriods.Count() Then
					
					For Each workPeriod In WorkPeriods Do
						
						SelectedRow = SelectedResources.Add();
						SelectedRow.Resource = Resource;
						SelectedRow.BeginOfPeriod = workPeriod.BeginOfPeriod;
						SelectedRow.EndOfPeriod = workPeriod.EndOfPeriod;
						SelectedRow.Loading = 1;
						SelectedRow.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.NoRepeat");
						
						SelectedRow.ControlStep = workPeriod.ControlStep;
						SelectedRow.MultiplicityPlanning = workPeriod.MultiplicityPlanning;
						
					EndDo;
					
				Else
					
					SelectedRow = SelectedResources.Add();
					SelectedRow.Resource = Resource;
					SelectedRow.BeginOfPeriod = BeginOfPeriod;
					SelectedRow.EndOfPeriod = EndOfPeriod;
					SelectedRow.Loading =1;
					SelectedRow.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.NoRepeat");
					
					SelectedRow.ControlStep = StructureData.ControlStep;
					SelectedRow.MultiplicityPlanning = StructureData.MultiplicityPlanning;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	SetupBinRepresentation();
	
EndProcedure

&AtClient
Procedure PickupInBinFromContexBar(Resource, Area, BeginTime, EndTime, StructureData)
	
	RowCoordinate = Area.Top;
	
	EndTime = ?(Not ValueIsFilled(EndTime), EndOfDay(BeginTime), EndTime);
	
	BeginOfPeriod = ?(WorksScheduleRadioButton = "Day", BegOfDay(BeginTime), BeginTime); 
	
	EndOfPeriod = EndTime;
	
	SelectedDateList =  New ValueList;
	
	If BegOfDay(BeginOfPeriod) = BegOfDay(EndOfPeriod) Then
		SelectedDateList.Add(BegOfDay(BeginOfPeriod));
	Else
		
		PeriodDate = BegOfDay(BeginOfPeriod);
		PeriodComplete = BegOfDay(EndOfPeriod);
		
		While PeriodDate <= PeriodComplete Do
			
			FoundValue = ListPeriodDates.FindByValue(PeriodDate);
			
			If Not FoundValue = Undefined Then
				SelectedDateList.Add(PeriodDate)
			EndIf;
			
			PeriodDate = BegOfDay(PeriodDate + 86400);
			
		EndDo;
	EndIf;
	
	If WorksScheduleRadioButton = "Interval planning" Then
		
		For Each ListPeriod In SelectedDateList Do
			
			IsBreak = IsBreakByRightDay(ListPeriod.Value, SelectedDateList);
			
			If ListPeriod.Value<=BegOfDay(EndOfPeriod) And Not IsBreak Then Continue EndIf;
			
			EndOfPeriod = RelaitedIntervalEnd(ListPeriod.Value, SelectedDateList);
			EndOfPeriod = ?(BegOfDay(EndOfPeriod) = BegOfDay(EndTime), EndTime, EndOfPeriod);
			
			BeginOfPeriod = ?(BegOfDay(ListPeriod.Value) = BegOfDay(BeginTime), BeginTime, BegOfDay(ListPeriod.Value));
			
			FilterParameters = New Structure("Resource, BeginOfPeriod, EndOfPeriod", Resource, BeginOfPeriod, EndOfPeriod);
			FoundStrings = SelectedResources.FindRows(FilterParameters);
			
			If FoundStrings.Count() Then
				SelectedRow = FoundStrings[0];
				SelectedRow.Loading = SelectedRow.Loading+1;
				Continue
			EndIf;
			
			SelectedRow = SelectedResources.Add();
			SelectedRow.Resource = Resource;
			SelectedRow.BeginOfPeriod = BeginOfPeriod;
			SelectedRow.EndOfPeriod = EndOfPeriod;
			SelectedRow.Loading =1;
			SelectedRow.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.NoRepeat");
			
			SelectedRow.ControlStep = StructureData.ControlStep;
			SelectedRow.MultiplicityPlanning = StructureData.MultiplicityPlanning;
			
		EndDo;
	Else
		
		ResourcesList = New ValueList;
		ResourcesList.Add(Resource);
			
		MapWorkPeriodsByDays = New Map;
		
		For Each ListPeriod In SelectedDateList Do
			WorkPeriods = GetResourceWorkGraph(ResourcesList, BegOfDay(ListPeriod.Value));
			
			If WorkPeriods.Count() Then
				MapWorkPeriodsByDays.Insert(ListPeriod.Value, WorkPeriods);
			EndIf;
			
		EndDo;
		
		WasOutputByGraph = False;
		
		For Each ListPeriod In SelectedDateList Do
			
			MapValue = MapWorkPeriodsByDays.Get(ListPeriod.Value);
			
			OutputBySchedule = False;
			If Not MapValue = Undefined Then
				If Not MapValue[0].EndOfPeriod = EndOfDay(MapValue[0].EndOfPeriod) Then
					OutputBySchedule = True
				EndIf;
			EndIf;
			
			If OutputBySchedule Then
				
				WorkPeriods = MapValue;
				
				For Each workPeriod In WorkPeriods Do
					
					FilterParameters = New Structure("Resource, BeginOfPeriod, EndOfPeriod", Resource, workPeriod.BeginOfPeriod, workPeriod.EndOfPeriod);
					FoundStrings = SelectedResources.FindRows(FilterParameters);
					
					If FoundStrings.Count() Then
						SelectedRow = FoundStrings[0];
						SelectedRow.Loading = SelectedRow.Loading+1;
						Continue
					EndIf;
					
					SelectedRow = SelectedResources.Add();
					SelectedRow.Resource = Resource;
					SelectedRow.BeginOfPeriod = workPeriod.BeginOfPeriod;
					SelectedRow.EndOfPeriod = workPeriod.EndOfPeriod;
					SelectedRow.Loading = 1;
					SelectedRow.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.NoRepeat");
					
					SelectedRow.ControlStep = workPeriod.ControlStep;
					SelectedRow.MultiplicityPlanning = workPeriod.MultiplicityPlanning;
					
					WasOutputByGraph = True;
					
				EndDo;
				
				
			Else
				
				IsBreak = IsBreakByRightDay(ListPeriod.Value, SelectedDateList) Or WasOutputByGraph;
				
				If ListPeriod.Value<=BegOfDay(EndOfPeriod) And Not IsBreak Then Continue EndIf;
				
				WasOutputByGraph = False;
				
				EndOfPeriod = RelaitedIntervalEnd(ListPeriod.Value, SelectedDateList, MapWorkPeriodsByDays);
				
				FilterParameters = New Structure("Resource, BeginOfPeriod, EndOfPeriod", Resource, BegOfDay(ListPeriod.Value), EndOfPeriod);
				FoundStrings = SelectedResources.FindRows(FilterParameters);
				
				If FoundStrings.Count() Then
					SelectedRow = FoundStrings[0];
					SelectedRow.Loading = SelectedRow.Loading+1;
					Continue
				EndIf;
				
				SelectedRow = SelectedResources.Add();
				SelectedRow.Resource = Resource;
				SelectedRow.BeginOfPeriod = BegOfDay(ListPeriod.Value);
				SelectedRow.EndOfPeriod = EndOfPeriod;
				SelectedRow.Loading =1;
				SelectedRow.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.NoRepeat");
				
				SelectedRow.ControlStep = StructureData.ControlStep;
				SelectedRow.MultiplicityPlanning = StructureData.MultiplicityPlanning;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	SetupBinRepresentation(,False);
	
EndProcedure

&AtClient
Function IsBreakByRightDay(PeriodDay, SelectedDateList)

	DateCount = SelectedDateList.Count();
	
	If DateCount <= 1 Then Return True EndIf;
	
	FoundedValueLeft = SelectedDateList.FindByValue(BegOfDay(PeriodDay - 86400));
	
	Return ?(FoundedValueLeft = Undefined, True, False);
	
EndFunction

&AtClient
Function RelaitedIntervalEnd(PeriodDay, SelectedDateList, MapWorkPeriodsByDays = Undefined)

	DateCount = SelectedDateList.Count();
	LastRelaitedValue = PeriodDay;
	
	If DateCount <= 1 Then Return EndOfDay(LastRelaitedValue) EndIf;
	
	If Not MapWorkPeriodsByDays = Undefined Then
		
		While True Do
			
			FoundValueRight = SelectedDateList.FindByValue(BegOfDay(LastRelaitedValue + 86400));
			
			If FoundValueRight = Undefined Then Return EndOfDay(LastRelaitedValue) EndIf;
			
			MapValue = MapWorkPeriodsByDays.Get(BegOfDay(LastRelaitedValue+86400));
			
			If Not MapValue = Undefined
				And Not MapValue[0].EndOfPeriod = EndOfDay(MapValue[0].EndOfPeriod) Then
				Return EndOfDay(LastRelaitedValue);
			EndIf;
			
			LastRelaitedValue = FoundValueRight.Value;
			
		EndDo;
		
	Else
		
		While True Do
			
			FoundValueRight = SelectedDateList.FindByValue(BegOfDay(LastRelaitedValue + 86400));
			
			If FoundValueRight = Undefined Then Return EndOfDay(LastRelaitedValue) EndIf;
			
			LastRelaitedValue = FoundValueRight.Value;
			
		EndDo;
		
	EndIf;
	
EndFunction

&AtClient
Procedure AfterQuestionClosing(Result, Parameters) Export
	If Result = DialogReturnCode.No Then
		Return;
	EndIf;
	
	SelectedAction = Parameters.SelectedAction;
	
	Area = Parameters.Area;
	GraphControl = Parameters.GraphControl;
	
	If SelectedAction = NStr("en='Pick';ru='Подобрать';vi='Lựa chọn'") Then
		PickupInBin(Parameters.Resource, Parameters.Area, GraphControl);
		Return
	EndIf;
	
	If SelectedAction = NStr("en='Create Production order';ru='Создать Заказ на производство';vi='Tạo đơn hàng sản xuất'") Then
		PickupInBuffer(Parameters.Resource, Area, GraphControl);
		CreateProductionOrder();
		AddInDocumentBuffer.Clear();
		Return
	EndIf;
	
	If SelectedAction = NStr("en='Create Work order';ru='Создать Заказ наряд';vi='Tạo đơn hàng'") Then
		PickupInBuffer(Parameters.Resource, Area, GraphControl);
		CreateWorkOrder();
		AddInDocumentBuffer.Clear();
		Return
	EndIf;
	
	If SelectedAction = NStr("en='Add In Work order';ru='Добавить в Заказ наряд';vi='Thêm để đặt hàng'") Then
		PickupInBuffer(Parameters.Resource, Area, GraphControl);
		AddInWorkOrder();
		AddInDocumentBuffer.Clear();
		Return
	EndIf;
	
	
	If SelectedAction = NStr("en='Add In Production order';ru='Добавить в Заказ на производство';vi='Thêm vào đơn đặt hàng sản xuất'") Then
		PickupInBuffer(Parameters.Resource, Area, GraphControl);
		AddInProductionOrder();
		AddInDocumentBuffer.Clear();
		Return;
	EndIf;
	
	If SelectedAction = NStr("en='Create event ""Record""';ru='Создать событие ""Запись""';vi='Tạo sự kiện ""Bản ghi""'") Then
		PickupInBuffer(Parameters.Resource, Area, GraphControl);
		CreateEvent();
		AddInDocumentBuffer.Clear();
		Return
	EndIf;
	
	If SelectedAction = NStr("en='Add In event ""Record""';ru='Добавить в событие ""Запись""';vi='Thêm vào sự kiện ""Bản ghi""'") Then
		PickupInBuffer(Parameters.Resource, Area, GraphControl);
		AddInEvent();
		AddInDocumentBuffer.Clear();
		Return
	EndIf;

	
EndProcedure

&AtServerNoContext
Function GetREsourceData(StructureData)
	
	StructureData.Insert("ControlStep", StructureData.Resource.ControlIntervalsStepInDocuments);
	StructureData.Insert("Capacity", StructureData.Resource.Capacity);
	StructureData.Insert("MultiplicityPlanning", StructureData.Resource.MultiplicityPlanning);
	
	Return StructureData;
EndFunction

&AtClient
Procedure PickupInBuffer(Resource,Area, GraphControl)
	
	RowCoordinate = Area.Top;
	
	BeginTime = PositioningPeriod;
	EndTime = PositioningPeriod + (Area.Right - Area.Left)*300 + 300;
	PeriodDay = PeriodPresentation;
	
	EndTime = ?(Not ValueIsFilled(EndTime), BeginTime, EndTime);
	
	If WorksScheduleRadioButton = "Interval planning" And (ValueIsFilled(EndTime) And ValueIsFilled(PeriodDay)) 
		Or (WorksScheduleRadioButton = "Day" And ValueIsFilled(PeriodDay))Then 
		
		TimeFinishSec = EndTime - Date(1,1,1);
		DateAndTimeFinish = PeriodDay + TimeFinishSec;
		DateAndTimeFinish = ?(DateAndTimeFinish>EndOfDay(PeriodDay), EndOfDay(PeriodDay), DateAndTimeFinish);
		
		StructureData = New Structure();
		StructureData.Insert("Resource", Resource);
		StructureData = GetREsourceData(StructureData);
		
		If WorksScheduleRadioButton = "Day" Then
			BeginOfPeriod = BegOfDay(PeriodDay);
			EndOfPeriod = EndOfDay(PeriodDay);
		Else
			BeginOfPeriod = PeriodDay+(BeginTime - Date(1,1,1));
			EndOfPeriod = BeginOfPeriod + StructureData.MultiplicityPlanning * 60;
			
			EndOfPeriod = ?(EndOfPeriod>DateAndTimeFinish, DateAndTimeFinish, EndOfPeriod);
			
			If EndOfPeriod >= BegOfDay(BeginOfPeriod+86400) Then
				EndOfPeriod = ?(BegOfDay(EndOfPeriod) = EndOfPeriod, EndOfPeriod - 1, EndOfPeriod - 300);
			EndIf;
		EndIf;
		
		FilterParameters = New Structure("Resource, BeginOfPeriod, EndOfPeriod", Resource, BeginOfPeriod, EndOfPeriod);
		
		FoundStrings = AddInDocumentBuffer.FindRows(FilterParameters);
		
		If FoundStrings.Count() Then
			SelectedRow = FoundStrings[0];
			SelectedRow.Loading = SelectedRow.Loading+1;
		Else
			
			If WorksScheduleRadioButton = "Interval planning" Then
				SelectedRow = AddInDocumentBuffer.Add();
				SelectedRow.Resource = Resource;
				SelectedRow.BeginOfPeriod = BeginOfPeriod;
				SelectedRow.EndOfPeriod = EndOfPeriod;
				SelectedRow.Loading =1;
				SelectedRow.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.NoRepeat");
				
				SelectedRow.ControlStep = StructureData.ControlStep;
				SelectedRow.MultiplicityPlanning = StructureData.MultiplicityPlanning;
			Else
				
				ResourcesList = New ValueList;
				ResourcesList.Add(Resource);
				
				WorkPeriods = GetResourceWorkGraph(ResourcesList, BegOfDay(BeginOfPeriod));
				
				If WorkPeriods.Count() Then
					
					For Each workPeriod In WorkPeriods Do
						
						SelectedRow = AddInDocumentBuffer.Add();
						SelectedRow.Resource = Resource;
						SelectedRow.BeginOfPeriod = workPeriod.BeginOfPeriod;
						SelectedRow.EndOfPeriod = workPeriod.EndOfPeriod;
						SelectedRow.Loading = 1;
						SelectedRow.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.NoRepeat");
						
						SelectedRow.ControlStep = workPeriod.ControlStep;
						SelectedRow.MultiplicityPlanning = workPeriod.MultiplicityPlanning;
						
					EndDo;
					
				Else
					
					SelectedRow = AddInDocumentBuffer.Add();
					SelectedRow.Resource = Resource;
					SelectedRow.BeginOfPeriod = BeginOfPeriod;
					SelectedRow.EndOfPeriod = EndOfPeriod;
					SelectedRow.Loading =1;
					SelectedRow.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.NoRepeat");
					
					SelectedRow.ControlStep = StructureData.ControlStep;
					SelectedRow.MultiplicityPlanning = StructureData.MultiplicityPlanning;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf
	
EndProcedure

&AtClient
Procedure PickupInBufferContexBar(Resource, Area, GraphControl, BeginTime, EndTime)
	
	RowCoordinate = Area.Top;
	
	EndTime = ?(Not ValueIsFilled(EndTime), EndOfDay(BeginTime), EndTime);
	
	StructureData = New Structure();
	StructureData.Insert("Resource", Resource);
	StructureData = GetREsourceData(StructureData);
	
	BeginOfPeriod = ?(WorksScheduleRadioButton = "Day", BegOfDay(BeginTime), BeginTime); 
	
	EndOfPeriod = EndTime;
	
	SelectedDateList =  New ValueList;
	
	If BegOfDay(BeginOfPeriod) = BegOfDay(EndOfPeriod) Then
		SelectedDateList.Add(BegOfDay(BeginOfPeriod));
	Else
		
		PeriodDate = BegOfDay(BeginOfPeriod);
		PeriodComplete = BegOfDay(EndOfPeriod);
		
		While PeriodDate <= PeriodComplete Do
			
			FoundValue = ListPeriodDates.FindByValue(PeriodDate);
			
			If Not FoundValue = Undefined Then
				SelectedDateList.Add(PeriodDate)
			EndIf;
			
			PeriodDate = BegOfDay(PeriodDate + 86400);
			
		EndDo;
	EndIf;
	
	If WorksScheduleRadioButton = "Interval planning" Then
		
		For Each ListPeriod In SelectedDateList Do
			
			IsBreak = IsBreakByRightDay(ListPeriod.Value, SelectedDateList);
			
			If ListPeriod.Value<=BegOfDay(EndOfPeriod) And Not IsBreak Then Continue EndIf;
			
			EndOfPeriod = RelaitedIntervalEnd(ListPeriod.Value, SelectedDateList);
			EndOfPeriod = ?(BegOfDay(EndOfPeriod) = BegOfDay(EndTime), EndTime, EndOfPeriod);
			
			BeginOfPeriod = ?(BegOfDay(ListPeriod.Value) = BegOfDay(BeginTime), BeginTime, BegOfDay(ListPeriod.Value));
			
			FilterParameters = New Structure("Resource, BeginOfPeriod, EndOfPeriod", Resource, BeginOfPeriod, EndOfPeriod);
			FoundStrings = AddInDocumentBuffer.FindRows(FilterParameters);
			
			If FoundStrings.Count() Then
				SelectedRow = FoundStrings[0];
				SelectedRow.Loading = SelectedRow.Loading+1;
				Continue
			EndIf;
			
			SelectedRow = AddInDocumentBuffer.Add();
			SelectedRow.Resource = Resource;
			SelectedRow.BeginOfPeriod = BeginOfPeriod;
			SelectedRow.EndOfPeriod = EndOfPeriod;
			SelectedRow.Loading =1;
			SelectedRow.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.NoRepeat");
			
			SelectedRow.ControlStep = StructureData.ControlStep;
			SelectedRow.MultiplicityPlanning = StructureData.MultiplicityPlanning;
			
		EndDo;
	Else
		
		ResourcesList = New ValueList;
		ResourcesList.Add(Resource);
			
		MapWorkPeriodsByDays = New Map;
		
		For Each ListPeriod In SelectedDateList Do
			WorkPeriods = GetResourceWorkGraph(ResourcesList, BegOfDay(ListPeriod.Value));
			
			If WorkPeriods.Count() Then
				MapWorkPeriodsByDays.Insert(ListPeriod.Value, WorkPeriods);
			EndIf;
			
		EndDo;
		
		WasOutputByGraph = False;
		
		For Each ListPeriod In SelectedDateList Do
			
			MapValue = MapWorkPeriodsByDays.Get(ListPeriod.Value);
			
			If Not MapValue = Undefined Then
				
				WorkPeriods = MapValue;
				
				For Each workPeriod In WorkPeriods Do
					
					FilterParameters = New Structure("Resource, BeginOfPeriod, EndOfPeriod", Resource, workPeriod.BeginOfPeriod, workPeriod.EndOfPeriod);
					FoundStrings = AddInDocumentBuffer.FindRows(FilterParameters);
					
					If FoundStrings.Count() Then
						SelectedRow = FoundStrings[0];
						SelectedRow.Loading = SelectedRow.Loading+1;
						Continue
					EndIf;
					
					SelectedRow = AddInDocumentBuffer.Add();
					SelectedRow.Resource = Resource;
					SelectedRow.BeginOfPeriod = workPeriod.BeginOfPeriod;
					SelectedRow.EndOfPeriod =  workPeriod.EndOfPeriod;
					SelectedRow.Loading = 1;
					SelectedRow.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.NoRepeat");
					
					SelectedRow.ControlStep = workPeriod.ControlStep;
					SelectedRow.MultiplicityPlanning = workPeriod.MultiplicityPlanning;
					
					WasOutputByGraph = True;
					
				EndDo;
				
			Else
				
				IsBreak = IsBreakByRightDay(ListPeriod.Value, SelectedDateList) Or WasOutputByGraph;
				
				If ListPeriod.Value<=BegOfDay(EndOfPeriod) And Not IsBreak Then Continue EndIf;
				
				WasOutputByGraph = False;
				
				EndOfPeriod = RelaitedIntervalEnd(ListPeriod.Value, SelectedDateList, MapWorkPeriodsByDays);
				
				FilterParameters = New Structure("Resource, BeginOfPeriod, EndOfPeriod", Resource, BegOfDay(ListPeriod.Value), EndOfPeriod);
				FoundStrings = AddInDocumentBuffer.FindRows(FilterParameters);
				
				If FoundStrings.Count() Then
					SelectedRow = FoundStrings[0];
					SelectedRow.Loading = SelectedRow.Loading+1;
					Continue
				EndIf;
				
				SelectedRow = AddInDocumentBuffer.Add();
				SelectedRow.Resource = Resource;
				SelectedRow.BeginOfPeriod = BegOfDay(ListPeriod.Value);
				SelectedRow.EndOfPeriod = EndOfPeriod;
				SelectedRow.Loading =1;
				SelectedRow.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.NoRepeat");
				
				SelectedRow.ControlStep = StructureData.ControlStep;
				SelectedRow.MultiplicityPlanning = StructureData.MultiplicityPlanning;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterChoiceFormMenu(SelectedItem, Parameters) Export
	
	If SelectedItem = Undefined Then Return EndIf;
	
	AddingFormBin = False;
	
	Area = Parameters.Area;
	
	If Not SelectedItem.Value = NStr("en='Go to';ru='Перейти';vi='Chuyển đến'") And Not WorksScheduleRadioButton = "Month" Then
		
		If Parameters.GraphControl And Not TypeOf(Area.Details) = Type("Structure") 
			Or (TypeOf(Area.Details) = Type("Structure") And Area.Details.Property("ItWorkPeriod") And Not Area.Details.ItWorkPeriod) Then
			
			NotificationParameters = New Structure("Resource, Area, SelectedAction, GraphControl", Parameters.Resource, Area, SelectedItem.Value, Parameters.GraphControl);
			Notification = New NotifyDescription("AfterQuestionClosing", ThisForm, NotificationParameters);
			
			Mode = QuestionDialogMode.YesNo;
			ShowQueryBox(Notification, NStr("en='The interval goes beyond the schedule of working hours. Continue?';ru='Интервал выходит за границы графика рабочего времени. Продолжить?';vi='Khoảng thời gian vượt ra ngoài ranh giới của lịch trình thời gian làm việc. Tiếp tục?'"), Mode, 0);
			
			Return;
			
		EndIf;
		
	EndIf;
	
	If SelectedItem.Value = Nstr("en='Pick';ru='Подбор';vi='Chọn'") Then
		
		PickupInBin(Parameters.Resource, Area, Parameters.GraphControl);
		
	ElsIf SelectedItem.Value = NStr("en='Go to';ru='Перейти';vi='Chuyển đến'") And Not WorksScheduleRadioButton = "Month" Then
		OutputMultiplicityInterval(Parameters.Day);
	ElsIf SelectedItem.Value = NStr("en='Go to';ru='Перейти';vi='Chuyển đến'")  And WorksScheduleRadioButton = "Month" Then
		
		Details = Area.Details;
		
		CleanPeriodInFilter();
		
		CleanFilterTableByFieldsName("Resource");
		
		BeginPeriodDetails = BegOfMonth(Date(Details.Year, Details.Month,1));
		DetailsPeriodEnd = EndOfMonth(BeginPeriodDetails);
		
		Items.Calendar.SelectedDates.Clear();
		BeginDetails = BeginPeriodDetails;
		While BeginDetails <= DetailsPeriodEnd Do
			Items.Calendar.SelectedDates.Add(BeginDetails);
			BeginDetails = BeginDetails+86400;
		EndDo;
		
		WorksScheduleRadioButton = "Day";
		
		FillListPeriodDates(BeginPeriodDetails, DetailsPeriodEnd);
		
		SetListTagAndFilter("Resource", "GroupFilterResource", Details.Resource);
		
		Items.ShowPanningInterval.Check = False;
		Items.ShowDay.Check = True;
		Items.ShowMonth.Check = False;
		Items.GroupStepIntervalMin.Visible = False;
		Items.GroupIntervalSetting.Enabled = True;
		
	ElsIf SelectedItem.Value = Nstr("en='Create Production order';ru='Создать Заказ на производство';vi='Tạo đơn hàng sản xuất'") Then
		PickupInBuffer(Parameters.Resource, Area, Parameters.GraphControl);
		CreateProductionOrder();
		AddInDocumentBuffer.Clear();
	ElsIf SelectedItem.Value = NStr("en='Create Work order';ru='Создать Заказ наряд';vi='Tạo đơn hàng'") Then
		PickupInBuffer(Parameters.Resource, Area, Parameters.GraphControl);
		CreateWorkOrder();
		AddInDocumentBuffer.Clear();
	ElsIf SelectedItem.Value = Nstr("en='Create event ""Record""';ru='Создать событие ""Запись"" ';vi='Tạo sự kiện ""Bản ghi""'") Then
		PickupInBuffer(Parameters.Resource, Area, Parameters.GraphControl);
		CreateEvent();
		AddInDocumentBuffer.Clear();
	ElsIf SelectedItem.Value = NStr("en='Add in Work order';ru='Добавить в Заказ наряд';vi='Thêm để đặt hàng'") Then
		PickupInBuffer(Parameters.Resource, Area, Parameters.GraphControl);
		AddInWorkOrder();
	ElsIf SelectedItem.Value = Nstr("en='Add in Production order';ru='Добавить в Заказ на производство';vi='Thêm vào đơn đặt hàng sản xuất'") Then
		PickupInBuffer(Parameters.Resource, Area, Parameters.GraphControl);
		AddInProductionOrder();
	ElsIf SelectedItem.Value = Nstr("en='Add in event ""Record"" ';ru='Добавить в событие ""Запись"" ';vi='Thêm vào sự kiện ""Bản ghi""'") Then
		PickupInBuffer(Parameters.Resource, Area, Parameters.GraphControl);
		AddInEvent();
	EndIf;
	
EndProcedure

&AtClient
Procedure SetupBinRepresentation(FormOpening = False, CleanSelectionOnUpdatePeriods = True)
	
	PickupedQuantity = SelectedResources.Count();
	
	Items.DecorationSelected.Title = NStr("en='Pickuped: ';vi='Đã lấy lên: '") + String(PickupedQuantity);
	Items.GroupCart.Enabled = PickupedQuantity;
	
	If Not FormOpening Then
		UpdatePickupedPeriods(CleanSelectionOnUpdatePeriods);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenBin()
	
	FilterParameters = New Structure("FilterFieldName", "Counterparty");
	FoundStrings = LabelData.FindRows(FilterParameters);
	
	If FoundStrings.Count() Then 
		Counterparty = FoundStrings[0].Mark
	Else
		Counterparty = Undefined;
	EndIf;
	
	OpenParameters = New Structure("SelectedResources, ThisSelection, OnlyBySubsystem1, OnlyBySubsystem2, OnlyBySubsystem3, Counterparty"
	, SelectedResources, ThisSelection, OnlyBySubsystem1, OnlyBySubsystem2, OnlyBySubsystem3, Counterparty);
	
	NotificationParameters = New Structure();
	
	Notification = New NotifyDescription("ProcessBinData", ThisObject, NotificationParameters);
	
	OpenForm("DataProcessor.ResourcePlanner.Form.FormSelectedResources",OpenParameters,ThisForm,,,,Notification,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ProcessBinData(NotifyResult, Parameters) Export
	
	SelectedResources.Clear();
	
	ProcessbinDataServer(NotifyResult.SelectedResources);
	
	If NotifyResult.Property("CloseForm") Then
		TransferToDocument();
		Return;
	EndIf;
	
	SetupBinRepresentation();
	
EndProcedure

&AtServer
Procedure ProcessbinDataServer(SelectedResourcesBin);
	
	SelectedResources.Load(SelectedResourcesBin.Unload());
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Function IsWorksPeriods(WorkPeriods)
	
	For Each TableRow In WorkPeriods Do 
		
		If ValueIsFilled(TableRow.BeginWorkPeriodInDay) Or ValueIsFilled(TableRow.WorkPeriodPerDayEnd) Then
			Return True;
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

&AtClient
Procedure SetupSettingsBySubsystemNumber()
	
	Items.CommandCreateProductionOrder.Visible = OnlyBySubsystem2;
	Items.CommandAddInProductionOrder.Visible = OnlyBySubsystem2;
	Items.LoadingResourcesContextBarCommandCreateProductionOrder.Visible = OnlyBySubsystem2 And Not ThisSelection;
	Items.LoadingResourcesContextBarCommandAddInProductionOrder.Visible = OnlyBySubsystem2 And Not ThisSelection;
	
	Items.CommandCreateEvent.Visible = OnlyBySubsystem3;
	Items.CommandAddInEvent.Visible = OnlyBySubsystem3;
	Items.LoadingResourcesContextBarCommandCreateEvent.Visible = OnlyBySubsystem3 And Not ThisSelection;
	Items.LoadingResourcesContextBarCommandAddInEvent.Visible = OnlyBySubsystem3 And Not ThisSelection;
	
	Items.GroupFilterContact.Visible = OnlyBySubsystem3;
	
	If OnlyBySubsystem3 Then
		Items.FilterContact.TypeRestriction = New TypeDescription("String",, New StringQualifiers(100));
	EndIf;
	
	Items.CommandCreateCustomerOrder.Visible = OnlyBySubsystem1;
	Items.CommandAddInWorkOrder.Visible = OnlyBySubsystem1;
	Items.LoadingResourcesContextBarCommandCreateCustomerOrder.Visible = OnlyBySubsystem1 And Not ThisSelection;
	Items.LoadingResourcesContextBarCommandAddInWorkOrder.Visible = OnlyBySubsystem1 And Not ThisSelection;
	
	If SubsystemNumber = 3 Then
		
		FilterParameters = New Structure("FilterFieldName", "Counterparty");
		FoundStrings = LabelData.FindRows(FilterParameters);
		
		If FoundStrings.Count() Then
			DeleteFilterMarksDataByFieldName("Counterparty");
		EndIf;
		
	EndIf;
	
	If Not OnlyBySubsystem2 And Not OnlyBySubsystem3 And Not OnlyBySubsystem1
		Then
		Items.LoadingResourcesContextBarCommandPickupInBin.Visible = False;
	Else
		Items.LoadingResourcesContextBarCommandPickupInBin.Visible = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessPickupEvent(EnterpriseResources, DatesArray, PlanningBoarders)
	
	For Each TableRow In EnterpriseResources Do
		
		NewRow = SelectedResources.Add();
		FillPropertyValues(NewRow, TableRow);
		
		NewRow.Resource = TableRow.EnterpriseResource;
		NewRow.BeginOfPeriod = TableRow.Start;
		NewRow.EndOfPeriod = TableRow.Finish;
		NewRow.Loading = TableRow.Capacity;
		NewRow.ControlStep = TableRow.ControlStep;
		NewRow.MultiplicityPlanning = TableRow.MultiplicityPlanning;
		
	EndDo;
	
	PlanningBoarders = ResourcePlanningCM.MaxIntervalBoarders(EnterpriseResources, "Start", "Finish");
	
	BeginPlanning = BegOfDay(PlanningBoarders.IntervalBegin);
	PlanningEnd = BegOfDay(PlanningBoarders.IntervalEnd);
	
	Items.Calendar.SelectedDates.Clear();
	
	If BeginPlanning = PlanningEnd
		Then
		DatesArray.Add(BeginPlanning);
		Items.Calendar.SelectedDates.Add(BeginPlanning);
		WorksScheduleRadioButton = "Interval planning";
	Else
		
		While BeginPlanning <= PlanningEnd Do
			
			DatesArray.Add(BeginPlanning);
			Items.Calendar.SelectedDates.Add(BeginPlanning);
			BeginPlanning = BeginPlanning+86400;
			
		EndDo;
		
		Items.ShowPanningInterval.Check = False;
		Items.ShowDay.Check = True;
		
		WorksScheduleRadioButton = "Day";
		
	EndIf;
	
	PickupedQuantity = SelectedResources.Count();
	
	Items.DecorationSelected.Title = "Pickuped: " + String(PickupedQuantity);
	Items.GroupCart.Enabled = PickupedQuantity;
	
EndProcedure

&AtServer
Procedure SetupSettingsFormItemsOnCreate()
	
	Items.GroupRepresentationInterval.Enabled = Not OnlyWorkTime;
	Items.GroupRepresentationVariant.Visible = UseVariants;
	
	Items.GroupSubmenuDocuments.Enabled = Not ThisSelection;
	Items.CommandMoveInDocument.Visible = ThisSelection; 
	Items.OptionsGroup.Visible = Not ThisSelection;
	
EndProcedure

&AtServer
Procedure SetupSettingsDefaultColors()
	
	ColorWorkTime = WebColors.MediumSeaGreen;
	ColorNotworkingTime = WebColors.Silver;
	ColorFullLoading = WebColors.Gold;
	ColorOverloading = WebColors.Salmon;
	ColorPartialLoadingBefore = WebColors.MediumSeaGreen;
	ColorPartialLoadingAfter = WebColors.MediumSeaGreen;
	ColorPickedupInBin = WebColors.RoyalBlue;
	
	LoadingProcent = 50;
	
EndProcedure

&AtServer
Function AccordanceDaysOfWeek()
	
	ReturnMap = New Map;
	
	ReturnMap.Insert(1, "mon.");
	ReturnMap.Insert(2, "tu.");
	ReturnMap.Insert(3, "we.");
	ReturnMap.Insert(4, "th.");
	ReturnMap.Insert(5, "fr.");
	ReturnMap.Insert(6, "sa.");
	ReturnMap.Insert(7, "su.");
	
	Return ReturnMap;
	
EndFunction

&AtClient
Procedure CleanFilterPeriod()
	
	Period.StartDate = Date(1,1,1);
	Period.EndDate = Date(1,1,1);
	
	PeriodLabel = NStr("en='Period: defined by calendar';ru='Период: определяется календарем';vi='Thời gian: được xác định bởi lịch'");
	
EndProcedure

&AtClient
Procedure CleanPeriodInFilter()
	Period.StartDate = Date(1,1,1);
	Period.EndDate = Date(1,1,1);
EndProcedure

&AtServer
Function MonthByNumber(MonthNumber)
	
	MapMonth = New Map;
	
	    MapMonth.Insert(1, NStr("en='January';vi='Tháng 1';"));
		MapMonth.Insert(2, NStr("en='February';vi='Tháng 2';"));
		MapMonth.Insert(3, NStr("en='March';vi='Tháng 3';"));
		MapMonth.Insert(4, NStr("en='April';vi='Tháng 4';"));
		MapMonth.Insert(5, NStr("en='May';vi='Tháng 5';"));
		MapMonth.Insert(6, NStr("en='June';vi='Tháng 6';"));
		MapMonth.Insert(7, NStr("en='July';vi='Tháng 7';"));
		MapMonth.Insert(8, NStr("en='August';vi='Tháng 8';"));
		MapMonth.Insert(9, NStr("en='September';vi='Tháng 9';"));
		MapMonth.Insert(10, NStr("en='October';vi='Tháng 10';"));
		MapMonth.Insert(11, NStr("en='November';vi='Tháng 11';"));
		MapMonth.Insert(12, NStr("en='December';vi='Tháng 12';"));
	
	Return MapMonth.Get(MonthNumber);
	
EndFunction

&AtServer
Function GetListGroupParentName()
	
	AddedItemsRemovalFormGroupsList = LabelData.Unload();
	AddedItemsRemovalFormGroupsList.GroupBy("GroupParentName","");
	
	Return AddedItemsRemovalFormGroupsList.UnloadColumn("GroupParentName");
	
EndFunction

&AtClientAtServerNoContext
Function UpdatePeriodRepresentation(Period)
	
	If Not ValueIsFilled(Period) Or (Not ValueIsFilled(Period.StartDate) And Not ValueIsFilled(Period.EndDate)) Then
		DescriptionPeriodFilter = NStr("en='Period: defined by calendar';ru='Период: определяется календарем';vi='Thời gian: được xác định bởi lịch'");
	Else
		EndDateOfPeriod = ?(ValueIsFilled(Period.EndDate), EndOfDay(Period.EndDate), Period.EndDate);
		If EndDateOfPeriod < Period.StartDate Then
			#If Client Then
				SmallBusinessClient.ShowMessageAboutError(Undefined, NStr("en='Period end date is less than start date!';ru='Выбрана дата окончания периода, которая меньше даты начала!';vi='Đã chọn ngày cuối kỳ nhỏ hơn ngày đầu kỳ!'"));
			#EndIf
			DescriptionPeriodFilter = NStr("en='from ';ru='с ';vi='từ '")+Format(Period.StartDate,"DF=dd.MM.yyyy");
		Else
			DescriptionPeriodFilter = NStr("ru='за ';vi='cho '")+Lower(PeriodPresentation(Period.StartDate, EndDateOfPeriod));
		EndIf; 
	EndIf;
	
	Return DescriptionPeriodFilter;
	
EndFunction

&AtServerNoContext
Procedure AddCounterpertyFilterByContacts(Filter, Counterparty)
	RelaitedContacts = Catalogs.Counterparties.RelaitedContacts(Counterparty);
	CommonUseClientServer.SupplementArray(Filter, RelaitedContacts);
EndProcedure

&AtClient
Procedure FillListPositioningPeriod()
	
	Items.PositioningPeriod.ChoiceList.Clear();
	
	If Not WorksScheduleRadioButton = "Interval planning" Or Not ListPeriodDates.Count() Then
		Return
	EndIf;
	
	If ValueIsFilled(PeriodPresentation) Then
		
		FilterParameters = New Structure("Date", PeriodPresentation);
		FoundRowsItems = PeriodByDays.FindRows(FilterParameters);
		
		If Not FoundRowsItems.Count() Then Return EndIf;
		
		For Each ListElement In FoundRowsItems[0].ChioceListTimeMoveByCoordinate Do
			
			DateDescription = ?(ListElement.Value = Date(1,1,1), "00:00", Format(ListElement.Value,"DF=ЧЧ:мм"));
			
			Items.PositioningPeriod.ChoiceList.Add(ListElement.Value, DateDescription);
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessEventIntervalChoice(Resource, Area, Day, GraphControl)
	
	If OnlyFormReview Then Return EndIf;
	
	NotificationParameters = New Structure("Resource, Area, Day, GraphControl", Resource, Area, Day, GraphControl);
	
	List = New ValueList;
	
	If Not WorksScheduleRadioButton = "Month" 
		And (OnlyBySubsystem1 Or OnlyBySubsystem2 Or OnlyBySubsystem3) Then
		List.Add(Nstr("en='Pick';ru='Подбор';vi='Chọn'"));
	EndIf;
	
	If Not WorksScheduleRadioButton = "Interval planning" Then
		List.Add(Nstr("en='Go to';ru='Перейти';vi='Chuyển đến'"),,False, PictureLib.GoForward);
	EndIf;
	
	If Not ThisSelection And Not WorksScheduleRadioButton = "Month" Then
		
			If OnlyBySubsystem1 Then
				List.Add(NStr("en='Create Work order';ru='Создать Заказ наряд';vi='Tạo đơn hàng'"),,False,PictureLib.CreateListItem);
				List.Add(NStr("en='Add in Work order';ru='Добавить в Заказ наряд';vi='Thêm để đặt hàng'"));
			EndIf;
			
			If OnlyBySubsystem2 Then
				List.Add(Nstr("en='Create Production order';ru='Создать Заказ на производство';vi='Tạo đơn hàng sản xuất'"),,False, PictureLib.CreateListItem);
				List.Add(Nstr("en='Add in Production order';ru='Добавить в Заказ на производство';vi='Thêm vào đơn đặt hàng sản xuất'"));
			EndIf;
			
			If OnlyBySubsystem3 Then
				List.Add(Nstr("en='Create event ""Record""';ru='Создать событие ""Запись"" ';vi='Tạo sự kiện ""Bản ghi""'"),,False, PictureLib.CreateListItem);
				List.Add(Nstr("en='Add in event ""Record"" ';ru='Добавить в событие ""Запись"" ';vi='Thêm vào sự kiện ""Bản ghi""'"));
			EndIf;
			
	EndIf;
	
	Notification = New NotifyDescription("AfterChoiceFormMenu",ThisForm, NotificationParameters);
	ShowChooseFromMenu(Notification, List, Items.ResourcesImport);
	
EndProcedure

&AtServer
Procedure SetupFormAttributesValuesByDefault()
	
	ResourcesImport.Clear();
	ListPeriodDates.Clear();
	Items.Calendar.SelectedDates.Clear();
	ListPeriodDates.Add(BegOfDay(CurrentSessionDate()));
	Items.Calendar.SelectedDates.Add(BegOfDay(CurrentSessionDate()));
	PeriodPresentation = Undefined;
	Items.PositioningPeriod.ChoiceList.Clear();
	
	AddedItemsRemovalFormGroupsList = GetListGroupParentName();
	LabelData.Clear();
	WorkWithFilters.RefreshLabelItems(ThisObject, AddedItemsRemovalFormGroupsList, "LabelData");
	
	BeginOfRepresentationInterval = Undefined;
	RepresentationIntervalEnd = Undefined;
	OnlyWorkTime = False;
	IntervalStepMin = 0;
	
	SetupSettingsDefaultColors();
	
	WorksScheduleRadioButton = "Interval planning";
	
	Items.ShowPanningInterval.Check = True;
	Items.ShowDay.Check = False;
	Items.ShowMonth.Check = False;
	Items.GroupIntervalSetting.Enabled = True;
	
	Items.GroupRepresentationInterval.Enabled = True;
	Items.PositioningPeriod.Visible = True;
	
EndProcedure

&AtServer
Function ProfileAvailable(RoleName)
	
	Query = New Query;
	
	Query.SetParameter("User", Users.AuthorizedUser());
	Query.SetParameter("Profile", Catalogs.AccessGroupsProfiles.FindByDescription(RoleName));
	
	Query.Text = 
	"SELECT DISTINCT
	|	AccessGroupsUsers.Ref AS Ref
	|FROM
	|	Catalog.AccessGroups.Users AS AccessGroupsUsers
	|WHERE
	|	AccessGroupsUsers.User = &User
	|	AND AccessGroupsUsers.Ref.Profile = &Profile";
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

&AtClient
Procedure ContexBarAvailable(Enabled = True)
	Items.ResourcesImport.ContextMenu.Enabled = Enabled;
EndProcedure

&AtClient
Procedure FillBuffer()
	
	SelectedAreas = Items.ResourcesImport.GetSelectedAreas();
	
	ListPeriodDates.SortByValue(SortDirection.Asc);
	
	For Each SelectedArea In SelectedAreas Do
		
		CurArea = SelectedArea;
		
		DownAreaBoarder = SelectedArea.Bottom;
		AreaTopBorder = SelectedArea.Top;
		
		For BoarderIndex = AreaTopBorder To DownAreaBoarder Do
			
			LeftBoarder = ?(SelectedArea.Left < 5, 5, SelectedArea.Left);
			
			CurArea = ResourcesImport.Area("R"+Format(BoarderIndex,"NG=")+"C"+Format(LeftBoarder,"NG=")+":"+"R"+Format(BoarderIndex+1,"NG=")+"C"+Format(SelectedArea.Right,"NG="));
			
			If CurArea.Left < 5 Then
				CurArea = ResourcesImport.Area("R"+Format(CurArea.Top,"NG=")+"C"+"5"+":"+"R"+Format(CurArea.Bottom,"NG=")+"C"+Format(CurArea.Right,"NG="));
			EndIf;
			
			If TypeOf(CurArea) <> Type("SpreadsheetDocumentRange") Then
				Return;
			EndIf;
			
			ColumnCoordinate = ?(WorksScheduleRadioButton = "Month",Format(CurArea.Left,"NG="),1);
			
			CellDetails = ResourcesImport.Area("R"+String(CurArea.Top)+"C"+String(ColumnCoordinate)).Details;
			
			If WorksScheduleRadioButton = "Interval planning" Then
				DetailsCellTimeBegin = ResourcesImport.Area("R"+3+"C"+Format(LeftBoarder+1,"NG=")+":"+"R"+3+"C"+Format(LeftBoarder+1,"NG=")).Details;
				DatailsCellTimeFinish = ResourcesImport.Area("R"+3+"C"+Format(SelectedArea.Right+2,"NG=")+":"+"R"+3+"C"+Format(SelectedArea.Right+2,"NG=")).Details;
				
				BeginTime = DetailsCellTimeBegin;
				EndTime = DatailsCellTimeFinish;
				
			ElsIf WorksScheduleRadioButton = "Day" Then
				DetailsCellTimeBegin = ResourcesImport.Area("R"+3+"C"+Format(LeftBoarder,"NG=")+":"+"R"+3+"C"+Format(LeftBoarder+1,"NG=")).Details;
				DatailsCellTimeFinish = ResourcesImport.Area("R"+3+"C"+Format(SelectedArea.Right,"NG=")+":"+"R"+3+"C"+Format(SelectedArea.Right,"NG=")).Details;
				
				If Not ValueIsFilled(DetailsCellTimeBegin) Then Return EndIf;
				
				BeginTime = BegOfDay(DetailsCellTimeBegin);
				EndTime = ?(TypeOf(DatailsCellTimeFinish) = Type("Date"), EndOfDay(DatailsCellTimeFinish), Undefined);
				
			EndIf;
			
			EndTime = ?(Not ValueIsFilled(EndTime), EndOfDay(BeginTime), EndTime);
			EndTime = ?(EndTime = BegOfDay(EndTime), EndOfDay(BeginTime), EndTime);
			
			Resource = Undefined;
			GraphControl = False;
			
			If TypeOf(CellDetails) = Type("Structure") And CellDetails.Property("Resource") And Not CellDetails.Property("DocumentReference") Then
				Resource = CellDetails.Resource;
				
				If CurArea.Left = 1 Then
					Return
				EndIf;
				
				GraphControl = ?(CellDetails.Property("ControlLoadingOnlyInWorkTime"), CellDetails.ControlLoadingOnlyInWorkTime, False);
				
				PickupInBufferContexBar(Resource, CurArea, GraphControl, BeginTime, EndTime);
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure TransferToDocument()
	ListPeriodDates.Clear();
	Items.Calendar.SelectedDates.Clear();
	ThisForm.Close(SelectedResources);
EndProcedure

&AtServer
Function DetailsMultiplicity(Resource)
	
	If Resource.MultiplicityPlanning >= 60 And Resource.MultiplicityPlanning < 1440 Then
		
		HoursCount = Int(Resource.MultiplicityPlanning/60);
		MinutesCount = Resource.MultiplicityPlanning - HoursCount*60;
		
		ReturnString = String(HoursCount)+ NStr("en=' h. ';vi=' giờ ';")+ String(MinutesCount)+ NStr("en=' Min';vi=' Phút';");
		
		Return ReturnString;
		
	ElsIf Resource.MultiplicityPlanning >= 1440 Then
		
		DaysNumber = Int(Resource.MultiplicityPlanning/1440);
		HoursCount = Int((Resource.MultiplicityPlanning - (DaysNumber*1440))/60);
		MinutesCount = Resource.MultiplicityPlanning - (DaysNumber*1440+HoursCount*60);
		
		ReturnString = "24 hour";//Строка(КоличествоДней)+" д. "+ Строка(КоличествоЧасов)+ " ч. "+ Строка(КоличествоМинут)+ " мин";
		
		Return ReturnString;
	Else
		ReturnString = String(Resource.MultiplicityPlanning)+ NStr("en=' Min';vi=' Phút';");
		Return ReturnString;
	EndIf
	
EndFunction

&AtServer
Procedure UpdatePickupedPeriods(PreCleaning = False)
	
	ScheduleTable = SelectedResources.Unload();
	
	ScheduleTable.Columns.Add("LineNumber");
	
	ColumnOfTV = ScheduleTable.Columns.Find("Resource");
	ColumnOfTV.Name = "EnterpriseResource";
	
	ColumnOfTV = ScheduleTable.Columns.Find("Loading");
	ColumnOfTV.Name = "Capacity";
	
	ColumnOfTV = ScheduleTable.Columns.Find("BeginOfPeriod");
	ColumnOfTV.Name = "Start";
	
	ColumnOfTV = ScheduleTable.Columns.Find("EndOfPeriod");
	ColumnOfTV.Name = "Finish";
	
	DecomposedTableFromScheduleBin = ResourcePlanningCM.DecomposeRowsByRecordsSchedule(Undefined,ScheduleTable);
	
	FilterParameters = New Structure("Period, EnterpriseResource");
	IntervalFilterParameters = New Structure("Date");
	
	SolidLine = New Line(SpreadsheetDocumentCellLineType.Solid, 3);
	None = New Line(SpreadsheetDocumentCellLineType.None);
	
	FilterByDaysParameters = New Structure("Date");
	
	For Each PeriodDate In ListPeriodDates Do
		
		IntervalFilterParameters.Date = PeriodDate.Value;
		RowsIntervalTable = DaysCoordinates.FindRows(IntervalFilterParameters);
		
		If Not RowsIntervalTable.Count() Then Continue EndIf;
		
		CurIntervalDate = RowsIntervalTable[0];
		
		For Each RowResource In ResourcesByRows Do 
			
			FilterParameters.Period = PeriodDate.Value;
			FilterParameters.EnterpriseResource = RowResource.Resource;
			
			FoundStrings = DecomposedTableFromScheduleBin.FindRows(FilterParameters);
			
			ResourceRowNumber = RowResource.LineNumber;
			
			If PreCleaning Then 
				
				CoordinateColumnBeginPositioning = Format(CurIntervalDate.CoordinateBegin,"NG=");
				CoordinateColumnEndPositioning = Format(CurIntervalDate.CoordinateEnd,"NG=");
				
				Area = ResourcesImport.Area(ResourceRowNumber-1,CoordinateColumnBeginPositioning,ResourceRowNumber-1,CoordinateColumnEndPositioning);
				
				Area.BottomBorder = None;
				
			EndIf;
			
			FilterByDaysParameters.Date = PeriodDate.Value;
			
			FoundRowsByPeriod = PeriodByDays.FindRows(FilterByDaysParameters);
			
			TimeBeginPeriod = Date(1,1,1);
			
			If FoundRowsByPeriod.Count() Then
				ListPositioningByPeriod = FoundRowsByPeriod[0].ChioceListTimeMoveByCoordinate;
				If ListPositioningByPeriod.Count() Then
					TimeBeginPeriod = ListPositioningByPeriod[0].Value;
				EndIf
			EndIf;
			
			DeviationBeginDay = Hour(TimeBeginPeriod)*60+Minute(TimeBeginPeriod);
			
			For Each FoundString In FoundStrings Do
				
				BeginSelectedInterval = Hour(FoundString.Start)*60+Minute(FoundString.Start)-DeviationBeginDay;
				CoordinateColumnBeginPositioningNumber = CurIntervalDate.CoordinateBegin + BeginSelectedInterval/MinInterval;
				CoordinateColumnBeginPositioning = Format(CoordinateColumnBeginPositioningNumber,"NG=");
				
				Finish = FoundString.Finish;
				
				If Finish = EndOfDay(Finish) Then
					EndSelectedInterval = 24*60 - DeviationBeginDay;
				Else
					EndSelectedInterval = Hour(Finish)*60+Minute(Finish) - DeviationBeginDay;
				EndIf;
				
				CoordinateColumnEndPositioningNumber = CurIntervalDate.CoordinateBegin + EndSelectedInterval/MinInterval;
				CoordinateColumnEndPositioning = Format(CoordinateColumnEndPositioningNumber,"NG=");
				
				If CoordinateColumnEndPositioningNumber > CurIntervalDate.CoordinateEnd Then
					CoordinateColumnEndPositioningNumber = CurIntervalDate.CoordinateEnd
				EndIf;
				
				Area = ResourcesImport.Area(ResourceRowNumber-1,CoordinateColumnBeginPositioning,ResourceRowNumber-1,CoordinateColumnEndPositioning-1);
				
				Area.BottomBorder = SolidLine;
				Area.BorderColor = ColorPickedupInBin;
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure OnChangeIntervalColor()
	
	If ColorWorkTime = New Color(0,0,0) Then
		ColorWorkTime = WebColors.MediumSeaGreen;
	EndIf;
	If ColorNotworkingTime = New Color(0,0,0) Then
		ColorNotworkingTime = WebColors.Silver;
	EndIf;
	If ColorFullLoading = New Color(0,0,0) Then
		ColorFullLoading = WebColors.Gold;
	EndIf;
	If ColorOverloading = New Color(0,0,0) Then
		ColorOverloading = WebColors.Salmon;
	EndIf;
	If ColorPartialLoadingBefore = New Color(0,0,0) Then
		ColorPartialLoadingBefore = WebColors.MediumSeaGreen;
	EndIf;
	If ColorPartialLoadingAfter = New Color(0,0,0) Then
		ColorPartialLoadingAfter = WebColors.MediumSeaGreen;
	EndIf;
	If ColorPickedupInBin = New Color(0,0,0) Then
		ColorPickedupInBin = WebColors.RoyalBlue;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnActivateSreadSheetDocument()
	
	CurrentPosition = Items.ResourcesImport.CurrentArea;
	
	CellDetails = ResourcesImport.Area("R"+CurrentPosition.Top+"C"+1).Details;
	
	ContexBarAvailable(False);
	
	If TypeOf(CellDetails) = Type("Structure") And CellDetails.Property("Resource") And Not CellDetails.Property("DocumentReference") Then
		
		LeftBoarder =CurrentPosition.Left;
		
		If WorksScheduleRadioButton = "Interval planning" Then
			DetailsCellTimeBegin = ResourcesImport.Area("R"+3+"C"+Format(LeftBoarder+1,"NG=")+":"+"R"+3+"C"+Format(LeftBoarder+1,"NG=")).Details;
		ElsIf WorksScheduleRadioButton = "Day" Then
			DetailsCellTimeBegin = ResourcesImport.Area("R"+3+"C"+Format(LeftBoarder,"NG=")+":"+"R"+3+"C"+Format(LeftBoarder+1,"NG=")).Details;
		EndIf;
		
		If TypeOf(DetailsCellTimeBegin) = Type("Date") Then
			ContexBarAvailable();
		EndIf;
	EndIf;
		
	If Not ListPeriodDates.Count() Then Return EndIf;
	
	If WorksScheduleRadioButton = "Month" Then Return EndIf;
	
	CurrentPosition = Items.ResourcesImport.CurrentArea;
	
	DescriptionCoordinate = "R4C"+String(Format(CurrentPosition.Left+1,"NG="));
	DescriptionCoordianteTime = "R3C"+String(Format(CurrentPosition.Left+1,"NG="));
	
	DescriptionCoordinate = StrReplace(DescriptionCoordinate,Chars.NBSp,"");
	
	CurrentPostionDate = Date(1,1,1);
	
	DataDate = CurentPositioningDate(CurrentPosition.Left);
	
	NeedRefillingPositioningList = False;
	
	If Not ValueIsFilled(DataDate) Then
		Items.PositioningPeriod.ChoiceList.Clear();
		PeriodPresentation = Undefined;
		Return;
	EndIf;
	
	If Not Items.PositioningPeriod.ChoiceList.Count() Or Not PeriodPresentation = DataDate Then
		PeriodPresentation = DataDate;
		FillListPositioningPeriod();
	EndIf;
	
	PeriodSelection = False;
	
	If WorksScheduleRadioButton = "Interval planning" And Not PeriodSelection Then
		
		If ValueIsFilled(ResourcesImport.Area(DescriptionCoordianteTime).Details) Then
			
			DataTime = ResourcesImport.Area(DescriptionCoordianteTime).Details;
			
			ListElement = Items.PositioningPeriod.ChoiceList.FindByValue(Date(1,1,1)+(DataTime-BegOfDay(DataTime)));
			
			If ListElement = Undefined Then 
				Return 
			EndIf;
			
			PositioningPeriod = ListElement.Value;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PickupInBinFromContexBarEnd(SelectedAreas)
	
	For Each SelectedArea In SelectedAreas Do
		
			CurArea = SelectedArea;
			
			DownAreaBoarder = SelectedArea.Bottom;
			AreaTopBorder = SelectedArea.Top;
			
			For BoarderIndex = AreaTopBorder To DownAreaBoarder Do
				
				LeftBoarder = ?(SelectedArea.Left < 5, 5, SelectedArea.Left);
				
				CurArea = ResourcesImport.Area("R"+Format(BoarderIndex,"NG=")+"C"+Format(LeftBoarder,"NG=")+":"+"R"+Format(BoarderIndex+1,"NG=")+"C"+Format(SelectedArea.Right,"NG="));
				
				If CurArea.Left < 5 Then
					CurArea = ResourcesImport.Area("R"+Format(CurArea.Top,"NG=")+"C"+"5"+":"+"R"+Format(CurArea.Bottom,"NG=")+"C"+Format(CurArea.Right,"NG="));
				EndIf;
				
				If TypeOf(CurArea) <> Type("SpreadsheetDocumentRange") Then
					Return;
				EndIf;
				
				ColumnCoordinate = ?(WorksScheduleRadioButton = "Month",Format(CurArea.Left,"NG="),1);
				
				CellDetails = ResourcesImport.Area("R"+String(CurArea.Top)+"C"+String(ColumnCoordinate)).Details;
				
				If WorksScheduleRadioButton = "Interval planning" Then
					DetailsCellTimeBegin = ResourcesImport.Area("R"+3+"C"+Format(LeftBoarder+1,"NG=")+":"+"R"+3+"C"+Format(LeftBoarder+1,"NG=")).Details;
					DatailsCellTimeFinish = ResourcesImport.Area("R"+3+"C"+Format(SelectedArea.Right+2,"NG=")+":"+"R"+3+"C"+Format(SelectedArea.Right+2,"NG=")).Details;
					
					BeginTime = DetailsCellTimeBegin;
					EndTime = DatailsCellTimeFinish;
			
				ElsIf WorksScheduleRadioButton = "Day" Then
					DetailsCellTimeBegin = ResourcesImport.Area("R"+3+"C"+Format(LeftBoarder,"NG=")+":"+"R"+3+"C"+Format(LeftBoarder+1,"NG=")).Details;
					DatailsCellTimeFinish = ResourcesImport.Area("R"+3+"C"+Format(SelectedArea.Right,"NG=")+":"+"R"+3+"C"+Format(SelectedArea.Right,"NG=")).Details;
					
					If Not ValueIsFilled(DetailsCellTimeBegin) Then Return EndIf;
					
					BeginTime = BegOfDay(DetailsCellTimeBegin);
					EndTime = ?(TypeOf(DatailsCellTimeFinish) = Type("Date"), EndOfDay(DatailsCellTimeFinish), Undefined);
					
				EndIf;
				
				EndTime = ?(Not ValueIsFilled(EndTime), EndOfDay(BeginTime), EndTime);
				EndTime = ?(EndTime = BegOfDay(EndTime), EndOfDay(BeginTime), EndTime);
				
				Resource = Undefined;
				
				If TypeOf(CellDetails) = Type("Structure") And CellDetails.Property("Resource") And Not CellDetails.Property("DocumentReference") Then
					Resource = CellDetails.Resource;
					
					If CurArea.Left = 1 Then
						Return
					EndIf;
					
					StructureData = New Structure();
					StructureData.Insert("Resource", Resource);
					StructureData = GetREsourceData(StructureData);
					
					PickupInBinFromContexBar(Resource, CurArea, BeginTime, EndTime, StructureData);
					
				EndIf;
				
			EndDo;
			
		EndDo;
EndProcedure

&AtClient
Function CompleteOnExistNotWorkingPeriods(SelectedAreas)
	
	For Each SelectedArea In SelectedAreas Do
		
			CurArea = SelectedArea;
			
			DownAreaBoarder = SelectedArea.Bottom;
			AreaTopBorder = SelectedArea.Top;
			
			For BoarderIndex = AreaTopBorder To DownAreaBoarder Do
				
				LeftBoarder = ?(SelectedArea.Left < 5, 5, SelectedArea.Left);
				
				CurArea = ResourcesImport.Area("R"+Format(BoarderIndex,"NG=")+"C"+Format(LeftBoarder,"NG=")+":"+"R"+Format(BoarderIndex+1,"NG=")+"C"+Format(SelectedArea.Right,"NG="));
				
				If CurArea.Left < 5 Then
					CurArea = ResourcesImport.Area("R"+Format(CurArea.Top,"NG=")+"C"+"5"+":"+"R"+Format(CurArea.Bottom,"NG=")+"C"+Format(CurArea.Right,"NG="));
				EndIf;
				
				If TypeOf(CurArea) <> Type("SpreadsheetDocumentRange") Then
					Continue;
				EndIf;
				
				ColumnCoordinate = ?(WorksScheduleRadioButton = "Month",Format(CurArea.Left,"NG="),1);
				
				CellDetails = ResourcesImport.Area("R"+String(CurArea.Top)+"C"+String(ColumnCoordinate)).Details;
				
				DetailsCellTimeBegin = ResourcesImport.Area("R"+3+"C"+Format(LeftBoarder+1,"NG=")+":"+"R"+3+"C"+Format(LeftBoarder+1,"NG=")).Details;
				DatailsCellTimeFinish = ResourcesImport.Area("R"+3+"C"+Format(SelectedArea.Right+2,"NG=")+":"+"R"+3+"C"+Format(SelectedArea.Right+2,"NG=")).Details;
				
				BeginTime = DetailsCellTimeBegin;
				EndTime = DatailsCellTimeFinish;
				
				EndTime = ?(Not ValueIsFilled(EndTime), EndOfDay(BeginTime), EndTime);
				EndTime = ?(EndTime = BegOfDay(EndTime), EndOfDay(BeginTime), EndTime);
				
				Resource = Undefined;
				GraphControl = False;
				PickupComplete = False;
				
				If TypeOf(CellDetails) = Type("Structure") And CellDetails.Property("Resource") And Not CellDetails.Property("DocumentReference") Then
					Resource = CellDetails.Resource;
					
					If CurArea.Left = 1 Then
						Continue
					EndIf;
					
					StructureData = New Structure();
					StructureData.Insert("Resource", Resource);
					StructureData = GetREsourceData(StructureData);
					
					GraphControl = ?(CellDetails.Property("ControlLoadingOnlyInWorkTime"), CellDetails.ControlLoadingOnlyInWorkTime, False);
					
					If GraphControl Then
						PickupComplete = PickupComplete(Resource, LeftBoarder, SelectedArea.Right, Format(BoarderIndex,"NG=")
																				, StructureData.MultiplicityPlanning, BeginTime, EndTime, StructureData);
					EndIf;
					
					If PickupComplete Then
						Return True
					EndIf;
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
		Return False;
	
EndFunction

&AtClient
Function PickupComplete(Resource, LeftBoarder, RightBoarder, AreaRowNumber, MultiplicityPlanning, BeginTime, EndTime, StructureData)
		CellsInPeriod = MultiplicityPlanning/5;
	
	While LeftBoarder < RightBoarder Do
		
		RightIntervalBoarder = LeftBoarder + CellsInPeriod;
		Area = ResourcesImport.Area("R"+AreaRowNumber+"C"+Format(LeftBoarder,"NG=")+":"+"R"+AreaRowNumber+"C"+Format(LeftBoarder+1,"NG="));
		LeftBoarder = RightIntervalBoarder;
		
		If Not TypeOf(Area.Details) = Type("Structure") 
			Or (TypeOf(Area.Details) = Type("Structure") And Area.Details.Property("ItWorkPeriod") And Not Area.Details.ItWorkPeriod) Then
			
			Return True;
			
		EndIf;

	EndDo;
	
	Return False;
	
EndFunction

&AtClient
Procedure AfterQuestionClosingPickUpFromContexBar(Result, NotificationParameters) Export
	If Result = DialogReturnCode.No Then
		Return;
	EndIf;
	
	SelectedAreas = NotificationParameters.SelectedAreas;
	PickupInBinFromContexBarEnd(SelectedAreas);
	
EndProcedure

&AtClient
Procedure PeriodLabelOnClickEnd(NewPeriod, Parameters) Export
	
	If NewPeriod = Undefined Then Return EndIf;
	
	Period = NewPeriod;
	PeriodLabel = UpdatePeriodRepresentation(Period);
	
	CreateByPeriodValueFilter();
	
	If Not WorksScheduleRadioButton = "Month" And Not ValueIsFilled(PositioningPeriod) Then
		Items.ResourcesImport.CurrentArea = ResourcesImport.Area("R7C2");
		PositioningOnArea(PeriodPresentation);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterChoiceDocumentFormMenu(SelectedItem, Parameters) Export
	
	If SelectedItem = Undefined Then Return EndIf;
	
	If SelectedItem.Value = Nstr("en='Production order';ru='Заказ на производство';vi='Đơn hàng sản xuất'") Then
		OpenParameters = New Structure();
		OpenForm("Document.ProductionOrder.Form.ChoiceForm", OpenParameters,Parameters.Item);
		Return;
	EndIf;
	
	If SelectedItem.Value = Nstr("en='Work order';ru='Заказ наряд';vi='Đơn hàng trọn gói'") Then
		OpenParameters = New Structure("ChoiceMode", True);
		OpenForm("Document.CustomerOrder.Form.ListFormWorkOrder", OpenParameters, Parameters.Item);
		Return;
	EndIf;
	
	If SelectedItem.Value = Nstr("en='Event ""Record""';ru='Событие ""Запись""';vi='Sự kiện ""Bản ghi""'") Then
		OpenParameters = New Structure("ChoiceMode, EventType", True, PredefinedValue("Enum.EventTypes.Record"));
		OpenForm("Document.Event.ListForm", OpenParameters, Parameters.Item);
		Return;
	EndIf
	
EndProcedure

&AtClient
Procedure AfterQuestionClosingOnClose(Result, NotificationParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		SelectedResources.Clear();
		
		If Not NotificationParameters.Exit Then
			BeforeClosingAtServer();
		EndIf;
		
		ThisForm.Close();
	EndIf;
	
EndProcedure


#EndRegion