&AtClient
Var HandlerParameters;

&AtClient
Var ClosingFormConfirmation;

&AtClient
Var LongOperationForm;

#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then
		Return;
	EndIf;
	
	If Parameters.Script = "SearchRefs" OR Parameters.Script = "InsertionFromClipboard" Then
		ImportType = "InsertionFromClipboard";
	ElsIf ValueIsFilled(Parameters.TabularSectionFullName) Then
		ImportType = "TabularSection";
	ElsIf Not Users.InfobaseUserWithFullAccess() Then
		Raise(NStr("en='Insufficient rights to open data import from file';ru='Недостаточно прав для открытия загрузки данных из файла';vi='Không đủ quyền để mở kết nhập dữ liệu từ tệp'"));
		Cancel = True;
		Return;
	EndIf;
	
	AdditionalParameters = Parameters.AdditionalParameters;
	ClosingFormConfirmation = Undefined;
	SetDataDesign();
	StandardSubsystemsServer.SetGroupHeadersDisplay(ThisObject);
	
	CreateIfNotMatched = 1;
	UpdateExisting = 0;
	
	If ValueIsFilled(Parameters.Title) Then 
		ThisObject.AutoTitle = False;
		ThisObject.Title = Parameters.Title;
	Else
		ThisObject.AutoTitle = False;
		ThisObject.Title = NStr("en='Data import to catalog';ru='Загрузка данных в справочник';vi='Kết nhập dữ liệu vào danh mục'")
	EndIf;
	
	WebClient = CommonUseClientServer.ThisIsWebClient();
	If WebClient Then
		Items.PageVariantTableFilling.Visible = False;
		Items.DataFillingPages.CurrentPage = Items.PageVariantLoadFromFile;
		Items.ImportingOption.Visible = False;
		Items.ExplanationForImportCatalogSelection.Title = NStr("en='Select a catalog to import data from spreadsheets located in external files (for example: Microsoft Office Excel, OpenOffice Calc, etc.).';ru='Выбор справочника для загрузки данных из электронных таблиц, расположенных во внешних файлах (например: Microsoft Office Excel, OpenOffice Calc и др.).';vi='Chọn danh mục để kết nhập dữ liệu từ bảng điện tử nằm trong các tệp ngoài (ví dụ: Microsoft Office Excel, OpenOffice Calc...).'");
		DataImportKind = 1;
	EndIf;
	
	If ImportType = "InsertionFromClipboard" Then
		FilterComparisonTable = "Unmapped";
		If Parameters.Property("FieldPresentation") Then
			Title = NStr("en='Insert from clipboard';ru='Вставить из буфера обмена';vi='Chèn từ bộ đệm trao đổi'") + " (" + Parameters.FieldPresentation + ")";
			ThisObject.AutoTitle = False;
		Else
			Title = NStr("en='Insert from clipboard';ru='Вставить из буфера обмена';vi='Chèn từ bộ đệm trao đổi'");
		EndIf;
		
		DataProcessors.DataLoadFromFile.InitializeSearchRefsMode(TemplateWithData, InformationByColumns, Parameters.TypeDescription);
		CreateMatchTableByInformationAboutColumnsAuto(Parameters.TypeDescription);
		
		If InformationByColumns.Count() = 1 Then
			Items.DataFillingPages.CurrentPage = Items.PageOneColumn;
			Items.ImportingOption.Visible = False;
			Items.InsertIntoList.Visible = False;
			Items.Next.Title = NStr("en='Add to list';ru='Добавление в список';vi='Thêm vào danh sách'");
		Else
			Items.DataFillingPages.CurrentPage = Items.PageManyColumns;
		EndIf;
		
		Items.AssistantPages.CurrentPage = Items.FillingTablesWithData;
		Items.GroupComparisonSettings.Visible = False;
		Items.MatchingColumnsList.Visible = False;
		Items.Close.Title = NStr("en='Cancel';ru='Отменить';vi='Hủy bỏ'");
		
	Else
		If Not ValueIsFilled(Parameters.TabularSectionFullName) Then 
			
			// SB
			If Parameters.Property("SelectionRowDescription") Then
				
				ExecuteStepFillingTableWithDataOnServer(Parameters.SelectionRowDescription);
				Items.AssistantPages.CurrentPage = Items.FillingTablesWithData;
				
			Else
				
				FillListDataImportKind();
				Items.AssistantPages.CurrentPage = Items.CatalogSelectionForImport;
				
			EndIf;
			// SB End
			
		Else
			CorrelationObjectName = DataProcessors.DataLoadFromFile.ObjectFullNameTabularSection(Parameters.TabularSectionFullName);
			
			TableInformationByColumns = CommonUse.CommonSettingsStorageImport("DataLoadFromFile", CorrelationObjectName,, UserName());
			If TableInformationByColumns = Undefined Then
				TableInformationByColumns = FormAttributeToValue("InformationByColumns");
			EndIf;
			
			DataProcessors.DataLoadFromFile.InitializeImportToTabularSection(CorrelationObjectName, Parameters.TemplateNameWithTemplate, TableInformationByColumns, TemplateWithData, AdditionalParameters, Cancel);
			If Cancel Then
				Return;
			EndIf;
			ValueToFormAttribute(TableInformationByColumns, "InformationByColumns");
			
			ShowInformationRowAboutMandatoryColumns();
			ChangeFormForInformationByColumns();
			Items.AssistantPages.CurrentPage = Items.FillingTablesWithData;
			Items.GroupComparisonSettings.Visible = False;
			Items.MatchingColumnsList.Visible = False;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If ClosingFormConfirmation = Undefined Then
		Return;
	EndIf;
	
	Cancel = Cancel Or (ClosingFormConfirmation <> True);
	If Exit Then
		WarningText = NStr("en = 'Entered data will not be written..'; ru = 'Введенные данные не будут записаны.'; vi = 'Sẽ ghi lại dữ liệu đã nhập.'");
		Return;
	EndIf;
		
	If Cancel Then
		Notification = New NotifyDescription("CloseFormEnd", ThisObject);
			QuestionText = NStr("en='Entered data will not be written. Close the form?';ru='Введенные данные не будут записаны. Закрыть форму?';vi='Sẽ ghi lại dữ liệu đã nhập. Đóng biểu mẫu?'");
		ShowQueryBox(Notification, QuestionText, QuestionDialogMode.YesNo);
	Else
		If OpenCatalogAfterAssistantClosing Then 
			OpenForm(ListForm(CorrelationObjectName));
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure CancelMapping(Command)
	Notification = New NotifyDescription("AfterQuestionAboutCancelMatch", ThisObject);
	ShowQueryBox(Notification, NStr("en='Cancel mapping?';ru='Отменить сопоставление?';vi='Hủy đặt tương ứng?'"), QuestionDialogMode.YesNo);
EndProcedure

&AtClient
Procedure ChangeForm(Command)
	FormParameters = New Structure();
	FormParameters.Insert("InformationByColumns", InformationByColumns);
	FormParameters.Insert("CorrelationObjectName", CorrelationObjectName);
		
	Notification = New NotifyDescription("AfterCallingFormChangeForm", ThisObject);
	OpenForm("DataProcessor.DataLoadFromFile.Form.FormEditing", FormParameters, ThisObject,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure EnableAmbiguity(Command)
	OpenAmbiguityPermissionForm(Items.DataMatchingTable.CurrentRow,Items.DataMatchingTable.CurrentItem.Name, True);
EndProcedure

&AtClient
Procedure InsertIntoList(Command)
	CloseFormAndReturnRefsArray();
EndProcedure

&AtClient
Procedure Next(Command)
	TransferToImportDataNextStep();
EndProcedure

&AtClient
Procedure AfterQuestionAboutInsertIntoTabularSection(Result, AdditionalParameters) Export 
	If Result = DialogReturnCode.Yes Then 
		ImportedDataAddress = AddressInTableMatchStorage();
		Close(ImportedDataAddress);
	EndIf;
EndProcedure

&AtServer
Procedure FillMatchTableFromTemporaryStorage()
	MatchedData = GetFromTempStorage(BackgroundJobStorageAddress);
	ValueToFormAttribute(MatchedData, "DataMatchingTable");
EndProcedure

&AtClient
Procedure CloseFormAndReturnRefsArray()
	ClosingFormConfirmation = True;
	RefArray = New Array;
	For Each String IN DataMatchingTable Do
		If ValueIsFilled(String.MappingObject) Then
			RefArray.Add(String.MappingObject);
		EndIf;
	EndDo;
	
	Close(RefArray);
EndProcedure

&AtClient
Procedure Back(Command)
	
	If Items.AssistantPages.CurrentPage = Items.FillingTablesWithData Then
		Items.AssistantPages.CurrentPage = Items.CatalogSelectionForImport;
		Items.Back.Visible = False;
		CommonUseClientServer.SetFormItemProperty(Items, "AnotherWayToImportData", "Visible", True); // SB
		ThisObject.Title = NStr("en='Data import to catalog';ru='Загрузка данных в справочник';vi='Kết nhập dữ liệu vào danh mục'");
		ClearTable();
	ElsIf Items.AssistantPages.CurrentPage = Items.ExportedDataComparison OR Items.AssistantPages.CurrentPage = Items.NotFound Then
		Items.AssistantPages.CurrentPage = Items.FillingTablesWithData; 
		Items.InsertIntoList.Visible = False;
		Items.Next.DefaultButton = True;
		Items.Next.Visible = True;
		If ImportType = "InsertionFromClipboard" Then 
			Items.Next.Title = NStr("en='Add to list';ru='Добавление в список';vi='Thêm vào danh sách'");
		Else
			Items.Next.Title = NStr("en='Next >';ru='Далее  >';vi='Tiếp theo >'");
		EndIf;
		If ImportType = "TabularSection" OR ImportType = "InsertionFromClipboard" Then
			Items.Back.Visible = False;
			CommonUseClientServer.SetFormItemProperty(Items, "AnotherWayToImportData", "Visible", True); // SB
		EndIf;
		Items.Back.Visible = (NOT VariantListImports.Count() = 0); // SB
	ElsIf Items.AssistantPages.CurrentPage = Items.ReportOnDataImport Then
		Items.OpenCatalogAfterAssistantClosing.Visible = False;
		Items.AssistantPages.CurrentPage = Items.ExportedDataComparison;
	EndIf;
	
EndProcedure

&AtClient
Procedure ExportTemplateToFile(Command)
	
	If AttachFileSystemExtension() Then
		If CommonUseClient.SubsystemExists("StandardSubsystems.FileFunctions") Then
			ModuleFileFunctionsServiceClient = CommonUseClient.CommonModule("FileFunctionsServiceClient");
			PathToFile = ModuleFileFunctionsServiceClient.MyDocumentsDir();
		Else
			PathToFile = "";
		EndIf;
		
		FileName = GenerateFileNameForMetadataObject(CorrelationObjectName);
		GetPathToFileSelectionBegin(FileDialogMode.Save, PathToFile, FileName);
		SelectedFile = CommonUseClientServer.SplitFullFileName(PathToFile);
		FileExtension = CommonUseClientServer.ExtensionWithoutDot(SelectedFile.Extension);
		If ValueIsFilled(SelectedFile.Name) Then
			If FileExtension = "csv" Then
				SaveTableToCSVFile(PathToFile);
			ElsIf FileExtension = "xlsx" Then
				AddressInTemporaryStorage = TabularDocumentDeleteNotes();
				TabularDocumentWithoutNotes = GetFromTempStorage(AddressInTemporaryStorage);
				TabularDocumentWithoutNotes.Write(PathToFile, SpreadsheetDocumentFileType.xlsx);
				TemplateWithData = TabularDocumentWithoutNotes;
			ElsIf FileExtension = "mxl" Then
				TemplateWithData.Write(PathToFile, SpreadsheetDocumentFileType.mxl);
			Else
				ShowMessageBox(, NStr("en='File template was not saved.';ru='Шаблон файла не был сохранен.';vi='Khuôn mẫu tệp chưa được lưu lại.'"));
			EndIf;
		EndIf;
	Else
		Notification = New NotifyDescription("AfterSelectingFileExtension", ThisObject);
		OpenForm("DataProcessor.DataLoadFromFile.Form.FileExtension",, ThisObject, True,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
		PathToFile = "";
	EndIf;

EndProcedure

// Function to crawl a saving error if there are notes in the document.
//
&AtServer
Function TabularDocumentDeleteNotes()
	TabularDocumentToSave = New SpreadsheetDocument;
	ChangeFormForInformationByColumns(TabularDocumentToSave);
	AddressInTemporaryStorage = PutToTempStorage(TabularDocumentToSave);
	Return AddressInTemporaryStorage;
EndFunction

&AtClient
Procedure ImportTemplateFromFile(Command)
	
	FullFileName = "";
	Interactively = True;
	If AttachFileSystemExtension() Then
		If CommonUseClient.SubsystemExists("StandardSubsystems.FileFunctions") Then
			ModuleFileFunctionsServiceClient = CommonUseClient.CommonModule("FileFunctionsServiceClient");
			PathToFile = ModuleFileFunctionsServiceClient.MyDocumentsDir();
		Else
			PathToFile = "";
		EndIf;
		
		FileName = GenerateFileNameForMetadataObject(CorrelationObjectName);
		GetPathToFileSelectionBegin(FileDialogMode.Open, PathToFile, "");
		SelectedFile = CommonUseClientServer.SplitFullFileName(PathToFile);
		FileExtension = CommonUseClientServer.ExtensionWithoutDot(SelectedFile.Extension);
		If ValueIsFilled(SelectedFile.Name) Then
			FullFileName = SelectedFile.DescriptionFull;
			Interactively = False;
		Else
			Return;
		EndIf;
	EndIf;
	TemporaryStorageAddress = "";
	Notification = New NotifyDescription("OnEndPlacingFile", ThisObject);
	BeginPutFile(Notification, TemporaryStorageAddress, FullFileName, Interactively);
	TableReport.FixedTop = 1;
	
EndProcedure

#EndRegion

#Region HeaderFormItemsEventsHandlers

&AtClient
Procedure FilterReportOnChange(Item)

	BackgroundJobReportOnClient();
	
	If FilterReport = "Skipped" Then 
		Items.ChangeAttributes.Enabled=False;
	Else
		Items.ChangeAttributes.Enabled=True;
	EndIf;
EndProcedure

&AtClient
Procedure FilterComparisonTableOnChange(Item)
	SetMatchTableFilter();
EndProcedure

&AtClient
Procedure SetMatchTableFilter()

	Filter = FilterComparisonTable;
	
	If ImportType = "TabularSection" Then
		If Filter = "Mapped" Then
			Items.DataMatchingTable.RowFilter = New FixedStructure("RowMatchResult", "RowMatched"); 
		ElsIf Filter = "Unmapped" Then 
			Items.DataMatchingTable.RowFilter = New FixedStructure("RowMatchResult", "NotMatched"); 
		ElsIf Filter = "Ambiguous" Then 
			Items.DataMatchingTable.RowFilter = New FixedStructure("ErrorDescription", "");
		Else
			Items.DataMatchingTable.RowFilter = Undefined;
		EndIf;
	ElsIf ImportType = "InsertionFromClipboard" Then
		If Filter = "Mapped" Then 
			Items.DataMatchingTable.RowFilter = New FixedStructure("RowMatchResult", "RowMatched");
		ElsIf Filter = "Unmapped" Then
			Items.DataMatchingTable.RowFilter = New FixedStructure("RowMatchResult", "Not");
		ElsIf Filter = "Ambiguous" Then
			Items.DataMatchingTable.RowFilter = New FixedStructure("RowMatchResult", "Ambiguity");
		Else
			Items.DataMatchingTable.RowFilter = Undefined;
		EndIf;
	Else
		If Filter = "Mapped" Then 
			Items.DataMatchingTable.RowFilter = New FixedStructure("RowMatchResult", "RowMatched");
		ElsIf Filter = "Unmapped" Then 
			Items.DataMatchingTable.RowFilter = New FixedStructure("RowMatchResult", "Not");
		ElsIf Filter = "Ambiguous" Then 
			Items.DataMatchingTable.RowFilter = New FixedStructure("RowMatchResult", "Ambiguity"); 
		Else
			Items.DataMatchingTable.RowFilter = Undefined;
		EndIf;
	EndIf;

EndProcedure


&AtClient
Procedure ColumnsListMatchingSelectionStart(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	
	If MatchByColumn.Count() = 0 Then
		For Each string IN InformationByColumns Do
			If ValueIsFilled(String.Synonym) Then
				ColumnPresentation = String.Synonym;
			Else
				ColumnPresentation = String.ColumnPresentation;
			EndIf;
			MatchByColumn.Add(string.ColumnName, ColumnPresentation);
		EndDo;
	EndIf;
	FormParameters  = New Structure("ListColumns", MatchByColumn);
	NotifyDescription  = New NotifyDescription("AfterSelectingColumnsForMatch", ThisObject);
	OpenForm("DataProcessor.DataLoadFromFile.Form.ColumnSelection", FormParameters, ThisObject, , , , NotifyDescription, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure AfterSelectingColumnsForMatch(Result, Parameter) Export
	
	If Result = Undefined Then 
		Return;
	EndIf;
		 
	MatchByColumn = Result;
	ColumnsInRow = "";
	Delimiter = "";
	SelectedColumnsQuantity = 0;
	For Each Item IN MatchByColumn Do 
		If Item.Check Then 
			ColumnsInRow = ColumnsInRow + Delimiter + Item.Presentation;
			Delimiter = ", ";
			SelectedColumnsQuantity = SelectedColumnsQuantity + 1;
		EndIf;
	EndDo;
	
	MatchingColumnsList = ColumnsInRow;
	PerformMapping();
EndProcedure

&AtClient
Procedure ImportingOptionOnChange(Item)
	
	If ImportingOption = 0 Then
		Items.DataFillingPages.CurrentPage = Items.PageVariantTableFilling;
	Else
		Items.DataFillingPages.CurrentPage = Items.PageVariantLoadFromFile;
	EndIf;
	
	ShowInformationRowAboutMandatoryColumns();
	
EndProcedure

#EndRegion

#Region TableItemsEventHandlersDataImportKind

&AtClient
Procedure DataImportKindValueSelection(Item, Value, StandardProcessing)
	StandardProcessing = False;
	TransferToImportDataNextStep();
EndProcedure


&AtClient
Procedure DataImportKindBeforeChange(Item, Cancel)
	Cancel = True;
EndProcedure

#EndRegion


#Region FormTableItemsEventsHandlersTemplateWithData

&AtClient
Procedure TemplateWithDataSelection(Item, Area, StandardProcessing)
	If Area.Top = 1 Then 
		StandardProcessing = False; // You can not edit a header
	EndIf;
EndProcedure

#EndRegion

#Region DataMatchTableItemsEventsHandlers

&AtClient
Procedure DataMatchingTableOnEditEnd(Item, NewRow, CancelEdit)
	
	If ImportType <> "TabularSection" Then
		If ValueIsFilled(Item.CurrentData.MappingObject) Then 
			Item.CurrentData.RowMatchResult = "RowMatched";
		Else
			Item.CurrentData.RowMatchResult = "NotMatched";
		EndIf;
	Else
		Filter = New Structure("ObligatoryToComplete", True);
		MandatoryToCompleteColumns = InformationByColumns.FindRows(Filter);
		RowMatchResult = "RowMatched";
		For Each TableColumn IN MandatoryToCompleteColumns Do
			If Not ValueIsFilled(Item.CurrentData["CWT_" + TableColumn.Association]) Then
				RowMatchResult = "NotMatched";
				Break;
			EndIf;
		EndDo;
		Item.CurrentData.RowMatchResult = RowMatchResult;
	EndIf;
	
	ShowStatisticsByMatchLoadFromFile();
	
EndProcedure

&AtClient
Procedure DataMatchingTableOnActivateCell(Item)
	Items.EnableAmbiguity.Enabled = False;
	Items.DataMatchingTableContextMenuDisambiguate.Enabled = False;
	
	If Item.CurrentData <> Undefined AND ValueIsFilled(Item.CurrentData.RowMatchResult) Then 
		If ImportType = "TabularSection" Then 
			If StrLen(Item.CurrentItem.Name) > 3 AND Left(Item.CurrentItem.Name,3) = "CWT_" Then
				ColumnName = Mid(Item.CurrentItem.Name, 4);
				If Find(Item.CurrentData.ErrorDescription, ColumnName) > 0 Then 
					Items.EnableAmbiguity.Enabled = True;
					Items.DataMatchingTableContextMenuDisambiguate.Enabled = True;
				EndIf;
			EndIf;
		ElsIf Item.CurrentData.RowMatchResult = "Ambiguity" Then 
			Items.EnableAmbiguity.Enabled = True;
			Items.DataMatchingTableContextMenuDisambiguate.Enabled = True;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure DataMatchingTableChoice(Item, SelectedRow, Field, StandardProcessing)
	OpenAmbiguityPermissionForm(SelectedRow, Field.Name, StandardProcessing);
EndProcedure

#EndRegion

#Region TableItemsEventsHandlersReport

&AtClient
Procedure TableReportOnActivateArea(Item)
	If TableReport.CurrentArea.Bottom = 1 AND TableReport.CurrentArea.Top = 1 Then
		Items.ChangeAttributes.Enabled = False;
	Else
		Items.ChangeAttributes.Enabled = True;
	EndIf;
EndProcedure

&AtClient
Procedure GroupAttributeChange(Command)
	
	If CommonUseClient.SubsystemExists("StandardSubsystems.GroupObjectsChange") Then
		If TableReport.CurrentArea.Top = 1 Then
			UpperPosition = 2;
		Else
			UpperPosition = TableReport.CurrentArea.Top;
		EndIf;
		RefArray = GroupAttributeChangeOnServer(UpperPosition, TableReport.CurrentArea.Bottom);
		If RefArray.Count() > 0 Then
			FormParameters = New Structure("ObjectsArray", RefArray);
			ObjectName = "DataProcessor.";
			OpenForm(ObjectName + "GroupAttributeChange.Form", FormParameters);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

/////////////////////////////////////// CLIENT ///////////////////////////////////////////

// End dialog of form closing.
&AtClient
Procedure CloseFormEnd(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult = DialogReturnCode.Yes Then
		ClosingFormConfirmation = True;
		Close();
	Else 
		ClosingFormConfirmation = False;
	EndIf;
EndProcedure


&AtClient
Procedure TransferToImportDataNextStep()
	
	If Items.AssistantPages.CurrentPage = Items.CatalogSelectionForImport Then 
		SelectionRowDescription = Items.DataImportKind.CurrentData.Value;
		ExecuteStepFillingTableWithDataOnServer(SelectionRowDescription);
		ExecuteStepFillingTableWithDataOnClient();
	ElsIf Items.AssistantPages.CurrentPage = Items.FillingTablesWithData Then
		ExecuteImportedDataMatchStep();
	ElsIf Items.AssistantPages.CurrentPage = Items.ComparisonResults Then
		Items.AssistantPages.CurrentPage = Items.ExportedDataComparison;
		Items.InsertIntoList.Visible = False;
		Items.Next.Title = NStr("en='Add to list';ru='Добавление в список';vi='Thêm vào danh sách'");
		Items.Next.DefaultButton = True;
		Items.Back.Title = NStr("en='< Home';ru='< Home';vi='< Trang chủ'");
	ElsIf Items.AssistantPages.CurrentPage = Items.ExportedDataComparison Then
		Items.InsertIntoList.Visible = False;
		If ImportType = "TabularSection" Then
			ClosingFormConfirmation = True;
			Filter = New Structure("RowMatchResult", "NotMatched");
			Rows = DataMatchingTable.FindRows(Filter);
			
			If Rows.Count() > 0 Then
				Notification = New NotifyDescription("AfterQuestionAboutInsertIntoTabularSection", ThisObject);
				ShowQueryBox(Notification, NStr("en='Strings with blank required columns will be skipped.';ru='Строки в которых не заполнены обязательные колонки будут пропущены.';vi='Dòng mà trong đó chưa điền các cột bắt buộc sẽ bị bỏ qua.'") + 
				Chars.LF + NStr("en='Continue?';ru='Продолжить?';vi='Tiếp tục?'"), QuestionDialogMode.YesNo);
				Return;
			EndIf;
			
			ImportedDataAddress = AddressInTableMatchStorage();
			Close(ImportedDataAddress);
			
		ElsIf ImportType = "InsertionFromClipboard" Then
			Items.Back.Title = NStr("en='< Home_';ru='< Home_';vi='< Trang chủ_'");
			ClosingFormConfirmation = True;
			CloseFormAndReturnRefsArray();
		Else
			Items.AssistantPages.CurrentPage = Items.LongActions;
			WriteImportedDataClient();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterAmbiguitiesMatch(Result, Parameter) Export
	
	If ImportType  = "TabularSection" Then
		If Result <> Undefined Then
			String = DataMatchingTable.FindByID(Parameter.ID);
			
			String["CWT_" +  Parameter.Name] = Result;
			String.ErrorDescription = StrReplace(String.ErrorDescription, Parameter.Name+";", "");
			String.RowMatchResult = ?(StrLen(String.ErrorDescription) = 0, "RowMatched", "NotMatched");
		EndIf;
	Else
		String = DataMatchingTable.FindByID(Parameter.ID);
		String.MappingObject = Result;
		If Result <> Undefined Then
			String.RowMatchResult = "RowMatched";
			String.AmbiguitiesList = Undefined;
		Else 
			If String.RowMatchResult <> "Ambiguity" Then 
				String.RowMatchResult = "NotMatched";
				String.AmbiguitiesList = Undefined;
			EndIf;
		EndIf;
	EndIf;
	
	ShowStatisticsByMatchLoadFromFile();
	
EndProcedure

&AtClient
Procedure PerformMapping()
	MatchedQuantityByColumns = 0;
	ListColumns = "";
	ExecuteMatchBySelectedAttribute(MatchedQuantityByColumns, ListColumns);
	ShowUserNotification(NStr("en='Mapped';ru='Выполнено сопоставление';vi='Đã so sánh'"),, NStr("en='Items mapped:';ru='Сопоставлено элементов:';vi='Đã so sánh các phần tử:'") + " " + String(MatchedQuantityByColumns));
	ShowStatisticsByMatchLoadFromFile();
EndProcedure

&AtClient
Function AllDataMapped()
	Filter = New Structure("RowMatchResult", "RowMatched");
	Result = DataMatchingTable.FindRows(Filter);
	MatchedQuantity = Result.Count();
	
	If DataMatchingTable.Count() = MatchedQuantity Then 
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

&AtClient
Function MatchStatistics()
	Filter = New Structure("RowMatchResult", "RowMatched");
	Result = DataMatchingTable.FindRows(Filter);
	MatchedQuantity = Result.Count();
	
	If ImportType = "InsertionFromClipboard" Then
		Filter = New Structure("RowMatchResult", "NotMatched");
		Result = DataMatchingTable.FindRows(Filter);
	Else
		Filter = New Structure("ErrorDescription", "");
		Result = DataMatchingTable.FindRows(Filter);
	EndIf;
	AmbiguousQuantity  = DataMatchingTable.Count() - Result.Count();
	
	NotMatchedQuantity = DataMatchingTable.Count() - MatchedQuantity;
	
	Result = New Structure;
	Result.Insert("TotalAmount", DataMatchingTable.Count());
	Result.Insert("Matched", MatchedQuantity);
	Result.Insert("Ambiguous", AmbiguousQuantity);
	Result.Insert("Unmatched", NotMatchedQuantity);
	Result.Insert("NotFound", NotMatchedQuantity - AmbiguousQuantity);
	
	Return Result;
	
EndFunction

&AtClient
Procedure ShowStatisticsByMatchLoadFromFile()
	
	Statistics = MatchStatistics();
	
	DataAboutMatch = MatchStatistics();
	
	TextAll = StringFunctionsClientServer.SubstituteParametersInString(NStr("en='All (%1)';ru='Все (%1)';vi='Tất cả (%1)'"), Statistics.TotalAmount);
	
	Items.CreateIfNotMatched.Title = NStr("en='Unmapped (';ru='Несопоставленные (';vi='Không tương ứng ('") + Statistics.Unmatched + ")";
	Items.UpdateExisting.Title = NStr("en='Mapped items (';ru='Сопоставленные элементы (';vi='Các phần tử so sánh ('") + String(Statistics.Matched) + ")";
	
	ChoiceList = Items.FilterComparisonTable.ChoiceList;
	ChoiceList.Clear();
	ChoiceList.Add("All", TextAll, True);
	ChoiceList.Add("Unmapped", StringFunctionsClientServer.SubstituteParametersInString(
	NStr("en='Unmapped (%1 out of %2)';ru='Несопоставленные (%1 из %2)';vi='Không tương ứng (%1 trong số %2)'"), Statistics.Unmatched, Statistics.TotalAmount));
	ChoiceList.Add("Mapped", StringFunctionsClientServer.SubstituteParametersInString(
	NStr("en='Mapped (%1 of %2)';ru='Сопоставленные (%1 из %2)';vi='So sánh (%1 từ %2)'"), Statistics.Matched, Statistics.TotalAmount));
	ChoiceList.Add("Ambiguous", StringFunctionsClientServer.SubstituteParametersInString(
	NStr("en='Ambiguous (%1 out of %2)';ru='Неоднозначные (%1 из %2)';vi='Không đơn trị (%1 trong số %2)'"), Statistics.Ambiguous, Statistics.TotalAmount));
	
	If Statistics.Ambiguous > 0 Then 
		Items.DescriptionAmbiguity.Visible=True;
		Items.DescriptionAmbiguity.Title = StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en='(ambiguities:% 1)';ru='(неоднозначностей: %1)';vi='(không đồng nhất: %1)'"), Statistics.Ambiguous);
	Else 
		Items.DescriptionAmbiguity.Visible=False;
	EndIf;
	
	If Not ValueIsFilled(FilterComparisonTable) Then 
		FilterComparisonTable = "Unmapped";
	EndIf;
	
	If ImportType = "InsertionFromClipboard" Then
		SetMatchTableFilter();
	Else
		SetMatchTableFilter();
	EndIf;
	
EndProcedure

#Region LoadVariantSelectionStep

&AtServer
Procedure FillListDataImportKind()
	DataProcessors.DataLoadFromFile.CreateCatalogsListForImport(VariantListImports);
EndProcedure 

#EndRegion

#Region StepFillingTableWithData

&AtClient
Procedure ExecuteStepFillingTableWithDataOnClient()
	
	Items.AssistantPages.CurrentPage = Items.FillingTablesWithData;
	Items.Back.Visible = True;
	
	CommonUseClientServer.SetFormItemProperty(Items, "AnotherWayToImportData", "Visible", False); // SB
	
EndProcedure

&AtClient
Function TableWithDataEmpty()
	If InformationByColumns.Count() = 1 AND TemplateWithData.TableHeight < 2 Then
		If Not ValueIsFilled(TemplateWithDataOneColumn) Then
			Return True;
		EndIf;
		CopyOneColumnToTemplateWithData();
	Else 
		If TemplateWithData.TableHeight < 2 Then
			Return True;
		EndIf;
	EndIf;
	
	Return False;
EndFunction

&AtServerNoContext
Function GetMetadataObjectFullName(Name)
	MetadataObject = Metadata.Catalogs.Find(Name);
	If MetadataObject <> Undefined Then 
		Return MetadataObject.FullName();
	EndIf;
	MetadataObject = Metadata.Documents.Find(Name);
	If MetadataObject <> Undefined Then 
		Return MetadataObject.FullName();
	EndIf;
	MetadataObject = Metadata.ChartsOfCharacteristicTypes.Find(Name);
	If MetadataObject <> Undefined Then 
		Return MetadataObject.FullName();
	EndIf;
	
	Return Undefined;
EndFunction

&AtServer
Procedure ExecuteStepFillingTableWithDataOnServer(SelectionRowDescription)
	
	If Find(SelectionRowDescription.FullMetadataObjectName, ".") > 0 Then
		CorrelationObjectName = SelectionRowDescription.FullMetadataObjectName;
	Else
		CorrelationObjectName = GetMetadataObjectFullName(SelectionRowDescription.FullMetadataObjectName);
	EndIf;
	
	ImportType = SelectionRowDescription.Type;
	If ImportType = "OuterImport" Then
		ExternalProcessingRef = SelectionRowDescription.Ref;
	EndIf;
	
	FormTemplateByImportType();
	CreateMatchTableByInformationAboutColumns();
	ShowInformationRowAboutMandatoryColumns();
	
EndProcedure

&AtServer
Procedure FormTemplateByImportType()
	
	ExportParameters = New Structure;
	If ImportType = "UniversalImport" Then
		ThisObject.Title = NStr("en='Import data to catalog ""';ru='Загрузка данных в справочник ""';vi='Kết nhập dữ liệu vào danh mục ""'") + CatalogPresentation(CorrelationObjectName)+"""";
		ThisObject.AutoTitle = False;
	ElsIf ImportType = "AppliedImport" Then
		DefineImportParameters(ExportParameters);
		ThisObject.AutoTitle = False;
		If ExportParameters.Property("Title") Then
			ThisObject.Title = ExportParameters.Title;
		Else
			ThisObject.Title = NStr("en='Import data to catalog ""';ru='Загрузка данных в справочник ""';vi='Kết nhập dữ liệu vào danh mục ""'") + CatalogPresentation(CorrelationObjectName)+"""";
		EndIf;
	ElsIf ImportType = "OuterImport" Then
		CommandID = CorrelationObjectName;
		ExportParameters = DataProcessors.DataLoadFromFile.LoadFromFileParametersExternalProcessing(CorrelationObjectName,
			ExternalProcessingRef); 
	EndIf;
	ExportParameters.Insert("ImportType", ImportType);
	ExportParameters.Insert("FullObjectName", CorrelationObjectName);
	
	GenerateTemplate(ExportParameters);
EndProcedure


&AtServer
Procedure GenerateTemplate(ExportParameters)
	
	InformationByColumnsTable = CommonUse.CommonSettingsStorageImport("DataLoadFromFile", CorrelationObjectName,, UserName());
	If InformationByColumnsTable = Undefined Then
		InformationByColumnsTable = FormAttributeToValue("InformationByColumns");
	EndIf;
	DataProcessors.DataLoadFromFile.DefineInformationByColumns(ExportParameters, InformationByColumnsTable);
	ValueToFormAttribute(InformationByColumnsTable, "InformationByColumns");
	
	ChangeFormForInformationByColumns();
	
	
EndProcedure

&AtServer
Procedure SaveTableToCSVFile(FullFileName)
	DataProcessors.DataLoadFromFile.SaveTableToCSVFile(FullFileName, InformationByColumns);
EndProcedure

#EndRegion

#Region StepMatchImportedData

&AtServer
Procedure CopyOneColumnToTemplateWithData()
	
	ClearTemplateWithData();
	
	LineCount = StrLineCount(TemplateWithDataOneColumn);
	LineNumberInTemplate = 2;
	For LineNumber = 1 To LineCount Do 
		String = StrGetLine(TemplateWithDataOneColumn, LineNumber);
		If ValueIsFilled(String) Then
			Cell = TemplateWithData.GetArea(LineNumberInTemplate, 1, LineNumberInTemplate, 1);
			Cell.CurrentArea.Text = String;
			TemplateWithData.Put(Cell);
			LineNumberInTemplate = LineNumberInTemplate + 1;
		EndIf;
	EndDo;
EndProcedure

&AtServer
Function CreateTableWithAmbiguitiesList()
	AmbiguitiesList = New ValueTable;
	AmbiguitiesList.Columns.Add("ID");
	AmbiguitiesList.Columns.Add("Column");
	
	Return AmbiguitiesList;
EndFunction

&AtServer
Procedure ExecuteImportedDataMatchStepOnServer(BackgroundJob = False)
	
	MappingTable = FormAttributeToValue("DataMatchingTable");
	If ImportType = "TabularSection" Then
		ImportedDataAddress = "";
		TabularSectionCopyAddress = "";
		AmbiguitiesList = CreateTableWithAmbiguitiesList();
		
		DataProcessors.DataLoadFromFile.ExportDataForTP(TemplateWithData, InformationByColumns, ImportedDataAddress);
		CopyTabularSectionStructure(TabularSectionCopyAddress);
		
		ObjectManager = ObjectManager(CorrelationObjectName);
		
		Try
			ObjectManager.MatchImportedData(ImportedDataAddress, TabularSectionCopyAddress, AmbiguitiesList, CorrelationObjectName, AdditionalParameters);
		Except
			// an old variant of the MatchImportedData method is used without the AdditionalParameters parameter.
			ObjectManager.MatchImportedData(ImportedDataAddress, TabularSectionCopyAddress, AmbiguitiesList, CorrelationObjectName);
		EndTry;
		
		If Not AttributesCreated Then
			CreateMatchTableByInformationAboutColumnsForTP();
		EndIf;
		
		PlaceDataInMatchTable(ImportedDataAddress, TabularSectionCopyAddress, AmbiguitiesList);
		
	ElsIf ImportType = "InsertionFromClipboard" Then
		DataProcessors.DataLoadFromFile.FillDataMatchTableWithDataFromTemplate(TemplateWithData, MappingTable, InformationByColumns);
		DataProcessors.DataLoadFromFile.MatchAutoColumnValue(MappingTable, "Refs");
		ValueToFormAttribute(MappingTable, "DataMatchingTable");
	Else
		ServerCallParameters = New Structure();
		ServerCallParameters.Insert("TemplateWithData", TemplateWithData);
		ServerCallParameters.Insert("MappingTable", MappingTable);
		TableInformationByColumns = FormAttributeToValue("InformationByColumns");
		
		ServerCallParameters.Insert("InformationByColumns", TableInformationByColumns);
		
		BackgroundJobResult = LongActions.ExecuteInBackground(UUID, 
		"DataProcessors.DataLoadFromFile.FillMatchTableWithDataFromTemplateBackground",
		ServerCallParameters, 
		NStr("en='DataLoadFromFile: Execute server method of data processor FillMatchTableWithDataFromTemplate';ru='ЗагрузкаДанныхИзФайла: Выполнение серверного метода обработки ЗаполнитьТаблицуСопоставленияДаннымиИзШаблона';vi='DataLoadFromFile: Thực hiện phương thức xử lý trên Server FillMatchTableWithDataFromTemplate'"));
		
		If BackgroundJobResult.JobCompleted Then
			BackgroundJobStorageAddress = BackgroundJobResult.StorageAddress;
			ExecuteImportedDataMatchStepAfterMatchOnServer();
		Else 
			BackgroundJob = True;
			BackgroundJobID  = BackgroundJobResult.JobID;
			BackgroundJobStorageAddress = BackgroundJobResult.StorageAddress;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ExecuteImportedDataMatchStepAfterMatchOnServer()
	
	MappingTable = GetFromTempStorage(BackgroundJobStorageAddress);
	
	If ImportType = "AppliedImport" Then
		MatchDataAppliedImport(MappingTable);
		Items.ExplanationForAppliedImport.Title = StringFunctionsClientServer.SubstituteParametersInString(
		Items.ExplanationForAppliedImport.Title, CatalogPresentation(CorrelationObjectName));
	ElsIf ImportType = "OuterImport" Then
		MatchDataExternalProcessing(MappingTable);
	EndIf;
	
	Items.ExplanationForAppliedImport.Title = StringFunctionsClientServer.SubstituteParametersInString(
	Items.ExplanationForAppliedImport.Title, CatalogPresentation(CorrelationObjectName));
	
	ValueToFormAttribute(MappingTable, "DataMatchingTable");
	
EndProcedure

&AtClient
Procedure ExecuteImportedDataMatchStep()
	
	If TableWithDataEmpty() Then
		ShowMessageBox(, (NStr("en='To go to the stage of data mapping and import, fill in the table.';ru='Для перехода к этапу сопоставления и загрузки данных, необходимо заполнить таблицу.';vi='Để chuyển đến bước so sánh và kết nhập dữ liệu, cần điền bảng.'")));	
		Return;
	EndIf;
	
	ClosingFormConfirmation = False;
	UnfilledColumnsList = UnfilledMandatoryColumns();
	If UnfilledColumnsList.Count() > 0 Then 
		If UnfilledColumnsList.Count() =1  Then 
			TextAboutColumns = NStr("en='Mandatory column ""';ru='Обязательная колонка""';vi='Nút bắt buộc ""'") + " " + UnfilledColumnsList[0] +
				NStr("en='"" contains empty strings, these strings will be ignored during import';ru='"" содержит незаполненные строки, эти строки будут пропущены при загрузке';vi='"" có chứa các dòng chưa điền, các dòng này sẽ được bỏ qua khi kết nhập'");
		Else
			TextAboutColumns = NStr("en='Mandatory columns ""';ru='Обязательные колонки""';vi='Nút bắt buộc ""'") + " " + StringFunctionsClientServer.RowFromArraySubrows(UnfilledColumnsList,", ") +
				NStr("en='"" contain empty strings, these strings will be ignored during import';ru='"" содержат незаполненные строки, эти строки будут пропущены при загрузке';vi='"" có chứa các dòng chưa điền, các dòng này sẽ được bỏ qua khi kết nhập'");
		EndIf;
		TextAboutColumns = TextAboutColumns + Chars.LF + NStr("en='Continue?';ru='Продолжить?';vi='Tiếp tục?'");
		
		Notification = New NotifyDescription("AfterQuestionAboutBlankRows", ThisObject);
		ShowQueryBox(Notification, TextAboutColumns, QuestionDialogMode.YesNo,, DialogReturnCode.No);
	Else
		ExecuteImportedDataMatchStepAfterCheck();
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterQuestionAboutBlankRows(Result, Parameter) Export
	If Result = DialogReturnCode.Yes Then 
		ExecuteImportedDataMatchStepAfterCheck();
	EndIf;
EndProcedure

&AtClient
Procedure ExecuteImportedDataMatchStepAfterCheck()
	
	Items.Back.Enabled = False;
	Items.Next.Enabled = False;
	
	BackgroundJob = False;
	ExecuteImportedDataMatchStepOnServer(BackgroundJob);
	
	If BackgroundJob = True Then 
		Items.AssistantPages.CurrentPage = Items.LongActions;
		LongActionsClient.InitIdleHandlerParameters(HandlerParameters);
		AttachIdleHandler("BackgroundJobMatchOnClient", 1, True);
		HandlerParameters.MaxInterval = 5;
	Else 
		If AllDataMapped() AND ImportType = "InsertionFromClipboard" Then
			CloseFormAndReturnRefsArray();
		Else
			ExecuteImportedDataMatchStepClient();
		EndIf;
	EndIf;

EndProcedure

#Region LongOperation

&AtClient
Procedure BackgroundJobImportFileOnClient()
	Result = BackgroundJobImportFileGetResult();
	If Result.BackGroundJobFinished Then
		If LongOperationForm.IsOpen() 
			AND LongOperationForm.JobID = BackgroundJobID Then
				LongActionsClient.CloseLongOperationForm(LongOperationForm);
		EndIf;
		TemplateWithData = GetFromTempStorage(BackgroundJobStorageAddress);
		Items.TemplateWithData.Visible = True;
	Else
		LongActionsClient.UpdateIdleHandlerParameters(HandlerParameters);
		AttachIdleHandler("BackgroundJobImportFileOnClient", HandlerParameters.CurrentInterval, True);
		
	EndIf;
EndProcedure

&AtClient
Procedure BackgroundJobMatchOnClient()
	Result = BackgroundJobMatchGetResult();
	If Result.BackGroundJobFinished Then
		If AllDataMapped() AND ImportType = "InsertionFromClipboard" Then
			CloseFormAndReturnRefsArray();
		Else
			ExecuteImportedDataMatchStepClient();
		EndIf;
	Else
		LongActionsClient.UpdateIdleHandlerParameters(HandlerParameters);
		AttachIdleHandler("BackgroundJobMatchOnClient", HandlerParameters.CurrentInterval, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteImportedDataClient()
	
	Items.Back.Enabled = False;
	Items.Next.Enabled = False;
	
	BackgroundOrderPercent = 0;
	BackgroundJob = False;
	WriteImportedDataReport(BackgroundJob);
	
	If BackgroundJob = True Then 
		Items.AssistantPages.CurrentPage = Items.LongActions;
		LongActionsClient.InitIdleHandlerParameters(HandlerParameters);
		AttachIdleHandler("BackgroundJobRecordOnClient", 1, True);
		HandlerParameters.MaxInterval = 5;
	Else 
		BackgroundJobReportOnClient(False);
	EndIf;
EndProcedure

&AtClient
Procedure BackgroundJobRecordOnClient()
	Result = BackgroundJobRecordGetResult();
	If Result.BackGroundJobFinished Then
		FillMatchTableFromTemporaryStorage();
		BackgroundJobReportOnClient(False);
	Else
		LongActionsClient.UpdateIdleHandlerParameters(HandlerParameters);
		AttachIdleHandler("BackgroundJobRecordOnClient", HandlerParameters.CurrentInterval, True);
	EndIf;
EndProcedure

&AtServer
Function BackgroundJobRecordGetResult()
	Result = New Structure;
	Result.Insert("BackGroundJobFinished", False);
	Result.BackGroundJobFinished = LongActions.JobCompleted(BackgroundJobID);
	If Not Result.BackGroundJobFinished Then
		BackgroundJobReadInterimResult(Result);
	EndIf;
	Return Result;
EndFunction

&AtClient
Procedure BackgroundJobReportOnClient(ShowWaitingWindow = True)
	
	BackgroundJob = False;
	FormReportAboutImport(FilterReport, BackgroundJob, Not ShowWaitingWindow);
	
	If BackgroundJob Then
		If ShowWaitingWindow Then 
			LongOperationForm = LongActionsClient.OpenLongOperationForm(ThisObject, BackgroundJobID);
		EndIf;
		LongActionsClient.UpdateIdleHandlerParameters(HandlerParameters);
		AttachIdleHandler("BackgroundJobCreateReportOnClient", HandlerParameters.CurrentInterval, True);
	Else
		Result = GetFromTempStorage(BackgroundJobStorageAddress);
		ShowReport(Result);
	EndIf;
EndProcedure

&AtClient
Procedure ShowReport(Report)
	
	If Items.AssistantPages.CurrentPage <> Items.ReportOnDataImport Then
		ExecuteStepDataImportReportClient();
	EndIf;
	
	TotalReportCreated = Report.Created;
	TotalReportUpdated = Report.Updated;
	TotalReportSkipped = Report.Skipped;
	TotalReportIncorrect = Report.Incorrect;
	
	Items.FilterReport.ChoiceList.Clear();
	Items.FilterReport.ChoiceList.Add("AllItems", NStr("en='All (';ru='Все (';vi='Tất cả ('") + Report.Total + ")");
	Items.FilterReport.ChoiceList.Add("New", NStr("en='New (';ru='Новые (';vi='Mới ('") + Report.Created+ ")");
	Items.FilterReport.ChoiceList.Add("Updated", NStr("en='Updated (';ru='Обновленные (';vi='Cập nhật ('") + Report.Updated+ ")");
	Items.FilterReport.ChoiceList.Add("Skipped", NStr("en='Missed (';ru='Пропущенные (';vi='Bỏ qua ('") + Report.Skipped+ ")");
	FilterReport = Report.ReportType;

	TableReport = Report.TableReport;
	
EndProcedure

&AtClient
Procedure BackgroundJobCreateReportOnClient()

	ExecutionResult = BackgroundJobReportGetResult();
	If ExecutionResult.BackGroundJobFinished Then
		If LongOperationForm <> Undefined
			AND LongOperationForm.IsOpen()
			AND LongOperationForm.JobID = BackgroundJobID Then
			LongActionsClient.CloseLongOperationForm(LongOperationForm);
		EndIf;
		
		Result = GetFromTempStorage(BackgroundJobStorageAddress);
		ShowReport(Result);
		ClosingFormConfirmation = True;
	Else
		LongActionsClient.UpdateIdleHandlerParameters(HandlerParameters);
		AttachIdleHandler("BackgroundJobCreateReportOnClient", HandlerParameters.CurrentInterval, True);
	EndIf;

EndProcedure

&AtServer
Function BackgroundJobImportFileGetResult()
	Result = New Structure;
	Result.Insert("BackGroundJobFinished", False);
	Result.BackGroundJobFinished = LongActions.JobCompleted(BackgroundJobID);
	Return Result;
EndFunction

&AtServer
Function BackgroundJobMatchGetResult()
	Result = New Structure;
	Result.Insert("BackGroundJobFinished", False);
	Result.BackGroundJobFinished = LongActions.JobCompleted(BackgroundJobID);
	If Result.BackGroundJobFinished Then
		ExecuteImportedDataMatchStepAfterMatchOnServer();
	Else
		BackgroundJobReadInterimResult(Result);
	EndIf;
	Return Result;
EndFunction

&AtServer
Function BackgroundJobReportGetResult()
	Result = New Structure;
	Result.Insert("BackGroundJobFinished", False);
	Result.BackGroundJobFinished = LongActions.JobCompleted(BackgroundJobID);
	If Not Result.BackGroundJobFinished Then
		BackgroundJobReadInterimResult(Result);
	EndIf;
	Return Result;
EndFunction

&AtServer
Procedure BackgroundJobReadInterimResult(Result)
	Progress = LongActions.ReadProgress(BackgroundJobID);
	If Progress <> Undefined Then
		BackgroundOrderPercent = Progress.Percent;
	EndIf;
EndProcedure

#EndRegion

&AtClient
Procedure ExecuteImportedDataMatchStepClient()
	
	If ImportType = "InsertionFromClipboard" Then
		Statistics = MatchStatistics();
		
		If Statistics.Matched > 0 Then
			TextFound = NStr("en='%2 out of %1 entered lines will be added to the list.';ru='Из %1 введенных строк в список будут вставлены: %2.';vi='Trong số %1 các dòng đã nhập trong danh sách, sẽ chèn %2.'");
			Items.LabelResultComparison.Title = StringFunctionsClientServer.SubstituteParametersInString(TextFound,
				Statistics.TotalAmount, Statistics.Matched);
			
			If Statistics.Ambiguous > 0 AND Statistics.NotFound > 0 Then 
				TextNotFound = NStr("en='11 lines will be ignored:';ru='11 строк будут пропущены:';vi='11 dòng sẽ bị bỏ qua:'") + Chars.LF + "  - " + NStr("en='No data in application: %1';ru='Нет данных в программе: %1';vi='Không có dữ liệu trong chương trình: %1'") 
					+ Chars.LF + "  - " +NStr("en='Several variants to insert: %2';ru='Несколько вариантов для вставки: %2';vi='Nhiều phương án chèn: %2'");
				TextNotFound = StringFunctionsClientServer.SubstituteParametersInString(TextNotFound, Statistics.NotFound, Statistics.Ambiguous);
			ElsIf Statistics.Ambiguous > 0 Then
				TextNotFound = NStr("en='Strings for which there are multiple variants in the application will be skipped: %1';ru='Строки, для которых в программе имеется несколько вариантов, будут пропущены: %1';vi='Dòng mà trong chương trình có nhiều phương án sẽ bị bỏ qua: %1'");
				TextNotFound = StringFunctionsClientServer.SubstituteParametersInString(TextNotFound, Statistics.Ambiguous);
			ElsIf Statistics.NotFound > 0 Then
				TextNotFound = NStr("en='Strings for which there are no matching data in the application will be skipped: %1';ru='Строки, для которых в программе нет соответствующих данных, будут пропущены: %1';vi='Dòng mà trong chương trình không có dữ liệu tương ứng sẽ bị bỏ qua: %1'");
				TextNotFound = StringFunctionsClientServer.SubstituteParametersInString(TextNotFound, Statistics.NotFound);
			EndIf;
			TextNotFound = TextNotFound + Chars.LF + NStr("en='To view skipped lines and data selection for insertion, click Next.';ru='Для просмотра пропущенных строк и подбора данных для вставки нажмите ""Далее"".';vi='Để xem các dòng đã bỏ qua và chọn dữ liệu để chèn, hãy nhấn nút ""Tiếp theo"".'");
			Items.DecorationNotFoundAndAmbiguity.Title = TextNotFound;
			
			Items.AssistantPages.CurrentPage = Items.ComparisonResults;
			Items.Back.Visible = True;
			CommonUseClientServer.SetFormItemProperty(Items, "AnotherWayToImportData", "Visible", False); // SB
			Items.InsertIntoList.Visible = True;
			Items.Next.Visible = True;
			Items.Back.Title = NStr("en='< Back';ru='< Back';vi='< Quay lại'");
			Items.Next.Title = NStr("en='Next >';ru='Далее  >';vi='Tiếp theo >'");
			Items.Next.DefaultControl = False;
			Items.InsertIntoList.DefaultControl = True;
			Items.InsertIntoList.DefaultButton = True;
			
			ShowStatisticsByMatchLoadFromFile();
			SetDesignForMatchingPage(False, Items.ExplanationForRefSearch, False, NStr("en='Next >';ru='Далее  >';vi='Tiếp theo >'"));
		Else
			Items.AssistantPages.CurrentPage = Items.NotFound;
			Items.Close.Title = NStr("en='Close';ru='Закрыть';vi='Đóng'");
			Items.Back.Visible = True;
			CommonUseClientServer.SetFormItemProperty(Items, "AnotherWayToImportData", "Visible", False); // SB
			Items.InsertIntoList.Visible = False;
			Items.Next.Visible = False;
		EndIf;
		
	Else 
		Items.AssistantPages.CurrentPage = Items.ExportedDataComparison;
		ShowStatisticsByMatchLoadFromFile();
		
		If ImportType = "UniversalImport" Then
			SetDesignForMatchingPage(True, Items.ExplanationForUniversalImport, True, NStr("en='Import data >';ru='Загрузить данные >';vi='Kết nhập dữ liệu >'"));
		ElsIf ImportType = "TabularSection" Then
			Filter = New Structure("RowMatchResult", "NotMatched");
			If DataMatchingTable.FindRows(Filter).Count() = 0 Then
				// All rows have been matched
				TransferToImportDataNextStep();
			EndIf;
			
			SetDesignForMatchingPage(False, Items.ExplanationForTabularSection, True, NStr("en='Import data';ru='Загрузить данные';vi='Kết nhập dữ liệu'"));
		ElsIf ImportType = "OuterImport" Then
			SetDesignForMatchingPage(False, Items.ExplanationForAppliedImport, False, NStr("en='Import data >';ru='Загрузить данные >';vi='Kết nhập dữ liệu >'"));
		Else
			SetDesignForMatchingPage(False, Items.ExplanationForAppliedImport, False, NStr("en='Import data >';ru='Загрузить данные >';vi='Kết nhập dữ liệu >'"));
		EndIf;
	EndIf;
	
	Items.Back.Enabled = True;
	Items.Next.Enabled = True;

EndProcedure

&AtClient
Procedure SetDesignForMatchingPage(ButtonVisibleMatch, ItemForExplanationText, ButtonVisibleAllowAmbiguity, TextButtonsNext)
	
	Items.MatchingColumnsList.Visible = ButtonVisibleMatch;
	Items.Back.Visible = True;
	CommonUseClientServer.SetFormItemProperty(Items, "AnotherWayToImportData", "Visible", False); // SB
	Items.ExplanationForUniversalImport.Visible = False;
	Items.ExplanationForAppliedImport.Visible = False;
	Items.ExplanationForTabularSection.Visible = False;
	Items.ExplanationForRefSearch.Visible = False;
	If ItemForExplanationText = Items.ExplanationForUniversalImport Then
		Items.ExplanationForUniversalImport.Visible = True;
	ElsIf ItemForExplanationText = Items.ExplanationForTabularSection Then
		Items.ExplanationForTabularSection.Visible = True;
	ElsIf ItemForExplanationText = Items.ExplanationForRefSearch Then
		Items.ExplanationForRefSearch.Visible = True;
		Items.ExplanationForDataMatching.ShowTitle = False;
	Else
		Items.ExplanationForAppliedImport.Visible = True;
	EndIf;
	
	Items.EnableAmbiguity.Visible = ButtonVisibleAllowAmbiguity;
	Items.Next.Title = TextButtonsNext;
	
EndProcedure

&AtClient
Procedure OpenAmbiguityPermissionForm(SelectedRow, FieldName, StandardProcessing)
	String = DataMatchingTable.FindByID(SelectedRow);
	
	If ImportType = "TabularSection" Then
		If String.RowMatchResult = "NotMatched" AND StrLen(String.ErrorDescription) > 0 Then
			If StrLen(FieldName) > 3 AND Left(FieldName,3) = "CWT_" Then
				Name = Mid(FieldName, 4);
				If Find(String.ErrorDescription, Name) Then
					StandardProcessing = False;
					StringFromTable = New Array;
					ImportedColumnValues = New Structure();
					For Each Column IN InformationByColumns Do
						ColumnArray = New Array();
						ColumnArray.Add(Column.ColumnName);
						ColumnArray.Add(Column.ColumnPresentation);
						ColumnArray.Add(String["Individual_" + Column.ColumnName]);
						ColumnArray.Add(Column.ColumnType);
						StringFromTable.Add(ColumnArray);
						If Name = Column.Association Then
							ImportedColumnValues.Insert(Column.ColumnName, String["Individual_" + Column.ColumnName]);
						EndIf;
					EndDo;
					
					FormParameters = New Structure();
					FormParameters.Insert("ImportType", ImportType);
					FormParameters.Insert("Name", Name);
					FormParameters.Insert("StringFromTable", StringFromTable);
					FormParameters.Insert("ImportedColumnValues", ImportedColumnValues);
					FormParameters.Insert("AmbiguitiesList", Undefined);
					FormParameters.Insert("TabularSectionFullName", CorrelationObjectName);
					FormParameters.Insert("AdditionalParameters", AdditionalParameters);
					
					Parameter = New Structure();
					Parameter.Insert("ID", SelectedRow);
					Parameter.Insert("Name", Name);
					
					Notification = New NotifyDescription("AfterAmbiguitiesMatch", ThisObject, Parameter);
					OpenForm("DataProcessor.DataLoadFromFile.Form.Disambiguation", FormParameters, ThisObject, True , , , Notification, FormWindowOpeningMode.LockOwnerWindow);
				EndIf;
			EndIf;
		EndIf;
	Else
		If String.RowMatchResult = "Ambiguity" Then
			StandardProcessing = False;
			
			StringFromTable = New Array;
			For Each Column IN InformationByColumns Do 
				ColumnArray = New Array();
				ColumnArray.Add(Column.ColumnName);
				ColumnArray.Add(Column.ColumnPresentation);
				ColumnArray.Add(String[Column.ColumnName]);
				ColumnArray.Add(Column.ColumnType);
				StringFromTable.Add(ColumnArray);
			EndDo;
			
			CorrelationColumns = New ValueList;
			For Each Item IN MatchByColumn Do 
				If Item.Check Then
					CorrelationColumns.Add(Item.Value);
				EndIf;
			EndDo;
			
			FormParameters = New Structure();
			FormParameters.Insert("StringFromTable", StringFromTable);
			FormParameters.Insert("AmbiguitiesList", String.AmbiguitiesList);
			FormParameters.Insert("CorrelationColumns", CorrelationColumns);
			FormParameters.Insert("ImportType", ImportType);
			
			Parameter = New Structure("ID", SelectedRow);
			
			Notification = New NotifyDescription("AfterAmbiguitiesMatch", ThisObject, Parameter);
			OpenForm("DataProcessor.DataLoadFromFile.Form.Disambiguation", FormParameters, ThisObject, True , , , Notification, FormWindowOpeningMode.LockOwnerWindow);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure MatchDataAppliedImport(DataMatchTableServer)
	
	ManagerObject = ObjectManager(CorrelationObjectName);
	
	ManagerObject.MapImportedDataFromFile(DataMatchTableServer);
	For Each String IN DataMatchTableServer Do 
		If ValueIsFilled(String.MappingObject) Then 
			String.RowMatchResult = "RowMatched";
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region StepReportAboutImport

&AtServer
Procedure WriteImportedDataReport(BackgroundJob = False)
	
	MatchedData = FormAttributeToValue("DataMatchingTable");
	
	If ImportType = "UniversalImport" Then
		
		ExportParameters = New Structure();
		ExportParameters.Insert("CreateIfNotMatched", CreateIfNotMatched);
		ExportParameters.Insert("UpdateExisting", UpdateExisting);

		ServerCallParameters = New Structure();
		ServerCallParameters.Insert("MatchedData", MatchedData);
		ServerCallParameters.Insert("ExportParameters", ExportParameters);
		ServerCallParameters.Insert("CorrelationObjectName", CorrelationObjectName);
		TableInformationByColumns = FormAttributeToValue("InformationByColumns");
		ServerCallParameters.Insert("InformationByColumns", TableInformationByColumns);
		
		BackgroundJobResult = LongActions.ExecuteInBackground(UUID, 
				"DataProcessors.DataLoadFromFile.WriteMatchedData",
				ServerCallParameters, 
				NStr("en='The ImportDataFromFile subsystem: Save imported data';ru='Подсистема ЗагрузкаДанныхИзФайла: Запись загружаемых данных';vi='Phân hệ ImportDataFromFile. Bản ghi dữ liệu đã kết nhập'"));
		
		If BackgroundJobResult.JobCompleted Then
			BackgroundJobStorageAddress = BackgroundJobResult.StorageAddress;
			MatchedData = GetFromTempStorage(BackgroundJobStorageAddress);
		Else 
			BackgroundJob = True;
			BackgroundJobID  = BackgroundJobResult.JobID;
			BackgroundJobStorageAddress = BackgroundJobResult.StorageAddress;
		EndIf;
	ElsIf ImportType = "OuterImport" Then
		WriteMatchedDataExternalDataProcessor(MatchedData);
	Else
		WriteMatchedDataAppliedImport(MatchedData);
	EndIf;
	
	If Not BackgroundJob Then
		ValueToFormAttribute(MatchedData, "DataMatchingTable");
	EndIf;
	
	Items.OpenCatalogAfterAssistantClosing.Title = StringFunctionsClientServer.SubstituteParametersInString(Items.OpenCatalogAfterAssistantClosing.Title, CatalogPresentation(CorrelationObjectName));
	Items.ImportReportExplanation.Title = StringFunctionsClientServer.SubstituteParametersInString(Items.ImportReportExplanation.Title, CatalogPresentation(CorrelationObjectName));
	
	ReportType = "AllItems";
	
EndProcedure


&AtClient
Procedure ExecuteStepDataImportReportClient()
	
	Items.AssistantPages.CurrentPage = Items.ReportOnDataImport;
	//Items.OpenCatalogAfterClosingAssistant.Visible = True; SB//
	Items.Close.Title = "Done";
	Items.Next.Visible = False;
	Items.Back.Visible = False;
	
EndProcedure
#EndRegion

/////////////////////////////////////// SERVER //////////////////////////////////////

&AtServer
Procedure ClearTable()
	
	DataMatchTableServer = FormAttributeToValue("DataMatchingTable");
	DataMatchTableServer.Columns.Clear();
	InformationByColumns.Clear();
	
	While Items.DataMatchingTable.ChildItems.Count() > 0 Do
		ThisObject.Items.Delete(Items.DataMatchingTable.ChildItems.Get(0));
	EndDo;
	TemplateWithData = New SpreadsheetDocument;
	
	AttributesMatchTables = ThisObject.GetAttributes("DataMatchingTable");
	AttributePathsArray = New Array;
	For Each TableAttribute IN AttributesMatchTables Do
		AttributePathsArray.Add("DataMatchingTable." + TableAttribute.Name);
	EndDo;
	If AttributePathsArray.Count() > 0 Then
		ChangeAttributes(,AttributePathsArray);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetDataDesign()
	
	If ImportType = "InsertionFromClipboard" Then 
		TextObjectNotFound = NStr("en='<Not specified>';ru='<Не найден>';vi='<Không tìm thấy>'");
		ColorObjectNotFound = StyleColors.UnavailableCellTextColor;
		ColorAmbiguity = StyleColors.ExplanationTextError;
	Else
		TextObjectNotFound = NStr("en='<ew>';ru='<ew>';vi='<ew>'");
		ColorObjectNotFound = StyleColors.ResultSuccessColor;
		ColorAmbiguity = StyleColors.ExplanationTextError;
	EndIf;
	
	ConditionalAppearance.Items.Clear();
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	AppearanceField = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("MappingObject");
	AppearanceField.Use = True;
	
	FilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue = New DataCompositionField("DataMatchTable.MappingObject"); 
	FilterItem.ComparisonType = DataCompositionComparisonType.NotFilled; 
	FilterItem.Use = True;
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", ColorObjectNotFound);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", TextObjectNotFound);
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	AppearanceField = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("MappingObject");
	AppearanceField.Use = True;
	FilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue = New DataCompositionField("DataMatchTable.RowMatchResult"); 
	FilterItem.ComparisonType = DataCompositionComparisonType.Equal; 
	FilterItem.RightValue = "Ambiguity"; 
	FilterItem.Use = True;
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", ColorAmbiguity);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("en='<ambiguity>';ru='<неоднозначность>';vi='<không đồng nhất>'"));
	
EndProcedure

&AtServer
Function InformationAboutColumn(ColumnName)
	Filter = New Structure("ColumnName", ColumnName);
	Result = InformationByColumns.FindRows(Filter);
	If Result.Count() > 0 Then
		Return Result[0];
	EndIf;
	
	Return Undefined;
EndFunction

&AtServer
Function InformationAboutMetadataObjectByType(ObjectFullType)
	ObjectDescription = New Structure("ObjectType, ObjectName");
	DescriptionFull = Metadata.FindByType(ObjectFullType).FullName();
	Result = StringFunctionsClientServer.DecomposeStringIntoSubstringsArray(DescriptionFull,".");
	If Result.Count()>1 Then
		ObjectDescription.ObjectType = Result[0];
		ObjectDescription.ObjectName = Result[1];
		
		Return ObjectDescription;
	Else
		Return Undefined;		
	EndIf;
	
EndFunction 

&AtServer
Function ConditionsBySelectedColumns()
	
	Delimiter = "";
	SeparatorAND = "";
	ComparisonType = " = ";
	withWhere = "";
	RowCondition = "";
	
	For Each Item IN MatchByColumn Do
		If Item.Check Then
			Column = InformationAboutColumn(Item.Value);
			// Create a query depending on types.
			If Column <> Undefined Then
				ColumnType = Column.ColumnType.Types()[0];
				If ColumnType = Type("String") Then
					If Column.ColumnType.StringQualifiers.Length = 0 Then
						RowCondition = RowCondition + SeparatorAND + "MatchCatalog." + Column.ColumnName +  " LIKE MatchTable." + Column.ColumnName;
						withWHERE = withWHERE + " And MatchCatalog." + Column.ColumnName + " <> """"";
					Else
						RowCondition = RowCondition + SeparatorAND + "MatchCatalog." + Column.ColumnName +  " = MatchTable." + Column.ColumnName;
						withWHERE = withWHERE + " And MatchCatalog." + Column.ColumnName + " <> """"";
					EndIf;
				ElsIf ColumnType = Type("Number") Then
					RowCondition = RowCondition + SeparatorAND + "MatchCatalog." + Column.ColumnName + " =  MatchTable." + Column.ColumnName;
				ElsIf ColumnType = Type("Date") Then 
					RowCondition = RowCondition + SeparatorAND + "MatchCatalog." + Column.ColumnName + " =  MatchTable." + Column.ColumnName;
				ElsIf ColumnType = Type("Boolean") Then 
					RowCondition = RowCondition + SeparatorAND + "MatchCatalog." + Column.ColumnName + " =  MatchTable." + Column.ColumnName;
				Else
					InfoObject = InformationAboutMetadataObjectByType(ColumnType);
					If InfoObject.ObjectType = "Catalog" Then
						Catalog = Metadata.Catalogs.Find(InfoObject.ObjectName);
						ConditionTextCatalog = "";
						SeparatorOR = "";
						For Each InputRow IN Catalog.InputByString Do 
							If InputRow.Name = "Code" AND Not Catalog.AutoNumber Then 
								InputConditionTextOnLine = "MatchCatalog." + Column.ColumnName+ ".Code " + ComparisonType + " MatchingTable." + Column.ColumnName;	
							Else
								InputConditionTextOnLine = "MatchCatalog." + Column.ColumnName+ "." + InputRow.Name  + ComparisonType + " MatchingTable." + Column.ColumnName;
							EndIf;	
							ConditionTextCatalog = ConditionTextCatalog + SeparatorOR + InputConditionTextOnLine;
							SeparatorOR = " OR ";
						EndDo;
						RowCondition = RowCondition + SeparatorAND + " ( "+ ConditionTextCatalog + " )";
					ElsIf InfoObject.ObjectType = "Enum" Then 
						RowCondition = RowCondition + SeparatorAND + "MatchCatalog." + Column.ColumnName + " =  MatchTable." + Column.ColumnName;	
					EndIf;
				EndIf;
				
			EndIf;
			
			SeparatorAND = " AND ";
			Delimiter = ",";
			
		EndIf;
	EndDo;
	
	Conditions = New Structure("AssociationCondition, Where");
	Conditions.AssociationCondition  = RowCondition;
	Conditions.Where = withWHERE;
	Return Conditions;
EndFunction

&AtServer
Procedure ExecuteMatchBySelectedAttribute(MatchedQuantity = 0, MapingColumnsList = "")
	
	Conditions = ConditionsBySelectedColumns();
	
	If Not ValueIsFilled(Conditions.AssociationCondition ) Then
		Return;
	EndIf;
	
	StructureObject = DataProcessors.DataLoadFromFile.DecomposeFullObjectName(CorrelationObjectName);
	CatalogName = StructureObject.NameObject;
	MappingTable = FormAttributeToValue("DataMatchingTable");
	
	ListColumns = "";
	Delimiter = "";
	For Each Column IN MappingTable.Columns Do
		If Column.Name <> "AmbiguitiesList" AND Column.Name <> "RowMatchResult" AND Column.Name <> "ErrorDescription" Then
			ListColumns = ListColumns + Delimiter + Column.Name;
			Delimiter = ", ";
		EndIf;
	EndDo;
	
	Query = New Query;
	Query.Text = "SELECT " + ListColumns + "
	|INTO MappingTable
	|FROM &MappingTable AS MappingTable
	|;
	|SELECT
	|	MatchCatalog.Ref, MappingTable.ID
	|FROM
	|	Catalog." + CatalogName + " AS MatchCatalog RIGHT JOIN MatchTable AS MatchTable ON " + Conditions.AssociationCondition + "
	|WHERE
	|	       MatchCatalog.RemovalMark = FALSE " + Conditions.Where + "
	|	ORDER BY MatchTable.Identifier TOTAL BY MatchTable.Identifier";
	
	Query.SetParameter("MappingTable", MappingTable);
	
	QueryResult = Query.Execute();
	SelectionDetailRecords = QueryResult.Select(QueryResultIteration.ByGroups);
	
	EmptyValue = ObjectManager(CorrelationObjectName).EmptyRef();
	
	While SelectionDetailRecords.Next() Do
		String = MappingTable.Find(SelectionDetailRecords.ID, "ID");
		
		If ValueIsFilled(String.MappingObject) Then
			Continue;
		EndIf;
		
		SelectionDetailedRecordsGroup = SelectionDetailRecords.Select();
		
		If SelectionDetailedRecordsGroup.Count() > 1 Then
			AmbiguitiesList = New ValueList;
			While SelectionDetailedRecordsGroup.Next() Do
				AmbiguitiesList.Add(SelectionDetailedRecordsGroup.Ref);
			EndDo;
			String.RowMatchResult = "Ambiguity";
			String.ErrorDescription = MatchingColumnsList;
			String.AmbiguitiesList = AmbiguitiesList;
		Else
			SelectionDetailedRecordsGroup.Next();
			MatchedQuantity = MatchedQuantity + 1;
			String.RowMatchResult = "RowMatched";
			String.ErrorDescription = "";
			String.MappingObject = SelectionDetailedRecordsGroup.Ref;
		EndIf;
	EndDo;
	
	ValueToFormAttribute(MappingTable, "DataMatchingTable");
	
EndProcedure

&AtServer
Procedure PlaceDataInMatchTable(ImportedDataAddress, TabularSectionCopyAddress, AmbiguitiesList)
	
	TabularSection =  GetFromTempStorage(TabularSectionCopyAddress);
	
	If TabularSection = Undefined OR TypeOf(TabularSection) <> Type("ValueTable") OR TabularSection.Count() = 0 Then
		Return;
	EndIf;
	
	Filter = New Structure("ObligatoryToComplete", True);
	SelectedColumnsMandatoryToCompleteTable= InformationByColumns.FindRows(Filter);
	ColumnsRequiredForFilling = New Map;
	For Each TableColumn IN SelectedColumnsMandatoryToCompleteTable  Do
		ColumnsRequiredForFilling.Insert(TableColumn.Association, True);
	EndDo;
	
	DataMatchingTable.Clear();
	ExportableData = GetFromTempStorage(ImportedDataAddress);
	
	TabularSectionColumns = New Map();
	For Each Column IN TabularSection.Columns Do
		TabularSectionColumns.Insert(Column.Name, True);
	EndDo;
	
	For Each String IN TabularSection Do
		NewRow = DataMatchingTable.Add();
		NewRow.ID = String.ID;
		FilledAllMandatoryColumns = True;
		For Each Column IN TabularSection.Columns Do
			If Column.Name <> "ID" Then
				NewRow["CWT_" + Column.Name] = String[Column.Name];
			EndIf;
			
			If ValueIsFilled(ColumnsRequiredForFilling.Get(Column.Name))
				AND FilledAllMandatoryColumns
				AND Not ValueIsFilled(String[Column.Name]) Then
					FilledAllMandatoryColumns = False;
			EndIf;
		EndDo;
		
		NewRow["RowMatchResult"] = ?(FilledAllMandatoryColumns, "RowMatched", "NotMatched");
		
		Filter = New Structure("ID", String.ID); 
		
		Ambiguity = AmbiguitiesList.FindRows(Filter);
		If Ambiguity.Count() > 0 Then 
			NewRow["RowMatchResult"] = "NotMatched";
			For Each Ambiguity IN Ambiguity Do
				NewRow["ErrorDescription"] = NewRow["ErrorDescription"] + Ambiguity.Column+ ";";
				ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
				AppearanceField = ConditionalAppearanceItem.Fields.Items.Add();
				AppearanceField.Field = New DataCompositionField("CWT_" + Ambiguity.Column);
				AppearanceField.Use = True;
				FilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
				FilterItem.LeftValue = New DataCompositionField("DataMatchTable.ErrorDescription"); 
				FilterItem.ComparisonType = DataCompositionComparisonType.Contains; 
				FilterItem.RightValue = Ambiguity.Column; 
				FilterItem.Use = True;
				ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.ExplanationTextError);
				ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("en='<ambiguity>';ru='<неоднозначность>';vi='<không đồng nhất>'"));
			EndDo;
		EndIf;
	EndDo;
	
	For Each String IN ExportableData Do 
		Filter = New Structure("ID", String.ID);
		Rows = DataMatchingTable.FindRows(Filter);
		If Rows.Count() > 0 Then 
			NewRow = Rows[0];
			For Each Column IN ExportableData.Columns Do
				If Column.Name <> "ID" AND Column.Name <> "RowMatchResult" AND Column.Name <> "ErrorDescription" 
					AND Column.Name <> "Count" AND Column.Name <> "Price" Then
					NewRow["Individual_" + Column.Name] = String[Column.Name];
					If TabularSectionColumns.Get(Column.Name) <> Undefined AND ValueIsFilled(String[Column.Name]) 
							AND Not ValueIsFilled(NewRow["CWT_" + Column.Name]) Then
						NewRow["RowMatchResult"] = "NotMatched";
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Function AddressInTableMatchStorage()
	Table = FormAttributeToValue("DataMatchingTable");
	
	TableForTP = New ValueTable;
	For Each Column IN Table.Columns Do
		If Left(Column.Name, 3) = "CWT_" Then
			TableForTP.Columns.Add(Mid(Column.name, 4), Column.ValueType, Column.Title, Column.Width);
		ElsIf  Column.Name = "RowMatchResult" OR Column.Name = "ErrorDescription" OR Column.Name = "ID" Then 
			TableForTP.Columns.Add(Column.name, Column.ValueType, Column.Title, Column.Width);
		EndIf;
	EndDo;
	
	For Each String IN Table Do
		NewRow = TableForTP.Add();
		For Each Column IN TableForTP.Columns Do
			If Column.Name = "ID" Then 
				NewRow[Column.Name] = String[Column.Name];
			ElsIf Column.Name <> "RowMatchResult" AND Column.Name <> "ErrorDescription" Then
				NewRow[Column.Name] = String["CWT_"+ Column.Name];
			EndIf;
		EndDo;
	EndDo;
	
	Return PutToTempStorage(TableForTP);
EndFunction

&AtServerNoContext
Function CatalogPresentation(FullMetadataObjectName)
	Return Metadata.FindByFullName(FullMetadataObjectName).Presentation();
EndFunction

&AtServerNoContext
Function ObjectManager(CorrelationObjectName)
		ObjectArray = DataProcessors.DataLoadFromFile.DecomposeFullObjectName(CorrelationObjectName);
		If ObjectArray.ObjectType = "Document" Then
			ObjectManager = Documents[ObjectArray.NameObject];
		ElsIf ObjectArray.ObjectType = "Catalog" Then
			ObjectManager = Catalogs[ObjectArray.NameObject];
		Else
			Raise StringFunctionsClientServer.SubstituteParametersInString(NStr("en='Object ""%1"" is not found';ru='Объект ""%1"" не найден';vi='Không tìm thấy đối tượng ""%1""'"), CorrelationObjectName);
		EndIf;
		
		Return ObjectManager;
EndFunction

&AtServerNoContext
Function ListForm(CorrelationObjectName)
	MetadataObject = Metadata.FindByFullName(CorrelationObjectName);
	Return MetadataObject.DefaultListForm.FullName();
EndFunction

&AtServer
Function TypeByMetadataDescription(FullMetadataObjectName)
	Result = DataProcessors.DataLoadFromFile.DecomposeFullObjectName(FullMetadataObjectName);
	If Result.ObjectType = "Catalog" Then 
		Return New TypeDescription("CatalogRef." +  Result.NameObject);
	ElsIf Result.ObjectType = "Document" Then 
		Return New TypeDescription("DocumentRef." +  Result.NameObject);
	EndIf;
	
	Return Undefined;
EndFunction

&AtServer
Function UnfilledMandatoryColumns()
	ColumnsWithoutDataNames = New Array;
	
	Filter = New Structure("ObligatoryToComplete", True);
	MandatoryColumns = InformationByColumns.FindRows(Filter);
	
	Header = TableTemplateTitleArea(TemplateWithData);
	For ColumnNumber = 1 To Header.TableWidth Do 
		Cell = Header.GetArea(1, ColumnNumber, 1, ColumnNumber);
		ColumnName = TrimAll(Cell.CurrentArea.Text);
		
		InformationAboutColumn = Undefined;
		Filter = New Structure("ColumnPresentation", ColumnName);
		ColumnsFilter = InformationByColumns.FindRows(Filter);
		
		If ColumnsFilter.Count() > 0 Then
			InformationAboutColumn = ColumnsFilter[0];
		Else
			Filter = New Structure("ColumnName", ColumnName);
			ColumnsFilter = InformationByColumns.FindRows(Filter);	
			
			If ColumnsFilter.Count() > 0 Then
				InformationAboutColumn = ColumnsFilter[0];
			EndIf;
		EndIf;
		If InformationAboutColumn <> Undefined Then
			If InformationAboutColumn.ObligatoryToComplete Then 
				For LineNumber = 2 To TemplateWithData.TableHeight Do 
					Cell = TemplateWithData.GetArea(LineNumber, ColumnNumber, LineNumber, ColumnNumber);
					If Not ValueIsFilled(Cell.CurrentArea.Text) Then
						ColumnsWithoutDataNames.Add(InformationAboutColumn.ColumnPresentation);
						Break;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndDo;
	
	Return ColumnsWithoutDataNames;
EndFunction

#Region OuterImport

&AtServer
Procedure MatchDataExternalProcessing(DataMatchTableServer )
	If CommonUse.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
		ModuleAdditionalReportsAndDataProcessors = CommonUse.CommonModule("AdditionalReportsAndDataProcessors");
		ExternalObject = ModuleAdditionalReportsAndDataProcessors.GetObjectOfExternalDataProcessor(ExternalProcessingRef);
		ExternalObject.MapImportedDataFromFile(CommandID, DataMatchTableServer);
	EndIf;
EndProcedure

&AtServer
Procedure WriteMatchedDataExternalDataProcessor(MatchedData) 
	
	If CommonUse.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
		ModuleAdditionalReportsAndDataProcessors = CommonUse.CommonModule("AdditionalReportsAndDataProcessors");
		ExternalObject = ModuleAdditionalReportsAndDataProcessors.GetObjectOfExternalDataProcessor(ExternalProcessingRef);
	EndIf;
	
	Cancel = False;
	ExportParameters = New Structure();
	ExportParameters.Insert("CreateNew", CreateIfNotMatched);
	ExportParameters.Insert("UpdateExisting", UpdateExisting);
	ExternalObject.LoadFromFile(CommandID, MatchedData, ExportParameters, Cancel); 
	
EndProcedure

#EndRegion

#Region LoadFromFile

&AtServer
Procedure WriteMatchedDataAppliedImport(MatchedData)
	
	ObjectManager =  ObjectManager(CorrelationObjectName);
	
	Cancel = False;
	ExportParameters = New Structure();
	ExportParameters.Insert("CreateNew", CreateIfNotMatched);
	ExportParameters.Insert("UpdateExisting", UpdateExisting);
	ObjectManager.LoadFromFile(MatchedData, ExportParameters, Cancel)
	
EndProcedure

#EndRegion

#Region ImportToTabularSection

&AtServer
Procedure CopyTabularSectionStructure(TabularSectionAddress)
	
	TabularSection = Metadata.FindByFullName(CorrelationObjectName);
	
	DataForTabularSection = New ValueTable;
	DataForTabularSection.Columns.Add("ID", New TypeDescription("Number"), "ID");
	For Each TabularSectionAttribute IN TabularSection.Attributes Do
		DataForTabularSection.Columns.Add(TabularSectionAttribute.Name, TabularSectionAttribute.Type, TabularSectionAttribute.Presentation());	
	EndDo;
	
	TabularSectionAddress = PutToTempStorage(DataForTabularSection);
	
EndProcedure

#EndRegion

&AtServer
Procedure FormReportAboutImport(ReportType = "AllItems", BackgroundJob = False, CalculateProgressPercent = False)
	
	MatchedData        = FormAttributeToValue("DataMatchingTable");
	TableInformationByColumns = FormAttributeToValue("InformationByColumns");
	
	ServerCallParameters = New Structure();
	ServerCallParameters.Insert("TableReport", TableReport);
	ServerCallParameters.Insert("ReportType", ReportType);
	ServerCallParameters.Insert("MatchedData", MatchedData);
	ServerCallParameters.Insert("TemplateWithData", TemplateWithData);
	ServerCallParameters.Insert("CorrelationObjectName", CorrelationObjectName);
	ServerCallParameters.Insert("CalculateProgressPercent", CalculateProgressPercent);
	ServerCallParameters.Insert("InformationByColumns", TableInformationByColumns);
	
	BackgroundJobResult = LongActions.ExecuteInBackground(UUID, 
			"DataProcessors.DataLoadFromFile.FormReportAboutImportBackground",
			ServerCallParameters, 
			NStr("en='The DataLoadFromFile subsystem: Execute the processing server mode form import report';ru='Подсистема ЗагрузкаДанныхИзФайла: Выполнение серверного метода обработки сформировать отчет о загрузке';vi='Phân hệ DataLoadFromFile: Thực hiện phương pháp xử lý Client-Server lập báo cáo về kết nhập'"));
	
	If BackgroundJobResult.JobCompleted Then
		BackgroundJobStorageAddress = BackgroundJobResult.StorageAddress;
	Else
		BackgroundJob = True;
		BackgroundJobID  = BackgroundJobResult.JobID;
		BackgroundJobStorageAddress = BackgroundJobResult.StorageAddress;
	EndIf;
	
EndProcedure

&AtServer
Function TableTemplateTitleArea(Pattern)
	MetadataAreaTableTitle = Pattern.Areas.Find("Header");
	
	If MetadataAreaTableTitle = Undefined Then 
		AreaTitleTables = Pattern.GetArea("R1");
	Else 
		AreaTitleTables = Pattern.GetArea("Header"); 
	EndIf;
	
	Return AreaTitleTables;
	
EndFunction

&AtServer
Procedure ShowInformationRowAboutMandatoryColumns()
	
	If Items.DataFillingPages.CurrentPage = Items.PageVariantLoadFromFile Then
		ToolTipText = NStr("en='To import data, save the form to a file and  fill in the table using another application.';ru='Для загрузки данных необходимо заполнить таблицу сохранив бланк в файл для заполнения в другой программе.';vi='Để kết nhập dữ liệu, cần điền bảng, sau khi lưu biểu mẫu vào tệp để điền trong chương trình khác.'") + Chars.LF;
		ToolTipText = ToolTipText  + NStr("en='Then import the completed table in one of the following formats: Microsoft Excel Workbook (XLSX), Comma Separated Values (CSV), or spreadsheet document (MXL).';ru='Затем загрузить заполненную таблицу в одном из форматов: Книга Microsoft Excel (.xlsx), текст с разделителями (.csv) или табличный документ (.mxl).';vi='Sau đó kết nhập bảng đã điền với một trong các định dạng: Tờ Microsoft Excel (.xlsx), văn bản có đường chia tách (.csv) hoặc văn bản dạng bảng (.mxl).'") + Chars.LF;
	Else
		ToolTipText = NStr("en='To fill in the table, copy data to the table from external file via clipboard.';ru='Для заполнения таблицы необходимо скопировать данные в таблицу из внешнего файла через буфер обмена.';vi='Để điền bảng, cần sao chép dữ liệu vào bảng từ tệp ngoài thông qua bộ đệm trung gian.'") + Chars.LF;
	EndIf;
	
	Filter = New Structure("ObligatoryToComplete", True);
	MandatoryColumns= InformationByColumns.FindRows(Filter);
	
	If MandatoryColumns.Count() > 0 Then 
		ListColumns = "";
		
		For Each Column IN MandatoryColumns Do 
			If ValueIsFilled(Column.Synonym) Then
				ListColumns = ListColumns + ", """ + Column.Synonym + """";
			Else
				ListColumns = ListColumns + ", """ + Column.ColumnPresentation + """";
			EndIf;
		EndDo;
		ListColumns = Mid(ListColumns, 3);
		
		If MandatoryColumns.Count() = 1 Then
			ToolTipText = ToolTipText + NStr("en='Required column:';ru='Колонка обязательная для заполнения:';vi='Cột bắt buộc điền'") + " " + ListColumns;
		Else
			ToolTipText = ToolTipText + NStr("en='Required columns:';ru='Колонки обязательные для заполнения:';vi='Cột bắt buộc điền:'") + " " + ListColumns;
		EndIf;
		
	EndIf;
	
	Items.LabelToolTipForFilling.Title = ToolTipText;
	Items.ExplanationVariantLoadFromFile.Title = ToolTipText;
	
EndProcedure

&AtServer
Procedure DefineImportParameters(ImportParametersFromFile)
	
	ObjectMetadata = Metadata.FindByFullName(CorrelationObjectName);
	ImportParametersFromFile = DataProcessors.DataLoadFromFile.ImportParametersFromFile(ObjectMetadata);
	ObjectManager(CorrelationObjectName).DefineDataLoadFromFileParameters(ImportParametersFromFile);
	
EndProcedure

&AtServer
Procedure AddStandardColumnsInMatchTable(TemporaryVT, MappingObjectStructure, AddID,
		AddErrorDescriptionFull, AddRowMatchResult, AddAmbiguitiesList)
		
	If AddID Then 
		TemporaryVT.Columns.Add("ID", New TypeDescription("Number"), NStr("en='item';ru='п/п';vi='TT'"));
	EndIf;
	If ValueIsFilled(MappingObjectStructure) Then 
		If Not ValueIsFilled(MappingObjectStructure.Synonym) Then
			ColumnsTitle = "";
			If MappingObjectStructure.ObjectMatchTypeDescription.Types().Count() > 1 Then 
				ColumnsTitle = "Objects";
			Else
				ColumnsTitle = String(MappingObjectStructure.ObjectMatchTypeDescription.Types()[0]);
			EndIf;
			
		Else
			ColumnsTitle = MappingObjectStructure.Synonym;
		EndIf;
		TemporaryVT.Columns.Add("MappingObject", MappingObjectStructure.ObjectMatchTypeDescription, ColumnsTitle);
	EndIf;
	If AddRowMatchResult Then 
		TemporaryVT.Columns.Add("RowMatchResult", New TypeDescription("String"), NStr("en='Result';ru='Результат';vi='Kết quả'"));
	EndIf;
	If AddErrorDescriptionFull Then
		TemporaryVT.Columns.Add("ErrorDescription", New TypeDescription("String"), NStr("en='Reason';ru='Причина';vi='Lý do'"));
	EndIf;

	If AddAmbiguitiesList Then 
		TypeN = New TypeDescription("ValueList");
		TemporaryVT.Columns.Add("AmbiguitiesList", TypeN, "AmbiguitiesList");
	EndIf;
EndProcedure

&AtServer
Procedure AddStandardColumnsToAttributesArray(AttributeArray, MappingObjectStructure , AddID, 
		AddErrorDescriptionFull, AddRowMatchResult, AddAmbiguitiesList)
		
		StringType = New TypeDescription("String");
		If AddID Then 
			NumberType = New TypeDescription("Number");
			AttributeArray.Add(New FormAttribute("ID", NumberType, "DataMatchingTable", "ID"));
		EndIf;
		If ValueIsFilled(MappingObjectStructure) Then 
			AttributeArray.Add(New FormAttribute("MappingObject", MappingObjectStructure.ObjectMatchTypeDescription, "DataMatchingTable", CorrelationObjectName));
		EndIf;
		
		If AddRowMatchResult Then
			AttributeArray.Add(New FormAttribute("RowMatchResult", StringType, "DataMatchingTable", "Result"));
		EndIf;
		If AddErrorDescriptionFull Then 
			AttributeArray.Add(New FormAttribute("ErrorDescription", StringType, "DataMatchingTable", "Cause"));
		EndIf;

	If AddAmbiguitiesList Then 
		TypeN = New TypeDescription("ValueList");
		AttributeArray.Add(New FormAttribute("AmbiguitiesList", TypeN, "DataMatchingTable", "AmbiguitiesList"));
	EndIf;

EndProcedure

&AtServer
Procedure CreateMatchTableByInformationAboutColumnsAuto(ObjectTypeMatchDescription)
	
	AttributeArray = New Array;
	
	TemporaryVT = FormAttributeToValue("DataMatchingTable");
	TemporaryVT.Columns.Clear();
	
	MappingObjectStructure = New Structure("ObjectMatchTypeDescription, Synonym", ObjectTypeMatchDescription, "");
	AddStandardColumnsInMatchTable(TemporaryVT, MappingObjectStructure, True, False, True, True);
	AddStandardColumnsToAttributesArray(AttributeArray, MappingObjectStructure , True, False, True, True);
	
	For Each Column IN InformationByColumns Do
		TemporaryVT.Columns.Add(Column.ColumnName, Column.ColumnType, Column.ColumnPresentation);
		AttributeArray.Add(New FormAttribute(Column.ColumnName, Column.ColumnType, "DataMatchingTable", Column.ColumnPresentation));
	EndDo;
	
	ChangeAttributes(AttributeArray);
	
	ValueToFormAttribute(TemporaryVT, "DataMatchingTable");
	
	For Each Column IN TemporaryVT.Columns Do
		NewItem = Items.Add(Column.Name, Type("FormField"), Items.DataMatchingTable);
		NewItem.Type = FormFieldType.InputField;
		NewItem.DataPath = "DataMatchingTable." + Column.Name;
		NewItem.Title = Column.Title;
		NewItem.ReadOnly = True;
		If NewItem.Type <> FormFieldType.LabelField Then
			ObligatoryToComplete = ThisColumnIsMandatoryToFill(Column.Name);
			NewItem.AutoMarkIncomplete  = ObligatoryToComplete;
			NewItem.ChoiceHistoryOnInput = ChoiceHistoryOnInput.DontUse;
			
		EndIf;
		If Column.Name = "MappingObject" Then
			NewItem.FixingInTable = FixingInTable.Left;
			NewItem.BackColor = StyleColors.MasterFieldBackground;
			NewItem.HeaderPicture = PictureLib.Change;
			NewItem.ReadOnly = False;
			
			NewItem.EditMode = ColumnEditMode.Enter;
			NewItem.DropListButton = False;
			NewItem.CreateButton = False;
			NewItem.TextEdit = False;
			NewItem.ChoiceHistoryOnInput = ChoiceHistoryOnInput.DontUse;
			NewItem.IncompleteChoiceMode = IncompleteChoiceMode.OnActivate;
		ElsIf Column.Name = "ID" Then
			NewItem.FixingInTable = FixingInTable.Left;
			NewItem.ReadOnly = True;
			NewItem.Width = 4;
		ElsIf Column.Name = "RowMatchResult" OR Column.Name = "AmbiguitiesList" Then
			NewItem.Visible = False;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure CreateMatchTableByInformationAboutColumns()
	
	AttributeArray = New Array;
	
	MetadataObject = Metadata.FindByFullName(CorrelationObjectName);
	ObjectTypeMatchDescription = TypeByMetadataDescription(CorrelationObjectName);
	StringType = New TypeDescription("String");
	NumberType = New TypeDescription("Number");
	TypeN = New TypeDescription("ValueList");
	
	TemporaryVT = FormAttributeToValue("DataMatchingTable"); 
	TemporaryVT.Columns.Clear();
	
	Synonym = MetadataObject.Synonym;
	MappingObjectStructure = New Structure("ObjectMatchTypeDescription, Synonym", ObjectTypeMatchDescription, Synonym);
	AddStandardColumnsInMatchTable(TemporaryVT, MappingObjectStructure, True, True, True, True);
	AddStandardColumnsToAttributesArray(AttributeArray, MappingObjectStructure, True, True, True, True);
	
	For Each Column IN InformationByColumns Do 
		ColumnPresentation = ?(ValueIsFilled(Column.Synonym), Column.Synonym, Column.ColumnPresentation);
		TemporaryVT.Columns.Add(Column.ColumnName, Column.ColumnType,ColumnPresentation);
		AttributeArray.Add(New FormAttribute(Column.ColumnName, Column.ColumnType, "DataMatchingTable", ColumnPresentation));
	EndDo;
	
	ChangeAttributes(AttributeArray);
	
	For Each Column IN TemporaryVT.Columns Do
		NewItem = Items.Add(Column.Name, Type("FormField"), Items.DataMatchingTable);
		NewItem.Type = FormFieldType.InputField;
		NewItem.DataPath = "DataMatchingTable." + Column.Name;
		NewItem.Title = Column.Title;
		NewItem.ReadOnly = True;
		If NewItem.Type <> FormFieldType.LabelField Then 
			ObligatoryToComplete = ThisColumnIsMandatoryToFill(Column.Name);
			NewItem.AutoMarkIncomplete  = ObligatoryToComplete;
			NewItem.ChoiceHistoryOnInput = ChoiceHistoryOnInput.DontUse;
		EndIf;
		If Column.Name = "MappingObject" Then 
			NewItem.FixingInTable = FixingInTable.Left;
			NewItem.BackColor = StyleColors.MasterFieldBackground;
			NewItem.HeaderPicture = PictureLib.Change;
			NewItem.ReadOnly = False;
			NewItem.EditMode =  ColumnEditMode.Directly;
			NewItem.IncompleteChoiceMode = IncompleteChoiceMode.OnActivate;
		ElsIf Column.Name = "ID" Then
			NewItem.FixingInTable = FixingInTable.Left;
			NewItem.ReadOnly = True;
			NewItem.Width = 4;
		ElsIf Column.Name = "RowMatchResult" OR Column.Name = "ErrorDescription" OR Column.Name = "AmbiguitiesList" Then
			NewItem.Visible = False;
		EndIf;
		
		Filter = New Structure("ColumnName", Column.Name);
		Columns = InformationByColumns.FindRows(Filter);
		If Columns.Count() > 0 Then 
			NewItem.Visible = Columns[0].Visible;
		EndIf;
		
	EndDo;
	
	ValueToFormAttribute(TemporaryVT, "DataMatchingTable");
EndProcedure

&AtServer
Procedure CreateMatchTableByInformationAboutColumnsForTP() 
	
	AttributeArray = New Array;
	StringType = New TypeDescription("String");
	NumberType = New TypeDescription("Number");
	
	TemporaryVT = FormAttributeToValue("DataMatchingTable"); 
	TemporaryVT.Columns.Clear();
	
	AddStandardColumnsInMatchTable(TemporaryVT, Undefined, True, True, True, False);
	AddStandardColumnsToAttributesArray(AttributeArray, Undefined, True, True, True, False);

	MandatoryColumns = New Array;
	ColumnsContainingSelectionParametersLinks = New Map;
	TPAttributes = Metadata.FindByFullName(CorrelationObjectName).Attributes;
	For Each Column IN TPAttributes Do
		
		If Column.FillChecking = FillChecking.ShowError Then
			MandatoryColumns.Add("CWT_" + Column.Name);
		EndIf;
		If Column.ChoiceParameterLinks.Count() > 0 Then
			ColumnsContainingSelectionParametersLinks.Insert(Column.Name, Column.ChoiceParameterLinks);
		EndIf;
		TemporaryVT.Columns.Add("CWT_" + Column.Name, Column.Type, Column.Presentation());
		AttributeArray.Add(New FormAttribute("CWT_" + Column.Name, Column.Type, "DataMatchingTable", Column.Presentation()));
	EndDo;
	
	For Each Column IN InformationByColumns Do
		TemporaryVT.Columns.Add("Individual_" + Column.ColumnName, StringType, Column.ColumnPresentation);
		AttributeArray.Add(New FormAttribute("Individual_" + Column.ColumnName, StringType, "DataMatchingTable", Column.ColumnPresentation));
	EndDo;
	
	ChangeAttributes(AttributeArray);
	AttributesCreated = True;
	
	ColumnsGroupImportedData = Items.Add("ExportableData", Type("FormGroup"), Items.DataMatchingTable);
	ColumnsGroupImportedData.Group = ColumnsGroup.Horizontal; 
	
	For Each Column IN TemporaryVT.Columns Do
		
		If Left(Column.Name, 3) = "CWT_" Then
			ColumnsGroupImportedTPData = Items.Add("ExportableData_" + Column.Name , Type("FormGroup"), ColumnsGroupImportedData);
			ColumnsGroupImportedTPData.Group = ColumnsGroup.Vertical;
			Parent = ColumnsGroupImportedTPData;
		ElsIf Left(Column.Name, 3) = "Individual_" Then
			Continue;
		Else
			Parent = ColumnsGroupImportedData;
		EndIf;
		
		NewItem = Items.Add(Column.Name, Type("FormField"), Parent);
		
		NewItem.Type = FormFieldType.InputField;
		NewItem.DataPath = "DataMatchingTable." + Column.Name;
		NewItem.Title = Column.Title;
		NewItem.ChoiceHistoryOnInput = ChoiceHistoryOnInput.DontUse;
		
		If StrLen(Column.Name) > 3 AND Left(Column.Name, 3) = "CWT_" Then
			Filter = New Structure("ColumnName", Mid(Column.Name, 4));
			Columns = InformationByColumns.FindRows(Filter);
			If Columns.Count() > 0 Then 
				NewItem.Visible = Columns[0].Visible;
			EndIf;
		EndIf;
		
		If Column.Name = "ID" Then
			NewItem.FixingInTable = FixingInTable.Left;
			NewItem.ReadOnly = True;
			NewItem.Width = 1;
		ElsIf Column.Name = "RowMatchResult" OR Column.Name = "ErrorDescription" Then
			NewItem.Visible = False;
		EndIf;
		
		If MandatoryColumns.Find(Column.Name) <> Undefined Then 
			NewItem.AutoMarkIncomplete = True;
		EndIf;
		
		If Left(Column.Name, 3) = "CWT_" Then
			ColumnType = Metadata.FindByType(Column.ValueType.Types()[0]);
			If ColumnType <> Undefined AND Find(ColumnType.FullName(), "Catalog") > 0 Then
				NewItem.HeaderPicture = PictureLib.Change;
			EndIf;
			
			ColumnSelectionParametersLink = ColumnsContainingSelectionParametersLinks.Get(Mid(Column.Name, 4));
			If ColumnSelectionParametersLink <> Undefined Then 
				NewArray = New Array();
				For Each ChoiceParameterLink IN ColumnSelectionParametersLink Do
					Position = StringFunctionsClientServer.FindCharFromEnd(ChoiceParameterLink.DataPath, ".");
					If Position > 0 Then
						ItemName = Mid(ChoiceParameterLink.DataPath, Position + 1);
						NewConnection = New ChoiceParameterLink(ChoiceParameterLink.Name, "Items.DataMatchingTable.CurrentData.CWT_" + ItemName, ChoiceParameterLink.ValueChange);
						NewArray.Add(NewConnection);
					EndIf;
				EndDo;
				NewConnections = New FixedArray(NewArray);
				NewItem.ChoiceParameterLinks = NewConnections;
			EndIf;
			
			Filter = New Structure("Association", Mid(Column.Name, 4));
			AssociationsColumns = InformationByColumns.FindRows(Filter);
			
			If AssociationsColumns.Count() = 1 Then
				
				ColumnLevel2 = TemporaryVT.Columns.Find("Individual_" + AssociationsColumns[0].ColumnName);
				If ColumnLevel2 <> Undefined Then 
					NewItem = Items.Add(ColumnLevel2.Name, Type("FormField"), Parent);
					NewItem.Type = FormFieldType.InputField;
					NewItem.DataPath = "DataMatchingTable." + ColumnLevel2.Name;
					ColumnType = Metadata.FindByType(ColumnLevel2.ValueType.Types()[0]);
					If ColumnType <> Undefined AND Find(ColumnType.FullName(), "Catalog") > 0 Then
						NewItem.Title = NStr("en='Data from file';ru='Данные из файла';vi='Dữ liệu từ tệp'");
					Else
						NewItem.Title = " ";
					EndIf;
					NewItem.ReadOnly = True;
					NewItem.TextColor = StyleColors.ExplanationText;
				EndIf;
				
			ElsIf AssociationsColumns.Count() > 1 Then
				ColumnsGroupImportedTPData = Items.Add("ImportedData_Individual_" + Column.Name , Type("FormGroup"), Parent);
				ColumnsGroupImportedTPData.Group = ColumnsGroup.InCell;
				Parent = ColumnsGroupImportedTPData;
				
				Prefix = NStr("en='Data from file:';ru='Данные из файла:';vi='Dữ liệu từ tệp:'");
				For Each ColumnAssociation IN AssociationsColumns Do
					Column2 = TemporaryVT.Columns.Find("Individual_" + ColumnAssociation.ColumnName);
					If Column2 <> Undefined Then 
						NewItem = Items.Add(Column2.Name, Type("FormField"), Parent); 
						NewItem.Type = FormFieldType.InputField;
						NewItem.DataPath = "DataMatchTable." + Column2.Name;
						NewItem.Title = Prefix + Column2.Title;
						NewItem.ReadOnly = True;
						NewItem.TextColor = StyleColors.ExplanationText;
						
						If StrLen(Column.Name) > 3 AND Left(Column.Name, 3) = "Individual_" Then
						Filter = New Structure("ColumnName", Mid(Column.Name, 4));
						Columns = InformationByColumns.FindRows(Filter);
							If Columns.Count() > 0 Then 
								NewItem.Visible = Columns[0].Visible;
							EndIf;
						EndIf;
						
					EndIf;
					Prefix = "";
				EndDo;
			Else
				NewItem.Visible = False;
			EndIf;
		EndIf;
	EndDo;
	
	ValueToFormAttribute(TemporaryVT, "DataMatchingTable");
EndProcedure

&AtServer
Function ThisColumnIsMandatoryToFill(ColumnName)
	Filter = New Structure("ColumnName", ColumnName);
	Column =  InformationByColumns.FindRows(Filter);
	If Column.Count()>0 Then 
		Return Column[0].ObligatoryToComplete;
	EndIf;
	
	Return False;
EndFunction

&AtServer
Procedure ClearTemplateWithData()
	TitleArea = TemplateWithData.GetArea(1, 1, 1, TemplateWithData.TableWidth);
	TemplateWithData.Clear();
	TemplateWithData.Put(TitleArea);
EndProcedure

&AtServer
Function GroupAttributeChangeOnServer(UpperPosition, LowerPosition)
	RefArray = New Array;
	For Position = UpperPosition To LowerPosition Do 
		Cell = TableReport.GetArea(Position, 2, Position, 2);	
		If ValueIsFilled(Cell.CurrentArea.Details) Then 
			RefArray.Add(Cell.CurrentArea.Details);
		EndIf;
	EndDo;
	Return RefArray;
EndFunction

#Region FileOperations

&AtClient
Procedure OnEndPlacingFile(Result, TemporaryStorageAddress, FileName, Parameter) Export
	
	If Result = True Then
		Extension = CommonUseClientServer.ExtensionWithoutDot(
		CommonUseClientServer.GetFileNameExtension(FileName));
		If Extension = "csv" OR Extension = "xlsx" OR Extension = "mxl" Then
			BackgroundJob = False;
			ImportFileWithDataToTabularDocumentOnServer(TemporaryStorageAddress, Extension, BackgroundJob);
			If BackgroundJob Then
				LongActionsClient.InitIdleHandlerParameters(HandlerParameters);
				AttachIdleHandler("BackgroundJobImportFileOnClient", 1, True);
				HandlerParameters.MaxInterval = 5;
				LongOperationForm = LongActionsClient.OpenLongOperationForm(ThisObject, BackgroundJobID);
			Else
				TransferToImportDataNextStep();
			EndIf;
		Else
			ShowMessageBox(,NStr("en='Cannot import data from this file. Make sure that data in the file is correct.';ru='Не получилось загрузить данные из этого файла. Убедитесь в корректности данных в файле.';vi='Không thể kết nhập dữ liệu từ tệp này. Hãy chắc chắn dữ liệu trong tệp là đúng.'"));        
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterSelectingFileExtension(Result, Parameter) Export
	If ValueIsFilled(Result) Then
		AddressInTemporaryStorage = ThisObject.UUID;
		SaveTemplateToTemporaryStorage(Result, AddressInTemporaryStorage);
		GetFile(AddressInTemporaryStorage, CorrelationObjectName + "." + Result, True);
	EndIf;
EndProcedure

&AtServer
Procedure SaveTemplateToTemporaryStorage(FileExtension, AddressInTemporaryStorage)
	
	FileName = GetTempFileName(FileExtension);
	If FileExtension = "csv" Then 
		SaveTableToCSVFile(FileName);
	ElsIf FileExtension = "xlsx" Then 
		TemplateWithData.Write(FileName, SpreadsheetDocumentFileType.xlsx);
	Else 
		TemplateWithData.Write(FileName, SpreadsheetDocumentFileType.mxl);
	EndIf;
	BinaryData = New BinaryData(FileName);
	
	AddressInTemporaryStorage = PutToTempStorage(BinaryData, AddressInTemporaryStorage);
EndProcedure

&AtServerNoContext
Function GenerateFileNameForMetadataObject(MetadataObjectName)
	CatalogMetadata = Metadata.FindByFullName(MetadataObjectName);
	
	If CatalogMetadata <> Undefined Then 
		FileName = TrimAll(CatalogMetadata.Synonym);
		If StrLen(FileName) = 0 Then 
			FileName = MetadataObjectName;	
		EndIf;
	Else
		FileName = MetadataObjectName;
	EndIf;
	
	FileName = StrReplace(FileName,":","");
	FileName = StrReplace(FileName,"*","");
	FileName = StrReplace(FileName,"\","");
	FileName = StrReplace(FileName,"/","");
	FileName = StrReplace(FileName,"&","");
	FileName = StrReplace(FileName,"<","");
	FileName = StrReplace(FileName,">","");
	FileName = StrReplace(FileName,"|","");
	FileName = StrReplace(FileName,"""","");
	
	Return FileName;
EndFunction 

&AtClient
Procedure GetPathToFileSelectionBegin(DialogMode, PathToFile, FileName = "")
	
	FileDialog = New FileDialog(DialogMode);
	
	FileDialog.Filter                      = NStr("en='Excel 2007 Workbook (*.xlsx)|*.xlsx|Text document with separators (*.csv)|*.csv|Tabular document (*.mxl)|*.mxl';ru='Книга Excel 2007 (*.xlsx)|*.xlsx|Текстовый документ c разделителями (*.csv)|*.csv|Табличный документ (*.mxl)|*.mxl';vi='Tờ Excel 2007 (*.xlsx)|*.xlsx|Văn bản thuần có đường chia tách (*.csv)|*.csv|Văn bản dạng bảng (*.mxl)|*.mxl'");
	FileDialog.Title                   = Title;
	FileDialog.Preview     = False;
	FileDialog.Extension                  = "xlsx";
	FileDialog.FilterIndex               = 0;
	FileDialog.FullFileName              = FileName;
	FileDialog.CheckFileExist = False;
	
	If FileDialog.Choose() Then
		PathToFile = FileDialog.FullFileName;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterQuestionAboutCancelMatch(Result, Parameter) Export
	
	If Result = DialogReturnCode.Yes Then
		For Each TableRow IN DataMatchingTable Do
			TableRow.MappingObject = Undefined;
			TableRow.RowMatchResult = "NotMatched";
			TableRow.AmbiguitiesList = Undefined;
			TableRow.ErrorDescription = "";
		EndDo;
		ShowStatisticsByMatchLoadFromFile();
	EndIf;
	
EndProcedure

&AtServer
Procedure ImportFileWithDataToTabularDocumentOnServer(TemporaryStorageAddress, Extension, BackgroundJob = False)
	TempFileName=GetTempFileName(Extension);
	BinaryData = GetFromTempStorage(TemporaryStorageAddress);
	BinaryData.Write(TempFileName);
	
	ClearTemplateWithData();

	ServerCallParameters = New Structure();
	ServerCallParameters.Insert("Extension", Extension);
	ServerCallParameters.Insert("TemplateWithData", TemplateWithData);
	ServerCallParameters.Insert("TempFileName", TempFileName);
	TableInformationByColumns = FormAttributeToValue("InformationByColumns");
	ServerCallParameters.Insert("InformationByColumns", TableInformationByColumns);
	
	BackgroundJobResult = LongActions.ExecuteInBackground(UUID, 
	"DataProcessors.DataLoadFromFile.ImportFileIntoTable",
	ServerCallParameters, 
	NStr("en='The DataLoadFromFile subsystem: Execute the processing server method import data from file';ru='Подсистема ЗагрузкаДанныхИзФайла: Выполнение серверного метода загрузка данных из файла';vi='Phân hệ DataLoadFromFile: Thực hiện phương pháp Client-Server kết nhập dữ liệu từ tệp'"));
	
	If BackgroundJobResult.JobCompleted Then
		BackgroundJobStorageAddress = BackgroundJobResult.StorageAddress;
		TemplateWithData = GetFromTempStorage(BackgroundJobStorageAddress);
	Else
		BackgroundJob = True;
		BackgroundJobID  = BackgroundJobResult.JobID;
		BackgroundJobStorageAddress = BackgroundJobResult.StorageAddress;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterCallingFormChangeForm(Result, Parameter) Export
	
	If Result <> Undefined Then
		If Result.Count() > 0 Then
			For Each TableRow IN Result Do
				FilterParameters = New Structure("ColumnName", TableRow.ColumnName);
				FoundString = InformationByColumns.FindRows(FilterParameters)[0];
				FillPropertyValues(FoundString, TableRow);
			EndDo;
		Else
			InformationByColumns.Clear();
			FormTemplateByImportType();
		EndIf;
		InformationByColumns.Sort("Position Asc");
		RefreshTableColumnsNamesMatches();
		ChangeFormForInformationByColumns();
	EndIf;
	
EndProcedure

&AtServer
Procedure ChangeFormForInformationByColumns(Form = Undefined)

	WithNotes = False;
	If Form = Undefined Then 
		Form = TemplateWithData;
		WithNotes = True;
	EndIf;
	
	ColumnsTable = FormAttributeToValue("InformationByColumns");
	CommonUse.CommonSettingsStorageSave("DataLoadFromFile", CorrelationObjectName, ColumnsTable,, UserName());
	Form.Clear();
	Header = DataProcessors.DataLoadFromFile.FormHeaderToFillByInformationByColumns(ColumnsTable, WithNotes);
	Form.Put(Header);
	ShowInformationRowAboutMandatoryColumns();
	
EndProcedure

&AtClient
Procedure TemplateWithDataOnChange(Item)
	ClosingFormConfirmation = False;
EndProcedure

#EndRegion 

#Region SB

&AtServer
Procedure RefreshTableColumnsNamesMatches()
	
	For Each TableRow IN InformationByColumns Do 
		Column = Items.DataMatchingTable.ChildItems.Find(TableRow.ColumnName);
		Column.Title = ?(NOT IsBlankString(TableRow.Synonym), 
			TableRow.Synonym + " (" + TableRow.ColumnPresentation +")", 
			TableRow.ColumnPresentation);
	EndDo;

EndProcedure

&AtClient
Procedure ImportDataWithOtherMethodClick(Item)
	
	ClosingResult = New Structure;
	ClosingResult.Insert("ActionsDetails", "ChangeDataImportFromExternalSourcesMethod");
	
	Close(ClosingResult);
	
EndProcedure

#EndRegion 

#EndRegion




















