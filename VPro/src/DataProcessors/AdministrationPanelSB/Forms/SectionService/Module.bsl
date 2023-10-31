
&AtClient
Var RefreshInterface;

////////////////////////////////////////////////////////////////////////////////
// SERVICE PROCEDURES AND FUNCTIONS

&AtClient
Procedure Attachable_OnAttributeChange(Item, RefreshingInterface = True)
	
	Result = OnAttributeChangeServer(Item.Name);
	
	If Result.Property("ErrorText") Then
		
		// There is no option to use CommonUseClientServer.ReportToUser as it is required to pass the UID forms
		CustomMessage = New UserMessage;
		Result.Property("Field", CustomMessage.Field);
		Result.Property("ErrorText", CustomMessage.Text);
		CustomMessage.TargetID = UUID;
		CustomMessage.Message();
		
		RefreshingInterface = False;
		
	EndIf;
	
	If RefreshingInterface Then
		#If Not WebClient And Not MobileClient Then
		AttachIdleHandler("RefreshApplicationInterface", 1, True);
		RefreshInterface = True;
		#EndIf
	EndIf;
	
	If Result.Property("NotificationForms") Then
		Notify(Result.NotificationForms.EventName, Result.NotificationForms.Parameter, Result.NotificationForms.Source);
	EndIf;
	
EndProcedure

&AtClient
Procedure RefreshApplicationInterface()
	
	#If Not WebClient And Not MobileClient Then
	If RefreshInterface = True Then
		RefreshInterface = False;
		RefreshInterface();
	EndIf;
	#EndIf
	
EndProcedure

// Procedure manages visible of the WEB Application group
//
&AtClient
Procedure VisibleManagement()
	
	#If Not WebClient And Not MobileClient Then
		
		CommonUseClientServer.SetFormItemProperty(Items, "WEBApplication", "Visible", False);
		
	#Else
		
		CommonUseClientServer.SetFormItemProperty(Items, "WEBApplication", "Visible", True);
		
	#EndIf
	
EndProcedure // VisibleManagement()

&AtServer
Procedure SetEnabled(AttributePathToData = "")
	
	If AttributePathToData = "ConstantsSet.FunctionalOptionUseWorkSubsystem" OR AttributePathToData = "" Then
		
		CommonUseClientServer.SetFormItemProperty(Items, "SettingsWorkOrders",	"Enabled", ConstantsSet.FunctionalOptionUseWorkSubsystem);
		
		If ConstantsSet.FunctionalOptionUseWorkSubsystem Then
			
			CommonUseClientServer.SetFormItemProperty(Items, "CatalogWorkOrderStates", 			"Enabled", ConstantsSet.UseCustomerOrderStates);
			CommonUseClientServer.SetFormItemProperty(Items, "SettingWorkOrderStatesDefault", "Enabled", Not ConstantsSet.UseCustomerOrderStates);
			
		EndIf;
		
	EndIf;
	
	If (RunMode.ThisIsSystemAdministrator OR CommonUseReUse.CanUseSeparatedData())
		AND ConstantsSet.FunctionalOptionUseWorkSubsystem Then
		
		If AttributePathToData = "ConstantsSet.UseCustomerOrderStates" OR AttributePathToData = "" Then
			
			CommonUseClientServer.SetFormItemProperty(Items, "CatalogWorkOrderStates", 			"Enabled", ConstantsSet.UseCustomerOrderStates);
			CommonUseClientServer.SetFormItemProperty(Items, "SettingWorkOrderStatesDefault", "Enabled", Not ConstantsSet.UseCustomerOrderStates);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Function OnAttributeChangeServer(ItemName)
	
	Result = New Structure;
	
	AttributePathToData = Items[ItemName].DataPath;
	
	ValidateAbilityToChangeAttributeValue(AttributePathToData, Result);
	
	If Result.Property("CurrentValue") Then
		
		// Rollback to previous value
		ReturnFormAttributeValue(AttributePathToData, Result.CurrentValue);
		
	Else
		
		SaveAttributeValue(AttributePathToData, Result);
		
		SetEnabled(AttributePathToData);
		
		RefreshReusableValues();
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure SaveAttributeValue(AttributePathToData, Result)
	
	// Save attribute values not connected with constants directly (one-to-one ratio).
	If AttributePathToData = "" Then
		Return;
	EndIf;
	
	// Definition of constant name.
	ConstantName = "";
	If Lower(Left(AttributePathToData, 13)) = Lower("ConstantsSet.") Then
		// If the path to attribute data is specified through "ConstantsSet".
		ConstantName = Mid(AttributePathToData, 14);
	Else
		// Definition of name and attribute value record in the corresponding constant from "ConstantsSet".
		// Used for the attributes of the form directly connected with constants (one-to-one ratio).
	EndIf;
	
	// Saving the constant value.
	If ConstantName <> "" Then
		ConstantManager = Constants[ConstantName];
		ConstantValue = ConstantsSet[ConstantName];
		
		If ConstantManager.Get() <> ConstantValue Then
			ConstantManager.Set(ConstantValue);
		EndIf;
		
		NotificationForms = New Structure("EventName, Parameter, Source", "Record_ConstantsSet", New Structure, ConstantName);
		Result.Insert("NotificationForms", NotificationForms);
	EndIf;
	
EndProcedure

// Procedure assigns the passed value to form attribute
//
// It is used if a new value did not pass the check
//
//
&AtServer
Procedure ReturnFormAttributeValue(AttributePathToData, CurrentValue)
	
	If AttributePathToData = "ConstantsSet.FunctionalOptionUseWorkSubsystem" Then
		
		ThisForm.ConstantsSet.FunctionalOptionUseWorkSubsystem = CurrentValue;
		
	ElsIf AttributePathToData = "ConstantsSet.UseCustomerOrderStates" Then
		
		ThisForm.ConstantsSet.UseCustomerOrderStates = CurrentValue;
		
	ElsIf AttributePathToData = "ConstantsSet.CustomerOrdersInProgressStatus" Then
		
		ThisForm.ConstantsSet.CustomerOrdersInProgressStatus = CurrentValue;
		
	ElsIf AttributePathToData = "ConstantsSet.CustomerOrdersCompletedStatus" Then
		
		ThisForm.ConstantsSet.CustomerOrdersCompletedStatus = CurrentValue;
		
	EndIf;
	
EndProcedure // ReturnFormAttributeValue()

////////////////////////////////////////////////////////////////////////////////
// GENERAL PURPOSE PROCEDURES AND FUNCTIONS

// Procedure to control the clearing of the "Use work" check box.
//
&AtServer
Function CancellationUncheckFunctionalOptionUseWorkSubsystem()
	
	ErrorText = "";
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	CustomerOrder.Ref
	|FROM
	|	Document.CustomerOrder AS CustomerOrder
	|WHERE
	|	CustomerOrder.OperationKind = VALUE(Enum.OperationKindsCustomerOrder.WorkOrder)";
	
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		
		ErrorText = NStr("en='There are documents of the ""Work order"" kind in the infobase. You cannot clear the ""Works"" check box.';ru='В информационной базе присутствуют документы ""Заказ - наряд""! Снятие флага ""Работы"" запрещено!';vi='Trong cơ sở thông tin có chứng từ ""Đơn hàng trọn gói""! Cấm bỏ dấu hộp kiểm ""Công việc""!'");
		
	EndIf;
	
	Return ErrorText;
	
EndFunction // CancellationUncheckFunctionalOptionUseWorkSubsystem()

// Check the possibility to disable the UseCustomerOrderStates option.
//
&AtServer
Function CancellationUncheckUseCustomerOrderStates()
	
	ErrorText = "";
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	CustomerOrder.Ref,
	|	CustomerOrder.OperationKind AS OperationKind
	|FROM
	|	Document.CustomerOrder AS CustomerOrder
	|WHERE
	|	(CustomerOrder.OrderState.OrderStatus = VALUE(Enum.OrderStatuses.Open)
	|			OR CustomerOrder.OrderState.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|				AND NOT CustomerOrder.Closed
	|				AND (CustomerOrder.OperationKind = VALUE(Enum.OperationKindsCustomerOrder.OrderForSale)
	|					OR CustomerOrder.OperationKind = VALUE(Enum.OperationKindsCustomerOrder.OrderForProcessing)))
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	WorkOrder.Ref,
	|	WorkOrder.OperationKind
	|FROM
	|	Document.CustomerOrder AS WorkOrder
	|WHERE
	|	(WorkOrder.OrderState.OrderStatus = VALUE(Enum.OrderStatuses.Open)
	|			OR WorkOrder.OrderState.OrderStatus = VALUE(Enum.OrderStatuses.Completed)
	|				AND NOT WorkOrder.Closed
	|				AND WorkOrder.OperationKind = VALUE(Enum.OperationKindsCustomerOrder.WorkOrder))";

	Result = Query.Execute();
	If Not Result.IsEmpty() Then
		
		ErrorText = NStr("en='There are documents ""Customer order"" and/or ""Work order"" in the base in the state with the ""Open"" and/or ""Executed (not closed)"" status!"
"Disabling the option is prohibited!"
"Note:"
"If there are documents in the state with"
"the status ""Open"", set them to state with the status ""In progress"""
"or ""Executed (closed)"" If there are documents in the state"
"with the status ""Executed (not closed)"", then set them to state with the status ""Executed (closed)"".';ru='В базе есть документы ""Заказ покупателя"" и/или ""Заказ-наряд"" в состоянии со статусом ""Открыт"" и/или ""Выполнен (не закрыт)""!"
"Снятие опции запрещено!"
"Примечание:"
"Если есть документы в состоянии со статусом ""Открыт"", "
"то установите для них состояние со статусом ""В работе"" или ""Выполнен (закрыт)"""
"Если есть документы в состоянии со статусом ""Выполнен (не закрыт)"","
"то установите для них состояние со статусом ""Выполнен (закрыт)"".';vi='Trong cơ sở có chứng từ ""Đơn hàng của khách"" và/hoặc ""Đơn hàng trọn gói"" với trạng thái ""Ghi nháp"" và/hoặc ""Đã thực hiện (chưa đóng)""!"
"Cấm bỏ tùy chọn!"
"Chú ý:"
"Nếu có chứng từ với trạng thái ""Ghi nháp"" thì hãy đặt trạng thái ""Đang xử lý"" hoặc ""Đã thực hiện (đã đóng)"""
"Nếu có chứng từ với trạng thái ""Đã thực hiện (chưa đóng)"" thì hãy đặt trạng thái ""Đã thực hiện (đã đóng)"". '"
		);
		
	EndIf;
	
	Return ErrorText;
	
EndFunction // CancellationUncheckUseCustomerOrderStates()

// Initialization of checking the possibility to disable the CurrencyTransactionsAccounting option.
//
&AtServer
Function ValidateAbilityToChangeAttributeValue(AttributePathToData, Result)
	
	// Disable/disable the Service section
	If AttributePathToData = "ConstantsSet.FunctionalOptionUseWorkSubsystem" Then
		
		If Constants.FunctionalOptionUseWorkSubsystem.Get() <> ConstantsSet.FunctionalOptionUseWorkSubsystem
			AND (NOT ConstantsSet.FunctionalOptionUseWorkSubsystem) Then
			
			ErrorText = CancellationUncheckFunctionalOptionUseWorkSubsystem();
			If Not IsBlankString(ErrorText) Then
				
				Result.Insert("Field", 				AttributePathToData);
				Result.Insert("ErrorText", 		ErrorText);
				Result.Insert("CurrentValue",	True);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	// If there are documents Customer order or Work order with the status which differs from Executed, it is not allowed to remove the flag.
	If AttributePathToData = "ConstantsSet.UseCustomerOrderStates" Then
		
		If Constants.UseCustomerOrderStates.Get() <> ConstantsSet.UseCustomerOrderStates
			AND (NOT ConstantsSet.UseCustomerOrderStates) Then
			
			ErrorText = CancellationUncheckUseCustomerOrderStates();
			If Not IsBlankString(ErrorText) Then
				
				Result.Insert("Field", 				AttributePathToData);
				Result.Insert("ErrorText", 		ErrorText);
				Result.Insert("CurrentValue",	True);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If AttributePathToData = "ConstantsSet.CustomerOrdersInProgressStatus" Then
		
		If Not ConstantsSet.UseCustomerOrderStates
			AND Not ValueIsFilled(ConstantsSet.CustomerOrdersInProgressStatus) Then
			
			ErrorText = NStr("en='The ""Use several customer order states"" check box is cleared, but the ""In progress"" state parameter is not filled in.';ru='Снят флаг ""Использовать несколько состояний заказов покупателей"", но не заполнен параматр состояния заказа покупателя ""В работе""!';vi='Đã bỏ dấu hộp kiểm ""Sử dụng nhiều trạng thái đơn hàng của khách"", nhưng chưa điền tham số trạng thái đơn hàng của khách ""Đang làm việc""!'");
			Result.Insert("Field", 				AttributePathToData);
			Result.Insert("ErrorText", 		ErrorText);
			Result.Insert("CurrentValue",	Constants.CustomerOrdersInProgressStatus.Get());
			
		EndIf;
		
	EndIf;
	
	If AttributePathToData = "ConstantsSet.CustomerOrdersCompletedStatus" Then
		
		If Not ConstantsSet.UseCustomerOrderStates
			AND Not ValueIsFilled(ConstantsSet.CustomerOrdersCompletedStatus) Then
			
			ErrorText = NStr("en='The ""Use several customer order states"" check box is cleared, but the ""Completed"" state parameter is not filled in.';ru='Снят флаг ""Использовать несколько состояний заказов покупателей"", но не заполнен параматр состояния заказа покупателя ""Выполнен""!';vi='Đã bỏ dấu hộp kiểm ""Sử dụng nhiều trạng thái đơn hàng của khách"", nhưng chưa điền tham số trạng thái đơn hàng của khách là ""Đã thực hiện""!'");
			Result.Insert("Field", 				AttributePathToData);
			Result.Insert("ErrorText", 		ErrorText);
			Result.Insert("CurrentValue",	Constants.CustomerOrdersCompletedStatus.Get());
			
		EndIf;
		
	EndIf;
	
EndFunction // CheckAbilityToChangeAttributeValue()

////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - FORM COMMAND HANDLERS

// Procedure - command handler UpdateSystemParameters.
//
&AtClient
Procedure UpdateSystemParameters()
	
	RefreshInterface();
	
EndProcedure // UpdateSystemParameters()

// Procedure - command handler CatalogWorkOrderStates.
//
&AtClient
Procedure CatalogWorkOrderStates(Command)
	
	OpenForm("Catalog.CustomerOrderStates.ListForm");
	
EndProcedure // CatalogWorkOrderStates()

////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - FORM EVENT HANDLERS

// Procedure - event handler OnCreateAtServer of the form.
//
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then
		Return;
	EndIf;
	
	// Attribute values of the form
	RunMode = CommonUseReUse.ApplicationRunningMode();
	RunMode = New FixedStructure(RunMode);
	
	SetEnabled();
	
EndProcedure // OnCreateAtServer()

// Procedure - event handler OnCreateAtServer of the form.
//
&AtClient
Procedure OnOpen(Cancel)
	
	VisibleManagement();
	
EndProcedure // OnOpen()

// Procedure - event handler OnClose form.
&AtClient
Procedure OnClose()
	
	RefreshApplicationInterface();
	
EndProcedure // OnClose()

////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - EVENT HANDLERS OF FORM ATTRIBUTES

// Procedure - event handler OnChange of the FunctionalOptionUseWorkSubsystem field.
//
&AtClient
Procedure FunctionalOptionUseWorkSubsystemOnChange(Item)
	
	Attachable_OnAttributeChange(Item);
	
EndProcedure // FunctionalOptionUseWorkSubsystemOnChange()

// Procedure - event handler OnChange of the UseWorkOrderStates field.
//
&AtClient
Procedure UseWorkOrderStatesOnChange(Item)
	
	Attachable_OnAttributeChange(Item);
	
EndProcedure // UseWorkOrderStatesOnChange()

// Procedure - event handler OnChange of the InProcessStatus field.
//
&AtClient
Procedure InProcessStatusOnChange(Item)
	
	Attachable_OnAttributeChange(Item);
	
EndProcedure // InProcessStatusOnChange()

// Procedure - event handler OnChange of the CompletedStatus field.
//
&AtClient
Procedure CompletedStatusOnChange(Item)
	
	Attachable_OnAttributeChange(Item);
	
EndProcedure // CompletedStatusOnChange()

&AtClient
Procedure FunctionalOptionPlanCompanyResourcesLoadingWorksOnChange(Item)
	
	Attachable_OnAttributeChange(Item);
	
EndProcedure


















