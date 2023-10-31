#Region GeneralPurposeProceduresAndFunctions

// Function places the Accruals tabular section into
// the temporary storage
//and returns the address
&AtServer
Function PlaceAccrualsToStorage()

	AddressInStorage = PutToTempStorage(Object.Accruals.Unload(), UUID);
	Return AddressInStorage;

EndFunction

// Procedure receives the Accruals tabular section from the temporary storage.
//
&AtServer
Procedure ReceiveAccrualsFromStorage(AccrualAddressInStorage)

	Object.Accruals.Load(GetFromTempStorage(AccrualAddressInStorage));

EndProcedure

#EndRegion

#Region ProceduresEventHandlersForms

// Procedure - handler of the WhenCreatingOnServer event.
//
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	OperationKindWhenChangingOnServer();
	
	// Set form attributes.
	DocumentDate = Object.Date;
	If Not ValueIsFilled(DocumentDate) Then
		DocumentDate = CurrentDate();
	EndIf;
	
	Company = SmallBusinessServer.GetCompany(Object.Company);
	TransactionKindAccrualsForCredits = Enums.LoanAccrualTypes.AccrualsForLoansBorrowed;
	
	// StandardSubsystems.Properties
	AdditionalParameters = PropertiesManagementOverridable.FillAdditionalParameters(Object, "AdditionalAttributesGroup");
	PropertiesManagement.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
EndProcedure

// Procedure - handler of the WhenOpening event.
//
&AtClient
Procedure OnOpen(Cancel)
	
	OperationType = Object.OperationType;
	
	// StandardSubsystems.Properties
	PropertiesManagementClient.AfterLoadAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
		
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)

	If TypeOf(SelectedValue) = Type("Structure") Then
		If SelectedValue.Property("AccrualAddressInStorage") Then
			ReceiveAccrualsFromStorage(SelectedValue.AccrualAddressInStorage);
			Modified = True;
			
			If Object.Accruals.Count() = 0 Then
				LineForOperationKind = ?(Object.OperationType = TransactionKindAccrualsForCredits, 
					NStr("en='credits';ru='кредитам';vi='cho vay'"), 
					NStr("en='loans';ru='займам';vi='khoản nợ'"));
					
				ShowMessageBox(Undefined, 
					StringFunctionsClientServer.SubstituteParametersInString(
						NStr("en='Interest accrual period is out of loan repayment schedule';ru='Для выбранного периода, начисление по %1 не нужно';vi='Đối với kỳ đã chọn, không cần tính lãi theo %1'"),
						LineForOperationKind));
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties
	If PropertiesManagementClient.ProcessAlerts(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertiesManagementClient.AfterLoadAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

// Procedure - handler of the WhenReadingOnServer event.
//
&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.Properties
	PropertiesManagement.OnReadAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.Properties
	
EndProcedure // WhenReadingOnServer()

// Procedure handler of the PopulationCheckProcessingOnServer event.
//
&AtServer
Procedure FillCheckProcessingAtServer(Cancel, AttributesToCheck)
	
	// StandardSubsystems.Properties
	PropertiesManagement.FillCheckProcessing(ThisForm, Cancel, AttributesToCheck);
	// End StandardSubsystems.Properties
	
EndProcedure

// Procedure handler of the BeforeWritingOnServer event.
//
&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertiesManagement.BeforeWriteAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.Properties
	
EndProcedure // BeforeWritingOnServer()

#EndRegion

#Region CommandActionProcedures

&AtClient
Procedure AddAdditionalAttribute(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("CurrentSetOfProperties", PredefinedValue("Catalog.AdditionalAttributesAndInformationSets.Document_LoanInterestCommissionAccruals"));
	FormParameters.Insert("ThisIsAdditionalInformation", False);
	
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInformation.ObjectForm", FormParameters,,,,,,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Procedure - handler of the PopulateAccruals command.
//
&AtClient
Procedure PopulateAccruals(Command)
	
	If Not ValueIsFilled(Object.OperationType) Then
		ShowMessageBox(Undefined, NStr("en='Operation is not specified.';ru='Не указана операция!';vi='Chưa chỉ ra giao dịch!'"));
		Return;
	EndIf;
	
	If Not ValueIsFilled(Object.Company) Then
		ShowMessageBox(Undefined, NStr("en='Company is not specified.';ru='Не указана организация!';vi='Chưa chỉ ra doanh nghiệp!'"));
		Return;
	EndIf;
	
	If Not ValueIsFilled(Object.StartDate) Then
		ShowMessageBox(Undefined, NStr("en='Accrual period start is not specified.';ru='Не указано начало периода начислений!';vi='Chưa chỉ ra bắt đầu kỳ tính toán!'"));
		Return;
	EndIf;
	
	If Not ValueIsFilled(Object.EndDate) Then
		ShowMessageBox(Undefined, NStr("en='Accrual period end is not specified.';ru='Не указан конец периода начислений!';vi='Chưa chỉ ra cuối kỳ tính toán!'"));
		Return;
	EndIf;
	
	If Not Object.EndDate > Object.StartDate Then
		ShowMessageBox(Undefined, NStr("en='Incorrect period is specified. Start date > End date.';ru='Указан неверный период. Дата начала > Даты окончания!';vi='Đã chỉ ra sai kỳ. Ngày bắt đầu  > Ngày kết thúc.'"));
		Return;
	EndIf;
	
	AccrualAddressInStorage = PlaceAccrualsToStorage();
	FilterParameters = New Structure("AccrualAddressInStorage,
		|Company,
		|Recorder,
		|OperationKind,
		|StartDate,
		|EndDate",
		AccrualAddressInStorage,
		Object.Company,
		Object.Ref,
		Object.OperationType,
		Object.StartDate,
		Object.EndDate);
	
	OpenForm("Document.LoanInterestCommissionAccruals.Form.FillingForm", 
		FilterParameters,
		ThisForm);
	
EndProcedure

#EndRegion

#Region ProceduresHandlersOfEventsHeaderAttributes

// Procedure - handler of the OnChange event of the OperationKind input field.
//
&AtClient
Procedure OperationKindOnChange(Item)
	
	If OperationType <> Object.OperationType Then
		OperationType = Object.OperationType;
		
		Object.Accruals.Clear();
		
		OperationKindWhenChangingOnServer();
	EndIf;
	
EndProcedure

// Procedure - handler of the OnChange event of the Company input field.
//
&AtClient
Procedure CompanyOnChange(Item)	
	Object.Number = "";	
EndProcedure

// Procedure - handler of the OnChange event of the OperationKind input field. Server part.
//
&AtServer
Procedure OperationKindWhenChangingOnServer()
	
	OperationType = Object.OperationType;
	
	If Object.OperationType = PredefinedValue("Enum.LoanAccrualTypes.AccrualsForLoansBorrowed") Then
		Items.Lender.Visible = True;
		Items.AccrualsEmployee.Visible = False;
	Else
		Items.Lender.Visible = False;
		Items.AccrualsEmployee.Visible = True;
	EndIf;
	
	NewArray = New Array();
	
	If Object.OperationType = Enums.LoanAccrualTypes.AccrualsForLoansBorrowed Then
		NewParameter = New ChoiceParameter("Filter.LoanKind", Enums.LoanContractTypes.Borrowed);
	Else
		NewParameter = New ChoiceParameter("Filter.LoanKind", Enums.LoanContractTypes.EmployeeLoanAgreement);
	EndIf;
	
	NewArray.Add(NewParameter);
	NewParameters = New FixedArray(NewArray);
	Items.AccrualsLoanContract.ChoiceParameters = NewParameters;
	
EndProcedure

// Procedure - handler of the OnChange event of the StartDate input field.
//
&AtClient
Procedure StartDateOnChange(Item)
	
	Object.EndDate = EndOfMonth(Object.StartDate);
	
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonUseClient.ShowCommentEditingForm(Item.EditText, ThisObject, "Object.Comment");
		
EndProcedure

#EndRegion

#Region ProceduresHandlersOfEventsTabularSectionAttributes

// Procedure - handler of the OnChange event of the LoanContract attribute for the Accruals tabular section.
//
&AtClient
Procedure AccrualsLoanContractOnChange(Item)
	
	CurrentData = Items.Accruals.CurrentData;
	
	If CurrentData <> Undefined Then
		
		AttributeStructure = AccrualsLoanContractWhenChangingOnServer(CurrentData.LoanContract, Object.OperationType);
		CurrentData.SettlementsCurrency = AttributeStructure.SettlementsCurrency;
		
		If AttributeStructure.Property("Lender") AND CurrentData.Lender.IsEmpty() Then
			CurrentData.Lender = AttributeStructure.Lender;
		EndIf;
		
		If AttributeStructure.Property("Employee") AND CurrentData.Employee.IsEmpty() Then
			CurrentData.Employee = AttributeStructure.Employee;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function AccrualsLoanContractWhenChangingOnServer(LoanContract, OperationType)
	
	AttributeStructure = New Structure;
	AttributeStructure.Insert("SettlementsCurrency", LoanContract.SettlementsCurrency);
	
	If OperationType = Enums.LoanAccrualTypes.AccrualsForLoansBorrowed 
		AND LoanContract.LoanKind = Enums.LoanContractTypes.Borrowed Then
		
		AttributeStructure.Insert("Lender", LoanContract.Counterparty);
		
	ElsIf OperationType = Enums.LoanAccrualTypes.AccrualsForEmployeeLoans
		AND	LoanContract.LoanKind = Enums.LoanContractTypes.EmployeeLoanAgreement Then
		
		AttributeStructure.Insert("Employee", LoanContract.Employee);
		
	EndIf;
	
	Return AttributeStructure;
	
EndFunction

#EndRegion

#Region LibraryHandlers

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesRunCommand(ItemOrCommand, URL = Undefined, StandardProcessing = Undefined)
	PropertiesManagementClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()

	PropertiesManagement.UpdateAdditionalAttributesItems(ThisForm, FormAttributeToValue("Object"));

EndProcedure

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
