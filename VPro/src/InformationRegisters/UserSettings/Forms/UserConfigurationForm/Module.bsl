//By transferred data create string tree on form
//
// Selection - query sample with data in hierarchy
// ValueTree - value tree items for which strings are created
//
Function AddRowsIntoTree(Selection, ValueTree)
	
	While Selection.Next() Do
		
		NewRowOfSetting = ValueTree.Add();
		FillPropertyValues(NewRowOfSetting, Selection);
		NewRowOfSetting.Value = Selection.Setting.ValueType.AdjustValue(Selection.Value);
		
		RowsOfSelection = Selection.Select(QueryResultIteration.ByGroupsWithHierarchy);
		If RowsOfSelection.Count() > 0 Then
			
			AddRowsIntoTree(RowsOfSelection, NewRowOfSetting.GetItems());
			
		EndIf;
		
	EndDo;
	
EndFunction

// Procedure updates information in the setting table.
//
Procedure FillTree()

	SettingsItems = SettingsTree.GetItems();
	SettingsItems.Clear();

	Query = New Query;
	Query.SetParameter("User", User);
	Query.Text=
	"SELECT
	|	Settings.Parent,
	|	Settings.Ref AS Setting,
	|	Settings.IsFolder AS IsFolder,
	|	NOT Settings.IsFolder AS PictureNumber,
	|	SettingsValue.Value,
	|	Constants.FunctionalOptionAccountingByMultipleCompanies,
	|	Constants.FunctionalOptionAccountingByMultipleWarehouses,
	|	Constants.FunctionalOptionAccountingByMultipleDepartments
	|FROM
	|	ChartOfCharacteristicTypes.UserSettings AS Settings
	|		LEFT JOIN InformationRegister.UserSettings AS SettingsValue
	|		ON (SettingsValue.Setting = Settings.Ref)
	|			AND (SettingsValue.User = &User),
	|	Constants AS Constants
	|WHERE
	|	NOT Settings.DeletionMark
	|	AND NOT(Settings.Ref = VALUE(ChartOfCharacteristicTypes.UserSettings.MainCompany)
	|				AND NOT Constants.FunctionalOptionAccountingByMultipleCompanies)
	|	AND NOT(Settings.Ref = VALUE(ChartOfCharacteristicTypes.UserSettings.MainWarehouse)
	|				AND NOT Constants.FunctionalOptionAccountingByMultipleWarehouses)
	|	AND NOT(Settings.Ref = VALUE(ChartOfCharacteristicTypes.UserSettings.MainDepartment)
	|				AND NOT Constants.FunctionalOptionAccountingByMultipleDepartments)
	|	AND NOT(Settings.Ref = VALUE(ChartOfCharacteristicTypes.UserSettings.StatusOfNewCustomerOrder)
	|				AND NOT Constants.UseCustomerOrderStates)
	|	AND NOT(Settings.Ref = VALUE(ChartOfCharacteristicTypes.UserSettings.StatusOfNewPurchaseOrder)
	|				AND NOT Constants.UsePurchaseOrderStates)
	|	AND NOT(Settings.Ref = VALUE(ChartOfCharacteristicTypes.UserSettings.StatusOfNewProductionOrder)
	|				AND NOT Constants.UseProductionOrderStates)
	|	AND (Settings.Parent <> VALUE(ChartOfCharacteristicTypes.UserSettings.MultiplePickSetting)
	|			OR Settings.Ref = VALUE(ChartOfCharacteristicTypes.UserSettings.UseNewSelectionMechanism))
	|	AND NOT(Settings.Ref = VALUE(ChartOfCharacteristicTypes.UserSettings.UsePerformerSalariesInWorkOrder)
	|				AND NOT Constants.FunctionalOptionUseSubsystemPayroll)
	|	AND NOT(Settings.Ref = VALUE(ChartOfCharacteristicTypes.UserSettings.UsePerformerSalariesInWorkOrder)
	|				AND NOT Constants.FunctionalOptionUseWorkSubsystem)
	|	AND NOT(Settings.Ref = VALUE(ChartOfCharacteristicTypes.UserSettings.UseMaterialsInWorkOrder)
	|				AND NOT Constants.FunctionalOptionUseWorkSubsystem)
	|	AND NOT(Settings.Ref = VALUE(ChartOfCharacteristicTypes.UserSettings.UseConsumerMaterialsInWorkOrder)
	|				AND NOT Constants.FunctionalOptionUseWorkSubsystem)
	|	AND NOT(Settings.Ref = VALUE(ChartOfCharacteristicTypes.UserSettings.UseProductsInWorkOrder)
	|				AND NOT Constants.FunctionalOptionUseWorkSubsystem)
	|	AND NOT(Settings.Ref = VALUE(ChartOfCharacteristicTypes.UserSettings.WorkKindPositionInWorkOrder)
	|				AND NOT Constants.FunctionalOptionUseWorkSubsystem)
	|	AND NOT Settings.Ref = VALUE(ChartOfCharacteristicTypes.UserSettings.DataImportMethodFromExternalSources)
	|	AND NOT Settings.Ref = VALUE(ChartOfCharacteristicTypes.UserSettings.DataImportFromExternalSources)
	|	AND NOT Settings.Ref = VALUE(ChartOfCharacteristicTypes.UserSettings.FillingValueProductsAndServicesCategory)
	|
	|ORDER BY
	|	IsFolder HIERARCHY,
	|	Settings.Description";
	
	Selection = Query.Execute().Select(QueryResultIteration.ByGroupsWithHierarchy);
	
	AddRowsIntoTree(Selection, SettingsItems);
	
EndProcedure // FillTree()

// Procedure writes the setting values into the information register.
//
Procedure UpdateSettings()
	
	RecordSet = InformationRegisters.UserSettings.CreateRecordSet();
	
	RecordSet.Filter.User.Use = True;
	RecordSet.Filter.User.Value      = User;
	
	SettingsGroups = SettingsTree.GetItems();
	For Each SettingsGroup IN SettingsGroups Do
		
		SettingsItems = SettingsGroup.GetItems();
		
		For Each SettingsRow IN SettingsItems Do
			
			Record = RecordSet.Add();
			
			Record.User = User;
			Record.Setting    = SettingsRow.Setting;
			Record.Value     = SettingsRow.Setting.ValueType.AdjustValue(SettingsRow.Value);
			
		EndDo;
		
	EndDo;
	
	RecordSet.Write();
	
	RefreshReusableValues();
	
EndProcedure // UpdateSettings()

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("User") Then
		
		User = Parameters.User;
		
		If ValueIsFilled(User) Then
			
			MainDepartment = ChartsOfCharacteristicTypes.UserSettings.MainDepartment;
			MainWarehouse = ChartsOfCharacteristicTypes.UserSettings.MainWarehouse;
			
			ChoiceParametersDepartment = Enums.StructuralUnitsTypes.Department;
			
			ChoiceParametersWarehouse = New ValueList;
			ChoiceParametersWarehouse.Add(Enums.StructuralUnitsTypes.Warehouse);
			ChoiceParametersWarehouse.Add(Enums.StructuralUnitsTypes.Retail);
			ChoiceParametersWarehouse.Add(Enums.StructuralUnitsTypes.RetailAccrualAccounting);
			
			
			FillTree();
			
		EndIf;
		
	EndIf;
	
EndProcedure // OnCreateAtServer()

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit Then
		UpdateSettings();
	EndIf;
	
EndProcedure // OnClose() 

&AtClient
Procedure SettingsTreeBeforeRowChange(Item, Cancel)
	
	If Item.CurrentData = Undefined OR Item.CurrentData.IsFolder Then
		
		Cancel = True;
		Return;
		
	ElsIf Item.CurrentData.Setting = MainDepartment Then
		
		NewArray = New Array();
		NewArray.Add(New ChoiceParameter("Filter.StructuralUnitType", ChoiceParametersDepartment));
		Items.SettingsTreeValue.ChoiceParameters = New FixedArray(NewArray);;
		
	ElsIf Item.CurrentData.Setting = MainWarehouse Then
		
		NewArray = New Array();
		For Each ItemOfList IN ChoiceParametersWarehouse Do
			NewArray.Add(ItemOfList.Value);
		EndDo;		
		ArrayWarehouse = New FixedArray(NewArray);
		NewParameter = New ChoiceParameter("Filter.StructuralUnitType", ArrayWarehouse);
		NewArray = New Array();
		NewArray.Add(NewParameter);
		Items.SettingsTreeValue.ChoiceParameters = New FixedArray(NewArray);
		
	EndIf;
	
EndProcedure
