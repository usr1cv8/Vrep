
&AtClient
Var CurrentTypeOfContentRow;

#Region FormEventsHandlers

&AtServer
// Процедура - обработчик события ПриСозданииНаСервере.
//
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Object.Ref.IsEmpty() Then
		FillCashValues();
		FillInternalDataAfterReadingObject(Object, CashValues);
	EndIf;
	
	SetFormConditionalAppearance();
	
	// StandardSubsystems.ВерсионированиеОбъектов
	ObjectVersioning.OnCreateAtServer(ThisForm);
	// End StandardSubsystems.ВерсионированиеОбъектов
	
	// StandardSubsystems.Свойства
	AdditionalParameters = PropertiesManagementOverridable.FillAdditionalParameters(Object, "AdditionalAttributesGroup");
	PropertiesManagement.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Свойства
	
	UseTechOperations = Constants.FunctionalOptionUseTechOperations.Get();
	UseAdditAttributes = (Constants.UseAdditionalAttributesAndInformation.Get() 
		And CommonUseClientServer.HasAttributeOrObjectProperty(ThisObject, "Properties_UseAdditionalAttributes") 
		And ThisObject.Properties_UseAdditionalAttributes);
	If Not (UseTechOperations Or UseAdditAttributes) Then
		Items.Pages.PagesRepresentation = FormPagesRepresentation.None;
	EndIf;
	If Not UseAdditAttributes Then
		Items.Additionally.Visible = False;
	EndIf; 
	If Not UseTechOperations Then
		Items.GroupOperations.Visible = False;
	EndIf; 
	
	// StandardSubsystems.ЗагрузкаДанныхИзВнешнегоИсточника
	DataImportFromExternalSources.OnCreateAtServer(Metadata.Catalogs.Specifications.TabularSections.Content, DataLoadSettings, ThisObject, False);
	// End StandardSubsystems.ЗагрузкаДанныхИзВнешнегоИсточника
	
	// Калькуляция
	Items.DocOrder.Visible = ValueIsFilled(Object.DocOrder);
	// Конец Калькуляция
	
	// ParametricSpecifications
	Items.GroupBaseSpecification.Visible = ValueIsFilled(Object.BaseSpecification);
	// End ParametricSpecifications
	
	UpdateChoiceListStages();
	
	FormManagement(ThisObject);
	
EndProcedure // ПриСозданииНаСервере()

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.Свойства
	PropertiesManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Свойства
	
	FillCashValues();
	FillInternalDataAfterReadingObject(Object, CashValues);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Свойства
	PropertiesManagementClient.AfterLoadAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Свойства
	
	// ParametricSpecifications
	UpdateAdditionalAttributesRequerments(ThisObject, True);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Src)
	
	// StandardSubsystems.Свойства 
	If PropertiesManagementClient.ProcessAlerts(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertiesManagementClient.AfterLoadAdditionalAttributes(ThisObject);
		// ParametricSpecifications
		UpdateAdditionalAttributesRequerments(ThisObject, True);
		// End ParametricSpecifications
	EndIf;
	// End StandardSubsystems.Свойства
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	Object.IsTemplate = False;
	If CashValues.UseParametricSpecifications Then
		For Each TabularSectionRow In Object.Content Do
			If ValueIsFilled(Object.DocOrder) Then
				// Привязанные к заказу спецификации не могут быть параметрическими
				TabularSectionRow.FormulaProductsAndServices = "";
				TabularSectionRow.FormulaNumber = "";
				TabularSectionRow.MappingUsed = False;
				TabularSectionRow.UseFormulaProductsAndServices = False;
				TabularSectionRow.UseFormulaNumber = False;
			EndIf; 
			If TabularSectionRow.UseFormulaProductsAndServices Then
				TabularSectionRow.ProductsAndServices = Undefined;
				TabularSectionRow.Characteristic = Undefined;
				TabularSectionRow.MeasurementUnit = Undefined;
				Object.IsTemplate = True;
			Else
				TabularSectionRow.FormulaProductsAndServices = "";
				TabularSectionRow.MappingUsed = False;
			EndIf; 
			If TabularSectionRow.UseFormulaNumber Then
				TabularSectionRow.Quantity = 0;
				Object.IsTemplate = True;
			Else
				TabularSectionRow.FormulaNumber = "";
			EndIf; 
		EndDo;
		For Each TabularSectionRow In Object.Operations Do
			If ValueIsFilled(Object.DocOrder) Then
				// Привязанные к заказу спецификации не могут быть параметрическими
				TabularSectionRow.FormulaOperation = "";
				TabularSectionRow.FormulaTimeNorm = "";
				TabularSectionRow.FormulaNumber = "";
				TabularSectionRow.MappingUsed = False;
				TabularSectionRow.UseFormulaOperation = False;
				TabularSectionRow.UseFormulaNumber = False;
			EndIf; 
			If TabularSectionRow.UseFormulaOperation Then
				TabularSectionRow.Operation = Undefined;
				Object.IsTemplate = True;
			Else
				TabularSectionRow.FormulaOperation = "";
				TabularSectionRow.MappingUsed = False;
			EndIf; 
			If TabularSectionRow.UseFormulaNumber Then
				TabularSectionRow.Quantity = 0;
				TabularSectionRow.TimeNorm = 0;
				Object.IsTemplate = True;
			Else
				TabularSectionRow.FormulaNumber = "";
				TabularSectionRow.FormulaTimeNorm = "";
			EndIf; 
		EndDo;
	Else
		For Each TabularSectionRow In Object.Content Do
			TabularSectionRow.FormulaProductsAndServices = "";
			TabularSectionRow.FormulaNumber = "";
			TabularSectionRow.MappingUsed = False;
		EndDo;
		For Each TabularSectionRow In Object.Operations Do
			TabularSectionRow.FormulaOperation = "";
			TabularSectionRow.FormulaTimeNorm = "";
			TabularSectionRow.FormulaNumber = "";
			TabularSectionRow.MappingUsed = False;
		EndDo;
		Object.ContentMapping.Clear();
		Object.OperationsMapping.Clear();
	EndIf; 		
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Свойства
	PropertiesManagement.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Свойства
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Свойства
	PropertiesManagement.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Свойства
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Parameter = New Structure("Ref, NotValid", Object.Ref, Object.NotValid);
	Notify("SpecificationSaved", Parameter, Object.Owner);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	FillInternalDataAfterReadingObject(Object, CashValues);
	
EndProcedure

#EndRegion

#Region FormItemEventsHandlers

#Region Content

&AtClient
Procedure ContentOnStartEdit(Item, NewRow, Copy)
	
	CurrentRow = Item.CurrentData;
	
	If NewRow And Copy Then
		BindingKeyBase = CurrentRow.ConnectionKey;
		CurrentRow.ConnectionKey = 0;
		If CashValues.UseParametricSpecifications 
			And CurrentRow.MappingUsed 
			And BindingKeyBase<>0 Then
			// Требуется скопировать настройки сопоставления
			FilterStructure = New Structure;
			FilterStructure.Insert("ConnectionKey", BindingKeyBase);
			Rows = Object.ContentMapping.FindRows(FilterStructure);
			If Rows.Count()>0 Then
				TabularSectionName = "Content";
				SmallBusinessClient.AddConnectionKeyToTabularSectionLine(ThisObject);
				For Each MappingRow In Rows Do
					NewRow = Object.ContentMapping.Add();
					FillPropertyValues(NewRow, MappingRow);
					NewRow.ConnectionKey = CurrentRow.ConnectionKey;
				EndDo; 
			EndIf; 
		EndIf; 
	EndIf; 	
	
	If CurrentRow.UseFormulaProductsAndServices And Item.CurrentItem=Items.ContentProductsAndServices Then
		Item.CurrentItem = Items.ContentFormulaProductsAndServices;
	EndIf; 
	
EndProcedure

&AtClient
Procedure ContentChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	For Each ProductsAndServices In SelectedValue Do
		
		StructureData = New Structure();
		StructureData.Insert("ProductsAndServices", ProductsAndServices);
		ExistingRows = Object.Content.FindRows(StructureData);
		If ExistingRows.Count()<>0 Then
			For Each TabularSectionRow In ExistingRows Do
				TabularSectionRow.Quantity = TabularSectionRow.Quantity + 1;
			EndDo;
			Continue;
		EndIf; 
		
		NewRow = Object.Content.Add();
		NewRow.ProductsAndServices = ProductsAndServices;
		NewRow.ContentRowType = PredefinedValue("Enum.SpecificationContentRowTypes.Material");
		
		StructureData = GetDataProductsAndServicesOnChange(StructureData);
		
		NewRow.Characteristic = Undefined;
		NewRow.MeasurementUnit = StructureData.MeasurementUnit;
		NewRow.Specification = StructureData.Specification;
		NewRow.Quantity = 1;
		NewRow.ProductsQuantity = 1;
		NewRow.CostPercentage = 1;
		
	EndDo; 
	
EndProcedure

&AtClient
Procedure ContentSelection(Item, SelectedRow, Field, StandardProcessing)
	
	If Field=Items.ContentFormulaProductsAndServices Then
		StandardProcessing = False;
		FormulaProductsAndServices();
	ElsIf Field=Items.ContentFormulaNumber Then
		StandardProcessing = False;
		FormulaNumberBeginSelection();
	EndIf; 	
	
EndProcedure

&AtClient
Procedure ContentAfterDeleteRow(Item)
	
	UpdateAdditionalAttributesRequerments(ThisObject);	
	
EndProcedure

&AtClient
Procedure ContentContentRowTypeOnChange(Item)
	
	TabularSectionRow = Items.Content.CurrentData;
	
	If ValueIsFilled(TabularSectionRow.ContentRowType)
		And ValueIsFilled(TabularSectionRow.ProductsAndServices) Then
		
		StructureData = New Structure();
		StructureData.Insert("ContentRowType", TabularSectionRow.ContentRowType);
		StructureData.Insert("ProductsAndServices", TabularSectionRow.ProductsAndServices);
		
		If Not CorrespondsRowTypeProductsAndServicesType(StructureData) Then
			
			TabularSectionRow.ProductsAndServices = Undefined;
			TabularSectionRow.Characteristic = Undefined;
			TabularSectionRow.MeasurementUnit = Undefined;
			TabularSectionRow.Specification = Undefined;
			TabularSectionRow.Quantity = 1;
			TabularSectionRow.ProductsQuantity = 1;
			TabularSectionRow.CostPercentage = 1;
			
		EndIf;
		
	EndIf;
	
EndProcedure // СоставТипСтрокиСоставаПриИзменении()

&AtClient
Procedure ContentUseFormulaProductsAndServicesOnChange(Item)
	
	UpdateAdditionalAttributesRequerments(ThisObject);	
	
EndProcedure

&AtClient
Procedure ContentProductsAndServicesOnChange(Item)
	
	TabularSectionRow = Items.Content.CurrentData;
	
	StructureData = New Structure();
	StructureData.Insert("ProductsAndServices", TabularSectionRow.ProductsAndServices);
	
	StructureData = GetDataProductsAndServicesOnChange(StructureData);
	
	TabularSectionRow.Characteristic = Undefined;
	TabularSectionRow.MeasurementUnit = StructureData.MeasurementUnit;
	TabularSectionRow.Specification = StructureData.Specification;
	TabularSectionRow.Quantity = 1;
	TabularSectionRow.ProductsQuantity = 1;
	TabularSectionRow.CostPercentage = 1;
	
EndProcedure // СоставНоменклатураПриИзменении()

&AtClient
Procedure ContentProductsAndServicesStartChoice(Item, ChoiceData, StandardProcessing)
	
	UpdateProductsAndServicesChoiceOptions();	
	
EndProcedure

&AtClient
Procedure ContentProductsAndServicesAutoComplete(Item, Text, ChoiceData, GetingDataParameters, Waiting, StandardProcessing)
	
	If Waiting=0 Then
		UpdateProductsAndServicesChoiceOptions();	
	EndIf; 
	
EndProcedure

&AtClient
Procedure ContentProductsAndServicesChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	// Запрещаем циклические ссылки
	If SelectedValue = Object.Owner Then
		CommonUseClientServer.MessageToUser(NStr("en='The specification may not include products.';ru='В состав спецификации не может входить продукция.';vi='Trong thành phần bảng kê chi tiết không thể có sản phẩm.'"));
		StandardProcessing = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure ContentFormulaProductsAndServicesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	FormulaProductsAndServices();
	
EndProcedure

&AtClient
Procedure FormulaProductsAndServices()
	
	CurrentRow = Items.Content.CurrentData;
	If CurrentRow.ConnectionKey=0 Then
		TabularSectionName = "Content";
		SmallBusinessClient.AddConnectionKeyToTabularSectionLine(ThisObject);
	EndIf; 
	Notification = New NotifyDescription("ContentFormulaProductsAndServicesSelectCompletion", ThisObject);
	OpenParameters = New Structure;
	OpenParameters.Insert("ProductsAndServicesCategory", CashValues.ProductsAndServicesCategory);
	OpenParameters.Insert("Formula", CurrentRow.FormulaProductsAndServices);
	OpenParameters.Insert("LongDesc", CurrentRow.LongDesc);
	OpenParameters.Insert("MappingUsed", CurrentRow.MappingUsed);
	OpenParameters.Insert("TSName", "Content");
	If CurrentRow.MappingUsed Then
		AddMappingOptionsInStructureOpen(OpenParameters, CurrentRow.ConnectionKey, "ContentMapping");
	EndIf; 
	OpenParameters.Insert("TypeRestriction", Type("CatalogRef.ProductsAndServices"));
	OpenParameters.Insert("ChoiceParameters", Items.ContentProductsAndServices.ChoiceParameters);
	OpenFormulasDesigner(OpenParameters, Notification);
	
EndProcedure

&AtClient
Procedure ContentFormulaProductsAndServicesSelectCompletion(SelectedValue, AdditionalParameters) Export
	
	CurrentRow = Items.Content.CurrentData;
	If TypeOf(SelectedValue)=Type("Structure") And CurrentRow<>Undefined Then
		SelectedValue.Property("MappingUsed", CurrentRow.MappingUsed);
		SelectedValue.Property("LongDesc", CurrentRow.LongDesc);
		SelectedValue.Property("Formula", CurrentRow.FormulaProductsAndServices);
		UpdateMapping(CurrentRow, SelectedValue, "ContentMapping");
	EndIf;	
	If CurrentRow.Quantity=0 And Not CurrentRow.UseFormulaNumber Then
		CurrentRow.Quantity = 1;
	EndIf; 
	If CurrentRow.CostPercentage=0 Then
		CurrentRow.CostPercentage = 1;
	EndIf; 
	If CurrentRow.ProductsQuantity=0 Then
		CurrentRow.ProductsQuantity = 1;
	EndIf; 
 	
EndProcedure

&AtClient
Procedure ContentCharacteristicOnChange(Item)
	
	TabularSectionRow = Items.Content.CurrentData;
	
	StructureData = New Structure;
	StructureData.Insert("ProductsAndServices", TabularSectionRow.ProductsAndServices);
	StructureData.Insert("Characteristic", TabularSectionRow.Characteristic);
	
	StructureData = GetDataCharacteristicOnChange(StructureData);
	
	TabularSectionRow.Specification = StructureData.Specification;
	
EndProcedure

&AtClient
Procedure ContentUseFormulaNumberOnChange(Item)
	
	UpdateAdditionalAttributesRequerments(ThisObject);	
	
EndProcedure

&AtClient
Procedure ContentFormulaNumberStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	FormulaNumberBeginSelection();
	
EndProcedure

&AtClient
Procedure FormulaNumberBeginSelection()
	
	CurrentRow = Items.Content.CurrentData;
	Notification = New NotifyDescription("ContentFormulaNumberSelectCompletion", ThisObject);
	OpenParameters = New Structure;
	OpenParameters.Insert("ProductsAndServicesCategory", CashValues.ProductsAndServicesCategory);
	OpenParameters.Insert("Formula", CurrentRow.FormulaNumber);
	OpenParameters.Insert("SimpleTypes", True);
	OpenFormulasDesigner(OpenParameters, Notification);
	
EndProcedure

&AtClient
Procedure ContentFormulaNumberSelectCompletion(SelectedValue, AdditionalParameters) Export
	
	CurrentRow = Items.Content.CurrentData;
	If TypeOf(SelectedValue)=Type("Structure") And CurrentRow<>Undefined Then
		SelectedValue.Property("Formula", CurrentRow.FormulaNumber);
	EndIf; 	
	
EndProcedure

#EndRegion 

#Region Operations

&AtClient
Procedure OperationsOnStartEdit(Item, NewRow, Copy)
	
	CurrentRow = Item.CurrentData;
	If NewRow And Copy Then
		BindingKeyBase = CurrentRow.ConnectionKey;
		CurrentRow.ConnectionKey = 0;
		If CashValues.UseParametricSpecifications 
			And CurrentRow.MappingUsed 
			And BindingKeyBase<>0 Then
			// Требуется скопировать настройки сопоставления
			FilterStructure = New Structure;
			FilterStructure.Insert("ConnectionKey", BindingKeyBase);
			Rows = Object.OperationsMapping.FindRows(FilterStructure);
			If Rows.Count()>0 Then
				TabularSectionName = "Operations";
				SmallBusinessClient.AddConnectionKeyToTabularSectionLine(ThisObject);
				For Each MappingRow In Rows Do
					NewRow = Object.OperationsMapping.Add();
					FillPropertyValues(NewRow, MappingRow);
					NewRow.ConnectionKey = CurrentRow.ConnectionKey;
				EndDo; 
			EndIf; 
		EndIf; 
	EndIf;
	
	If CurrentRow.UseFormulaOperation And Item.CurrentItem=Items.OperationsOperation Then
		Item.CurrentItem = Items.OperationFormulaOperation;
	EndIf; 
	
EndProcedure

&AtClient
Procedure OperationsChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	For Each Operation In SelectedValue Do
		
		StructureData = New Structure();
		StructureData.Insert("Operation", Operation);
		ExistingRows = Object.Operations.FindRows(StructureData);
		If ExistingRows.Count()<>0 Then
			For Each TabularSectionRow In ExistingRows Do
				TabularSectionRow.TimeNorm = TabularSectionRow.TimeNorm + 1;
			EndDo;
			Continue;
		EndIf; 
		
		NewRow = Object.Operations.Add();
		NewRow.Operation = Operation;
		
		StructureData = New Structure();
		StructureData.Insert("ProductsAndServices", Operation);
		StructureData = GetDataProductsAndServicesOnChange(StructureData);
		
		NewRow.TimeNorm = StructureData.TimeNorm;
		NewRow.FixedCost = StructureData.FixedCost;
		If ValueIsFilled(NewRow.Operation) And CashValues.OperationFixedCost.Get(NewRow.Operation)=Undefined Then
			ValueMap = New Map(CashValues.OperationFixedCost);
			ValueMap.Insert(NewRow.Operation, StructureData.FixedCost);
			CashValues.OperationFixedCost = New FixedMap(ValueMap);
		EndIf; 
		NewRow.ProductsQuantity = 1;
		NewRow.Quantity = 1;
		
	EndDo; 
	
EndProcedure

&AtClient
Procedure OperationsSelection(Item, SelectedRow, Field, StandardProcessing)
	
	If Field=Items.OperationFormulaOperation Then
		StandardProcessing = False;
		FormulaOperationBeginSelection();
	ElsIf Field=Items.OperationsFormulaNumber Then
		StandardProcessing = False;
		FormulaOperationsNumberBeginSelection();
	ElsIf Field=Items.OperationsFormulaTimeNorm Then
		StandardProcessing = False;
		FormulaTimeNormBeginSelection();
	EndIf; 	
	
EndProcedure

&AtClient
Procedure OperationsAfterDeleteRow(Item)
	
	UpdateAdditionalAttributesRequerments(ThisObject);	
	
EndProcedure

&AtClient
Procedure OperationsUseFormulaOperationOnChange(Item)
	
	UpdateAdditionalAttributesRequerments(ThisObject);	
	
EndProcedure

&AtClient
Procedure OperationsOperationOnChange(Item)
	
	TabularSectionRow = Items.Operations.CurrentData;
	
	StructureData = New Structure();
	StructureData.Insert("ProductsAndServices", TabularSectionRow.Operation);
	
	StructureData = GetDataProductsAndServicesOnChange(StructureData);
	
	TabularSectionRow.TimeNorm = StructureData.TimeNorm;
	TabularSectionRow.FixedCost = StructureData.FixedCost;
	If ValueIsFilled(TabularSectionRow.Operation) And CashValues.OperationFixedCost.Get(TabularSectionRow.Operation)=Undefined Then
		ValueMap = New Map(CashValues.OperationFixedCost);
		ValueMap.Insert(TabularSectionRow.Operation, StructureData.FixedCost);
		CashValues.OperationFixedCost = New FixedMap(ValueMap);
	EndIf; 
	TabularSectionRow.ProductsQuantity = 1;
	TabularSectionRow.Quantity = 1;
	
EndProcedure // ЗапасыНоменклатураПриИзменении()

&AtClient
Procedure OperationFormulaOperationStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	FormulaOperationBeginSelection();
	
EndProcedure

&AtClient
Procedure FormulaOperationBeginSelection()
	
	CurrentRow = Items.Operations.CurrentData;
	If CurrentRow.ConnectionKey=0 Then
		TabularSectionName = "Operations";
		SmallBusinessClient.AddConnectionKeyToTabularSectionLine(ThisObject);
	EndIf; 
	Notification = New NotifyDescription("OperationsFormulaOperationChoiceCompletion", ThisObject);
	OpenParameters = New Structure;
	OpenParameters.Insert("ProductsAndServicesCategory", CashValues.ProductsAndServicesCategory);
	OpenParameters.Insert("Formula", CurrentRow.FormulaOperation);
	OpenParameters.Insert("LongDesc", CurrentRow.LongDesc);
	OpenParameters.Insert("MappingUsed", CurrentRow.MappingUsed);
	OpenParameters.Insert("TSName", "Operations");
	If CurrentRow.MappingUsed Then
		AddMappingOptionsInStructureOpen(OpenParameters, CurrentRow.ConnectionKey, "OperationsMapping");
	EndIf; 
	OpenParameters.Insert("TypeRestriction", Type("CatalogRef.ProductsAndServices"));
	OpenParameters.Insert("ChoiceParameters", Items.OperationsOperation.ChoiceParameters);
	OpenFormulasDesigner(OpenParameters, Notification);
	
EndProcedure

&AtClient
Procedure OperationsFormulaOperationChoiceCompletion(SelectedValue, AdditionalParameters) Export
	
	CurrentRow = Items.Operations.CurrentData;
	If TypeOf(SelectedValue)=Type("Structure") And CurrentRow<>Undefined Then
		SelectedValue.Property("MappingUsed", CurrentRow.MappingUsed);
		SelectedValue.Property("Formula", CurrentRow.FormulaOperation);
		SelectedValue.Property("LongDesc", CurrentRow.LongDesc);
		UpdateMapping(CurrentRow, SelectedValue, "OperationsMapping");
	EndIf;
	If Not CurrentRow.UseFormulaNumber And CurrentRow.TimeNorm=0 Then
		CurrentRow.TimeNorm = 1;
	EndIf; 
	If Not CurrentRow.UseFormulaNumber And CurrentRow.Quantity=0 Then
		CurrentRow.Quantity = 1;
	EndIf; 
	If CurrentRow.ProductsQuantity=0 Then
		CurrentRow.ProductsQuantity = 1;
	EndIf;
	CurrentRow.FixedCost = True;
	
EndProcedure

&AtClient
Procedure OperationsUseFormulaNumberOnChange(Item)
	
	UpdateAdditionalAttributesRequerments(ThisObject);	
	
EndProcedure

&AtClient
Procedure OperationsFormulaTimeNormStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	FormulaTimeNormBeginSelection();
	
EndProcedure

&AtClient
Procedure FormulaTimeNormBeginSelection()
	
	Notification = New NotifyDescription("OperationsFormulaTimeNormChoiceCompletion", ThisObject);
	CurrentRow = Items.Operations.CurrentData;
	OpenParameters = New Structure;
	OpenParameters.Insert("ProductsAndServicesCategory", CashValues.ProductsAndServicesCategory);
	OpenParameters.Insert("Formula", CurrentRow.FormulaTimeNorm);
	OpenParameters.Insert("SimpleTypes", True);
	OpenFormulasDesigner(OpenParameters, Notification);
 
EndProcedure

&AtClient
Procedure OperationsFormulaTimeNormChoiceCompletion(SelectedValue, AdditionalParameters) Export
	
	CurrentRow = Items.Operations.CurrentData;
	If TypeOf(SelectedValue)=Type("Structure") And CurrentRow<>Undefined Then
		SelectedValue.Property("Formula", CurrentRow.FormulaTimeNorm);
	EndIf; 	
	
EndProcedure

&AtClient
Procedure OperationsFormulaNumberStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	FormulaOperationsNumberBeginSelection();
	
EndProcedure

&AtClient
Procedure FormulaOperationsNumberBeginSelection()
	
	Notification = New NotifyDescription("OperationsFormulaNumberChoiceCompletion", ThisObject);
	CurrentRow = Items.Operations.CurrentData;
	OpenParameters = New Structure;
	OpenParameters.Insert("ProductsAndServicesCategory", CashValues.ProductsAndServicesCategory);
	OpenParameters.Insert("Formula", CurrentRow.FormulaNumber);
	OpenParameters.Insert("SimpleTypes", True);
	OpenFormulasDesigner(OpenParameters, Notification);
 
EndProcedure

&AtClient
Procedure OperationsFormulaNumberChoiceCompletion(SelectedValue, AdditionalParameters) Export
	
	CurrentRow = Items.Operations.CurrentData;
	If TypeOf(SelectedValue)=Type("Structure") And CurrentRow<>Undefined Then
		SelectedValue.Property("Formula", CurrentRow.FormulaNumber);
	EndIf; 	
	
EndProcedure

#EndRegion 

&AtClient
Procedure OwnerOnChange(Item)
	
	FillCashValues();		
	
EndProcedure

&AtClient
Procedure ProductionKindOnChange(Item)
	
	If Not ValueIsFilled(Object.ProductionKind) Then
		For Each TabularSectionRow In Object.Content Do
			TabularSectionRow.Stage = PredefinedValue("Catalog.ProductionStages.EmptyRef");
		EndDo; 
		For Each TabularSectionRow In Object.Operations Do
			TabularSectionRow.Stage = PredefinedValue("Catalog.ProductionStages.EmptyRef");
		EndDo; 
	EndIf; 
	
	ProductionKindOnChangeServer();	
	
EndProcedure

&AtServer
Procedure ProductionKindOnChangeServer()
	
	UpdateChoiceListStages();
	
	FormManagement(ThisObject);
	
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonUseClient.ShowCommentEditingForm(Item.EditText, ThisObject, "Object.Comment");
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure PickContent(Command)
	
	FilterStructure = New Structure;
	For Each ChoiceParameter In Items.ContentProductsAndServices.ChoiceParameters Do
		AttributeName = StrReplace(ChoiceParameter.Name, "Filter.", "");
		FilterValue = ?(TypeOf(ChoiceParameter.Value)=Type("FixedArray"), New Array(ChoiceParameter.Value), ChoiceParameter.Value);
		FilterStructure.Insert(AttributeName, FilterValue); 
	EndDo;
	OpeningStructure = New Structure;
	OpeningStructure.Insert("Filter", FilterStructure);
	OpeningStructure.Insert("ChoiceMode", True);
	OpeningStructure.Insert("CloseOnChoice", False);
	OpeningStructure.Insert("MultipleChoice", True);
	If Items.Content.CurrentData<>Undefined And ValueIsFilled(Items.Content.CurrentData.ProductsAndServices) Then
		OpeningStructure.Insert("CurrentRow", Items.Content.CurrentData.ProductsAndServices);
	EndIf; 
	OpenForm("Catalog.ProductsAndServices.ChoiceForm", OpeningStructure, Items.Content, , , , , FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure OperationPick(Command)
	
	FilterStructure = New Structure;
	For Each ChoiceParameter In Items.OperationsOperation.ChoiceParameters Do
		AttributeName = StrReplace(ChoiceParameter.Name, "Filter.", "");
		FilterValue = ?(TypeOf(ChoiceParameter.Value)=Type("FixedArray"), New Array(ChoiceParameter.Value), ChoiceParameter.Value);
		FilterStructure.Insert(AttributeName, FilterValue); 
	EndDo;
	OpeningStructure = New Structure;
	OpeningStructure.Insert("Filter", FilterStructure);
	OpeningStructure.Insert("ChoiceMode", True);
	OpeningStructure.Insert("CloseOnChoice", False);
	OpeningStructure.Insert("MultipleChoice", True);
	If Items.Operations.CurrentData<>Undefined And ValueIsFilled(Items.Operations.CurrentData.Operation) Then
		OpeningStructure.Insert("CurrentRow", Items.Operations.CurrentData.Operation);
	EndIf; 
	OpenForm("Catalog.ProductsAndServices.ChoiceForm", OpeningStructure, Items.Operations, , , , , FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AddAdditionalAttribute(Command)
	
	FormParameters = AdditionalAttributeCreationSettings();
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInformation.ObjectForm", FormParameters,,,,,,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillByBase(Command)
	
	ShowQueryBox(New NotifyDescription("FillByBaseCompletion", ThisObject), NStr("en='The specification will be fully refilled on the base. Do you want to continue the operation?';ru='Спецификация будет полностью перезаполнена по базовой. Продолжить выполнение операции?';vi='Bảng kê chi tiết sẽ được điền lại hoàn toàn theo bảng kê cơ sở. Tiếp tục thực hiện giao dịch?'"), QuestionDialogMode.YesNo, 0);
	
EndProcedure

&AtClient
Procedure FillByBaseCompletion(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		
		FillByBaseServer();
		
	EndIf;

EndProcedure

&AtServer
Procedure FillByBaseServer()
	
	Cancel = False;
	ProductionFormulasServer.FillSpecification(Object, Cancel);
	
	FillCashValues();
	FillInternalDataAfterReadingObject(Object, CashValues);
	
EndProcedure

#EndRegion 

#Region FormViewManagement

&AtServer
Procedure SetFormConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Операции
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.Operations.FixedCost", False);
	WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, Items.OperationsQuantity.Name);
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.MinorInscriptionText);
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Text", NStr("en='Not used';ru='<Не используется>';vi='<Không sử dụng>'"));
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Enabled", False);
	
	If CashValues.UseParametricSpecifications Then
		
		// Формулы
		NewConditionalAppearance = ConditionalAppearance.Items.Add();
		WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.Content.UseFormulaProductsAndServices", True, DataCompositionComparisonType.NotEqual);
		WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, Items.ContentFormulaProductsAndServices.Name);
		WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Visible", False);
		
		NewConditionalAppearance = ConditionalAppearance.Items.Add();
		WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.Content.UseFormulaProductsAndServices", True);
		WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, Items.ContentProductsAndServices.Name);
		WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Visible", False);
		
		NewConditionalAppearance = ConditionalAppearance.Items.Add();
		WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.Content.UseFormulaNumber", False);
		WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, Items.ContentFormulaNumber.Name);
		WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Visible", False);
		
		NewConditionalAppearance = ConditionalAppearance.Items.Add();
		WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.Content.UseFormulaNumber", True);
		WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, Items.ContentQuantity.Name);
		WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Visible", False);
		
		NewConditionalAppearance = ConditionalAppearance.Items.Add();
		WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.Content.UseFormulaProductsAndServices", True);
		WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, Items.ContentMeasurementUnit.Name);
		WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.MinorInscriptionText);
		WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Text", NStr("en='<Basic unit of measurement>';ru='<Основная единица измерения>';vi='<Đơn vị tính cơ bản>'"));
		WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Enabled", False);
		
		NewConditionalAppearance = ConditionalAppearance.Items.Add();
		WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.Content.UseFormulaProductsAndServices", True, DataCompositionComparisonType.NotEqual);
		WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.Content.MeasurementUnit", , DataCompositionComparisonType.NotFilled);
		WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, Items.ContentMeasurementUnit.Name);
		WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "MarkIncomplete", True);
		
		NewConditionalAppearance = ConditionalAppearance.Items.Add();
		WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.Operations.UseFormulaOperation", False);
		WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, Items.OperationFormulaOperation.Name);
		WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Visible", False);
		
		NewConditionalAppearance = ConditionalAppearance.Items.Add();
		WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.Operations.UseFormulaOperation", True);
		WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, Items.OperationsOperation.Name);
		WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Visible", False);
		
		NewConditionalAppearance = ConditionalAppearance.Items.Add();
		WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.Operations.UseFormulaNumber", False);
		WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, Items.OperationsFormulaTimeNorm.Name);
		WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, Items.OperationsFormulaNumber.Name);
		WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Visible", False);
		
		NewConditionalAppearance = ConditionalAppearance.Items.Add();
		WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.Operations.UseFormulaNumber", True);
		WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, Items.OperationsTimeNorm.Name);
		WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, Items.OperationsQuantity.Name);
		WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Visible", False);
		
		// Сопоставление
		NewConditionalAppearance = ConditionalAppearance.Items.Add();
		WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.Content.MappingUsed", True);
		WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, Items.ContentFormulaProductsAndServices.Name);
		WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.MinorInscriptionText);
		
		NewConditionalAppearance = ConditionalAppearance.Items.Add();
		WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.Content.UseFormulaProductsAndServices", True);
		WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, Items.ContentCharacteristic.Name);
		WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Visible", False);
		
		NewConditionalAppearance = ConditionalAppearance.Items.Add();
		WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.Operations.MappingUsed", True);
		WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, Items.OperationFormulaOperation.Name);
		WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "TextColor", StyleColors.MinorInscriptionText);
		
	EndIf; 
	
EndProcedure

&AtClientAtServerNoContext
Procedure FormManagement(Form)
	
	Items = Form.Items;
	Object = Form.Object;
	CashValues = Form.CashValues;
	
	// Этапы производства
	CommonUseClientServer.SetFormItemProperty(Items, "ContentStage", "Visible", ValueIsFilled(Object.ProductionKind));	
	CommonUseClientServer.SetFormItemProperty(Items, "OperationsStage", "Visible", ValueIsFilled(Object.ProductionKind));
	
	// Параметрические спецификации
	CommonUseClientServer.SetFormItemProperty(Items, "ContentUseFormulaProductsAndServices", "Visible", CashValues.UseParametricSpecifications And Not ValueIsFilled(Object.DocOrder));	
	CommonUseClientServer.SetFormItemProperty(Items, "ContentFormulaProductsAndServices", "Visible", CashValues.UseParametricSpecifications And Not ValueIsFilled(Object.DocOrder));	
	CommonUseClientServer.SetFormItemProperty(Items, "ContentUseFormulaNumber", "Visible", CashValues.UseParametricSpecifications And Not ValueIsFilled(Object.DocOrder));	
	CommonUseClientServer.SetFormItemProperty(Items, "ContentFormulaNumber", "Visible", CashValues.UseParametricSpecifications And Not ValueIsFilled(Object.DocOrder));	
	CommonUseClientServer.SetFormItemProperty(Items, "OperationsUseFormulaOperation", "Visible", CashValues.UseParametricSpecifications And Not ValueIsFilled(Object.DocOrder));	
	CommonUseClientServer.SetFormItemProperty(Items, "OperationFormulaOperation", "Visible", CashValues.UseParametricSpecifications And Not ValueIsFilled(Object.DocOrder));	
	CommonUseClientServer.SetFormItemProperty(Items, "OperationsUseFormulaNumber", "Visible", CashValues.UseParametricSpecifications And Not ValueIsFilled(Object.DocOrder));	
	CommonUseClientServer.SetFormItemProperty(Items, "OperationsFormulaTimeNorm", "Visible", CashValues.UseParametricSpecifications And Not ValueIsFilled(Object.DocOrder));	
	CommonUseClientServer.SetFormItemProperty(Items, "OperationsFormulaNumber", "Visible", CashValues.UseParametricSpecifications And Not ValueIsFilled(Object.DocOrder));	
	
EndProcedure

#EndRegion 

#Region InternalProceduresAndFunctions

&AtServerNoContext
// Получает набор данных с сервера для процедуры НоменклатураПриИзменении.
//
Function GetDataProductsAndServicesOnChange(StructureData)
	
	StructureData.Insert("MeasurementUnit", StructureData.ProductsAndServices.MeasurementUnit);
	StructureData.Insert("TimeNorm", StructureData.ProductsAndServices.TimeNorm);
	StructureData.Insert("ProductsAndServicesType", StructureData.ProductsAndServices.ProductsAndServicesType);
	StructureData.Insert("FixedCost", StructureData.ProductsAndServices.FixedCost);
	
	If StructureData.Property("Characteristic") Then
		StructureData.Insert("Specification", SmallBusinessServer.GetDefaultSpecification(StructureData.ProductsAndServices, StructureData.Characteristic));
	Else
		StructureData.Insert("Specification", SmallBusinessServer.GetDefaultSpecification(StructureData.ProductsAndServices));
	EndIf;
	
	Return StructureData;
	
EndFunction // ПолучитьДанныеНоменклатураПриИзменении()

// Получает набор данных с сервера для процедуры ХарактеристикаПриИзменении.
//
&AtServerNoContext
Function GetDataCharacteristicOnChange(StructureData)
	
	StructureData.Insert("Specification", SmallBusinessServer.GetDefaultSpecification(StructureData.ProductsAndServices, StructureData.Characteristic));
	
	Return StructureData;
	
EndFunction // ПолучитьДанныеХарактеристикаПриИзменении()

&AtServerNoContext
// Возвращает результат проверки соответствия типа строки состава типу номенклатуры.
//
Function CorrespondsRowTypeProductsAndServicesType(StructureData)
	
	If (StructureData.ContentRowType = PredefinedValue("Enum.SpecificationContentRowTypes.Expense")
		And StructureData.ProductsAndServices.ProductsAndServicesType = PredefinedValue("Enum.ProductsAndServicesTypes.InventoryItem"))
		Or (StructureData.ContentRowType <> PredefinedValue("Enum.SpecificationContentRowTypes.Expense")
		And StructureData.ProductsAndServices.ProductsAndServicesType = PredefinedValue("Enum.ProductsAndServicesTypes.Service")) Then
		
		Return False;
		
	EndIf;
	
	Return True;
	
EndFunction // ПолучитьДанныеНоменклатураПриИзменении()

&AtServer
Function AdditionalAttributeCreationSettings()
	
	FormParameters = New Structure;
	
	CurrentSetOfProperties = Undefined;
	If ValueIsFilled(CashValues.ProductsAndServicesCategory) Then
		CurrentSetOfProperties = CommonUse.ObjectAttributeValue(CashValues.ProductsAndServicesCategory, "SpecificationAttributesArray");
	EndIf;
	If Not ValueIsFilled(CurrentSetOfProperties) Then
		CurrentSetOfProperties = Catalogs.AdditionalAttributesAndInformationSets.Catalog_Specifications_Common;
	EndIf; 
	FormParameters.Insert("CurrentSetOfProperties", CurrentSetOfProperties);
	FormParameters.Insert("ThisIsAdditionalInformation", False);
	
	Return FormParameters;
	
EndFunction

&AtServer
Procedure UpdateChoiceListStages()
	
	Items.ContentStage.ChoiceList.Clear();
	Items.OperationsStage.ChoiceList.Clear();
	
	If Not ValueIsFilled(Object.ProductionKind) Then
		Return;
	EndIf; 
	
	Query = New Query;
	Query.SetParameter("ProductionKind", Object.ProductionKind);
	Query.Text =
	"SELECT
	|	ProductionKindsStages.Stage AS Stage
	|FROM
	|	Catalog.ProductionKinds.Stages AS ProductionKindsStages
	|WHERE
	|	ProductionKindsStages.Ref = &ProductionKind
	|
	|ORDER BY
	|	ProductionKindsStages.LineNumber";
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		If Items.ContentStage.ChoiceList.FindByValue(Selection.Stage)<>Undefined Then
			Continue;
		EndIf; 
		Items.ContentStage.ChoiceList.Add(Selection.Stage);
		Items.OperationsStage.ChoiceList.Add(Selection.Stage);
	EndDo;
	If Items.ContentStage.ChoiceList.Count()=0 Then
		Items.ContentStage.ChoiceList.Add(Catalogs.ProductionStages.ProductionComplete);
		Items.OperationsStage.ChoiceList.Add(Catalogs.ProductionStages.ProductionComplete);
	EndIf; 
	
EndProcedure

&AtClient
Procedure UpdateProductsAndServicesChoiceOptions(AllTypes = False)
	
	CurRow = Items.Content.CurrentData;
	If CurRow=Undefined And Not AllTypes Then
		Return;
	EndIf; 
	
	// Установим параметры выбора номенклатуры в зависимости от типа строки состава
	FilterArray = New Array;
	
	If AllTypes Then
		FilterArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.Service"));
		FilterArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.InventoryItem"));
	ElsIf CurRow.ContentRowType = PredefinedValue("Enum.SpecificationContentRowTypes.Expense") Then
		FilterArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.Service"));
	Else
		FilterArray.Add(PredefinedValue("Enum.ProductsAndServicesTypes.InventoryItem"));
	EndIf;
	
	ChoiceParameter = New ChoiceParameter("Filter.ProductsAndServicesType", New FixedArray(FilterArray));
	SelectionParametersArray = New Array();
	SelectionParametersArray.Add(ChoiceParameter);

	Items.ContentProductsAndServices.ChoiceParameters = New FixedArray(SelectionParametersArray);
	
EndProcedure

&AtServer
Procedure FillCashValues()
	
	CashValues = New Structure;
	CashValues.Insert("UseParametricSpecifications", GetFunctionalOption("UseParametricSpecifications"));
	CashValues.Insert("OperationFixedCost", New FixedMap(New Map));
	CashValues.Insert("ProductsAndServicesCategory", CommonUse.ObjectAttributeValue(Object.Owner, "ProductsAndServicesCategory"));
	
	SupplementCashValues(Object.Operations, CashValues);
	
EndProcedure

&AtClient
Procedure OpenFormulasDesigner(OpenParameters, Notification)
	
	OpenForm("Catalog.Specifications.Form.FormulasDesigner", OpenParameters, , , , , Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SupplementCashValues(Operations, CashValues)
	
	OperationArray = New Array;
	For Each TabularSectionRow In Operations Do
		If Not ValueIsFilled(TabularSectionRow.Operation) Then
			Continue;
		EndIf; 
		If CashValues.OperationFixedCost.Get(TabularSectionRow.Operation)=Undefined Then
			OperationArray.Add(TabularSectionRow.Operation);
		EndIf; 
	EndDo;
	If OperationArray.Count()=0 Then
		Return;
	EndIf; 
	
	ValueMap = New Map(CashValues.OperationFixedCost);
	
	OperationsAttributes = OperationsAttributes(OperationArray);
	For Each KeyAndValue In OperationsAttributes Do
		ValueMap.Insert(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	CashValues.OperationFixedCost = New FixedMap(ValueMap);
	
EndProcedure

&AtServerNoContext
Function OperationsAttributes(Operations)
	
	Result = New Map;
	
	Query = New Query;
	Query.SetParameter("Operations", Operations);
	Query.Text =
	"SELECT
	|	ProductsAndServices.Ref AS Ref,
	|	ProductsAndServices.FixedCost AS FixedCost
	|FROM
	|	Catalog.ProductsAndServices AS ProductsAndServices
	|WHERE
	|	ProductsAndServices.Ref IN(&Operations)";
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Result.Insert(Selection.Ref, Selection.FixedCost);	
	EndDo;
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Procedure FillInternalDataAfterReadingObject(Object, CashValues)
	
	For Each TabularSectionRow In Object.Content Do
		TabularSectionRow.UseFormulaProductsAndServices = Not IsBlankString(TabularSectionRow.FormulaProductsAndServices);
		TabularSectionRow.UseFormulaNumber = Not IsBlankString(TabularSectionRow.FormulaNumber);
	EndDo; 
	
	For Each TabularSectionRow In Object.Operations Do
		TabularSectionRow.FixedCost = CashValues.OperationFixedCost.Get(TabularSectionRow.Operation);
		TabularSectionRow.UseFormulaOperation = Not IsBlankString(TabularSectionRow.FormulaOperation) And Not ValueIsFilled(Object.DocOrder);
		TabularSectionRow.UseFormulaNumber = (Not IsBlankString(TabularSectionRow.FormulaNumber) Or Not IsBlankString(TabularSectionRow.FormulaTimeNorm)) And Not ValueIsFilled(Object.DocOrder);
	EndDo; 	
		
EndProcedure

&AtClient
Procedure AddMappingOptionsInStructureOpen(OpenParameters, ConnectionKey, TabularSectionName)
	
	FilterStructure = New Structure;
	FilterStructure.Insert("ConnectionKey", ConnectionKey);
	Rows = Object[TabularSectionName].FindRows(FilterStructure);
	OpenParameters.Insert("Mapping", New Array);
	If TabularSectionName="ContentMapping" Then
		StringStructure = New Structure("RulesRowKey, ProductsAndServices, Characteristic, MappingAttribute, ValueOfAttribute");
	ElsIf TabularSectionName="OperationsMapping" Then
		StringStructure = New Structure("RulesRowKey, Operation, MappingAttribute, ValueOfAttribute");
	Else
		Return;
	EndIf; 
	For Each TabularSectionRow In Rows Do
		NewStructure = CommonUseClientServer.CopyRecursive(StringStructure);
		FillPropertyValues(NewStructure, TabularSectionRow);
		OpenParameters.Mapping.Add(NewStructure);
	EndDo; 
	
EndProcedure

&AtClient
Procedure UpdateMapping(CurrentRow, DesignerData, TabularSectionName)
	
	FilterStructure = New Structure;
	FilterStructure.Insert("ConnectionKey", CurrentRow.ConnectionKey);
	Rows = Object[TabularSectionName].FindRows(FilterStructure);
	For Each FoundString In Rows Do
		Object[TabularSectionName].Delete(FoundString);
	EndDo;
	If CurrentRow.MappingUsed Then
		For Each MappingItem In DesignerData.Mapping Do
			NewRow = Object[TabularSectionName].Add();
			FillPropertyValues(NewRow, MappingItem);
			NewRow.ConnectionKey = CurrentRow.ConnectionKey;
		EndDo;
		If TabularSectionName="OperationsMapping" Then
			FieldNameFormula = "FormulaOperation";
		Else
			FieldNameFormula = "FormulaProductsAndServices";
		EndIf; 
		If Not IsBlankString(DesignerData.LongDesc) Then // ava1c Description --> LongDesc
			CurrentRow[FieldNameFormula] = StrTemplate(NStr("en='<Mapping: %1>';ru='<Сопоставление: %1>';vi='<So sánh:%1>'"), DesignerData.LongDesc);
		Else
			CurrentRow[FieldNameFormula] = NStr("en='<Mapping>';ru='<Сопоставление>';vi='<So sánh>'");
		EndIf; 
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateAdditionalAttributesRequerments(Form, OnlyUpdateSigns = False)
	
	Object = Form.Object;
	CashValues = Form.CashValues;
	IsTemplateCurrentValue = Object.IsTemplate;
	If Not CashValues.Property("CheckedAdditionalAttributes") Then
		CashValues.Insert("CheckedAdditionalAttributes", New Array);
	EndIf;
	
	If Not OnlyUpdateSigns Then
		
		Object.IsTemplate = False;
		If CashValues.UseParametricSpecifications Then
			For Each TabularSectionRow In Object.Content Do
				If TabularSectionRow.UseFormulaProductsAndServices
					Or TabularSectionRow.UseFormulaNumber Then
					Object.IsTemplate = True;
					Break;
				EndIf; 
			EndDo;
			If Not Object.IsTemplate Then
				For Each TabularSectionRow In Object.Operations Do
					If TabularSectionRow.UseFormulaOperation
						Or TabularSectionRow.UseFormulaNumber Then
						Object.IsTemplate = True;
						Break;
					EndIf; 
				EndDo;
			EndIf; 
		EndIf;
		
	EndIf; 
	
	If Not CommonUseClientServer.HasAttributeOrObjectProperty(Form, "Properties_UseAdditionalAttributes") 
		Or Not Form.Properties_UseAdditionalAttributes Then
		Return;
	EndIf;
	If Form.Properties_AdditionalAttributesDescription.Count()=0 Then
		Return;
	EndIf; 
	
	If Object.IsTemplate<>IsTemplateCurrentValue Or OnlyUpdateSigns Then
		If Object.IsTemplate Then
			// Отключение обязательности доп. реквизитов
			CashValues.CheckedAdditionalAttributes.Clear();
			For Each TabularSectionRow In Form.Properties_AdditionalAttributesDescription Do
				If Not TabularSectionRow.FillObligatory Then
					Continue;
				EndIf; 
				If CashValues.CheckedAdditionalAttributes.Find(TabularSectionRow.Property)=Undefined Then
					CashValues.CheckedAdditionalAttributes.Add(TabularSectionRow.Property);
				EndIf;
				TabularSectionRow.FillObligatory = False;
				Item = Form.Items.Find(TabularSectionRow.AttributeNameValue);
				If Item<>Undefined And TypeOf(Item)=Type("FormField") And Item.Type=FormFieldType.InputField Then
					Item.AutoMarkIncomplete = False;
					Item.MarkIncomplete = False;
				EndIf; 
			EndDo;
		Else
			// Включение обязательности доп. реквизитов
			For Each Property In CashValues.CheckedAdditionalAttributes Do
				FilterStructure = New Structure;
				FilterStructure.Insert("Property", Property);
				Rows = Form.Properties_AdditionalAttributesDescription.FindRows(FilterStructure);
				For Each TabularSectionRow In Rows Do
					TabularSectionRow.FillObligatory = True;
					Item = Form.Items.Find(TabularSectionRow.AttributeNameValue);
					If Item<>Undefined And TypeOf(Item)=Type("FormField") And Item.Type=FormFieldType.InputField Then
						Item.AutoMarkIncomplete = True;
					EndIf; 
				EndDo; 
			EndDo; 
		EndIf; 
	EndIf; 
	
EndProcedure

#EndRegion 

#Region LibrariesHandlers

// StandardSubsystems.DataLoadFromFile
&AtClient
Procedure DataImportFromExternalSources(Command)
	
	NotifyDescription = New NotifyDescription("ImportDataFromExternalSourceResultDataProcessor", ThisObject, DataLoadSettings);
	
	DataImportFromExternalSourcesClient.ShowDataImportFormFromExternalSource(DataLoadSettings, NotifyDescription, ThisObject);
	
EndProcedure

&AtClient
Procedure ImportDataFromExternalSourceResultDataProcessor(ImportResult, AdditionalParameters) Export
	
	If TypeOf(ImportResult) = Type("Structure") Then
		
		If ImportResult.ActionsDetails = "ChangeDataImportFromExternalSourcesMethod" Then
			
			DataImportFromExternalSources.ChangeDataImportFromExternalSourcesMethod(DataLoadSettings.DataImportFormNameFromExternalSources);
			
			NotifyDescription = New NotifyDescription("ImportDataFromExternalSourceResultDataProcessor", ThisObject, DataLoadSettings);
			DataImportFromExternalSourcesClient.ShowDataImportFormFromExternalSource(DataLoadSettings, NotifyDescription, ThisObject);
			
		ElsIf ImportResult.ActionsDetails = "ProcessPreparedData" Then
			
			DataMatchingTable = ImportResult.DataMatchingTable;
			For Each TableRow In DataMatchingTable Do
				
				If TableRow[DataImportFromExternalSources.ServiceFieldNameImportToApplicationPossible()] Then
					
					FillPropertyValues(Object.Content.Add(), TableRow);
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
EndProcedure
// End StandardSubsystems.ЗагрузкаДанныхИзФайла

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesRunCommand(ItemOrCommand, URL = Undefined, StandardProcessing = Undefined)
	
	PropertiesManagementClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	PropertiesManagement.UpdateAdditionalAttributesItems(ThisObject);
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertiesManagementClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_AdditionalAttributeOnChange(Item)
	PropertiesManagementClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

// End StandardSubsystems.Свойства

#EndRegion

