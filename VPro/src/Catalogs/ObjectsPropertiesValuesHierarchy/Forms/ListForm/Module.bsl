#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.ChoiceMode Then
		StandardSubsystemsServer.SetFormPurposeKey(ThisObject, "PickupSelection");
		WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
	EndIf;
	
	If Parameters.Filter.Property("Owner") Then
		Property = Parameters.Filter.Owner;
		Parameters.Filter.Delete("Owner");
	EndIf;
	
	If Not ValueIsFilled(Property) Then
		Items.Property.Visible = True;
		CustomizeOrderValuesOnProperties(List);
	EndIf;
	
	Items.List.ChoiceMode = Parameters.ChoiceMode;
	
	SetCaption();
	
	OnChangeProperties();
	
	CommonUseClientServer.SetDynamicListParameter(
		List, "IsMainLanguage", CurrentLanguage() = Metadata.DefaultLanguage, True);
	CommonUseClientServer.SetDynamicListParameter(
		List, "LanguageCode", CurrentLanguage().LanguageCode, True);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Src)
	
	If EventName = "Writing_AdditionalAttributesAndInformation"
	   And Src = Property Then
		
		AttachIdleHandler("IdleHandlerOnChangeProperties", 0.1, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region HeaderFormItemsEventsHandlers

&AtClient
Procedure PropertyOnChange(Item)
	
	OnChangeProperties();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventsHandlersList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Group)
	
	If Not Copy
	   And Items.List.Representation = TableRepresentation.List Then
		
		Parent = Undefined;
	EndIf;
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Procedure CustomizeOrderValuesOnProperties(List)
	
	Var Order;
	
	// Порядок.
	Order = List.SettingsComposer.Settings.Order;
	Order.UserSettingID = "DefaultOrder";
	
	Order.Items.Clear();
	
	OrderingItem = Order.Items.Add(Type("DataCompositionOrderItem"));
	OrderingItem.Field = New DataCompositionField("Owner");
	OrderingItem.OrderType = DataCompositionSortDirection.Asc;
	OrderingItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	OrderingItem.Use = True;
	
	OrderingItem = Order.Items.Add(Type("DataCompositionOrderItem"));
	OrderingItem.Field = New DataCompositionField("Description");
	OrderingItem.OrderType = DataCompositionSortDirection.Asc;
	OrderingItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	OrderingItem.Use = True;
	
EndProcedure

&AtServer
Procedure SetCaption()
	
	TitleString = "";
	
	If ValueIsFilled(Property) Then
		If CurrentLanguage() = Metadata.DefaultLanguage Then
			TitleString = CommonUse.ObjectAttributeValue(
				Property, "ValueChoiceFormHeader");
		Else
			Attributes = New Array;
			Attributes.Add("ValueChoiceFormHeader");
			AttributeValues = PropertiesManagementService.LocalizedAttributeValues(Property, Attributes);
			TitleString = AttributeValues.ValueChoiceFormHeader;
		EndIf;
	EndIf;
	
	If IsBlankString(TitleString) Then
		
		If ValueIsFilled(Property) Then
			If Not Parameters.ChoiceMode Then
				TitleString = NStr("en='Значения свойства %1';ru='Значения свойства %1';vi='Giá trị thuộc tính %1'");
			Else
				TitleString = NStr("en='Выберите значение свойства %1';ru='Выберите значение свойства %1';vi='Chọn giá trị thuộc tính %1'");
			EndIf;
			
			TitleString = StringFunctionsClientServer.SubstituteParametersInString(TitleString, String(Property));
		
		ElsIf Parameters.ChoiceMode Then
			TitleString = NStr("en='Выберите значение свойства';ru='Выберите значение свойства';vi='Chọn giá trị thuộc tính'");
		EndIf;
	EndIf;
	
	If Not IsBlankString(TitleString) Then
		AutoTitle = False;
		Title = TitleString;
	EndIf;
	
EndProcedure

&AtClient
Procedure IdleHandlerOnChangeProperties()
	
	OnChangeProperties();
	
EndProcedure

&AtServer
Procedure OnChangeProperties()
	
	If ValueIsFilled(Property) Then
		
		AdditionalValuesOwner = CommonUse.ObjectAttributeValue(
			Property, "AdditionalValuesOwner");
		
		If ValueIsFilled(AdditionalValuesOwner) Then
			ReadOnly = True;
			
			ValueType = CommonUse.ObjectAttributeValue(
				AdditionalValuesOwner, "ValueType");
			
			CommonUseClientServer.SetFilterDynamicListItem(
				List, "Owner", AdditionalValuesOwner);
			
			AdditionalValuesWithWeight = CommonUse.ObjectAttributeValue(
				AdditionalValuesOwner, "AdditionalValuesWithWeight");
		Else
			ReadOnly = False;
			ValueType = CommonUse.ObjectAttributeValue(Property, "ValueType");
			
			CommonUseClientServer.SetFilterDynamicListItem(
				List, "Owner", Property);
			
			AdditionalValuesWithWeight = CommonUse.ObjectAttributeValue(
				Property, "AdditionalValuesWithWeight");
		EndIf;
		
		If TypeOf(ValueType) = Type("TypeDescription")
		   And ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValuesHierarchy")) Then
			
			Items.List.ChangeRowSet = True;
		Else
			Items.List.ChangeRowSet = False;
		EndIf;
		
		Items.List.Representation = TableRepresentation.HierarchicalList;
		Items.Owner.Visible = False;
		Items.Weight.Visible = AdditionalValuesWithWeight;
	Else
		CommonUseClientServer.DeleteGroupsSelectionDynamicListItems(
			List, "Owner");
		
		Items.List.Representation = TableRepresentation.List;
		Items.List.ChangeRowSet = False;
		Items.Owner.Visible = True;
		Items.Weight.Visible = False;
	EndIf;
	
	Items.List.Header = Items.Owner.Visible Or Items.Weight.Visible;
	
EndProcedure

#EndRegion
