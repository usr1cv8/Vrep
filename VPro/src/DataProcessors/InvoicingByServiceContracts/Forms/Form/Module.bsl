
#Region FormVariables

// Используется для сравнения имеющегося и нового значения реквизита ДатаФормированияДокументовСчета.
// См. Процедуру ДатаФормированияДокументовСчетаОкончаниеВводаТекста
&AtClient
Var DocumentGenerationDateInvoicesCache, DocumentsGenerationDateActsCache;

#EndRegion

#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DocumentsGenerationAllowed = AccessRight("Update", Metadata.Documents.InvoiceForPayment);
	If Not DocumentsGenerationAllowed Then
		Items.GenerateDocuments.Enabled = False;
		Items.GroupDocumentsGenerationDate.Enabled = False;
		Items.GroupGenerateInvoices.Enabled = False;
		Items.GroupGenerateActs.Enabled = False;
		Items.MessagePattern.Enabled = False;
	EndIf;
	
	SettingsKeyInvoicePrintForms = FormName + "/Document.InvoiceForPayment";
	SettingsKeyActPrintForms  = FormName + "/Document.AcceptanceCertificate";
	
	SetFormConditionalAppearance();
	
	// Настройки формы
	RestoreFormSettings();
	
	FillPrintFormsList();
	
	// Выбор периода
	GetServiceContractsPeriodicity();
	GetFilterByPeriodicityPeriod(FilterPeriod, PeriodPresentation, PeriodPeriodicity, DocumentsGenerationDateInvoices, DocumentGenerationDateActs);
	
	LisInvoicesForPayment.Parameters.SetParameterValue("CurrentDateSession", BegOfDay(CurrentSessionDate()));
	
	// Установим формат для текущей даты: ДФ=Ч:мм
	SmallBusinessServer.SetDesignDateColumn(LisInvoicesForPayment);
	SmallBusinessServer.SetDesignDateColumn(ListAcceptanceCertificates);
	
	If CommonUse.IsMobileClient() Then
		
		Items.FiltersSettingsAndExtraInfo.ShowTitle = True;
		Items.CollapseFilters.Visible = False;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	FormManagement();
	
	AttachIdleHandler("StartFormDataUpdate", 0.2, True);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	SaveFormSettings();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "SelectionPrintFormsForSending" Then
		FillPrintFormsList();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormLeftPanelItemsEventHandlers

&AtClient
Procedure DocumentsGenerationDateInvoicesOnChange(Item)
	
	ChangeDate = True;
	
	If DocumentGenerationDateInvoicesCache <> Undefined Then
		ChangeDate = ValidateDocumentsGenerationDateChoice("Account", DocumentsGenerationDateInvoices);
	EndIf;
	
	If Not ChangeDate Then
		Return;
	EndIf;
	
	If DocumentsGenerationDateActsChangeAutomatically Then
		DocumentGenerationDateActs = DocumentsGenerationDateInvoices;
	EndIf;
	
	StartFormDataUpdate();
	
EndProcedure

&AtClient
Procedure DocumentsGenerationDateInvoicesChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	ValidateDocumentsGenerationDateChoice("Account", SelectedValue, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DocumentsGenerationDateInvoicesTextEditEnd(Item, Text, ChoiceData, GetingDataParameters, StandardProcessing)
	
	DocumentGenerationDateInvoicesCache = DocumentsGenerationDateInvoices;
	
EndProcedure

&AtClient
Procedure DocumentGenerationDateActsOnChange(Item)
	
	If DocumentsGenerationDateActsCache <> Undefined Then
		ValidateDocumentsGenerationDateChoice("ACT", DocumentGenerationDateActs);
	EndIf;
	
EndProcedure

&AtClient
Procedure DocumentGenerationDateActsChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	ValidateDocumentsGenerationDateChoice("ACT", SelectedValue, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DocumentGenerationDateActsTextEditEnd(Item, Text, ChoiceData, GetingDataParameters, StandardProcessing)
	
	DocumentsGenerationDateActsCache = DocumentGenerationDateActs;
	
EndProcedure

&AtClient
Procedure ListServiceContractsOnActivateRow(Item)
	
	AttachIdleHandler("FillListServiceContractDetails", 0.2, True);
	
EndProcedure

&AtClient
Procedure ListServiceContractsSelection(Item, SelectedRow, Field, StandardProcessing)
	
	CurrentRow = Items.ListServiceContracts.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	Value = Undefined;
	
	If Field.Name = "ListServiceContractsCounterparty" Then
		ShowValue(, CurrentRow.Counterparty);
	ElsIf Field.Name = "ListServiceContractsContract" Then
		ShowValue(, CurrentRow.Contract);
	ElsIf Field.Name = "ListServiceContractsTariffPlan" Then
		ShowValue(, CurrentRow.TariffPlan);
	EndIf;
	
EndProcedure

&AtClient
Procedure ListServiceContractsGenerateInvoiceOnChange(Item)
	
	CurrentRow = Items.ListServiceContracts.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	If Not CurrentRow.GenerateInvoice Then
		CurrentRow.GenerateAct = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure ListServiceContractsGenerateActOnChange(Item)
	
	CurrentRow = Items.ListServiceContracts.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	If CurrentRow.GenerateAct Then
		CurrentRow.GenerateInvoice = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure ListServiceContractDetailsSelection(Item, SelectedRow, Field, StandardProcessing)
	
	CurrentRow = Items.ListServiceContractDetails.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	FilterProductsAndServices = CurrentRow.ProductsAndServices;
	
	If Field = Items.ListServiceContractDetailsProductsAndServices Then
		
		OpenForm("Catalog.ProductsAndServices.ObjectForm", New Structure("Key", CurrentRow.ProductsAndServices));
		
	ElsIf Field = Items.ListServiceContractDetailsCHARACTERISTIC
		And ValueIsFilled(CurrentRow.CHARACTERISTIC) Then
		
		OpenForm("Catalog.ProductsAndServicesCharacteristics.ObjectForm", New Structure("Key", CurrentRow.CHARACTERISTIC));
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormRightPanelItemsEventHandlers

&AtClient
Procedure PeriodPresentationClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	ShowChooseFromMenu(
		New NotifyDescription("PeriodPresentationPressComplete", ThisObject),
		ContractsPeriodicity,
		Item
	);
	
EndProcedure

&AtClient
Procedure PeriodPresentationPressComplete(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	SelectPeriodicity(Result.Value);
	GetFilterByPeriodicityPeriod(FilterPeriod, PeriodPresentation, PeriodPeriodicity, DocumentsGenerationDateInvoices, DocumentGenerationDateActs);
	
	StartFormDataUpdate();
	
EndProcedure

&AtClient
Procedure FormShowColumnDateOnChange(Item)
	
	FormManagement();
	
EndProcedure

&AtClient
Procedure ShowContractsColumnOnChange(Item)
	
	FormManagement();
	
EndProcedure

&AtClient
Procedure ShowRatesColumnOnChange(Item)
	
	FormManagement();
	
EndProcedure

&AtClient
Procedure GenerateInvoicesSendByEmailOnChange(Item)
	
	FormManagement();
	
EndProcedure

&AtClient
Procedure GenerateInvoicesPrintOnChange(Item)
	
	FormManagement();
	
EndProcedure

&AtClient
Procedure GenerateActsOnChange(Item)
	
	If Not GenerateActs Then
		GenerateActsPost = False;
		GenerateActsGenerateInvoices = False;
		GenerateActsSendByEmail = False;
		GenerateActsPrint = False;
	EndIf;
	
	FormManagement();
	
EndProcedure

&AtClient
Procedure GenerateActsPostOnChange(Item)
	
	If Not GenerateActsPost Then
		GenerateActsGenerateInvoices = False;
		GenerateActsSendByEmail = False;
		GenerateActsPrint = False;
	EndIf;
	
	FormManagement();
	
EndProcedure

&AtClient
Procedure GenerateActsSendByEmailOnChange(Item)
	
	FormManagement();
	
EndProcedure

&AtClient
Procedure GenerateActsPrintOnChange(Item)
	
	FormManagement();
	
EndProcedure

&AtClient
Procedure GenerateInvoicesPrintFormsPresentationClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("FormCaption",          NStr("en='Print form selection';ru='Выбор печатной формы';vi='Chọn mẫu in'"));
	FormParameters.Insert("ObjectManagerName",     "Document.InvoiceForPayment");
	FormParameters.Insert("PrintObjectFormName",   "Document.InvoiceForPayment.Form.ListForm");
	FormParameters.Insert("SettingsKey",            SettingsKeyInvoicePrintForms);
	FormParameters.Insert("PrintFormsChoiceMode", True);
	FormParameters.Insert("ShowPrintCommandsByOfficeDocumentPrintTemplates", False);
	
	OpenForm("CommonForm.SelectionPrintFormsForSending", FormParameters);
	
EndProcedure

&AtClient
Procedure GenerateActsPrintFormsPresentationClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("FormCaption",          NStr("en='Print form selection';ru='Выбор печатной формы';vi='Chọn mẫu in'"));
	FormParameters.Insert("ObjectManagerName",     "Document.AcceptanceCertificate");
	FormParameters.Insert("PrintObjectFormName",   "Document.AcceptanceCertificate.Form.ListForm");
	FormParameters.Insert("SettingsKey",            SettingsKeyActPrintForms);
	FormParameters.Insert("PrintFormsChoiceMode", True);
	
	OpenForm("CommonForm.SelectionPrintFormsForSending", FormParameters);
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure GenerateDocuments(Command)
	
//	If GenerateInvoicesSendByEmail Or (GenerateActs And GenerateActsSendByEmail) Then
//		DefaultAccount = SmallBusinessReUse.GetValueByDefaultUser(
//			UsersClientServer.CurrentUser(), "DefaultEmailAccount");
//		If Not ValueIsFilled(DefaultAccount) Then
//			ShowQueryBox(
//				New NotifyDescription("GoToUserAccountSetup", ThisObject),
//				NStr("ru = 'Необходимо выбрать основную учетную запись для отправки электронных писем.
//				|Перейти в настройки?';
//				|en = 'Необходимо выбрать основную учетную запись для отправки электронных писем.
//				|Перейти в настройки?';"),
//				QuestionDialogMode.YesNo);
//			Return;
//		EndIf;
//	EndIf;
	
	Cancel = False;
	
//	If GenerateInvoicesSendByEmail Or GenerateActsSendByEmail Then
//		If Not ValueIsFilled(GenerateInvoicesMessageTemplate) Then
//			CommonUseClientServer.MessageToUser(
//				NStr("ru = 'Не выбран шаблон рассылки электронных сообщений!';
//					|en = 'Не выбран шаблон рассылки электронных сообщений!';"),,
//				"GenerateInvoicesMessageTemplate"
//			);
//			Cancel = True;
//		EndIf;
//	EndIf;
	
	If GenerateInvoicesPrint Then
		If GenerateInvoicesPrintForms.Count() = 0 Then
			CommonUseClientServer.MessageToUser(
				NStr("en='No print form for Payment Invoices has been selected!';ru='Не выбрана ни одна печатная форма для Счетов на оплату!';vi='Chưa chọn mẫu in nào cho Yêu cầu thanh toán!'"),,
				"GenerateInvoicesPrintFormsPresentation"
			);
			Cancel = True;
		EndIf;
	EndIf;
	
	If GenerateActsPrint Then
		If GenerateActsPrintForms.Count() = 0 Then
			CommonUseClientServer.MessageToUser(
				NStr("en='No print form for Acceptance certificates has been selected!';ru='Не выбрана ни одна печатная форма для Актов выполненных работ!';vi='Chưa chọn mẫu in nào cho Biên bản cung cấp dịch vụ!'"),,
				"GenerateActsPrintFormsPresentation"
			);
			Cancel = True;
		EndIf;
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	StartDocumentPackageCreation();
	
EndProcedure

&AtClient
Procedure GenerateInvoicesUncheckMarks(Command)
	
	MarksCounterInvoices = 0;
	MarkCounterActs = 0;
	For Each Item In ListServiceContracts Do
		
		Item.GenerateInvoice = False;
		Item.GenerateAct = False;
		
	EndDo;
	ConfigureCommandsOfMarksSetting(Items, MarksCounterInvoices, MarkCounterActs);
	
EndProcedure

&AtClient
Procedure GenerateInvoicesCheckMarks(Command)
	
	MarksCounterInvoices = 0;
	For Each Item In ListServiceContracts Do
		
		If Not ValueIsFilled(Item.Amount) Then
			Continue;
		EndIf;
		
		Item.GenerateInvoice = True;
		MarksCounterInvoices = MarksCounterInvoices + 1;
		
	EndDo;
	
	ConfigureCommandsOfMarksSetting(Items, MarksCounterInvoices);
	
EndProcedure

&AtClient
Procedure GenerateActsUncheckMarks(Command)
	
	MarkCounterActs = 0;
	For Each Item In ListServiceContracts Do
		
		Item.GenerateAct = False;
		
	EndDo;
	ConfigureCommandsOfMarksSetting(Items,, MarkCounterActs);
	
EndProcedure

&AtClient
Procedure GenerateActsCheckMarks(Command)
	
	MarksCounterInvoices = 0;
	MarkCounterActs = 0;
	For Each Item In ListServiceContracts Do
		
		If Not ValueIsFilled(Item.Amount) Then
			Continue;
		EndIf;
		
		Item.GenerateInvoice = True;
		Item.GenerateAct = True;
		MarkCounterActs = MarkCounterActs + 1;
		
	EndDo;
	MarksCounterInvoices = MarkCounterActs;
	
	ConfigureCommandsOfMarksSetting(Items, MarksCounterInvoices, MarkCounterActs);
	
EndProcedure

&AtClient
Procedure RefreshFormData(Command)
	
	PeriodicityChanged = GetServiceContractsPeriodicity();
	If PeriodicityChanged Then
		GetFilterByPeriodicityPeriod(FilterPeriod, PeriodPresentation, PeriodPeriodicity, DocumentsGenerationDateInvoices, DocumentGenerationDateActs);
	EndIf;
	StartFormDataUpdate();
	
EndProcedure

&AtClient
Procedure SelectPreviousPeriod(Command)
	
	GetFilterByPeriodicityPeriod(FilterPeriod, PeriodPresentation, PeriodPeriodicity, DocumentsGenerationDateInvoices, DocumentGenerationDateActs, -1);
	StartFormDataUpdate();
	
EndProcedure

&AtClient
Procedure SelectNextPeriod(Command)
	
	GetFilterByPeriodicityPeriod(FilterPeriod, PeriodPresentation, PeriodPeriodicity, DocumentsGenerationDateInvoices, DocumentGenerationDateActs, 1);
	StartFormDataUpdate();
	
EndProcedure

#EndRegion

#Region WorkWithPeriodAndPeriodicity

&AtServer
Function GetServiceContractsPeriodicity()
	
	PeriodicityChangedAutomatically = False;
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	CASE
	|		WHEN CounterpartyContracts.ServiceContractPeriodicity = VALUE(Enum.BillingServiceContractPeriodicity.QUARTER)
	|				OR CounterpartyContracts.ServiceContractPeriodicity = VALUE(Enum.BillingServiceContractPeriodicity.HalfYear)
	|				OR CounterpartyContracts.ServiceContractPeriodicity = VALUE(Enum.BillingServiceContractPeriodicity.YEAR)
	|			THEN VALUE(Enum.BillingServiceContractPeriodicity.MONTH)
	|		ELSE CounterpartyContracts.ServiceContractPeriodicity
	|	END AS ServiceContractPeriodicity
	|INTO TTContractsPeriodicity
	|FROM
	|	Catalog.CounterpartyContracts AS CounterpartyContracts
	|		INNER JOIN Enum.BillingServiceContractPeriodicity AS BillingServiceContractPeriodicity
	|		ON CounterpartyContracts.ServiceContractPeriodicity = BillingServiceContractPeriodicity.Ref
	|
	|GROUP BY
	|	CASE
	|		WHEN CounterpartyContracts.ServiceContractPeriodicity = VALUE(Enum.BillingServiceContractPeriodicity.QUARTER)
	|				OR CounterpartyContracts.ServiceContractPeriodicity = VALUE(Enum.BillingServiceContractPeriodicity.HalfYear)
	|				OR CounterpartyContracts.ServiceContractPeriodicity = VALUE(Enum.BillingServiceContractPeriodicity.YEAR)
	|			THEN VALUE(Enum.BillingServiceContractPeriodicity.MONTH)
	|		ELSE CounterpartyContracts.ServiceContractPeriodicity
	|	END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTContractsPeriodicity.ServiceContractPeriodicity AS Periodicity,
	|	TTContractsPeriodicity.ServiceContractPeriodicity.Order AS ServiceContractPeriodicityOrder
	|FROM
	|	TTContractsPeriodicity AS TTContractsPeriodicity
	|
	|ORDER BY
	|	ServiceContractPeriodicityOrder";
	
	ContractsPeriodicity.Clear();
	
	SELECTION = Query.Execute().Select();
	While SELECTION.Next() Do
		PeriodicityPresentation = PeriodicityPresentation(SELECTION.Periodicity);
		ContractsPeriodicity.Add(SELECTION.Periodicity, PeriodicityPresentation);
	EndDo;
	
	If ContractsPeriodicity.Count() <> 0 And ContractsPeriodicity.FindByValue(PeriodPeriodicity) = Undefined Then
		PeriodPeriodicity = ContractsPeriodicity[0].Value;
		PeriodicityChangedAutomatically = True;
	EndIf;
	
	If ContractsPeriodicity.Count() > 1 Then
		Items.PeriodPresentation.Hyperlink = True;
		Items.PeriodPresentation.ToolTip = NStr("en='Change periodicity';ru='Изменить периодичность';vi='Thay đổi định kỳ'");
	Else
		Items.PeriodPresentation.Hyperlink = False;
		Items.PeriodPresentation.ToolTip = "";
	EndIf;
	
	Return PeriodicityChangedAutomatically;
	
EndFunction

&AtServerNoContext
Function PeriodicityPresentation(Periodicity)
	
	Presentation = Undefined;
	
	If Periodicity = Enums.BillingServiceContractPeriodicity.Day Then
		Presentation = NStr("en='This day';ru='Этот день';vi='Ngày này'");
	ElsIf Periodicity = Enums.BillingServiceContractPeriodicity.Week Then
		Presentation = NStr("en='This week';ru='Эта неделя';vi='Tuần này'");
	ElsIf Periodicity = Enums.BillingServiceContractPeriodicity.Month Then
		Presentation = NStr("en='This month';ru='Этот месяц';vi='Tháng này'");
	ElsIf Periodicity = Enums.BillingServiceContractPeriodicity.Quarter Then
		Presentation = NStr("en='This quarter';ru='Этот квартал';vi='Quý này'");
	ElsIf Periodicity = Enums.BillingServiceContractPeriodicity.HalfYear Then
		Presentation = NStr("en='This half year';ru='Это полугодие';vi='Nửa năm nay'");
	ElsIf Periodicity = Enums.BillingServiceContractPeriodicity.Year Then
		Presentation = NStr("en='This year';ru='Этот год';vi='Năm nay'");
	EndIf;
	
	Return Presentation;
	
EndFunction

&AtServer
Procedure SelectPeriodicity(SelectedPeriodicity)
	
	PeriodPeriodicity = SelectedPeriodicity;
	
	If PeriodPeriodicity = Enums.BillingServiceContractPeriodicity.Day Then
		TooltipPreviousInterval = NStr("en='Previous day';ru='Предыдущий день';vi='Ngày hôm trước'");
		ToolTipNextInterval  = NStr("en='Next day';ru='Следующий день';vi='Ngày hôm sau'");
	ElsIf PeriodPeriodicity = Enums.BillingServiceContractPeriodicity.Week Then
		TooltipPreviousInterval = NStr("en='Previous week';ru='Предыдущая неделя';vi='Tuần trước'");
		ToolTipNextInterval  = NStr("en='Next week';ru='Следующая неделя';vi='Tuần sau'");
	ElsIf PeriodPeriodicity = Enums.BillingServiceContractPeriodicity.Month Then
		TooltipPreviousInterval = NStr("en='Previous month';ru='Предыдущий месяц';vi='Tháng trước'");
		ToolTipNextInterval  = NStr("en='Next month';ru='Следующий месяц';vi='Tháng sau'");
	ElsIf PeriodPeriodicity = Enums.BillingServiceContractPeriodicity.Quarter Then
		TooltipPreviousInterval = NStr("en='Previous quarter';ru='Предыдущий квартал';vi='Quý trước'");
		ToolTipNextInterval  = NStr("en='Next quarter';ru='Следующий квартал';vi='Quý sau'");
	ElsIf PeriodPeriodicity = Enums.BillingServiceContractPeriodicity.Year Then
		TooltipPreviousInterval = NStr("en='Previous year';ru='Предыдущий год';vi='Năm ngoái'");
		ToolTipNextInterval  = NStr("en='Next year';ru='Следующий год';vi='Năm sau'");
	EndIf;
	
	Commands.Find("SelectPreviousPeriod").ToolTip = TooltipPreviousInterval;
	Commands.Find("SelectNextPeriod").ToolTip = ToolTipNextInterval;
	
EndProcedure

&AtClientAtServerNoContext
Procedure GetFilterByPeriodicityPeriod(FilterPeriod, PeriodPresentation, Periodicity, DocumentsGenerationDateInvoices, DocumentGenerationDateActs, Direction = 0)
	
	CurrentSessionDate = SmallBusinessReUse.GetSessionCurrentDate();
	If Direction = 0 Then
		BeginnigDate = CurrentSessionDate;
	ElsIf Direction > 0 Then
		BeginnigDate = FilterPeriod.EndDate;
	Else
		BeginnigDate = FilterPeriod.StartDate;
	EndIf;
	
	If Periodicity       = PredefinedValue("Enum.BillingServiceContractPeriodicity.Day") Then
		
		FilterPeriod.StartDate    = BegOfDay(BeginnigDate + Direction);
		FilterPeriod.EndDate = EndOfDay(FilterPeriod.StartDate);
		
	ElsIf Periodicity  = PredefinedValue("Enum.BillingServiceContractPeriodicity.Week") Then
		
		FilterPeriod.StartDate    = BegOfWeek(BeginnigDate + Direction);
		FilterPeriod.EndDate = EndOfWeek(FilterPeriod.StartDate);
		
	ElsIf Periodicity  = PredefinedValue("Enum.BillingServiceContractPeriodicity.Month") Then
		
		FilterPeriod.StartDate    = BegOfMonth(BeginnigDate + Direction);
		FilterPeriod.EndDate = EndOfMonth(FilterPeriod.StartDate);
		
	ElsIf Periodicity  = PredefinedValue("Enum.BillingServiceContractPeriodicity.Quarter") Then
		
		FilterPeriod.StartDate    = BegOfQuarter(BeginnigDate + Direction);
		FilterPeriod.EndDate = EndOfQuarter(FilterPeriod.StartDate);
		
	ElsIf Periodicity  = PredefinedValue("Enum.BillingServiceContractPeriodicity.HalfYear") Then
		
		If Direction = 0 Then
			
			FilterPeriod = New StandardPeriod(StandardPeriodVariant.ThisHalfYear);
			
		Else
			
			BegOfYear      = BegOfYear(BeginnigDate + Direction);
			HalfYearBeginning = AddMonth(BegOfYear, 6);
			
			If BeginnigDate + Direction >= HalfYearBeginning Then
				FilterPeriod.StartDate    = HalfYearBeginning;
				FilterPeriod.EndDate = EndOfYear(BeginnigDate + Direction);
			Else
				FilterPeriod.StartDate    = BegOfYear;
				FilterPeriod.EndDate = EndOfMonth(AddMonth(BegOfYear, 5));
			EndIf;
			
		EndIf;
		
	ElsIf Periodicity  = PredefinedValue("Enum.BillingServiceContractPeriodicity.Year") Then
		
		FilterPeriod.StartDate    = BegOfYear(BeginnigDate + Direction);
		FilterPeriod.EndDate = EndOfYear(FilterPeriod.StartDate);
		
	EndIf;
	
	PeriodPresentation = WorkWithFiltersClientServer.RefreshPeriodPresentation(FilterPeriod);
	
	If CurrentSessionDate >= FilterPeriod.StartDate
		And CurrentSessionDate <= FilterPeriod.EndDate Then
		// Актуальный период; Дата формирования документов = текущая дата.
		DocumentsGenerationDateInvoices = CurrentSessionDate;
	Else
		// Предыдущий/будущий период; Дата формирования документов = конец периода.
		DocumentsGenerationDateInvoices = FilterPeriod.EndDate;
	EndIf;
	
	DocumentGenerationDateActs = DocumentsGenerationDateInvoices;
	
EndProcedure

&AtClient
Function ValidateDocumentsGenerationDateChoice(DocumentType, NewValue, StandardProcessing = Undefined)
	
	If NewValue >= FilterPeriod.StartDate
		And NewValue <= FilterPeriod.EndDate Then
		
		// Дата корректна; принимает новое значение.
		ChangeDate = True;
		
		If DocumentType = "Account" Then
			If DocumentGenerationDateInvoicesCache = Undefined Then
				DocumentsGenerationDateActsChangeAutomatically = (DocumentsGenerationDateInvoices = DocumentGenerationDateActs);
			Else
				DocumentsGenerationDateActsChangeAutomatically = (DocumentGenerationDateInvoicesCache = DocumentGenerationDateActs);
			EndIf;
		EndIf;
		
	Else
		
		// Дата некорректна; устанавливается предыдущее значение.
		ChangeDate = False;
		
		If StandardProcessing <> Undefined Then
			// Дата изменялась через стандартный диалог выбора даты.
			StandardProcessing = False;
		Else
			// Дата изменялась через редактирование текста поля ввода.
			If DocumentType = "Account" Then
				DocumentsGenerationDateInvoices = DocumentGenerationDateInvoicesCache;
			ElsIf DocumentType = "ACT" Then
				DocumentGenerationDateActs = DocumentsGenerationDateActsCache;
			EndIf;
		EndIf;
		
		ShowMessageBox(,
			StrTemplate(
				NStr("en='The date of generated documents should be in the interval of the selected period: %1 - %2.';ru='Дата формируемых документов должна находиться в интервале выбранного периода: %1 — %2';vi='Ngày của tài liệu được tạo phải nằm trong khoảng thời gian đã chọn:%1 -%2'"),
				Format(FilterPeriod.StartDate, "DLF=D"),
				Format(FilterPeriod.EndDate, "DLF=D")
			)
		);
		
	EndIf;
	
	If DocumentType = "Account" Then
		DocumentGenerationDateInvoicesCache = Undefined;
	ElsIf DocumentType = "ACT" Then
		DocumentsGenerationDateActsCache = Undefined;
	EndIf;
	
	Return ChangeDate;
	
EndFunction

#EndRegion

#Region BackgroundJobsExecution

&AtClient
Procedure StartFormDataUpdate()
	
	ClearMessages();
	
	LongOperation = StartFormDataUpdateServer();
	
	WaitingParameters = LongActionsClient.WaitingParameters(ThisObject);
	WaitingParameters.ShowWaitingWindow = False;
	LongActionsClient.WaitForCompletion(LongOperation, New NotifyDescription("ProcessBackgroundJobCompletion", ThisObject), WaitingParameters);
	
	FormManagement();
	
EndProcedure

&AtClient
Procedure StartDocumentPackageCreation()
	
	ClearMessages();
	
	LongOperation = StartDocumentPackageCreationServer();
	
	WaitingParameters = LongActionsClient.WaitingParameters(ThisObject);
	WaitingParameters.ShowWaitingWindow = False;
	LongActionsClient.WaitForCompletion(LongOperation, New NotifyDescription("ProcessBackgroundJobCompletion", ThisObject), WaitingParameters);
	
	FormManagement();
	
EndProcedure

&AtServer
Function StartFormDataUpdateServer()
	
	BackgroundJobName = "BackgroundJobUpdateFormData";
	BackgroundJobStarted = True;
	ProcedureName = "DataProcessors.InvoicingByServiceContracts.GetDataByServiceContracts";
	
	Periodicities = New ValueList;
	Periodicities.Add(PeriodPeriodicity);
	If PeriodPeriodicity = Enums.BillingServiceContractPeriodicity.Month Then
		Periodicities.Add(Enums.BillingServiceContractPeriodicity.Quarter);
		Periodicities.Add(Enums.BillingServiceContractPeriodicity.HalfYear);
		Periodicities.Add(Enums.BillingServiceContractPeriodicity.Year);
	EndIf;
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("Periodicities", Periodicities);
	ProcedureParameters.Insert("BeginDate",    FilterPeriod.StartDate);
	ProcedureParameters.Insert("EndDate", FilterPeriod.EndDate);
	ProcedureParameters.Insert("DocumentsGenerationDateInvoices", DocumentsGenerationDateInvoices);
	
	ExecuteParameters = LongActions.BackgroundExecutionParameters(UUID);
	ExecuteParameters.BackgroundJobDescription = NStr("en='Getting data on service contracts';ru='Получение данных по договорам обслуживания';vi='Nhận dữ liệu về hợp đồng dịch vụ'");
	
	Return LongActions.ExecuteBackground(ProcedureName, ProcedureParameters, ExecuteParameters);
	
EndFunction

&AtServer
Function StartDocumentPackageCreationServer()
	
	BackgroundJobName = "BackgroundJobCreateDocumentPackage";
	BackgroundJobStarted = True;
	ProcedureName = "DataProcessors.InvoicingByServiceContracts.CreateDocumentPackage";
	
	ContractsPeriodicityFilter = New ValueList;
	ContractsPeriodicityFilter.Add(PeriodPeriodicity);
	If PeriodPeriodicity = Enums.BillingServiceContractPeriodicity.Month Then
		ContractsPeriodicityFilter.Add(Enums.BillingServiceContractPeriodicity.Quarter);
		ContractsPeriodicityFilter.Add(Enums.BillingServiceContractPeriodicity.HalfYear);
		ContractsPeriodicityFilter.Add(Enums.BillingServiceContractPeriodicity.Year);
	EndIf;
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("BeginDate",                      FilterPeriod.StartDate);
	ProcedureParameters.Insert("EndDate",                   FilterPeriod.EndDate);
	ProcedureParameters.Insert("DocumentsGenerationDateInvoices", DocumentsGenerationDateInvoices);
	ProcedureParameters.Insert("DocumentGenerationDateActs",  DocumentGenerationDateActs);
	ProcedureParameters.Insert("Periodicities",                   ContractsPeriodicityFilter);
	ProcedureParameters.Insert("ListServiceContracts",            ListServiceContracts.Unload());
	ProcedureParameters.Insert("ListServiceContractsExecution", ListServiceContractsExecution.Unload());
	ProcedureParameters.Insert("ListBillingDetails",             ListBillingDetails.Unload());
	ProcedureParameters.Insert("GenerateActs",                        GenerateActs);
	ProcedureParameters.Insert("GenerateActsPost",               GenerateActsPost);
	ProcedureParameters.Insert("GenerateActsSendByEmail",       GenerateActsSendByEmail);
	ProcedureParameters.Insert("GenerateActsGenerateInvoices", GenerateActsGenerateInvoices);
	ProcedureParameters.Insert("GenerateInvoicesSendByEmail", GenerateInvoicesSendByEmail);
	ProcedureParameters.Insert("MessagePattern", GenerateInvoicesMessageTemplate);
	
	ExecuteParameters = LongActions.BackgroundExecutionParameters(UUID);
	ExecuteParameters.BackgroundJobDescription = NStr("en='Getting data on service contracts';ru='Получение данных по договорам обслуживания';vi='Nhận dữ liệu về hợp đồng dịch vụ'");
	
	Return LongActions.ExecuteBackground(ProcedureName, ProcedureParameters, ExecuteParameters);
	
EndFunction

// Вызывает серверную обработку заполнения таблиц формы. Если в фоновом задании выполнялось формирование документов,..
// то на клиентскую сторону возвращается массив созданных документов для дальнейшей обработки (вызов команд печати и т.д.)
//
&AtClient
Procedure ProcessBackgroundJobCompletion(Result, AdditionalParameters) Export
	
	BackgroundJobStarted = False;
	
	ProcessBackgroundJobCompletionAtServer(Result);
	
	If BackgroundJobName = "BackgroundJobCreateDocumentPackage" Then
		
		TextNotificationActs = "";
		TextNotificationInvoices = "";
		TextNotificationEmails = "";
		
		If Result.Property("AcceptanceCertificates") Then
			
			TextNotificationActs = StrTemplate(
				NStr("en='Acceptance certificates - %1';ru='Актов выполненных работ — %1';vi='Biên bản thực hiện công việc — %1'"),
				Result.AcceptanceCertificates.Count()
			);
			
			If GenerateActsPrint And Result.Property("AcceptanceCertificatesTemplatesNames") Then
				PrintManagementClient.ExecutePrintCommand("Document.AcceptanceCertificate", Result.AcceptanceCertificatesTemplatesNames, Result.AcceptanceCertificates, ThisObject);
			EndIf;
			
		EndIf;
		
		If Result.Property("InvoicesForPayment") Then
			
			TextNotificationInvoices = StrTemplate(
				NStr("en='Payment invoices — %1';ru='Счетов на оплату — %1';vi='Yêu cầu thanh toán — %1'"),
				Result.InvoicesForPayment.Count()
			);
			
			If GenerateInvoicesPrint And Result.Property("InvoicesForPaymentTemplatesNames") Then
				PrintManagementClient.ExecutePrintCommand("Document.InvoiceForPayment", Result.InvoicesForPaymentTemplatesNames, Result.InvoicesForPayment, ThisObject);
			EndIf;
			
		EndIf;
		
		If Result.Property("Emails") Then
			
			TextNotificationEmails = StrTemplate(
				NStr("en='Email — %1';ru='Электронных писем — %1';vi='E-mail — %1'"),
				Result.Emails.Count()
			);
			
		EndIf;
		
		TextNotification = StrTemplate(
			NStr("en='Documents created:%1%2%3';ru='Создано документов:%1%2%3';vi='Đã tạo các chứng từ: %1%2%3'"),
			TextNotificationInvoices,
			TextNotificationActs,
			TextNotificationEmails
		);
		
		Text = NStr("en='Documents created:';ru='Создано документов:';vi='Đã tạo các chứng từ:'");
		Explanation = StrTemplate(
			"%1%2%3",
			TextNotificationInvoices,
			?(ValueIsFilled(TextNotificationActs), Chars.LF + TextNotificationActs, ""),
			?(ValueIsFilled(TextNotificationEmails), Chars.LF + TextNotificationEmails, "")
		);
		
		ShowUserNotification(Text,, Explanation);
		
	EndIf;
	
	FormManagement();
	
EndProcedure

// Заполняет таблицы формы: СписокВыполнениеДоговоровОбслуживания, СписокДоговорыОбслуживания.
// В случае если в фоновом задании создавались документы, они будут добавлены в возвращаемый параметр Результат.
//
&AtServer
Procedure ProcessBackgroundJobCompletionAtServer(Result)
	
	FormData = GetFromTempStorage(Result.ResultAddress);
	
	If FormData.Property("Errors") Then
		For Each Error In FormData.Errors Do
			UserMessage = New UserMessage;
			FillPropertyValues(UserMessage, Error);
			UserMessage.TargetID = UUID;
			UserMessage.Message();
		EndDo;
	EndIf;
	
	If Result <> Undefined Then
		
		If FormData.Property("InvoicesForPayment") Then
			
			InvoicesForPaymentTemplatesNames = "";
			
			For Each PrintCommand In GetFromTempStorage(GenerateInvoicesPrintCommandsAddress) Do
				If GenerateInvoicesPrintForms.FindByValue(PrintCommand.ID) = Undefined Then
					Continue;
				EndIf;
				
				ID = PrintCommand.ID;
				If PrintCommand.PrintManager = "StandardSubsystems.AdditionalReportsAndDataProcessors" Then
					ID = "ExternalPrintForm." + ID;
				EndIf;
				
				If InvoicesForPaymentTemplatesNames = "" Then
					InvoicesForPaymentTemplatesNames = ID;
				Else
					InvoicesForPaymentTemplatesNames = InvoicesForPaymentTemplatesNames + "," +  ID;
				EndIf;
			EndDo;
			
			Result.Insert("InvoicesForPayment", FormData.InvoicesForPayment);
			Result.Insert("InvoicesForPaymentTemplatesNames", InvoicesForPaymentTemplatesNames);
		EndIf;
		
		If FormData.Property("AcceptanceCertificates") Then
			
			AcceptanceCertificatesTemplatesNames = "";
			
			For Each PrintCommand In GetFromTempStorage(GenerateActsPrintCommandsAddress) Do
				If GenerateActsPrintForms.FindByValue(PrintCommand.ID) = Undefined Then
					Continue;
				EndIf;
				
				ID = PrintCommand.ID;
				If PrintCommand.PrintManager = "StandardSubsystems.AdditionalReportsAndDataProcessors" Then
					ID = "ExternalPrintForm." + ID;
				EndIf;
				
				If AcceptanceCertificatesTemplatesNames = "" Then
					AcceptanceCertificatesTemplatesNames = ID;
				Else
					AcceptanceCertificatesTemplatesNames = AcceptanceCertificatesTemplatesNames + "," +  ID;
				EndIf;
			EndDo;
			
			Result.Insert("AcceptanceCertificates", FormData.AcceptanceCertificates);
			Result.Insert("AcceptanceCertificatesTemplatesNames", AcceptanceCertificatesTemplatesNames);
		EndIf;
		
		If FormData.Property("Emails") Then
			Result.Insert("Emails", FormData.Emails);
		EndIf;
		
	EndIf;
	
	ListServiceContracts.Load(FormData.ListServiceContracts);
	ListServiceContractsExecution.Load(FormData.ListServiceContractsExecution);
	ListBillingDetails.Load(FormData.ListBillingDetails);
	ListServiceContractDetails.Clear();
	MarksCounterInvoices = FormData.MarksCounterInvoices;
	MarkCounterActs = FormData.MarkCounterActs;
	
	If ValueIsFilled(CurrentCounterparty)
		And ValueIsFilled(CurrentContract) Then
		
		// После обновления данных на форме выделить строку, которая была выбрана до обновления.
		FilterParameters = New Structure("Counterparty,Contract", CurrentCounterparty, CurrentContract);
		Rows = ListServiceContracts.FindRows(FilterParameters);
		If Rows.Count() <> 0 Then
			Items.ListServiceContracts.CurrentRow = Rows[0].GetID();
			FillListServiceContractDetailsServer();
			
			HasSalesWithPrice = Rows[0].HasItemsWithPrice;
			HasSalesWithoutPrice = Rows[0].HasItemsWithoutPrice;
			
		Else
			CurrentCounterparty = Undefined;
			CurrentContract    = Undefined;
		EndIf;
		
	EndIf;
	
	SetDynamicListFilters();
	ConfigureVisibilityOfServiceContractDetailsListColumns();
	ConfigureCommandsOfMarksSetting(Items, MarksCounterInvoices, MarkCounterActs);
	
EndProcedure

#EndRegion

#Region FormSettings

&AtServer
Procedure RestoreFormSettings()
	
	ObjectKey = "DataProcessorObject.InvoicingByServiceContracts";
	
	Settings = New Structure;
	Settings.Insert("PeriodPeriodicity", Enums.BillingServiceContractPeriodicity.Month);
	Settings.Insert("FormShowColumnDate", False);
	Settings.Insert("FormShowColumnContracts", False);
	Settings.Insert("FormShowColumnRates", True);
	
	Settings.Insert("GenerateActs", False);
	Settings.Insert("GenerateActsPost", False);
	Settings.Insert("GenerateActsPrint", False);
//	Settings.Insert("GenerateActsGenerateInvoices", False);
//	Settings.Insert("GenerateActsSendByEmail", False);
	
//	Settings.Insert("GenerateInvoicesSendByEmail", False);
	Settings.Insert("GenerateInvoicesPrint", False);
	Settings.Insert("GenerateInvoicesMessageTemplate");
	
	For Each Setting In Settings Do
		
		SettingValue = CommonUse.CommonSettingsStorageImport(ObjectKey, Setting.Key, Setting.Value);
		ThisForm[Setting.Key] = SettingValue;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SaveFormSettings()
	
	Settings = New Array;
	Settings.Add("PeriodPeriodicity");
	Settings.Add("FormShowColumnDate");
	Settings.Add("FormShowColumnContracts");
	Settings.Add("FormShowColumnRates");
	
	Settings.Add("GenerateActs");
	Settings.Add("GenerateActsPost");
	Settings.Add("GenerateActsPrint");
	Settings.Add("GenerateActsGenerateInvoices");
	Settings.Add("GenerateActsSendByEmail");
	
	Settings.Add("GenerateInvoicesSendByEmail");
	Settings.Add("GenerateInvoicesPrint");
	Settings.Add("GenerateInvoicesMessageTemplate");
	
	ObjectKey = "DataProcessorObject.InvoicingByServiceContracts";
	
	For Each SettingKey In Settings Do
		
		CommonUse.CommonSettingsStorageSave(ObjectKey, SettingKey, ThisForm[SettingKey]);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region FormViewManagement

&AtClient
Procedure FormManagement()
	
	// Выполнение фонового задания
	If BackgroundJobStarted And BackgroundJobName = "BackgroundJobUpdateFormData" Then
		Items.ContractsPages.CurrentPage = Items.PagePendingOperationExecution;
		Items.LabelWaitDataUpdate.Visible = True;
		Items.LabelWaitDocumentGeneration.Visible = False;
	ElsIf BackgroundJobStarted And BackgroundJobName = "BackgroundJobCreateDocumentPackage" Then
		Items.ContractsPages.CurrentPage = Items.PagePendingOperationExecution;
		Items.LabelWaitDataUpdate.Visible = False;
		Items.LabelWaitDocumentGeneration.Visible = True;
	ElsIf Not BackgroundJobStarted Then
		Items.ContractsPages.CurrentPage = Items.PageListServiceContracts;
	EndIf;
	
	Items.CommandBarGroupForms.Enabled  = Not BackgroundJobStarted;
	Items.GroupDetailsByContract.Enabled = Not BackgroundJobStarted;
	Items.RightPanel.Enabled                = Not BackgroundJobStarted;
	
	// ГруппаКолонки
	Items.ListServiceContractsGroupInvoicingDate.Visible = FormShowColumnDate;
	Items.ListServiceContractsContract.Visible      = FormShowColumnContracts;
	Items.ListServiceContractsTariffPlan.Visible = FormShowColumnRates;
	
	// ГруппаФормированиеСчетов
	Items.GenerateInvoicesPrintFormsPresentation.Visible = GenerateInvoicesPrint;
	
	// ГруппаФормированиеАктов
	Items.GenerateActsPost.Enabled                = GenerateActs;
	Items.GenerateActsPrint.Enabled                 = GenerateActs And GenerateActsPost;
	Items.GenerateActsPrintFormsPresentation.Visible = GenerateActs And GenerateActsPrint;
//	Items.GenerateActsGenerateInvoices.Enabled  = GenerateActs And GenerateActsPost;
//	Items.GenerateActsSendByEmail.Enabled        = GenerateActs And GenerateActsPost;
	
//	Items.GenerateInvoicesMessageTemplate.Visible = GenerateInvoicesSendByEmail Or GenerateActsSendByEmail;
	
	Items.ListServiceContractsGenerateAct.Visible = GenerateActs;
	ConfigureCommandsOfMarksSetting(Items,, MarkCounterActs);
	
	Items.GroupListAcceptanceCertificates.Visible = GenerateActs;
	
EndProcedure

&AtServer
Procedure SetFormConditionalAppearance()
	
	// Если СписокДоговорыОбслуживания.Сумма = 0, тогда неактивны флаги: ФормироватьСчет, ФормироватьАкт.
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	
	Filter = NewConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	Filter.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	Filter1 = Filter.Items.Add(Type("DataCompositionFilterItem"));
	
	Filter1.ComparisonType   = DataCompositionComparisonType.Equal;
	Filter1.Use  = True;
	Filter1.LeftValue  = New DataCompositionField(Items.ListServiceContractsAmount.DataPath);
	Filter1.RightValue = 0;
	
	Filter2 = Filter.Items.Add(Type("DataCompositionFilterItem"));
	
	Filter2.ComparisonType   = DataCompositionComparisonType.Equal;
	Filter2.Use  = True;
	Filter2.LeftValue  = New DataCompositionField("ListServiceContracts.HasItemsWithoutInvoicingAmount");
	Filter2.RightValue = False;
	
	MadeOutField                = NewConditionalAppearance.Fields.Items.Add();
	MadeOutField.Field           = New DataCompositionField(Items.ListServiceContractsGenerateInvoice.Name);
	MadeOutField.Use  = True;
	
	MadeOutField                = NewConditionalAppearance.Fields.Items.Add();
	MadeOutField.Field           = New DataCompositionField(Items.ListServiceContractsGenerateAct.Name);
	MadeOutField.Use  = True;
	
	Appearance = NewConditionalAppearance.Appearance.Items.Find("ReadOnly");
	Appearance.Value      = True;
	Appearance.Use = True;
	
	// Для оборотов номенклатуры, где УказанаСтоимость=Ложь.
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	
	Filter = NewConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.ComparisonType   = DataCompositionComparisonType.NotEqual;
	Filter.Use  = True;
	Filter.LeftValue  = New DataCompositionField(Items.ListServiceContractDetailsQuantityRenderedWithoutPrice.DataPath);
	Filter.RightValue = 0;
	
	MadeOutField                = NewConditionalAppearance.Fields.Items.Add();
	MadeOutField.Field           = New DataCompositionField(Items.ListServiceContractDetailsAmountRenderedWithoutPrice.Name);
	MadeOutField.Use  = True;
	
	Text = NStr("en='Without price';ru='Без цены';vi='Không có đơn giá'");
	Appearance = NewConditionalAppearance.Appearance.Items.Find("Text");
	Appearance.Value      = Text;
	Appearance.Use = True;
	
EndProcedure

&AtServer
Procedure ConfigureVisibilityOfServiceContractDetailsListColumns()
	
	If HasSalesWithPrice And Not HasSalesWithoutPrice
		Or Not HasSalesWithPrice And Not HasSalesWithoutPrice Then
		
		Items.ListServiceContractDetailsGroupRenderedWithPrice.Visible = True;
		Items.ListDetailsServicesContractGroupRenderedWithoutPrice.Visible = False;
		
		Items.ListServiceContractDetailsQuantityRenderedWithPrice.ShowInHeader = True;
		Items.ListServiceContractDetailsAmountRenderedWithPrice.ShowInHeader = True;
		Items.ListServiceContractDetailsQuantityRenderedWithoutPrice.ShowInHeader = False;
		Items.ListServiceContractDetailsAmountRenderedWithoutPrice.ShowInHeader = False;
		
	ElsIf Not HasSalesWithPrice And HasSalesWithoutPrice Then
		
		Items.ListServiceContractDetailsGroupRenderedWithPrice.Visible = False;
		Items.ListDetailsServicesContractGroupRenderedWithoutPrice.Visible = True;
		
		Items.ListServiceContractDetailsQuantityRenderedWithPrice.ShowInHeader = False;
		Items.ListServiceContractDetailsAmountRenderedWithPrice.ShowInHeader = False;
		Items.ListServiceContractDetailsQuantityRenderedWithoutPrice.ShowInHeader = True;
		Items.ListServiceContractDetailsAmountRenderedWithoutPrice.ShowInHeader = True;
		
	ElsIf HasSalesWithPrice And HasSalesWithoutPrice Then
		
		Items.ListServiceContractDetailsGroupRenderedWithPrice.Visible = True;
		Items.ListDetailsServicesContractGroupRenderedWithoutPrice.Visible = True;
		
		Items.ListServiceContractDetailsQuantityRenderedWithPrice.ShowInHeader = True;
		Items.ListServiceContractDetailsAmountRenderedWithPrice.ShowInHeader = True;
		Items.ListServiceContractDetailsQuantityRenderedWithoutPrice.ShowInHeader = False;
		Items.ListServiceContractDetailsAmountRenderedWithoutPrice.ShowInHeader = False;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureCommandsOfMarksSetting(Items, MarksCounterInvoices = Undefined, MarkCounterActs = Undefined)
	
	If MarksCounterInvoices <> Undefined Then
		Items.GenerateInvoicesUncheckMarks.Visible      = MarksCounterInvoices > 0;
		Items.GenerateInvoicesCheckMarks.Visible = MarksCounterInvoices = 0;
	EndIf;
	If MarkCounterActs <> Undefined Then
		Items.GenerateActsUncheckMarks.Visible       = MarkCounterActs > 0 And Items.ListServiceContractsGenerateAct.Visible;
		Items.GenerateActsCheckMarks.Visible  = MarkCounterActs = 0 And Items.ListServiceContractsGenerateAct.Visible;
	EndIf;
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Procedure SetDynamicListFilters()
	
	LisInvoicesForPayment.Parameters.SetParameterValue("Contract",       CurrentContract);
	LisInvoicesForPayment.Parameters.SetParameterValue("BeginOfPeriod", FilterPeriod.StartDate);
	LisInvoicesForPayment.Parameters.SetParameterValue("EndOfPeriod",  FilterPeriod.EndDate);
	
	ListAcceptanceCertificates.Parameters.SetParameterValue("Contract", CurrentContract);
	ListAcceptanceCertificates.Parameters.SetParameterValue("BeginOfPeriod", FilterPeriod.StartDate);
	ListAcceptanceCertificates.Parameters.SetParameterValue("EndOfPeriod", FilterPeriod.EndDate);
	
	ListRecordsByServiceContract.Parameters.SetParameterValue("Contract",       CurrentContract);
	ListRecordsByServiceContract.Parameters.SetParameterValue("BeginOfPeriod", FilterPeriod.StartDate);
	ListRecordsByServiceContract.Parameters.SetParameterValue("EndOfPeriod",  FilterPeriod.EndDate);
	
EndProcedure

&AtClient
Procedure FillListServiceContractDetails()
	
	CurrentRow = Items.ListServiceContracts.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	If CurrentRow.Contract = CurrentContract
		And CurrentRow.Counterparty = CurrentCounterparty Then
		Return;
	EndIf;
	
	ListServiceContractDetails.Clear();
	
	CurrentContract    = CurrentRow.Contract;
	CurrentCounterparty = CurrentRow.Counterparty;
	
	HasSalesWithoutPrice = CurrentRow.HasItemsWithoutPrice;
	HasSalesWithPrice  = CurrentRow.HasItemsWithPrice;
	
	FillListServiceContractDetailsServer();
	
EndProcedure

&AtServer
Procedure FillListServiceContractDetailsServer()
	
	If Not ValueIsFilled(CurrentContract) Then
		Return;
	EndIf;
	
	Rows = ListServiceContractsExecution.FindRows(New Structure("Contract", CurrentContract));
	For Each Str In Rows Do
		
		NewRow = ListServiceContractDetails.Add();
		FillPropertyValues(NewRow, Str);
		
	EndDo;
	
	SetDynamicListFilters();
	ConfigureVisibilityOfServiceContractDetailsListColumns();
	
EndProcedure

&AtServer
Procedure FillPrintFormsList()
	
	// Счета на оплату.
	GenerateInvoicesPrintForms.Clear();
	GenerateInvoicesPrintFormsPresentation = "";
	PrintObjectFormName = "Document.InvoiceForPayment.Form.ListForm";
	PrintCommands = PrintManagement.PrintCommandsForms(PrintObjectFormName);
	
	PrintFormsSettings = CommonUse.CommonSettingsStorageImport("PrintFormsSending", SettingsKeyInvoicePrintForms);
	If PrintFormsSettings <> Undefined Then
		For Each SelectedPrintForm In PrintFormsSettings Do
			Command = PrintCommands.Find(SelectedPrintForm, "ID");
			If Command = Undefined Then
				Continue;
			EndIf;
			
			GenerateInvoicesPrintForms.Add(SelectedPrintForm);
			
			If ValueIsFilled(GenerateInvoicesPrintFormsPresentation) Then
				GenerateInvoicesPrintFormsPresentation = GenerateInvoicesPrintFormsPresentation + ", ";
			EndIf;
			GenerateInvoicesPrintFormsPresentation = GenerateInvoicesPrintFormsPresentation + Command.Presentation;
		EndDo;
	Else
		DefaultPrintForm = "InvoiceForPayment";
		Command = PrintCommands.Find(DefaultPrintForm, "ID");
		If Command <> Undefined Then
			GenerateInvoicesPrintForms.Add(DefaultPrintForm);
			GenerateInvoicesPrintFormsPresentation = Command.Presentation
		EndIf;
	EndIf;
	
	GenerateInvoicesPrintCommandsAddress = PutToTempStorage(PrintCommands, UUID);
	
	If Not ValueIsFilled(GenerateInvoicesPrintFormsPresentation) Then
		GenerateInvoicesPrintFormsPresentation = NStr("en='<Print form is not selected>';ru='<Не выбрана печатная форма>';vi='<Chưa chọn mẫu in>'");
	EndIf;
	
	// Акты выполненных работ.
	GenerateActsPrintForms.Clear();
	GenerateActsPrintFormsPresentation = "";
	PrintObjectFormName = "Document.AcceptanceCertificate.Form.ListForm";
	PrintCommands = PrintManagement.PrintCommandsForms(PrintObjectFormName);
	
	PrintFormsSettings = CommonUse.CommonSettingsStorageImport("PrintFormsSending", SettingsKeyActPrintForms);
	If PrintFormsSettings <> Undefined Then
		For Each SelectedPrintForm In PrintFormsSettings Do
			Command = PrintCommands.Find(SelectedPrintForm, "ID");
			If Command = Undefined Then
				Continue;
			EndIf;
			
			GenerateActsPrintForms.Add(SelectedPrintForm);
			
			If ValueIsFilled(GenerateActsPrintFormsPresentation) Then
				GenerateActsPrintFormsPresentation = GenerateActsPrintFormsPresentation + ", ";
			EndIf;
			GenerateActsPrintFormsPresentation = GenerateActsPrintFormsPresentation + Command.Presentation;
		EndDo;
	Else
		DefaultPrintForm = "ACT";
		Command = PrintCommands.Find(DefaultPrintForm, "ID");
		If Command <> Undefined Then
			GenerateActsPrintForms.Add(DefaultPrintForm);
			GenerateActsPrintFormsPresentation = Command.Presentation
		EndIf;
	EndIf;
	
	GenerateActsPrintCommandsAddress = PutToTempStorage(PrintCommands, UUID);
	
	If Not ValueIsFilled(GenerateActsPrintFormsPresentation) Then
		GenerateActsPrintFormsPresentation = NStr("en='<Print form is not selected>';ru='<Не выбрана печатная форма>';vi='<Chưa chọn mẫu in>'");
	EndIf;
	
EndProcedure


&AtClient
Procedure GoToUserAccountSetup(Result, AdditionalParameters) Export
	
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
//	OpenForm("InformationRegister.UserAccounts.Form.UserAccountsSettings");
	
EndProcedure

#EndRegion

#Region FiltersLabels

&AtClient
Procedure CollapseExpandFiltersPanel(Item)
	
	ItemsNamesStructure = New Structure;
	ItemsNamesStructure.Insert("FiltersSettingsAndExtraInfo", Items.FiltersSettingsAndExtraInfo.Name);
	ItemsNamesStructure.Insert("DecorationExpandFilters", Items.GroupControlPanel.Name);
	ItemsNamesStructure.Insert("RightPanel", Items.FiltersSettingsAndExtraInfo.Name);
	
	NewValueVisibility = Not Items.FiltersSettingsAndExtraInfo.Visible;
	WorkWithFiltersClient.CollapseExpandFiltersPanel(ThisObject, NewValueVisibility, ItemsNamesStructure);
	
EndProcedure

#EndRegion
