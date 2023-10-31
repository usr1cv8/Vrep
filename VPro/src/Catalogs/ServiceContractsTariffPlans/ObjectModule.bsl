
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventsHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If UnplannedCostsIncludeInInvoice Then
		CheckedAttributes.Add("UnplannedCostsPresentationInInvoice");
		
		If UnplannedCostsPricingMethod = Enums.BillingCostsPricingMethod.FixedValue Then
			CheckedAttributes.Add("UnplannedCostsFixedPrice");
		ElsIf UnplannedCostsPricingMethod = Enums.BillingCostsPricingMethod.ByCostWithMarkup Then
			CheckedAttributes.Add("UnplannedCostsMarkup");
		EndIf;
	EndIf;
	
	For Each Str In ProductsAndServicesAccounting Do
		If Str.PricingMethod = Enums.BillingProductsAndServicesPricingMethod.FixedValue
			And Not ValueIsFilled(Str.Price) Then
			
			MessageText = StrTemplate(
				NStr("en='The ""Price"" column in the %1 line of the ""Products and services"" list is not filled.';ru='Не заполнена колонка ""Цена"" в строке %1 списка ""Номенклатура"".';vi='Chưa điền cột ""Đơn giá"" trong dòng %1 của danh sách ""Mặt hàng"".'"),
				Str.LineNumber
			);
			
			SmallBusinessServer.ShowMessageAboutError(
				ThisObject,
				MessageText,
				"ProductsAndServicesAccounting",
				Str.LineNumber,
				"PricePresentation",
				Cancel
			);
		EndIf;
	EndDo;
	
	For Each Str In CostAccounting Do
		
		If Str.PricingMethod = Enums.BillingCostsPricingMethod.FixedValue
			And Not ValueIsFilled(Str.Price) Then
			
			MessageText = StrTemplate(
				NStr("en='The ""Price"" column in the %1 line of the ""Costs"" list is not filled.';ru='Не заполнена колонка ""Цена"" в строке %1 списка ""Затраты"".';vi='Chưa điền cột ""Đơn giá"" trong dòng %1 của danh sách ""Chi phí"".'"),
				Str.LineNumber
			);
			
			SmallBusinessServer.ShowMessageAboutError(
				ThisObject,
				MessageText,
				"CostAccounting",
				Str.LineNumber,
				"PricePresentation",
				Cancel
			);
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndIf
