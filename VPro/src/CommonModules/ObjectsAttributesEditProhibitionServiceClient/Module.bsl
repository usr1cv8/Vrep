////////////////////////////////////////////////////////////////////////////////
// Subsystem "Prohibition of object attributes editing"
// 
////////////////////////////////////////////////////////////////////////////////

#Region ServiceProceduresAndFunctions

Procedure AuthorizeObjectAttributesEditingAfterDoMessageBox(ContinuationProcessor) Export
	
	If ContinuationProcessor <> Undefined Then
		ExecuteNotifyProcessing(ContinuationProcessor, False);
	EndIf;
	
EndProcedure

Procedure AuthorizeObjectAttributesEditingAfterRefsCheck(Result, Parameters) Export
	
	If Result Then
		ObjectsAttributesEditProhibitionClient.SetAllowingAttributesEditing(
			Parameters.Form, Parameters.BlockedAttributes);
		
		ObjectsAttributesEditProhibitionClient.SetEnabledOfFormItems(Parameters.Form);
	EndIf;
	
	If Parameters.ContinuationProcessor <> Undefined Then
		ExecuteNotifyProcessing(Parameters.ContinuationProcessor, Result);
	EndIf;
	
EndProcedure

Procedure CheckReferencesToObjectAfterCheckConfirmation(Response, Parameters) Export
	
	If Response <> DialogReturnCode.Yes Then
		ExecuteNotifyProcessing(Parameters.ContinuationProcessor, False);
		Return;
	EndIf;
		
	If Parameters.RefArray.Count() = 0 Then
		ExecuteNotifyProcessing(Parameters.ContinuationProcessor, True);
		Return;
	EndIf;
	
	If CommonUseServerCall.ThereAreRefsToObject(Parameters.RefArray) Then
		
		If Parameters.RefArray.Count() = 1 Then
			MessageText = NStr("en='Item ""%1"" is already used in other places in the application."
"It is not recommended to allow editing due to the risk of data misalignment.';ru='Элемент ""%1"" уже используется в других местах в программе."
"Не рекомендуется разрешать редактирование из-за риска рассогласования данных.';vi='Phần tử ""%1"" đã được sử dụng ở những chỗ khác trong chương trình."
"Không nên cho phép soạn do rủi ro không đồng nhất dữ liệu.'");
			MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText, Parameters.RefArray[0]);
		Else
			MessageText = NStr("en='Selected items (%1) are already used in other places in the application."
"It is not recommended to allow editing due to the risk of data misalignment.';ru='Выбранные элементы (%1) уже используются в других местах в программе."
"Не рекомендуется разрешать редактирование из-за риска рассогласования данных.';vi='Phần tử đã chọn (%1) đã được sử dụng tại các chỗ khác trong chương trình."
"Không nên cho phép soạn do rủi ro thống nhất dữ liệu.'");
			MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText, Parameters.RefArray.Count());
		EndIf;
		
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("en='Enable editing';ru='Разрешить редактирование';vi='Cho phép soạn'"));
		Buttons.Add(DialogReturnCode.No, NStr("en='Cancel';ru='Отменить';vi='Hủy bỏ'"));
		ShowQueryBox(
			New NotifyDescription(
				"CheckReferencesToObjectAfterEditConfirmation", ThisObject, Parameters),
			MessageText, Buttons, , DialogReturnCode.No, Parameters.DialogTitle);
	Else
		If Parameters.RefArray.Count() = 1 Then
			ShowUserNotification(NStr("en='Attribute editing is allowed';ru='Редактирование реквизитов разрешено';vi='Cho phép soạn các mục tin'"),
				GetURL(Parameters.RefArray[0]), Parameters.RefArray[0]);
		Else
			MessageText = StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en='Editing object attributes is allowed (%1)';ru='Разрешено редактирование реквизитов объектов (%1)';vi='Cho phép soạn các mục tin đối tượng (%1)'"), Parameters.RefArray.Count());
			ShowUserNotification(NStr("en='Attribute editing is allowed';ru='Редактирование реквизитов разрешено';vi='Cho phép soạn các mục tin'"),, MessageText);
		EndIf;
		ExecuteNotifyProcessing(Parameters.ContinuationProcessor, True);
	EndIf;
	
EndProcedure

Procedure CheckReferencesToObjectAfterEditConfirmation(Response, Parameters) Export
	
	ExecuteNotifyProcessing(Parameters.ContinuationProcessor, Response = DialogReturnCode.Yes);
	
EndProcedure

#EndRegion
