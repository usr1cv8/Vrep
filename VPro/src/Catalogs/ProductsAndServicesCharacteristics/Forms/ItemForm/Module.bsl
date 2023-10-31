
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If ValueIsFilled(Parameters.Key) Then
		
		If TypeOf(Parameters.Key.Owner) = Type("CatalogRef.ProductsAndServices") Then
		
			ProductsAndServicesCategory = Parameters.Key.Owner.ProductsAndServicesCategory;
			ProductsAndServices = Parameters.Key.Owner;
			
		ElsIf TypeOf(Parameters.Key.Owner) = Type("CatalogRef.ProductsAndServicesCategories") Then
			
			ProductsAndServicesCategory = Parameters.Key.Owner;
			ProductsAndServices = Undefined;
			
		EndIf;
		
	// Копирование объекта.
	ElsIf Parameters.Property("CopyingValue")
		And ValueIsFilled(Parameters.CopyingValue) Then
		
		If TypeOf(Parameters.CopyingValue.Owner) = Type("CatalogRef.ProductsAndServices") Then
			
			ProductsAndServices = Parameters.CopyingValue.Owner;
			ProductsAndServicesCategory = ProductsAndServices.ProductsAndServicesCategory;
			
		ElsIf TypeOf(Parameters.CopyingValue.Owner) = Type("CatalogRef.ProductsAndServicesCategories") Then
			
			ProductsAndServicesCategory = Parameters.CopyingValue.Owner;
			ProductsAndServices = Undefined;
			
		EndIf;
		
		Object.PictureFile = Undefined;
		
	// Заполнение.
	ElsIf Parameters.Property("FillingValues") Then
		
		If Parameters.FillingValues.Property("Owner") Then
			
			If TypeOf(Parameters.FillingValues.Owner) = Type("CatalogRef.ProductsAndServices") Then
				
				ProductsAndServices = Parameters.FillingValues.Owner;
				ProductsAndServicesCategory = ProductsAndServices.ProductsAndServicesCategory;
				
			ElsIf TypeOf(Parameters.FillingValues.Owner) = Type("CatalogRef.ProductsAndServicesCategories") Then
				
				ProductsAndServicesCategory = Parameters.FillingValues.Owner;
				ProductsAndServices = Undefined;
				
			ElsIf TypeOf(Parameters.FillingValues.Owner) = Type("ValueList") Then
				
				If Parameters.FillingValues.Owner.Count() = 1 And TypeOf(Parameters.FillingValues.Owner[0].Value) = Type("Array")
					Then
					
					For Each ListIt In Parameters.FillingValues.Owner[0].Value Do
						
						If TypeOf(ListIt) = Type("CatalogRef.ProductsAndServices") Then
							Object.Owner = ListIt;
							ProductsAndServices = ListIt;
							ProductsAndServicesCategory = ProductsAndServices.ProductsAndServicesCategory;
							Break;
						Else
							Object.Owner = ListIt;
							ProductsAndServicesCategory = ListIt;
						EndIf;
						
					EndDo;
					
				Else
					For Each ListIt In Parameters.FillingValues.Owner Do
						
						If TypeOf(ListIt.Value) = Type("CatalogRef.ProductsAndServices") Then
							Object.Owner = ListIt.Value;
							ProductsAndServices = ListIt.Value;
							ProductsAndServicesCategory = ProductsAndServices.ProductsAndServicesCategory;
							Break;
						Else
							Object.Owner = ListIt.Value;
							ProductsAndServicesCategory = ListIt.Value;
						EndIf;
						
					EndDo;
					
				EndIf;
				
			ElsIf TypeOf(Parameters.FillingValues.Owner) = Type("Array") Then
				For Each ListIt In Parameters.FillingValues.Owner Do
					
					If TypeOf(ListIt) = Type("CatalogRef.ProductsAndServices") Then
						Object.Owner = ListIt;
						ProductsAndServices = ListIt;
						ProductsAndServicesCategory = ProductsAndServices.ProductsAndServicesCategory;
						Break;
					Else
						Object.Owner = ListIt;
						ProductsAndServicesCategory = ListIt;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		
		// Элемент создается из формы выбора; заполним значения дополнительных реквизитов значениями отбора.
		If Parameters.FillingValues.Property("ValuesOfAdditionalAttributes") Then
			
			For Each Item In Parameters.FillingValues.ValuesOfAdditionalAttributes Do
				
				NewRow = Object.AdditionalAttributes.Add();
				NewRow.Property = Item.Key;
				NewRow.Value = Item.Value;
				
			EndDo;
			
		EndIf;
		
	Else
		
		ProductsAndServicesCategory = Undefined;
		ProductsAndServices = Undefined;
		
	EndIf;
	
	If Not Cancel Then
		FillOwnerChoiceList();
	EndIf;
	
	AllowedEditDocumentPrices = SmallBusinessAccessManagementReUse.HasAccessRight(
		"Update",
		CommonUse.MetadataObjectID(Metadata.InformationRegisters.ProductsAndServicesPrices)
	);
	MetadataObject = Object.Ref.Metadata();
	CharacteristicEditAllowed =
		SmallBusinessAccessManagementReUse.HasAccessRight(
			"Insert",
			CommonUse.MetadataObjectID(MetadataObject))
		Or SmallBusinessAccessManagementReUse.HasAccessRight(
			"Update", 
			CommonUse.MetadataObjectID(MetadataObject));
	
	// УНФ StandardSubsystems.Properties
	PropertiesManagementOverridable.PropertiesTableOnCreateAtServer(ThisObject);
	If Not Items.FormCommandBar.ChildItems.Find("EditAdditionalAttributesContent") = Undefined
		Then
		Items.FormCommandBar.ChildItems.EditAdditionalAttributesContent.Visible = False;
	EndIf;
	
	IsNew = (Object.Ref.IsEmpty());
	IsCopy = ValueIsFilled(Parameters.CopyingValue);
	
EndProcedure // ПриСозданииНаСервере()

&AtClient
Procedure OnOpen(Cancel)
	
	// УНФ StandardSubsystems.Properties
	PropertiesManagementClientOverridableCM.PropertiesTableRefreshAdditionalAttributeDependencies(ThisObject, Object); 
	
	If TypeOf(ThisForm.FormOwner) = Type("FormTable") And Not ThisForm.FormOwner.CurrentData = Undefined
		Then
		ThisForm.ReadOnly = ?(ThisForm.FormOwner.CurrentData.Property("IsCategory") And Not IsNew, ThisForm.FormOwner.CurrentData.IsCategory, False);
		Items.PropertiesAndValues.ReadOnly = ThisForm.ReadOnly;
		
		CommonUseClientServer.SetFormItemProperty(Items, "PictureURLContextMenuAddImage", "Enabled", Not ThisForm.ReadOnly);
		CommonUseClientServer.SetFormItemProperty(Items, "PictureAddressContextMenuSetImageAsDafault", "Enabled", Not ThisForm.ReadOnly);
		CommonUseClientServer.SetFormItemProperty(Items, "PictureAddressContextMenuDeleteImage", "Enabled", Not ThisForm.ReadOnly);
		
		CommonUseClientServer.SetFormItemProperty(Items, "FormCopy", "Enabled", Not ThisForm.ReadOnly);
		
		Cancel = IsCopy And ThisForm.ReadOnly;
	EndIf;
	
EndProcedure // ПриОткрытии()

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// УНФ StandardSubsystems.Properties
	PropertiesManagementOverridable.PropertiesTableFillCheckProcessingAtServer(ThisObject, Object, Cancel);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// УНФ StandardSubsystems.Properties
	PropertiesManagementOverridable.PropertiesTableBeforeWriteAtServer(ThisObject, CurrentObject);
	
EndProcedure // ПередЗаписьюНаСервере()

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
		
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	If IsNew Then
		Notify("CharacteristicAdded", Object.Ref, Object.Owner);
		IsNew = False;
	EndIf;
	
	If NamesMainPicture Then
	
		Notify("MainPictureUpdated", Object.Ref);
	
	EndIf; 
	
EndProcedure

#EndRegion

#Region FormItemsHandlers

&AtClient
Procedure OwnerOnChange(Item)
	
	If TypeOf(Object.Owner) = Type("CatalogRef.ProductsAndServices") Then
		ProductsAndServicesCategory = GetOwnerProductsAndServicesCategory(Object.Owner);
	ElsIf TypeOf(Object.Owner) = Type("CatalogRef.ProductsAndServicesCategories") Then
		ProductsAndServicesCategory = Object.Owner;
	Else
		ProductsAndServicesCategory = Undefined;
	EndIf;
	
	AdditionalAttributesInFormFill();
	
EndProcedure // ВладелецПриИзменении()

#EndRegion

#Region FormCommandsHandlers

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Function IsInventoryItem()
	
	If TypeOf(Object.Owner)=Type("CatalogRef.ProductsAndServices") Then
		Return CommonUse.ObjectAttributeValue(Object.Owner, "ProductsAndServicesType") = Enums.ProductsAndServicesTypes.InventoryItem;
	ElsIf TypeOf(Object.Owner)=Type("CatalogRef.ProductsAndServicesCategories") Then
		Return CommonUse.ObjectAttributeValue(Object.Owner, "DefaultProductsAndServicesType") = Enums.ProductsAndServicesTypes.InventoryItem;
	EndIf;
	
	Return False;
	
EndFunction

&AtServerNoContext
// Функция возвращает номенклутарную группу владельца.
//
Function GetOwnerProductsAndServicesCategory(ProductsAndServicesOwner)
	
	Return ProductsAndServicesOwner.ProductsAndServicesCategory;
	
EndFunction // ПолучитьНоменклатурнуюГруппуВладельца()

&AtServer
// Процедура - заполняет список выбора для реквизита Владелец.
//
Procedure FillOwnerChoiceList()
	
	Items.Owner.ChoiceList.Clear();
	If ValueIsFilled(ProductsAndServicesCategory) Then
		Items.Owner.ChoiceList.Add(ProductsAndServicesCategory);
	EndIf;
	If ValueIsFilled(ProductsAndServices) Then
		Items.Owner.ChoiceList.Add(ProductsAndServices);
	EndIf;
	
EndProcedure // ЗаполнитьСписокВыбораВладельца()

#EndRegion

#Region Properties

// УНФ StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesRunCommand(ItemOrCommand, URL = Undefined, StandardProcessing = Undefined)
	PropertiesManagementClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure // Подключаемый_РедактироватьСоставСвойств()

&AtClient
Procedure Properties_TablePropertiesAndValuesOnChange(Item)
	
	Modified = True;
	PropertiesManagementClientOverridableCM.PropertiesTableRefreshAdditionalAttributeDependencies(ThisObject, Object);
	
	Object.Description = GenerateDescription();
	
	
EndProcedure

&AtClient
Procedure Properties_TablePropertiesAndValuesBeforeAddRow(Item, Cancel, Copy, Parent, Group, Parameter)
	
	PropertiesManagementClientOverridableCM.PropertiesTable(Cancel);
	
EndProcedure

&AtClient
Procedure Properties_TablePropertiesAndValuesBeforeDeleteRow(Item, Cancel)
	
	Modified = True;
	
	PropertiesManagementClientOverridableCM.PropertiesTableBeforeDelete(Item, Cancel, Modified);
	
	PropertiesManagementClientOverridableCM.PropertiesTableRefreshAdditionalAttributeDependencies(ThisObject, Object);
	
EndProcedure

&AtServer
Procedure AdditionalAttributesInFormFill()
	
	PropertiesManagementOverridable.AdditionalAttributesInFormFill(ThisObject);
	
EndProcedure
// Конец УНФ StandardSubsystems.Properties

&AtServer
// Procedure traverses the value tree recursively.
//
Procedure RecursiveBypassOfValueTree(TreeItems, String)
	
	For Each TreeRow IN TreeItems Do
		
		If ValueIsFilled(TreeRow.Value) Then
			If IsBlankString(TreeRow.FormatProperties) Then
				String = String + TreeRow.Value + ", ";
			Else
				String = String + Format(TreeRow.Value, TreeRow.FormatProperties) + ", ";
			EndIf;
		EndIf;
		
		//NextTreeItem = TreeRow.GetItems();
		//RecursiveBypassOfValueTree(NextTreeItem, String);
		
	EndDo;
	
EndProcedure // RecursiveBypassOfValueTree()

&AtServer
// Function sets new characteristic description by the property values.
//
// Parameters:
//  PropertiesValuesCollection - a value collection with property Value.
//
// Returns:
//  String - generated description.
//
Function GenerateDescription()

	TreeItems = Properties_TablePropertiesAndValues.Unload();
	
	String = "";
	RecursiveBypassOfValueTree(TreeItems, String);
	
	String = Left(String, StrLen(String) - 2);

	If IsBlankString(String) Then
		String = "<Properties aren't assigned>";
	EndIf;

	Return String;

EndFunction // GenerateDescription()

#EndRegion

