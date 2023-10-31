
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// СтандартныеПодсистемы.ЗагрузкаДанныхИзВнешнегоИсточника
	DataImportFromExternalSources.OnCreateAtServer(Metadata.Catalogs.ProductsAndServicesCharacteristics, DataLoadSettings, ThisObject);
	// Конец СтандартныеПодсистемы.ЗагрузкаДанныхИзВнешнегоИсточника
	
	If Parameters.Property("Filter") And Parameters.Filter.Property("Owner") Then
		
		OwnerObject = Parameters.Filter.Owner;
		
		If TypeOf(OwnerObject) = Type("CatalogRef.ProductsAndServices") Then
			
			ProductsAndServices = OwnerObject.Ref;
			If ValueIsFilled(ProductsAndServices) Then
				
				AttributeValues = CommonUse.ObjectAttributesValues(ProductsAndServices, "UseCharacteristics, ProductsAndServicesType");
				ProductsAndServicesType = AttributeValues.ProductsAndServicesType;
				UseCharacteristics = AttributeValues.UseCharacteristics;
				
				If Not ProductsAndServicesType = Enums.ProductsAndServicesTypes.InventoryItem
					And Not ProductsAndServicesType = Enums.ProductsAndServicesTypes.Service
					And Not ProductsAndServicesType = Enums.ProductsAndServicesTypes.Work Then
					AutoTitle = False;
					Title = NStr("ru='Характеристики хранятся только для запасов, услуг и работ';en='Characteristics are stored only for inventory, services and work';vi='Chỉ lưu đặc tính vật tư, dịch vụ và công việc'");
				EndIf;
				
			EndIf; 
			
			DataLoadSettings.Insert("CommonValue", ProductsAndServices);
			SetOfAdditAttributes = OwnerObject.ProductsAndServicesCategory.CharacteristicPropertySet;
			
		ElsIf TypeOf(OwnerObject) = Type("CatalogRef.ProductsAndServicesCategories") Then
			
			ProductsAndServicesCategory = OwnerObject.Ref;
			
			DataLoadSettings.Insert("CommonValue", OwnerObject.Ref);
			SetOfAdditAttributes = OwnerObject.CharacteristicPropertySet;
			
			List.QueryText = QueryTextVariants(True);
			List.MainTable = "Catalog.ProductsAndServicesCharacteristics";
			
		Else
			
			Items.ChangeAdditionalAttributesContent.Visible = False;
			
		EndIf;
		
	Else
		
		Items.ChangeAdditionalAttributesContent.Visible = False;
		
	EndIf;
	
	Parameters.Property("HideAttributes", HideAttributes);
	
	ObjectKeyName = StrReplace(ThisObject.FormName,".","");
	
	If (Not ValueIsFilled(ProductsAndServices) And Not ValueIsFilled(ProductsAndServicesCategory))
		Then
		List.QueryText = QueryTextVariants(,True);
		List.MainTable = "Catalog.ProductsAndServicesCharacteristics";
	EndIf;
	
	ProductsAndServicesEditAvailable = AccessRight("Update", Metadata.Catalogs.ProductsAndServices, Users.AuthorizedUser());
	
	SetConditionalAppearance();
	FormManagement(ThisObject);

EndProcedure // ПриСозданииНаСервере()

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	SaveFiltersSettings();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "CharacteristicCopying" And ValueIsFilled(ProductsAndServices) And Parameter=ProductsAndServices Then
		Items.List.Refresh();
	ElsIf EventName = "OrderChanged" Then
		SetDefaultSorting();
	ElsIf EventName = "CharacteristicAdded" And ValueIsFilled(Parameter) Then 
		Items.List.Refresh();
	EndIf;
	
EndProcedure

&AtClient
Procedure FieldUseCharacteristicsOnChange(Item)

	OwnerForm = ThisForm.FormOwner;
	
	If OwnerForm <> Undefined Then 
		OwnerForm.Object.UseCharacteristics = UseCharacteristics;
		OwnerForm.Modified = True;
	EndIf;
	
	LockMenuCommands(Not UseCharacteristics);
	
	
	If ValueIsFilled(ProductsAndServices) Then
		If Not UseCharacteristics And BalancesOfProductsAndServicesWithCharacteristic() Then
			Items.NotificationsGroup.Visible = True;
		Else
			Items.NotificationsGroup.Visible = False;
		EndIf;
	EndIf;
	
	FormManagement(ThisObject);
	Items.List.Refresh();
	Notify("ValueChangeUseCharacteristics",UseCharacteristics);
	
EndProcedure

&AtClient
Procedure ModeOnChange(Item) 
	
	FoundItem = FilterField(List.Filter,"IsCategory");
	
	If FoundItem = Undefined
		Then
		Return;
	EndIf;
	
	NewFilter = FoundItem;
		
	If Mode=0 
		Then
		NewFilter.Use = False;
	ElsIf Mode=1 
		Then
		NewFilter.Use = True;
		NewFilter.RightValue = False;
	ElsIf Mode=2 
		Then
		NewFilter.Use = True;
		NewFilter.RightValue = True;
	EndIf;
	
	Items.List.Refresh();

EndProcedure

&AtClient
Procedure OnOpen(Cancel) 
	
	CorrectFilter();
	
EndProcedure

&AtClient
Procedure ListSelection(Item, SelectedRow, Field, StandardProcessing)
	
	If ValueIsFilled(ProductsAndServices) And Not Items.List.CurrentData.IsCategory
		Then
		StandardProcessing = False;
		
		OpenParameters = New Structure("Key, ReadOnly",SelectedRow, False);
		OpenForm("Catalog.ProductsAndServicesCharacteristics.ObjectForm",OpenParameters,ThisForm);
	ElsIf ValueIsFilled(ProductsAndServicesCategory) 
		Then
		StandardProcessing = False;
		
		OpenParameters = New Structure("Key, ReadOnly",SelectedRow, False);
		OpenForm("Catalog.ProductsAndServicesCharacteristics.ObjectForm",OpenParameters,ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationsGroupMessageURLProcessing(Item, FormattedStringURL, StandardProcessing) 
	
	StandardProcessing = False;
	
	Variant = GetReportVariant("Available balances");
	
	If Not ValueIsFilled(Variant)
		Then
		Return
	EndIf;
	
	DetailsFilter = New Map;
	DetailsFilter.Insert("ProductsAndServices", ProductsAndServices);
	
	OpenParameters = New Structure;
	OpenParameters.Insert("Context", ProductsAndServices);
	OpenParameters.Insert("DetailsFilter", DetailsFilter);
	
	ReportsVariantsClient.OpenReportForm(ThisForm, Variant, OpenParameters);

EndProcedure

#EndRegion

#Region FormItemEventsHandlers

// При клике на Характеристику из списка подключаем вывод картинки.
//
&AtClient
Procedure ListOnActivateRow(Item)
	
	If Item.CurrentData <> Undefined
		Then 
		If ValueIsFilled(ProductsAndServices)
			Then
			If Item.CurrentData.IsCategory Or Not UseCharacteristics
				Then
				LockMenuCommands();
			Else
				LockMenuCommands(False);
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ListBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
	SelectedRows = Items.List.SelectedRows;
	
	If Not SelectedRows.Count() Then
		Return;
	EndIf; 
	
	If SelectedRows.Count()>1
		Then
		QuestionText = NStr("en='Remove/set the selected items to the deletion mark?';ru='Снять / установить выделенным элементам пометку удаления?';vi='Bỏ chọn / đặt các mục đã chọn sẽ bị xóa?'");
	Else	
		TabularSectionRow = Items.List.CurrentData;
		If TabularSectionRow.DeletionMark And Not TabularSectionRow.IsCategory 
			Then	
			QuestionText = NStr("en='Remove the deletion mark from ""%1""?';ru='Снять с ""%1"" пометку удаления?';vi='Bỏ đánh dấu ""%1"" để xóa?'");
		Else
			QuestionText = NStr("en='Mark ""%1"" to delete?';ru='Пометить ""%1"" на удаление?';vi='Đặt dấu xóa ""%1""?'");
		EndIf;
		QuestionText = StrReplace(QuestionText, "%1", TabularSectionRow.ListDescription);
	EndIf;
	
	NotifyDescription = New NotifyDescription("SetMarkForDeletionClient", ThisForm, SelectedRows);
	ShowQueryBox(NotifyDescription, QuestionText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetMarkForDeletionClient(Result, SelectedRows) Export
	
	If Result = DialogReturnCode.No Then
		Return;
	EndIf;
	
	For Each SelectedRow In SelectedRows Do
		
		DeletionMarkNewValue = ChangeDeletionMarkServer(SelectedRow, ValueIsFilled(ProductsAndServices));
		
		ShowUserNotification(
		StrTemplate(NStr("ru='Пометка удаления %1';en='Deletion mark %1';vi='Đặt dấu xóa %1'"), ?(DeletionMarkNewValue, NStr("ru='установлена';en='is set';vi='đã thiết lập'"), NStr("ru='снята';en='is removed';vi='bỏ dấu'"))),
		GetURL(SelectedRow),
		SelectedRow,
		PictureLib.Information32);
	EndDo;
	
	Items.List.Refresh();
	
EndProcedure

&AtServerNoContext
Function ChangeDeletionMarkServer(ReferenceToCharacteristic, ProductsAndServicesFormOwner = False)
	
	If TypeOf(ReferenceToCharacteristic.Owner) = Type("CatalogRef.ProductsAndServicesCategories") 
		And ProductsAndServicesFormOwner	Then
		Return ReferenceToCharacteristic.DeletionMark;
	EndIf;
	
	CharacteristicObject = ReferenceToCharacteristic.GetObject();
	CharacteristicObject.SetDeletionMark(Not CharacteristicObject.DeletionMark, True);
	
	Return CharacteristicObject.DeletionMark;
	
EndFunction

&AtServerNoContext
Procedure ListOnGetDataAtServer(ItemName, Settings, Rows)
	FilterItemsQuantity = Settings.Filter.Items.Count();
	
	If FilterItemsQuantity >2
		Then
		Settings.Filter.Items.Delete(Settings.Filter.Items[0]);
		Settings.Filter.Items.Delete(Settings.Filter.Items[FilterItemsQuantity-2])
	EndIf;
	
EndProcedure

#EndRegion 

#Region FormCommandsHandlers

&AtClient
// Процедура - обработчик события Выполнить команды ИзменитьСоставДополнительныхРеквизитов.
//
Procedure ChangeAdditionalAttributesContent(Command)
	
	If Not ValueIsFilled(SetOfAdditAttributes) Then
		ShowMessageBox(,
			NStr("ru='Не удалось получить наборы дополнительных реквизитов объекта."
""
"Возможно у объекта не заполнены необходимые реквизиты.';en='Failed to receive the additional object attributes."
""
"Perhaps, the necessary attributes have not been filled for the document.';vi='Không thể nhận tập hợp mục tin bổ sung của đối tượng."
""
"Có thể, chưa điền mục tin cần thiết cho đối tượng.'")
		);
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("ShowAdditionalAttributes");
	
	OpenForm("Catalog.AdditionalAttributesAndInformationSets.ListForm", FormParameters);
	
	ParametersOfTransition = New Structure;
	ParametersOfTransition.Insert("Set", SetOfAdditAttributes);
	ParametersOfTransition.Insert("Property", Undefined);
	ParametersOfTransition.Insert("ThisIsAdditionalInformation", False);
	
	Notify("Transition_SetsOfAdditionalDetailsAndInformation", ParametersOfTransition);
	
EndProcedure // ИзменитьСоставДополнительныхРеквизитов()

&AtClient
Procedure CopyFrom(Command)

	OpeningStructure = New Structure;
	OpeningStructure.Insert("ProductsAndServices", ProductsAndServices);
	OpeningStructure.Insert("CopyCharacteristics", True);
	OpeningStructure.Insert("CopyFromSelected", True);
	OpenForm("Catalog.ProductsAndServices.Form.RelatedInformationCopyingForm", OpeningStructure, ThisObject);
	
EndProcedure

&AtClient
Procedure CopyOther(Command)
	
	OpeningStructure = New Structure;
	OpeningStructure.Insert("ProductsAndServices", ProductsAndServices);
	OpeningStructure.Insert("CopyCharacteristics", True);
	OpeningStructure.Insert("CopyFromSelected", False);
	OpenForm("Catalog.ProductsAndServices.Form.RelatedInformationCopyingForm", OpeningStructure, ThisObject);
	
EndProcedure

&AtClient
Procedure ShowInvalid(Command)
	
	Items.ShowInvalid.Check = Not Items.ShowInvalid.Check;
	
	FilterField = New DataCompositionField("NotValid");
	FoundItem = Undefined;
	
	For Each FilterItem In List.Filter.Items Do
		If FilterItem.LeftValue = FilterField
			Then
			FoundItem = FilterItem;
			Break
		EndIf;
	EndDo;
	
	If FoundItem = Undefined
		Then
		Return;
	EndIf;
	
	NewFilter = FoundItem;
	NewFilter.Use = Not NewFilter.Use;
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtClientAtServerNoContext
Procedure FormManagement(Form)
	
	Items = Form.Items;
	
	IsCategory = Not ValueIsFilled(Form.ProductsAndServices);
	
	EditProhibition  = ((Not ValueIsFilled(Form.ProductsAndServices) And Not ValueIsFilled(Form.ProductsAndServicesCategory)) Or Not Form.ProductsAndServicesEditAvailable);
//	If Not Form.ProductsAndServicesType = PredefinedValue("Enum.ProductsAndServicesTypes.InventoryItem")
//		And Not Form.ProductsAndServicesType = PredefinedValue("Enum.ProductsAndServicesTypes.Service")
//		And Not Form.ProductsAndServicesType = PredefinedValue("Enum.ProductsAndServicesTypes.Work") Then
//		ЗапретРедактирования = True;
//	EndIf;
		
	Form.ReadOnly = EditProhibition ;
	
	CommonUseClientServer.SetFormItemProperty(Items, "FormUseAsBasic", 				"Enabled", 		Form.UseCharacteristics And Not EditProhibition  And Not Form.ThisIsSet);
	
	CommonUseClientServer.SetFormItemProperty(Items, "FieldUseCharacteristics", 			"Enabled", 		Not EditProhibition );
	CommonUseClientServer.SetFormItemProperty(Items, "FieldUseCharacteristics", 			"Visible", 		Not Form.HideAttributes);
	
	CommonUseClientServer.SetFormItemProperty(Items, "IsCategory", 								"Visible", 		Not IsCategory);
	CommonUseClientServer.SetFormItemProperty(Items, "Mode", 									"Visible", 		Not EditProhibition  And Not IsCategory);
	CommonUseClientServer.SetFormItemProperty(Items, "GroupCopy", 						"Enabled", 		Form.UseCharacteristics And Not Form.HideAttributes And Not EditProhibition );
	CommonUseClientServer.SetFormItemProperty(Items, "FormDataImportFromExternalSources", 	"Enabled", 		Form.UseCharacteristics And Not Form.HideAttributes And Not EditProhibition );
	
	CommonUseClientServer.SetFormItemProperty(Items, "List", 									"ReadOnly", 	Not Form.UseCharacteristics);
		
EndProcedure

&AtServer
Procedure SaveFiltersSettings()
	
	
EndProcedure

// СтандартныеПодсистемы.ЗагрузкаДанныхИзВнешнегоИсточника
&AtClient
Procedure ShowLoadDataFromExternalSourceWizard()
	
	NotifyDescription = New NotifyDescription("ImportDataFromExternalSourceResultDataProcessor", ThisObject, DataLoadSettings);
	DataImportFromExternalSourcesClient.ShowDataImportFormFromExternalSource(DataLoadSettings, NotifyDescription, ThisObject);
	
EndProcedure

&AtClient
Procedure DataImportFromExternalSources(Command)
	
	If Not ValueIsFilled(DataLoadSettings.CommonValue) Then
		
		TextOfMessage = NStr("en='Not specified characteristic owner';ru='Не указан владелец характеристик';vi='Chủ sở hữu của các đặc tính không được chỉ định'");
		ShowMessageBox(Undefined, TextOfMessage, 15, NStr("en='Import characteristics from an external source';ru='Загрузить характеристики из внешнего источника';vi='Tải đặc tính từ nguồn bên ngoài'"));
		Return;
		
	EndIf;
	
	ShowLoadDataFromExternalSourceWizard();
	
EndProcedure

&AtClient
Procedure ImportDataFromExternalSourceResultDataProcessor(ImportResult, AdditionalParameters) Export
	
	If TypeOf(ImportResult) = Type("Structure") Then
		
		If ImportResult.ActionsDetails = "ChangeDataImportFromExternalSourcesMethod" Then
		
			DataImportFromExternalSources.ChangeDataImportFromExternalSourcesMethod(DataLoadSettings.DataImportFormNameFromExternalSources);
			
			NotifyDescription = New NotifyDescription("ImportDataFromExternalSourceResultDataProcessor", ThisObject, DataLoadSettings);
			DataImportFromExternalSourcesClient.ShowDataImportFormFromExternalSource(DataLoadSettings, NotifyDescription, ThisObject);
			
		ElsIf ImportResult.ActionsDetails = "ProcessPreparedData" Then
			
			ProcessPreparedData(ImportResult, AdditionalParameters);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessPreparedData(ImportResult, AdditionalParameters)
	
	CurrentUser = Users.AuthorizedUser();
	
	For Each TableRow In ImportResult.DataMatchingTable Do
		
		ImportToApplicationIsPossible = TableRow[DataImportFromExternalSources.ServiceFieldNameImportToApplicationPossible()];
		
		CoordinatedStringStatus = (TableRow._СтрокаСопоставлена And ImportResult.DataLoadSettings.UpdateExisting)
			Or (Not TableRow._СтрокаСопоставлена And ImportResult.DataLoadSettings.CreateIfNotMatched);
		
		If ImportToApplicationIsPossible And CoordinatedStringStatus Then
			
			If TableRow._СтрокаСопоставлена Then
				
				CatalogItem = TableRow.Characteristic.GetObject();
				
			Else
				
				CatalogItem = Catalogs.ProductsAndServicesCharacteristics.CreateItem();
				CatalogItem.Owner = ImportResult.DataLoadSettings.CommonValue;
				
				CatalogItem.Description = TableRow.CharacteristicTitle;
				
			EndIf;
			
			If TableRow.ApplyProductsAndServicesPrices Then
				
				RecordDetails = New Structure; 
				RecordDetails.Insert("Period",			CurrentSessionDate());
				RecordDetails.Insert("ProductsAndServices",	CatalogItem.Owner);
				RecordDetails.Insert("Characteristic", CatalogItem.Ref);
				RecordDetails.Insert("Author", 			CurrentUser);
				
				SmallBusinessServer.КопироватьЦеныНоменклатурыВНовуюХарактеристику(RecordDetails);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Items.List.Refresh();
	
EndProcedure
// Конец СтандартныеПодсистемы.ЗагрузкаДанныхИзВнешнегоИсточника

//Устанавливает сортировку харкатеристик в форме списка согласно значением заданным в категории номенклатуры
//
Procedure SetDefaultSorting(ProductsAndServicesCategoryFilter = Undefined)
	
	If ProductsAndServicesCategoryFilter = Undefined
		Then
		//Если есть пользовательская настройка
		For Each SettingItem In List.SettingsComposer.UserSettings.Items Do
			If TypeOf(SettingItem) = Type("DataCompositionOrder") And ValueIsFilled(SettingItem)
				Then
				SettingItem.Items.Clear();
			EndIf
		EndDo;
		
		ProductsAndServicesCategoryFilter = GetProductsAndServicesCategory();
	EndIf;
	
	If ValueIsFilled(ProductsAndServicesCategoryFilter)
		Then
		
		List.Order.Items.Clear();
		
		If ProductsAndServicesCategoryFilter.SortingOrder.Count()
			Then
			For Each RowSortingOrder In ProductsAndServicesCategoryFilter.SortingOrder Do
				OrderingItem = List.Order.Items.Add(Type("DataCompositionOrderItem"));
				OrderingItem.Use = True;
				OrderingItem.Field = New DataCompositionField("Ref." + String(RowSortingOrder.Property));
				OrderingItem.OrderType = DataCompositionSortDirection.Asc;
				OrderingItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
			EndDo;
		Else
			OrderingItem = List.Order.Items.Add(Type("DataCompositionOrderItem"));
			OrderingItem.Use = True;
			OrderingItem.Field = New DataCompositionField("Description");
			OrderingItem.OrderType = DataCompositionSortDirection.Asc;
			OrderingItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
		EndIf;
	EndIf;
	
EndProcedure

//Устанавливает двух владельцев(номенклатуру и категорию) в отбор динамического списка
//
&AtServer
Procedure CorrectFilter()
	
	If ValueIsFilled(ProductsAndServices)
		Then
		ThisForm.List.Filter.Items.Clear();
		
		ProductsAndServicesCategoryFilter = GetProductsAndServicesCategory();
		
		FilterByOwnerList = New ValueList;
		FilterByOwnerList.Add(ProductsAndServices);
		
		If ValueIsFilled(ProductsAndServicesCategoryFilter)
			Then
			FilterByOwnerList.Add(ProductsAndServicesCategoryFilter); 
			SetDefaultSorting(ProductsAndServicesCategoryFilter);
		EndIf;
		
//		List.Parameters.SetParameterValue("СписокВладельцев",СписокОтбораПоВладельцу);
//		List.Parameters.SetParameterValue("OwnerProductsAndServices",ProductsAndServices);
		
		FilterField = New DataCompositionField("Owner");
		
		NewFilter = List.Filter.Items.Add(Type("DataCompositionFilterItem"));
		NewFilter.LeftValue = FilterField;
		NewFilter.ComparisonType = DataCompositionComparisonType.InList;
		NewFilter.RightValue = FilterByOwnerList;
		
		FilterField = New DataCompositionField("IsCategory");
		
		NewFilter = List.Filter.Items.Add(Type("DataCompositionFilterItem"));
		NewFilter.Use = False;
		NewFilter.LeftValue = FilterField;
		NewFilter.ComparisonType = DataCompositionComparisonType.Equal;
		
	EndIf;
	
	FilterField = New DataCompositionField("NotValid");
	
	NewFilter = List.Filter.Items.Add(Type("DataCompositionFilterItem"));
	NewFilter.Use = True;
	NewFilter.LeftValue = FilterField;
	NewFilter.RightValue = False;
	NewFilter.ComparisonType = DataCompositionComparisonType.Equal;
	
	
EndProcedure

//Устанавливает текст запроса динамического списка для категорий или для общей формы списка
//
&AtServer
Function QueryTextVariants(QueryForCategory = False, CommonQuery = False)
	
	If QueryForCategory
		Then
		QueryText = 
		"SELECT ALLOWED
		|	ProductsAndServicesCharacteristicsOverridable.Ref AS Ref,
		|	ProductsAndServicesCharacteristicsOverridable.DataVersion AS DataVersion,
		|	ProductsAndServicesCharacteristicsOverridable.DeletionMark AS DeletionMark,
		|	ProductsAndServicesCharacteristicsOverridable.Owner AS Owner,
		|	ProductsAndServicesCharacteristicsOverridable.Code AS Code,
		|	CASE
		|		WHEN VALUETYPE(ProductsAndServicesCharacteristicsOverridable.Owner) = TYPE(Catalog.ProductsAndServicesCategories)
		|			THEN ProductsAndServicesCharacteristicsOverridable.Description
		|		ELSE ProductsAndServicesCharacteristicsOverridable.Description
		|	END AS Description,
		|	ProductsAndServicesCharacteristicsOverridable.Predefined AS Predefined,
		|	ProductsAndServicesCharacteristicsOverridable.PredefinedDataName AS PredefinedDataName,
		|	ProductsAndServicesCharacteristicsOverridable.Presentation AS Presentation,
		|	FALSE AS Default,
		|	FALSE AS IsCategory,
		|	ProductsAndServicesCharacteristicsOverridable.NotValid AS NotValid,
		|	CASE
		|		WHEN AttachedFilesExist.HasFiles IS NULL
		|			THEN 0
		|		WHEN AttachedFilesExist.HasFiles
		|			THEN 1
		|		ELSE 0
		|	END AS HasFiles
		|FROM
		|	Catalog.ProductsAndServicesCharacteristics AS ProductsAndServicesCharacteristicsOverridable
		|		{LEFT JOIN InformationRegister.AttachedFilesExist AS AttachedFilesExist
		|		ON ProductsAndServicesCharacteristicsOverridable.Ref = AttachedFilesExist.ObjectWithFiles}";
	ElsIf CommonQuery
		Then
		QueryText = 
		"SELECT ALLOWED
		|	ProductsAndServicesCharacteristicsOverridable.Ref AS Ref,
		|	ProductsAndServicesCharacteristicsOverridable.DeletionMark AS DeletionMark,
		|	ProductsAndServicesCharacteristicsOverridable.Owner AS Owner,
		|	ProductsAndServicesCharacteristicsOverridable.Code AS Code,
		|	ProductsAndServicesCharacteristicsOverridable.Description AS Description,
		|	ProductsAndServicesCharacteristicsOverridable.NotValid AS NotValid,
		|	ProductsAndServicesCharacteristicsOverridable.AdditionalAttributes.(
		|		Ref AS Ref,
		|		LineNumber AS LineNumber,
		|		Property AS Property,
		|		Value AS Value,
		|		TextString AS TextString
		|	) AS AdditionalAttributes,
		|	ProductsAndServicesCharacteristicsOverridable.Predefined AS Predefined,
		|	ProductsAndServicesCharacteristicsOverridable.PredefinedDataName AS PredefinedDataName,
		|	CASE
		|		WHEN AttachedFilesExist.HasFiles IS NULL
		|			THEN 0
		|		WHEN AttachedFilesExist.HasFiles
		|			THEN 1
		|		ELSE 0
		|	END AS HasFiles
		|FROM
		|	Catalog.ProductsAndServicesCharacteristics AS ProductsAndServicesCharacteristicsOverridable
		|		{LEFT JOIN InformationRegister.AttachedFilesExist AS AttachedFilesExist
		|		ON ProductsAndServicesCharacteristicsOverridable.Ref = AttachedFilesExist.ObjectWithFiles}";
	Else
		QueryText = "";
	EndIf;
	
	Return QueryText;
	
EndFunction

//Получает категорию для текущей номенклатуры
//
&AtServer
Function GetProductsAndServicesCategory()
	
	Query = New Query;
	
	Query.SetParameter("ProductsAndServices", ProductsAndServices);
	
	Query.Text =
	"SELECT
	|	ProductsAndServices.ProductsAndServicesCategory AS ProductsAndServicesCategory
	|FROM
	|	Catalog.ProductsAndServices AS ProductsAndServices
	|WHERE
	|	ProductsAndServices.Ref = &ProductsAndServices";
	
	QueryResult = Query.Execute().Select();
	QueryResult.Next();
	
	Return QueryResult.ProductsAndServicesCategory;
	
	
EndFunction

//Устанавливает условное оформление формы для недействительных характеристик
//
&AtServer
Procedure SetConditionalAppearance()
	
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "List.NotValid", True, DataCompositionComparisonType.Equal);
	WorkWithForm.AddConditionalAppearanceFields(NewConditionalAppearance, "ListDescription");
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.UnavailableCellTextColor); 

EndProcedure

// Возвращает Истину, если по номенклатуре есть остатки в разрезе характеристик.
//
&AtServer
Function BalancesOfProductsAndServicesWithCharacteristic()
	
	Query = New Query;
	
	Query.SetParameter("ProductsAndServices", ProductsAndServices);
	
	Query.Text = 
	"SELECT
	|	InventoryBalance.ProductsAndServices AS ProductsAndServices
	|FROM
	|	AccumulationRegister.Inventory.Balance(
	|			,
	|			ProductsAndServices = &ProductsAndServices
	|				AND NOT Characteristic = VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)) AS InventoryBalance";
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

//Получает значение характеристики по умолчанию для категории номенклатуры
//
&AtServer
Function GetDefaultValueForProductsAndServicesCategory() 
	
	If Not ValueIsFilled(ProductsAndServices) Or Not ValueIsFilled(ProductsAndServices.ProductsAndServicesCategory)
		Then
		Return Undefined
	EndIf;
	
	Query = New Query;
	Query.SetParameter("ProductsAndServicesCategory",ProductsAndServices.ProductsAndServicesCategory);
	
	Query.Text =
	"SELECT
	|	ЗначенияНоменклатурыПоУмолчанию.Characteristic AS Characteristic
	|FROM
	|	InformationRegister.ЗначенияНоменклатурыПоУмолчанию AS ЗначенияНоменклатурыПоУмолчанию
	|WHERE
	|	ЗначенияНоменклатурыПоУмолчанию.ProductsAndServices = &ProductsAndServicesCategory
	|	AND NOT ЗначенияНоменклатурыПоУмолчанию.Characteristic = VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)";
	
	Selection = Query.Execute().Select();
	
	If Selection.Next()
		Then
		Return Selection.Characteristic;
	Else
		Return Undefined;
	EndIf; 
	
EndFunction

//Получает вариант отчета по наименованию
//
&AtServer
Function GetReportVariant(VariantName)
	Return Catalogs.ReportsVariants.FindByDescription(VariantName);
EndFunction

//Блокирует доступность элементов командного и контекстного меню в зависимости от условия
//
&AtClient
Procedure LockMenuCommands(AvailabilityMark = True)

	CommonUseClientServer.SetFormItemProperty(Items, "ListContextMenuButtonChange", "Enabled", Not AvailabilityMark);
	CommonUseClientServer.SetFormItemProperty(Items, "ListContextMenuButtonAdd", "Enabled", UseCharacteristics);
	CommonUseClientServer.SetFormItemProperty(Items, "ListContextMenuButtonCopy", "Enabled", Not AvailabilityMark);
	CommonUseClientServer.SetFormItemProperty(Items, "ListContextMenuButtonMarkForDeletion", "Enabled", Not AvailabilityMark);
	CommonUseClientServer.SetFormItemProperty(Items, "FormCopy", "Enabled", Not AvailabilityMark);
	CommonUseClientServer.SetFormItemProperty(Items, "FormChange", "Enabled", Not AvailabilityMark);
	CommonUseClientServer.SetFormItemProperty(Items, "FormSetDeletionMark", "Enabled", Not AvailabilityMark);
	
EndProcedure

//Возвращает количество характеристик по владельцу 
//
&AtServer
Function CharacteristicsQuantity(OwnerCharacteristics, ProductsAndServicesCategory = Undefined)
	
	Query = New Query;
	
	Query.SetParameter("Owner", OwnerCharacteristics);
	
	Query.Text = "SELECT ALLOWED DISTINCT
	|	ProductsAndServicesCharacteristics.Ref AS Ref
	|FROM
	|	Catalog.ProductsAndServicesCharacteristics AS ProductsAndServicesCharacteristics
	|WHERE
	|	ProductsAndServicesCharacteristics.Owner = &Owner";
	
	Result = Query.Execute().Select();
	
	QuantityByOwner = Result.Count();
	
	QuantityByCategory = 0;
	
	If Not ProductsAndServicesCategory = Undefined
		Then	
		Query = New Query;
		
		Query.SetParameter("Owner", ProductsAndServicesCategory);
		
		Query.Text = "SELECT ALLOWED DISTINCT
		|	ProductsAndServicesCharacteristics.Ref AS Ref
		|FROM
		|	Catalog.ProductsAndServicesCharacteristics AS ProductsAndServicesCharacteristics
		|WHERE
		|	ProductsAndServicesCharacteristics.Owner = &Owner";
		
		Result = Query.Execute().Select();
		
		QuantityByCategory = Result.Count();
	EndIf;	
	
	Return QuantityByOwner + QuantityByCategory;
	
EndFunction

//Находит поле отбора в динамическом списке
//
&AtClientAtServerNoContext
Function FilterField(FilterItemGroup, FieldDataPath)
	
	Field = New DataCompositionField(FieldDataPath);
	
	For Each FilterItem In FilterItemGroup.Items Do
		If FilterItem.LeftValue=Field Then
			Return	FilterItem;
		EndIf; 
	EndDo; 
	
	Return Undefined;
	
EndFunction
#EndRegion
