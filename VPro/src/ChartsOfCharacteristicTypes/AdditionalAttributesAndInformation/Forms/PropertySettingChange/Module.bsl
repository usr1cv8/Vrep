
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.ThisIsAdditionalInformation Then
		Items.TypesProperties.CurrentPage = Items.AdditionalInformation;
		Title = NStr("en='Change additional information settings';ru='Изменить настройку дополнительного сведения';vi='Thay đổi tùy chỉnh thông tin bổ sung'");
	Else
		Items.TypesProperties.CurrentPage = Items.AdditionalAttribute;
	EndIf;
	
	If ValueIsFilled(Parameters.AdditionalValuesOwner) Then
		Items.AttributeKinds.CurrentPage = Items.KindCommonAttributesValues;
		Items.KindsOfInformation.CurrentPage  = Items.KindGeneralInformationValues;
		SinglePropertyWithCommonListOfValues = 1;
	Else
		Items.AttributeKinds.CurrentPage = Items.CommonAttributeKind;
		Items.KindsOfInformation.CurrentPage  = Items.CommonInformationKind;
		CommonProperty = 1;
	EndIf;
	
	Property = Parameters.Property;
	CurrentSetOfProperties = Parameters.CurrentSetOfProperties;
	ThisIsAdditionalInformation = Parameters.ThisIsAdditionalInformation;
	
	Items.IndividualValuesAttributeComment.Title =
		StringFunctionsClientServer.SubstituteParametersInString(
			Items.IndividualValuesAttributeComment.Title, CurrentSetOfProperties);
	
	Items.CommonAttributesValuesComment.Title =
		StringFunctionsClientServer.SubstituteParametersInString(
			Items.CommonAttributesValuesComment.Title, CurrentSetOfProperties);
	
	Items.SeparateDataValuesComment.Title =
		StringFunctionsClientServer.SubstituteParametersInString(
			Items.SeparateDataValuesComment.Title, CurrentSetOfProperties);
	
	Items.GeneralInformationValuesComment.Title =
		StringFunctionsClientServer.SubstituteParametersInString(
			Items.GeneralInformationValuesComment.Title, CurrentSetOfProperties);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New NotifyDescription("WriteAndCloseEnd", ThisObject);
	CommonUseClient.ShowFormClosingConfirmation(Notification, Cancel, Exit);
	
EndProcedure

#EndRegion

#Region HeaderFormItemsEventsHandlers

&AtClient
Procedure KindOnChange(Item)
	
	KindAtServerOnChange(Item.Name);
	
EndProcedure

&AtServer
Procedure KindAtServerOnChange(ItemName)
	
	SinglePropertyWithCommonListOfValues = 0;
	SeparatePropertyWithSeparateValuesList = 0;
	CommonProperty = 0;
	
	ThisObject[Items[ItemName].DataPath] = 1;
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure WriteAndClose(Command)
	
	WriteAndCloseEnd();
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtClient
Procedure WriteAndCloseEnd(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If SeparatePropertyWithSeparateValuesList = 1 Then
		WriteBegin();
	Else
		WriteCompletion(Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteBegin()
	
	ExecutionResult = WriteAtServer();
	
	If ExecutionResult.Status = "Completed" Then
		OpenProperty = GetFromTempStorage(ExecutionResult.ResultAddress);
		WriteCompletion(OpenProperty);
	Else
		WaitingParameters = LongActionsClient.WaitingParameters(ThisObject);
		CompletionNotification = New NotifyDescription("WriteContinue", ThisObject);
		
		LongActionsClient.WaitForCompletion(ExecutionResult, CompletionNotification, WaitingParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteContinue(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	OpenProperty = GetFromTempStorage(Result.ResultAddress);
	
	WriteCompletion(OpenProperty);
EndProcedure

&AtClient
Procedure WriteCompletion(OpenProperty)
	
	Modified = False;
	
	Notify("Writing_AdditionalAttributesAndInformation",
		New Structure("Ref", Property), Property);
	
	Notify("Writing_AdditionalAttributesAndInformationSets",
		New Structure("Ref", CurrentSetOfProperties), CurrentSetOfProperties);
	
	NotifyChoice(OpenProperty);
	
EndProcedure

&AtServer
Function WriteAtServer()
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("Property", Property);
	ProcedureParameters.Insert("CurrentSetOfProperties", CurrentSetOfProperties);
	
	JobDescription = NStr("en='Change additional property setting';ru='Изменение настройки дополнительного свойства';vi='Thay đổi tùy chỉnh thuộc tính bổ sung'");
	ExecuteParameters = LongActions.BackgroundExecutionParameters(UUID);
	ExecuteParameters.WaitForCompletion = 2;
	ExecuteParameters.BackgroundJobDescription = JobDescription;
	
	Result = LongActions.ExecuteInBackground("ChartsOfCharacteristicTypes.AdditionalAttributesAndInformation.ChangePropertiesConfiguration",
		ProcedureParameters, ExecuteParameters);
	
	Return Result;
	
EndFunction

#EndRegion
