
#Region FormEventHadlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Description	= Object.Description;
	
	SetFormConditionalAppearance();
	
	NationalCurrency	= Constants.NationalCurrency.Get();
	FixedContractAmount	= (Object.Amount <> 0);
	
	If Object.Ref.IsEmpty() Then
		
		FillPriceKind(True);
		FillCounterpartyPriceKind();
		
		If Not ValueIsFilled(Object.Company) Then
			
			CompanyByDefault = SmallBusinessReUse.GetValueByDefaultUser(UsersClientServer.AuthorizedUser(), "MainCompany");
			If ValueIsFilled(CompanyByDefault) Then
				Object.Company = CompanyByDefault;
			Else
				Object.Company = Catalogs.Companies.MainCompany;
			EndIf;
			
		EndIf;
		
		Object.VendorPaymentDueDate		= Constants.VendorPaymentDueDate.Get();
		Object.CustomerPaymentDueDate	= Constants.CustomerPaymentDueDate.Get();
		
		If Not ValueIsFilled(Object.SettlementsCurrency) Then
			Object.SettlementsCurrency	= NationalCurrency;
		EndIf;
		
		If Not IsBlankString(Parameters.FillingText) Then
			Object.ContractNo	= Parameters.FillingText;
			Object.Description	= GenerateDescription(Object.ContractNo, Object.ContractDate, Object.SettlementsCurrency);
		EndIf;
		
	EndIf;
	
	SetContractKindsChoiceList();
	
	If ValueIsFilled(Object.DiscountMarkupKind) Then
		Items.PriceKind.AutoChoiceIncomplete	= True;
		Items.PriceKind.AutoMarkIncomplete		= True;
	Else
		Items.PriceKind.AutoChoiceIncomplete	= False;
		Items.PriceKind.AutoMarkIncomplete		= False;
	EndIf;
	
	If Parameters.Property("Document") Then 
		ThisForm.OpeningDocument	= Parameters.Document;
	Else
		ThisForm.OpeningDocument	= Undefined;
	EndIf;
	
	GetBlankParameters();
	ThisForm.ShowDocumentBeginning	= True;
	ThisForm.DocumentCreated		= False;
	GenerateAndShowContract();
	
	// Billing
	BillingConfigureItemsVisibility();
	FillMailingRecipients();
	// End Billing
		
	SmallBusinessClientServer.SetPictureForComment(Items.GroupComment, Object.Comment);
	
	// StandardSubsystems.AdditionalReportsAndDataProcessors
	AdditionalReportsAndDataProcessors.OnCreateAtServer(ThisForm);
	// End StandardSubsystems.AdditionalReportsAndDataProcessors
	
	// StandardSubsystems.ObjectsAttributesEditProhibition
	ObjectsAttributesEditProhibition.LockAttributes(ThisForm);
	// End StandardSubsystems.ObjectsAttributesEditProhibition
	
	// StandardSubsystems.Properties
	AdditionalParameters = PropertiesManagementOverridable.FillAdditionalParameters(Object, "AdditionalAttributesGroup");
	PropertiesManagement.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.Printing
	PrintManagement.OnCreateAtServer(ThisForm, Items.ImportantCommandsGroup);
	// End StandardSubsystems.Printing
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	FormManagement();
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	ServiceContractEndDate = Object.ServiceContractEndDate;
		
	// StandardSubsystems.Properties
	PropertiesManagement.OnReadAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "PredefinedTemplateRestoration" Then 
		If Parameter = Object.ContractForm Then 
			FilterParameters = New Structure;
			FilterParameters.Insert("FormRefs", Object.ContractForm);
			ParameterArray = Object.EditableParameters.FindRows(FilterParameters);
			For Each String IN ParameterArray Do 
				String.Value = "";
			EndDo;
		EndIf;
	EndIf;
	
	If EventName = "ContractTemplateChangeAndRecordAtServer" Then 
		If Parameter = Object.ContractForm Then 
			ThisForm.DocumentCreated = False;
			GetBlankParameters();
			GenerateAndShowContract();
			ThisForm.Modified = True;
			ThisForm.ShowDocumentBeginning = True;
			ThisForm.CurrentParameterClicked = "";
		EndIf;
	EndIf;
	
	If EventName = "Write_Counterparty" Then
		// Billing
		If Object.IsServiceContract Then
			FillMailingRecipients();
		EndIf;
	EndIf;
	
	
	// StandardSubsystems.Properties
	If PropertiesManagementClient.ProcessAlerts(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Billing
	If Object.IsServiceContract And Not Object.DeletionMark Then
		Query = New Query;
		Query.Text = 
		"SELECT
		|	ServiceContractsTariffPlansProductsAndServicesAccounting.ProductsAndServices,
		|	ServiceContractsTariffPlansProductsAndServicesAccounting.CHARACTERISTIC,
		|	ISNULL(ProductsAndServicesPricesSliceLast.Price, 0) AS Price
		|INTO TTProductsAndServicesAndPrices
		|FROM
		|	Catalog.ServiceContractsTariffPlans.ProductsAndServicesAccounting AS ServiceContractsTariffPlansProductsAndServicesAccounting
		|		LEFT JOIN InformationRegister.ProductsAndServicesPrices.SliceLast(&ContractConclusionDate, PriceKind = &PriceKind) AS ProductsAndServicesPricesSliceLast
		|		ON ServiceContractsTariffPlansProductsAndServicesAccounting.ProductsAndServices = ProductsAndServicesPricesSliceLast.ProductsAndServices
		|			AND ServiceContractsTariffPlansProductsAndServicesAccounting.CHARACTERISTIC = ProductsAndServicesPricesSliceLast.CHARACTERISTIC
		|WHERE
		|	ServiceContractsTariffPlansProductsAndServicesAccounting.Ref = &TariffPlan
		|	AND ServiceContractsTariffPlansProductsAndServicesAccounting.PricingMethod = VALUE(Enum.BillingProductsAndServicesPricingMethod.ByContractPriceKind)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTProductsAndServicesAndPrices.ProductsAndServices,
		|	TTProductsAndServicesAndPrices.CHARACTERISTIC,
		|	TTProductsAndServicesAndPrices.Price
		|FROM
		|	TTProductsAndServicesAndPrices AS TTProductsAndServicesAndPrices
		|WHERE
		|	TTProductsAndServicesAndPrices.Price = 0";
		
		Query.SetParameter("ContractConclusionDate", Object.ServiceContractStartDate);
		Query.SetParameter("PriceKind", Object.PriceKind);
		Query.SetParameter("TariffPlan", Object.ServiceContractTariffPlan);
		
		SELECTION = Query.Execute().Select();
		While SELECTION.Next() Do
			CommonUseClientServer.MessageToUser(
				StrTemplate(NStr("en='For the product ""%1"" no price is set for price kind ""%2"" on contract start date (%3)!';ru='Для номенклатуры ""%1"" не установлена цена по виду цен ""%2"" на дату начала действия договора (%3)!';vi='Đối với mặt hàng ""%1"" chưa đặt đơn giá theo dạng giá ""%2"" tại ngày hợp đồng bắt đầu có hiệu lực (%3)!'"),
					SmallBusinessServer.PresentationOfProductsAndServices(SELECTION.ProductsAndServices, SELECTION.CHARACTERISTIC),
					Object.PriceKind,
					Format(Object.ServiceContractStartDate, "DLF=Д")
				),
				SELECTION.ProductsAndServices,
				,,
				Cancel
			);
		EndDo;
	EndIf;
	
	If MailingRecipientsRefill Then
		CurrentObject.ServiceContractMailingRecipients.Clear();
		For Each Str In BulkEmailRecipients Do
			
			If Not Str.Check Then
				Continue;
			EndIf;
			
			NewRow = CurrentObject.ServiceContractMailingRecipients.Add();
			FillPropertyValues(NewRow, Str);
			
		EndDo;
	EndIf;
	// End Billing
	
	// Mechanism handler "Properties".
	PropertiesManagement.BeforeWriteAtServer(ThisForm, CurrentObject);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
		
	// Billing
	If BusinessActivityChanged Then
		NotifyChanged(Object.ServiceContractBusinessActivity);
	EndIf;
	If NotifyAboutContractRecord Then
		NotifyChoice(Object.Ref);
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// Billing
	If CurrentObject.Description <> Description
		And ValueIsFilled(Object.ServiceContractBusinessActivity) Then
		
		BusinessActivityChanged = 
		Catalogs.CounterpartyContracts.RenameBusinessActivityForServiceContract(
			Object.ServiceContractBusinessActivity,
			Object.Owner,
			Object.Description,
			Description
		);
		
		Description = CurrentObject.Description;
		
	EndIf;
	
	SmallBusinessClientServer.SetPictureForComment(Items.GroupComment, Object.Comment);
	
	// Handler of the subsystem prohibiting the object attribute editing.
	ObjectsAttributesEditProhibition.LockAttributes(ThisForm);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If FixedContractAmount And Object.Amount = 0 Then
		
		ErrorText = NStr("en='The contract amount is not filled.';ru='Не заполнена сумма договора.';vi='Chưa điền số tiền hợp đồng.'");
		CommonUseClientServer.MessageToUser(
			ErrorText,
			Object.Ref,
			"Object.Amount",
			,
			Cancel);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormItemEventHadlers

&AtClient
Procedure OwnerOnChange(Item)
		
	// Billing
	If Object.IsServiceContract Then
		FillMailingRecipients();
	EndIf;

EndProcedure

&AtClient
Procedure ContractNoOnChange(Item)
	
	Object.Description = GenerateDescription(Object.ContractNo, Object.ContractDate, Object.SettlementsCurrency);
	
EndProcedure

&AtClient
Procedure ContractDateOnChange(Item)
	
	FillServiceContractStartDate();
	Object.Description = GenerateDescription(Object.ContractNo, Object.ContractDate, Object.SettlementsCurrency);
	
EndProcedure

&AtClient
Procedure SettlementsCurrencyOnChange(Item)
	
	Object.Description = GenerateDescription(Object.ContractNo, Object.ContractDate, Object.SettlementsCurrency);
	
EndProcedure

&AtClient
Procedure DiscountMarkupKindOnChange(Item)
	
	If ValueIsFilled(Object.DiscountMarkupKind) Then
		Items.PriceKind.AutoChoiceIncomplete	= True;
		Items.PriceKind.AutoMarkIncomplete		= True;	
	Else
		Items.PriceKind.AutoChoiceIncomplete	= False;
		Items.PriceKind.AutoMarkIncomplete		= False;
		ClearMarkIncomplete();
	EndIf;
	
EndProcedure

&AtClient
Procedure DiscountMarkupKindClear(Item, StandardProcessing)
	
	If ValueIsFilled(Object.DiscountMarkupKind) Then
		Items.PriceKind.AutoChoiceIncomplete	= True;
		Items.PriceKind.AutoMarkIncomplete		= True;	
	Else
		Items.PriceKind.AutoChoiceIncomplete	= False;
		Items.PriceKind.AutoMarkIncomplete		= False;
		ClearMarkIncomplete();
	EndIf;
	
EndProcedure

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	Items.ContractForm.AutoMarkIncomplete = False;
	If ThisForm.Modified Then
		ThisForm.DocumentCreated = False;
	EndIf;
	
	If Items.Pages.CurrentPage = Items.GroupPrintContract
		AND Not ThisForm.DocumentCreated Then 
		
		GenerateAndShowContract();
	EndIf;
	
EndProcedure

&AtClient
Procedure ContractFormOnChange(Item)
	
	If Item.EditText = "" Then
		ThisForm.DocumentCreated = False;
		GenerateAndShowContract();
	EndIf;
	
EndProcedure

&AtClient
Procedure ContractFormChoiceDataProcessor(Item, ValueSelected, StandardProcessing)
	
	If ValueIsFilled(Object.ContractForm) Then
		ThisForm.ShowDocumentBeginning = True;
	Else
		ThisForm.ShowDocumentBeginning = False;
	EndIf;
	If Object.ContractForm = ValueSelected Then
		ThisForm.DocumentCreated = True;
		ThisForm.ShowDocumentBeginning = False;
		Return;
	EndIf;
	ThisForm.CurrentParameterClicked = "";
	Object.ContractForm = ValueSelected;
	GetBlankParameters();
	ThisForm.DocumentCreated = False;
	GenerateAndShowContract();
	
EndProcedure

&AtClient
Procedure EditableParametersOnActivateCell(Item)
	
	If ValueIsFilled(Object.ContractForm) Then
		If Item.CurrentData <> Undefined Then
			If Not ThisForm.ShowDocumentBeginning Then
				SelectParameter(Item.CurrentData.ID);
			EndIf;
			ThisForm.ShowDocumentBeginning = False;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure EditableParametersParameterValueOnChange(Item)
	
	ParameterValue = Item.EditText;
	SetAndWriteParameterValue(ParameterValue, True);
	
EndProcedure

&AtClient
Procedure FixedContractAmountOnChange(Item)
	
	If Not FixedContractAmount Then
		Object.Amount = 0;
	EndIf;
	
	FormManagement();
	
EndProcedure

&AtClient
Procedure IsServiceContractOnChange(Item)
	
	If Not ValueIsFilled(Object.ServiceContractPeriodicity) Then
		Object.ServiceContractPeriodicity = PredefinedValue("Enum.BillingServiceContractPeriodicity.Month");
	EndIf;
	If Object.IsServiceContract And Object.ServiceContractDaysBeforeInvoicing = 0 Then
		DetermineInvoicingDate()
	EndIf;
	
	BillingConfigureItemsVisibility();
	FillServiceContractStartDate();
	FormManagement();
	
EndProcedure

&AtClient
Procedure ServiceContractStartDateOnChange(Item)
	
	CheckContractEndDateCorrectness();
	
	FormManagement();
	DetermineInvoicingDate();
	
EndProcedure

&AtClient
Procedure ServiceContractEndDateOnChange(Item)
	
	CheckContractEndDateCorrectness();
	
EndProcedure

&AtClient
Procedure CheckContractEndDateCorrectness()
	
	If Not ValueIsFilled(Object.ServiceContractEndDate) Then
		Return;
	EndIf;
	
	If Object.ServiceContractEndDate < Object.ServiceContractStartDate Then
		
		Object.ServiceContractEndDate = ServiceContractEndDate;
		
		Message = New UserMessage;
		Message.DataKey = Object.Ref;
		Message.Field = "Object.ServiceContractEndDate";
		Message.Text = NStr("en='The service contract expiration date cannot be earlier than the start date.';ru='Дата окончания действия договора обслуживания не может быть раньше даты начала.';vi='Ngày kết thúc hiệu lực hợp đồng dịch vụ không được sớm hơn ngày bắt đầu.'");
		Message.Message();
		Return;
		
	EndIf;
	
	ServiceContractEndDate = Object.ServiceContractEndDate;
	
EndProcedure

&AtClient
Procedure ServiceContractPeriodicityOnChange(Item)
	
	FormManagement();
	DetermineInvoicingDate();
	
EndProcedure

&AtClient
Procedure ServiceContractTariffPlanOnChange(Item)
	
	SetTitleBilling(ThisObject);
	
EndProcedure

&AtClient
Procedure InvoicingByMonthDayTuning(Item, Direction, StandardProcessing)
	
	StandardProcessing = Direction > 0 And Object.ServiceContractDaysBeforeInvoicing < 31
		Or Direction < 0 And Object.ServiceContractDaysBeforeInvoicing > 1;
	
EndProcedure

&AtClient
Procedure InvoicingByQuarterDayTuning(Item, Direction, StandardProcessing)
	
	StandardProcessing = Direction > 0 And Object.ServiceContractDaysBeforeInvoicing < 31
		Or Direction < 0 And Object.ServiceContractDaysBeforeInvoicing > 1;
	
EndProcedure

&AtClient
Procedure InvoicingByHalfYearDayTuning(Item, Direction, StandardProcessing)
	
	StandardProcessing = Direction > 0 And Object.ServiceContractDaysBeforeInvoicing < 31
		Or Direction < 0 And Object.ServiceContractDaysBeforeInvoicing > 1;
	
EndProcedure

&AtClient
Procedure InvoicingByYearDayTuning(Item, Direction, StandardProcessing)
	
	StandardProcessing = Direction > 0 And Object.ServiceContractDaysBeforeInvoicing < 31
		Or Direction < 0 And Object.ServiceContractDaysBeforeInvoicing > 1;
	
EndProcedure

&AtClient
Procedure InvoicingByMonthDayOnChange(Item)
	
	If Object.ServiceContractDaysBeforeInvoicing < 1 Then
		Object.ServiceContractDaysBeforeInvoicing = 1;
	ElsIf Object.ServiceContractDaysBeforeInvoicing > 31 Then
		Object.ServiceContractDaysBeforeInvoicing = 31;
	EndIf;
	
EndProcedure

&AtClient
Procedure InvoicingByQuarterDayOnChange(Item)
	
	If Object.ServiceContractDaysBeforeInvoicing < 1 Then
		Object.ServiceContractDaysBeforeInvoicing = 1;
	ElsIf Object.ServiceContractDaysBeforeInvoicing > 31 Then
		Object.ServiceContractDaysBeforeInvoicing = 31;
	EndIf;
	
EndProcedure

&AtClient
Procedure InvoicingByHalfYearDayOnChange(Item)
	
	If Object.ServiceContractDaysBeforeInvoicing < 1 Then
		Object.ServiceContractDaysBeforeInvoicing = 1;
	ElsIf Object.ServiceContractDaysBeforeInvoicing > 31 Then
		Object.ServiceContractDaysBeforeInvoicing = 31;
	EndIf;
	
EndProcedure

&AtClient
Procedure InvoicingByYearDayOnChange(Item)
	
	If Object.ServiceContractDaysBeforeInvoicing < 1 Then
		Object.ServiceContractDaysBeforeInvoicing = 1;
	ElsIf Object.ServiceContractDaysBeforeInvoicing > 31 Then
		Object.ServiceContractDaysBeforeInvoicing = 31;
	EndIf;
	
EndProcedure

&AtClient
Procedure BulkEmailRecipientsOnChange(Item)
	
	MailingRecipientsRefill = True;
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure CreateBusinessActivity(Command)
	CreateBusinessActivityQuestion();
EndProcedure

&AtClient
Procedure SetInterval(Command)
	
	Dialog = New StandardPeriodEditDialog();
	Dialog.Period.StartDate	= Object.ValidityStartDate;
	Dialog.Period.EndDate	= Object.ValidityEndDate;
	
	NotifyDescription = New NotifyDescription("SetIntervalCompleted", ThisObject);
	Dialog.Show(NotifyDescription);
	
EndProcedure

&AtClient
Procedure SetIntervalCompleted(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		Object.ValidityStartDate	= Result.StartDate;
		Object.ValidityEndDate		= Result.EndDate;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AddAdditionalAttribute(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("CurrentSetOfProperties", PredefinedValue("Catalog.AdditionalAttributesAndInformationSets.Catalog_CounterpartyContracts"));
	FormParameters.Insert("ThisIsAdditionalInformation", False);
	
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInformation.ObjectForm", FormParameters,,,,,,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

&AtClient
Procedure FormManagement()
	
	If Object.SettlementsCurrency = NationalCurrency Then
		Items.SettlementsInStandardUnits.Visible = False;
	Else
		Items.SettlementsInStandardUnits.Visible = True;
	EndIf;

	
	Items.Amount.Enabled			= FixedContractAmount;
	Items.Amount.AutoMarkIncomplete	= FixedContractAmount;
	
	// Billing
	Items.InvoicingByWeekDay.Visible     = False;
	Items.InvoicingByMonthDay.Visible     = False;
	Items.InvoicingByQuarterDay.Visible   = False;
	Items.InvoicingByQuarterMonth.Visible  = False;
	Items.InvoicingByHalfYearDay.Visible  = False;
	Items.InvoicingByHalfYearMonth.Visible = False;
	Items.InvoicingByYearDay.Visible       = False;
	Items.InvoicingByYearMonth.Visible      = False;
	
	If ValueIsFilled(Object.ServiceContractPeriodicity) Then
		If Object.ServiceContractPeriodicity = PredefinedValue("Enum.BillingServiceContractPeriodicity.Week") Then
			Items.InvoicingByWeekDay.Visible     = True;
		ElsIf Object.ServiceContractPeriodicity = PredefinedValue("Enum.BillingServiceContractPeriodicity.Month") Then
			Items.InvoicingByMonthDay.Visible     = True;
		ElsIf Object.ServiceContractPeriodicity = PredefinedValue("Enum.BillingServiceContractPeriodicity.Quarter") Then
			Items.InvoicingByQuarterDay.Visible   = True;
			Items.InvoicingByQuarterMonth.Visible  = True;
		ElsIf Object.ServiceContractPeriodicity = PredefinedValue("Enum.BillingServiceContractPeriodicity.HalfYear") Then
			Items.InvoicingByHalfYearDay.Visible  = True;
			Items.InvoicingByHalfYearMonth.Visible = True;
		ElsIf Object.ServiceContractPeriodicity = PredefinedValue("Enum.BillingServiceContractPeriodicity.Year") Then
			Items.InvoicingByYearDay.Visible       = True;
			Items.InvoicingByYearMonth.Visible      = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCounterpartyPriceKind()
	
	SetPrivilegedMode(True);
	
	Query = New Query("SELECT ALLOWED * FROM Catalog.CounterpartyPriceKind AS CounterpartyPrices WHERE CounterpartyPrices.Owner = &Owner AND NOT CounterpartyPrices.DeletionMark");
	Query.SetParameter("Owner", Object.Owner);
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then 
		
		Selection = QueryResult.Select();
		Selection.Next();
		Object.CounterpartyPriceKind = Selection.Ref;
		
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

&AtServer
Procedure FillPriceKind(IsNew = False)
	
	If IsNew Then
		
		PriceKindSales = SmallBusinessReUse.GetValueByDefaultUser(UsersClientServer.AuthorizedUser(), "MainPriceKindSales");
		
		If ValueIsFilled(PriceKindSales) Then
			
			Object.PriceKind = PriceKindSales;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function GenerateDescription(ContractNo, ContractDate, SettlementsCurrency)
	
	TextName = NStr("en='# %ContractNo% from %ContractDate% (%SettlementsCurrency%)';ru='№ %ContractNo% от %ContractDate% (%SettlementsCurrency%)';vi='Số %ContractNo% ngày %ContractDate% (%SettlementsCurrency%)'");
	TextName = StrReplace(TextName, "%ContractNo%", TrimAll(ContractNo));
	TextName = StrReplace(TextName, "%ContractDate%", ?(ValueIsFilled(ContractDate), TrimAll(String(Format(ContractDate, "DF=dd.MM.yyyy"))), ""));
	TextName = StrReplace(TextName, "%SettlementsCurrency%", TrimAll(String(SettlementsCurrency)));
	
	Return TextName;
	
EndFunction

&AtServer
Procedure SetContractKindsChoiceList()
	
	If Constants.FunctionalOptionTransferGoodsOnCommission.Get() Then
		Items.ContractKind.ChoiceList.Add(Enums.ContractKinds.WithAgent);
	EndIf;
	
	If Constants.FunctionalOptionReceiveGoodsOnCommission.Get() Then
		Items.ContractKind.ChoiceList.Add(Enums.ContractKinds.FromPrincipal);
	EndIf;	
	
EndProcedure

&AtServer
Procedure SetFormConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Print the contract. If the parameter is blank - display its title in the tooltip.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.EditableParametersValue.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue		= New DataCompositionField("EditableParameters.ValueIsFilled");
	ItemFilter.ComparisonType	= DataCompositionComparisonType.Equal;
	ItemFilter.RightValue		= False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableCellTextColor);
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("EditableParameters.Presentation"));
	
EndProcedure

#EndRegion
	
#Region PrintContract
	
&AtServer
Procedure GenerateAndShowContract()
	
	If Not ThisForm.DocumentCreated Then
		
		ThisForm.EditableParameters.Clear();
		FilterParameters = New Structure("FormRefs", Object.ContractForm);
		ArrayInfobaseParameters = Object.InfobaseParameters.FindRows(FilterParameters);
		For Each Parameter IN ArrayInfobaseParameters Do
			NewRow = ThisForm.EditableParameters.Add();
			NewRow.Presentation = Parameter.Presentation;
			NewRow.Value = Parameter.Value;
			NewRow.ID = Parameter.ID;
			NewRow.Parameter = Parameter.Parameter;
			NewRow.LineNumber = Parameter.LineNumber;
		EndDo;
		
		ArrayEditedParameters = Object.EditableParameters.FindRows(FilterParameters);
		For Each Parameter IN ArrayEditedParameters Do
			NewRow = ThisForm.EditableParameters.Add();
			NewRow.Presentation = Parameter.Presentation;
			NewRow.Value = Parameter.Value;
			NewRow.ID = Parameter.ID;
			NewRow.LineNumber = Parameter.LineNumber;
		EndDo;
		
		GeneratedDocument = SmallBusinessCreationOfPrintedFormsOfContract.GetGeneratedContractHTML(Object, ThisForm.OpeningDocument, ThisForm.EditableParameters);
		If ThisForm.ContractHTMLDocument = GeneratedDocument Then
			ThisForm.DocumentCreated = True;
		EndIf;
		ThisForm.ContractHTMLDocument = GeneratedDocument;
		
		FilterParameters = New Structure("Parameter", PredefinedValue("Enum.ContractsWithCounterpartiesTemplatesParameters.Facsimile"));
		Rows = ThisForm.EditableParameters.FindRows(FilterParameters);
		For Each String IN Rows Do
			ID = String.GetID();
			ThisForm.EditableParameters.Delete(EditableParameters.FindByID(ID));
		EndDo;
		
		FilterParameters.Parameter = PredefinedValue("Enum.ContractsWithCounterpartiesTemplatesParameters.Logo");
		Rows = ThisForm.EditableParameters.FindRows(FilterParameters);
		For Each String IN Rows Do
			ID = String.GetID();
			ThisForm.EditableParameters.Delete(EditableParameters.FindByID(ID))
		EndDo;
		
		For Each String IN ThisForm.EditableParameters Do
			If ValueIsFilled(String.Value) Then
				String.ValueIsFilled = True;
			Else
				String.ValueIsFilled = False;
			EndIf;
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure GetBlankParameters()
	
	FilterParameters = New Structure("FormRefs", Object.ContractForm);
	ObjectEditedParameters		= Object.EditableParameters.FindRows(FilterParameters);
	ObjectInfobaseParameters	= Object.InfobaseParameters.FindRows(FilterParameters);
	
	For Each Parameter IN ObjectEditedParameters Do
		FilterParameters = New Structure("ID", Parameter.ID);
		If Object.ContractForm.EditableParameters.FindRows(FilterParameters).Count() <> 0 Then
			Continue;
		EndIf;
		FilterParameters.Insert("FormRefs", Object.ContractForm);
		Rows = Object.EditableParameters.FindRows(FilterParameters);
		If Rows.Count() > 0 Then 
			Object.EditableParameters.Delete(Rows[0]);
		EndIf;
	EndDo;
	
	For Each Parameter IN Object.ContractForm.EditableParameters Do
		FilterParameters = New Structure("FormRefs, ID", Object.ContractForm, Parameter.ID);
		If Object.EditableParameters.FindRows(FilterParameters).Count() > 0 Then 
			Continue;
		EndIf;
		NewRow = Object.EditableParameters.Add();
		NewRow.FormRefs		= Object.ContractForm;
		NewRow.Presentation	= Parameter.Presentation;
		NewRow.ID			= Parameter.ID;
	EndDo;
	
	For Each Parameter IN ObjectInfobaseParameters Do
		FilterParameters = New Structure("ID", Parameter.ID);
		Rows = Object.ContractForm.InfobaseParameters.FindRows(FilterParameters);
		If Rows.Count() <> 0 Then
			Parameter.Presentation = Rows[0].Presentation;
			Continue;
		EndIf;
		FilterParameters.Insert("FormRefs", Object.ContractForm);
		Rows = Object.InfobaseParameters.FindRows(FilterParameters);
		If Rows.Count() > 0 Then 
			Object.InfobaseParameters.Delete(Rows[0]);
		EndIf;
	EndDo;
	
	For Each Parameter IN Object.ContractForm.InfobaseParameters Do 
		FilterParameters = New Structure("FormRefs, ID", Object.ContractForm, Parameter.ID);
		If Object.InfobaseParameters.FindRows(FilterParameters).Count() > 0 Then
			Continue;
		EndIf;
		NewRow = Object.InfobaseParameters.Add();
		NewRow.FormRefs		= Object.ContractForm;
		NewRow.Presentation	= Parameter.Presentation;
		NewRow.ID			= Parameter.ID;
		NewRow.Parameter	= Parameter.Parameter;
	EndDo;
	
EndProcedure

&AtClient
Procedure SelectParameter(Parameter)
	
	If Not ThisForm.DocumentCreated Then
		Return;
	EndIf;
	
	Var_Document = Items.ContractHTMLDocument.Document;
	
	If ValueIsFilled(ThisForm.CurrentParameterClicked) Then
		lastParameter = Var_Document.getElementById(ThisForm.CurrentParameterClicked);
		If lastParameter.className = "Filled" Then 
			lastParameter.style.backgroundColor = "#FFFFFF";
		ElsIf lastParameter.className = "Empty" Then 
			lastParameter.style.backgroundColor = "#DCDCDC";
		EndIf;
	EndIf;
	
	chosenParameter = Var_Document.getElementById(Parameter);
	If chosenParameter <> Undefined Then
		chosenParameter.style.backgroundColor = "#CCFFCC";
		chosenParameter.scrollIntoView();
		
		ThisForm.CurrentParameterClicked = Parameter;
	EndIf;
	
EndProcedure

&AtClient
Procedure ContractHTMLDocumentDocumentCreated(Item)
	
	Var_Document = Items.ContractHTMLDocument.Document;
	EditedParametersOnPage = Var_Document.getElementsByName("parameter");
	
	Iterator = 0;
	For Each Parameter in EditedParametersOnPage Do 
		FilterParameters = New Structure("ID", Parameter.id);
		String = EditableParameters.FindRows(FilterParameters);
		If String.Count() > 0 Then 
			RowIndex = EditableParameters.IndexOf(String[0]);
			Shift = Iterator - RowIndex;
			If Shift <> 0 Then 
				EditableParameters.Move(RowIndex, Shift);
			EndIf;
		EndIf;
		Iterator = Iterator + 1;
	EndDo;
	
	ThisForm.DocumentCreated = True;
	
EndProcedure

&AtServer
Function ThisIsInfobaseParameter(Parameter)
	
	Return ?(TypeOf(Parameter) = Type("EnumRef.ContractsWithCounterpartiesTemplatesParameters"), True, False);
	
EndFunction

&AtServer
Function ThisIsAdditionalAttribute(Parameter)
	
	Return ?(TypeOf(Parameter) = Type("ChartOfCharacteristicTypesRef.AdditionalAttributesAndInformation"), True, False);
	
EndFunction

&AtServer
Function GetParameterValue(Parameter, Presentation, ID)
	
	If ThisIsInfobaseParameter(Parameter) Then
		Return SmallBusinessCreationOfPrintedFormsOfContract.GetParameterValue(Object, , Parameter, Presentation);
	ElsIf ThisIsAdditionalAttribute(Parameter) Then
		Return SmallBusinessCreationOfPrintedFormsOfContract.GetAdditionalAttributeValue(Object, OpeningDocument, Parameter);
	Else
		Return SmallBusinessCreationOfPrintedFormsOfContract.GetFilledFieldValueOnGeneratingPrintedForm(Object, ID);
	EndIf;
	
EndFunction

&AtClient
Procedure EditableParametersOnStartEdit(Item, NewRow, Copy)
	
	If Not ValueIsFilled(ThisForm.CurrentParameterClicked) Then
		SelectParameter(Item.CurrentData.ID);
	EndIf;
	
	Rows = EditableParameters.FindRows(New Structure("ID", ThisForm.CurrentParameterClicked));
	If Rows.Count() > 0 Then
		Rows[0].ValueIsFilled = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure EditableParametersOnEditEnd(Item, NewRow, CancelEdit)
	
	Rows = EditableParameters.FindRows(New Structure("ID", ThisForm.CurrentParameterClicked));
	If Rows.Count() > 0 Then
		If ValueIsFilled(Rows[0].Value) Then
			Rows[0].ValueIsFilled = True;
		Else
			Rows[0].ValueIsFilled = False;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure EditableParametersParameterValueStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	Parameter = Items.EditableParameters.CurrentData;
	ParameterValue = GetParameterValue(Parameter.Parameter, Parameter.Presentation, Parameter.ID);
	Items.EditableParameters.CurrentData.Value = ParameterValue;
	
	SetAndWriteParameterValue(ParameterValue, False);
	
EndProcedure

&AtClient
Procedure SetAndWriteParameterValue(ParameterValue, WriteValue)
	
	Var_Document = Items.ContractHTMLDocument.Document;
	chosenParameter = Var_Document.getElementById(ThisForm.CurrentParameterClicked);
	
	If ValueIsFilled(ParameterValue) Then
		chosenParameter.innerText = ParameterValue;
		chosenParameter.className = "Filled";
		Items.EditableParameters.CurrentData.ValueIsFilled = True;
	Else
		chosenParameter.innerText = "__________";
		chosenParameter.className = "Empty";
		Items.EditableParameters.CurrentData.ValueIsFilled = False;
	EndIf;
	
	WorkingTable = Undefined;
	Parameter = Items.EditableParameters.CurrentData;
	If ThisIsInfobaseParameter(Parameter.Parameter) OR ThisIsAdditionalAttribute(Parameter.Parameter) Then
		WorkingTable = Object.InfobaseParameters;
		If WriteValue Then
			ParameterValueInInfobase = GetParameterValue(Parameter.Parameter, Parameter.Presentation, Parameter.ID);
			If ParameterValue = ParameterValueInInfobase Then
				WriteValue = False;
			EndIf;
		EndIf;
	Else
		WorkingTable = Object.EditableParameters;
	EndIf;
	
	FilterParameters = New Structure;
	FilterParameters.Insert("ID", ThisForm.CurrentParameterClicked);
	Rows = ThisForm.EditableParameters.FindRows(FilterParameters);
	If Rows.Count() > 0 Then 
		ParameterIndex = Rows[0].LineNumber - 1;
	Else
		ParameterIndex = Undefined;
	EndIf;
	
	If ParameterIndex = Undefined Then
		Return;
	EndIf;
	
	If WriteValue Then
		WorkingTable[ParameterIndex].Value = ParameterValue;
	Else
		WorkingTable[ParameterIndex].Value = "";
	EndIf;
	
	ThisForm.Modified = True;
	
EndProcedure

#EndRegion

#Region Billing

&AtClientAtServerNoContext
Procedure SetTitleBilling(Form)
	
	Object = Form.Object;
	DynamicParameters = New Array;
	
	If Object.IsServiceContract And ValueIsFilled(Object.ServiceContractTariffPlan) Then
		DynamicParameters.Add(NStr("en='Tariff plan ';ru='Тарифный план ';vi='Dịch vụ định kỳ'") + String(Object.ServiceContractTariffPlan));
	EndIf;
	
	SetCollapsedDisplayTitle(Form, "GroupBilling", DynamicParameters);
	
EndProcedure

// Процедура устанавливает заголовок свернутого отображения для группы, по шаблону:
// <заголовок группы (как задан в конфигураторе)> : <динамический параметр 1>, <динамический параметр 2>
//
// Parameters:
//  Form					 - Form	 - текущая форма
//  GroupName			 - String	 - имя группы формы, для которой устанавливается заголовок
//  DynamicParameters	 - Array	 - массив частей заголовка.
//
&AtClientAtServerNoContext
Procedure SetCollapsedDisplayTitle(Form, GroupName, DynamicParameters)
	
	TitleText = Form.Items[GroupName].Title;
	If DynamicParameters.Count() > 0 Then
		TitleText = TitleText + ": ";
		For Each Parameter In DynamicParameters Do
			TitleText = TitleText + Parameter + ", ";
		EndDo;
		StringFunctionsClientServer.DeleteLatestCharInRow(TitleText, 2);
	EndIf;
	
	Form.Items[GroupName].CollapsedRepresentationTitle = TitleText;
	
EndProcedure

&AtClient
Procedure CreateBusinessActivityQuestion()
	
	If Modified Then
		QuestionText = NStr("en='It is required to write an object before creation of business activity. Write?';ru='Перед созданием направления действия необходимо записать объект. Записать?';vi='Trước khi tạo lĩnh vực hoạt động, cần ghi lại đối tượng. Ghi lại?'");
		ShowQueryBox(New NotifyDescription("CreateBusinessActivityCompletion", ThisObject), QuestionText, QuestionDialogMode.YesNo);
	Else
		CreateBusinessActivityForServiceContract();
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateBusinessActivityCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		Write();
	Else
		Return;
	EndIf;
	
	CreateBusinessActivityForServiceContract();
	
EndProcedure

&AtServer
Procedure CreateBusinessActivityForServiceContract()
	
	Object.ServiceContractBusinessActivity = 
		Catalogs.CounterpartyContracts.CreateBusinessActivityForServiceContract(Object.Owner, Object.Ref);
	Write();
	
	BillingConfigureItemsVisibility();
	
EndProcedure

&AtServer
Procedure BillingConfigureItemsVisibility()
	
	If Object.IsServiceContract Then
		Items.GroupBillingSettings.Visible = True;
		Items.PriceKind.AutoMarkIncomplete = True;
	Else
		Items.GroupBillingSettings.Visible = False;
		Items.PriceKind.AutoMarkIncomplete = False;
		Return;
	EndIf;
	
	UseBusinessActivities = Constants.BillingKeepExpensesAccountingByServiceContracts.Get();
	
	If Not UseBusinessActivities Then
		Items.ServiceContractBusinessActivity.Visible = False;
		Items.GroupCreateBusinessActivity.Visible = False;
	Else
		If Not ValueIsFilled(Object.Ref)
			Or ValueIsFilled(Object.Ref) And Not Object.Ref.IsServiceContract Then
			// Это новый объект или существующий, который становится договором обслуживания.
			// Направление деятельности создается автоматически.
			Items.ServiceContractBusinessActivity.Visible = True;
			Items.GroupCreateBusinessActivity.Visible = False;
		Else
			// Это существующий договор обслуживания.
			// Направление деятельности создается вручную, если не было создано ранее.
			Items.ServiceContractBusinessActivity.Visible = ValueIsFilled(Object.ServiceContractBusinessActivity);
			Items.GroupCreateBusinessActivity.Visible = Not ValueIsFilled(Object.ServiceContractBusinessActivity);
		EndIf;
	EndIf;
	
EndProcedure


&AtServer
Procedure FillMailingRecipients()
	
	BulkEmailRecipients.Clear();
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	TRUE AS Check,
	|	CounterpartyContractsServiceContractMailingRecipients.Contact AS Contact,
	|	CounterpartyContractsServiceContractMailingRecipients.EmailAddress AS EmailAddress
	|INTO TTSelectedRecipients
	|FROM
	|	Catalog.CounterpartyContracts.ServiceContractMailingRecipients AS CounterpartyContractsServiceContractMailingRecipients
	|WHERE
	|	CounterpartyContractsServiceContractMailingRecipients.Ref = &Contract
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	FALSE AS Check,
	|	CounterpartiesContactInformation.Ref AS Contact,
	|	CounterpartiesContactInformation.Presentation AS EmailAddress
	|INTO TTAllRecipients
	|FROM
	|	Catalog.Counterparties.ContactInformation AS CounterpartiesContactInformation
	|WHERE
	|	CounterpartiesContactInformation.Ref = &Counterparty
	|	AND CounterpartiesContactInformation.Type = &CIType
	|
	|UNION
	|
	|SELECT 
	|	FALSE,
	|	ContactPersonsContactInformation.Ref,
	|	ContactPersonsContactInformation.Presentation
	|
	|FROM
	|	Catalog.ContactPersons.ContactInformation AS ContactPersonsContactInformation
	|WHERE
	|	ContactPersonsContactInformation.Ref.Owner = &Counterparty
	|	AND ContactPersonsContactInformation.Type = &CIType
	|	AND NOT ContactPersonsContactInformation.Ref.Invalid
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTSelectedRecipients.Check AS Check,
	|	TTSelectedRecipients.Contact AS Contact,
	|	TTSelectedRecipients.EmailAddress AS EmailAddress
	|FROM
	|	TTSelectedRecipients AS TTSelectedRecipients
	|
	|UNION
	|
	|SELECT
	|	TTAllRecipients.Check,
	|	TTAllRecipients.Contact,
	|	TTAllRecipients.EmailAddress
	|FROM
	|	TTAllRecipients AS TTAllRecipients
	|WHERE
	|	NOT TTAllRecipients.EmailAddress IN
	|				(SELECT
	|					TTSelectedRecipients.EmailAddress
	|				FROM
	|					TTSelectedRecipients AS TTSelectedRecipients)";
	
	Query.SetParameter("Counterparty", Object.Owner);
	Query.SetParameter("Contract", Object.Ref);
	Query.SetParameter("CIType", Enums.ContactInformationTypes.EmailAddress);
	
	SELECTION = Query.Execute().Select();
	HasAddressees = SELECTION.Count() <> 0;
	
	While SELECTION.Next() Do
		
		NewRow = BulkEmailRecipients.Add();
		FillPropertyValues(NewRow, SELECTION);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure FillServiceContractStartDate()
	
	If Object.IsServiceContract
		And Not ValueIsFilled(Object.ServiceContractStartDate)
		And ValueIsFilled(Object.ContractDate) Then
		
		Object.ServiceContractStartDate = Object.ContractDate;
		DetermineInvoicingDate();
	EndIf;
	
EndProcedure

&AtClient
Procedure DetermineInvoicingDate()
	
	If Object.ServiceContractPeriodicity = PredefinedValue("Enum.BillingServiceContractPeriodicity.Week") Then
		
		Object.ServiceContractDaysBeforeInvoicing = WeekDay(Object.ServiceContractStartDate);
		Object.ServiceContractMonthsBeforeInvoicing = 0;
		
	ElsIf Object.ServiceContractPeriodicity = PredefinedValue("Enum.BillingServiceContractPeriodicity.Month") Then
		
		Object.ServiceContractDaysBeforeInvoicing = (BegOfDay(Object.ServiceContractStartDate) - BegOfMonth(Object.ServiceContractStartDate)) / 86400 + 1;
		Object.ServiceContractMonthsBeforeInvoicing = 0;
		
	ElsIf Object.ServiceContractPeriodicity = PredefinedValue("Enum.BillingServiceContractPeriodicity.Quarter") Then
		
		Object.ServiceContractDaysBeforeInvoicing = (BegOfDay(Object.ServiceContractStartDate) - BegOfMonth(Object.ServiceContractStartDate)) / 86400 + 1;
		Object.ServiceContractMonthsBeforeInvoicing = Month(Object.ServiceContractStartDate) - Month(BegOfQuarter(Object.ServiceContractStartDate)) + 1;
		
	ElsIf Object.ServiceContractPeriodicity = PredefinedValue("Enum.BillingServiceContractPeriodicity.HalfYear") Then
		
		Object.ServiceContractDaysBeforeInvoicing = (BegOfDay(Object.ServiceContractStartDate) - BegOfMonth(Object.ServiceContractStartDate)) / 86400 + 1;
		Object.ServiceContractMonthsBeforeInvoicing = ?(Month(Object.ServiceContractStartDate) > 6, Month(Object.ServiceContractStartDate) - 6, Month(Object.ServiceContractStartDate));
		
	ElsIf Object.ServiceContractPeriodicity = PredefinedValue("Enum.BillingServiceContractPeriodicity.Year") Then
		
		Object.ServiceContractDaysBeforeInvoicing = (BegOfDay(Object.ServiceContractStartDate) - BegOfMonth(Object.ServiceContractStartDate)) / 86400 + 1;
		Object.ServiceContractMonthsBeforeInvoicing = Month(Object.ServiceContractStartDate);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region LibrariesHandlers

// StandardSubsystems.AdditionalReportsAndDataProcessors
&AtServer
Procedure AdditionalReportsAndProcessingsExecuteAllocatedCommandAtServer(ItemName, ExecutionResult)
	
	AdditionalReportsAndDataProcessors.ExecuteAllocatedCommandAtServer(ThisForm, ItemName, ExecutionResult);
	
EndProcedure
// End StandardSubsystems.AdditionalReportsAndDataProcessors

// StandardSubsystems.AdditionalReportsAndDataProcessors
&AtClient
Procedure Attachable_ExecuteAssignedCommand(Command)
	
	If Not AdditionalReportsAndDataProcessorsClient.ExecuteAllocatedCommandAtClient(ThisForm, Command.Name) Then
		ExecutionResult = Undefined;
		AdditionalReportsAndProcessingsExecuteAllocatedCommandAtServer(Command.Name, ExecutionResult);
		AdditionalReportsAndDataProcessorsClient.ShowCommandExecutionResult(ThisForm, ExecutionResult);
	EndIf;
	
EndProcedure
// End StandardSubsystems.AdditionalReportsAndDataProcessors

// StandardSubsystems.Printing
&AtClient
Procedure Attachable_ExecutePrintCommand(Command)
	PrintManagementClient.ExecuteConnectedPrintCommand(Command, ThisObject, Object);
EndProcedure
// End StandardSubsystems.Printing

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesRunCommand(ItemOrCommand, URL = Undefined, StandardProcessing = Undefined)
	PropertiesManagementClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure // Подключаемый_РедактироватьСоставСвойств()

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertiesManagement.UpdateAdditionalAttributesItems(ThisForm, FormAttributeToValue("Object"));
	
EndProcedure // ОбновитьЭлементыДополнительныхРеквизитов()

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertiesManagementClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_AdditionalAttributeOnChange(Item)
	PropertiesManagementClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure
// End StandardSubsystems.Properties

#EndRegion
