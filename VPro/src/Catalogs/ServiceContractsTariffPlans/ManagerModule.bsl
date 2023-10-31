#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region ProgramInterface

// Проверяет, имеются ли в базе тарифные планы с заполненными условиями по перевыставлению затрат:
//  — если имеются запланированные затраты,
//  — если задано какое-либо правило для внеплановых затрат.
// 
// Returns:
//   - Boolean
//
Function HasTariffPlansWithCostsAccounting() Export
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	ServiceContractsTariffPlans.Ref
	|FROM
	|	Catalog.ServiceContractsTariffPlans AS ServiceContractsTariffPlans
	|WHERE
	|	(ServiceContractsTariffPlans.UnplannedCostsIncludeInInvoice
	|			OR ServiceContractsTariffPlans.UnplannedCostsProhibit)
	|
	|UNION
	|
	|SELECT
	|	ServiceContractsTariffPlansCostAccounting.Ref
	|FROM
	|	Catalog.ServiceContractsTariffPlans.CostAccounting AS ServiceContractsTariffPlansCostAccounting";
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// Возвращает представление в счете объекта договора обслуживания в соответствии с тарифным планом.
//
// Parameters:
//  TariffPlan                - CatalogRef.ServiceContractsTariffPlans
//  ServiceContractObject  - СправочникСсылка.Номенклатура, ПланСчетовСсылка.Управленческий
// 
// Returns:
//   - CatalogRef.ProductsAndServices
//
Function PresentationInAccount(TariffPlan, ServiceContractObject) Export
	
	If TypeOf(ServiceContractObject) = Type("CatalogRef.ProductsAndServices") Then
		Row = TariffPlan.ProductsAndServicesAccounting.Find(ServiceContractObject, "ProductsAndServices");
		If Row <> Undefined Then
			Return Row.PresentationInAccount;
		EndIf;
	ElsIf TypeOf(ServiceContractObject) = Type("ChartOfAccountsRef.Managerial") Then
		Row = TariffPlan.CostAccounting.Find(ServiceContractObject, "CostsItem");
		If Row <> Undefined Then
			Return Row.PresentationInAccount;
		EndIf;
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#EndIf