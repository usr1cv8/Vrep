////////////////////////////////////////////////////////////////////////////////
// Серверные процедуры и функции для копирования и вставки 
// строк табличных частей
//
////////////////////////////////////////////////////////////////////////////////

#Region ProgramInterface

// Устанавливает доступность кнопки вставки скопированных строк в зависимости от заполненности буфера обмена.
//
// Parameters:
//  Controls - FormAllItems - Элементы формы, на которой расположены кнопки копирования и вставки строк.
//  TSName         - String - Имя таблицы формы, в которой буду производиться встака/копирование строк.
Procedure OnCreateAtServer(Controls, TSName) Export
	
	HasCopiedRows = CommonSettingsStorage.Load("ClipboardTabularSections", "Rows") <> Undefined;
	
	If TypeOf(TSName) = Type("Array") Then
		For Each Item In TSName Do
			SetButtonsVisibility(Controls, Item, HasCopiedRows);
		EndDo;
	Else
		SetButtonsVisibility(Controls, TSName, HasCopiedRows);
	EndIf;
	
EndProcedure

// Копирует выделенные строки табличной части в буфер обмена.
//
// Parameters:
//  TabSec                      - FormDataCollection - Табличная часть, в которой происходит копирование строк.
//  SelectedRows        - Array - Массив идентификаторов выделенных строк табличной части.
//  NumberOfCopied - Number - Получит значение количества скопированных строк.
Procedure Copy(TabSec, SelectedRows, NumberOfCopied) Export
	
	CopiedRows = TabSec.Unload();
	
	Iterator = TabSec.Count() - 1;
	While Iterator >= 0 Do
		ID = TabSec[Iterator].GetID();
		If SelectedRows.Find(ID) = Undefined Then
			CopiedRows.Delete(Iterator);
		EndIf;
		
		Iterator = Iterator - 1;
	EndDo;
	
	CommonSettingsStorage.Save("ClipboardTabularSections", "Rows", CopiedRows);
	NumberOfCopied = CopiedRows.Count();
	
EndProcedure

// Вставляет строки табличной части из буфер обмена в табличную часть.
//
// Parameters:
//  Object - FormDataStructure - Данные объекта, в котором расположена табличная часть.
//  TSName  - String - Имя таблицы формы, в которой буду производиться встака/копирование строк.
//  Controls           - FormAllItems - Элементы формы, на которой расположена табличная часть.
//  NumberOfCopied - Number - Получит значение количества строк, находящихся в буфере обмена.
//  NumberOfInserted   - Number - Получит значение количества вставленных строк.
Procedure Insert(Object, TSName, Controls, NumberOfCopied, NumberOfInserted) Export
	
	If TypeOf(TSName) = Type("Structure") Then
		ItemName = TSName.TagName;
		TSName = TSName.TSName;
	Else
		ItemName = TSName;
	EndIf;
	
	TabSec = Object[TSName];
	TSMetadata = Object.Ref.Metadata().TabularSections[TSName];
	
	SelectedRows = Controls[ItemName].SelectedRows;
	SelectedRows.Clear();
	
	AddingRows = CommonSettingsStorage.Load("ClipboardTabularSections", "Rows");
	If AddingRows = Undefined Then
		Return;
	EndIf;
	NumberOfCopied = AddingRows.Count();
	
	ExcludingColumns = "";
	
	For Each TSAttribute In TSMetadata.Attributes Do
		
		If AddingRows.Columns.Find(TSAttribute.Name) = Undefined Then
			If ValueIsFilled(ExcludingColumns) Then
				ExcludingColumns = ExcludingColumns + ",";
			EndIf;
			ExcludingColumns = ExcludingColumns + TSAttribute.Name;
			Continue;
		EndIf;
		
		FunctionalOption = Undefined;
		AttributeAvailable = CheckObjectAvailability(TSAttribute, FunctionalOption);
		If Not AttributeAvailable Then
			Continue;
		EndIf;
		
		If TSAttribute.Type.ContainsType(Type("Boolean")) Then
			Continue;
		EndIf;
		
		ValueIterator = 0;
		ConditionParameters = New Structure;
		AllowedValues = New Array;
		
		If Controls.Find(ItemName + TSAttribute.Name) <> Undefined Then
			ChoiceParameters = Controls[ItemName + TSAttribute.Name].ChoiceParameters;
		Else
			ChoiceParameters = TSAttribute.ChoiceParameters;
		EndIf;
		
		For Each ChoiceParameter In ChoiceParameters Do
			
			If StrFind(ChoiceParameter.Name, "Filter.") <> 1 Then
				Continue;
			EndIf;
			
			AttributePresentation = Right(ChoiceParameter.Name, StrLen(ChoiceParameter.Name) - StrLen("Filter."));
			ChoiceParameterPresentation = "Parameters.Row." + TSAttribute.Name + "." + AttributePresentation;
			
			AttributeCondition = "";
			
			If TypeOf(ChoiceParameter.Value) = Type("FixedArray") Or TypeOf(ChoiceParameter.Value) = Type("Array") Then
				For Each ValueOfAttribute In ChoiceParameter.Value Do
					
					If ValueIsFilled(AttributeCondition) Then
						AttributeCondition = AttributeCondition + "OR "
					EndIf;
					
					AllowedValues.Add(ValueOfAttribute);
					AttributeCondition = AttributeCondition + ChoiceParameterPresentation + "=Parameters.AllowedValues[" + ValueIterator + "] ";
					ValueIterator = ValueIterator + 1;
					
				EndDo;
			Else
				AllowedValues.Add(ChoiceParameter.Value);
				AttributeCondition = AttributeCondition + ChoiceParameterPresentation + "=Parameters.AllowedValues[" + ValueIterator + "] ";
				ValueIterator = ValueIterator + 1;
			EndIf;
			
			AttributeConditionByTypeAnd = "";
			AttributeConditionByTypeOR = "";
			TypesAttribute = TSAttribute.Type.Types();
			If TypesAttribute.Count() > 1 Then
				
				For Each Type In TypesAttribute Do
					
					MetadataObjectByType = Metadata.FindByType(Type);
					If MetadataObjectByType = Undefined Then
						
						If ValueIsFilled(AttributeConditionByTypeOR) Then
							AttributeConditionByTypeOR = AttributeConditionByTypeOR + " OR ";
						EndIf;
						
						AllowedValues.Add(Type);
						AttributeConditionByTypeOR = AttributeConditionByTypeOR + "TypeOf(Parameters.Row." + TSAttribute.Name + ")" + "=Parameters.AllowedValues[" + ValueIterator + "] ";
						ValueIterator = ValueIterator + 1;
						
					ElsIf CommonUse.ThisIsCatalog(MetadataObjectByType)
						Or CommonUse.ThisIsDocument(MetadataObjectByType) Then
						
						If MetadataObjectByType.Attributes.Find(AttributePresentation) = Undefined Then
							
							If ValueIsFilled(AttributeConditionByTypeOR) Then
								AttributeConditionByTypeOR = AttributeConditionByTypeOR + " OR ";
							EndIf;
							
							AllowedValues.Add(Type);
							AttributeConditionByTypeOR = AttributeConditionByTypeOR + "TypeOf(Parameters.Row." + TSAttribute.Name + ")" + "=Parameters.AllowedValues[" + ValueIterator + "] ";
							ValueIterator = ValueIterator + 1;
							
						Else
							
							If ValueIsFilled(AttributeConditionByTypeAnd) Then
								AttributeConditionByTypeAnd = AttributeConditionByTypeAnd + " OR ";
							Else
								AttributeConditionByTypeAnd = AttributeConditionByTypeAnd + "(";
							EndIf;
							
							AllowedValues.Add(Type);
							AttributeConditionByTypeAnd = AttributeConditionByTypeAnd + "TypeOf(Parameters.Row." + TSAttribute.Name + ")" + "=Parameters.AllowedValues[" + ValueIterator + "] ";
							ValueIterator = ValueIterator + 1;
							
						EndIf;
						
					EndIf;
					
				EndDo;
				
				AttributeConditionByTypeAnd = AttributeConditionByTypeAnd + ")";
				
				AttributeCondition = StrTemplate(
					"(%1 AND (%2))%3",
					AttributeConditionByTypeAnd,
					AttributeCondition,
					?(ValueIsFilled(AttributeConditionByTypeOR), " OR " + AttributeConditionByTypeOR, "")
				);
				
			EndIf;
			
			ConditionParameters.Insert("AllowedValues", AllowedValues);
			AddingRows = FindByCondition(AddingRows, TSAttribute.Name, AttributeCondition, TSAttribute.Type, ConditionParameters);
			
		EndDo;
		
	EndDo;
	
	ColumnsNotCopied = "SerialNumbers, SerialNumbersReceivedPosting, ConnectionKey, ConnectionKeySerialNumbers";
	
	NewRow = Undefined;
	For Each Row In AddingRows Do
		
		NewRow = TabSec.Add();
		
		ExcludingNewColumns = "";
		
		For Each Column In TSMetadata.Attributes Do
			If StrFind(ExcludingColumns, Column.Name) <> 0 Then
				Continue;
			EndIf;
			
			If StrFind(ColumnsNotCopied, Column.Name) <> 0 Then
				ExcludingNewColumns = ExcludingNewColumns + "," + Column.Name;
				Continue;
			EndIf;
			
			If Not Column.Type.ContainsType(TypeOf(Row[Column.Name])) Then
				ExcludingNewColumns = ExcludingNewColumns + "," + Column.Name;
			EndIf;
		EndDo;
		
		FillPropertyValues(NewRow, Row, , ExcludingNewColumns);
		
		SelectedRows.Add(NewRow.GetID());
		
	EndDo;
	
	NumberOfInserted = AddingRows.Count();
	
	If NewRow <> Undefined Then
		Controls[ItemName].CurrentRow = NewRow.GetID();
	EndIf;
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

// Осуществляет поиск строк таблицы значений, отвечающих заданныму условию одного реквизита таблицы.
//
// Parameters:
//  VT                 - ТаблицаЗначний - Таблица значений, в которой необходимо произвести отбор строк.
//  FilterAttribute     - String - Имя реквизита.
//  Condition - String   - Логическое выражение.
//  ValidTypes     - TypeDescription - Тип реквизита приемника.
//  ДопустимыеЗначения - Массив - Массив значений, которые может принимать указанный реквизит.
//                                Если реквизит
// Returns:
//  ValueTable - Таблица значений, содержащая строки, отвечающие заданному условию.
Function FindByCondition(VT, FilterAttribute, Condition, ValidTypes, Parameters)
	
	NewTK = VT.CopyColumns();
	
	For Each Row In VT Do
		
		Parameters.Insert("Row", Row);
		
		SuitableString = False;
		
		If Not ValueIsFilled(Row[FilterAttribute]) Then
			SuitableString = True;
		ElsIf ValidTypes.ContainsType(TypeOf(Row[FilterAttribute])) Then
			SuitableString = CommonUse.EvalInSafeMode(Condition, Parameters);
		EndIf;
		
		If SuitableString Then
			NewRow = NewTK.Add();
			FillPropertyValues(NewRow, Row);
		EndIf;
		
	EndDo;
	
	Return NewTK;
	
EndFunction

// Устанавливает доступность кнопок вставки и копирования строк в табличную часть.
Procedure SetButtonsVisibility(Controls, TSName, HasCopiedRows)
	
	Controls[TSName + "CopyRows"].Enabled = True;
	
	If HasCopiedRows Then
		Controls[TSName + "InsertRows"].Enabled = True;
	Else
		Controls[TSName + "InsertRows"].Enabled = False;
	EndIf;
	
EndProcedure

// Проверяет, входит ли реквизит в состав одной из функциональных опций и возвращает ее значение.
Function CheckObjectAvailability(Object, FunctionalOption)
	
	For Each FunctionalOption In Metadata.FunctionalOptions Do
		
		ContentItem = FunctionalOption.Content.Find(Object);
		If ContentItem <> Undefined Then
			Break;
		EndIf;
		
	EndDo;
	
	If ContentItem <> Undefined Then
		Return GetFunctionalOption(FunctionalOption.Name);
	EndIf;
	
	FunctionalOption = Undefined;
	Return True;
	
EndFunction

#EndRegion




