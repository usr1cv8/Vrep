#Region CommonUseProceduresAndFunctions

#EndRegion

#Region ServiceProceduresAndFunctions

// Fills document Receipt CR by cash register.
//
// Parameters
//  FillingData - Structure with the filter values
//
&AtServer
Procedure FillDocumentByCachRegister(CashCR, ParametersStructure = Undefined)
	
	StatusCashCRSession = Documents.RetailReport.GetCashCRSessionStatus(CashCR);
	
	If POSTerminal.IsEmpty() OR CashCR <> POSTerminal.PettyCash Then
		If ParametersStructure = Undefined Then
			Object.POSTerminal = Catalogs.POSTerminals.GetPOSTerminalByDefault(Object.CashCR);
			POSTerminal = Object.POSTerminal;
		Else
			Object.POSTerminal = ParametersStructure.POSTerminal;
			POSTerminal = Object.POSTerminal;
		EndIf;
	EndIf;
	
EndProcedure // FillDocumentByFilter()

#EndRegion

#Region ProceduresFormEventsHandlers

// Procedure - OnCreateAtServer event handler.
//
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ParametersStructure = Parameters.ParametersStructure;
	Object.CashCR = ParametersStructure.CashCR;
	If Object.CashCR <> Undefined Then
		FillDocumentByCachRegister(Object.CashCR, ParametersStructure);
	EndIf;
	
	Workplace = EquipmentManagerServerCall.GetClientWorkplace();
	If Not ValueIsFilled(Workplace) Then
		Message = New UserMessage;
		Message.Text = NStr("en='Failed to identify workplace to work with peripherals!';vi='Không xác định được nơi làm việc để làm việc với các thiết bị ngoại vi!'");
		Message.Message();
	EndIf;
		
	CWPSetting = CashierWorkplaceServerCall.GetCWPSetup(Workplace);
	If Object.CashCR.IsEmpty() Then
		If Not ValueIsFilled(CWPSetting) Then
			Message = New UserMessage;
			Message.Text = NStr("en='Failed to receive the CWP settings for current workplace!';vi='Không nhận được cài đặt CWP cho nơi làm việc hiện tại!'");
			Message.Message();
		Else
			DontShowOnOpenCashdeskChoiceForm = CWPSetting.DontShowOnOpenCashdeskChoiceForm;
		EndIf;
	Else
		If ParametersStructure.POSTerminalQuantity < 2 Then
			DontShowOnOpenCashdeskChoiceForm = True;
		Else
			DontShowOnOpenCashdeskChoiceForm = CWPSetting.DontShowOnOpenCashdeskChoiceForm;
		EndIf;
	EndIf;
	
	CashCR = Object.CashCR;
	POSTerminal = Object.POSTerminal;
	
EndProcedure

// Procedure - event handler OnOpen.
//
&AtClient
Procedure OnOpen(Cancel)
	
	If DontShowOnOpenCashdeskChoiceForm AND Not Object.CashCR.IsEmpty() Then
		OpenWorkplaceOfCashier(Commands.OpenWorkplaceOfCashier);
	EndIf;
	
EndProcedure

// Procedure - event handler OnLoadDataFromSettingsAtServer.
//
&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	CurCashCR = Settings.Get("CashCR");
	If ValueIsFilled(CurCashCR) Then
		CashCR = CurCashCR;
		Object.CashCR = CashCR;
	EndIf;
	
	CurPOSTerminal = Settings.Get("POSTerminal");
	If ValueIsFilled(CurPOSTerminal) Then
		POSTerminal = CurPOSTerminal;
		Object.POSTerminal = POSTerminal;
	EndIf;
	
	FillDocumentByCachRegister(Object.CashCR);
	
EndProcedure

// Procedure - event handler OnSaveDataInSettingsAtServer.
//
&AtServer
Procedure OnSaveDataInSettingsAtServer(Settings)
	
	If Not CloseFormAfterOpeningCWP Then
		Settings.Clear();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

// Procedure - command handler OpenCashierWorkplace form.
//
&AtClient
Procedure OpenWorkplaceOfCashier(Command)
	
	If Object.CashCR.IsEmpty() Then
		Message = New UserMessage;
		Message.Text = NStr("en='Select cashier workplace';vi='Chọn quầy thu ngân'");
		Message.Field = "CashCR";
		Message.Message();
		Return;
	EndIf;
	
	CloseFormAfterOpeningCWP = True;
	
	CWPParameters = New Structure;
	CWPParameters.Insert("Company", Object.Company);
	CWPParameters.Insert("CashCR", Object.CashCR);
	CWPParameters.Insert("StructuralUnit", Object.StructuralUnit);
	CWPParameters.Insert("POSTerminal", Object.POSTerminal);
	
	CashierWorkplaceServerCall.UpdateSettingsCWP(CWPSetting, DontShowOnOpenCashdeskChoiceForm);
	OpenForm("Document.ReceiptCR.Form.DocumentForm_CWP", CWPParameters);
	Close();
	
EndProcedure

#EndRegion

#Region ProceduresElementFormEventsHandlers

// Procedure - event handler OnChange item CashCR form.
//
&AtClient
Procedure CashCROnChange(Item)
	
	Object.CashCR = CashCR;
	
	FillDocumentByCachRegister(Object.CashCR);
	
EndProcedure

// Procedure - event handler OnChange item POSTerminal form.
//
&AtClient
Procedure POSTerminalOnChange(Item)
	
	Object.POSTerminal = POSTerminal;
	
EndProcedure

#EndRegion

