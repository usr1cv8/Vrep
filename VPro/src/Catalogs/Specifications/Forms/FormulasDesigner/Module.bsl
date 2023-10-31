
#Region FormEvents

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("ProductsAndServicesCategory", ProductsAndServicesCategory);
	Parameters.Property("SimpleTypes", SimpleTypes);
	Parameters.Property("TypeRestriction", TypeRestriction);
	Parameters.Property("LongDesc", LongDesc);
	Parameters.Property("TSName", TSName);
	If Parameters.Property("ChoiceParameters") Then
		Items.MappingProductsAndServices.ChoiceParameters = Parameters.ChoiceParameters;
	EndIf; 
	
	CashValues = New Structure;
	CashValues.Insert("OperandBegin", ProductionFormulasServer.OperandBeginString());
	CashValues.Insert("OperandEnd", ProductionFormulasServer.OperandEndString());
	
	Scheme = Catalogs.Specifications.GetTemplate("FormulaDesignerScheme");
	If ValueIsFilled(ProductsAndServicesCategory) Then
		CategoryAttributes = CommonUse.ObjectAttributesValues(ProductsAndServicesCategory, "PropertySet, CharacteristicPropertySet, SpecificationAttributesArray");
		Scheme.Parameters.PropertySet.Value = CategoryAttributes.PropertySet;
		Scheme.Parameters.CharacteristicPropertySet.Value = CategoryAttributes.CharacteristicPropertySet;
		Scheme.Parameters.SpecificationAttributesArray.Value = CategoryAttributes.SpecificationAttributesArray;
	EndIf; 
	SchemaURL = PutToTempStorage(Scheme, UUID);
	Composer.Initialize(New DataCompositionAvailableSettingsSource(SchemaURL));
	
	FillOperandsTree();
	FillOperatorsTree();
	
	If Not SimpleTypes And Parameters.Property("MappingUsed") And Parameters.MappingUsed Then
		Mode = 1;
		FillMappingTable(Parameters);
	Else
		Parameters.Property("Formula", Formula);
	EndIf;
	
	FormManagement(ThisObject);	
	
EndProcedure

#EndRegion

#Region FormItemsEvents

&AtClient
Procedure ModeOnChange(Item)
	
	If MappingAttributes.Count()=0 Then
		FillMappingTable(New Structure("Mapping", New Array));
	EndIf; 
	
	FormManagement(ThisObject);	
	
EndProcedure

&AtClient
Procedure FormulaOnChange(Item)
	
	OperatorsAllowingComma = New Array;
	OperatorsAllowingComma.Add("Min");
	OperatorsAllowingComma.Add("Max");
	OperatorsAllowingComma.Add("Round");
	
	NumberOfAcceptableCommas = 0;
	For Each ArrayElement In OperatorsAllowingComma Do
		
		NumberOfAcceptableCommas = NumberOfAcceptableCommas + StrOccurrenceCount(Upper(Formula), Upper(ArrayElement));
		
	EndDo;
	
	NumberOfCommas = StrOccurrenceCount(Formula, ",");
	If NumberOfCommas > NumberOfAcceptableCommas Then
		
		TextOfMessage = NStr("en='To indicate the fractional part, you need to use a dot, not a comma.';ru='Для указания дробной части необходимо использовать точку, а не запятую.';vi='Để chỉ ra phần thập phân, cần sử dụng dấu chấm, không phải dấu phẩy.'");
		CommonUseClientServer.MessageToUser(TextOfMessage, , "Formula");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OperandsTreeSelection(Item, SelectedRow, Field, StandardProcessing)
	
	DataCurrentRows = Items.OperandsTree.CurrentData;
	If DataCurrentRows = Undefined Then
		Return;
	EndIf;
	
	If DataCurrentRows.GetItems().Count()>0 Then
		// Группы операндов не используются в формулах
		Return;
	EndIf; 
	
	InsertText = CashValues.OperandBegin + DataCurrentRows.Operand + CashValues.OperandEnd;
	
	InsertTextInFormula(InsertText);
	
EndProcedure

&AtClient
Procedure OperandsTreeDragStart(Item, DragParameters, Execution)
	
	DataCurrentRows = Items.OperandsTree.CurrentData;
	If DataCurrentRows = Undefined Then
		Return;
	EndIf;
	
	If DataCurrentRows.GetItems().Count()>0 Then
		// Группы операндов не используются в формулах
		Return;
	EndIf;
	
	DragParameters.Value = CashValues.OperandBegin + DataCurrentRows.Operand + CashValues.OperandEnd;
	
EndProcedure

&AtClient
Procedure OperatorsSelection(Item, SelectedRow, Field, StandardProcessing)
	
	DataCurrentRows = Items.Operators.CurrentData;
	If DataCurrentRows = Undefined Then
		
		Return;
		
	EndIf;
	
	TextAddingSettings = BeforeAddTextToFormula(DataCurrentRows.Operator);
	If Not TextAddingSettings.Cancel = True Then
		
		InsertTextInFormula(TextAddingSettings.InsertText, TextAddingSettings.ReplaceTextFormula);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OperatorsDragEnd(Item, DragParameters, StandardProcessing)
	
	If DragParameters.Value.Count() < 0 Then
		
		Return;
		
	EndIf;
	
	DataCurrentRows = DragParameters.Value[0];
	If DataCurrentRows = Undefined Then
		
		Return;
		
	EndIf;
	
	StandardProcessing = False;
	
	TextAddingSettings = BeforeAddTextToFormula(DataCurrentRows.Operator);
	If Not TextAddingSettings.Cancel = True Then
		
		InsertTextInFormula(TextAddingSettings.InsertText, TextAddingSettings.ReplaceTextFormula);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_MappingAttributeBeginSelection(Item, ChoiceData, StandardProcessing)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("RowIndex", Items.GroupMappingAttributes.ChildItems.IndexOf(Item));
	Notification = New NotifyDescription("MappingAttributeSelectionCompletion", ThisObject, AdditionalParameters);
	OpenParameters = New Structure;
	OpenParameters.Insert("Title", NStr("en='Comparison fields';ru='Поля сопоставления';vi='Trường so sánh'"));
	OpenParameters.Insert("Mode", "GroupFields");
	OpenParameters.Insert("SchemaURL", SchemaURL);
	OpenParameters.Insert("SettingsAddress", PutToTempStorage(Composer.Settings, UUID));
	FieldList = New ValueList;
	For Each AttributeString In MappingAttributes Do
		If TypeOf(AttributeString.Attribute)<>Type("String") Or IsBlankString(AttributeString.Attribute) Then
			Continue;
		EndIf;
		FieldList.Add(AttributeString.Attribute);
	EndDo; 
	OpenParameters.Insert("ExistingFields", FieldList);
	OpenForm("CommonForm.FieldListForm", OpenParameters, , , , , Notification, FormWindowOpeningMode.LockOwnerWindow);
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure MappingAttributeSelectionCompletion(SelectedValue, AdditionalParameters) Export
	
	If Not ValueIsFilled(SelectedValue) Then
		Return;
	EndIf;
	
	AttributeString = MappingAttributes[AdditionalParameters.RowIndex];
	AttributeString.Attribute = SelectedValue;
	MappingAttributeSelectionCompletionServer(AttributeString.GetID());
	
EndProcedure

&AtServer
Procedure MappingAttributeSelectionCompletionServer(ID)
	
	FillTypeAttributeCaption(ID);
	UpdateAttributesOnForm(ID);
	
EndProcedure

&AtClient
Procedure Attachable_MappingAttributeClear(Item, StandardProcessing)
	
	StandardProcessing = False;
	AttributeName = Item.Name;
	MappingAttributeClearServer(AttributeName);	
	
EndProcedure

&AtServer
Procedure MappingAttributeClearServer(AttributeName)
	
	SearchStructure = New Structure;
	SearchStructure.Insert("AttributeName", AttributeName);
	Rows = MappingAttributes.FindRows(SearchStructure);
	If Rows.Count()=0 Then
		Return;
	EndIf;
	
	AttributesToBeRemoved = New Array;
	DeletedItems = New Array;
	For Each AttributeString In MappingAttributes Do
		Item = Items.Find(AttributeString.AttributeName);
		If Item<>Undefined Then
			DeletedItems.Add(Item);
		EndIf; 
	EndDo; 
	Item = Items.Find("Column"+AttributeName);
	If Item<>Undefined Then
		DeletedItems.Add(Item);
		AttributesToBeRemoved.Add("Mapping." + AttributeName);
	EndIf;
	
	AttributeString = Rows[0];
	MappingAttributes.Delete(AttributeString);
	
	For Each Item In DeletedItems Do
		Items.Delete(Item);
	EndDo; 
	If AttributesToBeRemoved.Count()>0 Then
		ChangeAttributes(, AttributesToBeRemoved);
	EndIf;
	
	For Each AttributeString In MappingAttributes Do
		Item = Items.Add(AttributeString.AttributeName, Type("FormField"), Items.GroupMappingAttributes);
		FillFilterItemProperties(Item, AttributeString);
	EndDo; 
	
	UpdateCleanButtons();
	
EndProcedure

&AtClient
Procedure MappingOnStartEdit(Item, NewRow, Copy)
	
	CurrentRow = Items.Mapping.CurrentData;
	
	// Заполнение ключей строк правил
	If Copy Then
		CurrentRow.RulesRowKey = 0;
	EndIf; 
	If NewRow Then
		NumbersList = New ValueList;
		For Each TabularSectionRow In Mapping Do
			If TabularSectionRow.RulesRowKey=0 And TabularSectionRow<>CurrentRow Then
				// Ошибка нумерации, незаполненные номера. Требуется перенумерация всей таблицы
				FillRulesKeys(Mapping);
				Return;
			EndIf; 
			If TabularSectionRow.RulesRowKey=0 Then
				Continue;
			EndIf; 
			NumbersList.Add(TabularSectionRow.RulesRowKey);
		EndDo;
		NumbersList.SortByValue();
		CurrentNumber = 1;
		For Each NumberItem In NumbersList Do
			If NumberItem.Value>CurrentNumber Then
				Break;
			ElsIf NumberItem.Value<CurrentNumber Then
				// Ошибка нумерации, повторяющиеся номера. Требуется перенумерация всей таблицы
				FillRulesKeys(Mapping);
				Return;
			EndIf;
			CurrentNumber = CurrentNumber + 1;
		EndDo;
		CurrentRow.RulesRowKey = CurrentNumber;
	EndIf; 
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillRulesKeys(Table)
	
	CurrentNumber = 1;
	For Each TabularSectionRow In Table Do
		TabularSectionRow.RulesRowKey = CurrentNumber;
		CurrentNumber = CurrentNumber + 1;
	EndDo;
 
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure OK(Command)
	
	If Not CheckFormFilling() Then
		Return;
	EndIf; 
	
	FormulaAdditionalProcessing();
	
	MappingMode = (Mode=1);
	Result = New Structure;
	Result.Insert("Result", DialogReturnCode.Yes);
	Result.Insert("MappingUsed", MappingMode);
	Result.Insert("Formula", ?(MappingMode, "", Formula));
	Result.Insert("Mapping", New Array);
	If MappingMode Then
		For Each TabularSectionRow In Mapping Do
			For Each AttributeString In MappingAttributes Do
				DescriptionStructure = New Structure;
				DescriptionStructure.Insert("RulesRowKey", TabularSectionRow.RulesRowKey);
				If TSName="Operations" Then
					DescriptionStructure.Insert("Operation", TabularSectionRow.ProductsAndServices);
				Else
					DescriptionStructure.Insert("ProductsAndServices", TabularSectionRow.ProductsAndServices);
					DescriptionStructure.Insert("Characteristic", TabularSectionRow.Characteristic);
				EndIf; 
				DescriptionStructure.Insert("MappingAttribute", AttributeString.Attribute);
				DescriptionStructure.Insert("ValueOfAttribute", TabularSectionRow[AttributeString.AttributeName]);
				Result.Mapping.Add(DescriptionStructure);
			EndDo; 
		EndDo; 
	EndIf;
	Result.Insert("LongDesc", LongDesc);
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure CheckFormula(Command)
	Var Errors;
	
	ClearMessages();
	CheckFormulaAtServer(Errors);
	
	If Errors = Undefined Then
		
		WarningText = NStr("en='The formula is suitable for calculations.';ru='Формула пригодна для расчетов.';vi='Công thức phù hợp để tính toán.'");
		ShowMessageBox(, WarningText, , NStr("en='Checking the formula';ru='Проверка формулы';vi='Kiểm tra công thức'"));
		
	Else
		
		CommonUseClientServer.ShowErrorsToUser(Errors);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AddMappingAttribute(Command)
	
	AddMappingAttributeServer();
	
EndProcedure

&AtServer
Procedure AddMappingAttributeServer()
	
	AttributeString = MappingAttributes.Add();
	AttributeString.AttributeName = AttributeNewName();
	UpdateAttributesOnForm(AttributeString.GetID());
 
EndProcedure

&AtClient
Procedure Fill(Command)
	
	For Each AttributeString In MappingAttributes Do
		If Not ValueIsFilled(AttributeString.Attribute) Then
			TextOfMessage = NStr("en='Not all matching attributes are filled.';ru='Заполнены не все реквизиты сопоставления.';vi='Đã điền không phải tất cả mục tin so sánh.'");
			CommonUseClientServer.MessageToUser(TextOfMessage, , AttributeString.AttributeName);
			Return;
		EndIf; 
	EndDo;  
	If Mapping.Count()>0 Then
		Notification = New NotifyDescription("FillEnd", ThisObject);
		TextOfMessage = NStr("en='These comparisons will be refilled. Continue?';ru='Данные сопоставления будут перезаполнены. Продолжить?';vi='Dữ liệu so sánh sẽ được điền lại. Tiếp tục?'");
		ShowQueryBox(Notification, TextOfMessage, QuestionDialogMode.OKCancel, 0, DialogReturnCode.Cancel); 
	Else
		FillFragment();
	EndIf; 
	
EndProcedure

&AtClient
Procedure FillEnd(ReturnCode, AdditionalParameters) Export
	
	If ReturnCode<>DialogReturnCode.OK Then
		Return;
	EndIf;
	
	FillFragment();
	
EndProcedure

&AtClient
Procedure FillFragment()
	
	FillMappingServer();	
	
EndProcedure
 
#EndRegion

#Region InternalProceduresAndFunctions

&AtClientAtServerNoContext
Procedure FormManagement(Form)
	
	Items = Form.Items;
	If Form.Mode=0 Then
		Items.Pages.CurrentPage = Items.FormulaPage;
	Else
		Items.Pages.CurrentPage = Items.PageMatching;
	EndIf;
	CommonUseClientServer.SetFormItemProperty(Items, "Validate", "Visible", Form.Mode=0);	
	CommonUseClientServer.SetFormItemProperty(Items, "Mode", "Visible", Form.TypeRestriction=Type("CatalogRef.ProductsAndServices"));	
	CommonUseClientServer.SetFormItemProperty(Items, "MappingCharacteristic", "Visible", Form.TSName="Content");
	If Form.TSName="Operations" Then
		CommonUseClientServer.SetFormItemProperty(Items, "MappingProductsAndServices", "Title", NStr("en='Operation';ru='Операция';vi='Thao tác'"));
	EndIf; 
	
EndProcedure

&AtClient
Function CheckFormFilling()
	
	Result = True;
	
	MappingMode = (Mode=1);
	If Not MappingMode And IsBlankString(Formula) Then
		TextOfMessage = NStr("en='No calculation formula has been set.';ru='Не задана формула расчета.';vi='Chưa đặt công thức tính.'");
		CommonUseClientServer.MessageToUser(TextOfMessage, , "Formula");
		Result = False;
	EndIf; 
	If MappingMode Then
		For Each AttributeString In MappingAttributes Do
			If Not ValueIsFilled(AttributeString.Attribute) Then
				TextOfMessage = NStr("en='No match details have been set.';ru='Не задан реквизит сопоставления.';vi='Chưa đặt mục tin so sánh.'");
				CommonUseClientServer.MessageToUser(TextOfMessage, , AttributeString.AttributeName);
				Result = False;
			EndIf; 
		EndDo;
		If Mapping.Count()=0 Then
			TextOfMessage = NStr("en='No mapping rules have been set.';ru='Не заданы правила сопоставления.';vi='Chưa đặt quy tắc so sánh.'");
			CommonUseClientServer.MessageToUser(TextOfMessage, , "Mapping");
			Result = False;
		EndIf;
		For Each MappingRow In Mapping Do
			If Not ValueIsFilled(MappingRow.ProductsAndServices) Then
				TextOfMessage = NStr("en='The item is not specified.';ru='Не указана заполняемая номенклатура.';vi='Chưa điền mặt hàng được điền'");
				CommonUseClientServer.MessageToUser(TextOfMessage, , , StrTemplate("Mapping[%1].ProductsAndServices", Mapping.IndexOf(MappingRow)));
				Result = False;
			EndIf; 
		EndDo; 
	EndIf; 
	
	Return Result;
	
EndFunction

&AtServer
Procedure FillOperandsTree()
	
	OperandsTree.GetItems().Clear();
	AvailableFields = Composer.Settings.GroupAvailableFields.Items;
	
	For Each Field In AvailableFields Do
		If Field.Folder Or Field.Resource Then
			Continue;
		EndIf;
		FieldName = String(Field.Field);
		ObjectString = OperandsTree.GetItems().Add();
		ObjectString.Operand = FieldName;
		ObjectString.Presentation = Field.Title;
		If FieldName="CustomerOrder" Or FieldName="ProductionOrder" Then
			ObjectString.Picture = PictureLib.Document;
		Else
			ObjectString.Picture = PictureLib.Catalog;
		EndIf;
		For Each Attribute In Field.Items Do
			AttributeName = String(Attribute.Field);
			IsProductionRow = (AttributeName="CustomerOrder.Inventory" Or AttributeName="ProductionOrder.Products");
			If Attribute.Folder And Not IsProductionRow Then
				// Прочие табличные части
				Continue;
			EndIf;
			If Not Attribute.Folder Then
				ItIsSimpleType = (Attribute.Type.ContainsType(Type("Number")) Or Attribute.Type.ContainsType(Type("String")) Or Attribute.Type.ContainsType(Type("Boolean")) Or Attribute.Type.ContainsType(Type("Date")));
				If TypeOf(TypeRestriction)=Type("Type") And Not Attribute.Type.ContainsType(TypeRestriction) And Not ItIsSimpleType Then
					// Неподходящий тип реквизита
					Continue;
				EndIf; 
				If SimpleTypes And Not ItIsSimpleType Then
					// Неподходящий тип реквизита
					Continue;
				EndIf; 
			EndIf; 
			AttributeString = ObjectString.GetItems().Add();
			AttributeString.Operand = AttributeName;
			AttributeString.Presentation = LastPartOfTitle(Attribute.Title, 1);
			If Attribute.Folder Then
				// ТЧ Запасы заказа покупателя и Продукция заказа на производство разворачиваем до реквизитов
				For Each TSAttribute In Attribute.Items Do
					ItIsSimpleType = (TSAttribute.Type.ContainsType(Type("Number")) Or TSAttribute.Type.ContainsType(Type("String")) Or TSAttribute.Type.ContainsType(Type("Boolean")) Or TSAttribute.Type.ContainsType(Type("Date")));
					If TypeOf(TypeRestriction)=Type("Type") And Not TSAttribute.Type.ContainsType(TypeRestriction) And Not ItIsSimpleType Then
						// Неподходящий тип реквизита
						Continue;
					EndIf; 
					If SimpleTypes And Not ItIsSimpleType Then
						// Неподходящий тип реквизита
						Continue;
					EndIf; 
					TSAttributeRow = AttributeString.GetItems().Add();
					TSAttributeRow.Operand = String(TSAttribute.Field);
					TSAttributeRow.Presentation = LastPartOfTitle(TSAttribute.Title, 2);
				EndDo; 
			EndIf; 
		EndDo;
	EndDo;
	
EndProcedure

&AtServer
Function LastPartOfTitle(Row, Level)
	
	Result = Row;
	Position = StrFind(Result, ".", SearchDirection.FromBegin, , Level);
	If Position>0 Then
		Result = Mid(Result, Position + 1);
	EndIf; 
	Return Result;
					
EndFunction

&AtClient
Function BeforeAddTextToFormula(Val InsertText)
	
	TextAddingSettings = New Structure("InsertText, ReplaceTextFormula, Cancel", InsertText, False, False);
	
	OperandData = Items.OperandsTree.CurrentData;
	
	If TrimAll(TextAddingSettings.InsertText) = "%1"
		Or TrimAll(TextAddingSettings.InsertText) = "%5"
		Or TrimAll(TextAddingSettings.InsertText) = "%20"
		Or TrimAll(TextAddingSettings.InsertText) = "%50"
		Then
		
		If OperandData = Undefined 
			Or IsBlankString(OperandData.Operand) Then
			
			TextOfMessage = NStr("en='What is the value from which you want to calculate the percentage';ru='Укажите значение, от которого необходимо вычислить процент';vi='Hãy chỉ ra giá trị mà bạn cần tính tỷ lệ phần trăm'");
			CommonUseClientServer.MessageToUser(TextOfMessage, , "OperandsTree");
			
			TextAddingSettings.Cancel = True;
			Return TextAddingSettings;
			
		Else
			
			PresentationNumber = StrReplace(InsertText, "%", "");
			TextAddingSettings.InsertText = StrTemplate(" + (%1", CashValues.OperandBegin) + OperandData.Operand + StrTemplate("%1 / 100 * ", CashValues.OperandEnd) + PresentationNumber + ".0)";
			
		EndIf;
		
	EndIf;
	
	If TrimAll(TextAddingSettings.InsertText) = "IF" Then
		
		ConditionalOperatorFirstValue = "<?>";
		If Not IsBlankString(Formula) Then
			
			ConditionalOperatorFirstValue = Formula;
			Formula = "";
			TextAddingSettings.ReplaceTextFormula = True;
			
		ElsIf OperandData <> Undefined 
			And Not IsBlankString(OperandData.Operand) Then
			
			ConditionalOperatorFirstValue = CashValues.OperandBegin + OperandData.Operand + CashValues.OperandEnd;
			
		EndIf;
		
		TextAddingSettings.InsertText = StrTemplate("#IF <Condition>%1%2#THEN %3%1%2#ELSE <?>%1#ENDIF", Chars.LF, Chars.Tab, ConditionalOperatorFirstValue);
		
	EndIf;
	
	Return TextAddingSettings;
	
EndFunction

&AtClient
Procedure InsertTextInFormula(InsertText, ReplaceTextFormula = False)
	
	If IsBlankString(InsertText) Then
		
		Return;
		
	EndIf;
	
	If ReplaceTextFormula Then
		
		Formula = InsertText;
		Return;
		
	EndIf;
	
	#If MobileClient Then
		
		Formula = Formula + InsertText;
		
	#Else
		
		StringBegin = 0;
		StringEnd = 0;
		ColumnBeg = 0;
		ColumnEn = 0;
		
		Items.Formula.GetTextSelectionBounds(StringBegin, ColumnBeg, StringEnd, ColumnEn);
		If (ColumnEn = ColumnBeg) And (ColumnEn + StrLen(InsertText)) > Items.Formula.Width / 8 Then
			
			Items.Formula.SelectedText = "";
			
		EndIf;
			
		Items.Formula.SelectedText = InsertText;
		
	#EndIf
	
	ThisForm.CurrentItem = Items.Formula;
	
EndProcedure

&AtServer
Procedure FillOperatorsTree()
	
	OperatorsTree = FormAttributeToValue("Operators", Type("ValueTree"));
	
	GroupRows 				= OperatorsTree.Rows.Add();
	GroupRows.Description	= NStr("en='ARITHMETIC OPERATORS';ru='АРИФМЕТИЧЕСКИЕ ОПЕРАТОРЫ';vi='HOẠT ĐỘNG ARITHMETIC'"); // ava1c GLOBAL GroupRows.Description --> Description
	GroupRows.Picture		= 1;
	
	NewRow 				= GroupRows.Rows.Add();
	NewRow.Description	= NStr("en='Adding ""+""';ru='Сложение ""+""';vi='Cộng ""+""'");
	NewRow.Operator		= " + ";
	
	NewRow 				= GroupRows.Rows.Add();
	NewRow.Description	= NStr("en='Subtraction ""-""';ru='Вычитание ""-""';vi='Phép trừ ""-""'");
	NewRow.Operator		= " - ";
	
	NewRow 				= GroupRows.Rows.Add();
	NewRow.Description	= NStr("en='Multiplying ""*""';ru='Умножение ""*""';vi='Phép nhân ""*""'");
	NewRow.Operator		= " * ";
	
	NewRow 				= GroupRows.Rows.Add();
	NewRow.Description	= NStr("en='Division ""/""';ru='Деление ""/""';vi='Phân chia ""/""'");
	NewRow.Operator		= " / ";
	
	NewRow 				= GroupRows.Rows.Add();
	NewRow.Description	= NStr("en='The remainder of the division ""%""';ru='Остаток от деления ""%""';vi='Số dư sau khi chia ""%""'");
	NewRow.Operator		= " % ";
	
	GroupRows 				= OperatorsTree.Rows.Add();
	GroupRows.Description	= NStr("en='LOGICAL OPERATORS';ru='ЛОГИЧЕСКИЕ ОПЕРАТОРЫ';vi='HOẠT ĐỘNG LOGIC'");
	GroupRows.Picture		= 1;
	
	NewRow 				= GroupRows.Rows.Add();
	NewRow.Description	= NStr("en='If... Else... EndIf';ru='Если...Иначе...КонецЕсли';vi='If... Else... EndIf'");
	NewRow.Operator		= "IF"; // "#ЕСЛИ <Условие> #ТОГДА <?> #ИНАЧЕ <?> #КОНЕЦЕСЛИ";
	
	NewRow 				= GroupRows.Rows.Add();
	NewRow.Description	= NStr("en='>';ru='>';vi='>'");
	NewRow.Operator		= " > ";
	
	NewRow 				= GroupRows.Rows.Add();
	NewRow.Description	= NStr("en='>=';ru='>=';vi='>='");
	NewRow.Operator		= " >= ";
	
	NewRow 				= GroupRows.Rows.Add();
	NewRow.Description	= NStr("en='<';ru='<';vi='<'");
	NewRow.Operator		= " < ";
	
	NewRow 				= GroupRows.Rows.Add();
	NewRow.Description	= NStr("en='<=';ru='<=';vi='<='");
	NewRow.Operator		= " <= ";
	
	NewRow 				= GroupRows.Rows.Add();
	NewRow.Description	= NStr("en='=';ru='=';vi='= ='");
	NewRow.Operator		= " = ";
	
	NewRow 				= GroupRows.Rows.Add();
	NewRow.Description	= NStr("en='<>';ru='<>';vi='<>'");
	NewRow.Operator		= " <> ";
	
	NewRow 				= GroupRows.Rows.Add();
	NewRow.Description	= NStr("en='AND';ru='И';vi='VÀ'");
	NewRow.Operator		= " AND ";
	
	NewRow 				= GroupRows.Rows.Add();
	NewRow.Description	= NStr("en='OR';ru='ИЛИ';vi='OR'");
	NewRow.Operator		= " OR ";
	
	NewRow 				= GroupRows.Rows.Add();
	NewRow.Description	= NStr("en='NOT';ru='НЕ';vi='NOT'");
	NewRow.Operator		= " NOT ";
	
	NewRow 				= GroupRows.Rows.Add();
	NewRow.Description	= NStr("en='TRUE';ru='ИСТИНА';vi='TRUE'");
	NewRow.Operator		= " True ";
	
	NewRow 				= GroupRows.Rows.Add();
	NewRow.Description	= NStr("en='FALSE';ru='ЛОЖЬ';vi='SAI'");
	NewRow.Operator		= " False ";
	
	NewRow 				= GroupRows.Rows.Add();
	NewRow.Description	= NStr("en='Opening bracket ""(""';ru='Открывающая скобка ""(""';vi='Dấu mở ngoặc ""(""'");
	NewRow.Operator		= " (";
	
	NewRow 				= GroupRows.Rows.Add();
	NewRow.Description	= NStr("en='Closing bracket "")""';ru='Закрывающая скобка "")""';vi='Dấu ngoặc đóng "")""'");
	NewRow.Operator		= ") ";
	
	GroupRows 				= OperatorsTree.Rows.Add();
	GroupRows.Description	= NStr("en='FUNCTIONS';ru='ФУНКЦИИ';vi='CHỨC NĂNG'");
	GroupRows.Picture		= 1;
	
	NewRow 				= GroupRows.Rows.Add();
	NewRow.Description	= NStr("en='Maximum';ru='Максимум';vi='Tối đa'");
	NewRow.Operator		= " Max(<?>,<?>)";
	
	NewRow 				= GroupRows.Rows.Add();
	NewRow.Description	= NStr("en='Minimum';ru='Минимум';vi='Tối thiểu'");
	NewRow.Operator		= " Min(<?>,<?>)";
	
	NewRow 				= GroupRows.Rows.Add();
	NewRow.Description	= NStr("en='The whole part';ru='Целая часть';vi='Phần nguyên'");
	NewRow.Operator		= " Int(<?>)";
	
	NewRow 				= GroupRows.Rows.Add();
	NewRow.Description	= NStr("en='Rounding';ru='Округление';vi='Làm tròn'");
	NewRow.Operator		= " Round(<?>,<Accuracy?>)";
	
	NewRow 				= GroupRows.Rows.Add();
	NewRow.Description	= NStr("en='Predefined value';ru='Предопределенное значение';vi='Giá trị định trước'");
	NewRow.Operator		= " PredefinedValue(<?>)";
	
	NewRow 				= GroupRows.Rows.Add();
	NewRow.Description	= NStr("en='Value filled';ru='Значение заполнено';vi='Giá trị đã điền'");
	NewRow.Operator		= " ValueIsFilled(<?>)";
	
	GroupRows 				= OperatorsTree.Rows.Add();
	GroupRows.Description	= NStr("en='TEMPLATES';ru='ШАБЛОНЫ';vi='KHUÔN MẪU'");
	GroupRows.Picture		= 1;
	
	NewRow 				= GroupRows.Rows.Add();
	NewRow.Description	= NStr("en='Percentage ""1%""';ru='Процент ""1%""';vi='Tỷ lệ ""1%""'");
	NewRow.Operator		= " %1";
	
	NewRow 				= GroupRows.Rows.Add();
	NewRow.Description	= NStr("en='Percentage ""5%""';ru='Процент ""5%""';vi='5% phần trăm'");
	NewRow.Operator		= " %5";
	
	NewRow 				= GroupRows.Rows.Add();
	NewRow.Description	= NStr("en='Percentage ""20%""';ru='Процент ""20%""';vi='Tỷ lệ ""20%""'");
	NewRow.Operator		= " %20";
	
	NewRow 				= GroupRows.Rows.Add();
	NewRow.Description	= NStr("en='Percentage ""50%""';ru='Процент ""50%""';vi='50 phần trăm'");
	NewRow.Operator		= " %50";
		
	ValueToFormAttribute(OperatorsTree, "Operators");
	
EndProcedure

&AtServer
Procedure CheckFormulaAtServer(Errors)
	
	TypeArray = New Array;
	If SimpleTypes Then
		TypeArray.Add(Type("Number"));
	Else
		TypeArray.Add(TypeRestriction);
	EndIf; 
	TypeDescription = New TypeDescription(TypeArray);
	
	ProductionFormulasServer.CheckFormula(Errors, Formula, TypeDescription, ProductsAndServicesCategory);
	
EndProcedure

&AtServer
Procedure AddMultiplicationInFormula()
	
	// Процедура заменяет "][" на "]*["
	InsertsTable = New ValueTable;
	InsertsTable.Columns.Add("OperandStartPosition");
	InsertsTable.Columns.Add("OperandEndPosition");
	
	OperandBeginning = ProductionFormulasServer.OperandBeginString();
	EndOfOperand = ProductionFormulasServer.OperandEndString();
	
	OperandStartPosition = 0;
	OperandEndPosition = 0;
	
	StringBetween			= "";
	StringLength 		= StrLen(Formula);
	For CharacterIndex = 0 To StringLength Do
		
		Char = Mid(Formula, CharacterIndex, 1);
		If Char = EndOfOperand Then
			
			StringBetween 			= "";
			OperandEndPosition 	= CharacterIndex;
			OperandStartPosition	= 0;
			
		ElsIf Char = OperandBeginning Then
			
			OperandStartPosition	= CharacterIndex;
			
		EndIf;
			
		If OperandEndPosition <> 0 
			And OperandStartPosition = 0
			And Char <> EndOfOperand Then
			
			StringBetween = StringBetween + Char;
			
		ElsIf OperandEndPosition <> 0 
			And OperandStartPosition <> 0 Then
			
			If IsBlankString(TrimAll(StringBetween)) Then
				
				NewRow							= InsertsTable.Add();
				NewRow.OperandStartPosition	= OperandStartPosition;
				NewRow.OperandEndPosition	= OperandEndPosition;
				
			EndIf;
			
			StringBetween				= "";
			OperandStartPosition	= 0;
			OperandEndPosition	= 0;
			
		EndIf;
		
	EndDo;
	
	NumberOfInserts = InsertsTable.Count();
	If NumberOfInserts > 0 Then
		
		While NumberOfInserts <> 0 Do
			
			TableRow = InsertsTable.Get(NumberOfInserts - 1);
			
			FirstSubstring = Left(Formula, TableRow.OperandEndPosition);
			SecondSubstring = Mid(Formula, TableRow.OperandStartPosition);
			
			Formula 		= FirstSubstring + " * " + SecondSubstring;
			
			NumberOfInserts = NumberOfInserts - 1;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FormulaAdditionalProcessing()
	
	AddMultiplicationInFormula();
	
EndProcedure

&AtServer
Procedure FillMappingTable(OpenParameters)
	
	MappingAttributes.Clear();
	Mapping.Clear();
	
	MappingTable = New ValueTable;
	MappingTable.Columns.Add("ProductsAndServices", New TypeDescription("CatalogRef.ProductsAndServices"));
	MappingTable.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ProductsAndServicesCharacteristics"));
	MappingTable.Columns.Add("RulesRowKey", New TypeDescription("Number", New NumberQualifiers(5, 0, AllowedSign.Nonnegative)));
	For Each MappingItem In OpenParameters.Mapping Do
		SearchStructure = New Structure;
		SearchStructure.Insert("Attribute", MappingItem.MappingAttribute);
		Rows = MappingAttributes.FindRows(SearchStructure);
		If Rows.Count()=0 Then
			AttributeName = AttributeNewName();
			MappingTable.Columns.Add(AttributeName);
			AttributeString = MappingAttributes.Add();
			AttributeString.Attribute = MappingItem.MappingAttribute;
			AttributeString.AttributeName = AttributeName;
			FillTypeAttributeCaption(AttributeString.GetID());
		EndIf;
		MappingRow = MappingTable.Find(MappingItem.RulesRowKey, "RulesRowKey");
		If MappingRow=Undefined Then
			MappingRow = MappingTable.Add();
			FillPropertyValues(MappingRow, MappingItem);
			If TSName="Operations" Then
				MappingRow.ProductsAndServices = MappingItem.Operation;
			EndIf; 
		EndIf;
		MappingRow[AttributeName] = MappingItem.ValueOfAttribute;
	EndDo;
	
	If MappingAttributes.Count()=0 Then
		AttributeString = MappingAttributes.Add();
		AttributeString.Attribute = "";
		AttributeString.AttributeName = AttributeNewName();
	EndIf; 
	
	UpdateAttributesOnForm();
	
	For Each MappingRow In MappingTable Do
		NewRow = Mapping.Add();
		FillPropertyValues(NewRow, MappingRow);
	EndDo; 
	
EndProcedure

&AtServer
Procedure UpdateAttributesOnForm(ID = Undefined)
	
	If ID<>Undefined Then
		ChangedRow = MappingAttributes.FindByID(ID);
		LastRow = (MappingAttributes.IndexOf(ChangedRow)=MappingAttributes.Count()-1);
		InsertIndex = MappingAttributes.IndexOf(ChangedRow);
	Else
		ChangedRow = Undefined;
		LastRow = False;
		InsertIndex = 0;
	EndIf; 
	
	AttributesToAdd = New Array;
	For Each AttributeString In MappingAttributes Do
		If ID<>Undefined And AttributeString.GetID()<>ID Then
			Continue;
		EndIf;
		If Not ValueIsFilled(AttributeString.Attribute) Then
			Continue;
		EndIf;
		Attribute = New FormAttribute(
		AttributeString.AttributeName,
		AttributeString.Type,
		"Mapping",
		AttributeString.Title);
		AttributesToAdd.Add(Attribute);
	EndDo;
	
	AttributesToBeRemoved = New Array;
	DeletedItems = New Array;
	For Each Item In Items.MappingGroupAttributes.ChildItems Do
		If TypeOf(Item)<>Type("FormField") Then
			Continue;
		EndIf;
		If ChangedRow<>Undefined And "Column"+ChangedRow.AttributeName<>Item.Name Then
			Continue;
		EndIf; 
		DeletedItems.Add(Item);
		AttributesToBeRemoved.Add(Item.DataPath);
	EndDo;
	For Each Item In Items.GroupMappingAttributes.ChildItems Do
		If TypeOf(Item)<>Type("FormField") Then
			Continue;
		EndIf;
		If ChangedRow<>Undefined And ChangedRow.AttributeName<>Item.Name Then
			Continue;
		EndIf;
		DeletedItems.Add(Item);
	EndDo;
	
	For Each Item In DeletedItems Do
		Items.Delete(Item);
	EndDo;
	
	ChangeAttributes(AttributesToAdd, AttributesToBeRemoved);
	
	For Each AttributeString In MappingAttributes Do
		If ID<>Undefined And AttributeString.GetID()<>ID Then
			Continue;
		EndIf; 
		If ValueIsFilled(AttributeString.Attribute) Then
			If ID=Undefined Or LastRow Then
				Item = Items.Add("Column" + AttributeString.AttributeName, Type("FormField"), Items.MappingGroupAttributes);
			Else
				Item = Items.Insert("Column" + AttributeString.AttributeName, Type("FormField"), Items.MappingGroupAttributes, Items.MappingGroupAttributes.ChildItems[InsertIndex]);
			EndIf; 
			Item.DataPath = "Mapping." + AttributeString.AttributeName;
			Item.Type = FormFieldType.InputField;
			Item.Title = AttributeString.Title;
			If TypeOf(AttributeString.ChoiceParameters)=Type("FixedArray") Then
				Item.ChoiceParameters = AttributeString.ChoiceParameters;
			EndIf; 
		EndIf;
		If ID=Undefined Or LastRow Then
			Item = Items.Add(AttributeString.AttributeName, Type("FormField"), Items.GroupMappingAttributes);
		Else
			Item = Items.Insert(AttributeString.AttributeName, Type("FormField"), Items.GroupMappingAttributes, Items.GroupMappingAttributes.ChildItems[InsertIndex]);
		EndIf;
		FillFilterItemProperties(Item, AttributeString);
	EndDo;
	
	UpdateCleanButtons();
	
EndProcedure

&AtServer
Procedure FillFilterItemProperties(Item, AttributeString)
	
	Item.DataPath = StrTemplate("MappingAttributes[%1].Attribute", MappingAttributes.IndexOf(AttributeString));
	Item.Type = FormFieldType.InputField;
	Item.TitleLocation = FormItemTitleLocation.None;
	Item.AutoMarkIncomplete = True;
	Item.ChoiceButton = True;
	Item.DropListButton = False;
	Item.OpenButton = False;
	Item.ChooseType = False;
	Item.ChoiceButtonRepresentation = ChoiceButtonRepresentation.ShowInInputField;
	Item.ChoiceHistoryOnInput = ChoiceHistoryOnInput.DontUse;
	Item.TextEdit = False;
	Item.SetAction("StartChoice", "Attachable_MappingAttributeBeginSelection");
	Item.SetAction("Clearing", "Attachable_MappingAttributeClear");
	
EndProcedure

&AtServer
Procedure UpdateCleanButtons()
	
	ClearButton = ?(MappingAttributes.Count()<=1, False, True);
	For Each AttributeString In MappingAttributes Do
		Item = Items[AttributeString.AttributeName];
		If TypeOf(Item)<>Type("FormField") Then
			Continue;
		EndIf;
		If Item.ClearButton<>ClearButton Then
			Item.ClearButton = ClearButton;
		EndIf; 
	EndDo; 
 
EndProcedure

&AtServer
Procedure FillTypeAttributeCaption(ID)
	
	AttributeString = MappingAttributes.FindByID(ID);
	If Not ValueIsFilled(AttributeString.Attribute) Then
		AttributeString.Type = New TypeDescription("Undefined");
		Return;
	EndIf; 
	
	AvailableField = Composer.Settings.GroupAvailableFields.FindField(New DataCompositionField(AttributeString.Attribute));
	If AvailableField=Undefined Then
		AttributeString.Type = New TypeDescription("Undefined");
		AttributeString.Title = "";
	Else
		AttributeString.Type = AvailableField.ValueType;
		Position = StrFind(AvailableField.Title, ".", SearchDirection.FromEnd);
		If Position>0 Then
			TitleFields = Mid(AvailableField.Title, Position + 1);
		Else
			TitleFields = AvailableField.Title;
		EndIf; 
		Position = StrFind(TitleFields, "(");
		If Position>0 Then
			TitleFields = Left(TitleFields, Position - 2);	
		EndIf; 
		AttributeString.Title = TitleFields;
		If AvailableField.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues")) Then
			// Требуется определить свойство-владелец значений
			Property = PropertyByName(String(AvailableField.Parent.Field), TitleFields);
			If Property<>Undefined Then
				ChoiceParameters = New Array;
				ChoiceParameters.Add(New ChoiceParameter("Filter.Owner", Property));
				AttributeString.ChoiceParameters = New FixedArray(ChoiceParameters);
			EndIf; 
		EndIf; 
	EndIf; 
	
EndProcedure

&AtServer
Function AttributeNewName()
	
	Return StrTemplate("Attribute%1", StrReplace(String(New UUID), "-", ""));
	
EndFunction

&AtServer
Function PropertyByName(ObjectName, Description)
	
	If IsBlankString(Description) Then
		Return Undefined;
	EndIf; 
	
	SetsArray = New Array;
	If ObjectName="ProductsAndServices" Then
		SetsArray.Add(Catalogs.AdditionalAttributesAndInformationSets.Catalog_ProductsAndServices);
	ElsIf ObjectName="Characteristic" Then
		SetsArray.Add(Catalogs.AdditionalAttributesAndInformationSets.Catalog_ProductsAndServicesCharacteristics);
	ElsIf ObjectName="Specification" Then
		SetsArray.Add(Catalogs.AdditionalAttributesAndInformationSets.Catalog_Specifications);
	ElsIf ObjectName="ProductionOrder" Then
		SetsArray.Add(Catalogs.AdditionalAttributesAndInformationSets.Document_ProductionOrder);
	ElsIf ObjectName="CustomerOrder" Then
		SetsArray.Add(Catalogs.AdditionalAttributesAndInformationSets.Document_CustomerOrder);
	Else
		Return Undefined;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Sets", SetsArray);
	Query.SetParameter("Description", Description);
	Query.Text =
	"SELECT ALLOWED
	|	AdditionalAttributesAndInformation.Ref AS Ref
	|FROM
	|	ChartOfCharacteristicTypes.AdditionalAttributesAndInformation AS AdditionalAttributesAndInformation
	|WHERE
	|	AdditionalAttributesAndInformation.PropertySet IN HIERARCHY (&Sets)
	|	AND AdditionalAttributesAndInformation.Description = &Description";
	Selection = Query.Execute().Select();
	If Selection.Count()<>1 Then
		Return Undefined;
	EndIf;
	Selection.Next();
	Return Selection.Ref;
	
EndFunction

&AtServer
Procedure FillMappingServer()
	
	Query = New Query;
	
	// Формирование текста запроса для выборки всех значений реквизитов сопоставления
	// Связь значений по принципу "все со всеми"
	// Учитываются только реквизиты с ограниченным количеством значений (ссылки, булево)
	PrimitiveType = New TypeDescription("String, Number, Date");
	Subqueries = New Array;
	ReadingAttributes = New Array;
	For Each AttributeString In MappingAttributes Do
		Types = AttributeString.Type.Types();
		ReadingTypes = New Array;
		For Each Type In Types Do
			If PrimitiveType.ContainsType(Type) Then
				Continue;
			EndIf;
			ReadingTypes.Add(Type);
		EndDo;
		CombainedQueries = New Array;
		For Each Type In ReadingTypes Do
			If Type=Type("Boolean") Then
				If CombainedQueries.Count()=0 Then
					SectionPlace = StrTemplate("INTO AllObjects%1", AttributeString.AttributeName);
				Else
					SectionPlace = "";
				EndIf; 
				QueryText = StrTemplate("SELECT TRUE AS Ref %1 ОБЪЕДИНИТЬ ВСЕ ВЫБРАТЬ ЛОЖЬ", SectionPlace);
				CombainedQueries.Add(QueryText);
			ElsIf Enums.AllRefsType().ContainsType(Type) Then
				Ref = New(Type);
				ObjectMetadata = Ref.Metadata();
				For Each Value In ObjectMetadata.EnumValues Do
					If CombainedQueries.Count()=0 Then
						SectionPlace = StrTemplate("INTO AllObjects%1", AttributeString.AttributeName);
					Else
						SectionPlace = "";
					EndIf; 
					QueryText = StrTemplate("SELECT Value(%2.%3) AS Ref %1", SectionPlace, ObjectMetadata.FullName(), Value.Name);
					CombainedQueries.Add(QueryText);
				EndDo; 
			Else
				Ref = New(Type);
				ObjectMetadata = Ref.Metadata();
				If CombainedQueries.Count()=0 Then
					SectionPlace = StrTemplate("INTO AllObjects%1", AttributeString.AttributeName);
				Else
					SectionPlace = "";
				EndIf;
				If TypeOf(AttributeString.ChoiceParameters)=Type("FixedArray") Then
					FilterItemArray = New Array;
					For Each ChoiceParameter In AttributeString.ChoiceParameters Do
						ParameterName = StrTemplate("Parameter%1", Query.Parameters.Count() + 1);
						FilterItemArray.Add(StrTemplate("%1 = &%2", StrReplace(ChoiceParameter.Name, "Filter.", ""), ParameterName));
						Query.SetParameter(ParameterName, ChoiceParameter.Value);
					EndDo; 
					SectionWhere = StrTemplate("WHERE %1", StrConcat(FilterItemArray, " AND "));
				Else
					SectionWhere = "";
				EndIf; 
				QueryText = StrTemplate("SELECT Ref AS Ref %1 ИЗ %2 %3", SectionPlace, ObjectMetadata.FullName(), SectionWhere);
				CombainedQueries.Add(QueryText);
			EndIf;
		EndDo;
		If CombainedQueries.Count()>0 Then
			QueryText = StrConcat(CombainedQueries, Chars.LF + "UNION ALL" + Chars.LF);
			Subqueries.Add(QueryText);
			ReadingAttributes.Add(AttributeString.AttributeName);
		EndIf; 
	EndDo;
	If Subqueries.Count()=0 Then
		TextOfMessage = NStr("en='There are no readable details.';ru='Нет читаемых реквизитов.';vi='Không có mục tin để đọc.'");
		CommonUseClientServer.MessageToUser(TextOfMessage, , "MappingAttributes");
		Return;
	EndIf; 
	QueryText = StrConcat(Subqueries, ";" + Chars.LF);
	SelectionFields = New Array;
	SelectionTables = New Array;
	For Each AttributeName In ReadingAttributes Do
		SelectionFields.Add(StrTemplate("AllObjects%1.Ref AS %1", AttributeName));
		SelectionTables.Add(StrTemplate("AllObjects%1", AttributeName));
	EndDo; 
	FinalRequest = StrTemplate("SELECT TOP 1000 %1 FROM %2",
	StrConcat(SelectionFields, "," + Chars.LF),
	StrConcat(SelectionTables, "," + Chars.LF));
	
	Query.Text = QueryText + ";" + Chars.LF + FinalRequest;
	Selection = Query.Execute().Select();
	If Selection.Count()>=1000 Then
		TextOfMessage = NStr("en='Too much data is available. You may not be able to match "
"only a fraction of the available information will be used for or for comparison. "
"Automatic filling is not possible.';ru='Слишком большой объем получаемых данных. Возможно, неверно настроены сопоставляемые "
"реквизиты или для сопоставления будет использоваться только часть имеющейся информации. "
"Автоматическое заполнение невозможно.';vi='Có quá nhiều dữ liệu được nhận. Có thể là đã tùy chỉnh sai"
"các mục tin được so sánh hoặc chỉ sử dụng một phần"
"thông tin có sẵn để so sánh."
"Không thể điền tự động.'");
		CommonUseClientServer.MessageToUser(TextOfMessage, , "Mapping");
		Return;
	EndIf; 
	
	Mapping.Clear();
	
	LineNumber = 0;
	While Selection.Next() Do
		NewRow = Mapping.Add();
		FillPropertyValues(NewRow, Selection);
		LineNumber = LineNumber + 1;
		NewRow.RulesRowKey = LineNumber;
	EndDo; 
	
EndProcedure

#EndRegion


