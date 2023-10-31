#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventsHandlers

// Procedure - event handler FillCheckProcessing object.
//
Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If ProductsAndServicesType = Enums.ProductsAndServicesTypes.InventoryItem Then
		
		CheckedAttributes.Add("EstimationMethod");
		CheckedAttributes.Add("BusinessActivity");
		CheckedAttributes.Add("ReplenishmentMethod");
		CheckedAttributes.Add("ExpensesGLAccount");
		CheckedAttributes.Add("InventoryGLAccount");
		
	ElsIf ProductsAndServicesType = Enums.ProductsAndServicesTypes.Service Then
		
		CheckedAttributes.Add("BusinessActivity");
		CheckedAttributes.Add("ExpensesGLAccount");
		
	ElsIf ProductsAndServicesType = Enums.ProductsAndServicesTypes.Work Then
		
		CheckedAttributes.Add("BusinessActivity");
		CheckedAttributes.Add("ExpensesGLAccount");
		
	ElsIf ProductsAndServicesType = Enums.ProductsAndServicesTypes.Operation Then
		
		CheckedAttributes.Add("ExpensesGLAccount");
		
	EndIf;
	
EndProcedure // FillCheckProcessing()

// Procedure - event handler BeforeWrite object.
//
Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load And AdditionalProperties.Property("DisableObjectChangeRecordMechanism") Then
		Return;
	EndIf;
	
	ChangeDate = CurrentDate();
	
	If Not IsFolder Then
		ProductsAndServicesCategoriesServer.PropertyFillingCheckBeforeWrite(ThisObject, Cancel);
	EndIf;

EndProcedure

// Procedure - event handler of the OnCopy object.
//
Procedure OnCopy(CopiedObject)
	
	If Not CopiedObject.IsFolder Then
		
		DeleteSpecification = Undefined;
		PictureFile = Catalogs.ProductsAndServicesAttachedFiles.EmptyRef();
		
	EndIf;
	
EndProcedure // OnCopy()

Procedure OnWrite(Cancel)
	
	If DataExchange.Load And AdditionalProperties.Property("DisableObjectChangeRecordMechanism") Then
		Return;
	EndIf;
	
	If Not IsFolder Then
		ProductsAndServicesCategoriesServer.PropertyFillingCheckOnWrite(ThisObject, ProductsAndServicesCategory, Cancel);
	EndIf;
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf