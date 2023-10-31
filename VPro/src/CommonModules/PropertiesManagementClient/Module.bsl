
#Region ProgramInterface

// Определяет, что указанное событие - это событие об изменении набора свойств.
//
// Parameters:
//  Form      - ClientApplicationForm - форма, в которой была вызвана обработка оповещения.
//  EventName - String           - имя обрабатываемого события.
//  Parameter   - Arbitrary     - параметры, переданные в событии.
//
// Returns:
//  Boolean - если True, тогда это оповещение об изменении набора свойств и
//           его нужно обработать в форме.
//
Function ProcessAlerts(Form, EventName, Parameter) Export
	
	If Not Form.Properties_UseProperties
	 Or Not Form.Properties_UseAdditionalAttributes Then
		
		Return False;
	EndIf;
	
	If EventName = "Writing_AdditionalAttributesAndInformationSets" Then
		If Not Parameter.Property("Ref") Then
			Return True;
		Else
			Return Form.Properties_AdditionalObjectAttributesSets.FindByValue(Parameter.Ref) <> Undefined;
		EndIf;
		
	ElsIf EventName = "Writing_AdditionalAttributesAndInformation" Then
		
		If Form.ProperyParameters.Property("ExecutedDeferredInitialization")
			And Not Form.ProperyParameters.ExecutedDeferredInitialization
			Or Not Parameter.Property("Ref") Then
			Return True;
		Else
			Filter = New Structure("Property", Parameter.Ref);
			Return Form.Properties_AdditionalAttributesDescription.FindRows(Filter).Count() > 0;
		EndIf;
	EndIf;
	
	Return False;
	
EndFunction

// Обновляет видимость, доступность и обязательность заполнения
// дополнительных реквизитов.
//
// Parameters:
//  Form  - ClientApplicationForm     - обрабатываемая форма.
//  Object - FormDataStructure - описание объекта, к которому подключены свойства,
//                                  если свойство не указано или Неопределено, то
//                                  объект будет взят из реквизита формы "Объект".
//
Procedure UpdateAdditionalAttributesDependencies(Form, Object = Undefined) Export
	
	If Not Form.Properties_UseProperties
	 Or Not Form.Properties_UseAdditionalAttributes Then
		
		Return;
	EndIf;
	
	If Form.Properties_DependentAdditionalAttributesDescription.Count() = 0 Then
		Return;
	EndIf;
	
	If Object = Undefined Then
		ObjectDescription = Form.Object;
	Else
		ObjectDescription = Object;
	EndIf;
	
	For Each DependentAttributeDescription In Form.Properties_DependentAdditionalAttributesDescription Do
		If DependentAttributeDescription.DisplayAsHyperlink Then
			ProcessedItem = StrReplace(DependentAttributeDescription.AttributeNameValue, "AdditionalAttributeValue_", "Group_");
		Else
			ProcessedItem = DependentAttributeDescription.AttributeNameValue;
		EndIf;
		
		If DependentAttributeDescription.AccessibilityCondition <> Undefined Then
			Parameters = New Structure;
			Parameters.Insert("ParameterValues", DependentAttributeDescription.AccessibilityCondition.ParameterValues);
			Parameters.Insert("Form", Form);
			Parameters.Insert("ObjectDescription", ObjectDescription);
			Result = Eval(DependentAttributeDescription.AccessibilityCondition.ConditionCode);
			
			Item = Form.Items[ProcessedItem];
			If Item.Enabled <> Result Then
				Item.Enabled = Result;
			EndIf;
		EndIf;
		If DependentAttributeDescription.VisibilityCondition <> Undefined Then
			Parameters = New Structure;
			Parameters.Insert("ParameterValues", DependentAttributeDescription.VisibilityCondition.ParameterValues);
			Parameters.Insert("Form", Form);
			Parameters.Insert("ObjectDescription", ObjectDescription);
			Result = Eval(DependentAttributeDescription.VisibilityCondition.ConditionCode);
			
			Item = Form.Items[ProcessedItem];
			If Item.Visible <> Result Then
				Item.Visible = Result;
			EndIf;
		EndIf;
		If DependentAttributeDescription.RequiredFillingCondition <> Undefined Then
			If Not DependentAttributeDescription.FillObligatory Then
				Continue;
			EndIf;
			
			Parameters = New Structure;
			Parameters.Insert("ParameterValues", DependentAttributeDescription.RequiredFillingCondition.ParameterValues);
			Parameters.Insert("Form", Form);
			Parameters.Insert("ObjectDescription", ObjectDescription);
			Result = Eval(DependentAttributeDescription.RequiredFillingCondition.ConditionCode);
			
			Item = Form.Items[ProcessedItem];
			If Not DependentAttributeDescription.DisplayAsHyperlink
				And Item.AutoMarkIncomplete <> Result Then
				Item.AutoMarkIncomplete = Result;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Проверяет наличие зависимых дополнительных реквизитов на форме
// и при необходимости подключает обработчик ожидания проверки зависимостей реквизитов.
//
// Parameters:
//  Form - ClientApplicationForm - проверяемая форма.
//
Procedure AfterLoadAdditionalAttributes(Form) Export
	
	If Not Form.Properties_UseProperties
		Or Not Form.Properties_UseAdditionalAttributes Then
		
		Return;
	EndIf;
	
	Form.AttachIdleHandler("UpdateAdditionalAttributesDependencies", 2);
	
EndProcedure

// Обработчик команд с форм, к которым подключены дополнительные свойства.
// 
// Parameters:
//  Form                - ClientApplicationForm - форма с дополнительными реквизитами, предварительно
//                          настроенная в процедуре УправлениеСвойствами.ПриСозданииНаСервере().
//  Item              - FormField, FormCommand - элемент, нажатие которого необходимо обработать.
//  StandardProcessing - Boolean - возвращаемый параметр, если необходимо выполнить интерактивные
//                          действия с пользователем, то устанавливается в значение False.
//
Procedure ExecuteCommand(Form, Item  = Undefined, StandardProcessing  = Undefined) Export
	
	If Item = Undefined Then
		CommandName = "EditAdditionalAttributesContent";
	ElsIf TypeOf(Item) = Type("FormCommand") Then
		CommandName = Item.Name;
	Else
		ValueOfAttribute = Form[Item.Name];
		If Not ValueIsFilled(ValueOfAttribute) Then
			EditAttributeHyperlink(Form, True, Item);
			StandardProcessing = False;
		EndIf;
		Return;
	EndIf;
	
	If CommandName = "EditAdditionalAttributesContent" Then
		EditContentOfProperties(Form);
	ElsIf CommandName = "EditAttributeHyperlink" Then
		EditAttributeHyperlink(Form);
	EndIf;
EndProcedure

#EndRegion

#Region ServiceProgramInterface

Procedure OpenPropertyList(AdditionalAttributes = False) Export
	
	FormParameters = New Structure;
	If AdditionalAttributes Then
		FormParameters.Insert("ShowAdditionalAttributes");
	Else
		FormParameters.Insert("ShowAdditionalInformation");
	EndIf;
	OpenForm("Catalog.AdditionalAttributesAndInformationSets.ListForm",
		FormParameters, , ?(AdditionalAttributes, "AdditionalAttributes", "AdditionalInformation"));
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

// Opens the form for editing the additional attributes.
//
// Parameters:
//  Form - ClientApplicationForm - форма, из которой осуществляется вызов метода.
//
Procedure EditContentOfProperties(Form)
	
	Sets = Form.Properties_AdditionalObjectAttributesSets;
	
	If Sets.Count() = 0
	 OR Not ValueIsFilled(Sets[0].Value) Then
		
		ShowMessageBox(,
			NStr("en='Failed to receive the additional object attributes."
""
"Perhaps, the necessary attributes have not been filled for the document.';ru='Не удалось получить наборы дополнительных реквизитов объекта."
""
"Возможно у объекта не заполнены необходимые реквизиты.';vi='Không thể nhận tập hợp mục tin bổ sung của đối tượng."
""
"Có thể, chưa điền mục tin cần thiết cho đối tượng.'"));
	
	Else
		FormParameters = New Structure;
		FormParameters.Insert("ShowAdditionalAttributes");
		
		OpenForm("Catalog.AdditionalAttributesAndInformationSets.ListForm", FormParameters);
		
		ParametersOfTransition = New Structure;
		ParametersOfTransition.Insert("Set", Sets[0].Value);
		ParametersOfTransition.Insert("Property", Undefined);
		ParametersOfTransition.Insert("ThisIsAdditionalInformation", False);
		
		LengthBeginning = StrLen("AdditionalAttributeValue_");
		IsFormField = (TypeOf(Form.CurrentItem) = Type("FormField"));
		If IsFormField And Upper(Left(Form.CurrentItem.Name, LengthBeginning)) = Upper("AdditionalAttributeValue_") Then
			
			IDSet   = StrReplace(Mid(Form.CurrentItem.Name, LengthBeginning +  1, 36), "x","-");
			PropertyID = StrReplace(Mid(Form.CurrentItem.Name, LengthBeginning + 38, 36), "x","-");
			
			If StringFunctionsClientServer.ThisIsUUID(Lower(IDSet)) Then
				ParametersOfTransition.Insert("Set", IDSet);
			EndIf;
			
			If StringFunctionsClientServer.ThisIsUUID(Lower(PropertyID)) Then
				ParametersOfTransition.Insert("Property", PropertyID);
			EndIf;
		EndIf;
		
		Notify("Transition_SetsOfAdditionalDetailsAndInformation", ParametersOfTransition);
	EndIf;
	
EndProcedure

Procedure EditAttributeHyperlink(Form, HyperlinkTransition = False, Item = Undefined)
	If Not HyperlinkTransition Then
		ButtonName = Form.CurrentItem.Name;
		UniquePart = StrReplace(ButtonName, "Button_", "");
		AttributeName = "AdditionalAttributeValue_" + UniquePart;
	Else
		AttributeName = Item.Name;
		UniquePart = StrReplace(AttributeName, "AdditionalAttributeValue_", "");
	EndIf;
	
	FilterParameters = New Structure;
	FilterParameters.Insert("AttributeNameValue", AttributeName);
	
	AttributesDescription = Form.Properties_AdditionalAttributesDescription.FindRows(FilterParameters);
	If AttributesDescription.Count() <> 1 Then
		Return;
	EndIf;
	AttributeFullName = AttributesDescription[0];
	
	If Not AttributeFullName.ReferenceTypeRow Then
		If Form.Items[AttributeName].Type = FormFieldType.InputField Then
			Form.Items[AttributeName].Type = FormFieldType.LabelField;
			Form.Items[AttributeName].Hyperlink = True;
		Else
			Form.Items[AttributeName].Type = FormFieldType.InputField;
			If AttributeFullName.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues"))
				Or AttributeFullName.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValuesHierarchy")) Then
				ChoiceParameter = ?(ValueIsFilled(AttributeFullName.AdditionalValuesOwner),
					AttributeFullName.AdditionalValuesOwner, AttributeFullName.Property);
				ChoiceParametersArray = New Array;
				ChoiceParametersArray.Add(New ChoiceParameter("Filter.Owner", ChoiceParameter));
				
				Form.Items[AttributeName].ChoiceParameters = New FixedArray(ChoiceParametersArray);
			EndIf;
		EndIf;
		
		Return;
	EndIf;
	
	OpenParameters = New Structure;
	OpenParameters.Insert("AttributeName", AttributeName);
	OpenParameters.Insert("ValueType", AttributeFullName.ValueType);
	OpenParameters.Insert("DescriptionAttribute", AttributeFullName.Description);
	OpenParameters.Insert("ReferenceTypeRow", AttributeFullName.ReferenceTypeRow);
	OpenParameters.Insert("ValueOfAttribute", Form[AttributeName]);
	OpenParameters.Insert("ReadOnly", Form.ReadOnly);
	If AttributeFullName.ReferenceTypeRow Then
		OpenParameters.Insert("RefAttributeName", "ReferenceAdditionalAttributeValue_" + UniquePart);
	Else
		OpenParameters.Insert("Property", AttributeFullName.Property);
		OpenParameters.Insert("AdditionalValuesOwner", AttributeFullName.AdditionalValuesOwner);
	EndIf;
	NotifyDescription = New NotifyDescription("EditAttributeHyperlinkEnd", PropertiesManagementClient, Form);
	OpenForm("CommonForm.EditHyperlink", OpenParameters,,,,, NotifyDescription);
EndProcedure

Procedure EditAttributeHyperlinkEnd(Result, AdditionalParameters) Export
	If TypeOf(Result) <> Type("Structure") Then
		Return;
	EndIf;
	
	Form = AdditionalParameters;
	Form[Result.AttributeName] = Result.Value;
	If Result.ReferenceTypeRow Then
		Form[Result.RefAttributeName] = Result.FormattedString;
	EndIf;
	Form.Modified = True;
EndProcedure

#EndRegion