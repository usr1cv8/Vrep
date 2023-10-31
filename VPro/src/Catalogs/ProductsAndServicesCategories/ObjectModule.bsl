#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventsHandlers

// Procedure - BeforeWrite event handler.
//
Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not Cancel And Not IsFolder Then
		
		// StandardSubsystems.Properties
		PropertiesManagement.BeforeObjectKindWrite(ThisObject, "Catalog_Specifications", "SpecificationAttributesArray");
		PropertiesManagement.BeforeObjectKindWrite(ThisObject, "Catalog_ProductsAndServicesCharacteristics", "CharacteristicPropertySet");
		PropertiesManagement.BeforeObjectKindWrite(ThisObject, "Catalog_ProductsAndServices", "PropertySet");
		// End StandardSubsystems.Properties
		
	EndIf;
	
	AdditionalProperties.Insert("IsNew", IsNew());
	
EndProcedure // BeforeWrite()

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If DeletionMark Then
		
		CategoryFillingValue = ProductsAndServicesCategoriesServer.CategoryFillingValue();
		If CategoryFillingValue = Ref Then
			ProductsAndServicesCategoriesServer.WriteCategoryFillingValue(Catalogs.ProductsAndServicesCategories.WithoutCategory);
		EndIf;
		
	EndIf;
	
EndProcedure // OnWrite()

// Procedure - event handler  AtCopy.
//
Procedure OnCopy(CopiedObject)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not IsFolder Then
		PropertySet = Undefined;
		CharacteristicPropertySet = Undefined;
		SortingOrder.Clear();
	EndIf;
	
EndProcedure // OnCopy()

#EndRegion

#EndIf