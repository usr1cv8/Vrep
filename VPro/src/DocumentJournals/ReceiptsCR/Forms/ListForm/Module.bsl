// Procedure - form event handler "OnLoadDataFromSettingsAtServer".
//
&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	CashCR = Settings.Get("CashCR");
	
	If GetFunctionalOption("LimitAccessOnRecordsLevel") Then
		Query = New Query;
		Query.Text = 
			"SELECT ALLOWED
			|	T.Ref AS Ref
			|FROM
			|	Catalog.CashRegisters AS T
			|WHERE
			|	T.Ref = &CashCR";
		
		Query.SetParameter("CashCR", CashCR);
		
		QueryResult = Query.Execute();
		If QueryResult.IsEmpty() Then
			CashCR = Catalogs.CashRegisters.EmptyRef();
		EndIf;
		
	EndIf;

	CurrentSessionOnly = Settings.Get("CurrentSessionOnly");
	
	UpdateCashCRSessionStateAtServer(CashCR);
	SetDynamicListsFilter();
	
//	UseWithoutEquipmentConnection = CommonUse.ObjectAttributeValue(CashCR,"UseWithoutEquipmentConnection");
	
	Items.CashDeposition.Visible = Not CashCR.UseWithoutEquipmentConnection;
	Items.Withdrawal.Visible = Not CashCR.UseWithoutEquipmentConnection;
	
EndProcedure // OnLoadDataFromSettingsAtServer()

///////////////////////////////////////////////////////////////////////////////
// PROCEDURE - FORM FIELD EVENT HANDLERS

// Procedure sets filter of dynamic form lists.
//
&AtServer
Procedure SetDynamicListsFilter()
	
	SmallBusinessClientServer.SetListFilterItem(ReceiptsCR, "CashCR", CashCR, ValueIsFilled(CashCR), DataCompositionComparisonType.Equal);
	SmallBusinessClientServer.SetListFilterItem(ReceiptsCR, "CashCRSession", CurrentCashCRSession, CurrentSessionOnly, DataCompositionComparisonType.Equal);
	
EndProcedure // SetDynamicListsFilter()

// Procedure - event handler "OnChange" of field "CashCR".
//
&AtServer
Procedure CashCRFilterOnChangeAtServer()
	
	UpdateCashCRSessionStateAtServer(CashCR);
	SetDynamicListsFilter();
	Items.CashDeposition.Visible = Not CashCR.UseWithoutEquipmentConnection;
	Items.Withdrawal.Visible = Not CashCR.UseWithoutEquipmentConnection;
	
EndProcedure // PettyCashFilterOnChangeAtServer()

// Procedure - event handler "OnChange" of field "CashCR" on server.
//
&AtClient
Procedure CashCRFilterOnChange(Item)
	
	CashCRFilterOnChangeAtServer();
	
EndProcedure // PettyCashFilterOnChange()

// Function opens the cash session on server.
//
&AtServer
Function CashCRSessionOpenAtServer(CashCR, ErrorDescription = "")
	
	Return Documents.RetailReport.CashCRSessionOpen(CashCR, ErrorDescription);
	
EndFunction // OpenCashCRSessionAtServer()

// Procedure closes the cash session on server.
//
&AtServer
Function CloseCashCRSessionAtServer(CashCR, ErrorDescription = "")
	
	Return Documents.RetailReport.CloseCashCRSessionExecuteArchiving(CashCR, ErrorDescription);
	
EndFunction // CloseCashCRSessionAtServer()

// It is required to call the procedure from client when opening the cash session
&AtServer
Procedure UpdateCashCRSessionStateAndSetDynamicListsFilter(CashCR)
	
	UpdateCashCRSessionStateAtServer(CashCR);
	
	SetDynamicListsFilter();
	
EndProcedure // UpdateCashCRSessionStateAtServer()

// Procedure - command handler "OpenCashCRSession".
//
&AtClient
Procedure CashCRSessionOpen(Command)
	
	ClearMessages();
	
	If Not ValueIsFilled(CashCR) Then
		Return;
	EndIf;
	
	Result = False;
	
	If EquipmentManagerClient.RefreshClientWorkplace() Then
		
		// Device connection
		CashRegistersSettings = SmallBusinessReUse.CashRegistersGetParameters(CashCR);
		DeviceIdentifier = CashRegistersSettings.DeviceIdentifier;
		UseWithoutEquipmentConnection = CashRegistersSettings.UseWithoutEquipmentConnection;
		
		If DeviceIdentifier <> Undefined OR UseWithoutEquipmentConnection Then
			
			ErrorDescription = "";
			
			If Not UseWithoutEquipmentConnection Then
				
				Result = EquipmentManagerClient.ConnectEquipmentByID(
					UUID,
					DeviceIdentifier,
					ErrorDescription
				);
				
			EndIf;
			
			If Result OR UseWithoutEquipmentConnection Then
				
				If Not UseWithoutEquipmentConnection Then
					
					InputParameters   = Undefined;
					Output_Parameters = Undefined;
					
					//Open session on fiscal register
					Result = EquipmentManagerClient.RunCommand(
						DeviceIdentifier,
						"OpenDay",
						InputParameters, 
						Output_Parameters
					);
					
				EndIf;
				
				If Result OR UseWithoutEquipmentConnection Then
					
					Result = CashCRSessionOpenAtServer(CashCR, ErrorDescription);
					
					If Not Result Then
						
						MessageText = NStr("en='An error occurred when opening the session."
"Session is not opened."
"Additional"
"description: %AdditionalDetails%';ru='При открытии смены произошла ошибка."
"Смена не открыта."
"Дополнительное"
"описание: %ДополнительноеОписание%';vi='Khi mở phiên làm việc đã xảy ra lỗi."
"Chưa mở thay đổi."
"Mô tả"
"bổ sung: %AdditionalDetails%'"
						);
						MessageText = StrReplace(
							MessageText,
							"%AdditionalDetails%",
							?(UseWithoutEquipmentConnection, ErrorDescription, Output_Parameters[1])
						);
						CommonUseClientServer.MessageToUser(MessageText);
						
					EndIf;
					
				Else
					
					MessageText = NStr("en='An error occurred when opening the session."
"Session is not opened."
"Additional"
"description: %AdditionalDetails%';ru='При открытии смены произошла ошибка."
"Смена не открыта."
"Дополнительное"
"описание: %ДополнительноеОписание%';vi='Khi mở phiên làm việc đã xảy ra lỗi."
"Chưa mở thay đổi."
"Mô tả"
"bổ sung: %AdditionalDetails%'"
					);
					MessageText = StrReplace(
						MessageText,
						"%AdditionalDetails%",
						ErrorDescription
					);
					CommonUseClientServer.MessageToUser(MessageText);
					
				EndIf;
				
				If Not UseWithoutEquipmentConnection Then
					
					EquipmentManagerClient.DisableEquipmentById(
						UUID,
						DeviceIdentifier
					);
					
				EndIf;
				
			Else
				
				MessageText = NStr("en='An error occurred when connecting the device."
"Session is not opened on the fiscal register."
"Additional"
"description: %AdditionalDetails%';ru='При подключении устройства произошла ошибка."
"Смена не открыта на фискальном регистраторе."
"Дополнительное"
"описание: %ДополнительноеОписание%';vi='Khi kết nối thiết bị đã xảy ra lỗi. Chưa mở phiên làm việc trên máy ghi nhận tiền mặt."
"Mô tả"
"bổ sung: %AdditionalDetails%"
"'"
				);
				MessageText = StrReplace(MessageText, "%AdditionalDetails%", ErrorDescription);
				CommonUseClientServer.MessageToUser(MessageText);
				
			EndIf;
			
		EndIf;
		
	Else
		
		MessageText = NStr("en='First, you need to select the work place of the current session peripherals.';ru='Предварительно необходимо выбрать рабочее место внешнего оборудования текущего сеанса.';vi='Trước tiên, cần chọn chỗ làm việc của thiết bị ngoài trong phiên làm việc hiện tại.'"
		);
		CommonUseClientServer.MessageToUser(MessageText);
		
	EndIf;
	
	UpdateCashCRSessionStateAndSetDynamicListsFilter(CashCR);
	
EndProcedure // OpenCashCRSession()

// Function verifies the existence of issued receipts during the session.
//
&AtServer
Function IssuedReceiptsExist(CashCR)
	
	StructureStateCashCRSession = Documents.RetailReport.GetCashCRSessionStatus(CashCR);
	
	If StructureStateCashCRSession.CashCRSessionStatus <> Enums.CashCRSessionStatuses.IsOpen Then
		Return False;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ReceiptCRInventory.Ref AS CountRecipies
	|FROM
	|	(SELECT
	|		ReceiptCRInventory.Ref AS Ref
	|	FROM
	|		Document.ReceiptCR.Inventory AS ReceiptCRInventory
	|	WHERE
	|		ReceiptCRInventory.Ref.CashCRSession = &CashCRSession
	|		AND ReceiptCRInventory.Ref.Posted
	|		AND ReceiptCRInventory.Ref.ReceiptCRNumber > 0
	|		AND (NOT ReceiptCRInventory.Ref.Archival)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ReceiptCRInventory.Ref
	|	FROM
	|		Document.ReceiptCRReturn.Inventory AS ReceiptCRInventory
	|	WHERE
	|		ReceiptCRInventory.Ref.CashCRSession = &CashCRSession
	|		AND ReceiptCRInventory.Ref.Posted
	|		AND ReceiptCRInventory.Ref.ReceiptCRNumber > 0
	|		AND (NOT ReceiptCRInventory.Ref.Archival)) AS ReceiptCRInventory";
	
	Query.SetParameter("CashCRSession", StructureStateCashCRSession.CashCRSession);
	
	Result = Query.Execute();
	
	Return Not Result.IsEmpty();
	
EndFunction // ThereAreIssuedReceiptsForSession()

// Procedure - command handler "CloseCashCRSession".
//
&AtClient
Procedure CloseCashCRSession(Command)
	
	ClearMessages();
	
	If Not ValueIsFilled(CashCR) Then
		Return;
	EndIf;
	
	Result = False;
	
	If Not IssuedReceiptsExist(CashCR) Then
		
		ErrorDescription = "";
		
		DocumentArray = CloseCashCRSessionAtServer(CashCR, ErrorDescription);
		
		If ValueIsFilled(ErrorDescription) Then
			MessageText = NStr("en='Session is closed on the fiscal register, but errors occurred when generating the retail sales report."
"Additional"
"description: %AdditionalDetails%';ru='Смена закрыта на фискальном регистраторе, но при формировании отчета о розничных продажах возникли ошибки."
"Дополнительное"
"описание: %ДополнительноеОписание%';vi='Đã đóng phiên làm việc trên máy ghi nhận tiền mặt, nhưng khi tạo báo cáo về bảng kê bán lẻ hàng hóa đã xảy ra lỗi."
"Mô tả"
"bổ sung: %AdditionalDetails%'"
			);
			MessageText = StrReplace(MessageText, "%AdditionalDetails%", ErrorDescription);
			CommonUseClientServer.MessageToUser(MessageText);
		EndIf;
		
		// Show all resulting documents to user.
		For Each Document IN DocumentArray Do
			
			OpenForm("Document.RetailReport.ObjectForm", New Structure("Key", Document));
			
		EndDo;
		
	ElsIf EquipmentManagerClient.RefreshClientWorkplace() Then
		
		// Device connection
		CashRegistersSettings = SmallBusinessReUse.CashRegistersGetParameters(CashCR);
		DeviceIdentifier = CashRegistersSettings.DeviceIdentifier;
		UseWithoutEquipmentConnection = CashRegistersSettings.UseWithoutEquipmentConnection;
	
		If DeviceIdentifier <> Undefined OR UseWithoutEquipmentConnection Then
			
			ErrorDescription = "";
			
			If Not UseWithoutEquipmentConnection Then
				
				Result = EquipmentManagerClient.ConnectEquipmentByID(
					UUID,
					DeviceIdentifier,
					ErrorDescription
				);
				
			EndIf;
			
			If Result OR UseWithoutEquipmentConnection Then
				
				If Not UseWithoutEquipmentConnection Then
					InputParameters  = Undefined;
					Output_Parameters = Undefined;
					
					Result = EquipmentManagerClient.RunCommand(
						DeviceIdentifier,
						"PrintZReport",
						InputParameters,
						Output_Parameters
					);
				EndIf;
				
				If Not Result AND Not UseWithoutEquipmentConnection Then
					
					MessageText = NStr("en='Error occurred when closing the session on the fiscal register."
"""%ErrorDescription%"""
"Report on fiscal register is not formed.';ru='При закрытии смены на фискальном регистраторе произошла ошибка."
"""%ОписаниеОшибки%"""
"Отчет на фискальном регистраторе не сформирован.';vi='Khi đóng phiên làm việc trên máy ghi nhận tiền mặt đã xảy ra lỗi."
"""%ErrorDescription%"""
"Chưa tạo báo cáo trên máy ghi nhận tiền mặt.'"
					);
					MessageText = StrReplace(
						MessageText,
						"%ErrorDescription%",
						Output_Parameters[1]
					);
					CommonUseClientServer.MessageToUser(MessageText);
					
				Else
					
					DocumentArray = CloseCashCRSessionAtServer(CashCR, ErrorDescription);
					
					If ValueIsFilled(ErrorDescription)
					   AND UseWithoutEquipmentConnection Then
						
						CommonUseClientServer.MessageToUser(ErrorDescription);
						
					ElsIf ValueIsFilled(ErrorDescription)
						 AND Not UseWithoutEquipmentConnection Then
						
						MessageText = NStr("en='Session is closed on the fiscal register, but errors occurred when generating the retail sales report."
"Additional description:"
"%AdditionalDetails%';ru='Смена закрыта на фискальном регистраторе, но при формировании отчета о розничных продажах возникли ошибки."
"Дополнительное"
"описание: %ДополнительноеОписание%';vi='Đã đóng phiên làm việc trên máy ghi nhận tiền mặt, nhưng khi tạo bảng kê bán lẻ hàng hóa đã xảy ra lỗi."
"Mô tả"
"bổ sung: %AdditionalDetails%"
"'"
						);
						MessageText = StrReplace(MessageText, "%AdditionalDetails%", ErrorDescription);
						CommonUseClientServer.MessageToUser(MessageText);
						
					EndIf;
					
					// Show all resulting documents to user.
					For Each Document IN DocumentArray Do
						
						OpenForm("Document.RetailReport.ObjectForm", New Structure("Key", Document));
						
					EndDo;
					
				EndIf;
				
				If Not UseWithoutEquipmentConnection Then
					
					EquipmentManagerClient.DisableEquipmentById(
						UUID,
						DeviceIdentifier
					);
					
				EndIf;
				
			Else
				
				MessageText = NStr("en='An error occurred when connecting the device."
"Report is not printed and session is not closed on the fiscal register."
"Additional description:"
"%AdditionalDetails%';ru='При подключении устройства произошла ошибка."
"Отчет не напечатан и смена не закрыта на фискальном регистраторе."
"Дополнительное"
"описание: %ДополнительноеОписание%';vi='Khi kết nối thiết bị đã xảy ra lỗi."
"Báo cáo chưa được in và chưa đóng phiên làm việc trên máy ghi nhận tiền mặt."
"Mô tả"
"bổ sung: %AdditionalDetails%'"
				);
				MessageText = StrReplace(MessageText, "%AdditionalDetails%", ErrorDescription);
				CommonUseClientServer.MessageToUser(MessageText);
				
			EndIf;
			
		EndIf;
		
	Else
		
		MessageText = NStr("en='First, you need to select the work place of the current session peripherals.';ru='Предварительно необходимо выбрать рабочее место внешнего оборудования текущего сеанса.';vi='Trước tiên, cần chọn chỗ làm việc của thiết bị ngoài trong phiên làm việc hiện tại.'"
		);
		CommonUseClientServer.MessageToUser(MessageText);
		
	EndIf;
	
	UpdateCashCRSessionStateAndSetDynamicListsFilter(CashCR);
	
	Notify("RefreshFormsAfterZReportIsDone");
	
EndProcedure // CloseCashCRSession()

// Procedure - command handler "FundsIntroduction".
//
&AtClient
Procedure CashDeposition(Command)
	
	If EquipmentManagerClient.RefreshClientWorkplace() Then
		
		InAmount = 0;
		
		WindowTitle = NStr("en='Deposit amount, ';ru='Сумма внесения, ';vi='Số tiền đặt cọc,'") + "%Currency%";
		WindowTitle = StrReplace(
			WindowTitle,
			"%Currency%",
			StructureStateCashCRSession.DocumentCurrencyPresentation
		);
		
		ShowInputNumber(New NotifyDescription("FundsIntroductionEnd", ThisObject, New Structure("InAmount", InAmount)), InAmount, WindowTitle, 15, 2);
		
	Else
		
		MessageText = NStr("en='First, you need to select the work place of the current session peripherals.';ru='Предварительно необходимо выбрать рабочее место внешнего оборудования текущего сеанса.';vi='Trước tiên, cần chọn chỗ làm việc của thiết bị ngoài trong phiên làm việc hiện tại.'"
		);
		CommonUseClientServer.MessageToUser(MessageText);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FundsIntroductionEnd(Result1, AdditionalParameters) Export
	
	InAmount = ?(Result1 = Undefined, AdditionalParameters.InAmount, Result1);
	
	If (Result1 <> Undefined) Then
		
		// Device connection
		CashRegistersSettings = SmallBusinessReUse.CashRegistersGetParameters(CashCR);
		DeviceIdentifier = CashRegistersSettings.DeviceIdentifier;
		UseWithoutEquipmentConnection = CashRegistersSettings.UseWithoutEquipmentConnection;
		
		If ValueIsFilled(DeviceIdentifier) Then
			FundsIntroductionFiscalRegisterConnectionsEnd(DeviceIdentifier, InAmount);
		Else
			NotifyDescription = New NotifyDescription("FundsIntroductionFiscalRegisterConnectionsEnd", ThisObject, InAmount);
			EquipmentManagerClient.OfferSelectDevice(NOTifyDescription, "FiscalRegister",
				NStr("en='Select a fiscal data recorder';ru='Выберите фискальный регистратор';vi='Hãy chọn máy ghi nhận tiền mặt'"), NStr("en='Fiscal data recorder is not connected.';ru='Фискальный регистратор не подключен.';vi='Chưa kết nối máy ghi nhận tiền mặt.'"));
		EndIf;
		
	EndIf;

EndProcedure // FundsIntroduction()

&AtClient
Procedure FundsIntroductionFiscalRegisterConnectionsEnd(DeviceIdentifier, Parameters) Export
	
	InAmount = Parameters;
	ErrorDescription = "";
	
	If DeviceIdentifier <> Undefined Then
		
		// Connect FR
		Result = EquipmentManagerClient.ConnectEquipmentByID(
			UUID,
			DeviceIdentifier,
			ErrorDescription
		);
		
		If Result Then
			
			//Prepare data
			InputParameters  = New Array();
			Output_Parameters = Undefined;
			
			InputParameters.Add(1);
			InputParameters.Add(InAmount);
			
			// Print receipt.
			Result = EquipmentManagerClient.RunCommand(
			DeviceIdentifier,
			"Encash",
			InputParameters,
			Output_Parameters
			);
			
			If Not Result Then
				
				MessageText = NStr("en='When printing a receipt, an error occurred."
"Receipt is not printed on the fiscal register."
"Additional description:"
"%AdditionalDetails%';ru='При печати чека произошла ошибка."
"Чек не напечатан на фискальном регистраторе."
"Дополнительное"
"описание: %ДополнительноеОписание%';vi='Khi in phiếu đã xảy ra lỗi. "
"Chưa in phiếu trên máy ghi nhận tiền mặt."
"Mô tả"
"bổ sung: %AdditionalDetails%'"
				);
				MessageText = StrReplace(MessageText,
				"%AdditionalDetails%",
				Output_Parameters[1]
				);
				CommonUseClientServer.MessageToUser(MessageText);
				
			EndIf;
			
			// Disconnect FR
			EquipmentManagerClient.DisableEquipmentById(UUID, DeviceIdentifier);
			
		Else
			
			MessageText = NStr("en='An error occurred when connecting the device."
"Receipt is not printed on the fiscal register."
"Additional description:"
"%AdditionalDetails%';ru='При подключении устройства произошла ошибка."
"Чек не напечатан на фискальном регистраторе."
"Дополнительное"
"описание: %ДополнительноеОписание%';vi='Khi kết nối thiết bị xảy ra lỗi."
"Phiếu tính tiền chưa được in trên máy ghi nhận tiền mặt."
"Mô tả"
"bổ sung: %AdditionalDetails%'"
			);
			MessageText = StrReplace(MessageText, "%AdditionalDetails%", ErrorDescription);
			CommonUseClientServer.MessageToUser(MessageText);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Procedure - command handler "FundsWithdrawal".
//
&AtClient
Procedure Withdrawal(Command)
	
	If EquipmentManagerClient.RefreshClientWorkplace() Then
		
		WithdrawnAmount = 0;
		
		WindowTitle = NStr("en='Withdrawal amount, ';ru='Сумма выемки, ';vi='Số tiền rút.'") + "%Currency%";
		WindowTitle = StrReplace(
			WindowTitle,
			"%Currency%",
			StructureStateCashCRSession.DocumentCurrencyPresentation
		);
		
		ShowInputNumber(New NotifyDescription("CashWithdrawalEnd", ThisObject, New Structure("WithdrawnAmount", WithdrawnAmount)), WithdrawnAmount, WindowTitle, 15, 2);
		
	Else
		
		MessageText = NStr("en='First, you need to select the work place of the current session peripherals.';ru='Предварительно необходимо выбрать рабочее место внешнего оборудования текущего сеанса.';vi='Trước tiên, cần chọn chỗ làm việc của thiết bị ngoài trong phiên làm việc hiện tại.'");
		CommonUseClientServer.MessageToUser(MessageText);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CashWithdrawalEnd(Result1, AdditionalParameters) Export
	
	WithdrawnAmount = ?(Result1 = Undefined, AdditionalParameters.WithdrawnAmount, Result1);
	
	If (Result1 <> Undefined) Then
		
		ErrorDescription = "";
		
		// Device connection
		CashRegistersSettings = SmallBusinessReUse.CashRegistersGetParameters(CashCR);
		DeviceIdentifier = CashRegistersSettings.DeviceIdentifier;
		UseWithoutEquipmentConnection = CashRegistersSettings.UseWithoutEquipmentConnection;
		
		If ValueIsFilled(DeviceIdentifier) Then
			CashWithdrawalFiscalRegisterConnectionsEnd(DeviceIdentifier, WithdrawnAmount);
		Else
			NotifyDescription = New NotifyDescription("CashWithdrawalFiscalRegisterConnectionsEnd", ThisObject, WithdrawnAmount);
			EquipmentManagerClient.OfferSelectDevice(NOTifyDescription, "FiscalRegister",
				NStr("en='Select a fiscal data recorder';ru='Выберите фискальный регистратор';vi='Hãy chọn máy ghi nhận tiền mặt'"), NStr("en='Fiscal data recorder is not connected.';ru='Фискальный регистратор не подключен.';vi='Chưa kết nối máy ghi nhận tiền mặt.'"));
		EndIf;
	
	EndIf;

EndProcedure // FundsWithdrawal()

&AtClient
Procedure CashWithdrawalFiscalRegisterConnectionsEnd(DeviceIdentifier, Parameters) Export
	
	WithdrawnAmount = Parameters;
	ErrorDescription = "";
	
	If DeviceIdentifier <> Undefined Then
			
			// Connect FR
			Result = EquipmentManagerClient.ConnectEquipmentByID(
			UUID,
			DeviceIdentifier,
			ErrorDescription
			);
			
			If Result Then
				
				//Prepare data
				InputParameters  = New Array();
				Output_Parameters = Undefined;
				
				InputParameters.Add(0);
				InputParameters.Add(WithdrawnAmount);
				
				// Print receipt.
				Result = EquipmentManagerClient.RunCommand(
					DeviceIdentifier,
					"Encash",
					InputParameters,
					Output_Parameters
				);
				
				If Not Result Then
					
					MessageText = NStr("en='When printing a receipt, an error occurred."
"Receipt is not printed on the fiscal register."
"Additional description: "
"%AdditionalDetails%';ru='При печати чека произошла ошибка. Чек не напечатан на фискальном регистраторе. Дополнительное описание: %ДополнительноеОписание%';vi='Khi in phiếu đã xảy ra lỗi. Chưa in phiếu trên máy ghi nhận tiền mặt."
"Mô tả bổ sung:"
"%AdditionalDetails%'"
					);
					MessageText = StrReplace(
					MessageText,
					"%AdditionalDetails%",
					Output_Parameters[1]
					);
					CommonUseClientServer.MessageToUser(MessageText);
					
				EndIf;
				
				// Disconnect FR
				EquipmentManagerClient.DisableEquipmentById(UUID, DeviceIdentifier);
				
			Else
				
				MessageText = NStr("en='An error occurred when connecting the device."
"Receipt is not printed on the fiscal register."
"Additional description:"
"%AdditionalDetails%';ru='При подключении устройства произошла ошибка."
"Чек не напечатан на фискальном регистраторе."
"Дополнительное"
"описание: %ДополнительноеОписание%';vi='Khi kết nối thiết bị xảy ra lỗi."
"Phiếu tính tiền chưa được in trên máy ghi nhận tiền mặt."
"Mô tả"
"bổ sung: %AdditionalDetails%'"
				);
				MessageText = StrReplace(MessageText, "%AdditionalDetails%", ErrorDescription);
				CommonUseClientServer.MessageToUser(MessageText);
				
			EndIf;
			
		EndIf;
	
EndProcedure

// Function gets cash session state on server.
//
&AtServerNoContext
Function GetCashCRSessionStateAtServer(CashCR)
	
	Return Documents.RetailReport.GetCashCRSessionStatus(CashCR);
	
EndFunction // GetCashCRSessionStateAtServer()

// Procedure updates cash session state on client.
//
&AtServer
Procedure UpdateCashCRSessionStateAtServer(CashCR)
	
	StructureStateCashCRSession = GetCashCRSessionStateAtServer(CashCR);
	If ValueIsFilled(StructureStateCashCRSession.CashCRSessionStatus) Then
		
		MessageText = NStr("en='Session No.%NumberOfSession%, Status: %SessionStatus% %ModifiedAt%, IN cash %CashInPettyCash% %Currency%';ru='Session No.%NumberOfSession%, Status: %SessionStatus% %ModifiedAt%, IN cash %CashInPettyCash% %Currency%';vi='Số phiên.%NumberOfSession%, Trạng thái: %SessionStatus% %ModifiedAt%, Tiền mặt %CashInPettyCash% %Tiền mặt%'");
		
		MessageText = StrReplace(MessageText, "%NumberOfSession%", TrimAll(StructureStateCashCRSession.CashCRSessionNumber));
		MessageText = StrReplace(MessageText, "%SessionStatus%", StructureStateCashCRSession.CashCRSessionStatus);
		MessageText = StrReplace(MessageText, "%CashInPettyCash%", StructureStateCashCRSession.CashInPettyCash);
		MessageText = StrReplace(MessageText, "%Currency%", StructureStateCashCRSession.DocumentCurrencyPresentation);
		MessageText = StrReplace(MessageText, "%ModifiedAt%", Format(StructureStateCashCRSession.StatusModificationDate,"DF=dd.MM.yy HH:mm'"));
		
		StatusCashCRSession = MessageText;
		
	Else
		
		StatusCashCRSession = NStr("en='Shift is not opened.';ru='Смена не открыта.';vi='Chưa mở phiên làm việc.'");
		
	EndIf;
	
	// Form variable
	SessionIsOpen = StructureStateCashCRSession.SessionIsOpen;
	CurrentCashCRSession = StructureStateCashCRSession.CashCRSession;
	
	// Availability management.
	Items.DisableZReport.Visible		  = SessionIsOpen;
	Items.CashCRSessionOpen.Visible = Not SessionIsOpen AND ValueIsFilled(CashCR);
	
	Items.ReceiptsCRCreateReceipt.Enabled					= SessionIsOpen;
	Items.ReceiptsCRDocumentReturnReceiptCRCreateBasedOn.Enabled = SessionIsOpen;
	Items.ReceiptsCRCopy.Enabled				= SessionIsOpen;
	Items.ContextMenuReceiptsCRCopy.Enabled = SessionIsOpen;
	
	Items.CashDeposition.Enabled = ValueIsFilled(CashCR);
	Items.Withdrawal.Enabled   = ValueIsFilled(CashCR);
	
EndProcedure // UpdateCashCRSessionStateAndSetDynamicListFilter()

// Procedure - command handler "UpdateCashCRSessionState".
//
&AtClient
Procedure UpdateCashCRSessionState(Command)
	
	If Not ValueIsFilled(CashCR) Then
		Return;
	EndIf;
	
	UpdateCashCRSessionStateAndSetDynamicListsFilter(CashCR);
	
EndProcedure // UpdateCashCRSessionState()

// Procedure - command handler "OpenFiscalRegisterManagement".
//
&AtClient
Procedure OpenFiscalRegisterManagement(Command)
	
	OpenForm("Catalog.Peripherals.Form.FiscalRegisterManagement");

EndProcedure // OpenFiscalRegisterManagement)()

// Procedure - command handler "OpenPOSTerminalManagement".
//
&AtClient
Procedure OpenPOSTerminalManagement(Command)
	
	OpenForm("Catalog.Peripherals.Form.POSTerminalManagement");

EndProcedure // OpenPOSTerminalManagement()

// Procedure - form event handler "NotificationProcessing".
//
&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName  = "RefreshFormsAfterZReportIsDone" Then
		Items.ReceiptsCR.Refresh();
		UpdateCashCRSessionStateAndSetDynamicListsFilter(CashCR);
		ReceiptsCROnActivateRowAtClient();
	ElsIf EventName = "RefreshReceiptCRDocumentsListForm" Then
		Items.ReceiptsCR.Refresh();
		UpdateCashCRSessionStateAndSetDynamicListsFilter(CashCR);
		ReceiptsCROnActivateRowAtClient();
	ElsIf EventName = "RefreshFormsAfterClosingCashCRSession" Then
		Items.ReceiptsCR.Refresh();
		UpdateCashCRSessionStateAndSetDynamicListsFilter(CashCR);
		ReceiptsCROnActivateRowAtClient();
	EndIf;
	
EndProcedure // NotificationProcessing()

// Procedure is intended to handle the "OnActivateRow" event of the ReceiptsCR list
//
&AtClient
Procedure ReceiptsCROnActivateRowAtClient()
	
	If StructureStateCashCRSession = Undefined Then
		UpdateCashCRSessionStateAndSetDynamicListsFilter(CashCR);
	EndIf;
	
	CurrentData = Items.ReceiptsCR.CurrentData;
	If CurrentData <> Undefined Then
		
		If Not CurrentData.Property("RowGroup")
			AND ValueIsFilled(CurrentData.ReceiptCRNumber)
			AND ValueIsFilled(StructureStateCashCRSession)
			AND CurrentData.CashCRSession = StructureStateCashCRSession.CashCRSession
			AND Not CurrentData.ThereIsBillForReturn
			AND SessionIsOpen
			AND CurrentData.Type <> Type("DocumentRef.ReceiptCRReturn") Then
			
			Items.ReceiptsCRDocumentReturnReceiptCRCreateBasedOn.Enabled = True;
			Items.ContextMenuReceiptsCRDocumentReceiptCRReturnCreateBasedOn.Enabled = True;
			
		Else
			
			Items.ReceiptsCRDocumentReturnReceiptCRCreateBasedOn.Enabled = False;
			Items.ContextMenuReceiptsCRDocumentReceiptCRReturnCreateBasedOn.Enabled = False;
			
		EndIf;
		
	EndIf;
	
EndProcedure // ReceiptsCROnActivateRowAtClient()

// Procedure - event handler "OnActivateRow" of the ReceiptsCR list.
//
&AtClient
Procedure ReceiptsCROnActivateRow(Item)
	
	ReceiptsCROnActivateRowAtClient();
	
EndProcedure // ReceiptsCROnActivateRow()

// Procedure is intended to handle the "OnChangeAtServer" event of the CurrentSessionOnlyFilter flag on server
//
&AtServer
Procedure CurrentSessionOnlyFilterOnChangeAtServer()
	
	SetDynamicListsFilter();
	
EndProcedure // CurrentSessionOnlyFilterOnChangeAtServer()

// Procedure - event handler "OnChange" of the CurrentSessionOnlyFilter flag.
//
&AtClient
Procedure CurrentSessionOnlyFilterOnChange(Item)

	CurrentSessionOnlyFilterOnChangeAtServer();

EndProcedure // CurrentSessionOnlyFilter()

// Procedure - command handler "CreateReceipt".
//
&AtClient
Procedure CreateReceipt(Command)
	
	If SessionIsOpen Then
		OpenParameters = New Structure("Basis", New Structure("CashCR", CashCR));
		OpenForm("Document.ReceiptCR.ObjectForm", OpenParameters);
	EndIf;
	
EndProcedure // CreateReceipt()

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Set the format for the current date: DF=H:mm
	SmallBusinessServer.SetDesignDateColumn(ReceiptsCR);
	
EndProcedure

#Region PerformanceMeasurements

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Group)
	
	KeyOperation = "FormCreatingReceiptCR";
	PerformanceEstimationClientServer.StartTimeMeasurement(KeyOperation);
	
EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	KeyOperation = "FormOpeningReceiptCR";
	PerformanceEstimationClientServer.StartTimeMeasurement(KeyOperation);
	
EndProcedure

#EndRegion
