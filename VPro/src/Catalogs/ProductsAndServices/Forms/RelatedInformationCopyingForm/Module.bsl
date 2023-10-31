
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	LoadTooltipDisplaySettings();
	
	Parameters.Property("ProductsAndServices", ProductsAndServices);
	AttributeValues = CommonUse.ObjectAttributesValues(ProductsAndServices, "ProductsAndServicesCategory, ProductsAndServicesType, UseCharacteristics");
	FillPropertyValues(ThisObject, AttributeValues);
	
	If Parameters.Property("CopyUnitsOfMeasurement", CopyUnitsOfMeasurement)
		Or Parameters.Property("CopyCharacteristics", CopyCharacteristics)
		Or Parameters.Property("CopySpecifications", CopySpecifications)
		Or Parameters.Property("CopySetsContent", CopySetsContent) Then
		ObjectsByString = "";
		If CopyUnitsOfMeasurement Then
			ObjectsByString = ObjectsByString + ?(IsBlankString(ObjectsByString), "", ", ") + NStr("en='units';ru='единиц измерения';vi='đơn vị đo'");
		EndIf; 
		If CopyCharacteristics Then
			ObjectsByString = ObjectsByString + ?(IsBlankString(ObjectsByString), "", ", ") + NStr("en='Characteristics';ru='характеристик';vi='Đặc tính '");
		EndIf; 
		If CopySpecifications Then
			ObjectsByString = ObjectsByString + ?(IsBlankString(ObjectsByString), "", ", ") + NStr("en='specifications';ru='спецификаций';vi='bảng kê chi tiết'");
		EndIf; 
		If CopySetsContent Then
			ObjectsByString = ObjectsByString + ?(IsBlankString(ObjectsByString), "", ", ") + NStr("en='set-up';ru='состава наборов';vi='thành phần tập hợp'");
		EndIf; 
		Title = StrTemplate(NStr("en='Copy %1';ru='Копирование %1';vi='Sao chép %1'"), ObjectsByString);
	EndIf;
	
	If Not Parameters.Property("CopyFromSelected", CopyFromSelected) Then
		IdentifyMode();
	EndIf; 
	ModeSetting();
	If Not CopyFromSelected Then
		If Parameters.Property("SelectedValues") And TypeOf(Parameters.SelectedValues)=Type("Array") Then
			SelectedValues = Parameters.SelectedValues;
		Else
			SelectedValues = New Array;
		EndIf; 
		UpdateCopyingList(SelectedValues);
		If Values.Count()=0 Then
			Cancel = True;
			Return;
		EndIf; 
	EndIf; 
	
	FormManagement(ThisObject);
	
	If CopyFromSelected Then
		Items.Copy.Title = NStr("ru='Скопировать и закрыть';en='Copy and close';vi='Sao chép và đóng'");
	EndIf; 
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	
	If TypeOf(SelectedValue)<>Type("CatalogRef.ProductsAndServices") Or Not ValueIsFilled(SelectedValue) Then
		Return;
	EndIf;
	FilterStructure = New Structure;
	FilterStructure.Insert("Value", SelectedValue);
	If SelectedObjects.FindRows(FilterStructure).Count()>0 Then
		Return;
	EndIf;
	
	NewRow = SelectedObjects.Add();
	NewRow.Value = SelectedValue;
	NewRow.Check = True;
	If CopyFromSelected Then
		UpdateCopyingList();	
	EndIf; 
	
EndProcedure

#EndRegion 

#Region FormItemEventsHandlers

&AtClient
Procedure SelectedObjectsValueOnChange(Item)
	
	UpdateCopyingList();	
	
EndProcedure

&AtClient
Procedure SelectedObjectsOnStartEdit(Item, NewRow, Copy)
	
	If NewRow And Not CopyFromSelected Then
		CurRow = Items.SelectedObjects.CurrentData;
		CurRow.Check = True;
	EndIf; 
	
EndProcedure

&AtClient
Procedure SelectedObjectsSelection(Item, SelectedRow, Field, StandardProcessing)
	
	If Field.Name="SelectedObjectsMessage" Then
		StandardProcessing = False;
		TabularSectionRow = SelectedObjects.FindByID(SelectedRow);
		If CopyUnitsOfMeasurement Then
			OpenParameters = New Structure;
			OpenParameters.Insert("Filter", New Structure);
			OpenParameters.Filter.Insert("Owner", TabularSectionRow.Value);
			OpenForm("Catalog.Uom.ListForm", OpenParameters, ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
		ElsIf CopyCharacteristics Then
			OpenParameters = New Structure;
			OpenParameters.Insert("HideAttributes", True);
			OpenParameters.Insert("Filter", New Structure);
			OpenParameters.Filter.Insert("Owner", TabularSectionRow.Value);
			OpenForm("Catalog.ProductsAndServicesCharacteristics.ListForm", OpenParameters, ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
		ElsIf CopySpecifications Then
			OpenParameters = New Structure;
			OpenParameters.Insert("Filter", New Structure);
			OpenParameters.Filter.Insert("Owner", TabularSectionRow.Value);
			OpenForm("Catalog.Specifications.ListForm", OpenParameters, ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
		EndIf; 
	EndIf; 
	
EndProcedure

&AtClient
Procedure SelectedObjectsAfterDeleteRow(Item)
	
	UpdateCopyingList();	
	
EndProcedure

&AtClient
Procedure DecorationCloseWarningClick(Item)
	
	// Закрытие подсказки
	If CurrentTooltip="AddingCharacteristics" Then
		SetProperty(TooltipDisplaySettings, "HideCharacteristicAddingTooltip", True);
		SaveTooltipDisplaySettings();
	ElsIf CurrentTooltip="CharacteristicsAbsence" Then
		SetProperty(TooltipDisplaySettings, "HideCharacteristicAbsenceTooltip", True);
		SaveTooltipDisplaySettings();
	EndIf;
	CurrentTooltip = "";
	Items.Warning.Visible = False;
	
EndProcedure

#EndRegion 

#Region FormCommandsHandlers

&AtClient
Procedure SelectAll(Command)
	
	For Each TabularSectionRow In Values Do
		TabularSectionRow.Check = True;
	EndDo; 	
	
EndProcedure

&AtClient
Procedure UncheckAll(Command)
	
	For Each TabularSectionRow In Values Do
		TabularSectionRow.Check = False;
	EndDo; 	
	
EndProcedure

&AtClient
Procedure Pick(Command)
	
	FilterStructure = New Structure;
	For Each ChoiceParameter In Items.SelectedObjectsValue.ChoiceParameters Do
		AttributeName = StrReplace(ChoiceParameter.Name, "Filter.", "");
		FilterValue = ?(TypeOf(ChoiceParameter.Value)=Type("FixedArray"), New Array(ChoiceParameter.Value), ChoiceParameter.Value);
		FilterStructure.Insert(AttributeName, FilterValue); 
	EndDo;
	OpeningStructure = New Structure;
	OpeningStructure.Insert("Filter", FilterStructure);
	OpeningStructure.Insert("ChoiceMode", True);
	OpeningStructure.Insert("CloseOnChoice", False);
	OpenForm("Catalog.ProductsAndServices.ChoiceForm", OpeningStructure, ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure Copy(Command)
	
	Cancel = False;
	Errors = Undefined;
	For Each TabularSectionRow In SelectedObjects Do
		IndexOf = SelectedObjects.IndexOf(TabularSectionRow);
		If Not ValueIsFilled(TabularSectionRow.Value) Then
			CommonUseClientServer.AddUserError(Errors, "SelectedObjects[%1].Value", NStr("en='No copying object selected';ru='Не выбран объект копирования';vi='Chưa chọn đối tượng sao chép'"), "SelectedObjects.Value", IndexOf, NStr("en='No copy object selected in %1';ru='Не выбран объект копирования в строке %1';vi='Chưa chọn đối tượng sao chép tại dòng%1'"));
		EndIf; 
	EndDo;
	CommonUseClientServer.ShowErrorsToUser(Errors, Cancel);
	If Cancel Then
		Return;
	EndIf; 
	
	ExecuteDataCopying();
	
	If CopyFromSelected Then
		EventName = "";
		If CopySetsContent Then
			EventName = "SetContentCopying";
		ElsIf CopyCharacteristics Then
			EventName = "CharacteristicCopying";
		ElsIf CopySpecifications Then
			EventName = "SpecificationsCopying";
		ElsIf CopyUnitsOfMeasurement Then
			EventName = "UnitOfMeasurementCopying";
		EndIf;
		If Not IsBlankString(EventName) Then
			Notify(EventName, ProductsAndServices, ThisObject);
		EndIf; 
	EndIf; 
	
	If CopyFromSelected Then
		Close();
	EndIf; 
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();		
	
EndProcedure

#EndRegion 

#Region InternalProceduresAndFunctions

&AtClientAtServerNoContext
Procedure FormManagement(Form)
	
	Items = Form.Items;
	
	// Текст предупреждения
	If Form.HasConnectionWithCharacteristics 
		And Form.CopySetsContent 
		And GetProperty(Form.TooltipDisplaySettings, "HideCharacteristicAddingTooltip", False)=False Then
		Form.CurrentTooltip = "AddingCharacteristics";
	ElsIf Form.HasConnectionWithCharacteristics 
		And Form.CopySpecifications 
		And GetProperty(Form.TooltipDisplaySettings, "HideCharacteristicAbsenceTooltip", False)=False Then
		Form.CurrentTooltip = "CharacteristicsAbsence";
	Else
		Form.CurrentTooltip = "";
	EndIf;
	DisplayTooltip(Form);
	
	Items.SelectedObjectsCheck.Visible = Not Form.CopyFromSelected;
	Items.SelectedObjectsMessage.Visible = Not Form.CopyFromSelected And Form.CopyingCompleted;
	
EndProcedure

&AtServer
Procedure IdentifyMode()
	
	Query = New Query;
	Query.SetParameter("ProductsAndServices", ProductsAndServices);
	Query.SetParameter("CopyUnitsOfMeasurement", CopyUnitsOfMeasurement);
	Query.SetParameter("CopyCharacteristics", CopyCharacteristics);
	Query.SetParameter("CopySpecifications", CopySpecifications);
	Query.SetParameter("CopySetsContent", CopySetsContent);
	Query.Text =
	"SELECT TOP 1
	|	UOM.Ref AS Ref
	|FROM
	|	Catalog.UOM AS UOM
	|WHERE
	|	UOM.Owner = &ProductsAndServices
	|	AND &CopyUnitsOfMeasurement
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	ProductsAndServicesCharacteristics.Ref
	|FROM
	|	Catalog.ProductsAndServicesCharacteristics AS ProductsAndServicesCharacteristics
	|WHERE
	|	ProductsAndServicesCharacteristics.Owner = &ProductsAndServices
	|	AND &CopyCharacteristics
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	Specifications.Ref
	|FROM
	|	Catalog.Specifications AS Specifications
	|WHERE
	|	Specifications.Owner = &ProductsAndServices
	|	AND &CopySpecifications
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	СоставНаборов.ProductsAndServicesOfSet
	|FROM
	|	InformationRegister.СоставНаборов AS СоставНаборов
	|WHERE
	|	СоставНаборов.ProductsAndServicesOfSet = &ProductsAndServices
	|	AND &CopySetsContent";
	CopyFromSelected = Query.Execute().IsEmpty();		
	
EndProcedure

&AtServer
Procedure UpdateCopyingList(SelectedValues = Undefined)
	
	ProductsAndServicesArray = New Array;
	If CopyFromSelected Then
		For Each TabularSectionRow In SelectedObjects Do
			ProductsAndServicesArray.Add(TabularSectionRow.Value);
		EndDo; 
	Else
		ProductsAndServicesArray.Add(ProductsAndServices);
	EndIf;
	
	If ProductsAndServicesArray.Count()=0 Then
		If CopyFromSelected Then
			Values.Clear();
		EndIf; 
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("ProductsAndServicesArray", ProductsAndServicesArray);
	Query.SetParameter("ProductsAndServices", ProductsAndServices);
	Query.SetParameter("SeveralSources", CopyFromSelected And SelectedObjects.Count()>1);
	Query.SetParameter("CopyUnitsOfMeasurement", CopyUnitsOfMeasurement);
	Query.SetParameter("CopyCharacteristics", CopyCharacteristics);
	Query.SetParameter("CopySpecifications", CopySpecifications);
	Query.SetParameter("CopySetsContent", CopySetsContent);
	Query.SetParameter("UseCharacteristics", ?(CopyFromSelected, UseCharacteristics, Undefined));
	Query.SetParameter("SelectedValues", Values.Unload(New Structure("Check", True), "Value, ValueType, Check"));
	Query.Text =
	"SELECT
	|	SelectedValues.Value AS Value,
	|	SelectedValues.ValueType AS ValueType,
	|	SelectedValues.Check AS Check
	|INTO SelectedValues
	|FROM
	|	&SelectedValues AS SelectedValues
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UOM.Ref AS Value,
	|	UOM.Description + CASE
	|		WHEN &SeveralSources
	|			THEN "" ("" + UOM.Owner.Description + "")""
	|		ELSE """"
	|	END AS Presentation,
	|	""Uom"" AS ValueType,
	|	ISNULL(SelectedValues.Check, TRUE) AS Check,
	|	1 AS Order,
	|	FALSE AS UseCharacteristics,
	|	VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef) AS Characteristic,
	|	UOM.Owner AS ProductsAndServices
	|FROM
	|	Catalog.UOM AS UOM
	|		LEFT JOIN SelectedValues AS SelectedValues
	|		ON UOM.Ref = SelectedValues.Value
	|			AND (SelectedValues.ValueType = ""Uom"")
	|WHERE
	|	UOM.Owner IN(&ProductsAndServicesArray)
	|	AND NOT UOM.DeletionMark
	|	AND &CopyUnitsOfMeasurement
	|
	|UNION ALL
	|
	|SELECT
	|	ProductsAndServicesCharacteristics.Ref,
	|	ProductsAndServicesCharacteristics.Description + CASE
	|		WHEN &SeveralSources
	|			THEN "" ("" + ProductsAndServicesCharacteristics.Owner.Description + "")""
	|		ELSE """"
	|	END,
	|	""ProductsAndServicesCharacteristics"",
	|	ISNULL(SelectedValues.Check, TRUE),
	|	2,
	|	FALSE,
	|	VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef),
	|	ProductsAndServicesCharacteristics.Owner
	|FROM
	|	Catalog.ProductsAndServicesCharacteristics AS ProductsAndServicesCharacteristics
	|		LEFT JOIN SelectedValues AS SelectedValues
	|		ON ProductsAndServicesCharacteristics.Ref = SelectedValues.Value
	|			AND (SelectedValues.ValueType = ""ProductsAndServicesCharacteristics"")
	|WHERE
	|	ProductsAndServicesCharacteristics.Owner IN(&ProductsAndServicesArray)
	|	AND NOT ProductsAndServicesCharacteristics.DeletionMark
	|	AND NOT ProductsAndServicesCharacteristics.NotValid
	|	AND &CopyCharacteristics
	|	AND NOT &UseCharacteristics = FALSE
	|
	|UNION ALL
	|
	|SELECT
	|	Specifications.Ref,
	|	Specifications.Description + CASE
	|		WHEN &SeveralSources
	|			THEN "" ("" + Specifications.Owner.Description + "")""
	|		ELSE """"
	|	END,
	|	""Specifications"",
	|	ISNULL(SelectedValues.Check, TRUE),
	|	3,
	|	CASE
	|		WHEN Specifications.ProductCharacteristic <> VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	Specifications.ProductCharacteristic,
	|	Specifications.Owner
	|FROM
	|	Catalog.Specifications AS Specifications
	|		LEFT JOIN SelectedValues AS SelectedValues
	|		ON Specifications.Ref = SelectedValues.Value
	|			AND (SelectedValues.ValueType = ""Specifications"")
	|WHERE
	|	Specifications.Owner IN(&ProductsAndServicesArray)
	|	AND NOT Specifications.DeletionMark
	|	AND NOT Specifications.NotValid
	|	AND Specifications.DocOrder IN (VALUE(Document.CustomerOrder.EmptyRef), VALUE(Document.ProductionOrder.EmptyRef), UNDEFINED)
	|	AND &CopySpecifications
	|	AND CASE
	|			WHEN &UseCharacteristics = FALSE
	|				THEN Specifications.ProductCharacteristic = VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	|			ELSE TRUE
	|		END
	|
	|ORDER BY
	|	Order,
	|	ProductsAndServices,
	|	Value";
	
	Values.Load(Query.Execute().Unload());
	
	If CopySpecifications Then
		TabChecks = Values.Unload();
		TabChecks.GroupBy("Characteristic");
		If TabChecks.Count()>1 Then
			// Если копируются спецификации с разными характеристкиами - отображаем их в списке
			For Each CopyingRow In Values Do
				If Not ValueIsFilled(CopyingRow.Characteristic) Then
					Continue;
				EndIf; 
				If Right(CopyingRow.Presentation, 1)=")" Then
					CopyingRow.Presentation = Left(CopyingRow.Presentation, StrLen(CopyingRow.Presentation)-1)
					+StrTemplate(", %1)", String(CopyingRow.Characteristic));
				Else
					CopyingRow.Presentation = CopyingRow.Presentation+StrTemplate(" (%1)", String(CopyingRow.Characteristic));
				EndIf; 
			EndDo; 
		EndIf; 
	EndIf; 
	
	FormManagement(ThisObject);
	
EndProcedure

&AtServer
Procedure ModeSetting()
	
	If CopyFromSelected Then
		Items.GroupSelectedObjects.Title = NStr("en='Copy from';ru='Скопировать из';vi='Sao chép từ'");
		If Items.Columns.ChildItems.IndexOf(Items.ValueColumn)=0 Then
			 Items.Move(Items.ValueColumn, Items.Columns);
		EndIf; 
	Else
		Items.GroupSelectedObjects.Title = NStr("en='Copy in';ru='Скопировать в';vi='Sao chép vào'");
		If Items.Columns.ChildItems.IndexOf(Items.ColumnObjects)=0 Then
			 Items.Move(Items.ColumnObjects, Items.Columns);
		EndIf; 
	EndIf;
	
	FillChoiceParameters();
	
EndProcedure
 
&AtServer
Procedure FillChoiceParameters()
	
	ChoiceParameters = New Array;
	
	HasConnectionWithCharacteristics = (CopySpecifications Or CopySetsContent) And UseCharacteristics;
	CharacteristicCopyingNeeded = CopyCharacteristics Or HasConnectionWithCharacteristics;
	
	// Копирование характеристик и спецификаций ограничено той же категорией номенклатуры
	If ValueIsFilled(ProductsAndServices) And (CharacteristicCopyingNeeded Or CopySpecifications) Then
		ChoiceParameters.Add(New ChoiceParameter("Filter.ProductsAndServicesCategory", ProductsAndServicesCategory));
	EndIf;
	
	If CopyUnitsOfMeasurement Then
		ChoiceParameters.Add(New ChoiceParameter("Filter.ThisIsSet", False));
	EndIf; 
	If CopyCharacteristics Then
		ChoiceParameters.Add(New ChoiceParameter("Filter.UseCharacteristics", True));
	EndIf; 
	If CopySpecifications Then
		ChoiceParameters.Add(New ChoiceParameter("Filter.ThisIsSet", False));
	EndIf; 
	If CopySetsContent Then
		ChoiceParameters.Add(New ChoiceParameter("Filter.ThisIsSet", True));
	EndIf;
	ChoiceParameters.Add(New ChoiceParameter("Filter.ProductsAndServicesSource", ProductsAndServices));
	ChoiceParameters.Add(New ChoiceParameter("Filter.ProductsAndServicesType", ProductsAndServicesType));
	
	// Если номенклатура-источник использует характеристики, то для получателей тоже можно использовать 
	// 	только номенклатуру, использующую характеристики
	If Not CopyFromSelected And UseCharacteristics And (CopySpecifications Or CopySetsContent) Then
		ChoiceParameters.Add(New ChoiceParameter("Filter.UseCharacteristics", True));
	EndIf;
	
	Items.SelectedObjectsValue.ChoiceParameters = New FixedArray(ChoiceParameters);
	
EndProcedure

&AtServer
Procedure ExecuteDataCopying()
	
	If CopyFromSelected Then
		Owners = New Array;
		Owners.Add(ProductsAndServices);
	Else
		Owners = New Array;
		For Each TabularSectionRow In SelectedObjects Do
			If Not TabularSectionRow.Check Then
				Continue;
			EndIf;
			Owners.Add(TabularSectionRow.Value);
		EndDo; 
	EndIf;
	If Owners.Count()=0 Then
		Return;
	EndIf;
	
	If CopySpecifications Or CopySetsContent Then
		ProductsAndServicesArray = New Array;
		For Each TabularSectionRow In SelectedObjects Do
			ProductsAndServicesArray.Add(TabularSectionRow.Value);
		EndDo; 
		CharacteristicsMapping = ExistingCharacteristics(ProductsAndServices, ProductsAndServicesArray, CopyFromSelected);
	Else
		CharacteristicsMapping = New Map;
	EndIf; 
	
	BeginTransaction();
	Copied = 0;
	For Each TabularSectionRow In Values Do
		If Not TabularSectionRow.Check Then
			Continue;
		EndIf;
		Copied = Copied+1;
		If TabularSectionRow.ValueType="Uom" Then
			CopyUnitOfMeasurement(TabularSectionRow.Value, Owners, TabularSectionRow.ProductsAndServices);
		EndIf; 
		If TabularSectionRow.ValueType="ProductsAndServicesCharacteristics" Then
			CopyCharacteristic(TabularSectionRow.Value, Owners, CharacteristicsMapping, CopyFromSelected);
		EndIf; 
		If TabularSectionRow.ValueType="Specifications" Then
			CopySpecification(TabularSectionRow.Value, Owners, CharacteristicsMapping, CopyFromSelected);
		EndIf; 
	EndDo;
	
	Try
		CommitTransaction();
	Except
		RollbackTransaction();
		TextOfMessage = DetailErrorDescription(ErrorInfo());
		WriteLogEvent("ru = 'Copy connected information.';
								|en = 'Copy connected information.';", EventLogLevel.Error, Metadata.Catalogs.ProductsAndServices, ProductsAndServices, TextOfMessage);
		CommonUseClientServer.MessageToUser(TextOfMessage);
		Return;
	EndTry;  
	
	If Not CopyFromSelected Then
		For Each TabularSectionRow In SelectedObjects Do
			TabularSectionRow.Message = "";
			TabularSectionRow.Check = False;
		EndDo;
		If CopyUnitsOfMeasurement Then
			TextOfMessage = NStr("en='Copied units (%1)';ru='Скопированы единицы (%1)';vi='Đã sao chép đơn vị (%1)'");
		ElsIf CopyCharacteristics Then
			TextOfMessage = NStr("en='Copied characteristics (%1)';ru='Скопированы характеристики (%1)';vi='Sao chép đặc tính (%1)'");
		ElsIf CopySpecifications Then
			TextOfMessage = NStr("en='Copied BOM (%1)';ru='Скопированы спецификации (%1)';vi='Sao chép bảng kê chi tiết (%1)'");
		ElsIf CopySetsContent Then
			TextOfMessage = NStr("en='Copied sets (%1)';ru='Скопированы наборы (%1)';vi='Đã sao chép tập hợp (%1)'");
		Else
			TextOfMessage = NStr("en='Copied items (%1)';ru='Скопированы элементы (%1)';vi='Đã sao chép các phần tử (%1)'");
		EndIf; 
		For Each Owner In Owners Do
			FilterStructure = New Structure;
			FilterStructure.Insert("Value", Owner);
			Rows = SelectedObjects.FindRows(FilterStructure);
			If Rows.Count()=0 Then
				Continue;
			EndIf; 
			TabularSectionRow = Rows[0];
			TabularSectionRow.Message = StrTemplate(TextOfMessage, Copied);
		EndDo; 
		CopyingCompleted = True;
		FormManagement(ThisObject);
		Items.Cancel.Title = NStr("ru='Закрыть';en='Close';vi='Đóng'");
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ExistingCharacteristics(ProductsAndServices, SelectedObjects, CopyFromSelected)
	
	Result = New Map;
	For Each Object In SelectedObjects Do
		Result.Insert(Object, New Map);
	EndDo; 
	
	Query = New Query;
	Query.SetParameter("ProductsAndServices", ProductsAndServices);
	Query.SetParameter("SelectedObjects", SelectedObjects);
	If CopyFromSelected Then
		Query.Text =
		"SELECT
		|	CopiedCharacteristics.Owner AS ProductsAndServices,
		|	CopiedCharacteristics.Ref AS Characteristic,
		|	ExistingCharacteristics.Ref AS ExistingCharacteristic
		|FROM
		|	Catalog.ProductsAndServicesCharacteristics AS CopiedCharacteristics
		|		LEFT JOIN Catalog.ProductsAndServicesCharacteristics AS ExistingCharacteristics
		|		ON CopiedCharacteristics.Description = ExistingCharacteristics.Description
		|			AND (ExistingCharacteristics.Owner = &ProductsAndServices)
		|WHERE
		|	CopiedCharacteristics.Owner IN(&SelectedObjects)
		|	AND NOT ExistingCharacteristics.Ref IS NULL";
	Else
		Query.Text =
		"SELECT
		|	ExistingCharacteristics.Owner AS ProductsAndServices,
		|	CopiedCharacteristics.Ref AS Characteristic,
		|	ExistingCharacteristics.Ref AS ExistingCharacteristic
		|FROM
		|	Catalog.ProductsAndServicesCharacteristics AS CopiedCharacteristics
		|		LEFT JOIN Catalog.ProductsAndServicesCharacteristics AS ExistingCharacteristics
		|		ON CopiedCharacteristics.Description = ExistingCharacteristics.Description
		|			AND (ExistingCharacteristics.Owner IN (&SelectedObjects))
		|WHERE
		|	CopiedCharacteristics.Owner = &ProductsAndServices
		|	AND NOT ExistingCharacteristics.Ref IS NULL";
	EndIf;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Result[Selection.ProductsAndServices].Insert(Selection.Characteristic, Selection.ExistingCharacteristic);	
	EndDo; 
	
	Return Result;
	
EndFunction

&AtServer
Procedure CopyUnitOfMeasurement(MeasurementUnit, Owners, ProductsAndServices)
	
	Query = New Query;
	Query.SetParameter("MeasurementUnit", MeasurementUnit);
	Query.SetParameter("ProductsAndServices", ProductsAndServices);
	Query.Text =
	"SELECT
	|	ВесИОбъемЕдиницТоваров.Weight AS Weight,
	|	ВесИОбъемЕдиницТоваров.Volume AS Volume
	|FROM
	|	InformationRegister.ВесИОбъемЕдиницТоваров AS ВесИОбъемЕдиницТоваров
	|WHERE
	|	ВесИОбъемЕдиницТоваров.MeasurementUnit = &MeasurementUnit
	|	AND ВесИОбъемЕдиницТоваров.ProductsAndServices = &ProductsAndServices";
	SelectionWeightVolume = Query.Execute().Select();
	SaveWeightVolume = SelectionWeightVolume.Next();
	
	For Each Owner In Owners Do
		NewItem = MeasurementUnit.Copy();
		NewItem.Owner = Owner;
		NewItem.Write();
		If SaveWeightVolume Then
			Record = InformationRegisters.ВесИОбъемЕдиницТоваров.CreateRecordManager();
			Record.ProductsAndServices = Owner;
			Record.MeasurementUnit = NewItem.Ref;
			Record.Weight = SelectionWeightVolume.Weight;
			Record.Volume = SelectionWeightVolume.Volume;
			Record.Write(True);
		EndIf; 
	EndDo; 
	
EndProcedure

&AtServer
Procedure CopyCharacteristic(Characteristic, Owners, CharacteristicsMapping, CopyFromSelected)
	
	For Each Owner In Owners Do
		NewItem = Characteristic.Copy();
		OldOwner = NewItem.Owner;
		If TypeOf(OldOwner)=Type("CatalogRef.ProductsAndServicesCategories") Then
			Continue;
		EndIf; 
		NewItem.Owner = Owner;
		NewItem.Write();
		ProductsAndServicesOfMapping = ?(CopyFromSelected, OldOwner, Owner);
		If CharacteristicsMapping.Get(ProductsAndServicesOfMapping)=Undefined Then
			CharacteristicsMapping.Insert(ProductsAndServicesOfMapping, New Map);
		EndIf; 
		CharacteristicsMapping[ProductsAndServicesOfMapping].Insert(Characteristic, NewItem.Ref);
	EndDo; 
	
EndProcedure

&AtServer
Procedure CopySpecification(Specification, Owners, CharacteristicsMapping, CopyFromSelected)
	
	For Each Owner In Owners Do
		NewItem = Specification.Copy();
		OldOwner = NewItem.Owner;
		NewItem.Owner = Owner;
		If ValueIsFilled(NewItem.ProductCharacteristic) Then
			ProductsAndServicesOfMapping = ?(CopyFromSelected, OldOwner, Owner);
			NewCharacteristic = CharacteristicsMapping.Get(ProductsAndServicesOfMapping).Get(NewItem.ProductCharacteristic);
			If ValueIsFilled(NewCharacteristic) Then
				NewItem.ProductCharacteristic = NewCharacteristic;
			EndIf;
			If ValueIsFilled(NewItem.ProductCharacteristic) Then
				OwnerCharacteristics = CommonUse.ObjectAttributeValue(NewItem.ProductCharacteristic, "Owner");
				If OwnerCharacteristics<>Owner And TypeOf(OwnerCharacteristics)<>Type("CatalogRef.ProductsAndServicesCategories") Then
					NewItem.ProductCharacteristic = Catalogs.ProductsAndServicesCharacteristics.EmptyRef();
				EndIf; 
			EndIf; 
		EndIf; 
		NewItem.Write();
	EndDo; 
	
EndProcedure

#Region Tooltips

&AtServer
Procedure LoadTooltipDisplaySettings()
	
	TooltipDisplaySettings = CommonUse.SystemSettingsStorageImport("RelatedInformationCopying", "TooltipDisplaySettings", New Structure);
	CheckProperty(TooltipDisplaySettings, "HideCharacteristicAddingTooltip", False);
	CheckProperty(TooltipDisplaySettings, "HideCharacteristicAbsenceTooltip", False);
	
EndProcedure
 
&AtServer
Procedure SaveTooltipDisplaySettings()
	
	CommonUse.SystemSettingsStorageSave("RelatedInformationCopying", "TooltipDisplaySettings", TooltipDisplaySettings);
	
EndProcedure

&AtClientAtServerNoContext
Procedure DisplayTooltip(Form)
	
	Items = Form.Items;
	
	IsTooltipCharacteristicsAdding = (Form.CurrentTooltip="AddingCharacteristics");
	IsTooltipCharacteristicsAbsence = (Form.CurrentTooltip="CharacteristicsAbsence");
	
	If Form.CopySpecifications Then
		ValueText = NStr("en='specifications';ru='спецификаций';vi='bảng kê chi tiết'");
	ElsIf Form.CopySetsContent Then
		ValueText = NStr("en='set-up';ru='состава наборов';vi='thành phần tập hợp'");
	ElsIf Form.CopyCharacteristics Then
		ValueText = NStr("en='set-up';ru='состава наборов';vi='thành phần tập hợp'");
	ElsIf Form.CopyUnitsOfMeasurement Then
		ValueText = NStr("en='Characteristics';ru='характеристик';vi='Đặc tính '");
	EndIf;
	
	WarningText = "";
	If IsTooltipCharacteristicsAdding Then
		WarningText = NStr("en='When copying %1, the missing characteristics can be created%2';ru='При копировании %1 могут быть созданы недостающие характеристики%2';vi='Khi sao chép %1, có thể tạo các đặc tính còn thiếu%2'");
	ElsIf IsTooltipCharacteristicsAbsence Then
		WarningText = NStr("en='When copying %1, the missing characteristics can be created%2';ru='При копировании %1 могут быть созданы недостающие характеристики%2';vi='Khi sao chép %1, có thể tạo các đặc tính còn thiếu%2'");
	EndIf;
	
	If IsTooltipCharacteristicsAdding Or IsTooltipCharacteristicsAbsence Then
		If Form.CopyFromSelected Then
			TextProductsAndServices = StrTemplate(NStr("en=' products and services %1';ru=' у номенклатуры %1';vi='của mặt hàng %1'", Form.ProductsAndServices));
		Else
			TextProductsAndServices = "";
		EndIf;
		WarningText = StrTemplate(WarningText, ValueText, TextProductsAndServices);
		Items.WarningLabel.Title = WarningText;
		Items.Warning.Visible = True;	
	Else
		Items.Warning.Visible = False;	
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure CheckProperty(Structure, Property, DefaultValue)
	
	If TypeOf(Structure)<>Type("Structure") Then
		Structure  = New Structure;
	EndIf; 	
	
	If Structure.Property(Property) Then
		Return;
	EndIf; 
	
	Structure.Insert(Property, DefaultValue);
	
EndProcedure

&AtClientAtServerNoContext
Function GetProperty(Structure, Property, DefaultValue)
	
	If TypeOf(Structure)<>Type("Structure") Then
		Structure  = New Structure;
	EndIf; 	
	
	Value = Undefined;
	If Structure.Property(Property, Value) Then
		Return Value;
	Else
		Structure.Insert(Property, DefaultValue);
		Return DefaultValue;
	EndIf; 
	
EndFunction

&AtClientAtServerNoContext
Procedure SetProperty(Structure, Property, Value)
	
	If TypeOf(Structure)<>Type("Structure") Then
		Structure  = New Structure;
	EndIf; 	
	
	Structure.Insert(Property, Value);
	
EndProcedure

&AtServerNoContext
Function AttributeValues(Object, Attributes)
	
	Return CommonUse.ObjectAttributesValues(Object, Attributes);	
	
EndFunction

#EndRegion 

#EndRegion
 