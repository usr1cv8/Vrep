#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	SetConditionalAppearance();
	If Parameters.Property("AutoTest") Then
		Return;
	EndIf;
	
	MixedImportance = NStr("en='Different';ru='Различная';vi='Khác'");
	
	// The number of variants is controlled before opening the form.
	CustomizableOptions.LoadValues(Parameters.OptionsArray);
	
	RefillTree(False);
	
	ReportsVariants.SubsystemsTreeAddConditionalAppearance(ThisObject);
	
	CurrentItem = Items.SubsystemsTree;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	If ExecutionResult <> Undefined Then
		If ExecutionResult.Property("Cancel") AND ExecutionResult.Cancel = True Then
			Cancel = True;
			ShowExecutionResult();
		Else
			AttachIdleHandler("ShowExecutionResult", 0.2, True);
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region HeaderFormItemsEventsHandlers

&AtClient
Procedure ChangedOptionsOnChange(Item)
	RefillTree(False);
	ShowExecutionResult();
EndProcedure

#EndRegion

#Region FormTableItemsEventsHandlersSubsystemsTree

&AtClient
Procedure SubsystemsTreeUsingOnChange(Item)
	ReportsVariantsClient.SubsystemsTreeUsingOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure SubsystemsTreeImportanceOnChange(Item)
	ReportsVariantsClient.SubsystemsTreeImportanceOnChange(ThisObject, Item);
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure Place(Command)
	If CheckCountOfVariants() Then
		WriteAtServer();
		NotificationText = NStr("en='Report variant settings were changed (%1 items).';ru='Изменены настройки вариантов отчетов (%1 шт.).';vi='Thay đổi tùy chỉnh phương án báo cáo (%1 c.).'");
		NotificationText = StrReplace(NotificationText, "%1", Format(CustomizableOptions.Count(), "NZ=0; NG=0"));
		ShowUserNotification(, , NotificationText);
		ReportsVariantsClient.OpenFormsRefresh();
		Close();
	EndIf;
EndProcedure

&AtClient
Procedure Reread(Command)
	If CheckCountOfVariants() Then
		RefillTree(False);
		Items.SubsystemsTree.Expand(SubsystemsTree.GetItems()[0].GetID(), True);
		ShowExecutionResult();
	EndIf;
EndProcedure

&AtClient
Procedure UncheckAll(Command)
	If CheckCountOfVariants() Then
		RefillTree(True);
		Items.SubsystemsTree.Expand(SubsystemsTree.GetItems()[0].GetID(), True);
		ShowExecutionResult();
	EndIf;
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

&AtServer
Procedure SetConditionalAppearance()
	Instruction = ReportsVariants.ConditionalDesignInstruction();
	Instruction.Fields = "SubsystemsTreeImportance";
	Instruction.Filters.Insert("SubsystemsTree.Importance", New DataCompositionField("MixedImportance"));
	Instruction.Appearance.Insert("TextColor", StyleColors.BlockedAttributeColor);
	ReportsVariants.AddConditionalAppearanceElement(ThisObject, Instruction);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Client

&AtClient
Function CheckCountOfVariants()
	ClearMessages();
	If VariantCount = 0 Then
		CommonUseClientServer.MessageToUser(
			NStr("en='Fill in the list ""Report variants""';ru='Необходимо заполнить список ""Варианты отчетов""';vi='Cần điền danh sách ""Phương án báo cáo""'"),
			,
			"CustomizableOptions");
		Return False;
	EndIf;
	Return True;
EndFunction

&AtClient
Procedure ShowExecutionResult()
	ClearMessages();
	If ExecutionResult <> Undefined Then
		StandardSubsystemsClient.ShowExecutionResult(ThisObject, ExecutionResult);
		ExecutionResult = Undefined;
	EndIf;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Calling the server

&AtServer
Procedure RefillTree(JustUncheckCheckBoxes)
	
	If JustUncheckCheckBoxes = True Then
		TreeReceiver = FormAttributeToValue("SubsystemsTree", Type("ValueTree"));
		Found = TreeReceiver.Rows.FindRows(New Structure("Use", 1), True);
		For Each TreeRow IN Found Do
			TreeRow.Use = 0;
			If TreeRow.Use <> TreeRow.UsingByDefault Then
				TreeRow.ChangedByUser = True;
			EndIf;
		EndDo; 
		
		Found = TreeReceiver.Rows.FindRows(New Structure("Use", 2), True);
		For Each TreeRow IN Found Do
			TreeRow.Use = 0;
			If TreeRow.Use <> TreeRow.UsingByDefault Then
				TreeRow.ChangedByUser = True;
			EndIf;
		EndDo; 
		
		ValueToFormAttribute(TreeReceiver, "SubsystemsTree");
		Return;
	EndIf;
	
	VariantCount = CustomizableOptions.Count();
	If VariantCount = 0 Then
		ExecutionResult = New Structure;
		MessageText = NStr("en='Select report variants';ru='Необходимо выбрать варианты отчетов';vi='Cần chọn phương án báo cáo'");
		StandardSubsystemsClientServer.ShowMessage(ExecutionResult, MessageText);
		ExecutionResult = New FixedStructure(ExecutionResult);
		Items.SubsystemsTree.Enabled = False;
		Return;
	EndIf;
	
	QueryText =
	"SELECT ALLOWED
	|	ReportsVariants.Ref,
	|	ReportsVariants.PredefinedVariant,
	|	CASE
	|		WHEN ReportsVariants.DeletionMark
	|			THEN 1
	|		WHEN &FullRightsForVariants = FALSE
	|				AND ReportsVariants.Author <> &CurrentUser
	|			THEN 2
	|		WHEN Not ReportsVariants.Report IN (&UserReporting)
	|			THEN 3
	|		WHEN ReportsVariants.Ref IN (&DisabledApplicationOptions)
	|			THEN 4
	|		ELSE 0
	|	END AS Cause
	|INTO ttOptions
	|FROM
	|	Catalog.ReportsVariants AS ReportsVariants
	|WHERE
	|	ReportsVariants.Ref IN(&OptionsArray)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ttOptions.Ref AS Ref,
	|	PredefinedReportsVariantsPlacement.Subsystem AS Subsystem,
	|	PredefinedReportsVariantsPlacement.Important AS Important,
	|	PredefinedReportsVariantsPlacement.SeeAlso AS SeeAlso
	|INTO TTGeneral
	|FROM
	|	ttOptions AS ttOptions
	|		INNER JOIN Catalog.PredefinedReportsVariants.Placement AS PredefinedReportsVariantsPlacement
	|		ON (ttOptions.Cause = 0)
	|			AND ttOptions.PredefinedVariant = PredefinedReportsVariantsPlacement.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReportsVariantsPlacement.Ref AS Ref,
	|	ReportsVariantsPlacement.Use AS Use,
	|	ReportsVariantsPlacement.Subsystem AS Subsystem,
	|	ReportsVariantsPlacement.Important AS Important,
	|	ReportsVariantsPlacement.SeeAlso AS SeeAlso
	|INTO TTDivided
	|FROM
	|	ttOptions AS ttOptions
	|		INNER JOIN Catalog.ReportsVariants.Placement AS ReportsVariantsPlacement
	|		ON (ttOptions.Cause = 0)
	|			AND ttOptions.Ref = ReportsVariantsPlacement.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ttOptions.Ref,
	|	ttOptions.Cause AS Cause
	|FROM
	|	ttOptions AS ttOptions
	|WHERE
	|	ttOptions.Cause <> 0
	|
	|ORDER BY
	|	Cause
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(SettingsSeparatedBy.Subsystem, SettingsGeneral.Subsystem) AS Ref,
	|	SUM(1) AS Quantity,
	|	CASE
	|		WHEN ISNULL(SettingsSeparatedBy.Important, SettingsGeneral.Important) = TRUE
	|			THEN &PresentationImportant
	|		WHEN ISNULL(SettingsSeparatedBy.SeeAlso, SettingsGeneral.SeeAlso) = TRUE
	|			THEN &PresentationSeeAlso
	|		ELSE """"
	|	END AS Importance
	|FROM
	|	TTGeneral AS SettingsGeneral
	|		Full JOIN TTDivided AS SettingsSeparatedBy
	|		ON SettingsGeneral.Ref = SettingsSeparatedBy.Ref
	|			AND SettingsGeneral.Subsystem = SettingsSeparatedBy.Subsystem
	|WHERE
	|	(SettingsSeparatedBy.Use = TRUE
	|			OR SettingsSeparatedBy.Use IS NULL )
	|
	|GROUP BY
	|	ISNULL(SettingsSeparatedBy.Subsystem, SettingsGeneral.Subsystem),
	|	CASE
	|		WHEN ISNULL(SettingsSeparatedBy.Important, SettingsGeneral.Important) = TRUE
	|			THEN &PresentationImportant
	|		WHEN ISNULL(SettingsSeparatedBy.SeeAlso, SettingsGeneral.SeeAlso) = TRUE
	|			THEN &PresentationSeeAlso
	|		ELSE """"
	|	END";
	
	Query = New Query;
	Query.SetParameter("FullRightsForVariants",        ReportsVariants.FullRightsForVariants());
	Query.SetParameter("CurrentUser",          Users.CurrentUser());
	Query.SetParameter("OptionsArray",              CustomizableOptions.UnloadValues());
	Query.SetParameter("UserReporting",           ReportsVariants.CurrentUserReports());
	Query.SetParameter("DisabledApplicationOptions", ReportsVariantsReUse.DisabledApplicationOptions());
	Query.SetParameter("PresentationImportant",          ReportsVariantsClientServer.PresentationImportant());
	Query.SetParameter("PresentationSeeAlso",         ReportsVariantsClientServer.PresentationSeeAlso());
	
	Query.Text = QueryText;
	TemporaryTables = Query.ExecuteBatch();
	
	FilteredVariants = TemporaryTables[3].Unload();
	ErrorsCount = FilteredVariants.Count();
	
	If ErrorsCount > 0 Then
		ExecutionResult = New Structure;
		CurrentCause = 0;
		PrefixRecords = Chars.LF + "    ";
		ErrorsText = "";
		For Each TableRow IN FilteredVariants Do
			If CurrentCause <> TableRow.Cause Then
				CurrentCause = TableRow.Cause;
				ErrorsText = ?(ErrorsText = "", "", ErrorsText + Chars.LF + Chars.LF);
				If CurrentCause = 1 Then
					ErrorsText = ErrorsText + NStr("en='Marked for deletion:';ru='Помеченные на удаление:';vi='Đánh dấu xóa:'");
				ElsIf CurrentCause = 2 Then
					ErrorsText = ErrorsText + NStr("en='Insufficient rights to change:';ru='Недостаточно прав для изменения:';vi='Không đủ quyền để thay đổi:'");
				ElsIf CurrentCause = 3 Then
					ErrorsText = ErrorsText + NStr("en='The report is disabled or unavailable for the rights:';ru='Отчет отключен или недоступен по правам:';vi='Báo cáo đã bị ngắt hoặc không khả dụng đối với quyền:'");
				ElsIf CurrentCause = 4 Then
					ErrorsText = ErrorsText + NStr("en='Report variant is disabled using functional option:';ru='Вариант отчета отключен по функциональной опции:';vi='Phương án báo cáo ngắt bỏ theo tùy chọn chức năng:'");
				EndIf;
			EndIf;
			
			ErrorsText = ErrorsText + Chars.LF + "    - " + String(TableRow.Ref);
			CustomizableOptions.Delete(CustomizableOptions.FindByValue(TableRow.Ref));
		EndDo;
		
		VariantCount = CustomizableOptions.Count();
		
		If VariantCount = 0 Then
			MessageText = NStr("en='Insufficient rights to place the selected report variants in sections.';ru='Недостаточно прав для размещения в разделах выбранных вариантов отчетов.';vi='Không đủ quyền để sắp xếp trên thanh lệnh các phương án báo cáo đã chọn.'");
			Items.SubsystemsTree.Enabled = False;
			ExecutionResult.Insert("Cancel", True);
		Else
			MessageText = NStr("en='Insufficient rights to place some report variants (%1) in sections.';ru='Недостаточно прав для размещения в разделах некоторых вариантов отчетов (%1).';vi='Không đủ quyền để sắp xếp trên thanh lệnh nhiều phương án báo cáo (%1).'");
			MessageText = StrReplace(MessageText, "%1", Format(ErrorsCount, "NG="));
			Items.SubsystemsTree.Enabled = True;
		EndIf;
		
		StandardSubsystemsClientServer.DisplayWarning(ExecutionResult, MessageText, ErrorsText);
		ExecutionResult = New FixedStructure(ExecutionResult);
	Else
		Items.SubsystemsTree.Enabled = True;
	EndIf;
	
	SubsystemsOccurrences = TemporaryTables[4].Unload();
	
	TreeSource = ReportsVariantsReUse.CurrentUserSubsystems();
	
	TreeReceiver = FormAttributeToValue("SubsystemsTree", Type("ValueTree"));
	TreeReceiver.Rows.Clear();
	
	AddSubsystemsToTree(TreeReceiver, TreeSource, SubsystemsOccurrences);
	
	ValueToFormAttribute(TreeReceiver, "SubsystemsTree");
EndProcedure

&AtServer
Procedure WriteAtServer()
	Cache = New Structure;
	
	BeginTransaction();
	For Each ItemOfList IN CustomizableOptions Do
		VariantObject = ItemOfList.Value.GetObject();
		ReportsVariants.SubsystemsTreeWrite(ThisObject, VariantObject, Cache);
		VariantObject.Write();
	EndDo;
	CommitTransaction();
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Server

&AtServer
Procedure AddSubsystemsToTree(ReceiverParent, SourceParent, SubsystemsOccurrences)
	For Each Source IN SourceParent.Rows Do
		
		Receiver = ReceiverParent.Rows.Add();
		FillPropertyValues(Receiver, Source);
		
		ThisSubsystemOccurrence = SubsystemsOccurrences.Copy(New Structure("Ref", Receiver.Ref));
		If ThisSubsystemOccurrence.Count() = 1 Then
			Receiver.Importance = ThisSubsystemOccurrence[0].Importance;
		ElsIf ThisSubsystemOccurrence.Count() = 0 Then
			Receiver.Importance = "";
		Else
			Receiver.Importance = MixedImportance; // It is also used for conditional formatting.
		EndIf;
		
		VariantsOccurrence = ThisSubsystemOccurrence.Total("Quantity");
		If VariantsOccurrence = VariantCount Then
			Receiver.Use = 1;
		ElsIf VariantsOccurrence = 0 Then
			Receiver.Use = 0;
		Else
			Receiver.Use = 2;
		EndIf;
		
		// Recursion
		AddSubsystemsToTree(Receiver, Source, SubsystemsOccurrences);
	EndDo;
EndProcedure

#EndRegion
