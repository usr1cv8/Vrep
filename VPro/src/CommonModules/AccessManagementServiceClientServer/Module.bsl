////////////////////////////////////////////////////////////////////////////////
// Subsystem "Access management".
// 
////////////////////////////////////////////////////////////////////////////////

#Region ServiceProgramInterface

////////////////////////////////////////////////////////////////////////////////
// Servicing of tables AccessKinds and AccessValues in edit forms.

// Only for internal use.
Procedure FillInAllAllowedPresentation(Form, AccessTypeDescription, AddValuesNumber = True) Export
	
	Parameters = AllowedValuesEditFormParameters(Form);
	
	If AccessTypeDescription.AllAllowed Then
		If Form.ThisIsAccessGroupsProfile AND Not AccessTypeDescription.Preset Then
			Name = "InitiallyAllAllowed";
		Else
			Name = "AllAllowed";
		EndIf;
	Else
		If Form.ThisIsAccessGroupsProfile AND Not AccessTypeDescription.Preset Then
			Name = "InitiallyAllProhibited";
		Else
			Name = "AllProhibited";
		EndIf;
	EndIf;
	
	AccessTypeDescription.AllAllowedPresentation =
		Form.PresentationsAllAllowed.FindRows(New Structure("Name", Name))[0].Presentation;
	
	If Not AddValuesNumber Then
		Return;
	EndIf;
	
	If Form.ThisIsAccessGroupsProfile AND Not AccessTypeDescription.Preset Then
		Return;
	EndIf;
	
	Filter = FilterInAllowedValuesEditFormTables(Form, AccessTypeDescription.AccessKind);
	
	ValueCount = Parameters.AccessValues.FindRows(Filter).Count();
	
	If Form.ThisIsAccessGroupsProfile Then
		If ValueCount = 0 Then
			NumberAndSubject = NStr("en='not assigned';ru='не назначены';vi='chưa ấn định'");
		Else
			NumberInWords          = NumberInWords(
				ValueCount,
				"L=en_US",
				NStr("en=',,,,,,,,0';ru=',,,,,,,,0';vi=',,,,,,,,0'"));
			
			SubjectAndNumberInWords = NumberInWords(
				ValueCount,
				"L=en_US",
				NStr("en='value, values, values,,,,,,0';ru='-го значения,-х значений,-и значений,,,,,,0';vi='giá trị thứ nhất,giá trị thứ hai, giá trị thứ n,,,,,,0'"));
			
			NumberAndSubject = StrReplace(
				SubjectAndNumberInWords,
				NumberInWords,
				Format(ValueCount, "NG=") + " ");
		EndIf;
		
		AccessTypeDescription.AllAllowedPresentation =
			AccessTypeDescription.AllAllowedPresentation
				+ " (" + NumberAndSubject + ")";
		Return;
	EndIf;
	
	If ValueCount = 0 Then
		Presentation = ?(AccessTypeDescription.AllAllowed,
			NStr("en='All permitted without exceptions';ru='Все разрешены, без исключений';vi='Cho phép tất cả, không có ngoại lệ'"),
			NStr("en='All prohibited without exceptions';ru='Все запрещены, без исключений';vi='Cấm tất cả, không có ngoại lệ'"));
	Else
		NumberInWords = NumberInWords(
			ValueCount,
			"L=en_US",
			NStr("en=',,,,,,,,0';ru=',,,,,,,,0';vi=',,,,,,,,0'"));
		
		SubjectAndNumberInWords = NumberInWords(
			ValueCount,
			"L=en_US",
			NStr("en='value, values, values,,,,,,0';ru='значение,значения,значений,,,,,,0';vi='giá trị,giá trị,giá trị,,,,,,0'"));
		
		NumberAndSubject = StrReplace(
			SubjectAndNumberInWords,
			NumberInWords,
			Format(ValueCount, "NG="));
		
		Presentation = StringFunctionsClientServer.SubstituteParametersInString(
			?(AccessTypeDescription.AllAllowed,
				NStr("en='All permitted except for %1';ru='Все разрешены, кроме %1';vi='Cho phép tất cả, ngoại trừ %1'"),
				NStr("en='All prohibited except for %1';ru='Все запрещены, кроме %1';vi='Cấm tất cả, ngoại trừ %1'")),
			NumberAndSubject);
	EndIf;
	
	AccessTypeDescription.AllAllowedPresentation = Presentation;
	
EndProcedure

// Only for internal use.
Procedure FillInAccessValuesByKindLineNumbers(Form, AccessTypeDescription) Export
	
	Parameters = AllowedValuesEditFormParameters(Form);
	
	Filter = FilterInAllowedValuesEditFormTables(Form, AccessTypeDescription.AccessKind);
	AccessValuesByKind = Parameters.AccessValues.FindRows(Filter);
	
	CurrentNumber = 1;
	For Each String IN AccessValuesByKind Do
		String.LineNumberByKind = CurrentNumber;
		CurrentNumber = CurrentNumber + 1;
	EndDo;
	
EndProcedure

// Only for internal use.
Procedure OnChangeCurrentAccessKind(Form) Export
	
	Items = Form.Items;
	Parameters = AllowedValuesEditFormParameters(Form);
	
	ValuesAreEditable = False;
	
	#If Client Then
		CurrentData = Items.AccessKinds.CurrentData;
	#Else
		CurrentData = Parameters.AccessKinds.FindByID(
			?(Items.AccessKinds.CurrentRow = Undefined,
			  -1,
			  Items.AccessKinds.CurrentRow));
	#EndIf
	
	If CurrentData <> Undefined Then
		
		If CurrentData.AccessKind <> Undefined
		   AND Not CurrentData.Used Then
			
			If Not Items.TextAccessKindNotUsed.Visible Then
				Items.TextAccessKindNotUsed.Visible = True;
			EndIf;
		Else
			If Items.TextAccessKindNotUsed.Visible Then
				Items.TextAccessKindNotUsed.Visible = False;
			EndIf;
		EndIf;
		
		Form.CurrentAccessType = CurrentData.AccessKind;
		
		If Not Form.ThisIsAccessGroupsProfile OR CurrentData.Preset Then
			ValuesAreEditable = True;
		EndIf;
		
		If ValuesAreEditable Then
			
			If Form.ThisIsAccessGroupsProfile Then
				Items.AccessKindTypes.CurrentPage = Items.PresetAccessKind;
			EndIf;
			
			// Values selection setting.
			UpdateStringsFilter = False;
			RowFilter = Items.AccessValues.RowFilter;
			Filter = FilterInAllowedValuesEditFormTables(Form, CurrentData.AccessKind);
			
			If RowFilter = Undefined Then
				UpdateStringsFilter = True;
				
			ElsIf Filter.Property("AccessGroup") AND RowFilter.AccessGroup <> Filter.AccessGroup Then
				UpdateStringsFilter = True;
				
			ElsIf RowFilter.AccessKind <> Filter.AccessKind
			        AND Not (RowFilter.AccessKind = "" AND Filter.AccessKind = Undefined) Then
				
				UpdateStringsFilter = True;
			EndIf;
			
			If UpdateStringsFilter Then
				If CurrentData.AccessKind = Undefined Then
					Filter.AccessKind = "";
				EndIf;
				Items.AccessValues.RowFilter = New FixedStructure(Filter);
			EndIf;
			
		ElsIf Form.ThisIsAccessGroupsProfile Then
			Items.AccessKindTypes.CurrentPage = Items.NormalAccessType;
		EndIf;
		
		If CurrentData.AccessKind = Form.AccessTypeUsers Then
			PatternLabel = ?(CurrentData.AllAllowed,
				NStr("en='Prohibited values (%1) - the current user is always allowed';ru='Запрещенные значения (%1) - текущий пользователь всегда разрешен';vi='Giá trị bị cấm (%1) - người sử dụng hiện tại luôn được phép'"),
				NStr("en='Allowed values (%1) - the current user is always allowed';ru='Разрешенные значения (%1) - текущий пользователь всегда разрешен';vi='Giá trị được phép (%1) - người sử dụng hiện tại luôn được phép'") );
		
		ElsIf CurrentData.AccessKind = Form.AccessKindExternalUsers Then
			PatternLabel = ?(CurrentData.AllAllowed,
				NStr("en='Prohibited values (%1) - the current external user is always allowed';ru='Запрещенные значения (%1) - текущий внешний пользователь всегда разрешен';vi='Giá trị bị cấm (%1) - người sử dụng ngoài hiện tại luôn cho phép'"),
				NStr("en='Allowed values (%1) - the current external user is always allowed';ru='Разрешенные значения (%1) - текущий внешний пользователь всегда разрешен';vi='Giá trị được phép (%1) - người sử dụng ngoài hiện tại luôn được phép'") );
		Else
			PatternLabel = ?(CurrentData.AllAllowed,
				NStr("en='Prohibited values (%1)';ru='Запрещенные значения (%1)';vi='Giá trị bị cấm (%1)'"),
				NStr("en='Allowed values (%1)';ru='Разрешенные значения (%1)';vi='Giá trị được phép (%1)'") );
		EndIf;
		
		// Update of the field LabelAccessKind.
		Form.AccessTypeLabel = StringFunctionsClientServer.SubstituteParametersInString(
			PatternLabel, String(CurrentData.AccessKindPresentation));
		
		FillInAllAllowedPresentation(Form, CurrentData);
	Else
		If Items.TextAccessKindNotUsed.Visible Then
			Items.TextAccessKindNotUsed.Visible = False;
		EndIf;
		
		Form.CurrentAccessType = Undefined;
		Items.AccessValues.RowFilter = New FixedStructure(
			FilterInAllowedValuesEditFormTables(Form, Undefined));
		
		If Parameters.AccessKinds.Count() = 0 Then
			Parameters.AccessValues.Clear();
		EndIf;
	EndIf;
	
	Form.SelectedValuesCurrentType  = Undefined;
	Form.SelectedValuesCurrentTypes = New ValueList;
	
	If ValuesAreEditable Then
		Filter = New Structure("AccessKind", CurrentData.AccessKind);
		DescriptionTypesKindsAccess = Form.AllSelectedValuesTypes.FindRows(Filter);
		For Each AccessTypeTypeDescription IN DescriptionTypesKindsAccess Do
			
			Form.SelectedValuesCurrentTypes.Add(
				AccessTypeTypeDescription.ValuesType,
				AccessTypeTypeDescription.TypePresentation);
		EndDo;
	Else
		If CurrentData <> Undefined Then
			
			Filter = FilterInAllowedValuesEditFormTables(
				Form, CurrentData.AccessKind);
			
			For Each String IN Parameters.AccessValues.FindRows(Filter) Do
				Parameters.AccessValues.Delete(String);
			EndDo
		EndIf;
	EndIf;
	
	If Form.SelectedValuesCurrentTypes.Count() = 0 Then
		Form.SelectedValuesCurrentTypes.Add(Undefined, NStr("en='Undefined';ru='Неопределено';vi='Không xác định'"));
	EndIf;
	
	Items.AccessValues.Enabled = ValuesAreEditable;
	
EndProcedure

// Only for internal use.
Function AllowedValuesEditFormParameters(Form, CurrentObject = Undefined) Export
	
	Parameters = New Structure;
	Parameters.Insert("PathToTables", "");
	
	If CurrentObject <> Undefined Then
		TablesStorage = CurrentObject;
		
	ElsIf ValueIsFilled(Form.TablesStorageAttributeName) Then
		Parameters.Insert("PathToTables", Form.TablesStorageAttributeName + ".");
		TablesStorage = Form[Form.TablesStorageAttributeName];
	Else
		TablesStorage = Form;
	EndIf;
	
	Parameters.Insert("AccessKinds",     TablesStorage.AccessKinds);
	Parameters.Insert("AccessValues", TablesStorage.AccessValues);
	
	Return Parameters;
	
EndFunction

// Only for internal use.
Function FilterInAllowedValuesEditFormTables(Form, AccessKind = "WithoutFilterByAccessKind") Export
	
	Filter = New Structure;
	
	Structure = New Structure("CurrentAccessGroup", "AttributeDoesNotExist");
	FillPropertyValues(Structure, Form);
	
	If Structure.CurrentAccessGroup <> "AttributeDoesNotExist" Then
		Filter.Insert("AccessGroup", Structure.CurrentAccessGroup);
	EndIf;
	
	If AccessKind <> "WithoutFilterByAccessKind" Then
		Filter.Insert("AccessKind", AccessKind);
	EndIf;
	
	Return Filter;
	
EndFunction

// Only for internal use.
Procedure FillAccessKindsPropertiesInForm(Form) Export
	
	Parameters = AllowedValuesEditFormParameters(Form);
	
	AccessKindsFilter = FilterInAllowedValuesEditFormTables(Form);
	AccessKinds = Parameters.AccessKinds.FindRows(AccessKindsFilter);
	
	For Each String IN AccessKinds Do
		
		String.Used = True;
		
		If String.AccessKind <> Undefined Then
			Filter = New Structure("Ref", String.AccessKind);
			FoundStrings = Form.AllAccessKinds.FindRows(Filter);
			If FoundStrings.Count() > 0 Then
				String.AccessKindPresentation = FoundStrings[0].Presentation;
				String.Used            = FoundStrings[0].Used;
			EndIf;
		EndIf;
		
		FillInAllAllowedPresentation(Form, String);
		
		FillInAccessValuesByKindLineNumbers(Form, String);
	EndDo;
	
EndProcedure

// Only for internal use.
Procedure AllowedValuesEditFormFillCheckProcessingAtServerProcessor(
		Form, Cancel, VerifiedTablesAttributes, Errors, DoNotCheck = False) Export
	
	Items = Form.Items;
	Parameters = AllowedValuesEditFormParameters(Form);
	
	VerifiedTablesAttributes.Add(Parameters.PathToTables + "AccessKinds.AccessKind");
	VerifiedTablesAttributes.Add(Parameters.PathToTables + "AccessValues.AccessKind");
	VerifiedTablesAttributes.Add(Parameters.PathToTables + "AccessValues.AccessValue");
	
	If DoNotCheck Then
		Return;
	EndIf;
	
	AccessKindsFilter = FilterInAllowedValuesEditFormTables(
		Form);
	
	AccessKinds = Parameters.AccessKinds.FindRows(AccessKindsFilter);
	AccessKindIndex = AccessKinds.Count()-1;
	
	// Checking of unfilled and repeating kinds of access.
	While Not Cancel AND AccessKindIndex >= 0 Do
		
		AccessKindRow = AccessKinds[AccessKindIndex];
		
		// Checking completion of access kind.
		If AccessKindRow.AccessKind = Undefined Then
			CommonUseClientServer.AddUserError(Errors,
				Parameters.PathToTables + "AccessKinds[%1].AccessKind",
				NStr("en='Access kind was not selected.';ru='Вид доступа не выбран.';vi='Dạng truy cập chưa chọn.'"),
				"AccessKinds",
				AccessKinds.Find(AccessKindRow),
				NStr("en='Access kind in line %1 was not selected.';ru='Вид доступа в строке %1 не выбран.';vi='Dạng truy cập trong dòng %1 chưa chọn.'"),
				Parameters.AccessKinds.IndexOf(AccessKindRow));
			Cancel = True;
			Break;
		EndIf;
		
		// Checking existence of repeating kinds of access.
		AccessKindsFilter.Insert("AccessKind", AccessKindRow.AccessKind);
		FoundAccessTypes = Parameters.AccessKinds.FindRows(AccessKindsFilter);
		
		If FoundAccessTypes.Count() > 1 Then
			CommonUseClientServer.AddUserError(Errors,
				Parameters.PathToTables + "AccessKinds[%1].AccessKind",
				NStr("en='The access type is recurring.';ru='Вид доступа повторяется.';vi='Dạng truy cập lặp lại.'"),
				"AccessKinds",
				AccessKinds.Find(AccessKindRow),
				NStr("en='Access kind in line %1 is repeated.';ru='Вид доступа в строке %1 повторяется.';vi='Dạng truy cập trong dòng %1 lặp lại.'"),
				Parameters.AccessKinds.IndexOf(AccessKindRow));
			Cancel = True;
			Break;
		EndIf;
		
		AccessValuesFilter = FilterInAllowedValuesEditFormTables(
			Form, AccessKindRow.AccessKind);
		
		AccessValues = Parameters.AccessValues.FindRows(AccessValuesFilter);
		AccessValueIndex = AccessValues.Count()-1;
		
		While Not Cancel AND AccessValueIndex >= 0 Do
			
			AccessValueString = AccessValues[AccessValueIndex];
			
			// Checking completion of access value.
			If Not ValueIsFilled(AccessValueString.AccessValue) Then
				Items.AccessKinds.CurrentRow = AccessKindRow.GetID();
				Items.AccessValues.CurrentRow = AccessValueString.GetID();
				
				CommonUseClientServer.AddUserError(Errors,
					Parameters.PathToTables + "AccessValues[%1].AccessValue",
					NStr("en='Value is not selected.';ru='Значение не выбрано.';vi='Giá trị chưa chọn.'"),
					"AccessValues",
					AccessValues.Find(AccessValueString),
					NStr("en='Value in line %1 is not selected.';ru='Значение в строке %1 не выбрано.';vi='Giá trị trong dòng %1 chưa chọn.'"),
					Parameters.AccessValues.IndexOf(AccessValueString));
				Cancel = True;
				Break;
			EndIf;
			
			// Checking existence of duplicate values.
			AccessValuesFilter.Insert("AccessValue", AccessValueString.AccessValue);
			FoundValues = Parameters.AccessValues.FindRows(AccessValuesFilter);
			
			If FoundValues.Count() > 1 Then
				Items.AccessKinds.CurrentRow = AccessKindRow.GetID();
				Items.AccessValues.CurrentRow = AccessValueString.GetID();
				
				CommonUseClientServer.AddUserError(Errors,
					Parameters.PathToTables + "AccessValues[%1].AccessValue",
					NStr("en='Value is repeated.';ru='Значение повторяется.';vi='Giá trị lặp lại.'"),
					"AccessValues",
					AccessValues.Find(AccessValueString),
					NStr("en='Value in line %1 is repeated.';ru='Значение в строке %1 повторяется.';vi='Giá trị trong dòng %1 lặp lại.'"),
					Parameters.AccessValues.IndexOf(AccessValueString));
				Cancel = True;
				Break;
			EndIf;
			
			AccessValueIndex = AccessValueIndex - 1;
		EndDo;
		AccessKindIndex = AccessKindIndex - 1;
	EndDo;
	
EndProcedure

#EndRegion
