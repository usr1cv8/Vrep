
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Not AccessRight("Update", Metadata.InformationRegisters.AdditionalInformation) Then
		Items.FormWrite.Visible = False;
		Items.FormWriteAndClose.Visible = False;
	EndIf;
	
	If Not AccessRight("Update", Metadata.Catalogs.AdditionalAttributesAndInformationSets) Then
		Items.ChangeContentOfAdditionalInformation.Visible = False;
	EndIf;
	
	ObjectReference = Parameters.Ref;
	
	// Getting the list of available properties sets.
	PropertiesSets = PropertiesManagementService.GetObjectPropertiesSets(Parameters.Ref);
	For Each Row In PropertiesSets Do
		AvailableSetsOfProperties.Add(Row.Set);
	EndDo;
	
	// Filling the property values table.
	FillValuesPropertiesTable(True);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New NotifyDescription("WriteAndCloseEnd", ThisObject);
	CommonUseClient.ShowFormClosingConfirmation(Notification, Cancel, Exit);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Writing_AdditionalAttributesAndInformationSets" Then
		
		If AvailableSetsOfProperties.FindByValue(Source) <> Undefined Then
			FillValuesPropertiesTable(False);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventsHandlersPropertyValuesTable

&AtClient
Procedure PropertyValuesTableOnChange(Item)
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure PropertyValuesTableBeforeAddRow(Item, Cancel, Copy, Parent, Group)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure PropertyValuesTableBeforeDeleteRow(Item, Cancel)
	
	If Item.CurrentData.PictureNumber = -1 Then
		Cancel = True;
		Item.CurrentData.Value = Item.CurrentData.ValueType.AdjustValue(Undefined);
		Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure PropertyValuesTableOnStartEdit(Item, NewRow, Copy)
	
	Item.ChildItems.PropertyValuesTableValue.TypeRestriction
		= Item.CurrentData.ValueType;
	
EndProcedure

&AtClient
Procedure PropertyValuesTableBeforeRowChange(Item, Cancel)
	If Items.PropertyValuesTable.CurrentData = Undefined Then
		Return;
	EndIf;
	
	Row = Items.PropertyValuesTable.CurrentData;
	
	ChoiceParametersArray = New Array;
	If Row.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues"))
		Or Row.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValuesHierarchy")) Then
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.Owner",
			?(ValueIsFilled(Row.AdditionalValuesOwner),
				Row.AdditionalValuesOwner, Row.Property)));
	EndIf;
	Items.PropertyValuesTableValue.ChoiceParameters = New FixedArray(ChoiceParametersArray);
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure Write(Command)
	
	WritePropertyValues();
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	
	WriteAndCloseEnd();
	
EndProcedure

&AtClient
Procedure ChangeContentOfAdditionalInformation(Command)
	
	If AvailableSetsOfProperties.Count() = 0
	 OR Not ValueIsFilled(AvailableSetsOfProperties[0].Value) Then
		
		ShowMessageBox(,
			NStr("en='Failed to get the additional information sets of the object."
""
"Perhaps, the necessary attributes have not been filled for the document.';ru='Не удалось получить наборы дополнительных сведений объекта."
""
"Возможно у объекта не заполнены необходимые реквизиты.';vi='Không thể nhận tập hợp mục tin bổ sung của đối tượng."
""
"Có thể, chưa điền mục tin cần thiết cho đối tượng.'"));
	Else
		FormParameters = New Structure;
		FormParameters.Insert("ShowAdditionalInformation");
		
		OpenForm("Catalog.AdditionalAttributesAndInformationSets.ListForm", FormParameters);
		
		ParametersOfTransition = New Structure;
		ParametersOfTransition.Insert("Set", AvailableSetsOfProperties[0].Value);
		ParametersOfTransition.Insert("Property", Undefined);
		ParametersOfTransition.Insert("ThisIsAdditionalInformation", True);
		
		If Items.PropertyValuesTable.CurrentData <> Undefined Then
			ParametersOfTransition.Insert("Set", Items.PropertyValuesTable.CurrentData.Set);
			ParametersOfTransition.Insert("Property", Items.PropertyValuesTable.CurrentData.Property);
		EndIf;
		
		Notify("Transition_SetsOfAdditionalDetailsAndInformation", ParametersOfTransition);
	EndIf;
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtClient
Procedure WriteAndCloseEnd(Result = Undefined, AdditionalParameters = Undefined) Export
	
	WritePropertyValues();
	Modified = False;
	Close();
	
EndProcedure

&AtServer
Procedure FillValuesPropertiesTable(FromHandlerOnCreate)
	
	// Filling the tree with property values.
	If FromHandlerOnCreate Then
		PropertiesValues = ReadPropertiesValuesFromInformationRegister(Parameters.Ref);
	Else
		PropertiesValues = GetCurrentPropertiesValues();
		PropertyValuesTable.Clear();
	EndIf;
	
	CheckedTable = "InformationRegister.AdditionalInformation";
	AccessValue = Type("ChartOfCharacteristicTypesRef.AdditionalAttributesAndInformation");
	
	Table = PropertiesManagementService.PropertiesValues(
		PropertiesValues, AvailableSetsOfProperties, True);
	
	CheckRights = Not Users.InfobaseUserWithFullAccess() And CommonUse.SubsystemExists("StandardSubsystems.AccessManagement");
	If CheckRights Then
		ModuleAccessManagementService = CommonUse.CommonModule("AccessManagementService");
		PropertiesToCheck = Table.UnloadColumn("Property");
		AllowedProperties = ModuleAccessManagementService.РазрешенныеЗначенияДляДинамическогоСписка(
			CheckedTable,
			AccessValue,
			PropertiesToCheck, , True);
	EndIf;
	
	For Each Row In Table Do
		AvailableToChange = True;
		If CheckRights Then
			// Check propery reading.
			If AllowedProperties <> Undefined And AllowedProperties.Find(Row.Property) = Undefined Then
				Continue;
			EndIf;
			
			// Check propery write.
			BeginTransaction();
			Try
				Set = InformationRegisters.AdditionalInformation.CreateRecordSet();
				Set.Filter.Object.Set(Parameters.Ref);
				Set.Filter.Property.Set(Row.Property);
				
				Record = Set.Add();
				Record.Property = Row.Property;
				Record.Object = Parameters.Ref;
				Set.DataExchange.Load = True;
				Set.Write(True);
				
				RollbackTransaction();
			Except
				ErrorInfo = ErrorInfo();
				DetailErrorDescription(ErrorInfo);
				RollbackTransaction();
				AvailableToChange = False;
			EndTry;
		EndIf;
		
		NewRow = PropertyValuesTable.Add();
		FillPropertyValues(NewRow, Row);
		
		NewRow.PictureNumber = ?(Row.Deleted, 0, -1);
		NewRow.AvailableToChange = AvailableToChange;
		
		If Row.Value = Undefined
			And CommonUse.TypeDescriptionFullConsistsOfType(Row.ValueType, Type("Boolean")) Then
			NewRow.Value = False;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure WritePropertyValues()
	
	// Writing the property values to the information register.
	PropertiesValues = New Array;
	
	For Each Row In PropertyValuesTable Do
		Value = New Structure("Property, Value", Row.Property, Row.Value);
		PropertiesValues.Add(Value);
	EndDo;
	
	If PropertiesValues.Count() > 0 Then
		WriteSetPropertiesToRegister(ObjectReference, PropertiesValues);
	EndIf;
	
	Modified = False;
	
EndProcedure

&AtServerNoContext
Procedure WriteSetPropertiesToRegister(Val Ref, Val PropertiesValues)
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.AdditionalInformation");
		LockItem.SetValue("Object", Ref);
		Block.Lock();
		
		Set = InformationRegisters.AdditionalInformation.CreateRecordSet();
		Set.Filter.Object.Set(Ref);
		Set.Read();
		CurrentValues = Set.Unload();
		For Each Row In PropertiesValues Do
			Record = CurrentValues.Find(Row.Property, "Property");
			If Record = Undefined Then
				Record = CurrentValues.Add();
				Record.Property = Row.Property;
				Record.Value = Row.Value;
				Record.Object   = Ref;
			EndIf;
			Record.Value = Row.Value;
			
			If Not ValueIsFilled(Record.Value)
				Or Record.Value = False Then
				CurrentValues.Delete(Record);
			EndIf;
		EndDo;
		Set.Load(CurrentValues);
		Set.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
	EndTry;
	
EndProcedure

&AtServerNoContext
Function ReadPropertiesValuesFromInformationRegister(Ref)
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	AdditionalInformation.Property,
	|	AdditionalInformation.Value
	|FROM
	|	InformationRegister.AdditionalInformation AS AdditionalInformation
	|WHERE
	|	AdditionalInformation.Object = &Object";
	Query.SetParameter("Object", Ref);
	
	Return Query.Execute().Unload();
	
EndFunction

&AtServer
Function GetCurrentPropertiesValues()
	
	PropertiesValues = New ValueTable;
	PropertiesValues.Columns.Add("Property");
	PropertiesValues.Columns.Add("Value");
	
	For Each Row In PropertyValuesTable Do
		
		If ValueIsFilled(Row.Value) And (Row.Value <> False) Then
			NewRow = PropertiesValues.Add();
			NewRow.Property = Row.Property;
			NewRow.Value = Row.Value;
		EndIf;
	EndDo;
	
	Return PropertiesValues;
	
EndFunction

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PropertyValuesTableValue.Name);
	
	// Date format - time.
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PropertyValuesTable.ValueType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New TypeDescription("Date",,, New DateQualifiers(DateFractions.Time));
	Item.Appearance.SetParameterValue("Format", "DLF=T");
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PropertyValuesTableValue.Name);
	
	// Date format - date.
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PropertyValuesTable.ValueType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New TypeDescription("Date",,, New DateQualifiers(DateFractions.Date));
	Item.Appearance.SetParameterValue("Format", "DLF=D");
	
	//
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PropertyValuesTableValue.Name);
	
	// Availability of field, if no rights for changing.
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PropertyValuesTable.AvailableToChange");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableCellTextColor);
	
EndProcedure

#EndRegion
