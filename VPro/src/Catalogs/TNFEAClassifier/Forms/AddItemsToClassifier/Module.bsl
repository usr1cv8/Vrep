#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(cancel, StandardProcessing)
	
	SetConditionalAppearance();

	CatalogName 			= "TNFEAClassifier";
	
	Items.Classifier.MultipleChoice = True;
	CloseOnChoice = False;
		
	InitializeClassifier();
	
EndProcedure

#EndRegion

#Region ClassifierFormTableEventHandlers

//Вызывается при двойном щелчке мыши или нажатии Enter
//
&AtClient
Procedure ClassifierSelection(Item, SelectedRow, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	NewClassifierItemsAdded = False;
	SelectedItem = ClassifierSelectionAtServer(SelectedRow, NewClassifierItemsAdded);
	If SelectedItem <> Undefined Then
		NotifyFormAndUserAndClose(SelectedItem, NewClassifierItemsAdded);
	EndIf;
	
EndProcedure

//Вызывается при нажатии на кнопку выбрать
//
&AtClient
Procedure ClassifierValueChoice(Item, Value, StandardProcessing)
	
	StandardProcessing = False;
	
	NewClassifierItemsAdded = False;
	SelectedItem = ClassifierSelectionAtServer(Value, NewClassifierItemsAdded);
	If SelectedItem <> Undefined Then
		NotifyFormAndUserAndClose(SelectedItem, NewClassifierItemsAdded);
	EndIf;
	
EndProcedure

//Функция обрабатывает данные выбора пользователя
//
//В случае если выбранные элементы классификатора отсутстуют в справочнике
// они будут добавлены.
//
//Если был осуществлен множественный выбор, то все выбранные элементы будут обработаны
// (добавлены в справочник в случае отсутствия), в возвращаемый параметр, будет передан
// массив ссылок на элементы
//
// Parameters:
// SelectedRows - Массив, массив выбранных строк таблицы формы классификатор
// NewClassifierItemsAdded - Булево, флаг устанавливается 
// 	если в справочник были добавлены элементы
//
// Returns:
// Неопределено или СправочникСсылка: 
// 		ClassifierEconomicActivityKinds 
// 		или  КлассификаторПродукцииПоВидамДеятельности 
//		или КлассификаторУслугНаселению
//
&AtServer
Function ClassifierSelectionAtServer(Val SelectedRows, NewClassifierItemsAdded = False)

	ItemRef = Undefined;
	
	RefArray = New Array();
	
	If TypeOf(SelectedRows) = Type("Array") Then
		
		For Each RowID In SelectedRows Do
			
			Item = Classifier.FindByID(RowID);
			
			If Not ValueIsFilled(Item.Ref) Then
				
				AddClassifierItem(Item);
				NewClassifierItemsAdded = True;
				
			EndIf;
			
			RefArray.Add(Item.Ref);
			ItemRef = Item.Ref;
			
		EndDo;	
		
	ElsIf TypeOf(SelectedRows) = Type("Number") Then	
		
		Item = Classifier.FindByID(SelectedRows);
		
		If Not ValueIsFilled(Item.Ref) Then
			
			AddClassifierItem(Item);
			NewClassifierItemsAdded = True;
			
		EndIf;
		
		RefArray.Add(Item.Ref);
		ItemRef = Item.Ref;
		
	EndIf;

	If Pick Then
		Return RefArray;
	Else	
		Return ItemRef;
	EndIf;
	
EndFunction

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();


	// Классификатор

	CAItem = ConditionalAppearance.Items.Add();

	DataCompositionClientServer.AddAppearanceField(CAItem.Fields, "Classifier");

	CommonUseClientServer.AddCompositionItem(CAItem.Filter,
		"Classifier.HasRef", DataCompositionComparisonType.Equal, True);

	CAItem.Appearance.SetParameterValue("TextColor", StyleColors.FieldSelectionBackColor);

EndProcedure

&AtServer
Function GetPreviouslyAddedItems()
	
	Query = New Query;
	QueryText = "SELECT
	               |	%1.Code,
				   |	%1.Ref
	               |FROM
	               |	Catalog.%1 AS %1";
				   
	MetadataCatalog = Metadata.Catalogs[CatalogName];
	Parameter2Text = "%1.";
	Query.Text = StrReplace(QueryText, "%1", CatalogName);			   
	
	Return Query.Execute().Unload();
	
EndFunction

&AtServer
Function GetClassifierValuesFromTemplate()
	
	IndicatorsTable = Catalogs.TNFEAClassifier.TableOfTNFEAClassifier();
	Return IndicatorsTable;
	
EndFunction

// Заполняет классификатор данными
//
&AtServer
Procedure FillClassifier()
	
	Classifier.Clear();
	
	//Получаем полную таблицу элементов классификатора
	// в таблице содержатся Код и Наименование, элементов классификатора
	ClassifierItemsFromTemplate = GetClassifierValuesFromTemplate();
	
	//Получаем таблицу элементов классификатора уже имеющихся в справочнике
	PreviouslyAddedClassifierItems 	= GetPreviouslyAddedItems();
	PreviouslyAddedClassifierItems.Indexes.Add("Code");
	
	ClassifierItems = ClassifierItemsFromTemplate;
	
	If ClassifierItems.Count() = 0 Then
		Return;
	EndIf;
	
	// Инициализируем структуру которую будем использовать для поиска существующих элементов
	PreviouslyCreatedSearchStructure = New Structure();
	
	For Each Item In ClassifierItems Do
		
		NewRow = Classifier.Add();
		NewRow.Code   = Item.Code;
		
		Description = Item.Description;
		NewRow.Description = Description;
		
		PreviouslyCreatedSearchStructure.Insert("Code",        Item.Code);
		FoundItem = PreviouslyAddedClassifierItems.FindRows(PreviouslyCreatedSearchStructure);
		
		If FoundItem.Count() > 0 Then
			
			NewRow.Ref = FoundItem[0].Ref;
			NewRow.HasRef = True;
			
		EndIf;
		
	EndDo;
		
	Classifier.Sort("HasRef Desc, Code Asc");
		
EndProcedure	

// Добавляет новый элемент в классификатор
// Parameters:
// - ВыбраннаяСтрока - Строка таблицы, источник данных для заполнения реквизитов классификатораъ
// 		Если в строке присутсвуют данные о единице измерения, 
//		запускается поиск и добавление единицы измерения
//
&AtServer
Procedure AddClassifierItem(SelectedRow)
	
	ClassifierItem = Catalogs[CatalogName].CreateItem();
	FillPropertyValues(ClassifierItem, SelectedRow);
	ClassifierItem.DescriptionFull = SelectedRow.Description;
	
	MetadataCatalog = Metadata.Catalogs[CatalogName];
	
	ClassifierItem.Write();
	SelectedRow.Ref = ClassifierItem.Ref;
	
EndProcedure	
	
// Вызывает оповещение об изменении справочника
// вызывает оповещение пользователя
// закрывает форму подбора из классификатора
//
&AtClient
Procedure NotifyFormAndUserAndClose(SelectedItem, NewClassifierItemsAdded = False)
	
	If NewClassifierItemsAdded Then
		
		NotifyChanged(Type("CatalogRef." + CatalogName));	
		
		ShowUserNotification(
			NStr("en='Сохранение';ru='Сохранение';vi='Lưu lại'"),
			,
			ThisForm.Title,
			PictureLib.Information32);
	EndIf;
	
	NotifyChoice(SelectedItem);
	
EndProcedure

&AtServer
Procedure InitializeClassifier()
	
	FillClassifier();
	
EndProcedure

#EndRegion