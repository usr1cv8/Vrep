#Region ProgramInterface


Function BasisDocumentDescription(BasisDocument) Export
	
	If Not ValueIsFilled(BasisDocument) Then
		Return Undefined;
	EndIf;
	
	If CommonUse.RefExists(BasisDocument) Then
		Return String(BasisDocument);
	Else
		Return "NoObject";
	EndIf;
	
EndFunction

Function GetDataProductsAndServicesOnChange(StructureData) Export
	
	If StructureData.Property("ProductsAndServices") Then
		StructureData.Insert("MeasurementUnit", StructureData.ProductsAndServices.MeasurementUnit);
	EndIf;
	
	If StructureData.Property("VATTaxation") 
		And Not StructureData.VATTaxation = Enums.VATTaxationTypes.TaxableByVAT Then
		
		If StructureData.VATTaxation = Enums.VATTaxationTypes.NotTaxableByVAT Then
			StructureData.Insert("VATRate", SmallBusinessReUse.GetVATRateWithoutVAT());
		Else
			StructureData.Insert("VATRate", SmallBusinessReUse.GetVATRateZero());
		EndIf;	
																
	ElsIf ValueIsFilled(StructureData.ProductsAndServices.VATRate) Then
		StructureData.Insert("VATRate", StructureData.ProductsAndServices.VATRate);
	Else
		StructureData.Insert("VATRate", Catalogs.VATRates.VATRate(StructureData.Company.DefaultVATRateType, ?(ValueIsFilled(StructureData.ProcessingDate), StructureData.ProcessingDate, CurrentSessionDate())));
	EndIf;
	
	If StructureData.Property("DiscountMarkupKind") 
		And ValueIsFilled(StructureData.DiscountMarkupKind) Then
		StructureData.Insert("DiscountMarkupPercent", StructureData.DiscountMarkupKind.Percent);
	Else	
		StructureData.Insert("DiscountMarkupPercent", 0);
	EndIf;
		
	If StructureData.Property("DiscountPercentByDiscountCard") 
		And ValueIsFilled(StructureData.DiscountCard) Then
		CurPercent = StructureData.DiscountMarkupPercent;
		StructureData.Insert("DiscountMarkupPercent", CurPercent + StructureData.DiscountPercentByDiscountCard);
	EndIf;

	Return StructureData;
	
EndFunction

#EndRegion
