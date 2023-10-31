Var IsNewObject;

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventsHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		If FillingData.Property("ProductsAndServicesRef") Then
			
			Owner = FillingData.ProductsAndServicesRef;
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load And AdditionalProperties.Property("DisableObjectChangeRecordMechanism") Then
		Return;
	EndIf;
	
	ProductsAndServicesCategoriesServer.PropertyFillingCheckBeforeWrite(ThisObject, Cancel);
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	IsNewObject = IsNew();
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load And AdditionalProperties.Property("DisableObjectChangeRecordMechanism") Then
		Return;
	EndIf;
	
	If TypeOf(Owner) = Type("CatalogRef.ProductsAndServices") Then
		Category = Owner.ProductsAndServicesCategory;
	ElsIf TypeOf(Owner) = Type("CatalogRef.ProductsAndServicesCategories") Then
		Category = Owner;
	EndIf;
	ProductsAndServicesCategoriesServer.PropertyFillingCheckOnWrite(ThisObject, Category, Cancel);
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

//Возвращает количество характеристик по владельцу 
//
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

#EndRegion

#EndIf