
// Work methods with DLS from report form (client, server).
//
////////////////////////////////////////////////////////////////////////////////

#Region ProgramInterface

// Default settings of a report form.
//
// Returns:
//   Structure - Report form settings.
//       
//       * FormImmediately - Boolean - Default value for the Form immediately checkbox.
//           When the check box is selected, the report will be formed.:
//             - After opening;
//             - After selection of custom settings;
//             - After selecting another report variant.
//       
//       * OutputSelectedCellsAmount - Boolean - If True, then the autoamount field will be displayed in the report.
//       
//       * MapParametersFrequency - Map - Restrict list of the StandardPeriod fields selection.
//           ** Key - DataCompositionParameter - parameter description report to which the restriction applies.
//           ** Value - EnumRef.AvailableReportPeriods - Restriction of the below report period.
//       
//       * Print - Structure - Print parameters for the by default tabular document.
//           ** FieldAbove - Number - Top indent during printing (in millimetres).
//           ** FieldLeft  - Number - Left indent during printing (in millimetres).
//           ** FieldBottom  - Number - Bottom indent during printing (in millimetres).
//           ** FieldRight - Number - Right indent during printing (in millimetres).
//           ** PageOrientation - PageOrientation - Portrait or Landscape.
//           **AutoScale - Boolean - Automatically customize scale according to the page size.
//           **PrintScale - Number - Image scale (percent).
//       
//       * Events - Structure - Events, for which handlers are defined in a report object module.
//           
//           **OnCreateAtServer - Boolean - If True, then you should
//               define event handler by a pattern in the object module:
//               
//               // Called in the handler of the report form eponymous event after execution of the form code.
//              
//                Parameters:
//               //   Form - ManagedForm - Report form.
//                //  Cancel - Passed from the handler parameters "as is."
//           //       StandardProcessing - Passed from the handler parameters "as is."
//           //    
//               See also:
//               //   ManagedForm.OnCeateOnServer in syntax helper.
//              
//               Procedure OnCreateAtServer (Form, Denial,
//               	 StandardProcessing) Export Event processing.
//               EndProcedure
//           
//           ** BeforeLoadVariantOnServer - Boolean - If True, then you should
//               define event handler by a pattern in the object module:
//               
//               // Called in the handler of the report form eponymous event after execution of the form code.
//              
//                Parameters:
//               //   Form - ManagedForm - Report form.
//                //  NewSettingsDC - DataCompositionSettings - Settings for import to the settings linker.
//              
//   //            See also:
//               //   Extension of the controlled form for report.OnLoadVariantOnServer in syntax helper.
//              
//               Procedure BeforeLoadVariantOnServer (Form,
//               	 NewKDsettings) Export Event processing.
//               EndProcedure
//           
//           **OnLoadVariantOnServer - Boolean - If True, then you should
//               define event handler by a pattern in the object module:
//               
//               // Called in the handler of the report form eponymous event after execution of the form code.
//              
//                Parameters:
//               //   Form - ManagedForm - Report form.
//                //  NewSettingsDC - DataCompositionSettings - Settings for import to the settings linker.
//              
//   //            See also:
//               //   Extension of the controlled form for report.OnLoadVariantOnServer in syntax helper.
//              
//               Procedure OnLoadVariantOnServer (Form,
//               	 NewKDSettings) Export Event processing.
//               EndProcedure
//           
//           ** OnLoadUserSettingsOnServer - Boolean - If True, then you should
//               define event handler by a pattern in the object module:
//               
//               // Called in the handler of the report form eponymous event after execution of the form code.
//              
//                Parameters:
//               //   Form - ManagedForm - Report form.
//                //  NewDCUserSettings - DataCompositionUserSettings -
//               //       Custom settings to import to the settings linker.
//              
//               See also:
//               //   Extension of the managed
//                   form for report.OnLoadUserSettingsAtServer in the syntax helper.
//              
//               Procedure OnLoadUserSettingsAtServer (Form,
//               	 NewKDUserSettings) Export Event processing.
//               EndProcedure
//           
//           ** BeforeFillingQuickSettingsPanel - Boolean - If True, then you should
//               define event handler by a pattern in the object module:
//               
//               // Called before refilling the settings panel of report form.
//              
//                Parameters:
//               //   Form - ManagedForm - Report form.
//                //  FillingParameters - Structure - Parameters to be imported into the report.
//              
// //              Procedure BeforeFillQuichSettingsPanel (Form,
//               	 FillingParameters) Export Event processing.
//               EndProcedure
//           
//           ** AfterFillingQuickSettingsPanel - Boolean - If True, then you should
//               define event handler by a pattern in the object module:
//               
//               // Calls after refill of the report form settings panel.
//              
//                Parameters:
//               //   Form - ManagedForm - Report form.
//                //  FillingParameters - Structure - Parameters to be imported into the report.
//              
// //              Procedure AfterFillQuichSettingsPanel (Form,
//               	 FillingParameters) Export Event processing.
//               EndProcedure
//           
//           ** ContextServerCall - Boolean - If True, then you should
//               define event handler by a pattern in the object module:
//               
//               // Handler of a server context call.
//                  Allows to execute server context call if needed from the client common mode.
//                  For example, from ReportsClientOverridable.CommandHandler().
//              
//                Parameters:
//               //   Form  - ManagedForm
//                  Ke//y      - String    - Key of operation that needs to be executed in the context call.
//                 // Parameters - Structure - Parameters of server call.
//              //    Result - Structure - Result of server work, returns to the client.
//              
//    //           See also:
//               //   CommonForm.ReportForm.ExecuteContextServerCall().
//              
//               Procedure ContextServerCall (Form, Key, Parameters,
//               	 Result) Export Event processing.
//               EndProcedure
//           
//           **OnDefineSelectionParameters - Boolean - If True, then you should
//               define event handler by a pattern in the object module:
//               
//               // Called in the form of report before the setting output.
//                  Details - see ReportsOverridable.OnDefineSelectionParameters().
//              
//       //        Procedure OnDefineSelectionParameters (Form,
//               	 SettingProperties) Export Event processing.
//               EndProcedure
//           
//           ** ExpandMetadataObjectsLinks - Boolean - If True, then you should
//               define event handler by a pattern in the object module:
//               
//               // Additional links settings of this report.
//                  Details - see ReportsOverridable.ExpandMetadataObjectsLinks().
//              
//          //     Procedure ExpandMetadataObjectsLinks
//               	 (MetadataObjectsLink) Export Event processing.
//               EndProcedure
//
Function GetReportSettingsByDefault() Export
	Print = New Structure;
	Print.Insert("TopMargin", 10);
	Print.Insert("LeftMargin", 10);
	Print.Insert("BottomMargin", 10);
	Print.Insert("RightMargin", 10);
	Print.Insert("PageOrientation", PageOrientation.Portrait);
	Print.Insert("FitToPage", True);
	Print.Insert("PrintScale", Undefined);
	
	Events = New Structure;
	Events.Insert("OnCreateAtServer", False);
	Events.Insert("BeforeLoadVariantAtServer", False);
	Events.Insert("OnLoadVariantAtServer", False);
	Events.Insert("OnLoadUserSettingsAtServer", False);
	Events.Insert("BeforeFillingQuickSettingsPanel", False);
	Events.Insert("AfterFillingQuickSettingsPanel", False);
	Events.Insert("ContextServerCall", False);
	Events.Insert("OnDefineSelectionParameters", False);
	Events.Insert("SupplementMetadataObjectsLinks", False);
	
	Settings = New Structure;
	Settings.Insert("FormImmediately", False);
	Settings.Insert("OutputAmountSelectedCells", True);
	Settings.Insert("AccordanceFrequencySettings", New Map);
	Settings.Insert("Print", Print);
	Settings.Insert("Events", Events);
	
	// Expired:
	Settings.Insert("PrintParametersByDefault", Print); // See Settings.Print.
	
	Return Settings;
	
EndFunction

#EndRegion

#Region ServiceProgramInterface

// Forms a brief error presentation.
//
// Parameters:
//   ErrorInfo - ErrorInfo - Error information.
//
// Returns:
//   String - Short error presentation.
//
Function BriefErrorDescriptionOfReportFormation(ErrorInfo) Export
	
	ErrorDescription = ErrorInfo.Description;
	CauseErrors = ErrorInfo.Cause;
	While CauseErrors <> Undefined Do
		ErrorDescription = CauseErrors.Description;
		CauseErrors = CauseErrors.Cause;
	EndDo;
	
	Return ErrorDescription;
	
EndFunction

#EndRegion

#Region ServiceProceduresAndFunctions

// Finds available setting for filter or parameter.
//
// Parameters:
//   DCSettings - DataCompositionSettings - Settings collection.
//   CommonSetting - DataLayoutFilterItem,
//       DataLayoutSettingsParameterValue, DataLayoutInsertedObjectSettings - Item value of setting.
//
// Returns:
//   DataLayoutAvailableField, DataLayoutAvailableParameter, DataLayoutAvailableSettingObject -
//   Available setting.
//   Undefined - If an available setting is not found.
//
Function FindAvailableSetting(DCSettings, CommonSetting) Export
	CommonSettingType = TypeOf(CommonSetting);
	If CommonSettingType = Type("DataCompositionFilterItem") Then
		Return FindKDAvailableField(DCSettings, CommonSetting.LeftValue);
	ElsIf CommonSettingType = Type("DataCompositionSettingsParameterValue") Then
		Return FingAvailableKDParameter(DCSettings, CommonSetting.Parameter);
	ElsIf CommonSettingType = Type("DataCompositionNestedObjectSettings") Then
		Return DCSettings.AvailableObjects.Items.Find(CommonSetting.ObjectID);
	EndIf;
	
	Return Undefined;
EndFunction

// Finds available setting of data layout field .
//
// Parameters:
//   DCSettings - DataCompositionSettings - Settings collection.
//   DCField - DataCompositionField - Field name.
//
// Returns:
//   AvailableDataLayoutField, Undefined - Available setting for a field.
//
Function FindKDAvailableField(DCSettings, DCField) Export
	If DCField = Undefined Then
		Return Undefined;
	EndIf;
	
	AvailableSetting = DCSettings.FilterAvailableFields.FindField(DCField);
	If AvailableSetting <> Undefined Then
		Return AvailableSetting;
	EndIf;
	
	StructuresArray = New Array;
	StructuresArray.Add(DCSettings.Structure);
	While StructuresArray.Count() > 0 Do
		
		StructureCD = StructuresArray[0];
		StructuresArray.Delete(0);
		
		For Each ItemOfDCStructure IN StructureCD Do
			
			If TypeOf(ItemOfDCStructure) = Type("DataCompositionNestedObjectSettings") Then
				
				AvailableSetting = ItemOfDCStructure.Settings.FilterAvailableFields.FindField(DCField);
				If AvailableSetting <> Undefined Then
					Return AvailableSetting;
				EndIf;
				
				StructuresArray.Add(ItemOfDCStructure.Settings.Structure);
				
			ElsIf TypeOf(ItemOfDCStructure) = Type("DataCompositionGroup") Then
				
				AvailableSetting = ItemOfDCStructure.Filter.FilterAvailableFields.FindField(DCField);
				If AvailableSetting <> Undefined Then
					Return AvailableSetting;
				EndIf;
				
				StructuresArray.Add(ItemOfDCStructure.Structure);
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Return Undefined;
EndFunction

// Finds available setting of the data layout parameter.
//
// Parameters:
//   DCSettings - DataCompositionSettings - Settings collection.
//   DCParameter - DataCompositionParameter - Parameter description.
//
// Returns:
//   AvailableDataLayoutParameter, Undefined - Available setting for a parameter.
//
Function FingAvailableKDParameter(DCSettings, DCParameter) Export
	If DCParameter = Undefined Then
		Return Undefined;
	EndIf;
	
	If DCSettings.DataParameters.AvailableParameters <> Undefined Then
		// Settings, to which data parameters belong are associated with available source settings.
		AvailableSetting = DCSettings.DataParameters.AvailableParameters.FindParameter(DCParameter);
		If AvailableSetting <> Undefined Then
			Return AvailableSetting;
		EndIf;
	EndIf;
	
	StructuresArray = New Array;
	StructuresArray.Add(DCSettings.Structure);
	While StructuresArray.Count() > 0 Do
		
		StructureCD = StructuresArray[0];
		StructuresArray.Delete(0);
		
		For Each ItemOfDCStructure IN StructureCD Do
			
			If TypeOf(ItemOfDCStructure) = Type("DataCompositionNestedObjectSettings") Then
				
				If ItemOfDCStructure.Settings.DataParameters.AvailableParameters <> Undefined Then
					// Settings, to which data parameters belong are associated with available source settings.
					AvailableSetting = ItemOfDCStructure.Settings.DataParameters.AvailableParameters.FindParameter(DCParameter);
					If AvailableSetting <> Undefined Then
						Return AvailableSetting;
					EndIf;
				EndIf;
				
				StructuresArray.Add(ItemOfDCStructure.Settings.Structure);
				
			ElsIf TypeOf(ItemOfDCStructure) = Type("DataCompositionGroup") Then
				
				StructuresArray.Add(ItemOfDCStructure.Structure);
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Return Undefined;
EndFunction

// Finds a custom setting by its identifier.
//
// Parameters:
//   DCUserSettings - DataCompositionUserSettings - Collection of custom settings.
//   ID - String -
//
Function FindCustomSetting(DCUserSettings, ID) Export
	For Each UserSetting IN DCUserSettings.Items Do
		If UserSetting.UserSettingID = ID Then
			Return UserSetting;
		EndIf;
	EndDo;
	
	Return Undefined;
EndFunction

// Finds the nested custom setting by its identifier.
Function FindEnclosedUserSetting(UserSetting, ID) Export
	If Not ValueIsFilled(ID) Then
		Return Undefined;
	EndIf;
	
	For Each EnclosedSetting IN UserSetting.Items Do
		If String(UserSetting.GetIDByObject(EnclosedSetting)) = ID Then
			Return EnclosedSetting;
		EndIf;
		If TypeOf(EnclosedSetting) = Type("DataCompositionSelectedFieldGroup") Then
			SearchResult = FindChoiceField(UserSetting, ID, EnclosedSetting);
			If SearchResult <> Undefined Then
				Return SearchResult;
			EndIf;
		EndIf;
	EndDo;
	
	Return Undefined;
EndFunction

// Finds a common setting by custom setting ID.
//
// Parameters:
//   Settings - DataCompositionSettings - Settings collection.
//   UserSettingID - String -
//
Function GetObjectByUserIdentifier(Settings, UserSettingID, Hierarchy = Undefined, UserSettings = Undefined) Export
	If Hierarchy = Undefined
		And TypeOf(UserSettings) = Type("DataCompositionUserSettings") Then 
		
		FoundItems =
			UserSettings.GetMainSettingsByUserSettingID(UserSettingID);
		
		If FoundItems.Count() > 0 Then 
			Return FoundItems[0];
		EndIf;
	EndIf;
	
	If Hierarchy <> Undefined Then
		Hierarchy.Add(Settings);
	EndIf;

	
	SettingType = TypeOf(Settings);
	
	If SettingType <> Type("DataCompositionSettings") Then
		
		If Settings.UserSettingID = UserSettingID Then
			
			Return Settings;
			
		ElsIf SettingType = Type("DataCompositionNestedObjectSettings") Then
			
			Return GetObjectByUserIdentifier(Settings.Settings, UserSettingID, Hierarchy);
			
		ElsIf SettingType = Type("DataCompositionTableStructureItemCollection")
			OR SettingType = Type("DataCompositionChartStructureItemCollection")
			OR SettingType = Type("DataCompositionSettingStructureItemCollection") Then
			
			For Each NestedItem IN Settings Do
				SearchResult = GetObjectByUserIdentifier(NestedItem, UserSettingID, Hierarchy);
				If SearchResult <> Undefined Then
					Return SearchResult;
				EndIf;
			EndDo;
			
			If Hierarchy <> Undefined Then
				Hierarchy.Delete(Hierarchy.UBound());
			EndIf;
			
			Return Undefined;
			
		EndIf;
		
	EndIf;
	
	If Settings.Selection.UserSettingID = UserSettingID Then
		Return Settings.Selection;
	ElsIf Settings.ConditionalAppearance.UserSettingID = UserSettingID Then
		Return Settings.ConditionalAppearance;
	EndIf;
	
	If SettingType <> Type("DataCompositionTable") AND SettingType <> Type("DataCompositionChart") Then
		If Settings.Filter.UserSettingID = UserSettingID Then
			Return Settings.Filter;
		ElsIf Settings.Order.UserSettingID = UserSettingID Then
			Return Settings.Order;
		EndIf;
	EndIf;
	
	If SettingType = Type("DataCompositionSettings") Then
		SearchResult = FindSettingItem(Settings.DataParameters, UserSettingID);
		If SearchResult <> Undefined Then
			Return SearchResult;
		EndIf;
	EndIf;
	
	If SettingType <> Type("DataCompositionTable") AND SettingType <> Type("DataCompositionChart") Then
		SearchResult = FindSettingItem(Settings.Filter, UserSettingID);
		If SearchResult <> Undefined Then
			Return SearchResult;
		EndIf;
	EndIf;
	
	SearchResult = FindSettingItem(Settings.ConditionalAppearance, UserSettingID);
	If SearchResult <> Undefined Then
		Return SearchResult;
	EndIf;
	
	If SettingType = Type("DataCompositionTable") Then
		
		SearchResult = GetObjectByUserIdentifier(Settings.Rows, UserSettingID, Hierarchy);
		If SearchResult <> Undefined Then
			Return SearchResult;
		EndIf;
		
		SearchResult = GetObjectByUserIdentifier(Settings.Columns, UserSettingID, Hierarchy);
		If SearchResult <> Undefined Then
			Return SearchResult;
		EndIf;
		
	ElsIf SettingType = Type("DataCompositionChart") Then
		
		SearchResult = GetObjectByUserIdentifier(Settings.Points, UserSettingID, Hierarchy);
		If SearchResult <> Undefined Then
			Return SearchResult;
		EndIf;
		
		SearchResult = GetObjectByUserIdentifier(Settings.Series, UserSettingID, Hierarchy);
		If SearchResult <> Undefined Then
			Return SearchResult;
		EndIf;
		
	Else
		
		SearchResult = GetObjectByUserIdentifier(Settings.Structure, UserSettingID, Hierarchy);
		If SearchResult <> Undefined Then
			Return SearchResult;
		EndIf;
		
	EndIf;
	
	If Hierarchy <> Undefined Then
		Hierarchy.Delete(Hierarchy.UBound());
	EndIf;
	
	Return Undefined;
	
EndFunction

// Function returns the available field of data layout.
//
// Parameters:
// 	Available fields - available fields of the data layout, available fields of
// 	the data layout filter etc. Field           - Field name of data layout.
//
Function GetAvailableField(AvailableFields, Field) Export
	
	If TypeOf(Field) = Type("String") Then
		AccessField = New DataCompositionField(Field);
	ElsIf TypeOf(Field) = Type("DataCompositionField") Then
		AccessField = Field;
	Else
		Return Undefined;
	EndIf;
	
	Return AvailableFields.FindField(AccessField);
	
EndFunction

// Function returns the Parameter available compositing data.
//
// Parameters:
// 	Available fields - available fields of the data layout, available fields of
// 	the data layout filter etc. Parameter       - Name of the data layout parameters.
//
Function GetAvailableParameter(AvailableParameters, Parameter) Export
	
	If TypeOf(AvailableParameters) <> Type("DataCompositionAvailableParameters") Then
		Return Undefined;
	EndIf;
	
	If TypeOf(Parameter) = Type("String") Then
		AccessParameter = New DataCompositionParameter(Parameter);
	ElsIf TypeOf(Parameter) = Type("DataCompositionParameter") Then
		AccessParameter = Parameter;
	Else
		Return Undefined;
	EndIf;
	
	Return AvailableParameters.FindParameter(AccessParameter);
	
EndFunction

// Imports the values of the item in the table.
Procedure AddSettingItems(ReportForm, Table, SettingItem, ChoiceItem, AddHierarchicalFields, Indent = "") Export
	
	For Each ComboBox IN ChoiceItem.Items Do
		Title = ComboBox.Title;
		If Title = "" Then
			AvailableField = GetAvailableField(ReportForm.Report.SettingsComposer.Settings.SelectionAvailableFields, ComboBox.Field);
			If AvailableField <> Undefined Then
				Title = AvailableField.Title;
			Else
				Continue;
			EndIf;
		EndIf;
		ComboBoxRow = Table.Add();
		ComboBoxRow.Presentation = Indent + Title;
		ComboBoxRow.Use = ComboBox.Use;
		ComboBoxRow.ID = String(SettingItem.GetIDByObject(ComboBox));
		If TypeOf(ComboBox) = Type("DataCompositionSelectedFieldGroup") Then
			ComboBoxRow.IsFolder = True;
		EndIf;
		If AddHierarchicalFields AND TypeOf(ComboBox) = Type("DataCompositionSelectedFieldGroup") AND ComboBox.Items.Count() > 0 Then
			AddSettingItems(ReportForm, Table, SettingItem, ComboBox, True, Indent + "    ");
		EndIf;
	EndDo;
	
EndProcedure

// Returns a list of periods in the range of period.
Function GetFiltersStructure(ReportForm, SettingsComposer, IdentificatorRow, FilterType = Undefined, FilterTypeString = Undefined) Export
	
	ParametersStructure = New Structure();
	
	If FilterType = Undefined AND (FilterTypeString = Undefined Or FilterTypeString = "") Then
		Return Undefined;
	EndIf;
	
	If FilterType = Undefined AND FilterTypeString <> Undefined AND FilterTypeString = "" Then
		FilterType = Type(FilterTypeString);
	EndIf;
	
	// Get connections table 
	LinksStrings = ReportForm.FiltersLinks.FindRows(New Structure("FilterIdentifier", IdentificatorRow));
	LinksStringsArray = New Array;
	For Each LinkString IN LinksStrings Do
		If Type(LinkString.Type) = FilterType Then
			LinksStringsArray.Add(LinkString);
		EndIf;
	EndDo;
	
	// Add filters and parameters from the report settings items by table of fields links.
	For Each LinkString IN LinksStringsArray Do
		SettingItem = FindCustomSetting(SettingsComposer.UserSettings, LinkString.FilterValueIdentifier);
		If SettingItem = Undefined Or Not SettingItem.Use Then
			Continue;
		EndIf;
		FilterValue = UNDEFINED;
		If TypeOf(SettingItem) = Type("DataCompositionFilterItem") Then
			FilterValue = SettingItem.RightValue;
		ElsIf TypeOf(SettingItem) = Type("DataCompositionSettingsParameterValue") Then
			FilterValue = SettingItem.Value;
		EndIf;
		If FilterValue <> UNDEFINED Then
			ChoiceParameterNames = StringFunctionsClientServer.DecomposeStringIntoSubstringsArray(LinkString.FieldAttribute, ".");
			If ChoiceParameterNames.Count() = 1 Then
				ParametersStructure.Insert(ChoiceParameterNames[0], FilterValue);
			ElsIf ChoiceParameterNames[0] = "Filter" Then
				If Not ParametersStructure.Property("Filter") Then
					ParametersStructure.Insert("Filter", New Structure());
				EndIf;
				ParametersStructure.Filter.Insert(ChoiceParameterNames[1], FilterValue);
			EndIf;
		EndIf;
	EndDo;
	
	Return ParametersStructure;
	
EndFunction

// Adds a selected data layout field.
//
// Parameters:
//   Where - DataLayoutSettingsLayout, DataLayoutSettings, DataLayoutSelectedFields -
//       Collection to which you need to add the selected field.
//   NameOrDCField - String, DataLayoutField - Field name.
//   Title    - String - Optional. Presentation fields.
//
// Returns:
//   DataCompositionSelectedField - Added selected field.
//
Function AddSelectedField(Where, NameOrDCField, Title = "") Export
	
	If TypeOf(Where) = Type("DataCompositionSettingsComposer") Then
		FieldsSelectedCD = Where.Settings.Selection;
	ElsIf TypeOf(Where) = Type("DataCompositionSettings") Then
		FieldsSelectedCD = Where.Selection;
	Else
		FieldsSelectedCD = Where;
	EndIf;
	
	If TypeOf(NameOrDCField) = Type("String") Then
		DCField = New DataCompositionField(NameOrDCField);
	Else
		DCField = NameOrDCField;
	EndIf;
	
	SelectedFieldKD = FieldsSelectedCD.Items.Add(Type("DataCompositionSelectedField"));
	SelectedFieldKD.Field = DCField;
	If Title <> "" Then
		SelectedFieldKD.Title = Title;
	EndIf;
	
	Return SelectedFieldKD;
	
EndFunction

// Returns a list of all groupings of settings layout.
// 
// Parameters:
// 	StructureItem - item of the DLS setting structure, DLS setting or settings linker.
// 	ShowTableGroups - shows that columns groupings were added to the list (True by default).
//
Function GetGroups(StructureItem, ShowTableGroups = True) Export
	
	FieldList = New ValueList;
	If TypeOf(StructureItem) = Type("DataCompositionSettingsComposer") Then
		Structure = StructureItem.Settings.Structure;
		AddGroups(Structure, FieldList);
	ElsIf TypeOf(StructureItem) = Type("DataCompositionSettings") Then
		Structure = StructureItem.Structure;
		AddGroups(Structure, FieldList);
	ElsIf TypeOf(StructureItem) = Type("DataCompositionTable") Then
		AddGroups(StructureItem.Rows, FieldList);
		AddGroups(StructureItem.Columns, FieldList);
	ElsIf TypeOf(StructureItem) = Type("DataCompositionChart") Then
		AddGroups(StructureItem.Series, FieldList);
		AddGroups(StructureItem.Points, FieldList);
	Else
		AddGroups(StructureItem.Structure, FieldList, ShowTableGroups);
	EndIf;
	Return FieldList;
	
EndFunction

// Finds a user setting by the parameter name.
//   If the custom setting is
//   not found (for example if the parameter
//   is not put out into the custom settings), then it receives a general parameter setting.
//
// Parameters:
//   DCSettingsComposer - DataCompositionSettingsComposer - Settings composer.
//   ParameterName          - String - Parameter description.
//
// Returns:
//   DataCompositionSettingsParameterValue - Custom setting of the parameter.
//   Undefined - If parameter is not found.
//
Function GetParameter(DCSettingsComposer, ParameterName) Export
	DCParameter = New DataCompositionParameter(ParameterName);
	
	For Each UserSetting IN DCSettingsComposer.UserSettings.Items Do
		If TypeOf(UserSetting) = Type("DataCompositionSettingsParameterValue")
			AND UserSetting.Parameter = DCParameter Then
			Return UserSetting;
		EndIf;
	EndDo;
	
	Return DCSettingsComposer.Settings.DataParameters.FindParameterValue(DCParameter);
EndFunction

// Returns a list of grouping fields of all settings linker groupings.
//
// Parameters: 
// 	SettingsComposer - Settings composer.
// 	WithoutUserFields - shows that DLS custom settings were not enabled.
//
Function GetGroupFields(SettingsComposer, WithoutUserFields = False) Export
	
	FieldList = New ValueList;
	
	Structure = SettingsComposer.Settings.Structure;
	AddGroupFields(Structure, FieldList, WithoutUserFields);
	Return FieldList;
	
EndFunction

// Returns the last item of structure - grouping.
//
// Parameters:
// 	SettingsStructureItem - structure item of data layout.
// 	Rows - shows that last grouping of rows (Series) or columns (points) was received.
//
Function GetLastStructureItem(SettingsStructureItem, Rows = True) Export
	
	If TypeOf(SettingsStructureItem) = Type("DataCompositionSettingsComposer") Then
		Settings = SettingsStructureItem.Settings;
	ElsIf TypeOf(SettingsStructureItem) = Type("DataCompositionSettings") Then
		Settings = SettingsStructureItem;
	Else
		Return Undefined;
	EndIf;
	
	Structure = Settings.Structure;
	If Structure.Count() = 0 Then
		Return Settings;
	EndIf;
	
	If Rows Then
		NameStructureTable = "Rows";
		NameStructureChart = "Series";
	Else
		NameStructureTable = "Columns";
		NameStructureChart = "Points";
	EndIf;
	
	While True Do
		StructureItem = Structure[0];
		If TypeOf(StructureItem) = Type("DataCompositionTable") AND StructureItem[NameStructureTable].Count() > 0 Then
			If StructureItem[NameStructureTable][0].Structure.Count() = 0 Then
				Structure = StructureItem[NameStructureTable];
				Break;
			EndIf;
			Structure = StructureItem[NameStructureTable][0].Structure;
		ElsIf TypeOf(StructureItem) = Type("DataCompositionChart") AND StructureItem[NameStructureChart].Count() > 0 Then
			If StructureItem[NameStructureChart][0].Structure.Count() = 0 Then
				Structure = StructureItem[NameStructureChart];
				Break;
			EndIf;
			Structure = StructureItem[NameStructureChart][0].Structure;
		ElsIf TypeOf(StructureItem) = Type("DataCompositionGroup")
			  OR TypeOf(StructureItem) = Type("DataCompositionTableGroup")
			  OR TypeOf(StructureItem) = Type("DataCompositionChartGroup") Then
			If StructureItem.Structure.Count() = 0 Then
				Break;
			EndIf;
			Structure = StructureItem.Structure;
		ElsIf TypeOf(StructureItem) = Type("DataCompositionTable") Then
			Return StructureItem[NameStructureTable];
		ElsIf TypeOf(StructureItem) = Type("DataCompositionChart")	Then
			Return StructureItem[NameStructureChart];
		Else
			Return StructureItem;
		EndIf;
	EndDo;
	
	Return Structure[0];
	
EndFunction

// Converts value of the GroupsAndItemsUse type into the GroupsAndItems type.
//  For other types returns the Auto value.
//
Function AdjustValueToGroupsAndItemsType(SourceValue) Export
	If SourceValue = FoldersAndItemsUse.Items Then
		Return FoldersAndItems.Items;
	ElsIf SourceValue = FoldersAndItemsUse.FoldersAndItems Then
		Return FoldersAndItems.FoldersAndItems;
	ElsIf SourceValue = FoldersAndItemsUse.Folders Then
		Return FoldersAndItems.Folders;
	ElsIf TypeOf(SourceValue) = Type("FoldersAndItems") Then
		Return SourceValue;
	Else
		Return FoldersAndItems.Auto;
	EndIf;
EndFunction

// Converts value of the GroupsAndItems type into the GroupsAndItemsUse type.
//  For the Auto value and other types returns the Undefined value.
//
Function AdjustValueToTypeOfFoldersAndItemsUse(SourceValue) Export
	If SourceValue = FoldersAndItems.Items Then
		Return FoldersAndItemsUse.Items;
	ElsIf SourceValue = FoldersAndItems.FoldersAndItems Then
		Return FoldersAndItemsUse.FoldersAndItems;
	ElsIf SourceValue = FoldersAndItems.Folders Then
		Return FoldersAndItemsUse.Folders;
	ElsIf TypeOf(SourceValue) = Type("FoldersAndItemsUse") Then
		Return SourceValue;
	Else
		Return Undefined;
	EndIf;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Local service procedures and functions.

// Adds inserted grouping fields.
Procedure AddGroupFields(Structure, FieldList, WithoutUserFields)
	
	For Each StructureItem IN Structure Do
		If TypeOf(StructureItem) = Type("DataCompositionTable") Then
			AddGroupFields(StructureItem.Rows, FieldList, WithoutUserFields);
			AddGroupFields(StructureItem.Columns, FieldList, WithoutUserFields);
		ElsIf TypeOf(StructureItem) = Type("DataCompositionChart") Then
			AddGroupFields(StructureItem.Series, FieldList, WithoutUserFields);
			AddGroupFields(StructureItem.Points, FieldList, WithoutUserFields);
		Else
			For Each CurrentGroupingField IN StructureItem.GroupFields.Items Do
				AvailableField = StructureItem.Selection.SelectionAvailableFields.FindField(CurrentGroupingField.Field);
				If AvailableField <> Undefined 
				  AND (AvailableField.Parent = Undefined OR Not WithoutUserFields OR AvailableField.Parent.Field <> New DataCompositionField("UserFields")) Then
					FieldList.Add(String(AvailableField.Field), AvailableField.Title);
				EndIf;
			EndDo;
			AddGroupFields(StructureItem.Structure, FieldList, WithoutUserFields);
		EndIf;
	EndDo;
	
EndProcedure

// Adds nested groups of the structure item.
Procedure AddGroups(Structure, ListOfGroups, ShowTableGroups = True)
	
	For Each StructureItem IN Structure Do
		If TypeOf(StructureItem) = Type("DataCompositionTable") Then
			AddGroups(StructureItem.Rows, ListOfGroups);
			AddGroups(StructureItem.Columns, ListOfGroups);
		ElsIf TypeOf(StructureItem) = Type("DataCompositionChart") Then
			AddGroups(StructureItem.Series, ListOfGroups);
			AddGroups(StructureItem.Points, ListOfGroups);
		Else
			ListOfGroups.Add(StructureItem);
			If ShowTableGroups Then
				AddGroups(StructureItem.Structure, ListOfGroups);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Locates the selected field of data layout by identifier.
Function FindChoiceField(SettingsItem, ID, Group)
	
	FoundChoiceField = Undefined;
	
	For Each ComboBox IN Group.Items Do
		If String(SettingsItem.GetIDByObject(ComboBox)) = ID Then
			FoundChoiceField = ComboBox;
			Break;
		EndIf;
		If TypeOf(ComboBox) = Type("DataCompositionSelectedFieldGroup") Then
			FoundChoiceField = FindChoiceField(SettingsItem, ID, ComboBox);
			If FoundChoiceField <> Undefined Then
				Break;
			EndIf;
		EndIf;
	EndDo;
	
	Return FoundChoiceField;
EndFunction

// Finds a common setting of data layout by identifier.
Function FindSettingItem(SettingItem, UserSettingID)
	// Search item with the specified UserSettingID (USI) property.
	
	GroupArray = New Array;
	GroupArray.Add(SettingItem.Items);
	
	While GroupArray.Count() > 0 Do
		
		ItemCollection = GroupArray.Get(0);
		GroupArray.Delete(0);
		
		For Each SubordinateItem IN ItemCollection Do
			If TypeOf(SubordinateItem) = Type("DataCompositionSelectedFieldGroup") Then
				// Does not contain IIT; The collection of inserted items does not contain IIT.
			ElsIf TypeOf(SubordinateItem) = Type("DataCompositionParameterValue") Then
				// Does not contain IIT; The collection of inserted items may contain IIT.
				GroupArray.Add(SubordinateItem.NestedParameterValues);
			ElsIf SubordinateItem.UserSettingID = UserSettingID Then
				// Required item is found.
				Return SubordinateItem;
			Else
				// Contains IIT; The collection of inserted items may contain IIT.
				If TypeOf(SubordinateItem) = Type("DataCompositionFilterItemGroup") Then
					GroupArray.Add(SubordinateItem.Items);
				ElsIf TypeOf(SubordinateItem) = Type("DataCompositionSettingsParameterValue") Then
					GroupArray.Add(SubordinateItem.NestedParameterValues);
				EndIf;
			EndIf;
		EndDo;
		
	EndDo;
	
	Return Undefined;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// For work with the frequency mechanism.

// Returns a date of the period start.
Function ReportPeriodStart(PeriodKind, PeriodDate) Export
	BeginOfPeriod = PeriodDate;
	
	If PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.Custom") Then
		// Action is not required
	ElsIf PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.Year") Then
		BeginOfPeriod = BegOfYear(PeriodDate);
	ElsIf PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.HalfYear") Then
		If Month(PeriodDate) >= 7 Then
			BeginOfPeriod = Date(Year(PeriodDate), 7, 1);
		Else
			BeginOfPeriod = Date(Year(PeriodDate), 1, 1);
		EndIf;
	ElsIf PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.Quarter") Then
		BeginOfPeriod = BegOfQuarter(PeriodDate);
	ElsIf PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.Month") Then
		BeginOfPeriod = BegOfMonth(PeriodDate);
	ElsIf PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.TenDays") Then
		If Day(PeriodDate) <= 10 Then
			BeginOfPeriod = Date(Year(PeriodDate), Month(PeriodDate), 1);
		ElsIf Day(PeriodDate) <= 20 Then
			BeginOfPeriod = Date(Year(PeriodDate), Month(PeriodDate), 11);
		Else
			BeginOfPeriod = Date(Year(PeriodDate), Month(PeriodDate), 21);
		EndIf;
	ElsIf PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.Week") Then
		BeginOfPeriod = BegOfWeek(PeriodDate);
	ElsIf PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.Day") Then
		BeginOfPeriod = BegOfDay(PeriodDate);
	EndIf;
	
	Return BeginOfPeriod;
	
EndFunction

// Returns a date of the period end.
Function ReportEndOfPeriod(PeriodKind, PeriodDate) Export
	EndOfPeriod = PeriodDate;
	
	If PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.Custom") Then
		// Action is not required
	ElsIf PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.Year") Then
		EndOfPeriod = EndOfYear(PeriodDate);
	ElsIf PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.HalfYear") Then
		If Month(PeriodDate) >= 7 Then
			EndOfPeriod = EndOfYear(PeriodDate);
		Else
			EndOfPeriod = EndOfDay(Date(Year(PeriodDate), 6, 30));
		EndIf;
	ElsIf PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.Quarter") Then
		EndOfPeriod = EndOfQuarter(PeriodDate);
	ElsIf PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.Month") Then
		EndOfPeriod = EndOfMonth(PeriodDate);
	ElsIf PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.TenDays") Then
		If Day(PeriodDate) <= 10 Then
			EndOfPeriod = EndOfDay(Date(Year(PeriodDate), Month(PeriodDate), 10));
		ElsIf Day(PeriodDate) <= 20 Then
			EndOfPeriod = EndOfDay(Date(Year(PeriodDate), Month(PeriodDate), 20));
		Else
			EndOfPeriod = EndOfMonth(PeriodDate);
		EndIf;
	ElsIf PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.Week") Then
		EndOfPeriod = EndOfWeek(PeriodDate);
	ElsIf PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.Day") Then
		EndOfPeriod = EndOfDay(PeriodDate);
	EndIf;
	
	Return EndOfPeriod;
	
EndFunction

// Returns a list of periods in the range of period beginning.
Function FixedPeriodsList(Val BeginOfPeriod, PeriodKind) Export
	PeriodsList = New ValueList;
	
	If BeginOfPeriod = '00010101' Then
		Return PeriodsList;
	EndIf;
	
	BeginOfPeriod = BegOfDay(BeginOfPeriod);
	SelectionOfRelativePeriod = (BeginOfPeriod = "SelectionOfRelativePeriod");
	ShowAllComparativePeriods = False;
	
	#If Client Then
		Today = CommonUseClient.SessionDate();
	#Else
		Today = CurrentSessionDate();
	#EndIf
	Today = BegOfDay(Today);
	
	NavigationPointItemPreviouslyPresentation = NStr("en='Previously...';ru='Раньше ...';vi='Trước đây...'");
	NavigationPointLaterPresentation = NStr("en='Later ...';ru='Позже...';vi='Muộn hơn...'");
	
	If PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.Day") Then
		CurrentDayOfWeek   = WeekDay(Today);
		SelectedWeekDay = WeekDay(BeginOfPeriod);
		
		// Calculation of initial and ending period according to the formula.
		WeekStartDay = CurrentDayOfWeek - 5;
		WeekFinalDay  = CurrentDayOfWeek + 1;
		If SelectedWeekDay > WeekFinalDay Then
			SelectedWeekDay = SelectedWeekDay - 7;
		EndIf;
		
		Period = BeginOfPeriod - 86400 * (SelectedWeekDay - WeekStartDay);
		
		// Add the <Earlier> navigation point..." for transition to earlier periods.
		PeriodsList.Add(Period - 86400 * 7, NavigationPointItemPreviouslyPresentation);
		
		// Values adding.
		For Counter = 1 To 7 Do
			PeriodsList.Add(Period, Format(Period, "DF='dd MMMM yyyy, dddd'") + ?(Period = Today, " - " + NStr("en='today';ru='сегодня';vi='hôm nay'"), ""));
			Period = Period + 86400;
		EndDo;
		
		// Add the <Later> navigation point..." for transition to later periods.
		PeriodsList.Add(Period + 86400 * 6, NavigationPointLaterPresentation);
		
	ElsIf PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.Week") Then
		CurrentWeekBeginning   = BegOfWeek(Today);
		SelectedWeekBegin = BegOfWeek(BeginOfPeriod);
		
		// Calculation of initial and ending period according to the formula.
		DifferenceWeeks = (SelectedWeekBegin - CurrentWeekBeginning) / 604800;
		Factor = (DifferenceWeeks - 2)/7;
		Factor = Int(Factor - ?(Factor < 0, 0.9, 0)); // Negative numbers are rounded up.
		InitialWeek = CurrentWeekBeginning + (2 + Factor*7) * 604800;
		
		// Add the <Earlier> navigation point..." for transition to earlier periods.
		PeriodsList.Add(InitialWeek - 7 * 604800, NavigationPointItemPreviouslyPresentation);
		
		// Values adding.
		For Counter = 0 To 6 Do
			Period = InitialWeek + Counter * 604800;
			EndOfPeriod  = EndOfWeek(Period);
			PeriodPresentation = Format(Period, "DF=dd.MM") + " - " + Format(EndOfPeriod, "DLF=D") + " (" + WeekOfYear(EndOfPeriod) + " " + NStr("en='week of the year';ru='неделя года';vi='tuần năm'") + ")";
			If Period = CurrentWeekBeginning Then
				PeriodPresentation = PeriodPresentation + " - " + NStr("en='this week';ru='эта неделя';vi='tuần này'");
			EndIf;
			PeriodsList.Add(Period, PeriodPresentation);
		EndDo;
		
		// Add the <Later> navigation point..." for transition to later periods.
		PeriodsList.Add(InitialWeek + 13 * 604800, NavigationPointLaterPresentation);
		
	ElsIf PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.TenDays") Then
		CurrentYear   = Year(Today);
		SelectedYear = Year(BeginOfPeriod);
		CurrentMonth   = Month(Today);
		SelectedMonth = Month(BeginOfPeriod);
		CurrentDay   = Day(Today);
		SelectedDay = Day(BeginOfPeriod);
		CurrentTenDays   = ?(CurrentDay   <= 10, 1, ?(CurrentDay   <= 20, 2, 3));
		SelectedDecade = ?(SelectedDay <= 10, 1, ?(SelectedDay <= 20, 2, 3));
		CurrentTenDaysTotally   = CurrentYear*36 + (CurrentMonth-1)*3 + (CurrentTenDays-1);
		SelectedDecadeAbsolutely = SelectedYear*36 + (SelectedMonth-1)*3 + (SelectedDecade-1);
		StringTenDays = NStr("en='ten-day period';ru='декада';vi='10 ngày'");
		
		// Calculation of initial and ending period according to the formula.
		Factor = (SelectedDecadeAbsolutely - CurrentTenDaysTotally - 2)/7;
		Factor = Int(Factor - ?(Factor < 0, 0.9, 0)); // Negative numbers are rounded up.
		InitialTenDays = CurrentTenDaysTotally + 2 + Factor*7;
		FinalDecade  = InitialTenDays + 6;
		
		// Add the <Earlier> navigation point..." for transition to earlier periods.
		TenDays = InitialTenDays - 7;
		Year = Int(TenDays/36);
		DecadeInYear = TenDays - Year*36;
		MonthInYear = Int(DecadeInYear/3) + 1;
		DecadeInMonth = DecadeInYear - (MonthInYear-1)*3 + 1;
		Period = Date(Year, MonthInYear, (DecadeInMonth - 1) * 10 + 1);
		PeriodsList.Add(Period, NavigationPointItemPreviouslyPresentation);
		
		// Values adding.
		For TenDays = InitialTenDays To FinalDecade Do
			Year = Int(TenDays/36);
			DecadeInYear = TenDays - Year*36;
			MonthInYear = Int(DecadeInYear/3) + 1;
			DecadeInMonth = DecadeInYear - (MonthInYear-1)*3 + 1;
			Period = Date(Year, MonthInYear, (DecadeInMonth - 1) * 10 + 1);
			Presentation = Format(Period, "DF='MMMM yyyy'") + ", " + Left("III", DecadeInMonth) + " " + StringTenDays + ?(TenDays = CurrentTenDaysTotally, " - " + NStr("en='this ten-day period';ru='эта декада';vi='mười ngày này'"), "");
			PeriodsList.Add(Period, Presentation);
		EndDo;
		
		// Add the <Later> navigation point..." for transition to later periods.
		TenDays = FinalDecade + 1;
		Year = Int(TenDays/36);
		DecadeInYear = TenDays - Year*36;
		MonthInYear = Int(DecadeInYear/3) + 1;
		DecadeInMonth = DecadeInYear - (MonthInYear-1)*3 + 1;
		Period = Date(Year, MonthInYear, (DecadeInMonth - 1) * 10 + 1);
		PeriodsList.Add(Period, NavigationPointLaterPresentation);
		
	ElsIf PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.Month") Then
		CurrentYear   = Year(Today);
		SelectedYear = Year(BeginOfPeriod);
		CurrentMonth   = CurrentYear*12   + Month(Today);
		SelectedMonth = SelectedYear*12 + Month(BeginOfPeriod);
		
		// Calculation of initial and ending period according to the formula.
		Factor = (SelectedMonth - CurrentMonth - 2)/7;
		Factor = Int(Factor - ?(Factor < 0, 0.9, 0)); // Negative numbers are rounded up.
		InitialMonth = CurrentMonth + 2 + Factor*7;
		EndMonth  = InitialMonth + 6;
		
		// Add the <Earlier> navigation point..." for transition to earlier periods.
		Month = InitialMonth - 7;
		Year = Int((Month - 1) / 12);
		MonthInYear = Month - Year * 12;
		Period = Date(Year, MonthInYear, 1);
		PeriodsList.Add(Period, NavigationPointItemPreviouslyPresentation);
		
		// Values adding.
		For Month = InitialMonth To EndMonth Do
			Year = Int((Month - 1) / 12);
			MonthInYear = Month - Year * 12;
			Period = Date(Year, MonthInYear, 1);
			PeriodsList.Add(Period, Format(Period, "DF='MMMM yyyy'") + ?(Year = CurrentYear AND CurrentMonth = Month, " - " + NStr("en='this month';ru='этот месяц';vi='tháng này'"), ""));
		EndDo;
		
		// Add the <Later> navigation point..." for transition to later periods.
		Month = EndMonth + 1;
		Year = Int((Month - 1) / 12);
		MonthInYear = Month - Year * 12;
		Period = Date(Year, MonthInYear, 1);
		PeriodsList.Add(Period, NavigationPointLaterPresentation);
		
	ElsIf PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.Quarter") Then
		CurrentYear = Year(Today);
		SelectedYear = Year(BeginOfPeriod);
		CurrentQuarter   = 1 + Int((Month(Today)-1)/3);
		SelectedQuarter = 1 + Int((Month(BeginOfPeriod)-1)/3);
		CurrentQuarterAbsolutely   = CurrentYear*4   + CurrentQuarter   - 1;
		SelectedQuarterAbsolutely = SelectedYear*4 + SelectedQuarter - 1;
		RowQuarter = NStr("en='quarter';ru='квартал';vi='quý'");
		
		// Calculation of initial and ending period according to the formula.
		Factor = (SelectedQuarterAbsolutely - CurrentQuarterAbsolutely - 2)/7;
		Factor = Int(Factor - ?(Factor < 0, 0.9, 0)); // Negative numbers are rounded up.
		InitialQuarter = CurrentQuarterAbsolutely + 2 + Factor*7;
		FinalQuarter  = InitialQuarter + 6;
		
		// Add the <Earlier> navigation point..." for transition to earlier periods.
		Quarter = InitialQuarter - 7;
		Year = Int(Quarter/4);
		QuarterInYear = Quarter - Year*4 + 1;
		MonthInYear = (QuarterInYear-1)*3 + 1;
		Period = Date(Year, MonthInYear, 1);
		PeriodsList.Add(Period, NavigationPointItemPreviouslyPresentation);
		
		// Values adding.
		For Quarter = InitialQuarter To FinalQuarter Do
			Year = Int(Quarter/4);
			QuarterInYear = Quarter - Year*4 + 1;
			MonthInYear = (QuarterInYear-1)*3 + 1;
			Period = Date(Year, MonthInYear, 1);
			Presentation = ?(QuarterInYear = 4, "IV", Left("III", QuarterInYear)) + " " + RowQuarter + " " + Format(Period, "DF='yyyy'") + ?(Quarter = CurrentQuarterAbsolutely, " - " + NStr("en='this quarter';ru='этот квартал';vi='quý này'"), "");
			PeriodsList.Add(Period, Presentation);
		EndDo;
		
		// Add the <Later> navigation point..." for transition to later periods.
		Quarter = FinalQuarter + 1;
		Year = Int(Quarter/4);
		QuarterInYear = Quarter - Year*4 + 1;
		MonthInYear = (QuarterInYear-1)*3 + 1;
		Period = Date(Year, MonthInYear, 1);
		PeriodsList.Add(Period, NavigationPointLaterPresentation);
		
	ElsIf PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.HalfYear") Then
		CurrentYear = Year(Today);
		SelectedYear = Year(BeginOfPeriod);
		CurrentHalfYear   = 1 + Int((Month(Today)-1)/6);
		SelectedHalfyear = 1 + Int((Month(BeginOfPeriod)-1)/6);
		CurrentHalfyearAbsolutely   = CurrentYear*2   + CurrentHalfYear   - 1;
		HalfYearIsAbsolutely = SelectedYear*2 + SelectedHalfyear - 1;
		StringHalfYear = NStr("en='half';ru='половина';vi='một nửa'");
		
		// Calculation of initial and ending period according to the formula.
		Factor = (HalfYearIsAbsolutely - CurrentHalfyearAbsolutely - 2)/7;
		Factor = Int(Factor - ?(Factor < 0, 0.9, 0)); // Negative numbers are rounded up.
		InitialHalfYear = CurrentHalfyearAbsolutely + 2 + Factor*7;
		FinalHalfyear  = InitialHalfYear + 6;
		
		// Add the <Earlier> navigation point..." for transition to earlier periods.
		HalfYear = InitialHalfYear - 7;
		Year = Int(HalfYear/2);
		HalfInYear = HalfYear - Year*2 + 1;
		MonthInYear = (HalfInYear-1)*6 + 1;
		Period = Date(Year, MonthInYear, 1);
		PeriodsList.Add(Period, NavigationPointItemPreviouslyPresentation);
		
		// Values adding.
		For HalfYear = InitialHalfYear To FinalHalfyear Do
			Year = Int(HalfYear/2);
			HalfInYear = HalfYear - Year*2 + 1;
			MonthInYear = (HalfInYear-1)*6 + 1;
			Period = Date(Year, MonthInYear, 1);
			Presentation = Left("II", HalfInYear) + " " + StringHalfYear + " " + Format(Period, "DF='yyyy'") + ?(HalfYear = CurrentHalfyearAbsolutely, " - " + NStr("en='this half-year';ru='это полугодие';vi='nửa năm này'"), "");
			PeriodsList.Add(Period, Presentation);
		EndDo;
		
		// Add the <Later> navigation point..." for transition to later periods.
		HalfYear = FinalHalfyear + 1;
		Year = Int(HalfYear/2);
		HalfInYear = HalfYear - Year*2 + 1;
		MonthInYear = (HalfInYear-1)*6 + 1;
		Period = Date(Year, MonthInYear, 1);
		PeriodsList.Add(Period, NavigationPointLaterPresentation);
		
	ElsIf PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.Year") Then
		CurrentYear = Year(Today);
		SelectedYear = Year(BeginOfPeriod);
		
		// Calculation of initial and ending period according to the formula.
		Factor = (SelectedYear - CurrentYear - 2)/7;
		Factor = Int(Factor - ?(Factor < 0, 0.9, 0)); // Negative numbers are rounded up.
		InitialYear = CurrentYear + 2 + Factor*7;
		FinalYear = InitialYear + 6;
		
		// Add the <Earlier> navigation point..." for transition to earlier periods.
		PeriodsList.Add(Date(InitialYear-7, 1, 1), NavigationPointItemPreviouslyPresentation);
		
		// Values adding.
		For Year = InitialYear To FinalYear Do
			PeriodsList.Add(Date(Year, 1, 1), Format(Year, "NG=") + ?(Year = CurrentYear, " - " + NStr("en='this year';ru='этот год';vi='năm nay'"), ""));
		EndDo;
		
		// Add the <Later> navigation point..." for transition to later periods.
		PeriodsList.Add(Date(FinalYear+7, 1, 1), NavigationPointLaterPresentation);
		
	EndIf;
	
	Return PeriodsList;
EndFunction

// Returns a list of periods in the range of period beginning.
Function CalculatingPeriodsList(PeriodKind) Export
	
	PeriodsList = New ValueList;
	
	If PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.Day") Then
		PeriodsList.Add(StandardPeriodVariant.Yesterday);
		PeriodsList.Add(StandardPeriodVariant.Today);
		PeriodsList.Add(StandardPeriodVariant.Tomorrow);
	ElsIf PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.Week") Then
		PeriodsList.Add(StandardPeriodVariant.LastWeek);
		PeriodsList.Add(StandardPeriodVariant.LastWeekTillSameWeekDay);
		PeriodsList.Add(StandardPeriodVariant.Last7Days);
		PeriodsList.Add(StandardPeriodVariant.ThisWeek);
		PeriodsList.Add(StandardPeriodVariant.FromBeginningOfThisWeek);
		PeriodsList.Add(StandardPeriodVariant.TillEndOfThisWeek);
		PeriodsList.Add(StandardPeriodVariant.NextWeek);
		PeriodsList.Add(StandardPeriodVariant.NextWeekTillSameWeekDay);
		PeriodsList.Add(StandardPeriodVariant.Next7Days);
	ElsIf PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.TenDays") Then
		PeriodsList.Add(StandardPeriodVariant.LastTenDays);
		PeriodsList.Add(StandardPeriodVariant.LastTenDaysTillSameDayNumber);
		PeriodsList.Add(StandardPeriodVariant.ThisTenDays);
		PeriodsList.Add(StandardPeriodVariant.FromBeginningOfThisTenDays);
		PeriodsList.Add(StandardPeriodVariant.TillEndOfThisTenDays);
		PeriodsList.Add(StandardPeriodVariant.NextTenDays);
		PeriodsList.Add(StandardPeriodVariant.NextTenDaysTillSameDayNumber);
	ElsIf PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.Month") Then
		PeriodsList.Add(StandardPeriodVariant.LastMonth);
		PeriodsList.Add(StandardPeriodVariant.LastMonthTillSameDate);
		PeriodsList.Add(StandardPeriodVariant.Month, NStr("en='From the same date of the previous month';ru='С такой же даты прошлого месяца';vi='Từ ngày này của tháng trước'"));
		PeriodsList.Add(StandardPeriodVariant.ThisMonth);
		PeriodsList.Add(StandardPeriodVariant.FromBeginningOfThisMonth);
		PeriodsList.Add(StandardPeriodVariant.TillEndOfThisMonth);
		PeriodsList.Add(StandardPeriodVariant.NextMonth);
		PeriodsList.Add(StandardPeriodVariant.NextMonthTillSameDate);
	ElsIf PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.Quarter") Then
		PeriodsList.Add(StandardPeriodVariant.LastQuarter);
		PeriodsList.Add(StandardPeriodVariant.LastQuarterTillSameDate);
		PeriodsList.Add(StandardPeriodVariant.ThisQuarter);
		PeriodsList.Add(StandardPeriodVariant.FromBeginningOfThisQuarter);
		PeriodsList.Add(StandardPeriodVariant.TillEndOfThisQuarter);
		PeriodsList.Add(StandardPeriodVariant.NextQuarter);
		PeriodsList.Add(StandardPeriodVariant.NextQuarterTillSameDate);
	ElsIf PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.HalfYear") Then
		PeriodsList.Add(StandardPeriodVariant.LastHalfYear);
		PeriodsList.Add(StandardPeriodVariant.ThisHalfYear);
		PeriodsList.Add(StandardPeriodVariant.NextHalfYear);
		PeriodsList.Add(StandardPeriodVariant.FromBeginningOfThisHalfYear);
		PeriodsList.Add(StandardPeriodVariant.TillEndOfThisHalfYear);
		PeriodsList.Add(StandardPeriodVariant.LastHalfYearTillSameDate);
		PeriodsList.Add(StandardPeriodVariant.NextHalfYearTillSameDate);
	ElsIf PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.Year") Then
		PeriodsList.Add(StandardPeriodVariant.LastYear);
		PeriodsList.Add(StandardPeriodVariant.LastYearTillSameDate);
		PeriodsList.Add(StandardPeriodVariant.ThisYear);
		PeriodsList.Add(StandardPeriodVariant.FromBeginningOfThisYear);
		PeriodsList.Add(StandardPeriodVariant.TillEndOfThisYear);
		PeriodsList.Add(StandardPeriodVariant.NextYear);
		PeriodsList.Add(StandardPeriodVariant.NextYearTillSameDate);
	EndIf;
	
	Return PeriodsList;
	
EndFunction

// Returns presentation of a period using its kind and specified value.
Function PresentationStandardPeriod(StandardPeriod, PeriodKind) Export
	
	If StandardPeriod.Variant = StandardPeriodVariant.Month Then
		Return NStr("en='From the same date of the previous month';ru='С такой же даты прошлого месяца';vi='Từ ngày này của tháng trước'");
	ElsIf StandardPeriod.Variant <> StandardPeriodVariant.Custom Then
		Return String(StandardPeriod.Variant);
	EndIf;
	
	If PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.Custom") Then
		Return Format(StandardPeriod.StartDate, "DF=dd MMMM yyyy'") + " - " + Format(StandardPeriod.EndDate, "DF=dd MMMM yyyy'");
	EndIf;
	
	PeriodsList = FixedPeriodsList(StandardPeriod.StartDate, PeriodKind);
	ItemOfList = PeriodsList.FindByValue(StandardPeriod.StartDate);
	If ItemOfList <> Undefined Then
		Return ItemOfList.Presentation;
	EndIf;
	
	Return "";
	
EndFunction

// Returns a period kind.
Function GetPeriodKind(BeginOfPeriod, EndOfPeriod, AvailablePeriods = Undefined) Export
	
	PeriodKind = Undefined;
	If BeginOfPeriod = BegOfDay(BeginOfPeriod)
		AND EndOfPeriod = EndOfDay(EndOfPeriod) Then
		
		DaysDifference = (EndOfPeriod - BeginOfPeriod + 1) / (60*60*24);
		If DaysDifference = 1 Then
			
			PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.Day");
			
		ElsIf DaysDifference = 7 Then
			
			If BeginOfPeriod = BegOfWeek(BeginOfPeriod) Then
				PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.Week");
			EndIf;
			
		ElsIf DaysDifference <= 11 Then
			
			If (Day(BeginOfPeriod) = 1 AND Day(EndOfPeriod) = 10)
				OR (Day(BeginOfPeriod) = 11 AND Day(EndOfPeriod) = 20)
				OR (Day(BeginOfPeriod) = 21 AND EndOfPeriod = EndOfMonth(BeginOfPeriod)) Then
				PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.TenDays");
			EndIf;
			
		ElsIf DaysDifference <= 31 Then
			
			If BeginOfPeriod = BegOfMonth(BeginOfPeriod) AND EndOfPeriod = EndOfMonth(BeginOfPeriod) Then
				PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.Month");
			EndIf;
			
		ElsIf DaysDifference <= 92 Then
			
			If BeginOfPeriod = BegOfQuarter(BeginOfPeriod) AND EndOfPeriod = EndOfQuarter(BeginOfPeriod) Then
				PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.Quarter");
			EndIf;
			
		ElsIf DaysDifference <= 190 Then
			
			If Month(BeginOfPeriod) + 5 = Month(EndOfPeriod)
				AND BeginOfPeriod = BegOfMonth(BeginOfPeriod)
				AND EndOfPeriod = EndOfMonth(EndOfPeriod)
				AND (BeginOfPeriod = BegOfYear(BeginOfPeriod) OR EndOfPeriod = EndOfYear(BeginOfPeriod)) Then
				PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.HalfYear");
			EndIf;
			
		ElsIf DaysDifference <= 366 Then
			
			If BeginOfPeriod = BegOfYear(BeginOfPeriod) AND EndOfPeriod = EndOfYear(BeginOfPeriod) Then
				PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.Year");
			EndIf;
			
		EndIf;
	EndIf;
	
	If PeriodKind = Undefined Then
		PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.Custom");
	EndIf;
	
	If AvailablePeriods <> Undefined AND AvailablePeriods.FindByValue(PeriodKind) = Undefined Then
		PeriodKind = AvailablePeriods[0].Value;
	EndIf;
	
	Return PeriodKind;
	
EndFunction

// Returns a period kind. Unlike the GetPeriodKind function in output takes StandardPeriod.
Function GetKindOfStandardPeriod(StandardPeriod, AvailablePeriods = Undefined) Export
	
	If StandardPeriod.Variant = StandardPeriodVariant.Custom Then
		
		Return GetPeriodKind(StandardPeriod.StartDate, StandardPeriod.EndDate, AvailablePeriods);
		
	ElsIf StandardPeriod.Variant = StandardPeriodVariant.ThisYear
		Or StandardPeriod.Variant = StandardPeriodVariant.LastYear
		Or StandardPeriod.Variant = StandardPeriodVariant.NextYear
		Or StandardPeriod.Variant = StandardPeriodVariant.FromBeginningOfThisYear
		Or StandardPeriod.Variant = StandardPeriodVariant.TillEndOfThisYear
		Or StandardPeriod.Variant = StandardPeriodVariant.LastYearTillSameDate
		Or StandardPeriod.Variant = StandardPeriodVariant.NextYearTillSameDate Then
		
		Return PredefinedValue("Enum.AvailableReportPeriods.Year");
		
	ElsIf StandardPeriod.Variant = StandardPeriodVariant.ThisHalfYear
		Or StandardPeriod.Variant = StandardPeriodVariant.LastHalfYear
		Or StandardPeriod.Variant = StandardPeriodVariant.NextHalfYear
		Or StandardPeriod.Variant = StandardPeriodVariant.FromBeginningOfThisHalfYear
		Or StandardPeriod.Variant = StandardPeriodVariant.TillEndOfThisHalfYear
		Or StandardPeriod.Variant = StandardPeriodVariant.LastHalfYearTillSameDate
		Or StandardPeriod.Variant = StandardPeriodVariant.NextHalfYearTillSameDate Then
		
		Return PredefinedValue("Enum.AvailableReportPeriods.HalfYear");
		
	ElsIf StandardPeriod.Variant = StandardPeriodVariant.ThisQuarter
		Or StandardPeriod.Variant = StandardPeriodVariant.LastQuarter
		Or StandardPeriod.Variant = StandardPeriodVariant.NextQuarter
		Or StandardPeriod.Variant = StandardPeriodVariant.FromBeginningOfThisQuarter
		Or StandardPeriod.Variant = StandardPeriodVariant.TillEndOfThisQuarter
		Or StandardPeriod.Variant = StandardPeriodVariant.LastQuarterTillSameDate
		Or StandardPeriod.Variant = StandardPeriodVariant.NextQuarterTillSameDate Then
		
		Return PredefinedValue("Enum.AvailableReportPeriods.Quarter");
		
	ElsIf StandardPeriod.Variant = StandardPeriodVariant.ThisMonth
		Or StandardPeriod.Variant = StandardPeriodVariant.LastMonth
		Or StandardPeriod.Variant = StandardPeriodVariant.NextMonth
		Or StandardPeriod.Variant = StandardPeriodVariant.Month
		Or StandardPeriod.Variant = StandardPeriodVariant.FromBeginningOfThisMonth
		Or StandardPeriod.Variant = StandardPeriodVariant.TillEndOfThisMonth
		Or StandardPeriod.Variant = StandardPeriodVariant.LastMonthTillSameDate
		Or StandardPeriod.Variant = StandardPeriodVariant.NextMonthTillSameDate Then
		
		Return PredefinedValue("Enum.AvailableReportPeriods.Month");
		
	ElsIf StandardPeriod.Variant = StandardPeriodVariant.ThisTenDays
		Or StandardPeriod.Variant = StandardPeriodVariant.LastTenDays
		Or StandardPeriod.Variant = StandardPeriodVariant.NextTenDays
		Or StandardPeriod.Variant = StandardPeriodVariant.FromBeginningOfThisTenDays
		Or StandardPeriod.Variant = StandardPeriodVariant.TillEndOfThisTenDays
		Or StandardPeriod.Variant = StandardPeriodVariant.LastTenDaysTillSameDayNumber
		Or StandardPeriod.Variant = StandardPeriodVariant.NextTenDaysTillSameDayNumber Then
		
		Return PredefinedValue("Enum.AvailableReportPeriods.TenDays");
		
	ElsIf StandardPeriod.Variant = StandardPeriodVariant.ThisWeek
		Or StandardPeriod.Variant = StandardPeriodVariant.LastWeek
		Or StandardPeriod.Variant = StandardPeriodVariant.NextWeek
		Or StandardPeriod.Variant = StandardPeriodVariant.FromBeginningOfThisWeek
		Or StandardPeriod.Variant = StandardPeriodVariant.TillEndOfThisWeek
		Or StandardPeriod.Variant = StandardPeriodVariant.Last7Days
		Or StandardPeriod.Variant = StandardPeriodVariant.Next7Days
		Or StandardPeriod.Variant = StandardPeriodVariant.LastWeekTillSameWeekDay
		Or StandardPeriod.Variant = StandardPeriodVariant.NextWeekTillSameWeekDay Then
		
		Return PredefinedValue("Enum.AvailableReportPeriods.Week");
		
	ElsIf StandardPeriod.Variant = StandardPeriodVariant.Today
		Or StandardPeriod.Variant = StandardPeriodVariant.Yesterday
		Or StandardPeriod.Variant = StandardPeriodVariant.Tomorrow Then
		
		Return PredefinedValue("Enum.AvailableReportPeriods.Day");
		
	EndIf;
	
EndFunction

// Returns available periods by ascending periodicity.
Function GetAvailablePeriodsList() Export
	
	AvailablePeriodsList = New Array;
	AvailablePeriodsList.Add(PredefinedValue("Enum.AvailableReportPeriods.Day"));
	AvailablePeriodsList.Add(PredefinedValue("Enum.AvailableReportPeriods.Week"));
	AvailablePeriodsList.Add(PredefinedValue("Enum.AvailableReportPeriods.TenDays"));
	AvailablePeriodsList.Add(PredefinedValue("Enum.AvailableReportPeriods.Month"));
	AvailablePeriodsList.Add(PredefinedValue("Enum.AvailableReportPeriods.Quarter"));
	AvailablePeriodsList.Add(PredefinedValue("Enum.AvailableReportPeriods.HalfYear"));
	AvailablePeriodsList.Add(PredefinedValue("Enum.AvailableReportPeriods.Year"));
	AvailablePeriodsList.Add(PredefinedValue("Enum.AvailableReportPeriods.Custom"));
	
	Return AvailablePeriodsList;
	
EndFunction

// Converts value of the AvailableCountdownPeriods enumeration into the standard period variant.
Function SetPeriodKindToStandard(PeriodKind) Export
	
	If PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.Day") Then
		Return StandardPeriodVariant.Today;
	ElsIf PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.Week") Then
		Return StandardPeriodVariant.ThisWeek;
	ElsIf PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.TenDays") Then
		Return StandardPeriodVariant.ThisTenDays;
	ElsIf PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.Month") Then
		Return StandardPeriodVariant.ThisMonth;
	ElsIf PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.Quarter") Then
		Return StandardPeriodVariant.ThisQuarter;
	ElsIf PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.HalfYear") Then
		Return StandardPeriodVariant.ThisHalfYear;
	ElsIf PeriodKind = PredefinedValue("Enum.AvailableReportPeriods.Year") Then
		Return StandardPeriodVariant.ThisYear;
	EndIf;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Unification of the report form and the report settings form.

Function SettingsComposer(Form) Export
	If Form.FormName = "SettingsStorage.ReportsVariantsStorage.Form.ReportSettings" Then
		Return Form.SettingsComposer;
	Else
		Return Form.Report.SettingsComposer;
	EndIf;
EndFunction

Function PathToSettingsLinker(Form) Export
	If Form.FormName = "SettingsStorage.ReportsVariantsStorage.Form.ReportSettings" Then
		Return "SettingsComposer";
	Else
		Return "Report.SettingsComposer";
	EndIf;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Other

Function RowSettingType(Type) Export
	If Type = Type("DataCompositionSettings") Then
		Return "Settings";
	ElsIf Type = Type("DataCompositionNestedObjectSettings") Then
		Return "NestedObjectSettings";
	
	ElsIf Type = Type("DataCompositionFilter") Then
		Return "Filter";
	ElsIf Type = Type("DataCompositionFilterItem") Then
		Return "FilterItem";
	ElsIf Type = Type("DataCompositionFilterItemGroup") Then
		Return "FilterItemGroup";
	
	ElsIf Type = Type("DataCompositionSettingsParameterValue") Then
		Return "SettingsParameterValue";
	
	ElsIf Type = Type("DataCompositionGroup") Then
		Return "Group";
	ElsIf Type = Type("DataCompositionOrder") Then
		Return "Order";
	ElsIf Type = Type("DataCompositionSelectedFields") Then
		Return "SelectedFields";
	
	ElsIf Type = Type("DataCompositionConditionalAppearance") Then
		Return "ConditionalAppearance";
	ElsIf Type = Type("DataCompositionConditionalAppearanceItem") Then
		Return "ConditionalAppearanceItem";
	
	ElsIf Type = Type("DataCompositionSettingStructure") Then
		Return "SettingsStructure";
	ElsIf Type = Type("DataCompositionSettingStructureItemCollection") Then
		Return "SettingsStructureItemCollection";
	
	ElsIf Type = Type("DataCompositionTable") Then
		Return "Table";
	ElsIf Type = Type("DataCompositionTableGroup") Then
		Return "TableGrouping";
	ElsIf Type = Type("DataCompositionTableStructureItemCollection") Then
		Return "StructureTableItemsCollection";
	
	ElsIf Type = Type("DataCompositionChart") Then
		Return "Chart";
	ElsIf Type = Type("DataCompositionChartGroup") Then
		Return "ChartGrouping";
	ElsIf Type = Type("DataCompositionChartStructureItemCollection") Then
		Return "ChartStructureItemsCollection";
	
	ElsIf Type = Type("DataCompositionGroupField") Then
		Return "GroupingField";
	ElsIf Type = Type("DataCompositionGroupFields") Then
		Return "GroupFields";
	ElsIf Type = Type("DataCompositionGroupFieldCollection") Then
		Return "CollectionGroupFields";
	
	Else
		Return "";
	EndIf;
EndFunction

Function CopyRecursive(Node, WhatCopy, WhereInsert, IndexOf, Map) Export
	PointType = TypeOf(WhatCopy);
	ParametersOfCopying = ParametersOfCopying(PointType, WhereInsert);
	
	If ParametersOfCopying.NeedToSpecifyPointType Then
		If IndexOf = Undefined Then
			NewRow = WhereInsert.Add(PointType);
		Else
			IndexOf = IndexOf + 1;
			NewRow = WhereInsert.Insert(IndexOf, PointType);
		EndIf;
	Else
		If IndexOf = Undefined Then
			NewRow = WhereInsert.Add();
		Else
			IndexOf = IndexOf + 1;
			NewRow = WhereInsert.Insert(IndexOf);
		EndIf;
	EndIf;
	
	If ParametersOfCopying.ExcludingProperties <> "*" Then
		FillPropertyValues(NewRow, WhatCopy, , ParametersOfCopying.ExcludingProperties);
	EndIf;
	
	If ParametersOfCopying.FormTreeFormed Then
		
		Map.Insert(WhatCopy, NewRow);
		
		NestedCollection = WhatCopy.GetItems();
		If NestedCollection.Count() > 0 Then
			NewNestedCollection = NewRow.GetItems();
			For Each SubordinatedRow IN NestedCollection Do
				CopyRecursive(Node, SubordinatedRow, NewNestedCollection, Undefined, Map);
			EndDo;
		EndIf;
		
	Else
		
		OutdatedIdentifier = Node.GetIDByObject(WhatCopy);
		NewIdentifier = Node.GetIDByObject(NewRow);
		Map.Insert(OutdatedIdentifier, NewIdentifier);
		
		If ParametersOfCopying.IsSettings Then
			NewRow = NewRow.Settings;
			SubordinatedRow = SubordinatedRow.Settings;
		EndIf;
		
		If ParametersOfCopying.HasItems Then
			//   Items
			//       (FieldsDataLayoutSelectedCollection, DataLayoutFilterItemsCollection)
			NestedCollection = WhatCopy.Items;
			If NestedCollection.Count() > 0 Then
				NewNestedCollection = NewRow.Items;
				For Each SubordinatedRow IN NestedCollection Do
					CopyRecursive(Node, SubordinatedRow, NewNestedCollection, Undefined, Map);
				EndDo;
			EndIf;
		EndIf;
		
		If ParametersOfCopying.HasSelection Then
			//   Selection
			//   (DataLayoutSelectedFields) Selection.Items (DataLayoutSelectedFieldsCollection)
			FillPropertyValues(NewRow.Selection, WhatCopy.Selection, , "SelectionAvailableFields, Items");
			NestedCollection = WhatCopy.Selection.Items;
			If NestedCollection.Count() > 0 Then
				NewNestedCollection = NewRow.Selection.Items;
				For Each SubordinatedRow IN NestedCollection Do
					CopyRecursive(Node, SubordinatedRow, NewNestedCollection, Undefined, Map);
				EndDo;
			EndIf;
		EndIf;
		
		If ParametersOfCopying.HasFiler Then
			//   Filter
			//   (DataLayoutFilter) Filter.Items (DataLayoutFilterItemsCollection)
			FillPropertyValues(NewRow.Filter, WhatCopy.Filter, , "FilterAvailableFields, Items");
			NestedCollection = WhatCopy.Filter.Items;
			If NestedCollection.Count() > 0 Then
				NewNestedCollection = NewRow.Filter.Items;
				For Each SubordinatedRow IN NestedCollection Do
					CopyRecursive(Node, SubordinatedRow, NewNestedCollection, Undefined, New Map);
				EndDo;
			EndIf;
		EndIf;
		
		If ParametersOfCopying.HasOutputParameters Then
			//   OutputParameters
			//       (DataLayoutOutputParameterValues,
			//       GroupingDataLayoutOutputParameterValues,
			//       GroupingTableDataLayoutOutputParameterValues,
			//       GroupingChartDataLayoutOutputParameterValues,
			//       GroupingDataLayoutTableOutputParameterValues,
			//   GroupingChartDataLayoutOutputParameterValues) OutputParameters.Items (DataLayoutParameterValuesCollection)
			NestedCollection = WhatCopy.OutputParameters.Items;
			If NestedCollection.Count() > 0 Then
				NestedNode = NewRow.OutputParameters;
				For Each SubordinatedRow IN NestedCollection Do
					DCParameterValue = NestedNode.FindParameterValue(SubordinatedRow.Parameter);
					If DCParameterValue <> Undefined Then
						FillPropertyValues(DCParameterValue, SubordinatedRow);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		
		If ParametersOfCopying.HasDataParameters Then
			//   DataParameters
			//   (DataLayoutDataParametersValues) DataParameters.Items (DataLayoutDataParametersValuesCollection)
			NestedCollection = WhatCopy.DataParameters.Items;
			If NestedCollection.Count() > 0 Then
				NewNestedCollection = NewRow.DataParameters.Items;
				For Each SubordinatedRow IN NestedCollection Do
					CopyRecursive(Node, SubordinatedRow, NewNestedCollection, Undefined, Map);
				EndDo;
			EndIf;
		EndIf;
		
		If ParametersOfCopying.HasCustomFields Then
			//   CustomFields
			//   (DataLayoutCustomFields) CustomFields.Items (DataLayoutCustomFieldsCollection)
			NestedCollection = WhatCopy.UserFields.Items;
			If NestedCollection.Count() > 0 Then
				NewNestedCollection = NewRow.UserFields.Items;
				For Each SubordinatedRow IN NestedCollection Do
					CopyRecursive(Node, SubordinatedRow, NewNestedCollection, Undefined, Map);
				EndDo;
			EndIf;
		EndIf;
		
		If ParametersOfCopying.HasGroupFields Then
			//   GroupFields
			//   (DataLayoutGroupFields) GroupFields.Items (DataLayoutGroupFieldsCollection)
			NestedCollection = WhatCopy.GroupFields.Items;
			If NestedCollection.Count() > 0 Then
				NewNestedCollection = NewRow.GroupFields.Items;
				For Each SubordinatedRow IN NestedCollection Do
					CopyRecursive(Node, SubordinatedRow, NewNestedCollection, Undefined, New Map);
				EndDo;
			EndIf;
		EndIf;
		
		If ParametersOfCopying.HasOrder Then
			//   Order
			//   (DataLayoutOrder) Order.Items (DataLayoutOrderItemsCollection)
			FillPropertyValues(NewRow.Order, WhatCopy.Order, , "OrderAvailableFields, Items");
			NestedCollection = WhatCopy.Order.Items;
			If NestedCollection.Count() > 0 Then
				NewNestedCollection = NewRow.Order.Items;
				For Each SubordinatedRow IN NestedCollection Do
					CopyRecursive(Node, SubordinatedRow, NewNestedCollection, Undefined, Map);
				EndDo;
			EndIf;
		EndIf;
		
		If ParametersOfCopying.HasStructure Then
			//   Structure
			//       (DataLayoutSettingsStructureItemsCollection,
			//       DataLayoutChartStructureItemsCollection, DataLayoutTableStructureItemsCollection).
			FillPropertyValues(NewRow.Structure, WhatCopy.Structure);
			NestedCollection = WhatCopy.Structure;
			If NestedCollection.Count() > 0 Then
				NewNestedCollection = NewRow.Structure;
				For Each SubordinatedRow IN NestedCollection Do
					CopyRecursive(Node, SubordinatedRow, NewNestedCollection, Undefined, Map);
				EndDo;
			EndIf;
		EndIf;
		
		If ParametersOfCopying.HasConditionalDesign Then
			//   ConditionalDesign
			//   (DataLayoutConditionalDesign) ConditionalDesign.Items (DataLayoutConditionalDesignItemsCollection)
			FillPropertyValues(NewRow.ConditionalAppearance, WhatCopy.ConditionalAppearance, , "FilterAvailableFields, FieldsAvailableFields, Items");
			NestedCollection = WhatCopy.ConditionalAppearance.Items;
			If NestedCollection.Count() > 0 Then
				NewNestedCollection = NewRow.ConditionalAppearance.Items;
				For Each SubordinatedRow IN NestedCollection Do
					CopyRecursive(Node, SubordinatedRow, NewNestedCollection, Undefined, Map);
				EndDo;
			EndIf;
		EndIf;
		
		If ParametersOfCopying.HasColumnsAndRows Then
			//   Columns (DataLayoutTableStructureItemsCollection).
			NestedCollection = WhatCopy.Columns;
			NewNestedCollection = NewRow.Columns;
			OutdatedIdentifier = Node.GetIDByObject(NestedCollection);
			NewIdentifier = Node.GetIDByObject(NewNestedCollection);
			Map.Insert(OutdatedIdentifier, NewIdentifier);
			For Each SubordinatedRow IN NestedCollection Do
				CopyRecursive(Node, SubordinatedRow, NewNestedCollection, Undefined, Map);
			EndDo;
			//   Rows (DataLayoutTableStructureItemsCollection).
			NestedCollection = WhatCopy.Rows;
			NewNestedCollection = NewRow.Rows;
			OutdatedIdentifier = Node.GetIDByObject(NestedCollection);
			NewIdentifier = Node.GetIDByObject(NewNestedCollection);
			Map.Insert(OutdatedIdentifier, NewIdentifier);
			For Each SubordinatedRow IN NestedCollection Do
				CopyRecursive(Node, SubordinatedRow, NewNestedCollection, Undefined, Map);
			EndDo;
		EndIf;
		
		If ParametersOfCopying.HasSeriesAndPoints Then
			//   Series (DataLayoutChartStructureItemsCollection).
			NestedCollection = WhatCopy.Series;
			NewNestedCollection = NewRow.Series;
			OutdatedIdentifier = Node.GetIDByObject(NestedCollection);
			NewIdentifier = Node.GetIDByObject(NewNestedCollection);
			Map.Insert(OutdatedIdentifier, NewIdentifier);
			For Each SubordinatedRow IN NestedCollection Do
				CopyRecursive(Node, SubordinatedRow, NewNestedCollection, Undefined, Map);
			EndDo;
			//   Points (DataLayoutChartStructureItemsCollection).
			NestedCollection = WhatCopy.Points;
			NewNestedCollection = NewRow.Points;
			OutdatedIdentifier = Node.GetIDByObject(NestedCollection);
			NewIdentifier = Node.GetIDByObject(NewNestedCollection);
			Map.Insert(OutdatedIdentifier, NewIdentifier);
			For Each SubordinatedRow IN NestedCollection Do
				CopyRecursive(Node, SubordinatedRow, NewNestedCollection, Undefined, Map);
			EndDo;
		EndIf;
		
		If ParametersOfCopying.HasNestedParameterValues Then
			//   InsertedParametersValues (DataLayoutParametersValuesCollection).
			For Each SubordinatedRow IN WhatCopy.NestedParameterValues Do
				CopyRecursive(Node, SubordinatedRow, NewRow.NestedParameterValues, Undefined, Map);
			EndDo;
		EndIf;
		
		If ParametersOfCopying.HasFieldsAndDesign Then
			For Each MadeOutField IN WhatCopy.Fields.Items Do
				FillPropertyValues(NewRow.Fields.Items.Add(), MadeOutField);
			EndDo;
			For Each Source IN WhatCopy.Appearance.Items Do
				Receiver = NewRow.Appearance.FindParameterValue(Source.Parameter);
				If Receiver <> Undefined Then
					FillPropertyValues(Receiver, Source, , "Parent");
				EndIf;
			EndDo;
		EndIf;
		
	EndIf;
	
	Return NewRow;
EndFunction

Function ParametersOfCopying(PointType, Collection)
	Result = New Structure;
	Result.Insert("NeedToSpecifyPointType", False);
	Result.Insert("FormTreeFormed", False);
	Result.Insert("ExcludingProperties", Undefined);
	Result.Insert("IsSettings", False);
	Result.Insert("HasItems", False);
	Result.Insert("HasSelection", False);
	Result.Insert("HasFiler", False);
	Result.Insert("HasOutputParameters", False);
	Result.Insert("HasDataParameters", False);
	Result.Insert("HasCustomFields", False);
	Result.Insert("HasGroupFields", False);
	Result.Insert("HasOrder", False);
	Result.Insert("HasStructure", False);
	Result.Insert("HasConditionalDesign", False);
	Result.Insert("HasColumnsAndRows", False);
	Result.Insert("HasSeriesAndPoints", False);
	Result.Insert("HasNestedParameterValues", False);
	Result.Insert("HasFieldsAndDesign", False);
	
	If PointType = Type("FormDataTreeItem") Then
		
		Result.FormTreeFormed = True;
		
	ElsIf PointType = Type("DataCompositionSelectedFieldGroup")
		Or PointType = Type("DataCompositionFilterItemGroup") Then
		
		Result.NeedToSpecifyPointType = True;
		Result.ExcludingProperties = "Parent";
		Result.HasItems = True;
		
	ElsIf PointType = Type("DataCompositionSelectedField")
		Or PointType = Type("DataCompositionAutoSelectedField")
		Or PointType = Type("DataCompositionFilterItem") Then
		
		Result.ExcludingProperties = "Parent";
		Result.NeedToSpecifyPointType = True;
		
	ElsIf PointType = Type("DataCompositionGroupField")
		Or PointType = Type("DataCompositionAutoGroupField")
		Or PointType = Type("DataCompositionOrderItem")
		Or PointType = Type("DataCompositionAutoOrderItem") Then
		
		Result.NeedToSpecifyPointType = True;
		
	ElsIf PointType = Type("DataCompositionConditionalAppearanceItem") Then
		
		Result.HasFiler = True;
		Result.HasFieldsAndDesign = True;
		
	ElsIf PointType = Type("DataCompositionGroup")
		Or PointType = Type("DataCompositionTableGroup")
		Or PointType = Type("DataCompositionChartGroup")Then
		
		Result.ExcludingProperties = "Parent";
		CollectionType = TypeOf(Collection);
		If CollectionType = Type("DataCompositionSettingStructureItemCollection") Then
			Result.NeedToSpecifyPointType = True;
			PointType = Type("DataCompositionGroup"); // Substitute type to a supported.
		EndIf;
		
		Result.HasSelection = True;
		Result.HasFiler = True;
		Result.HasOutputParameters = True;
		Result.HasGroupFields = True;
		Result.HasOrder = True;
		Result.HasStructure = True;
		Result.HasConditionalDesign = True;
		
	ElsIf PointType = Type("DataCompositionTable") Then
		
		Result.ExcludingProperties = "Parent";
		Result.NeedToSpecifyPointType = True;
		
		Result.HasSelection = True;
		Result.HasColumnsAndRows = True;
		Result.HasOutputParameters = True;
		
	ElsIf PointType = Type("DataCompositionChart") Then
		
		Result.ExcludingProperties = "Parent";
		Result.NeedToSpecifyPointType = True;
		
		Result.HasSelection = True;
		Result.HasSeriesAndPoints = True;
		Result.HasOutputParameters = True;
		
	ElsIf PointType = Type("DataCompositionNestedObjectSettings") Then
		
		Result.ExcludingProperties = "Parent";
		Result.NeedToSpecifyPointType = True;
		Result.IsSettings = True;
		
		Result.HasSelection = True;
		Result.HasFiler = True;
		Result.HasOutputParameters = True;
		Result.HasDataParameters = True;
		Result.HasCustomFields = True;
		Result.HasGroupFields = True;
		Result.HasOrder = True;
		Result.HasStructure = True;
		Result.HasConditionalDesign = True;
		
	Else
		
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='Copying of items ""%1"" is not supported.';ru='Копирование элементов ""%1"" не поддерживается';vi='Không hỗ trợ sao chép các phần tử ""%1""'"),
			PointType);
		
	EndIf;
	
	Return Result;
	
EndFunction

Function OnAddItemSpecifyType(PointType) Export
	If PointType = Type("DataCompositionSelectedFieldGroup")
		Or PointType = Type("DataCompositionFilterItemGroup")
		Or PointType = Type("DataCompositionSelectedField")
		Or PointType = Type("DataCompositionFilterItem")
		Or PointType = Type("DataCompositionGroupField")
		Or PointType = Type("DataCompositionOrderItem")
		Or PointType = Type("DataCompositionAutoSelectedField")
		Or PointType = Type("DataCompositionAutoGroupField")
		Or PointType = Type("DataCompositionAutoOrderItem")
		Or PointType = Type("DataCompositionGroup")
		Or PointType = Type("DataCompositionTable")
		Or PointType = Type("DataCompositionChart")
		Or PointType = Type("DataCompositionNestedObjectSettings") Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction

Function OnAddToCollectionNeedToSpecifyPointType(CollectionType) Export
	If CollectionType = Type("DataCompositionTableStructureItemCollection")
		Or CollectionType = Type("DataCompositionChartStructureItemCollection") Then
		Return False;
	Else
		Return True;
	EndIf;
EndFunction

Function AddUniqueValueInList(ValueList, Value, Presentation, Use) Export
	If Not ValueIsFilled(Value) AND Not ValueIsFilled(Presentation) Then
		Return Undefined;
	EndIf;
	ItemOfList = ValueList.FindByValue(Value);
	If ItemOfList = Undefined Then
		ItemOfList = ValueList.Add();
		ItemOfList.Value = Value;
	EndIf;
	If ValueIsFilled(Presentation) Then
		ItemOfList.Presentation = Presentation;
	ElsIf Not ValueIsFilled(ItemOfList.Presentation) Then
		ItemOfList.Presentation = String(Value);
	EndIf;
	If Use AND Not ItemOfList.Check Then
		ItemOfList.Check = True;
	EndIf;
	Return ItemOfList;
EndFunction

Function ValueList(Values) Export
	If TypeOf(Values) = Type("ValueList") Then
		Return Values;
	Else
		ValueList = New ValueList;
		If TypeOf(Values) = Type("Array") Then
			ValueList.LoadValues(Values);
		Else
			AddUniqueValueInList(ValueList, Values, Undefined, False);
		EndIf;
		Return ValueList;
	EndIf;
EndFunction

Function ValueInArray(Value) Export
	If TypeOf(Value) = Type("Array") Then
		Return Value;
	Else
		Array = New Array;
		Array.Add(Value);
		Return Array;
	EndIf;
EndFunction

Function TypesAnalysis(InitialTypeDescription, ResultInForm) Export
	Result = New Structure;
	Result.Insert("ContainsTypeType",        False);
	Result.Insert("ContainsTypeDate",       False);
	Result.Insert("ContainsTypeBoolean",     False);
	Result.Insert("ContainsTypeOfRow",     False);
	Result.Insert("ContainsTypeNumber",      False);
	Result.Insert("ContainsTypePeriod",     False);
	Result.Insert("ContainsObjectTypes", False);
	
	Result.Insert("LimitedLength",     True);
	
	Result.Insert("TypeCount",            0);
	Result.Insert("PrimitiveTypesQuantity", 0);
	
	Result.Insert("ObjectiveTypes", New Array);
	
	If ResultInForm Then
		AddTypes = New Array;
		DeductionTypes = New Array;
	EndIf;
	
	TypeArray = InitialTypeDescription.Types();
	For Each Type IN TypeArray Do
		If Type = Type("DataCompositionField") Then
			If ResultInForm Then
				DeductionTypes.Add(Type);
			EndIf;
			Continue;
		EndIf;
		Result.TypeCount = Result.TypeCount + 1;
		
		If Type = Type("Type") Then
			Result.ContainsTypeType = True;
			If ResultInForm Then
				AddTypes.Add(Type("TypeDescription"));
				DeductionTypes.Add(Type("Type"));
			EndIf;
		ElsIf Type = Type("Date") Then
			Result.ContainsTypeDate = True;
			Result.PrimitiveTypesQuantity = Result.PrimitiveTypesQuantity + 1;
		ElsIf Type = Type("Boolean") Then
			Result.ContainsTypeBoolean = True;
			Result.PrimitiveTypesQuantity = Result.PrimitiveTypesQuantity + 1;
		ElsIf Type = Type("Number") Then
			Result.ContainsTypeNumber = True;
			Result.PrimitiveTypesQuantity = Result.PrimitiveTypesQuantity + 1;
		ElsIf Type = Type("StandardPeriod") Then
			Result.ContainsTypePeriod = True;
		ElsIf Type = Type("String") Then
			Result.ContainsTypeOfRow = True;
			Result.PrimitiveTypesQuantity = Result.PrimitiveTypesQuantity + 1;
			If InitialTypeDescription.StringQualifiers.Length = 0
				AND InitialTypeDescription.StringQualifiers.AllowedLength = AllowedLength.Variable Then
				Result.LimitedLength = False;
			EndIf;
		Else
			Result.ContainsObjectTypes = True;
			Result.ObjectiveTypes.Add(Type);
		EndIf;
		
	EndDo;
	
	If ResultInForm Then
		TypeDescriptionForForm = New TypeDescription(InitialTypeDescription, AddTypes, DeductionTypes);
		
		Result.Insert("TypeDescriptionSource", InitialTypeDescription);
		Result.Insert("TypeDescriptionForForm", TypeDescriptionForForm);
	EndIf;
	
	Return Result;
EndFunction

Function AdjustIDToName(ID) Export
	Return StrReplace(StrReplace(String(ID), "-", ""), ".", "_");
EndFunction

#EndRegion

#Region UniversalReport

// Дополнительные настройки отчета по умолчанию, определяющие:
//  * Признак формирования отчета при открытии;
//  * Подключаемые обработчики событий;
//  * Print settings;
//  * Использование функции расчетных показателей;
//  * Rights.
//
// Returns:
//   Structure - Настройки (дополнительные свойства) отчета, хранящиеся в данных формы:
//       
//       * FormImmediately - Boolean - значение по умолчанию для флажка "Формировать сразу".
//           Когда флажок включен, то отчет будет формироваться после открытия,
//           после выбора пользовательских настроек, после выбора другого варианта отчета.
//       
//       * OutputAmountSelectedCells - Boolean - если Истина, то в отчете будет выводиться поле автосуммы.
//       
//       * EditStructureAllowed - Boolean - если Ложь, то в настройках отчета будет скрыта вкладка "Структура".
//           Если Истина, то вкладка "Структура" показывается для отчетов на СКД: в расширенном режиме,
//           а также в простом режиме, если в пользовательские настройки выведены флажки использования группировок.
//       
//       * EditOptionsAllowed - Boolean - если Ложь, то блокируются кнопки изменения вариантов этого отчета. 
//           Если у текущего пользователя нет прав "СохранениеДанныхПользователя" и "Добавление" 
//           справочника ВариантыОтчетов, то принудительно устанавливается в Ложь.
//
//       * SelectAndEditOptionsWithoutSavingAllowed - Boolean - если Истина,
//           то есть возможность выбора и настройки предопределенных вариантов отчета, но без возможности сохранения 
//           выполненных настроек. Например, может быть задано для контекстных отчетов (открываемых с параметрами), 
//           у которых есть несколько вариантов.
//
//       * ControlItemsPlacementParameters - Structure, Undefined - Options:
//           - Undefined - параметры элементов управления общей формы отчетов "по умолчанию".
//           - Structure - с именами настройки в коллекции НастройкиКомпоновкиДанных свойства Настройки
//                         типа КомпоновщикНастроекКомпоновкиДанных:
//               ** Filter           - Array - как у следующего свойства.
//               ** DataParameters - Structure - со свойствами поля формы:
//                    *** Field                     - String - имя поля, отображение которого настраивается.
//                    *** HorizontalStretch - Boolean - значение свойства поля формы.
//                    *** AutoMaxWidth   - Boolean - значение свойства поля формы.
//                    *** Width                   - Number  - значение свойства поля формы.
//
//            Пример определения описываемого параметра:
//
//               МассивНастроек              = Новый Массив;
//               НастройкиЭлементаУправления = Новый Структура;
//               НастройкиЭлементаУправления.Вставить("Поле",                     "СписокРегистров");
//               НастройкиЭлементаУправления.Вставить("РастягиватьПоГоризонтали", Ложь);
//               НастройкиЭлементаУправления.Вставить("АвтоМаксимальнаяШирина",   Истина);
//               НастройкиЭлементаУправления.Вставить("Ширина",                   40);
//
//               МассивНастроек.Добавить(НастройкиЭлементаУправления);
//
//               НастройкиЭлементовУправления = Новый Структура();
//               НастройкиЭлементовУправления.Вставить("ПараметрыДанных", МассивНастроек);
//
//               Возврат НастройкиЭлементовУправления;
//
//       * ImportSettingsOnChangeParameters - Array - коллекция параметров компоновки данных,
//                                                    изменение которых, приводит к переформированию
//                                                    Схемы компоновки данных.
//
//               // Пример:
//               // 1. Инициализация:
//               //	Процедура ОпределитьНастройкиФормы(Форма, КлючВарианта, Настройки) Экспорт
//               //		Настройки.ЗагрузитьНастройкиПриИзмененииПараметров = Отчеты.УниверсальныйОтчет.ЗагрузитьНастройкиПриИзмененииПараметров();
//               //	КонецПроцедуры
//
//               //	Функция ЗагрузитьНастройкиПриИзмененииПараметров() Экспорт 
//               //		Параметры = Новый Массив;
//               //		Параметры.Добавить(Новый ПараметрКомпоновкиДанных("ТипОбъектаМетаданных"));
//               //		Параметры.Добавить(Новый ПараметрКомпоновкиДанных("ИмяОбъектаМетаданных"));
//               //		Параметры.Добавить(Новый ПараметрКомпоновкиДанных("ИмяТаблицы"));
//               //		
//               //		Возврат Параметры;
//               //	КонецФункции
//
//               // 2. Использование:
//               //	Процедура Подключаемый_ЭлементНастройки_ПриИзменении(Элемент)
//               //		...
//               //		Если ТипЗнч(ЭлементПользовательскойНастройки) = Тип("ЗначениеПараметраНастроекКомпоновкиДанных")
//               //			И НастройкиОтчета.ЗагрузитьНастройкиПриИзмененииПараметров.Найти(ЭлементПользовательскойНастройки.Параметр) <> Неопределено Тогда 
//               //			// Вызов метода переформирования Схемы компоновки данных...
//               //		КонецЕсли;
//
//       * HideBulkEmailCommands - Boolean - флаг, позволяющий скрыть команды рассылок, у тех отчетов,
//           для которых рассылка не имеет смысла.
//           Истина              - команды рассылок будут скрыты,
//           Ложь (по умолчанию) - команды будут доступны.
//
//       * Print - Structure - параметры печати табличного документа "по умолчанию".
//           ** ПолеСверху - Число - отступ сверху при печати (в миллиметрах).
//           ** ПолеСлева  - Число - отступ слева  при печати (в миллиметрах).
//           ** ПолеСнизу  - Число - отступ снизу  при печати (в миллиметрах).
//           ** ПолеСправа - Число - отступ справа при печати (в миллиметрах).
//           ** ОриентацияСтраницы - ориентацияСтраницы - "Портрет" или "Ландшафт".
//           ** АвтоМасштаб - Булево - автоматически подгонять масштаб под размер страницы.
//           ** МасштабПечати - Число - масштаб изображения (в процентах).
//       
//       * Events - Structure - события, для которых определены обработчики в модуле объекта отчета.
//           
//           ** ПриСозданииНаСервере - Булево - если Истина, то в модуле объекта отчета
//               следует определить обработчик события по шаблону:
//               
//               // Вызывается в обработчике одноименного события формы отчета после выполнения кода формы.
//               //
//               // Параметры:
//               //   Форма - ФормаКлиентскогоПриложения - форма отчета.
//               //   Отказ - Булево - признак отказа от создания формы.
//               //      See описание одноименного параметра "ФормаКлиентскогоПриложения.ПриСозданииНаСервере" в синтакс-помощнике.
//               //   СтандартнаяОбработка - Булево - признак выполнения стандартной (системной) обработки события.
//               //      See описание одноименного параметра "ФормаКлиентскогоПриложения.ПриСозданииНаСервере" в синтакс-помощнике.
//               //
//               // See также:
//               //   Процедура для вывода добавленных команд в форму: ОтчетыСервер.ВывестиКоманду().
//               //   Глобальный обработчик этого события: ОтчетыПереопределяемый.ПриСозданииНаСервере().
//               //
//               // Пример добавления команды:
//               //	Команда = Форма.Команды.Добавить("<ИмяКоманды>");
//               //	Команда.Действие  = "Подключаемый_Команда";
//               //	Команда.Заголовок = НСтр("ru='<Представление команды...>';vi='<Lệnh trình bày...>'");
//               //	ОтчетыСервер.ВывестиКоманду(Форма, Команда, "<ВидГруппы>");
//               // Обработчик команды пишется в процедуре ОтчетыКлиентПереопределяемый.ОбработчикКоманды.
//               //
//               Процедура ПриСозданииНаСервере(Форма, Отказ, СтандартнаяОбработка) Экспорт
//               	// Обработка события.
//               КонецПроцедуры
//           
//           ** ПередЗагрузкойНастроекВКомпоновщик - Булево - если Истина, то в модуле объекта отчета
//               следует определить обработчик события по шаблону:
//               
//               // Вызывается перед загрузкой новых настроек. Используется для изменения схемы компоновки.
//               //   Например, если схема отчета зависит от ключа варианта или параметров отчета.
//               //   Чтобы изменения схемы вступили в силу следует вызывать метод ОтчетыСервер.ПодключитьСхему().
//               //
//               // Параметры:
//               //   Контекст - Произвольный - 
//               //       Параметры контекста, в котором используется отчет.
//               //       Используется для передачи в параметрах метода ОтчетыСервер.ПодключитьСхему().
//               //   КлючСхемы - Строка -
//               //       Идентификатор текущей схемы компоновщика настроек.
//               //       По умолчанию не заполнен (это означает что компоновщик инициализирован на основании основной схемы).
//               //       Используется для оптимизации, чтобы переинициализировать компоновщик как можно реже.
//               //       Может не использоваться если переинициализация выполняется безусловно.
//               //   КлючВарианта - Строка, Неопределено -
//               //       Имя предопределенного или уникальный идентификатор пользовательского варианта отчета.
//               //       Неопределено когда вызов для варианта расшифровки или без контекста.
//               //   НовыеНастройкиКД - НастройкиКомпоновкиДанных, Неопределено -
//               //       Настройки варианта отчета, которые будут загружены в компоновщик настроек после его инициализации.
//               //       Неопределено когда настройки варианта не надо загружать (уже загружены ранее).
//               //   НовыеПользовательскиеНастройкиКД - ПользовательскиеНастройкиКомпоновкиДанных, Неопределено -
//               //       Пользовательские настройки, которые будут загружены в компоновщик настроек после его инициализации.
//               //       Неопределено когда пользовательские настройки не надо загружать (уже загружены ранее).
//               //
//               // Примеры:
//               // 1. Компоновщик отчета инициализируется на основании схемы из общих макетов:
//               //	Если КлючСхемы <> "1" Тогда
//               //		КлючСхемы = "1";
//               //		СхемаКД = ПолучитьОбщийМакет("МояОбщаяСхемаКомпоновки");
//               //		ОтчетыСервер.ПодключитьСхему(ЭтотОбъект, Контекст, СхемаКД, КлючСхемы);
//               //	КонецЕсли;
//               //
//               // 2. Схема зависит от значения параметра, выведенного в пользовательские настройки отчета:
//               //	Если ТипЗнч(НовыеПользовательскиеНастройкиКД) = Тип("ПользовательскиеНастройкиКомпоновкиДанных") Тогда
//               //		ПолноеИмяОбъектаМетаданных = "";
//               //		Для Каждого ЭлементКД Из НовыеПользовательскиеНастройкиКД.Элементы Цикл
//               //			Если ТипЗнч(ЭлементКД) = Тип("ЗначениеПараметраНастроекКомпоновкиДанных") Тогда
//               //				ИмяПараметра = Строка(ЭлементКД.Параметр);
//               //				Если ИмяПараметра = "ОбъектМетаданных" Тогда
//               //					ПолноеИмяОбъектаМетаданных = ЭлементКД.Значение;
//               //				КонецЕсли;
//               //			КонецЕсли;
//               //		КонецЦикла;
//               //		Если КлючСхемы <> ПолноеИмяОбъектаМетаданных Тогда
//               //			КлючСхемы = ПолноеИмяОбъектаМетаданных;
//               //			СхемаКД = Новый СхемаКомпоновкиДанных;
//               //			// Наполнение схемы...
//               //			ОтчетыСервер.ПодключитьСхему(ЭтотОбъект, Контекст, СхемаКД, КлючСхемы);
//               //		КонецЕсли;
//               //	КонецЕсли;
//               //
//               Процедура ПередЗагрузкойНастроекВКомпоновщик(Контекст, КлючСхемы, КлючВарианта, НовыеНастройкиКД, НовыеПользовательскиеНастройкиКД) Экспорт
//               	// Обработка события.
//               КонецПроцедуры
//           
//           ** ПередЗагрузкойВариантаНаСервере - Булево - если Истина, то в модуле объекта отчета
//               следует определить обработчик события по шаблону:
//               
//               // Вызывается в обработчике одноименного события формы отчета после выполнения кода формы.
//               //
//               // Параметры:
//               //   Форма - ФормаКлиентскогоПриложения - Форма отчета.
//               //   НовыеНастройкиКД - НастройкиКомпоновкиДанных - Настройки для загрузки в компоновщик настроек.
//               //
//               // See ReportsOverridable.ПередЗагрузкойВариантаНаСервере().
//               //
//               Процедура ПередЗагрузкойВариантаНаСервере(Форма, НовыеНастройкиКД) Экспорт
//               	// Обработка события.
//               КонецПроцедуры
//           
//           ** ПриЗагрузкеВариантаНаСервере - Булево - если Истина, то в модуле объекта отчета
//               следует определить обработчик события по шаблону:
//               
//               // Вызывается в обработчике одноименного события формы отчета после выполнения кода формы.
//               //
//               // Параметры:
//               //   Форма - ФормаКлиентскогоПриложения - форма отчета.
//               //   НовыеНастройкиКД - НастройкиКомпоновкиДанных - настройки для загрузки в компоновщик настроек.
//               //
//               // See синтакс-помощник "Расширение управляемой формы для отчета.ПриЗагрузкеВариантаНаСервере" в синтакс-помощнике.
//               //
//               Процедура ПриЗагрузкеВариантаНаСервере(Форма, НовыеНастройкиКД) Экспорт
//               	// Обработка события.
//               КонецПроцедуры
//           
//           ** ПриЗагрузкеПользовательскихНастроекНаСервере - Булево - если Истина, то в модуле объекта отчета
//               следует определить обработчик события по шаблону:
//               
//               // Вызывается в обработчике одноименного события формы отчета после выполнения кода формы.
//               //
//               // Параметры:
//               //   Форма - ФормаКлиентскогоПриложения - форма отчета.
//               //   НовыеПользовательскиеНастройкиКД - ПользовательскиеНастройкиКомпоновкиДанных -
//               //       Пользовательские настройки для загрузки в компоновщик настроек.
//               //
//               // See синтакс-помощник "Расширение управляемой формы для отчета.ПриЗагрузкеПользовательскихНастроекНаСервере"
//               //    в синтакс-помощнике.
//               //
//               Процедура ПриЗагрузкеПользовательскихНастроекНаСервере(Форма, НовыеПользовательскиеНастройкиКД) Экспорт
//               	// Обработка события.
//               КонецПроцедуры
//           
//           ** ПередЗаполнениемПанелиБыстрыхНастроек - Булево - если Истина, то в модуле объекта отчета
//               следует определить обработчик события по шаблону:
//               
//               // Вызывается до перезаполнения панели настроек формы отчета.
//               //
//               // Параметры:
//               //   Форма - ФормаКлиентскогоПриложения - форма отчета.
//               //   ПараметрыЗаполнения - Структура - параметры, которые будут загружены в отчет.
//               //
//               Процедура ПередЗаполнениемПанелиБыстрыхНастроек(Форма, ПараметрыЗаполнения) Экспорт
//               	// Обработка события.
//               КонецПроцедуры
//           
//           ** ПослеЗаполненияПанелиБыстрыхНастроек - Булево - если Истина, то в модуле объекта отчета
//               следует определить обработчик события по шаблону:
//               
//               // Вызывается после перезаполнения панели настроек формы отчета.
//               //
//               // Параметры:
//               //   Форма - ФормаКлиентскогоПриложения - Форма отчета.
//               //   ПараметрыЗаполнения - Структура - параметры, которые будут загружены в отчет.
//               //
//               Процедура ПослеЗаполненияПанелиБыстрыхНастроек(Форма, ПараметрыЗаполнения) Экспорт
//               	// Обработка события.
//               КонецПроцедуры
//           
//           ** ПриОпределенииПараметровВыбора - Булево - если Истина, то в модуле объекта отчета
//               следует определить обработчик события по шаблону:
//               
//               // Вызывается в форме отчета перед выводом настройки.
//               //
//               // Параметры:
//               //   Форма - ФормаКлиентскогоПриложения, Неопределено - форма отчета.
//               //   СвойстваНастройки - Структура - описание настройки отчета, которая будет выведена в форме отчета.
//               //       * ОписаниеТипов - ОписаниеТипов - тип настройки.
//               //       * ЗначенияДляВыбора - СписокЗначений - объекты, которые будут предложены пользователю в списке
//                          выбора. Дополняет список объектов, уже выбранных пользователем ранее.
//               //       * ЗапросЗначенийВыбора - Запрос - возвращает объекты, которыми необходимо дополнить ЗначенияДляВыбора.
//               //           Первой колонкой (с 0м индексом) должен выбираться объект,
//               //           который следует добавить в ЗначенияДляВыбора.Значение.
//               //           Для отключения автозаполнения
//               //           в свойство ЗапросЗначенийВыбора.Текст следует записать пустую строку.
//               //       * ОграничиватьВыборУказаннымиЗначениями - Булево - когда Истина, то выбор пользователя будет
//               //           ограничен значениями, указанными в ЗначенияДляВыбора (его конечным состоянием).
//               //
//               // See также:
//               //   ОтчетыПереопределяемый.ПриОпределенииПараметровВыбора().
//               //
//               Процедура ПриОпределенииПараметровВыбора(Форма, СвойстваНастройки) Экспорт
//               	// Обработка события.
//               КонецПроцедуры
//           
//           ** ПриОпределенииИспользуемыхТаблиц - Булево - Если Истина, то в модуле объекта отчета
//               следует определить обработчик события по шаблону:
//               
//               // Список регистров и других объектов метаданных, по которым формируется отчет.
//               //   Используется для проверки что отчет может содержать не обновленные данные.
//               //
//               // Параметры:
//               //   КлючВарианта - Строка, Неопределено -
//               //       Имя предопределенного или уникальный идентификатор пользовательского варианта отчета.
//               //       Неопределено когда вызов для варианта расшифровки или без контекста.
//               //   ИспользуемыеТаблицы - Массив из Строка -
//               //       Полные имена объектов метаданных (регистров, документов и других таблиц),
//               //       данные которых выводятся в отчете.
//               //
//               // Пример:
//               //	ИспользуемыеТаблицы.Добавить(Метаданные.Документы.<ИмяДокумента>.ПолноеИмя());
//               //
//               Процедура ПриОпределенииИспользуемыхТаблиц(КлючВарианта, ИспользуемыеТаблицы) Экспорт
//               	// Обработка события.
//               КонецПроцедуры
//           
//           ** ДополнитьСвязиОбъектовМетаданных - Булево - если Истина, то в модуле объекта отчета
//               следует определить обработчик события по шаблону:
//               
//               // Additional links settings of this report.
//               // В данной процедуре следует описать дополнительные зависимости объектов метаданных
//               //   конфигурации, которые будут использоваться для связи настроек отчетов.
//               //
//               // PARAMETERS:
//               //   СвязиОбъектовМетаданных - ТаблицаЗначений - таблица связей.
//               //       * ПодчиненныйРеквизит - Строка - имя реквизита подчиненного объекта метаданных.
//               //       * ПодчиненныйТип      - Тип    - тип подчиненного объекта метаданных.
//               //       * ВедущийТип          - Тип    - тип ведущего объекта метаданных.
//               //
//               // See также:
//               //   ReportsOverridable.ExpandMetadataObjectsLinks().
//               //
//               Процедура ДополнитьСвязиОбъектовМетаданных(СвязиОбъектовМетаданных) Экспорт
//               	// Обработка события.
//               EndProcedure
//
Function DefaultReportSettings() Export
	Settings = New Structure;
	Settings.Insert("FormImmediately", False);
	Settings.Insert("OutputAmountSelectedCells", True);
	Settings.Insert("EditStructureAllowed", True);
	Settings.Insert("EditOptionsAllowed", True);
	Settings.Insert("SelectAndEditOptionsWithoutSavingAllowed", False);
	Settings.Insert("ControlItemsPlacementParameters", Undefined);
	Settings.Insert("HideBulkEmailCommands", False);
	Settings.Insert("ImportSchemaAllowed", False);
	Settings.Insert("EditSchemaAllowed", False);
	Settings.Insert("RestoreStandardSchemaAllowed", False);
	Settings.Insert("ImportSettingsOnChangeParameters", New Array);
	
	Print = New Structure;
	Print.Insert("TopMargin", 10);
	Print.Insert("LeftMargin", 10);
	Print.Insert("BottomMargin", 10);
	Print.Insert("RightMargin", 10);
	Print.Insert("PageOrientation", PageOrientation.Portrait);
	Print.Insert("FitToPage", True);
	Print.Insert("PrintScale", Undefined);
	
	Settings.Insert("Print", Print);
	
	Events = New Structure;
	Events.Insert("OnCreateAtServer", False);
	Events.Insert("BeforeImportSettingsToComposer", False);
	Events.Insert("BeforeLoadVariantAtServer", False);
	Events.Insert("OnLoadVariantAtServer", False);
	Events.Insert("OnLoadUserSettingsAtServer", False);
	Events.Insert("BeforeFillingQuickSettingsPanel", False);
	Events.Insert("AfterFillingQuickSettingsPanel", False);
	Events.Insert("OnDefineSelectionParameters", False);
	Events.Insert("OnDefineUsedTables", False);
	Events.Insert("SupplementMetadataObjectsLinks", False);
	Events.Insert("OnDefineSettingsFormItemsProperties", False);
	
	Settings.Insert("Events", Events);
	
	Return Settings;
EndFunction

Function LoadSettings(SettingsComposer, Settings, UserSettings = Undefined, FixedSettings = Undefined) Export
	SettingsImported = (TypeOf(Settings) = Type("DataCompositionSettings")
		And Settings <> SettingsComposer.Settings);
	
	If SettingsImported Then
		If TypeOf(UserSettings) <> Type("DataCompositionUserSettings") Then
			UserSettings = SettingsComposer.UserSettings;
		EndIf;
		
		If TypeOf(FixedSettings) <> Type("DataCompositionSettings") Then 
			FixedSettings = SettingsComposer.FixedSettings;
		EndIf;
		
		AvailableValues = CommonUseClientServer.StructureProperty(
			SettingsComposer.Settings.AdditionalProperties, "AvailableValues");
		
		If AvailableValues <> Undefined Then 
			Settings.AdditionalProperties.Insert("AvailableValues", AvailableValues);
		EndIf;
		
		SettingsComposer.LoadSettings(Settings);
	EndIf;
	
	If TypeOf(UserSettings) = Type("DataCompositionUserSettings")
		And UserSettings <> SettingsComposer.UserSettings Then
		SettingsComposer.LoadUserSettings(UserSettings);
	EndIf;
	
	If TypeOf(FixedSettings) = Type("DataCompositionSettings")
		And FixedSettings <> SettingsComposer.FixedSettings Then
		SettingsComposer.LoadFixedSettings(FixedSettings);
	EndIf;
	
	Return SettingsImported;
EndFunction

Function UniqueKey(FullReportName, VariantKey) Export
	Result = FullReportName;
	If ValueIsFilled(VariantKey) Then
		Result = Result + "/VariantKey." + VariantKey;
	EndIf;
	Return Result;
EndFunction

Function PictureIndex(Type, State = Undefined) Export
	If Type = "Group" Then
		IndexOf = 1;
	ElsIf Type = "Item" Then
		IndexOf = 4;
	ElsIf Type = "Grouping"
		Or Type = "TableGrouping"
		Or Type = "ChartGrouping" Then
		IndexOf = 7;
	ElsIf Type = "Table" Then
		IndexOf = 10;
	ElsIf Type = "Chart" Then
		IndexOf = 11;
	ElsIf Type = "NestedObjectSettings" Then
		IndexOf = 12;
	ElsIf Type = "DataParameters" Then
		IndexOf = 14;
	ElsIf Type = "DataParameter" Then
		IndexOf = 15;
	ElsIf Type = "filters" Then
		IndexOf = 16;
	ElsIf Type = "FilterItem" Then
		IndexOf = 17;
	ElsIf Type = "SelectedFields" Then
		IndexOf = 18;
	ElsIf Type = "order" Then
		IndexOf = 19;
	ElsIf Type = "ConditionalAppearance" Then
		IndexOf = 20;
	ElsIf Type = "Settings" Then
		IndexOf = 21;
	ElsIf Type = "Structure" Then
		IndexOf = 22;
	ElsIf Type = "Resource" Then
		IndexOf = 23;
	ElsIf Type = "Warning" Then
		IndexOf = 24;
	ElsIf Type = "Error" Then
		IndexOf = 25;
	Else
		IndexOf = -2;
	EndIf;
	
	If State = "DeletionMark" Then
		IndexOf = IndexOf + 1;
	ElsIf State = "Predefined" Then
		IndexOf = IndexOf + 2;
	EndIf;
	
	Return IndexOf;
	
EndFunction

Function IsListComparisonKind(Var_ComparisonType) Export 
	ComparisonsTypes = New Array;
	ComparisonsTypes.Add(DataCompositionComparisonType.InList);
	ComparisonsTypes.Add(DataCompositionComparisonType.NotInList);
	ComparisonsTypes.Add(DataCompositionComparisonType.InListByHierarchy);
	ComparisonsTypes.Add(DataCompositionComparisonType.NotInListByHierarchy);
	
	Return ComparisonsTypes.Find(Var_ComparisonType) <> Undefined;
EndFunction

Function ChoiceParameters(Settings, UserSettings, SettingItem, OptionChangeMode = False) Export 
	ChoiceParameters = New Array;
	
	SettingItemDetails = FindAvailableSetting(Settings, SettingItem);
	If SettingItemDetails = Undefined Then 
		Return New FixedArray(ChoiceParameters);
	EndIf;
	
	Parameters = SettingItemDetails.GetChoiceParameters(); // ПараметрыВыбораКомпоновкиДанных
	For Each Parameter In Parameters Do 
		If ValueIsFilled(Parameter.Name) Then
			ChoiceParameters.Add(New ChoiceParameter(Parameter.Name, Parameter.Value));
		EndIf;
	EndDo;
	
	Parameters = SettingItemDetails.GetChoiceParameterLinks();
	For Each Parameter In Parameters Do 
		If Not ValueIsFilled(Parameter.Name) Then
			Continue;
		EndIf;
		
		Value = ChoiceParameterValue(Settings, UserSettings, Parameter.Field, OptionChangeMode);
		If ValueIsFilled(Value) Then 
			ChoiceParameters.Add(New ChoiceParameter(Parameter.Name, Value));
		EndIf;
	EndDo;
	
	Return New FixedArray(ChoiceParameters);
EndFunction

Function SettingItemCondition(Item, LongDesc) Export 
	Condition = DataCompositionComparisonType.Equal;
	
	If TypeOf(Item) = Type("DataCompositionFilterItem") Then 
		Condition = Item.ComparisonType;
	ElsIf TypeOf(Item) = Type("DataCompositionSettingsParameterValue")
		And LongDesc.ValueListAllowed Then 
		Condition = DataCompositionComparisonType.InList;
	EndIf;
	
	Return Condition;
EndFunction

Function ChoiceParameterValue(Settings, UserSettings, Field, OptionChangeMode)
	Value = DataParameterValueByField(Settings, UserSettings, Field, OptionChangeMode);
	
	If Value = Undefined Then 
		FilterItems = Settings.Filter.Items;
		FindFilterItemsFieldValues(Field, FilterItems, UserSettings, Value, OptionChangeMode);
	EndIf;
	
	Return Value;
EndFunction

Function DataParameterValueByField(Settings, UserSettings, Field, OptionChangeMode)
	If TypeOf(Settings) <> Type("DataCompositionSettings") Then 
		Return Undefined;
	EndIf;
	
	SettingsItems = Settings.DataParameters.Items;
	For Each Item In SettingsItems Do 
		UserItem = UserSettings.Find(Item.UserSettingID);
		ItemToAnalyse = ?(OptionChangeMode Or UserItem = Undefined, Item, UserItem);
		
		Fields = New Array;
		Fields.Add(New DataCompositionField(String(Item.Parameter)));
		Fields.Add(New DataCompositionField("DataParameters." + String(Item.Parameter)));
		
		If ItemToAnalyse.Use
			And (Fields[0] = Field Or Fields[1] = Field)
			And ValueIsFilled(ItemToAnalyse.Value)
			And TypeOf(ItemToAnalyse.Value) <> Type("ValueList") Then 
			
			Return ItemToAnalyse.Value;
		EndIf;
	EndDo;
	
	Return Undefined;
EndFunction

Procedure FindFilterItemsFieldValues(Field, FilterItems, UserSettings, Value, OptionChangeMode)
	If ValueIsFilled(Value) Then 
		Return;
	EndIf;
	
	For Each Item In FilterItems Do 
		UserItem = UserSettings.Find(Item.UserSettingID);
		ItemToAnalyse = ?(OptionChangeMode Or UserItem = Undefined, Item, UserItem);
		
		If TypeOf(ItemToAnalyse) = Type("DataCompositionFilterItemGroup") Then 
			FindFilterItemsFieldValues(Field, Item.Items, UserSettings, Value, OptionChangeMode);
		Else
			If Item.LeftValue = Field
				And ItemToAnalyse.Use
				And ItemToAnalyse.ComparisonType = DataCompositionComparisonType.Equal
				And ValueIsFilled(ItemToAnalyse.RightValue) Then 
				
				Value = ItemToAnalyse.RightValue; 
				Break;
			EndIf;
		EndIf;
	EndDo;
EndProcedure

Function GroupsAndItemsTypeValue(SourceValue, Condition = Undefined) Export
	If Condition <> Undefined Then 
		If Condition = DataCompositionComparisonType.InListByHierarchy
			Or Condition = DataCompositionComparisonType.NotInListByHierarchy Then 
			If SourceValue = FoldersAndItems.Folders
				Or SourceValue = FoldersAndItemsUse.Folders Then 
				Return FoldersAndItems.Folders;
			Else
				Return FoldersAndItems.FoldersAndItems;
			EndIf;
		ElsIf Condition = DataCompositionComparisonType.InHierarchy
			Or Condition = DataCompositionComparisonType.NotInHierarchy Then 
			Return FoldersAndItems.Folders;
		EndIf;
	EndIf;
	
	If TypeOf(SourceValue) = Type("FoldersAndItems") Then 
		Return SourceValue;
	ElsIf SourceValue = FoldersAndItemsUse.Items Then
		Return FoldersAndItems.Items;
	ElsIf SourceValue = FoldersAndItemsUse.FoldersAndItems Then
		Return FoldersAndItems.FoldersAndItems;
	ElsIf SourceValue = FoldersAndItemsUse.Folders Then
		Return FoldersAndItems.Folders;
	EndIf;
	
	Return FoldersAndItems.Auto;
	
EndFunction

Function FindTableRows(TableAttribute, RowData) Export
	If TypeOf(TableAttribute) = Type("FormDataCollection") Then // Таблица значений.
		Return TableAttribute.FindRows(RowData);
	ElsIf TypeOf(TableAttribute) = Type("FormDataTree") Then // Дерево значений.
		Return FindRecursively(TableAttribute.GetItems(), RowData);
	Else
		Return Undefined;
	EndIf;
EndFunction

Function FindRecursively(RowsSet, RowData, Found = Undefined)
	If Found = Undefined Then
		Found = New Array;
	EndIf;
	For Each TableRow In RowsSet Do
		ValuesMatch = True;
		For Each KeyAndValue In RowData Do
			If TableRow[KeyAndValue.Key] <> KeyAndValue.Value Then
				ValuesMatch = False;
				Break;
			EndIf;
		EndDo;
		If ValuesMatch Then
			Found.Add(TableRow);
		EndIf;
		FindRecursively(TableRow.GetItems(), RowData, Found);
	EndDo;
	Return Found;
EndFunction

Procedure CastValueToType(Value, TypeDescription) Export
	If TypeOf(Value) = Type("ValueList") Then 
		For Each ListElement In Value Do 
			If Not TypeDescription.ContainsType(TypeOf(ListElement.Value)) Then
				ListElement.Value = TypeDescription.AdjustValue();
			EndIf;
		EndDo;
	Else
		If Not TypeDescription.ContainsType(TypeOf(Value)) Then
			Value = TypeDescription.AdjustValue();
		EndIf;
	EndIf;
EndProcedure

Function SettingItemIndexByPath(Val Path, ItemProperty = Undefined) Export 
	AvailableProperties = StrSplit("Use, Value, List", ", ", False);
	For Each ItemProperty In AvailableProperties Do 
		If StrEndsWith(Path, ItemProperty) Then 
			Break;
		EndIf;
	EndDo;
	
	IndexDetails = New TypeDescription("Number");
	
	ItemIndex = StrReplace(Path, "SettingsComposerUserSettingsItem", "");
	ItemIndex = StrReplace(ItemIndex, ItemProperty, "");
	
	Return IndexDetails.AdjustValue(ItemIndex);
EndFunction

Function ExpandList(TargetList, SourceList, ControlType = Undefined, AddNewItems = True) Export
	
	If TargetList = Undefined Or SourceList = Undefined Then
		Return Undefined;
	EndIf;
	
	ReplaceExistingItems = True;
	ReplacePresentation = ReplaceExistingItems And AddNewItems;
	
	Result = New Structure;
	Result.Insert("Total", 0);
	Result.Insert("Added", 0);
	Result.Insert("Updated", 0);
	Result.Insert("IsSkipped", 0);
	
	If ControlType = Undefined Then
		ControlType = (TargetList.ValueType <> SourceList.ValueType);
	EndIf;
	If ControlType Then
		DestinationTypesDetails = TargetList.ValueType;
	EndIf;
	For Each ItemSource In SourceList Do
		Result.Total = Result.Total + 1;
		Value = ItemSource.Value;
		If ControlType And Not DestinationTypesDetails.ContainsType(TypeOf(Value)) Then
			Result.IsSkipped = Result.IsSkipped + 1;
			Continue;
		EndIf;
		ItemReceiver = TargetList.FindByValue(Value);
		If ItemReceiver = Undefined Then
			If AddNewItems Then
				Result.Added = Result.Added + 1;
				FillPropertyValues(TargetList.Add(), ItemSource);
			Else
				Result.IsSkipped = Result.IsSkipped + 1;
			EndIf;
		Else
			If ReplaceExistingItems Then
				Result.Updated = Result.Updated + 1;
				FillPropertyValues(ItemReceiver, ItemSource, , ?(ReplacePresentation, "", "Presentation"));
			Else
				Result.IsSkipped = Result.IsSkipped + 1;
			EndIf;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion
