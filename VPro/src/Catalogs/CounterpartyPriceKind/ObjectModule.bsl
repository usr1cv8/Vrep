
Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If TypeOf(FillingData) = Type("CatalogRef.CounterpartyContracts") Then
		
		Description = NStr("en='Main price kind';ru='Основной вид цены';vi='Loại giá chính' ");
		Owner = FillingData.Owner;
		PriceCurrency = FillingData.SettlementsCurrency;
		
	EndIf;
	
EndProcedure
