
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then
		Return;
	EndIf;
	
	MetadataObject = Metadata.FindByFullName(Parameters.FullObjectName);
	
	If CommonUseSTL.ThisIsConstant(MetadataObject) Then
		ObjectTypePresentation = NStr("en='constant';ru='константе';vi='hằng'");
	ElsIf CommonUseSTL.ThisIsCatalog(MetadataObject) Then
		ObjectTypePresentation = NStr("en='catalog';ru='справочнику';vi='danh mục'");
	ElsIf CommonUseSTL.ThisIsDocument(MetadataObject) Then
		ObjectTypePresentation = NStr("en='document';ru='документу';vi='cho chứng từ'");
	ElsIf CommonUseSTL.IsSequenceRecordSet(MetadataObject) Then
		ObjectTypePresentation = NStr("en='sequences';ru='последовательности';vi='trình tự'");
	ElsIf CommonUseSTL.IsDocumentJournal(MetadataObject) Then
		ObjectTypePresentation = NStr("en='document journal';ru='журналу документов';vi='nhật ký chứng từ'");
	ElsIf CommonUseSTL.IsEnum(MetadataObject) Then
		ObjectTypePresentation = NStr("en='enumeration';ru='перечислению';vi='chuyển khoản'");
	ElsIf CommonUseSTL.ThisIsChartOfCharacteristicTypes(MetadataObject) Then
		ObjectTypePresentation = NStr("en='chart of characteristic types';ru='плану видов характеристик';vi='hệ thống dạng đặc tính'");
	ElsIf CommonUseSTL.ThisIsChartOfAccounts(MetadataObject) Then
		ObjectTypePresentation = NStr("en='chart of accounts';ru='плану счетов';vi='hệ thống tài khoản'");
	ElsIf CommonUseSTL.ThisIsChartOfCalculationTypes(MetadataObject) Then
		ObjectTypePresentation = NStr("en='chart of calculation types';ru='плану видов расчета';vi='hệ thống dạng tính'");
	ElsIf CommonUseSTL.ThisIsInformationRegister(MetadataObject) Then
		ObjectTypePresentation = NStr("en='information register';ru='регистру сведений';vi='biểu ghi thông tin'");
	ElsIf CommonUseSTL.ThisIsAccumulationRegister(MetadataObject) Then
		ObjectTypePresentation = NStr("en='accumulation register';ru='регистру накопления';vi='biểu ghi tích lũy'");
	ElsIf CommonUseSTL.IsAccountingRegister(MetadataObject) Then
		ObjectTypePresentation = NStr("en='accounting register';ru='регистру бухгалтерии';vi='biểu ghi kế toán'");
	ElsIf CommonUseSTL.ThisIsCalculationRegister(MetadataObject) Then
		ObjectTypePresentation = NStr("en='calculation register';ru='регистру расчета';vi='biểu ghi tính toán'");
	ElsIf CommonUseSTL.IsRecalculationRecordSet(MetadataObject) Then
		ObjectTypePresentation = NStr("en='recalculation';ru='перерасчету';vi='hạch toán lại'");
	ElsIf CommonUseSTL.ThisIsBusinessProcess(MetadataObject) Then
		ObjectTypePresentation = NStr("en='business process';ru='бизнес-процессу';vi='quy trình nghiệp vụ'");
	ElsIf CommonUseSTL.ThisIsTask(MetadataObject) Then
		ObjectTypePresentation = NStr("en='task';ru='задаче';vi='nhiệm vụ'");
	ElsIf CommonUseSTL.ThisIsExchangePlan(MetadataObject) Then
		ObjectTypePresentation = NStr("en='exchange plan';ru='плану обмена';vi='sơ đồ trao đổi'");
	EndIf;
	
	If Parameters.Insert Then
		
		Items.GroupPagesHeader.CurrentPage = Items.GroupPageHeaderAdd;
		Items.GroupPagesFooter.CurrentPage = Items.GroupPageFooterAdd;
		Items.DecorationTitleHeaderAdd.Title = StringFunctionsClientServer.SubstituteParametersInString(
			Items.DecorationTitleHeaderAdd.Title,
			ObjectTypePresentation,
			MetadataObject.Presentation()
		);
		
	Else
		
		Items.GroupPagesHeader.CurrentPage = Items.GroupHeaderPageDelete;
		Items.GroupPagesFooter.CurrentPage = Items.GroupFooterPageDelete;
		Items.DecorationTitleHeaderDelete.Title = StringFunctionsClientServer.SubstituteParametersInString(
			Items.DecorationTitleHeaderDelete.Title,
			ObjectTypePresentation,
			MetadataObject.Presentation()
		);
		
	EndIf;
	
	ThisObject.Title = StringFunctionsClientServer.SubstituteParametersInString(
		ThisObject.Title, MetadataObject.Presentation());
	
	// Filling of tree
	
	Tree = New ValueTree();
	
	Tree.Columns.Add("DescriptionFull", New TypeDescription("String"));
	Tree.Columns.Add("Presentation", New TypeDescription("String"));
	Tree.Columns.Add("Class", New TypeDescription("Number", , New NumberQualifiers(10, 0, AllowedSign.Nonnegative)));
	Tree.Columns.Add("Picture", New TypeDescription("Picture"));
	
	AddTreeRootString(Tree, "Constant", NStr("en='Constants';ru='Константы';vi='Hằng'"), 1, PictureLib.Constant);
	AddTreeRootString(Tree, "Catalog", NStr("en='Catalogs';ru='Справочники';vi='Danh mục'"), 2, PictureLib.Catalog);
	AddTreeRootString(Tree, "Document", NStr("en='Documents';ru='Документы';vi='Chứng từ'"), 3, PictureLib.Document);
	AddTreeRootString(Tree, "DocumentJournal", NStr("en='Document logs';ru='Журналы документов';vi='Nhật ký chứng từ'"), 4, PictureLib.DocumentJournal);
	AddTreeRootString(Tree, "Enum", NStr("en='Enum';ru='Перечисление';vi='Chuyển khoản'"), 5, PictureLib.Enum);
	AddTreeRootString(Tree, "ChartOfCharacteristicTypes", NStr("en='Charts of characteristic types';ru='Планы видов характеристик';vi='Hệ thống dạng đặc tính'"), 6, PictureLib.ChartOfCharacteristicTypes);
	AddTreeRootString(Tree, "ChartOfAccounts", NStr("en='Charts of accounts';ru='Планы счетов';vi='Hệ thống tài khoản'"), 7, PictureLib.ChartOfAccounts);
	AddTreeRootString(Tree, "ChartOfCalculationTypes", NStr("en='Charts of calculation types';ru='Планы видов расчета';vi='Hệ thống dạng tính toán'"), 8, PictureLib.ChartOfCalculationTypes);
	AddTreeRootString(Tree, "InformationRegister", NStr("en='Information registers';ru='Регистры сведений';vi='Biểu ghi thông tin'"), 9, PictureLib.InformationRegister);
	AddTreeRootString(Tree, "AccumulationRegister", NStr("en='Accumulation registers';ru='Регистры накопления';vi='Biểu ghi tích lũy'"), 10, PictureLib.AccumulationRegister);
	AddTreeRootString(Tree, "AccountingRegister", NStr("en='Accounting registers';ru='Регистры бухгалтерии';vi='Biểu ghi kế toán'"), 11, PictureLib.AccountingRegister);
	AddTreeRootString(Tree, "CalculationRegister", NStr("en='Calculation registers';ru='Регистры расчета';vi='Biểu ghi tính toán'"), 12, PictureLib.CalculationRegister);
	AddTreeRootString(Tree, "BusinessProcess", NStr("en='Business processes';ru='Деловые процессы';vi='Quy trình nghiệp vụ'"), 13, PictureLib.BusinessProcess);
	AddTreeRootString(Tree, "Task", NStr("en='Tasks';ru='Задания';vi='Nhiệm vụ'"), 14, PictureLib.Task);
	AddTreeRootString(Tree, "ExchangePlan", NStr("en='Exchange plans';ru='Планы обмена';vi='Sơ đồ trao đổi'"), 15, PictureLib.ExchangePlan);
	
	For Each Dependence IN Parameters.ObjectDependencies Do
		AddTreeSubstring(Tree, Metadata.FindByFullName(Dependence));
	EndDo;
	
	Tree.Columns.Delete(Tree.Columns["DescriptionFull"]);
	Tree.Columns.Delete(Tree.Columns["Class"]);
	
	RowsToDelete = New Array();
	For Each TreeRow IN Tree.Rows Do
		If TreeRow.Rows.Count() = 0 Then
			RowsToDelete.Add(TreeRow);
		EndIf;
	EndDo;
	For Each RemovedRow IN RowsToDelete Do
		Tree.Rows.Delete(RemovedRow);
	EndDo;
	
	ValueToFormAttribute(Tree, "MetadataObjects");
	
EndProcedure

&AtServer
Procedure AddTreeRootString(Tree,Val DescriptionFull, Val Presentation, Val Class, Val Picture)
	
	NewRow = Tree.Rows.Add();
	NewRow.DescriptionFull = DescriptionFull;
	NewRow.Presentation = Presentation;
	NewRow.Class = Class;
	NewRow.Picture = Picture;
	
EndProcedure

Procedure AddTreeSubstring(Tree, Val MetadataObject)
	
	DescriptionFull = MetadataObject.FullName();
	
	NameStructure = StringFunctionsClientServer.DecomposeStringIntoSubstringsArray(DescriptionFull, ".");
	ClassObject = NameStructure[0];
	
	RowOwner = Undefined;
	For Each TreeRow IN Tree.Rows Do
		If TreeRow.DescriptionFull = ClassObject Then
			RowOwner = TreeRow;
			Break;
		EndIf;
	EndDo;
	
	If RowOwner = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='Unknown metadata object: %1';ru='Неизвестный объект метаданных: %1';vi='Chưa xác định đối tượng metadata: %1'"), DescriptionFull);
	EndIf;
	
	NewRow = RowOwner.Rows.Add();
	
	NewRow.Presentation = MetadataObject.Presentation();
	NewRow.Class = RowOwner.Class;
	NewRow.Picture = RowOwner.Picture;
	
EndProcedure
